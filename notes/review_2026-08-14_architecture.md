# REVIEW — CarbonCycleEmulator, 2026-08-14: targets, inputs, components, and whether it works

**This is the deliverable §2 of `handoff_2026-08-14_step_back_architecture_review.md` asks
for: a design document, not a to-do list, answering four questions.** The refit was not
started and the pump was not built. Everything numbered below was measured this session
unless it carries a citation to an earlier note; three new diagnostics carry the receipts
(`diag_stream_leverage.R`, `diag_luc_scale.R`, `diag_joos_beta_scan.R`).

Branch `luc-veg-debit`, at `90c8b30` + these diagnostics. `beta` 0.75, `f_luc_wood` 0.

---

## 0. HEADLINE — the four questions have one answer between them

**The shipped default fails two of DESIGN §6's own hard gates, and it fails them because
the objective's weighting made a single stream decide a parameter that four other gates
also depend on.**

Measured, at `ccx_default_params()` (β 0.75):

| DESIGN §6 gate | target | model | verdict |
|---|---|---|---|
| **7 — sinks, 2015–2024** | land 2.36 ± 0.9, ocean 3.22 ± 0.4 GtC/yr | **4.57 / 2.38** | **FAIL, +2.5σ / −2.1σ** |
| **12 — Joos IRF, integrated, TH 20/50/100** | inside 12.2–16.3 / 24.0–36.6 / 39.5–65.2 yr | **10.4 / 19.9 / 31.2** | **FAIL at all three** |
| Pulse Lab Revelle lesson (13i §A1) | ssp585 − ssp119 airborne frac > 0 | −0.109 | **reversed** |
| CO₂ level, 2015–2024 MLO | 0 | +3.34 ppm | pass |

DESIGN §6 opens *"all must pass before headline claims."* Gate 12's own recorded status
(*"inside the range at all three horizons (12.6 / 26.2 / 43.6)"*) is **stale** — it was
written at β 0.38.

