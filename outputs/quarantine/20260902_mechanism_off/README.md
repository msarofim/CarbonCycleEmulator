# Quarantine — 2026-09-02, "the mechanism was off"

Two diagnostics were found, on 2026-09-02, to have been **reporting with their own
mechanism silently disabled**. This directory holds the outputs one of them left
behind. Nothing here is a result; nothing here should be read for a number.

## 1. Which bug applies

**`calibration/diag_gross_cancellation_geometry.R:237` set a RETIRED parameter.**
The 15-point `GC_LAG_GRID` sweep assigned the scalar `seas_lag_p`, which the
2026-08-31 split (`seas_lag_p_NH` / `seas_lag_p_SH`, handoff `2026-08-31…`,
`11ff844`) had demoted: with a **complete** split present the scalar loses by
silent precedence, so the assignment did nothing at all.

**Verified by running it, not by reading it:** setting the scalar to 0.5, 1.75
and 4.0 all returned a lag of **2.25**. The sweep ran at constant lag and the
"maximum" it printed was read off a **flat curve**.

Fixed in `95e97ab` (the assignment now goes through the split fields), and the
same commit made both split contracts hard-error so a retired name beside a
complete split can no longer be written silently.

⚠ The companion finding of the same day is **not** represented here because it
left no artifact: `calibration/diag_gamma_iav.R:62` deleted all four
`gamma_enso_*` names via the `intersect()` + `NULL`-assign idiom
(`[[intersect_is_a_silent_default]]`), so its whole `q10` scan ran with **ENSO
off** — measured cost 3.68 ppm of CO₂_NH over 1960–2000. That file writes no
`.rds`, so there was nothing to move.

## 2. Which files these are

| file | written | what is wrong with it |
|---|---|---|
| `gross_cancellation_geometry.rds` | 2026-08-29 10:24 | its `lag_profile` element, and the `G5` verdict derived from it, are a constant-lag curve. Its other elements (`ta_grid`, `profile`, `a_grid`, `gross`, `cmip6`, `obs`, `G0`–`G3`) do **not** pass through the broken assignment and were correct **for the model as it stood on 2026-08-29**. |
| `gross_cancellation_geometry.log` | 2026-08-29 10:25 | the console transcript of the same run, including the printed maximum read off the flat curve. |

⚠ **A second reason not to reuse even the unaffected elements.** On 2026-09-02
the **ENSO land term was restructured** from a signed flux out of `soil_fast`
into a one-way GPP modulation (Marcus's ruling; `R/model.R`, `src/ccx_core.cpp`).
That is a change to the model these numbers describe, so the whole file is
superseded on structure as well as on the lag axis.

## 3. The canonical replacement

Re-run to the canonical path:

```
Rscript calibration/diag_gross_cancellation_geometry.R
```

which writes `outputs/diagnostics/gross_cancellation_geometry.rds` and, with the
usual redirection, `.log` beside it. **The lag-axis numbers in the replacement
will differ from the ones here, and that is the point** — the old ones were
measurements of nothing.
