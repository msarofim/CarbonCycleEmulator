# Handoff — 2026-09-06, SESSION CLOSE. Memory cleanup → the `q` attachment arc → two debts paid.
# **✅ SUITE GREEN AND VERIFIED: 1861 pass / 0 FAIL / 4 skip / 66 warn.**
# **⛔ THE ONE FINDING TO CARRY: `q` at the BOTTOM scores 1.739, but the MECHANISM I pre-registered is REFUTED.**
# **⛔ NOTHING WAS ADOPTED. `hs_frac` ships 0; `ent26` untouched.**

**Repos, both CLEAN, no remote on either:**
- `~/Documents/2026/CodeProjects/CarbonCycleEmulator/` — trunk `main`, **7 commits**
  `5309195 · 5a95341 · 13eb0ad · 2d29eff · 7dc0c17 · ac67b65 · e7ee63c · 789b739 · e052f1a`.
- `~/Documents/2026/CodeProjects/FaIRtoFrEDI/` — **`15f0498`** (CLAUDE.md sub-index registration only).
⚠ **Sessions launch from `FaIRtoFrEDI/`; nearly all of this is in `CarbonCycleEmulator/`.** Use `git -C <abspath>`.

**Arc detail lives in `handoff_2026-09-05f_q_attachment.md`** — read it for the attachment work.
This note is the session close: what changed, what is owed, and what a fresh session must not
mis-read.

---

## 1. ⛔⛔ THE FINDING, AND THE HALF OF IT THAT IS A REFUTATION

Marcus's ruling opened it: *"We don't need to stay true to HILDA, but we should stay true to the
conceptual way that the simplified model's ocean works."* That **authorised the departure** and
**forbade the cheap version of it** — attaching `q` low *because it scores better* would be tuning
geometry to the residual. So the prereg argues from CCX's own structure and declares the attachment
set from a **non-score criterion with no free boundary**.

New **`q_attach_from`**, both cores. **1 = HILDA's depth-independent `q` = the 09-05 structure BIT
FOR BIT**; absence means 1.

| arm (iso-deep, `kz` re-solved) | `kz` | **mean \|z\|** |
|---|---|---|
| layer 1 — HILDA, depth-independent | 1900 | **2.048** |
| layer 10 — **BOTTOM ONLY** | **2686** | **1.739** |

