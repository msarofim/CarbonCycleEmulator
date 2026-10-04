# HANDOFF 2026-10-04 — the SH winter mixed-layer substep defect: found, ruled, fixed; the suite is clean and the branch awaits a merge

**Picks up from** `notes/handoff_2026-10-03_obj15_refit.md`, which remains the record of the objective-#15 refit.
`hilda34g`'s adoption is CHANGELOG 10-03 (h)–(i). This note covers only the start-017 investigation and the
fix it led to. It is self-contained.

**Start here.**
1. Read this note.
2. Then CHANGELOG 10-04 (a) and 10-03 (j), at the top of `CHANGELOG.md`.
3. Then memory `ccx_seasml_substep_controller_unstable`, reached through `INDEX_diag_conv.md` or `INDEX_ccx.md`.

⚠ **The work is on branch `claude/pensive-burnell-a9bf40`** (worktree `.claude/worktrees/pensive-burnell-a9bf40`),
**not on `main`**. See §5.1.

## 1. What we were doing
- **The task.** 10-03 (e) found start 017 of the #15 lag arm stalled at −1306.89, with three non-smooth directions:
  - kz and kz_deep_frac moved `co2_seasonal_SPO` by about −250;
  - h_ml sent `d13c_seasonal_SPO` to −2e37.

  It filed a task: find the mechanism, test the four named candidates, propose a fix, and do not move the objective
  without Marcus's ruling.
- **The answer (10-03 j).** The RK4 substep controller `ccx_substeps_for()` under-resolves the SH winter
  mixed-layer peak near the P8 wall. The integration there runs past RK4's stability limit for ~10 days a year, and
  the objective returns integrator artefact. 017's stored logpost is +273.2 of artefact.
- **What happened next.** Marcus ruled the fix in; it is applied (10-04 a), and the full suite is clean.

## 2. Decisions and their reasons
- **The ruling, verbatim:** "Apply A+B+C (Recommended)". The alternatives offered were "Apply A+B only" and
  "Hold; document only". The three parts:
  - **(A)** Take the RK4 bound at the MLD interpolant's CONTINUOUS extremes, the `$f_min` / `$f_max` that
    `ccx_seas_ml_guard()` already reads. The 12 monthly samples' pooled max is 1.6817 (the NH's, and the NH is flat
    in the run under this label); the SH interpolant peaks at 1.6876. At 017 that 0.35 % is layer 1 at 1.19 m against
    the 0.75 m the integrator meets.
  - **(B)** Use the HELD `kz_int` profile. Re-evaluated on the moved grid, the ML base read 0.82 × kz, where the
    integrator holds kz itself.
  - **(C)** STOP (−Inf in the objective) past `CCX_SUBSTEPS_MAX` = 256. The silent clamp it replaces ran a count its
    own bound called unstable.
- **Why it needed a ruling.** Review A16 (09-12) had left the controller on the samples because a count change "moves
  the objective". Priced first, the fix moves no registered mode, bit for bit. It does move the count at 77 of the 434
  `seas_ml` = 1 start-file endpoints, so it is an objective change under the D1 precedent (10-02 cc).
- **The new tests reuse the existing accuracy bar** rather than a tuned one: `test-stability.R`'s "accurate, not
  merely stable" (CO₂ < 1e-6 relative, Δ¹⁴C < 1e-3 ‰ on doubling the count).
- **Deliberately LEFT OUT of the ruling:** `ccx_tr_box_eigbound()` still re-evaluates its own K on the moved grid, the
  same class as (B). The box is off at every registered mode, and a comment in the code says so.

## 3. Files and commits (branch pushed to origin; 3 commits ahead of `main` @ `4593043` before this note)
- **`57a1e97`, the diagnosis:**
  - `calibration/diag_seasml_substep_controller.R` (new);
  - `outputs/diagnostics/seasml_substep_controller_20261003.{log,rds}`;
  - CHANGELOG 10-03 (j).
- **`a7eab97`, the fix:**
  - `R/model.R`: `ccx_substeps_for()`, plus one comment in `ccx_mld_fourier()`.
  - `tests/testthat/test-stability.R`: three `seas_ml` = 1 tests and their helpers `seasml_at()`, `true_stiffness()`,
    `ss_pre_20261004()` (the MUTATION: the old bound) and `p8_wall()`.
  - `DESIGN.md` §3.7 gains the rule; CHANGELOG 10-04 (a).
- **`7b80b21`, the suite record:** `outputs/diagnostics/suite_20261004_a7eab97_all.log`, and the result in CHANGELOG
  10-04 (a).
- **This note and CHANGELOG 10-04 (b):** the commit after `7b80b21`.
- **Memory** (outside the repo; the shared FaIRtoFrEDI store):
  - `ccx_seasml_substep_controller_unstable.md` (new);
  - one-line pointers in `INDEX_diag_conv.md` (its "Solver residuals" section) and in `INDEX_ccx.md`.

