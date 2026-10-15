#!/usr/bin/env Rscript
# =====================================================================
# diag_iav_redesign_ridge.R -- IS THE REDESIGN's FUTURES MOVE FORCED BY THE RECORD, OR A POSITION ON THE beta_max RIDGE?
# (CHANGELOG 2026-10-07 e; the test asked of 10-07 d's "+23 ppm" before it is put to Marcus.)
# calibration/diag_iav_redesign_price.R's B2 re-fits the five land names under the redesign (the detrended ENSO index + the
# low-pass gcb_ocean_sink row) at basin B and moves CO2 in 2300 +23 ppm under SSP5-8.5, carried by beta_max (-7.3 %;
# +31.8 ppm, diag_iav_redesign_futures_attr.R). beta_max and fert_k sit on a cor ~0.998 RIDGE: on 09-29 (e) converging a
# re-fit barely moved its cost but moved the futures by tens of ppm. So, two hypotheses:
#   FORCED   the redesign's record prefers the lower beta_max by a margin the re-fit cannot give back;
#   RIDGE    the record is ~indifferent along beta_max once the other land names follow, and B2 is one position on it.
# THE TEST: PROFILE beta_max over RF_GRID with the other four land names re-optimized (whitened by B's stored Hessian
# block; diag_obj17_price.R's B2 method), under #17 as landed (shipped index, ocean row year by year) and under the
# redesign, and read the logpost and the futures along each profile. The price that separates the two readings is the
# logpost difference between beta_max at B's value and at B2's, under each objective.
# Both halves of the redesign are EMULATED exactly as in diag_iav_redesign_price.R (its wrapper and objective, verbatim).
# GATES: B reproduces its stored logpost under #17 (tol 1e-5); at B's own beta_max under #17 the four do not move (B is the
# 29-name optimum: the start's max whitened slope < RF_MODE_TOL); at B2's beta_max under the redesign the profile
# reproduces B2's stored logpost within the re-fit's own convergence bound (1/2 x RF_MODE_TOL^2 per free name).
# Usage: Rscript calibration/diag_iav_redesign_ridge.R [pricing rds]   (CCX_RF_WORKERS, default 6)
# OUTPUTS: outputs/diagnostics/iav_redesign_ridge_<date>.{log,rds}. ⛔ ADOPTS NOTHING. No RNG.
# =====================================================================
t_start <- Sys.time()
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L      # = the pricing's
source(file.path("calibration", "lib_block_reopt.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
RF_DRIVER  <- "calibration/diag_iav_redesign_ridge.R"
RF_ARGS    <- commandArgs(trailingOnly = TRUE)
RF_PRICE   <- if (length(RF_ARGS)) RF_ARGS[1] else file.path("outputs", "diagnostics", "iav_redesign_price_20261007.rds")
RF_HELD    <- "beta_max"
RF_FOLLOW  <- c("fert_k", "luc_scale", "imb_share_land", "ndep_ret")      # the rest of the pricing's B2 block
RF_EXTRA   <- c(1.90, 2.00, 2.05, 2.15)                                   # + B's and B2's own values (below)
# CCX_RF_EXTRA overrides the grid (comma-separated beta_max values; B's and B2's are always added), CCX_RF_TAG suffixes the
# output. Added 10-07 (e) for the WIDE run: the first grid spans about +/-0.5 sigma of the ridge, so its 1-sigma width was a
# quadratic EXTRAPOLATION, and the ridge is known to stiffen away from the mode (memory laplace_fails_on_fertilisation_ridge).
if (nzchar(Sys.getenv("CCX_RF_EXTRA", ""))) RF_EXTRA <- as.numeric(strsplit(Sys.getenv("CCX_RF_EXTRA"), ",")[[1]])
stopifnot(length(RF_EXTRA) > 0, all(is.finite(RF_EXTRA)))
RF_TAG     <- Sys.getenv("CCX_RF_TAG", "")
RF_MODE_TOL <- 0.1; RF_PULL_H <- 0.1; RF_NDEPS <- 0.01; RF_RELTOL <- 1e-12; RF_BFGS_MAXIT <- 200L; RF_NM_MAXIT <- 1500L
RF_ROUNDS  <- 3L                                                          # = the pricing's B2 settings
RF_B2_TOL  <- 0.5 * RF_MODE_TOL^2 * (1 + length(RF_FOLLOW))              # B2's own convergence bound on its logpost
RF_WORKERS <- as.integer(Sys.getenv("CCX_RF_WORKERS", "6"))
RF_OUT <- file.path("outputs", "diagnostics", sprintf("iav_redesign_ridge_%s%s", format(Sys.Date(), "%Y%m%d"),
                                                      if (nzchar(RF_TAG)) paste0("_", RF_TAG) else ""))
COMMIT <- ccx_git_stamp()
`%||%` <- function(a, b) if (is.null(a)) b else a
LOGCON <- file(paste0(RF_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
PR <- readRDS(RF_PRICE); PV <- PR$provenance
cat(sprintf("%s @%s, %s | from %s (%s @%s) | basin B %s | held %s, followed by %s | %d workers\n", RF_DRIVER, COMMIT,
            format(Sys.time(), "%Y-%m-%d %H:%M"), RF_PRICE, PV$driver, PV$commit, PV$mode_b, RF_HELD, paste(RF_FOLLOW, collapse = ", "), RF_WORKERS))
if (!identical(unname(tools::md5sum(PV$mode_b)), PV$mode_b_md5)) stop("basin B's file is not the one the pricing read")
stopifnot(identical(sort(c(RF_HELD, RF_FOLLOW)), sort(PV$block)))

# ---- the redesign's emulation: diag_iav_redesign_price.R's wrapper and objective, verbatim ----------
RP_OCEAN_ROW <- "gcb_ocean_sink"; RP_OCEAN_DF <- PV$ocean_df; RP_OCEAN_SD <- PV$ocean_sd; RP_SHIPPED <- "demean"
.ccx_loglik_shipped <- ccx_loglik
RP_OCEAN_LP <- FALSE
RP_LAST <- new.env()
ccx_loglik <- function(out, obs, err, luc = NULL, deep = NULL, ocean_grad = NULL, by_stream = FALSE, d14c_mid = NULL,
                       npp = NULL, residuals = FALSE) {
  if (!RP_OCEAN_LP)
    return(.ccx_loglik_shipped(out, obs, err, luc = luc, deep = deep, ocean_grad = ocean_grad, by_stream = by_stream,
                               d14c_mid = d14c_mid, npp = npp, residuals = residuals))
  st <- .ccx_loglik_shipped(out, obs, err, luc = luc, deep = deep, ocean_grad = ocean_grad, by_stream = TRUE,
                            d14c_mid = d14c_mid, npp = npp, residuals = TRUE)
  RES <- attr(st, "residuals")
  if (!RP_OCEAN_ROW %in% names(st) || length(RES[[RP_OCEAN_ROW]]) != 1L) stop("the wrapper: no single ", RP_OCEAN_ROW, " residual series")
  e <- RES[[RP_OCEAN_ROW]][[1]]
  lu <- if (is.null(luc)) data.frame(year = obs$gcb$year, eluc = obs$gcb$luc) else luc
  g  <- merge(merge(as.data.frame(obs$gcb)[, c("year", "ocean_sink", "land_sink")], ccx_calendar_flux(out), by = "year"), lu, by = "year")
  if (length(e) != nrow(g)) stop("the wrapper: ", length(e), " ocean residuals for ", nrow(g), " scored GCB years")
  full <- st[[RP_OCEAN_ROW]]
  if (abs(sum(stats::dnorm(e, 0, RP_OCEAN_SD, log = TRUE)) - full) > 1e-8) stop("the wrapper: the residuals do not rebuild the ocean row")
  hc <- ccx_land_highpass_cost(e, g$year, RP_OCEAN_DF, RP_OCEAN_SD)
  assign("full_row", full, envir = RP_LAST); assign("high_cost", hc, envir = RP_LAST)
  st[[RP_OCEAN_ROW]] <- full + hc
  if (!isTRUE(residuals)) attr(st, "residuals") <- NULL
  if (by_stream) return(st)
  ll <- sum(unlist(st)); if (!is.finite(ll)) -Inf else ll
}
MD_B <- readRDS(PV$mode_b); SPF_B <- ccx_spinup_from_label(ccx_mode_spinup(MD_B)); OBS <- ccx_prepare_obs()
P0 <- ccx_mode_pins(MD_B); P0 <- stats::setNames(as.numeric(unclass(P0)), names(P0))
stopifnot(identical(P0, PR$pins$P0))
with_objective <- function(pins, index, FUN) {
  g <- ccx_apply_gate(ccx_mode_struct(MD_B)); on.exit(ccx_unapply_gate(g), add = TRUE)
  r <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(r), add = TRUE, after = FALSE)
  bp <- ccx_mode_base(MD_B); for (n in names(pins)) bp[[n]] <- pins[[n]]; bp$pump_mode <- MD_B$pump_mode
  if (index != RP_SHIPPED) bp$enso_index <- CCX_ENSO_INDEX_CODES[[index]]
  stopifnot(identical(ccx_enso_index_of(bp), index))
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = SPF_B, obs = OBS)
  old <- RP_OCEAN_LP; RP_OCEAN_LP <<- TRUE; on.exit(RP_OCEAN_LP <<- old, add = TRUE)
  ev <- function(over = NULL) {
    pm <- ccx_mode_par_with_pins(MD_B); for (n in names(over)) pm[[n]] <- over[[n]]
    for (k in c("full_row", "high_cost")) if (exists(k, envir = RP_LAST, inherits = FALSE)) rm(list = k, envir = RP_LAST)
    v <- lp(ccx_par_to_unc(pm))
    if (!is.finite(v)) return(list(logpost_lp = -Inf, logpost_full = -Inf))
    s <- attr(v, "streams"); s <- stats::setNames(as.numeric(s), names(s))
    hc <- get("high_cost", envir = RP_LAST); full <- get("full_row", envir = RP_LAST)
    st_full <- s; st_full[[RP_OCEAN_ROW]] <- full
    list(logpost_lp = as.numeric(v), lik_lp = attr(v, "loglik"), prior = as.numeric(v) - attr(v, "loglik"),
         lik_full = attr(v, "loglik") - hc, logpost_full = as.numeric(v) - hc, st_lp = s, st_full = st_full, high_cost = hc)
  }
  FUN(ev)
}

#' The four followers re-optimized with beta_max HELD at `bm` (natural), under `index` with the ocean row `rows`
#' ("lp" the redesign's, "full" #17's); whitened by B's stored Hessian block for the four; from B's own values.
profile_cell <- function(bm, index, rows) {
  U <- chol(br_prec(MD_B, RF_FOLLOW)); u0 <- br_u_of_par(MD_B, RF_FOLLOW); key <- if (rows == "lp") "logpost_lp" else "logpost_full"
  par_of_z <- function(z) { uu <- u0 + backsolve(U, z)
    c(stats::setNames(list(bm), RF_HELD),
      stats::setNames(as.list(vapply(RF_FOLLOW, function(n) .from_unc(uu[[n]], CCX_PARAM_GATED_ALL[[n]] %||% CCX_PARAM_TABLE[[n]]), 0)), RF_FOLLOW)) }
  t0 <- Sys.time()
  o <- with_objective(P0, index, function(ev) {
    f <- function(z) { v <- tryCatch(ev(par_of_z(z))[[key]], error = function(e) -Inf); if (is.finite(v)) -v else 1e10 }
    slope <- function(z) vapply(seq_along(z), function(i) { e <- rep(0, length(z)); e[i] <- RF_PULL_H
      (f(z + e) - f(z - e)) / (2 * RF_PULL_H) }, 0)
    z <- rep(0, length(RF_FOLLOW)); s <- slope(z); s_start <- s; rounds <- 0L
    while (max(abs(s)) >= RF_MODE_TOL && rounds < RF_ROUNDS) {
      rounds <- rounds + 1L
      o1 <- stats::optim(z, f, method = "BFGS", control = list(ndeps = rep(RF_NDEPS, length(z)), reltol = RF_RELTOL, maxit = RF_BFGS_MAXIT))
      o2 <- stats::optim(rep(0, length(z)), function(w) f(o1$par + w), method = "Nelder-Mead", control = list(reltol = RF_RELTOL, maxit = RF_NM_MAXIT))
      z <- o1$par + o2$par; s <- slope(z)
    }
    list(z = z, s = s, s_start = s_start, rounds = rounds, at = ev(par_of_z(z))) })
  par <- unlist(par_of_z(o$z)); at <- o$at
  V <- dg_vector(PV$mode_b); if (index != RP_SHIPPED) V$p$enso_index <- CCX_ENSO_INDEX_CODES[[index]]
  for (n in names(par)) { if (n %in% names(V$p)) V$p[[n]] <- par[[n]]; V$pm[[n]] <- par[[n]] }
  V$p <- ccx_set_enso(V$p, V$pm); V$luc_scale <- V$pm$luc_scale
  list(bm = bm, index = index, rows = rows, par = par, logpost = at[[key]], lik = if (rows == "lp") at$lik_lp else at$lik_full,
       prior = at$prior, st = if (rows == "lp") at$st_lp else at$st_full, rounds = o$rounds, slope_start = max(abs(o$s_start)),
       slope_end = max(abs(o$s)), converged = max(abs(o$s)) < RF_MODE_TOL, futures = br_futures(V, dg_spinup(V)),
       minutes = as.numeric(difftime(Sys.time(), t0, units = "mins")))
}

cat("\n=== 0. GATES ===\n")
g0 <- with_objective(P0, RP_SHIPPED, function(ev) ev())
cat(sprintf("  B under #17 (shipped, year by year): logpost %.6f vs stored %.6f (%+.1e)\n", g0$logpost_full, MD_B$logpost, g0$logpost_full - MD_B$logpost))
if (abs(g0$logpost_full - MD_B$logpost) > 1e-5) stop("basin B does not reproduce its stored logpost")
BM_B <- MD_B$par_mode[[RF_HELD]]; BM_B2 <- PR$b2_block[[RF_HELD]]
GRID <- sort(unique(c(RF_EXTRA, BM_B, BM_B2)))
CELLS <- expand.grid(bm = GRID, obj = c("obj17", "redesign"), stringsAsFactors = FALSE)
cat(sprintf("  the grid: %s = %s (B %.5f, B2 %.5f); %d cells on %d workers\n", RF_HELD, paste(sprintf("%.4f", GRID), collapse = ", "), BM_B, BM_B2,
            nrow(CELLS), RF_WORKERS))
RES <- parallel::mclapply(seq_len(nrow(CELLS)), function(i) { while (sink.number() > 0L) sink()
  if (CELLS$obj[i] == "obj17") profile_cell(CELLS$bm[i], RP_SHIPPED, "full") else profile_cell(CELLS$bm[i], PV$index, "lp") },
  mc.cores = RF_WORKERS)
bad <- vapply(RES, inherits, logical(1), "try-error"); if (any(bad)) stop("a profile cell failed: ", paste(unlist(RES[bad]), collapse = " | "))
TAB <- do.call(rbind, lapply(RES, function(r) data.frame(obj = if (r$index == RP_SHIPPED) "obj17" else "redesign", beta_max = r$bm,
  logpost = r$logpost, lik = r$lik, prior = r$prior, fert_k = r$par[["fert_k"]], luc_scale = r$par[["luc_scale"]], ndep_ret = r$par[["ndep_ret"]],
  ssp585 = r$futures[["ssp585"]], vvH = r$futures[["vvH"]], icecores = sum(r$st[grep("icecore", names(r$st))]),
  co2_levels = sum(r$st[grep("^co2_level_", names(r$st))]), rounds = r$rounds, slope0 = r$slope_start, slope1 = r$slope_end, conv = r$converged)))
k17 <- TAB$obj == "obj17" & abs(TAB$beta_max - BM_B) < 1e-12; kR <- TAB$obj == "redesign" & abs(TAB$beta_max - BM_B2) < 1e-12
cat(sprintf("  at B's own %s under #17 the four start at max whitened slope %.3f (tol %.1f) and move the logpost %+.1e\n", RF_HELD,
            TAB$slope0[k17], RF_MODE_TOL, TAB$logpost[k17] - MD_B$logpost))
if (TAB$slope0[k17] >= RF_MODE_TOL) stop("B is not the four followers' conditional optimum under #17")
b2_lp <- PR$b2$logpost_lp
cat(sprintf("  at B2's %s under the redesign the profile's logpost %.6f vs the pricing's B2 %.6f (%+.1e; bound %.3f); futures %+.2f / %+.2f ppm off B2's\n",
            RF_HELD, TAB$logpost[kR], b2_lp, TAB$logpost[kR] - b2_lp, RF_B2_TOL, TAB$ssp585[kR] - PR$futures["B2", "ssp585"], TAB$vvH[kR] - PR$futures["B2", "vvH"]))
if (abs(TAB$logpost[kR] - b2_lp) > RF_B2_TOL) stop("the redesign's profile does not reproduce B2 at B2's beta_max")
if (!all(TAB$conv)) cat(sprintf("  ⚠ %d cell(s) did not converge (max whitened slope >= %.1f): read them as bounds\n", sum(!TAB$conv), RF_MODE_TOL))

cat(sprintf("\n=== THE PROFILES: %s held, %s re-optimised; logpost relative to each profile's best grid point ===\n", RF_HELD, paste(RF_FOLLOW, collapse = ", ")))
for (o in c("obj17", "redesign")) {
  T <- TAB[TAB$obj == o, ]; T <- T[order(T$beta_max), ]; best <- max(T$logpost)
  cat(sprintf("\n  %s (%s)\n  %9s %10s %9s %9s %9s %8s %10s %9s %9s %10s\n", o, if (o == "obj17") "shipped index, ocean row year by year" else
              sprintf("'%s' index, ocean row low-pass", PV$index), RF_HELD, "dlogpost", "dlik", "dprior", "fert_k", "ndep_ret", "SSP5-8.5", "vvH",
              "icecores", "CO2 lvls"))
  for (i in seq_len(nrow(T))) cat(sprintf("  %9.4f %+10.3f %+9.3f %+9.3f %9.2f %8.3f %10.2f %9.2f %+10.3f %+9.3f%s\n", T$beta_max[i], T$logpost[i] - best,
       T$lik[i] - T$lik[which.max(T$logpost)], T$prior[i] - T$prior[which.max(T$logpost)], T$fert_k[i], T$ndep_ret[i], T$ssp585[i], T$vvH[i],
       T$icecores[i] - T$icecores[which.max(T$logpost)], T$co2_levels[i] - T$co2_levels[which.max(T$logpost)],
       paste0(if (abs(T$beta_max[i] - BM_B) < 1e-12) "  <- B" else "", if (abs(T$beta_max[i] - BM_B2) < 1e-12) "  <- B2" else "",
              if (!T$conv[i]) "  (not converged)" else "")))
}
pr <- function(o, a, b) { T <- TAB[TAB$obj == o, ]; T$logpost[abs(T$beta_max - a) < 1e-12] - T$logpost[abs(T$beta_max - b) < 1e-12] }
fu <- function(o, a, b) { T <- TAB[TAB$obj == o, ]; T$ssp585[abs(T$beta_max - a) < 1e-12] - T$ssp585[abs(T$beta_max - b) < 1e-12] }
cat(sprintf("\n  logpost at B2's %s MINUS at B's (the four re-optimised at each): under #17 %+.3f, under the redesign %+.3f\n",
            RF_HELD, pr("obj17", BM_B2, BM_B), pr("redesign", BM_B2, BM_B)))
cat(sprintf("  the futures between the same two points (SSP5-8.5 2300, B2's minus B's): %+.2f ppm under #17, %+.2f under the redesign\n",
            fu("obj17", BM_B2, BM_B), fu("redesign", BM_B2, BM_B)))

saveRDS(list(table = TAB, cells = RES, grid = GRID, beta_max_b = BM_B, beta_max_b2 = BM_B2,
             provenance = list(driver = RF_DRIVER, commit = COMMIT, price = RF_PRICE, price_commit = PV$commit, mode_b = PV$mode_b,
                               mode_b_md5 = PV$mode_b_md5, index = PV$index, held = RF_HELD, follow = RF_FOLLOW, grid = GRID, tag = RF_TAG,
                               tols = c(mode = RF_MODE_TOL, pull_h = RF_PULL_H, ndeps = RF_NDEPS, reltol = RF_RELTOL, bfgs = RF_BFGS_MAXIT,
                                        nm = RF_NM_MAXIT, rounds = RF_ROUNDS, b2 = RF_B2_TOL), workers = RF_WORKERS,
                               futures = paste(names(BR_FUT_SPLICE), collapse = "+"), year = BR_FUT_YEAR, date = format(Sys.time(), "%Y-%m-%d %H:%M"),
                               rng = "none", units = "log-likelihood units; CO2 ppm")), paste0(RF_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds} | %.1f min\n⛔ ADOPTS NOTHING.\n", RF_OUT, as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
sink(); close(LOGCON)
