# Live checks of the y-title and title-link deploy, 2026-11-11 (CHANGELOG 2026-11-11 g)

Host: https://01a14244-5cc3-1951-7b06-9e2fb07beae3.share.connect.posit.cloud/, revision
`01a1cac5-1226-1c4b-6f95-22f8d91a8e4f`, published 13:21:26 UTC from `~/ccx_frozen/bundle_20261111_8be0095a`
(`host_revision_20261111.json`, upload URL omitted): 4096 MB, 2 CPU, timeouts 1200 / 1800 / idle 5, `sched_min_proc` 1.

Headless Chrome (port 9333, scratch profile), from 13:23 UTC:
- `live_time_tab_draws_1440x900.log`, `live_time_tab_draws_200x800.log`: every tab and sub-tab draws all its charts
  (Build your own skipped: it waits for "Run it"), slowest 5.6 s at 1440 x 900; ALL OK at both sizes.
- `live_check_live_pointer_1440x900.log`: every tab draws every chart with alt text and no output errors; both
  pointers open their card with the host's href rewrite; the CSV names `8be0095`. Its one FAIL is Build your own
  before "Run it" (by design).
- `live_check_scan_ui_{1440x900,375x812}.log`: ALL OK, screenshots beside them.
- `live_k_seasonal_1440x900.png`, `live_c_resid_1440x900.png`: both y titles on two lines inside the panel, clear of
  the caption. The host's font sets text wider than the laptop's: the residual chart's caption wraps to a second
  line and still clears the title.

Built-in browser (13:27 UTC): the navbar name is a link to https://carbotope.org (no target), white and
un-underlined; clicking it opened https://carbotope.org/ in the same tab. One "desktop" session in the visit log.
