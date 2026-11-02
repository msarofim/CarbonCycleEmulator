# Live checks of the session-logging deploy, 2026-11-02 (CHANGELOG 2026-11-02 c)

Host: https://01a14244-5cc3-1951-7b06-9e2fb07beae3.share.connect.posit.cloud/, revision
`01a19e4d-f9e8-7e66-345a-ad37c259c1a9`, published 22:08:21 UTC from `~/ccx_frozen/bundle_20261102_54e9ef80`
(`host_revision_20261102.json`, upload URL omitted). 4096 MB, 2 CPU, timeouts 1200 / 1800 / idle 5, `sched_min_proc` 1.

All runs below are headless Chrome (port 9333, scratch profile) on Marcus's laptop, which was on a train connection
("I am on a train, so my internet connection may be patchy", sent during run 3). Times UTC.

| time | run | result |
|---|---|---|
| 22:31:44 | `check_live_pointer.py` 1440 x 900 (run 1) | pointers OK, CSV `54e9ef8`; Isotopes 0/2, Scenarios 0/1, Pulse lab 0/2, Known issues 0/9 within the fixed waits; no output errors |
| 22:33:26 | `check_live_pointer.py` 200 x 800 | every tab draws; one FAIL, Build your own before "Run it" (by design) |
| 22:36:29 | `time_tab_draws.py` 1440 x 900 (run 1) | every tab draws, slowest 5.1 s (Scenarios) |
| 22:37:37 | `time_tab_draws.py` on a FRESH local copy of the bundle (port 7795) | every tab's first draw within 1.8 s, so a first-visit cost on a new worker cannot account for a ~30 s stall |
| 22:38:14 | `check_live_pointer.py` 1440 x 900 (run 2) | CSV fetch empty; 6 panes not drawn; no output errors |
| 22:40 | `check_scan_ui.py` 1440 x 900 and 375 x 812 | ALL OK at both |
| 22:41:37 | `check_live_pointer.py` 1440 x 900 (run 3) with `monitor_session.py` on the same page | Pulse lab, Known issues, Under the hood not drawn. Monitor: session `9f7f6e90` stayed connected through the sweep with no reconnect dialog; nothing arrived from the server between 22:42:52 and 22:43:24, after the checker had finished at 22:43:18, so the messages were late rather than lost |
| 22:44:13 | `time_tab_draws.py` 1440 x 900 (run 2), latency log alongside | every tab draws; Known issues took 55.6 s |
| 22:45:46 | `time_tab_draws.py` 200 x 800 (run 2), latency log alongside | every tab draws, slowest 9.7 s |

Latency log (`live_network_latency_run4.log`, a 204 endpoint at www.gstatic.com once a second, 22:44:13 to 22:46:33):
73 requests, median 0.53 s, 15 over 1 s, the longest 9.3 s (ending 22:45:18) and 6.1 s (ending 22:45:33). Both
fall inside the 55.6 s Known-issues wait.

Reading: the app drew every chart, with alt text and no output errors, whenever the timed probe waited for it. The
fixed-wait failures came with stalls on the laptop's connection. Not shown: a clean fixed-wait run from a stable
connection, and whether another visitor's computation also held the R process (the content's Logs would show other
sessions' `CCX_SESSION` lines).

Not checked here: the `CCX_SESSION` lines in the content's Logs (no log endpoint is open to the rsconnect token);
Build your own's "Run it" (no code change there since 10-26, where it drew in 3.5 s).

Gate gap found: `check_live_pointer.py` passed a pane with 0 charts on show as "0/0 drawn -> OK" ("What pins down
what?" in runs 2 and 3, where the charts sit in an output the server had not yet sent). Fixed 11-02 (c): 0 charts
is now a FAIL; the rule was checked on four cases, including 0/0.
