# =====================================================================
# F3 -- HOW MUCH OF THE ENSO TEMPERATURE SIGNAL IS THE GMST DRIVER ALREADY
# CARRYING?  (Marcus review comment #12, ruled "investigate first" 2026-09-24.)
#
# THE QUESTION THE COMMENT ASKS is whether FaIR can be used to separate the
# long-term warming from the ENSO part of the temperature record, so the ENSO
# temperature could be moved into the ENSO effect.
#
# ⭐⭐ THE QUESTION THAT MATTERS UNDERNEATH IT is whether CCX is seeing ENSO
# TWICE. It is driven by the OBSERVED IGCC temperature record, which contains
# ENSO's temperature signature; and it separately receives the Nino 3.4 index,
# which `gamma_enso_*` is fitted to. If the observed record's ENSO wiggle is
# already moving carbon through q10 and the solubility path, then part of what
# `gamma_enso_*` was fitted to absorb had already been supplied -- and the two
# terms are not independent.
#
# ⛔ THIS SCRIPT MEASURES. IT CHANGES NOTHING. Acting on the answer means
# changing the GMST driver, which moves every fitted value: objective #13 is
# FROZEN and the mode is tagged v1.0-hilda29l. The cheap branch Marcus named
# ("otherwise, just add caveats") has to be costed against a refit, and this is
# the number that decides which.
#
# METHOD. FaIR is a FORCED-RESPONSE model with no internal variability at all,
# so (observed GMST - FaIR GMST) is an estimate of internal variability, and the
# ENSO-congruent part of it is recoverable by regression on the Nino 3.4 index.
#
# ⚠ FOUR CAVEATS, and they are reported with the answer, not buried:
#  1. The residual is internal variability + forcing error + observational
#     error. Volcanic-response error, aerosol uncertainty, PDO and AMO all land
#     in it. It is an UPPER BOUND on the ENSO part.
#  2. It is CONFIG-DEPENDENT. "The" FaIR forced response is a choice among 841.
#     The median is used AND the 5-95 % spread across configs is reported;
#     neither is quietly picked.
#  3. Like-for-like: both series are re-referenced to the SAME window before
#     differencing. ⭐ The REGRESSION SLOPE is invariant to that choice (a
#     constant offset moves only the intercept) -- which is worth stating
#     because it means the FaIR-vs-IGCC level offset, real as it is, cannot
#     contaminate the ENSO coefficient. The offset is reported anyway.
#  4. Residuals are autocorrelated, so OLS standard errors are too small.
#     Newey-West (HAC) errors are reported beside them.
#
# ⚠ THE POWER CHECK IS THE FIRST RESULT, not an afterthought: regressing the
# FaIR FORCED series itself on the index must give ~zero. FaIR has no ENSO, so a
# non-zero coefficient there would mean the index is picking up the trend rather
# than ENSO, and every number below it would be an artifact. A test whose null
# is structurally guaranteed reports "no effect" identically to one that looked
# (~/.claude/CLAUDE.md).
# =====================================================================

suppressWarnings(suppressMessages({
  for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)
}))

# ---- named constants; every label below derives from these ----------
F3_FAIR_DIR   <- "~/Documents/2026/CodeProjects/FaIRtoFrEDI/fair_outputs"
F3_FAIR_FILE  <- "fair_baseline_gmst_v160_egu.csv"
F3_FAIR_LABEL <- "FaIR 2.2.4 (calib 1.6.0), 841 configs, baseline arm"
F3_OBS_LABEL  <- "IGCC observed GMST (data/forcing_gmst.rds)"
F3_REF_WIN    <- c(1850L, 1900L)   # common reference window, both series
F3_FIT_WIN    <- c(1950L, 2024L)   # Nino 3.4 starts 1948; 1950 leaves lag room
# ⛔ SIGN CONVENTION, AND THE FIRST VERSION HAD IT BACKWARDS. POSITIVE = the
# index LEADS the temperature by that many months, which is the physical
# direction (the atmosphere responds to a Pacific SST anomaly some months
# later). BOTH SIGNS ARE SCANNED deliberately: a profile that peaked at a
# NEGATIVE lag -- temperature leading the index -- would mean the regression is
# fitting something other than the ENSO response, and a one-sided scan could
# never see that. The first run scanned only one side and reported its edge
# (lag 0) as the optimum.
F3_LAGS_MON   <- -6:12
F3_HAC_LAG    <- 4L                # Newey-West bandwidth, years
F3_OUT        <- "calibration/out/diag_f3_enso_in_the_gmst_driver.csv"

