# Handoff — CarbonCycleEmulator, 2026-08-11

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `main`.
Supersedes `handoff_2026-08-10b_bomb14c_and_sampler.md` — both of its blockers are cleared.
Test suite: **371 pass / 0 fail / 2 skip** (`Rscript tests/run_tests.R`; the 2 skips are
seacarb, not installed). Was 174/0/2.

---

## 1. Headline

Marcus's call was **fix the §5 blockers before building the app**. Both are fixed, the model
was recalibrated, and the app is built. One new problem replaced them, and it is a better
problem than the ones it replaced.

1. **The `-Inf` wall was the RK4 explicit-diffusion stability limit.** Controlled, gated,
   changes no existing result. §2.
2. **The AR(1) error model was laundering model discrepancy into free noise** — 812 monthly
   CO₂ observations were worth **n_eff = 0.8**. Retired for annual values + an explicit
   seasonal statistic. §3.
3. **Recalibrated: CO₂ now fits (422.2 ppm at 2024 vs ~424 observed, MLO annual residual rms
   0.99 ppm). ¹⁴C does not.** `bomb_total` rails at **+4.60σ**, 48 % above a citable prior. §4.
4. **The Shiny app is built and runs**, six tabs, live model runs. §5.
5. **Production MCMC is still not launched**, deliberately. §6 says what to do first.

---

## 2. Blocker 1 — the solver wall (CLEARED)

Not a mystery. Interior diffusion is integrated explicitly, so a hard-coded `substeps = 4L`
caps `kz`. Bisection on the NA threshold against the diffusion operator's largest eigenvalue:

| h_ml (m) | substeps | empirical NA threshold | analytic | ratio |
|---|---|---|---|---|
| 75 | 4 | 155,319 | 155,366 | 1.000 |
| 75 | 8 | 310,694 | 310,732 | 1.000 |
| 75 | 16 | 621,433 | 621,464 | 1.000 |
| 30 | 4 | 92,896 | 93,754 | 0.991 |
| 200 | 4 | 178,231 | 177,409 | 1.005 |

`ccx_substeps_for()` (R/model.R) now derives the count from that eigenvalue — exact and
trajectory-independent, since it is linear in `kz` and independent of state. Floored at
`CCX_SUBSTEPS_MIN = 4L`, so **nothing existing changed**: `kz` must clear ~155,000 (**+6.2σ**
on its prior) before the count moves. `ccx_run()` / `ccx_run_fast()` default to
`substeps = "auto"`.

Air-sea stiffness is deliberately **not** in the criterion — it can dominate the Jacobian at
low `kz` (15× the diffusion eigenvalue at k_w = 6000, h_ml = 30) but stays ~13× below the RK4
budget and would need k_w ≈ 80,000 (+11σ) to bind. Rather than carry a second closed form with
a fudge factor for its Revelle-driven growth along the trajectory (measured up to 3.9×),
`ccx_run_fast()` escalates on NA up to `CCX_SUBSTEPS_MAX = 256L`.

**`test-stability.R` is mutation-tested**: with the controller forced back to the old fixed 4,
`kz` ∈ {175,790, 4e5, 1e6} must all still fail. Otherwise the "no NAs" test could pass because
the cases were never unstable.

**Generalisable lesson:** an `anyNA` → `-Inf` guard in a likelihood is a *silent prior*. Before
believing a posterior boundary, check whether the integrator can represent the region at all.

---

## 3. Blocker 2 — the AR(1) error model (CLEARED)

Worse than the previous handoff estimated. Measured at the 2026-08-10 mode, MLO CO₂:

| ρ | n_eff (of 812 monthly) | log-units lost to a +50 ppm bias |
|---|---|---|
| **0.998 (the mode)** | **0.8** | **13.7** |
| 0.95 | 20.8 | 3,391 |
| 0 (independent) | 812 | 1,274,218 |
| annual means, σ = 2 ppm | 69 | 27,462 |

67 years of the Keeling curve carried the weight of **less than one independent observation**.
The residuals genuinely *are* that autocorrelated (lag-1 **0.998** MLO, **0.9998** SPO), so
AR(1) was describing them faithfully — and that is the trap. They are **model discrepancy, not
noise**, and AR(1) reclassified discrepancy as free noise, which is why `q10` could sit at 0.28.

