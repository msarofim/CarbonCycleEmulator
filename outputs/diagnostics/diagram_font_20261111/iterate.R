# One layout iteration: for each font and width, save the diagram as drawn and list the pixel gate's problems.
# Usage (repo root): Rscript iterate.R <out_prefix> [width ...]
root <- normalizePath("."); source(file.path(root, "tests/testthat/helper-diagram-pixels.R"))
a <- commandArgs(trailingOnly = TRUE); pre <- normalizePath(dirname(a[1])); pre <- file.path(pre, basename(a[1]))
widths <- as.integer(a[-1]); if (!length(widths)) widths <- 565L
suppressMessages(library(ggplot2))
app <- suppressMessages(shiny::shinyAppDir(file.path(root, "app")))
shiny::testServer(app, {
  AE <- environment(renderPlotFit); A <- function(nm) get(nm, envir = AE); h <- A("APP_HIST")$out
  for (font in c("system", "dejavu")) {
    dgp_use_font(font)
    for (W in widths) {
      sc <- A("diagram_scale")(W); H <- A("diagram_height_px")(W)
      p <- A("plot_box_diagram")(A("APP_FLUX_NOW"), h[nrow(h), ], A("app_params")$p, n_layers = A("APP_SPIN")$grid$nl, scale = sc)
      f <- sprintf("%s_%s_%d.png", pre, font, W); ragg::agg_png(f, width = W, height = H, res = 72); print(p); grDevices::dev.off()
      bad <- dgp_check(dgp_elements(p, W, H), clear = max(1, round(2 * sc)), free = "land-use change (1.18)",
                       notes_edge = font == "system")
      cat(sprintf("== %s %d px: %d problems\n", font, W, nrow(bad))); if (nrow(bad)) print(bad, row.names = FALSE)
    }
  }
  dgp_reset_font()
})
