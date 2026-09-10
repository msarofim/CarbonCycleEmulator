# Handoff — 2026-09-09x. **THE ADOPTION RULING IS PRICED BUT STILL UNRULED. ⭐⭐ COST IS ~3× AND AFFORDABLE (≈5 h/start), BUT THE "NO-OP AT `seas_ml` = 0" EXPECTATION IS REFUTED — ADOPTION MOVES THE COLUMN ERA BY −10.158 IN LIKELIHOOD. AND THE OFF-ORBIT DEFECT IS SEASONALITY ITSELF, SO IT PREDATES ROUND 6 AND THE 08-18 DRIVER PATH. THE DUPLICATED DIAGNOSTICS BLOCK IS FIXED. NOTHING ADOPTED; NO DEFAULT CHANGED.**

> ⚠ This header states what is DONE. For live state read `CHANGELOG.md` **09-09x** and
> **`INDEX_ccx_seas_ml.md`**, not this line ⇒ [[status_field_carries_the_query]].

Read first: **CHANGELOG 09-09x** — every number with its derivation. Memory:
[[ccx_periodic_adoption_priced]] (new), [[ccx_seas_amp_dead_at_drivers]] (new),
[[ccx_f2_periodic_spinup_owed]] (linked forward), `INDEX_ccx_seas_ml.md`.

---

## 0. WHAT THE NEXT SESSION SHOULD DO
1. ⛔⛔ **THE RULING IS STILL MARCUS'S AND STILL GATES THE REFIT** — but it is no longer a cold
   question. §2 below is the FOR/AGAINST with every number measured. The new fact he did not have:
   **adoption is not confined to the `seas_ml = 1` arm; it moves the COLUMN ERA by −10.158 in
   likelihood**, so it is a third re-baselining rather than a round-6 detail.
2. Then the refit: **31 par** (`ent_seas_amp_SH` KEPT — ruled 09-09w), **LIKELIHOOD-only**, a **TORCH
   ARRAY** not a laptop job ⇒ [[consider_torch_first]]. Priced at **≈5.05 h per start** under the
   periodic spinup against ≈1.65 h under the aseasonal one.
3. Untouched review leads, still `[R]`: F3, F4, GATE Q's missing `test-gate-bounds` coverage,
   `ccx_loglik()`'s finite 0, and the §6/§7 pedagogy items from the 09-09t review.
4. ⚠ **Two memory-budget items are owed and both are Marcus's call about what stays**: root
   `MEMORY.md` at **17,921 B of 18,432** (unchanged today — deliberately not touched), and
   `INDEX_ccx_seas_ml.md` now at **17,176 B of 18,432** (was 15,979). Content bytes, comment blocks
   stripped ⇒ [[memory_budget_is_content_not_file]], [[memory_index_split_beats_trim]].

## 1. STATE OF THE TREE
- **`CarbonCycleEmulator/main`**, no remote. This session's changes: `R/spinup.R` (the new producer),
  `calibration/lib_periodic_spinup.R` (routed through it), `R/calibrate.R` (two new default-inert
  arguments), `calibration/diag_periodic_spinup_adoption.R` (new),
  `tests/testthat/test-spinup-diagnostics.R` (new, 37 assertions), `CHANGELOG.md`.
- **`hilda31` still canonical. `seas_ml` still DEFAULT 0. NO REFIT RUN. NOTHING ADOPTED** — in
  particular `ccx_make_logpost()`'s `spinup_fn` still defaults to `ccx_spinup`.
- ✅ **The aseasonal path is verified to have moved NOTHING**: the objective at `hilda31`'s `u_mode`
  returns likelihood **−1439.424788**, log-prior **−40.045695**, total **−1479.470483** — matching
  09-09w's post-prior-shift figures to all printed digits. ⚠ **The stored `logpost` −1478.659503 is
  still STALE by the 09-09w prior shift (−0.811). COMPARE ON LIKELIHOOD.**

## 2. ⛔⛔ THE RULING, WITH ITS THREE CHECKS NOW ANSWERED
**Should the PERIODIC spinup become the OBJECTIVE's spinup?**

