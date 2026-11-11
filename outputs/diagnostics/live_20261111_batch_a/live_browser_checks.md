# Live checks of the batch-A deploy, 2026-11-11 (CHANGELOG 2026-11-11 m)

Host: https://01a14244-5cc3-1951-7b06-9e2fb07beae3.share.connect.posit.cloud/, revision
`01a1cbfb-cefb-dc06-68da-47f338111b9e`, published 19:00:44–19:00:48 UTC by Marcus from
`~/ccx_frozen/bundle_20261111_01cdaf99` (`host_revision_20261111b.json`, upload URL omitted): 4096 MB, 2 CPU, timeouts
1200 / 1800 / idle 5, init 60, `sched_min_proc` 1.

Headless Chrome (port 9333, scratch profile), from 19:04 UTC:
- `live_time_tab_draws_{1440x900,200x800}.log`: every tab and sub-tab draws all its charts (Build your own skipped: it
  waits for "Run it"), slowest 5.8 s at 1440 x 900; ALL OK at both sizes.
- `live_check_live_pointer_1440x900.log`: every tab draws every chart with alt text and no output errors; both pointers
  open their card with the host's href rewrite; the CSV names `01cdaf9`. Its one FAIL is Build your own before "Run it"
  (by design).
- `live_check_scan_ui_{1440x900,375x812}.log`: ALL OK, screenshots beside them.
- `live_check_dl_links_{1440x900,375x812}.log` (new, `review_20261111/check_dl_links.py`): ALL OK, 10/10 panes at each
  size. Every link under a drawn chart is visible, addressed and enabled; no Download line under Build your own's
  undrawn chart.
- `phone/` (`mobile_layout_20261020/shoot_tabs.py --mobile`, 375 x 812): every tab's page is 375 px wide (no sideways
  page scroll), all charts drawn, no errors; full-page screenshots in `phone/full/`.
- `live_log_problems.log` (`review_20261111/log_problems.R "2026-11-11 19:00"`): 113 lines, 15 sessions started, no
  problem-looking lines.

The two items the handoff said to check on the host:
- **Card 2's facet titles** (`live_{1440x900,375x812}_rv_gradient_*_img.png`): "CO₂ gradient (ppm)" and
  "δ¹³C gradient (‰)" draw with their digits. The blank digits seen locally were this laptop's font. The δ¹³C Model bar
  ends above the panel's lower edge (A6); the phone caption's last line is whole.
- **Box diagram** (`live_*_h_diagram_*_img.png`, against `local_*` from the checkout at the same commit):
  - Host only: the host's font sets the box labels wider, so Vegetation and Soil are drawn wider and the gap between
    them is about 15 px at 1440 x 900. The litterfall arrow shows no head at either size, and the land-use arrow from
    the atmosphere lands on Soil's top-left corner. Locally the gap is about 45 px and the head shows (A1's fix).
    `crop3x_litterfall_{live,local}_1440x900.png`, `crop4x_litterfall_live_375x812.png`.
  - Both host and laptop, at the tuned width (565 px, what a phone shows with sideways scroll): the 92 arrow touches
    "warm" in "warm sea to air", and the 69 soil-to-air arrow touches the "r" of "respiration". At 815 px (desktop) both
    are clear. `crop3x_upper_{live,local}_375x812.png`.
  - Not fixed here; reported to Marcus.

`pngcrop.py`: the zlib-only crop and nearest-neighbour enlargement used for the crops (no PIL or R `png` on this machine).
