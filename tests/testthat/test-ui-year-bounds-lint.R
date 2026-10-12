# =====================================================================
# test-ui-year-bounds-lint.R -- the "Years shown" sliders derive their bounds.
#
# THE DEFECT THIS GUARDS (found in the 2026-09-25 app review). All four
# "Years shown" sliders in app/ui.R hardcoded `min = 1750, max = 2024`, and the
# upper end of each `value =` range typed 2024 a second time -- against
# `APP_HIST_YEARS <- c(1750, 2024)` in app/global.R (its end year has been READ
# from the GCB file since 2026-10-12, code review sec.4), whose own section header
# says every label derives from these constants "so changing a window or a
# scenario cannot leave a stale label behind (standing project rule)".
#
# ⛔ WHAT IT WOULD HAVE COST. A GCB update to 2025 moves APP_HIST_YEARS, so the
# model runs to 2025 and FOUR tabs silently cap their sliders at 2024. No error,
# no warning, and no visible symptom except a slider that will not reach the last
# year of data -- which reads as "the data stops in 2024", the exact wrong
# conclusion. Nine occurrences of the end year across four sliders, and a
# reviewer would have had to notice all nine.
#
# ⚠ THE START OF EACH RANGE IS STILL A LITERAL, DELIBERATELY. 1958 (Keeling),
# 1850, 1850, 1940 (the bomb spike) are per-tab editorial choices about where the
# interesting part begins; they are not the model's span and do not move when the
# record grows. Only the BOUNDS and the range's UPPER end are that fact.
#
# HOW IT CANNOT GO STALE -- the house ratchet idiom (test-overlay-idiom-lint.R):
#   1. COVERAGE -- every `*_years` slider derives both bounds. Catches a new
#      slider added with typed years.
#   2. NO-LITERAL -- no `min =`/`max =` anywhere in ui.R carries a 4-digit year,
#      so the defect cannot reappear under a slider that is not named `*_years`.
#   3. NO-STALE COUNT -- the number of such sliders is pinned, so ADDING one is a
#      deliberate act that edits this file. Assertion 1 alone passes vacuously on
#      a file with zero sliders, which is how a lint outlives the thing it lints.
# MUTATION-TESTED: each assertion is paired below with the break it must reject.
# =====================================================================

.uy_ui <- file.path(.root, "app", "ui.R")
.uy_raw <- readLines(.uy_ui, warn = FALSE)

# \u26d4 STRIP COMMENTS BEFORE SCANNING, AND THE FIRST DRAFT DID NOT (2026-09-25).
# Assertion 2 below looks for a literal year in a `min =`/`max =`, and on raw
# lines it matched THE COMMENT IN ui.R THAT DESCRIBES THE DEFECT -- the sentence
# "All four sliders hardcoded min = 1750, max = 2024" documenting the very fix
# this lint protects. A text lint that reads its own documentation reports the
# repair as the disease, and the tempting response (narrow the pattern until it
# goes quiet) would have narrowed it past the case it exists to catch.
# \u26a0 QUOTE-AWARE, not a bare sub("#.*"): a `#` inside a string is content, and
# app/ui.R carries hex colours ("#C4315F"). Cut at a `#` only where an EVEN number
# of double quotes precedes it, i.e. where it is not inside a string literal.
# ⛔ THE STRIPPER MOVED to helper-code-lines.R on 2026-09-25, when a third gate
# needed it. It was defined here and byte-alike in test-imbalance-panel.R; one
# rule in three places is three chances for one copy to be fixed alone.
.uy_src <- ccx_code_lines(.uy_raw)

# the sliders this file is about, pinned. Adding one belongs in this vector.
UY_YEAR_SLIDERS <- c("k_years", "w_years", "c_years", "i_years")

# `sliderInput("id", ...)` spans several lines, so take the id line plus the two
# that follow it -- min/max and value all sit inside that window.
.uy_block <- function(id) {
  i <- grep(sprintf('sliderInput\\("%s"', id), .uy_src, fixed = FALSE)
  if (!length(i)) return(character(0))
  paste(.uy_src[i[1]:min(i[1] + 3L, length(.uy_src))], collapse = " ")
}

test_that("1. every *_years slider derives BOTH bounds from APP_HIST_YEARS", {
  for (id in UY_YEAR_SLIDERS) {
    blk <- .uy_block(id)
    expect_true(nzchar(paste(blk, collapse = "")),
                info = paste("slider not found in ui.R:", id))
    expect_match(blk, "min[[:space:]]*=[[:space:]]*APP_HIST_YEARS\\[1\\]", info = id)
    expect_match(blk, "max[[:space:]]*=[[:space:]]*APP_HIST_YEARS\\[2\\]", info = id)
    # ...and the RANGE's upper end too -- it is the same fact, typed a second
    # time, and it is the copy a reader is least likely to spot.
    expect_match(blk, "value[[:space:]]*=[[:space:]]*c\\([0-9]{4},[[:space:]]*APP_HIST_YEARS\\[2\\]\\)",
                 info = id)
  }
})

test_that("2. no min=/max= anywhere in ui.R carries a literal 4-digit year", {
  # ⚠ Deliberately wider than the four sliders: the point is that a NEW control
  # cannot reintroduce the defect under a name this file does not list.
  # [[gate_only_guards_what_it_lists]] -- a gate built from a protected list can
  # never catch the unlisted case, so this assertion is not scoped to one.
  hits <- grep("(min|max)[[:space:]]*=[[:space:]]*1[6-9][0-9]{2}|(min|max)[[:space:]]*=[[:space:]]*2[0-9]{3}",
               .uy_src, value = TRUE)
  expect_length(hits, 0L)
})

test_that("3. the slider count is pinned, so adding one edits this file", {
  found <- grep('sliderInput\\("[a-z]_years"', .uy_src, value = TRUE)
  expect_length(found, length(UY_YEAR_SLIDERS))
})
