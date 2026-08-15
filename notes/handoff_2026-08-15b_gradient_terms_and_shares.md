# Handoff — CarbonCycleEmulator, 2026-08-15b: the gradient is in the objective, and the refit is HELD

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `luc-veg-debit`,
still **not merged**. Working tree clean.
**Supersedes `handoff_2026-08-15_mm_flip_map_mode_and_5c.md`** for items 5, 5b and the four
flagged tests; everything else in that note still stands. `notes/review_2026-08-14_architecture.md`
remains the statement of WHAT was wrong — but **§0's headline was already superseded** by 15,
and **§2.3's "there is no gradient term" is now false**.

---

## 0. START HERE

1. **Items 5 and 5b are DONE.** The interhemispheric gradient is a scored stream for the first
   time, and the land-use hemispheric share is sourced and time-varying. §§2–3.
2. **Three of the four flagged test failures are RESOLVED — by re-expression, not
   re-baselining.** Every repair replaced a hard-coded fixture with a *derived* quantity, and
   all three were mutation-tested. §5. **Suite 4 failing, was 8.**
3. **Parameters 18 → 20.** `grad_off_co2`, `grad_off_d13c`. `calibration/output/mode_fit.rds`
   is **quarantined and the canonical path is EMPTY**. §6.
4. **THE REFIT IS HELD — Marcus's call, 2026-08-15.** Not blocked on 5/5b any more; held
   pending the `sigma_co2` decision from 15 §4.1. **Do not start item 8 without re-asking.** §7.
5. **`FORC_FOSS_NH_SHARE` moved 0.95 → 0.9201.** Measured, not chosen. Anything comparing
   against a pre-today run must set it back.

---

## 1. What Marcus decided today

| | decision | evidence it was taken on |
|---|---|---|
| 1 | CO₂ gradient: score the **level, with a calibrated offset parameter** | the offset is measured at −0.45 ± 0.10 ppm and rejected from 0 |
| 2 | δ¹³C gradient: **same treatment**, despite being a pure offset | b = 1 admissible in all four fits |
| 3 | `FORC_FOSS_NH_SHARE` **0.95 → 0.9201** | EDGAR-measured; +95 log-units to the new term, −1.5 to everything else |
| 4 | the three test failures: **re-express on derived quantities** | each fixture had gone stale *because the model improved* |
| 5 | **HOLD the refit** | ~6–7 h at 20 params; `sigma_co2` is unidentified and would hurt mixing |

---

## 2. Item 5b — the land-use share (`98f0457`)

`FORC_LUC_NH_SHARE = 0.55` was "provisional" since it was written and is wrong at **both**
ends. OSCAR v3.1's *Regional* sheet gives a flux-weighted NH share of **0.838 (1750–1849) →
0.398 (1990–2018)**; against the constant that is **+31 GtC** of cumulative land-use carbon
misplaced by 1959. Full table and provenance in **DATA.md §6a**.

**Why it is a measurement and not a preference.** The within-region NH fractions are geographic
judgements, so the product ships a lo/central/hi bracket — and **the direction survives all of
it**: pre-1950 even the low end is ≥ 0.60, post-1990 even the high end is ≤ 0.53. The ends do
not overlap under any admissible judgement. 0.55 is not even the flux-weighted mean (0.620).

**Three traps, all gated (`test-luc-nh-share.R`, 22 assertions, two mutation-tested):**

- **One share per calendar year, held, not interpolated to months.** Keeps
  `mean_year(luc_NH) = share(y)·mean_year(luc)` exact and puts the only discontinuity *on* the
  year boundary, where the harmonic estimator cannot alias it into the seasonal statistic.
