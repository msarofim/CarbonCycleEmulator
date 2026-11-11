# Y titles running into the caption on short charts, 2026-11-11 (CHANGELOG 2026-11-11 d)

Marcus: "On the keeling curve page, the y-axis label of the 2nd graph and the carbotope.org (beta) are overlapping.
Same with the 3rd graph on the what-if page."

- `before_*` / `after_*`: the local app (`ccx-app`), headless Chrome at 1440 x 900, each plot output clipped from the
  page by `shoot_plots.py` (`python3 -I shoot_plots.py 9333 http://127.0.0.1:7788/ 1440 900 <prefix> "<tab>:<id>" ...`).
  `k_seasonal` (260 px) and `c_resid` (200 px): the rotated y title was taller than the panel and ran into the caption
  (and, on `c_resid`, off the top). After: wrapped onto two lines inside the panel. `c_growth` (300 px) is
  byte-identical before and after (its title fits; the cheap check skips it).
- The blue marks at the bottom-right corner of the clipped images are the top of the "Download:" line under each chart,
  caught by the clip, not part of the chart.
- Cause: `app_fit_plot()` returned at once above `APP_FIT_MAX_PX` (552 px), and these panels are 1045 px wide; and the
  seasonal chart's title is plotmath (`app_plotmath()`, Marcus's 10-15 ruling for sub/superscripts), which the wrap step
  skipped. Fix and tests: CHANGELOG 2026-11-11 (d). `mutate_y_title.sh` / `.log`: five mutations, each caught.
