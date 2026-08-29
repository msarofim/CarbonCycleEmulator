# QUARANTINE 2026-08-29 — `diag_landed_gap_streams.R`, a PRE-ADOPTION driver

**This is a DECISION, taken by Marcus on 2026-08-29** ("quarantine"), closing an item owed since
`handoff_2026-08-28d` §5 and restated in `handoff_2026-08-29` §5(b).

## 1. Which change retires it

**`2153bd6`, 2026-08-28, "ADOPT OPTION 5":** the three ocean-gradient rows are now scored at
`sigma_eff(h_ml)` at every `h_ml`, and the `LIK_OCEAN_GRAD_HML_OK` = [85, 120] skip is RETIRED.
**Every pre-adoption fitted vector is non-comparable**, and this driver reads only such vectors:

    GAP_ARMS = ref    refit_20260825f_ref/mode_fit_pumpN_progress.rds
               from90 the canonical mode, fitted pre-option-5
               pin90  the pinned arm, fitted pre-option-5

**It is not repairable by widening a band, which is why it was the one mirror deliberately left
un-widened on 08-28i.** Its GATE 1 reproduces logposts **STORED** by band-fitted arms, so widening
fails it *by construction*, and re-pointing it at post-adoption vectors would silently change what
GATE 1 is checking. It measures a real thing about a model that no longer exists.

⚠ **The 2026-08-29 session made the general form of this concrete:** across the option-5 change a
stored logpost moves by **0.081** (measured at four points spanning 60 log units), and this driver's
whole method is differences of stored logposts. See `notes/collect_2026-08-29_the_recovery_fraction_is_not_a_number.md`
and memory `compare_gaps_not_absolute_logposts`.

## 2. What was produced, and moved here

    landed_gap_streams.rds     <- was calibration/output/landed_gap/landed_gap_streams.rds

⚠ **`calibration/output/landed_gap/` is NOT retired as a directory** — `diag_stream_neff.R` writes
`stream_neff.rds` there and WAS widened on 08-28i, so it is a live mirror. Only the one file moved.

## 3. The canonical replacement

**There is none, and that is deliberate.** The question this driver answered — *where do the 86.7
log-units actually live, at the landed modes?* — has to be **re-asked** against post-adoption
vectors, not re-pointed. The nearest live reader is **`calibration/diag_stream_neff.R`**, which
prices the station-level streams' effective n and is band-widened; its finding
([[ridge_veto_is_a_bias]]) that the veto is a MEAN SHIFT rather than a stream weight, and that
repricing is "a 15 % haircut, not two orders", is unaffected by the objective change because it is
an n_eff argument, not a logpost difference.

**The driver itself is kept in `calibration/` as provenance and now HARD-STOPS** rather than being
deleted or moved: a reader who runs it gets the reason, not stale numbers. Never delete pre-fix
work — see the quarantine rule in `~/.claude/CLAUDE.md`.
