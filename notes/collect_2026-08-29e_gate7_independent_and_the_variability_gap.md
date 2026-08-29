# COLLECT 2026-08-29e — **THE CHEAP TEST: THE TWO DEFECTS ARE INDEPENDENT**
# And a scoping measurement for ENSO + volcanoes: **the model has only ~⅓ of the observed
# interannual variability, gets Pinatubo almost entirely wrong, and the reason is MECHANISM.**

**Prereg:** `notes/prereg_2026-08-29e_does_the_seasonal_fix_move_gate7.md` (`2ac40ce`).
**Driver:** `calibration/diag_seasonal_fix_vs_gate7.R`. **Output:** `outputs/diagnostics/seasonal_fix_vs_gate7.rds`.

---

## 1. THE CHEAP TEST — ANSWER: **NO. THEY ARE INDEPENDENT.**

**T0 PASS** (land 3.5581, ocean 2.9703, reproducing the gates driver's 3.56 / 2.97).

**T2 — the land sink does not move, at all**, across the whole seasonal-fix family:

| lag | `seas_T_amp_SH` | land sink | z vs GCB | Δ land |
|---|---|---|---|---|
| 1.7677 (mode) | 1.0391 | 3.558 | **+2.30** | — |
| 2.00 | 1.7960 | 3.558 | +2.30 | −0.000 |
| 2.25 | 3.4945 | 3.558 | +2.30 | +0.000 |
| 2.50 | 5.4056 | 3.559 | +2.30 | +0.001 |

**Gate 7 needs −1.148 GtC/yr. The seasonal fix supplies +0.001.** ⇒ **the seasonal partition defect
and the land-sink defect are INDEPENDENT, and gate 7 needs its own arm.**

**⚠ AND THIS IS NOT "THE SEASONAL FIX WAS TRIED AND FAILED" — THE PATH DOES NOT EXIST.**
`ccx_core.cpp:379-381` divides the seasonal respiration factor by `seas_r_norm[h]`, which
(lines 653–659) is the **720-point annual mean of that same factor**: the Jensen rectification is
removed *by construction*, at every amplitude. That was established from the CODE and written into
the prereg **before** the run, precisely so a null here could not be mistaken for a measurement
([[no_power_null]]).

## 2. ⚠ MY T1 GATE FIRED, AND ITS VERDICT LINE IS WRONG

T1 swept `seas_T_amp_SH` alone with a gate of |Δ land| < **0.001** GtC/yr, and printed
**"FAIL — my code reading was WRONG"**. Read the numbers:

    seas_T_amp_SH   1.0391 -> Δland -2.1e-09     3.4945 -> +2.8e-04
                    7.1012 -> +6.8e-04          13.9500 -> +1.5e-03   <- trips the gate

**The code reading is RIGHT; my TOLERANCE was wrong.** It trips only at 13.95 K — *twice outside the
parameter's bracket* — and even there the effect is **1.5e-3 against the 1.148 GtC/yr gate 7 needs,
three orders of magnitude short.** I set an absolute 0.001 instead of deriving it from the quantity
under test ([[derive_gate_from_the_thing]]); derived from the gap it should have been ~1e-2.

**The small residual is real and has a cause worth naming:** `seas_r_norm` normalises ⟨factor⟩ = 1,
but the flux is factor × C_soil(t) and the soil pool has its own seasonal cycle, so
⟨factor·C⟩ ≠ ⟨factor⟩⟨C⟩. **What survives the normalisation is the factor–pool COVARIANCE**, and it
is ~1e-3 GtC/yr at 13.95 K. Not a bug; not useful either.

## 3. SCOPING FOR ENSO + VOLCANOES (Marcus, 2026-08-29)

### 3a. What is already there

**ENSO IS ALREADY WIRED AND FITTED.** `data/forcing_enso.rds` (Niño3.4 anomaly) → `R/forcing.R:661`
→ `ccx_core.cpp:396-397`, `gamma_enso * enso * enso_share[hi]` out of the responsive soil pool.
**`gamma_enso` = 0.85119 at the mode and IS one of the fitted parameters.**

**VOLCANOES ARE NOT IN THE MODEL** — no code, no data, only two mentions in `DESIGN.md`.
⚠ **BUT VOLCANIC COOLING ALREADY ENTERS**, because `ccx_core.cpp:371` is
`q10f = pow(q10, gmst/10)` and `gmst` is the **OBSERVED** GMST anomaly (`data/forcing_gmst.rds`),
which contains Pinatubo. The ocean SST anomalies derive from the same series. **So the thermal
pathway is present; what is absent is everything else.**

### 3b. How much variability is missing — MEASURED

Detrended (cubic) interannual CO₂ growth-rate anomaly, 1959–2023, sd in ppm/yr:

    model, ENSO ON    0.3006
    model, ENSO OFF   0.1725      => ENSO currently supplies sqrt(.3006²-.1725²) = 0.246
    GCB OBSERVED      0.8996      => THE MODEL HAS 33 % OF THE OBSERVED SD

**Correlation of the model's anomaly with the observed one is 0.571** — the model gets the SIGN and
TIMING of interannual variability but only ~⅓ of the amplitude. Consistent with, and sharper than,
gate 4's decadal spread (0.026 vs GCB's 0.051).

