# PREREG — round 6 = **OPTION A**: a TRUE seasonal mixed layer that entrains real water
# (option **(A)** of `notes/options_2026-09-08d_seasonal_h_ml.md`. ⚠ **Lettering collides across
# notes**: 09-08j's ranking calls this round "option C"; the 09-08d note's "(C)" is the free-`h_ml`
# prior, already SHIPPED in round 4. This document builds the **time-varying mixed layer**.)

**RULED BY MARCUS 2026-09-09g, and this document is written to those rulings:**
1. ⭐ **Build (A), the real seasonal mixed layer** — *not* the derived-amplitude shim (B). Reason in
   §3: **B's isotopic discriminant is compromised before it runs.**
2. ⭐ **The seasonal shape is MEAN-PRESERVING** (the "demeaned" ruling): `h_ml(t)` is the MLD
   climatology **scaled so its annual mean is the fitted `h_ml`**. The annual-mean entrainment
   effect is already inside the fitted `h_ml`, pump and `kz`; a non-mean-preserving shape
   double-counts it.

Baseline: canonical `hilda31` (31 par, struct hilda, logpost −1478.66,
`calibration/output/refit_20260908_hilda31/mode_fit_pumpN.rds`).
Read first: `notes/options_2026-09-08d_seasonal_h_ml.md`, `notes/handoff_2026-09-08j_next_step_recommendation.md` §4–5.
Memory: [[ccx_seasonal_h_ml_option]], [[ccx_pedagogical_not_emulator]], [[ccx_gate_s_ocean_phase]],
[[default_off_hides_the_bug]], [[never_reship_mid_array]], [[consider_torch_first]].

**⛔ NOTHING BUILT YET.** Every model number in §3 is GENERATED at `hilda31` by
**`calibration/diag_seasonal_ml_geometry.R`** (→ `outputs/diagnostics/seasonal_ml_geometry_20260909.{rds,log}`),
which is committed and re-runnable; every observation number is from `data/obs_mld.rds$seasonal`
(Holte Argo product, built 09-08d).

---

## 1. What is being replaced

`ent_seas_amp_SH`, the 26th parameter (freed 09-03), adds a **zero-mean sine** to the SH mixed
layer's DIC *for the pCO₂ computation only* — `R/model.R:1857-1860`, `src/ccx_core.cpp:535-538`:

```
dic_ml <- dic_ml + p$ent_seas_amp_SH * 1e-6 * sin(2*pi*(t - (CCX_ENT_SEAS_PEAK_MO/12 - 0.25)))
```

A **fitted amplitude, a registered phase, no link to how deep the mixed layer goes, and no NH
counterpart** — which is where the strain sits (`sst_seas_amp_NH` prior-z **−2.96** at `hilda31`).

**Round 6 replaces it with a mixed layer that actually deepens and shoals**, entraining real water —
carbon and both isotopes — from the layer below. `ent_seas_amp_SH` **RETIRES: 31 → 30 parameters**
⇒ **comparable on LIKELIHOOD only**, never on a logpost.

---

## 2. ⭐ WHY (A) AND NOT THE ONE-DAY SHIM — the finding that decided it (verified in source)

The shim is **pCO₂-side: it moves no carbon.** `add_flux` takes `r13 <- y[src,"C13"]/y[src,"C"]`
from the **source box's own ratio** (`R/model.R:1441-1443`), so the evasion limb carries the ML's
**unmodified** signature. ⇒ **option B has NO isotopic signature in EITHER isotope**, and **P4 — the
one thing solubility cannot fake — cannot be tested as designed.**

Entrained water is light in δ¹³C **and older in Δ¹⁴C**. Option A carries **both for free and
correctly**, and needs **no ¹⁴C fractionation term at all**: the model stores Δ¹⁴C, normalised to
α₁₄ = α₁₃², so a Δ¹⁴C tracer crosses a fractionating interface unfractionated and adding an alpha
would double-count ~17 ‰ ≈ 3× `sigma_d14c` (`R/model.R:1445-1455`; the one live trap in `MEMORY.md`).

