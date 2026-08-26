# refit_20260825f — the post-isotope-fix refit, 3 arms

**Pre-registration: `notes/prereg_2026-08-25f_post_isotope_fix_refit.md`, written before launch.**

Launched 2026-08-25f after commit `6bda464` (seasonal-NEP double discrimination fixed in both
cores). **The objective changed with that commit**, so nothing fitted before it is comparable and
every pre-fix vector is in `calibration/output/quarantine/20260825_seas_isotope_rectification/`.

| arm | dir | pin | seed | warm-start logpost under the NEW objective |
|---|---|---|---|---|
| reference | `refit_20260825f_ref` | none | the quarantined arm-N mode | **−1909.0** (its file says −1859.3, the OLD objective) |
| free-from-90 | `refit_20260825f_from90` | none | K = 90 ridge cell, enh(420) = 0.207443 | −2457.5 |
| pin90 | `refit_20260825f_pin90` | `fert_k` = 90 | same cell | −2445.9 (includes the near-delta prior offset) |

`ref` becomes the canonical mode when it lands. Until then there is none.

**Read the prereg's P1–P5 before reading any number out of these directories**, and remove the pin
offset before comparing `pin90`'s logpost to a free arm's. `h_ml` is bounded to [85, 120] by the
driver and must be restored before recomputing anything from these files (memory
`ccx_hml_band_provenance`).