cat("=====================================================================\n")
cat("F3: the ENSO temperature signal already inside the GMST driver\n")
cat("  obs  :", F3_OBS_LABEL, "\n")
cat("  model:", F3_FAIR_LABEL, "\n    file:", F3_FAIR_FILE, "\n")
cat("  common reference window:", F3_REF_WIN[1], "-", F3_REF_WIN[2], "\n")
cat("  regression window      :", F3_FIT_WIN[1], "-", F3_FIT_WIN[2], "\n")
cat("=====================================================================\n\n")

# ---- 1. the two temperature series, on a common reference -----------
obs <- as.data.frame(readRDS(ccx_path("data", "forcing_gmst.rds")))
fp  <- file.path(path.expand(F3_FAIR_DIR), F3_FAIR_FILE)
stopifnot(file.exists(fp))
fair <- utils::read.csv(fp, check.names = FALSE)
cfg  <- setdiff(names(fair), "year")
cat(sprintf("FaIR file: %d configs, %d-%d\n", length(cfg), min(fair$year), max(fair$year)))

yrs <- intersect(obs$year, fair$year)
obs  <- obs[match(yrs, obs$year), ]
fair <- fair[match(yrs, fair$year), ]

rebase <- function(v, yr) v - mean(v[yr >= F3_REF_WIN[1] & yr <= F3_REF_WIN[2]])
obs_v  <- rebase(obs$gmst_anom, yrs)
fair_m <- as.matrix(fair[, cfg])
fair_m <- apply(fair_m, 2, rebase, yr = yrs)
fair_med <- apply(fair_m, 1, stats::median)

# The level offset caveat 3 names. Reported, then set aside: it does not enter
# the slope.
k_now <- yrs >= 2015 & yrs <= 2024
cat(sprintf("\nLEVEL: over 2015-2024, obs %.3f C vs FaIR median %.3f C -> obs is %+.3f C\n",
            mean(obs_v[k_now]), mean(fair_med[k_now]),
            mean(obs_v[k_now]) - mean(fair_med[k_now])))
cat("  (re-referenced to", F3_REF_WIN[1], "-", F3_REF_WIN[2],
    "; a constant offset cannot change the slopes below)\n")

# ---- 2. the Nino 3.4 index CCX ITSELF RECEIVES ----------------------
# ⛔ Taken from the assembled forcing, not from the raw rds: ccx_build_forcing()
# applies the RULING-A demeaning window and the pre-1948 zeros, and the question
# is about the index the MODEL sees, not the one the archive ships.
F <- suppressWarnings(ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0))
idx_mon <- data.frame(t = F$t, year = F$year, month = F$month, x = F$enso)
idx_mon <- idx_mon[idx_mon$year >= 1948, ]

# The index averaged over the 12 months ending L months BEFORE the calendar
# year's end, i.e. the index LEADING the temperature by L months. `+ L/12`
# pushes each month's value FORWARD into the year that responds to it.
lagged_annual <- function(L) {
  tt <- idx_mon$t + L / 12
  yy <- floor(tt + 1e-9)
  a <- stats::aggregate(list(x = idx_mon$x), list(year = yy), mean)
  a
}

# ---- 3. THE POWER CHECK ---------------------------------------------
fitw <- function(d) d[d$year >= F3_FIT_WIN[1] & d$year <= F3_FIT_WIN[2], ]
hac <- function(m) {
  ct <- lmtest::coeftest(m, vcov. = sandwich::NeweyWest(m, lag = F3_HAC_LAG,
                                                        prewhite = FALSE))
  ct["x", c("Estimate", "Std. Error", "Pr(>|t|)")]
}
a0 <- lagged_annual(0)
d_forced <- fitw(merge(data.frame(year = yrs, y = fair_med), a0, by = "year"))
m_forced <- stats::lm(y ~ x + splines::ns(year, df = 3), data = d_forced)
h_forced <- hac(m_forced)
cat(sprintf(paste("\nPOWER CHECK -- the FaIR FORCED series regressed on the index",
                  "(it must be ~0):\n  beta = %+.4f C per C  (HAC se %.4f, p = %.3f)\n"),
            h_forced[1], h_forced[2], h_forced[3]))
