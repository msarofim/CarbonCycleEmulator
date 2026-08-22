# Handoff — CarbonCycleEmulator, 2026-08-22: four reviews, three tests, and a redirected priority

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean at `d6adb58`.
**Supersedes:** the *priority* of `handoff_2026-08-21d_app_landed_level_swing.md` §12c. 21d's
§§1–11 stand as provenance; **§12c's "start with the LUC time profile" is withdrawn** — see §3
below, which undercuts it twice with measurements.

---

## 0. STATE IN TEN LINES

1. **A four-expert panel reviewed the model** (carbon cycle, reduced-complexity modelling, code,
   observations). Each read the code, not just the handoff. §1 is the merged ranking.
2. **THE OBJECTIVE CHANGED TODAY.** The ice term now scores against `co2_SH`, not `co2_NH`.
   **Nothing fitted before `d6adb58` is comparable across it.** §2.
3. **The ice term was scored against the wrong hemisphere** — and the diagnostic that produced
   the swing table used the *other* one. Worth +16.9 log-units and 16 % of the swing. §2.
4. **21d TEST 2's mid-century localisation was the smoother.** Raw estimator moves the minimum
   from the 1950s to the 1940s. **The pause is real and 4.7× the noise floor** — the decade was
   wrong, the feature is not. §3a.
5. **The model's growth-rate error tracks GCB's own budget imbalance: r = 0.771, slope 0.781**
   over 11 decades. GCB cannot close its own budget by 20.9 ppm over 1930–69. §3b.
6. **No terrestrial or emissions explanation of the swing survives the isotopes — 12.7 σ.** The
   δ¹³C residual is monotone while the CO₂ residual changes sign. §3c. **This is the session's
   real finding.**
7. **The gate was mutation-tested before its negative was believed** (6.4 se of signal), and the
   mutation corrected the analytic transfer ratio by 2.4×. §3c.
8. **974/976 tests pass** — the same by-design `test-fluxes.R:99,:100` pair.
9. Still no posterior. Nothing here changes that.
10. **Four claims in 21d do not survive contact with the code.** §5.

---

## 1. THE PANEL'S MERGED RANKING

Four reviewers, run independently. Where I verified a claim myself it is marked **[V]**.

| # | defect | cost |
|---|---|---|
| 1 | **[V]** Ice term scored against `co2_NH`; Law Dome is 66.7 °S — **FIXED today**, §2 | 1 line |
| 2 | **[V]** Most of the mid-century swing is GCB's own budget imbalance, not the model, §3b | — |
| 3 | **[V]** §4 GATE E's mechanism is backwards: levels are scored **annually** (126 rows, not 1523 monthly), and the level is *over*-constrained by an ice term whose rows are not independent | half day |
| 4 | **[V]** TEST 2's localisation is a LOESS artefact — **MEASURED today**, §3a | — |
| 5 | `q10` is structurally incapable: 93 % of soil C is in a τ=500 yr pool ⇒ γ_L ≈ −4 GtC/K vs C4MIP −45.1 ± 50.6 | 3 h–3 d |
| 6 | Six of 21 parameters sit 2.4–6.3 σ outside their priors, three of them *measured climatology* (`sst_seas_amp_NH` = 0.47 K vs observed 2.24 K) | 1 d |
| 7 | **[V]** DESIGN gates measured at **defaults**; the app ships the **mode**. `diag_joos_irf.R:97` has no mode path. Gate 12 at the shipped vector has never been measured, against a 6 % TH100 margin | 2 h |
| 8 | **[V]** 65.6 s of the 73 s cold start is one discarded computation (`app/global.R:204-208` → used only at `app/server.R:220`; `ccx_run_fast` does it in 0.05 s) | 1 h |
| 9 | **[V]** The `intersect()` silent-drop mechanism is still live (`R/calibrate.R:615`, `app/global.R:117`); 11 scripts hardcode the never-existed `mode_fit.rds`, 3 degrade silently, 2 print default output under a `POSTERIOR MODE` heading | 3 h |
| 10 | **[V]** Cement carbonation (0.21 GtC/yr) is in the data and absent from the forcing — 0.42 σ of gate 7, free | 1 h |
| 11 | GCB sink terms score one systematic as 66 independent annual draws | half day |
| 12 | `rep_dC`'s N(0, 1.0) prior is mis-**centred**: both stations must read *below* their box means, so the physical expectation is positive, not zero | 1 h + data |

**Not yet acted on and cheap:** #7, #8, #9, #10.

---

## 2. THE ICE TERM WAS SCORED AGAINST THE WRONG BOX — FIXED