### 3c. Event by event — the model misses the big ones almost entirely

| year | event | model anom | obs anom | model / obs |
|---|---|---|---|---|
| 1963–64 | Agung | −0.08 / −0.12 | −0.54 / −0.80 | ~15 % |
| 1982–83 | El Chichón + El Niño | −0.14 / +0.09 | −0.90 / +0.86 | ~13 % |
| **1991–92** | **PINATUBO** | **+0.22 / +0.04** | **−1.83 / −1.94** | **~0 %, WRONG SIGN** |
| 1998 | big El Niño | +0.43 | +2.28 | 19 % |

### 3d. ⚠ THE FIRST-PRINCIPLES CHECK SAYS TEMPERATURE CANNOT DO IT

Pinatubo cooled GMST by ~0.4 K for ~2 yr. Through the model's own path that is
`q10^(−0.4/10)` = `1.13579^(−0.04)` = **0.9949 — a 0.51 % cut in soil respiration**. On ~60 GtC/yr
of heterotrophic respiration that is **0.31 GtC/yr ≈ 0.15 ppm/yr**, against an observed anomaly of
**~1.9 ppm/yr**. **The thermal path can supply at most ~7 % of Pinatubo, and the measurement above
(+0.04 vs −1.94) confirms it delivers ~0.**

⇒ **"Adding volcanoes" is NOT about adding a temperature effect — that is already in, and it is an
order of magnitude too small.** The literature attributes the Pinatubo CO₂ anomaly to **DIFFUSE-LIGHT
FERTILISATION** — stratospheric aerosol scatters sunlight, raising the diffuse fraction and canopy
light-use efficiency, so NPP rises (Gu et al. 2003, *Science*; Mercado et al. 2009, *Nature*).
**That is a MISSING MECHANISM driven by stratospheric AOD, and it needs an AOD series the repo does
not have.**

### 3e. What this implies for the work, and for the pedagogy

- **ENSO**: the coupling exists and is fitted; it is **~5× too weak in amplitude** (1998: 0.43 vs
  2.28) while being **well correlated in timing** (r = 0.57). ⇒ **first measurement: profile
  `gamma_enso` and find out whether the fit WANTS more ENSO and is being blocked, or whether the
  ENSO response shape is wrong.** Cheap, and it decides whether this is a tuning or a structure job.
- **Volcanoes**: needs (i) a stratospheric AOD forcing series, (ii) a diffuse-light NPP term with
  its own parameter, (iii) a decision on whether autotrophic-respiration reduction is separate.
- **Pedagogy — the relationship IS straightforward and DOES match expectations**, in both
  directions: El Niño → warm/dry tropics → land releases → growth spikes; big eruption → cooling +
  diffuse light → land takes up → growth dips. **Both stories are currently muted ~5× in the model**,
  which is exactly what makes them worth fixing for a teaching tool.
