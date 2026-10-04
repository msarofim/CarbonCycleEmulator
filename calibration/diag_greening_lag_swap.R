#!/usr/bin/env Rscript
# =====================================================================
# diag_greening_lag_swap.R -- DOES THE LAND ENSO LAG SET THE SIGN OF THE GREENING TERM? (2026-10-04)
#
# Pre-registration: notes/prereg_2026-10-04_greening_lag_swap.md, committed before any cell ran.
# Handoff notes/handoff_2026-10-04_hilda34g_adopted.md §4 item 3. The reading under test is CHANGELOG
# 10-03 (g)'s, recorded there as UNTESTED: without the lag, a slightly NEGATIVE npp_tsens (warm year =>
# less NPP; the annual-mean GMST column peaks ~6 months after a December Nino 3.4 peak) supplied a LATE
# El Nino source that patched the too-early land ENSO response; with the lag it is no longer needed,
# and npp_tsens flipped -0.0079 -> +0.0089 /K against beta_max 2.23 -> 1.83.
#
# THE TEST. Two bases (LAG = hilda34g, the lag arm; CTL = the lag-0 control refit) x three lags
# (0; the lag arm's own 2.644; 5 = the observed growth timing, descriptive). In each cell the 8-name
# LAND BLOCK is re-optimised on the #15 LOGPOST, every other name held at the base, from TWO starts
# (the base's own block and the OTHER arm's), in coordinates whitened by the base's block precision.
#   A  the lag's share of the npp_tsens flip, f_B, read as an ORDERING (> or < one half);
#   B  which rows carry the npp_tsens move: the cross cells re-optimised with npp_tsens HELD;
#   C  the greening term's own growth signal against the land ENSO term's, vs Nino 3.4;
#   D  (descriptive, open item 2) the L = 5 column: block, cost, timing, futures.
# L = 0 is scored EXACTLY under the lag-0 label; L > 0 under the lag label. Compare on LIKELIHOOD
# across lags (the lag's flat prior and logit Jacobian sit in the logpost).
# ⛔ ADOPTS NOTHING; moves no stored value. No RNG.
# Usage: Rscript calibration/diag_greening_lag_swap.R   (CCX_GS_WORKERS=<n> forked workers, default 6)
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
GS_DRIVER     <- "calibration/diag_greening_lag_swap.R"
GS_PREREG     <- "notes/prereg_2026-10-04_greening_lag_swap.md"
GS_LABEL_LAG  <- "hilda_csl3v0kaidgbe"
GS_LABEL_ZERO <- "hilda_csl3v0kaidgb"
GS_BASES      <- c(LAG = ccx_mode_file("hilda34g"),
                   CTL = file.path("calibration", "output", "refit_20261003_obj15_hilda_csl3v0kaidgb", "mode_fit_pumpN.rds"))
GS_OTHER      <- c(LAG = "CTL", CTL = "LAG")
GS_LAGNAME    <- "lag_enso_land"
GS_GREEN      <- "npp_tsens"
GS_FERT       <- "beta_max"
GS_AMP        <- c("gamma_enso_land_NH", "gamma_enso_land_SH")
GS_BLOCK      <- c(GS_GREEN, GS_FERT, "fert_k", GS_AMP, "luc_scale", "imb_share_land", "ndep_ret")
GS_BLOCK_SMALL <- c(GS_GREEN, GS_FERT, "fert_k", GS_AMP)   # the power comparison only (the prereg's 0.77-0.78)
GS_LAG_OBS    <- 5                                        # months: observed growth peaks 5 months after Nino 3.4 (10-02 x)
GS_REPRO_TOL  <- 1e-6                                     # log-units: a base reproduces its stored logpost
GS_MODE_TOL   <- 0.1                                      # max |whitened slope| at an optimum: < 0.1 conditional sd away
                                                          #   (the refit read's RD_MODE_TOL convention)
