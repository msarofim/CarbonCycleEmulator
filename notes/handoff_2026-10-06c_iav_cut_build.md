# HANDOFF 2026-10-06c — BUILD OBJECTIVE #17: the interannual cut (Marcus's split calibration). Ruled; nothing built yet.

**Supersedes** `notes/handoff_2026-10-06b_rulings_applied_h2_priced.md`, which now points here. Everything in that note's
§4 not named below is still open, and its §5 non-obvious state still holds.
- Written on Marcus's ruling, verbatim: "Yes, handoff first (Recommended)".
- `main` is at this note's commit, pushed.

**Start here.**
1. `notes/proposal_2026-10-06_iav_cut.md`. It is the design and every number; §6 is the build as ruled.
2. CHANGELOG 2026-10-06 (n), then (m), then (l).
3. Memory, shared store:
   - `ccx_iav_cut_previewed` (new): the whole arc;
   - `ccx_growth_objective_declined` and `ccx_enso_response_too_early`, both cross-linked today and both corrected in
     place.

## 1. What happened today (this session)
- **Marcus's question, verbatim:**
  - "I still find it odd that there is a pattern in the data that ENSO causes a lagged effect on CO2 and that we can't
    somehow make our ENSO parameter do a better job of reproducing that lag.
  - "What about having a 12-month smoothed CO2 growth that is used only for calibrating the ENSO and volcanic aerosol
    parameters?
  - "E.g., the parameters that only care about interannual variability and not the regular annual cycle or the long term
    trend which is what all the other parameters in the model care about."
- **Previewed** as a modular ("cut") calibration. It is NOT the growth row declined on 09-26 or the timing row ruled
  out on 10-04: those sat in the JOINT objective.
