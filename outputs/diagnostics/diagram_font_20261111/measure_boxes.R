# Each box's drawn extent (ink bounding box) in px and data units, on both fonts, at 565 px (scale 1).
root <- normalizePath("."); source(file.path(root, "tests/testthat/helper-diagram-pixels.R"))
suppressMessages(library(ggplot2))
app <- suppressMessages(shiny::shinyAppDir(file.path(root, "app")))
shiny::testServer(app, {
  AE <- environment(renderPlotFit); A <- function(nm) get(nm, envir = AE); h <- A("APP_HIST")$out
  W <- 565L; H <- A("diagram_height_px")(W)
  for (font in c("system", "dejavu")) {
    dgp_use_font(font)
    p <- A("plot_box_diagram")(A("APP_FLUX_NOW"), h[nrow(h), ], A("app_params")$p, n_layers = A("APP_SPIN")$grid$nl, scale = 1)
    b <- ggplot_build(p); xr <- b$layout$panel_params[[1]]$x.range; yr <- b$layout$panel_params[[1]]$y.range
    k <- which(vapply(p$layers, function(l) inherits(l$geom, "GeomLabel"), NA)); bx <- p$layers[[k]]$data
    cat(sprintf("== %s; x range %.3f..%.3f (%.2f px/unit), y range %.3f..%.3f (%.2f px/unit)\n", font, xr[1], xr[2],
                W / diff(xr), yr[1], yr[2], H / diff(yr)))
    for (i in seq_len(nrow(bx))) {
      m <- dgp_ink(dgp_only(p, k, i), W, H); r <- range(which(rowSums(m) > 0)); c <- range(which(colSums(m) > 0))
      ux <- xr[1] + (c - 0.5) / W * diff(xr); uy <- yr[2] - (r - 0.5) / H * diff(yr)
      cat(sprintf("  %-22s px w %3d h %2d | data x %.3f..%.3f (half %.3f) y %.3f..%.3f (half %.3f)\n", sub("\n.*", "", bx$lab[i]),
                  diff(c) + 1L, diff(r) + 1L, ux[1], ux[2], diff(ux) / 2, uy[2], uy[1], diff(rev(uy)) / 2))
    }
  }
  dgp_reset_font()
})
