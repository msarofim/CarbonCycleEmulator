# Handoff — 2026-09-11. **ROUND 6 IS CLOSED (refuted as built on GATE P7, mechanism retained); `hilda31p` IS CANONICAL; OPTION B — LATITUDE STRUCTURE FOR THE MIXED LAYER — IS OPEN, WITH ITS PREREG WRITTEN AND FOUR RULINGS OWED BEFORE A LINE OF CODE.**

> Read first: **CHANGELOG 2026-09-11 (2)** back to **2026-09-10 (6)**; `notes/prereg_2026-09-11_option_b_ml_box.md`.
> Memory: [[ccx_round6_result]], [[ccx_hilda31p_adopted]], [[ccx_fixB_reservoir_priced]],
> [[penalty_must_lose_to_the_start]], [[ccx_seas_ml_p8_wall_blocks_reference_set]].

## 1. STATE OF THE TREE (`CarbonCycleEmulator/main`, clean, no remote; last commit `9eb5770`)
- **Canonical `hilda31p`** (`refit_20260910_hilda31_periodic/mode_fit_pumpN.rds`): 31 par, hilda, periodic spinup,
  `seas_ml` 0, `spinup` "periodic" recorded, −1480.5404, Hessian PD. `hilda31` quarantined
  (`CCX_MODE_HILDA31_QUARANTINED`). `test-mode-file.R` compares FREE arms RE-SCORED on today's objective (option 2).
- **Round 6 outputs**: `calibration/output/multistart_20260910_round6_seasml1_sd1.0452/` — 24 starts, both collector
  logs, `round6_read.log`, `round6_p7.log`, SLURM logs; dead first-run files under `dead_20260910_penalty_plateau/`
  on Torch only. Mode −1492.1591 (id 4). **NOT promoted; not to be.**
- **GATE P7** in the ledger; `test-gate-p7.R` green (18 expectations). `seas_ml` built, gated, default-off.
- **Driver** (`run_dispersed_multistart.R`): REQUIRES `CCX_MS_STRUCT` + `CCX_MS_SEAS_ML`; penalty derived from the start
  (10×|start|); dead-task gate; references `hilda31p` / `hilda31`; `CCX_MS_SPREAD` explicit in the sbatch (1.0452).
  `port_targets.csv` is at **`seas_ml = 1`** — ⚠ regenerate at 0 (`CCX_MS_STRUCT=hilda CCX_MS_SEAS_ML=0`) before any
  `seas_ml = 0` array, or the port gate refuses (correctly).
- **Torch**: nothing queued. Main tree `/scratch/ms17839/CarbonCycleEmulator` has the fixed driver; a second tree
  `/scratch/ms17839/CarbonCycleEmulator_r6fix` was used for the requeue and can be deleted.
- **Suite**: last full run 12,990 / 2 / 1 / 4 (pre-existing: alpha-as GATE Q, seas-lag-split migration) — BEFORE
  `test-gate-p7.R`, the option-2 rewrite and the P7 ledger entry; those files pass alone. ⚠ Re-run the full suite
  before the first B commit.

## 2. THE FOUR RULINGS OWED (prereg §2) — ask, do not assume
1. Is `ml_hi` the **existing HS box** (cheapest; it has its own ALK, T, pump) or a **new** box?
2. A tropical **box** or a tropical **limb on `ml_lo`** (T-A0 sized ~26 Sv, modulated by Niño3.4)?
3. Which seasonal driver each box gets (SST amplitude per box; does the sine path retire?).
4. Does `ent_seas_amp_SH` survive the build?
Plus one DATA task: a **poleward-masked** Holte MLD climatology for `ml_hi` (`data-raw/build_mld_targets.R` builds
the hemispheric one).

## 3. WHAT B MUST SATISFY (prereg §3; write the sign and bound BEFORE any run)
**P7′** (`seas_ml = 1` on `ml_hi` passes GATE P7 — if not, the formulation is wrong, STOP), **PB1** (solubility-only
ENSO r flips positive at a physical modulation; `gamma_enso_*` |sum| 0.356 → < 0.18), **PB2** (two SH regimes,
GATE S still passes on `ml_hi`), **PB3** (P2 inside 2σ; `ent` ≤ 1.5× centre or retired), **PB4** (Δ¹⁴C rows
< 1 log-unit each), **PB5** (no loss on likelihood vs `hilda31p`), **PB6** (CO₂ seasonal rows < 1).

## 4. NON-OBVIOUS STATE
- **`seas_ml = 1` has a HARD WALL at h_ml ≈ 75 m** (P8 guard → −Inf). Any B refit that switches it on needs
  feasible references (the 09-10 set is) and the derived penalty (in place).
- **Every stored logpost before 09-10 is in another objective's units.** Compare on likelihood, or re-score.
- **`rep_dC` +3.17** — untouched by every ocean option; not B's job; do not let it hide.
- **Root `MEMORY.md` is 13.2 KB of CONTENT** (measure with the one-liner in `memory_budget_is_content_not_file`,
  NOT `wc -c`). `INDEX_ccx` 15.7 KB, `INDEX_slr` 17.6 KB, `INDEX_cmp` 17.2 KB, `INDEX_cmp_pulse` 17.1 KB — over soft,
  under hard; a split is owed for the three near 17 KB when convenient.

## 5. ⛔ WHAT I WOULD NOT DO
- Promote the round-6 mode, or relabel it as anything but "refuted on P7, retained".
- Build B without the four rulings; build `ml_hi` as a fresh box before checking whether the HS box IS it.
- Run any array without `CCX_MS_SEAS_ML` matching `port_targets.csv`; ship a bundle while `squeue` is non-empty.
- Read `hilda31p` unrefitted at `seas_ml = 1` (−1634.68) as a verdict on anything.
