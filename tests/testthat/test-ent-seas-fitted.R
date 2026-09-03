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
  expect_identical(length(CCX_PARAM_NAMES), 26L)
  # THE DRIFT THIS CLOSES. `init` is a literal because CCX_PARAM_TABLE is built
  # before ccx_const() exists, so the prior's CENTRE and its STARTING POINT are
  # written in two places. Same guard as pump_grad and npp_frac_NH carry.
  expect_equal(CCX_PARAM_TABLE$ent_seas_amp_SH$init,
               ccx_const("ENT_SEAS_AMP_SH_DERIV"), tolerance = 1e-12)
  expect_identical(CCX_PARAM_TABLE$ent_seas_amp_SH$tr, "log")
})

test_that("the derived centre is the IN-BAND value diluted onto the SH box", {
  # ⛔ THE TWO SCALES MUST NOT COLLAPSE INTO ONE. 30 umol/kg is the anomaly
  # WITHIN the 40-90 S band; the PARAMETER perturbs the whole SH mixed layer, so
  # the prior centre is that number times the band's ocean-area weight. The
  # recorded plausibility band "far outside ~5-30" mixes them, which is exactly
  # why both are registered and why this ties the arithmetic.
  expect_equal(ccx_const("ENT_SEAS_AMP_SH_DERIV"),
               ccx_const("ENT_SEAS_AMP_SH_INBAND") * 0.369, tolerance = 1e-12)
  expect_lt(ccx_const("ENT_SEAS_AMP_SH_DERIV"), ccx_const("ENT_SEAS_AMP_SH_INBAND"))
})

test_that("the prior is CENTRED on the derived value and reads 5-30 as ~2 sigma", {
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
  # ⭐ THE WIDTH ENCODES A CLAIM, AND THIS IS THE CLAIM. The recorded band's own
  # wording -- "a fitted value FAR OUTSIDE ~5-30 is the channel being used as a
  # fudge factor" -- is a plausibility GATE, i.e. a ~2 sigma statement, not the
  # +/- 1 sigma bracket that ccx_bracket_lnorm() would have made of it. Read as a
  # bracket the width would be 0.896 and both endpoints would sit at 1 sigma;
  # this must fail if anyone makes that substitution.
  for (edge in c(5, 30)) {
    z <- abs(ccx_prior_z("ent_seas_amp_SH", edge))
    expect_gt(z, 1.5); expect_lt(z, 2.5)
  }
  # and the width is a JUDGEMENT that lives in ONE place
  expect_identical(ENT_SEAS_LOGSD, 0.45)
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

test_that("the DEFAULT stays 0 while the INIT is non-zero, deliberately", {
  # ⛔ NOT AN INCONSISTENCY -- two different statements, and the asymmetry is the
  # ruling. The INIT is where the search starts (and is what tests an
  # off-by-default mechanism at an explicit non-zero value); the DEFAULT is what
  # an UNCALIBRATED run does, and the mechanism is a hypothesis that has not been
  # refitted, let alone adopted. Flipping the default would move every "at
  # defaults" number on the project for a mechanism nothing has accepted.
  # ⇒ WHEN THE REFIT IS ADOPTED, this expectation is the thing to change.
  expect_equal(ccx_default_params()$ent_seas_amp_SH, 0)
  expect_gt(CCX_PARAM_TABLE$ent_seas_amp_SH$init, 0)
})
