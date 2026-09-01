# =====================================================================
# test-pump-conveyor.R -- the BIOLOGICAL PUMP and the CONVEYOR, together.
#
# ⚠ WHY THIS FILE EXISTS, AND A CORRECTION TO THE CLAIM THAT PROMPTED IT.
# `calibration/diag_conveyor_enso_lever.R` (2026-09-01) reported that
# "test-conveyor.R never sets `pump_grad` and test-pump.R never sets `q_conv`,
# so pump-and-conveyor together has NO coverage", and checked carbon
# conservation itself on that basis.
#
# THE FIRST HALF IS TRUE AND THE SECOND HALF IS NOT. `ccx_default_params()`
# ships `pump_grad = PUMP_GRAD_OBS` (233.1094) -- the pump has been ON by
# default since 2026-08-16d -- so test-conveyor.R's `conv_p()` has been running
# BOTH mechanisms all along: its derivative-conservation test, its quiet-run
# drift gate, its spinup fixed-point test and its R/C++ parity test are all
# pump+conveyor tests already.
#
# ⚠ BUT THE COVERAGE IS INCIDENTAL, WHICH IS THE REAL DEFECT. It exists only
# because a default happens to be non-zero, and that default HAS moved once
# already (0 from the port until 08-16d). If it ever moves back, every one of
# those tests keeps passing while quietly testing the conveyor alone -- the
# mirror image of `default_off_hides_the_bug`, where a mechanism defaulted OFF
# hid an out-of-bounds read for two days. test-conveyor.R's own AOD mutation
# test states the rule this file applies to the pump: set the mechanism
# EXPLICITLY, so the coverage does not move when the default moves.
#
# WHAT THIS FILE ADDS THAT NOTHING ELSE HAS:
#   1. AN EXPLICIT PIN on both mechanisms at once, with a mutation test proving
#      the pump is live ALONGSIDE the conveyor rather than merely present.
#   2. THE DIC-LIMITED PUMP with the conveyor on. test-pump.R covers both export
#      modes; `conv_p()` only ever reaches the default nutrient-limited one, so
#      "D" + conveyor is the genuinely untested corner -- and it is the mode in
#      which the pump's export depends on the mixed-layer carbon the conveyor
#      moves, i.e. the one where the two mechanisms actually interact.
#   3. INTEGRATED carbon closure over a long quiet run. The existing gates check
#      the OPERATOR (a derivative) and the observable drift (CO2, d13C); neither
#      says the INTEGRATOR conserves total carbon with both on, which is what
#      the diagnostic measured at 1.8e-10 GtC over 274 yr.
# =====================================================================

PC_Q      <- 20            # Sv, inside the observed overturning range
PC_GRAD   <- 233.1094      # explicit, NOT ccx_default_params()'s -- see above
PC_YRS    <- c(1750, 2024) # the diagnostic's window; ccx_build_forcing() wants
                           # the start of the emissions record, not 1959

pc_p <- function(q = PC_Q, grad = PC_GRAD, mode = "N") {
  p <- ccx_default_params()
  p <- ccx_set_enso(p, list(gamma_enso = 0))
  p$seas_amp_NH <- 0; p$seas_amp_SH <- 0; p$seas_drivers <- 0
  p$gamma_diff <- 0            # explicit: volcanic NPP is orthogonal to this
  p$pump_grad <- grad; p$pump_mode <- mode
  p$q_conv <- q; p$conv_sink <- 8L; p$conv_descent <- 0L; p$conv_reverse <- 0L
  p
}

pc_quiet <- function(s, years = PC_YRS) {
  F <- ccx_build_forcing("historical", years, prod_c14 = 0, bomb_total_kmol = 0)
  F$e_foss_NH <- 0; F$e_foss_SH <- 0; F$e_luc_NH <- 0; F$e_luc_SH <- 0
  # the cumulative too: a non-zero LUC STOCK shrinks the land's equilibrium and
  # the relaxation would read as a closure failure (test-conveyor.R's note)
  F$cum_luc_NH <- 0; F$cum_luc_SH <- 0
  F <- ccx_hold_climate(F, value = 0); F$c14_bomb <- 0; F$c14_nuclear <- 0
  F$c14_cosmo <- 0
  F$aod_NH <- 0; F$aod_SH <- 0
  F
}

pc_forc <- function() list(
  e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
  cum_luc = list(NH = 0, SH = 0),
  gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = 0,
  d13c_foss = -28, aod_NH = 0, aod_SH = 0)

test_that("BOTH mechanisms are live at once, and the pin is EXPLICIT", {
  p <- pc_p()
  expect_gt(p$q_conv, 0)
  expect_gt(p$pump_grad, 0)
  expect_false(is.null(ccx_prepare(p)$pump))
  # the pin must not silently BE the default -- if it ever coincides by
  # accident this test still passes, but the value here is a literal and the
  # coverage survives a default change either way
  expect_identical(p$pump_grad, PC_GRAD)
})

