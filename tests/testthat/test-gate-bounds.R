# =====================================================================
# test-gate-bounds.R -- MUTATION TESTS for the DESIGN gate bounds.
#
# WHY THIS FILE EXISTS. On 2026-09-02 the gate ledger found that gates 4 and 5
# printed tables and no verdict, so neither could fail, and that gate 7 judged a
# fitted stream three times more strictly than the objective that fitted it.
# Marcus ruled that all three get proper bounds. A BOUND THAT HAS NEVER BEEN
# BROKEN IS NOT A BOUND -- "a gate that passes is not a gate that works"
# ([[mutation_test_gates]]) -- so every one of them is exercised here in BOTH
# directions: it must FAIL when the thing it guards is broken, and PASS when it
# is not. A gate that can only ever fail is as uninformative as one that can only
# ever pass, and gates 4 and 5 both currently FAIL at every shipped arm, which is
# exactly the situation where the pass direction has to be demonstrated.
#
# ⚠ THESE MUTATE THE KERNEL'S OUTPUT, NOT THE MODEL. The bounds are functions of
# the kernel output, so that is the right surface to mutate: it tests the BOUND.
# Mutating the model tests the KERNEL, which was done separately for gate 7 (the
# beta_max walk, 2026-09-02: land 1.663 -> 6.697 monotone across beta_max x0.5 to
# x2.0). Both are needed and neither substitutes for the other.
# =====================================================================

# SOURCED ONCE, AT FILE SCOPE (2026-09-12, review B4). Every block used to
# `source(skip_if_no_gates(), local = TRUE)`, and the gate lib calls
# ccx_prepare_obs() and sources lib_seas_limbs.R at source time -- 14 blocks, 14
# rebuilds. The skip semantics are KEPT: the lib is sourced only if present, and
# every block still calls skip_if_no_gates() so a checkout without it SKIPS
# rather than errors (test-gate-p7.R sources unconditionally; this file does not).
GATES_LIB <- ccx_path("calibration", "lib_design_gates.R")
if (file.exists(GATES_LIB)) source(GATES_LIB, local = TRUE)
skip_if_no_gates <- function()
  skip_if_not(file.exists(GATES_LIB), "lib_design_gates.R not present")

test_that("GATE 4 is RETIRED, and says so by name rather than scoring", {
  skip_if_no_gates()
  # ⛔ RETIRED 2026-09-04 (Marcus). The ordering this block used to mutation-test
  # -- sd(model decadal AF) >= sd(GCB decadal AF) -- is gone: its numerator was a
  # scored stream, its denominator a model input, 70 % of its target's variance
  # was sampling noise, and sd() over seven decades could not tell a drift from a
  # wiggle [[ccx_gate4_no_power]]. A retired verdict must ERROR WITH THE REASON,
  # the way a retired mode name does, not return a plausible number.
  expect_error(dg_gate4_verdict(list(dec = DG_AF_OBS_DEC)), "RETIRED")
  # ...and the AF itself is still COMPUTED, because the level is worth printing.
  expect_equal(length(DG_AF_OBS_DEC), length(DG_AF_DECADES))
  expect_true(is.function(dg_gate4))
})

test_that("GATE V's bound is DERIVED from the observation, and fails in BOTH directions", {
  skip_if_no_gates()
  ov <- dg_gateV_obs()
  # ONE STRICTNESS across the distributional gates.
  expect_identical(DG_V_NSD, DG_Q_NSD)
  # THE SIGMA IS THE OBSERVED sd's OWN SAMPLING ERROR, not a chosen tolerance --
  # on the RESIDUAL dof nu = n - (DG_V_DF + 1) (2026-09-12, review A7): the
  # anomaly is taken about a fitted smooth with DG_V_DF + 1 parameters.
  expect_equal(ov$dof, ov$n - (DG_V_DF + 1))
  expect_equal(ov$se, ov$sd / sqrt(2 * ov$dof))
  expect_gt(ov$sd, 0); expect_gt(ov$se, 0); expect_gt(ov$n, 50)
  # ...and that analytic form is VALIDATED AGAINST A DESIGN-MATCHED MONTE CARLO,
  # which is the standing rule for any analytic se this project acts on.
  set.seed(20260904)
  mc <- stats::sd(replicate(2000, sqrt(sum(stats::rnorm(ov$dof, 0, ov$sd)^2) / ov$dof)))
  expect_lt(abs(mc - ov$se) / ov$se, 0.06)
  # MUTATION, BOTH DIRECTIONS -- the claim is two-sided: too MUCH interannual
  # variance is as wrong as too little.
  at <- function(sd) dg_gateV_verdict(list(sd = sd), ov)
  expect_true( at(ov$sd)$pass); expect_equal(at(ov$sd)$z, 0)
  expect_true( at(ov$sd - (DG_V_NSD - 0.1) * ov$se)$pass)
  expect_true( at(ov$sd + (DG_V_NSD - 0.1) * ov$se)$pass)
  expect_false(at(ov$sd - (DG_V_NSD + 0.5) * ov$se)$pass)   # too SMOOTH
  expect_false(at(ov$sd + (DG_V_NSD + 0.5) * ov$se)$pass)   # too NOISY
  # THE OBSERVED ANOMALY IS WHITE, which is what makes sqrt(2 nu) the right
  # denominator. If a GCB vintage change made it autocorrelated, the bound would
  # be wrong and this must fail rather than let it pass silently.
  expect_lt(abs(ov$rho), 0.2)
  # AND THE SMOOTHING IS A CHOICE, so the observed side must not turn on it.
  sds <- vapply(2:5, function(d) dg_gateV_obs(df = d)$sd, 0)
  expect_lt(diff(range(sds)) / mean(sds), 0.05)
})

