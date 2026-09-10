# Quarantine — 2026-09-09w, `d14c_profile_rows_missing`

## 1. The bug this quarantine applies to
The **`streams` field only** of the canonical mode file carried the retired
**`d14c_deep_ocean`** row (−4.1833) where the objective actually scored the three
**`d14c_profile_*`** rows (−8.9376). The `d14c` profile form (GNORM) has been on since
**2026-09-07**; the producer that wrote this field called `ccx_loglik()` with **no `d14c_mid`
argument**, so it reproduced the pre-profile decomposition. The field was short by **4.7543**
log-units, exactly as the 2026-09-09t whole-model review (§10 item 6) reported.

⛔ **The 2026-09-09v handoff rebutted that review finding and the rebuttal was wrong.** It read the
43.99 gap between the stored rows (−1434.6705) and the stored `logpost` (−1478.6595) as "the
log-prior, as expected". **The log-prior is −39.2347** and was never computed
⇒ `[[residual_named_not_computed]]`, CHANGELOG **09-09w**.

## 2. Which file is here, and what was wrong with it
| | |
|---|---|
| file | `mode_fit_pumpN.rds` — the **canonical** `hilda31` mode, `calibration/output/refit_20260908_hilda31/` |
| quarantined | the **pre-repair** copy, taken before `calibration/repair_canonical_streams.R` wrote |
| wrong | `streams` (23 rows, −1434.670486) |
| **RIGHT, and untouched** | `par_mode`, `u_mode`, **`logpost`**, `hessian`, `cov`, `cor`, `sd_unc`, `eigen`, `logdet_negH`, `prior_z` |

⭐⭐ **THE `logpost` IS VALID AND THIS IS NOT A REFIT OBLIGATION.** `logpost − logprior =
−1439.424788`, which is the **recomputed 25-row** sum to **1.27e−10**. The stored `logpost` is
therefore *today's* objective, `hilda31` **is** a mode of this space, and no refit, no re-promotion
and no other quarantine follows. The **22 common rows agree to 1.38e−10**, so the model and every
other term are identical — the defect is confined to one leg of one reporting field.

⚠ **Nothing load-bearing moved.** P12's **−514** is on `co2_level_MLO`/`co2_level_SPO`, both common
rows, agreeing to 1e−10. The F2 / periodic-spinup finding is untouched.

## 3. The canonical post-fix replacement
**The same path** — `calibration/output/refit_20260908_hilda31/mode_fit_pumpN.rds`, repaired in
place. It now holds:

- `streams` — 25 rows, **−1439.424788**, on today's objective
- `streams_as_fitted` — the 23 rows preserved verbatim
- `streams_provenance` — dates, commit, the computed `logprior` and `loglik_implied`, and the
  `fields_unaffected` list

⭐ **Unlike the 2026-08-22 repair whose contract this copies, the repaired file holds ONE vintage,
not two** — and that is **gated, not assumed**: `repair_canonical_streams.R` **refuses to write**
unless `logpost − logprior` reconciles with the recomputed sum, because a file that does not
reconcile is a refit obligation rather than a stale field. The gate is mutation-tested (it fails on
the stored set, on a moved logpost, and on a dropped row).

## 4. Why it survived adoption — a SILENT GATE
`calibration/diag_adoption_read_hilda31.R:29` exists to catch exactly this. It **`intersect()`s the
two name sets before comparing** and reports `max|diff|`, then only `cat()`s the leftovers. A
`max|diff|` over an intersection **cannot fail on a SUBSTITUTION**, only on a movement — and a
substitution is precisely what a changed objective produces. On the live defect it returned
**1.4e−10 and PASSED**, and 13 sites read the field for the next day.
⇒ `[[intersect_is_a_silent_default]]` (the COMPARISON form), `calibration/diag_mode_streams_provenance.R`.

⛔ **`calibration/repair_arm_streams.R` is itself still a stale producer** — its `ccx_loglik()` call
passes no `d14c_mid`. Its two arms are retired and its already-repaired guard stops it re-running,
so it was not rewritten; a banner on it points here.

## 5. Reproducing the finding
```
Rscript calibration/diag_mode_streams_provenance.R        # reads only; the measurement
Rscript calibration/repair_canonical_streams.R --dry-run  # the gate, without writing
```
