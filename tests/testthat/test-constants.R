# =====================================================================
# Gate: constants provenance and internal consistency.
#
# Motivated by a real bug (2026-08-10): LAMBDA_C14 was written as the literal
# log(2)/5700 while being LABELED "derived" from T_HALF_C14. Changing the
# half-life left the decay rate untouched, and a mutation test that swapped in
# the Libby 5568 yr value produced bit-identical output -- i.e. the decay gate
# was inert. These tests make that class of decoupling impossible to reintroduce.
# =====================================================================

test_that("every constant declares a status and a source", {
  for (nm in names(CCX_CONSTANTS)) {
    k <- CCX_CONSTANTS[[nm]]
    expect_true(!is.null(k$value),  info = nm)
    expect_true(!is.null(k$units),  info = nm)
    # "retired" added 2026-09-04h: a constant whose GENERATING METHOD has been
    # invalidated, kept by name for matched comparison and provenance, and read
    # by no live gate. It is a distinct state from "provisional" -- provisional
    # means "we are using it and it carries a dependence"; retired means "do
    # NOT use it as a target". A test below asserts the roster.
    expect_true(k$status %in% c("derived", "cited", "data", "provisional", "retired"),
                info = nm)
    expect_true(nchar(k$source) > 20, info = paste(nm, "needs a real source string"))
    expect_true(is.finite(k$value), info = nm)
  }
})

test_that("derived constants actually derive from their stated inputs", {
  # If any of these is re-typed as a literal, changing the parent silently
  # decouples it -- exactly the bug this file exists to prevent.
  expect_equal(ccx_const("LAMBDA_C14"), log(2) / ccx_const("T_HALF_C14"))
  expect_equal(ccx_const("MOL_C_PER_GtC"), 1e15 / 12.011)

  lambda_s <- log(2) / (ccx_const("T_HALF_C14") * 365.25 * 86400)
  expect_equal(ccx_const("MOL_C14_PER_GBq"), 1e9 / lambda_s / 6.02214076e23,
               tolerance = 1e-12)
})

test_that("the 14C half-life is the true value, not the Libby reporting convention", {
  # 5568 yr is an AGE-REPORTING convention (Stuiver & Polach 1977) and must
  # never be used as a decay constant.
  expect_equal(ccx_const("T_HALF_C14"), 5700)
  expect_false(isTRUE(all.equal(ccx_const("T_HALF_C14"), 5568)))
})

test_that("the GCB and first-principles GtC/ppm agree to better than 0.5 %", {
  # They are NOT identical (2.124 vs 2.130). The model uses the GCB value for
  # consistency with the sink targets; this test documents the size of the gap
  # so it cannot quietly grow.
  rel <- abs(ccx_const("GtC_PER_PPM_DERIVED") / ccx_const("GtC_PER_PPM") - 1)
  expect_lt(rel, 0.005)
  expect_gt(rel, 0.001)    # they genuinely differ; if this fails someone aliased them
})

