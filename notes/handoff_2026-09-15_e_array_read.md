# Handoff — 2026-09-15. **THE E ARRAY IS READ (Torch 17839702): one mode at −1480.4720 (10 of 24 starts agree); OPTION D + E AS BUILT FAILS ITS OWN PREREG — PE-1 FAIL (kz ×1.27, not > 2.7×), PE-2 FAIL (DIC gradient 346.6 vs 233 ± 25, worse than the canonical), PE-4 unmoved, PE-5 0.36× obs; bomb rows pass; −37.5 log-units like-for-like vs `hilda30c`. The PI layer-2 DIC inversion SURVIVED the refit and is real. Nothing adopted; NOT promoted; `hilda30c` canonical. RULINGS OWED.**

> Self-contained. HEAD = the commit carrying this note (`ce94ced` + memory). CHANGELOG 2026-09-15 and 09-14 (i). Memory:
> [[ccx_option_e_array_read]] (new, in `INDEX_ccx_ocean_cell`, 12.8 KB), [[port_gate_tolerance_below_roundoff_floor]] (new, in
> `INDEX_diag`, 15.7 KB — over soft). ⚠ Root `MEMORY.md` is 18.28 KB of an 18.43 KB hard ceiling: RESTRUCTURE THE ROOT before
> adding a line. Previous: `handoff_2026-09-14j_e_array_preflight_queued.md` (the launch), `_14i_` (the prep).

## 1. This session, in order
1. Bundle → Torch; `make_bundle.sh` had shipped without the ent26 column control since 09-08 (the registry check tested Mac
   existence, not tarball membership) — fixed + membership gate, mutation-tested (`efeaaaa`).
2. Setup gate PASSED (rel 3.5e-11). Preflight 17818291 queued 4.7 h at FairShare 0.19; 23/24 LAUNCHABLE, **id 1 FAILED port gate (a)
   at the incumbent, rel 2.16e-8 vs 1e-8**. DIAGNOSED on both machines: NOT a discrete flip (same substeps, same Newton history,
   Torch self-reproduces to 1e-14); the objective's own roundoff floor is POINT-DEPENDENT, 20–40× larger there (max 3.5e-5 Mac /
   8.7e-5 Torch, flat across ε), carried by the δ¹³C level rows. **Marcus ruled option A**: gate (a)'s bound = max(1e-8·|target|,
   3 × measured floor), ceiling 1e-6 relative → CANNOT-BE-APPLIED stop; mutation-tested (`bf03507`). Re-preflight PASSED.
3. **WAVE 17839702** (`13cf3ff`): 24/24 exit 0 in 4:13–5:15; 23 hit the 300-min wall (cs661 contention) but ten starts agree to 1e-4.
4. **READ** (`ce94ced`): `calibration/diag_option_e_array_read.R` → `outputs/diagnostics/option_e_array_read_20260915.{log,rds}`;
   collector `outputs/diagnostics/e_array_collect_20260915.log`; profile reader check `diag_option_e_array_profile_reader.R`.

## 2. The result (numbers in the memory file and CHANGELOG; the read log has every row)
| | canonical `hilda30c` (solved) | E mode (id 14) | incumbent basin (id 1) |
|---|---|---|---|
| logpost (own objective) | −1426.24 | −1480.47 | −1488.00 |
| loglik, 25 rows | −1392.0 | **−1429.5** | −1440.8 |
| kz / deep frac / h_ml | 10,964 / 0.012 / 65.2 | **8,615 / 0.089 / 38.2** | 6,811 / 0.147 / 74.8 |
| export GtC/yr | 45.5 (solved, gross) | 8.35 (Martin) | 6.62 |
| w_vent / gamma_vent | — | 243 Sv / 0.36 | 217 / 0.30 |
| modern DIC gradient (233 ± 25) | 302.9, z +2.8 | **346.6, z +4.5** | 340.3 |
| δ¹³C gradient / GATE GL | 0.350 / 1.97× | 0.320 / 2.02× | 0.362 / 2.06× |
| ENSO ocean slope | 0.58× obs (option A) | 0.36× (loop) | 0.46× |
| PI layer-2 − ML DIC | +5 | **−66** (real; winter ML 64 m < layer-1 base 91 m) | −66 |
Prior-tail leans at the mode: `hs_asx_frac` z +4.1, `pump_hs_gcm2` +3.0, `rep_dC` +3.7, `sst_seas_amp_SH` −3.3, `q10` −2.6.

## 3. Rulings owed (Marcus)
1. **Option E's fate** — refuted as built by PE-1/PE-2/PE-4.
2. **Promotion** — recommend NOT (a PE-1/PE-2 FAIL is not a canonical; the 09-14 c `hilda30e` precedent). The start files are the record.
3. **The constants batch alone** — `hilda_c` rode in this array; a `hilda_c` / solved-field arm (same pins minus `pump_grad`, 33 free)
   would price the batch (~−290 at the canonical vector) as a REFIT, separately from the field. Cheap: one array.
4. **Next** — T5 (the tropical column) per ruling E5, or the kz/pump STRUCTURE the 09-14 g review named root cause (1), now with the
   measured fact that prescribing the export is not the lever. PE-3 unread (needs a composed `hilda_eq` + batch + martin label).

## 4. Non-obvious state
- `port_targets.csv` is the E arm's (hilda_c / martin / 4 pins); regenerate before any other array (the gate refuses otherwise).
- The driver's gate (a) now MEASURES its floor (12 evals, ~6 s/task); `port_floor` / `port_tol` / `port_diff` are in every start file.
- Torch tree `/scratch/ms17839/CarbonCycleEmulator` = `bf03507`'s R/src/data + `calibration/`; the outdir there is a copy of what is
  committed here. `logs/torch_17839702/` holds the 24 wave logs + the two preflights' (17818291, 17839654).
- Standing reds unchanged: GATE Q pair (`test-alpha-as`), `test-seas-lag-split:205`. Suite NOT re-run this session (driver-only change;
  no test covers `run_dispersed_multistart.R` — the three CSV mutations are its test record).
- `/scratch/ms17839/tmp/ccx_setup_*` / `ccx_diag_*` dirs on Torch: trap-removed; check for strays.
