# Handoff — 2026-09-27 (c). **YOU ARE THE TEST. The memory-symlink check runs against THIS session, and the old version of it had no power. Everything else is discharged.**

> ⛔ **§0 IS WITHDRAWN (Marcus, 2026-09-27): the symlink test is dropped.** Launch from `FaIRtoFrEDI/` and
> move with `change_directory`; see CHANGELOG 2026-09-27 (d). §1–§5 remain current.

> ⚠ **YOUR CWD IS `CarbonCycleEmulator/`** — this session was launched here deliberately, which is
> the reverse of every earlier handoff's warning. Paths below are relative to this repo.
> The FaIRtoFrEDI repo is at `~/Documents/2026/CodeProjects/FaIRtoFrEDI/`; use absolute paths for it.
> ⛔ **`cd X && ...` in a Bash call MOVES the session's primary working directory** — only a
> subshell `( cd X && ... )` or `git -C` is safe. Recover with `change_directory`; it lands at the
> END of the turn. (The 09-27 c session tripped this on its FIRST call, having just read the
> warning. Treat it as a live trap, not a historical note.)
>
> **Read first:** **§0**, and do not read past it until Marcus has asked the two questions.
> Then CHANGELOG **2026-09-27 (b)** and **(a)**. Supersedes `handoff_2026-09-27b_arm_required.md`
> for STATE; that file's gate-12 and near-tie **measurements** are unchanged and still current.

---

## 0. ⛔⛔ THE TEST — IT RUNS BEFORE YOU DO ANYTHING ELSE

This session exists to answer one question: **does the harness load memory through the
`CarbonCycleEmulator` symlink?** The memory keyspace follows the LAUNCH cwd. Until 09-27 every
session was launched from `FaIRtoFrEDI/` because a session started elsewhere gets that repo's
`CLAUDE.md` but an **empty** memory.

⛔ **If you are reading this before Marcus has asked you the two questions, STOP and say so.**
Reading further contaminates the test: this handoff is in the repo, and anything quoted in it is
something you could recite without memory. That is precisely how the previous version of this test
came to have no power.

**Marcus holds the answer key**, deliberately stored OUTSIDE this repo at
`~/Documents/2026/CodeProjects/FaIRtoFrEDI/notes/symlink_test_answer_key_2026-09-27.md`.
⛔ **Do not open it.** It contains the expected answers; reading it destroys the measurement.

- **Q1 tests whether the root was INLINED at session start.** Answer from context only — if you
  find yourself wanting to grep or Read, the answer is "I don't have it", and that is a legitimate
  and useful result. **Do not reconstruct it from this repo.**
- **Q2 tests whether the symlinked tree is READABLE**, which is a different thing. A pass on one
  does not imply the other.

⚠ **Why the old test was replaced** — it asked what `INDEX_ccx.md` gives as the canonical mode and
accepted "answered without reading a file" as a pass. Two independent defects, both measured 09-27:
1. The canonical mode name appears in **79 files in this repo, including `DESIGN.md`**. A session
   with **zero** memory answers it correctly. The gate could not fail.
2. `INDEX_ccx.md` is **not auto-loaded at all** — only the root `MEMORY.md` is, by this repo's own
   documented tiering. So "no file read" was the wrong criterion for that file; a passing session
   would have been answering from the root and proving nothing about the sub-index tier.

⇒ **FOURTH instance this arc of a gate that could not fail** — the FaIR overlay (09-26, tested the
helper not the caller), the constraint-map tie test's hardcoded share (09-26), the joos arm gate's
first version (09-27 b), and now the symlink test itself. ⭐ **This is the first one caught BEFORE
it misled anyone**, and it was caught by asking the standing question — *could this gate have
failed?* — rather than by running it. ⇒ [[mutation_test_gates]], [[no_power_null]].

### After the test
Record the outcome per the key's grading table. **A negative result is a real result** — record it
so it is not re-attempted. Until Q1 passes, **keep launching from `FaIRtoFrEDI/`**.

---

## 1. What is owed

### The symlink test (§0) — and NOTHING else is blocked on Marcus
Both 09-26 rulings were discharged on 09-27: the near-ties (a) and the default arm (b). The memory
tree is clear. ⚠ **The one owed item is now a test whose own design was the defect** — see §0.

---

## 2. What changed in 09-27 (c)

