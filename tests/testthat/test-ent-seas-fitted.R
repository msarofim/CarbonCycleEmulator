# =====================================================================
# test-ent-seas-fitted.R -- `ent_seas_amp_SH` ENTERING THE FITTED SET.
#
# WHAT CHANGED (2026-09-03, Marcus). The Southern-Ocean entrainment channel had
# existed since 2026-08-27g IMPLEMENTED, DEFAULTED TO 0 AND NOT IN
# CCX_PARAM_TABLE -- [[default_off_hides_the_bug]] in its textbook form -- while
# the model's worst prior violation was the SOLUBILITY amplitude it was standing
# in for. It is now fitted: 25 -> 26 parameters.
#
# WHAT THIS FILE GUARDS, and none of it is the logpost:
#   * the prior CENTRE is DERIVED and stays tied to its own arithmetic;
#   * the prior WIDTH still encodes the claim it was chosen to encode;
#   * the migration fills what the ancestor RAN, and says so;
#   * and the resulting vector REFUSES to encode, by name -- because a log space
#     has no 0, and that refusal is the honest answer rather than a bug.
# =====================================================================

test_that("ent_seas_amp_SH is fitted, and its init is TIED to the derived constant", {
  expect_true("ent_seas_amp_SH" %in% CCX_PARAM_NAMES)
  expect_identical(length(CCX_PARAM_NAMES), 38L)   # + the layer-2 limb w_enso_l2 (2026-09-17 k)   # 36 + w_thc (O1 arm THC, 2026-09-15 d); 33 + option D+E's three (2026-09-14 h)   # 26 -> 28 on 2026-09-06d (kz_deep_frac, hs_asx_frac); 29 on 09-07 (h_hs); 30 on 09-07e (pump_hs_gcm2); 31 on 09-08d (u_hs); 33 on 09-13i (w_eq, gamma_eq: the equatorial cell)
  # THE DRIFT THIS CLOSES. `init` is a literal because CCX_PARAM_TABLE is built
  # before ccx_const() exists, so the prior's CENTRE and its STARTING POINT are
  # written in two places. Same guard as pump_grad and npp_frac_NH carry.
  # ⚠ The tolerance is the TYPED PRECISION, not a chosen number: `init` carries
  # six decimals, so half a unit in the last of them is the most agreement a
  # literal can be asked for.
  expect_lt(abs(CCX_PARAM_TABLE$ent_seas_amp_SH$init -
                ccx_const("ENT_SEAS_AMP_SH_DERIV")), 0.5e-6)
  expect_identical(CCX_PARAM_TABLE$ent_seas_amp_SH$tr, "log")
})

