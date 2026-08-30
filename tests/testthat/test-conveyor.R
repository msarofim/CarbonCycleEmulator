# =====================================================================
# Gate: THE CONVEYOR (`q_conv`, `conv_sink`, `conv_descent`, `conv_reverse`,
# added 2026-08-13). NH sinking -> deep interhemispheric flow -> SH upwelling ->
# surface return. The first OCEAN-OCEAN coupling in the model.
#
# Three configurations, from notes/redteam_2026-08-13_conveyor_configurations.md:
#   A  conv_sink = N_INTERIOR, conv_descent = 0   handoff 13b sec.4.2 as written
#   B  conv_sink = N_INTERIOR, conv_descent = 1   distributed descent
#   C  conv_sink = 8,          conv_descent = 0   sink to NADW depth (DEFAULT)
#
# WHAT THIS FILE HAS TO HOLD, and why each one is here:
#
#   1. THE DEFAULT IS INERT. q_conv = 0 must reproduce the pure-diffusion column
#      EXACTLY, or every result computed before 2026-08-13 has silently moved.
#      Test 1 is the guard and test 2 is its MUTATION TEST -- with q_conv > 0 the
#      same comparison must FAIL, or test 1 could be passing because the
#      mechanism does nothing (the lesson of feedback_mutation_test_your_gates:
#      the 14C decay gate was inert for weeks and the suite still passed).
#
#   2. THE SPINUP IS A TRUE FIXED POINT. This is the one that nearly went wrong.
#      Handoff 13b sec.4.2 claims ccx_spinup() "needed no change at all" because
#      a uniform-concentration ocean is still an exact fixed point. THAT IS TRUE
#      WITHIN A COLUMN AND FALSE BETWEEN THEM: the two columns sit at different
#      DIC (SST 18 vs 16 degC -> 2.03786 vs 2.05570 mol/m3), so the
#      interhemispheric limbs see a real gradient. Skipping the solve left a
#      0.135 GtC/yr residual and -0.915 permil of spurious d13C drift over a
#      zero-emission 1750-2024 run -- nearly twice the entire misfit the
#      conveyor was proposed to fix. Tests 3 and 4 are the guards.
#
#   3. IT IS DISTINGUISHABLE FROM ITS OWN REVERSE. The decisive wiring check
#      (sec.4.5 step 1). Handoff 13b sec.2 proved that reversing a CLOSED
#      vertical loop is invisible to the atmosphere; the conveyor breaks both
#      premises of that theorem, so reversing it MUST change the atmosphere. A
#      TIE means the loop has been accidentally closed within a column or the
#      interhemispheric limbs are wired to the wrong boxes.
#      NOTE the gate must be read off an INTEGRATED RUN, not the derivative: the
#      conveyor touches no atmospheric box directly, so dy[atm] is identical
#      forward and reversed at any fixed state. Asserting it on the derivative
#      would be a gate that can never fail.
#
#   4. R AND C++ AGREE. New code in both files.
# =====================================================================

skip_if_no_cpp <- function() {
  skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) skip("C++ core failed to compile")
}

Q_TEST   <- 20            # Sv, inside the observed overturning range
CONV_YRS <- c(1750, 1850)
CONFIGS  <- list(A = list(sink = N_INTERIOR, desc = 0L),
                 B = list(sink = N_INTERIOR, desc = 1L),
                 C = list(sink = 8L,         desc = 0L))

conv_p <- function(q = 0, cfg = CONFIGS$C, reverse = 0L) {
  p <- ccx_default_params()
  p$gamma_enso <- 0; p$seas_amp_NH <- 0; p$seas_amp_SH <- 0; p$seas_drivers <- 0
  p$q_conv <- q; p$conv_sink <- cfg$sink
  p$conv_descent <- cfg$desc; p$conv_reverse <- reverse
  p
}

