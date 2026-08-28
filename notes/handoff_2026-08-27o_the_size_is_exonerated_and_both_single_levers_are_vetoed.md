# Handoff — CarbonCycleEmulator, 2026-08-27o: **THE SIZE IS EXONERATED, AND BOTH SINGLE LEVERS ARE VETOED BY THE SAME ROW**
# The SH land overshoot is real, its mechanism is now measured, and NO ONE-SIDED FIX CAN BE AFFORDED.

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, **clean**.
**Nothing is running.** **Suite: 1157 pass / 0 fail** (checked after the only `R/` change of the day,
a comment). Eight commits, `79b0eb1..54710f2`.

⚠ **THE SESSION CWD WAS `FaIRtoFrEDI/`, BUT ALL OF THIS WORK IS IN `CarbonCycleEmulator/`.** The
handoff that opened the session (27k) lives here too. Do not split these notes across repos.

---

## 0. STATE IN NINE LINES

1. **Decision (ii) of 27k is SETTLED, and the project's own provenance settled it on 2026-08-20**:
   the GPP/PsnNet bracket is ORDERED, not symmetric. **GPP was never available.** §1
2. ⇒ **27j's LAND-only and JOINT arms are INADMISSIBLE as configurations**; its **INTERACTION
   +64.99 survives** as a structural claim about coupling. §1
3. **Marcus ruled: re-derive off a NON-MODIS product**, accepting model-derivation AND circularity
   **for a pedagogical tool**. Both named products were unfetchable; substitutes approved. §2
4. **The SH `(phi, A)` pair is a FLAT RIDGE — 5.3× in size for ~3 pp of shape residual — and the SH
   argmin runs to the GRID EDGE. There is no interior optimum on the insolation basis.** §3
5. ⚠ **That corrects a number I published earlier the same session** (27l said 1.0 pp / 3.2×; the
   window was confounded with the product). §3
6. **THE NH POWER CHECK PASSES and independently CONFIRMS `phi_eff['NH'] = 75` and
   `SEAS_NPP_AMP_NH = 0.4969`** from a satellite-free product family. §3
7. **Two independent lines say the SH size should roughly DOUBLE, not shrink ⇒ `SEAS_NPP_AMP_SH` IS
   NOT THE BUG.** The gap is **CANCELLATION**: SH land nets only **25.1 %** of its gross swing to
   air; the NH nets **68.2 %**. §4
8. **27n pre-registered and ran the cancellation arm. The mechanism is REAL and EXACTLY as
   predicted — and UNAFFORDABLE.** §5
9. ⇒ **TWO levers have now failed on the SAME ROW from OPPOSITE directions.** The next arm is 27j's
   2×2 structure with the admissible lever. §6

---

## 1. DECISION (ii) — ANSWERED BY THE REPO, NOT BY A NEW EXPERIMENT

`data-raw/build_npp_seasonal_shape.R:20-28` and `DATA.md:237-242`, **written 2026-08-20, before this
arc and before any fit wanted 0.352**:

- `gpp` is "GROSS. Autotrophic respiration runs through the shoulder seasons, so GPP is **LESS
  rectified** than NPP and its phi_eff is biased EQUATORWARD, **i.e. toward the convenient answer**."
- `net_photosynthesis` is PsnNet = GPP − leaf/fine-root maintenance respiration, "closer to NPP;
  still omits growth respiration and live-wood maintenance."
- **"The truth for NPP sits at or BEYOND the PsnNet end of the bracket."**
- `R/model.R:1115` confirms the driver multiplies **the model's own `npp`** through the LEAF pool:
  `seas <- seas_npp_amp_SH * npp * (ccx_insol(phi_eff)/nrm$n - 1)`.

**⇒ The 1.4× is an ORDERED bracket with a DERIVED direction. NPP sits at or PAST 0.5027, away from
0.352.** Adopting the GPP end would have moved a measured constant in the direction its own
derivation calls the convenient answer.

