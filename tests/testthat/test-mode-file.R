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
    # A PINNED arm (2026-09-13) carries the build's set MINUS its pins, and its
    # `pins` names only fitted names of this build; a free arm carries the set.
    # 2026-09-13i: a registered file may LACK exactly the names in
    # CCX_PARAM_ABSENT_OK (the cell's pair, which entered the table after every
    # registered mode was fitted and is inert under their "hilda" structure);
    # ccx_mode_carries_build() is that statement, order included. A file fitted
    # under "hilda_eq" must carry them: its absent set is then empty.
    expect_true(ccx_mode_carries_build(md),
                info = paste("mode", a, "was fitted on a different parameter set"))
    expect_true(all(ccx_mode_absent(md) %in% CCX_PARAM_ABSENT_OK), info = paste("mode", a))
    if (md$struct %in% c("hilda_eq", "hilda_tr"))
      expect_length(ccx_mode_absent(md), 0L)
    # 2026-09-19 (m): PINNED = the file holds a name its structure READS (ccx_mode_pinned); a
    # file whose pins are all INERT (hilda31pe: the six unread names + the limb's) is a FREE arm
    expect_identical(ccx_mode_pinned(md), unname(CCX_MODE_PINNED[[a]]),
                     info = paste("mode", a, ": the file's `pins` and CCX_MODE_PINNED disagree"))
    if (!is.null(md$pins) && !ccx_mode_pinned(md))
      expect_true(all(names(md$pins) %in% ccx_inert_names(ccx_mode_pump_field(md), ccx_mode_struct(md))), info = paste("mode", a))
    expect_true(all(names(md$pins) %in% CCX_PARAM_NAMES),
                info = paste("mode", a, "pins a name this build does not fit"))
    # THE BAND IS PART OF THE VECTOR'S PROVENANCE, not housekeeping: the driver
    # overrides CCX_PARAM_TABLE$h_ml in-process, and a logpost recomputed under
    # the default band is off by ~1.1 (memory ccx_hml_band_provenance).
    expect_false(is.null(md$hml_bound),
                 info = paste("mode", a, "does not record its h_ml band"))
    # THE STRUCTURE IS PROVENANCE TOO (2026-09-08f): a hilda mode consumed on
    # ccx_default_params() runs as a column with nothing said.
    expect_false(is.null(md$struct), info = paste("mode", a, "does not record its structure"))
    expect_true(md$struct %in% CCX_STRUCT_LABELS)   # "", hilda, hilda_eq (09-13g), hilda_tr (09-14f)
    # 2026-09-17 (h): hs_frac is the STRUCTURE's declared value (hilda 0.16; hilda_c 0.128 = the
    # ocean's actual fraction poleward of 57.14 deg), read from the block, never typed here
    expect_equal(ccx_mode_base(md)$hs_frac, if (nzchar(md$struct)) ccx_struct_block(md$struct)$hs_frac else 0)
    if (md$struct %in% c("hilda_eq", "hilda_tr")) expect_true(ccx_eq_on(ccx_mode_base(md)))
    if (identical(md$struct, "hilda_tr")) expect_true(ccx_tr_on(ccx_mode_base(md)))
  }
})