test_that("GATE 4's observed vector is COMPUTED, and the retired literals were a DIFFERENT estimator", {
  skip_if_no_gates()
  a <- DG_AF_OBS_ANNUAL
  # 1. THE GATE SCORES AT THE MODEL'S OWN ESTIMATOR. dg_gate4() computes the
  #    model's decadal AF as a ratio of decade sums, so the observed side must be
  #    the same functional or the gate is not like-for-like.
  expect_equal(DG_AF_OBS_DEC, dg_af_dec(a, how = "ratio_of_sums")$dec)
  expect_equal(DG_AF_OBS,     dg_af_dec(a, how = "ratio_of_sums")$all)
  # 2. PROVENANCE OF THE RETIRED LITERALS, PINNED. They are the MEAN OF ANNUAL
  #    AF to 2 dp -- all seven -- and that is how the mismatch was found. If a
  #    GCB vintage change moves the budget, this fails rather than drifting.
  expect_identical(round(dg_af_dec(a, how = "mean_of_annual")$dec, 2),
                   DG_AF_OBS_DEC_TYPED)
  # 3. AND THE TWO ESTIMATORS ARE NOT INTERCHANGEABLE: the 1960s decade is where
  #    they round differently, which is the single observation that identified it.
  expect_false(identical(round(dg_af_dec(a, how = "ratio_of_sums")$dec, 2),
                         DG_AF_OBS_DEC_TYPED))
  # 4. The rounded literals were 6.6 % wider than the observations they stood
  #    for. That WAS the gate's bound until 2026-09-04; the AF is now printed
  #    rather than judged, so this guards the printed number's provenance.
  expect_lt(stats::sd(DG_AF_OBS_DEC), stats::sd(DG_AF_OBS_DEC_TYPED))
})

test_that("GATE 5's derived sigma is positive, finite, and rests on stated draws", {
  skip_if_no_gates()
  sp <- dg_obs_gate5_spread()
  expect_true(all(is.finite(sp$sd)))
  expect_true(all(sp$sd > 0))
  # ⚠ THE DRAW COUNTS ARE PART OF THE CLAIM. The NH aggregate has 3 zones and the
  # SH 2, so leave-one-out gives 4 and 3 draws; the lag is a function of both, so
  # it gets the 12 combinations. If the zone definitions change, this must fail
  # rather than silently re-scale every gate-5 tolerance.
  expect_identical(unname(sp$n[["nh"]]), 4L)
  expect_identical(unname(sp$n[["sh"]]), 3L)
  expect_identical(unname(sp$n[["lag"]]), 12L)
  # And the hemispheric spreads must NOT be taken over the 12 combinations: that
  # repeats each value and biases the sd about 10 % low, making the gate stricter
  # than the data warrants. Guard the property rather than the number.
  expect_gt(sp$sd[["nh_t"]], 0.9 * stats::sd(vapply(sp$nh, function(x) x[["t"]],
                                                    numeric(1))) - 1e-12)
  # ⭐ RULING 1 (2026-09-09): the TROUGH DEPTH's sigma comes off the SAME
  # leave-one-zone-out draws, so it must be present, positive and finite too.
  expect_true(is.finite(sp$sd[["nh_drop"]])); expect_gt(sp$sd[["nh_drop"]], 0)
  expect_true(is.finite(sp$sd[["nh_p1_t"]])); expect_gt(sp$sd[["nh_p1_t"]], 0)
  # ⭐ AND THE RULING'S OWN PREMISE, ASSERTED RATHER THAN QUOTED: the argmax
  # time flips between the two lumps under a zonal drop, the first-peak time
  # cannot. If that ever stops being true the ruling's justification is gone and
  # this must say so. MEASURED 2026-09-09: 0.444 yr vs 0.042 yr.
  expect_gt(sp$sd[["nh_t"]], 3 * sp$sd[["nh_p1_t"]])
})

test_that("GATE 5's NH shape kernel reads the double peak, and is the ONLY copy", {
  skip_if_no_gates()
  ob <- dg_obs_gate5()
  # The observed NH aggregate is double-peaked with the FIRST lump higher; the
  # trough sits between the two windows. These orderings are the structure the
  # trough statistic reads, so they are asserted, not assumed.
  expect_gt(ob$NH[["p1_v"]], ob$NH[["tr_v"]])
  expect_gt(ob$NH[["p2_v"]], ob$NH[["tr_v"]])
  expect_gt(ob$NH[["p1_v"]], ob$NH[["p2_v"]])       # first higher, by 2.4 %
  expect_lt(ob$NH[["p1_t"]], ob$NH[["tr_t"]])
  expect_lt(ob$NH[["tr_t"]], ob$NH[["p2_t"]])
  expect_equal(ob$NH[["drop"]], ob$NH[["p1_v"]] - ob$NH[["tr_v"]])
  # MUTATION on the kernel: flatten the curve and the drop must collapse to 0.
  t <- ob$NH[["p1_t"]] + seq(0, 1.5, by = 1 / 12)
  expect_equal(dg_nh_shape(t, rep(500, length(t)))[["drop"]], 0)
  # and deepen a synthetic trough and the drop must follow it, one for one
  v <- rep(500, length(t)); v[which.min(abs(t - 1964.125))] <- 400
  expect_equal(dg_nh_shape(t, v)[["drop"]], 100)
})