test_that("the derived centre is the IN-BAND value diluted onto the SH box", {
  # ⛔ THE TWO SCALES MUST NOT COLLAPSE INTO ONE. 30 umol/kg is the anomaly
  # WITHIN the 40-90 S band; the PARAMETER perturbs the whole SH mixed layer, so
  # the prior centre is that number times the band's ocean-area weight. The
  # recorded plausibility band "far outside ~5-30" mixes them, which is exactly
  # why both are registered and why this ties the arithmetic.
  expect_equal(ccx_const("ENT_SEAS_AMP_SH_DERIV"),
               ccx_const("ENT_SEAS_AMP_SH_INBAND") *
                 ccx_const("ENT_SEAS_BAND_AREA_FRAC"), tolerance = 1e-12)
  expect_lt(ccx_const("ENT_SEAS_AMP_SH_DERIV"), ccx_const("ENT_SEAS_AMP_SH_INBAND"))
  # ⛔ AND BOTH MUST BE **COMPUTED**, NOT TYPED. Until 2026-09-03 the in-band
  # entry carried `value = 30` with its arithmetic only in the prose `source` --
  # labelled "derived" while being an independent copy, which is the LAMBDA_C14
  # bug this file's own header warns about. Recomputing moved it 30 -> 29.68 and
  # the centre 11.07 -> 10.95. Re-deriving the chain here is what keeps a future
  # edit to any input from leaving these two behind.
  # ⚠ THE COEFFICIENT IS REFERENCED, THE REST IS TRANSCRIBED, AND THAT SPLIT IS
  # DELIBERATE. `SST_PCO2_SENSITIVITY` is a REGISTERED constant, so the chain
  # must USE it -- the audit caught this very chain having typed 0.0423 a second
  # time. The remaining inputs are module-locals with no public name, so
  # transcribing them here is an INDEPENDENT check that the arithmetic has not
  # drifted, which is the whole point of a derivation test.
  # ⭐ VALUES UPDATED 2026-09-09w, TRANSCRIPTION KEPT (ruled by Marcus). Both
  # band inputs moved from typed literals in constants.R to data/ products:
  #   .ENT_SO_SST_AMP   3.0   -> 1.499498  K     (3.0 was the band P2P wearing
  #                                               the label "half-amplitude")
  #   .ENT_SO_PCO2_AMP  19.45 -> 16.258289 uatm  (19.45 was the PER-CELL
  #                                               reduction; a well-mixed BOX
  #                                               needs the AREA-MEAN harmonic)
  # ⚠ They are TRANSCRIBED here rather than read from the products ON PURPOSE:
  # reading them would only verify that this test opens the same file
  # constants.R opens, which is a tautology. An independent copy is what makes
  # this a derivation check. The cost is accepted and named: **if either product
  # is rebuilt to a different number, THIS TEST FAILS** -- which is the intended
  # alarm, not a maintenance defect. The product row below says which file.
  ENT_SO_SST_AMP_XCRIBED  <- 1.499498     # data/obs_so_sst_seas_amp.rds
  ENT_SO_PCO2_AMP_XCRIBED <- 16.258289    # data/obs_so_pco2_seas_amp.rds
  inband <- (ENT_SO_SST_AMP_XCRIBED * ccx_const("SST_PCO2_SENSITIVITY") * 370 +
             ENT_SO_PCO2_AMP_XCRIBED) / 370 * 2150 / 13
  # the transcription carries 6 decimals, so agreement is asked to the precision
  # a 6-decimal literal can actually deliver, not to 1e-10 ([[derived_must_mean_computed]])
  expect_equal(ccx_const("ENT_SEAS_AMP_SH_INBAND"), inband, tolerance = 1e-6)
  # ⛔ AND THE TRANSCRIPTION MUST STILL BE THE PRODUCT'S OWN NUMBER. This is the
  # half that keeps a stale transcription from passing quietly: it fails if a
  # product is rebuilt and this file is not updated with it.
  expect_equal(readRDS(ccx_path("data", "obs_so_sst_seas_amp.rds"))$band_half_amp_K,
               ENT_SO_SST_AMP_XCRIBED, tolerance = 5e-7)
  expect_equal(readRDS(ccx_path("data", "obs_so_pco2_seas_amp.rds"))$band_amp_uatm,
               ENT_SO_PCO2_AMP_XCRIBED, tolerance = 5e-7)
  # ⛔ AND THE COEFFICIENT MUST NOT SILENTLY FORK AGAIN: if someone re-types it
  # in the chain, this stops agreeing with the registry.
  expect_equal(ccx_const("ENT_SEAS_AMP_SH_INBAND") /
                 ((ENT_SO_SST_AMP_XCRIBED * ccx_const("SST_PCO2_SENSITIVITY") * 370 +
                   ENT_SO_PCO2_AMP_XCRIBED) / 370),
               2150 / 13, tolerance = 1e-6)
  # the area fraction is REGISTERED, so it cannot go on being a free literal
  expect_true("ENT_SEAS_BAND_AREA_FRAC" %in% names(CCX_CONSTANTS))
  # ⚠ and it is PROVISIONAL -- a geographic area ratio with no cited source --
  # so anything derived from it inherits that. Guard the label, not just the value.
  expect_identical(CCX_CONSTANTS$ENT_SEAS_BAND_AREA_FRAC$status, "provisional")
})

