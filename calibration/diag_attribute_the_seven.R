# =====================================================================
# WHAT EACH OF THE 7 POST-ADOPTION TEST FAILURES ACTUALLY IS
#
# Handoff 2026-08-30 sec.4 attributed all 7 to `gamma_diff = 0.25` (correct --
# with it back at 0 all 7 pass) and sketched what each needs. This script
# MEASURES each one, because two of the five sketches are wrong:
#
#   * test-likelihood.R was filed as "re-guard AFTER the refit". IT CANNOT BE:
#     its fixture runs on ccx_default_params(), NOT the fitted mode, so the
#     owed 21-param refit does not touch it.
#   * test-mode-file.R was filed as "stored logpost changed, refresh
#     provenance". THE STORED-LOGPOST ASSERTION PASSES. What fails is the
#     RECOMPUTED same-harness gap, which the test's own comment argues should
#     be objective-independent -- and it is not.
#
# Everything here is measurement. Nothing is fixed; the 7 stay failing until
# Marcus rules (handoff sec.6 item 1).
#
# Run:  Rscript calibration/diag_attribute_the_seven.R     (~6 min)
# =====================================================================

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

GAMMAS <- c(0, 0.125, CCX_GAMMA_DIFF_DEFAULT)   # bracket the adopted value
hdr <- function(s) cat("\n", strrep("=", 70), "\n", s, "\n", strrep("=", 70), "\n", sep = "")

# ---------------------------------------------------------------------
# PART 1. The AOD record itself -- READ THIS BEFORE THE CONVEYOR RESULT.
# The conveyor's quiet run is 1750-1850, and AOD is IDENTICALLY ZERO for
# 99 of those 100 years: the CMIP7 series begins in 1850. So that failure
# is not "volcanoes now drive NPP across the run" -- it is the record's
# TURN-ON STEP landing on the run's LAST year, which is what an endpoint
# -minus-start drift gate reads.
# ---------------------------------------------------------------------
hdr("PART 1 -- where the AOD record is nonzero")
F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = 0)
ag <- aggregate(cbind(aod_NH, aod_SH) ~ year, data.frame(year = floor(F$year),
                aod_NH = F$aod_NH, aod_SH = F$aod_SH), mean)
nz <- ag[ag$aod_NH > 0 | ag$aod_SH > 0, ]
cat(sprintf("first nonzero year: %d   nonzero years: %d of %d\n",
            min(nz$year), nrow(nz), nrow(ag)))
cat(sprintf("mean aod_NH 1850-2024: %.6f  =>  a SUSTAINED +%.3f%% NPP at gamma_diff = %.3f\n",
            mean(ag$aod_NH[ag$year >= 1850]),
            100 * CCX_GAMMA_DIFF_DEFAULT * mean(ag$aod_NH[ag$year >= 1850]),
            CCX_GAMMA_DIFF_DEFAULT))
cat(sprintf("aod_NH in 1850 (the conveyor window's LAST year): %.6f\n",
            ag$aod_NH[ag$year == 1850]))

# ---------------------------------------------------------------------
# PART 2. test-conveyor.R "a quiet run does not drift" (3 failures).
# Is `quiet_forcing()` zeroing AOD enough to restore the gate?
# ---------------------------------------------------------------------
hdr("PART 2 -- test-conveyor.R, with and without AOD zeroed in quiet_forcing()")
CONV_YRS <- c(1750, 1850); Q_TEST <- 20
CONFIGS <- list(A = list(sink = N_INTERIOR, desc = 0L),
                B = list(sink = N_INTERIOR, desc = 1L),
                C = list(sink = 8L,         desc = 0L))
