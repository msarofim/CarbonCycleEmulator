# Handoff — 2026-09-16 (b). **O5b (the HS pump on the rectified bloom) BUILT, PROBED and REFUTED as the SPO's mechanism — the pre-check called it before the run; the `h_ml` box floor is 42.5 m (a table change with a band term); THC parked; a suite trap (gitignored run input) found and gated. `hilda30c` canonical; nothing adopted.**

> Self-contained. HEAD = see `git log` (`4cc6fc3` = the probe; the floor commit follows it). CHANGELOG entry 09-16 (b). Memory:
> [[ccx_o5b_hs_rectified_bloom_0916b]]; NEW sub-index `INDEX_ccx_ocean_pump.md` (the kz/pump arc, split off `INDEX_ccx_ocean_cell` —
> now 13.3 KB; the pump index 7 KB); the floor/band term in `INDEX_ccx.md` (16.7 KB, over its 14 KB soft target — next add merges).
> Previous: `handoff_2026-09-16_o5_source_2x2.md`.

## 1. Rulings taken this session (Marcus, 09-16 b)
O5b: "yes: prereg, build, probe". `h_ml`'s box floor → 42.5 m (the Holte prior's 16 % point) for arrays. THC: PARK.

## 2. What happened, in order
1. **Prereg** `notes/prereg_2026-09-16b_o5b_hs_seasonal_export.md` (`0b38756`). The pre-check from the canonical's numbers: the HS SH box's
   air–sea coefficient k_w·asx_hs·K₀ = **0.0306 GtC yr⁻¹ µatm⁻¹** caps the SPO first-harmonic gain at **≤ 0.04 ppm** of the 0.251-ppm deficit
   left after O5-at-source; closing it through HS needs a **55-µatm** HS pCO₂ amplitude = **3.4×** SOM-FFN's 16.3 (40–90 °S) ⇒ the SPO and
   SO-pCO₂ rows have JOINT POWER. Rule stated in ppm / µatm (the 09-15 g lesson).
2. **Build** (`31dc887`): `pump_hs_seas_amp` [0, 1] / `pump_hs_seas_lag` (structural; both cores; bit-exact off). `s_hs = 1 + amp·(F_h − 1)`,
   `F_h` = `ccx_mld_fourier()` of the CMIP6 unit-mean HS median shape, read once via `ccx_export_hs_seas_shape()` into
   `aux$hs_export_seas_coef` (NOT `pump_hs_*` — `aux$pump_hs` is a prefix; partial-matching trap when the pump is off). Precedence: 0 = O5's
   sine on the HS pump exactly; > 0 replaces it on the HS pump only. `test-pump-hs-seas.R` 100/100; `test-pump-seas.R` 114/114.
