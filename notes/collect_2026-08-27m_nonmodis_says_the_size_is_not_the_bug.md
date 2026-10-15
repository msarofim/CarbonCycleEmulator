# Collect 2026-08-27m — **TWO NON-MODIS PRODUCTS SAY THE SH PRODUCTIVITY SIZE SHOULD GO *UP*,
# AND THE MISSING PIECE IS CANCELLATION**
# SH land cancels **74.9 %** of its gross swing before it reaches the atmosphere. The NH cancels 31.8 %.

**Marcus's rulings executed (2026-08-27):** re-derive off a NON-MODIS product — both a process-model
track and an inversion track, model-derivation and circularity accepted for a pedagogical tool; score
the inversion BOTH ways side by side; and **measure through both bases before choosing one**.

**⚠ THIS NOTE CORRECTS TWO NUMBERS IN 27l.** See sec.1. The qualitative reading survives and is
stronger; the headline figure was window-dependent and should not have been quoted bare.

---

## 0. WHAT WAS BUILT

Neither named product was fetchable as named — **CAMS** needs a Copernicus ADS account key (none on
this machine, and I cannot create accounts), **TRENDY** is access-by-request and its site does not
resolve. Substitutes approved by Marcus:

| track | product | why | ⚠ |
|---|---|---|---|
| process | **CMIP6 `npp`, Lmon historical**, 1995–2014, 34 models, one member each | same class as TRENDY, **no satellite in the chain**, and the ONLY candidate that **IS NPP** rather than a GPP proxy or a net flux | **MODELS, NOT OBSERVATIONS** |
| inversion | **NOAA CarbonTracker CT2022**, monthly 1×1, 2000–2020 | same class as CAMS, open | **CIRCULAR** (constrained by MLO+SPO) and it is **NEE, not NPP** |

New: `data-raw/build_cmip6_npp_seasonal_shape.py`, `data-raw/build_carbontracker_land_shape.py`,
`data-raw/npz_to_csv_seasonal.py`, `calibration/diag_sh_pair_nonmodis.R`,
`calibration/diag_mod17_monthly_control.R`. Both downloads are in `MANIFEST.csv` with SHA-256 and
with their weaknesses written into the `notes` column, not just into this file.

**Two gates fired during the build and both would have corrupted the answer silently:**
- **`SAM0-UNICON` returns NEGATIVE NPP** (−29.0/−19.7 PgC/yr). Under a unit-mean normalization that
  inverts the model's entire seasonal shape. Now **rejected loudly**, not filtered downstream.
- **`UKESM1-0-LL` died on `2014-12-31`** — a **360-day calendar has no 31 December**. That is a
  calendar error, not a data gap, and it would have deleted a major structural family from the
  ensemble while looking like a legitimate skip.

## 1. ⚠ THE WINDOW WAS NOT INNOCENT — 27l's HEADLINE NUMBER WAS 8-DAY-GRID-SPECIFIC

CMIP6 is monthly; MOD17 is 8-daily. Product and window were **confounded**, so
`diag_mod17_monthly_control.R` pushed MOD17 through the *identical monthly* pipeline
(aggregation duration-weighted, not nearest-midpoint — ~13 % of composites straddle a month).
[[like_for_like_forcing]]

| SH_psnnet | swing | A range | argmin |
|---|---|---|---|
| MOD17, **8-day** (27l) | **1.0 pp** | 0.97 → 0.30 (3.2×) | ~−40, shallow |
| MOD17, **monthly** | **2.91 pp** | 1.01 → 0.19 (**5.26×**) | **−60 = grid edge** |
| CMIP6, **monthly** | 3.25 pp | 1.90 → 0.35 (**5.41×**) | −50 |

**⇒ MOD17-monthly resembles CMIP6-monthly far more than it resembles MOD17-8day.** Most of the
apparent "the non-MODIS product disagrees in the SH" is the **WINDOW**. Without this control I would
have reported a product difference that was mostly a smoothing artifact.

**CORRECTIONS TO 27l:** (a) the SH swing "1.0 percentage point" is an 8-day-grid figure — on matched
monthly windows it is **2.9 pp**; (b) the degeneracy is **worse** than the 3.2× reported, not better —
**5.3×** at matched windows. **The qualitative finding STANDS and hardens: the SH argmin runs to the
grid edge at −60 and is still falling, so on the insolation basis the SH latitude has NO INTERIOR
OPTIMUM AT ALL**, against the NH's clean interior 75.

## 2. THE NH POWER CHECK PASSES — AND INDEPENDENTLY CONFIRMS TWO SHIPPED CONSTANTS

A flat SH row is worth nothing unless the same pipeline finds the NH sharp. [[no_power_null]]

| NH | argmin | swing | fitted A at 75 |
|---|---|---|---|
| MOD17 8-day (`psnnet`) | **75** | 5.2 pp | 0.50 |
| MOD17 monthly (`psnnet`) | **75** | 6.29 pp | 0.50 |
| **CMIP6 monthly** | **75** | 5.22 pp | 0.60 |

**⇒ `CCX_SEAS_PHI_EFF['NH'] = 75` and `SEAS_NPP_AMP_NH = 0.4969` are CONFIRMED by a product family
with no satellite in it.** The strongest independent support either constant has had. The check was
built to validate the method; it also validated the NH pair.

## 3. THE ANSWER: AT A FIXED SHAPE, THE NON-MODIS PRODUCT WANTS THE SIZE *BIGGER*

At the shipped `CCX_SEAS_PHI_EFF['SH'] = −30`, on **matched monthly windows**:

