# Handoff — 2026-09-27 (b). **`diag_joos_irf.R` has no default arm any more, and `canonical` is an arm name. Both 09-26 rulings are now discharged — nothing is blocked on Marcus except the memory-symlink test.**

> ⚠ **IF YOU ARE A FRESH SESSION: paths here are relative to
> `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, which is NOT your cwd.** Sessions launch
> from `FaIRtoFrEDI/`. Use absolute paths.
> ⛔ **`cd X && ...` in a Bash call MOVES the session's primary working directory** — only a
> subshell `( cd X && ... )` or `git -C` is safe. Recover with `change_directory`; it lands at the
> END of the turn.
>
> **Read first:** CHANGELOG **2026-09-27 (a)**, then **§1** and **§4**. Supersedes
> `handoff_2026-09-27_gate12_readable_and_ties.md` for STATE; that file holds the gate-12 / near-tie
> **measurements**, which are unchanged. The pulse/FaIR/TCRE measurements are in
> `handoff_2026-09-26b_*`.

---

## 1. What is owed

### ⛔ ONE ITEM, AND IT IS NOT A RULING
**The `CarbonCycleEmulator` memory symlink has never been tested against the harness** (owed since
09-26 a). **One-line test**: start a session in `CarbonCycleEmulator/` and ask what `INDEX_ccx.md`
gives as the canonical mode; an answer without reading a file means it loaded. Until then, **keep
launching from `FaIRtoFrEDI/`** — the memory keyspace follows the launch cwd, and a session started
elsewhere gets that repo's `CLAUDE.md` but an EMPTY memory.

### Nothing else is blocked on Marcus
Both 09-26 rulings are discharged: the near-ties (09-27 a) and the default arm (below). The memory
tree is clear — tightest index `INDEX_ais.md` at 1,775 B, nothing in split territory.

---

## 2. What changed

```
Rscript calibration/diag_joos_irf.R            -> ERROR, listing the arms
Rscript calibration/diag_joos_irf.R canonical  -> the shipped model
Rscript calibration/diag_joos_irf.R defaults   -> the uncalibrated table
```

A bare run used to mean `JOOS_ARM_DEFAULT = "defaults"`, the **uncalibrated table** — pulse AF@100
**0.445** against the shipped model's **0.307** — with `JOOS_SRC` naming the truth 180 lines above
the verdict. The 08-31f fix made an *unrecognised* argument an error and left the *absent* one
silent, though its own comment already said **"absence must ASSERT"**.

⛔⛔ **WHY NOT SIMPLY DEFAULT TO THE CANONICAL** — Marcus asked, and the answer is MEASURED:
**`CCX_MODE_CANONICAL` changed ELEVEN times in the 25 days to 2026-09-20** — from90 → ent26 →
hilda31 → hilda31p → hilda31s → hilda31s2 → hilda30c → hilda30h → hilda30e → hilda30s → hilda29l,
**twice on 09-13 and twice on 09-20**. A bare command would then mean something different each month
with nothing in the invocation recording which model was measured: **trading "reports a model nobody
ships" for "reports a different model each month", which is HARDER to notice because the number
stays plausible.** It would also still be a SILENT DEFAULT — this bug class waiting for the next
structural change, exactly as the last one waited for `w_enso_l2` to replace the ENSO shim.

⭐ **`canonical` RESOLVES through the pointer at run time** — never a typed mode name, which would
freeze the alias at today's arm — and the resolution is stamped into the output:
*"arm hilda29l [asked for 'canonical', resolved 2026-09-27]"*. Runs months apart are therefore
distinguishable in their own logs. Verified: `canonical` and `hilda29l` give identical numbers
(ssp245 IRF@20/50/100 = **0.571 / 0.411 / 0.307**, integrated IRF **45.5**).

⚠ **A correction that is now in the record**: I had said changing the default would "re-mean every
past gate-12 number". **Overstated.** `JOOS_SRC` writes the arm into the log, so past runs were
labeled — badly placed, but recorded. Nothing retroactive was ever at stake.

⭐ **Marcus's standing frame is intact: no number, band or threshold changed. Joos and FaIR remain
COMPARISONS, not targets to meet.**

---

## 3. ⛔ THE GATE'S FIRST VERSION HAD NO POWER — third instance this arc

The test written for this change **passed with the silent default restored**. It took
`.src[i:(i+2)]` and asserted the window contained `stop(` — which it did, because the window ran on
into the **unknown-arm** branch and found THAT branch's `stop()`. The mutant scored **zero**
failures.

⇒ **Scope a text gate to the BRANCH, not to "the next few lines", and assert what must NOT be there
as well as what must.** Rewritten to bound the window by the next branch and to reject `return(`;
re-mutated, it now fails **2** on the silent default and **1** on freezing the alias to a mode name.

⚠ **This is the THIRD time this arc that a gate passed while the defect it existed for was present**
— the FaIR overlay (09-26, tested the helper not the caller), the constraint-map tie test's
hardcoded share (09-26), and this. **Mutation-testing found all three; nothing else would have.**
⇒ [[mutation_test_gates]], [[gate_tested_the_helper_not_the_caller]].

---

## 4. Non-obvious state

- **Suite: pass 4915 / fail 1 / error 0.** ⚠ The one failure is the **NAMED STANDING RED**
  `paths.R` documents (`test-mode-file`'s canonical-beats-the-control AIC gate, ruling 2 of 09-19).
  **Do not "fix" it.**
- **Gates added across this arc, all mutation-tested**: `test-joos-arm-required.R` (12),
  `test-cmap-tie.R` (23), `test-fair-overlay.R` (29), `test-stylised-takeaway.R` (49),
  `test-pulse-linearity.R` (13).
- ⚠ **The app on `:7793` predates today's commits** — restart before judging any copy on screen.
  Managed launch target `ccx-app` in **`FaIRtoFrEDI/.claude/launch.json`**, absolute path, cold start
  ~110 s.
- **`par_mode` is the FREE set** — a pinned name is absent from it by construction. Use
  `ccx_mode_par_with_pins()`. Any diagnostic still reading `md$par_mode` is reading the free set;
  grep before trusting one ⇒ [[free_set_is_not_the_parameter_set]].
- ⚠ `w_eq` (27 vs 0), `gamma_eq` (1 vs 0) and `pump_export` (9.08 vs 0) differ from the defaults yet
  are **inert under the shipped `hilda_csl3` structure** — deleting them moved no number. Recorded
  09-27, **not chased**. Do not assume a pin is doing work.
- ⚠ `APP_PULSE_LIN_*` and `APP_CMAP_TIE_*` in `global.R` are LABELS for measurements made in
  `calibration/diag_pulse_vs_tcre.R` and `calibration/diag_constraint_map_arms.R`. Their gates
  re-read those artifacts but **SKIP if absent**, so a fresh clone will not catch a drift until each
  driver has been run once.
- **The tie threshold rests on 3 arms × 12 rows.** If a fourth arm lands a row in the measured gap
  (flips ≤ 0.85 pp, stable ≥ 3.02 pp), **re-derive from the endpoints rather than nudging the cut** —
  the gate asserts the gap is still a gap, so that is what fails.
- **No refit, no objective change, no mode file written.** `emissions-interp-constant` (`35f38dc`)
  still rides with the next refit.
- **Unchanged deploy blockers, all Marcus's**: the two `SET-BEFORE-DEPLOY` URLs (⚠ update
  `test-review-cards.R`, don't delete it), the idle start-up re-time, the hosting plan's limits.

---

## 5. Recommended order for the next session
1. **Verify the memory symlink** (§1) — one session start, one question. It is the only owed item.
2. **Restart the app** before judging any copy on screen.
3. Optional, cheap, and now possible: re-run `diag_joos_irf.R canonical` after any adoption, since
   the comparison at the shipped model is obtainable for the first time.
4. Still open and unstarted: whether the carbon-cycle gap is ever CHASED rather than reported.
   ⚠ It is the **marginal** response that is low, not the scenario level (the emulator tracks FaIR to
   ~0.05 °C on ssp245 at 2100), so the target would be the pulse decay. Marcus ruled 09-04 that the
   long lifetime *should be an emergent behaviour* and reaffirmed 09-27 that **FaIR and Joos are
   comparisons, not targets to meet** — so this is a deliberate open question, **not a bug queue
   item**, and any work here must not turn either model into a scoring target.
