# OPTIONS — is P1's band the right yardstick for OPTION A? (2026-09-09l)
# **Ruling owed. Nothing changed on the strength of this note; P1's pre-registered FAIL stands until Marcus rules.**
# **Every model number is GENERATED at the canonical `hilda31` (`h_ml` 49.153) by `calibration/diag_seasonal_ml_geometry.R`, `diag_seas_ml_probe.R`, `diag_seas_ml_convergence.R` and the spinup profile read in this note. Every observation number is from `data/obs_mld.rds` (Holte Argo) or is cited to its product.**

## 0. The question
P1 asks the emergent seasonal ML DIC anomaly to land in **[10, 17] µmol/kg (SH)** and **[8, 14] (NH)**.
MEASURED, converged: **NH 10.26 PASS, SH 9.83 FAIL** by 2.1 % of the floor. Is that band the right
test for option A, or is it the wrong yardstick?

---

## 1. What the band is actually made of — by SOURCE, which is what decides its standing
From `notes/options_2026-09-08d_seasonal_h_ml.md` §2: **half the `f_ent` swing × ΔC**.

| leg | value | SOURCE | standing under `threshold_from_obs_or_law` |
|---|---|---|---|
| `f_ent` half-swing | SH **0.239**, NH **0.1975** | Holte Argo MLD climatology, per-cell (h−h_min)/h | ✅ **OBSERVATION** |
| ΔC | **42–70** µmol/kg | the model's own PI ML→layer-1/2 DIC step, at the **round-3 winner** (`h_ml` 39.8) | ⛔ **THE CODE UNDER TEST**, and a **FITTED** quantity (the LS pump, `kz`) |
| the product form | `f_ent × ΔC` | a dilution scaling | ⚠ **an ansatz**, not a derived law — see §3 |

⇒ **The band is a hybrid, and its scale is set by the leg that is the code under test.** The
standing rule is explicit: a model-derived threshold is a last resort, and *"another model" NEVER
means the code under test — a gate derived from its own numerical agreement is re-baselining in
disguise and can never reject it.* Here the ΔC leg is worse than "another model": it is **this**
model, and a **fitted** part of it. Double `pump_grad` and the band doubles with it.

---

## 2. PROS of keeping the band

1. ⭐⭐ **It was PRE-REGISTERED, and that is not a small thing.** It was written down before the
   mechanism existed, and the number came in afterwards. Discarding a pre-registered bound because
   the result missed it is precisely the failure preregistration exists to prevent. **This is the
   strongest argument for keeping it, and no argument below outweighs it on its own** — which is why
   the FAIL is recorded as a FAIL and this note changes nothing.
2. ✅ **Its shape leg is a real observation** — the Holte Argo climatology, not a guess. The band is
   not model-only.
3. ⭐ **It did the work a pre-check is for.** It established the mechanism is **smaller than the
   fitted compensator** it replaces (21.2 / 19.0) — the substantive question — and it sized to the
   observed order **with nothing tuned**, the same out-of-sample criterion the HS pump met. A test
   that lands within tens of percent untuned has earned some standing.
4. ✅ **Its verdict errs in the SAFE direction.** It stopped the round rather than waving it through.
   A yardstick that is too strict costs a ruling; one that is too loose costs an adoption.
5. ✅ **Cheap, computed, and already spent.** No new data, no new acquisition.

---

## 3. CONS — and the first three are the ones that matter

### 3a. ⛔ The ΔC leg is the code under test, and it is FITTED
Covered in §1. A band that moves with the fit **cannot reject the fit**. This alone disqualifies it
as a *gate*; it does not disqualify it as a *sanity check*.

### 3b. ⛔ The upper edge of the band rests on a geometry that DOES NOT HAPPEN
"42–70" interpolates between the layer-1 step (+42) and the layer-2 step (+97) **on the assumption
that the winter mixed layer punches into layer 2.** Under the mean-preserving ruling at the
canonical it does not: the ML reaches **82.7 / 82.5 m** against a layer-1 base of **101.4 m**
(`diag_seasonal_ml_geometry.R`; the same finding that became gate P8).

