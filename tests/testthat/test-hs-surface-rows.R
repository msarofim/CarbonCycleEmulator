# =====================================================================
# OBJECTIVE #11 -- THE HS SURFACE ROWS (2026-09-07f)
#
# The HILDA HS box's surface DIC (SH) and d13C (both hemispheres) scored against
# GLODAPv2.2023 high-latitude surface bottles at their own epochs. Built because
# the HS pump buys the deep gradients partly with the HS surface d13C
# (probe 09-07e, P6): without these rows a refit could spend an unscored
# observable.
#
# WHAT THESE TESTS GUARD:
#   * the flag ships ON and the product exists with both rows and their epochs.
#   * the HS columns ride in CCX_OCEAN_BOX_COLS on BOTH cores: NA with the
#     structure off, finite with it on, R == C++.
#   * the rows are ABSENT with the structure off and PRESENT with it on, and
#     their values are the box concentration at the epoch (recomputed here).
#   * MUTATION: the HS pump moves hs_surf_d13c (it strips light carbon), so the
#     row is live, not a constant.
#   * sigma_eff is DERIVED from the product (sd and sd_cluster), not typed.
# =====================================================================

hr_par <- function(hs = TRUE, g = 0) {
  p <- ccx_default_params()
  if (hs) { p$hs_frac <- 0.16; p$u_hs <- 38; p$tau_q <- 538; p$sst_hs <- 2 }
  p$pump_hs_gcm2 <- g
  p
}
hr_run <- function(p, to = 2012) {
  sp <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", c(1750, to), prod_c14 = sp$prod_c14)
  list(sp = sp, out = ccx_run_fast(sp, F)$out, F = F)
}
# file-level memo on (hs, g, to) (review B4, 2026-09-12): the structure-off 1760
# run and the default structure-on run were each made twice
hr_memo <- new.env()
hr_at <- function(hs = TRUE, g = 0, to = 2012) {
  k <- paste(hs, g, to)
  if (is.null(hr_memo[[k]])) hr_memo[[k]] <- hr_run(hr_par(hs = hs, g = g), to = to)
  hr_memo[[k]]
}

test_that("the flag ships ON and the product carries both rows with epochs and derived sigmas", {
  expect_true(LIK_USE_HS_SURFACE)
  tg <- ccx_hs_surface_target(); expect_false(is.null(tg))
  for (n in c("dic", "d13c")) {
    expect_true(all(c("target", "sd", "sd_cluster", "n_eff", "epoch") %in% names(tg[[n]])))
    expect_gt(tg[[n]]$n_eff, 30); expect_gt(tg[[n]]$sd_cluster, tg[[n]]$sd)
  }
  expect_identical(tg$dic$hemis, "SH")
})

test_that("the HS columns are in CCX_OCEAN_BOX_COLS, NA with the structure off, finite and R == C++ with it on", {
  skip_if_no_cpp()
  expect_true(all(c("hs_C_NH", "hs_C13_NH", "hs_C_SH", "hs_C13_SH") %in% CCX_OCEAN_BOX_COLS))
  off <- hr_at(hs = FALSE, to = 1760)
  expect_true(all(is.na(off$out$hs_C_SH))); expect_false(anyNA(off$out$ml_C_SH))
  sp <- ccx_spinup(hr_par()); F <- ccx_build_forcing("historical", c(1750, 1760), prod_c14 = sp$prod_c14)
  rR <- ccx_run(sp, F)$out; rC <- ccx_run_fast(sp, F)$out
  for (cc in c("hs_C_NH", "hs_C13_SH")) { expect_false(anyNA(rC[[cc]])); expect_equal(rR[[cc]], rC[[cc]], tolerance = 1e-10) }
  expect_gt(max(abs(rC$hs_C_NH - rC$ml_C_NH)), 0)          # not a transposition of the ML column
})

test_that("rows are absent with the structure off, present with it on, and equal the box state at the epoch", {
  skip_if_no_cpp()
  off <- hr_at(hs = FALSE, to = 1760)
  expect_null(ccx_ocean_grad_scored(off$out, off$sp)$hs_surf)
  on <- hr_at(); g <- ccx_ocean_grad_scored(on$out, on$sp); hs <- g$hs_surf
  expect_false(is.null(hs)); tg <- ccx_hs_surface_target(); aux <- on$sp$aux
  # recompute DIC by hand: the ANNUAL MEAN over the epoch year (2026-09-11 (5)),
  # 12 month-centres, each over the box's mass then (constant here: no seasonal HS)
  tt <- ccx_epoch_year_samples(tg$dic$epoch)
  C <- stats::approx(on$out$t, on$out$hs_C_SH, xout = tt, rule = 2)$y
  expect_equal(hs$dic, mean(C * aux$mol_per_GtC / aux$hs_mass_kg$SH * 1e6), tolerance = 1e-12)
  # and it is NOT the instant read (the retired form) -- the box has its own seasonal cycle
  C1 <- stats::approx(on$out$t, on$out$hs_C_SH, xout = tg$dic$epoch, rule = 2)$y
  expect_false(isTRUE(all.equal(hs$dic, C1 * aux$mol_per_GtC / aux$hs_mass_kg$SH * 1e6, tolerance = 1e-6)))
  expect_true(hs$dic > 1900 && hs$dic < 2400)                # a surface-ocean number
  expect_equal(unname(hs$sd_eff[["dic"]]), sqrt(tg$dic$sd^2 + tg$dic$sd_cluster^2))
  expect_equal(unname(hs$sd_eff[["d13c"]]), sqrt(tg$d13c$sd^2 + tg$d13c$sd_cluster^2))
  # and the loglik carries the two rows, as dnorm of exactly these
  obs <- ccx_prepare_obs(); err <- list(sigma_d14c = 20, rep_dC = 0.3, grad_off_co2 = 0, grad_off_d13c = 0)
  # no tryCatch (review A15, 2026-09-12): an error here must FAIL the test, not
  # make the two row assertions vanish silently
  st <- ccx_loglik(on$out, obs, err, ocean_grad = g, by_stream = TRUE)
  expect_true(all(c("hs_surf_dic", "hs_surf_d13c") %in% names(st)))
  expect_equal(unname(st[["hs_surf_dic"]]), stats::dnorm(tg$dic$target, hs$dic, hs$sd_eff[["dic"]], log = TRUE))
})

test_that("MUTATION: the HS pump moves hs_surf_d13c -- the row is live", {
  skip_if_no_cpp()
  a <- hr_at(g = 0); b <- hr_at(g = 60)
  ha <- ccx_ocean_grad_scored(a$out, a$sp)$hs_surf; hb <- ccx_ocean_grad_scored(b$out, b$sp)$hs_surf
  expect_gt(abs(hb$d13c - ha$d13c), 0.05)
  expect_gt(abs(hb$dic - ha$dic), 1)
})