test_that("GATE 5 fails a shifted peak and an inverted ordering, and passes the truth", {
  skip_if_no_gates()
  ob <- dg_obs_gate5(); sp <- dg_obs_gate5_spread()
  # A synthetic gate-5 result built FROM the observation: the model that is
  # exactly right must pass, which is the direction a failing gate cannot show.
  # ⭐ RULING 1: the NH member of the judged set is the TROUGH DEPTH, so the
  # synthetic model must carry one. `ddrop` mutates it; `dnh` moves only the
  # argmax time, which after the ruling must NOT be able to fail the gate.
  mk <- function(dnh = 0, dsh = 0, ddrop = 0,
                 vnh = ob$NH[["v"]], vsh = ob$SH[["v"]])
    list(pk = list(NH = c(t = ob$NH[["t"]] + dnh, v = vnh,
                          drop = ob$NH[["drop"]] + ddrop,
                          p1_t = ob$NH[["p1_t"]],
                          # 2026-10-02 (W4): the e-fold is JUDGED since gate 5's sub-checks were
                          # restored, so the truth carries it (approved by Marcus)
                          efold = ob$NH[["efold"]]),
                   SH = c(t = ob$SH[["t"]] + dsh, v = vsh, efold = ob$SH[["efold"]])),
         # the lag is on the FIRST-PEAK time (ruled 2026-09-12), as dg_gate5()
         lag = (ob$SH[["t"]] + dsh) - ob$NH[["p1_t"]])
  expect_true(dg_gate5_verdict(mk(), ob, sp)$pass)

  # push the TROUGH out past the bound and it must fail, on the z and not the
  # ordering -- a mutation that trips the wrong clause is not a test of this one
  big_d <- (DG_G5_NSD + 1) * sp$sd[["nh_drop"]]
  v <- dg_gate5_verdict(mk(ddrop = -big_d), ob, sp)
  expect_false(v$pass); expect_false(v$pass_z); expect_true(v$pass_ord)
  expect_lt(v$z[["nh_drop"]], -DG_G5_NSD)
  # a too-DEEP trough must fail too: this is a two-sided bound, not a floor
  expect_false(dg_gate5_verdict(mk(ddrop = big_d), ob, sp)$pass)

  # ⛔ AND THE RULING'S POINT, AS A MUTATION: an NH argmax that has jumped to the
  # other lump -- the exact artifact that produced the retired "+2.17 sigma
  # late" -- must NOT fail the gate any more. The jump is the observed lump
  # spacing, taken from the observation rather than typed.
  lump <- ob$NH[["p2_t"]] - ob$NH[["p1_t"]]
  vj <- dg_gate5_verdict(mk(dnh = lump), ob, sp)
  expect_true(vj$pass)
  expect_equal(unname(vj$z[["nh_drop"]]), 0)      # the NH statistic does not move
  # ⭐ AND THE LAG NO LONGER INHERITS THE ARGMAX (ruled 2026-09-12): it is SH
  # peak minus NH FIRST-PEAK time in dg_gate5(), the spread and the verdict, so
  # a lump flip leaves it EXACTLY unmoved (it moved 1.86 sigma before).
  expect_equal(unname(vj$z[["lag"]]), 0)
  # ... and the spread's lag sigma is built on the same statistic
  expect_true(is.finite(sp$sd[["lag"]]) && sp$sd[["lag"]] > 0)
  expect_false("nh_t" %in% names(dg_gate5_verdict(mk(), ob, sp)$z))
  # the first-peak time is REPORTED, so it must be there and be finite
  expect_true(is.finite(dg_gate5_verdict(mk(), ob, sp)$reported[["nh_p1_t_z"]]))

  # the SH peak time is unchanged by ruling 1 and must still be able to fail
  big <- (DG_G5_NSD + 1) * sp$sd[["sh_t"]]
  v <- dg_gate5_verdict(mk(dsh = big), ob, sp)
  expect_false(v$pass); expect_false(v$pass_z)

  # ORDERING CLAUSE, which needs no sigma: put the SH peak BEFORE the NH one.
  # The bomb source was northern, so this is unphysical at any tolerance.
  v <- dg_gate5_verdict(mk(dsh = -2 * (ob$SH[["t"]] - ob$NH[["t"]])), ob, sp)
  expect_false(v$ord[["sh_after_nh"]]); expect_false(v$pass)

  # ... and make the SH peak the higher one, likewise unphysical.
  v <- dg_gate5_verdict(mk(vsh = ob$NH[["v"]] * 2), ob, sp)
  expect_false(v$ord[["nh_peak_higher"]]); expect_false(v$pass)
})

test_that("GATE 7 judges at the objective's sigmas, and can still fail", {
  skip_if_no_gates()
  # THE SIGMAS ARE THE OBJECTIVE'S, NOT THIS FILE'S. If R/likelihood.R changes
  # either one, this must fail rather than let the gate drift away from the fit.
  expect_equal(DG_G7_LAND_SD, LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE)
  expect_equal(DG_G7_OCEAN_SD, LIK_GCB_OCEAN_SD)
  # The three distributional gates share one strictness, ruled 2026-09-02.
  expect_identical(DG_G7_NSD, DG_Q_NSD)
  expect_identical(DG_G5_NSD, DG_Q_NSD)

  tgt <- list(land = 2.41, ocean = 3.20)
  ok  <- dg_gate7_verdict(list(land = tgt$land, ocean = tgt$ocean), tgt)
  expect_true(ok$pass); expect_equal(ok$z_land, 0); expect_equal(ok$z_ocean, 0)

  # break each half in turn, just past the bound
  bad_l <- dg_gate7_verdict(
    list(land = tgt$land + (DG_G7_NSD + 0.5) * DG_G7_LAND_SD, ocean = tgt$ocean), tgt)
  expect_false(bad_l$pass)
  bad_o <- dg_gate7_verdict(
    list(land = tgt$land, ocean = tgt$ocean - (DG_G7_NSD + 0.5) * DG_G7_OCEAN_SD), tgt)
  expect_false(bad_o$pass)

  # and the BARE-sigma readout, which every pre-2026-09-02 result used, must
  # still be reported; it is the stricter of the two exactly when the objective
  # inflates the land sigma (x3 until objective #12, 2026-09-16 e) and EQUAL to
  # it when it does not (LIK_LAND_SINK_INFLATE = 1 since #12: both halves at
  # GCB's stated sigma) -- the readout tracks the objective, never diverges from it
  expect_gte(abs(bad_l$z_land_bare), abs(bad_l$z_land))
  expect_equal(abs(bad_l$z_land_bare) / abs(bad_l$z_land), LIK_LAND_SINK_INFLATE, tolerance = 1e-8)
})

