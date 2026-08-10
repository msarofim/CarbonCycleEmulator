# =====================================================================
# Gate: the integrator's explicit-diffusion stability limit is CONTROLLED,
# not discovered at runtime as a wall of NAs.
#
# Why this gate exists. Before 2026-08-11 the substep count was hard-coded at 4,
# which caps kz at ~155,000 m2/yr. The mode-finder walked straight into that cap
# (kz = 175,790, i.e. ~1 % from the boundary) and every caller's `anyNA` -> -Inf
# guard turned "the integrator diverged" into "this parameter has zero posterior
# probability". The posterior was being truncated by the solver.
#
# So there are two things to hold: (1) the criterion actually predicts where the
# old scheme broke -- otherwise we have fixed the wrong thing; and (2) with the
# criterion wired in, no parameter value in or beyond the prior's support
# produces NA. Test 4 is a MUTATION TEST of test 3: with the controller forced
# back to the old fixed 4, the same case MUST fail. Without it, test 3 could
# pass for the trivial reason that the case was never unstable.
# =====================================================================

skip_if_no_cpp <- function() {
  skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) skip("C++ core failed to compile")
}

# analytic kz at which a FIXED substep count goes unstable, from the same
# eigenvalue the controller uses (safety margin removed, so this is the edge)
kz_wall <- function(h_ml, substeps) {
  g <- ccx_ocean_grid(h_ml)
  lam1 <- ccx_diffusion_eigmax(1, g)              # eigenvalue is linear in kz
  CCX_RK4_STAB_LIMIT / ((1 / 12) / substeps * lam1)
}

run_at <- function(kz, h_ml = 75, substeps = "auto", retry_na = TRUE,
                   years = c(1900, 1960)) {
  p <- ccx_default_params(); p$gamma_enso <- 0.5; p$kz <- kz; p$h_ml <- h_ml
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", years, prod_c14 = sp$prod_c14)
  ccx_run_fast(sp, F, substeps = substeps, retry_na = retry_na)
}

test_that("the controller is a no-op at every ordinary parameter value", {
  # The whole point of flooring at CCX_SUBSTEPS_MIN: switching the default to
  # "auto" must not change a single existing result. kz has to clear ~155,000
  # (+6.2 sigma on its lnorm(log 4000, 0.6) prior) before the count moves.
  p <- ccx_default_params()
  expect_identical(ccx_substeps_for(p), CCX_SUBSTEPS_MIN)
  # across the prior's central 99.99 % and both ends of the h_ml range
  for (q in c(1e-4, 0.5, 0.9999)) {
    for (hm in c(30, 75, 200)) {
      pp <- p; pp$kz <- qlnorm(q, log(4000), 0.6); pp$h_ml <- hm
      expect_identical(ccx_substeps_for(pp), CCX_SUBSTEPS_MIN,
                       info = sprintf("kz q=%g h_ml=%g", q, hm))
    }
  }
})

test_that("the criterion predicts where the OLD fixed-substep scheme broke", {
  skip_if_no_cpp()
  # This is the diagnosis, held as a test: the -Inf wall was the RK4 limit on
  # the negative real axis, not anything about the data or the physics.
  for (hm in c(30, 75)) {
    w <- kz_wall(hm, 4)
    expect_false(anyNA(run_at(0.95 * w, hm, substeps = 4L, retry_na = FALSE)$out),
                 info = sprintf("h_ml %g: 0.95x the analytic wall must be stable", hm))
    expect_true(anyNA(run_at(1.10 * w, hm, substeps = 4L, retry_na = FALSE)$out),
                info = sprintf("h_ml %g: 1.10x the analytic wall must diverge", hm))
  }
})

test_that("no NAs anywhere in or far beyond the prior's support", {
  skip_if_no_cpp()
  # 175790 is the 2026-08-10 mode, which the old scheme could not evaluate.
  for (kz in c(4000, 37200, 175790, 4e5, 1e6)) {
    r <- run_at(kz)
    expect_false(anyNA(r$out), info = sprintf("kz = %g", kz))
    expect_gt(min(r$out$co2_NH), 0)
    expect_true(r$substeps >= CCX_SUBSTEPS_MIN)
  }
})

test_that("MUTATION: with the controller disabled, the same cases DO fail", {
  skip_if_no_cpp()
  # Guards against an inert gate. If forcing the old fixed 4 (and disabling the
  # NA retry) still produced finite output, the test above would be proving
  # nothing.
  fails <- vapply(c(175790, 4e5, 1e6),
                  function(kz) anyNA(run_at(kz, substeps = 4L, retry_na = FALSE)$out),
                  logical(1))
  expect_true(all(fails))
})

test_that("the auto substep count is accurate, not merely stable", {
  skip_if_no_cpp()
  # Stability is necessary but not sufficient: a barely-stable step can still be
  # inaccurate. Doubling the substeps beyond the controller's choice must not
  # move the answer more than RK4 truncation error.
  for (kz in c(175790, 1e6)) {
    p <- ccx_default_params(); p$gamma_enso <- 0.5; p$kz <- kz
    ss <- ccx_substeps_for(p)
    a <- run_at(kz, substeps = ss)$out
    b <- run_at(kz, substeps = 2L * ss)$out
    expect_lt(max(abs(a$co2_NH - b$co2_NH)) / max(a$co2_NH), 1e-6,
              label = sprintf("kz = %g CO2 relative change on doubling substeps", kz))
    expect_lt(max(abs(a$d14c_NH - b$d14c_NH)), 1e-3)
  }
})
