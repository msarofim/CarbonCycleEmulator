# QUARANTINE — 2026-08-25e, seasonal-NEP double discrimination

## 1. The bug these outputs were fitted under

`R/model.R` emitted the seasonal land flux as

```r
add_flux(iatm, ilef, seas, alpha13 = aux$alpha_photo, lab = "seas")
```

`seas` is **zero-mean by construction**, so it is negative for half of every year, and `add_flux`
resolves a negative flux by swapping the SOURCE box while **still applying `alpha13`**. The carbon
returning from the leaf pool each autumn was therefore discriminated a **second** time.
Photosynthesis discriminates; respiration does not.

`src/ccx_core.cpp` implemented the same rule, so **both cores were wrong together** and the R↔C++
parity test could not see it. ¹³C conservation could not see it either — `add_flux` is
antisymmetric, so total ¹³C is conserved for any `alpha13`; this was a mis-partition, not a leak.
And `test-conservation.R:82` and `test-parity.R:72/151` all set `seas_drivers <- 0`, so the two
suites with any claim to power over the seasonal isotope path **disabled it**.

**Size, parameter-free:** a closed two-box system with one 60 GtC/yr zero-mean sinusoid returns
carbon to 9e−13 GtC and drifts δ¹³C by **−0.124 ‰ per cycle**, forever. In the full model the leaf
pool sat **+5.000 ‰** above `r_atm·α` — flat across 1770/1860/1960/2014 — where after the fix it
sits at **+0.012 to +0.025 ‰**.

**Consequence for the fit:** seasonal δ¹³C amplitude per ppm was 1.28× observed at MLO and 2.45× at
SPO; after the fix, 0.93× and 1.58×. Frozen at the pre-fix mode the fix is worth `d13c_seasonal`
**+210.7** and `d13c_level` **−259.5** log-units — which is why a refit is owed and why no number
in these files can be carried across.

Fixed in commit on 2026-08-25e (`R/model.R`, `src/ccx_core.cpp`), together with an `add_flux` guard
that refuses a signed flux carrying a fractionation.

## 2. What is in here

Every directory holding a FITTED PARAMETER VECTOR as of 2026-08-25:

| directory | what it was |
|---|---|
| `pump_arms/` | **the adopted arm-N mode** (`mode_fit_pumpN.rds`), its Hessian and arm D |
| `ridge_free_from90/`, `ridge_pin120/`, `ridge_pin90/`, `ridge_pin60/` | the 2026-08-25 pre-registered 4-arm fertilization-ridge refit |
| `luc_arm_pinluc/`, `luc_arm_pin2/` | the pinned `luc` arms (08-24c; `pin2` was STOPPED at 1 h 25 and was already labeled so) |
| `pump_arms_SINK25/`, `pump_arms_SINK25_PINLUC/` | the artificial-mid-century-sink arms |
| `pump_arms_SMOKE/`, `pump_arms_SMOKE_20260822/` | smoke runs |

**Everything else under `calibration/output/` was left in place.** Those are dated diagnostic
products, not fitted vectors — they are read by the notes that cite them and are not at risk of
being silently retrieved as a current parameter estimate. They are nonetheless **all pre-fix** and
any δ¹³C-sensitive number in them is affected.

## 3. The canonical replacement

**PENDING — there is no post-fix mode yet.** `calibration/output/pump_arms/mode_fit_pumpN.rds` does
not exist until a refit is run (~9 h; `calibration/run_modefind_pump_arms.R`). Until then:

- **the Shiny app and every diagnostic that resolves a mode file will FAIL, loudly.** That is the
  intended behavior. A pre-fix mode silently reused under a post-fix objective would be worse.
- **the ridge question is REOPENED.** Under the patch, at pre-fix parameters, the pin90-vs-reference
  likelihood gap goes −90.07 → −25.28 and what remains is `gcb_land_sink` −24.00, a carbon-budget
  objection rather than an isotopic one. **That is not a result** — both arms move under a refit and
  the free arm has to be re-run.

## 4. THE OBJECTIVE CHANGED

Same class as the 2026-08-22 ice-hemisphere change: **nothing fitted before 2026-08-25e is
comparable across it**, no logL or evidence may be quoted against a post-fix number, and every gate
verdict in `DESIGN.md` §6 is owed a re-measurement.

## 5. Provenance

- `notes/collect_2026-08-25d_seasonal_isotope_rectification.md` — the finding, the receipt, the
  channel decomposition that located it, and the evaluation of the two candidate corrections.
- `calibration/diag_seas_isotope_rectification.R` — reproduces the closed-box receipt and the
  frozen per-stream cost.
- `tests/testthat/test-seas-isotope.R` — the regression test, and the first test in the repo that
  exercises the seasonal isotope path with `seas_drivers = 1`.
- memory `seas_isotope_rectification`.
