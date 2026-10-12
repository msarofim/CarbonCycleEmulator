# QUARANTINE 2026-10-12 — `diag_joos_irf.R` ran a different model from the one it names

## 1. The bugs (two, in `calibration/diag_joos_irf.R`; fixed in the commit that adds this README)

1. **The wrong spin-up.** It spun up every arm with `ccx_spinup(p0)`, the ASEASONAL spin-up. Every
   mode since the 09-09x periodic adoption is fitted, and run by the app, card 5 and gate L
   (`dg_vector()` → `ccx_spinup_from_label(ccx_mode_spinup(md))`), on the spin-up its own file names.
2. **A fitted parameter dropped.** Its overlay looped over `intersect(names(p0), CCX_PARAM_NAMES)` +
   `ccx_set_enso()`, which never writes the GATED fitted parameters. At `hilda29e` it ran with
   `ndep_ret = 0` (fitted 9.08): N-deposition retention OFF, since that parameter arrived (09-30).
   `ccx_overlay_par()`, which `dg_vector()` uses, writes the gated set and refuses a deleting overlay.

Size, at `hilda29e`, PD100 climate free (2026-10-12): the held 2010 background was **403.20 ppm**
with both bugs, **398.43** with the spin-up fixed, **393.62** with both fixed (= card 5).
IRF@100 0.386 → 0.383 → **0.379**.

## 2. Files

| file | produced | bugs |
|---|---|---|
| `joos_irf_canonical_20260927d.log` | 2026-09-27, arm `hilda29l` (then canonical) | 1 (spin-up). `ndep_ret` did not exist yet. Source of the "TH 13.04 / 25.80 / 41.80 at hilda29l" in memory and records. Also climate HELD (the protocol then). |
| `joos_irf_canonical_20261012_aseasonal_ndep0.log` | 2026-10-12, `hilda29e`, @6282b57 | 1 and 2 |
| `joos_irf_canonical_20261012_periodic_ndep0.log` | 2026-10-12, `hilda29e`, spin-up fixed | 2 |

## 3. The canonical replacement

`outputs/diagnostics/joos_irf_canonical_20261012.log` — both fixes, climate FREE (Marcus 2026-10-12),
with the HELD protocol's values printed beside it. It reproduces card 5 (`rv_pulse()`) exactly:
target 393.62 ppm; IRF 20/100/300 0.522 / 0.379 / 0.295 free, 0.509 / 0.361 / 0.272 held.

⚠ The nine HELD-ERA diagnostics (header "HELD-ERA RECORD (2026-10-12)") were NOT converted and may
carry either bug; they are records of what they printed, not the canonical's numbers.