GS_PULL_H     <- 0.1                                      # whitened half-step of the slope check (0.1 conditional sd)
GS_NDEPS      <- 0.01                                     # BFGS central-difference step, whitened units
GS_BFGS_MAXIT <- 200L
GS_NM_MAXIT   <- 1500L
GS_RELTOL     <- 1e-12
GS_ROUNDS     <- 3L                                       # BFGS + Nelder-Mead rounds until the slope check passes
GS_SHARE_CUT  <- 0.5                                      # A's ORDERING: the lag carries more / less than half the flip
GS_RUN_TOL    <- 1e-6                                     # the own-cell runs reproduce the refit read's timing r / futures
GS_GROUPS     <- c(SEASONAL = "seasonal", LEVEL = "^(co2|d13c)_level_", GCB = "^gcb_", ICE = "icecore")   # B's row groups
GS_WIN        <- c(1980L, 2024L)                          # = the refit read's section 6 (= 10-02 x)
GS_TREND_DF   <- 5L
GS_XLAGS      <- -6:18                                    # months; > 0 = Nino 3.4 LEADS growth
GS_OBS_WEEKLY <- file.path("data-raw", "downloads", "mbl_zonal_co2_GL.txt")
GS_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE)            # = the refit read's section 8 conventions
GS_FUT_YEAR   <- 2300L
GS_REFIT_READ <- file.path("outputs", "diagnostics", "obj15_refit_read_20261003.rds")   # the own-cell run targets
GS_WORKERS    <- as.integer(Sys.getenv("CCX_GS_WORKERS", "6"))
# SMOKE (CCX_GS_SMOKE=1): every cell at a tiny optimiser budget, to run every section end to end before the
# real run; its outputs say SMOKE in their name and nothing in them is a result.
GS_SMOKE      <- identical(Sys.getenv("CCX_GS_SMOKE", ""), "1")
if (GS_SMOKE) { GS_BFGS_MAXIT <- 2L; GS_NM_MAXIT <- 10L; GS_ROUNDS <- 1L }
# FROM CELLS (CCX_GS_FROM_CELLS=<path>): re-read a finished run's checkpointed cells instead of recomputing them
GS_FROM_CELLS <- Sys.getenv("CCX_GS_FROM_CELLS", "")
# POST-HOC (CCX_GS_POSTHOC=1, with CCX_GS_FROM_CELLS): sections 3b and 3c, added AFTER the 2026-10-04 run and NOT
# pre-registered -- 3b reads each cell that failed the slope gate by its LOCAL curvature; 3c profiles npp_tsens at
# the two cross cells. Their outputs carry "_posthoc".
GS_POSTHOC    <- identical(Sys.getenv("CCX_GS_POSTHOC", ""), "1")
if (GS_POSTHOC && !nzchar(GS_FROM_CELLS)) stop("CCX_GS_POSTHOC reads a finished run's cells: set CCX_GS_FROM_CELLS too")
GS_PROF_DELTA <- 0.003                                    # 3c: npp_tsens held at nu* -/+ this (/K; ~0.36 marginal sd)
GS_TAG  <- paste0(format(Sys.Date(), "%Y%m%d"), if (GS_SMOKE) "_SMOKE" else "", if (GS_POSTHOC) "_posthoc" else "")
GS_OUT  <- file.path("outputs", "diagnostics", sprintf("greening_lag_swap_%s", GS_TAG))
GS_PROG <- paste0(GS_OUT, "_progress.txt")
COMMIT  <- local({
  h <- suppressWarnings(tryCatch(system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE), error = function(e) character(0)))
  d <- suppressWarnings(tryCatch(system2("git", c("status", "--porcelain", "--", "R", "src", "calibration", "data"), stdout = TRUE),
                                 error = function(e) NA_character_))
  if (length(h) != 1L) "?" else paste0(h, if (anyNA(d)) "+dirty?" else if (length(d)) "+dirty" else "")
})
stopifnot(isTRUE(LIK_USE_ICE_D13C), identical(LIK_ICE_CO2_END, 1958))      # objective #15
`%||%` <- function(a, b) if (is.null(a)) b else a
prog <- function(...) cat(sprintf("%s %s\n", format(Sys.time(), "%H:%M:%S"), sprintf(...)), file = GS_PROG, append = TRUE)
if (file.exists(GS_PROG)) file.remove(GS_PROG)
# the log is a connection THIS script owns: it is flushed before the fork, so a child that drops the
# diversion cannot write a copy of an unflushed buffer into it
LOGCON <- file(paste0(GS_OUT, ".log"), open = "wt")
sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | prereg %s | %d workers\n", GS_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), GS_PREREG, GS_WORKERS))

OBS <- ccx_prepare_obs()
MD  <- lapply(GS_BASES, readRDS)
stopifnot(identical(ccx_mode_struct(MD$LAG), GS_LABEL_LAG), identical(ccx_mode_struct(MD$CTL), GS_LABEL_ZERO),
          identical(unclass(MD$LAG$pins), unclass(MD$CTL$pins)))
GS_PINS <- stats::setNames(as.numeric(MD$LAG$pins), names(MD$LAG$pins))   # the common nine, WITHOUT gate_struct: the cell opens its own gate
SPF <- lapply(MD, function(md) ccx_spinup_from_label(ccx_mode_spinup(md)))
L_LAG <- MD$LAG$par_mode[[GS_LAGNAME]]
GS_LAGS <- c(0, L_LAG, GS_LAG_OBS)
NU <- vapply(MD, function(md) md$par_mode[[GS_GREEN]], 0)
FLIP <- NU[["LAG"]] - NU[["CTL"]]
cat(sprintf("  bases: LAG %s (L %.4f, %s %+.5f, %s %.4f)\n         CTL %s (L 0, %s %+.5f, %s %.4f)\n  the flip: %s %+.5f /K\n",
            GS_BASES[["LAG"]], L_LAG, GS_GREEN, NU[["LAG"]], GS_FERT, MD$LAG$par_mode[[GS_FERT]],
            GS_BASES[["CTL"]], GS_GREEN, NU[["CTL"]], GS_FERT, MD$CTL$par_mode[[GS_FERT]], GS_GREEN, FLIP))

# the base's precision on a set of names, named
prec <- function(md, nm) { H <- md$hessian; dimnames(H) <- list(md$param_names, md$param_names); -H[nm, nm, drop = FALSE] }
cov_of <- function(md) { S <- md$cov; dimnames(S) <- list(md$param_names, md$param_names); S }
u_of_par <- function(md, nm) vapply(nm, function(n) .to_unc(md$par_mode[[n]], CCX_PARAM_GATED_ALL[[n]] %||% CCX_PARAM_TABLE[[n]]), 0)

# ---- 0. POWER: how far the block frees npp_tsens (the prereg's design numbers, recomputed) -----
cat("\n=== 0. POWER: sd of npp_tsens with the block free and every other name held, as a fraction of its MARGINAL sd ===\n")
for (b in names(MD)) {
  S <- cov_of(MD[[b]]); Q <- solve(S); m <- sqrt(S[GS_GREEN, GS_GREEN])
  fr <- vapply(list(block = GS_BLOCK, small = GS_BLOCK_SMALL, none = GS_GREEN), function(B) sqrt(solve(Q[B, B, drop = FALSE])[GS_GREEN, GS_GREEN]) / m, 0)
  cat(sprintf("  %s: marginal sd %.5f /K; the %d-name block frees %.2f of it; the %d-name block %.2f; npp_tsens alone %.2f; the flip is %.2f marginal sds\n",
              b, m, length(GS_BLOCK), fr[["block"]], length(GS_BLOCK_SMALL), fr[["small"]], fr[["none"]], FLIP / m))
}