## 2. WHAT WAS BUILT, AND WHAT IT IS NOT

Neither product Marcus named was fetchable: **CAMS** needs a Copernicus ADS account key (none here,
and I cannot create accounts); **TRENDY** is access-by-request and its site does not resolve.

| track | product | why | ⚠ |
|---|---|---|---|
| process | **CMIP6 `npp` Lmon historical**, 1995–2014, **34 models**, one member each | same class as TRENDY, **no satellite in the chain**, and the ONLY candidate that **IS NPP** | **MODELS, NOT OBSERVATIONS** |
| inversion | **NOAA CarbonTracker CT2022**, monthly 1×1, 2000–2020 | same class as CAMS, open | **CIRCULAR** (constrained by MLO+SPO) and **NEE, not NPP** |

Both are in `data-raw/downloads/MANIFEST.csv` with SHA-256 **and their weaknesses in the `notes`
column**, not only in a note file. ⚠ **CT's SH land is weakly constrained by data, so its SH
seasonality is substantially its PRIOR — do not treat NH and SH as equally observational.**

**Excluded on audit, and the first one is the trap:** CAMS/CarbonTracker-class inversions are
**CIRCULAR** here; **FLUXCOM and GOSIF/CSIF are MODIS-fed** and fail independence; TROPOMI/GOME-2 SIF
are independent but GPP proxies; FLUXNET towers have unusable SH coverage for a hemispheric aggregate.

**Two build gates fired and both would have corrupted the answer silently:**
- **`SAM0-UNICON` returns NEGATIVE NPP** (−29.0/−19.7 PgC/yr) — under unit-mean normalisation that
  inverts the model's whole seasonal shape. **Now rejected loudly.**
- **`UKESM1-0-LL` died on `2014-12-31` — a 360-day calendar has no 31 December.** A calendar error
  that looks like a legitimate skip while deleting a major structural family.

## 3. THE RIDGE — AND ⚠ A CORRECTION I MADE TO MY OWN EARLIER NUMBER

CMIP6 is monthly, MOD17 8-daily, so **product and window were CONFOUNDED**.
`calibration/diag_mod17_monthly_control.R` pushes MOD17 through the identical monthly pipeline
(aggregation duration-weighted, not nearest-midpoint — ~13 % of composites straddle a month).
[[like_for_like_forcing]]

| SH_psnnet | swing | A range | argmin |
|---|---|---|---|
| MOD17 **8-day** (as 27l reported) | 1.0 pp | 0.97 → 0.30 (3.2×) | ~−40 |
| MOD17 **monthly** | **2.91 pp** | 1.01 → 0.19 (**5.26×**) | **−60 = grid edge** |
| CMIP6 monthly | 3.25 pp | 1.90 → 0.35 (5.41×) | −50 |

**MOD17-monthly resembles CMIP6 far more than it resembles MOD17-8day** — most of the apparent
product disagreement was SMOOTHING. **27l's "1.0 pp" was 8-day-specific and its 3.2× UNDERSTATED the
degeneracy.** The qualitative finding HARDENS: **the SH argmin runs to the grid edge still falling —
no interior optimum exists on the insolation basis**, and Form C leaves **92 %** of the SH residual
against 65 % in the NH.

**THE NH POWER CHECK PASSES** — argmin **75** in ALL of MOD17-8day, MOD17-monthly and CMIP6 (swings
5.2 / 6.29 / 5.22 pp; A at 75 = 0.50 / 0.50 / 0.60). Built to validate the method; **it also gave
`CCX_SEAS_PHI_EFF['NH'] = 75` and `SEAS_NPP_AMP_NH = 0.4969` their first satellite-free support.**

## 4. THE RESULT — THE SIZE IS EXONERATED AND CANCELLATION IS THE GAP