cat("  FaIR has no ENSO, so a coefficient here would mean the index is standing\n",
    "  in for the trend and every number below would be an artifact.\n")

# ---- 4. the lag profile, on the MEDIAN config -----------------------
cat("\nLAG PROFILE -- residual (obs - FaIR median) on the Nino 3.4 index:\n")
cat("  lead beta (C per C)   HAC se      p        R2(partial)   (+ = index leads)\n")
resid_med <- obs_v - fair_med
prof <- do.call(rbind, lapply(F3_LAGS_MON, function(L) {
  d <- fitw(merge(data.frame(year = yrs, y = resid_med), lagged_annual(L), by = "year"))
  m <- stats::lm(y ~ x + splines::ns(year, df = 3), data = d)
  m0 <- stats::lm(y ~ splines::ns(year, df = 3), data = d)
  h <- hac(m)
  r2 <- 1 - sum(stats::resid(m)^2) / sum(stats::resid(m0)^2)
  cat(sprintf("  %+3d   %+8.4f      %.4f   %7.4f   %6.3f\n", L, h[1], h[2], h[3], r2))
  data.frame(lag_months = L, beta = h[1], hac_se = h[2], p = h[3], partial_r2 = r2)
}))
best <- prof[which.max(prof$partial_r2), ]
cat(sprintf("\nBEST LAG: %d months, beta = %+.4f +/- %.4f C per C, partial R2 = %.3f\n",
            best$lag_months, best$beta, best$hac_se, best$partial_r2))

# ---- 5. config spread at the best lag (caveat 2) --------------------
aL <- lagged_annual(best$lag_months)
mm <- merge(data.frame(year = yrs), aL, by = "year")
kf <- mm$year >= F3_FIT_WIN[1] & mm$year <= F3_FIT_WIN[2]
xx <- mm$x[kf]; yy2 <- mm$year[kf]
ns3 <- splines::ns(yy2, df = 3)
betas <- vapply(seq_along(cfg), function(j) {
  r <- (obs_v - fair_m[, j])[match(mm$year[kf], yrs)]
  unname(stats::coef(stats::lm(r ~ xx + ns3))["xx"])
}, numeric(1))
qs <- stats::quantile(betas, c(0.05, 0.5, 0.95))
cat(sprintf(paste("\nCONFIG SPREAD (caveat 2), all %d FaIR members at lag %d:\n",
                  " beta median %+.4f, 5-95%% [%+.4f, %+.4f] C per C\n"),
            length(cfg), best$lag_months, qs[2], qs[1], qs[3]))
cat(sprintf("  -> the choice of config moves beta by %.1f %% of its own value.\n",
            100 * (qs[3] - qs[1]) / abs(qs[2])))

# ---- 6. WHAT THAT IS IN DEGREES, i.e. what the driver carries -------
sdx <- stats::sd(xx); rngx <- diff(range(xx))
cat(sprintf(paste("\nAMPLITUDE IN THE DRIVER: the index has sd %.3f C and range %.3f C",
                  "over %d-%d,\n  so the ENSO-congruent temperature in the observed",
                  "record is about\n  +/- %.3f C (1 sd) and %.3f C peak-to-peak.\n"),
            sdx, rngx, F3_FIT_WIN[1], F3_FIT_WIN[2],
            abs(best$beta) * sdx, abs(best$beta) * rngx))

