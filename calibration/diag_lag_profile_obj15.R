#!/usr/bin/env Rscript
# diag_lag_profile_obj15.R -- D3: HOW OBJECTIVE #15 IDENTIFIES THE LAND ENSO LAG, before the refit.
#
# The 10-02h handoff (sec. 2, D3): "After W1-W3, profile the NEW objective over L in a committed
# script, with the ENSO amplitude re-optimized." Two readings disagreed before #15 existed: a
# conditional probe by the audit (not reproduced) had the rows preferring 2-3 months, through the
# GCB land sink and the seasonal-coefficient rows; the growth rate's own timing says 5 (10-02 x:
# observed growth peaks 5 months after Nino 3.4, r 0.50). This measures it on #15.
#
# THE PROFILE IS CONDITIONAL: at each lag L the two LAND ENSO amplitudes (gamma_enso_land_NH/SH;
# the ocean pair is PINNED at 0 in hilda33d) are re-optimized on the full #15 LOGPOST, and every
# other name stays at hilda33d's restamped mode. The joint answer is the refit's (D5); this says
# what the rows want and which rows want it.
#   P1 the profile: logpost, likelihood and every stream at each L, the amplitudes' optimum.
#      L = 0 is scored EXACTLY, under the lag-0 label kaidgb (the D2 control's objective); L > 0
#      under the lag label kaidgbe, whose lag prior (flat on (0, 12)) adds its logit Jacobian to
#      the logpost and nothing to the likelihood -- so COMPARE ON LIKELIHOOD.
#   P2 the rows: each stream's move from L = 0 at the likelihood's best L, largest first.
#   P3 the timing the profile buys: the model's monthly growth (centered 12-month difference of
#      global CO2, spline-detrended, 1980-2024) against Nino 3.4 -- the lag of peak correlation
#      at each L, beside the OBSERVED peak from NOAA's MBL global record (10-02 x's estimator).
# No RNG. Run from the repo root:  Rscript calibration/diag_lag_profile_obj15.R
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) ----------------
ARM        <- "hilda33d"                      # the canonical, restamped under #15
LABEL_LAG  <- "hilda_csl3v0kaidgbe"           # the lag arm's label
LABEL_ZERO <- "hilda_csl3v0kaidgb"            # the lag-0 control's label (= the file's own)
LAGS       <- c(0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 6, 7, 8, 9, 10, 11)   # months
AMP        <- c("gamma_enso_land_NH", "gamma_enso_land_SH")
NM_RELTOL  <- 1e-9;  NM_MAXIT <- 400L          # the amplitudes' Nelder-Mead, per L (1e-9 of ~1200 = ~1e-6 log-units)
WIN        <- c(1980L, 2024L)                 # = 10-02 (x)'s window
TREND_DF   <- 5L                              # = 10-02 (x)'s detrending spline
XLAGS      <- -6:18                           # months; > 0 = Nino 3.4 LEADS growth
OBS_WEEKLY <- file.path("data-raw", "downloads", "mbl_zonal_co2_GL.txt")
DRIVER     <- "calibration/diag_lag_profile_obj15.R"
OUT_STEM   <- file.path("outputs", "diagnostics", sprintf("lag_profile_obj15_%s", format(Sys.Date(), "%Y%m%d")))

commit <- ccx_git_stamp()
dirty  <- ccx_stamp_dirty(commit)   # the rds keeps `dirty`: TRUE / FALSE / NA = git could not tell
sink(paste0(OUT_STEM, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s | arm %s | lag label %s, lag-0 label %s\n", DRIVER, commit,
            format(Sys.time(), "%Y-%m-%d %H:%M"), ARM,
            LABEL_LAG, LABEL_ZERO))
stopifnot(isTRUE(LIK_USE_ICE_D13C), identical(LIK_ICE_CO2_END, 1958))   # objective #15

