# GATE S's blind phase at hilda31w: the SST-lag test (2026-10-13, CHANGELOG 10-13 p)

The 10-13 (g) ledger recorded GATE S's blind read moving 4.10 → 4.38 months at hilda31w, outside its 0.05 tolerance.
It named a candidate cause, inferred and not tested: the WTC label reads the seasonal SST lag per hemisphere from
ERSSTv5 (SH 1.536 months against the legacy `CCX_SST_SEAS_LAG` 1.32).

`gateS_lag_test.R` → `gateS_lag_test.log` (@94378a2, deterministic, the second run identical to the first) uses the
gate's OWN construction (`test-gate-bounds.R`: `dg_gateS()`, and the knockout of `DG_S_KO` minus `seas_ml` for the
blind read). It runs at the canonical with the lag as fitted, then restored to the legacy 1.32:

| arm | whole limb (the verdict) | blind read |
|---|---|---|
| A, as run (NH 1.325, SH 1.536) | 0.388 ppm @ 8.908 mo, PASS | 0.854 @ **4.377** (reproduces the recorded 4.38) |
| B, SH → 1.32 | 0.332 @ 9.346, PASS | 0.854 @ **4.155** |
| C, both → 1.32 | as B | as B (the NH lag does not reach SPO) |

- **CONFIRMED for the bulk:** a −0.216 month SH lag change moves the blind phase −0.222, one for one, as it must if the blind phase is the thermal phase. That is **80 %** of the +0.28 move. The remaining +0.055 is the rest of the refit.
- The same lag also moves the gate's VERDICT quantity, the whole limb, by +0.44 months (8.91 → 9.35). Both lie inside the gate's arc (7.41–10.41), so the verdict does not change.
