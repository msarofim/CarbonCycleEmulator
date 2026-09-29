# Handoff 2026-09-29 (c): the NPP₀ residence rescan and the PASSIVE-SOIL arc

> Launch from `FaIRtoFrEDI/`, then `change_directory` here (CLAUDE.md). ⛔ **Never use a bare `cd` in a
> Bash call**; use `git -C` or absolute paths.
> **Read first:** this file, then CHANGELOG **2026-09-29 (m)–(s)**, then the memory via **`INDEX_ccx_phi.md`**
> → `ccx_npp_is_a_residence_ridge` (it carries the whole arc, m through s).
> The previous handoff is `notes/handoff_2026-09-29_npp_repdc.md`; its open items not closed here are
> carried in §4.

---

## 1. What we were working on
Item 1 of the previous handoff: **what holds the model's modern NPP at 70** (against ~56 from the
verified totals), and whether B2 (a fitted NPP₀) is worth building. The residence-time rescan
answered that, then opened a second question: **how big and how old the passive soil pool is**, and
what that choice does to the 2300 futures. Every run is at arm A (`hilda_csl3v0ka`) at v0k basin 1,
with the 11 names from the 09-29 (k) scan re-optimised.

## 2. Decisions (Marcus) and results, in order
1. **NPP₀ rescan with the residence times free** (Marcus: free alongside the 11; no priors; unbounded).
   CHANGELOG (m).
   - The ×0.75 cost goes −125 → ≤ −18, and `d14c_NH` −70 → −4. The residence-fixed control gains
     ≤ 5, so the gain is the residence times.
   - ⇒ **The bomb record pins the carbon in DECADAL pools, not NPP.** It is a ridge: different scales
     buy it with different pools.
   - The profile is noisy (±10) and 3 of 7 rows hit maxit, so it does not locate the NPP optimum.
   - ⛔ **Every fit pushed `tau_soil_slow` to 1000–1800 yr**, a passive stock of 2.6–5.6k GtC.
2. **`tau_soil_slow`-only profile** (default mode: `litter_slow_frac` fixed, so the stock grows with τ).
   CHANGELOG (n).
   - Likelihood +4.8 / +6.1 / +5.5 at 750 / 1000 / 1500 yr, and flat within ~6 from 500 to ~3000 yr.
   - The big frozen cost (CO₂ LEVEL via `q10` × stock) is absorbed by `luc_scale` ↓, `kz` ↓ and
     `fert_k` ↑.
3. **Futures at 1000 / 1500 yr (default mode).** CHANGELOG (o).
   - SSP5-8.5 2300 −32 / −40 ppm; land uptake +98 / +133 GtC.
   - ⚠ Land ×PI falls 1.63 → 1.29 only because the PI stock grows, so the **Koven multiple benchmark
     is stock-dependent**.
4. **Swap decomposition.** CHANGELOG (p). It is order-robust.
   - **τ alone (retention)** gives −48 to −70 ppm; the fertilisation pair gives +9 to +21.
   - `fert_k` alone gives +28 to +35: a HIGHER `fert_k` WEAKENS fertilisation, so (o)'s first guess
     had the wrong sign.
5. **Literature (subagent)** → `notes/lit_2026-09-29_passive_soil_stock.md`. CHANGELOG (q).
   - The evidence favours a passive stock of ~1500 GtC (1200–2000), not 3–4.5k. AR6 Fig. 5.12: soils
     1700 + permafrost 1200.
   - ⚠ Naegler & Levin 2006's "2200 PgC" is their MODEL's setting, not an observation.
6. **`R/model.R` comment fixed** (Marcus: "fix the model.R comment"; `06aec68`). Only the bomb-¹⁴C
   inventories are observational; the pool sizes are checked against AR6 Fig. 5.12 and the ¹⁴C note.
7. **T1, age vs stock** (`TS_FIXED_STOCK=1`: `litter_slow_frac` = 0.05·500/τ). CHANGELOG (r).
   - **The +5.7 VANISHES**: the profile peaks at the default. ⇒ The record was buying STOCK, which the
     inventories reject, so **the default stands**.
   - ⛔ **But at fixed stock an OLDER pool (less input → less retention) RAISES SSP5-8.5 2300 by
     +68 / +112 ppm** (τ 1000 / 1500) for only −1.2 / −2.4. **A near-free futures lever.**
8. **T2, soil Δ¹⁴C vs Shi 2020.** CHANGELOG (s). The analytic steady-state gate PASSES (0.09 ‰).
   - τ 500 gives a yr-2000 bulk of −19 ‰ against Shi's **−244 ± 48** (z +4.7). It is matched only at
     τ ≈ 2000–5000, where the atmosphere charges −4 to −17.
   - ⛔ That holds only if there is little radiocarbon-free soil carbon.
   - **The aOC-robust yardsticks have NO POWER** (errors propagated):
     - Copard-adjusted bulk: −75 ‰, ±1σ −215..+127.
     - Σ C·F¹⁴C: 1372 ± 398 GtC.
   - ⇒ The verdict rests on the Shi/He vs Copard dispute.
