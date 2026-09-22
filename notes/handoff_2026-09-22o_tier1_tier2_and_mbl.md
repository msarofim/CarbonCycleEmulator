# Handoff — 2026-09-22 (o). **Marcus's 45-comment review is COMPLETE: Tier 1, Tier 2, R3 and all of Tier 3, every item verified in a browser. The app is now CarboTope. The NOAA MBL zonal pull landed and RETRACTS two of the three failures (n) reported against `rep_dC`. And the first Tier-3 chart falsified a claim the app itself was making, which is the best argument for having built it. What remains is R2 (an objective ruling), N5, and the four deploy-time settings.**

> Self-contained. **Read first, in this order:** `notes/review_2026-09-22_marcus_app_comments.md`
> (the 45-item triage, **§8b the status block**, **Appendix A** the first `rep_dC` result and
> **Appendix B** the measurement that revises it) · CHANGELOG 09-22 (o) (p) (q) ·
> `notes/plan_2026-09-22_product_beta_and_writeup.md` · handoff (n) for everything before this.
> ⚠ `~/.claude/CLAUDE.md` execution rules apply. ⚠ `INDEX_ccx.md` is the auto-loaded ROOT ONLY —
> read the sub-index before answering.

## 1. The model is untouched, again
`v1.0-hilda29l` at `3d1b0c0` is still the tag. **No model code, objective or mode file was
modified.** The only change outside `app/`, `tests/`, `notes/` and `CHANGELOG.md` is one
user-facing blurb string in `R/mechanisms.R` (a dated code comment that had leaked into copy) and
a new fetcher in `data-raw/download_data.R`. Commits `814c61c` · `486f401` · `1b16375`.

## 2. What shipped
1. **`814c61c` — Tier 1 + Tier 2.** All eight Tier-1 items and all 17 Tier-2 copy edits except
   **O1 (the rename)**. Two of the Tier-1 items got a **gate** rather than a rewrite; see §3.
2. **`486f401` — the MBL zonal measurement** and the retraction it forces; see §4.
3. **`1b16375` — start-up re-timed**: 116 s to listening at load ~2.5, then **0.4 s** to a
   rendered first page. ⚠ **Every process start recompiles the C++ core** — `Rcpp::sourceCpp()`'s
   `cacheDir` is the R session's own tempdir, so a container is always cold and there is no warm
   case to hope for. `APP_WARMUP_NOTE` deliberately **kept at "three minutes"**: it is an upper
   bound, the contended case measured 168 s, and shaving a public promise to the best observation
   is the wrong direction for a beta whose visitors arrive in a burst.

**Verified in a running browser, not by sourcing**: every stale string absent and every
replacement present in `document.body.textContent`; the parameter table **38 rows, no blank
description or unit, exactly 3 em-dashes**; the two stand-in/pin tables rendering with the
computed overlap; no console errors.

## 3. The two that were not copy problems
Both were **hand-maintained tables drifting behind a moving model**, which is the constants-ledger
decoupling class. A third hand-rewrite buys a year at most, so both now fail loudly.

- **U1 — the parameter table printed a column of NAs** under *"these are the numbers the
  calibration fits."* 38 names through a ~22-name-era `desc`/`unit` list. Now
  `app/R/params_meta.R` + `app_validate_param_meta()`, which rejects **a fitted name with no
  label** and **a label for a name that is neither fitted nor DECLARED retired**;
  `app_param_table()` **reports a failing table in place of the rows**.
  `tests/testthat/test-app-params-table.R`: **18 assertions, 5 mutation tests.**
  ⚠ **Second bug found while fixing it: `bomb_total`, `luc_scale` and `rep_dC` are fitted names
  with NO slot in `ccx_default_params()`** — global.R carries them separately — so they printed
  "—" although the app runs on their fitted values. **Any loop over `CCX_PARAM_NAMES` against a
  parameter LIST silently misses these three.**
- **N12 — the pins and the shims were two lists presented as one.** Two labelled tables now, with
  the **overlap COMPUTED** (7 stand-ins, 9 pins, 3 in both at `hilda29l`, all held at 0 — i.e.
  stand-ins switched off). `RV_SHIMS` is sourced to the 09-16 whole-model review and gated by
  `rv_validate_shims()`, 4 more mutation-tested checks.

