# =====================================================================
# Gate: the NUMBERS typed into the Known-issues copy stay true of the canonical (2026-10-06).
#
# WHY. app/R/review.R is sourced before the model's R/ files, so its prose cannot read the fit at load
# time, and test-app-review-copy pins the WORDS, not whether they are still true. Two of Marcus's
# 10-06 rulings put fitted numbers into that prose:
#   card 4 (carbotopecomments.10.2.26, his wording): the land's ENSO response "is defined to occur 2.5
#     months after the index" -- the canonical FITS it (hilda33p 2.606 +/- 0.407 months);
#   card 7 ("Add a line about k_w to the known issues tab"): the gas transfer speed "comes out at about
#     1,900 m per year, against the literature's 1,446" -- hilda33p 1894.7 +/- 53.7; the prior center.
#     2026-10-13 (g): "about 1,850" (Marcus) -- hilda31w 1835.4 +/- 52.5.
# THE TOLERANCE IS EACH FIT'S OWN POSTERIOR SD (the Laplace marginal on the natural scale, by the delta
# method through the parameter's transform), never a hand-picked band: a refit that moves the value more
# than one sd from the typed number makes the card false, and this is what says so. The literature
# number is tied EXACTLY to the constant it quotes.
# The canonical is read through ccx_mode_base() (test-mode-struct-lint's resolver): the value checked is
# the one the model RUNS, not a field of the file.
#
# ⛔ RE-EXPRESSED 2026-10-08 (g) (Marcus: "Both, now"). Card 4's lag tests used to open with
# skip_if(!"lag_enso_land" %in% md$param_names), so hilda29e -- which PINS the lag (the interannual cut's module,
# 5.93 months) -- made them SKIP, not fail, while the card said 2.5. They now read the lag the canonical RUNS,
# fitted OR pinned: a fitted lag's sd is the mode's Laplace marginal, a pinned one's is the module's own Laplace
# (CCX_MODE_CANONICAL_MODULE_CHECK, gated on md5 to the canonical's mode file). A lag neither fitted nor held is
# an ERROR, not a skip. And card 4's "a little below the range" -- described in review.R since 10-01 as recomputed
# by a test that was never written -- is now that test. Both FAIL at hilda29e until card 4's copy changes.
# =====================================================================

rcn_review_text <- function() paste(readLines(file.path(ccx_root(), "app", "R", "review.R"), warn = FALSE),
                                    collapse = "\n")

# review.R's constants and functions (RV_CARDS, RV_ENSO_L2_VS_OBS, rv_enso_l2_relation, rv_enso_l2_bracket): it
# defines only constants and functions at load time, so it sources without the app (test-review-cards.R's pattern)
.rcn_rv <- new.env(parent = environment())
sys.source(file.path(ccx_root(), "app", "R", "review.R"), envir = .rcn_rv)

# card 4's typed values -- they change in the SAME commit as the copy
# 2026-10-15 (Marcus: "Apply minimal factual fixes"): 2.5 -> "about six" (hilda31w holds 5.93 +/- 1.21).
RCN_CARD4_LAG      <- 6
RCN_CARD4_LAG_TEXT <- "about six months after the index"

# The land ENSO lag the canonical RUNS and its sd, fitted OR pinned (`how`). For a pinned lag, `md5` / `base_lag`
# are what the caller must check: the module check was taken AT this mode file, AT this lag.
rcn_lag <- function(md, run, module_check = CCX_MODE_CANONICAL_MODULE_CHECK) {
  if ("lag_enso_land" %in% md$param_names)
    return(list(how = "fitted", value = run$lag_enso_land,
                sd = rcn_sd_nat(md, "lag_enso_land", CCX_PARAM_GATED_ALL$lag_enso_land)))
  if (!"lag_enso_land" %in% names(md$pins))
    stop("rcn_lag: the canonical neither fits nor holds lag_enso_land, and card 4 quotes one")
  mc <- readRDS(file.path(ccx_root(), module_check))
  list(how = "pinned", value = run$lag_enso_land, sd = mc$laplace$sd[["L"]],
       md5 = c(check_base = mc$provenance$base_md5, mode_file = unname(tools::md5sum(ccx_mode_file()))),
       base_lag = mc$base_values[["L"]])
}
rcn_card4_detail <- function() Filter(function(c) identical(c$id, 4), .rcn_rv$RV_CARDS)[[1]]$detail

# the natural-scale posterior sd of a fitted name: sd_unc through the transform's derivative at the mode
rcn_sd_nat <- function(md, name, spec) {
  x <- md$par_mode[[name]]; su <- md$sd_unc[[name]]
  switch(spec$tr,
         log   = x * su,
         logit = { p <- (x - spec$lo) / (spec$hi - spec$lo); (spec$hi - spec$lo) * p * (1 - p) * su },
         stop("rcn_sd_nat: no derivative coded for transform '", spec$tr, "'"))
}

