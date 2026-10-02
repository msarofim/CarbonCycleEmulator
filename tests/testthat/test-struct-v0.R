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

# ---- hilda_csl3v0k: the fert_k SHAPE prior (2026-09-28) ------------------------
test_that("hilda_csl3v0k is hilda_csl3v0 plus the prior flag, and nothing else", {
  a <- ccx_struct_block("hilda_csl3v0"); b <- ccx_struct_block("hilda_csl3v0k")
  expect_identical(setdiff(names(b), names(a)), "fert_k_prior")
  expect_identical(b[names(a)], a)
  expect_identical(b$fert_k_prior, 1L)
})

test_that("fert_k's prior is FLAT unless the label switches it on", {
  s <- CCX_PARAM_TABLE$fert_k; x <- c(100, 546, 900, 1900)
  flat <- dunif(x, 20, 2000, log = TRUE)
  expect_identical(vapply(x, function(v) .ccx_prior_eval(s, v, NULL), 0), flat)
  expect_identical(vapply(x, function(v) .ccx_prior_eval(s, v, ccx_default_params()), 0), flat)
  # the labels that switch the prior ON: hilda_csl3v0k and the NPP option-4 arms built on it
  # (A = hilda_csl3v0ka, B1 = hilda_csl3v0kan; 2026-09-29, extension authorised by Marcus)
  # + arm A's inert-pool label (hilda_csl3v0kai; 2026-09-30, extension authorised by Marcus)
  # + the D2 / D3 label chained from it (hilda_csl3v0kaidgb; 2026-09-30, objective #14; the
  #   09-30c handoff's "extend the label ledgers deliberately")
  # + the land ENSO lag label chained from THAT (hilda_csl3v0kaidgbe; 2026-10-02, objective #15;
  #   the 10-02 plan's "extend the four label ledgers")
  PRIOR_ON <- c("hilda_csl3v0k", "hilda_csl3v0ka", "hilda_csl3v0kan", "hilda_csl3v0kai", "hilda_csl3v0kaidgb",
                "hilda_csl3v0kaidgbe")
  for (lab in PRIOR_ON) expect_identical(ccx_struct_block(lab)$fert_k_prior, 1L, info = lab)
  for (lab in setdiff(CCX_STRUCT_LABELS, PRIOR_ON)) {
    p <- ccx_apply_structure(ccx_default_params(), lab, seas_ml = "0")
    expect_identical(vapply(x, function(v) .ccx_prior_eval(s, v, p), 0), flat, info = lab)
  }
  p <- ccx_apply_structure(ccx_default_params(), "hilda_csl3v0k", seas_ml = "1")
  pr <- ccx_fert_k_prior()
  got <- vapply(x, function(v) .ccx_prior_eval(s, v, p), 0)
  expect_equal(got, dlnorm(x, log(pr$median_ppm), pr$log_sd, log = TRUE))
  # MUTATION: the prior must actually prefer the evidence (546) over the log-like fits (900)
  expect_gt(got[2], got[3])
})

test_that("the prior file carries its two sources and reproduces its median", {
  pr <- ccx_fert_k_prior()
  expect_true(all(c("varney", "walker") %in% names(pr$sources)))
  expect_equal(pr$median_ppm, exp(mean(log(c(pr$K_walker, pr$K_varney)))))
  expect_equal(pr$log_sd, 0.35)
  expect_gt(pr$K_walker, 400); expect_lt(pr$K_walker, 700)
  expect_gt(pr$K_varney, 400); expect_lt(pr$K_varney, 700)
})
