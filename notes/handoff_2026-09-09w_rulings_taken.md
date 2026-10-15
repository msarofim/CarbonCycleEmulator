# Handoff — 2026-09-09w. **ALL FIVE RULINGS TAKEN AND THE SUITE IS GREEN AT 2397/3/4. ⭐⭐ THE PERIODIC SPINUP RETURNS 99.6 % OF P12's −514, SO THAT PENALTY WAS THE SEED AND "P12 IS PHYSICS" IS RETRACTED. BOTH PRIOR LEGS RE-CENTERED FROM data/ PRODUCTS; EVERY STORED LOGPOST IS STALE BY −0.811 AND THE LIKELIHOOD IS UNTOUCHED. ⛔ THE REFIT IS NEXT AND ONE RULING GATES IT.**

> ⚠ This header states what is DONE. For live state read `CHANGELOG.md` **09-09w** and **09-09w (2)**
> and **`INDEX_ccx_seas_ml.md`** (new — the round-6 arc, split off `INDEX_ccx_seas` today), not this
> line ⇒ [[status_field_carries_the_query]].

Read first: **CHANGELOG 09-09w and 09-09w (2)** — every number with its derivation. Memory:
[[ccx_f2_periodic_spinup_owed]] (REWRITTEN — it is now ANSWERED, not owed),
[[residual_named_not_computed]] (new), [[intersect_is_a_silent_default]] (new COMPARISON-form
section), `INDEX_ccx_seas_ml.md` (new), `INDEX_diag.md`.

---

## 0. WHAT THE NEXT SESSION SHOULD DO
1. ⛔⛔ **RULE §6 FIRST — it GATES THE REFIT and it is Marcus's.** Should the periodic spinup become
   **the OBJECTIVE's** spinup? Marcus ruled *build it*; adoption is a separate, larger step that
   changes what every future fit optimizes. **A refit under the aseasonal seed and one under the
   periodic seed are NOT comparable — pick BEFORE launching, not after.**
2. Then the refit: **31 par** (`ent_seas_amp_SH` KEPT — ruled), **LIKELIHOOD-only**, a **TORCH
   ARRAY** not a laptop job ⇒ [[consider_torch_first]].
3. Untouched review leads, still `[R]`: F3, F4, GATE Q's missing `test-gate-bounds` coverage,
   `ccx_loglik()`'s finite 0, and the §6/§7 pedagogy items from the 09-09t review.

## 1. STATE OF THE TREE
- **`CarbonCycleEmulator/main`, tree CLEAN, not pushed (no remote).** This session's commits, oldest
  first: `d8be300` (settle review §7 by computation) → `f95f65e` (propagate the retraction) →
  `78b00d5` (ruling 1: `streams` repair + the periodic spinup) → `959589d` (rulings 2 + 3) →
  `b971360` (the five contract tests) → `6c42883` (suite counts + the `test_dir` gotcha).
  ⚠ This note's own commit follows and is therefore not in that list
  ⇒ [[status_field_carries_the_query]].
- **`FaIRtoFrEDI`**: `290a603` registers the new memory index. Clean.
- ✅ **SUITE: PASS 2397 / FAIL 3 / SKIP 4.** The 3 are exactly the pre-existing set
  (`test-alpha-as.R:116,117`, `test-seas-lag-split.R:199`). **+10 over 09-09v's 2387** are the
  mutation-test assertions the five rewrites added. **No regression.**
- **`hilda31` still canonical. `seas_ml` still DEFAULT 0. NO REFIT RUN.** Nothing adopted beyond the
  five rulings.

## 2. ⭐⭐ THE PERIODIC SPINUP — BUILT, AND IT REVERSED A CONCLUSION
`calibration/lib_periodic_spinup.R` solves **Φ(y\*) = y\*** on the one-year map: Newton on the
carbon block (which carries the nonlinearity), then the isotope **MONODROMY** built exactly, since
both isotopes enter linearly once the carbon orbit is fixed and 12C does not read them. The pins are
`ccx_spinup()`'s own, moved from an **instant** to an **ANNUAL MEAN** — pinning the instant would
silently redefine `CO2_PI_PPM` as "CO₂ in January". `aux` is prepared from the SAME `p` that is
integrated and **that invariant is asserted**, because it is the 09-09t leak's exact mechanism
⇒ [[two_gates_one_mechanism]].