| | fitted A at phi = −30 |
|---|---|
| MOD17 monthly `psnnet` | **0.50** (= the shipped 0.5027; window-insensitive) |
| **CMIP6 npp, 34-model median** | **0.94**  (IQR 0.71–1.22) |

**⇒ a genuine ~1.9× PRODUCT disagreement at fixed shape — LARGER than the 1.4× GPP/PsnNet bracket
that 27i, 27j and decision (ii) were all about — and it points the OPPOSITE way from the arc.**

This is now the **second** independent line pointing up. 27l already had the first: the **measured**
SH NPP centroid −15.12 gives A ≈ 0.97. **Both say the SH productivity swing should be roughly double
the shipped constant, while the atmosphere says the model's SH land signal is already 1.33–1.92× too
BIG.** Those cannot both be closed by the size.

**⇒ `SEAS_NPP_AMP_SH` IS NOT THE BUG, AND 27j's GPP MOVE WAS COMPENSATING FOR SOMETHING ELSE.**

## 4. WHAT THE INVERSION ADDS — THE CANCELLATION, AND IT IS THE MISSING PIECE

Scored as Marcus directed: the **net-flux column** first, in its own units, not mixed with the
productivity re-derivation.

| seasonal peak-to-peak, PgC/yr | NH | SH |
|---|---|---|
| **CMIP6 NPP** (gross uptake swing), median | 61.5 (IQR 56.1–71.0) | 15.0 (IQR 12.3–20.6) |
| **CT2022 NEE** (net swing reaching the atmosphere) | 42.0 | **3.8** |
| **net / gross** | **0.682** | **0.251** |

**⇒ SH LAND CANCELS 74.9 % OF ITS GROSS PRODUCTIVITY SWING BEFORE THE ATMOSPHERE SEES IT.
THE NH CANCELS 31.8 %. A 2.72× HEMISPHERIC ASYMMETRY IN THE CANCELLATION ITSELF.**

The physics is the one already written in `R/constants.R`: SH productivity is tropical and
**water-driven**, so photosynthesis and heterotrophic respiration are driven by the SAME wet season
and are nearly IN PHASE — NEP is a small residual of two large in-phase fluxes. The NH's boreal
cycle is light- and temperature-limited, photosynthesis and respiration separate in time, and far
less cancels.

**⇒ THE COHERENT STORY.** Gross SH productivity should be ~2× the model's constant; 75 % of it
should cancel; the model instead carries roughly half the gross and **under-cancels**, and lands
1.33–1.92× too big at SPO. **Shrinking the gross (27j's GPP move) mimics cancellation with the
wrong knob** — which is exactly why it needed a value the provenance forbids.

**AND THERE IS A NAMED SUSPECT ALREADY ON THE BOOKS.** `seas_T_amp_SH` multiplies SOIL RESPIRATION,
and [[seas_amps_hemispheric_inversion]] records the fit driving **SH land to 29 % of its bracket's
LOW end** while cranking **NH land to 131 % of its HIGH end**. Suppressing SH respiration is
precisely how cancellation goes missing. **NOT YET TESTED — this is a hypothesis with a lever and a
sign, which is what 27h and 27i demanded before any arm is run.**

⚠ **A phase input, measured but NOT converted:** CT2022's SH land **uptake centroid is month 2.23**
(austral summer), NH month 6.26. Turning a flux centroid into the CO2-signature phase the arc
compares against is an INTEGRATION, not a 6-month shift, and **that conversion has not been done** —
do not difference 2.23 against the model's 10.09 SPO land peak. [[smoother_wider_than_feature]]

## 5. THE SECOND INVERSION COLUMN IS NOT DONE

Marcus asked for both: the net-flux check (sec.4, **done**) and the **model-mediated constant** —
backing an implied productivity amplitude out of CT's NEE by adding the model's own respiration.
**Not run.** It needs a model evaluation at the mode, and it is model-signature-dependent in exactly
the way handoff 27k warns about for the inversion's "observed" land. Sec.4 is the honest half; the
mediated half is where the dependence gets MEASURED rather than asserted small.

## 6. OPEN

1. **Test the cancellation hypothesis** — `seas_T_amp_SH` power/price, the same way 27h did `tau_ex`
   and 27i did `seas_npp_amp_SH`: does it have the SIGN, and what does it cost? **Pre-register.**
2. **The second inversion column** (sec.5).
3. **The basis decision is still open and should now be taken on sec.1's evidence**: the SH
   insolation fit has **no interior optimum** (argmin at the grid edge, still falling) and a ~12 %
   floor. That is a stronger argument for an empirical SH shape than 27l had.
4. `SEAS_NPP_AMP_SH = 0.5027` should probably be **re-stated with its real uncertainty** — 0.50
   (MOD17) vs 0.94 (CMIP6) at fixed phi, and 5.3× across the ridge. It is currently `status = "data"`
   with an sd of 0.087, which is **the spread across five MOD17 years** and badly understates it.

## 7. STATE

- Repo clean before this; **`R/` and `src/` untouched** in sec.1–4 (the only `R/` change today is the
  `likelihood.R:175` comment, commit `6e26248`). **No model runs at all.**
- Suite **1157 pass / 0 fail** (checked after the comment edit; nothing since touches `R/`).
- `outputs/diagnostics/sh_pair_nonmodis.rds` written. The CT2022 `.nc` (498 MB) and the derived
  `.npz`/`.csv` sit under `data-raw/downloads/`, which `.gitignore:12` already excludes wholesale
  (only `MANIFEST.csv` and three small seasonality CSVs are un-ignored) — **checked, nothing large
  is staged.** Both products are reproducible from their build scripts + the manifest.
