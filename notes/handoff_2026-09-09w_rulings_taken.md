# Handoff — 2026-09-09w. **ALL FOUR RULINGS TAKEN. ⭐⭐ THE PERIODIC SPINUP RETURNS 99.6 % OF P12's −514, SO THAT PENALTY WAS THE SEED AND "P12 IS PHYSICS" IS RETRACTED. BOTH PRIOR LEGS RE-CENTRED FROM data/ PRODUCTS; EVERY STORED LOGPOST IS NOW STALE BY −0.811 AND THE LIKELIHOOD IS UNTOUCHED. ⛔ THE REFIT IS THE NEXT STEP, AND ONE QUESTION MUST BE RULED BEFORE IT.**

> ⚠ This header states what is DONE. For live state read `CHANGELOG.md` 09-09w and
> **`INDEX_ccx_seas_ml.md`** (new — the round-6 arc split off `INDEX_ccx_seas` today), not this
> line ⇒ [[status_field_carries_the_query]].

Read first: **CHANGELOG 09-09w and 09-09w (2)** — every number with its derivation. Memory:
[[ccx_f2_periodic_spinup_owed]] (rewritten — it is now ANSWERED), [[residual_named_not_computed]]
(new), [[intersect_is_a_silent_default]] (the COMPARISON form, new section),
`INDEX_ccx_seas_ml.md`, `INDEX_diag.md`.

---

## 0. WHAT THE NEXT SESSION SHOULD DO
1. ⛔⛔ **RULE THE ADOPTION QUESTION FIRST — §6. It is Marcus's and it gates the refit.** Marcus
   ruled "BUILD the periodic spinup"; whether it becomes **the OBJECTIVE's** spinup is a separate,
   larger decision that changes what every future fit optimises. **Do not start the refit until it
   is ruled**, because the two choices optimise different objectives.
2. Then the refit: **31 par** (`ent_seas_amp_SH` KEPT — ruled), **LIKELIHOOD-only**, a TORCH ARRAY
   not a laptop job ⇒ [[consider_torch_first]].
3. Untouched review leads, still `[R]`: F3, F4, GATE Q's missing `test-gate-bounds` coverage,
   `ccx_loglik()`'s finite 0, the §6/§7 pedagogy items.

## 1. STATE OF THE TREE
- **`main`**, not pushed (no remote). Commits this session, oldest first:
  `d8be300` (settle review §7), `f95f65e` (propagate the retraction), `78b00d5` (ruling 1:
  streams repair + the periodic spinup), `959589d` (rulings 2 + 3), plus the test repair.
  `FaIRtoFrEDI` carries `290a603` (register the new memory index).
- **`hilda31` still canonical. `seas_ml` still DEFAULT 0. NO REFIT RUN. Nothing adopted beyond the
  four rulings.**

## 2. ⭐⭐ THE PERIODIC SPINUP — BUILT, AND IT REVERSED A CONCLUSION
`calibration/lib_periodic_spinup.R` solves **Φ(y\*) = y\*** on the one-year map: Newton on the
carbon block (which carries the nonlinearity), then the isotope **MONODROMY** built exactly, since
both isotopes enter linearly once the carbon orbit is fixed. Pins are `ccx_spinup()`'s own, moved
from an **instant** to an **ANNUAL MEAN**. `aux` is prepared from the SAME `p` that is integrated
and that invariant is **asserted** — it is the 09-09t leak's exact mechanism.

