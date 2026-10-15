# Quarantine 2026-09-16 (d): the three registered mode files BEFORE the hygiene-batch restamp

Copies of `mode_fit_pumpN.rds` for `hilda30c` (refit_20260913_hilda30_cprime_pin_ent0), `hilda31s2`
(refit_20260912_hilda31_seasml1_round7) and `hilda31p` (refit_20260910_hilda31_periodic) as they stood at
commit `1f62f4b`, before `calibration/restamp_mode_objective.R` re-recorded their `streams` / `logpost` under
the 09-16 (d) objective (the deep/slab D14C rows reading every box; the land-sink sigma at GCB's stated 0.5;
Naegler 2009's net-uptake correction on the excess-14C centers; the pre-1850 SST baseline; the h_hs Holte prior).
Measured likelihood moves (outputs/diagnostics/hygiene_batch_price_20260916.log): hilda30c -22.7561,
hilda31s2 -22.5294, hilda31p -18.8767. The restamped files also carry the history inside `objective_history`.
Canonical post-restamp path: the same `calibration/output/<dir>/mode_fit_pumpN.rds`.
