# Handoff — CarbonCycleEmulator, 2026-09-05f (the `q` ATTACHMENT-DEPTH arc)
# **⭐ THE OUTCOME HOLDS — 2.048 → 1.739, under the reduced form's 1.81.**
# **⛔ THE MECHANISM I PRE-REGISTERED IS REFUTED: `kz` RISES, it does not relieve.**
# **⛔ TWO ERRORS OF MINE, BOTH CAUGHT BY MY OWN TESTS — §4 before quoting P3 or P4.**
# **⚠ THE SUITE IS NOT GREEN, AND IT WAS NOT GREEN WHEN I ARRIVED — §5.**

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

⛔ **`test-overlay-idiom-lint.R` FAILS 2**: novel site **`diag_surface_d14c_power.R`**, and the
ratchet **62 > 61**. **Introduced by `d6587be`, the LAST COMMIT OF THE 09-05 SESSION** — verified by
removing every file of mine and re-running, where it fails identically. **The 09-05 handoff's
"1842 pass / 0 fail / green throughout" was wrong, or the lint was never re-run after that commit.**
**I did not touch it** — the fix is to convert that file to `ccx_overlay_par(p, pm)` and decrement
`OI_BASELINE_N`, and it is one line of judgement that belongs to whoever owns that diagnostic.
⇒ **A handoff's "suite green" claim is only as good as the run that produced it, and the last
commit of a session is exactly where it goes stale.**

* **Torch: nothing running.** All local; the diagnostic is ~2 min, the suite ~12.
* ⚠ **`hs_frac = 0` IS THE SHIPPED CONFIGURATION AND MUST STAY THAT WAY** until a decision.
* ⚠ **`INDEX_ccx_ocean.md` is 18,144 B against a hard ceiling of 18,432** — **288 B of headroom.**
  It needs **restructuring, not nibbling**; I compressed the superseded conduit entry and that
  bought 34 B. `INDEX_cmp_pulse.md` was taken 18,076 → 17,736 by consolidating its archive pointers.
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
3. **The lint (§5)** — one file, one line, someone's call.
4. **A refit**, if the attachment is ever adopted: `ent26`'s 26 parameters were fitted at
   `hs_frac = 0`, and `kz` = 2686 is an iso-deep **solve**, not a fit.
5. **`INDEX_ccx_ocean.md`'s 288 B** (§5) — restructure.
