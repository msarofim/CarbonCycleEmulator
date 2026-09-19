# Quarantine 2026-09-19 — `hilda30e` adopted (objective #13), `hilda31pe` registered as the control

**Rulings (Marcus, 2026-09-19):** promote the canonical's objective-#13 refit; register the seas_ml-0 control's #13
refit as the control and let `test-mode-file`'s "canonical beats the control" gate stand as a NAMED RED.

## What is here and why
- `refit_20260917_hilda30h_obj12_hilda_c/` — **`hilda30h`**, canonical 09-17 (i) → 09-19: fitted under objective #12 on
  `hilda_c`, RESTAMPED (not refit) to #13 on 09-18 (e); stored streams are #13's 26 rows, likelihood −1402.2491,
  logpost −1436.6717. Superseded by its own refit under #13 (`hilda30e`: the ENSO ocean slope 0.35× → 0.94× GCB through
  `gamma_enso_ocn_NH` 0.36 → 0.45 alone, −0.37 on the other 25 rows). Resolvable by path as
  `CCX_MODE_HILDA30H_QUARANTINED` for a like-for-like read against every 09-17 i → 09-19 h record.
- `refit_20260910_hilda31_periodic/` — **`hilda31p`**, the registered seas_ml-0 control 09-10 → 09-19: a mode of the
  `hilda` structure under the 09-10 objective, restamped through #11/#12/#13, never refit under `hilda_c`. Its staleness
  manufactured the "+11.60 over the control" margin (09-18 a). Superseded as the control by `hilda31pe` (the #13 refit
  of the control's arm on `hilda_c`). Resolvable by path as `CCX_MODE_HILDA31P_QUARANTINED`.

## The canonical replacements
- `calibration/output/refit_20260919_hilda30e_obj13_hilda_c/` — `hilda30e` (wave id 1 of
  `multistart_20260918_hilda_c_seasml1_pin_ent_seas_amp_SH=0_…_w_enso_l2=0_sd1.0452`).
- `calibration/output/refit_20260919_hilda31pe_obj13_hilda_c_seasml0/` — `hilda31pe` (wave id 11 of
  `multistart_20260918_hilda_c_seasml0_pin_w_eq=27_…_w_enso_l2=0_sd1.0452`).
Reads: `outputs/diagnostics/obj13_{canonical,control}_refit_read_20260919.*`; CHANGELOG 09-19 (h), (i), (j).
