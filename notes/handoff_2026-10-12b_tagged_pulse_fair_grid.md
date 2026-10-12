# HANDOFF 2026-10-12 (b) — the pulse lab shows a TAGGED pulse beside the perturbation, and FaIR on the SAME pulse; card 5a draws FaIR's band; the tie cut is the basin spread; the suite is at card 4's two

**Supersedes** `notes/handoff_2026-10-12_pd100_free_climate.md`. Everything still open from its §4 is restated in §4 below.

Written on Marcus's request ("Yes, write the handoff note"), 2026-10-12. **Nothing is running** except the local app preview and one background session (§5).

**Start here.**
1. CHANGELOG **2026-10-12 (e)–(l)**: this session, (e) to (l) in order.
2. Memory (all new today):
   - [[ccx_tagged_pulse_built]]
   - [[fair_pulse_af_exceeds_one]]
   - [[ccx_cmap_tie_basin_spread]]
   - [[ccx_early_drawdown_diagnosis]]
3. `notes/early_drawdown_diagnosis_2026-10-12.md` and `notes/card5a_caption_facts_2026-10-12.md`.

## 1. What was done

| Item | Outcome |
|---|---|
| **FaIRtoFrEDI pushed** ("Push now") | `8984a13..964aa12`, then this session's two driver commits (`..810acf4`). Level with origin. |
| **Scorecard re-run at `hilda29e`** ("Re-run + quarantine") | `whole_model_scorecard_20261012_hilda29e.{log,rds}` reproduces card 5 exactly: 0.522 / 0.379 / 0.295, split 17 / 58 / 25. The 52 older scorecard files (09-08 → 10-08) and `tl_land_share_gate_20260908.*` are in `outputs/quarantine/20261012_pd100_held_sst/` (README). Only their PD100 sections carry the defect. |
| **Constraint-map arms** ("hilda29a6") | `hilda32f` is no longer like-for-like (structure `hilda_csl3`; lacks `ndep_ret` / `imb_share_*`). `hilda29a6` is the new A2. **No row's winner flips between the basins.** Maps: `constraint_map_hilda29a6.rds` (new) and `_hilda31pe.rds` (rebuilt; the 09-26 one was stale). |
| **Tie cut** ("Scale to basin spread") | `APP_CMAP_TIE_PP` = **1.923 pp**, the largest margin shift between the two basins. `test-cmap-tie.R` "THE SPREAD" recomputes it from both maps (39 / 0, 2 code mutations caught). **The deliberate RED is gone.** No displayed phrase changed. |
| **Card 5a facts note** | `notes/card5a_caption_facts_2026-10-12.md`. No prose. |
| **Card 5a draws FaIR's 5–95 % band** ("Draw the band") | The band sits behind the lines, its key on its own row; card 5a is 320 → 400 px. CarboTope is ABOVE FaIR's p95 to 27.5 yr and inside from 28.5 to 300 yr. |
| **The tagged pulse** ("Side by side in pulse lab") | `R/c14_tag.R`; `ccx_run_coupled(c14_tag_base = )`; a third run in `pulse_runs()`; the tagged line plus a faceted partition. At `vvM`, 100 GtC in 2050: **+100 yr, 9.7 % of the pulse's atoms are in the air against 50.4 % of the extra CO₂**. `test-c14-tag.R` 26 / 0. |
| **FaIR on the pulse lab's own pulse** ("Keep card 5; FaIR on same pulse") | `FaIRtoFrEDI/scripts/run_fair_vv_pulse_grid_for_ccx.py` (7 markers × 2030–2100/10, 100 GtC, 841 configs, paired) → `data-raw/build_fair_pulse_grid.R` → `data/fair_pulse_grid.rds`. It is drawn only on a grid point; off the grid the note gives the reason. **On the default pulse, CarboTope is inside FaIR's band at +1 / +20 / +100 / +250 yr.** `test-fair-pulse-grid.R` 35 / 0. |
| **Early-drawdown question** | Measured by a subagent (§2). Record: `notes/early_drawdown_diagnosis_2026-10-12.md`; scripts (UNREVIEWED) in `outputs/diagnostics/early_drawdown_20261012/`. |
| **Full suite at `54dde08`** | **7279 passed, 2 failed, 3 skipped** (`suite_20261012_54dde08.log`). The 2 are card 4's, by design. |
| **Live app** | Verified at 1024 px: card 5a's band; the pulse lab's two lines, two panels and FaIR band (on grid) / reason (off grid). 0 `shiny-output-error`. |

