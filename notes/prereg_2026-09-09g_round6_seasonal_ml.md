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

**⛔ NOTHING BUILT YET.** Every model number below is GENERATED at `hilda31` by
`scratch/geom{,2,3}.R`-class one-liners quoted inline; every observation number is from
`data/obs_mld.rds$seasonal` (Holte Argo product, built 09-08d).

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
2. **Box mass must track thickness.** `ml_mass_kg` is currently a scalar per hemisphere
   (`R/model.R:2587`, `A * grid$h_ml * RHO_SEAWATER`) and is the denominator of
   `dic_ml <- y[iml,"C"] * mol_per_GtC / ml_mass_kg` (`R/model.R:1833`). It becomes a function of
   `t`. ⛔ **Getting the mass right but not the transfer (or vice versa) silently manufactures or
   destroys DIC** — the conservation assertion in §6.3 is what catches it.
3. **A PERIODIC spinup.** Today's spinup zeroes seasonality and solves a fixed point
   (`ccx_spinup()`); (A) needs a **periodic steady state** — iterate a full year to a year-over-year
   tolerance. **This is the main cost and the main risk of the round.**

---

## 5. Pre-registered predictions

**Probed UNREFITTED at `hilda31` first** (the T-D0 pattern — probe before any Torch array):

- **P1 (sizing, now EMERGENT not imposed).** The seasonal ML DIC anomaly the mechanism *produces*
  lands in **[10, 17] µmol/kg (SH)** and **[8, 14] (NH)** — against the fitted compensator's 21.2
  (round-3 winner) / 19.0 (`ent26`) and its prior centre 10.95. ⛔ Outside those, the mechanism is
  not the compensator's physics and the round stops before the refit.
  ⚠ Model-conditional: the sub-ML gradient (+42 µmol/kg into layer 1) is itself fitted.
- **P2 ⭐ LOAD-BEARING.** On refit, `sst_seas_amp_NH`'s prior-z relaxes from **−2.96** to **inside
  2σ**. The NH analogue of 09-03's P2, and the reason the round exists. ⛔ If it does not relax, the
  NH strain is not seasonal entrainment.
- **P3 (phase).** The SPO ocean limb's phase stays inside **GATE S's bracket [7.41, 10.41]**, the
  peak moving from the registered **7.50** to the observed **8.0**. ⭐ The phase now comes from
  **data**, not a registered constant.
- **P4 ⭐ THE DISCRIMINANT — and under (A) it is GENUINELY TESTABLE.** The `d13c_seasonal_*` rows
  **IMPROVE or HOLD**: entrainment brings isotopically light water up in winter, a signal solubility
  cannot produce. ⛔ **If they PAY, the mechanism is wrong in the isotope and (A) is refuted.**
- **P5 (Δ¹⁴C, free and unfudged).** The seasonal Δ¹⁴C signature appears with **no ¹⁴C fractionation
  term added anywhere**. The `d14c_*` rows move by **less than `sigma_d14c`** — entrainment is a
  surface-cycle mechanism and must not disturb the bomb constraint.
- **P6 (no free lunch).** `co2_seasonal_SPO` / `co2_seasonal_MLO` move by **less** than the fitted
  21.2 compensator would predict — the mechanism is *smaller* than the thing it replaces — and the
  likelihood loses no more at the SH seasonal rows than the compensator's own worth. The round is
  judged on whether the NH gain (P2) exceeds that loss.
- **P7 ⭐ NOT A DEEP LEVER IN DISGUISE.** The **modern** surface−deep δ¹³C gradient (**0.40** at
  `hilda31`) does not move by more than the `ocean_grad_d13c` row's σ_eff (**0.16**).
  ⚠ **Modern, like-for-like — never the PI number** ([[ccx_cheap_probes_20260908h]]'s retraction).
- **P8 ⛔ GEOMETRY STOPPING CONDITION (§3c).** The refitted `h_ml` stays **below 76.1 m**. If it
  crosses, the winter ML punches layer 1, single-layer entrainment is **invalid**, and the round
  **stops and reports** rather than adopting. ⚠ `ent26` sat at 134 m — this can happen.

**Reported, never scored:** IRF(100), and the land share of a pulse — **comparisons** by the 09-04e
ruling. ⛔ **No Joos row anywhere in this prereg.**

---

## 6. Build order

1. **Grid decoupling** (§3a): interior grid from the annual-mean `h_ml`; ML/layer-1 boundary moves.
2. **Both cores**, R `ccx_deriv` and `src/ccx_core.cpp`: `h_ml(t)`, time-varying `ml_mass_kg`, the
   two entrainment limbs at `alpha13 = 1`.
3. **Periodic spinup** (§4.3) — the risk item; do it before the probe, not after.
4. **Tests BEFORE the probe.** R/C++ **parity**; a **mutation test at an explicit non-zero seasonal
   amplitude** ([[default_off_hides_the_bug]] — a mechanism defaulted off is untested where it
   matters); ⭐ a **conservation assertion that total C, C13 and C14 are unchanged by a full
   entrain–detrain cycle**; a **mutation test on P8's bound** (set `h_ml` = 90 and confirm the build
   REFUSES rather than silently reading out of layer 1) ⇒ [[mutation_test_gates]];
   `test-mode-struct-lint` still green.
5. **Probe unrefitted at `hilda31`:** P1, P3, P6, P7, gate S. **Stop here if P1 fails.**
6. **Refit on Torch.** ⭐ **Verdict said out loud** ([[consider_torch_first]]): a **30-parameter
   multistart is a Torch array, not a laptop job** — 24 starts, one wave, ~2.5 h on the 09-08e
   recipe. ⚠ The periodic spinup may raise the per-evaluation cost materially
   ([[ccx_spinup_is_the_cost]]: 84 % of an evaluation is already the spinup) — **re-time a single
   evaluation before sizing the array.** Port targets committed at the launch commit; preflight 8/8;
   ⛔ **NEVER re-ship the bundle mid-array** ([[never_reship_mid_array]]).
7. Score against P1–P8. **Adoption is Marcus's call.** Then the whole-model scorecard arm.

## 7. What this round does NOT touch
The ENSO ocean sign (**the blocker** — the tropical box, weeks), the ventilation limb (E), Martin
remineralisation (D, needs E first), `alk_hs` (closed: not a lever), and the three open σ-audit
items — of which **`gcb_ocean_sink`'s uninflated 0.4 GtC/yr is an objective change needing its own
ruling**, separately from this one.
