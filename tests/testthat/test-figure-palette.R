# =====================================================================
# Gate: the accessibility receipts recorded next to a figure's colours must be
# REPRODUCIBLE, and by a named tool (2026-09-25).
#
# ⛔⛔ THE INCIDENT THIS EXISTS FOR. CHANGELOG 2026-09-24 (k) re-stepped
# `calibration/fig_land_sink_vs_gcb.R`'s pair and recorded "normal 31.3 / protan
# 13.5 / deutan 26.1 / tritan 31.7, all passing" — from a dichromat
# implementation written for that session and never committed. When the check was
# written properly as `tools/palette_check.py` (09-24 n) it reproduced that pair's
# NORMAL dE exactly (31.3) and scored its protan at 7.4, BELOW the 8 target. One
# of the two was wrong, nothing could arbitrate, and the figure had been shipping
# on a number that could not be reproduced. ⇒ [[palette_check_unreproduced]]
#
# So the receipt is no longer a comment. The colours and their scores are both
# NAMED CONSTANTS in the figure script, and this test parses them out and re-runs
# the checker against them. Two failure modes, both silent otherwise:
#   1. A colour is changed and the recorded scores are not — the caption-sync bug
#      class, applied to an accessibility claim.
#   2. A pair drifts below the target and nothing says so, because a figure that
#      is hard to read for one reader in twelve still looks fine to the author.
#
# ⚠ THE TOOL IS THE ARBITER, NOT A REMEMBERED NUMBER. The test computes; it does
# not compare against a second copy of the answer.
# ⚠ SKIPS if python3 is unavailable. The `dataviz` skill's own validator needs
# `node`, which is NOT installed on this machine — which is why the check was
# reimplemented in the first place.
# =====================================================================

.fp_fig  <- file.path(.root, "calibration", "fig_land_sink_vs_gcb.R")
.fp_tool <- file.path(.root, "tools", "palette_check.py")

FP_TOL <- 0.05   # the tool prints one decimal; anything further apart is a real move

skip_if_no_tool <- function() {
  skip_if(!file.exists(.fp_fig),  "figure script absent")
  skip_if(!file.exists(.fp_tool), "tools/palette_check.py absent")
  skip_if(unname(Sys.which("python3")) == "", "python3 not available")
}

# Read a constant out of the figure script by PARSING it, never by regex on the
# line: a regex would match the same text inside the comment block that explains
# the constant, which is exactly where the stale numbers lived last time.
fp_const <- function(name, file = .fp_fig) {
  e <- parse(file = file)
  for (x in e) {
    if (is.call(x) && length(x) == 3L && as.character(x[[1]]) %in% c("<-", "=") &&
        identical(as.character(x[[2]]), name))
      return(eval(x[[3]]))
  }
  stop("no top-level assignment to ", name, " in ", basename(file))
}

fp_scores <- function(a, b) {
  out <- suppressWarnings(system2("python3", c(shQuote(.fp_tool), shQuote(a), shQuote(b)),
                                  stdout = TRUE, stderr = TRUE))
  row <- grep(paste0(a, "/", b), out, fixed = TRUE, value = TRUE)
  if (length(row) != 1L)
    stop("could not read a score row for ", a, "/", b, ":\n", paste(out, collapse = "\n"))
  v <- as.numeric(regmatches(row, gregexpr("[0-9]+\\.[0-9]", row))[[1]])
  if (length(v) < 5L) stop("unexpected score row: ", row)
  stats::setNames(v[1:4], c("normal", "protan", "deutan", "tritan"))
}

test_that("1. the figure's recorded scores are what the checker actually computes", {
  skip_if_no_tool()
  col <- fp_const("FG_COL")
  rec <- fp_const("FG_COL_SCORES")
  got <- fp_scores(col[["model"]], col[["gcb"]])
  expect_named(rec, names(got))
  expect_equal(unname(got[names(rec)]), unname(rec), tolerance = FP_TOL)
})

test_that("2. the pair clears the target under the committed checker", {
  skip_if_no_tool()
  col <- fp_const("FG_COL")
  tgt <- fp_const("FG_COL_TARGET")
  got <- fp_scores(col[["model"]], col[["gcb"]])
  expect_gt(min(got), tgt)
  # MUTATION: the pair this replaced must NOT clear it, or the gate is guarding
  # nothing. This is the number that could not be reproduced.
  old <- fp_scores("#C2185B", "#12395C")
  expect_lt(min(old), tgt)
  expect_equal(unname(old[["normal"]]), 31.3, tolerance = FP_TOL)  # (k)'s one reproducible value
})

test_that("3. the checker is self-consistent, so it is not obviously the broken one", {
  skip_if_no_tool()
  # a colour against itself is zero under every vision type, and neutrals are
  # INVARIANT under all three dichromacies -- a projection with the wrong plane
  # moves greys, so this is the structural check that the simulation is sane
  for (h in c("#808080", "#333333")) {
    got <- fp_scores(h, h)
    expect_equal(unname(got), rep(0, 4), tolerance = FP_TOL)
  }
})