test_that("provisional constants are reported, not silently used", {
  prov <- ccx_check_constants(quiet = TRUE)
  expect_true(is.character(prov))
  # This is a LEDGER, not a pass/fail: it records which constants still need
  # sourcing. Update the expected set deliberately when one is retired.
  # D14C_PI was RETIRED from this list on 2026-08-10 (IntCal20 supplied +2.16
  # per mil, replacing a 0-by-construction placeholder). The ledger failing on a
  # retirement is the intended behavior -- it forces the update to be deliberate.
  # ADDED 2026-08-16 with the biological pump (task 9): the two 13C
  # fractionations on the export limbs. Both are recollected working values --
  # ~20-22 permil depletion for marine organic matter, a small positive offset
  # for biogenic CaCO3 -- and neither has a citation yet. They are the pump's
  # only uncited numbers: its export FIELD is solved from GLODAP and its
  # carbonate SHARE is pinned by GLODAP's alkalinity gradient.
  # ADDED 2026-08-20k: NPP_FRAC_NH_ANCHOR_1750. It is NOT provisional for want
  # of a source -- MOD17 is its source and NPP_FRAC_NH_OBS is `data`. It is
  # provisional because it is the OBSERVATION INVERTED THROUGH THE MODEL's own
  # clearing, so it rides on `luc_scale` and the land turnover times. The ledger
  # is the right place for that: it keeps a model-dependent prior center
  # visible. Its dependence is priced in calibration/diag_npp_frac_anchor.R and
  # is an order of magnitude below the prior width.
  # ADDED 2026-09-02 with the temperature-dependent air-sea 13C pair, and the
  # ledger fired on all three, which is the mechanism working: registering a
  # provisional constant has to be deliberate.
  #   ALPHA_AS_FCO3 -- the surface carbonate fraction is HELD rather than solved
  #     per step. Not provisional for want of a source (it is measured at the
  #     mode's own surface state and sits inside Zhang's stated 0.05-0.20) but
  #     because it is an APPROXIMATION: carrying it properly means [CO3=]/DIC
  #     from the carbonate solve on both the R and C++ paths. Priced in
  #     R/constants.R -- 0.020 permil of an ~8.7 permil offset, 1 % of the slope.
  #   ALPHA_AS_DOWN_LEGACY / _UP_LEGACY -- the RETIRED scalars, kept so
  #     `alpha_as_tdep = 0` reproduces the pre-09-02 model bit for bit. They are
  #     provisional in the ledger's exact sense: they never had a source, which
  #     is why they were replaced. ⚠ They are the ONE case here where being on
  #     this list is not a debt to pay down -- the debt was paid by measuring
  #     them, and they survive only as a reproduction path.
  # ADDED 2026-09-02 with the SPO seasonal-partition registry. SIX entries, and
  # the ledger fired on all six -- again the mechanism working. Same standing as
  # NPP_FRAC_NH_ANCHOR_1750 and for the same reason: the land limb, the ocean
  # limb, their phases and the phase's bootstrap bounds are OBSERVATIONS
  # INVERTED THROUGH THE MODEL's own d13C signatures, so they carry a model
  # dependence that the ledger is the right place to keep visible. Measured, it
  # is small -- re-inverting at a different `tau_ex` moved the land limb -1 %.
  # ⚠ The TOTAL, SPO_SEAS_AMP_OBS, is deliberately NOT on this list: the
  # inversion closes CO2 = L + O on the observed total, so no model enters it,
  # and it was re-measured model-free on 2026-09-02 at 1.1684.
  # ADDED 2026-09-03 with the entrainment prior. ENT_SEAS_BAND_AREA_FRAC is the
  # 40-90 S ocean area as a fraction of SH ocean area, and it is provisional for
  # the plainest reason on this list: it is a GEOGRAPHIC ratio with no cited
  # source, exactly as OCEAN_AREA_NH/SH are. It was a free-floating literal in
  # three files until the provenance audit; registering it is what let the two
  # entrainment constants be COMPUTED rather than typed, and it also sets the
  # prior WIDTH (1/it is the no-dilution ceiling). ⚠ So both ENT_SEAS_AMP_SH_*
  # inherit this debt even though they are labeled "derived" -- the ledger is
  # the right place for that to stay visible.
  # ADDED 2026-09-14 g: ALPHA_PHOTO_EPS. The -18 permil terrestrial photosynthetic
  # discrimination had been a literal in ccx_prepare()'s aux for the model's
  # whole life, outside this ledger, citing a constants note that did not exist.
  # Registered at its value with the source (Lloyd & Farquhar 1994: C3 17.8,
  # total 14.8 at 25 % C4); PROVISIONAL because the value in use is the C3-only
  # one and the biosphere-wide revision belongs to the next refit.
  # RETIRED 2026-09-21 h: SST_PCO2_SENSITIVITY -- cited (Takahashi et al. 1993, GBC 7(4)
  # 843-878, doi:10.1029/93GB02263, 0.0423 +- 0.0002 per degC); status "data". The
  # freeze pass's one quick fix among the provisional set; the other fourteen are
  # provisional for the reasons recorded above (inverted through the model, held, a
  # C3-only value, no citation yet), none a lookup.
  # RETIRED 2026-09-21 h (the freeze's citation pass): OCEAN_AREA_NH / _SH (Pidwirny's
  # 60.7 / 80.9 %; the pair = Eakins & Sharman 2010 to 0.2 %) and RHO_SEAWATER (EOS-80)
  # -- each cited at the value it always had. OCEAN_DEPTH stays: the cited 3690 is 0.3 %
  # off the working 3700 and the value is a model change. ALK_SURFACE / NPP_GLOBAL_PI /
  # PUMP_EPS13_* stay: no source found in the pass that pins the working value.
  expect_setequal(prov, c("OCEAN_DEPTH", "ALPHA_PHOTO_EPS",
                          "ALK_SURFACE", "PUMP_EPS13_ORG", "PUMP_EPS13_CARB",
                          "NPP_GLOBAL_PI",
                          "NPP_FRAC_NH_ANCHOR_1750",
                          "ALPHA_AS_FCO3",
                          "ALPHA_AS_DOWN_LEGACY", "ALPHA_AS_UP_LEGACY",
                          "ENT_SEAS_BAND_AREA_FRAC"))
})

