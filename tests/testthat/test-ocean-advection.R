# =====================================================================
# Gate: the ocean overturning terms (`w_up`, `w_out_NH`, `w_out_SH`, added
# 2026-08-13) are OFF by default and correct when on.
#
# TWO CONFIGURATIONS, differing in which limb is non-local:
#   `w_up`   distributed upwelling with a non-local SINKING limb (ml -> bottom):
#            the classical upwelling-diffusion column.
#   `w_out`  a non-local UPWELLING limb (bottom -> ml, a Southern Ocean outcrop)
#            with a distributed descent. Per hemisphere.
# The last two tests hold the symmetry that ties them at the atmosphere.
#
# WHY THIS FILE EXISTS AT ALL, given that the mechanism is not adopted.
# diag_ocean_upwelling.R measured it and the answer was "possible, cheap, and it
# does not help" -- so `w_up` stays 0 everywhere and is absent from
# CCX_PARAM_TABLE. The code stays because the measurement is worth more with the
# implementation that produced it, and because "why not just add advection?" is
# a question this model will be asked again. That makes two things testable:
#
#   1. THE DEFAULT IS INERT. w_up = 0 must reproduce the pure-diffusion column
#      EXACTLY -- not approximately -- or every result computed before
#      2026-08-13 has silently moved. Test 1 is the guard, and test 2 is its
#      mutation test: with w_up > 0 the same comparison MUST fail, otherwise
#      test 1 could be passing because the mechanism does nothing at all.
#   2. IT IS CONSERVATIVE AND SPINUP-COMPATIBLE when on. The advective limbs go
#      through add_flux, so carbon conservation is structural; and a uniform
#      column is still an exact fixed point, which is what lets ccx_spinup()'s
#      analytic 12C equilibrium stand unchanged (spinup.R, ocean block).
# =====================================================================

skip_if_no_cpp <- function() {
  skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) skip("C++ core failed to compile")
}

W_TEST <- 4          # m/yr, the classical upwelling-diffusion value
YRS    <- c(1900, 1960)

run_w <- function(w, years = YRS) {
  p <- ccx_default_params(); p$gamma_enso <- 0.5; p$w_up <- w
  s <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", years, prod_c14 = s$prod_c14)
  list(spin = s, run = ccx_run_fast(s, F))
}

test_that("w_up = 0 is the pure-diffusion model, exactly", {
  skip_if_no_cpp()
  # A parameter list with NO w_up at all is the pre-2026-08-13 model; one with
  # w_up = 0 is the current default. They must be indistinguishable.
  p_new <- ccx_default_params()
  p_old <- p_new; p_old$w_up <- NULL
  expect_identical(p_new$w_up, 0)

  s_new <- ccx_spinup(p_new)
  s_old <- ccx_spinup(p_old)
  expect_equal(s_new$y, s_old$y, tolerance = 0)
  expect_equal(s_new$prod_c14, s_old$prod_c14, tolerance = 0)

  F <- ccx_build_forcing("historical", YRS, prod_c14 = s_new$prod_c14)
  o_new <- ccx_run_fast(s_new, F)$out
  o_old <- ccx_run_fast(s_old, F)$out
  expect_equal(o_new, o_old, tolerance = 0)

  # and the substep controller must not have moved either
  expect_identical(ccx_substeps_for(p_new), ccx_substeps_for(p_old))
  expect_identical(ccx_advection_eigbound(0, ccx_ocean_grid(p_new$h_ml)), 0)
})

test_that("MUTATION: w_up > 0 does change the answer", {
  skip_if_no_cpp()
  # Without this, the test above could pass because the mechanism is a no-op
  # everywhere -- the failure mode of the 14C decay gate and the inert fossil
  # scan (memory feedback_mutation_test_your_gates).
  a <- run_w(0)$run$out
  b <- run_w(W_TEST)$run$out
  expect_false(isTRUE(all.equal(a$co2_NH, b$co2_NH)))
  expect_false(isTRUE(all.equal(a$d13c_NH, b$d13c_NH)))
  # the deep ocean is the loudest signal: the sinking limb ventilates it
  expect_lt(abs(run_w(0)$spin$diagnostics$d14c_deep_ocean -
                run_w(W_TEST)$spin$diagnostics$d14c_deep_ocean), 200)
  expect_gt(run_w(W_TEST)$spin$diagnostics$d14c_deep_ocean,
            run_w(0)$spin$diagnostics$d14c_deep_ocean)
})

test_that("overturning is conservative and leaves the spinup an exact fixed point", {
  p <- ccx_default_params(); p$w_up <- W_TEST
  s <- ccx_spinup(p)
  # the analytic 12C equilibrium must still be a fixed point with advection on
  expect_lt(s$diagnostics$max_abs_dCdt, 1e-6)
  expect_lt(s$diagnostics$max_abs_dC13dt, 1e-12)
  expect_lt(s$diagnostics$max_abs_dC14dt, 1e-10)

  # volume conservation, stated as carbon conservation: with no emissions and no
  # decay the advective limbs must move carbon without creating any. Checked on
  # the derivative directly so this is about the operator, not the integrator.
  zero <- list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
               gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0,
               c14_cosmo = 0, d13c_foss = -28)
  y <- s$y
  y[s$aux$idx$NH$ml, "C"] <- y[s$aux$idx$NH$ml, "C"] * 1.3   # perturb, off the fixed point
  d <- ccx_deriv(y, 1800, within(p, gamma_enso <- 0), zero, s$grid, s$aux)
  expect_lt(abs(sum(d[, "C"])), 1e-9)
  expect_lt(abs(sum(d[, "C13"])), 1e-11)
})

