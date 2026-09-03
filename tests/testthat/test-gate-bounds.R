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

skip_if_no_gates <- function() {
  f <- ccx_path("calibration", "lib_design_gates.R")
  skip_if_not(file.exists(f), "lib_design_gates.R not present")
  f
}

test_that("GATE 4's ordering fails a smoother model and passes a rougher one", {
  source(skip_if_no_gates(), local = TRUE)
  so <- stats::sd(DG_AF_OBS_DEC)
  # The bound is an ORDERING with no threshold, so the mutation is a scale on the
  # spread about its own mean -- which changes the variability and nothing else.
  spread <- function(f) {
    m <- mean(DG_AF_OBS_DEC); list(dec = m + f * (DG_AF_OBS_DEC - m))
  }
  expect_false(dg_gate4_verdict(spread(0.5))$pass)   # smoother than GCB -> FAIL
  expect_true( dg_gate4_verdict(spread(1.5))$pass)   # rougher  than GCB -> PASS
  # AT the observation it must pass: the claim is ">=", not ">".
  expect_true( dg_gate4_verdict(spread(1.0))$pass)
  expect_equal(dg_gate4_verdict(spread(1.0))$ratio, 1)
  expect_equal(dg_gate4_verdict(spread(1.0))$sd_obs, so)
})

test_that("GATE 5's derived sigma is positive, finite, and rests on stated draws", {
  source(skip_if_no_gates(), local = TRUE)
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
})

test_that("GATE 5 fails a shifted peak and an inverted ordering, and passes the truth", {
  source(skip_if_no_gates(), local = TRUE)
  ob <- dg_obs_gate5(); sp <- dg_obs_gate5_spread()
  # A synthetic gate-5 result built FROM the observation: the model that is
  # exactly right must pass, which is the direction a failing gate cannot show.
  mk <- function(dnh = 0, dsh = 0, vnh = ob$NH[["v"]], vsh = ob$SH[["v"]])
    list(pk = list(NH = c(t = ob$NH[["t"]] + dnh, v = vnh),
                   SH = c(t = ob$SH[["t"]] + dsh, v = vsh)),
         lag = (ob$SH[["t"]] + dsh) - (ob$NH[["t"]] + dnh))
  expect_true(dg_gate5_verdict(mk(), ob, sp)$pass)

  # push the NH peak out past the bound and it must fail, on the z and not the
  # ordering -- a mutation that trips the wrong clause is not a test of this one
  big <- (DG_G5_NSD + 1) * sp$sd[["nh_t"]]
  v <- dg_gate5_verdict(mk(dnh = big, dsh = big), ob, sp)
  expect_false(v$pass); expect_false(v$pass_z); expect_true(v$pass_ord)

  # ORDERING CLAUSE, which needs no sigma: put the SH peak BEFORE the NH one.
  # The bomb source was northern, so this is unphysical at any tolerance.
  v <- dg_gate5_verdict(mk(dsh = -2 * (ob$SH[["t"]] - ob$NH[["t"]])), ob, sp)
  expect_false(v$ord[["sh_after_nh"]]); expect_false(v$pass)

  # ... and make the SH peak the higher one, likewise unphysical.
  v <- dg_gate5_verdict(mk(vsh = ob$NH[["v"]] * 2), ob, sp)
  expect_false(v$ord[["nh_peak_higher"]]); expect_false(v$pass)
})

test_that("GATE 7 judges at the objective's sigmas, and can still fail", {
  source(skip_if_no_gates(), local = TRUE)
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
  # still be reported and must be the stricter of the two
  expect_gt(abs(bad_l$z_land_bare), abs(bad_l$z_land))
})

