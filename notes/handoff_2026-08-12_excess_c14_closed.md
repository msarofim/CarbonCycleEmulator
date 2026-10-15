# Handoff — CarbonCycleEmulator, 2026-08-12

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, branch `main`.
Supersedes `handoff_2026-08-11_blockers_app_and_c14.md`, whose §7 step 1 is now **closed**.
Test suite: **384 pass / 0 fail / 2 skip** (`Rscript tests/run_tests.R`; the 2 skips are
seacarb, not installed). Was 371/0/2.

---

## 1. Headline

Step 1 of the previous handoff — put the ocean excess-¹⁴C inventory into the likelihood — is
**done, and the answer is a negative result that is worth more than a positive one would have
been.**

1. **The constraint is live and costs nothing.** `excess_c14_ocean` scores the model's ocean
   excess ¹⁴C at 1975 and 1995. Posterior evaluation is still **0.046 s**. §2.
2. **It does not move `bomb_total`: 151.2 → 149.8.** The fit *pays* the penalty rather than give
   up any atmospheric fit. §3.
3. **No admissible setting of it ever could.** Profiled across `bomb_total` and both published
   target sets: the constraint clears the bar in exactly one corner, and that corner buys the
   ocean inventory at 190 ‰ of atmospheric misfit. §4.
4. **A ¹⁴C source nobody declared:** land-use-change emissions inject ~28 kmol of ¹⁴C ex nihilo,
   14–16 % of the system excess. Found by checking the budget closes, not by looking for it.
   **Not fixed — it is a modeling decision.** §5.
5. **Production MCMC is still not launched**, for the same reason as before, now better
   evidenced: two independent ¹⁴C constraints indict the same structural defect. §7.

**The ¹⁴C problem is not underdetermination. It is contradiction.** The model cannot match the
atmospheric Δ¹⁴C decline and the observed ocean inventory together at *any* `bomb_total`. That
is the ocean-side twin of what 2026-08-11 §6.4(c) found from the atmospheric side (it cannot
match the observed Δ¹⁴C curve at any `bomb_total` either). Neither is a parameter problem.

---

## 2. The constraint

`data-raw/manual/naegler_levin_2006_budget.csv` → parsed by `build_calibration_data.R` §8 →
`data/obs_excess_c14.rds` → `ccx_loglik()`'s `excess_c14_ocean`. Design note 5 in
`R/likelihood.R` carries the reasoning; `calibration/diag_excess_c14.R` reproduces every number
it cites. Both cores now emit `ocean_C14` / `land_C14` / `atm_C14` in state units (kmol is the
likelihood's business, not the core's), under `test-parity.R`.

**Three definition questions, all measured rather than assumed.** This is the part worth
re-reading before touching the term:

**(a) The natural baseline is free.** The run's first row *is* the 1750 steady state by
construction, so no counterfactual run is needed. Measured against the expensive alternative — a
full no-fossil/no-LUC/no-bomb/no-nuclear counterfactual carrying the observed GMST and ENSO — the
two differ by **0.27 kmol (1975) and 0.58 (1995)**, under 1 % of the excess against a ~16 kmol
observational spread. Removing the climate forcing too reproduces the spinup state to 0.003 kmol.

**(b) Bomb-only vs total-minus-natural does not matter for the ocean.** N&L's Table 4 model
partition sums *exactly* to their cumulative bomb input at both years, so theirs is a paired
difference; the observational estimates are not. For the ocean: paired 72.6 / 94.3 kmol against
total-minus-natural 75.9 / 95.4 — a 1–4 % gap. **For the land it matters enormously** (§5).

**(c) The units were checked before the term was trusted.** The troposphere is the only row where
N&L's number and ours meet with no model in between. Rebuilding the *atmospheric* excess from the
CO₂ and Δ¹⁴C observations alone gives **37.3 kmol (1975) and 25.6 (1995)** against their
troposphere+stratosphere **35.6 and 21.7**: **+4.8 % and +18.0 %**. That measured spread sets
`LIK_EXCESS_C14_REP_FRAC = 0.15`, carried as a **rank-one shared method bias** across the two
years, not per-year quadrature — two estimates from overlapping reconstructions do not carry
twice the information.

The term **refuses to score** rather than mis-baseline if a run does not start at
`LIK_EXCESS_C14_BASE_YEAR`, and `test-likelihood.R` asserts it *is* scored under the standard
pipeline. A constraint that silently skips itself is worse than one that is absent.

---

## 3. The recalibration