test_that("GATE G bounds the SURFACE LEVEL and not the inventory, and can fail", {
  skip_if_no_gates()
  expect_identical(DG_GD_NSD, DG_Q_NSD)      # one strictness across the four
  expect_identical(DG_GD_NEFF, LIK_D14C_DEEP_NEFF)   # the ruled convention, not a new number

  obs <- list(surf = 2034.9, surf_sd = 79.9,
              profile = data.frame(dic = 2034.9))
  mk <- function(surf, inv = 36990, inv_obs = 36990)
    list(surf = surf, inv = inv, inv_obs = inv_obs, inv_1750 = inv - 149)
  se <- obs$surf_sd / sqrt(DG_GD_NEFF)

  expect_true(dg_gateG_verdict(mk(obs$surf), obs)$pass)
  expect_equal(dg_gateG_verdict(mk(obs$surf), obs)$z, 0)
  expect_false(dg_gateG_verdict(mk(obs$surf + (DG_GD_NSD + 0.5) * se), obs)$pass)
  expect_false(dg_gateG_verdict(mk(obs$surf - (DG_GD_NSD + 0.5) * se), obs)$pass)

  # ⛔ THE INVENTORY MUST NOT ENTER THE VERDICT. The pump's export field was
  # solved to hold the OBSERVED gradient, so a bound on the inventory would
  # partly read back what built it ([[gate_reads_its_own_output]]). Wreck the
  # inventory and the verdict must be unmoved.
  a <- dg_gateG_verdict(mk(obs$surf), obs)
  b <- dg_gateG_verdict(mk(obs$surf, inv = 10000), obs)
  expect_true(a$pass); expect_true(b$pass)
  expect_equal(a$z, b$z)
  expect_false(isTRUE(all.equal(a$inv_pct, b$inv_pct)))   # ... but it IS reported

  # the sigma is a convention, so the verdict must move with n_eff -- which is
  # why the report walks it rather than quoting one number
  tight <- dg_gateG_verdict(mk(obs$surf + 1.5 * se), obs, n_eff = DG_GD_NEFF * 25)
  expect_false(tight$pass)
})

test_that("ccx_overlay_par() refuses to delete a parameter, and repairs the lag", {
  # THE REGRESSION FOR 2026-09-02's LIVE BUG. A pre-split 21-parameter set fed
  # through the bare `intersect()` idiom DELETES seas_lag_p_NH/_SH and the four
  # gamma_enso_* names, and the model then runs on ccx_default_params()' NAMED
  # DEFAULTS with nothing said -- lag 2.25 where the mode says 1.7677.
  # ⚠ ccx_set_enso() is NOT a fix for it: it repairs the ENSO names only.
  # ⚠ THE CANONICAL IS POST-SPLIT (31 parameters, seas_lag_p_NH/SH), so the
  # pre-split ancestor is CONSTRUCTED from it exactly as test-seas-lag-split.R
  # does: drop the pair, put back the legacy scalar. Until 2026-09-12 this block
  # `skip_if_not("seas_lag_p" %in% names(pm))` -- false of every post-split
  # canonical -- so the ONE regression test for the live bug never ran (review A10).
  pm <- ccx_migrate_par_set(ccx_mode_params()); attr(pm, "migrated") <- NULL
  pm <- pm[setdiff(names(pm), c("seas_lag_p_NH", "seas_lag_p_SH"))]
  pm$seas_lag_p <- 1.7502
  expect_false(any(c("seas_lag_p_NH", "seas_lag_p_SH") %in% names(pm)))   # or (a) has no power
  d <- ccx_default_params()

  # (a) the bare idiom really does delete, and really does change the lag
  bad <- d
  for (n in intersect(names(bad), CCX_PARAM_NAMES)) bad[[n]] <- pm[[n]]
  expect_false("seas_lag_p_NH" %in% names(bad))
  expect_equal(unname(ccx_seas_lag_p(bad)[["NH"]]), d$seas_lag_p_NH)   # the DEFAULT
  expect_false(isTRUE(all.equal(ccx_seas_lag_p(bad)[["NH"]],
                                ccx_seas_lag_p(pm)[["NH"]])))

  # (b) the helper keeps every name and lands on the MODE's lag
  ok <- ccx_overlay_par(d, pm)
  expect_true(all(setdiff(names(d), "gamma_enso") %in% names(ok)))
  expect_equal(ccx_seas_lag_p(ok)[["NH"]], ccx_seas_lag_p(pm)[["NH"]])
  expect_equal(ccx_seas_lag_p(ok)[["SH"]], ccx_seas_lag_p(pm)[["SH"]])
  expect_true(any(unlist(ccx_gamma_enso(ok)) != 0))

  # (c) and it HARD-ERRORS rather than dropping a name it cannot supply
  expect_error(ccx_overlay_par(c(d, list(not_a_real_param = 1)),
                               structure(pm, class = "list")),
               NA)   # an EXTRA name in `p` is not a deletion and must be fine
})

