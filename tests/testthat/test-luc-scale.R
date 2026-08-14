# =====================================================================
# test-luc-scale.R -- the land-use input-uncertainty parameter (2026-08-14)
#
# `luc_scale` exists so E_LUC's own uncertainty has somewhere to go other than
# `beta`. Three things have to hold for that to be true rather than decorative:
#
#   1. it is BIT-IDENTICAL at 1, so adding it changed no existing result;
#   2. the fast path used inside the MCMC (a column multiply on a prebuilt
#      forcing) equals the slow path (rebuilding the forcing with the scale) --
#      including the PRE-WINDOW cumulative, which is where a partial application
#      would hide;
#   3. the gross-sink likelihood term follows the MODEL's scaled land-use flux
#      and not GCB's unscaled column.
# =====================================================================

test_that("luc_scale = 1 is bit-identical to the unscaled forcing", {
  a <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0)
  b <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, luc_scale = 1)
  expect_identical(as.data.frame(a), as.data.frame(b))
  expect_equal(attr(b, "luc_scale"), 1)
})

test_that("the MCMC's column rescale equals rebuilding the forcing", {
  s <- 0.65
  base <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0)
  slow <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, luc_scale = s)

  fast <- base
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    fast[[cc]] <- base[[cc]] * s

  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    expect_equal(fast[[cc]], slow[[cc]], tolerance = 1e-12,
                 info = paste("column", cc))
  # nothing else may move
  for (cc in c("e_foss_NH", "e_foss_SH", "gmst", "enso", "c14_bomb"))
    expect_equal(base[[cc]], slow[[cc]], tolerance = 1e-12)
})

test_that("the PRE-WINDOW cumulative scales too", {
  # A window starting in 1900 carries 1750-1899 clearing in cum_luc's offset.
  # Scaling the monthly columns after the fact would scale that offset as well
  # (it is inside the column), but scaling only e_luc and NOT cum_luc -- or
  # rebuilding without touching luc_pre -- would leave the cleared fraction
  # inconsistent with the flux. This pins the offset itself.
  s <- 0.5
  a <- ccx_build_forcing("historical", c(1900, 2024), prod_c14 = 0)
  b <- ccx_build_forcing("historical", c(1900, 2024), prod_c14 = 0, luc_scale = s)
  cum_a <- a$cum_luc_NH[1] + a$cum_luc_SH[1]
  cum_b <- b$cum_luc_NH[1] + b$cum_luc_SH[1]
  expect_gt(cum_a, 20)                       # there IS a pre-window offset
  expect_equal(cum_b, s * cum_a, tolerance = 1e-10)
})

test_that("luc_scale is rejected if it is not a usable multiplier", {
  expect_error(ccx_build_forcing("historical", c(1900, 1950), prod_c14 = 0,
                                 luc_scale = -1), "non-negative")
  expect_error(ccx_build_forcing("historical", c(1900, 1950), prod_c14 = 0,
                                 luc_scale = NA_real_), "finite")
})

test_that("the gross-sink term uses the MODEL's land-use flux, not GCB's", {
  s   <- 0.65
  obs <- ccx_prepare_obs()
  p   <- ccx_default_params()
  sp  <- ccx_spinup(p)
  F   <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14,
                           luc_scale = s)
  out <- ccx_run_fast(sp, F)$out
  err <- list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5)

  eluc <- ccx_forcing_eluc_annual(F)
  # the model's own flux really is the scaled one
  expect_equal(mean(eluc$eluc[eluc$year >= 2015]),
               s * mean(obs$gcb$luc[obs$gcb$year >= 2015]), tolerance = 1e-8)

  right <- ccx_loglik(out, obs, err, luc = eluc,  by_stream = TRUE)
  wrong <- ccx_loglik(out, obs, err, luc = NULL,  by_stream = TRUE)

  # Passing the scaled flux must change the land term and ONLY the land term.
  expect_false(isTRUE(all.equal(right[["gcb_land_sink"]],
                                wrong[["gcb_land_sink"]])))
  for (nm in setdiff(names(right), "gcb_land_sink"))
    expect_equal(right[[nm]], wrong[[nm]], tolerance = 1e-10, info = nm)
})

test_that("the land term compares GROSS to GROSS", {
  # The defect fixed 2026-08-14: the model's d(land_C)/dt is NET of E_LUC and
  # GCB's land_sink column is GROSS. Reconstructed correctly, a model whose
  # gross sink equals GCB's must score at the density's peak. Built here as an
  # explicit arithmetic identity rather than by trusting the implementation.
  obs <- ccx_prepare_obs()
  p   <- ccx_default_params()
  sp  <- ccx_spinup(p)
  F   <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
  out <- ccx_run_fast(sp, F)$out
  err <- list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5)
  parts <- ccx_loglik(out, obs, err, by_stream = TRUE)

  eluc <- ccx_forcing_eluc_annual(F)
  yrs  <- sort(unique(floor(out$t + 1e-9)))
  bnd  <- c(yrs, max(yrs) + 1L)
  st   <- function(v) stats::approx(out$t, v, xout = bnd, rule = 2)$y
  fl   <- data.frame(year = utils::head(bnd, -1), land = diff(st(out$land_C)))
  g    <- merge(as.data.frame(obs$gcb)[, c("year", "land_sink")], fl, by = "year")
  g    <- merge(g, eluc, by = "year")
  ref  <- sum(stats::dnorm(g$land_sink, g$land + g$eluc,
                           LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE, log = TRUE))
  # rule = 2 here vs the end-extrapolation inside ccx_loglik() differ only on
  # the two boundary years, so an ABSOLUTE tolerance of 1 log-unit on a term of
  # order -122 is the tight check; a relative one would have been meaningless.
  expect_lt(abs(parts[["gcb_land_sink"]] - ref), 1)

  # ...and it must be a long way from the NET comparison, which is what the bug
  # scored. NOTE THE DIRECTION, because it is counter-intuitive and it is the
  # whole point: at the current default the NET (buggy) comparison scores
  # BETTER -- -97.3 against -122.0 -- because the model over-absorbs, its gross
  # sink being 4.57 GtC/yr against GCB's 2.36. The bug was FLATTERING the
  # high-beta model, which is exactly why nothing objected to beta rising. Do
  # not "fix" this test by asserting gross beats net; that holds only for a
  # model whose sink is right, and asserting it would re-introduce the bug the
  # day the model improved.
  net <- sum(stats::dnorm(g$land_sink, g$land,
                          LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE, log = TRUE))
  expect_gt(abs(parts[["gcb_land_sink"]] - net), 10)
})