`R/likelihood.R` compared the Law Dome record to `co2_NH` on the comment *"SH-cored but globally
well mixed pre-1900"*. **96 of 255 rows are pre-1900; 159 are not, and 52 are post-1958.**
`calibration/diag_co2_level_swing.R:66` already used `co2_SH`, with the comment *"Law Dome is
ANTARCTIC: the like-for-like model series is the SH box."*

**So the objective and the diagnostic that produced 21d §4 GATE D's swing table disagreed about
which model series the same observations should be compared to, and the two were quoted
interchangeably.** `calibration/diag_ice_hemisphere.R` (new) measures it at the arm-N mode:

| gate | result |
|---|---|
| model NH−SH gradient over the scored ice years | +0.32 (1850–1900) → +0.61 (1900–40) → +0.82 (1940–58) → **+1.75 ppm (1958–97)** |
| ice-term logL, `co2_NH` → `co2_SH` | −706.8 → −689.9 = **+16.9 log-units** |
| era swing, NH vs SH | 11.20 → 9.44 ppm ⇒ **1.76 ppm (16 %) was the hemisphere choice** |

Fixed. **This changes the objective; a refit is owed and every arm-file posterior field is now
stale on top of whatever was already stale.** Tests: 974 pass / 2 fail, the same by-design pair.

*(The panel predicted +24.6 log-units. It reproduces as +16.9 when the likelihood's own
`approx(..., rule = 2)` on the sub-annual series is used rather than annual means. The direction
and the conclusion hold; quote 16.9.)*

---

## 3. THE SWING: RE-MEASURED, RE-ATTRIBUTED, AND ISOTOPICALLY CONSTRAINED

### 3a. TEST 2's localisation was the smoother — but the pause is real

`calibration/diag_swing_estimator.R` (new). 21d TEST 2 differentiated a
`loess(CO2ppm ~ year, span = 0.25)` fitted over 1850–1996 — **an effective window of ~36 yr, wider
than the decadal feature it was resolving.** On a raw within-decade OLS with no smoother anywhere:

| decade | 1900s | 1910s | 1920s | 1930s | **1940s** | 1950s | 1960s |
|---|---|---|---|---|---|---|---|
| ice, raw OLS | 0.654 | 0.804 | 0.297 | 0.527 | **0.010** | 0.411 | 0.950 |
| 21d TEST 2 (LOESS) | — | 0.465 | — | 0.279 | 0.376 | **0.207** | 0.523 |

**The minimum moves from the 1950s to the 1940s.** 21d §10's sentence — *"nearly halves in the
1950s (0.376 → 0.207) and then jumps to 0.523"* — is a property of the smoother.

**But it does not weaken the finding, it strengthens it.** Measured against SPO flask (no firn,
no gas age) on the *same* estimator over their overlap, this record's decadal-growth error bar is
**RMS 0.098 ppm/yr**. The raw pause sits 0.459 ppm/yr below its neighbours — **4.7× the noise
floor.** The decade was wrong; the feature is real and better resolved than 21d claimed.

### 3b. The swing largely belongs to GCB, not to the model

GCB 2025 publishes an `imbalance` column its own header calls *"a measure of our imperfect data
and understanding of the contemporary carbon cycle"*. Decadal, GtC/yr:

| 1880s | 1890s | 1900s | 1910s | 1920s | 1930s | **1940s** | **1950s** | 1960s | 1970s |
|---|---|---|---|---|---|---|---|---|---|
| −0.23 | −0.13 | +0.19 | +0.14 | +0.45 | +0.58 | **+1.30** | **+1.62** | +0.93 | +0.46 |

Regressing the model's growth-rate error on it, **on the raw estimator** (the LOESS version gave
r = 0.839 / slope 0.486, so the finding survives the estimator that produced it):

> **r = 0.771, slope 0.781, intercept −0.504, over 11 decades.**

**Cumulative GCB imbalance 1930–1969 = +44.3 GtC = +20.9 ppm**, against a model residual swing of
~9 ppm. **The modern (2015–24) imbalance is +0.016 GtC/yr** — so this explains the mid-century
half well and the **land-sink miss not at all**. That remains a genuine partition error.

**Consequence for gate 7.** Gate 7 asks the model to match GCB's sinks *and* the CO₂ record from
GCB's emissions. Those cannot be satisfied together, by exactly `B_IM + S_CEM`. **Gate 7 as
written may be unreachable by construction and needs restating before it is used to rank
anything.** (Note also the panel flagged a ~0.69 GtC/yr closure gap between gate 7's σ's and the
CO₂ trajectory that it could not reconcile — **unresolved, ~30 min to check, and §6's ranking in
21d rests on those numbers.**)