quiet_forcing <- function(s, years = CONV_YRS) {
  F <- ccx_build_forcing("historical", years, prod_c14 = 0, bomb_total_kmol = 0)
  F$e_foss_NH <- 0; F$e_foss_SH <- 0; F$e_luc_NH <- 0; F$e_luc_SH <- 0
  # THE CUMULATIVE TOO, and this is not bookkeeping. cum_luc shrinks the land's
  # equilibrium (the converted-land term, 2026-08-13), so a forcing with zero
  # LUC FLUX and a non-zero LUC STOCK asks the model to relax a pristine spinup
  # state toward a smaller land -- a real drift, which this helper's callers
  # would read as a conveyor failure. Zeroing only the flux is not "quiet".
  F$cum_luc_NH <- 0; F$cum_luc_SH <- 0
  F <- ccx_hold_climate(F, value = 0); F$c14_bomb <- 0; F$c14_nuclear <- 0
  F$c14_cosmo <- s$prod_c14
  # AND THE VOLCANIC AEROSOL, added 2026-08-30 on Marcus's ruling after
  # CCX_GAMMA_DIFF_DEFAULT went to 0.25. ccx_hold_climate() deliberately does
  # NOT hold aod_* -- AOD is a radiative DRIVER, not a climate variable, and
  # the volcanic temperature signal is already inside the gmst record it does
  # hold (R/forcing.R). That function's own comment states the consequence and
  # the remedy: "a diagnostic that needs a volcanically quiet run must zero
  # aod_NH/aod_SH itself". This is that.
  #
  # SAME SHAPE AS THIS SUITE'S SEASONALITY PRECEDENT: test-luc-permanence.R
  # runs its control seasonless rather than loosening its flatness gate,
  # because seasonality is orthogonal to what that gate measures. Volcanic
  # diffuse-light NPP is orthogonal to conveyor drift in exactly the same way.
  #
  # ⚠ AND THE FAILURE IT FIXES WAS NOT WHAT IT LOOKED LIKE. This window is
  # 1750-1850 and the CMIP7 AOD series BEGINS in 1850, so 99 of these 100
  # years are already volcanically silent. What tripped the gate was the
  # record's TURN-ON STEP landing on the run's LAST year -- which is the one
  # year an endpoint-minus-start drift gate reads. Measured: 0.0246 ppm with
  # AOD free, EXACTLY 0.00000 with it zeroed (calibration/diag_attribute_the_seven.R).
  F$aod_NH <- 0; F$aod_SH <- 0
  F
}

test_that("q_conv = 0 reproduces the pure-diffusion column exactly", {
  skip_if_no_cpp()
  p_off <- conv_p(0)
  # a parameter list with no conveyor fields at all must behave identically to
  # one that carries them set to zero -- the pre-2026-08-13 compatibility path
  p_none <- p_off
  p_none$q_conv <- NULL; p_none$conv_sink <- NULL
  p_none$conv_descent <- NULL; p_none$conv_reverse <- NULL
  s1 <- ccx_spinup(p_off); s2 <- ccx_spinup(p_none)
  expect_equal(s1$y, s2$y, tolerance = 0)
  expect_identical(ccx_substeps_for(p_off, s1$grid), ccx_substeps_for(p_none, s1$grid))
  expect_equal(ccx_advection_eigbound(c(0, 0, 0), s1$grid, p_off), 0)
})

test_that("MUTATION TEST: with q_conv > 0 the inertness comparison must fail", {
  # If this passes, test 1 above is vacuous.
  s_off <- ccx_spinup(conv_p(0))
  s_on  <- ccx_spinup(conv_p(Q_TEST))
  expect_false(isTRUE(all.equal(s_off$y[, "C"], s_on$y[, "C"], tolerance = 1e-10)))
  expect_gt(ccx_advection_eigbound(c(0, 0, 0), s_off$grid, conv_p(Q_TEST)), 0)
})

test_that("the spinup is a TRUE fixed point with the conveyor on, in every config", {
  for (nm in names(CONFIGS)) {
    s <- ccx_spinup(conv_p(Q_TEST, CONFIGS[[nm]]))
    # tighter than the conveyor-off column manages (6.3e-09), because the solve
    # is a Newton on ccx_deriv() itself rather than an analytic guess
    expect_lt(s$diagnostics$max_abs_dCdt, 1e-9)
    expect_lt(s$diagnostics$max_abs_dC13dt, 1e-11)
    # global preindustrial CO2 is the pin; the interhemispheric SPLIT is free
    expect_equal(s$diagnostics$co2_ppm, ccx_const("CO2_PI_PPM"), tolerance = 1e-9)
  }
})

test_that("a quiet run does not drift with the conveyor on", {
  skip_if_no_cpp()
  # THE REGRESSION GUARD for the sec.4.2 error. Before ccx_c12_steady_conveyor()
  # this drifted -0.915 permil of d13C and several ppm of CO2 over 1750-2024.
  for (nm in names(CONFIGS)) {
    p <- conv_p(Q_TEST, CONFIGS[[nm]])
    s <- ccx_spinup(p)
    r <- ccx_run_fast(s, quiet_forcing(s))$out
    co2 <- (r$co2_NH + r$co2_SH)
    expect_lt(abs(co2[length(co2)] - co2[1]), 1e-3)
    expect_lt(abs(r$d13c_NH[length(r$d13c_NH)] - r$d13c_NH[1]), 1e-3)
  }
})