md  <- readRDS(ccx_mode_file(ARM))
stopifnot(identical(ccx_mode_struct(md), LABEL_ZERO))
obs <- ccx_prepare_obs()
spinup_fn <- ccx_spinup_from_label(ccx_mode_spinup(md))
base0 <- ccx_mode_base(md); if (!is.null(md$pump_mode)) base0$pump_mode <- md$pump_mode
baseL <- base0; baseL[[CCX_GATE_FLAG_ENSO_LAG]] <- 1L
stopifnot(identical(ccx_gates_open(baseL), ccx_gates_open(LABEL_LAG)))

# the amplitudes' conditional optimum on one objective, from a start
opt_amp <- function(lp, u, start) {
  f <- function(a) { uu <- u; uu[AMP] <- a; v <- as.numeric(lp(uu)); if (is.finite(v)) -v else 1e10 }
  o <- stats::optim(start, f, method = "Nelder-Mead", control = list(reltol = NM_RELTOL, maxit = NM_MAXIT))
  uu <- u; uu[AMP] <- o$par
  v <- lp(uu)
  list(u = uu, logpost = as.numeric(v), streams = unlist(attr(v, "streams")), conv = o$convergence,
       evals = o$counts[["function"]])
}
# one gate state at a time: the gate, the file's pins, the file's start, the objective
in_gate <- function(label, base, f) {
  g <- ccx_apply_gate(label); r <- ccx_apply_pins(ccx_mode_pins(md))
  on.exit({ ccx_unpin_params(r); ccx_unapply_gate(g) }, add = TRUE)
  invisible(utils::capture.output(st <- ccx_mode_start(md, "lag profile")))
  lp <- ccx_make_logpost(base_params = base, by_stream = TRUE, spinup_fn = spinup_fn, obs = obs)
  f(lp, st)
}

# ---- P1 the profile -----------------------------------------------------------------
cat("\n=== P1. The conditional profile over L (land ENSO amplitudes re-optimised; all else at the mode) ===\n")
res <- list()
amp0 <- unlist(md$par_mode[AMP])
res[["0"]] <- in_gate(LABEL_ZERO, base0, function(lp, st) {
  o <- opt_amp(lp, st$u, st$u[AMP]); o$lag <- 0; o$logpost_mode <- as.numeric(lp(st$u)); o })
cat(sprintf("  L = 0 (exact, %s): logpost at the stored mode %.4f; amplitudes re-optimised -> %.4f\n",
            LABEL_ZERO, res[["0"]]$logpost_mode, res[["0"]]$logpost))
pos <- LAGS[LAGS > 0]
in_gate(LABEL_LAG, baseL, function(lp, st) {
  spec <- CCX_PARAM_GATED_ALL$lag_enso_land
  start <- res[["0"]]$u[AMP]
  for (L in pos) {
    u <- st$u; u[["lag_enso_land"]] <- .to_unc(L, spec)
    o <- opt_amp(lp, u, start); o$lag <- L
    res[[format(L)]] <<- o; start <- o$u[AMP]                       # continuation
  }
})
tab <- do.call(rbind, lapply(res, function(o) {
  a <- ccx_unc_to_par(o$u[AMP])
  data.frame(lag = o$lag, logpost = o$logpost, lik = sum(o$streams), g_NH = a[[AMP[1]]], g_SH = a[[AMP[2]]],
             conv = o$conv, evals = o$evals)
}))
tab <- tab[order(tab$lag), ]; tab$d_lik <- tab$lik - tab$lik[tab$lag == 0]
print(tab, digits = 6, row.names = FALSE)
best <- tab$lag[which.max(tab$lik)]
cat(sprintf("  best L on the LIKELIHOOD: %g months (d lik vs L = 0: %+.3f)\n", best, max(tab$d_lik)))

