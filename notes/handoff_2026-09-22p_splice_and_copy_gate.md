# Handoff — 2026-09-22 (p). **The two things handoff (o) left unblocked are done: the copy audit is a GATED SUITE FILE instead of a lost scratchpad script, and the cross-tab step is measured, RULED (Marcus: splice + caption) and BUILT. The measurement found a THIRD emissions history nobody had looked at, and the fix moves a shipped number: ssp245 at 2100 goes 502.6 → 515.0 ppm. What remains is still R2 and the four deploy-time settings — both Marcus's.**

> Self-contained. **Read first, in this order:** handoff (o) for everything before this ·
> CHANGELOG 09-22 (w) (x) (y) · `notes/plan_2026-09-22_product_beta_and_writeup.md` §1 and §3
> (build item 1 is now closed) · `outputs/diagnostics/app_cross_tab_step_20260922.log`.
> ⚠ `~/.claude/CLAUDE.md` execution rules apply. ⚠ `MEMORY.md` is the auto-loaded ROOT ONLY —
> read `INDEX_ccx_ref.md` before answering anything about the app.

## 1. The model is untouched, a third time
`v1.0-hilda29l` at `3d1b0c0` is still the tag. **No model code, objective or mode file was
modified.** Everything is in `app/`, `tests/`, `calibration/`, `notes/`, `CHANGELOG.md` and one
diagnostic log. Commits `b7df044` · `1b4ca98` · `4e9baf3` · `a5a7a46` · `98db028`.

## 2. The copy audit is a suite file now (`b7df044`, CHANGELOG (w))
`tests/testthat/test-app-review-copy.R` — **36 assertions, 4 mutation tests.**

- **It had been lost.** (o) §6 says the audit is the only thing that caught the Python batch
  that reported three copy edits "ok" and then wrote nothing. It lived in a scratchpad, and that
  scratchpad belonged to the previous session. **Re-run as found it reports 6 failures of 27 —
  and all six are R COMMENT LINES quoting the old wording**, which is the false-failure mode the
  fixed version stripped. The fixed version was never written out.
- **Whole-line comments only.** Deciding whether a `#` inside a line opens a comment or sits in a
  string needs a parser. ⚠ If a TRAILING comment ever trips a check, move the comment onto its
  own line — do not weaken the strip.
- ⭐ **One mutation test requires the RAW source to fail MORE than the stripped source.** Without
  it the strip could stop mattering (someone deletes the comments) and nothing would say so.
- The surface grew from six files to eight (`app/R/plots.R`, `app/R/plots_review.R` joined when
  Tier 3 landed), read as one blob so an item moving between files is not a failure. **C2's
  corrected wobble claim is item 28.** **Re-run this after any further copy work.**

## 3. ⛔ THREE HISTORIES, not two (`1b4ca98`, CHANGELOG (x))
`calibration/diag_app_cross_tab_step.R`. Measured off **the app's own startup** — `source("app/
global.R")`, its spinup, its fitted forcing parameters, the same helpers `server.R` calls.

| tab | inventory | CO₂ 2024 | step |
|---|---|---|---|
| The Keeling Curve | historical (GCB) | **424.37 ppm** | — |
| Futures | ssp245 (SSP/LUH2) | **412.33** | **−12.05** |
| Futures › **“Build your own”** | GCB fossil + SSP land-use | **410.79** | **−13.58** |

- ⚠ **THE THIRD HISTORY IS A PILL INSIDE FUTURES, NOT THE “What if…?” TAB.** (x) first named it
  wrong and (y) corrects it: “What if…?” runs the MECHANISM switches on the historical scenario
  and never had a step. `app_stylised_emissions()` takes fossil from the GCB history and land-use
  from the SSP background **for every year** — the `kind` switch only rewrites the future — so the
  hybrid past was under all four stylised pathways. Gate 5 only ever compared two.
- **Verified to be the inventory before being called one:** both curves are `(co2_NH+co2_SH)/2`
  annual-mean (`R/climate.R:196`), both see the same spliced IGCC temperature over history
  (`gmst_obs = TRUE`), and −84.5 GtC at a 270-yr airborne fraction of 30 % reproduces the −12.05.
- ✅ **A check that PASSES on the way past**: the Keeling tab's 424.37 reproduces the objective's
  periodic run to the digit, and sits **+3.40 ppm** above the MLO/SPO station mean against the
  fitted `rep_dC` = 3.52 — the panel shows the offset the likelihood scored.
- **The 21,862 startup warnings are ONE class**, captured rather than suppressed
  (`withCallingHandlers`): the carbonate constants extrapolating below 2 °C in the cold boxes,
  benign per 09-21 (i). *"There were 50 or more warnings"* is exactly the shape a second, real
  warning hides in. There isn't one.

## 4. ⭐⭐ THE SPLICE (Marcus: “splice + caption”) — `98db028`, CHANGELOG (y)
`app_splice_history(em, scenario)` in `app/global.R`, called from **`app_run_coupled()`** so all
four emissions paths get it (scenario comparison, build-your-own, the pulse lab — which built its
table from `APP_SSP_EMIS` by hand — and anything added later). Splicing at the four call sites
would have been four chances to forget; same choke-point argument as the fitted forcing
parameters that wrapper already carries.

**Measured after: the Futures tab reproduces the Keeling tab at 2024 to the last digit (424.37
both), the stylised path to 424.38. Worst step 13.58 → 0.00 ppm.**

