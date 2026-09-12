# Handoff — 2026-09-11 (b). **THE ROUND-6 "REFUTATION" WAS AN OBSERVABLE ARTEFACT. Ruled and shipped: concentration observables are ANNUAL MEANS over the box's mass AT THE TIME. Round 6b (the same arm, corrected objective) is RUNNING on Torch as job 17367892. Option B's four (+2) rulings are taken; its build is PAUSED at the R side until round 6b is read.**

> Self-contained. Read CHANGELOG 2026-09-11 (3) → (5) for every number. Memory: [[seasonal_box_observable_artefact]],
> [[ccx_option_b_rulings]], [[ccx_round6_result]] (retraction banner), [[ccx_hilda31p_adopted]].

## 1. WHAT THIS SESSION DID (from `handoff_2026-09-11_round6_closed_open_b.md`; commits `4d816b3` … this one)
| step | outcome |
|---|---|
| full suite first | 13,010/402: the pre-existing pair **+ `test-mode-struct-lint`** (three 09-11 files hand-built the base) → converted to `ccx_mode_base()`, logs identical |
| option B rulings 1–4 (Marcus) | `ml_hi` = HS box; Niño3.4 LIMB on `ml_lo` first; `ml_lo` fitted SST sines / `ml_hi` `seas_ml` + PINNED SST amp; `ent_seas_amp_SH` stays fitted |
| data task | poleward Holte shapes (57°+, 40°+, 40–57) + per-cap ERSST SST amps; every shipped row bit-identical |
| rulings 5–6 (Marcus) | GATE S re-cut to 57–90 °S for `ml_hi`; `h_hs` under the HS Holte prior as 09-08d |
| build, R side | `seas_ml = 2` geometry/entrainment/guard written, UNREACHABLE (parser refuses 2), 0/1 bit-exact — commit `5ed31cf` |
| ⛔ FOUND | the gradient row reads instant carbon / annual-mean mass → round 6's P7 was the artefact (09-11 (4)) |
| RULED (Marcus) | "annual mean of the concentration" → shipped `c0bf185`, priced −0.0957, files restamped, 15-test guard mutation-tested |
| round 6b | Torch **17367892**, 24 starts %24, port gate PASSED on the nodes, ~1.7 s/eval, 6 h wall |

## 2. THE FINDING, in one table (`calibration/diag_seasonal_box_observable_artefact.R`)
surface DIC at the GLODAP epoch, `hilda31p` → round 6: objective (instant/mean mass) **−156.9**; instant/instant +43.6;
annual mean **+0.9**. Gradient under the corrected read: 300 → **227** (target 233) — the recorded 385 was the
artefact; the δ¹³C half (−0.300 → +0.031) is the DEEP box the fit moved (`pump_grad` 255 → 280) to cancel it.
⇒ round 6's likelihood, P7, P2/P12 reads are properties of a fit to a corrupted objective. Same construction was in
`dg_gateG` and `ccx_model_hs_surface` — all three now go through `ccx_box_annual_conc()`.

## 3. FILES
- `R/likelihood.R`: `LIK_ANNUAL_MEAN_N`, `ccx_epoch_year_samples()`, `ccx_box_mass_at()`, `ccx_box_annual_conc()`;
  `ccx_model_ocean_gradient`/`ccx_model_hs_surface` rewritten. `calibration/lib_design_gates.R` `dg_gateG` final-year mean.
- NEW `calibration/restamp_mode_objective.R` (gates on the PRICED likelihood move; `objective_history` in the file).
  Restamped: `refit_20260910_hilda31_periodic/mode_fit_pumpN.rds` (−1480.5404 → **−1480.6361**) and the quarantined
  `hilda31` (−1478.6595 → −1479.5641, of which −0.811 is the 09-09w prior drift now brought current).
- NEW tests: `test-seasonal-box-observable.R` (15). Re-pinned: `test-enso-demean` (45.1848 / 43.8318 / 63.7234),
  `test-hs-surface-rows`, `test-gate-p7` (−0.300 → +0.031, 300 → 227 — the UNREFIT record; re-pin after 6b).
