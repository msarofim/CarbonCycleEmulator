# =====================================================================
# test-enso-split.R -- the ENSO response went LAND/OCEAN x NH/SH 2026-09-01
# (Marcus's design call; notes/handoff_2026-09-01_enso_arc.md sec.6).
#
# `gamma_enso` was ONE scalar moving LAND ONLY, split 50/50 between the
# hemispheres by a hardcoded `aux$enso_share`. Measured against GCB over
# 1959-2024 with a shared estimator: the land response is 53 % of observed and
# the OCEAN response is ANTI-correlated with it (r = -0.51 [-0.68, -0.28]
# against an observed +0.535 [+0.29, +0.72]). The two errors CANCEL 87 % in CO2
# growth, which is why a fit that outvotes partition 40:1 never saw them.
#
# WHAT THIS FILE HAS TO HOLD:
#   1. THE ABSENCE CONTRACT, IN BOTH CORES. A pre-split list carries only the
#      legacy scalar and must reproduce the old model BIT FOR BIT -- the
#      behaviour-preserving default the `gamma_diff` adoption did not have.
#      ⚠ And R and C++ must agree about it: on 2026-08-30 `gamma_diff`'s two
#      fallbacks had drifted apart for a 0.647 GtC/yr parity break that every
#      test missed, because they all pinned EXPLICIT values and an explicit
#      value never exercises a fallback.
#   2. BOTH-AT-ONCE IS AN ERROR. One name became four at ~70 call sites; a
#      precedence rule would have let every one of them run with ENSO OFF and
#      report a number.
#   3. THE MECHANISMS ARE REAL. The land pair must be separable by hemisphere,
#      and the OCEAN pair must move the ocean -- in the direction the
#      observation asks for -- or the split is decoration and test 1 passes
#      vacuously.
#   4. THE ISOTOPES ARE WHAT MAKE THE FOUR IDENTIFIABLE, so the ocean term must
#      carry the AIR-SEA fractionation of its own direction and NOT the land
#      one. That is the load-bearing half of the design.
#   5. PARITY AT UNEQUAL, NON-ZERO COEFFICIENTS -- an all-equal set cannot
#      distinguish the four from the old scalar.
# =====================================================================

ge_p <- function(land_NH = NULL, land_SH = NULL, ocn_NH = NULL, ocn_SH = NULL,
                 legacy = NULL) {
  p <- ccx_default_params()
  # ⚠ the four are FIELDS of ccx_default_params() now, so a legacy test list
  # has to REMOVE them -- assigning the scalar alongside them is the error
  # case, not the legacy case.
  if (!is.null(legacy)) {
    p <- p[setdiff(names(p), CCX_ENSO_PARAMS)]
    p$gamma_enso <- legacy
  } else {
    p$gamma_enso_land_NH <- land_NH; p$gamma_enso_land_SH <- land_SH
    p$gamma_enso_ocn_NH  <- ocn_NH;  p$gamma_enso_ocn_SH  <- ocn_SH
  }
  p
}

ge_forc_at <- function(F, i) list(
  e_foss = list(NH = F$e_foss_NH[i], SH = F$e_foss_SH[i]),
  e_luc  = list(NH = F$e_luc_NH[i],  SH = F$e_luc_SH[i]),
  cum_luc = list(NH = F$cum_luc_NH[i], SH = F$cum_luc_SH[i]),
  gmst = F$gmst[i], enso = F$enso[i], c14_bomb = F$c14_bomb[i],
  c14_nuclear = F$c14_nuclear[i], c14_cosmo = F$c14_cosmo[i],
  d13c_foss = F$d13c_foss[i], sst_anom_NH = F$sst_anom_NH[i],
  sst_anom_SH = F$sst_anom_SH[i], sink_ocean = F$sink_ocean[i],
  aod_NH = F$aod_NH[i], aod_SH = F$aod_SH[i])

test_that("the split is declared, and every entry carries the ORIGINAL prior", {
  expect_true(all(CCX_ENSO_PARAMS %in% CCX_PARAM_NAMES))
  # the retired name must be GONE, not merely unused: a list carrying it is a
  # pre-split list and must take ccx_gamma_enso()'s legacy branch
  expect_false("gamma_enso" %in% CCX_PARAM_NAMES)
  # the split adds degrees of freedom; it must not smuggle in a new belief
  # about any ONE of them. (It DOES widen the implied prior on the land TOTAL
  # by sqrt(2) -- deliberate, and recorded at the table.)
  for (x in c(-1, 0, 0.85119, 2))
    for (n in CCX_ENSO_PARAMS)
      expect_equal(CCX_PARAM_TABLE[[n]]$prior(x), dnorm(x, 0, 2, log = TRUE))
  # the OCEAN pair starts at the incumbent model, which is the mechanism OFF
  expect_equal(CCX_PARAM_TABLE$gamma_enso_ocn_NH$init, 0)
  expect_equal(CCX_PARAM_TABLE$gamma_enso_ocn_SH$init, 0)
})

