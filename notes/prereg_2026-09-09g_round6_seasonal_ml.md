# PREREG — round 6 = OPTION C ALONE: the seasonal mixed layer with a DERIVED entrainment amplitude
# (option **B** of `notes/options_2026-09-08d_seasonal_h_ml.md`; "option C" is its name in the
# 09-08j ranking. The two letterings collide — **this document builds the DERIVED-AMPLITUDE
# ENTRAINMENT**, and never the free-`h_ml`-prior variant that the 09-08d note calls (C).)

**Status: DRAFT, nothing built, awaiting Marcus on §3.** Baseline is the canonical `hilda31`
(31 par, struct hilda, logpost −1478.66, `calibration/output/refit_20260908_hilda31/mode_fit_pumpN.rds`).
Read first: `notes/options_2026-09-08d_seasonal_h_ml.md` (the design and its pre-check),
`notes/handoff_2026-09-08j_next_step_recommendation.md` §4–5 (why C before B).
Memory: [[ccx_seasonal_h_ml_option]], [[ccx_pedagogical_not_emulator]], [[ccx_gate_s_ocean_phase]],
[[default_off_hides_the_bug]], [[never_reship_mid_array]].

---

## 1. What is being replaced, exactly

The model carries a seasonal mixed layer **in disguise**: `ent_seas_amp_SH`, the 26th parameter
(freed 09-03), adds a **zero-mean sine** to the SH mixed layer's DIC *for the pCO₂ computation only*
— `R/model.R:1857-1860` and `src/ccx_core.cpp:535-538`, one expression each:

```
dic_ml <- dic_ml + p$ent_seas_amp_SH * 1e-6 * sin(2*pi*(t - (CCX_ENT_SEAS_PEAK_MO/12 - 0.25)))
```

It is winter entrainment of DIC-rich water **with a fitted amplitude, a registered phase, no link
to how deep the mixed layer actually goes, and no NH counterpart** — which is where the strain now
sits (`sst_seas_amp_NH` prior-z **−2.96** at `hilda31`).

**The build replaces the fitted amplitude with the one the MLD climatology and the model's own
vertical DIC gradient imply, in BOTH hemispheres:**

```
dic_ml <- dic_ml + (C_1 - C_ml)(t) * fbar_h(month)
```

with `fbar_h` from `data/obs_mld.rds$seasonal$<h>$f_ent` (built 09-08d, **verified present**:
NH 12 values, mean 0.461, max 0.652 Feb-Jan, min 0.257; SH mean 0.461, max 0.680 Aug, min 0.202).
`ent_seas_amp_SH` **RETIRES: 31 → 30 parameters.** ⇒ **comparable on LIKELIHOOD only**, never on a
logpost (objective/space change; the standing rule).

---

## 2. Why this is the pedagogical standard and not a re-parameterisation

CCX is a **pedagogical model, not an emulator** ([[ccx_pedagogical_not_emulator]]). The test a
mechanism must pass is that it **sizes to the observation with nothing tuned** — the criterion the
HS pump met. Recomputed here from the 09-08d note's own numbers (model side: `hilda31`'s
preindustrial ML vs layer 1, **C₁ − C_ml = +42 µmol/kg**, reaching **~+70** where the winter layer
punches into layer 2):

| | half-swing of `f_ent` | × ΔC 42–70 | **implied amplitude** | fitted compensator |
|---|---|---|---|---|
| SH | (0.680 − 0.202)/2 = 0.239 | | **10–17 µmol/kg** | 21.2 (round-3 winner), 19.0 (`ent26`) |
| NH | (0.652 − 0.257)/2 = 0.198 | | **8–14 µmol/kg** | *none — the model has no NH channel* |

⚠ **These are model-conditional**: the gradient C₁ − C_ml is itself fitted (the LS pump, `kz`), so
this is an order check, not an independent measurement. It is still the right check — the mechanism
lands on the observed order **before** any tuning, and it hands the NH a channel it does not have.

---

## 3. ⚠ TWO DESIGN CHOICES THAT ARE NOT MINE TO MAKE — Marcus, these are the ruling