**N8 was my error and now carries a measurement.** Card 4 denied the volcanic mechanism;
`gamma_diff = 0.25` is live and a matched pair (0.25 vs 0, same spin-up function, same forcing)
prices the AOD → diffuse-light → NPP path at **1.53 ppm** at its largest in 1991–95 and
**−0.73 ppm** at 2024. ⚠ `R/forcing.R`'s comment *"Moot while gamma_diff defaults to 0"* is STALE.

## 4. ⛔ THE RETRACTION — read this before quoting anything from (n) §5 or Appendix A §A3
**`calibration/diag_rep_dc_mbl_zonal.R`**, Appendix B, CHANGELOG (p).

NOAA MBL **zonal** reference (Lan et al. 2024, **doi:10.15138/DVNP-F961**), sine-latitude
weighted, minus **the repo's own** station series, **matched month by month** (SPO carries 12
months in only 36 of 48 years, so annual means either truncate at 2020 or alias the seasonal cycle):

| | NH | SH |
|---|---|---|
| model needs | **+3.41** | **+3.62** |
| **MBL zonal, MEASURED** | **+0.738** (47/47 yr positive) | **+0.814** (46/46) |
| ratio | **4.6×** | **4.5×** |

- ⛔ **SIGN: RETRACTED.** (n) read it off **global − MLO** = −0.88 — a *global* mean against a
  *northern* station. **Not like-for-like**, which is the standing rule it broke. Hemisphere
  against its own station, **both offsets are positive in every year**.
- ⛔ **ORDERING: RETRACTED.** Measured **SH > NH**, the model's own ordering, not backwards.
  (n)'s ~+0.9/+0.3 was the global number shifted by half an *assumed* gradient — §A4 flagged it
  as arithmetic and it was wrong.
- ✅ **MAGNITUDE stands and is now the whole case: ~4.5×.**
- **NEW:** the NH offset declines at **−0.105 ± 0.026 ppm/decade** (4σ); the model's is constant.
- **VALIDATED, not trusted:** the two quantities Wu et al. (2024) report independently both land
  **inside** their ranges, and the diagnostic prints INSIDE/OUTSIDE rather than asserting it.
- ⚠ **(n) said the download needs a browser session. It does not** — the form's Submit is JS but
  GETs a plain `ghg.php?...` endpoint. `fetch_mbl_zonal()` in `data-raw/download_data.R` does the
  two-step, errors loudly if the form changes, and writes three MANIFEST rows (URL, citation,
  date, SHA-256). **The previous pull was scratchpad-only; that gap is closed.**

## 5. R3 and Tier 3 — RULED and BUILT (commits `a799dba`, `2a8141d`)
**Marcus's rulings, taken during this session:**
- **R3 — the rename is scoped to the TITLE and the DEPLOYED URL.** `APP_TITLE <- "CarboTope"`;
  deploy target **`carbotope.shinyapps.io/carbotope`**, recorded in `app/DEPLOY.md`. **The repo
  stays `CarbonCycleEmulator` and the code keeps `ccx_`** — neither is public-facing. ⭐ The URL
  is the expensive half and must be set at the FIRST deploy.
- **Tier 3 — all four, in order: C2, F2, I1, C6.** All built, all verified in a browser.

⛔ **C2 EARNED ITS PLACE IMMEDIATELY BY FALSIFYING THE SENTENCE NEXT TO IT.** The ENSO blurb said
*"switch it off and the wobbles go."* MEASURED 1959–2024: full model **0.269 ppm/yr** vs observed
**0.435** (62 %); **ENSO −23 %, temperature −22 %, volcanic −8 %, all three together only −43 %.**
Most of this model's wobble is the **prescribed emissions record's own year-to-year structure**
(−19 % alone), and `ocean sink off` *increases* the scatter by 7 %. Blurb rewritten ⇒
[[ccx_wobble_is_mostly_emissions]]. ⚠ Not gate V's estimator; never quote as the gate's
decomposition.

