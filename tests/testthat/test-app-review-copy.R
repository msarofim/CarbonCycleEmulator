# =====================================================================
# Gate: the APP COPY fixed in Marcus's 2026-09-22 review STAYS fixed.
#
# WHAT THIS GUARDS. The 45-comment review produced 27 copy items whose whole
# content is a string: a sentence on a card that was FALSE (the app denied the
# volcanic mechanism it runs), a claim that was stale (`No ocean circulation`),
# a dated code comment that had leaked into user-facing copy. None of them is
# reachable by any other test -- the app renders, the suite passes, and the
# page says the wrong thing.
#
# WHY IT IS A GATE AND NOT A CHECKLIST. The 09-22 (o) session lost three
# already-applied edits to a Python batch that asserted part-way through and
# wrote NOTHING; they were reported "ok" and discarded. The only thing that
# caught it was an audit pass of exactly this shape, and that audit lived in a
# scratchpad and did not survive the session -- so this file exists to stop the
# next copy edit from silently reverting one of these, and to stop the audit
# itself from being scratchpad-only a second time.
#
# ⚠ R COMMENT LINES ARE STRIPPED BEFORE MATCHING. Six of the 27 items are
# documented in the source by a comment that QUOTES the old wording ("...the
# `No ocean circulation` claim is cut..."). Matching raw source reads every one
# of those as a miss -- the audit's own false-failure mode, measured: 6 of 27.
# Only WHOLE-LINE comments are stripped, because deciding whether a `#` inside
# a line opens a comment or sits in a string needs a parser. If a TRAILING
# comment ever trips a check here, move that comment onto its own line; do not
# weaken the strip.
#
# ⚠ MUTATION-TESTED BELOW. Every mechanism in this file -- the absent check,
# the present check, the comment strip -- is paired with input it must REJECT
# or must NOT reject. A gate that has only ever passed has not been shown to be
# a gate (project rule, ~/.claude/CLAUDE.md).
# =====================================================================

# The copy surface: every file the review's items were applied to. Read as one
# blob on purpose -- an item that moves between ui.R and review.R is still fixed,
# and this gate should not fail on a refactor that changes nothing on screen.
AC_COPY_FILES <- c(
  "app/ui.R", "app/server.R", "app/global.R",
  "app/R/review.R", "app/R/params_meta.R", "app/R/plots.R",
  "app/R/plots_review.R", "R/mechanisms.R"
)

# Drop whole-line R comments (including roxygen `#'`). See the header.
ac_strip_comments <- function(lines) lines[!grepl("^\\s*#", lines)]

ac_copy_source <- function(root, files = AC_COPY_FILES) {
  paths <- file.path(root, files)
  paste(unlist(lapply(paths[file.exists(paths)], function(p)
    ac_strip_comments(readLines(p, warn = FALSE)))), collapse = "\n")
}