⇒ the 09-08d note's *"(A) only if (B)'s isotope test fails"* was **too weak**: B's isotope test is
compromised **before** it runs.

---

## 3. ⭐⭐ THE GEOMETRY, MEASURED — and it is FAVOURABLE, with one hard bound

### 3a. The grid must be DECOUPLED from the moving ML base
`ccx_ocean_grid(h_ml)` derives **every interior thickness** from `h_ml`:
`dz_int <- (total_depth - h_ml) * w / sum(w)` (`R/model.R:766`). Feeding a time-varying `h_ml`
through it unchanged would move **every interface in the column** seasonally — including the
1314–1861 m NADW layer — re-anchor `K(z)` (which pins `K(h_ml) = kz` **exactly**, `R/model.R:2496-2497`)
and change the substep stability count every month. That is wrong physics and expensive.

⇒ **The build holds the interior grid FIXED**, constructed once at the **annual-mean** fitted
`h_ml`. Only the ML/layer-1 boundary moves: `dz_ML(t) = h_ml(t)`, `dz_1(t) = dz_1 + (h_ml − h_ml(t))`.
**Layer 1 absorbs the whole excursion.** Interior interfaces, `K(z)`'s anchor and the substep count
are untouched — so *nothing below layer 1 can tell the difference*, which is also what P7 asserts.

### 3b. ✅ The winter mixed layer STAYS INSIDE LAYER 1 at the canonical
At `hilda31`, fitted **`h_ml` = 49.15 m**, and the mean-preserving climatology reaches:

| | ML min | ML **max** | layer-1 base | punches layer 1? |
|---|---|---|---|---|
| NH | 29.7 m | **82.7 m** (Feb) | **101.4 m** | **no** |
| SH | 26.3 m | **82.5 m** (Aug) | **101.4 m** | **no** |

⭐ **This is the result that makes (A) tractable.** The 09-08d note feared "a winter mixed layer of
83 / 114 m reaches through layer 1 into layer 2" — that was computed at the round-3 winner's
`h_ml` 39.8 using the **raw** observed depths. Under the **mean-preserving** ruling at the
**canonical**, it does not happen: single-layer entrainment suffices, and no multi-layer
entrainment code is needed.

### 3c. ⛔ THE HARD BOUND: the design breaks if a refit pushes `h_ml` past ~76 m
max/mean of the climatology is **1.682 (NH) / 1.678 (SH)** — nearly identical — while layer 1's base
grows only ~0.99 × `h_ml` + a constant. Solving for the crossing (`uniroot`, not algebra):

> **The winter ML punches layer 1 when fitted `h_ml` > 76.1 m (NH) / 76.6 m (SH).**
> At `hilda31`'s 49.15 m the margin is **27 m**.

⚠ **This is NOT hypothetical: `ent26`'s `h_ml` was 134.15 m** — the design would have been invalid
there. ⇒ **P8 below is a stopping condition on the refit, not a footnote.**

### 3d. ✅ The high-latitude box does NOT get dragged
`h_hs` follows `grid$h_ml` **only when `p$h_hs <= 0`** (`R/model.R:2531`). At `hilda31`
**`h_hs` = 401.1 m**, pinned — so a seasonal ML leaves the HILDA surface box alone. ⚠ Re-check this
if a future mode file sets `h_hs = 0`.

---

## 4. What (A) must get right

1. **Entrainment / detrainment as a real transfer.** Deepening moves water from layer 1 into the ML
   at **layer-1 concentrations** (C, C13, C14); shoaling leaves ML water behind at **ML
   concentrations**. Both directions through `add_flux`, resolved **per direction** — ⛔ never one
   signed flux, which is the 2026-08-25e seasonal-NEP bug and no conservation gate can see it.
   These limbs carry **`alpha13 = 1`**: entrainment is physical transport, not a fractionating
   exchange.
