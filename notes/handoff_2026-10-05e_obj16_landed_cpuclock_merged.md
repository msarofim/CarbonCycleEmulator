# HANDOFF 2026-10-05e — #16 has LANDED (not adopted), and the CPU-clock budget is BUILT, TESTED and MERGED. Nothing is running.

> ⛔ **SUPERSEDED by `notes/handoff_2026-10-06_hilda33p_adopted.md`.** #16 was ADOPTED on 2026-10-06 as `hilda33p` (CHANGELOG 10-06 a).

**Supersedes** `notes/handoff_2026-10-05d_obj16_cpu_budget.md`.
- Written at the end of the overnight work. Marcus, 2026-10-05 ~20:50: "I'm headed to bed. Take the next obvious steps whenever the running tasks complete."
- `main` is at `c7242cc` (pushed).

**Start here.**
1. Read CHANGELOG 2026-10-05 (q), (p) and (o), newest at the top.
2. Then these memory files (shared store):
   - `ccx_obj16_landed` (new; the read, and the "two basins" correction);
   - `mac_sleep_eats_wall_budget` (marked FIXED by q);
   - `mutation_test_gates` (gains a fourth blind spot: a mutant can HANG a test).

## 1. What happened overnight
- **#16 landed itself** (CHANGELOG 10-05 p). `~/ccx_frozen/20261005f_obj16_landchain.sh` ran under `nohup` + `caffeinate` and carried out 10-05d §4 steps 1–7, 22:26–22:41.
  - Every gate passed: promote 1–5, the Hessian (PD, condition 2.73e5, step-stable), ocean CHECK 0 with both mutations caught, and the scorecard's reproduction.
  - The ruled sleep statement is in `RUN_PROVENANCE.txt`, every number read. All 8 out-of-time starts slept.
- **The CPU-clock build (10-05d §5) is merged** (CHANGELOG 10-05 q). It is a fast-forward to `05796b9`:
  - 13/13 mutations caught;
  - 15/15 pre-registered smoke criteria PASS, including a real SIGSTOP;
  - the full suite 6281 / 0 / 3, rc 0.

## 2. #16's read (for the adoption ruling): the same 27 rows, against hilda34g
| quantity | #16 | hilda34g |
|---|---|---|
| likelihood | **−1.7678 worse** (CO₂ −1.437, of it `co2_icecore` −1.099; GCB −0.318; δ¹³C +0.137) | — |
| CO₂ in 2300, SSP5-8.5 / vvH | **+12.88 / +7.81 ppm** (feedback +5.52 / +2.87; pin + re-arrangement +7.36 / +4.94) | 1448.65 / 1002.22 |
| land net climate effect 2015–24 | **−0.0378 GtC/yr** (z +1.09 vs GCB −0.8 ± 0.7) | +0.1176 (z +1.31) |
| ocean like-for-like (ruled GMST rule) | **−0.3749 ± 0.028** (1.87× GCB); twin −0.3549; feedback −0.020 | −0.357 ± 0.027 |
| scorecard gates | no verdict flips; GATE V z −4.39 | −4.60 |
| survey | ONE basin; 16 converged, 8 out of time (all slept) | — |

- ⚠ **"Two basins" (10-05 m, c, d) was wrong.** They were value groups within 0.19, inside the optimiser's 0.5 bound, and the collector puts all 16 starts in ONE basin.
- If Marcus adopts: the steps are in `notes/handoff_2026-10-05b` §5 step 7. Then ask whether the hilda34g assessment becomes a #16 assessment.

## 3. Open items (each is Marcus's to prioritise)
1. **#16: adopt or not.** §2 is the read.
2. **Optional:** resume the 8 sleep-affected starts (12, 13, 14, 15, 16, 18, 20, 21) from their checkpoints.
   - With today's driver this runs on the CPU clock, so the collector will WARN about a mixed wave (D3, by design).
   - A resume gets a fresh budget.
3. **Three flags from the build (q), none acted on:**
   - (a) the budget's env name is now `CCX_MS_BUDGET_MIN`, my choice: veto?
   - (b) the driver's direct-invocation default is 180 while both runners export 300: change the value?
   - (c) the end-of-run "eval rate … SIZE THE ARRAY ON THIS" line under-reports ~10× (pre-existing): fix?
4. **Carried, unchanged:**
   - H2 (deferred);
   - `hs_asx_frac`'s judgement width (kept);
   - H1's observed-ratio arm (needs his download permission);
   - card 4 wording (his text);
   - the substep held-K rule (optional);
   - the unmerged git-stamp branch `claude/youthful-blackburn-fbc009` (merge or retire);
   - `~/.claude/CLAUDE.md`'s pgrep remedy (his file; the bracket form is right).
5. **Housekeeping, each needing his OK.** Nothing has been deleted.
   - `~/ccx_frozen/20261005f_obj16`, the run tree. Its landing was verified byte-identical. Also its companions `…_launch.{sh,out}`, `…_land.sh`, `…_landchain.{sh,out,pid}` and `…_sleep_addendum.R`; copies of the chain files are in the outdir's `logs/`.
   - `~/ccx_frozen/20261005g_ocgobm`, the 10-05 test tree (scratch).
   - Tonight's worktrees:
     - `20261005h_cpuclock` (the branch's; merged);
     - `20261005h_cpuclock_old` and `20261005h_cpuclock_smoke` (scratch; #16's port targets copied in, smoke outputs inside);
     - `20261005h_suite_05796b9` (the suite tree);
     - plus `20261005h_cpuclock_smoke_logs/` (copied into the repo), `…_smoke.{sh,out,pid}`, `…_smoke_eval.R` and `…_suite_05796b9_launch.{sh,out,pid}`.
   - The local branch `claude/ms-cpu-clock`: merged, so `git branch -d` is safe. It was never pushed.
   - The three `20261004f_kw1446_launch.*` files (carried).

## 4. Non-obvious state
- **The Mac runner now budgets CPU time by default** (`CCX_MS_CLOCK=cpu`).
  - A Mac wave's wall ETA grows with contention: ~10 % at 0.91 CPU/wall, so a 3-round wave of ~13.7 h becomes ~15–16 h.
  - Nothing runs while the Mac sleeps: keep it on AC, lid open or in closed-display mode.
  - The launch warns on battery.
- **Torch's sbatch pins `CCX_MS_CLOCK=wall` and refuses anything else.**
- **Start files now carry `clock`, `budget_min`, `minutes_wall` and `wall_warned`.** An old file reads as "wall".
- **The landing helper refuses while ANY `run_dispersed_multistart.R` process is alive,** a smoke test's included. Run smokes after a landing's step 1, never before.
- **`pgrep`:** the bracket form, as before. Tonight's waiters used `kill -0` on PIDs instead.
- **Untracked in the repo, not this session's:** `carbotopecomment*.docx`, `outputs/diagnostics/smoke/`, `outputs/mcmc_smoke/`.
