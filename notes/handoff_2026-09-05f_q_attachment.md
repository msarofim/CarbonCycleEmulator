# Handoff — CarbonCycleEmulator, 2026-09-05f (the `q` ATTACHMENT-DEPTH arc)
# **⭐ THE OUTCOME HOLDS — 2.048 → 1.739, under the reduced form's 1.81.**
# **⛔ THE MECHANISM I PRE-REGISTERED IS REFUTED: `kz` RISES, it does not relieve.**
# **⛔ TWO ERRORS OF MINE, BOTH CAUGHT BY MY OWN TESTS — §4 before quoting P3 or P4.**
# **✅ BOTH §5 ITEMS CLOSED 2026-09-06: the lint is FIXED and the ocean index is SPLIT — see §5.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, working tree CLEAN.
Commits **`5309195`, `5a95341`, `13eb0ad`, `2d29eff` (4)**. No remote.
⚠ **Sessions launch from `FaIRtoFrEDI/`; all of this is in `CarbonCycleEmulator/`.** Use `git -C`.

**Read before this one:** `handoff_2026-09-05_hilda_boxes_arc.md` — this arc is its §7 decision.

---

## 0. MARCUS'S RULING, WHICH SHAPED EVERYTHING

> *"We don't need to stay true to HILDA, but we should stay true to the conceptual way that the
> simplified model's ocean works."*

⇒ The departure from HILDA is **authorised**; the constraint is coherence with **CCX's** ocean. That
ruled out the cheap version of the move — attaching `q` low *because it scores better* would be
tuning geometry to the residual. The prereg's §1 therefore argues from CCX's structure alone, and
§3 declares the attachment set from a **non-score criterion** with **no free boundary**.

Also decided: **LICENSE = MIT** (`13eb0ad`). Rank 3 of the previous handoff, now closed.

## 1. WHAT WAS BUILT

**`q_attach_from`** — the shallowest interior layer HD exchanges with — in **both cores**.
**1 = every layer = HILDA's depth-independent `q` = the 09-05 structure BIT FOR BIT**; absence means
1, so nothing written earlier changes model. `hs_frac` still ships **0**; `ent26` untouched.
⚠ **`tau_q` is NOT renormalised over the subset** — a smaller set is *less* total exchange, not the
same exchange repacked. Deliberate and pinned by a test: renormalising would smuggle a rate change
in with a geometry change and neither could then be read.

## 2. THE RESULT

| arm (iso-deep, `kz` re-solved) | `kz` | `kz`/`kz₀` | **mean \|z\|** |
|---|---|---|---|
| layer 1 — HILDA, depth-independent | 1900 | 0.299 | **2.048** |
| layer 10 — **BOTTOM ONLY** | **2686** | 0.423 | **1.739** |

⛔⛔ **P1 FAILED AND THE FAILURE IS THE FINDING.** I predicted the deep's own pathway would *relieve*
`kz`, as 09-04k2's reduced form did (0.50×). **It rises.** With `tau_q` per-layer, bottom-only is
*less* exchange, so `kz` must do *more*. Both arms still relieve against the incumbent.
⇒ **DO NOT CARRY 09-04k2's "the conduit relieves `kz`" FRAMING ONTO THIS ARM.**
⭐ **The gain IS the attachment**, by a **POST HOC** matched-`kz` decomposition: bottom dominates at
both `kz` values (0.377 vs 2.048 at 1900; 1.739 vs 3.092 at 2686). ⛔ Those two off-control numbers
**decompose only — never quote them as scores.**
⭐ **`tau_q` scan: HILDA's own central 538 is the best arm** (200 → 1.783, 1048 → 2.204; 28 and 100
hit the ceiling). **Nothing was tuned to land there.**
⛔ It does **not** reach DESIGN §3.4a's **|z| < 1** benchmark, and it is **NOT "HILDA's model."**

## 3. ✅ P0 IS CLEAN

**SUITE (verified 2026-09-06, full `test_dir`): 1861 pass / 0 FAIL / 4 skip / 66 warn.**
⭐ The counts reconstruct the 09-05 error exactly: **1861 − 19** (this arc's new
`test-q-attachment.R`) **= 1842**, the pass-count that handoff reported. So its 1842 was
RIGHT and its **"0 fail" was not** — the two lint failures came in with `d6587be`, the very
last commit, and the suite was never re-run after it.

