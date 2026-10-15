# Handoff — CarbonCycleEmulator, 2026-08-15d: the DIC diagnostic is done, item 9's three clauses all PASS, and the uptake argument for the pump is dead

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`, still
**not merged**. Suite **4 failing**, unchanged, none flagged for Marcus.

**Supersedes `handoff_2026-08-15c_sigma_co2_and_h_ml.md`** for §3.3's mechanism claim and for
§5's candidate set. Everything else in 15c still stands — in particular the `sigma_co2`
retirement (19 parameters), the two opposite absence conventions in `err`, and the "still do
NOT" list.

---

## 0. START HERE

1. **`calibration/diag_dic_gradient.R` is done and it settles the fork's factual half.**
   All three of item 9's amended clauses **PASS at the mode**, at **zero fitted parameters**,
   for **−13.7 log-units** with nothing refitted. §2.
2. **But it passes them for a different reason than 15c §3.3 gave, and that reason is
   measured-wrong.** A constant-mass pump adds **exactly zero** uptake — +0.000000 GtC/yr,
   pre-registered and confirmed. **The pump is not an export mechanism in this model.** §2.1.
3. **Two of my own predictions failed and are recorded in the diagnostic's header, not
   dropped.** If you find yourself re-deriving "the pump lowers surface DIC hence the Revelle
   factor" or "the pump makes deep Δ¹⁴C *less* depleted", read §3 first — both are measured
   false, and the second one flips the sign of clause 3 between operating points.
4. **The candidate list is no longer just {pump, conveyor}.** Marcus added **depth-dependent
   `K_z`** and the **high-latitude outcrop** on 2026-08-15. They live in **DESIGN.md §3.4a**
   with the five observables that discriminate all four candidates. §4.
5. **The fork is still open and is still Marcus'.** It has moved, though: it is no longer
   "pump vs refit" but "which ocean structure, and at what export". §5.

---

## 1. What was done

| | |
|---|---|
| new | `calibration/diag_dic_gradient.R`, output `calibration/output/dic_gradient/` (+ `run.log`) |
| new | **DESIGN.md §3.4a** — the four ocean structural candidates and their discriminating rows |
| edited | DESIGN.md §10 — points at §3.4a instead of carrying the ocean options itself |
| **not** touched | **any model file.** The pump is a shim over `ccx_deriv()` inside the diagnostic |

**Zero fitted parameters.** The export field is *solved* as the source that makes GLODAPv2's own
observed DIC profile an exact steady state of the model's own diffusion operator. No Martin
curve is chosen, no magnitude is fitted. The single structural choice — the ¹³C fractionation on
export — is run **both ways** rather than resolved.

---

## 2. The result

At the pre-gradient MAP mode's other parameters, **each arm at its own best depth**:

| | pump OFF | pump ON |
|---|---|---|
| `h_ml` | 184 m | **100 m** |
| logL | −2269.7 | −2283.4 |
| ocean sink | 3.063 | 3.052 GtC/yr |
| deep Δ¹⁴C | −157.8 (z **+1.70**) | −164.2 (z **+1.08**) |
| deep DIC | 1996 | 2241 µmol/kg (obs 2274) |
| deep δ¹³C | +1.560 (z **+14.1**) | −0.628 (z **−12.6**) (obs +0.406) |

- **CLAUSE 1 PASS** — `h_ml` relaxes 184 → 100 m.
- **CLAUSE 2 PASS** — 3.052 against 3.063: **the same sink at a physical mixed-layer depth**.
- **CLAUSE 3 PASS** — deep Δ¹⁴C moves *toward* the target, z +1.70 → +1.08.
- **Cost −13.7 log-units, nothing refitted.** The biggest loss channel is atmospheric Δ¹⁴C
  (−30/−31 NH/SH) and **`bomb_total`, the free parameter that absorbs exactly that, is held
  fixed.** Do not read −13.7 as "the pump is worse"; read it as "the pump is a wash before
  refitting".

### 2.1 THE MECHANISM IS NOT THE ONE 15c §3.3 NAMED

Pre-registered before part 3 ran: the interior is a passive tracer with no chemistry and
diffusion is linear in concentration, so a static background DIC profile superposes on the
anthropogenic perturbation and cannot change how it propagates — **therefore a nutrient-limited
(constant-mass) pump must move the ocean sink by exactly zero.**

**Measured +0.000000 GtC/yr.** A DIC-limited export moves it by **+0.130 GtC/yr** at 22.0 GtC/yr
of export. So:

> **The pump does not supply the export deficit. It changes which `h_ml` the objective wants, by
> changing the background state and the isotopes.** 15c §3.3's sentence — "adding uptake WITHOUT
> mixing surface water down" — is wrong as a description of what happens here.

That the clauses pass anyway is the interesting part, and it means clause 2 was never really
testing export.

### 2.2 AT DEFAULTS, CLAUSE 3 FAILS INSTEAD — and this is not a contradiction

z −1.08 → **−1.52**, i.e. away. At `ccx_default_params()` `kz` is low and the model is already
*over*-depleted, so more depletion is a loss. At the mode `kz` is 96.6 % up its bracket and the
model is *under*-depleted, which is the miss under discussion. **Both are printed. Do not average
them, and do not quote the defaults number as the answer to 15c §3.4.**

---

## 3. Two of my predictions were measured and FAILED

Both are in the diagnostic's header so they cannot be re-derived by accident.

1. **The Revelle/capacity channel does not exist.** Model ML DIC is 1986.3 µmol/kg; GLODAPv2's
   0–75 m volume-weighted mean is 2028.9 **modern**, ≈1979 preindustrial. The model's surface is
   right to ~7 µmol/kg and **the whole 244.7 µmol/kg deficit is interior.** So there is no
   surface-buffer channel connecting the pump to uptake, and the arms do not include one.
2. **The pump makes deep Δ¹⁴C MORE depleted, not less.** The pumped carbon is delivered young
   (−51 ‰) but exits only by the same slow diffusive return, so deep inventory rises ~12 % while
   the ventilation flux rises much less, mean age goes up, and **decay beats the injection
   value**. The residence-time channel dominates. This is what flips clause 3's sign between
   operating points.

---

## 4. The candidate list, and why it grew (Marcus 2026-08-15)

**DESIGN.md §3.4a is now the canonical list.** Four candidates, scored on the same five rows —
the three item-9 clauses plus the preindustrial **DIC** and **δ¹³C** gradients, which are the two
rows **only the pump can move** and which **the likelihood does not currently score at all.**
That asymmetry is itself worth noticing: the candidate with the most distinctive signature is the
one the objective is blind to.

- **A. Depth-dependent `K_z`** — **one parameter, no new state, no new fluxes, no isotope
  decisions**, and the per-interface diffusion loop already takes a coefficient vector. This is
  the literature's answer to exactly the tension 15c §3.3 measured: a *constant* K cannot
  reproduce natural Δ¹⁴C (10²–10³ yr) and bomb Δ¹⁴C (decadal) at once, and the fix is a K that
  **decreases with depth** (Siegenthaler & Joos 1992, *Tellus B* 44:186; Siegenthaler 1983, *JGR*
  88:3599). It is also the degree of freedom `h_ml` = 184 m is counterfeiting. **Passes the §2
  pedagogy constraint in one sentence.**
- **B1. Outcrop, within-column — ALREADY BUILT AND OFF.** `w_out_NH` / `w_out_SH` exist in
  `ccx_default_params()`, default 0, bit-reproduce the pure-diffusion model. **Freeing them is a
  parameter decision, not a structural one, and an SH-only value is a testable claim about the
  MLO−SPO gradient the likelihood already scores.** This is the cheapest untried thing in the
  repo. **B2** (HILDA's separate high-latitude column) stays out of v1 on the **pedagogy**
  constraint from §2 — which is a live decision, not a physics verdict.
- **C. Pump** — this file. **D. Conveyor** — still NO, listed only so it is not re-proposed.

**A and C are complements, not alternatives** — see §5's first scoping fact.

---

## 5. Two scoping facts any pump design must answer

1. **The implied export is 22.0 GtC/yr, 2.6× the literature 5–12 GtC/yr.** It is set by how fast
   the model's diffusion *destroys* the gradient, i.e. by `kz` — and `kz` = 5000 is **9× Ledwell's
   NATRE 536 m²/yr**. An effective diffusivity tuned to emulate 3-D advective *transport* also
   spuriously destroys *gradients*. **This is the NATRE ratio seen a second way, and it is the
   argument that A should come before or with C, not after it.**
2. **A soft-tissue-only pump cannot fit both observed gradients, and that is arithmetic.**
   244.7 µmol/kg of organic carbon at ε = −20 ‰ predicts −2.153 ‰ against an observed −0.938 ‰:
   **2.3× overshoot predicted, 2.3× measured.** No single ε removes it. Implied split ≈**45 %
   soft-tissue / 55 % carbonate** (order only — it also absorbs preformed-δ¹³C and air-sea
   disequilibrium). **The carbonate limb moves alkalinity, which the model holds fixed at
   `ALK_SURFACE`** — a second structural commitment behind the first.

---

## 6. Non-obvious state

- **The C++ core does not know about the pump.** Every run in the diagnostic goes through the R
  reference integrator `ccx_run()`; that is the whole ~15 min. Porting to `src/ccx_core.cpp` is a
  **shipping** decision this file deliberately does not pre-empt.
- **`dg_spinup()` is a near-verbatim copy of `ccx_spinup()`** with the full-state Newton solve
  made unconditional (it is otherwise gated on the conveyor, and a uniform column stops being a
  fixed point once the pump is on). **It is gated:** parity against `ccx_spinup()` at pump-off is
  6.5e-07 GtC over 96 states, and it `stop()`s above 1e-6. If you change `ccx_spinup()`, this
  copy will fail loudly rather than drift.
- **The observed profile has a slight mid-depth maximum** (1314–1861 m sits ~3 µmol/kg above the
  bottom), so two boxes per hemisphere need a **negative** source — not remineralization.
  Reported with magnitudes (min S ≈ −0.14 GtC/yr), **not smoothed away**.
- **The free validations are NOT in the objective:** ocean inventory 32,827 → 36,467 GtC
  (canonical ~38,000) and natural ¹⁴C production 0.672 → 0.736 of canonical. Both improve. **Do
  not quote them as if the likelihood had rewarded them.**
- Everything in 15c §4 that is not superseded still stands: 19 parameters; `mode_fit.rds` still
  EMPTY; the two **opposite** absence conventions in `err`; `FORC_FOSS_NH_SHARE` has no switch;
  `luc-veg-debit` never merged.

---

## 7. The ordering, amended

| # | task | status |
|---|---|---|
| ~~1–5c, 6b, 7~~ | objective, β, `luc_scale`, GLODAPv2, gradient, shares, seasonality, MM fertilization, `sigma_co2` | **DONE** |
| **6** | `LIK_EXCESS_C14_TARGET` | **NOT a blocker** |
| **8** | **THE REFIT**, 19 parameters, ~5.4 h | structurally unblocked; held only by the fork |
| **9** | **the pump** | **all three clauses PASS** — but on the background-state channel, not export. §2 |
| **10** | **depth-dependent `K_z`** | **NEW.** 1 parameter. Untried. §4 A |
| **11** | **outcrop `w_out_NH`/`w_out_SH`** | **NEW — ALREADY BUILT, defaulting to 0.** Untried. §4 B1 |

**THE FORK, restated.** It is no longer "pump vs refit". Items 10 and 11 are both cheaper than 9
and neither has been scored on the five rows. The honest ordering question for Marcus:

> Run **10 and 11** through the same five-row comparison first (a day, no structural commitment,
> and 11 needs no new code at all), then decide 9 knowing whether the 2.6× export excess shrinks
> once the column ventilates properly? Or take 9 now on its three passing clauses and accept
> building the pump at 2.6× export inside a 9×-NATRE column?

**Marcus deferred the last fork deliberately to decide cold. Ask; do not pick.**

**Still do NOT:** anything on 15c §5's list, unchanged — hand-tune stream weights; delete
`excess_c14_ocean` or `d14c_intcal`; free any land turnover parameter; delete the `kz` bracket;
build the conveyor; splice any pre-2026-08-15 posterior; quote a log-likelihood from a diagnostic
not given the gradient offsets; lower `LIK_CO2_REP_ERR` as housekeeping. **Add:** do not quote
the defaults-parameter clause-3 verdict as the answer (§2.2), and do not quote the free
validations as scored (§6).

---

## 8. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-15d_dic_gradient_and_candidate_list.md`. The DIC-gradient
> diagnostic is done: **all three of item 9's clauses PASS at the mode for −13.7 log-units with
> nothing refitted — but a constant-mass pump adds EXACTLY ZERO uptake, so the pump works through
> the background state, not export.** The candidate list grew to four (DESIGN.md §3.4a);
> **depth-dependent `K_z` and the outcrop `w_out_*` are both cheaper than the pump and neither
> has been scored.** Open on §7's fork. Suite 4 failing, none flagged.