**The reason is measurable and is the answer to question (a).** Across a one-prior-sd step
in β, the CO₂ streams move 1,565 log-units, the ice core 118, `gcb_ocean_sink` 36, and
`gcb_land_sink` **2.0** (7.3 once §1's bug is fixed). The partition constraint loses to the
CO₂ level by roughly **40 : 1**, so the sampler will always buy CO₂ level with land sink.
The β re-centrings did exactly that, twice, correctly following the objective as written.

**So: fix the objective before re-taking β, and re-take β before anything else. The refit
and the pump are both correctly deferred, and neither is the next step.**

---

## 1. §1's defect — CONFIRMED, PRICED, and it is not the expensive one

The handoff's diagnosis of `R/likelihood.R:590–596` is correct as written: `mod_ld` is the
model's **net** land flux and `g$land_sink` is GCB's **gross** residual sink. Confirmed by
reading, and the corrected term (`mod_ld + E_LUC`) is scored alongside the shipped one in
`diag_stream_leverage.R`.

**What is new is its price.** Leverage per one-prior-sd step, at the current defaults:

| | β | q10 | k_w | h_ml | kz | everything else |
|---|---|---|---|---|---|---|
| `gcb_land_sink` **as shipped** | 2.0 | 0.2 | 0.1 | 0.0 | 0.0 | ≤ 7.8 (`gamma_enso`) |
| `gcb_land_sink` **corrected** | 7.3 | 0.9 | 0.4 | 0.1 | 0.2 | ≤ 8.1 |

**Fixing it is necessary and will change essentially nothing about the fit.** It restores a
correct sign (§1's table: the corrected term's own optimum is β ≈ 0.39 and it resists rising
β) but at 7.3 log-units against CO₂'s 1,565 it cannot act on that preference. Fix it because
the objective is *wrong*, not because it will move the answer — and do not let its landing
be mistaken for having addressed the weighting problem. It is a worked example of exactly
what the review is for, and the review's finding is that it is the small half of the issue.

**A second, smaller defect in the same block, not previously recorded.** Both sink terms
compare `diff()` of the model's **annual-mean** stock to GCB's **calendar-year** flux. The
difference of two annual means is the flux integrated over [mid-year *y*−1, mid-year *y*] —
a half-year offset from the quantity GCB reports. At σ 0.4–2.7 GtC/yr against a sink
trending ~0.03 GtC/yr² this is worth ~0.015 GtC/yr of bias, i.e. nothing; it does alias
interannual variability, which is the part of the GCB series a partition constraint is
supposed to use. Fix it in the same commit as §1 — it is the same three lines.

`gcb_ocean_sink` has no `E_LUC` analog and is unaffected by §1, as the handoff says.

---

## 2. (a) TARGETS — the weights are not defensible, and now there are numbers

### 2.1 The instrument

The inventory in the handoff lists each stream's **logL level**. That is not its weight.
A stream's ability to decide a parameter is its **leverage** — log-units moved per unit of
parameter — and `diag_stream_leverage.R` measures it directly: each of the 16 calibrated
parameters perturbed by ±1 prior sd (10 % of range for uniform priors), scoring every stream
separately via `ccx_loglik(by_stream = TRUE)`.

**The perturbation size is a stated choice, not a derived one.** One prior sd is the scale
the sampler proposes in, which is the relevant scale for "can this stream outvote that one".
It is a finite difference of the level, not a Hessian, so a stream already sitting at its own
optimum shows small numbers by construction; both signed halves are reported in the RDS.

### 2.2 Result — a 5,000× dynamic range, and three decorative streams

Max |Δ logL| any parameter can extract from each stream:

| stream | max leverage | on which parameter | logL level |
|---|---|---|---|
| `co2_seasonal_MLO` | **4,118** | `seas_phase_NH` | −837 |
| `d14c_SH` / `d14c_NH` | **1,011 / 727** | `k_w` | −394 / −311 |
| `co2_level_MLO` / `_SPO` | **901 / 664** | β | −195 / −158 |
| `bomb_total`'s decider → `d14c_*` | 677 / 570 | `bomb_total` | — |
| `d13c_level_MLO` / `_SPO` | 382 / 277 | `k_w` | −198 / −52 |
| `co2_seasonal_SPO` | 264 | `seas_phase_SH` | −103 |
| `co2_icecore` | 118 | β | −683 |
| `gcb_ocean_sink` | 36 | β | −58 |
| **`gcb_land_sink` (corrected)** | **7.3** | β | −135 |
| **`d14c_intcal`** | **2.8** | `k_w` | **−670** |
| **`gcb_land_sink` (shipped)** | **2.0** | β | −128 |
| **`excess_c14_ocean`** | **0.8** | `bomb_total` | −7.5 |

**Answer to the question: no, the weights are not defensible.** Four specific findings:

**(i) `excess_c14_ocean` failed at its stated job, and the failure is exactly the one it was
built to prevent.** Design note 5 in `likelihood.R` states the purpose in its own words:
the ocean's ventilation *"is only ever inferred from how fast the atmosphere loses its bomb
spike — and that can be bought with a larger bomb source instead of a faster sink."* The
term added to price the sink directly has **0.8 log-units** of leverage on `bomb_total`,
against the atmospheric Δ¹⁴C streams' **1,247**. It is outvoted 1,500 : 1. `bomb_total` is
still decided entirely by the atmosphere, and the loophole is still open. This is not an
argument for deleting the term — it is an argument that its σ (a 15 % rank-one method bias
on a ±7.9 kmol target) is far too loose to do the job it was added for, and the σ is the
only lever it has.

**(ii) A large logL level with no leverage is a constant offset, not a constraint.**
`d14c_intcal` carries −670 log-units — the third-largest level in the objective — and
**2.8** log-units of leverage. It is the pre-1950 Suess decline scored against a model whose
pre-1950 Δ¹⁴C no calibrated parameter moves. It costs a great deal of the objective's
absolute value and decides nothing. Same pattern, less extreme, at `co2_icecore`
(−683 level, 118 leverage). Whenever a stream's level is quoted as evidence of its
importance, this is the counter-example.

**(iii) `q10` is decided by δ¹³C — the one stream with a known, unclosed structural
misfit.** Total leverage on `q10` across all streams is ~70, i.e. **20× weaker than β's
~1,700**, and its composition is:

| stream | leverage on `q10` | sign of preference |
|---|---|---|
| `co2_level_SPO` | 20.6 | prefers **higher** q10 |
| `d13c_level_MLO` | 19.2 | prefers **lower** |
| `d13c_level_SPO` | 12.2 | prefers **lower** |
| `co2_level_MLO` | 7.9 | prefers **lower** |
| `co2_icecore` | 4.8 | prefers lower |
| `gcb_ocean_sink` | 4.5 | prefers higher |

The two CO₂ station terms **oppose each other and nearly cancel** (+7.2 / −6.9 on the high
side). What is left standing is δ¹³C, pulling `q10` down with 31 of the ~70 available
log-units — and δ¹³C is the stream the model over-depletes by ~0.53 ‰ for reasons neither
the source signature, the fractionation constants, the reachable partition nor the gross
land loop closes (`diag_d13c_suess`, 13i §3.1). **This is the q10 → 0.169 pathology, seen
directly rather than inferred.** It independently confirms `diag_which_stream_pays.R`'s
hypothesis with a cleaner instrument, at the current defaults rather than at the stale mode.

**(iv) Three σ are free and every other stream's is fixed — so structural misfit converts
itself into de-weighting.** `sigma_co2`, `sigma_d13c`, `sigma_d14c` are calibrated with
lognormal priors; the GCB sinks, the ice core, IntCal, the Δ¹⁴C representation error and the
excess-¹⁴C covariance are all hard-coded. A free σ re-weights its own stream by its own fit
quality. Measured, signed: a +0.7 log-sd move in `sigma_d13c` **gains** `d13c_level_MLO`
+153 and `_SPO` +49 log-units. The δ¹³C stream's strongest available move is to inflate its
own error bar and stop mattering. That is not a hypothetical failure mode; it is 510
log-units of leverage, more than any physical parameter except β, `k_w` and the seasonal
phases.

### 2.3 The interhemispheric gradient — DESIGN says it constrains τ_ex; the code says otherwise

DESIGN §6 gate 9: *"with the bomb-spike NH→SH lag this is the main constraint on τ_ex."*
**There is no gradient term in `ccx_loglik()`.** MLO and SPO are scored as two independent
levels. Measured, τ_ex's ~350 log-units of total leverage decompose as:

| stream | leverage on `tau_ex` |
|---|---|
| `co2_seasonal_MLO` | 144.5 |
| `co2_seasonal_SPO` | 87.6 |
| `d13c_level_MLO` / `_SPO` | 37.3 / 20.9 |
| `d14c_SH` / `_NH` | 30.3 / 11.9 |
| `co2_level_MLO` / `_SPO` | 7.1 / 6.4 |

**66 % of τ_ex is set by the seasonal-harmonic terms.** The interhemispheric exchange time
is currently being determined by the shape of the Keeling sawtooth, not by the gradient
DESIGN nominates. And the gradient *is* constrained, but only implicitly and loosely: two
independent station levels at σ = √(σ_co2² + 1.0²) ≈ 1.8 ppm give the difference a σ of
~2.5 ppm, against an observed decadal gradient that DESIGN gate 9 already tabulates to
0.01 ppm and that runs 0.47 → 3.97 ppm across the record. The model's known error in it is
~1.1 ppm — **less than half its own effective error bar**, which is why nothing has ever
objected.

**Recommendation: yes, make the gradient an explicit target.** It is nearly free (gate 9's
seasonally adjusted decadal series already exists and is computed by the same estimator the
likelihood uses), it is the only thing that would give τ_ex a physically appropriate
constraint, and it is the natural home for the δ¹³C gradient miss (−0.210 modeled against
−0.074 observed) which currently has no term either.

### 2.4 Monthly — the seasonal cycle should stay fitted, not become derived

The handoff asks whether the seasonal cycle should be a derived check instead. **No.** Four
parameters (`seas_amp_*`, `seas_phase_*`) exist only to fit it and nothing else touches
them: the leverage matrix shows `seas_phase_NH` moved by `co2_seasonal_MLO` (4,118) and by
essentially nothing else (`co2_icecore` 11.2, everything else < 1). Demoting the target
would leave four unidentified parameters. The genuine question is the opposite one — the
seasonal terms carry the **largest curvature in the whole objective**, and they are what is
currently setting τ_ex (§2.3). Adding a gradient term is the fix for that, not removing the
seasonal one.

The one real caution: the rectification side-effect `likelihood.R` documents is still
present but is now correctly outranked — `seas_amp_NH` moves `co2_seasonal_MLO` by 1,060
against `d13c_level_MLO` by 68. The per-year scoring decision was right and is working.

### 2.5 What should be in the target set that is not

1. **The MLO−SPO CO₂ gradient**, seasonally adjusted, decadal (§2.3). Data already in repo.
2. **The MLO−SPO δ¹³C gradient**, same term, same reason — it is 3× off and unscored.
3. **A deep-ocean Δ¹⁴C term** (12d §§8–9, still never built). Its purpose in leverage terms
   is precise: **nothing in the objective constrains `kz` except δ¹³C**, the misfitting
   stream (`kz` leverage: `d13c_level_MLO` 9.3, `d14c_SH` 8.4, `d14c_NH` 7.8, `co2_level_MLO`
   6.9, `gcb_ocean_sink` 6.4 — all small and mutually canceling, which is why the bracket
   has to exist). **BLOCKED on GLODAPv2**, correctly, per 13i §A3.
4. **Quay 2003 / Eide 2017 / SHCal20** (13h §5 decision 3): these are the three the handoff
   lists as candidates. On the leverage evidence, admit **Quay's mixed-layer Suess rate**
   — it is the one that would price the air–sea exchange independently of `k_w`'s current
   sole deciders (Δ¹⁴C, 1,738 log-units, which is the same atmospheric-decline information
   `bomb_total` can buy). Hold SHCal20 and Eide: both are pre-industrial or cumulative
   quantities of the `d14c_intcal` type, which §2.2(ii) shows arrive with no leverage.

### 2.6 What is in it that should not be

**Nothing should be deleted.** Both decorative terms (`excess_c14_ocean`, `d14c_intcal`)
are *correct physics against real data*; the problem is their σ, not their presence. Deleting
them would remove a check that currently costs nothing and would look like a fit improvement.
The action is to re-take their σ, and for `excess_c14_ocean` that means re-taking
`LIK_EXCESS_C14_TARGET` (the wide `table4_obs_range` vs the 3× tighter `table2_peacock`) —
already **flagged for Marcus** in `likelihood.R` and still open. **The leverage table is new
evidence for that decision: at the wide target the term does nothing at all.**

---

## 3. (b) INPUTS — `E_LUC` is the wrong *kind* of input, and it is absorbing ~30 ppm

### 3.1 The question the handoff asks, answered with a measurement

> *"Is `E_LUC` the right kind of input at all?"*

**No — it is prescribed as exact, and it is the least certain number in the whole forcing
table.** `DATA.md` §3a records the receipts already: GCB 2025's bookkeeping mean is
**239.8 GtC over 1850–2018** against OSCAR v3.1's **178.9 for the identical period** — a
**34 % product spread** — and OSCAR's own paper headline (Gasser et al. 2020,
doi:10.5194/bg-17-4075-2020) is **206 ± 57 PgC for 1750–2018**. ±57 GtC is **±27 ppm**.

