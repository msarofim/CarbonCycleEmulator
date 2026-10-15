# WHOLE-MODEL STATUS — CCX, 2026-08-29
# Measured today at the canonical mode `from90`, on the CURRENT (post-option-5) objective.
# Sources: `diag_fit_at_mode.R`, `diag_design_gates_at_mode.R`, both re-run 2026-08-29
# (`outputs/diagnostics/{fit_at_mode,design_gates_at_mode}_20260829.log`), plus today's arc.

> **HEADLINE. The CO₂ record is matched very well and is not the problem. Every remaining defect
> is INTERHEMISPHERIC or SEASONAL STRUCTURE, and three of them have now been shown to be the SAME
> SHAPE: one scalar parameter serving two things that need different values.**

---

## 1. HOW WELL DOES IT MATCH THE OBSERVATIONS? (physical units, not log units)

`bias = mean(obs − model)`. RMSz ≈ 1 means "fits within its assigned uncertainty".

| stream | n | RMS resid | bias | unit | RMSz |
|---|---|---|---|---|---|
| co2_level_MLO | 66 | **0.577** | −0.137 | ppm | 0.58 |
| co2_level_SPO | 59 | **0.532** | +0.024 | ppm | 0.53 |
| co2_gradient | 59 | 0.239 | −0.001 | ppm | 0.68 |
| co2_icecore | 255 | 3.39 | +1.30 | ppm | 0.78 |
| co2_seasonal_MLO | 100 | 0.252 | +0.003 | ppm (harm.) | 1.14 |
| co2_seasonal_SPO | 98 | 0.134 | +0.033 | ppm (harm.) | 1.09 |
| d13c_level_MLO | 45 | 0.0601 | **+0.042** | ‰ | 1.20 |
| d13c_level_SPO | 44 | 0.0610 | **−0.043** | ‰ | 1.22 |
| d13c_gradient | 43 | 0.0196 | +0.00005 | ‰ | 0.78 |
| d14c_NH | 79 | 13.16 | **−2.83** | ‰ | 0.98 |
| d14c_SH | 79 | 11.01 | **+2.73** | ‰ | 1.02 |
| d14c_intcal | 200 | 4.07 | −2.96 | ‰ | 0.38 |
| gcb_ocean_sink | 66 | 0.235 | +0.078 | GtC/yr | 0.59 |
| gcb_land_sink | 66 | 1.084 | **−0.941** | GtC/yr | 0.72 |

**CO₂ concentration: EXCELLENT.** 0.53–0.58 ppm RMS at the stations against a ~120 ppm industrial
rise, the MLO−SPO gradient to 0.24 ppm, ice cores to 3.4 ppm. Every RMSz ≤ 0.78 — the CO₂ rows are
comfortably inside their uncertainties, and by [[ccx_stream_leverage]] they outvote the partition
40:1, which is why the fit protects them.

**⚠ BOTH ISOTOPES SAY THE SAME THING, AND IT IS AN INTERHEMISPHERIC-CONTRAST ERROR.** The level
biases are **equal and opposite** in each isotope:

- δ¹³C: model is **0.042 ‰ MORE depleted at MLO** and **0.043 ‰ LESS depleted at SPO**
  ⇒ its N–S δ¹³C contrast is **≈ 0.085 ‰ TOO STRONG**.
- Δ¹⁴C: model is **2.83 ‰ HIGH in the NH** and **2.73 ‰ LOW in the SH**
  ⇒ its N–S Δ¹⁴C contrast is **≈ 5.6 ‰ TOO STRONG**.

**⚠ AND THE GRADIENT STREAMS CANNOT SEE ANY OF IT.** `co2_gradient` and `d13c_gradient` are scored
TRANSIENTLY with fitted offsets (`grad_off_co2`, `grad_off_d13c`; [[ccx_grad_contrast_sigma]]), so
their biases are ~0 **by construction**. The contrast error is visible only antisymmetrically in the
LEVEL rows. This is a [[no_power_null]] in the objective itself: the rows named "gradient" are the
ones structurally blind to a constant gradient error.

## 2. COMPONENT BY COMPONENT, AGAINST KNOWN PHYSICS

**① Interhemispheric transport — WEAKEST, and STRUCTURAL.** `tau_ex` = 1.159 yr.
- Both CO₂ and δ¹³C gradient streams sit at a **sharp interior optimum** at 1.159 (logL −6.0 at
  1.159 vs −178.8 at 0.80 and −881.4 at 2.00).
- The **bomb-¹⁴C NH→SH lag is 0.97 yr against an observed 1.34 yr** and needs τ ≈ **2.3 yr**.
- **The gradient wins by three orders of magnitude, so the lag miss is a FORCED residual.**
  Measured today: *"the model cannot satisfy both interhemispheric constraints with one `tau_ex`."*