**FOR**
- The aseasonal seed puts a **+19.9 ppm shock** at 1750 and a flat **+2.45 ppm** bias into every
  `seas_ml = 1` run — a defect in a **PEDAGOGICAL** model on its own terms
  ⇒ [[ccx_pedagogical_not_emulator]] — worth **+512.53** on the level rows unrefitted.
- ⭐⭐ **NEW, and it strengthens the FOR case: the defect is NOT round 6's.** With the driver path
  live the off-orbit cost at `seas_ml = 0` is **−10.158**; with the legacy SINE path instead
  (`seas_drivers = 0`, amps 12/2) it is **−10.520**, within **4 %**; with **BOTH off** it is
  **+2.1e−08**, an identity at solver tolerance separating the arms by >8 orders. ⇒ **the aseasonal
  spinup has never been on the model's own orbit for ANY seasonal configuration.** Adoption is
  therefore *correcting a spinup that was always wrong*, not *changing the objective for round 6*.
- ✅ **COST IS THE CHEAP SIDE OF THE WORRY** (the handoff's own load-bearing unknown): **2.15×** at
  `seas_ml` = 0, **~2.9–3.1×** at `seas_ml` = 1. Priced off the mode file's OWN refit (36,569 evals /
  99.2 min): **≈5.05 h for ONE start** ⇒ [[eta_in_days_is_not_a_slow_run]].

**AGAINST**
- ⛔⛔ **IT MOVES THE COLUMN ERA, and the "gate it BIT-IDENTICAL at `seas_ml` = 0" instruction CANNOT
  BE SATISFIED.** `ccx_spinup()` zeroes **FOUR** seasonal paths in its `p0` (`seas_amp_NH`,
  `seas_amp_SH`, `seas_drivers`, `seas_ml`) and the instruction named the fourth only
  ⇒ [[verify_the_quantity_not_the_word]]. Measured at `hilda31`: likelihood **−1439.4248 →
  −1449.5827 (−10.158)**, max|dy| **0.697 GtC** (3.50 % rel), ocean **−0.9139 GtC**, CO₂ delta
  **exactly 0** (PINNED). So adoption is a **THIRD re-baselining** after the −0.811.
- ⚠ Concentrated, not diffuse: TWO of 25 streams with OPPOSITE signs — `d13c_level_SPO` **−16.732**,
  `d13c_level_MLO` **+8.282** — every other stream ≤ 1.02. An INTERHEMISPHERIC d13C shift.

⚠⚠ **WHAT THE −10.158 IS NOT.** It is **not** evidence the periodic spinup fits worse. The mode was
FITTED under the aseasonal spinup, so re-scoring it at the *old optimum* under a different spinup is
not a comparison ⇒ [[like_for_like_forcing]]. It measures **non-comparability only.** Direction needs
a refit.

⛔ **A refit under the aseasonal spinup and one under the periodic spinup ARE NOT COMPARABLE — pick
BEFORE launching, not after.**

## 3. ✅ THE CODE FIX THAT WAS OWED REGARDLESS
`ccx_spinup_diagnostics()` in `R/spinup.R` is now the **ONE producer** both spinups call.
`ccx_periodic_spinup()` had inherited `sp0$diagnostics` and overwritten **6 of 19** fields; the other
13 carried the ASEASONAL SEED's value — sharpest, **`prod_c14_mol_yr`/`prod_ratio` contradicted the
object's own `$prod_c14`** (415.860811 vs 415.861951) because the periodic solve re-solves production
⇒ [[two_gates_one_mechanism]].
⭐ **The two ESTIMATOR-DEPENDENT rows are REQUIRED ARGUMENTS with no defaults** — `residuals`
(instantaneous |dy/dt| vs |Φ(y)−y| over one period) and `co2_ppm` (an instant vs an ANNUAL MEAN) mean
different things in the two solves, and a default is exactly how one caller inherits the other's
convention. Mutation-tested; the pre-fix inherited list is shown to FAIL.

## 4. ⚠ TWO NEW ARGUMENTS ON `ccx_make_logpost()`, BOTH DEFAULT-INERT
- **`spinup_fn = ccx_spinup`** — so the periodic spinup is scored by **THE objective** rather than by
  a second copy of the scoring path. ⛔⛔ **CHANGING THIS DEFAULT IS ADOPTION.** It is Marcus's
  ruling and must never be flipped as a side effect of another change.