The model's single largest structural misfit — 13i §2's "CO₂ level vs GCB budget", ~21–32 ppm
depending on β and debit — **is smaller than the stated uncertainty of one of its inputs.**

### 3.2 The test, and it settles the β dispute differently from either option on the table

`diag_luc_scale.R`. Hold everything at defaults, scale the LUC forcing (and `cum_luc` with
it, since the converted-land term reads it), 2015–2024 means:

| β | LUC × | cum LUC 1750–2024 | CO₂ bias (obs−mod) | gross land | ocean | δ¹³C bias |
|---|---|---|---|---|---|---|
| — | — | — | 0 | **2.36 ± 0.9** | **3.22 ± 0.4** | 0 |
| 0.40 | 1.00 | 289.3 | −32.53 | 2.49 | 2.96 | +0.819 |
| 0.40 | 0.55 | 159.1 | −7.15 | **2.42** | 2.76 | +0.628 |
| **0.50** | **0.65** | **188.0** | **−2.58** | **3.06** | 2.63 | +0.542 |
| 0.50 | 0.75 | 217.0 | −7.74 | 3.09 | 2.67 | +0.582 |
| **0.75** | **1.00** | **289.3** | **+3.34** | **4.57** | **2.38** | +0.382 |

**At matched CO₂ bias there are two settlements, and they are not equally good:**

