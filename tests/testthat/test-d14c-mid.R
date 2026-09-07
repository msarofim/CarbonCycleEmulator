# =====================================================================
# THE INTERMEDIATE D14C ROWS (2026-09-06) -- two GLODAPv2 slabs, 1500-2000 m
# and 2000-2627.2 m, scoring the depths where the model's ventilation error
# actually sits. Objective change #8.
#
# WHAT THESE TESTS GUARD:
#   * the targets tile the bomb-free interior with the deep row, no gap, no
#     overlap, and their sigma is DERIVED from the stored spread and n_eff.
#   * the rows are ABSENT without `d14c_mid`, Gaussian with it, and by_stream
#     still decomposes into the total -- the deep row's own contract.
#   * the model-side slab mean is thickness-weighted and pooled over both
#     hemispheres the way the bottom box is: a layer wholly inside a slab
#     contributes its whole stock, one half inside contributes half.
#   * MUTATION: slower mixing must age the slabs, and the objective must
#     actually carry the rows (switching them off changes the logpost by
#     exactly their Gaussians).
# =====================================================================

skip_if_no_cpp <- function() {
  skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) skip("C++ core failed to compile")
}
skip_if_no_mid <- function() skip_if(is.null(ccx_mid_d14c_target()), "intermediate build product absent")
# The fixture helper now lives in R/likelihood.R as ccx_profile_rows_delta()
# (2026-09-07): ONE source for the objective and every fixture.

test_that("the two slabs tile 1500 m to the deep row's top, with a derived sigma", {
  skip_if_no_mid()
  tg <- ccx_mid_d14c_target()
  expect_equal(nrow(tg$slabs), 2L)
  expect_equal(tg$slabs$top[1], 1500)
  expect_equal(tg$slabs$bot[1], tg$slabs$top[2])
  expect_equal(tg$slabs$bot[2], tg$deep_top)
  dp <- ccx_deep_d14c_target()
  if (!is.null(dp)) expect_equal(tg$deep_top, unname(dp$layer[["top"]]))
  expect_equal(tg$slabs$sd, tg$slabs$sd_spread / sqrt(tg$n_eff))
  # the upper slab is younger than the lower (the observation says so, 7 permil
  # against a 13.5 permil se); the lower slab and the deep row are a TIE within
  # their error bars (-175.6 vs -175.3) -- asserting a strict ordering there
  # would be asserting something the data do not say
  expect_gt(tg$slabs$target[1], tg$slabs$target[2])
  if (!is.null(dp)) expect_lt(abs(tg$slabs$target[2] - dp$target), dp$sd)
  expect_identical(tg$slabs$stream, c("d14c_mid_1500_2000", "d14c_mid_2000_2627"))
})

test_that("the slab mean is thickness-weighted and pooled like the bottom box", {
  p  <- ccx_default_params(); sp <- ccx_spinup(p)
  g  <- sp$grid; zb <- cumsum(g$dz)
  # a slab exactly equal to the bottom box reproduces d14c_bottom_box
  bot <- data.frame(name = "bot", top = zb[length(zb) - 1], bot = zb[length(zb)])
  expect_equal(unname(ccx_model_d14c_slabs(sp, bot)[["bot"]]),
               sp$diagnostics$d14c_bottom_box, tolerance = 1e-12)
  # a slab covering the lower half of the bottom box gives the SAME value (the
  # layer is uniform), so the weighting cannot invent structure inside a layer
  half <- data.frame(name = "h", top = mean(zb[length(zb) - 1:0]), bot = zb[length(zb)])
  expect_equal(unname(ccx_model_d14c_slabs(sp, half)[["h"]]),
               sp$diagnostics$d14c_bottom_box, tolerance = 1e-12)
  # a slab straddling two layers lies strictly between their values
  two <- data.frame(name = "t", top = zb[length(zb) - 2], bot = zb[length(zb)])
  v <- unname(ccx_model_d14c_slabs(sp, two)[["t"]])
  lay <- function(k) { ix <- c(sp$aux$idx$NH$oc[k], sp$aux$idx$SH$oc[k])
                       1000 * (sum(sp$y[ix, "C14"]) / sum(sp$y[ix, "C"]) - 1) }
  expect_true(v < lay(g$nl - 1) && v > lay(g$nl))
})

test_that("the rows are absent without `d14c_mid`, Gaussian with it, and decompose", {
  skip_if_no_cpp(); skip_if_no_mid()
  p  <- ccx_default_params(); sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1955, 1960), prod_c14 = sp$prod_c14)
  o  <- ccx_run_fast(sp, F)$out
  obs <- ccx_prepare_obs(); err <- list(sigma_d14c = 5, rep_dC = 0)
  bare <- ccx_loglik(o, obs, err, by_stream = TRUE)
  tg <- ccx_mid_d14c_target()
  expect_false(any(tg$slabs$stream %in% names(bare)))
  at <- function(v) ccx_loglik(o, obs, err, by_stream = TRUE, d14c_mid = v)
  parts <- at(stats::setNames(tg$slabs$target, tg$slabs$name))
  expect_true(all(tg$slabs$stream %in% names(parts)))
  for (i in 1:2)
    expect_equal(unname(parts[[tg$slabs$stream[i]]]),
                 stats::dnorm(0, 0, tg$slabs$sd[i], log = TRUE), tolerance = 1e-10)
  # quadratic in the miss, per slab
  z <- function(k, s) { v <- stats::setNames(tg$slabs$target, tg$slabs$name); v[k] <- v[k] + s * tg$slabs$sd[k]; v }
  cost <- function(k, s) parts[[tg$slabs$stream[k]]] - at(z(k, s))[[tg$slabs$stream[k]]]
  expect_equal(cost(1, 2), 4 * cost(1, 1), tolerance = 1e-8)
  expect_equal(cost(2, 1), 0.5, tolerance = 1e-8)
  expect_equal(sum(parts), ccx_loglik(o, obs, err, d14c_mid = stats::setNames(tg$slabs$target, tg$slabs$name)),
               tolerance = 1e-9)
})

test_that("MUTATION: slower mixing ages both slabs", {
  p <- ccx_default_params()
  a <- ccx_model_d14c_slabs(ccx_spinup(p))
  p$kz <- p$kz * 0.5
  b <- ccx_model_d14c_slabs(ccx_spinup(p))
  skip_if(is.null(a), "intermediate build product absent")
  expect_true(all(b < a - 1))
})

test_that("the objective carries the rows: switching them off moves the logpost by their Gaussians", {
  skip_if_no_cpp(); skip_if_no_mid()
  u0 <- ccx_init_unc()                      # the table's own init vector
  sc <- function(on) { old <- LIK_USE_D14C_MID
    assign("LIK_USE_D14C_MID", on, envir = globalenv())
    on.exit(assign("LIK_USE_D14C_MID", old, envir = globalenv()), add = TRUE)
    ccx_make_logpost()(u0) }
  on <- sc(TRUE); off <- sc(FALSE)
  tg  <- ccx_mid_d14c_target()
  pp  <- ccx_overlay_par(ccx_default_params(), ccx_unc_to_par(u0))
  sp  <- ccx_spinup(pp); mid <- ccx_model_d14c_slabs(sp); deep <- sp$diagnostics$d14c_bottom_box
  rows <- ccx_profile_rows_delta(mid, deep)   # what switching the mid rows OFF removes
  expect_equal(on - off, rows, tolerance = 1e-6, scale = 1)
  expect_gt(abs(rows), 0.1)   # and they are not a vanishing constant
})
