# The diagram in DejaVu at the LIVE scale: the app takes the text scale from the panel width Shiny reports (815.984375 px
# at a 1440 px viewport) and draws an 815 x 696 image. Saves the render and runs the pixel gate at that scale.
# Usage (repo root): Rscript render_live_scale.R <out_png> <image_w> <image_h> <client_width>
root <- normalizePath("."); source(file.path(root, "tests/testthat/helper-diagram-pixels.R"))
a <- commandArgs(trailingOnly = TRUE); out <- normalizePath(dirname(a[1])); out <- file.path(out, basename(a[1]))
W <- as.integer(a[2]); H <- as.integer(a[3]); cw <- as.numeric(a[4])
suppressMessages(library(ggplot2))
app <- suppressMessages(shiny::shinyAppDir(file.path(root, "app")))
shiny::testServer(app, {
  AE <- environment(renderPlotFit); A <- function(nm) get(nm, envir = AE); h <- A("APP_HIST")$out
  dgp_use_font("dejavu"); sc <- A("diagram_scale")(cw)
  p <- A("plot_box_diagram")(A("APP_FLUX_NOW"), h[nrow(h), ], A("app_params")$p, n_layers = A("APP_SPIN")$grid$nl, scale = sc)
  ragg::agg_png(out, width = W, height = H, res = 72); print(p); grDevices::dev.off()
  el <- dgp_elements(p, W, H)
  bad <- dgp_check(el, clear = max(1, round(2 * sc)), free = grep("^land-use", names(el$arrow), value = TRUE), notes_edge = FALSE)
  cat(sprintf("scale %.5f, %d x %d: %d problems\n", sc, W, H, nrow(bad))); if (nrow(bad)) print(bad, row.names = FALSE)
  dgp_reset_font()
})
