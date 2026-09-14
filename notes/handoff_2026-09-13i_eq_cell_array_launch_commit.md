# Handoff — 2026-09-13 (i). **THE ARRAY-LAUNCH COMMIT IS BUILT: `w_eq` / `gamma_eq` are in the table (31 → 33; 32 free under the kept C′ pin), the port targets are measured under `hilda_eq`, the Mac preflight says LAUNCHABLE. The array is NOT submitted — Torch, Marcus's hands. Nothing adopted.**

> Self-contained. CHANGELOG 09-13 (i); memory [[ccx_eq_cell_array_launch_kit]] (in `INDEX_ccx_ocean_circ`; `INDEX_ccx` live line updated).
> Previous: `handoff_2026-09-13h_eq_cell_built_probed.md`; prereg `notes/prereg_2026-09-13g_equatorial_cell_build.md` (§6: the array is the step after the probe).
> Canonical `hilda30c` UNCHANGED on disk and in `R/paths.R` — but see §3: it no longer LOADS through `ccx_load_mode()` until promotion.

## 1. What this commit does (the 09-13 (h) ruling: the table change rides in the launch commit)
- **`R/calibrate.R`**: `w_eq` (logit [5, 60] Sv, init 27, prior N(27, 3) read from `ccx_eq_cell_obs()$w0_prior`) and `gamma_eq`
  (logit [0, 2], init 1, `dunif` flat) after `u_hs`; migration contract absent = 0 (no loop, what every ancestor RAN) ⇒ both on a
  floor ⇒ `ccx_seed_unencodable()` seeds 27 / 1 (the probe's PE1 point). ⚠ The (h) handoff said "id [0, 2]" — an `id` has no box
  here; the box is carried as logit with the flat prior, bounds and prior preserved exactly. **Say so if you want `id` + N(0, σ)
  instead** (that is a different prior, not a re-encoding).
- **Measured**: at the canonical migrated + seeded under `"hilda"`, the 25 stream likelihoods reproduce TO THE BIT and the logpost
  moves by exactly −0.8236 (two priors at init + Jacobians) — asserted as a constant in the re-expressed P0a (`test-eq-cell.R`).
- **`calibration/torch/port_targets.csv`** regenerated: `CCX_MS_PIN=ent_seas_amp_SH=0 CCX_MS_STRUCT=hilda_eq CCX_MS_SEAS_ML=1`;
  cold −15408.0929, incumbent (`hilda30c` at 27/1) −1548.9498 (−122.71 vs stored: ~−86 the `eq_b1` row at z +13, ~−18 the common
  rows at γ 1, −0.82 the priors, the rest the incumbent's own `gamma_enso_ocn_*` now supplementing the cell), new basin (`hilda31p`)
  −1699.3705. Stamp `9ad0908` = the tree the numbers were measured on (the launch commit follows it; the gate reads brackets/labels, not the hash).
- **`calibration/torch/multistart.sbatch`**: the (i) block; the OUTDIR now carries every label axis
  (`multistart_20260913_eqcell_${CCX_MS_STRUCT}_seasml${SEAS}${PIN}_sd${SPREAD}`). Default struct is still `hilda` — the label
  MUST be given on the command line.
- **Mac preflight** ids 0/1/2/6 (`CCX_MS_PREFLIGHT=1`, scratch outdir): port VERIFIED rel 1.8e-15 / 2.4e-14 / 9.6e-15 / 9.6e-15,
  **0.195 s/eval** (the cell costs nothing measurable over C′'s rate) ⇒ the 300/360-min arithmetic stands; `MS_SPREAD_SKIP =
  w_eq, gamma_eq` (measured sd 0.2250 over the other 30; the explicit 1.0452 rules, as ruled 09-10). Dispersed starts draw the
  pair about the cold init like every coordinate.
- Tests: counts 31 → 33 (`test-ent-seas-fitted:20`, `test-likelihood:571`); R3 test + P0a re-expressed in `test-eq-cell.R`; two
  fixture seeds (`test-enso-split:218`, `test-seas-lag-split:140`) — **flagged for veto**, see CHANGELOG (i) §Tests.

## 2. To launch (Torch — the standing verdict: no licence/substrate blocker, 24 parallel starts the laptop would serialise)
```
bash calibration/torch/make_bundle.sh            # → /tmp/ccx_torch_bundle.tar.gz; scp + untar per its printout
CCX_MS_STRUCT=hilda_eq CCX_MS_PIN=ent_seas_amp_SH=0 CCX_MS_PREFLIGHT=1 sbatch --array=0-5,25,45 --time=00:15:00 calibration/torch/multistart.sbatch
#  READ IT: port VERIFIED on all 8, s/eval on the nodes vs the 108-min worst case in the sbatch header; then
CCX_MS_STRUCT=hilda_eq CCX_MS_PIN=ent_seas_amp_SH=0 sbatch --array=0-23%24 calibration/torch/multistart.sbatch
```
No ControlMaster was live this session (`ssh -O check torch`: no socket). If one is opened and Marcus says so, the 09-03 precedent
(`runnable_is_not_undrivable`) lets the session submit.
Afterwards: `CCX_MS_PIN=ent_seas_amp_SH=0 CCX_MS_OUTDIR=<dir> Rscript calibration/collect_dispersed_multistart.R`;
`promote_multistart_mode.R --outdir=… --dest=refit_20260913_hilda30e_eqcell_pin_ent0` (proposed name `hilda30e`); `recompute_hessian.R --update`;
repoint `R/paths.R` (`CCX_MODE_CANONICAL`, `CCX_MODE_FILES`, `CCX_MODE_PINNED`; the FREE PARENT question — there is no free `hilda_eq`
parent; `test-mode-file:239` asserts the parent carries the full set — is a RULING at promotion); `test-mode-file:175-176`
`struct %in% c("", "hilda", "hilda_eq")` + the `hs_frac` assertion (0.16 for both hilda labels); `make_bundle.sh` the new dir;
`port_targets.csv` regenerated. THEN PE2–PE5, PE7–PE8 on the array's mode; PE9 once.

## 3. Non-obvious state
- **`ccx_load_mode()` refuses every registered mode** (31 names vs 33) until promotion: the app, the scorecard and every `diag_*.R`
  that resolves the canonical STOP. The driver, `make_port_targets.R` and the eq-cell tests do not go through it (they migrate + seed).
  Suite: 2796 / 7 F / 12 E — the known pair + error, plus 11 expectations in 6 files that all read a registered file's `par_mode`/`u_mode`.
- `w_eq`/`gamma_eq` are inert under `"hilda"` (asserted: spinup and deriv bit-identical at 40 / 1.5). Identifiable only under `hilda_eq`.
- The dispersed starts' `w_eq` draws span roughly 12–45 Sv (logit sd 1.0452 about 27); `gamma_eq` roughly 0.4–1.6 about 1.
- Still owed after the array: M, pin-vs-retire of `ent_seas_amp_SH`, option K, the `OCEAN_AREA_*` provenance one-liner, the ~35 stopping `diag_*.R`.
