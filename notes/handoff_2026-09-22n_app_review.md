# Handoff — 2026-09-22 (n). **The PUBLIC BETA is built and the "Known issues" tab ships eight cards. Marcus's 45-comment review is TRIAGED; his ruling R1 is IMPLEMENTED (the carbon-budget panel was out by 32 % and now closes to 0.14 %). The `rep_dC` research he asked for has a HARD first result: the fitted offset is the wrong SIGN, ~4× the magnitude, and its hemispheric ordering is backwards. Tier 1 / Tier 2 of the review and the R3 rename are NOT started.**

> Self-contained. **Read first, in this order:** `notes/review_2026-09-22_marcus_app_comments.md`
> (the 45-item triage + **Appendix A**, the `rep_dC` research) · `notes/plan_2026-09-22_product_beta_and_writeup.md`
> (the beta's design, the card ledger, the C/D/E reasoning, the paper parked in §7) ·
> CHANGELOG 09-22 (l) (m) (n) · `notes/assessment_2026-09-21_product_ready.md` (the freeze record).
> Supersedes handoff (k) for everything after the tag. ⚠ `~/.claude/CLAUDE.md` execution rules apply.
> ⚠ `INDEX_ccx.md` is the auto-loaded ROOT ONLY — read the sub-index before answering.

## 1. Where the MODEL stands — unchanged, and nothing here touched it
`v1.0-hilda29l` at `3d1b0c0` is still the tag. **No model code, objective, or mode file was
modified in this session.** Every commit below is app, notes, tests or docs. Objective **#13**
frozen; canonical `hilda29l` (29 fitted + 9 pins, likelihood −1391.8051 on 26 rows); free parent
`hilda32f`; control `hilda31pe`.

## 2. What shipped (commits `98f7b3d` … `be1ce72`, all after the tag)
1. **`02861de` — the beta's seventh tab, "Known issues."** Eight cards (`app/R/review.R`,
   `app/R/plots_review.R`), each putting one flaw as *deal-breaker / fixable / acceptable*.
   **Every number is MEASURED by the running model** through the scorecard's own gate kernels
   (`calibration/lib_design_gates.R`, sourced lazily, memoized in `RV_CACHE`, computed on first
   view ≈ 6 s). All eight reproduce the 09-21 scorecard to the printed digit. Also: **C2** — the
   Keeling panel now draws BOTH the raw box and `box − rep_dC` (the comparison the likelihood
   actually scored); **C3** — the residual pair is card 1; **D1** — no bands, and card 7 asks
   whether that is acceptable.
2. **`8f0589b` — ⛔ THE SERVER FUNCTION WAS NEVER THE SERVER.** `app/server.R` ended with
   `` `%||%` <- function(a, b) ``, and Shiny's two-file style takes `source("server.R")$value`
   — the LAST top-level expression — as the server. Every session died with
   `Error in server(...) : unused arguments` **before one output rendered**. **PRE-EXISTING**
   (byte-identical at the tag). Invisible from every direction previously checked: the UI builds,
   the banner renders, the process answers HTTP 200, and every plot is simply blank. Fixed by
   moving the helper above the server function. **Also fixed: the banner printed "38 parameters"**
   from `length(CCX_PARAM_NAMES)` (the whole table) while the canonical fits 29 with 9 held.
3. **`05e9470` — the launch config lives with the app** (`.claude/launch.json`, `ccx-app`, 7788).
4. **`bce110d` — Marcus's review triaged**, 45 items, + the source docx.
5. **`0397e49` — R1 implemented** (§4).
6. **`be1ce72` — the `rep_dC` research** (§5).

