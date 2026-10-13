# =====================================================================
# Gate: the "What pins down what?" TAB's wiring and copy (Marcus 2026-09-25).
#
# Same failure modes as test-luc-regrowth-panel.R and test-imbalance-panel.R --
# the ways a panel goes wrong without erroring:
#   1. An output rendered but never placed, or placed but never rendered.
#   2. A heading or caveat typed as a LITERAL in one file and as a constant in
#      the other, so a rename orphans the prose silently.
#   3. The sentence that keeps the chart honest disappearing: this map is a
#      LOCAL statement at one parameter set, at an equal-cost step. That claim
#      is the app's and the app cannot check it -- so the strings are asserted
#      here.
#      ⚠ A THIRD claim used to be asserted here and is GONE BY RULING (Marcus
#      2026-09-25): APP_CMAP_SD_NOTE said the step was "a Laplace (Hessian)
#      standard deviation at the mode, not a sampled posterior". He asked for it
#      to be deleted, so the assertion goes with the string rather than passing
#      on text the app no longer prints. THE FACT IS STILL TRUE -- the step is
#      still a conditional Hessian sd (diag_constraint_map.R's `sd_kind` records
#      it in the product) -- the app simply no longer says it.
#   4. `renderPlotFit` given the wrong id: it renders fine and wraps its text to
#      ANOTHER panel's width (09-25 c).
#   5. The tension chart's direction keys swapping meaning, which inverts every
#      bar while the chart still draws.
#
# ⛔⛔ AND ONE THAT A STATIC TEST CANNOT SEE, recorded so the next reader knows:
# reading these files as TEXT cannot tell you they still RUN
# ([[static_test_cannot_tell_you_it_runs]], 09-25 c). Test 6 therefore CALLS the
# two plot functions on the real product.
# =====================================================================

.cmp_app   <- file.path(.root, "app")
.cmp_ui    <- readLines(file.path(.cmp_app, "ui.R"), warn = FALSE)
.cmp_srv   <- readLines(file.path(.cmp_app, "server.R"), warn = FALSE)
.cmp_glob  <- readLines(file.path(.cmp_app, "global.R"), warn = FALSE)
.cmp_plots <- readLines(file.path(.cmp_app, "R", "plots.R"), warn = FALSE)

CMP_OUTPUTS   <- c("cm_map_ui", "cm_map", "cm_takeaway", "cm_pin_note",
                   "cm_tension_ui", "cm_tension", "cm_structure_ui")
CMP_PLACED_UI <- c("cm_map_ui", "cm_takeaway", "cm_pin_note",
                   "cm_tension_ui", "cm_structure_ui")
CMP_CONSTS    <- c("APP_CMAP_TAB", "APP_CMAP_HEADING", "APP_CMAP_TENSION_HEADING",
                   "APP_CMAP_NOTE")
CMP_INPUT     <- "cm_level"

test_that("1. every output is rendered, and every placed output exists", {
  for (o in CMP_OUTPUTS)
    expect_true(any(grepl(sprintf("output\\$%s\\b", o), .cmp_srv)),
                info = paste("server.R never renders", o))
  for (o in CMP_PLACED_UI)
    expect_true(any(grepl(sprintf('"%s"', o), .cmp_ui)),
                info = paste("ui.R never places", o))
  # the two plots are placed by the renderUI wrappers, not by ui.R
  for (o in c("cm_map", "cm_tension"))
    expect_true(any(grepl(sprintf('plotOutput\\("%s"', o), .cmp_srv)),
                info = paste("no plotOutput for", o))
})