identity **0.000e+00** · closure **1.08e-16** · parity **3.55e-14** (incumbent's own 1.14e-13) ·
mutation fires (−113.20 → −116.07) · out-of-range **errors by name on both cores** ·
**19/19 in `tests/testthat/test-q-attachment.R`.**

## 4. ⛔ TWO ERRORS OF MINE — READ BEFORE QUOTING P3 OR P4

1. **P3 as pre-registered COULD NOT PASS — I put the control inside the test.** It required *every*
   scored layer to age, but **3172 m IS the iso-deep control**, pinned in every arm. Scored on the
   FREE layers it passes (−4.1, −8.5, both toward GLODAP).
   ⭐⭐ **The same fact is a POWER statement worth more than the fix:** that layer contributes an
   **identical |z| to every arm**, so **one third of the scored statistic cannot discriminate.**
   `mean|z|` was **left on the full band anyway** — narrowing it would break comparability with
   2.55 / 2.048 / 1.81. **Measure the dead weight and report it; never silently redefine a score.**
2. **P4 WAS MEASURED ACROSS A `kz` CHANGE.** I read HD off the two iso-deep arms (−98.7 vs −109.2)
   and charged the 10.5 ‰ to the attachment. **The control solves a DIFFERENT `kz` per arm.**
   Deconfounded at fixed `kz`: **attachment +2.92 ‰, `kz` +8.90 ‰ — HD is set by `kz`, 3.1×** — and
   the predicted *direction* is wrong too. **The test caught it, not me:** the assertion FAILED at
   `ccx_default_params()` (−94.57 vs −94.14) because the effect is ~1–3 ‰ with **no robust sign**.
   ⇒ ⭐⭐ **AN ISO-DEEP CONTROL LICENSES EXACTLY ONE COMPARISON — the intermediate PROFILE, which is
   what it equalises the deep age FOR. Read every quantity it does not pin at MATCHED `kz`.**

## 5. ⚠⚠ NON-OBVIOUS STATE — THE SUITE IS NOT GREEN AND THAT IS NOT NEW

✅ **RESOLVED 2026-09-06, `ac67b65`.** `test-overlay-idiom-lint.R` had failed since **`d6587be`** —
the LAST COMMIT OF THE 09-05 SESSION, whose handoff reported "1842 pass / 0 fail / green
throughout". Two assertions: novel site `diag_surface_d14c_power.R`, and the ratchet **62 > 61**.
Fixed the ruling's own way — **CONVERT ON TOUCH** to `ccx_overlay_par()` — **not** by adding a
baseline entry, which would have defeated the ratchet the lint exists to be.
⚠ The lint's header warns each conversion needs a look, because converting a site that had been
running at the default lag MOVES its numbers. **Checked, not assumed:** `pv` there is built from
`CCX_PARAM_NAMES`, so it carries all 26 by construction, the deletion the helper guards against
cannot occur, and the run is **BYTE-IDENTICAL** before and after — mode −48.35, sd 0.93.
**The 09-05d collect's numbers stand.** Count back to **61 = `OI_BASELINE_N`**, no decrement owed.
⇒ **A handoff's "suite green" claim is only as good as the run that produced it, and the LAST
COMMIT of a session is exactly where it goes stale.** ⭐ No mutation test was needed here: the lint
caught the real novel site on its own, which is the same demonstration.

* **Torch: nothing running.** All local; the diagnostic is ~2 min, the suite ~12.
* ⚠ **`hs_frac = 0` IS THE SHIPPED CONFIGURATION AND MUST STAY THAT WAY** until a decision.
* ✅ **`INDEX_ccx_ocean.md` was SPLIT 2026-09-06** (it had 288 B of hard-ceiling headroom, where
  trimming meant deleting live findings). The split line is chosen so future routing is decidable:
  **`INDEX_ccx_ocean.md` = what the ocean IS** (pump, `h_ml`, `kz`, `tau_ex`, carbonate/Revelle,
  gradients, GLODAP, the gates on those); new **`INDEX_ccx_ocean_struct.md` = what SHAPE it should
  BE** (candidate geometries, the HILDA HS/HD boxes, `q`'s attachment, the circulation limbs, the
  ocean's ENSO response). ⚠ **`kz` splits both ways and both files say so** — its value, bracket and
  pricing stay with the properties; what a STRUCTURE does to it goes with the structures.
  **18,144 → 9,248 + 11,400**, both well under soft. Verified by an orphan/dangling sweep that
  nothing was lost: **540 memories, 0 orphans, 0 dangling**. Routing updated in `MEMORY.md` and the
  project `CLAUDE.md` (FaIRtoFrEDI `15f0498`).
  ⚠ **Still over SOFT, none over hard: 7 of 17** — `INDEX_cmp_pulse` 17,736 (taken there 09-05 by
  consolidating its archive pointers), `INDEX_slr` 17,253, `INDEX_cmp` 17,220, `INDEX_ccx` 16,536,
  `INDEX_diag` 16,341, `INDEX_ccx_seas` 15,627, `INDEX_ais` 14,983. **`INDEX_cmp_pulse` is the next
  one that will need this treatment**, and the ocean split is the worked precedent for how.
* **Memory:** `ccx_q_attach_bottom`, `iso_deep_control_licenses_one_comparison`,
  `retraction_in_place_does_not_propagate` (from the cleanup, §6).
* **Still owed from before, untouched:** the SOM-FFN tie for `SO_DPCO2_PEAK_MO`; `sst_seas_amp_NH`
  at −3.91σ; a posterior; CITATION + DOI; the carbonate formulation if HS ever goes transient.

## 6. THE MEMORY CLEANUP THAT OPENED THE SESSION

- ⛔ **`INDEX_ccx_seas.md` quoted GATE Q at "1.0σ" — a value its own source file RETRACTS** ("reproduces
  at NO arm"; **defaults 1.37**, and **1.27 at `ent26`**). And that source, `alpha_as_t_dependent_shipped.md`,
  was an **ORPHAN** — linked from no index, so nothing pointed at the retraction from anywhere.
  The root also routed the alphas to `INDEX_ccx.md`, which does not hold them. **All three fixed.**
  ⇒ New memory `retraction_in_place_does_not_propagate`: **an in-place retraction does not reach the
  indexes that quote the number, and an unlinked memory cannot correct a linked one. Grep the tree
  for the retracted value and fix every quoting site in the same edit.**
- ✅ Tree otherwise sound: **537 memories, 0 orphans, 0 dangling links, 0 name/filename mismatches**,
  root **11,639 B against a 12,288 soft target — compliant** ([[memory_budget_is_content_not_file]]:
  strip the comment blocks before counting; `wc -c` is the wrong check for the root).
- **`DESIGN.md` §6 (`5309195`)**: nine "STATUS AT THE CANONICAL MODE" blocks were measured at
  **`from90`, which now ERRORS by name**, and four tables called it "(canonical)". Header added
  carrying the **`ent26` ledger: 4 PASS (7 −0.32, Q 1.27, G −0.06, S +1.00), 2 FAIL (gate 4 AF
  spread 0.48 ratio; gate 5 NH peak year z +2.17)**. No table deleted — they cannot be re-derived,
  the mode errors. Rewriting §6's criteria *at* `ent26` is still owed.

## 7. ⇒ WHAT'S NEXT — RANKED

1. ⭐⭐ **Prereg the matched-`kz` decomposition** (§2). It carries the whole attribution and it is post hoc.
2. ⭐ **The attachment BOUNDARY.** Only layers **1 and 10** were run; the prereg refused a tunable
   boundary. A declared scan is a separate question — ⛔ **and it must not be scored by picking its best.**
3. **A refit**, if the attachment is ever adopted: `ent26`'s 26 parameters were fitted at
   `hs_frac = 0`, and `kz` = 2686 is an iso-deep **solve**, not a fit.
4. **`INDEX_cmp_pulse.md` at 17,736 B** — the next index that will need the ocean split's treatment.
~~The lint~~ and ~~`INDEX_ccx_ocean`~~ are **DONE** (§5).
