# Pixel collisions in the box diagram, on this machine's sans and on DejaVu Sans (the host's), at the drawn widths.
# Uses tests/testthat/helper-diagram-pixels.R. Usage (repo root): Rscript check_diagram.R [width ...]
root <- normalizePath("."); source(file.path(root, "tests/testthat/helper-diagram-pixels.R"))
widths <- as.integer(commandArgs(trailingOnly = TRUE)); if (!length(widths)) widths <- c(552L, 565L, 815L)
suppressMessages(library(ggplot2))
app <- suppressMessages(shiny::shinyAppDir(file.path(root, "app")))
shiny::testServer(app, {
  AE <- environment(renderPlotFit); A <- function(nm) get(nm, envir = AE); h <- A("APP_HIST")$out
  for (font in c("system", "dejavu")) {
    cat(sprintf("== %s: %s\n", font, basename(dgp_use_font(font))))
    for (W in widths) {
      p <- A("plot_box_diagram")(A("APP_FLUX_NOW"), h[nrow(h), ], A("app_params")$p, n_layers = A("APP_SPIN")$grid$nl,
                                 scale = A("diagram_scale")(W))
      el <- dgp_elements(p, W, A("diagram_height_px")(W))
      bad <- dgp_check(el, clear = max(1, round(2 * A("diagram_scale")(W))), free = grep("^land-use", names(el$arrow), value = TRUE),
                       notes_edge = font == "system")
      cat(sprintf("  %d px: %d problems\n", W, nrow(bad)))
      if (nrow(bad)) print(bad, row.names = FALSE)
    }
  }
  dgp_reset_font()
})
