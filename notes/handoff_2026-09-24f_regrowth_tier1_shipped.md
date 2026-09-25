# Handoff — 2026-09-24 (f). **REGROWTH TIER 1 IS SHIPPED, END TO END.** Acquired, built, gated, and drawn in the app; three rulings taken from Marcus; pushed to `main` (`216a484`). **The next job is the GCB IMBALANCE-BAND PANEL** — handoff (e) item 3, and it is now the strongest remaining app addition.

> ⚠ **IF YOU ARE A FRESH SESSION: paths here are relative to
> `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, which is NOT your cwd.** Sessions launch
> from `FaIRtoFrEDI/` (the memory keyspace follows the launch cwd), so a bare `notes/...` will not
> resolve. Prefix with the absolute path, or `cd` there.
>
> **Read first, in this order:** CHANGELOG **09-24 (m)** and **(n)** · then **§1** and **§4**.
> ⚠ `~/.claude/CLAUDE.md` applies. ⚠ `MEMORY.md` is the auto-loaded ROOT ONLY. Read
> **`INDEX_ccx_ref.md`** (land/LUC) and **`INDEX_ccx_app.md`** (the app as a product) before
> answering anything here. The Tier-1 facts are in **`ccx_luc_gross_split.md`**.

---

## 1. ⭐⭐⭐ WHAT SHIPPED, AND THE THREE RULINGS BEHIND IT

Handoff (e) said Tier 1 was free because CCX already contains forest regrowth, netted invisibly
inside GCB's prescribed E_LUC. **That premise held and is now gated**: GCB 2025's Land-Use Change
Emissions sheet `Net` column and the `luc` column the model burns are the **same numbers**
(max |diff| **exactly 0.0e+00**), and `luc_scale × (gross + regrowth)` rebuilds the burnt `E_luc`
to **2.2e-16**. ⇒ arithmetic on a forcing column. **No refit. Objective #13 untouched.**

### Marcus's three rulings (2026-09-24), each a flagged methodological choice
| | ruling | the thing it beat |
|---|---|---|
| **R1** | convention = **GCB 2025's "forest regrowth (total)"** | OSCAR v3.1's `E_negative`, **3.15×** larger on the same model and years |
| **R2** | pre-1959 = **OSCAR's share SHAPE rescaled to GCB's LEVEL** over the window adjacent to the join | reporting 1959+ only; a flat hold (the 08-13 bug) |
| **R3** | future = **a prescribed exponential decay** | inheriting it from the scenarios, which does not work |

### ⛔⛔ TWO FACTS HANDOFF (e) DID NOT KNOW. Do not re-derive them the wrong way.
1. **"Regrowth" is CONVENTION-DEPENDENT BY A FACTOR OF THREE.** Same model, same years
   (1959–2018): OSCAR v3.1's `E_negative` **−3.122** vs GCB 2025's OSCAR "forest regrowth (total)"
   **−0.992**. GCB reports *wood harvest & other forest management* **NET of its own post-harvest
   regrowth**, so rotation regrowth never reaches GCB's regrowth column; `E_negative` counts every
   negative flux. **Not a vintage difference.** Same class as the project's 32 %
   [[ccx_app_luc_budget_convention]] bug — **name the convention on every reported number.**
2. **THE FUTURE DECAY DOES NOT FALL OUT FOR FREE.** (e)'s design note said it would, "as LUC
   emissions go to zero in the SSPs". Measured, the prescribed **net** LUC does not go to zero — it
   goes **NEGATIVE** at 2100 in four of five SSPs (ssp119 −0.65, ssp126 −0.79, ssp245 −1.31,
   ssp585 −0.42; only ssp370 stays positive at +0.73). In bookkeeping accounting that is **gross
   regrowth OVERTAKING gross clearing**, the opposite of a decaying regrowth term.

### ⚠ Coverage, and it is Tier 1's real limit
The model burns **237.6 GtC** of net LUC over 1750–2024 at `luc_scale` 0.8214. The published split
covers **39 %** of it; **209 of 275 years (76 %) have none**, which is what R2 exists to fill.
**43 % of the cumulative regrowth is observed, 57 % is R2's construction** — every year carries a
source label and `test-luc-gross-split.R` asserts the labels.

### ⚠⚠ AND THE WHOLE NUMBER IS ASSERTED, NOT MEASURED
Imported from GCB's bookkeeping models. **09-24 (h) showed this record cannot see the split**, and
Tier 1 does not change that. The app panel says so in its own copy, in the plot caption, and in an
info box; `test-luc-regrowth-panel.R` fails if that sentence disappears.

---

## 2. ⭐⭐ R3's TIMESCALE IS FITTED — and its error bar is the part worth keeping

A one-pole recursive kernel mapping the gross source onto GCB's observed regrowth:
**τ = 19.50 yr**, r **+0.967** raw and **+0.733 detrended** (2/√n = 0.246); SSE **13.7×** the
minimum at τ = 5 and **2.1×** at 60, so **τ is identified, not flat**.

⛔⛔ **The naive bracket is 5× too tight.** Residuals are almost perfectly red — **lag-1 ρ = 0.905
⇒ n_eff = 3.3 of n = 66** — so SSE × (1+1/n) gives **19.00–20.25 yr**, a 1.25-yr precision on a
66-point record. **Corrected: 17.25–23.75 yr**, and that is what is stored and quoted.
⚠ The detrended r alone peaks **shorter** (~10 yr); the level information pulls longer, which is
why the bracket is ~17–24 rather than 19–20.
⚠ **`tau_wood` = 20 yr is a COINCIDENCE, NOT A VALIDATION** — this τ is fitted to GCB's bookkeeping
models and says nothing about CCX's wood pool. ⚠ Nor is it independent of R2: the pre-1959 history
it convolves came from OSCAR's share.

⭐ **An FIR convolution will NOT work here** and cost a debugging cycle: a kernel long enough for
τ = 60 yr is longer than the 275-year series, and `stats::filter(method="convolution")` then
returns NA across the entire fit window. The one-pole recursion needs no history — initialised at
its own equilibrium for the first year's input, the initialisation error is gone many τ before
1959.

---

## 3. What was built (all pushed, `main` at `216a484`)

| file | what it is |
|---|---|
| `data-raw/download_gcb_luc_components.R` | acquires 4 files (3-model mean + BLUE/OSCAR/LUCE); **refuses to record a file whose components do not reproduce its Net** |
| `calibration/diag_luc_gross_split.R` | 3 gates + the convention/coverage/futures evidence |
| `data-raw/build_luc_gross_split.R` | → `data/forcing_luc_gross_split.rds` |
| `tests/testthat/test-luc-gross-split.R` | 28 assertions, mutation-tested 9 ways |
| `tests/testthat/test-luc-regrowth-panel.R` | 27 static assertions on the panel wiring |
| `tools/palette_check.py` | the dichromat checker (e) said to re-use and that was never committed |
| app: `global.R`, `ui.R`, `server.R`, `R/plots.R` | the panel |

⚠ **The per-model LUC files OMIT the peat column but their `Net` INCLUDES peat** — GCB adds ONE
common peat estimate to each model. Test the closure without adding it back and the residual is up
to **0.72 GtC/yr**, which is the peat term, not a broken sheet. Cost one iteration; the gate now
does it correctly.

⚠ **`luc_scale` is NOT baked into the product.** It is a FITTED name, so the rds is stored unscaled
and `app/global.R` multiplies **all three columns**. Scaling one half breaks the closure by
**0.575 GtC/yr** — that is a gated mutation in two places.

⚠ **`takeaway()` and `info_box()` MOVED from `app/ui.R` to `app/global.R`.** The regrowth section is
assembled in `server.R` through `uiOutput`, and a helper defined at the top level of `ui.R` is not
reliably in scope inside the server function.

### The numbers, for anyone quoting them
GCB 2025 3-model mean, GtC/yr: regrowth **−1.02** (1959–2024), **−1.30** (2015–24); offsets **38 %**
of the gross source over the record, **49 %** recently; **3-model spread 38 % of the mean**
(OSCAR −1.49 / BLUE −1.41 / LUCE −0.99). Cumulative 1750–2024 **gross +444.2, regrowth −154.9,
net +289.3 GtC**. Panel readouts (2015–24, `luc_scale` applied): **2.19 / −1.07 / 1.13**.
⭐ Over 1959–2024 the net flux moved **−0.05** GtC/yr per decade, gross clearing **+0.01**, regrowth
**+0.06** ⇒ **the regrowth moved, not the clearing** — and the panel computes that direction rather
than asserting it.

---

## 4. ~~THE NEXT JOB~~ ✅ **DONE, SAME SESSION** — the GCB IMBALANCE-BAND PANEL

> ✅ **SHIPPED 2026-09-24 (o), commit `8d59aef`, pushed.** See CHANGELOG (o). ⛔⛔ **Building it
> found the unfixed half of [[ccx_gcb_land]]**: the app diffed stock ANNUAL MEANS where the
> objective interpolates to CALENDAR-YEAR boundaries — a HALF-YEAR OFFSET, fixed in the objective
> on 08-14 (`304386a`) and never in the app. Silent. The land bar moved **3.06 → 3.05** and the
> decade table now reproduces (k)'s figure row for row. ⭐ **It was found by gating two
> IMPLEMENTATIONS against each other** — a stored-number gate would have ratified either.
> ⇒ [[app_sink_half_year_offset]], [[subtitles_clip_too]]. **Remaining work is §6 items 2–4.**
> The section below is kept as the build record.

## 4. (build record) THE GCB IMBALANCE-BAND PANEL

Handoff (e) item 3, and the content is already measured — this is a drawing job on a settled
result, not a new investigation.

**What it says.** 09-24 (i) established that the model's **+0.32 GtC/yr** land-sink excess is an
**exact identity** (closes 3e-14): GCB's own unclosed **imbalance +0.54**, plus the **cement sink
the model lacks +0.09**, less the fitted **`luc_scale` −0.30**. **Nothing unexplained.**
⛔⛔ **GCB's land sink is NOT the residual — the IMBALANCE is** (tested; the land sink is an
independent DGVM estimate). ⛔ **The imbalance is POSITIVE**, so GCB's own sinks are too small to
close its budget and a **larger** model sink moves **TOWARD** closure. **Never read "above GCB" as
"too high" without the sign.**

**Where it goes.** Same tab as the regrowth panel — *Where does the carbon go?* — under
`output$w_gcb`'s two bars, which is exactly where a reader who has just seen "this model 3.06 vs
GCB 2.47" will ask why. The regrowth panel is directly below; the two pair naturally (one says
where the land-use number came from, the other says how much slack the comparison has).

**What already exists to reuse.** `calibration/fig_land_sink_vs_gcb.R` draws it for print, with
GCB's imbalance as a band. **Reuse its content, not its parameters**: it uses a **5-yr** smoother
(Marcus's request for that figure) while the app's constant is **`APP_LUC_SMOOTH_YR` = 11**.
⛔ **Both conventions must be kept apart** — panel A is the RESIDUAL SINK (LUC outside, what GCB
publishes and gate 7 scores), panel B is the NET LAND FLUX (LUC inside, the one that crosses zero).
Conflating them is the project's own 32 % bug.

**The band is an EXTREME ATTRIBUTION** (all unplaced carbon assigned to land) and must be captioned
as one. Containment is **measured, not eyeballed**: **4 of 7 decades inside** — 1970s misses by
0.01 (immaterial), 1980s by 0.20, **2020–24 by 1.04, the one real excursion**, consistent with
09-24 (i)/(j) which flagged that window and declined to attribute it.

**Suggested order:** (1) a plot function in `app/R/plots.R` taking the app's own smoother constant;
(2) the section in `ui.R` + `server.R` with a takeaway whose decade containment is **computed**;
(3) a static gate like `test-luc-regrowth-panel.R` — the failure modes are identical (orphaned
renderer, wrong convention, the "extreme attribution" caption disappearing).

---

## 5. Non-obvious state

- **Branches.** CCX `main` at **`216a484`, PUSHED** to `msarofim/CarbonCycleEmulator` (private).
  FaIRtoFrEDI still on **`heat-ed-morbidity`** at `b1889af`, **NOT pushed** — the `calibration_v160`
  unit fix is still sitting on a branch unrelated to its topic (handoff (e) §3).
- ⚠ **MARCUS MAY BE EDITING IN PARALLEL.** `deliverables/egu_sprm/*` in **FaIRtoFrEDI** were dirty
  as of (e) and are **HIS**. ⛔ Per [[marcus_edits_docx_directly]], **diff any returned `.docx`
  against HEAD and pull his prose into the SOURCE before rebuilding.**
- **Suite.** Filter `climate|app|review|driver|growth|future|mechanisms|luc|forcing|stability`:
  **573 / 0** (was 518; the delta is exactly the 55 new assertions), 25 warnings, all the
  pre-existing 1900-start transient. ⛔ **A green filter is not a green suite.**
  ⚠ **The reds are now THREE, not four**: `test-mode-file.R` (1) and `test-overlay-idiom-lint.R` (2)
  — **checked to be unaffected by this session**, the lint's `CCX_PARAM_NAMES` idiom appears in none
  of the new files. **`test-seas-lag-split.R` now passes 35/0**; (e)'s "four known reds" is stale.
- ⛔ **`tools/palette_check.py` DOES NOT REPRODUCE (k)'s DICHROMAT NUMBERS.** It matches (k)'s
  **normal** OKLab ΔE for the shipped figure pair **exactly (31.3)** and gives protan **7.4** where
  (k) recorded **13.5** — so **(k)'s claim that `calibration/fig_land_sink_vs_gcb.R`'s pair clears
  the ≥8 target is currently unreproducible**. The tool self-checks (LMS matrices are exact
  inverses; neutrals invariant under all three dichromacies). `node` is absent, so the skill's own
  validator cannot arbitrate. **The figure was NOT changed on an unreproduced disagreement** —
  flagged for Marcus, and the new panel's colours were chosen with margin (worst pair **10.9**) so
  nothing turns on it. ⇒ [[palette_check_unreproduced]]. **The imbalance panel will hit this same
  question** — pick with margin and score it.
- ✅ **RESOLVED 09-24 (p) — existing copy (was flagged).** `output$w_luc_note` credits the land's crossing to
  "CO₂ fertilisation **and forest regrowth on former farmland**". With Tier 1 drawn directly below
  it, that is visibly imprecise: **regrowth is inside the LUC INPUT, not inside the natural land
  sink**, and fertilisation is the model's only long-term land-uptake term
  ([[ccx_land_sink_single_term]]). Copy is Marcus's; the suggestion is to end the sentence at
  "CO₂ fertilisation".
- **Two app instances were left running**: PID 61815 on **:7788** (pre-dates this session, Marcus's,
  OLD code) and one on **:7789** carrying the new panel. ⚠ `preview_start` picks up a *different*
  `launch.json` than CCX's — it started `docket-site` on 8765. Launch the app from Bash instead.
- **Machine was IDLE** this session (load ~1.9), unlike (e)'s 6.5–9.6. Still read `uptime` first.
- **Still unmerged, still owed**: `emissions-interp-constant` (`35f38dc`) rides with the next refit.
  **Tier 1 did not trigger one.**
- **Unchanged deploy blockers, all Marcus's**: the two `SET-BEFORE-DEPLOY` URLs (⚠ update
  `test-review-cards.R`, don't delete it), a start-up re-time on an **IDLE** machine, the hosting
  plan's limits. W4's ratchet entry still unratified.

## 6. Recommended order for the next session
1. ~~The imbalance-band panel~~ ✅ **DONE 09-24 (o)**, `8d59aef`; its open text-slot item
   ✅ **DONE 09-25 (b)**, `65595ef`. ⛔⛔ **The unchecked slots were FINE; the CAPTIONS were broken**
   — `strwrap(150)` counts characters, clipping is pixels, and the two HALF-width panels had been
   clipping at every viewport width. ([[subtitles_clip_too]])
2. ~~The `w_luc_note` copy fix~~ ✅ **DONE 09-24 (p)**, `b1c39d8`. It was two corrections, not one:
   the regrowth attribution AND "larger sink than GCB" left standing as an unqualified fault.
   ⭐ **Adding a panel falsified copy two charts above it** — re-read the neighbours when a chart lands.
3. ~~Resolve the palette discrepancy~~ ✅ **DONE 09-25**, `c55eaba`. Re-stepped to `#C4315F` /
   `#16345A` (protan 12.6), the MINIMAL change clearing a floor of 12; the receipt is now a GATE
   (`test-figure-palette.R`). ⛔ **Which implementation is right is STILL UNKNOWN** — the pair was
   moved so the answer stops mattering for this figure. ⚠ Neither colour could be held fixed.
4. ⛔⛔ **`b1889af` IS ONLY A CHANGELOG ENTRY** — checked 09-25, and this corrects handoff (e) §3
   and §5 (and my own summary of them). The unit fix's CODE is in **`ec495b6`**, a commit titled
   *"Convert the Author Bio to third person"*, which carries 54 lines of
   `scripts/build_emissions_v160_ssp245.py` alongside the bio edit. **Cherry-picking `b1889af`
   alone would move documentation for code that is not there.** And the builder does not exist on
   `main` at all (315 lines, whole file new, from `ec046c2`). ⚠ `scripts/fair_units.py` is on
   **`claude/calib160-migration`** only. ⇒ this is a 3-commit untangle on the trunk, not a
   cherry-pick; Marcus's call.
