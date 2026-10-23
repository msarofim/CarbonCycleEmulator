# The hilda31fl adoption's test ledger (2026-10-23)

The full suite at `6171db02` (the adoption commit) and the evidence used to classify every failure. CHANGELOG 2026-10-23 (l).
Nothing here edits a repo test. Model: CarbonCycleEmulator, canonical `hilda31fl` (label `hilda_csl3v0kaidgbemwtcf`,
seas_ml 1; mode file md5 `80c487f5…`). No RNG is used in these files.

| file | what it is |
|---|---|
| `../suite_20261023_6171db02.log` | the full suite, frozen worktree `~/ccx_frozen/suite_20261023_6171db02` (79 download links + 3 tracked files), BLAS pinned to 1: 9177 passed, 81 failed, 2 errored, 4 skipped, 24.5 min |
| `../suite_20261023_6171db02_perfile.csv` | the suite's per-file counts |
| `../suite_20261023_6171db02_failing.log` | `ledger_rerun.R` on the 16 failing files: every failure and error message (83 = 81 + 2), since the summary reporter printed only the first 10. Same counts as the suite |
| `suite_runner_6171db02.sh` | the suite runner as it ran |
| `ledger_rerun.R` | the re-run, as it ran |
| `../mechanism_sweep_20261023_hilda31fl.{log,rds}` | `calibration/diag_mechanism_sweep.R` at `6171db02` (reads `CCX_MODE_CANONICAL`): the measurement behind G |

## The 83 entries in 27 tests across 16 files

Compared with hilda31w's ledger (10-13 g): no harness errors (that class was fixed on 10-13 h), no app gap (the fitted
names are hilda31w's 31), and one new class of premise (B2), from the flask switch.

### B. The previous canonical by name or label: 11 entries in 4 tests

| test | entries | what it asserts | proposed |
|---|---|---|---|
| `flux-trace-exact:66` | 1 | `CCX_MODE_CANONICAL` is "hilda31w" (the file's power premise) | re-express to "hilda31fl"; the structure checks under it (hs, l2, seas_ml on) are the power and pass |
| `ms-reference-set` (11) `:198` | 1 | the canonical runs the WTC label | re-express to `CCX_MODE_FLASK_STRUCT` |
| `ms-reference-set` (14) `:346-348` | 2 + 1 error | the canonical is "hilda31w" on the WTC label, and pass 2's pins under that label return it as a MODE | as at 10-13 (h): the pins under the canonical's label (flask) return the canonical as a MODE; under the WTC label they are now REFUSED ("is not that label", a new mutation); seas_ml 0, a moved module value and a dropped module name stay refused |
| `flask-label` REPRODUCTION `:90, 93, 94, 95, 105, 106` | 6 | `fl_score()` reads `ccx_mode_file()`; the test means the mode T8f was computed at (`T8F$provenance$mode` = "hilda31w", md5 `53ee816a…`) | re-express `fl_score()` to read that mode by name (`T8F$provenance$mode`, or `CCX_MODE_FLASK_INCUMBENT`); every assertion kept. Optional addition: at hilda31fl, its stored logpost reproduces under its own label |

**B2. A premise the flask switch breaks** (2 entries in 1 test): `mode-file:446-447` checks that the comparable-row rule
drops exactly the D3-moved rows between the canonical and the seas_ml-0 control. The canonical now also differs from the
control in the flask switch, so the rule also drops the three MLO CO₂ rows (`co2_level_MLO`, `co2_seasonal_MLO`,
`co2_gradient`), as ruled 10-22 (g). The rule is right; the test's expected set assumed one difference.
Proposed: the expected set is `setdiff(intersect(r_c, r_ctl), c(LIK_IMB_ROWS, LIK_CO2_FLASK_ROWS))` when the two labels
differ in `co2_mlo_flask` (read from `ccx_struct_block()`), else as now; the count difference 5 (2 + 3). The test then
checks both drops.

### C. A measured literal to re-pin: 1 entry

`gate-bounds:509`: GATE S's whole limb 8.91 → **8.983** (the scorecard's "SPO ocean limb 0.407 ppm @ month 8.98",
`flask_landing_20261023/scorecard.log`), outside the 0.05 tolerance by 0.023. The blind read still passes its 4.38 ± 0.05,
and the verdict passes. Proposed: re-pin 8.98 with the measurement in the comment, as at every adoption since hilda30h.

### D. Precomputed products keyed to hilda31w, each refused by its loader: 67 entries in 19 tests

The loaders refuse a product built for another mode, as designed. Each clears when the product is rebuilt at hilda31fl
(handoff 10-23 §4 item 5).

| product | entries |
|---|---|
| the app's start-up and default-pulse precompute (`data/app_startup_precompute.rds`, `data/pulse_default_precompute.rds`) | `app-precompute` 47 + 1 error (the mutation tests expect one problem and find the unmutated product's three: built for hilda31w, its md5, its run inputs); `app-a11y:64` (the Pulse lab at its defaults shows the prompt, since the stored run is refused) |
| the constraint map (`data/constraint_map.rds`) | `constraint-map` ×4; `app-downloads:341` (`cm_map`, `cm_tension` not drawn); `app-scan-items:118` (no share link on the map) |
| the ocean-climate card (`data/ocean_climate_card.rds`) | `ocean-climate-card:27`; `app-downloads:341` (`rv_oclim`, `rv_oclim_stake`) |
| the Known-issues precompute (`data/review_precompute.rds`) | `review-precompute` ×9 |
| the futures band (`data/futures_ribbons.rds`) | `futures-ribbons:156` (needs the MCMC at hilda31fl first) |
| `pulse_vs_tcre` (`outputs/diagnostics/pulse_vs_tcre_20261013.csv`) | `pulse-linearity:49` (+ its 2 skips) |

(`app-downloads:341` is one entry covering both the map and the ocean card.)

### F. The release: 1 entry

`app-version:55`: `APP_RELEASE_MODE` is "hilda31w", the app loads "hilda31fl". It stays red until the products are rebuilt
and Marcus decides the release (precedent 10-13 h: "Hold until rebuilt").

### G. Power lost at this mode: 1 entry

`mechanisms:334`: the power check expects the OLD construction (the ocean switch inside the spin-up) to crash "singular"
on `warming_feedback + ocean_sink + revelle`, the smallest combination that crashed at hilda31w. At hilda31fl it does not.
The test's own comment: "re-measure before deleting it".

MEASURED (`../mechanism_sweep_20261023_hilda31fl.log`): the old construction crashes on 8 of the 64 ocean combinations
(hilda31w: 8), converges on 32 (16) and warns non-convergence on 24 (40). **Every crash contains `warming_feedback +
ocean_sink` without `revelle`**, and the pair itself crashes "singular" again, as it did before 10-13. The triple now only
warns (|resid| 5.2e-9). The app's construction: 127 / 127 clean, no warnings.

The crash has moved between the pair and the triple at two adoptions in a row, so a check keyed to one combination
loses its power whenever the mode moves a little. Proposed, either:
- (a) move the check back to the pair, the smallest combination that crashes at hilda31fl (the 10-13 h idiom); or
- (b) require the old construction to crash on at least one of the two (pair, triple). That keeps the power across both
  modes measured so far, and the app's construction is already tested on both in the loop above it.

### The four skips

`cmap-tie` (from D), `pulse-linearity` ×2 (from D), and `test-l2-enso-limb.R`, standing.
