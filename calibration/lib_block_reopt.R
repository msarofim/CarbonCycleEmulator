# =====================================================================
# lib_block_reopt.R -- re-optimise a BLOCK of fitted names at a fixed vector, and read what the
# optimum implies (2026-10-04). The machinery of calibration/diag_greening_lag_swap.R (CHANGELOG
# 10-04 e), lifted so the objective-#16 previews (10-04 h) use the SAME code. That driver keeps its
# own copies, verbatim at its commit, so its recorded outputs stay reproducible.
#
# THE CALLER DEFINES, before calling anything here:
#   BR_MD      named list of mode files (readRDS), the BASES
#   BR_SPF     the same names -> each base's spinup function (ccx_spinup_from_label)
#   BR_OBS     ccx_prepare_obs()
#   BR_PINS    the common pins, a NAMED numeric WITHOUT gate_struct (the cell opens its own gate)
#   BR_LABEL_LAG, BR_LABEL_ZERO   the lag / lag-0 structure labels (L > 0 / L = 0)
#   BR_VB      the same names -> dg_vector(<base file>), built with NO gate applied
#   BR_WIN, BR_TREND_DF, BR_XLAGS, BR_OBS_WEEKLY   the growth-timing estimator (the refit read's s. 6)
#   BR_FUT_SPLICE, BR_FUT_YEAR                    the futures (the refit read's s. 8)
# Tolerances (BR_MODE_TOL, BR_PULL_H, BR_NDEPS, BR_BFGS_MAXIT, BR_NM_MAXIT, BR_RELTOL, BR_ROUNDS)
# default to diag_greening_lag_swap.R's values when the caller leaves them unset.
# ⚠ The convergence gate (every whitened slope < BR_MODE_TOL) is CURVATURE-BLIND away from the base
# (memory whitened_slope_gate_blind_off_base): read a failed gate with two starts or a held profile.
# =====================================================================
`%||%` <- function(a, b) if (is.null(a)) b else a
.br_default <- function(nm, v) if (!exists(nm, envir = globalenv())) assign(nm, v, envir = globalenv())
.br_default("BR_MODE_TOL", 0.1); .br_default("BR_PULL_H", 0.1); .br_default("BR_NDEPS", 0.01)
.br_default("BR_BFGS_MAXIT", 200L); .br_default("BR_NM_MAXIT", 1500L); .br_default("BR_RELTOL", 1e-12)
.br_default("BR_ROUNDS", 3L)

br_prec <- function(md, nm) { H <- md$hessian; dimnames(H) <- list(md$param_names, md$param_names); -H[nm, nm, drop = FALSE] }
br_u_of_par <- function(md, nm) vapply(nm, function(n) .to_unc(md$par_mode[[n]], CCX_PARAM_GATED_ALL[[n]] %||% CCX_PARAM_TABLE[[n]]), 0)

