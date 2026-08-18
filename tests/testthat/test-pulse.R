# =====================================================================
# Gate: the matched pulse/baseline experiment behind the app's Pulse Lab.
#
# This is the five-test paired checklist from the climate-modeling skill,
# applied to the coupled runner. It matters more here than usual: the Pulse Lab
# is the one place where a student reads a number ("half of it is still there in
# 2150") straight off a difference between two model runs. If the pairing is
# wrong, the number is wrong and nothing else in the app would show it.
#
# ON THE BENCHMARK NUMBERS BELOW. The Joos et al. (2013) values are no longer
# from recollection: the Table 5 IRF fit and the Table 4 integrated ranges are
# transcribed in R/joos_irf.R and are what the airborne-fraction test scores
# against, at Joos's own PD100 protocol. Any OTHER Joos figure appearing in a
# comment in this file is still unverified -- check R/joos_irf.R before citing
# one, and if it is not there, it has not been checked.
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

# THE JOOS TOLERANCE, as a fraction of the published multi-model mean.
#
# RE-PROTOCOLED 2026-08-18 (Marcus). The bar this replaced quoted Joos's PD100
# numbers (0.59 / 0.47 / 0.41) but MEASURED on SSP1-1.9, a declining background
# -- so it compared a model to a benchmark computed under different conditions,
# and af(100) = 0.213 was failing a bar it was never being asked to meet. The
# fix is to run Joos's protocol, not to loosen Joos's number: this test now uses
# PD100 (100 GtC onto a background HELD at ~389 ppm by diagnosed compatible
# emissions), which is the protocol Table 5 is for.
#
# WHERE THE TOLERANCE COMES FROM, measured 2026-08-18 by calibration/
# diag_joos_irf.R part 2 and reproduced by this test:
#   horizon    model    Joos T5    model/Joos
#      20 yr   0.520     0.596        0.87
#      50 yr   0.378     0.487        0.78
#     100 yr   0.292     0.409        0.71
# The model is on the LOW-airborne-fraction side at every horizon, which is a
# known and accepted property, not a defect -- on the time-INTEGRATED IRF it is
# 12.7 / 15.5 / 20.0 % low and inside all three of Joos's 5-95 % bands.
#
# THAT INTEGRATED CHECK IS *DESIGN.md* GATE 12, AND IT HAS NO TEST. Its only
# implementation is calibration/diag_joos_irf.R part 3, a diagnostic nobody runs
# -- which is how its recorded status went stale across two beta moves once
# already. The test below scores the POINT IRF and does NOT cover it: passing
# here is not gate 12 passing. Wiring gate 12 into this file is the obvious
# follow-up and is deliberately not bundled into the repair that added this.
#
# THE TOLERANCE IS DERIVED AT THE ADOPTED MODE, NOT AT THESE DEFAULTS, and the
# distinction is the whole reason this constant is 0.40 and not 0.35. Measured
# 2026-08-18 by mutation test, worst |rel| gap over the three horizons:
#   package defaults (what this test runs) 0.287
#   ARM D mode                             0.297
#   ARM N mode -- ADOPTED, the shipping configuration      0.325
# A tolerance derived from the defaults' 0.287 lands at 0.35 and leaves the
# ADOPTED model 0.025 from firing: that is a flaky gate, not a strict one, and
# it would go red on ordinary re-fitting rather than on a real regression.
# 0.40 is derived from the 0.325 that ships, with headroom for the same
# parameter movement the arms already show between them.
#
# WHY IT CANNOT BE MUCH TIGHTER THAN THAT, stated so nobody "improves" it: the
# point IRF is remarkably insensitive to the ocean parameters. Quartering k_w
# or h_ml moves the worst gap by ~0.03. The one parameter it IS sensitive to is
# kz -- and the calibration pins kz at the TOP of its bracket, which is the
# direction that makes the Joos agreement WORSE (see the scan in the handoff).
# So this gate catches gross breakage and a kz-scale structural change; it does
# NOT certify agreement with Joos, and must not be quoted as if it did.
#
# IF THIS EVER TIGHTENS, tighten it because the model improved -- re-derive from
# diag_joos_irf.R part 2 AT THE ADOPTED MODE, never from wherever code lands.
JOOS_POINT_TOL <- 0.40

# The PD100 background: historical spin-up to JOOS_REF_YEAR, then emissions
# diagnosed to hold CO2 constant. This is diag_joos_irf.R's construction, using
# the same R/joos_irf.R helpers, so the test and the diagnostic cannot drift.
pd100_irf <- function() {
  spin <- ccx_spinup(ccx_default_params())
  F_hist <- ccx_build_forcing("historical", c(1750, JOOS_REF_YEAR),
                              prod_c14 = spin$prod_c14)
  sp_ref <- spin
  sp_ref$y <- ccx_run_fast(spin, F_hist)$state
  # Joos releases the pulse 5 yr after the reference year, onto an already
  # settled background, so the run must cover the shift plus the last horizon.
  span <- (JOOS_PULSE_YR - JOOS_REF_YEAR) + max(JOOS_TH) + 10
  F_fwd <- suppressWarnings(
    ccx_build_forcing("historical", c(JOOS_REF_YEAR, JOOS_REF_YEAR + span),
                      prod_c14 = spin$prod_c14, bomb_total_kmol = 0))
  for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "enso",
               "c14_bomb", "c14_nuclear")) F_fwd[[cc]] <- 0
  F_fwd$gmst <- F_fwd$gmst[1]        # climate held at the reference year
  F_hold <- ccx_hold_forcing(sp_ref, F_fwd)
  o <- ccx_irf(sp_ref, F_hold)
  o$t <- o$t - (JOOS_PULSE_YR - JOOS_REF_YEAR)
  list(t = o$t, irf = o$irf, dev = attr(F_hold, "dev"),
       target = attr(F_hold, "target"))
}

test_that("the airborne fraction matches Joos et al. (2013) at Joos's own protocol", {
  skip_if_no_cpp()
  o <- pd100_irf()

  # THE PROTOCOL'S OWN PRECONDITION. Every number below is meaningless if the
  # background is not actually held, so gate it before reading the IRF. The
  # diagnosed emissions hold ~388 ppm to ~1.1 ppm, i.e. 0.3 %.
  expect_lt(o$dev / o$target, 0.01)
  expect_gt(o$target, 370); expect_lt(o$target, 400)   # Joos's PD100 is 389 ppm

  at <- function(h) o$irf[which.min(abs(o$t - h))]
  for (h in JOOS_TH) {
    ref <- joos_irf(h)
    expect_lt(abs(at(h) - ref) / ref, JOOS_POINT_TOL,
              label = sprintf("IRF@%d yr = %.3f vs Joos %.3f", h, at(h), ref))
  }
  # ... and it must decay, which no tolerance band would catch on its own.
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