test_that("2. headings and caveats come from constants, never literals", {
  for (k in CMP_CONSTS)
    expect_true(any(grepl(sprintf("^%s\\s*<-", k), .cmp_glob)),
                info = paste(k, "is not defined in global.R"))
  # ui.R must USE them
  for (k in c("APP_CMAP_TAB", "APP_CMAP_HEADING", "APP_CMAP_TENSION_HEADING"))
    expect_true(any(grepl(k, .cmp_ui, fixed = TRUE)),
                info = paste("ui.R does not use", k))
  # ...and must not ALSO retype their text.
  # ⛔ THE LITERAL IS READ OUT OF global.R, NEVER TYPED HERE. Until 2026-09-25 this
  # guard named the heading's text in its own pattern ('h5("Which part of the
  # model'), so the moment Marcus reworded the heading the guard would have gone
  # on passing while guarding nothing -- [[gate_only_guards_what_it_lists]], and
  # the same shape as the text gates that matched their own comments in 09-25 (i).
  # Deriving it means a reword re-keys the guard automatically.
  .cmp_const_value <- function(k) {
    ln <- grep(sprintf('^%s\\s*<-\\s*"', k), .cmp_glob, value = TRUE)
    if (!length(ln)) return(NA_character_)
    sub('^[^"]*"(.*)"\\s*$', '\\1', ln[[1]])
  }
  # \u26d4 AGAINST CODE, NOT RAW LINES. ui.R's own section comment is
  # `# ---- 6. What pins down what? ...`, which contains APP_CMAP_TAB's text --
  # so the raw-line form of this check FAILED THE MOMENT IT WAS WRITTEN, on the
  # comment naming the section rather than on any retyped literal. That is
  # [[text_gate_matches_its_own_comment]] for the third time in two sessions,
  # which is why the stripper is now shared (helper-code-lines.R).
  .cmp_ui_code <- ccx_code_lines(.cmp_ui)
  for (k in c("APP_CMAP_TAB", "APP_CMAP_HEADING", "APP_CMAP_TENSION_HEADING")) {
    v <- .cmp_const_value(k)
    expect_false(is.na(v), info = paste(k, "is not a one-line string literal in global.R"))
    expect_false(any(grepl(v, .cmp_ui_code, fixed = TRUE)),
                 info = paste("ui.R retypes", k, "'s text instead of using the constant"))
  }
})

test_that("3. the sentences that keep the chart honest are present", {
  glob <- paste(.cmp_glob, collapse = " ")
  # LOCAL, at one parameter set -- not a statement about other structures
  expect_match(glob, "fitted mode", fixed = TRUE)
  expect_match(glob, "would notice a change", fixed = TRUE)   # re-pinned 2026-10-02 (caps sweep, approved)
  # the equal-cost step, which is what makes rows comparable
  expect_match(glob, "conditional Hessian standard deviation", fixed = TRUE)
  # ⚠ The "not a sampled posterior" leg was retired 2026-09-25 with the string it
  # asserted (see the header). Deliberately NOT replaced by a weaker match.
  # and the app must actually place the honesty caveat next to the chart
  expect_true(any(grepl("APP_CMAP_NOTE", .cmp_srv, fixed = TRUE)))
})

test_that("4. renderPlotFit ids match their outputs", {
  # ⚠ renderPlotFit("x", ...) assigned to output$y renders fine and wraps to
  # another panel's width. Same check as test-plot-text-fits.R test 7, scoped here.
  hits <- grep('output\\$(cm_[a-z_]+)\\s*<-\\s*renderPlotFit\\("([a-z_]+)"', .cmp_srv,
               value = TRUE)
  expect_gt(length(hits), 0)
  for (h in hits) {
    m <- regmatches(h, regexec('output\\$(cm_[a-z_]+)\\s*<-\\s*renderPlotFit\\("([a-z_]+)"', h))[[1]]
    expect_identical(m[[2]], m[[3]], info = h)
  }
  # and no bare renderPlot( for these panels, which would lose the live width
  expect_false(any(grepl('output\\$cm_[a-z_]+\\s*<-\\s*renderPlot\\(', .cmp_srv)))
})

test_that("5. the direction keys say which way, and are not interchangeable", {
  pl <- paste(.cmp_plots, collapse = " ")
  expect_match(pl, 'KEY_CMAP_UP\\s*<-\\s*"wants it higher"')   # re-pinned 2026-10-02 (caps sweep, approved)
  expect_match(pl, 'KEY_CMAP_DOWN\\s*<-\\s*"wants it lower"')
  # the fill mapping must pair DOWN with pull_down and UP with pull_up, in that
  # order -- swapping them inverts every bar with no other symptom
  expect_match(pl, paste0('setNames\\(c\\(PAL\\[\\["pull_down"\\]\\], ',
                          'PAL\\[\\["pull_up"\\]\\]\\),\\s*',
                          'c\\(KEY_CMAP_DOWN, KEY_CMAP_UP\\)\\)'))
  # the scored pair itself, with its receipt in the file
  expect_match(pl, 'pull_up\\s*=\\s*"#b2182b"')
  expect_match(pl, 'pull_down\\s*=\\s*"#2166ac"')
  expect_match(pl, "21.2", fixed = TRUE)
})

