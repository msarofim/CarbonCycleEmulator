# Handoff — 2026-09-24 (c). **F4 and F5 are SHIPPED and browser-verified. Marcus's build list from the 09-24 review is now EMPTY.** ⭐⭐ **Building F4's gate found a REAL, PRE-EXISTING DEFECT — the pulse lab releases carbon before the year the slider says — and the fix is DELIBERATELY UNTAKEN, awaiting his ruling.** The next item is Q3/Q1, which costs a refit.

> ⚠ **IF YOU ARE A FRESH SESSION: every path here is relative to
> `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, which is NOT your cwd.** The standing rule
> launches sessions from `FaIRtoFrEDI/` (the memory keyspace follows the launch cwd), so a bare
> `notes/...` will not resolve. Prefix with the absolute path, or `cd` there.
>
> **Read first, in this order:** `notes/handoff_2026-09-24_app_review_round2.md` (the five rulings
> — still the governing document) · CHANGELOG **09-24 (d)** and **(e)** · then **§3 and §4 below**,
> the only parts containing work not yet done.
> ⚠ `~/.claude/CLAUDE.md` applies. ⚠ `MEMORY.md` is the auto-loaded ROOT ONLY — read
> `INDEX_ccx_ref.md` before answering anything about the app or the pulse.

## 1. What this session did
Commits **`a9c0167`** (F4 + the diagnostic) and **`416bd69`** (F5). ⭐ **The model is untouched** —
`v1.0-hilda29l` at `3d1b0c0` is still the tag, objective #13 still frozen, no parameter or prior
moved. Everything is app code, a diagnostic, two gates, CHANGELOG and memory.

**Marcus's ordered build list (F1 → F2 → F4, then F5) is now COMPLETE.**

| item | state |
|---|---|
| F1 driver panel | shipped 09-24 (b), `bf7e879` |
| F2 residual numbers on panel 2 | shipped 09-24 (c), `a398162` |
| **F4 temp/CO₂ radio on all three modes** | **shipped this session, `a9c0167`** |
| **F5 the 1900–2150 span** | **shipped this session, `416bd69`** |
| F3 ENSO double-count | ANSWERED 09-24 (b) — caveat, not refit. ⚠ **the caveat sentence itself is still unwritten** |

## 2. ⭐⭐ THE DEFECT F4's GATE FOUND — read this before touching the pulse lab
`calibration/diag_pulse_spline_ringing.R` · memory `ccx_pulse_spline_ringing` · CHANGELOG 09-24 (d).

The gate's first draft asserted that the pulse run and the baseline run **agree before the pulse**,
as causality requires. **It failed.**

| | |
|---|---|
| **cause** | `ccx_annual_to_monthly()` uses a **natural cubic spline** = a **GLOBAL** interpolant. Its additive per-year correction fixes each year's **MEAN** (exact to 2.7e-15 GtC/yr ⇒ **the pulse size is fine**) and does **nothing about the AMPLITUDE**. |
| **emissions space** | within-year monthly swing **68.2 GtC/yr in 2049**, *larger* than the **34.2** in the pulse year itself; decays ~4× per year either side |
| **the artefact** | **3.06 ppm CO₂ + 0.003 °C in the 26 years BEFORE the release**, 13 −ve / 13 +ve = **6.5 % of one pulse-ppm** |
| **the consequence** | vs a ring-free control: **−0.05 pp** airborne at +100 yr, **−0.01 pp** at +250 yr, **−0.1 %** warming ⇒ **the numbers the tab quotes STAND** |
| **verdict** | a **causality violation** (bound = 0, from a law) with a **presentational** consequence |

⛔ **THE CODE DOCUMENTS THIS AGAINST ITSELF.** `R/forcing.R:536` states the assumption the pulse
breaks in as many words, and the `method = "constant"` branch exists *precisely* because a spline
through the sharply peaked bomb-¹⁴C series undershot either side of the 1962 peak. **Same lesson,
not yet applied to the pulse.**

⚠ **The decay chart is clipped at the pulse year, so the reader never sees the bump.** The clip is
doing the app a favour **by accident**. A docstring written earlier in the same session called the
pre-pulse difference "zero by construction"; it was **retracted in-session by its own gate**.

### ⛔ THE FIX IS NOT TAKEN — this is the decision waiting for Marcus
Two candidate homes, and they are **not the same size**:
1. **The model's forcing path** — `ccx_annual_to_monthly()`, or a `method` argument threaded
   through `ccx_build_forcing()`. **Every fitted value depends on this path.** Objective **#13 is
   FROZEN**, mode tagged **`v1.0-hilda29l`**. Same freeze consideration F3 and Q3 carry.
2. **The app's pulse construction alone** — nothing else touches it, so it is **free**; but
   piecewise-constant emissions change that tab's *background* within-year shape too, which is a
   change to what the tab shows.

⭐ **My recommendation if he wants one:** (2), scoped to the pulse lab, because the consequence is
presentational and (1) cannot be done without a refit. But it is a methodological choice and the
standing rule says flag it, so it is flagged.

## 3. What is NEXT
1. ⭐⭐ **Q3 + Q1 as ONE investigation** — forest regrowth vs CO₂ fertilisation. **The only open
   item that could move a number.** Testable hypothesis unchanged: the model crosses land
   source→sink in **1971** against the measured **1989**, and an over-strong single fertilisation
   term doing the work of both is exactly what makes the sink appear too early. ⛔ **Costs a new
   pool or flux, a new fitted name and a REFIT** — same freeze consideration as F3 and as the
   pulse fix above. **Do not start it without his go-ahead on the freeze.**
2. **The F3 caveat sentence** — measured 09-24 (b), still not drafted. Per the standing rule,
   reader-facing copy states the current fact and carries **no fix history**.
3. **The pulse-ringing fix**, once ruled (§2).
4. **Q4 / Q2 / Q5** — unchanged and still unmeasured; see 09-24 (b) §4.

## 4. ⚠ Flagged this session, NOT acted on
- ⚠ **Build-your-own's takeaway says "Note how little the temperature falls even when emissions
  stop"** — **false for the `rate` branch**, where emissions never stop and reach 4,926 GtC/yr.
  Pre-existing (equally wrong at 2100). Reader-facing copy ⇒ Marcus's call.
- ⚠ **The fitted-range caveat is BEYOND F5's letter.** F5 took the stylised "+5 %/yr" case from
  **2.1× to 26.2×** outside the fitted CO₂→forcing range (3,516 ppm at 2100 → **44,172 ppm and
  +17.7 °C at 2150**; fitted 278–1,687 ppm). `ccx_run_coupled()` has always warned — **to the R
  console**, which is not where a student dragging a slider is looking. So a **conditional**
  caveat now renders on the page, computed from the module and the run, silent on the SSPs
  (1,137 ppm at 2150). **One `div`, trivially revertible if he would rather the tab said nothing.**

## 5. ⚠ Non-obvious state to carry
- ⛔⛔ **`INDEX_ccx_ref.md` IS AT 18,129 B OF ITS 18,432 B HARD CEILING — 303 B.** This session's
  two additions took it there (it was 16,987). ⛔ Per `memory_index_split_beats_trim` **split
  rather than trim**, and **Marcus asks for splits explicitly** ⇒ **ASK HIM FIRST, at the top of
  the next session.** `INDEX_diag.md` is **17,291 B** (1,141 headroom) and root `MEMORY.md` is
  **15,223 B of content** against a 12 KB soft target. ⚠ Root budget is CONTENT — strip the
  `<!-- -->` blocks before measuring.
- ⚠ **A PREVIEW SERVER IS RUNNING** on `http://127.0.0.1:7788` (PID via
  `lsof -nP -iTCP:7788 -sTCP:LISTEN -t`; kill **THAT**, never `pkill -f` the runApp string).
  ⭐ **The Bash workaround is confirmed and is what this session used** — `preview_start` still
  resolves `launch.json` from the SESSION root (`FaIRtoFrEDI/`) and silently starts the wrong
  server. Start it with `Rscript -e "shiny::runApp('app', port=7788, host='127.0.0.1',
  launch.browser=FALSE)"` in the background and point the browser pane at it with `navigate`.
  ⚠ Start-up **70 s and 140 s** this session at load ~2.5 — closer to the 73 s idle figure than
  09-23's, but the machine was still not idle.
