# Handoff — 2026-09-25 (c). **All four static findings from (b) §1(b) are FIXED, and THREE of the four were worse than the review recorded.** The NaN question (§1c) is ANSWERED. Both `Rplots.pdf` untracked; the three stale app instances are KILLED. ⚠ **The ONE thing still owed is the same one (b) owed: Marcus's copy for the placeholder sentence.**

> ⚠ **IF YOU ARE A FRESH SESSION: paths here are relative to
> `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, which is NOT your cwd.** Sessions launch
> from `FaIRtoFrEDI/` (the memory keyspace follows the launch cwd). Use absolute paths.
> ⚠ **A bare `cd` into CCX in a Bash call MOVES the session's primary working directory** — it
> happened again this session, on a `cd … && git -C …` where the `cd` was redundant. Use
> `git -C <abspath>` and `(cd <abspath> && …)` subshells, and do not prefix them with a bare `cd`.
>
> **Read first:** CHANGELOG **09-25 (i)** · then **§1** (what is owed) and **§4** (non-obvious state).
> ⚠ `~/.claude/CLAUDE.md` applies. Read **`INDEX_ccx_app.md`** before touching the app. Three new
> memories: `measure_the_note_dont_reread_it`, `text_gate_matches_its_own_comment`,
> `known_unchecked_slot_is_a_pending_finding`.

---

## 1. What is owed

### (a) ⚠ UNCHANGED FROM (b): one PLACEHOLDER sentence is live in the shipped app
The *Build your own* takeaway's non-`to_zero` branches read:

> "Fossil emissions never reach zero on this pathway — holding them at today's level keeps them
> there, and a fixed rate only ever approaches zero — so carbon keeps being added to what is already
> up there, and that does not come back down quickly either."

**That is mine, not Marcus's.** Correct (`e0 * (1 + rate/100)^n` over a −5…+5 %/yr slider is
strictly positive across the range, so neither branch can reach zero) but the pedagogy is his.
`app/server.R`, the `"Build your own"` branch; the conditional structure survives any rewording.
**This was item 1 of (b)'s recommended order and it is still item 1.**

### (b) Two small things this session surfaced and did NOT act on
1. **`calibration/diag_app_params.R:52` carries a THIRD copy of the year span** — `AP_YEARS <-
   c(1750, 2024)`, with the comment `# = APP_HIST_YEARS in app/global.R`. The app's four copies are
   now derived; this one is not, and it is outside `app/` so the new lint does not see it. It
   self-documents, which is why it was left — but it is the same fact typed a third time.
2. **`INDEX_ccx_app.md` is 179 B over its 14,336 B soft budget** (14,515; hard is 18,432). "Merge
   when convenient", not a restructure.

### (c) Still unchecked, and now recorded as a PENDING finding, not a clean one
**Axis labels and legend titles have never been measured** against their panels. The 09-25 audit
said so; this session collected the `annotate("text")` half of that sentence and found BOTH diagram
footnotes clipping. ⇒ `known_unchecked_slot_is_a_pending_finding`.

---

## 2. What shipped (7 commits, all on CCX `main`; ⚠ NOT PUSHED — see §4)

| commit | what |
|---|---|
| `78f7a19` | untrack both `Rplots.pdf` (repo root + `tests/testthat/`) |
| `06afc6e` | #3 one font size, derived; new gate test 0 |
| `e38bfc7` | #1 four slider bounds derived; new `test-ui-year-bounds-lint.R` |
| `8c1d29d` | #2 the +0.32 decomposition COMPUTED, and two errors in its description corrected |
| `59d8653` | #4 both diagram footnotes wrapped by MEASUREMENT |
| `084373c` | name 3a's weak assertion and add one with power |
| `62f0ee0` | CHANGELOG (i) |

### ⭐⭐ THE PATTERN: every finding grew when it was MEASURED rather than re-read
Three of the four were mis-stated **in a direction that would have misled the fix**:

- **#3 `CCX_BASE_SIZE`.** The review said moving the constant alone desynchronizes the budgets.
  **It moves nothing** — `theme_ccx()` is a complete theme, its explicit element sizes win, and
  `CAPTION_PT`/`SUBTITLE_PT` already tracked the signature (13 and 20 on that term both give 10/12).
  The live exposure is the **other** direction: move the SIGNATURE and `test-plot-text-fits.R`
  tests 3/3b keep measuring axis labels at the stale constant.
- **#2 "about 0.3 GtC".** Not a one-number drift. The prose named **3 of 5** terms, and as three it
  does **not** close: per-year residual **sd 0.86**, range −1.8…+2.6, mean near zero only by
  averaging (−0.004 over 1959–2024, **−0.044** one year earlier). ⛔ And the roxygen's *"closes to
  3e-14"* is the **GCB BUDGET IDENTITY's** closure — a different equation. This one closes at
  **−0.006**, the `num` column of 09-24 (i)'s table. **Twelve orders of magnitude, borrowed from the
  neighboring paragraph.**
- **#4 the footnote's literal `\n`.** The flagged sibling was real — and the one that "had been
  fixed" had **never fitted**. At the 424 px diagram panel (budget **383.5 px**): footnote 1
  **480.0 px**, footnote 2 **404.4 px**. Now 364.8 / 367.2.

⭐ (b)'s own navbar note had the same shape — *"wraps to a second row at 800 px"* understated an
eight-row stack at 991 px by **4×**. ⇒ **A flagged-but-unmeasured note is a LEAD, not a finding.**

---

## 3. ⛔⛔ THE TWO GATE LESSONS

### (a) A TEXT GATE MATCHED ITS OWN COMMENT — twice in one session
The `ui.R` year lint forbids a literal year in a `min =`/`max =`; it matched the **comment in
`ui.R` describing the old code**. The `server.R` gate forbids `"about 0.3 GtC"`; it matched the
**comment documenting the retired literal**. A file's own description of a defect contains the
defect's text, so a raw-line gate reports **every repair as a relapse**.
⚠ The tempting response — narrow the pattern until it goes quiet — narrows it past the case it
exists to catch. Both strippers are **quote-aware** (a `#` inside a string is content; `ui.R`
carries hex colors). ⇒ `text_gate_matches_its_own_comment`

### (b) A GATE THAT PASSED FOR THE WRONG REASON
3a's pixel assertion **cannot fail**: it wraps with `app_wrap_px()` and measures the result against
`app_wrap_px()`'s own budget. Tripling `DIAGRAM_NOTE_SIZE_BOLD` to 4.6 does **not** fail it — the
wrapper just returns more lines. ⭐ **Kept with its weakness STATED rather than deleted** (it still
catches a broken wrapper or a word wider than the panel), and paired with two that bite: the panel
class is load-bearing (at the FULL budget the same text overflows the diagram panel), and both call
sites are asserted to pass `app_text_px("diagram")` — the mutation that switches one to `"full"`
fails. Same family as `gate_reads_its_own_output`.

### ⚠ AND ONE PROCESS SLIP WORTH NOT REPEATING
Mutation-testing #3 with `git checkout -- app/R/plots.R` **reverted my own uncommitted fix**.
⇒ **Commit the fix BEFORE mutation-testing it.** Everything after #3 was done that way.

---

## 4. §1(c) ANSWERED — and the test (b) proposed had NO POWER

(b) asked whether `test-seas-lag-split.R`'s "NaNs produced" warnings predate that session, and said
to run the file at `0cbc1ac`. **That run was guaranteed to return "identical"**: the whole load path
(`R/`, `setup.R`, the test file, `lib_run_inputs.R`) is byte-identical at `0cbc1ac` and HEAD, tree
hash `a34b77aa` both. The commit that mattered was **`ee0958c`**, four earlier.

| | `9973232` (= `ee0958c^`) | HEAD |
|---|---|---|
| NaN warnings | **6** — 251 (×3), 256 (×5) | **10** — 251 (×5), 263 (×4), 280 (×1) |
| result | **ERROR** at :256 | PASS |