test_that("GATE H bounds the gradient CONTRAST, keeps its CO2 control, and cannot read its own offset", {
  skip_if_no_gates()
  obs <- ccx_prepare_obs()
  ho  <- dg_gateH_obs(obs)

  # (1) THE TARGET AND THE BOUND ARE BOTH COMPUTED FROM THE OBSERVATIONS, not
  # typed. If either side is ever re-typed as a literal this fails.
  expect_equal(ho$co2$mean,  mean(obs$co2_grad$grad[is.finite(obs$co2_grad$grad)]))
  expect_equal(ho$d13c$mean, mean(obs$d13c_grad$grad[is.finite(obs$d13c_grad$grad)]))
  # the se is on the RESIDUAL sd (ruled 2026-09-12), never the raw trended sd
  expect_equal(ho$co2$se,  ho$co2$sd_resid  / sqrt(ho$co2$n_eff))
  expect_equal(ho$d13c$se, ho$d13c$sd_resid / sqrt(ho$d13c$n_eff))
  expect_lt(ho$co2$sd_resid, ho$co2$sd)      # the trend is NOT charged to the noise
  # n_eff is a CORRECTION, never a licence: it may not exceed n.
  expect_lte(ho$co2$n_eff,  ho$co2$n)
  expect_lte(ho$d13c$n_eff, ho$d13c$n)
  expect_identical(DG_H_NSD, DG_Q_NSD)   # one strictness across the family

  # (2) ⭐ THE MUTATION THAT MATTERS. The gate exists because a FITTED OFFSET
  # absorbs the d13C gradient error. Feed it a model whose d13C gradient is the
  # OBSERVED one -- i.e. the error the offset hides, removed -- and the contrast
  # must collapse to the CO2 arm's own miss and PASS. If it does not, the gate
  # is not measuring what it claims.
  g_ok <- list(co2 = ho$co2$mean, d13c = ho$d13c$mean)
  v_ok <- dg_gateH_verdict(g_ok, ho)
  expect_equal(v_ok$R_co2, 1); expect_equal(v_ok$R_d13c, 1)
  expect_equal(v_ok$d, 0); expect_true(v_ok$pass)

  # (3) ⭐⭐ AND IT MUST FAIL ON THE REAL DEFECT. A d13C gradient 1.97x observed
  # with the CO2 gradient at 0.91x is the measured state at ent26; the contrast
  # must reject it, and reject it in the POSITIVE direction (d13C too steep
  # RELATIVE to CO2), not by some other route.
  g_bad <- list(co2 = 0.913 * ho$co2$mean, d13c = 1.969 * ho$d13c$mean)
  v_bad <- dg_gateH_verdict(g_bad, ho)
  expect_false(v_bad$pass)
  expect_gt(v_bad$z, DG_H_NSD)
  expect_gt(v_bad$z, 5)          # it is a ~6.5 sigma miss, not a marginal one

  # (4) ⭐ A COMMON TRANSPORT ERROR MUST CANCEL. That is the gate's whole
  # premise: scale BOTH gradients by the same factor and the contrast must not
  # move. If this ever fails, the gate has started charging transport errors to
  # the isotopes and its verdict means something else.
  for (k in c(0.7, 0.85, 1.15, 1.4)) {
    vk <- dg_gateH_verdict(list(co2 = k * ho$co2$mean, d13c = k * ho$d13c$mean), ho)
    expect_true(vk$pass, info = paste("common scaling", k))
    expect_equal(vk$d, 0, tolerance = 1e-12, info = paste("common scaling", k))
  }

  # (5) ⛔ IT MUST NOT BE ABLE TO READ THE COMPENSATOR. dg_gateH() takes the RAW
  # MLO-SPO difference; if a future edit ever adds the fitted offset back in,
  # the gate would be comparing the observation against itself and could never
  # fail. Asserted structurally: the model side must not depend on grad_off_*.
  v  <- dg_vector(CCX_MODE_CANONICAL)
  g1 <- dg_gateH(v, obs, ho)
  v2 <- v; v2$p$grad_off_co2 <- 0; v2$p$grad_off_d13c <- 0
  g2 <- dg_gateH(v2, obs, ho)
  expect_equal(g1$co2,  g2$co2)
  expect_equal(g1$d13c, g2$d13c)

  # (6) ⚠ THE CO2 CONTROL'S OWN LEVEL IS REPORTED, AND IT IS OUT (ruled
  # 2026-09-12: under the residual se it reads -3.6 se, 0.916x observed -- an
  # 8 % transport/representation miss). The claim that survives is an ORDERING:
  # the d13C arm's miss is several times the control's, so the contrast is not
  # driven by the shared transport error.
  vd <- dg_gateH_verdict(g1, ho)
  expect_gt(abs(vd$z_level_co2), DG_H_NSD)
  expect_gt(abs(vd$z_level_d13c), 4 * abs(vd$z_level_co2))
  expect_gt(abs(vd$z_level_d13c), 5)
  expect_false(vd$pass)
})

