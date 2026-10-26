# Live checks of the small-window fixes, 2026-10-26 (CHANGELOG 2026-10-26 a)

Host: https://carbotope.org/ (served from https://01a14244-5cc3-1951-7b06-9e2fb07beae3.share.connect.posit.cloud/),
revision `01a177bd-d5c0-f756-f8c1-cf170e3f00c6`, published 2026-10-26 10:25:04 UTC from
`~/ccx_frozen/bundle_20261025_5c9576fa`. The CSV header reads "Code commit: 5c9576f" in every headless run.

## Built-in browser (Claude desktop app); "Run it" was pressed after the headless runs, the rest before them

| check | result |
|---|---|
| Keeling tab at 1440 x 900 | k_plot and k_seasonal drawn, 1056 px panels |
| k_plot's element set to `width: 0px` (Shiny reports width 0) | output empty, no error |
| width restored | k_plot redrawn at 1056 px |
| viewport 200 x 800 (176 px panels) | k_plot and k_seasonal drawn (k_seasonal failed at 176 px before the fix) |
| Futures -> Build your own -> "Run it" | f_plot drawn in 3.5 s, alt "Future CO₂ on your pathway", 0 output errors on the page; takeaway "Your pathway reaches 701 ppm and +4.0 °C by 2150 ..." |

## Headless Chrome (port 9333, scratch profile), from 10:26:51 UTC

- `live_check_live_pointer_1440x900.log`, `live_check_live_pointer_200x800.log`: every tab draws every chart with alt text
  and no output errors; both pointers open Known issues at card top 0 with the host's href rewrite; CSV commit 5c9576f.
  Each run's one FAIL is Futures -> Build your own before "Run it" (by design; pressed above).
- `live_check_scan_ui_1440x900.log`, `live_check_scan_ui_375x812.log`: ALL OK, screenshots beside them.