# (label, must be ABSENT, must be PRESENT); NA for "not checked on this side".
AC_CHECKS <- list(
  c("K1 no 'Given only emissions'",      "Given only emissions", NA),
  c("K1 no 'Nothing here was tuned'",    "Nothing here was tuned", NA),
  # ⚠ K2 SUPERSEDED IN PART 2026-10-01 by Marcus's A7 ("add N deposition as a driver"): the list gained
  # nitrogen deposition, so the phrase it requires is the list up to the volcanic term; A7's own check
  # (AC_CHECKS_1001) requires the new term. Changed with the spec, not to turn a red test green.
  # ⚠ K2 SUPERSEDED IN PART 2026-10-21 by Marcus's "3a" (ENSO spelled out at first use): the phrase it requires
  # moved with the spec; AC_CHECKS_1021 below requires the new list. Changed with the spec, not to turn a red test green.
  c("K2 driver list in takeaway",        NA, "an index of El Niño and La Niña (ENSO), volcanic aerosol"),
  c("K4 see_card text",                  NA, "The solid one shows the"),
  # ⚠ W4 was SUPERSEDED 2026-09-24 by Marcus's C3, which replaced the 09-22
  # wording wholesale. The ratchet still ratchets: the PRE-09-22 phrasing must
  # still be absent, and the phrase asserted present is now C3's. Changed with
  # the spec, NOT to make a red test green -- the 09-22 phrase it used to
  # require ("not a clean score for the sinks") is gone on Marcus's own
  # instruction, and requiring it would pin the app to a superseded round.
  c("W4/C3 airborne fraction reworded",  "the single most useful summary", "should not be"),
  c("C4 dated clause gone",              "since 2026-09-01", NA),
  c("C4 ENSO blurb",                     NA, "out of the surface ocean, year by year"),
  # ⚠ C5 SUPERSEDED IN PART 2026-10-01 by Marcus's A3 ("Delete the fertilization sentence where it
  # appears"): the whole "no separate land sink switch" box went, and with it the seasonal sentence this
  # used to require. The absent side still ratchets.
  c("C5 'exactly one reason' gone",      "for exactly one", NA),
  c("F1 FaIR text",                      "So the honest reading is", "Future scenario temperatures are a result"),
  c("F3 confound sentence gone",         "confound it", NA),
  # N1 SUPERSEDED 2026-10-15 by Marcus's new comment text (CarboTopecomments.10.15.26): it now pins that.
  c("N1 acknowledgement wording",        "Anyone whose comment", "please include your full name in the comments."),
  c("N2 lead sentence cut",              "not quoted", NA),
  c("N4 mechanism not carrier",          "What carrier would you expect", "What mechanism might help"),
  c("N8 volcanic mechanism",             "for which there is no mechanism", "Pinatubo"),
  # N9 SUPERSEDED 2026-10-15: his new gloss.
  c("N9 comparison gloss",               "not a gate. Nothing from this source", "property of having a physical model tuned to observed variables."),
  # ⚠ N10 SUPERSEDED IN PART 2026-10-01: its sentence was card 6's question, and card 6 was RETIRED (A1,
  # "Retire card 6"). The absent side still ratchets.
  c("N10 physical mechanism",            "When a named mechanism loses", NA),
  c("N11 'most that naming buys' gone",  "most that naming buys", NA),
  c("N12 two lists",                     NA, "rv_standins"),
  c("N12 shim gate",                     NA, "rv_validate_shims"),
  c("U1 gated param table",              "desc = c(", "app_param_table(CCX_PARAM_NAMES"),
  c("U2 drivers table",                  NA, "h_drivers"),
  c("U2 IGCC no longer a target",        NA, "What drives the model"),
  c("U3/R4 affiliation dropped",         "NYU Marron Institute\"", "APP_AUTHOR       <- \"Marcus C. Sarofim\""),
  c("U4 isotope sentence",               "which is what lets the isotope tab work", "All exchanges include all three carbon"),
  c("U5 'No ocean circulation' gone",    "No ocean circulation", "meet only in the atmosphere"),
  # re-pinned 2026-10-15 (Marcus 2026-10-15: "Apply all the app text suggestions"): "duplicate" -> "reproduce most" (issues 2-3 are hemispheric misses)
  c("U6 goal first",                     NA, "able to reproduce most observed hemispheric, seasonal"),
  c("O2 banner shortened",               NA, "provenance_detail"),
  # C2 (09-22 r): the chart measured the claim next to it and falsified it --
  # ENSO off removes 23 % of the scatter, not the wobble. See
  # [[ccx_wobble_is_mostly_emissions]].
  # 2026-10-03 (h): at hilda34g ENSO off removes 40 % (calibration/diag_app_wobble_shares.R; 28 % at
  # hilda33d), and the blurb says "about 40 %" (Marcus: "\"about 40 %\" (Recommended)"; this re-pin:
  # "Approve all (Recommended)").
  c("C2 wobble claim corrected",         "switch it off and the wobbles go", "about 40% of the wobble")   # "40 %" -> "40%", 10-15
)

