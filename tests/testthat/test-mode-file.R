# =====================================================================
# test-mode-file.R -- THE CANONICAL MODE IS NAMED IN EXACTLY ONE PLACE.
#
# WHY THIS EXISTS. Until 2026-08-27 the adopted mode's path was a LITERAL,
# written out independently in ccx_load_mode(), in app/global.R, and in ~35
# diagnostics that never went through ccx_load_mode() at all. When the
# 2026-08-25f seasonal-NEP isotope fix (`6bda464`) changed the objective and
# quarantined every pre-fix vector, that meant 37 separate edits -- and 37
# chances to leave one pointing at a vector fitted on a different objective.
#
# THE DANGEROUS FAILURE IS NOT A MISSING FILE. A missing file is loud. The
# failure this guards is a diagnostic that still RESOLVES, silently, to a
# quarantined mode and prints its numbers as current. app/global.R makes that
# concrete: a path that resolves to nothing fails silently there by design (the
# banner is the only report), which is how the app shipped uncalibrated
# defaults for weeks.
#
# A helper nobody is forced to use would not stop this coming back. The lint
# does: it fails on the LITERAL, wherever it is written. Same construction, and
# for the same reason, as test-luc-scale.R's two-statement lint.
# =====================================================================

test_that("no live source hardcodes a fitted-mode path", {
  root  <- ccx_root()
  files <- c(list.files(file.path(root, "R"),           "\\.R$", full.names = TRUE),
             list.files(file.path(root, "calibration"), "\\.R$", full.names = TRUE),
             list.files(file.path(root, "app"),         "\\.R$", full.names = TRUE))
  # SCOPE. This lints the path of the ADOPTED mode -- the retired `pump_arms`
  # directory and the post-fix refit directories that CCX_MODE_FILES names. It
  # deliberately does NOT lint the other arms (`ridge_pin*`, `luc_arm_*`,
  # `ocean_probe_scan/*`, the sink arms): those are their own scratch runs, are
  # not resolvable through ccx_mode_file(), and naming them is correct.
  #
  # EXEMPTIONS, declared rather than pattern-matched so a third one is a
  # visible decision:
  #   paths.R                     -- IS where the canonical mode is named.
  #   diag_gates_at_landed_modes.R -- points at the quarantine ON PURPOSE; it is
  #                                  the pre-fix-vs-post-fix comparison, so its
  #                                  "before" side must name a quarantined file.
  #   run_modefind_pump_arms.R    -- the DRIVER. It WRITES these files; a writer
  #                                  cannot resolve its output through a reader.
  #   finish_pump_arms_comparison.R, repair_arm_streams.R -- ditto, they rebuild
  #                                  or repair arm files in place.
  #   diag_hml_seasonal_limbs.R   -- a DECLARED TWO-MODE COMPARISON (added
  #                                  2026-08-29). It measures the OLD h_ml mode
  #                                  (96.47 m) against the NEW one (35.38 m), so
  #                                  it needs BOTH paths at once, and
  #                                  ccx_mode_file() returns exactly ONE mode by
  #                                  construction -- it cannot express a
  #                                  comparison. Same category as
  #                                  diag_gates_at_landed_modes.R above.
  #                                  ⚠ THE COST OF THIS MECHANISM: an exemption
  #                                  is per FILE, so a careless hardcode
  #                                  elsewhere in an exempt file also passes.
  #                                  That is the price of "declared rather than
  #                                  pattern-matched"; a sixth entry should
  #                                  prompt a per-LINE marker instead.
  allowed <- c("paths.R", "diag_gates_at_landed_modes.R",
               "run_modefind_pump_arms.R", "finish_pump_arms_comparison.R",
               "repair_arm_streams.R", "diag_hml_seasonal_limbs.R")
  dirs <- c("pump_arms", basename(dirname(CCX_MODE_FILES)))
  rx   <- sprintf('"[^"]*(%s)[^"]*mode_fit_pump', paste(dirs, collapse = "|"))
  offenders <- character()
  for (f in files) {
    if (basename(f) %in% allowed) next
    L <- readLines(f, warn = FALSE)
    hits <- grep(rx, L)
    hits <- hits[!grepl("^\\s*#", L[hits])]      # a comment naming it is history
    for (j in hits) offenders <- c(offenders, sprintf("%s:%d", basename(f), j))
  }
  expect_equal(offenders, character(),
               info = paste("hardcoded mode path -- use ccx_mode_file():",
                            paste(offenders, collapse = ", ")))
})

