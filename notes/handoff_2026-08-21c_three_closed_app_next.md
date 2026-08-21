# Handoff — CarbonCycleEmulator, 2026-08-21c: all three items closed, and the app is the next thing

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `368dc89`.
**Supersedes:** `handoff_2026-08-21_refit_landed_next_three.md` (§§2–4 all answered) and
`handoff_2026-08-21b_ridge_confirmed_repair_amended.md` (its §5 said §4 was open; it is not).
Read this one; the other two are provenance.

---

## 0. STATE IN TEN LINES

1. **§2 CLOSED.** The (`seas_T_amp_NH`, `q10`) ridge is EXACT. The repair is amended and
   **BLOCKED on a soil-damping factor with provenance** — the 15 h refit is not owed until
   that exists, and its answer is already computed (§2d below).
2. **§3 CLOSED, and it was a false alarm.** `log|−H|` moves 0.03, `h_ml`'s sd 2 %.
   **The uncertainties in `mode_fit_pumpN.rds` were quotable all along.**
3. **§4 CLOSED.** The **δ¹³C** seasonal rows veto the observed ocean amplitude, by
   **cancellation, not strength**. §4's own advice applies: **STOP, and do NOT buy the
   Takahashi climatology.**
4. **`prior_z()` was wrong by up to 1.3 sd** and had mis-ranked the whole week's work.
   Fixed, tested, and two of six |z| > 3 flags were artefacts.
5. **The app runs on UNCALIBRATED DEFAULTS** because `app/global.R` looks for a file that
   does not exist. This is the single highest-value fix in the repo and it is nearly a
   one-liner. **§6.**
6. **974 / 976 tests pass.** The two failures are still the by-design `test-fluxes.R` ones
   awaiting Marcus.
7. **The pulse-partition panel is SPECIFIED** (DESIGN §7b, Marcus 2026-08-21: five bars,
   summing to one) and **PROTOTYPED** (`diag_pulse_partition.R`). One prerequisite: two
   output columns.
8. **A label is not a perturbation** — they differ 2.8× in the atmosphere at 100 yr, and the
   model already carries the tracer. Both belong in the app; they must not share a caption.
9. **The model puts 40 % of a pulse in the LAND at year 3000.** No existing gate can see
   this. It is the most interesting unexamined thing in the model right now.
10. Still no posterior. Nothing this session changes that.

---

## 1. WHAT WAS RUN, AND WHERE IT LIVES

| script | answers | output |
|---|---|---|
| `calibration/diag_seas_T_amp_q10_ridge.R` | 3 axes × 4 tiers × 2 objectives | `output/seas_T_amp_q10_ridge_{amp,q10,q10_land,q10_partial,sst}.{rds,log}` |
| `calibration/diag_seas_reanchor_arithmetic.R` | what a re-anchored refit would find, **without running it** | prints |
| `calibration/recompute_hessian.R` (rewritten) | second-order block, per-parameter step | `output/pump_arms/mode_fit_pumpN_hess.rds` |
| `calibration/diag_pulse_partition.R` | the §7b panel's feasibility | prints |
| `calibration/diag_tracer_vs_perturbation.R` | label vs perturbation | prints |
| `R/calibrate.R::ccx_prior_z` + `tests/testthat/test-prior-z.R` | prior-tail position, correctly | — |

**`mode_fit_pumpN.rds` is NOT modified.** The recomputed second-order block is beside it as
`mode_fit_pumpN_hess.rds`; `--update` is required to write it back and has not been passed.

---

## 2. §2 — THE RIDGE IS EXACT, THE REPAIR IS AMENDED, AND IT IS BLOCKED

### 2a. Confirmed

`seas_T_amp_NH` × ln(`q10`) holds to **2.2609–2.2663** across q10 = 1.09 → 2.0 (PAIRSH
tier), and the re-optimised `A_T` at q10 = 2.0 is **3.2695 K** against the analytic
2.2513/ln 2 = **3.2479**. Four significant figures. The Hessian agrees independently:
**cor(q10, `seas_T_amp_NH`) = −0.972** — strong, and NOT degenerate.

### 2b. The seasonal rows do not identify q10

**4.3 log-units** across the whole q10 range. `beta_max`/`fert_k` absorb **85 %** of the cost
of raising q10 (352 log-units with them frozen → **50.3** free). **So q10 is NOT determined
to ±0.019** — that Laplace marginal is local, and it already inflates 11.6× over the
conditional.

