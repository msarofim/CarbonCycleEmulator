# Handoff — 2026-09-25 (b). **FULL APP REVIEW, and all three defects Marcus ruled in are FIXED.** ⛔⛔ **THE OPEN RULING FROM HANDOFF (a) IS CLOSED: Marcus ratified the CONDITIONAL step.** ⚠ One sentence now in the shipped app is a PLACEHOLDER awaiting his copy, and a STALE app instance is still serving pre-fix code on :7791.

> ⚠ **IF YOU ARE A FRESH SESSION: paths here are relative to
> `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, which is NOT your cwd.** Sessions launch
> from `FaIRtoFrEDI/` (the memory keyspace follows the launch cwd), so a bare `app/...` will not
> resolve. Use the absolute path. ⚠ A bare `cd` into CCX in a Bash call **moves the session's
> primary working directory** — use `git -C <abspath>` and `(cd <abspath> && …)` subshells.
>
> **Read first, in this order:** CHANGELOG **09-25 (g)** and **(h)** · then **§1** (what is owed)
> and **§5** (non-obvious state, including the stale instance).
> ⚠ `~/.claude/CLAUDE.md` applies. ⚠ `MEMORY.md` is the auto-loaded ROOT ONLY. Read
> **`INDEX_ccx_app.md`** before touching the app. The two new facts are in
> **`ccx_app_review_20260925.md`** and **`gate_named_a_constant_that_did_not_exist.md`**.

---

## 1. What is owed, in priority order

### (a) ⚠ One PLACEHOLDER sentence is live in the shipped app — copy is Marcus's
The *Build your own* readout used to print *"how little the temperature falls even when emissions
stop"* on **all three** `s_kind` branches, and emissions stop in **one**. It is now conditional. The
`to_zero` branch keeps **Marcus's wording verbatim**; the other branch now reads:

> "Fossil emissions never reach zero on this pathway — holding them at today's level keeps them
> there, and a fixed rate only ever approaches zero — so carbon keeps being added to what is already
> up there, and that does not come back down quickly either."

**That is mine, not his.** It is *correct* — the rate law is `e0 * (1 + rate/100)^n` over a
**−5 … +5 %/yr** slider, strictly positive across the whole range, so neither remaining branch can
reach zero — but the pedagogy is his. **Ask him to rewrite it.** `app/server.R`, in the
`"Build your own"` branch of the takeaway; the conditional structure should survive any rewording.

### (b) Four static findings NOT fixed, each re-verified by grep — Marcus's call
Not touched because none was in scope of what he ruled in, and three of them are judgment calls:

1. **Four "Years shown" sliders hardcode `min = 1750, max = 2024`** (`app/ui.R:136, 176, 264, 328`)
   against `APP_HIST_YEARS <- c(1750, 2024)` (`global.R:51`), whose own comment says *"changing a
   window cannot leave a stale label behind"*. A GCB update to 2025 silently caps four tabs.
2. **`app/server.R:212` types "about 0.3 GtC"** in prose where `plots.R:600` measures **+0.32**
   (= +0.54 − 0.30 + 0.09) — on the panel whose header insists *"THE CONTAINMENT IS COMPUTED, NOT
   DESCRIBED"* and whose sibling takeaway does compute its numbers.
3. **`theme_ccx(base_size = 13)` and `CCX_BASE_SIZE <- 13` are two copies of one number**
   (`plots.R:76, 154`), and in `theme_minimal(base_size = CCX_BASE_SIZE) + theme_ccx()` **`theme_ccx()`'s
   own default WINS** — so moving `CCX_BASE_SIZE` alone leaves every pixel budget measured at the old
   font size while the charts render at the new one. ⭐ This is the defect the surrounding comment
   claims to have eliminated.
4. **The box diagram's SECOND footnote still carries a literal `\n`** (`plots.R:1400`) — three lines
   below the comment documenting that exact incident on the *first* footnote. The fix was applied to
   one and not its sibling.

Also: **`tests/testthat/Rplots.pdf` is TRACKED and not in `.gitignore`**, so it churns on every test
run that opens a device (it showed up as `M` twice during this session).

### (c) ⚠ A warning I did NOT diagnose
`test-seas-lag-split.R` emits **"NaNs produced"** warnings. The file **passes**, and nothing this
session touched is in that path — **but I did not establish whether they predate today.** Do not
repeat "pre-existing" without checking; run that file at `0cbc1ac` and compare.

---

## 2. What shipped (three commits, all PUSHED to `msarofim/CarbonCycleEmulator` `main`)

| commit | what |
|---|---|
| `af0c856` | the `$`→`[[` conversion at `lib_seas_limbs.R:117`, + the corrected count of what is left |
| `9887eb9` | the text-fit gate pointed at a constant that exists, + CHANGELOG (g), the review record |
| `100b353` | the three ruled defects fixed + CHANGELOG (h), the ratified step |

### ⭐⭐ RULING (Marcus, 2026-09-25): the map's step is the CONDITIONAL Hessian sd
He **ratified the substitution**. The marginal step stays **reported** — marginal ÷ conditional
(median **3.3**, max **92** for `beta_max`/`fert_k`) is the identifiability statement the tab rests
on — but it is **not the step**. `CM_STEP_KIND` unchanged, **no rebuild**, objective **#13 still
FROZEN**. Handoff (a) §1 is **CLOSED**; do not re-open it.

### The three fixes, each verified in a RUNNING app
- **Navbar.** ⭐ **The cause was a MISSING CLASS, not a width.** `navbarPage()` emits the Bootstrap
  **3** classes `navbar navbar-default navbar-static-top` with **no `navbar-expand-*`**, so bslib's
  BS5 shim applies `flex-direction: row` only inside `@media (min-width: 992px)`; below it BS5's own
  `column` default wins, and there is **no `.navbar-collapse` and no toggler** to absorb it. One rule
  in `ui.R`'s existing style block, **a no-op above 992 px so it cannot drift with the breakpoint**.
  Measured before → after: **960 / 800 / 768 px: 8 rows (448 px) → 2 rows (100 px)**; ~697 px: 8 → 4
  rows (216 px), no horizontal scroll; 1440 px unchanged at 1 row.
  ⚠ Handoff (a) called this *"wraps to a second row at 800 px"* — the second row starts at **1200**
  and the eight-row stack at **991**. **A flagged-but-unmeasured layout note understated it 4×.**
- **Row totals.** `fmt_cmap_total()` (one decimal below 10, integer above) now serves the chart label
  **and** the two prose sentences quoting the same numbers, so they cannot disagree again. The
  weakest row reads **(0.2)** where it read **(0)**, against prose saying 0.2 and dividing by it.
- **The emissions clause.** See §1(a).

---

## 3. ⛔⛔ THE THREE LESSONS, and the second is the one that nearly bit

### (a) A gate NAMED A CONSTANT THAT DOES NOT EXIST — `e$X` is NULL, not an error
`test-plot-text-fits.R` referenced **`e$LAB_LUC_CAPTION` twice; no such constant has ever existed in
`app/`** — it is `NOTE_LUC_SPLIT` (`plots.R:520`), which the **same test file names correctly in a
comment**. So the value was `NULL`, and (i) test 1's `extras` carried `NULL` **twice**, leaving the
longest caption in the app unmeasured at both widths; (ii) the assertion whose own comment says *"the
retired character-count wrap must FAIL the same budget, or this gate is not guarding the thing that
was wrong"* wrapped the bare provenance prefix — **399.5 px against a 233.1 px budget, so `expect_gt`
passed on a string 2.2× smaller than its subject.** The caption it names is **897.1 px**.

⭐⭐ **AND THE CLAIM WAS BOUNDED BY MUTATING BOTH VERSIONS.** Forcing the retired character-count path
gives **14 FAIL after** the repair — **and 14 FAIL before it too**, because the other three captions
catch a broken wrapper. **The file was NOT blind**: one caption unmeasured, and its self-declared
mutation check aimed at the wrong string. ⛔ **The tempting headline — "the gate never worked" — was
FALSE.** A gate can be WEAKENED without being DISABLED, and only mutating the old version tells you
which. ⇒ `gate_named_a_constant_that_did_not_exist.md`

### (b) ⛔ THE OBVIOUS FIX TO THE COPY BUG WAS ITSELF A BUG
The clause had to become conditional. Branching on **`input$s_kind` at RENDER time** would have made
the sentence change **the moment the dropdown moved**, while the two numbers printed beside it still
described the **previous run** — a readout whose prose and whose numbers describe different
experiments. The pathway is captured in a `reactiveVal` **INSIDE the `eventReactive`**, so the
sentence always describes the run that executed. ⭐ **Whenever a readout mixes computed numbers with
branch-dependent prose, the branch must be captured where the numbers were.**

### (c) A ROUND-TRIP TOLERANCE IS FORMAT-DEPENDENT
The new row-total gate's first draft asserted `|as.numeric(label) − total| ≤ 0.05` for every row and
**failed on 18.203 → "18"**, which is *correct to its own precision*. One tolerance across two
formats either passes a wrong label or fails a right one. Now 0.05 below 10, 0.5 at or above.
(Same family as the standing rule that a tolerance is scaled to the quantity it tests.)

---

## 4. What the review found CLEAN — do not re-spend a session on these

All 8 tabs render; **23 plots** across them (17 panel + 8 review-card, one tab overlapping) all carry
a real `<img>` with non-zero natural dimensions; **zero** `.shiny-output-error` anywhere; zero
`NA`/`NaN`/`NULL` in rendered text. *Under the hood* tables full at **38 / 6 / 8 rows, 0 empty
cells** — the label-table validators hold. ⚠ **`f_partition` sitting EMPTY at rest is CORRECT** —
it is behind `conditionalPanel("input.f_mode == 'Pulse lab'")` and renders 1044×300 after a run;
do not "fix" it. No cell clears the `v >= 0.5` label threshold and then prints "0" (0 of 63
parameter-view, 0 of 37 component-view).

The static pass also reported these classes **CLEAN**, with the method stated: orphaned
renderers/outputs (both directions, all 58 `output$` against `ui.R` **and** the four `renderUI`
blocks), `renderPlotFit` id mismatches (all 25 call sites), `$` partial-matching **inside `app/`**,
and the Shiny server-arity trap.

---

## 5. Non-obvious state

- ⛔⛔ **A STALE APP INSTANCE IS SERVING PRE-FIX CODE ON `:7791`** (PID **1755**, ~3 h old, inherited
  from the previous session). It still shows **`(0)`**, the **8-row navbar** and the **old emissions
  clause** — it looks current and is not. **My verified instance is `:7793`** (PID **7734**, launched
  from Bash, current code, all three fixes). ⚠ **`:7788` and `:7789` return HTTP 500** — dead
  instances from an earlier session. **Marcus was told and has not yet said to kill any of them.**
  Kill 1755 before showing anyone `:7791`.
- **Branch.** CCX `main` at **`100b353`, PUSHED**, tree clean.
- **Suite.** App-facing files (constraint-map ×2, plot-text-fits, review-cards, the four panels, both
  lints, future ×2, seas-lag-split, enso-split) = **607 PASS / 0 FAIL / 0 ERR**. ⚠ A FULL run takes
  **~12 minutes** and was **not** re-run after the fixes — the known standing red is
  `test-mode-file.R:323`, dAIC +4.18, **NAMED RED BY RULING**, not a red to fix.
- ⚠ **`pgrep -f` self-matching** applies as always — match on `exec/R --no-echo.*runApp` or wait on
  the PID. And **never edit a script while an interpreter is running it**; the mutation tests in this
  session were run against a git-revertible tree, never a live one.
- **The `$` partial-match exposure is NOT closed.** `af0c856` converted `lib_seas_limbs.R:117`, but
  handoff (a)'s claim that this was *"the one that is not a print statement"* is **WRONG**: **eleven
  exposed reads remain in `calibration/`, and FOUR are inside gates** —
  `diag_price_the_lag.R:205`, `diag_price_the_land_axis_on_support.R:91`,
  `diag_kz_bracket_on_the_sourced_target.R:227`, and the E2 verdict at
  `diag_gamma_enso_profile.R:123`. **All eleven read a legacy 21-parameter ancestor, which carries
  the scalar EXACTLY, so none is live** — measured: `$` and `[[` agree whenever the exact name is
  present. **Convert-on-touch; the four gate reads deserve a pass of their own.**
- **Still unmerged, still owed** (unchanged): `emissions-interp-constant` (`35f38dc`) rides with the
  next refit; **this work did not trigger one** — no objective change, no mode file written.
- **Unchanged deploy blockers, all Marcus's**: the two `SET-BEFORE-DEPLOY` URLs (⚠ update
  `test-review-cards.R`, don't delete it), a start-up re-time on an **IDLE** machine, the hosting
  plan's limits. ⚠ Cold start measured today: **~120 s to HTTP 200** on a machine running other work.

---

## 6. Recommended order for the next session
1. **Get Marcus's copy for §1(a)** — a placeholder sentence of mine is live in the shipped app.
   Everything else can wait; that cannot.
2. **Kill PID 1755 (`:7791`)** once he says so, and 7788/7789 with it. A stale instance that looks
   current is the app-side version of a stale output sitting at a canonical path.
3. **Rule on §1(b)** — the four static findings. #3 (`CCX_BASE_SIZE`) is the one with teeth: it is
   silent, and it corrupts the pixel budgets that every text gate depends on.
4. **Answer §1(c)** — run `test-seas-lag-split.R` at `0cbc1ac` and settle whether the NaN warnings
   predate today. One command, and it stops a caveat propagating.
5. **Then, if the app work is done: §4 of handoff (a) is still open and unstarted** — whether the
   constraint map wants a **SECOND evaluation point** (e.g. at the quarantined `hilda31pe` control,
   ~50 s), to say whether the pins/pulls picture is a property of the MODEL or of THIS fit. **A real
   choice, not a chore.**