# THE 2026-10-01 RULINGS (Marcus, review notes/review_2026-10-01c_open_decisions.md: "1) Retire card 6.
# 2) Say about 1.4 dC per 1000 GtC. 3) Delete the fertilization sentence where it appears. 4) Fix Card 4
# and 5, and the land pools, and add N deposition as a driver. 5) update the version to BETA v1.0
# CarboTope. ... 8) If it is a gross rate, then name it that. 9) Reword: it should be specifically about CO2
# fertilization, with nitrogen effects a different arm"). Kept apart from the 09-22 list so each round
# can be read, and superseded, on its own.
AC_CHECKS_1001 <- list(
  c("A1 card 6 retired (title)",          "A simpler version of the model fits the data better", NA),
  c("A1 card 6 retired (caption)",        "in the simpler version's favour", NA),
  # RE-PINNED 2026-10-11 (Marcus: "Re-pin both (Recommended)"): his 10-11 paragraph replaced the
  # horizon sentence and carries its claim ("about 1.4 degC per 1000 GtC from any time period ...").
  c("A2 pulse box: one figure",           "NOT in when you look", "per 1000 GtC from any"),
  c("A3/B5 '(the land sink)' label gone", "CO₂ fertilization (the land sink)", NA),   # U.S. spelling since 10-15
  c("A3/B5 'IS the land sink' gone",      "IS the land sink", NA),
  c("A3 'single cause' gone",            "sink has a single cause", NA),
  c("A3 'only long-term' gone",          "only long-term land-uptake term", NA),
  c("A3 'no land sink' box gone",         "Why there is no separate 'no land sink' switch", NA),
  c("A4 card 4 range claim",              "lands inside the observed range", "RV_ENSO_L2_VS_OBS"),
  c("A5 card 5 partition",                "and the ocean a smaller one", "split between land, ocean and air is close to the"),
  c("A6 land pools (structure)",          "two-pool land biosphere", "a land biosphere of four"),
  c("A6 land pools (limits)",             "Two land pools", "Four land pools"),
  c("A7 N deposition in the takeaway",    NA, "and nitrogen deposition, and its calibration data"),
  c("A7 N deposition in the table",       NA, "Nitrogen deposition on land"),
  c("B2 release name",                    "v1.0-hilda29l", "APP_RELEASE_NAME"),
  c("B4 ndep_ret named gross",            "Carbon stored per unit of nitrogen", "Gross carbon uptake per unit of nitrogen"),
  c("B5 CO2 fertilisation only",          "the land stops taking up carbon", "This switches off CO₂ fertilization only")
)

# THE 2026-10-06 RULINGS (Marcus, after the hilda33p adoption; handoff 10-06 §4.1): "Caveat sentence
# (Recommended)" -- the warming switch's caveat names the mixing slowdown it now also removes, in DESIGN
# §3.4a S's sentence ("smaller" is measured and guarded in test-mechanisms.R); "Mark held rows
# (Recommended)" -- the parameter table's intro gains a clause and the table a generated "Set" column
# (test-app-params-table.R holds the column to the mode file).
AC_CHECKS_1006 <- list(
  c("W1 warming caveat: the third effect", NA, "It also removes a third, smaller effect"),
  c("W1 warming caveat: DESIGN's sentence", NA, "the upper ocean becomes more layered and"),
  c("H1 held rows: the intro clause",      "These are the numbers the calibration fits. Everything", "and the few it holds at a"),
  c("H1 held rows: the column is wired",   NA, "held = APP_HELD_NAMES"),
  # carbotopecomments.10.2.26, his rulings of 10-06 on card 4 (the ENSO TIMING miss): his wording
  # replaced the 10-04 draft's in both places, so the draft's phrases must not appear either.
  # 2026-10-15: his timing sentence was FALSE since hilda29e (model and record both peak +5 months) and is
  # REMOVED; the lag sentence was corrected to the 5.93 months hilda31w holds (Marcus: "Apply minimal factual fixes").
  c("C4t card 4 timing, plain",  "Its timing is a little early, too", NA),
  c("C4t card 4 timing removed", "peaking a month after the Pacific warmth index", NA),
  c("C4t card 4 timing, detail", "giving it the weight its year-to-year information supports",
    "about six months after the index, the value a separate fit"),
  c("C4t card 4 lag, old value", "2.5 months after the index", NA)
)

