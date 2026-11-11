# =====================================================================
# test-diagram-pixels.R -- the box diagram ("Under the hood") on PIXELS, in this machine's font and in the host's
# (2026-11-11, CHANGELOG 2026-11-11 n; helpers in helper-diagram-pixels.R).
#
# What it found: on the host's DejaVu Sans, about 22 % wider in bold than this machine's Helvetica, the font-sized
# boxes grew over the fixed arrow ends. The litterfall arrowhead was hidden under the Soil box and the land-use arrow
# lay on Soil's corner. In BOTH fonts, two arrowheads (air to warm sea, air to cold sea) ended inside their boxes, and
# labels offset by a fraction of each line's width ("62", "1.2") sat ~1 px from their arrows. The diagram now has
# fixed-size boxes, arrows placed on box edges, labels at a fixed gap and two tiers of labels (app/R/plots.R).
#
# THE WIDTHS are the ones the app draws (measured 2026-11-11 in headless Chrome): 565 on a phone (drawn at its tuned
# width, scrolled sideways), 552 at the narrowest panel (576 px viewport; also ~555 at 992), 815 at a 1440 px screen.
# Text scales with the width up to 904 px (DIAGRAM_SCALE_RANGE), so between those widths the drawing is one shape.
# =====================================================================

.dp_app_dir <- file.path(.root, "app")
DP_WIDTHS <- c(552L, 565L, 815L)
skip_if_no_dp <- function() {
  for (pk in c("shiny", "ggplot2", "bslib", "ragg", "systemfonts")) skip_if_not_installed(pk)
  skip_if(!file.exists(file.path(.dp_app_dir, "R", "plots.R")), "app files absent")
  skip_if_no_cpp(); skip_if_no_climate()
}
# clearance in px scales with the text: 2 px at the tuned size
dp_clear <- function(e, W) max(1, round(2 * get("diagram_scale", envir = e)(W)))
dp_free <- function(el) grep("^land-use", names(el$arrow), value = TRUE)
dp_with_app <- function(f) {
  app <- suppressMessages(shiny::shinyAppDir(.dp_app_dir))
  shiny::testServer(app, {
    AE <- environment(renderPlotFit); h <- get("APP_HIST", envir = AE)$out
    build <- function(W) get("plot_box_diagram", envir = AE)(
      get("APP_FLUX_NOW", envir = AE), h[nrow(h), ], get("app_params", envir = AE)$p,
      n_layers = get("APP_SPIN", envir = AE)$grid$nl, scale = get("diagram_scale", envir = AE)(W))
    f(AE, build)
  })
}
dp_run_font <- function(font) {
  on.exit(dgp_reset_font(), add = TRUE)
  dgp_use_font(font)
  dp_with_app(function(AE, build) {
    for (W in DP_WIDTHS) {
      el <- dgp_elements(build(W), W, get("diagram_height_px", envir = AE)(W))
      # footnote edges only in the platform font: under DejaVu the wrap is still MEASURED in the default family
      # (app_wrap_px), so its lines are too long for the emulated font (on the host both are DejaVu)
      bad <- dgp_check(el, clear = dp_clear(AE, W), free = dp_free(el), notes_edge = font == "system")
      expect_identical(nrow(bad), 0L,
                       info = sprintf("%s font, %d px: %s", font, W,
                                      paste(sprintf("%s: %s / %s (%s)", bad$check, bad$a, bad$b, bad$px), collapse = "; ")))
      expect_gte(length(el$head), 13L)   # every arrow was found and checked (13 with the cold boxes)
    }
  })
}

test_that("1. in this machine's font, no text touches an arrow, box or other text, and every arrowhead shows", {
  skip_if_no_dp()
  dp_run_font("system")
})

test_that("2. the same in DejaVu Sans, the host's font", {
  skip_if_no_dp()
  skip_if(is.null(dgp_dejavu_dir()), "DejaVu Sans not found (set CCX_DEJAVU_DIR); the host's font is not checked")
  dp_run_font("dejavu")
})