test_that("the prior is CENTRED on the derived value and its WIDTH is a geometric ceiling", {
  a  <- ccx_const("ENT_SEAS_AMP_SH_DERIV")
  # ⛔ CENTRED IN THE **UNCONSTRAINED** COORDINATE, WHICH IS WHERE THE CLAIM
  # LIVES -- and asserting it on the natural-scale DENSITY would be wrong, not
  # merely awkward. A lognormal density peaks at exp(mu - sigma^2), BELOW its
  # median exp(mu), so `pr(a) > pr(a/1.2)` is FALSE here by 0.10 log-units even
  # though the prior is centred exactly on `a`. That is [[prior_z_grid_scale]]'s
  # lesson in miniature: integrate in the coordinate the parameter is sampled in.
  expect_equal(ccx_prior_z("ent_seas_amp_SH", a), 0, tolerance = 1e-8)
  # symmetric about the centre IN LOG SPACE, which is what "centred" means for
  # this transform -- a ratio up and the same ratio down are equal and opposite
  for (k in c(1.2, 2, 3)) {
    expect_equal(ccx_prior_z("ent_seas_amp_SH", a * k),
                 -ccx_prior_z("ent_seas_amp_SH", a / k), tolerance = 1e-8)
  }
  # ... and monotone away from it, so `a` really is the extremum and not a shelf
  expect_gt(ccx_prior_z("ent_seas_amp_SH", a * 2), ccx_prior_z("ent_seas_amp_SH", a * 1.2))
  # ⭐ THE WIDTH IS DERIVED FROM A GEOMETRIC CEILING, AND THIS TIES IT THERE.
  # The parameter is the in-band anomaly DILUTED onto the SH box, so the box
  # mean cannot exceed the in-band amplitude; it reaches it only if every SH
  # ocean square metre behaves like the observed 40-90 S band. That no-dilution
  # limit is log(1/area fraction) above the centre, and reading it as DG-family
  # 2 sigma fixes the width. ⛔ The width must NOT be read off the recorded
  # "5-30" band instead: that band's lower endpoint has no derivation anywhere,
  # and a width resting on an unsourced number is a chosen one in disguise.
  expect_lt(abs(ENT_SEAS_LOGSD -
                log(1 / ccx_const("ENT_SEAS_BAND_AREA_FRAC")) / 2), 0.5e-5)
  # ⭐ THE CONSEQUENCE, EXACT BY CONSTRUCTION: the in-band value sits at +2 sigma.
  # If this stops holding, the width and the ceiling have come apart.
  # ⚠ The tolerance is PROPAGATED from the typed precision, not chosen: z scales
  # as 1/ENT_SEAS_LOGSD, which is a literal carrying five decimals, so half a
  # unit in its last digit moves this z by DG_S_NSD * 0.5e-5 / ENT_SEAS_LOGSD.
  expect_lt(abs(ccx_prior_z("ent_seas_amp_SH", ccx_const("ENT_SEAS_AMP_SH_INBAND")) - 2),
            2 * 0.5e-5 / ENT_SEAS_LOGSD)
  # ✅ AND THE INDEPENDENT CORROBORATION -- an ORDERING, with no threshold of its
  # own: the recorded plausibility band, derived a completely different way,
  # must fall INSIDE the interval this ceiling implies. It does (z -1.57 at 5).
  # That the two readings agree is the check; neither is fitted to the other.
  expect_lt(abs(ccx_prior_z("ent_seas_amp_SH", 5)), 2)
  expect_gt(abs(ccx_prior_z("ent_seas_amp_SH", 5)),
            abs(ccx_prior_z("ent_seas_amp_SH", ccx_const("ENT_SEAS_AMP_SH_DERIV"))))
})

test_that("a 25-parameter ancestor migrates to 0 -- what it RAN -- and says so", {
  full <- ccx_unc_to_par(ccx_init_unc())
  expect_false(is.null(full$ent_seas_amp_SH))
  anc  <- full; anc$ent_seas_amp_SH <- NULL          # the pre-2026-09-03 shape
  mig  <- ccx_migrate_par_set(anc)
  # ⛔ 0 IS NOT AN INVENTED COORDINATE HERE. The channel did not exist in the
  # fitted set when that ancestor was fitted, so 0 is the state it RAN -- the
  # same reasoning that migrates the ENSO OCEAN pair to 0. And it is the value
  # the model's own absence contract would have produced anyway.
  expect_equal(mig$ent_seas_amp_SH, 0)
  expect_true("ent_seas_amp_SH" %in% attr(mig, "migrated"))
  # every other coordinate is untouched by this branch
  for (n in setdiff(CCX_PARAM_NAMES, "ent_seas_amp_SH"))
    expect_equal(mig[[n]], full[[n]], info = n)
})