- **`by_stream = FALSE`** — TRUE returns the same scalar carrying `attr(, "streams")` from the
  objective's OWN `ccx_loglik()` call. Ten `calibration/` diagnostics rebuild that call by hand and
  on 09-09w one (`repair_arm_streams.R`) was found omitting `d14c_mid`, i.e. producing a stream set
  for a different objective than the one being fitted.
Both are gated inert in `test-spinup-diagnostics.R`.

## 5. ⭐ A DEAD PARAMETER, AND HOW IT WAS FOUND
`seas_amp_NH = 12` / `seas_amp_SH = 2` in the canonical mode's base list are **DEAD** at
`seas_drivers = 1`. `R/model.R:1291-1296` says so ("THE SINE'S KNOBS, live only at
`seas_drivers = 0`") and nothing tested it. Now gated **both ways**: symmetrising to 7/7 moves the
objective by **exactly 0** at `seas_drivers = 1` and by **−1854.94** at `seas_drivers = 0`.
⚠ **And `seas_drivers = 0` is NOT an aseasonal control** — it hands seasonality to the sine at those
amplitudes ⇒ [[ccx_seas_amp_dead_at_drivers]].

## 6. ⛔ MY OWN TWO ERRORS, BOTH THIS SESSION'S OWN THROUGH-LINE
Recorded because they are the 09-09w family — *a quantity that looked plausible but was not the
quantity intended* — and both were caught by their own printed output, not by a gate:
1. **"the periodic solve was 130 % of the evaluation containing it"** — impossible. A single **COLD**
   solve timing against a **WARM** per-evaluation average. Fixed: one warm-first timing helper, and
   an assertion that a part cannot exceed its whole.
2. **A NULL WITH NO POWER, read as a result.** The first CHECK 4 "tested" the hemispheric asymmetry
   by symmetrising `seas_amp_*` and got a figure **identical in every printed digit** to the
   as-fitted arm; I first read that as "100 % of it". It was a dead parameter
   ⇒ [[no_power_null]]. ⚠ The corrected arm then failed its OWN first identity — `seas_drivers = 0`
   does not remove seasonality — and that failure is how the "seasonality itself" finding in §2 was
   found. **Both kept as gates, not deleted.**

## 7. NON-OBVIOUS STATE
- ⚠ **`ccx_make_logpost()` needs `base_params = ccx_mode_base(md)` for a HILDA mode.** Called with
  the default `ccx_default_params()` it returns **−23,306,101** at `hilda31`'s `u_mode` and looks
  like a catastrophic regression. It is not; it is the wrong base list.
- ⚠ **`ccx_overlay_par()` expects a FULL fitted par set** and migrates it — a one-name list like
  `list(seas_ml = 1)` raises inside `ccx_migrate_par_set()`. To move a NON-fitted name, edit the base
  list directly (`b <- base; b$seas_ml <- 1`). To move a FITTED one you must move `u`: a
  `base_params` override of a fitted name is **silently discarded** by the objective's own
  `for (n in intersect(names(p), CCX_PARAM_NAMES))` loop.
- The fitted seasonal names are `seas_T_amp_*`, `seas_lag_p_*`, `sst_seas_amp_*`, `ent_seas_amp_SH`;
  `seas_amp_*`, `seas_drivers` and `seas_ml` are **NOT** fitted and ride in `base_params`.
- Newton iterations for the periodic solve: **3** at `seas_ml` = 0, **6** at `seas_ml` = 1. That is
  the whole reason the cost factor differs between the arms, so the `seas_ml` = 0 factor must not be
  used to price a round-6 refit.
- The session scratchpad holds frozen copies of the diagnostic and the suite driver only; nothing
  there is load-bearing.

## 8. ⛔ WHAT I WOULD NOT DO NEXT
- **Do not flip `spinup_fn`'s default.** That is the unruled adoption.
- **Do not launch the refit before the ruling.** The two objectives are not comparable.
- **Do not read the −10.158 as "the periodic spinup fits worse."** It is measured at a mode fitted
  under the other spinup.
- **Do not read any stored `logpost` or `prior_z` as current** — both stale by the 09-09w −0.811.
- **Do not re-run the suite for counts without `stop_on_failure = FALSE`** (09-09w §7).
- **Do not treat `seas_drivers = 0` as an aseasonal control.** See §5.