- ⚠ **`get_page_text` RETURNS THE WRONG TAB** (Shiny keeps every tab in the DOM). Use
  `javascript_tool: document.querySelector('.tab-pane.active').innerText` — every copy check this
  session was made that way. ⭐ **`s_kind` is a selectize input**: `el.value = 'rate'` does NOT
  work; use `$('#s_kind')[0].selectize.setValue('rate')`.
- ✅ **RESOLVED, retire the flag: `fair_outputs/egu_fair_levels_v160_egu.csv` IS NOW COMMITTED**
  in FaIRtoFrEDI (`a6fcb32`) and the working tree is clean for it. Three handoffs carried this as
  an open item; it is done.
- ⚠ **`notes/egu_comment_mortality_rule_examples.md` is UNTRACKED in FaIRtoFrEDI** and is not from
  this session. Left alone.
- **The three DEPLOY blockers are unchanged and all Marcus's**: `APP_FEEDBACK_URL` and
  `APP_REPO_URL` both `"SET-BEFORE-DEPLOY"` (⚠ update `test-review-cards.R` when set, do not
  delete it); start-up re-timed on an **IDLE** machine; the hosting plan's concurrency limits.
- **W4's ratchet entry is still flagged and unratified** — edited while correctly failing (C3
  superseded it). Marcus has not objected and has not ratified. Unchanged since 09-24 (a).