# ---- one cell: the block's conditional optimum at lag L, from a start ---------------------
# `free` = the names optimised (the block, or the block minus npp_tsens for B's HELD cells); the held
# npp_tsens stays at the BASE's value. Runs inside its own gate state and restores it.
cell_opt <- function(b, L, start, free, max_rounds = GS_ROUNDS, hold = NULL) {
  md <- MD[[b]]
  label <- if (L == 0) GS_LABEL_ZERO else GS_LABEL_LAG
  g <- ccx_apply_gate(label); r <- ccx_apply_pins(GS_PINS)
  on.exit({ ccx_unpin_params(r); ccx_unapply_gate(g) }, add = TRUE)
  bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  bp[[CCX_GATE_FLAG_ENSO_LAG]] <- if (L > 0) 1L else NULL
  stopifnot(identical(ccx_gates_open(bp), ccx_gates_open(label)))
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = SPF[[b]], obs = OBS)
  pm <- ccx_mode_par_with_pins(md)
  pm[[GS_LAGNAME]] <- if (L > 0) L else NULL
  src <- if (identical(start, "own")) b else GS_OTHER[[b]]
  for (n in free) pm[[n]] <- MD[[src]]$par_mode[[n]]
  for (n in names(hold)) { stopifnot(!n %in% free); pm[[n]] <- hold[[n]] }   # 3c only (post-hoc)
  u_st <- ccx_par_to_unc(pm)
  stopifnot(identical(names(u_st), CCX_PARAM_NAMES), (L > 0) == (GS_LAGNAME %in% names(u_st)))
  u0 <- u_of_par(md, free)                               # the frame's origin: the BASE's own values
  U  <- chol(prec(md, free))                             # whitening: -logpost ~ |z|^2 / 2 about the base mode
  u_at <- function(z) { uu <- u_st; uu[free] <- u0 + backsolve(U, z); uu }
  n_eval <- 0L; n_bad <- 0L
  f <- function(z) { n_eval <<- n_eval + 1L
    v <- tryCatch(as.numeric(lp(u_at(z))), error = function(e) -Inf)
    if (is.finite(v)) -v else { n_bad <<- n_bad + 1L; 1e10 } }
  slope <- function(z) vapply(seq_along(z), function(i) { e <- rep(0, length(z)); e[i] <- GS_PULL_H
    (f(z + e) - f(z - e)) / (2 * GS_PULL_H) }, 0)
  z <- as.numeric(U %*% (u_st[free] - u0)); t0 <- Sys.time(); rounds <- 0L
  s <- slope(z)
  while (max(abs(s)) >= GS_MODE_TOL && rounds < max_rounds) {
    rounds <- rounds + 1L
    o1 <- stats::optim(z, f, method = "BFGS", control = list(ndeps = rep(GS_NDEPS, length(z)), reltol = GS_RELTOL, maxit = GS_BFGS_MAXIT))
    zc <- o1$par
    o2 <- stats::optim(rep(0, length(z)), function(w) f(zc + w), method = "Nelder-Mead",
                       control = list(reltol = GS_RELTOL, maxit = GS_NM_MAXIT))
    z <- zc + o2$par
    s <- slope(z)
  }
  v <- lp(u_at(z)); uu <- u_at(z); par <- ccx_unc_to_par(uu)
  list(base = b, L = L, start = start, free = free, held = setdiff(GS_BLOCK, free), label = label,
       z = z, u = uu, block = unlist(par[GS_BLOCK]), logpost = as.numeric(v), streams = unlist(attr(v, "streams")),
       lik = sum(unlist(attr(v, "streams"))), slope = s, converged = max(abs(s)) < GS_MODE_TOL, rounds = rounds,
       n_eval = n_eval, n_bad = n_bad, minutes = as.numeric(difftime(Sys.time(), t0, units = "mins")))
}

# ---- the runs a cell's optimum implies (timing, futures), from the base's vector -------------
VB <- lapply(GS_BASES, dg_vector)                         # built with no gate applied (dg_vector reads the file)
v_cell <- function(b, block, L) {
  v <- VB[[b]]
  for (n in names(block)) { if (n %in% names(v$p)) v$p[[n]] <- block[[n]]; v$pm[[n]] <- block[[n]] }
  v$p[[GS_LAGNAME]] <- L                                 # the model reads p[["lag_enso_land"]]; 0 = the index itself
  v$p <- ccx_set_enso(v$p, v$pm)
  v$luc_scale <- v$pm$luc_scale
  v
}
cen12 <- function(x) { n <- length(x); g <- rep(NA_real_, n); i <- 7:(n - 6); g[i] <- x[i + 6] - x[i - 6]; g }
wk <- utils::read.table(GS_OBS_WEEKLY, comment.char = "#")
mo <- stats::aggregate(list(co2 = wk$V5), list(year = wk$V1, month = wk$V2), mean); mo <- mo[order(mo$year, mo$month), ]
obs_g <- data.frame(k = mo$year * 12L + mo$month, g = cen12(mo$co2))
timing <- function(out, F) {                              # the refit read's section 6, verbatim in kind
  m <- data.frame(k = F$year * 12L + F$month, g = cen12((out$co2_NH + out$co2_SH) / 2), nino = F$enso)
  M <- merge(m, obs_g, by = "k", suffixes = c("_mod", "_obs"))
  M <- M[M$k >= GS_WIN[1] * 12L + 1L & M$k <= GS_WIN[2] * 12L + 12L & stats::complete.cases(M), ]
  tt <- (M$k - 1) / 12
  detr <- function(g) stats::residuals(stats::lm(g ~ splines::ns(tt, df = GS_TREND_DF)))
  xc <- sapply(GS_XLAGS, function(Lg) { n <- m$nino[match(M$k - Lg, m$k)]
    c(mod = stats::cor(detr(M$g_mod), n, use = "complete.obs"), obs = stats::cor(detr(M$g_obs), n, use = "complete.obs")) })
  c(peak_mod = GS_XLAGS[which.max(xc["mod", ])], r_mod = max(xc["mod", ]), peak_obs = GS_XLAGS[which.max(xc["obs", ])],
    r_obs = max(xc["obs", ]), r_mod_obs = stats::cor(detr(M$g_mod), detr(M$g_obs)))
}
hist_em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))[, c("year", "fossil_GtC", "luc_GtC")]
emis <- function(s) { if (!GS_FUT_SPLICE[[s]]) return(NULL); e <- ccx_scenario_emissions(s)
  rbind(hist_em, e[e$year > max(hist_em$year), c("year", "fossil_GtC", "luc_GtC")]) }