#' The conditional optimum of `free` at base `b`, land ENSO lag `L` (0 = the lag-0 label, exactly),
#' every other name at the base, `hold` (named natural values) overriding held names. Starts from the
#' base's own block, or from `start_par` (a named natural list for the free names). Whitened by the
#' base's stored block precision; BFGS + Nelder-Mead rounds until the slope check passes.
#' `extra` (2026-10-04, the P3 preview): an optional function of the NATURAL parameter list returning a
#' log-likelihood term ADDED to the objective (a candidate row priced before it is built). NULL = the
#' objective alone, exactly as before.
#' `drop` (2026-10-06, the interannual-cut preview): stream names LEFT OUT of the objective the block is
#' optimised on. The returned `logpost`/`streams` stay the FULL objective's; `obj` is the optimised value.
#' Checked against the objective's own stream names before any optimisation (inside f() a bad name would
#' be swallowed by the tryCatch as -Inf on every evaluation). NULL = exactly as before.
#' `base_over` (2026-10-06, same preview): a named list overriding NON-fitted base parameters of the
#' objective (e.g. `gamma_diff`, held at 0.25 by the canonical). A fitted or unknown name STOPS.
#' NULL = exactly as before.
br_cell <- function(b, L, free, hold = NULL, start_par = NULL, max_rounds = BR_ROUNDS, extra = NULL,
                    drop = NULL, base_over = NULL) {
  md <- BR_MD[[b]]
  label <- if (L == 0) BR_LABEL_ZERO else BR_LABEL_LAG
  g <- ccx_apply_gate(label); r <- ccx_apply_pins(BR_PINS)
  on.exit({ ccx_unpin_params(r); ccx_unapply_gate(g) }, add = TRUE)
  bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  for (n in names(base_over)) {
    if (n %in% CCX_PARAM_NAMES || !n %in% names(bp))
      stop("br_cell(): base_over may only override a NON-fitted base parameter; '", n, "' is ",
           if (n %in% CCX_PARAM_NAMES) "fitted" else "not a base parameter")
    bp[[n]] <- base_over[[n]]
  }
  bp[[CCX_GATE_FLAG_ENSO_LAG]] <- if (L > 0) 1L else NULL
  stopifnot(identical(ccx_gates_open(bp), ccx_gates_open(label)))
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = BR_SPF[[b]], obs = BR_OBS)
  pm <- ccx_mode_par_with_pins(md)
  pm[["lag_enso_land"]] <- if (L > 0) L else NULL
  for (n in names(start_par)) { stopifnot(n %in% free); pm[[n]] <- start_par[[n]] }
  for (n in names(hold)) { stopifnot(!n %in% free); pm[[n]] <- hold[[n]] }
  u_st <- ccx_par_to_unc(pm)
  stopifnot(identical(names(u_st), CCX_PARAM_NAMES), (L > 0) == ("lag_enso_land" %in% names(u_st)))
  u0 <- br_u_of_par(md, free); U <- chol(br_prec(md, free))
  u_at <- function(z) { uu <- u_st; uu[free] <- u0 + backsolve(U, z); uu }
  .obj <- function(lv) if (is.null(drop)) as.numeric(lv) else as.numeric(lv) - sum(unlist(attr(lv, "streams"))[drop])
  if (!is.null(drop)) { s0 <- names(unlist(attr(lp(u_st), "streams")))
    if (!all(drop %in% s0)) stop("br_cell(): `drop` names streams the objective does not have: ",
                                 paste(setdiff(drop, s0), collapse = ", ")) }
  n_eval <- 0L; n_bad <- 0L
  f <- function(z) { n_eval <<- n_eval + 1L
    v <- tryCatch({ uu <- u_at(z); .obj(lp(uu)) + if (is.null(extra)) 0 else extra(ccx_unc_to_par(uu)) },
                  error = function(e) -Inf)
    if (is.finite(v)) -v else { n_bad <<- n_bad + 1L; 1e10 } }
  slope <- function(z) vapply(seq_along(z), function(i) { e <- rep(0, length(z)); e[i] <- BR_PULL_H
    (f(z + e) - f(z - e)) / (2 * BR_PULL_H) }, 0)
  z <- as.numeric(U %*% (u_st[free] - u0)); t0 <- Sys.time(); rounds <- 0L
  s <- slope(z)
  while (max(abs(s)) >= BR_MODE_TOL && rounds < max_rounds) {
    rounds <- rounds + 1L
    o1 <- stats::optim(z, f, method = "BFGS", control = list(ndeps = rep(BR_NDEPS, length(z)), reltol = BR_RELTOL, maxit = BR_BFGS_MAXIT))
    zc <- o1$par
    o2 <- stats::optim(rep(0, length(z)), function(w) f(zc + w), method = "Nelder-Mead", control = list(reltol = BR_RELTOL, maxit = BR_NM_MAXIT))
    z <- zc + o2$par; s <- slope(z)
  }
  v <- lp(u_at(z)); uu <- u_at(z); par <- ccx_unc_to_par(uu)
  ex <- if (is.null(extra)) 0 else extra(par)
  blk <- unique(c(free, names(hold)))
  out <- list(base = b, L = L, free = free, hold = hold, label = label, z = z, u = uu, block = unlist(par[blk]),
       logpost = as.numeric(v), streams = unlist(attr(v, "streams")), lik = sum(unlist(attr(v, "streams"))), extra = ex,
       slope = s, converged = max(abs(s)) < BR_MODE_TOL, rounds = rounds, n_eval = n_eval, n_bad = n_bad,
       minutes = as.numeric(difftime(Sys.time(), t0, units = "mins")))
  # only when used, so every pre-10-06 caller's return value is unchanged, field for field
  if (!is.null(drop)) { out$drop <- drop; out$obj <- .obj(v) + ex }
  if (!is.null(base_over)) out$base_over <- base_over
  out
}

#' The model vector a cell's optimum implies: the base's, with the block's natural values and the lag.
br_vec <- function(b, block, L) {
  v <- BR_VB[[b]]
  for (n in names(block)) { if (n %in% names(v$p)) v$p[[n]] <- block[[n]]; v$pm[[n]] <- block[[n]] }
  v$p[["lag_enso_land"]] <- L
  v$p <- ccx_set_enso(v$p, v$pm)
  v$luc_scale <- v$pm$luc_scale
  v
}

