# =====================================================================
# test-npp-record.R -- the per-hemisphere NPP record (2026-09-29)
#
# The modern-NPP likelihood row (NPP_GLOBAL_PI option 4, Marcus 2026-09-29)
# reads NPP from the C++ core's `npp` matrix. For that number to be the model's
# NPP and not a second estimator:
#   1. the C++ and R cores agree to roundoff (hard rule 1);
#   2. both equal the flux recorder's `gpp - ra` (R/fluxes.R), the definition
#      diag_model_npp_modern.R measured with;
#   3. the columns are not transposed, and the record MOVES with ENSO and with
#      fertilisation (a record frozen at npp0 would pass 1 and fail 3).
# =====================================================================

p_npp <- local({ p <- ccx_default_params(); ccx_set_enso(p, list(gamma_enso = 0.5)) })
sp_npp <- ccx_spinup(p_npp)
F_npp  <- ccx_build_forcing("historical", c(1950, 1975), prod_c14 = sp_npp$prod_c14)

test_that("C++ and R NPP records agree to roundoff", {
  skip_if_no_cpp()
  rR <- ccx_run(sp_npp, F_npp)
  rC <- ccx_run_fast(sp_npp, F_npp)
  expect_identical(names(rC$npp), c("t", "npp_NH", "npp_SH"))
  for (cc in c("npp_NH", "npp_SH"))
    expect_lt(max(abs(rR$npp[[cc]] - rC$npp[[cc]])) / max(abs(rR$npp[[cc]])), 1e-13, label = cc)
  expect_identical(rC$npp$t, F_npp$t)
})

test_that("the record IS the flux recorder's gpp - ra", {
  r  <- ccx_run(sp_npp, F_npp, fluxes = TRUE)
  fl <- r$fluxes
  expect_lt(max(abs((r$npp$npp_NH + r$npp$npp_SH) - (fl$gpp - fl$ra))), 1e-10)
})

test_that("the record is hemispheric, not transposed, and it moves", {
  skip_if_no_cpp()
  rC <- ccx_run_fast(sp_npp, F_npp)
  # hemispheres sum to the 1750 constant's split, so the NH column carries npp_frac_NH
  frac <- rC$npp$npp_NH[1] / (rC$npp$npp_NH[1] + rC$npp$npp_SH[1])
  expect_lt(abs(frac - p_npp$npp_frac_NH), 0.05)
  # ENSO modulation makes month-to-month variation; fertilisation makes a trend
  expect_gt(stats::sd(diff(rC$npp$npp_NH)), 0)
  yr <- floor(rC$npp$t)
  expect_gt(mean(rC$npp$npp_NH[yr == 1975]), mean(rC$npp$npp_NH[yr == 1950]))
})