futures <- function(v, sp) vapply(names(GS_FUT_SPLICE), function(s) {
  rr <- suppressWarnings(ccx_run_coupled(sp, s, c(1750L, GS_FUT_YEAR), emissions = emis(s),
                                         bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale))
  co2 <- tapply((rr$out$co2_NH + rr$out$co2_SH) / 2, floor(rr$out$t), mean); co2[[as.character(GS_FUT_YEAR)]] }, 0)
runs_of <- function(v) { r <- dg_run(v); c(timing(r$out, r$F), stats::setNames(futures(v, r$sp), sprintf("%s_%d", names(GS_FUT_SPLICE), GS_FUT_YEAR))) }

# ---- 1. IDENTITY GATES: each base reproduces, is the block's optimum, and its runs reproduce the refit read ----
cat("\n=== 1. IDENTITY GATES (each base at its own lag, its own block) ===\n")
RR <- readRDS(GS_REFIT_READ)
ID <- list()
for (b in names(MD)) {
  Lb <- if (b == "LAG") L_LAG else 0
  o <- cell_opt(b, Lb, "own", GS_BLOCK, max_rounds = 0L)  # no optimisation: the slope check AT the mode
  d <- o$logpost - MD[[b]]$logpost
  cat(sprintf("  %s at L %.4f: logpost %.6f (stored %.6f, diff %+.1e); likelihood %.4f; max |whitened slope| %.4f (gate < %g)\n",
              b, Lb, o$logpost, MD[[b]]$logpost, d, o$lik, max(abs(o$slope)), GS_MODE_TOL))
  if (!(abs(d) <= GS_REPRO_TOL)) stop(b, " does NOT reproduce its stored logpost")
  if (!o$converged) stop(b, "'s mode is not the block's conditional optimum at this tolerance: the frame is wrong")
  rn <- runs_of(v_cell(b, o$block, Lb)); a <- if (b == "LAG") "lag" else "control"
  tgt <- RR$timing[RR$timing$vector == a, ]; fut_t <- RR$futures[a, sprintf("%s_%d", names(GS_FUT_SPLICE), GS_FUT_YEAR)]
  cat(sprintf("    runs: growth peak %+d months (refit read %+d), r_mod_obs %.6f (%.6f); %s\n", as.integer(rn[["peak_mod"]]),
              as.integer(tgt$peak_mod), rn[["r_mod_obs"]], tgt$r_mod_obs,
              paste(sprintf("%s %.3f (%.3f)", names(fut_t), rn[names(fut_t)], fut_t), collapse = ", ")))
  if (rn[["peak_mod"]] != tgt$peak_mod || abs(rn[["r_mod_obs"]] - tgt$r_mod_obs) > GS_RUN_TOL ||
      any(abs(rn[names(fut_t)] - fut_t) > GS_RUN_TOL)) stop(b, "'s runs do not reproduce the refit read: the run path is wrong")
  o$runs <- rn; ID[[b]] <- o
}
ROWS <- names(ID$LAG$streams); stopifnot(setequal(ROWS, names(ID$CTL$streams)))

# ---- 2. THE CELLS, forked ------------------------------------------------------------------
CELLS <- list()
for (b in names(MD)) for (L in GS_LAGS) for (st in c("own", "other")) {
  own_lag <- isTRUE(all.equal(L, if (b == "LAG") L_LAG else 0))
  if (own_lag && st == "own") next                      # = the identity gate above
  CELLS[[length(CELLS) + 1L]] <- list(b = b, L = L, start = st, free = GS_BLOCK, kind = "A")
}
for (b in names(MD)) for (L in GS_LAGS) {                # B: npp_tsens HELD at the base's value, wherever the lag moved
  if (isTRUE(all.equal(L, if (b == "LAG") L_LAG else 0))) next
  CELLS[[length(CELLS) + 1L]] <- list(b = b, L = L, start = "own", free = setdiff(GS_BLOCK, GS_GREEN), kind = "B")
}
cat(sprintf("\n=== 2. %d CELLS on %d forked workers (progress: %s) ===\n", length(CELLS), GS_WORKERS, GS_PROG))
run_cell <- function(cl) {
  while (sink.number() > 0L) sink()                      # a child writes only its progress file
  id <- sprintf("%s L=%.3f %s %s", cl$b, cl$L, cl$start, cl$kind)
  prog("START %s", id)
  o <- tryCatch(cell_opt(cl$b, cl$L, cl$start, cl$free), error = function(e) { prog("ERROR %s: %s", id, conditionMessage(e)); NULL })
  if (is.null(o)) return(list(cell = cl, error = TRUE))
  o$runs <- tryCatch(runs_of(v_cell(cl$b, o$block, cl$L)), error = function(e) { prog("RUN ERROR %s: %s", id, conditionMessage(e)); NULL })
  o$kind <- cl$kind
  prog("DONE  %s: logpost %.4f lik %.4f %s %+.5f %s %.4f; %d evals (%d bad), %d rounds, %.1f min, converged %s",
       id, o$logpost, o$lik, GS_GREEN, o$block[[GS_GREEN]], GS_FERT, o$block[[GS_FERT]], o$n_eval, o$n_bad, o$rounds, o$minutes, o$converged)
  o
}
if (GS_SMOKE) cat(sprintf("  ⚠ SMOKE: every cell at BFGS maxit %d, Nelder-Mead maxit %d, %d round -- NOT A RESULT\n",
                          GS_BFGS_MAXIT, GS_NM_MAXIT, GS_ROUNDS))