br_cen12 <- function(x) { n <- length(x); g <- rep(NA_real_, n); i <- 7:(n - 6); g[i] <- x[i + 6] - x[i - 6]; g }
br_obs_growth <- function() {
  wk <- utils::read.table(BR_OBS_WEEKLY, comment.char = "#")
  mo <- stats::aggregate(list(co2 = wk$V5), list(year = wk$V1, month = wk$V2), mean); mo <- mo[order(mo$year, mo$month), ]
  data.frame(k = mo$year * 12L + mo$month, g = br_cen12(mo$co2))
}
#' The refit read's section-6 estimator, plus the two detrended series (for n_eff).
br_timing <- function(out, F, obs_g) {
  m <- data.frame(k = F$year * 12L + F$month, g = br_cen12((out$co2_NH + out$co2_SH) / 2), nino = F$enso)
  M <- merge(m, obs_g, by = "k", suffixes = c("_mod", "_obs"))
  M <- M[M$k >= BR_WIN[1] * 12L + 1L & M$k <= BR_WIN[2] * 12L + 12L & stats::complete.cases(M), ]
  tt <- (M$k - 1) / 12
  detr <- function(g) stats::residuals(stats::lm(g ~ splines::ns(tt, df = BR_TREND_DF)))
  dm <- detr(M$g_mod); do <- detr(M$g_obs)
  xc <- sapply(BR_XLAGS, function(Lg) { n <- m$nino[match(M$k - Lg, m$k)]
    c(mod = stats::cor(dm, n, use = "complete.obs"), obs = stats::cor(do, n, use = "complete.obs")) })
  list(stats = c(peak_mod = BR_XLAGS[which.max(xc["mod", ])], r_mod = max(xc["mod", ]), peak_obs = BR_XLAGS[which.max(xc["obs", ])],
                 r_obs = max(xc["obs", ]), r_mod_obs = stats::cor(dm, do)), detr_mod = dm, detr_obs = do)
}
br_hist_em <- function() as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))[, c("year", "fossil_GtC", "luc_GtC")]
br_futures <- function(v, sp) {
  he <- br_hist_em()
  vapply(names(BR_FUT_SPLICE), function(s) {
    em <- if (!BR_FUT_SPLICE[[s]]) NULL else { e <- ccx_scenario_emissions(s)
      rbind(he, e[e$year > max(he$year), c("year", "fossil_GtC", "luc_GtC")]) }
    rr <- suppressWarnings(ccx_run_coupled(sp, s, c(1750L, BR_FUT_YEAR), emissions = em,
                                           bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale))
    co2 <- tapply((rr$out$co2_NH + rr$out$co2_SH) / 2, floor(rr$out$t), mean); co2[[as.character(BR_FUT_YEAR)]] }, 0)
}

#' THE NET CLIMATE EFFECT on the land sink, on GCB 2025's TRENDY definition (S2 - S1: climate varying vs
#' 1901-20 climate held), over `win`: the model's mean land-carbon gain with the GMST column as observed,
#' minus with GMST HELD at its `clim` mean from clim[1] on. E_LUC is prescribed and identical in both, so
#' it cancels from S_LAND = d(land_C)/dt + E_LUC. ⚠ CO2 is INTERACTIVE here and prescribed in TRENDY: the two
#' runs' CO2 differs and feeds back on fertilisation. MEASURED (calibration/diag_net_climate_co2_feedback.R,
#' 2026-10-04): at hilda34g the warm run has 1.26 ppm LESS CO2 (its land gains with warming), a -0.023 GtC/yr
#' bias (like-for-like +0.141 vs +0.118 here); at q10 1.4, +0.009. Small against GCB's sigma 0.7; not corrected.
#' GMST also drives the ocean's T terms; only the LAND sink is read.
br_net_climate <- function(v, win = c(2015L, 2024L), clim = c(1901L, 1920L)) {
  sp <- dg_spinup(v)
  F <- withCallingHandlers(
    ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp$prod_c14, bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale,
                      enso_index = ccx_enso_index_of(v$p), aod_mode = ccx_aod_mode_of(v$p)),
    warning = function(w) if (grepl("held FLAT", conditionMessage(w))) invokeRestart("muffleWarning"))
  F0 <- F; sel <- F0$year >= clim[1]
  F0$gmst[sel] <- mean(F$gmst[F$year >= clim[1] & F$year <= clim[2]])
  gain <- function(out) { at <- function(t) stats::approx(out$t, out$land_C, xout = t)$y
    (at(win[2] + 1) - at(win[1])) / (win[2] + 1 - win[1]) }
  gg <- c(full = gain(ccx_run_fast(sp, F)$out), held = gain(ccx_run_fast(sp, F0)$out))
  c(gg, net_climate = gg[["full"]] - gg[["held"]])
}
