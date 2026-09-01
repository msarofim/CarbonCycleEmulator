# =====================================================================
# sigma-INFLATION (option 5, adopted by Marcus 2026-08-28)
#
# The three ocean-gradient rows used to be SKIPPED outside [85, 120] m of h_ml.
# That skip was measured to bear a FREE LUNCH: leaving the band bought +7.30
# log-units of un-scored data out of a +7.39 total advantage, so the objective
# preferred BEING SCORED ON LESS DATA rather than a shallower mixed layer
# (notes/collect_2026-08-28_hml_unbound_profile.md). Inflation carries the
# representation error in quadrature instead, and the rows are scored everywhere.
#
# THESE TESTS GATE THE PROPERTY THE ADOPTION WAS FOR -- continuity of the
# objective in h_ml -- not merely that the code runs.
# =====================================================================

# Bars, named so scoring cannot quietly move them.
SI_EDGE_EPS   <- 0.01     # m; the straddle either side of a retired edge
SI_EDGE_BAR   <- 0.15     # log-units; measured sigma_rep roughness maxes at 0.0734
SI_SHIPPED    <- c(85, 120)   # what the retired band WAS, typed so a rename is caught
SI_RECIPE_TOL <- 1e-6     # the shipped grid vs a fresh recomputation

test_that("the retired band constant is gone from the live path, kept as provenance", {
  expect_false(exists("LIK_OCEAN_GRAD_HML_OK"))
  expect_equal(LIK_OCEAN_GRAD_HML_OK_RETIRED, SI_SHIPPED)
})

test_that("sigma_eff >= sigma_obs everywhere, and is smooth through the crossing", {
  tg <- ccx_ocean_gradient_target()
  skip_if(is.null(tg), "GLODAPv2 gradient block absent")
  sr <- ccx_ocean_sigma_rep_table()
  skip_if(is.null(sr), "obs_glodap_sigma_rep.rds absent -- run data-raw/build_glodap_sigma_rep.R")
  H <- seq(min(sr$h), max(sr$h), by = 0.25)
  for (n in c("dic", "d13c", "alk")) {
    se <- vapply(H, function(h) ccx_ocean_sigma_eff(n, h), numeric(1))
    expect_true(all(is.finite(se)))
    expect_true(all(se >= tg[[n]]$sd - 1e-12))
    # ⚠ The shipped grid is the SIGNED like-for-like target. Folding it to
    # |sigma_rep| is NOT a smoothness question -- sigma_eff squares the
    # difference, so the two agree to 0.0002 sigma_obs. This gates that
    # equivalence, so a future reader cannot mistake the choice for a fix.
    folded <- stats::splinefun(sr$h, abs(sr$like_for_like[[n]] - tg[[n]]$target),
                               method = "monoH.FC")
    se_f <- sqrt(tg[[n]]$sd^2 + folded(H)^2)
    expect_lt(max(abs(se - se_f)) / tg[[n]]$sd, 1e-3)
    # Roughness from bottle selection, which IS real and is measured, not assumed:
    # median 0.0055 / max 0.0734 log-units on the three rows' summed logL.
    expect_lt(max(abs(diff(se))) / tg[[n]]$sd, 0.02)
  }
})