test_that("the migrated ancestor REFUSES to encode, by name and with the value", {
  full <- ccx_unc_to_par(ccx_init_unc())
  anc  <- full; anc$ent_seas_amp_SH <- NULL
  mig  <- ccx_migrate_par_set(anc)
  # ⭐ THE POINT. `tr = "log"` has no 0, so the ancestor's OFF state is not a
  # point of this build's fitted space. Before 2026-09-03 this returned -Inf
  # SILENTLY and handed a non-finite start vector to an optimiser three frames
  # away; it now refuses and names the coordinate.
  err <- tryCatch(ccx_par_to_unc(mig), error = conditionMessage)
  expect_type(err, "character")
  expect_match(err, "ent_seas_amp_SH", fixed = TRUE)
  expect_match(err, "OUTSIDE their transform", fixed = TRUE)
  # ⚠ AND IT MUST STILL BE RUNNABLE. A vector you cannot ENCODE is still a
  # legitimate vector to MEASURE at -- that is what every gate driver does with
  # a migrated mode -- so the refusal must be on the encoder alone.
  expect_equal(mig$ent_seas_amp_SH, 0)
  # seeding the coordinate at its table init makes it encodable again, which is
  # the documented repair for a START point
  seeded <- mig; seeded$ent_seas_amp_SH <- CCX_PARAM_TABLE$ent_seas_amp_SH$init
  expect_true(all(is.finite(ccx_par_to_unc(seeded))))
})

test_that("the DEFAULT is the derived prior centre, now that the refit is adopted", {
  # ⭐ CHANGED 2026-09-04, and this test asked to be. Its previous form asserted
  # `default == 0` while the INIT was non-zero, with the reason written into it:
  # "the mechanism is a hypothesis that has not been refitted, let alone
  # adopted... ⇒ WHEN THE REFIT IS ADOPTED, this expectation is the thing to
  # change." The 26-parameter `ent26` mode was adopted on 2026-09-04, so it is.
  #
  # ⚠ WHY THE DEFAULT COULD NOT STAY 0 ONCE THE CHANNEL WAS REAL. R/model.R's
  # guard is `p$ent_seas_amp_SH != 0`, so zero does not mean "a small amplitude"
  # -- it SHORT-CIRCUITS the entrainment code path outright, and every
  # defaults-arm run (the gates' whole "defaults" column) would exercise a model
  # the calibrated one does not have ([[default_off_hides_the_bug]]).
  #
  # ⛔ THE DEFAULT IS THE PRIOR CENTRE, NOT THE FITTED 19.0291. The two are
  # different statements and conflating them is what this file is about:
  # `ccx_default_params()` is the UNCALIBRATED reference (its `sst_seas_amp_SH`
  # is 1.2 against a fitted 1.85), so a fitted number here would make the gates'
  # "defaults" column an undeclared second copy of the mode.
  expect_equal(ccx_default_params()$ent_seas_amp_SH,
               CCX_PARAM_TABLE$ent_seas_amp_SH$init)
  expect_gt(CCX_PARAM_TABLE$ent_seas_amp_SH$init, 0)
  # ⛔ AND NO TIGHTER ASSERTION THAN THAT HERE. The obvious next line -- that the
  # default EQUALS ccx_const("ENT_SEAS_AMP_SH_DERIV") to machine precision -- was
  # written on 2026-09-04 and REMOVED the same hour: it fails by 4.41e-07,
  # because `init` is necessarily a six-decimal LITERAL (R/calibrate.R is sourced
  # before R/constants.R, so ccx_const() does not exist when the table is built).
  # The first test in this file already bounds that drift, and bounds it by the
  # literal's own typed precision rather than by a chosen number. Repeating it
  # tighter here would not be a stronger guard, only a failing one.
})
