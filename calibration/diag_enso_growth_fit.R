#!/usr/bin/env Rscript
# diag_enso_growth_fit.R -- WHY switching ENSO off does not worsen the app's growth-rate fit
#
# Marcus 2026-10-02: "ENSO doesn't seem to have much effect over the 1980-2024 period (turning it
# off actually improves the fit by 1%!). Why?"
#
# The What-if readout's "typical miss" is the RMS of (model - observed) annual CO2 growth over the
# window, on the app's OWN estimator (app_annual_growth() against APP_OBS_GROWTH: calendar-year
# means differenced, NOAA MBL global). This script MEASURES five candidate explanations instead of
# arguing for one:
#   T1 THE ARITHMETIC. Adding a component x to the model lowers the RMS only if x correlates with
#      the gap it should fill (observed - model without it) by more than sd(x) / (2 sd(gap)).
#      Reports corr, that threshold, and the least-squares amplitude a* (a* < 0.5 => adding x at
#      full strength RAISES the RMS even though x is "right" in part).
#   T2 TIMING. (a) Shift the index the model reads by k months (k > 0 = the model responds LATER)
#      and re-run. (b) Monthly cross-correlation of observed and modelled growth with Nino 3.4,
#      on a centred 12-month difference that is identical for both.
#   T3 LAND vs OCEAN. The land term alone (the pre-10-02 switch: gamma_enso_* = 0, the ocean still
#      reading the index) against the ocean's ENSO channels (the rest of the index-zeroed effect).
#   T4 AMPLITUDE. The index scaled by s.
#   T5 IS "1 %" REAL. Moving-block bootstrap of the RMS change, and the per-year ledger.
#   T6 the whole index read at the OBSERVED lag (from T2(b)), with a bootstrap error bar.
#   T7 the LAND term alone read late (DESIGN.md's never-built L_MEI), ocean on time.
# Nothing here changes the model or the app. Parameters: the app's (APP_PARAMS, the canonical
# mode via ccx_mode_file()). Run from the repo root.

t_start <- Sys.time()
ROOT <- normalizePath(getwd())
stopifnot(file.exists(file.path(ROOT, "app", "global.R")))
setwd(file.path(ROOT, "app"))
invisible(capture.output(suppressMessages(suppressWarnings(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv())))))
setwd(ROOT)

# ---- named constants (every label below derives from these) ----------------
WIN        <- c(1980L, 2024L)  # the readout's window at the default slider: observed record x 1850-2024
SHIFTS     <- c(-6L, -3L, 0L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 10L, 12L)   # months; > 0 = model reads the index LATER
SCALES     <- c(0, 0.5, 1, 1.5, 2, 3)                                 # multiplier on the index
LAGS       <- -6:18            # months; > 0 = the index LEADS the growth rate
TREND_DF   <- 5L               # natural-spline df removing the multi-decadal trend in T2(b)
BOOT_N     <- 2000L            # T5 resamples
BOOT_BLOCK <- 3L               # years per block (ENSO's ~3-7 yr quasi-period keeps neighbours dependent)
SEED       <- 20261002L        # T5 only; set IMMEDIATELY before the bootstrap's sample.int calls
OBS_WEEKLY <- file.path("data-raw", "downloads", "mbl_zonal_co2_GL.txt")
# the date AND the mode the app loaded (2026-10-03): the 10-02 run's stem was a typed date, so a re-run
# at another mode -- the objective-#15 candidate, read before adoption -- would have overwritten it.
# The 10-02 outputs keep their name (enso_growth_fit_20261002.*, at hilda33d).
OUT_STEM   <- file.path("outputs", "diagnostics", sprintf("enso_growth_fit_%s_%s", format(Sys.Date(), "%Y%m%d"), CCX_MODE_CANONICAL))