t_cells <- Sys.time()
if (nzchar(GS_FROM_CELLS)) {
  ck <- readRDS(GS_FROM_CELLS); stopifnot(identical(ck$cells_spec, CELLS)); RES <- ck$RES
  cat(sprintf("  the cells RE-READ from %s (run @%s)\n", GS_FROM_CELLS, ck$commit))
} else {
  flush(LOGCON)
  RES <- parallel::mclapply(CELLS, run_cell, mc.cores = GS_WORKERS, mc.preschedule = FALSE)
  saveRDS(list(cells_spec = CELLS, RES = RES, commit = COMMIT), paste0(GS_OUT, "_cells.rds"))   # the checkpoint
}
cat(sprintf("  the cells took %.1f min\n", as.numeric(difftime(Sys.time(), t_cells, units = "mins"))))
bad <- vapply(RES, function(o) inherits(o, "try-error") || !is.list(o) || isTRUE(o$error) || is.null(o$logpost), TRUE)
if (any(bad)) stop(sum(bad), " cell(s) FAILED: see ", GS_PROG)

# every cell, as a table (the identity cells included)
ALL <- c(lapply(names(ID), function(b) { o <- ID[[b]]; o$kind <- "A"; o }), RES)
tab <- do.call(rbind, lapply(ALL, function(o) data.frame(base = o$base, L = round(o$L, 4), kind = o$kind, start = o$start,
  logpost = o$logpost, lik = o$lik, npp_tsens = o$block[[GS_GREEN]], beta_max = o$block[[GS_FERT]], fert_k = o$block[["fert_k"]],
  g_NH = o$block[[GS_AMP[1]]], g_SH = o$block[[GS_AMP[2]]], luc_scale = o$block[["luc_scale"]], imb_land = o$block[["imb_share_land"]],
  ndep_ret = o$block[["ndep_ret"]], max_slope = max(abs(o$slope)), conv = o$converged, evals = o$n_eval, bad = o$n_bad,
  peak = if (is.null(o$runs)) NA else o$runs[["peak_mod"]], r_obs = if (is.null(o$runs)) NA else o$runs[["r_mod_obs"]],
  ssp585 = if (is.null(o$runs)) NA else o$runs[[sprintf("ssp585_%d", GS_FUT_YEAR)]],
  vvH = if (is.null(o$runs)) NA else o$runs[[sprintf("vvH_%d", GS_FUT_YEAR)]])))
tab <- tab[order(tab$kind, tab$base, tab$L, tab$start), ]
cat("\n=== 3. EVERY CELL (block re-optimised on the #15 logpost; kind B = npp_tsens HELD at the base) ===\n")
print(tab, digits = 5, row.names = FALSE)
if (any(!tab$conv)) cat(sprintf("  ⚠ %d cell(s) did NOT pass the slope check in %d rounds: read them as points, not optima\n", sum(!tab$conv), GS_ROUNDS))

# the answer per (base, L): the BETTER of the two starts, and whether the two agree
best_of <- function(b, L) {
  cand <- Filter(function(o) o$kind == "A" && o$base == b && isTRUE(all.equal(o$L, L)), ALL)
  cand[[which.max(vapply(cand, `[[`, 0, "logpost"))]]
}
agree_tol <- 2 * GS_MODE_TOL * sqrt(length(GS_BLOCK))  # two converged optima of ONE point differ by <= this, whitened
cat(sprintf("\n  START AGREEMENT (two starts reach one point if their whitened distance <= %.2f = 2 x %g x sqrt(%d)):\n",
            agree_tol, GS_MODE_TOL, length(GS_BLOCK)))
for (b in names(MD)) for (L in GS_LAGS) {
  cand <- Filter(function(o) o$kind == "A" && o$base == b && isTRUE(all.equal(o$L, L)), ALL)
  if (length(cand) < 2L) next
  dz <- sqrt(sum((cand[[1]]$z - cand[[2]]$z)^2)); dlp <- cand[[1]]$logpost - cand[[2]]$logpost
  cat(sprintf("    %s L %.3f: whitened distance %.3f, d logpost %+.4f, npp_tsens %+.5f vs %+.5f => %s\n", b, L, dz, dlp,
              cand[[1]]$block[[GS_GREEN]], cand[[2]]$block[[GS_GREEN]], if (dz <= agree_tol) "ONE point" else "⚠ TWO POINTS (the better is used)"))
}