- **The pre-window cumulative takes its own flux-weighted share** (~0.79 for a 1900 start, not
  the window's ~0.49). Getting this wrong misplaces ~14 GtC of converted land and **nothing
  else in the suite would see it** — the flux still conserves.
- **Outside 1750–2018 the end value is HELD.** Every SSP run splits on a frozen 2018 share
  (~0.385). Extrapolating the decline forward runs it negative before 2260.

`FORC_USE_LUC_NH_SHARE_TS = FALSE` reproduces every earlier result, **max |diff| exactly 0**
across every numeric column of a full-record *and* a windowed forcing.

**It cost 17.2 log-units, almost all in `co2_seasonal_MLO`.** A bias correction, not a fit
improvement — the same shape as 5c. **Do not expect 5b to raise the log-posterior.**

---

## 3. Item 5 — the gradient terms (`abf8e3b` measurement, `b42859e` implementation)

`calibration/diag_gradient_terms.R` measured five things *before* anything was written, because
**the σ is the decision**. Output kept at `calibration/output/gradient/`.

### 3.1 The four findings that shaped the design

1. **The likelihood's own estimator reproduces gate 9** to ≤ 0.02 ppm on every decade it covers,
   and drops the 1950s entry (8 paired months). No new estimator; gate 9's mandatory seasonal
   adjustment is handled by construction rather than by a special case.
2. **Observational floors, measured.** CO₂ **0.225 ppm** RMS between Scripps and NOAA — *and it
   is a lower bound*: **`MLO` and `MLO_NOAA` agree to 0.002 ppm RMS over 189 months**,
   confirming 15 §4.1's flag that they are one series under two names, so 0.225 is the two SPO
   records alone. δ¹³C **0.0152 ‰**, and *that* one is a genuine two-station two-network
   comparison (the records share no month timestamps at all).
3. **THE MISS IS NOT ONE THING, AND THE TWO SPECIES DIFFER.** Regressing obs ~ a + b·model:
   - **CO₂** — both rejected. A stable **−0.45 ± 0.10 ppm intercept** (the sign and size a
     station-below-the-source-region argument predicts: MLO at 19.5 °N cannot represent the NH
     mean) **plus** a genuine shape error whose sign changes across the record (b = 0.845 at
     defaults, 1.14–1.23 at the mode).
   - **δ¹³C** — **b = 1 admissible in all four fits**, only the +0.10 ‰ intercept rejected. A
     pure offset. And **8× larger** than scaling CO₂'s 19 % predicts, so `grad_off_d13c` is
     absorbing the **structural** δ¹³C misfit, *not* a representation constant. **The δ¹³C
     gradient term contributes shape, not level. Never read a fitted `grad_off_d13c` as a
     representation estimate.**
   - The MAP mode is pre-5b, so part 3 reports it on **both** forcings; the finding is robust
     (a −0.55 vs −0.46, b 1.23 vs 1.14).
4. **The double count is second-order.** The two station levels imply a gradient sd of 1.45 ppm
   (2.55 at σ_co2 = 1.5); a term at 0.35 outweighs it ~17× in variance. **Adding** a term is
   right; **rotating (MLO, SPO) → (mean, gradient) was considered and rejected on that
   measurement** — it would rewrite the two highest-leverage streams to fix something that is
   not binding. Re-measure if `sigma_co2` or `LIK_CO2_REP_ERR` move.

### 3.2 What shipped

Streams `co2_gradient`, `d13c_gradient`. Parameters `grad_off_co2` ~ N(0, 0.5 ppm),
`grad_off_d13c` ~ N(0, 0.15 ‰). **Both priors are centred at ZERO** — centring them on the
measured offsets would tell the model the answer and then credit it for agreeing; the prior
*widths* put the measured values near 1 sd.

σ = **the measured model-vs-obs scatter about a constant offset, floored by the observations'
own precision**: **0.35 ppm** and **0.025 ‰**. `test-gradient.R` recomputes both floors from the
data and fails if either σ is tightened below them.

**THE ABSENCE CONTRACT — read this before writing any diagnostic.** The offsets ride in `err`,
and their **absence SKIPS the terms** rather than zeroing them (the same contract `deep` uses).
A zero offset is *not* a neutral default: it asserts the box gradient **is** the station
gradient, which the measurement rejects at 95 %. **Every diagnostic written before today passes
only three sigmas and therefore shows both streams ABSENT under `by_stream`.** That is visible
and intended — but it means *no pre-today diagnostic's log-likelihood is comparable with a
post-today one*, and re-running one without adding the offsets will silently under-report.

**Effect:** τ_ex's constraint is now dominated by the gradient (**+366 / −950** log-units per
prior sd) and it pulls **opposite** to everything else (−208 / +107). DESIGN's long-standing
claim that gate 9 constrains τ_ex is true for the first time. DESIGN §6 gate 9 carries the full
measured status.

