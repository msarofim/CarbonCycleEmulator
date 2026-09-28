# test-struct-v0.R -- the "hilda_csl3v0" label (2026-09-28): hilda_csl3 with the
# vegetation-capacity loop OFF. The label is what carries the setting into every
# mode file and back out through ccx_mode_base(), so it is tested as a LABEL.

test_that("hilda_csl3v0 is hilda_csl3 plus npp_veg_frac = 0, and nothing else", {
  a <- ccx_struct_block("hilda_csl3"); b <- ccx_struct_block("hilda_csl3v0")
  expect_identical(setdiff(names(b), names(a)), "npp_veg_frac")
  expect_identical(b[names(a)], a)
  expect_identical(b$npp_veg_frac, 0)
  # the shipped default is 0.5; a label that equalled it would test nothing
  expect_false(identical(ccx_default_params()$npp_veg_frac, 0))
})

test_that("the label reaches the model's parameters, and the old label is untouched", {
  p0 <- ccx_apply_structure(ccx_default_params(), "hilda_csl3", seas_ml = "1")
  p1 <- ccx_apply_structure(ccx_default_params(), "hilda_csl3v0", seas_ml = "1")
  expect_identical(p1$npp_veg_frac, 0)
  expect_identical(p0$npp_veg_frac, ccx_default_params()$npp_veg_frac)
  expect_identical(attr(p1, "struct"), "hilda_csl3v0")
  expect_identical(p0[setdiff(names(p0), "npp_veg_frac")], p1[setdiff(names(p1), "npp_veg_frac")])
})
