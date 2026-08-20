# Handoff — CarbonCycleEmulator, 2026-08-20e: φ_eff measured three ways, and the defect is AMPLITUDE

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`.
**Predecessor:** `handoff_2026-08-20d_drivers_and_channels.md`. Read this one first. **20d §6's
hypothesis is CONFIRMED in substance and WRONG in its remedy** — see §3.

---

## 0. STATE IN TEN LINES

1. **`CCX_SEAS_PHI_EFF` is now measured three independent ways**, and all three agree on the
   diagnosis: the NEP channel is over-driven ~2×. §2.
2. **But the shipped LATITUDES are not the error — the amplitude is.** With a free amplitude the
   observed NH shape prefers **φ = 75 with the swing halved** (residual 7.2 % vs 10.7 % at φ = 50),
   and so does the calibration. §3.
3. **`seas_npp_amp_{NH,SH}` already exists** (identity default, added 08-20f) and is exactly the
   knob this needs. **The best repair requires NO new code.** §3.
4. **A light THRESHOLD buys nothing** — it optimises to c = 0, i.e. it chooses to be the incumbent
   form, in 3 of 4 cases. The "growing season switches on" story, implemented literally, is not
   what the data want. §2c.
5. **The shipped LATITUDES with both MEASURED amplitude factors — (75, −30, 0.49, 0.50) —
   scores −2027.7 against the shipped −2576.0. A +548 log-unit gain for TWO measured constants
   and no latitude change at all**, and it is within 2.5 of the best cell tested anywhere. §3.
6. **`seas_T_amp_NH` lands on its observed value there**: 10.92 against a measured **11.45**, from
   a fitted 48.07. The cancellation hypothesis is confirmed by its own repair. §3.
7. **`npp_frac_NH` re-anchoring is LANDED** (Marcus' call, option (a)): prior
   `dnorm(·, 0.5986119, 0.04)`. The circularity is priced at ≤0.0013. §4.
8. **The −794 veto on raising `npp_frac_NH` was an artefact of φ = 75** — de-amplify NEP and the
   fit asks for the observed share by itself. §4.
9. **`sst_seas_amp_NH` is untouched by ANY of this** — 0.33–0.54 at every configuration against an
   observed 2.237. A separate, still-open defect. §5.
10. **933 tests pass, 1 fails** — still `test-fluxes.R:99` from 08-20g, unchanged and untouched.
    Still no posterior, still no refit, `output/mode_fit.rds` still absent.

---

## 1. WHAT WAS ASKED

Marcus, in order:
1. *(continue from 20d)* → §6's suggested order was followed: measure, then profile, then refit.
2. *"Download the sub annual product"* → §2b. MOD17A2HGF 8-daily, 5 years, both `gpp` and
   `net_photosynthesis`.
3. *"For the npp_frac_NH: … this is a pedagogical product. As long as the approach is physically
   reasonable and uses as much of the observed data as possible, it is fine to make choices that
   are designed to make the model easier to calibrate and run. Given that, do you have a
   recommendation?"* → §4. **Recommendation given, Marcus accepted, LANDED.**
4. *"Is there a way to do a quick check on the 3 options for phi-eff?"* → §2c and §3, and yes:
   one offline test on data already on disk (minutes, no model runs) and one profile pass.

---

## 2. THE THREE MEASUREMENTS

### 2a. The annual product — the aggregation question (`diag_npp_eff_latitude.R`)

`CCX_SEAS_PHI_EFF` enters the model as an assertion: *NPP follows normalised insolation at φ*.
Applying that premise **per grid cell**, weighting by each cell's annual MOD17 NPP, and asking
which single latitude reproduces the hemispheric aggregate gives **NH 38.35, SH −15.75** — where
the NPP-weighted **mean** latitude is 34.29 (insolation is nonlinear in latitude, so these are not
the same number and both are reported).

**Phase carries no information and the output says so.** Daily-mean insolation is symmetric about
the solstice at every extratropical latitude, so every candidate peaks in the same month and
`seas_lag_p` has nothing to absorb. The "phase-matched" row is degenerate — it returns the lowest
latitude whose peak still lands on the solstice, a property of the tropics.

**This could not test the premise**, only the aggregation under it — which is why the 8-day
product was needed.

### 2b. The 8-day product — the premise removed (`build_npp_seasonal_shape.R`)

MOD17A2HGF C6.1, same algorithm, same ICDC 0.5° regrid, CC-BY-4.0, no registration
(doi:10.25592/uhhfdm.14449). Five years **spread across the record** (2001, 2006, 2011, 2016, 2021;
2022 absent upstream) so the spread across them is the uncertainty rather than one pentad's ENSO.
**Zips kept, unzipped files not** — 597 MB/yr against a 70 MB zip, and it keeps the manifest
SHA-256 verifiable, which it is *not* for the annual product.

| | φ (shape) | sd yr | φ (amplitude) | obs p2p | unexplained |
|---|---|---|---|---|---|
| NH `gpp` | 49.26 | 2.62 | 54.60 | 1.699 | 10.8 % |
| NH `psnnet` | **49.96** | 2.93 | **55.49** | 1.747 | 11.4 % |
| SH `gpp` | −10.86 | 4.22 | −28.17 | 0.736 | 14.3 % |
| SH `psnnet` | **−16.14** | 2.67 | **−32.15** | 0.845 | 12.8 % |
| *shipped* | 75.0 / −30.0 | | | *2.801 / 0.742* | |

**`gpp` and `net_photosynthesis` BRACKET NPP** and both are carried: GPP is less rectified than
NPP (autotrophic respiration runs in the shoulder seasons) so its φ is biased **equatorward** —
toward the convenient answer; PsnNet omits only growth and live-wood respiration.

**Rectification is real** — the observed NH shape sits ~11° poleward of the insolation-weighted
aggregate, so a poleward φ was never indefensible. **Shape and amplitude want different
latitudes**, and 11 % (NH) / 13 % (SH) of the cycle is residual **no single latitude explains**.

**By-product: `seas_lag_p` is measured.** NH **+0.8 to +1.0 months** against a fitted 2.17; SH
**−2.1 to −2.9**, a *lead*. **One global `seas_lag_p` cannot be both** — a structural limitation
of the term, not a mis-set value. **Left open.**

### 2c. Which FORM does the shape want? (`diag_seas_rectification.R`) — the cheap check

Offline, on data already on disk, no model runs. Four forms, each adding exactly one parameter to
the incumbent, all window-integrated with a free shift, scored as rms residual ÷ observed p2p:

| case | A (incumbent) | B1 threshold | B2 power | C amplitude |
|---|---|---|---|---|
| NH `gpp` | 10.8 % | 10.8 % (c = 0) | 10.5 % (γ 1.52) | **7.1 %** (φ 74.2, A 0.49) |
| NH `psnnet` | 11.4 % | 11.4 % (c = 0) | 11.0 % (γ 1.60) | **7.4 %** (φ 74.8, A 0.50) |
| SH `gpp` | 14.3 % | 14.2 % | 12.9 % | 12.5 % |
| SH `psnnet` | 12.8 % | 12.8 % (c = 0) | 12.2 % | 11.8 % |

**B1 buys NOTHING** — the threshold optimises to zero and *chooses* to be the incumbent. (The
offline fit that produced 75 recorded the same thing: "the light threshold optimised to ZERO".)
**B2 buys 4–9 %.** **C buys 34–35 % in the NH.**

**And C's latitude is genuinely determined in the NH**, which is what makes this a finding rather
than an artefact of an extra parameter. Residual with A re-optimised at each φ:

```
NH_psnnet   38.35:12.7%/A1.38  45:12.0%/A1.12  50:11.4%/A0.96  55:10.8%/A0.83
            65:9.3%/A0.62      75:7.5%/A0.49   85:8.3%/A0.44          <- interior minimum at 75
