# A first visit to CarboTope, timed before and after the precompute (2026-10-20)

CHANGELOG 2026-10-20 (c). Before: deploy bundle built from `9cb7701b`. After: deploy bundle built from `1838885e`
(products built at `bff29ab3`). Both bundles were made with `app/make_deploy_bundle.sh` (after: 113 files, 7.2 MB;
before: 111 files, 4.3 MB). All numbers are from the M4 laptop (load average 2.5–3.5 on 10 cores). Connect Cloud
was not touched: no redeploy, no load test.

## Results

| | before | after |
|---|---|---|
| R start-up work, all of `global.R` + `app/R/` + `ui.R` + `server.R` (`time_stages.R`, 3 runs each) | 4.67–4.80 s | 0.92–0.95 s |
| process start → serving (HTTP 200) | 5.3–5.6 s | 1.49–1.52 s |
| process start → first plot drawn (first visitor) | 6.0–6.3 s | 2.25–2.30 s |
| Futures tab, first draw (clicked right after the first plot) | 1.75–1.84 s | 2.44–2.56 s |
| "Release the pulse", default settings, click → partition panel drawn | 3.67–3.84 s | 0.47–0.53 s |
| "Release the pulse", pulse size 200 GtC (computed live in both) | 3.76–4.00 s | 3.79–3.94 s |
| R process memory when serving | 266–280 MB | 244–248 MB |
| peak memory of the whole process tree in the first 8 s (`startup_memory.py`) | 458–485 MB | 616–623 MB |

Three fresh processes per column for the browser timings (`coldstart_*.csv`), two for memory. The pulse takeaway
text the browser displayed is identical before and after, for both pulses.

### Where the start-up time went (before; `stages_before_*.csv`)

| stage | seconds |
|---|---|
| `ccx_load_cpp()`, the C++ compile | 1.68–1.80 |
| `APP_FLUX`, the one-year RK4 flux trace (R path) | 1.37–1.41 |
| `APP_SPIN`, the periodic 1750 spin-up | 0.72–0.74 |
| `library(shiny)`, `library(ggplot2)`, `library(bslib)` | 0.32–0.35 |
| `app_params` (reads the mode file), `APP_OBS`, `APP_HIST` | 0.09–0.11 each |
| everything else | ~0.2 |

After (`stages_after_*.csv`): the spin-up, the historical run and the flux trace are read from
`data/app_startup_precompute.rds`, and the compile runs in a background R process, so neither is on the path to the
first page. The largest stages left are `library(ggplot2)` 0.21 s, `ccx_prepare_obs()` 0.14 s and `library(shiny)`
0.13 s.

### What moved the other way

- **The Futures tab's first draw** is the first live run, and when it is opened about 2.3 s after start it waits for
  the background compile to finish: +0.6–0.8 s. A reader who spends a few seconds on the first tab does not wait.
- **Peak memory during start-up** is ~140 MB higher, for the first ~2.5 s: the compiler now runs while the app process
  holds its data (~230 MB), plus the background R process. Before, it ran at the top of `global.R`.

## The pulse lab's display (CHANGELOG 2026-10-20 d, measured on the worktree after `0176015`)

Marcus ruled the default is drawn with no click and the result grays out when a pulse setting changes.
`pulse_display_check.py` (three fresh processes; `pulse_display_check.csv`):

| step | seconds |
|---|---|
| open Pulse lab (Futures tab settled first) → partition drawn, no click | 0.51–0.52 |
| pulse size slider to 200 → all six result outputs grayed and the note shown (old chart kept) | 0.33 |
| "Release the pulse" → new chart drawn, gray and note gone | 3.70–3.77 |
| slider back to 100 → the stored chart again | 0.66–0.67 |

`pulse_display_stale_1440x900.png` is the grayed state. ⚠ Since this change `coldstart.py`'s default-pulse step
(click at the default, wait for a NEW partition image) would time out: the default is already on screen and an
identical result is not redrawn. The `coldstart_*` numbers are from `1838885`, before it.

## Method

- `time_stages.R <bundle> <out_csv> <label>`: in a fresh `Rscript`, evaluates `app/global.R` expression by expression
  (as Shiny does), then `app/R/*.R`, `ui.R` and `server.R`, timing each.
- `coldstart.py <chrome_port> <bundle> <app_port> <reps> <out_csv> <label>`: per repetition, starts a fresh R process
  serving the bundle, polls for HTTP 200, opens the app in a new headless-Chrome context (1440×900), waits for the
  first plot; opens Futures → Pulse lab and waits until the app has been idle for 0.5 s (no `shiny-busy`, no visible
  `recalculating` output); clicks "Release the pulse" and times until the partition panel's image is new and drawn;
  then sets the pulse size to 200 GtC (`Shiny.setInputValue`) and repeats. Stdlib only; the DevTools client is
  `../loadtest_20261020/loadtest.py`'s.
- `coldstart_*_noidlewait.csv`: the first pass, which clicked without waiting for idle. Its default pulse (5.4–5.5 s
  before, 2.8–2.9 s after) includes the Futures tab's own scenario runs queued ahead of it, so it measures the queue
  as well as the pulse.
- `startup_memory.py <bundle> <port> <out_csv>`: samples `ps` every 0.1 s for 8 s after start; sums the app process's
  tree and the background build's (detached by `system2(wait = FALSE)`, so it is found by its command line).

## Not measured

- **Connect Cloud.** Its 18–27 s loading page includes container start and package loading, which this does not
  change; only a redeploy can measure the new number. As an estimate only: the 2026-10-20 load test had one pulse at
  16.7 s live against 5.6 s on this laptop, about 3×; at that ratio the R start-up work would fall from ~14 s to
  ~3 s, and the default pulse to under 2 s.
- **Bit-identity on Connect Cloud.** The products are computed on this Mac (clang, macOS libm). Connect Cloud's live
  runs use its own compiler and libm, so its live values can differ from the stored ones at roundoff. The same is
  already true of `data/review_precompute.rds`. Not measured here.