| | β 0.75, LUC × 1.00 (shipped) | β 0.50, LUC × 0.65 |
|---|---|---|
| CO₂ level | +3.3 ppm ✓ | −2.6 ppm ✓ |
| **gate 7 land** | 4.57 = **+2.5σ ✗** | 3.06 = +0.8σ ✓ |
| **gate 7 ocean** | 2.38 = **−2.1σ ✗** | 2.63 = −1.5σ (marginal) |
| **gate 12 Joos IRF** | **FAIL ×3** | **inside ×3** |
| Pulse Lab Revelle | **reversed** | holds (+0.085) |
| δ¹³C bias | +0.382 | +0.542 |

**The LUC route wins on four criteria and loses on δ¹³C by 0.16 ‰.** Stated plainly because
it is the one place the shipped default is better: δ¹³C prefers the high-β settlement, and
that should not be buried. It does not come close to outweighing two failed hard gates.

**And 188 GtC is not a tuned number pulled to fit** — it sits inside OSCAR's published
206 ± 57 PgC, about 0.5σ below center, and LUC × 0.75 = 217 GtC is *within a few GtC of
OSCAR's central value* while still closing 25 of the 32 ppm.

### 3.3 What this means, and what it does not

**It means:** the model is currently forced to pick between GCB's LUC magnitude and GCB's
own sink magnitudes. Inside a model that closes its carbon budget exactly, the two are
mutually inconsistent at the ~30 ppm level, and β is paying the difference. 13i §2's
observation that *"GCB's own table carries a +35.6 GtC cumulative imbalance over 1959–2024
alone"* is the same fact from the other end: **the model has to put the imbalance
somewhere, and the honest place for it is the input that carries the imbalance's own size
in its error bar.**

**It does not mean** that LUC × 0.65 is the right number, and it must not be adopted as
one. Three limits, stated:
- A uniform scale is a crude instrument. It scales the OSCAR-derived pre-1850 segment and
  the GCB 1850–2024 segment together, and those have different provenance and different
  errors. A real implementation wants a scale on the GCB segment with an OSCAR-informed prior.
- **GCB 2025's own stated uncertainty on E_LUC has not been pulled from the source.** I am
  citing OSCAR's ±57 (which is in `DATA.md` with a DOI); the GCB figure is a different number
  and is needed before this becomes a prior. **Project rule 2 — do not put it in code first.**
- 13i §2's `−57.4 / +209.8` GtC GCB comparison figures still carry their **PROVENANCE FLAG**
  and cannot be recomputed from the repo (`obs_gcb.rds` starts 1959). Unchanged by this.

**Recommendation: `luc_scale` becomes a 17th calibrated parameter with a sourced prior.**
Pre-registered prediction for the refit, so it is falsifiable: with `luc_scale` free, **β
falls to 0.40–0.55 and `luc_scale` settles at 0.6–0.8**, because the CO₂ level's 1,565
log-units will find the cheaper of the two ways to close the same gap and the LUC route
costs no gate.

### 3.4 The other three input questions

**The four provisional hemispheric shares (0.95 / 0.55 / 0.90 / 0.90) — still the cheapest
unexplored lead, and now with a reason nobody has checked them.** `npp_frac_NH` has ~35
log-units of total leverage, i.e. the objective is nearly blind to N/S land partitioning; and
**there is no gradient statistic** (§2.3), so nothing in the likelihood would object to a
wrong share. The gradient's 3× δ¹³C miss and ~1.1 ppm CO₂ miss are therefore *exactly the
observables a wrong share would show up in, and exactly the ones that are unscored.* Do the
sensitivity sweep — but do it **after** the gradient term exists, or it will measure nothing.