9. **Housekeeping:** the three old worktrees and the merged subagent branch are removed. Every run
   here came from a frozen worktree, and each was removed after archiving.

## 3. Files (CCX `main`, all pushed; last commit `9338db2` + this handoff)
- **Drivers** (all in `calibration/`, all no-RNG screens, all run from frozen worktrees):
  - `diag_npp0_scan_resfree.R` (m).
  - `diag_tau_soil_slow_profile.R`. Env `TS_FIXED_STOCK=1` gives the fixed-stock mode; the per-row
    base overrides are recorded as `$over` in the rds.
  - `diag_tau_soil_slow_futures.R`. Env `TF_PROFILE_TAG` picks the profile; it rebuilds from `$over`.
  - `diag_tau_soil_slow_swap.R` (p).
  - `diag_soil_d14c_shi2020.R` (s). It reads soil pools via `ccx_run(edge_fn=)` and has an analytic
    steady-state gate.
- **Outputs** (`outputs/diagnostics/`, `*_20260929.*`):
  - `npp0_scan_resfree`;
  - `tau_soil_slow_profile{,_fixedstock}`;
  - `tau_soil_slow_futures{,_fixedstock}`;
  - `tau_soil_slow_swap`;
  - `soil_d14c_shi2020`;
  - plus the smoke logs.
- **Code:** only the `R/model.R` comment (~line 1232). **No model behaviour changed.**
- **Notes:** `lit_2026-09-29_passive_soil_stock.md` (per-source access level: FULL / ABS / SNIP; He 2016
  is abstract-only; Scharlemann, Trumbore and Ciais are search-summary only).

## 4. Open questions / next steps (all Marcus's)
1. **τ_slow at fixed stock is an uncited [VERIFY]-class design default** (CLAUDE.md hard rule 2) that
   moves SSP5-8.5 2300 by ~100 ppm. Options:
   - (a) a prior from Shi's bulk, with σ inflated to span the aOC dispute;
   - (b) keep 500 and document the sensitivity;
   - (c) free it with a prior in the next refit label.
2. **Futures at τ 2000–3000 (fixed stock)**, to see how far the future moves if soil ¹⁴C is taken at
   face value. Not run.
3. **Structure:** is a depth-resolved or inert soil pool in scope for a pedagogical model
   ([[ccx_pedagogical_not_emulator]])? Without one, T2 cannot be made like-for-like. Also: the bulk is
   sensitive to the fast/slow split (soil_fast at +138 ‰ in yr 2000).
4. **NPP:** B2 is still not row-pulled (at σ 7.76, 74 → 56 is worth ~+2.7). A lower NPP is only cheap
   via a residence structure the data cannot check. Accepting 70 vs ~56 as a named tension looks
   like the defensible default, but that is Marcus's call.
5. **Koven benchmark:** re-express the 09-29 (g) comparison as absolute ΔC_land at a matched PI stock
   before quoting any "inside the band".
6. **Carried over from the previous handoff:**
   - the arm-A Torch refit and φ = 0 adoption (Hessian, registration, app repoint);
   - `rep_dC` at φ = 0 vs the R2 ruling;
   - the prereg P1 wording;
   - the `app/global.R` menu descriptors;
   - the untested `f_luc_wood` / `kz_deep_frac` findings.

## 5. Non-obvious state and traps
- **Nothing is running. No worktrees remain** besides `main`.
- ⚠ **A git worktree lacks the gitignored `data-raw/downloads/*`.** Symlink them in (the drivers
  above assume it), or the nuclear ¹⁴C source silently zeroes.
- **Identity numbers:**
  - v0k SSP5-8.5 2300 is **1388.28 ppm** (the stored mode, through the futures driver);
  - the τ-500 rebalanced control is 1387.9;
  - the (k) scale-1 optimum reproduces to 4e-7 as a warm start.
- **Profile rds compatibility:** the old default-mode profile rds has no `$over`; the futures and T2
  drivers fall back to τ-only. Keep that fallback if either is edited.
- **The frozen costs in (n)/(r) are huge** (−500 to −2100) and are absorbed by the rebalance. Never quote
  a frozen cost as the record's verdict on τ.
- **Directional traps:**
  - With the stock GROWING with τ, longer τ LOWERS 2300 CO₂.
  - With the stock FIXED, longer τ RAISES it.
  - Always say which mode.
- **Memory:** the whole arc is in `ccx_npp_is_a_residence_ridge.md` (pointer line in `INDEX_ccx_phi.md`,
  3.8 KB).
  - Still pending from the last handoff: listing `INDEX_ccx_phi.md` in `FaIRtoFrEDI/CLAUDE.md`
    (Marcus's approval);
  - root `MEMORY.md` over its soft budget;
  - `INDEX_ccx_app.md` 68 B from its limit.
- **Full test suite not re-run this session.** The only code change is a comment, and the new
  drivers are diagnostics outside `R/`. The last full-suite log is still `suite_20260929_postc5c5d4e.log`.
- `carbotopecomment.9.26.26.docx` is untracked and belongs to Marcus. Leave it alone.
