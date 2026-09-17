# Quarantine 2026-09-17 — `hilda30h` adopted

**Why here.** `hilda30h` (`calibration/output/refit_20260917_hilda30h_obj12_hilda_c/`) became the
canonical on 2026-09-17 (h): the first mode FITTED under objective #12 (the 09-16 e hygiene batch)
and the first on the `hilda_c` structure. The mode it replaces is not a bug's output — it is the
previous canonical, superseded — and is moved here so that no diagnostic resolves it as live state
while it stays resolvable by path for like-for-like reads (`CCX_MODE_HILDA30C_QUARANTINED`).

**What is here.** `refit_20260913_hilda30_cprime_pin_ent0/` = `hilda30c` (C′, 09-13 (d)): the
`hilda` structure, `seas_ml` 1, the shim `ent_seas_amp_SH` pinned at 0, 30 free names; FITTED under
objective #11 and RESTAMPED (not refit) under #12 on 09-16 (e) — its stored streams are #12's
(likelihood −1414.77 on the 25 rows; pinned logpost −1450.6873). Its Hessian block and the
promotion / Hessian logs travel with it. ⚠ Its stored `prior_z` for `h_hs` (+0.77) predates the
Holte prior; the live-table value is +2.02.

**The canonical replacement.** `calibration/output/refit_20260917_hilda30h_obj12_hilda_c/mode_fit_pumpN.rds`
(`CCX_MODE_CANONICAL = "hilda30h"`); the wave it came from is
`calibration/output/multistart_20260916_hilda_c_seasml1_pin_…_sd1.0452/` (24 Mac starts, read in
`outputs/diagnostics/hygiene_refit_read_20260917.log`, CHANGELOG 09-17 (h)).
