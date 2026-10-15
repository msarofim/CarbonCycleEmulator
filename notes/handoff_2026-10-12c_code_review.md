# HANDOFF 2026-10-12 (c) — the pre-beta code review: the model's mechanics are clean; ONE live objective bug (IntCal σ) is measured, not fixed; five wrong app numbers are fixed; stale text corrected; the citation list is compiled; `v1.1-hilda29e` is NOT tagged

> ⚠ **SUPERSEDED** by `notes/handoff_2026-10-12d_citation_rulings_refit_plan.md` (2026-10-12). Read that one first; its §4 restates everything still open here. Review §4–§6 are now DONE, and every citation item is RULED.

**Supersedes** `notes/handoff_2026-10-12b_tagged_pulse_fair_grid.md`. Everything still open from its §4 is restated in §4 below.

Written on Marcus's request ("Yes, write the handoff note"), 2026-10-12. **Nothing is running** except the local app preview (§5). main = origin/main = `6e211d0` before this note's commit.

**Start here.**
1. CHANGELOG **2026-10-12 (n)–(w)**. (q) and (r) are PR #1's, from the Joos background session.
2. `notes/code_review_2026-10-12.md` — the review record. Its STATUS block at the top says what was fixed, what was measured and what is open.
3. `notes/constants_citation_needs_2026-10-12.md` (the citation list) and `notes/beta_copy_worklist_2026-10-12.md` (every string waiting on Marcus's words).
4. Memory, new or rewritten today:
   - [[ccx_intcal_sigma_is_age_years]]
   - [[ccx_flux_trace_snapshot_aliases]]
   - [[ccx_app_beta_blockers]] (head rewritten: the canonical is `hilda29e`)
   - [[joos2013_reading_traps]] (corrected: §4.3, not §3.2; Table 4 has two ranges)

## 1. What was done

| Item | Outcome |
|---|---|
| **Joos background session merged** | `3c45224` cherry-picked as `55206e3`, relettered (n): Joos's split ± are ±2 s.d., label only. PR #1, which Marcus merged, then fixed the two `lib_design_gates.R` band strings and ratified `DG_L_NSD` = 1 s.d., text only (q, r). |
| **Five Joos-labeled logs quarantined** ("Quarantine + README") | `outputs/quarantine/20261012_joos_pm_label/` (o). PR #1 confirmed "Keep them quarantined". |
| **"Easy improvements?"** | None. The ocean excess and fertilization would be model changes, and FaIR ΔT would need a FaIR re-run. Marcus: finalize the model, work on the text. |
| **Beta copy worklist** | `notes/beta_copy_worklist_2026-10-12.md`: A 5, B 11, C 16, D 5, E 5, F 6 (p). Measured: `APP_SPLICE_YEAR` = **2024**, so `APP_FAIR_NOTE`'s typed "Before 2024" is a year early. |
| **Pre-beta code review** ("one more full code review … then push") | Seven read-only lanes. Record: `notes/code_review_2026-10-12.md`; scripts in `outputs/diagnostics/code_review_20261012/` (s). **Clean at the canonical:** conservation ≤ 1e-13, R↔C++ ≤ 1.3e-16, stability, periodic spin-up 1.4e-10, mode resolution, logpost Δ 0, app loaders, pulse pairing. |
| **IntCal σ bug — MEASURED** ("Measure impact first") | The row's σ is the ¹⁴C-AGE sigma (yr) used as ‰; the published Δ¹⁴C σ is 1.2–1.4 ‰. PSIS on 1000 draws (k-hat 0.149, ESS 437): **`luc_scale` +0.67, `bomb_total` −0.54, `rep_dC` +0.53 sd**; vvM CO₂ 2100 563.8 → 564.0 ppm, band shift ≤ 0.066 × its width; 2010–19 land sink 2.861 → 2.907. **Nothing canonical changed** (u). |
| **Five wrong app numbers — FIXED** (all four groups) | Scenarios span (305–825), Keeling (315 in 1958; 423 vs 424, 2024 means), δ¹³C since 1850 (2.35), land crossing (1969), box diagram (59 / 58, warm route, L2 limb in the tap, exact RK4 trace opt-in). New tests: `test-flux-trace-exact.R` 16 / 0 (2 mutations caught) and `test-takeaway-arithmetic.R` 26 / 0 (t). Verified in the browser (w). |
| **Stale text — FIXED** ("Fix all text-only") | 14 `.R` files under a parse-identity gate; 3 registry `source` strings and 1 validator message (values proven identical); `CLAUDE.md` constants path and roundoff parity; DESIGN path, parity, §6 banner and MM note (v). |
| **Constants citation list** ("Cite before beta") | `notes/constants_citation_needs_2026-10-12.md`: 31 items, 20 in the fitted objective, 24 with an on-disk candidate. **12 candidates disagree with the code, 6 of them in the objective** (refit if adopted). **7 have nothing on disk.** |
| **Full suite** | `56b5ceb` and `d36cda1` both **7321 passed, 2 failed (card 4's, by design), 3 skipped**. Logs: `outputs/diagnostics/suite_20261012_{56b5ceb,d36cda1}.log`. |

## 2. Decisions and their rationale

**Marcus, verbatim (this session):**
- "Quarantine + README (Recommended)"
- "Are any of these easy improvements? If not, I think I want to finalize this model version and work on the text so I can release the beta version."
- "Keep OFF, shared (Recommended)" (the FaIR box in the pulse lab)
- "Do one more full code review of the model to make sure there are no bugs or inconsistencies. Then push it."
- "Measure impact first (Recommended)"
- "Scenarios span (Recommended), Keeling year + land crossing, Keeling 'today' like-for-like, Box diagram ocean arrow"
- "Fix all text-only (Recommended)" (including the `CLAUDE.md` line)
- "Cite before beta"
- **Via PR #1** (the Joos session): "Fix the two ledger strings; leave the logs in place", then "Keep DG_L_NSD at 1 sd; push the branch", then "Keep them quarantined; merge the PR".

**Mine, stated and not ruled (ask if wanted otherwise):**
- **"Then push it" was read as "push main".** The tag was withheld because the review found a live objective bug.
- **The Keeling numbers are calendar-year means of the SCORED line**, the 1958 one included. The δ¹³C "since 1850" uses annual means at both ends; fixing only its tie would have compared a January with a December.
- **The flux trace's DEFAULT stays the snapshot**; the exact RK4 trace is opt-in (`flux_method = "rk4"`), used by the box diagram. I first made RK4 the default, and `test-npp-record.R` failed. The test was not touched; the change was narrowed.
- **`APP_FLUX` traces only the year the app reads** (C++ to Dec 2023, then the R core with the ENSO history and T_deep): 0.8 s. The split's 2024 equals a full R run's to 1.5e-12.
- **The IntCal measurement:**
  - changed σ only (column 5); the row's converted d14c values were kept (within 0.106 ‰ of the published column 4);
  - kept the 4 ‰ representation term;
  - used raw weights, with no Pareto smoothing;
  - used N = 1000, every 17th pooled draw.
- **The worklist and the citation list were compiled by subagents and spot-checked:**
  - all 36 worklist locations and 170 quoted lines were found in the code;
  - the Bastos 2016 Table 4 quote was verified against the PDF.

## 3. Files

- **New:**
  - `notes/{code_review,beta_copy_worklist,constants_citation_needs}_2026-10-12.md`;
  - `tests/testthat/{test-flux-trace-exact,test-takeaway-arithmetic}.R`;
  - `calibration/diag_intcal_sigma_impact.R`;
  - `outputs/diagnostics/{code_review_20261012/, intcal_impact_20261012/, suite_20261012_56b5ceb.log, suite_20261012_d36cda1.log}`;
  - `outputs/quarantine/20261012_joos_pm_label/`.
- **Code changed (t):**
  - `R/model.R` (the L2 limb records);
  - `R/fluxes.R` (`ccx_flux_stage_vec`, `ccx_step_rk4_traced`, `ccx_flux_trace_rk4`, `ccx_flux_warm_route`; the `hs_hd_net` comment);
  - `R/forcing.R` (`ccx_run(flux_method = )`);
  - `app/global.R` (`app_year_mask`, `app_annual_mean_of`, `app_scenario_span`, `app_keeling_numbers`; the split `APP_FLUX`);
  - `app/server.R` (Keeling, Isotopes, Scenarios, land-use note);
  - `app/R/plots.R` (`app_sinks_annual()$land_net`; the warm route in the diagram).
- **Text only (v):**
  - 14 `.R` files;
  - `R/constants.R` (3 `source` strings);
  - `R/paths.R` (1 message);
  - `CLAUDE.md`, `DESIGN.md`;
  - `tests/testthat/test-spinup-diagnostics.R` (comments).
- **Merged:** `calibration/diag_pulse_land_attribution.R` (n); `calibration/lib_design_gates.R` (PR #1).

## 4. Still open, all Marcus's

- **IntCal: refit, or ship `hilda29e` and document it?** The impact is in (u).
  - My suggestion: settle the citation list first. Six in-objective values would change on adoption, which alone means a refit, so one refit could take both.
  - The fix itself:
    - `data-raw/build_calibration_data.R` takes the published Δ¹⁴C σ (column 5) from the downloaded IntCal20 file;
    - add a `download_data.R` / `MANIFEST.csv` entry (URL `https://intcal.org/curves/intcal20.14c`, accessed 2026-10-12, sha256 `974a6664…168e`);
    - rebuild `data/obs_d14c_intcal20.rds`;
    - then refit. ⚠ After the data change the canonical's stored logpost will NOT reproduce, so `test-mode-file` (d) must move with the refit.
- **The citation list:** supply or approve sources. Seven items have nothing on disk:
  - `PUMP_EPS13_ORG`;
  - `OCEAN_DEPTH`;
  - the obliquity;
  - the +10-day declination offset;
  - `CCX_SEAS_T_LAG`;
  - `FORC_BOMB_NH_SHARE`;
  - the Earth area and the 2.04 atoms cm⁻² s⁻¹ production rate.
  - ⚠ The bomb and nuclear NH shares must change TOGETHER (the ¹⁴C tag's 2×2 solve needs them to differ).
- **The flux trace's default:** snapshot (now) or RK4 month-mean (and the NPP record with it).
- **The `v1.1-hilda29e` tag:** not made. Decide after the IntCal question.
- **Copy:**
  - the whole worklist;
  - two new items from the review:
    - card 6's title "no uncertainty bands, anywhere" is already false (FaIR bands on 5a and in the pulse lab);
    - the pulse box's "about 1.4 °C per 1000 GtC" was measured only on vvM / 2050: 1.12–1.47 on vvH, 1.43–1.69 on vvLN (review §2 A6);
  - the 10-12b list: the tagged-pulse keys / panels / notes, the FaIR pulse-lab formats, the section heading, card 5a's caption, and "decays faster" (reversed against FaIR).
- **Code items the review listed and nothing has fixed yet:**
  - `CCX_MODE_RETIRED` lacks five names;
  - the dead fallback mode path at `app/global.R` ~211;
  - `APP_HIST_YEARS` and `server.R`'s year ranges are typed;
  - the periodic spin-up report's start-of-year δ¹³C / Δ¹⁴C;
  - `ccx_run`'s fused roxygen block (`forcing.R` ~1220);
  - 13 dormant bugs (review §5);
  - test-coverage gaps (review §6: conservation, parity and spin-up tests run the defaults, not the canonical).
- **Unchanged from 10-12b:**
  - the early-drawdown question (3 GtC of first-year ocean excess unexplained);
  - the tie spread rests on one pair of basins;
  - FaIR ΔT in the pulse lab (not asked);
  - card 4's two by-design failures;
  - the cards 2/3 ¹⁴C facts;
  - the residual-strip wording;
  - card 8's draft;
  - the constraint-map caption;
  - the What-if "about a third" (29 %);
  - the nine held-era diagnostics (convert on touch);
  - deploy (`SET-BEFORE-DEPLOY` ×2; start-up re-timing on an IDLE machine — `global.R` now loads in about 5 s here, but the deploy timing is a separate measurement; hosting limits).

## 5. Non-obvious state

- **The app preview** runs at `http://127.0.0.1:7788` (launch config `ccx-app`) on `d36cda1`'s code; no code changed after that. In the pane's own session, all seven Scenarios boxes were ticked by my check.
- **Frozen worktrees** (all removable with `git worktree remove` once nobody needs the runs):
  - made this session: `~/ccx_frozen/{intcal_impact_1b16747, suite_20261012_56b5ceb, suite_20261012_d36cda1}`. The IntCal one has `data-raw/downloads` SYMLINKED to the main tree, so remove the link before deleting by hand.
  - from 10-12b: `suite_20261012_{0e57110,54dde08}`.
  - `.claude/worktrees/recursing-hermann-a2f965` belonged to the ended Joos background session, whose branch went in through PR #1.
- **IntCal20 is downloaded** to `data-raw/downloads/intcal20/intcal20.14c` (gitignored). It is not yet in `download_data.R` / `MANIFEST.csv`.
- ⚠ **`rintcal` is no longer installed.** Re-running `data-raw/build_calibration_data.R` today would WARN AND SKIP the IntCal block, leaving the old `data/obs_d14c_intcal20.rds` in place. The fix should read the downloaded file, not `rintcal`.
- **The review's scripts are UNREVIEWED as code** (`outputs/diagnostics/code_review_20261012/L1…L7/`). Their numbers were checked where §1 of the review says "[verified]".
- **Memory sizes:** `INDEX_ccx_app` 15.2 KB and `INDEX_ccx_ref` 12.3 KB, both under the 18 KB hard budget. `INDEX_ccx_app` is over the 14 KB soft one, as before.
- **Untracked, leave them:** the three CarboTope comment `.docx` files, `outputs/diagnostics/smoke/`, `outputs/mcmc_smoke/`.