**Also done, unblocked, from the original Tier-3 list:**
- **W2 — computed, and the PREMISE IS FALSE.** Land-use emissions are positive in **all 275
  years**; there is no date on which deforestation became a net sink. What crosses is the land
  AS A WHOLE: **1989** in GCB, **1971** in this model. The 18-year gap is the same story as the
  model's high land sink (2015–24 residual 3.01 vs GCB 2.36; gate 7 z +1.36) and the note says
  so on the page.

**NOT built, and the only Tier-3 item left: N7** (commonalities among the years the model over-
and undershoots the growth rate). The C2 panel is now the natural place for it.

## 5b. NEXT — what is actually owed
1. ⏳ **R2 — `rep_dC`'s prior. THE SIDE TEST IS DONE** (`diag_rep_dc_prior_centre_width.R`,
   CHANGELOG 09-22 (u); run at `outputs/diagnostics/rep_dc_prior_centre_width_20260922.log`).
   **Re-centring alone: +0.049 ppm, free.** **Tightening σ 1.0→0.2: −1.65 ppm at −17.6
   log-units.** ⭐⭐ **They INTERACT** — the tightening costs 28.7 centred at 0 but 17.6 centred
   at the measured 0.78, so **the centre matters only once the width is tight**; if it is ever
   tightened it must be re-centred in the same move. ⛔⛔ **And who pays is NOT the station
   levels** (`co2_level_MLO` +0.92, `co2_level_SPO` +0.31, `d13c_level_SPO` +8.56 all IMPROVE):
   the cost is **`co2_icecore` −13.45** and **bomb-¹⁴C −10.7**. The offset is held up by the
   preindustrial anchor and the ventilation constraint. **The measured offset is now ON CARD 1**,
   as Marcus ruled. Remaining for R2 proper: ⛔ An OBJECTIVE change (freeze record §4.1: a ruling, then
   a restamp of every mode). **The measurement is in** (§4). What it says: re-centring on +0.78
   moves the fit z +3.52 → +2.74, **relieving 22 % and relabelling 78 %** — and
   [[ccx_rep_dc_prior]] already measured the centre as **nearly inert** (likelihood-only optimum
   5.62 ppm at curvature sd 0.097, ~10× tighter than the prior), so re-centring would barely move
   the fit at all. **The WIDTH is the live question**: a representation term's defensible σ floor
   is ~0.2 ppm (Francey et al. 2019), 5× tighter than today's 1.0, at which the same value sits at
   z +13.7. ⛔ >1/3 of the offset's value is isotopic — never a CO₂-only ruling.
2. ⛔ **N5 — STILL NOT DONE, and now SCOPED. NOAA publishes NO zonal/MBL reference for
   δ¹³C** — measured, not assumed: `ghg.php?param=C13` returns an empty fragment with no
   generated file, and the form's own parameter list is CO₂/CH₄/N₂O/SF₆. So the CO₂ trick of
   §4 does not transfer. What DOES exist is **95 per-site δ¹³C flask records**
   (`aftp/data/trace_gases/co2c13/flask/surface/`, `..._sil_month.txt`), so the hemispheric
   mean has to be BUILT the way NOAA builds its CO₂ one — sine-latitude weighting over the
   station network. ⚠ **That is a METHOD CHOICE, not a download**: which sites qualify, how to
   weight them, how to treat gappy records. Per the standing rule it needs a ruling before it is
   built, and it is the reason N5 is not simply "an hour's work" like the CO₂ side was.
3. **N7 — DONE** (`calibration/diag_growth_residual_years.R`, CHANGELOG 09-22 (u)/(v)). The
   misses are **not structured**: ENSO r −0.06 (p 0.62), volcanic AOD r +0.18 (p 0.16), year
   r −0.00 (p 1.00) on n = 66, every decade mean inside half a standard deviation. Largest
   single overshoot **1991** (the model under-draws after Pinatubo); **1983** misses the other
   way, so not even volcanoes are a rule. ⭐ **The finding that survives is on card 4 and is
   computed there:** the model's growth anomaly tracks the ENSO index MORE strongly (+0.39) than
   the observed one does (+0.29) — **the variance it is missing is not ENSO-shaped.**
