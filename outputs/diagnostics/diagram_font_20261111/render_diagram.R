# Draw the box diagram as the app does, with ragg, on this machine's "sans" (Helvetica) or on DejaVu Sans, the
# default sans of the host's Ubuntu (2026-11-11, the litterfall arrowhead hidden on the host only; CHANGELOG 11-11 n).
# DejaVu comes from matplotlib's copy in the miniforge package cache and is registered as "sans" for this process only.
# Usage (from the repo root): Rscript render_diagram.R <system|dejavu> <out_dir> <width_px> [...]
args <- commandArgs(trailingOnly = TRUE); font <- args[1]; widths <- as.integer(args[-(1:2)])
out_dir <- normalizePath(args[2])   # absolute: testServer() runs inside app/
DEJAVU_DIR <- "/Users/MarcusMarcus/miniforge3/pkgs/matplotlib-base-3.8.4-py310hedb7998_2/lib/python3.10/site-packages/matplotlib/mpl-data/fonts/ttf"
if (identical(font, "dejavu"))
  systemfonts::register_font("sans", plain = file.path(DEJAVU_DIR, "DejaVuSans.ttf"),
                             bold = file.path(DEJAVU_DIR, "DejaVuSans-Bold.ttf"),
                             italic = file.path(DEJAVU_DIR, "DejaVuSans-Oblique.ttf"),
                             bolditalic = file.path(DEJAVU_DIR, "DejaVuSans-BoldOblique.ttf"))
cat("sans ->", systemfonts::match_fonts("sans", weight = "bold")$path, "\n")
# ggplot draws text in the default family "", which ragg resolves to the system default and NOT through the
# registry (measured: registering "sans" moved family "sans" only). So the geoms are pointed at "sans", which on
# this machine is Helvetica either way and on the host fontconfig's default sans.
suppressMessages(library(ggplot2))
update_geom_defaults("text", list(family = "sans")); update_geom_defaults("label", list(family = "sans"))
app <- suppressMessages(shiny::shinyAppDir("app"))
shiny::testServer(app, {
  AE <- environment(renderPlotFit); A <- function(nm) get(nm, envir = AE)
  h <- A("APP_HIST")$out
  for (W in widths) {
    f <- file.path(out_dir, sprintf("%s_h_diagram_%d.png", font, W))
    ragg::agg_png(f, width = W, height = A("diagram_height_px")(W), res = 72)
    print(A("plot_box_diagram")(A("APP_FLUX_NOW"), h[nrow(h), ], A("app_params")$p, n_layers = A("APP_SPIN")$grid$nl,
                                scale = A("diagram_scale")(W)))
    grDevices::dev.off(); cat("wrote", f, "\n")
  }
})