test_that("6. the plot functions actually RUN on the real product", {
  # the half a text-reading test cannot cover
  f <- file.path(.root, "data", "constraint_map.rds")
  if (!file.exists(f)) skip("constraint map not built")
  if (!requireNamespace("ggplot2", quietly = TRUE)) skip("ggplot2 not installed")
  cm <- readRDS(f)
  # ⚠ plots.R needs ggplot2 ATTACHED, not merely installed, and one app-level
  # constant it reads at call time -- same setup as test-imbalance-panel.R.
  env <- new.env(parent = environment())
  assign("APP_CMAP_NOTE", "note", envir = env)
  # app_provenance_caption() reads the app's parameter-provenance object;
  # a stub is enough here because this test is about the plot RUNNING, and
  # test-plot-text-fits.R is what checks the caption fits.
  assign("app_params", list(source = "posterior mode", status = "beta"), envir = env)
  ok <- tryCatch({
    local({ library(ggplot2); sys.source(file.path(.cmp_app, "R", "plots.R"), envir = env) })
    TRUE }, error = function(e) FALSE)
  skip_if(!ok, "app/R/plots.R did not load")
  expect_s3_class(env$plot_constraint_map(cm, "component"), "ggplot")
  expect_s3_class(env$plot_constraint_map(cm, "parameter"), "ggplot")
  # the tension helper lives in global.R; reproduce its contract on the product
  fam <- cm$family
  S <- vapply(fam, function(ss) colSums(cm$SLOPE[ss, , drop = FALSE]), numeric(ncol(cm$SLOPE)))
  tn <- do.call(rbind, lapply(rownames(S), function(par) {
    v <- S[par, ]; hi <- names(which.max(v)); lo <- names(which.min(v))
    if (v[[hi]] <= 0 || v[[lo]] >= 0) return(NULL)
    data.frame(par = par, up = hi, up_pull = v[[hi]], down = lo, down_pull = v[[lo]],
               opposed = min(v[[hi]], -v[[lo]]), stringsAsFactors = FALSE)
  }))
  expect_true(!is.null(tn) && nrow(tn) > 0)
  tn <- utils::head(tn[order(-tn$opposed), ], 6)
  expect_s3_class(env$plot_constraint_tension(tn), "ggplot")
  # an OPPOSED pair by construction: one sign each, never both the same way
  expect_true(all(tn$up_pull > 0 & tn$down_pull < 0))
})

