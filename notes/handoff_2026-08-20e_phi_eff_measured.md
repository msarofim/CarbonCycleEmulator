# Handoff — CarbonCycleEmulator, 2026-08-20e: φ_eff measured, SHIPPED, and the refit launched

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`.
**Predecessor:** `handoff_2026-08-20d_drivers_and_channels.md`. Read this one first.
**20d §5 and §6 are both CLOSED by this session.** 20d §6's hypothesis was right in substance and
wrong in its remedy — see §3.

---

## 0. STATE IN TEN LINES

1. **THE REFIT IS DONE AND CONVERGED.** −1877.9; the four seasonal rows went −576.6 → **+207.3**.
   `seas_T_amp_NH` flags at +3.29 σ but that is the **q10 degeneracy**, not a failure. §7.
2. **SHIPPED: `seas_npp_amp_{NH,SH}` 1 → 0.4969 / 0.5027**, measured. `CCX_SEAS_PHI_EFF` UNCHANGED
   at (75, −30). **+548.7 log-units for two constants and no latitude change.** §3.
3. **The shipped latitudes were never the error — the amplitude was.** 75 is the best *shape* match
   once amplitude is free (polar night = a hard zero); its curve was simply 1.6× too big. §2.
4. **`seas_T_amp_NH` came home**: re-optimizes to **11.08** against a measured **11.45**, from a
   fitted 48.07. The cancellation hypothesis is confirmed by its own repair. §3.
5. **`npp_frac_NH` re-anchored and SHIPPED** — `dnorm(·, 0.5986119, 0.04)`, the *fixed point*, not
   the audit's 0.6136. Circularity priced at ≤0.0013. §4.
6. **Banding the hemisphere was tested and REJECTED**, twice, in two forms. Under a non-negativity
   constraint every multi-box fit deletes its own low-latitude boxes and loses to one curve. §5.
7. **A CORRECTION is on the record**: the "four boxes beat one curve, 7.1 % vs 7.4 %" claim was an
   artifact of an unconstrained solve using **negative** amplitudes. The honest number is 9.9 %. §5.
8. **TWO tests fail, neither modified**: `test-fluxes.R:99` (from 08-20g) and `:100` (new, and a
   direct consequence of the amplitude change). **947 pass.** §6.
9. **`sst_seas_amp_NH` = 0.41 against an observed 2.237 in ALL 31 profile cells.** Untouched by this
   entire arc. **It is the next real defect.** §6.
10. Still no posterior; `output/mode_fit.rds` still absent. The refit in §7 is a MODE-FIND.

---

## 1. WHAT WAS ASKED

Marcus, in order, each answered in the section named:
1. *(continue 20d)* → §6's order followed: measure, profile, then refit.
2. *"Download the sub annual product"* → §2b.
3. *"For npp_frac_NH … this is a pedagogical product … do you have a recommendation?"* → §4.
   **Recommendation given, accepted, SHIPPED.**
4. *"Is there a way to do a quick check on the 3 options for φ-eff?"* → §2c. Yes: one offline test
   (minutes, no model runs) and one profile pass.
5. *"What is the average latitude for NH NPP, and how close is it to 75? Is it possible that optimal
   NH latitude will change now that we've updated our SH numbers?"* → §2d. **34.29, and yes** — the
   answer exposed a rigged comparison in my own earlier profile.
6. *"Would there be value in dividing the NH land?"* → §5. Tested, no.
7. *"What about not including the low-latitudes in the annual cycle at all?"* → §5. Tested; it does
   not beat one curve, but it **derives** the poleward φ, which is the useful part.
8. *"So a single NPP box at 75 outperforms a dual NPP box…?"* → §5. **Yes** — and answering it
   produced the correction in §0.7.
9. *"If 75 + 0.49 is the better fit, go with the better fit."* → §3. **SHIPPED.**
10. *"Make the handoff current, and then start the refit."* → this file, and §7.

---

## 2. THE MEASUREMENTS

### 2a. Annual MOD17A3HGF — the aggregation question (`diag_npp_eff_latitude.R`)

Applying the model's own premise (*NPP follows normalised insolation*) **per grid cell**, weighted
by annual NPP: the hemispheric aggregate is reproduced by **NH 38.35 / SH −15.75**. The NPP-weighted
*mean* latitude is **34.29 / −15.12** — not the same number, because insolation is nonlinear in
latitude, and both are reported.

**Phase carries NO information.** Daily-mean insolation peaks at the solstice at every extratropical
latitude, so every candidate peaks with the aggregate and `seas_lag_p` has nothing to absorb.

### 2b. 8-day MOD17A2HGF — the premise removed (`build_npp_seasonal_shape.R`, DATA.md §3d)

Same algorithm, same ICDC 0.5° regrid, CC-BY-4.0, no registration (doi:10.25592/uhhfdm.14449).
**Five years spread across the record** (2001, 2006, 2011, 2016, 2021; 2022 absent upstream).
**Zips kept, unzipped files not** — 597 MB/yr vs a 70 MB zip, and it keeps the manifest SHA-256
verifiable, which it is *not* for the annual product.

| | φ (shape) | sd yr | φ (amplitude) | obs p2p | unexplained |
|---|---|---|---|---|---|
| NH `gpp` | 49.26 | 2.62 | 54.60 | 1.699 | 10.8 % |
| NH `psnnet` | **49.96** | 2.93 | **55.49** | 1.747 | 11.4 % |
| SH `gpp` | −10.86 | 4.22 | −28.17 | 0.736 | 14.3 % |
| SH `psnnet` | **−16.14** | 2.67 | **−32.15** | 0.845 | 12.8 % |
| *shipped* | 75.0 / −30.0 | | | *2.801 / 0.742* | |

**`gpp` and `net_photosynthesis` BRACKET NPP.** GPP is less rectified than NPP (autotrophic
respiration runs in the shoulder seasons) so its φ is biased **equatorward**, toward the convenient
answer; PsnNet omits only growth and live-wood respiration.

**By-product — `seas_lag_p` is measured**: NH **+0.8 to +1.0 months** against a fitted 2.17; SH
**−2.1 to −2.9**, a *lead*. **One global `seas_lag_p` cannot be both.** Structural, still OPEN.

### 2c. Which FORM the shape wants (`diag_seas_rectification.R`) — the cheap decisive test

Offline, no model runs. Four forms, each adding one parameter, window-integrated, free shift:

| case | A: one curve | B1: threshold | B2: power | C: free amplitude |
|---|---|---|---|---|
| NH `psnnet` | 11.4 % | **11.4 % (c = 0)** | 11.0 % (γ 1.60) | **7.4 %** (φ 74.8, A 0.50) |
| SH `psnnet` | 12.8 % | 12.8 % (c = 0) | 12.2 % | 11.8 % |

**A light THRESHOLD buys NOTHING — it optimizes to zero and *chooses* to be the incumbent form.**
(The original offline fit recorded the same and it was never followed up.) **A free amplitude buys
34–35 % in the NH**, and its φ is an **interior minimum at 75**:

```
NH_psnnet  38.35:12.7%/A1.38  45:12.0%/A1.12  50:11.4%/A0.96  55:10.8%/A0.83
           65:9.3%/A0.62      75:7.5%/A0.49   85:8.3%/A0.44        <- interior min
