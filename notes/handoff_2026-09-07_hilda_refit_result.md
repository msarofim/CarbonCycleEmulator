# Handoff — 2026-09-07. THE HILDA REFIT RESULT: converged, and it rejects the structure; objective #9 de-weighted the level 3× and decided it.
# **⛔ NOTHING ADOPTED. `CCX_MODE_CANONICAL` = `ent26` (26 names); the two mode-file tests still fail on purpose.**
# **⇒ NEXT IS A RULING on objective #9's level weight, and THEN the three cheap tests in §3.**

**Repo:** `CarbonCycleEmulator/`, `main`. Read: CHANGELOG 2026-09-07 (the tables), the scored
`notes/prereg_2026-09-07_hilda_refit_run.md`, then `handoff_2026-09-06e_...` for how it was launched.
Results are IN GIT: `calibration/output/multistart_20260907_hilda28/` (46 starts + ckpts + summary +
Torch logs), `outputs/diagnostics/hilda28_{predictions,basins}_20260907.{rds,log}`.

## 1. THE RESULT IN THREE LINES
1. 46/46 converged; 26 starts reach ONE basin (−1472.72): f 0.81 (K nearly uniform), `hs_asx_frac`
   0.22 (the floor; the cold box's exchange shut), `h_ml` 44 m (from 134), the whole interior 50 ‰
   too young. R1, R2, R3, R5 FAIL. The structural family (f 0.006, K_deep 60–86) is 39–63 worse and
   pays it on the pump's GRADIENT rows (`ocean_grad_d13c` −21.9).
2. The ranking `ent26` (column, structure off) vs the winner FLIPS with the objective: #9-60 the
   winner +23; independent rows `ent26` +20. It is the 0.98 CORRELATION (not the variances): one
   common-mode event instead of three level errors. Verified by swapping the diagonal and the
   correlation separately (`diag_hilda28_basins.R`).
3. Under EVERY objective tried, no structural basin beats the column on the non-profile streams.

## 2. ⚠ WHAT I GOT WRONG, ON THE RECORD
* I built #9 as "the contrast row" and tested that a level shift is cheaper than under independent
  rows — as a PROPERTY TO ASSERT. It was the defect to price. The design's §2 said "the levels'
  weight barely moves"; the level's weight moved 3× (it became one datum). Not pre-registered.
* 09-06c's "unrecovered structural cost −60 to −80, mostly CO₂ level and bomb" was wrong in size
  and location: it is −40 after refit and it sits in the pump gradient rows.
* Declaring `h_hs = h_ml` coupled the HS bomb capacity to the mixed layer; every basin moved `h_ml`
  to an extreme (37–47 or 184–200 m). Not separated before launch.

## 3. ⇒ NEXT — the ruling, then three tests (each local, ~10 min: conditional re-optimisation from a stored start)
**The ruling:** what is the LEVEL's weight in the profile row? Options, none pre-decided: (a) keep
#9 (the correlation is measured; a 50 ‰ common miss at 3.2σ costing 5 units IS the statistics of a
±15 ‰ mean); (b) the independent rows + the B−deep contrast as a fourth row (keeps the level's
triple weight; over-counts, and says so); (c) the MVN with the common-mode variance set by
n_eff (10.3²) rather than the 16-block bootstrap. The column's shape error (−48 under #9) and the
winner's level error (−35 under #8) are the two numbers any choice has to be argued against.
**Then:**
1. `h_hs` DECOUPLED from `h_ml` (fixed 134, or free): re-optimise from the winner AND from the
   structural start (ids 12 and 43). Does `h_ml` return; does `hs_asx_frac` leave the floor?
2. The exchange floor lowered ([0.02, 2]): does the winner drive it to zero? A cold box that wants
   NO air–sea exchange is a "delete the HS box" signal, not a fit.
3. Re-optimise the structural start under the ruled objective and print the pump gradient rows:
   is −21.9 a K_deep-too-small artefact (it should shrink as f rises toward 0.05) or the structure's.

## 4. NON-OBVIOUS STATE
* Torch: nothing running; `multistart_20260907_hilda28/` there = here. Nothing else changed.
* The table is 28-parameter; `ent26` loads only through migration (`dg_vector`), not `ccx_load_mode()`.
* `LIK_USE_D14C_PROFILE_MVN` TRUE, block 60, as ruled 09-06 — the ruling above may change it.