commit <- ccx_git_stamp()
dirty  <- ccx_stamp_dirty(commit)   # the rds keeps `dirty`: TRUE / FALSE / NA = git could not tell
mode_file <- tryCatch(ccx_mode_file(), error = function(e) NA_character_)
cat(sprintf("diag_enso_growth_fit | commit %s | mode %s | window %d-%d\n",
            commit, basename(dirname(mode_file)),
            WIN[1], WIN[2]))

# ---- the app's estimator, reproduced and GATED against the app's own function ----
obs <- app_obs_growth(APP_OBS_GROWTH)
fit <- function(out) {
  m <- app_annual_growth(out)
  d <- merge(m, obs, by = "year", suffixes = c("_mod", "_obs"))
  d <- d[d$year >= WIN[1] & d$year <= WIN[2], ]
  e <- d$g_mod - d$g_obs
  list(year = d$year, g = d$g_mod, obs = d$g_obs, e = e,
       rms = sqrt(mean(e^2)), bias = mean(e), n = nrow(d))
}

F0  <- suppressWarnings(app_build_forcing("historical", APP_HIST_YEARS, prod_c14 = 0))
sp0 <- app_spinup(APP_PARAMS)
run_F <- function(F, sp = sp0) {
  F$c14_cosmo <- sp$prod_c14
  r <- ccx_run_fast(sp, F)
  r$out$co2_global <- (r$out$co2_NH + r$out$co2_SH) / 2
  r$out
}

full    <- run_F(F0)
off_app <- app_run_mechanisms("enso")$out            # the app's switch, exactly as the readout runs it
r_app   <- app_growth_residuals(APP_HIST$out, off_app, APP_OBS_GROWTH, WIN)
f_full  <- fit(full); f_off <- fit(off_app)
# GATES: this script must be measuring the readout's numbers, not a neighbour of them.
d_full <- max(abs(f_full$g - fit(APP_HIST$out)$g))
stopifnot(d_full < 1e-6,
          abs(f_full$rms - r_app$full$rms) < 1e-6, abs(f_off$rms - r_app$alt$rms) < 1e-6)
# ...and index-zeroed with the ORIGINAL parameters must equal the app's switch (which also zeroes
# the coefficients): the T4 scale-0 arm relies on it.
F_zero <- F0; F_zero$enso <- 0
f_zero <- fit(run_F(F_zero))
d_zero <- max(abs(f_zero$g - f_off$g))
cat(sprintf("gates: full vs APP_HIST %.1e; index-zeroed vs app switch %.1e ppm/yr\n", d_full, d_zero))
stopifnot(d_zero < 1e-6)

pct <- function(a, b) 100 * (1 - b / a)   # "% closer to the data" exactly as the readout prints it
cat(sprintf("\nREADOUT: full RMS %.4f, ENSO off %.4f ppm/yr => %+.2f%% (positive = OFF is closer)\n",
            f_full$rms, f_off$rms, pct(f_full$rms, f_off$rms)))
cat(sprintf("         bias full %+.4f, off %+.4f; n = %d years\n", f_full$bias, f_off$bias, f_full$n))

# ---- T1: the arithmetic of adding a component ----------------------------
t1 <- function(x, gap, label) {
  a_star <- sum(x * gap) / sum(x^2)                  # least-squares amplitude through the origin (raw RMS)
  r  <- stats::cor(x, gap)
  th <- stats::sd(x) / (2 * stats::sd(gap))
  data.frame(component = label, sd_x = stats::sd(x), sd_gap = stats::sd(gap), corr = r,
             corr_needed = th, a_star = a_star, stringsAsFactors = FALSE)
}
gap_off <- f_off$obs - f_off$g                        # what the no-ENSO model leaves unexplained
x_enso  <- f_full$g - f_off$g                         # what ENSO adds to the model
T1 <- t1(x_enso, gap_off, "ENSO (index zeroed)")

