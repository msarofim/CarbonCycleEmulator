# Handoff — 2026-09-14 (i). **The E array is LAUNCHABLE: the `w_vent` prior sourced (Liu & Huang 2012 / the climatologies: 284 Sv, log-sd 0.575), the constants batch ruled and built as `hilda_c`, `pump_field` threaded through the whole array kit, port targets regenerated, Mac preflight VERIFIED at 0.174 s/eval. NOT submitted — Torch (say it aloud). Nothing adopted; `hilda30c` canonical.**

> Self-contained. HEAD = the commit carrying this note. CHANGELOG 09-14 (h) "THE ARRAY PREP". Memory: [[ccx_option_e_built_probe]]
> updated (in `INDEX_ccx_ocean_cell` — NEW, split off `_circ` this session); ⚠ root `MEMORY.md` is 18.28 KB of an 18.43 KB hard
> ceiling: RESTRUCTURE THE ROOT before adding a line. Previous: `handoff_2026-09-14h_option_e_built_probed.md`.

## 1. Done this session (commits `4c7be1c` … `dc06e96`)
1. `INDEX_ccx_ocean_circ` split: the live arc → `INDEX_ccx_ocean_cell.md`; CLAUDE.md registry + root pointer updated.
2. **`w_vent` prior sourced** (`0928beb`): global subduction into the permanent pycnocline, ~160 (climatologies) vs 505.8 Sv (SODA;
   Liu & Huang 2012, doi:10.1175/2011JCLI4228.1 — the ~160 comparison is THEIR p. 1099). Lognormal 284 / 0.575, box [0, 1500].
   Probe at the prior's readings: **γ 0.5 flips the ENSO slope unrefitted — +0.75× at 284 Sv (r = the canonical's +0.254)**.
3. **Constants batch ruled + built** (`dc06e96`): `hilda_c` = hilda + `sst_NH/SH` 22.3/18.7 (WHOLE-LS re-based — ⚠ the review's
   17.18/15.35 was the residual ML, wrong box) + `hs_frac` 0.128 + `alpha_photo_eps` 15.6 (base parameter; absent = ledger 18).
4. **Array kit** (`e6e0d4f`): `CCX_MS_PUMP_FIELD` read / recorded / gated / in the outdir; inert names refused free; the extend-
   canonical pin rule; sbatch + setup_torch (now pin-aware). `port_targets.csv` under hilda_c / seas_ml 1 / martin / 4 pins.

## 2. THE LAUNCH (session 3) — exactly these, from `calibration/torch/multistart.sbatch`'s 09-14 (h) block
```
CCX_MS_STRUCT=hilda_c CCX_MS_SEAS_ML=1 CCX_MS_PUMP_FIELD=martin CCX_MS_PIN=ent_seas_amp_SH=0,pump_grad=314.1031,gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0 CCX_MS_PREFLIGHT=1 sbatch --array=0-23 --time=00:15:00 calibration/torch/multistart.sbatch
CCX_MS_STRUCT=hilda_c CCX_MS_SEAS_ML=1 CCX_MS_PUMP_FIELD=martin CCX_MS_PIN=ent_seas_amp_SH=0,pump_grad=314.1031,gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0 sbatch --array=0-23%24 calibration/torch/multistart.sbatch
```
Before: `make_bundle.sh` → ship → `setup_torch.sh` with the SAME four env vars exported (its gate now needs CCX_MS_PIN too) → the
Torch preflight (re-read s/eval there; the Mac's 0.174 is not Torch's) → the wave. After: `collect_dispersed_multistart.R`,
`promote_multistart_mode.R` (carries `pump_field`), then read PE-1..PE-4 at the mode:
PE-1 kz < 4,000 with the bomb rows within 2; PE-2 gradient 233 ± 29 at export in 6.8–12.1; PE-4 δ¹³C gradient 0.40 → 0.89;
then E5: the cell re-read (`hilda_eq`'s block + the batch — ⚠ no `hilda_eq_c` label exists yet; compose one when needed).

## 3. Owed / open
- The σ-audit three; whether DESIGN §6 stands (unchanged).
- The root `MEMORY.md` restructure (18.28 of 18.43 KB).
- `hilda_c` carries the batch for `hilda` only; `hilda_eq` / `hilda_tr` keep their own SST overrides (residual ML) — the cell
  re-read needs a composed label.

## 4. Suite (`outputs/diagnostics/suite_20260914h2.log`)
**3349 pass / 3 fail / 2 skip = exactly the standing pair (GATE Q, `test-alpha-as`) + the 08-30 arm error
(`test-seas-lag-split:205`).** `test-option-e.R` 86/86, `test-constants-batch.R` 33/33 included.

## 5. Non-obvious state
- `port_targets.csv` is now the E arm's (hilda_c/martin/4 pins); any other array must regenerate it first (the gate refuses).
- Standing reds: the GATE Q pair (`test-alpha-as`) and `test-seas-lag-split:205`.