## 2. Decisions and their rationale

**Marcus, verbatim:**
- "Push now"
- "Re-run + quarantine (Recommended)"
- "hilda29a6 (Recommended)"
- "Write the facts note (Recommended)"
- "Side by side in pulse lab (Recommended)"
- "Draw the band. Do we have a physical explanation for why CarboTope has an early faster drawdown?"
- "Keep card 5; FaIR on same pulse (Recommended)"
- "Scale to basin spread (Recommended)"

**His new requests that started this:**
- "a button on the Futures panel which is a pulse but for a tracer to show how quickly the original carbon moves into different reservoirs (as versus the pulse). Or suggest a better way"
- "show the FaIR uncertainty envelope for the pulse. And if CarboTope is within that envelope, should we move Card 5 to the Futures panel"

**Mine, stated and not ruled (ask if wanted otherwise):**
- **FaIR gate G5 re-scoped after it FAILED on `vvH`.** "AF ≤ 1 everywhere" was my assumption, not a law.
  - The cause is FaIR's r_A sink saturation: zeroing `iirf_airborne` removes every case, while zeroing `iirf_temperature` or `iirf_uptake` does not.
  - G5 now requires AF > 0 always and AF ≤ 1 at the end of the release year.
  - The offending configs are KEPT and counted: 5–34 of 841, on `vvH` only. Diagnosis scripts: `outputs/diagnostics/fair_pulse_g5_20261012/`.
- **The grid driver mirrors the app's own exporter** (`run_fair_vv_for_ccx.py`), not the `run_fair_pulse_for_ccx.py` the question named. That one is ssp245 on RCMIP, and the app's backgrounds are the van Vuuren markers.
- **The "Compare with standard FaIR" box is OFFERED in the pulse lab again**, shared with the Scenarios view, default OFF. It was withheld 10-02 because it did nothing there.
- **The tag is the emissions DIFFERENCE** (month × hemisphere), placed through the two ¹⁴C source columns by a 2×2 solve. That needed no core change.
- **The 09-26 `hilda31pe` arm map was rebuilt** under the current code (its objective had been restamped). The arms comparison drops DECLARED arm-only streams that form a family of their own.

## 3. Files

- **New:**
  - code and tests: `R/c14_tag.R`; `data-raw/build_fair_pulse_grid.R`; `tests/testthat/test-c14-tag.R`, `test-fair-pulse-grid.R`;
  - data and diagnostics: `data/fair_pulse_grid.rds`; `outputs/diagnostics/{whole_model_scorecard_20261012_hilda29e.*, constraint_map_hilda29a6.rds, constraint_map_20261012_*.log, constraint_map_arms_20261012.log, suite_20261012_54dde08.log, early_drawdown_20261012/, fair_pulse_g5_20261012/}`;
  - quarantine: `outputs/quarantine/20261012_pd100_held_sst/`;
  - notes: `card5a_caption_facts_2026-10-12.md`, `early_drawdown_diagnosis_2026-10-12.md`.
- **Changed:**
  - `R/climate.R` (`c14_tag_base`);
  - `app/global.R`: the tie constants; `APP_PULSE_GTC_RANGE` / `APP_PULSE_YEAR_RANGE`; the FaIR pulse loader and matcher; the tag splice;
  - `app/server.R` (the tagged run, FaIR in the pulse lab, the note);
  - `app/ui.R` (5a height; named slider bounds; the FaIR box in the pulse lab);
  - `app/R/plots.R` (tagged line and panel, FaIR layer, the DRAFT keys and notes);
  - `app/R/review.R` and `plots_review.R` (5a band);
  - `calibration/diag_constraint_map_arms.R`; `calibration/diag_ta1_enso_thermocline_limb.R` (path into the quarantine);
  - `tests/testthat/test-cmap-tie.R` (re-expressed, approved by the ruling).
- **FaIRtoFrEDI** (`heat-ed-morbidity`, pushed): `scripts/run_fair_vv_pulse_grid_for_ccx.py` (`fa948f9`, `810acf4`).
  - Its raw output is in `CarbonCycleEmulator/data-raw/downloads/fair_v160_vv_pulse/` (gitignored, local): the CSV, provenance and gates. Re-run: about 10 min on the laptop.

