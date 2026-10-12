# HANDOFF 2026-10-12 — Card 5's FaIR line is drawn and the PD100 is climate FREE everywhere it is live; the suite is at 3 expected failures

**Supersedes** `notes/handoff_2026-10-11_comments_fair_pd100.md`. Everything still open from its §4 is restated in §4 below.

Written on Marcus's request ("Approve the lint update, then write the handoff note"), 2026-10-12. Nothing is running except the local app preview.

**Start here.**
1. CHANGELOG **2026-10-12 (b)** (the work) and **(c)** (the suite). ⚠ Lettering: a concurrent session took (a) first. Commit `0e57110`'s message calls my entry "(a)"; it is (b).
2. Memory: [[ccx_pd100_free_climate]], [[fair_pd100_for_ccx]], [[diag_built_vector_drifts_from_canonical]] (all new today).
3. `fair-quirks` skill item 14 (new today) before any concentration-driven FaIR rerun.

## 1. What was done

| Item | Outcome |
|---|---|
| **Card 5's FaIR PD100 line** (ruled 10-11) | **DONE and DRAWN.** `FaIRtoFrEDI/run_fair_pd100_for_ccx.py` (heat-ed-morbidity `964aa12`, **not pushed**). It runs Joos Table 1 runs 1–3 on `calibration_v160_prod`. 4 gates, 6 of 6 mutations caught; byte-identical across two runs; 72 s. IRF 20/100/300 = 0.483 / 0.364 / 0.291, α 0.283. Imported by `data-raw/build_fair_pd100.R` → `data/fair_pd100.rds`; test `test-fair-pd100.R` 22 / 0. Drawn dashed on card 5a, legend in two rows. |
| **Free climate everywhere live** | **DONE.** One runner, `ccx_pd100()` in `R/joos_irf.R`. Used by card 5a, gate L / card 5b (now released at 2015, as 5a), the scorecard §4, tl_land_share and `diag_joos_irf.R`. Card 5 at hilda29e: **0.522 / 0.379 / 0.295** (held as shipped: 0.509 / 0.361 / 0.271); 5b **17.4 / 57.6 / 25.0 %**, z +0.20 / −0.23 / −0.01. All typed claims on the card still hold. `rv_pulse` 5.2 s. Test `test-pd100-runner.R` 22 / 0, 5 of 5 mutations caught. |
| **Two bugs in the held builder** | FIXED. `ccx_pulse_forcings()` held GMST by hand and left observed SST running (now `ccx_hold_climate()`): +0.20 % IRF@100. T_deep restarted at 0 at each seam (now carried): −0.01 %. |
| **Two bugs in `diag_joos_irf.R`** | FIXED. It used the aseasonal spin-up and dropped `ndep_ret` (the gated overlay): 403.2 vs 393.6 ppm background. It now reproduces card 5 exactly. Three logs quarantined in `outputs/quarantine/20261012_joos_irf_aseasonal_spinup/` (README), including the 09-27 source of "TH 13.04/25.80/41.80 at hilda29l". |
| Full suite at `0e57110` | **7204 passed, 5 failed, 3 skipped**, 18.2 min (`outputs/diagnostics/suite_20261012_0e57110.log`). The two lint-ratchet failures are now fixed (`1ef8d7e`, "Approve the lint update"), so **3 are expected**: `test-cmap-tie.R:131` (the audit's deliberate RED) and card 4's `test-review-card-numbers.R:75`, `:85`. |
| Live app | Verified at 1024 px: card 5 renders with the FaIR line and the free numbers in both captions; 0 `shiny-output-error`. |

## 2. Decisions and their rationale (Marcus, verbatim)

- **"Allow 2320 for this run"**: a PD100 exception to the 2300 end year. Nothing after 2010 reads scenario data.
- **"heat-ed-morbidity"**: the driver sits beside its sibling `run_fair_pulse_for_ccx.py`. Only the new file was staged, by path; his egu_sprm docx edits are untouched.
- **"Mid-release, t = year − 2015.5"**: FaIR spreads the pulse over 2015.
- **"Free everywhere"**, his reason being *"if climate/carbon feedbacks are relevant for Card 5, they'd also be relevant for the Futures tab"*.
  - Measured first: the held/free mismatch alone flipped FaIR to the other side of CarboTope at 100 and 300 yr. Like-for-like, CarboTope sits a few % above FaIR under either protocol.
  - Nearly all of the free − held difference is the pulse's own +0.15 K.
  - Scope ruled **"Builder + live consumers"**.
- **"Release at 2015, like 5a and Joos"**: gate L had pulsed the 2010 state.
- **"Fix both in the builder"**: the SST and T_deep fixes.
- **"Approve the lint update"**: `OI_BASELINE_N` 59 → 58.
- **Mine, stated and not ruled; ask if wanted otherwise:**
  - FaIR uses its OWN emissions-driven CO₂ history, not the RCMIP record (measured ≤ 0.16 %).
  - `stochastic_run` is left at the posterior's value (≤ 0.05 %).
  - The PI case in `diag_joos_irf.R` §4 releases after the same 5-yr hold as PD (it pulsed at row 1).
  - `ccx_irf_pd()` treats a table with no `pd_climate` stamp as **held**, with a message, so that `test-pulse.R` and the held-era diagnostics run unchanged.

## 3. Files

- **New:**
  - `R/joos_irf.R`: `ccx_pd100`, `ccx_pulse_ref_state`, `ccx_pulse_continue`, `ccx_pulse_background` (free/held; `coupled = TRUE` for a decaying background), `ccx_pulse_pair`, `ccx_pulse_set_climate`; `CCX_PD_CLIMATE_DEFAULT`.
  - `R/climate.R`: `ccx_climate_irf_filter()` (a bit-identical split).
  - `data-raw/build_fair_pd100.R`; `data/fair_pd100.rds`.
  - Tests: `test-fair-pd100.R`, `test-pd100-runner.R`.
  - Outputs: `outputs/diagnostics/joos_irf_canonical_20261012.log`, `tl_land_share_gate_20261012.{log,rds}`, `suite_20261012_0e57110.log`.
- **Changed:**
  - `app/R/review.R` (rv_pulse; `RV_PD_CLIMATE`, `RV_FAIR_PD100_FILE`, `RV_FAIR_LAB_FMT`);
  - `app/R/plots_review.R` (card 5a's third line);
  - `calibration/lib_design_gates.R` (gate L);
  - `diag_whole_model_scorecard.R`, `diag_joos_irf.R`;
  - `diag_rep_dc_product_ladder.R` (gate L pinned "held");
  - nine diagnostics headed **"HELD-ERA RECORD (2026-10-12)"**, not converted;
  - DESIGN §6 gate 12 (the protocol paragraph);
  - `test-overlay-idiom-lint.R` (the approved tightening).
- **FaIRtoFrEDI:** `run_fair_pd100_for_ccx.py` (`964aa12`). The export goes to `data-raw/downloads/fair_v160_pd100/` (gitignored, local): CSV, provenance, MANIFEST, run log.

## 4. Still open, all Marcus's

- **Card 5a's caption** (his copy): it prints no FaIR numbers, and it might say that all three lines now share Joos's climate-free protocol.
- **Push FaIRtoFrEDI heat-ed-morbidity?** It is 28 ahead of origin: `964aa12` plus 27 earlier commits.
- **The scorecard is not re-run** (an adoption-time tool; its next run is free).
  - Its 10-06/10-07 logs and `tl_land_share_gate_20260908.*` were NOT quarantined. Their PD100 parts carry the ≤ 0.3 % SST defect, no code reads them, and their other sections are valid. Ask him if they should move.
- **The nine held-era diagnostics** may carry the SST, T_deep, spin-up or overlay bugs. They were not converted, by ruling; convert on touch.
- **Unchanged from 10-11:**
  - the band hold's four pieces of copy (`notes/ship_copy_facts_2026-10-09.md`);
  - card 4's stale timing sentence and its two by-design failures;
  - the cards 2/3 ¹⁴C facts (CHANGELOG 10-11 a);
  - the residual-strip wording and the pulse box's orphaned "The first is";
  - card 8's draft, the constraint-map caption, the What-if "about a third" (now 29 %);
  - the constraint-map tie cut (the deliberate RED clears when `diag_constraint_map_arms.R` is re-run at hilda29e; the comparison arms are his to choose);
  - deploy (`SET-BEFORE-DEPLOY`, `ccx_app_beta_blockers`).

## 5. Non-obvious state

- **The app preview** runs at `http://127.0.0.1:7788` (launch config `ccx-app`), restarted today on the new code.
- **Frozen worktree** `~/ccx_frozen/suite_20261012_0e57110`, created today for the suite. It can go once nobody needs the run (`git worktree remove`); `~/ccx_frozen/20261008j_mcmc` and `.claude/worktrees/*` are not mine.
- **Both background sessions have ended**, and their work is in main:
  - "Audit app constants measured at a retired mode": CHANGELOG 10-11 (c) and 10-12 (a), with the deliberate cmap-tie RED;
  - the N7 driver fix (`551928e`).
- **The prototypes are in this session's scratchpad** (ephemeral): `…/scratchpad/pd100/`, holding `proto_pd100.py`, `card5_free.R`, `analyse.py` and the mutation copies. Everything that mattered is now in the repo's runner, drivers and tests.
  - The prototype's "FaIR held climate" arm (IRF@100 ≈ 0.345) was an APPROXIMATION: `iirf_temperature` 0, with `iirf_0` shifted by rT × T2010 over the whole run, history included. The exact version (a restart at 2010) was never built, and is no longer needed under the ruling.
- **Memory:** `INDEX_ccx_app` 14.97 KB, `INDEX_ccx_gates` 14.18, `INDEX_fair` 14.59, `INDEX_diag` 15.63. All are over the 14 KB soft budget and under the 18 KB hard one. `ccx_app_beta_blockers` has its card-5 section rewritten, and `ccx_joos_gate` has a 10-12 banner.
- **Untracked, leave them:** the three CarboTope comment docx files, `outputs/diagnostics/smoke/`, `outputs/mcmc_smoke/`.