4. **Before the post:** set `APP_FEEDBACK_URL` and `APP_REPO_URL` in `app/global.R` (both are
   `SET-BEFORE-DEPLOY` and the app says so on screen); claim the **carbotope** shinyapps name;
   check the host's active-hours and concurrency limits. ⚠ `calibration/lib_design_gates.R` is a
   **runtime dependency of the app** and must ship — `app/DEPLOY.md`.

## 6. State to carry — non-obvious
- ⚠ **`CarboTopeSubstack.docx` is in the repo root and Word has it OPEN** (`~$` lock file).
  **Marcus's drafting — do not read, edit or commit it.** Both untracked, left exactly as found.
- **The app is RUNNING** on `http://127.0.0.1:7788`, started by hand from this repo (option 2 in
  `app/DEPLOY.md`), serving the current code.
- ⛔ **A TRAP WORTH THE SPACE: `pkill -f "shiny::runApp('app', port = 7788"` MATCHES NOTHING.**
  `ps` renders the R child's command line with `~+~` in place of spaces, so the pattern misses,
  the old process keeps the port, the "restart" dies with `Failed to create server` — **and the
  browser goes on serving the OLD build while you verify against it.** It cost two fixes reading
  as "not applied". **Check the process that holds the RESOURCE**:
  `lsof -nP -iTCP:7788 -sTCP:LISTEN`. Same family as [[pgrep_wait_loop_matches_itself]].
- ⛔ **AND ONE OF MINE: a Python edit batch that asserts part-way through writes NOTHING.** Three
  successful replaces were reported "ok" and then discarded when a fourth assertion failed before
  `write()`. **Caught only by an explicit audit pass** — a script asserting, for all 27 review
  items, that the old string is ABSENT and the new one PRESENT, with R comment lines stripped so a
  comment quoting the old text does not read as a miss. **Re-run that audit after any further copy
  work**; it is the reason this handoff can say "all of Tier 1 and 2" rather than "most of".
- ⛔ **`co2_global` IS NOT A COLUMN OF ANY RUN** ⇒ [[ccx_co2_global_not_a_column]]. `app/global.R`
  attaches it by hand to TWO paths; every PULSE run has none. Reading it elsewhere gives NULL →
  `numeric(0)` → **rows `rbind` drops SILENTLY**, and the F2 panel drew two of three bands with no
  error. Use `ccx_global_co2()`. **A column one code path attaches is not a property of the
  structure — grep the CONSTRUCTOR.**
- ⚠ **ggplot captions CLIP; the (l) fix had only ever been applied to the REVIEW tab.**
  `app_provenance_caption()` now wraps, so every panel is covered and it cannot be forgotten at a
  call site.
- ⚠ **`test-mode-struct-lint.R` is a LITERAL, FILE-LEVEL string match.** A comment that spells out
  the pattern it rejects trips the gate. And `ccx_load_mode()` returns the likelihood parameters
  under **`$err`**, not the top level — `lm$rep_dC` is NULL and fails as "argument is of length
  zero", not as a wrong number.
- **SUITE: 4181 / 2 after all of the above.** (Was 4176 / 2 at §2.) Both failures **PRE-EXISTING, REPORTED, NOT TOUCHED**:
  Both failures **PRE-EXISTING, REPORTED, NOT TOUCHED**: `test-mode-file.R:323` (the **NAMED AIC
  RED**, ΔAIC +4.18 for the control — a ruling, not a regression) and `test-seas-lag-split.R:205`
  (the standing fixture error named in (k)). Neither references `app/`. ⚠ Differs from (n)'s pair:
  `test-u-hs-fitted.R:87` reports as a **WARNING** now, not a failure.
- **R4 is ruled and PROPAGATED**: the affiliation is off the app (`APP_AUTHOR` is the bare name),
  and the standing rule in `~/.claude/CLAUDE.md` now carries the professional/informal split
  rather than a single form.
- **Memory updated, retraction propagated**: `ccx_rep_dc_co2_bias` (the retracted paragraphs are
  marked in place, not deleted), `ccx_rep_dc_prior` (cross-linked — it is why re-centring would
  not move the fit), two new files `ccx_app_label_tables_gated` and
  `ccx_app_says_what_it_is_fitted_to`, both indexed in `INDEX_ccx_ref.md` (8.9 KB, well inside
  budget).
