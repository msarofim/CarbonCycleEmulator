# Handoff 2026-09-30 (b): the land-alignment check is done → next arc: non-CO₂ land-sink drivers, imbalance allocation, app unfreeze

> **Session start.** Launch from `FaIRtoFrEDI/`, then `change_directory` here (CLAUDE.md). ⛔ Never use
> a bare `cd` in a Bash call; use `git -C` or absolute paths.
>
> **Read first:**
> 1. this file;
> 2. CHANGELOG **2026-09-30 (b)–(g)**;
> 3. memory:
>    - `ccx_rulings_0930_nonco2_imbalance_app.md` (the rulings below);
>    - `ccx_land_knobs_one_constraint_0930.md` (why the land is one constraint);
>    - `ccx_inert_box_kprior_r2_0930.md` (inert box, K prior, R2);
>    - all three are indexed in `INDEX_ccx_phi.md`;
> 4. `notes/r2_explained_2026-09-30.md`.
>
> The earlier handoff the same day is `notes/handoff_2026-09-30_inert_pool_sink.md`. All of its §4 items
> are resolved or carried below.

---

## 1. What this session did

Marcus's six-item list. Every result is in the CHANGELOG entry named.

| item | outcome | CHANGELOG |
|---|---|---|
| depth scope | **0–1 m, f 0.195** (the passive pool's 1500 GtC IS the 0–1 m inventory) | (b) |
| inert pool | built as a carve-out (c), then made a **STATE BOX** `soil_inert` (f) under label **`hilda_csl3v0kai`**. RothC IOM precedent verified | (c), (f) |
| "bring fertilisation down?" | shape into the band costs −5.6 / −14.5; amplitude −61 / −187. The amplitude is held by the **atmospheric CO₂ record**, and `gcb_land_sink` IMPROVES as it falls | (d) |
| 1. tighten the K prior | **not tightened**: the ESM spread (log-sd 0.26–0.37) brackets the ruled 0.35; a width that works needs ≤ 0.14–0.21 | (e) |
| 3. inert pool as a real component | state box, pinned in all spinup solves, in `land_C`; parity 1e-16; mutation-tested | (f) |
| 4. stock readouts | `ccx_stock_readout()`; Shi driver bug fixed; app copy flagged | (f) |
| 5. straightforward steps | R2 note + φ = 0 shelf; separability test INCONCLUSIVE | (f), (g) |
| 6. alignment check | scorecard + 12-arm screen. **Parametric alignment is exhausted; the routes are structural** | (g) |

**The finding that sets the next arc** (g):
- Every land knob trades against the others under ONE fixed historical uptake, which the CO₂ record
  demands (the ocean is on GCB).
- Soft literature constraints at the literature's own σ do not move the fit.
- q10 = 2 drives β_max to its bound (3.0).
- Freeing NPP₀ sends it UP.
- A gross photosynthesis loop is wanted small (`ra_ratio` ≈ 0.08, +3.2) but does not release NPP.
- ⇒ The model has ONE CO₂-proportional mechanism for the historical sink. That is what the rulings
  address.

## 2. Rulings (Marcus, 2026-09-30, verbatim)

> *"1) unfreeze the app. 2) definitely add non-CO2 contributors to carbon as in item 2. All 3 items seem
> defensible and relevant. 3) For the GCB budget imbalance: the calibration should have freedom to move
> it where it helps the model solve best. Then could the display panel use that calibration solution to
> assign it visually? 4) I still have hope that the NPP 70 vs. 56 might resolve with our fixes, but if it
> doesn't, then we need to keep it as a named tension."*

Also standing from this session:
- 0–1 m.
- Build the inert pool; make it a model component.
- Stock readouts must include every pool.
- The K prior may be tightened only if the science supports it (it does not).
- **The arm-A refit HOLDS until the carbon-pool questions are worked out**, i.e. until D2 and D3 are
  built and screened.

Referred to below as **D1–D4**, so as not to collide with "R2", the `rep_dC` decision.

## 3. The plan: the next arc, in order

### Step 0: the literature pass for D2 (subagent; receipts before any number enters code, hard rule 2)
For each driver, find:
- the functional form simple models use;
- a magnitude with its uncertainty;
- a dataset for the forcing, if there is one (hard rule 3: `data-raw/` script, URL, access date,
  checksum).

Candidates to verify (⚠ **my recollection, unverified**):
- Zhu et al. 2016 (Nat. Clim. Change), attribution of satellite greening: CO₂ ~70 %, N deposition ~9 %,
  climate ~8 %, land-cover ~4 %.
