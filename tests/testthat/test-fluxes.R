# =====================================================================
# test-fluxes.R -- the flux trace (R/fluxes.R).
#
# THE LOAD-BEARING TEST IS THE FIRST ONE. The trace is only worth anything if
# the fluxes it reports are the fluxes the model integrates, rather than a
# parallel derivation that can drift. `boxnet` is accumulated by the same tap
# inside add_flux/add_source/add_diffusion, so asserting boxnet == dy[, "C"]
# EXACTLY proves both that the tap is complete (nothing unrecorded) and that it
# is faithful (nothing double-counted). It is simultaneously a free extra
# conservation check on ccx_deriv itself.
# =====================================================================

test_p <- function() {
  # gamma_enso is NOT in ccx_default_params() and ccx_deriv requires it
  # explicitly (handoff 2026-08-13c sec.7). Set non-zero here so the ENSO
  # channel is genuinely exercised rather than silently absent.
  p <- ccx_default_params(); p$gamma_enso <- 0.5; p
}

test_that("recorded fluxes reproduce dy[, 'C'] exactly", {
  p <- test_p(); s <- ccx_spinup(p)
  F <- suppressWarnings(ccx_build_forcing("historical", c(1750, 1760),
                                          prod_c14 = s$prod_c14))
  for (i in c(1L, 7L, 60L)) {
    dy <- ccx_deriv(s$y, F$t[i], p, ccx_forcing_at(F, i), s$grid, s$aux,
                    record = TRUE)
    expect_equal(attr(dy, "fluxes")$boxnet, unname(dy[, "C"]), tolerance = 0)
  }
})

test_that("recording does not change the derivative", {
  p <- test_p(); s <- ccx_spinup(p)
  F <- suppressWarnings(ccx_build_forcing("historical", c(1750, 1760),
                                          prod_c14 = s$prod_c14))
  a <- ccx_deriv(s$y, F$t[7], p, ccx_forcing_at(F, 7), s$grid, s$aux)
  b <- ccx_deriv(s$y, F$t[7], p, ccx_forcing_at(F, 7), s$grid, s$aux,
                 record = TRUE)
  attributes(b) <- attributes(a)
  expect_identical(a, b)
})

test_that("fluxes = TRUE does not change the trajectory", {
  p <- test_p(); s <- ccx_spinup(p)
  F <- suppressWarnings(ccx_build_forcing("historical", c(1750, 1760),
                                          prod_c14 = s$prod_c14))
  expect_identical(ccx_run(s, F)$out, ccx_run(s, F, fluxes = TRUE)$out)
})

test_that("the ENSO, seasonal and land-use channels are separated from their neighbours", {
  # Each of these three shares an endpoint PAIR with another process, so they
  # are the only fluxes carrying an explicit label. A regression that dropped a
  # label would silently merge two physically distinct channels.
  p <- test_p(); s <- ccx_spinup(p)
  F <- suppressWarnings(ccx_build_forcing("historical", c(1990, 1991),
                                          prod_c14 = s$prod_c14))
  fl <- ccx_run(s, F, fluxes = TRUE)$fluxes
  expect_true(any(fl$enso != 0))              # soil -> atm, not folded into rh
  expect_true(any(fl$seas != 0))              # atm -> leaf, not folded into gpp
  expect_true(all(fl$luc > 0))                # wood -> atm, not folded into ra
  expect_true(all(fl$gpp > 0), all(fl$rh > 0))
})

