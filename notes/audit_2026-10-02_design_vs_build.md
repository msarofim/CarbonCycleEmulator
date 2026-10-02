# AUDIT 2026-10-02 — DESIGN.md against what was built

**Marcus (10-02):** *"But scan for any other design.md definitions that weren't implemented first!"* The trigger was
the ENSO lag `L_MEI`: DESIGN specified it as fitted, it was never built, and nothing ever retired it (CHANGELOG 10-02 x).

**Method.**
- Four read-only audits ran in parallel, one per part of DESIGN.md:
  - §1–4: model structure and data;
  - §5: calibration design;
  - §6: sanity gates;
  - §7–9: app, repo layout and open questions.
- §10 (v2 backlog) is excluded: it is explicitly out of v1.
- Each item was classed as implemented, changed-with-record, retired-with-record, **changed silently**, **never built
  and never retired**, or unclear.
- Every flagged item below is marked **✓** if I re-checked it myself with grep, sed or a probe, or **(audit)** if it
  rests on the audit's file:line evidence without re-checking.
- Totals across the four audits:
  - implemented: 141;
  - changed with a record: 70;
  - retired with a record: 13.
- Nothing in the model, objective or app was changed by this audit.

---

## A. ⛔ Specified, never built, never retired

| # | DESIGN | item | evidence | note |
|---|---|---|---|---|
| A1 | l.51, 174–176, 557 | **`L_MEI`, a fitted ENSO lag on the land term**, U(0, 12) months | ✓ the index is read at t (R/model.R:2556, src/ccx_core.cpp:641); no lag name anywhere | It was listed as contradiction 7 in `notes/review_2026-09-16c_whole_model.md` l.46 ✓ and never reached a ruling. Diagnosed 10-02 (x). **Option 2 is in progress.** |
| A2 | l.502, 588 | **The Law Dome ice-core δ¹³C row**, "pre-1990 Suess target" (Rubino et al. 2019) | ✓ `ccx_prepare_obs()` loads only `co2_samples`; `d13c_samples` feeds only diag_d13c_midcentury.R and fig_model_vs_obs.R; no likelihood row | CHANGELOG 08-22 noted "NOT in the objective" and made no ruling (audit). Gate 8's retirement (09-02) does not cover 1750–1977 (audit). **The pre-1977 Suess decline is scored nowhere.** |
| A3 | l.209 | **The Revelle factor "displayed in the app"** | ✓ there is a "frozen Revelle" switch, but the factor itself is never shown | — |
| A4 | l.1280–81 | **Full calibration report**: posterior tables, prior-vs-posterior plots | (audit) no artifact or code; ✓ the docstring at likelihood.R:2044 refers to "the calibration report" as if it existed | Pieces exist: the scorecard, `diag_fit_at_mode.R`, the mode files' `prior_z`. |
| A5 | l.1958–70 | **App tab "How long does it last?"**: mass pulse vs ¹⁴C label pulse, turnover vs adjustment, background slider, Cawley. DESIGN calls it *"the tab the project exists for"* | ✓ absent from ui.R | Specced 08-13 with "Tab implementation is NOT done" (audit). The 08-29 spec's tab mapping dropped it (§D). |
| A6 | l.1972–81 | **App tab "What drives CO₂?"**: the r ≈ 0.93 / detrended 0.58 / δ¹³C-closing sequence | ✓ absent from ui.R | Only its "no emissions" switch was built. Its claim (ii), "it is ENSO, the model reproduces it", is undercut by A1. |
| A7 | l.2032–56 | **§7a "Claims you may meet"** appendix | (audit) nothing in app/ | The wording was your call (08-13 e). `app/www/sarofim_essenhigh_comment_2011.doc` was added for it and nothing links to it (audit). |
| A8 | l.1949, 1956–57, 2008–11 | Smaller §7 items: a partition of **annual** emissions; a Suess-vs-nuclear-test overlay; vegetation and soil columns from `ccx_run_fast()` for §7b | (audit) | The last is moot if §7b's five-bar panel is dropped (C8). |
| A9 | project CLAUDE.md rule 7 | **ppm / ‰ / GtC tooltips; a takeaway on every panel** | ✓ "Under the hood" has no takeaway. (audit) `gloss()` is used twice (ui.R:199, 206), so no ppm or ‰ tooltips exist, and the GtC one sits inside one collapsed box | Takeaways are plain text, so they cannot carry tooltips as written. |

## B. ⚠ Built differently, with no record of the change