# ---- 7. CROSS-CHECK: the same regression on the OBSERVED series -----
# If FaIR's forced response really carries no ENSO, then regressing the OBSERVED
# record on the index (with the same trend control) must give the SAME slope as
# the residual regression. Two routes to one number; if they disagree, the
# decomposition is not doing what it claims.
d_obs <- fitw(merge(data.frame(year = yrs, y = obs_v), aL, by = "year"))
h_obs <- hac(stats::lm(y ~ x + splines::ns(year, df = 3), data = d_obs))
cat(sprintf(paste("\nCROSS-CHECK: the same regression on the OBSERVED record directly:\n",
                  " beta = %+.4f (HAC se %.4f) vs %+.4f from the residual",
                  "-- difference %+.4f\n"),
            h_obs[1], h_obs[2], best$beta, h_obs[1] - best$beta))

dir.create(dirname(F3_OUT), showWarnings = FALSE, recursive = TRUE)
prof$provenance <- paste(F3_FAIR_LABEL, "|", F3_FAIR_FILE, "| obs:", F3_OBS_LABEL,
                         "| ref", paste(F3_REF_WIN, collapse = "-"),
                         "| fit", paste(F3_FIT_WIN, collapse = "-"),
                         "| HAC lag", F3_HAC_LAG, "| no RNG")
utils::write.csv(prof, F3_OUT, row.names = FALSE)
cat("\nwrote", F3_OUT, "\n")

# =====================================================================
# 8. THE PART THAT DECIDES BUILD-vs-CAVEAT: does that temperature signal
#    actually MOVE CARBON, and how much of it is gamma_enso being paid for
#    a second time?
#
# Sections 1-7 measure a TEMPERATURE. A temperature the carbon cycle barely
# notices is a caveat; one that moves as much carbon as the explicit ENSO term
# does is a double-count. Only a run can tell them apart -- the standing
# "compute the expected magnitude before calling a result reasonable" rule.
#
# FOUR ARMS, one estimator:
#   A  full model                                (canonical mode, canonical forcing)
#   B  ENSO-congruent temperature REMOVED from gmst, gamma_enso untouched
#   C  gamma_enso = 0, gmst untouched            (the app's existing knockout)
#   D  both removed
#
# The estimator is the app's own: the scatter of the annual CO2 growth rate
# about a 3-dof smooth, over the years GCB covers. Using the same statistic the
# app prints is deliberate -- a different one could not be compared against the
# "-23 %" the ENSO switch already reports to the reader.
#
# ⛔ THE SST COLUMNS MUST BE RE-DERIVED. `sst_anom_NH/SH` are a FUNCTION of the
# gmst column (ccx_sst_anom_from_gmst), so editing gmst alone would remove the
# ENSO signal from the land's temperature path and leave it in the ocean's --
# half a counterfactual, silently. This is the same failure the warming_feedback
# switch had in 2026-08-18 (`p$sst_obs <- 0`, R/mechanisms.R).
# =====================================================================
ccx_load_cpp()
F3_MODE_FILE <- ccx_mode_file()
F3_CARB_WIN  <- c(1959L, 2024L)     # GCB's atmospheric growth record

md <- readRDS(F3_MODE_FILE)

# \u26d4\u26d4 THE PARAMETERS ARE BUILT THE WAY app/global.R BUILDS THEM, LINE FOR
# LINE, AND THE FIRST VERSION WAS NOT. It used `ccx_default_params()` as the
# base and filled from `md$par_mode`; the app uses `ccx_mode_base(md)` -- the
# mode file's OWN STRUCTURE -- and `ccx_mode_par_with_pins(md)`, which hands
# back the 9 held values the pinned canonical does not carry in its free set.
#
# The cost of getting it wrong was NOT an error. Every arm was internally
# consistent, so the comparison between them still ran and still looked
# finished; the numbers were simply a DIFFERENT MODEL's. The tell was that the
# full-model wobble came out 0.321 ppm/yr where the app prints 0.27, and the
# gamma_enso knockout -37 % where the app prints -23 %. An arm-to-arm ratio can
# be perfectly self-consistent and still not be the ratio anyone asked for --
# and the app's -23 % is the number in front of the reader.
#
# \u26a0 The spinup is read from the mode file for the same reason
# (ccx_mode_spinup, as app/global.R line ~228). It is the PERIODIC spinup for
# every registered mode. Measured here: switching it does NOT move this
# statistic -- the wobble is an interannual quantity and an initial-condition
# difference washes into the level, not the scatter -- so the spinup is not
# what the 0.321-vs-0.27 gap was. It is still read rather than assumed.
stopifnot(ccx_mode_carries_build(md))
pm <- ccx_mode_par_with_pins(md)
if (length(ccx_mode_absent(md))) pm <- ccx_migrate_par_set(pm)
P0 <- ccx_mode_base(md)
for (n in intersect(names(P0), names(pm))) P0[[n]] <- pm[[n]]
P0 <- ccx_set_enso(P0, pm)
P0$pump_mode <- md$pump_mode
F3_LUC  <- pm$luc_scale
F3_BOMB <- pm$bomb_total
F3_SPINUP_LABEL <- ccx_mode_spinup(md)
f3_spinup <- ccx_spinup_from_label(F3_SPINUP_LABEL)
cat(sprintf("\n\nmode arm %s (logpost %.2f), file %s, spinup %s\n",
            CCX_MODE_CANONICAL, md$logpost, basename(F3_MODE_FILE),
            F3_SPINUP_LABEL))