- `calibration/torch/port_targets.csv` regenerated at `seas_ml = 1` (incumbent −1634.68 → −1614.01); `multistart.sbatch`
  outdir `multistart_20260911_round6b_seasml1_sd1.0452`.
- Data: `data/obs_mld.rds` (+`seasonal_hs/so/40_57`), `data/obs_so_sst_seas_amp.rds` (+`caps`); builders generalised.
- `R/model.R` (paused B): `ccx_mld_shape(box)`, `ccx_seas_ml_ls_on/hs_on`, `ccx_seas_ml_hs_guard`, HS block time-varying.
- Notes: prereg §2a/2b (rulings), §2c (amendment). CHANGELOG 09-11 (3)(4)(5). Suite last: **13,028/406, 2 F / 1 E / 4 S** (the pair).

## 4. NEXT
1. **Collect round 6b** when 17367892 finishes (`collect_dispersed_multistart.R` on the outdir; requeue out-of-time
   tasks as round 2 the way round 6 was). Read it with `diag_round6_read.R` / `diag_round6_p7_gradient.R` (both take
   the outdir `D` — point them at 6b). **P7 on the 6b mode is the mechanism's verdict.** Re-pin `test-gate-p7.R`.
2. Then either promote (if P7 passes and it beats `hilda31p` on likelihood — Marcus's call) or resume option B:
   C++ twin of the R-side `seas_ml = 2`, parser 0/1/2, `h_hs` Holte prior (`data-raw/build_h_hs_prior.R`, HS readings
   mean 115 / max 268 → 09-08d idiom), pinned HS SST amp, tests, then the `ml_lo` limb.
3. `refit_20260910_hilda31_periodic/…_hess.rds` reference logpost is pre-restamp (provenance note only).

## 5. ⛔ WHAT I WOULD NOT DO
- Quote any round-6 (09-10) number as a property of the seasonal mixed layer.
- Ship a bundle while 17367892 runs. Re-run `make_port_targets.R` before any `seas_ml = 0` array.
- Add a `seas_ml = 2` parser value without the C++ twin and parity test in the same commit.

---
## POST-SCRIPT (same day, evening) — ROUND 6b IS IN AND ADOPTED; `hilda31s` IS CANONICAL
- Round 2 (17379055): 8 converged; mode **−1475.4579** (id 5, h_ml 64.8), second basin −1475.8811 (h_ml 49.8);
  18 dispersed reproduced. **Likelihood EQUAL to `hilda31p` (−0.61 / +0.23), priors +5.8, P7 PASS (−0.028 vs
  0.163, toward obs), P2 inside 2σ, P12 1.25×** — CHANGELOG 09-11 (7), [[ccx_round6b_result]].
- **Marcus: "Promote 1 and clean memory."** Promoted (5 gates) → Hessian (PD, cond 3.4e5, NOTHING step-unstable,
  h_ml ± 2.3 m) → repointed: `CCX_MODE_CANONICAL = "hilda31s"`, `hilda31p` registered as
  **`CCX_MODE_SEASML0_CONTROL`** — CHANGELOG 09-11 (8), commit `2fe2ec6`, [[ccx_hilda31s_adopted]].
  Suite 13,044/407, the pre-existing pair only.
- Memory: `INDEX_ccx` split → `INDEX_ccx_arch_modes.md` (registered in `FaIRtoFrEDI/CLAUDE.md` `7832847`);
  banners/retractions propagated; 0 orphans / 0 dangling. Over-soft indexes listed in CHANGELOG (8).
- ⚠ For the NEXT Torch array: the driver's reference set is still `hilda31p` / `hilda31` — add `hilda31s`
  (and regenerate `port_targets.csv` at the array's `seas_ml`) before launching. `make_bundle.sh` ships the
  new refit dir. Option B: P7′ is no longer its motivation; P1c + Fix B remain; build paused at the R side.