| quiet run 1750–2250 | excursion | settled offset vs `seas_ml` 0 |
|---|---|---|
| `seas_ml` 0 (**the floor**) | 0.0212 ppm | — |
| `seas_ml` 1, aseasonal | **17.5863** | **+2.4507 ppm** (= F2's own number) |
| `seas_ml` 1, **PERIODIC** | **0.0000** | **+0.0104 ppm** — 0.4 % kept |

⛔⛔ **P12's −514.38 IS REPRODUCED TO 0.003** as the level-row cost on the aseasonal seed
(**−514.383** — a `stopifnot` inside the script, not a number read off afterwards), and **the
periodic seed returns +512.53 of it, 99.6 %.** The CO₂ level rows go to **−132.29** against the
`seas_ml` 0 arm's **−130.44**.

⛔ **SO "P10 AND P12 ARE ONE FINDING AND IT IS PHYSICS" (09-09v) IS RETRACTED FOR P12.** The −514 was
the **aseasonal SEED**. There is no separate industrial-uptake component in those rows, and the
+2.45-vs-+2.857 arithmetic that inferred one does not survive. ⚠ **P10's own finding — the mechanism
changes anthropogenic uptake — is UNTOUCHED**; what is withdrawn is that P12 measured the same thing.

⭐ **The open question resolved as NEITHER posed branch.** The pin did not push the offset into the
ocean: the air kept 0.4 % and the ocean sits **−60.294 GtC** — the system found a different limit
cycle rather than trading the offset between two reservoirs.

⭐ **What is REAL once the seed is fixed** (unrefitted, `ent_seas_amp_SH` forced 0 on every arm):
`ocean_grad_dic` **−21.3**, `co2_seasonal_MLO` **−20.8**, `d13c_level_SPO` **−16.1**. The mechanism
buys **+515.2** on `co2_seasonal_SPO` with **no fitted amplitude** ⇒ unrefitted it is **+463.5
BETTER** than `seas_ml` 0, where on the aseasonal seed it was **48.7 WORSE**.

Both gates mutation-tested, neither threshold invented: **GATE P1** is an IDENTITY at the solver's
own tolerance (the aseasonal state fails it by ~10 orders of magnitude); **GATE P2**'s floor is the
same excursion measured on the `seas_ml` 0 arm — a co-located instrument, not a guess
⇒ [[threshold_from_obs_or_law]].

## 3. THE TWO PRIOR LEGS, AND WHAT THEY COST
Both `.ENT_SO_*` now **READ data/ products** — not re-typed at corrected values, which would be the
same defect at a better number ⇒ [[derived_must_mean_computed]].

| | was | now |
|---|---|---|
| `.ENT_SO_SST_AMP` | 3.0 (the band **P2P** labeled "half-amplitude") | **1.499498** K |
| `.ENT_SO_PCO2_AMP` | 19.45 (the **per-cell** reduction) | **16.258289** µatm |
| `ENT_SEAS_AMP_SH_INBAND` | 29.68 | **17.7574** |
| `ENT_SEAS_AMP_SH_DERIV` (**the prior center**) | 10.95 | **6.5525** |
| `h_ml` prior center | 83.94 m | **59.69 m**; P8 exposure 61.3 % → **23.8 %** |

⭐ `data-raw/build_so_sst_seas_amp.R`'s **GATE 1 is the point**: it reproduces the already-registered
`SST_SEAS_AMP_SH_OBS` (1.74644) from the same product, mask, window and estimator to **1.9e−05**,
and **FAILS on the p2p and on the band row** — so the band figure is like-for-like with the
hemispheric constant beside it rather than a second convention. ✅ It also **falsifies
`constants.R`'s own comment**: the band does **NOT** swing harder than the hemisphere
(1.4995 < 1.7464); that read true only by comparing a p2p against a half-amp
⇒ [[like_for_like_forcing]], [[amp_definition_mismatch]] (third incident).
⚠ The review's claim that the **pCO₂** leg was ALSO a p2p stays **REFUTED** — a p2p would be ≈39;
its defect was 4.8 %, not 2×.

⛔ **THE COST, MEASURED: log-prior −39.234715 → −40.045695 (−0.8110). THE LIKELIHOOD IS UNTOUCHED at
−1439.424788** (neither constant enters the model). **Every stored `logpost` and every stored
`prior_z` is now STALE by exactly that shift — COMPARE ON LIKELIHOOD.**
`ent_seas_amp_SH`'s z: +1.310 → **+2.34** (now a strained prior). `h_ml`'s: −1.577 → **−0.57**.

⚠⚠ **`h_ml`'s prior WIDTH is deliberately UNCHANGED and is a FLAGGED CHOICE, not a derivation** — it
still spans an ambiguity round 6 discharged, and the 23.8 % Marcus ruled on was computed at that
width. Re-deriving it (from `sd_cell_m`, say) is a SECOND methodological move and was NOT taken.

## 4. THE `streams` REPAIR, AND THE SILENT GATE BEHIND IT
`calibration/repair_canonical_streams.R` rewrote the canonical file's `streams` (**−4.7543**),
keeping `streams_as_fitted` and `streams_provenance`, quarantining the pre-repair copy to
`calibration/output/quarantine/20260909w_d14c_profile_rows_missing/` with a README.
**It REFUSES TO WRITE unless `logpost − logprior` reconciles** — a file that does not reconcile is a
refit obligation, not a stale field — and that gate is mutation-tested against the stored set, a
moved logpost and a dropped row. **ONE vintage, not two**, unlike the 08-22 repair it copies.

⭐ **The gate that should have caught it**: `diag_adoption_read_hilda31.R:29` `intersect()`ed the
name sets before comparing, and a `max|diff|` over an intersection **CANNOT FAIL ON A SUBSTITUTION**
— it returned 1.4e−10 and PASSED at adoption, while 13 sites read the stale field. Now asserts
`setequal(names)` and stops.
⛔ `repair_arm_streams.R` is **itself a stale producer** (its `ccx_loglik()` passes no `d14c_mid`)
and carries a banner saying so; its arms are retired and its own guard stops it re-running.

## 5. ✅ THE FIVE CONTRACT TESTS — REPORTED FIRST, THEN RULED, THEN UPDATED
Nine failures appeared after the prior moves: **3 pre-existing + 1 REAL BUG + 5 encoding the
superseded contract.** The 5 were **reported to Marcus before being touched** (per
`~/.claude/CLAUDE.md`: a previously passing test is reported, not edited to pass); **he ruled update
all five, and KEEP the transcription.** Each was re-pointed with its POWER preserved and
mutation-tested.

- ✅ **THE REAL BUG, and its guard worked exactly as designed.** `test-ent-seas-fitted.R:27` ties
  `CCX_PARAM_TABLE$ent_seas_amp_SH$init` to the derived center at the TYPED PRECISION. The center
  moved and `init` did not: **drift 4.3999**, caught the same day ⇒ [[derived_must_mean_computed]].
  **FIXED IN THE CODE** (10.952353 → **6.552465**), not in the test. ⚠ It stays a literal because
  `CCX_PARAM_TABLE` is built in `calibrate.R`, which the alphabetical bootstrap sources BEFORE
  `constants.R`; the `prior` closure beside it CAN call `ccx_const()` because it runs later.
- `test-enso-demean.R:144` gated on the file's **STORED ABSOLUTE LOGPOST** and failed by exactly
  **−0.811** on a perfectly correct arm — the **THIRD** instance of
  [[compare_gaps_not_absolute_logposts]]. **Repaired by DERIVATION, not re-baselining**
  ⇒ [[stale_fixture_repair]]: harness logpost **minus the log-prior** must equal the file's own
  stored per-stream **likelihood**. **Strictly STRONGER** (pins 25 rows' sum, not one total), immune
  to any prior move, and it still fails the moment the harness scores a different vector. Two
  mutations assert it can fail.
- `test-ent-seas-fitted.R:55,58` — **transcription KEPT** (ruled), values updated to 1.499498 and
  16.258289, **plus the half that keeps a STALE transcription from passing quietly**: an assertion
  that each transcribed value still equals the product's own. Tolerance 1e−10 → **1e−6**, the
  precision a 6-decimal literal can actually deliver.
- `test-u-hs-fitted.R:32,36` — asserted the **retired** geometric-mean encoding. Replaced by the
  ruled contract plus the **P8 exposure**, which is what the ruling was actually about;
  mutation-tested so that the retired center is *rejected*. The unchanged WIDTH is now asserted too,
  so a future re-derivation is a deliberate act rather than a drift.

## 6. ⛔⛔ THE ONE RULING OWED — AND IT GATES THE REFIT
**Should the PERIODIC spinup become the OBJECTIVE's spinup?** Marcus ruled *build it*; adoption is a
further, larger step and was deliberately NOT taken.
- **FOR**: the aseasonal seed puts a **+19.9 ppm shock** at 1750 and a flat **+2.45 ppm** bias into
  every `seas_ml = 1` run — a defect in a **PEDAGOGICAL** model on its own terms
  ⇒ [[ccx_pedagogical_not_emulator]] — worth **+512.53** on the level rows unrefitted.
- **AGAINST / CHECK FIRST**:
  - ⚠ **COST IS NOT PROFILED INSIDE `ccx_make_logpost()`.** ~37 one-year runs per Newton iteration
    *on top of* the existing spinup; seconds per call in the diagnostic, but the refit is a Torch
    array of thousands of evaluations. **PROFILE BEFORE ADOPTING** ⇒ [[eta_in_days_is_not_a_slow_run]].
  - ⚠ It **changes the OBJECTIVE**, so every stored logpost becomes non-comparable — a SECOND
    re-baselining on top of the −0.811.
  - ⚠ At `seas_ml = 0` it must be a no-op; **gate that BIT-IDENTICAL before adoption**, or every
    column-era result moves.
  - ⚠ The periodic object **inherits unrecomputed `$diagnostics` fields** from the aseasonal seed
    (`d14c_deep_ocean`, `land_C_GtC`, `d13c_atm`, …); the ones the OBJECTIVE reads ARE recomputed
    (`d14c_bottom_box`, `co2_ppm`, `ocean_C_GtC`, the three residuals). **Before adoption, extract
    `ccx_spinup()`'s diagnostics block into ONE producer both spinups call** — a second copy is the
    defect class this whole session was about ⇒ [[two_gates_one_mechanism]].
- ⛔ **A refit under the aseasonal spinup and one under the periodic spinup ARE NOT COMPARABLE.**

## 7. NON-OBVIOUS STATE
- ⭐ **`R/aaa_root.R` IS NEW AND ITS NAME IS LOAD-BEARING.** `REPO_MARKER`, `ccx_root()` and
  `ccx_path()` were hoisted out of `paths.R` because the alphabetical `list.files("R", ...)`
  bootstrap sources `calibrate.R` and `constants.R` BEFORE `paths.R`, and the new constants need a
  path at SOURCE time. ⛔ **The first attempt used a relative `"data/..."` fallback and took the
  ENTIRE SUITE DOWN** — testthat runs from `tests/testthat/` and the app from `app/`, exactly as
  `paths.R`'s own header says. Verified resolving from all three directories. **Do not rename it,
  and do not add anything else to it.**
- ⛔ **`testthat::test_dir()` RAISES on any failure**, so `r <- test_dir(...); cat(summary(r))`
  **halts before printing** and yields no counts. **It presents as a slow run and is not one** —
  it cost two full 15-minute runs today. Pass `stop_on_failure = FALSE` when the counts are the
  point, or parse the `reporter = "summary"` log already produced. ⭐ The second run was pure waste:
  the failure LIST was already in hand and only the tallies were missing.
- ⛔ **`test-mode-struct-lint.R`'s literal rule is EVADED by splitting the call across two
  statements** (`f <- ccx_mode_file(...)` then `readRDS(f)`). `repair_canonical_streams.R` does
  exactly that and is benign — it resolves through `dg_vector()` — but the lint could not have told.
  **NOT fixed; a decision, since tightening it would re-scan 30 files.**
- **`INDEX_ccx_seas.md` was SPLIT** at 19,841 B of its 18 KB hard ceiling — the SECOND split off it.
  The round-6 arc is now **`INDEX_ccx_seas_ml.md`**. Post-split 8,494 + 15,978 B; `_ml` is over its
  14 KB soft target and under the hard ceiling ⇒ merge when convenient. Straddlers named in `_ml`'s
  header; an orphan sweep over twelve round-6 terms found nothing lost.
- ⚠ **The ROOT `MEMORY.md` is at 17,921 B of an 18,432 B hard ceiling** (soft target 12,288). It was
  already at 17,575 before today. **A root restructure is owed and is Marcus's call about what
  stays** ⇒ [[memory_index_split_beats_trim]], [[memory_budget_is_content_not_file]].
- The session scratchpad holds throwaway probes only; nothing there is load-bearing.

## 8. ⛔ WHAT I WOULD NOT DO NEXT
- **Do not launch the refit before §6 is ruled.** The two objectives are not comparable.
- **Do not quote the +463.5 as a refit result.** It is UNREFITTED, with `ent_seas_amp_SH` forced to
  0 on every arm.
- **Do not read any stored `logpost` or `prior_z` as current.** Both are stale by the prior shift;
  the LIKELIHOOD is the comparable quantity.
- **Do not re-derive `h_ml`'s prior width** without a ruling — the 23.8 % rests on the current one.
- **Do not re-run the suite for counts without `stop_on_failure = FALSE`.** See §7.

## 9. THE THROUGH-LINE, because three failures today were the same shape
All three were **a quantity that looked plausible but was not the quantity intended**:
the **43.99** named "the log-prior" instead of computed (**it was 39.23**, and the two readings meant
a refit vs a cosmetic repair); **`intersect()` in a gate** that cannot see a substitution; and a
**stored absolute logpost** used as a fixture. ⚠ The third was **already written down in memory**
and still caught us — which is why its test was repaired by DERIVATION rather than re-baselined.
⇒ [[residual_named_not_computed]], [[verify_the_quantity_not_the_word]].
