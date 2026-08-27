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
  allowed <- c("paths.R", "diag_gates_at_landed_modes.R",
               "run_modefind_pump_arms.R", "finish_pump_arms_comparison.R",
               "repair_arm_streams.R")
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
  for (a in names(CCX_MODE_RETIRED)) {
    e <- tryCatch({ ccx_mode_file(a); NULL }, error = function(e) conditionMessage(e))
    expect_true(!is.null(e), info = paste("retired arm", a, "resolved"))
    expect_match(e, "quarantine", info = paste("arm", a, "error omits the reason"))
    expect_match(e, "6bda464",   info = paste("arm", a, "error omits the fix commit"))
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
  # and the trap is REAL, not hypothetical -- if this ever stops holding, the
  # comment above is stale and the naive comparison has become safe.
  expect_gt(lp[["pin90"]], lp[[CCX_MODE_CANONICAL]])
})
