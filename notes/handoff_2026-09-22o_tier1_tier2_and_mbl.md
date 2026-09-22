# Handoff — 2026-09-22 (o). **Tier 1 and Tier 2 of Marcus's review are DONE and verified in a browser. The NOAA MBL zonal pull landed and RETRACTS two of the three failures (n) reported against `rep_dC` — the sign and the ordering were artifacts of comparing a global mean to a northern station. Only the ~4.5× magnitude survives, and it is now measured. Two decisions are waiting on Marcus: R3 (the rename / URL) and the Tier-3 priority order.**

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

## 5. NEXT — and the first two are Marcus's, not mine
1. ⏳ **R3 — the rename.** Left deliberately LAST of the edits. `APP_TITLE` is one constant, but
   the **deployed URL** is decided at the same time and renaming after the post circulates is the
   expensive direction. **Needs: app title only, or repo + URL too?**
2. ⏳ **Tier 3 priority order.** My ordering, unchanged from (n): **C2 the year-over-year CO₂ chart
   first** (it serves C1, C3 and card 4 at once, and is 08-29 spec ①b), then **F2** (pulse
   partition panel — machinery exists; ⚠ must NOT share a caption with a label run,
   [[pulse_label_vs_perturb]], 2.8× apart at 100 yr), **I1** (isotope hemisphere toggle), **C6**
   (volcano/temperature switches — ⚠ **two** edits each per spec §3a: zero `aod_*` AND remove the
   component from `gmst`/`sst_anom_*`, or the thermal half keeps running; the `gamma_diff` knockout
   in §3 is the measured half of it), **N7** (over/undershoot years), **W2** (the LUC sign-change
   date — **compute it, do not recall it**).
3. ⏳ **R2 — `rep_dC`'s prior centre.** ⛔ An OBJECTIVE change (freeze record §4.1: a ruling, then
   a restamp of every mode). The measurement is now in. **What it says:** re-centring on +0.78
   moves the fit from z +3.52 to z +2.74 — **relieves 22 %, relabels 78 %** — and
   [[ccx_rep_dc_prior]] already measured the centre as **nearly inert** (likelihood-only optimum
   5.62 ppm at curvature sd 0.097, ~10× tighter than the prior), so re-centring would barely move
   the fit at all. **The WIDTH is the live question, not the centre**: a representation term's
   defensible σ floor is ~0.2 ppm (Francey et al. 2019), 5× tighter than today's 1.0 ppm, at
   which the same value sits at z +13.7. ⛔ And **>1/3 of the offset's value is isotopic**, so it
   is never a CO₂-only ruling.
4. **Before the post:** set `APP_FEEDBACK_URL` and `APP_REPO_URL` in `app/global.R` (both are
   `SET-BEFORE-DEPLOY` and the app says so on screen); check the host's active-hours and
   concurrency limits. ⚠ `calibration/lib_design_gates.R` is a **runtime dependency of the app**
   and must ship — `app/DEPLOY.md`.
5. **N5** (isotope station-vs-hemisphere offsets) is the δ¹³C analogue of the CO₂ measurement just
   made and is **not done**. Card 2 is scored net of `grad_off_d13c`.

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
- **SUITE: 4176 / 2.** Both failures **PRE-EXISTING, REPORTED, NOT TOUCHED**:
  `test-mode-file.R:323` (the **NAMED AIC RED**, ΔAIC +4.18 for the control — a ruling, not a
  regression) and `test-seas-lag-split.R:205` (the standing fixture error named in (k)). Neither
  references `app/`. ⚠ Note this differs from (n)'s pair: `test-u-hs-fitted.R:87` reported as a
  **WARNING** this run, not a failure.
- **R4 is ruled and PROPAGATED**: the affiliation is off the app (`APP_AUTHOR` is the bare name),
  and the standing rule in `~/.claude/CLAUDE.md` now carries the professional/informal split
  rather than a single form.
- **Memory updated, retraction propagated**: `ccx_rep_dc_co2_bias` (the retracted paragraphs are
  marked in place, not deleted), `ccx_rep_dc_prior` (cross-linked — it is why re-centring would
  not move the fit), two new files `ccx_app_label_tables_gated` and
  `ccx_app_says_what_it_is_fitted_to`, both indexed in `INDEX_ccx_ref.md` (8.9 KB, well inside
  budget).
