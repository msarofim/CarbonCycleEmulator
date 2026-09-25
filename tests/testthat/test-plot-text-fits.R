# =====================================================================
# Gate: no text slot in app/R/plots.R may be wider than the panel it is drawn in.
#
# ⛔⛔ THE AUDIT THIS COMES FROM (2026-09-25). ggplot captions and subtitles CLIP
# rather than wrap, and the repo's fix for that was `strwrap(width = 150)` — a
# count of CHARACTERS, where what clips is PIXELS. Measured against the panels
# the plots are really drawn in:
#   * 150 characters is up to 683 px; the full panel is 552 px at the narrowest
#     side-by-side layout, so every full-panel caption clipped below a ~1030 px
#     viewport.
#   * `w_af` and `w_gcb` are 264 px and were handed the same caption. Those two
#     had been clipping at EVERY viewport width. Seen on screen, not just
#     computed: "Model: posterior mode (single best fit). Not peer-" is where it
#     stopped.
#   * The subtitle added on 09-24 (o) measured 549 px against a 552 px panel and
#     clipped anyway — the measurement had ignored the plot's own 16 px margin.
#
# ⚠ THE SLOTS THAT WERE FINE. Axis titles, legend keys and the in-panel
# annotations all fit with room to spare; the failure was concentrated in the one
# slot family everybody believed was already fixed. That is why this gate covers
# EVERY slot rather than the ones that happened to be wrong.
#
# ⚠ MEASUREMENT NEEDS A DEVICE, so each test opens one at the panel's own size.
# ⚠ The numbers are this machine's fonts. APP_TEXT_SAFETY is the headroom for a
# deploy host whose fonts are not these, and it is why the assertions are against
# the budget rather than against the raw panel width.
# =====================================================================

.pt_plots <- file.path(.root, "app", "R", "plots.R")

skip_if_no_plots <- function() {
  skip_if_not_installed("ggplot2")
  skip_if(!file.exists(.pt_plots), "app/R/plots.R absent")
}

.pt_env <- local({
  e <- new.env(parent = globalenv())
  assign("app_params", list(source = "posterior mode (single best fit)",
                            status = "Not peer-reviewed teaching software"), envir = e)
  assign("APP_LUC_SMOOTH_YR", 11L, envir = e)
  assign("APP_LUC_SPLIT_NOTE", NULL, envir = e)
  ok <- tryCatch({ suppressMessages(library(ggplot2)); sys.source(.pt_plots, envir = e); TRUE },
                 error = function(err) FALSE)
  if (ok) e else NULL
})

# longest rendered LINE, in px at res 72 — the quantity that clips
pt_px <- function(s, pt) {
  if (is.null(s) || !nzchar(paste(s, collapse = ""))) return(0)
  lines <- unlist(strsplit(paste(s, collapse = "\n"), "\n", fixed = TRUE))
  max(vapply(lines, function(l)
    grid::convertWidth(grid::grobWidth(grid::textGrob(l, gp = grid::gpar(fontsize = pt))),
                       "in", valueOnly = TRUE), numeric(1))) * 72
}
pt_with_device <- function(px, expr) {
  f <- tempfile(fileext = ".png")
  grDevices::png(f, width = max(px, 200), height = 330, res = 72)
  on.exit({ grDevices::dev.off(); unlink(f) }, add = TRUE)
  force(expr)
}

test_that("1. every caption fits the panel it is drawn in, at both widths", {
  skip_if_no_plots(); skip_if(is.null(.pt_env), "plots.R did not load")
  e <- .pt_env
  extras <- list(NULL, e$LAB_LUC_CAPTION, e$IMB_BAND_SHORT, e$GROWTH_UNIT_NOTE,
                 e$PULSE_PARTITION_NOTE)
  for (panel in c("full", "half")) {
    budget <- e$app_text_px(panel)
    pt_with_device(e$APP_PANEL_PX[[panel]], {
      for (x in extras) {
        cap <- e$app_provenance_caption(x, panel = panel)
        expect_lte(pt_px(cap, e$CAPTION_PT), budget)
      }
    })
  }
})

test_that("2. every subtitle fits, including the one that clipped", {
  skip_if_no_plots(); skip_if(is.null(.pt_env), "plots.R did not load")
  e <- .pt_env
  subs <- c(
    sprintf(paste("%d-yr centred mean, so each bold line stops %d yr short at both ends",
                  "— the thin annual line does not, and the recent years are on it.",
                  "Land-use emissions are OUTSIDE this sink, as GCB reports it."), 11L, 5L),
    sprintf("Shaded: before %d, the split itself is back-extended, not observed", 1959L))
  pt_with_device(e$APP_PANEL_PX[["full"]], {
    for (s in subs)
      expect_lte(pt_px(e$app_subtitle(s), e$SUBTITLE_PT), e$app_text_px("full"))
  })
})