test_that("card 4's lag is within ONE sd of the land ENSO lag the canonical RUNS, fitted OR pinned", {
  md <- readRDS(ccx_mode_file())
  run <- ccx_overlay_par(ccx_mode_base(md), md$par_mode)
  L <- rcn_lag(md, run)
  if (L$how == "fitted") {
    expect_equal(run$lag_enso_land, md$par_mode$lag_enso_land)        # the base runs the fitted value
  } else {
    expect_equal(run$lag_enso_land, md$pins[["lag_enso_land"]])       # ... or the held one
    expect_identical(L$md5[["check_base"]], L$md5[["mode_file"]])     # the sd was taken AT this mode file
    expect_lt(abs(L$base_lag - run$lag_enso_land), 1e-12)             # ... and at this lag
  }
  expect_gt(L$sd, 0)
  expect_lt(abs(L$value - RCN_CARD4_LAG), L$sd)
  expect_true(grepl(RCN_CARD4_LAG_TEXT, rcn_review_text(), fixed = TRUE))
})

test_that("card 4's 'a little <word> the range' is where the limb strength the canonical RUNS sits against the observed bracket", {
  md <- readRDS(ccx_mode_file())
  run <- ccx_overlay_par(ccx_mode_base(md), md$par_mode)
  expect_true("w_enso_l2" %in% c(md$param_names, names(md$pins)))     # a fitted or module-held strength, not a default
  br <- .rcn_rv$rv_enso_l2_bracket()
  expect_length(br, 2L)
  expect_identical(.rcn_rv$rv_enso_l2_relation(run$w_enso_l2, br), .rcn_rv$RV_ENSO_L2_VS_OBS)
  # the card renders THAT word (it is sprintf'd in at load, so read the built card, not the source text)
  # 2026-10-15: the card renders a PHRASE for the word ("inside" cannot follow "a little"), so check that phrase
  expect_true(grepl(sprintf("sits %s the range", .rcn_rv$rv_enso_l2_phrase(.rcn_rv$RV_ENSO_L2_VS_OBS)),
                    rcn_card4_detail(), fixed = TRUE))
})

test_that("card 7's k_w line: '1,446' IS the prior's centre, and 'about 1,850' is within one sd of the fit", {
  rv <- rcn_review_text()
  expect_identical(ccx_const("KW_PRIOR_CENTRE"), 1446)
  expect_true(grepl(sprintf("against the literature's %s", format(ccx_const("KW_PRIOR_CENTRE"), big.mark = ",")),
                    rv, fixed = TRUE))
  md <- readRDS(ccx_mode_file())
  run <- ccx_overlay_par(ccx_mode_base(md), md$par_mode)
  sd_nat <- rcn_sd_nat(md, "k_w", CCX_PARAM_TABLE$k_w)
  expect_gt(sd_nat, 0)
  expect_lt(abs(run$k_w - 1850), sd_nat)
  expect_true(grepl("about 1,850 m per year", rv, fixed = TRUE))
})

test_that("MUTATION: the one-sd rule FAILS a typed number the fit has left behind", {
  md <- readRDS(ccx_mode_file())
  run <- ccx_overlay_par(ccx_mode_base(md), md$par_mode)
  L <- rcn_lag(md, run)
  sd_kw <- rcn_sd_nat(md, "k_w", CCX_PARAM_TABLE$k_w)
  # the rule's boundary, at whatever the canonical runs: 0.99 sd passes, 1.01 sd fails
  expect_true(abs(L$value - (L$value + 0.99 * L$sd)) < L$sd)
  expect_false(abs(L$value - (L$value + 1.01 * L$sd)) < L$sd)
  # Naegler's 1,446 typed as the FITTED value fails: the fit is ~8 sd away
  expect_false(abs(md$par_mode$k_w - 1446) < sd_kw)
  expect_error(rcn_sd_nat(md, "k_w", list(tr = "identity")), "no derivative coded")
  # a lag neither fitted nor held is an ERROR, never a skip (the 10-08 (g) defect: the old guard skipped)
  md0 <- md; md0$param_names <- setdiff(md0$param_names, "lag_enso_land")
  md0$pins <- md0$pins[names(md0$pins) != "lag_enso_land"]
  expect_error(rcn_lag(md0, run), "neither fits nor holds")
})

test_that("MUTATION: a pinned lag's sd from ANOTHER mode's module check is caught", {
  md <- readRDS(ccx_mode_file())
  skip_if(!"lag_enso_land" %in% names(md$pins), "the canonical fits the lag: the module-check branch is not in use")
  run <- ccx_overlay_par(ccx_mode_base(md), md$par_mode)
  # #18 pass 1's check: taken at basin 1 BEFORE pass 2 (the source of the pins), so its base is another mode file
  L <- rcn_lag(md, run, module_check = CCX_MODE_OBJ18P2_MODULE_FILE)
  expect_false(identical(L$md5[["check_base"]], L$md5[["mode_file"]]))
})

test_that("MUTATION: the relation word has power on both sides of the bracket", {
  br <- .rcn_rv$rv_enso_l2_bracket()
  rel <- .rcn_rv$rv_enso_l2_relation
  expect_identical(rel(br[1] - 0.01, br), "below")
  expect_identical(rel(br[1] + 0.01, br), "inside")
  expect_identical(rel(br[2] + 0.01, br), "above")
  expect_identical(rel(11.91, br), "below")                 # hilda33d's value, where "below" was written (10-01)
  # a card rendering another word than the constant is caught by the built-card check
  expect_false(grepl("sits a little inside the range", rcn_card4_detail(), fixed = TRUE) &&
                 !identical(.rcn_rv$RV_ENSO_L2_VS_OBS, "inside"))
})