### 3a. **DEMEANED or RAW `f_ent`?** — recommendation: **DEMEANED**

`f_ent` is a **positive** quantity (NH 0.257–0.652). Used raw it adds a **level shift** of
`mean(f_ent) × ΔC ≈ 0.461 × 42 ≈ +19 µmol/kg` to the mixed layer's pCO₂-side DIC all year round —
not a seasonal cycle at all, and a large bias on the annual-mean air-sea flux.

**Recommendation: `fbar_h(month) = f_ent(month) − mean(f_ent)`.** Physically, an ML that returns to
the same depth each year entrains for half the year and detrains for the other half: the *annual
mean* effect of entrainment is already inside the fitted `h_ml`, the pump and `kz`. Using raw
`f_ent` **double-counts it**. The demeaned form is also what the 09-08d note's own pre-check assumes
(it takes *half the f-swing*), and it preserves the current shim's zero-mean convention, so the
change is attributable to *shape and hemisphere*, not to a new level.
⚠ **If this is ruled RAW instead, §2's amplitude table does not apply and P1/P2 must be rewritten
before anything is built.**

### 3b. **HOW THE ¹³C STEP IS CARRIED** — and this one may sink form (B) outright

This is a **pCO₂-side shim: it moves no carbon.** The ML's δ¹³C state is untouched, so the evasion
limb (`add_flux(iml, iatm, gx * pco2_ml, alpha13 = a_as$up, alpha13_signed = TRUE)`,
`R/model.R:1884`) carries the ML box's **unmodified** signature — **verified, not assumed**:
`add_flux` takes `r13 <- y[src,"C13"]/y[src,"C"]` from the **source box's own ratio**
(`R/model.R:1441-1443`). ⇒ **as written, the derived form has NO isotopic signature** beyond a
larger flux at the old ratio — and the isotopic signature is the entire discriminant (P4), the one
thing solubility cannot fake.

⚠ **And it forfeits BOTH isotopes, not one.** Entrained subsurface water is isotopically light in
δ¹³C *and* depleted in Δ¹⁴C (it is older). Form (A) carries both **for free**, correctly, and needs
**no ¹⁴C fractionation term at all** — the model stores Δ¹⁴C, which is by definition normalised to
α₁₄ = α₁₃², so adding one would double-count ~17 ‰ ≈ 3× `sigma_d14c` (`R/model.R:1445-1455`; the
one live trap in `MEMORY.md`). A pCO₂-side shim reproduces neither signature, and the Δ¹⁴C rows are
the most heavily scored in the stack. **This is the strongest argument in the document for (A).**

