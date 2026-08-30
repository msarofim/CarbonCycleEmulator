# =====================================================================
# test-luc-permanence.R -- land-use carbon must not be given back.
#
# THE REGRESSION THIS GUARDS. Between 98c1783 (2026-08-12) and the
# converted-land term (2026-08-13), land-use emissions had an airborne fraction
# of 0.002 at 100 years against 0.262 for a fossil emission on the same
# background: the wood pool the debit came out of regrew what deforestation
# removed, because its fixed point did not know a forest had become a field.
# See calibration/diag_1900_deficit.R and notes/handoff_2026-08-13f.
#
# The gate is a PULSE PAIR on a flat background. It uses no historical forcing,
# no observation and no fit, so it cannot be satisfied by re-tuning anything.
# =====================================================================

skip_if_no_cpp <- function() {
  skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) skip("C++ core failed to compile")
}

LP_PULSE  <- 100      # GtC
LP_YEAR   <- 1760     # leaves 264 yr of response inside the standard record
LP_YRS    <- c(1750, 2024)
LP_PPM    <- 0.4707   # ppm per GtC, whole atmosphere
LP_LAG    <- 100      # yr, the horizon the gate is stated at

# The fossil reference arm's expected airborne fraction at LP_LAG, and its
# tolerance. NOT a fitted value and NOT read off this test: it is the model's
# "PI, background HELD" IRF@100 from calibration/diag_joos_irf.R part 4, which
# is what lp_background() is -- a preindustrial, zero-emission, frozen-climate
# control. See the derivation note at the gate below.
#
# WHAT THIS GATE DOES AND DOES NOT CATCH, measured 2026-08-18 so that nobody has
# to re-derive it to find out. Values of af_foss:
#   package defaults 0.1513 | ARM N mode (adopted) 0.1622 | ARM D mode 0.1646
#   kz over its whole bracket and well below it (500 -> 6528): 0.1852 -> 0.1458
#   k_w x4 or /4, h_ml /4: 0.1502 -> 0.1560
# So the band holds at BOTH modes with room to spare, and a 13x change in kz
# moves it only ~12 %. This is a SANITY AND CROSS-CHECK gate on the reference
# arm -- it catches the arm breaking (af -> 0, or the pulse not landing) and it
# catches the arm drifting away from the independent diagnostic. It is NOT
# sensitive to ocean-parameter drift and must not be cited as if it were; the
# Joos point-IRF gate in test-pulse.R is where kz-scale changes show up.
LP_FOSS_PI_REF <- 0.152
LP_FOSS_PI_TOL <- 0.30

# A zero-emission background with GMST and ENSO FROZEN. Left free, a
# zero-emission run moves +8.34 ppm over 275 yr -- the prescribed-warming
# carbon-climate feedback, not drift -- and the control would not be flat.
lp_background <- function(s) {
  ze <- data.frame(year = seq(LP_YRS[1], LP_YRS[2]),
                   fossil_GtC = 0, luc_GtC = 0, d13c_foss = -24)
  F <- ccx_build_forcing("historical", LP_YRS, prod_c14 = s$prod_c14, emissions = ze)
  F$c14_bomb <- 0; F$c14_nuclear <- 0
  F <- ccx_hold_climate(F)   # gmst, enso AND the observed-SST columns
  # AND THE VOLCANIC AEROSOL (2026-08-30, Marcus's ruling), for the same
  # reason this control already runs seasonless and with sst_obs = 0: the
  # mechanism is real but ORTHOGONAL to land-use permanence, so the control
  # excludes it rather than the gate being loosened to admit it.
  # ccx_hold_climate() does not hold aod_* by design (AOD is a radiative
  # driver, not a climate variable; R/forcing.R states this and says a
  # volcanically quiet diagnostic must zero it itself). Once
  # CCX_GAMMA_DIFF_DEFAULT went to 0.25 this control drifted 0.2322 ppm
  # against its 0.05 gate; zeroed, 0.0437, which is the pre-adoption value.
  #
  # ⚠ ONLY THE PRECONDITION WAS AFFECTED, NOT THE GATE'S SUBSTANCE. The three
  # assertions below are pulse-MINUS-control differences, so the volcanic
  # signal cancels out of them almost exactly: with AOD free vs zeroed,
  # af_foss 0.1506 / 0.1513, af_luc/af_foss 1.033 / 1.032, 150-yr ratio
  # 0.864 / 0.867 (calibration/diag_attribute_the_seven.R). Zeroing the AOD
  # restores the flatness precondition; it does not move the answer.
  F$aod_NH <- 0; F$aod_SH <- 0
  F
}