- CMIP6 input4MIPs nitrogen-deposition fields (historical + SSP), as the N-dep forcing.
- The 09-28 note already carries Walker 2021's apparent-vs-theory gap (β_app ≈ 1.2 vs 0.6). That is the
  observational case that the historical sink is not all physiology.

### Step 1: the D2 design note (prereg)

All three enter as **drivers into the existing pools, not new pools**. What distinguishes them is their
FUTURE.

**(a) N deposition.** An NPP multiplier `(1 + γ_N · ΔNdep_h(t))` with a new forcing column.
- It follows the N-emission scenario, not CO₂.
- Template: the diffuse-light term already in `npp <- npp0_h * capacity * fert * (1 + gdiff * aod_h)`
  (`R/model.R` ~2420, mirrored in `src/ccx_core.cpp`).
- Forcing columns are appended LAST: `CCX_FORCING_COLS` in `R/cpp.R` and `N_FORCING` in C++, which must
  move together.

**(b) Climate greening.** A temperature term on NPP. Today only respiration sees temperature (q10).
- ⚠ **Identifiability:** γ_T (NPP up with warming) and q10 (respiration up with warming) partly cancel.
  The seasonal drivers already tie q10 to the seasonal temperature amplitude (09-29 v B).
- Decide:
  - global or NH-only (greening is boreal-heavy);
  - whether it saturates or turns over at high temperature;
  - whether the SEASONAL path should see it. Probably not: keep it on the annual-mean GMST.

**(c) Recovery from past disturbance.** Two candidate forms:
- **(i) a 1750 land deficit.** Pools start below equilibrium and refill at their turnover times, giving
  a decaying sink.
  - Carbon must come from somewhere: a pre-1750 transient with pre-industrial land use, or an explicit
    deficit.
  - It breaks the "PI steady state" design assumption, so it needs a ruling.
  - ⚠ Prediction to test: the model's 1870–1920 growth error is already NEGATIVE (−0.05 to −0.10 ppm/yr,
    `ccx_land_sink_doors`), and an early extra sink makes it worse.
- **(ii) partial regrowth of cleared land** (`f_luc_perm` < 1).
  - ⛔ **Double-counting risk:** GCB's net E_LUC already includes regrowth on abandoned land. Only
    recovery NOT in bookkeeping (demography, fire suppression, natural-disturbance legacies) belongs
    here.

**Pre-registered predictions** (write them in the prereg before any run):
- fertilisation amplitude falls;
- the post-2100 land sink falls toward Koven;
- q10 can rise;
- modern NPP: (a) and (b) RAISE NPP, while (c) does not. ⇒ **D4's hope rests mostly on (c)**, and on the
  fertilisation amplitude falling.

### Step 2: build D2
- Structure labels chained from `hilda_csl3v0kai`: one per driver, plus all three together.
- Parameters default to OFF, so every registered file stays bit-exact.
- R and C++ with parity tests (hard rule 1), conservation tests, cited constants in `R/constants.R`,
  and a DESIGN.md spec change.
- Follow the `test-soil-inert.R` pattern:
  - off is bit-exact;
  - an equivalence where one exists;
  - parity;
  - conservation;
  - mutation-test every guard.

### Step 3: D3, the imbalance allocation (an OBJECTIVE CHANGE, #13 → #14, authorised by D3)

**Today.** `R/likelihood.R` ~2424 scores ANNUAL model sinks:
- `gcb_ocean_sink` against GCB's ocean sink, σ `LIK_GCB_OCEAN_SD`;
- `gcb_land_sink` against GCB's land sink, σ `LIK_GCB_LAND_SD × LIK_LAND_SINK_INFLATE`, on the residual
  convention (model land flux + E_LUC).

GCB's budget does not close (imbalance +0.54 GtC/yr mean 1959–2024). The model's budget does, so the fit
is forced to put the imbalance somewhere, and the σ's decide where. It currently lands almost all in the
land (09-24 identity, [[ccx_land_sink_is_gcb_imbalance]]; at arm A, 09-30 c).

**Proposed form.**
- Fitted shares on the simplex: `s_land`, `s_ocean` (and an emissions share?), with targets
  `GCB_land + s_land · Imb(t)` and `GCB_ocean + s_ocean · Imb(t)`.
- Flat priors, since D3 says "where it helps the model solve best".
- The shares are bounded, so the rows can never absorb more than GCB's own imbalance.