2. ⚠ **The SUBSTEP BOUND must be taken at the THINNEST ML, not the mean.** `ccx_substeps_for()`
   sizes stability from `kz / (dz_k * dz_mid_k)` and `w / dz_k` on a grid built at the annual mean;
   the summer ML thins to **26–30 m** against that 49 m mean, tightening both. Compute the bound on
   the grid at `min(h_ml(t))` — the conservative direction, and one line.
   ✅ Contained, because only two thicknesses move and one combination does not: `dz_ML + dz_1` is
   **conserved by construction**, so `dz_mid[1] = (dz_ML + dz_1)/2` is **invariant**; only
   `dz_mid[2]` varies. And `kz_int` must be computed **once at the annual mean** and held — the
   interior interfaces do not move, so their `K` must not either, while the ML base keeps
   `K = kz` by the anchor convention.
3. **Box mass must track thickness.** `ml_mass_kg` is currently a scalar per hemisphere
   (`R/model.R:2587`, `A * grid$h_ml * RHO_SEAWATER`) and is the denominator of
   `dic_ml <- y[iml,"C"] * mol_per_GtC / ml_mass_kg` (`R/model.R:1833`). It becomes a function of
   `t`. ⛔ **Getting the mass right but not the transfer (or vice versa) silently manufactures or
   destroys DIC** — the conservation assertion in §6.4 is what catches it.
4. ⭐⭐ **A PERIODIC SPINUP IS NOT NEEDED — CONFIRMED TWICE (09-09j), the round's stated main risk
   is retired.** By construction (the C++ guard's first firing showed `ccx_spinup()` solves through
   that path at `seas_drivers = 0`) and by measurement (**P10**: the quiet-window rectification is
   settled).
   `R/spinup.R:227` sets `p0$seas_drivers <- 0`: the spinup is **aseasonal by construction**, and
   every existing seasonal mechanism (seasonal SST, the land drivers, the `ent_seas_amp_SH` shim)
   already lives under that one switch precisely so the spinup's zeroing covers it and
   `seas_drivers = 0` stays the **exact** aseasonal model. ⇒ **Put the seasonal ML under the SAME
   switch** and the spinup keeps its existing fixed point; the seasonal cycle equilibrates in the
   transient on ML timescales (months).
   ⚠ **The one thing to CHECK, not assume:** unlike the pCO₂-side shim, (A) moves **real carbon**
   seasonally, so it rectifies onto the annual-mean state. The model already accepts that class of
   rectification as physics (seasonal SST, the fertilisation rectifier). **Measure the annual-mean
   drift over the first decades of the transient**; only if it fails to settle does a periodic
   steady state become necessary. ⇒ **The round is materially cheaper than §6 first scoped it.**

---

## 5. Pre-registered predictions

**Probed UNREFITTED at `hilda31` first** (the T-D0 pattern — probe before any Torch array):

- **P1 ⛔⛔ RETIRED AS A GATE (Marcus, 2026-09-09m)** — *"I'm fine getting rid of a pre-registered
  bound if and when we determine that the pre-registered bound was flawed in the first place."*
  The band [10, 17] / [8, 14] is **still computed and REPORTED** (NH **10.23**, SH **9.79**;
  converged — P9) but **decides nothing**. Why, from `notes/options_2026-09-09l_p1_yardstick.md` —
  all four true independently of which side the model landed on, and **three true the day the band
  was written**: (a) its SCALE leg (ΔC 42–70) is the **CODE UNDER TEST**, and **fitted**; (b) its
  upper edge assumes the winter ML reaches layer 2, which it **does not** (82.7 / 82.5 m against a
  layer-1 base of 101.4) — the measured step is a **point, +44.2**; (c) `f_ent × ΔC` is the **wrong
  algebra** for a moving boundary (P1a); (d) its target — the ON-minus-OFF difference — is
  **UNOBSERVABLE IN PRINCIPLE**, since nature runs no `seas_ml = 0` arm.
  ⭐ **Replaced by two ORDERINGS (P1a, P1b) and, once unblocked, one OBSERVATION (P1c).**

