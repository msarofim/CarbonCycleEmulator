# =====================================================================
# DEPTH-DEPENDENT INTERIOR DIFFUSIVITY -- `kz_deep_frac` / `kz_zscale` (2026-09-06b)
#
#     K(z_k) = kz * [ f + (1 - f) * exp(-(z_k - h_ml) / z_K) ]
#
# anchored so K(h_ml) = kz exactly. Pre-registered in
# notes/prereg_2026-09-06b_kz_profile_with_conduit.md. The mechanism exists
# because 2026-09-04k measured K(z) WITHOUT a conduit (counterproductive) and
# 2026-09-06 measured the conduit WITHOUT K(z) (starves the thermocline); DESIGN
# sec.3.4a's B2 is the two together and had never been run.
#
# WHAT THESE TESTS GUARD:
#   * f = 1 -- and ABSENCE -- reproduce the model BIT FOR BIT, in the spinup AND
#     in a transient. A parameter list written before today must not change model.
#   * kz_zscale is INERT at f = 1 (so a stale value cannot leak in).
#   * the switch is MUTATION-TESTED: f = 0.5 must move the deep Delta14C. A knob
#     that is read but not acted on reports "no effect" identically to one that
#     was measured ([[no_power_null]], [[default_off_hides_the_bug]]).
#   * the profile is anchored: K at the ML base IS kz, and K falls monotonically
#     to f * kz.
#   * BOTH cores read the same vector: R vs C++ parity at f = 0.5, with the HS
#     boxes on, because that is the configuration the prereg runs.
#   * conservation survives a non-uniform K -- each interface flux is applied
#     to both layers, so K's value cannot leak carbon.
#   * the pump's export solve reads the profile (it must be solved against the
#     operator the model mixes with, or the DIC gradient is held by a different
#     K than the one that erodes it).
#   * invalid values ERROR BY NAME. A silent clamp is a mechanism defaulted OFF.
#   * the substep bound is unchanged at f = 1 and never smaller at f < 1.
# =====================================================================

skip_if_no_cpp <- function() {
  skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) skip("C++ core failed to compile")
}

kp_par <- function(f = NULL, zs = NULL, hs = FALSE) {
  p <- ccx_default_params()
  if (!is.null(f))  p$kz_deep_frac <- f
  if (!is.null(zs)) p$kz_zscale <- zs
  if (hs) { p$hs_frac <- 0.16; p$u_hs <- 38; p$tau_q <- 538; p$sst_hs <- 2 }
  p
}
zero_forcing <- function(sp) list(
  e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
  cum_luc = list(NH = 0, SH = 0), gmst = 0, enso = 0,
  c14_bomb = 0, c14_nuclear = 0, d13c_foss = -27.6, c14_cosmo = sp$prod_c14)

test_that("the default is f = 1 with HILDA's z0, and the profile is then uniform", {
  p <- ccx_default_params()
  expect_identical(p$kz_deep_frac, 1)
  expect_identical(p$kz_zscale, 253)
  g <- ccx_ocean_grid(p$h_ml)
  expect_identical(ccx_kz_profile(p, g), rep(p$kz, g$nl))
})

test_that("f = 1 and ABSENCE reproduce the model bit for bit -- spinup and transient", {
  skip_if_no_cpp()
  p1  <- kp_par(1)
  pab <- ccx_default_params(); pab$kz_deep_frac <- NULL; pab$kz_zscale <- NULL
  s1 <- ccx_spinup(p1); sab <- ccx_spinup(pab)
  expect_identical(s1$y, sab$y)
  expect_identical(s1$aux$kz_int, rep(p1$kz, s1$grid$nl))
  expect_identical(sab$aux$kz_int, rep(pab$kz, sab$grid$nl))
  F  <- ccx_build_forcing("historical", c(1955, 1960), prod_c14 = s1$prod_c14)
  r1 <- ccx_run_fast(s1, F); rab <- ccx_run_fast(sab, F)
  expect_identical(r1$out, rab$out)
})

test_that("kz_zscale is INERT at f = 1", {
  a <- ccx_spinup(kp_par(1, 253)); b <- ccx_spinup(kp_par(1, 50))
  expect_identical(a$y, b$y)
})