test_that("turnover time from the flux trace matches an independent label pulse", {
  # THE CROSS-VALIDATION. tau_turn = M_atm / (gross flux out) is computed from
  # the flux trace. The SAME quantity is the initial decay rate of a pure 14C
  # LABEL perturbation, which uses no flux output at all -- it is read off the
  # integrated trajectory. The two routes must agree.
  #
  # SEASONALITY IS SWITCHED OFF FOR THIS TEST, and that is the point of the
  # third expectation below rather than a convenience: seasonal NEP is a real
  # atm->leaf flux but integrates to zero annually and is signed, so it is
  # EXCLUDED from atm_out. Launch a label pulse in January with seasonality on
  # and the first month's decay is contaminated by it (measured: 4.32 yr against
  # a true 4.69). Excluding it is correct for the annual-mean turnover time and
  # wrong for a one-month finite difference; the test pins both facts.
  #
  # THE SEASONAL SST IS HELD OFF IN *BOTH* ARMS (2026-08-27), and that is what
  # makes the third expectation an IDENTITY rather than a margin. `seas_drivers`
  # is a MASTER switch: setting it to 0 disables the seasonal SST cycle as well
  # as the seasonal NEP flux. So `mk(TRUE)` vs `mk(FALSE)` used to toggle TWO
  # seasonal paths at once, and the ocean one legitimately moves `as_down` --
  # which IS in atm_out. That is not a leak of `seas` into the turnover time; it
  # is the test failing to control what it meant to control.
  #
  # MEASURED, before and after: with the SST cycle left on, seasonality moved
  # tau_turn[1] by 8.05e-3 (gpp identical to 0.000000, m_atm identical, and the
  # whole difference in as_down: 65.340510 -> 65.556037). With it held off in
  # both arms the difference is EXACTLY ZERO. The tolerance below was therefore
  # NOT loosened -- the control was completed, which is the stronger repair.
  #
  # AND THE DECAY HAS A DATE. At `25dce56` this difference was 0.000000; the
  # seasonal SST landed at `6fadb34` (2026-08-18) and made it 2.15e-3, inside
  # the tolerance and so invisible; `7708404` (SST lag 2.5 -> 1.32) took it to
  # 8.05e-3 and the test went red. The AMPLITUDES never moved (2.0 / 1.2
  # throughout) -- it was the PHASE, because tau_turn[1] samples January alone.
  # `ccx_hold_climate()` does not suppress this: the cycle is generated from the
  # `sst_seas_amp_*` PARAMETERS, not read from a forcing column.
  mk <- function(seas_off) {
    p <- ccx_default_params(); p$gamma_enso <- 0
    p$sst_seas_amp_NH <- 0; p$sst_seas_amp_SH <- 0   # OFF IN BOTH ARMS -- see above
    if (seas_off) { p$seas_amp_NH <- 0; p$seas_amp_SH <- 0; p$seas_drivers <- 0 }  # BOTH paths
    s <- ccx_spinup(p)
    F <- suppressWarnings(ccx_build_forcing("historical", c(1750, 1760),
                                            prod_c14 = s$prod_c14,
                                            bomb_total_kmol = 0))
    for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "enso",
                 "c14_bomb", "c14_nuclear")) F[[cc]] <- 0
    F <- ccx_hold_climate(F, value = 0)   # gmst AND observed-SST columns
    ctl <- ccx_run(s, F)$out
    sl <- s
    for (k in c(s$aux$idx$NH$atm, s$aux$idx$SH$atm))
      sl$y[k, "C14"] <- sl$y[k, "C14"] * 1.1
    lp <- ccx_run(sl, F)$out
    lab <- ((lp$d14c_NH - ctl$d14c_NH) + (lp$d14c_SH - ctl$d14c_SH)) / 2
    list(tau_label = -(1 / 12) / log(lab[2] / lab[1]),
         tau_flux  = ccx_run(s, F, fluxes = TRUE)$fluxes$tau_turn[1])
  }
  off <- mk(TRUE)
  expect_equal(off$tau_label, off$tau_flux, tolerance = 0.01)  # 4.700 vs 4.692
  expect_gt(off$tau_flux, 3); expect_lt(off$tau_flux, 7)       # the "5-year" number
  on <- mk(FALSE)
  expect_equal(on$tau_flux, off$tau_flux, tolerance = 1e-3)    # seas excluded -- EXACT
  # THE 0.2 yr MAGNITUDE GATE IS WITHDRAWN (Marcus, 2026-08-27): a threshold has
  # to come from an observation or a physical law, and this one could come from
  # neither.
  #
  # WHY NOT AN OBSERVATION. The contaminating quantity is the January seasonal
  # flux across the atmosphere's boundary, and the observed seasonal CO2 swing IS
  # its time integral -- so it looks anchorable. It is not anchorable HERE,
  # because this test runs at ccx_default_params() with the climate held, and in
  # that configuration the model's seasonal cycle does not resemble the observed
  # one: NH peak-to-peak 1.66 ppm against MLO's 5.72, and the SH January tendency
  # is +2.03 ppm/yr against SPO's -3.40 -- an INVERTED SIGN. (At the canonical
  # mode with full forcing it matches well: NH 6.36 vs 5.72 and +19.14 vs +16.75,
  # SH 1.09 vs 1.08 and -3.37 vs -3.40. The mismatch is this harness, not the
  # model.) A threshold cannot be derived from data the configuration does not
  # reproduce.
  #
  # WHY NOT A PHYSICAL LAW. The obvious law is that seasonal NEP is zero-mean, so
  # a label estimate should be contaminated over ONE month and CLOSE over TWELVE.
  # Measured, it does not close: the 12-month contamination is 0.2307 yr, LARGER
  # than the 1-month 0.1805. Over a full cycle the label is not a passive tracer
  # -- it is rectified into and out of the leaf pool -- so the zero-mean law does
  # not transfer to the label. Mass balance on the atmosphere does not close it
  # either: M/(atm_out + |seas|) predicts a 0.489 yr shortening against 0.1805
  # measured, because the label responds to GROSS one-way exchange, not to net NEP.
  #
  # WHAT THE OLD NUMBER WAS. 0.2 was set 2026-08-13 against a measured 0.37, and
  # `f85ef7b` (2026-08-20) took the shortening 0.7079 -> 0.1805 in ONE commit by
  # SHIPPING THE MEASURED NEP amplitude factors, seas_npp_amp 1 -> 0.4969/0.5027
  # (seas[1] halved, -29.430 -> -14.585). The threshold was calibrated against an
  # amplitude since measured to be ~2x too large. It was tracking a driver, which
  # is exactly what a gate must not do.
  #
  # WHAT IS ASSERTED INSTEAD carries NO threshold: turning seasonality on must
  # make the one-month label estimate a WORSE estimator of tau_turn than it is
  # with seasonality off. That is the ordering the physical claim implies -- a
  # zero-mean flux is excluded from the annual-mean turnover time but is present
  # in any one-month window -- and it is a comparison between two measured
  # quantities with no number chosen by anyone.
  # MEASURED 2026-08-27: 0.1727 with seasonality on against 0.0078 with it off.
  expect_gt(abs(on$tau_label  - off$tau_flux),
            abs(off$tau_label - off$tau_flux))
})

test_that("gross fluxes dwarf the net, which is the point of the trace", {
  p <- test_p(); s <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", c(2015, 2024), prod_c14 = s$prod_c14)
  a <- ccx_flux_annual(ccx_run(s, F, fluxes = TRUE)$fluxes)
  expect_gt(mean(a$gpp), 50)                       # ~60-70 GtC/yr
  expect_gt(mean(a$as_down), 50)                   # ~90 GtC/yr each way
  expect_gt(mean(a$as_down), 20 * mean(a$ocean_net))
  expect_lt(abs(mean(a$ocean_net)), 10)            # a few GtC/yr net
  expect_equal(mean(a$ocean_net), mean(a$as_down) - mean(a$as_up), tolerance = 1e-10)
})

test_that("an unclassified flux fails loudly rather than being absorbed", {
  # The classifier is keyed on reservoir type, so a future flux between a new
  # pair is captured automatically -- but a genuinely unknown pair must error,
  # not land in a neighbouring channel.
  cls <- c("atm", "veg", "mystery")
  expect_null(ccx_flux_channel(2L, 3L, NULL, cls, 1L))
})
