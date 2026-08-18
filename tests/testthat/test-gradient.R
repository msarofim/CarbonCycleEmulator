# =====================================================================
# Gate: the interhemispheric-gradient terms (2026-08-15, review item 5).
#
# DESIGN sec.6 gate 9 claimed since it was written that the MLO-SPO gradient is
# "the main constraint on tau_ex", and the objective had no gradient term at
# all. These terms are that claim, finally made true. Each test below guards a
# way the change could be silently wrong rather than loudly broken:
#
#   1. THE ESTIMATOR IS THE ONE GATE 9 SPECIFIES. Gate 9's first trap is that
#      seasonal adjustment is "mandatory, not cosmetic" -- uneven month coverage
#      aliases MLO's 6 ppm cycle into the difference and turns the 1950s
#      NEGATIVE. If differenced ccx_year_harmonic() levels did not reproduce
#      gate 9's decadal table, the term would be scoring a different quantity
#      from the one DESIGN tabulates and nothing would say so.
#   2. THE ABSENCE CONTRACT. A caller that supplies no offset must see the
#      stream ABSENT, not scored at a silent zero. A zero offset is not a
#      neutral default: it asserts the model's box gradient IS the station
#      gradient, which part 3 of diag_gradient_terms.R rejects at 95 %.
#   3. THE OFFSET IS LOAD-BEARING AND POINTS THE RIGHT WAY. MLO sits south of
#      the northern source region, so the station gradient must be SMALLER than
#      the box gradient and the CO2 offset must come out NEGATIVE. A sign error
#      here would be invisible in the total and would double the miss.
#   4. THE SIGMAS ARE NOT BELOW WHAT THE OBSERVATIONS RESOLVE. Recomputed from
#      the two networks in the repo, not read back from the constants. This is
#      the test that fires if someone tightens a sigma to buy leverage.
#   5. THE TERM ACTUALLY CONSTRAINS tau_ex, which is the entire reason it
#      exists, and it constrains it in the direction the current objective does
#      NOT -- so a future refactor that quietly neuters it gets caught.
# =====================================================================

skip_if_no_cpp <- function() {
  skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) skip("C++ core failed to compile")
}

GR_YEARS <- c(1750, 2024)
GR_SIG3  <- list(sigma_co2 = 1.5, sigma_d13c = 0.44, sigma_d14c = 5)
# DESIGN sec.6 gate 9, decadal, seasonally adjusted
GR_GATE9 <- c(`1960` = 0.85, `1970` = 1.66, `1980` = 1.96, `1990` = 2.32,
              `2000` = 2.72, `2010` = 3.66, `2020` = 3.97)
GR_GATE9_TOL <- 0.03            # ppm; the measured worst decade is 0.02

gr_obs <- local({ o <- NULL; function() { if (is.null(o)) o <<- ccx_prepare_obs(); o } })

gr_run <- function(p = ccx_default_params()) {
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", GR_YEARS, prod_c14 = sp$prod_c14)
  o  <- ccx_run_fast(sp, F)$out
  list(out = o, ms = ccx_model_stats(o, gr_obs()),
       luc = ccx_forcing_eluc_annual(F))
}
gr_parts <- function(r, off_co2 = NULL, off_d13c = NULL) {
  err <- GR_SIG3
  if (!is.null(off_co2))  err$grad_off_co2  <- off_co2
  if (!is.null(off_d13c)) err$grad_off_d13c <- off_d13c
  ccx_loglik(r$out, gr_obs(), err, luc = r$luc, by_stream = TRUE)
}

# ---------------------------------------------------------------------
test_that("1. the scored observed gradient reproduces DESIGN gate 9's table", {
  g <- gr_obs()$co2_grad
  expect_gt(nrow(g), 50)
  dec <- floor(g$year / 10) * 10
  tb  <- tapply(g$grad, dec, mean)
  for (d in names(GR_GATE9)) {
    if (!d %in% names(tb)) next
    expect_lt(abs(tb[[d]] - GR_GATE9[[d]]), GR_GATE9_TOL,
              label = sprintf("decade %ss (%.2f vs gate 9 %.2f)",
                              d, tb[[d]], GR_GATE9[[d]]))
  }
  # gate 9's 1950s entry rests on 8 paired MONTHS and its own note calls it
  # indicative only; the 9-month annual minimum must drop it rather than score it
  expect_false("1950" %in% names(tb))
})

