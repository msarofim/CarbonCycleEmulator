# =====================================================================
# Gate: the matched pulse/baseline experiment behind the app's Pulse Lab.
#
# This is the five-test paired checklist from the climate-modeling skill,
# applied to the coupled runner. It matters more here than usual: the Pulse Lab
# is the one place where a student reads a number ("half of it is still there in
# 2150") straight off a difference between two model runs. If the pairing is
# wrong, the number is wrong and nothing else in the app would show it.
#
# ON THE BENCHMARK NUMBERS BELOW. The Joos et al. (2013) impulse-response values
# quoted in the comments are FROM RECOLLECTION and have not been checked against
# the paper in this repository. They are used only to bound an order of
# magnitude, and the assertions are deliberately loose enough that being wrong
# about the third digit changes nothing. Do not cite them.
# =====================================================================

skip_if_no_cpp <- function() {
  skip_if_not_installed("Rcpp")
  ok <- tryCatch({ ccx_load_cpp(); TRUE }, error = function(e) FALSE)
  if (!ok) skip("C++ core failed to compile")
}
skip_if_no_climate <- function() {
  if (!file.exists(ccx_path("data", CLIMATE_MODULE_FILE)))
    skip("climate module not built (data-raw/build_climate_module.R)")
}

PULSE_YEAR <- 2050
PULSE_SPAN <- c(1750, 2300)

pulse_pair <- function(gtc, bg = "ssp245", pyear = PULSE_YEAR, yrs = PULSE_SPAN) {
  p <- ccx_default_params(); p$gamma_enso <- 0.5
  sp <- ccx_spinup(p)
  y <- seq(yrs[1], yrs[2])
  e <- as.data.frame(readRDS(ccx_path("data", "ssp_emissions.rds")))
  e <- e[e$scenario == bg, ]
  base <- data.frame(
    year = y,
    fossil_GtC = stats::approx(e$year, e$fossil_GtC, xout = y, rule = 2)$y,
    luc_GtC    = stats::approx(e$year, e$luc_GtC,    xout = y, rule = 2)$y)
  pul <- base
  pul$fossil_GtC[pul$year == pyear] <- pul$fossil_GtC[pul$year == pyear] + gtc
  b <- ccx_run_coupled(sp, bg, yrs, bg, emissions = base)$climate
  q <- ccx_run_coupled(sp, bg, yrs, bg, emissions = pul)$climate
  list(year = b$year, d_ppm = q$co2_ppm - b$co2_ppm,
       frac = (q$co2_ppm - b$co2_ppm) / (gtc / ccx_const("GtC_PER_PPM")),
       d_temp = q$gmst - b$gmst)
}

test_that("a zero pulse reproduces the baseline exactly", {
  skip_if_no_cpp(); skip_if_no_climate()
  # The single most important test in the file. If a zero perturbation moves the
  # answer at all, the two arms are not actually paired and every pulse number
  # is contaminated by that difference.
  z <- pulse_pair(0)
  expect_equal(max(abs(z$d_ppm)), 0)
  expect_equal(max(abs(z$d_temp)), 0)
})

test_that("the pulse response flips sign and scales", {
  skip_if_no_cpp(); skip_if_no_climate()
  up <- pulse_pair(100); dn <- pulse_pair(-100); db <- pulse_pair(200)
  i <- which(up$year == 2100)
  expect_gt(up$d_ppm[i], 0)
  expect_lt(dn$d_ppm[i], 0)
  # near-antisymmetric: the residual IS the carbon cycle's nonlinearity, so it
  # must be small but must NOT be zero -- exact antisymmetry would mean the
  # Revelle and fertilisation nonlinearities had been lost somewhere.
  asym <- abs(up$d_ppm[i] + dn$d_ppm[i]) / up$d_ppm[i]
  expect_lt(asym, 0.10)
  expect_gt(asym, 1e-4)
  # doubling the pulse roughly doubles the response, slightly more than double
  # because a larger pulse pushes further up the buffer curve
  expect_gt(db$d_ppm[i] / up$d_ppm[i], 1.95)
  expect_lt(db$d_ppm[i] / up$d_ppm[i], 2.20)
})

test_that("the pulse decays, monotonically, and never fully disappears", {
  skip_if_no_cpp(); skip_if_no_climate()
  r <- pulse_pair(100)
  k <- r$year > PULSE_YEAR
  f <- r$frac[k]
  expect_lt(f[length(f)], f[1])                     # it decays
  expect_gt(min(f), 0.2)                            # but a large share persists
  # no non-monotonic excursions beyond numerical noise
  expect_lt(max(diff(f)), 1e-3)
})

test_that("the airborne fraction depends on the background -- Revelle saturation", {
  skip_if_no_cpp(); skip_if_no_climate()
  # The pedagogical claim the Pulse Lab makes. An identical pulse must persist
  # LONGER on a high-CO2 background, because the ocean's buffer is already
  # stretched. If this ever reversed, the tab would be teaching the opposite.
  lo <- pulse_pair(100, "ssp119")
  # suppressWarnings: SSP5-8.5 to 2300 at these parameters passes 1998 ppm,
  # beyond the 1687 ppm top of FaIR's own SSP range, so the CO2->forcing curve
  # extrapolates and rightly says so. It affects the temperature, not the
  # airborne fraction this test reads, and the warning is the feature working.
  hi <- suppressWarnings(pulse_pair(100, "ssp585"))
  i <- which(lo$year == PULSE_YEAR + 100)
  expect_gt(hi$frac[i], lo$frac[i])
  expect_gt(hi$frac[i] - lo$frac[i], 0.05)
})

test_that("the airborne fraction is in the right ballpark", {
  skip_if_no_cpp(); skip_if_no_climate()
  # Order-of-magnitude only. Recalled Joos et al. (2013) multi-model values for
  # a 100 GtC pulse onto ~389 ppm are roughly 0.59 / 0.47 / 0.41 at 20 / 50 /
  # 100 yr -- NOT verified against the paper, see the file header. SSP1-1.9 is
  # the closest available background. The bounds below are wide on purpose.
  lo <- pulse_pair(100, "ssp119")
  at <- function(h) lo$frac[lo$year == PULSE_YEAR + h]
  expect_gt(at(20), 0.45);  expect_lt(at(20), 0.80)
  expect_gt(at(100), 0.30); expect_lt(at(100), 0.60)
  expect_lt(at(100), at(20))
})

test_that("a pulse warms, and the warming outlives the century", {
  skip_if_no_cpp(); skip_if_no_climate()
  # The coupled runner must propagate the pulse all the way to temperature --
  # this is what a prescribed GMST path could not do, and the reason the climate
  # module exists at all.
  r <- pulse_pair(100)
  i100 <- which(r$year == PULSE_YEAR + 100)
  i250 <- which(r$year == PULSE_YEAR + 250)
  expect_gt(r$d_temp[i100], 0.02)
  expect_gt(r$d_temp[i250], 0)
})
