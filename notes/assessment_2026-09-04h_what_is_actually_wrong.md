# WHAT IS ACTUALLY WRONG WITH THE MODEL — observations and physics
# 2026-09-04h. **Every number measured today at `CCX_MODE_CANONICAL` (`ent26`)**, not recalled.
# Sources: `dg_streams()`, `ccx_model_stats()`, `ccx_prior_z()`, `diag_design_gates_at_mode.R`,
# `diag_gateS_indep_and_fixB.R`. Suite 1771/0/0/4.

---

## 0. THE ONE-PARAGRAPH ANSWER

The model **fits the observations it is scored against very well, and three of its largest errors
are absorbed by free nuisance parameters rather than being seen.** Its genuine physical problems are
concentrated in one place — **the ocean** — and they are of two kinds: a **wrong-signed ENSO
mechanism** that a fitted coefficient cancels, and a **carbon-uptake capacity** that is too small on
centennial timescales while being right at present day. The isotopes point consistently at a fourth
thing: **too much isotopically-light carbon in the northern hemisphere.**

---

## 1. ✅ WHAT IT GENUINELY MATCHES

| observable | model vs observed |
|---|---|
| **CO₂ seasonal cycle, MLO** | 1.01× amplitude, **0.04 months** of phase |
| **CO₂ seasonal cycle, SPO** | 0.98× amplitude, **0.01 months** |
| δ¹³C seasonal cycle, MLO | 0.98×, +0.14 mo |
| **CO₂ record shape** (offset removed) | RMS **0.51 ppm** (MLO) / **0.45 ppm** (SPO) on a ~90 ppm rise |
| **post-bomb Δ¹⁴C decay, 1976–2019** | RMS **4.1 ‰** (SH), 7.3 ‰ (NH) |
| ocean sink 2015–23 | 3.07 vs GCB 3.202 ± 0.40 → **−0.32σ** |
| ocean surface DIC vs GLODAP (gate G) | **−0.06σ** |
| air-sea δ¹³C disequilibrium vs Quay 2003 (gate Q) | **+1.27σ** |
| SPO ocean seasonal limb phase (gate S, rebased) | **8.87 mo, inside [7.41, 10.41]** |

That is a real achievement and the analysis below should be read against it, not instead of it.

---

## 2. ⛔⛔ THE BIGGEST PROBLEM: THREE LARGE ERRORS ARE ABSORBED BY FREE PARAMETERS

The likelihood carries three additive nuisance parameters. **At the canonical mode each one sits
almost exactly on the discrepancy it is able to absorb** — measured, to four decimals:

| free parameter | fitted value | the discrepancy it absorbs | prior z | flagged? |
|---|---|---|---|---|
| `rep_dC` | **+3.3930** | CO₂ level bias **+3.31 / +3.55 ppm** | **+3.39** | ⚠ yes, strained |
| `grad_off_co2` | **+0.2098** | CO₂ gradient error **−0.2120 ppm** | +0.42 | ⛔ **no** |
| `grad_off_d13c` | **+0.06464** | δ¹³C gradient error **−0.06470 ‰** | +0.43 | ⛔ **no** |

⭐⭐ **THE CONSEQUENCE, STATED PLAINLY: the model's δ¹³C interhemispheric gradient is 1.97× observed
— −0.1314 ‰ against −0.0668 ‰ — and NOTHING IN THE OBJECTIVE OR THE GATE SET NOTICES**, because a
free offset at an unremarkable prior z of +0.43 removes it. The `d13c_gradient` stream scores
**+106** log-units, one of the best in the model.

⇒ **The gradient streams constrain the YEAR-TO-YEAR VARIATION of the gradient, not its LEVEL.**
That is a design choice with a real justification (station-vs-box representation error), but at 2×
it is no longer absorbing a representation error — it is absorbing a physical one.
⇒ **The CO₂ gradient is 0.91× observed** and absorbed the same way, though the size is defensible.
⇒ **`rep_dC` is the one that shows**: the model's atmospheric box runs **~3.4 ppm above the
stations**, and this is the third-most-strained parameter in the model.

**This is the single highest-value thing to fix in the objective**, and it is cheap: the fix is a
gate on the gradient LEVEL, not a change to the model.

---

## 3. ⛔ WHAT IT MISSES OUTRIGHT

### 3a. The isotopes say there is too much light carbon in the north
- **δ¹³C level is 0.14–0.20 ‰ TOO DEPLETED** at both stations (MLO −0.1960, SPO −0.1354), and
  **RMS ≈ |bias|** (0.1985 / 0.1399) — i.e. it is a nearly pure OFFSET, not a shape error.
  ⚠ Unlike CO₂, there is **no free offset on the δ¹³C level**, so this one is real and visible.
- **The δ¹³C gradient is 1.97× too large** (§2) — and its sign means the excess depletion is in the
  **NH**.
- **The SPO δ¹³C seasonal amplitude is 1.19× observed** while CO₂ there is 0.98× — the residual
  "too photosynthetic" signature, much reduced from the 2.54× on record but not gone.
⇒ **These three are consistent with one story**: too much depleted (land- or fossil-signatured)
carbon reaching the atmosphere, concentrated in the north. They should be diagnosed together, not
separately.

### 3b. The bomb spike
- **Δ¹⁴C RMS 22 ‰ over 1955–1975**, max error **53 ‰** (NH) / 42 ‰ (SH), against a post-bomb RMS of
  4–7 ‰. The transient is much worse fitted than the decay.
- **GATE 5 FAILS**: NH peak **+2.17σ** late. ⚠ This is a **forced** residual, not an overlooked one —
  see §4b.