**ENSO's non-zero future mean (+0.286 over 1750–2100, +1.438 post-2020) — real, and a second
issue sits next to it.** `ccx_default_params()$gamma_enso` is **0**, while
`CCX_PARAM_TABLE$gamma_enso$init` is 0.5 and `app/global.R:71` overrides the default to the
table's init. This is documented and deliberate (`model.R:372–382` — 0 is the
behavior-preserving value after the R/C++ divergence of 2026-08-13d), so it is **not a bug**.
It is a provenance hazard: **every "at default parameters" number in this repo — the β
re-centering, the Joos gate, the Pulse Lab reversal, and everything in this review — is
ENSO-off, while the app the numbers describe runs ENSO-on.** For pulse work that is almost
certainly immaterial (ENSO is an internal soil↔atmosphere transfer, and its leverage tops out
at 16.3 log-units anywhere in the objective). It should still be stated on every output, and
the two should be reconciled rather than left as an asymmetry a reader has to know about.
On the forcing itself: a +1.438 post-2020 mean in an index the model treats as a zero-mean
oscillation is an **extension artifact to fix at the source**, not a physical claim.

**Bomb-¹⁴C shape — yes, it has to stop being provisional, and §2.2(i) is why.** The argument
was previously "magnitude absorbs shape error, so the post-peak decay can still constrain
ventilation". The leverage table shows the absorber is unopposed: `bomb_total` is set by
`d14c_NH`/`_SH` at 1,247 log-units against `excess_c14_ocean`'s 0.8. Shape error therefore
lands in `bomb_total` and from there in the inferred ocean sink, with nothing pushing back.
Either tighten `excess_c14_ocean` (§2.6) or resolve the shape; doing neither means Δ¹⁴C
cannot be trusted to constrain ventilation, which is the handoff's own question answered yes.

---

## 4. (c) COMPONENTS — one component has a demonstrated failure; the ocean is re-motivated

### 4.1 Fertilization — the binding structural defect, and the arithmetic of why

`NPP = NPP₀(1 + β ln(χ/χ₀))` has **one parameter controlling two things the data want to set
independently**:

- the **integral** — cumulative historical land uptake, which the CO₂ record and GCB's land
  sink both bear on;
- the **derivative at today's CO₂** — `dNPP/dχ = β·NPP₀/χ`, which is what a pulse sees, and
  therefore what DESIGN gate 12 and the Pulse Lab's Revelle lesson both bear on.

At β 0.75, χ 388 ppm: `0.75 × 60 / 388` = **0.116 GtC yr⁻¹ ppm⁻¹**. Gate 12 passes at
β ≈ 0.40–0.50, i.e. at a marginal sensitivity of **0.062–0.077**. The log form cannot
deliver a large integral and a small derivative; the ratio between them is fixed by the
functional form, and β only slides along it.

**The unsaturated form's failure is now corroborated by an external benchmark, not only by
the app's own test.** 13i §A1 showed the Revelle lesson reversing above β ≈ 0.53 because NPP
reaches **2.48× preindustrial at 1998 ppm**. `diag_joos_beta_scan.R` shows the same
mechanism failing against Joos et al. (2013):

| β | int IRF @20 | @50 | @100 | verdict | Revelle lesson |
|---|---|---|---|---|---|
| 0.30 | 13.8 | 29.8 | 51.2 | inside (best est. 14.2/30.3/52.4) | holds |
| 0.40 | 13.0 | 27.3 | 46.0 | inside | holds |
| **0.50** | **12.2** | **25.0** | **41.1** | **inside — but @20 is exactly the 5th pct** | holds (+0.085) |
| 0.60 | 11.5 | 22.8 | 36.8 | **FAIL ×3** | **reversed (−0.011)** |
| 0.75 | 10.4 | 19.9 | 31.2 | **FAIL ×3** | **reversed (−0.109)** |

**Two entirely independent criteria — a 15-model literature benchmark and the app's own
pedagogical claim — put the same ceiling on β at ≈ 0.50.** Neither was used to set it.

Also from that scan, and it belongs in the record: the **PI < PD ordering survives at every
β** (30.1 < 34.2 yr at β 0.75; 42.0 < 53.6 at 0.30), so the *held-background* Revelle claim
is intact. It is only the *rising-background* (SSP) comparison that reverses. The app's
background slider spans both protocols, which is why the tab can be simultaneously right and
wrong depending on which end of its own slider the user is on. That is worth knowing before
anyone tries to fix the tab by changing its wording.

**Recommendation — a two-parameter saturating form, with an explicit design target.** Not
"add saturation" as a direction, but a target the replacement must hit:

> reproduce the historical cumulative land uptake that β ≈ 0.7 gives, while delivering a
> marginal sensitivity at 388 ppm no larger than β ≈ 0.5 gives (≈ 0.077 GtC yr⁻¹ ppm⁻¹), and
> a 1998 ppm NPP ratio well below 2.48×.

