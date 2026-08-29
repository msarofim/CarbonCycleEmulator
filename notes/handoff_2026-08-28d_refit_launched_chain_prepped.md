# Handoff — CarbonCycleEmulator, 2026-08-28d: **THE REFIT IS RUNNING. §4.2–4.5 IS WRITTEN AND TESTED.**
# Nothing is quarantined, nothing is repointed. Two decisions are OWED before the chain can run.

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `e31c867`.
**Suite 1206 pass / 0 fail** (was 1203). Continues `handoff_2026-08-28c_option5_adopted.md`.

⚠ **SESSION CWD WAS `FaIRtoFrEDI/`; ALL THIS WORK IS IN `CarbonCycleEmulator/`.**

---

## 0. STATE IN SIX LINES

1. ⚠ **THE 21-PARAMETER REFIT IS RUNNING** — pid 3192, launched 19:44, ETA ~14:00 on 08-29. §1
2. **08-28c §4.1 is DISCHARGED. §4.2–4.5 is now ONE command**, written and tested against the
   incumbent while the refit ran. §2
3. ⚠ **TWO DECISIONS ARE OWED BEFORE THAT COMMAND CAN FINISH** — the `pin90` retirement and one
   test's premise. Both are hard stops, not defaults. §3
4. **Nothing is quarantined and nothing is repointed**, still deliberately. §3
5. **Two bugs in my own new code were found by TESTING, not review** — both in the same trap. §4
6. **`CCX_MODE_RETIRED` now carries a reason PER ARM.** Behaviour-preserving today; it is what
   lets tomorrow's retirement state *its own* cause instead of the isotope fix's. §2

---

## 1. THE RUNNING REFIT

    calibration/output/refit_20260828_sigma_eff/     pid 3192, ~160 MB RSS, 1 thread
    tail -f calibration/output/refit_20260828_sigma_eff/_run.log

Production budget (20 restarts × 20000 maxit × ≤6 cycles), `h_ml` **UNBOUNDED**, BLAS pinned to one
thread, run from a **FROZEN copy** of the driver committed beside it so the tracked
`run_modefind_pump_arms.R` stays editable ([[never_edit_a_running_script]]).

- **Warm-started from a byte copy of the incumbent canonical mode.** Safe across the objective
  change because `par_mode` is band-INDEPENDENT and is re-encoded under this run's table;
  `u_mode` would NOT have been.
- **Gates H1/H2/H3 all pass in the log** — shipped support un-renormalised, the shipped init 75
  accepted, and the three ocean-gradient rows LIVE with finite `sd_eff` at 31 / 75 / 199 m.
- **The warm start reads −1544.6 against a file that says −1544.6** — a MATCHED read.
- ⚠ **The launch was gated on the MACHINE.** 08-28c left it open because a Julia SLR job was
  running here; that job had finished, **checked before launching, not assumed**
  ([[eta_in_days_is_not_a_slow_run]]).
- ⚠ **The seeded `mode_fit_pumpN.rds` is deliberately NOT committed.** It is the incumbent's bytes
  and the driver overwrites it in place, so committing it now would record a result that does not
  exist. This also means **its existence proves nothing** — see the mtime check in §2.

## 2. WHAT §4.2–4.5 IS NOW: `calibration/run_post_refit_adoption.R`

    Rscript calibration/run_post_refit_adoption.R --retire-pin90   # or --keep-pin90
    Rscript calibration/run_post_refit_adoption.R --stage=read     # one stage at a time

Five stages in the only safe order: **check → read → quarantine → repoint → rerun.**

- **`check` REFUSES to start on an unfinished refit** — and does not trust the mode file's
  existence, because the directory was seeded with a copy. What discriminates is its **mtime**
  against the incumbent's, the log ending in the comparison write, and **`hml_bound` recording the
  SHIPPED support**: had the refit written `[85, 120]` there, every downstream
  `ccx_mode_params()` decode would silently be wrong.