test_that("THE ABSENCE CONTRACT: a legacy scalar reaches the LAND pair only", {
  g <- ccx_gamma_enso(ge_p(legacy = 0.85119))
  expect_equal(unname(g[c("land_NH", "land_SH")]),
               rep(0.85119 * 0.5, 2))
  # the ocean mechanism did not exist, so a fitted ancestor gets ZERO -- not a
  # share of the land coefficient, which would invent a response the fit never
  # saw, with the wrong sign at that
  expect_equal(unname(g[c("ocn_NH", "ocn_SH")]), c(0, 0))
  # neither field nor legacy -> the named default, not a silent something
  p_none <- ccx_default_params()[setdiff(names(ccx_default_params()), CCX_ENSO_PARAMS)]
  expect_equal(unname(ccx_gamma_enso(p_none)), rep(CCX_GAMMA_ENSO_DEFAULT, 4))
  # explicit fields are used as given
  expect_equal(unname(ccx_gamma_enso(ge_p(0.4, 0.3, 0.2, 0.1))),
               c(0.4, 0.3, 0.2, 0.1))
})

test_that("BOTH the scalar and the split fields is an ERROR, not a precedence rule", {
  # This is the guard that turns ~70 stale `p$gamma_enso <- ...` call sites
  # into a loud stop instead of a silent run with the response switched OFF.
  p <- ccx_default_params()          # carries the four
  p$gamma_enso <- 0.85119            # ... and now the retired scalar as well
  expect_error(ccx_gamma_enso(p), "BOTH")
  # and the error survives the trip through either core's entry point
  expect_error(ccx_cpp_par(p), "BOTH")
})

test_that("a pre-split parameter list is BIT-IDENTICAL to the explicit half-pair", {
  skip_if_no_cpp()
  s_leg <- ccx_spinup(ge_p(legacy = 0.85119))
  s_new <- ccx_spinup(ge_p(land_NH = 0.85119 / 2, land_SH = 0.85119 / 2,
                           ocn_NH = 0, ocn_SH = 0))
  F <- suppressWarnings(ccx_build_forcing("historical", c(1960, 1990),
                                          prod_c14 = s_leg$prod_c14))
  a <- ccx_run_fast(s_leg, F)$out; b <- ccx_run_fast(s_new, F)$out
  expect_equal(a$co2_NH, b$co2_NH, tolerance = 0)
  expect_equal(a$co2_SH, b$co2_SH, tolerance = 0)
  expect_equal(a$d13c_NH, b$d13c_NH, tolerance = 0)
})

test_that("MUTATION TEST: the land pair separates by HEMISPHERE", {
  skip_if_no_cpp()
  # If this fails, the tests above are passing on a parameter that does nothing
  # -- the lesson of the 14C decay gate, inert for weeks.
  s_eq <- ccx_spinup(ge_p(land_NH = 0.4256, land_SH = 0.4256))
  s_un <- ccx_spinup(ge_p(land_NH = 0.8512, land_SH = 0))
  F <- suppressWarnings(ccx_build_forcing("historical", c(1960, 1990),
                                          prod_c14 = s_eq$prod_c14))
  a <- ccx_run_fast(s_eq, F)$out; b <- ccx_run_fast(s_un, F)$out
  # same TOTAL land coefficient, so this can only be the hemispheric split
  expect_gt(max(abs(a$co2_NH - b$co2_NH)), 1e-3)
  expect_gt(max(abs((a$co2_NH - a$co2_SH) - (b$co2_NH - b$co2_SH))), 1e-3)
})

