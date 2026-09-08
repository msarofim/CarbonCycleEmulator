# Handoff — 2026-09-08d. RULED: `u_hs` FREED under the observed overturning and `h_ml` under the Holte mean/max prior — ROUND 4 (31 par) PREPARED; the SEASONAL mixed layer SCOPED as the round-5 candidate (it is the mechanistic successor of `ent_seas_amp_SH`); the WHOLE-MODEL SCORECARD says the ocean arc bought the deep and nothing on the pedagogical chain, and added a gate-Q failure.
# **⛔ Canonical `ent26`. Every model number is GENERATED (`diag_whole_model_scorecard.R`, `diag_u_hs_h_ml_tests.R`, the build scripts); the one recollection (Martin b) is labelled. LAUNCH STATUS: see §6.**

Read first: `notes/handoff_2026-09-08c_u_hs_h_ml_tests.md`, `notes/prereg_2026-09-08d_round4_u_hs_freed.md` (binding),
`notes/options_2026-09-08d_seasonal_h_ml.md`, CHANGELOG 2026-09-08d. Memory: [[ccx_round4_prepared]],
[[ccx_scorecard_20260908]], [[ccx_seasonal_h_ml_option]], [[ccx_u_hs_h_ml_tests]].

## 1. The ruling and what was done with it
Marcus: "Free u_hs. Either free h_ml or explore pinning it to a seasonal shape so that it can capture both the annual
mean and the annual max. Also, continue to judge the model overall in the context of the overall goals."
1. **`u_hs` is the 31st fitted parameter** (`R/calibrate.R`: table entry after `h_hs`, logit [5, 150] m/yr; prior lognormal
   median 21.84, log-sd 0.242 from `data/obs_u_hs_prior.rds` = NADW 18 + AABW 16–29 Sv over the model's HS area; the old
   38 at z +2.29). Removed from `CCX_STRUCT_HILDA`; `CCX_U_HS_DECLARED` (38) is what ancestors migrate to (it encodes, so
   every start begins AT 38). Both cores already read it per draw. `tests/testthat/test-u-hs-fitted.R` (67 assertions).
2. **`h_ml` keeps its box and gets the observation prior**: lognormal median 83.9 m, log-sd 0.341, so the LS annual mean
   (59.7) and max (118) are the 16/84 % points (`data/obs_h_ml_prior.rds`). 39.8 sits at z −2.19. The prior ENCODES the
   mean-vs-max ambiguity; the seasonal mixed layer (item 3) is what would resolve it.
3. **The seasonal shape is scoped, not built** (§3). The Holte monthly cycle is in `data/obs_mld.rds$seasonal`.
4. **The scorecard** (§4) at `ent26` and the round-3 winner.
5. **Round 4 prepared**: prereg R1–R10, outdir `multistart_20260908d_hilda31` at its three sites, port targets re-cut
   (31 par, hilda), local preflights ids 0/1/2 PASS (port rel 1.4e-15, 0.082 s/eval, LAUNCHABLE).
   ⚠ **Test edits made under the ruling, flagged for veto:** counts 30 → 31 (`test-ent-seas-fitted.R`,
   `test-likelihood.R`, the precedent); and `test-prior-z.R`'s "uniform under logit" case RE-TARGETED from `h_ml` (no
   longer uniform) to `h_hs` (same claim, same transform), plus a new case asserting the two boxed lognormals against
   the TRUNCATED closed form (the screen integrates inside the box; `h_ml`'s box clips 0.7 % and shifts z ≤ 0.03).

## 2. Round 4 — THE question (prereg 09-08d)
Does the fit run `u_hs` back toward 38 against a prior that says 22? **≥ 33 m/yr** ⇒ the 70 Sv flush is a SINK
requirement of a model whose LS column ventilates only by `kz` — a structure finding (the missing mode-water limb),
and `u_hs` should then be DECLARED at the observation with that limb added. **≤ 27** ⇒ the observation holds once the
rest refits; the export falls with it (R2: `pump_hs` ≈ 3.6–4.3 × `u_hs`). Between: contest, do not adopt. My prediction
is R1 ≥ 33 (T1(i)'s 189 at 24 m/yr dwarfs the prior's 2.6). R3 `h_ml` in [50, 100]; R4 common-row likelihood within 5 of
−1438.64; R9 gate Q and the HS surface δ¹³C RECORDED.

## 3. The seasonal mixed layer (`notes/options_2026-09-08d_seasonal_h_ml.md`)
`ent_seas_amp_SH` (fitted, SH only, winner 21.2 µmol/kg) IS winter entrainment as a compensator. The climatology gives
the shape (NH 30 → 83 m Feb; SH 36 → 114 m Aug; per-cell entrainment fraction 0.26–0.65 / 0.20–0.68); the winner's own
sub-ML DIC step (+42 layer 1, +97 layer 2) makes the DERIVED amplitude **SH 10–17, NH 8–14 µmol/kg** — the observed order
untuned, and the NH channel `sst_seas_amp_NH` (z −2.8 / −3.9) is straining for. **Option B** (the shim made honest:
amplitude = `(C₁ − C_ml)(t) × f(month)`, both hemispheres, ¹³C carried, `ent_seas_amp_SH` retires) is the round-5
candidate; P1–P5 drafted, P2 (the NH strain RELAXES) load-bearing, P4 (the `d13c_seasonal_*` rows must not pay) the
discriminant. Build after round 4 is read so the `u_hs` answer stays attributable. Option A (a true time-varying grid) only
if B's isotope test fails.

## 4. The scorecard (`outputs/diagnostics/whole_model_scorecard_20260908.log`)
| | `ent26` | round-3 winner |
|---|---|---|
| likelihood, common rows | −1652.6 | −1427.6 (+225: profile +234, ocean_deep −10, hs_surf −11; transient groups ±3) |
| V / H / 5 | FAIL −2.67 / +6.55 / +2.17 | FAIL −2.74 / +6.50 / +2.17 |
| G / Q / 7 / S | PASS / **PASS 1.27** / PASS / PASS 8.87 mo | PASS / **FAIL 2.17** / PASS / PASS 8.93 |
| ENSO ocean ÷ obs (solubility-only r) | 0.47× (−0.52) | 0.44× (−0.53) |
| IRF(100) (Joos 0.409) | 0.276 | 0.275 |
| strained priors | q10 −2.2, sst_seas_amp_NH −3.9, rep_dC +3.4 | q10 −2.2, kz_deep_frac −2.1, pump_hs +3.0, sst_seas_amp_NH −2.8, rep_dC +3.5 |
**Judgment against the goals.** The structure bought the deep and is a wash on every transient observable; it ADDED gate
Q's failure (the 2 °C cold box lifts the mean air-sea δ¹³C disequilibrium to 0.82 vs 0.60 ± 0.10 — the round-3 handoff's
"2 °C fractionation" item). For the pedagogical chain the live defects, in order: **the ENSO ocean sign (Fix B, unchanged
since 09-04) > the NH seasonal strain (option B addresses it mechanically) > the δ¹³C gradient LEVEL (H; an objective gap)
> gate Q.** Round 4 is a physical-intuition question, not a chain fix — say so when reading it.