SH_psnnet -15.75:12.9%/A0.97 -20:12.5%/A0.77 -30:12.0%/A0.50 -40:11.9%/A0.36   <- FLAT
```

**So the offline fit that chose 75 was right about the SHAPE.** Polar night is the only hard zero in
the insolation family, and it emulates a rectified boreal growing season better than any lower
latitude's smooth curve. The model just had no way to SCALE it. **The SH latitude is NOT determined
once amplitude is free.**

### 2d. Where the land and the biomass actually are (`diag_sh_land_latitude.R`)

| weighting | SH | NH |
|---|---|---|
| land area, Antarctica EXCLUDED | **−18.08** | 37.70 |
| land area, Antarctica *included* | −35.93 | 37.70 |
| vegetated area (MOD17 valid px) | −18.47 | 40.59 |
| NPP flux | −15.12 | **34.29** |

**The shipped NH 75 is 40.7° from the NH NPP centroid.** That is why the constant's comment had to
be rewritten (§3) — it called itself "flux-weighted effective" and is nothing of the kind.
**Marcus' SH prior (non-Antarctic land mass) is −18.08**, next to the shape-matched −16.14. Note
also that Antarctica-INCLUDED gives **−35.93, close to the shipped −30** — suggestive of where the
shipped value came from, not proof.

---

## 3. THE PROFILE, AND WHAT SHIPPED (`diag_phi_eff_profile.R`, 31 cells, 5 passes)

Every cell patches **both cores**, rebuilds in its own `tempdir()`, passes **three gates**, and
**re-optimizes the seven parameters the seasonal cycle identifies** (`seas_T_amp_{NH,SH}`,
`seas_lag_p`, `sst_seas_amp_{NH,SH}`, `npp_frac_NH`, `q10`) on the full posterior. A frozen profile
would be worthless: moving φ at a fixed `seas_T_amp_NH = 48 K` breaks the cancellation by
construction.

**The gate that matters was MUTATION-TESTED**: disabling the C++ patch while leaving the R patch in
makes the R-vs-C++ derivative parity check fire, so no worker can run the incumbent's constant under
a challenger's label.

| φ NH | φ SH | amp NH | amp SH | REOPT | `seas_T_amp_NH` | `npp_frac_NH` |
|---|---|---|---|---|---|---|
| 75 | −40 | 0.49 | 0.36 | −2025.2 | 10.75 | 0.555 |
| **75** | **−30** | **0.4969** | **0.5027** | **−2027.3** | **11.08** | **0.550** |
| 75 | −18 | 0.49 | 0.97 | −2043.5 | 11.45 | 0.571 |
| 50 | −15.75 | 1 | 1 | −2071.4 | 11.68 | 0.534 |
| 45 | −30 | 1 | 1 | −2187.3 | 10.82 | 0.684 |
| **75** | **−30** | **1** | **1** | **−2576.0** | **38.61** | **0.459** |

*(observed: `seas_T_amp_NH` 11.445, `npp_frac_NH` 0.594)*

**SHIPPED (Marcus: "if 75 + 0.49 is the better fit, go with the better fit"):** the amplitude
factors as `SEAS_NPP_AMP_{NH,SH}` in `R/constants.R` (`data`), **`CCX_SEAS_PHI_EFF` unchanged**.
Applying the same rule to the SH lands on the shipped −30 too, so **no latitude moved at all**.
**The SH remains available at −18 for 15.8 log-units** if the physical reading is later preferred.

**No C++ edit was needed** — both cores already read these from the parameter list — so **parity is
untouched**.

**`CCX_SEAS_PHI_EFF`'s comment is rewritten.** The pair is ONE (shape, size) unit:
`test-likelihood.R` RE-FITS both factors from `data/obs_npp_seasonal_shape.rds` at the CURRENT φ and
asserts agreement, with a mutation check that the gate fails at φ = 50. **Move φ without redoing the
factors and the suite says so.**

**The hemispheres INTERACT — a 1D φ profile misleads.** At SH −30 the NH optimum is 38–45 and 75
loses by ~390; at SH −15.75 the ordering REVERSES. `seas_lag_p`, `q10` and `npp_frac_NH` are global.
Pass 1 was a 1D slice **and** ran most cells at amplitude 1 while 75 and 65 carried their measured
factors — rigged in 75's favor, and read as if it were not. Marcus' question (§1.5) is what exposed
it; the measured-ridge pass fixed both flaws at once.

---

## 4. `npp_frac_NH` — SHIPPED (20d §5 CLOSED)

Option **(a)**, a prior on the 1750 parameter. **The circularity is priced, not argued**
(`diag_npp_frac_anchor.R`): `luc_scale` ±30 % moves the anchor **0.0013**, `tau_soil_slow` ±30 %
0.0012, `tau_wood` ±30 % 0.0003 — an order of magnitude below the 0.04 prior width and below
MOD17's own 0.0135 interannual sd. Option (b) would have RELOCATED the circularity into a direct
`npp_frac_NH`↔`luc_scale` correlation plus a likelihood stream: harder to calibrate, not easier.

**It ships as the FIXED POINT, 0.5986119, not the audit's 0.6136.** The inversion is implicit
(`cum_luc / land0`, and `land0` ∝ `npp_frac_NH`), and the **+0.0149** difference is larger than
every other model-dependence in the table.

**The width 0.04 is a stated JUDGMENT**, like `SST_SEAS_LOGSD`. The old mode sits at **−3.31 σ**,
which is the point. `NPP_FRAC_NH_ANCHOR_1750` is `provisional` and joins the ledger **deliberately**
— it keeps a model-dependent prior center visible.

**And the profile vindicates it independently**: the audit's −794 veto on raising `npp_frac_NH` was
**an artifact of φ = 75**. Re-optimized it runs 0.459 at the old configuration and **0.55–0.62
wherever NEP is de-amplified** — the fit asks for the observed share by itself.

---

## 5. BANDING — TESTED TWICE, REJECTED, AND ONE NUMBER WITHDRAWN

**Marcus' physical reading was right**: the bands genuinely are different ecosystems (NH peak-to-peak
spans 0.94 → 3.96, best-fit φ spans 5 → 86). **The fix does not follow from it.**

`diag_npp_bands.R` — per-band residuals are **11.5 / 13.7 / 8.3 / 9.5 %** against a whole-hemisphere
**11.4 %**; two bands are *worse*. **So the misfit is NOT an aggregation artifact.** The pattern:
40–55 and 55–90 want φ **poleward** of their own centroids with A ≈ 1 (rectification, independently
confirmed per band); 0–23.5 and 23.5–40 are **not light-shaped at all** (water-driven).

`diag_npp_seasonal_fraction.R` — deleting the low latitudes instead. Zero-parameter version (both
w(L) and φ(L) measured, A = 1) gives **16–27 %**; A-free tops out at **9.4 %** at L = 60, still short
of 7.4 %. **But it DERIVES the poleward φ**: at L = 60 the model is a curve at **φ 64.4 with
effective amplitude 0.63** — essentially the (65, 0.62) ridge cell, from a different direction. And
**A measures the rectification**: 1.54 at the equator → **5.85 at 60 N**.

`diag_npp_twobox.R` — Marcus' exact configuration (0–60 weak, 60–90 strong, both boxes kept).
**A_lo is driven to ZERO at every split up to 60**: the two-box model deletes its own low box and
becomes the cutoff model. Best 9.4 %, never 7.4 %.

### ⚠ CORRECTION, on the record

**"Four boxes = 7.1 %, beating one curve's 7.4 %" was WRONG.** It came from an unconstrained
`qr.solve`, and unconstrained solves in this family reach for **negative amplitudes** — a
productivity box run backwards through the year. Re-derived under non-negativity (exact, 2⁴ active
sets): **NH 9.9 %, SH 11.7 %** — four boxes LOSE. And the solution zeroes three of four, keeping
only 55–90, i.e. the cutoff model at L = 55 which independently gave 9.9 %. **The two diagnostics
agree exactly, which is what makes this the correction and not a second error.**

**Why one rectified curve beats the boreal box alone:** at φ 75 / A 0.49 the *whole* hemisphere's
NPP carries a heavily rectified shape at half strength; boreal-only has 11 % of the NPP at 5.9×
strength. Similar amplitude, different distribution — and the aggregate prefers the rectified shape
**spread across all the carbon**.

---

## 6. WHAT IS STILL BROKEN

- **`sst_seas_amp_NH` = 0.33–0.54 in EVERY one of 31 cells** against an observed **2.237** (−12.9 σ).
  Nothing in this arc moved it. **THE NEXT REAL DEFECT.**
- **The MLO cycle still undershoots**: 5.81 ppm against 6.754. **The isotopic signature still does
  not close**: 0.068 against 0.0528 (improved from 0.0788, then stopped).
- **`seas_lag_p` cannot be both hemispheres' lag** (+0.9 NH, −2.1 SH; one global parameter at 1.73).
- **TWO failing tests, neither modified, both reported:**
  - `test-fluxes.R:99` — from 08-20g; its 1e-3 tolerance silently encoded `CCX_SST_SEAS_LAG = 2.5`.
  - `test-fluxes.R:100` — **new**. `expect_lt(on$tau_label, off$tau_label - 0.2)` gives 4.523 vs a
    4.500 bar. The gap is 0.705 at `seas_npp_amp` 1, **0.177 at the shipped 0.4969**, and turns
    **negative below ~0.35** — so the 0.2 threshold silently encoded amplitude 1, *and* the
    assertion is not monotone in what it varies. Options: derive the threshold from
    `seas_npp_amp`; assert the sign only; or run at the amplitude it was written for and say so.
- **`enso_share` 50/50** remains the cheapest unsourced split, GFED already on disk.

---

## 7. THE REFIT — DONE (2026-08-21), CONVERGED, UNCERTAINTIES NOT QUOTABLE

Launched 2026-08-20 evening, `calibration/run_modefind_pump_arms.R`, **ONE ARM (N)**, ~18 h.
Log: `calibration/output/pump_arms/refit_20260820.log`. Output overwrites
`calibration/output/pump_arms/mode_fit_pumpN.rds`; **the pre-refit file is preserved under
`pre_refit_20260820r/`.**

**Three edits to the driver, all in this session:**
1. **`ARM_MODES` c("N","D") → c("N")**. The 08-18 two-arm run found the arms indistinguishable and
   its evidence margin was explicitly not quotable; nothing changed since touches the pump. **This
   is a deliberate narrowing, reversible in one line** — the comparison block reactivates itself.
2. **`hml_bound` is now RECORDED in the output**, next to `kz_bracket`. It should always have been:
   the refit overrides `h_ml`'s bounds in-process, the 08-18 files did not say so, and decoding
   their `u_mode` under the default [30, 200] gave 81.75 / 46.46 m and flipped the arm margin to
   −34.63 (`ccx_hml_band_provenance`).
3. **The two-arm gates are guarded.** With one arm `fits$D` is NULL and `identical(x, NULL)` is
   FALSE for every name, so the "arms differ in more than pump_mode" gate reported all 48
   parameters as differing — **a gate failing because there was nothing to compare**. Found by
   smoke-testing before launch, not at hour 18.

**SMOKE-TESTED END TO END** at `ARM_MAXIT = 60`, `ARM_RESTARTS = 2`, output to a tempdir: exit 0,
mode written, comparison skipped cleanly. That run's numbers are meaningless — it tests plumbing.

### RESULT (commits `be86760`, `8c785c9`, and the continuation)

919 min + a 15.6 min continuation. **Mode −1877.9475, `hit_cap` FALSE, verified converged** by an
independent warm-started restart that moved it by 2.3e-4 relative.

| stream | 08-18 | **now** |
|---|---|---|
| `co2_seasonal_MLO` | −232.2 | **−39.1** |
| `co2_seasonal_SPO` | −95.6 | **+35.1** |
| `d13c_seasonal_MLO` | −141.6 | **+116.6** |
| `d13c_seasonal_SPO` | −107.2 | **+94.7** |
| **seasonal total** | **−576.6** | **+207.3** |

**`seas_T_amp_NH` = 25.94 at +3.29 σ is the q10 DEGENERACY.** The identified quantity is
`seas_T_amp` × ln(`q10`): **11.16** at the 08-18 mode, **2.205** in the 7-parameter profile,
**2.251** here. The refit and the profile agree to 2 % — **the amplitude fix worked**; `q10` then
slid to 1.0907 and dragged A up the ridge. **The prior is on the wrong coordinate.** NEXT.

**`sst_seas_amp_NH` = 0.467 (−5.97 σ)** — moved 5× and still 4.8× below the observed 2.237.
**`npp_frac_NH` = 0.559 (−0.99 σ)** — the re-anchored prior works, no fight. **`kz` = 6461 (97.4 %
up its bracket)** — still pinned, §5.2h unresolved.

**⚠ THE UNCERTAINTIES ARE NOT QUOTABLE.** `hessian` is UNSTABLE at `h_ml`, so `logdet_negH`,
`sd_unc`, `cov` and any Laplace evidence are out. It is NOT the kink problem — the mode is 10.85 m
from the nearest kink — it is a parameter 2.56 m above its bound. **`par_mode` is usable; the
second-order block is not.** Fixing it needs a step-size study for `h_ml`, NOT done.

**Superseded plan, kept because the reasoning was wrong and the correction is the lesson:**
1. **The CO₂-level streams** (`co2_level_MLO/SPO`) — the 08-18 refit recovered them and that was
   the evidence the `h_ml` bound was cheap. If they blow out, the bound is doing damage.
2. **`seas_T_amp_NH`** — it should land near 11.45. The profile says 11.08 with only seven
   parameters free; a full refit has 21.
3. **`sst_seas_amp_NH`** — does it move off 0.4 now that NEP is de-amplified and its prior is
   re-anchored? If not, §6's headline defect is confirmed as independent of everything done here.
4. **`npp_frac_NH`** — the profile wants 0.55, the prior centers 0.599. A large prior_z means the
   two are still fighting.
5. **`kz`** — still pinned near the bracket top? That is the standing question from §5.2h.

---

## 8. FILES

**New this session:** `calibration/diag_npp_eff_latitude.R`, `diag_seas_rectification.R`,
`diag_phi_eff_profile.R`, `diag_sh_land_latitude.R`, `diag_npp_frac_anchor.R`, `diag_npp_bands.R`,
`diag_npp_seasonal_fraction.R`, `diag_npp_twobox.R`; `data-raw/download_mod17_gpp8d.R`,
`data-raw/build_npp_seasonal_shape.R`; products `data/obs_npp_seasonal_shape.rds`,
`obs_npp_bands.rds`, `obs_npp_latwindow.rds`; outputs `calibration/output/phi_eff_profile*.rds` (5).

**Edited:** `R/constants.R` (4 new constants), `R/calibrate.R` (`npp_frac_NH` prior +
`NPP_FRAC_NH_SD`), `R/model.R` (amplitude defaults + the φ comment),
`calibration/run_modefind_pump_arms.R` (§7), `tests/testthat/test-constants.R`,
`tests/testthat/test-likelihood.R`, `DATA.md` §3d, `CHANGELOG.md`,
`data-raw/downloads/MANIFEST.csv` (5 new entries).

---

## 9. TRAPS FOUND THIS SESSION

Everything in 20d §8 still applies. New:

- **`ccx_const()` is NOT callable at `CCX_PARAM_TABLE` construction time** — `R/calibrate.R` sources
  before `R/constants.R`. A prior *closure* can call it; an `init` cannot. Hence literal-plus-tie-test.
- **A one-shot inversion is not a fixed point.** The `npp_frac_NH` anchor depends on itself through
  `land0`; the gap was +0.0149, **larger than every model-dependence it was being compared against**.
- **Unconstrained least squares will buy a NEGATIVE amplitude** — an inverted seasonal cycle, which
  fits and cannot exist. It cost one wrong published number (§5). Constrain, or check the sign.
- **`qr.solve` on a near-empty column returns 1e3–1e6 WITHOUT erroring**, so `tryCatch` is not a
  guard. Check `is.finite` on the result, and count what you skip.
- **A circular time shift has a DIRECTION**, and reversing it returns a plausible φ with a
  sign-flipped lag. Gate on a synthetic (φ, lag) recovery.
- **The last MOD17 composite of a year is 5–6 days, not 8.** Treating it as 8 inflates the winter
  end of the NH cycle — the end carrying the rectification signal.
- **A 1D profile of a 2D surface with an interaction reads as an answer.** Pass 1 said 38–45; pass 2
  reversed it. Fill the plane, and check that every cell got the same optimization.
- **`net_photosynthesis` is in the 8-day file** and is much closer to NPP than `gpp`.
- **A two-arm gate fires on a one-arm run** if it compares against a NULL. §7.3.

---

## 10. OPENING THE NEXT SESSION

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-20e_phi_eff_measured.md`. **§7 is done: the refit CONVERGED at
> −1877.9 and the seasonal rows went −576.6 → +207.3. Two things fall out of it: the
> `seas_T_amp`×ln(`q10`) degeneracy means the prior is on the wrong coordinate, and the Hessian is
> unstable at `h_ml` so no uncertainty from that file is quotable.** The φ_eff and
> `npp_frac_NH` questions are both CLOSED and SHIPPED; do not reopen them without reading §3 and §5,
> and note the CORRECTION in §5. **§6's `sst_seas_amp_NH` at −12.9 σ is the next real defect and
> this arc did not touch it.** Two tests fail by design (§6) and are Marcus'. Do not quote
> `logpost`/`hessian`/evidence from any pre-08-20r arm file: the priors changed twice and the model
> once since they were written.
