# Handoff — 2026-09-14 (a). **PRE-LAUNCH REVIEW DONE (no run-class bug; one latent closure defect guarded; kit hardened), THE 31-vs-33 INTERVAL CLOSED BY CONTRACT (suite green but for the known pair + error), the bundle is ON TORCH at `cf1e380`/`11e2b7a`, the PREFLIGHT `--array=0-23` is SUBMITTED (job 17769390). THE WAVE IS NOT — it waits on the `gamma_eq` prior ruling.**

> Self-contained. CHANGELOG 09-14 (a); memory [[ccx_eq_cell_prelaunch_review]] (in `INDEX_ccx_ocean_circ`; `INDEX_ccx` live line updated).
> Previous: `handoff_2026-09-13i_eq_cell_array_launch_commit.md`; prereg `notes/prereg_2026-09-13g_equatorial_cell_build.md`.

## 1. State on Torch
- `/scratch/ms17839/CarbonCycleEmulator` = the bundle from `11e2b7a` (port_targets stamp `cf1e380`, n_par 32, struct `hilda_eq`, seas_ml 1, the pin). ControlMaster was live this session; Claude shipped + submitted the preflight on Marcus's instruction ("before launching").
- **Preflight job 17769390**, ids 0–23, `--time=00:15:00`. READ IT before the wave: every task must print `port VERIFIED` and `LAUNCHABLE`; take the worst s/eval and check it against the sbatch header's 108-min worst case (0.19–0.22 s/eval on the Mac; Torch has run 2–5× slower per eval).
- **The wave (NOT submitted):**
  `cd /scratch/ms17839/CarbonCycleEmulator && CCX_MS_STRUCT=hilda_eq CCX_MS_PIN=ent_seas_amp_SH=0 sbatch --array=0-23%24 calibration/torch/multistart.sbatch`
  Outdir on Torch: `calibration/output/multistart_20260913_eqcell_hilda_eq_seasml1_pin_ent_seas_amp_SH=0_sd1.0452`.

## 2. The open ruling: `gamma_eq`'s prior (CHANGELOG 09-14 (a) §gamma_eq)
Shipped = FLAT on [0, 2] (logit box, `dunif`). Recommendation: KEEP for this array — PE7 ("fitted γ_eq in [0.4, 1.1]") is the array's measurement of γ and an observation prior centred there would pass it by construction. Candidate production prior once PE7 is read: lognormal from the product, centre 0.697, log-sd 0.401 (= [0.467, 1.042] from 14–25 Sv/index over W0 24–30 Sv; both from `obs_eq_cell.rds$w0_prior`). If Marcus rules the observation prior NOW: change the table entry (read it from the product), add the tie in `test-eq-cell.R`, regenerate `port_targets.csv`, re-bundle, re-preflight; PE7 becomes a check, not a test.

## 3. What changed today (all committed: `cf1e380`, `11e2b7a`)
- **Contract, not waiting**: `CCX_PARAM_ABSENT_OK`, `ccx_mode_carries_build()`, `ccx_mode_start()` (`R/calibrate.R` after `.CCX_PARAM_ORDER`); consumers `ccx_load_mode` (migrates, does NOT seed), `ccx_check_mode_decode`, `app/global.R`, six test files; `test-param-absent-ok.R` keeps the list LIVE (fails the day every registered file carries a listed name). The app, scorecard and diags that go through `ccx_load_mode()` are BACK; `ccx_require_param_set()` (the Hessian-class diags) still refuses a migrated file, deliberately.
- **Model**: `ccx_prepare()` refuses cell + (`w_up` | `w_out_*` | `q_conv` > 0) — D1 closes only the cell's own limbs; the older ML-touching limbs leak `w·a_eq·conc` (0.192 GtC/yr at 1 m/yr, measured). R deriv NULL pair → 0 (C++ contract). Comment 63 → 57.7 m/yr.
- **Kit**: sbatch exits 1 without `CCX_MS_STRUCT`; `unset CCX_MS_ID`; preflight = ids 0–23; banner prints the `hilda_eq` block; CSV re-measured at HEAD (bit-identical).
- **Suite**: 2957 / 2 F / 1 E (GATE Q pair, 08-30 arm error). Yesterday's two fixture edits "flagged for veto" are superseded by `ccx_mode_start()`.

## 4. Review items recorded, not changed (CHANGELOG 09-14 (a))
Pump `kappa` on `a_ls` under D1 (unstated choice; PE5 confound); substep bound at the summer ML extreme 0.5 % under (winter dominates, cell bound adds 10.4); B1's HS weighting vs the ice-masked product; γ = 0 unreachable under logit (don't read PE2/N1 off a railed γ). sbatch header still describes ids 3–5 as "the 25-parameter space" (stale prose).

## 5. After the wave
`CCX_MS_PIN=ent_seas_amp_SH=0 CCX_MS_OUTDIR=<dir> Rscript calibration/collect_dispersed_multistart.R` → `promote_multistart_mode.R --outdir=… --dest=refit_20260914_hilda30e_eqcell_pin_ent0` → `recompute_hessian.R --update` → repoint `R/paths.R` (the free-parent question is a RULING: no free `hilda_eq` parent exists; `test-mode-file` now accepts a parent that lacks only `CCX_PARAM_ABSENT_OK`) → `make_bundle.sh` dir → `port_targets.csv` → then PE2–PE5, PE7–PE8; PE9 once. Owed after: M, pin-vs-retire, option K, `OCEAN_AREA_*` provenance, the `diag_*.R` on `ccx_require_param_set`.

## 6. UPDATE 09-14 (b) — LAUNCHED
Marcus ruled the `gamma_eq` prior FLAT. Preflight 17769390: 24/24 LAUNCHABLE, port VERIFIED rel ≤ 2.2e-10, 0.43 / 0.52 / 0.94 s/eval.
**Wave = Torch job 17769990**, `--array=0-23%24`, 24/24 running from 06:58 EDT, tree `11e2b7a`, outdir
`calibration/output/multistart_20260913_eqcell_hilda_eq_seasml1_pin_ent_seas_amp_SH=0_sd1.0452`. Expect ~6 h; C′'s yield at this
budget was 4 CONVERGED of 24 — a round 2 resumes the best ids from `summary.csv`, never the whole array. Then §5.

## 7. UPDATE 09-14 (c) — the array is READ; the second build is SCOPED (`faddcfd`)
Results committed under the outdir (+ Torch logs). Best −1450.518 (id 0 converged; 10 tasks), `w_eq` **10.72 Sv (z −5.4, PE8 FAIL)**,
`gamma_eq` 0.600, PE1 on the vector 1.12× obs. `diag_eq_cell_levers.R`: at 27 Sv the excess (+133) is the T-term (+124/+159) — the
ML's 18 °C DIC at 27 °C; T-term off ⇒ +61 (z +0.8). **Rulings taken: start from HEAD; `hilda30e` NOT promoted; own label.**
**Prereg** `notes/prereg_2026-09-14c_equatorial_cell_tdic.md` (scoping tier): T1 = a TROPICAL SURFACE BOX `tr` the loop closes through;
**R1–R4 owed** (T1 vs alternatives; the latitude bound; `seas_ml` on `tr`; `q_tr` fitted or structural). PT1–PT6 registered (PT3: γ
drops to ~0.3, BELOW the observed bracket). Torch tree is still the launch bundle (fine; the next build re-bundles).