### 2c. Two mistakes I made getting there, both worth not repeating

- **I read a frozen-block profile as bounding the posterior.** BLOCK freezes `beta_max`,
  `fert_k`, `luc_scale` — and β–γ compensation is exactly the repair it forbids.
  `match_incumbents_optim`, applied to myself. **This bit twice: §4's frozen tier is also
  ~2× its re-optimised one.**
- **A pure-likelihood objective lets the NUISANCE parameters escape.** The first `land` run
  put `seas_T_amp_SH` at 1e-23 and `sst_seas_amp_NH` at 1e-31 in every row — both channels
  off at z = −37.5 — and reported a spread of 15.9. Internally consistent, and a profile of
  a **different model**. **Use the `partial` objective** (the default): it drops the priors
  on the parameters UNDER TEST and keeps every other one. GATE 3 prints which are which.

### 2d. The refit's answer, computed rather than run

`diag_seas_reanchor_arithmetic.R` re-scores the `land` points under a re-anchored prior set.
No model runs.

| q10 | `A_T` (K) | Δ logpost NOW | Δ logpost DAMPED |
|---|---|---|---|
| 1.0907 (mode) | 26.49 | 0.00 | 0.00 |
| **1.35** | **7.81** | −20.2 | **+19.7** |
| 2.00 (literature) | 3.45 | **−63.7** | +4.0 |

Damping **both** land amplitude priors by 0.2838 (NH centre 14.32 → 4.06 K, SH 5.05 → 1.43 K).
**The sign flips; the landing is q10 ≈ 1.35–1.5, not 2.0.** And the decisive lever is the
**SH** prior as much as the NH — §2 as written only argued the NH case.

### 2e. WHAT TO DO — and the first step is a gate, not a refit

1. **Get a soil-temperature damping factor with provenance.** Respiration-weighted depth.
   **If it comes back far from 0.28, that is the falsification and the refit should not be
   run at all.** The 0.2838 above is DERIVED to put the mode's product at the literature q10
   — the most favourable value the hypothesis could have, and not a measurement.
2. Only then: re-anchor **both** land amplitude priors, keep the bracket-derived widths,
   refit (~15 h, warm-started).
3. **Pre-register `q10` → 1.35–1.5, `A_T` → 6–8 K.** Not "q10 back near 2.0".

---

## 3. §3 — CLOSED, AND SMALLER THAN IT LOOKED

**The step is now DERIVED:** `eps_k = 0.1 × sd_k`, each direction's own posterior width, so
the objective moves 0.005 log-units in every direction by construction. All 21 parameters
stable to < 1 % across eps/3 → 3·eps.

**A rule I tried and rejected, recorded so it is not retried:** "largest stable diagonal
step" chose eps = 1e-1 for nearly everything — 313 log-units for `beta_max` — and produced a
**positive** eigenvalue of +86.8 in the (`beta_max`, `fert_k`) plane, correlation **+0.997**.
A diagonal-only stability scan cannot see a cross-derivative going bad.

**The cause is not the one §3 proposed.** 3e-4 is 0.5–1.8× the right step for the seven STIFF
directions and 0.003–0.06× for the soft ones — calibrated on the stiff subspace. `h_ml` is
simply the SOFTEST direction (unconstrained sd 0.888), 296× under-stepped. **`kz` was
under-stepped 181× and `gamma_enso` 66×, neither near a bound and neither flagged** — the
instability report was UNDER-reporting. The logit-compression story is true about REACH and
wrong about CAUSE.

**And it barely mattered:** `log|−H|` **127.0986 vs 127.1280**, `h_ml` sd **+2 %**, all else
**< 0.5 %**, −H positive-definite. "NO UNCERTAINTIES ARE QUOTABLE" was over-cautious.

**`recompute_hessian.R` also needed two structural repairs:** it read `md$u_mode` and decoded
it under the DEFAULT table (band-dependent; this file does round-trip, and GATE 1 now prints
both), and **it wrote its result back over the mode file**. Both fixed.

---

## 4. §4 — CLOSED. THE δ¹³C ROWS VETO IT, BY CANCELLATION

`diag_seas_T_amp_q10_ridge.R sst`, 0.05 → the observed 2.2374, `partial`.

