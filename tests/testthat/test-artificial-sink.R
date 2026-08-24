# =====================================================================
# The artificial mid-century sink, routed into the OCEAN BOX (2026-08-23c).
#
# These are the four mechanical gates pre-registered in
# notes/prereg_2026-08-24_ocean_sink_14c_null.md sec."Mechanical gates" -- the
# fifth (the 14C null) is a SCIENTIFIC prediction and is checked by the arm
# driver, not here, because it is a statement about what the world does and not
# about whether the code is right.
#
# WHY EACH ONE EXISTS, since a gate nobody can justify gets relaxed later:
#   1. rate 0 is BIT-identical      -- the instrument must be inert when off, in
#                                      all three modes, or every existing result
#                                      quietly stops reproducing.
#   2. conservation                 -- C, 13C and 14C all closed with the flux
#                                      ON. The negative-emission arm could not
#                                      have this gate; it is the whole point of
#                                      routing through add_flux.
#   3. the ocean gains what the      -- the property that makes this an UPTAKE
#      atmosphere loses                 rather than a negative emission.
#   4. R <-> C++ parity              -- the sampler and every diagnostic run the
#                                      C++ core. R-only would leave them on the
#                                      un-sunk model while the R path said
#                                      otherwise.
# =====================================================================

# The instrument reads its rate from a forcing column, so these gates drive it
# by writing that column directly rather than by setting an env var and
# rebuilding -- CCX_ARTIFICIAL_SINK_RATE is resolved at SOURCE time, so an
# in-test Sys.setenv would not reach it, and a gate that silently tested the
# OFF state is worse than no gate. Mutation-tested: setting SINK_TEST_RATE to 0
# makes gates 3 fail (nothing to detect) -- see the assertion in gate 3 that the
# effect is non-trivial.
SINK_TEST_RATE <- 2.5      # GtC/yr, the literature-sized rate the arms use
SINK_TEST_WIN  <- c(1942, 1949)

