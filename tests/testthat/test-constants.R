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
  expect_setequal(prov, c("D14C_PI", "OCEAN_AREA_NH", "OCEAN_AREA_SH", "OCEAN_DEPTH",
                          "ALK_SURFACE", "RHO_SEAWATER", "NPP_GLOBAL_PI",
                          "SST_PCO2_SENSITIVITY"))
})
