# HANDOFF 2026-10-11 — Marcus's 10-11 CarboTope comments are worked through; NEXT is card 5's FaIR PD100 line (ruled)

> **UPDATE 2026-10-12: SUPERSEDED** by `notes/handoff_2026-10-12_pd100_free_climate.md`. §3's FaIR PD100 is DONE and drawn, and card 5 is now climate FREE (Marcus: "free everywhere").

**Supersedes** `notes/handoff_2026-10-10_band_shipped_hold_on_copy.md`. Everything in its §3 that is still open is restated in §4 below.

Written on Marcus's request ("Yes, write the handoff note"), 2026-10-11. Nothing is running except the local app preview and the separate audit session (§5).

**Start here.**
1. CHANGELOG **2026-10-11 (a)** (and (b), this note's entry).
2. This note's §3: the FaIR PD100 task, which is ruled but not started.
3. `~/.claude/CLAUDE.md`, this repo's `CLAUDE.md`, and the skills **`fair-quirks`** and **`climate-modeling`** (paired-pulse discipline) before touching FaIR.
4. Memory: [[gate_newest_artifact_wrong_mode]] (new today) and `ccx_app_beta_blockers`.

## 1. What was done (source: `CarboTopecomments.10.11.26.docx`, untracked in the repo root)

| Item | Outcome |
|---|---|
| **"I get an error when selecting warming, ENSO, volcanoes, and ocean sink. Check all combinations"** | **FIXED** (`4e819ad`). 16 of 127 switch combinations crashed: `ocean_sink` with `warming_feedback` or `revelle`. The ocean switch acted inside the spin-up; the periodic Newton never converged (negative SH deep carbon) and the ¹³C solve was singular. Now RUN-ONLY: `CCX_MECH_RUN_ONLY` and `ccx_mechanism_spinup()` in `R/mechanisms.R`. 127 combinations: 0 errors; the 63 without the ocean switch are bit-identical; the others move ≤ 0.098 ppm. Regression test with a power check in `test-mechanisms.R` (105 / 105). |
| "…and perturbations" | `shiny::testServer` sweep of the real server, every tab's controls at their extremes, 6490 renders. Found ONE more crash: the regrowth chart with "Years shown" ending before 1959, now a `validate()` message. **Final sweep: 0 errors.** |
| "without Warming … 0.00 (100% less)": lower case | Done: `app_mech_inline()`; "El Niño", "CO₂" and "Revelle" keep their capitals; the one sentence-start use is capitalised. |
| "That math doesn't work: there's still noise" | **Measured, not changed.** With the four switches off, model growth is ~1e-12 ppm/yr, so "0.00" is right. The noise he saw is in the residual strip (model − measured = −measured). Rewording it is his call. |
| "GCB doesn't add up" said 3×, "only need two" | Cut MY paragraph in the "Why a bigger sink can be the closer one" box. His two are kept: the paragraph under the heading and `IMB_BAND_NOTE`. |
| "These 2 switches do not add up" → his sentence | Done, verbatim. |
| Keeling "it only adjusts" | Done. |
| Delete the harmonisation sentence | Done; `APP_SPLICE_STEP` removed with it. |
| Pulse box: two "Change"s, and his replacement paragraph | Done. His paragraph replaces three old ones; "form" → "from" and "dC" → °C; numbers come from the named constants. **RULED "Temperature only (Recommended)"**: "on temperature" (the CO₂ response spreads 6.4–7.0 %, ~3× the temperature figure). |
| "start the line at zero when the pulse starts" | Done: `pulse_from_release()`, an exact 0 at the release with annual means at mid-year. **RULED "Re-pin both (Recommended)"**: `test-future-yvar` and `test-app-review-copy` A2 are re-pinned (`76f6bf4`). |
| ⛔ Found on the way: the pulse numbers were **hilda33p's** | `test-pulse-linearity.R` read the newest CSV without its mode. Re-measured at hilda29e: spread **2.3 %**, horizons 1.44 / 1.37 / 1.35 / 1.40. The gate now requires the canonical's CSV and is mutation-tested (`fa6bb86`). An audit of the other gates was spun off (§5). |
| Card 4: "is the timing still true?" | **No.** At hilda29e the model peaks +5 months and the record +5 (`card4_audit_20261008_hilda29e.log` §5). The card's wording is his; test C4t pins the old phrase. |
| Cards 2 & 3: ¹⁴C gradient and air-sea disequilibrium | Facts only (CHANGELOG 10-11 a): the post-1980 NH−SH Δ¹⁴C matches Hua; the bomb era misses (gate 5 FAILS); the air-sea Δ¹⁴C disequilibrium is neither fitted nor gated (41 vs ~52 ‰, 1997); the ocean bomb-¹⁴C inventory overshoots (84 vs 56 kmol, 1995). Where any of it goes is his call. |
| Card 5: "add a FaIR pulse decay" | **RULED "Run FaIR on Joos's PD100 (Recommended)". NOT STARTED.** See §3. |
| "I didn't see any uncertainty bands" | Answered: the hold is still set, waiting on his copy (§4), and the app is not deployed (`carbotope.shinyapps.io/carbotope` returns 404). |

Commits: `4e819ad`, `fa6bb86`, `fb8ceba`, `76f6bf4` (all pushed), plus this note's commit.

## 2. Decisions and their rationale

- **Ocean switch = run-only, not "fix the solver".** The switch's own blurb asks what happens when the ocean stops absorbing *our* carbon. A spin-up with the ocean closed built a different 1750: 268 GtC moved within the ocean, and ¹⁴C production fell to 7 %.
  - Every other switch leaves 1750 bit-identical (ENSO, volcanic, emissions) or within 1 GtC (fertilisation, warming, Revelle), so it was left as it was.
  - The CO₂ effect is ≤ 0.1 ppm on combinations that already worked. Below the app's resolution, so no ruling was sought; it was reported.
- **The regrowth guard uses `validate()`, not `stop()`**: its message survives the error sanitising shinyapps.io applies.
- **A pulse-line point sits at mid-year**: the rows are annual means (0.446 in the release year, 0.903 the next), so drawing them at their integer year would start the rise a year early.

## 3. NEXT: card 5's FaIR PD100 line (ruled 10-11)

**The ruled option text:** "New FaIR run in FaIRtoFrEDI: 100 GtC in 2015 on a constant-2010 CO₂ background, climate free as in Joos, 841-config mean, imported with provenance and labelled FaIR 2.2.4 (calib 1.6.0). A few minutes on the laptop."

**Read first:**
- Joos et al. 2013, ACP 13:2793, at `~/Documents/2026/ClaudeDocs/Papers/joos.carboncycle.2013.acp-13-2793-2013`: §2 and Table 1, the PD100 protocol.
- CarboTope's own PD100 in `R/joos_irf.R`:
  - `JOOS_REF_YEAR` 2010, `JOOS_PULSE_YR` 2015, `JOOS_PULSE` 100, `JOOS_PPM_PER` 2.123;
  - the background is held by diagnosed compatible emissions (`ccx_hold_forcing`); `ccx_irf_pd()` holds it to 2015, then releases.
- Card 5: `app/R/review.R` ~L372–390 (the run) and `app/R/plots_review.R` ~L249–266 (the plot).
- ⚠ CarboTope's PD100 HOLDS temperature at 2010, and ENSO, land-use emissions and bomb ¹⁴C are zero. Joos lets climate evolve. The ruled FaIR line is "climate free as in Joos". **Say this difference on the card, or ask Marcus whether the FaIR arm should match CarboTope instead.**

**Choices to settle against the paper BEFORE running.** Flag each one; do not resolve silently.
1. The background CO₂ level: Joos's 389 ppm, or FaIR's own historical 2010 value?
2. Non-CO₂ forcing in the background: held at 2010, per Joos? Check §2.
3. How to hold CO₂: a concentration-driven FaIR run to diagnose emissions, then emissions-driven PAIRED runs, base and +100 GtC in 2015, from those emissions. Difference the pair; never a pulse against a different base.
4. The statistic: the 841-config MEAN of per-config differences, which matches Joos's multi-model mean and the existing CCX FaIR file. Memory says the median sits ~5 % below.
5. GtC per ppm: 2.123 (Joos, as card 5 uses) vs 2.124 (the existing FaIR files). Use the card's own constant.
6. The horizon: ~305 yr (card 5a). Card 5b (land/ocean split) probably gets no FaIR bar: FaIR's CO₂ boxes are timescales, not reservoirs (unverified).
7. ⚠ FaIR's CO₂ partition fractions (0.2173 / 0.224 / 0.2824 / 0.2763) and lifetimes (1e9 / 394.4 / 36.54 / 4.304 yr) ARE Joos's Table 5, as `species_configs_properties_1.6.0.csv` shows. So the FaIR line differs from Joos only through its state-dependent iIRF scaling. Say so where the line is captioned.

**Where to build it:**
- The template is `FaIRtoFrEDI/run_fair_pulse_for_ccx.py` (`a7e92ce`). ⚠ It exists ONLY on FaIRtoFrEDI's **`heat-ed-morbidity`** branch, not `main`.
- That branch is 27 commits ahead of origin and carries Marcus's UNCOMMITTED docx edits (`deliverables/egu_sprm/*.docx`). Do not touch, stash or commit those.
- **Ask Marcus which branch the new script goes on** (heat-ed-morbidity, beside its sibling, or a new branch).
- Python: `source ~/climate-env/bin/activate`. Torch verdict, said out loud: the laptop. Three runs × 841 configs × ~300 yr is minutes, with no licence or substrate blocker.

**Import (this repo's hard rule 3):**
- Outputs go to `data-raw/downloads/fair_v160_pulse/` with `MANIFEST.csv` (sha256) and a `_provenance.csv` (script, commit, FaIR version, calibration files, n_configs, protocol), following the 09-26 pulse file. Then a versioned `.rds` in `data/`.
- Label "FaIR 2.2.4 (calib 1.6.0)".
- Card 5's plot gains the line. A test pins it to the file (by md5 or provenance, and to the protocol constants), mutation-tested.
- The caption and card text are Marcus's.

## 4. Still open, all Marcus's

- **The band's hold** (unchanged since 10-10): the label, card 6, the panel clause, the temperature-view sentence (`APP_RIBBON_NOTE_TEMP`). Facts are in `notes/ship_copy_facts_2026-10-09.md`.
- **Card 4:** the timing sentence is stale. `test-review-card-numbers.R:75, :85` still fail by design; C4t pins the phrase.
- **Cards 2/3 ¹⁴C:** where, and whether, to add the facts in §1.
- **Optional:** wording for the residual strip under the four-switch case; the pulse box's "Two things … The first is" now has no "second".
- From the 10-08b/10-09 handoffs: card 8's draft, the constraint-map caption line, the What-if blurb ("about a third" is now 29 %).
- Deploy (shinyapps.io) is his: `SET-BEFORE-DEPLOY` and `ccx_app_beta_blockers`.

## 5. Non-obvious state

- **A separate local session is running the spun-off audit**, task "Audit app constants measured at a retired mode". It reports which other constant-vs-artifact gates lack a mode check. Read its result before trusting the full suite's green on any displayed number.
- **No full suite this session.** The last full suite was at `e1711dc` (10-09). Every file touched today was run on its own, all passing: mechanisms 105, future-yvar 35, app-review-copy 41, pulse-linearity 21, plus the 17 app-reading files. Run the full suite early next session (~18 min, frozen worktree as on 10-09). Card 4's two failures remain by design.
- **The local app preview** is running at `http://127.0.0.1:7788` (launch config `ccx-app`), on the final code.
- **The sweep harnesses are in this session's scratchpad** (`…/scratchpad/mech/sweep_server.R`, `sweep_fix.R`), which is ephemeral. To rebuild:
  - source `app/global.R`, then `app/R/*.R`. ⚠ Shiny auto-loads `app/R/`; a harness that sources only `global.R` fails every plot with "could not find function";
  - `server <- source("app/server.R")$value`;
  - `testServer(server, { session$setInputs(...); output[[id]] })`, classifying `shiny.silent.error` / `validation` as deliberate blanks.
- **The Keeling tab's "figure margins too large"** still appears at first render in the narrow preview pane (known transient, CHANGELOG 10-08). Not investigated.
- **Untracked, leave them:** `CarboTopecomments.10.11.26.docx` and the older comment docs, `outputs/diagnostics/smoke/`, `outputs/mcmc_smoke/`.
- **Kept, not mine to remove:** `~/ccx_frozen/20261008j_mcmc`, `.claude/worktrees/friendly-einstein-26825b`.
- **Memory:** `INDEX_diag.md` is 15.4 KB, over its 14 KB soft budget; today's line was added there. `INDEX_ccx_app.md` is 14.8 KB.