# One year of emission at LP_PULSE GtC/yr, split in the forcing's own NH share.
# For the LUC arm the CUMULATIVE column has to carry the pulse forward too --
# that is the whole mechanism, and a pulse that moved e_luc alone would test
# nothing.
lp_pulse <- function(F, luc) {
  ir <- which(F$year == LP_YEAR)
  sh <- if (luc) FORC_LUC_NH_SHARE else FORC_FOSS_NH_SHARE
  a  <- if (luc) "e_luc_NH" else "e_foss_NH"
  b  <- if (luc) "e_luc_SH" else "e_foss_SH"
  F[[a]][ir] <- F[[a]][ir] + LP_PULSE * sh
  F[[b]][ir] <- F[[b]][ir] + LP_PULSE * (1 - sh)
  if (luc) {
    add <- rep(0, nrow(F))
    add[ir] <- LP_PULSE * seq_len(12) / 12
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
  (a$co2[a$year == LP_YEAR + lag] - ctl$co2[ctl$year == LP_YEAR + lag]) /
    LP_PPM / LP_PULSE
}

test_that("a land-use pulse is not given back to the land", {
  skip_if_no_cpp()
  # seas_drivers = 0, and the reason is MEASURED, not assumed (2026-08-18
  # drift decomposition; numbers in the CHANGELOG entry). The driver seasonal
  # cycle drifts a zero-emission control +0.43 ppm over 275 yr: +0.33 is the
  # fertilisation RECTIFIER (the seasonal CO2 swing modulates NPP and the
  # product has nonzero annual mean -- real physics, amplitude-dependent, so it
  # shrinks when the refit brings the uncalibrated 5 ppm default cycle to the
  # observed 3) and +0.10 is the integrator's quadrature over the polar-night
  # kinks (already cut from +0.22 by the 720-point norm; the residual is the
  # integrator's own and no norm choice removes it). The old sine drifted
  # +0.044, under this file's 0.05 flatness gate; the driver control cannot
  # get under it, and the gate is load-bearing per the header. Seasonality is
  # orthogonal to land-use permanence, so the control runs seasonless rather
  # than the gate being loosened.
  p_lp <- ccx_default_params(); p_lp$seas_drivers <- 0
  # sst_obs = 0 too: ccx_hold_climate() freezes the observed-SST columns at
  # their 1750 value, but that value is the 1850s HadSST4 anomaly (+0.02 K)
  # while ccx_spinup() equilibrates at anomaly ZERO -- the mismatch alone
  # drifts the control +0.03 ppm/275 yr. The control predates both drivers.
  p_lp$sst_obs <- 0
  s   <- ccx_spinup(p_lp)
  F0  <- lp_background(s)
  ctl <- lp_co2(s, F0)

  # the control must be flat, or every number below is measured against a moving
  # baseline. This is also the gate on the frozen-GMST construction above.
  expect_lt(abs(ctl$co2[nrow(ctl)] - ctl$co2[1]), 0.05)

  af_foss <- lp_af(s, lp_pulse(F0, luc = FALSE), ctl, LP_LAG)
  af_luc  <- lp_af(s, lp_pulse(F0, luc = TRUE),  ctl, LP_LAG)

  # THE GATE. Pre-fix this ratio was 0.01. The threshold is set well below the
  # measured 0.50 so that ordinary parameter movement does not trip it, and far
  # above the regression it exists to catch.
  #
  # THE REFERENCE ARM'S BAR IS A PREINDUSTRIAL ONE, restated 2026-08-18 (Marcus).
  # It read "> 0.2" -- a present-day airborne fraction applied to a measurement
  # taken on lp_background(), which is zero-emission with GMST and ENSO FROZEN,
  # i.e. PREINDUSTRIAL. On a PI background the buffer is not yet stretched and
  # the fraction is legitimately far lower, so the arm was failing a bar written
  # for a background it never runs on.
  #
  # THE BAR IS DERIVED, AND FROM OUTSIDE THIS FILE. calibration/diag_joos_irf.R
  # part 4 measures the model's "PI, background HELD" IRF at 100 yr as 0.152, by
  # a completely separate code path (diagnosed-emission hold, ccx_irf, no
  # lp_* helper involved). This test measures 0.151. Agreement to 0.001 across
  # two independent constructions is a stronger statement than the bar it
  # replaces made, and LP_FOSS_PI_REF/TOL turn it into a two-sided cross-check:
  # the reference arm must land on the model's own PI impulse response, so this
  # trips if EITHER the arm or the diagnostic moves.
  expect_gt(af_foss, LP_FOSS_PI_REF * (1 - LP_FOSS_PI_TOL))
  expect_lt(af_foss, LP_FOSS_PI_REF * (1 + LP_FOSS_PI_TOL))
  expect_gt(af_luc / af_foss, 0.3)

  # ... and it must not decay away afterwards, which is what the old model did:
  # 0.072 at 50 yr -> 0.002 at 100 -> -0.003 at 150.
  expect_gt(lp_af(s, lp_pulse(F0, luc = TRUE), ctl, 150), 0.8 * af_luc)
})

test_that("MUTATION TEST: the control is flat only BECAUSE lp_background() zeroes the AOD", {
  skip_if_no_cpp()
  # Otherwise the aod line in lp_background() could be dropped and the
  # flatness gate above would keep passing without anyone noticing why.
  # gamma_diff EXPLICIT, so this does not go quiet if the default moves.
  p_lp <- ccx_default_params(); p_lp$seas_drivers <- 0; p_lp$sst_obs <- 0
  p_lp$gamma_diff <- 0.25
  s  <- ccx_spinup(p_lp)
  F0 <- lp_background(s)
  Fv <- ccx_build_forcing("historical", LP_YRS, prod_c14 = s$prod_c14,
                          emissions = data.frame(year = seq(LP_YRS[1], LP_YRS[2]),
                                                 fossil_GtC = 0, luc_GtC = 0,
                                                 d13c_foss = -24))
  F0$aod_NH <- Fv$aod_NH; F0$aod_SH <- Fv$aod_SH      # put the volcanoes back
  ctl <- lp_co2(s, F0)
  expect_gt(abs(ctl$co2[nrow(ctl)] - ctl$co2[1]), 0.05)
})

test_that("f_luc_perm = 0 AND f_luc_wood = 1 reproduce the pre-2026-08-13 behaviour", {
  skip_if_no_cpp()
  # The escape hatch has to actually work, both so the regression can be
  # re-measured and so the fix's size can be quoted. It is NOT a supported
  # configuration -- it is the bug, kept reachable.
  #
  # IT TAKES BOTH KNOBS. The pre-08-13 model was permanence OFF *and* the debit
  # taken from wood alone; ea7c70b later adopted pro rata and flipped
  # CCX_F_LUC_WOOD_DEFAULT 1 -> 0, so f_luc_perm = 0 on its own now reproduces a
  # model that never shipped (af@100 = 0.074, which is what this gate was
  # failing on). Measured 2026-08-18 -- notes/diag_2026-08-18_test_failures.R:
  #   perm 0, wood 0 : af@50 0.1171  af@100  0.0744  af@150  0.0542  (neither model)
  #   perm 0, wood 1 : af@50 0.0187  af@100 -0.0032  af@150 -0.0026  (the bug)
  # and -0.0032 / -0.0026 reproduce the signature this file's header records
  # (0.002 at 100 -> -0.003 at 150). The bar is NOT re-baselined: it is the
  # 0.02 the header already stated, now measured at the config it describes.
  p <- ccx_default_params(); p$f_luc_perm <- 0; p$f_luc_wood <- 1
  p$seas_drivers <- 0; p$sst_obs <- 0    # same seasonless, obs-less control
  s <- ccx_spinup(p)
  F0 <- lp_background(s); ctl <- lp_co2(s, F0)
  expect_lt(abs(lp_af(s, lp_pulse(F0, luc = TRUE), ctl, LP_LAG)), 0.02)
})

test_that("the cleared fraction is what the arithmetic says it is", {
  # Guards the denominator. Using veg0 instead of land0 would make this ~4x
  # bigger and the debit over-permanent; the two are easy to confuse and the
  # difference is invisible in any single CO2 number.
  s <- ccx_spinup(ccx_default_params())   # seasonality irrelevant: reads cum_luc only
  F <- ccx_build_forcing("historical", LP_YRS, prod_c14 = s$prod_c14)
  n <- nrow(F)
  land0 <- s$aux$land0$NH + s$aux$land0$SH
  expect_equal(F$cum_luc_NH[n] + F$cum_luc_SH[n],
               sum(readRDS(ccx_path("data", "forcing_emissions_historical.rds"))$luc_GtC),
               tolerance = 1e-6)
  # ~14 % of the land cleared by 2024, nowhere near CCX_LUC_CLEARED_MAX
  expect_gt((F$cum_luc_NH[n] + F$cum_luc_SH[n]) / land0, 0.10)
  expect_lt((F$cum_luc_NH[n] + F$cum_luc_SH[n]) / land0, 0.20)
})

test_that("a forcing with land-use emissions and no cum_luc is an error", {
  # Silently defaulting it to zero would restore the bug through a code path
  # nobody chose -- see ccx_forcing_cum_luc().
  expect_error(ccx_forcing_cum_luc(list(e_luc = list(NH = 0.5, SH = 0.4))),
               "no `cum_luc`")
  expect_equal(ccx_forcing_cum_luc(list(e_luc = list(NH = 0, SH = 0))),
               list(NH = 0, SH = 0))
})
