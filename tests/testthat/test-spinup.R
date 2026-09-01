# =====================================================================
# Gate 2: the preindustrial steady state is actually steady, hits its
# targets, and produces physically sensible free diagnostics.
# =====================================================================

sp <- local({ p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0)); ccx_spinup(p) })

test_that("the spinup state is genuinely stationary", {
  d <- sp$diagnostics
  # Residuals are limited by the uniroot tolerance on mixed-layer DIC, not by
  # the algebra; 1e-6 GtC/yr against ~60 GtC/yr gross fluxes is 1e-8 relative.
  expect_lt(d$max_abs_dCdt,   1e-6)
  expect_lt(d$max_abs_dC13dt, 1e-10)
  expect_lt(d$max_abs_dC14dt, 1e-10)
})

test_that("spinup reproduces its prescribed targets exactly", {
  d <- sp$diagnostics
  expect_equal(d$co2_ppm,  ccx_const("CO2_PI_PPM"), tolerance = 1e-6)
  expect_equal(d$d13c_atm, ccx_const("D13C_PI"),    tolerance = 1e-6)
  expect_equal(d$d14c_atm, ccx_const("D14C_PI"),    tolerance = 1e-6)
})

test_that("integrating the spinup state forward leaves it unchanged", {
  # The real test of a steady state: run it and see if it moves.
  zero <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
               gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0,
               c14_cosmo = sp$prod_c14)
  p <- sp$params; p <- ccx_set_enso(p, list(gamma_enso = 0)); p$seas_amp_NH <- 0; p$seas_amp_SH <- 0; p$seas_drivers <- 0
  y <- sp$y; t <- 1750
  for (m in seq_len(12 * 50)) {
    y <- ccx_step_rk4(y, t, 1 / 12, p, zero, sp$grid, sp$aux); t <- t + 1 / 12
  }
  atm <- c(sp$aux$idx$NH$atm, sp$aux$idx$SH$atm)
  co2_drift <- sum(y[atm, "C"]) / sum(sp$y[atm, "C"]) - 1
  d14_drift <- 1000 * (sum(y[atm, "C14"]) / sum(y[atm, "C"]) - 1) - sp$diagnostics$d14c_atm
  expect_lt(abs(co2_drift), 1e-4)
  expect_lt(abs(d14_drift), 0.05)      # per mil, over 50 yr
})

test_that("deep-ocean Delta14C lands in the observed range (FREE check)", {
  # Nothing in the spinup targets this: it emerges from Kz, ocean geometry and
  # decay. Observed deep water is roughly -150 to -200 per mil. A value near 0
  # would mean the interior is ventilating far too fast; below -300 far too slow.
  expect_gt(sp$diagnostics$d14c_deep_ocean, -260)
  expect_lt(sp$diagnostics$d14c_deep_ocean, -120)
})

test_that("derived natural 14C production is within a factor of 2 of canonical", {
  # Production is SOLVED FOR, not prescribed, so the canonical cosmogenic
  # estimate (~2.04 atoms/cm2/s ~ 545 mol/yr) is an independent check on the
  # model's carbon inventory and 14C unit bookkeeping. A factor-2 miss would
  # indicate a units error; a 30 % miss reflects the model's ocean inventory
  # sitting below the canonical ~38,000 GtC and the spread in published
  # production estimates (1.6-2.5 atoms/cm2/s).
  expect_gt(sp$diagnostics$prod_ratio, 0.5)
  expect_lt(sp$diagnostics$prod_ratio, 2.0)
})

test_that("preindustrial carbon stocks are physically plausible", {
  d <- sp$diagnostics
  expect_gt(d$ocean_C_GtC, 25000); expect_lt(d$ocean_C_GtC, 45000)
  expect_gt(d$land_C_GtC,   1000); expect_lt(d$land_C_GtC,   4000)
})

test_that("isotopes exchange at equilibrium (the gross-flux fix)", {
  # Regression guard for a real bug: with NET-only fluxes the preindustrial
  # isotope operator had no transport at all (net fluxes vanish at equilibrium),
  # which made it exactly singular. Perturbing one box's 14C must relax back.
  y <- sp$y
  y[sp$aux$idx$NH$ml, "C14"] <- y[sp$aux$idx$NH$ml, "C14"] * 1.05
  zero <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
               gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0,
               c14_cosmo = sp$prod_c14)
  p <- sp$params; p <- ccx_set_enso(p, list(gamma_enso = 0))
  d <- ccx_deriv(y, 1750, p, zero, sp$grid, sp$aux)
  # the perturbed box must lose 14C, and the atmosphere must gain some
  expect_lt(d[sp$aux$idx$NH$ml, "C14"], 0)
  expect_gt(d[sp$aux$idx$NH$atm, "C14"], 0)
})