ac_audit <- function(src, checks = AC_CHECKS) {
  problems <- character(0)
  for (ck in checks) {
    label <- ck[[1]]; absent <- ck[[2]]; present <- ck[[3]]
    if (!is.na(absent) && grepl(absent, src, fixed = TRUE))
      problems <- c(problems, paste0(label, ": still contains '", absent, "'"))
    if (!is.na(present) && !grepl(present, src, fixed = TRUE))
      problems <- c(problems, paste0(label, ": missing '", present, "'"))
  }
  problems
}

.ac_src <- ac_copy_source(.root)

test_that("every copy file the review touched is present", {
  missing <- AC_COPY_FILES[!file.exists(file.path(.root, AC_COPY_FILES))]
  expect_equal(missing, character(0),
               info = paste("copy surface moved or lost:", paste(missing, collapse = ", ")))
})

test_that("all 28 of Marcus's 2026-09-22 copy items are still applied", {
  problems <- ac_audit(.ac_src)
  expect_equal(problems, character(0), info = paste(problems, collapse = " | "))
})

test_that("all of Marcus's 2026-10-01 copy rulings are still applied", {
  problems <- ac_audit(.ac_src, AC_CHECKS_1001)
  expect_equal(problems, character(0), info = paste(problems, collapse = " | "))
})

# CarboTopecomments.10.15.26 (Marcus 2026-10-15): his wording, and the factual fixes he approved the same day.
# Each PRESENT fragment sits inside ONE source string (comments are stripped, literals are not joined).
AC_CHECKS_1015 <- list(
  c("W growth heading",       "The same run, year by year", "Annual growth rate"),
  c("W growth sentence",      "where switching a mechanism off is actually visible",
    "The annual growth rate showcases the year-to-year variability in the trend."),
  c("W relative to",          "Against the measured record", "Relative to the measured record over the same %d years:"),
  c("W ENSO index defined",   "This sets the El Niño index", "This sets the ENSO index — a measure of how strong El Niño and"),
  c("W ENSO temperature",     "own temperature signature", "temperature driver: this switch only removes the other"),
  c("W ENSO blurb",           "largest reason the Keeling curve", "driver of the variability in annual growth rate — switch it"),
  c("W volcano blurb",        "A big eruption puts a haze", "Some explosive volcanic eruptions put sulfate aerosols into"),
  c("W volcano caveat",       "This removes the light effect only", "This removes the diffuse scattering effect only. The planetary"),
  c("F tagged panel",         "The pulse's own atoms", "The pulse's carbon atoms"),
  c("F off-grid message",     "set the pulse to one of those to compare", "FaIR was only run for %g GtC pulses: set the pulse size to %g GtC."),
  c("F checkbox, pulse lab",  NA, "Compare with FaIR (%g GtC pulse only)"),
  c("K comment text",         "lead your comment with the card number", "Comments are public on Substack. Be specific about what"),
  c("K issue numbering",      "Comment on card %d", "Issue %d: %s"),
  c("K shim gloss",           "a fitted stand-in for a mechanism", "a model correction that is not based on a physical mechanism."),
  c("K comparison gloss old", "long tail of carbon dioxide is robust", NA),
  c("K issue 1 plain",        "until now the panel drew the box", "offset between the hemispheric box and the station data that"),
  c("K issue 4 title",        "Year-to-year variability is about 60% of observed", "Year-to-year variability is somewhat smaller than observed"),
  c("K issue 4 share",        "only about 60% of the observed", "wobble in CO₂ growth is only about 70–90% of the observed"),
  c("K issue 4 index name",   "Niño3.4 index (annual mean)", "ENSO index (Niño 3.4, annual mean)"),
  c("K issue 5 title",        "decays faster here than in the multi-model mean", "Comparing CO₂ pulse decay rates to other sources"),
  c("K issue 5 ask",          "acceptable to teach, or does it undercut the lesson?", "What is the best comparison for long-term CO₂ decay?"),
  c("K issue 8 title",        "loses uptake to warming", "uptake declines with warming about twice as fast in CarboTope"),
  c("K issue 8 first detail", "This is a comparison, not a test: those ocean models", "CarboTope was not tuned to this mechanism."),
  c("K issue 8 deleted",      "tested but not settled", NA),
  # The next two rows' present-halves were superseded 2026-10-21 (AC_CHECKS_1021C, Marcus: "Update the pins"):
  # the mixing explanation they required was replaced after H2's test. Their absent-halves still hold.
  c("K issue 8 carbon-rich",  "refilled with carbon-rich water", NA),
  c("K issue 8 mixing",       "Mixing less is not the fix", NA),
  c("K issue 8 second chart", "The second chart says what it is worth", "climate effect. The second chart shows the implications of the"),
  c("K issue 8 SSP5-8.5 out", "SSP5-8.5 (older high scenario)", NA),
  c("F temperature shape",    NA, "FaIR shows the same shape for the same pulse; whether temperature rises again before 2300,")
)

