# App run-time proof at hilda31w (2026-10-13, CHANGELOG 10-13 m)

Marcus: "Yes, start the app on hilda31w". This is the RUN-TIME half of CHANGELOG 10-12 (hh), whose static argument
was that every app forcing carries the WTC label's `nuc_share` (handoff 10-13b §4 step 4: "Before any live app run,
start the app on hilda31w").

## 1. Headless: `app_nuc_proof.R` → `app_nuc_proof.log` (12 / 12 PASS, @5c57add)

It loads the app's own objects (`shiny::loadSupport`, as `calibration/diag_app_ssp585_ref.R` does) and checks:
- the app loads hilda31w (mode md5 `53ee816a…`), and the label asks for `per_year`, so an unstamped table would NOT pass by default and the guard has power;
- `bomb_share_NH` 0.8417 and `seas_T_lag` 0.2760 in the app's spin-up equal `ccx_mode_params()`;
- `APP_HIST`'s forcing is stamped `per_year`, and its `nuc_share_NH` column is per-year (27 distinct values, 0.942–1.000);
- the flux trace's row subset keeps the stamp and the column, and `APP_FLUX` is finite (this feeds the pure-R core, which has NO `nuc_share` guard of its own and reads the column);
- `app_build_forcing("vvM")` is stamped; `app_run_coupled("vvM")` runs to 2300 at 576.63 ppm, the same as the futures-stake driver's f = 1 vvM (576.630) by an independent path;
- MUTATIONS: a table with the stamp stripped, and one stamped `"constant"`, are both REFUSED by `ccx_nuc_share_check()` ("nuclear 14C share mismatch").

## 2. Live: a fresh app on :7790 (launch config `ccx-app-7790`), every tab visited

- All 8 tabs and the 3 Futures sub-tabs render with no `.shiny-output-error`. The Pulse lab ran at its defaults (the ¹⁴C-tag path).
- The Pulse lab's box prints 0.135 °C, **1.35 °C per 1000 GtC**, a 2.1 % spread, "about 1.4": the rebuilt constants. The parameter table shows both new names with their ruled labels and no bug banner. The futures band is HELD by design (`APP_RIBBONS_HOLD`).
- Server log, all pre-existing or transient:
  - "figure margins too large" on `k_plot` / `k_seasonal`, once, at the first page load into a hidden pane. A reload rendered both plots (733×380, 733×260) with no new warning.
  - ggplot "Removed 10 rows" ×3: the hilda29e instance on :7788 logs the same three.
  - "Ignoring unknown parameters: `label.size`" (`app/R/plots_review.R:94`, card 1, since 09-22). ggplot2 4.0.2 ignores the parameter, so that label likely gets a default border. Flagged, not changed.
