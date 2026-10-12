# =====================================================================
# THE PD100 RUNNER (R/joos_irf.R ccx_pd100), at the CANONICAL -- 2026-10-12.
#
# RULED (Marcus 2026-10-12): "free everywhere" -- card 5a, gate L / card 5b, the scorecard,
# tl_land_share and diag_joos_irf.R run Joos's PD100 with the climate FREE; gate L releases at
# JOOS_PULSE_YR like card 5a. And "Fix both in the builder": the HELD background holds the SST
# columns with GMST, and T_deep is carried across the seams.
#
# ⛔ WHY THIS FILE. test-pulse.R runs its OWN held table at ccx_default_params(), where the
# stratification feedback is OFF -- so it never exercised the protocol card 5 uses, and both held
# defects passed it (the SST one because it calls ccx_hold_climate() itself). This runs the
# builder and the runner at the fitted mode, where the feedback is ON.
#
# Thresholds: identities are exact or at float tolerance; the climate claim is an ORDERING between
# two measured runs (free outlasts held because the pulse warms), never a typed IRF value.
# =====================================================================
skip_if_no_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))

PD_TEST_HORIZON <- 100                                   # the IRF read (yr after the release)
PD_TEST_END     <- JOOS_PULSE_YR + PD_TEST_HORIZON + DG_L_EXTRA_YR   # = gate L's window at that horizon
.v    <- dg_vector(CCX_MODE_CANONICAL)
.spin <- dg_spinup(.v)
.pf   <- ccx_pulse_forcings(.spin, c(JOOS_REF_YEAR, PD_TEST_END), .v$bomb_total, .v$luc_scale)
.ref  <- ccx_pulse_ref_state(.spin, .pf$F_hist)
.at   <- function(o, h) o$irf[which.min(abs(o$t - h))]

test_that("the HELD background holds the SST columns with GMST (fix 1)", {
  # ccx_pulse_forcings() held GMST by hand and left the observed SST running, which the ocean
  # reads (sst_obs = 1): NH 0.72 K in 2010 -> 1.29 K in 2024 inside a 'held' climate
  for (cc in c("gmst", "sst_anom_NH", "sst_anom_SH", "enso"))
    expect_identical(length(unique(.pf$F_fwd[[cc]])), 1L, info = cc)
})

test_that("the reference state carries T_deep out of the history (fix 2)", {
  skip_if(!ccx_mix_on(.spin$params), "the canonical carries no stratification feedback")
  expect_identical(.ref$tdeep0, ccx_mix_tdeep_after(.pf$F_hist$gmst, .pf$F_hist$t, .spin$params))
  expect_gt(.ref$tdeep0, 0)          # restarting it at 0 is what the defect did
})

test_that("the FREE background: the module's GMST, SST following it by the ratio rule", {
  Fb <- ccx_pulse_background(.ref, .pf$F_fwd, "free")
  expect_identical(attr(Fb, "pd_climate"), "free")
  g <- Fb$gmst
  expect_gt(g[length(g)], g[1])      # committed warming under held forcing
  h <- .ref$pd_hist; k <- h$year > max(h$year) - CCX_SST_SPLICE_YR
  expect_equal(Fb$sst_anom_NH - mean(h$sst_NH[k]), CCX_SST_RATIO_NH * (g - mean(h$gmst[k])), tolerance = 1e-12)
  expect_equal(Fb$sst_anom_SH - mean(h$sst_SH[k]), CCX_SST_RATIO_SH * (g - mean(h$gmst[k])), tolerance = 1e-12)
  # and the HELD stamp leaves the held table as it is
  expect_identical(attr(ccx_pulse_background(.ref, .pf$F_fwd, "held"), "pd_climate"), "held")
})

.free <- ccx_pd100(.spin, PD_TEST_END, .v$bomb_total, .v$luc_scale, climate = "free")
.held <- ccx_pd100(.spin, PD_TEST_END, .v$bomb_total, .v$luc_scale, climate = "held")

test_that("the FREE PD100 converges, warms, releases the whole pulse, and outlasts the HELD one", {
  expect_identical(.free$climate, "free"); expect_identical(.held$climate, "held")
  expect_true(.free$converged)
  expect_gt(.free$iter, 1L)                       # the pulse's warming was actually fed back
  expect_true(all(.free$dT > 0))
  expect_lt(abs(.free$irf[1] - 1), JOOS_IRF0_TOL) # the release check, on both
  expect_lt(abs(.held$irf[1] - 1), JOOS_IRF0_TOL)
  expect_gt(.at(.free, PD_TEST_HORIZON), .at(.held, PD_TEST_HORIZON))
})

test_that("gate L (card 5b) is card 5a's protocol: released at JOOS_PULSE_YR, same climate", {
  g <- dg_gateL_partition(.v, horizon = PD_TEST_HORIZON)      # default climate: free
  expect_identical(g$climate, CCX_PD_CLIMATE_DEFAULT)
  # the air share IS the IRF of the same runner, up to the two GtC-per-ppm constants
  expect_equal(g$share_at(PD_TEST_HORIZON)[["air"]],
               100 * .at(.free, PD_TEST_HORIZON) * ccx_const("GtC_PER_PPM") / JOOS_PPM_PER, tolerance = 1e-10)
  expect_equal(g$closure, 1, tolerance = 1e-4)
})