test_that("7. a row total never prints as a bare 0, and the prose uses the SAME formatter", {
  # ⛔ THE DEFECT (2026-09-25). The chart label was `sprintf("(%.0f)")`, so the
  # weakest row -- Δ¹⁴C pre-bomb at 0.196 -- printed "(0)" while the tab's prose
  # called it 0.2 and divided by it ("about 133 times less"). A row labelled
  # "(0)" also reads as "worth nothing", which is the misreading the tab's own
  # third caveat exists to prevent. Both now go through fmt_cmap_total().
  f <- file.path(.root, "data", "constraint_map.rds")
  if (!file.exists(f)) skip("constraint map not built")
  if (!requireNamespace("ggplot2", quietly = TRUE)) skip("ggplot2 not installed")
  env <- new.env(parent = environment())
  assign("APP_CMAP_NOTE", "note", envir = env)
  assign("app_params", list(source = "posterior mode", status = "beta"), envir = env)
  ok <- tryCatch({
    local({ library(ggplot2); sys.source(file.path(.cmp_app, "R", "plots.R"), envir = env) })
    TRUE }, error = function(e) FALSE)
  skip_if(!ok, "app/R/plots.R did not load")
  expect_true(is.function(env$fmt_cmap_total))

  cm <- readRDS(f)
  fam <- cm$family
  M <- matrix(0, length(fam), ncol(cm$M), dimnames = list(names(fam), colnames(cm$M)))
  for (a in seq_along(fam)) M[a, ] <- colSums(cm$M[fam[[a]], , drop = FALSE])
  for (mat in list(M, cm$MC)) {
    tot <- rowSums(mat)
    lab <- env$fmt_cmap_total(tot)
    # NO row may print as "0" -- every family carries SOME leverage, and a
    # reader is told by the subtitle to read this number.
    expect_false(any(lab == "0"))
    # and the printed value must round-trip within ITS OWN precision, which is
    # format-dependent: one decimal below 10 (tolerance 0.05), an integer at or
    # above it (tolerance 0.5). A single tolerance here would either pass a
    # wrong label or fail a right one -- the first draft used 0.05 throughout
    # and failed on 18.203 -> "18", which is correct to its own precision.
    tol <- ifelse(tot < 10, 0.05, 0.5) + 1e-9
    expect_true(all(abs(as.numeric(lab) - tot) <= tol))
  }
  # MUTATION: the retired %.0f label must FAIL this, or the gate is decorative.
  # ⚠ SELF-CONTAINED since 2026-10-13 (Marcus: "Self-contained mutation (Recommended)"). It relied on the
  # canonical HAVING a row under 0.5 -- hilda29e's pre-bomb Δ¹⁴C, 0.177 -- and at hilda31w the smallest row is
  # 1.113, so it lost its power. It now injects that measured 0.177 into a copy of the totals: the retired label
  # must print "0" there and the live one must not, whatever the canonical's own rows are.
  tot_mut <- rowSums(cm$MC); tot_mut[[which.min(tot_mut)]] <- 0.177
  retired <- sprintf("%.0f", tot_mut)
  expect_true(any(retired == "0"))
  expect_false(any(env$fmt_cmap_total(tot_mut) == "0"))
})

# 2026-10-08 (h) (Marcus: "Main fit only"). At an interannual-CUT canonical the El Nino settings are fitted in a
# separate step and are not on the map; the caveat box says so, COMPUTED from the product's `module` record. The
# failure this guards is the caption silently vanishing (or silently staying) when the cut changes.
.cmp_mod <- new.env(parent = globalenv())
for (e in parse(file.path(.cmp_app, "global.R")))
  if (is.call(e) && length(e) >= 3L && identical(as.character(e[[1]]), "<-") && is.name(e[[2]]) &&
      as.character(e[[2]]) %in% c("APP_CMAP_MODULE_ROW_TEXT", "app_cmap_module_note")) eval(e, .cmp_mod)

test_that("8. the map says the cut's El Nino settings are not on it -- exactly when the product is a cut arm", {
  f <- file.path(.root, "data", "constraint_map.rds")
  if (!file.exists(f)) skip("constraint map not built")
  cm <- readRDS(f)
  note <- .cmp_mod$app_cmap_module_note
  expect_true(is.function(note))
  # server.R places it in the map's caveat box (code, not a comment)
  expect_true(any(grepl("app_cmap_module_note(APP_CMAP)", ccx_code_lines(.cmp_srv), fixed = TRUE)))
  # the product's cut flag decides, and the note follows it
  expect_true("iav_cut" %in% names(cm$provenance))
  if (isTRUE(cm$provenance$iav_cut)) {
    expect_setequal(cm$module$names, CCX_IAV_MODULE_NAMES)
    expect_length(intersect(CCX_IAV_MODULE_NAMES, colnames(cm$M)), 0L)    # none of them is on the map
    expect_length(intersect(cm$module$rows, rownames(cm$M)), 0L)           # nor the rows the module scores
    txt <- note(cm)
    expect_match(txt, "four El Niño settings", fixed = TRUE)
    expect_match(txt, sprintf("%d–%d", cm$module$growth_window[1], cm$module$growth_window[2]), fixed = TRUE)
  } else {
    expect_null(note(cm))
  }
  # MUTATION: without the module record there is nothing to say; an unknown module row is an ERROR, not an omission
  expect_null(note(within(cm, module <- NULL)))
  bad <- cm; bad$module <- list(names = CCX_IAV_MODULE_NAMES, rows = "a_new_row", growth_window = c(1980L, 2024L))
  expect_error(note(bad), "no plain-language text")
})
