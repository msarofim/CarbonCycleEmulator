# PRE-REGISTRATION — the HILDA refit, ROUND 2: 29 parameters, objective #10 (level + contrasts, shape 4). Written 2026-09-07 BEFORE launch; binding.

**Ruling (Marcus, 2026-09-07):** after the round-1 result (`handoff_2026-09-07_hilda_refit_result.md`):
the profile scored as **(mean level, A−B, B−deep)**, three rows with declared sigmas (level 10.26 ‰ =
the deep row's `sd_w/√n_eff` convention; contrasts 2.29 / 4.04 ‰ = the 60° bootstrap), each a
**generalised-normal with shape 4** (cost |z|⁴/2: 1σ 0.5, 2σ 8, 3σ 40, 5σ 312) — a plausibility cost for
a bounded representation error, on these three rows only. Plus the two coupled fixes: **`h_hs` FITTED**
(box [20, 500]; a migrated ancestor starts at its own `h_ml`) and **the exchange floor lowered to 0.02**.

## What is fitted / declared
- Fitted (29): round 1's 28 + `h_hs`. `kz` bracket unchanged [1161.6, 27808] (bisected at `h_hs` = `h_ml`;
  not re-bisected — the deep is insensitive to `h_hs` at first order; R6 remains the test).
- Declared: `hs_frac` 0.16, `u_hs` 38, `tau_q` 538, `sst_hs` 2, `q_attach_from` 1, `kz_zscale` 253 (unchanged).
- Objective: #8 + **#10** (`LIK_USE_D14C_PROFILE_GNORM`, β 4); #9 OFF. Harness as round 1, out
  `multistart_20260907b_hilda29/`.

## The round-1 basins under #10 (scored before launch, `CHANGELOG 2026-09-07b`)
Winner: level row ≈ −290 (its +50 ‰ at 4.9σ); column: contrasts ≈ −125; both untenable. A basin inside
~2σ on all three rows is what the survey must find — the 09-06c arm (f 0.049, `hs_asx` 0.8) was inside 1σ
on all three at matched parameters, so such a region exists.

## Predictions (the run is judged on these)
| | prediction | falsified if |
|---|---|---|
| R1 | the mode keeps the structure: **f < 0.3**, `hs_asx_frac` in **[0.45, 0.85]** (within 2 sd of 0.653), **not at the 0.02 floor** | f → 1, or the factor at/near 0.02 ("no cold-box exchange"), or outside the band |
| R2 | level, A−B and B−deep all inside **2σ** (the shape makes 2σ the working edge) | any |z| > 2 |
| R3 | modern sink and both bomb curves within 2 log-units of `ent26`'s streams under #10 | worse by > 2 |
| R4 | the pump gradient rows (`ocean_grad_d13c`, `_dic`, `_alk`) within 5 each of `ent26`'s | > 5 worse on any — round 1's structural family was −22 / −6 / −6 |
| R5 | the likelihood beats `ent26` re-scored under #10 by MORE than the three profile rows' own gain | the whole gain is the rows |
| R6 | `kz` interior (> 5 % from each bound) | rails |
| R7 | `h_ml` returns toward the incumbent's range (**60–180 m**) once `h_hs` is free, and `h_hs` lands interior | `h_ml` at 37–47 or 184–200 again, or `h_hs` at a bound |
| R8 | the survey is UNIMODAL at the top: the best basin is reached from ≥ 10 starts and no second basin within 5 log-units differs in f by > 0.2 | two structurally different basins within 5 |

## SCORED 2026-09-07 (job 17110417, 46/46) — `calibration/diag_hilda29_predictions.R`
R1 PASS (f 0.009, factor 0.507), R2 PASS (−1.32 / +1.40 / +0.42), **R3 FAIL** (`d14c_NH` −4.1), **R4 FAIL**
(δ¹³C −27.6, DIC −6.1, ALK −7.1), **R5 FAIL** (+188 vs rows +231; rest −43), R6 PASS, **R7 FAIL** (`h_ml` 37),
R8 PASS (28 starts). The structure holds the Δ¹⁴C profile and breaks the DIC/δ¹³C gradients: the conduit's
HS water has no biology (export 57 GtC/yr cannot rebuild a gradient it flushes). CHANGELOG 2026-09-07c.

**RE-SCORED 2026-09-07d under the corrected gradient rows** (the rows had divided by `a_oc`, not `a_ls` — CHANGELOG 2026-09-07d):
R4 δ¹³C −27.56, DIC **−3.96**, ALK **−13.80** (still FAIL); R5 +183.5 vs rows +231.3, rest **−47.8** (FAIL). Every other verdict unchanged.