- Physically this is expected of a two-box atmosphere: **one exponential exchange time sets both the
  mean gradient and the pulse lag, but the real atmosphere has a DISTRIBUTED transit time** whose
  mean and shape are independent. The contrasts being too strong (slow) while the lag is too short
  (fast) is the signature of forcing one number to do two jobs.

**② Seasonal cycle / land–ocean partition — the ACTIVE arc, and now DIAGNOSED.** SPO total matches
to ~2 % **by cancellation of two ~2× errors** (SH land 1.92× obs, SH ocean 0.45× and ~5 months out
of phase). Today: the channels are **152.9° apart**, flooring the net at 0.454 × gross, so the model
**cannot cancel more than 54.5 %** where CT2022 needs 74.9 % ([[gross_phase_not_amplitude]]); and the
one free lever that opens that angle, `seas_lag_p`, is **a SCALAR serving BOTH hemispheres**, so
using it costs **−838** with the **NH paying 94 %** ([[one_lag_two_hemispheres]]).
⚠ **The fit WANTS the fix** — given the geometry it raised `seas_T_amp_SH` 1.04 → 3.49 unprompted
and took SH land 1.308 → 1.071.

**③ Land carbon — FAILS ITS GATE.** DESIGN gate 7, 2015–2023: **land 3.56 vs GCB 2.410 ± 0.50 =
+2.30 σ FAIL** (ocean 2.97 vs 3.202 ± 0.40 = −0.58 σ, PASS). The land takes up ~1.15 GtC/yr too
much. Fertilization is Michaelis–Menten with `beta_max`/`fert_k` at ρ = +0.998 and FACE constraining
only the SHAPE ([[ccx_face_fert_k_ceiling]], [[face_ceiling_is_the_headline_in_disguise]]).

**④ Ocean carbon — GOOD, with one flag.** Sink −0.58 σ; the three GLODAP gradient rows are small
(−4.27 / +1.15 / −4.26). The pump is shipped and all three ocean rows close together
([[ccx_pump_ported]]). ⚠ **`kz` still RAILS — 6332 against a bracket top of 6528 (97 %)**: the data
want more vertical diffusion than the bracket allows, and a railed parameter is not a fitted one.

**⑤ Radiocarbon — GOOD on amplitude, wrong on timing.** Bomb peak NH 873.1 vs 855.3 (+2.1 %), SH
669.8 vs 659.8 (+1.5 %), post-peak e-folding 15.0 vs 15.5 yr. The failure is the LAG (①).
⚠ A measured oddity: **`d14c_SH`'s de-biased scatter (10.73) is BELOW the representation floor
(10.96)** — "σ explains nothing" there, i.e. the fitted `sigma_d14c` is doing no work in the SH.

**⑥ Airborne fraction and decadal variability — TOO SMOOTH.** AF 0.413 vs GCB 2025's 0.431 (fine),
but the **decadal spread is 0.026 against GCB's 0.051 — the model is 2× too smooth.** It reproduces
the level and misses the variability. (Gate 12 / Joos IRF **not re-run today**.)

**⑦ Calibration machinery — NO POSTERIOR, and this is a blocker in its own right.** The Hessian is
conditioned **1.11e6**, its softest direction is `h_ml`, whose objective **is not even C1** (pump
`1/eps` kinks), and the other soft direction is the railed `kz` ([[ccx_hessian_is_the_blocker]]).

**⑧ Where the priors are fighting.** Six parameters carry |prior z| > 2 and **five of the six are
seasonal**: `sst_seas_amp_SH` −6.32, `seas_T_amp_SH` −4.64, `sst_seas_amp_NH` −3.48, `rep_dC` +3.38,
`q10` −2.26, `seas_T_amp_NH` +2.20. **The model's prior conflict is almost entirely the seasonal
block** — the fit is being pushed far off independently measured driver values there and essentially
nowhere else.

## 3. OPTIONS, RANKED BY PAYOFF PER UNIT OF WORK

**A. Hemisphere-specific NPP timing: `seas_lag_p` → `seas_lag_p[2]`.** Smallest structural change
(the amplitudes are already per-hemisphere arrays a few lines away). Registered prediction: the NH's
−788 disappears, leaving ~−35 to −50 of SH-side cost against SH land 1.308 → ~1.07. Adds a 22nd
parameter. `SEAS_T_LAG` (respiration phase, also global, also compile-time) is an equally valid
place to open the same angle. **Marcus's design call.**