# Marcus 2026-10-21: the pre-redeploy scan's wording ("Use 'Still in the air'", his takeaway sentence, the FaIR
# label, drafts 10 and 11, and "1b, 2a, 3a, 4a, 5").
AC_CHECKS_1021 <- list(
  c("K takeaway sentence",   "not an abstract regression: it only adjusts quantities that",
                             "not an abstract regression: with a couple exceptions, it is designed around"),
  c("K takeaway SST + ENSO", "global temperature, an ENSO index",
                             "sea-surface temperature, an index of El Niño and La Niña (ENSO)"),
  c("W still in the air",    "Stayed in the air", "LAB_STILL_IN_AIR <- \"Still in the air\""),
  c("F FaIR checkbox",       "Compare with standard FaIR", "Compare with FaIR, a widely used climate emulator."),
  c("F build prompt",        NA, "Choose a pathway and press \\u201c%s\\u201d."),
  c("I pulse lab pointer",   "(see the Pulse lab)", "(see Futures → Pulse lab)"),
  c("C no colour reference", "the purple", "is drawn as zero: the “Without” line is what the counterfactual ran with."),
  c("K progress message",    "Running the model with its ENSO mechanisms off", "RV_PROGRESS_MSG <- \"Drawing the chart\""),
  c("F pulse prompt",        NA, "\"to see results at these settings.\""),
  c("all caption lead",      "Model: %s (%s). Not peer-reviewed", "CAPTION_CREDIT <- \"CarboTope.org (beta)\""),
  c("F EXTRA lower case",    "how much EXTRA carbon", "how much extra carbon")
)

test_that("all of Marcus's 2026-10-21 copy rulings are still applied", {
  problems <- ac_audit(.ac_src, AC_CHECKS_1021)
  expect_equal(problems, character(0), info = paste(problems, collapse = " | "))
})

test_that("MUTATION: the 10-21 list fires when an old phrase returns or a new one goes", {
  m1 <- paste(.ac_src, '  "is drawn as zero: the purple line is what the counterfactual ran with."', sep = "\n")
  expect_true(any(grepl("C no colour reference", ac_audit(m1, AC_CHECKS_1021), fixed = TRUE)))
  m2 <- gsub("with a couple exceptions, it is designed around", "it only adjusts", .ac_src, fixed = TRUE)
  expect_true(any(grepl("K takeaway sentence", ac_audit(m2, AC_CHECKS_1021), fixed = TRUE)))
  for (ck in AC_CHECKS_1021) expect_true(!is.na(ck[[2]]) || !is.na(ck[[3]]), info = ck[[1]])
})