A Michaelis–Menten / bounded-exponential in (β_max, K) does this by construction: the
saturation decouples integral from derivative, which is the whole requirement. Nutrient
limitation would too, at more structural cost. **Keeping the log form and capping the app's
scenario range is the third option and it should be named as available** — it is much
cheaper and it fails honestly rather than silently — but it does not restore gate 12, which
is at 388 ppm and has nothing to do with scenario range.

**This is PHASE-3-class model-structure work and it is the highest-value structural question
in the project.** It is also the one place where a fix to (c) is forced by (d) rather than
motivated by tidiness.

### 4.2 Ocean — the pump's case is *changed and strengthened*, and it is now falsifiable

At the β 0.50 / LUC 0.65 settlement, **the ocean sink is the only remaining gate miss**:
2.63 against GCB's 3.22 ± 0.4, i.e. −1.5σ. Everything else lands. That is a much better
motivation for ocean structural work than the one 13h §4.3 had, and it points the same way as
13e §6's measured **14 % ocean inventory deficit** and the **exactly-zero interior DIC
gradient** (1986.3 µmol/kg uniform through 3700 m against an observed ~300 µmol/kg range).

**But it must be pre-registered as a test, not assumed.** 13h §4.3's own verdict was that
a pump alone is *"mostly bookkeeping"*, and there is a physical reason to take that seriously:
the model's uniform 1986 µmol/kg is roughly right at the **surface** and far too low at
**depth**, so a pump raises deep DIC without necessarily lowering surface DIC — and it is
surface DIC, through the Revelle factor, that sets anthropogenic uptake. The pump might buy
the interior gradient and buy **no ocean sink at all**.