Mode-find against the new posterior: **118.8 min, 151,536 evals at 0.047 s/eval, −26,005.8 →
−2,374.1.** `calibration/output/mode_fit.rds`.

| | pre-constraint | post-constraint |
|---|---|---|
| `bomb_total` | 151.25 (+4.60σ) | **149.81 (+4.54σ)** |
| `k_w` / `kz` / `h_ml` | 2950 / 8354 / 37.7 | 2921 / 8267 / 37.3 |
| `q10` | 4.143 (+3.41σ) | 4.093 |
| `sigma_d14c` | 45.84 (+3.01σ) | 45.86 |
| ocean excess ¹⁴C @1975 / @1995 | 76.9 / 95.7 | **75.8 / 94.3** kmol |
| MLO CO₂ annual rms | 0.986 ppm | 0.983 |
| bomb-window Δ¹⁴C rms | 69.1 ‰ | 67.9 |
| Hessian condition number | 8.29e4 | 7.69e4 (PD) |

**Every parameter moved ~1 %.** The same three flags fire. `excess_c14_ocean` sits at **−14.55**
at the mode, missing targets of 48.6 ± 7.9 and 51.4 ± 7.6 by **+27 and +43 kmol** — and the fit
takes that rather than concede anything atmospheric.

---

## 4. Why no setting of the constraint can win

`calibration/profile_bomb_total.R` (91.7 min): `bomb_total` ∈ {102, 120, 135, 150, 165} kmol with
every other parameter re-optimized at each point, under **both** target sets.

| `bomb_total` | logpost | ocean term | ocean excess 1975/1995 | bomb-win Δ¹⁴C rms | CO₂ rms |
|---|---|---|---|---|---|
| 102 | −2483.1 | −7.21 | 52.7 / 64.4 | **190.6 ‰** | 0.98 |
| 120 | −2433.7 | −8.93 | 60.8 / 75.4 | 119.9 | 0.99 |
| 135 | −2393.0 | −11.24 | 67.8 / 84.7 | 74.7 | 0.99 |
| **150** | **−2374.1** | −14.60 | 75.9 / 94.4 | **68.1** | 0.98 |
| 165 | −2393.4 | −19.07 | 85.0 / 104.3 | 90.6 | 0.96 |

`table2_peacock` is within 1.3 log-units at every point, and **both target sets choose 150**.

**A framing error worth not repeating.** The target-set choice was flagged as worth ~130
log-units. That estimate assumed **per-year quadrature**, which the term does not use. The model
overshoots *both* years in the same direction — exactly the direction a common method bias is
allowed to explain — so once the shared error is modeled as the rank-one term it actually is,
the two sets differ by **0.7 log-units**. The lesson generalizes: when observations share a
method, whether their error is modeled as independent or as a common bias changes the leverage
by more than an order of magnitude, and the *sign of the residuals* tells you which regime you
are in before you compute anything.

`calibration/diag_excess_c14_leverage.R` locates the real lever. Bar to clear: **116.4
log-units** (what the rest of the likelihood pays to move 150 → 102, almost all of it the bomb
window at 68.1 → 190.6 ‰).

| `LIK_EXCESS_C14_REP_FRAC` | `table4_obs_range` | `table2_peacock` |
|---|---|---|
| 0.00 | 20.4 | **135.4** ← the only corner that clears |
| 0.02 | 19.7 | 108.7 |
| 0.05 | 16.9 | 53.3 |
| 0.10 | 11.3 | 18.9 |
| **0.15 (in use)** | **7.4** | 9.1 |
| 0.20 | 5.1 | 5.3 |

Even 2 % of shared bias closes the one corner that clears. And what that corner buys is not a
model that fits both — it is the ocean inventory purchased at 190 ‰ of atmospheric bomb-window
misfit. **Choosing it would be choosing which observation to disbelieve.**

---

## 5. THE OPEN DEFECT: land-use-change emissions inject ¹⁴C ex nihilo

Found while validating the definition, not by looking for it. Excess ¹⁴C can only come from the
prescribed sources minus decay, so the reservoir excesses must sum to the cumulative bomb input.
N&L's do, exactly. **Ours do not.** From `dE/dt = sources − λE`, assuming nothing about where the
extra comes from:

| | excess | declared | decay | **undeclared** |
|---|---|---|---|---|
| 1975 | 167.85 | 144.38 | −0.45 | **+23.93 kmol (14.3 %)** |
| 1995 | 178.84 | 151.45 | −0.88 | **+28.27 kmol (15.8 %)** |