### 3c. Sinks and variability
- **Land sink 3.29 vs GCB 2.410 ± 0.50.** It passes gate 7 at **+0.59σ** only because the objective
  inflates the land sigma 3× to 1.50. **At GCB's own stated sigma it is +1.76σ.** The inflation is a
  documented, defensible choice — but the model is high on land uptake and the gate is quiet about it.
- **Interannual CO₂ growth variability 0.77× observed** (gate V, **−2.67σ**). Non-blocking by ruling,
  and mostly downstream of §4a.

---

## 4. ⛔⛔ THE PHYSICS PROBLEMS — all four are structural, and three are in the ocean

### 4a. **The ocean's ENSO response has the WRONG SIGN and is canceled by a fitted coefficient**
Measured like-for-like (model's own annual ocean uptake regressed on annual Niño3.4 with a year
term, n = 66):

| arm | slope GtC/yr per index | r |
|---|---|---|
| GCB (observed) | **+0.1153 ± 0.0246** | +0.488 |
| model, `ent26` | +0.0532 | +0.207 |
| model, solubility only | **−0.1274** | **−0.432** |

The model's only physical ENSO→ocean path is SST solubility. **0.356 of fitted coefficient buys
+0.181 of net slope** because it must first cancel the −0.127, and the net still lands at **0.46×
observed**. **There is no tropical box**, so the equatorial upwelling that actually carries the
observed signal is not representable at all. The reservoir is real and the right size — the
equatorial Pacific sits **+55.5 µatm** above the global ocean mean and the observed sensitivity
needs only **0.24×** of it.
⇒ **For a pedagogical model this is the worst defect in the list**: right answer, wrong physics.

### 4b. **One `tau_ex` cannot serve both the interhemispheric gradient and the bomb-¹⁴C lag**
The gradient wants ~1.16 yr; the bomb lag wants ~2.3. The fit lands at **0.902**, and gate 5's peak
miss is what that compromise costs. This is the recurring structural pattern in this model —
**one scalar serving two things that need different values** — and it also has instances in the
seasonal lags. Amplitudes are per-hemisphere arrays; **timing parameters are not.**

### 4c. **Ocean carbon-uptake CAPACITY is too small on centennial timescales**
IRF(100) = **0.276** against Joos et al. (2013)'s 0.409, while the tail SHAPE is inside their band
and the **present-day ocean sink is right** (−0.32σ) and the **surface DIC is right** (−0.06σ).
⇒ That combination localizes it: not an uptake RATE error, not a surface carbonate error, but a
**capacity/buffering** one in the interior. ⚠ Gate 12 is a comparison against another model, not an
observation, so this is a **reported difference and an open research question** — the "P5 falsified"
label is withdrawn. What is still owed is a **hypothesis**.

### 4d. **The NH seasonal solubility amplitude is strained to −3.91σ with no mechanism to relieve it**
`sst_seas_amp_NH` = 0.842 at prior z **−3.91**, the worst violation in the model. The SH had the same
problem and it was relieved by giving it a *mechanism* — the Southern-Ocean entrainment channel,
after which `sst_seas_amp_SH` went −5.14 → **+0.24**. **The NH has no such channel**, so the
solubility amplitude is still standing in for whatever the real NH mechanism is.
⚠ Second strained parameter: **`q10` at −2.24**, pushed low, and `q10` is *shared* between the
seasonal cycle and the long-term land temperature response — another one-scalar-two-jobs case.

---

## 5. ⚠ WHAT IS NOT CONSTRAINED AT ALL

- **No law-derived gate anywhere.** Every gate is an observation or (now, for gate S's conversion)
  a lag bound. **Carbonate/Revelle consistency and Henry's-law solubility are both unbuilt** — the
  ocean chemistry is checked against data, never against its own equations.
- **The land/ocean seasonal PARTITION is checked on one limb only.** Gate S scores the ocean limb;
  nothing scores the land one. ⚠ Measured like-for-like the land limb is **1.05×** observed and
  inside its interval, so this is a gap in coverage rather than a known error — but the coverage gap
  is real, and the target for it is now retired (§6).
- **Observations held and unused**: `obs_d14c_station_validation` (160 station Δ¹⁴C points, built as
  a held-out set, read by nothing); the Eide ocean δ¹³C Suess depth profile; the MOD17 **global** NPP
  level (only the NH *share* is used).
- **Absent entirely**: the ocean **anthropogenic carbon inventory** (which would test §4c directly),
  and **atmospheric O₂/APO** (the independent observational land/ocean sink split).

---

## 6. ⚠ AND A METHODOLOGICAL HOLE OPENED TODAY

The **two-signature inversion is retired** (2026-09-04h, option (a)): the 09-02 temperature-dependent
air-sea ¹³C alphas made the ocean's isotopic signature rotate seasonally, so it is no longer the
signed scalar the method assumed, and it no longer runs. Gate S was rebased on an independent pCO₂
route and survives. **But the LAND limb's observed target went with it**, and there is currently no
independent replacement for it — which is why §5's coverage gap cannot be closed today.

---

## 7. ⇒ IF I HAD TO RANK THE FIXES

1. ⭐⭐ **Gate the gradient LEVEL** (§2). Cheapest by far, needs no model change, and it is currently
   hiding a 2× error behind an unstrained parameter.
2. ⭐⭐ **Fix B — an ENSO→ocean mechanism with the right sign** (§4a). The worst defect for a teaching
   model, and now specified and priced.
3. ⭐ **Diagnose the three δ¹³C misses together** (§3a) — level, gradient and SPO seasonal all say
   "too much light carbon in the north".
4. ⭐ **Give the NH a seasonal ocean mechanism** (§4d), the way the SH got one.
5. **A hypothesis for the centennial capacity gap** (§4c) — Marcus asked for one, and it is a
   research question, not a gate to pass.
6. **Build one law-derived gate** (§5) — Revelle or Henry's law.