test_that("R and C++ agree with overturning on", {
  skip_if_no_cpp()
  # test-parity.R runs the pure-diffusion column; the advective limbs are new
  # code in both files and need their own gate. Same scale-relative tolerance
  # discipline as test-parity.R.
  p <- ccx_default_params(); p$w_up <- W_TEST; p$gamma_enso <- 0.5
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
})

test_that("reversing the circulation leaves the ATMOSPHERE invariant, not the deep ocean", {
  skip_if_no_cpp()
  # The symmetry measured 2026-08-13 and proved in diag_ocean_upwelling.R part 9.
  # `w_up` (distributed up, non-local sinking) and `w_out` (non-local upwelling,
  # distributed descent) are the same closed loop run in opposite directions, so
  # their transport operators are related by A_out = D A_up^T D^-1 with
  # D = diag(dz). A transpose preserves diagonal elements of the propagator, and
  # the mixed layer is the ONLY box coupling the ocean to the rest of the model
  # (air-sea acts at `iml` and nowhere else) -- so every observable outside the
  # column is invariant, while the interior is not.
  #
  # This is held as a test because it is the load-bearing reason the mechanism
  # was not adopted: it makes the negative result GENERAL (no rerouting of a
  # closed vertical loop can change what the atmosphere sees) rather than a
  # property of one parameterisation. If a future edit breaks the tie, either
  # the operator symmetry is gone or something has started coupling the interior
  # to the atmosphere directly -- both worth knowing about immediately.
  p <- ccx_default_params(); p$gamma_enso <- 0.5
  a <- run_w(0); stopifnot(!anyNA(a$run$out))
  up  <- run_w(W_TEST)
  pp  <- p; pp$w_out_NH <- W_TEST; pp$w_out_SH <- W_TEST
  s   <- ccx_spinup(pp)
  F   <- ccx_build_forcing("historical", YRS, prod_c14 = s$prod_c14)
  out <- ccx_run_fast(s, F)

  # the atmosphere, the land and the ocean TOTALS are tied
  #
  # SCOPED 2026-08-16, and the reason is worth keeping. This was
  # `expect_equal(as.matrix(out$out), ...)` over the WHOLE frame, which matched
  # the comment above only by accident: `out` carried no interior quantity, so
  # "everything in out" and "everything outside the column" were the same set.
  # Adding the bottom-box columns (CCX_OCEAN_BOX_COLS, for the ocean gradient
  # terms) broke that coincidence and the assertion started contradicting its
  # own next line, which asserts the deep DOES move. Measured at the split:
  # every pre-existing column ties to <= 1.5e-10, the MIXED-LAYER columns tie to
  # <= 2.9e-13, and only the BOTTOM-BOX ones differ (deep_C_NH by 3.68 GtC).
  # So the physics is untouched; the assertion's scope was wrong.
  deep_cols <- grep("^deep_", CCX_OCEAN_BOX_COLS, value = TRUE)
  tied <- setdiff(names(out$out), deep_cols)
  expect_equal(as.matrix(out$out[, tied]), as.matrix(up$run$out[, tied]),
               tolerance = 1e-8)
  # The MIXED LAYER tying is not incidental -- it is the mechanism claim above
  # ("air-sea acts at iml and nowhere else") measured directly, and it is a
  # stronger statement than the totals alone, which could tie by cancellation.
  for (cc in setdiff(CCX_OCEAN_BOX_COLS, deep_cols))
    expect_lt(max(abs(out$out[[cc]] - up$run$out[[cc]])), 1e-8)
  # ...and the BOTTOM BOX must NOT tie, or the transpose symmetry would be
  # saying something far stronger than it does.
  for (cc in deep_cols)
    expect_gt(max(abs(out$out[[cc]] - up$run$out[[cc]])), 1e-6)
  # and the mechanism is doing something -- against no advection at all
  expect_false(isTRUE(all.equal(out$out$d13c_NH, a$run$out$d13c_NH)))
  # but the INTERIOR is not tied: the outcrop keeps the deep ocean OLDER, i.e.
  # MORE negative in Delta14C -- it never injects modern surface water into the
  # bottom box, where the classic-UD sinking limb does exactly that.
  expect_lt(s$diagnostics$d14c_deep_ocean - up$spin$diagnostics$d14c_deep_ocean, -5)
})

test_that("the operator symmetry itself holds: A_out = D A_up^T D^-1", {
  # Stated on the operators rather than on a run, so a failure says WHICH of the
  # two limbs was mis-wired instead of only that some output moved.
  g <- ccx_ocean_grid(75); n <- g$nl + 1; dz <- g$dz; w <- W_TEST
  A_up <- A_out <- matrix(0, n, n)
  for (k in seq_len(g$nl)) {
    A_up[k, k + 1] <- A_up[k, k + 1] + w / dz[k + 1]
    A_up[k + 1, k + 1] <- A_up[k + 1, k + 1] - w / dz[k + 1]
    A_out[k + 1, k] <- A_out[k + 1, k] + w / dz[k]
    A_out[k, k] <- A_out[k, k] - w / dz[k]
  }
  A_up[n, 1] <- A_up[n, 1] + w / dz[1]; A_up[1, 1] <- A_up[1, 1] - w / dz[1]
  A_out[1, n] <- A_out[1, n] + w / dz[n]; A_out[n, n] <- A_out[n, n] - w / dz[n]
  D <- diag(dz)
  expect_lt(max(abs(A_out - D %*% t(A_up) %*% solve(D))), 1e-15)
  # both conserve mass and both hold a uniform column as a fixed point
  expect_lt(max(abs(colSums(A_up))), 1e-15)
  expect_lt(max(abs(colSums(A_out))), 1e-15)
  expect_lt(max(abs(A_up %*% dz)), 1e-12)
  expect_lt(max(abs(A_out %*% dz)), 1e-12)
})