# POWER: each kind of fault, planted in the built plot, is reported. The plot's layers are ggproto objects (shared
# environments), so a fault goes into a CHILD of the layer, never the layer itself.
dp_mutate <- function(p, geom, f, has = NULL) {
  ks <- which(vapply(p$layers, function(l) class(l$geom)[1] == geom &&
                       (is.null(has) || (is.data.frame(l$data) && all(has %in% names(l$data)))), NA))
  k <- ks[1]; l <- ggplot2::ggproto(NULL, p$layers[[k]]); f(l); q <- p; q$layers[[k]] <- l; q
}
test_that("3. the pixel checks have power: each planted fault is reported", {
  skip_if_no_dp()
  on.exit(dgp_reset_font(), add = TRUE)
  dgp_use_font("system")
  W <- 565L
  dp_with_app(function(AE, build) {
    H <- get("diagram_height_px", envir = AE)(W); p <- build(W)
    found <- function(q, check, a_rx) {
      el <- dgp_elements(q, W, H); bad <- dgp_check(el, clear = dp_clear(AE, W), free = dp_free(el))
      any(bad$check == check & grepl(a_rx, bad$a))
    }
    seg <- function(q, row, ...) dp_mutate(q, "GeomSegment", function(l) { d <- l$data; v <- list(...)
      for (n in names(v)) d[[n]][row] <- v[[n]]; l$data <- d })
    lab <- function(q, rx, ...) dp_mutate(q, "GeomText", function(l) { d <- l$data; i <- grep(rx, d$nm); v <- list(...)
      for (n in names(v)) d[[n]][i] <- v[[n]]; l$data <- d }, has = c("nm", "val"))
    a <- p$layers[[which(vapply(p$layers, function(l) inherits(l$geom, "GeomSegment"), NA))]]$data
    r_lit <- grep("^litterfall", a$nm); r_luc <- grep("^land-use", a$nm)
    soil <- get("DIAGRAM_BOX_HW", envir = AE)[["soil"]]
    expect_true(found(seg(p, r_lit, xend = 2.85), "arrowhead under a box", "^litterfall"))           # head to Soil's centre
    expect_true(found(seg(p, r_lit, x = a$xend[r_lit] - 0.08), "arrow shaft too short", "^litterfall"))
    expect_true(found(seg(p, r_luc, x = 2.85 - soil, xend = 2.85 - soil), "arrow grazes a box", "^land-use"))
    expect_true(found(lab(p, "^photosynthesis", hj = 0.5, vj = 0.5, lx = 1.05, ly = 3.5), "text on an arrow", "^photosynthesis"))
    expect_true(found(lab(p, "^respiration", lx = 1.75, ly = 3.4, hj = 0, vj = 0.5), "text on text", "land-use|respiration"))
    expect_true(found(lab(p, "^respiration", lx = 3.3, ly = 2.35, hj = 0.5, vj = 0.5), "text on a box", "^respiration"))
    expect_true(found(lab(p, "^photosynthesis", lx = 0.4), "text at the image edge", "^photosynthesis"))   # half off
    # wholly off: an anchor outside xlim() is DROPPED by the scale (with this warning), so the label leaves no ink at all;
    # an anchor inside the limits cannot put a label wholly off the image (the limits sit 5 % inside its edges)
    expect_warning(off <- found(lab(p, "^photosynthesis", lx = -0.35), "text not drawn", "^photosynthesis"),
                   "outside the scale range")
    expect_true(off)
    expect_true(found(dp_mutate(p, "GeomText", function(l) { d <- l$data; d$lab[d$id == "soil"] <- "Soil\n(fast + slow + inert + more)"
      l$data <- d }, has = c("hw", "lab")), "name outside its box", "^Soil"))
  })
})