## 5b. ⚠ THE FULL SUITE'S 4 RED ARE UNCHANGED AND STILL PRE-SESSION
`test-mode-file.R:323` (dAIC +4.2, **NAMED RED by ruling**), `test-overlay-idiom-lint.R:102`/`:122`
(`diag_rep_dc_product_ladder.R` carries the bare-`intersect()` idiom; 62 vs baseline 61),
`test-seas-lag-split.R:205` (a migrated ancestor encodes 10 parameters outside their transform
domain). **None is touched by this session's work.** ⛔ **DO NOT READ A GREEN `app|review` AS A
GREEN SUITE** — this session ran `app|review|driver|growth|future|mechanisms|climate` at **322 / 0**,
which touches none of the four.
⚠ ⭐ **The overlay lint still has the blind spot recorded in 09-24 (b)** — it matches only lines
containing `CCX_PARAM_NAMES`, so the `intersect(names(P0), names(pm))` spelling of the same idiom
slips past. Neither of this session's new files uses it either way.

## 6. The two new gates, and why they are shaped as they are
- **`test-future-yvar.R` (F4), 26 assertions.** ⚠ (a)'s failure mode was **measured, not assumed**:
  a bad radio value raises inside `data.frame()` and surfaces as a red `shiny-output-error` box —
  *not* the silent empty panel the first draft's comment claimed. (c) **ratchets the ringing as a
  SHARE of one pulse-ppm** (0.08 against a measured 0.065) so it scales with the pulse, and pairs
  it with `expect_gt(ring, 0)` so **a fix also fails the gate** and forces the ratchet down rather
  than leaving a stale bound. ⛔ **No magnitude is asserted there**: it runs on
  `ccx_default_params()`, which is **not** the app's basis (`ccx_diag_must_use_mode_base`), so
  magnitudes live in the diagnostic, which sources `app/global.R`.
- **`test-future-span.R` (F5), 21 assertions.** Pins that the run span and the view span stay
  distinct; that a view selecting no years is **refused** rather than drawn empty; and that the y
  scale trains on visible years — **mutation-tested against `coord_cartesian`, which it rejects**
  (y range 1049 vs 0.1).
- ⭐ **Both diagnostics/gates carry an EXTERNAL ANCHOR.** The ringing diagnostic reproduces the
  app's printed **31 % / 23 %** airborne shares before any arm is read. That is
  `ccx_diag_must_use_mode_base`'s rule applied, and it is what made the anchor trustworthy.

## 7. Memory written this session
`ccx_pulse_spline_ringing` (new — the defect and its transferable lesson: **an annual-mean-
conserving interpolator conserves the MEAN, not the SHAPE; any global interpolant makes a
sharply-peaked input ACAUSAL**), and two lines in `INDEX_ccx_ref.md` (which is why it is now at
its ceiling — see §5).
