# COLLECT — 2026-08-27g: the Southern-Ocean entrainment channel WORKS, and the fit
# USED IT AS A COUNTERWEIGHT INSTEAD

Scores `notes/prereg_2026-08-27g_so_entrainment_channel.md`, written before a line of the channel
existed. **Six predictions: two PASS, one PARTIAL, one INCONCLUSIVE, one FAILED — and the failure
is the result.**

Scope authorised by Marcus 2026-08-27: **4a** (a second seasonal air-sea channel, no new state),
with 4b held conditional on this residual. Estimator: **`|mean vector|`**, so the standing SPO
partition target is **1.93×**.

---

## THE ONE-LINE RESULT

**The channel does exactly what it was built to do, and the fit declined to use it that way.**
Given the freedom, the optimiser spent the new channel on *permission to double the wrong-phase
solubility limb* — `sst_seas_amp_SH` 0.360 → 0.741, worth **+16.8 of prior** — while keeping the
NET ocean component in austral autumn, where it always was. **The model reproduced the observed
76 % cancellation internally, with its own two limbs.**

## THE SCORECARD

| | prediction | result | verdict |
|---|---|---|---|
| **P0** | method control | bit-identical at zero in both cores; R/C++ parity on; `seas_drivers` kills it; conservation holds | **PASS** (35 assertions) |
| **P1** | channel can deliver ≥ 0.70 ppm at SPO | **0.860 ppm at 10 µmol/kg**, inside the 5–30 physical band; ocean limb goes **0.247 @ 3.68 → 0.614 @ 9.91** | **PASS** |
| **P2** | `sst_seas_amp_SH` ≥ 0.60, z > −5.0, SPO pair ≥ 287.2 | **0.741**, z **−3.43** ✓ ✓ — but SPO pair **286.1** ✗ | **PARTIAL** |
| **P3** | model SPO ocean peak 3.35 → ≥ 6.0 | **3.45** — moved **+0.10 months** | **FAILED** |
| **P4** | SPO residual 1.93× → ≤ 1.70×, MLO in 0.90–1.10 | **1.77×**, MLO **0.97×** | **INCONCLUSIVE** (pass ≤1.70, fail ≥1.85) |
| **P5** | no driver moves further from observed | all four moved TOWARD observed | **PASS** |
| **P7** | MLO control (inversion readable) | **113.9 %** | **PASS** |

**No threshold was moved after the fact.** P2 missed on a gate set at exact equality with no
tolerance, and P4 landed between its own two gates. Both are reported as they scored.

## WHAT P1 PROVES, AND IT IS NOT NOTHING

The channel is a working instrument, and its phase is right. At 10 µmol/kg the whole ocean limb
lands at **0.614 ppm at month 9.91** against an observed **0.522 at 8.52** — size and phase both
near observation, the limb rotating ~6 months. **The mechanism is available.** P3's failure is
therefore not "the channel cannot rotate the ocean limb"; it is **"the fit chose not to."**

## WHY THE FIT CHOSE NOT TO — the residual, which is the point of running 4a first

At the fitted **4.16 µmol/kg** — *below* the 5–30 physical pre-check band, and flagged as such —
the SST limb (now doubled) and the entrainment limb are near-antiphase and largely cancel:

| SPO ocean component | amplitude | peak month | vs observed |
|---|---|---|---|
| mode (channel off) | 0.236 ppm | 3.35 | 0.45× |
| **challenger (channel at 4.16)** | **0.124 ppm** | **3.45** | **0.23×** |
| observed (inversion) | 0.522 ppm | 8.52 | — |

**The ocean component got WORSE.** And the reason is not in the ocean at all:

- **SH land at SPO is 2.05× observed** (1.364 against 0.665), and **0.821 ppm of the model's
  1.364 arrives from the NH** — more than the entire observed SPO land component.
- With the land that large, the total SPO CO2 amplitude has no headroom. It already overshoots at
  the challenger: **−2.5 % → +5.8 %**.
- So a bigger *net* ocean limb is unaffordable, and the only profitable use of the new channel is
  as a **counterweight** that lets `sst_seas_amp_SH` rise and collect prior credit.

**The +11.62 total is +16.78 prior against −5.17 likelihood** — measured, not inferred. The
likelihood cost is thin and spread (`co2_seasonal_MLO` −1.59, `co2_seasonal_SPO` −1.47,
`d13c_seasonal_MLO` −1.45); nothing collapses.

