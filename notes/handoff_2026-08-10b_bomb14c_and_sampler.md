# Handoff — CarbonCycleEmulator, 2026-08-10 (session B)

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `main`.
Supersedes parts of `handoff_2026-08-10_calibration.md` — read this one after it.
Test suite: **174 pass / 0 fail / 2 skip** (`Rscript tests/run_tests.R`; the 2 skips are
seacarb, not installed). The earlier note's "177 passing" was already stale — I verified
174/0/2 on the pre-session HEAD as well, so nothing regressed.

---

## 1. Headline

Two things happened, and the second one is more important than the first.

1. **The bomb ¹⁴C shape gap is CLOSED**, without UNSCEAR. It was a physics error, not a
   missing citation. Details in §2; full derivation in **DATA.md §9**.
2. **The posterior is pathological, and the previous handoff's diagnosis was wrong.**
   It said the failed pilot was "a too-short-chain and bad-starting-point problem, not
   evidence of a broken posterior." It is evidence of a broken posterior. Details in §4.
   **Do not launch a production MCMC run until §4 is resolved.**

---

## 2. Bomb ¹⁴C: delivery, not production

Marcus supplied two references. Neither is the UNSCEAR 2000 Annex C yield table that
DATA.md §8 said was needed, and it turned out not to be needed at all.

**The error.** `R/model.R` gives each hemisphere one well-mixed troposphere and **no
stratospheric box**, so `forc$c14_bomb` is a stratosphere→troposphere **delivery** rate.
The placeholder was shaped like **production** — 54.0 % of all bomb ¹⁴C in 1961–62, 2.2 %
in 1963 — delivering the big test series with no stratospheric residence. Telegadas'
measurements say 56–60 % of the Naegler & Levin total was still *in the stratosphere* in
Dec 62 – Feb 63.

**Sources** (both extract cleanly with `pdftotext -layout`; no figure digitising):

| Reference | Role |
|---|---|
| **Tans 1981**, SCOPE 16 pp. 131–157, Tables 1–2 | **The source function.** Tans p.133: input to the troposphere = the stratospheric decrease. Transcribed to `data-raw/manual/tans1981_scope16_table{1,2}_*.csv` |
| **Graven et al. 2017**, GMD 10:4405 | **Not** a bomb source — an observation product, coarser than the Hua et al. 2022 record already in `obs_d14c_zonal.rds`. Kept as a δ¹³C cross-check back to 1850 |

