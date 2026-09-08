# Handoff — 2026-09-08e. ROUND 4 CUT AT WAVE 2 (Marcus) after its interim answer; ROUND 5 LAUNCHED: the cold box's exchange factor under ITS observation — where does the modern sink go?
# **⛔ Canonical `ent26`. Every number GENERATED (`diag_hilda31_predictions.R` on the 10 wave-1 starts; `build_hs_asx_prior.R`). LAUNCH STATUS: §3.**

Read first: `notes/handoff_2026-09-08d_round4_scorecard_seasonal.md` (§6 the interim read), `notes/prereg_2026-09-08e_round5_hs_asx_prior.md`
(binding), CHANGELOG 2026-09-08e. Memory: [[ccx_round5_design]], [[ccx_round4_prepared]], [[ccx_hs_asx_obs_factor]].

## 1. Round 4, cut at 20 starts (Marcus: ten were enough for the conclusion; cancel to start sooner)
Wave 1 (ids 0–9, all CONVERGED 130–149 min): `u_hs` **15.0–15.4 m/yr** (28 Sv; z −1.48 BELOW its prior), likelihood
**−1433.3 / −1432.8** (round 3 −1438.64), export 61 gC m⁻² yr⁻¹ (3.5 GtC/yr, z +1.63), ratio 4.0; `h_ml` 50–58 (leading
family) / 156–176 (1.4 behind); HS δ¹³C 2.46 → 2.35. **The sink moved: `hs_asx_frac` 0.82 → 1.835** (box top 2.0; measured
0.653), `kz` 9047 → 15058, `kz_deep_frac` 0.025 → 0.0067 (K_deep 101), sink 3.03 → 2.96; rows: `d14c_NH` +2.9,
`d13c_level_MLO` +2.3, `ocean_grad_d13c` +2.1, `co2_icecore` −1.9, `gcb_ocean_sink` −1.6. Prereg 09-08d: R2–R6 PASS, **R1 FAIL
the other way, R7 (10 starts) and R8 FAIL, R10 FAIL** — and the mechanical "observation holds" reading does not apply.
Pending 26 tasks cancelled 10:50 EDT (`scancel --state=PENDING 17185969`). **Ids 10–19 finish ~12:40 and close the record at
20 starts** — collect with `rsync … multistart_20260908d_hilda31/` then `Rscript calibration/diag_hilda31_predictions.R`
(it prints PARTIAL: 20 of 46; R7's power is reduced — say so in the CHANGELOG line that closes round 4).

## 2. Round 5 (prereg 09-08e)
`hs_asx_frac` keeps its box, gets lognormal(0.653, 0.15) — the 0.15 is a **JUDGEMENT** (2.8× the measured component spread
0.053; the hemispheric 0.44 is representation error and would let 1.83 stand). 1.83 sits at z +6.9. `u_hs` and `h_ml` keep
round 4's priors; 31 parameters. **THE question: with both the flush and the exchange honest, where does the sink go?**
Priced routes: `u_hs` back up (2.6 log-units — PREDICTED), `k_w` (2× costs 1.5) / `kz`, the land (gate 7's land row), or no
route (likelihood −10 ⇒ the missing LS ventilation limb, proven by exhaustion). P1 `hs_asx_frac` ≤ 0.88; P2 `u_hs` ≥ 33;
P3 ratio 3.6–4.3; P4 likelihood within 5 of −1433.3; P5 K_deep ≥ 150; P6 `h_ml` 45–100; P7 unimodal among 18 dispersed
(weaker power, stated); P8 sink/bomb rows within 2; P9 recorded. Array **24 at `%24`**, one wave.

## 3. LAUNCH STATUS
**LAUNCHED 2026-09-08 11:37 EDT: Torch job 17194179** (`sbatch --array=0-23%24 calibration/torch/multistart.sbatch` at launch commit **d65b299**, port targets committed after it). Setup gate PASSED (0.44 s/eval login node); preflight 17193798 **8/8 port VERIFIED rel ≤ 2.4e-12** (ids 0–5 fixed, 15/23 dispersed), compute nodes 0.14–0.30 s/eval. 20 of 24 started at once beside round 4's last wave (32-CPU QoS cap; 4 pend until ~12:40). Suite before launch: 2147 pass / 9 fail, the same nine pre-existing. Expect the array to drain by ~14:00–15:00 EDT; collect and score per the handoff §4.

## 3b. RESULT (14:30 EDT) — see CHANGELOG 2026-09-08e (result) and [[ccx_round5_result]]
24/24 CONVERGED. Winner id 3 (13 of 24): **`u_hs` 24.2 m/yr (44 Sv, z +0.42), `hs_asx_frac` 0.780 (z +1.2), `k_w` 1661 (+31 %,
z +0.27), `h_ml` 49.2, `h_hs` 401, `kz` 11,698, K_deep 129, export 91 (z +2.3), ratio 3.77; likelihood −1439.4 (round 3 −1438.6;
common rows −1429.0 vs −1427.6)**; second family `h_ml` 153–176 at −1485.5 (7 behind, `u_hs` 20.5). **P2 FAILED: the flush did
not return to 38 — the 70 Sv was never a sink requirement; the sink went to `k_w`, inside its prior.** Gates as round 3; Q 2.44σ.
⚠ **Round 4's wave 2 was killed by my re-ship** (`never_reship_mid_array`); its record is 10 starts.
**Owed rulings:** (1) adopt the round-5 winner as the HILDA canonical? (2) round 6 = the seasonal mixed layer (option B) or the
2 °C cold-box fractionation (gate Q + HS δ¹³C +2.41)? (3) the export's +2.3σ — a wider export prior (the 400 m-flux meaning) or
leave it as the model's statement?

## 4. Collect and score
```
ssh torch 'sacct -j <JOBID> -X --format=JobID,State,ExitCode,Elapsed | tail -30'
rsync -a torch:/scratch/ms17839/CarbonCycleEmulator/calibration/output/multistart_20260908e_hilda31_asx/ calibration/output/multistart_20260908e_hilda31_asx/
CCX_MS_STRUCT=hilda CCX_MS_OUTDIR=calibration/output/multistart_20260908e_hilda31_asx Rscript calibration/collect_dispersed_multistart.R
```
Scorer: copy `diag_hilda31_predictions.R` → `diag_hilda31asx_predictions.R` with `R4_DIR` → the new outdir, `R4_N_EXPECTED` 24,
the round-4 leading start (id 3, lik −1433.27) as the comparison, and P1–P9's verdicts (the route named by which of
`u_hs` / `k_w` / `kz` / `beta_max` moved > 30 % from round 4). Then the CHANGELOG line, the memory body, and the ruling.
**Still owed:** the seasonal mixed layer (option B, [[ccx_seasonal_h_ml_option]]) as round 6; a SOURCED Martin exponent.
