# ccx_prior_z() -- the physical-plausibility screen both mode-finders print.
#
# It exists because the per-driver copies it replaced were wrong by up to 1.3 sd
# on the tight lognormals in CCX_PARAM_TABLE, which put two parameters on a
# |z| > 3 flag list that do not belong there. These tests pin it to the
# ANALYTIC answer for every prior whose family is known in closed form, so the
# same class of quadrature error cannot come back silently.

test_that("ccx_prior_z matches the analytic z for every lognormal prior", {
  # the probability integral transform is exact for a lognormal: qnorm(Plnorm(x))
  # = (log x - mu) / sigma, so these are not approximations of the truth, they
  # ARE the truth.
  cases <- list(
    list(n = "q10",             mu = log(2.0),   sd = 0.25,
         xs = c(1.0907, 2.0, 3.1)),
    list(n = "k_w",             mu = log(1500),  sd = 0.40,
         xs = c(600, 1500, 2024.4)),
    list(n = "sst_seas_amp_NH", mu = log(ccx_const("SST_SEAS_AMP_NH_OBS")), sd = 0.25,
         xs = c(0.46677, 2.23739)),
    list(n = "sst_seas_amp_SH", mu = log(ccx_const("SST_SEAS_AMP_SH_OBS")), sd = 0.25,
         xs = c(0.59619, 1.74644)),
    list(n = "seas_T_amp_NH",
         mu = log(sqrt(ccx_const("SEAS_T_AMP_NH_OBS_LO") * ccx_const("SEAS_T_AMP_NH_OBS_HI"))),
         sd = log(ccx_const("SEAS_T_AMP_NH_OBS_HI") / ccx_const("SEAS_T_AMP_NH_OBS_LO")) / 2,
         xs = c(11.445, 25.93708, 50)),
    list(n = "seas_T_amp_SH",
         mu = log(sqrt(ccx_const("SEAS_T_AMP_SH_OBS_LO") * ccx_const("SEAS_T_AMP_SH_OBS_HI"))),
         sd = log(ccx_const("SEAS_T_AMP_SH_OBS_HI") / ccx_const("SEAS_T_AMP_SH_OBS_LO")) / 2,
         xs = c(1.29564, 5.0502)))
  for (cc in cases)
    for (x in cc$xs)
      expect_equal(ccx_prior_z(cc$n, x), (log(x) - cc$mu) / cc$sd,
                   tolerance = 1e-3, info = sprintf("%s at %g", cc$n, x))
})

test_that("ccx_prior_z matches the analytic z for the normal prior", {
  # NAMES UPDATED 2026-09-01. This read `seas_lag_p`, which the 2026-08-31 split
  # (`11ff844`) retired, so it had been ERRORING with "no such parameter" -- not
  # failing on the z, failing before reaching it. ⚠ It was booked under "the 6
  # failures all say the stored modes are 21-parameter files"; it does not, and
  # no refit or adoption would have fixed it ([[explained_away_test]]).
  #
  # BOTH LIMBS, not one. R/calibrate.R:272 states that the split keeps the
  # ORIGINAL prior on each -- "the split adds a degree of freedom without
  # smuggling in a new belief" -- so running the analytic check on both is what
  # actually TESTS that claim, where picking either alone would only assume it.
  for (n in c("seas_lag_p_NH", "seas_lag_p_SH"))
    for (x in c(0, 1.6376, 2.25, 4.5))                # tr = "id", dnorm(2.25, 0.75)
      expect_equal(ccx_prior_z(n, x), (x - 2.25) / 0.75, tolerance = 1e-3,
                   info = sprintf("%s at %g", n, x))
})

test_that("ccx_prior_z is right for a uniform prior under the logit transform", {
  # RE-TARGETED 2026-09-08d (h_ml -> h_hs) and again 2026-09-16 d (h_hs -> fert_k):
  # h_hs went under the Holte HS lognormal in the hygiene batch, so the uniform-
  # under-logit claim now reads fert_k, dunif(20, 2000) on a logit box. The
  # claim is unchanged: the prior CDF is linear in x, z = qnorm((x-lo)/(hi-lo))
  # -- the case the transform could most easily get wrong, because the Jacobian
  # is what makes the pushforward non-uniform.
  s <- CCX_PARAM_TABLE$fert_k; expect_identical(s$tr, "logit")
  for (x in c(30, 300, 1200, 1990))
    expect_equal(ccx_prior_z("fert_k", x), stats::qnorm((x - s$lo) / (s$hi - s$lo)), tolerance = 1e-3)
  # and h_hs now carries the Holte HS lognormal (observation prior, 09-16 d)
  hp <- ccx_h_hs_prior()
  z_trunc <- function(x, mu, sd, lo, hi) { F <- function(v) stats::pnorm((log(v) - mu) / sd); stats::qnorm((F(x) - F(lo)) / (F(hi) - F(lo))) }
  for (x in c(75, 115, 175, 268, 393))
    expect_equal(ccx_prior_z("h_hs", x), z_trunc(x, log(hp$centre_m), hp$log_sd, 20, 500), tolerance = 2e-3, info = sprintf("h_hs at %g", x))
})