At the shipped `phi = −30` on **matched monthly windows**: MOD17 gives A = **0.50** (= the shipped
0.5027, window-insensitive), **CMIP6's 34 models give 0.94** (IQR 0.71–1.22). **A ~1.9× product
disagreement — LARGER than the 1.4× bracket decision (ii) was about, and pointing the OPPOSITE way
from the arc.** With 27l's measured-centroid line (−15.12 → A ≈ 0.97), **two independent lines say
the SH productivity swing should roughly DOUBLE** while the atmosphere says the model's SH land is
already **1.33–1.92× too BIG**.

Seasonal peak-to-peak, PgC/yr: **CMIP6 NPP (gross) NH 61.5 / SH 15.0; CT2022 NEE (net) NH 42.0 /
SH 3.8** ⇒ **net/gross NH 0.682, SH 0.251.**

**⇒ SH LAND CANCELS 74.9 % OF ITS GROSS SWING BEFORE THE ATMOSPHERE SEES IT; THE NH CANCELS 31.8 %.**
SH productivity is tropical and water-driven, so photosynthesis and heterotrophic respiration share a
wet season and nearly cancel. **The model carries ~half the amplitude factor and UNDER-CANCELS;
shrinking the gross (27j's GPP move) mimicked cancellation with the wrong knob.**

## 5. 27n — THE CANCELLATION ARM: PRE-REGISTERED, RUN, MECHANISM CONFIRMED, COST PROHIBITIVE

Prereg `notes/prereg_2026-08-27n_...md`, **committed `11a59de` BEFORE
`calibration/diag_seas_T_amp_sh_power.R` existed. No gate was moved.**

**`P0 ✓ P1 ✓ P2 ✓ P3 ✓ · P4 ✗ P5 ✗ P7 ✗ · P6 ✓ · P8 = 1.79× obs, 15.3 % of the excess closed.`**

The two SH land channels at SPO: **NEP 1.3950 ppm @ mo 10.15, respiration 0.0926 @ mo 5.05 — 153°
apart**, so respiration cancels. Their vector sum **1.313 @ 10.09** reproduces 27k's independent
**1.315 @ 10.09**. `seas_T_amp_SH` landed at **1.0391 K = 28.9 % of its bracket LOW end** [3.59, 7.10]
while `seas_T_amp_NH` sits at **131 % of its HIGH end**.

- **P1 ✓** the pre-registered closed form matched to **0.4–0.7 %** (gate 3 %).
- **P2 ✓** the geometric floor is real and the profile **NON-MONOTONE**: min **0.6181 at 13.95 K**,
  rising to **0.8107 at 20.0** — a turn only the 153° geometry produces.
- **P3 ✓** the **prior PAYS +8.34** to move to the bracket top (`seas_npp_amp_SH` COST 79).
- **P5 ✗ — THE DIAGNOSTIC GATE.** Frozen at bracket HI the bill is **−214.70**, of which
  **`co2_seasonal_SPO` carries −187.21 = 87 %.**

| a_t (K) | cond Δlp | frozen Δlp | SH-land | ×obs |
|---|---|---|---|---|
| 1.0391 (landed) | +1.43 | −0.00 | 1.3234 | 1.94 |
| 3.5915 (bracket LO) | −11.29 | −46.53 | 1.2552 | 1.84 |
| **7.1012 (bracket HI)** | **−33.68** | −204.45 | **1.2256** | **1.79** |

⚠ **I PRE-REGISTERED P4 AS "PREDICTED POSITIVE". IT LANDED AT −35.11. THE PREDICTION WAS WRONG.**
The slice buys back **84 %** of the frozen cost **by restoring the very signal the lever removed** —
frozen SH-land 1.308 → 0.873 (−0.435), conditional 1.3234 → **1.2256** (−0.098), so **78 % of the
improvement is undone.** An 84 % buy-back that returns the diagnostic to its start is a **refusal**.

**P6 ✓ is the one clean result and it sets up §6**: `sst_seas_amp_SH` moves only **0.3596 → 0.3046,
z −1.19**, where 27j's LAND-only arm **collapsed it to 0.176 (z −9.18)**. **The improvement is EARNED,
not bought — and the ocean limb still has room.**

## 6. ⇒ THE NEXT ARM (NOT RUN, NOT PRE-REGISTERED)

**Two levers have now failed on the SAME ROW from OPPOSITE directions** — `seas_npp_amp_SH` (27i,
−113.25 of −113.87) and `seas_T_amp_SH` (−187.21 of −214.70). **That is not two coincidences; it is a
row with no power punishing motion.** The mode matches SH seasonal CO2 to ~1 %, the SPO total is right
**BY CANCELLATION** (land 1.92× too big against an ocean 0.45× too small), and **every one-sided move
breaks it.** [[seas_right_observable_wrong_drivers]] [[land_and_ocean_are_one_fix]]

**PROPOSED: a 2×2 in `seas_T_amp_SH` × `ent_seas_amp_SH`**, 27j's parameter-balanced
`INTERACTION = JOINT − LAND − OCEAN + INCUMBENT` (npar 7−6−7+6 = 0) with the **admissible** lever
replacing the forbidden productivity one. Reach known in advance: cancelling SH land drops the SPO
total ~0.06 ppm (1.1407 → 1.0780 frozen) while 27j's entrainment channel added **≈0.37 ppm at mo
9.24** (obs 8.52). **P6 is what makes it worth running.**

**⚠ FIX THE DRIVER'S CONDITIONAL SLICE FIRST — see §7.**

## 7. NON-OBVIOUS STATE — READ BEFORE TOUCHING ANYTHING

- ⚠ **THE 27n DRIVER'S CONDITIONAL SLICE HOLDS BOTH `seas_T_amp_NH` AND `q10`, AND THEIR PRODUCT
  RIDGE IS EXACT** (2.2609–2.2663 across q10 1.09→2.0, Hessian **cor −0.972**; the seasonal rows move
  only 4.3 log-units across the whole range and **do NOT identify q10**). Nelder-Mead crawls a
  direction the data does not constrain — points took **10 / 70 / 150+ min**. **Drop `q10` from the
  slice, or reparameterise to (product, ratio); add intermediate warm-start rungs. DO NOT raise
  `TA_RESTOL`** — that buys speed by accepting under-convergence, the failure 27h already made once.
  [[ccx_seas_q10_ridge]]
- ⚠ **A GATE THAT DECLINES TO RUN IS WORSE THAN ONE THAT FAILS.** The first 27n driver read streams
  from `attr(lp(u), "streams")`, got NULL, and **printed "per-stream breakdown unavailable" while
  silently skipping P5 — the arm's own diagnostic gate.** It is `ccx_loglik(..., by_stream = TRUE)`.
  **Fixed in the repo copy AFTER the run started**, so ⚠ **`outputs/diagnostics/seas_T_amp_sh_power.rds`
  does NOT carry the streams**; the P5 table came from a standalone re-run. Re-run the fixed driver if
  the archive needs them. [[mutation_test_gates]]
- ⚠ **`md$u_mode` — SPELL IT OUT.** R's `$` partial-matches, so `md$u` silently resolves to it.
  Worked today; one added field from resolving elsewhere.
- ⚠ **`SEAS_NPP_AMP_SH`'s stated sd of 0.087 BADLY UNDERSTATES its uncertainty** — that is the spread
  across five MOD17 years, against a **1.9× product disagreement** and a **5.3× ridge**. It is still
  `status = "data"`. Consider restating it; **not done, and it is a provenance edit, so it is Marcus's.**
- ⚠ **`ccx_make_logpost()` still does not reproduce the mode's stored logpost** — −1547.9370 vs
  −1544.6148, **offset −3.3223**, verified again today and identical. **Never quote an absolute
  logpost against the mode file.** [[ccx_mode_logpost_offset]]
- **SEVEN of the 21 calibrated names are likelihood-side and absent from `ccx_default_params()`** —
  read them off `pv`, never `p`. **`ccx_model_stats()` returns a LIST OF COLUMNS, not a data.frame**
  (`nrow()` is NULL → `sprintf()` returns `character(0)` → `cat()` prints nothing, silently).
- **`R/likelihood.R:175`'s "66 % of `tau_ex`'s leverage is seasonal" IS NOW QUALIFIED** (`6e26248`)
  with 27h's measurement that it is the **LOWER jaw only**. 27k's live item is **CLOSED**.
- **Downloads are gitignored** (`.gitignore:12` covers `data-raw/downloads/*`); the 498 MB CT2022
  `.nc` is on disk and reproducible from its build script + MANIFEST.
- ⚠ **Memory sub-index `INDEX_ccx_seas.md` is at ~15.9 KB against a 14 KB soft target** (hard 18 KB).
  The arc now has six partly-superseding entries. **A merge pass is due; I did not prune arc history
  unilaterally.**

## 8. STILL OPEN BEHIND THIS

- **The second inversion column** (27m sec.5): the model-mediated constant, backing an implied
  productivity amplitude out of CT's NEE via the model's own respiration. **Needs a model evaluation
  at the mode.** It is where the model-signature dependence gets MEASURED rather than asserted small.
- **The CLOSURE ARM (27n prereg sec.5), recorded before testing so it cannot be back-fitted:**
  CMIP6's 1.87× bigger productivity × CT2022's 0.251 net/gross = **0.655 against an observed 0.683 —
  two products agreeing to 4 % on a quantity neither was fitted to.** ⚠ **NOT AUTHORISED**: it sets
  `SEAS_NPP_AMP_SH` to a CMIP6 **ensemble** value, Marcus's call exactly as the GPP end was. And the
  flux-ratio transfer to an SPO signature is an **approximation, not an identity.**
- **The basis decision is STILL OPEN** and should be taken on §3's evidence: the SH insolation fit has
  **no interior optimum** and a ~12 % floor. That is a stronger argument for an **empirical SH shape**
  than 27l had. Marcus chose "measure first, decide after" — **the measuring is now done.**
- ⚠ CT2022's SH land **uptake centroid is month 2.23** (NH 6.26), but converting a flux centroid to a
  CO2-signature phase is an **INTEGRATION**, not a shift, and **was not done** — do not difference it
  against the model's 10.09.
- `R/likelihood.R:1028/1091/1178` — `co2_NH` maps to MLO with a level offset and **no seasonal
  amplitude representation term** (27k sec.7). Still unchecked. ⚠ Correcting it makes the NH import
  WORSE, so it is worth doing to KNOW, not as a fix.
- The δ¹³C Suess overshoot re-check; `gcb_land_sink` (−7.94); **`kz` railing** (6332 vs 6528);
  `alpha13_signed` (b); `alpha_as_*` hardcoded and temperature-independent; the Hessian condition
  number; **the sampler — the project's oldest open item, and there is STILL NO POSTERIOR.**

## 9. HOW TO RUN WHAT EXISTS

    python data-raw/build_cmip6_npp_seasonal_shape.py     # ~6 min, lazy zarr, 34 models
    python data-raw/build_carbontracker_land_shape.py     # seconds, needs the 498 MB .nc
    python data-raw/npz_to_csv_seasonal.py                # format only
    Rscript calibration/diag_sh_pair_nonmodis.R           # ~10 min, NH power check + SH ridge
    Rscript calibration/diag_mod17_monthly_control.R      # ~8 min, the WINDOW control
    Rscript calibration/diag_seas_T_amp_sh_power.R        # ⚠ ~4 h as written -- FIX THE SLICE (§7)
    Rscript calibration/diag_seas_rectification.R         # ~4 min, offline, the original ridge table

Outputs in `outputs/diagnostics/`: `sh_pair_nonmodis.rds`, `seas_T_amp_sh_power.rds`.
**Run long jobs from a FROZEN COPY in `/tmp`, pin BLAS to one thread, and check `uptime` first.**
[[never_edit_a_running_script]] [[eta_in_days_is_not_a_slow_run]]