| # | DESIGN | item | evidence |
|---|---|---|---|
| B1 | l.1279 | **The app runs the posterior MODE**, where DESIGN says the posterior median | ✓ app/global.R:295 `src <- "posterior mode"`. They are close in the one cell measured: MCMC median 825.5 vs mode 826.6 ppm, vvH 2150 (audit, 10-02 t). |
| B2 | l.1951 | "Live stock readouts (atm GtC, ocean DIC, land pools)" are cumulative uptake readouts instead | ✓ ui.R:219–226 |
| B3 | l.1956 | The NH→SH bomb-spike **animation** is a static chart | (audit) |
| B4 | l.55, §8; project CLAUDE.md rule 2 | **`data-raw/constants.R` does not exist**; the registry is `R/constants.R` | ✓. Three governing documents name a nonexistent file. |
| B5 | l.443–445, 488–489; project CLAUDE.md rule 3 | **Data provenance.** The nuclear-industry ¹⁴C files are fetched (download_data.R:414–433) but have no MANIFEST row and no versioned `data/*.rds`; the model reads the git-ignored raw CSVs at run time | ✓ 0 "nuc" rows in `data-raw/downloads/MANIFEST.csv`; ✓ `ccx_nuclear_c14_annual()` reads `data-raw/downloads/nuclear14c`. ✓ 0 rows for `eide`. `oscar_eluc` is reported missing (audit) but one "oscar" line exists, so this is unresolved. ✓ download_data.R:532 **overwrites** MANIFEST with its own rows only, so a full re-run would drop ~30 rows other scripts upserted (audit). |
| B6 | l.1540–80, 1769–88 | **Gates 6** (seasonal-amplitude growth) **and 11** (suspicious-uniformity screen) | Both left the maintained set after 09-04 without being retired. ✓ absent from `DG_LEDGER`; ✓ their only code, `diag_design_gates_unscored.R`, was last committed 09-04. (audit) That driver builds the model from defaults plus fitted names with the aseasonal spinup, so it cannot score the canonical. |
| B7 | l.1303 | **Gate P7 compares two different models** | ✓ the scorecard's P7 is arm B (`CCX_MODE_SEASML0_CONTROL`) vs arm C (canonical). (audit) Those differ in structure, seas_ml, objective and parameter count, so the 10-01 "P7 PASS" is not the mixed layer's own effect. The same mismatch was fixed in test-gate-p7.R on 09-21 g, but not in the scorecard. |
| B8 | l.1992 | **The repository link is a live placeholder** | ✓ app/global.R:109–113 says ui.R shows a warning when a URL is a placeholder, but ui.R:676 renders `APP_REPO_URL` ("SET-BEFORE-DEPLOY") as a live link with no check. Only the feedback link is guarded. |

## C. Needs a ruling

| # | DESIGN | item | state |
|---|---|---|---|
| C1 | l.99–100, 204–205, 552–553 | **Two `[VERIFY]` priors were never discharged**: `k_w` dlnorm(log 1500, 0.4) ("Wanninkhof global mean") and `tau_ex` dlnorm(log 1.3, 0.25) ("SF₆-derived ≈1.3 yr") | ✓ bare literals in `CCX_PARAM_TABLE` (calibrate.R:205, 643), outside the provisional-constant ledger. This breaks DESIGN §2 and project CLAUDE.md rule 2. |
| C2 | l.105–107 | **NPP₀ "to be FITTED against a modern-NPP prior (option 4)"** | (audit) arm B2 was blocked (09-29 j); ruling D4 made modern NPP a named tension (10-01 a); the DESIGN line was never retired. |
| C3 | l.501 | **Law Dome CO₂ as a "pre-1958 target"** | ✓ `co2_icecore` scores 52 post-1958 samples (likelihood.R comment at ~2133) that overlap MLO. Noted 08-22 as a "non-independent ice term"; no ruling (audit). |
| C4 | l.1459–60, 1505–07 | **Gate 5 sub-checks**: post-peak e-folding (15.4 yr) and peak heights | (audit) computed and printed but in no verdict; dropped by omission. Retire them or restore them. |
| C5 | l.1300, 1581–83 | **Gate 7 judges the sinks against bare GCB** | ✓ `dg_gcb_target()` uses bare GCB, while objective #14 scores GCB + s·I(t) (audit, CHANGELOG:932). |
| C6 | l.1383–85 | **Coverage of gates 1 and 2** | (audit) no whole-system ¹⁴C budget test with production on; gate 2's forward drift run checks only atmospheric CO₂ and Δ¹⁴C. |
| C7 | l.1450–56 | **Gate 4's pre-registration** (LUC time-profile changes are scored against gate 4) | (audit) orphaned when gate 4 retired (09-04e). It matters only if the LUC time profile changes. |
| C8 | §7 | **App items needing a ruling** | (audit) the "no land sink" toggle: merged into fertilisation at the first build, premise retracted 10-01, B5 declined a whole-sink switch. §7b's five bars to 3000 vs the three-reservoir chart to 2300 you asked for (F2, 09-22 r). The pulse lab's "depends on the background" is never shown. The parameter table has no "posterior ranges". "One-sentence" takeaways mostly run 2–3 sentences, several in your own wording. The pre-launch checklist has gone untracked since 09-27c. |

