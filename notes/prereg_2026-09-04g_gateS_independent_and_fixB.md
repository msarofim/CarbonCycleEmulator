# PRE-REGISTRATION — GATE S's target against an observation that never passes
# through the model, and the FIX B pre-test, from ONE product

**Written 2026-09-04, BEFORE `calibration/diag_gateS_indep_and_fixB.R` was written or run.**
The SOM-FFN file has been opened before, on 2026-08-27f, for `diag_so_pco2_phase.R`; the bands,
the fill-value trap and the estimator are reused from there rather than re-derived. **What has
NOT been computed before is every number this file predicts**: no ΔpCO₂ *bracket*, no
tropical-minus-global contrast, no flux pricing.

Handoff `handoff_2026-09-04_gate_audit.md` §8 item 1 — the top of the open list, and the one
place where one measurement serves two owed questions.

---

## Why these two questions are one script

**GATE S is self-declared circular.** Its target `SPO_SEAS_OCEAN_PHASE_INV` = 8.52 mo
[7.82, 9.20] is the observed SPO CO₂ + δ¹³C first-harmonic pair inverted through **two scalars
the model supplies** (`s_L`, `s_O`, ‰ per ppm). All six `SPO_SEAS_*` constants carry
`status = "provisional"` and say so at the gate.

**FIX B is untouched** and its cheap pre-test — the model's tropical surface pCO₂ disequilibrium
against a climatology — has never been run. `gamma_enso_ocn_*` is an **empirical patch**: the
comment at `src/ccx_core.cpp:528` and `R/model.R:1720` states plainly that the model's only ENSO
path to the ocean is SST solubility, that it has the **wrong sign** (r −0.51 against GCB's
+0.535), and that the conveyor was refuted as the fix.

Both questions are answered by the same field: **Landschützer, Laruelle, Roobaert & Regnier
(2020)**, ESSD 12:2537, NOAA NCEI accession 0209633 — a monthly surface-ocean pCO₂ **climatology**,
`data-raw/downloads/MPI-ULB-SOM_FFN_clim.nc`, registered in `download_data.R` §6c.

⚠ **A CLIMATOLOGY HAS NO INTERANNUAL AXIS.** It can measure the tropical **reservoir** ENSO
modulates. It cannot measure the modulation. Every ENSO-variance number below therefore comes
from GCB + Niño3.4, and the climatology's role is to say how big the pool is.

⚠ **pCO₂ IS NOT FLUX.** `F = k·K₀·ΔpCO₂`, and neither the wind seasonality in `k` nor the
temperature seasonality in `K₀` is in this file. This caveat is inherited verbatim from
prereg 2026-08-27f and it still binds.

---

# PART A — IS GATE S's TARGET CORROBORATED BY AN INDEPENDENT OBSERVATION?

## The route, and the law it rests on

The climatology gives the **ocean's** ΔpCO₂ phase. Gate S's target is an **atmospheric** phase.
The conversion is not free, so it is done as a **BRACKET derived from a physical law, not as a
number**: a first-order box forced sinusoidally at ω,

    dC/dt = F(t) − C/τ  ⇒  C lags F by arctan(ωτ) ∈ (0°, 90°]

so an atmospheric concentration limb lags its driving flux by **between 0 and 3 months**, 3 only
in the lossless limit. The bracket is `[m_ΔpCO₂, m_ΔpCO₂ + 3]`.

## A1 — THE CHECK

**PREDICT: 8.52 lies inside the bracket built on the Southern Ocean (40–90 °S) band.**
**FALSIFIER: 8.52 outside it** ⇒ the gate's target is NOT corroborated by an observation that
avoids the model, and gate S must be re-derived from this product or demoted to a comparison the
way gate 12 was.

## A2 — POWER, STATED BEFORE THE RESULT

The bracket is 3 of 12 months = **25 % of the circle**, so a phase drawn at random passes with
p = 0.25. A check that only ever passes is not a check ([[no_power_null]]).

**PREDICT: the same bracket EXCLUDES the model's pre-fix SH ocean limb** — 3.35 mo on the
`lib_seas_limbs.R` estimator, 4.16 mo on the channel decomposition, the defect gate S was created
to catch. **FALSIFIER: the bracket contains 4.16 as well** ⇒ the test has no power, it is reported
as such, and **it may not be used to upgrade any constant's status**.

## A3 — DISCRIMINATION: WHICH REGIME DOES SPO SAMPLE?

2026-08-27f established that the SH area-mean pCO₂ cycle is a **76 % cancellation** of two
antiphase regimes, and that the model matches the residual. If the SH-mean bracket also contained
8.52, this route could not say which regime the SPO limb comes from.

**PREDICT: the bracket built on the SH area-mean (0–90 °S) EXCLUDES 8.52.**
**FALSIFIER: it contains it** ⇒ A1 is not evidence about the Southern Ocean specifically, and the
conclusion is weakened to "some SH ocean regime".

## A4 — THE NARROWED BRACKET (LABELED WEAKER IN ADVANCE, AND NON-BINDING)

