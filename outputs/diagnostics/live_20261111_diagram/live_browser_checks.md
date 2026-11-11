# Live checks of the box-diagram deploy, 2026-11-11 (CHANGELOG 2026-11-11 p)

Host: https://01a14244-5cc3-1951-7b06-9e2fb07beae3.share.connect.posit.cloud/, revision
`01a1cc55-987f-30a5-3bf4-deed63dfa8c0`, published 20:38:50–20:38:55 UTC by Marcus from
`~/ccx_frozen/bundle_20261111_64d91397` (`host_revision_20261111c.json`, upload URL omitted): 4096 MB, 2 CPU, timeouts
1200 / 1800 / idle 5, init 60, `sched_min_proc` 1.

Headless Chrome (port 9337, scratch profile), from 20:50 UTC:
- `live_time_tab_draws_{1440x900,200x800}.log`: every tab and sub-tab draws (Build your own skipped), slowest 6.1 s at
  1440 x 900; ALL OK at both sizes.
- `live_check_live_pointer_1440x900.log`: both pointers open their card with the host's href rewrite; every tab draws
  with alt text and no output errors; the CSV names `64d9139`. Its one FAIL is Build your own before "Run it" (by design).
- `live_check_scan_ui_{1440x900,375x812}.log`: ALL OK.
- `live_check_dl_links_{1440x900,375x812}.log`: ALL OK, 10/10 panes at each size.
- `live_log_problems.log` (since 20:38): 145 lines, 14 sessions started, no problem-looking lines.

The diagram (`live_{1440x900,375x812}_h_diagram_*_img.png`), diagram area only (above the footnote, which wraps to the
live width), compared with `diagram_font_20261111/compare.py`:
- 565 x 482 (phone): identical to the DejaVu render `diagram_font_20261111/iter/i04_dejavu_565.png` (0 of 177,975 pixels);
  11,286 differ from the Helvetica render.
- 815 x 696 (1440 px screen): Shiny reports the panel as 815.984375 px wide and the app takes the text scale from that
  (1.44422). The DejaVu render at that scale (`dejavu_live_scale_815x696.png`, `diagram_font_20261111/render_live_scale.R`)
  differs from the live image in 46 of 370,825 pixels; the same render at exactly 815 px differed in 12,024. The pixel
  gate finds 0 problems at the live scale.
