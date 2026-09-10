# Handoff — 2026-09-09x. **⭐⭐ THE PERIODIC SPINUP IS ADOPTED AS THE OBJECTIVE'S SPINUP (Marcus). SUITE 2443 / 2 FAIL / 1 ERROR = THE PRE-EXISTING SET. PORT TARGETS REGENERATED. ⛔ THE REFIT IS PREPARED BUT NOT SUBMITTED — IT NEEDS A PREFLIGHT MEASUREMENT AND MARCUS'S AUTHENTICATED CHANNEL.**

> ⚠ This header states what is DONE. For live state read `CHANGELOG.md` **09-09x (2)** and **09-09x**,
> and **`INDEX_ccx_seas_ml.md`**, not this line ⇒ [[status_field_carries_the_query]].
> ⛔ This note SUPERSEDES `handoff_2026-09-09x_adoption_priced.md`, written earlier the same day
> BEFORE the ruling; that file says the adoption was not taken and is kept only as the record of the
> pre-ruling state ⇒ [[retraction_in_place_does_not_propagate]].

Read first: **CHANGELOG 09-09x (2)** then **09-09x** — every number with its derivation. Memory:
[[ccx_periodic_adoption_priced]], [[ccx_seas_amp_dead_at_drivers]], `INDEX_ccx_seas_ml.md`.

---

## 0. WHAT THE NEXT SESSION SHOULD DO

> ⭐⭐ **UPDATE 2026-09-10 — THE REFIT IS SUBMITTED AND RUNNING: job `17318015`, 24/24 on partition
> `cs`.** Item 1 below is DONE; read `CHANGELOG.md` **2026-09-10** for it. ⛔ **`cpu_short` PUT 20 OF
> 24 TASKS ON A GPU NODE where this job got 13–18 % of a core**; the first array (`17316364`) was
> cancelled and resubmitted on `cs`. ⛔ **`--exclude` IS REFUSED BY THE CLUSTER** — a GPU-free
> PARTITION is the only mechanism. ⚠ **`cs` has `QoS=N/A`**, so `cpu_short`'s caps (6 h; cpu=32,
> mem=120G) DO NOT BIND — the 6 h wall and `%24` are now deliberate choices, kept because the
> restart/polish arithmetic is derived against them.
> **WHEN IT LANDS**: `collect_dispersed_multistart.R`, then `promote_multistart_mode.R` (whose GATE 5
> was repaired for the adopted spinup on 09-10 — it would otherwise have failed AFTER the run).
> ⛔ **Round 2 is NOT this array resubmitted** — fixed starts plus round 1's best dispersed ids only.

1. ✅ **DONE 09-10 — THE REFIT IS RUNNING.** (Original text kept below for its preconditions.)
   ⛔⛔ **THE REFIT, AND IT NEEDS TWO THINGS FIRST.** (a) A **PREFLIGHT** batch on Torch to measure the
   per-evaluation cost ON A NODE — ruled 09-09x, because scaling the Mac's ~3× onto a node is exactly
   what [[eta_in_days_is_not_a_slow_run]] forbids; (b) **Marcus's authenticated channel** (VPN, gateway
   password, Duo, a Microsoft device code at `login.torch`) — the constraint is AUTHENTICATION, not
   authorship ⇒ [[runnable_is_not_undrivable]]. Then size `--time`/`CCX_MS_WALL_MIN` from the
   measurement and submit 24 starts (6 fixed + 18 dispersed) at `%24`, mirroring round 5.
   **Objective: MAP as usual (likelihood + prior + Jacobian) — ruled 09-09x; "likelihood-only" meant
   COMPARE on likelihood, not fit without priors.** 31 par, `ent_seas_amp_SH` KEPT.
2. ⚠ **Decide whether `hilda31` joins the fixed starts.** `make_bundle.sh` does NOT ship
   `calibration/output/refit_20260908_hilda31`, and the fixed starts are the 08-30 incumbent and the
   08-31e new basin — **neither is the current canonical mode**, which this refit is meant to supersede.
   Recommended, flagged, NOT taken.