Two further defects found while measuring it, either fatal alone: applied on **observation
index, not time** (SPO's 16-month gap counted as one step), and one `rho` shared across four
series of different sampling density.

**Marcus chose: annual values, independent errors, plus the seasonal cycle as an explicit
per-year harmonic statistic.** Rejected: capping ρ at 0.90 (the cap becomes the answer — an
analyst-chosen effective sample size wearing a fitted parameter's clothes); explicit per-stream
bias parameters (4+ more on an 18-parameter, 2.4e6-condition-number problem, and ρ would still
rail); continuous-time AR(1) (fixes the sampling defect, leaves the loophole).

`ccx_year_harmonic()` fits, per calendar year, `v ~ 1 + (t − midyear) + sin(2πφ) + cos(2πφ)`.
Intercept = deseasonalised, detrended annual level, immune to partial month coverage; sin/cos =
the seasonal statistic. **The same estimator runs on model and observations**, so neither NOAA's
deseasonalisation nor the model's seasonal shape has to be trusted separately.

`rho` retired: **18 → 17 parameters**, scored terms **4,713 → 632**.

**Δ¹⁴C went annual too, as a consequence.** The Hua et al. (2022) zonal record is a *smoothed
monthly compilation* fitted to sparser samples, so its 939 monthly values per hemisphere were
never 939 independent measurements. Leaving them monthly while thinning CO₂ would have
relocated the swamping rather than removed it.

**Tried and rejected mid-implementation:** scoring the seasonal cycle as the multi-year *mean*
harmonic (4 terms). It made the seasonal cycle weaker than its own side effect — moving
`seas_amp_NH` 20 → 24 GtC/yr cost 1.2 log-units on the seasonal term but 6 on the CO₂ *level*
term, via rectification against the log fertilisation term. Per-year scoring (~50 pairs per
station) restores the ordering: 62 log-units against the level term's 6.

**Performance regression caught:** the first implementation called `ccx_year_harmonic()` on four
model series inside the MCMC loop, taking the posterior evaluation **0.046 → 0.718 s** (40 h for
a production run). The model is on an exact monthly grid, so every full year shares one design
matrix and the reduction is a single 4×12 by 12×N product. Back to **0.046 s**, gated against
the general estimator.

---

## 4. The recalibration, and the new problem

Mode-find re-run: **126 min, 164,635 evals, −25,999 → −2,359.3**.
`calibration/output/mode_fit.rds`.

| | 2026-08-10 mode | 2026-08-11 mode |
|---|---|---|
| `q10` | **0.280** (respiration *fell* with warming) | **4.14** |
| `kz` | 175,790 — at the solver wall | **8,354**, needs only the floor 4 substeps |
| `sigma_co2` | 0.0744 ppm (collapsed) | 0.301 ppm |
| Hessian condition number | 2.4e6 | **8.29e4** |
| MLO CO₂ annual residual | mean +6.6, rms 13.6 ppm | **mean −0.15, rms 0.99 ppm** |
| CO₂ at 2024 | — | **422.2 ppm** vs ~424 observed |
| Ocean sink 2014–23 | — | **3.26** vs GCB **3.19** GtC/yr |
| Land sink 2014–23 | — | 2.98 vs GCB 2.47 (high, inside the inflated σ) |

`run_modefind.R` now reports each parameter's position in its own prior's tail and flags
|z| > 3 — added because the 2026-08-10 mode was accepted for a day before anyone noticed
Q10 < 1. **Three fired:**

| flagged | mode | z | reading |
|---|---|---|---|
| `bomb_total` | **151.2 kmol** | **+4.60σ** | prior lnorm(log 102, 0.10) from Naegler & Levin's citable 99.3–104.9. The fit wants **48 % more bomb ¹⁴C than was produced.** |
| `sigma_d14c` | 45.8 ‰ | +3.01σ | the Δ¹⁴C error term inflating to absorb a poor fit |
| `q10` | 4.14 | +3.46σ | right sign at last, but above the ~1.5–2.5 usually quoted |

Δ¹⁴C residuals: NH rms **47 ‰** overall, **69 ‰ inside 1960–70**, against a bomb-window mean
bias of only −5.3 ‰. **The inflated source has fixed the level and left the shape wrong** — the
failure mode §2 of the previous handoff predicted.

---

## 5. The app (BUILT)

`app/global.R` + `ui.R` + `server.R` + `app/R/plots.R`; `app/DEPLOY.md` has the shinyapps.io
notes. Six tabs per DESIGN §7. Verified rendering in a browser, not just that the builders run.

```bash
Rscript -e 'shiny::runApp("app", launch.browser = TRUE)'
```

- **shiny + bslib + ggplot2 only.** No plotly/DT/shinyWidgets — shinyapps.io memory is the
  binding constraint.
- **Nothing precomputed.** Counterfactual rerun ~60 ms, three coupled SSP futures ~0.5 s, a
  matched pulse pair over 1750–2300 ~0.65 s. No cached figure can drift from the model.
- **Takeaway sentences are computed from the displayed run**, never written. A hard-coded "the
  ocean has absorbed a quarter of our emissions" becomes a lie the first time calibration moves.
- **A non-dismissible provenance banner** names the parameter set on every tab, and ignores a
  saved fit whose `param_names` don't match — so the quarantined 18-parameter fits can't
  silently misalign into 17 slots.

**New model capability the app needed:** `revelle_frozen`, a mechanism switch in **both**
model.R and ccx_core.cpp (parity 4e-17), because frozen Revelle can't be a parameter change —
buffer saturation is emergent. The PI buffer factor falls out at **9.47 NH / 9.79 SH**, inside
the observed ~8–10 (an emergent check, not a tuned input). Frozen gives 46.5 ppm less airborne
CO₂ and 152 GtC more ocean carbon at 2100 on SSP2-4.5.

**`R/mechanisms.R`** holds the counterfactual switches, each tested for a measurable effect
**and the right sign** — a switch that silently did nothing would look identical to a working
one in the UI. DESIGN's separate "no CO₂ fertilization" and "no land sink" toggles are
**merged**: in this model they are one mechanism (`beta`), and offering two would imply a
distinction the model does not have. The app says so.

**Future temperature now comes from FaIR** (Marcus's call), replacing a silent bug:
`ccx_build_forcing()` extrapolated IGCC flat past 2024, so every future run sat at +1.53 °C
with the q10 and solubility feedbacks off. `FaIRtoFrEDI/run_fair_ssps_for_ccx.py` exports 5
SSPs 1750–2500; `data-raw/build_climate_module.R` fits CO₂→ERF (quadratic in ln(CO₂/CO₂_PI),
rmse 0.029 W/m², **F₂ₓ = 3.85 W/m²**) and ERF→T (3-timescale IRF, d = 1.56 / 14.2 / 261 yr,
**ECS-equivalent 3.24 K**, rmse vs FaIR **0.010–0.030 °C after 2050**).

Exported as forcing rather than as a GMST path **because a prescribed temperature cannot
respond to a pulse** — it would show a pulse changing CO₂ while the climate sat still, the
exact misconception the Pulse Lab exists to dispel. Coupling is an outer loop over whole runs
(6 passes, 0.17 s), not a climate module inside `ccx_deriv()`, which would have meant porting
one into the C++ core and rebuilding its parity gate. **The feedback is not negligible:**
SSP5-8.5 at 2100 is **+111 ppm and +0.32 °C** coupled versus one uncoupled pass.

**Two errors of mine en route, both caught by the gates:** I first *interpolated* the pooled
(CO₂, erf_co2) pairs — they are ensemble means over 841 configs with differing forcing scales,
and CO₂ is **not monotone in time** (SSP1-1.9/1-2.6 peak and decline), so sorting by CO₂
interleaved the rising and falling limbs (334 descending steps, worst −0.147 W/m²), which
`monoH.FC` cannot repair because it is monotone only for monotone *input*. **The 0.000 residual
that seemed to justify it was vacuous:** a spline through every point interpolates by
construction and can never show scatter. And a pure log law costs 3× the error.

---

## 6. THE OPEN PROBLEM: ¹⁴C

Marcus raised two hypotheses. Here is what the arithmetic says about each, and they rank
differently than they might look.

### 6.1 Correction first: the land is NPP, not GPP

**The gross-flux fix was applied to air-sea and interhemispheric exchange only.** The land
uptake flux in `R/model.R:169` is still **NPP**, and the reason the ocean argument does not
transfer is worth stating, because it is easy to over-generalise:

The air-sea interface was singular for isotopes because it was represented by its **net** flux,
which is *exactly zero* at preindustrial equilibrium — so a net-only interface transferred no
¹³C or ¹⁴C at all. The land is not like that. It is a **closed loop of genuine one-way fluxes**:
NPP in (60 GtC/yr), litterfall veg→soil, heterotrophic respiration soil→atm — all nonzero at
equilibrium. No singularity, and isotopes do exchange.

### 6.2 The third level you are remembering, and whether it matters

GPP → NPP → NEP. **NPP = GPP − autotrophic respiration**, which includes leaf/foliar, stem and
root respiration; **NEP = NPP − heterotrophic respiration**. GPP is roughly 2× NPP globally, so
the model omits ~60 GtC/yr of autotrophic respiration as an explicit two-way exchange.

**The argument that it does not matter:** autotrophic respiration returns carbon fixed very
recently, so it carries essentially the atmosphere's own current ¹⁴C signature. Isotopically it
is a futile cycle.

**The argument that it might:** that only holds to the extent the lag is short compared with
how fast atmospheric Δ¹⁴C is changing. During the bomb rise it was changing extremely fast.
Steepest observed: **+344 ‰/yr (1962→1963)**. A lag `L` in autotrophic respiration creates a
disequilibrium of 344·L on a 60 GtC/yr flux:

| effective lag | disequilibrium | missing ¹⁴C flux | on the atmosphere |
|---|---|---|---|
| 15 days | 14 ‰ | 0.86 GtC-eq/yr | **1.5 ‰/yr** |
| 1 month | 29 ‰ | 1.72 | **2.9 ‰/yr** |
| 3 months | 86 ‰ | 5.16 | **8.8 ‰/yr** |

**Verdict: real, but second-order, and not the leading candidate.** Leaf respiration draws
largely on same-day-to-same-week photosynthate, so the effective lag is probably days to weeks,
putting this at a few ‰/yr against a **69 ‰ rms** bomb-window misfit. It would act as a fast
damping term — lowering the peak, slowing the initial decline — which is the right *kind* of
shape correction, just not big enough on its own.

**Caveat on that verdict:** the lag is the whole calculation and it is not well constrained
here. If a large share of autotrophic respiration draws on stored non-structural carbohydrate
rather than recent photosynthate, the effective lag is months and this moves to first-order.
That is a literature question, not a modelling one, and it is worth ten minutes before dismissing.

### 6.3 The ocean hypothesis is stronger — and the arithmetic makes it sharper

Three independent diagnostics, all pointing at the diffusion-only ocean.

**(a) The ¹⁴C production shortfall is an INVENTORY problem, not a ventilation one.** This is
provable rather than arguable. In steady state production = total decay = λ × ¹⁴C inventory:

| reservoir | C (GtC) | ¹⁴C (GtC-eq) | Δ¹⁴C |
|---|---|---|---|
| atmosphere | 588 | 589 | +2.2 |
| land | 1,508 | 1,508 | +0.0 |
| ocean mixed layer | 334 | 326 | −26.3 |
| ocean interior | 32,492 | 29,665 | −87.0 |
| **TOTAL** | **34,923** | **32,088** | **−81.2** |

λ × 32,088 GtC-eq = **382 mol/yr**, exactly what the spinup solves. But **even at Δ¹⁴C = 0
everywhere, this carbon inventory can only support 416 mol/yr.** The canonical ~545 is
**unreachable at this inventory regardless of ventilation** — a 24 % shortfall to the ceiling
before ventilation is discussed. *No amount of `kz` retuning can fix the production diagnostic.*
It needs more carbon.

**(b) The model's ocean DIC is exactly uniform with depth** — surface/deep ratio **1.000**,
forced by the zero-flux spinup condition of pure diffusion. The real ocean's DIC rises ~10–15 %
from surface to deep, because of the **biological pump, which this model does not have**. Model
ocean carbon **32,827 GtC against an observed ~38,000 (14 % low)**. (a) and (b) are the same
fact seen twice.

**(c) The deep ocean is too young — this is your circulation point, and it is measurable.**

| Δ¹⁴C | apparent age |
|---|---|
| model, 3,158 m: **−115 ‰** | **1,005 yr** |
| observed deep ocean −150 ‰ | 1,336 yr |
| observed deep ocean −180 ‰ | 1,632 yr |
| observed deep ocean −200 ‰ | 1,835 yr |

**The model's deepest water is roughly 600 years too young.** Pure vertical diffusion ventilates
the abyss too fast. And the basin structure you named is entirely unrepresentable in one
column: deep North Atlantic and deep North Pacific differ by well over 100 ‰ in the real ocean
(*I have not verified those figures against a source in this repo — treat as recollection*),
and a single diffusive column can only produce one intermediate value.

**The sharp version of the hypothesis: a single `kz` is being asked to serve two processes that
are different in the real ocean.** Bomb-¹⁴C penetration is decadal, thermocline, surface-
intensified. Natural deep ¹⁴C age is millennial and set by overturning. **This was tested and
is CONFIRMED** — see §6.4.

---

## 6.4 THE CHEAP CHECKS, RUN (2026-08-11)

`calibration/profile_kz_ventilation.R` was written for a full conditional profile but is too
slow to be the first tool (~28 min per `kz`; 16 free parameters × 3 Nelder-Mead restarts).
Two cheaper experiments answered the question. Both are in scratch, results below.

### (a) The ventilation map — no fitting required

Deep-ocean Δ¹⁴C at spinup is a function of the ventilation parameters alone, so it can be
mapped directly. Over `kz` ∈ [250, 16000] × `h_ml` ∈ [30, 200]:

- **Deep Δ¹⁴C depends on `kz` essentially alone.** `h_ml` moves it < 5 ‰ across its whole range.
- **The observed −150 to −200 ‰ is reached at `kz` ≈ 3000–4000** (−202 and −166). The mode's
  `kz` = 8354 gives −104. **The fit put `kz` roughly 2× above the deep-ocean-matching value.**
- **Ocean carbon is 32,827 GtC at EVERY cell** — invariant to both parameters. This settles
  §6.3(a)/(b): the inventory shortfall is structural (uniform DIC from the zero-flux condition
  of pure diffusion, i.e. no biological pump) and **no ventilation retune can touch it**.
  The ¹⁴C production ratio never exceeds 0.72 anywhere on the map.

### (b) The trade-off — CONFIRMS the single-`kz` conflict

At each fixed `kz`, re-optimising the parameters that can compensate
(`k_w`, `h_ml`, `bomb_total`, `sigma_d14c`, `sigma_co2`, `beta`, `q10`):

| kz | logpost | deep Δ¹⁴C | prod/canon | **bomb_total** | bomb-win rms | CO₂ rms |
|---|---|---|---|---|---|---|
| 2000 | −2649.2 | −268.0 | 0.62 | **153.1** | 126.6 | 0.99 |
| 3000 | −2516.9 | −202.1 | 0.65 | **154.1** | 94.4 | 0.98 |
| 4000 | −2448.8 | −165.7 | 0.67 | **153.9** | 80.8 | 0.99 |
| 6000 | −2383.1 | −127.1 | 0.69 | **151.7** | 68.2 | 0.98 |
| 8354 *(mode)* | −2359.3 | −104.2 | 0.70 | **151.2** | 69.1 | 0.99 |

**Deep Δ¹⁴C and the bomb window improve at opposite ends of `kz`.** Buying the observed deep
ocean costs **~90 log-units** and takes bomb-window rms from 69 to 81–94 ‰. One diffusivity
cannot serve both the decadal transient and the millennial age. **The fix is structural — an
advective term or a second ventilation timescale — not a retune.**

Note also that `k_w` swings 6808 → 3348 across the table: the optimiser trades surface exchange
against deep mixing to hold total ocean bomb uptake roughly fixed, because that is what the
observed atmospheric decline requires.

### (c) CORRECTION to §6.3 — `bomb_total` is NOT driven by ventilation

**My earlier claim that over-ventilation causes the 48 % bomb inflation is wrong.**
`bomb_total` sits at **151–154 kmol at every `kz` in the table**, including `kz` = 2000 where
the ocean is far less ventilated. Ventilation does not explain it.

Pinning `bomb_total` at the citable 102 kmol and re-optimising everything else:

| | bomb_total | NH peak Δ¹⁴C | bomb-win rms | ocean/land/atm bomb ¹⁴C |
|---|---|---|---|---|
| mode (free) | 151.2 | **960.9 ‰** | 69.1 | 110.0 / 30.3 / 12.5 kmol |
| pinned at 102 | 102.0 | **638.3 ‰** | 191.9 | 74.4 / 20.2 / 8.6 kmol |
| **observed** | 99.3–104.9 | **853.2 ‰** | — | — |

**The model OVERSHOOTS the observed peak by 108 ‰ at its fitted total, and UNDERSHOOTS by
215 ‰ at the correct total.** It cannot match the observed curve at any bomb total. The fit
chooses to overshoot the peak in order to fit the rest of the decline; pinning the correct
total costs **116 log-units** and triples the bomb-window rms.

That is the signature of a **wrong delivery time-shape**, not a wrong sink — and it is exactly
the caveat left open on 2026-08-10: *"a 4.5× one-month step survives at the Part A/B join in
1963.04 — inside this window"*. The bomb source is now the prime suspect for `bomb_total`,
independently of everything the ocean is doing.

### (d) The land: `tau_veg` is an uncalibrated constant sitting on a real tension

`tau_veg` is **fixed at 10 yr and is not in `CCX_PARAM_TABLE`**. It is not innocuous:

| tau_veg | bomb-win rms | CO₂ rms | land bomb ¹⁴C |
|---|---|---|---|
| 3 yr | **59.5** | **11.98 ppm** | 22.0 kmol |
| 5 yr | 62.4 | 7.98 | 24.5 |
| **10 yr (assumed)** | 69.1 | **0.99** | 30.3 |
| 20 yr | 76.6 | 10.68 | 40.5 |
| 40 yr | 83.2 | 21.86 | 53.7 |

**The vegetation turnover CO₂ wants is not the one ¹⁴C wants.** This is where Marcus's
GPP/NPP question actually lands — not in the fast autotrophic-respiration loop of §6.2, whose
magnitude is second-order, but in the *pool turnover* that sets how much bomb ¹⁴C the land
absorbs. It should be freed and calibrated rather than assumed.

### (e) The ocean bomb-¹⁴C inventory — BLOCKED on literature access

The model says **110.0 kmol in the ocean by 2024** (72 % of surviving bomb ¹⁴C). The observed
value could not be sourced: Naegler & Levin 2006 (AGU) returns HTTP 402, and the abstract of
Mouchet (2013), *Radiocarbon* **55**(3):1580–1594, doi:10.1017/S0033822200048505 — "The Ocean
Bomb Radiocarbon Inventory Revisited" — carries no numbers.

**A caution that came out of that abstract anyway:** *"large discrepancies exist among
data-based estimates and model reconstructions of the ocean bomb radiocarbon inventory"*, and
observation-based estimates that lack information about CO₂ invasion are **underestimates**
(supporting Naegler 2009). So this check is less sharp than hoped — the target itself has
method spread of order 10 % or more, and any constraint built from it must carry that.

**What is needed:** the ocean bomb ¹⁴C inventory at a stated epoch, in 10²⁶ atoms / kmol / mol,
with its uncertainty, and ideally the ocean/biosphere/atmosphere partition from Naegler &
Levin 2006. Marcus has offered institutional access — same route as the Scripps files, which
are hand-supplied and tracked in git because `download_data.R` cannot regenerate them.

## 7. What to do next, in order

**Do not launch the production MCMC yet.** 2.6 h of sampling around a mode whose bomb source is
48 % above a tightly-constrained citable prior gives a posterior whose ¹⁴C-derived ocean
ventilation — the thing ¹⁴C is in the model *for* — is not believable.

**Both cheap checks are now done (§6.4).** Revised order:

1. **Re-open the bomb delivery SHAPE.** §6.4(c) says `bomb_total`'s +4.6σ is a source problem,
   not a sink one — the model cannot match the observed Δ¹⁴C curve at any total. Start with the
   Part A/B join at 1963.04 that 2026-08-10 left unresolved. This is the single highest-value
   item and it is independent of the ocean work.
2. **Free `tau_veg`** into `CCX_PARAM_TABLE` (§6.4(d)). It is an uncalibrated constant sitting
   directly on a CO₂-vs-¹⁴C tension. Cheap; do it before anything structural, so the structural
   diagnosis is not absorbing an avoidable parameter error.
3. **Decide on the ocean structure.** §6.4(b) confirms one `kz` cannot serve both timescales.
   The options are an explicit advective overturning loop (already in DESIGN §10's v2 backlog)
   or a second ventilation timescale. This is a design decision for Marcus, not a fix.
4. **Address the ocean carbon inventory** (the biological pump, or at minimum a prescribed
   DIC-vs-depth profile). Watch whether ¹⁴C production moves from 382 toward 545. Note this
   also touches the provisional `OCEAN_DEPTH` / `ALK_SURFACE` constants.
5. **Only then** the GPP/autotrophic-respiration loop (§6.2), if a shape misfit survives. It is
   a cheap addition — a fast two-way land exchange with a lag parameter — but doing it before
   the bomb-shape work risks tuning it to absorb a source error.
6. **Then** production MCMC: 50k × 4, gate on **R̂ < 1.05 AND ESS ≥ 400**. At 0.046 s/eval that
   is ~2.6 h. The app picks up `calibration/output/posterior_draws.rds` automatically and
   switches its banner to "calibrated posterior".

---

## 8. Non-obvious state

- **`calibration/output/quarantine/20260811_ar1_pathology_and_solver_wall/`** holds every
  pre-fix fit with a README. They carry **18** parameters against the current **17** — loading
  one and feeding `u_mode` to a current `ccx_make_logpost()` will not error informatively, it
  will silently misalign every parameter.
- `calibration/run_modefind_bombwin.R` was folded into `run_modefind.R` (they differed only in
  output filename). `recompute_hessian.R` now defaults to `mode_fit.rds`.
- `ccx_ll_ar1()` is renamed **`ccx_ll_ar1_SUPERSEDED()`** and kept runnable, so the diagnosis
  can be reproduced. Do not wire it back in.
- `ccx_build_forcing()` **warns** when it holds GMST flat past the observations. Two existing
  tests now wrap it in `suppressWarnings` with a comment — they check the emissions columns,
  and warning about the column they don't read is correct behaviour.
- The FaIR export lives in `data-raw/downloads/fair_v145_ssp/` with a MANIFEST. Regenerate with
  `source ~/climate-env/bin/activate && python run_fair_ssps_for_ccx.py` **from FaIRtoFrEDI**,
  then `Rscript data-raw/build_climate_module.R` here.
- The climate module's worst year is **1817** (post-Tambora); a 1-yr IRF box cannot track a
  −5 W/m² one-year volcanic spike. max |err| 0.192 °C, identical across scenarios because 1817
  is shared history. Bounded by the gate, not hidden.
- Uncalibrated CO₂ at 2100 ran well above FaIR's own (SSP2-4.5: 620 vs 530 ppm). **Recheck at
  the new mode** — the historical bias that drove it is now gone. Separately, FaIR's
  *emissions-driven* SSP CO₂ is itself below the SSP database's concentration projections
  (~530 vs ~600 ppm for SSP2-4.5 at 2100); flagged, not explained, not this project's problem.
- `SST_PCO2_SENSITIVITY` double-counting check and the other provisional constants are still
  open from 2026-08-09.

## 9. Commits this session

| | |
|---|---|
| `e31c82d` | Solver stability wall: diagnose as RK4 diffusion limit, control it, gate it |
| `9a439d1` | Retire the AR(1) error model for annual values + an explicit seasonal statistic |
| `65ed4e9` | Future temperature from FaIR, coupled to the model's own CO₂ |
| `21e036d` | Frozen-Revelle mechanism switch, in both implementations, under the parity gate |
| `6ca47c3` | The Shiny app: six tabs, live model runs, computed takeaways |
| `20530e7` | Recalibrate on the fixed posterior: CO₂ now fits, ¹⁴C does not |

Plus `c5c2fa0` in **FaIRtoFrEDI** (branch `heat-ed-morbidity`): the SSP climate export driver.