**Re-optimisation halves the veto:** mode → observed costs **223.2** frozen, **108.5** with
the seasonal block free. Half of every earlier "the ocean channel is rejected" reading was
home-ground advantage.

**Outcome 3 excluded:** of the 223.2 frozen, **222.3 is in the four seasonal rows, 0.96 in
everything else.** Not a leak into the annual budget. Not a bug.

**The veto is δ¹³C** — the outcome §4 called surprising and worth stopping on:

| stream | Δ at the observed amplitude |
|---|---|
| `d13c_seasonal_MLO` | **−52.3** |
| `d13c_seasonal_SPO` | **−26.7** |
| `co2_seasonal_MLO` | −20.4 |
| `co2_seasonal_SPO` | −10.7 |

**δ¹³C carries 72 %.**

**The mechanism is CANCELLATION, not strength.** Raising `sst_seas_amp_NH` 0.4668 → 2.2374
makes the MLO CO₂ seasonal amplitude **fall**, 6.224 → 5.302 against an observed 6.754 — the
ocean channel is ANTIPHASE to the net cycle. The δ¹³C-per-ppm signature then **rises**,
0.06804 → 0.07906 against an observed 0.0528, because the denominator shrinks faster than the
numerator. **The near-neutral ocean channel does not dilute the signature as §4 predicted; it
inflates it.** Same cancellation geometry `ccx_seas_chan_budget` found between NEP and
respiration, now in the ocean limb.

**And it is NOT phase** — `CCX_SST_SEAS_LAG` is already at its measured 1.32.

**SO: STOP.** Do not buy the Takahashi seasonal flux climatology. It would measure the
STRENGTH of a channel whose problem is its SIGN relative to everything else. The next move,
if there is one, is structural: the model's seasonal cycle is built from two channels that
mostly cancel, and a third one is being asked to fit into a residual it is antiphase to.
That is a modelling question for Marcus, not a data acquisition.

---

## 5. THE PRIOR-TAIL SCREEN WAS WRONG, AND IT HAD RANKED THE WORK

Both mode-finders built the prior CDF on `seq(x/1e3, x*1e3, length.out = 4001)` — a LINEAR
grid. For `seas_T_amp_NH` at x = 25.94: **one grid point inside the entire prior.**

| parameter | reported | correct |
|---|---|---|
| `seas_T_amp_NH` | +3.29 | **+2.65** |
| `bomb_total` | +3.08 | **+1.81** |
| `q10` | −2.01 | **−2.43** |
| `rep_dC` | +5.75 | **+5.18** |
| `seas_T_amp_SH` | −3.71 | **−3.99** |
| `sst_seas_amp_NH` | −5.97 | **−6.27** |

The |z| > 3 list loses two of six. Also: **the prior CENTRE for `seas_T_amp_NH` is
14.3215 K** (the geometric mean of the bracket), not the LO end 11.445 — the joint prior
implies **4.41×**, not 3.52×.

Replaced by `ccx_prior_z()` in `R/calibrate.R`, integrating in the unconstrained coordinate.
`tests/testthat/test-prior-z.R`, 27 assertions. **The stale `prior_z` field in the arm file
is NOT quarantined** — it touched one reported field, never the objective, and is
recomputable in one line.

---

## 6. THE APP AND A BETA — ASSESSED THIS SESSION

**The single highest-value fix in the repo.** `app/global.R` resolves parameters from
`calibration/output/mode_fit.rds`. **That file does not exist**; the adopted mode is
`mode_fit_pumpN.rds`. So the banner says "uncalibrated defaults" and this is what ships:

| | CO₂ @2024 | vs obs 424.3 ppm | land sink | ocean sink |
|---|---|---|---|---|
| **app defaults (today)** | 409.8 | **−14.6 ppm** | 2.73 | 2.44 (−1.96σ) |
| **calibrated arm-N mode** | 418.6 | **−5.8 ppm** | 2.54 | 2.89 (−0.83σ) |
| GCB 2025 | — | — | 2.36 ± 0.5 | 3.22 ± 0.4 |

Tab 1's takeaway is "the model reproduces 65+ years of measurements from emissions alone."
At −14.6 ppm (3.4 %) that is awkward; at −5.8 ppm (1.4 %) it is defensible with a caveat.
**Check the 21-parameter-name guard in `app_params()` accepts the arm file** — it was written
to reject a stale 18-parameter fit.

**The rest of the beta list, ranked:**