cat(sprintf("  luc_scale %.4f  bomb_total %.2f  %d free names + %d pinned\n",
            F3_LUC, F3_BOMB, length(md$param_names), length(ccx_mode_pins(md))))

BETA <- best$beta; BEST_L <- best$lag_months
Ffull <- suppressWarnings(ccx_build_forcing("historical", c(1750, 2024),
                                            prod_c14 = 0, luc_scale = F3_LUC,
                                            bomb_total_kmol = F3_BOMB))
# the ENSO-congruent temperature, on the monthly grid, at the fitted lead
enso_lead <- stats::approx(Ffull$t + BEST_L / 12, Ffull$enso,
                           xout = Ffull$t, rule = 2)$y
dT <- BETA * enso_lead
Fnoenso_T <- Ffull
Fnoenso_T$gmst <- Ffull$gmst - dT
Fnoenso_T <- ccx_sst_anom_from_gmst(Fnoenso_T)   # ⛔ see header
kw <- Ffull$year >= F3_FIT_WIN[1] & Ffull$year <= F3_FIT_WIN[2]
cat(sprintf(paste("removing %+.4f C/C x the index (lead %d mo) changes mean gmst over",
                  "%d-%d by %+.4f C\n  and its sd by %+.4f C (%.1f %% of the",
                  "original %.4f)\n"),
            BETA, BEST_L, F3_FIT_WIN[1], F3_FIT_WIN[2],
            mean(Fnoenso_T$gmst[kw]) - mean(Ffull$gmst[kw]),
            stats::sd(Fnoenso_T$gmst[kw]) - stats::sd(Ffull$gmst[kw]),
            100 * (stats::sd(Fnoenso_T$gmst[kw]) - stats::sd(Ffull$gmst[kw])) /
              stats::sd(Ffull$gmst[kw]), stats::sd(Ffull$gmst[kw])))

run_arm <- function(p, F) {
  sp <- f3_spinup(p)
  F$c14_cosmo <- sp$prod_c14
  ccx_run_fast(sp, F)$out
}
# the app's estimator, verbatim in spirit (app/server.R output$c_growth_note).
# ⚠ `ccx_global_co2()` lives in app/R/plots.R, NOT in R/, so it is not on the
# path here. Its body is one line and its whole point is that `co2_global` is
# not a column of every run -- inlined rather than sourced, because sourcing
# plots.R would pull ggplot and the palette into a numerical diagnostic.
f3_global_co2 <- function(o) if (!is.null(o$co2_global)) o$co2_global else
  (o$co2_NH + o$co2_SH) / 2
wobble <- function(o) {
  g <- f3_global_co2(o)
  a <- stats::aggregate(list(co2 = g), list(year = floor(o$t)), mean)
  n <- stats::aggregate(list(n = g), list(year = floor(o$t)), length)
  a <- a[n$n == 12, ]
  d <- data.frame(year = a$year[-1], g = diff(a$co2))
  d <- d[d$year >= F3_CARB_WIN[1] & d$year <= F3_CARB_WIN[2], ]
  stats::sd(stats::residuals(stats::lm(g ~ splines::ns(year, df = 3), data = d)))
}
P_noenso <- ccx_set_enso(P0, list(gamma_enso = 0))
arms <- list(
  A_full              = list(p = P0,       F = Ffull),
  B_no_enso_in_T      = list(p = P0,       F = Fnoenso_T),
  C_no_gamma_enso     = list(p = P_noenso, F = Ffull),
  D_neither           = list(p = P_noenso, F = Fnoenso_T))
