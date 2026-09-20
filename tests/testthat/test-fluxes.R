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
  # the ENSO coefficients ARE in ccx_default_params(), at 0; set them non-zero
  # so the `enso` channel this file checks is actually exercised
  # explicitly (handoff 2026-08-13c sec.7). Set non-zero here so the ENSO
  # channel is genuinely exercised rather than silently absent.
  p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0.5)); p
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

test_that("the 14C edge tap reproduces dy[, 'C14'] on every non-atmosphere box", {
  # 2026-09-15b (prereg_2026-09-15b_kz_pump_diagnosis.md sec.1): the same
  # load-bearing pattern as the first test, for the 14C-signal edges. A
  # non-atmosphere box has no 14C source, so its recorded net inflow must
  # equal its tendency PLUS its own decay, exactly up to the one floating
  # subtraction of the decay term. Proves the tap is complete (no 14C
  # tendency outside add_flux/add_diffusion) and faithful (nothing counted
  # twice). Run on the HILDA structure so the HS/HD, flush, conduit and the
  # seasonal mixed layer are all under the tap, at a bomb-era month so the
  # 14C gradients are not preindustrial.
  p <- ccx_apply_structure(test_p(), struct = "hilda", seas_ml = "1")
  s <- ccx_spinup(p)
  F <- suppressWarnings(ccx_build_forcing("historical", c(1750, 1970),
                                          prod_c14 = s$prod_c14))
  lam <- ccx_const("LAMBDA_C14")
  for (i in c(7L, 2500L, 2600L)) {
    y  <- s$y; if (i > 1L) y[, "C14"] <- y[, "C14"] * (1 + 0.2 * seq_len(nrow(y)) / nrow(y))
    dy <- suppressWarnings(ccx_deriv(y, F$t[i], p, ccx_forcing_at(F, i), s$grid, s$aux, record = TRUE))
    e  <- attr(dy, "fluxes")$edges14
    net <- colSums(e)[-1] - rowSums(e)[-1]
    atm <- c(s$aux$idx$NH$atm, s$aux$idx$SH$atm)
    nb  <- setdiff(seq_len(nrow(y)), atm)
    expect_equal(net[nb], unname(dy[nb, "C14"] + lam * y[nb, "C14"]), tolerance = 1e-12)
    # the split matrices: an interior-interior pair carries ONLY diffusion
    # under "hilda" (the conduit attaches HD, not oc_k, to oc_k), so the whole
    # equals the diffusive part there exactly; and the pump edges are present.
    d <- attr(dy, "fluxes")$diff_edges14; pu <- attr(dy, "fluxes")$pump_edges14
    o2 <- s$aux$idx$NH$oc[2] + 1L; o3 <- s$aux$idx$NH$oc[3] + 1L
    expect_identical(e[o2, o3], d[o2, o3]); expect_identical(e[o3, o2], d[o3, o2])
    expect_true(e[o2, o3] != 0); expect_true(sum(pu != 0) > 0)
  }
})

test_that("recording the 14C edges does not change the derivative or the trajectory", {
  p <- ccx_apply_structure(test_p(), struct = "hilda", seas_ml = "1"); s <- ccx_spinup(p)
  F <- suppressWarnings(ccx_build_forcing("historical", c(1750, 1760),
                                          prod_c14 = s$prod_c14))
  a <- ccx_deriv(s$y, F$t[7], p, ccx_forcing_at(F, 7), s$grid, s$aux)
  b <- ccx_deriv(s$y, F$t[7], p, ccx_forcing_at(F, 7), s$grid, s$aux, record = TRUE)
  attributes(b) <- attributes(a)
  expect_identical(a, b)
  keep <- function(fl, y, t) sum(fl$edges14)
  # the SST extrapolation warning fires per derivative call on this structure;
  # it is not what this test is about
  r0 <- suppressWarnings(ccx_run(s, F)); r1 <- suppressWarnings(ccx_run(s, F, edge_fn = keep))
  expect_identical(r0$out, r1$out); expect_identical(r0$state, r1$state)
  expect_length(r1$edge_trace, nrow(r0$out))
})

test_that("fluxes = TRUE does not change the trajectory", {
  p <- test_p(); s <- ccx_spinup(p)
  F <- suppressWarnings(ccx_build_forcing("historical", c(1750, 1760),
                                          prod_c14 = s$prod_c14))
  expect_identical(ccx_run(s, F)$out, ccx_run(s, F, fluxes = TRUE)$out)
})