2. **No posterior ⇒ no uncertainty ribbons.** DESIGN §7 calls for them on historical +
   presets. A beta can ship central-line-only with a banner, but it is a designed feature
   that will not be there.
3. **Ocean sink ~10 % weak even at the mode** (2.89 vs 3.22). Tab 2 is literally "Where does
   the carbon go?", so it is the first number a knowledgeable visitor checks.
4. **Pulse response low against the literature.** Gate 12 **passes** — integrated IRF
   12.4 / 25.5 / 41.9 yr inside Joos's 5–95 % — but at the low end of each, with the point
   IRF **0.077–0.118 below** the multi-model mean throughout. Belongs in the caption of the
   tab the project exists for.
5. **Cold start unverified.** `global.R` took 79 s here (under load; `DEPLOY.md` claims
   ~20 s). shinyapps.io has startup timeouts. **Do a timed real deploy before announcing.**
6. **Two millennial-run labelling issues, both benign and both currently silent:** non-CO₂
   ERF is held flat past 2500, and the CO₂→forcing curve extrapolates above 1687 ppm (SSP5-8.5
   pulse runs already trip that warning).

**DESIGN §6 gate 7's status line is stale** — it says land +2.28σ / ocean −1.52σ; measured
today at defaults it is land **+0.73σ** / ocean **−1.96σ**. The land improved a lot and the
ocean got worse. That line carries its own warning that it is a measurement, not a
description.

---

## 7. THE PULSE PANEL (DESIGN §7b) — SPECIFIED, PROTOTYPED, ONE PREREQUISITE

**Marcus 2026-08-21: FIVE BARS, SUMMING TO ONE** — atmosphere / vegetation / soil / surface
ocean / deep ocean. Curve of the atmospheric perturbation on top, bars underneath, annual to
2100 then points at 2200 … 3000.

**It works.** 100 GtC in 2030 on SSP2-4.5: the partition closes to **0.000 %** from 2050
onward, and two coupled runs 1750–3000 take **1.7 s** — live in Shiny, nothing precomputed.

| year | atmosphere | land | surface ocean | deep ocean | ppm left |
|---|---|---|---|---|---|
| 2100 | 0.506 | 0.233 | 0.024 | 0.237 | 23.8 |
| 2300 | 0.292 | 0.352 | 0.016 | 0.339 | 13.8 |
| 3000 | 0.164 | 0.396 | 0.011 | 0.429 | 7.7 |

**THE ONE PREREQUISITE:** `land_C` aggregates leaf + wood + soil_fast + soil_slow, so
**vegetation and soil do not exist as output columns**. The state vector has all four;
`ccx_run_fast()` must return them, with a `test-parity.R` entry. A column, not a mechanism.

**THREE TRAPS, all hit by the prototype:**

1. **The SSP emissions table is DECADAL past 2020.** Add the pulse to an ANNUAL grid;
   adding it to a decadal knot delivers ~10× the pulse, smeared over twenty years. The first
   run reported **242 ppm** from 100 GtC. `app/server.R` already interpolates first and is
   correct.
2. **`deep_C_{NH,SH}` is the BOTTOM BOX**, one interior layer of ten, and exists for the
   §5.2a gradient terms. Summing `ml + deep` captures 31 % of `ocean_C`. **The interior is
   the REMAINDER:** `ocean_C − (ml_C_NH + ml_C_SH)`.
3. **This panel is not gate 12** and must not be captioned as if it were. Gate 12's PD100
   protocol holds the background at 389 ppm.

### 7a. A LABEL IS NOT A PERTURBATION (Marcus's tracer proposal, 2026-08-21)

**No fourth isotope is needed.** ¹⁴C decays at the same rate in every box, so
L(t) = e^(−λt)·M(t) solves the decaying system exactly and **the fraction in each reservoir
is identical**. Checked, not assumed: **1.1e-16**. The model's existing ¹⁴C, transported
without fractionation, already IS the inert tracer.

**But the two experiments answer different questions** (held preindustrial background):

| yr | label: atm / land / ocean | perturbation: atm / land / ocean |
|---|---|---|
| 20 | 0.165 / 0.238 / 0.597 | 0.313 / 0.472 / 0.215 |
| 100 | **0.055** / 0.131 / 0.814 | **0.154** / 0.597 / 0.249 |
| 1000 | **0.021** / 0.058 / 0.921 | **0.147** / 0.424 / 0.429 |