## ⚠ A LIMIT OF MY OWN DESIGN, STATED PLAINLY

**The P2 slice could not bring the land down.** It held `sst_seas_amp_{NH,SH}`,
`seas_T_amp_{NH,SH}`, `seas_lag_p`, `q10` — and `q10` only because of the exact ridge. But:

- `seas_npp_amp_SH` — the **dominant SH-local channel at SPO** (1.390 ppm against `resp SH`'s
  0.092) — **is a measured constant and is not fittable at all.**
- **`tau_ex` IS fittable, carries the 0.821 ppm NH import, and I FROZE IT.**

So the fit was asked to fix a partition while being denied every lever on the half of it that is
too big. **P3's failure may be an artefact of the slice rather than of the physics, and that is a
hypothesis for a NEW pre-registered test — not a licence to re-run this one with `tau_ex` added
and relabel the result.**

Note that 27e **exonerated `tau_ex` as a PARTITION lever** (the SPO δ¹³C-per-ppm ratio moves 4.2 %
over a 5.7× range) — and said in the same breath that **the leak is a SIZE error**. Size is
exactly what is binding here. The two findings do not conflict; the second is the one that applies.

## WHAT THIS SAYS ABOUT 4b

**It does not yet make the case for 4b, and it does not close it either.** The blocker this
residual identifies is **not the ocean's structure** — a second SH ocean column would not reduce
an SH land component that is 2× too big with 60 % of it imported from the NH. **Spending the
largest structural change since the pump on a diagnosis that points elsewhere would be the wrong
order.**

## RECOMMENDED NEXT, in order

1. **Pre-register and run the wider slice**: the seasonal block **plus `tau_ex`**, both arms, same
   matched design. This is the direct test of "the slice, not the physics, scored P3 FAILED".
2. **Only then** decide 4b, with a residual that has had the land lever available to it.
3. Cheap and unrelated, still open from 27g §6: `R/likelihood.R:1028` maps `co2_NH` → MLO with no
   seasonal representation term, i.e. the model asserts MLO's cycle IS the NH hemispheric mean. If
   a hemispheric mean is larger, **the NH leak into SPO gets worse** — which is the quantity
   binding above. NOAA's network measures it.

## Artefacts

- `R/model.R` `CCX_ENT_SEAS_PEAK_MO = 7.50`, `ent_seas_amp_SH` (default 0); twin in
  `src/ccx_core.cpp`; `tests/testthat/test-so-entrainment.R` (35 assertions).
- `calibration/diag_so_entrainment_power.R` (P1), `calibration/diag_so_entrainment_refit.R` (P2).
- `outputs/diagnostics/so_entrainment_power.rds`, `so_entrainment_refit.rds`.
- Suite **1157 pass / 0 fail**.

## Bugs found and fixed en route — all in diagnostics, none in the model

1. The power script's "total ocean" column subtracted a run that **still had the channel on**, and
   reported a dead-flat 0.247 @ 3.68 at every amplitude.
2. `air-sea SH off` in **both** the inversion and the decomposition was `sst_seas_amp_SH = 0`
   only, leaving the entrainment limb running — and in the inversion that case is where the
   **ocean signature s_O** is measured. Substantive, not cosmetic.
3. The inversion's amplitude label read the env var, not the value used, so a run at 4.16 printed
   "channel OFF".
4. A conservation assertion of mine used `ocean_C + land_C + atm_C`, which **omits the
   wood/product pool**.
5. A top-level `if/else if` chain in the refit script — a real R syntax error that incremental
   parsing had hidden behind an earlier `stopifnot`.

## ⚠ PRE-EXISTING, UNRELATED, AND NOT DIAGNOSED

`ccx_make_logpost()` does not reproduce the canonical mode's stored `logpost` at its own `u_mode`:
**−3.3223**, identical at `fbf4b4c`. Entirely in the likelihood; the signature is an
**interhemispheric redistribution** (`d14c_NH` −2.78 / `d14c_SH` +2.44, `d13c_level_MLO` −2.65 /
`d13c_level_SPO` +1.97). Ruled out: both `FORC_` hemispheric flags, `substeps`, the `h_ml` refit
bound. **Flagged, not resolved.** It does not touch anything above — every comparison here is
matched — but **no absolute logpost from a live harness may be quoted against the mode file.**