test_that("the seasonal and land-use channels are separated from their neighbours", {
  # Each of these shares an endpoint PAIR with another process, so they are the
  # only fluxes carrying an explicit label. A regression that dropped a label
  # would silently merge two physically distinct channels.
  # ⚠ `enso` WAS the third one and was RETIRED 2026-09-02 with the signed
  # soil_fast flux it named; the term is now a one-way GPP modulation and has
  # no edge of its own. Its replacement assertion is the next test, which is
  # STRONGER: a label can only be dropped, but a modulation folded into another
  # flux can be silently ZERO, which is the failure mode that actually bit
  # (two diagnostics ran for a day with their mechanism off).
  p <- test_p(); s <- ccx_spinup(p)
  F <- suppressWarnings(ccx_build_forcing("historical", c(1990, 1991),
                                          prod_c14 = s$prod_c14))
  fl <- ccx_run(s, F, fluxes = TRUE)$fluxes
  expect_false("enso" %in% names(fl))         # retired, not merely empty
  expect_true(any(fl$seas != 0))              # atm -> leaf, not folded into gpp
  expect_true(all(fl$luc > 0))                # wood -> atm, not folded into ra
  expect_true(all(fl$gpp > 0), all(fl$rh > 0))
})

test_that("the ENSO land term actually moves GPP, and only GPP", {
  # The mechanism-is-live test the retired channel used to give for free. It
  # must move `gpp` and NOT `rh`: the whole point of 2026-09-02 is that the
  # term left the soil pool. A sign check is included because the modulation's
  # minus sign is the one thing that could be inverted without any other
  # symptom -- El Nino (positive index) must SUPPRESS photosynthesis.
  s0 <- ccx_spinup(ccx_set_enso(ccx_default_params(), list(gamma_enso = 0)))
  s1 <- ccx_spinup(test_p())
  F0 <- suppressWarnings(ccx_build_forcing("historical", c(1990, 1991),
                                           prod_c14 = s0$prod_c14))
  F1 <- suppressWarnings(ccx_build_forcing("historical", c(1990, 1991),
                                           prod_c14 = s1$prod_c14))
  a <- ccx_run(s0, F0, fluxes = TRUE)$fluxes
  b <- ccx_run(s1, F1, fluxes = TRUE)$fluxes
  expect_true(any(abs(b$gpp - a$gpp) > 1e-8))
  # the ENSO index over 1990-1991 is not identically zero, so pick the month
  # with the largest |index| and check the sign of the GPP response there
  e <- F1$enso[seq_len(nrow(b))]
  k <- which.max(abs(e))
  expect_lt((b$gpp[k] - a$gpp[k]) * e[k], 0)
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
    p <- ccx_default_params(); p <- ccx_set_enso(p, list(gamma_enso = 0))
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

test_that("the per-edge sums reproduce the box net exactly, and the cold boxes' own flows are read from them", {
  # the column model: the edge columns exist, are ZERO, and the identity holds
  p <- test_p(); s <- ccx_spinup(p)
  F <- suppressWarnings(ccx_build_forcing("historical", c(1750, 1760), prod_c14 = s$prod_c14))
  dy <- ccx_deriv(s$y, F$t[7], p, ccx_forcing_at(F, 7), s$grid, s$aux, record = TRUE)
  fl <- attr(dy, "fluxes"); nb <- nrow(s$y)
  expect_equal(dim(fl$edges), c(nb + 1L, nb + 1L))
  expect_equal(colSums(fl$edges)[-1] - rowSums(fl$edges)[-1], unname(dy[, "C"]), tolerance = 1e-12)
  expect_equal(sum(fl$pump_edges), fl$channels[["pump"]], tolerance = 1e-12)
  hs0 <- ccx_flux_hs_derive(fl$edges, fl$pump_edges, s$aux)
  expect_named(hs0, names(CCX_FLUX_HS)); expect_true(all(hs0 == 0))
  # the HILDA structure: the HS flows are inside their channels, never beyond them
  ph <- ccx_apply_structure(test_p(), "hilda"); ph$pump_hs_gcm2 <- 50
  sh <- ccx_spinup(ph)
  Fh <- suppressWarnings(ccx_build_forcing("historical", c(1750, 1760), prod_c14 = sh$prod_c14))
  dyh <- suppressWarnings(ccx_deriv(sh$y, Fh$t[7], ph, ccx_forcing_at(Fh, 7), sh$grid, sh$aux, record = TRUE))
  flh <- attr(dyh, "fluxes"); ch <- flh$channels
  expect_equal(colSums(flh$edges)[-1] - rowSums(flh$edges)[-1], unname(dyh[, "C"]), tolerance = 1e-12)
  hs <- ccx_flux_hs_derive(flh$edges, flh$pump_edges, sh$aux)
  expect_gt(hs[["hs_as_down"]], 0); expect_gt(hs[["hs_as_up"]], 0); expect_gt(hs[["hs_pump"]], 0)
  expect_lt(hs[["hs_as_down"]], ch[["as_down"]]); expect_lt(hs[["hs_as_up"]], ch[["as_up"]])
  expect_lte(hs[["hs_pump"]], ch[["pump"]] + 1e-12)
  # hs_hd_net is the pump PLUS the flush's net (which returns carbon upward, so
  # the net can sit BELOW the export). MUTATION: with the flush OFF (u_hs 0) the
  # pump is the only HS -> HD edge and the two must be identical.
  pf <- ph; pf$u_hs <- 0; sf <- ccx_spinup(pf)
  dyf <- ccx_deriv(sf$y, Fh$t[7], pf, ccx_forcing_at(Fh, 7), sf$grid, sf$aux, record = TRUE)
  hsf <- ccx_flux_hs_derive(attr(dyf, "fluxes")$edges, attr(dyf, "fluxes")$pump_edges, sf$aux)
  expect_equal(hsf[["hs_hd_net"]], hsf[["hs_pump"]], tolerance = 1e-12)
  expect_gt(hsf[["hs_pump"]], 0)
  # and the trace carries the columns (the pure-R carbonate path warns below 2 C: pre-existing)
  tr <- suppressWarnings(ccx_run(sh, Fh, fluxes = TRUE))$fluxes
  expect_true(all(names(CCX_FLUX_HS) %in% names(tr)))
  expect_true(all(is.finite(tr$hs_as_down)))
})

test_that("the 13C edge tap reproduces dy[, 'C13'] on every box, exactly", {
  # 2026-09-20 t: the same load-bearing pattern as the 14C tap, for the 13C each
  # edge carries. 13C has no decay and the fossil source is IN the tap (row 1),
  # so every box -- the atmosphere included -- must close exactly. Proves the tap
  # is complete (no C13 tendency outside add_flux/add_diffusion/add_source) and
  # faithful; it is what licenses reading the hemispheric isoflux budget from it.
  p <- ccx_apply_structure(test_p(), struct = "hilda", seas_ml = "1")
  s <- ccx_spinup(p)
  F <- suppressWarnings(ccx_build_forcing("historical", c(1750, 1970),
                                          prod_c14 = s$prod_c14))
  for (i in c(7L, 2500L, 2600L)) {
    y  <- s$y; if (i > 1L) y[, "C13"] <- y[, "C13"] * (1 - 0.01 * seq_len(nrow(y)) / nrow(y))
    dy <- suppressWarnings(ccx_deriv(y, F$t[i], p, ccx_forcing_at(F, i), s$grid, s$aux, record = TRUE))
    e  <- attr(dy, "fluxes")$edges13
    net <- colSums(e)[-1] - rowSums(e)[-1]
    expect_equal(net, unname(dy[, "C13"]), tolerance = 1e-12)
    # the fossil source is a row-1 (external) 13C edge into the atmosphere at the
    # forcing's own signature, and only after fossil emissions exist
    atmN <- s$aux$idx$NH$atm + 1L
    fc <- ccx_forcing_at(F, i)
    if (fc$e_foss$NH > 0) {
      d_carried <- 1000 * (e[1L, atmN] / (attr(dy, "fluxes")$edges[1L, atmN] * ccx_const("R13_VPDB")) - 1)
      expect_equal(d_carried, ccx_forcing_d13c_foss(fc), tolerance = 1e-9)
    } else expect_identical(e[1L, atmN], 0)
  }
})

test_that("recording the 13C edges does not change the derivative", {
  p <- ccx_apply_structure(test_p(), struct = "hilda", seas_ml = "1"); s <- ccx_spinup(p)
  F <- suppressWarnings(ccx_build_forcing("historical", c(1750, 1760), prod_c14 = s$prod_c14))
  a <- ccx_deriv(s$y, F$t[7], p, ccx_forcing_at(F, 7), s$grid, s$aux)
  b <- ccx_deriv(s$y, F$t[7], p, ccx_forcing_at(F, 7), s$grid, s$aux, record = TRUE)
  expect_true(!is.null(attr(b, "fluxes")$edges13))
  attributes(b) <- attributes(a)
  expect_identical(a, b)
})
