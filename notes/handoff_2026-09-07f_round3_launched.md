# Handoff — 2026-09-07f. ROUND 3 LAUNCHED: Torch job **17150003** (`--array=0-45%10`), 30 parameters (+ `pump_hs_gcm2` with a literature prior), objective #10 + #11 (HS-surface rows), corrected gradient rows; out `multistart_20260907f_hilda30/`. Judged on prereg 09-07f R1–R11.
# **⛔ NOTHING ADOPTED. Canonical `ent26`. ⇒ NEXT: collect when `sacct -j 17150003` shows 46 COMPLETED, score against the prereg, then Marcus's ruling.**

Read: `notes/prereg_2026-09-07f_hs_pump_round3.md` (binding), CHANGELOG 2026-09-07f, then `handoff_2026-09-07e_*` and `_07d_*`.

## 1. Launch record
- Launch commit **4bef40e** (bundle); port targets **882de83** (`make_port_targets.R`, 30 par, struct hilda, cold −16654.0522,
  incumbent −2087.8649, new_basin −2133.6050); caption fix 44ede22 (not in the bundle; no code change).
- Local preflight ids 0/1/2: port rel ≤ 1.7e-14, 0.074–0.080 s/eval (`outputs/diagnostics/preflight_hilda30_id*.log`).
- Torch: setup gate PASSED (0.35 s/eval on the login node); preflight job **17149964** 8/8 COMPLETED, port rel ≤ 2.4e-12,
  **0.14 s/eval** (14 min per 6000-eval restart of a 180 min budget); production **17150003** submitted 21:1x, fairshare 0.18.
- Collect (when done):
```
ssh torch 'sacct -j 17150003 -X --format=JobID,State,ExitCode,Elapsed | tail -50'
rsync -a torch:/scratch/ms17839/CarbonCycleEmulator/calibration/output/multistart_20260907f_hilda30/ calibration/output/multistart_20260907f_hilda30/
CCX_MS_STRUCT=hilda CCX_MS_OUTDIR=calibration/output/multistart_20260907f_hilda30 Rscript calibration/collect_dispersed_multistart.R
```
  then a `diag_hilda30_predictions.R` modeled on `diag_hilda29_predictions.R` (add R9–R11: `hs_surf_*` rows, the
  prior-z of `pump_hs_gcm2`, unimodality in that coordinate).

## 2. What changed since round 2 (all in git)
09-07d: gradient rows' area bug fixed (every HILDA arm's DIC/ALK read 16 % low); HS end-member probed.
09-07e: the HS pump built in both cores; probed (+17 unrefitted; gate failed by its letter). 09-07f: literature prior
(median 22.9 gC m⁻² yr⁻¹, log-sd 0.6); objective #11 (HS-surface DIC SH 2163 / δ¹³C +1.31, σ_eff 24 / 0.31 —
WEAK by construction, recorded not arbitrating); new `hs_*` out columns (and the NaN-guard regression they caused,
fixed: `ccx_out_na_guard_cols()`); sweep fixes; `CCX_RUN_INPUTS` carries both products.

## 3. What to expect (so it is not read as a surprise)
R10 predicts the mode's `pump_hs_gcm2` ABOVE the prior median (the probe's optimum 60 is +1.6σ; the prior costs only
2.3 there against the δ¹³C row's +19) — read that as the `u_hs` = 38 flush / export-horizon question, not as a
defect. The #11 δ¹³C row will likely sit at z ≈ 2–2.5 (HS surface too heavy) — the surviving defect for the next
ruling (T-dependent air–sea fractionation at 2 °C, or HS ventilation). Round-2 checkpoints are refused by name
(29 ≠ 30); the new outdir cannot collide.

## 4. State / open
Test suite: 353 tests, the same 9 pre-existing failures (mode-file, mode-decode ×4, seas-lag-split ×2, enso-demean,
enso-split). Memory: `INDEX_diag` at 17.3 KB — SPLIT next session (hard 18); `INDEX_ccx_ocean_struct` 15.3 KB.
Owed: the pump/ALK solves' operator (conduit + HS limb); HS alkalinity (C8, ~−50 on the NH level); a
`diag_hilda30_predictions.R`.
