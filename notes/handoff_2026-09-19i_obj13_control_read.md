# Handoff — 2026-09-19 (i). **Both objective-#13 refits READ: each arm buys the ENSO ocean slope (0.3× → 0.94× GCB) through `gamma_enso_ocn` alone for < 0.5 log-units on the other rows, and the ordering does not move — refit against refit under #13 the seas_ml-0 CONTROL beats the canonical by +10.22 on 26 rows. The row's diagnosis is CLOSED. Nothing is running; the Mac is free. THREE RULINGS are owed.**

> Self-contained with handoffs (g) `handoff_2026-09-18g_test_a_read.md` (test (a): the ML costs ~6 vs the ML + shim-free arm) and (h) `handoff_2026-09-19h_obj13_canonical_read.md` (the canonical's #13 read + the linearity scan). Session record: CHANGELOG 09-19 (h), (i); memory [[ccx_obj13_canonical_refit_read_0919h]], [[ccx_obj13_control_refit_read_0919i]]; `INDEX_ccx.md` back to **13.5 KB** (two closed paragraphs moved 09-19 i: objective #12's content → `INDEX_ccx_ref.md` (6.7 KB), the #12 refit-read record → `INDEX_ccx_arch_modes.md` (**16.2 KB — over soft, under hard**)).
> **NOTHING IS RUNNING.** The chain ended 13:19 (both #13 waves 24/24 exit 0; `chain.pid` removed). Frozen trees under `~/ccx_frozen/` are disposable — every outdir is copied into the repo — EXCEPT `20260918f_free_parent_obj13_refit/`, staged and never fired (`./launch_now.sh`; preflight 24/24 on 09-18). Torch reserved for FrEDI through ~09-19.

## 1. The #13 like-for-like set (26 rows; `diag_obj13_refit_read.R`)
| arm | names | 26-row likelihood | slope (× GCB) | `gamma_enso_ocn` NH / SH | `h_ml` | shim |
|---|---|---|---|---|---|---|
| canonical `hilda30h` (#13 stamp, unrefit) | 30 | −1402.25 | 0.35 | 0.36 / 0.00 | 64.7 | 0 (pinned) |
| **canonical's #13 refit** (wave id 1) | 30 | **−1397.93** | 0.94 | 0.45 / 0.015 | 64.7 | 0 (pinned) |
| **control's #13 refit** (wave id 11) | 31 | **−1387.71** | 0.94 | 0.42 / 0.063 | 49.5 | 18.02 |
| fp1, test (a) (a #12 fit, unrefit under #13) | 31 | −1398.09 | 0.34 | 0.37 / 0.00 | 49.4 | 9.13 |

Both refits: +4.7 / +5.1 on the row, −0.37 / −0.46 on the other 25, nothing but the ENSO pair moved. Chain H/GL/Q FAIL, 7/S PASS at every arm; GATE V z −4.8 everywhere (the slope is bought, the interannual variance is not). The slope is linear in the shim (0.633·γ_NH − 0.187; `enso_slope_gamma_scan_20260919.*`).

## 2. What to do next — the rulings (Marcus), then the work each implies
1. **The seasonal ML:** a mechanism (round 6, `INDEX_ccx_seas_ml.md`) that costs ~6 log-units against the ML + shim-free arm (test (a)) and ~10 against ML-off at the pinned canonical, under BOTH objectives, on the NH seasonal rows (`d13c_seasonal_MLO`, `co2_seasonal_MLO`). Keep as mechanism / drop / keep with the shim free — a ruling, not a number. If "keep with the shim free": fire the staged free-parent #13 tree (~6 h) so the set has three refit arms.
2. **The registered control and `test-mode-file`'s "canonical beats the control" gate:** the control's #13 refit (id 11) beats the canonical's; registering it as `CCX_MODE_SEASML0_CONTROL` fails the gate as written. Either the gate is re-ruled (the control is allowed to win, and the canonical's case is the mechanism) or the canonical changes (ruling 1).
3. **Promotion:** the canonical's #13 refit (wave id 1 — `promote_multistart_mode.R --name=<new> --outdir=<the canonical wave> --dest=calibration/output/refit_20260919_<new>_obj13_hilda_c`, then `recompute_hessian.R --update`, repoint `R/paths.R`, scorecard, suite re-pins with reasons — the 09-17 i four steps) — OR the control's arm as canonical (a structural re-ruling of round 6, needs 1 first). Under ruling 1 = "drop the ML", the control's refit (id 11) is the candidate and the free parent / control roles need re-cutting in `ccx_ms_reference_set()`.
4. **The limb under #13** (`hilda_cl3`, prereg 09-17 k §4, `INDEX_ccx_ocean_cell`'s successor arc): it now competes against a shim that FITS the slope at an unstrained γ (z +0.22), so its case is physicality (ŵ inside Meinen's [14, 25]) and GATE V, not fit. Regenerate port targets for `CCX_MODE_L2_ARM_PINS` under #13 first (the 09-17 l tree is #12). Only after 1–3 fix which arm it sits on.
5. Carry-forward unchanged (handoff e §2.5): the E array's start count 22; the shim's `co2_gradient` job; `sacct`'s phantom; the σ-audit items (a)–(c); indexes over soft (`INDEX_cmp_pulse` 17.1, `INDEX_slr` 17.0, `INDEX_diag` 16.3, `INDEX_ccx_arch_modes` 16.2, `INDEX_ais` 15.0 KB).

## 3. Non-obvious state
- `ccx_mode_file()` → `hilda30h`, #13-stamped; its refit is READ, not promoted. `calibration/torch/port_targets.csv` = the free-parent arm under #13 (`b8438c8`).
- The two #13 outdirs carry `CCX_MS_TAG=20260918` (the launch-design date); the control's differs from the 09-17 j control wave's ONLY by `_w_enso_l2=0` in the label.
- `diag_obj13_refit_read.R` (`O13_DIR` / `O13_LABEL=canonical|control|free_parent` / `O13_SUB`) prints the 25-row (#12) and 26-row (#13) totals side by side; its verdict reads the row alone against the same arm's #12 fit. `diag_enso_slope_gamma_scan.R` types the w1 pair from the read.
- Which of NH/SH carries the slope differs by arm (near-degenerate; SH adds ~0.9/unit at the canonical) — not a finding.