- **`read` exists so an `h_ml` move CANNOT be reported without its decomposition.** It re-evaluates
  BOTH vectors under the CURRENT objective — the stored logposts belong to two different objectives
  and **cannot be subtracted** — and splits Δlogpost into prior / jacobian / loglik, naming the
  per-parameter movers. **It warns, by construction, when the total rises while the likelihood
  falls**: that is the smoke test's exact signature (+4.060 total, −1.201 loglik, the whole gain
  prior credit on `sst_seas_amp_SH`/`_NH`) and must not be read as a better fit.
- **`quarantine`** `git mv`s the incumbent to `quarantine/20260828_sigma_inflation_adopted/` and
  writes the README (which bug/change, what is in it, the canonical replacement).
- **`repoint`** rewrites three `R/paths.R` blocks, adds the retirement entries, then runs the suite
  and STOPS if it fails.
- **`rerun`** runs `recompute_hessian.R` (WITHOUT `--update` — overwriting a fresh mode's
  second-order block is a decision, not a side effect), `diag_hess_eps_21par.R`, and the three
  design gates, logging each to `post_refit_logs/`.

**`CCX_MODE_RETIRED` carries a reason PER ARM** (`R/paths.R`, done first). The reason used to live
in `ccx_mode_file()`'s error as ONE hardcoded sentence — the isotope fix `6bda464`, quarantined
under `20260825_seas_isotope_rectification/`. Correct while a single objective change had retired
every arm; **option 5 (`2153bd6`) is a second one**, so the shared sentence would state the wrong
cause and point at the wrong directory. `test-mode-file.R`'s check **generalises rather than
relaxes**: each entry must name a quarantine path AND a cause commit, whatever they are for that arm.

### What was VERIFIED, not asserted

- **The `read` decomposition CLOSES**: loglik by subtraction vs computed directly through
  `ccx_loglik()` agree to **2.6e-10**. Identity gate (a vector against itself) is **exact** zero in
  all four channels.
- **`sub1()` mutation-tested** — refuses at 0 matches and at 2 ([[mutation_test_gates]]). The three
  anchors each match exactly once; the rewrite parses, sources, and satisfies all three invariants
  `test-mode-file.R` asserts.
- **The retirement anchor's uniqueness is MEASURED**: the bare path line appears **3** times (N, D
  and ref all name it), the two-line form exactly **once**.
- **Both hard stops fire and edit nothing.**

## 3. ⇒ WHAT IS OWED, IN ORDER — **TWO ARE DECISIONS, NOT WORK**

1. **Wait for the refit.** `pgrep -f run_modefind_pump_arms_FROZEN` before anything else.
2. ✅ **DECIDED 2026-08-28 (Marcus): RETIRE `pin90`. `--retire-pin90` is now the DEFAULT.**
   ⚠ **My "six diagnostics name it" was WRONG — it is TWO**, and I withdraw the count. The rest
   were filename matches, not call sites ([[audit_live_paths]]): `diag_stream_neff.R` and
   `seed_fert_ridge_arms.R` mean **`ridge_pin90`, a DIFFERENT arm**, and
   `diag_design_gates_at_mode.R` names it only in comments. The two real readers are
   `diag_design_gates_unscored.R` (an OPTIONAL read, now guarded so it degrades instead of
   stopping) and `diag_landed_gap_streams.R`, whose other arms (`ref`, `from90`) are retired by
   the same change anyway. The `+11.6698` offset stops being reproducible from a live run — if
   that matters, **STORE it**, do not keep an arm resolvable for it. `--keep-pin90` still overrides.
3. ⚠ **REWRITE, do not relax, `test-mode-file.R`'s last assertion.**
   `expect_gt(lp[["pin90"]], lp[[CCX_MODE_CANONICAL]])` compares two **STORED** logposts; across
   the objective change that is **meaningless, not merely false**, and under `--retire-pin90`
   `pin90` is not resolvable at all. The trap it encodes — that a stored number decides an arm — is
   still worth asserting, just not across two objectives.
