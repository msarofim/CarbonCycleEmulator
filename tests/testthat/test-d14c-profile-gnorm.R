# =====================================================================
# OBJECTIVE CHANGE #10 (2026-09-07, Marcus): the interior D14C profile as
# (mean level, A-B, B-deep), three generalized-normal rows with declared sigmas
# (level: the deep row's convention; contrasts: the bootstrap) and shape 4.
#
# WHAT THESE TESTS GUARD:
#   * the switches ship as ruled: gnorm ON, MVN OFF, beta 4.
#   * ccx_dgnorm_log at beta = 2 IS dnorm(log = TRUE), constant included; the
#     cost relative to the mode is |z|^beta / 2 (2 sigma costs 8 at beta 4).
#   * with beta forced to 2 the three rows equal Gaussian rows on the derived
#     (level, A-B, B-deep) computed by hand -- the reduction gate.
#   * the rows replace the three level rows and decompose; a missing input
#     falls back to the independent rows.
#   * MUTATION on the first refit's own basins: the winner's +50 permil level
#     costs > 100 log-units more than a profile at the targets; the column's
#     contrasts cost > 50 (both were < 50 under the forms they beat).
# =====================================================================
skip_if_no_spec <- function() skip_if(is.null(ccx_profile_d14c_spec()), "profile spec inputs absent")
with_beta <- function(beta, expr) {
  old <- LIK_D14C_PROFILE_BETA
  assign("LIK_D14C_PROFILE_BETA", beta, envir = globalenv())
  on.exit(assign("LIK_D14C_PROFILE_BETA", old, envir = globalenv()), add = TRUE)
  force(expr)
}

test_that("the switches ship as ruled and the spec is derived from the rows", {
  expect_true(LIK_USE_D14C_PROFILE_GNORM); expect_false(LIK_USE_D14C_PROFILE_MVN)
  expect_identical(LIK_D14C_PROFILE_BETA, 4)
  skip_if_no_spec()
  sp <- ccx_profile_d14c_spec(); tgm <- ccx_mid_d14c_target(); tgd <- ccx_deep_d14c_target(); pc <- ccx_profile_d14c_cov()
  mu <- c(tgm$slabs$target, tgd$target)
  expect_equal(sp$level, mean(mu)); expect_equal(sp$ab, mu[1] - mu[2]); expect_equal(sp$bd, mu[2] - mu[3])
  expect_equal(sp$level_sd, tgd$sd)                       # the deep row's convention, not the bootstrap
  expect_equal(c(sp$ab_sd, sp$bd_sd), unname(pc$se[c("AB", "BD")]))
  expect_lt(sp$bd_sd, 0.5 * sp$level_sd)                  # the contrasts are the well-measured part
})

test_that("beta = 2 is the Gaussian, and the cost is |z|^beta / 2", {
  x <- c(-3.2, 0, 1.7, 12.5); mu <- 1; sd <- 3.7
  expect_equal(ccx_dgnorm_log(x, mu, sd, 2), stats::dnorm(x, mu, sd, log = TRUE), tolerance = 1e-12)
  cost <- function(z, beta) ccx_dgnorm_log(0, 0, 1, beta) - ccx_dgnorm_log(z, 0, 1, beta)
  expect_equal(cost(1, 4), 0.5); expect_equal(cost(2, 4), 8); expect_equal(cost(3, 4), 40.5); expect_equal(cost(5, 4), 312.5)
  expect_equal(cost(2, 2), 2); expect_equal(cost(1, 2), 0.5)
  # a proper density at beta = 4: integrates to 1
  expect_equal(integrate(function(v) exp(ccx_dgnorm_log(v, 0, 1, 4)), -Inf, Inf)$value, 1, tolerance = 1e-6)
})

test_that("with beta forced to 2 the rows are Gaussian rows on the derived (level, A-B, B-deep)", {
  skip_if_no_spec()
  sp <- ccx_profile_d14c_spec(); m <- c(-150.2, -161.9, -170.4)
  rows <- with_beta(2, ccx_profile_rows_at(m))
  expect_identical(names(rows), c("d14c_profile_level", "d14c_profile_ab", "d14c_profile_bd"))
  expect_equal(unname(rows[["d14c_profile_level"]]), stats::dnorm(sp$level, mean(m), sp$level_sd, log = TRUE), tolerance = 1e-12)
  expect_equal(unname(rows[["d14c_profile_ab"]]), stats::dnorm(sp$ab, m[1] - m[2], sp$ab_sd, log = TRUE), tolerance = 1e-12)
  expect_equal(unname(rows[["d14c_profile_bd"]]), stats::dnorm(sp$bd, m[2] - m[3], sp$bd_sd, log = TRUE), tolerance = 1e-12)
  # at the targets the beta-4 rows are their normalizing constants
  at <- ccx_profile_rows_at(sp$mu)
  expect_equal(unname(at[["d14c_profile_level"]]), ccx_dgnorm_log(0, 0, sp$level_sd, 4))
})

test_that("the rows replace the three level rows, decompose, and fall back when an input is absent", {
  skip_if_no_cpp(); skip_if_no_spec()
  p <- ccx_default_params(); sp <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", c(1955, 1960), prod_c14 = sp$prod_c14)
  o <- ccx_run_fast(sp, F)$out; obs <- ccx_prepare_obs(); err <- list(sigma_d14c = 5, rep_dC = 0)
  deep <- sp$diagnostics$d14c_bottom_box; mid <- ccx_model_d14c_slabs(sp)
  three <- c("d14c_mid_1500_2000", "d14c_mid_2000_2627", "d14c_deep_ocean"); g <- c("d14c_profile_level", "d14c_profile_ab", "d14c_profile_bd")
  on <- suppressWarnings(ccx_loglik(o, obs, err, deep = deep, d14c_mid = mid, by_stream = TRUE))
  expect_true(all(g %in% names(on))); expect_false(any(three %in% names(on)))
  tgm <- ccx_mid_d14c_target()
  expect_equal(unname(on[g]), unname(ccx_profile_rows_at(c(mid[[tgm$slabs$name[1]]], mid[[tgm$slabs$name[2]]], deep))), tolerance = 1e-12)
  expect_equal(sum(on), suppressWarnings(ccx_loglik(o, obs, err, deep = deep, d14c_mid = mid)), tolerance = 1e-9)
  half <- suppressWarnings(ccx_loglik(o, obs, err, deep = deep, by_stream = TRUE))
  expect_false(any(g %in% names(half))); expect_true("d14c_deep_ocean" %in% names(half))
})

test_that("MUTATION: the first refit's winner pays for its level, the column for its shape", {
  skip_if_no_spec()
  f <- ccx_path("outputs", "diagnostics", "hilda28_basins_20260907.rds")
  skip_if(!file.exists(f), "first-refit basin product absent")
  x <- readRDS(f); sp <- ccx_profile_d14c_spec()
  at_target <- sum(ccx_profile_rows_at(sp$mu))
  winner <- ccx_profile_rows_at(x$fam[[1]]$lev); column <- ccx_profile_rows_at(x$ent26$lev)
  expect_gt(at_target - winner[["d14c_profile_level"]] - (ccx_dgnorm_log(0, 0, sp$level_sd, 4) - 0), 100)   # > 100 on the level alone
  expect_gt(at_target - sum(column), 50)                                                                   # the column's contrasts
  # and neither was priced like that before: under the MVN the winner's whole row was -19.5
  expect_lt(sum(winner), -100)
})
