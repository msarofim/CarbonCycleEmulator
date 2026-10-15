# Handoff 2026-09-30: fixed-stock futures, the cheap measurements (A–D), the inert pool and sink → source

> Launch from `FaIRtoFrEDI/`, then `change_directory` here (CLAUDE.md). ⛔ **Never use a bare `cd` in a
> Bash call**; use `git -C` or absolute paths. Last session a `cd` into a worktree moved the session cwd,
> and removing that worktree left the shell in a deleted directory.
> **Read first:** this file, then CHANGELOG **2026-09-29 (u) and (v)**, then memory
> **`ccx_cheap_measurements_0929v.md`** (pointer in `INDEX_ccx_phi.md`), which links back to
> `ccx_npp_is_a_residence_ridge.md` for the (m)–(s) arc.
> The previous handoff is `notes/handoff_2026-09-29_passive_soil.md`. Its §4 items are resolved or
> carried in §4 below.

---

## 1. What we were working on
We continued `handoff_2026-09-29_passive_soil.md`:
- **Item 2 of that handoff:** the futures at τ_slow 2000–5000 at fixed stock.
- **Marcus's questions** on its decision points:
  1. Does τ_slow help the radiocarbon fits?
  2. An inert soil pool.
  3. Does either help the NPP tension?
  4. Can the land turn from sink to source?
  5. The refit and R2.
- **"Run all the cheap measurements"** to answer them.

Every run is at arm A (`hilda_csl3v0ka`), v0k basin 1. The control is the fixed-stock τ-500
rebalanced vector (11 names re-optimized).

## 2. Decisions and positions (Marcus), in order
1. **"Expand on the decision points"** was answered in chat (not a file).
2. **Marcus's positions (09-29, stated, not formal rulings):**
   - An inert pool should be **part of the model**, not only applied at the comparison step. He
     thinks this is more consistent.
   - **Sink → source:** "I don't see how we can build in a sink to source effect … given our design
     criteria. I think that might have to be a major caveat."
   - ⛔ **"Refitting should wait until we figure out 1–4."**
   - ⛔ **"I'd want to revisit R2 with a longer explanation."** It is not drafted yet.
3. **Carve-out vs add-on:** Marcus asked whether carve-out is the right choice. I answered yes:
   the inventories weigh radiocarbon-free carbon, so an add-on double-counts it. He did not
   explicitly confirm. ⚠ **The depth scope is open:** Copard's inert fraction is 0.195 to 1 m but
   0.51 at 1–2 m. The runs used 0–1 m, which gives 0.195, an inert mass of 292 GtC and an
   exchanging passive stock of 1208.
4. **"Run all the cheap measurements."** Done: A–D, plus two follow-ups the results required (the
   literature-fertilization arm and the q10-pinned NPP scan).

## 3. Results (all in CHANGELOG (u)/(v); every identity and gate passed)
- **(u) Fixed-stock futures at τ 2000 / 3000 / 5000:** SSP5-8.5 2300 +137 / +153 / +182 ppm.
  - The effect **saturates**, as the retention weight predicted; half of it is reached at τ ≈ 1250.
  - The 500 / 1000 / 1500 rows are identical to the shipped (r) output.
- **A. Bomb partition:** τ and the carve-out move each reservoir by ≤ 1–2 kmol.
  - 1995 at N&L's input: atmosphere 18.4–18.8 (observed 20.3–22.8); ocean 67–70 (observed 55.5 ± 7.6).
  - Land 13.3–16.5 against N&L's model 18.9. **There is no land observation.**
  - ⇒ The passive pool cannot fix the radiocarbon defects.