## 3. Marcus's four rulings, 2026-09-22
- **R1 — the budget convention: plot the GCB convention.** ✅ DONE, §4.
- **R2 — `rep_dC`'s prior center:** research first. ⏳ first result in §5; **not ruled**.
- **R3 — the rename: "rename everything."** ❌ NOT STARTED. App title, repo, deployed URL.
- **R4 — affiliation:** *"Marron Institute is for professional output (posters, talks, papers),
  but not for Substack output, comments on rules, or other less official output."* ⇒ **drop it
  from the app** (which is Substack-facing). ⚠ **This REFINES the standing global rule** in
  `~/.claude/CLAUDE.md` ("Affiliation is 'Marcus C. Sarofim (NYU Marron Institute)' only") —
  that rule should be updated to carry the professional/informal split. **Not yet done.**

## 4. R1 — what changed and what it proved (`0397e49`)
Two of Marcus's comments were ONE bug. Land-use emissions are an **internal transfer** in this
model (`e_luc` moves carbon out of the land pool into the air), so they cannot also be an
addition to the atmosphere+land+ocean system — only **fossil** carbon is new to it.

| at 2024 | GtC |
|---|---|
| cumulative fossil / LUC / total | 504.7 / 237.6 / **742.3** |
| atmosphere +314.2, raw land **−32.1**, ocean +221.5 → sum | 503.6 |
| sum − fossil | **−1.05 (0.2 %)** |
| sum − total (what the chart showed) | **−238.7 (32 %)** = cumulative LUC to within 1 GtC |

`partition_table()` now reports `land = pool change + cumulative LUC` (the residual terrestrial
sink; `land_gross` keeps the raw change by name). **Residual now +1.05 GtC = 0.14 %.**
**The same fix lands the GCB bars, and the gate settled which side was wrong:** `plot_gcb_bars()`
used raw `diff(land_C)` while `dg_annual_sinks()` — which **GATE 7 passes on at land 3.09** —
adds `eluc` back. 2014–2023 land sink **1.89 → 3.06** against GCB 2.47. ⚠ The app now agrees
with the gate, and the **remaining** model-high gap is the REAL one gate 7 scores at z +1.36.
`plot_gcb_bars()` gained a forcing argument and y-headroom (its labels were clipping).

## 5. R2 — the `rep_dC` research, first result. **This is the substantive finding of the session.**
Full record: **Appendix A** of the triage note. In brief:

**Measured from the code.** The box is a **mass-weighted WHOLE-ATMOSPHERE hemispheric mean**
(`gtc_per_ppm_hemi = GtC_PER_PPM/2`, *"each hemisphere holds half the atmosphere"*), not a
surface mean — so the continental-boundary-layer argument in the likelihood's comments is weak
against it (the BL is ~10 % of atmospheric mass). `rep_dC` is applied **identically to both
stations**. With `grad_off_co2` it jointly implies **off_NH ≈ +3.41, off_SH ≈ +3.62 ppm**,
confirmed by direct residuals (**MLO +3.37, SPO +3.69**), **flat in time** (so not a budget
drift), and worth **1306.9 log-units** — of which **more than a third is ISOTOPIC**
(`d13c_level_MLO` −361.0, `d13c_level_SPO` −163.3), because the parameter is tied across species
by mass balance. ⇒ **R2 cannot be decided as a CO₂-only question.**

