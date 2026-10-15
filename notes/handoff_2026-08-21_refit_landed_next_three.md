# Handoff — CarbonCycleEmulator, 2026-08-21: the refit landed, and three steps are teed up

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `d33b0c1`.
**Predecessor:** `handoff_2026-08-20e_phi_eff_measured.md` — read it for *how* the seasonal driver
got fixed. This file is for *what happens next*, and §§2–4 are written to be executed.

---

## 0. STATE IN EIGHT LINES

1. **The refit CONVERGED**: mode −1877.9475, `hit_cap` FALSE, verified by an independent
   warm-started restart that moved it 2.3e-4. `calibration/output/pump_arms/mode_fit_pumpN.rds`.
2. **The four seasonal rows went −576.6 → +207.3**, ~784 log-units. That is what the 08-20 arc
   bought, and it is the headline result of the week.
3. **SHIPPED this week:** `seas_npp_amp_{NH,SH}` = 0.4969 / 0.5027 (measured);
   `npp_frac_NH` prior re-anchored at the fixed point 0.5986119; `CCX_SST_SEAS_LAG` = 1.32.
   `CCX_SEAS_PHI_EFF` unchanged at (75, −30) — it is a SHAPE latitude, not a centroid.
4. **⚠ NO UNCERTAINTIES ARE QUOTABLE.** The Hessian is unstable at `h_ml`. `par_mode` is fine;
   `sd_unc`, `cov`, `logdet_negH` and any Laplace evidence are NOT. **§3 fixes this.**
5. **The `seas_T_amp` × ln(`q10`) conflict is the big new finding** and it is a *physical*
   conflict, not a parameterization nuisance. **§2, and it is the most valuable of the three.**
6. **`sst_seas_amp_NH` = 0.467 against an observed 2.237 (−5.97 σ)** — untouched all week. **§4.**
7. **Two tests fail by design**, both in `test-fluxes.R` (:99 and :100), both reported and awaiting
   Marcus. See 20e §6.
8. Still no posterior. The sampler has never converged and nothing here changes that.

---

## 1. WHAT THE MODE LOOKS LIKE

```
beta_max  0.9310   fert_k 503.53   q10 1.0907   k_w 2024.5   h_ml  87.56
kz     6461.42   pump_grad 298.32  tau_ex 1.0319   npp_frac_NH 0.5590
seas_T_amp_NH 25.936  seas_T_amp_SH 1.2959  seas_lag_p 1.6376
sst_seas_amp_NH 0.4668  sst_seas_amp_SH 0.5962  gamma_enso 0.7867
bomb_total 122.22  luc_scale 0.8902  sigma_d14c 6.2805  rep_dC 5.1754
grad_off_co2 -0.2147  grad_off_d13c 0.0931
```

Flagged (|z| > 3): `seas_T_amp_NH` +3.29, `seas_T_amp_SH` −3.70, `sst_seas_amp_NH` −5.97,
`sst_seas_amp_SH` −3.95, `bomb_total` +3.08, `rep_dC` +5.75. Also `q10` at −2.43 σ, and `kz` pinned
at **97.4 %** of its bracket (§5.2h, still unresolved, not one of the three below).

---

## 2. STEP ONE — the `seas_T_amp` × ln(`q10`) conflict. **DO THIS FIRST.**

### The finding, in three numbers

At small amplitude the seasonal respiration channel identifies the **product** `seas_T_amp` ×
ln(`q10`), not either factor:

| | `seas_T_amp_NH` | `q10` | product |
|---|---|---|---|
| **prior centers** | 11.445 (measured) | 2.00 (literature) | **7.933** |
| the 08-18 mode | 48.07 | 1.2613 | 11.16 |
| the 7-parameter profile | 11.08 | 1.2201 | 2.205 |
| **the converged mode** | **25.94** | **1.0907** | **2.251** |

**The two priors JOINTLY imply 3.52× the modulation the likelihood accepts.** So both are fought,
in opposite directions along the ridge — `seas_T_amp_NH` +3.29 σ, `q10` −2.43 σ — and the mode
satisfies neither. **This is not a bad prior on one parameter; it is a real conflict between two
measurements and the CO₂/δ¹³C record.**

### The hypothesis, and it is a specific one

**`seas_T_amp_*`'s prior is anchored on AIR temperature, and the parameter multiplies SOIL
respiration.** `R/constants.R` sources it from the CRU 1961–90 *absolute climatology* — 2 m air
temperature. Soil temperature's seasonal amplitude is strongly damped with depth.