3. ⛔ **RULING A's ratification at the re-priced demean gap** (43.8367 → 63.7282, +45 %). Marcus's.
4. Untouched review leads, still `[R]`: F3, F4, GATE Q's missing `test-gate-bounds` coverage,
   `ccx_loglik()`'s finite 0, and the §6/§7 pedagogy items from the 09-09t review.
5. ⛔ **THE ROOT `MEMORY.md` RESTRUCTURE IS THE ONE MEMORY ITEM STILL OWED, AND IT IS MARCUS'S CALL
   ABOUT WHAT STAYS**: **18,197 B of an 18,432 hard ceiling — 235 B left.** (It was 17,921; today's
   276 B is the standing warning that the objective's spinup changed, which auto-loads and is worth
   its space.) ⚠ CONTENT bytes, `<!-- -->` stripped ⇒ [[memory_budget_is_content_not_file]].
   ✅ **`INDEX_ccx_seas_ml.md` is NO LONGER a problem** — it went 56 B OVER its hard ceiling and was
   **SPLIT** (09-09x): the CLOSED build arc is now `INDEX_ccx_seas_ml_arch.md`, leaving **8,083** and
   **12,835 B**, both under the 14 KB soft target. Registered in the project `CLAUDE.md` and the root;
   straddlers named in `_arch`'s header; a 22-term orphan sweep found nothing lost.
   ⚠⚠ **THE LESSON, because I relearned it the hard way twice in one hour**: at the hard ceiling,
   **SPLIT — do not compress.** Both of my "reclaim" edits made the file BIGGER, which is exactly what
   [[memory_index_split_beats_trim]] records.

## 1. STATE OF THE TREE
- **`CarbonCycleEmulator/main`, no remote.** This session, oldest first: `50f0105` (adopt) →
  `02c9f87` (port targets) → `79d9245` (the four test repairs + `CCX_OBJECTIVE_SPINUP`).
  ⚠ This note's own commit follows and is not in that list ⇒ [[status_field_carries_the_query]].
- ✅ **SUITE: PASS 2443 / FAIL 2 / ERROR 1 / SKIP 4.** The 2 + 1 are EXACTLY the pre-existing set
  (`test-alpha-as.R:116,117`; the `test-seas-lag-split.R:199` **ERROR**). **+46 over the 2397 baseline.**
- **`hilda31` still canonical. `seas_ml` still DEFAULT 0. NO REFIT RUN.**
- ⛔⛔ **EVERY STORED `logpost`, `prior_z`, PORT TARGET AND CHECKPOINT `ref_logpost` IS NON-COMPARABLE
  with a run of the objective today.** Second re-baselining after 09-09w's prior shift, and unlike that
  one **this moves the LIKELIHOOD**. At `hilda31`: −1439.424788 → −1449.582691.

## 2. WHAT ADOPTION CONSISTS OF
- `calibration/lib_periodic_spinup.R` → **`R/periodic_spinup.R`** (`git mv`; `git log --follow`).
- **`ccx_make_logpost()`'s `spinup_fn` defaults to `CCX_OBJECTIVE_SPINUP` = `ccx_periodic_spinup`.**
  `ccx_spinup` stays reachable and is how a pre-adoption number is reproduced — name it EXPLICITLY.
- `verbose` now defaults FALSE (it is called once per evaluation).
- A **non-converged** periodic solve returns −Inf, gated on the ABSENCE contract (`$periodic`).
- ⭐⭐ **`CCX_OBJECTIVE_SPINUP` IS THE STRUCTURAL FIX** and the reason the four test failures were ONE
  cause: every hand-built reconstruction of the objective's scoring path now reads that name instead of
  hard-coding a spinup ⇒ [[two_gates_one_mechanism]]. ⛔ Defined in `R/periodic_spinup.R`, NOT
  `calibrate.R` — the alphabetical bootstrap sources `calibrate.R` first, so a binding there would
  evaluate before the function exists; a DEFAULT ARGUMENT is fine because it resolves at call time.

