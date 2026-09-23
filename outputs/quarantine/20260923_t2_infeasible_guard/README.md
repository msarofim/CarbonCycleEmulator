# Quarantine — 2026-09-23, T2's infeasible-point guard

## The bug
`calibration/diag_rep_dc_release_test.R`'s drop-arm closure conflated **an infeasible parameter
vector** with **a missing likelihood stream**. `ccx_make_logpost()` returns a bare `-Inf` with **no
`streams` attribute** whenever the optimiser proposes a vector the spinup cannot take; the closure
then ran `setdiff(drop, names(NULL))`, concluded every dropped stream was absent, and `stop()`ed:

    Error in lp_arm(w) : arm ice_dropped: stream(s) absent: co2_icecore
    Error in lp_arm(w) : arm bomb_dropped: stream(s) absent: d14c_NH, d14c_SH

Measured: `k_w`, `h_ml` and `tau_ex` at +60 in unconstrained space all go off-support (`kz` at +60
does not). **Every gate had passed** — because all of them evaluated only at `u0`, which is feasible
by construction, and none had power over the points an optimiser invents. Fixed by returning `-Inf`
off-support and reserving the `stop()` for a *feasible* point whose streams list genuinely lacks the
name (the renamed-row defect the guard exists for), plus a new **GATE INFEASIBLE** that probes each
arm off-support and is mutation-tested to fail without the fix.

## Which files are here
The **8 of 16** jobs that completed on the pre-fix driver (HEAD `62ac59b`), all from the two arms
whose code path never reaches the drop closure:

- `job01..04` — arm `shipped` (3 rungs + 1 replicate)
- `job05..08` — arm `ice_sigma` (3 rungs + 1 replicate)

Jobs 9–16 (`ice_dropped`, `bomb_dropped`) produced **no artifact**; they died 65–145 min in.

## Why these are quarantined rather than kept
The fix is provably in a branch these 8 never executed — `shipped` returns `lp1` directly and
`ice_sigma` returns a rebuilt objective, both before the drop closure. They are very likely
byte-identical to their replacements. **They are quarantined anyway** because a partial result set
at a canonical path invites exactly the silent retrieval the standing rule is about, and because
"very likely identical" is an argument, not a measurement. Keeping them also makes the replacement
run checkable: the new `shipped`/`ice_sigma` artifacts SHOULD reproduce these.

## Canonical replacement
`outputs/diagnostics/rep_dc_release_test_20260923/` — all 16 jobs re-run on the post-fix driver.