Carrying it requires **special-casing the evasion limb's source signature** to be seasonally lighter
than the ML box it draws from — a deliberate departure from `add_flux`'s "the source box's own
ratio" convention, which is the convention that makes the conservation and double-discrimination
guards work ([[ccx_enso_gpp_modulation]]'s two-limb lesson is the same class of trap).

**Three ways out, my ranking:**
1. ⭐ **Special-case it, and gate it.** One expression, an explicit `alpha13_signed` source override,
   plus a **mutation test at an explicit non-zero amplitude** ([[default_off_hides_the_bug]]) and a
   conservation assertion that the override moves ¹³C **and only** ¹³C. Keeps the one-day cost.
2. **Build form (A) instead** — a true time-varying `h_ml` that entrains real water, carbon and both
   isotopes. Conservation and the isotopes come out **for free and correctly**, and it is the
   honest pedagogy. **Cost: days, and it touches the spinup fixed point** (today's spinup zeroes
   seasonality and solves for a steady state; (A) needs a *periodic* steady state). The 09-08d note
   reserved (A) for "if (B)'s isotope test fails" — ⚠ **this argues (B)'s isotope test is
   compromised by construction, not merely at risk.**
3. **Build (B) with NO isotopic step**, score only the CO₂ seasonal rows, and report P4 as untested.
   Cheapest and honest, but it forfeits the discriminant and cannot refute the mechanism.

⚠ I am **not** resolving this. It changes what the round can conclude.

---

## 4. Pre-registered predictions

**Probed UNREFITTED at `hilda31` first** (the T-D0 pattern — a probe before a Torch array):

- **P1 (sizing).** The derived SH amplitude lands in **[10, 17] µmol/kg**, the NH in **[8, 14]**,
  at `hilda31`'s own gradient. ⛔ Outside those, the mechanism is not the compensator's physics and
  the round stops before the refit.
- **P2 ⭐ LOAD-BEARING.** On refit, `sst_seas_amp_NH`'s prior-z relaxes from **−2.96** to **inside
  2σ**. This is the NH analogue of 09-03's P2 and the reason the round exists. ⛔ If it does not
  relax, the NH strain is not seasonal entrainment and (B) is refuted as built.
- **P3 (phase).** The SPO ocean limb's phase stays inside **GATE S's bracket [7.41, 10.41]**, with
  the peak moving from the registered **7.50** to the observed **8.0** (SH `f_ent` max, August).
  ⭐ The phase now comes from **data**, not a registered constant — a strengthening either way.
- **P4 (the discriminant, conditional on §3b).** The `d13c_seasonal_*` rows **IMPROVE or HOLD**.
  Entrainment brings isotopically light water up in winter — a signal the solubility cycle cannot
  produce. ⛔ **If they PAY, the mechanism is wrong in the isotope and (B) is refuted.**
  ⚠ **Untestable under §3b option 3.**
- **P5 (no free lunch).** `co2_seasonal_SPO` / `co2_seasonal_MLO` move by **less** than the fitted
  21.2 compensator would predict — the mechanism is *smaller* than the thing it replaces.
- **P6 (SH honesty).** The likelihood loses **no more than the compensator's own worth** at the SH
  seasonal rows. Retiring a fitted parameter *must* cost something; the round is judged on whether
  the NH gain (P2) exceeds it.
- **P7 ⭐ NOT A DEEP LEVER IN DISGUISE.** The **modern** surface−deep δ¹³C gradient (**0.40** at
  `hilda31`) does not move by more than the `ocean_grad_d13c` row's σ_eff (**0.16**). Entrainment is
  a surface-cycle mechanism; if it moves the deep gradient it is doing something else.
  ⚠ Modern, like-for-like — **never** the PI number ([[ccx_cheap_probes_20260908h]]'s retraction).

**Reported, never scored:** IRF(100), and the land share of a pulse. Both are **comparisons** by the
09-04e ruling. ⛔ **No Joos row anywhere in this prereg.**

---

## 5. Build order

1. **Ruling on §3a and §3b.** Nothing is built before it.
2. Both cores, one expression each (`R/model.R`, `src/ccx_core.cpp`) + the §3b isotopic path.
   `ent_seas_amp_SH` retired from `CCX_PARAM_TABLE`; the migration path must land pre-30 ancestors
   correctly ([[runnable_is_not_encodable]] — a lognormal prior on a retired name is prior-zero).
3. **Tests before the probe:** R/C++ parity; a **mutation test at an explicit non-zero amplitude**;
   a conservation assertion for the §3b override; `test-mode-struct-lint` still green.
4. **Probe unrefitted at `hilda31`:** P1, P3, P5, P7, gate S. Stop here if P1 fails.
5. **Refit on Torch.** ⭐ **Say the verdict out loud** ([[consider_torch_first]]): a **30-parameter
   multistart is a Torch array, not a laptop job** — 24 starts, one wave, ~2.5 h on the 09-08e
   recipe. Port targets committed at the launch commit; preflight 8/8;
   ⛔ **NEVER re-ship the bundle mid-array** ([[never_reship_mid_array]]).
6. Score against P1–P7. **Adoption is Marcus's call.** Then the whole-model scorecard arm, then B's
   design note.

## 6. What this round does NOT touch
The ENSO ocean sign (**the blocker** — that is option B, the tropical box, weeks), the ventilation
limb (E), Martin remineralisation (D, needs E first), `alk_hs` (closed: not a lever), and the three
open σ-audit items — of which **`gcb_ocean_sink`'s uninflated 0.4 GtC/yr is an objective change and
needs its own ruling**, separately from this one.