- **Fitted to the growth alone:**
  - lag 5.9 months (the canonical's 2.6 is outside 2σ);
  - amplitude ×1.3–1.4, `gamma_diff` 0.56;
  - growth peak +6 (record +5); ENSO's What-if share 9.6 % → 25.9 %.
- **Why the joint fit holds 2.6.** The rows that see ENSO measure DIFFERENT objects:
  - GCB's DGVM land sink. It is earlier and weaker than the land sink GCB's own budget implies (data only), and GCB's
    imbalance is anti-correlated with ENSO;
  - MLO, which sees ENSO ~3 months before the global mean (data only, Scripps and NOAA). The two-box NH box cannot;
  - the seasonal harmonics: real information, not visibility. SPO's preference is UNEXPLAINED.
- **What does not help:**
  - a memory kernel reconciles nothing;
  - smoothing the land-sink row alone moves the joint lag only 2.5 → 2.9.
- **`gamma_diff` is not interannual-only.** Its AOD forcing has a positive mean, so it drags the fertilisation pair and
  2300 CO₂ by −22 ppm. Held at 0.25, as Marcus leans.
- **The low-pass land-sink row, priced.** It is an exact orthogonal split (df 6), so it needs no new σ. Under the cut,
  B2 goes from −36 to **−10**, the land row's trend part improves, and what remains is the seasonal rows (−13).

## 2. Rulings (Marcus, 2026-10-06, verbatim)
- "Explain why ocean enso is not also a part of this. But I think that land enso only is a good path."
  - "Land ENSO only" = `gamma_diff` held.
  - The ocean answer is proposal §5.3: on the growth alone the ocean term and the land term cancel each other; its own
    row pins it; so it goes IN the module WITH that row.
- "Price a smoothed row first (Recommended)" → done, CHANGELOG (m).
- "Monthly (Recommended)".
- **"Build: land + ocean module (Recommended)"**: objective #17, as proposal §6.
- **"Mac, overnight (Recommended)"**: the stage-2 refit host.
- "Yes, handoff first (Recommended)" → this note.
- Not answered: removing `~/ccx_frozen/20261006_iavcut_54d85e5`. Its outputs are in the repo; it is redundant. Ask.

## 3. THE BUILD (objective #17), in order. Each step is the next session's.
1. **A structure label for #17.** The name is Marcus's call; ASK. Follow #16's precedent: CHANGELOG 10-04 (n), the
   stratification feedback.
   - The pieces: `CCX_STRUCT_LABELS` (`R/calibrate.R:2489`), `ccx_struct_block()`, the gate machinery
     (`CCX_PARAM_GATES`, `ccx_apply_gate`).
   - Absent label = BIT-IDENTICAL: hilda33p's stored logpost must reproduce with diff 0.
2. **The low-pass land-sink row** in `R/likelihood.R`, `gcb_land_sink` block (~line 2666), switched by the label.
   - Definition, identical to the preview's `diag_iav_cut_smoothed_land.R`:
     - e = target − (model land + E_LUC) over the scored GCB years;
     - P = the orthogonal projection onto [1, ns(year, df = 6)];
     - row = Σ log N(e; 0, σ) + |(I−P)e|² / (2σ²).
   - Gate it against the preview: at hilda33p the low-pass row is −22.270 (raw −49.852, high −27.582).
   - Mutation-test it: break the projection, and the test must fail.
3. **`gcb_ocean_enso_slope` MOVES to the module**: out of the main objective under #17.
4. **The monthly growth data product** (Hard rule 3).
   - A `data-raw/` builder of the NOAA MBL global monthly series and its centred 12-month difference, plus a MANIFEST
     row and `data/*.rds`.
   - The source is the weekly `data-raw/downloads/mbl_zonal_co2_GL.txt`: month means of column V5, as in
     `lib_block_reopt.R br_obs_growth()`. The annual builder `data-raw/build_mbl_global_growth.R` is the template.
5. **The stage-1 module fitter** (a calibration script).
   - Objective: −(n_eff/2)·log(SSR / SSR_ref) + `gcb_ocean_enso_slope`'s row.
     - The growth is monthly, 1980–2024, both series detrended by ns df 5.
     - n_eff = 22.5: Bretherton 1999 eq. 31, measured at the canonical. Record it as a constant with provenance.
   - Names: `lag_enso_land`; ONE land scale s on (`gamma_enso_land_NH`, `gamma_enso_land_SH`), with NH : SH held at
     the canonical's 0.5078 : 0.4866; `w_enso_l2`.
   - Method: Nelder–Mead on real runs, as the preview did (~150–300 evaluations, 1–2 s each).
   - The preview's answer to reproduce: lag 5.84, ×1.30 (0.661 / 0.633), `w_enso_l2` 14.7, growth r 0.683.
   - Also report the lag's profile range.
6. **The multistart reference set.** `ccx_ms_reference_set()` (`R/calibrate.R:2621`) STOPS on an unregistered pin
   set (10-05 e). #17 pins the existing 10 plus the module's 4 (lag, both land gammas, `w_enso_l2`).
   - Add a RULED branch.
   - Regenerate the port targets: `make_port_targets.R` with `CCX_MS_STRUCT` / `CCX_MS_SEAS_ML` / `CCX_MS_PIN`.
     The driver STOPS on stale ones.
7. **Price #17 on the canonical before launching**, unrefitted and B2-style. Expect ≈ −10 (proposal §6).
8. **The stage-2 refit:** 24 starts on the Mac overnight, as ruled.
   - Run from a FROZEN worktree with `data-raw/downloads/*` symlinked in, under `caffeinate -i`.
   - CPU-clock budget, as #16. Expect ~13–16 h.
   - Wait on the PID, never with a `pgrep -f` loop.
9. **Iterate once:** re-run stage 1 at stage 2's values. The trend names move little (B2 +0.6 %), so expect a small
   shift. Then re-check.
10. **Read and land** as #16 was:
    - the scorecard, the constraint map, likelihood comparisons, the gate ledger;
    - adoption is Marcus's call.
11. **The app copy:** card 4 (the timing disclosure becomes obsolete), the What-if numbers, the wobble shares.
    - ⚠ `tests/testthat/test-review-card-numbers.R` will FAIL by design once the lag moves. Update the copy WITH Marcus,
      not the test.

**Design points still open, to ASK before or while building:**
- the label name;
- the CUT POSTERIOR for the app's ribbons: stage 1's spread propagated into stage 2. A Laplace approximation of the
  3-name module is the cheap option;
- whether stage 1 / stage 2 iterate to a fixed point or stop after one pass;
- `gamma_diff`'s own future: an AOD term made zero-mean, as Ruling A made the ENSO index? Separate from #17.

## 4. Files today (all committed; `main` = this note's commit)
- **Drivers** (`calibration/`):
  - `diag_iav_cut_preview.R`: A, B, C1–C4;
  - `diag_iav_kernel_preview.R`: C5;
  - `diag_iav_station_timing.R`: C6;
  - `diag_iav_cut_se.R`, `diag_iav_cut_scope.R`, `diag_iav_cut_smoothed_land.R`, `fig_iav_cut_preview.R`.
- **`calibration/lib_block_reopt.R`:** `br_cell()` gains optional `drop` and `base_over`. NULL = unchanged, return
  value too.
- **Outputs:** `outputs/diagnostics/iav_*_20261006_hilda33p.*`; the figure is `iav_cut_preview_20261006_hilda33p.png`.
- **Notes:** `notes/proposal_2026-10-06_iav_cut.md`, and this note.
- **Lints run green:** git-stamp, overlay-idiom, mode-struct, ui-year-bounds. The full suite was NOT re-run: no `R/`,
  `src/`, `app/` or `tests/` file changed.

## 5. Non-obvious state
- **Running:** only the `ccx-app` preview on localhost:7788, as the 10-06b note left it.
- **`~/ccx_frozen/20261006_iavcut_54d85e5`** is a detached worktree at `54d85e5`. It is redundant (its outputs are in
  the repo); removing it needs Marcus's OK.
- **The preview's C1 CORRECTS 10-06 (j).** The seasonal rows set how FIRMLY the lag is held, not where: without them
  the optimum is 2.65. Both memory files are corrected in place. ⚠ The 10-06b handoff's §4.3 still carries the old
  reading.
- **The FACE `fert_k` ceiling is WITHDRAWN.** Never gate a `fert_k` move on it (memory
  `face_ceiling_is_the_headline_in_disguise`).
- **dg_streams reproduces the objective's rows** to 2.7e-10 at the canonical. The preview's B1 attribution and C2 rely
  on it.
- **The superposition of the interannual terms holds** to 8.5e-5 ppm/yr against a 0.30 signal. It is fine for stage-1
  speed, but verify on real runs.