**Re-measured at `hilda31`, the entrained water is layer-1 water and nothing else:**

| | ML | layer 1 | layer 2 | **L1 − ML** | L2 − ML |
|---|---|---|---|---|---|
| NH (PI) | 1990.3 | 2034.6 | 2084.0 | **+44.3** | +93.7 |
| SH (PI) | 2007.1 | 2051.4 | 2100.6 | **+44.2** | +93.5 |

⇒ **ΔC is not a 42–70 range. It is +44.2, a point.** ⭐ Note the ΔC leg itself barely moved between
`h_ml` 39.8 and 49.153 (42 → 44.2), so "computed at a different model state" is a **weak**
criticism and is not being pressed. **The defect is the inapplicable upper edge, not staleness.**

**And collapsing the band to the measured ΔC breaks it in a revealing way:**

| | band with ΔC = 44.2 | model (converged) | verdict |
|---|---|---|---|
| NH | 0.1975 × 44.3 = **8.75** | **10.26** | **17 % HIGH** |
| SH | 0.239 × 44.2 = **10.56** | **9.83** | **7 % LOW** |

⇒ **the two hemispheres miss in OPPOSITE DIRECTIONS.** A defect in the *mechanism* would push both
the same way — they share one mechanism and their ΔC agree to 0.2 %. Opposite-signed misses are the
signature of a wrong **functional form**, not a wrong model.

### 3c. ⛔ `f_ent × ΔC` IS THE WRONG ALGEBRA FOR A MOVING BOUNDARY — and the physics is elementary
`f_ent` prices the **shim's imposed** amplitude. For a mixed layer that actually deepens, entrainment
gives, with `c₁` the layer-1 concentration held over a season:

> dc/dt = (dh/dt)(c₁ − c)/h  while deepening; **dc/dt = 0 while shoaling** — detrainment sheds water
> at the ML's OWN concentration, so it changes the stock and the mass together and leaves the
> concentration untouched.

Integrating the deepening limb, `(c₁ − c) ∝ 1/h`, hence

> **Δc(peak-to-trough) = (c₁ − c_min) · (1 − h_min/h_max)** — an UNDAMPED upper bound.

| | h_min/h_max | 1 − r | ΔC | **undamped half-amplitude** | model | model / bound |
|---|---|---|---|---|---|---|
| NH | 0.3595 | 0.6405 | 44.3 | **14.20** | 10.26 | 0.72 |
| SH | 0.3191 | 0.6809 | 44.2 | **15.06** | 9.83 | 0.65 |

✅ **The model sits BELOW the undamped bound in both hemispheres** — it must, because a real DIC
anomaly is continuously relaxed toward the atmosphere, whereas the shim never had to survive
equilibration. ⚠ **The band omits that damping entirely**, so as an undamped construction it should
*overpredict*; instead its under-sized `f_ent` factor pulls it back down. **Two errors partially
cancelling** — the pattern this project has been burned by three times.

**The functional forms are also distinguishable on the hemispheric RATIO, which is the cleanest
discriminator available because it divides ΔC out:**

| SH/NH amplitude ratio | predicted / measured |
|---|---|
| `f_ent` form (0.239 / 0.1975) | **1.21** |
| moving-boundary form (0.3403 / 0.3203) | **1.06** |
| **the model** | **0.96** |

⇒ the model's hemispheric contrast is **6 %** from the moving-boundary form and **26 %** from
`f_ent`. ⚠ This compares two ALGEBRAS against the model's behaviour — it is a statement about which
formula describes the mechanism, **not** evidence that the model is right.

### 3d. ⛔ THE DEEPEST ONE: P1's quantity is UNOBSERVABLE IN PRINCIPLE
P1 scores the **ON-minus-OFF difference** — the mechanism's contribution in isolation. **Nature does
not run a `seas_ml = 0` arm.** There is no observation of "the seasonal DIC anomaly attributable to
entrainment", and there never can be. ⇒ **any band for this quantity is necessarily model- or
theory-derived**, which is why P1 ended up leaning on the code under test. The quantity was chosen so
that it *cannot* be checked against an observation.