# ---- P2 the rows ---------------------------------------------------------------------
cat(sprintf("\n=== P2. Each stream's move from L = 0, at L = %g and at L = 5 (the observed timing) ===\n", best))
S0 <- res[["0"]]$streams
for (L in unique(c(best, 5))) {
  d <- res[[format(L)]]$streams - S0[names(res[[format(L)]]$streams)]
  d <- d[order(-abs(d))]; d <- d[abs(d) > 0.01]
  cat(sprintf("  L = %g: %s\n", L, paste(sprintf("%s %+.3f", names(d), d), collapse = ", ")))
}
cat("  every stream at every L (d vs L = 0):\n")
D <- sapply(res[order(sapply(res, `[[`, "lag"))], function(o) o$streams - S0[names(o$streams)])
colnames(D) <- sprintf("L%g", sort(sapply(res, `[[`, "lag")))
keep <- apply(abs(D), 1, max) > 0.05
print(round(D[keep, , drop = FALSE], 3))

# ---- P3 the timing ----------------------------------------------------------------------
cat("\n=== P3. Growth timing against Nino 3.4 (centred 12-month difference, ns(df) detrended) ===\n")
v0 <- dg_vector(ARM)
cen12 <- function(x) { n <- length(x); g <- rep(NA_real_, n); i <- 7:(n - 6); g[i] <- x[i + 6] - x[i - 6]; g }
wk <- utils::read.table(OBS_WEEKLY, comment.char = "#")
mo <- stats::aggregate(list(co2 = wk$V5), list(year = wk$V1, month = wk$V2), mean)
mo <- mo[order(mo$year, mo$month), ]
obs_g <- data.frame(k = mo$year * 12L + mo$month, g = cen12(mo$co2))
timing <- function(out, F) {
  m <- data.frame(k = F$year * 12L + F$month, g = cen12((out$co2_NH + out$co2_SH) / 2), nino = F$enso)
  M <- merge(m, obs_g, by = "k", suffixes = c("_mod", "_obs"))
  M <- M[M$k >= WIN[1] * 12L + 1L & M$k <= WIN[2] * 12L + 12L & stats::complete.cases(M), ]
  tt <- (M$k - 1) / 12
  detr <- function(g) stats::residuals(stats::lm(g ~ splines::ns(tt, df = TREND_DF)))
  xc <- sapply(XLAGS, function(L) {
    n <- m$nino[match(M$k - L, m$k)]
    c(mod = stats::cor(detr(M$g_mod), n, use = "complete.obs"), obs = stats::cor(detr(M$g_obs), n, use = "complete.obs"))
  })
  c(peak_mod = XLAGS[which.max(xc["mod", ])], r_mod = max(xc["mod", ]),
    peak_obs = XLAGS[which.max(xc["obs", ])], r_obs = max(xc["obs", ]),
    r_mod_obs = stats::cor(detr(M$g_mod), detr(M$g_obs)))
}
TT <- do.call(rbind, lapply(res[order(sapply(res, `[[`, "lag"))], function(o) {
  a <- ccx_unc_to_par(o$u[AMP]); v <- v0
  for (n in AMP) { v$p[[n]] <- a[[n]]; v$pm[[n]] <- a[[n]] }
  v$p$lag_enso_land <- o$lag
  r <- dg_run(v)
  data.frame(lag = o$lag, t(timing(r$out, r$F)))
}))
print(TT, digits = 3, row.names = FALSE)

saveRDS(list(profile = tab, streams = D, timing = TT, best_lik = best,
             provenance = list(driver = DRIVER, commit = commit, dirty = dirty, arm = ARM,
                               lag_label = LABEL_LAG, zero_label = LABEL_ZERO, lags = LAGS, amp = AMP,
                               win = WIN, trend_df = TREND_DF, rng = "none", objective = "#15",
                               date = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(OUT_STEM, ".rds"))
cat(sprintf("\nprovenance: %s @%s; arm %s (%s spinup), objective #15; L = 0 under %s, L > 0 under %s; no RNG\n",
            DRIVER, commit, ARM, ccx_mode_spinup(md),
            LABEL_ZERO, LABEL_LAG))
sink()
