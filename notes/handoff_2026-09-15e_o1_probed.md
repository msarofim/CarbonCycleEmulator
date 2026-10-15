# Handoff — 2026-09-15 (e). **O1 (the mean deep return) BUILT in two arms and PROBED unrefitted at `hilda30c`: REFUTED AS BUILT under its own preregistered rule — not promoted. The HS-route THC limb (`w_thc`, `k_thc`) is in both cores, bit-exact off. The read: the 1995 ocean bomb inventory is z ≈ +4 in EVERY configuration incl. the canonical; kz cannot fall under a prescribed export; the martin field's own −208 on `co2_seasonal_SPO` is that row DEMANDING the export magnitude (A2) — "demanded by no row" retracted in part; the layer-2 inversion is the field's. What worked: THC brings the DIC gradient inside σ at k ≥ 8; HS water at ~5 Sv is FREE on the deep Δ¹⁴C (P3 amended A1). Also this session: the flux/isotope AUDIT (clean, one latent D1 defect FIXED), the root-memory false alarm (5th), Torch down 09-16. Candidates O5 / O6; rulings owed. `hilda30c` canonical; nothing adopted.**

> Self-contained. HEAD = `6e7ed5f` (+ this note). CHANGELOG 09-15 (d) + (e). Memory: [[ccx_flux_audit_0915d]], [[ccx_o1_deep_return_probe_0915d]],
> [[torch_downtime_20260916]] (pointers in `INDEX_ccx_ocean_cell` — ⚠ now 14.5 KB, OVER its 14 KB soft target: merge a line before adding
> one; `INDEX_ccx_ocean` 12.6 KB; `INDEX_infra` 5.8 KB). Root `MEMORY.md` content 11.9 KB, UNDER soft — the 09-15 (c) header's "18,400 of
> 18,432, RESTRUCTURE" was a bare `wc -c`, the FIFTH such false alarm; the check is now the root's first visible line. Previous:
> `handoff_2026-09-15c_kz_pump_diagnosed.md`.

## 1. This session, in order
1. **Root memory re-measured** (content 11,705 B, not 18,400) — header counts fixed, live warning restored; orphan sweep 0/0.
2. **Rulings (Marcus, 09-15 d):** O1 is the direction ("consistent with physics"; improvement NOT established); do the prereg + the mean limb +
   the O1 build; **T5 / the cell WAITS for O1; the `hilda_c` / solved arm DEFERRED**; audit for one-way fluxes and one-isotope terms;
   **both arms** (HS-route THC + local STC). Torch DOWN Wed 09-16 07:00–19:00.