# ---- T3: land vs ocean ----------------------------------------------------
p_land  <- ccx_set_enso(APP_PARAMS, list(gamma_enso = 0))   # the PRE-10-02 switch: land term only
sp_land <- app_spinup(p_land)
f_land  <- fit(run_F(F0, sp_land))                    # ocean still reads the index
x_land  <- f_full$g - f_land$g                        # land's ENSO term (with the ocean's on)
x_ocn   <- f_land$g - f_off$g                         # the ocean's ENSO channels (with land's off)
stopifnot(max(abs(x_land + x_ocn - x_enso)) < 1e-9)   # the two pieces sum to the whole, by construction
T1 <- rbind(T1, t1(x_land, gap_off, "land term only"), t1(x_ocn, gap_off, "ocean channels only"))
cat("\nT1/T3: does each ENSO component fill the gap the no-ENSO model leaves?\n")
cat("       (it lowers the RMS only if corr > corr_needed; a* = best amplitude, 1 = as modelled)\n")
print(T1, digits = 3, row.names = FALSE)
cat(sprintf("pre-10-02 switch (land term only off): RMS %.4f => %+.2f%% vs full\n",
            f_land$rms, pct(f_full$rms, f_land$rms)))

# ---- T2(a): shift the index the model reads -------------------------------
shift_vec <- function(v, k) {
  n <- length(v)
  if (k == 0L) v else if (k > 0L) c(rep(0, k), v[seq_len(n - k)]) else c(v[(1L - k):n], rep(v[n], -k))
}
T2a <- do.call(rbind, lapply(SHIFTS, function(k) {
  F <- F0; F$enso <- shift_vec(F0$enso, k)
  f <- fit(run_F(F))
  x <- f$g - f_off$g
  data.frame(shift_months = k, rms = f$rms, pct_vs_off = pct(f_off$rms, f$rms),
             corr_x_gap = stats::cor(x, gap_off), a_star = sum(x * gap_off) / sum(x^2))
}))
cat("\nT2(a): the index read k months LATE (k > 0). pct_vs_off > 0 = better than ENSO off\n")
print(T2a, digits = 3, row.names = FALSE)

# ---- T2(b): monthly timing against Nino 3.4 --------------------------------
wk <- utils::read.table(OBS_WEEKLY, comment.char = "#")
mo <- stats::aggregate(list(co2 = wk$V5), list(year = wk$V1, month = wk$V2), mean)
mo <- mo[order(mo$year, mo$month), ]
cen12 <- function(x) { n <- length(x); g <- rep(NA_real_, n); i <- 7:(n - 6); g[i] <- x[i + 6] - x[i - 6]; g }
obs_m <- data.frame(year = mo$year, month = mo$month, g = cen12(mo$co2))
mod_m <- function(out) {
  # the run's months ARE the forcing's rows; read them there rather than re-deriving a month from
  # a decimal time (round-half-even and float error both bite that) -- and gate the identity
  stopifnot(nrow(out) == nrow(F0), max(abs(out$t - F0$t)) < 1e-9)
  data.frame(year = F0$year, month = F0$month, g = cen12(ccx_global_co2(out)))
}
key <- function(d) d$year * 12L + d$month
idx <- data.frame(k = F0$year * 12L + F0$month, nino = F0$enso)
M <- merge(merge(transform(obs_m, k = key(obs_m))[, c("k", "g")],
                 transform(mod_m(full), k = key(mod_m(full)))[, c("k", "g")], by = "k",
                 suffixes = c("_obs", "_full")),
           transform(mod_m(off_app), k = key(mod_m(off_app)))[, c("k", "g")], by = "k")
names(M)[names(M) == "g"] <- "g_off"
M <- M[M$k >= WIN[1] * 12L + 1L & M$k <= WIN[2] * 12L + 12L & stats::complete.cases(M), ]
M <- M[order(M$k), ]
tt <- (M$k - 1) / 12
detr <- function(g) stats::residuals(stats::lm(g ~ splines::ns(tt, df = TREND_DF)))
S <- list(observed = detr(M$g_obs), model_full = detr(M$g_full),
          enso_component = M$g_full - M$g_off, gap_left_by_off = detr(M$g_obs - M$g_off))