### 3e. ⚠ It carries no error bar and no power statement
A **2.1 %** miss is reported against a band whose own inputs have unquantified spread: `f_ent`
depends on a dilution convention (the note records a per-cell and an area-mean form), and ΔC was an
eyeballed range. **A curvature needs an error bar before it needs an explanation**; so does a
2 % rejection.

---

## 4. What to use instead — observation first, then law

### ⭐ 4a. BEST: score the OBSERVABLE, on GATE S's own template
GATE S is classed **"OBSERVATION + LAW"** and already reads the **Landschutzer/Laruelle SOM-FFN**
Southern-Ocean air-sea ΔpCO₂ climatology (NCEI **0209633**) for its **phase**, with **"NO MODEL IN
THE LOOP"** (`calibration/lib_design_gates.R`). **That same product carries the AMPLITUDE of the same
first harmonic.** ⇒ compare the model's own simulated seasonal ΔpCO₂ amplitude against it directly.

- ✅ No derived band, no ΔC leg, no code under test.
- ✅ **Amplitude and phase then come from ONE observation**, so P3 and the amplitude test stop being
  independent conventions that can disagree for bookkeeping reasons.
- ✅ It scores what actually matters — the total seasonal cycle the model must reproduce — rather
  than an unobservable decomposition of it.
- ⚠ **It tests the TOTAL cycle, not the mechanism in isolation.** That is a feature: the isolated
  quantity is the one §3d shows cannot be checked at all.
- ⛔ **The aggregation convention must be fixed FIRST, and this is the live hazard.** The model's ML
  is a hemispheric box; SOM-FFN is 40–90°S. GATE S already hit exactly this and it BIT: the
  SH-area-mean bracket **[1.54, 4.54]** excludes the correct answer while *containing* the pre-fix
  model's 4.16 — "the pre-fix model was matching the **76 %-cancelling area mean**". ⇒ **reuse GATE
  S's settled convention; do not invent a second one.**

### 4b. SECOND: keep the analytic form but take ΔC from GLODAP
If a mechanism-isolating number is still wanted, replace the model's fitted gradient with the
**observed** ML→subsurface DIC gradient over the depth range the ML actually spans. GLODAP is
already in the objective (`obs_glodap_deep/intermediate/profile_cov/sigma_rep`). ⇒ the band's scale
would then be an observation, and §3a dissolves. ⚠ It still leaves §3d: the *target* remains
unobservable.

### 4c. LAW, when no external number is available: assert an ORDERING, not a value
Per the standing rule's last resort. Two orderings the physics gives for free, both already satisfied:
- **0 < emergent amplitude < (c₁ − c_min)(1 − h_min/h_max)/2** — below the undamped bound (§3c).
  ✅ Holds: 0.72 / 0.65 of it.
- **The peak must fall at h_max**, because the concentration rises only while deepening.
  ✅ Holds exactly: NH month 2, SH month 8.

⭐ Both are **stronger than they look**: they are hemisphere-specific, sign-specific, and neither can
be satisfied by a model that has the mechanism wired backwards — which is what a pre-check is for.

---

## 5. Recommendation
**Retire P1's band as a GATE; keep its number as a REPORTED diagnostic; replace it with 4a, on GATE
S's convention, and carry 4c's two orderings as the cheap standing checks.**

⚠ **What that costs, stated plainly:** it replaces a pre-registered bound after seeing the result,
which is a real methodological price and the reason this is a ruling and not a decision I should
take. The defensible version of the move is **not** "the model missed, so widen the band" but
**"the band's scale is the code under test (§3a), its upper edge assumes a geometry that does not
occur (§3b), its algebra is the wrong form for a moving boundary (§3c), and its target is
unobservable in principle (§3d)"** — every one of which is true independently of which side the
model landed on, and three of which were true the day the band was written.

⛔ **If the ruling is that the band stands**, then option A is refuted as built at the SH and the
round stops — and the honest next step is not a refit but a re-derivation of the band under §4b,
because the ΔC leg would then be doing the rejecting.
