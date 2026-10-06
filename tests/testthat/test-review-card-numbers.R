# =====================================================================
# Gate: the NUMBERS typed into the Known-issues copy stay true of the canonical (2026-10-06).
#
# WHY. app/R/review.R is sourced before the model's R/ files, so its prose cannot read the fit at load
# time, and test-app-review-copy pins the WORDS, not whether they are still true. Two of Marcus's
# 10-06 rulings put fitted numbers into that prose:
#   card 4 (carbotopecomments.10.2.26, his wording): the land's ENSO response "is defined to occur 2.5
#     months after the index" -- the canonical FITS it (hilda33p 2.606 +/- 0.407 months);
#   card 7 ("Add a line about k_w to the known issues tab"): the gas transfer speed "comes out at about
#     1,900 m per year, against the literature's 1,446" -- hilda33p 1894.7 +/- 53.7; the prior centre.
# THE TOLERANCE IS EACH FIT'S OWN POSTERIOR SD (the Laplace marginal on the natural scale, by the delta
# method through the parameter's transform), never a hand-picked band: a refit that moves the value more
# than one sd from the typed number makes the card false, and this is what says so. The literature
# number is tied EXACTLY to the constant it quotes.
# The canonical is read through ccx_mode_base() (test-mode-struct-lint's resolver): the value checked is
# the one the model RUNS, not a field of the file.
# =====================================================================

rcn_review_text <- function() paste(readLines(file.path(ccx_root(), "app", "R", "review.R"), warn = FALSE),
                                    collapse = "\n")

# the natural-scale posterior sd of a fitted name: sd_unc through the transform's derivative at the mode
rcn_sd_nat <- function(md, name, spec) {
  x <- md$par_mode[[name]]; su <- md$sd_unc[[name]]
  switch(spec$tr,
         log   = x * su,
         logit = { p <- (x - spec$lo) / (spec$hi - spec$lo); (spec$hi - spec$lo) * p * (1 - p) * su },
         stop("rcn_sd_nat: no derivative coded for transform '", spec$tr, "'"))
}

test_that("card 4's '2.5 months' is within ONE posterior sd of the land ENSO lag the canonical runs", {
  md <- readRDS(ccx_mode_file())
  skip_if(!"lag_enso_land" %in% md$param_names, "the canonical does not fit the land ENSO lag")
  run <- ccx_overlay_par(ccx_mode_base(md), md$par_mode)
  expect_equal(run$lag_enso_land, md$par_mode$lag_enso_land)          # the base runs the fitted value
  sd_nat <- rcn_sd_nat(md, "lag_enso_land", CCX_PARAM_GATED_ALL$lag_enso_land)
  expect_gt(sd_nat, 0)
  expect_lt(abs(run$lag_enso_land - 2.5), sd_nat)
  expect_true(grepl("2.5 months after the index", rcn_review_text(), fixed = TRUE))
})

test_that("card 7's k_w line: '1,446' IS the prior's centre, and 'about 1,900' is within one sd of the fit", {
  rv <- rcn_review_text()
  expect_identical(ccx_const("KW_PRIOR_CENTRE"), 1446)
  expect_true(grepl(sprintf("against the literature's %s", format(ccx_const("KW_PRIOR_CENTRE"), big.mark = ",")),
                    rv, fixed = TRUE))
  md <- readRDS(ccx_mode_file())
  run <- ccx_overlay_par(ccx_mode_base(md), md$par_mode)
  sd_nat <- rcn_sd_nat(md, "k_w", CCX_PARAM_TABLE$k_w)
  expect_gt(sd_nat, 0)
  expect_lt(abs(run$k_w - 1900), sd_nat)
  expect_true(grepl("about 1,900 m per year", rv, fixed = TRUE))
})

test_that("MUTATION: the one-sd rule FAILS a typed number the fit has left behind", {
  md <- readRDS(ccx_mode_file())
  skip_if(!"lag_enso_land" %in% md$param_names, "the canonical does not fit the land ENSO lag")
  sd_lag <- rcn_sd_nat(md, "lag_enso_land", CCX_PARAM_GATED_ALL$lag_enso_land)
  sd_kw  <- rcn_sd_nat(md, "k_w", CCX_PARAM_TABLE$k_w)
  # the card-4 sentence's draft said "about three months" for a DIFFERENT quantity; typed here, it fails
  expect_false(abs(md$par_mode$lag_enso_land - 3.5) < sd_lag)
  # Naegler's 1,446 typed as the FITTED value fails: the fit is ~8 sd away
  expect_false(abs(md$par_mode$k_w - 1446) < sd_kw)
  expect_error(rcn_sd_nat(md, "k_w", list(tr = "identity")), "no derivative coded")
})