# Marcus 2026-10-21, on the scan list: "Do 1-7 and the 'own' fix. 8: 'CarboTope is a set of carbon pools in each
# hemisphere, joined with flows; the tables below lists [list] the parameters included, the inputs, and the
# observations that are used to fit and drive the model.'" The behavior items (glosses, links, spans) are in
# test-app-scan-items.R.
AC_CHECKS_1021B <- list(
  c("H takeaway",            NA, "is a set of carbon pools in each hemisphere, joined with flows;"),
  c("H takeaway placed",     NA, "takeaway(APP_HOOD_TAKEAWAY)"),
  c("F method said once",    "How this is computed: ", "with and without the pulse, from identical starting"),
  c("C ppm per year",        "ppm/yr", "Model \\u2212 measured (ppm per year)"),
  c("M ENSO year-to-year",   "month-to-month wobble", "to the year-to-year wobble in CO₂'s growth rate"),
  c("F its peak",            "of its own peak", "and by %s of its peak")
)

test_that("Marcus's 2026-10-21 scan rulings are still applied", {
  problems <- ac_audit(.ac_src, AC_CHECKS_1021B)
  expect_equal(problems, character(0), info = paste(problems, collapse = " | "))
})

test_that("MUTATION: the scan list fires when an old phrase returns or a new one goes", {
  m1 <- paste(.ac_src, '  "the full model runs %+.2f ppm/yr on average"', sep = "\n")
  expect_true(any(grepl("C ppm per year", ac_audit(m1, AC_CHECKS_1021B), fixed = TRUE)))
  m2 <- gsub("joined with flows;", "joined by flows;", .ac_src, fixed = TRUE)
  expect_true(any(grepl("H takeaway", ac_audit(m2, AC_CHECKS_1021B), fixed = TRUE)))
  for (ck in AC_CHECKS_1021B) expect_true(!is.na(ck[[2]]) || !is.na(ck[[3]]), info = ck[[1]])
})

# Marcus 2026-10-21, on the three held draft strings after the seasonal-tracer and H2 tests (CHANGELOG 10-21 v):
# item 8 (What pins down what?'s seasonal paragraph) the timing draft, item 9 (the `response` gloss) "after
# calibration", item 10 (card 8's detail) the decomposition draft; then "Update the pins".
# Item 8 revised again the same day after T8d (CHANGELOG 10-21 y, Marcus: "Revise for sampling"): half the lead is
# the flask / in situ sampling difference.
AC_CHECKS_1021C <- list(
  c("S seasonal: timing at MLO",   "the surface ocean without a",
    " samples runs about four days ahead of the continuously measured CO₂ cycle."),
  c("S seasonal: sampling half",   "seasonal cycle comes from land plants, the observed ¹³C cycle runs about four",
    " About half of that comes from the two sampling methods, and the model's land"),
  c("S seasonal: in step",         NA, " plants move the two tracers in step, so the fit splits the difference."),
  c("Gloss: response",             "refitting the same model does not fix it",
    "the process is in the model, but after calibration it still responds by"),
  c("K issue 8: decomposition",    "Our leading explanation",
    "temperature here matches the measured value. The larger part of the"),
  c("K issue 8: share unexplained", "Mixing less would help this issue",
    "vertical mixing is halved or doubled, so its cause is not yet known. The")
)

test_that("Marcus's 2026-10-21 rulings on the held draft strings are still applied", {
  problems <- ac_audit(.ac_src, AC_CHECKS_1021C)
  expect_equal(problems, character(0), info = paste(problems, collapse = " | "))
})