✅ **P2 passes and beats the stretch** (the 09-04k2 reduced form's 1.81).
⛔⛔ **P1 FAILED: `kz` RISES.** I predicted the deep's own pathway would *relieve* `kz`. It cannot —
`tau_q` is per-layer, so bottom-only is **less** exchange and `kz` must do **more**.
⇒ **DO NOT CARRY 09-04k2's "the conduit relieves `kz`" FRAMING ONTO THIS ARM.** Both arms still
relieve against the incumbent; P1 was written against the depth-independent arm.
⭐ The gain **is** the attachment, by a **POST HOC** matched-`kz` decomposition. ⛔ Its two
off-control numbers (0.377, 3.092) **decompose only — never quote them as scores.**
⭐ **HILDA's own central `tau_q` = 538 is the best arm. Nothing was tuned to land there.**
⛔ It does **not** reach DESIGN §3.4a's **|z| < 1**, and it is **NOT "HILDA's model."**

## 2. ⛔ TWO ERRORS OF MINE, BOTH CAUGHT BY MY OWN TESTS — the transferable half

1. **I put the control INSIDE its own test.** P3 required *every* scored layer to age, but **3172 m
   IS the iso-deep control**, pinned in every arm. ⭐⭐ The same fact is a **POWER** statement worth
   more than the fix: that layer contributes an **identical |z| to every arm**, so **a third of the
   scored statistic cannot discriminate.** `mean|z|` was left on the full band regardless —
   narrowing it would break comparability with 2.55 / 2.048 / 1.81. **Measure the dead weight and
   report it; never silently redefine a score.**
2. **I measured P4 across a `kz` change.** Read HD off the two iso-deep arms and charged the 10.5 ‰
   to attachment. Deconfounded: **attachment +2.92 ‰, `kz` +8.90 ‰ — HD is set by `kz`, 3.1×** — and
   the predicted *direction* was wrong too. **The test caught it, not me**: it failed at
   `ccx_default_params()` because the effect is ~1–3 ‰ with **no robust sign**.
⇒ ⭐⭐ **AN ISO-DEEP CONTROL LICENSES EXACTLY ONE COMPARISON — the intermediate PROFILE, which is
what it equalises the deep age FOR. Read every quantity it does not pin at MATCHED `kz`.**
⇒ [[iso_deep_control_licenses_one_comparison]].

## 3. ✅ THE TWO DEBTS PAID ON 09-06

**(a) `test-overlay-idiom-lint` (`ac67b65`) — the suite had been red since `d6587be`.**
That is the **LAST COMMIT of the 09-05 session**, whose handoff reported *"1842 pass / 0 fail /
green throughout"*. Fixed the ruling's own way — **CONVERT ON TOUCH** to `ccx_overlay_par()` — not
by a baseline entry, which would have defeated the ratchet the lint exists to be.
⚠ The header warns conversions move printed numbers. **Checked, not assumed:** `pv` there is built
from `CCX_PARAM_NAMES`, carries all 26 by construction, and the run is **BYTE-IDENTICAL** before and
after — mode −48.35, sd 0.93. **The 09-05d collect's numbers stand.** Count back to
**61 = `OI_BASELINE_N`**, no decrement owed.
⭐⭐ **THE ARITHMETIC THAT PINS THE ERROR: 1861 − 19** (this arc's new `test-q-attachment.R`)
**= 1842**, exactly what that handoff reported. **Its pass-count was RIGHT and its "0 fail" was NOT.**
⇒ **A "suite green" claim is only as good as the run behind it, and the LAST COMMIT of a session is
precisely where it goes stale. Re-run after the final commit, not before it.**

**(b) `INDEX_ccx_ocean.md` — SPLIT, not trimmed.** It had **288 B** of hard-ceiling headroom and
lossless compression bought **34 B**, because the file was dense with live findings; trimming
further would have deleted content to satisfy a budget.
**`INDEX_ccx_ocean.md` = what the ocean IS** (pump, `h_ml`, `kz`, `tau_ex`, carbonate/Revelle,
gradients, GLODAP) · new **`INDEX_ccx_ocean_struct.md` = what SHAPE it should BE** (candidate
geometries, the HILDA boxes, `q`'s attachment, circulation limbs, the ocean's ENSO response).
**18,144 B → 9,248 + 11,400.** ⚠ **`kz` straddles it and BOTH files say so** — value/bracket/pricing
with the properties, what a STRUCTURE does to it with the structures. **Naming the straddling case
is what stops the two re-merging by drift.** ⇒ [[memory_index_split_beats_trim]].

## 4. ✅ ALSO CLOSED — the FaIRtoFrEDI-side and housekeeping items

- **`DESIGN.md` §6 (`5309195`)** — nine *"STATUS AT THE CANONICAL MODE"* blocks were measured at
  **`from90`, which `ccx_mode_file()` now ERRORS on by name**, and four tables still called it
  "(canonical)". Header added carrying the measured **`ent26` ledger: 4 PASS** (gate 7 ocean z
  **−0.32**, Q **1.27**, G **−0.06**, S **+1.00**) **/ 2 FAIL** (gate 4, AF decadal *spread* ratio
  **0.48** vs 0.76 at defaults in the same run; gate 5, NH bomb peak **YEAR** z **+2.17**).
  ⚠ **No table deleted — they cannot be re-derived, the mode errors.** ⛔ **STILL OWED: rewriting
  §6's criteria AT `ent26`.** This is a stopgap against misreading, not that rewrite.
- **LICENSE = MIT (`13eb0ad`)**, Marcus's call. No `DESCRIPTION` exists; if one is ever written its
  field must read `MIT + file LICENSE`.

## 5. THE MEMORY CLEANUP THAT OPENED THE SESSION

- ⛔ **`INDEX_ccx_seas.md` quoted GATE Q at "1.0σ" — a value its own source file RETRACTS** ("reproduces
  at NO arm"; **defaults 1.37**, **1.27 at `ent26`**). That source, `alpha_as_t_dependent_shipped.md`,
  was an **ORPHAN** — linked from no index, so nothing pointed at the retraction from anywhere. The
  root also routed the alphas to `INDEX_ccx.md`, which does not hold them. **All three fixed.**
  ⇒ [[retraction_in_place_does_not_propagate]]: **an in-place retraction does not reach the indexes
  that quote the number, and an unlinked memory cannot correct a linked one. Grep the tree for the
  retracted VALUE and fix every quoting site in the same edit.**
- **Tree now: 541 memories, 17 indexes, 0 orphans, 0 dangling links, 0 name/filename mismatches.**

## 6. ⚠ NON-OBVIOUS STATE

* **Torch: nothing running.** All local. `diag_q_attachment.R` ~2 min; full suite ~12 min.
* ⚠⚠ **`hs_frac = 0` IS THE SHIPPED CONFIGURATION AND MUST STAY THAT WAY** until a decision. Every
  `ent26` number and every stored logpost is a **32-box** number.
* ⚠ **`q_attach_from` > 1 is a DEPARTURE FROM HILDA.** Any result on such an arm carries that label.
* ⚠ **Memory budgets: 7 of 17 indexes over SOFT, none over hard.** `INDEX_cmp_pulse` **17,736** is
  **the next one that will need the ocean split's treatment** — and that split is the worked
  precedent. `INDEX_slr` 17,253 · `INDEX_cmp` 17,220 · `INDEX_ccx` 16,536 · `INDEX_diag` 16,341 ·
  `INDEX_ccx_seas` 15,627 · `INDEX_ais` 14,983.
* ⚠⚠ **`MEMORY.md` is at 12,286 / 12,288 — TWO BYTES.** Compliant, and hard is 18,432 so nothing is
  at risk, but **it cannot take another pointer without a trim**; I tightened two lines to fit
  today's. ⚠ Measure it with the comment blocks STRIPPED — `wc -c` is the wrong check for the root
  and has produced a false "over budget" three handoffs running
  ([[memory_budget_is_content_not_file]]).
* **New memories this session:** `ccx_q_attach_bottom`, `iso_deep_control_licenses_one_comparison`,
  `retraction_in_place_does_not_propagate`, `memory_index_split_beats_trim`.
* **Untouched, owed from before:** the SOM-FFN recomputation tie for `SO_DPCO2_PEAK_MO`;
  `sst_seas_amp_NH` at −3.91σ; a posterior; CITATION + DOI; the carbonate formulation (only if the
  HS boxes ever go transient or below 2 °C — Lueker's validity floor).

## 7. ⇒ NEXT, RANKED

1. ⭐⭐ **Pre-register the matched-`kz` decomposition.** It carries the entire attribution in §1 and
   it is **post hoc**. Nothing should be built on it until it has its own prereg.
2. ⭐ **The attachment BOUNDARY.** Only layers **1 and 10** were run — the prereg refused a tunable
   boundary. A declared scan is a separate question, ⛔ **and it must not be scored by picking its best.**
3. **`DESIGN.md` §6 rewritten at `ent26`** (§4). The stopgap is not the rewrite.
4. **A refit**, if the attachment is ever adopted: `ent26`'s 26 parameters were fitted at
   `hs_frac = 0`, and `kz` = 2686 is an iso-deep **SOLVE**, not a fit.
5. **`INDEX_cmp_pulse.md`** (§6) — the next split.

## 8. ⇒ STANDING RULES THIS SESSION ADDED

* ⭐⭐ **A CONTROL LICENSES ONLY THE COMPARISON IT WAS BUILT FOR.** It equalises ONE quantity; read
  everything it does not pin at MATCHED values of whatever it moved. ⚠ **The confound is CREATED BY
  the control, which is why it does not look like one.** And **the quantity a control pins has NO
  POWER** — measure how much of your statistic is dead weight, and report it rather than quietly
  redefining the statistic.
* ⭐⭐ **A RETRACTION MADE IN PLACE DOES NOT PROPAGATE.** Grep the tree for the retracted VALUE and
  fix every quoting site in the same edit. **An unlinked memory cannot correct a linked one**, so
  orphan-checking and retraction-propagation are one pass.
* ⭐ **NEAR A HARD CEILING, SPLIT — DON'T TRIM.** State the split line in **both** files, **name the
  case that straddles it**, and prove nothing was lost with an orphan sweep rather than by trusting
  that you moved every block.
* ⭐ **RE-RUN THE SUITE AFTER THE LAST COMMIT, NOT BEFORE IT** — that is exactly where a "green"
  claim goes stale, and it cost two failures carried silently across a session boundary.