- **B. Sink → source (SSP5-8.5):**
  - **No flip at the fitted vector**, at frozen q10 2.0, or at re-fitted q10 2.0 (loglik −35.9).
  - **A flip in 2274 only at literature fertilization (β_max 1.34, K 580) plus q10 2.0.** That run
    sits inside Koven's ±1σ for 2100–2200 and 2200–2300.
  - **The lever is the fitted fertilization:** NPP goes 60 → 137 by 2200. A flip needs
    q10^(ΔT/10) > NPP/NPP0.
  - **q10 is held low by the seasonal temperature-amplitude observation priors** (~40 of 46
    logpost units). One q10 serves the seasonal and the century scales.
  - vvL goes to a small source after ~2128 in every arm. That is carbon returning as CO₂ falls.
- **C. NPP with the decadal residence times free and the passive stock fixed:**
  - With q10 free, ×0.80 (NPP 57) costs only −8.8, but **only via the q10 < 1 escape**.
  - **With q10 pinned at 1.10 it costs up to −39.6** (maxit, so an upper bound), and the seasonal
    streams pay.
  - ⇒ The NPP ~56 target is not cheap by any route tested.
- **D. Carve-out proxy** (`litter_slow_frac` × the exchanging fraction):
  - At f 0.195 the record cost is −4.4 and SSP5-8.5 2300 moves +18.8 ppm.
  - **The in-model bulk soil Δ¹⁴C is −206 ‰ against Shi's −244 ± 48 (z +0.8)**, so τ 500 matches
    Shi once the inert pool exists.
  - The ±1σ on f (my propagation, layers fully correlated) spans z +3.6 to −2.0 and +7 to +54 ppm.
  - A frozen carve-out gives +52 ppm; the re-fit absorbs ~64%.

## 4. Open questions / next steps (all Marcus's)
1. **Inert pool, depth scope.**
   - Options: 0–1 m with f 0.195, or deeper.
   - Then the build: C++ core + R reference with a bit-parity test (hard rule 1), the conservation
     tests, a cited f in `constants.R`, and a DESIGN.md spec change. Keep it strictly inert
     (constant, no fluxes; spinup unaffected).
   - ⚠ **No go-ahead to build has been given.**
2. **τ_slow prior** (the old item 1: a / b / c). It is reframed by D. With an inert pool, Shi's
   bulk constrains the pair (f, τ), not τ alone.
3. **The fertilization strength** is now the main sink → source lever. The fitted β_max 2.55 /
   K 868 lies above the 09-28 (c) literature band (β_max 1.3–2.0, K 500–750).
   - It is tied to R2: at the measured `rep_dC` offset (0.776), φ = 0 fertilization lands inside
     the band (β_max 1.97, K 644) for −45.0 ([[ccx_rep_dc_lever_is_the_phi_loop]]).
   - Proposed caveat wording, not yet accepted: "the fitted CO₂ fertilization is stronger than the
     literature supports, and one q10 does two jobs." Marcus's own framing was "a major caveat".
4. **R2 write-up, when Marcus asks for it.** Source material:
   - `ccx_rep_dc_prior.md` (the 09-23 ruling, T1 / T2 / T3 / T4p);
   - `ccx_rep_dc_lever_is_the_phi_loop.md`;
   - the φ = 0 ladder, `outputs/diagnostics/rep_dc_product_ladder_v0k_20260929/`;
   - the B result above.
   - ⚠ The 09-23 shelf **expires with a structure change**, so the φ = 0 numbers, not `hilda29l`'s,
     are the live ones.
5. **NPP:** accept 70 vs ~56 as a named tension (my recommendation after C), or build B2. B2 is
   only worth it if some structure makes a low NPP cheap, and none tested does.
6. **Koven comparison:** absolute land change is now in `land_sink_trajectory_full_20260929.csv`.
   CCX's fitted run is above Koven's upper 1σ in all three windows (+486 / +593 / +255 GtC).
