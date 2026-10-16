# The pulse lab's ocean by depth, 2026-10-16

The Pulse lab's two partition panels (the extra carbon; the pulse's tagged carbon atoms) now split the
ocean into three groups built from the model's existing boxes. Display only: no model, parameter or
calibration change. Code: `app/R/ocean_depth.R`, `app/R/plots.R` `plot_pulse_partition()`; commits `db0d5c4`
(build) and `cd7a1c9` (Marcus's copy). The numbers below were made at `db0d5c4`; `cd7a1c9` changed copy only.

## Marcus's rulings (2026-10-16)

| choice | ruling |
|---|---|
| groups | upper = mixed layer + polar surface box HS + oc1–oc3; intermediate = oc4–oc6; deep = oc7–oc10 |
| polar deep box HD | split by depth ("B: HD split by depth") |
| which panels | both |
| colors | one sequential blue, lightest = upper |
| build | annual restarts of the C++ core from saved states |

The mixed layer and oc1 share a group because the seasonal mixed layer entrains from oc1.

HD is one well-mixed box at constant area under HS, so its carbon is uniform in depth and each group gets
the share of HD's thickness inside it. HS is about 293.5 m thick at `hilda31w` (`h_hs` is fitted), so HD
spans 293.5 m to the floor at 3,682 m. Its shares are 0.05 % upper, 18.27 % intermediate and 81.68 % deep.
The numbers first put to Marcus assumed HD started at the mixed layer's 70 m (6 / 17 / 77 %).

Group boundaries are the bottoms of oc3 and oc6 on the run's grid: 295.2 m and 914.3 m. The legend
rounds them to 300 m and 900 m.

## Numbers (vvM, 100 GtC released over 2050, `hilda31w`, read at mid-year)

Share of the pulse, %. From `pulse_ocean_depth_vvM_2050_100GtC_offsets.csv`.

**The pulse's carbon atoms (tagged, decay undone)**

| reservoir | +1 | +5 | +10 | +20 | +50 | +100 | +150 | +200 | +250 |
|---|---|---|---|---|---|---|---|---|---|
| air | 82.78 | 48.52 | 31.96 | 19.79 | 12.51 | 9.69 | 8.18 | 6.96 | 6.05 |
| land | 7.35 | 16.81 | 18.55 | 18.17 | 14.40 | 11.78 | 11.02 | 10.63 | 10.30 |
| upper ocean | 9.66 | 28.80 | 33.93 | 32.33 | 25.23 | 19.70 | 16.70 | 14.82 | 13.43 |
| intermediate ocean | 0.14 | 4.76 | 12.56 | 23.21 | 34.03 | 35.38 | 32.94 | 30.33 | 28.11 |
| deep ocean | 0.07 | 1.11 | 3.00 | 6.49 | 13.83 | 23.45 | 31.16 | 37.26 | 42.11 |

**The extra carbon (with the pulse minus without)**

| reservoir | +1 | +5 | +10 | +20 | +50 | +100 | +150 | +200 | +250 |
|---|---|---|---|---|---|---|---|---|---|
| air | 89.68 | 74.15 | 66.78 | 59.46 | 52.92 | 50.43 | 47.80 | 44.37 | 41.19 |
| land | 4.00 | 11.90 | 16.08 | 20.42 | 23.34 | 22.95 | 23.38 | 24.57 | 25.72 |
| upper ocean | 6.20 | 11.37 | 11.52 | 10.61 | 8.72 | 7.36 | 6.80 | 6.62 | 6.46 |
| intermediate ocean | 0.07 | 2.12 | 4.66 | 7.65 | 10.82 | 11.71 | 11.64 | 11.57 | 11.55 |
| deep ocean | 0.05 | 0.46 | 0.96 | 1.86 | 4.20 | 7.55 | 10.38 | 12.86 | 15.09 |

### Check against the 2026-10-15 scratch analysis

That analysis read every box's state from an independent restart chain (`tagged_tail/02_runs.R`, in a
scratch directory, not in the repo). Regrouped under the rulings above, its per-box table of the tagged
atoms agrees with the table here within 0.016 percentage points in all 45 entries. That is inside its
rounding: it printed each box to 0.01, and a group sums up to five boxes (± 0.025). Example: tagged
intermediate at +20 is 21.95 + 0.1827 × 6.94 = 23.22, against 23.21 here. Its own grouping put HD wholly in the deep
ocean, which is why its quoted intermediate and deep figures (22 / 33 / 26 and 8 / 26 / 44) differ from
the table here.

## Checks (all in `tests/testthat/test-pulse-ocean-depth.R`, 66 expectations)

- The weights partition the ocean: every ocean box's weights sum to 1 and no other box has one.
  A box left out is refused by name.
- The three groups sum to each panel's ocean total at every instant, against the same states (summation
  roundoff) and against the unsplit run's `$out` (the ocean band the panels drew before). Dropping one box
  fails both comparisons.
- The restarted runs reproduce the unsplit runs: 3.8e-15 relative here, against a bound of 8.8e-12
  (months × substeps × machine epsilon). An off-by-one instant (1.5e-3) and a stale T_deep (4.5e-4) both
  fail the bound. `app_pulse_depth_runs()` refuses to draw a chain that fails it.
- The plotted shares close to 100 % after the release: the tagged panel within the decay undo's
  second-order term (λ²Δ²/8 = 1.85e-9), the extra panel within roundoff. Since Marcus cut the closure
  sentence from the caption, the panel refuses to draw when a panel misses its bound. Over the sliders'
  extremes (vvVL / vvM / vvH, 2030–2100, 10–500 GtC) the residual is at most 0.22 of its bound; a
  1e-6 leak is refused.
- The five fills, composited at the bands' 0.9 alpha over white, clear `tools/palette_check.py`'s
  target of 8. The worst pair is 14.1 (intermediate / deep) and ColorBrewer's Blues triple fails (3.4).
- The legend's row count is chosen by measuring the keys against the panel width. It has 1 row at
  1440 px, 2 at 1024 and 3 at the 768 px floor. The rendered guide box is checked at both ends, and a
  forced single row fails at the floor (683 px against 536).

## Screenshots

`screenshot_1440x900_pulse_partition.png` and `screenshot_768x1024_pulse_partition.png`: the app at
`cd7a1c9` (with Marcus's copy), Pulse lab defaults, captured with `shoot_app.py` (headless Chrome through
the DevTools protocol, Python standard library only). The partition panel appeared 4.0 s after the click
at both widths.

## Copy (Marcus, 2026-10-16)

His takeaway paragraph sits over both panels (`PULSE_DEPTH_TAKEAWAY`). The caption is cut to "Left: This
is how much extra carbon each reservoir holds because of the pulse. Right: the same pulse, with its carbon
atoms tagged." He judged the three ocean bands to need no separate line, so the placeholder line and its
tooltip are gone. The three legend keys (`KEY_OCEAN_*_FMT`) stay as drafted ("Keys are fine as drafted").
No bracketed placeholder remains, so `app/make_deploy_bundle.sh` no longer refuses.

## Reproduce

```
Rscript outputs/diagnostics/pulse_ocean_depth_20261016/make_record.R
```

The CSV is byte-identical across two runs. Screenshots need the app running on a port and Chrome:
start Chrome with `--headless=new --remote-debugging-port=<p>`, then run
`python3 shoot_app.py <p> http://127.0.0.1:<port> <prefix> 1440 900`.
