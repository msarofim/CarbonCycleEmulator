# Handoff — 2026-09-20 (n). **Ruling 1's test answered: H_DRIVER. The `hilda_cs` refit (the seasonal mixed layer's NH cycle FLAT, SH cycle on) recovers the NH seasonal δ¹³C row entirely and lands +7.65 over the canonical on the same 30 names — within 2.6 of ML-off at one fewer name. The ML's price was its NH driver, not the mechanism. Nothing is running; the Mac is free. Rulings owed: adopt `hilda_cs`; the mechanism at −2.6; the limb's arm.**

> Self-contained with handoffs (i) `handoff_2026-09-19i_obj13_control_read.md` (the #13 like-for-like set, the three rulings) and the CHANGELOG 09-19 (j)–(m), 09-20 (n). HEAD = `647d084`+. Memory: [[ccx_hilda30e_adopted]], [[ccx_hilda_cs_structure]] (updated with the read), [[ccx_obj13_canonical_refit_read_0919h]], [[ccx_obj13_control_refit_read_0919i]]; `INDEX_ccx.md` 14.3 KB (at soft). **NOTHING IS RUNNING.** Frozen trees under `~/ccx_frozen/` are disposable (every outdir is in the repo) except the never-fired `20260918f_free_parent_obj13_refit/`. Torch was reserved for FrEDI through ~09-19 — check before using it.

## 1. State of the registry (09-19 j → m)
- **Canonical `hilda30e`** (the canonical's #13 refit: hilda_c, ML on both hemispheres, 8 pins incl. `w_enso_l2 = 0`, 30 free; likelihood −1397.93 on 26 rows; slope 0.94×). **Control `hilda31pe`** (the control's #13 refit: ML off, shim free 18.0, 31 names; −1387.71). `hilda31s2` the (stale, `hilda`/#12) free parent. `hilda30h` / `hilda31p` quarantined by path.
- **Two NAMED REDS in `test-mode-file` by ruling 2 (b)**: the control beats the canonical by 10.21; the best free arm is the control, not the parent. Suite on a full copy of `0dbfdb4`: **3958 / 4 / 9 + 1 error** = the GATE Q pair + `test-seas-lag-split:205` + the two named reds.
- Promoter now stores the OBJECTIVE's streams (gate 5 keeps its hand path); `ccx_inert_names()` / `ccx_mode_pinned()` (a file with only inert pins is a free arm); `ml_nh_cycle` (renamed off the `seas_ml` prefix — `p$seas_ml` partial-matched it); counting copies are FULL tree copies, not the bundle.

## 2. The `hilda_cs` result (09-20 n; `outputs/diagnostics/hilda_cs_refit_read_20260920.*`)
| arm | names | 26-row likelihood | `d13c_seasonal_MLO` | `sst_seas_amp_NH` | `h_ml` |
|---|---|---|---|---|---|
| canonical `hilda30e` (ML both) | 30 | −1397.93 | 200.91 | 2.44 | 64.7 |
| **`hilda_cs` w1 (ML SH-only)** | 30 | **−1390.28** | **208.07** | **1.68** | 58.0 (ridge 50–64, 0.43 wide) |
| control `hilda31pe` (ML off) | 31 | −1387.71 | 208.12 | 1.71 | 49.5 |

The SH cycle pays `d13c_seasonal_SPO` −0.38 / `ocean_grad_alk` −1.15 vs the canonical; gate S PASS (0.286 @ 8.98); slope 0.94× kept; chain unchanged. 21/24 converged, one `h_ml` ridge in three sub-modes (58.0 / 63.7 / 49.9 within 0.43): **`h_ml` is barely identified with the NH cycle flat — Hessian before any promotion.**

## 3. What to do next (rulings, then the work each implies)
1. **Adopt `hilda_cs`?** Promote wave id 0 (`promote_multistart_mode.R --name=<new> --outdir=<the hilda_cs wave> --dest=…`; the promoter now writes objective-path streams), `recompute_hessian.R --update` (read the `h_ml` direction: a ridge 0.43 log-units over 14 m may be step-unstable), repoint `R/paths.R` (canonical + `CCX_MODE_CANONICAL_PINS` unchanged; the structure moves to `hilda_cs`), scorecard, suite re-pins with reasons (named red #2 shrinks to −2.6 and stays red; the demean price moves). DESIGN.md §3.4 then records the shipped model as SH-only entrainment.
2. **The mechanism at −2.6 on one fewer name** (AIC-style within noise; ML-off +1.6 net): keep as mechanism (recommended — the round-6b case is restored: likelihood-neutral to 2.6, priors relieved, P7/gate S pass, physical entrainment where the climatology is right) or drop. If kept, the "canonical beats the control" gate could be re-cut to a like-for-like MARGIN with an AIC allowance — a ruling, not a re-ruling to pass.
3. **The limb (`hilda_cl3`) under #13** now sits on top of `hilda_cs` if 1 is yes: a `hilda_csl3` label (hilda_cs + the limb) is the arm; its case is physicality + GATE V, since the shim already fits the slope.
4. The free-parent #13 tree (`20260918f_free_parent_obj13_refit`) is moot under 1 = yes (its arm has ML both + shim free); delete or re-stage on `hilda_cs`.
5. Carry-forward: `INDEX_ccx_arch_modes` 16.7 KB (over soft); the σ-audit items (a)–(c); the E array's start count; indexes over soft (`INDEX_cmp_pulse`, `INDEX_slr`, `INDEX_diag`, `INDEX_ais`).

## 4. Non-obvious state
- `diag_obj13_refit_read.R`'s verdict line asks "did the row get bought" — the wrong question for a wave whose incumbent already bought it; read sections 1–3, not the verdict, for `hilda_cs`-type waves.
- The two-path 1e-8 relative difference (objective path vs `dg_run`) comes from the encode/decode round trip's 1-ulp move amplified by the periodic spinup; reads use 1e-3, the stored streams are the OBJECTIVE's path, `test-gcb-enso-slope` tolerates 1e-6.
- An old `git stash` (`stash@{0}` from 88c314f, weeks old) is still in the list — not mine; do not pop it.