test_that("ccx_mode_file refuses the quarantined arm names WITH THE REASON", {
  # A file-not-found would be loud but uninformative, and would invite someone
  # to "fix" it by pointing at the quarantine directory -- which is exactly the
  # move the quarantine exists to prevent. The error has to carry why.
  #
  # ASSERTED PER ARM AGAINST ITS OWN REGISTRY ENTRY, not against one shared
  # literal. Until 2026-08-28 this checked every arm for the string "6bda464",
  # which was right only while a SINGLE objective change had retired all of
  # them. Option 5 (2026-08-28) is a second one, with a different cause commit
  # and a different quarantine directory, so a shared-literal test would have
  # forced the next retirement to either state the wrong cause or edit the test
  # -- and "edit the test" is how the reason quietly stops being carried at all.
  # What is required of an entry is therefore structural: it must name WHERE the
  # vector went and WHICH commit caused it, whatever those are for that arm.
  for (a in names(CCX_MODE_RETIRED)) {
    e <- tryCatch({ ccx_mode_file(a); NULL }, error = function(e) conditionMessage(e))
    expect_true(!is.null(e), info = paste("retired arm", a, "resolved"))
    expect_match(e, CCX_MODE_RETIRED[[a]], fixed = TRUE,
                 info = paste("arm", a, "error does not carry its OWN reason"))
    expect_match(CCX_MODE_RETIRED[[a]], "quarantine/", fixed = TRUE,
                 info = paste("arm", a, "reason does not say WHERE it was quarantined"))
    expect_match(CCX_MODE_RETIRED[[a]], "`[0-9a-f]{7,}`",
                 info = paste("arm", a, "reason does not name the CAUSE commit"))
  }
  expect_error(ccx_mode_file("no_such_arm"), "unknown mode")
  expect_error(ccx_mode_file(c("from90", "pin90")), "ONE mode name")
})

test_that("every named mode is on disk and carries the 21-parameter set", {
  for (a in names(CCX_MODE_FILES)) {
    f <- ccx_mode_file(a)
    expect_true(file.exists(f), info = paste("mode", a, "is named but missing:", f))
    md <- readRDS(f)
    expect_identical(md$param_names, CCX_PARAM_NAMES,
                     info = paste("mode", a, "was fitted on a different parameter set"))
    # THE BAND IS PART OF THE VECTOR'S PROVENANCE, not housekeeping: the driver
    # overrides CCX_PARAM_TABLE$h_ml in-process, and a logpost recomputed under
    # the default band is off by ~1.1 (memory ccx_hml_band_provenance).
    expect_false(is.null(md$hml_bound),
                 info = paste("mode", a, "does not record its h_ml band"))
  }
})