> **Pre-registered test, to be run before the pump is adopted on sink grounds:** build the
> pump, and measure the **2015–2024 ocean sink** and the **surface DIC** at fixed β and
> `luc_scale`. If the sink moves from 2.63 toward 3.22, the pump is a mechanism and the case
> is made on physics. If it moves < 0.1 GtC/yr, 13h §4.3 was right, the pump is bookkeeping,
> and it should then be judged **on pedagogy alone** — where it passes the one-sentence test
> ("plankton grow at the surface, die, and sink, which is why the deep ocean is rich in carbon
> and the surface is poor") and the conveyor, which fails its own falsification test (13c §2c)
> and fails the one-sentence test, should not ship.

Independent of the pump: `kz` = 5000 m² yr⁻¹ is ~9× Ledwell's NATRE 536 and the 1-D posterior
still peaks there. §2.5(3) explains why that is not reassuring — nothing but δ¹³C constrains
`kz`. **GLODAPv2 unblocks both this and the pump's deep DIC/δ¹³C targets. One pull, two uses,
and doing it early is the cheaper ordering** (13i §A3, unchanged and still right).

### 4.3 The remaining components — leave them alone, with reasons

| component | verdict | why |
|---|---|---|
| **Land pools (4)** | **keep 4; free none of them** | Nothing in (a) asks for more or fewer. The layout fixed the bomb-¹⁴C partition (+51 % → +0 % at 1975) and 13i records that **one** free land timescale was enough to undo it (`tau_soil_fast` → 11.16 yr, +3.6σ). No stream scores the ¹⁴C partition, so nothing would catch the regression a second time. Structure, not parameters — the existing decision is correct. |
| **`ra_ratio` = 0 (no gross land loop)** | **keep, document the asymmetry** | The asymmetry against gross air–sea and gross interhemispheric is real but defensible on measurement: δ¹³C moves only 0.10 ‰ across `ra_ratio`'s whole range while Δ¹⁴C moves 2.7 → −14.6 ‰, which forbids large values. And no stream could pay for it: the leverage matrix has nothing that would identify it. Leaving it free would be a 17th parameter with no data behind it. |
| **Temperature × ENSO interaction** | **do not build** | They act on the same pool through independent terms, and `gamma_enso`'s max leverage anywhere in the objective is **16.3 log-units**. An interaction between a well-constrained parameter and an unconstrained one is an unidentifiable parameter. Revisit only if a growth-rate-variance statistic enters the likelihood — which is what `test-mechanisms.R:32` is actually asking for. |
| **Atmosphere (2 boxes, no stratosphere)** | **keep** | v2 backlog. The bomb delivery kernel is measured (Tans 1981), not parameterized; the case for explicit strat boxes was the peak *shape*, and §3.4 says resolve the shape at the source instead. |
| **Conveyor (built, off)** | **keep off, do not ship** | Fails its own falsification test (13c §2c: it moves the MLO−SPO δ¹³C gradient the wrong way) and fails the pedagogy one-sentence test. `project_ccx_upwelling_does_not_close_d13c`'s result — reversing a closed vertical loop is provably invisible to the atmosphere — is the general warning that covers this whole family of options. |

---

## 5. (d) DOES THE ASSEMBLED THING WORK — the weakest test is failing, as Marcus predicted

**Marcus' framing was that pulse lifetime would be the weakest test. It is, and it is now
below the literature rather than merely at its low edge.**

**Q: "What β can the app ship with, and is that compatible with any calibration criterion?"**

**A: β ≤ 0.50, and it is compatible with three of the four gates but not with the CO₂ level
at LUC × 1.00 — which is why §3 matters.** The Joos ceiling (≈0.50) and the Revelle ceiling
(≈0.53) agree. The four calibration criteria that set the current default all read the CO₂
record (13i §3.1: 0.591/0.597/0.597/0.617 under wood-only; 0.712–0.770 under pro rata) and
they agree with each other because **they are four views of one stream that outvotes
everything else 40 : 1.** Four criteria agreeing is not four pieces of evidence when they
share a denominator.

With `luc_scale` free, β ≈ 0.50 becomes compatible with the CO₂ level too (−2.6 ppm), and
the incompatibility dissolves without a structural change. **The fertilization form still
has to change** — β 0.50 sits *exactly on* the 5th percentile at TH 20 (12.2 vs 12.2), which
is not a margin — but the ordering matters: `luc_scale` is a cheap input fix that buys the
gates back now, and the fertilization form is the expensive structural fix that buys margin.

**Q: "Re-run the Joos IRF gate at the current default before anything else in (d)."**
**Done — §4.1. It fails at all three horizons, and DESIGN §6 gate 12's recorded status is
stale.** Point IRF is 0.400/0.264/0.202/0.148 at 20/50/100/300 yr against Joos Table 5's
0.596/0.487/0.409/0.322. The file header's recorded values (0.531/0.397/0.313/0.212) were
measured at β 0.38 and must be re-stamped.

**Also failing, and not previously connected to this:** on the future-scenario protocol the
model gives an ssp585 point IRF at 100 yr of **0.096** — 10 % of the pulse remaining — where
Joos's Bern3D-LPJ has the RCP8.5 pulse airborne fraction *above 80 % at year 1000*. This is
the Pulse Lab reversal again, measured against the literature rather than against the app's
own test. The two failures have one cause.

**Q: pedagogy — the one-sentence test applied to every option in (c).**

| option | one sentence | verdict |
|---|---|---|
| saturating fertilization | "plants respond less and less to each extra bit of CO₂, because something else eventually runs short" | **passes** |
| biological pump | "plankton grow at the surface, die, and sink, which is why the deep ocean is rich in carbon and the surface is poor" | **passes** |
| conveyor | — (13c: no sentence survived) | **fails** |
| `luc_scale` | "how much carbon deforestation released is itself uncertain, and the model lets the data say" | **passes**, and it teaches something the app currently cannot |

**Q: turnover vs adjustment (4.69 yr against a 40.3 yr mass 1/e).** **Not re-measured this
session** — `diag_pedagogy.R` was not run, and its numbers predate both β moves exactly as
the Joos gate did. Given that the mass 1/e time is precisely the quantity §4.1 shows moving
with β, **the 40.3 yr figure should be assumed stale until re-run.** The turnover figure
(a ¹⁴C-label quantity, set by gross fluxes) should be much more robust, but that is a
prediction, not a measurement. Re-run it at whatever β lands; it is the app's headline
pedagogical claim and it is currently uncorroborated at the shipped default.

---

## 6. THE FAILING TESTS — the pulse ones are the model talking, and now have external corroboration

Unchanged recommendation from 13i (**report, don't edit**), with one upgrade:
**`test-pulse.R:83, :100, :101, :112` are no longer only an internal disagreement.** The Joos
scan reproduces the same defect against an outside benchmark at the same β. They are the
model correctly reporting a structural failure, and they should stay failing until the
fertilization form changes — not be re-derived to a passing threshold.

**Add gate 12 to the suite.** DESIGN §6 lists it as a hard gate; `diag_joos_irf.R` is a
diagnostic nobody runs, which is exactly how its recorded status went stale across two β
moves. A test would have caught the β 0.60 move on the day it happened.

The other six remain as 13i and A5 describe them.

---

## 7. VERDICT ON THE SHELVED PLAN, AND THE ORDERING

**13h §3 (the refit) and §4 (the pump) both stay on the shelf, and neither is the next step
— but for different reasons and with different futures.**

- **The refit is not wrong, it is premature in three specific ways.** It would run against
  an objective with a sign error (§1), with 40 : 1 weighting that has already driven β past
  two hard gates (§2), missing the input parameter that carries the residual it is meant to
  explain (§3), and with a fertilization form that cannot satisfy both ends of the data
  (§4.1). 13h §3.1's pre-registered prediction (β 0.088 → ~0.5, q10 0.169 → ~1.5) is
  **unchanged and still the right test** — and §3.3 adds a second pre-registered prediction
  to run alongside it.
- **The pump's case is *stronger* than 13h made it, and now falsifiable** (§4.2). It moves
  behind the GLODAPv2 pull, which it shares with the `kz` decision.

### The ordering

| # | task | why here | blocked on |
|---|---|---|---|
| **1** | **Fix `gcb_land_sink` net-vs-gross, and the half-year alignment in both sink terms** | The objective is wrong. Everything downstream is invalid until it lands, and it is three lines. | — |
| **2** | **Re-take the β default against DESIGN's own gates, not the CO₂ stream alone** | Two hard gates are failing *now*, at the shipped default, in the app. β ≤ 0.50 restores both. This is a **Marcus decision**, not mine: it trades a CO₂ bias for two gates, and (3) is the argument that the trade is temporary. | — |
| **3** | **`luc_scale` as a 17th parameter with a GCB-sourced prior** | Cheapest structural change with the largest measured effect: closes ~30 ppm, restores gate 7, costs nothing on the gates. | pull GCB 2025's own stated E_LUC uncertainty (rule 2) |
| **4** | **GLODAPv2 pull** | One pull unblocks the `kz` decision (13i A3, currently BLOCKED on provenance) *and* the pump's deep DIC/δ¹³C targets. Doing it before the refit is the cheaper ordering, as 13i already argued. | — |
| **5** | **Add the interhemispheric-gradient terms (CO₂ + δ¹³C)** | τ_ex is currently set by the seasonal cycle (§2.3); the gradient is 3× off and unscored; and the hemispheric-share sensitivity sweep measures nothing until this exists. Data already in repo. | — |
| **6** | **Re-take the free-σ decision, and `LIK_EXCESS_C14_TARGET`** | §2.2(iv) and §2.2(i) are new evidence on two decisions already flagged for Marcus and answered "left free" / "flagged". Both were taken without leverage numbers. | Marcus |
| **7** | **Saturating fertilization (two-parameter), to the §4.1 design target** | The one component with a demonstrated failure against an external benchmark. PHASE-3-class. Buys margin on gate 12 that β ≤ 0.50 does not have. | — |
| **8** | **THEN the refit**, ~18 parameters | Every blocker above is inside the objective or inside the model it optimizes. | 1–7 |
| **9** | **Pump**, on the §4.2 pre-registered test | | 4, 8 |

### What NOT to do

- **Do not hand-tune stream weights to "balance" the objective.** The imbalance is real
  information about which data constrain which parameters; the fix is to add constraints that
  are missing (§2.5) and to re-take σ decisions on evidence (§2.6), not to equalize log-units.
- **Do not delete `excess_c14_ocean` or `d14c_intcal`.** Correct physics with a loose σ.
- **Do not free any land turnover parameter.** 13i priced this; nothing scores the property
  it would break.
- **Do not delete the `kz` bracket bare.** Measured and rejected (kz → 10,686, deep Δ¹⁴C
  −112.7 ‰), and still true.
- **Do not adopt LUC × 0.65 as a fixture.** It is a measurement of what is *available*, not
  a calibrated value; §3.3 lists its three limits.

---

## 8. PROPOSED DESIGN.md AMENDMENTS — written out, not applied

Deliberately **not** applied: every one of these encodes a methodological choice that is
Marcus'. Listed so the decision is concrete rather than abstract.

1. **§3.3, fertilization** — replace the log form's specification with the two-parameter
   saturating form and the §4.1 design target (integral of β ≈ 0.7, marginal slope at 388 ppm
   ≤ that of β ≈ 0.5). Record the log form and why it was abandoned, per the CHANGELOG rule.
2. **§3.6, forcings** — `E_LUC` gains a calibrated scale with a sourced prior; the table entry
   stops presenting a ±27 ppm quantity as prescribed-exact.
3. **§5.1, free parameters** — ~16 → ~18 (`luc_scale`, fertilization's second parameter).
4. **§5.2, likelihood** — add the interhemispheric-gradient terms; state explicitly that
   `gcb_land_sink` compares **gross to gross**; record the free-σ asymmetry as a known
   property with its measured leverage.
5. **§6, gates** — gate 12's recorded status is stale and must be re-stamped with β; add the
   Joos gate to the test suite; add a **gate 13: stream-leverage screen** — no calibrated
   parameter may be decided by a stream carrying a known unclosed structural misfit, which is
   the general form of the `q10`/δ¹³C finding and would have caught it two weeks ago.
6. **§9, Q1** — the "soft constraint with inflated σ, default yes" answer is now measured to
   make the term decorative (7.3 log-units corrected). Re-take it with the number attached.

---

## 9. Non-obvious state added by this session

- **No model code, no fixtures and no defaults were changed.** Three diagnostics added.
- `calibration/output/recentre_beta_scan.rds` was **overwritten** by re-running
  `diag_recentre_beta.R` at the current defaults (it was last written at β 0.60 under
  wood-only). Its contents are now pro-rata / β 0.75 — an improvement, but any number quoted
  from the old file does not correspond to it any more.
- Every number in this review is at **`gamma_enso` = 0** (§3.4), i.e. ENSO off, which is
  `ccx_default_params()` and is **not** what `app/global.R` runs.
- `diag_joos_beta_scan.R` is `diag_joos_irf.R` truncated after part 4 with a β override; it
  is a probe, not a replacement, and `diag_joos_irf.R` remains the canonical gate.
- The Joos scan takes ~4 min per β; the leverage matrix ~2 min; the LUC scan ~1 min.