**B. Break the single-τ interhemispheric transport.** Highest payoff — it touches **four** observables
at once (δ¹³C contrast, Δ¹⁴C contrast, bomb lag, CO₂ gradient). Options: a third (tropical) box; or
a two-parameter transit representation that separates the transit-time MEAN from its SHAPE. Largest
change here; also the one the physics most clearly asks for.

**C. Land sink (gate 7, +2.30 σ).** ⚠ **And there may be a shared cause worth testing first:** the
seasonal arm wants SH soil respiration 3.4× larger, and gate 7 says the land sink is 1.15 GtC/yr too
large. **Check whether the seasonal fix moves gate 7** — cheap, and if it does, two defects collapse
into one.

**D. Decadal variability (0.026 vs 0.051).** The model is 2× too smooth. Candidates: ENSO coupling
(`gamma_enso` already exists), volcanic/climate variability in the land flux. **This is the only
place where higher-frequency forcing genuinely helps — and it is INTERANNUAL, not sub-monthly.**

**E. Unblock the posterior.** Reparameterize `h_ml` or smooth the pump's `1/eps` kinks so the
objective is C1; justify or widen the `kz` bracket it rails against. Without this there is no
posterior, only a mode.

**F. Cheap unrun diagnostics.** Decompose the Δ¹⁴C bias by EPOCH (pre-bomb / spike / decay) — the
record-mean antisymmetry is currently un-attributed and could be a peak-shape error rather than a
gradient error. Re-run gate 12 (Joos IRF) at the current mode.

## 4. ⚠ SHORTER TIMESTEPS — MEASURED, AND IT IS NOT THE ISSUE

**The model already integrates sub-monthly.** `src/ccx_core.cpp:739`: RK4 with
`h = (1/12)/substeps`, and `substeps = "auto"` picks the smallest count that keeps the explicit
diffusion term stable (`ccx_substeps_for()`).

**And the repo already measures that this is converged.** `tests/testthat/test-stability.R`:
*doubling the substeps beyond the controller's choice must move CO₂ by less than 1e-6 relative and
Δ¹⁴C by less than 1e-3 ‰* — and it passes at `kz` = 175,790 and 1e6. **So integration error is ~4
orders of magnitude below the smallest residual of interest (0.134 ppm).**

Three ways a shorter step could still have mattered, all ruled out or too small:

1. **Aliasing of the seasonal cycle.** 12 samples/cycle resolves the first harmonic to ~1 %; a
   monthly MEAN of a sinusoid is reduced by sinc(π/12) = **0.9886, a 1.1 % amplitude effect**. The
   seasonal defects are **10–100 %** errors, and the θ deficit is a **PHASE** error of 12° that a
   symmetric amplitude factor cannot produce.
2. **Nonlinear rectification of sub-monthly variance** (⟨e^T⟩ ≠ e^⟨T⟩ through `q10`; nonlinear
   air–sea flux). **Real, but the model's drivers are smooth analytic seasonal cycles — there is no
   sub-monthly variance present to rectify, and shortening the step creates none.** Getting this
   effect requires ADDING stochastic sub-monthly forcing, which is a different study, and it is
   second-order against a 12° phase error.
3. **Phase resolution.** The phases are set ANALYTICALLY (`SEAS_PHI_EFF`, `seas_lag_p`,
   `SEAS_T_LAG`), not by the discretization. A finer step cannot move an analytic phase.

**⇒ VERDICT: shortening the timestep addresses none of ①–⑧.** The monthly step is the model's
OUTPUT and FORCING resolution, not its integration step, and the integration is already converged.
The defects are structural (one scalar doing two jobs) and parametric, not numerical.

**The one nearby idea that IS worth something is different in kind:** the model is **2× too smooth
decadally** (⑥). That is a missing-VARIABILITY problem at INTERANNUAL frequency — ENSO, volcanoes,
climate-driven land flux — not a timestep problem.

## 5. THE PATTERN WORTH NAMING

**Three defects, one shape: a single scalar serving two things that need different values.**

| scalar | wants to be | and also | evidence |
|---|---|---|---|
| `tau_ex` | 1.159 yr (CO₂ + δ¹³C gradients, sharp interior optimum) | ~2.3 yr (bomb ¹⁴C lag) | gate 5, today |
| `seas_lag_p` | 1.7677 (NH) | ~2.25 (SH, for θ ≥ 164.8°) | 08-29d, −838 |
| `SEAS_T_LAG`, `SEAS_PHI_EFF` | compile-time globals | — | `ccx_core.cpp:168`, 220 |

**The AMPLITUDES are already per-hemisphere arrays (`seas_npp_amp[2]`, `seas_T_amp[2]`). The TIMING
parameters are not.** That asymmetry in the model's design is the single best explanation on the
table for why the seasonal partition and the interhemispheric isotope contrasts both resist fitting
while the CO₂ level record fits beautifully.