# ---- 3b. POST-HOC (NOT pre-registered; added after the 2026-10-04 run) ------------------------------
# The slope gate reads |whitened slope| < 0.1 as "the optimum lies < 0.1 conditional sd away". That holds
# where the curvature is the BASE's (the whitened Hessian = I); away from the base the gate is
# CURVATURE-BLIND. Here each cell that failed it gets its LOCAL Hessian in the same whitened frame
# (central differences, half-step GS_PULL_H), the Newton step that Hessian implies, and the objective
# evaluated AT the step: the distance and the gain the gate was meant to bound, and the npp_tsens the
# step would move to. A cell sits at its optimum within the gate's intent if the step is < GS_MODE_TOL
# per axis (|step| < GS_MODE_TOL x sqrt(k)) and the real gain is below the objective's own spread
# between the two starts (read off the table above, not typed).
A_NU <- NULL; A_PROF <- NULL
if (GS_POSTHOC) {
  cat("\n=== 3b. POST-HOC (not pre-registered): the cells that failed the slope gate, read by their LOCAL curvature ===\n")
  newton_cell <- function(o) {
    while (sink.number() > 0L) sink()
    b <- o$base; md <- MD[[b]]; L <- o$L; free <- o$free
    label <- if (L == 0) GS_LABEL_ZERO else GS_LABEL_LAG
    g0 <- ccx_apply_gate(label); r <- ccx_apply_pins(GS_PINS)
    on.exit({ ccx_unpin_params(r); ccx_unapply_gate(g0) }, add = TRUE)
    bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
    bp[[CCX_GATE_FLAG_ENSO_LAG]] <- if (L > 0) 1L else NULL
    lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = SPF[[b]], obs = OBS)
    stopifnot(identical(names(o$u), CCX_PARAM_NAMES))
    u0 <- u_of_par(md, free); U <- chol(prec(md, free))      # the SAME frame as cell_opt()
    u_at <- function(z) { uu <- o$u; uu[free] <- u0 + backsolve(U, z); uu }
    f <- function(z) { v <- tryCatch(as.numeric(lp(u_at(z))), error = function(e) -Inf); if (is.finite(v)) -v else Inf }
    z <- o$z; k <- length(z); h <- GS_PULL_H; f0 <- f(z)
    if (abs(-f0 - o$logpost) > GS_REPRO_TOL) stop("the cell does not reproduce its logpost")
    E <- diag(h, k)
    fp <- vapply(seq_len(k), function(i) f(z + E[, i]), 0); fm <- vapply(seq_len(k), function(i) f(z - E[, i]), 0)
    g <- (fp - fm) / (2 * h); H <- diag((fp - 2 * f0 + fm) / h^2, k)
    for (i in 1:(k - 1)) for (j in (i + 1):k)
      H[i, j] <- H[j, i] <- (f(z + E[, i] + E[, j]) - f(z + E[, i] - E[, j]) - f(z - E[, i] + E[, j]) + f(z - E[, i] - E[, j])) / (4 * h^2)
    ev <- eigen(H, symmetric = TRUE)$values
    step <- -solve(H, g); f1 <- f(z + step)
    nu <- function(zz) ccx_unc_to_par(u_at(zz))[[GS_GREEN]]
    list(base = b, L = L, start = o$start, kind = o$kind, max_slope = max(abs(g)), eig_min = min(ev), eig_max = max(ev),
         newton_dist = sqrt(sum(step^2)), max_step = max(abs(step)), pred_gain = 0.5 * sum(g * solve(H, g)), real_gain = f0 - f1,
         nu = nu(z), nu_newton = nu(z + step))
  }
  todo <- Filter(function(o) !isTRUE(o$converged), ALL)
  flush(LOGCON)
  NW <- parallel::mclapply(todo, newton_cell, mc.cores = GS_WORKERS, mc.preschedule = FALSE)
  if (any(vapply(NW, function(x) inherits(x, "try-error") || !is.list(x), TRUE))) stop("a Newton check FAILED")
  NWT <- do.call(rbind, lapply(NW, as.data.frame))
  spread <- max(vapply(split(tab[tab$kind == "A", ], paste(tab$base[tab$kind == "A"], tab$L[tab$kind == "A"])),
                       function(d) diff(range(d$logpost)), 0))
  NWT$reading <- ifelse(NWT$real_gain > spread, "NOT AT OPTIMUM (the step found a better point)",
                 ifelse(NWT$real_gain < 0, "QUADRATIC INVALID (the step WORSENS the objective)",
                 ifelse(NWT$max_step < GS_MODE_TOL, "AT OPTIMUM", "flat (gain below the start spread)")))
  print(NWT, digits = 4, row.names = FALSE)
  cat(sprintf("  (k = %d; the gain threshold = the largest logpost spread between two starts of one cell, %.2e)\n", length(GS_BLOCK), spread))
  cat(sprintf("  => %s. ⚠ A step that WORSENS the objective says the local quadratic fails over it; its npp_tsens is not an estimate of anything.\n",
              paste(sprintf("%d %s", as.integer(table(NWT$reading)), names(table(NWT$reading))), collapse = "; ")))
  A_NU <- NWT

  # ---- 3c. POST-HOC (NOT pre-registered): npp_tsens PROFILED at the two cross cells --------------------
  # At each cross cell npp_tsens is HELD at nu* - delta, nu* + delta and at the value where f_B = 1/2 (the
  # pre-registered ordering's boundary), the other 7 block names re-optimised (cell_opt's `hold`), and
  # compared with the free optimum. If nu* is the profile's maximum, both -/+ delta points lie below it; the
  # boundary's deficit is how much worse "the lag carries only half the flip" fits, conditionally.
  cat(sprintf("\n=== 3c. POST-HOC (not pre-registered): npp_tsens PROFILED at the two cross cells (held at nu* -/+ %g and at f = 1/2; the other %d names re-optimised) ===\n",
              GS_PROF_DELTA, length(GS_BLOCK) - 1L))
  nu_star <- c(LAG = best_of("LAG", 0)$block[[GS_GREEN]], CTL = best_of("CTL", L_LAG)$block[[GS_GREEN]])
  nu_half <- c(LAG = best_of("LAG", L_LAG)$block[[GS_GREEN]] - FLIP / 2, CTL = best_of("CTL", 0)$block[[GS_GREEN]] + FLIP / 2)
  PJ <- list()
  for (b in names(nu_star)) { L <- if (b == "LAG") 0 else L_LAG
    for (w in c("minus", "plus", "half")) PJ[[length(PJ) + 1L]] <- list(b = b, L = L, which = w,
      nu = switch(w, minus = nu_star[[b]] - GS_PROF_DELTA, plus = nu_star[[b]] + GS_PROF_DELTA, half = nu_half[[b]])) }
  flush(LOGCON)
  PR <- parallel::mclapply(PJ, function(pj) { while (sink.number() > 0L) sink()
    o <- cell_opt(pj$b, pj$L, "own", setdiff(GS_BLOCK, GS_GREEN), hold = stats::setNames(pj$nu, GS_GREEN))
    list(b = pj$b, L = pj$L, which = pj$which, nu = pj$nu, logpost = o$logpost, lik = o$lik, conv = o$converged,
         max_slope = max(abs(o$slope)), evals = o$n_eval) }, mc.cores = GS_WORKERS, mc.preschedule = FALSE)
  if (any(vapply(PR, function(x) inherits(x, "try-error") || !is.list(x), TRUE))) stop("a profile point FAILED")
  PRT <- do.call(rbind, lapply(PR, as.data.frame))
  PRT$d_logpost <- PRT$logpost - vapply(PRT$b, function(b) best_of(b, if (b == "LAG") 0 else L_LAG)$logpost, 0)
  PRT$d_lik <- PRT$lik - vapply(PRT$b, function(b) best_of(b, if (b == "LAG") 0 else L_LAG)$lik, 0)
  print(PRT, digits = 5, row.names = FALSE)
  for (b in names(nu_star)) { d <- PRT[PRT$b == b, ]
    cat(sprintf("  %s (L %.3f): nu* %+.5f is the profile maximum within -/+ %g: %s; f = 1/2 (nu %+.5f) fits %.3f logpost / %.3f likelihood WORSE\n",
                b, d$L[1], nu_star[[b]], GS_PROF_DELTA, if (all(d$d_logpost[d$which != "half"] < 0)) "YES" else "NO",
                nu_half[[b]], -d$d_logpost[d$which == "half"], -d$d_lik[d$which == "half"])) }
  A_PROF <- PRT
}