nino_at <- function(L) idx$nino[match(M$k - L, idx$k)]
xc <- do.call(rbind, lapply(LAGS, function(L) {
  n <- nino_at(L)
  data.frame(lag = L, t(vapply(S, function(s) stats::cor(s, n, use = "complete.obs"), numeric(1))))
}))
peak <- vapply(names(S), function(s) xc$lag[which.max(xc[[s]])], numeric(1))
cat(sprintf("\nT2(b): corr with Nino 3.4 LEADING by L months (monthly, centred 12-mo growth, %d-%d)\n",
            WIN[1], WIN[2]))
print(xc[xc$lag %in% c(-3, 0, 2, 3, 4, 5, 6, 7, 8, 10, 12), ], digits = 2, row.names = FALSE)
cat("peak lag (months):", paste(sprintf("%s %d (r %.2f)", names(S), as.integer(peak),
    vapply(names(S), function(s) max(xc[[s]]), numeric(1))), collapse = "; "), "\n")

# ---- T4: amplitude ----------------------------------------------------------
T4 <- do.call(rbind, lapply(SCALES, function(s) {
  F <- F0; F$enso <- s * F0$enso
  f <- fit(run_F(F))
  data.frame(scale = s, rms = f$rms, pct_vs_off = pct(f_off$rms, f$rms))
}))
cat("\nT4: the index scaled by s (1 = as fitted). pct_vs_off > 0 = better than ENSO off\n")
print(T4, digits = 3, row.names = FALSE)

# ---- T6/T7: the index read at the OBSERVED lag -------------------------------
# The lag is taken from T2(b)'s OBSERVED cross-correlation, NOT from T2(a)'s RMS search, so the
# improvement below is not the best of twelve tries. T6 delays the whole index (land + ocean);
# T7 delays the LAND term only, with the ocean on time -- DESIGN.md's F_ENSO = gamma * MEI(t - L)
# was a land term. T7 is built by SUPERPOSITION (the land term's own contribution under the
# delayed index, added to the run whose land term is off and whose ocean reads the index on
# time): exact at L = 0 (gated below), second-order in the land-ocean interaction otherwise.
L_OBS  <- as.integer(peak[["observed"]])
T7_LAGS <- c(0L, 3L, 4L, 5L, 6L, 7L, 8L)
late_F <- function(k) { F <- F0; F$enso <- shift_vec(F0$enso, k); F }
land_late <- function(k) {
  Fk <- late_F(k)
  f_land$g + (fit(run_F(Fk))$g - fit(run_F(Fk, sp_land))$g)
}
stopifnot(max(abs(land_late(0L) - f_full$g)) < 1e-9)
f_T6 <- fit(run_F(late_F(L_OBS)))
T7 <- do.call(rbind, lapply(T7_LAGS, function(k) {
  e <- land_late(k) - f_full$obs
  data.frame(land_lag_months = k, rms = sqrt(mean(e^2)), pct_vs_off = pct(f_off$rms, sqrt(mean(e^2))))
}))
e_T7 <- land_late(L_OBS) - f_full$obs
cat(sprintf("\nT6/T7: the observed lag from T2(b) is %d months.\n", L_OBS))
cat(sprintf("T6 whole index %d months late: RMS %.4f (%+.1f%% vs off, %+.1f%% vs full)\n", L_OBS,
            f_T6$rms, pct(f_off$rms, f_T6$rms), pct(f_full$rms, f_T6$rms)))
cat("T7 LAND term late by k months, ocean on time (superposition):\n")
print(T7, digits = 3, row.names = FALSE)