## 5. Files (this commit)
`R/calibrate.R` (accessors, table, migration, struct list, comments), `calibration/lib_run_inputs.R`,
`data-raw/build_u_hs_prior.R` → `data/obs_u_hs_prior.rds`, `data-raw/build_h_ml_prior.R` → `data/obs_h_ml_prior.rds`,
`data-raw/build_mld_targets.R` (+`$seasonal`) → `data/obs_mld.rds`, `calibration/diag_whole_model_scorecard.R` +
`outputs/diagnostics/whole_model_scorecard_20260908.{log,rds}`, `calibration/diag_u_hs_h_ml_tests.R` (repointed),
`calibration/make_port_targets.R` (caption fix) + `calibration/torch/port_targets.csv`, `calibration/run_dispersed_multistart.R`
+ `calibration/torch/multistart.sbatch` (outdir), `tests/testthat/{test-u-hs-fitted,test-prior-z,test-ent-seas-fitted,test-likelihood}.R`,
`outputs/diagnostics/preflight_hilda31_id{0,1,2}.log`, `notes/{prereg_2026-09-08d_round4_u_hs_freed,options_2026-09-08d_seasonal_h_ml}.md`,
`notes/caveats_declared_parameters.md`, CHANGELOG, this note. Memory: `ccx_round4_prepared`, `ccx_scorecard_20260908`,
`ccx_seasonal_h_ml_option`; pointers in `INDEX_ccx`, `INDEX_ccx_seas`, `INDEX_ccx_ocean_struct`, `MEMORY.md`.
⚠ `INDEX_ccx.md` is at 17.4 KB of its 18 KB hard ceiling — SPLIT before the next addition (the "Likelihood, scoring,
parameters" section is the natural cut).

## 6. LAUNCH STATUS
**LAUNCHED 2026-09-08 ~08:10 EDT: Torch job 17185969** (`sbatch --array=0-45%10 calibration/torch/multistart.sbatch` from `/scratch/ms17839/CarbonCycleEmulator` at launch commit **81d164c**, port targets 63324fa). Setup gate PASSED (0.37 s/eval on the login node); preflight array 17185953 **8/8 COMPLETED, port VERIFIED rel ≤ 2.4e-12** (ids 0–5 seeded, 25/45 dispersed). Budget as round 3 (3 × 6000 × 6, wall 180 min); round 3 took ≈ 9 h end-to-end at `%10`, so expect the array to drain by ~17:00–18:00 EDT. Collect with the §7 commands; score with `calibration/diag_hilda31_predictions.R` (smoke-tested on round 3: reproduces −1438.64).

## 7. Collect (after the array drains; from the Mac, never rsync from inside an ssh session)
```
ssh torch 'sacct -j <JOBID> -X --format=JobID,State,ExitCode,Elapsed | tail -50'
rsync -a torch:/scratch/ms17839/CarbonCycleEmulator/calibration/output/multistart_20260908d_hilda31/ calibration/output/multistart_20260908d_hilda31/
CCX_MS_STRUCT=hilda CCX_MS_OUTDIR=calibration/output/multistart_20260908d_hilda31 Rscript calibration/collect_dispersed_multistart.R
```
Then a scorer modelled on `diag_hilda30_predictions.R` (edit `HP_DIR`, `HP_N_EXPECTED`; add R1's `u_hs` read and the
≥ 33 / ≤ 27 verdict; compare on LIKELIHOOD to −1438.64). Still owed: a SOURCED Martin exponent; the `INDEX_ccx` split.