test_that("MUTATION: the 10-21 held-strings list fires when an old sentence returns or a new one goes", {
  m1 <- paste(.ac_src, '  "temperature here matches the measured value. Our leading explanation",', sep = "\n")
  expect_true(any(grepl("K issue 8: decomposition", ac_audit(m1, AC_CHECKS_1021C), fixed = TRUE)))
  m2 <- gsub("after calibration it still responds by", "it reacts by", .ac_src, fixed = TRUE)
  expect_true(any(grepl("Gloss: response", ac_audit(m2, AC_CHECKS_1021C), fixed = TRUE)))
  for (ck in AC_CHECKS_1021C) expect_true(!is.na(ck[[2]]) || !is.na(ck[[3]]), info = ck[[1]])
})

test_that("all of Marcus's 2026-10-15 copy rulings are still applied", {
  problems <- ac_audit(.ac_src, AC_CHECKS_1015)
  expect_equal(problems, character(0), info = paste(problems, collapse = " | "))
})

test_that("MUTATION: the 10-15 list fires when an old phrase returns or a new one goes", {
  m1 <- paste(.ac_src, '  caveat = paste("This removes the light effect only. Eruptions also cool the")', sep = "\n")
  expect_true(any(grepl("W volcano caveat", ac_audit(m1, AC_CHECKS_1015), fixed = TRUE)))
  m2 <- gsub("What is the best comparison for long-term CO₂ decay?", "Is it acceptable?", .ac_src, fixed = TRUE)
  expect_true(any(grepl("K issue 5 ask", ac_audit(m2, AC_CHECKS_1015), fixed = TRUE)))
  for (ck in AC_CHECKS_1015) expect_true(!is.na(ck[[2]]) || !is.na(ck[[3]]), info = ck[[1]])
})

# Marcus 2026-10-16, on the pulse lab's partition panels after the ocean was split by depth: caption cuts,
# his takeaway paragraph over both panels, and no separate line on the three ocean groups.
AC_CHECKS_1016 <- list(
  c("P caption: perturbation clause cut", "the difference between running with it and",
    "This is how much extra carbon each reservoir holds because of the pulse."),
  c("P caption: not-a-trace sentence cut", "It is not a trace of where those particular molecules", NA),
  c("P caption: tagged note",             "and followed wherever they go", "Right: the same pulse, with its carbon atoms tagged."),
  c("P caption: no 'own' atoms",          "with its own carbon atoms", NA),
  c("P caption: closure sentence cut",    "The shares add to 100%", NA),
  c("P takeaway: surface ocean",          NA, "carbon also mixes into the surface ocean."),
  c("P takeaway: residence lifetime",     NA, "(the rate of decline in the atmosphere in this box informs the “residence lifetime”)."),
  c("P takeaway: deep ocean slow",        NA, "While the land and surface ocean equilibrate quickly, mixing into the deep ocean is a slow process."),
  c("P no ocean-groups placeholder",      "[MARCUS:", NA),
  # "Keys are fine as drafted" (Marcus 2026-10-16)
  c("P key: upper ocean",                 NA, "Upper ocean (0–%s m)"),
  c("P key: intermediate ocean",          NA, "Intermediate ocean (%s–%s m)"),
  c("P key: deep ocean",                  NA, "Deep ocean (below %s m)")
)

test_that("all of Marcus's 2026-10-16 copy rulings are still applied", {
  problems <- ac_audit(.ac_src, AC_CHECKS_1016)
  expect_equal(problems, character(0), info = paste(problems, collapse = " | "))
})

test_that("MUTATION: the 10-16 list fires when a cut phrase returns or his paragraph goes", {
  m1 <- paste(.ac_src, '  note = paste("Right: the same pulse, with its own carbon atoms tagged and followed wherever they go.")', sep = "\n")
  expect_true(any(grepl("P caption: tagged note", ac_audit(m1, AC_CHECKS_1016), fixed = TRUE)))
  m2 <- gsub("mixing into the deep ocean is a slow process.", "mixing is slow.", .ac_src, fixed = TRUE)
  expect_true(any(grepl("P takeaway: deep ocean slow", ac_audit(m2, AC_CHECKS_1016), fixed = TRUE)))
  for (ck in AC_CHECKS_1016) expect_true(!is.na(ck[[2]]) || !is.na(ck[[3]]), info = ck[[1]])
})