**Measured from observations** (NOAA `co2_annmean_gl.txt` − `co2_annmean_mlo.txt`, fetched and
**re-derived locally in R, not transcribed**): global MBL-surface mean − MLO = **−0.88 ppm**
(1980–2020 mean), **negative every year since 1981**, drifting to −1.82 by 2024. Corroborated by
**Wu et al. 2024, ACP 24:1249–1264, doi:10.5194/acp-24-1249-2024** (global−MLO −0.46 to −0.88;
global−SPO +1.91 to +2.24; networks agree on the **growth rate** to <0.023 ppm/yr, so the
disagreement is in the **LEVEL** — `rep_dC`'s own axis).

**The confrontation — three failures at once:** magnitude (~3–4× too large), **sign** (the marine
surface mean sits BELOW Mauna Loa; `rep_dC` needs the box ABOVE it), and **ordering** (the
observations make NH the larger offset; the model has SH ≥ NH). The surface → mass-weighted
correction is **negative** (stratospheric lag, mean age ~5 yr, Andrews et al. 2001,
doi:10.1029/2001JD000465), so it **widens** the gap. ⇒ the evidence so far says `rep_dC` is **not
a representation offset** but a constant ~3.5 ppm **level bias** (~7.4 GtC of excess airborne
carbon) against an ice-core-anchored preindustrial. **Re-centering the prior would relocate the
bias, not fix it.**

⚠ **NOT established — do not quote as measured.** The **hemispheric** figures (~+0.9 NH / ~+0.3
SH) are **arithmetic**, not measurement: the global number shifted by half an assumed
interhemispheric gradient. **The real measurement is the NOAA MBL Reference ZONAL product**
(`gml.noaa.gov/ccgg/mbl/data.php`, Zonal → Northern / Southern Hemisphere, 1979–2025, text,
~100 KB). ⚠ Its form is **AJAX** and the direct URL was not recoverable from the served HTML —
**it needs a browser session.** That is the cheap next step (~1 h) and it converts the middle row
from arithmetic into measurement. **Circularity for that step:** NOAA's global mean **EXCLUDES**
Mauna Loa (so that side is genuinely independent) but **INCLUDES** South Pole. CarbonTracker
assimilates **both** and is fully circular here. A defensible σ floor for a station-representation
term is **~0.2 ppm** (Francey et al. 2019, ACP 19:14741) — **5× tighter than the current 1.0 ppm
prior**. ⛔ **Any change to this prior is an OBJECTIVE change** — freeze record §4.1: a ruling,
then a restamp of every mode.

## 6. NEXT — what is owed, in order
1. **Tier 1 of the review — the app says things that are FALSE.** All confirmed, none fixed:
   - **K1/K2** the Keeling takeaway (*"nothing was tuned to the shape of this curve"*,
     *"given only emissions"*). The CO₂ level and seasonal rows ARE objective rows;
     `gmst`/`sst_anom_*`/`enso`/`aod_*` are all prescribed.
   - **N8** review card 4 denies the volcanic mechanism — **`gamma_diff = 0.25` is LIVE**
     (`ccx_default_params()`; not fitted, not pinned) and the AOD→diffuse-light→NPP path runs.
     **My error, in the card I wrote.**
   - **U5/N6** *"No ocean circulation — diffusion only"* is stale at `hilda_csl3` (HILDA cold
     boxes, the pump, the layer-3 limb). The hemispheres interact through the **atmosphere**
     (`tau_ex`), not the deep ocean — that is the honest sentence. The tropical box was explored
     and **NOT adopted**.
   - **N12** card 8 conflates the **9 PINS** with the **named SHIMS** — two different lists, only
     `ent_seas_amp_SH` + the ENSO pair in both. Must show both, labeled.
   - **U1** `output$h_params` maps **38** parameter names through a **~22-name-era** `desc`/`unit`
     table, so most render **NA** (carries retired `beta`, `sigma_co2`; lacks every HILDA/pump/
     seasonal-ML/limb name).
   - **U2** `h_data` lists IGCC temperature under "What it is fitted to" — it is a **driver**.
     Needs a separate "what drives the model" box (IGCC T, ENSO, emissions, volcanic AOD, and
     **land-use change**, which is a driver too).
   - **C5** *"the land takes up carbon for exactly one reason"* — true of the **secular sink**,
     false as stated (the seasonal cycle is light-driven).
2. **Tier 2 — ~17 copy edits**, most supplied verbatim (O1, O2, K4, W1, W4, C4, F1, F3, N1, N2,
   N4, N9, N10, N11, U3, U4, U6). ⚠ **C4** (*"and, since 2026-09-01, in and out of the surface
   ocean"*) is a **dated code comment leaking into user-facing copy** — sweep for others.
3. **R3 the rename** — do it LAST of the edits; it touches the most files and the URL decision
   interacts with the Substack post.
4. **R4** — update the affiliation rule in `~/.claude/CLAUDE.md` to carry the professional /
   informal split.
5. **Tier 3 features, Marcus's priority order not yet given.** My ordering: **C2 the
   year-over-year CO₂ chart first** (it serves C1, C3 and card 4 at once, and is 08-29 spec ①b),
   then F2 (pulse partition panel — machinery exists; ⚠ must NOT share a caption with a label
   run, [[pulse_label_vs_perturb]], 2.8× apart at 100 yr), I1 (isotope hemisphere toggle),
   C6 (volcano/temperature switches — ⚠ needs **two** edits each per spec §3a, zero `aod_*` AND
   remove the component from `gmst`/`sst_anom_*`, or the thermal half keeps running),
   N7 (over/undershoot year analysis), W2 (the LUC sign-change date — **compute it, do not
   recall it**).
6. **Before the post:** set `APP_FEEDBACK_URL` (and `APP_REPO_URL`) in `app/global.R`; **re-time
   start-up on an IDLE machine**; check the host's active-hours and concurrency limits.

## 7. State to carry — non-obvious
- **The app is RUNNING** on `http://127.0.0.1:7788` (preview server, `ccx-app`). It was started
  before the R1 edits, so **it is serving pre-R1 code** — restart to see the fixed budget panel.
- ⚠ **`CarboTopeSubstack.docx` appeared in the repo root during this session and Word has it
  OPEN** (`~$rboTopeSubstack.docx` lock file). **Marcus's drafting — do not read, edit or commit
  it.** Both are untracked.
- ⚠ **Another process is writing to `FaIRtoFrEDI`.** `deliverables/egu_sprm/egu_sprm_memo_draft.docx`
  (08:54) and `postprocess_vehicle_npv_v145_fredi5.R` (07:29) changed DURING this session and
  **were not touched here** (all work was in `CarbonCycleEmulator`). A parallel session or Marcus
  working alongside. Left exactly as found.
- **`outputs/diagnostics/`**: one modified `.rds` + six untracked smoke files, mtimes 09-14→09-21,
  **all predating this session.** Not strays from this work; left alone.
- **SUITE: 4117 / 2** (`tests/run_tests.R`, contended). Both failures **PRE-EXISTING** and
  **REPORTED, NOT TOUCHED** (standing rule): `test-seas-lag-split.R:205` (the standing fixture
  error named in handoff (k)) and `test-u-hs-fitted.R:87` (the objective errors on a 1750–1800
  window because the ocean-gradient rows sit before their 1999/2002 epochs). Proof they are not
  ours: `tests/testthat/setup.R` sources only `R/` + `calibration/lib_run_inputs.R`, and neither
  test references `app/`. **Plus the new `test-review-cards.R`: 33 checks, 6 mutation tests.**
- **The launch config problem.** The harness resolves `.claude/launch.json` from the **SESSION
  ROOT** (standing rule: launch from `FaIRtoFrEDI/`), so a session there **cannot see**
  `CarbonCycleEmulator/.claude/launch.json`. Workarounds are in `app/DEPLOY.md`; a temporary
  entry in `FaIRtoFrEDI/.claude/launch.json` **must be reverted** (tracked file), and `cwd`
  outside the project root is **rejected** — use an absolute `setwd()` in `runtimeArgs`.
- **Traps met this session** (each with its fix in CHANGELOG): Shiny's `server.R` last-expression
  rule (§2.2); `is.function()` is **not** the property — the **arity** is, and the weaker check
  passed on the wrong function; `app/R/*.R` auto-source order depends on **locale collation**
  (`PAL` read at load time died with "object not found"); **ggplot captions CLIP, they do not
  wrap**, and the provenance prefix counts toward line 1's width; the 09-21 smoke number
  **424.37 is the GLOBAL annual mean** (1850 = 283.46, also global) — NH annual is 426.14, NH
  December 425.94, so a check reading the NH box reports a 1.6 ppm regression that is not there.
- **Frozen/scratch:** the `rep_dC` probe and the NOAA files are in the session scratchpad only
  (disposable). `calibration/lib_design_gates.R` is now a **runtime dependency of the app** and
  must ship — see `app/DEPLOY.md`.