---

## 4. Three things the gradient term decided on its way in

- **The fossil NH share.** It prefers the EDGAR-measured **0.9201** over 0.95 by +95 log-units
  where the rest of the objective is indifferent (−1.5). Moved, per decision 3. Gradient
  5.03 → **4.67 ppm** against an observed 3.74.
- **5b's land-use bracket.** The term pulls toward the **LO** end (+191 log-units at σ = 0.35 vs
  +4 for the hi end). Nothing has been changed on that basis — it is one term's preference, not
  a measurement — but **expect the refit to push the share down**, and if it lands at the
  bracket edge that is the signal the within-region judgements need revisiting rather than the
  parameter being right.
- **The δ¹³C gradient lead is dead, again and more firmly.** 5b moved it −0.245 → −0.238 ‰
  against an observed −0.074. The shares are not the cause of the 3× miss; part 3 now says why
  (pure offset, b = 1), and it is structural.

---

## 5. The four flagged tests — THREE RESOLVED, one left

**All three repairs replaced a hard-coded fixture with a DERIVED quantity, and all three were
mutation-tested.** None was re-baselined.

| test | was | now |
|---|---|---|
| `test-likelihood.R` CO₂-bias | `cost(1) > 100` **from zero** | cost measured **from the fitted offset**; the guard is on the **curvature** A > 10 log-units/ppm² |
| `test-likelihood.R` σ_co2 profile | collapsed value beaten by a hand-picked σ = 5 | the profile's optimum, as an **effective sd**, must sit within 1.5× the **measured residual RMS** |
| `test-luc-scale.R` gross-vs-net | `abs(gross − net) > 10` | the **closed-form E_LUC displacement**, asserted to 1e-8 |

**Why each had gone stale is the same story: the model improved.** The CO₂-bias test was
measuring the model's own level bias, not the price of a bias, so it broke twice as the level
fit got better. The σ_co2 comparator of 5 stopped being sane once the residual RMS fell to
~1.13. The gross-vs-net gap is *large because the model over-absorbs*, so it shrinks as the
sink improves (4.57 → 3.50 → 3.48 GtC/yr) — that test used a symptom of the old bug as a proxy
for the fix and would have failed **harder** the more the refit succeeded.

**Mutation tests, both caught:** reverting `gcb_land_sink` to the NET comparison fails
`test-luc-scale.R` (2 assertions); inflating the CO₂-level sd 30× — the AR(1) loophole in
effect — fails `test-likelihood.R` (3).

### The 4 that remain, unchanged and untouched

```
test-luc-permanence.R:88    the FOSSIL reference arm, 0.151 vs > 0.2
test-luc-permanence.R:104   needs f_luc_perm = 0 AND f_luc_wood = 1; sets only the first
test-mechanisms.R:32        ENSO switch weak (0.30 vs > 0.5)
test-pulse.R:113            ssp119 airborne fraction 0.213 vs > 0.3
```

`test-pulse.R:113` is still worth a separate look: it is an *unbenchmarked* ballpark check on a
declining SSP1-1.9 background, while gate 12 — the protocol-matched Joos comparison at a held
389 ppm — passes. Different protocols. **None of these was flagged for Marcus and none has been
touched.**

---

## 6. Non-obvious state