conv_p <- function(q, cfg) {
  p <- ccx_default_params()
  p <- ccx_set_enso(p, list(gamma_enso = 0)); p$seas_amp_NH <- 0; p$seas_amp_SH <- 0; p$seas_drivers <- 0
  p$q_conv <- q; p$conv_sink <- cfg$sink; p$conv_descent <- cfg$desc
  p$conv_reverse <- 0L; p
}
quiet_forcing <- function(s, zero_aod) {
  F <- ccx_build_forcing("historical", CONV_YRS, prod_c14 = 0, bomb_total_kmol = 0)
  F$e_foss_NH <- 0; F$e_foss_SH <- 0; F$e_luc_NH <- 0; F$e_luc_SH <- 0
  F$cum_luc_NH <- 0; F$cum_luc_SH <- 0
  F <- ccx_hold_climate(F, value = 0); F$c14_bomb <- 0; F$c14_nuclear <- 0
  F$c14_cosmo <- s$prod_c14
  if (zero_aod) { F$aod_NH <- 0; F$aod_SH <- 0 }
  F
}
for (nm in names(CONFIGS)) {
  s <- ccx_spinup(conv_p(Q_TEST, CONFIGS[[nm]]))
  for (za in c(FALSE, TRUE)) {
    r <- ccx_run_fast(s, quiet_forcing(s, za))$out
    co2 <- r$co2_NH + r$co2_SH
    cat(sprintf("cfg %s  zero_aod=%-5s  |dCO2| = %.5f  |dd13C| = %.6f   (both gated < 1e-3)\n",
                nm, za, abs(co2[length(co2)] - co2[1]),
                abs(r$d13c_NH[length(r$d13c_NH)] - r$d13c_NH[1])))
  }
}

# ---------------------------------------------------------------------
# PART 3. test-luc-permanence.R "a pulse is not given back" (1 failure).
# ONLY the control-flatness PRECONDITION breaks. The three assertions the
# gate exists for are pulse-MINUS-control differences, so the volcanic
# signal cancels out of them -- shown by running both ways.
# ---------------------------------------------------------------------
hdr("PART 3 -- test-luc-permanence.R, with and without AOD zeroed in lp_background()")
LP_PULSE <- 100; LP_YEAR <- 1760; LP_YRS <- c(1750, 2024)
LP_PPM <- 0.4707; LP_LAG <- 100
p_lp <- ccx_default_params(); p_lp$seas_drivers <- 0; p_lp$sst_obs <- 0
s_lp <- ccx_spinup(p_lp)
lp_background <- function(s, zero_aod) {
  ze <- data.frame(year = seq(LP_YRS[1], LP_YRS[2]), fossil_GtC = 0,
                   luc_GtC = 0, d13c_foss = -24)
  F <- ccx_build_forcing("historical", LP_YRS, prod_c14 = s$prod_c14, emissions = ze)
  F$c14_bomb <- 0; F$c14_nuclear <- 0
  F <- ccx_hold_climate(F)
  if (zero_aod) { F$aod_NH <- 0; F$aod_SH <- 0 }
  F
}
lp_pulse <- function(F, luc) {
  ir <- which(F$year == LP_YEAR)
  sh <- if (luc) FORC_LUC_NH_SHARE else FORC_FOSS_NH_SHARE
  a  <- if (luc) "e_luc_NH" else "e_foss_NH"
  b  <- if (luc) "e_luc_SH" else "e_foss_SH"
  F[[a]][ir] <- F[[a]][ir] + LP_PULSE * sh
  F[[b]][ir] <- F[[b]][ir] + LP_PULSE * (1 - sh)
  if (luc) {
    add <- rep(0, nrow(F)); add[ir] <- LP_PULSE * seq_len(12) / 12
    add[seq(max(ir) + 1, nrow(F))] <- LP_PULSE
    F$cum_luc_NH <- F$cum_luc_NH + add * sh
    F$cum_luc_SH <- F$cum_luc_SH + add * (1 - sh)
  }
  F
}
lp_co2 <- function(s, F) {
  o <- ccx_run_fast(s, F)$out
  stats::aggregate(co2 ~ year,
    data.frame(year = floor(o$t), co2 = (o$co2_NH + o$co2_SH) / 2), mean)
}
lp_af <- function(s, F, ctl, lag) {
  a <- lp_co2(s, F)
  (a$co2[a$year == LP_YEAR + lag] - ctl$co2[ctl$year == LP_YEAR + lag]) / LP_PPM / LP_PULSE
}
for (za in c(FALSE, TRUE)) {
  F0 <- lp_background(s_lp, za); ctl <- lp_co2(s_lp, F0)
  af_f <- lp_af(s_lp, lp_pulse(F0, FALSE), ctl, LP_LAG)
  af_l <- lp_af(s_lp, lp_pulse(F0, TRUE),  ctl, LP_LAG)
  af_l150 <- lp_af(s_lp, lp_pulse(F0, TRUE), ctl, 150)
  cat(sprintf(paste0("zero_aod=%-5s  ctl drift = %.4f (gate < 0.05)  |  ",
                     "af_foss = %.4f (0.152 +-30%%)  af_luc/af_foss = %.3f (> 0.3)  ",
                     "150/100 = %.3f (> 0.8)\n"),
              za, abs(ctl$co2[nrow(ctl)] - ctl$co2[1]), af_f, af_l / af_f, af_l150 / af_l))
}