⇒ **Line 251's warnings predate `ee0958c`, so they predate every commit in handoff (b).** But they
are not unchanged — `ee0958c` added 263/280 the same day, swapping hand-seeding of ONE name for
`ccx_seed_unencodable()`, which exercises **ten** out-of-domain coordinates.
⚠ **6→10 is NOT like-for-like** — the parent errored inside the first arm, so `pin90` never ran.
Direction safe, arithmetic not.
⭐ **They are the test's own subject**: every site calls `ccx_par_to_unc()` on a vector the test
asserts must REFUSE to encode, and `log`/`logit` of an out-of-domain value returns NaN with a base-R
warning. Line 272 already wraps the one *diagnostic* call in `suppressWarnings`. **Not a defect; do
not "fix" them.**
⭐ **`ccx_require_run_inputs()` earned its keep** — the first worktree run reported "0 warnings",
which was the setup gate refusing to start over a missing `data-raw/downloads/nuclear14c`, not an
answer. A silent gate would have yielded "0 vs 10: today introduced them", which is false.

---

## 5. Non-obvious state

- ⛔ **NOTHING IS PUSHED.** CCX `main` is at **`62f0ee0`**, 7 commits ahead of `origin/main`, tree
  clean. Every previous session pushed; this one did not, because Marcus has not seen the four
  fixes. **Push is his call.**
- **ONE app instance: `:7793`, PID from the last launch, on the fixed code.** The three stale ones
  (1755/`:7791` serving pre-fix code, 61815/`:7788`, 96373/`:7789`) were **killed on his ruling**.
  ⚠ Cold start measured **~115 s to HTTP 200** at load 2.5 — consistent with (b)'s ~120 s, and still
  **not** the idle re-time that is a deploy blocker.
- **Verified in the running app, not asserted**: zero `.shiny-output-error`; all 8 plots on the
  touched tabs carry a real `<img>` with non-zero dimensions; sliders render **1750–2024** unchanged;
  the info box prints its five computed terms (closure **0.007**, "about 2 %"); both diagram
  footnotes render complete and unclipped.
  ⚠ The app's closure prints **0.007** where the offline probe and 09-24 (i) give **−0.006** — the
  app's historical run is built through `APP_SPIN`/`APP_HIST`, not the gate's path. Both are ~2 % and
  inside the gate's |.| < 0.02. **Not chased.**
- **App-facing suite: 714 PASS / 0 FAIL / 0 ERR** across 17 files (the 10 warnings are §4's NaNs).
  ⚠ A FULL run takes **~12 min** and was **not** re-run; the known standing red is
  `test-mode-file.R:323`, dAIC +4.18, **NAMED RED BY RULING**.
- **No refit triggered** — no objective change, no mode file written. `emissions-interp-constant`
  (`35f38dc`) still rides with the next one.
- **The `$` partial-match exposure is UNCHANGED**: eleven reads remain in `calibration/`, four
  inside gates (`diag_price_the_lag.R:205`, `diag_price_the_land_axis_on_support.R:91`,
  `diag_kz_bracket_on_the_sourced_target.R:227`, `diag_gamma_enso_profile.R:123`). All read a legacy
  21-parameter ancestor carrying the scalar exactly, so none is live. Convert-on-touch.
- **Unchanged deploy blockers, all Marcus's**: the two `SET-BEFORE-DEPLOY` URLs (⚠ update
  `test-review-cards.R`, don't delete it), the idle start-up re-time, the hosting plan's limits.

---

## 6. Recommended order for the next session
1. **Get Marcus's copy for §1(a)**, and **ask whether to push** the 7 commits. Both are one question.
2. **§1(b)1** — the third copy of the year span in `diag_app_params.R`. Small, and it is the only
   remaining typed copy of a fact the app now derives.
3. **§1(c)** — measure axis labels and legend titles against their panels. The last unchecked text
   slots, and the two collected this session were both clipping.
4. **Then, still open and unstarted since (b) §4 / (a) §4:** whether the constraint map wants a
   **SECOND evaluation point** (e.g. at the quarantined `hilda31pe` control, ~50 s), to say whether
   the pins/pulls picture is a property of the MODEL or of THIS fit. **A real choice, not a chore.**
