# =====================================================================
# Gate: within-year emission seasonality (2026-08-15, review item 5c).
#
# The change adds a monthly weight to the fossil and land-use inputs. It is a
# REDISTRIBUTION, so the one thing that must never break is annual conservation
# -- and the repo has a standing rule that anything quietly changing annual sums
# changes the answer (R/forcing.R's header). Everything else here guards a
# specific way the change could be silently wrong:
#
#   1. ANNUAL TOTALS ARE UNTOUCHED, to machine precision, for BOTH inputs and
#      for the cumulative land-use series the converted-land term reads.
#   2. THE SWITCH OFF REPRODUCES THE OLD MODEL EXACTLY. Without that, every
#      pre-2026-08-15 result becomes unreproducible.
#   3. THE PHASES ARE RIGHT. Fossil NH peaks in northern winter and fossil SH in
#      southern winter; land-use fire peaks in the burning hemisphere's dry
#      season. A sign or index error would sail past a conservation test, and
#      the handoff's own phase control (flipping the NH burning peak Jan -> Jul
#      turned +130 log-units into -40) shows the objective can tell.
#   4. THE LAND-USE DAMPING IS APPLIED. Only 21.6 % of E_LUC is fire; using the
#      raw fire shape would overstate the correction ~4.6x.
# =====================================================================

skip_if_no_cpp <- function() {
  skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) skip("C++ core failed to compile")
}
skip_if_no_seasonality <- function()
  skip_if(is.null(ccx_emission_seasonality()),
          "data/forcing_emission_seasonality.rds absent")

ES_YEARS <- c(1750, 2024)

es_forcing <- function(on) {
  old <- FORC_USE_EMIS_SEASONALITY
  on.exit(assign("FORC_USE_EMIS_SEASONALITY", old, envir = globalenv()))
  assign("FORC_USE_EMIS_SEASONALITY", on, envir = globalenv())
  ccx_build_forcing("historical", ES_YEARS, prod_c14 = 1)
}

test_that("ccx_seasonalise conserves every annual mean exactly", {
  set.seed(11)
  yrs <- 2000:2010
  v <- abs(rnorm(12 * length(yrs), 5, 2))       # a series with real within-year structure
  w <- c(1.6, 1.4, 1.2, 0.9, 0.7, 0.6, 0.6, 0.7, 0.8, 1.0, 1.2, 1.3)
  out <- ccx_seasonalise(v, yrs, w / mean(w))
  yv <- rep(yrs, each = 12)
  expect_equal(as.numeric(tapply(out, yv, mean)),
               as.numeric(tapply(v, yv, mean)), tolerance = 1e-12)
  # ...and it must actually DO something, or conservation is trivially satisfied
  expect_gt(max(abs(out - v)), 0.1)
  # a flat weight is the identity
  expect_equal(ccx_seasonalise(v, yrs, rep(1, 12)), v, tolerance = 1e-12)
  # a year of exact zeros rescales by 1, not 0/0
  z <- v; z[1:12] <- 0
  expect_true(all(is.finite(ccx_seasonalise(z, yrs, w / mean(w)))))
  expect_equal(ccx_seasonalise(z, yrs, w / mean(w))[1:12], rep(0, 12))
})

test_that("seasonality leaves every annual emission total untouched", {
  skip_if_no_cpp(); skip_if_no_seasonality()
  a <- es_forcing(TRUE); b <- es_forcing(FALSE)
  for (nm in list(c("e_foss_NH", "e_foss_SH"), c("e_luc_NH", "e_luc_SH"))) {
    ta <- tapply(a[[nm[1]]] + a[[nm[2]]], a$year, mean)
    tb <- tapply(b[[nm[1]]] + b[[nm[2]]], b$year, mean)
    expect_equal(as.numeric(ta), as.numeric(tb), tolerance = 1e-12)
  }
  # PER HEMISPHERE too -- a weight applied to the wrong hemisphere would
  # conserve the global total while corrupting the gradient.
  for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH"))
    expect_equal(as.numeric(tapply(a[[cc]], a$year, mean)),
                 as.numeric(tapply(b[[cc]], b$year, mean)), tolerance = 1e-12)
  # the cumulative land-use series the converted-land term reads must land in
  # the same place, or the cleared fraction drifts against the flux
  expect_equal(tail(a$cum_luc_NH + a$cum_luc_SH, 1),
               tail(b$cum_luc_NH + b$cum_luc_SH, 1), tolerance = 1e-9)
})

test_that("the switch OFF reproduces the pre-5c forcing exactly", {
  skip_if_no_cpp(); skip_if_no_seasonality()
  b <- es_forcing(FALSE)
  # the incumbent construction, written out rather than referenced, so this
  # test fails if the fallback branch ever silently changes
  e <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
  yrs <- seq(ES_YEARS[1], ES_YEARS[2])
  foss <- ccx_annual_to_monthly(e$year, e$fossil_GtC, yrs)
  expect_equal(b$e_foss_NH, foss * FORC_FOSS_NH_SHARE, tolerance = 1e-12)
})

test_that("seasonality is ON by default and DOES move the monthly series", {
  skip_if_no_cpp(); skip_if_no_seasonality()
  expect_true(FORC_USE_EMIS_SEASONALITY)
  a <- es_forcing(TRUE); b <- es_forcing(FALSE)
  k <- a$year == 2015
  expect_gt(max(abs(a$e_foss_NH[k] - b$e_foss_NH[k])), 1)   # GtC/yr, and it is ~4
})

test_that("the PHASES are right -- the part a conservation test cannot see", {
  skip_if_no_seasonality()
  s <- ccx_emission_seasonality(); w <- s$weights
  # fossil is winter heating, so the two hemispheres must be OPPOSED
  expect_true(which.max(w$fossil_NH) %in% c(12, 1, 2))
  expect_true(which.max(w$fossil_SH) %in% c(6, 7, 8))
  # land-use fire follows the burning hemisphere's dry season
  expect_true(which.max(w$luc_SH) %in% c(8, 9, 10))
  # every weight is a proper mean-1 weight, non-negative
  for (k in names(w)) {
    expect_equal(mean(w[[k]]), 1, tolerance = 1e-12)
    expect_true(all(w[[k]] >= 0))
    expect_length(w[[k]], 12L)
  }
  # SH fire is far more sharply peaked than NH fossil -- if these ever came out
  # comparable, a normalisation has been applied twice
  expect_gt(max(w$luc_SH) - min(w$luc_SH), 3 * (max(w$fossil_NH) - min(w$fossil_NH)))
})

test_that("the land-use weight is DAMPED by f_fire, not applied raw", {
  skip_if_no_cpp(); skip_if_no_seasonality()
  s <- ccx_emission_seasonality()
  # f_fire is a measured ratio, not a setting: GFED DEFO+PEAT / GCB E_LUC
  expect_gt(s$f_fire, 0.1); expect_lt(s$f_fire, 0.4)
  a <- es_forcing(TRUE); b <- es_forcing(FALSE)
  k <- a$year == 2015
  # observed peak-to-peak on the applied SH land-use flux, as a fraction of that
  # year's mean, must match the DAMPED weight -- not the raw one
  mean_luc <- mean(b$e_luc_SH[k])
  obs_pp <- (max(a$e_luc_SH[k]) - min(a$e_luc_SH[k])) / mean_luc
  raw_pp <- max(s$weights$luc_SH) - min(s$weights$luc_SH)
  expect_lt(obs_pp, 0.5 * raw_pp)                      # damping is real
  expect_equal(obs_pp, s$f_fire * raw_pp, tolerance = 0.15)   # and it is f_fire
})