SH_psnnet  -15.75:12.9%/A0.97 -20:12.5%/A0.77 -25:12.2%/A0.61 -30:12.0%/A0.50
            -40:11.9%/A0.36   -50:12.2%/A0.30                        <- FLAT: not determined
```

**So the offline fit that chose 75 was right about the SHAPE.** Polar night at 75 N is a better
emulation of a rectified boreal growing season than any lower latitude's smooth curve. What was
wrong is that the model had **no way to scale it**, so 75's shape arrived with 75's amplitude
(2.801 peak-to-peak against an observed 1.747) — and `seas_T_amp_NH = 48 K` was the cancellation
that fixed the amplitude. **The SH latitude is NOT determined once amplitude is free**; choose it
on the fit or on interpretability.

---

## 3. THE PROFILE — four passes, and the answer (`diag_phi_eff_profile.R`)

Every case patches **both cores**, rebuilds in its own `tempdir()`, passes **three gates**, and
**re-optimises the seven parameters the seasonal cycle identifies** (`seas_T_amp_{NH,SH}`,
`seas_lag_p`, `sst_seas_amp_{NH,SH}`, `npp_frac_NH`, `q10`) on the full post-08-20g posterior.
A frozen profile would be worthless: moving φ while holding `seas_T_amp_NH` at 48 K breaks the
NEP/respiration cancellation **by construction**.

**The gate that matters was MUTATION-TESTED.** Disabling the C++ patch while leaving the R patch
in makes the R-vs-C++ derivative parity check fire (`max|dR-dC|/max|dR| < 1e-12 is not TRUE`), so
a worker cannot run the incumbent's constant under a challenger's label.

Headline cells (full table in `calibration/output/phi_eff_profile*.rds`; the report merges every
pass automatically):

| φ NH | φ SH | amp NH | amp SH | REOPT | `seas_T_amp_NH` | `npp_frac_NH` | sig MLO |
|---|---|---|---|---|---|---|---|
| 75 | −40 | 0.49 | 0.36 | **−2025.2** | 10.75 | 0.555 | 0.0680 |
| **75** | **−30** | **0.49** | **0.50** | **−2027.7** | **10.77** | 0.552 | 0.0680 |
| 75 | −15.75 | 0.49 | 1 | −2037.5 | 10.92 | 0.554 | 0.0681 |
| 65 | −30 | 0.60 | 0.50 | −2052.7 | 10.39 | 0.549 | 0.0689 |
| 55 | −30 | 1 | 0.50 | −2057.3 | 15.04 | 0.492 | 0.0701 |
| 55 | −15.75 | 1 | 1 | −2066.9 | 15.33 | 0.495 | 0.0704 |
| 50 | −15.75 | 1 | 1 | −2071.4 | 11.68 | 0.534 | 0.0699 |
| 45 | −30 | 1 | 1 | −2187.3 | 10.82 | 0.684 | 0.0737 |
| 38.35 | −30 | 1 | 1 | −2184.2 | 6.55 | 0.728 | 0.0716 |
| **75** | **−30** | 1 | 1 | **−2576.0** | 38.61 | 0.459 | 0.0788 |

*(observed: `seas_T_amp_NH` 11.45, `npp_frac_NH` 0.594, sig MLO 0.0528, MLO p2p 6.754)*

**Four things this says, in order of how much they matter:**

1. **The shipped configuration loses by 548 log-units to ITS OWN LATITUDES with the two measured
   amplitude factors applied.** Nothing about (75, −30) needs to move; the whole gap is amplitude,
   and both factors are measurements. (75, −40, 0.49, 0.36) is 2.5 better and (75, −15.75, 0.49, 1)
   is 12 worse — the SH latitude remains undetermined, exactly as §2c's flat SH profile says.
2. **`seas_T_amp_NH` comes home**: 10.92 at the best cell against a measured 11.45, from 38.61 at
   the shipped one. **20d §6's cancellation hypothesis is confirmed by its own repair.**
3. **The hemispheres INTERACT and a 1D profile misleads.** At SH = −30 the NH optimum is 38–45 and
   75 loses by ~390; at SH = −15.75 the ordering **reverses**. The coupling is real —
   `seas_lag_p`, `q10` and `npp_frac_NH` are global, not per-hemisphere. Pass 1 was a 1D slice and
   was read as one only because pass 2 filled the plane in.
4. **SH −15.75 with amp 1 and SH −30 with amp 0.50 are near-equivalent** (−2066.9 vs −2057.3 at
   φ_NH 55), exactly as §2c's flat SH profile predicts.

### ⚠ WHAT IS STILL MARCUS' CALL

**The measurements do not choose between two configurations that both work.** Both are defensible
and they mean different things:

- **(i) Keep the shipped latitudes, apply the measured amplitude factors.**
  `CCX_SEAS_PHI_EFF` unchanged at (75, −30); `seas_npp_amp_{NH,SH}` = (0.49, 0.50) as **measured
  constants**. Physically: *the NH's productive season is shaped like the light cycle at 75 N —
  polar night is the off-switch — but the swing is half what that latitude's light alone would
  drive.* **−2027.7, i.e. +548 on the shipped configuration**, best on the shape data, no new
  code, and no latitude moves. Keeps a constant whose NAME still misdescribes it.
- **(ii) Move the latitudes to the measured shape values,** (50, −16), amplitudes 1. Physically:
  *the productive land sits where MOD17 says it sits, and its cycle follows the light there.*
  **−2071.4, so it loses ~44 to (i)** and ~3.5 points of shape residual, but the constant then
  means what it says, which for a pedagogical model is worth something real.

**Pass 4 settled the arithmetic: (i) wins by ~44 and needs no latitude change.** My recommendation
is therefore (i) with the constant RENAMED — it is the best fit, the best shape, the
measured amplitudes, and no new code; and renaming (`CCX_SEAS_NEP_SHAPE_LAT`, or a comment that
says plainly "this is a SHAPE proxy for a rectified growing season, not the NPP centroid") removes
the only thing wrong with it. **Not done — it is a naming/pedagogy decision, and Marcus owns the
pedagogy.**

**Either way `seas_npp_amp_{NH,SH}` stops being an identity default and becomes measured
constants.** They are currently absent from `CCX_PARAM_TABLE` and never fitted; that should stay
true — they are **measurements**, not parameters.

---

## 4. `npp_frac_NH` — LANDED (§5 of 20d is CLOSED)

Marcus took **option (a)**, a prior on the 1750 parameter, on the pedagogical-product criterion.

**The circularity objection is priced, not argued** (`diag_npp_frac_anchor.R`): `luc_scale` ±30 %
moves the anchor by **0.0013**, `tau_soil_slow` ±30 % by 0.0012, `tau_wood` ±30 % by 0.0003 — an
order of magnitude below the 0.04 prior width and below MOD17's own 0.0135 interannual sd. Option
(b) would have **relocated** the circularity into a direct `npp_frac_NH`↔`luc_scale` correlation
and added a likelihood stream: harder to calibrate, not easier.

**It ships as the FIXED POINT, 0.5986119, not the audit's 0.6136.** The inversion is implicit
(cleared fraction = `cum_luc / land0`, and `land0` ∝ `npp_frac_NH`), so evaluating it at the
incumbent's fitted 0.4662 is not self-consistent — and the **+0.0149** difference is larger than
every other model-dependence in the table.

Prior `dnorm(x, NPP_FRAC_NH_ANCHOR_1750, 0.04)`; **the width is a stated judgement**, like
`SST_SEAS_LOGSD`, because MOD17's interannual sd is the wrong uncertainty and no bracket exists on
disk. The old mode now sits at **−3.31 σ**, which is the point.

**And the profile vindicates it from a different direction.** The audit's −794 veto on raising
`npp_frac_NH` was **an artefact of φ = 75**: re-optimised, the parameter runs 0.459 at the shipped
configuration but **0.55–0.62 wherever NEP is de-amplified** — the fit asks for the observed share
by itself once the NEP channel is not over-driven.

---

## 5. WHAT IS STILL BROKEN, and is NOT a φ_eff problem

- **`sst_seas_amp_NH` = 0.33–0.54 at EVERY configuration** against an observed **2.237** (−12.9 σ
  under the re-anchored prior). Nothing in this arc moved it. The NH ocean channel's rejection is
  its own defect and 20d §6 does not explain it. **This is the next real question.**
- **The MLO cycle still undershoots**: 5.78 ppm at the best cell against 6.754.
- **The isotopic signature still does not close**: 0.0681 against 0.0528. It improved from 0.0788
  and stopped.
- **`seas_lag_p` cannot be both hemispheres' lag** (+0.9 NH, −2.1 SH, one global parameter at 1.73).
- **`test-fluxes.R:99` still fails by design.** 20d §4d's option (ii) — evaluate `tau_turn` on an
  annual mean rather than month 1 — still looks right and is still not done.
- **`enso_share` 50/50** remains the cheapest unsourced split, with GFED already on disk.

---

## 6. FILES

**New:**
- `calibration/diag_npp_eff_latitude.R` — the annual-product measurement (§2a).
- `data-raw/download_mod17_gpp8d.R` → `data-raw/downloads/mod17_gpp8d/*.zip` (gitignored).
- `data-raw/build_npp_seasonal_shape.R` → `data/obs_npp_seasonal_shape.rds` (§2b).
- `calibration/diag_seas_rectification.R` — the offline form test (§2c).
- `calibration/diag_phi_eff_profile.R` → `calibration/output/phi_eff_profile{,_2d,_amp,_amp2}.rds` (§3).
- `calibration/diag_npp_frac_anchor.R` — provenance for a shipped constant (§4).

**Edited:** `R/constants.R` (2 new constants), `R/calibrate.R` (`npp_frac_NH` prior +
`NPP_FRAC_NH_SD`), `tests/testthat/test-constants.R` (ledger), `tests/testthat/test-likelihood.R`
(the tie), `DATA.md` §3d, `CHANGELOG.md`, `data-raw/downloads/MANIFEST.csv` (5 new entries).

---

## 7. TRAPS FOUND THIS SESSION

Everything in 20d §8 still applies. New:

- **`ccx_const()` is NOT callable at `CCX_PARAM_TABLE` construction time** — `R/calibrate.R`
  sources before `R/constants.R`. A prior *closure* can call it (it runs later); an `init` cannot.
  Hence the literal-plus-tie-test idiom, which `pump_grad` already used.
- **A one-shot inversion is not a fixed point.** The `npp_frac_NH` anchor depends on itself
  through `land0`; the difference between the two is +0.0149, larger than every model-dependence
  it was being compared against. **Iterate implicit inversions, and assert the fixed point.**
- **A circular time shift has a DIRECTION, and getting it backwards is silent.** It returns a
  plausible φ with a sign-flipped lag. Gated by recovering a known (φ, lag) from a synthetic
  target — do not trust an FFT or a roll without one.
- **The last MOD17 composite of a year is 5–6 days, not 8.** Treating it as 8 inflates the winter
  end of the NH cycle, which is exactly the end carrying the rectification signal.
- **`net_photosynthesis` is in the 8-day file** and is much closer to NPP than `gpp`. Anyone
  reaching for GPP alone is taking the equatorward-biased answer.
- **A 1D profile of a 2D surface with an interaction reads as an answer.** Pass 1 said "38–45";
  pass 2 reversed it. Fill the plane before concluding.

---

## 8. OPENING THE NEXT SESSION

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-20e_phi_eff_measured.md`. **§3's "WHAT IS STILL MARCUS' CALL" is the
> one open decision** — configuration (i) or (ii) for `CCX_SEAS_PHI_EFF` + `seas_npp_amp`. Once
> that lands, **the refit §4 of 20d owes is next** (~overnight, single arm; the last two-arm refit
> took 32.6 h) and must not start before it — `ccx_path_relocates`. **`sst_seas_amp_NH` at −12.9 σ
> is the next real defect and this arc did NOT touch it.** Do not read any `logpost`/`hessian`/
> evidence out of the arm rds files: the priors have changed twice since they were written.