test_that("GATE S is an INTERVAL from an OBSERVATION plus a LAW, and it still fires on 3.35", {
  skip_if_no_gates()
  # ⛔⛔ REBASED 2026-09-04h. This block used to assert a Gaussian bound derived
  # from SPO_SEAS_OCEAN_PHASE_INV's bootstrap CI. That target is RETIRED -- the
  # two-signature inversion that produced it cannot be run at the canonical
  # mode -- and the gate now reads an INDEPENDENT pCO2 climatology plus a
  # physical law. THE BOUND'S KIND FOLLOWS ITS SOURCE
  # ([[gate_bound_matches_its_claim]]): an arc, not a sigma.

  # (1) BOTH ENDS COME FROM THE REGISTRY, NOT FROM LITERALS HERE.
  expect_equal(DG_S_PCO2_MO, ccx_const("SO_DPCO2_PEAK_MO"))
  expect_equal(DG_S_LAG_MAX, ccx_const("SO_DPCO2_LAG_MAX_MO"))
  expect_equal(DG_S_LO, DG_S_PCO2_MO)
  expect_equal(DG_S_HI, (DG_S_PCO2_MO + DG_S_LAG_MAX) %% 12)
  # (2) THE LAG BOUND IS A QUARTER CYCLE, DERIVED -- not a chosen tolerance.
  # If someone re-types it as a convenient number this fails.
  expect_equal(DG_S_LAG_MAX, 12 / 4)
  # (3) THERE IS NO SIGMA, AND THERE MUST NOT BE ONE. A gate whose source is
  # "somewhere in this arc" that grows a sigma has invented a distribution.
  expect_false(exists("DG_S_SD"))
  expect_false(exists("DG_S_NSD"))

  mk <- function(mo, amp = 0.5) list(mo = mo, amp = amp)
  # (4) INSIDE passes with a zero miss; just outside each edge fails -- both
  # directions, and the arc is CIRCULAR.
  expect_true(dg_gateS_verdict(mk(DG_S_LO))$pass)
  expect_true(dg_gateS_verdict(mk(DG_S_HI))$pass)
  expect_equal(dg_gateS_verdict(mk((DG_S_LO + DG_S_LAG_MAX / 2) %% 12))$d_mo, 0)
  eps <- 0.02
  expect_true( dg_gateS_verdict(mk((DG_S_LO + eps) %% 12))$pass)
  expect_true( dg_gateS_verdict(mk((DG_S_HI - eps) %% 12))$pass)
  expect_false(dg_gateS_verdict(mk((DG_S_LO - eps) %% 12))$pass)
  expect_false(dg_gateS_verdict(mk((DG_S_HI + eps) %% 12))$pass)
  # circularity: a month on the far side of the wrap is judged by ARC distance
  expect_false(dg_gateS_verdict(mk(1.0))$pass)
  expect_lt(abs(dg_gateS_verdict(mk(0.5))$d_mo), 6)

  # (5) ⭐⭐ THE POWER ASSERTION -- THE REASON A WIDER GATE IS STILL A GATE.
  # The rebased bound is 3.00 months against the retired 1.41, i.e. 25 % of the
  # circle, so it MUST be shown to still reject what it exists to reject: the
  # model's pre-fix SH ocean limb, on BOTH readings of it (4.16 on the channel
  # decomposition, 3.35 on lib_seas_limbs.R). If a future edit to the pCO2
  # constant ever swallows these, this fails and the gate has quietly lost its
  # power ([[no_power_null]]).
  expect_false(dg_gateS_verdict(mk(3.35))$pass)
  expect_false(dg_gateS_verdict(mk(4.16))$pass)
  # and it rejects them EARLY, not by wrapping round the far side
  expect_lt(dg_gateS_verdict(mk(3.35))$d_mo, 0)
  expect_lt(dg_gateS_verdict(mk(4.16))$d_mo, 0)

  # (6) THE RETIRED TARGET IS STILL CARRIED, FOR MATCHED COMPARISON ONLY, and
  # it lies INSIDE the new arc -- which is the corroboration that licensed the
  # rebase in the first place (2026-09-04g, the SOM-FFN bracket).
  expect_equal(DG_S_OBS_RETIRED, ccx_const("SPO_SEAS_OCEAN_PHASE_INV"))
  expect_true(dg_gateS_verdict(mk(DG_S_OBS_RETIRED))$pass)

  # (7) ⭐ AN ORDERING, NO THRESHOLD: the entrainment driver is far closer to
  # the arc than the active solubility limb is. Retained from the pre-rebase
  # block, because it is a statement about the model and not about the bound.
  expect_lt(abs(dg_mo_diff(CCX_ENT_SEAS_PEAK_MO, DG_S_LO)),
            abs(dg_mo_diff(3.35, DG_S_LO)))
  # ⭐ AND THE DRIVER'S OWN 7.50 NOW PASSES, WHERE IT FAILED THE RETIRED BOUND
  # AT |z| ~ 2.9. That is a real loosening and it is recorded here rather than
  # left to be discovered: the arc's lower edge is 7.41, and 7.50 sits just
  # inside it. The pre-registered "a limb that merely inherits the driver's
  # phase cannot clear GATE S" ceiling was already MEASURED AND WITHDRAWN on
  # 2026-09-03 for a different reason (the limb saturates ~2.3 months later
  # than the driver), so nothing depends on the old exclusion.
  expect_true(dg_gateS_verdict(mk(CCX_ENT_SEAS_PEAK_MO))$pass)
})

test_that("GATE S's knockout kills ALL THREE SH ocean limbs, and comes from the estimator", {
  skip_if_no_gates()
  # ⚠ THE 27g BUG, GUARDED STRUCTURALLY. `sst_seas_amp_SH = 0` alone leaves the
  # entrainment limb running, and this gate is built to be run with that channel
  # switched ON -- so a one-limb knockout would gate a limb that is not the one
  # named. Guard the NAMES, and guard that they are TAKEN from the shared
  # estimator rather than retyped beside it.
  # ⛔ AND THE THIRD LIMB (2026-09-12): with the seasonal mixed layer ON the
  # two-name knockout read 0.410 ppm @ 4.53 mo at hilda31s -- a FAIL that was the
  # gate's blind spot, not the model's phase (the whole limb is 0.465 @ 8.96).
  expect_setequal(names(DG_S_KO), c("sst_seas_amp_SH", "ent_seas_amp_SH", "seas_ml"))
  expect_true(all(unlist(DG_S_KO) == 0))
  expect_identical(DG_S_KO, SL_CASES$SH_ocean)
})