# ---- T5 (+ T6/T7 error bars): is the difference real? ------------------------
# One set of block resamples, drawn ONCE, serves every comparison (paired). The draws are made in
# the same order as the first version of this script drew them, so T5's numbers are unchanged.
n  <- f_full$n; nb <- ceiling(n / BOOT_BLOCK)
set.seed(SEED)   # <- the ONLY RNG use in this script, immediately before it
IDX <- replicate(BOOT_N, {
  st <- sample.int(n - BOOT_BLOCK + 1L, nb, replace = TRUE)
  unlist(lapply(st, function(s) s:(s + BOOT_BLOCK - 1L)))[seq_len(n)]
}, simplify = FALSE)
rms_i <- function(e, i) sqrt(mean(e[i]^2))
boot <- vapply(IDX, function(i) pct(rms_i(f_full$e, i), rms_i(f_off$e, i)), numeric(1))
q <- stats::quantile(boot, c(0.05, 0.5, 0.95))
qb <- function(e) stats::quantile(vapply(IDX, function(i) pct(rms_i(f_off$e, i), rms_i(e, i)), numeric(1)),
                                  c(0.05, 0.5, 0.95))
q6 <- qb(f_T6$e); q7 <- qb(e_T7)
cat(sprintf("T6 vs ENSO off, %% closer: median %+.1f, 90%% [%+.1f, %+.1f]\n", q6[2], q6[1], q6[3]))
cat(sprintf("T7 vs ENSO off, %% closer: median %+.1f, 90%% [%+.1f, %+.1f]\n", q7[2], q7[1], q7[3]))
cat(sprintf("\nT5: %% closer with ENSO off, %d-yr block bootstrap (%d draws, seed %d): median %+.1f, 90%% [%+.1f, %+.1f]\n",
            BOOT_BLOCK, BOOT_N, SEED, q[2], q[1], q[3]))
nino_ann <- stats::aggregate(list(nino = F0$enso), list(year = F0$year), mean)
L <- data.frame(year = f_full$year, nino = nino_ann$nino[match(f_full$year, nino_ann$year)],
                obs = f_full$obs, full = f_full$g, off = f_off$g,
                e_full = f_full$e, e_off = f_off$e, d_sq = f_full$e^2 - f_off$e^2)
L <- L[order(-L$d_sq), ]
cat("years where ENSO HURTS most (d_sq > 0 = full model further from the data):\n")
print(utils::head(L, 6), digits = 3, row.names = FALSE)
cat("years where ENSO HELPS most:\n")
print(utils::tail(L, 6), digits = 3, row.names = FALSE)
cat(sprintf("sum d_sq %+.3f; hurts in %d of %d years\n", sum(L$d_sq), sum(L$d_sq > 0), nrow(L)))

# ---- save, with provenance ---------------------------------------------------
res <- list(
  provenance = list(script = "calibration/diag_enso_growth_fit.R", commit = commit, dirty = dirty,
                    mode_file = mode_file, window = WIN,
                    estimator = "app_annual_growth() vs APP_OBS_GROWTH (calendar-year means differenced)",
                    obs = APP_OBS_GROWTH$provenance[c("source", "sha256", "accessed")],
                    obs_monthly = OBS_WEEKLY, trend_df = TREND_DF,
                    seed = SEED, seed_applied = "T5 block bootstrap only, set immediately before sample.int",
                    boot = c(n = BOOT_N, block = BOOT_BLOCK), run_at = format(Sys.time(), tz = "UTC")),
  readout = c(rms_full = f_full$rms, rms_off = f_off$rms, pct_closer_off = pct(f_full$rms, f_off$rms)),
  T1 = T1, T2a = T2a, T2b = xc, T2b_peak = peak, T4 = T4,
  T5 = list(quantiles = q, ledger = L), rms_land_switch = f_land$rms,
  T6 = list(lag = L_OBS, rms = f_T6$rms, vs_off_quantiles = q6),
  T7 = list(table = T7, vs_off_quantiles_at_obs_lag = q7,
            method = "superposition: land-off run + (full - land-off) under the delayed index"))
saveRDS(res, paste0(OUT_STEM, ".rds"))
cat(sprintf("\nsaved %s.rds | %.1f min\nDONE\n", OUT_STEM, as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
