# PRE-REGISTRATION — the HILDA-structure refit, 28 parameters, objective #9. Written 2026-09-06d BEFORE launch; binding.

**Ruling (Marcus, 2026-09-06):** on `prereg_2026-09-07_hilda_refit_design.md` §7 — (1) objective #9
ON, **60° block**; (2) `z_K`, `u_hs`, `tau_q` **declared** at HILDA's values with the 09-06d scan
caveats; (3) `h_hs` **declared** (follows `h_ml`); (4) `hs_asx_frac`'s observational value is a
**cross-check only**, not a prior; (5) *"check all the model code and launch … on Torch."*

## What is fitted, what is declared
- **Fitted (28):** the 26 of `ent26` + `kz_deep_frac` (logit box [0.005, 1], init 0.05) +
  `hs_asx_frac` (logit box [0.2, 2], init 1). `kz` re-bisected on the structure: **[1161.6, 27808.0]**
  (k = 3σ, `diag_kz_bracket_hilda36.R`), init 5683.6 (geometric center).
- **Declared (`ccx_apply_structure("hilda")`):** `hs_frac` 0.16 (measured 0.160), `u_hs` 38, `tau_q` 538,
  `sst_hs` 2, `q_attach_from` 1 (HILDA's, the observed contrast), `kz_zscale` 253; `h_hs` = `h_ml`.
- **Objective:** #8 (intermediate rows) + **#9 ON** (the profile as one MVN row, 60°). Baseline for
  comparison: `ent26` RE-SCORED under this objective, stream by stream — never its stored logpost.
- **Harness:** `run_dispersed_multistart.R`, `--array=0-45%10`, `cpu_short`, 4 h wall / 180 min
  budget, `CCX_MS_STRUCT=hilda`, out `calibration/output/multistart_20260907_hilda28/`. Ids 0–5 fixed
  (cold init; the two known basins migrated + seeded, ± the ENSO seedings); 6–45 dispersed at the
  measured basin separation. Port gate (a) at 28 parameters, the new brackets AND the structure label.

## Predictions (registered; the run is judged on these, NOT on the logpost)
| | prediction | falsified if |
|---|---|---|
| R1 | the mode keeps the structure: **f < 0.3** and **`hs_asx_frac` within 2 sd of 0.653** (sd = the fit's own marginal, ~0.10; and outside [0.45, 0.85] regardless) | f → 1 (uniform), or the factor lands outside the band — then `u_hs`/`h_hs` (declared, degenerate with it) are absorbing something and the cross-check has found it |
| R2 | the (A, B, deep) profile: all three levels AND the B − deep contrast inside 1σ | any |z| > 1 |
| R3 | modern sink (gate 7) and both bomb curves within 2 log-units each of `ent26`'s streams under the same objective | either worse by > 2 |
| R4 | the pump-δ¹³C gradient row recovers to within 5 of `ent26`'s | > 5 worse |
| R5 | the likelihood beats `ent26`'s (re-scored under #9) by MORE than the profile row's own gain | the whole gain is the row |
| R6 | `kz` lands INTERIOR: > 5 % of the box from either bound | rails |
| R7 (new) | `tau_q`-direction check: the fitted `hs_asx_frac` does NOT sit at a box bound (the scans showed the CO₂ rows reward weakening the conduit; with `tau_q` declared, the exchange factor is the only lever left) | at 0.2 or 2 |

## Known caveats going in
- The logit Jacobian pulls f toward the box center by ~1.7 log-units between 0.05 and 0.5 (stated in the table).
- The `kz` bracket is a support at fixed f; R6 tests it.
- A refit's port gate compares against targets measured on the Mac at THIS commit and structure.
- 09-06d audit: the R-path `ccx_run()` ocean inventory excluded HS/HD (fixed; the objective's C++ path never did).

## SCORED 2026-09-07 (job 17072999, 46/46 converged) — `calibration/diag_hilda28_predictions.R`
| | result | verdict |
|---|---|---|
| R1 | f **0.813**, `hs_asx_frac` **0.220** (−4.3 sd from 0.653; outside [0.45, 0.85]) | **FAIL** — and not the registered "u_hs absorbing" reading: the fit SHUT the exchange and flattened K |
| R2 | levels +3.6 / +3.2 / +3.1 (bootstrap sds), contrast +2.7 | **FAIL** |
| R3 | sink +1.3, `d14c_NH` **−2.8**, `d14c_SH` +0.2 | **FAIL** |
| R4 | pump-δ¹³C row −3.9 | PASS (winner); the structural family is at −21.9 |
| R5 | gain +22.9 vs the row's own +28.9 | **FAIL** — the whole gain is the row |
| R6 | `kz` 6847, 21 % into [1161.6, 27808] | PASS |
| R7 | 0.220 in [0.2, 2] | PASS by 2 % — effectively at the floor |

**Unregistered property that decided the run:** #9's 0.98 correlation prices a COMMON level shift
as one event (winner's +50 ‰: −19.5 vs −34.6 independent) and shape errors dearly (`ent26`: −48.5
vs −20.3). The ranking `ent26` vs winner flips with the objective. See CHANGELOG 2026-09-07.