test_that("GATE S has POWER against its own blind spot: at a seas_ml = 1 canonical the switch moves the limb by months", {
  skip_if_no_gates()
  # the resolver takes a NAME (test-mode-struct-lint.R: no direct readRDS of a mode file here)
  skip_if_not(identical(ccx_mode_seas_ml(CCX_MODE_CANONICAL), 1L), "canonical has seas_ml OFF; the third limb is absent")
  obs <- ccx_prepare_obs(); v <- dg_vector(CCX_MODE_CANONICAL)
  full  <- dg_gateS_verdict(dg_gateS(v, obs))
  blind <- local({ ko <- DG_S_KO; ko$seas_ml <- NULL
    base <- dg_spo_vec(v, obs); vk <- v; for (n in names(ko)) vk$p[[n]] <- ko[[n]]
    d <- base - dg_spo_vec(vk, obs); list(amp = sl_amp(d), mo = sl_ang_mo(d)) })
  # the switch is load-bearing: without it the gate reads a different limb, by months
  expect_gt(abs(dg_mo_diff(full$mo, blind$mo)), 1)
  # THE RECORD (2026-09-12, hilda31s): whole limb 0.465 @ 8.96 PASS; the blind read 0.410 @ 4.53 FAIL.
  # At hilda31s2 (09-13): 0.472 @ 8.96 / 0.425 @ 4.51 -- same phases within the tolerance.
  # At hilda30c (09-13 (d), the shim PINNED at 0): whole limb 0.357 @ 8.92 PASS; the blind
  # read moves to @ 4.13 -- with the shim gone the blind knockout is the SST sine ALONE
  # (0.63 @ 4.1 in the C' anatomy), so the blind phase IS the thermal phase. Still FAIL.
  # At hilda30h (09-17 (h), the hygiene-batch refit on hilda_c): whole limb 0.327 @ 8.46 PASS
  # (the scorecard's number); the blind read stays @ 4.13 within the tolerance.
  # At hilda30e (09-19 (j), the #13 refit): unchanged, 0.327 @ 8.45. At hilda30s (09-20 (o), the hilda_cs
  # structure -- the ML's NH cycle FLAT, the SH cycle on): whole limb 0.286 @ 8.98 PASS (the scorecard's
  # number; the SPO limb is later by half a month with h_ml 58 and sst_seas_amp_NH 1.68), the blind read
  # 0.767 @ 4.10 -- the thermal phase, as before.
  # At hilda33d (2026-10-01 c, the D2/D3 canonical): whole limb 0.280 @ 8.83 PASS (the scorecard's number;
  # re-pin approved by Marcus).
  # At hilda34g (2026-10-03 h, the land ENSO lag fitted): whole limb 0.210 @ 8.50 PASS (8.5037; the
  # scorecard's number); the blind read 4.08, within its tolerance (Marcus 2026-10-03: "Approve all (Recommended)").
  expect_true(full$pass)
  expect_equal(full$mo,  8.50, tolerance = 0.05, scale = 1)
  expect_equal(blind$mo, 4.10, tolerance = 0.05, scale = 1)
  expect_false(dg_gateS_verdict(list(mo = blind$mo, amp = blind$amp))$pass)
})

test_that("L is a COMPARISON, not a gate: the verdict errors by name and dg_compareL() reports z's without a pass", {
  skip_if_no_gates()
  # ⛔ RULED 2026-09-08h (Marcus): Joos is not a scoring mechanism -- the long
  # lifetime is meant to be EMERGENT. A verdict must ERROR WITH THE REASON.
  expect_error(dg_gateL_verdict(list(share = c(land = 16, ocean = 59, air = 25))), "COMPARISON, NOT A GATE")
  expect_match(DG_L_COMPARISON, "emergent")
  # the split is a partition: the three ensemble means sum to 100 %
  expect_equal(sum(vapply(DG_L_RES, function(k) DG_L_JOOS[[k]][["mean"]], numeric(1))), 100)
  expect_match(DG_L_JOOS$src, "Joos")
  cmp <- dg_compareL(list(share = c(land = 16, ocean = 59, air = 25)))
  expect_equal(unname(cmp$z), c(0, 0, 0)); expect_null(cmp$pass)
  cmp2 <- dg_compareL(list(share = c(land = 30, ocean = 47, air = 23)))
  # re-pinned 2026-10-02 (approved, "Fix it"): Joos's +-14 / +-12 are +-2 s.d., so a share at the
  # published edge is z = +-2, not +-1. And the stored pair is consistent: pm2sd == 2 * sd.
  expect_equal(cmp2$z[["land"]], 2); expect_equal(cmp2$z[["ocean"]], -2)
  for (k in DG_L_RES) expect_equal(DG_L_JOOS[[k]][["pm2sd"]], 2 * DG_L_JOOS[[k]][["sd"]])
})

test_that("GATE GL bounds the d13C gradient LEVEL on the observation's own se, both ways, at H's strictness", {
  skip_if_no_gates()
  expect_identical(DG_GL_NSD, DG_H_NSD)
  ho <- dg_gateH_obs(ccx_prepare_obs())
  o  <- ho$d13c
  expect_equal(o$se, o$sd_resid / sqrt(o$n_eff))   # residual sd (ruled 2026-09-12)
  # ⭐ RULING 3 (2026-09-09): the gate is the AUGMENTED form and rep_frac is
  # DERIVED from the CO2 control, so the synthetic must carry a co2 arm. Giving
  # it the observed CO2 gradient makes R_co2 = 1 and rep_frac = 0 EXACTLY, which
  # is what lets the bare-se assertions below still be exact -- a perfect
  # control reduces the augmented gate to the bare one, and that is a property
  # worth asserting rather than a convenience.
  at <- function(m, ...) dg_gateGL_verdict(list(co2 = ho$co2$mean, d13c = m), ho, ...)
  expect_equal(at(o$mean)$rep_frac, 0); expect_true(at(o$mean)$rep_frac_derived)
  expect_equal(at(o$mean)$se, o$se)
  v0 <- at(o$mean); expect_true(v0$pass); expect_equal(v0$z, 0); expect_equal(v0$ratio, 1)
  expect_true (at(o$mean + (DG_GL_NSD - 0.1) * o$se)$pass)
  expect_false(at(o$mean + (DG_GL_NSD + 0.1) * o$se)$pass)
  expect_true (at(o$mean - (DG_GL_NSD - 0.1) * o$se)$pass)
  expect_false(at(o$mean - (DG_GL_NSD + 0.1) * o$se)$pass)
  # a 2x gradient (the canonical's class of miss) fails by a wide margin
  expect_false(at(2 * o$mean)$pass); expect_gt(abs(at(2 * o$mean)$z), 5)
  # the representation allowance WIDENS the se in quadrature, never narrows it
  v1 <- at(2 * o$mean, rep_frac = 0.1)
  expect_gt(v1$se, o$se); expect_equal(v1$se, sqrt(o$se^2 + (0.1 * o$mean)^2))
  expect_lt(abs(v1$z), abs(at(2 * o$mean)$z))
  expect_false(at(NA_real_)$pass)

  # ⭐ RULING 3, MUTATION-TESTED. Detune the CO2 control and the DERIVED
  # allowance must (a) equal |1 - R_co2| exactly, (b) widen the se, (c) shrink
  # |z| -- and (d) the bare-se z must be REPORTED unchanged beside it, so the
  # size of the allowance is always legible next to the verdict.
  bad <- function(f, m = 2 * o$mean)
    dg_gateGL_verdict(list(co2 = f * ho$co2$mean, d13c = m), ho)
  v2 <- bad(1.3)
  expect_equal(v2$rep_frac, 0.3); expect_true(v2$rep_frac_derived)
  expect_equal(v2$se, sqrt(o$se^2 + (0.3 * o$mean)^2))
  expect_gt(v2$se, o$se)
  expect_lt(abs(v2$z), abs(v2$z_bare))
  expect_equal(v2$z_bare, (2 * o$mean - o$mean) / o$se)
  # the allowance is |1 - R_co2|, so a control wrong the OTHER way widens it too
  expect_equal(bad(0.7)$rep_frac, 0.3)
  # ⛔ AND IT MUST NOT BE ABLE TO RESCUE THE CANONICAL'S CLASS OF MISS. A 2x
  # gradient fails at every control detuning up to 30 %: an allowance that could
  # flip the verdict would be an excuse, not a representation error.
  for (f in c(1, 1.05, 1.1, 1.2, 1.3)) expect_false(bad(f)$pass)
  # an ABSENT control must not silently become a passing gate (silent-gate family)
  expect_false(dg_gateGL_verdict(list(co2 = NA_real_, d13c = o$mean), ho)$pass)
})

