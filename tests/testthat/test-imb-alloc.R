# =====================================================================
# test-imb-alloc.R -- D3, the GCB imbalance allocation (Marcus 2026-09-30;
# R/likelihood.R LIK_IMB_*, candidate objective #14)
#
# What has to hold for the machinery to be safe to have in the objective's path
# BEFORE anything adopts it:
#   1. ABSENT is objective #13, bit for bit; shares (0, 0) are too.
#   2. The shares move the two GCB sink rows and NOTHING ELSE (every other
#      stream identical), and the rows equal a hand-built sum.
#   3. The imbalance series is what its treatment says, over every GCB year.
#   4. The guards refuse a half pair, a negative share and a sum above 1.
#   5. The stick-breaking resolver implies the FLAT simplex prior it claims.
#   6. The logpost carries the shares from base_params to the rows.
# Mutation-tested 2026-09-30 (CHANGELOG 09-30 j): each guard and each wire was
# broken in turn and the file was run.
# =====================================================================

.ia_gcb <- function() as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$budget)

test_that("3. the imbalance series follows its treatment over every GCB year", {
  g <- .ia_gcb(); n <- nrow(g)
  raw <- ccx_imb_series(g, "raw", FALSE)
  expect_identical(raw$year, g$year)
  expect_identical(raw$I, g$imbalance)
  cst <- ccx_imb_series(g, "const", FALSE)
  expect_equal(cst$I, rep(mean(g$imbalance), n), tolerance = 0)
  # smooth: k = 1 is the raw series; interior = the plain centered mean; the ends SHRINK
  expect_identical(ccx_imb_series(g, "smooth", FALSE, k = 1L)$I, g$imbalance)
  sm <- ccx_imb_series(g, "smooth", FALSE, k = 11L)$I
  expect_false(anyNA(sm)); expect_length(sm, n)
  expect_equal(sm[30], mean(g$imbalance[25:35]), tolerance = 1e-14)
  expect_equal(sm[1],  mean(g$imbalance[1:6]),   tolerance = 1e-14)
  expect_equal(sm[n],  mean(g$imbalance[(n - 5):n]), tolerance = 1e-14)
  # cement is ADDED, not substituted
  expect_equal(ccx_imb_series(g, "raw", TRUE)$I, g$imbalance + g$cement_carbonation, tolerance = 0)
  # a shuffled table gives the same series (it is ordered by year inside)
  expect_identical(ccx_imb_series(g[rev(seq_len(n)), ], "smooth", FALSE)$I, sm)
  # guards
  expect_error(ccx_imb_series(g, "loess", FALSE), "treatment")
  expect_error(ccx_imb_series(g, "smooth", FALSE, k = 10L), "ODD")
  expect_error(ccx_imb_series(g[, setdiff(names(g), "cement_carbonation")], "raw", TRUE), "cement_carbonation")
})

test_that("4. the share guards refuse what is not an allocation", {
  expect_null(ccx_imb_shares_check(NULL, NULL))
  expect_error(ccx_imb_shares_check(0.3, NULL), "PAIR")
  expect_error(ccx_imb_shares_check(NULL, 0.3), "PAIR")
  expect_error(ccx_imb_shares_check(-0.01, 0.3), "simplex")
  expect_error(ccx_imb_shares_check(0.7, 0.31), "simplex")
  expect_error(ccx_imb_shares_check(NaN, 0.3), "finite")
  expect_identical(ccx_imb_shares_check(0.7, 0.3), c(land = 0.7, ocean = 0.3))
})

test_that("5. the stick-breaking resolver implies the flat simplex prior it claims", {
  expect_null(ccx_imb_shares(list()))
  expect_error(ccx_imb_shares(list(imb_share_land = 0.2)), "pair")
  expect_error(ccx_imb_shares(list(imb_share_land = 1.2, imb_share_ocean_rest = 0.5)), "\\[0, 1\\]")
  s <- ccx_imb_shares(list(imb_share_land = 0.4, imb_share_ocean_rest = 0.5))
  expect_equal(s, c(land = 0.4, ocean = 0.3), tolerance = 1e-15)
  # Beta(1,2) x Uniform(0,1) over (s_land, rest), mapped to (s_land, s_ocean) with
  # |d(s_land, s_ocean)/d(s_land, rest)| = 1 - s_land, is CONSTANT (= 2) on the simplex
  sl <- c(0.01, 0.2, 0.5, 0.8, 0.99); r <- c(0.1, 0.9, 0.5, 0.3, 0.7)
  dens <- stats::dbeta(sl, 1, 2) * stats::dunif(r) / (1 - sl)
  expect_equal(dens, rep(2, length(sl)), tolerance = 1e-12)
})