Factor **2.8** in the atmosphere at 100 yr. The label converges on the reservoirs' own
proportions (744 / 1667 / 36,591 GtC → 1.9 / 4.3 / 93.8 %, measured 2.1 / 5.8 / 92.1 % at
1000 yr) because atoms mix. The perturbation does not, because carbonate buffering sets how
much EXTRA the ocean holds.

**§7b's bar chart must stay the PERTURBATION partition.** The label version on the same axes
with the same caption states the true premise of the residence-time argument §7a exists to
answer. **Both belong in the app — Cawley 2011 vs Essenhigh 2009 is exactly this — and they
must not share a caption.** Two bar charts side by side is probably a better tab 5 than the
two decay curves alone.

(¹⁵C is radioactive, t½ ≈ 2.4 s. For a public panel, "tagged carbon" beats an isotope number
a curious student will look up.)

---

## 8. THE MOST INTERESTING UNEXAMINED THING

**At year 3000 the model puts 40 % of a pulse in the LAND** and 43 % in the deep ocean. On a
preindustrial background it is worse — ~60 % land at 50–100 yr. Most models send far more to
the ocean at millennial timescales.

**No existing gate can see this.** Gate 12 scores the airborne fraction, and an airborne
fraction says nothing about WHICH sink took the rest. So the §7b panel is a new diagnostic as
well as a panel, and **the land share should be checked against the literature before it
ships with a caption claiming it teaches where carbon goes.**

Related, and possibly the same thing: gate 12's point IRF is 0.077–0.118 **below** the
multi-model mean at every horizon — the model sheds atmospheric carbon too fast — and §2
found `beta_max`/`fert_k` absorb 85 % of a q10 change. A land sink that is too eager would
explain all three.

---

## 9. NON-OBVIOUS STATE

- **`diag_seas_T_amp_q10_ridge.R` takes five args:** axis (`amp`|`q10`|`sst`), tag, tiers,
  grid, objective (`partial`|`lik`). Tiers for amp/q10: `pair`/`pairSH`/`block`/`land`; for
  sst: `frozen`/`seas`/`land`. **Default to `partial`.** `lik` exists only to reproduce the
  first pass and lets the nuisance parameters escape.
- **Never read the `pair` tier alone.** It freezes `seas_T_amp_SH` while q10 — which both
  hemispheres SHARE — moves. On the amp axis that artefact is 217.6 vs 111.8 of spread.
- **One bad optimiser cell:** q10 = 2.3, BLOCK tier, `lik` objective — non-monotonic
  (`d13c_seasonal_MLO` −36.7 against −3.4 at q10 = 2.0). A different local optimum. Read
  PAIRSH there.
- **`calibration/diag_phi_eff_profile.R` still carries a double-`luc_scale` bug** in its
  `by_stream`/`gcb_land_sink` column. Its optimisation went through `ccx_make_logpost()` and
  its seasonal-row conclusions never touch LUC, so its published findings stand — but do not
  copy that idiom. `ccx_forcing_eluc_annual()` reads the forcing's `e_luc` columns, so the
  annual series must be taken **before** the `luc_scale` column multiply.
- **The two `test-fluxes.R` failures (:99, :100) are still failing by design** and still
  awaiting Marcus. 974 pass.
- Everything in handoff 20e §9's trap list still applies.

---

## 10. OPENING THE NEXT SESSION

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-21c_three_closed_app_next.md`. All three items from the
> 2026-08-21 handoff are CLOSED — do not re-open them. **The science is at a natural
> stopping point and §4 ends in a modelling question for Marcus, not more computation.**
>
> **Default next move is §6, the app**: `app/global.R` resolves a parameter file that does
> not exist, so the app ships on uncalibrated defaults and is 14.6 ppm low at 2024 instead of
> 5.8. Fix that, verify the banner and the 21-name guard, and do a timed cold start against
> the shinyapps.io startup limit.
>
> **Then §7b**, which needs two output columns and is otherwise prototyped and specified.
> **Before it ships, check §8** — 40 % of a pulse in the land at year 3000, which no gate
> currently scores.
>
> **Do NOT run the §2 refit** until a soil-damping factor with independent provenance exists;
> if it is far from 0.28 the refit should never run. **Do NOT buy the Takahashi climatology**
> for §4 — the ocean channel's problem is its sign, not its strength.