**Only the project log. No code, no refit, no objective change, no mode file, and no number moved.**

`6ebacc9` — **CHANGELOG 2026-09-27 (b)**, which had never been written: commit `72da9ba` shipped
the arm-required change with a handoff and a git entry but **no CHANGELOG entry**. Logged now:
absence asserts, `canonical` resolves through the pointer at run time and stamps the resolution,
why defaulting to the canonical was rejected (the mode pointer moved **11 times in 25 days**), and
the no-power gate.

⚠ **(a)'s closing line is struck**, with a pointer to (b) §3. It had said that changing the default
would "re-mean every past gate-12 number". **Overstated** — `JOOS_SRC` already wrote the arm into
every log, so past runs were labeled and nothing retroactive was ever at stake. The ruling was
cheaper than it had been presented as being. Pushed to `origin/main`.

⭐ **Marcus's standing frame is intact: Joos and FaIR remain COMPARISONS, not targets to meet**
(ruled 09-04, reaffirmed 09-27).

---

## 3. Verified first-hand this session, not transcribed

- **The arm contract works.** A bare `Rscript calibration/diag_joos_irf.R` errors with the arm list
  built from `names(CCX_MODE_FILES)`. `canonical` resolves and stamps it into the output header:
  `posterior mode, arm hilda29l [asked for 'canonical', resolved 2026-09-27]`.
- **Suite: pass 4915 / fail 1 / error 0.** ⚠ The one failure is the **NAMED STANDING RED** that
  `paths.R` documents — `test-mode-file.R:323`, the canonical-beats-the-control AIC gate, dAIC
  **+4.18**, ruling 2 of 09-19. **Do not "fix" it.**
- ⭐ **An apparent numeric conflict between the two 09-27 documents is NOT one.** (a) quotes
  integrated IRF **35.1 / 41.8**; the (b) handoff quotes **45.5**. Different sections of the same
  driver: §4 is the PI/PD background protocol (PI 35.1, PD 41.8), §5 is the ssp245 pulse of 100 GtC
  in 2050 (IRF@20/50/100 = 0.571 / 0.411 / 0.307, int IRF 45.5). Both reproduce exactly on the
  `canonical` arm. ⚠ Resolved by RUNNING the driver rather than picking one — do the same with any
  future pair that looks contradictory across handoffs.
- **App restarted** on `:7793`, serving `v1.0-hilda29l`. ⚠ Two `figure margins too large` errors in
  its log are the **zero-width initial render** of the preview tab only; the Keeling panels draw
  correctly at real width. Not a regression — but re-check after any resize work.

---

## 4. Non-obvious state (carried forward, still true)

- **Gates added across this arc, all mutation-tested**: `test-joos-arm-required.R` (12),
  `test-cmap-tie.R` (23), `test-fair-overlay.R` (29), `test-stylised-takeaway.R` (49),
  `test-pulse-linearity.R` (13).
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
  (flips ≤ 0.85 pp, stable ≥ 3.02 pp), **re-derive from the endpoints rather than nudging the cut**.
- `emissions-interp-constant` (`35f38dc`) still rides with the next refit.
- **Unchanged deploy blockers, all Marcus's**: the two `SET-BEFORE-DEPLOY` URLs (⚠ update
  `test-review-cards.R`, don't delete it), the idle start-up re-time, the hosting plan's limits.
- ⚠ Untracked in this repo: `carbotopecomment.9.26.26.docx`. Left alone — Marcus's.

---

## 5. Recommended order
1. **§0, before anything else.** It is the only owed item, and its design is the point.
2. Record the outcome against the key's grading table — **including a negative one**.
3. Optional and cheap: `Rscript calibration/diag_joos_irf.R canonical` after any adoption, since the
   comparison at the shipped model is obtainable for the first time.
4. Still open and unstarted: whether the carbon-cycle gap is ever CHASED rather than reported.
   ⚠ It is the **marginal** response that is low, not the scenario level (the emulator tracks FaIR
   to ~0.05 °C on ssp245 at 2100), so the target would be the pulse decay. Marcus ruled 09-04 that
   the long lifetime *should be an emergent behaviour* and reaffirmed 09-27 that **FaIR and Joos are
   comparisons, not targets to meet** — a deliberate open question, **not a bug-queue item**. Any
   work here must not turn either model into a scoring target.