test_that("1-2. absent and (0, 0) are objective #13; shares move the two GCB rows only", {
  skip_if_no_cpp()
  obs <- ccx_prepare_obs()
  sp  <- ccx_spinup(ccx_default_params())
  F   <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
  out <- ccx_run_fast(sp, F)$out
  eluc <- ccx_forcing_eluc_annual(F)
  err <- list(sigma_d14c = 5)
  base <- ccx_loglik(out, obs, err, luc = eluc, by_stream = TRUE)
  zero <- ccx_loglik(out, obs, c(err, imb_share_land = 0, imb_share_ocean = 0), luc = eluc, by_stream = TRUE)
  expect_identical(zero, base)                                      # BIT-EXACT
  sh <- c(land = 0.4, ocean = 0.2)
  al <- ccx_loglik(out, obs, c(err, imb_share_land = sh[["land"]], imb_share_ocean = sh[["ocean"]]),
                   luc = eluc, by_stream = TRUE)
  rows <- c("gcb_land_sink", "gcb_ocean_sink")
  expect_identical(names(al), names(base))
  for (nm in setdiff(names(base), rows)) expect_identical(al[[nm]], base[[nm]], info = nm)
  for (nm in rows) expect_false(isTRUE(all.equal(al[[nm]], base[[nm]])), info = nm)
  # the rows, built by hand from the SAME estimator's annual sinks: recover them
  # from the base rows' own residuals is circular, so rebuild the annual sinks
  yrs <- sort(unique(floor(out$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L); tt <- out$t; nt <- length(tt)
  st <- function(v) { y <- stats::approx(tt, v, xout = bnd)$y; lo <- bnd < tt[1]; hi <- bnd > tt[nt]
    y[lo] <- v[1] + (bnd[lo] - tt[1]) * (v[2] - v[1]) / (tt[2] - tt[1])
    y[hi] <- v[nt] + (bnd[hi] - tt[nt]) * (v[nt] - v[nt - 1]) / (tt[nt] - tt[nt - 1]); y }
  fl <- data.frame(year = utils::head(bnd, -1), ocean = diff(st(out$ocean_C)), land = diff(st(out$land_C)))
  g <- merge(merge(as.data.frame(obs$gcb), fl, by = "year"), data.frame(year = eluc$year, eluc = eluc$eluc), by = "year")
  im <- ccx_imb_series(obs$gcb); I <- im$I[match(g$year, im$year)]
  hand_l <- sum(stats::dnorm(g$land_sink + sh[["land"]] * I, g$land + g$eluc, LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE, log = TRUE))
  hand_o <- sum(stats::dnorm(g$ocean_sink + sh[["ocean"]] * I, g$ocean, LIK_GCB_OCEAN_SD, log = TRUE))
  expect_equal(al[["gcb_land_sink"]],  hand_l, tolerance = 1e-10)
  expect_equal(al[["gcb_ocean_sink"]], hand_o, tolerance = 1e-10)
  # the treatment reaches the rows (raw differs from the default smooth)
  old <- LIK_IMB_TREATMENT; on.exit(assign("LIK_IMB_TREATMENT", old, envir = globalenv()), add = TRUE)
  assign("LIK_IMB_TREATMENT", "raw", envir = globalenv())
  rw <- ccx_loglik(out, obs, c(err, imb_share_land = sh[["land"]], imb_share_ocean = sh[["ocean"]]),
                   luc = eluc, by_stream = TRUE)
  expect_false(isTRUE(all.equal(rw[["gcb_land_sink"]], al[["gcb_land_sink"]])))
  # a half pair is an ERROR, not a zero
  expect_error(ccx_loglik(out, obs, c(err, imb_share_land = 0.4), luc = eluc), "PAIR")
})

test_that("6. the logpost carries the shares from base_params to the rows, and only there", {
  skip_if_no_cpp()
  u  <- ccx_init_unc()
  bp <- ccx_default_params()
  lp_of <- function(b) ccx_make_logpost(base_params = b, spinup_fn = ccx_spinup, by_stream = TRUE)
  a <- lp_of(bp)(u)
  b0 <- bp; b0$imb_share_land <- 0; b0$imb_share_ocean_rest <- 0
  z <- lp_of(b0)(u)
  expect_identical(as.numeric(z), as.numeric(a))                      # (0, 0) = absent, bit-exact
  expect_identical(attr(z, "streams"), attr(a, "streams"))
  b1 <- bp; b1$imb_share_land <- 0.3; b1$imb_share_ocean_rest <- 0.5
  s1 <- attr(lp_of(b1)(u), "streams"); s0 <- attr(a, "streams")
  rows <- c("gcb_land_sink", "gcb_ocean_sink")
  for (nm in setdiff(names(s0), rows)) expect_identical(s1[[nm]], s0[[nm]], info = nm)
  for (nm in rows) expect_false(isTRUE(all.equal(s1[[nm]], s0[[nm]])), info = nm)
})