test_that("3. axis titles fit the narrowest panel that carries one", {
  skip_if_no_plots(); skip_if(is.null(.pt_env), "plots.R did not load")
  e <- .pt_env
  # \u26d4 CLASSIFY BY PREFIX, not by a glob over every constant. `LAB_*` is an
  # axis title; the first draft of this test measured NOTE_LUC_SPLIT (caption
  # prose, 1,299 px) and KEY_LUC_NET (a legend key) as though they were axis
  # titles and reported two failures that were not failures.
  labs <- unlist(mget(grep("^LAB_", ls(e), value = TRUE), envir = e))
  labs <- labs[vapply(labs, is.character, logical(1))]
  # the two HALF-width plots label their y axes with literals, not constants
  half_labs <- c("Share of all emissions still in the air", "Average uptake (GtC per year)")
  pt_with_device(e$APP_PANEL_PX[["half"]], {
    for (s in half_labs)
      expect_lte(pt_px(s, e$CCX_BASE_SIZE), e$app_text_px("half"))
    for (nm in names(labs))
      expect_lte(pt_px(labs[[nm]], e$CCX_BASE_SIZE), e$app_text_px("full"))
  })
})

test_that("3b. legend keys fit, as a ROW and not only one at a time", {
  skip_if_no_plots(); skip_if(is.null(.pt_env), "plots.R did not load")
  e <- .pt_env
  keys <- unlist(mget(grep("^KEY_", ls(e), value = TRUE), envir = e))
  keys <- keys[vapply(keys, is.character, logical(1))]
  # \u26a0 A legend draws its keys SIDE BY SIDE, so the row is what has to fit --
  # each key on its own always does. The glyph + padding before each label is
  # approximated by a fixed allowance per key.
  GLYPH_PX <- 34
  pt_with_device(e$APP_PANEL_PX[["full"]], {
    for (nm in names(keys))
      expect_lte(pt_px(keys[[nm]], e$SUBTITLE_PT), e$app_text_px("full"))
    for (row in list(c("KEY_IMB_MODEL", "KEY_IMB_GCB", "KEY_IMB_BAND"),
                     c("KEY_LUC_GROSS", "KEY_LUC_REGROW", "KEY_LUC_NET"))) {
      w <- sum(vapply(row, function(k) pt_px(get(k, envir = e), e$SUBTITLE_PT) + GLYPH_PX,
                      numeric(1)))
      # both of these legends are set to wrap onto 2 rows in their plot, so the
      # budget they must meet is two panel widths, not one
      expect_lte(w, 2 * e$app_text_px("full"))
    }
  })
})

test_that("4. the wrapper respects its budget on adversarial input", {
  skip_if_no_plots(); skip_if(is.null(.pt_env), "plots.R did not load")
  e <- .pt_env
  pt_with_device(552, {
    long <- paste(rep("reproducible", 60), collapse = " ")
    for (px in c(504, 233, 120)) {
      w <- pt_px(e$app_wrap_px(long, px, e$CAPTION_PT), e$CAPTION_PT)
      expect_lte(w, px)
    }
    # MUTATION: the retired character-count wrap must FAIL the same budget, or
    # this gate is not guarding the thing that was wrong.
    old <- paste(strwrap(e$app_provenance_caption(e$LAB_LUC_CAPTION), width = e$APP_CAP_WIDTH),
                 collapse = "\n")
    expect_gt(pt_px(old, e$CAPTION_PT), e$app_text_px("half"))
  })
})

test_that("5. the half-width plots, and only those, narrow their captions", {
  skip_if_no_plots(); skip_if(is.null(.pt_env), "plots.R did not load")
  e <- .pt_env
  src <- readLines(.pt_plots, warn = FALSE)
  # \u26a0 SKIP COMMENTS. The first draft matched the sentence in plots.R that
  # DESCRIBES this rule and attributed `panel = "half"` to theme_ccx().
  src <- src[!grepl("^\\s*#", src)]
  fn <- NA_character_; got <- character(0)
  for (l in src) {
    m <- regmatches(l, regexec("^([a-zA-Z_.][a-zA-Z0-9_.]*) *<- *function", l))[[1]]
    if (length(m) == 2L) fn <- m[2]
    if (grepl('panel = "half"', l, fixed = TRUE) && !is.na(fn)) got <- union(got, fn)
  }
  expect_setequal(got, e$APP_HALF_WIDTH_PLOTS)
})
