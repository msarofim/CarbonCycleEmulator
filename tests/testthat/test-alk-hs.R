# =====================================================================
# `alk_hs` -- the cold box's own alkalinity (T-ALK, 2026-09-08g).
#
# A default-off switch is untested where it matters
# ([[default_off_hides_the_bug]]), so: (1) ABSENT is bit-exact with the
# explicit global constant in both cores; (2) an EXPLICIT lower value lowers
# the HS DIC at the same pCO2, in the spinup and in the transient; (3) the two
# cores agree to roundoff AT the explicit value; (4) it errors by name.
# =====================================================================

test_that("alk_hs ABSENT is bit-exact with the global constant, and an explicit value is felt in BOTH cores", {
  skip_if_no_cpp()
  p0 <- ccx_apply_structure(ccx_default_params(), "hilda")
  p1 <- p0; p1$alk_hs <- ccx_const("ALK_SURFACE")
  s0 <- ccx_spinup(p0); s1 <- ccx_spinup(p1)
  expect_identical(s0$y, s1$y)
  expect_identical(s0$aux$dic0_hs, s1$aux$dic0_hs)
  F <- ccx_build_forcing("historical", c(1750, 1800), prod_c14 = s0$prod_c14)
  o0 <- ccx_run_fast(s0, F)$out; o1 <- ccx_run_fast(s1, F)$out
  expect_identical(o0, o1)

  # an explicit LOWER alkalinity: lower HS DIC at the same PI pCO2
  p2 <- p0; p2$alk_hs <- ccx_const("ALK_SURFACE") - 44e-6
  s2 <- ccx_spinup(p2)
  expect_lt(s2$aux$dic0_hs, s0$aux$dic0_hs)
  for (h in HEMIS) expect_lt(s2$y[s2$aux$idx[[h]]$hs, "C"], s0$y[s0$aux$idx[[h]]$hs, "C"])
  # ...and the LS mixed layer's own PI reference is untouched
  expect_identical(s2$aux$dic0, s0$aux$dic0)

  # the transient feels it, and the two cores agree AT the explicit value
  # the pure-R carbonate path WARNS below its 2 C fit range (the cold box at sst_hs 2 + a negative
  # anomaly); pre-existing behaviour of ccx_run() under the HILDA structure, not this switch's
  rC <- ccx_run_fast(s2, F); rR <- suppressWarnings(ccx_run(s2, F))
  expect_gt(max(abs(rC$out$hs_C_SH - o0$hs_C_SH)), 1e-6)
  expect_lt(max(abs(rR$out$hs_C_SH - rC$out$hs_C_SH)) / max(abs(rC$out$hs_C_SH)), 1e-12)
  expect_lt(max(abs(rR$out$co2_NH  - rC$out$co2_NH))  / max(abs(rC$out$co2_NH)),  1e-13)
  expect_lt(max(abs(rR$out$d13c_SH - rC$out$d13c_SH)), 1e-9)

  # errors by name, never clamps
  p3 <- p0; p3$alk_hs <- -1
  expect_error(ccx_prepare(p3), "alk_hs")
  p4 <- p0; p4$alk_hs <- NA_real_
  expect_error(ccx_prepare(p4), "alk_hs")
})