**This exact mistake was CAUGHT for the lag and MISSED for the amplitude.** `CCX_SEAS_T_LAG` is
documented at length in `R/model.R` as deliberately NOT matching the air-temperature value,
*"because this term multiplies SOIL respiration, not air temperature"* — and the 18,944-logL
profile agrees. The amplitude sitting three lines away was re-anchored on air T in 08-20g without
anyone noticing the same argument applies.

**And the arithmetic is consistent with it.** Holding `q10` at its literature 2.0, the implied
soil/air amplitude ratio is **0.28**. That is low against typical 10–20 cm damping (~0.5–0.7) but
the right side of 1, and it is not absurd once snow insulation and the fact that most heterotrophic
respiration is *below* 10 cm are allowed for.

### What to do, in order

1. **Establish that the ridge is real before repairing it.** Profile `seas_T_amp_NH` from 5 to 50 at
   the converged mode with **`q10` re-optimized at each point** (the `diag_phi_eff_profile.R`
   partial-reoptimization idiom — reuse it, do not rewrite it). If the profile is flat in the
   product and the two coordinates trade one-for-one, the diagnosis holds. **If it is not flat, stop
   — the conflict is somewhere else and this whole section is wrong.**
2. **Find a damping factor with provenance, or say plainly that it is a judgment.** A measured
   soil-temperature seasonal climatology would be ideal. If none is cheaply available, the honest
   move is `SEAS_T_SOIL_DAMPING` as a `provisional` constant with a stated range, in the
   `SST_SEAS_AMP_LOGSD` idiom — **not** a silently widened prior.
3. **Re-anchor both land priors** on (air amplitude × damping), keeping the bracket-derived widths
   from 08-20g and widening them by the damping's own uncertainty.
4. **Refit.** ~15 h; the driver now warm-starts (`ARM_WARM`), so start from the current mode.

### What success looks like

`seas_T_amp_NH` inside 1–2 σ **and** `q10` back near 2.0, with the product still ≈ 2.25. If `q10`
stays near 1.1 after re-anchoring, the damping hypothesis is wrong and the conflict is in the
respiration model itself.

**COST:** the profile is ~1 h; the refit ~15 h. **VALUE: highest of the three** — it is the only one
that could change a physical parameter rather than an error bar.

---

## 3. STEP TWO — the `h_ml` Hessian. **Without this there are no uncertainties on anything.**

### What is broken

`[N] curvature step-stability at the mode (eps × 1/3, 1, 3): UNSTABLE at h_ml`. So `logdet_negH`,
`sd_unc`, `cov` and any Laplace evidence in the file are unusable.

**Rule out the wrong explanation first, because it is the obvious one and it is false here.** This
is NOT the piecewise-C1 kink problem (`ccx_hml_kink`): the mode is at **87.56 m** and the nearest
kink is **10.85 m away**. The log even says so.

**The likely cause is the opposite of the usual one — the step is too SMALL.** `ARM_HESS_EPS` =
3e-4 on the unconstrained scale, and `h_ml` is `logit`-transformed on [85, 120], so near the lower
bound du → dh_ml is heavily compressed: **the step reaches 7.12e-4 m**. Curvature measured over
seven ten-thousandths of a meter is reading the integrator's own noise, not the posterior.

### What to do

1. **`calibration/recompute_hessian.R` already exists and does exactly this job** — it sweeps
   candidate steps and picks the largest one whose curvature is stable. It was written for the
   opposite failure (`kz` with a step far too *large*). **Run it at the current mode first**; it may
   simply answer the question.
2. If a single global eps cannot serve both `kz` and `h_ml`, move to a **per-parameter eps vector**.
   That is the real fix and it is not large: the Hessian loop already takes a scalar, and the
   diagonal step-stability scan already reports per-parameter results.
3. **Re-derive `ARM_HESS_EPS`'s comment from whatever the scan says**, and record the vector in the
   output file next to `hml_bound` — the same lesson as `ccx_hml_band_provenance`: a second-order
   block that cannot be reproduced without an unrecorded setting is a trap.

**COST:** hours, not days — no refit needed, the mode is fixed. **VALUE: unblocking.** Nothing
about parameter uncertainty, evidence, or the H-S decomposition can be said until it is done.

---

## 4. STEP THREE — `sst_seas_amp_NH` at −5.97 σ. **The largest single misfit in the model.**