**Method** (Marcus's rule): *inventory data set the TOTALS; observed concentration supplies
the SUB-ANNUAL PATTERN only where no sub-annual inventory exists.* Annual totals from
Table 2's stratospheric decrease (1963+) and from budget closure before that — what was
still aloft at 1963.04 subtracted from the Naegler & Levin total gives 35 % delivered
pre-1963, **with no test-yield inventory at all**. Within-year shape from
`g(t) = dN14/dt + λ·N14` on observed monthly Δ¹⁴C, smoothed 5 months.
λ is solved in closed form from the budget (0.1996/yr) and checked **independently**
against gross air-sea exchange from Tans' own 19 mol/m²/yr (0.1495/yr → ocean 75 %).

**Result** (uncalibrated defaults, vs area-weighted hemispheric obs, 1962–1972):

| Bomb source | debiased sd NH | corr NH |
|---|---|---|
| Measured input function (current) | **34.5 ‰** | **0.970** |
| Two-exponential fit (intermediate, superseded) | 48.0 ‰ | 0.951 |
| Placeholder (superseded) | 233.4 ‰ | **0.121** |

`LIK_USE_BOMB_WINDOW` is now **TRUE** (it was FALSE only because the shape was a
placeholder carrying 90 % of the likelihood information).

### Two traps worth not repeating

- **Table 2's quarterly resolution is illusory.** Quarter-on-quarter releases are
  `7, 48, 29, 17, 30, 42, 13, 0, 14, 5, 7, −2, 15, 3` units against ~3-figure reporting.
  The `0` is because "170" is printed twice in succession; it produced **three months of
  exactly zero delivery**. Use annual sums (101 / 85 / 24). The one real sub-annual signal
  that survives is an **Apr–Jul maximum in both 1963 and 1964** — the spring stratospheric
  intrusion, which a smooth two-exponential fit destroys.
- **Do not score on peak timing.** The observed NH aggregate is **double-peaked**
  (850.3 ‰ @1963.625, dip to 741.9, 832.6 @1964.625; maxima 2 % apart), so `which.max()`
  flips lobes and manufactures a "+0.92 yr timing error" that no parameter can move. I
  chased it first as the zero-delivery notch — wrong; removing the notch didn't move the
  peak. Use debiased sd + correlation. Also **do not gate `d14c_NH` on the Hua Zone-1
  numbers** in DESIGN §6 — the model has one hemispheric box; the comparable benchmark is
  **NH 853.2 ‰ @1963.708, SH 659.4 ‰ @1965.042** via `ccx_zone_weights()`.

### Open caveats on the shape

- Sub-annual pattern comes from the record the likelihood scores against. Annual and longer
  timescales stay independent (those totals are Tans'), but the bomb window is **not** a
  fully independent test of within-year ocean exchange.
- A **−118 ‰ mean bias** survives at uncalibrated defaults — a level, not a shape.
- Part A/B join step is down 4.5× → 1.6× and the remainder is defensible as real spring
  acceleration.
- Tans' own caveats carry over (aircraft calibration possibly ~20 % high; the Dec 62–Feb 63
  point is a floor and is raised, not dropped; post-1963 French/Chinese tests uncaptured).

---

## 3. What now works in the calibration machinery

- **Mode-finding works.** `calibration/run_modefind.R` — Nelder-Mead restarts + BFGS
  polish. On the pre-bomb-window likelihood it gained **+81,718 log-units** and beat the
  original pilot's best (−6469) **on its first restart**, confirming that pilot never left
  burn-in. On the final likelihood: init −84,837.5 → mode **−8,736.6**, 103 min,
  135,585 evaluations at 0.046 s/eval. Output `calibration/output/mode_fit_bombwin.rds`.
- **`calibration/recompute_hessian.R`** — redoes the Hessian at an existing mode with a
  step-size sweep, so the covariance is never trusted without checking curvature stability.
- **`calibration/run_repilot.R`** — pilot restarted from the mode with a Hessian-scaled
  (full covariance) proposal. `adaptMCMC::MCMC` accepts a covariance matrix for `scale`;
  verified empirically, not just from the docs.

**Fixed bug:** `MODE_HESS_EPS` was `1e-3`, far too large — it produced a non-PD Hessian
with entries like −5.4e61. At the mode, stepping `log(kz)` by 1e-3 costs 49,000 log-units
and by 1e-2 leaves the feasible region; the true second derivative at 1e-4 is −41.3. Now
`3e-4`, and `run_modefind.R`'s condition-number print was taking `max/min` of negative
eigenvalues instead of `max|λ|/min|λ|`.

**The suspected ridge was refuted.** The previous handoff guessed `k_w`/`h_ml`/`kz` were
correlated. With a valid Hessian the strongest correlations are **`beta`↔`q10` (r = +0.817)**
and **`k_w`↔`bomb_total` (r = +0.813)**. Condition number ~2.4e6 — badly conditioned, but
not where expected. `h_ml` is the least-constrained parameter (unconstrained sd 1.36 vs
0.0033 for `bomb_total`).

---

## 4. THE BLOCKER: the mode sits on a numerical-stability wall

**Do not run production MCMC until this is resolved.** The re-pilot came back
acceptance `0.000, 0.000, 0.205, 0.187`; worst R̂ **9.672** (pilot 4.53), min ESS 3.
Chains 3 and 4 were near the 0.234 target; chains 1 and 2 never moved at all.

Diagnosis, in order:

1. **All four chains start at `lp = -Inf`** — even at 0.5 posterior-sd dispersion, not just
   the 2.0 sd the script used.
2. The mode's `kz = 175,790` is within **~1 %** of a hard feasibility boundary, while its
   posterior sd is ~20 %. Chains 3 and 4 got acceptance ~0.2 only because from `-Inf` the
   first finite proposal is always accepted, so they wandered back into feasible space;
   1 and 2 never did.
3. **The `-Inf` is solver failure, not zero probability.** The spinup is fine throughout
   (`prod_c14` ≈ 333 at every `kz` tested). It is `ccx_run_fast()` that returns NAs in
   `co2_NH` above **kz ≈ 177,000**, which `ccx_make_logpost()` converts to `-Inf` via its
   `anyNA` guard. Almost certainly a diffusion stability limit at `substeps = 4L`.

**So the optimiser maximised into a numerical wall.** The likelihood wants even faster
ocean mixing and was stopped by the integrator, not by the data or the prior.

### The mode is not physically credible

| param | mode | prior | distance |
|---|---|---|---|
| `q10` | **0.280** | lnorm(log 2, 0.25) | **−7.9σ** — and Q10 < 1 means respiration *falls* with warming |
| `kz` | 175,790 | lnorm(log 4000, 0.6) | +6.3σ, at the solver wall |
| `sigma_co2` | 0.0744 ppm | lnorm(log 1.5, 0.7) | −4.3σ |
| `sigma_d13c` | 0.00706 ‰ | lnorm(log 0.1, 0.7) | far low |
| `k_w` | 273 | lnorm(log 1500, 0.4) | −4.3σ |
| `rho` | **0.998063** | bounded [0, 0.999] | railed at the bound |

### Probable root cause: the AR(1) error model

`ccx_ll_ar1()` (`R/likelihood.R:136`) uses the exact AR(1) likelihood. As `rho`→1 the
innovation becomes `(r_t − r_{t−1})/sd`, so the optimal `sd` collapses to the RMS of the
residual **increments** rather than the residual level. For a smooth model against a smooth
observation series that is tiny — hence `sigma_co2` = 0.074 ppm. Profiles (others held at
the mode) confirm both are genuine interior maxima, not runaway:

- `rho`: 0.90 → −12,653; 0.99 → −8,778; **0.998 → −8,736.6**; 0.9989 → −8,740.
  A **3,916 log-unit** preference for near-unit-root autocorrelation.
- `sigma_co2`: 0.05 → −8,737.5; **0.0744 → −8,736.6**; 0.5 → −8,852; 1.5 → −9,471.

Net effect: the AR(1) term absorbs systematic model–data mismatch as "correlated noise",
removing the penalty on bias, so the physics parameters are free to drift into deep prior
tails and `kz` runs to the solver wall. This is also the most likely reason the −118 ‰
Δ¹⁴C bias survives untouched.

---

## 5. Suggested order for the next session

1. **Find the solver's actual stability limit** and either raise `substeps`, make the
   diffusion step implicit, or bound `kz`'s prior below the limit. An `-Inf` that means
   "the integrator broke" must not be doing duty as a prior bound — right now the posterior
   is silently truncated by numerics.
2. **Fix the AR(1) pathology.** Options: cap `rho` well below 1 (say 0.95); put an
   informative prior on `sigma_*` from the actual measurement precision rather than a wide
   lognormal; or drop AR(1) in favour of an explicit representation-error term. This is a
   methodological choice — flag it for Marcus rather than picking one.
3. Re-run `run_modefind.R` → `recompute_hessian.R` → `run_repilot.R` and check `q10`
   returns to a physical value.
4. Only then production: 50k × 4, gate on **R̂ < 1.05 AND ESS ≥ 400**.
5. Separately, the **−118 ‰ bomb-window bias** — worth checking whether it is absorbed once
   the error model is fixed, since a bias-blind likelihood cannot currently penalise it.

Also still open from the previous handoff: 7 provisional constants (and the
`SST_PCO2_SENSITIVITY` double-counting check), the optional GLODAP ocean bomb-¹⁴C
inventory constraint, and the Shiny app.

---

## 6. Commits this session

| | |
|---|---|
| `262694c` | Bomb ¹⁴C source: replace production-shaped placeholder with Tans 1981 measured delivery |
| `1fab425` | Admit the bomb window to the likelihood; fix the DESIGN §6 comparison basis |
| `68eb7d0` | Sub-annual bomb shape from observed Δ¹⁴C; drop illusory quarterly resolution |

Stale outputs: `calibration/output/pilot_fit.rds` (original pilot, superseded),
`mode_fit.rds` + `modefind.log` (pre-bomb-window likelihood, kept only as the "before"
reference), `repilot_fit.rds` (the run diagnosed in §4 — its chains 1–2 never moved).
`mode_fit_bombwin.rds` carries the corrected Hessian from `recompute_hessian.R`.