test_that("MUTATION TEST: the ocean pair moves the OCEAN, in the observed direction", {
  skip_if_no_cpp()
  # The whole point of the term: a positive coefficient must make the ocean
  # take up MORE carbon in a warm ENSO year, which is the sign GCB reports
  # (r = +0.535) and the sign the model cannot produce through SST alone.
  p0 <- ge_p(land_NH = 0, land_SH = 0, ocn_NH = 0, ocn_SH = 0)
  p1 <- ge_p(land_NH = 0, land_SH = 0, ocn_NH = 0.137, ocn_SH = 0.137)
  s0 <- ccx_spinup(p0); s1 <- ccx_spinup(p1)
  F <- suppressWarnings(ccx_build_forcing("historical", c(1960, 1961),
                                          prod_c14 = s0$prod_c14))
  # THE INDEX IS SET, not searched for: a warm-phase month has to exist for the
  # sign of the response to be readable, and "whatever 1960 happened to do" is
  # not a fixture. +1 index unit, so the flux IS the coefficient.
  fy <- ge_forc_at(F, 1); fy$enso <- 1
  d0 <- ccx_deriv(s0$y, F$t[1], p0, fy, s0$grid, s0$aux)
  d1 <- ccx_deriv(s1$y, F$t[1], p1, fy, s1$grid, s1$aux)
  ml <- vapply(HEMIS, function(h) s0$aux$idx[[h]]$ml, integer(1))
  atm <- vapply(HEMIS, function(h) s0$aux$idx[[h]]$atm, integer(1))
  expect_gt(sum(d1[ml, "C"]) - sum(d0[ml, "C"]), 0)      # ocean gains
  expect_lt(sum(d1[atm, "C"]) - sum(d0[atm, "C"]), 0)    # atmosphere loses
  # and the two are the same carbon: this flux moves it, it does not make it
  expect_equal(sum(d1[, "C"]) - sum(d0[, "C"]), 0, tolerance = 1e-10)
})

test_that("the OCEAN term carries the AIR-SEA fractionation, not the land one", {
  skip_if_no_cpp()
  # THE LOAD-BEARING HALF OF THE DESIGN. Each anomaly carries the fractionation
  # of its OWN uptake path -- that is what makes the four identifiable, because
  # the land path is ~8x stronger on d13C and OPPOSITE in sign. If the ocean
  # term were emitted unfractionated (alpha13 = 1) this test fails, and the
  # ocean pair would then be identifiable only through CO2.
  p0 <- ge_p(land_NH = 0, land_SH = 0, ocn_NH = 0, ocn_SH = 0)
  p1 <- ge_p(land_NH = 0, land_SH = 0, ocn_NH = 0.137, ocn_SH = 0.137)
  s0 <- ccx_spinup(p0); s1 <- ccx_spinup(p1)
  F <- suppressWarnings(ccx_build_forcing("historical", c(1960, 1961),
                                          prod_c14 = s0$prod_c14))
  fy <- ge_forc_at(F, 1); fy$enso <- 1
  d0 <- ccx_deriv(s0$y, F$t[1], p0, fy, s0$grid, s0$aux)
  d1 <- ccx_deriv(s1$y, F$t[1], p1, fy, s1$grid, s1$aux)
  atm <- vapply(HEMIS, function(h) s0$aux$idx[[h]]$atm, integer(1))
  dC   <- sum(d1[atm, "C"])   - sum(d0[atm, "C"])
  dC13 <- sum(d1[atm, "C13"]) - sum(d0[atm, "C13"])
  # the 13C/C ratio of the carbon this term removes, against the atmosphere's
  # own ratio: the quotient IS the applied fractionation factor
  r_atm <- sum(s0$y[atm, "C13"]) / sum(s0$y[atm, "C"])
  # ⚠ UPDATED 2026-09-02, and it FIRED first: this read `s0$aux$alpha_as_down`,
  # which is now the RETIRED SCALAR. The claim is unchanged -- the ENSO ocean
  # limb rides the INVASION alpha -- but that alpha is a function of SST, so the
  # expectation is resolved through `ccx_alpha_as()` as the model resolves it.
  # ⚠ The deriv runs at F$t[1] with seasonality ON, so the two hemispheres see
  # different SSTs; this is a summed-over-hemispheres quantity, so it is bracketed
  # by the two rather than pinned to one. Tight: the bracket is ~0.002 wide on a
  # factor of ~0.999, and the retired scalar 0.998 is OUTSIDE it, which is
  # asserted below so the bracket cannot be satisfied by the old constant.
  a_dn <- vapply(HEMIS, function(h) ccx_alpha_as(s0$aux$sst[[h]], s0$aux)$down, 0)
  q <- dC13 / dC / r_atm
  expect_gte(q, min(a_dn) - 1e-6); expect_lte(q, max(a_dn) + 1e-6)
  expect_false(isTRUE(all.equal(q, 1)))                      # a real alpha
  expect_false(isTRUE(all.equal(q, s0$aux$alpha_as_down,     # NOT the retired one
                                tolerance = 1e-6)))
})