4. **Then run the chain**, and read `read`'s decomposition before believing any `h_ml` number.
5. **§4.5 — SWEPT 2026-08-28, and TWO of the four must NOT be widened.** See CHANGELOG 08-28i.
   - `diag_hess_eps_21par.R`, `diag_stream_neff.R` — **WIDENED**, constants derived from the
     shipped table; hess_eps's gate **INVERTED** (table must be UNTOUCHED), because deleting an
     override without inverting its gate leaves a check that passes *because it cannot fail*
     ([[no_power_null]]). ⚠ hess_eps's per-direction `h_ml` step is **not comparable** with any
     pre-08-28 run — the logit is over a 4.857× wider support.
   - `diag_ridge_reparam.R` — **WIDENED, LADDER SHIFTED.** `RR_THRESH` is a set of ABSOLUTE
     logpost levels; on the shipped support the same vector scores lower by exactly
     **log(170/35) = 1.5805** (pure prior renormalisation — the same −1.5805 08-28c calls the
     bounded refit's narrowed-prior constant; verified numerically). Left as typed it would have
     shifted every verdict one rung, silently. The shift is now COMPUTED, not typed.
   - `diag_landed_gap_streams.R` — **DELIBERATELY NOT WIDENED.** Its GATE 1 reproduces arms'
     **STORED** logposts and those arms were FITTED under `[85, 120]`; the band is their
     PROVENANCE, and widening fails the gate by 1.5805 by construction. It is a PRE-ADOPTION
     driver — **re-point or quarantine is a decision, still owed.** It says so at runtime now.
   - ⚠ **The band CONSTANT itself stays.** `test-sigma-inflation.R:74` needs `c(85, 120)` to test
     that the cliff at 85 and 120 is gone; deleting it deletes the adoption's regression test.
   - ⚠ **None of the four was EXECUTED** — two need the new mode, one is expensive, all contend
     with the refit. Parse-checked only; their on-disk outputs remain pre-adoption.
   - ⚠ `HEPS_HML_INIT` now derives from the table (75). **75.00 is ALSO on a kink** — round numbers
     dominate the 26, so no round init escapes one. Left as the shipped value and flagged, not
     silently moved.

## 4. NON-OBVIOUS STATE

- ⚠ **TWO PARAMETER LISTS THAT LOOK INTERCHANGEABLE AND ARE NOT.** Both bugs in my new code were
  this, and both were found by the closure test rather than by reading:
  `ccx_mode_params()` returns the **21 FITTED names only**, and `ccx_spinup()` needs the whole set —
  it dies inside `ccx_dic_for_pco2()`'s `uniroot` on a zero-length argument, naming neither the
  missing parameter nor the line. But merging onto `ccx_default_params()` then **silently drops
  `bomb_total` and `luc_scale`**, which are not in it, and the forcing columns become `numeric(0)`.
  `ccx_make_logpost()` handles this by using the merged list for the MODEL and the fitted list for
  those two; anything reconstructing a run outside the objective must mirror it. [[ccx_two_param_lists]]
- **`recompute_hessian.R` is self-correcting on the band** — it reads `md$hml_bound` from the file,
  and the new mode records the shipped support. `diag_hess_eps_21par.R` is NOT; it hardcodes.
- ⚠ **The `ref` entry claims it is "quarantined under …20260825_seas_isotope_rectification/"** but
  `calibration/output/refit_20260825f_ref/` is still in place. That claim is **pre-existing** — I
  carried it through the per-arm refactor unchanged rather than silently resolving it. Worth
  checking whether the directory should move or the wording should.
- **Everything in 08-28c §6 still stands**, including: `ccx_loglik()` STOPS on an `ocean_grad`
  without `sd_eff`; `data/obs_glodap_sigma_rep.rds` is a hard dependency of the objective; and the
  harness offset **−1.5805 is a PRE-ADOPTION number**, not current.
- ⚠ **`MEMORY.md` root 18.1 KB (soft 12) and `INDEX_ccx.md` 15.9 KB (soft 14).** Flagged in 08-28c,
  still not restructured; this session added one line to each and one memory file. **Offered to
  Marcus and not chosen** — he picked prepping this chain instead.

## 5. HOW TO RUN WHAT THIS SESSION ADDED

    pgrep -f run_modefind_pump_arms_FROZEN                          # MUST be empty first
    Rscript calibration/run_post_refit_adoption.R --stage=check
    Rscript calibration/run_post_refit_adoption.R --stage=read      # read this before anything
    Rscript calibration/run_post_refit_adoption.R --retire-pin90    # or --keep-pin90; all stages