- ⭐ **THE JOIN IS A RAMP, AND THE GRID DOES IT — nothing was harmonised.** The spliced table keeps
  the scenario's OWN rows at the years it reports them (the SSPs are annual to 2015, decadal
  after), so the first post-2024 node is **2030** and `ccx_annual_to_monthly()` crosses 2025–29
  exactly as it already does between two decadal nodes. No offset, no convergence year.
- ⛔ **WHAT THE SPLICE CANNOT FIX, and §3b of the diagnostic PRINTS:** against observed 2024 fossil
  (10.53 GtC/yr) each scenario's next reported year sits at **ssp119 −4.40, ssp126 −1.11,
  ssp245 +0.54, ssp370 +2.93, ssp585 +3.32 GtC/yr.** Several SSPs no longer start where the world
  is. **Not drawn anywhere** — the Futures tab plots CO₂ and temperature, never emissions — but an
  emissions panel added later would show it.
- **The gate is DERIVED, not picked**: "what remains must be under a tenth of the step it was
  built to close". An absolute ppm bound here would be a number chosen by whoever wrote the gate.
- **`d13c_foss` is deliberately NOT carried across.** `ccx_build_forcing()` falls back to the
  historical file's own column when the supplied table lacks it (`R/forcing.R:718`) — exactly the
  series the splice would have passed — while carrying it would put NAs on the scenario rows.
- **The caption** is `APP_SPLICE_NOTE`, derived from `APP_SPLICE_YEAR <- max(APP_EMIS_HIST$year)`,
  so a GCB update moves the handover and the sentence together.
- ⛔⛔ **IT MOVES A SHIPPED NUMBER: ssp245 2100 502.6 → 515.0 ppm; build-your-own 501.6 → 514.8.**
  Checked: **no card, test or figure quotes a futures concentration** — card 5's IRF runs
  `ccx_build_forcing("historical", …)` directly and is untouched. But any note or figure made
  before (y) is on the old basis.

**VERIFIED IN A RUNNING BROWSER, not by sourcing**: the caption present in
`document.body.textContent`; all three modes exercised — Scenarios (402–911 ppm at 2100),
Build your own (544 ppm), Pulse lab (100 GtC in 2050 → 31 % airborne at +100 yr, F2 partition
panel rendering); **zero `.shiny-output-error` nodes** in any of them.

## 5. NEXT — what is owed, and both are Marcus's
1. ⏳ **R2 — `rep_dC`'s prior.** Unchanged from (o) §5b: the side test and N5 are in, the WIDTH is
   the live question (σ 1.0 → 0.2 is −1.65 ppm at −17.6 log-units; centre and width INTERACT and
   must move together), and it is an OBJECTIVE change — a ruling, then a restamp of every mode.
   ⛔ >1/3 of the offset's value is isotopic; never a CO₂-only ruling.
2. **Before the post:** set `APP_FEEDBACK_URL` and `APP_REPO_URL` in `app/global.R` (both
   `SET-BEFORE-DEPLOY`, and the app says so on screen); claim the **carbotope** shinyapps name;
   check the host's active-hours and concurrency limits. ⚠ `calibration/lib_design_gates.R` is a
   **runtime dependency of the app** and must ship — `app/DEPLOY.md`.
3. Optional, not owed: an emissions panel on the Futures tab would make §4's join visible, which
   is an argument both for and against adding one.

## 6. State to carry — non-obvious
- **The app is RUNNING on `http://127.0.0.1:7788`**, restarted by this session at `98db028` and
  serving the splice. ⛔ **Stop it by the process that holds the RESOURCE**
  (`lsof -nP -iTCP:7788 -sTCP:LISTEN -t`), never `pkill -f` on the runApp string — `ps` renders
  the R child's command line with `~+~` in place of spaces, confirmed again this session.
  Startup to "Listening on" was ~3 min at load 9.3 (the diagnostic runs were on the machine).
- ⛔ **`test-mode-struct-lint.R` bit twice, and the second time was the documented trap.** A raw
  `readRDS` of the mode file for PROVENANCE trips it (rightly — it is one line from running a
  HILDA mode as a column; use `ccx_load_mode()$md`), and then **the comment EXPLAINING the fix
  tripped it again at the same count**, because the lint is a LITERAL, FILE-LEVEL string match.
  The warning is now in `diag_app_cross_tab_step.R` for the next person.
- ⚠ **`CarboTopeSubstack.docx` is still in the repo root with Word's `~$` lock file.** Marcus's
  drafting — do not read, edit or commit it. Untracked, left exactly as found.
- ⚠ **`outputs/diagnostics/whole_model_scorecard_20260920_hilda29l.rds` has an uncommitted
  modification that PREDATES this session** (it was already dirty at launch). Not touched, not
  committed; worth someone deciding whether it should be.
- **Memory**: new `ccx_app_three_histories.md`, indexed in `INDEX_ccx_ref.md` (11.1 KB, inside
  budget). Records the fix, the moved 2100 number, and the join the splice cannot close.
- **Suites run:** `app|review` **117/0** (2 pre-existing warnings), `struct-lint|overlay-idiom`
  **13/13**, the new copy gate **36/0**. The full suite was NOT re-run — the two standing
  failures from (o) §6 (`test-mode-file.R:323` named AIC red, `test-seas-lag-split.R:205` fixture)
  are untouched by anything here.