test_that("ccx_prior_z matches the analytic z for the two OBSERVATION lognormals under a logit box (09-08d)", {
  # h_ml (box [30, 200]) and u_hs (box [5, 150]) carry lognormal priors read
  # from build products; the box truncates the density but the z the screen
  # reports is the UNTRUNCATED family's, as for every other lognormal above.
  # ⚠ THE BOX TRUNCATES. The screen integrates the prior INSIDE the logit box,
  # so it reports the z of the TRUNCATED family: z_t = qnorm((F(x) - F(lo)) /
  # (F(hi) - F(lo))). For u_hs the box [5, 150] holds all the mass (z_lo -6.1,
  # z_hi +8.0) and the two agree to 1e-3; for h_ml the box [30, 200] clips
  # ~0.7 % (z_lo -3.02, z_hi +2.55) and the truncated z differs from the plain
  # one by up to 0.03 sd at the box's edges -- real, small, and documented here
  # rather than hidden in a loose tolerance.
  hp <- readRDS(ccx_path("data", "obs_h_ml_prior.rds")); up <- readRDS(ccx_path("data", "obs_u_hs_prior.rds"))
  z_trunc <- function(x, mu, sd, lo, hi) { F <- function(v) stats::pnorm((log(v) - mu) / sd)
    stats::qnorm((F(x) - F(lo)) / (F(hi) - F(lo))) }
  # The box is READ from the table (2026-09-16 b: the floor moved 30 -> CCX_HML_FLOOR_M = 42.5, the
  # prior's 16 % point, so the truncation now clips ~16 % below and the truncated z differs from
  # the plain one by ~0.2 sd at the centre -- larger, and still asserted rather than tolerated).
  bx <- CCX_PARAM_TABLE$h_ml; expect_identical(bx$lo, CCX_HML_FLOOR_M)
  for (x in c(45, 59.7, 83.9, 118, 134.15))
    expect_equal(ccx_prior_z("h_ml", x), z_trunc(x, log(hp$centre_m), hp$log_sd, bx$lo, bx$hi), tolerance = 2e-3, info = sprintf("h_ml at %g", x))
  expect_gt(abs(ccx_prior_z("h_ml", 45) - (log(45) - log(hp$centre_m)) / hp$log_sd), 0.02)   # the truncation IS visible
  expect_true(is.na(ccx_prior_z("h_ml", 39.8)))                                               # below the floor: no z, never a clamp
  for (x in c(12, 21.84, 38, 60))
    expect_equal(ccx_prior_z("u_hs", x), (log(x) - log(up$centre_m_yr)) / up$log_sd, tolerance = 1e-3, info = sprintf("u_hs at %g", x))
  # hs_asx_frac (09-08e): box [0.02, 2.0] holds all the mass of a 0.15-wide lognormal at 0.653
  ap <- readRDS(ccx_path("data", "obs_hs_asx_prior.rds"))
  for (x in c(0.5, 0.653, 0.818, 1.835))
    expect_equal(ccx_prior_z("hs_asx_frac", x), (log(x) - log(ap$centre)) / ap$log_sd, tolerance = 1e-3, info = sprintf("hs_asx_frac at %g", x))
})

test_that("ccx_prior_z resolves deep tails, which the linear-grid version could not", {
  # -6.27 sd is a lower-tail mass of 1.8e-10. Computing it as 1 - upper would
  # lose it to floating point; the two-tail branch is what makes it survive.
  expect_equal(ccx_prior_z("sst_seas_amp_NH", 0.46677), -6.269, tolerance = 1e-3)
  # and far beyond anything the fit reaches, to show the range is not a fluke
  expect_equal(ccx_prior_z("q10", 2 * exp(-15 * 0.25)), -15, tolerance = 1e-2)
})

test_that("ccx_prior_z accepts a caller-supplied table", {
  # the arm driver overrides h_ml's band IN PROCESS, so the screen must follow
  # the table it is given rather than a global (ccx_hml_band_provenance).
  tb <- CCX_PARAM_TABLE
  tb$h_ml$lo <- 85; tb$h_ml$hi <- 120
  tb$h_ml$prior <- function(x) stats::dunif(x, 85, 120, log = TRUE)
  expect_equal(ccx_prior_z("h_ml", 87.56224, table = tb),
               stats::qnorm((87.56224 - 85) / 35), tolerance = 1e-3)
  # MUTATION: under the DEFAULT band the same value gives a different z, so the
  # test above cannot be passing by ignoring `table`.
  expect_false(isTRUE(all.equal(ccx_prior_z("h_ml", 87.56224),
                                stats::qnorm((87.56224 - 85) / 35), tolerance = 1e-3)))
})