| quiet run 1750–2250 | excursion | settled offset vs `seas_ml` 0 |
|---|---|---|
| `seas_ml` 0 (**the floor**) | 0.0212 ppm | — |
| `seas_ml` 1, aseasonal | **17.5863** | **+2.4507 ppm** (= F2's own number) |
| `seas_ml` 1, **PERIODIC** | **0.0000** | **+0.0104 ppm** — 0.4 % kept |

⛔⛔ **P12's −514.38 IS REPRODUCED to 0.003** as the level-row cost on the aseasonal seed
(−514.383 — a `stopifnot` in the script, not a number read off afterwards), and **the periodic seed
returns +512.53 of it, 99.6 %.** The CO₂ level rows go to −132.29 against the `seas_ml` 0 arm's
−130.44.

⛔ **SO "P10 AND P12 ARE ONE FINDING AND IT IS PHYSICS" (09-09v) IS RETRACTED FOR P12.** The −514
was the **aseasonal SEED**. There is no separate industrial-uptake component in those rows and the
+2.45-vs-+2.857 arithmetic that inferred one does not survive. ⚠ **P10's own finding is UNTOUCHED.**

⭐ **The open question resolved as NEITHER posed branch.** The pin did not push the offset into the
ocean: the air kept 0.4 % and the ocean sits **−60.294 GtC** — the system found a different limit
cycle rather than trading the offset between two reservoirs.

⭐ **What is REAL once the seed is fixed** (unrefitted, `ent_seas_amp_SH` forced 0 on every arm):
`ocean_grad_dic` **−21.3**, `co2_seasonal_MLO` **−20.8**, `d13c_level_SPO` **−16.1**. The mechanism
buys **+515.2** on `co2_seasonal_SPO` with **no fitted amplitude** ⇒ unrefitted it is **+463.5
BETTER** than `seas_ml` 0, where on the aseasonal seed it was **48.7 WORSE**.

Both gates mutation-tested, neither threshold invented: **GATE P1** is an IDENTITY at the solver's
own tolerance (the aseasonal state fails it by ~10 orders); **GATE P2**'s floor is the same
excursion measured on the `seas_ml` 0 arm — a co-located instrument ⇒ [[threshold_from_obs_or_law]].

## 3. THE TWO PRIOR LEGS, AND WHAT THEY COST
Both `.ENT_SO_*` now READ data/ products — not re-typed at corrected values, which would be the
same defect at a better number ⇒ [[derived_must_mean_computed]].

| | was | now |
|---|---|---|
| `.ENT_SO_SST_AMP` | 3.0 (the band **P2P** labelled "half-amplitude") | **1.499498** K |
| `.ENT_SO_PCO2_AMP` | 19.45 (the **per-cell** reduction) | **16.258289** µatm |
| `ENT_SEAS_AMP_SH_DERIV` (**prior centre**) | 10.95 | **6.5525** |
| `h_ml` prior centre | 83.94 m | **59.69 m**; P8 exposure 61.3 % → **23.8 %** |

⭐ `data-raw/build_so_sst_seas_amp.R`'s **GATE 1** reproduces the already-registered
`SST_SEAS_AMP_SH_OBS` (1.74644) from the same product, mask, window and estimator to **1.9e−05**,
and FAILS on the p2p and on the band row. ✅ It also falsifies `constants.R`'s own comment: the band
does **NOT** swing harder than the hemisphere (1.4995 < 1.7464).

⛔ **THE COST, MEASURED: log-prior −39.234715 → −40.045695 (−0.8110). THE LIKELIHOOD IS UNTOUCHED at
−1439.424788** (neither constant enters the model). **Every stored `logpost` and every stored
`prior_z` is now STALE by exactly that shift — COMPARE ON LIKELIHOOD.**
`ent_seas_amp_SH`'s z: +1.310 → **+2.34** (now strained). `h_ml`'s: −1.577 → **−0.57**.

⚠⚠ **`h_ml`'s prior WIDTH is deliberately UNCHANGED and is a FLAGGED CHOICE, not a derivation** —
it still spans an ambiguity round 6 discharged, and the 23.8 % Marcus ruled on was computed at that
width. Re-deriving it (from `sd_cell_m`, say) is a SECOND methodological move and was NOT taken.

## 4. THE `streams` REPAIR, AND THE SILENT GATE BEHIND IT
`calibration/repair_canonical_streams.R` rewrote the canonical file's `streams` (−4.7543), keeping
`streams_as_fitted` and `streams_provenance` and quarantining the pre-repair copy to
`calibration/output/quarantine/20260909w_d14c_profile_rows_missing/`. **It refuses to write unless
`logpost − logprior` reconciles**, because a file that does not reconcile is a refit obligation
rather than a stale field; mutation-tested. **ONE vintage, not two.**

⭐ **The gate that should have caught it:** `diag_adoption_read_hilda31.R:29` `intersect()`ed the
name sets before comparing, so a `max|diff|` **cannot fail on a SUBSTITUTION** — it returned
1.4e−10 and PASSED at adoption. Now asserts `setequal(names)` and stops.
⛔ `repair_arm_streams.R` is **itself a stale producer** (no `d14c_mid`) and carries a banner.

## 5. ⚠ THE SUITE, AND WHAT WAS AND WAS NOT EDITED
Nine failures appeared: **3 pre-existing + 1 REAL BUG + 5 encoding the superseded contract.**
- ✅ **The real bug, caught by its own guard**: `ent_seas_amp_SH$init` is a typed literal that must
  track the derived centre; the centre moved and it did not (**drift 4.3999**). **FIXED IN THE
  CODE** (10.952353 → 6.552465), not in the test. It stays a literal because `CCX_PARAM_TABLE` is
  built in `calibrate.R`, which the bootstrap sources BEFORE `constants.R`.
- **The 5 were reported to Marcus BEFORE being touched, and he ruled: update all five.** Each was
  re-pointed at the new contract with its POWER preserved and mutation-tested:
  - `test-enso-demean.R:144` gated on a **STORED ABSOLUTE LOGPOST** (off by exactly −0.811) — the
    **THIRD** instance of [[compare_gaps_not_absolute_logposts]]. Repaired **by DERIVATION, not
    re-baselining**: harness logpost − log-prior must equal the file's own stored per-stream
    likelihood. **Strictly stronger** (25 rows, not one total) and immune to any prior move.
  - `test-ent-seas-fitted.R:55,58` — **transcription KEPT** (ruled), values updated, **plus a new
    assertion that the transcription still equals the product's own number**, so a silent product
    rebuild cannot pass.
  - `test-u-hs-fitted.R:32,36` — the retired geometric-mean encoding replaced by the ruled contract
    plus the **P8 exposure**, which is what the ruling was actually about; mutation-tested against
    the retired centre.

## 6. ⛔⛔ THE ONE RULING OWED — AND IT GATES THE REFIT
**Should the PERIODIC spinup become the OBJECTIVE's spinup?** Marcus ruled "build it"; adoption is
a further, larger step and was deliberately NOT taken.
- **FOR**: the aseasonal seed puts a **+19.9 ppm shock** at 1750 and a flat **+2.45 ppm** bias into
  every `seas_ml = 1` run, which is a defect in a **pedagogical** model on its own terms
  ⇒ [[ccx_pedagogical_not_emulator]]. Unrefitted it is worth **+512.53** on the level rows alone.
- **AGAINST / TO CHECK FIRST**: ⚠ **cost** — the shooting solve is ~37 one-year runs per Newton
  iteration on top of the existing spinup; measured at **a few seconds** per call in the diagnostic,
  but it has **NOT been profiled inside `ccx_make_logpost()`**, and the refit is a Torch array of
  thousands of evaluations. **PROFILE IT BEFORE ADOPTING.** ⚠ It changes the objective, so **every**
  stored logpost becomes non-comparable — a second, larger re-baselining on top of the −0.811.
  ⚠ At `seas_ml = 0` it should be a no-op; **that must be gated bit-identical before adoption**, or
  every column-era result moves.
- ⛔ **A REFIT RUN UNDER THE ASEASONAL SPINUP AND ONE RUN UNDER THE PERIODIC SPINUP ARE NOT
  COMPARABLE.** Pick before launching, not after.

## 7. NON-OBVIOUS STATE
- ⭐ **`R/aaa_root.R` IS NEW AND ITS NAME IS LOAD-BEARING.** `REPO_MARKER`, `ccx_root()` and
  `ccx_path()` were hoisted out of `paths.R` because the alphabetical `list.files("R", ...)`
  bootstrap sources `calibrate.R` and `constants.R` BEFORE `paths.R`, and the new constants need a
  path at SOURCE time. ⛔ **The first attempt used a relative `"data/..."` fallback and took the
  ENTIRE SUITE DOWN** — testthat runs from `tests/testthat/`, the app from `app/`, exactly as
  `paths.R`'s own header says. Verified from all three directories. **Do not rename it, and do not
  add anything else to it.**
- ⛔ **`test-mode-struct-lint.R`'s literal rule is EVADED by splitting the call across two
  statements** (`f <- ccx_mode_file(...)` then `readRDS(f)`). `repair_canonical_streams.R` does
  exactly that and is benign — it resolves through `dg_vector()` — but the lint could not have told.
  **Not fixed; a decision, since tightening it would re-scan 30 files.**
- **`INDEX_ccx_seas.md` was SPLIT** (2026-09-09w) at 19,841 B of its 18 KB hard ceiling — the SECOND
  split off it. The round-6 arc is now **`INDEX_ccx_seas_ml.md`** (8,494 + 14,168 B, both in
  budget). Straddlers named in `_ml`'s header; orphan sweep over twelve terms found nothing lost.
- ⚠ **The ROOT `MEMORY.md` is at 17,921 B of an 18,432 B hard ceiling** (soft target 12,288). It was
  already at 17,575 before today. **A root restructure is owed and is Marcus's call about what
  stays** ⇒ [[memory_index_split_beats_trim]], [[memory_budget_is_content_not_file]].
- The periodic spinup's `$diagnostics` **inherits unrecomputed fields from the aseasonal seed**
  (`d14c_deep_ocean`, `land_C_GtC`, `d13c_atm`, …); the ones the OBJECTIVE reads are recomputed
  (`d14c_bottom_box`, `co2_ppm`, `ocean_C_GtC`, the three residuals). ⛔ **Before adoption, extract
  `ccx_spinup()`'s diagnostics block into ONE producer both spinups call** — a second copy is the
  defect class this whole session was about.

## 8. ⛔ WHAT I WOULD NOT DO NEXT
- **Do not launch the refit before §6 is ruled.** The two objectives are not comparable.
- **Do not quote the +463.5 as a refit result.** It is UNREFITTED with `ent_seas_amp_SH` forced to 0.
- **Do not read any stored `logpost` or `prior_z` as current.** Both are stale by the prior shift;
  the LIKELIHOOD is the comparable quantity.
- **Do not re-derive `h_ml`'s prior width** without a ruling — the 23.8 % rests on the current one.