# ---- A. the lag's share of the flip ----------------------------------------------------------
cat(sprintf("\n=== A. THE LAG'S SHARE OF THE FLIP: f_B = [nu*(B, %.3f) - nu*(B, 0)] / %+.5f (the ordering: > or < %g) ===\n",
            L_LAG, FLIP, GS_SHARE_CUT))
A <- t(vapply(names(MD), function(b) { n0 <- best_of(b, 0)$block[[GS_GREEN]]; nL <- best_of(b, L_LAG)$block[[GS_GREEN]]
  c(nu_L0 = n0, nu_Llag = nL, f = (nL - n0) / FLIP, sign_follows = as.numeric(n0 < 0 && nL > 0)) }, numeric(4)))
print(round(A, 5))
verdict_A <- if (all(A[, "f"] > GS_SHARE_CUT) && all(A[, "sign_follows"] == 1)) "THE LAG SETS THE SIGN (H1 or H3; B decides which)" else
             if (all(A[, "f"] < GS_SHARE_CUT)) "THE HELD NAMES CARRY THE FLIP (H2)" else "AMBIGUOUS (the bases disagree, or the sign does not follow)"
cat(sprintf("  VERDICT A (pre-registered): %s\n", verdict_A))
cat("  the rest of the block alongside (natural units; L = 0 vs the lag arm's lag):\n")
for (b in names(MD)) { b0 <- best_of(b, 0)$block; bL <- best_of(b, L_LAG)$block
  cat(sprintf("    %s: %s\n", b, paste(sprintf("%s %.4g -> %.4g", GS_BLOCK, b0[GS_BLOCK], bL[GS_BLOCK]), collapse = "; "))) }

# ---- B. which rows carry the npp_tsens move -------------------------------------------------------
cat("\n=== B. WHICH ROWS CARRY THE npp_tsens MOVE: streams(block free) - streams(npp_tsens HELD at the base), per cell where the lag moved ===\n")
grp_of <- function(r) { for (g in names(GS_GROUPS)) if (grepl(GS_GROUPS[[g]], r)) return(g); "REST" }
B <- list()
for (b in names(MD)) for (L in GS_LAGS) {
  if (isTRUE(all.equal(L, if (b == "LAG") L_LAG else 0))) next
  fr <- best_of(b, L); hd <- Filter(function(o) o$kind == "B" && o$base == b && isTRUE(all.equal(o$L, L)), ALL)[[1]]
  d <- fr$streams[ROWS] - hd$streams[ROWS]
  gs <- tapply(d, vapply(ROWS, grp_of, ""), sum)
  B[[sprintf("%s_L%g", b, L)]] <- list(rows = d, groups = gs, d_lik = fr$lik - hd$lik, d_logpost = fr$logpost - hd$logpost,
                                      nu_free = fr$block[[GS_GREEN]], nu_held = hd$block[[GS_GREEN]])
  top <- d[order(-abs(d))][1:6]
  cat(sprintf("  %s L %.3f: npp_tsens %+.5f free vs %+.5f held; freeing it buys %+.3f likelihood (%+.3f logpost)\n    by group: %s\n    largest rows: %s\n",
              b, L, fr$block[[GS_GREEN]], hd$block[[GS_GREEN]], fr$lik - hd$lik, fr$logpost - hd$logpost,
              paste(sprintf("%s %+.3f", names(gs), gs), collapse = ", "), paste(sprintf("%s %+.3f", names(top), top), collapse = ", ")))
  pos <- gs[gs > 0]
  cat(sprintf("    the channel by the pre-registered ordering (the largest positive group): %s\n",
              if (length(pos)) names(pos)[which.max(pos)] else "none (no group gains)"))
}