**Cause, `R/model.R:226`:** LUC is emitted with `add_source()` at the **vegetation box's own ¹⁴C
ratio** while the vegetation box is never debited. 273 GtC of LUC carbon at a land Δ¹⁴C of
+221 ‰ is a real ¹⁴C source. Fossil carbon is emitted at Δ¹⁴C = −1000 and correctly carries none.
Two independent estimates agree to ~1 %: the closure residual above, and integrating the LUC flux
against the run's own vegetation ratio (24.0 / 27.9 kmol).

**NOT FIXED — this is a modeling decision for Marcus.** The case that it is a bug: the ¹⁴C
leaving a cleared forest was taken up from the atmosphere earlier and is already inside the bomb
budget, so injecting it again double-counts, and the model's own veg/soil pools have separately
absorbed their share. The case that it is defensible: LUC is exogenous to two *responsive* pools,
the deforested stock is genuinely outside the model, and its carbon does carry real ¹⁴C.

**Whichever way it goes, the ¹⁴C budget cannot close while the deforested pool is unrepresented.**
The two ends of the choice are (i) leave it, and never compare a summed inventory to N&L again
without saying so, or (ii) emit LUC at the *preindustrial* vegetation ratio, or as a debit from
the veg box, so no post-bomb ¹⁴C enters.

**What it does and does not contaminate:**

- **Ocean: barely.** Paired vs total differ 1–4 %. The new constraint stands.
- **Land: a lot — and this CORRECTS 2026-08-11 §6.4(e).** At the citable 102 kmol our land excess
  is 43.8 kmol total-minus-natural but **29.6 kmol paired**, against N&L's 18.9. **"Our land
  holds 2–3× their biosphere" becomes ~1.6×.** Still high, still consistent with the `tau_veg`
  tension, but not the gap it looked like — and step 3 below lands directly on top of this.

---

## 6. Two decisions waiting on Marcus

**(i) The LUC ¹⁴C injection** (§5). Bug or acceptable consequence? Blocks nothing, but step 3
(`tau_veg`) sits directly on it: freeing `tau_veg` against a land ¹⁴C inventory that is ~40 %
undeclared source would calibrate a pool turnover to absorb a bookkeeping artifact.

**(ii) `LIK_EXCESS_C14_REP_FRAC = 0.15`** (§2c). Measured from a +4.8 % / +18.0 % spread, but
only two comparisons stand behind it and one of them is against N&L's *modelled* stratosphere.
§4's table is the full sensitivity: nothing about the conclusions changes anywhere in
0.02 ≤ rep_frac ≤ 0.20 with the default target set.

Neither was resolved unilaterally; both are flagged in `CHANGELOG.md` 2026-08-11 (night).

---

## 7. What to do next, in order

Steps renumbered from the previous handoff's §7, with step 1 struck out.

1. ~~Add the ocean excess-¹⁴C inventory to the likelihood~~ **DONE. It does not resolve
   `bomb_total`, and §4 proves nothing about how it is specified could.**
2. **Re-open the bomb delivery SHAPE. This is now the highest-value work by a wide margin.**
   Start at the **Part A / Part B join at 1963.04**, where a 4.5× one-month step survives
   (2026-08-10, still unresolved). Two independent constraints now say the source's time-shape is
   wrong: the model overshoots the observed 853 ‰ NH peak by 108 ‰ at its fitted total and
   undershoots by 215 ‰ at the correct one (§6.4(c) of the previous handoff), and it overshoots
   the ocean inventory by 46–83 % at the total it prefers (§3 here). A wrong *amount* cannot
   produce both.
3. **Free `tau_veg`** into `CCX_PARAM_TABLE` — but **settle decision 6(i) first**, or the
   calibration absorbs the LUC artifact. It is fixed at 10 yr, is not calibrated, and trades CO₂
   against ¹⁴C directly (3 yr: bomb rms 59.5 but CO₂ rms 11.98; 10 yr: 69.1 and 0.99). Consider
   also whether the two-pool land survives at all: no (`tau_veg`, `tau_soil`) keeps both the CO₂
   fit and a defensible land ¹⁴C inventory. N&L's biosphere has four pools and 2200 PgC; a third,
   fast pool is the obvious minimal change.
4. **Decide on the ocean structure.** 2026-08-11 §6.4(b) confirmed one `kz` cannot serve both the
   decadal bomb transient and the millennial deep age; the deep ocean is ~600 yr too young
   (−105 ‰ against an observed −150 to −200). Options: an explicit advective overturning loop
   (DESIGN §10 v2 backlog) or a second ventilation timescale. **Design decision for Marcus.**