test_that("the RETIRED roster is exactly the two-signature inversion's outputs", {
  # ⛔ RETIRED 2026-09-04h. These six were the inversion's outputs and they were
  # PROVISIONAL until the method that produced them stopped working: the
  # 2026-09-02 temperature-dependent air-sea 13C alphas make the ocean limb's
  # isotopic signature ROTATE seasonally, so it is not the signed SCALAR the
  # inversion assumes, all four ocean channels fail its own antiphase gate, and
  # diag_seas_signature_inversion.R ERRORS at the canonical mode.
  #
  # THE ROSTER IS ASSERTED, NOT COUNTED, for the reason the whole file exists:
  # retiring a constant must be a deliberate, listed act. If a SEVENTH thing is
  # ever retired this fails and someone has to say why -- and, just as
  # important, if one of these is quietly un-retired and pressed back into
  # service as a target, this fails too.
  ret <- names(CCX_CONSTANTS)[vapply(CCX_CONSTANTS,
                                     function(k) identical(k$status, "retired"), TRUE)]
  expect_setequal(ret, c("SPO_SEAS_AMP_LAND_INV", "SPO_SEAS_AMP_OCEAN_INV",
                         "SPO_SEAS_LAND_PHASE_INV", "SPO_SEAS_OCEAN_PHASE_INV",
                         "SPO_SEAS_OCEAN_PHASE_INV_LO",
                         "SPO_SEAS_OCEAN_PHASE_INV_HI"))
  # ⚠ SPO_SEAS_AMP_OBS is NOT retired and must not be: the inversion closes
  # CO2 = L + O on the observed TOTAL, so no model enters it. It survives the
  # method that produced its siblings.
  expect_identical(CCX_CONSTANTS$SPO_SEAS_AMP_OBS$status, "data")
  # every retirement must SAY it is retired, in its own source string
  for (nm in ret)
    expect_match(CCX_CONSTANTS[[nm]]$source, "RETIRED", info = nm)
})

test_that("PUMP_GRAD_OBS IS the shipped ocean_grad_dic target, not a copy of it", {
  # PROMISED BY R/constants.R AND WRITTEN 2026-08-16e (handoff 16d sec.4 flagged
  # it as the one piece of the pump wiring left undone).
  #
  # `PUMP_GRAD_OBS` is the prior CENTER for the fitted `pump_grad`, and it is the
  # same observation the `ocean_grad_dic` likelihood row scores -- a deliberate,
  # documented mild double-count. That is only defensible while the two are the
  # SAME NUMBER: if the target is ever re-derived (different depth bins, a newer
  # GLODAP release, a different area weighting) and the constant is not, the
  # prior would start pulling the parameter away from the row that scores it,
  # silently and in a direction nobody chose. Hence a hard tie rather than a
  # comment.
  tg <- ccx_ocean_gradient_target()
  skip_if(is.null(tg) || is.null(tg$dic), "GLODAPv2 gradient block absent")
  expect_equal(ccx_const("PUMP_GRAD_OBS"), tg$dic$target, tolerance = 1e-9)
  # ...and it is `status = "data"`, so ccx_check_constants() must NOT be
  # reporting it as provisional -- the pump's magnitude prior is anchored on an
  # observation, which is the whole argument for centering it there.
  expect_false("PUMP_GRAD_OBS" %in% ccx_check_constants(quiet = TRUE))
})
