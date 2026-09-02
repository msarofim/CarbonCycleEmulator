# =====================================================================
# Gate: constants provenance and internal consistency.
#
# Motivated by a real bug (2026-08-10): LAMBDA_C14 was written as the literal
# log(2)/5700 while being LABELLED "derived" from T_HALF_C14. Changing the
# half-life left the decay rate untouched, and a mutation test that swapped in
# the Libby 5568 yr value produced bit-identical output -- i.e. the decay gate
# was inert. These tests make that class of decoupling impossible to reintroduce.
# =====================================================================

test_that("every constant declares a status and a source", {
  for (nm in names(CCX_CONSTANTS)) {
    k <- CCX_CONSTANTS[[nm]]
    expect_true(!is.null(k$value),  info = nm)
    expect_true(!is.null(k$units),  info = nm)
    expect_true(k$status %in% c("derived", "cited", "data", "provisional"), info = nm)
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
  # retirement is the intended behaviour -- it forces the update to be deliberate.
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
  # is the right place for that: it keeps a model-dependent prior centre
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
  expect_setequal(prov, c("OCEAN_AREA_NH", "OCEAN_AREA_SH", "OCEAN_DEPTH",
                          "ALK_SURFACE", "PUMP_EPS13_ORG", "PUMP_EPS13_CARB",
                          "RHO_SEAWATER", "NPP_GLOBAL_PI",
                          "SST_PCO2_SENSITIVITY", "NPP_FRAC_NH_ANCHOR_1750",
                          "ALPHA_AS_FCO3",
                          "ALPHA_AS_DOWN_LEGACY", "ALPHA_AS_UP_LEGACY"))
})

test_that("PUMP_GRAD_OBS IS the shipped ocean_grad_dic target, not a copy of it", {
  # PROMISED BY R/constants.R AND WRITTEN 2026-08-16e (handoff 16d sec.4 flagged
  # it as the one piece of the pump wiring left undone).
  #
  # `PUMP_GRAD_OBS` is the prior CENTRE for the fitted `pump_grad`, and it is the
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
  # observation, which is the whole argument for centring it there.
  expect_false("PUMP_GRAD_OBS" %in% ccx_check_constants(quiet = TRUE))
})