test_that("a hand-built ocean_grad without sd_eff is LOUD, not silently rescored", {
  skip_if_no_cpp()
  tg <- ccx_ocean_gradient_target()
  skip_if(is.null(tg), "GLODAPv2 gradient block absent")
  p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5))
  sp <- ccx_spinup(p)
  ff <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
  f <- list(obs = ccx_prepare_obs(), out = ccx_run_fast(sp, ff)$out,
            err = list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5))
  # Scoring at sigma_obs is the RETIRED objective. It must be impossible to reach
  # by omission -- a silent fallback would produce a number that looks comparable
  # with post-adoption fits and is not.
  expect_error(
    ccx_loglik(f$out, f$obs, f$err, by_stream = TRUE,
               ocean_grad = list(dic = tg$dic$target, d13c = tg$d13c$target)),
    "sd_eff")
  # ...and the supported constructor supplies it.
  se <- vapply(c("dic", "d13c", "alk"), ccx_ocean_sigma_eff, numeric(1), h_ml = 100)
  ok <- ccx_loglik(f$out, f$obs, f$err, by_stream = TRUE,
                   ocean_grad = list(dic = tg$dic$target, d13c = tg$d13c$target,
                                     alk = tg$alk$target, sd_eff = se))
  expect_true(all(c("ocean_grad_dic", "ocean_grad_d13c", "ocean_grad_alk") %in% names(ok)))
})

test_that("THE CLIFF IS GONE: no jump in the rows across either retired band edge", {
  skip_if_no_cpp()
  skip_if(is.null(ccx_ocean_gradient_target()), "GLODAPv2 gradient block absent")
  skip_if(is.null(ccx_ocean_sigma_rep_table()), "obs_glodap_sigma_rep.rds absent")
  # THIS IS THE ADOPTION'S WHOLE PURPOSE. Under the retired skip these straddles
  # measured +7.3005 at 85 m and +8.4257 at 120 m -- a discontinuity in the
  # posterior's SOFTEST direction. They must now be continuous.
  rows_at <- function(h) {
    p <- ccx_default_params(); p$h_ml <- h
    sp <- ccx_spinup(p)
    ff <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
    og <- ccx_ocean_grad_scored(ccx_run_fast(sp, ff)$out, sp)
    tg <- ccx_ocean_gradient_target()
    sum(vapply(c("dic", "d13c", "alk"), function(n)
      stats::dnorm(tg[[n]]$target, og[[n]], og$sd_eff[[n]], log = TRUE), numeric(1)))
  }
  for (edge in SI_SHIPPED) {
    lo <- rows_at(edge - SI_EDGE_EPS); hi <- rows_at(edge + SI_EDGE_EPS)
    expect_true(is.finite(lo) && is.finite(hi))
    expect_lt(abs(hi - lo), SI_EDGE_BAR)
  }
})

test_that("the shipped sigma_rep grid still reproduces its own recipe", {
  sr <- ccx_ocean_sigma_rep_table()
  skip_if(is.null(sr), "obs_glodap_sigma_rep.rds absent")
  iso <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
  skip_if_not(file.exists(iso), "GLODAP isotope subset not present")
  # Guards data/obs_glodap_sigma_rep.rds against silent drift from its builder.
  # The isotope population covers dic + d13c; ALK lives in a 19 MB file and is
  # deliberately not read in the suite.
  d <- utils::read.csv(iso)
  r <- sr$recipe
  cell <- function(val, flag, zmin, zmax) {
    v <- d[[val]]; fl <- d[[flag]]
    ok <- is.finite(v) & v > -900 & is.finite(fl) & fl == r$flag_ok &
          d$depth >= zmin & d$depth < zmax
    x <- d[ok, ]
    id <- paste(floor(x$lat / r$dlat), floor(x$lon / r$dlon), floor(x$depth / r$dz))
    m <- as.numeric(tapply(x[[val]], id, mean)); la <- as.numeric(tapply(x$lat, id, mean))
    sum(cos(la * pi / 180) * m) / sum(cos(la * pi / 180))
  }
  for (spec in list(c("dic", "tco2", "tco2f"), c("d13c", "c13", "c13f")))
    for (h in c(40, 96, 150)) {
      gr <- ccx_ocean_grid(h); zb <- c(0, cumsum(gr$dz)); k <- length(gr$dz)
      fresh <- cell(spec[2], spec[3], zb[k], zb[k + 1]) - cell(spec[2], spec[3], 0, zb[2])
      expect_equal(sr$fun[[spec[1]]](h), fresh, tolerance = SI_RECIPE_TOL)
    }
})