With τ taken from the fitted interhemispheric exchange time the lag is `arctan(ωτ)` rather than
the full 0–3 months. Reported for information.

⚠ **THIS ROW MAY NOT FAIL THE GATE**, for three reasons stated before it is computed:
(1) it neglects the k and K₀ seasonality the caveat above names; (2) the SH box loses signal to
sinks as well as to exchange, so a τ from `tau_ex` alone is an **upper bound** and the implied lag
is biased **LATE**; (3) it is a one-box idealization of a two-hemisphere model. It is printed
beside A1, never in place of it.

---

# PART B — THE FIX B PRE-TEST: IS THERE A TROPICAL RESERVOIR, AND DOES THE MODEL HAVE IT?

## B0 — the observable is REFERENCE-FREE, deliberately

This product carries **no atmospheric pCO₂ field and no stated reference year**, so an absolute
ΔpCO₂ would need an assumed normalization year. The primary observable is therefore an
**internal contrast** — a band's area-weighted annual-mean pCO₂ **minus the global ocean
area-weighted annual-mean** — which is invariant to any uniform offset and so needs neither.
The absolute disequilibrium is reported **only** as a sensitivity swept over reference years, and
no verdict rests on it.

## B1 — THE RESERVOIR: AN ORDERING, NOT AN INVENTED NUMBER

Per `~/.claude/CLAUDE.md`, with nothing external to fix a threshold, assert an **ORDERING between
two measured quantities**.

**PREDICT: `pCO₂(equatorial Pacific 5 °S–5 °N, 160 °E–80 °W) > pCO₂(tropics 20 °S–20 °N) >
pCO₂(global ocean mean)`**, both differences positive — the equatorial Pacific is the ocean's
largest natural outgassing region because it upwells DIC-rich water, which is the *same*
mechanism the ENSO comment invokes.
**FALSIFIER: either inequality reversed or within the spread of the band means** ⇒ the mechanism
Fix B posits is not visible in this product at basin scale and Fix B is not worth building on it.
Magnitudes are **reported**, not gated.

## B2 — WHAT THE MODEL CAN REPRESENT (a SOURCE reading, not a measurement)

**PREDICT, and verify by reading `R/model.R` and `src/ccx_core.cpp` rather than by recall
([[runnable_is_not_encodable]], and the standing rule that a capability claim is checked in the
thing itself): the ocean is TWO hemispheric mixed layers with no tropical box, so the model's
representable tropical-minus-global pCO₂ contrast is EXACTLY ZERO** — and the model's ENSO ocean
term is consequently an additive flux with a free coefficient, not an upwelling response.
**FALSIFIER: a tropical or equatorial box exists** ⇒ the pre-test's premise is wrong and Fix B is
a parameter question, not a structural one.

This is labeled a **code reading**. It cannot be "confirmed" by a run.

## B3 — PRICING, FROM OBSERVATIONS ON BOTH SIDES

The gate-V deficit is `sd_obs 0.911 − sd_model 0.698 = 0.213` GtC/yr, i.e. the drivers need
**1.76×** their present combined variance ([[ccx_gate_v_variability]]).

1. Regress the **GCB ocean sink** on **Niño3.4** (both already in the repo) for the **observed**
   ENSO ocean sensitivity, GtC/yr per index unit, with its standard error.
2. Convert that sensitivity to the **ΔpCO₂ swing** it implies over the equatorial-Pacific mask,
   using the model's **own** `k_w` and `K₀` — so the conversion is the model's, not a new constant.
3. Express that swing as a **FRACTION of the reservoir measured in B1**.

**PREDICT: the required fraction is BELOW 1** — i.e. the observed ENSO ocean sensitivity is a
*modulation* of the equatorial reservoir, not larger than it.
**FALSIFIER: a fraction ≥ 1** ⇒ equatorial upwelling cannot be the whole of the observed ENSO
ocean signal and Fix B is mis-specified as stated.

**REPORTED, NOT GATED:** how much of gate V's 0.213 GtC/yr the observed sensitivity supplies when
driven by the observed index. ⚠ Gate V's own record says a FAIL there **is not a blocker**
(Marcus, 2026-09-04f), so no number in B3 may be read as a requirement.

---

## What is NOT claimed anywhere in this file

- **No refit, no posterior, no parameter change.** Every model number is read at
  `CCX_MODE_CANONICAL` (`ent26`) or from source.
- **No new gate is created here.** If A1 passes, the *existing* gate S's target is corroborated
  and its provenance note gains an independent line; the constant's `status` is a separate
  decision and is **not** taken by this script.
- **A climatology is not an error bar.** This product carries no per-month spread, so the phases
  have no observational uncertainty attached. Spread ACROSS BANDS is the honest scale — the same
  statement prereg 2026-08-27f made.
- **The equatorial-Pacific longitude mask is a judgment** (160 °E–80 °W). It is declared here,
  before the result, and the sensitivity to widening it is reported.
