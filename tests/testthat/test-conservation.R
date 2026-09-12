# =====================================================================
# Gate 1: carbon conservation.
#
# The derivative is written in strict flux form, so total carbon must have zero
# derivative at every RK stage and be conserved to ROUNDOFF at any step size.
# If these fail, the formulation has an asymmetric flux somewhere -- do not
# "fix" them by shrinking dt, which would only hide it.
# =====================================================================

# A closed configuration: no emissions, no 14C sources, no decay-driven leak
# for the 12C budget. ENSO is off (all four coefficients 0 in the defaults).
closed_forcing <- function() {
  list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
       gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = 0)
}

test_state <- function(p = ccx_default_params()) {
  aux  <- ccx_prepare(p)
  y    <- ccx_new_state()
  grid <- aux$grid
  # deliberately NOT an equilibrium: conservation must hold out of balance too
  for (h in HEMIS) {
    i <- aux$idx[[h]]
    y[i$atm,  "C"] <- 300
    y[i$leaf, "C"] <- 30
    y[i$wood, "C"] <- 220
    y[i$soil_fast, "C"] <- 100
    y[i$soil_slow, "C"] <- 600
    y[i$ml,   "C"] <- 400
    y[i$oc,   "C"] <- 1500 * grid$dz[-1] / sum(grid$dz[-1])
  }
  y[, "C13"] <- y[, "C"] * ccx_const("R13_VPDB")
  y[, "C14"] <- y[, "C"] * 1.0
  list(y = y, p = p, aux = aux, grid = grid)
}

test_that("total carbon derivative is exactly zero in a closed system", {
  s <- test_state()
  s$p <- ccx_set_enso(s$p, list(gamma_enso = 0))
  d <- ccx_deriv(s$y, 1900, s$p, closed_forcing(), s$grid, s$aux)
  # Relative to the largest individual box tendency, not to zero in absolute terms
  scale <- max(abs(d[, "C"]))
  expect_lt(abs(sum(d[, "C"])) / scale, 1e-12)
  expect_lt(abs(sum(d[, "C13"])) / max(abs(d[, "C13"])), 1e-12)
})

test_that("total carbon is conserved over a century of integration", {
  s <- test_state()
  s$p <- ccx_set_enso(s$p, list(gamma_enso = 0))
  y <- s$y
  tot0 <- ccx_total(y)
  t <- 1900
  for (m in seq_len(12 * 100)) {
    y <- ccx_step_rk4(y, t, 1 / 12, s$p, closed_forcing(), s$grid, s$aux)
    t <- t + 1 / 12
  }
  expect_lt(abs(ccx_total(y) / tot0 - 1), 1e-10)
  expect_lt(abs(ccx_total(y, "C13") / ccx_total(s$y, "C13") - 1), 1e-10)
})

test_that("conservation is independent of step size (formulation, not accuracy)", {
  s <- test_state(); s$p <- ccx_set_enso(s$p, list(gamma_enso = 0))
  tot0 <- ccx_total(s$y)
  errs <- sapply(c(1L, 4L, 16L), function(ss) {
    y <- s$y; t <- 1900
    for (m in seq_len(120)) {
      y <- ccx_step_rk4(y, t, 1 / 12, s$p, closed_forcing(), s$grid, s$aux, substeps = ss)
      t <- t + 1 / 12
    }
    abs(ccx_total(y) / tot0 - 1)
  })
  # All at roundoff: a step-size-DEPENDENT error would mean the flux form is broken
  expect_true(all(errs < 1e-11))
})

test_that("14C decays at exactly the right rate with transport switched off", {
  # Isolate decay: no transport (kz=0, k_w=0, tau_ex=Inf, no land turnover)
  p <- ccx_default_params()
  p$kz <- 0; p$k_w <- 0; p$tau_ex <- 1e12; p$beta <- 0
  p$tau_leaf <- 1e12; p$tau_wood <- 1e12
  p$tau_soil_fast <- 1e12; p$tau_soil_slow <- 1e12; p <- ccx_set_enso(p, list(gamma_enso = 0))
  p$seas_amp_NH <- 0; p$seas_amp_SH <- 0; p$seas_drivers <- 0  # BOTH seasonal paths off
  s <- test_state(p)
  y <- s$y; t <- 1900
  yrs <- 50
  for (m in seq_len(12 * yrs)) {
    y <- ccx_step_rk4(y, t, 1 / 12, p, closed_forcing(), s$grid, s$aux)
    t <- t + 1 / 12
  }
  expected <- ccx_total(s$y, "C14") * exp(-ccx_const("LAMBDA_C14") * yrs)
  expect_lt(abs(ccx_total(y, "C14") / expected - 1), 1e-9)
  # and 12C must be untouched
  expect_lt(abs(ccx_total(y) / ccx_total(s$y) - 1), 1e-12)
})

# DELETED 2026-09-12 (review A15): "a zero-length run is a no-op, and Delta14C
# of standard carbon is 0" asserted C14/C == 1 on a fixture that had just set
# `C14 <- C * 1.0` three lines earlier -- a tautology on the fixture, and no run
# of any length was made. The decay test above is the one that reads that ratio.

test_that("ocean grid is exactly the stated depth and monotonically coarsening", {
  g <- ccx_ocean_grid(75)
  expect_equal(sum(g$dz), ccx_const("OCEAN_DEPTH"))
  expect_equal(g$dz[1], 75)
  expect_true(all(diff(g$dz[-1]) > 0))
})