test_that("GATE D bounds the HEMISPHERIC disequilibrium asymmetry from the GLODAP artifact, and cannot read the model's own state for its bound", {
  skip_if_no_gates()
  skip_if_not(file.exists(DG_D_OBS_FILE), "data/obs_hemi_diseq.rds not built")
  do <- dg_gateD_obs()
  # (1) THE TARGET AND THE BOUND COME FROM THE ARTIFACT, never typed: the
  # asymmetry equals the two hemispheric means' difference, the se is their
  # bootstrap se in quadrature, and the artifact records its own seed.
  o <- readRDS(DG_D_OBS_FILE)
  expect_equal(do$asym, o$targets$NH_all_area$mean - o$targets$SH_all_area$mean)
  expect_equal(do$asym_se, sqrt(o$targets$NH_all_area$se^2 + o$targets$SH_all_area$se^2))
  expect_true(is.finite(o$provenance$seed))
  expect_identical(DG_D_NSD, DG_Q_NSD)
  # its global mean must reproduce Quay's independently published value, which
  # is what licenses the artifact as an observation (0.60 +/- 0.10)
  expect_lt(abs(o$global$k - ccx_const("AIRSEA_D13C_DISEQ_OBS")), ccx_const("AIRSEA_D13C_DISEQ_SD"))
  # the meridional structure Quay describes: subtropics positive, poleward of 55 negative, in BOTH hemispheres
  for (h in HEMIS) { expect_gt(do$region[[paste0(h, "_ml")]]$mean, 0); expect_lt(do$region[[paste0(h, "_hs")]]$mean, 0) }

  # (2) an exact-match model passes with z 0
  g_ok <- list(region = lapply(do$region, `[[`, "mean"), hemi = lapply(do$hemi, `[[`, "mean"),
               asym = do$hemi$NH$mean - do$hemi$SH$mean, lat_hi = do$lat_hi)
  v_ok <- dg_gateD_verdict(g_ok, do)
  expect_equal(v_ok$z, 0); expect_true(v_ok$pass)
  expect_equal(unname(v_ok$z_region), rep(0, 4))

  # (3) ⭐ THE MUTATION THAT MATTERS: the hemispheres SWAPPED must fail, and in
  # the NEGATIVE direction (the model's NH too light relative to its SH)
  g_sw <- g_ok; g_sw$hemi <- list(NH = g_ok$hemi$SH, SH = g_ok$hemi$NH); g_sw$asym <- -g_ok$asym
  v_sw <- dg_gateD_verdict(g_sw, do)
  expect_false(v_sw$pass); expect_lt(v_sw$z, -DG_D_NSD)
  # and a model with NO asymmetry (two identical columns) fails too -- the
  # defect the gate exists for
  g_0 <- g_ok; g_0$asym <- 0
  expect_false(dg_gateD_verdict(g_0, do)$pass)

  # (4) ⛔ THE MODEL SIDE CANNOT DEPEND ON THE FITTED OFFSETS
  v  <- dg_vector(CCX_MODE_CANONICAL); r <- dg_run(v)
  g1 <- dg_gateD(r, v, do)
  v2 <- v; v2$grad_off_d13c <- 0; v2$grad_off_co2 <- 0; v2$p$grad_off_d13c <- 0
  g2 <- dg_gateD(r, v2, do)
  expect_equal(g1$asym, g2$asym)
  # the model's hemispheric D is the AREA-weighted mean of its regional D's
  # (ML region + HS box), so the two decompositions agree
  a_hs <- r$sp$aux$a_hs$NH; a_ml <- ccx_ml_area(r$sp$aux, "NH") + r$sp$aux$a_eq$NH + r$sp$aux$a_tr$NH
  expect_equal(g1$hemi$NH, (a_ml * g1$region$NH_ml + a_hs * g1$region$NH_hs) / (a_ml + a_hs))
  # (5) the canonical's measured state: the gate must be able to FAIL it
  # (the 09-20 s diagnosis: both columns at D ~ 0.9, asymmetry far below the observed)
  vd <- dg_gateD_verdict(g1, do)
  expect_true(is.finite(vd$z))
})