test_that("1b. the model side goes through the SAME estimator", {
  skip_if_no_cpp()
  r <- gr_run()
  A <- r$ms$co2$MLO; B <- r$ms$co2$SPO
  g <- gr_obs()$co2_grad
  mg <- A$level[match(g$year, A$year)] - B$level[match(g$year, B$year)]
  expect_true(all(is.finite(mg)))
  # the scored model gradient IS the difference of the levels the level terms
  # score -- no second estimator, nothing to drift apart
  expect_equal(mg, (A$level - B$level)[match(g$year, A$year)])
})

# ---------------------------------------------------------------------
test_that("2. no offset in `err` leaves the streams ABSENT, not zeroed", {
  skip_if_no_cpp()
  r <- gr_run()
  p3 <- gr_parts(r)
  expect_false("co2_gradient"  %in% names(p3))
  expect_false("d13c_gradient" %in% names(p3))
  p5 <- gr_parts(r, 0, 0)
  expect_true("co2_gradient"  %in% names(p5))
  expect_true("d13c_gradient" %in% names(p5))
  # and the absent case is not the zero-offset case wearing a different name
  expect_false(isTRUE(all.equal(sum(p3), sum(p5))))
})

test_that("2b. one offset supplied scores one stream only", {
  skip_if_no_cpp()
  r <- gr_run()
  p <- gr_parts(r, off_co2 = 0)
  expect_true("co2_gradient" %in% names(p))
  expect_false("d13c_gradient" %in% names(p))
})

# ---------------------------------------------------------------------
test_that("3. the CO2 offset is load-bearing, and its optimum is NEGATIVE", {
  skip_if_no_cpp()
  r <- gr_run()
  grid <- seq(-2, 1, by = 0.02)
  v <- vapply(grid, function(x) gr_parts(r, off_co2 = x)[["co2_gradient"]],
              numeric(1))
  best <- grid[which.max(v)]
  # NEGATIVE: MLO sits south of the northern source region, so the station
  # gradient must be smaller than the model's box gradient. A sign error would
  # put this positive and would double the miss instead of removing it.
  expect_lt(best, 0)
  # and it is load-bearing: the offset is worth a large multiple of the term's
  # own scale, so fixing it at zero is not a neutral simplification
  expect_gt(max(v) - v[grid == 0], 50)
})

test_that("3b. the d13C offset optimum is POSITIVE and of the measured size", {
  skip_if_no_cpp()
  r <- gr_run()
  grid <- seq(-0.3, 0.3, by = 0.005)
  v <- vapply(grid, function(x) gr_parts(r, off_d13c = x)[["d13c_gradient"]],
              numeric(1))
  best <- grid[which.max(v)]
  expect_gt(best, 0.05); expect_lt(best, 0.20)
})

