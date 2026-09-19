# Handoff — 2026-09-19 (h). **The canonical's objective-#13 refit READ: the ENSO-slope row BOUGHT the slope (0.35× → 0.94× GCB) for −0.37 on the other 25 rows, through `gamma_enso_ocn_NH` 0.36 → 0.45 alone; a perturbation scan shows the slope is LINEAR in the shim on top of the solubility term, and the #12 objective was flat there. The CONTROL's #13 wave is RUNNING (07:27 →, ~6 h). Nothing promoted.**

> Self-contained with handoff (g) `handoff_2026-09-18g_test_a_read.md` (test (a)'s result, the two rulings, the three #13 trees). Session record: CHANGELOG 09-19 (h); memory [[ccx_obj13_canonical_refit_read_0919h]]; ⚠ `INDEX_ccx.md` is **14.4 KB — over soft (14), under hard (18)**: move a closed paragraph out before the next entry ([[memory_index_split_beats_trim]]).
> **RUNNING:** the control's #13 refit (`~/ccx_frozen/20260918f_control_obj13_refit/`, fired by the chain 07:27; ML off, six inert + `w_enso_l2=0`, shim free; refs `hilda31p` −1795.40 / `hilda31s2` −2093.20). Ends ~13:30–14:00 uncontended. The chain script exits after it. The free-parent #13 tree (`~/ccx_frozen/20260918f_free_parent_obj13_refit/launch_now.sh`) is staged, NOT armed. Torch reserved for FrEDI through ~09-19.

## 1. What happened (09-19 h)
- Wave 20:42 → 07:26, 21/24 CONVERGED + 3 out of wall; ONE basin −1432.3938 = `hilda30h`'s own re-convergence (cold + ENSO seed + dispersed on the same vector); `h_ml` 49.9 sub-mode −0.45; a second basin −2.54.
- `diag_obj13_refit_read.R` (new: `O13_DIR` / `O13_LABEL=canonical|control|free_parent` / `O13_SUB`) → `outputs/diagnostics/obj13_canonical_refit_read_20260919.*`: **+4.69 on `gcb_ocean_enso_slope`, −0.37 on the other 25**; slope +0.040 → +0.109 (z −0.27; r 0.38 vs obs 0.49); **only `gamma_enso_ocn_NH` moved (0.36 → 0.45; SH 0 → 0.015)**; chain unchanged; GATE V slightly worse (z −4.77).
- `diag_enso_slope_gamma_scan.R` → `enso_slope_gamma_scan_20260919.*`: slope = **0.6328·γ_NH − 0.1873**, intercept = the T-A2 solubility-only slope to 4 decimals; the other 25 rows flat (2.4 log-units over [0.30, 0.60]). Real, not a kink.
- On the 26 #13 rows: canonical-refit −1397.93 · c1 −1392.39 · fp1 −1398.09 — but c1/fp1 are #12 fits; the control's #13 wave is the like-for-like.

## 2. What to do next (in order)
1. **Read the control's #13 wave** when it lands (~14:00): copy outdir `multistart_20260918_hilda_c_seasml0_pin_w_eq=27_…_w_enso_l2=0_sd1.0452` + logs into the repo, collect, then `O13_DIR=<outdir> O13_LABEL=control [O13_SUB=<h_ml twin id>] Rscript calibration/diag_obj13_refit_read.R`. Expect the shim-free arm to buy the slope the same way (γ_NH → ~0.45) — the question is whether ML-off still beats the ML arm by ~6–10 on 26 rows refit-vs-refit.
2. **Then the three rulings (Marcus):** (a) the seasonal ML — mechanism vs a ~6 log-unit price (handoff g); (b) the control's registration vs the "canonical beats the control" gate; (c) whether to PROMOTE the canonical's #13 refit (id 1 of the wave; precedent `promote_multistart_mode.R --name=<new> --outdir=<wave> --dest=…`, then Hessian, repoint, scorecard, suite re-pins — the 09-17 i four steps).
3. **The limb under #13** (`hilda_cl3`, prereg 09-17 k §4): now competes against a shim that FITS the slope at an unstrained γ — its case is physicality (ŵ inside [14, 25]), not fit. Only after 2.
4. If ruling (a) keeps the ML with the shim free: launch the free-parent #13 tree by hand.
5. `INDEX_ccx.md` over soft — split before the next entry. Carry-forward items unchanged from (g) §2.5.

## 3. Non-obvious state
- Both #13 wave outdirs carry `CCX_MS_TAG=20260918` (the tag is the LAUNCH design date, not the finish date); the control's outdir differs from the 09-17 j control wave's ONLY by `_w_enso_l2=0` in the pin label — do not confuse them when copying.
- `diag_obj13_refit_read.R` reports the 25-row (#12) and 26-row (#13) totals side by side; its verdict line reads the row alone ("BOUGHT" ≥ +1) against the same arm's #12 fit (`canonical` / `c1` / `fp1` by `O13_LABEL`).
- The perturbation scan's `GS_W1_NH/SH` are typed from the read; re-type them if the read is re-run on a different id.