# ---------------------------------------------------------------------
# PART 4. test-likelihood.R "a CO2 level bias is expensive" (1 failure).
# THE FIXTURE IS ON ccx_default_params(), NOT the fitted mode -- so the
# owed refit cannot move this, and "re-guard after the refit" is not
# available. Report b0 (the tripped guard) and A (the curvature the test
# says is the load-bearing, scale-free half) against gamma_diff.
# ---------------------------------------------------------------------
hdr("PART 4 -- test-likelihood.R: the fitted level offset b0 vs gamma_diff")
obs <- ccx_prepare_obs()
err <- list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5)
for (gd in GAMMAS) {
  p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5)); p$gamma_diff <- gd
  sp <- ccx_spinup(p)
  Fh <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
  out <- ccx_run_fast(sp, Fh)$out
  shift <- function(b) {
    o <- out; o$co2_NH <- o$co2_NH + b; o$co2_SH <- o$co2_SH + b
    ccx_loglik(o, obs, err)
  }
  bb <- c(-4, -2, -1, 0, 1, 2, 4); ll <- vapply(bb, shift, numeric(1))
  m  <- stats::lm(I(ll - ll[bb == 0]) ~ 0 + bb + I(bb^2)); cf <- stats::coef(m)
  A  <- -cf[["I(bb^2)"]]; b0 <- cf[["bb"]] / (2 * A)
  cat(sprintf("gamma_diff = %5.3f   b0 = %7.4f ppm (guard |b0| < 3)   A = %7.3f (guard A > 10)\n",
              gd, b0, A))
}

# ---------------------------------------------------------------------
# PART 5. test-mode-file.R (1 failure). The failing line is the
# RECOMPUTED gap, not the stored one. The test's comment argues the
# recomputed gap is objective-independent "because it is a GAP between
# two vectors scored by the SAME harness". That holds for a COMMON shift.
# gamma_diff is not one: it changes the MODEL, and the two arms sit at
# different fert_k, so they pay different amounts.
# ---------------------------------------------------------------------
hdr("PART 5 -- test-mode-file.R: the recomputed pin90 - canonical gap vs gamma_diff")
PIN_PRIOR_CREDIT <- 11.6698
band0 <- CCX_PARAM_TABLE$h_ml
on.exit(CCX_PARAM_TABLE$h_ml <<- band0, add = TRUE)
for (gd in GAMMAS) {
  now <- vapply(names(CCX_MODE_FILES), function(a) {
    md <- readRDS(ccx_mode_file(a)); ccx_adopt_mode_band(md)
    bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode; bp$gamma_diff <- gd
    v <- ccx_make_logpost(years = c(1750, 2024), base_params = bp)(md$u_mode)
    CCX_PARAM_TABLE$h_ml <<- band0
    v
  }, numeric(1))
  cat(sprintf("gamma_diff = %5.3f   gap = %8.4f (expected -%.4f +-0.2)   pin90 = %9.3f   canonical = %9.3f\n",
              gd, now[["pin90"]] - now[[CCX_MODE_CANONICAL]], PIN_PRIOR_CREDIT,
              now[["pin90"]], now[[CCX_MODE_CANONICAL]]))
}
cat("\nPIN_PRIOR_CREDIT is a PRIOR term (the near-delta fert_k prior at 90) and does not\n",
    "depend on gamma_diff. Any movement in the gap is therefore a LIKELIHOOD differential.\n", sep = "")
