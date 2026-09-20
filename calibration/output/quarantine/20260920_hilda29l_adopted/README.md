# Quarantine 2026-09-20 — `hilda29l` adopted (the layer-3 Niño3.4 return limb on `hilda_cs`)

**Ruling (Marcus, 2026-09-20): "Adopt the limb."** The physical limb (`w_enso_l2` = 13.71 ± 2.13 Sv/index, Meinen's bracket
[14, 25] at 1 sd) replaces the two-coefficient ocean ENSO shim (`gamma_enso_ocn_NH/SH`, now pinned at 0) at an AIC tie.

- `refit_20260920_hilda30s_obj13_hilda_cs/` — **`hilda30s`**, canonical 09-20 (o) → (r): `hilda_cs`, the shim pair fitted at
  0.44/0.04, 30 names; likelihood −1390.2774 on 26 rows, logpost −1425.056641. Superseded by `hilda29l` (`hilda_csl3`, 29 names,
  −1391.8051 / −1425.362014; ΔAIC +1.06 for hilda30s — a tie). Resolvable by path as `CCX_MODE_HILDA30S_QUARANTINED`: the
  like-for-like "shim" arm of the canonical, and the point every 09-20 (o)–(q) read was taken at.
- The replacement: `calibration/output/refit_20260920_hilda29l_obj13_hilda_csl3/` (wave id 3 of
  `multistart_20260920_hilda_csl3_seasml1_pin_…_sd1.0452`; Hessian PD cond 2.40e5, no unstable direction; `w_enso_l2` ± 2.13,
  `h_ml` 57.3 ± 3.65 — the ridge). Read: `outputs/diagnostics/l2_array_read_csl3_20260920.*`; CHANGELOG 09-20 (q), (r).