test_that("R and C++ agree at four UNEQUAL coefficients, and on the legacy path", {
  skip_if_no_cpp()
  for (p in list(ge_p(land_NH = 0.52, land_SH = 0.33,     # explicit, UNEQUAL,
                      ocn_NH = 0.18, ocn_SH = -0.09),     # and ocean SIGNED
                 ge_p(legacy = 0.85119))) {               # the fallback path
    s <- ccx_spinup(p)
    F <- suppressWarnings(ccx_build_forcing("historical", c(1960, 1962),
                                            prod_c14 = s$prod_c14))
    # the index is SET, not searched for: parity on a month that happened to
    # be ENSO-neutral is parity on a term that was never evaluated
    fy <- ge_forc_at(F, 1); fy$enso <- 1.4
    dR <- ccx_deriv(s$y, F$t[1], p, fy, s$grid, s$aux)
    dC <- ccx_deriv_fast(s$y, F$t[1], p, fy, s$grid, s$aux)
    for (tr in CCX_TRACERS)
      expect_lt(max(abs(dR[, tr] - dC[, tr])), 1e-9 * max(abs(dR[, tr])) + 1e-12)
  }
})

test_that("ccx_migrate_par_set reproduces the LEGACY reading exactly", {
  # The migration must hold no opinion of its own: it reads ccx_gamma_enso(),
  # the one resolver both cores go through. A migrated legacy list must encode
  # IDENTICALLY to one whose four fields were set by hand. Not close: identical.
  # ⚠ ccx_mode_params() is itself a PRE-split list -- the canonical mode
  # predates both this split and the seas_lag_p one -- so "an ancestor current
  # in every other respect" has to be constructed, or this test measures the
  # lag migration instead.
  p <- ccx_migrate_par_set(ccx_mode_params()); attr(p, "migrated") <- NULL
  p_old <- p[setdiff(names(p), CCX_ENSO_PARAMS)]
  p_old$gamma_enso <- 0.85119

  mig <- ccx_migrate_par_set(p_old)
  expect_setequal(attr(mig, "migrated"), CCX_ENSO_PARAMS)
  expect_true(all(CCX_ENSO_PARAMS %in% attr(mig, "migrated")))
  expect_identical(mig$gamma_enso_land_NH, 0.85119 * 0.5)
  expect_identical(mig$gamma_enso_land_SH, 0.85119 * 0.5)
  expect_identical(mig$gamma_enso_ocn_NH, 0)
  expect_identical(mig$gamma_enso_ocn_SH, 0)
  # and it DROPS the retired scalar, or the result is a list ccx_gamma_enso()
  # refuses to read
  expect_null(mig$gamma_enso)
  expect_silent(ccx_gamma_enso(mig))

  p_hand <- p_old; p_hand$gamma_enso <- NULL
  p_hand$gamma_enso_land_NH <- p_hand$gamma_enso_land_SH <- 0.85119 * 0.5
  p_hand$gamma_enso_ocn_NH  <- p_hand$gamma_enso_ocn_SH  <- 0
  expect_identical(ccx_par_to_unc(mig), ccx_par_to_unc(p_hand))
})

test_that("migration REFUSES a list that carries no ENSO response at all", {
  # Filling from CCX_GAMMA_ENSO_DEFAULT would turn a warm start into an
  # invented coordinate wearing a fitted vector's name.
  p <- ccx_migrate_par_set(ccx_mode_params()); attr(p, "migrated") <- NULL
  p_none <- p[setdiff(names(p), c(CCX_ENSO_PARAMS, "gamma_enso"))]
  expect_error(ccx_migrate_par_set(p_none), "not a fitted ancestor")
})

test_that("a stored vector decodes and encodes under ITS OWN names", {
  u <- structure(as.list(rep(0, length(CCX_PARAM_NAMES))), names = CCX_PARAM_NAMES)
  expect_named(ccx_unc_to_par(u), CCX_PARAM_NAMES)
  u_old <- u[setdiff(names(u), CCX_ENSO_PARAMS)]
  u_old$gamma_enso <- 0
  expect_error(ccx_unc_to_par(u_old), "different parameter set")

  p <- ccx_migrate_par_set(ccx_mode_params()); attr(p, "migrated") <- NULL
  p_old <- p[setdiff(names(p), CCX_ENSO_PARAMS)]
  p_old$gamma_enso <- 0.85119
  err <- tryCatch(ccx_par_to_unc(p_old), error = conditionMessage)
  expect_match(err, "different parameter set")
  expect_match(err, "gamma_enso_land_NH")
})