5. **Address the ocean carbon inventory** — the biological pump, or at minimum a prescribed
   DIC-vs-depth profile. Model ocean carbon is 32,827 GtC against an observed ~38,000, DIC is
   *exactly uniform* with depth (surface/deep ratio 1.000, forced by the zero-flux spinup
   condition of pure diffusion), and ¹⁴C production solves to 382 mol/yr against the canonical
   ~545 — a ceiling of 416 even at Δ¹⁴C = 0 everywhere. Watch whether production moves toward
   545. Also touches the provisional `OCEAN_DEPTH` / `ALK_SURFACE` constants.
6. **Only then** the GPP / autotrophic-respiration loop, if a shape misfit survives.
7. **Then** production MCMC: 50k × 4, gate on **R̂ < 1.05 AND ESS ≥ 400**. At 0.047 s/eval that
   is ~2.6 h. The app picks up `calibration/output/posterior_draws.rds` automatically and
   switches its banner to "calibrated posterior".

---

## 8. Non-obvious state

- **Two quarantine directories now**, and they are not equivalent:
  - `calibration/output/quarantine/20260811_ar1_pathology_and_solver_wall/` — genuinely wrong
    results, **18** parameters against the current 17.
  - `calibration/output/quarantine/20260811b_pre_excess_c14/` — **more dangerous, because it
    looks current.** Same 17 parameters, same model, same integrator. Its `par_mode` is a fine
    starting point; its **`logpost` −2359.3 must not be quoted** (that vector scores −2378.6 under
    the current posterior) and its Hessian is of the old posterior.
- `data/obs_excess_c14.rds` holds **both** candidate target sets; `LIK_EXCESS_C14_TARGET` picks by
  name. Regenerate with `Rscript data-raw/build_calibration_data.R` (needs `data-raw/downloads/`,
  which is gitignored but reproducible via `download_data.R`).
- The N&L PDF is at
  `~/Documents/2026/ClaudeDocs/Papers/Journal of Geophysical Research  Atmospheres - 2006 - Naegler - Closing the global radiocarbon budget 1945 2005.pdf`
  — check there before hitting a paywall. `pdftotext -layout` works on it.
- Hand-transcribed manual CSVs carry their citation as a leading `#` block, so they are read with
  `read.csv(comment.char = "#")`, **not** `fread` (which cannot skip it and fails confusingly).
- `ccx_run()` (the R reference) requires `p$gamma_enso` to be set; `ccx_default_params()` does not
  set it, and the failure is an opaque `argument is of length zero` inside `add_flux`.
  `ccx_run_fast()` defaults it to 0 in `ccx_cpp_par()`. Pre-existing; not a regression.
- `calibration/output/profile_bomb_total.rds` holds the full profile including per-point
  parameter vectors, so §4 can be re-analysed without re-running the 92 min.
- Everything from 2026-08-11 §8 still applies: `ccx_ll_ar1_SUPERSEDED()`, the
  `ccx_build_forcing()` flat-GMST warning, the FaIR export in `data-raw/downloads/fair_v145_ssp/`,
  the 1817 post-Tambora worst year in the climate module, and the `SST_PCO2_SENSITIVITY`
  double-counting check still open from 2026-08-09.

---

## 9. Commits this session

| | |
|---|---|
| `4e726b5` | Ocean excess-¹⁴C inventory enters the likelihood |
| `b67a1c7` | Land-use-change emissions inject ¹⁴C ex nihilo; diagnostics committed |
| `e4cd317` | Recalibrate with the ocean constraint: `bomb_total` 151.2 → 149.8, i.e. nothing |
| `62e1451` | `bomb_total` profile: the target-set choice dissolves; the constraint cannot win |

---

## 10. Starting the next session with Remote Control

Remote Control lets this session be driven from claude.ai or the mobile app — useful here because
the natural rhythm of this work is *launch a 2-hour mode-find, go away, check on it.*

```bash
cd ~/Documents/2026/CodeProjects/CarbonCycleEmulator && claude --remote-control ccx-dev
```

The name is optional (`--remote-control` alone auto-names from the hostname; the prefix is
configurable with `--remote-control-session-name-prefix`). Launching from the repo root rather
than `FaIRtoFrEDI/` is deliberate — `ccx_root()` keys off `DESIGN.md`, and the user-level
`additionalDirectories` already covers everything under `CodeProjects/`.

Open with:

> Read `notes/handoff_2026-08-12_excess_c14_closed.md` and continue carbon cycle emulator
> development.