# ---- C. the mechanism's premise --------------------------------------------------------------------------
cat("\n=== C. THE GREENING TERM'S OWN GROWTH SIGNAL vs THE LAND ENSO TERM'S, against Nino 3.4 (section 6's estimator) ===\n")
xdelta <- function(r1, r0) {
  k <- r1$F$year * 12L + r1$F$month; stopifnot(identical(k, r0$F$year * 12L + r0$F$month))
  d <- cen12((r1$out$co2_NH + r1$out$co2_SH) / 2) - cen12((r0$out$co2_NH + r0$out$co2_SH) / 2)
  sel <- k >= GS_WIN[1] * 12L + 1L & k <= GS_WIN[2] * 12L + 12L & is.finite(d)
  tt <- (k[sel] - 1) / 12; dd <- stats::residuals(stats::lm(d[sel] ~ splines::ns(tt, df = GS_TREND_DF)))
  xc <- vapply(GS_XLAGS, function(Lg) stats::cor(dd, r1$F$enso[match(k[sel] - Lg, k)], use = "complete.obs"), 0)
  i <- which.max(abs(xc)); c(peak = GS_XLAGS[i], r_at_peak = xc[i], sd_ppm_yr = stats::sd(dd))
}
C <- list()
for (b in names(MD)) {
  Lb <- if (b == "LAG") L_LAG else 0; blk <- ID[[b]]$block
  r_full <- dg_run(v_cell(b, blk, Lb))
  bg <- blk; bg[[GS_GREEN]] <- 0;  r_ng <- dg_run(v_cell(b, bg, Lb))
  be <- blk; be[GS_AMP] <- 0;      r_ne <- dg_run(v_cell(b, be, Lb))
  C[[b]] <- rbind(greening = xdelta(r_full, r_ng), enso_term = xdelta(r_full, r_ne))
  cat(sprintf("  %s (npp_tsens %+.5f, L %.3f):\n", b, blk[[GS_GREEN]], Lb)); print(round(C[[b]], 4))
  cat(sprintf("    amplitude ratio sd(greening) / sd(ENSO term) = %.3f\n", C[[b]]["greening", "sd_ppm_yr"] / C[[b]]["enso_term", "sd_ppm_yr"]))
}
c1 <- C$CTL["greening", "peak"] > C$CTL["enso_term", "peak"]
c2 <- NU[["CTL"]] < 0 && C$CTL["greening", "r_at_peak"] > 0
cat(sprintf("  PREMISE (pre-registered orderings at the control): (i) the greening signal peaks LATER than the ENSO term: %s (%+d vs %+d months); (ii) at npp_tsens < 0 its correlation at the peak is POSITIVE: %s (%+.3f)\n",
            if (c1) "YES" else "NO", as.integer(C$CTL["greening", "peak"]), as.integer(C$CTL["enso_term", "peak"]),
            if (c2) "YES" else "NO", C$CTL["greening", "r_at_peak"]))

# ---- D. the L = 5 column (descriptive, open item 2) -------------------------------------------------------
cat(sprintf("\n=== D. THE L = %g COLUMN (descriptive; a conditional slice, not a refit) ===\n", GS_LAG_OBS))
FN <- sprintf("%s_%d", names(GS_FUT_SPLICE), GS_FUT_YEAR)
for (b in names(MD)) { o5 <- best_of(b, GS_LAG_OBS); oL <- best_of(b, L_LAG)
  cat(sprintf("  %s: likelihood at L %g minus at L %.3f = %+.3f; npp_tsens %+.5f (at %.3f: %+.5f); beta_max %.4f (%.4f); growth peak %+d months (%+d; observed +%g); r with observed growth %.3f (%.3f); %s %.1f ppm (%.1f); %s %.1f (%.1f)\n",
              b, GS_LAG_OBS, L_LAG, o5$lik - oL$lik, o5$block[[GS_GREEN]], L_LAG, oL$block[[GS_GREEN]], o5$block[[GS_FERT]], oL$block[[GS_FERT]],
              as.integer(o5$runs[["peak_mod"]]), as.integer(oL$runs[["peak_mod"]]), GS_LAG_OBS, o5$runs[["r_mod_obs"]], oL$runs[["r_mod_obs"]],
              FN[1], o5$runs[[FN[1]]], oL$runs[[FN[1]]], FN[2], o5$runs[[FN[2]]], oL$runs[[FN[2]]])) }

sink(); close(LOGCON)
out <- list(cells = tab, all = lapply(ALL, function(o) o[c("base", "L", "kind", "start", "free", "label", "z", "block", "logpost", "lik",
                                                             "streams", "slope", "converged", "rounds", "n_eval", "n_bad", "minutes", "runs")]),
            identity = ID, A = A, verdict_A = verdict_A, B = B, C = C, premise = c(later = c1, positive = c2), newton = A_NU, profile = A_PROF,
            provenance = sprintf(paste0("%s @%s; prereg %s; bases LAG %s, CTL %s; block %s; lags %s; whitened by each base's stored ",
                                        "Hessian; BFGS + Nelder-Mead, slope gate %g; objective #15; no RNG; %s"),
                                 GS_DRIVER, COMMIT, GS_PREREG, GS_BASES[["LAG"]], GS_BASES[["CTL"]], paste(GS_BLOCK, collapse = ","),
                                 paste(round(GS_LAGS, 4), collapse = ","), GS_MODE_TOL, format(Sys.time(), "%Y-%m-%d %H:%M")))
saveRDS(out, paste0(GS_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}\nprovenance: %s\n", GS_OUT, out$provenance))