### 3c. THE ISOTOPES REJECT A TERRESTRIAL SOURCE AT 12.7 σ — the session's real finding

`calibration/diag_d13c_midcentury.R` (new). **105 Law Dome δ¹³C samples, 37 of them in 1900–1960,
stated errors 0.01–0.19 ‰, sitting on disk and NOT in the objective** — the only δ¹³C levels
scored start in 1978.

The candidate causes carry different signatures: emissions error ≈ −25 to −28 ‰; land sink ≈ −18 ‰;
ocean sink ≈ −2 ‰ (and isotopically slow); a firn/sampling artefact preserves the ratio, because
firn diffusion is near species-independent.

**GATE 1 — the two residuals are decoupled.**

| window | 1860–1900 | 1900–20 | 1920–40 | 1940–60 | 1960–80 | 1980–94 |
|---|---|---|---|---|---|---|
| CO₂ residual, ppm | −2.18 | −4.38 | −3.99 | −0.77 | **+4.22** | **+4.76** |
| δ¹³C residual, ‰ | −0.030 | −0.062 | −0.070 | −0.122 | −0.171 | −0.160 |

**The CO₂ residual changes sign. The δ¹³C residual is monotone.**

**GATE 5 — the gate was mutation-tested before its negative was believed.** Injecting the LUC
pulse a terrestrial explanation needs (×1.60 over 1930–65 = **+33.1 GtC**) moves δ¹³C by **6.4 se**
in the test window. The instrument is **LIVE**. It also measured the transfer ratio at
**−0.0239 ‰/ppm where closed-box mass balance gives −0.0571** — a factor of 2.4, because air–sea
isotopic exchange damps the δ¹³C perturbation faster than the CO₂ one. **GATE 4's σ's are inflated
by that factor; GATE 6 supersedes them.**

**GATE 6 — the verdict, on the measured ratio.**

> CO₂ residual change to explain: **+8.74 ppm** → a terrestrial/LUC explanation **requires
> −0.209 ‰** of δ¹³C excursion. Observed: **−0.003 ± 0.016 ‰**. **12.7 σ.**

**CAVEAT, and it must ride with the number.** This assumes the model's δ¹³C is a fair probe.
Memory `ccx_d13c_suess` records the δ¹³C Suess overshoot as **structural**, and the monotone
−0.0014 ‰/yr drift in GATE 4 is very likely it. A real signal could in principle be cancelled by
that bias — but the bias is linear in time and the signal would have to be equal, opposite and
localised. Not generic, and testable against an independent δ¹³C product.

**Read it as:** *no terrestrial or emissions explanation of the swing survives the isotopes* —
**not** as "the swing is not carbon".

**GATE 2 is confounded and marked not-to-quote in the file:** its ratio statistic divides by a CO₂
residual that passes through zero inside the test window, so its "+5.70 sd" is a denominator
artefact.

---

## 4. WHAT THIS DOES TO §12c

21d §12c closed three doors and left one open: *"the land-use inventory's TIME PROFILE — start
there, and ask what E_LUC(t) SHAPE the CO₂ record wants."* **That is now undercut twice:**

1. **The shape it would be fitted to is largely GCB's own imbalance** (§3b, r = 0.771), which is
   already on disk and does not need deconvolving out of the CO₂ record.
2. **The isotopes reject a terrestrial source for the swing at 12.7 σ** (§3c). Fitting an E_LUC
   shape to it would be fitting an emissions shape to something the isotopes say is not emissions.

And the framing itself is the `rep_dC` trap one level up: **a free *function* where `rep_dC` was a
free constant**, in a model with six parameters 2.4–6.3 σ outside their priors and no discrepancy
term. It would absorb the ocean's IRF deficit and the ice term's mis-specified covariance and
return something that looks like a discovery.

**Do not start it on the current rationale.** If it is ever started, it must be a 2-parameter
pre-registered perturbation (mid-century shift + amplitude), bounded by the published
bookkeeping-model spread, scored against gate 4's decadal airborne-fraction variability rather
than the level.

---

## 5. WHAT IN 21d DOES NOT SURVIVE

1. **§4 GATE E's "1523 monthly station points at σ ≈ 1 ppm".** **[V]** `R/likelihood.R:1090-1101`
   scores `obs$co2_ann` — **annual** harmonic-reduced rows, 126 of them. The 1523 is the raw
   monthly count, compared against the ice term's *inverse-variance sum* (14.33) — a count against
   a precision. Like-for-like it is ~9–14 : 1, not ~100 : 1.