## D. Your 08-29 app spec — decided, parked 09-22, partly unbuilt

`notes/spec_2026-08-29_app_six_tabs.md` holds your requirements. DESIGN never mentions it; it was parked 09-22, and parts
have been built piecemeal since.
- **① "The ENSO and volcano boxes adjust BOTH the temperature and the non-temperature factors"**, via a
  **Foster–Rahmstorf-style regression decomposition of GMST** (§3b, *DECIDED 2026-08-29*) ✓. **Not built.** It bears
  directly on today's ENSO switch, whose caveat says El Niño's warming keeps running.
- **④ The tracer (label) chart**, chart 2 of the three decided pulse charts ✓ (spec l.19–23). Not built: the app has
  charts 1 and 3.
- **③ MAGICC** beside FaIR in Futures: only FaIR is built.
- **⑥ The ocean-transport (pump) tab** ("needs presentation, not physics"): not built (audit).
- ⑤ The hemispheric tab is deferred by your own ruling until the component is fixed. That is recorded, so it is not a gap.

## E. Documentation drift (the change is recorded, the governing text is stale)

**DESIGN.md:**
- l.3 still says "DRAFT … No model code".
- It names hilda31s (l.80) and hilda29l (l.226) as canonical.
- The §6 acceptance ledger is frozen at 09-14 g:
  - it has no gate D and no AIC gate;
  - Q reads FAIL where it now passes;
  - the ENSO→ocean "release blocker" was discharged 09-21;
  - IRF(100) reads 0.280, from before the 09-27 e clock fix (now 0.360).
- Gate G's row describes the circular inventory quantity the code deliberately does not judge.
- §5 errors:
  - §5.2k's headline was refuted on 08-28 d;
  - §5.2j's kz bracket is two re-bisections out of date;
  - §5.2l was replaced by objective #10;
  - `sigma_d13c` "remains free" (it was retired 08-18).
- §9's questions were all answered on 08-09.
- §1 numbers the tabs "4 and 5" where §7 has 5 and 6.

**Other files:**
- README still says "two-pool land biosphere" and "SSPs".
- Project CLAUDE.md says "No Python/Julia", but ✓ 6 `.py` files are tracked: 5 data-raw builders and `tools/palette_check.py`.
- lib_design_gates.R prints gate 7's land σ as "0.5 × 3.0 = 1.50" ✓; `LIK_LAND_SINK_INFLATE` has been 1.0 since #12.
- likelihood.R header notes still say the land-sink inflation "rides on top" and still name the retired `seas_amp_*`.
- The first app build (`6ca47c3`, 08-10) has no CHANGELOG entry.

## F. Your own text, flagged rather than edited

- **The airborne-fraction info box** (ui.R:206–214) says *"the ratio of emissions to the rise in atmospheric
  concentration in a given year"* ✓. That is the inverse of the airborne fraction (rise ÷ emissions). It is also
  annual, while the tooltip beside it ("the share of everything ever emitted that is still in the air") and the chart
  are cumulative.

## G. What bears on the Option-2 refit — decide BEFORE launching, so one refit covers it

A refit is the expensive step: the last one (#14) was 24 starts, 8 at a time, about 9 h on the Mac. Anything that
changes the objective or the parameter set should ride in the same refit.
1. **A2: the ice-core δ¹³C row** (an objective change).
2. **C1: citing the `k_w` and `tau_ex` priors** (a prior change if the cited values differ).
3. **C2: NPP₀ fitted**, or retire the DESIGN line.
4. **C3: the 52 post-1958 ice-core CO₂ samples.**
5. **How the lag is identified.**
   - A conditional probe by the refit-procedure audit (not yet reproduced by me) has the current objective preferring a
     land lag of **2–3 months**, through the GCB land-sink and seasonal-coefficient rows.
   - The growth-rate timing itself says **5 months** (10-02 x).
   - The growth-rate row was declined on 09-26, to be re-proposed only with "a NEW reason" (memory
     `ccx_growth_objective_declined`). ENSO timing may be that reason. Its three recorded objections still stand.
6. **Judging the refit honestly** needs B6 (gates 6/11), B7 (P7's arms) and C5 (gate 7's target). These are not
   objective changes, but they should be fixed before the new mode is scored.
