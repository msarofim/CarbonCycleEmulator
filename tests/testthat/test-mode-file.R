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
  # ⚠ SCOPE DELIBERATELY UNCHANGED, and one attempt to widen it is recorded here
  # because the failure was instructive. On 2026-09-04 this list was extended to
  # cover every QUARANTINED arm directory, on the reasoning that retiring an arm
  # drops its directory out of the lint at exactly the moment a hardcode to it
  # becomes dangerous. That reasoning is right; the mechanism was wrong. Scanning
  # the quarantine pulls in `luc_arm_*`, `ridge_pin*` and the SINK arms -- the
  # scratch runs this lint's SCOPE paragraph above deliberately excludes -- so it
  # silently redefined what the lint is for. ⇒ The staleness question is a
  # DIFFERENT question and is asked separately, in the test below.
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

test_that("no live source names a mode-file path that has MOVED", {
  # ⭐ A DIFFERENT QUESTION FROM THE LINT ABOVE, and it needs to be. That one asks
  # "should this path go through ccx_mode_file()?" and is scoped to the REGISTRY
  # arms on purpose. This one asks "does this path still EXIST?", which is scoped
  # to nothing at all -- a scratch arm's path going stale is just as broken as a
  # canonical one's, and quarantining is precisely the operation that breaks them.
  #
  # WHY IT DID NOT EXIST BEFORE 2026-09-04: nothing had ever been adopted out of
  # a multistart, so no registry arm had moved since the lint above was written.
  # The `ent26` adoption moved two, and SEVEN live lines across four files went
  # stale with nothing reporting it. One of the seven --
  # diag_luc_arm_ridge_confound.R's `luc_arm_pinluc` -- had been stale since the
  # 2026-08-25 quarantine and no test had ever looked.
  root  <- ccx_root()
  files <- c(list.files(file.path(root, "R"),           "\\.R$", full.names = TRUE),
             list.files(file.path(root, "calibration"), "\\.R$", full.names = TRUE),
             list.files(file.path(root, "app"),         "\\.R$", full.names = TRUE))
  # run_post_refit_adoption.R holds string TEMPLATES it substitutes INTO
  # R/paths.R -- paths it WRITES, not paths it reads. Declared, not pattern-matched.
  allowed <- c("run_post_refit_adoption.R")
  rx <- '"((?:[^"]*/)?[^"]*mode_fit_pump[^"]*)"'
  stale <- character()
  for (f in files) {
    if (basename(f) %in% allowed) next
    L <- readLines(f, warn = FALSE)
    for (j in seq_along(L)) {
      if (grepl("^\\s*#", L[j])) next            # a comment naming a path is history
      m <- regmatches(L[j], gregexpr(rx, L[j], perl = TRUE))[[1]]
      for (q in m) {
        pth <- sub('^"(.*)"$', "\\1", q)
        if (!grepl("/", pth)) next                # a bare filename is a pattern, not a path
        if (!file.exists(file.path(root, pth)))
          stale <- c(stale, sprintf("%s:%d -> %s", basename(f), j, pth))
      }
    }
  }
  expect_equal(stale, character(),
               info = paste("mode-file path no longer on disk (quarantined?):",
                            paste(stale, collapse = "; ")))
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
  expect_error(ccx_mode_file(rep(CCX_MODE_CANONICAL, 2L)), "ONE mode name")
})

test_that("every named mode is on disk and carries THIS BUILD's parameter set", {
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
  # THE TRAP THIS ENCODES. A reader compares two STORED logposts and picks the
  # wrong arm, because a pinned arm's objective carries a near-delta prior the
  # free arm's does not. The project rule is "the highest FREE arm wins
  # regardless of name", so what is asserted is that the canonical mode is FREE
  # -- never that its stored number is the largest.
  expect_true(CCX_MODE_CANONICAL %in% names(CCX_MODE_FILES))
  expect_setequal(names(CCX_MODE_PINNED), names(CCX_MODE_FILES))
  expect_false(CCX_MODE_PINNED[[CCX_MODE_CANONICAL]])

  lp <- vapply(names(CCX_MODE_FILES),
               function(a) readRDS(ccx_mode_file(a))$logpost, numeric(1))
  free <- names(CCX_MODE_FILES)[!CCX_MODE_PINNED[names(CCX_MODE_FILES)]]
  expect_equal(CCX_MODE_CANONICAL, free[which.max(lp[free])])

  # =================================================================
  # ⛔ THE PIN_PRIOR_CREDIT ASSERTION IS GONE, 2026-09-04, AND THIS SAYS WHY
  # so that nobody re-derives it or reads its absence as an oversight.
  #
  # It asserted that the free arm's advantage over `pin90`, recomputed on ONE
  # objective, EQUALS 11.6698 -- the pinned arm's near-delta `fert_k` prior at
  # fert_k = 90. It had been failing deliberately since 2026-08-30 on Marcus's
  # ruling ("leave it failing and re-measure after the owed refit"), because
  # gamma_diff = 0.25 changed the MODEL and the two arms, sitting at different
  # fert_k, paid differently for it: the gap ran -11.49 / -14.90 / -19.86 across
  # gamma = 0 / 0.125 / 0.25.
  #
  # ⭐ WHAT SETTLED IT (Marcus, 2026-09-04): "the only tests that matter are the
  # ones that are against observations or physics" -- and this is NEITHER. Both
  # sides are the model's own fitted arms, scored by the model's own objective,
  # against a number that is the value of a prior this project chose evaluated
  # at a fert_k this project chose. A threshold taken from the code under test
  # can never reject that code ([[threshold_from_obs_or_law]]); it re-baselines.
  # So it retired with `pin90` rather than being carried forward or re-measured,
  # and the +11.6698 is deliberately NOT preserved anywhere.
  #
  # ⚠ WHAT IS GENUINELY LOST, stated rather than glossed: with one arm in the
  # registry the free-vs-pinned comparison above has NO POWER -- `free` is a
  # single name and which.max() over one element cannot fail. It regains power
  # when a second arm lands, and a 26-parameter PINNED refit is the thing that
  # would do it. Until then this is a gate that says nothing, and saying so is
  # the point ([[no_power_null]]).
  # =================================================================
})

test_that("the free-vs-pinned comparison has POWER, or says that it does not", {
  # ⛔ NOT `expect_length(CCX_MODE_FILES, 1L)`, which is what this line was for
  # about a minute: that would PIN the registry at one arm and fail on the very
  # event it is waiting for. What is worth asserting is the POWER of the test
  # above, which is a different statement -- with one arm, `free` is a single
  # name and which.max() over one element cannot fail, so a green result there
  # means "nothing was compared", not "the right arm won".
  n <- length(CCX_MODE_FILES)
  if (n < 2L)
    skip(sprintf(paste("%d arm in the registry: the free-vs-pinned comparison cannot",
                       "fail and is reported DARK rather than green. It regains power",
                       "when a second arm lands -- a 26-parameter PINNED refit is the",
                       "thing that would do it."), n))
  expect_true(any(CCX_MODE_PINNED[names(CCX_MODE_FILES)]),
              info = "more than one arm, but none is pinned -- nothing tests the trap")
})