3. **AUDIT** `notes/audit_2026-09-15d_flux_closure_isotopes.md` (`e85c52d`): five `dy` write paths, every transport carries C/¹³C/¹⁴C at the
   source ratio (decay the only ¹⁴C-only sink; fossil's Δ = −1000 ⇒ 0); every water limb closes; pumps one-way by design, conserving.
   **ONE latent defect FIXED:** `tr` WITHOUT the cell (licensed by `ccx_tr_on()`) shrank `a_ml` under `eq_on || tr_on` while three sites (ML/layer-1
   diffusion thickness, seasonal-ML excursion share, entrainment) read `eq_on` alone — 125 GtC/yr spurious at uniform conc, both cores,
   invisible to conservation. One flag `d1_on` (R `ccx_prepare()`, derived in C++ `unpack_aux()`); `test-tr-box.R` P0g-tr (fails 125 / passes
   1.7e-13 / mutation 376). No registered mode affected. Cosmetic, recorded: `q_conv` mislabeled by (1 − f_hs) under HILDA; its deep leg on the
   annual-mean grid; `ent_seas_amp_SH` moves no tracer (pinned 0).
4. **PREREG** `notes/prereg_2026-09-15d_o1_deep_return_probe.md` (`1287b2e`, before any core edit): the two arms with their physical
   mechanisms and depth ranges (STC k ≤ 4; THC any k), P0 contracts, the grid, the decision rule (a)–(d).
5. **BUILD** (`f51a219`): arm THC — `w_thc` [Sv, both hemispheres, split by a_hs; table logit [0, 60], FLAT prior — ⚠ **PRIOR SOURCE OWED**],
   `k_thc` (structural, on `p`). Five legs `ml → hs → hd → oc[nl] → up through every interface below k → oc[k] → ml`, each W × the source box's
   per-volume conc (D1 closes; uniform column a fixed point). Inert under "solved" (E's contract); errors by name without HS boxes;
   `ccx_thc_eigbound()` exactly 0 off. Registered: absent-ok, migration 0, `ccx_pump_field_inert("solved")`. `test-thc-limb.R` 105/105; table
   count 36 → 37 in five test files. Arm STC = E's `w_vent` at `k_e1 = k_e2 = k`, `gamma_vent` 0 (no build).
6. **PROBE** `calibration/diag_o1_deep_return_scan.R` → `outputs/diagnostics/o1_deep_return_scan_20260915.{log,rds}` (`6e7ed5f`; stage 1
   43 s, stage 2 ~35 min). Gates 1–4 PASS; martin/no-limb reproduces the E probe's D-alone −894.8. Post-hoc A1/A2 (stamped in CHANGELOG (e)),
   scratch script not committed.

## 2. The numbers that matter
| | control (solved) | THC best (k1 W10) | THC k10 W10 | STC k2 W10 |
|---|---|---|---|---|
| arm C dlik at kz × 1 | 0 | −276 | −319 | −286 |
| DIC gradient (233 ± 25) | 303 (z +2.4) | 269 (+1.2) | **247 (+0.4)** | 295 (+2.1) |
| 1995 bomb excess (51.4 ± 10.8 kmol) | 81.4 (z +3.9) | 82.9 (+4.1) | 82.8 (+4.1) | 81.7 (+4.0) |
| PI layer 2 − ML (µmol/kg) | +5 | −66 | −70 | −68 |
| `co2_seasonal_SPO` (arm C) | 0 | −208 | −227 | −214 |
Control arm C along kz × 0.7 / 0.5 / 0.35 / 0.2: −19 / −86 / −134 / −224 (bomb excess z +3.5 / +3.1 / +2.9 / +2.6). No limb at kz × 0.5 / 0.35 /
0.2 raw: −4059 / −8409 / −23815; the THC limb recovers ≤ 20 %. **A1:** THC k1 at 2.5 / 5 / 10 / 20 Sv, the deep Δ¹⁴C rows ab/bd/level:
+1.3/−0.3/+1.1, +0.2/−3.5/+1.1, −27/−15/−1, −261 total (T-A0's ML-sourced 0.5 m/yr ≈ 2.4 Sv/hemisphere cost −104 on bd). **A2:** martin, no limb,
export 9.08 / 20 / 45.5 → `co2_seasonal_SPO` −252 / −137 / −6. τ_q × 0.5 / 2 at THC k1 W10: −1249 / −1202 raw (DIC 242 / 331).

## 3. What is closed, what is open
- **O1 as scoped (prescribed export + a mean deep return, either closure) is REFUTED** by its own rule; the build tier / array did NOT happen.
  O2's DESIGN §6 statement is the honest end state for O1 — **NOT yet written** (owed if Marcus rules O2).
- **The two structure-independent facts** the probe exposed: (i) the ocean bomb inventory overshoot is the objective's, not any candidate's
  (the atmospheric Δ¹⁴C rows outvote `excess_c14_ocean` 40:1); (ii) `co2_seasonal_SPO` holds the export magnitude because the export is
  CONSTANT in the deriv (`R/model.R` pump block: `sc` rescales it under pump_mode D, no seasonal term) and the SH seasonal CO₂ amplitude is the
  seasonal ML entraining the sub-ML DIC gradient ∝ export / K.
- **Candidates with a mechanism and a test, NOT ruled:** **O5 a seasonal export** (SH-summer-peaked; mean 9.08 with an amplitude — does the SPO
  row recover and the layer-2 inversion clear?); **O6 the bomb budget's land share** (the model's 1995 atm/land/ocean excess vs a literature
  budget — LOOK IT UP, do not recall). Follow-up on the THC limb: is the HS box's PI Δ¹⁴C too young for a deep-water end-member (the profile
  rows bound the overturning at ≲ 5–10 Sv both hemispheres; a real MOC is ~20–30 Sv — uncited recollection)?
- **Rulings owed (Marcus):** O5 / O6 / O2; whether T5 / the cell stays parked (it waited for O1); the deferred `hilda_c` arm.

## 4. Non-obvious state
- `calibration/torch/port_targets.csv` is STILL the E arm's (hilda_c / martin / 4 pins) — regenerate before ANY array.
- **Torch DOWN Wed 09-16 07:00–19:00** (Marcus): submit nothing that must survive it; queue was empty 09-15.
- The probe's stage-1 grid selected W = 10 (the smallest) and kz × 1 for EVERY (arm, k) — the limb is a cost at every point unrefitted, growing
  with W; the arm-C selection rule (best raw per arm × k) is therefore effectively "smallest W, canonical kz"; a scan below 10 Sv was only run
  post hoc (A1, k = 1). The stage-2 optimizer: 1600–1700 evals/point, ~2 min each, no non-converged periodic spinup flagged.
- `INDEX_ccx_ocean_cell.md` is OVER its soft target (14.5 KB); merge before the next add. `w_thc` prior source owed before any array frees it.
- Untracked: `outputs/diagnostics/o1_deep_return_scan_20260915_smoke.{log,rds}` (the 3-point smoke, disposable), `port_gate_id1_20260914.log`
  (the pre-split stray). Suite `suite_20260915e.log` 3492 / 4 / 2: the standing reds (GATE Q pair, `test-seas-lag-split:205`) + `test-tr-box:88`
  (a 36 → 37 count, fixed after the run; file re-run 254/0). Two earlier suite runs this session were invalid — files edited under the running
  parser (my breach of the never-edit-a-running-script rule) and a regex-broken two-line `expect_setequal`; both fixed.
- The P3 mis-specification (20 Sv vs T-A0's ~2.4 Sv/hemisphere) is the like-for-like class; the memory file's "How to apply" (1) records it.
