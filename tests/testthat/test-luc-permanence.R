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

# A zero-emission background with GMST and ENSO FROZEN. Left free, a
# zero-emission run moves +8.34 ppm over 275 yr -- the prescribed-warming
# carbon-climate feedback, not drift -- and the control would not be flat.
lp_background <- function(s) {
  ze <- data.frame(year = seq(LP_YRS[1], LP_YRS[2]),
                   fossil_GtC = 0, luc_GtC = 0, d13c_foss = -24)
  F <- ccx_build_forcing("historical", LP_YRS, prod_c14 = s$prod_c14, emissions = ze)
  F$c14_bomb <- 0; F$c14_nuclear <- 0
  F$gmst <- F$gmst[1]; F$enso <- F$enso[1]
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
  s   <- ccx_spinup(ccx_default_params())
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
  expect_gt(af_foss, 0.2)                 # the reference arm must be sane
  expect_gt(af_luc / af_foss, 0.3)

  # ... and it must not decay away afterwards, which is what the old model did:
  # 0.072 at 50 yr -> 0.002 at 100 -> -0.003 at 150.
  expect_gt(lp_af(s, lp_pulse(F0, luc = TRUE), ctl, 150), 0.8 * af_luc)
})

test_that("f_luc_perm = 0 reproduces the pre-2026-08-13 behaviour exactly", {
  skip_if_no_cpp()
  # The escape hatch has to actually work, both so the regression can be
  # re-measured and so the fix's size can be quoted. It is NOT a supported
  # configuration -- it is the bug, kept reachable.
  p <- ccx_default_params(); p$f_luc_perm <- 0
  s <- ccx_spinup(p)
  F0 <- lp_background(s); ctl <- lp_co2(s, F0)
  expect_lt(abs(lp_af(s, lp_pulse(F0, luc = TRUE), ctl, LP_LAG)), 0.02)
})

test_that("the cleared fraction is what the arithmetic says it is", {
  # Guards the denominator. Using veg0 instead of land0 would make this ~4x
  # bigger and the debit over-permanent; the two are easy to confuse and the
  # difference is invisible in any single CO2 number.
  s <- ccx_spinup(ccx_default_params())
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