**Choices to put to Marcus:**
- the RAW annual imbalance (noisy: 2024 is −1.69; decadal +0.59 → −0.07) or a smoothed one;
- constant shares or time-varying;
- ⚠ an emissions share is CONFOUNDED with `luc_scale`, which already moves E_LUC. Either drop the
  emissions share or replace `luc_scale` with it;
- GCB's cement-carbonation sink (+0.09, which the model lacks): fold it in or keep it separate.

**The display (D3's question). Yes.**
- The existing panel ("Is the model's land sink too high?", `plot_land_sink_imbalance()` in
  `app/R/plots.R` ~663, gated by `tests/testthat/test-imbalance-panel.R`) today draws an **EXTREME** band:
  GCB's land sink plus ALL of the imbalance.
- It also already computes the 5-term identity (`app_imbalance_identity()`).
- With D3 it can draw `GCB_land + s_land · Imb(t)` (and the ocean equivalent) as **"this calibration's
  attribution"**. That is the fitted solution, labelled as the MODEL's attribution, not GCB's and not an
  uncertainty.
- `IMB_BAND_NOTE` / `IMB_BAND_SHORT` and the test's wording assertions change with it.
- Even before D3, the identity gives the model's IMPLIED allocation and could be drawn now.

### Step 4: screen, then refit
- **Screen.** Extend `calibration/diag_alignment_screen.R` (arms, soft constraints, scorecard, futures;
  env `AS_ONLY`, `AS_TAG_SUFFIX`, `AS_SMOKE`) with the D2 labels and the D3 objective.
  - The scorecard is the acceptance view: pools, NPP, GPP, sinks vs GCB, soil Δ¹⁴C vs Shi, the
    fertilisation responses (Keenan, 400→564, 2×, 4×), q10, and the Koven windows.
- **Then the refit** on the new label and objective #14.
  - **Consider Torch first** (standing rule: say the verdict out loud; Torch is free as of 09-26, but ask
    first).
  - Restamp every mode (freeze record §4.1).
- ⚠ **Price structural choices only at a full refit.** The R2 shape-fixed test (g) showed that a narrow
  (10-name) rebalance can move the future the OPPOSITE way from a full (28-name) one.

### Step 5: D4, NPP
- At the refit, read modern NPP against 56.1 ± 7.75 (`data/obs_npp_modern_target.rds`). Today it is 69.6
  (z +1.75).
- If it is not resolved, record it as a **named tension** in the new assessment.
- What is known: it is held by the NH bomb-¹⁴C row, through LITTER into the decadal soil pools (09-29 k).
  NPP₀ left free goes UP (g), and the gross loop does not help (g).

### Step 6: D1, the app
- The app is UNFROZEN. `v1.0-hilda29l` stays as the record tag.
- After the refit, re-point the app at the new mode:
  - `app/global.R` must use the mode's own spinup (the 09-21 lesson).
  - The stock footnote picks up the inert pool automatically (`land_C` is total).
  - The box-diagram soil label already names it (`ccx_inert_on()`).
- **Copy edits now allowed** (Marcus drafts or approves wording; app text is for undergrads):
  - `app/ui.R` ~623 "a two-pool land biosphere" and ~664 "Two land pools". WRONG since 2026-08-12:
    there are four dynamic pools plus the inert one.
  - The "Under the hood" limits list gains the non-CO₂ drivers.
- The D3 imbalance panel (step 3).
- A new assessment / freeze record at the end.

## 4. Still open (not ruled)
- **R2** (`rep_dC` prior): the menu is in `notes/r2_explained_2026-09-30.md` §6.
  - (a) keep it as a named shim;
  - (c) σ 0.2 centred on 0.776: `rep_dC` 1.74 for −16.0.
  - Quote its future only from a full refit.
- **`ra_ratio` ≈ 0.08:** free it at the refit, under the AR6-GPP cap (`AS_GPP_PI` 113)?
  +3.2 log-units; otherwise inert.
- **A century-scale q10 split:** worth it only together with D2. On its own it trades against
  fertilisation (J5/J6).
- **The K prior stays 0.35** (e).
- **Carried from earlier handoffs:**
  - the prereg P1 wording;
  - the `app/global.R` menu descriptors;
  - the untested `f_luc_wood` / `kz_deep_frac` findings;
  - memory housekeeping:
    - list `INDEX_ccx_phi.md` in `FaIRtoFrEDI/CLAUDE.md` (needs approval);
    - root `MEMORY.md` is over its soft budget;
    - ⚠ `INDEX_ccx_app.md` is now **14,131 B**, just over its 14 KB soft budget. Split it.

## 5. Files (CCX `main`, all pushed; 29 commits since `409eab4` + this handoff)

**Model code** (`582456a`, `c187deb`, `2ff8918`):
- `R/model.R`:
  - `soil_inert_frac` (default 0);
  - `ccx_litter_slow_eff()`, `ccx_soil_inert_stock()`, `ccx_inert_on()`, `ccx_inert_idx()`,
    `ccx_inert_c13()`;
  - `CCX_LAND_INERT`;
  - the box-name / index / aux threading.
- `R/spinup.R`: the pins, `soil_inert_C_GtC`, `ccx_stock_readout()`.
- `R/periodic_spinup.R`: the pins.
- `R/cpp.R`: the carve-out resolution, `inert_on`, box names.
- `R/fluxes.R`: class "soil".
- `R/forcing.R`: a label.
- `R/calibrate.R`: label `hilda_csl3v0kai`.
- `R/constants.R`: `SOIL_INERT_FRAC`.
- `src/ccx_core.cpp`: `ISI`, the land and ocean sums.
- `app/R/plots.R`: the diagram label.
- `DESIGN.md` §3.3.

**Tests:**
- `tests/testthat/test-soil-inert.R` (12 tests / 103 expectations);
- ledger extensions in `test-tr-box.R`, `test-constants-batch.R` and `test-struct-v0.R`
  (PRIOR_ON, per the 09-29 pattern).
- **Last full suite:** `outputs/diagnostics/suite_20260930_post7f48dd9.log`, only the named red
  (`test-mode-file.R:323`). No `R/` or `src/` change since then.

**Drivers** (`calibration/`), all committed before running:
- `diag_inert_pool_build_check.R` (v2)
- `diag_fert_profile.R`
- `diag_budget_armA.R`
- `diag_fert_k_prior_width.R`
- `diag_rep_dc_shelf_v0k.R`
- `diag_alignment_screen.R`
- `diag_r2_shape_fixed.R`

Extended:
- `diag_land_sink_trajectory.R` (`LS_FERT_PROFILE`);
- `diag_soil_d14c_shi2020.R` (reads the inert box).

**Outputs** (`outputs/diagnostics/*_20260930.*`):
- `inert_pool_build_check{,_v2}`
- `fert_profile_fixedstock`
- `land_sink_trajectory_fertprof` (+ `_annual`)
- `budget_armA`
- `fert_k_prior_width`
- `rep_dc_shelf_v0k`
- `alignment_screen{,_q10,_gross}`
- `r2_shape_fixed`
- the two suite logs

**Notes:** `notes/r2_explained_2026-09-30.md`, and this file.

## 6. Non-obvious state and traps

**Inert state box.**
- Label `hilda_csl3v0kai`: `soil_inert` is appended LAST per hemisphere and is ABSENT when off.
- ⛔ **The C++ out matrix treats IML..NPH as ocean.** Any future box appended to a hemisphere block must
  be excluded there. That loop now stops at `ISI`.
- ⛔ **A zero-flux box makes every spinup operator singular.** It must be pinned in:
  - `ccx_c12_steady_conveyor()`;
  - the aseasonal ¹³C solve;
  - the periodic Newton;
  - the periodic ¹³C monodromy.
- `ccx_flux_boxclass()` refuses unclassified boxes.

**`land_C` convention.**
- Under `kai`, `land_C` is TOTAL land, including 292 GtC inert. Differences are unaffected.
- Comparisons to Naegler & Levin's 2200 PgC (their model config) or land-use Δ¹⁴C bookkeeping should
  subtract `soil_inert`.
- Land ×PI multiples use TOTAL land.

**Screen controls and identities.**
- The alignment screen's control is the (v) D carve-out re-fit (proxy vector), rescored under `kai`:
  Δ 4.9e-4. Its SSP5-8.5 2300 CO₂ is **1406.71**.
- Arm A (`ka`) fixed-stock τ-500 control: 2300 = **1387.8816**. v0k: **1388.28**.

**Screen behaviour to remember.**
- Soft penalties at the literature σ are too weak to move this record. To change the fit, change the
  structure or the objective (D2, D3).
- q10 = 2 rails β_max at its hard bound of 3.0 (J5). If a new structure still rails β_max, inspect the
  bound before trusting the fit.

**State of the machine and tree.**
- **Nothing is running.**
- `outputs/diagnostics/smoke/` holds the untracked smoke outputs (not committed, by convention).
- `carbotopecomment.9.26.26.docx` is untracked and belongs to Marcus. Leave it alone.
- Machine contention: other sessions run heavy Python/Julia jobs at times (load reached ~200 today).
  Check `uptime` before a long run, and pin BLAS threads.
