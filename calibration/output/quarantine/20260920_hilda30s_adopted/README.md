# Quarantine 2026-09-20 — `hilda30s` adopted (the `hilda_cs` structure: the seasonal mixed layer's NH cycle FLAT)

**Ruling (Marcus, 2026-09-20): "yes for all 3"** — adopt `hilda_cs`; keep the mechanism; the limb next on top of it.

- `refit_20260919_hilda30e_obj13_hilda_c/` — **`hilda30e`**, canonical 09-19 (j) → 09-20: the canonical's objective-#13 refit on
  `hilda_c` (the ML cycling in BOTH hemispheres), likelihood −1397.9253 on 26 rows, logpost −1432.393791. Superseded by
  `hilda30s` = the SAME 30 names and 8 pins refit under `hilda_cs` (the NH cycle flat, SH on): −1390.2774 / −1425.056641,
  **+7.65 on the same scale** — the NH seasonal δ¹³C gap to ML-off recovered entirely (`d13c_seasonal_MLO` 200.91 → 208.07)
  through `sst_seas_amp_NH` 2.44 → 1.68. Read: `outputs/diagnostics/hilda_cs_refit_read_20260920.*`; CHANGELOG 09-20 (n), (o).
  Resolvable by path as `CCX_MODE_HILDA30E_QUARANTINED` — every 09-19 j → 09-20 n record was taken at it.
- The replacement: `calibration/output/refit_20260920_hilda30s_obj13_hilda_cs/` (wave id 0 of
  `multistart_20260919_hilda_cs_seasml1_pin_ent_seas_amp_SH=0_…_w_enso_l2=0_sd1.0452`; Hessian PD cond 2.42e5, **`h_ml`
  step-UNSTABLE at 3.0 %** — the ridge 50–64 m within 0.43 log-units; recorded, not gated).
