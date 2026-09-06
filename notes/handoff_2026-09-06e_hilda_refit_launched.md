# Handoff — 2026-09-06e. THE HILDA REFIT IS RUNNING ON TORCH: job `17072999`, 28 parameters, objective #9 ON.
# **⛔ NOTHING ADOPTED YET. `CCX_MODE_CANONICAL` is still `ent26` (26 names) — two mode-file tests FAIL on purpose until this refit's mode is promoted.**
# **⇒ NEXT: collect when the array drains (~4 h/task, 46 tasks at %10 ⇒ ~20 h wall), score R1–R7, then Marcus's adoption call.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, `main`, commits `ce3d20b` (the prep),
`7ca9d01` (targets), + the handoff commit. Read first: `notes/prereg_2026-09-07_hilda_refit_run.md`
(the binding predictions), CHANGELOG 09-06d (ii), `handoff_2026-09-06d_...` for the observation pin.

## 1. WHAT IS RUNNING
Torch `cpu_short`, `--array=0-45%10`, 4 h wall / 180 min budget, out
`/scratch/ms17839/CarbonCycleEmulator/calibration/output/multistart_20260907_hilda28/`, logs
`logs/ccx_multistart_17072999_*.{out,err}`. Preflight `17072646` 8/8 green (port rel ≤ 7e-13;
0.15–0.21 s/eval). Fixed ids 0–5 (cold; the two known basins migrated + SEEDED — `kz_deep_frac`
seeded 0.05 because the migrated 1 is the box bound; `hs_asx_frac` migrates to 1 and encodes),
6–45 dispersed at sd 1.0452 (pool excludes the two new names, migrated in both references).
Structure: `CCX_MS_STRUCT=hilda` ⇒ `CCX_STRUCT_HILDA` (hs_frac 0.16, u_hs 38, tau_q 538, sst_hs 2,
q_attach_from 1, kz_zscale 253); fitted: the 26 + `kz_deep_frac` [0.005, 1] + `hs_asx_frac` [0.2, 2];
`kz` [1161.6, 27808.0]. Objective #8 + #9 (60° block).

## 2. HOW TO COLLECT AND JUDGE
```
ssh torch 'sacct -j 17072999 -X --format=JobID,State,ExitCode,Elapsed | tail -50'
rsync -a torch:/scratch/ms17839/CarbonCycleEmulator/calibration/output/multistart_20260907_hilda28/ \
      ~/Documents/2026/CodeProjects/CarbonCycleEmulator/calibration/output/multistart_20260907_hilda28/
CCX_MS_STRUCT=hilda CCX_MS_OUTDIR=calibration/output/multistart_20260907_hilda28 Rscript calibration/collect_dispersed_multistart.R
```
⚠ The collector may not know `struct`; check it re-scores with `ccx_apply_structure()` before
trusting any logpost it prints. Baseline = `ent26` RE-SCORED under #9 with the structure OFF —
stream by stream (dg_streams), never a stored logpost. Then R1–R7 of the run prereg; R1's
`hs_asx_frac` band is the cross-check against 0.653. Expect most tasks "OUT OF TIME" after round
one (README: that is not a failure); round 2 = ids 0–5 + the best dispersed ids.

## 3. ⚠ ON THE RECORD
* Audit bug fixed before launch: `ccx_run()` (R path) excluded HS/HD from `ocean_C`/`ocean_C14`;
  the objective's C++ path never did. Every R-path structure-on diagnostic before `ce3d20b` under-
  counted the ocean stock.
* The two new parameters are `logit` boxes with a uniform prior on the natural scale (the design
  said "log scale"); Jacobian pull ~1.7 log-units between f 0.05 and 0.5. Stated in the table.
* The column-era `kz` guards (lo ≥ 3500, hi < 10686, init = mean) were retired in
  `test-likelihood.R` and restated on the structure; on the structure kz = 10686 is +0.9σ on the
  deep — the runaway is a statement about f·kz now.
* Left failing: `test-mode-file.R` "carries THIS BUILD's parameter set" and `test-mode-decode.R`'s
  fixture (26-name canonical mode, 28-name build). The 22→25 precedent; they pass at promotion.
* `setup_torch.sh` no longer carries a cold-target literal; it reads the shipped CSV.

## 4. NON-OBVIOUS STATE
* Local: nothing running. `calibration/output/multistart_20260907_hilda28/` exists locally from the
  preflights (empty of results). Downloads for the obs pin are gitignored (HadISST 465 MB unzipped).
* Torch bundle = `ce3d20b` + targets `7ca9d01`; old outputs (`multistart_20260903_ent26` etc.) still
  there. `/scratch/ms17839/Rlibs/4.5` has Rcpp 1.1.0.
* Memory: `INDEX_ccx_ocean_struct` ~16.3 KB (over soft; split next), root ~12.5 KB.
