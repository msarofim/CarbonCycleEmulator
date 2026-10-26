# Small-window plot errors: browser checks, 2026-10-25 (CHANGELOG 2026-10-25 g)

Local app (`ccx-app`, port 7788, `shiny::runApp('app')`), Keeling tab, built-in browser with the viewport set by
`resize_window`. shiny 1.13.0, ragg 1.5.0, ggplot2 4.0.2, R 4.5. "panel" is the output element's rendered width.

## Before the fix (code at 29763dee, same app code as 07d04b16)

| viewport | panel | k_plot | k_seasonal |
|---|---|---|---|
| 1024 x 768 | 744 px | draws | draws |
| 300 x 700 | 276 px | draws | draws |
| 260 x 700 | 236 px | draws | draws |
| 230 x 700 | 206 px | draws | draws |
| 200 x 700 | 176 px | draws | ERROR "`breaks` and `labels` have different lengths." |
| 180 x 700 | 156 px | draws | same error |
| 160 x 700 | 136 px | draws | same error |
| 100 x 700 (page 141 px) | 76 px | draws | same error |

Server log at first load, before any resize: `Error in graphics::plot.new: figure margins too large` from
`startPNG` <- `drawPlot` for `output$k_plot` and `output$k_seasonal`, the two outputs on the opening tab. Both drew
once the page had a size.

For the seasonal error the log has `app_fit_plot: left as drawn (...)` followed by the same error from
`print.ggplot`: the fitting step caught it, then returned the half-refitted plot.

Shiny's `startPNG()` sets `par(mar = 0)` before `plot.new()`. Called directly at pixel ratio 2 with height 380:
fails at width 0 and 0.25 (device 0 px), opens at 0.5 (device 1 px) and at 1, 2, 5, 10, 20, 50. At pixel ratio 1,
0.5 fails (device 0 px). Height 0 fails the same way.

## After the fix

- 180 x 700 (156 px panel) and 120 x 700 (96 px): both charts draw; server log clean.
- k_plot's element set to `width: 0px` at 1024 x 768 (Shiny reports `output_k_plot_width = 0`): the output is
  empty, no error; width restored: draws at 744 px.
- Same 0 px check with only the width guard removed from `renderPlotFit` (server.R): "figure margins too large".
  server.R was restored from a copy and `cmp`-checked.