- **P1a ✅ BELOW THE UNDAMPED MOVING-BOUNDARY BOUND — a LAW. PASS.** Entrainment gives
  `dc/dt = (dh/dt)(c₁−c)/h` while deepening and **zero while shoaling** (detrainment sheds water at
  the ML's own concentration, moving stock and mass together). Integrating, `(c₁−c) ∝ 1/h`, so
  **Δc(pk-pk) = (c₁ − c_min)(1 − h_min/h_max)** — undamped, because a real DIC anomaly is relaxed
  toward the atmosphere and the retired shim never had to survive that. **MEASURED: bound 14.20 (NH)
  / 15.06 (SH) half-amplitude; emergent 10.23 / 9.79; ratio 0.72 / 0.65 — inside (0, 1) in both.**
  ⭐ An ordering between two **measured** quantities, not an invented threshold. Mutation-tested.
- **P1b ✅ THE ANOMALY MUST PEAK AT MAXIMUM MIXED-LAYER DEPTH — a LAW. PASS.** The concentration
  rises only while the layer deepens. **NH month 2, SH month 8 — both match `h_max` exactly.**
  Hemisphere- and sign-specific: a backwards-wired limb fails it. Mutation-tested.
- **P1c ⛔ THE OBSERVATIONAL TEST — PREPARED, BLOCKED ON TWO RULINGS.** On **GATE S's own template**
  (classed "OBSERVATION + LAW", **no model in the loop**): the Landschutzer/Laruelle **SOM-FFN**
  climatology (NCEI **0209633**) is **already local** and carries the amplitude of the same first
  harmonic as GATE S's phase. **EXTRACTED** (`calibration/diag_so_pco2_amplitude.R`), same masks and
  same estimator — the magnitude of the **mean harmonic vector**, never the mean of per-month
  magnitudes:

  | band | amp (µatm) | peak month |
  |---|---|---|
  | **SO 40–90 °S** (GATE S's band) | **16.26** | **7.50** |
  | SO 60–90 °S | 25.19 | 7.79 |
  | SO 40–60 °S | 11.31 | 7.10 |
  | SH 30–40 °S | 22.19 | 1.28 |
  | SH subtrop 0–30 °S | 12.62 | 1.43 |
  | **SH all (0–90 °S)** | **3.69** | 1.20 |
  | NH all | 1.77 | 8.14 |

  ⭐ The 40–90 °S phase **7.50** sits beside GATE S's **7.41**; not identical, and it should not be
  — GATE S uses the air-sea **DIFFERENCE**, this is ocean pCO₂ alone. They agree closely because the
  SH atmospheric cycle (~1 ppm) is small against the ocean's 16 µatm. ⛔⛔ **AND THE AGGREGATION
  HAZARD IS NOW QUANTIFIED: the hemispheric mean is 3.69 µatm against the Southern Ocean's 16.26 —
  a 4.4× cancellation**, because the subtropics (peak Jan) and the Southern Ocean (peak Jul) are in
  ANTIPHASE. Picking the wrong band moves the target by **4.4×**. This is the same hazard that bit
  GATE S, whose SH-area-mean bracket excluded the right answer while containing the pre-fix model.
  **BLOCKED ON:** (1) **which band maps to the model's `ml` box** — it is the LOW-LATITUDE surface
  box, since `hs_frac` splits the high latitudes into `hs`; **reuse GATE S's settled convention, do
  not invent a second**; and (2) **the model does not expose mixed-layer pCO₂** — `ccx_run()$out`
  carries `ml_C`/`ml_C13` and the flux trace carries none, so that output must be added first.
  ⛔ **pCO₂ IS NOT FLUX**: these may not be quoted as flux amplitudes.

- **P2 ⭐ LOAD-BEARING.** On refit, `sst_seas_amp_NH`'s prior-z relaxes from **−2.96** to **inside
  2σ**. The NH analogue of 09-03's P2, and the reason the round exists. ⛔ If it does not relax, the
  NH strain is not seasonal entrainment.
- **P3 (phase).** The SPO ocean limb's phase stays inside **GATE S's bracket [7.41, 10.41]**, the
  peak moving from the registered **7.50** to the observed **8.0**. ⭐ The phase now comes from
  **data**, not a registered constant.
- **P4 ⭐ THE DISCRIMINANT — and under (A) it is GENUINELY TESTABLE.** The `d13c_seasonal_*` rows
  **IMPROVE or HOLD**: entrainment brings isotopically light water up in winter, a signal solubility
  cannot produce. ⛔ **If they PAY, the mechanism is wrong in the isotope and (A) is refuted.**
- **P5 (Δ¹⁴C, free and unfudged).** ✅ **FIRST HALF VERIFIED 09-09j**: the signature appears with
  **no ¹⁴C fractionation term added anywhere** — the entrainment limbs run at `alpha13 = 1` and
  `add_flux` carries Δ¹⁴C unfractionated by the α₁₄ = α₁₃² convention; `test-seas-ml.R` asserts the
  ML's ¹⁴C **ratio** is pulled toward layer 1's older water while deepening and not while shoaling.
  ⚠ **Second half still owed** (the rows' movement). The seasonal Δ¹⁴C signature appears with
  **no ¹⁴C fractionation term added anywhere**. The `d14c_*` rows move by **less than `sigma_d14c`** — entrainment is a
  surface-cycle mechanism and must not disturb the bomb constraint.
- **P6 (no free lunch).** `co2_seasonal_SPO` / `co2_seasonal_MLO` move by **less** than the fitted
  21.2 compensator would predict — the mechanism is *smaller* than the thing it replaces — and the
  likelihood loses no more at the SH seasonal rows than the compensator's own worth. The round is
  judged on whether the NH gain (P2) exceeds that loss.
- **P7 ⭐ NOT A DEEP LEVER IN DISGUISE.** The **modern** surface−deep δ¹³C gradient (**0.40** at
  `hilda31`) does not move by more than the `ocean_grad_d13c` row's σ_eff (**0.16**).
  ⚠ **Modern, like-for-like — never the PI number** ([[ccx_cheap_probes_20260908h]]'s retraction).
- **P8 ⛔ GEOMETRY STOPPING CONDITION (§3c) — ✅ NO LONGER A PREDICTION, IT IS AN ENFORCED GATE.**
  The refitted `h_ml` must stay **below 76.1 m**; past it the winter ML punches layer 1 and
  single-layer entrainment is **invalid**. Implemented as `ccx_seas_ml_guard()`, which **STOPS
  rather than clamping** — a clamp would turn a design violation into a quiet bias — and is
  **mutation-tested** at `h_ml` 90 and at `ent26`'s **134.15**. ⇒ a refit cannot cross it silently.

**ADDED 2026-09-09j — four pre-checks this list did not have, two already executed:**

- **P9 ✅ SUBSTEP CONVERGENCE — EXECUTED, CONVERGED.** `ccx_substeps_for()` bounds diffusion and
  advection, but the model's own substepping rationale is the **air-sea timescale `h_ml/k_w`, which
  shrinks with the mixed layer**: 0.0296 yr (10.8 d) at the annual mean but **0.0158 yr (5.8 d) at
  the summer minimum (26.3 m)**, against a substep of 30/4 = 7.6 d — so in summer the ML
  equilibrates **faster than a substep resolves**, and the eigenvalue bound cannot see it (it
  returns 4 either way, because `CCX_SUBSTEPS_MIN = 4` is the floor; the §4.2 change is therefore
  **inert at the canonical**). MEASURED: P1's amplitude moves **0.38 %** from 4 to 16 substeps,
  against a **1 %** tolerance scaled to P1's own band width. ⇒ **P1 is measuring the model, not the
  integrator.**
- **P10 ✅ THE RECTIFICATION SETTLES — EXECUTED, and it needed TWO WINDOWS to be answerable.**
  Option A moves real carbon, so it rectifies onto the annual mean. A trend in the on-minus-off
  difference over an **industrial** window has two causes needing opposite responses — **spin-in**
  (a periodic spinup is owed) or **a change in anthropogenic uptake** (real physics) — and one
  window reports them identically. ⛔ A first version measured only 1900–2000, got "still drifting",
  and could not tell which. MEASURED on both: **QUIET (1750–1850, near-zero emissions) is SETTLED**
  — trend/century 3.84 % (NH) / 3.07 % (SH) of the seasonal amplitude, inside the 5 % ordering ⇒
  **no spin-in; the aseasonal spinup STANDS and no periodic spinup is owed** (the §4.4 claim, now
  measured rather than argued). ⚠ **The NH margin is thin (3.84 % against 5 %) — re-measure after
  any refit that moves `h_ml`.** **INDUSTRIAL NH drifts at 7.72 %** ⇒ **the seasonal mixed layer
  changes how the ocean takes up anthropogenic carbon — a RESULT to report, not a defect to fix.**
- **P11 ⛔ C++ PARITY AT `seas_ml = 1` — OWED, and blocked on the twin.** The tolerance is
  **derived from the flux count**, never fitted to a measurement (the 2026-08-16e discipline):
  the mechanism adds 2 limbs, so the reassociation bound is `n_terms × eps × throughput`.
  Until then `R/cpp.R` **STOPS** rather than silently running the aseasonal ML — parity cannot see
  a run nobody compares.
- **P12 ⚠ THE COMPENSATOR MUST BECOME REDUNDANT — OWED.** If (A) is the physics `ent_seas_amp_SH`
  was standing in for, then refitting with **both** active must drive the compensator **toward
  zero**. If instead it stays large, (A) is an ADDITION to the shim rather than its **replacement**,
  and retiring the parameter would not be justified. ⇒ this is the test that distinguishes "one
  mechanism" from "two", and it is cheap: profile `ent_seas_amp_SH` at the canonical with
  `seas_ml = 1`.

**Reported, never scored:** IRF(100), and the land share of a pulse — **comparisons** by the 09-04e
ruling. ⛔ **No Joos row anywhere in this prereg.**

---

## 6. Build order

1. **Grid decoupling** (§3a): interior grid from the annual-mean `h_ml`; ML/layer-1 boundary moves.
2. **Both cores**, R `ccx_deriv` and `src/ccx_core.cpp`: `h_ml(t)`, time-varying `ml_mass_kg`, the
   two entrainment limbs at `alpha13 = 1`.
3. **Put the mechanism under `seas_drivers`** (§4.3) — the spinup then needs NO change. ⭐ Measure
   the annual-mean rectification drift in the transient and report it; build a periodic steady state
   **only if** that measurement says the aseasonal fixed point will not do.
4. **Tests BEFORE the probe.** R/C++ **parity**; a **mutation test at an explicit non-zero seasonal
   amplitude** ([[default_off_hides_the_bug]] — a mechanism defaulted off is untested where it
   matters); ⭐ a **conservation assertion that total C, C13 and C14 are unchanged by a full
   entrain–detrain cycle**; a **mutation test on P8's bound** (set `h_ml` = 90 and confirm the build
   REFUSES rather than silently reading out of layer 1) ⇒ [[mutation_test_gates]];
   `test-mode-struct-lint` still green.
5. **Probe unrefitted at `hilda31`:** P1, P3, P6, P7, gate S. **Stop here if P1 fails.**
6. **Refit on Torch.** ⭐ **Verdict said out loud** ([[consider_torch_first]]): a **30-parameter
   multistart is a Torch array, not a laptop job** — 24 starts, one wave, ~2.5 h on the 09-08e
   recipe. ⭐ With the spinup unchanged (§4.3) the per-evaluation cost should be **essentially flat** —
   84 % of an evaluation is the spinup ([[ccx_spinup_is_the_cost]]) and the spinup does not move.
   ⚠ **Re-time a single evaluation anyway before sizing the array**; the transient gains two flux
   limbs and a tighter substep bound (§4.4). Port targets committed at the launch commit; preflight 8/8;
   ⛔ **NEVER re-ship the bundle mid-array** ([[never_reship_mid_array]]).
7. Score against P1–P8. **Adoption is Marcus's call.** Then the whole-model scorecard arm.

## 7. What this round does NOT touch
The ENSO ocean sign (**the blocker** — the tropical box, weeks), the ventilation limb (E), Martin
remineralisation (D, needs E first), `alk_hs` (closed: not a lever), and the three open σ-audit
items — of which **`gcb_ocean_sink`'s uninflated 0.4 GtC/yr is an objective change needing its own
ruling**, separately from this one.
