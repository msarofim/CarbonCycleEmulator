# =====================================================================
# Lint: the app's reader-facing text uses U.S. spelling (Marcus 2026-10-15: "Update spelling in the app to
# be U.S. spelling"; CHANGELOG 2026-10-15 f).
#
# WHAT IT READS. Every STRING LITERAL (R's own parser, getParseData() STR_CONST: comments, identifiers and
# list names are never read) in the app's sources and in R/mechanisms.R, whose label / blurb / caveat the
# What-if tab renders. Code identifiers keep their spelling: the mechanism key `fertilisation`, ggplot's
# `colour` aesthetic, R's colour names (grey20 ...). Comments are not app text and are not linted.
# NOT READ: the data artifacts' provenance notes and field names (none is rendered; checked 2026-10-15),
# and R/constants.R's notes (the app shows only the provisional constants' NAMES).
# =====================================================================

US_SPELL_FILES <- c(file.path("app", c("global.R", "server.R", "ui.R")),
                    file.path("app", "R", list.files(file.path(.root, "app", "R"), pattern = "\\.R$")),
                    file.path("R", "mechanisms.R"))
# British forms, word-bounded and case-insensitive. -yse is matched only as a verb ("analyses" is also the
# U.S. plural of "analysis").
US_SPELL_BRITISH <- paste0("(?i)\\b(",
  "fertilis\\w*|\\w+isations?|",
  "(organi|reali|recogni|summari|characteri|emphasi|minimi|maximi|stabili|normali|optimi|parameteri|utili|",
  "harmoni|digiti|equali|neutrali|categori|prioriti|visuali|generali|standardi|initiali|lineari|discreti|",
  "regulari|vapori|(re)?minerali|oxidi|acidi|ioni|mobili|centrali|seasonali|deseasonali)s(e|es|ed|ing)|",
  "(analy|cataly|paraly)s(e|ed|ing)|",
  "colour\\w*|behaviour\\w*|favour\\w*|neighbour\\w*|labour\\w*|honour\\w*|vapour\\w*|",
  "centre[sd]?|centring|metres?|litres?|fibres?|grey(ish)?|",   # centring: missed until 2026-10-15 (issue 1)
  "modell(ed|ing|er|ers)|labell(ed|ing)|travell\\w*|cancell(ed|ing)|signall(ed|ing)|",
  "artefact\\w*|ageing|judgement|whilst|amongst|programmes?|sulph\\w*|palaeo\\w*|aluminium|",
  "licence|defence|offence|catalogue|analogue|per cent",
  ")\\b")
# Strings that keep a British form on purpose: a proper name, and a ggplot argument value.
US_SPELL_ALLOW <- c("Met Office Hadley Centre HadSST.4.2.0.0", "colour")

us_spell_strings <- function(src_lines, file) {
  pd <- utils::getParseData(parse(text = src_lines, keep.source = TRUE, encoding = "UTF-8"))
  s <- pd[pd$token == "STR_CONST", c("id", "line1")]
  # getParseText(), not pd$text: getParseData() abbreviates a long string to "[N chars quoted ...]"
  s$text <- vapply(utils::getParseText(pd, s$id), function(t) eval(parse(text = t, encoding = "UTF-8")),
                   character(1), USE.NAMES = FALSE)
  s$file <- file
  s
}
us_spell_hits <- function(strs) {
  strs <- strs[!strs$text %in% US_SPELL_ALLOW, , drop = FALSE]
  m <- regmatches(strs$text, gregexpr(US_SPELL_BRITISH, strs$text, perl = TRUE))
  i <- lengths(m) > 0L
  if (!any(i)) return(character(0))
  sprintf("%s:%d %s", strs$file[i], strs$line1[i], vapply(m[i], paste, character(1), collapse = ", "))
}
.us_all <- do.call(rbind, lapply(US_SPELL_FILES, function(f)
  us_spell_strings(readLines(file.path(.root, f), warn = FALSE, encoding = "UTF-8"), f)))

test_that("the app's reader-facing strings use U.S. spelling", {
  expect_gt(nrow(.us_all), 1000L)             # the parser read the app, not an empty file list
  h <- us_spell_hits(.us_all)
  expect_equal(h, character(0), info = paste(h, collapse = " | "))
})

test_that("MUTATION: British forms in a string are caught; comments, identifiers and the allowlist are not", {
  src <- c('x <- paste("CO₂ fertilisation, the grey band, the colours and cubic metres, re-centring")',
           '# a comment about fertilisation and colour',
           'fertilisation <- list(label = "CO₂ fertilization")',
           'scale_colour_hue(aesthetics = c("colour", "fill"))',
           'src <- "Met Office Hadley Centre HadSST.4.2.0.0"',
           'y <- "the analyses agree"')
  h <- us_spell_hits(us_spell_strings(src, "mut.R"))
  expect_length(h, 1L)
  expect_match(h, "^mut.R:1 ")
  for (w in c("fertilisation", "grey", "colours", "metres", "centring")) expect_match(h, w, fixed = TRUE)
})