2. **§4's "the absolute level is effectively unconstrained post-1958" is closer to backwards.**
   With `rep_dC` free, the level is held by the ice term at a nominal ±0.26 ppm. It is *nominally
   over-constrained* by a term whose 255 rows share a site, a gas-age scale and a firn transfer
   function and are scored as independent. **The conclusion survives; the remedy is the ice
   covariance, not the `rep_dC` prior.** §4a's decision not to touch the prior was right for a
   reason that does not hold.
3. **§12a's "Reason 1 — the observable points the WRONG WAY" is void.** With `gamma_enso` free at
   N(0,2) and 17× the leverage (Reason 2), the γ_IAV row carries no `q10` information in *either*
   direction. Reason 2 kills Reason 1; presenting them as independent double-counts one
   measurement.
4. **§12b's corollary should not go in the app.** 6528 is the **permissive edge** of the deep-Δ¹⁴C
   bracket, and §12b's own measurement 2 says the ¹⁴C term *prefers lower* `kz`. As written it
   would tell a reader two observables concur when the CO₂ record outvoted the ¹⁴C one by two
   orders of magnitude.
5. **§5's 91.4 GtC is not a defect.** It is 0.34 GtC/yr against GCB's own **±0.7 GtC/yr** stated
   1 σ (quoted at `R/likelihood.R:288`) — half of one sigma, with four named accounting reasons
   for divergence. The app has a presentation problem; the science does not have a 91 GtC problem.
   **The fix is an anomaly splice, not a rescale.**
6. **§11 TEST D should not be read as "the LUC input improves".** It cuts the mid-century error
   because it is *lower* mid-century, and costs 14 ppm at 2024. That is adopting an accounting
   convention.

**The pattern:** none of these were gated against anything, which is the same failure mode as
21c §6. **The structural fix is a provenance stamp on every saved fit plus golden snapshots for
the ~8 diagnostics that get quoted into handoffs** (all four checked run in 4–6 s and take no
arguments).

---

## 6. NON-OBVIOUS STATE

- **`R/likelihood.R`'s ice block now reads `co2_SH`.** Every logL, every `by_stream`, every
  evidence margin from before `d6adb58` is on the old objective.
- `diag_ice_hemisphere.R` reproduces the likelihood's `approx(..., rule = 2)` on the **raw
  sub-annual** series deliberately — the annual-mean version gives a different number.
- `diag_d13c_midcentury.R` **GATE 2 must not be quoted** (confounded denominator); **GATE 4's
  σ's must not be quoted** (superseded by GATE 6's measured ratio). Both are marked in the file.
- The δ¹³C samples are keyed on **`age_CO2`**, not a `year` column, and `age_ice` is a character
  column containing `"firn"` — coercing the wrong one gives an empty series silently.
- `gcb_budget.rds` has **two** elements: `$budget` (1959+) and `$historical` (1750+, and the only
  one with pre-1959 `imbalance`). Reading the wrong one returns NA for every pre-1959 decade.
- Everything in 21d §8 and 20e §9's trap list still applies.

---

## 7. OPENING THE NEXT SESSION

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

> Read `notes/handoff_2026-08-22_panel_and_three_tests.md`. **The objective changed on
> 2026-08-22** (ice → `co2_SH`); nothing fitted earlier is comparable. **Do NOT start the §12c
> LUC time-profile programme** — §4 here undercuts it twice.
>
> **The open scientific question is now narrower and better posed than 21d's:** a mid-century CO₂
> growth-rate pause that is real (4.7× its own noise floor), correlates with GCB's published
> budget imbalance at r = 0.77, and carries **no isotopic signature** — 12.7 σ against a
> terrestrial or emissions source. That combination points at the ocean, at a CO₂-only record
> artefact, or at compensating errors, and §3c's caveat names the one way the isotope test could
> be wrong.
>
> **Cheapest unstarted items, all measured and all under a day:** gates 4/5/7/12 **at the shipped
> mode** (`diag_joos_irf.R:97` is hardcoded to defaults; gate 12 could be failing); the gate-7
> closure check (~0.69 GtC/yr unreconciled); subtract cement carbonation (0.42 σ, free); the app's
> 65.6 s startup (1 h, and it is the launch blocker); the ice covariance
> `diag + s²11ᵀ` profile of `rep_dC`.
>
> **The app decisions are still Marcus's:** the `rep_dC` display question (21d §4a) and the
> tab-1/tab-5 step — which §5 here reframes as an anomaly-splice presentation fix, not a 91 GtC
> defect.
