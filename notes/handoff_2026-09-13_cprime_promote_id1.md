# Handoff — 2026-09-13 (late). **NEXT SESSION: PROMOTE C′ id 1 (the shim pinned to 0, h_ml 65.2 m, CONVERGED), THEN THE HESSIAN. It will be the project's FIRST PINNED CANONICAL, and three pieces of machinery do not yet know what that is — do those edits BEFORE the promotion, not after it breaks.**

> Self-contained. The arc: CHANGELOG 09-12 (c)–(f), 09-13, 09-13 (b), (c). Memory: [[ccx_cprime_result]], [[ccx_pinned_arms]],
> [[ccx_hilda31s2_adopted]], [[ccx_assessment_20260912]]. The evaluation that recommends promotion is the last message of the
> 09-13 session (its numbers are in CHANGELOG 09-13 (c) and below). Marcus has NOT yet ruled on promotion; the evaluation
> recommended it and named its two conditions. **Tree clean at `69d0e90`.**

## 1. THE RULING THIS HANDOFF ASSUMES (take it explicitly at the start of the session)
"Promote C′ id 1." Its conditions, from the evaluation: **id 1, not id 5** (id 5 is 0.2 better but sits at h_ml 72.8 m,
2 m under the P8 wall, and is not CONVERGED; id 1 is CONVERGED at 65.2 m, the canonical's own depth); and **the canonical becomes
PINNED** (`ent_seas_amp_SH` = 0 held in the base, 30 free names) — a stopgap for RETIRING the shim from the table, which is a
separate, larger change (§6).

## 2. WHAT C′ SHOWED (the case; CHANGELOG 09-13 (c))
| | `hilda31s2` (shim 8.01) | **C′ id 1** |
|---|---|---|
| likelihood, common rows | −1389.48 | −1392.02 (**−2.53**, of which `d13c_seasonal_SPO` −1.88) |
| pinned logpost (NOT comparable: no prior/Jacobian for the shim) | — | −1426.2428, CONVERGED (ids 0/3/6 agree to 4 dp) |
| SPO limb anatomy | SST 0.90 @ 4.1 / entrained 0.82 @ 9.7 / shim 0.50 → 0.465 @ 8.96 | SST 0.63 @ 4.1 / entrained **0.96** @ 9.7 → 0.357 @ 8.92 PASS |
| SPO δ¹³C seasonal amp (obs 0.0168 ± 0.0157/yr) | 0.0199 | 0.0221 (phase unchanged) |
| `sst_seas_amp_SH` (obs 1.746) | 1.85, z +0.26 | **1.29, z −1.22** — not strained, but a directional move OFF its observation: the shim was standing in for this |
| strains | rep_dC +3.40, kz_deep_frac −2.45, pump_hs +2.31, q10 −2.10 | +3.35, −2.47, +2.22, −2.11 (the same four) |
| chain (V / H / 5 lag / G / Q / 7 / ENSO) | −2.55 / +11.58 / +1.72 / +1.24 / 2.88 / PASS / 0.57× (r −0.528) | −2.55 / +11.59 / +1.74 / +1.21 / 2.94 / PASS / 0.58× (r −0.527) — **unchanged** |
Outdir `calibration/output/multistart_20260913_cprime_seasml1_pin_ent_seas_amp_SH=0_sd1.0452/` (24 starts, `collect_round1.log`,
`summary.csv`); the start files record `pins = c(ent_seas_amp_SH = 0)`, `param_names` (30), `struct` hilda, `seas_ml` 1.

## 3. THE THREE EDITS BEFORE THE PROMOTION (each is a consumer that encodes the canonical's `par_mode` or reads its shim)
1. **`calibration/recompute_hessian.R`** does NOT apply a file's pins: `ccx_par_to_unc(md$par_mode)` on a 30-name `par_mode` under the
   31-name table dies with "p lacks parameters this build fits: ent_seas_amp_SH". Add, right after `ccx_load_cpp()`:
   `invisible(ccx_apply_pins(ccx_mode_pins(md)))` (after `md` is read), and let `bp <- ccx_mode_base(md)` carry the value (it already
   does). GATE 1 (reproduce the stored logpost) then works on the 30-name space; the Hessian is 30×30. Record `pins` in the hess file.
2. **`calibration/lib_design_gates.R` `dg_vector()`**: `ccx_migrate_par_set(md$par_mode)` will see the shim ABSENT in a 30-name file
   and try to MIGRATE it — the absence contract fills 0 (the pre-09-03 meaning) and flags `migrated = "ent_seas_amp_SH"`, so every
   scorecard line would print "MIGRATED 30->31" for the canonical. Fix: exclude `names(md$pins)` from the absence test (a pinned name
   is not absent, it is held), and have `ccx_mode_base(md)` (already pin-aware) supply the value. `dg_streams` is unaffected
   (it calls `ccx_loglik` directly).
3. **`tests/testthat/test-mode-file.R:193-207`** asserts `expect_false(CCX_MODE_PINNED[[CCX_MODE_CANONICAL]])` and re-scores the FREE arms
   requiring the canonical to WIN on logpost. Both encode "the canonical is a free arm", which the 09-04 registry note wrote when
   no pin existed. ⛔ THIS IS A RULING, NOT A REPAIR — re-express as: (a) a pinned canonical is allowed when its pin is a
   retirement-in-waiting (the file's `pins` names it); (b) among FREE arms the best free arm is `hilda31s2` and the test still
   asserts that; (c) the canonical must beat the seas_ml 0 CONTROL on LIKELIHOOD (common rows: C′ −1392.02 vs `hilda31p` −1396.26,
   +4.2) and its PRICE vs its free parent (−2.53 vs `hilda31s2`) is RECORDED, not gated — the ruling is that the price is accepted.
   The stored-logpost-reproduces assertion stays (apply pins first).
Then these tests need re-pinning or re-expression (they read `md$par_mode$ent_seas_amp_SH` or encode the canonical's `par_mode`):
`test-pinned-arm.R` (its identity test uses the CANONICAL's fitted shim — point it at a FREE file, `hilda31s2` by name if it stays
registered, else by quarantine path), `test-enso-demean.R` (`edm_price` → `ccx_par_to_unc(md$par_mode)`: apply pins; the demean price
at the pinned mode is a NEW number to measure), `test-gate-bounds.R` (the GATE S power test's blind read moves: measure), `test-ent-seas-fitted.R`,
`test-likelihood.R`, `test-seas-ml-label.R`, `test-seas-ml.R`, `test-seas-lag-split.R`, `test-so-entrainment.R` (grep
`ent_seas_amp_SH` / `ccx_par_to_unc(md$par_mode)` in each; most only need `ccx_apply_pins(ccx_mode_pins(md))` before encoding, or to
name a free file). `lib_seas_limbs.R` `sl_overlay` must carry `md$pins` too (it applies structure + seas_ml; add the pins).

## 4. THE PROMOTION, STEP BY STEP (after §3)
```
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator
Rscript calibration/promote_multistart_mode.R \
  --outdir=calibration/output/multistart_20260913_cprime_seasml1_pin_ent_seas_amp_SH=0_sd1.0452 \
  --dest=calibration/output/refit_20260913_hilda30_cprime_pin_ent0 2>&1 | tee .../promote.log
```
The tool already applies the starts' pins before GATE 1 (09-13 (b)); GATE 3 derives the best CONVERGED start = **id 1** (ids 0/6 are
TIME at the same value, id 3 CONVERGED at the same value — the tool picks by logpost among converged, so id 1 or 3; either is the
same point to 4 dp). Expect GATE 5's streams −1392.0157 + prior/jac ≈ −34.23 = −1426.2428. Then:
```
Rscript calibration/recompute_hessian.R calibration/output/refit_20260913_hilda30_cprime_pin_ent0/mode_fit_pumpN.rds --update
```
Read: PD; condition number; the step-drift column (2 % tolerance); `h_ml` ± (65.2 m; the wall is ~10 m away); and **`sst_seas_amp_SH`'s
posterior sd** — the parameter the fit moved off its observation is where a soft direction would show. If anything is
step-unstable, STOP and report before repointing.

## 5. THE REPOINT (`R/paths.R`), following the 09-13 precedent
- Name: **`hilda30c`** (30 free names, C′). `CCX_MODE_CANONICAL <- "hilda30c"`; `CCX_MODE_FILES` = hilda30c + **hilda31s2** (KEEP
  REGISTERED as the free 31-name parent — C′'s meaning is its price against this file) + hilda31p (the seas_ml 0 control);
  `CCX_MODE_PINNED <- c(hilda30c = TRUE, hilda31s2 = FALSE, hilda31p = FALSE)` — the first TRUE, and the registry's own comment
  block must say what a pin IS now (it still describes `pin90`'s near-delta prior). No quarantine this time (nothing is superseded:
  `hilda31s2` is the parent, not a defect). Update `run_dispersed_multistart.R` / `make_port_targets.R`'s incumbent only if the next
  array is a pinned one (they read `CCX_MS_PIN`; the incumbent must be evaluated under the array's own pins).
- Then: port targets (`CCX_MS_PIN=ent_seas_amp_SH=0 CCX_MS_STRUCT=hilda CCX_MS_SEAS_ML=1 Rscript calibration/make_port_targets.R`),
  the scorecard (`diag_whole_model_scorecard.R` — arm C via `dg_vector`, so §3.2 first), the re-pins, the full suite, CHANGELOG,
  memory (`ccx_hilda30c_adopted`; `INDEX_ccx` live line; `ccx_hilda31s2_adopted` gets a "PARENT of the pinned canonical" note, not
  SUPERSEDED), `make_bundle.sh` (add the new refit dir; it asserts registry files now).

## 6. WHAT THIS DOES NOT SETTLE (say so in the record)
- **The shim is PINNED, not RETIRED.** Retiring `ent_seas_amp_SH` from `CCX_PARAM_TABLE` makes the build a 30-name space for
  everyone: `hilda31p` (the seas_ml 0 control, shim 18.7 — at seas_ml 0 the shim IS the DIC side) would then be unscorable as it
  stands. So retirement needs either a seas_ml 0 control refit without the shim (a new array) or the control kept as a
  pinned-at-18.7 arm. A ruling for later; the pin is the honest interim.
- `sst_seas_amp_SH` 1.29 vs 1.746: inside its prior (z −1.22) but off its observation. If the Hessian shows it soft, that is the
  shim's missing piece asking for a mechanism (the thermal:DIC ratio gate, assessment option K, would make it a gate rather than
  a prior). Not a blocker.
- id 5's 72.8 m sub-basin: 0.2 log-units better, abuts the P8 wall. Recorded; not promoted.

## 7. NON-OBVIOUS STATE
- **Torch**: queue EMPTY; nothing in flight. Fairshare ~0.20 (a 6-h queue wait on `cs` is the observed cost of an array; the C′
  array happened to start immediately). The remote tree is at `f65c960` + the bundle fix; it lacks nothing the promotion needs
  (promotion runs on the Mac).
- `calibration/torch/port_targets.csv` is currently the C′ (pinned) set — a FREE-arm array must regenerate it with `CCX_MS_PIN` unset.
- `CCX_PINS` is a process-global: any script that applies pins and then scores a FREE file in the same process scores it with the shim
  at its DEFAULT (the 09-13 (c) evaluation tripped on exactly this — `ccx_unpin_params(list())` is a no-op; unpin with the object
  `ccx_apply_pins()` RETURNED, or use a fresh process).
- Next after the promotion: **A's unrefitted probe** (the Niño3.4 limb on `ml_lo`, option B ruling 2) at the new canonical; then M
  (the per-hemisphere MLD handle). The 09-12 assessment's verdict — the ENSO link is the blocker — is unchanged by C′.