test_that("MUTATION: f = 0.5 moves the deep Delta14C, and in the right direction", {
  d1 <- ccx_spinup(kp_par(1))$diagnostics$d14c_bottom_box
  d5 <- ccx_spinup(kp_par(0.5))$diagnostics$d14c_bottom_box
  expect_gt(abs(d5 - d1), 1)
  # slower deep mixing at the same thermocline K = an OLDER deep
  expect_lt(d5, d1)
})

test_that("the profile is anchored at the ML base and falls monotonically to f * kz", {
  p <- kp_par(0.2, 253); g <- ccx_ocean_grid(p$h_ml)
  k <- ccx_kz_profile(p, g)
  expect_identical(k[1], p$kz)                      # exp(0) = 1 exactly
  expect_true(all(diff(k) < 0))
  expect_gt(k[g$nl], 0.2 * p$kz)                    # the floor is approached, never crossed
  expect_lt(k[g$nl], 0.2 * p$kz * 1.01)             # ... and nearly reached by 2645 m
})

test_that("R and C++ agree at f = 0.5 with the HS boxes on", {
  skip_if_no_cpp()
  p  <- kp_par(0.5, 253, hs = TRUE)
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1850, 1851), prod_c14 = sp$prod_c14)
  fr <- ccx_forcing_at(F, 1L)
  dR <- ccx_deriv(sp$y, 1850, p, fr, sp$grid, sp$aux)
  dC <- ccx_deriv_fast(sp$y, 1850, p, fr, sp$grid, sp$aux)
  expect_equal(dR, dC, tolerance = 1e-10)
  r <- ccx_run_fast(sp, F)
  expect_false(anyNA(r$out))
  # and the C++ core is genuinely reading the profile, not P.kz: a different f
  # must give a different derivative through the C++ path
  p2 <- kp_par(0.9, 253, hs = TRUE); sp2 <- ccx_spinup(p2)
  dC2 <- ccx_deriv_fast(sp$y, 1850, p2, fr, sp2$grid, sp2$aux)
  expect_false(isTRUE(all.equal(dC, dC2)))
})

test_that("conservation survives a non-uniform K", {
  for (f in c(0.5, 0.05)) {
    p0 <- ccx_set_enso(kp_par(f, 253), list(gamma_enso = 0))
    p0$seas_amp_NH <- 0; p0$seas_amp_SH <- 0; p0$seas_drivers <- 0
    sp <- ccx_spinup(p0)
    d  <- ccx_deriv(sp$y, 1750, p0, zero_forcing(sp), sp$grid, sp$aux)
    expect_lt(sum(abs(d[, "C"])) / sum(sp$y[, "C"]), 1e-9)
  }
})

test_that("the pump's export solve reads the profile", {
  # pump_grad > 0 at the defaults; the export that holds the observed gradient
  # must change when the operator changes, or the solve is against a K the
  # model does not use
  a <- ccx_spinup(kp_par(1))$aux$pump
  b <- ccx_spinup(kp_par(0.5))$aux$pump
  skip_if(is.null(a), "pump off at the defaults")
  expect_false(isTRUE(all.equal(a$NH$org, b$NH$org)))
  # and the interior is still solved to the SAME gradient, so the DIC gradient
  # diagnostic (if reported) does not move with f
  sa <- ccx_spinup(kp_par(1)); sb <- ccx_spinup(kp_par(0.5))
  if (!is.null(sa$diagnostics$dic_gradient))
    expect_equal(sa$diagnostics$dic_gradient, sb$diagnostics$dic_gradient, tolerance = 1e-6)
})

test_that("invalid values error by name", {
  g <- ccx_ocean_grid(ccx_default_params()$h_ml)
  expect_error(ccx_kz_profile(kp_par(0), g),   "kz_deep_frac")
  expect_error(ccx_kz_profile(kp_par(1.5), g), "kz_deep_frac")
  expect_error(ccx_kz_profile(kp_par(0.5, 0), g), "kz_zscale")
  expect_error(ccx_kz_profile(kp_par(0.5, -10), g), "kz_zscale")
})

test_that("the substep bound is unchanged at f = 1 and never smaller below it", {
  p1 <- kp_par(1); p5 <- kp_par(0.5)
  expect_identical(ccx_substeps_for(p1), ccx_substeps_for(kp_par(1, 50)))
  expect_gte(ccx_substeps_for(p1), ccx_substeps_for(p5))
})
