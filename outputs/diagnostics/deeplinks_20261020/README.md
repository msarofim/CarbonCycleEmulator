# Deep links and downloads: browser check, 2026-10-20

The local app (preview config `ccx-app`, `http://127.0.0.1:7788/`, started from this worktree), first at `4c62888`
and rerun on the code committed with this file, after the auto-run was removed (Marcus 2026-10-20: a link restores
the tab and settings and presses no button). The tables are the rerun's. Not the live app. CHANGELOG 2026-10-20 (e)
describes the feature.

## Method (`roundtrip.py`, stdlib Python over the Chrome DevTools protocol)

For each view: open the app in one headless-Chrome browser context (1440 x 900), set the view with its controls
(clicks on the tab, the pill, radio buttons and checkboxes; the sliders' and menus' own JavaScript APIs), wait for
the address bar to change, and read what the page shows: the active tab and pill, and each control's widget state.
Then open that address in a **fresh browser context** (its own cookies and storage) and require the same tab, pill
and settings. In the second context it also checks:

- the address is unchanged after the restore;
- the first chart's CSV, fetched through its own download link, has the line `# Link to this view: <address>`
  and at least one data row;
- that a restored link presses no button: "Run it" and "Release the pulse" are both unpressed and their charts
  are empty (Marcus 2026-10-20).

Three controls show that the comparison can fail. Each opens an altered link and requires a mismatch on exactly
the settings that were altered: `k_hemi` changed by hand from NH to SH; the What-if link with its `c_mech=null`
removed; and the bare address with no settings, against the Pulse lab view.

## Results (`roundtrip_results.csv`, `roundtrip.log`, `screenshots/`)

11 of 11 views passed, and all 3 controls failed where expected.

| view | the link's query (decoded) | settings in link | CSV rows |
|---|---|---|---|
| Keeling | `tabs="The Keeling Curve"&k_years=[1980,2010]&k_hemi="NH"&k_obs=false` | 4 | 720 |
| Where does the carbon go | `tabs="Where does the carbon go?"&w_years=[1900,2000]` | 2 | 4800 |
| What if, two switches | `tabs="What if…?"&c_years=[1950,2020]&c_mech=["enso","volcanic"]` | 3 | 1680 |
| What if, nothing switched off | `tabs="What if…?"&c_years=[1850,2024]&c_mech=null` | 3 | 2088 |
| Isotopes | `tabs="Isotope fingerprints"&i_years=[1950,2000]&i_hemi="SH"` | 3 | 1448 |
| Futures, Scenarios | `tabs="Futures"&f_mode="Scenarios"&f_yvar="gmst"&f_scen=["vvVL","vvH"]&f_fair=true` | 5 | 1004 |
| Futures, Build your own | `…&f_mode="Build your own"&s_kind="to_zero"&s_bg="vvH"&s_zero_year=2080&s_rate=1&f_yvar="co2_ppm"&f_fair=false` | 8 | not pressed, chart empty |
| Futures, Pulse lab | `…&f_mode="Pulse lab"&p_bg="vvH"&p_gtc=200&p_year=2070&f_yvar="gmst"&f_fair=false` | 7 | not pressed, chart empty |
| Known issues | `tabs="Known issues"` | 1 | 1594 |
| What pins down what | `tabs="What pins down what?"&cm_level="parameter"` | 2 | 372 |
| Under the hood | `tabs="Under the hood"` | 1 | 14 |

"Settings in link" counts the tab. Only the open tab's settings (and, on Futures, the open pill's) are in a
link. Any other control opens at its default.

- The Pulse lab restore also shows the FaIR checkbox with the Pulse lab's label ("Compare with FaIR (100 GtC pulse
  only)"). `app_links_server()` sets that label on restore, because server.R's label observer has
  `ignoreInit = TRUE` and skips the first pill value. That the label would otherwise be wrong comes from reading
  the code; it was not run without the fix.
- `sample_downloads/`: one CSV and one PNG fetched from the running app with curl
  (`Content-Disposition: attachment; filename="carbotope_v1.0_keeling_curve.csv"` / `.png`). The CSV starts with a
  UTF-8 byte-order mark. The PNG is 2089 x 760, twice the on-screen 1045 x 380, and its caption ends with the
  provenance line.
- At 375 x 812, the download links under the Keeling chart sit on one line (12–359 px), and the page does not
  scroll sideways.

## Not established

- The live host. On Connect Cloud, check after the next deploy that the address bar updates. If the app is
  served inside a frame, `updateQueryString()` changes the frame's address, not the visible one.
- The merged branches. "CarboTope phone layout" replaces the navbar on narrow screens, and `STATE_JS` reads the
  active tab from `.navbar`. "CarboTope first visit" shows the precomputed default pulse without a press and greys
  it when the settings change; the Pulse lab row here (non-default settings) expects an empty chart and may need
  "greyed default" instead. Rerun this check after both merges.
- Real downloads through a browser's save dialog. The CSV was fetched by the page's own `fetch()` and by curl.

## Rerun

```
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --remote-debugging-port=9333 --user-data-dir=<tmp> about:blank &
python3 -I outputs/diagnostics/deeplinks_20261020/roundtrip.py 9333 http://127.0.0.1:7788/ outputs/diagnostics/deeplinks_20261020/roundtrip_results.csv outputs/diagnostics/deeplinks_20261020/screenshots
```

## Tests

- `tests_app_facing_no_autorun.log` (the code committed with this file): `test-review-*`, `test-app-*`,
  `test-pulse-*`, `test-plot-text-fits`, `test-ui-year-bounds-lint`: 14 files, 987 passed, 0 failed, 0 skipped,
  2 warnings (both in `test-review-0916-fixes.R`, present before this change).
- `tests_app_facing_4c62888.log`: the same files at `4c62888`, with the auto-run still in: 990 passed, 0 failed.
- `tests_other_app_readers_4c62888.log`: the 21 other files that read the app's code, at `4c62888`: 1088 passed,
  0 failed, 2 warnings (the model's start-up-transient warning in `test-luc-scale.R`). None of them reads
  `app/R/links.R`, the only file the removal changed beyond one line of `app/R/downloads.R`.