# ---------------------------------------------------------------------
test_that("4. neither sigma claims more precision than the observations have", {
  # Recomputed from the data, NOT read back from the constants: this is the
  # test that fires if a sigma is ever tightened to buy leverage.
  gr_net <- function(file, vcol, a1, b1, a2, b2) {
    d <- as.data.frame(readRDS(ccx_path("data", file)))
    lev <- function(st) {
      o <- d[d$station == st, ]
      if (!nrow(o)) return(NULL)
      ccx_year_harmonic(o$decimal_date, o[[vcol]])[, c("year", "level")]
    }
    gg <- function(x, y) {
      A <- lev(x); B <- lev(y)
      if (is.null(A) || is.null(B)) return(NULL)
      m <- merge(A, B, by = "year"); data.frame(year = m$year, g = m$level.x - m$level.y)
    }
    s <- gg(a1, b1); n <- gg(a2, b2)
    if (is.null(s) || is.null(n)) return(NA_real_)
    m <- merge(s, n, by = "year")
    if (nrow(m) < 10) return(NA_real_)
    sqrt(mean((m$g.x - m$g.y)^2))
  }
  f_co2 <- gr_net("obs_co2_monthly.rds", "co2_ppm", "MLO", "SPO",
                  "MLO_NOAA", "SPO_NOAA")
  f_d13 <- gr_net("obs_d13c_monthly.rds", "d13c", "MLO", "SPO",
                  "MLO_NOAA", "SPO_NOAA")
  skip_if(is.na(f_co2) || is.na(f_d13), "network cross-check unavailable")
  expect_gt(LIK_GRAD_CO2_SD,  f_co2)     # floor ~0.225 ppm, and a LOWER bound
  expect_gt(LIK_GRAD_D13C_SD, f_d13)     # floor ~0.015 permil
  # ...and not absurdly above it either, which would make the terms decoration
  expect_lt(LIK_GRAD_CO2_SD,  4 * f_co2)
  expect_lt(LIK_GRAD_D13C_SD, 4 * f_d13)
})

# ---------------------------------------------------------------------
test_that("5. the term constrains tau_ex, and not in the direction the rest does", {
  skip_if_no_cpp()
  # seas_drivers = 0: this test reads a SIGN off small logL differences, and on
  # the driver path at UNCALIBRATED defaults the seasonal streams misfit by
  # hundreds of log-units (amp 5 vs 3 ppm until the refit), swamping d_other
  # with seasonal noise that has nothing to do with tau_ex. The term's
  # directionality was derived on the incumbent model; instrument it there.
  # Re-point to the driver path after a driver-era refit exists.
  p_b <- ccx_default_params(); p_b$seas_drivers <- 0
  base <- gr_run(p_b)
  p_lo <- p_b; p_lo$tau_ex <- p_lo$tau_ex * exp(-0.25)
  r_lo <- gr_run(p_lo)
  b5 <- gr_parts(base, 0, 0); l5 <- gr_parts(r_lo, 0, 0)
  d_grad  <- l5[["co2_gradient"]] - b5[["co2_gradient"]]
  d_other <- sum(l5[!names(l5) %in% c("co2_gradient", "d13c_gradient")]) -
             sum(b5[!names(b5) %in% c("co2_gradient", "d13c_gradient")])
  # worth more than one prior sd of anything the review measured as small
  expect_gt(abs(d_grad), 50)
  # OPPOSITE SIGN to the rest of the objective. This is the whole case for the
  # term: it supplies information the objective did not have. If a refactor ever
  # makes these agree, the term has stopped doing its job.
  expect_lt(d_grad * d_other, 0)
})

# ---------------------------------------------------------------------
test_that("6. the double count stays second-order, so ADD-a-term still beats ROTATE", {
  # ADDED 2026-08-15 with the retirement of sigma_co2 (review item 6b), because
  # the LIK_GRAD_* block's standing instruction is "re-measure if sigma_co2 or
  # LIK_CO2_REP_ERR move" and one of them just did.
  #
  # The two station levels price their difference implicitly at sd*sqrt(2). The
  # decision to ADD a gradient term rather than ROTATE (MLO, SPO) -> (mean,
  # gradient) rested on the added term outweighing that implicit one by enough
  # for the overlap to be second-order (~17x in variance, handoff 2026-08-15b
  # sec.3.1). With sigma_co2 gone, LIK_CO2_REP_ERR is the ONLY input to the
  # implicit sd -- so this is now a pure constants check and cannot go stale
  # against the model. It fails if anyone lowers LIK_CO2_REP_ERR or loosens
  # LIK_GRAD_CO2_SD far enough to make the rotation the honest form again.
  implied <- LIK_CO2_REP_ERR * sqrt(2)
  ratio   <- (implied / LIK_GRAD_CO2_SD)^2
  expect_gt(ratio, 4)          # second-order overlap; below this, re-open the
                               # rotation question rather than adjusting a sigma
  expect_equal(ratio, 16.3, tolerance = 0.05)   # the value recorded on retirement
})