3. **Probe** `calibration/diag_o5b_hs_seasonal_export.R` → `outputs/diagnostics/o5b_hs_seasonal_export_20260916.{log,rds}` (`4cc6fc3`). Gates
   1/2/4 PASS (gate 2 = the O5 cell reproduces the 2×2's −797.6 raw: the precedence contract measured). Raw amp 1: SPO amplitude 0.302 →
   0.292 / 0.307 ppm (lag 0 / −1); HS SH pCO₂ 0.53 → 9.1 µatm @ month 9.9 (predicted 8.9 @ 9–10). **Arm C** (the PK-2 eight, `h_ml` band
   [42.5, 200] in process): O5 cell **−194.9** (h_ml 48.8; the 2×2's −194.7 reproduced under the new band) → amp 1 lag −1 **−179.7**
   (SPO amplitude 0.334 → 0.336; phase + MLO bought the +15), amp 1 lag 0 −191.2 (0.321). **VERDICT: REFUTED** — (a) < 0.03 ppm, (d) < +20;
   (b) 8.8 ≤ 33 µatm and (c) phase PASS. Control (canonical, solved field): amp 1 costs −7.7 (SPO −3).
4. **The reading.** The SPO deficit's home is NOT the HS pump under this geometry (the box's exchange per µatm is 4× the LS SH ML's smaller
   on a quarter of the area). It is the LS SH mixed layer: the martin field FLIPS its pCO₂ cycle from a winter peak (canonical 10.8 µatm
   @ 7.5, the SO obs phase) to a summer, T-driven one (8.5 @ 2.4) — the inverted sub-ML gradient seen from the surface.
5. **The `h_ml` floor** (its own commit, after the probe): `CCX_PARAM_TABLE$h_ml$lo` = `CCX_HML_FLOOR_M` = 42.5. Jacobian shifts: canonical
   −0.362, `hilda31s2` −0.368, `hilda31p` −2.105 (44.09 m); likelihood untouched. `ccx_mode_start()` carries a BAND TERM in `logpost_shift`
   (recorded `hml_bound` ≠ live table) so every gate 4 closes without restamping. `test-hml-floor.R` 16/16 (mutation: without the term
   the canonical fails by 0.36). `test-mode-decode.R`'s canonical invariant restated (band-blind decode is now WRONG for the canonical:
   75.1 vs 65.2 m; `ccx_check_mode_decode()` ERRORS band-blind; adopt the band THEN check — the two callers reordered). Port targets
   regenerated (`CCX_MS_STRUCT=hilda CCX_MS_SEAS_ML=1`; incumbent `hilda31s2`, offset −3.96; `hilda31p` −138.6 at seas_ml 1).
6. **The suite trap.** First suite (frozen copy WITHOUT `data-raw/downloads`): 3637 / 20 / 6 + 1 — twenty "canonical streams reproduce"
   failures incl. files that passed in the tree. A/B on a worktree at the pre-O5b commit: same failures; real tree: PASS; inputs md5-identical.
   Cause: `ccx_nuclear_c14_annual()` reads the gitignored `data-raw/downloads/nuclear14c/` at run time and silently zeroes the source (the
   three ¹⁴C rows move 0.37 / 1.23 / 0.02). `tests/testthat/setup.R` now runs `ccx_require_run_inputs()` first. Counting run on the
   committed tree (with the inputs): **3674 / 2 / 6 + 1 error = the standing reds only** (`outputs/diagnostics/suite_20260916b_counts.log`).

## 3. Open, and the rulings owed
- **The honest next candidate is on the LS SH mixed layer's seasonal pCO₂ phase** (winter under the solved field, summer under martin),
  i.e. the sub-ML gradient the martin field inverts — not more high-latitude export. No prereg written; Marcus's call whether to pursue the
  martin arc further or park it (⇒ O2's DESIGN §6 statement).
- THC parked (`w_thc` prior source still owed if ever revived). T5 / the cell / `hilda_c` arm still parked.
- The 1995 bomb inventory z +4 everywhere and the layer-2 inversion under martin: unmoved by every candidate.
- `INDEX_ccx.md` is 16.7 KB (soft 14): merge before the next add.

## 4. Non-obvious state
- `pump_hs_seas_amp` / `_lag` are STRUCTURAL (on `p`, default 0, marshalled by name, not in the table); `aux$hs_export_seas_coef` is built
  whenever the HS pump is on (cached read of the CMIP6 rds) and is inert at amp 0.
- Any diagnostic that compares a stored logpost must go through `ccx_mode_start()` (the band term) or `ccx_adopt_mode_band()`; the
  band-blind `ccx_unc_to_par(md$u_mode)` is wrong for EVERY pre-09-16 file now, the canonical included.
- A frozen copy for a suite run MUST carry `data-raw/downloads/nuclear14c/` (rsync `--exclude 'data-raw/downloads/*'` then copy it in).
- `calibration/torch/port_targets.csv` is regenerated for the canonical objective (struct hilda, seas_ml 1, no pins); any array
  regenerates for its own pins/struct.
- Untracked, disposable: the two `_smoke` outputs (O1, O5) and `port_gate_id1_20260914.log`.