## 3. ⛔⛔ THE GUARD BUG, AND WHY IT MATTERS BEYOND ITSELF
The convergence guard first gated **`resid_state`** against **`PS_TOL`** — not the same quantity.
`PS_TOL` is the **CARBON NEWTON's** tolerance and `resid_carbon` the residual of the vector it drives
(one row being the **ANNUAL-MEAN PIN**); `resid_state` is `max|Φ(y) − y|` over every row and all three
tracers with **no pin substitution**. Measured at `ccx_init_unc()` + a luc/bomb perturbation:
`resid_carbon` **3.71e−10 (CONVERGED, 3 iterations)** while `resid_state` was **1.354e−09** — on a
**3.90e+04 GtC** inventory, i.e. **3.5e−14 RELATIVE**, a floating-point floor. ⚠ The max was
**CARBON's own**, not an isotope's (C13 2.8e−14, C14 6.8e−13) — which refuted my first hypothesis.
⇒ It returned **−Inf on good arms**: the 2026-08-11 failure reincarnated, **a posterior truncated by
numerics wearing a prior's clothes.** ⭐ **The tell was that the test numbers were not DIFFERENT, they
were ABSENT (NaN/−Inf).**
⚠ **The same mismatch was already in the 09-09w code** — `diag_periodic_spinup.R`'s GATE P1 — and had
PASSED only because that mode's raw atmospheric return happened to be small. Corrected, verdict
unchanged. ⛔ My own new test asserted the absolute form too and **would have ratified the bug**.

## 4. NON-OBVIOUS STATE
- ⚠⚠ **`make_port_targets.R` MUST be run with `CCX_MS_STRUCT=hilda` EXPORTED.** It reads the structure
  from that variable and `ccx_apply_structure()` defaults to `""` = the **COLUMN** model, while the
  sbatch defaults the same variable to `hilda`. Run with it unset it writes COLUMN targets — cold init
  **−5,436,208** — which I first misread as an adoption catastrophe; it was a column model compared
  against hilda targets ⇒ [[like_for_like_forcing]]. ✅ `run_dispersed_multistart.R:546` HARD-VALIDATES
  the `struct` column, so the mismatch would have been refused at the port gate.
- ⭐ **The adoption is a RESHAPING, not an offset**, so it cannot be corrected for arithmetically:
  cold **−167.24**, `hilda31` **−10.158**, incumbent **+88.70**, new_basin **+144.41**. ⚠ Four
  different points, none a periodic-spinup optimum ⇒ none is a like-for-like verdict.
- ⚠ **`as.data.frame(test_dir())` has SEPARATE `failed` and `error` columns.** Summing `failed` alone
  reported "FAIL 2" for a baseline the repo has always called **FAIL 3**. The counting driver now
  reports both and their sum.
- ⚠ `ccx_make_logpost()` needs `base_params = ccx_mode_base(md)` for a HILDA mode; on the column
  default the same vector scores **−2.3e7** and looks like a catastrophic regression.
- ⚠ `ccx_overlay_par()` expects a FULL fitted par set. To move a NON-fitted name edit the base list
  (`b <- base; b$seas_ml <- 1`); a `base_params` override of a FITTED name is **silently discarded**.
- `seas_amp_*`, `seas_drivers`, `seas_ml` are NOT fitted; `seas_T_amp_*`, `seas_lag_p_*`,
  `sst_seas_amp_*`, `ent_seas_amp_SH` are ⇒ [[ccx_seas_amp_dead_at_drivers]].
- Newton iterations: **3** at `seas_ml` = 0, **6** at `seas_ml` = 1 — the whole reason the cost factor
  differs between arms, so the `seas_ml` = 0 factor must not price a round-6 refit.
- Scratchpad holds frozen script copies and suite logs only; nothing load-bearing.

## 5. ⛔ WHAT I WOULD NOT DO NEXT
- **Do not submit the array before the preflight.** The wall arithmetic is marked stale in the sbatch
  for a reason, and a collapsed restart design **exits 0** rather than announcing itself.
- **Do not re-ship the bundle while an array is live** ⇒ [[never_reship_mid_array]].
- **Do not read the −10.158, the +88.70 or the +144.41 as a verdict** on the periodic spinup. All are
  at points fitted under the other one.
- **Do not read any stored `logpost`, `prior_z` or port target as current.**
- **Do not run `make_port_targets.R` without `CCX_MS_STRUCT=hilda`.**
- **Do not re-run the suite for counts without `stop_on_failure = FALSE`**, and do not read `failed`
  without `error`.