test_that("the canonical wins among FREE arms re-scored on today's objective, or is a PINNED arm whose pin the registry names and whose parent is the best free arm", {
  # THE TRAP THIS ENCODES. A reader compares two STORED logposts and picks the
  # wrong arm -- because a pinned arm's objective carries a near-delta prior the
  # free arm's does not (`pin90`, 2026-08), OR because the two arms were fitted
  # under different objectives (`hilda31` -1478.66 vs `hilda31p` -1480.54 on
  # 2026-09-10: the OLDER one "wins" on paper and is 9.09 BEHIND like-for-like),
  # OR -- since 2026-09-13 -- because a PINNED arm's logpost carries NO prior and
  # NO Jacobian for the held name and is in no free arm's units at all.
  # A stored logpost is a number in the units of the objective that produced
  # it; nothing in the registry says which objective that was
  # ⇒ [[compare_gaps_not_absolute_logposts]], [[ccx_pinned_arms]].
  #
  # ⛔ UNTIL 2026-09-10 THE LINE BELOW COMPARED STORED NUMBERS, while this very
  # comment said "never that its stored number is the largest" -- the two
  # contradicted each other, invisibly, because the registry had held ONE arm
  # since 09-04. Resolved on Marcus's ruling (option 2): every FREE arm's
  # `par_mode` is RE-SCORED under TODAY'S objective, through the file's own
  # base list, and the best free arm is found on THAT.
  #
  # ⭐ 2026-09-13 (Marcus's ruling, "Promote C' id 1"): THE CANONICAL MAY BE A
  # PINNED ARM. The 09-04 registry note wrote "the canonical is a free arm" when
  # no pin existed and the only pinned comparison (`pin90`) was a near-delta
  # prior. A real pin (ccx_apply_pins) is different in kind: it holds a fitted
  # name at a stated value with no prior term, and the project uses it as a
  # RETIREMENT-IN-WAITING -- `ent_seas_amp_SH`, the pCO2-side entrainment shim,
  # pinned to 0 so the real seasonal mixed layer carries the SH DIC side alone.
  # Retiring the name from the table is a larger change (the seas_ml 0 control
  # `hilda31p` carries the shim at 18.7 and would become unscorable), so the
  # pin is the honest interim. What this test now asserts is the RE-EXPRESSED
  # rule, not a weakening:
  #   (a) a pinned canonical is allowed ONLY when its file's `pins` names exactly
  #       what the registry says it pins (CCX_MODE_CANONICAL_PINS) and the
  #       registry names its free PARENT (CCX_MODE_PINNED_PARENT);
  #   (b) among FREE arms re-scored on today's objective, the best is the
  #       parent (a pinned canonical) or the canonical itself (a free one);
  #   (c) the canonical beats the seas_ml 0 CONTROL on LIKELIHOOD over the
  #       common stream rows -- the one scale a pinned and a free arm share --
  #       and its PRICE against its free parent on the same scale is RECORDED
  #       (printed), not gated: the ruling accepted it (-2.53 at C' id 1, all on
  #       `d13c_seasonal_SPO`), and a gate on the model's own gap would be the
  #       code under test setting its own bar ([[threshold_from_obs_or_law]]);
  #   (d) the canonical's stored logpost reproduces under today's objective
  #       WITH its pins applied.
  expect_true(CCX_MODE_CANONICAL %in% names(CCX_MODE_FILES))
  expect_setequal(names(CCX_MODE_PINNED), names(CCX_MODE_FILES))
  canon_pinned <- CCX_MODE_PINNED[[CCX_MODE_CANONICAL]]
  md_c <- readRDS(ccx_mode_file())
  if (canon_pinned) {
    expect_false(is.null(CCX_MODE_CANONICAL_PINS),
                 info = "a pinned canonical must have its pins NAMED in the registry")
    expect_equal(md_c$pins[names(CCX_MODE_CANONICAL_PINS)], CCX_MODE_CANONICAL_PINS,
                 info = "the canonical file's pins are not the registry's")
    expect_setequal(names(md_c$pins), names(CCX_MODE_CANONICAL_PINS))
    expect_true(!is.null(CCX_MODE_PINNED_PARENT) && CCX_MODE_PINNED_PARENT %in% names(CCX_MODE_FILES),
                info = "a pinned canonical must name a REGISTERED free parent")
    expect_false(CCX_MODE_PINNED[[CCX_MODE_PINNED_PARENT]], info = "the parent must be a FREE arm")
    # the parent is the same space with the pinned names FREE: it must carry them
    md_p <- readRDS(ccx_mode_file(CCX_MODE_PINNED_PARENT))
    # 2026-09-17 (h): a pin may also be one of the INERT names the parent is allowed to lack
    # (CCX_PARAM_ABSENT_OK): hilda30h pins the six the hilda_c / solved-field structure never reads
    expect_true(all(names(md_c$pins) %in% c(md_p$param_names, CCX_PARAM_ABSENT_OK)))
    expect_true(ccx_mode_carries_build(md_p))   # the full set, or minus CCX_PARAM_ABSENT_OK only (09-13i)
  } else {
    expect_null(CCX_MODE_CANONICAL_PINS); expect_null(CCX_MODE_PINNED_PARENT)
    expect_null(md_c$pins)
  }

  skip_if_no_cpp()
  # (b) the free arms, re-scored -- on the FULL table (no pins live at entry); a free arm
  # that HOLDS inert names (hilda31pe, 09-19 m) is encoded with them applied and restored
  expect_null(CCX_PINS)
  free <- names(CCX_MODE_FILES)[!CCX_MODE_PINNED[names(CCX_MODE_FILES)]]
  # 2026-09-13i: the registered files lack the cell's pair; ccx_mode_start()
  # migrates (0 = what they ran), seeds the floor-sitting pair at init and
  # encodes. The seed's prior + Jacobian is a KNOWN constant (`logpost_shift`),
  # subtracted where a STORED logpost is reproduced; the free-arm ranking and the
  # likelihood comparison are unaffected (every arm pays the same constant, and
  # the streams are prior-free).
  score <- function(md) {
    bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
    .todo <- ccx_mode_pins(md); .todo <- .todo[names(.todo) %in% CCX_PARAM_NAMES]   # the file's pins not already live
    .rm <- if (length(.todo)) ccx_apply_pins(.todo) else list()
    st <- ccx_mode_start(md, "test-mode-file")
    v  <- ccx_make_logpost(base_params = bp, by_stream = TRUE)(st$u)
    ccx_unpin_params(.rm)
    attr(v, "logpost_shift") <- st$logpost_shift
    v
  }
  rescored <- lapply(free, function(a) score(readRDS(ccx_mode_file(a)))); names(rescored) <- free
  lp_free <- vapply(rescored, as.numeric, numeric(1))
  expect_true(all(is.finite(lp_free)))
  best_free <- free[which.max(lp_free)]
  # ⛔ NAMED RED #1 by ruling (Marcus 2026-09-19, ruling 2 = "b"): the best FREE arm is the seas_ml-0 CONTROL
  # hilda31pe (its #13 refit on hilda_c, -1425.02), not the registered parent hilda31s2 (a `hilda` / #12 fit,
  # restamped, never refit under hilda_c or #13; the free-parent #13 tree is staged). This expectation stays
  # AS WRITTEN and RED until the seasonal-ML ruling (the hilda_cs refit) and a free-parent refit resolve it.
  expect_equal(best_free, if (canon_pinned) CCX_MODE_PINNED_PARENT else CCX_MODE_CANONICAL,
               label = sprintf("best free arm %s (logposts: %s) -- NAMED RED by ruling 09-19 (b) while it is the control", best_free, paste(sprintf("%s %.4f", free, lp_free), collapse = ", ")))

  # (d) the canonical reproduces its stored logpost under ITS pins (applied, then
  # restored with the object ccx_apply_pins() returned -- CCX_PINS is process-global)
  if (canon_pinned) {
    rm <- ccx_apply_pins(ccx_mode_pins(md_c)); on.exit(ccx_unpin_params(rm), add = TRUE)
    sc_c <- score(md_c)
    ccx_unpin_params(rm); rm <- list()
  } else sc_c <- rescored[[CCX_MODE_CANONICAL]]
  # tolerance = the reproduction precision of recompute_hessian.R GATE 1 / promote GATE 4;
  # minus the seeded pair's prior + Jacobian (-0.8236 on 09-13i; 0 once the file carries them)
  expect_equal(as.numeric(sc_c) - attr(sc_c, "logpost_shift"), md_c$logpost, tolerance = 1e-5, scale = 1)

  # (c) LIKELIHOOD on the common rows: the canonical beats the seas_ml 0 control;
  # its price against the parent is recorded
  lik <- function(sc) attr(sc, "streams")
  common <- Reduce(intersect, c(list(names(lik(sc_c))), lapply(rescored, function(r) names(lik(r)))))
  L <- c(vapply(rescored, function(r) sum(lik(r)[common]), numeric(1)),
         setNames(sum(lik(sc_c)[common]), CCX_MODE_CANONICAL))
  # ⛔ NAMED RED #2 by ruling (Marcus 2026-09-19, ruling 2 = "b"): the control hilda31pe (ML OFF, shim free,
  # 31 names, refit under #13) beats the canonical hilda30e (ML ON, shim pinned, 30 names, refit under #13) by
  # ~10.2 on the 26 common rows -- refit against refit, under #12 (+10.31) and #13 alike. The gate is NOT
  # re-ruled to pass (a gate chosen because the model passes it is not a gate); the red IS the open question:
  # the seasonal mixed layer as a MECHANISM vs its price on the NH seasonal rows (d13c_seasonal_MLO,
  # co2_seasonal_MLO). Resolution = the hilda_cs refit (the ML's NH cycle flat) and the ML ruling.
  expect_gt(L[[CCX_MODE_CANONICAL]], L[[CCX_MODE_SEASML0_CONTROL]],
            label = sprintf("canonical likelihood %.4f vs the seas_ml 0 control %.4f (%d common rows) -- NAMED RED by ruling 09-19 (b)",
                            L[[CCX_MODE_CANONICAL]], L[[CCX_MODE_SEASML0_CONTROL]], length(common)))
  if (canon_pinned)
    cat(sprintf("\n  [test-mode-file] PINNED canonical %s: likelihood %.4f on %d common rows; parent %s %.4f (price %+.4f, RECORDED not gated); control %s %.4f (%+.4f)\n",
                CCX_MODE_CANONICAL, L[[CCX_MODE_CANONICAL]], length(common), CCX_MODE_PINNED_PARENT,
                L[[CCX_MODE_PINNED_PARENT]], L[[CCX_MODE_CANONICAL]] - L[[CCX_MODE_PINNED_PARENT]],
                CCX_MODE_SEASML0_CONTROL, L[[CCX_MODE_SEASML0_CONTROL]],
                L[[CCX_MODE_CANONICAL]] - L[[CCX_MODE_SEASML0_CONTROL]]))

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
  # and the +11.6698 is deliberately NOT preserved anywhere. The 09-13 price of
  # C' (-2.53 likelihood) is printed above for the same reason it is not gated.
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
  # 2026-09-11 (8): the second arm LANDED, and it is FREE (`hilda31p`, the seas_ml = 0
  # control, beside the canonical `hilda31s`). The re-scored comparison above now has
  # power with two FREE arms -- which.max over two re-scored values can pick the
  # wrong one -- so the trap is tested; a PINNED arm is the other way to give it
  # power, not the only one. Re-expressed, not re-baselined.
  n_free <- sum(!CCX_MODE_PINNED[names(CCX_MODE_FILES)])
  expect_true(n_free >= 2L || any(CCX_MODE_PINNED[names(CCX_MODE_FILES)]),
              info = "more than one arm, but only one is free and none is pinned -- nothing tests the trap")
})