test_that("MUTATION TEST: the quiet run is only quiet BECAUSE the AOD is zeroed", {
  skip_if_no_cpp()
  # Without this, quiet_forcing()'s AOD line could be deleted and the gate
  # above would keep passing for a reason nobody checked -- the same way the
  # 14C decay gate sat inert for weeks (feedback_mutation_test_your_gates).
  #
  # gamma_diff is set EXPLICITLY rather than taken from the default, so this
  # coverage does not move if the default moves. That is the lesson of the
  # 2026-08-29 f[15]/f[16] out-of-bounds read, which survived precisely
  # because the mechanism was off by default.
  p <- conv_p(Q_TEST); p$gamma_diff <- 0.25
  s <- ccx_spinup(p)
  F <- quiet_forcing(s)
  F_aod <- ccx_build_forcing("historical", CONV_YRS, prod_c14 = 0, bomb_total_kmol = 0)
  F$aod_NH <- F_aod$aod_NH; F$aod_SH <- F_aod$aod_SH   # put the volcanoes back
  r <- ccx_run_fast(s, F)$out
  co2 <- (r$co2_NH + r$co2_SH)
  expect_gt(abs(co2[length(co2)] - co2[1]), 1e-3)
})

test_that("the conveyor conserves carbon on the derivative", {
  # on the DERIVATIVE, so this is about the operator and not the integrator
  p <- conv_p(Q_TEST)
  s <- ccx_spinup(p)
  zero <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
               gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0,
               c14_cosmo = 0, d13c_foss = -28)
  y <- s$y
  y[s$aux$idx$NH$ml, "C"]  <- y[s$aux$idx$NH$ml, "C"] * 1.3
  y[s$aux$idx$SH$oc[8], "C"] <- y[s$aux$idx$SH$oc[8], "C"] * 0.7
  d <- ccx_deriv(y, 1800, p, zero, s$grid, s$aux)
  expect_lt(abs(sum(d[, "C"])), 1e-9)
  expect_lt(abs(sum(d[, "C13"])), 1e-11)
})

test_that("REVERSING THE CONVEYOR CHANGES THE ATMOSPHERE (the wiring gate)", {
  skip_if_no_cpp()
  # sec.4.5 step 1. Must be read off an integrated run -- see the header.
  p_f <- conv_p(Q_TEST, reverse = 0L)
  p_r <- conv_p(Q_TEST, reverse = 1L)
  s_f <- ccx_spinup(p_f); s_r <- ccx_spinup(p_r)
  F_f <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0,
                           bomb_total_kmol = 102)
  F_r <- F_f
  F_f$c14_cosmo <- s_f$prod_c14; F_r$c14_cosmo <- s_r$prod_c14
  o_f <- ccx_run_fast(s_f, F_f)$out; o_r <- ccx_run_fast(s_r, F_r)$out
  # NOT a tie: if these are equal the loop is closed within a column
  expect_gt(max(abs(o_f$co2_NH  - o_r$co2_NH)),  1e-3)
  expect_gt(max(abs(o_f$d14c_NH - o_r$d14c_NH)), 1e-2)
  # and the deep ages must SWAP, which is the off-diagonal statement itself
  df <- s_f$diagnostics$d14c_deep_by_hemi
  dr <- s_r$diagnostics$d14c_deep_by_hemi
  expect_gt(df[["NH"]], df[["SH"]])   # forward: NH is the ventilated end
  expect_gt(dr[["SH"]], dr[["NH"]])   # reversed: SH is
})

test_that("without a conveyor the two hemispheres' deep oceans have the same age", {
  # guards the new per-hemisphere diagnostic itself: it must be flat when there
  # is nothing to split, or a spurious split would read as a conveyor signal
  s <- ccx_spinup(conv_p(0))
  d <- s$diagnostics$d14c_deep_by_hemi
  expect_lt(abs(d[["NH"]] - d[["SH"]]), 2)
})

test_that("R and C++ agree with the conveyor on, in every config", {
  skip_if_no_cpp()
  for (nm in names(CONFIGS)) {
    p <- conv_p(Q_TEST, CONFIGS[[nm]]); p$gamma_enso <- 0.5
    s <- ccx_spinup(p)
    F <- ccx_build_forcing("historical", c(1960, 1961), prod_c14 = s$prod_c14)
    frc <- list(e_foss = list(NH = F$e_foss_NH[1], SH = F$e_foss_SH[1]),
                e_luc  = list(NH = F$e_luc_NH[1],  SH = F$e_luc_SH[1]),
                cum_luc = list(NH = F$cum_luc_NH[1], SH = F$cum_luc_SH[1]),
                gmst = F$gmst[1], enso = F$enso[1], c14_bomb = F$c14_bomb[1],
                c14_nuclear = F$c14_nuclear[1], c14_cosmo = F$c14_cosmo[1],
                d13c_foss = F$d13c_foss[1])
    dR <- ccx_deriv(s$y, 1960, p, frc, s$grid, s$aux)
    dC <- ccx_deriv_fast(s$y, 1960, p, frc, s$grid, s$aux)
    for (tr in CCX_TRACERS)
      expect_lt(max(abs(dR[, tr] - dC[, tr])), 1e-9 * max(abs(dR[, tr])) + 1e-12)
  }
})