- **`calibration/output/mode_fit.rds` IS GONE from the canonical path**, quarantined to
  `calibration/output/quarantine/20260815_pre_gradient_terms/` with a README. It is an
  18-parameter mode belonging to a different input (5b) and an objective with two fewer
  streams. **Its log-posterior −2221.3 is NOT on the same scale as anything computed after
  today.** `app/global.R`'s `identical(md$param_names, CCX_PARAM_NAMES)` guard rejects it —
  that is the guard working. The app has no mode until item 8 runs.
- **Three switches now reproduce history exactly**, and between them nothing had to be deleted:
  `FORC_USE_LUC_NH_SHARE_TS = FALSE` (pre-5b), `FORC_USE_EMIS_SEASONALITY = FALSE` (pre-5c),
  `p$fert_form <- CCX_FERT_LOG` (pre-2026-08-14). **`FORC_FOSS_NH_SHARE` has no switch** — set
  the constant back to 0.95 by hand to reproduce a pre-today run.
- **One eval is now 0.083 s**, up from 0.060. A comparable mode-find is ~6–7 h, not ~5.
- **`ccx_loglik()` gained no new arguments** — the offsets ride in `err`. But that means the
  *positional*-argument hazard from 15 §10 is unchanged and `err` now has five fields where
  every legacy caller supplies three. **Name your arguments; check `by_stream` for ABSENT
  streams before quoting a log-likelihood.**
- **Every "at default parameters" number in this repo is still at `gamma_enso` = 0** while
  `app/global.R` overrides it to 0.5. Unchanged, still a live provenance hazard.
- New diagnostic `calibration/diag_gradient_terms.R` (~3 min), output under
  `calibration/output/gradient/`. New tests `test-luc-nh-share.R` (22),
  `test-gradient.R` (28).
- The nine legacy diagnostics pinned to `CCX_FERT_LOG` are **now doubly stale**: they also
  predate 5b, 5 and the fossil-share move.

---

## 7. The ordering, amended

| # | task | status |
|---|---|---|
| ~~1–4~~ | objective, β default, `luc_scale`, GLODAPv2 | **DONE** |
| ~~5~~ | **interhemispheric-gradient terms** | **DONE** `b42859e` |
| ~~5b~~ | **time-varying LUC hemispheric share** | **DONE** `98f0457` |
| ~~5c~~ | sourced input seasonality | **DONE** `0cd9fbb` |
| **6** | `LIK_EXCESS_C14_TARGET` | **NOT a blocker** — 15 §9 |
| **6b** | **`sigma_co2`: fix it or drop it — DO NOT SAMPLE IT** | **NEW BLOCKER on 8.** 15 §4.1: unidentified, pinned at a boundary, will hurt mixing and covariance conditioning. This is what the refit is now held on |
| ~~7~~ | saturating fertilisation | **DONE** |
| **8** | **THE REFIT**, 20 parameters, ~6–7 h | **HELD by Marcus 2026-08-15.** Structurally unblocked; do NOT start without re-asking |
| **9** | pump | do the cheap `h_ml` capacity-vs-export decomposition FIRST (15 §4.2) |

**Still do NOT:** hand-tune stream weights; delete `excess_c14_ocean` or `d14c_intcal`; free any
land turnover parameter; delete the `kz` bracket; build the pump before the `h_ml`
decomposition; splice any pre-2026-08-15 posterior into a new chain (**two** model changes and
two new parameters now separate them); quote a log-likelihood from a diagnostic that has not
been given the gradient offsets.

---

## 8. Opening the next session

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-15b_gradient_terms_and_shares.md`. Items 1–5c and 7 are done and
> the gradient is scored. **The refit (item 8) is HELD by Marcus and must not be started without
> asking** — it is waiting on the `sigma_co2` decision (item 6b, handoff 15 §4.1: unidentified,
> pinned at a boundary, fix it or drop it, do not sample it). Suite is **4 failing**, none of
> them flagged for Marcus. Note that `ccx_loglik()`'s new gradient streams are **ABSENT** unless
> `err` carries `grad_off_co2` and `grad_off_d13c`, so no pre-2026-08-15 diagnostic's
> log-likelihood is comparable with a new one until it is updated.