test_that("all of Marcus's 2026-10-06 copy rulings are still applied", {
  problems <- ac_audit(.ac_src, AC_CHECKS_1006)
  expect_equal(problems, character(0), info = paste(problems, collapse = " | "))
})

test_that("MUTATION: the 10-06 list fires when the old intro returns or the caveat sentence goes", {
  m1 <- paste(.ac_src, '  p("These are the numbers the calibration fits. Everything else")', sep = "\n")
  expect_true(any(grepl("H1 held rows: the intro clause", ac_audit(m1, AC_CHECKS_1006), fixed = TRUE)))
  m2 <- gsub("the upper ocean becomes more layered and", "the ocean changes and", .ac_src, fixed = TRUE)
  expect_true(any(grepl("W1 warming caveat: DESIGN's sentence", ac_audit(m2, AC_CHECKS_1006), fixed = TRUE)))
})

test_that("MUTATION: the 10-01 list fires when the deleted fertilisation sentence returns", {
  mutated <- paste(.ac_src, '  caveat = paste("In this model CO₂ fertilization IS the land sink")', sep = "\n")
  expect_true(any(grepl("IS the land sink", ac_audit(mutated, AC_CHECKS_1001), fixed = TRUE)))
})

test_that("every check actually checks something", {
  for (ck in AC_CHECKS)
    expect_true(!is.na(ck[[2]]) || !is.na(ck[[3]]),
                info = paste("check specifies neither side:", ck[[1]]))
})

# ---------------------------------------------------------------------
# MUTATION TESTS -- each shows the gate REJECTS what it claims to reject.
# ---------------------------------------------------------------------

test_that("MUTATION: an absent-check fires when the old wording returns to CODE", {
  # Not a comment: the reverted sentence as it would appear back in a tags$p().
  mutated <- paste(.ac_src, '  p("No ocean circulation -- diffusion only.")', sep = "\n")
  problems <- ac_audit(mutated)
  expect_true(any(grepl("U5", problems, fixed = TRUE)),
              info = paste("gate missed a reverted line:", paste(problems, collapse = " | ")))
})

test_that("MUTATION: a present-check fires when the replacement wording is deleted", {
  mutated <- gsub("meet only in the atmosphere", "meet somewhere", .ac_src, fixed = TRUE)
  problems <- ac_audit(mutated)
  expect_true(any(grepl("U5", problems, fixed = TRUE)),
              info = paste("gate missed a deleted replacement:", paste(problems, collapse = " | ")))
})

test_that("MUTATION: the comment strip is what keeps the six documented items green", {
  # The measured false-failure mode: matching RAW source (comments included)
  # reports misses for the six items whose fix is documented by a comment that
  # quotes the old wording. If this ever drops to zero, the comments went away
  # and the strip is no longer load-bearing -- not that the gate got better.
  raw <- paste(unlist(lapply(
    file.path(.root, AC_COPY_FILES)[file.exists(file.path(.root, AC_COPY_FILES))],
    function(p) readLines(p, warn = FALSE))), collapse = "\n")
  expect_true(length(ac_audit(raw)) > length(ac_audit(.ac_src)),
              info = "stripping comments changed nothing; the strip is untested here")
})

test_that("MUTATION: the strip removes whole-line comments and nothing else", {
  lines <- c("  # No ocean circulation", "#' No ocean circulation",
             'p("No ocean circulation")', "x <- 1  # No ocean circulation")
  kept <- ac_strip_comments(lines)
  expect_equal(length(kept), 2L)
  expect_true(any(grepl("p(\"", kept, fixed = TRUE)))
  expect_true(any(grepl("x <- 1", kept, fixed = TRUE)))
})