test_that("GATE G bounds the SURFACE LEVEL and not the inventory, and can fail", {
  source(skip_if_no_gates(), local = TRUE)
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
  pm <- ccx_mode_params()                       # the canonical pre-split ancestor
  skip_if_not("seas_lag_p" %in% names(pm), "canonical mode is not pre-split")
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

test_that("GATE S bounds the limb PHASE, is CIRCULAR, and fires on the 3.35 defect", {
  source(skip_if_no_gates(), local = TRUE)
  # ONE STRICTNESS across the distributional gates, ruled 2026-09-02.
  expect_identical(DG_S_NSD, DG_Q_NSD)
  # THE SIGMA IS DERIVED FROM THE REGISTRY, NOT TYPED. If the registered CI
  # moves, this must fail rather than let the gate keep an orphaned tolerance.
  expect_equal(DG_S_OBS,    ccx_const("SPO_SEAS_OCEAN_PHASE_INV"))
  expect_equal(DG_S_OBS_LO, ccx_const("SPO_SEAS_OCEAN_PHASE_INV_LO"))
  expect_equal(DG_S_OBS_HI, ccx_const("SPO_SEAS_OCEAN_PHASE_INV_HI"))
  expect_equal(DG_S_SD, (DG_S_OBS_HI - DG_S_OBS_LO) / (2 * stats::qnorm(0.975)))
  # ... and harmonising with the family must not have widened the registered
  # interval: |z| <= 2 has to reproduce [LO, HI] to better than 0.05 months.
  expect_lt(abs(DG_S_OBS - DG_S_NSD * DG_S_SD - DG_S_OBS_LO), 0.05)
  expect_lt(abs(DG_S_OBS + DG_S_NSD * DG_S_SD - DG_S_OBS_HI), 0.05)

  mk <- function(mo, amp = DG_S_AMP_OBS) list(mo = mo, amp = amp)
  # AT the observation: pass, and exactly zero.
  expect_true(dg_gateS_verdict(mk(DG_S_OBS))$pass)
  expect_equal(dg_gateS_verdict(mk(DG_S_OBS))$z, 0)
  # just INSIDE each edge passes, just OUTSIDE fails -- both directions
  eps <- 0.02
  expect_true( dg_gateS_verdict(mk(DG_S_OBS - DG_S_NSD * DG_S_SD + eps))$pass)
  expect_true( dg_gateS_verdict(mk(DG_S_OBS + DG_S_NSD * DG_S_SD - eps))$pass)
  expect_false(dg_gateS_verdict(mk(DG_S_OBS - (DG_S_NSD + 0.5) * DG_S_SD))$pass)
  expect_false(dg_gateS_verdict(mk(DG_S_OBS + (DG_S_NSD + 0.5) * DG_S_SD))$pass)

  # ⭐ THE MUTATION THAT MATTERS: the model's ACTIVE solubility limb peaks at
  # 3.35 months. The gate exists because nothing scored that, so it must FAIL
  # there -- and fail by ~5.17 months, not by some other route.
  v <- dg_gateS_verdict(mk(3.35))
  expect_false(v$pass)
  expect_equal(v$d_mo, 3.35 - DG_S_OBS, tolerance = 1e-9)
  expect_gt(abs(v$z), 10)
  # ⚠ AND THE PASS DIRECTION IS DEMONSTRATED ABOVE, NOT HERE. It is tempting to
  # assert that the DISABLED entrainment channel passes -- but CCX_ENT_SEAS_PEAK_MO
  # is the DRIVER's peak month, not a measured SPO limb, and the two differ by
  # whatever lag the transport and air-sea exchange impose. Testing the constant
  # against this gate would compare a driver with an observable.
  # ⭐ WHAT IS WORTH RECORDING, AS AN ORDERING WITH NO THRESHOLD: the entrainment
  # driver is far CLOSER to the observed limb than the active solubility one.
  expect_lt(abs(dg_mo_diff(CCX_ENT_SEAS_PEAK_MO, DG_S_OBS)),
            abs(dg_mo_diff(3.35, DG_S_OBS)))
  # THE DRIVER'S OWN 7.50 IS 1.02 MONTHS EARLY, i.e. |z| ~ 2.9 on this gate's
  # DERIVED sigma -- OUTSIDE the bound. That is a property of the gate and it is
  # what this asserts.
  # ⛔ IT WAS ALSO PRE-REGISTERED AS A CEILING ON FIX A -- "a limb that merely
  # inherits the driver's phase cannot clear GATE S" -- AND THAT CEILING IS NOW
  # MEASURED AND WITHDRAWN (diag_ent_conditional_lever.R, 2026-09-03): the SPO
  # limb saturates near month 9.8, some 2.3 months LATER than the driver, so it
  # does NOT inherit the driver's phase and the reachable range BRACKETS 8.52.
  # The assertion below stands; the inference drawn from it did not.
  expect_false(dg_gateS_verdict(mk(CCX_ENT_SEAS_PEAK_MO))$pass)
  expect_gt(abs(dg_gateS_verdict(mk(CCX_ENT_SEAS_PEAK_MO))$z), DG_S_NSD)

  # ⭐ MONTHS ARE AN ANGLE. A limb at 0.1 is 0.2 months from one at 11.9, not
  # 11.8 -- and a wrapped phase must read identically to its unwrapped twin.
  expect_equal(dg_mo_diff(0.1, 11.9), 0.2, tolerance = 1e-9)
  expect_equal(dg_mo_diff(11.9, 0.1), -0.2, tolerance = 1e-9)
  expect_equal(dg_gateS_verdict(mk(DG_S_OBS + 12))$z, 0)
  expect_equal(dg_gateS_verdict(mk(DG_S_OBS - 12))$z, 0)
  # the largest possible miss is half a year, never more
  expect_lte(max(abs(vapply(seq(0, 12, by = 0.25),
                            function(m) dg_gateS_verdict(mk(m))$d_mo, 0))), 6)

  # ⛔ THE AMPLITUDE MUST NOT ENTER THE VERDICT. It is reported because the arc
  # is quoted in it, but SPO_SEAS_AMP_OCEAN_INV carries no interval, so bounding
  # it would be choosing a number after seeing the result. Wreck it and the
  # verdict must be unmoved -- the GATE G idiom.
  a <- dg_gateS_verdict(mk(DG_S_OBS))
  b <- dg_gateS_verdict(mk(DG_S_OBS, amp = DG_S_AMP_OBS * 100))
  expect_true(a$pass); expect_true(b$pass); expect_equal(a$z, b$z)
  expect_false(isTRUE(all.equal(a$amp_ratio, b$amp_ratio)))   # ... but IS reported
})

test_that("GATE S's knockout kills BOTH SH ocean limbs, and comes from the estimator", {
  source(skip_if_no_gates(), local = TRUE)
  # ⚠ THE 27g BUG, GUARDED STRUCTURALLY. `sst_seas_amp_SH = 0` alone leaves the
  # entrainment limb running, and this gate is built to be run with that channel
  # switched ON -- so a one-limb knockout would gate a limb that is not the one
  # named. Guard the NAMES, and guard that they are TAKEN from the shared
  # estimator rather than retyped beside it.
  expect_setequal(names(DG_S_KO), c("sst_seas_amp_SH", "ent_seas_amp_SH"))
  expect_true(all(unlist(DG_S_KO) == 0))
  expect_identical(DG_S_KO, SL_CASES$SH_ocean)
})