Observed **2.237 K**, mode **0.4668**. It moved 5× in this refit (from 0.0892) and is still **4.8×
low**. **Nothing in the entire 08-20 arc touched it** — it sat at 0.33–0.54 in all 31 φ-profile
cells, so it is independent of the NEP repair.

### What is already known, so it is not re-derived

- The ocean channel contributes **~1 %** of the MLO seasonal cycle, and at the *old* mode turning it
  **off improved** the objective (+11.8 NH, +7.2 SH) — it was not merely inert but harmful.
- The 08-20d phase fix (`CCX_SST_SEAS_LAG` 2.50 → 1.32, measured) recovered **44 %** of the penalty
  for raising it. **56 % survives**, so phase is not the answer.
- Its prior width `SST_SEAS_LOGSD` = 0.25 is a **stated judgment**, not a measurement, and it
  stands in for exactly the gap this section is about: ERSSTv5 gives an **area-weighted** mean and
  the parameter is a **gas-exchange-weighted** one.

### The first move is a per-stream veto profile, not a new download

Profile `sst_seas_amp_NH` from 0.467 to 2.237 at the converged mode, with the rest of the seasonal
block re-optimized, and read the **per-stream** decomposition — the same design that showed the
−794 veto on `npp_frac_NH` was a φ = 75 artifact. **Which rows reject it, and by how much, is the
whole question.** Three outcomes, each pointing somewhere different:

- **the CO₂ seasonal rows veto it** → the air-sea flux response is too strong; suspect the
  solubility-only formulation (no seasonal MLD, no biology) applied to a single hemispheric box.
- **the δ¹³C seasonal rows veto it** → the partition is wrong, not the amplitude; the ocean channel
  is isotopically near-neutral (0.0045) and adding it should *help* the signature, so a δ¹³C veto
  would be genuinely surprising and worth stopping on.
- **the annual/level rows veto it** → the seasonal term is leaking into the annual budget, which
  would be a bug, not physics — the term is supposed to be zero-annual-mean by construction.

**Only if that is inconclusive** is a new observational product worth it: a seasonal air-sea CO₂
flux climatology (Takahashi's monthly ΔpCO₂) would let the flux be *measured* rather than fitted,
which is the move that has worked all week. **Do not start there** — it is a download and a build
against a diagnostic that costs an hour.

**COST:** ~1–2 h for the profile. **VALUE:** it is the biggest misfit, and it is currently
unexplained rather than merely unfixed.

---

## 5. NON-OBVIOUS STATE

- **The driver warm-starts now** (`ARM_WARM = TRUE`, `calibration/run_modefind_pump_arms.R`). It
  re-encodes from `par_mode`, never `u_mode`, and reports the log-post at the warm point so a
  mismatch against the file is visible immediately. **It runs ONE arm (N)** — `ARM_MODES` is a
  one-line change if the pump is ever back in play, and the comparison block reactivates itself.
- **NM and BFGS alternate in cycles** until a cycle gains < `ARM_CYCLE_TOL` (0.5). Progress is
  written every cycle to `mode_fit_pumpN_progress.rds`, so a kill loses nothing.
- **A large BFGS polish gain after stalled NM restarts means NM stalled — NOT that the mode is
  elsewhere.** That misreading cost a (cheap) continuation run on 08-21; the correction is in the
  CHANGELOG and is the kind of inference to make once and not again.
- **`pre_refit_20260820r/`** holds the 08-18 modes with a README naming the three changes that make
  their posterior fields unquotable. Do not splice anything out of them.
- Everything in 20e §9's trap list still applies — especially that unconstrained least squares will
  buy a **negative** amplitude, and that `qr.solve` returns 1e3–1e6 on a near-empty column **without
  erroring**.

---

## 6. OPENING THE NEXT SESSION

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-21_refit_landed_next_three.md`. The refit is DONE and converged;
> §§2–4 are three ready-to-run steps in priority order. **Start with §2** — the measured land-T
> amplitude and a literature `q10` jointly imply **3.52×** the seasonal respiration the data accept,
> and the hypothesis is specific: the prior is anchored on AIR temperature while the parameter
> multiplies SOIL respiration, which is the exact mistake that was caught for the LAG and missed for
> the AMPLITUDE. **§2 step 1 is a falsification test — run it before repairing anything.**
> **Quote no uncertainties from `mode_fit_pumpN.rds` until §3 is done.**