# Local copies of test-conservation.R's closed system and test-parity.R's
# tolerance. testthat evaluates each file in its OWN environment, so a helper
# defined at the top of another test file is NOT in scope here -- copying is the
# only alternative to promoting them to setup.R, and promoting them would change
# what those files test. Kept deliberately identical; if the originals move,
# these must move with them.
sink_closed_forcing <- function() {
  list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
       gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = 0)
}
sink_test_state <- function(p = ccx_default_params()) {
  aux  <- ccx_prepare(p)
  y    <- ccx_new_state()
  grid <- aux$grid
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
SINK_PARITY_REL_TOL <- 5e-14      # = test-parity.R's PARITY_REL_TOL, derived there

sink_forcing <- function(years = c(1930, 1960), rate = SINK_TEST_RATE) {
  sp <- ccx_spinup(ccx_default_params())
  F  <- suppressWarnings(
    ccx_build_forcing("historical", years, prod_c14 = sp$prod_c14))
  F$sink_ocean <- ifelse(F$year >= SINK_TEST_WIN[1] & F$year <= SINK_TEST_WIN[2],
                         rate, 0)
  list(sp = sp, F = F)
}

test_that("rate 0 is inert in every mode, and the column exists", {
  # The column is built unconditionally and is identically zero unless BOTH the
  # rate and the mode select it -- so a forcing built with the switch off is the
  # pre-2026-08-23c forcing plus a column of zeros.
  sp <- ccx_spinup(ccx_default_params())
  F0 <- suppressWarnings(
    ccx_build_forcing("historical", c(1940, 1950), prod_c14 = sp$prod_c14))
  expect_true("sink_ocean" %in% names(F0))
  expect_true(all(F0$sink_ocean == 0))
  expect_identical(CCX_ARTIFICIAL_SINK_RATE, 0)   # default OFF

  # and a zero column emits NOTHING: identical to a forcing without the column
  # at all, which is the absence contract ccx_forcing_at()/ccx_deriv() carry.
  d_col <- ccx_deriv(sp$y, 1945.5, sp$params, ccx_forcing_at(F0, 1),
                     sp$grid, sp$aux)
  fa <- ccx_forcing_at(F0, 1); fa$sink_ocean <- NULL
  d_no <- ccx_deriv(sp$y, 1945.5, sp$params, fa, sp$grid, sp$aux)
  expect_identical(d_col, d_no)
})

test_that("the sink conserves C, 13C and 14C exactly", {
  # A CLOSED system with the sink on: no emissions, no 14C sources. Total
  # carbon must have zero derivative, exactly as gate 1 requires of every other
  # flux in the model. Same test_state()/sink_closed_forcing() helpers as
  # test-conservation.R, with the sink column added.
  s <- sink_test_state()
  s$p$gamma_enso <- 0
  fc <- sink_closed_forcing(); fc$sink_ocean <- SINK_TEST_RATE
  d  <- ccx_deriv(s$y, 1945.5, s$p, fc, s$grid, s$aux)
  expect_lt(abs(sum(d[, "C"]))   / max(abs(d[, "C"])),   1e-12)
  expect_lt(abs(sum(d[, "C13"])) / max(abs(d[, "C13"])), 1e-12)

  # 14C IS NOT CONSERVED AND MUST NOT BE ASSERTED TO BE -- it decays, so the
  # closed-system total falls by lambda * N even with every flux perfectly
  # antisymmetric (this is why test-conservation.R checks C and C13 only, and
  # asserting it here failed at 4.2e-4, which is the decay rate, not a leak).
  # THE SINK'S OWN CONTRIBUTION is what has to be conservative, and that is a
  # DIFFERENCE, not a total: on minus off must sum to zero in all three tracers.
  d0 <- ccx_deriv(s$y, 1945.5, s$p, sink_closed_forcing(), s$grid, s$aux)
  dd <- d - d0
  for (tr in CCX_TRACERS)
    expect_lt(abs(sum(dd[, tr])) / max(abs(dd[, tr])), 1e-12)

  # ...and over a century of integration, not just at one state.
  y <- s$y; tot0 <- ccx_total(y); t <- 1900
  for (m in seq_len(12 * 100)) {
    y <- ccx_step_rk4(y, t, 1 / 12, s$p, fc, s$grid, s$aux)
    t <- t + 1 / 12
  }
  expect_lt(abs(ccx_total(y) / tot0 - 1), 1e-10)
  expect_lt(abs(ccx_total(y, "C13") / ccx_total(s$y, "C13") - 1), 1e-10)
})

test_that("the ocean gains exactly what the atmosphere loses", {
  # THE PROPERTY THE NEGATIVE-EMISSION ARM COULD NOT HAVE. Measured on the
  # DERIVATIVE, at one state, with everything else held identical: the
  # difference between sink-on and sink-off must be +rate into the two mixed
  # layers and -rate out of the two atmospheres, and ZERO everywhere else.
  s <- sink_test_state()
  s$p$gamma_enso <- 0
  f_off <- sink_closed_forcing()
  f_on  <- sink_closed_forcing(); f_on$sink_ocean <- SINK_TEST_RATE
  d0 <- ccx_deriv(s$y, 1945.5, s$p, f_off, s$grid, s$aux)
  d1 <- ccx_deriv(s$y, 1945.5, s$p, f_on,  s$grid, s$aux)
  dd <- d1 - d0

  atm <- vapply(HEMIS, function(h) s$aux$idx[[h]]$atm, integer(1))
  ml  <- vapply(HEMIS, function(h) s$aux$idx[[h]]$ml,  integer(1))
  # non-trivial: the gate is worthless if the effect is zero (mutation test)
  expect_gt(abs(sum(dd[ml, "C"])), 1)
  expect_equal(sum(dd[ml,  "C"]),  SINK_TEST_RATE, tolerance = 1e-12)
  expect_equal(sum(dd[atm, "C"]), -SINK_TEST_RATE, tolerance = 1e-12)
  # every other box untouched
  other <- setdiff(seq_len(nrow(dd)), c(atm, ml))
  expect_equal(max(abs(dd[other, ])), 0)

  # SPLIT ON OCEAN AREA, not on the fossil share -- the split is the difference
  # between an ocean uptake and a relabelled emission.
  sh_NH <- s$aux$asx$NH / (s$aux$asx$NH + s$aux$asx$SH)
  expect_equal(dd[ml[["NH"]], "C"], SINK_TEST_RATE * sh_NH, tolerance = 1e-12)
  expect_false(isTRUE(all.equal(sh_NH, FORC_FOSS_NH_SHARE, tolerance = 1e-3)))

  # ISOTOPES AT THE SOURCE RATIO. 13C carries alpha_as_down; 14C carries NO
  # fractionation. This is the mechanism behind the pre-registered 14C null, so
  # it is asserted directly rather than inferred from a run.
  for (h in HEMIS) {
    ia <- s$aux$idx[[h]]$atm; im <- s$aux$idx[[h]]$ml
    fC <- dd[im, "C"]
    r13 <- s$y[ia, "C13"] / s$y[ia, "C"]
    r14 <- s$y[ia, "C14"] / s$y[ia, "C"]
    expect_equal(dd[im, "C13"], fC * r13 * s$aux$alpha_as_down, tolerance = 1e-12)
    expect_equal(dd[im, "C14"], fC * r14, tolerance = 1e-12)
  }
})

test_that("R and C++ agree with the sink on", {
  skip_if_no_cpp()
  p <- ccx_default_params(); p$gamma_enso <- 0.5
  sp <- ccx_spinup(p)
  forc <- list(e_foss = list(NH = 8, SH = 0.4), e_luc = list(NH = 0.6, SH = 0.5),
               cum_luc = list(NH = 120, SH = 80),
               gmst = 1.1, enso = 0.7, c14_bomb = 1200, c14_nuclear = 40,
               c14_cosmo = sp$prod_c14, d13c_foss = -27.6,
               sink_ocean = SINK_TEST_RATE)
  dR <- ccx_deriv(sp$y, 1945.5, p, forc, sp$grid, sp$aux)
  dC <- ccx_deriv_fast(sp$y, 1945.5, p, forc, sp$grid, sp$aux)
  expect_lt(max(abs(dR - dC)) / max(abs(dR)), SINK_PARITY_REL_TOL)

  # ...and over a full run through the C++ core, against the R reference.
  sf <- sink_forcing()
  rR <- ccx_run(sf$sp, sf$F)
  rC <- ccx_run_fast(sf$sp, sf$F)
  for (cc in c("co2_NH", "co2_SH", "d13c_NH", "d14c_NH", "ocean_C")) {
    expect_lt(max(abs(rR$out[[cc]] - rC$out[[cc]])) /
                max(abs(rR$out[[cc]])), 1e-10)
  }
  # the run is NOT a no-op: the sink actually moved CO2 (mutation test)
  F0 <- sf$F; F0$sink_ocean <- 0
  r0 <- ccx_run_fast(sf$sp, F0)
  expect_gt(max(abs(rC$out$co2_NH - r0$out$co2_NH)), 0.1)
})
