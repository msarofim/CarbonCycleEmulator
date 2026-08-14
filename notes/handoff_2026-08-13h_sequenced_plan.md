# Handoff — CarbonCycleEmulator, 2026-08-13 (h)

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`
at **`54e42a6`** (still **not merged**). Suite **505 pass / 2 fail / 2 skip**.

**This is a SEQUENCED WORK PLAN**, written on Marcus' instruction: cheap fixes first, then
the refit, then the biological pump. It supersedes **13g §6**'s unordered "what to do next"
and answers the question 13g left open ("would the pump and a refit be a good next step?").
**Short answer: refit yes, pump not yet, and not together.** 13g §§1–5 stand as the record
of what was built; 13f is the diagnosis; 13e §§0.1–0.3 and 13c §5 still hold what is Marcus'.

---

## 0. START HERE

1. **The model changed structurally today and has NEVER been refitted in its current
   form.** The converted-land term (`404d66d`) made the land-use debit permanent. Every
   parameter in `mode_fit.rds` was fitted to the model that preceded it.
2. **The q10 inversion was the land-use bug, not δ¹³C** (`54e42a6`). On the buggy model a
   (β, q10) slice puts the optimum at the grid corner **(0.10, 0.20)**, reproducing
   `mode_fit.rds`'s **(0.088, 0.169)**; on the fixed model it is **(0.50, 1.50)** — both
   defensible. **That is a prediction, and PHASE 2 is the experiment that tests it.**
3. **The obvious hope failed and is recorded so it is not re-formed.** The converted-land
   term does **not** relieve the δ¹³C misfit: the β gap between the δ¹³C and CO₂ crossings
   is **0.57 (bug) → 0.59 (fixed)**. `diag_d13c_suess` §3's structural verdict **survives**.
4. **DO NOT do the pump and the refit together.** It confounds the one clean experiment
   available, and the pump cannot be evaluated at all without a no-pump posterior to
   compare parameter *vectors* against (13c §5's own design rule).
5. **The MCMC has still never been run.** There is no `posterior_draws.rds`. A mode-find is
   not a posterior, and DESIGN §5.4 wants uncertainty. See PHASE 2b.

---

## 1. The sequence, and what each step costs and buys

| | step | cost | what it buys | what skipping it costs |
|---|---|---|---|---|
| **1** | Cheap fixes (§2) | ~1 day, no long runs | a refit that is valid and interpretable | a 4 h refit that a later decision voids |
| **2** | Refit, conveyor OFF (§3) | ~4 h | tests §0.2's prediction; the baseline vector everything later compares to | the pump has nothing to be judged against |
| **2b** | First production MCMC (§3.4) | days | the repo's largest gap vs DESIGN §5.4 | the app can show no uncertainty at all |
| **3** | Biological pump (§4) | +2 params, spinup rework, then another refit | two obs gradients currently *exactly zero*; a ventilation constraint independent of the deep-Δ¹⁴C target | — |

**The ordering rule underneath it:** each step's result must be attributable. The model just
moved; measure it where it stands before moving it again.

---

## 2. PHASE 1 — the cheap fixes

Split by whether they **block** the refit. Everything here is minutes-to-hours, against the
refit's 4 h.

### 2.1 BLOCKING — settle these or the refit is void

**(a) Delete `kz`'s `[3830, 6200]` bracket.** *12d §6 already decided this* — "do not carry
it across", because the bracket is conditional on the pure-diffusion column it was bisected
on. **It is still live in `CCX_PARAM_TABLE`** (verified today). One-line change, but it
changes what the refit is allowed to explore, so it cannot be done afterwards. Honest
accounting if the conveyor is ever turned on: one parameter added, one constraint removed.

**(b) The pro-rata debit — MEASURE, then decide.** The shipped fix delivers ~**0.5×** the
fossil airborne fraction at 100 yr, not 1×, because the debit lands on wood (37 yr) while
the equilibrium reduction is pro rata with 70 % of it in a 500-yr soil pool. *Confirmed by
test, not argument:* at `tau_soil_slow = 20` the ratio is **1.02**. Debiting the pools pro
rata would close it — and trades against the 2026-08-12 call that the emitted carbon
carries **wood's** lagged ¹⁴C.
**This changes the model materially, so decide it BEFORE the refit.** The measurement is
cheap (a variant `add_flux` split plus a re-run of `test-luc-permanence.R`'s pulse pair) and
should be produced so the call is made on numbers: the two things to report are the LUC
airborne fraction at 100 yr and the ¹⁴C consequence the pro-rata debit would incur.

**(c) `sigma_d13c` — and today's measurement reframes the question.** The standing debate
has been whether 0.45 ‰ is a defensible error bar. **Measured (`diag_which_stream_pays.R`):
at the mode's own 0.44 ‰ the δ¹³C stream contributes ~3 log-units of discrimination across
the entire q10 range, against CO₂'s 3200, and it pays 2.8 log-units to move to β 0.5 /
q10 2.0 where CO₂ pays 39.9.** So at that width δ¹³C is **very nearly inert** for the land
parameters. The question is therefore not "is 0.45 ‰ defensible" but **"do you want δ¹³C in
the likelihood at all at that width?"** — a σ chosen to absorb a structural misfit has
absorbed the constraint with it. Marcus'.

### 2.2 NON-BLOCKING but cheap, and now clearly warranted

**(d) Re-measure the δ¹³C and ocean diagnostics on the fixed model** —
`diag_d13c_suess.R`, `diag_oceanic_suess.R`, `diag_conveyor.R`, ~1 min each. Every δ¹³C
number dated 2026-08-13 was measured **after** `98c1783` and therefore on a model with part
of its Suess forcing switched off. The fix moves the 1900→2020 Suess decline
**−2.209 → −2.366 ‰, 7.1 % faster**, on a model already ~25 % too fast. **The three ocean
decisions must not be settled on the old numbers**, and this is what makes (c) and PHASE 3
decidable.

**(e) Re-centre the default `beta`.** At 0.38 the model now runs **+17.5 ppm high at 2024**
— that default was re-centred on 2026-08-12 *against the bug*. The CO₂ record's 1-D
preferred value is **0.50**. This is an app and test fixture, not a calibrated value, and
DESIGN's app panels should not be built on it as it stands.

**(f) Re-derive the two remaining suite failures rather than inheriting them.**
`test-climate.R:122` (0.092 against a 0.1 threshold) and `test-mechanisms.R:32` (0.29
against 0.5). **The precedent is today's:** two of the four "pre-existing, unrelated"
failures turned out to be the suite correctly reporting a real bias, mislabelled a stale
AR(1) fixture across five handoffs. Carry the *evidence*, not the label.

**(g) Merge or tag `luc-veg-debit` before spending 4 h against it.** It has been unmerged
since 2026-08-12 and now carries a model-structure change, two diagnoses and a DESIGN
amendment.

---

## 3. PHASE 2 — the refit

### 3.1 The prediction, stated in advance so it cannot be retrofitted

On the fixed model, with the conveyor off:

| parameter | `mode_fit.rds` (fitted to the bug) | predicted |
|---|---|---|
| `beta` | 0.088 | **rises to ~0.5** |
| `q10` | 0.169 | **rises to ~1.5–2**, i.e. the sign of the soil response inverts back |
| `h_ml` | 178.5 (88 % up its bound) | falls — *untested, carried from 13c §5* |
| `tau_ex` | 0.856 | rises — *untested, carried from 13c §5* |

**If β and q10 do not move, §0.2's attribution is wrong** and the low values are being set
by something other than the land-use defect. That is the falsification condition.

### 3.2 Design

- **Conveyor OFF (`q_conv = 0`).** This matters and it *unblocks* one of the three standing
  decisions: the `[−150, −200]` deep-Δ¹⁴C bracket was derived on a **single-column** ocean,
  which is exactly what `q_conv = 0` gives. **13c §0.2's "do not refit until the deep-Δ¹⁴C
  target is chosen" binds a conveyor-ON refit, not this one.**
- **`f_luc_perm` stays fixed at 1** and out of `CCX_PARAM_TABLE`. It is the mass-consistent
  point, and adding a free parameter to the experiment that tests the fix would blunt it.
- **Window 1750–2024**, which `ccx_make_logpost()` already uses — verified today, so the
  new mid-record start-up-transient warning does **not** fire and the refit is clean.
- **Compare parameter VECTORS, not just log-posterior** (13c §5). A better fit bought by
  driving `k_w` or `h_ml` somewhere indefensible is not a better model.

### 3.3 What would void it

The pro-rata decision (2.1b), the `sigma_d13c` decision (2.1c), or the `kz` bracket (2.1a)
landing *after* the run. That is the entire reason PHASE 1 exists.

### 3.4 PHASE 2b — the first production MCMC

**Only after the mode-find lands somewhere defensible.** This is the largest single gap
between the repo and DESIGN §5.4 (13e §0.5) and it is what stands between the app and
showing any uncertainty at all. `ESS`/`maxlag` and BLAS-thread pinning conventions are in
memory; a mode-find is not a posterior and the app cannot ship on one.

---

## 4. PHASE 3 — the biological pump

### 4.1 Why it is third and not first

- **It would confound PHASE 2.** The model has never been refitted in its current form;
  changing it again before that happens makes no subsequent result attributable.
- **It cannot be judged without PHASE 2's output.** 13c §5's rule is to compare parameter
  vectors; the no-pump vector does not exist yet.
- **Spinup risk, with a precedent that cost a week.** The pump changes the preindustrial
  steady state. 13c §2a: the conveyor's "`ccx_spinup()` needed no change at all" claim was
  **false and silent** — −0.915 ‰ of spurious δ¹³C drift, nearly twice the misfit the
  conveyor was proposed to fix, and 13c's own words are that *it would have looked like a
  result*. Assume the pump needs a spinup solve and budget for it.
- **+2 parameters** (export production, remineralisation depth scale) on a model the expert
  panel has just concluded is at the right complexity.

### 4.2 Why it is nonetheless the right third step

- **It improves two measured mismatches that are currently EXACTLY ZERO**, and therefore
  cost nothing to improve: the ocean's vertical **DIC** gradient (observed ~300 µmol/kg;
  model 1986.3 µmol/kg uniform through 3700 m) and its vertical **δ¹³C** gradient (observed
  ~1–1.5 ‰; model +1.560 ‰ uniform). The ~14 % ocean inventory deficit and the missing DIC
  gradient are **the same number** — 13e §6's arithmetic, and it is solid.
- **It supplies a ventilation constraint that does NOT require the deep-Δ¹⁴C target to be
  settled first**, because a pump's gradient is set by **export ÷ ventilation**. That is a
  route *around* one of the three blocking decisions rather than through it.
- **PHASE 2's residual points at the ocean.** At the (β, q10) slice optimum the model's
  2015–2024 **land sink is 3.41 GtC/yr against GCB's 2.36** and its **ocean sink 2.99
  against 3.22** — land too strong, ocean too weak, and the ocean is the reservoir with the
  known structural deficiency (`kz` 9× Ledwell's NATRE 536 m²/yr).
- **It passes the pedagogy test the conveyor failed.** "Plankton grow at the surface, die,
  and sink, which is why the deep ocean is rich in carbon and the surface is poor" is one
  sentence, is famous, and explains the 50× ocean:atmosphere stock ratio the app already
  displays.

### 4.3 What must be stated in advance, so it cannot be retrofitted

- **The pump's effect on the ATMOSPHERIC δ¹³C misfit is SIGN-UNKNOWN.** 13e §7 said so and
  nothing since has changed it. **Do not adopt it expecting the δ¹³C misfit to close** — the
  case for it is the two interior gradients and the ventilation constraint, not δ¹³C.
- **It works AGAINST the deep-age constraint**, injecting surface-¹⁴C carbon into the deep
  non-locally and making it *younger*. Magnitude unmeasured. Measure it before, not after.
- **It cannot change surface DIC, the Revelle factor, or the IRF to first order** (13e §6):
  the interior carries no carbonate chemistry, and in steady state the mixed layer's DIC is
  chemistry-pinned. **A pump alone is mostly bookkeeping; a pump plus a return path is a
  mechanism.** Decide up front whether it ships with the conveyor.
- **GLODAPv2 is the source to pull.** The deep DIC/δ¹³C values quoted in 13e are
  recollection; the 2299 µmol/kg volume-weighted figure is the model's own arithmetic and
  is solid, the observed ones are not yet sourced.

---

## 5. Decisions that remain Marcus'

| | decision | now informed by |
|---|---|---|
| 1 | `sigma_d13c` | §2.1c — measured to be **nearly inert** at 0.44 ‰ |
| 2 | the deep-Δ¹⁴C target for a bipolar ocean | **not binding on a conveyor-OFF refit** (§3.2) |
| 3 | whether Quay's ml Suess rate / the SHCal ¹⁴C offset become likelihood terms | re-measure first (§2.2d) |
| 4 | **pro-rata vs wood-only LUC debit** | §2.1b — blocking, measure then decide |
| 5 | **whether the pump ships with a return path** | §4.3 |

---

## 6. Non-obvious state

- **A window starting mid-record no longer begins at a fixed point** and `ccx_build_forcing()`
  warns. The **48 warnings in a suite run are all real.** Comparison runs where both arms
  share the transient are unaffected; absolute numbers are not.
- **A forcing with LUC emissions and no `cum_luc` is an ERROR**, not a zero-default.
- **`CCX_LUC_CLEARED_MAX` (R) and `LUC_CLEARED_MAX` (C++) are duplicated and NOTHING catches
  a disagreement.** If one moves the other must move in the same commit.
- **`ccx_spinup()` is untouched; every pre-2026-08-13 spinup result is bit-identical.**
- **A zero-emission run is not flat unless GMST and ENSO are frozen** (+8.34 ppm / 275 yr).
- `mode_fit.rds` is stale in four ways and its `par_mode` carries **only the 16 calibrated
  names** — it is not a usable parameter list on its own (`ccx_spinup()` dies in the
  carbonate solve on the missing `sst_NH`); overlay it on `ccx_default_params()`.
- Everything in 12d §§2–8 and §10 still applies.

## 7. Commits (2026-08-13, this thread of work)

| | |
|---|---|
| `6733f9c` | The 1900 deficit diagnosed: land-use carbon has an airborne fraction of zero |
| `404d66d` | The converted-land term: the land-use debit is made permanent |
| `e51b02f` | Handoff 13g: the converted-land term shipped, and what it costs |
| `54e42a6` | Two diagnostics for "is there a path forward": the q10 inversion was the bug |

## 8. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-13h_sequenced_plan.md` and work it in order: **PHASE 1 cheap
> fixes, then the conveyor-OFF refit, then the biological pump.** Branch `luc-veg-debit`,
> unmerged. **Do not start the refit until the `kz` bracket is deleted, the pro-rata LUC
> debit is decided, and `sigma_d13c` is settled** — those three void it retroactively.
> **Do not build the pump before the refit**: it confounds the one clean experiment
> available and cannot be judged without a no-pump parameter vector. The refit is a
> pre-registered test — β should rise from 0.088 to ~0.5 and q10 from 0.169 to ~1.5; if they
> do not move, the attribution in §0.2 is wrong.
