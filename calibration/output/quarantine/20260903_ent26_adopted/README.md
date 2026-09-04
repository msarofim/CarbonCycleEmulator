# QUARANTINE 20260903_ent26_adopted — the 21-parameter arms

Moved 2026-09-04, when `ent26` became `CCX_MODE_CANONICAL`.

## 1. WHY THESE ARE HERE

**NOT a bug — a deliberate change of PARAMETER SPACE.** Three splits took the
fitted set from 21 names to 26 in five days:

| date | commit | change | count |
|---|---|---|---|
| 2026-08-31 | `11ff844` | `seas_lag_p` split per hemisphere | 21 → 22 |
| 2026-09-01 | `71155ad` | ENSO response split four ways (land/ocean × NH/SH) | 22 → 25 |
| 2026-09-03 | `88ee23c` | `ent_seas_amp_SH` freed (Fix A: SH ocean entrainment) | 25 → 26 |

⇒ **Everything here was fitted on a 21-parameter space and is NOT a mode of the
current one.** `ccx_migrate_par_set()` can still say what these vectors RAN —
and that is the right thing to do when MEASURING at them — but they cannot be
**encoded**: under `tr = "log"` the migrated `ent_seas_amp_SH = 0` has prior
probability ZERO, not merely an awkward coordinate. `ccx_par_to_unc()` refuses
it by name.

⚠ Two OBJECTIVE changes also separate them from anything fitted since
(2026-09-02: temperature-dependent air-sea ¹³C alphas, and the one-way ENSO GPP
modulation with `FORC_ENSO_DEMEAN`). So their stored logposts cannot be
differenced against a current one either — on **two** independent grounds.

## 2. WHAT IS IN HERE

- `refit_20260825f_from90/` — the FREE arm, `CCX_MODE_CANONICAL` from
  2026-08-26 to 2026-09-04. Stored logpost −1544.615, `fert_k` 154.85,
  `h_ml` 96.47 m (its `u_mode` decodes to 85.73 m under the default band —
  the band-provenance trap; `par_mode` is the band-independent field).
- `refit_20260825f_pin90/` — the `fert_k`-PINNED comparison arm.

⛔ **The +11.6698 pinned-prior credit is deliberately NOT preserved.** It was
never an observational or physical quantity: it is the value of a near-delta
prior this project chose, evaluated at a `fert_k` this project chose. A
threshold taken from the code under test cannot reject that code. A pinned
comparison needs a new **26-parameter pinned refit**, not this number.

## 3. THE CANONICAL REPLACEMENT

`calibration/output/refit_20260903_ent26/mode_fit_pumpN.rds`, resolved as
`ccx_mode_file("ent26")` — 26 parameters, logpost −1446.7627, promoted from
start id 18 of the 40-task Torch survey `16837149` by
`calibration/promote_multistart_mode.R`.

⛔ Its logpost is **not** comparable with −1544.615 above, and not with the
25-parameter −1482.6144 either. What IS comparable is the **likelihood**: the
21 data streams and their sigmas are identical across the builds, and it moved
**+20.41** against the 25-parameter winner.

Do not point anything here except a deliberate before/after comparison.