test_that("MUTATION TEST: the pump moves the state ALONGSIDE the conveyor", {
  # Without this, every test below could be passing on a conveyor-only model --
  # exactly the failure mode the incidental coverage above already has.
  s_both <- ccx_spinup(pc_p())
  s_conv <- ccx_spinup(pc_p(grad = 0))
  expect_null(ccx_prepare(pc_p(grad = 0))$pump)
  expect_false(isTRUE(all.equal(s_both$y[, "C"], s_conv$y[, "C"], tolerance = 1e-8)))
  # and the conveyor moves the state alongside the PUMP, the other way round
  s_pump <- ccx_spinup(pc_p(q = 0))
  expect_false(isTRUE(all.equal(s_both$y[, "C"], s_pump$y[, "C"], tolerance = 1e-8)))
})

test_that("the OPERATOR conserves carbon with both on, in BOTH export modes", {
  # on the DERIVATIVE, off a PERTURBED state: at the fixed point every tendency
  # is ~0 and a conservation check divides one small number by another. The
  # perturbation is what gives the gate something to conserve.
  for (mode in c("N", "D")) {
    p <- pc_p(mode = mode)
    s <- ccx_spinup(p)
    y <- s$y
    y[s$aux$idx$NH$ml, "C"]    <- y[s$aux$idx$NH$ml, "C"] * 1.3
    y[s$aux$idx$SH$oc[8], "C"] <- y[s$aux$idx$SH$oc[8], "C"] * 0.7
    d <- ccx_deriv(y, 1900, p, pc_forc(), s$grid, s$aux)
    # an IDENTITY, so the bound is machine-scaled: every flux is emitted through
    # add_flux(), which is antisymmetric by construction
    expect_lt(abs(sum(d[, "C"])) / max(abs(d[, "C"])), 1e-12)
    expect_lt(abs(sum(d[, "C13"])) / max(abs(d[, "C13"])), 1e-12)
  }
})

test_that("the INTEGRATOR closes on a DRIVEN 1750-2024 run, in both modes", {
  skip_if_no_cpp()
  # What the existing gates do NOT say. test-conveyor.R asserts the OBSERVABLES
  # do not drift (CO2, d13C); this asserts that stock change equals input, which
  # is the quantity diag_conveyor_enso_lever.R had to check for itself.
  #
  # ⚠ DRIVEN, NOT QUIET, AND THAT IS THE WHOLE DESIGN OF THIS GATE. The obvious
  # version -- a closed run with no emissions, asserting total carbon does not
  # move -- was written first and MEASURED VACUOUS: from an exact fixed point
  # under a constant forcing, every box's carbon comes back BIT-IDENTICAL after
  # 3300 RK4 months (max |dC| = 0 exactly, CO2 276.5064 -> 276.5064). A closure
  # gate on a state that does not move cannot detect a closure failure. Driving
  # it with 1 GtC/yr moves 43 GtC through the boxes and gives the gate something
  # to close. Same lesson as `gate_reads_its_own_output`: a gate that passes is
  # not a gate that works.
  #
  # TOLERANCE FROM THE ARITHMETIC, not from taste. 3300 monthly increments
  # accumulating into a ~37750 GtC total have a roundoff floor of about
  # sqrt(3300) x 37750 x 2.2e-16 = 4.8e-10 GtC; the measured closure is
  # 1.0e-10 GtC (matching the 1.8e-10 the diagnostic reported over the same
  # window). 1e-8 is ~20x the floor -- tight enough to see a real leak, loose
  # enough not to be a roundoff alarm.
  PC_CLOSE <- 1e-8            # GtC
  for (mode in c("N", "D")) {
    p <- pc_p(mode = mode)
    s <- ccx_spinup(p)
    F <- pc_quiet(s)
    F$e_foss_NH <- 1                       # GtC/yr, a pure external source
    r <- ccx_run_fast(s, F)
    emit   <- sum(F$e_foss_NH) / 12        # monthly rows, annual rate
    dstock <- ccx_total(r$state) - ccx_total(s$y)
    expect_lt(abs(dstock - emit), PC_CLOSE)
    # AND THE GATE HAS THE POWER TO SEE A LEAK. Restating the input wrong by
    # 1e-6 GtC -- a hundredth of the smallest leak worth caring about -- must
    # trip it. Without this the bound above could be looser than the quantity
    # it bounds and nobody would know.
    expect_gt(abs(dstock - (emit + 1e-6)), PC_CLOSE)
    # the carbon really did move, or the closure above is the vacuous version
    expect_gt(max(abs(r$state[, "C"] - s$y[, "C"])), 1)
  }
})

test_that("R and C++ agree with the pump AND the conveyor on, in both modes", {
  skip_if_no_cpp()
  # test-pump.R runs parity with the pump on and no conveyor; test-conveyor.R
  # runs it with the conveyor on and the pump at whatever the default is. The
  # DIC-limited mode with the conveyor on is the corner neither reaches -- and
  # it is the one where the pump's export reads the mixed-layer carbon the
  # conveyor is moving, so the two mechanisms genuinely interact.
  for (mode in c("N", "D")) {
    p <- pc_p(mode = mode)
    s <- ccx_spinup(p)
    y <- s$y
    y[s$aux$idx$NH$ml, "C"] <- y[s$aux$idx$NH$ml, "C"] * 1.15
    dR <- ccx_deriv(y, 1960, p, pc_forc(), s$grid, s$aux)
    dC <- ccx_deriv_fast(y, 1960, p, pc_forc(), s$grid, s$aux)
    for (tr in CCX_TRACERS)
      expect_lt(max(abs(dR[, tr] - dC[, tr])), 1e-9 * max(abs(dR[, tr])) + 1e-12)
  }
})
