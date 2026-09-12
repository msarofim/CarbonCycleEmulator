# =====================================================================
# OBJECTIVE CHANGE #9 (2026-09-06, PENDING RULING): the three interior D14C
# levels as ONE multivariate-normal row with the measured covariance.
#
# WHAT THESE TESTS GUARD:
#   * the switch SHIPS OFF, and off means the three independent rows and no
#     MVN row -- bit for bit what every stored logpost was scored with.
#   * the build product scores the SAME three targets as the rows.
#   * the density reduces EXACTLY to the three Gaussians when the covariance
#     is diagonal (the prereg's reduction gate).
#   * THE PROPERTY THE ROW EXISTS FOR: with the measured covariance a common
#     LEVEL shift of the profile is cheaper than under independent rows, and a
#     CONTRAST shift (B down, deep up, mean unchanged) is dearer. Both margins
#     are derived in-test from the stored covariance, never typed.
#   * switched ON, the row replaces the three and the total moves by exactly
#     (MVN row - the three Gaussians): nothing else in the objective changes.
# =====================================================================

skip_if_no_prof <- function() skip_if(is.null(ccx_profile_d14c_cov()) || is.null(ccx_mid_d14c_target()) ||
                                        is.null(ccx_deep_d14c_target()), "profile covariance build product absent")
# 2026-09-07: the MVN form is SUPERSEDED by the generalised-normal rows (#10);
# these tests exercise it with the gnorm form switched OFF, so they stay a
# guard on the MVN machinery diagnostics still use.
with_mvn <- function(on, expr) {
  old <- LIK_USE_D14C_PROFILE_MVN; oldg <- LIK_USE_D14C_PROFILE_GNORM
  assign("LIK_USE_D14C_PROFILE_MVN", on, envir = globalenv())
  assign("LIK_USE_D14C_PROFILE_GNORM", FALSE, envir = globalenv())
  on.exit({ assign("LIK_USE_D14C_PROFILE_MVN", old, envir = globalenv())
            assign("LIK_USE_D14C_PROFILE_GNORM", oldg, envir = globalenv()) }, add = TRUE)
  force(expr)
}

test_that("the MVN switch is OFF (superseded 2026-09-07 by #10) and the build product scores the rows' own targets", {
  expect_false(LIK_USE_D14C_PROFILE_MVN); expect_identical(LIK_D14C_PROFILE_BLOCK, 60)
  skip_if_no_prof()
  pc <- ccx_profile_d14c_cov(); tgm <- ccx_mid_d14c_target(); tgd <- ccx_deep_d14c_target()
  expect_equal(unname(pc$targets), c(tgm$slabs$target, tgd$target))
  expect_equal(unname(pc$means), unname(pc$targets), tolerance = 1e-5)
  expect_identical(pc$streams, c(tgm$slabs$stream, "d14c_deep_ocean"))
  expect_equal(dim(pc$cov), c(3L, 3L))
  expect_true(all(eigen(pc$cov, symmetric = TRUE, only.values = TRUE)$values > 0))
  # the levels share their columns: every correlation is high, and the contrast
  # se is well below each level se (the reason the row exists)
  R <- stats::cov2cor(pc$cov)
  expect_true(all(R[upper.tri(R)] > 0.9))
  expect_lt(pc$se[["BD"]], 0.5 * min(pc$se[c("B", "deep")]))
})

test_that("the density reduces exactly to the three Gaussians when Sigma is diagonal", {
  mu <- c(-168.6, -175.6, -175.3); x <- c(-161.2, -172.0, -175.3); sd <- c(13.5, 13.6, 10.3)
  expect_equal(ccx_dmvnorm_log(mu, x, diag(sd^2)),
               sum(stats::dnorm(mu, x, sd, log = TRUE)), tolerance = 1e-12)
  # symmetric in its first two arguments, like dnorm
  expect_equal(ccx_dmvnorm_log(mu, x, diag(sd^2)), ccx_dmvnorm_log(x, mu, diag(sd^2)))
})

test_that("with the measured covariance a LEVEL shift is cheap and a CONTRAST shift is dear", {
  skip_if_no_prof()
  pc <- ccx_profile_d14c_cov(); mu <- unname(pc$targets); S <- pc$cov; D <- diag(diag(S))
  pen <- function(x, Sig) ccx_dmvnorm_log(mu, mu, Sig) - ccx_dmvnorm_log(mu, x, Sig)   # >= 0
  d <- 5
  level    <- mu - d                          # whole profile 5 permil older
  contrast <- mu + c(0, -d, +d)               # B - deep moved by -10, mean of B and deep unchanged
  expect_lt(pen(level, S), pen(level, D))     # correlation absorbs a common move
  expect_gt(pen(contrast, S), pen(contrast, D))  # and punishes a contrast
  # the size of the effect, derived from the stored contrast se: a -2d contrast at
  # se(BD) costs about 0.5 (2d / se)^2 under the MVN, and far less under the diagonal
  expect_gt(pen(contrast, S), 0.5 * (2 * d / pc$se[["BD"]])^2 * 0.8)
})

test_that("switched ON the row replaces the three and moves the total by exactly their difference", {
  skip_if_no_cpp(); skip_if_no_prof()
  p  <- ccx_default_params(); sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1955, 1960), prod_c14 = sp$prod_c14)
  o  <- ccx_run_fast(sp, F)$out
  obs <- ccx_prepare_obs(); err <- list(sigma_d14c = 5, rep_dC = 0)
  deep <- sp$diagnostics$d14c_bottom_box; mid <- ccx_model_d14c_slabs(sp)
  three <- c("d14c_mid_1500_2000", "d14c_mid_2000_2627", "d14c_deep_ocean")
  off <- with_mvn(FALSE, ccx_loglik(o, obs, err, deep = deep, d14c_mid = mid, by_stream = TRUE))
  on  <- with_mvn(TRUE,  ccx_loglik(o, obs, err, deep = deep, d14c_mid = mid, by_stream = TRUE))
  expect_true(all(three %in% names(off))); expect_false("d14c_profile_mvn" %in% names(off))
  expect_true("d14c_profile_mvn" %in% names(on)); expect_false(any(three %in% names(on)))
  expect_equal(setdiff(names(off), three), setdiff(names(on), "d14c_profile_mvn"))
  expect_equal(sum(on) - sum(off), on[["d14c_profile_mvn"]] - sum(off[three]), tolerance = 1e-9)
  tot_on  <- with_mvn(TRUE,  ccx_loglik(o, obs, err, deep = deep, d14c_mid = mid))
  tot_off <- with_mvn(FALSE, ccx_loglik(o, obs, err, deep = deep, d14c_mid = mid))
  expect_equal(tot_on - tot_off, on[["d14c_profile_mvn"]] - sum(off[three]), tolerance = 1e-9)
  # the row is the density the code claims, on the model vector the rows score
  pc <- ccx_profile_d14c_cov(); tgm <- ccx_mid_d14c_target()
  m <- c(mid[[tgm$slabs$name[1]]], mid[[tgm$slabs$name[2]]], deep)
  expect_equal(on[["d14c_profile_mvn"]], ccx_dmvnorm_log(unname(pc$targets), m, pc$cov), tolerance = 1e-12)
  # a missing input falls back to the independent rows, visibly, never a half-score
  half <- with_mvn(TRUE, ccx_loglik(o, obs, err, deep = deep, by_stream = TRUE))
  expect_false("d14c_profile_mvn" %in% names(half)); expect_true("d14c_deep_ocean" %in% names(half))
})
