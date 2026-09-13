# Handoff — 2026-09-13 (d). **`hilda30c` IS CANONICAL (the first PINNED canonical). Next: A's UNREFITTED probe at it, then M.**

> Self-contained. CHANGELOG 09-13 (d); memory [[ccx_hilda30c_adopted]] (+ `INDEX_ccx` live line, `INDEX_ccx_arch_modes` lineage,
> the PARENT note on [[ccx_hilda31s2_adopted]]). Commit `7b92f02`. Suite 13,138 / the known pair + error only.

## 1. What is true now
- `CCX_MODE_CANONICAL = "hilda30c"` — `refit_20260913_hilda30_cprime_pin_ent0/mode_fit_pumpN.rds`, `pins = c(ent_seas_amp_SH = 0)`,
  30 free names, pinned logpost −1426.242817 (⛔ not comparable to a free arm); likelihood on the 25 common rows −1392.02.
- `hilda31s2` = `CCX_MODE_PINNED_PARENT` (free, 31 names, −1389.48 likelihood; the shim's price −2.53 is RECORDED by test-mode-file,
  not gated). `hilda31p` = the seas_ml 0 control (−1396.26; the canonical must beat it — gated).
- Hessian: PD, cond 3.31e5; **h_ml 65.23 ± 2.40 m, step drift 3.81 %** (plateau 1e-3..1e-2 flat to 0.5 %; the 3 eps leg touches the
  roll-off hilda31s2 also has). **`sst_seas_amp_SH` 1.288 ± 0.188 vs obs 1.746: 2.4 posterior σ UNDER, not soft** — a mechanism ask
  (thermal:DIC ratio gate, assessment option K), recorded, not a blocker.
- Scorecard `whole_model_scorecard_20260913_hilda30c.{log,rds}`: nothing on the chain moved. Q 2.94 FAIL is still the seasonal
  strain; the ENSO link (0.58×, solubility-only r −0.527) is still THE blocker (assessment 09-12 verdict unchanged).

## 2. Machinery a pinned canonical brought (know these before writing a diagnostic)
- **A pinned name is HELD, not absent.** `ccx_mode_par_with_pins(md)`; `ccx_mode_params()` returns it; `ccx_mode_base(md)` stamps
  `attr(p, "pins")` and `ccx_overlay_par()` honours it; `ccx_load_mode()`, `dg_vector()` (`$pins`), `sl_overlay(pins=)`, the app.
- **To ENCODE the canonical:** `rm <- ccx_apply_pins(ccx_mode_pins(md)); ...; ccx_unpin_params(rm)`. ⚠ `CCX_PINS` is process-global —
  a FREE file scored after an un-restored pin runs with the shim at its DEFAULT. `ccx_require_param_set()` now says "apply its pins".
- **Need an encodable 31-name template** (ancestor construction, a free start)? `ccx_mode_params(ccx_mode_free_name())` = the parent.
- **Arrays:** the incumbent FOLLOWS the array's pins (`MS_REF_INC_NAME` / `PT_INC_NAME`): canonical under `CCX_MS_PIN=ent_seas_amp_SH=0`,
  the parent for a free array, any other pin set STOPS. `port_targets.csv` is currently the PINNED set (incumbent −1426.2428).
- ~35 one-off `diag_*.R` that encode `md$par_mode` on the canonical will now STOP with the pinned-file message; fix each when run.
- `make_bundle.sh` lists the new refit dir; the Torch tree does NOT yet have it (nothing in flight; ship the bundle before any array).

## 3. Not settled (rulings for later, in order of when they bite)
1. **Pin vs RETIRE.** Retiring `ent_seas_amp_SH` from the table makes `hilda31p` unscorable (its shim is 18.7 at seas_ml 0 — there the
   shim IS the DIC side). Needs a seas_ml 0 control refit without the shim (a new array) or the control kept as a pinned-at-18.7 arm.
2. `sst_seas_amp_SH` off its observation — option K would make it a gate rather than a prior.
3. id 5's 72.8 m sub-basin (0.2 better, 2 m under the P8 wall) — recorded, not promoted.
4. The root `MEMORY.md` is at 18,202 B of its 18,432 B hard ceiling after the one-line canonical update — the next root edit must SPLIT
   (`memory_index_split_beats_trim`), not trim.

## 4. Next
**A's unrefitted probe** (the Niño3.4 limb on `ml_lo`, option B ruling 2) at `hilda30c` — resolve the vector with `dg_vector(CCX_MODE_CANONICAL)`
(pin-aware) and spin up with `dg_spinup(v)`; then **M** (the per-hemisphere MLD handle; the NH mixed layer's 0.107 ppm leak into SPO is
still inside GATE S's knockout).
