# The CPU-clock build's evidence (2026-10-05)

Built on branch `claude/ms-cpu-clock`: the driver is `8691199`; `0038262` fixes a test helper.
It implements Marcus's rulings D1–D4 (CHANGELOG 2026-10-05 o).

## Unit tests and mutations
- `tests/testthat/test-ms-clock.R`: C1–C5, 47 expectations. `test-ms-deadline.R` D1–D8 pass unchanged (36).
- `mutations.sh` → `mutations_0038262.log`: **13 of 13 mutations caught**, each by the test aimed at it.
- The first attempt HUNG on MC4. The test helper `burn()` timed its own cost with the clock under test, and MC4 stops that clock. `0038262` times it with base `proc.time()`.

## End-to-end smokes
`smoke_cpuclock.sh` (criteria pre-registered in its header) and `smoke_cpuclock_eval.R` → `eval.log`: **15 PASS, 0 FAIL**.
They ran objective #16's config at id 1, after #16 had landed.

| test | what | result |
|---|---|---|
| T0 | the Mac runner, a 1-task PREFLIGHT, on the CPU clock | rc 0. Banner "BUDGET 300 min on the cpu clock"; the driver prints "CPU 300 min", "0.2250 CPU-s/eval", "of a 300 CPU-min budget. LAUNCHABLE"; port VERIFIED |
| T1 | old driver (`2ed310a`) vs new vs new through the legacy `CCX_MS_WALL_MIN`, WALL clock | the NM restart is IDENTICAL in all three: log-post −1193.7792, gain 55.6725, 202 evals, identical traces. `T1_old_vs_new.diff`: the logs differ ONLY in the env name, the output path and two measured timings |
| T1c | both budget names set and different | stops at start-up with the message |
| T3 | a real SIGSTOP of 180 s, 60 s after the rate line; 3-min budget | **CPU arm:** the restart rode through it (324 evals of a sized 322), 1.632 CPU-min against 4.650 wall-min. **Wall arm:** the budget was spent inside the stop, and the restart STOPPED AT THE DEADLINE after 210 of 355 |

The scratch trees `~/ccx_frozen/20261005h_cpuclock_old` and `~/ccx_frozen/20261005h_cpuclock_smoke` hold the start files.
Each has #16's port targets copied in; they are scratch only.