## 4. Still open, all Marcus's

- **Copy, all DRAFTS:**
  - the tagged pulse's `KEY_PULSE_EXTRA`, `KEY_PULSE_TAGGED`, `PANEL_PULSE_EXTRA`, `PANEL_PULSE_TAGGED`, `PULSE_TAG_DECAY_NOTE` and `PULSE_TAG_PARTITION_NOTE`, plus the "Left:" prefix on his `PULSE_PARTITION_NOTE` (`app/R/plots.R`);
  - `APP_FAIR_PULSE_LAB_FMT`, `_OFFGRID_FMT` and `_NOTE` (`app/global.R`);
  - the section heading "Where the extra carbon ends up", which now sits over both panels.
- **Card 5a's caption:** "nothing from this source" is singular, and the card now has two sources. The facts are in the note: FaIR 0.483 / 0.364 / 0.291, band 0.453–0.515 / 0.307–0.413 / 0.223–0.369.
  - ⚠ The card's "decays faster here than in the multi-model mean" is true against Joos but the REVERSE against FaIR.
- **The early drawdown: what next.** About 3 GtC of the first-year ocean excess is unexplained. Candidates: the provisional alkalinity, the SH winter mixed-layer depth, the high-latitude box. Fertilisation is about 25 % strong, and its strength has not been checked against FACE.
  - CCX is pedagogical, not an emulator ([[ccx_pedagogical_not_emulator]]), so whether to chase any of this is his call.
- **The tie spread rests on ONE pair of basins.** A third basin can only widen it.
- **FaIR's temperature response to the pulse** is in the grid (`d_gmst_mean`) but NOT drawn on the pulse lab's temperature view. Not asked.
- **The FaIR box's default** in the pulse lab (OFF, shared with Scenarios). Confirm.
- **Unchanged from the 10-12 handoff:**
  - the band hold's four pieces of copy;
  - card 4's stale timing sentence and its two by-design failures;
  - the cards 2/3 ¹⁴C facts;
  - the residual-strip wording and the orphaned "The first is";
  - card 8's draft;
  - the constraint-map caption;
  - the What-if "about a third" (now 29 %);
  - the nine held-era diagnostics (convert on touch);
  - deploy (`SET-BEFORE-DEPLOY`, `ccx_app_beta_blockers`).

## 5. Non-obvious state

- **A background session is RUNNING:** task "Reconcile Joos 2013 ± convention across two files" (Marcus started the chip).
  - `calibration/diag_pulse_land_attribution.R:28-29, 55` reads Joos's split as "±1 sd" (and cites the wrong section); `lib_design_gates.R:2136-2141` reads it as 2 sd.
  - It is instructed to change no gate or number without Marcus's approval. Expect its CHANGELOG entry, and check the lettering against (l)/(m).
- **The app preview** runs at `http://127.0.0.1:7788` (launch config `ccx-app`) on `54dde08`'s code. After an R change, restart it; the first load takes about 3 min before "Listening".
- **Frozen worktrees made today:** `~/ccx_frozen/suite_20261012_0e57110` (previous session) and `~/ccx_frozen/suite_20261012_54dde08` (this one). Both can go (`git worktree remove`) once nobody needs the runs. The others in `~/ccx_frozen/` and `.claude/worktrees/*` are not mine.
- **Ephemeral scratchpad prototypes**, all superseded by repo code: `tag_proto.R`, `tag_plots.R`, `env.R` (the CarboTope-vs-FaIR-envelope year-by-year table, whose result is in CHANGELOG 10-12 g) and the `cmap/` helpers.
- **Memory:**
  - INDEX sizes: `INDEX_ccx_app` 15.2 KB, `INDEX_fair` 14.8, `INDEX_ccx_gates` 14.4, `INDEX_ccx_phi` 8.3. All are under the 18 KB hard budget, and three are over the 14 KB soft one (as before).
  - `ccx_app_beta_blockers` was NOT updated with the new draft copy; this handoff and the CHANGELOG carry it.
- **Untracked, leave them:** the three CarboTope comment docx files, `outputs/diagnostics/smoke/`, `outputs/mcmc_smoke/`.
