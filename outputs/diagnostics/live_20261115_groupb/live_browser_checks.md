# Live checks of the group B deploy, 2026-11-15 (CHANGELOG 2026-11-15 i)

Host: https://01a14244-5cc3-1951-7b06-9e2fb07beae3.share.connect.posit.cloud/, revision
`01a1e15d-6a4f-07e7-0c38-2928be77b656`, published 22:39:22–22:39:28 UTC by Marcus from
`~/ccx_frozen/bundle_20261115_8ba6c320` (`host_revision_20261115.json`, upload and log-channel fields omitted):
4096 MB, 2 CPU, timeouts 1200 / 1800 / idle 5, init 60, `sched_min_proc` 1.

Headless Chrome (port 9337, scratch profile), 22:40–22:50 UTC:
- `live_time_tab_draws_{1440x900,375x812}.log`: every tab and sub-tab draws (Build your own skipped), slowest 5.6 s;
  ALL OK at both sizes.
- `live_check_live_pointer_1440x900.log`: both pointers open their card with the host's href rewrite; every tab draws
  with alt text and no output errors; the CSV names `8ba6c32`. Its one FAIL is Build your own before "Run it" (by design).
- `live_check_scan_ui_{1440x900,375x812}.log`: ALL OK.
- `live_check_dl_links_{1440x900,375x812}.log`: ALL OK.
- Card 4a (`shots_1440/card4a_rv_variance.png`): the caption reads "…averaged over the twelve months to each January,
  where both peak, r is +0.73 for the model and +0.51 for the measurements (n = 45)…".
- Card 4 (`live_card4_text_1440.log`, `card4_text_actions.json`): the approved second-draft paragraph, in the card's
  collapsed details; "about two thirds"; the ask without "volcanic".
- Phone (`live_phone_check_375.log`, `groupb_build_20261115/phone_check.json`, 375 × 812, touch): banner and takeaway
  edges 12–363; download links 32 px; the share link on one line; readout numbers at 442 px; after Run it the takeaway
  is 20 px from the top; "Calculating…" on and the chart at opacity 0.35 300 ms after each press.
  ⚠ The pulse step's fixed 6 s wait ended before the host finished a 200 GtC pulse (takeaway still "Release the
  pulse…"). Re-run polling every 2 s (`pulse_poll_actions.json`, `live_phone_pulse_polled_375.log`): the calculation
  ended between 10 and 12 s, then the takeaway was 20 px from the top with the result, as in the bundle check. The
  host's pulse time was 11.8 s on 10-15; the 6 s wait suits only the laptop.
- `live_log_problems.log` (since 22:39): 150 lines, 25 sessions started, all headless (these checks and the host's
  thumbnail render), no problem-looking lines.
- The previous revision's log channel (`01a1cc55`) was still readable after the publish: all 1,366 lines.