7. **Carried over, unchanged:**
   - the arm-A Torch refit and φ = 0 adoption (now explicitly WAITING on 1–4);
   - the prereg P1 wording;
   - the `app/global.R` menu descriptors;
   - the untested `f_luc_wood` / `kz_deep_frac` findings;
   - memory housekeeping: listing `INDEX_ccx_phi.md` in `FaIRtoFrEDI/CLAUDE.md` (needs approval),
     root `MEMORY.md` over its soft budget, and `INDEX_ccx_app.md` near its limit.

## 5. Files (CCX `main`, all pushed; last commit `4cb0cb4` + this handoff)
- **New drivers** (`calibration/`):
  - `diag_q10_profile.R` (q10 pinned, 10 names re-fitted, reports loglik AND logpost);
  - `diag_land_sink_trajectory.R` (B1 / B2 / B2f / B3; env `LS_FERT`, `LS_Q10_PROFILE`, `LS_OUT_SUFFIX`);
  - `diag_passive_bomb_partition.R` (env `BP_PROFILES`; passive-tracer linearity gate);
  - `diag_carve_frozen_check.R` (the frozen +52 ppm check).
- **Extended drivers** (defaults unchanged):
  - `diag_tau_soil_slow_futures.R`: `TF_ROWS`, `TF_OUT_SUFFIX`, `profile_conv`.
  - `diag_tau_soil_slow_profile.R`: `TS_STOCK_FRAC` (carve-out proxy, needs `TS_FIXED_STOCK=1`),
    `TS_VALUES`.
  - `diag_npp0_scan_resfree.R`: `RS_RES_FREE`, `RS_FIX_PASSIVE`, `RS_PIN_Q10`. The pinned warm start
    takes the seasonal amplitudes from the scale-1 row.
  - `diag_soil_d14c_shi2020.R`: `SD_CARVE_TAGS` (in-model inert bulk), `SD_OUT_SUFFIX`.
- **Outputs** (`outputs/diagnostics/*_20260929.*`):
  - `tau_soil_slow_futures_fixedstock_ext`;
  - `tau_soil_slow_profile_fixedstock_stock{9479,8053,6627}` and `tau_soil_slow_futures_fixedstock_stock*`;
  - `q10_profile_fixedstock`;
  - `land_sink_trajectory_full` (+ `_annual.csv`);
  - `passive_bomb_partition`;
  - `soil_d14c_shi2020_carve`;
  - `npp0_scan_resfree_leaf-wood-soil_fast_fixpassive` and `…_q10pin1.10151`;
  - plus the `.stdout` files.
- **Code:** no model behavior changed. No file in `R/` or `src/` was touched.

## 6. Non-obvious state and traps
- **Nothing is running. No worktrees remain** besides `main`.
- ⚠ **A git worktree lacks the gitignored `data-raw/downloads/*`.** Symlink them in.
- ⚠ **Smoke outputs** were written in the worktrees and are not in `main`. Only full-run outputs
  were copied.
- **Identity numbers:**
  - v0k SSP5-8.5 2300 is **1388.28**;
  - the fixed-stock τ-500 control is **1387.8816**;
  - the q10 profile's control rescored its stored `$opt` to 7.9e-9.
- ⚠ **The q10 profile's LOGPOST is not comparable across rows** (q10 carries a prior, and the
  seasonal-amplitude priors move). Read `d_loglik`.
- ⚠ **The NPP scans' free-q10 costs are the escape.** Never quote "NPP 56 costs −8.8".
- **Directional traps:**
  - With the stock GROWING with τ, an older pool LOWERS 2300 CO₂.
  - With the stock FIXED, an older pool RAISES it.
  - A carve-out (smaller exchanging stock) RAISES it.
  - A re-fit roughly halves a frozen effect.
  - Always say which mode.
- **The literature-fertilization arm is FROZEN.** Its record cost was not computed. It is a
  mechanism test, not a candidate.
- `carbotopecomment.9.26.26.docx` is untracked and belongs to Marcus. Leave it alone.
- **Full test suite not re-run.** No `R/` code changed. The last suite log is
  `suite_20260929_postc5c5d4e.log`.