w <- vapply(arms, function(a) wobble(run_arm(a$p, a$F)), numeric(1))

cat(sprintf("\nCO2 GROWTH SCATTER about a 3-dof smooth, %d-%d, ppm/yr:\n",
            F3_CARB_WIN[1], F3_CARB_WIN[2]))
for (nm in names(w))
  cat(sprintf("  %-18s %.4f   (%+.1f %% vs full)\n", nm, w[[nm]],
              100 * (w[[nm]] / w[["A_full"]] - 1)))

drop_T  <- 1 - w[["B_no_enso_in_T"]]  / w[["A_full"]]
drop_g  <- 1 - w[["C_no_gamma_enso"]] / w[["A_full"]]
drop_b  <- 1 - w[["D_neither"]]       / w[["A_full"]]
cat(sprintf(paste("\n⭐ THE ANSWER:\n",
                  " the ENSO temperature inside the GMST driver carries %+.1f %% of the",
                  "model's wobble;\n  the explicit gamma_enso term carries %+.1f %%;",
                  "removing BOTH removes %+.1f %%.\n"),
            100 * drop_T, 100 * drop_g, 100 * drop_b))
cat(sprintf(paste("  Additivity check: %.1f %% + %.1f %% = %.1f %% against %.1f %%",
                  "measured together\n  -> overlap %+.1f percentage points.\n"),
            100 * drop_T, 100 * drop_g, 100 * (drop_T + drop_g), 100 * drop_b,
            100 * (drop_T + drop_g - drop_b)))

# ---- caveat 2, PROPAGATED rather than restated ----------------------
# The config spread moves beta by ~57 % of its own value. A warning to that
# effect is worth less than the two extra runs that say what it does to the
# ANSWER, so the 5th and 95th percentile betas are run as arms of their own.
# If the whole config range lands well below the explicit term, the choice of
# FaIR member cannot change the conclusion and caveat 2 stops mattering here.
mk_T <- function(b) {
  Fx <- Ffull
  Fx$gmst <- Ffull$gmst - b * enso_lead
  ccx_sst_anom_from_gmst(Fx)
}
w_lo <- wobble(run_arm(P0, mk_T(qs[1])))
w_hi <- wobble(run_arm(P0, mk_T(qs[3])))
cat(sprintf(paste("\nCAVEAT 2 PROPAGATED: across the 5-95 %% FaIR-config range of beta",
                  "[%+.4f, %+.4f],\n  the temperature channel carries %.1f %% to %.1f %%",
                  "of the wobble, against %.1f %% for gamma_enso.\n"),
            qs[1], qs[3], 100 * (1 - w_hi / w[["A_full"]]),
            100 * (1 - w_lo / w[["A_full"]]), 100 * drop_g))
cat(sprintf("  -> the config choice cannot bring the two channels within %.0fx of each other.\n",
            drop_g / max(1e-9, 1 - w_hi / w[["A_full"]])))

utils::write.csv(
  data.frame(arm = names(w), growth_scatter_ppm_yr = as.numeric(w),
             pct_vs_full = 100 * (as.numeric(w) / w[["A_full"]] - 1),
             beta_C_per_C = BETA, lead_months = BEST_L,
             provenance = paste(CCX_MODE_CANONICAL, "|", basename(F3_MODE_FILE),
                                "| logpost", round(md$logpost, 2), "| spinup", F3_SPINUP_LABEL, "|",
                                F3_FAIR_LABEL, "| window",
                                paste(F3_CARB_WIN, collapse = "-"), "| no RNG")),
  sub("[.]csv$", "_carbon_arms.csv", F3_OUT), row.names = FALSE)
cat("\nwrote", sub("[.]csv$", "_carbon_arms.csv", F3_OUT), "\n")