## 4. The numbers a next session will want (all in the diagnostic's log and rds)
- **017.**
  - The value: −1306.890 at the controller's 15 substeps, −1580.051 converged (×2 to ×16 agree to 2.3e-4). The
    artefact is +273.2, almost all on `co2_seasonal_SPO`: +72.55 at 15 substeps against −199.76 converged.
  - Smoothness: on the converged objective the pair sums are h_ml −0.198, kz −0.015, kz_deep_frac −0.011. At the
    controller's count they were −3e37, −250.7 and −250.9.
  - The stiffness at 017's SH winter peak (t = 0.646 yr): the integrator's Jacobian is 730/yr. The shipped bound gave
    426; with (A) 676; with (A+B) 827. The result was z 4.06 against 2.785, unstable for 10.3 days a year.
  - 017's `need` is 14.99997: the simplex parked 2.6e-5 below the 15 → 16 substep switch, climbing INTO the artefact.
  - The h_ml+ blow-up: the periodic orbit's SH mixed layer holds −17.8 GtC in January 1750 and −96.8 GtC at its
    minimum, and |δ¹³C_SH| reaches 1.4e17 ‰. The periodic spinup "converged" anyway (resid ≤ 4.5e-10), because Newton
    finds the fixed point of an unstable discrete map just as readily.
- **The edge**, at the canonical's other values: the first unstable h_ml is 72.75 m, 5.5 marginal sds above the mode's
  49.65 m. The P8 wall is at 75.504 m.
- **Who was in it.**
  - Every registered mode sits at 4 substeps with z ≤ 1.19. Every `seas_ml` = 1 mode file has h_ml ≤ 65.23 m.
  - 51 of the 434 start-file endpoints were unstable, 13 of them converged. A material artefact needs z ≥ 3.84: 17
    points, 16 of them positive.
  - Only ONE converged start is materially off: 09-16 `hilda_c` id 23 (+27.6).
  - MCMC stage 1 (`hilda33d`) made one excursion, to 73.34 m (2 draws), with an artefact of +0.004.
  - The Laplace misses the h_ml ridge's reach (99.9 % at 59.2 m against the MCMC's 69.5 m).
- **After the fix.**
  - At 017's h_ml on the canonical's column the count is 29; doubling it moves SH CO₂ by 1.7e-7 relative, against
    6.3e-3 at the old 15.
  - The bound stops by 0.1 m short of the wall (308 substeps needed there).
  - The suite at `a7eab97`: **6039 passed, 0 failed, 3 skipped, 0 errors**. That is `e2f611b`'s 6030 plus exactly the
    nine new expectations.

## 5. Next steps (Marcus's calls; none started)
1. **Merge `claude/pensive-burnell-a9bf40` into `main`.** Offered at the end of the session; he chose this handoff
   first, so the merge is NOT done. The fix changes no registered mode, so the app's numbers are the same either way.
2. *(Optional)* Re-read the older waves' survey verdicts against the driver's section 4(e), above all the "h_ml ridge"
   endpoints at 73–74.4 m. This is low priority: only 09-16 id 23 is materially off among converged points.
3. *(Optional; needs a ruling)* Extend (B) to `ccx_tr_box_eigbound()`. No registered mode would move, but it is still
   an objective change for tr-box structures.
4. *(Housekeeping)* `INDEX_ccx.md` is at 14,306 B of its 14,336 B soft budget. The next addition there should split
   the file or route elsewhere (`INDEX_conv.md`'s rules).

## 6. Non-obvious state
- **Nothing from this session is running.**
  - The scratch suite worktree `~/ccx_frozen/suite_20261004a` was removed.
  - The two `~/ccx_frozen/20261002ee_obj15_{lag,ctl}` git worktrees (at `3fc5dca`) belong to the #15 refit. They were
    not touched, and nothing runs in them.
- **The app preview runs from the MAIN checkout** (PID 44422, port 7788, `main` @ `4593043`, i.e. the pre-fix
  controller). It is unaffected: the canonical runs at 4 substeps under either controller.
- **A worktree needs the gitignored downloads.** This one has `data-raw/downloads/nuclear14c` copied in; without it
  every logpost is off (017 scores −1307.53 instead of −1306.89). Suite runs symlink every download, as 10-03 (d) and
  this suite did.
- **The diagnostic driver is a PRE-FIX record.**
  - It treats `ccx_substeps_for()` as "the shipped controller", so on a fixed tree its section-1 power gate
    (`pair_x1 > SC_SMOOTH_TOL`) STOPS the run. That is by design: the defect is gone.
  - Reproduce its numbers at `57a1e97`.
  - Its outputs were stamped `4593043+dirty`. The only dirt was the driver itself (md5 `e3ab3b34`, identical to the
    committed file).
- **Some stored logposts no longer reproduce.** The 77 start files whose count moved score differently under the fixed
  controller; 017's stored −1306.89 is now −1580.05. Registered modes are bit-identical. Start files were NOT restamped
  (nothing requires it): compare them as gaps under one build.
- **Encode old start files from their NATURAL values.** h_ml's lower bound moved 30 → 42.5 m on 09-16, so a pre-09-16
  `u_mode` decodes 13–31 % off under today's table. The diagnostic's first run made exactly this error; the committed
  driver is repaired.
- **Readings that are superseded but still on disk.**
  - 10-03 (e)'s "STUCK start" and "barrier 1212.8" are superseded by 10-03 (j): 017 was parked on a substep switch.
    The converged dip on the straight line to the mode is 939.5, and it is real.
  - `outputs/diagnostics/obj15_refit_read_20261003.log` still records 017 at its pre-fix value (123.90 below the
    mode). It was not regenerated.
