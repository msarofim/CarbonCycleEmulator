# Handoff — CarbonCycleEmulator, 2026-08-16f: THE PUMP SHIPPED (wiring committed, all 7 tests re-derived), `kz` re-bisected — and the two-arm refit is BUILT but NOT LAUNCHED, blocked on `h_ml`

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`,
**89 commits ahead of `main` and still not merged**. **HEAD = `c78cf8e`. The working tree is
CLEAN** — unlike 16d, there is nothing held back.

**Supersedes `handoff_2026-08-16d_pump_ships_on.md` entirely for its §4, §5 and §7 items 1–3
(all now done).** Its §2 decision stands; its §3 measurements stand; its §8 cautions all still
hold except the two that are now discharged (§9 below).

**Commits this session:** `a39aab0` (the 7 tests + the wiring) → `af3531f` (refit prep) →
`96d647f` (`kz` re-bisected, driver built, not launched) → `c78cf8e` (smoke-test evidence).

---

## 0. START HERE

1. **THE NEXT SESSION'S JOB IS TWO DECISIONS, AND NOTHING ELSE UNTIL THEY LAND** (Marcus
   2026-08-16f): **(a) the `h_ml` question** — §5, this is the hard one — and **(b) N or D**,
   which §6 says cannot honestly be answered until (a) is, because both arms currently land
   in the regime where the pump's own constraint is switched off.
2. **THE PUMP IS COMMITTED AND THE SUITE IS BACK TO BASELINE.** 4 failing / **857 passing**,
   against 4 / 802 at 16d's HEAD. All 7 blocking tests re-derived, **none re-expressed to make
   a model change pass**; five now assert *more* than before. §3.
3. **MY HYPOTHESIS IN 16d §5 WAS WRONG.** The advection failure is not hemispheric asymmetry —
   that is *inapplicable*, `w_up` is one global parameter. It is that **the pump is the model's
   first INTERIOR source**, and the transpose symmetry only ever protected mixed-layer sources.
   **CO₂ still ties exactly; only the ISOTOPES break.** §3.1.
4. **TWO TESTS CAUGHT REAL DEFECTS ON THEIR FIRST RUN** — the drift-guard constant (233.109 vs
   a target of 233.109378176267) and, in the other direction, a parity tolerance that was an
   operation count in disguise. §3.2. **This is the argument for re-deriving rather than
   re-baselining, and it is worth carrying to the next stale gate.**
5. **`kz`'s bracket was re-bisected on Marcus's decision: [3830, 6200] → [3942.5, 6528].** The
   pump-OFF control reproduces the shipped bracket to 1.3 m²/yr, so the recipe is faithful. §4.
6. **THE REFIT IS WRITTEN, GATED, SMOKE-TESTED AND DELIBERATELY NOT LAUNCHED.** §5 is why. A
   run launched as-is would have burned ~11 h to compare N against D in a regime where the
   pump is held by its prior. **Do not launch it before settling `h_ml`.**
7. **THE MODEL HAS STILL NEVER BEEN CALIBRATED.** `calibration/output/mode_fit.rds` does not
   exist; there is no MCMC, pilot, chain or posterior output anywhere. §8.

---

## 1. What was asked and what was done

16d left seven tests blocking the pump wiring. This session re-derived all seven, committed the
wiring, then — on Marcus's "run both arms and compare" — built the two-arm refit, re-bisected
`kz` for it on his decision, smoke-tested the driver, and **stopped**, because the smoke test
found a blocker worth more than the compute it would have cost.

---

## 2. THE DECISIONS TAKEN THIS SESSION (Marcus)

| question | decision |
|---|---|
| N vs D export law | **Fit BOTH arms and compare.** Not resolved by fiat. |
| `kz` bracket, stale on a no-pump model | **Re-bisect** → [3942.5, 6528]. §4. |
| `h_ml` band / gradient-row switch | **OPEN — this is the next session's first job.** §5. |

---

## 3. THE SEVEN TESTS — all re-derived, suite 4/857

**No test was re-expressed to make a model change pass.** DESIGN §5.2i has the full account.

### 3.1 `test-ocean-advection.R` — the one that needed real work, and my 16d hypothesis was wrong

16d §5 offered "the export field is solved per hemisphere, so reversing which hemisphere sinks
is no longer a symmetry", flagged in terms as a hypothesis. **It is inapplicable, killed on
inspection before a single run was spent on it:** `w_up` is one **global** parameter and the
test sets `w_out_NH = w_out_SH`, so **no hemisphere is ever swapped**. Both hemispheres break in
the *same* direction, at the ratio of their ocean areas (1.24 measured vs 1.33), which a swap
cannot produce.

**What is actually happening** (`calibration/diag_pump_advection_symmetry.R`, ~1 min, five
pre-registered predictions, all confirmed). `e^{A_out t} = D (e^{A_up t})ᵀ D⁻¹`, so propagator
element (i,j) maps to (j,i). The mixed layer is box 1:

- **(1,1) is preserved BIT-EXACTLY** — |gap| = **0.000e+00** at both 10 and 60 yr.
- **Interior→ML elements (1,k) differ by O(1)** — 0.402 at 10 yr, 0.220 at 60 yr.

**The atmosphere's invariance was always conditional on the ocean having no interior source —
the test said so in its own words — and the pump is the model's first one.** Premise falsified,
theorem intact.

| quantity | gap | reading |
|---|---|---|
| CO₂, `ml_C`, `land_C` | ≤ 1.8e-12 | **TIED EXACTLY**, at every `pump_grad` 0→466.2 |
| `ocean_C` | 1351.8 GtC, flat to 7.3e-11 | preindustrial-inventory **OFFSET**, not a transient |
| δ¹³C | 1.7e-3 ‰ | BROKEN — **0.4 % of the 0.44 ‰ σ** |
| Δ¹⁴C / `atm_C14` | 4.7e-2 ‰ | BROKEN |

At `pump_grad` = 0 everything ties to 4.1e-12.

**Why 12C survives, with its own mutation test.** Mode "N" fixes the export **MASS** (`sc = 1`),
so 12C's interior source is a **constant field** — it cancels from the linear anomaly equation
and lands entirely in the steady state (= `ocean_C`'s flat offset). Mode N does **not** fix the
export's **ISOTOPIC RATIO**, which tracks the mixed layer's own and rides the Suess effect.
**Mode "D" makes 12C state-dependent too and CO₂ moves 5.3e-2 ppm — 6e10× mode N.** So it is
**state-DEPENDENCE** of an interior source that reaches the atmosphere, not its mere presence.

### 3.2 The two that caught real defects

- **`PUMP_GRAD_OBS` ↔ `ocean_grad_dic`.** The consistency test 16d §4 promised was written and
  **failed on its first run**: the constant was hand-typed **233.109** against a shipped target
  of **233.109378176267**. 1.6e-6 relative — physically nothing, and *exactly* the drift it
  exists to prevent. Both the constant and `CCX_PARAM_TABLE$pump_grad$init` now carry the
  target's digits. **`init` must REPEAT rather than read the constant** — `R/calibrate.R` sorts
  before `R/constants.R`, so `ccx_const()` does not exist when the table is built. The test is
  what makes the repetition safe.
- **`test-parity.R` — never a parity break, and the tolerance is DERIVED, not re-baselined.**
  The pump emits into `nl` = 10 interior boxes on both limbs = **20 extra terms** accumulating
  into the mixed layer, carrying **18.83 GtC/yr**. Reassociation bound = 20 × ε × 18.83 =
  **8.36e-14**; **measured 8.53e-14 — 1.02× the bound.** Tolerance set at 4× the derived bound,
  with a **pump-OFF arm retained at the original 1e-15** (measured 5.1e-18) so a real break
  cannot hide in the pump's roundoff budget.

### 3.3 The other four, briefly

- **The tripwire fired as designed** ("either a pump has landed (expected) or something is
  leaking carbon (not)") at exactly `pump_grad`. Split into two arms: OFF keeps the original
  zero-uniformity claim unweakened; ON asserts the interior gradient **equals `pump_grad` to
  1e-13 for every parameter perturbed**, `kz` and `h_ml` included. Parameter-independence is the
  non-trivial part, and a leak would break it while leaving a "gradient is nonzero" test happy.
- **The leverage test's GUARD failed, not its bound.** The pump closed the miss **11.02 σ →
  1.79 σ**, so `expect_gt(miss, 5)` fired while every leverage stayed inside `LEV_MAX`.
  Restated as the ratio it always meant (≤ 0.049 measured against a 0.10 gate). **The pump does
  not touch the leverage at all** — identical to three digits on and off (`kz` 0.026,
  `beta_max` 0.088, `k_w` 0.013 σ). It moves the *level*, not the grip. Now gated.
- **`test-pump.R`** tested the *default* under a title about *bit-reproduction*. Split, and the
  reproduction claim strengthened to run against a parameter list carrying no `pump_grad` at all.
- **Parameter count** 19 → 20, with the `init`-equals-`PUMP_GRAD_OBS` tie asserted.

**NOT DONE, deliberately:** `test-parity.R`'s frozen-Revelle arm still carries a bare `1e-15`
and **passes** with the pump on. Left alone rather than swept into `PARITY_REL_TOL` — a passing
gate is not something to loosen on tidiness grounds. It is the one place §3.2's derivation is
not applied, and it will fire if a future mechanism raises the flux count through that branch.

---

## 4. `kz` RE-BISECTED (Marcus's decision, on the numbers)

`calibration/diag_kz_bracket_pump.R`, ~3 min. It would otherwise have decided the refit's answer:
§5.2h P2 measured `kz` **pinning to the bracket's top**, so the top *is* the refit's `kz`, and
[3830, 6200] was bisected on a model with **no pump** against the very row the pump moves.

| arm | lo (−200 ‰) | hi (−150 ‰) |
|---|---|---|
| **pump OFF (control)** | 3828.7 | 6200.8 |
| shipped | 3830 | 6200 |
| **pump ON (N *and* D)** | **3942.5** | **6528.0** |

- **The OFF arm is the control and it passes**, to 1.3 / 0.8 m²/yr. The recipe is faithful.
- **+328 m²/yr (+5.3 %) at the top**, in the direction §5.2h predicted: the pump makes deep water
  older, so it takes *more* mixing to reach the same Δ¹⁴C. **The pump buys `kz` headroom.**
- **N and D give the IDENTICAL bracket** — a check, not luck: at the preindustrial steady state
  D's scale factor `y[iml,"C"]/ml_C0` is 1 by construction, so **the arms can differ only in the
  transient**. The bracket cannot bias the comparison either way.
- **On the bottom box** — the layer `d14c_deep_ocean` actually scores — the new bracket reads
  −219.8 / −162.8 against the old −220.4 / −163.5. **Nearly a no-op on the scored quantity:** it
  moves *which* `kz` delivers the observed deep age, not the deep age.

---

## 5. THE BLOCKER — `h_ml`, and why it is bigger than a refit nuisance

`LIK_OCEAN_GRAD_HML_OK` = **[85, 120]**. Outside it, all three ocean-gradient rows **SKIP**.

### 5.1 The objective starts outside the band, and is PAID to stay there

**`h_ml`'s init is 75.** So the objective begins with all three rows absent. Measured at
otherwise-init parameters:

| crossing | Δ log-posterior |
|---|---|
| `h_ml` 84.99 → 85.00 (absent → **live**) | **−10.07** (costs) |
| `h_ml` 119.99 → 120.01 (**live** → absent) | **+9.6** (gains) |

**A mode-finder is rewarded for leaving the band.** And `h_ml`'s own likelihood pulls it out
anyway: the log-posterior falls **monotonically** from −4105 at `h_ml` = 70 to −4703 at 150. The
previous (quarantined) mode's `h_ml` was **183.95**.

### 5.2 It is not cosmetic — those rows are what constrain `pump_grad`

| regime | best `pump_grad` | prior sd |
|---|---|---|
| rows **LIVE** (`h_ml` = 100) | **250.0** | **+0.28** |
| rows absent, truncated 20-par arm N | 963.6 | **+5.68** |
| rows absent, truncated 20-par arm D | 1431.0 | **+7.25** |

Live, it lands at 250.0 — close to both the observation (233.109) and §5.2g's 1-D optimum
(274.5). Absent, it is held by its prior plus weak leverage and runs 6–7 σ into the tail.

### 5.3 The smoke test confirmed it in BOTH arms, independently

`calibration/output/pump_arms_SMOKE/` (README marks it not-a-result; the `.rds` are gitignored).
Truncated to 1 restart × 60 iterations:

| arm | `h_ml` | rows | `kz` (bracket [3942.5, 6528]) | `pump_grad` |
|---|---|---|---|---|
| N | **85.00** | ABSENT | 6434.3 (96.4 % up) | 963.6 |
| D | **33.52** | ABSENT | 4174.6 (9.0 % up) | 1431.0 |

**The arms diverge completely** — `h_ml` 85.00 vs 33.52, `kz` at 96.4 % vs 9.0 % of the same
bracket. With the constraining rows off, two arms of the *same* objective wander to unrelated
corners: a comparison run there is **noise, not a close call**. N sitting at *exactly* 85.00 is
§5.1's cliff being found from the outside.

### 5.4 THE POINT THAT MATTERS MOST FOR THE NEXT SESSION

**The discontinuity is probably worse for the MCMC than for the mode-find.** A mode-finder
crossing a 10-log-unit cliff gives a bad mode. An adaptive-Metropolis chain gives a **bimodal
posterior with a near-impassable barrier** between rows-live and rows-absent, and adaptation
will size the proposal to whichever basin it started in. Given the sampler has *never* converged
on this model (§8), this is on the critical path to any posterior at all.

### 5.5 The four options, with my recommendation

1. **Bound `h_ml` to [85, 120] for this refit.** Rows stay live; `pump_grad` is constrained by
   the data it was introduced for. Cost: `h_ml` is no longer free and 183.95 is excluded — a
   real constraint on a parameter that does a lot of other work.
2. **Run as-is and report** which arm had the rows live. Cheap, probably uninformative about
   the pump.
3. **Taper the gradient terms at the band edges** instead of a hard on/off. A likelihood
   redesign, and Marcus's call whether that is in scope.
4. **Four arms** (N/D × free/bounded `h_ml`), ~22 h.

**My recommendation, and it moved during the session:** take **1 for this refit**, but **3 is no
longer deferrable to "later"** — it is the only option that makes the objective sampler-safe,
and §5.4 puts it on the path to any posterior. The band exists because fixed-depth targets are
only like-for-like with the model's boxes inside it, so **a mode outside the band is not scoring
those rows *wrongly* — it is not scoring them at all**, which is the weaker of the two failures
and the one a taper fixes cleanly.

---

## 6. THE TWO-ARM REFIT — built, gated, ready, NOT launched

`calibration/run_modefind_pump_arms.R`. Lifted from `run_modefind.R`; the only changes are the
`base_params` injection, per-arm output paths, and arm labels.

- **`ccx_make_logpost(base_params=)`** is new — it lets a **structural** choice that is not a
  fitted parameter vary between two otherwise identical objectives. **The default path is
  bit-identical** (verified by `identical()` on the log-posterior at init). N and D differ by
  **314 log-units at the hand-set init** — which is exactly why they must be *refitted* rather
  than compared there, since `beta_max`, `kz` and `k_w` can reallocate it.
- **A gate refuses to run if the two arms differ in anything but `pump_mode`.** Fires and passes.
- **Runtime ~6–7 h per arm** at 20 parameters (0.083 s/eval, CHANGELOG 2026-08-15). Sequential,
  not parallel: 16 GB Mac, each arm holds its own forcing tables and spinup state.
- **Same seed both arms**, so no part of a difference is search luck.

**How they are compared, decided before either was run.** Primary is the **Laplace evidence**;
both arms carry the same 20 parameters, priors, data and likelihood, so `(d/2) log 2π` cancels
and the contrast is `Δ logpost(MAP) − ½ Δ log|−H|`. **Stated as indicative, not a Bayes factor:**
with `kz` expected to pin, the posterior is not locally Gaussian in that direction and the
Hessian reports the *transformed* coordinate's curvature. **If the arms come out close the answer
is "the data do not distinguish them", NOT the sign of a small number.** Secondary, and more
informative when the primary is close: the per-stream logL decomposition; where each arm puts
`pump_grad` **relative to its prior**; whether `kz` still pins.

**A LIVE RISK the smoke test surfaced.** The Laplace evidence **degrades to `NA` rather than
being patched** when an arm's Hessian is not PD — N's was not, at a non-converged point. No PD
Hessian, no evidence number. `calibration/recompute_hessian.R` (sweeps the step, checks curvature
is stable) is the remedy, and `ARM_HESS_EPS` = 3e-4 is inherited from `run_modefind.R` rather
than re-derived at 20 parameters.

**NOT A FINDING, and flagged in three places so it is not read as one.** The truncated per-stream
table shows D gaining on `co2_seasonal_MLO` (+29.6), `d14c_NH` (+24.8) and `d13c_level_SPO`
(+10.8) — i.e. *not* "entirely the CO₂ record", which was the pre-refit reading. **Neither arm is
converged.** Recorded only as a reason to read that table carefully when the real run lands.

---

## 7. Files

| file | what |
|---|---|
| `calibration/diag_pump_advection_symmetry.R` | **NEW**, ~1 min. §3.1 |
| `calibration/diag_kz_bracket_pump.R` | **NEW**, ~3 min. §4 |
| `calibration/run_modefind_pump_arms.R` | **NEW**, ~6–7 h/arm. **NOT RUN.** §6 |
| `calibration/output/pump_advection_symmetry/`, `kz_bracket_pump/` + `_run.log`s | committed |
| `calibration/output/pump_arms_SMOKE/README.md` | not-a-result marker + the §5.3 numbers |
| `R/constants.R`, `R/model.R`, `R/calibrate.R` | **the pump wiring — COMMITTED.** Plus `PUMP_GRAD_OBS` full precision, the re-bisected `kz`, `base_params` |
| `tests/testthat/` ×5 | the seven re-derivations + the new constants test |
| `DESIGN.md` | **§5.2i** (the tests), **§5.2j** (`kz` + the two arms) |
| `CHANGELOG.md` | 2026-08-16e and 2026-08-16f |

Memory: `project_ccx_pump_advection_symmetry` (new); `project_ccx_pump_ships_on_decision`
updated to committed.

---

## 8. THE STANDING STATE OF THE MODEL — read this before promising anything

**The machine is built and well-tested. It has never been calibrated.** Verified this session:

- **`calibration/output/mode_fit.rds` does not exist.** No MCMC, pilot, chain or posterior
  output anywhere in `calibration/output/`.
- **Seven quarantined modes**, each superseded because the likelihood changed under it. The only
  usable point estimate is `quarantine/20260815_pre_gradient_terms/`, which predates **both** the
  gradient terms and the pump — so every "at the mode" number in recent handoffs comes from a
  model two structural changes out of date.
- **The sampler has never converged.** The one pilot that ran came back R̂ 4.53, min ESS 4,
  acceptance 0.045–0.063, which `run_modefind.R`'s own header calls burn-in, not sampling.
- **DESIGN §5.4's products do not exist** — no ~100-draw ensemble, no central parameter set. The
  app has nothing calibrated to run on.
- **`luc-veg-debit` is 89 commits ahead of `main`** and has never been merged.

**The critical path:** `h_ml` (§5) → refit (§6) → N-vs-D → **a pilot MCMC that actually
converges** → ensemble → app. Step 4 is the one with no precedent on this model.

**The 4 remaining test failures were triaged 2026-08-15 and are unchanged.** None is
pump-related (measured at `pump_grad` = 0: identical at every lag). `test-pulse.R`'s af(100) =
0.213 vs > 0.30 is an *unbenchmarked* ballpark check on a **declining** ssp119 background while
the protocol-matched gate 12 **passes** (12.4 / 25.6 / 41.9 yr, inside at all three horizons).
`test-luc-permanence.R` ×2 (the fossil reference arm; a case needing `f_luc_wood = 1`).
`test-mechanisms.R` (ENSO 0.30 vs > 0.5). **All four are plausibly stale gates rather than
physics failures — but nobody has diagnosed them, so that is an assessment, not a verdict.**

---

## 9. Open decisions, in dependency order

1. **`h_ml`** — §5. **First job.** Blocks everything below.
2. **N or D** — §6. Marcus's instruction is *fit both and compare*; §5 says the comparison is
   not honest until 1 lands.
3. **THE REFIT** — §6, ~6–7 h/arm. Then `recompute_hessian.R` if either Hessian is non-PD.
4. **The pilot MCMC**, and whether §5.4's barrier is what has been breaking it.
5. **Re-derive `ARM_HESS_EPS` at 20 parameters** rather than inheriting 3e-4 from an 18-parameter
   run. (new)
6. **The frozen-Revelle parity tolerance** (§3.3) — only when something makes it fire.
7. **σ_Δ has NOT plateaued in block size**; **representation error still ZERO**; **point σ vs
   Student-t**; **is A's `kz` = 6404 a blocker or a re-derivation**; **does candidate A ship**.
   (all carried unchanged from 16c/16d)
8. **Merge `luc-veg-debit`**, eventually. 89 commits is a lot of unmerged work.

---

## 10. Non-obvious state, and cautions

- **THE WORKING TREE IS CLEAN.** 16d's "dirty on purpose" caution is **discharged** — do not go
  looking for held-back edits.
- **16d's `test-parity.R` caution is discharged**: measured, they were never a parity break, and
  the tolerance is now derived (§3.2).
- **`calibration/output/mode_fit.rds` is still absent** (not empty — absent). Every "at the mode"
  number comes from `quarantine/20260815_pre_gradient_terms/mode_fit.rds`. (carried, sharpened)
- **The pump diagnostics FORCE `h_ml` to 100** because all three gradient rows skip outside
  [85, 120]. Any arm run outside the band scores a *different objective*, silently — and §5 is
  that fact arriving as a blocker rather than a caveat. (carried, promoted)
- **The full suite takes ~10–12 min** and its summary reporter **prints only the first 10
  failures**; re-run individual files for assertion values. Better: use the `reporter="silent"`
  + `as.data.frame(r)` pattern this session used, which gives exact per-file counts.
- **`calibration/output/pump_arms_SMOKE/` is NOT A RESULT.** Neither arm is converged. Its README
  says so; the numbers in it exist only as §5.3's evidence.
- **Name collision, unchanged:** `grad_off_co2` / `grad_off_d13c` in `err` are the **MLO−SPO
  ATMOSPHERIC** offsets. The ocean rows are `LIK_OCEAN_GRAD_*` / `ocean_grad_*`.

**Still do NOT:** hand-tune stream weights; delete `excess_c14_ocean` or `d14c_intcal`; free any
land turnover parameter; delete the `kz` bracket bare; build the conveyor; splice any
pre-2026-08-15 posterior; **compare any logL across the 2026-08-16 boundary**; quote §4.2's ~384
log-units or its 1996.2555 baseline; **quote the SHIM's export figures or the "3.6×" POC ratio**;
**quote §5.2g's +259.4 as the pump's value without the upper-bound caveat**; **quote 274.5 as
`pump_grad`'s value** (it is a fit at a `kz` the refit will move); or **quote anything from
`pump_arms_SMOKE/`**.

---

## 11. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-16f_pump_shipped_refit_blocked.md`. **The pump SHIPPED — wiring
> committed, all 7 blocking tests re-derived, suite 4 failing / 857 passing — and `kz` was
> re-bisected to [3942.5, 6528].** The two-arm refit is written, gated and smoke-tested but
> **deliberately not launched**. The job is §5 then §6: **settle `h_ml` first** (the objective
> starts outside [85, 120], is paid ~10 log-units to stay outside, and with the gradient rows off
> `pump_grad` runs to 6–7 prior σ in *both* truncated arms), **then N vs D**. Note §5.4: the
> discontinuity is probably worse for the MCMC than for the mode-find, and the sampler has never
> converged on this model. Do not launch `run_modefind_pump_arms.R` before `h_ml` is settled.