test_that("the canonical mode is a FREE arm, and stored logposts do not decide it", {
  # THE TRAP THIS ENCODES. `pin90`'s STORED logpost is HIGHER than the canonical
  # mode's, and a reader comparing the two numbers picks the wrong arm. The
  # pinned arm's objective carries a near-delta prior on `fert_k` worth
  # +11.6698 at fert_k = 90; on the comparable scale it is 11.56 BELOW. The
  # project rule is "the highest FREE arm wins regardless of name", so what is
  # asserted here is that the canonical mode is FREE -- not that its stored
  # number is the largest, which it is not.
  expect_true(CCX_MODE_CANONICAL %in% names(CCX_MODE_FILES))
  expect_setequal(names(CCX_MODE_PINNED), names(CCX_MODE_FILES))
  expect_false(CCX_MODE_PINNED[[CCX_MODE_CANONICAL]])

  lp <- vapply(names(CCX_MODE_FILES),
               function(a) readRDS(ccx_mode_file(a))$logpost, numeric(1))
  free <- names(CCX_MODE_FILES)[!CCX_MODE_PINNED[names(CCX_MODE_FILES)]]
  expect_equal(CCX_MODE_CANONICAL, free[which.max(lp[free])])

  # ⚠ REWRITTEN 2026-08-29 -- THE PREMISE, NOT THE TOLERANCE. What stood here was
  #     expect_gt(lp[["pin90"]], lp[[CCX_MODE_CANONICAL]])
  # on two STORED logposts, and across an objective change that is not merely
  # false, it is MEANINGLESS. The MARGIN measures how meaningless: the stored
  # ordering favours pin90 by only +0.113, while the option-5 change (`2153bd6`)
  # moved logposts by 0.081 -- measured at four separate points, collect
  # 2026-08-29. A third objective change of that size FLIPS this assertion, and
  # the old comment would then have read the flip as "the trap has become safe"
  # when only the units moved. A test whose failure message is a false
  # explanation is worse than no test.
  #
  # THE PREMISE RESTATED. The TRAP is that a reader compares STORED numbers.
  # The TRUTH is what the arms are worth on ONE objective. Both are asserted
  # below; only the second is load-bearing, because it is a GAP between two
  # vectors scored by the SAME harness in the SAME session, so whatever the
  # objective is, it cancels.
  expect_gt(lp[["pin90"]] - lp[[CCX_MODE_CANONICAL]], 0)   # the trap is LIVE

  skip_if_no_cpp()
  # PIN_PRIOR_CREDIT is the near-delta fert_k prior at fert_k = 90 that the
  # pinned arm's objective carries and the free arm's does not. Asserting the
  # recomputed gap EQUALS it is asserting the MECHANISM -- so this fails if the
  # trap's cause changes, and not merely if two numbers cross.
  # =================================================================
  # ⚠ THIS ASSERTION IS FAILING ON PURPOSE AS OF 2026-08-30. DO NOT "FIX" IT.
  #
  # Marcus's ruling: leave it failing and re-measure after the owed 21-param
  # refit. It is recorded here so the next session does not re-derive it or
  # mistake it for the bookkeeping it is not.
  #
  # WHAT IT IS NOT. Handoff 2026-08-30 sec.4 filed this as "stored logpost
  # changed, refresh provenance". The STORED-logpost assertion above (the
  # `lp[["pin90"]] - lp[[...]] > 0` line) PASSES. What fails is the RECOMPUTED
  # gap below -- the one this file's own comment argues is objective-INdependent
  # "because it is a GAP between two vectors scored by the SAME harness, so
  # whatever the objective is, it cancels".
  #
  # WHY THAT ARGUMENT DOES NOT COVER THIS CHANGE. It holds for an objective
  # change that is a COMMON SHIFT. gamma_diff = 0.25 is not one: it changes the
  # MODEL, and the two arms sit at different fert_k, so they pay different
  # amounts for the same mechanism. Measured over gamma = 0 / 0.125 / 0.25
  # (calibration/diag_attribute_the_seven.R part 5):
  #
  #     gap = -11.4936  /  -14.8961  /  -19.8635
  #
  # PIN_PRIOR_CREDIT is a PRIOR term -- the near-delta fert_k prior at 90 --
  # and carries no gamma_diff dependence at all, so the entire +8.4 movement is
  # a LIKELIHOOD differential: diffuse light costs the pinned arm more than the
  # canonical one. That is a finding about the two arms, not drift in a
  # provenance number, and the test caught exactly what it says it exists to
  # catch ("this fails if the trap's CAUSE changes").
  #
  # WHY IT IS NOT RESOLVED NOW. Both arms are PRE-adoption vectors read under a
  # POST-adoption objective, so the gap is provisional whichever way it is
  # written; re-deriving PIN_PRIOR_CREDIT from them would bake in a number
  # measured on vectors that are about to be replaced. (Sanity check that the
  # harness is sound rather than the vectors: the canonical arm's own frozen
  # price is -40.49 across the adoption, which reproduces the recorded "the
  # frozen column overstated the price by 82 %" -- 7.42 / 0.18 = 41.2.)
  # =================================================================
  PIN_PRIOR_CREDIT <- 11.6698
  band0 <- CCX_PARAM_TABLE$h_ml
  on.exit(CCX_PARAM_TABLE$h_ml <<- band0, add = TRUE)
  now <- vapply(names(CCX_MODE_FILES), function(a) {
    md <- readRDS(ccx_mode_file(a))
    ccx_adopt_mode_band(md)          # each arm decodes under its OWN band
    bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
    ccx_make_logpost(years = c(1750, 2024), base_params = bp)(md$u_mode)
  }, numeric(1))
  expect_lt(now[["pin90"]] - now[[CCX_MODE_CANONICAL]], 0)
  expect_equal(now[["pin90"]] - now[[CCX_MODE_CANONICAL]], -PIN_PRIOR_CREDIT,
               tolerance = 0.2,
               info = "the canonical arm's advantage on ONE objective is no longer the pin's prior credit")
})
