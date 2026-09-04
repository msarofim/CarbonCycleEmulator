# CHANGELOG — CarbonCycleEmulator

Project log: what was done, what was tried and abandoned, and why.

## 2026-09-04e — THE GATE SET, AUDITED: 4/8/10 RETIRED, GATE V ADDED, GATE 12 DEMOTED

Marcus's rule, applied to the whole set: **every test must compare an observed variable — including
measures of interannual variability and other second-order observations — or a physical law, against
the model.** Note `notes/diag_2026-09-04_gate_set_audit_and_gateV.md`.

⛔ **GATE 4 RETIRED.** Its quantity is a GCB observation, so it passes the rule as WORDED; it fails
what the rule is FOR. Its numerator is a scored stream and its denominator a model input, and the one
signal it had — the 2020s — reappears in `co2_level_MLO` at **mean z −0.96, max |z| 1.63**, the
largest decadal excursion in that stream's record: same sign, same size, already in the objective.
The AF is still COMPUTED and PRINTED; `dg_gate4_verdict()` now ERRORS with the reason.

⭐⭐ **GATE V ADDED — the interannual CO₂ growth variability**, the second-order observation gate 4
was reaching for, where it IS resolved (66 annual values, not 7 decadal ones). Estimator identical
both sides (`grow = AF(y)·emis + eps`, AF a natural spline); the gate is `sd(eps)`. ⭐ **The bound is
DERIVED FROM THE OBSERVATION**: the sampling error of an sd, `sd/sqrt(2(n−1))` = **0.080 GtC/yr**,
MC-validated to three decimals; two-sided at `DG_V_NSD` = 2. **Nothing in the objective asks for it**
— `co2_level_*` scores levels at a soft 1.0 ppm.

| | sd GtC/yr | ratio | z |
|---|---|---|---|
| GCB 2025 | 0.911 ± 0.080 | 1.00 | — |
| defaults | 0.638 | 0.70 | −3.42 |
| **ent26** | 0.698 | 0.77 | **−2.67 FAIL** |

⭐ **AND THE KNOCKOUT DECOMPOSITION MAKES IT ACTIONABLE** (`diag_gateV_variability_drivers.R`, 5 runs
in 0.5 s). Variance lost when each driver Marcus named is removed — temperature SMOOTHED with an
11-yr centred mean rather than held, so the trend survives: **TEMPERATURE (`gmst` + `sst_anom_*`)
−47.8 %, ENSO (land + ocean) −66.3 %, VOLCANIC (AOD → diffuse light) −6.1 %, all three −92.6 %.**
⚠ Singles sum to 0.586 against the joint 0.451 — the difference is INTERACTION, printed not hidden.
⇒ **The named drivers would have to supply 1.76× their present combined variance to close gate V**,
and ENSO is the largest share — with the ENSO OCEAN response already on record as ANTI-correlated
with observed (r −0.51 vs +0.535). **Gate V points at Fix B.**

☀ **AND A SOLAR CYCLE WOULD NOT HELP — three independent grounds.** (1) **It is already in the
model**: CCX is driven with the OBSERVED GMST, which carries whatever the solar cycle did to
temperature — the same argument `R/forcing.R` already makes for volcanic cooling; a solar→T term
DOUBLE-COUNTS, and the only non-redundant addition is a direct irradiance→photosynthesis MECHANISM.
(2) **The observations show no significant cycle**: best-fitting period in 9–13 yr is **9.4 yr, not
11**, amplitude 0.477 GtC/yr — but a white-noise null searched over the SAME band has median 0.316
and 95 % 0.502, so it sits at the **93rd percentile**. (3) **Too small either way**: it carries
0.114 of the 0.343 (GtC/yr)² needed, **33 %**. ⚠ **Power stated**: the test detects any harmonic
above ~15 % of the observed variance and cannot rule out smaller ones — on ~6 cycles that is the
honest null.

⛔ **GATES 8 AND 10 RETIRED, neither replaced.** Gate 8 differenced two station-years that
`d13c_level_MLO/SPO` score EVERY year of, then re-judged them at a typed 0.10 ‰ with no derivation.
Gate 10 is the clearest case in the set: its own header said its target AND sigma came from
"the LIKELIHOOD's own accessor, so this gate cannot drift from the stream that scores it" — **a gate
tied to the stream it checks cannot fail independently of the optimiser.** ⚠ What is LOST is written
into the retirement block: both were the only places certain quantities were PRINTED beside their
targets. Bring back the print, never the verdict.
🐛 **And `diag_design_gates_unscored.R`'s summary could not run at all** — `cn` was the typed literal
`"from90"`, quarantined 09-04, so every lookup indexed a NULL. Now `CCX_MODE_CANONICAL`. **Gate 6
PASSES at ent26** (growth +19.4 % vs observed +15.6 %).

⚠ **GATE 12 / 12a / 12b → A POST-MODEL COMPARISON, NOT A STRICT TEST** (Marcus): *"we don't
necessarily expect to meet it, the long lifetime should be an emergent behavior."* Joos 2013 is
another MODEL, and **no observation constrains a CO₂ perturbation lifetime** — ¹⁴C measures tracer
transport and the two are ~2.8× apart at 100 yr. Still computed, still printed against Joos's ranges
with inside/BELOW/ABOVE; **nothing scored, gated, or chased in a refit.**
⛔⛔ **CONSEQUENCE: P5 IS NO LONGER "FALSIFIED."** IRF(100) = 0.276 is now a REPORTED DIFFERENCE about
where the emergent lifetime sits. Every record saying "P5 FALSIFIED" predates this ruling.
The strict assertion in `test-pulse.R` — |model − Joos|/Joos < **0.40**, a typed band against another
model, evaluated at `ccx_default_params()` rather than the fitted mode — is GONE; what remains
asserted there is only what is ours (the protocol's precondition, IRF ∈ (0,1), and decay).
`test-joos-irf.R` keeps EVERY assertion, because none of them is about our model: the
single-exponential locus is parameter-free ALGEBRA and the rest are properties of the REFERENCE.

⇒ **STILL OPEN, and now the top of the list.** **GATE S IS CIRCULAR** — its target is an SPO
observation inverted through the model's own signatures, all six constants `status = "provisional"`,
and the independent check its own source names is the **MPI SOM-FFN surface-ocean pCO₂ climatology
already on disk**, used only to bracket `sst_seas_amp`. That same product is the Fix B pre-test.
Untested observations we HAVE: `obs_d14c_station_validation` (160 points, built as a held-out
validation set, used by nothing), the Eide ocean δ¹³C Suess depth profile, the MOD17 GLOBAL NPP
level. Not in the repo at all: the ocean **anthropogenic carbon inventory** (¹⁴C measures
ventilation, not buffer capacity, and gate 12a's verdict is an ocean-CAPACITY defect) and
**atmospheric O₂/APO**.

## 2026-09-04d — GATE 4 HAS NO POWER: the "smoother than the defaults" reading is a TREND artifact

Open decision 1 of the adoption handoff was gate 4 — *"why did the AF decadal spread get SMOOTHER?
0.48x observed against defaults' 0.76x, the clearest new lead the adoption produced."* Measured, it
is not a lead. Both prior numbers reproduce exactly (0.763 / 0.478 against the retired target), so
what follows is a re-reading of the same measurement. `calibration/diag_gate4_af_spread.R`,
note `notes/diag_2026-09-04_gate4_has_no_power.md`.

⛔ **THE TWO SIDES OF THE GATE WERE USING DIFFERENT ESTIMATORS.** `DG_AF_OBS_DEC` was seven typed
two-decimal literals with no provenance line. Recomputed from the same GCB budget the likelihood
reads, only ONE of the two natural estimators reproduces all seven: the **mean of annual AF**
(0.3534 0.4265 0.4661 0.3807 0.4245 0.4482 0.4970). `dg_gate4()` has always computed the model side
as a **ratio of decade sums** (0.3568 ...) — and 2 dp of rounding hid the difference in six of the
seven decades; only the 1960s, 0.3568 → 0.36 against the typed 0.35, exposes it.
⚠ **The gate's BOUND is the sd of that vector**: 0.0515 typed → 0.0491 mean-of-annual → **0.0483
like-for-like**, so the model was being asked to beat a spread 6.6 % larger than the observations
have. Both sides now go through one `dg_af_dec()`; the literals are kept as `*_TYPED` and their
provenance is pinned in `test-gate-bounds.R`, so a GCB vintage change has to break something.
No verdict flips. [[derived_must_mean_computed]], [[like_for_like_forcing]]

⛔ **70 % OF THE TARGET'S VARIANCE IS INTERANNUAL NOISE.** The anomaly about a smooth AF(t) is
0.911 GtC/yr and white (lag-1 rho +0.014), so a decade's AF carries a sampling sd of 0.026–0.060
(the 2020s "decade" is 5 years). Analytic floor rms **0.0404** against an observed spread of 0.0483
⇒ the RESOLVED decadal signal is **0.0265**. Robust across ns df 2–5. ⭐ The analytic se was
validated against a **matched Monte Carlo** before anything was concluded from it: per-decade
0.0594/0.0444/0.0401/0.0355/0.0301/0.0255/0.0347 against the analytic row, agreement 1–4 %.

⭐⭐ **AND THE DEFAULTS' ADVANTAGE WAS A DRIFT, NOT A WIGGLE.** `sd()` over seven decades cannot tell
a model whose AF *varies* from one whose AF *drifts* ([[two_statistics_can_be_blind]]):

| arm | sd(dec) | sd(trend) | sd(detrended) | R² | raw ratio | **detrended** |
|---|---|---|---|---|---|---|
| GCB 2025 | 0.0483 | 0.0320 | 0.0397 | 0.439 | 1.000 | 1.000 |
| defaults | 0.0393 | 0.0323 | 0.0245 | 0.677 | 0.813 | **0.617** |
| ent26 | 0.0246 | 0.0107 | 0.0243 | 0.188 | 0.509 | **0.613** |

Detrended, **the two arms are identical to three decimals**. The adoption did not smooth the
airborne fraction; it changed the AF TREND (+0.0157 → +0.0057 per decade) and the gate's statistic
charged that to variability.

⚠ **AND THE TREND CANNOT REJECT EITHER ARM.** Estimated on the ANNUAL series, the observed AF trend
is **+0.0147 ± 0.0080 per decade, t = +1.83** — not significant at 95 %, and both arms sit inside its
95 % CI (z +0.12 and −1.12). A trend needs an error bar before it needs an explanation.

⭐ **THE DECISIVE TEST — judge each arm against ITSELF.** A null built on an arm's OWN fitted trend
and OWN anomaly amplitude puts every arm INSIDE: GCB 0.0483 in [0.0261, 0.0734], defaults 0.0393 in
[0.0239, 0.0602], ent26 0.0246 in [0.0165, 0.0489] (median 0.0303). ⇒ **Nothing decadal is left
over.** Gate 4's failure decomposes entirely into a trend inside the observations' own CI plus the
already-recorded interannual gap (the arms carry 0.70 / 0.77 of the observed anomaly sd).

✅ **WHAT DOES SURVIVE: the 2020s, and half of it is one year.** Scored per decade against the
observations' own sampling noise, the only miss with size is 2020–2024, ent26 **z −2.68** (defaults
−1.33). Model growth 22.92 GtC vs GCB 28.50 = a **5.58 GtC deficit**, ~1.1 GtC/yr of excess sink,
visible in the cumulative CO₂ rise (model−GCB +0.37 ppm at 2019 → **−2.26 ppm at 2024**);
`luc_scale` = 0.975 accounts for 0.16 GtC, so it is not an emissions-input artifact. ⚠ But **2024
alone is −2.89 GtC, 52 % of it** — the observed record 7.92 GtC/yr read as 5.03 — which is the ENSO
arc (Fix B), not a new decadal finding. The steadier ~1 GtC/yr over 2020–2022 is unattributed.

⇒ **RULINGS OWED (Marcus; proposed, NOT adopted).** (1) Gate 4's ordering should be split or
retired — the natural replacement is the per-decade z against the observations' own sampling sd,
the only form here with power ([[tolerance_scaled_to_spread]]). (2) Open decision 1 should be
**re-ranked**: it is the interannual gap under a decadal name, not the clearest lead the adoption
produced.

⇒ **AND THE STANDING RULE THIS ADDS TO:** *a gate that reports one number for two mechanisms cannot
be read as evidence about either.* Gate 4's `sd()` was blind to the trend/variability distinction,
so the same statistic ranked the UNCALIBRATED defaults above the adopted mode — and the ranking
inverted the moment the two were separated.

## 2026-09-04c — SUITE FULLY GREEN: 1737 pass / 0 fail / 0 error / 4 skip

The last three problems were all the same shape — a test asserting something that is not true of the
model, or not about the model at all. None was fixed by relaxing a number.

⛔ **THE ANCESTOR ENCODING IS GONE (2 errors).** Both `test-seas-lag-split.R:174` and
`test-enso-demean.R:105` migrated a pre-26 ancestor and then ENCODED it. That stopped being valid
when `ent_seas_amp_SH` was freed (`88ee23c`): a migrated ancestor has `ent_seas_amp_SH = 0`, which
has no image under `tr = "log"` and probability ZERO under a lognormal prior. **Asserting it encodes
was asserting something FALSE about the model**, not something true about the migration.
- `test-seas-lag-split.R` now asserts the **OPPOSITE, which is a real claim**: the encoder must
  REFUSE, and refuse BY NAME — the guard hardened on 09-03 that nothing was testing. Migration
  itself (21 names in, the legacy both-hemispheres lag contract) is asserted exactly as before, and
  the vector SEEDED at its table init is asserted to encode finitely, which is the
  migration-vs-seeding separation `ccx_seed_unencodable()` exists to make.
- `test-enso-demean.R`'s Ruling A guard was broken **three ways**: it encoded an ancestor, it
  asserted TWO ABSOLUTE LOGPOSTS (−1568.4936 / −1512.0151) that no fill repairs, and it called
  `dg_vector("from90")` for a pump_mode — a now-RETIRED arm. It now scores **at the canonical mode**
  (a genuine point of the fitted space, no migration) and asserts **the GAP**, which is what Ruling A
  actually claims and is objective-independent by construction.
  ⚠ **THE GAIN SHRANK, +56.4785 → +45.1618, AND THAT IS THE EXPECTED DIRECTION**: the 26-par refit
  absorbed part of the ENSO forcing's non-zero mean into other coordinates, so the MARGINAL value of
  demeaning at the refitted optimum is smaller than at the un-refitted ancestor it was ratified on.
  Cross-checked: with the flag ON — the shipped state — the harness reproduces the mode file's own
  stored logpost exactly, so the two scorings are demonstrably of the vector the test names.

⛔ **THE PARITY TIMING GATE IS REMOVED (1 failure).** "The C++ core is fast enough for MCMC",
`el < 0.05` s from one `system.time()`. It was never a parity test and never a test of the code — it
measured the MACHINE, and it sat exactly on its own threshold: **median 0.0490 s, 7 of 15 runs over**.
A ~50/50 coin flip that duly flipped, under load 11.85 on 10 cores from an unrelated MAGICC job, in
a suite where every other failure was being read as a finding.
⚠ **Widening the budget would have been the wrong fix**: a wall-clock threshold on a shared machine
has no stable value, and a check that fires at random trains the reader to skip the file.
⇒ The performance question is real and is already owned properly by the 09-03 profiling, which took
2.9× off every evaluation by MEASURING where the time went rather than by asserting a ceiling.

**4 SKIPS, all declared**: two carbonate, one gate-bounds, and `test-mode-file.R`'s free-vs-pinned
comparison, which reports itself DARK because one arm in the registry cannot fail.

## 2026-09-04b — the kz guard rail becomes a test against the OBSERVATION

**Marcus's ruling, and it generalises: "the only tests that matter are the ones against
observations or physics."** `kz` is not directly observed; the deep-ocean Δ¹⁴C is.

⛔ **REMOVED `expect_lte(CCX_PARAM_TABLE$kz$hi, 7000)`** (test-likelihood.R). It had been failing
since the 09-01 re-bisection moved `kz$hi` to 8109.9, and the reason it failed is that it was never
a test of the model: it bounded the SUPPORT OF A LATENT PARAMETER and justified itself by naming
"the observed −150 to −200", which `R/calibrate.R`'s own header records as **an uncited
recollection**, on the bottom THREE boxes rather than the bottom box the likelihood scores. The
09-01 work replaced it with GLODAPv2's sourced **−175.26 ± 10.259 ‰** — which is precisely why
`kz$hi` moved past 7000. The assertion was failing against a number the project had already retired.
⚠ **And it had no power either way**: at `ent26`, `kz` = 6356, BELOW the 7000 it bounded.

✅ **REPLACED by the observable**: the model's bottom-box Δ¹⁴C must sit within 2σ of
`ccx_deep_d14c_target()` (read, never retyped). Measured at `ent26`: **−156.15 ‰ vs −175.26 ± 10.26,
z = +1.86 — INSIDE, but on the young/better-ventilated side and not comfortably so** (~450 m²/yr of
`kz` of margin). That thinness is information: the model really does sit near the edge of the
observation.

⭐ **MUTATION-TESTED ACROSS `kz`, and the table says something the bracket does not:**

| kz | 4379.1 | 5000 | 6356.2 | 7000 | 8109.9 | 10686 |
|---|---|---|---|---|---|---|
| deep Δ¹⁴C | −196.94 | −181.05 | −156.14 | −147.41 | −135.36 | −116.49 |
| z | −2.11 | −0.57 | **+1.86** | +2.71 | +3.89 | +5.73 |
| verdict | FAIL | PASS | **PASS (mode)** | FAIL | FAIL | FAIL |

It fails at the runaway that motivated the original bound (10,686, z +5.73) — the mutation that
matters. ⚠ **And it fails at BOTH ENDPOINTS of the shipped bracket [4379.1, 8109.9].** Not a
contradiction — a prior SUPPORT is not a 2σ interval, and the bisection recipe never claimed to be
one — but the retired comment's promise, "the range that keeps deep-ocean D14C inside the observed
range", was **not literally true at the bracket's own edges**. The observationally admissible window
at 2σ is roughly `kz` ∈ (4400, 6800); the fit lands at 6356.

**KEPT**: `expect_identical(kz$tr, "logit")` and `expect_lt(kz$hi, 10686)` — the latter is a
different KIND of claim, an ORDERING against a MEASURED runaway rather than a threshold anyone chose.

## ⛔ CORRECTION TO THE 2026-09-04 ENTRY ABOVE: the suite counts omitted ERRORS

`as.data.frame(test_dir(...))$failed` counts FAILURES and **not ERRORS**, so "1719 pass / 1 fail /
4 skip" understated the state. **The true post-adoption count is 1720 pass / 1 fail / 2 ERRORS /
4 skip** (3 problems, against the handoff's 10).

⇒ **Adoption cleared TWO of the four 09-03 encoder failures, not all four.**
`test-enso-split.R:236` and `test-seas-lag-split.R:150` went green; **`test-seas-lag-split.R:174`
and `test-enso-demean.R:105` still ERROR.** Same root cause in both: they migrate a **pre-26
ancestor** and then ENCODE it, and `ent_seas_amp_SH = 0` has no image under `tr = "log"`. VERIFIED
untouched by the adoption — they read `refit_20260830_gamma_diff_remap/` and
`multistart_20260901_enso25/`, neither of which moved. ⚠ The 09-03 ruling was that nothing would
encode a pre-26 ancestor once a 26-par mode was adopted; these two still do, so the ruling implies
an edit to them that has NOT been made. **AWAITING A RULING; not modified.**

⚠ **AND ONE MORE, WHICH IS THE MACHINE AND NOT THE CODE:** `test-parity.R:235` failed once —
"the C++ core is fast enough for MCMC", `el < 0.05` s. It is a WALL-CLOCK BUDGET, not a parity or
physics assertion. Measured 15 times: **median 0.0490 s against the 0.05 s budget, 7 of 15 over.**
The test sits on its own threshold and is ~50/50 by construction. It passed in both earlier suite
runs today at load ~3; it failed at **load 11.85 on 10 cores**, with a concurrent
`slr-refresh-2025` pymagicc/MAGICC job (not ours) running 6+ processes. **NOT widened** — a
performance gate that measures the machine rather than the code is worth a decision, not a bigger
number.

## 2026-09-04 — THE 26-PARAMETER MODE IS ADOPTED: `ent26` is `CCX_MODE_CANONICAL`

**The refit results were never pulled off Torch.** `calibration/output/multistart_20260903_ent26/`
was EMPTY locally; both rounds (40 + 5 starts) are now down and the collector reproduces the
handoff exactly — 39 of 40 at −1446.7627/−1446.7631 (spread 3.93e-4), id 12 alone at −1508.7786.

**ADOPTED.** `from90` (21 par, canonical since 2026-08-26) and `pin90` are quarantined under
`calibration/output/quarantine/20260903_ent26_adopted/`; `CCX_MODE_CANONICAL` is `ent26`,
promoted from start id 18 by the new `calibration/promote_multistart_mode.R` (5 gates; the start
is COMPUTED from the directory, never typed). This is the first time a multistart result has been
promoted to a mode file, which is why no such tool existed.

**All five pre-registered claims re-measured AT THE ADOPTED FILE** (`diag_adoption_read_ent26.R`),
and every one reproduces the handoff: P2 `sst_seas_amp_SH` −5.139 → +0.237; P1 GATE S 0.330 ppm
@ 4.19 (z −12.30) → 0.437 @ 8.87 (z +1.00), FAIL → PASS; P3 land limb 2.475× → 1.683×;
`npp_frac_NH` −2.153 → −0.051; `ent_seas_amp_SH` 19.029 at prior-z +1.11. |z|>2: 5 → 3; |z|>3: 3 → 2.

⭐ **AND THE HALF THE HANDOFF COULD NOT STATE: the LIKELIHOOD moved +20.41.** The two logposts are
not comparable (different spaces), but the 21 data streams and their sigmas are identical across
the builds, so the likelihood is. The fit improved; the prior was not merely paid.

⭐ **THE HESSIAN BLOCKER IS MEASURABLY BETTER, AND `h_ml` IS NO LONGER STEP-UNSTABLE.** At the new
mode −H is PD, **condition number 7.394e+04** against the 1.11e6 recorded at `from90` (⚠ a
DIFFERENT objective — three changes separate them, so this is indicative, not like-for-like), and
**no parameter is flagged unstable**: `h_ml`'s own eps/3–3eps disagreement is 1.20 % against the
2 % tolerance. Softest/stiffest eigen-sd ratio 1055× → 272×. `kz` sits at 6356 inside [4379, 8110],
not railed.

**THREE BUGS FOUND AND FIXED WHILE DOING IT, none of them in the model:**
1. ⛔ `recompute_hessian.R`'s per-parameter step table printed its header and **ZERO ROWS** on the
   promoted file. Line 177 indexed `md$hess_eps`, which a multistart-promoted mode does not have;
   `NULL / EPSV[k]` is `numeric(0)`, `sprintf()` returns `character(0)`, `cat()` prints nothing —
   and the `*** UNSTABLE` step-stability verdict rode along in that same row. The silent-gate
   family exactly. Both branches now mutation-tested.
2. ⛔ Its **"condition number" was the RECIPROCAL** — `max/min` over eigenvalues that are all
   negative, so the two signs cancelled and it printed 1.352e-05 for a conditioning of 7.394e+04.
   Wrong for every mode this script has ever produced. `run_modefind_pump_arms.R` used `abs()` and
   is unaffected. Also: `21x21` was a hardcoded label in a 26-parameter build.
3. ⛔ **Retiring an arm silently UN-LINTED its path.** `test-mode-file.R`'s hardcode lint builds its
   directory list from `CCX_MODE_FILES`, so quarantining `from90`/`pin90` dropped them from scope at
   exactly the moment seven live lines across four files went stale. Widening that lint to scan the
   quarantine was the WRONG fix (it pulls in the `luc_arm_*`/`ridge_pin*` scratch arms the lint's own
   SCOPE paragraph excludes) and is recorded as such; the staleness question is now a SEPARATE test —
   every quoted `mode_fit_pump*` path on a live line must exist on disk. It found an eighth
   occurrence nobody knew about: `diag_luc_arm_ridge_confound.R` had pointed at a `luc_arm_pinluc`
   moved by the 2026-08-25 quarantine, stale for ten days. Mutation-tested.

**TEST SUITE 1710/10/2 → 1719 pass / 1 fail / 4 skip.** Adoption cleared everything the handoff
predicted (`test-mode-file.R:109×2/:203`, `test-mode-decode.R:15`, and all four 09-03 encoder
failures). It also broke 20 previously-passing assertions, NONE of them a model defect — Marcus's
criterion ("the only tests that matter are the ones against observations or physics") sorted them:

- `test-so-entrainment.R` (15) — an IDENTITY control. Its fixture read the zero baseline off
  `ccx_default_params()`, which the adoption flipped 0 → 10.9524. The claim it guards (absent ≡
  zero) was MEASURED intact, bit for bit, both cores, all five columns. ⚠ **Two assertions did NOT
  fail, which is the worse half**: P0.2's mutation guard and the rectification bound both used the
  default as their OFF baseline, silently became ON-vs-ON, and kept passing while measuring less
  than they claimed. The off-state is now a named fixture; nothing in that file reads the default.
- `test-ent-seas-fitted.R:157` (1) — a POLICY assertion that named itself as the thing to change on
  adoption. ⚠ Its replacement was first written one assertion too strong (default == the derived
  constant to 1e-9); that fails by 4.41e-07 because `init` is necessarily a six-decimal literal —
  `R/calibrate.R` is sourced before `R/constants.R`. Removed; the file's first test already bounds
  that drift by the literal's own typed precision.
- `test-mode-decode.R` (4) — a PROVENANCE guard asserting the h_ml band-provenance trap is PRESENT.
  ⭐ **The trap is gone**: `ent26` was fitted on the shipped support with no in-process override, so
  `u_mode` decodes to `par_mode` exactly (134.150 m either way). Deleting the tests would leave the
  trap-handling code exercised by NOTHING, so the trap half now runs against an explicit override
  fixture (with a mutation guard on the fixture itself) and the canonical file gets the assertion
  that is true of it.

⛔ **`test-likelihood.R:596` LEFT RED, and it is the only failure.** It is the one
observation-facing assertion: "kz is BOUNDED to the range that keeps deep-ocean D14C inside the
observed −150 to −200", and `expect_lte(kz$hi, 7000)` fails because the 09-01 re-bisection on the
sourced GLODAP target moved `hi` to 8109.9. VERIFIED untouched by this session — it failed
identically in the pre-repoint baseline and none of the changed files goes near `kz`. It is a real
tension between two observations and needs a ruling on which binds.

⚠ **`ccx_default_params()$ent_seas_amp_SH` FLIPPED 0 → the derived prior centre** (10.9524, read
from `CCX_PARAM_TABLE`, not typed). Held at 0 deliberately until adoption. It could not stay:
`R/model.R`'s guard is `!= 0`, so zero SHORT-CIRCUITS the entrainment path and every defaults-arm
run would exercise a model the calibrated one does not have. It is the PRIOR CENTRE, not the fitted
19.029 — `ccx_default_params()` is the uncalibrated reference.

⛔ **`pin90` retired, and the `PIN_PRIOR_CREDIT` assertion retired with it rather than being
re-measured or preserved** (Marcus's ruling). Both sides were the model's own fitted arms scored by
the model's own objective, against the value of a prior this project chose at a `fert_k` this
project chose — a threshold taken from the code under test, which can never reject that code.
⚠ **The cost is stated, not glossed**: with one arm in the registry the free-vs-pinned comparison
has NO POWER, and `test-mode-file.R` now reports it DARK via `skip()` rather than green. A
26-parameter PINNED refit is what would restore it.

⛔ **P5 IS STILL FALSIFIED.** IRF(100) 0.276 → 0.276. Fixing the seasonal ocean physics did not
lengthen the perturbation lifetime by any amount; the three problems are INDEPENDENT and Fix C
needs its own mechanism. This is the pedagogically important failure, because the emergent-lifetime
claim is what the model exists to demonstrate.

⚠ **`sst_seas_amp_NH` −3.558 → −3.911 is now the model's worst prior violation**, and it is
explicitly NOT the SH fix repeated — the NH has no entrainment channel by measurement.

## 2026-09-03 — **ROUND 2 CLOSED, AND THE SPINUP SPEEDUP IS SHIPPED**

**`16905919` (half dispersion): 5/5 COMPLETED, 0 errors, all five at −1446.7631 / −1446.7627** — the
dominant basin. Nothing new at sd 0.5233.

⇒ **THE TWO DISPERSIONS TOGETHER SAY SOMETHING THE COUNT ALONE COULD NOT:**
| dispersion | draws | dominant basin | second basin |
|---|---|---|---|
| sd 1.0466 (measured) | 34 | 33 | **1** (−1508.7786) |
| sd 0.5233 (half) | 5 | 5 | 0 |

The second basin is reached only from the WIDER dispersion, which is consistent with it being
genuinely distant in u-space rather than adjacent to the main one. ⚠ 5 draws at the narrow
dispersion is a weak bound and is quoted as one — this rules nothing out, it just fails to find it.

**SHIPPED to Torch now that nothing is running**: the `ccx_deriv_fast()` spinup (2.9×) and
`port_targets.csv` regenerated under it at commit `80f212f`. The targets moved by ~1e-9 absolute
(cold −17421.4037269681 → −17421.4037269680), exactly the 8e-14 relative already priced.

## 2026-09-03 — ⭐⭐ **THE SPINUP MOVED TO THE COMPILED DERIVATIVE: 2.9× ON EVERY EVALUATION**

`R/spinup.R`'s four call sites now use **`ccx_deriv_fast()`** — the same-signature compiled twin
`test-parity.R` already exercised, so this is a substitution, not a reformulation.

| | before | after | |
|---|---|---|---|
| `ccx_spinup()` | 0.1252 s | **0.0178 s** | 7.0× |
| full objective | 0.1404 s | **0.0483 s** | **2.9×** |

⭐ **THE OBJECTIVE MOVED 7.98e-14 RELATIVE (+1.155e-10 absolute)** — five orders **inside** the port
gate's own 1e-8. So `port_targets.csv`, every stored logpost and every checkpoint `ref_logpost` stamp
stay valid, and nothing needed regenerating. That is consistent with `test-parity.R`'s **analytic**
bound of 8.5e-15 relative (floating-point reassociation of the pump's 20 flux terms and nothing
else), which sits 5 orders below the Newton's 1e-9 residual tolerance and 8 below its 1e-7
finite-difference step — neither the Jacobian nor the convergence test can feel it.
⚠ Suite unchanged: 1710 pass / 10 fail / 2 skip, `test-parity.R` among the passes.

⚠ **The balance has flipped and that is the right shape**: the transient is now ~58 % of an
evaluation and the spinup ~37 %. Any further gain would have to come from building the two isotope
operators **analytically** — both tracers enter the derivative linearly — rather than by 32
finite-difference columns each.
⛔ **NOT YET SHIPPED TO TORCH**: `16905919`'s five half-dispersion tasks are still running.

## 2026-09-03 — ⛔ **THE OUTLIER IS REAL: TWO BASINS, NOT ONE**

id 12's resume (`16905918`, 300 min budget) ran cycle 3 with **two FULL-LENGTH restarts** — 4,521 and
8,634 evals, **not** wall-shortened — and both gained **exactly 0.0000**, finishing in 44 of 300 min.
⇒ **−1508.7786 is a genuine local optimum, 61.9 log-units above the main basin**, found by **1 of 34**
dispersed draws.

⚠ **I had leaned the other way** — "most likely a task that ran out of budget in a bad region". The
resume was the test and it said otherwise. ⇒ **The survey's claim is "one DOMINANT basin (33/34)
plus a second at −1508.78", not "one basin"** — and the round-1 `CONVERGED` label, which I flagged as
overstating, turns out to have been right for the wrong reason.

## 2026-09-03 — **ROUND 1 CLOSED (40/40, 0 errors); ROUND 2 RUNNING**

**`16837149` final: 40 COMPLETED, 0 errors, ids 40–45 cancelled deliberately.**
**39 of 40 at −1446.7627 / −1446.7631** (spread 4e-4) — of which **34 were dispersed draws and 33
hit the basin**. One outlier, id 12, at −1508.7786.

**⭐ THE `colClasses` PROVENANCE FIX SHIPPED IN THIS WINDOW**, which is the whole reason it was held:
nothing was running to have its driver re-parsed underneath it ([[never_edit_a_running_script]]), and
nothing was pending to read a different build than its siblings.

**ROUND 2, both verified as started correctly:**
* **`16905918`** — id 12 resumed: `RESUMED from checkpoint at cycle 2, log-post −1508.7786`, wall
  budget **300 min** (inside `cpu_short`'s 6 h QoS, read off `sacctmgr`). It reached only cycle 2 of
  6 in round 1, so this gives it cycles 3–6 with full-length restarts. **Diagnostic either way:**
  stays at −1508.78 ⇒ a real local optimum; drops to −1446.76 ⇒ it was budget, and the `CONVERGED`
  label was measuring an exhausted wall.
* **`16905919`** — 5 draws at **half** the measured dispersion, `OVERRIDE CCX_MS_SPREAD = 0.5233
  (default 1.046575)`, own output directory. The dispersion, not the count, was the untested axis.

## 2026-09-03 — ⭐⭐ **THE REFIT ANSWERS THE PRE-REGISTRATION: P1/P2/P3 LAND, P5 IS FALSIFIED**

Job `16837149`, **12 of 46 tasks in, every one at −1446.7627/−1446.7631 (spread 4e-4)** — ONE BASIN,
reached from the cold init, the migrated ancestors, the seeded starts and dispersed draws alike.
⛔ **NOT comparable to the 25-par −1482.6144**; different space.

| | 25-par winner | 26-par refit | |
|---|---|---|---|
| **P2** `sst_seas_amp_SH` prior-z | **−5.14** | **+0.24** | ✅ **the 5σ strain is GONE** |
| **P1** GATE S ocean limb | 0.330 @ 4.19, z −12.30 | **0.438 @ 8.87, z +0.99** | ✅ **PASS** |
| **P3** SPO land limb | 2.48× obs | **1.68×** | ⚠ better, not closed |
| **P3** `npp_frac_NH` prior-z | −2.15 | **−0.05** | ✅ back at its prior |
| **P5** IRF(100) | 0.276 | **0.276** | ⛔ **unmoved** |
| `ent_seas_amp_SH` | — | **19.03, z +1.11** | ✅ not strained |
| \|z\|>2 / \|z\|>3 | 5 / 3 | **3 / 2** | |

⭐ **THE HYPOTHESIS HELD.** One missing mechanism did explain the worst prior violation, the seasonal
partition error and the land limb's excess at once — and the mechanism landed at a **physically
plausible 19.03 µmol/kg**, inside its prior and inside the recorded 5–30 band, not at a fudge-factor
value. ⭐ **The pre-registered risk did NOT materialise**: the conditional profile put the optimum at
ent ≈ 2 / prior-z −3.41 and warned the strain might just move onto the new coordinate. It didn't —
another frozen slice overstating a cost, exactly as this project keeps finding.

### ⛔ AND THE PART THAT DID NOT WORK, WHICH IS THE PEDAGOGICALLY IMPORTANT ONE
**P5 IS FALSIFIED. IRF(100) 0.276 → 0.276; ∫IRF@100 39.23 → 39.26.** Fixing the seasonal ocean
physics did **not** lengthen the perturbation lifetime by any amount. ⇒ **The three problems are
INDEPENDENT**, the hoped-for "constrain the seasonal observables with the right mechanisms and the
long lifetime falls out" **does not happen**, and Fix C needs its own mechanism. That was written
down as a prediction before the run precisely so it could fail this way.

### ⚠ AND A NEW WORST VIOLATION, WHICH IS NOT THE SAME FIX AGAIN
`sst_seas_amp_NH` went **−3.56 → −3.91** and is now the model's worst prior violation. ⛔ The NH
deliberately has **no** entrainment channel, and that is a MEASUREMENT, not an omission: NH-mean pCO2
sits 0.30 months from NH-mean SST, so the NH really is solubility-dominated at the hemispheric mean.
Also open: the SH land limb is 1.68× at phase **11.19 against an observed 9.29**, and `rep_dC` is
still +3.38.

## 2026-09-03 — ⭐⭐ **WHY THE FIT IS EXPENSIVE, PROFILED: IT IS THE SPINUP, IN R**

Marcus asked whether a 15-hour array for a "simple model" is just the parameter count. ⛔ **It is not.**

| piece of one evaluation | time | share |
|---|---|---|
| **`ccx_spinup()`** | **0.1252 s** | **84 %** |
| transient, 1750–2024 | 0.0282 s | 19 % |
| `ccx_loglik()`, ~20 streams | 0.0025 s | 2 % |
| **full objective** | **0.1485 s** | |

⚠ **THE PHYSICS IS CHEAP.** 96 state numbers (32 boxes × 3 tracers), 4 substeps/month ⇒ **13,200 RK4
steps / 52,800 derivative calls** for 275 years in **0.028 s** — about **0.5 µs per derivative call**,
because the transient runs in the C++ core. **Re-deriving the 1750 equilibrium costs 4.4× the entire
historical simulation.**

⭐ **AND THE DIAGNOSIS IS ONE LINE.** `Rprof` over 40 spinups: **`ccx_deriv` is 91 % of it**
(`add_flux` 41.7 %, `add_diffusion` 17.9 %, **`%in%` 7.3 %**, `h_from_dic_alk` 3.7 %).
**`ccx_spinup()` calls the *R* `ccx_deriv` while `ccx_deriv_cpp` is already exported**
(`src/ccx_core.cpp:783`) and is what the transient uses. Three hot sites in `R/spinup.R`: the Newton
residual (`:84`, inside the iteration), the isotope operator (`:207`/`:211` — a loop building a
32×32 matrix **one column at a time**, ~32 calls per tracer), and a final residual (`:239`).

**WHAT IT COSTS:** Torch runs 0.27 s/eval (~1.8× the Mac); 6,000 × 3 restarts × 6 cycles ⇒ up to
108,000 evals/task, **46 tasks ⇒ up to 138 CPU-hours** — of which **≈5 CPU-days is spinup and ≈1
CPU-day is the climate history.**

**THE OTHER TWO MULTIPLIERS, both real but smaller:** Nelder-Mead at n=26 (derivative-free is FORCED
because `h_ml` re-discretises the grid, and the **1055× sd ratio** is what makes the eval count
large), and **× 46 dispersed starts** — whose expected value is now lower than when the design was
set, since 09-01 and 09-02 both found ONE basin.

⇒ **~5× is on the table**, larger than any other speed lever here. ⛔ **Hazard: it would move the
OBJECTIVE if the two derivatives differ at all.** `test-parity.R` holds them together, but parity to
1e-9 is not bit-identical and a Newton solve amplifies — any substitution must reproduce stored
logposts to the port gate's own 1e-8 before adoption. ⛔ **And not while an array is running.**

## 2026-09-03 — ⭐⭐ **THE 26-PARAMETER REFIT IS RUNNING ON TORCH: job `16837149`**

Marcus's call, submitted over a live ControlMaster. `--array=0-45%10`, `cpu_short`, 4 h wall against
a 180 min task budget, out to `calibration/output/multistart_20260903_ent26/`.

**CHECKED BEFORE SUBMITTING, because reading the launch path found three places the 25 → 26 change
bites, not one:**
* `make_port_targets.R` migrates-then-encodes as well — so the seeding moved into the library as
  `ccx_seed_unencodable()`, beside the migration it completes. It stays **separate** from the
  migration on purpose: the migration says what the ancestor **RAN** (which is why every gate at a
  stored mode reads the same across 25 → 26), this says where a **SEARCH** begins.
* **PORT GATE (a) hard-stops on a parameter-count change by design** ("The target is stale").
  `port_targets.csv` regenerated at 26 parameters, at the run's own commit.
* `MS_SPREAD_ALL25` → `MS_SPREAD_ALL`; the sbatch outdir moved to `_ent26`, because the 09-02
  checkpoints are 25-name files and a directory that cannot collide beats leaning on the guard.

**MEASURED, NOT ASSUMED:** the `migrated` attribute survives element assignment, so
`ent_seas_amp_SH` lands in `MS_SPREAD_SKIP` and **the dispersion pool stays 19 coordinates at
sd 1.0466** — adding a parameter did not dilute the dispersion scale. Local preflight passed ids
0/1/2/25; the **Torch preflight batch (`16837134`, 8 tasks) passed PORT GATE (a) on real nodes at
rel 1.1e-12 – 1.2e-13** against a 1e-8 tolerance. No jobs of mine queued, `cpu_short` at 44 pending
/ 35 running, scratch 82 % with 617T free.

### ⚠ ONE DEFECT THE PREFLIGHT LOGS SURFACED, AND WHY IT IS NOT SHIPPED YET
The gate printed its own provenance as **`8.297e+87`**: `read.csv` parses the short hash `8297e84`
as a number. The **gate is unaffected** — it keys on `n_par` and the brackets, and the CSV on disk is
intact — but a provenance label that silently becomes a different string is the label-drift class
this project keeps paying for. Fixed locally with `colClasses` on the provenance columns.
⛔ **NOT SHIPPED WHILE THE ARRAY RUNS.** Pending tasks read the driver from `/scratch` at start time,
so re-shipping now would have tasks 10–45 running different code from 0–9 — a silent split of one
array across two builds. It goes up when the array drains.

### WHAT THE RUN IS FOR, restated so the result is judged on it
⛔ **NOT the logpost** — freeing a parameter cannot lower it. **P2**: does `sst_seas_amp_SH`'s
prior-z relax from **−5.14**? **P3**: does the SPO land limb come down from **2.48×**?
⚠ And the pre-registered risk: the refit may simply **move the strain** onto `ent_seas_amp_SH`
(conditional optimum sits at prior-z −3.41), which would falsify the hypothesis.

## 2026-09-03 — ⭐⭐ **FIX A SHIPPED: `ent_seas_amp_SH` IS FITTED (25 → 26), AND GATE S EXISTS**

Structural change **before** the refit, which is the ordering that cost 14 h once. Nothing is
adopted and no refit has been launched.

### ⭐ GATE S — the SPO **ocean** limb's **PHASE**, the bound the seasonal arc was missing
The model's SH ocean seasonal limb has been carried for weeks as "~5 months out of phase", and
**nothing scored it.** `co2_seasonal_SPO` IS a fitted stream, but it scores the **TOTAL**, which
the model already matches to ~1 % by cancelling a 2.48× land limb against a 0.63× ocean one — a
matched total has no power over the partition beneath it. GATE S scores the partition's phase.
* Target `SPO_SEAS_OCEAN_PHASE_INV` = 8.52 mo, registered 09-02, **not produced by this gate**.
  Its model-dependence is two δ¹³C signature SCALARS; the model's own seasonal phase never enters,
  and the registered CI was bootstrapped over years **crossed with the signature spread**.
* **Sigma DERIVED, not chosen**: (9.20 − 7.82) / (2 × 1.96) = 0.3520 mo. At `DG_S_NSD = 2` — the
  one strictness the distributional gates share — that reproduces the registered CI to 0.02 mo.
* The limb **amplitude is REPORTED and NOT bounded**: `SPO_SEAS_AMP_OCEAN_INV` carries no interval,
  so no bound is derivable and inventing one would be choosing a number after seeing the result.
* **Mutation-tested in both directions** (`test-gate-bounds.R`), including the circularity: months
  are an angle, so 0.1 and 11.9 are 0.2 apart, and a wrapped phase reads identically.

**FIRST MEASUREMENT, at the refit winner:** limb **0.3300 ppm @ month 4.19** against **0.522 @
8.52** ⇒ **z −12.30, FAIL.**

### ⛔ AND IT CORRECTED THE ARC'S OWN RECORDED NUMBERS
The handoff and memory carry this limb at **3.35 mo / 0.45×**, a 5.17-month miss, attributed to the
refit winner. Measured there with the shared estimator it is **4.19 mo / 0.632×**, a **4.33**-month
miss. Those recorded values belong to **earlier vectors** (the `h_ml` arc walked this limb
4.15 → 3.90). The direction and the verdict are unchanged; every RATIO quoted against 3.35 or 0.45×
is not. ⚠ Verified, not asserted: the GATE S kernel reproduces `lib_seas_limbs.R`'s `sl_score()` at
this vector to **4e-16** (amplitude) and **4e-14** (phase).

### ⭐⭐ `ent_seas_amp_SH` ENTERS `CCX_PARAM_TABLE` — 25 → 26
Implemented since 08-27g, **defaulted 0 and unfitted** — [[default_off_hides_the_bug]] in its
textbook form — while the worst prior violation was the solubility amplitude standing in for it.
* **Prior centre DERIVED and COMPUTED**: `ENT_SEAS_AMP_SH_DERIV` = **10.95** µmol/kg = the in-band
  **29.68** diluted onto the SH box by the now-registered `ENT_SEAS_BAND_AREA_FRAC`. Both scales are
  registered separately, because the recorded "5–30" band **mixes them**. (See the provenance audit
  below for why these are 10.95/29.68 and not 11.07/30.)
* **Width `ENT_SEAS_LOGSD` = 0.49848, DERIVED from a geometric ceiling.** ⛔ A uniform on [0, 40]
  was offered and rejected: an unpriored mechanism is a **free compensator**, and then a logpost
  gain says nothing about whether the mechanism is right.
* ⛔ **THE ACCEPTANCE TEST IS NOT THE LOGPOST.** Freeing a parameter cannot lower it. **P2** —
  does `sst_seas_amp_SH`'s prior-z relax from **−5.14**? — is the test. If it does not move, the
  hypothesis is wrong and solubility was never doing entrainment's job.
* ⚠ `tau_ex_seas_amp` is in the same defaulted-off state and was **deliberately NOT freed**, so P2
  has one mechanism to attribute to.

### ⭐⭐ PROVENANCE AUDIT (Marcus asked: does every test trace to an OBSERVATION or a LAW?)
Every number introduced by this arc, classified. **Four did not trace, and all four were mine.**

| number | class | verdict |
|---|---|---|
| `DG_S_OBS` / `_LO` / `_HI` / `_AMP_OBS` | OBSERVATION (inverted, provisional, stated) | ✅ |
| `DG_S_SD` = (HI−LO)/(2·1.96) | OBSERVATION + the *definition* of a 95 % interval | ✅ |
| `dg_mo_diff`'s 6 / 12 | DEFINITION (months are an angle) | ✅ |
| `DG_S_KO` | taken from `SL_CASES`, not retyped | ✅ |
| `DG_S_NSD = 2` | **CONVENTION** — the project's shared strictness, tied to `DG_Q_NSD` | ⚠ labelled |
| `ENT_SEAS_AMP_SH_INBAND` | said "derived", **value was TYPED `30`** | ⛔ **FIXED** |
| `ENT_SEAS_AMP_SH_DERIV` | re-typed the `30`; `0.369` free-floating in 3 files | ⛔ **FIXED** |
| `ENT_SEAS_LOGSD = 0.45` | rested on the band's **unsourced lower endpoint 5** | ⛔ **FIXED** |
| test gates `z ∈ (1.5, 2.5)`, `\|z\| > 10`, `< 0.05 mo` | **invented tolerances** | ⛔ **FIXED** |

**1. "Derived" must mean COMPUTED.** `ENT_SEAS_AMP_SH_INBAND` carried `value = 30` with its
arithmetic only in the prose `source` — labelled derived while being an independent copy, **the exact
`LAMBDA_C14` bug `constants.R`'s own header warns about.** Computing it from named inputs
(`.ENT_SO_SST_AMP` … `.ENT_REVELLE`) gives **29.68**, and the centre **10.95** rather than 11.07 —
the drift a typed "derived" value hides. Init moved 11.07 → 10.952353.
⚠ The chain's one thermodynamic input is Takahashi's 0.0423 /K; the rest is observation and geometry.
⛔ The Revelle factor is **deliberately not read off the model's own carbonate chemistry** — this sets
a PRIOR CENTRE, and a prior derived from the code under test can never disagree with it.

**2. `0.369` is now `ENT_SEAS_BAND_AREA_FRAC`**, registered **provisional** (a geographic area ratio
with no cited source, exactly as `OCEAN_AREA_NH/SH` are) — and a test guards the *label*, so anything
derived from it inherits that weakness visibly. It was a free literal in `constants.R`, `model.R` and
a test.

**3. ⭐ THE PRIOR WIDTH IS RE-DERIVED, 0.45 → 0.49848.** The approved 0.45 read the recorded "5–30"
band at 2σ — but **the number 5 has no derivation anywhere**, so the width rested on an unsourced
endpoint. It now comes from a **geometric ceiling**: the box mean cannot exceed the in-band amplitude,
reaching it only if every SH ocean square metre behaves like the observed band, so the no-dilution
limit sits at exactly `log(1/ENT_SEAS_BAND_AREA_FRAC)` = 0.99696 above the centre; read as the
family's 2σ that fixes the width. **The in-band value now lands at +2.000σ by construction**, and the
recorded band's own endpoints fall at z −1.57 (5) and +2.02 (30) — so the two readings **corroborate**
rather than compete, and neither is fitted to the other.
⚠ **Marcus approved 0.45 before this audit.** The change is a provenance repair, not a retuning — the
band both readings encode is the same to within a fifth of a sigma — and it is flagged, not slipped in.

**4. Invented test tolerances replaced by derivations.** `z ∈ (1.5, 2.5)` → the width tied to
`log(1/area)/2` plus the exact `z(in-band) = 2`; `|z| > 10` → `|z| > DG_S_NSD`, the gate's own bound;
`< 0.05 months` → the *exact* predictable gap, `(OBS − CI midpoint) ± (2 − 1.96)·σ`. Remaining
tolerances are **propagated typed precision** (half a unit in a literal's last digit), stated as such.

**5. ⭐ THE AUDIT CAUGHT ITSELF TWICE MORE, VIA THE REPO'S OWN LEDGERS.**
* `0.0423` — the Takahashi coefficient my chain named `.ENT_PCO2_DLNDT` — **was already registered
  as `SST_PCO2_SENSITIVITY`.** I had committed the exact duplication I was auditing for. Hoisted to
  one module-local that both entries now reference. ⚠ That entry warns about **double counting**
  against the carbonate module's own K0/K1/K2 temperature dependence; not a risk here, because the
  factor is used only in a back-of-envelope prior centre and never applied inside the model.
* `test-constants.R`'s **provisional ledger fired** on `ENT_SEAS_BAND_AREA_FRAC` — the mechanism
  working exactly as its own comments describe ("registering a provisional constant has to be
  deliberate"). Declared, with the reason, and both `ENT_SEAS_AMP_SH_*` are noted as inheriting that
  debt despite being labelled "derived".

**⚠ TWO INPUTS STATED RATHER THAN QUIETLY RECONCILED.** `.ENT_SO_SST_AMP` = 3.0 K is the **40–90 S
band**, *not* `SST_SEAS_AMP_SH_OBS` = 1.746 K (the SH hemispheric mean) — a different quantity, now
named apart so they cannot be conflated. And `.ENT_DIC_SURF` = 2150 µmol/kg is **uncited and sits
~5.6 % above the GLODAP surface value GATE G scores against (~2035)**; left as inherited because the
impact is measured and negligible — `log(2035/2150)/ENT_SEAS_LOGSD` = **0.11 σ**.

**⚠ THE PRE-EXISTING SET, CHECKED NOT ASSUMED.** Gates 4/5/7/Q/G trace to GCB 2025, Hua 2022, Quay
2003 and GLODAPv2 respectively; 12/12b is **already labelled** last-resort ("a threshold from another
model", Joos 2013, vintage stated). `DG_EFOLD_FLOOR = 20` ‰ is a DESIGN window, not an observation —
labelled. The weakest survivor is `test-gate-bounds.R`'s `0.9 *` in gate 5's spread guard: it encodes
the stated "biases the sd about 10 % low", so it has a rationale but not a derivation. **Left alone —
not mine, and not load-bearing for a verdict.**
⭐ **GATE S does NOT change the ledger's standing admission: there is STILL NOT ONE LAW-DERIVED GATE.**
It is observational, like every other one.

### ⚠ TWO CONSEQUENCES, NEITHER ROUTED AROUND
1. **`tr = "log"` has no 0**, so the channel's OFF state is not a point of the fitted space. A
   25-parameter ancestor migrates to **0 — what it RAN**, the same reasoning that migrated the ENSO
   ocean pair — and such a vector can be **RUN and MEASURED but not ENCODED**.
   `ccx_par_to_unc()` was **hardened** to refuse a non-finite encoding **by name and with the
   value**; it previously returned −Inf silently and would have handed a non-finite start vector to
   the optimiser three frames away. `run_dispersed_multistart.R` now **seeds** such a coordinate at
   its table init and prints both numbers — what the ancestor ran, and where the search begins.
2. **`ccx_default_params()` stays 0** and is therefore no longer encodable. Deliberate: the INIT is
   where the search starts, the DEFAULT is what an uncalibrated run does, and the mechanism is a
   hypothesis nothing has adopted. Flipping the default would move every "at defaults" number on
   the project for a mechanism nothing has accepted. **Flip it when the refit is adopted.**

⭐ **THE INVARIANT, ASSERTED IN THE DRIVER:** adding the parameter must not move a measurement at an
already-fitted vector. GATE S reads **bit-identical** across the 25 → 26 change.

### ⚠ A PRE-EXISTING LINT BREAK, FOUND AND CLEARED
`test-overlay-idiom-lint.R` had been **RED since this morning's `4f327cb`**: both 09-03 gate drivers
carried the bare `intersect()` idiom and were never added to the baseline (64 occurrences > 61).
Inert while stored vector and build both had 25 names; **live** the moment the table grew. All three
09-03 drivers converted to `ccx_overlay_par()` (convert-on-touch). Baseline count unchanged — they
were never on it.

### ⭐ THE CHANNEL'S LEVER, MEASURED — and it withdrew a caveat I had pre-registered
`calibration/diag_ent_conditional_lever.R`. ⛔ **CONDITIONAL: nothing re-optimised, every other
coordinate held at the refit winner, `sst_seas_amp_SH` included.** It measures the LEVER, not the fit.

| `ent` | limb amp | × obs | peak mo | z | GATE S |
|---|---|---|---|---|---|
| 0 | 0.3300 | 0.632 | 4.19 | −12.30 | FAIL |
| 5 | 0.1136 | **0.218** | 8.90 | **+1.07** | **PASS** |
| 11.07 | 0.6189 | 1.186 | 9.70 | +3.34 | FAIL |
| 30 | 2.2403 | 4.292 | 9.81 | +3.67 | FAIL |

* **(a) The lever exists.** The limb rotates 4.19 → ~9.8 months and crosses the observed window.
* **(b) ⛔ MY PRE-REGISTERED CEILING IS WITHDRAWN.** I had written that a limb inheriting the
  driver's 7.50 could not clear GATE S (7.50 is itself z −2.90). Measured: the limb **saturates near
  9.8, ~2.3 months LATER than the driver**, so it does not inherit the driver's phase and the
  reachable range **brackets** 8.52. The assertion in `test-gate-bounds.R` stands; the inference did not.
* **(c) ⚠ WHAT BINDS INSTEAD IS AMPLITUDE.** Where the phase is right (`ent` ≈ 5) the amplitude
  **collapses to 0.218×**: solubility at 4.19 and entrainment at 7.50 are nearly antiphase and
  **cancel**. Limbs are VECTORS. Conditionally the two cannot both be right — which is precisely
  what the refit is for, and precisely **P2**.
* **(d) ⚠ PRIOR vs PHASE DISAGREE BY ~2σ.** The phase-centring value is ≈5 (prior-z ≈ −1.8); the
  derived centre 11.07 puts the phase at 9.70 (z +3.34). The refit arbitrates; neither is moved by hand.

### ⛔ FOUR PREVIOUSLY-PASSING TESTS NOW FAIL, AND THEY ARE NOT MODIFIED
`test-enso-demean.R:105`, `test-enso-split.R:236`, `test-seas-lag-split.R:150` and `:174`. **All four
have the same single cause** and it is the design decision above: each MIGRATES an ancestor and then
**ENCODES** it, and a vector carrying `ent_seas_amp_SH = 0` is not a point of a log space.
⚠ In all four the encoding is **machinery, not the claim** (three compare migrated against
hand-built; one builds a fixture). ⛔ **Left failing for Marcus** — per the standing rule, a
previously-passing test is reported, not edited. Suite **1702 pass / 10 fail / 2 skip**; the other
**six are the pre-existing family** (five "stored modes are 21-parameter ancestors", plus
`test-likelihood.R:596`'s `kz$hi <= 7000` guard rail, failing since 09-01).
**THE CHOICE IS BETWEEN TWO MEANINGS OF A MIGRATED ANCESTOR:**
* **fill 0** (shipped) — *"it ran with the channel off"*. Truthful, and GATE S is **bit-identical**
  across 25 → 26. Cost: the migrated vector cannot be encoded.
* **fill the init** — *"it holds no opinion; start it at the prior centre"*. Cost: every measurement
  at a stored mode moves — GATE S at the refit winner would go z −12.30 → +3.34.

### ⛔ CORRECTION, MEASURED THE SAME DAY — I GOT TWO THINGS WRONG ABOVE
**(i) "fill the init → all ten go green" is FALSE. It fixes THREE of the four.** Measured
(`probe`, `diag_ent_conditional_lever.R`): `test-enso-demean.R:105` still fails, because its two
published anchors are **stale in a 26-parameter space no matter which fill is chosen** —
−1568.4936 → **−1880.10** and −1512.0151 → **−1829.09**, and Ruling A's headline gain
**+56.4785 → +51.0081**. That is the precedented consequence of a parameter-count change (the ENSO
split moved every stored logpost −4.777 and it was re-measured, not repaired).

**(ii) "one cause" is too strong.** Three are the ENCODER (`:174` asserts `all(is.finite(u))`
outright — *"the end-to-end claim the refit rests on"*; `:150` and `enso-split:236` use the encoder
merely as a comparison vehicle, and **both sides break equally**). The fourth additionally carries a
**stale logpost reference**, which no fill repairs.

**⭐ AND THE SHARPEST STATEMENT OF THE PROBLEM, which neither framing had reached:** under fill-0 the
ancestor's own state does not merely fail to encode — **it has prior probability ZERO.**
`dlnorm(0)` is 0, so a lognormal prior *asserts the mechanism is present*. A 25-parameter ancestor is
not at the edge of the new space; it is outside its support.

### ⚠ AND THE DATA, CONDITIONALLY, DO NOT WANT THE DERIVED AMPLITUDE
Profile along the axis at the refit winner, everything else held (prior term separated exactly):

| `ent` | logpost | prior term | likelihood | prior-z |
|---|---|---|---|---|
| 0.01 | −1581.35 | −98.79 | −1482.56 | −14.04 |
| 1 | −1492.09 | −11.75 | **−1480.34** | −4.80 |
| **2** | **−1490.13** | −6.04 | −1484.09 | −3.41 |
| 10.95 | −1788.44 | −0.22 | −1788.22 | 0.00 |
| 29.68 | −4042.26 | −2.22 | −4040.04 | +2.00 |

* ✅ **The prior is NOT choosing the physics.** The likelihood dominates by *hundreds* of log-units;
  it costs the prior only **11.53** to sit at the likelihood's own optimum. That was the live worry
  about an informative prior on a new mechanism, and it is answered.
* ⭐ **There IS a real likelihood gain from a small channel**: ~0 → 1 buys **+2.22** in likelihood.
* ⛔ **But the data want it 5–10× SMALLER than the derived 10.95**, and the conditional optimum sits
  at prior-z **−3.41**. ⚠ **RISK TO P2, pre-registered now:** the refit may simply **move the strain**
  from `sst_seas_amp_SH` (−5.14) onto `ent_seas_amp_SH` (−3.4) rather than relieve it. That outcome
  would falsify the hypothesis, which is what the pre-registration is for.
* ⚠ **CONDITIONAL, and that is the whole caveat**: every other coordinate is held at a vector fitted
  *without* the channel. The hypothesis is precisely that the fit re-arranges. This cannot decide it.

### ⚠ WHAT IS NOT DONE
The **refit is not launched** (Torch submission is Marcus's call), so P1–P5 are pre-registered and
unmeasured. Fix B's pCO₂-disequilibrium pre-test and Fix C's pulse partition on the Joos PD100
background are untouched.

## 2026-09-03 — ⭐ **THE 25-PARAMETER REFIT LANDED: ONE BASIN AT −1482.6144**

Torch jobs `16805561` (ids 0–19) + `16814121` (ids 20–45, resubmitted). **46 of 46 tasks
COMPLETED, 42 converged.** Results in `calibration/output/multistart_20260902_demean25/`.

| | logpost | n | converged |
|---|---|---|---|
| **cluster A** | **−1482.6144 / −1482.6145** | **38** | 35/38 |
| cluster B | −1482.7079 / −1482.7080 | 7 | 7/7 |
| outlier (id 26) | −1543.8553 | 1 | **0/1 — hit the wall** |

**THE GAIN, against every reference measured on the same objective:**
• vs the incumbent −1543.6880 → **+61.07**  • vs the 09-01 basin −1512.0151 → **+29.40**
• vs `new_basin` −1496.2524 → **+13.64**  • vs the best preflight point −1491.5671 → **+8.95**

⭐ **THE COLD INIT REACHED IT.** Id 0 starts at −18986 and lands on −1482.6144, the same value as
the warm starts — so the optimum is reachable without being told where it is.

### ⛔ CLUSTER B IS NOT A SECOND BASIN, AND THE OUTLIER IS NOT A THIRD
Measured on the same instrument the 09-01 survey used for its own "one basin" claim:
• within A, max pairwise u-distance **0.0119**; within B, **0.000748**; **A↔B 0.1712**.
• ⭐ **95 % of that separation is ONE coordinate: `h_ml`** (0.163 of 0.171). Everything else is at
  noise level. In physical units **148.33 m vs 154.00 m — 3.8 % apart, worth 0.0936 log-units**,
  against an h_ml spread WITHIN cluster A of 147.94–148.34 m across 38 tasks.
⇒ **A shallow `h_ml` ridge, which is the step-instability this project already knows about** — not
a basin. And **id 26 is one of the 4 tasks that never converged**, so its −1543.86 is an unfinished
run, not structure. **The survey found ONE basin.**

### ⛔ AND THE REASON THE 09-01 BASIN WAS NOT ADOPTED STILL APPLIES — ONE FLAG WORSE, ONE NEW
prior-z at the winner: **5 coordinates |z| > 2, three of them |z| > 3.**

| | 09-01 basin | refit winner |
|---|---|---|
| `sst_seas_amp_SH` | −4.71 | **−5.14** (worse) |
| `rep_dC` | +3.60 | +3.59 (unchanged) |
| `sst_seas_amp_NH` | not flagged | **−3.56 (NEW)** |
| `q10` / `npp_frac_NH` | — | −2.58 / −2.15 |

⚠ **BOTH seasonal SST amplitudes are now pushed hard below their priors**, which lands squarely on
the ACTIVE seasonal arc. ⛔ **This is an argument against adopting the vector as-is**, and adoption
is Marcus's call in any case — the driver writes `start_<id>.rds` and no mode file.
⚠ `fert_k` = **328.09** continues the 189→320 move; **the FACE re-check is still owed.**

### ⚠ AN OPERATIONAL NOTE, AND IT WAS NOT OURS
Array elements `_[20-45]` showed **CANCELLED by 0**. Not a limit and not the submission: at
2026-09-02T19:02:10 the scheduler purged **1,751 pending jobs across many users** cluster-wide.
Resubmitted as `16814121` and they all completed. ⚠ **The job ran under QoS `cpu48`** (2-day wall,
cpu=3000), **not `cpu_short`** — so the "cpu_short = 6 h / cpu=32" figure in memory is not the cap
that applied here.

## 2026-09-02q — **PRE-LAUNCH REVIEW: TWO THINGS WOULD HAVE CORRUPTED THE REFIT**

Marcus: check the model and the Torch launch code, then run the refit. The review found two live
hazards, both created by *today's* work, and neither would have announced itself.

### ⛔ 1. A 09-01 CHECKPOINT WOULD HAVE BEEN SILENTLY RESUMED INTO A DIFFERENT OBJECTIVE
`run_dispersed_multistart.R` refused a stale checkpoint on `param_names` — written 09-01j precisely
because the parameter set had moved twice in three days. **But 2026-09-02 moved the OBJECTIVE three
times at a CONSTANT 25 names** (T-dependent air-sea ¹³C alphas, the one-way GPP ENSO term, Ruling
A's demeaning). Verified against the real file: `start_000_ckpt.rds` carries **25 matching names and
no objective stamp**, so the guard would have **waved it through** and the task would have resumed a
pre-adoption `best` of −1495.795 into a post-adoption objective.

**The fix stamps the FIXED REFERENCE POINT's own value** (`ref_logpost`) into every checkpoint and
re-reads it at resume — derived from the objective itself, not a commit hash a comment-only commit
would move. **Mutation-tested in three directions**: a real 09-01 checkpoint (no stamp) is refused;
a stamp perturbed by 0.01 is refused with the delta named; the true stamp **resumes**, so it is not
a gate that can only fail. ⇒ [[recorded_but_never_restored]]

Belt and braces: the output directory is renamed **`multistart_20260902_demean25`**, because a
directory named for the parameter set alone cannot distinguish two objectives at 25 names.

### ⛔ 2. THE PORT TARGETS WERE STALE, AND THE PORT GATE WOULD HAVE FAILED EVERY TASK
`port_targets.csv` was measured 09-01 at `53ef03d`, before all three objective changes.
Regenerated at `eae5d92`. **The gate working, not a bug** — but it had to be re-cut before launch.

### ⭐ AND THE REGENERATION REVEALED SOMETHING: THE OBJECTIVE CHANGE REORDERED THE KNOWN POINTS

| point | 09-01 objective | today | moved |
|---|---|---|---|
| `start_000` (the 09-01 survey basin) | −1495.7950 | **−1512.0151** | **−16.22** |
| `new_basin` (08-31e, migrated) | −1500.0507 | **−1496.2524** | +3.80 |
| `incumbent` (08-30, migrated) | −1551.1222 | −1543.6880 | +7.43 |

**09-01: `start_000` beat `new_basin` by 4.26. Today `new_basin` beats it by 15.76.** ⇒ The
handoff's "the refit starts from −1512.02" names where Ruling A was *priced*, **not the best
available start** — and a ranking that flips under an objective change is the argument for
re-running the **dispersed survey** rather than warm-starting one basin. The driver's existing
ids 0–5 already carry `new_basin` and its ENSO-seeded variants, so no design change was needed.

### CLEAN
The model sees ENSO only through `forc$enso`, one demeaning point; `ccx_spinup()` sets it to 0.
The run-input manifest is still complete — re-checked with the grep its own header prescribes,
since today added `EIX_ERSST_V6` (a *calibration* read, not a run-time one).

## 2026-09-02p — **THE v6 GRID CLOSES §4, AND MY OWN "FINDING" LASTED TWO CONTROLS**

Marcus: **pull it.** 90 MB, `downloads.psl.noaa.gov/Datasets/noaa.ersst.v6/sst.mnmean.nc`,
registered in `MANIFEST.csv` and — for the first time — in `download_data.R`, which had **never**
carried the v5 grid either (it was fetched by hand, so "re-fetchable from `download_data.R`" was
false of it). Both are there now. Same 2° grid, same `days since 1800-1-1` epoch, same variable
names as v5, so `eix_ersst_box()` takes it unchanged — **gated (V-G), not assumed**.

### Q1 — IS THE 15 % AMPLITUDE GAP A VERSION EFFECT? **PARTLY, AND ONLY PARTLY.**
Deseasonalised over 1991–2020, `nina34.data` sits closer to the v6 grid than to v5
(|slope−1| **0.1116 vs 0.1577**, 1.41×), so the version naming is **not wrong** — but it is not the
story either. The two grids differ by only **5.1 %** (slope 0.949) while `nina34.data` is still
**11.2 %** off v6, and the **+0.60 °C climatology offset barely moves** (v6−v5 is +0.039 of it).
⇒ **The level offset is essentially NOT a version effect.** The gate that licensed this is an
**ORDERING** — the two disagreements compared with each other — because no external number exists
for how much better v6 ought to agree. ⇒ [[threshold_from_obs_or_law]]

### Q2 — DOES AN UNCLIPPED ROLLING BASE BEAT `demean`? **NO. AND THE FIRST ANSWER WAS AN ARTIFACT.**
The v6 grid reaches 1850, so its rolling base clips **3 of 16** scored blocks against nina34's
**6 of 16** (V-U). Raw, the unclipped rolling base beat demeaning **within v6 by +43.38** — which
would have reopened a ruling adopted the same day. **It did not survive two controls:**
- **AMPLITUDE** (rescale demean_v6 to roll_v6's sd, convention unchanged): **+2.76**. Small.
- ⭐ **COVERAGE**: both v6 candidates supply ENSO for **1850–1947**, where the shipped model has
  `FORC_ENSO_PRE1948 = 0`, and the PSL pair they were being set against has no such extension.
  Truncated to nina34's own span, roll − demean = **−5.12**. ⇒ [[like_for_like_forcing]]

**The like-for-like sign matches the PSL pair (−1.91) and `detrend` (−1.78). RULING A STANDS.**

### ⭐ TWO RESULTS THAT FELL OUT OF THE CONTROLS
1. **Extending the ENSO forcing before 1948 costs −49.21 under a fixed 1991–2020 base and −0.71
   under a rolling one.** The fixed base carries its mean-state offset through all 98 added years.
   ⇒ **If the forcing is ever extended pre-1948, it must use a rolling base.** A price, not a ruling.
   ⚠ This confound was invisible until now: the baseline diagnostic's `roll_full` had exactly the
   same coverage mismatch and was never priced, because G-P refused it.
2. **With convention AND span matched, the v6 grid and `nina34.data` land 0.55 log-units apart.**
   So the 15 % amplitude gap costs the *shipped* configuration far less than §1 suggests.

`calibration/diag_enso_v6_provenance.R`, three gates (V-G grid, V-C ordering, V-U unclipping), and
it says in its own header that a win would be a **reopening for Marcus, not an adoption**.

## 2026-09-02o — ⭐ **RULING A ADOPTED: THE ENSO INDEX IS DEMEANED**

Marcus, this session: **adopt `demean`, then refit.** Shipped in `ccx_build_forcing()`'s ENSO
branch behind `FORC_ENSO_DEMEAN` (TRUE) over `FORC_ENSO_DEMEAN_WIN = c(1948, 2024)` — the span the
bake-off priced.

**WHAT IT IS WORTH, MEASURED THROUGH THE LIVE BUILDER, NOT THE BAKE-OFF'S WRAPPER.** At the 09-01
basin vector, unrefitted: `FORC_ENSO_DEMEAN = FALSE` gives **−1568.4936** and TRUE gives
**−1512.0151**, a gain of **+56.4785** — the published pair back to 3 × 10⁻⁵, i.e. inside their own
printed precision. That is **86 % of the one-way GPP term's −65.74** recovered by removing a
base-period artifact.

**THE MEAN IS TAKEN OVER THE INDEX'S OWN RECORD, NOT THE REQUESTED RUN WINDOW.** A mean that moved
with `yrs` would make a 1750–2300 build and a 1948–2024 build see different ENSO, silently, and
every stored logpost would depend on the span it was scored over.

**`FORC_ENSO_DEMEAN = FALSE` reproduces the pre-adoption model bit for bit** — the same reproduction
path `ALPHA_AS_*_LEGACY` has. It is not a tuning knob.

### ⚠ A GATE I WROTE HAD NO POWER, AND THE MUTATION TEST CAUGHT IT
`test-enso-demean.R`'s SPAN-INVARIANCE test first compared a 1750–2024 build against a 1948–2024
one. **That pair cannot fail**: the ENSO index starts in 1948, so both windows select the same index
rows, and a mutation that demeaned over the *requested* window instead of the fixed one **passed
unchanged**. The second span now cuts *into* the record (1980–2024) and the mutation fails as it
must. Four gates, all mutation-tested: INTENT (mean is zero), IDENTITY (legacy exact; the change is
a *constant*, and a non-zero one, so the gate cannot pass vacuously), SPAN-INVARIANCE, and the
PRICED anchor above. ⇒ [[no_power_null]]

### AND ONE THAT WOULD NOT HAVE RUN AT ALL
The priced anchor guarded itself with `skip_if(!exists("dg_vector"))`, which under `test_dir()`
**skipped it in every full-suite run**. It sources the lib it needs instead.
⇒ [[broken_gate_reports_nothing]]

### THE DIAGNOSTIC'S OWN GATE FOLLOWED THE MODEL
`diag_enso_index_baseline.R`'s **G-I** hard-stops unless the wrapper is a no-op on the shipped
index. Hardcoded to `asis`, adoption would have turned it into a permanent refusal. It now reads
`EI_SHIPPED_TREATMENT`, which follows `FORC_ENSO_DEMEAN`, and asserts that the priced window equals
the shipped one. Re-run post-adoption: **G-I PASS, bit-identical on `demean`**, every treatment
price unchanged, G-M now −792.37 (it mutates a demeaned baseline).

**`asis` IS NOW THE PRE-ADOPTION INDEX**, not the shipped one, and is relabelled as such in the
bake-off and in `eix_nino34_shipped()`'s header. Leaving those captions alone is the drift this
project keeps paying for.

**Suite 1622 PASS / 6 FAIL / 2 skip** — failure set byte-identical to standing. No test in the suite
pinned an absolute logpost against a stored mode, so nothing else moved.

⇒ **NEXT: the 25-parameter refit, starting from the `demean` vector (−1512.02, not −1568.49).**

## 2026-09-02n — **THE FOUR SPO CONSTANTS ARE REGISTERED, AND TIED TO THEIR 34 COPIES**

Handoff 09-02k §8.5's standing debt, discharged. The four numbers the whole seasonal-partition arc
is scored against — observed SPO total **1.168 ppm**, land limb **0.683**, ocean limb **0.522**,
ocean peak month **8.52** — were file-local literals in **14 diagnostics** and in `R/constants.R`
nowhere. `lib_seas_limbs.R` had extracted the *estimator* for this arc in August and deliberately
left the constants alone, saying registering them was "a constants-registry decision". This is that
decision.

**REGISTERED AS `SPO_SEAS_*`**, seven entries — the four above plus the land peak month **9.29** and
the ocean phase's 95 % bootstrap bounds **[7.82, 9.20]**, because `diag_so_pco2_phase.R` scores
against those bounds and a gate's target may not be a literal in the gate (the
`AIRSEA_D13C_DISEQ_OBS` precedent).

**SIX OF THE SEVEN ARE `provisional`, AND NOT FOR WANT OF A SOURCE.** They are observations
**inverted through the model's own δ¹³C signatures** — exactly `NPP_FRAC_NH_ANCHOR_1750`'s standing,
and the ledger is where a model-dependent target stays visible. The dependence is measured and small
(re-inverting at a different `tau_ex` moved the land limb −1 %). The **total is not** on the ledger:
the inversion closes `CO2 = L + O` on the observed total, so no model enters it.

**AND THE TOTAL WAS RE-MEASURED MODEL-FREE** rather than copied forward: `1.1684`, SPO first
harmonic, magnitude-of-mean-vector, 44 years 1979–2023. It confirms the literal exactly.

### ⛔ A CLOSURE GATE CONSIDERED AND REFUSED
The two limbs' vector sum at the printed values is **1.181**, i.e. **1.1 % above the total**, where
the printed rounding admits only ±0.002 — six times the envelope. That looked like an inconsistency
worth gating. It is not one: **the reported limbs are bootstrap MEDIANS of 2000 draws**, and a median
does not commute with the nonlinear `amp()`/`ang_mo()`. At the point estimate the identity holds by
construction. **No gate was written**, because the only bound available would have been the residual
itself — [[gate_reads_its_own_output]]. The arithmetic is recorded in `R/constants.R` so the next
reader does not mistake it for a defect and "fix" a limb to make it close.

### THE TIE, NOT A BULK CONVERSION
`tests/testthat/test-spo-constants-tie.R`. The copies are **not** converted in bulk — several
callers are pre-registered artefacts whose scored gates may not move under a refactor
(`diag_admissible_2x2_land_ocean.R` is the explicit case). So this follows Marcus's Ruling B idiom:
**convert on touch, and let a ratchet make the count go one way.** Three assertions over **34
copies in 14 files**, the middle one load-bearing:
- **TIE** — every copy equals the registry, **exactly** (it is an identity, so the bound is exact).
- **NO-STALE** — a listed declaration that is *gone* also fails, so converting a file forces its
  removal and the list can only shrink.
- **SUBSET / NO-GROWTH** — no unlisted top-level constant in `calibration/` carries one of the
  values, and the count may not rise.

It **parses** each diagnostic rather than sourcing it (these files run the model), and evaluates
only numeric literals and `c()` of literals. **Mutation-tested three ways**: moving a registry value
fails TIE across every copying file; converting one declaration to `ccx_const()` fails NO-STALE;
appending a new copy fails SUBSET. Restored, it passes 61.

**Suite 1611 PASS / 6 FAIL / 2 skip** — failure set byte-identical to standing (5 × the
21-parameter-modes-in-a-25-parameter-build mismatch, plus `test-likelihood.R:587`'s `kz$hi <= 7000`
guard rail left for Marcus). ⚠ The pass count is **not** comparable to 09-02k's 1515: that run quit
at the default max-fails; this one sets `max_fails = Inf`, so more of the suite actually ran.

## 2026-09-02m — **RULING 4 OF 4: AND THE RE-RUN FOUND A LIVE BUG THE HANDOFF HAD MIS-DIAGNOSED**

Marcus: fix `diag_gamma_iav.R`, quarantine, re-run both. The quarantine landed in 09-02j. This is
the rest — and the re-run did not go as expected.

**`diag_gamma_iav.R` FIXED.** It read `md$par_mode` RAW and then ran the `intersect()` copy loop, so
on a pre-split 21-parameter ancestor all four `gamma_enso_*` names were **deleted** (assigning NULL
drops the element) and **every scan ran with ENSO OFF** — including the q10 scan whose whole point is
whether the explicit ENSO term absorbs q10. Re-run with the mechanism on, and it now prints its four
ENSO coefficients and **asserts they are not all zero**. ⚠ Its Q3 sweep is now labelled as what it
is: a **scalar SLICE through a four-dimensional space**, and its `sd_unc` numbers are named as
**21-parameter posterior sds used in a 25-parameter build**.

## ⛔ AND THEN `diag_gross_cancellation_geometry.R` REFUSED TO RUN — CORRECTLY

Its own **G0 reproduction gate** hard-stopped it: NEP **1.3807 @ 10.66 mo** against the 08-27n
reference **1.3950 @ 10.15**, i.e. 1.03 % on an amplitude tolerance of 1 % and **0.51 months on a
phase tolerance of 0.05**.

**THE FIRST QUESTION WAS WHETHER TODAY'S ENSO CHANGE CAUSED IT. IT DID NOT** — measured, not
assumed: the same file on the pre-change worktree gives **1.3777 @ 10.66**. My change moved the
amplitude by 0.2 % and the phase not at all. **G0 was already failing.**

**THE SECOND QUESTION WAS WHETHER THE FIXTURE WAS STALE, AND IT WAS NOT.** Forcing
`seas_lag_p_NH = _SH = 1.7677` reproduces 27n at **1.3970 @ 10.15** against its recorded
1.3950 @ 10.15 — **0.14 % and 0.00 months**. And the 1.3807 @ 10.66 the file was reporting is
**exactly the lag-2.25 row of that same profile**.
⇒ **THE FIXTURE WAS RIGHT AND THE CODE WAS WRONG.** A "stale fixture" label would have buried it —
which is precisely [[explained_away_test]].

**THE DEFECT.** `ccx_mode_params()` returns `par_mode` RAW; `from90` is pre-split, so it carries the
legacy `seas_lag_p` scalar and NEITHER split name. The copy loop **deleted both** from a
`ccx_default_params()` that carries no legacy scalar either, and `ccx_seas_lag_p()` fell through to
the **NAMED DEFAULT, 2.25**. **Every run in that file used lag 2.25 while its own header printed
1.7677**, read off `pv0` rather than off the parameters the model actually got — **a caption-sync bug
sitting on top of a silent-default bug**.

⚠ **AND THE HANDOFF'S DIAGNOSIS OF THE FLAT LAG SWEEP WAS INCOMPLETE.** `95e97ab` fixed section 5b's
grid and **missed G5's lever list**, which still named the retired scalar — so after migration was
added it died on a length-zero argument. G5's levers are now **SETTERS, not names**: each says which
FIELDS it writes and which parameter-table entry supplies its prior, and 5b reuses G5's setter so
there is one definition of "sweep the lag".

**⭐ THE RESULT CHANGED.** With the baseline at the mode's lag and the sweep live, the lag axis runs
**115.2° at 0.50 to 176.1° at 2.75**, the mode marked at 1.75, against a needed **164.8°** ⇒
**"`seas_lag_p` CAN reach the needed separation — it is the second member of the pair."** The
pre-fix file read its maximum off a flat curve. All gates now score: **G0 PASS, G1 PASS, G2 PASS,
G3 UNREACHABLE, G5 lever exists.**

## ⛔⛔ THE BLAST RADIUS, MEASURED RATHER THAN ASSERTED — 49 SITES

`grep` for the idiom and classify by whether the site **migrates first**:

| | sites |
|---|---|
| **MIGRATES (safe)** | **8** — including **`R/calibrate.R`**, the refit harness, and `lib_design_gates.R`, so **every gate number and every fitted result is unaffected** |
| **does NOT migrate, but calls `ccx_set_enso`** | **37** |
| **does NOT migrate, repairs nothing** | **12** |

⚠ **`ccx_set_enso()` IS NOT A FIX FOR THIS**, and that is the sharpest form of it: it repairs the
ENSO names only, so those **37 files look safe and still run at lag 2.25**. The 12 additionally run
with ENSO at zero.
⚠ **49 is an UPPER BOUND on the affected set**, not a confirmed count — a site only bites if it
loads a pre-split mode file through this idiom. `CCX_MODE_CANONICAL` **is** `from90`, a 21-parameter
ancestor, so most will.

**✅ THE FIX HAS A HOME NOW: `ccx_overlay_par(p, pm)`** — migrate, copy, repair, then **ASSERT THE
OVERLAY DELETED NOTHING**, hard-erroring with the names if it did. The assertion is the point; the
rest is the idiom everyone already writes. The two files fixed today use it, and
`test-gate-bounds.R` (now **48 assertions**) carries the regression: it demonstrates the bare idiom
deleting the names and landing on the default, then the helper landing on the mode's.
⛔ **THE OTHER 49 SITES ARE NOT CONVERTED. That is Marcus's call, not a silent 49-file refactor.**

## 2026-09-02l — **RULING 3 OF 4: GATE G, AND THE FIRST DESIGN FOR IT WAS PARTLY CIRCULAR**

Marcus's pick if only one gate got built: an ocean DIC gate against GLODAP, because gate 12a
reports an ocean-CAPACITY defect it cannot LOCALISE and nothing in the repo tests the ocean's
absolute DIC against an observation.

**⛔ THE OBVIOUS DESIGN — "the whole-column inventory" — IS PARTLY CIRCULAR, and it was caught
before it shipped, not after.** The biological pump's export field was SOLVED to hold
`DIC_ml(model) + [DIC_k(obs) − DIC_0(obs)]` as an exact steady state: the OBSERVED GRADIENT,
anchored on the model's own mixed layer. So the profile's SHAPE is GLODAP-derived by construction,
and an inventory gate would partly read back what built it — [[gate_reads_its_own_output]], which
is the same failure GATE Q committed on 09-02 morning. (Not WHOLLY circular: the pump's magnitude
carries a prior and the model's gradient comes out ~13 % LARGER than observed. So the inventory is
REPORTED, with this said, and **not bounded**.)

**✅ WHAT IS OUT-OF-SAMPLE, CHECKED RATHER THAN ASSUMED: THE MIXED-LAYER DIC LEVEL.** The
likelihood's three ocean rows are GRADIENTS with fitted offsets (`R/likelihood.R:1541`), and a
gradient with a fitted offset is blind to the level; `d14c_deep_ocean` is Δ¹⁴C, not DIC;
`gcb_ocean_sink` is a FLUX, not a stock. The model's surface DIC comes from carbonate equilibrium
with the 1750 atmosphere at `ALK_SURFACE`, a fixed constant whose own status string still says it
"NEEDS a cited global-mean surface value". **Nothing that produced the model's surface DIC level
ever saw this observation.**

**AND IT IS THE RIGHT PLACE TO LOOK FOR AN OCEAN-CAPACITY DEFECT**: the surface Revelle factor is a
function of surface DIC and alkalinity, so a level that is right bounds gate 12a's defect AWAY from
the surface carbonate state.

**THE RESULT: PASS at every arm.** At the bottles' own epoch (**2002.4**, derived from the data, not
typed) the observed 0–96 m volume-weighted DIC is **2034.9 µmol/kg** and from90 gives **2045.7**,
**+10.8 µmol/kg = +0.61σ**. defaults +0.81, pin90 +0.41. Column inventory **36,948.5 GtC** against
an observed 36,990.8 (**−0.11 %**); anthropogenic uptake 1750→2002 **+148.9 GtC**.
⚠ **LIKE-FOR-LIKE IN TIME IS NOT FREE**: GLODAP bottles are MODERN, so the model is run to the
bottles' mean year. Comparing the 1750 spinup column (1996.3) with a modern observation would have
shown the anthropogenic increment as a **−38.6 µmol/kg model defect**.
⚠ **THE SIGMA IS A CONVENTION, AND THE REPORT SAYS SO WITH A WALK.** It is an SE at
`LIK_D14C_DEEP_NEFF` = 20 — the n_eff Marcus ruled on 2026-08-14 for the deep Δ¹⁴C target, borrowed
rather than re-chosen. That n_eff was picked for the ABYSS, where water masses are basin-coherent;
the surface is better sampled, so borrowing it is **CONSERVATIVE — it makes this gate more lenient
than the surface data warrant**. The report walks n_eff 5/20/100/500: z runs +0.30/+0.61/+1.35/+3.03,
so **the verdict flips at n_eff ≈ 500**. Stated, not exploited.

**⭐ AND IT HAS DEMONSTRATED POWER, ON THE MODEL AND NOT ONLY ON ITS OWN OUTPUT.**
`calibration/diag_gate_g_mutation.R` walks `ALK_SURFACE` and the gate **FAILS at ±2 %** while
passing within ±1 % (−3.67σ at ×0.96, +2.74σ at ×1.02). The measured elasticity is **R = 0.932 %
of DIC per % of ALK** — near 1, which is what carbonate equilibrium at fixed pCO₂ predicts, so the
mutation reaches the gate through the physics the header claims and not through some other path.
⇒ **GATE G bounds a PROVISIONAL constant observationally at ±2 %**, which is the first quantitative
handle this repo has had on `ALK_SURFACE`. The mutation is restored and **the restoration is
checked**, not assumed.
⚠ A trap worth naming: the first run failed with "object 'CCX_CONSTANTS' not found" because the
loop runs at TOP LEVEL, where `<<-` starts its search in globalenv's PARENT — the attached packages
— and never finds it. **A superassignment at top level is not "assign globally".**

**⭐ AN EXTRACTION THE GATE FORCED, AND IT IS NOT TIDINESS.** GATE G needs the GLODAP binning
helpers, and `calibration/pump_shim.R` **cannot be sourced to get them**: it wraps `ccx_deriv()` in
the global environment, so sourcing it into a gate report would change the model the gates are
measuring. The alternative — a second copy of the binning — is the caption-sync bug class
(`dg_annual_sinks` was extracted 08-31 for exactly this). The three pure helpers moved VERBATIM to
**`calibration/lib_glodap_obs.R`**, which is safe to source twice because it has no wrapper to
re-capture. `pump_shim.R` now sources it.

**THE LEDGER'S "NOT ONE LAW-DERIVED GATE" FINDING STILL STANDS.** GATE G is OBSERVATIONAL. What it
does is put an observation ON the surface carbonate state — the quantity a Revelle or Henry's-law
gate would test — so it **narrows the hole without closing it**. Carbonate/Revelle consistency and
Henry's-law solubility remain unbuilt, and the printed ledger says so.

**`tests/testthat/test-gate-bounds.R` is now 40 assertions.** GATE G's include the one that matters
most: **wrecking the inventory must leave the verdict untouched** (`expect_equal(a$z, b$z)` with
`inv = 10000`), which is the circularity guard turned into a test rather than a comment.

## 2026-09-02k — **RULING 2 OF 4: GATES 4 AND 5 GET BOUNDS; GATE 7 STOPS OUT-JUDGING THE FIT**

**GATE 7 NOW JUDGES AT THE OBJECTIVE'S OWN SIGMAS.** The 09-02i ledger found its standing FAIL
was a STRICTNESS MISMATCH: the likelihood scores the land sink at `LIK_GCB_LAND_SD *
LIK_LAND_SINK_INFLATE` = **1.50** GtC/yr and the gate judged the same stream on the same data at
**0.50**. ⚠ **The ocean sigma is NOT inflated in the likelihood** (`R/likelihood.R:1608-1612`), so
the two halves take different sigmas and that asymmetry is the objective's, not the gate's.
`DG_G7_NSD` 1 → **2**, harmonising with `DG_Q_NSD` and the new `DG_G5_NSD`. **All three arms now
PASS** (from90 land **+0.72**, ocean −0.55), and the report still prints the BARE-sigma reading
(+2.15) because that is what every pre-today result quoted.
⚠ **It is still not an independent test.** Aligning a sigma cannot make a restatement
out-of-sample. The ledger now says so where it used to say the FAIL was a mismatch.

**⭐ AND THE VERDICT ITSELF IS FINALLY CENTRALISED.** `dg_gate7_verdict()` — the z-scores and the
pass rule were computed INLINE in both callers while the file's header claimed "one kernel, two
callers". The kernel was centralised 08-31f; the verdict was not.

**GATE 4 GETS AN ORDERING, AND NO THRESHOLD.** Its own stated claim is "must not be SMOOTHER than
this", which is an ordering between two measured quantities, and an ordering gets no threshold —
inventing one would be choosing the physics. **All three arms FAIL**: decadal AF spread
defaults 0.039 / from90 **0.032** / pin90 0.041 against GCB's **0.051**. That is the variability
gap, now gated.
⚠ **THE AF LEVEL STAYS DELIBERATELY UNBOUNDED** and the report says why: it is near-algebraic in
quantities the objective already fits, so a bound would test the optimiser, not the model.

**GATE 5 GETS TWO ORDERINGS AND A DERIVED SIGMA.** ⛔ Hua 2022 publishes no sigma on a hemispheric
peak time or on the NH→SH lag, so one had to be **derived, not typed**: the aggregate is a weighted
mean over Hua's ZONES, so re-running the same estimator with one zone left out at a time gives the
spread its own spatial composition carries — **NH 0.444 yr (4 draws), SH 0.338 (3), lag 0.494 (12)**.
⚠ **A trap avoided, and it is worth naming**: pooling the hemispheric quantities over all 12
(NH-drop × SH-drop) COMBINATIONS repeats each value and biases the sd about **10 % LOW**, which
would have made the gate quietly stricter than the data warrants. Each hemisphere's spread is taken
over its own distinct draws; only the lag, a function of both, uses the combinations.
Result: **all three arms FAIL on the NH peak time (+2.11 to +2.15 sigma, ~0.95 yr late)** — the SH
is inside at +1.72 to +2.10 and the lag is comfortably inside at −0.45 to −0.75. The two
threshold-free orderings (SH peaks AFTER NH; NH peak HIGHER) pass everywhere.
⇒ **The gate localises what was previously a table: the miss is the NH PEAK TIME, not the lag.**

**✅ ALL THREE BOUNDS ARE MUTATION-TESTED, PERMANENTLY** — `tests/testthat/test-gate-bounds.R`,
29 assertions. Each is exercised in BOTH directions, which matters because gates 4 and 5 currently
fail at every arm and **a gate that can only fail is as uninformative as one that can only pass**.
Gate 4 passes a rougher model and fails a smoother one, and passes exactly AT the observation
(the claim is ">=", not ">"). Gate 5 passes a synthetic model built FROM the observation, fails a
peak pushed past the bound **on the z clause and not the ordering clause** (a mutation that trips
the wrong clause is no test of this one), and fails each ordering when inverted. Gate 7 pins
`DG_G7_LAND_SD` to the likelihood's own product, so a change in `R/likelihood.R` fails here rather
than letting the gate drift away from the fit. The draw counts (4/3/12) are pinned too: if the zone
definitions change, every gate-5 tolerance silently re-scales, and this fails instead.

## 2026-09-02j — **RULING 1 OF 4: THE ENSO LAND TERM IS NOW A ONE-WAY GPP MODULATION**

Marcus ruled all four of the 09-02i handoff's owed rulings. This is the first, and it is the
one that had to land before the refit because it changes what gets fitted.

**THE CHANGE.** The ENSO land anomaly was ONE SIGNED FLUX out of `soil_fast` at `alpha13 = 1`,
whose reverse limb ran atmosphere → `soil_fast`: a land uptake that never passes through
vegetation. For the SH that reverse direction was the **MAJORITY** direction — 61 % of
ENSO-active months, 44.5 GtC against the forward limb's 21.7 — and `add_flux`'s guard is
STRUCTURALLY BLIND to it (it fires on `alpha13 != 1`, so it can never see a reversing flux that
*should* fractionate and does not). It is now folded into the two GPP limbs as a modulation that
cannot reverse, **split by `npp_leaf_frac`**, in both cores. **No new fitted coordinate; still
25 parameters.**

**WHY GPP AND NOT RESPIRATION, given 09-02i proved the data cannot tell them apart.** Because
it is a PHYSICS choice, not a fitted one, and the model already has a respiration path (`q10`
on GMST, worth 3.2 % of the term) and **no moisture path at all**. The GPP/moisture limb is the
one that is missing. Fire stays unrepresented either way.

**⭐ THE PRICE, MEASURED PROPERLY: −65.74 log-units at fixed parameters** — and the diagnosis
matters more than the number. `calibration/diag_enso_gpp_margin.R` runs twice, once in a git
worktree at the pre-change source, and refuses to report anything if the two runs share a
**model-source fingerprint** (the first attempt caught itself this way: the commit hash was
identical because the change was uncommitted, so the guard now hashes `R/model.R` +
`src/ccx_core.cpp`, not `git rev-parse`).

**⛔ THE COST IS NOT ISOTOPIC AND IT IS NOT A BUG — IT IS A PROPERTY OF THE FORCING.** The two
structures put the SAME net carbon into the SAME atmosphere at every instant, so −65.7 needed a
diagnosis before it could be accepted. By stream it is paid almost entirely in CO2 LEVELS
(MLO −33.8, SPO −20.2) for a **0.58 ppm** shift in CO2_NH(2024), not in the isotopes
(d14c_NH −0.02, d13c_NH moved 0.0004 permil). The cause:

* **the ENSO index is NOT zero-mean** — mean **−0.218** over 1948–2024, identically 0 before,
  so the two structures are bit-identical pre-1948 and the whole difference is post-1948;
* a sustained anomaly loads onto **different pools**: the old form onto `soil_fast` alone
  (**tau 2.0 yr**), the new form onto the whole land chain (**veg 8.6 + soil 26.9 = 35.5 yr**);
* the arithmetic: +0.083 GtC/yr sustained x (35.5 − 2.0) yr = **+2.77 GtC = −1.31 ppm**, against
  a measured −0.58 ppm. Same sign, 2.3x over — expected, since the estimate is a full
  equilibrium while the anomaly has run 76 yr against a 36 yr constant, with the ocean and CO2
  fertilisation damping it.

⇒ **THE SAME COEFFICIENT MEANS SOMETHING DIFFERENT IN THE TWO STRUCTURES**, so −65.74 is an
UPPER BOUND a refit should largely recover.
⚠ **AND IT SURFACES A CHOICE NOBODY HAS MADE: should the ENSO index be DEMEANED over its
non-zero span?** Under the old structure the mean was nearly inert; under the new one it is a
~1 ppm lever. **NOT RESOLVED — for Marcus.**

**✅ THE MARGIN, because folding into a gross flux buys one-wayness at the price of a new way to
go negative.** Peak |anomaly| against the hemisphere's own preindustrial gross GPP limb:
NH **1.42 %**, SH **14.45 %**. It would take a gamma about **7x** the fitted one to shut
photosynthesis off. `ra_ratio` is 0 in this arm, so the gross limb IS `npp` and adds no headroom.

**THE `enso` FLUX CHANNEL WAS RETIRED WITH IT** (`R/fluxes.R`). The term no longer names an edge,
so a channel for it could only ever report zero — the silent-gate shape. `land_net` drops its
`- ch[["enso"]]` term (the anomaly is now inside `gpp`; subtracting it would remove it twice).

**A TEST WAS DELIBERATELY REPLACED, NOT SKIPPED.** `test-fluxes.R`'s `any(fl$enso != 0)` pinned
the exact design being changed. Its replacement is **stronger**: `expect_false("enso" %in%
names(fl))` (retired, not merely empty) plus a new test that the term actually MOVES `gpp`, with
a **sign check** at the largest-|index| month — El Nino must SUPPRESS photosynthesis. A dropped
label can only be dropped; a modulation folded into another flux can be silently ZERO, which is
the failure mode that actually bit twice on 09-02.

**Suite 1459 PASS / 6 FAIL / 2 skip**, failure set byte-identical to the standing one (5 x the
21-vs-25 parameter mismatch, 1 x the `kz$hi <= 7000` guard rail left failing for Marcus). The
+2 is this change's two new assertions.

**ALSO LANDED, no judgement required:** the quarantine ruling 4 asked for —
`outputs/quarantine/20260902_mechanism_off/` with a README naming the retired-`seas_lag_p`
bug, the files, and the canonical replacement path; and the 09-02 note that contradicted
itself (**+18.7 %** in its title line against **+42.4 %** in its body, off the same 1.424 → 1.621
column) now says +42.4 % with the correction recorded in place.

## 2026-09-02i — **THE ENSO PRE-CHECK REFUTED THE ARGUMENT I MADE FOR IT; THE GATE LEDGER**

Marcus asked for both: price the two-channel ENSO restructuring, and start a gate ledger.

**⛔ I ARGUED THE TWO CHANNELS WOULD BE ISOTOPICALLY IDENTIFIABLE. THEY ARE NOT, AND THE
PRE-CHECK WAS WRITTEN TO BE ABLE TO SAY SO.** `calibration/diag_enso_two_channel_precheck.R`,
~40 s, IMPLEMENTS NOTHING. A respiration limb draws `soil_fast` at −24.9 to −26.4 permil; a
GPP limb withholds carbon at delta_atm + eps_photo = −25.2 to −26.8. **They differ by
0.32–0.48 permil, because SOIL_FAST *IS* OLD PHOTOSYNTHATE** — the only contrast is Suess
drift across its ~2 yr turnover. On whole-record gross carbon that is **0.04 permil** of
atmospheric d13C against a **0.05** representation error: BELOW NOISE. 14C is the larger
contrast (+35 to +52 permil post-bomb) and still comes to **3.6** against a fitted
`sigma_d14c` of **6.1**: ALSO BELOW NOISE.
⇒ **The data CANNOT apportion the term between the channels.** A fitted partition would be a
judgement width wearing a fitted coefficient's name — the `npp_frac_NH` failure mode.

**⛔ NOR IS IT A DOUBLE-COUNTING FIX.** GMST does carry ENSO (r = +0.41, **+0.53 at the
3-month lag**), but 1 sd of ENSO moves GMST only **0.042 degC**, which at the mode's
`q10 = 1.136` is **+0.054 %** of respiration = 0.032 GtC/yr against the explicit SH term's
1.025 — **3.2 %**. The channel is weak because q10 rides GLOBAL mean temperature while the
physics is TROPICAL land temperature and moisture. ⚠ **And the model has NO moisture variable
at all** — no precipitation, soil water, drought or aridity anywhere in `R/model.R`.

**✅ WHAT SURVIVES IS CORRECTNESS, AND IT IS ENOUGH.** The reverse limb moves carbon
atm → `soil_fast` — land uptake that never passes through vegetation — at `alpha13 = 1`, and
`add_flux`'s guard is STRUCTURALLY BLIND to it because it only fires on `alpha13 != 1`. In the
SH that is **61 % of ENSO-active months and twice the forward limb's carbon**.
⇒ **REVISED RECOMMENDATION: make the term ONE-WAY, do NOT split it into two FITTED channels.**
One coefficient per hemisphere as now, no new coordinate. The GPP/moisture limb is the one the
model LACKS ENTIRELY. ⚠ Fire, the third observed limb, stays unrepresented either way.

**⚠ AND THE PRE-CHECK'S FIRST RUN PRINTED AN EMPTY TABLE RATHER THAN ERRORING**: `alpha_photo`
lives in the AUX list, so `v$p$alpha_photo` was NULL, `(NULL - 1) * 1000` is `numeric(0)`, and
that flows through `sprintf()` as `character(0)`. The same silent zero-length class as
[[intersect_is_a_silent_default]]. Guarded with `stopifnot(length(...) == 1L)`.

**THE GATE LEDGER** (`DG_LEDGER` + `dg_print_ledger()` in `lib_design_gates.R`, printed by the
canonical report). Each gate now declares SOURCE CLASS, BOUND + claim kind, SCORED?, and
POWER. The last column is the one nobody had written down, and it re-reads the whole set:
* **GATE Q is the ONLY genuinely out-of-sample gate.** Everything else restates a scored
  stream or rests on another model.
* **⛔ GATE 7's STANDING FAILURE IS A SIGMA MISMATCH, NOT A MODEL DEFECT.** The likelihood
  scores the land sink at `LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE` = 0.5 × 3.0 = **1.50**
  GtC/yr; the gate judges the SAME stream on the SAME data at **0.50**. A deliberate 3×
  stricter re-judgement that had never said so. Computed in the ledger, not quoted.
* Gate 7's source is also MIXED — GCB's ocean sink is a model product, its land sink a residual.
* Gates 4 and 5 have NO BOUND and cannot fail; gate 4 is near-algebraic in fitted quantities.
* **⛔ NOT ONE LAW-DERIVED GATE EXISTS.** Candidates named, none built: carbonate/Revelle,
  Henry's-law solubility, and — most valuable, since gate 12a reports an ocean-CAPACITY defect
  it cannot localise — **ocean DIC inventory vs GLODAP**, observational and currently ungated.

**Verdict on "rewrite the gates from scratch": NO — restructure.** The estimators are the
expensive part and they are sound (gate 5's parabolic peak refinement, gate 7's linear end
extrapolation matched to the objective, gate 4's self-consistent scaled denominator). The
deficiencies are bounds, provenance and power, not sources.

Suite 1457 / 6 / 2, failure set identical to baseline.

## 2026-09-02h — **BOTH SPLIT CONTRACTS HARD-ERROR, AND "BOTH ACTIVE" IS NARROWER THAN IT SOUNDS**

Marcus: add a hard error where a legacy branch and a current branch are both active, and
check first that no legacy branch is in use.

**⛔ THE AUDIT FOUND THE THING THAT MADE IT NON-TRIVIAL: `ccx_migrate_par_set()` NEVER DROPPED
THE `seas_lag_p` SCALAR** while its `gamma_enso` branch always had. So every migrated ancestor
carried BOTH names and a naive error would have fired on `from90` immediately. **The tell was
the parameter COUNT**: migration returned **26** names against `CCX_PARAM_NAMES`' 25, and the
extra one was exactly that scalar. Now dropped -- numerically inert, since the split fields
are filled FROM it (1.7677/1.7677 preserved, gate 7 land 3.5774 / gate Q 0.8025 / AF 0.41128
all unchanged).

**⛔ MY FIRST ATTEMPT WAS TOO COARSE AND A TEST CAUGHT IT.** `any(split present)` took the
suite 6 -> 7: `test-seas-lag-split.R:47` pins `lag_p(sh = 2.4, legacy = 1.9)` -> `c(1.9, 2.4)`
ON PURPOSE ("an explicit field WINS over the legacy scalar"). **The test was right and the
contract was wrong; the test was NOT touched.** A legacy scalar beside a PARTIAL split is not
an ambiguity -- it is what FILLS the absent half, and `ccx_migrate_par_set()` calls the
resolver for exactly that. An `any()` rule breaks the migration from inside itself.
⇒ **"BOTH ACTIVE" = THE SCALAR IS SHADOWED BY A COMPLETE SET**, not merely present:

| shape | result |
|---|---|
| complete split + legacy | **ERROR** -- nothing to fill, two answers, the silent no-op |
| partial split + legacy | resolves (migration's own fill path) |
| legacy only | resolves, pre-split ancestor bit for bit |
| neither | the named default |

**⭐ AND `ccx_gamma_enso()` HAD THE IDENTICAL LATENT BUG, `any()` -> `all()`.** A legacy scalar
beside a PARTIALLY split list errored, and that error came out of `ccx_migrate_par_set()`
itself. Dormant only because every stored ancestor has all four names absent; it would have
fired the first time one carried three of four. Verified on a real fitted par_set: partial +
legacy now migrates to 25 names, `land_NH` filled to 0.4256, scalar dropped.

**✅ THE BUG THIS WAS FOR IS CAUGHT.** `p$seas_lag_p <- x` on a live list is now an error,
because `ccx_default_params()` always carries a complete split set. That is what made
`diag_gross_cancellation_geometry.R`'s 15-point `GC_LAG_GRID` sweep run FLAT -- every point at
2.25, its printed maximum read off a constant. Fixed to write the split names.
⚠ **THAT FILE'S LAG-AXIS NUMBERS THEREFORE CHANGE.** Not re-run here: the old ones were
meaningless, so it is a re-measurement to make deliberately, possibly with a quarantine.

**LEGACY-BRANCH AUDIT, the answer to the question asked:** nothing live uses one. The
25-parameter survey vectors carry neither retired name; `ccx_default_params()` carries
neither; `alpha_as_tdep` is 1. The scalar-only branch stays reachable and correct for
pre-split ancestors, which is its purpose.

Suite 1457 / 6 / 2, failure set identical to baseline.

## 2026-09-02g — **DEBUG THE GATES: ONE WAS NEVER CALLED, TWO HAVE NO BOUND**

Asked to debug all the gates before the §6 review. Ran the standing suite, measured every
gate at every arm, and mutation-tested the two that have bounds.

**⛔ GATE Q WAS IN NEITHER GATE REPORT.** It shipped in `lib_design_gates.R` with the
T-dependent alphas (`6263bf6`) and its ONLY caller was `tests/testthat/test-alpha-as.R`. So
the refit-acceptance criterion the handoff itself sets -- "GATE Q must still PASS" -- could
not be checked by running either gate report. Added to `diag_design_gates_at_mode.R` as a
per-arm measurement; the unit test remains the DISCRIMINATION test. It now reads
defaults 1.37 / from90 0.80 / pin90 0.76 observational sigma, all PASS.

**⚠ AND THE QUOTED SIGMA REPRODUCES AT NO ARM.** The handoff §3 and memory
`alpha_as_t_dependent_shipped` both say "6.4 sigma -> 1.0 sigma". Measured: from90 0.80,
defaults 1.37, retired pair 6.59 / 6.02. The pre-check's 0.741 permil = 1.4 sigma is the
DEFAULTS arm. Nothing gives 1.0. The verdict (PASS, and discrimination) is unaffected.

**⛔ GATES 4 AND 5 HAVE NO BOUND AND NO VERDICT.** Line 135 was the only verdict logic in
the whole report. They print tables and cannot fail. Gate 5's NH->SH lag is 0.97 against an
observed 1.34 (-28 %) and its peaks are ~0.95 yr late; gate 4's decadal spread is 0.030
against GCB's 0.051 under a stated "must not be SMOOTHER than this" test. Both misses are
sitting in a report under the word GATE with nothing to fail against. **NOT fixed here:
choosing those thresholds is a design decision, flagged for Marcus.**

**⚠ GATE 7's BOUND WAS A BARE LITERAL, DUPLICATED.** `|z| <= 1` was copy-pasted into the
verdict line of BOTH callers while this library's own header claims "one kernel, two
callers" -- the kernel was centralised on 08-31f, the VERDICT was not. Now `DG_G7_NSD`,
named in the library and referenced by both. ⚠ It is 1 where GATE Q's `DG_Q_NSD` is 2, both
distributional claims against a stated sigma; recorded at the constant, NOT ruled on.

**✅ GATE 7 MUTATION-TESTED AND IT HAS POWER.** Walking `beta_max` x0.5 -> x2.0 moves land
1.663 -> 6.697 GtC/yr, z -1.49 -> +8.57, monotone, failing on BOTH sides and PASSING at
x0.80 (land 2.819, z +0.82; ocean 3.208, z +0.01). So its standing FAIL at the mode
(land +2.33 sigma) is a real model miss, not a broken gate -- and it is not new: DESIGN
records +2.28 sigma on 2026-08-14.

**⚠ "GATE 4" IS TWO DIFFERENT GATES.** `diag_gates_in_the_new_basin.R` defines its own
GATE 1/2/3/4 as hard `stop()` guards (feasibility, encoding, bands, objective-purity) in
the same file that reports DESIGN gate 4/5/7. "GATE 4 FAILED -- the objective is not a pure
function of u" is not the airborne fraction. Flagged, not renamed.

**Credit: GATE 12b is the best-built gate in the repo** -- it declares its borrowed band as
an assumption and carries its own in-run mutation test.

Suite 1457 / 6 / 2, byte-identical to the pre-patch run: no test outcome changed.

## 2026-09-02f — **DECLARE THE SWITCH, AND HAND OFF TO A REVIEW-THEN-REFIT**

**A defect I introduced this morning, found by auditing my own change rather than by a failure.**
`alpha_as_tdep` shipped as a `p$alpha_as_tdep` read inside `ccx_prepare()` and was NOT in
`ccx_default_params()`. So a MISSPELLED switch (`alpha_as_tdp <- 0`) would have been absent,
defaulted to 1, and run the WRONG MODEL while printing numbers -- the same silent-default class as
the alphas themselves before this change, and the third instance of it today. Now declared beside
`revelle_frozen`, with the reason at the line. Suite unchanged at 1457 / 6 / 2.

**⚠ AND THE MARSHALLING AUDIT THAT FOUND IT ALSO PRODUCED TWO FALSE ALARMS**, both looking exactly
like an uninitialised-memory bug in the C++ struct: once from `tr -d 'a["]'` deleting every letter
`a` from the field names, once from a character class `[A-Za-z_]` that excluded the digit in
`fco3`. The code was correct both times. The working form is recorded in the handoff:
`grep -o 'a\["alpha_as_[A-Za-z0-9_]*"\]' src/ccx_core.cpp | sed 's/^a\["//; s/"\]$//' | sort -u`
against `grep("^alpha_as_", names(ccx_cpp_aux(...)))`. Verified clean both ways.

**HANDOFF** at `notes/handoff_2026-09-02_the_limb_the_pair_and_the_shipped_alphas.md`, ordered as
Marcus directed: **code review first, then refit.** The review section names specific risks rather
than asking for a general look -- the two split contracts that disagree (`ccx_seas_lag_p()` uses
precedence where `ccx_gamma_enso()` hard-errors), the strongly ANTIsymmetric fitted ENSO
coefficients nobody has asked about, whether four ENSO parameters earn their keep at |z| <= 0.68 and
0.003-0.006 ppm of seasonal amplitude, the four alpha application sites and whether `sst` is the
seasonal one at each, and one inconsistency better ruled on than discovered: GATE Q uses the box-mean
SST while the deriv uses the seasonal one. The refit section flags the judgement (one basin at 25
parameters across ten starts, so a polish may beat another dispersed multi-start) rather than making
it, and carries the Torch traps and the quarantine contract.

**The pattern the handoff closes on**, because it should weight the review: three errors this session
and all three were in checks I wrote, not the code they checked -- GATE Q built self-referentially,
the 2x2 diagnostic's stored ratios nearly drifting under my own change (a 3-byte file difference),
and the two bad audits above.

## 2026-09-02e — **SHIPPED: THE AIR-SEA 13C ALPHAS ARE TEMPERATURE-DEPENDENT. THE OBJECTIVE CHANGED.**

Marcus's call, steps 1-3 of the plan priced in 09-02d. `R/constants.R`, `R/model.R`,
`src/ccx_core.cpp`, `R/cpp.R`, `calibration/lib_design_gates.R`, `tests/testthat/test-alpha-as.R`.

**1. REGISTERED.** Eleven constants with provenance: the Zhang (1995) seawater fit with BOTH
printings and their one-sigma discrepancy documented; the kinetic pair; the held fCO3 with its
approximation priced (0.020 per mille of an ~8.7 per mille offset, 1 % of the slope); the retired
scalars; and Quay (2003)'s disequilibrium target, registered because a gate's target may not be a
literal in the gate. The two alphas had been literals read from nowhere else -- which is what made
setting them a silent no-op.

**2. TEMPERATURE-DEPENDENT.** `eps_down = eps_k(T)`, `eps_up = eps_k(T) - eps_DIC-g(T)`, applied at
the LOCAL SEASONAL SST on both the R and C++ paths. `alpha_as_tdep = 0` reproduces the pre-09-02
model BIT FOR BIT. ⚠ It defaults ON, so the LEGACY path is now the untested one and `test-alpha-as.R`
asserts both -- the inverse of the usual default-off trap.

**3. GATE Q**, in the shared design-gate library beside 4/5/7. **Legacy 6.4 sigma FAIL -> shipped
1.0 sigma PASS**, and that discrimination is itself a test. ⛔ I built it wrong first: it read the
equilibrium offset off the model's OWN alphas, which made it self-referential and PASSED the retired
pair at 1.2 sigma. Caught only because BOTH settings passed when legacy was known to fail.

**WHAT MOVED.** Invasion limb -2.00 -> -0.84 (it was 2.4x too large); evasion -10.00 -> -9.50/-9.72.
Objective **-4.84 log-units at the un-refitted mode, and ONLY d13C streams move** -- `d13c_level_MLO`
+7.77 against `d13c_seasonal_SPO` -4.73, `d13c_seasonal_MLO` -3.19, `d13c_level_SPO` -3.97. The CO2
limbs are untouched to machine precision, which is the correct signature of a 13C-only change.
⛔ **EVERY FITTED VECTOR PREDATES THIS AND A REFIT IS OWED.**

**⭐ 14C INHERITS THE TEMPERATURE DEPENDENCE -- no separate term, and adding one would be a bug.**
Marcus's framing, and it is the right one: the 14C fractionation is DEFINED by its relationship to
the 13C one, so it inherits whatever temperature dependence alpha13 has. The model carries
Delta-14C (`C14/C = 1 + D/1000`) and `add_flux` applies no fractionation to it, which is exact
precisely WHEN alpha14 = alpha13^2. alpha13 is now a function of SST, so the alpha13^2 that line
assumes is too -- automatically, with no code and nothing to keep in sync. Adding a 14C term later
would DOUBLE-COUNT by ~2 x 8.7 = 17 per mille, about 3x the fitted `sigma_d14c`. The one residual is
a deviation from the DEFINING relationship rather than a missing dependence: the square law is exact
for equilibrium and ~1.9 for the kinetic limb, leaving ~0.09 per mille on the mean and ~0.001 per
mille/K -- three orders below the noise floor. Recorded in `add_flux`, whose comment said "NO
fractionation -- see header" while the header did not say, which is why the question arose at all.

**THREE TESTS FIRED AND ALL THREE WERE RIGHT TO.** `test-artificial-sink.R` and `test-enso-split.R`
each pinned `aux$alpha_as_down`, now the retired scalar; `test-constants.R`'s provisional ledger
demanded the three new entries be deliberate. **None was loosened** -- each was re-pointed at
`ccx_alpha_as()` at 1e-12, with the retired value asserted to FAIL so the update cannot be satisfied
by the old constant. The sink test also needed `seas_drivers = 0`, so the box SST is exactly
`aux$sst`; otherwise the expectation would have meant a second copy of the seasonal-SST formula.

**Memory consolidated** (snapshot `memory_backup_20260902/`). `INDEX_ccx_seas.md` had breached its
HARD ceiling at 17.6 KB; the closed 08-27 sub-arc (28 bullets) moved to `INDEX_ccx_arch.md` and the
live state was compressed -- **17.6 -> 11.6 KB**. ⚠ On the root index I nearly repeated the mistake
its own footer records: `MEMORY.md` is 29 % comment, so its CONTENT is 10.9 KB against a 12 KB soft
budget and it was compliant all along. Measure content, not the file.

## 2026-09-02d — **THE MEASURED PAIR CLOSES GATE Q, AND THE ALPHAS ARE UNSETTABLE**

Asked what the next model improvement should be, and tested the candidate rather than arguing it.
`diag_alpha_as_up_precheck.R` sec.6. **STILL ADOPTS NOTHING.**

**⛔ FIRST, A DEFECT THE TEST HAD TO WORK AROUND.** `alpha_as_down` / `alpha_as_up` are literals
inside `ccx_prepare()`'s aux and are read from NOWHERE else, so setting them on a parameter list is a
**silent no-op** — it returns an unchanged number with no error. The first attempt did exactly that
and produced four IDENTICAL rows; the uniformity is the only reason it was caught. Third instance
today of "a value you can set that nothing reads". The only injection point is `ccx_prepare()`, and
the SPINUP must see the change or the run starts at the old isotopic equilibrium.

**⭐ WITH THAT FIXED, THE RESULT IS DECISIVE.** Alphas changed in the spinup too, nothing refitted:
the model as it stands gives an air-sea d13C disequilibrium of -0.040 per mille (**6.4 sigma out,
wrong sign**); the measured pair gives **+0.741, i.e. 1.4 sigma** against Quay's 0.60 ± 0.10. Surface
d13C_DIC moves from +0.72/+0.75 to **+1.47/+1.50**, inside the observed modern range. **Only the full
pair works** — invasion-only lands at 5.3 sigma, evasion-only at 10.3. So this is not a knob turned
to meet a target: two independently measured constants agree with an independent, UNSCORED
observation only together.

⚠ Still high, not centred, and the NH/SH spread is comparable to the observational sigma.
⛔ Adopting changes the objective ⇒ every fitted vector quarantined and a refit owed. Batch it with
any other objective-changing adoption rather than spending a refit on it alone.

## 2026-09-02c — **THE PAPERS ARRIVED: THE INVASION LIMB IS THE WRONG ONE, AND AN UNSCORED GATE FAILS**

Marcus supplied `zhangquaywilbur1995.pdf` and Quay et al. 2003 (GBC 17(1)) after the first pass had
to quote them second-hand. `calibration/diag_alpha_as_up_precheck.R` rebuilt on the primary source.
**STILL IMPLEMENTS NOTHING.**

**⛔ THE PAPER PRINTS ITS OWN FIT TWICE, WITH DIFFERENT COEFFICIENTS.** Abstract:
`eps_DIC-g = (0.014 ± 0.01)*T*fCO3 - (0.105 ± 0.002)*T + 10.53`. Conclusions: `(0.0144 ± 0.01)` and
**`(0.107 ± 0.002)`**. The two T coefficients are exactly one stated sigma apart — the paper's two
printings straddle its own error bar — and nothing in the text prefers one. **Both are now carried**
and every result prints under each (it moves dE/dT by 1.7 %). The first pass had only the abstract
form, from a secondary source, and would have shipped it as "the" coefficient.

**⭐ AND THE PAPER MEASURES THE OTHER LIMB, WHICH CHANGES THE ANSWER.** `eps_k = -0.81 ± 0.16` per
mille at 21 °C and `-0.95 ± 0.20` at 5 °C. BOTH limbs carry eps_k; only evasion also carries the
equilibrium offset — the structure Quay 2003 eq.(2) uses. So the measured pair is
`eps_down = eps_k`, `eps_up = eps_k - eps_DIC-g`, and the slope inherits the kinetic dependence:
**+0.113 per mille/K**, not the +0.104 of the first pass. Against that, the recalled Mook value
(+0.114) is within **1.4 %**, and the boiling-point anchor with a LINEAR law within 6 %.

**⭐ §5a IS ANSWERED, AND WITHOUT GLODAP.** Measured pair vs the model's: `eps_down` **-0.84 vs -2.00,
i.e. 2.4x TOO LARGE**; `eps_up` -9.50/-9.72 vs -10.00, right to 3-5 %. So the limb that is wrong is
the INVASION one, not the evasion one the arc was looking at. ⚠ This CORRECTS the first pass, which
read the model's -10 as `-eps_DIC-g` and concluded the pair needed `eps_down ~ 0`: with both limbs
carrying eps_k the pair is structurally consistent, just ~1.1 per mille out on each limb in the same
direction.

**⛔ AND A NEW GATE FAILS AT ~6 SIGMA, WITH THE WRONG SIGN.** Quay 2003's global mean air-sea d13C
disequilibrium for 1995 is 0.60 ± 0.10 per mille; the model gives **-0.04**. ⭐ The gate has POWER
precisely because the quantity is UNSCORED — the ocean d13C stream is `ocean_grad_d13c`, a
SURFACE-MINUS-DEEP gradient, and the two `d13c_level_*` rows are atmospheric, so nothing in the
likelihood constrains the absolute surface-ocean d13C. A failure is an unconstrained direction, not
a broken fit. It localises to **d_ml being 0.53-0.75 per mille too light**, not to the alpha pair
(adopting the measured pair moves the offset only ~0.7). ⚠ Candidate, untested: this mode's mixed
layer is 139 m, well below a 50-75 m surface layer, and a deeper box mixes in lighter subsurface DIC.

**The §5b verdict is unchanged by any of it**: the omitted temperature term is 9-16 % of the two
d13c_seasonal rows' residual and moves both the wrong way. ⚠ One label had gone stale under the new
slope — the verdict string said "8-15 %" while the numbers read 16.0/9.1 — and now derives from the
computed values, which is the rule it should have followed from the start.

## 2026-09-02b — **`alpha_as_up` PRICED: REAL PHYSICS, AND STILL NOT THE ANSWER**

`handoff_2026-09-01f` §5's pre-check, run before anything was written.
`calibration/diag_alpha_as_up_precheck.R`, ~30 s. **IMPLEMENTS NOTHING** — `R/model.R`,
`src/ccx_core.cpp` and `R/constants.R` are all untouched.

**⭐ THE SLOPE IS NO LONGER AN ANCHOR-DERIVED GUESS.** Marcus pointed at Broecker & Maier-Reimer
1992 or Mook; neither is in `ClaudeDocs/Papers/` and AGU refused the fetch. What surfaced instead is
the laboratory measurement both rest on — **Zhang, Quay & Wilbur (1995), GCA 59, 107–114**, whose
seawater fit is `eps_DIC-g = 0.014*T*fCO3 - 0.105*T + 10.53` per mille for 5–25 °C and
0.05 < fCO3 < 0.20. The model's own state sits inside both ranges (NH 18 °C / fCO3 0.086; SH 16 °C /
0.079), giving **d(eps_up)/dT = +0.104 per mille/K**. ⚠ Quoted from SECONDARY sources — the PDF is
not on disk — and therefore cross-checked against an independent application of the same paper
(CROCCA-2S 13C Suess study: 0.18 °C/decade ⇒ −0.019 per mille/decade = −0.1056 per mille/°C). The two
agree to 1.6 %. **Get the PDF before shipping a constant; a cross-checked secondary quote is enough
to price a mechanism and not enough to adopt one.**

**⭐ AND MARCUS'S ANCHOR IS RIGHT — THE `1/T` FORM WAS WHAT WAS WRONG.** Against the measured
+0.104: the boiling-point anchor with a `1/T` law gives +0.137 (**+32 %**), with a LINEAR law
**+0.106 (+2 %)**; the critical-point anchor gives −46 %; Mook as recalled +10 %. And Zhang's linear
fit crosses eps = 0 at **101.4 °C = 374.5 K**, 1.4 K from the boiling point — an independent
corroboration of the anchor from data that knew nothing about it. (⚠ A 4× extrapolation beyond the
fit's stated range; Zhang claims nothing at 100 °C.)

**⛔ THE MECHANISM IS NOT THE EXPLANATION FOR THE −12.2 FLAG.** The analytic response
`amp(d13C_atm) = F_up * amp(eps_up) / (M_atm * omega)` — an UPPER bound, since it ignores
interhemispheric exchange and the ocean's own d13C response — gives 0.0036 (NH) / 0.0026 (SH) per
mille peak-to-peak. That is 1.0 % / 7.7 % of the OBSERVED seasonal d13C, and **14.8 % / 8.4 % of what
the model already gets WRONG on the two rows that carry the veto**. At the derived phase it moves
BOTH residuals the wrong way by ~5 %. ⚠ The phase is derived, not measured, and the effect goes as
cos(gap), so its sign flips at a 3-month gap: the SH gap (+1.83 mo) is robust, the **NH gap (−2.49 mo)
is MARGINAL, 0.51 mo from flipping**. Either way, a flag worth −12.2 prior-sd cannot be paid for out
of a term this size. Real physics; not the answer — which is exactly the outcome §5 said was worth an
afternoon rather than a refit.

**Not priced, and deliberately separated: the MEAN value.** Zhang puts eps_up at −8.66 / −8.87 per
mille against the model's hardcoded −10.00. That is a constant offset on the evasion limb and it is
the §5a question. ⚠ It also exposes a tension the pair cannot hold: reproducing Zhang's equilibrium
offset (~+8.8 per mille) while keeping a −2 per mille kinetic invasion term needs eps_down ≈ 0.

**⚠ Still owed, and a prerequisite to changing either:** `alpha_as_down` / `alpha_as_up` are literals
at `R/model.R:2023-2024` (mirrored `src/ccx_core.cpp:477-478`) carrying the word "provisional"
without being in the provisional-constant LEDGER that exists to track exactly this.

## 2026-09-02 — **THE 2×2 RE-PRICED: THE LAND *PARAMETER* CLOSED, THE LAND *LIMB* GOT WORSE**

`handoff_2026-09-01f` §4's check, run. `calibration/diag_2x2_repriced_at_enso25.R` on the new
`calibration/lib_seas_limbs.R`, ~70 s. **ADOPTS NOTHING, REFITS NOTHING** — 27q's P1 interaction
needs six refitted arms and was not re-run; what is re-priced is the ARITHMETIC verdict, which is
what §4 says went out of date.

**⛔ THE PREMISE WAS RIGHT AND THE ANSWER GOES THE OTHER WAY.** 27q said rotating the SH ocean into
phase overshoots the SPO total by 18 %, measured against an SH land limb at 1.26× observed. At the
25-parameter mode the SH land **limb** is **2.55× observed** (1.312 → 1.743 ppm), the SPO total is
**0.927×** obs so 27q's P4 window now fails from BELOW, the d13C-per-ppm ratio worsened 1.933 →
2.063, and **putting the ocean limb at the observed one overshoots by +62.1 %, not +42.4 %**. The
required ocean limb moved AWAY from the observed one on both axes (0.89× → 0.57× in size, 3.0 →
4.1 months off in phase). Both cluster representatives agree to three decimals on every limb.

**⭐ AND THE LEVER IS NOT THE ONE THE ARC WAS WATCHING.** One-at-a-time, 27q INCUMBENT → enso25 A:
`npp_frac_NH` 0.6485 → 0.5076 is **+0.600** on the SH-land limb; `seas_T_amp_SH` 1.039 → 4.054 does
exactly what 27q said it does, **−0.228**, and is **outvoted 2.6 : 1**. Pre-checked before believing
it: the SH NPP share goes ×1.4008, predicting 1.838 against a measured 1.912, **+4.0 %** — a
productivity shift across the equator and nothing else. So the fit traded a MEASURED-bracket flag
for a JUDGEMENT-width one (`NPP_FRAC_NH_SD` = 0.04, moved 3.5 of those sd) and the observable got
worse. ⛔ **Not a fix to reach for**: matching the observed land limb by NPP share alone needs
`npp_frac_NH` ≈ 0.81, outside its [0.4, 0.8] bounds, and its own prior centre would make the limb
worse still — the SIZE was already exonerated, the missing piece is CANCELLATION.

**GATE R was fired, and NOT widened.** Re-scoring 27q's stored arms through today's harness missed
by 1.8e-3–5.0e-3 relative, uniformly one sign, on a **1e-8 identity bound**. Rather than loosen it,
the gate now carries a control: at `gamma_diff = 0` — its value when 27q ran — all twelve limbs
reproduce to **≤7e-14**. The whole gap is volcanic diffuse-light fertilisation (`328cdb8`, adopted
`a2298dc`, both 2026-08-29; 27q ran 08-28). A SECOND change would now fail that control instead of
hiding inside a tolerance someone had widened to make a table print.

**Tried and rejected: editing `diag_admissible_2x2_land_ocean.R` to use the new library.** It is a
pre-registered artefact whose gates may not move under a refactor. It keeps its inline estimator;
what binds the two files is GATE R re-scoring its stored arms through the library.

**One error of mine, caught by output contradicting a comment I had just written.** I documented the
21-parameter ancestors as having run with the ENSO response OFF at the pre-split default of 0. The
new ENSO limb came back at 0.0055 ppm on those arms instead of the identical zero I predicted:
`gamma_enso` was one of their 21 **calibrated** names, fitted at 0.8512. The machinery was right —
the migration contract had split the fitted value correctly — and only the comment was wrong.

**⚠ Owed:** SPO total 1.168 / land 0.683 / ocean 0.522 / ocean phase 8.52 are not in
`R/constants.R`; they are replicated file-locally across ~10 diagnostics. Gate O checks them against
the obs actually loaded (1.170, implied land 0.679, mutually consistent as VECTORS), but a registry
entry is owed.

**⚠ AND THE SUITE WAS AT SEVEN, NOT SIX.** `handoff_2026-09-01f` records "1365 / 6 FAIL / 2 skip,
the same six, unchanged by everything here". It was **1364 / 7**: `900f90b` shipped
`diag_prior_screen_enso25.R` with the `from90` ancestor written as a **literal mode path**, which
`test-mode-file.R:71`'s hardcoded-path lint has been failing on ever since. Fixed here — the line
now calls `ccx_mode_file("from90")`, which resolves to the identical file — and the suite is back to
**6 FAIL / 2 skip**, the six being the standing 21-vs-25 parameter-set failures that will clear on
adoption plus the `kz` bracket bound. ⚠ The lesson is not the literal; it is that a suite count
quoted in a handoff was quoted rather than read.

## 2026-09-01n — **THE LAND HALF CLOSED, THE OCEAN HALF GOT WORSE, AND THE WIDTH WAS THE WRONG SUSPECT**

The prior screen 09-01e §6 made adoption conditional on, plus the width measurement it pointed to.
**ADOPTS NOTHING**; `CCX_MODE_CANONICAL` and `R/constants.R` both untouched.

**⭐ THE LAND HALF OF THE SEASONAL-AMPLITUDE PROBLEM HAS CLOSED.** `seas_T_amp_SH` −4.64 → **−0.64**
and `seas_T_amp_NH` +2.20 → **+0.29**: both MEASURED-bracket parameters are now INSIDE their
brackets, where 08-27 had NH land at 131 % of its high end and SH land at 29 % of its low end. That
finding no longer holds. ⚠ Attribution is CONFOUNDED — everything moves in the 08-30 → 08-31e
column, which carries the `seas_lag_p` split AND the basin together, and the only post-lag-split
ancestor on disk is also the new basin.

**⛔ THE OCEAN HALF SURVIVES, AND MEASURING ITS WIDTH MADE IT WORSE.** Three fixed weightings of one
ERSSTv5 climatology (area; |CT2022 flux|; K0(SST)·pCO₂) put the weighting ambiguity at log-sd
**0.160 (NH) / 0.097 (SH)** against the **0.25 JUDGEMENT** it would replace — narrower, and flux
weighting moves the anchor UP, away from the fit. `sst_seas_amp_SH` goes **−4.71 → −12.2**.
**The 0.25 was GENEROUS to the fit, and the width is no longer an explanation for the flag.**
Marcus's constraint shaped the whole design: the amplitude factors are NOT true observables, so the
job was never to recentre on a flux-weighted number — only to measure the SPREAD.

**Both cluster representatives give the SAME screen** (max |B−A| = 0.02), so the `h_ml` micro-split
costs nothing. **The ENSO split moved nothing either** — every parameter within 0.08 of the 08-31e
basin, the four coordinates at |z| ≤ 0.68, and ANTIsymmetric (ocean −0.950 NH / +1.187 SH) where
both seeds assumed symmetry.

**A z-RANKING WAS THE WRONG INSTRUMENT** and the project already knew it: `SST_SEAS_LOGSD` and
`NPP_FRAC_NH_SD` are widths the code LABELS as judgements while `seas_T_amp_*` carry measured
brackets. Every z now prints its prior's PROVENANCE, three-valued (BRACKET / JUDGEMENT /
UNLABELLED — the last meaning *the code does not say*), derived by deparsing each closure.

**Gates.** Stored `prior_z` recomputed under today's table (1e-11); the ancestor comparison gated
per parameter on that recompute, which FIRES on `kz` and `h_ml`; and the area-weighted anchor
reproduced from the new pipeline to 1.1e-05 with the target READ from the registry.
⚠ **One gate had to be rewritten mid-run**: I gated the finite fraction on every `ncvar_get` and
MPI-ULB's `pco2` returned "100.0 % finite, range [−999, 693]" — **−999 IS FINITE**, so the gate
passed on poisoned data. `fillvalue_not_applied` reproducing itself one gate short. Reads now
declare a PHYSICAL RANGE.

⚠ **Three label errors of mine, all caught by output contradicting the label**:
`refit_20260831_seas_lag_split/` holds a 21-parameter SCALAR-lag vector (I read its directory name);
the attribution header went stale within the hour; and ratios against zero-centred priors printed
1e13-scale garbage that looked like a result. Counts, field names and headers are now read or
derived, and zero-centred priors report an OFFSET.

**NEXT, both recorded in the handoff**: (1) re-price the 08-27q admissible 2×2 — its 18 % overshoot
verdict was measured against an SH land limb at 1.26× obs, and that limb has moved; (2)
`alpha_as_up` — the preindustrial DIC−atmosphere offset the α pair implies (+8 ‰) checked against
GLODAP, and its missing TEMPERATURE dependence, anchored on **α → 1 at the boiling point** (Marcus).
Also noted: `tau_ex_seas_amp` and `ent_seas_amp_SH` are implemented, defaulted to 0, and NOT in the
fitted set; `k_w` is aseasonal; and no wind field is on disk, which is why `k` is missing from both
the model and every weighting above.

Handoff: `notes/handoff_2026-09-01f_prior_screen_width_and_alpha.md`.

## 2026-09-01m — **THE TWO OWED FIXES, AND BOTH GATES MUTATION-TESTED**

Clears the two items 09-01l left **OWED AND UNCOMMITTED**. **Neither changes a round-1 number** —
every task ran in the right repo, on the right objective, against the right port targets; one wrote
its files to the wrong path and one printed a wrong word.

**1. `multistart.sbatch` — the clobbered `PROJ`.** Torch's `~/.bashrc` exports
`PROJ=/scratch/ms17839/SLR-RFF-BRICK`, and the script set `PROJ`, `cd`-ed, sourced the rc, and only
THEN built `CCX_MS_OUTDIR` from it — so round 1's ten result files landed in another project's tree
with nothing erroring. ⚠ **The `cd` was correct only because it happened to precede the source: an
ordering that works is not an ordering that is SAFE.** Three structural fixes rather than a
re-ordering, because a re-ordering is a convention and conventions rot:

* renamed to **`CCX_PROJ_DIR`** — a script may not name a variable the environment it sources also
  owns (`CCX_PROJ` stays the override INPUT, which is what the local dry-run sets);
* **`readonly`**, so a clobber is a HARD ERROR and not a silent rebind — verified: a rc setting
  `CCX_PROJ_DIR` now aborts the job with `readonly variable` instead of continuing
  [[split_name_must_hard_error]];
* `CCX_MS_OUTDIR` computed **before** the source and **ASSERTED** to be under the project **after**
  it (a gate placed before the hazard it guards is not a gate), with an explicit
  `CCX_MS_OUTDIR_EXTERNAL=1` escape — plus an idempotent re-`cd` on the same side of the source,
  because an rc may change the working directory as easily as it may rebind a name and the
  `Rscript calibration/...` at the bottom is a RELATIVE path.

**MUTATION-TESTED, all three states**: the default outdir passes; `CCX_MS_OUTDIR` pointed at
`SLR-RFF-BRICK` — the exact round-1 bug — exits **1** naming both paths; the escape downgrades it to
a warning and proceeds. `setup_torch.sh` gets the same rename: it never READ `$PROJ` after its own
source, so it had no live bug, but leaving the shape in the neighbouring file is how the class comes
back.

**2. `collect_dispersed_multistart.R` — a bound that did not match its claim.** The verdict gated at
**`1e-8`**. That is the right bound for the PORT GATE, whose claim is an **evaluation identity** —
one fixed point, two machines, agree to floating point. The verdict's claim is a comparison of two
**optimiser outputs**, and no optimiser promises `1e-8`; so it printed *"4 dispersed starts did NOT
reach the best re-converged known basin"* for a difference of **−0.0000** (≈1e-6), in the single
line a reader takes away. [[gate_bound_matches_its_claim]], reproduced in the same session that
cited it.

⇒ The bound is now the driver's **own convergence criterion**, `MS_CYCLE_TOL` = 0.5: a start is
declared CONVERGED when a whole cycle gains less than that, so two finals closer than it are not
distinguishable **by this optimiser's own standard**. It is **RECORDED** by the driver
(`cycle_tol`, `restart_tol` in every `start_*.rds`) and **READ** by the collector
[[recorded_but_never_restored]], **PRINTED** on the verdict line so the bound travels with the
claim, and files disagreeing on it are a hard error — they are not one survey. A file written before
today has no `cycle_tol`; the collector says so out loud and names the fallback as ASSUMED. ⚠ And
**absence ASSERTS**: `unique(unlist(...))` drops NULLs, so a directory MIXING pre- and post-fix
files would have taken the recorded value and said nothing about the half carrying no opinion —
the silent-omission shape of [[intersect_is_a_silent_default]]. It now counts them and names the ids.

**MUTATION-TESTED on a fixture carrying the REAL round-1 finals** (the Torch `start_*.rds` are on
`/scratch`, so the fixture reproduces the published numbers rather than importing them). All six
states fire correctly: the actual −0.0000 case now reads **REPRODUCED** (it read "did NOT reach");
all dispersed −3 reads **did NOT reach**; +3 reads **FOUND A BETTER BASIN THAN**; −0.02, inside the
bound, reads **REPRODUCED**; no `cycle_tol` anywhere names the fallback as assumed; 3-of-10 missing
names the three ids; and two DIFFERENT `cycle_tol` values across files hard-errors.

**Also corrected**, one line, in `multistart.sbatch`'s WALL block: it asserted "cpu_short caps at
4 h", which [[torch_qos_is_the_real_cap]] contradicts — the QoS allows **6 h**. The arithmetic is
unchanged because it is against this job's own `--time=04:00:00` REQUEST; the comment now says
request-not-ceiling, and points at the 6 h a round 2 may claim.

⛔ **Still ADOPTS NOTHING**, and the four open decisions of 09-01e §6 (adoption against the prior-z
screen, ratifying the ENSO prior, a profile/Hessian on the four, whether to survey wider) are
untouched.

## 2026-09-01l — **THE SURVEY RAN: ONE BASIN AT 25 PARAMETERS, AND THE 08-31e TWO-BASIN STRUCTURE WAS A 22-PARAMETER PROPERTY**

Torch job **16732800**, `--array=0-45%10`. **10 COMPLETED, 11 CANCELLED** (Marcus, once the answer
was clear). **ADOPTS NOTHING**; `CCX_MODE_CANONICAL` untouched.

**⭐ ALL TEN STARTS CONVERGE TO −1495.795**, from starts spanning six orders of magnitude — the cold
init (−19,205), the migrated incumbent (−1551.12), the migrated new basin (−1500.05), the
observation-implied ENSO partition (−1507.69), and four dispersed draws (−181,947 to −2,113,779).
**Total spread 0.0022 log-units.**

**⛔ AND THEY ARE THE SAME POINT — CHECKED, NOT ASSUMED.** "All the same value" is the
suspicious-uniformity pattern, so the question was whether one basin or a flat direction. Pairwise
Euclidean distance in 25-dim `u` is **≤0.0005** within {0,1,2,3,4,6,7}; a micro-cluster {5,8,9} sits
**0.069** away; the ONLY coordinate with meaningful spread is **`h_ml`** (0.065), then `rep_dC`
(0.017) and `kz` (0.013) — every other coordinate agrees to 4–5 decimals. The micro-split is the
already-documented `h_ml` step-instability reproducing. Collector: **1 DISTINCT BASIN**.

**⇒ The 08-31e "two basins, +52.0 apart, 21.53-log-unit barrier" is CORRECT IN THE 22-PARAMETER
SPACE and scope-limited to it.** The four ENSO coordinates connect them. **A barrier on the straight
`u`-path in a smaller space is not a barrier in a larger one.** Within-run gains are the comparable
statement: incumbent lineage **+55.3**, new-basin lineage **+4.26**. ⚠ −1495.795 is NOT comparable
to −1496.01 (different parameter count AND `kz` bracket).

**✅ BOTH SUB-QUESTIONS THE RE-DESIGN ADDED ANSWERED, both negatively — which is the useful
outcome.** ENSO seeding bought **0.0000**: Nelder-Mead finds the ocean direction unaided within one
restart, so the +1.91 conditional advantage does not survive re-optimising — measurable ONLY because
ids 1/2 were kept as unseeded controls. ⚠ The seeded/unseeded ordering FLIPPED between restart 1 and
restart 2 at sub-log-unit gaps; reading a winner off either snapshot would have been wrong. And the
**observation-implied partition converged to the same mode**, so its conditional −7.72 was a
FROZEN-SLICE artifact — the third time this arc has paid for that lesson.

**⚠ WHAT IT DOES NOT SHOW**: 4 dispersed starts at ONE dispersion. A bound, not a proof.

**⛔ TWO FIXES ARE OWED AND UNCOMMITTED** (local repo access was lost to a macOS TCC revocation
mid-session; neither affects the numbers). (1) `multistart.sbatch` named a variable **`PROJ`**, which
Torch's `~/.bashrc` exports as `/scratch/ms17839/SLR-RFF-BRICK` — it clobbered ours BETWEEN the `cd`
and the `CCX_MS_OUTDIR` line, so round 1 ran in the right repo and wrote its results into another
project's tree, silently. Namespace it `CCX_PROJ_DIR`, compute the outdir BEFORE sourcing, and
ASSERT it is under the project. **An ordering that works is not an ordering that is SAFE.** Files
have been moved and the stray empty dirs removed with `rmdir`. (2) `collect_dispersed_multistart.R`
gates its verdict at **1e-8** — an EVALUATION bound applied to an OPTIMISATION comparison — and
printed "did NOT reach" for a −0.0000 difference.

**⚠ NOT ADOPTED, and the prior-z screen is unexamined**: `sst_seas_amp_SH` **−4.71**, `rep_dC`
**+3.60**, `sst_seas_amp_NH` −2.95, `q10` −2.64, `npp_frac_NH` −2.28.

**Torch lessons**, both now in the `nyu-torch-hpc` skill: **`Rscript -e` EATS `$`** (the module is a
Singularity wrapper re-quoting argv into a double-quoted `bash -c`; it forged a `-Inf` cold init that
reads exactly like a broken port — the tells were 0.024 s/eval being far too FAST and a per-call
`Coercing LHS to a list`), and **the QoS, not `sinfo`, carries the cap** (`cpu_short` = 6 h and
`cpu=32` per user, not 4 h). Measured eval rate on the compute nodes **0.245–0.455 s/eval, median
0.33**; the login node's 0.808 was contention.

Handoff: `notes/handoff_2026-09-01e_torch_survey_result.md`.

## 2026-09-01k — **THE TORCH SURVEY IS RE-DESIGNED FOR THE 25-PARAMETER MODEL, NOT JUST RE-CUT FOR IT**

09-01j regenerated `port_targets.csv` and made the bundle **runnable** at 25 parameters. This entry
asks the different question — **what the survey should now DO** — and changes three things.
`run_dispersed_multistart.R`, `collect_dispersed_multistart.R`, `calibration/torch/multistart.sbatch`
and `calibration/torch/README.md`. **Adopts nothing; `CCX_MODE_CANONICAL` untouched.**

**⛔ 1. NEITHER KNOWN BASIN IS A MODE OF THIS SPACE, SO THE SURVEY HAD NO BASELINE IT COULD USE.**
Both mode files are migrated 21-parameter vectors whose ocean ENSO pair is **exactly 0** — 0 is what
they RAN, because the mechanism did not exist when they were fitted. Measured on the shipped
objective: migrated incumbent **−1551.1222**, migrated new basin **−1500.0507**, and moving the
ocean pair to **+0.10 in each hemisphere with nothing else touched** is worth **+1.9087** at the new
basin and **+0.2947** at the incumbent (reproducing `diag_enso_objective_leverage.R`'s +1.91).
⇒ **−1496.01 is not a number a 25-parameter result may be ranked against**, and neither is id 2's
start value — that comparison is an optimum against a migrated point [[like_for_like_forcing]].

**The fix is three more fixed ids, not a caveat in a README.** The array's fixed head went from 3
to 6: **id 3** = incumbent + ocean +0.10 each (−1550.8275), **id 4** = new basin + the same
(−1498.1420), **id 5** = new basin + the **OBSERVATION-implied** partition, ocean +0.326 each and
land ×1.734 (−1507.6925). Ids 1 and 2 stay as **UNSEEDED controls** beside 3 and 4, so the pair
says what the seeding was worth, and the collector prints that difference. **Id 5 is conditionally
WORSE on purpose**: it starts where GCB's measured ENSO sink slopes say the partition is, which a
frozen slice scores at −7.72 — and a conditional sign is a hypothesis about a refit, not a
prediction of one (the gate-pricing arc measured 253 log-units of pure frozen-slice artifact, and
09-01g's compensating-error state is exactly other coordinates absorbing an ENSO change).

`collect_dispersed_multistart.R`'s verdict is now an ordering against **the best FINAL value among
ids 1–5**, not against id 2, and it says so with the missing ids named when some are absent. It also
reports **BEST DISPERSED separately from BEST FOUND**: only a dispersed start can answer "is there a
third basin", and with the fixed starts now seeded the top of the table is quite likely to be one of
them — one line for both states would print the same string for "the survey found something" and
"the known basins are still the best known basins" [[no_power_null]].

**⛔ 2. THE DISPERSION WAS DILUTED 8.4 % BY A BOOKKEEPING ARTIFACT.** `MS_SPREAD` is the
per-coordinate RMS separation between the two known basins. Four of the 25 coordinates were
**migrated in BOTH files**, so their separation is a property of the migration contract and not of
the basins — the ocean pair differs by **exactly 0**, the land pair by **0.0100**, which is the
retired scalar cut in half. Averaging them in multiplied the whole dispersion by
**√(21/25) = 0.9165**. Measured: **RMS over all 25 = 0.9592, over the 21 that at least one
reference point FITTED = 1.0466.** The pool is now the second, derived from `attr(, "migrated")` —
the field the migration itself records — so the next split fixes itself, and the excluded names are
PRINTED rather than assumed. ⚠ **0.9592 was never "the basins got closer"**; over the shared
coordinates the separation is what it always was.

⚠ **This does NOT give the four ENSO coordinates a scale of their own**, and that is stated at the
point of use: they are dispersed at the shared pooled sd, which is an **assertion**, because their
own separation is structurally zero and no second basin exists to measure it against. 09-01j is the
check that it is not silly — at ~1.05 they land **6–9 conditional sds** out against **325–430** for
the stiffest coordinates.

**⚠ 3. ROUND 2 IS NOT ROUND 1 REPEATED — and that answers the N = 40 question 09-01c left open.**
At 25 parameters the Nelder-Mead simplex has **26 vertices**, so each task converges less far in the
same wall than the 22-dimensional design assumed. The old advice was "re-submit the same array";
that spends three times the fairshare converging starts already 50+ log-units behind. **Round 1 =
`0-45%10`. Round 2 = the six fixed ids plus the best ~8 dispersed ids from `summary.csv`.** The
fixed ids are always re-submitted — they are the baseline the verdict is an ordering against, so
they are the tasks that most need to be converged. ⇒ **N stays at 40**: buy DEPTH in round 2, not
width in round 1. ⚠ The cost is written down rather than hidden ([[no_power_null]]): a truncated
start is ranked on a value it had not finished climbing to, so a deep basin that started slowly can
be dropped — which is why the cut is the best ~8 and why OUT-OF-TIME is printed beside every rank.

**What did NOT change, and why.** `CCX_MS_MAXIT = 6000` — the **wall**, not the cycle budget, stops
a round (3 × 6,000 evals is ~111 min at the 0.37 s/eval a 2×-slower node implies), so raising it
would change nothing a round executes. The dispersion **centre** is still the COLD init. The
objective and the parameter table are untouched: `port_targets.csv` still stands at `53ef03d`,
`n_par = 25`, and **nothing here needed it re-run**.

**⭐ A GUARD FOUND BY MUTATION-TESTING THE GUARD.** The first cut dispatched the seeded ids as
`id == MS_SEED_IDS[["new_obs"]]`. Deleting an entry then died at *"subscript out of bounds"* three
frames from the cause and **never reached the gap guard written for exactly that case**. Dispatch is
now through `names(MS_SEED_IDS)[match(id, ...)]`, and **both directions fire with the reason**: an
id the vector no longer names hits the gap guard ("id 5 is below MS_DISPERSED_FROM but matches no
fixed start"), an id it names with no branch hits a new one. ⇒ **a guard that is unreachable is not
a guard**; the mutation test is what distinguishes the two [[mutation_test_gates]].

**Also**: the default output directory names the **parameter set** (`multistart_20260901_enso25`),
not a date — a `u` vector is meaningless without it, and this project moved that set twice in three
days; `start_class`, the dispersion pool and the ENSO seed values are recorded in every
`start_*.rds` **and read by the collector** [[recorded_but_never_restored]]; and two stale captions
went with it (`(2n+1)` at n = 22, and a −1548.0112 port-gate example that predates both the `kz`
re-bisection and the split).

**PREFLIGHTED on the Mac for ids 0, 1, 2, 3, 4, 5, 25 and 45** — all eight `PORT GATE (a) PASSED`,
rel 7.6e-16 to 2.5e-14. Nothing has touched Torch; Marcus submits.

## 2026-09-01j — **PRE-REFIT PASS: THE OBJECTIVE ALREADY WANTS THE OCEAN TERM, AND 09-01g NAMED A SLOPE GAP AS A COEFFICIENT**

`calibration/diag_enso_objective_leverage.R`, new (~6 min). Adopts nothing. Written to answer the
one question the refit rests on: **can the objective see the four new coordinates, and which way
does it pull them?** Measured at the 08-31e basin, matched harness, shipped table.

**⭐ Q1 — LEVERAGE: yes, and they are the SOFTEST coordinates in the space.** 85–252 log-units per
prior sd; diagonal conditional sd **0.10–0.16** in u. Ranked against all 25, `luc_scale` (0.0022),
`bomb_total` (0.0025) and `q10` (0.0029) are 40–70× stiffer, so the survey's single-scalar
dispersion of 0.96 is **6–9 sds** on the ENSO coordinates against **325–430** on the stiffest.
**Nothing special is needed for the new parameters; if the dispersion is a problem it is a
pre-existing one, and it is not a problem the split created.** ⚠ Diagonal curvature, not marginal
sd — the Hessian's 1.11e6 conditioning is still the standing blocker.

**⭐ Q2 — DIRECTION: the objective ALREADY WANTS an ocean ENSO term, in the observed direction.**

| point (other 21 frozen) | Δ logpost | land | ocean | partition misfit |
|---|---|---|---|---|
| observed | — | −0.665 | +0.119 | 0.000 |
| mode as migrated (ocean 0) | +0.00 | −0.352 | −0.155 | 0.587 |
| land ×1.89 only | −9.85 | −0.732 | −0.099 | 0.284 |
| **ocean +0.137 each only** | **+1.66** | −0.357 | −0.040 | 0.467 |
| both | −4.75 | −0.738 | +0.016 | 0.175 |
| ocean −0.137 (wrong way) | −8.42 | −0.346 | −0.270 | 0.708 |
| ENSO off entirely | −12.71 | +0.076 | −0.218 | 1.078 |

Re-optimising a 3-parameter carbon slice moves ocean-only from **+1.66 to +1.98**. A scan puts the
conditional optimum near **+0.10 each (+1.91)**. ⇒ **The incumbent's ocean sign error was never
something the objective was defending — it was something a one-parameter structure could not
express.** The LAND amplitude is what the CO₂ streams resist (−9.85, barely relieved by
re-optimisation).

**⛔ AND A CORRECTION: 09-01g NAMED SLOPE QUANTITIES AS PARAMETER VALUES.**
`diag_enso_ocean_term_design.R` printed `gamma_enso_ocn = +0.274` where +0.274 is the ocean-sink
SLOPE gap, and `gamma_enso × 1.89` where 1.89 is a ratio of SLOPES. Measured transfer (R² =
**1.000000**, five points each):

    land   slope = +0.0762 − 0.4297 · coef
    ocean  slope = −0.1550 + 0.4194 · coef

- ⛔ **The transfer is ~0.43, not 1**, and the **intercepts are non-zero**. So the coefficients that
  close the observed slopes are land **1.726 total (×1.734, not ×1.89)** and ocean **+0.653 total =
  +0.326 EACH — 2.4× the +0.274 printed.** [[ratio_needs_its_base]]
- ✅ **09-01g's slope arithmetic is sound and every conclusion it draws stands** — compensating
  errors, 87 % cancellation, ocean-only worsens growth, ~72 % ceiling. **Two labels were wrong**,
  and both are now corrected in place with the reason.
- ⚠ **Why 0.43 and not 1**: the estimator scores at the OBSERVATION's own best lag (land 3 mo, ocean
  2 mo) while the model's ENSO flux is contemporaneous; `cor(annual index at that lag, at lag 0)` is
  0.82 / 0.91, so **the lag accounts for only ~0.85** and the rest is the annual sink's own response
  to an instantaneous flux anomaly. Measured, not explained — and identical in both reservoirs,
  which points at the estimator rather than the physics.
- ⚠ **The objective wants about a THIRD of what the partition asks for** (+0.10 vs +0.326 each).
  That trade is the refit's to make.

**Also in this pass, before the refit:**
- ⛔ **The Torch bundle is STALE.** `port_targets.csv` records `n_par = 22` at commit `3346ded`;
  `run_dispersed_multistart.R` refuses it with "The target is stale." Re-run
  `make_port_targets.R` and `make_bundle.sh`. The driver itself is fine — it already migrates both
  reference points through `ccx_migrate_par_set()`.
- **The measured dispersion moves 1.0493 → 0.9592 for a BOOKKEEPING reason, not a physical one**:
  the two known basins differ by 0.01 in the land coordinates and **exactly 0** in the ocean ones
  (neither file has an ocean term), so four near-identical coordinates dilute the per-coordinate RMS
  by exactly √(21/25) = 0.9165. The scale is recomputed at every run, so nothing needs editing —
  but the number in the README is now stale.
- ✅ **`ccx_require_param_set()` replaces EIGHT bare `stopifnot(identical(md$param_names, …))`.**
  That form raises "identical(nm, CCX_PARAM_NAMES) is not TRUE" — a diagnostic that cannot run and
  does not say why ([[broken_gate_reports_nothing]]); it has aborted two gates on this project
  already, and the ENSO split killed all eight in the same second. The refusal is unchanged; it now
  names the retired and missing parameters and points at `ccx_migrate_par_set()`.
- ⚠ **The app has been shipping UNCALIBRATED DEFAULTS since 2026-08-31, and NOT because of this
  split.** `app/global.R` skips any mode whose `param_names` differ, and the canonical mode is a
  **21-parameter** file — so it has been skipped since the `seas_lag_p` split. It could migrate and
  say so instead; left alone as a separate decision.

## 2026-09-01i — **THE PUMP+CONVEYOR COVERAGE CLAIM WAS HALF WRONG, AND THE FIRST GATE I WROTE FOR IT WAS VACUOUS**

`tests/testthat/test-pump-conveyor.R`, new, 23 assertions. Two corrections, both worth more than the
file itself.

**⛔ CORRECTION 1 — "pump+conveyor has NO coverage" is FALSE.** `diag_conveyor_enso_lever.R` (09-01f)
reported that `test-conveyor.R` never sets `pump_grad` and `test-pump.R` never sets `q_conv`, and
concluded the combination was untested. **The premise is true and the conclusion is not:**
`ccx_default_params()` ships `pump_grad = PUMP_GRAD_OBS = 233.1094` — the pump has been ON by default
since 08-16d — so `conv_p()` has been running BOTH mechanisms all along. Its derivative-conservation
test, quiet-run drift gate, spinup fixed-point test and R↔C++ parity test **are already
pump+conveyor tests**.

- ⚠ **The real defect is that the coverage is INCIDENTAL.** It exists only because a default happens
  to be non-zero, and that default HAS moved once (0 from the port until 08-16d). If it moves back,
  every one of those tests keeps passing while quietly testing the conveyor alone — the mirror image
  of [[default_off_hides_the_bug]]. ⇒ **"never sets X" is a statement about the TEST; "is not
  covered" is a statement about the DEFAULT. Read the default before turning one into the other.**
- What was genuinely uncovered, and is now covered: an **explicit** pin on both mechanisms, the
  **DIC-limited** pump with the conveyor on (the corner where the pump's export reads the mixed-layer
  carbon the conveyor is moving — the only place the two actually interact), and **integrated**
  closure.

**⛔ CORRECTION 2 — my first closure gate was VACUOUS, and measuring it is what showed that.** The
obvious form — a closed run with no emissions, asserting total carbon does not move — passes for the
wrong reason: from an exact fixed point under a constant forcing, every box's carbon comes back
**BIT-IDENTICAL** after 3300 RK4 months (`max |dC| = 0` exactly; CO₂ 276.5064 → 276.5064). **A
closure gate on a state that does not move cannot detect a closure failure.** [[gate_reads_its_own_output]]

- ✅ **Driven instead**: 1 GtC/yr moves **43 GtC** through the boxes; stock change minus input closes
  to **1.0e−10 GtC** over 274 yr (matching the 1.8e−10 the diagnostic reported).
- ✅ **Tolerance FROM THE ARITHMETIC**: 3300 monthly increments into a ~37750 GtC total have a
  roundoff floor of √3300 × 37750 × 2.2e−16 ≈ **4.8e−10 GtC**; the gate is set at **1e−8**, ~20×
  the floor. [[tolerance_scaled_to_spread]]
- ✅ **And its POWER is asserted**: restating the input wrong by 1e−6 GtC must trip it, and the run
  must actually move ≥1 GtC. [[no_power_null]] [[mutation_test_gates]]

## 2026-09-01h — **THE FOUR-PARAMETER ENSO DESIGN IS IMPLEMENTED: 22 → 25 PARAMETERS**

Marcus's design call of 09-01 (`notes/handoff_2026-09-01_enso_arc.md` §6), built. **Nothing is
fitted and nothing is adopted** — `CCX_MODE_CANONICAL` is untouched, every new coefficient defaults
to **0**, and 0 in all four is the incumbent model bit for bit.

`gamma_enso` (one scalar, LAND ONLY, split 50/50 by a hardcoded `aux$enso_share`) →
**`gamma_enso_land_NH/_SH` + `gamma_enso_ocn_NH/_SH`**.

- **ONE RESOLVER, `ccx_gamma_enso()` (R/model.R), and both cores go through it** — the
  `ccx_seas_lag_p()` pattern, for the reason that function records: a default carries two contracts,
  the value and what ABSENCE means, and the 08-30 `gamma_diff` break came from two cores holding
  different opinions about the second.
- ✅ **THE BEHAVIOUR-PRESERVING DEFAULT the `gamma_diff` adoption did not have.** A pre-split list
  carrying only the scalar takes the legacy branch — LAND gets `gamma_enso` × the retired 0.5/0.5
  share, OCEAN gets **0** — and reproduces the old model **bit for bit** (asserted at
  `tolerance = 0` on CO₂ and δ¹³C over 1960–1990). The ocean pair gets 0 rather than a share of the
  land coefficient because **the mechanism did not exist**: a fitted ancestor holds no opinion about
  it, and inventing one would smuggle in a response of the wrong sign.
- ⛔ **CARRYING BOTH NAMES IS AN ERROR, NOT A PRECEDENCE RULE.** One name became four at **~110 call
  sites** (70 in `calibration/`, 37 in `tests/`, the rest in `R/` and `app/`), every one of them
  `p$gamma_enso <- …` on a list that now carries four explicit zeros. Under a "split wins" rule each
  would have run with **the ENSO response switched OFF** and reported a number. The guard turned all
  of them into a loud stop; all were rewritten to `ccx_set_enso(p, src)`, which reads the source
  through the same contract. [[intersect_is_a_silent_default]], [[recorded_but_never_restored]]
- **The OCEAN term is TWO EXPLICIT LIMBS, alpha resolved per direction** — invasion carries
  `alpha_as_down`, the La Niña reversal carries `alpha_as_up`. One signed flux with a single alpha
  is the 08-25e seasonal-NEP bug exactly, and no conservation gate can see it. Both limbs are
  UNLABELLED, so the trace classifies them `as_down`/`as_up` and `ocean_net` counts them — the same
  call, and the same reason, as the artificial mid-century sink.
- **`aux$enso_share` is GONE** from R and from the C++ `Aux` struct, in the same commit. The 0.5/0.5
  survives as `CCX_ENSO_SHARE_LEGACY`, read only by the resolver's legacy branch.
- **Priors: each of the four keeps the original N(0, 2)** — the `seas_lag_p` call, so the split adds
  degrees of freedom without smuggling in a new belief about any one of them. ⚠ **It is NOT
  scale-preserving on the SUM**: two independent halves imply N(0, 2√2) on the land total where the
  scalar had N(0, 2), i.e. the land prior is **wider by √2**. Deliberate, recorded at the table, and
  the alternative (2/√2 each) is what to revisit if the land pair ever runs to the prior rather than
  to the data. **This is the one methodological choice in the change and it wants Marcus's
  ratification.**
- **`tests/testthat/test-enso-split.R`, 56 assertions**, all passing: the absence contract in both
  cores, both-at-once refused, bit-identity of the legacy path, R↔C++ parity at four UNEQUAL and
  SIGNED coefficients, migration identity, and two mutation tests — the land pair must separate by
  hemisphere at a fixed total, and the ocean pair must move the ocean **in the observed direction**.
- ⭐ **The isotope check is the load-bearing one.** The ocean term's applied fractionation is
  asserted equal to `alpha_as_down` (and ≠ 1). That is what makes the four identifiable at all:
  land is −0.0172 ‰ per GtC and ocean +0.0022 ‰, ~8× weaker and OPPOSITE, so δ¹³C identifies the
  land pair and CO₂ the ocean pair by difference. With a generic fractionation the design collapses.
- ⚠ **`calibration/diag_gamma_enso_profile.R` now REFUSES with the reason** rather than dying on
  `match()` returning `NA`. It profiled a retired scalar; its answer — more amplitude is LOUDER, not
  righter — is unchanged and is what the split was built on.
- ⚠ **A 25-PARAMETER REFIT IS OWED, and it now stacks with the 22-parameter one already owed.**
  Every stored mode is a 22-parameter file in a 25-parameter build: `par_mode` still overlays through
  the legacy branch, `u_mode` does not decode. Warm-start from `par_mode` via
  `ccx_migrate_par_set()`. `ccx_load_mode()` says exactly this when it refuses one.

## 2026-09-01g — **THE ENSO ERRORS ARE COMPENSATING: AN OCEAN-ONLY TERM WOULD MAKE THINGS WORSE**

`calibration/diag_enso_ocean_term_design.R`. Pricing Marcus's proposal — an ENSO term on surface
uptake in each hemisphere, mirroring the land term — **before building it**. Adopts nothing.

**Slopes in GtC/yr per °C Niño3.4** (⚠ GCB `atm_growth` is GtC/yr; the model's is ppm/yr. Comparing
them raw is a factor-2.124 error and it inverted this file's first answer. Units settled by the
BUDGET IDENTITY, not by a magnitude heuristic — which got it wrong.)

| | land | ocean | CO₂ growth |
|---|---|---|---|
| **observed** | −0.665 | **+0.119** | **+0.757** |
| model | −0.352 (53 %) | **−0.155** | +0.404 (53 %) |

- ⭐ **The model is in a COMPENSATING-ERROR state.** Land short by −0.314, ocean off by +0.274 —
  opposite effects on the atmosphere, **cancelling 87 %**. That is why growth is a respectable 53 %
  while both components are badly wrong, and why the fit never forced it: CO₂ outvotes partition
  40:1, so only the weak streams can see the error.
- ⛔ **Ocean-only would take growth from 53 % to 17 % of observed** — trading the better-measured,
  more heavily weighted observable for the weaker one.
- ✅ **Ocean + land together**: closing both slope gaps gives both partitions right and growth
  **53 % → 72 %**. ⛔ **The PARAMETER values this entry originally named (`gamma_enso` × 1.89,
  `gamma_enso_ocn` = +0.274) are WRONG and were corrected 09-01j** — they are a slope ratio and a
  slope gap wearing coefficient names. Measured transfer is ~0.43 with a non-zero intercept, so the
  coefficients are land **×1.734** and ocean **+0.653 total (+0.326 each)**. The slope arithmetic
  and every conclusion in this entry are unaffected.
- ⚠ **A ceiling from the DATA:** GCB's own slopes do not close — −(land+ocean) = +0.547 against a
  measured growth of +0.757, the +0.210 gap living in the imbalance term. **No model tuned to those
  sink products can exceed ~72 %.**

## 2026-09-01f — **THE CONVEYOR IS REFUTED AS THE ENSO FIX — WRONG SIGN, AND CHEAPLY**

`calibration/diag_conveyor_enso_lever.R` (~1 min). Adopts nothing; `q_conv` stays 0.

09-01e proposed that the ocean's ENSO sign error is the missing CIRCULATION term, and named the
conveyor. ⭐ **The obvious next step — make `q_conv` time-varying — would have meant a new forcing
column, R and C++ twins, a parity test and an `N_FORCING` bump.** A STATIC scan over `q_conv` asks
the same question in one minute. **Measure the lever before building the machinery.**

| q_conv (Sv) | ocean sink | land sink | deep Δ¹⁴C |
|---|---|---|---|
| 0 | 3.024 | 3.345 | −158.8 |
| 10 | 3.122 | 3.313 | −146.3 |
| 20 | 3.226 | 3.280 | −135.0 |

- ⛔ **THE SIGN IS WRONG.** `d(ocean sink)/dq = +0.0101 GtC/yr per Sv` — **more conveyor, more
  uptake**. El Niño *suppressing* the overturning therefore makes the response **more negative**, the
  discrepancy WORSE. Closing the gap needs `k < 0`: El Niño *strengthening* the cell, the opposite of
  the physical story. In a transient anthropogenic run, ventilating deep water undersaturated in
  anthropogenic carbon beats upwelling DIC-rich water to outgas.
- ⛔ **The magnitude is implausible regardless**: 136 % (q0 = 20 Sv) to 542 % (5 Sv) of the whole
  circulation, per °C.
- ⛔ **And it worsens the deep-ventilation gate**: Δ¹⁴C −158.8 → −135.0 against GLODAP's −175.3.
- ⭐ **20 Sv moves the sink by 0.20 GtC/yr** — transport is a weak lever on this ocean, a third
  instance of the standing reading that the defects are capacity, not transport.
- ✅ **By-product: an untested combination now has a check.** `test-conveyor.R` never sets
  `pump_grad`, `test-pump.R` never sets `q_conv` — pump+conveyor had **no coverage**. Carbon closure
  departs from the `q=0` case by **1.8e−10 GtC over 274 yr**. Worth promoting to a real test.

⚠ **The sign error stands; my mechanism for it does not.** Still open: an over-amplified
SST/solubility path, or a structural limit — equatorial upwelling has no tropics to live in here.

⚠ **Two bugs of my own, both caught by running it:** a top-level `if/else` (the identical trap I hit
and documented in `run_dispersed_multistart.R` earlier the same day), and a 1959 forcing start that
put a 165.8 GtC land-use start-up transient inside the measurement window. Now `DG_YEARS`.

## 2026-09-01e — **THE OCEAN'S ENSO RESPONSE IS ANTI-CORRELATED, AND THIS TIME IT IS POWERED**

`calibration/diag_enso_model_vs_obs.R` (~20 s) + `calibration/lib_enso_regression.R`. Adopts nothing.

The properly-shaped version of the claim retracted at 09-01c. Regression of detrended annual sinks
on Niño3.4 over **1959–2024**, model and observation through **one shared estimator**:

| | land slope | ocean slope | ocean r (95 % CI) |
|---|---|---|---|
| **observed (GCB)** | **−0.665** | **+0.119** | **+0.535** [+0.287, +0.716] |
| incumbent | −0.383 (**58 %**) | **−0.109** | **−0.496** [−0.673, −0.265] |
| new basin | −0.352 (**53 %**) | **−0.155** | **−0.506** [−0.680, −0.278] |

- ⛔ **The ocean sign is wrong**, p = 1e−4 in both basins, **CIs non-overlapping** with the
  observation, and **invariant to the detrending order to three decimals**. n = 66 years, not one
  event. **Marcus's retraction was right about the method and the conclusion survived it.**
- ⭐ **The amplitude is right and the phase is wrong**: the incumbent's detrended ocean residual sd
  is **0.122** against the observed **0.123**. The ocean is not too quiet — it moves the wrong way.
  (The new basin is noisier at 0.170: a second small mark against it.)
- **Land is right-signed at 53–58 % of observed** — a magnitude shortfall, not a structural one, and
  better than the 33 % of CO₂-growth variability recorded in `ccx_variability_gap`.
- ⭐ **AND THE HYPOTHESIS IS CONFIRMED FROM THE CODE — the negative sign is the ONLY sign this
  structure can produce.** ENSO enters as a **land-only** flux (`R/model.R:1256`, `soil_fast → atm`);
  the ocean feels it through **exactly one path, SST** (`cor(sst_anom, Niño3.4) ≈ +0.40`), i.e. the
  thermal term alone. **There is no upwelling to suppress**: the conveyor is built but `q_conv = 0`,
  is not in `CCX_PARAM_TABLE`, and is absent from the fitted mode, so vertical transport is
  time-invariant diffusion. The pump is live but constant-mass. **No value of `gamma_enso` can fix
  this, because `gamma_enso` only moves land.**
- ⚠ Three caveats stated in the file and not softened: **not independent** (the model is driven by
  this index), **model-vs-product** (GCB's ocean sink is an ensemble, not measured air-sea flux), and
  the ocean target clears its own detection floor by only 1.3×.

**Also de-duplicated:** the annual-sink construction became `dg_annual_sinks()` in
`lib_design_gates.R` — gate 7 is now the window mean of that same series, and
`diag_elnino_2023_sink_response.R` no longer carries its own copy. Gate 7 verified **bit-identical**
across the refactor, as was the power test across the regression extraction.

## 2026-09-01d — **THE OBSERVABLE IS NOT BLIND: THE ENSO SINK SENSITIVITIES, MEASURED**

`calibration/diag_enso_sink_power.R` (~5 s, OBSERVATIONS ONLY — it scores no model).

Run as the power check that had to precede any ENSO composite: a series that cannot show the effect
reports "no effect" identically to one that looked. **It can show it.**

| sink | best lag | r | 95 % CI | slope (GtC/yr per °C Niño3.4) | n → n_eff |
|---|---|---|---|---|---|
| **land** (positive control) | 3 mo | **−0.677** | [−0.790, −0.519] | **−0.665** | 65 → 65 |
| **ocean** | 2 mo | **+0.535** | [+0.287, +0.716] | **+0.119** | 65 → **45** |

- ✅ **The positive control passes** — the land signal is found strongly, with the known sign — so a
  null on the ocean would have meant something. There is no null: **the ocean signal is real and
  POSITIVE. El Niño strengthens ocean uptake**, agreeing in direction with Ke et al. 2026.
- **n_eff, not n.** Both series are autocorrelated (detrended ocean lag-1 = 0.60), which cuts the
  ocean's effective sample from 65 to 45; the naive CI would have been far too tight.
- **Robust to every free choice**: 13/13 lags individually significant, so the scanned best-lag CI
  is not carrying the verdict; stable across detrending orders 1–3; stronger on MEI.
- ⚠ **The ocean is the weaker case** — it clears its 80 %-power detection floor by only 1.3×, land
  by 2.0×.
- ⛔ **AND IT RETIRES A NUMBER.** Ke et al.'s 0.38 GtC/yr at MEI 0.71 implies ~0.54 per unit —
  **4.5× the measured slope**, and 5.9× the detection floor. A persistent response that size would be
  unmissable here and is not. It is an event-specific, Jul–Jul, baseline-relative anomaly:
  **never use it as a sensitivity. Use +0.119.**

⇒ **The composite test is now well posed and worth running**, with a quantitative target for the
model's ocean response rather than a one-event sign.

## 2026-09-01c — **RETRACTED: THE EL NIÑO OCEAN "SIGN ERROR" IS 0.6 SIGMA, NOT A FINDING**

Marcus, same day: *"Don't over-read a single year: every ENSO is going to have somewhat different
impacts on land and ocean carbon, our best will only ever capture the average response (modulated by
intensity)."* He is right and the arithmetic says so.

- **model − obs on the ocean delta = 0.60 σ** of GCB's own stated 2-year bar. Not a detection. I
  issued a `*** CONTRADICTS ***` verdict without ever computing the bar.
- **And the bar is ambiguous, which is the deeper point.** GCB's stated 0.40 is systematic and
  largely cancels in a difference; the series' own year-to-year sd is **0.11**, but that is a
  smoothed model-ensemble mean. The same delta is **0.6 σ against one bar and 2.4 sd against the
  other** — the definition of a question one event cannot settle.
- ⛔ **"Both basins ⇒ structural" was not evidence.** Both are fits of ONE structure with ONE
  `gamma_enso` and share an ENSO response by construction.
- ⛔ **And it was model-vs-MODEL.** GCB's ocean sink is a product ensemble; Ke et al.'s +0.38 comes
  from ML emulators of ocean biogeochemical models, not measured air-sea flux.

The diagnostic keeps its year-by-year table and now reports the delta **with its bar and no verdict**.
⭐ **What survives is a fact about the GATE, not the event**: gate 7 scores a 2015–2023 window MEAN
and is blind to a terminal-year divergence by construction.

**The standing rule this establishes:** a one-parameter ENSO response can only capture the AVERAGE
response modulated by intensity, so it must be tested as a composite/regression over ALL events,
never on one.

## 2026-09-01b — **[SUPERSEDED BY 09-01c] the 2023/24 El Niño sink comparison**

`calibration/diag_elnino_2023_sink_response.R` (~10 s). Adopts nothing.

Marcus supplied **Ke et al. (2026), iScience 29(8):117053**, doi:10.1016/j.isci.2026.117053
(open access, vintage 2026-08-21) as background. It quantifies the event our historical run now ends
inside: CO₂ growth **3.66 ± 0.09 ppm/yr** over Jul2023–Jun2024, the highest July-to-July rate since
1979, from a **2.24 GtC/yr** net-land-sink weakening (97.5 % tropical), **partly offset by
0.38 GtC/yr of STRONGER ocean uptake**.

Testing the mechanism against the GCB series the objective already uses, 2022 → 2024:

| | land Δ | ocean Δ | land captured |
|---|---|---|---|
| **observed** | **−1.16** | **+0.27** | — |
| incumbent | −1.04 | **−0.03** | 89 % |
| new basin | −0.91 | **−0.07** | 78 % |

- ⛔ **The land response is largely right; the OCEAN moves the WRONG WAY in BOTH basins**, so it is
  structural rather than a property of the basin choice. **2023 is the model's worst ocean-sink year
  of the decade (−0.67 GtC/yr).** A third independent line pointing where gate 12a's capacity defect
  and gate 7's ocean half already point.
- ⚠ **DESIGN gate 7 cannot see this**: it scores the 2015–2023 window MEAN, and a mean over nine
  years averages away a divergence concentrated in the last one. The model passes ocean at −0.45σ on
  the mean while 2023 alone is 0.67 off. That is `no_power_null` in the shape of an averaging window,
  and it is why this file reports YEAR BY YEAR.
- ⚠ **The paper's own numbers are quoted for ORIENTATION and never differenced against ours** — its
  window is Jul–Jul and its land decomposition is not the `land_sink` column this differences.
  Quoting 2.24 against our −1.16 would be exactly the like-for-like error the project rule forbids.
  What the paper licenses here is the **mechanism and the sign**.
- ⚠ Small mark against the new basin for the adoption call: it captures **78 %** of the land drop
  where the incumbent gets **89 %**.
- ⚠ The paper never uses the phrase "airborne fraction"; any link to gate 4 is inference, not its framing.

## 2026-09-01 — **RULING #1 CLOSED: THE `kz` BRACKET IS RE-BISECTED WIDE ON THE SOURCED TARGET**

`R/calibrate.R` `kz`: **[3942.5, 6528] → [4379.1, 8109.9]**, `init` 5235.25 → 6244.5. Marcus's call.

**THE DEFECT WAS THE TARGET, NOT THE RECIPE.** The bisection is observational — both ends are the
`kz` that puts the model's deep ocean at a stated Δ¹⁴C — but it was run against an **uncited
recollection**, `[-200, -150]‰`, on the bottom **three** boxes, while the `d14c_deep_ocean` term
added 2026-08-14 scores the **bottom box** against GLODAPv2's **−175.26 ± 10.259‰**. On the layer
that is actually scored, the old bracket was **z ∈ [−4.34, +1.22]**: 5.55σ wide, centred 1.56σ BELOW
the target, and truncating it at the top — which is exactly where every constrained row of the land
axis railed. The same recipe at the same default parameters, against the sourced target:

| k | target ± kσ | → `kz` bracket |
|---|---|---|
| 1 | [−185.52, −165.00] | [5211.9, 6373.9] |
| 2 | [−195.78, −154.74] | [4763.5, 7146.6] |
| **3** | **[−206.03, −144.48]** | **[4379.1, 8109.9]** ← SHIPPED |

- ⚠ **THE FLOOR RISES TOO** (3942.5 → 4379.1): this is a **re-centring** on the sourced target, not
  only a widening. Every mode file on disk stays strictly interior (`kz` 6169–6400).
- ⭐ **THE BRACKET WAS NOT WHAT HELD `kz`**: on this support the anchor row turns over **INTERIOR at
  6486.1 = 56 % of the box**, with `fert_k`/`q10` re-optimised. `R/calibrate.R`'s stated exit
  condition — delete it only after a refit shows the term holding `kz` alone — is closer but unmet,
  so the bracket stays.
- ⚠ **THE UNIVARIATE JUSTIFICATION WAS RE-MEASURED BEFORE SHIPPING** — new
  `calibration/diag_kz_bracket_hml_sensitivity.R`. The sentence it rests on ("`h_ml` moves it under
  1.5‰ across `h_ml` 39.7–100") was measured over a window that **no longer contains the better
  basin's 143.9 m**. Inside its own window it REPRODUCES (0.99‰); across the live band [35, 195] the
  Δ¹⁴C at fixed `kz` moves **6.25‰ = 0.61σ = 10.2 % of the 3σ box**, and the bracket ends move
  −87/−165 m²/yr. Sufficient at k = 3; it would not obviously hold at k = 1.

**CONSEQUENCES, ALL MEASURED:**

- **Every stored logpost moved**, because a fixed `kz` now sits at a different fraction of the
  bracket and the logit Jacobian changes: incumbent −1548.011 → **−1546.345**, new basin −1496.013 →
  **−1495.276**. ⇒ **the basin gap is +52.00 → +51.07**, and **all of the move is PRIOR**: the
  loglik gap is unchanged at +37.82, so the prior share goes +14.18 → +13.25.
- ✅ **Gates 4/5/7, both re-priced rulings and every prior-z are BIT-IDENTICAL** (diffed). They are
  model-vs-obs at fixed parameters, so a support change must not touch them — and does not.
- **`calibration/torch/port_targets.csv` re-measured**, and it now RECORDS the bracket it was
  measured under. `run_dispersed_multistart.R` REFUSES a target file from a different table: a
  re-centred bracket shifts every logpost, so a stale target would fail the port gate for a reason
  that has nothing to do with the port.
- ⛔ **THREE OF MY OWN BAND GATES WOULD HAVE REFUSED EVERY MODE FILE ON DISK**, because they demanded
  a file's recorded bands EQUAL the shipped table — a strictly wider claim than any of them makes.
  Narrowed to what each actually needs ([[gate_bound_matches_its_claim]]): **feasibility** for a
  start point or a target, **same-bands-as-each-other** for a matched comparison, and the
  table-identity check moved to where it belongs, on the port-target file. The band mismatch is now
  RECORDED loudly instead of being fatal.

⛔ **ONE PREVIOUSLY PASSING TEST NOW FAILS AND IS LEFT FAILING:** `test-likelihood.R:578`,
`expect_lte(CCX_PARAM_TABLE$kz$hi, 7000)` — 8109.9 > 7000. It is a deliberate loose guard rail whose
own comment says it exists so the band cannot be "widened into uselessness one re-bisection at a
time". Its runaway guard (`hi < 10686`, the unbounded 17-parameter mode) still passes, and the new
bracket has a sourced justification the old one lacked — but how loose that rail should be is a
policy call, not a code fix. **Marcus's.**

**Suite: 1282 / 6 FAIL / 2 skip** (was 1275 / 6 / 2). Same count, different composition — see below.

### Also: the "all 6 failures say one thing" label was wrong, twice

- ✅ **FIXED: `test-prior-z.R`** was ERRORING on `no such parameter: seas_lag_p`, the scalar retired
  by the 08-31 split. It was booked under "the stored modes are 21-parameter files"; **it is not,
  and no refit or adoption would have fixed it.** Now runs the analytic check on **both** limbs,
  which actually TESTS `R/calibrate.R`'s claim that the split kept the original prior on each.
- ⛔ **AND ADOPTION WOULD NOT FIX TWO MORE — IT WOULD INVERT THEM.** `test-mode-decode.R`'s two
  failures encode the CURRENT canonical's **retired [85,120] band** as their premise: they assert
  the band-blind idiom is wrong by ~10.7 m and that `ccx_check_mode_decode()` ERRORS. Point
  `CCX_MODE_CANONICAL` at the polished mode — recorded under the shipped bands — and both premises
  dissolve and the tests fail the other way. They need a file that genuinely carries an overridden
  band (the 08-31 probe is one, on disk) rather than relying on the canonical happening to have one.
- ⇒ **The honest tally: 3 of the 6 are "21-parameter file in a 22-parameter build" and adoption
  fixes them; 2 are premises adoption inverts; 1 was unrelated and is fixed.** Plus the new bracket
  guard rail above.

## 2026-08-31f — **THE DISPERSED MULTI-START, RESTRUCTURED FOR TORCH AND READY TO LAUNCH**

`calibration/run_dispersed_multistart.R`, `calibration/collect_dispersed_multistart.R`,
`calibration/make_port_targets.R`, `calibration/torch/` (sbatch + setup + bundle + README).
**Adopts nothing. Nothing has touched Torch.**

**TORCH VERDICT (standing rule, said out loud): RUNNABLE, NOT YET RUN, AND NOW STAGED.** A straight
port of the serial driver is still MEASURED TO LOSE — the Mac is ~2× faster per eval and one
warm-started chain took 203 min. **Torch wins only RESTRUCTURED**, and this is the restructuring:
ONE start per process, so N starts are an array instead of a queue. ⚠ **Claude cannot submit**
(VPN + gateway + Duo + device-code); every step is Marcus's.

- **ONE START PER INVOCATION**, id from `CCX_MS_ID` or `SLURM_ARRAY_TASK_ID`, deterministic per id
  (`seed + id`), so a start is the same point whether it runs alone or in an array of 400 and a
  failed task can be requeued unchanged.
- ⭐ **THE DISPERSION SCALE IS MEASURED, NOT INVENTED: 1.0493**, the per-coordinate RMS distance
  between the TWO KNOWN BASINS, recomputed from their own mode files every run. That is the
  separation a survey must resolve to be worth running. ⚠ Still a methodological choice; printed,
  stored in every output, and `CCX_MS_SPREAD` overrides it.
- ⭐ **THE PORT GATES ITSELF, AND EACH BOUND MATCHES ITS OWN CLAIM.** Ids 0/1/2 are the cold init,
  the 08-30 incumbent and the 08-31e new basin. **(a)** the START point is an EVALUATION ⇒ relative
  **1e-8** against `calibration/torch/port_targets.csv`, logposts measured on the Mac and carrying
  host + commit; **(b)** the FINAL value is an OPTIMISATION ⇒ an **ORDERING** and no threshold at
  all. Mutation-tested: perturbing a target by 1e-6 relative fires (a).
  ⚠ The target is **NOT** each file's stored `logpost` — the incumbent's −0.85 is objective drift
  and would have spent most of a 1.0-log-unit budget before the port was considered.
- **THE BUDGET SIZES THE RESTART, IT DOES NOT MERELY VETO IT.** `optim()` cannot be interrupted once
  entered, so a clock-only check commits a task to a whole further restart and lands past the
  partition cap. The guard PROJECTS from a measured restart duration — and when a full-maxit restart
  does not fit, it runs a SHORTER one rather than checking out with 0 evals.
- ⛔ **TWO BUGS THE SMOKE FOUND, both of the "a null that is structurally guaranteed" class:**
  a task whose budget could not fit ONE restart reported **`CONVERGED`** (cycle gain 0.0000 because
  nothing was tried), and printed an eval rate of 2.6 s/eval computed over zero evals. Both now say
  what actually happened. The collector excludes such a task from the basin count.
- **The collector counts BASINS, not runs** — single-linkage in u-space at 0.25 × the measured
  inter-basin separation, i.e. the survey's own resolution — and states the verdict as an ORDERING
  against the incumbent to beat (−1496.01). ⚠ It says explicitly that a survey bounds what N starts
  at ONE dispersion found and is not a proof that no better basin exists.

⚠ **A dispersed start is a LONG climb**: at sd 1.05 a draw scores ~−3×10⁵ against the cold init's
−1.9×10⁴, so a start may spend its whole wall budget unconverged. Every task checkpoints every
cycle, so re-submitting the same array RESUMES rather than restarts.

**⭐ THE FIRST END-TO-END RUN FOUND TWO MORE, and both were reporting bugs, not arithmetic ones:**

- ⛔ **A task reported `CONVERGED` *and* `OUT OF TIME`.** Its BFGS polish had been skipped for budget,
  and the NM-only cycle gain then cleared `ARM_CYCLE_TOL`. But the polish is exactly the half that
  gained **9.07** in the probe run from an NM-stalled point, so a cycle without it is not a completed
  cycle. `out_of_time` now VETOES convergence, and the collector **errors** if it ever sees both
  flags — mutation-tested against the pre-fix files, which still carry them.
- ⛔ **The collector's own consistency gate printed all 22 parameter names above the report title.**
  At top level in an `Rscript`, the value of a call is auto-printed; the gate returned it. `invisible()`.

**End-to-end, 5 starts (short budget, contended laptop):** the port gates passed on all three
references (rel 6e-16 to 2e-14), id 2 re-found **−1496.0128 exactly**, id 1 gained **+15.31 in 802
evals** — a fresh confirmation that the incumbent is not converged — and a dispersed draw climbed
from −450,536 to −2,196 in the same budget.

⚠ **The only R dependency is Rcpp** (`adaptMCMC` is used only by `ccx_run_mcmc()` and is not on
Torch — which is why the survey is a mode-finder, not a sampler). The bundle excludes `data-raw/`
(3.4 GB) and is ~2 MB. `DESIGN.md` is **not** optional: it is `REPO_MARKER` in `R/paths.R`.

## 2026-08-31f — **THE GATES, RE-PRICED IN THE NEW BASIN — AND THE HARNESS THAT MEASURES THEM WAS BROKEN**

`calibration/diag_gates_in_the_new_basin.R` (~10 s) + `calibration/lib_design_gates.R`. Adopts nothing.

08-31e §8.6 left two open rulings carrying the same warning — *"worth re-pricing IN THE NEW BASIN
before ruling"*. This does that. It also had to repair the thing that measures gates.

- ⛔ **`diag_design_gates_at_mode.R` HAD NOT RUN SINCE 08-31.** Its
  `stopifnot(identical(md$param_names, CCX_PARAM_NAMES))` aborted before the first gate the moment
  `seas_lag_p` split — the same one true thing the 6 failing tests say. **A gate that cannot run
  reports nothing**, which is worse than one that runs and says its input was migrated. Both it and
  `diag_joos_irf.R` now MIGRATE a fitted ancestor through `ccx_migrate_par_set()` (the model's own
  absence contract, which errors rather than hand-filling) and PRINT that they did.
- ⛔ **`diag_joos_irf.R` took an unrecognised arm as a request for `defaults`.** A typo — or a
  perfectly good PATH, legal to `ccx_mode_file()` since 08-27 — ran the uncalibrated defaults and
  reported gate 12 as if that were what was asked. Absence now ASSERTS; paths are legal.
  Mutation-tested: `nonsense_arm` stops.
- **ONE KERNEL, TWO CALLERS.** Gates 4/5/7, their targets, windows and estimators moved to
  `lib_design_gates.R` rather than being written a second time. A second copy of a gate is the
  caption-sync bug class: the day one copy's window moves, two files report one gate name at two
  measurements and nothing says so.

**THE RE-PRICING (incumbent 08-30 → new basin 08-31e polished, matched under the SHIPPED table):**

| gate | incumbent | new basin | direction |
|---|---|---|---|
| **4** airborne fraction (GCB 0.431) | 0.418 (err 0.013) | **0.428 (err 0.003)** | ✅ better |
| 4 decadal sd (obs 0.051) | 0.028 | **0.024** | ⚠ SMOOTHER — worse on the spread half |
| **5** NH→SH bomb lag (obs 1.34 yr) | 0.97 (−0.37) | **0.86 (−0.48)** | ⛔ worse |
| **7** land σ | +2.37 | **+1.87** | ✅ better by 0.50 σ, still FAILS |
| **7** ocean σ | −0.82 | **−0.45** | ✅ better, passes |
| **12a** integrated IRF, TH-20 vs Joos floor | −0.09 % | **−3.33 %** | ⛔ worse, still BELOW |
| **12b** tail ratio (band 0.593–0.979) | 0.7063 | 0.7077 | — unchanged, passes both |
| prior-z flags (\|z\| > 3) | 3 | **2** | ✅ |

- ⭐ **THE +52.0 IS LIKELIHOOD-DRIVEN: loglik +37.82, prior +14.18.** That is the
  `hml_shallow_is_prior_credit` test, and this basin passes it where the 08-28 option-5 refit failed
  it (+4.060 = prior +7.397 / loglik **−1.199**). The prior term is not zero and is not hidden.
- **Biggest stream payers:** `d13c_level_SPO` +8.04, `co2_seasonal_SPO` +7.59, `gcb_land_sink`
  +7.03, `co2_seasonal_MLO` +6.70, `d14c_NH` +5.47. **Biggest payer AGAINST: `co2_gradient` −9.70.**
- ⛔ **GATE 12a DOES NOT CLOSE IN THIS BASIN EITHER — and moves the wrong way.** A 52-log-unit move
  to a different basin buys nothing on the pulse response. That is the strongest evidence yet for
  the standing reading that 12a is an ocean-CAPACITY defect, not a rate or a fitting one.
- **RULING #2 re-priced:** gate 7's land axis improved 0.50 σ ON ITS OWN, and `d14c_deep_ocean`
  barely moved (−4.89 → −4.53). The trade buys less and is needed less.
- **RULING #3 re-priced:** `tau_ex` 1.147 → **0.828**, so gate 5's gap GREW and the seasonal-`tau_ex`
  mechanism's best cell now covers **56 %** of it, against 72 % in the incumbent. ⚠ The numerator
  (+0.268 yr) was measured in the OLD basin and is NOT re-measured here.

⚠ **NOTHING IS ADOPTED. `CCX_MODE_CANONICAL` is unchanged.** No `R/` file was touched, so the suite
stands where 08-31e left it (1275 / 6 FAIL / 2 skip) and was not re-run.

## 2026-08-31e — **THE PROBE'S MODE IS FEASIBLE UNDER THE SHIPPED BRACKET, AND IT IS A SEPARATE BASIN**

`calibration/diag_probe_basin_vs_incumbent.R` (~40 s). Adopts nothing.

08-31d left the +51.9 decomposed by ARITHMETIC and named the missing control — *"the staged refit,
split with the SHIPPED bracket — HAS NOT BEEN RUN"* — and costed it as a refit. **It is not one.**
The probe's mode has `kz` = 6302.37, **inside** the shipped `[3942.5, 6528]`, and `h_ml` = 134.11,
inside the shipped `[30, 200]`; all 22 parameters are strictly interior. So the control is a matched
pair of evaluations under one table.

- **`probe − incumbent = +51.73` under the SHIPPED table** (incumbent = the 08-30 landed mode, md5
  `f4f28060…`, = the probe's own warm start). The handoff's cross-bracket +51.9 survives almost
  intact. ⇒ **the widening contributed NOTHING; the whole gain is available in the un-widened
  problem.** It was never a bracket question.
- ⛔ **NOT `CCX_MODE_CANONICAL`.** `refit_20260825f_from90` predates three of the four stacked
  objective changes and reproduces its own stored logpost only to **−42.99** in today's build. The
  08-30 file reproduces to −0.85. Using the canonical file would have priced the gap at +89.67 —
  **wrong by 38 log-units**, all of it objective drift.
- **NO single-coordinate move from the incumbent is uphill**: split lags alone **−654.53**, `h_ml`
  alone **−330.05**, `kz` alone **−2.71**. Only the joint move gains.
- **Each point is a local maximum in `h_ml` conditional on the rest** (argmax 35.0 m and 135.0 m on
  a 43-point profile across the shipped band, each at its own value).
- ⭐ **MODE CONNECTIVITY: the straight path in `u`-space dips to −1569.54 at t = 0.40 — 21.53
  log-units BELOW the worse endpoint.** ⇒ **two basins, not one hill the 08-30 refit failed to
  finish climbing.** A warm-started local search from the incumbent cannot cross.
  ⚠ **CHECK, surfaced not swallowed:** one straight path bounds what a LOCAL search can reach; it is
  not a proof of topological separation.
- **The incumbent is not converged either** — on its own side of the barrier, t ∈ [0.025, 0.100]
  scores above it, best **+2.43** at t = 0.05. Consistent with the 08-30 run hitting its restart cap
  while still gaining.

⇒ **RULING #4 IS ANSWERED, AND IT IS INDEPENDENT OF RULINGS #1–#3.** The basin question does not wait
on the `kz` bracket. Any refit warm-started from the incumbent inherits the wrong basin, so the
dispersed multi-start is now the load-bearing experiment — 08-31d §5b's recommendation, arrived at by
measurement rather than by one accident.

⚠ **Gates MUTATION-TESTED 2/2**: raising `kz$lo` above the probe's value fires GATE 1 on the probe
alone; narrowing the shipped `h_ml` band fires GATE 4. A `<<-` restoring `CCX_PARAM_TABLE` at script
top level searches ABOVE `globalenv()` and fails — plain `<-` at that scope.

## 2026-08-31d — **THE PROBE: `kz` STAYED PUT WITH 2× THE CEILING — AND FOUND A BETTER MODE ELSEWHERE**

`calibration/output/probe_20260831_kz_wide_support/` (220 min, 84,299 evals, one arm N, commits
`89048f7` + `a323a5d`). Asks `R/calibrate.R`'s stated exit condition — *"delete it only after a
REFIT shows the term holding `kz` alone"* — with **all 22 parameters free**, which neither
`diag_kz_railed.R` (0 free) nor 08-31c PART 3 (3 free) could.

### The support was set by POWER, not by taste

`CCX_WIDEN_PARAMS="kz=3494.9,13265.0"` = the **k = 6σ** bracket re-bisected on GLODAP. The runaway
the bracket exists to stop is the 17-param unbounded mode at `kz` = **10,686**, which on the shipping
model reads deep Δ¹⁴C −125.6 ‰ = **z +4.84**. A support must CONTAIN that or the null is
structurally guaranteed ([[no_power_null]]):

    k = 4 -> [4045.3,  9344.5]  EXCLUDES the runaway -> NO POWER, rejected
    k = 6 -> [3494.9, 13265.0]  CONTAINS it          -> ADOPTED

**k = 6 is the smallest sourced bracket that can fail.**

### THE RESULT — `kz` used none of 6,865 m²/yr of new headroom

    kz  6400.4 (95.1 % of [3942.5,  6528.0])  ->  6302.4 (28.7 % of [3494.9, 13265.0])

**Down 1.5 %, with the ceiling raised 2.03×.** Out of 20 shared parameters it is the **third
least-changed in the whole vector**. Pre-registered reading: this is the "stays interior" outcome,
**suggestive and NOT conclusive** — and the driver says why in its own words:
`*** [N] LAST CYCLE HIT THE RESTART CAP -- this mode is NOT converged`. Restart 4 still gained 0.70
and the BFGS polish then gained **9.07**, the same simplex-collapse signature as 08-20r.

⇒ **This does NOT certify the exit condition met.** It is the strongest available version of "not
violated": a run that travelled a long way, was free to range over twice its old ceiling, and did
not go.

### ⚠ BUT THE GAIN IS `h_ml`'s, NOT `kz`'s — so the probe did not isolate what it was built to

    logpost  -1547.2 -> -1495.3   (+51.9)
    h_ml       35.25 ->  134.11 m (+280 %)   <- inside its UNCHANGED band
    seas_T_amp_SH +278 %, fert_k +63 %, beta_max +20 %, kz -1.5 %

Decomposition, and it is **arithmetic, not measurement**: ≈1.5 is the reparameterisation artifact
(predicted +1.49 from the parameter values before looking, observed +1.5), ≈11.3 the `seas_lag_p`
split, leaving **≈39 that is a better `h_ml` the 08-30 run never found** — it too had hit its restart
cap while still gaining. **The control that would separate these — the staged refit, split with the
SHIPPED bracket — has not been run.**

⚠ **THE FINDING TO FLAG HARDEST IS NOT ABOUT `kz`: THE CANONICAL MODE MAY NOT BE THE MODE.** −1495.3
against −1547.2, driven by a parameter whose band nobody touched. That is direct evidence for the
basin-survey argument in handoff 08-31b §2b, and it is not a bracket question at all.

### Two predictions from 08-31c, both confirmed

- **`kz`'s Hessian entry stabilised.** The morning's step study found `kz` the ONE step-dependent
  coordinate at the `lifted` point; the probe reports **all 22 stable**. That was the
  Jacobian-compression hypothesis (a logit pressed to 95.1 % of its bracket has `dkz/du` compressed
  3.6–10×). ⚠ Confounded — `h_ml` moved 280 % too.
- **Conditioning improved 5.36e5 → 6.84e4**, ~8×. [[ccx_hessian_is_the_blocker]] records 1.11e6 as
  the sampler's blocker.

### FIVE BUGS FIXED (`a323a5d`) — suite 1275 pass / 6 FAIL / 2 skip, the SAME six, no regressions

1. ⛔ **`kz_bracket` was RECORDED AND NEVER RESTORED (HIGH).** The driver has written it since
   08-16 for the reason it states beside `hml_bound` — *"`par_mode` is band-independent; `u_mode`,
   `hessian` and `cov` are NOT"* — and `ccx_mode_params()` / `ccx_adopt_mode_band()` restored only
   `hml_bound`. **Invisible for a fortnight because every file's `kz_bracket` equalled the shipped
   table** ([[default_off_hides_the_bug]]). The probe wrote the first file where they differ, and on
   it the standard idiom decodes `kz` as **4685.5 against a true 6302.4 — 26 % wrong, silently.**
   Recorded bands now live ONCE in `CCX_MODE_BAND_FIELDS`; both functions restore and VERIFY all of
   them. ⚠ A defect I introduced and caught mid-patch: `on.exit` registered INSIDE the restore loop
   captures the loop variable at exit, restoring the last band twice and leaking the rest.
2. **`diag_hess_eps_21par.R` CRASHED (exit 1).** Empty `kb` ⇒ `cumsum(c(TRUE, diff(integer(0))>1))`
   is length 1 while `kb` is length 0 ⇒ `split()` yields one EMPTY group ⇒ length-0 into a
   `numeric(1)` contract, erroring with neither cause nor variable named. Empty because the 08-29k
   C1 remap removed the kinks. Three live sites of the idiom; **the other two were already guarded.**
3. **`min()` of an empty vector** in the driver, printing *"ARM_HML_INIT = 100 is Inf m clear"* every
   run. **Line ~795 of the same file already had the guarded form.**
4. **A gate that could no longer pass**: `!= 3` was the PRE-remap kink count, so it fired every run.
   Expected count is now **0**, measured and named with provenance.
5. **Two "21 coordinates" labels in a 22-parameter build**, now derived from `length()`.

**Not touched, deliberately:** the `intersect()` overlay across 75 scripts — per-caller vs one shared
helper is a design decision parked with Marcus, not a bug fix.

## 2026-08-31c — **THE BRACKET WAS THE ARTIFACT, NOT THE −232: `kz` ≤ 6528 IS A +1.2σ TRUNCATION**

`calibration/diag_kz_bracket_on_the_sourced_target.R` (~18 min). Handoff 08-31b §1a lists the `kz`
bracket as the BLOCKING item, and [[ccx_price_measured_off_support]] says which end of
"−232 vs −285" is right "depends on whether `kz` ≤ 6528 is defensible. Settle the bracket BEFORE the
judgement call." Settled. **It moved the call, and not in the direction 08-31b expected.**

### ⚠ FIRST, A CORRECTION TO 08-31b's OWN FRAMING

08-31b calls the bracket "a numerically-chosen support, **neither an observation nor a law**."
**Half wrong, and it is the half that matters.** The bisection recipe in `R/calibrate.R` *is*
observational — both ends are the `kz` that puts the model's deep ocean at a stated Δ¹⁴C. What is
not sourced is the **target**: `[−200, −150] ‰`, which `R/calibrate.R` itself records as *"an
uncited recollection"*, on the bottom **three** boxes — while the `d14c_deep_ocean` term added
later scores the **bottom box** against GLODAPv2's sourced **−175.3 ± 10.3 ‰** ([[ccx_glodap_deep]]).
So the question was never "observation or not". It was **which observation, on which layer, with
what σ.**

**And the physical-law route is closed with a receipt, not a shrug.** DESIGN §3.4 already prices
`kz` against Ledwell's NATRE thermocline diffusivity, (1.7 ± 0.2)×10⁻⁵ m² s⁻¹ = 536 m² yr⁻¹: the
model runs **7.4–12.2× that by construction**, because a 1-D column's effective diffusivity is
emulating three-dimensional advective transport. [[threshold_from_obs_or_law]]'s law route cannot
bound this parameter at all, so the deep-Δ¹⁴C observation is the *only* bound available — a reason
to get it right, not to shrug.

### PART 1 — the bracket in the units of the observation it encodes

Gated against DESIGN §5.2j's own published bottom-box ends (reproduced to **0.05 ‰**).

| | `kz` | bottom box | z vs GLODAP | 3-box (where it was bisected) |
|---|---|---|---|---|
| lo | 3942.5 | −219.75 | **−4.34** | −199.93 |
| hi | **6528.0** | −162.78 | **+1.22** | −149.96 |

⇒ **a box 5.55σ wide, centred 1.56σ BELOW the sourced target.** `kz` ≤ 6528 is a **hard truncation
of GLODAP at +1.22σ** (on the *mode's* own map, +2.0σ). That is far tighter than the σ = 10.3 the
likelihood term scores the same observable with — **which is why the term never speaks on the high
side and the axis rails.**

### PART 2 — the same recipe, re-bisected on GLODAP instead of the recollection

| k | target ± kσ | → `kz` bracket (defaults) | top vs 6528 | at the MODE's params |
|---|---|---|---|---|
| 1 | [−185.5, −165.0] | [5211.9, **6373.9**] | −154 (−2 %) | [4888.3, 5884.2] |
| 2 | [−195.8, −154.7] | [4763.5, **7146.6**] | +619 (+9 %) | [4495.6, **6529.1**] |
| 3 | [−206.0, −144.5] | [4379.1, **8109.9**] | +1582 (+24 %) | [4154.7, 7314.9] |

⚠ **At the mode's parameters the 2σ top is 6529.1 against the shipped 6528.** Not a plant — the
bisection is at defaults and the sensitivity row is a different map — but it is the cleanest
statement of what the ceiling *is*: **a 2σ cutoff.**

### PART 3 — the land axis on the sourced 3σ support. **THE −232 WAS RIGHT.**

Same frontier, same gates (objective-likelihood gate reads −1494.871 exactly), `kz` on a logit over
the sourced 3σ bracket instead of the recollection's. Prior stays flat inside, every row including
the anchor re-optimised on the same support.

| `beta_max` | d loglik | (08-31b on-support) | d logpost | (08-31b) | `kz` | % of 3σ box | **deep z** | IRF100 |
|---|---|---|---|---|---|---|---|---|
| 0.5552 | 0.00 | 0.00 | 0.00 | 0.00 | 6486.1 | 56 % | +1.94 | 0.283 |
| 0.5000 | −8.27 | — | −8.53 | — | 6608.1 | 60 % | +2.11 | 0.294 |
| 0.4500 | −38.77 | −41.86 | −39.33 | −57.37 | 6799.7 | 65 % | +2.37 | 0.305 |
| 0.4000 | −105.86 | — | −106.87 | — | 7121.6 | 74 % | +2.77 | 0.317 |
| **0.3500** | **−231.96** | **−284.86** | **−233.93** | −298.16 | 7666.5 | 88 % | **+3.39** | 0.330 |
| 0.3000 | −456.94 | −621.25 | −477.52 | −638.23 | 8109.9 | **100 % ⚠** | +3.83 | 0.348 |

⚠ Deltas are comparable WITHIN a frontier only — different prior, different log-jacobian. ⚠ The
0.30 row **rails on my own 3σ ceiling** and is therefore not a clean measurement of anything.

⭐ **AN UNPLANNED CONVERGENCE CHECK, AND IT IS THE STRONGEST THING HERE.** The five non-railed rows
reproduce the *published off-support* `kz` — 6486.0, 6608.1, 6799.6, 7121.6, 7666.6 — to a maximum
of **0.1 m²/yr**. An unbounded `exp(u)` search and a logit search on a 3σ-sourced bracket, written
a day apart for opposite purposes, land on the same optimum. **Both searches converged; the
disagreement was never numerical.**

⇒ **THE 08-31 FRONTIER'S PARAMETERS WERE RIGHT AND ITS SUPPORT WAS WRONG.** `kz` = 7667 at the
gate-7 row is not "ocean mixing the model is not allowed to have" — it is ocean mixing the
*recollection* excluded and the *sourced observation* permits. **−232 is the number; −285 is what
truncation at +1.2σ costs.**

⚠ **THE PROCESS FINDING OF 08-31b IS UNTOUCHED AND STILL RIGHT.** A frontier that optimises outside
its own declared support, with nothing to object because `loglik_of()` never evaluates a prior, is a
real defect and the support gate that caught it should stay. **What was wrong was the remedy: the
fix was to re-derive the support, not to re-price against it.** ⇒ **A GATE INHERITS THE AUTHORITY OF
THE BOUND IT ENFORCES.** Ours enforced a bound with no receipt, and so converted an uncited
recollection into a −53-log-unit correction that read as a discovery.

### ⇒ WHAT §8.3 IS ACTUALLY ASKING, RESTATED

Not "is −232 or −285 the price?" The price is a **curve** in how much deep-Δ¹⁴C misfit is tolerated
(−285 at +1.2σ, −232 at +3.4σ), and the `d14c_deep_ocean` term **already prices that continuously**.
So the question for Marcus is a trade between two independent observations:

> **Will we buy gate 7 (the GCB land/ocean partition) by putting the deep ocean 3.4σ young on
> GLODAP?** At `beta_max` 0.35 both sinks land inside 1σ (land +0.78, ocean +0.16) — reproducing
> the *published* closure exactly, not 08-31b's marginal +0.98 — and deep Δ¹⁴C goes −155.4 → −140.5 ‰.

At z = 3.39 the deep term contributes only ≈ −5.7 log-units of the 232, so **it is not what is being
paid** — the CO₂ streams are, at their usual 40:1 leverage ([[ccx_stream_leverage]]). The bracket
was not preventing that trade. It was **hiding** it: capping `kz` at +1.2σ made the optimiser pay in
likelihood instead of in deep-ocean age, where the cost is visible and scored.

**Gate 12a unaffected either way** — IRF(100) reaches 0.330 (sourced) vs 0.342 (truncated) against
Joos's 0.409. Still the equilibrium/capacity defect.

### The exit condition in `R/calibrate.R` is MET at the mode, and only there

*"Keep the bracket, add the term at n_eff = 20. DELETE IT ONLY AFTER A REFIT SHOWS THE TERM HOLDING
`kz` ALONE."* `diag_kz_railed.R` asked this with every other parameter FROZEN. PART 3's anchor asks
it with `kz`/`fert_k`/`q10` re-optimised — strictly harder — and **the term holds: `kz` turns over
at 6486.1, 56 % of a 3σ box, ≥ 40 % clear of both ends, and identical to the incumbent anchor to
0.1 m²/yr.** Under a *forced* `beta_max` it walks to +3.4σ, but that is CO₂ outvoting the deep term,
which no bracket width fixes.

**NOTHING ADOPTED.** `CCX_PARAM_TABLE` is never mutated (asserted at the end; the guard passed).
Moving the bounds is Marcus's call and `R/calibrate.R` says so in terms. **Three options, and the
staged refit's mode moves under all but the first:**
1. **Keep [3942.5, 6528]** — then say in DESIGN that it is a +1.2σ truncation of GLODAP, chosen
   deliberately, and stop quoting prices measured against it as physics.
2. **Re-bisect on the sourced target at a stated k** — same recipe, one number to choose, and the
   inherited layer/target mismatch goes away.
3. **Delete the bracket and let the term hold `kz`** — the exit condition as written; PART 3's
   anchor is the evidence it is met, and a wide logit (say k = 4) keeps the transform well posed.

## 2026-08-31b — **THE -232 WAS MEASURED OFF-SUPPORT, and the overlay idiom silently defaults**

Handoff 08-31 §8.3 puts "gate 7 closes for −232 log-units" to Marcus as a judgement call. **The
number is measured at parameter values the model's own domain excludes.**

`diag_price_the_gates.R` PART 2 re-optimises `kz`/`fert_k`/`q10` as `exp(u)` — unbounded log. But
`kz` is a **logit** parameter on a hard support **[3942.5, 6528]**. Every land-axis row except the
anchor sits above the top; the row that closes gate 7 uses **`kz` = 7667, 17 % over**, where
`.to_unc()` is `NaN` and the prior is `−Inf`. Part of gate 7's closure was bought with ocean mixing
the model is not allowed to have.

**The defect class.** The 08-31 session added a self-check gate pinning the frontier's LIKELIHOOD to
the objective's, after a truncated likelihood cost 253 log-units of artifact. That gate is necessary
and it passes. **Nothing pinned the frontier's PARAMETERS to the objective's SUPPORT**, and
`loglik_of()` never evaluates a prior, so there was nothing to object.

⚠ **THE OCEAN AXIS IS NOT DAMAGED.** It leaves the support too (`kz` ≤ 3000 is under `lo`), but in
the direction that makes the optimiser's job EASIER, and it still got worse on every gate. **"`kz` is
not the lever" survives**; only the favourable price on the land axis does not.

### The corrected axis (`diag_price_the_land_axis_on_support.R`, ~12 min)

Same frontier, every parameter moving in ITS OWN transform so the search cannot leave the support,
plus a gate — derived from `CCX_PARAM_TABLE`, not a literal, and mutation-tested exact at the
boundary — that refuses to report an off-support point.

| `beta_max` | d loglik | published | d logpost | z_land | z_ocean | IRF100 | `kz` |
|---|---|---|---|---|---|---|---|
| 0.5552 | 0.00 | 0.00 | 0.00 | +2.35 | −0.78 | 0.283 | 6486 (98 %) |
| 0.4500 | −41.9 | −38.8 | −57.4 | +1.79 | −0.59 | 0.306 | 6528 (100 %) |
| **0.3500** | **−284.9** | −232.0 | **−298.2** | **+0.98** | −0.34 | 0.342 | 6528 (100 %) |
| 0.3000 | −621.3 | −449.4 | −638.2 | +0.40 | −0.15 | 0.368 | 6528 (100 %) |

**Gate 7 still first closes at `beta_max` 0.35, so §8.3 is still a live call — at −285 likelihood /
−298 posterior, 23 % more than quoted.** But the closure is MARGINAL: `z_land` **+0.98**, inside by
0.02, against the off-support +0.78; and `z_ocean` never crosses over on support, so the published
"both sinks inside, ocean at +0.16" was partly the off-support `kz`.

⚠ **THE PRICE IS SET BY A BRACKET, NOT BY PHYSICS.** At every point below the anchor `kz` rails at
**exactly 6528** — the constrained optimum is ON the boundary, so it still wants to go higher. That
bracket was re-bisected for the pump on 08-16e: a numerically-chosen support, neither an observation
nor a law. **−232 and −285 BRACKET the truth**, and which end is right depends on whether `kz` ≤ 6528
is defensible. Settle that before the judgement call; it is cheaper and it moves it.

> ⛔ **SUPERSEDED 2026-08-31c — SETTLED, AND IT WENT THE OTHER WAY. DO NOT QUOTE −285 AS "the
> corrected price".** The bracket IS observational (bisected on deep Δ¹⁴C); what is unsourced is its
> TARGET, an uncited recollection on the wrong layer. On a support re-bisected against GLODAP the
> price is **−232.0**, reproducing the "off-support" number, and the five non-railed rows reproduce
> its `kz` to **0.1 m²/yr**. The frontier's PARAMETERS were right; its SUPPORT was wrong. See the
> 08-31c entry above and `diag_kz_bracket_on_the_sourced_target.R`. The support-gate defect this
> entry found is real and its gate stays.


Gate 12a is unaffected — IRF(100) reaches 0.342 of Joos's 0.409. Still the equilibrium/capacity
defect, closable on neither axis.

### ⚠ AND `diag_price_the_gates.R` CANNOT BE RE-RUN IN THE 22-PARAMETER BUILD

Its own likelihood gate hard-stops it, which is how this surfaced. The cause is a THIRD instance of
live-names-meet-a-stored-vector, and the only SILENT one so far:

    for (n in intersect(names(base), names(p0))) base[[n]] <- p0[[n]]

`p0` is a 21-parameter mode, `base` a 22-parameter default. `intersect()` does not error — **it
omits** — so the fitted NPP lag is dropped and `base` runs at the DEFAULT **2.25** instead of the
fitted **1.7502**. The gate then reads **−3187.902 against −1494.871: 1693 log-units**, because the
seasonal CO₂ streams carry the model's highest leverage (`co2_seasonal_MLO` 4118). Routing `p0`
through `ccx_migrate_par_set()` restores it to −1494.871 exactly.

**Blast radius, and it splits on whether a guard exists.** 75 calibration scripts use an `intersect`
overlay; 20 mention `param_names` at all. **The app is guarded and degrades honestly** —
`app/global.R:121` skips any mode whose `param_names` mismatch, so it refuses all stored modes and
falls back to hand-set values under a banner that says "not fitted to anything". The unguarded
diagnostics do not. **Not fixed beyond the one script this needed: 75 call sites, and whether the fix
belongs per-caller or in one shared helper, is Marcus's ruling.**

⇒ **THE RULE THE DAY ARGUES FOR: `intersect()` on a stored parameter vector converts a version
mismatch into a SILENT DEFAULT.** Of today's three instances, the two caught fast were caught because
something asserted a CONTRACT — the objective's own gate, and a loop over `CCX_PARAM_NAMES` that
refuses a `NULL`. The one that cost real numbers is the one that treats absence as normal.

## 2026-08-30 — **THE 7 FAILURES RULED ON — and a THIRD one-core-only default found**

Handoff 08-30 left 7 attributed failures for Marcus. All measured first
(`calibration/diag_attribute_the_seven.R`), and **two of the five sketches in that handoff were
wrong**:

- **test-likelihood.R** was filed as *"re-guard AFTER the refit"*. **It cannot be**: `lik_fixture()`
  runs on `ccx_default_params()`, not the fitted mode, so the owed 21-param refit does not touch it.
  `b0` is **linear in `gamma_diff`** (2.418 / 2.718 / **3.017** at γ = 0 / 0.125 / 0.25, +2.40 ppm per
  unit) and was already at **81 % of its bar before the adoption**. The curvature `A` — which the
  test's own comment calls the load-bearing, scale-free half — is **26.398 at all three**, unmoved.
- **test-mode-file.R** was filed as *"stored logpost changed, refresh provenance"*. The
  **stored-logpost assertion passes.** What fails is the **recomputed** gap, which that file argues is
  objective-independent "because it is a GAP between two vectors scored by the SAME harness". True for
  a **common shift**; `gamma_diff` is not one — it changes the MODEL and the arms sit at different
  `fert_k`. gap = **−11.4936 / −14.8961 / −19.8635** over the same γ. `PIN_PRIOR_CREDIT` is a PRIOR
  term with no γ dependence, so the whole **+8.4 is a LIKELIHOOD differential**: diffuse light costs
  pin90 more than the canonical arm. A finding, not drift.

And the **conveyor** failure is not "volcanoes drive NPP across the run" either: the **CMIP7 AOD
series begins in 1850**, so 99 of that test's 100 years are already volcanically silent. What trips it
is the record's **turn-on step landing on the run's LAST year** — the one year an
endpoint-minus-start gate reads.

### ⚠ A THIRD SILENT ONE-CORE-ONLY DEFAULT — found, fixed, mutation-tested

The 08-29k entry above says the adoption used the `CCX_FERT_FORM_DEFAULT` pattern "so R and C++
cannot disagree about what a parameter list without the field means". **Only `ccx_cpp_par()` got the
constant.** `ccx_deriv()` still hardcoded `if (is.null(p$gamma_diff)) 0`, so a parameter list
**without** the field reached the R reference as 0 and the C++ as 0.25 — an R↔C++ parity break of
**0.647 GtC/yr** at Pinatubo (vs 0.07 for yesterday's out-of-bounds read). **`ccx_mode_params()` is
such a list**: the fitted 21 do not carry `gamma_diff`.

⚠ **The adoption's own parity hardening could not catch it, for a good reason.** It pins parity at
**explicit** γ = 0 / 0.25 / 0.97 — deliberately, so coverage would not move if the default moved. An
explicit value **never exercises either fallback**. The general lesson, now encoded as `test-parity.R`
item 5: **a default has TWO contracts — what the value IS, and what ABSENCE MEANS — and pinning only
the first leaves the second free to drift between the cores.** Third instance in three days of one
core being taught something the other was not (`N_FORCING`, the `f[15]`/`f[16]` read, this).

### The rulings (Marcus, 2026-08-30)

1. **"Quiet" means volcanically quiet too** (conveyor ×3 + LUC ×1). `quiet_forcing()` and
   `lp_background()` zero `aod_NH`/`aod_SH` themselves — which is what `R/forcing.R` already
   instructs, and the same shape as this suite's existing precedent of running the LUC control
   *seasonless* rather than loosening its gate. Conveyor drift **0.0246 → exactly 0.00000** ppm; LUC
   control **0.2322 → 0.0437** against its 0.05 gate. ⚠ **Only the flatness PRECONDITION was ever
   affected** — the three assertions the LUC gate exists for are pulse-minus-control DIFFERENCES, so
   the volcanic signal cancels: af_foss 0.1506 → 0.1513, ratio 1.033 → 1.032, 150-yr 0.864 → 0.867.
   Both helpers now carry a **mutation test** at an EXPLICIT γ, so the zeroing cannot go vacuous.
2. **The CO2 level bar is DERIVED, not rounded up** (`calibration/diag_co2_level_bar.R`). A uniform
   model shift is degenerate with a systematic level offset in the record, so the bar is that
   record's level uncertainty: **`LIK_ICE_REP_ERR` = 4.0 ppm**. Validated against a fully external
   **floor** — Law Dome vs **SPO** (like-for-like Antarctic; against MLO the comparison carries the
   real interhemispheric gradient and reads 1.6 ppm larger for no reason of record quality) over
   their 1962–1996 overlap, **RMS 1.087 ppm**, no model or likelihood weight involved — which shows
   the constant is **3.7× conservative**. ⚠ The floor is **BLIND** to gas-age, firn smoothing and
   model-vs-ice representation (both records there are modern, precise and Antarctic), so it bounds
   from below and is **not** the bar. ⚠ Coupling stated: `LIK_ICE_REP_ERR` is inside the objective,
   but the dependence runs the wrong way to self-satisfy — inflating it *down*-weights the ice and
   pulls `b0` toward the MLO/SPO-only optimum. Mutation-tested at 2× the bar.
   **b0 = 3.017 is inside the bar (75 %) but 2.8× the floor** — a model-quality statement to re-read
   after the refit.
3. **test-mode-file.R stays FAILING, deliberately**, and the measurement is recorded in the file so
   the next session does not re-derive it. Re-measure `PIN_PRIOR_CREDIT` after the refit; deriving it
   now would bake in a number taken from vectors that are about to be replaced.
4. **test-volcanic-diffuse.R's default contract INVERTED** (the 08-28 h_ml-gate precedent), and
   re-aimed: it now asserts **the named constant** rather than a bare literal, so it breaks on a
   CONTRACT change instead of on a value change, and it pins **absence** in both cores.

**Tried and rejected:** loosening the conveyor/LUC tolerances to admit the volcanic signal (costs
both gates real power — 30× and 6× — and confounds "did the conveyor drift" with "did the volcano do
something"); making `ccx_hold_climate()` zero AOD (contradicts the 08-29 ruling that AOD is a
radiative driver, and would silently disable diffuse light in every climate-held diagnostic).

### Suite: **1243 pass / 1 fail / 2 skip**

The single remaining failure is `test-mode-file.R:206`, **failing on purpose** by ruling 3 above; the
reason is written into the file so it cannot be mistaken for a regression. Six of the seven are
resolved, and the run is +16 assertions over the pre-ruling 1227 (the new mutation tests and the
parameter-absence parity contract).

**Still owed and unchanged:** the 21-param refit. Nothing quantitative off the calibrated 21 is
quotable until it lands. ⚠ **Run it AFTER this commit, not before** — the absence-default fix changes
what `ccx_deriv()` computes for any parameter list lacking `gamma_diff`, and the R core is the
reference the C++ is checked against.

## 2026-08-29k — **BOTH ADOPTED (Marcus), AND THE ADOPTION EXPOSED AN OUT-OF-BOUNDS READ**

Marcus adopted **both** open calls from 08-29i/j: `gamma_diff = 0.25`, and the **CUM** C1 remap.

### The adoptions
- `CCX_GAMMA_DIFF_DEFAULT <- 0.25` in `R/model.R`, used by BOTH `ccx_default_params()` and
  `ccx_cpp_par()` — the `CCX_FERT_FORM_DEFAULT` pattern, so R and C++ cannot disagree about what a
  parameter list without the field means. **0.25 is NOT behaviour-preserving and that is the point:
  everything fitted before today was fitted at 0 and is NON-COMPARABLE.**
- `ccx_pump_shape()` now interpolates the **CUMULATIVE integral** with a monotone C1 spline, instead
  of overlap-integrating piecewise-constant bins. **All 26 kinks on [30,200] are gone**; conservative
  to **3.3e−16** whenever a layer spans whole bins.

### ⚠ THE BUG THE ADOPTION EXPOSED — an out-of-bounds read, live for two days

`ccx_deriv_fast()` builds a **flat** forcing vector the C++ indexes **by position** against
`CCX_FORCING_COLS`. When `aod_NH`/`aod_SH` were appended on 08-29g, `CCX_FORCING_COLS`, the C++, and
the MATRIX builder `ccx_cpp_forcing()` were all extended — **this single-step builder was not.** It
stopped at `sink_ocean`, so the core read `f[15]`/`f[16]` **two slots past the end of a 15-element
vector.** Neither language reported anything.

**It was invisible because `gamma_diff` defaulted to 0** — the out-of-bounds value was multiplied by
zero. **Adopting 0.25 is what exposed it**, as an R↔C++ parity break of **~0.07 GtC/yr** in the
NPP-fed pools (atm/leaf/wood, every tracer block), 18 of 96 states. Parity was exact (1.6e−13) at
`gamma_diff = 0` and broke at 0.25 — which is how it was attributed in one step.

⚠ This is the **second** time in three days that appending those two columns bit through
position-indexing; 08-29f was `N_FORCING` not being bumped. Both were silent. **The fix is
structural this time**: `ccx_deriv_fast()` now ERRORS if its vector is not `length(CCX_FORCING_COLS)`,
and `test-parity.R` pins the length, the parity at **explicit** γ = 0/0.25/0.97 (so coverage does not
move if the default moves — which is exactly how this survived), a **loud-AOD mutation test**, and
the absence contract. **Mutation-tested**: re-introducing the bug fails 7 assertions; the fix passes
all 53.

### Suite: 1227 pass / **7 fail** / 2 skip — and the 7 are attributed

Re-running with the remap adopted but `gamma_diff` back at 0: **all 7 pass.** So **the C1 remap
breaks nothing**, and every remaining failure is the `gamma_diff` adoption invalidating a contract
that was written against `gamma_diff = 0`:

| test | why it fails | what it needs |
|---|---|---|
| `test-volcanic-diffuse.R` "gamma_diff defaults to 0 and 0 is behaviour-preserving" | asserts the OLD default | rewrite to the adopted contract |
| `test-conveyor.R` "a quiet run does not drift" (3) | a quiet run is **no longer quiet** — volcanoes now drive NPP. Handoff 08-29c §8 predicted exactly this | decide what "quiet" means post-adoption |
| `test-luc-permanence.R` "a pulse is not given back" | same cause | same |
| `test-likelihood.R` "a CO2 level bias is expensive" | fitted offset 3.017 ppm vs a `< 3` guard — **the level moved, the refit is OWED** | re-guard after the refit |
| `test-mode-file.R` "stored logposts do not decide it" | the stored logpost changed, as every objective change makes it | refresh provenance |

**NOT TOUCHED.** Per the standing rule a previously passing test is not edited to make it pass —
reported and left for Marcus. ⚠ **The 21-param refit is OWED and NOT RUN**, and until it is, the
calibrated 21 are a pre-adoption vector being read under a post-adoption objective.

⚠ **The remap breaking zero tests is not a clearance.** GATE B measured it moving the pump field
9.6–15.8 % of a layer step; the suite simply has no guard on that. That is a statement about the
suite's power, not about the change's size.

## 2026-08-29j — **PLAN ITEM ②, MEASURED: THE C1 DEFECT IS 8.7× BIGGER THAN RECORDED, AND THE FIX IS NOT FREE**

Two drivers, both measure-only: `diag_hml_c1_kinkmap.R`, `diag_hml_c1_remap_price.R`.
**No model code touched, nothing adopted.**

### ① The "sparse, 3 kinks" verdict was BAND-DEPENDENT and is superseded

`ccx_hml_kink` recorded **3 kinks** in `h_ml`, *"sparse — 5 of 3499 probe points"*, which is why the
C1 defect was filed as a caveat rather than a blocker. **That was measured over the refit band
[85,120], and the σ-inflation adoption of 08-28 RETIRED that band** — `h_ml` now has an interior
maximum over its full prior support **[30,200]**, 4.9× wider.

Re-measured there: **26 kinks**, density **0.086 → 0.153 per metre (1.78×)**, closest pair **0.33 m**
apart. They **cluster on the 25 m GLODAP bin edges** — tight groups at h_ml = 50, 75, 100, 125, 150,
175 — because `h_ml` is the first layer boundary and the deeper boundaries scale with it.
⚠ **`CCX_PARAM_TABLE$h_ml$init = 75` sits EXACTLY on a kink**, as `ARM_HML_INIT = 100` already did.
Harmless to Nelder-Mead; not harmless to anything gradient-based started there. The incumbent mode
(96.47 m) is 1.94 m clear and the rejected option-5 refit (35.38 m) 11.47 m clear, so **no fitted
mode is contaminated** — the probability-of-landing-on-one reading survives; the *traverse* reading
does not.

### ② A conservative C1 remap exists, and it works

The kink is a **box filter with hard edges**: the stored shape is treated as piecewise-CONSTANT in
each bin, so its antiderivative is only piecewise-linear and the layer mean `(S(b)−S(a))/(b−a)` has
slope jumps wherever a boundary crosses a bin edge. Two candidates priced:

| | kinks in [30,200] | reproduces a whole bin's mean | field move at the mode |
|---|---|---|---|
| incumbent (clamped overlap) | **26** | 0 by construction | — |
| **MID** (Hermite thru bin *midpoints*) | 0 | 2.0e−3 — **not conservative** | 26.7 % of a layer step |
| **CUM** (C1 spline of the *cumulative* integral) | **0** | **3.3e−16** | **15.4 % of a layer step** |

**CUM is the right construction**: the bin averages pin the cumulative integral EXACTLY at every bin
edge, so interpolating **S** rather than **shape** is C1 *and* conservative. Mutation-tested — the
gate fails the incumbent (3 kinks in [90,110]) and a C0 linear control (167), passes CUM (0).

### ③ ⚠ BUT IT IS **NOT** "A CODE FIX, NOT A SCIENCE CHANGE"

The plan note argued ② is a pure code fix. **The measurement refutes that.** CUM moves the pump
field by **9.6–15.8 % of the median layer step** across the band (15.4 % at the incumbent mode) —
and the export is a *difference* of adjacent layers, so that is the scale the pump actually uses.

And the deeper point: **a remap's behaviour between bin edges is a SUB-BIN MODEL, and the data do
not contain one.** CUM invents smooth sub-bin structure exceeding the local 3-bin range in **10 of
29 intervals**, worst **42 % of a bin step at ~450 m** (the thermocline, where the profile curves
hardest). But the **incumbent asserts the shape is CONSTANT within a bin** — equally absent from the
data, and exactly what makes it kinked. **Neither remap is "the observations"; they are two
different sub-bin assumptions, and choosing between them is a methodological call.**

⇒ **FOR MARCUS.** Adopt CUM (C1 restored, conservative, pump field moves ~15 % of a layer step and
`pump_grad` would want a refit), or keep the incumbent and carry 26 kinks on the live support.
Not resolved here.

## 2026-08-29i — **THE FACE GATE CLEARS, AND THE GATE WAS FRAMED AROUND THE WRONG NUMBER**

`calibration/diag_face_check_gamma_diff.R`. Handoff 08-29c §6 left one check gating adoption of
`gamma_diff`: *"the −7.42 is paid by `fert_k` +28.9 % … FACE is the only thing bounding this
direction."* Both halves of that framing are wrong, and correcting them is most of the result.

**① The +28.9 % is the γ = 0.97 number, and γ = 0.97 is already rejected** (14× dearer, fits the
record worse). At the **γ = 0.25 operating point the payment is `fert_k` +6.1 %** (154.84 → 164.23)
with `beta_max` +2.3 % — a fifth of the movement the gate was written against.

**② FACE does not cap `fert_k`.** That ceiling was **withdrawn 2026-08-25** on Marcus's ruling —
*"the exact numbers shouldn't be a constraint because FACE is only temperate forests, but FACE can
still inform response shape and realistic limits."* The ceiling exists only if you adopt the
**21.8 % plantation-weighted** headline, and at ≤ 15 % assumed response there is no ceiling anywhere
in [20, 2000]. So the driver tests what FACE *does* constrain — the **ridge coordinate's implied
FACE response** `R(400 → 564)` — against the observed **bracket**, and reports the ceiling only to
show the distance to it.

| γ | `beta_max` | `fert_k` | **R(400→564)** |
|---|---|---|---|
| 0 (mode) | 0.5109 | 154.84 | **8.61 %** |
| **0.25** | 0.5228 | 164.23 | **8.87 %** |
| 0.97 | 0.5701 | 199.58 | 9.76 % |

**GATE-N PASSES: 8.87 %, +0.26 pt on the mode**, at the **mature-forest end** of the bracket
(EucFACE ~0 %, BIFoR-FACE +10 %), far under the 21.8 % synthesis and the **32.1 % box maximum**.
**GATE-M**: the pair moves **along** the ρ = +0.998 ridge (both up), and the withdrawn ceiling
(~1374 at ambient 400) sits **8.4× above** the operating point — it was never the operative
constraint. ⇒ **γ = 0.25 is defensible on FACE. The `fert_k` payment is not a provenance problem.**

**Estimator validated against three recorded cells** — design 7.8 %, old adopted mode 13.6 %,
pinned-`luc` probe 17.2 % (memory says 17.3 %) — same MM form as
`diag_face_prior_for_beta_max.R`, so this is like-for-like, not a second opinion.

**⚠ MEASURE THE GATE'S POWER BEFORE READING ITS PASS.** GATE-N only fires above 21.8 %: the
mutation test FAILS the young-plantation cell (3.0 / 340 → 32.0 %) but **PASSES the pinned-`luc`
probe at 17.2 %**. That is correct behaviour on Marcus's ruling — over this range **FACE brackets,
it refutes nothing** — but it means the pass is informative through the **distance** (8.87 % is a
third of the box maximum and moves 0.26 pt), not through the bare verdict.

**Nothing adopted.** `gamma_diff` still defaults to 0; the calibrated 21 are untouched.

## 2026-08-29h — **DIFFUSE LIGHT PRICED: CHEAP (−7.4), AND THE CORRELATION GAIN IS REAL**

Marcus: *"Price gamma_diff conditionally first."* Slice `beta_max, fert_k, q10, rep_dC`.

| γ | frozen | **conditional** | buy-back | **r** |
|---|---|---|---|---|
| 0 | 0 | 0 | — | 0.571 |
| **0.25** | −40.5 | **−7.42 CHEAP** | **82 %** | **0.624** |
| 0.50 | −160.8 | −28.7 | 82 % | **0.626** |
| 0.97 (matches Pinatubo) | −601.3 | **−105.5** | 82 % | 0.575 |

**The frozen cost overstated the price by 82 % at every γ** — handoff 08-25b §7 again. **H4: the r
gain SURVIVES refitting**, so the mechanism supplies real signal rather than borrowing from frozen
parameters (contrast ENSO, whose r was flat across an 11× range). H5: land sink moves ≤ 0.057
GtC/yr. **Matching the Pinatubo feature costs 14× more than γ = 0.25 and fits the record WORSE.**

### ⚠ H3 REFUTED MY OWN MECHANISM, WHICH IS WHY IT WAS THERE
I proposed in 08-29g that the cost was a **cumulative CO₂ level offset**, put `rep_dC` in the slice
so it could be refuted, and gated the mechanism separately. **H2 passed on the number and its
printed verdict "LEVEL OFFSET CONFIRMED" is WRONG**: `rep_dC` moved **−0.01 prior-sd**. The absorber
is the **FERTILISATION PAIR** — `fert_k` **+28.9 %**, `beta_max` +11.6 % along their ρ = +0.998 ridge.

### ⚠ SO "CHEAP" IS CONDITIONAL — AND THIS GATES ADOPTION
**`fert_k` is the one parameter in that slice with an EXTERNAL constraint**: FACE caps `fert_k` and
cannot prior `beta_max`, so FACE is the only thing bounding this direction. **Cheap in logpost is not
cheap in provenance. NOT YET CHECKED: is `fert_k` 164–200 inside the FACE-informed range?**

**Largest payer is `co2_icecore` (−4.53), not the station rows** — the AOD series' biggest event is
**Krakatau 1884**, so the amplitude is constrained by smoothed ice cores more than by Pinatubo at MLO.

### Also settled
**`ccx_hold_climate()` is KEPT** and is not replaced by the app's checkboxes: all 10 callers are
diagnostics and TESTS, it FREEZES (usually at 0) rather than decomposing, and the
warming/ENSO/volcanic decomposition is not exhaustive so three boxes cannot reproduce it. Tests must
not depend on a regression fit. Build the checkboxes as a separate forcing-side layer.

## 2026-08-29g — **VOLCANIC DIFFUSE-LIGHT LANDED: r 0.571 → 0.625**

Plan item ①, on Marcus's instruction. `NPP_h = npp0_h * capacity * fert * (1 + gamma_diff * AOD_h)`
(Gu 2003; Mercado 2009), wired at six sites with R and C++ twins in parity and four tests.

**`gamma_diff` DEFAULTS TO 0** — every pre-2026-08-29 result is bit-identical (logpost at `u_mode`
still −1546.276578) and the calibrated 21 stay comparable. It is a `base_param` like
`ent_seas_amp_SH`; fitting it is a separate decision.

| `gamma_diff` | 1992 | sd | **r** | Δlogpost frozen |
|---|---|---|---|---|
| 0 | +0.043 | 0.301 | 0.571 | 0 |
| **0.25 / 0.50** | −0.47 / −0.98 | 0.32 / 0.36 | **0.625 / 0.625** | −40 / −161 |
| 0.97 | **−1.934** | 0.491 | 0.573 | −601 |
| observed | **−1.937** | 0.900 | 1.000 | |

**⇒ r RISES — the first change this session that makes the model MORE RIGHT rather than louder**
(ENSO's r was flat across an 11× amplitude range). ⚠ **The two optima disagree**: Pinatubo wants
γ ≈ 0.97, correlation wants 0.25–0.50. Reproducing a FEATURE and fitting the RECORD are different
targets. **NOT ADOPTED** — the Δlogpost column is FROZEN, frozen costs are upper bounds, and the
conditional profile is the next step.

### ⚠ THE N_FORCING TRAP, WALKED INTO AND THEN GUARDED
`src/ccx_core.cpp:52` hardcodes the forcing row width and its own comment says *"a disagreement in
the ceiling is NOT caught by anything."* I appended two columns without bumping it, so `f[15]` and
`f[16]` read **past the row buffer** and returned adjacent memory: **−0.0004 ppm of effect instead
of −4.1, nothing errored, no test failed.** R↔C++ parity caught it (now 4.5e-13 with the mechanism
on). The new test's third case is the mutation test: **turning the mechanism ON must MOVE the
answer** — a test that only checks the OFF value could never see this.

⚠ **CORRECTION.** I first wrote that "nothing else would have caught it". **False**:
`test-forcing.R:127` pins `length(CCX_FORCING_COLS)` against `N_FORCING` and failed as soon as the
suite ran — I had reported before running it. Extended to 17 (the deliberate edit the pin exists to
force). A second failure, `test-so-entrainment.R`'s climate inventory gate, forced a decision about AOD's
classification. **I answered it wrong and Marcus corrected it.**

### ⚠ THE AOD ARCHITECTURE (Marcus, 2026-08-29)
*"The AOD should be a diffuse light → NPP mechanism, with the AOD → climate mechanism implicit in
the existing temperature record (and then backed out with FaIR or Foster-Rahmstorf for removing
volcanic influence through the checkbox)."*

⇒ **THE MODEL HAS EXACTLY ONE AOD PATHWAY: diffuse light → NPP.** AOD is a **RADIATIVE DRIVER, not
a climate variable**, so `ccx_hold_climate()` does **NOT** freeze it — the volcanic temperature
effect is already carried by the observed `gmst` that function DOES hold.
⚠ **NEVER add an AOD → temperature term: it would DOUBLE-COUNT the cooling `gmst` already has.**
⚠ **Consequence, documented at the call site:** once `gamma_diff` ≠ 0, *"climate held" does NOT
imply "volcanically quiet"* — a diagnostic needing a quiet run must zero AOD itself.
⇒ **The app's "volcanoes off" is TWO forcing-side edits, neither sufficient alone:** zero AOD (the
NPP path) AND subtract the volcanic component from `gmst` (the thermal path, via FaIR's
volcanic-free run or the Foster–Rahmstorf regression term).

**Suite GREEN: 1226 pass / 2 skip / 0 fail.**

### Decisions recorded
GMST decomposition uses a **Foster–Rahmstorf-style regression as primary**, FaIR as cross-check;
the pulse tab gets **three charts** (total CO₂; tracer fraction by box; added CO₂ by box — the last
two being exactly the label/perturbation pair that differ 2.8× at 100 yr); **more tabs are fine**;
**the hemispheric tab is deferred until the component is fixed**; **four-box is HELD**.
**Next: ② make the objective C1 in `h_ml`, then ③ seasonal `tau_ex`.**

## 2026-08-29f — **AOD IN HAND, ENSO PROFILED, AND THE ORDER DECIDED**

### The cheap test (Marcus's "do this first"): the two defects are INDEPENDENT
Gate 7 moves **+0.001 GtC/yr** across the whole seasonal-fix family where it needs **−1.148**, and
the path is structurally absent — `seas_r_norm` removes the Jensen rectification by construction.
Named in the prereg BEFORE the run so the null could not be mistaken for a measurement.

### An AOD series
`data/forcing_volcanic_aod.rds` from NASA GISS **`tau_reff_CMIP7-2-2-1.nc`** (1.23 MB) — CMIP7
chosen **like-for-like with the project's FaIR calib 1.6.0 + CMIP7 drivers**. Global + NH + SH,
monthly, exact sin(lat) band weights. Gates pass: Pinatubo peak global AOD **0.1070** (lit.
0.08–0.20), quiet-year 2005 0.0043, and the two largest events come out as **Krakatau 1884 (0.110)
and Pinatubo (0.107)**, correctly. ⚠ **Pre-1850 is ZERO — Laki 1783, 1808/09 and TAMBORA 1815 are
missing** (need eVolv2k); 2024 held at 2023-12. Provenance in `download_data.R` + `MANIFEST.csv`.

### `gamma_enso` profiled: louder, not righter
Across γ = 0.4 → 4.0 (sd 0.223 → 0.953 against an observed 0.900) **r stays flat at 0.54–0.57.**
The frozen argmax is **exactly** the fitted 0.85119 — the fit was asked and refuses, at **−62.6
frozen / −61.3 conditional: MODERATE, not the PROHIBITIVE I predicted.** Largest objector is
**`gcb_land_sink` −21.72 (35 %)**, a new untested link to gate 7.
⇒ **the missing 2/3 of the interannual variance is NOT ENSO amplitude**, and the biggest single
miss — Pinatubo — needs **diffuse-light fertilisation**, since the thermal path can supply ≤ 7 %.

⚠ **Two more of my own gate verdicts were wrong and are corrected in the collect note**: E1's
"the response SATURATES" is an artefact of quadrature-subtracting *correlated* components (on a
valid estimator the response is linear to **0.25 %**), and the closing "the fit was never asked"
contradicts E2, which shows it was. Third instance today of a verdict string asserting a mechanism
the measurement does not establish.

### The order (`notes/plan_2026-08-29_implementation_order.md`)
① volcanic diffuse-light (additive, largest miss, AOD in hand, the tool needs it) → ② make the
objective C1 in `h_ml` **before any refit** → ③ **seasonal `tau_ex`** as the CHEAP test of the
gradient-vs-lag tension → ④ 4-box atmosphere **only if ③ fails** → ⑤ per-box NPP lag (**demoted**:
③/④ change what "per hemisphere" means) → ⑥ gate 7 → ⑦ ENSO response shape (lowest).

### The six-tab spec (`notes/spec_2026-08-29_app_six_tabs.md`)
Recorded as requirements, mapped onto the existing app, with three flags: the four checkboxes need
an **attributable GMST decomposition** and **FaIR supplies the volcanic half but NOT ENSO** (internal
variability — needs Foster–Rahmstorf-style regression); the pulse tab must show **label and
perturbation separately** (2.8× apart at 100 yr); and "What if…?" / "Under the hood" are displaced.

## 2026-08-29d — **THE LAG IS PROHIBITIVE, AND THE BLOCKER IS MODEL STRUCTURE**

`calibration/diag_price_the_lag.R`, prereg `1f3731c`. Q0 PASS on all six controls.

| lag | θ | frozen | **conditional** | buy-back | SH-land | `seas_T_amp_SH` |
|---|---|---|---|---|---|---|
| 1.7677 (mode) | 152.9° | 0 | 0 | — | 1.308 | 1.0391 |
| 2.00 | 160.2° | −391.5 | −184.8 | 53 % | 1.231 | 1.7960 |
| **2.25** | **168.1°** | −1599.9 | **−838.3** | 48 % | **1.071** | **3.4945** |
| 2.50 | 176.0° | −3456.7 | −1972.9 | 43 % | 0.890 | 5.4056 |

**Q4 → PROHIBITIVE** (bands CHEAP ≤ 20 / MODERATE ≤ 100 / PROHIBITIVE > 100). 27n's lever cost −35
conditionally; **this is 24× that.** ⚠ **My registered prediction was MODERATE, −20 to −60 — wrong
by an order of magnitude.**

**Q1 PASS: the NH pays 94 %** — `co2_seasonal_MLO` −586.96 + `d13c_seasonal_MLO` −201.57 of −838.32.
**The reason is STRUCTURE, verified at `src/ccx_core.cpp:386`, not inferred:** `SEAS_PHI_EFF` is
indexed by hemisphere but **`seas_lag_p` is a SCALAR** and shifts NPP phase in BOTH.
`seas_npp_amp[2]` and `seas_T_amp[2]` are already per-hemisphere arrays a few lines away — **the lag
is the one that is not.** The SH needs its NEP ~12° later, the NH does not, one knob serves both,
and the part the model fits BEST pays for asking. **Q2 PASS** (frozen SH-land moves −1.9 % while the
floor falls 0.632 → 0.283: the lag opens the door, it does not walk through it). **Q5 PASS**
(r_SPO 1.930 → 1.956, away from the observed 1.00).

### ⚠ Q3 FAILED, IN THE INFORMATIVE DIRECTION

I predicted `seas_T_amp_SH` would not rise — the CO2 seasonal rows are matched by cancellation and
"have no power". **It rose 1.0391 → 3.4945 at lag 2.25 and 5.4056 at 2.50, taking SH-land 1.308 →
1.071 → 0.890 (1.92× observed → 1.57× → 1.30×).** ⇒ **once the geometry permits cancellation the fit
USES it, unprompted.** That REFRAMES the no-power reading rather than overturning it: the rows still
cannot SEE the partition error, but they will spend a lever that PAYS, and at θ = 152.9° this one
did not. **The SH defect is fixable and self-fixing; only the shared lag's NH bill blocks it.**

### ⇒ THE INDICATED NEXT STEP IS A MODEL CHANGE, AND IT IS A DESIGN CALL

**`seas_lag_p` → `seas_lag_p[2]`**, exactly analogous to the amplitude arrays. Prediction to
pre-register: **the NH's −788 disappears** (untouched), leaving ~−35 to −50 of SH-side cost against
SH-land 1.308 → ~1.07. It adds a 22nd calibrated parameter, and `SEAS_T_LAG` (the respiration phase,
also global, also compile-time at `ccx_core.cpp:168`) is an equally valid place to open the same
angle. **Marcus's call. NOT STARTED.**

### OPEN, FLAGGED NOT RESOLVED

The `seas_T_amp_SH` prior gain measures **+90.66** here (`prior(log(x))` −99.09 → −8.45) where 27n
recorded **+8.34** for the analogous move. `ccx_prior_z()` returns **−4.6387**, matching 27n's
−4.64 σ exactly, so the prior's z has NOT changed and the two numbers measure different things.
**Neither may be quoted as "the prior credit" until settled.** Nothing above depends on it.

**Nothing adopted.** `seas_lag_p` stays at the mode, `seas_npp_amp_SH` stays 0.5027,
`ccx_mode_file()` still resolves `from90`.

## 2026-08-29c — **THE PAIR IS (GROSS × PHASE), AND FOUR OWED DECISIONS ARE CLOSED**

Marcus's ordered instruction: follow all five recommendations from the 08-29b decision list.

### THE SCIENCE — a 12-second pre-check killed a 2×2 before it was pre-registered

`calibration/diag_gross_cancellation_geometry.R`, prereg `30320c1`. The SH land channels at SPO are
**152.9° apart** (NEP 1.3896 @ mo 10.15, respiration 0.0923 @ 5.05), so the net has a hard floor
`a_NEP · sin(27.1°)` = **0.454 × gross**:

> **THE MODEL CANNOT CANCEL MORE THAN 54.5 % OF ITS GROSS AT ANY RESPIRATION AMPLITUDE.
> CT2022 needs 74.9 %.**

Verified three ways — closed form 0.6320 vs 27n's 0.633; MEASURED minimum 0.6180 at 13.95 K
(−2.2 %, profile turning after, as 27n's P2 predicted); `a_NEP` linear in the gross to 0.04 % with
phase invariant to 0.000 mo. **At the CMIP6 gross A = 0.94 the floor is 1.1826 — ABOVE the observed
0.683** (registered prediction ~1.19). ⇒ **correcting the gross makes the cancellation IMPOSSIBLE;
a (gross, respiration) 2×2 is a guaranteed null.**

**What is missing is 11.9° = 0.40 months of separation, and it has a FITTED lever.** θ is
NON-MONOTONE in `seas_lag_p`, peaking at **176.1° at 2.75**, while `a_NEP` stays 1.37–1.43 — it
rotates without rescaling. The needed **164.8°** sits between lag **2.00** (its profiled optimum)
and **2.25** (its own `init`), against a mode that has drifted to **1.7677**.
**⇒ THE PAIR IS (GROSS ↑, LAG ↑). NOT RUN.** Price the lag first — it is GLOBAL.

⚠ **TRIED AND CORRECTED:** I pre-registered G5 as a MAGNITUDE gate ("does θ move?") for a
DIRECTIONAL question ("can θ move UP?"). Its two-point sample returned 122.7° and 145.8°, both below
the mode, and I read the sign backwards. **The profile refutes it — two points cannot see a hump.**
G5 is scored as written; §5b is an ADDED measurement, not a moved gate.

### THE DECISIONS (Marcus, 2026-08-29)

1. **A CMIP6 ensemble value for `SEAS_NPP_AMP_SH` is AUTHORISED — diagnostic arms only**, never
   shipped and never called an observational constraint. Shipped stays 0.5027, `status="data"`.
2. **A diagnostic arm may leave a bracket — for MEASUREMENT, not adoption.** Both are recorded in
   prereg 29c §0 and re-stated at the foot of every run.
3. **RATIFIED: do NOT adopt `refit_20260828_sigma_eff`.** `ccx_mode_file()` stays on `from90`; the
   adoption chain's `quarantine`/`repoint`/`rerun` stages are not to be run. Outputs committed as
   provenance. ⚠ **The pinned-96 successor is NOT launchable as a config change** — `ARM_HML_BOUND`
   is marked PROVENANCE ONLY since `2153bd6` and the driver's unbounded block is unconditional, so
   it needs a reviewed NEW constant; a BOUND (with prior renormalisation, the source of the −1.5805
   offset) is a different object from a PIN; and four Julia workers were saturating the machine.
   **QUEUED, NOT LAUNCHED.**
4. **`test-mode-file.R` — the suite is GREEN again.** (a) declared exemption for
   `diag_hml_seasonal_limbs.R`, a two-mode comparison `ccx_mode_file()` cannot express by
   construction; the per-FILE cost of that mechanism is documented and a sixth entry should force a
   per-LINE marker. (b) the `pin90`-vs-canonical trap **restated in GAP form**: the stored ordering
   (**+0.113**, against a measured objective drift of 0.081 — only 1.4× margin) is asserted as the
   TRAP, and the load-bearing assertion now recomputes BOTH arms on ONE objective, getting
   **−11.497** against the pin's +11.6698 `fert_k` prior credit — **1.5 % apart, so it asserts the
   MECHANISM**, and fails if the trap's cause changes rather than if two numbers cross.
5. **`diag_landed_gap_streams.R` QUARANTINED, not re-pointed.** Every arm it reads predates
   `2153bd6`; its GATE 1 reproduces STORED logposts so widening fails it by construction. The driver
   is kept in place, readable, and now HARD-STOPS with the reason; its output moved to
   `outputs/quarantine/20260829_preadoption_landed_gap/` with a README. **No replacement — the
   question must be re-asked post-adoption.**

## 2026-08-29b — **THE CONTROLLED `q10` TEST: THE RECOVERY FRACTION IS NOT A CHANNEL PROPERTY**

Step 1 of the 08-29 handoff's ordered list, and it CLOSES the confound the OPPOSITE way to the
prediction. `calibration/diag_q10_controlled_recovery.R` re-runs 27q's six arms with **ONE axis
moved** — `q10` FREE in every arm instead of pinned, lever and everything else held.

| | land lever | `q10` | land cost | INTERACTION | **recovered** | vacancy | per-ppm |
|---|---|---|---|---|---|---|---|
| 27j | `seas_npp_amp_SH` (INADMISSIBLE) | free | 80.44 | +67.28 | **83.6 %** | 0.383 | 175.8 |
| 27q | `seas_T_amp_SH` pinned | pinned | 80.42 / 162.14 | +34.47 / +70.89 | **42.9 / 43.7 %** | 0.305 / 0.449 | 113.0 / 157.9 |
| **08-29** | same lever | **FREE** | 29.75 / 43.60 | +6.24 / +7.41 | **21.0 / 17.0 %** | 0.081 / 0.092 | 77.3 / 80.8 |

⇒ **`q10` is NOT why 27j reached 83.6 % — freeing it moves the fraction the WRONG WAY.** The
contrast belongs to the **LEVER** (the shape of the vacancy), prereg 27q §4's alternative.

**WHY, and it is the more useful finding.** With `q10` free the LAND arm barely imposes the defect
at all — SH-land 1.308 → **1.216**, vacating **0.092 ppm** against 0.449 pinned — because
`seas_T_amp_NH` runs to **57.5 / 75.5 K = 321-421 % of its measured 17.92 K high end** while
`ln q10` falls 59-69 %, holding the identified product to 0.4 %. The three slices order themselves
by **how much escape they allow**, and recovery falls monotonically along that order.
**The fraction measures ESCAPE, not SUPPLY. Never quote one without its slice.**

The MECHANISM replicates a THIRD time (`ent` 4.78 / 4.87, `sst_seas_amp_SH` 0.29 → 0.65 in JOINT);
P1 falsified at both ends again. **SH land stays 1.308 = 1.92× obs, untouched.**

### TRIED AND CORRECTED IN THIS SESSION

- ⚠ **I wrote gates C1/C2 as ABSOLUTE logposts against numbers stored by 27j/27p/27q — which ran on
  08-27, before `2153bd6` ("ADOPT OPTION 5") changed the objective.** Same defect the 08-29 handoff
  flags in `test-mode-file.R`, reproduced in a driver whose header cites it. Amended the prereg to
  **gap form BEFORE any arm result**; C2-as-registered then failed on exactly the two arms whose
  whole gap was the shift (−0.082, −0.049). **The shift is an additive constant, MEASURED at four
  points spanning 60 log units: −0.082, −0.082, −0.080, −0.080.** Gap-form reproduction of three
  other drivers is then exact (+12.57, −29.75, −43.60).
- ⚠ **C7 was mis-scoped**: `grep("grad")` swept in the ATMOSPHERIC `co2_gradient`/`d13c_gradient`
  rows, which option 5 does not touch. Narrowed on the COMMIT (`R/likelihood.R:1541` names
  `ocean_grad_{dic,d13c,alk}`), not on the answer — spread **0.0169 ≤ 0.05, PASS**.
- ⚠ **BOTH registered predictions were wrong in magnitude**: I registered recovery "stable, 33-54 %"
  (measured 21.0 / 17.0) and a per-ppm band 110-200 (measured 77.3 / 80.8). The direction they
  existed to license survives a fortiori. Per-ppm was more stable only relatively — 2.2× against
  the fraction's 4.9×.
- **Nothing adopted, quarantined or repointed.** `ccx_mode_file()` still resolves `from90`.

**NEXT: step 2, the NH-IMPORT channel** — 0.821 of the model's 1.373 SH land is imported from the
NH, and this run measures NH_origin **INERT at 0.818-0.821 across all six arms**.

## 2026-08-29 — **THE REFIT LANDED AND CONVERGED. IT MUST NOT BE ADOPTED. Next: the SH land overshoot.**

Landed 06:39:50, 10.9 h, 274,722 evals at 0.142 s/eval. **Cycle 2 gained exactly 0.0000** and
`CONVERGED` fired: NM restarts and BFGS polish both gain zero from the cycle-1 mode. The cycle-1
`HIT THE RESTART CAP WHILE STILL GAINING` banner is a **false alarm** — it is threshold-triggered
(`ARM_TOL` 1e-4) on a gain of 0.0012, and the polish then gained **0.0317** against 08-20r's 16.08.

⚠ **THE PRODUCTION REFIT REPRODUCED THE 14-MINUTE CRIPPLED SMOKE TEST TO THREE DECIMALS** —
+4.060 total, jac −2.139, loglik −1.199 vs −1.201, `h_ml` 35.38 m in both. **That INVERTS handoff
08-28c §3**, which read the smoke's 35.38 m as an artefact of its budget. It did not wander. What
§3 got right is the part that matters: **the +4.06 is ENTIRELY PRIOR CREDIT and the fit got WORSE.**

### `h_ml` = 35.38 m is an ARTEFACT — measured twice, and BOTH tests corrected something of mine

**`diag_hml_seasonal_limbs.R` — the repair hypothesis, REFUTED.** SH ocean limb 48% → **49%** of
observed on a defect needing a doubling, while the **phase rotated AWAY** from obs (4.17 → 3.90
against 8.52). This arc's own lesson again: limbs are **VECTORS**, and a magnitude moving the wanted
way can still be a phase error that makes the sum worse. SH land **1.92× → 1.93×**: untouched.

**`diag_hml_sst_elasticity.R` — MY explanation, REFUTED, and the physics INVERTED.** I inferred the
shallow layer DAMPED the transfer from `sst_seas_amp_SH`, letting the fit buy prior credit by
neutering the parameter. Its pre-registered P2 — stated as the live outcome, not a formality —
**fired**: elasticities **1.0002 (35 m) vs 0.9999 (96 m)**, identical and exactly linear. Withdrawn.

⚠ **AND THE PHYSICS I ASSERTED WAS BACKWARDS.** At FIXED `sst_seas_amp_SH` = 0.4312, `h_ml`
96.47 → 35.38 m takes the limb **0.3066 → 0.2577 (59% → 49% of obs)** and its phase 4.15 → 3.90.
**A shallower mixed layer makes this limb SMALLER, not larger.** Retracted in place, at the site,
with the measurement. So `h_ml` → 35 m *degrades* the limb that is already ~2× too small, and the
20% rise in `sst_seas_amp_SH` is **compensation for that damage**, not a gain.

⚠ **ALSO RETRACTED: "revisit the `sst_seas_amp_*` priors".** `ccx_prior_z()` is the post-fix
implementation (unconstrained coordinate, Jacobian, prior's own mode by scan, both tails with the
smaller used) so **−6.32 is real**. And `INDEX_ccx_seas.md` is explicit that the priors are the part
ANCHORED ON OBSERVATIONS — `sst_seas_amp_SH` sits at 21% of observed *because* SH land is 1.9× too
big. **The prior is not wrong; the partition is.** I reasoned from the z magnitude without reading
the seasonal sub-index first.

### The decision, and what was deliberately NOT done

**Not adopted.** It is the legitimate posterior mode of the adopted objective, but *posterior mode*
and *better model* have come apart. **Nothing is quarantined and nothing is repointed** —
`ccx_mode_file()` still resolves `from90`, and `run_post_refit_adoption.R`'s `quarantine` /
`repoint` / `rerun` stages have never been run; only `check` (5/5) and `read`.

⚠ **This reads as a problem with OPTION 5 rather than with the refit.** Freeing `h_ml` let the
seasonal prior conflict pay itself out through ocean structure, because the CO2 seasonal rows have
**no power to object** — already matched by cancellation. A candidate that keeps the σ-inflation
while denying the anti-physical lever is a refit with `h_ml` PINNED at ~96; not run, not decided.

### ⇒ NEXT: THE SH LAND OVERSHOOT (Marcus, 08-29)

Two independent arcs now point at it. The seasonal arc reached it from the partition side; this
refit reached it from the ocean side, by exhausting every ocean-side lever — `ent` vetoed, `tau_ex`
exonerated, `(phi_eff, amp)` degenerate, and now `h_ml` running the wrong way. Order: (1) the
**controlled `q10` test** (the 82%-vs-42% recovery contrast is confounded by q10 free vs pinned;
cheap, still not run); (2) the **NH-import channel** — 0.821 of the model's 1.373 SH land is
imported from the NH, more than the entire observed SPO land component, and nothing has been aimed
at it; (3) the NH box's own seasonal amplitude, still unchecked; (4) then 4b.

## 2026-08-28i — **`pin90` retirement adopted; the band mirrors swept — and TWO of the four must NOT be widened**

**Marcus: retire `pin90`, and remove anything that reads retired code.** Done, with two
qualifications that came out of reading the files rather than the filenames.

**⚠ I OVER-COUNTED THE COST OF RETIRING `pin90` AND WITHDRAW IT.** I reported "six diagnostics
name it". **Two** call `ccx_mode_file("pin90")`. The others were filename matches, not call sites —
exactly what [[audit_live_paths]] warns about: `diag_stream_neff.R` and `seed_fert_ridge_arms.R`
mean **`ridge_pin90`, a DIFFERENT arm** (`output/ridge_pin90/`), and `diag_design_gates_at_mode.R`
names it only in comments and `cat` text. `--retire-pin90` is now the DEFAULT.

**And the one real cost is smaller than it looked.** `diag_landed_gap_streams.R` computes the
`+11.6698` pinned-prior offset, which is cited in comments and stored nowhere. But its line 162
reads `intersect(c("ref", "from90"), names(A))` and **`ref` is already unresolvable** — after the
refit `from90` goes too. Every arm it compares is retired by the objective change, so `pin90` is
not what keeps it alive. If that offset matters, **store it**; do not keep an arm resolvable for it.

### ⚠ THE BAND CONSTANT STAYS. Deleting it would delete the proof that the adoption worked.

`test-sigma-inflation.R:74` — "THE CLIFF IS GONE: no jump across either retired band edge" —
iterates over `c(85, 120)`, and line 23 asserts the constant still equals it **so a rename is
caught**. To test that a cliff at 85 and 120 is gone you must retain where 85 and 120 were.
The distinction that matters is not whether a file NAMES the retired band but whether it uses it to
**CONFIGURE a live run**. Provenance reads are the thing to keep.

### The four mirrors, swept BY WHAT THEY DO WITH IT — two widened, two not

- **`diag_hess_eps_21par.R` — WIDENED.** Bound and init now read from the shipped table, not typed.
  Its gate is **INVERTED** (table must be UNTOUCHED), as the refit driver's H1/H2 were: deleting the
  override without inverting the gate leaves a check that passes because it *cannot fail*, which
  reads identically to one that looked and found nothing ([[no_power_null]]).
  ⚠ Its per-direction `h_ml` step is **not comparable** with any pre-08-28 run — the logit is over a
  4.857× wider support — and the kink scan now sweeps the whole support.
- **`diag_stream_neff.R` — WIDENED**, on its own evidence: the override existed only for the prior,
  and the comment that stood there said this file does not use it.
- **`diag_ridge_reparam.R` — WIDENED, AND ITS LADDER SHIFTED.** `RR_THRESH` is a set of **absolute
  logpost levels** written under `h_ml ~ U[85, 120]`. On the shipped support the same vector scores
  lower by **exactly log(170/35) = 1.5805** — pure prior renormalisation, nothing physical, and the
  same −1.5805 the 08-28 handoff calls "the bounded refit's narrowed-prior constant, exactly"
  (verified numerically, not recalled). Left as typed it would have compared post-adoption logposts
  against pre-adoption thresholds and **shifted every verdict one rung, silently**. The shift is
  now COMPUTED from the two priors, so it cannot go stale.
- **`diag_landed_gap_streams.R` — DELIBERATELY **NOT** WIDENED.** Its GATE 1 reproduces each arm's
  **STORED** logpost, and every arm it reads was FITTED under `[85, 120]`. Here the band is not a
  scoring choice, it is those vectors' **provenance**; widening would fail GATE 1 by 1.5805 **by
  construction** — which its own pre-existing comment ("Without it GATE 1 fails by ~1.1") already
  half-said. It is a PRE-ADOPTION driver and cannot be made current by editing a constant. It now
  prints that at runtime, not just in a comment. **Re-point or quarantine is a decision, owed.**

### Also

- **`diag_design_gates_unscored.R:91`** asked `file.exists(ccx_mode_file("pin90"))` — but
  `ccx_mode_file()` **throws on a retired name before `file.exists()` ever runs**, turning an
  intended graceful absence into a hard stop. Now asks the registry first. Verified both ways:
  old guard ERRORS, new guard returns FALSE.
- **Same file named its canonical element `from90` by hand** while resolving the VALUE through
  `CCX_MODE_CANONICAL` — so every table it printed would have gone on calling the new vector by the
  old arm's name after the repoint. The label now derives from the constant.
- **The driver's mirror-staleness check ignores COMMENT lines** and carries two DECLARED exemptions
  (same construction as `test-mode-file.R`'s `allowed`). A check that cannot tell a provenance
  mention from a live read would report all four forever and stop being read.

**NOT DONE, and not runnable yet:** none of the four edited diagnostics was EXECUTED. Two need the
new mode, one is expensive, and all would contend with the running refit for CPU. They are
parse-checked, and the constants they now derive were verified numerically; their OUTPUTS on disk
remain pre-adoption and are owed a re-run.

## 2026-08-28h — **THE OWED REFIT IS LAUNCHED; the post-refit chain is written and tested ahead of it**

**The 21-parameter refit onto the post-option-5 objective is RUNNING** —
`calibration/output/refit_20260828_sigma_eff/`, launched 19:44, ~18 h, production budget,
`h_ml` UNBOUNDED, BLAS pinned to one thread, run from a FROZEN copy of the driver so the tracked
one stays editable ([[never_edit_a_running_script]]). Warm-started from a byte copy of the
incumbent canonical mode: `par_mode` is band-INDEPENDENT and is re-encoded under this run's table,
so warm-starting ACROSS the objective change is safe where reusing `u_mode` would not be.
Gates H1/H2/H3 pass in the log, and the warm start reads −1544.6 against a file that says −1544.6
— a MATCHED read, which is the only honest form of that comparison.

**The launch was gated on the machine, not on the calendar.** The 08-28c handoff left it open
because a Julia SLR job was running on this Mac; that job had finished, checked before launching
rather than assumed ([[eta_in_days_is_not_a_slow_run]]).

**The seeded mode rds is deliberately NOT committed.** It is the incumbent's bytes today and the
driver overwrites it in place, so committing it now would record a result that does not exist.

### `calibration/run_post_refit_adoption.R` — §4.2–4.5 as ONE command, written while waiting

Five stages in the only safe order: `check` (refuse to start on an unfinished refit), `read`,
`quarantine`, `repoint`, `rerun`. Written now, deliberately: the work is identical either way, and
prepared against a handoff still in context it is reviewable, where reconstructed at the end of an
18 h wait it is four chances to skip a step.

- **`check` does not trust the mode file's EXISTENCE.** The directory was SEEDED with a copy of
  the incumbent, so the file has been there since 19:43 and proves nothing; what discriminates is
  its mtime against the incumbent's, plus the log ending in the comparison write, plus
  `hml_bound` recording the SHIPPED support rather than the retired band — if the refit had written
  `[85, 120]` there, every downstream `ccx_mode_params()` decode would silently be wrong.
- **`read` exists so an `h_ml` move cannot be reported without its decomposition.** It re-evaluates
  BOTH vectors under the CURRENT objective — the stored logposts belong to two different objectives
  and cannot be subtracted — and splits Δlogpost into prior / jacobian / loglik, naming the
  per-parameter movers. It prints a warning, by construction, when the total rises while the
  likelihood falls: that is the smoke test's exact signature (+4.060 total, −1.201 loglik, the whole
  gain prior credit on `sst_seas_amp_SH`/`_NH`) and it must not be read as a better fit.
- **`repoint`'s three `R/paths.R` edits are exactly-one-match or they refuse.** MUTATION-TESTED
  against a copy: the guard correctly refuses at 0 matches and at 2, and the rewrite parses, sources,
  and satisfies all three structural invariants `test-mode-file.R` asserts ([[mutation_test_gates]]).
- **`rerun` runs the Hessian pair and the three design gates, and REFUSES to run the four mirror
  diagnostics.** They still read the retired band; re-running them as they stand would file
  pre-adoption numbers beside post-adoption ones, which is worse than not running them because the
  output would look current. It reports which still carry it.
- **`recompute_hessian.R` is called WITHOUT `--update`** — it writes its own `_hess.rds` and does
  not mutate the fresh mode file. Overwriting a mode's second-order block is a decision to take
  after reading its gates, not a side effect.

### `CCX_MODE_RETIRED` now carries a reason PER ARM (`R/paths.R`, `test-mode-file.R`)

**Done first, because without it the repoint could not state its own cause.** The retirement reason
lived in `ccx_mode_file()`'s error as ONE hardcoded sentence — the 2026-08-25f isotope fix
(`6bda464`), quarantined under `20260825_seas_isotope_rectification/`. That was correct while a
single objective change had retired every arm. Option 5 (`2153bd6`) is a SECOND one, so the shared
sentence would have told a reader the wrong cause and pointed at the wrong directory. Entries now
carry their own cause commit and quarantine path; the error composes from them.

`test-mode-file.R`'s retired-arm test was checking every arm for the literal `"6bda464"`. That
assertion generalises rather than relaxes: each entry must name a quarantine path AND a cause
commit, whatever they are for that arm. A shared literal would have forced the next retirement to
either state the wrong cause or edit the test — and "edit the test" is how a reason quietly stops
being carried at all.

**Left deliberately undone, and flagged in the driver rather than guessed:**
- **`pin90` is as pre-adoption as `from90`, and the driver will not choose for you.** `repoint`
  STOPS without `--retire-pin90` or `--keep-pin90`. Retiring is the correct semantics and breaks six
  diagnostics LOUDLY (which is what the mode registry's own header argues for); keeping leaves a
  vector fitted on a retired objective resolvable by name, which is the silent failure it exists to
  prevent. A methodological choice, so it is not defaulted.
- **`test-mode-file.R`'s `expect_gt(lp[["pin90"]], lp[[CCX_MODE_CANONICAL]])`.** Across the
  objective change that comparison is MEANINGLESS, not merely false. Its premise needs rewriting,
  not relaxing to green.

## 2026-08-28g — **OPTION 5 ADOPTED: the ocean-gradient rows are scored at every `h_ml`**

**Marcus 2026-08-28: "Adopt option 5."** The `[85, 120]` skip is RETIRED. Suite **1164 -> 1203, 0 fail**.
`data-raw/build_glodap_sigma_rep.R` -> `data/obs_glodap_sigma_rep.rds`; `R/likelihood.R`;
`calibration/run_modefind_pump_arms.R` unbounded; 13 diagnostics swept.
⚠ **A full 21-parameter refit is OWED and NOT YET RUN** — every pre-adoption fitted vector is
non-comparable, and nothing is quarantined yet because quarantining before a replacement exists
would break `ccx_mode_file()`, the app and every diagnostic.

`sigma_eff(h)^2 = sigma_obs^2 + (target - like-for-like(h))^2`, normalisation retained, sigma_rep
**measured** off GLODAP by the shipped target's own recipe (G1 reproduces all three targets to
**0.00e+00**), on a 1 m grid across `h_ml`'s whole support. `ccx_loglik()` **errors** if a
hand-built `ocean_grad` omits `sd_eff`: a silent fallback to sigma_obs is the retired objective
wearing the new one's clothes.

**NO SMOOTHING, and a moving average was TRIED AND REJECTED on measurement** — at every width it
deviated from the raw curve by more than the jumps it removed (0.131 vs 0.090 at w = 11 m), because
the V-bottom at the crossing is narrower than the smoother. Measured roughness: median 0.0055, max
0.0734 log-units.

⚠ **I OVERCLAIMED AND CORRECTED IT IN PLACE.** An earlier draft of the builder and likelihood
comments said shipping `|sigma_rep|` instead of the signed like-for-like would "plant a KINK in the
posterior's softest direction". **Measured: the two constructions differ by 0.0002 sigma_obs with
second differences equal to six decimals** — sigma_eff squares the difference, so folding is nearly
a no-op. Withdrawn in both files and gated by a test. The signed form still ships, for faithfulness
to the measured quantity, **not** as a smoothness fix.

⚠ **`h_ml` IS NOT NOW SMOOTH, AND THE EARLIER FRAMING NEEDS THIS QUALIFIER.** Widening the refit's
kink scan from the retired band to the full support finds **26 kinks in [30, 200]** (46.85, 47.68,
49.51, 50.00, 73.05, ... 199.86), many on round numbers. Option 5 removes the band CLIFF (+7.30 /
+8.43), which was by far the largest defect in the softest direction; the `1/eps` pump kinks are a
SEPARATE, pre-existing problem ([[ccx_hml_kink]] had 3 inside the band alone) that this does not
touch. `diag_hess_eps_21par.R` is owed a re-run.

**THE SMOKE TEST, AND WHY ITS ALARMING RESULT IS NOT A FINDING.** A deliberately crippled run
(1 restart, 1 cycle, maxit 60; 14.2 min) warm-started at 96.47 m and reported `h_ml` **35.38 m**,
"gaining" 4.1 log-units — apparently contradicting Stage B's interior maximum. Diagnosed rather
than rationalised, and it is neither a bug nor a refutation:

    DELTA (smoke - old):  logpost +4.060 = prior +7.399  jac -2.139  loglik -1.201

**The entire gain is PRIOR credit on the seasonal amplitudes** — `sst_seas_amp_SH` **+4.145**,
`sst_seas_amp_NH` +1.632, `rep_dC` +1.088 — **bought by making the FIT WORSE.** Those are the known
prior-data conflict ([[seas_amps_hemispheric_inversion]], `sst_seas_amp_SH` at z ~ -6.3). Stage B
held all 16 of those parameters FIXED, so they could not move; the smoke let them go where their
priors want and dragged `h_ml` down the softest direction as a side effect. **Verified first that
the rows ARE scored at 35.38 m** (sum -7.876, sd_eff/sd_obs 1.322 / 1.483 / 1.055) — the
implementation is correct. ⇒ **The real refit needs its full restart/cycle budget**, and the
seasonal-amplitude prior conflict is now the dominant gradient in it.

**One output line was genuinely WRONG and is fixed:** the arms' report still printed
"gradient rows LIVE only inside [85, 120]: *** ABSENT ***" at the landed `h_ml`. The rows are always
scored now; it reports `sd_eff/sd_obs` instead.

## 2026-08-28f — **STAGE B: σ-INFLATION ERASES THE FREE LUNCH; THE PULL IS 0.033**

Prereg amendment `672dd8b` BEFORE the driver. `calibration/diag_sigma_inflation_profile.R`;
collect `notes/collect_2026-08-28b_sigma_inflation_pricing.md`. 26 points, all converged.
**`R/` and `src/` untouched; the band and the skip are exactly as shipped.**
**B1 ✗ (pre-registered as expected to fail) B2 ✓ B3 ✓ B4 ✓.**

**The shipped skip's pull was +7.39 log-units. With the rows scored at σ_eff everywhere it is
+0.033 — a 99.55 % reduction.** 08-28 §6's inferred ~1.6 ("80 %, NOT elimination") **is refuted by
measurement.** Best in-band −1544.357 at 85.01 m; best out −1544.324 at **82 m** — so the argmax
does sit 3 m outside the lower edge (B1 ✗, as pre-registered), but **by 0.033, which is 21× below
the refit's own 0.70 restart noise floor.** That is not a preference the fit can act on.

**Both cliffs are gone and leaving the band is now slightly downhill** (B4): 85 m
**+7.3005 → −0.0064**, 120 m **+8.4257 → −0.0047**. ⚠ Stage A's LOWER had suggested the 120 edge
would stay at −6.74; at 120.01 the five free parameters recover nearly the whole 8.4 of bracket
width. **The bound was rigorous; the inference drawn from it was not.**

**The substantive case for option 5:** the inflated objective has an **interior maximum** over the
full [30, 200] support — a 1.64-log-unit plateau across 65–120 m, falling to **−5.56 at 32 m** and
**−13.03 at 198 m**. `h_ml` no longer needs a hard bound to stay put; the data holds it.

**B3 ✓ 26/26** — every refit landed inside Stage A's bracket, and the Stage B guard reproduced
Stage A's `LOWER` at the mode by a completely different route at **0.000e+00**.

**Two side-findings.** ⚠ **`kz` still rails and still inverts** (97.9 % of bracket at 32 m → 92.4 %
at 96.47 → 66.1 % at 198), **unchanged** — inflation does not touch it, and this arc has now twice
failed to be its cause. **`pump_grad` narrows 226–446 → 253–302**: with the rows on everywhere, the
quantity they exist to constrain stops wandering. That is the positive half of §5's **H4 ✗** and
the first direct evidence those three rows do the identifying.

**NOT ADOPTED.** Option 5 remains Marcus's call and a likelihood redesign: the conditional argmax
moves 96.47 → 82 m, and adoption owes a full 21-parameter refit even though the move is inside the
noise. Correcting the **target** to its like-for-like value is a different, more aggressive remedy,
measurable from the same curves — **not priced, not proposed.**

## 2026-08-28e — **σ-INFLATION, PRICED: THE ~1.6 RESIDUAL WAS A RATIO ON THE WRONG BASE**

Pre-registered `notes/prereg_2026-08-28b_sigma_inflation_pricing.md` (`15d1906`) BEFORE the
driver, amended (`672dd8b`) for Stage B before *its* driver. `calibration/diag_sigma_inflation_pricing.R`.
**`R/` and `src/` untouched; `LIK_OCEAN_GRAD_HML_OK` and the skip are exactly as shipped, and no
refit is owed.** **G1 ✗ G2 ✓ G3 ✗ G4 ✓.**

08-28 §6 proposed re-running the out-of-band profile points with inflation ON. **Both sides turned
out to be boundable exactly from artifacts already on disk**, so Stage A bracketed first:

    LOWER(h) = lp_shipped(h) − rows_shipped(h) + rows_inflated_at_the_STORED_vector(h)
    UPPER(h) = lp_shipped(h) − rows_shipped(h) + Σ −log(√(2π) σ_eff(h))

Both rigorous, in opposite directions: re-optimising with the rows ON can only *raise* the
objective above its value at the stored vector, and can never raise a row above its own density
peak. σ_eff² = σ_obs² + σ_rep(h)², with σ_rep PCHIP-interpolated through the **measured** points
(`hml_band_discontinuity.rds` for DIC/δ¹³C, `alk_sigma_rep.rds` for ALK) — never a parametric fit.

**⚠ 08-28 §6's "inflation leaves ≈1.53, an 80 % reduction not an elimination" IS WITHDRAWN AS
REASONING.** 16g measured **2.14 of 10.01** — a *difference* (in-band row cost − out-of-band
inflated row cost) expressed as a fraction of **its own** in-band cost. §6 multiplied that 21 % by
§5's base of **7.30**, which is not 16g's. **The relief is a difference whose subtrahend is set by
the σ's, not a fixed fraction of the base.** Measured: **+0.541**, not 1.6.
[[ratio_needs_its_base]] — the project's own promoted convention, walked into from the inside.
The 21 % itself is *not* wrong; it is a correct measurement of 16g's frozen-19 configuration, and
of DIC + δ¹³C only, ALK's σ_rep not existing until 08-18.

**G2 ✓ (+0.541 ≤ 0.70), G4 ✓ (inflation costs the mode −0.085).**

**G1 ✗ — the bracket does not separate on the SHALLOW side**: `max UPPER(out) −1543.817` at 82 m
against `max LOWER(in) −1544.358` at 85.01 m, an overlap of 0.541 against widths of 0.50–0.65.
⇒ **Stage B owed and launched** (`diag_sigma_inflation_profile.R`), which refits all 26 points
with the rows ON via an exact algebraic identity — `dnorm(t,v,σ_eff) = dnorm(t,v′,σ_obs) −
log(σ_eff/σ_obs)` with `v′ = t − (t−v)σ_obs/σ_eff` — so the **shipped** `ccx_loglik` path does the
scoring and no incumbent/challenger mismatch can creep in [[match_incumbents_optim]]. Its guard,
that the override reproduce Stage A's `LOWER` at the mode by a completely different route,
**passed at 0.000e+00**.

**On the DEEP side the bracket IS decisive, and in the direction nobody predicted.** Every
`h > 120` sits ≥ 6.7 log-units BELOW the in-band maximum, because the model's gradient misfits
badly there once it is actually scored: `rows_infl` runs **−15.2 at 120.01 to −46.5 at 198**,
against a ceiling of −6.8.

**⚠ G3 ✗, AND THE FAILURE IS THE BAR'S, NOT THE REMEDY'S — carried as evidence, not as a label**
[[explained_away_test]]. I gated on `|jump|` at the band edges. The 85 straddle collapses
**+7.300 → −0.131**, as predicted. The 120 straddle stays large but **REVERSES SIGN**: **+8.426 →
−6.743**. A step *down* on leaving the band is the remedy working — the incentive now points
inward — so magnitude was the wrong quantity to gate. Stage B's **B4** replaces it with the
**signed** jump.

**Not priced, not proposed, recorded so it is visible rather than defaulted:** correcting the
**target** to its like-for-like value at `h_ml` is a different and strictly more aggressive remedy,
measurable from the same stored `like_for_like` columns. Marcus's call. [[threshold_from_obs_or_law]]

## 2026-08-28d — **THE 236-LOG-UNIT `h_ml` PULL DOES NOT EXIST; THE CLIFF IS THE WHOLE STORY**

Pre-registered `notes/prereg_2026-08-28_hml_unbound_profile.md` (`805e8c4`) BEFORE the driver.
Collect: `notes/collect_2026-08-28_hml_unbound_profile.md`. 26 points, all converged.
**`R/` and `src/` untouched; no objective changed, no refit owed.** **H1 ✓ H2 ✗ H3 ✗ H4 ✗.**

Marcus asked for the profile while leaning toward option 5 (σ-inflation). It was run over the
**SHIPPED** [30, 200] with `beta_max`, `fert_k`, `k_w`, `kz`, `pump_grad` re-optimised at every
point — the configuration never previously run.

**08-16g's "argmax 32 m, pull 236 log-units against a 10.0 cliff, 24×" DOES NOT REPRODUCE.** That
was measured with **19 parameters frozen**. With the uptake set free: **argmax 75 m**, pull beyond
the cliff **0.09**, and **32 m is 4.57 log-units WORSE than 75 m**. The refit had *suggested* the
236 was an artefact; it is now **measured**. 5 free is conservative and one-way — freeing more can
only reduce the pull — so this generalises to the full 20.

**THE SHAPE IS THE RESULT.** In-band the objective is **flat**: +0.00 (96.47 m) → +0.35 (85.01 m)
across 11.5 m, consistent with `h_ml`'s ~11 m 1σ, with the in-band optimum at the *shallow* end.
The cliff is **−7.300 at 85** and **+8.426 at 120**. Beyond it the profile is flat then **declines**.

**THE CLIFF *IS* THE THREE ROWS, TO 0.3 %.** Just inside the lower edge they sum to **−7.275**
against a measured cliff of **−7.300**. Outside, they are **absent — not zero** — from
`ccx_loglik`'s output. ⇒ **The bound IS load-bearing (H2 ✗), but 7.30 of the 7.39 advantage at the
argmax is three skipped Gaussians.** The objective does not prefer a shallower mixed layer; it
prefers **being scored on less data**. That is defect (B), isolated and quantified. At the upper
edge ~1.0 log-unit is re-optimisation freedom on top (`pump_grad` 273.4 → 324.0).

**H3 ✗ AND IT INVERTS.** `kz` does not come off its rail below the band — it is pushed **harder**
onto it (92.4 % → **98.2 %** at 32 m), releasing only going *deeper* (**57.7 %** at 198 m). The
bound is not propping `kz` up; a shallower mixed layer drives `kz` into its ceiling. My hypothesis
had the sign backwards.

**H4 ✗.** `pump_grad` stays **226–446** with the rows off, never near 963.6 / 1431.0. ⚠ Not a
refutation of those — they came from truncated arms with far more freedom — but the effect **needs
more than the uptake set to appear**.

**FOR THE OPTION CHOICE, INCLUDING THE PART THAT DOES NOT FAVOUR OPTION 5.** This says exactly what
σ-inflation must do: charge for the −7.275 the skip gives away free. ⚠ **But at 08-16g's measured
21 % residual, inflation would leave ≈1.53 — the pull falls from 7.39 to ~1.6, an 80 % reduction,
NOT elimination, and the argmax would still sit just outside the band.** And that 21 % is
**observation-side only**. **The profile now makes the proper measurement cheap: re-run these
out-of-band points with inflation ON and read the argmax, instead of scaling a number from another
configuration.**

**TWO PROCESS DEFECTS, BOTH MINE.** A reporting bug destroyed 45 minutes of fits because `saveRDS`
came *after* the pretty-printing — the artifact is now written first. And I walked into a trap this
project has already documented: `ccx_loglik(by_stream = TRUE)` returns a **named numeric VECTOR**,
so `s[["absent"]]` **errors** rather than returning NULL. Test **membership**, never nullity.

## 2026-08-28c — **THE `h_ml` SWEEP: 10 DRIVERS PATCHED, EVERY ARC RE-RUN, AND NO VERDICT MOVED**

Follow-up to `2f60dd9` / `abc9704`. Pre-fix outputs in
`outputs/quarantine/20260828_hml_band_decode/` (with a README); canonical replacements regenerated
to `outputs/diagnostics/`.

**THE RE-RUNS, and the headline is that the arc survives its own worst bug.**

| arc | pre-fix | band-corrected | verdict |
|---|---|---|---|
| **27g** `sst_seas_amp_SH` | 0.360 → 0.736, z −3.43 | 0.360 → 0.736, **z −3.45** | P2 PARTIAL, unchanged |
| **27h** SH-local invariance | +1.7 %, NH-origin −73.4 % | **identical** | unchanged |
| **27i** GPP-end SH-land | 0.892 ppm, cost −79.01 | 0.892 ppm, cost **−80.27** | unchanged |
| **27j** INTERACTION | **+64.99** (gate 39.59) | **+67.28** (gate 40.22) | **P1 CONFIRMED** |
| 27j recovery | 82.1 % | **83.6 %** | — |
| **27n** P8 | 1.79× obs, 15.3 % closed | **1.78×, 14.7 %** | unchanged |
| **27p** vacated / closed | 0.4489 ppm, 71.8 % | **0.4491 ppm, 71.9 %** | S0–S5 all PASS |
| **27q** INTERACTION mid/hi | +32.81 / +67.76 | **+34.47 / +70.89** | **P1 FALSIFIED at both** |
| 27q recovery | 40.9 / 41.9 % | **42.9 / 43.7 %** | still ~half of 27j |
| 27q P2–P8 | ✓✓✓✓✓ / ✗✗ ✗✗ | **identical** | — |
| **gates 6/8/10/11** | PASS/FAIL/FAIL/FLAGS | **identical** (gate 8 by 0.004 ‰, gate 10 by 0.3 ‰) | — |

**WHY SO LITTLE MOVED, and it is not luck.** The mixed-layer depth sets the ocean's carbon
**CAPACITY**; the SPO seasonal **AMPLITUDE** is driven by `sst_seas_amp_SH` and the entrainment
channel. 27j's four P0 controls moved by **≤0.001** across an 11 % change in `h_ml`. The seasonal
arc was reading a quantity the defect barely touches.

**ONE THING CHANGED IN KIND RATHER THAN DEGREE.** 27q's P0 previously reproduced 27j's four
control values to three decimals *because both sessions shared the defect*. Both are now measured
at the correct 96.47 m and still agree — **the cross-session reproducibility claim is finally
earned rather than coincidental.**

**A SECOND LATENT BUG, EXPOSED BY FIXING THE FIRST.** `diag_seas_T_amp_sh_power.R`'s per-stream
table used `sprintf(" %>10s")`, an invalid format that ABORTS. It had never executed because the
original run took the try-error branch — the streams bug 27o §7 records. **Two defects in one
block, the second hidden behind the first.**

**AND A THIRD, of the same family, in my own 27p driver.** `QP_S1_FREE` was a hardcoded 1.2256 —
27n's pre-fix value — printed beside a vacated-ppm figure that WAS computed from the rds. Re-running
27n moved one and not the other. It now reads the value from the file. A displayed constant that
states a measured quantity has to be measured.

**AUDIT RESULT.** 10 drivers patched; 4 already applied the band by hand
(`run_modefind_pump_arms`, `recompute_hessian`, `diag_hess_eps_21par`,
`diag_seas_T_amp_q10_ridge`); 7 already used `md$par_mode` (`diag_design_gates_at_mode`,
`diag_fit_at_mode`, `diag_joos_irf`, `diag_gates_at_landed_modes`, `diag_stream_neff`,
`diag_landed_gap_streams`, **`app/global.R`**) — so the shipped app was never affected; 2 dead
(`profile_kz_ventilation`, `profile_bomb_total` read a `mode_fit.rds` that does not exist).

⚠ **`diag_landed_gap_streams.R:36-37` HAD ALREADY DOCUMENTED THE DEFECT** — "`u_mode` DOES NOT
DECODE under the default [30, 200] band … `par_mode` is the authority" — and it never propagated
to the other drivers or to memory. Same shape as the net/gross trap: **a trap documented once is
not thereby fixed everywhere.**

## 2026-08-28b — **THE MODE'S `h_ml` WAS BEING DECODED UNDER THE WRONG BAND, AND THAT IS THE −3.3223 OFFSET**

Suite **1164 / 0** (1157 + 7 new). New: `ccx_mode_params()` and `ccx_check_mode_decode()` in
`R/paths.R`, `tests/testthat/test-mode-decode.R`, `calibration/diag_hml_mode_decode.R`.
**No objective changed and no refit is owed** — the calibration was fine; what was wrong is what
the DIAGNOSTICS fed the model afterwards.

**THE DEFECT.** `h_ml` is logit-transformed onto `[lo, hi]`, and the pump refits **override that
band in process** (`run_modefind_pump_arms.R`, `recompute_hessian.R:112-113`). The band is a
property of the refit, so `R/calibrate.R` is deliberately untouched — but the same `u_mode` then
decodes to a different depth depending on which band is in force, and `ccx_unc_to_par()` is a pure
function of the SHIPPED table and cannot know:

| | `h_ml` |
|---|---|
| `ccx_unc_to_par(md$u_mode)` (shipped `[30, 200]`) | **85.7292 m** |
| `md$par_mode[["h_ml"]]` — what the refit found | **96.4737 m** |

**An 11.14 % error, and `h_ml` is the ONLY one of the 21 parameters that moves.** Every diagnostic
using the standard `pv <- ccx_unc_to_par(md$u_mode)` idiom has been running an **11 % shallower
mixed layer than the mode it names**.

**IT ACCOUNTS FOR THE STANDING OFFSET, EXACTLY.** Decoding under the recorded band moves the
"mode logpost is not reproducible" gap from **−3.3223 to −1.5805**, and −1.5805 **is** the bounded
refit's narrowed-prior constant — additive, deliberate, and cancelling from every contrast.
`|residual − prior constant| = 0.0000`. ⇒ **`ccx_mode_logpost_offset` is CLOSED.** Its own note
had listed "the h_ml refit bound" among the things ruled out; that ruling-out was wrong.

**WHAT IT DOES NOT CHANGE — the refit's own guards were RIGHT.** At the true 96.47 m the nearest
pump kink is **1.94 m** away and the Hessian's reach is **0.366 m**, so `hml_kink_hit = FALSE` was
correct and **the Hessian is not kink-contaminated**. ⚠ **This retracts what I said on 08-27 about
the softest direction being non-differentiable.** It is soft (1σ ≈ **11.00 m**, interval
[88.67, 108.46]) but its Hessian row is clean.

**THE REAL `h_ml` PROBLEM, RESTATED CORRECTLY.** Under the recorded band the logit maps [85, 120]
onto the whole line, so **`h_ml` < 85 is UNREACHABLE**: the mode-find is protected **by
construction, not by the data**. A sampler is not — the edge sits about **1.5σ** below the mode, a
routine excursion, and the shipped model allows [30, 200] where the *unbounded* objective's argmax
was measured at **32 m**. **Any posterior drawn in these coordinates is conditioned on a bound
adopted as a refit expedient, not as a belief.** That is the live question, and it is the one
Marcus flagged and did not resolve on 08-16g: **hard bound (option 1) vs measured σ-inflation
(option 5)**. Still his call; nothing here preempts it.

⚠ **MATCHED CONTRASTS SURVIVE; ABSOLUTE VALUES AND CROSS-SESSION CONTROLS DO NOT.** Every arm of a
given driver shared the same wrong `h_ml`, so 27i–27q's differences and interactions stand. What
does **not** stand is any absolute decomposition value, and in particular 27q's "P0 reproduced all
four of 27j's control values to three decimals" — those agreed because all three sessions shared
the defect, not because the values were right. [[mutation_test_gates]]

**THE GUARD.** `ccx_check_mode_decode()` **errors** (not warns) when a mode file fails to decode to
its own stored `par_mode`, and the test asserts the affected set is *exactly* `h_ml` — so a second
parameter acquiring an in-process band override fails loudly instead of silently.

## 2026-08-27q — **THE MECHANISM REPLICATES IN FULL. THE ARITHMETIC DOES NOT.**

Pre-registered `notes/prereg_2026-08-27q_admissible_2x2_land_ocean.md`, committed **`36e4051`
BEFORE** `calibration/diag_admissible_2x2_land_ocean.R` existed. **No gate moved.** Collect:
`notes/collect_2026-08-27q_the_mechanism_replicates_the_arithmetic_does_not.md`. **`R/` and `src/`
untouched.** Six arms, all converged (1 restart, last gain 0.0000), 70–207 s each.

**P0 ✓ · P1 ✗✗ · P2 ✓✓ P3 ✓✓ P6 ✓✓ P7 ✓✓ P8 ✓✓ · P4 ✗✗ P5 ✗✗**

**P0 reproduced ALL FOUR of 27j's control values to three decimals** (total 1.141, SH-land 1.308,
NH-origin 0.821, ratio 1.930), and the LAND arms landed within **0.07** of 27p's independently
fitted profile. Three sessions, same numbers.

**P1 IS FALSIFIED AT BOTH BRACKET ENDS.** INTERACTION **+32.81** (gate 40.07) at the prior centre
and **+67.76** (gate 80.86) at bracket HI — **82 % and 84 % of gate**. The **recovered fraction is
40.9 % and 41.9 %** across a 2× range of land cost: **the channel supplies a fixed FRACTION of what
the cancellation lever vacates, not a fixed amount.** 27j's productivity lever recovered 82.1 %.

**BUT THIS IS NOT A NULL — THE MECHANISM REPLICATES IN EVERY QUALITATIVE RESPECT.**
- **The channel is SUPPRESSED by the land error and RELEASED when it is fixed**, 27j's central
  structural claim, now with the ADMISSIBLE lever: `ent` sits at **4.342, BELOW the 5–30 band, in
  OCEAN_only** (27g got 4.16) and moves **INSIDE** it the moment the land is pinned — **5.886**,
  then **7.046**, scaling with how much land is fixed. The SH ocean limb rotates **4.13 → 9.42 mo**
  (obs 8.52; 27j 9.24).
- **P7 ✓✓ the collapse is repaired**: `sst_seas_amp_SH` recovers from 27p's crushed **0.1553
  (z −9.68)** to **0.4856**, against a 0.26 gate derived before the run.
- **P8 ✓✓, and it is the one that matters**: JOINT SH-land is **identical** to LAND-only
  (0.859 at HI). **The refit does NOT undo the land correction**, so the 58 % shortfall is a genuine
  residual cost and not the 27n failure mode.
- **The interaction is carried by the vetoed row**: `co2_seasonal_SPO` supplies **+50.36 of +67.76
  (74 %)**, no other stream above 1.1. The row that punishes each single move pays for the joint one.

**WHY IT STILL FAILS, AND IT IS GEOMETRY.** The incumbent's SPO total is right because the two limbs
sit **5.96 months apart and SUBTRACT**. Rotating the ocean into place is physically correct — nature's
land and ocean both peak ~8.5–9.3 — but it **removes the cancellation** and exposes that **SH land is
still 1.26× observed and SH ocean still 0.53× observed**. In phase, those two errors **add**:
total **1.376** against 27j's 1.267 and an observed 1.168 (**P4 ✗**). **P5 ✗ at 0.532: the channel
supplies PHASE, not AMPLITUDE.** ⚠ And the cancellation lever makes this *worse* than the
productivity lever did, because it rotates the **land** limb too (10.09 → **9.59**, where 27j left it
at 10.08), closing the gap to **0.17 mo** against 27j's 0.84.

**⚠ THE 82 % vs 42 % CONTRAST IS CONFOUNDED AND IS NOT QUOTED AS CONTROLLED.** 27j ran 6 free + ent
with `q10` FREE; this ran 4–5 free + ent with `q10` PINNED. Each interaction is balanced *within* its
design; the fraction is not a controlled cross-design comparison. **The controlled test — not run,
not pre-registered — is 27j's `seas_npp_amp_SH` lever on THIS pinned slice**, which changes only the
land knob. It is cheap.

**PREDICTIONS: 2 OF 4.** Right: P7 passes / P5 fails; `_hi` interaction > `_mid`. Wrong: P1 passes;
P4 passes at `_hi`. ⚠ **The P4 miss is worth the record.** I argued the land lever "pulls the total
DOWN" while the channel "pushes up" so "the two errors now oppose" — **treating two limbs as SCALARS
when they are VECTORS**, with 27p's phase columns in front of me and `ang_mo` computed in the driver
for exactly that reason. They do not oppose; rotating the ocean makes them **add**.

**WHERE THE ARC STANDS.** Three levers have now been tested against `co2_seasonal_SPO` and the
residual survived all three. But the defect is now **much better posed**: with the limbs finally in
phase it is an **AMPLITUDE PAIR** — SH land **1.26×** observed, SH ocean **0.53×** — that can no
longer hide inside a cancellation. **4b (the SH ocean AMPLITUDE, as distinct from the phase channel)
has now failed P5 three times — 27g, 27j and here — always for the same reason.**

⚠ **NOTHING IS ADOPTED.** `ent_seas_amp_SH` has no prior and `seas_T_amp_SH` sat at a pinned bracket
value in every arm that passed anything. No constant, no prior edited.

## 2026-08-27p — **THE CONDITIONAL SLICE WAS LEAKING 64 % OF THE LEVER THROUGH `q10`**

Pre-registered `notes/prereg_2026-08-27p_q10_pin_slice_repair.md`, committed **`a92aa5f` BEFORE**
`calibration/diag_seas_slice_q10_pin.R` existed. **No gate was moved.** Collect:
`notes/collect_2026-08-27p_the_q10_leak_disarmed_the_lever.md`. **`R/` and `src/` untouched**, so
the 1157/0 suite is untouched by construction.

**S0 ✓ S1 ✓ S2 ✓ S3 ✓ S4 ✓ S5 ✓ · ~60 s/point, against 27n's 10 / 70 / 150+ min.**

**THE MECHANISM.** `R/model.R:194-195`, written long before this arc, already says that **at small
amplitude only the product `A_T · ln(q10)` is identified** — and `q10` is **GLOBAL**. 27n's
five-parameter conditional slice rode exactly that ridge: the NH product `seas_T_amp_NH · ln(q10)`
was held to **2.98122 ± 0.00919 = 0.31 %** while its two factors moved **2.77×** and **2.75×**.
Because `q10` is shared with the SH, that cancelled the perturbation the arm existed to apply. The
SH product rose only **2.48×** where a pinned `q10` gives **6.83×** — **THE ARM DELIVERED 36.3 % OF
ITS OWN LEVER** — and the bill was `seas_T_amp_NH` running to **79.35 K, prior z +7.65**.

**THE REPAIR.** Pin `q10` at the mode's 1.13579 and leave `seas_T_amp_NH` free. The NH product still
spans its whole range through `seas_T_amp_NH` alone, so **nothing the seasonal rows identify is
removed**; what is removed is `q10`'s nonlinear part and its cross-timescale duty
(`model.R:1086`), which the LEVEL rows and `gcb_land_sink` identify. **S0: the pin costs −1.36.
S5: `gcb_land_sink` moves −0.04 = 0.03 % of the bill** — the risk the pin carried by construction
did not materialise. 27o §7's two proposed repairs (drop `q10`, or reparameterise to
(product, ratio)) are the **same slice up to a relabelling**; the pin is the simpler one.

**THE RESULT.** SH-land at bracket HI **1.2256 → 0.8595**, *below* the full-frozen 0.8728 — the four
remaining slice members are two OCEAN amplitudes, the **NH** land amplitude and a LAG, and
measurably none of them restores SH-LOCAL land. **Vacated 0.4489 ppm, closing 71.8 % of the excess,
not 15.3 %.** Honest cost **−161.72**, of which `co2_seasonal_SPO` carries **73.6 %** — the same row
from the same direction as 27i (87 %) and 27n-frozen (87 %).

**TWO 27o READINGS OVERTURNED.**
- §7 called this a **SPEED** problem. It was also an **ATTENUATION** problem —
  `[[no_power_null]]` in a new dress: not a null with no lever, but a lever silently disarmed by a
  route back through a **shared** parameter. ⚠ 27n's **P4 (−35.11)** and **P8 (1.79× obs, 15.3 %)**
  must not be quoted as the cancellation mechanism's reach.
- ⚠ §5's **"P6 ✓ — the one clean result"**, on which §6 was explicitly built (*"P6 is what makes it
  worth running"*), is **FALSIFIED**. With the leak closed `sst_seas_amp_SH` goes **0.3663 → 0.1553,
  z −6.25 → −9.68** — **past 27j's LAND-only collapse to 0.176 (z −9.18)**. The ocean limb has **no**
  room; the apparent room was the leak.

**THE EXCHANGE RATE, and it is the real lesson.** Cost per ppm of SH-land removed: the admissible
cancellation lever **193.0** on its first rung, the inadmissible productivity lever **206.8** —
**7 % apart**. **The two vetoed levers cost the SAME at the margin and differ only in how long they
stay cheap** (productivity holds ~207/ppm out to 0.383 ppm; cancellation doubles by 0.2 ppm and
trebles by 0.45). That is what a *single row pricing the SH-land amplitude regardless of which knob
moves it* looks like — a sharper form of 27o §6's "a row with no power punishing motion."
⚠ The two **chords** agreeing at 359 / 360 is chord arithmetic over different arcs on a convex
curve, **NOT** an invariance.

**WHAT IT DOES NOT DO.** It does **not** rehabilitate `seas_T_amp_SH`: conditionally **−161.72**,
worse than the −35.11 that 27o already called a veto, so the §6 veto is **strengthened**. No constant
and no prior was edited. ⚠ **S3 was mis-argued in the prereg** — I called it exact "for the same
reason as S0", but a difference of differences carries no sign constraint; the genuinely exact check
is `pinned(a) ≤ free(a)` at every rung, and it holds at all four (−1.36, −26.60, −58.95, −127.97).

**NEXT.** 27o §6's 2×2 in `seas_T_amp_SH` × `ent_seas_amp_SH` is still right but its **motivation is
replaced**: not "the ocean limb has room" (dead) but "**the admissible lever now produces the same
defect, at the same price, as the inadmissible one** — and 27j's JOINT arm is the only experiment
that ever repaired it (`ent` 8.105 inside 5–30, limb rotated 4.13 → 9.24 mo, INTERACTION +64.99)."
It must be built on the **PINNED** slice; parameter balance survives the swap (k − (k−1) − (k+1) + k
= 0). **Not pre-registered, not run.**

⚠ **Every earlier conditional slice holding BOTH `seas_T_amp_NH` and `q10` is suspect on this ground
and should be re-read before being quoted.** 27j's four arms were **checked and are CLEAN** (NH
product 2.9705–3.0224 = 1.7 %, `q10` 1.094–1.109, `seas_T_amp_NH` 29.1–33.3) because
`seas_T_amp_SH` was FREE there and absorbed the SH adjustment itself.

## 2026-08-27n — **THE CANCELLATION MECHANISM IS REAL, EXACTLY AS PREDICTED, AND UNAFFORDABLE**

Pre-registered `notes/prereg_2026-08-27n_...md`, committed **`11a59de` BEFORE**
`calibration/diag_seas_T_amp_sh_power.R` existed. **No gate was moved.** Collect:
`notes/collect_2026-08-27n_cancellation_arm_the_mechanism_is_real_and_unaffordable.md`.
**`R/` and `src/` untouched.**

**P0 ✓ P1 ✓ P2 ✓ P3 ✓ · P4 ✗ P5 ✗ P7 ✗ · P6 ✓ · P8 = 1.79× observed, 15.3 % of the excess closed.**

**THE MECHANISM IS CONFIRMED AND THE CLOSED FORM WAS RIGHT.** P1 matched the pre-registered
predictions to **0.4 / 0.4 / 0.6 / 0.7 %** against a 3 % gate. **P2's geometric floor is real and the
profile is NON-MONOTONE** — SH-land bottoms at **0.6181 at 13.95 K** (predicted 0.633) and rises to
**0.8107 at 20.0 K**, a turn only the 153° near-antiphase geometry produces. The prior pays exactly
**+8.34** (P3). **27m's diagnosis stands: SH land under-cancels, and this is its lever.**

**AND IT IS STILL UNAFFORDABLE.** Frozen at the bracket top the cost is **−204.45**, of which
`co2_seasonal_SPO` carries **−187.21 — 87 %**. The prereg fixed P5 as `Δ > 0` and wrote down what a
failure would mean: *"the SPO CO2 row is vetoing ANY change to SH land."* **It is the same signature
as 27i**, where that row carried **−113.25 of −113.87** against the *productivity* lever. **Two
levers, opposite directions, one veto** — the row already matches to ~1 %, has no power, and can only
punish motion. [[seas_right_observable_wrong_drivers]]

| a_t (K) | cond Δlp | frozen Δlp | SH-land | ×obs |
|---|---|---|---|---|
| 1.0391 (landed) | +1.43 | −0.00 | 1.3234 | 1.94 |
| 3.5915 (bracket LO) | −11.29 | −46.53 | 1.2552 | 1.84 |
| **7.1012 (bracket HI)** | **−33.68** | −204.45 | **1.2256** | **1.79** |

⚠ **P4 WAS PRE-REGISTERED AS "PREDICTED POSITIVE" AND LANDED AT −35.11. THAT PREDICTION WAS WRONG.**
The conditional slice buys back **84 %** of the frozen cost — but **by restoring the very signal the
lever removed**: frozen, SH-land falls 1.308 → 0.873 (−0.435); conditionally only 1.3234 → 1.2256
(−0.098), so **78 % of the improvement is undone** and only **15.3 %** of the excess closes against a
predicted 68.8 %. **An 84 % buy-back that returns the diagnostic to its starting value is a refusal,
not a cheaper fix.**

**P6 PASSES AND IT IS THE ONE CLEAN RESULT**: `sst_seas_amp_SH` moves only **0.3596 → 0.3046,
z −1.19**, where 27j's LAND-only arm saw it **collapse to 0.176 (z −9.18)**. **The small improvement
this lever delivers is EARNED, not bought** — and it leaves the ocean limb with room, which is what
makes the next arm worth running.

**⇒ NEXT: a 2×2 in `seas_T_amp_SH` × `ent_seas_amp_SH`** — 27j's parameter-balanced structure with
the admissible lever in place of the forbidden productivity one. NOT RUN, NOT PRE-REGISTERED.

**TWO DRIVER DEFECTS, BOTH RECORDED.** (1) The first version read streams from
`attr(lp(u), "streams")`, got NULL, and **printed "unavailable" while silently skipping P5, the arm's
own diagnostic gate** — it is `ccx_loglik(by_stream = TRUE)`. Fixed; **a gate that declines to run is
worse than one that fails.** (2) The conditional slice contains **both `seas_T_amp_NH` and `q10`,
whose product ridge is EXACT** (2.2609–2.2663 across q10 1.09→2.0, Hessian cor −0.972), so
Nelder-Mead crawls a direction the data does not constrain — points took 10 / 70 / 150+ min. Fix
recorded: drop `q10` or reparameterise; **not** raise the restart tolerance.
⚠ The archived RDS does **not** carry the streams (fix postdates the run).

## 2026-08-27m — **TWO NON-MODIS PRODUCTS SAY THE SH SIZE SHOULD GO *UP*; THE MISSING PIECE IS CANCELLATION**

Collect: `notes/collect_2026-08-27m_nonmodis_says_the_size_is_not_the_bug.md`.
**No model runs. `R/` and `src/` untouched.**

Marcus's 27l rulings executed: re-derive off a non-MODIS product (model-derivation and circularity
accepted for a pedagogical tool), score the inversion both ways, **measure through both bases first**.
Neither named product was fetchable as named — CAMS needs a Copernicus ADS key, TRENDY is
access-by-request and unreachable — so **CMIP6 `npp` Lmon historical (34 models)** substitutes for
TRENDY and **NOAA CarbonTracker CT2022** for CAMS. Both in `MANIFEST.csv` with SHA-256 and with
their weaknesses in the `notes` column. Two build gates fired: **SAM0-UNICON returns NEGATIVE NPP**
(would have inverted that model's shape under unit-mean normalisation) and **UKESM1-0-LL died on
`2014-12-31`, which a 360-day calendar does not have**.

**⚠ THE WINDOW WAS CONFOUNDED WITH THE PRODUCT, AND IT CORRECTS 27l.** CMIP6 is monthly, MOD17
8-daily. `diag_mod17_monthly_control.R` pushes MOD17 through the identical monthly pipeline:

| SH_psnnet | swing | A range | argmin |
|---|---|---|---|
| MOD17 8-day (27l) | 1.0 pp | 0.97 → 0.30 (3.2×) | ~−40 |
| MOD17 **monthly** | **2.91 pp** | 1.01 → 0.19 (**5.26×**) | **−60, grid edge** |
| CMIP6 monthly | 3.25 pp | 1.90 → 0.35 (5.41×) | −50 |

**MOD17-monthly resembles CMIP6 far more than it resembles MOD17-8day** — most of the apparent
product disagreement was smoothing. **27l's "1.0 pp" was 8-day-specific (2.9 pp at matched windows)
and its 3.2× understated the degeneracy (5.3×).** The qualitative finding HARDENS: **the SH argmin
runs to the grid edge and is still falling — on the insolation basis the SH latitude has no interior
optimum at all.**

**THE NH POWER CHECK PASSES AND CONFIRMS TWO SHIPPED CONSTANTS.** argmin **75** in all three of
MOD17-8day, MOD17-monthly and CMIP6 (swings 5.2 / 6.29 / 5.22 pp), with A at 75 of 0.50 / 0.50 /
0.60. **`CCX_SEAS_PHI_EFF['NH'] = 75` and `SEAS_NPP_AMP_NH = 0.4969` now have independent support
from a product family with no satellite in it.**

**THE RESULT.** At the shipped phi = −30 on matched monthly windows, MOD17 gives A = **0.50** (the
shipped value) and **CMIP6 gives 0.94** (IQR 0.71–1.22) — a real **~1.9× product disagreement,
LARGER than the 1.4× GPP/PsnNet bracket the whole of decision (ii) was about, and pointing the
OPPOSITE way from the arc.** With 27l's measured centroid (−15.12 → A ≈ 0.97) that is **two
independent lines saying the SH productivity swing should be roughly double the shipped constant**,
while the atmosphere says the model's SH land signal is already 1.33–1.92× too big.
**⇒ `SEAS_NPP_AMP_SH` is not the bug, and 27j's GPP move was compensating for something else.**

**AND THE INVERSION SAYS WHAT.** Net-flux column, PgC/yr peak-to-peak:

| | NH | SH |
|---|---|---|
| CMIP6 NPP (gross) | 61.5 | 15.0 |
| CT2022 NEE (net) | 42.0 | **3.8** |
| **net / gross** | **0.682** | **0.251** |

**SH land cancels 74.9 % of its gross productivity swing before the atmosphere sees it; the NH
cancels 31.8 % — a 2.72× asymmetry.** SH productivity is water-driven, so photosynthesis and
heterotrophic respiration share a wet season and nearly cancel; the NH's separate in time.
**The model carries ~half the gross and UNDER-CANCELS — shrinking the gross mimics cancellation with
the wrong knob.** Named suspect already on the books: `seas_T_amp_SH` multiplies soil respiration and
the fit drove **SH land to 29 % of its bracket's LOW end** while cranking NH land to 131 % of its
HIGH end. **NOT TESTED — a hypothesis with a lever and a sign, to be pre-registered.**

⚠ CT2022's SH land uptake centroid is **month 2.23**, but converting a flux centroid to the CO2
signature phase is an integration and **was not done** — do not difference it against the model's
10.09 SPO land peak. ⚠ The **second inversion column** Marcus asked for (the model-mediated
constant) is **not run**; it needs a model evaluation at the mode.

## 2026-08-27l — **THE SH (shape, size) PAIR IS A DEGENERATE RIDGE; THE ARC'S RESIDUAL IS INSIDE IT**

Collect: `notes/collect_2026-08-27l_the_sh_pair_is_a_degenerate_ridge.md`.
**Nothing in `R/` or `src/` touched except one comment** (below). No model runs.

**DECISION (ii) OF HANDOFF 27k IS ANSWERED, AND THE PROVENANCE ANSWERED IT ON 2026-08-20.**
`data-raw/build_npp_seasonal_shape.R:20-28` and `DATA.md:237-242` say the GPP/PsnNet bracket is
**ORDERED, not symmetric**: GPP is less rectified than NPP because autotrophic respiration runs
through the shoulder seasons, so its phi_eff is biased equatorward — the derivation's own words,
"toward the convenient answer" — and **"the truth for NPP sits at or BEYOND the PsnNet end."**
`R/model.R:1115` confirms the driver multiplies the model's own `npp` through the leaf pool, so
PsnNet is its observable. **⇒ 27j's LAND-only and JOINT arms are INADMISSIBLE as candidate
configurations.** What survives is 27j's **INTERACTION (+64.99)** as evidence that the land and
ocean corrections COUPLE — a structural claim that does not depend on 0.352.

**MARCUS'S RULING: re-derive the bracket off a NON-MODIS product.** Neither end trusted; MOD17 is a
single point of failure for a constant carrying the whole seasonal arc.

**AND THEN THE BRACKET TURNED OUT NOT TO BE THE UNCERTAINTY.** Re-running the existing offline
`calibration/diag_seas_rectification.R` and reading its Form-C profile — `A` re-optimised at every
phi, which its own header calls the only fair way — for the **SH**, a row never read for this
question:

| phi | −15.75 | −20 | −25 | **−30 (shipped)** | −40 | −50 |
|---|---|---|---|---|---|---|
| `SH_psnnet` residual | 12.9% | 12.5% | 12.2% | **12.0%** | 11.9% | 12.2% |
| `SH_psnnet` fitted A | **0.97** | 0.77 | 0.61 | **0.50** | 0.36 | **0.30** |

**The SH latitude is NOT determined** — 1.0 percentage-point over 34°, against the NH's 5.2-point
swing to a clean interior optimum at 75. Form C leaves **92 %** of the SH residual (NH: 65 %), so
there is a ~12 % floor no single-latitude insolation curve gets below — the stated physics being
that 76 % of SH NPP is equatorward of 23.5 S and the cycle is **water-driven, not light-driven**.

    GPP/PsnNet bracket           1.4x   <- what 27i, 27j and decision (ii) argued about
    SH land residual (27j)       1.33x  <- what the arc is trying to close
    (phi, A) ridge degeneracy    3.2x   <- what is actually unpinned

**`0.5027` was never a pinned measurement — it is one point on a flat ridge, selected by a phi_eff
of −30 the data cannot distinguish from −15.75 or −40.** And the ridge holds BOTH answers at equal
cost: the **measured** SH NPP centroid −15.12 gives **A = 0.97** (SH land nearly DOUBLE, the wrong
way for the arc), while −40/−50 gives **0.36/0.30**, past the GPP end and the way the fit wants.

**⇒ MARCUS'S TASK IS RE-SPECIFIED, NOT REFUSED.** A replacement product fitted onto the same
insolation basis lands on the same ridge and returns a new number without pinning anything —
**necessary, not sufficient.** An independence audit of the candidates is in the collect (sec.4);
its trap is that **atmospheric inversions are CIRCULAR here**, being constrained by the same MLO/SPO
CO2 the model is scored on, and **FLUXCOM and GOSIF/CSIF are MODIS-fed** and fail on independence.
**TRENDY is the only candidate that IS NPP**; every other option reproduces "neither is NPP" in a
new instrument. Three questions are open to Marcus (collect sec.5).

**ALSO: handoff 27k's live item CLOSED.** `R/likelihood.R:175`'s "66 % of `tau_ex`'s leverage came
from the seasonal harmonics" is now qualified with 27h's measurement that it describes only the
**LOWER jaw** — upward at 1.26 tau_0 the bill is annual-mean isotopes and levels, the four seasonal
rows net −3.40, and `co2_seasonal_SPO` **improves +9.74**. Comment only, commit `6e26248`.
**Suite 1157 pass / 0 fail, unchanged.**

## 2026-08-27j — **ONE FIX, CONFIRMED: interaction +64.99 against a pre-registered gate of +39.59**

Pre-registered in `notes/prereg_2026-08-27j_joint_land_ocean_arm.md`, committed **`fa83faa` before
`calibration/diag_joint_land_ocean_refit.R` existed**. No gate was moved. All four arms converged.
**Nothing in `R/` or `src/` touched.**

A 2×2 — land at PsnNet 0.5027 vs the GPP end 0.352, ocean channel off vs free in 5–30 — because
the claim was an INTERACTION, and

    INTERACTION = JOINT − LAND-only − OCEAN-only + INCUMBENT,   npar 7−6−7+6 = 0

is parameter-balanced and therefore interpretable, where a bare challenger-minus-incumbent
Δlogpost is not (27g refused to read one, correctly).

| arm | land | ent | vs incumbent |
|---|---|---|---|
| LAND-only | 0.352 | 0 | **−79.18** |
| OCEAN-only | 0.5027 | 4.31 | **+11.93** (reproduces 27g's 4.16 / +11.62) |
| **JOINT** | 0.352 | **8.11** | **−2.26** (sum of singles: −67.25) |

**⇒ INTERACTION +64.99: 82 % of the land reduction's penalty is recovered when the channel is
present.** P0 PASS · **P1 CONFIRMED** · P2 PASS (**ent 8.11, inside 5–30 for the first time** —
27g landed 4.16, below) · P3 PASS (**partition 1.93 → 1.390**, beating both singles, 1.834 land /
1.765 ocean) · P4 **FAIL** (total 1.267 vs gate 1.114–1.222) · P5 **FAIL** (ocean ratio 0.495 vs
≥0.75) · P6 PASS (MLO 0.966).

**The channel was being SUPPRESSED by the land error.** Given a corrected land the fit takes it to
8.11 µmol/kg and uses it to **rotate the SPO ocean limb 4.13 → 9.24 months**, against an observed
8.52 — the quantity **27g's P3 scored FAILED** on (3.35 → 3.45, +0.10). ⚠ Not a 27j gate and not
claimed as a pass; reported as a measured outcome.

**And LAND-only catches the cancellation in the act:** cutting land should shrink the total, so a
compensating fit should raise the ocean — instead `sst_seas_amp_SH` collapses to **0.176 (z −9.18)**,
because the solubility limb at month 4.13 was ANTIPHASE to land at 10.11 and *subtracting*.

**Why P4/P5 failed, and it is one reason twice.** Once the ocean limb reaches 9.24 it is nearly in
phase with land at 10.08, so the two now ADD where they used to cancel — the assembly nature uses.
But **SH-local land is still 0.906 = 1.33× the observed 0.683** (the GPP end was not far enough),
so two in-phase parts overshoot; and the wrong-phase solubility limb is still carried at
`sst_seas_amp_SH` 0.656 (37.6 % of observed, z −3.92), cancelling the channel and holding the net
ocean at 0.258 against an observed 0.522.

### What this does NOT licence

Not a licence to adopt the GPP end — `seas_npp_amp_SH` was FIXED, not fitted, so the interaction
shows the corrections couple, not that 0.352 is right; PsnNet and GPP disagree by 1.4× and the
model uses one end without saying why. **Marcus's call, on the measurement's terms.** Not a verdict
on `phi_eff` — the (shape, size) pair must be re-derived together. **4b is not ruled out but is no
longer indicated**: the existing channel reached its physical band and the right phase.

⚠ `seas_T_amp_NH` lands at 31.41, prior z **+3.50**, the largest positive flag in the slice, and it
moves the same way in every arm. Not caused by this experiment, not explained by it, not clean.

**⇒ Next, in order:** (A) re-derive `CCX_SEAS_PHI_EFF['SH']` and `SEAS_NPP_AMP_SH` TOGETHER against
the observed SH productivity cycle — the residual is a land SIZE error of 1.33× and the size is half
of a pair whose shape has never been re-fitted for the SH; (B) pin `sst_seas_amp_SH` or price it
honestly. Full reasoning in
`notes/collect_2026-08-27j_one_fix_confirmed_the_residual_is_still_land.md` §4.

## 2026-08-27i — `seas_npp_amp_SH` has the SIGN but not the price: **the land and ocean fixes are ONE fix**

Marcus chose 27h fork **(A)**: power-check `seas_npp_amp_SH` — the dominant SH-local land channel at
SPO and a MEASURED CONSTANT no fit can touch — before designing any refit around it.
`calibration/diag_seas_npp_sh_power.R` added; **nothing in `R/` or `src/` touched.**

**The grid came from the measurement.** `R/constants.R` gives PsnNet **0.5027 ± 0.087** with **GPP
at 0.352** as the other end of the bracket, so the GPP end is **−1.73 sd** and the span is a
measured product disagreement, not a chosen one. Gate: the driver factor `insol/n − 1` integrates
to **1.086e-16** over a year, so this redistributes carbon within the year; measured rectification
is negligible (every level row ≤ 0.06 across the whole grid).

**IT HAS THE SIGN.** SH-local land at SPO goes **1.308 (1.92× obs) → 0.892 (1.31×)** at the GPP
end — **67 % of the excess** — where 27h's `tau_ex` at 4× made the ratio *worse*. The δ¹³C-per-ppm
partition ratio improves too, but **the raw and conditional arms disagree in sign** (raw
1.930 → 1.950 *worse*; conditional 1.940 → **1.834** better), so both are now printed. MLO control
0.965 → 0.965, invariant.

**BUT THE PRICE IS 79 LOG-UNITS CONDITIONALLY (113.9 raw), AND THE ENTIRE BILL IS ONE ROW:**
`co2_seasonal_SPO` **−113.25** of the −113.87, while `d13c_seasonal_SPO` **improves +2.99** and
every level/gradient row moves ≤ 0.03. The CO2 amplitude row vetoes the land reduction; the δ¹³C
row wants it. And that CO2 row is the one already matched to ~1 %, so it can only punish a driver
that moves, never reward a correct one ([[seas_right_observable_wrong_drivers]]).

### ⇒ The finding

**The model's SPO total cycle is right BY CANCELLATION** — 1.141 against observed 1.168 (−2.3 %),
built from land 1.92× too big and ocean 0.45× too small, ~5 months apart. Remove the excess land
alone and the total collapses to 0.882 (−25 %). **This is the exact mirror of 27g**, where the
entrainment channel worked mechanically but was spent as a counterweight because the total was
already right.

**The land correction and the ocean correction are not two candidate fixes. They are ONE fix, and
neither arm can be scored alone.** Every experiment that has moved one while holding the other has
been charged for breaking a cancellation.

The joint arithmetic lands: the GPP end leaves the total **0.286 ppm short**, and 27g's P1 measured
the entrainment channel adding **≈ 0.37 ppm at month 9.91** (from 0.247 @ 3.68) at 10 µmol/kg,
inside the 5–30 physical band and within 1.4 months of the observed ocean peak of 8.52. Right size,
right phase.

**Recommended next:** a pre-registered **JOINT arm** — `seas_npp_amp_SH` at the GPP end AND
`ent_seas_amp_SH` free in 5–30, matched design. Predictions and falsifier in
`notes/collect_2026-08-27i_the_land_and_ocean_fix_is_one_fix.md` §4. If it fails, **4b becomes the
live question** on a residual that has finally had both levers available. Marcus's call — and
moving a measured constant to the far end of its bracket needs his sign-off on its own terms.

### Fixed en route

- **A silently empty report.** `ccx_model_stats()` returns a LIST of columns, so `nrow()` is NULL,
  `sprintf()` returns `character(0)`, and `cat()` printed nothing — the whole rectification block
  vanished without an error. `length()` + a `stopifnot`.
- **`ccx_total(o)`** takes a state matrix, not the output series. And an invariant annual mean was
  the wrong thing to assert anyway: gate the structure, MEASURE the rectification.

## 2026-08-27h — `tau_ex` POWER PRE-CHECK: **fork (a) is a guaranteed null, and it was not run**

Marcus chose handoff 27h §4 **fork (a)** — pre-register and run the 27g seasonal slice **plus
`tau_ex`**, on the hypothesis that P3 scored FAILED because the slice froze the only fittable lever
on the 0.821 ppm NH seasonal import into SPO. **The wider slice was NOT run, no prereg was written
for it, and that is the result.** The power was measured first, because the test's null was at risk
of being structurally guaranteed: if the interhemispheric rows pin `tau_ex`, "we freed it and P3
still failed" and "we never freed it" produce the same output.

**This is the second half of 27e, not a re-derivation of it.** `diag_tau_ex_leak_profile.R` already
exonerated `tau_ex` as a **partition** lever (SPO δ¹³C-per-ppm moves 4.2 % over a 5.7× range).
Handoff 27h §4 accepts that and says the binding error is one of **SIZE** — which 27e did not
settle, and could not: its own header calls it frozen in the other 20 parameters, every cost an
overstatement, with `grad_off_co2` named as an unremoved caveat. All three are removed here.

Two diagnostics added. **Nothing in `R/` or `src/` was touched.**

    calibration/diag_tau_ex_seasonal_power.R      # 15-point profile, offsets re-optimised, ~12 min
    calibration/diag_tau_ex_conditional_power.R   # whole 8-par slice re-optimised at fixed tau_ex

### Three findings, ascending in force

**PRICE.** `tau_ex` is pinned to **~2.6 % per log-unit**. The 27g challenger's entire **+11.62**
net gain buys τ +9.2 %, moving the NH import **0.821 → 0.758 ppm** — **0.0054 ppm per log-unit,
9 % of the ~0.70 ppm SPO land excess.** The conditional slice buys back ~30 % of the profile's cost
(1.26τ: 77.01 → 53.93) without changing the verdict, and that point is **bought, not earned**:
`grad_off_co2` lands at −0.827 ppm, past the measured station-latitude constant (−0.386/−0.549).
The analytic two-box gain `(1/τ)/√(ω²+1/τ²)` is **verified against the measured import to 2–6 %**
across an 8× range, so the 1/τ law is the right model of this lever.

**INVARIANCE.** Over that 8× grid, at any price, the SPO **total** moves 1.141 → 1.121 (−1.7 %) and
**SH-LOCAL land** 1.308 → 1.331 (**+1.7 %**) while NH-origin falls 73 %. `tau_ex` **reallocates**
SPO's cycle between NH-origin and SH-local; it does not shrink it.

**SIGN.** Re-run in the handoff's own estimator, the signature inversion, at τ = 4.636 yr (4.00×,
−4529 log-units): the SPO land ratio goes **2.01× → 2.07×, WORSE**. NH-origin peaks month **6.47**
and SH-local land month **10.09** — **108° apart, so they partially CANCEL**.
**⇒ The NH import is not causing the SH-land overshoot; it is partly HIDING it.** Handoff §4's
arithmetic is right and operationally irrelevant.

### A standing code note now needs qualifying

`R/likelihood.R:175` — "66 % of `tau_ex`'s leverage came from the seasonal harmonics", written
2026-08-15 *as the justification for adding* the gradient term — holds only **downward** (at 0.79τ:
`co2_seasonal_SPO` −57.0, `co2_seasonal_MLO` −28.3). **Upward, the direction that shrinks the
import, the bill is annual-mean**: `d13c_level_MLO` −20.4, `d13c_level_SPO` −14.4, `d14c_NH` −12.1,
`co2_level_MLO` −9.5, `d14c_SH` −8.0, `co2_gradient` −7.5 — with the four seasonal rows netting
**−3.4**, and `co2_seasonal_SPO` actually **improving** +9.74.

### Tried and discarded

- **The wider slice itself.** Predictable from the above and not evidence. Reporting "P3 FAILED
  again" from it would be a powerless null dressed as a finding.
- **The first conditional run.** Hit `maxit` at all three points. An under-converged optimum at
  fixed `tau_ex` overstates that `tau_ex`'s cost — it manufactures exactly the verdict the script
  exists to test. Replaced by continuation warm-start + BFGS polish + restart-until-still, with the
  restart count and last gain printed so a silent `maxit` cannot recur.
- **A first grid whose smallest step above the mode was 1.26×.** That step costs 77 log-units, so
  every affordability rung resolved to "1.00×" and printed NA. Fine points at 1.03–1.19 added.
- **`p$bomb_total` / `p$luc_scale` in the new `run_at()`.** Seven of the 21 calibrated names are
  likelihood-side and absent from `ccx_default_params()`, so `p$bomb_total` was NULL, `NULL/102` is
  `numeric(0)`, and the c14 column silently became zero-length. Read off `pv`, as `streams_at()`
  already did.

### ⇒ The blocker moved again, and it is now specific

**The SH-LOCAL land channel at SPO is ~2× the observed land component, and `seas_npp_amp_SH` — its
dominant term (1.390 ppm at SPO against `resp SH`'s 0.092) — is a MEASURED CONSTANT no fit can
touch.** Collected in `notes/collect_2026-08-27h_tau_ex_has_no_power_and_the_wrong_sign.md` §4 with
three candidate readings and a recommendation to POWER-CHECK `seas_npp_amp_SH` before designing any
refit around it. Marcus's call.

## 2026-08-27g — the SOUTHERN-OCEAN ENTRAINMENT CHANNEL (version 4a): P0 green, P1 has power

Pre-registered in `notes/prereg_2026-08-27g_so_entrainment_channel.md`, written before a line of
the channel existed. **Two decisions taken by Marcus first, both from handoff 27g:**

- **§4 SCOPE → 4a**, a second seasonal air-sea CHANNEL. One SH ocean box, no new state, no C++
  column port. **4b (a genuine second SH ocean column) is HELD, conditional on 4a's residual.**
- **§7 ESTIMATOR → `|mean vector|`.** The standing SPO partition target is therefore **1.93×**,
  not the ~1.48× that had been quoted.

### The estimator, and why it changes no result

`CCX_SEAS_AMP_ESTIMATOR` + `ccx_harmonic_amp()` / `ccx_harmonic_peak_month()` give the two
estimators one named home. **The likelihood scores the per-year sin/cos COEFFICIENTS and never
forms an amplitude**, so this moves no objective and no gate — it is reporting only.
`diag_seas_isotope_rectification.R` now prints BOTH estimators and the per-series inflation, so
the **1.33×** that lands in the observed SPO δ¹³C DENOMINATOR is a measurement in the output
rather than a claim in a comment. All four MODEL series sit at 1.00×, having no interannual
scatter to inflate; only the observed SPO δ¹³C series does.

### The channel

A zero-mean seasonal DIC anomaly on the SH mixed layer, peaking at `CCX_ENT_SEAS_PEAK_MO = 7.50`
— **MEASURED** from the ocean-area-weighted 40–90 S pCO2 first harmonic, the same standing as
`CCX_SST_SEAS_LAG` = 1.32, **not fitted**. It perturbs only the DIC entering the pCO2 calculation,
so it moves no carbon vertically and adds no box, and it reaches the atmosphere through the
evasion limb that already carries `alpha_as_up` — so what it adds is **ocean-signatured**. That is
the point: SPO's cycle is too photosynthetic. **SH only**, and the asymmetry is measured rather
than convenient: NH-mean pCO2 is **0.30 months** from NH-mean SST, so the NH gets no twin.

Default 0, and ABSENT is 0 too, so every stored mode still runs the model it was fitted to. **Not
in `CCX_PARAM_TABLE`** — adding it would change the calibrated vector's length and invalidate the
stored mode and its Hessian.

### P0, the method control — 35 assertions, all PASS

Bit-identical at zero amplitude in BOTH cores; R/C++ parity with the channel ON at
`test-parity.R`'s tolerance; **a mutation guard so parity cannot pass by both cores ignoring the
parameter**; `seas_drivers = 0` kills it; conservation on `ccx_total()` in a closed system.

It also **discharges 27g §6's audit**: `ccx_hold_climate()` is COMPLETE over the forcing columns
that carry climate (`gmst`, `enso`, `sst_anom_{NH,SH}`), and the gap found in 27c is structural
and confined to the cycles `ccx_deriv()` generates from PARAMETERS and `t` — land T, NPP, SST, and
now entrainment. Those are gated by `seas_drivers`, which is the control to use. **An inventory
gate now fails if a new forcing column appears without that decision being made.**

### THE RESULT: P3 FAILED — the fit used the channel as a COUNTERWEIGHT

Scored in `notes/collect_2026-08-27g_entrainment_channel_is_a_counterweight.md`. **Two PASS, one
PARTIAL, one INCONCLUSIVE, one FAILED. No threshold was moved after the fact.**

**The channel does what it was built to do, and the fit declined to use it that way.** Given the
freedom it spent the new limb on *permission to double the wrong-phase solubility limb* —
`sst_seas_amp_SH` 0.360 → **0.741** (prior z −6.32 → **−3.43**, 20.6 % → 42.5 % of observed) —
while the NET ocean component stayed in austral autumn:

| SPO ocean component | amplitude | peak month | vs obs |
|---|---|---|---|
| mode (channel off) | 0.236 ppm | 3.35 | 0.45× |
| **challenger (channel 4.16)** | **0.124 ppm** | **3.45** | **0.23×** |
| observed | 0.522 ppm | 8.52 | — |

**P3 FAILED** on its own falsifier (stayed within 1.0 month of 3.35). **P4 INCONCLUSIVE**: the SPO
residual moved **1.93× → 1.77×** with the MLO control at 0.97×, between its gates of ≤1.70 (pass)
and ≥1.85 (fail). **P2 PARTIAL**: the amplitude rose, but the SPO pair fell 287.2 → 286.1.

**THE +11.62 IS +16.78 PRIOR AGAINST −5.17 LIKELIHOOD**, measured. The channel buys the model
permission to move its drivers toward observation at a thin, spread likelihood cost.

**WHY, and it is not in the ocean.** SH land at SPO is **2.05× observed**, and **0.821 ppm of the
model's 1.364 arrives from the NH**. The total SPO CO2 amplitude already overshoots at the
challenger (−2.5 % → **+5.8 %**), so a bigger net ocean limb is unaffordable and the only
profitable use of the channel is as a counterweight.

**⚠ A LIMIT OF MY OWN DESIGN.** The P2 slice held no lever on the land: `seas_npp_amp_SH` — the
dominant SH-local channel at SPO (1.390 ppm against `resp SH`'s 0.092) — is a measured constant
and not fittable; **`tau_ex` is fittable, carries the NH import, and I froze it.** So P3's failure
may be an artefact of the slice rather than the physics. **That is a hypothesis for a new
pre-registered test, not a licence to re-run this one with `tau_ex` added and relabel it.** (27e
exonerated `tau_ex` as a PARTITION lever while saying the leak is a SIZE error — size is what
binds here, so the two findings do not conflict.)

**WHAT IT SAYS ABOUT 4b:** not yet a case for it, and not a case against. **The blocker this
residual identifies is not the ocean's structure**, and a second SH ocean column would not shrink
an SH land component that is 2× too big. Recommended order: the wider slice (seasonal block +
`tau_ex`) first, 4b decided after.

### Bugs found in the OLDER diagnostics, which only bite once the ocean has two limbs

`air-sea SH off` was `sst_seas_amp_SH = 0` in **both** `diag_seas_signature_inversion.R` and
`diag_seas_channel_decomp.R`, leaving the entrainment limb running — and in the inversion that
case is where the **ocean signature `s_O`** is measured, so it was substantive rather than
cosmetic. Both now switch off both limbs, identically to before at amplitude 0. The inversion also
printed its amplitude from the env var rather than the value used, so a run at 4.16 announced
"channel OFF".

### P1, the power measurement — PASS, and the phase is right

Threshold **0.70 ppm**, taken from the OBSERVED antiphase gap (model SPO ocean 0.236 ppm at month
3.35, observed 0.522 at 8.52 — 5.17 months apart, so the vector difference is 0.236 + 0.522), not
chosen to pass. At **10 µmol/kg**, inside the 5–30 µmol/kg the prereg's pre-check derives, the
channel delivers **0.860 ppm** at SPO and the model's whole ocean component moves

| | amplitude | peak month |
|---|---|---|
| model, channel off | 0.247 ppm | 3.68 |
| model, channel at 10 | **0.614 ppm** | **9.91** |
| observed (inversion) | 0.522 ppm | 8.52 |

**Size and phase both land near observation, and the ocean limb rotates ~6 months** — so this is
not a reparametrisation of `sst_seas_amp_SH`, which was the failure mode named in advance.

**AND THE COST IS EXACTLY WHERE THE ACCOUNT SAYS IT SHOULD BE.** At frozen neighbours the whole
bill falls on `co2_seasonal_SPO` (57.4 → −169.5) while `d13c_seasonal_SPO` barely moves (−3.4).
The SPO CO2 amplitude was already matched **by two errors cancelling**; adding a correctly-phased
ocean limb puts ocean (9.84) nearly in phase with land (8.82), as the observations have them
(8.52 and 9.29), so the total overshoots **until the land comes down**. Model SPO land is 2.01×
observed. **That is what P2 tests.**

### Two bugs found and fixed before anything was believed

- `diag_so_entrainment_power.R`'s "total ocean" column subtracted a run that **still had the
  channel on**, and so reported a dead-flat 0.247 ppm at month 3.68 for every amplitude. It was
  isolating the SST limb and calling it the ocean.
- The first conservation assertion used `ocean_C + land_C + atm_C`, which **omits the wood/product
  pool** — replaced by the repo's own `ccx_total()` identity in a closed system.

### ⚠ AN OPEN ITEM FOUND IN PASSING, PRE-EXISTING AND NOT CAUSED BY THIS WORK

**`ccx_make_logpost()` does not reproduce the canonical mode's stored `logpost` at the mode's own
`u_mode`: −1547.9370 against a stored −1544.6148, an offset of −3.3223.** Verified **identical at
commit `fbf4b4c`**, before the entrainment channel existed, by checking `R/` and `src/` out at
that commit in the working tree. Entirely in the LIKELIHOOD — the prior + Jacobian reproduce to
the last decimal (−57.3519, and stored streams + that prior = the stored logpost exactly).

**Its signature is an INTERHEMISPHERIC REDISTRIBUTION**, NH and SH rows moving in mirror-image
pairs: `d14c_NH` −2.78 / `d14c_SH` +2.44, `d13c_level_MLO` −2.65 / `d13c_level_SPO` +1.97,
`co2_level_MLO` −2.58 / `co2_level_SPO` −0.66.

**Ruled out:** `FORC_USE_LUC_NH_SHARE_TS` and `FORC_USE_EMIS_SEASONALITY` (all four combinations
tried; the shipped TRUE/TRUE is the best AND is the one that is 3.32 off), `substeps` (4 both
ways), and the refit's `h_ml` [85, 120] bound (`h_ml` = 85.729 is inside both brackets, and the
prior reproduces exactly regardless). **NOT diagnosed further — flagged, not resolved.**

**It does not invalidate P2**, whose comparison is MATCHED (`match_incumbents_optim`): incumbent
and challenger are scored by the SAME harness, so a constant offset cancels out of every
difference. What it WOULD invalidate is quoting an absolute logpost from the refit script against
a number from the mode file, so that script does not do it and carries the offset as a named
constant with a gate that fires if it ever moves.


## 2026-08-27e/f — `tau_ex` EXONERATED; and the SH ocean channel's PHASE is RIGHT — its WEIGHTING is wrong

Pre-registered in `notes/prereg_2026-08-27e_tau_ex_leak_profile.md` and
`notes/prereg_2026-08-27f_so_pco2_phase.md`; scored in
`notes/collect_2026-08-27ef_tau_ex_exonerated_and_the_weighting_error.md`. **Seven predictions,
three FAILED, and the failures are the result.**

**⚠ CORRECTING HANDOFF 27d §3(a) IN PLACE.** It read the 4.16-vs-8.52 phase gap as "the model's
SH air-sea channel arrives in the wrong season". **The gap is real; my reading of it was half
wrong.** Against the Landschützer/Laruelle merged pCO2 climatology (NCEI 0209633, downloaded and
registered today, Marcus's choice):

| band | pCO2 amp µatm | peak mo | SST peak mo | gap |
|---|---|---|---|---|
| **SH all (0–90 S)** | **4.56** | **1.20** | 2.05 | **0.85** |
| SH subtrop 0–30 S | 16.41 | 1.43 | 2.21 | 0.78 |
| **SO 40–90 S** | **19.45** | **7.50** | 1.94 | **5.56** |
| NH all (0–90 N) | 2.93 | 8.14 | 7.84 | 0.30 |

**P1 FAILED**: SH-MEAN ocean pCO2 is 0.85 months from SH-mean SST, so a solubility-only channel is
the RIGHT description of the hemispheric mean. **P4 FAILED**: the model's channel at 4.16 matches
the observed SH-mean ΔpCO2-implied 4.54 to **0.38 months**. I had conflated "the SH ocean" with
"the Southern Ocean"; they are antiphase.

**WHAT IS ACTUALLY WRONG IS THE WEIGHTING.** Subtropical limb (0–40 S) **11.70 at month 1.38**
against Southern Ocean (40–90 S) **7.18 at month 7.50** — **5.88 months apart**. Vector sum 4.56
against a scalar 18.87: **76 % CANCELS**. **The model matches the residual, which is not matching
either regime.** What SPO sees is the Southern Ocean — its ΔpCO2 peaks **7.41** against the
inversion's atmospheric **8.52 [7.82, 9.20]**, a 1.13-month lag (shorter than a quarter cycle
because the box loses signal); the subtropical limb at 1.52 cannot produce 8.52 at any lag.

⇒ **No value of `sst_seas_amp_SH` can fix this — the parameter scales a phase it cannot rotate**,
which is why the fit suppressed it to 21 % of observed. **§7c-3 lands on Marcus's own named
candidate: LATITUDE BANDS WITHIN A HEMISPHERE.** And the NH working is the control: NH-mean pCO2
is 0.30 months from NH SST, so the NH really is solubility-dominated at the hemispheric mean.

**P2 CONFIRMED converts the mechanism from a reading into a measurement**: south of 40 S pCO2
peaks month 7.50, **5.56 months** from SST — wintertime entrainment raising pCO2 in the season
solubility alone would lower it. **P3 method control PASSED** (subtropical gap 0.78 ≤ 2.5).

**`tau_ex` IS EXONERATED AS A PARTITION LEVER (27e).** 11 nodes over 0.7–4.0 yr, two runs each so
the leak is differenced vectorially at every node. **P2 CONFIRMED**: the SPO δ¹³C-per-ppm ratio
moves **4.2 % across a 5.7× range** of `tau_ex` (1.83×→1.99×, fitted 1.91×) against a ±10 % band —
**transport relabels WHERE the cycle was made, not WHAT made it.** The leak is a SIZE error, not
the partition error. **P1 CONFIRMED on its falsifier** (leak 0.422 ppm at τ = 2.371 vs a predicted
0.42–0.48) but **MISSED on its other half** — the SH-sink damping falls monotonically 11.0 → 5.9 %,
it is not constant. **P3's substantive half CONFIRMED** (seasonal and gradient rows disagree in
direction) **but MY SIGN WAS WRONG**: `co2_seasonal_SPO` wants a LONGER `tau_ex`, not shorter — I
reasoned from amplitude alone on a row that is phase-driven, the same scalar-reading error
`diag_seas_channel_decomp.R`'s header already records. **And my first P3 readout was an artefact
of my own grid** (log spacing put 1.181 8× closer to the fitted 1.159 than 0.992); replaced with a
symmetric central difference in ln τ, which also gives a free convergence check —
slope÷curvature puts the optimum at **1.156** against the stored **1.159**, 0.3 %.

**⚠ A MASKING BUG, FOUND AND FIXED THE SAME DAY, AND WHAT IT DID NOT COST.** The pCO2 file names
its fill attribute `FillValue`, not the CF-standard `_FillValue`, **and stores it as a STRING**, so
`ncdf4` applied nothing and −999 entered every band mean over land. Caught by an arithmetic
impossibility — ocean-area band weights came back EXACTLY equal to the sin(lat) hemispheric ones
(0.500/0.143/0.357), which cannot happen in a band containing Australia — after the script's own
"100.0 % of cells valid" line had been read past. **−999 is CONSTANT IN TIME, so it contributes
nothing to a seasonal harmonic: every PHASE above is unchanged to the last decimal and no verdict
moved.** Only AMPLITUDES were wrong, scaled by each band's ocean fraction (SH-mean 3.69 → 4.56;
60–90 S, the most land/ice-covered band, 25.19 → 41.91). All amplitudes here and in the collect
note, handoff and memory are the CORRECTED ones. `diag_so_pco2_phase.R` now reads the fill value
from the file, coerces and asserts it, and **gates the finite fraction to 0.55–0.78**.

**Carried:** pCO2 is NOT flux (`F = k·K0·ΔpCO2`; no wind or K0 seasonality in any number here, so
nothing above is a flux amplitude); a climatology carries no error bar, so the spread ACROSS BANDS
is the honest scale; the `tau_ex` profile is frozen in 20 parameters and overstates every cost.

## 2026-08-27d — §7c-3 OPENED: the model builds SPO's cycle out of the WRONG TWO PIECES, and its ocean piece arrives FIVE MONTHS LATE

Pre-registered in `notes/prereg_2026-08-27d_sh_seasonal_partition_power.md` before either
measurement ran; scored in `notes/collect_2026-08-27d_sh_seasonal_partition_inversion.md`.
**All six predictions recorded, hits and misses.**

**THE TABLE.** The observed seasonal cycle split into LAND and OCEAN components by their δ¹³C
signatures — amplitude AND phase, from the observations alone — against the same split of the
model's:

| stn | part | obs amp | model amp | ratio | obs peak mo | model peak mo | phase err |
|---|---|---|---|---|---|---|---|
| MLO | land | 7.717 | 7.235 | 0.94× | 3.39 | 3.54 | +0.15 |
| MLO | ocean | 1.091 | 0.582 | 0.53× | 8.35 | 9.50 | +1.16 |
| **SPO** | **land** | **0.683** | **1.373** | **2.01×** | 9.29 | 8.82 | −0.47 |
| **SPO** | **ocean** | **0.522** | **0.236** | **0.45×** | **8.52** | **3.35** | **−5.17** |

**Nature ADDS two nearly in-phase pieces** at SPO (0.77 months apart, 58 % + 45 % ≈ 103 %).
**The model SUBTRACTS two nearly antiphase ones** (5.47 months apart, 120 % − 21 % ≈ 99 %).
The CO2 amplitude agrees to 2 % **because two errors cancel** — which is handoff 27c §3's "the CO2
rows have no power" turned from an inference into a measurement.

**MEASUREMENT A** (`diag_seas_channel_decomp.R`, three cross-hemisphere cases added). **72.0 % of
the model's SPO cycle is NH-ORIGIN**, arriving 2.25 months early (108°); the two parts close to
the total as vectors within 1.6 %. The analytic two-box transfer function at `tau_ex` = 1.159 yr —
`|C_S/C_N| = (1/τ)/√(ω²+1/τ²)` = 0.1360, lag `atan(ωτ)` = 2.74 mo — predicted 0.897 ppm undamped
against 0.821 measured, so the SH sinks damp it by 8 %. **P1, P2 CONFIRMED.**

**P3/P4 WITHDRAWN BEFORE SCORING, and the withdrawal is a finding.** `seas_T_amp_SH` — the
parameter carrying the −4.64 σ prior flag — moves the SPO cycle by **0.092 ppm** against
`NEP SH`'s **1.390**. It has no authority over the observable it was to be tested on, so the SH
land respiration flag is **not** being set by the SPO seasonal rows.

**MEASUREMENT B** (`diag_seas_signature_inversion.R`, NEW). Every channel's δ¹³C harmonic vector
is antiphase to its CO2 vector to within **0.43 months** (GATED, all 12 pairs), so each signature
is a signed scalar and two vector equations close exactly: `L = (d13 − s_O·CO2)/(s_L − s_O)`.
Measured `s_L` = −0.04733, `s_O` = −0.00461 ‰/ppm — **10.3× apart**, which is what conditions the
inverse. Bars: bootstrap over years × signature range, 2000 draws, **seeded**; angles averaged as
VECTORS, never as wrapped scalars. **P7 control PASSES** (MLO observed land share 113.3 %),
**P5 CONFIRMED** (SPO ocean share 44.7 %), **P6 CONFIRMED** (observed SPO ocean peaks
**8.52 [7.82, 9.20]** against the model's solubility channel at **4.16** — 4.35 months).
Cross-validated against the direct channel sum on the model side: SPO land +2.4 %, SPO ocean
−4.9 %, all four phases within 0.55 months.

**⇒ §7c-3'S CANDIDATE IS NOT A LAND BOX.** A solubility-only ocean (`sst_seas_amp_SH` modulates
SST and nothing else) can only draw CO2 down in the cold season, so month ~4 is the only phase it
can have; the observed component peaks five months later, where a seasonal mixed-layer /
entrainment cycle would put it. **The fit's 4.9× suppression of `sst_seas_amp_SH` was CORRECT** —
it was refusing a channel with the wrong phase, and its −6.32 σ flag is the model being penalised
for that refusal. And **0.821 of the model's 1.373 ppm SH land arrives from the NH — more than the
entire observed SPO land component of 0.683** — so a box placed in the SH cannot fix it.
⚠ The entrainment MECHANISM is a reading, not a citation; the PHASE is the measurement. Named
test: an observational Southern-Ocean seasonal flux climatology.

**AND A STANDING NUMBER MOVES: the SPO partition residual is 1.93×, not ~1.5×.** Same quantity,
two estimators, and the whole gap is ONE CELL — the observed SPO δ¹³C harmonic inflates **1.33×**
under `mean(sqrt(a²+b²))` where all seven other series sit at 1.00–1.02×, and 1.93/1.33 = 1.45.
`diag_seas_isotope_rectification.R` uses the mean of per-year magnitudes (Jensen-inflated by
year-to-year scatter, which flatters the model because the inflation is in the denominator);
`diag_seas_channel_decomp.R` uses the magnitude of the mean vector. **METHODOLOGICAL CHOICE,
FLAGGED NOT RESOLVED** — recommendation is the noise-immune estimator; Marcus's call.

## 2026-08-27c — `test-fluxes.R` GREEN, and a THRESHOLD RULE: observations or physical laws

Decision 6b answered. Suite **1122 pass / 0 fail**, from 2 failing.

**LINE 99 — REPAIRED BY COMPLETING ITS CONTROL** (`e816700`). Not the isotope fix: the probe is
BIT-IDENTICAL either side of `6bda464`. `tau_turn = m_atm/(gpp + as_down)` and seasonal NEP is
genuinely excluded — gpp identical to 0.000000, m_atm identical, **100 % of the difference in
`as_down`** (65.340510 → 65.556037). Toggling the paths separately: seasonal NEP on with the
seasonal SST OFF gives **4.691976, identical to baseline**. The assertion broke because
`seas_drivers` is a MASTER switch that also kills the seasonal SST cycle, a second seasonal path
that legitimately moves air-sea exchange — and `ccx_hold_climate()` does not suppress it, because
that cycle comes from the `sst_seas_amp_*` PARAMETERS, not a forcing column. Dated:
`25dce56` 0.000000 (exact) → `6fadb34` 0.002148 (a MARGIN, 46 % of tolerance, invisible) →
`7708404` 0.008054 (red). The amplitudes never moved; it was the **PHASE**, because `tau_turn[1]`
samples January alone. Repaired by holding the seasonal SST off in BOTH arms — the difference is
then exactly zero and the tolerance was not loosened.

**LINE 100 — THE MAGNITUDE GATE IS WITHDRAWN, and the rule is now standing.**
Marcus: **"Thresholds should be derived from observations or from physical laws."** My first
proposal — gate on 10× the same file's seasonality-off agreement — was rejected as self-referential,
which it is: it derives a gate from the model's own numerics and can never reject them.

Both principled routes were then TRIED AND MEASURED, and both fail *here*:
- **Observation.** The contaminating quantity is the January seasonal boundary flux, whose time
  integral IS the observed seasonal CO₂ swing — anchorable in principle. Not here: the test runs at
  `ccx_default_params()` with climate held, where model NH pk-pk is **1.66 ppm against MLO's 5.72**
  and the SH January tendency is **+2.03 against SPO's −3.40, an inverted sign**.
- **Physical law.** "Seasonal NEP is zero-mean, so a label estimate must close over 12 months" is a
  real law that **does not transfer**: measured, the 12-month contamination is **0.2307 yr, LARGER**
  than the 1-month 0.1805, because the label is rectified into and out of the leaf pool. Mass
  balance fails too — `M/(atm_out + |seas|)` predicts **0.489** against 0.1805 measured, because the
  label responds to GROSS one-way exchange, not net NEP.

**Why the old number went red: it was tracking a driver.** 0.2 was set 2026-08-13 against a measured
0.37. **`f85ef7b` (2026-08-20) took the shortening 0.7079 → 0.1805 in ONE commit** by SHIPPING THE
MEASURED NEP amplitude factors, `seas_npp_amp` 1 → **0.4969 / 0.5027** (`seas[1]` halved,
−29.430 → −14.585). The gate went red for a deliberate, evidence-based improvement.

**What is asserted instead carries NO threshold:** seasonality must make the one-month label
estimate a WORSE estimator of `tau_turn` than it is without seasonality — an ordering between two
measured quantities, with no number chosen by anyone. Measured: **0.1727 on against 0.0078 off.**

**RIGHT OBSERVABLE, WRONG DRIVERS — and a FALSE ALARM caught before it was reported.** Checking the
seasonal phase at the CANONICAL MODE with full forcing (rather than at defaults) gives model NH
**6.36** pk-pk / **+19.14** ppm/yr against MLO 5.72 / +16.75, and model SH **1.09 / −3.37** against
SPO **1.08 / −3.40** — both signs agree, SH to ~1 %, consistent with `ccx_seas_phase_late`. So the
sign inversion above is the HARNESS, not the model; I nearly reported it as a defect.

The standing consequence is larger than the test: **the model reproduces the observed seasonal CO₂
cycle while running `seas_T_amp_SH` at 29 % of its bracket's LOW end, `sst_seas_amp_SH` at 21 % of
observed and `seas_T_amp_NH` at 131 % of its HIGH end** (the 2026-08-27 §7c-2 finding). That is
`ccx_seas_partition`'s compensation seen from the **CO₂** side. ⇒ **The CO₂ seasonal rows have NO
POWER to reject the partition — they are already matched. Any test of it must run on the ISOTOPES
or on the DRIVERS.** That is a direct constraint on how §7c-3 (the SH land box) should be posed.

## 2026-08-27b — GATE 7's WINDOW DROPS 2024 (Marcus), and the CAUSE WAS HALF A MONTH

Follow-up to the 2026-08-27 entry's open decision 6a. Marcus: drop 2024.

**THE DIAGNOSIS NARROWED ON MEASUREMENT, and the earlier framing here was wrong.** The
2026-08-27 entry said the two gate-7 reconstructions disagreed because "the run ends at 2024,
so neither file has a 2025 state to difference the land stock against". That is not the size of
the gap. The run ends at **t = 2024.958**, so the 2025 year boundary is **0.0417 yr — half a
month — past the last state**, exactly as `R/likelihood.R:1422-1428` already documented. What
makes half a month worth **0.65 GtC/yr** is *where* it falls in the seasonal cycle: at a
year boundary the land stock's slope is at its most **negative** (NH December respiration), so
flat extrapolation (`approx(rule = 2)`) and linear extrapolation of that slope differ far more
than a half-month average flux would suggest. Under 0.001 GtC/yr in every other year.

**FIXED TWO WAYS, because dropping the year alone would only hide today's instance:**
1. `DG_SINK_WIN` / `FIT_SINK_WIN` = **2015–2023** in both reconstructions, and **the observed
   means are RECOMPUTED on that window** (land **2.410**, ocean **3.202**) rather than the
   published 2015–2024 figures being quoted against a nine-year model mean. The file asserts
   that recomputing on GCB's own published window still returns **2.363 / 3.221** against the
   published 2.36 / 3.22 — so the target cannot drift away from the publication silently.
2. `diag_design_gates_at_mode.R` now extrapolates the ends **LINEARLY**. It had been the one
   file using `approx(rule = 2)`, against `R/likelihood.R:1422-1428`'s stated convention and
   its stated reason ("it would land entirely on the two end years rather than spread out,
   which is the shape of a bug"). That divergence, not the window, is what let the two files
   disagree at all.

**NEW GATE 7, both reconstructions now agreeing to 1e-4:**

| | land | σ | ocean | σ |
|---|---|---|---|---|
| GCB 2025, 2015–2023 | **2.410 ± 0.50** | — | **3.202 ± 0.40** | — |
| defaults | 3.51 | +2.21 | 2.63 | −1.43 |
| **`from90`** | **3.558** | **+2.30** | **2.970** | **−0.58** |
| `pin90` | 3.85 | +2.87 | 3.02 | −0.46 |

**Verdict unchanged — FAIL land, PASS ocean.** The whole change is worth **0.02σ**; its value
is that the gate now reproduces itself.

**THE OBJECTIVE IS UNCHANGED AND NO REFIT IS OWED.** `ccx_loglik`'s `gcb_land_sink` stream still
scores 1959–**2024** and already used the linear form. Measured before deciding not to touch it:
its 2024 row sits at z **+0.86** against a 1959–2023 mean |z| of **0.64** — **1.3×, not an
outlier** — contributing −1.69 logL. This was a GATE window, not the objective, so nothing is
quarantined.

Also fixed: `diag_fit_at_mode.R`'s header printed "(adopted arm is N)" — now derived from
`CCX_MODE_CANONICAL`.

## 2026-08-27 — WHOLE-MODEL QUALITY RE-ESTABLISHED POST-FIX: §7a, §7b, and §7c items 1–2

`notes/collect_2026-08-27_post_fix_model_quality.md`. Commits `aa1c5e1`, `2779463`, `b5d482d`.
Executes §7 of `notes/handoff_2026-08-27_post_fix_model_quality.md`.

**§7a — the canonical mode is now named in ONE place.** `ccx_mode_file()` (`R/paths.R`) plus
`CCX_MODE_CANONICAL` / `CCX_MODE_FILES` / `CCX_MODE_RETIRED`. 38 sites converted, plus
`app/global.R` and `app/DEPLOY.md`. The retired names `N`/`D`/`ref` now ERROR **with the reason**
(quarantine dir + fix commit `6bda464`) rather than file-not-found — because a diagnostic that
resolves silently to a vector fitted on a different objective is the dangerous failure, and a
missing file is the loud one. `ref` is refused deliberately: its mode file is the pre-fix SEED.
`tests/testthat/test-mode-file.R` lints the literal out, with five DECLARED exemptions.
`CCX_MODE_PINNED` records which arms are free, because `pin90`'s stored −1544.50 reads HIGHER than
the canonical −1544.615 and is really **−1556.17** once the +11.6698 pin offset is removed; the test
asserts the trap is still live so the comment cannot go stale.

Two live-path defects surfaced only by doing the conversion: `diag_design_gates_at_mode.R`'s τ_ex
profile read `V$N` and **crashed**, and ten call sites wrapped `ccx_path()` around a path that is
already absolute.

**§7b — DESIGN §6 re-measured at `from90` and `pin90`. THREE OF FOUR GATES MOVED.**

| gate | pre-fix | `from90` | `pin90` |
|---|---|---|---|
| 4 AF level / decadal sd / **trend** | 0.434 / 0.019 / **−0.0007** | 0.413 / 0.026 / **+0.0080** | 0.391 / 0.036 / +0.0137 |
| 5 NH→SH bomb lag (obs 1.34) | 0.92 | 0.97 — **FAILS** | 0.97 |
| 7 land / ocean σ | +2.12 / −0.64 | **+2.46** / −0.67 | +3.03 / −0.55 |
| 12 TH 20/50/100 | ✗✗✗ | **✗✓✓** | ✓✓✓ |
| 12b tail ratio | 0.707 | 0.709 | 0.716 |

**Gate 4's decadal AF trend had the WRONG SIGN pre-fix and now has the right one** at the
posterior's own preferred free mode. **Gate 12 passes two of three horizons — the first pass at any
fitted mode** (12.14 / 24.98 / 41.11; TH 20 misses by 0.48 %). **Gate 12b moved 0.002 while 12a moved
from 0-of-3 to 2-of-3**, which is exactly the division of labour it was added for: 12a reads the
calibration, 12b reads the STRUCTURE. Gate 7's ocean half passes and its land half went further out.
Superseded blocks kept in `<details>`, marked not-comparable, rather than deleted.

**Withdrawn:** `diag_joos_irf.R`'s header claim that the model is "INSIDE BOTH" of Joos §4.4.1's
PI/PD ranges is false at every vector on disk (PI 27.4 vs 34–47; PD 43.8 vs 45–62). The ORDERING
passes; the LEVELS do not.

**§7c.1 — the rank-one d¹³C finding tightened 150×, and the COMMON MODE is gone.**
`grad_off_d13c` = **+0.08512 ‰** equals the MLO−SPO level-bias difference **+0.08514 ‰** to
**0.00002 ‰** (was 0.003 pre-fix). The two station biases are now **+0.84 / −0.86 z**, mean
**−0.00042 ‰**, against +1.12 / −0.77 pre-fix: **the residual d¹³C level misfit is now PURELY
ANTISYMMETRIC.** ⇒ `ccx_fit_at_mode`'s standing design recommendation — one shared representation
parameter generating both species' level offsets by mass balance — **is now unmotivated and should
NOT be built**: it existed to absorb a common mode that no longer exists. All 14 streams reproduce
their stored logL; nothing is grossly misfit.

**§7c.2 — `rep_dC` is no longer the model's largest prior flag. THREE SEASONAL AMPLITUDES ARE, and
the fix INVERTED their hemispheric asymmetry.** `rep_dC` 5.566 → **3.378** sd, now only fourth.
Ahead of it: `sst_seas_amp_SH` −4.25 → **−6.32 (worse)**, `seas_T_amp_SH` −3.95 → −4.64,
`sst_seas_amp_NH` **−6.22 → −3.48 (relieved)**. Priced on RATIOS, which do not depend on a prior
width: SH ocean seasonal SST at **21 %** of observed, NH ocean **42 %**, SH land **29 % of its
bracket's LOW end**, NH land **131 % of the HIGH end**. **The fit buys its seasonal cycle by cranking
NH LAND far above any observed amplitude and pushing SH land and both oceans far below.** Two of the
three worst-flagged parameters in the whole fit are SH seasonal amplitudes — independent
corroboration of §7c item 3's *untested* suspicion that the SH residual is the larger and a single SH
land box at an effective latitude is the suspect. Caveat carried: `SST_SEAS_LOGSD` = 0.25 is a
stated JUDGEMENT width (DESIGN 5.2, "no bracket for it exists"), so the ocean pair's z is partly a
statement about that width — the ratio is the robust half. The land pair's width is a measured
bracket, not a judgement.

**FOUND, NOT PATCHED — DESIGN gate 7's two reconstructions disagree, and the whole disagreement is
the run's LAST YEAR.** Land 2015–2024 reads **3.590** (+2.46σ) in `diag_design_gates_at_mode.R`
against **3.525** (+2.33σ) in `diag_fit_at_mode.R`; per year they are identical to 1e-4 for
2015–2023 and differ by **0.65 GtC/yr in 2024**. The run ends at 2024, so neither file has a 2025
state to difference the land stock against — one extrapolates FLAT (`approx(rule = 2)`), the other
LINEARLY. Dropping 2024 gives 3.514 / **+2.31σ**. The verdict (FAIL land) is unchanged, so this is
not result-changing; the fix is a methodological choice — drop the truncated year, or run to 2025 —
and it is **Marcus's, not resolved here.** DESIGN's claim that the two reconstructions "agree to the
reported precision" has been moved into the superseded block.

**NOT DONE (handoff §7c items 3–6, §7d):** the seasonal-partition test itself at ~1.5×, the d¹³C
Suess overshoot re-check, whether `gcb_land_sink` should be decisive, `kz` railing (unchanged at
6332 against a bracket top of 6528), the pump's `alpha13_signed` (b) case, `alpha_as_*`, the Hessian
condition number, and the sampler.

**PRE-EXISTING FAILURE, REPORTED NOT TOUCHED:** `test-fluxes.R:99/100` fail at `5777955` and still
fail — the seasonal ¹⁴C label-turnover assertions (`on$tau_flux` vs `off$tau_flux`, and the >0.2 yr
label shortening). Verified by stashing that they pre-date today's work. Almost certainly the
isotope fix itself acting on exactly the quantity those two lines assert; it belongs in the §7c
assessment, not in a test edit.

## 2026-08-25g — the post-fix refit is RUNNING, 3 arms, pre-registered

`notes/prereg_2026-08-25f_post_isotope_fix_refit.md`, written before launch. Arms: `ref` (free, warm
from the quarantined arm-N mode — becomes the canonical mode), `from90` (free, seeded at the K = 90
ridge cell — **does a second basin exist now?**), `pin90` (`fert_k` pinned at 90 — prices forced
saturation under the corrected objective). `pin60`/`pin120` deliberately NOT re-run: they bracket a
cost curve whose middle point is the one that matters, and the free arm decides whether the curve is
interesting at all.

Warm-start log-posteriors under the NEW objective: ref **−1909.0** (its file says −1859.3, the old
objective — an independent confirmation of the −49.7 frozen cost measured beforehand), from90
−2457.5, pin90 −2445.9.

**A smoke run at reduced settings proved the pipeline end-to-end first**, and inside 402 evaluations
the reference arm had already gained **+306.4** over its warm start and was still gaining — which
is P1's direction, though P1 is settled at the landed mode, not here.

**GPP limbs declared `alpha13_signed` (reason (a), one-way by construction) before launch.** The
guard would otherwise have turned a diverging state — where `npp` goes negative because CO₂ has —
from "finite and rejected" into a hard `-Inf`, quietly shrinking the optimiser's feasible set. That
is how the pre-2026-08-11 substep wall truncated the posterior, and it is not a change this fix was
supposed to make. Parity re-checked at 5.6e-13; `test-seas-isotope.R` still 5/5.

## 2026-08-25f — FIXED: the seasonal NEP flux discriminated on both halves of its cycle

**THE OBJECTIVE HAS CHANGED. Nothing fitted before this entry is comparable across it** — same class
as the 2026-08-22 ice-hemisphere change. Every fitted vector, **including the adopted arm-N mode**,
is quarantined at `calibration/output/quarantine/20260825_seas_isotope_rectification/` with a README.
**There is no canonical mode until a refit runs**, and every diagnostic that resolves one will fail
loudly. That is intended.

**THE FIX.** `R/model.R` and `src/ccx_core.cpp` now emit the seasonal land flux as
`alpha13 = if (seas > 0) alpha_photo else 1`. `seas` is zero-mean by construction, so it is negative
half of every year, and `add_flux` resolves a negative flux by swapping the SOURCE box while still
applying `alpha13` — so autumn respiration out of the leaf pool was discriminated a second time.
Photosynthesis discriminates; respiration does not. Option 1 (bidirectional NEP) was adopted over
option 2 (a modulation of gross photosynthesis) because **the NH leaf pool's CARBON oscillates by
38 % of its own mass peak-to-trough**, so carbon really does flow leaf→atm each autumn; a GPP
modulation never reverses and would need the carbon side changed too. Post-fix the two are
indistinguishable anyway (0.012–0.025 ‰).

**THE GUARD, which is the durable half.** `add_flux()` in both cores now REFUSES a negative flux
carrying `alpha13 != 1`. Reviewed call sites declare `alpha13_signed = TRUE` with a stated reason:
**(a) one-way by construction** — the air-sea gross limbs and the artificial sink, which can only go
negative in a diverging RK4 stage the caller is about to reject, and where a hard stop would break
`ccx_run_fast()`'s NA-retry and `test-stability.R`; **(b) genuinely signed and still OPEN** — the
biological pump.

**AND THE GUARD IMMEDIATELY FOUND A SECOND CASE, NOT FIXED.** `ccx_pump_export()` builds `S[k]` as
the DIVERGENCE of a diffusive flux, so it is negative in **2 of 10 layers** at the adopted mode,
carrying **0.4 % of the field's gross magnitude** (0.039 of 9.58 GtC/yr). On those layers the pump
sends carbon UP to the mixed layer and depletes it by a further ε_org, which is not what "organic
matter sinks and remineralises" means. **Grandfathered bit-exactly and flagged** — unlike the
seasonal case it is not obvious what the reverse limb should be, and `PUMP_EPS13_ORG` is itself
"provisional, recollected, NEEDS a cited source". Marcus's call.

**TESTS.** New `tests/testthat/test-seas-isotope.R` — **the first test in the repo that exercises the
seasonal isotope path with `seas_drivers = 1`**; `test-conservation.R:82` and `test-parity.R:72/151`
all set it to 0, which is why nothing caught this. Its assertion is neither conservation (blind —
`add_flux` is antisymmetric, so total ¹³C is conserved for any α) nor parity (blind — both cores
shared the rule) but **that a zero-mean exchange must not RECTIFY**. Full suite: back to the two
pre-existing by-design `test-fluxes.R:99/100` failures, with unchanged numbers (they are carbon
quantities and the fix moves no carbon). R↔C++ parity 5.6e-13 at the pre-fix mode.

**WHAT IS OWED:** a refit (~9 h), the ridge arms with it, and a re-measurement of every `DESIGN.md`
§6 gate. Under the patch at pre-fix parameters the pin90-vs-reference gap goes −90.07 → −25.28 and
what remains is `gcb_land_sink`, a carbon objection — **that is not a result**, both arms move.

## 2026-08-25e — the veto is a MEAN SHIFT on white residuals, not a stream weight

`notes/collect_2026-08-25c_the_veto_is_not_a_weighting.md`. Two report-only files:
`calibration/diag_landed_gap_streams.R`, `calibration/diag_stream_neff.R`.

**THE 93 % WAS A FROZEN-VECTOR NUMBER AND IT DOES NOT SURVIVE THE LANDING.** Handoff 08-25b §4
built the inherited objective-weighting question on `co2_level_MLO + co2_level_SPO` carrying 93 %
of pin90's 86.7 log-unit penalty. Measured at the LANDED modes the pair carries **−0.1 %** (MLO
+2.49, SPO −2.40, net +0.09). The gap is carried by `d13c_seasonal_SPO` **−38.16** (44 %),
`d13c_seasonal_MLO` **−24.22** (28 %) and `gcb_land_sink` **−24.00** (28 %) — 100 % between them.
§7 of that same handoff had already written the rule ("never read a frozen conditional optimum as
a prediction of where a refit lands"); §4 did not apply it to itself.

**THE EFFECTIVE-n DIAGNOSTIC WAS RUN ANYWAY, ON ALL 15 ANNUAL STREAMS, AND IT INVERTS.** The
station levels are genuinely weakly informed — Geyer n_eff **12.6 of 66** (MLO, ρ₁ +0.79) and
**13.2 of 59** (SPO) — and they are exactly the streams that do not carry the gap. The three
that do have n_eff ≈ N: ρ₁ = −0.20 / −0.01 / +0.16, all inside the white-noise band 2/√N.

**AND THE PENALTY IS PURE BIAS**, which an n_eff correction must not forgive — `R/likelihood.R`'s
own `sigma_d13c` block ("the d13C residual is BIAS, not scatter … a robustness valve venting the
signal"). Splitting Δ into mean vs scatter: −38.12 / −24.96 / −24.48 is bias, −0.04 / +0.73 /
+0.48 is scatter. Both corrections therefore miss: pin90 goes −96.91 → **−82.75** (scalar n_eff/N)
or **−82.08** (AR(1) GLS). **A 15 % haircut, not two orders of magnitude.**

**WHAT THE BIAS IS.** The seasonal δ¹³C-per-ppm partition ratio (semi-amplitude √(a²+b²), same
estimator both sides) goes **2.45× → 2.61× → 2.68× → 2.84×** at SPO across ref/pin120/pin90/pin60
while the CO₂ amplitude does not move. Saturation buys the AF trend by making the seasonal flux
MORE photosynthetic, deepening a misfit that is already 2.45× at the reference mode.

⇒ `diag_fert_ridge_streams.R` offered (a) physical conflict / (b) mis-weighted stream / (c) frozen
artifact. The refit killed (c); this kills (b). **What is left is (a)** — the model cannot have the
airborne-fraction trend and the seasonal isotopic partition at once, and that is reportable as a
real internal contradiction rather than as a weighting choice.

**Two gates and two of my own bugs, both found by the gates.** (1) The `h_ml` band must be restored
to `[85, 120]` before any of this reproduces: under the default `[30, 200]` every arm's logpost is
off by ~1.1 in the same direction — right deltas, wrong levels — and `u_mode` does not decode at all
(max |u − u(par_mode)| = 1.7). (2) A first draft detected the seasonal streams' stacked (a, b)
vectors by `anyDuplicated(year)`; the ICE CORE has 255 rows over 136 years, took that branch, and
was silently halved twice. Stream kind is now DECLARED. Also: pooled ρ₁ was being summed instead of
averaged, and the gap-splitter split on the residual index (contiguous by construction) rather than
on the year — the same defect design note 1 records the retired AR(1) having. All 15 residual
reconstructions are gated against `by_stream` to 1e-6, and the 15 gated streams account for −89.70
of pin90's −90.07 likelihood delta.

## 2026-08-25d — the refit falsifies its own headline: only gate 4 survives

`notes/collect_2026-08-25_fert_ridge_refit.md`, against the pre-registration written before launch.

**P1 FALSIFIED.** `ridge_free_from90`, seeded at the `fert_k` = 90 cell with a warm start of −3412,
climbed back to **`fert_k` 554.98** against the adopted mode's 554.54 — 0.08 % apart, logpost
identical to two decimals, `beta_max` and `rep_dC` restored exactly. **No second basin.** The
pre-registration's stated consequence applies and is applied.

**P2 FALSIFIED, and the mechanism is visible.** `rep_dC` landed 4.967 / 4.733 / 4.138 at
K = 120/90/60 against the frozen scan's 1.370 / 0.150 / −1.750. **Pinning one coordinate of a
ρ = +0.997 pair does not hold the pair:** each arm was seeded *on* the ridge at enh(420) = 0.2074
and the fit moved *off* it — 0.2614 / 0.2873 / 0.3387 — raising present-day fertilisation 26–63 %,
restoring the CO₂-level fit, and taking `rep_dC` back with it.

**P3 holds and no longer means what it was meant to.** The refit recovers 15–19× more than the
frozen estimate (pin120 −47.5 vs −912.9) — a measure of how efficiently the model routes around a
pin, not of the cell's viability.

**P4 holds, and is the one real survivor.** At the landed pin120 mode: AF trend −0.0007 → **+0.0107**
(target +0.0148), decadal sd 0.019 → **0.030**, r −0.06 → **+0.48**, with 19 parameters free to undo
it and none doing so. **Fertilisation saturation genuinely produces airborne-fraction
time-dependence.** But **gate 7 reverses** — land **+2.62 σ**, worse than the reference's +2.12,
where the frozen scan predicted +1.26 — and the AF level degrades 0.434 → 0.405.

**P5 not supported:** `q10` 1.091 → 1.099–1.101.

**RETRACTED: 2026-08-25c's "four problems, one direction".** One responds; three do not. The price
of gate 4's trend is **47 log-units and +0.5 σ of land sink**, and the free arm says the posterior
declines it. [[sens_scan_achievable]]: the scan ranked the work correctly and was wrong about
everything it inferred beyond the ranking.

**Still owed:** `ridge_pin60` and `ridge_pin90` are in cycle 1 (interim numbers above); gate 12 and
12b at the landed modes are unmeasured — **do not quote the frozen figures for them.**


## 2026-08-25c — gate 4 is the fertilisation saturation SHAPE, and it zeroes `rep_dC`

Marcus framed gate 4 mechanically: AF rises when emissions grow fast or when sinks saturate;
emissions are an input, so the model's freedom is in how its sinks change over time. He named
ocean warming/stratification, surface CO₂ saturation, fertilisation saturation, and deforestation.

**Step 1 was a code inventory, not a scan.** Five of the six mechanisms already exist. **Ocean
stratification is genuinely absent** — `R/model.R:846`, the interior flux is `p$kz * gradient` with
`kz` a constant and `w_up` = 0.

**TRIED AND ABANDONED — building the missing mechanism.** `kz` moves the AF *level* hard (0.490 at
2000 → 0.415 at 9000) and its *trend* by **±0.0002 across that entire range**. Closing the
+0.0156/decade gap through the level needs `kz` to fall by more than its own value. The lever
Marcus named first, and the only one missing, **cannot deliver the trend.**

**The answer is the (`beta_max`, `fert_k`) ridge, travelled ALONG at fixed present-day NPP
enhancement** — the one direction the historical CO₂ integral cannot identify:

| `fert_k` | FACE | AF trend | dec sd | land σ | IRF 20/50/100 | Δ logL frozen → after `rep_dC` | `rep_dC` |
|---|---|---|---|---|---|---|---|
| 554.5 mode | 13.6 % | −0.0007 | 0.019 | +2.12 | 11.69/23.81/39.06 | 0 | **5.566** |
| 180 | 8.2 % | +0.0063 | 0.023 | +1.54 | 12.35/25.66/42.63 | −1138 → −370 | 2.87 |
| **90** | ~5 % | +0.010 | 0.031 | ~+1.0 | all inside | −4674 → **−1550** | **0.150** |
| 60 | 3.8 % | **+0.0163** | 0.040 | **+0.74** | 13.15/28.08/47.64 | −8657 → −2914 | −1.75 |
| target | 0–23 % | +0.0148 | 0.048 | 0 | 12.2/24.0/39.5 | — | 0 |

**Gates 4, 7 and 12 move together, and so does the blocker.** Gate 12 passes at all three horizons
for the first time at any fitted vector; gate 7's land sink comes inside 1 σ; and **`rep_dC` falls
monotonically through zero at `fert_k` ≈ 90** — the 5.6 σ flag that has driven the whole 08-21 →
08-25 arc is a fertilisation-shape artefact.

**93 % of the cost is the two CO₂ station LEVEL streams**; **no sink stream objects at any cell**
(`gcb_land_sink` −0.7, `gcb_ocean_sink` −1.0). Freeing `rep_dC` — a 1-D conditional optimum, exact
because it enters only the station terms additively — returns a **flat ~67 % at every cell**, the
signature of an offset absorbing a level and not a shape. The residue is then `d13c_level_MLO`
(−578.8 at K=90), the CO₂ shape, and `co2_icecore`; `rep_dC` is shared between the CO₂ and δ¹³C
station terms, so serving one costs the other.

**TRIED AND CORRECTED — the gate-7 construction.** The first draft computed sinks from the monthly
flux trace. Switched to `dg_gate7`'s stocks-plus-E_LUC construction: ~50× faster, and a second
construction risked disagreeing with the gate being scored against.

**This is a refit proposal, not a result.** Every Δ logL is a frozen-vector upper bound (19
coordinates held, including `luc_scale` 0.898 and `q10` 1.091 — the plausible absorbers), and every
`rep_dC` landing point is conditional.


## 2026-08-25b — G1: the century drift does not survive its own error bar; the seam is the ocean sink

`calibration/diag_gcb_seam_1959.R`. Five data-only tests, no refit, as §6 of the 08-25 handoff
specified. Note: `notes/diag_2026-08-25_g1_gcb_seam.md`.

**The successor programme nominated in §5 — GCB's `imbalance` as the home for `rep_dC` — shrinks to
a caveat.** Four of the five things it rested on fail their own bar or their own decomposition.

| §5 | G1 |
|---|---|
| 37.8 ppm, 56 % pre-1959 | reproduced exactly; identity closes to 1.4e-10 |
| "the century drift" | **1850–1939 nets 16.6 GtC and changes sign twice**; the 1940s+50s carry **63 %** in 17 % of the years |
| 44.7 GtC is a number to explain | **0.43–1.5 σ** once errors are correlated as a smoothed reconstruction's must be |
| the seam is a candidate generator | **confirmed and localised — the OCEAN SINK, not growth** |
| `rep_dC` might live here | growth **exonerated** (6 %, 1.14 σ) and the test is **circular** |

**The bar came first.** The imbalance's 1 σ is now derived from `R/likelihood.R`'s own sigmas —
`sqrt(0.70² + 0.40² + 0.50² + 5 %·F̄)` = **0.949 GtC/yr**, a *floor* — instead of a hand-set 0.7,
and the 109-yr cumulative's bar is scanned over the error correlation length: 9.9 GtC at ρ = 0
(4.5 σ) but **29–104 GtC at ρ ≥ 0.8 (1.5 σ down to 0.43 σ)**. ρ = 0 is the wrong row: GCB's own
header says the pre-1959 growth and ocean sink carry no year-to-year variability, i.e. their errors
are the correlated case. [[curvature_needs_an_error_bar]], fourth firing.

**The variance seam and the level seam are different objects.** Smoothness fingerprint (post/pre sd
of second differences) is 27.9× for `atm_growth` and 42.4× for `ocean_sink`, ≤4.4× everywhere else
— GCB's header, measured. But only `ocean_sink` also has a resolved **level** step: **+0.232 GtC/yr
at 3.18 σ** (w = 10), monotone across windows to **+0.279 at 5.30 σ** (w = 20). `atm_growth`'s step
is **0.54 σ — not resolved**.

**Newey-West was anti-conservative by up to 4.9× here** (w = 8–20 residuals, lag truncation 1–2)
and is not what any z uses. The bar used is a matched block bootstrap of each side's own local
residuals through the same estimator, which preserves the seam's heteroscedasticity (`ocean_sink`
residual sd about a local quadratic: pre **0.0093**, post **0.1015**).

**TRIED AND ABANDONED — a null built around the wrong trend.** The first MC resampled residuals
about a *global* linear fit, so for `atm_growth` the "noise" was the global line's curvature
misspecification; it declared the analytic bar anti-conservative by 8× and would have made every
step unresolvable. A null distribution must be built around a trend model the data could plausibly
have come from. Recorded, not deleted.

**TRIED AND NOT IDENTIFIED — the ocean-sink backcast.** Held constant over 109 yr the step prices
at **+25.3 GtC = 57 %** of the pre-seam cumulative, an upper bound (a diagnostic model at lower CO₂
*should* have a smaller sink). The replacement — `ocean_sink ~ (CO₂ − 276.88)` fitted post-seam and
extrapolated back — gives **15 %** on 1959–1980 and **116 %** on 1959–2024, **7.6× apart**, because
the relation is curved and the pre-seam era is outside the fitted range. No window is chosen; the
seam's share is bounded, not measured.

**Growth is exonerated, and the test is circular.** GCB's `atm_growth` cumulated from an 1850 ice
anchor tracks the **172 raw Law Dome samples the likelihood scores** at **RMS z = 0.46**. The level
residual *is* the running integral of the growth error, so its drift needs no bandwidth choice
(preferred to a differentiated spline per [[smoother_wider_than_feature]]): **−1.19 ± 1.04 ppm =
1.14 σ = 2.5 GtC = 6 %** of the cumulative, with n_eff from the 4.5–7.0 yr air-age spectral width
([[ccx_d13c_neff]]) rather than the raw sample count. **And GCB's pre-1959 growth is Joos & Spahni
2008, a reconstruction of that same record** — so it and our ice term are *one object*, agreement is
by construction, and the imbalance could only ever have been a statement about emissions and sinks.
§5's item 1 ("the model's sinks responding to a CO₂ level that is itself partly the imbalance's
doing") has the causality backwards: CO₂ level is an **input** to the imbalance.

**CONSEQUENCE.** G2 (price the transfer) and G3 (isotopic attribution) were scoped to explain a
37.8 ppm century drift that does not survive T0 and T5 — **premature as written**. G4 (a refit) is
unjustified by this line. What survives is narrow: GCB's pre-1959 `ocean_sink` carries a resolved
+0.23–0.28 GtC/yr discontinuity at its own methodology seam — a caveat on any future use of the
pre-1959 budget, not a programme. **Nothing here is a home for `rep_dC`.**


## 2026-08-24c — `ocean_deep` is not needed: the `luc` arm already IS the discriminating cell

08-24b closed the plateau arc but recorded a **residual confound**: `foss` (Δ`rep_dC` **−6.02 σ**)
and `ocean` (**+0.18 σ**) differ in **two** ways — persistence AND isotopic signature — so the pair
cannot say which bought the relief. §8 proposed building **`ocean_deep`** to separate them, and
blocked on choosing its vertical profile.

**IT DOES NOT HAVE TO BE BUILT.** The `luc` arm already sits in that cell, is implemented, and its
numbers were on disk from 08-24a (`output/sink_three_arms/three_arms_N_rate2.5.rds`):

| arm | fraction of window-end CO₂ effect left at 1960 / 2024 | Δ¹⁴C excursion 1941–50 NH |
|---|---|---|
| `foss` 2.5 | 0.736 / **0.432** | **+9.72 ‰** |
| **`luc` 2.5** | 0.745 / **0.501** | **+0.170 ‰** |
| `ocean` 2.5 | 0.181 / **0.027** | −0.122 ‰ |

`luc` carries **`foss`'s CO₂ trajectory** (window-end −6.531 vs −6.512 ppm, matched to **0.3 %**,
and *more* persistent at 2024) with **`ocean`-scale isotopes** (both ~1–2 % of `foss`'s excursion).
That is verbatim the specification §8 wrote for `ocean_deep` — *"`foss`'s CO₂ trajectory and
`ocean`'s isotopes"* — **with no vertical profile to choose.** [[bracket_needs_no_new_run]] firing
a second time on this arc: **look for a recombination among existing arms before building arm N+1.**

**THE REFUSAL BECAME A CORRECT PATH.** `ccx_make_logpost()` and `ccx_scaled_forcing()` applied
`luc_scale` as a column multiply and **errored** on the `luc` arm, because `ccx_build_forcing()`
applies the arm *after* `luc_scale`, making the columns **affine** (`s·L − S`) not linear. The
refusal's stated reason was that *"the correction has a right answer that depends on what the
caller meant"* — but the builder has already made and documented that choice, so the answer is not
a guess. `.ccx_make_luc_scaler()` now holds the arm-off base and the perturbation and composes
`s·L + d`: **exact, constant-time, and bit-identical to the old path whenever the arm is off.** The
refusal is not deleted — it still fires for a caller that cannot supply the scenario/years needed
to rebuild the arm-off base, the only case where the composition genuinely cannot be formed. A base
built with the arm OFF is **refused** rather than silently treated as the arm.

**GATED AND MUTATION-TESTED IN BOTH DIRECTIONS** (`test-luc-scale.R`, +3 tests): the composition
must equal `ccx_build_forcing()` to 1e-12, the refused multiply must **FAIL** the same assertion,
and it must fail by a **material** amount (10 % of the perturbation at the mode's `luc_scale`), or
the gate is a tautology.

**ONE REFIT LAUNCHED**, predictions **pre-registered before launch**
(`notes/prereg_2026-08-24c_luc_arm_persistence_vs_isotopes.md`). Arm N, `CCX_SINK_MODE=luc`,
rate 2.5, `luc_scale` pinned 0.898400, `RESTARTS=8 CYCLES=2`, h_ml [85, 120] — **every setting
copied from the pinned `foss` run**, so the two are like-for-like down to the restart count.
Headline P1: **Δ`rep_dC` ≤ −5.0 σ** (falsifier |Δ| < 1.0 σ ⇒ the isotopic signature, not
persistence, is the driver, and 08-24b §3's mechanism argument is wrong).

**PROVENANCE GATE PASSED EXACTLY.** The warm-start logpost was predicted at **−2691.2** from the
at-mode `luc` total (−1859.32 − 839.879 + ~8.0 for the pin's prior) and measured at **−2691.2** —
so the new affine path and the 08-24a diagnostic's independent `ccx_build_forcing()` route agree to
the decimal, and the run is carrying the arm it says it is rather than the seeded reference
(08-24b §6's seed-copy trap). Output `calibration/output/luc_arm_pinluc/` — **SCRATCH, never the
shipped mode.**

## 2026-08-24b — Six refits: the plateau decade is NOT the source of `rep_dC`

Marcus: *"I was worried that fitting to the plateau was making the pre- and post-plateau model
worse. It seems like some combination of reducing emissions or artificially injected atmospheric
carbon into the oceans should be able to take the tension off of that decade."*

**That is a LEVERAGE question and only a re-optimisation answers it.** The 08-24a work was at the
fixed mode and could not. Six refits, all predictions pre-registered before launch
(`notes/prereg_2026-08-24b_ocean_probe_rate_scan.md`).

| arm | logpost | `rep_dC` | Δσ | `luc_scale` Δσ | ridge Δσ |
|---|---|---|---|---|---|
| 0 (matched zero) | −1859.32 | 5.5658 | — | — | — |
| 2.5 | −1860.38 | 5.6042 | +0.16 | +0.52 | −0.14 / −0.19 |
| 9.434 | −1874.34 | 5.6447 | **+0.32** | +1.90 | −0.54 / −0.72 |
| 15 | −1895.97 | 5.6174 | +0.21 | **+2.94** | −0.84 / −1.12 |
| 9.434 **pin** | −1868.5 | 5.6086 | +0.18 | pinned | +1.31 / +1.13 |
| 15 **pin** | −1893.4 | 5.5252 | −0.17 | pinned | **+2.08 / +1.75** |

Rate 0 reproduces the shipped mode (gain **0.0000**), so the scan's zero is the adopted mode
rather than a re-derivation. Pinned logposts are NOT comparable to free ones.

**THE ANSWER. `rep_dC` moves |≤0.32| σ in every live arm, with an inconsistent sign.** The `foss`
probe at the **same window-end CO₂ relief** and the same lever pinned moved it **−6.02 σ**
(5.566 → 4.102). ⇒ **the relief `foss` appeared to buy was payment for its PERMANENT LEVEL SHIFT**
(42 % of its 1950 CO₂ effect survives to 2024, against `ocean`'s 3.3 %), **not for explaining the
plateau.** Marcus's worry is redirected, not confirmed: the plateau decade is not what distorts the
pre- and post-plateau fit — the century-scale drift is, and that was already traced to GCB's own
budget imbalance (r = 0.771).

**And `co2_icecore` is the sharpest form of it: 0.00 → +0.87 → −5.53 → −19.16.** The model already
sits **1.67 ppm BELOW** the ice in 1942–50, so a temporally local probe **overshoots** the window
it is meant to relieve. **There is no rate at which relieving the plateau improves the plateau
term.**

**ESCAPE ROUTES, in order.** `luc_scale` free (+2.94 σ); with it pinned, the (`beta_max`, `fert_k`)
ridge takes over (+2.08 / +1.75 σ) — the same second route the pinned `foss` run used
(0.93→2.70, 423→1738). `sigma_d14c` stays within 0.15 σ throughout, against `foss`'s **+3.85 σ**,
so no Suess artefact contaminates the read.

**P3 WAS FALSIFIED AND THE LESSON GENERALISES.** I predicted `luc_scale` < 1 σ because the probe's
time-shape (3.3 % left by 2024) is nearly orthogonal to a `luc_scale` rescale's (196 % by 2024),
and claimed the escape route **closed by construction**. It moved **+2.94 σ**, past the 2 σ
falsifier I had named. **A fit does not need to MATCH a perturbation's shape to route around it —
it only needs to trade enough likelihood elsewhere.** Orthogonality bounds the *exchange rate*
(0.34× `foss` at matched CO₂ effect), never the possibility. Predict the exchange rate, not a
yes/no, and pin the lever anyway when the conclusion depends on it.

**FOUR OF MY OWN THRESHOLDS/LABELS WERE WRONG**, all caught by reading output rather than by a
gate, and one fired **against a correct result**:

- **The pin gate.** Hand-picked `1e-6`; it errored with *"the pin did NOT bind"* when the pin had
  bound perfectly. `ARM_PIN_SD` is **1e-4 in LOG space**, so `luc_scale` may move ~9e-5 absolute
  and the converged arm sat 1.04e-6 away = **0.01 prior sd**. Now derived as 10 × the pin's own
  prior sd, still rejecting a free arm by 70×.
- **`paste0(character(0), "P")` is `"P"` in R**, not `character(0)` — zero-length recycling
  injected a phantom column and killed the run.
- **"ratio at matched CO₂ effect"** was computed from the *unmatched* largest arm.
- **Monotonicity** was tested on differences that dropped the reference arm's implicit 0.00 — the
  point the rise-then-fall turns on — and printed *"monotone? YES"* for 0.00 → +0.87 → −5.53.
- And the pre-registration quoted **−21 σ** where the measured value is **−6.02 σ**; corrected in
  place with a visible note, since a wrong number in a pre-registration is the last thing that
  should be quietly repaired.

**A SEED-COPY TRAP, worth remembering for any warm-started scan.** Every arm directory was seeded
with a copy of the adopted mode so the warm-start path runs as production does — so
`mode_fit_pumpN.rds` **exists in an arm that has not started**, and it is the UNPERTURBED
reference. Keying completion on it reported the still-running rate-15 arm as finished with every
delta exactly **+0.00**. Completion now keys on `pump_arms_comparison.rds` plus a bit-identity
gate. All-exactly-zero is a code path, never nature.

**RESIDUAL CONFOUND, recorded not buried.** `ocean` differs from `foss` in **two** ways —
persistence AND isotopic signature — so the pair does not isolate which drives the `rep_dC`
difference. The mechanism argument favours persistence (`rep_dC` is a CO₂ *level* offset; only
persistence touches the level after 1960) but it is an argument, not a measurement. **`ocean_deep`
would discriminate directly** — `foss`'s CO₂ trajectory, `ocean`'s isotopes. Its vertical profile
is a mechanism choice and remains Marcus's call, alongside 23c's `beta_max`/`fert_k` question.

## 2026-08-24 — The ocean-box arm: the isotopes clear it and the carbon budget kills it

Handoff `2026-08-23c` §4 built, gated, and §4e run. **All three arms measured at the adopted mode
in 8 seconds — no refit was needed to answer any of it**, and that is the first thing worth
recording: three refits would have cost ~30 h and could not have made isotopically
indistinguishable arms distinguishable.

**THE BUILD.** `CCX_SINK_MODE` selects the isotopic signature at a fixed magnitude —
`foss` (negative fossil emission, −28 ‰, ¹⁴C-FREE; the incumbent), `luc` (the land-use flux is
reduced so the carbon stays in the WOOD pool), `ocean` (atmosphere → mixed layer through
`add_flux` at the model's own `alpha_as_down`, ¹⁴C unfractionated at the source ratio). The ocean
arm rides a new LAST forcing column `sink_ocean`, split in the deriv on the **ocean-area** shares
`aux$asx` — not the fossil share — and mirrored in `src/ccx_core.cpp` (`N_FORCING` 14 → 15).
`ccx_build_forcing()` gained `sink_rate`/`sink_mode` **arguments** so one process can build all
three arms; the env constants remain the defaults.

**FOUR MECHANICAL GATES, PRE-REGISTERED AND PASSING** (`test-artificial-sink.R`, +30 tests,
1007 pass against 977): rate 0 bit-inert in every mode; the ocean gains exactly what the
atmosphere loses, split on ocean area, isotopes at the source ratio; R↔C++ parity with the flux
on; and conservation — **asserted as a DIFFERENCE, not a total.** Asserting closed-system ¹⁴C
conservation failed at 4.2e-4, which is λ: ¹⁴C decays, so the *total* must not be gated (this is
why `test-conservation.R` checks C and ¹³C only). What has to be conservative is the sink's own
contribution, i.e. on-minus-off, and that closes to 1e-12 in all three tracers.

**P1 — THE ¹⁴C NULL HOLDS, BY 58–80×.** Pre-bomb Δ¹⁴C excursion against the sink-off arm:
`ocean` **0.122–0.156 ‰** against `foss` **7.12–11.57 ‰**. Worst-cell ratio **0.017** against a
pre-registered ≤0.20 and an absolute pre-registration of <1 ‰. **P2** the same in δ¹³C, worst
ratio **0.070**. On the likelihood at the mode: `foss` pays **−46.8** on `d14c_NH` and −13.4 on
`d14c_SH`; `ocean` pays **−0.20 / +0.47**. The ¹⁴C rejection of the reduced-emissions hypothesis
reproduces at the mode, un-refitted, and the ocean routing is isotopically invisible — exactly as
the mechanism predicts, since removing carbon at the atmosphere's own ¹⁴C/C leaves the *ratio*
alone.

**P3 — MISSED AT THE WINDOW END, HELD AFTER, AND THE REASON MATTERS.** Pre-registered
`ocean/foss` CO₂ ratio 0.08–0.25; measured **0.271** at 1949.5, **0.066** at 1960.5, **0.017** at
2024.5. The band was derived from the *equilibrium* buffered-capacity partition
(0.2503/(0.2503+2.1240) = 10.5 %) and applied to an epoch where the mixed layer has not yet given
the carbon back and the sink is still running. Direction right, endpoint wrong; recorded rather
than re-baselined.

**THE RESULT: A MIXED-LAYER SINK CANNOT HOLD CARBON.** Of 18.75 GtC injected by the window end,
the interior holds **3.02** and the mixed layer **1.38**; by 1960 the interior holds **1.47** and
by 2024 **0.55**. Atmospheric drawdown **1.76 ppm** at the window end against `foss`'s 6.51, and
**0.32 ppm** by 1960 against 4.79. Bisected on the model, matching the `foss` arm's CO₂ effect
would need **9.4 GtC/yr** at the window end, **42.7** at 1960 and **294** at 2024 — against a
literature sizing of 2–3 GtC/yr and a present-day *total* global ocean sink of ~3 GtC/yr.

**⇒ THE TWO ARMS BRACKET EVERY OCEAN ROUTING, AND NO FOURTH RUN IS NEEDED TO SEE IT.** An ocean
sink that ventilated its carbon instantly would have the **`foss` arm's CO₂ trajectory** (same
removal, never returned) and the **`ocean` arm's isotopes** (removal at the atmosphere's own
ratio, wherever it ends up). So the surviving hypothesis is not "an ocean sink" but
**"an ocean sink whose carbon is exported below the mixed layer as fast as it is taken up"** — and
the destination profile for such an arm is a mechanism choice, so it is **flagged for Marcus, not
chosen here**.

**The `luc` arm is nearly a relabelling of `foss` on CO₂** (−6.53 vs −6.51 ppm at the window end)
and intermediate on ¹⁴C (`d14c_NH` −7.8 against `foss`'s −46.8), as the signature predicts. It
pays **−840** at the mode against `foss`'s −796 and `ocean`'s **−2.00**; the ocean arm is
essentially free *because it does almost nothing*.

**ONE TRAP FOUND AND GATED.** `ccx_scaled_forcing()` and `ccx_make_logpost()` apply `luc_scale` as
a **column multiply** on an already-built base, which is exact only because the LUC columns are
LINEAR in the annual series. The `luc` arm makes them **affine**, so the multiply would have
rescaled the 2.5 GtC/yr perturbation to 2.5 × 0.8984 and the arms would have stopped being
magnitude-matched — a 10 % error in the one quantity the comparison holds fixed.
`.ccx_assert_luc_arm_safe()` now **errors** in both paths rather than guessing, which is the same
lesson as the eight `luc_scale`-squared sites.

**Two of my own reporting bugs, both caught by the output rather than by a gate:** the pre-bomb
residual table indexed `obs$d14$NH`, which does not exist (`ccx_prepare_obs()` returns
`d14_nh`/`d14_sh`) and printed NaN in every cell; and the per-stream ranking indexed `ord` by
POSITION, printing row 1 twice and TOTAL never. Both fixed; the numbers above are from the
corrected run.

**NOT DONE, DELIBERATELY:** no refit. Nothing in §4e needed one, and the ocean arm costs 2.00
log-units at the mode — there is no misfit for a refit to relieve. **Open for Marcus** (carried
forward from 23c): whether to pin `beta_max`/`fert_k`; and now also whether to build the
`ocean_deep` arm and on what vertical profile.

## 2026-08-23f — The artificial sink: the model routes around it via `luc_scale`

Sink-on refit (2.5 GtC/yr over 1942–49, arm N, warm) converged at **−1894.26** against sink-off
**−1859.32**. `calibration/output/pump_arms_SINK25/` (SCRATCH — never the shipped mode).

**`rep_dC` DID NOT COME DOWN.** The 1-D scan — every other parameter frozen — predicted **2.21**
at this rate. The full refit gives **5.126**, still 5.1 σ. **The reason is the largest move in the
fit: `luc_scale` 0.8984 → 1.0852, +5.52 posterior sd, crossing 1.0, which adds 54 GtC of land-use
emissions over the record against the sink's 20 GtC removal.** The model put the carbon back
rather than relaxing.

**⇒ THE SINK AND `luc_scale` ARE DEGENERATE, and the experiment as built cannot test the
hypothesis.** A prescribed removal in one window is absorbed by a global emissions rescale. This
does **not** refute Marcus's concern that the fit is bent toward a mid-century the field cannot
explain — it says the instrument does not isolate it. **The test that does: pin `luc_scale` at the
sink-off value and re-run (one warm cycle).**

**On the readable streams the sink is net POSITIVE:** CO₂ **+15.8** (`co2_icecore` **+34.4**,
stations −20.3). Isotopes −47.8 and contaminated — and `sigma_d14c` inflates **+3.85 sd**
(6.13 → 8.96), the ¹⁴C error scale swelling to absorb the fossil-signature artefact exactly as
predicted. So the −38.2 total is smaller than the contamination it contains and cannot be read as
a verdict.

**A units error caught before it was quoted:** the first comparison divided *natural*-scale
parameter differences by `sd_unc`, which is the posterior sd in the **unconstrained** coordinate —
producing "+2202 sd" for `k_w`. Both sides must be in the same coordinate; redone, the largest
move is `luc_scale` at +5.52 sd and the RMS is 1.57.

## 2026-08-23e — Model-vs-obs figures, and the mid-century correction: measured, and the premise does not hold

Marcus asked for graphs of model vs observations, and whether an artificial correction for the
mid-century alone would let the rest of the model solve better. New
`calibration/fig_model_vs_obs.R` (~30 s → `calibration/output/figures/`, 3 PNGs) and an OFF-by-
default `LIK_ICE_DISCREPANCY_*` window in `R/likelihood.R`.

**THE FIGURES SHOW ONE THING THE APP CANNOT.** Both the raw model BOX and the STATION prediction
(`box − rep_dC`) are drawn and labelled, because `plot_keeling()` draws only the box and the
calibrated model therefore sits ~5.6 ppm above Mauna Loa there by construction. Panel B is the
result: **post-1958 the ICE residual is +4.8 ppm while the STATION residual is ~0** — and Test 1
showed those two observing systems read the same air to −0.31 ± 0.15 ppm. **`rep_dC` is hiding a
model level bias for one of them.** Two plotting bugs found and fixed in the making: differencing
the monthly series at integer years aliased the SH seasonal cycle into the "growth rate" (±0.3
ppm/yr, comparable to the plateau signal itself), and `approx(rule = 2)` manufactured pre-1750
"residuals" that were really the flat extrapolation of the model's 1750 value.

**THE ANSWER ON THE CORRECTION IS NO, AND FOR THREE INDEPENDENT REASONS.** The window was built
first and measured before being used.

1. **The plateau is the SECOND-BEST-fitting era, not the worst.** Per-era ice fit:
   1900–1935 mean residual **−4.08**, logL/row −2.90; **1935–1960 −1.21, −2.58**; 1960–1997
   **+4.83, −3.07**. The plateau window is where the model's ~8.9 ppm swing **crosses zero**.
   In-window mean |residual| **2.22 ppm against 3.14 out**. Inflating its σ would delete the
   best-fitting quarter, leave both bad wings, and give the swing *more* freedom to steepen.
2. **The likelihood is internally inconsistent about the offset, and repairing it does not help.**
   `rep_dC` = 5.57 ppm is applied to MLO/SPO and **zero** to Law Dome — yet Test 1 says the two
   read the same air to 0.31 ppm. Applying it consistently repairs 1960–97 (**+4.83 → −0.74**)
   and wrecks everything earlier (1750–1850 **−0.93 → −6.49**), for **−263.0 log-units**.
3. **A constant cannot change a difference.** Under that repair the swing is **+8.91 ppm before
   and +8.91 ppm after — exactly unchanged.** The defect is a **shape** error; no offset scheme,
   at any window, reaches it.

**WHAT WOULD BE DEFENSIBLE, and it is not on the observations.** The swing tracks GCB's own
published `imbalance` at r = 0.771, and that imbalance is **+1.30 (1940s) / +1.62 GtC/yr (1950s)**
— GCB cannot close its own budget in the same decades. So the uncertainty belongs on the
**emissions input**, not on the ice observations: a σ-inflation on the emissions-driven CO₂ across
the swing era, externally justified by GCB's own numbers, adding **no parameter**. That is
distinct from the §12c LUC time-profile programme the 2026-08-22 panel withdrew — that one *fitted
a shape and claimed a mechanism*; this one only *widens*, and cannot absorb signal into a
discovery.

The `LIK_ICE_DISCREPANCY_*` switch is kept (OFF, default inert — `co2_icecore` reproduces
−690.86) with the per-era table written into its own comment, so the next person to reach for the
mid-century window meets the measurement first. 977/979 tests pass; no objective change.

## 2026-08-23d — The 12.7 σ validated and CORRECTED to ~5 σ. The conclusion survives; the number does not.

Marcus supplied the Bastos PDF, which quotes Francey et al. (1995) that Law Dome δ¹³C scatter can
make terrestrial/oceanic partitioning spurious, and records Trudinger et al. (2002a) finding the
terrestrial explanation's δ¹³C peak inconsistent with measurements **"although the differences are
not large compared to the measurement uncertainties"**. That was in direct tension with the
2026-08-22 session's headline. Validated, and **the tension was real: the error bar was too small.**

**THE DEFECT.** `diag_d13c_midcentury.R` computed `se <- sd(resid) / sqrt(n)` — every ice sample
treated as an independent draw of the atmosphere. **They are not.** Bastos §2.1 gives Law Dome's
air-age spectral width as **4.5 yr (DE08, DE08-2), 5.8 (DSS), 7.0 (DSSW20K)** (Trudinger et al.
2002b); samples closer together than that measure **overlapping air-age distributions**. The
1940–1960 window's **13 samples sit in four tight groups — 1957–58, 1955, 1947–50, 1940–41 —
spanning 18 yr**. span/width = **3.6** independent draws; clustering at one width gives **2**.
Not 13. **This is the same non-independence the 2026-08-22 panel flagged for the CO₂ ice term
(255 site-correlated rows scored as independent), sitting undetected in the isotope term.**

**THE CORRECTION.** `se` is now computed on `n_eff`, clustered at `DM_SPECTRAL_WIDTH` = 5.0 (the
sample-weighted mean over the window; larger widths give fewer draws and a *larger* σ, so 5.0 is
the conservative end of the published range). Window se's go 0.014–0.020 → 0.023–0.076 ‰.

| | shipped | corrected |
|---|---|---|
| observed excursion | −0.002 ± **0.016** ‰ | −0.002 ± **0.041** ‰ |
| departure from the −0.214 ‰ a terrestrial explanation needs | **13.1 σ** | **5.1 σ** |

**Estimator sensitivity, and it must be quoted as a range:** clustering gives 2 draws → 5.1 σ;
span/width gives 3.6 → ~6.8 σ. **The verdict is ~5–7 σ. Do not quote "12.7 σ" again.**

**THE CONCLUSION SURVIVES.** 5 σ still rejects a terrestrial or emissions explanation of the
mid-century swing decisively, so **handoff 2026-08-22 §4's withdrawal of the LUC time-profile
programme still stands** — it was the right call for a reason that is 2.5× weaker than stated.

**A THIRD ERROR TERM IS STILL UNQUANTIFIED, and it is now the binding one.** The full budget:
(1) sampling on `n_eff` — the σ above; (2) the trend-prediction error, ~0.006 ‰, **omitted
entirely before today**, subdominant, moves the verdict <0.1 σ; (3) **systematic/calibration —
unbounded here.** A *constant* offset cancels in this excursion by construction and a *linear*
drift is absorbed by the fitted trend, so what survives is a **non-linear calibration drift
localised near mid-century**. Nothing in the repo bounds it, and Francey's warning is precisely
about that class. Recorded in the file's own GATE 6 output rather than left to a reader.

977/979 tests pass. No objective change; no refit owed.

## 2026-08-23c — `rep_dC`: the panel's "mis-centred prior" does not survive measurement

Marcus asked for panel item 12. New `calibration/diag_rep_dC_prior.R` (~4 min). **The prior was
NOT changed** — the measurement says a change would hide the blocker rather than fix it, and the
choice of what to do instead is Marcus's.

**THE PHYSICS IN ITEM 12 IS RIGHT AND THE REMEDY IS NOT.** Both stations should read below their
box means, so the physical expectation for `rep_dC` is positive rather than zero. But profiling it
with its two strongly-correlated partners re-optimised (`k_w` −0.78, `bomb_total` −0.73) puts the
**likelihood-only optimum at 5.62 ppm with curvature sd 0.097 ppm** — the data are ~10× tighter
than the 1.0 ppm prior. **Re-centring the prior anywhere in [0, 3] ppm moves the posterior by
≤ 0.03 ppm.** What it moves is the *diagnostic*: `prior_z` 5.57 → 3.59 at μ = 2. A prior centre
that only moves the flag, and demotes the top-ranked one at that, is the `prior_z_grid_scale`
failure repeated deliberately.

**THE PRIOR SD HAS NO RECEIPT FOR THE QUANTITY IT CONSTRAINS.** `LIK_CO2_REP_ERR` = 1.0 ppm is
both the CO₂-level stream sd and this prior's sd, and its stated receipt is **co-located
INSTRUMENT disagreement at one site** (NOAA in-situ vs SIO flask at MLO, 0.39–0.59 ppm RMS). The
comment concedes it: "a station-vs-hemispheric-BOX term must exceed it. 1.0 ppm is a plausible
value." A station-vs-box offset is a *spatial-representativeness* quantity and nothing on disk
measures it — which is what item 12's "1 h + **data**" price was really about.

**AND THE REAL DEFECT IS NEITHER, which is the finding.** `rep_dC` is applied to the MLO/SPO level
streams only; the ice block scores the bare `co2_SH` box. Comparing the two eras isolates it:

| flask era | MLO | SPO | mean | | ice era | box − obs |
|---|---|---|---|---|---|---|
| 1958–70 | 4.85 | 4.49 | 4.67 | | 1850–1900 | **−1.89** |
| 1970–85 | 5.94 | 5.67 | 5.81 | | 1900–40 | **−3.86** |
| 1985–2000 | 5.94 | 5.72 | 5.83 | | 1940–58 | **−0.67** |
| 2000–12 | 5.55 | 5.32 | 5.44 | | | |
| 2012–24 | 5.67 | 5.49 | 5.58 | | | |

**Within the flask era the demanded offset is constant to ~1 ppm over 66 years, and MLO and SPO
agree to ~0.3 ppm — genuinely common-mode, and the fitted 5.57 is exactly the flask-era mean
5.47. Before 1958 it has the OPPOSITE SIGN.** A representation offset is a property of a station
versus a box; it cannot change sign because the observing system changed. **So `rep_dC` is not a
representation constant that came out too big — it is the modern half of the ~9.4 ppm swing, and
the +5.57 σ is that swing reported in the units of the parameter that hides it.** This reaches
`ccx_rep_dc_co2_bias`'s conclusion from the residual side, where that memory reached it from logL.

**Consequence: no change to this prior addresses it.** Re-centring hides it; widening hides it
further; *tightening* forces the modern residual back into the CO₂ rows where it is visible, at a
cost part 1 prices (~370 log-units to pin at 3.0 ppm with two partners free). And it ties
`rep_dC` directly to the session's live scientific question rather than leaving it a nuisance
parameter: the swing is the thing, and this parameter is where half of it went.

## 2026-08-23b — The per-direction Hessian folded into the refit driver

Marcus. The correct Hessian existed only in `calibration/recompute_hessian.R`, as a manual second
step after every refit — and forgetting it silently shipped `sd_unc`, `cov`, `logdet_negH` and the
Laplace evidence computed at a scalar `ARM_HESS_EPS = 3e-4` that is **250× too small for `h_ml`,
167× for `kz`, 67× for `gamma_enso`** (`ccx_hess_step_sd`).

**NOT COPIED INTO THE DRIVER — PROMOTED TO `R/calibrate.R`.** Copying it would have created the
second implementation that yesterday's `luc_scale` sweep spent a day removing. New
`ccx_hessian_per_direction(lp, u)` sizes one step per direction (`eps_k = 0.10 × sd_k`, plateau-
scanned over a 10-point grid, verified at eps/3 and 3·eps), and **both** the driver and
`recompute_hessian.R` now call it. `ARM_HESS_EPS` is retired to reporting-only.

**VERIFIED BOTH WAYS.** The driver's new path against the reference `recompute_hessian.R` output:
`max|ΔH|/max|H|` **1.4e-8**, Frobenius **2.9e-8**, `sd_unc` **3.4e-4**, `logdet(−H)` **6.7e-4**,
both PD. The rewired `recompute_hessian.R` against its own previous output: **bit-identical,
0.00e+00** on ΔH, `sd_unc` and `logdet`.

**A 3.0e+04 "relative difference" in that first comparison was a DENOMINATOR ARTEFACT** and is
recorded because it reads exactly like a real defect: the worst cell is `[rep_dC, bomb_total]`,
where the reference entry is **exactly 0.0**. Scale by the matrix norm, not cell-wise, when
comparing Hessians — same failure mode as `diag_d13c_midcentury.R`'s GATE 2.

**TWO SILENT DEFECTS FELL OUT OF THE REWIRE:**
1. The driver's kink-proximity check used the scalar step to compute how far the Hessian's `h_ml`
   row reaches into the kink map. Since `h_ml`'s correct step is ~250× larger, **the check was
   certifying the safety of a step the Hessian did not take** — reassurance about the wrong
   quantity. Now uses `h_ml`'s own step.
2. The driver's "curvature step-stability at the mode" block re-ran an eps × (1/3, 1, 3) sweep at
   the same retired scalar, and at a loose 0.25 tolerance. It now consumes
   `ccx_hessian_per_direction()`'s own verification around each direction's **actual** step, at
   the tighter 0.02.

Arm files now also record `hess_eps_frac`, `hess_sd_diag`, `hess_eps_grid`, `hess_eps_verify` and
`hess_eps_no_plateau`, so the step choice is auditable from the file rather than from a log.
977/979 tests pass — the same by-design `test-fluxes.R:99,:100` pair.

## 2026-08-23 — The arm-N refit onto the new objective: converged, and it fixed no gate

First fit on the post-`d6adb58` objective. Arm N only (Marcus). 623.9 min, 266,961 evals,
0.140 s/eval, warm-started from the repaired 08-21 mode. `refit_20260822.log`.

**CONVERGED, AND THE 08-20r PATHOLOGY DID NOT RECUR.** Cycle 1 ran to the 20-restart cap
(gain 1.7295) and its BFGS polish then gained **0.0359** — against the 16.08 that revealed the
un-located mode in 08-20r. Cycle 2 confirmed it immediately: two restarts at 0.0000, polish
0.0000, `CONVERGED: cycle gain below ARM_CYCLE_TOL`. Final log-post **−1859.32**.

**THE 10.4-HOUR RUN LANDED EXACTLY WHERE THE 20-MINUTE SMOKE RUN DID.** Same log-post to four
decimals (−1859.3225), max coordinate difference **0.0016 sd**. Two very different search budgets
converging on the same point is good evidence the mode is genuinely located — and it means the
next refit on a small objective change can be scoped at ~1 cycle with a warm start rather than
20 restarts. Worth knowing before spending another 10 h.

**THE MODE MOVED MORE THAN THE LOG-POST SUGGESTED, which is why the displacement was measured
rather than inferred from the 1.7 gain.** RMS **0.577 sd**, three coordinates over 1 sd:
`rep_dC` **+1.60** (5.176 → 5.566), `k_w` **−1.35** (2024 → 1977), `bomb_total` **−1.21**
(122.22 → 121.22). Measured on the CORRECTED Hessian (below), encoding all vectors under one
table since `par_mode` is band-safe and `u_mode` is not.

**`rep_dC` GOT WORSE, NOT BETTER.** The ice-hemisphere fix pushed the station-vs-box CO₂ offset
from 5.18 to **5.57 σ** outside its N(0,1) prior. The standing blocker in
`ccx_rep_dc_co2_bias` is sharpened by the correction, not relieved by it. Parameters beyond 3 σ
at the new mode: `sst_seas_amp_NH` −6.22, `rep_dC` +5.57, `sst_seas_amp_SH` −4.25,
`seas_T_amp_SH` −3.95.

**HESSIAN RECOMPUTED PER-DIRECTION** (`recompute_hessian.R --update`, `HESS_EPS_FRAC` 0.10), and
it confirms `ccx_hess_step_sd` from measurement: the refit driver's scalar `ARM_HESS_EPS = 3e-4`
is **250× too small for `h_ml`, 167× for `kz`, 67× for `gamma_enso`** (0.004× / 0.006× / 0.015×
in the log's `vs refit 3e-4` column). `-H` PD, all coordinates step-stable. **The driver still
writes the scalar-eps Hessian, so `recompute_hessian.R` remains a mandatory second step after
every refit** — worth folding into the driver.

**AND THE POINT OF THE WHOLE EXERCISE: NO GATE CHANGED VERDICT. Three drifted slightly worse.**

| gate | pre-refit | refitted | verdict |
|---|---|---|---|
| 12 — Joos IRF | 11.74 / 23.97 / 39.36 | **11.69 / 23.81 / 39.06** | FAILS all three, further out |
| 4 — airborne fraction | 0.435, sd 0.019 | **0.434, sd 0.019** | level passes, variability still 2.7× too smooth |
| 5 — bomb curve | peak 892.3 ‰, lag 0.91 | **888.5 ‰, lag 0.92** | FAILS; still +33 ‰ and ~1 yr late |
| 7 — sinks | land +2.04σ | **land +2.12σ**, ocean −0.64σ | FAILS on land |

**WITHDRAWN: "TH 50 and TH 100 are ON the floor".** At −0.13 % and −0.35 % pre-refit that reading
was fair; at **−0.78 % and −1.12 %** it is not. Gate 12 now fails clearly at all three horizons,
not marginally at two.

**So the +16.9 log-units the objective correction was worth bought no physical improvement.** The
ice term was scored against the wrong hemisphere and fixing it moved the likelihood a long way
and the observables not at all — which is itself the informative result, and it points the open
questions back at structure rather than calibration.

## 2026-08-22c — The luc_scale bug swept repo-wide; the arm files repaired; two lint gates

Marcus: fix the stored streams and debug the code so the next step starts clean. Eight sites,
two mutation-tested gates, both arm files repaired, and one claim of mine withdrawn.

**THE SWEEP — eight sites, not one.** A mechanical scan of every file that derives an annual
E_LUC and multiplies it by `luc_scale` found **eight** applying it twice (the forcing's LUC
columns scaled, then `eluc` derived from that already-scaled forcing and scaled again):
`run_modefind_pump_arms.R:452`, `diag_driver_audit.R`, `diag_fit_at_mode.R`,
`diag_phi_eff_profile.R`, `diag_rep_dC_gates.R`, `diag_rep_dC_pinned.R`,
`diag_seas_channel_decomp.R`, `diag_seas_obs_drivers.R`. Four near-identical-looking sites were
**correct** and left alone — they take `eluc` from the UNSCALED base (`diag_dic_gradient.R`,
`diag_h_ml_roles.R`, `diag_ocean_candidates.R`, `diag_hml_band_discontinuity.R`), which is the
discriminator the first two passes of the scan both missed. **Blast radius is exactly one
stream:** `ccx_loglik` reads `luc` only in the `gcb_land_sink` block.

**THE STRUCTURAL FIX.** `ccx_load_mode()` and `ccx_scaled_forcing()` promoted to `R/calibrate.R`;
the latter returns the forcing AND its matching `eluc` from one call, so they cannot disagree.
`CCX_BOMB_REF` / `CCX_LUC_COLS` named in `R/constants.R`. But a helper nobody must use fixes
nothing, so `test-luc-scale.R` gained **two gates**: a repo lint on the two-statement signature,
and a numerical twin asserting the canonical reconstruction equals `ccx_make_logpost`'s own
likelihood to 1e-8.

**BOTH GATES WERE MUTATION-TESTED, AND THE SECOND ONE FAILED ITS MUTATION.** Squaring `luc_scale`
inside the helper left the numerical gate at FAIL 0 — because it evaluated at `ccx_init_unc()`,
where `luc_scale` init is exactly 1 and `bomb_total` exactly the reference 102, so a double
scaling is invisible. Both are now perturbed off their inits and the gate asserts they are. It
then catches the squared-luc mutation (−11.2) and a dropped-bomb_total mutation (+696). **The
lint later caught a regression I introduced myself** — a comment-stripping edit silently reverted
the fix in `diag_rep_dC_gates.R` — which is the argument for the lint over the helper.

**ARM FILES REPAIRED** by new `calibration/repair_arm_streams.R`; pre-repair copies in
`output/quarantine/20260822_luc_scale_squared_streams/` with a README. Each file now carries
`streams` (this par_mode under the CURRENT objective), `streams_as_fitted` (what the refit stored)
and `streams_provenance`. **`par_mode`, `logpost`, `hessian`, `cov`, `eigen` are untouched — the
objective never had the bug, so no fitted quantity was ever affected.** Two vintages now live in
each file deliberately, and the provenance field says so. All 21 streams reproduce to 0.000.

**`diag_fit_at_mode.R` WAS COMPREHENSIVELY STALE — five defects, all silent, and its own gate
printed MISMATCH on all 14 rows while the file went on to print the rankings that were quoted
into memory `ccx_fit_at_mode`.** (1) The `seas_drivers/sst_obs <- 0` escape hatch claimed the mode
was fitted under the pre-08-18 seasonal sine; the 08-21 file carries DRIVER parameters and no sine
knobs, so it ran the diagnostic at a different model from the fit. (2) `rep_dC` never applied, so
both CO2 level rows reported the 5.18 ppm offset as model bias. (3) `sigma_d13c` retired 08-18 ⇒
`sqrt(NULL^2+REP^2)` is numeric(0) ⇒ both d13C level rows silently reported **n = 0** and were
dropped from every ranking. (4) ice still on `co2_NH`. (5) **gate 7's land σ hardcoded 0.9** — the
value `LIK_GCB_LAND_SD` held before 2026-08-14, when it became 0.5. All fixed; the gate is now
FATAL and its allow-list is empty. The same stale hatch was removed from `diag_rep_dC_gates.R` and
`diag_station_representation.R`, and `diag_rep_dC_gates.R`'s GATE 1 was **retargeted**: it was
asserting legacy parity against stored streams that are no longer legacy, failing by 880.6
log-units against a contract that no longer described the object. A new gate 1b checks the
absence contract against itself, so it cannot go stale the same way.

**CONSEQUENCE FOR MEMORY `ccx_fit_at_mode`: "gate 7 PASSES (−0.6σ/+0.9σ)" IS WRONG.** It rests on
the stale 0.9. At `LIK_GCB_LAND_SD` = 0.5 the shipped mode is ocean −0.6σ, **land +1.9σ — gate 7
FAILS**, consistent with the +2.04σ measured independently in 2026-08-22b. Its "d13C levels are
pure BIAS" also came from the un-offset version; with `rep_dC` applied the d13C level biases are
+1.12 and **−0.77** z — small and OPPOSITE in sign between stations, which is not a common-mode
bias at all.

**TRIED AND WITHDRAWN — "`gamma_enso` is dropped by `intersect(names(p), CCX_PARAM_NAMES)`".** I
wrote this into a code comment and a docstring off a crude grep, then checked before acting on it
across 11 files: `gamma_enso` IS a field of `ccx_default_params()` and IS in `CCX_PARAM_NAMES`, so
intersect() picks it up and it was never dropped anywhere. Both comments corrected. The six
parameters intersect() really does drop are `bomb_total`, `luc_scale`, `sigma_d14c`, `rep_dC`,
`grad_off_co2`, `grad_off_d13c`; `app/global.R`'s explicit `gamma_enso` line is redundant on the
mode path, not load-bearing.

977/979 tests pass — the same by-design `test-fluxes.R:99,:100` pair. Gate 12's numbers are
unchanged by all of this (11.74 / 23.97 / 39.36), as they must be: the bug never touched a fit.

## 2026-08-22b — DESIGN gates 4/5/7/12 at the vector the app actually ships

Discharges panel item #7 ("DESIGN gates measured at defaults; the app ships the mode"). Since
`8b94ba4` (2026-08-21) `app/global.R` resolves `mode_fit_pumpN.rds`, so every "Status at default
parameters" line in DESIGN sec.6 described a vector the app does not run. `diag_joos_irf.R:97`
was hardcoded to `ccx_default_params()` and grew a mode path
(`Rscript calibration/diag_joos_irf.R [defaults|N|D]`, ~7 s); new
`calibration/diag_design_gates_at_mode.R` (~9 s) covers gates 4, 5 and 7 plus a provenance gate.
Both carry the two FORCING parameters (`bomb_total`, `luc_scale`) through a wrapper, the same
construction and for the same reason as `app_build_forcing()` — and on gate 5 that is not a
refinement, it is the whole measurement.

**GATE 12 FAILS AT THE SHIPPED MODE, at all three horizons** — integrated IRF 11.74 / 23.97 /
39.36 yr against Joos floors 12.2 / 24.0 / 39.5, i.e. −3.73 / −0.13 / −0.35 %. The gate's status
line has now been stale three times. Read the rows differently: TH 20 is a substantive miss, TH
50 and TH 100 sit ON the floor to within a third of a percent. **The background does not explain
it and points the other way** — the mode's held 2010 background is 394.4 ppm vs 387.6 at
defaults, and a higher background makes a pulse last *longer* (part 4 measures PI 33.9 vs PD
42.1 at the mode), so it fails in spite of a bias in its favour. The imperfect hold is not the
cause either: `ccx_irf()` is a paired difference, so baseline drift cancels to first order.

**GATE 4 SPLITS — the level passes, the variability fails, and the mode is worse than the
defaults on the half that fails.** AF 1959–2024 = 0.435 against GCB's 0.431 (best the model has
recorded), but the decadal spread is sd 0.019 against the observations' 0.051 — **2.7× too
smooth**, where defaults gave 0.035. The gate's second sentence ("must not be *smoother* than
this") is the one being failed. **And gate 4 is immune to the contamination that afflicts gate
7**: AF = growth ÷ emissions, while GCB's `imbalance` is the residual *after* the sinks, so it
enters neither term. This supplies the number the 2026-08-22 handoff §4 pre-registration clause
asked for — target 0.051, model 0.019.

**GATE 5 FAILS, and the finding is not the one the measurement was started to confirm.** The
observed hemispheric aggregate was recomputed under `ccx_zone_weights()` with the same peak
estimator applied to the model, and it reproduces DESIGN's own table (NH 855.3 ‰ @1963.676 vs
853.2/1963.708; lag 1.34 vs 1.33) — the estimator is validated where a published answer exists
before being used where none is. At the mode: NH peak 892.3 ‰ (defaults 801.5, obs 855.3), so
the fitted `bomb_total` = 122.22 kmol moved the miss ACROSS ZERO rather than closing it; peak
timing ~1 yr late in every vector and `bomb_total` cannot touch it; NH→SH lag 0.91 vs 1.34 obs.

**TRIED AND WITHDRAWN — "both interhemispheric constraints say τ_ex is too fast".** Written into
DESIGN from the sign of gate 9's stored log-units, then profiled before it was allowed to stand,
and it is FALSE. The bomb lag rises monotonically with τ_ex and needs ≈ 2.3 yr to reach 1.34;
both gradient streams sit at a **sharp interior optimum at the mode's 1.032** and reject τ_ex =
2.0 by ~1490 log-units on `co2_gradient` alone. **The two interhemispheric observables disagree,
and the gradient outvotes the bomb lag by three orders of magnitude** — so gate 5's lag miss is a
FORCED residual and a structural statement about the two-box exchange, not an untried parameter.
Magnitudes are a frozen 1-D profile and therefore upper bounds (cf. `ccx_seas_q10_ridge`, where
`beta_max`/`fert_k` absorbed 85 % of exactly this kind of cost); the ordering is robust.

**GATE 7 still fails on land at the mode** — land +2.04σ (3.38 GtC/yr), ocean −0.62σ (2.97),
measured by two independently written reconstructions that agree. The fit bought back most of
the ocean miss and almost none of the land one.

**BUG FOUND AND FIXED — `run_modefind_pump_arms.R:452` applied `luc_scale` TWICE** to the
gross-land-sink reconstruction (the LUC columns of `F` were already scaled three lines up, then
`el` was derived from that `F` and scaled again). `ccx_make_logpost()` does not have it — it
derives `ELUC_BASE` once from a luc_scale = 1 forcing outside the closure — so **the objective
was always right and every logpost / Hessian / evidence number stands.** What was wrong is the
per-stream DECOMPOSITION stored in `mode_fit_pump{N,D}.rds`, which is the only per-stream table
the project has and the one handoffs rank work from: arm N's `gcb_land_sink` reads −93.71 where
the correct value is −95.62, flattered by 1.91 log-units. It is NOT common-mode (luc_scale
0.8902 vs 0.8575), so the N-vs-D per-stream comparison inherits a differential error of the same
order as the 5.62 evidence margin printed beside it. The stored `streams` stay wrong until the
owed refit rewrites them — **quarantine of the arm files is Marcus's call**, and note their
`par_mode`/`logpost`/Hessian fields are all fine, so quarantining would cost the app its
parameters to fix a diagnostic field.

**The provenance gate is the reusable part**, and it is what found that bug — the structural fix
the 2026-08-22 handoff §5 asked for ("a provenance stamp on every saved fit"). It recomputes
each arm file's stored per-stream logL at the same `par_mode` under today's code. Arm N moves by
**+16.9 on `co2_icecore` alone**, independently reproducing `diag_ice_hemisphere.R`'s headline.
**Arm D moves by −8244**, dominated by `co2_seasonal_MLO` (−7131): it was last fitted before the
2026-08-20g `CCX_SST_SEAS_LAG` correction — both `refit_20260820.log` and
`refit_20260821_cont.log` read "REFIT, 1 ARM(S) [N]". **So arm D and arm N are two objectives,
not two pump modes, and must not be read as an arm comparison.** The likelihood is recomputed
rather than the posterior because the refit's h_ml bound [85,120] renormalises the prior and is
not reconstructible from `ccx_default_params()` (memory `ccx_hml_band_provenance`); `par_mode` is
band-safe.

974/976 tests pass — the same by-design `test-fluxes.R:99,:100` pair. No refit run; the objective
change of `d6adb58` still owes one, and everything above is measured at the pre-change mode
because that is what the app ships today.

## 2026-08-22 — Four-expert panel; the ice hemisphere, the estimator, and the isotopes

**Objective CHANGED.** `R/likelihood.R`'s ice term now scores against `co2_SH`, not `co2_NH`.
Nothing fitted before `d6adb58` is comparable across it. Law Dome is at 66.7 S; the shipped
comment ("SH-cored but globally well mixed pre-1900") covers 96 of 255 rows, and
`diag_co2_level_swing.R:66` had been using `co2_SH` with the opposite reasoning all along — so
the objective and the diagnostic that produced the sec.4 GATE D swing table disagreed and were
quoted interchangeably. New `diag_ice_hemisphere.R`: +16.9 logL, and 1.76 ppm (16 %) of the
11.20 ppm era swing was the hemisphere choice. 974/976 tests still pass.

**TRIED AND WITHDRAWN — the sec.12c LUC time-profile programme.** Not abandoned for cost;
abandoned because two measurements undercut its rationale. (1) `diag_swing_estimator.R`: 21d
TEST 2's growth rates came from a loess(span=0.25) over 1850-1996, a ~36 yr window on a decadal
feature. Raw within-decade OLS moves the minimum from the 1950s (+0.207) to the 1940s (+0.010).
The pause is NOT weaker for it — against SPO flask on the same estimator the record's decadal
error bar is 0.098 ppm/yr, so the raw pause is 4.7x the noise floor. The decade was wrong, the
feature is real. And the model's growth-rate error tracks GCB's OWN published budget imbalance
at r = 0.771 / slope 0.781 (r = 0.839 / 0.486 on the LOESS numbers, so it survives the estimator
that produced it); GCB fails to close its own budget by 44.3 GtC = 20.9 ppm over 1930-1969
against a ~9 ppm model swing, while the modern imbalance is +0.016 GtC/yr. (2)
`diag_d13c_midcentury.R`: a terrestrial or emissions explanation of the swing is rejected at
12.7 sigma. So the shape it would have been fitted to is largely GCB's imbalance, and the
isotopes say it is not emissions.

**The isotope test, and mutation-testing it before believing its negative.** 105 Law Dome d13C
samples (37 in 1900-1960) were on disk and NOT in the objective. The d13C residual is monotone
(-0.030 -> -0.160 permil) while the CO2 residual changes sign (-4.38 -> +4.76 ppm). Excursion at
1940-1960: -0.003 +/- 0.016 permil against the -0.209 required. GATE 5 injected 33.1 GtC of
mid-century LUC and confirmed the gate is LIVE at 6.4 se — and in doing so measured the transfer
ratio at -0.0239 permil/ppm where closed-box mass balance gives -0.0571, a factor of 2.4 from
air-sea isotopic damping. GATE 4's sigmas are inflated by that factor and GATE 6 supersedes them;
GATE 2's ratio statistic is confounded where the CO2 residual crosses zero and is marked
not-to-quote in the file.

**Four claims in handoff 21d do not survive the code** (see the new handoff sec.5): the "1523
monthly points" information ratio (levels are scored ANNUALLY, 126 rows); "the level is
unconstrained post-1958" (it is nominally OVER-constrained by a non-independent ice term — the
conclusion survives, the remedy is the covariance not the prior); sec.12a's "Reason 1" (void,
Reason 2 kills it); and sec.12b's kz corollary (6528 is the permissive edge of the 14C bracket).
None had been gated against anything — the same failure mode as 21c sec.6.

Handoff: `notes/handoff_2026-08-22_panel_and_three_tests.md`.

## 2026-08-21 (last) — The swing survives four obs-artefact tests; three candidate fixes closed

### 1. Marcus challenged the swing on the ice data, and it held (`diag_co2_level_swing.R`)

The challenge was right and my cross-check was weaker than I presented it: ice and SPO flask
agreeing to 0.31 ppm is real, but **that overlap starts in 1957 and the crossover is at
~1945–1955**, inside the window where ice is the only product. Four tests, each able to kill it:

- **BY CORE.** Law Dome is five cores with **two gas-age offsets** (DE08/DE08-2 at 31 yr,
  DSS/DSS0506 at 60). Over 1900–1940 DE08 gives **−3.85** and DSS **−3.86**. Over 1958–1997
  DE08 +4.44, DE08-2 +5.45, DSSW20K +5.22. The two families differ by 0.73 ppm across
  1900–1962 — the scale of any product inconsistency, against an 8.8 ppm swing. **8.3 of the
  8.8 is within DE08 alone.**
- **GROWTH RATE — and Marcus's "weird pause" is real.** The ice-derived rate runs 0.376 (1940s)
  → **0.207 (1950s)** → 0.523 (1960s); the model runs smoothly 0.527 → 0.498 → 0.856. The error
  is −0.05 to −0.10 ppm/yr in 1870–1920, **+0.15 to +0.33 in 1930–1965**, ~0 by the 1970s.
  **It is one mid-century feature, not a drift** — which sharpens the earlier entry's framing.
- **FIRN SMOOTHING**, scanned rather than asserted (no citation is carried): Gaussian widths
  0/5/10/20/30 yr leave the swing at 8.82/9.01/9.41/7.44/8.64. Nothing removes it.
- **GAS AGE.** A −10 yr shift collapses the swing to 1.68 and drives both ends to −7.50/−5.82.
  Closed independently: the post-1958 end is corroborated by **SPO flask data**, which has no
  firn and no age ambiguity, at +4.51/+5.29/+5.08.

**Not settled, and recorded as such:** whether the pause is real atmosphere or an enclosure
artefact **common to all Law Dome cores**. By-core agreement rules out core-*specific* artefacts,
not a shared firn process — every core here is one site. Needs WAIS Divide / Siple or the
literature; no papers folder on this machine, so no citation is asserted.

### 2. No land knob fixes both ends (`diag_land_eagerness.R`)

Built so the previous entry's "land sink is too eager" hypothesis could lose, and it half-lost.
Every lever reducing the modern land sink makes the mid-century error **worse**, because each is
a *gain* on a sink and a gain moves both ends the same way. All three verdicts: TRADES.

**q10 is still the right knob for the modern half**: 1.09 → 2.0 takes land +2.04 → **+0.94 σ**
and ocean −0.62 → −0.37 σ (both improve) for +4.5 ppm of CO₂; `beta_max` and `fert_k` buy more
land-sink reduction and cost **+20–25 ppm**. q10 acts through warming, which is where the sink
error is. It sits at 1.0907 because the **seasonal** rows put it there via the exact ridge with
`seas_T_amp_NH` — rows that move 4.3 log-units across the whole q10 range. Note 21c §2d's
re-anchored prediction (1.35–1.5) lands at **+1.44 σ: even the blocked refit does not close
gate 7.** And **~40 % of the mid-century half is the land-use INPUT** — swapping to SSP/LUH2 cuts
that error +0.228 → +0.137 while barely touching the sink.

### 3. Three candidate directions tested and closed

**The γ_IAV term is dead** (`diag_gamma_iav.R`), measured *before* touching the objective because
a new likelihood term means refit-owed. Observed 1.779 ± 0.433 ppm/yr/K; model at the mode 1.581;
model at q10 = 2.0 **2.491**. (a) The observable **points the wrong way** — the model already
matches it at low q10 and raising q10 overshoots by 1.0–1.6 se. (b) It would be **absorbed**:
`gamma_enso` (wide N(0,2) prior) has **17× the leverage per posterior σ**. The mode matches
observed γ_IAV through a fitted ENSO flux, not through respiration temperature sensitivity.

**The partition reframing, and its one lever, closed** (`diag_kz_railed.R`). Land +2.04 σ, ocean
−0.62 σ, CO₂ +5 ppm read together say total uptake is about right and the *partition* is wrong.
`kz` is the only knob moving land down / ocean up / CO₂ down together, and kz = 8000 lands the
ocean sink on 3.20 vs GCB 3.22 ± 0.40. But: the likelihood **turns over at 6462, inside** the
[3942.5, 6528] bracket — so the bracket is redundant, not binding; what holds kz is the **CO₂
level streams by two orders of magnitude**; and **`rep_dC` does not rescue it** (profiled free,
the optimum moves 6462 → 6528, +0.6 log-units — it can translate, and kz changes shape). The
script's filename and first header both asserted "railed"; the header was rewritten, not the
finding.

**Good news corollary:** the bracket ceiling was bisected so kz maps to the observed deep-Δ¹⁴C
edge (−150 ‰); the CO₂ record's optimum lands at 6462 **independently**. Two unrelated
observables put kz in the same place to within 1 %.

### What is left, and what was tried and abandoned

**Abandoned, with measurements so they are not re-opened:** the γ_IAV likelihood term; `kz` as a
partition lever; single-knob land eagerness. **Open:** the **land-use inventory's time profile** —
the only lever that moved the mid-century end, with the two inventories 91.4 GtC apart. Ask what
E_LUC(t) *shape* the CO₂ record wants; `luc_scale` is one number and cannot change a shape.
**Do not refit** — no land parameter expresses the defect and the ocean parameters are pinned.

## 2026-08-21 (later still) — The app runs on the calibrated mode; `rep_dC` is laundering a 9 ppm swing

Took handoff 21c's stated default next move (§6, the app). Two things came out of it: the
app fix, which was not the one-liner the handoff described, and a first-order finding about
the calibration that the app work surfaced by accident.

### 1. The app fix, and why the path was the small half

`app/global.R` resolved `calibration/output/mode_fit.rds`, a file that has never existed, so
the app shipped uncalibrated defaults. Repointing it at `pump_arms/mode_fit_pumpN.rds` is
necessary and **not sufficient**: six of the 21 fitted parameters have no slot in
`ccx_default_params()` and the existing `intersect()` dropped all six silently. Four are
likelihood parameters and cannot move a trajectory. **Two are FORCING parameters** —
`bomb_total` 122.22 kmol, `luc_scale` 0.8902 — applied by `ccx_make_logpost()` as column
rescalings, worth **+5.8 ppm at 2024** on their own. The path fix alone would have run the
fitted parameters against a forcing the fit never saw, and produced a WORSE curve than the
defaults it replaced.

Every forcing in the app now goes through `app_build_forcing()` / `app_run_coupled()`.
The second needed a pass-through added to `ccx_run_coupled()`, which built its own forcing
internally — worth another 2.7 ppm at 2100 of silent disagreement between the historical tab
and the futures tab.

| resolution | NH box @2024 | vs MLO | land sink | ocean sink |
|---|---|---|---|---|
| DEFAULTS (shipped until today) | 423.3 | −1.1 | +2.18 σ | −1.49 σ |
| PAR-ONLY (path fix alone) | 433.8 | +9.4 | +2.06 σ | −0.47 σ |
| **FULL (landed)** | **428.0** | **+3.6** | **+2.04 σ** | **−0.62 σ** |

**What the fix buys is the ocean sink**, −1.49 → −0.62 σ. The land sink does not move and
still misses by 2 σ.

### 2. Handoff 21c §6's table does not reproduce, and it had set the priority

21c §6 reported defaults at **409.8 ppm / −14.6 vs obs, land 2.73, ocean 2.44**, and called
the fix "the single highest-value fix in the repo" on the strength of closing a 14.6 ppm
gap. Measured here: **423.3 / −1.1, land 3.45, ocean 2.62**. Two independent checks say
these are right — sourcing `app/global.R` itself returns them to the digit, and DESIGN §6
gate 7's recorded line (land +2.28 σ / 3.50, ocean −1.52 σ / 2.61, 2026-08-14) agrees to
within 0.1 σ. **So gate 7's status line is NOT stale, contra 21c §6, and the app was never
14.6 ppm low.** The fix was still worth making; the reason given for it was wrong.

### 3. `rep_dC` = +5.18 σ is the late half of a 9 ppm swing (`diag_rep_dC_shape.R`)

`rep_dC` has prior N(0, `LIK_CO2_REP_ERR` = 1.0 ppm) — the repo's own station-vs-box scale,
with a receipt. The mode puts it at **+5.176 ppm**, the largest |z| in the fit, and
`R/calibrate.R` says the prior exists to "resist a structural error wearing its clothes"
and that the case it was built for wants **−4.19** ppm. Opposite sign, larger magnitude.

- **97 % common-mode** — NH −MLO +5.15, SH−SPO +4.93, difference 0.22 ppm. A station-vs-box
  offset is a property of a station's latitude inside its box; the same number in both
  hemispheres is +10.7 GtC of atmospheric carbon, not a representation constant.
- **Flat over 1958–2024** — trend +0.0120 ± 0.0039 ppm/yr, 0.79 ppm of drift on a 5.06 ppm
  mean. Subtract 5.18 and no decade of either station is off by more than 0.9 ppm: the model
  has the SHAPE of the Keeling curve.
- **But 1958–2024 was the wrong window.** `rep_dC` applies only to the station streams; the
  ice-core term is scored without it. On Antarctic CO₂ across the whole record (Law Dome,
  then SPO flask — the two agree to 0.31 ppm over 54 overlapping years):

  | era | model−obs | era | model−obs | era | model−obs |
  |---|---|---|---|---|---|
  | 1750–1800 | −0.57 | 1900–1940 | **−4.12** | 1958–1980 | +4.51 |
  | 1800–1850 | −1.28 | 1940–1960 | −0.77 | 1980–2000 | **+5.29** |
  | 1850–1900 | −2.03 | | | 2000–2025 | +5.08 |

  A **~9 ppm swing with its crossover in the 1940s**, not an offset. The model
  under-accumulates through 1900–1940 and over-accumulates after 1950. The 1900 deficit is a
  known arc (`diag_1900_deficit.R` took it from −6.5 to −2.08 ppm at default parameters);
  what is new is that it did not go away, that it **changes sign**, and that the parameter
  absorbing the modern half is 5 σ into its prior.
- **Why the prior never stood a chance:** `rep_dC` 5.18 → 0 costs **2812 log-units** of
  likelihood and saves **13.4** of prior. **210 to 1.** The absolute CO₂ level is held by the
  ice-core term alone — ~14 units of inverse variance against 1523 monthly station points —
  so post-1958 the model's absolute height is effectively unconstrained and only its shape is
  fitted.

Recorded, not acted on: the ice term is scored against `co2_NH` on a "globally well mixed
pre-1900" argument, sound for its 87 pre-1900 rows and less so for its 52 post-1958 ones
where the model's own NH−SH gradient reaches 3.5 ppm.

### 4. A 13.1 ppm step between two tabs of the same app (`diag_app_params.R` gate 5)

Pre-existing, parameter-independent, and not previously written down. Tab 1 runs the GCB
2025 budget; tab 5 runs the SSP/LUH2 harmonisation. Over 1750–2020 they differ by **91.4 GtC
of cumulative land-use carbon** (187.2 vs 278.6). Measured: **425.9 ppm at 2024 on tab 1,
412.8 ppm at 2024 on tab 5.** SSP2-4.5 reaches 499.6 ppm at 2100 carrying the same deficit.

### Not done, and why

- **The §2 refit** — still blocked on a soil-damping factor with provenance, per 21c §2e.
  Nothing here changes that.
- **The Takahashi climatology** — still the wrong purchase, per 21c §4.
- **Applying `rep_dC` to the app's Keeling panel.** It would make the panel look right, and
  it would be exporting a 5 σ prior violation into a public-facing figure as if it were a
  display convention. The banner now says the fit constrains shape more tightly than height;
  the offset itself is a decision for Marcus.

974 tests pass / 2 fail — the by-design `test-fluxes.R:99,:100` pair, unchanged.

## 2026-08-21 (later) — The prior-tail screen was wrong by up to 1.3 sd, and it had already mis-ranked the work

Started on handoff §2 (the `seas_T_amp_NH` × ln(`q10`) conflict). Restating the conflict
from the constants rather than from the handoff turned up two errors in the numbers the
handoff is built on, one mine and one the code's.

**1. The prior centre is not the bracket's lower end.** `seas_T_amp_NH`'s prior is
`ccx_bracket_lnorm`, whose centre is the GEOMETRIC MEAN of the measured bracket —
`sqrt(11.445 × 17.921) = 14.3215`, not 11.445. So the joint prior implies
14.3215 × ln(2.0) = **9.927** against the mode's 2.251: a factor of **4.41×**, not the
3.52× the handoff quotes off the LO bracket. The direction of the finding is unchanged and
the gap is larger than advertised.

**2. `prior_z()` integrated the prior on a grid that barely contained it.** Both
mode-finders carried their own copy of a physical-plausibility screen that built the prior
CDF on `seq(x/1e3, x*1e3, length.out = 4001)` — a LINEAR grid. For `seas_T_amp_NH` at
x = 25.94 that is 0.026 → 25,937 in steps of 6.5 K, against a prior whose ±1 σ spans
11.4–17.9 K: **one grid point inside the entire prior**. Every tight lognormal was
mis-reported:

| parameter | reported | correct | error |
|---|---|---|---|
| `seas_T_amp_NH` | +3.29 | **+2.65** | 0.64 |
| `bomb_total` | +3.08 | **+1.81** | 1.27 |
| `q10` | −2.01 | **−2.43** | 0.41 |
| `sst_seas_amp_NH` | −5.97 | **−6.27** | 0.30 |
| `seas_T_amp_SH` | −3.71 | **−3.99** | 0.29 |
| `rep_dC` | +5.75 | **+5.18** | 0.57 |

**This is not cosmetic: it changes the flag list the handoff prioritised from.** At
|z| > 3 the old screen flagged six parameters; four survive. `seas_T_amp_NH` (+2.65) and
`bomb_total` (+1.81) come OFF the list. §2's headline "`seas_T_amp_NH` +3.29 σ and `q10`
−2.43 σ" was also mixing the two calculations — one number from the file, one analytic.
The honest pair is **+2.65 / −2.43**, and the conflict is a symmetric ~2.5 σ tug rather
than the asymmetric one it looked like.

**FIXED** as a single `ccx_prior_z()` in `R/calibrate.R`, called by both drivers. It
integrates in the UNCONSTRAINED coordinate, where every prior in `CCX_PARAM_TABLE` has
scale O(1) by construction — a lognormal in x is a normal in log x, a uniform under
`logit` is a standard logistic — so one window and one spacing serve all 21 parameters,
which is exactly what the natural scale could not do. The window is centred on the PRIOR's
mode, found by a coarse scan, not on x: the whole point of the statistic is that x may be
far out in the tail. Both tails are carried and the smaller is used, so a z of −6.27 (a
lower-tail mass of 1.8e-10) survives instead of being lost to `1 - upper`. A half-cell
midpoint correction removes the last +0.003 sd of bias.

`tests/testthat/test-prior-z.R` pins it to the ANALYTIC z for all six lognormal priors,
the one normal prior, and the uniform-under-logit case (where the Jacobian is what could
most easily be got wrong), plus a deep-tail case at −15 σ and a mutation test that the
caller-supplied `table=` argument is actually honoured (the arm driver overrides `h_ml`'s
band in-process). 27 assertions.

**NOT quarantined, deliberately.** The bug touches one REPORTED field, `prior_z`, in
`mode_fit_pumpN.rds`; it never entered the objective, the mode, or the Hessian. Moving the
15-hour refit's output to `outputs/quarantine/` would break §§2–4, which all read it, to
protect against a screening statistic that is now recomputable in one line. The stale
field stays where it is and is superseded by `ccx_prior_z()`.

**Also fixed, in passing:** `ccx_forcing_eluc_annual()` reads `e_luc_{NH,SH}` straight off
the forcing, so taking the annual LUC series AFTER the column multiply and then scaling it
again applies `luc_scale` **twice**. `ccx_make_logpost()` avoids this by building its
`ELUC_BASE` from the unscaled `base_forcing`; the diagnostic idiom copied out of
`diag_phi_eff_profile.R` does not. Worth 1.91 log-units at the arm-N mode, all of it in
`gcb_land_sink`. Caught by the new diagnostic's GATE 2 (loglik computed two ways) before
it produced a single number. `diag_phi_eff_profile.R` still carries it — in its
`by_stream`/`gcb_land_sink` column only, since its optimisation went through
`ccx_make_logpost()` and its seasonal-row conclusions never touch LUC.

**Added `calibration/diag_seas_T_amp_q10_ridge.R`** — the §2 step-1 falsification test.
Profiles `seas_T_amp_NH` over 5–50 K at the converged mode with `q10` re-optimised, on the
LOG-LIKELIHOOD rather than the log-posterior: the priors on those two parameters are the
things in conflict, so an objective containing them cannot say whether the DATA
distinguish the pair. Three tiers (q10 alone; q10 + `seas_T_amp_SH`, since q10 is SHARED
between hemispheres and freezing the SH breaks its product by construction; the full
seasonal block), and the profile is split into the four seasonal rows versus everything
else — because q10 also carries the ANNUAL feedback `q10^(gmst/10)`, and a profile that is
flat in the seasonal rows but not in the rest would mean the repair is splitting q10's two
duties, not re-anchoring a prior. Result pending.

## 2026-08-21 (night) — §4 answered: the δ¹³C rows veto the ocean amplitude. And a label is not a perturbation

### §4 — `sst_seas_amp_NH`, and it is the outcome the handoff said to stop on

`diag_seas_T_amp_q10_ridge.R sst`, profiling 0.05 → the observed 2.2374, `partial` objective.
Two tiers: FROZEN (nothing free — the incumbent's home ground) and SEAS (the rest of the
seasonal block re-optimised).

**Re-optimisation halves the veto**: mode → observed costs **223.2** log-units frozen and
**108.5** with the block free. So 51 % of every previous "the ocean channel is rejected"
reading was home-ground advantage (`match_incumbents_optim` again).

**Outcome 3 is excluded outright.** Of the 223.2 frozen cost, **222.3 is in the four
seasonal rows and 0.96 in everything else.** The seasonal term is NOT leaking into the annual
budget — that would have been a bug, and it is not happening.

**And the veto is δ¹³C, not CO₂** — the outcome §4 called "genuinely surprising and worth
stopping on". At the observed amplitude, SEAS tier, relative to the mode:

| stream | Δ log-units |
|---|---|
| `d13c_seasonal_MLO` | **−52.3** |
| `d13c_seasonal_SPO` | **−26.7** |
| `co2_seasonal_MLO` | −20.4 |
| `co2_seasonal_SPO` | −10.7 |
| everything else combined | −1.8 |

**δ¹³C carries 72 % of it.**

**The mechanism is visible in the amplitude column and it is CANCELLATION, not strength.**
As `sst_seas_amp_NH` rises 0.4668 → 2.2374 the MLO CO₂ seasonal amplitude FALLS, 6.224 →
5.302 against an observed 6.754 — the ocean channel is ANTIPHASE to the net cycle, so
strengthening it shrinks the observable. The δ¹³C-per-ppm signature then rises 0.06804 →
0.07906 against an observed 0.0528: the numerator shrinks more slowly than the denominator.
So the near-neutral ocean channel does NOT dilute the signature as §4 expected — it inflates
it, by shrinking what it is divided by. **The model is already 1.29× too depleted per ppm at
the mode and the observed ocean amplitude makes it 1.50×.**

This is the same cancellation geometry `ccx_seas_chan_budget` found between NEP and
respiration, now in the ocean limb — and it is NOT phase, because `CCX_SST_SEAS_LAG` is
already at its measured 1.32. **§4's own advice applies: stop here rather than push on, and
do NOT go buy a Takahashi flux climatology, which would measure the strength of a channel
whose problem is its sign relative to everything else.**

### A LABEL IS NOT A PERTURBATION, and the panel needs the second one

Marcus proposed tagging the pulse with an inert isotopic label and watching where the label
goes, rather than taking a paired difference. `calibration/diag_tracer_vs_perturbation.R`
runs both from the same state on a held preindustrial background.

**No fourth isotope is needed, and this is the useful part.** ¹⁴C decays at the same rate in
every box, so if M(t) is the no-decay solution then L(t) = e^(−λt)·M(t) solves the decaying
system exactly and **the fraction in each reservoir is identical**. Checked, not assumed:
max |fraction with decay − fraction with decay undone| = **1.1e-16**. The model's existing
¹⁴C, transported without fractionation, already IS the inert tracer.

**And the two experiments give very different answers:**

| yr | label: atm / land / ocean | perturbation: atm / land / ocean |
|---|---|---|
| 20 | 0.165 / 0.238 / 0.597 | 0.313 / 0.472 / 0.215 |
| 100 | **0.055** / 0.131 / 0.814 | **0.154** / 0.597 / 0.249 |
| 1000 | **0.021** / 0.058 / 0.921 | **0.147** / 0.424 / 0.429 |

At 100 yr the atmosphere holds 5.5 % of the label and 15.4 % of the perturbation — a factor
of **2.8**. The label converges on the reservoirs' own proportions (atmosphere 744, land
1667, ocean 36,591 GtC → 1.9 / 4.3 / 93.8 %, against a measured 2.1 / 5.8 / 92.1 % at
1000 yr) because atoms mix. The perturbation does not, because how much EXTRA the ocean will
hold is set by carbonate buffering, not by size.

**So DESIGN §7b's bar chart must stay the PERTURBATION partition.** Its headline is that a
CO₂ pulse is still perturbing the atmosphere in the year 3000; the label partition on the
same axes with the same caption shows the atmosphere nearly empty within a century, which is
the true premise of the residence-time argument §7a exists to answer. **Both belong in the
app — Cawley (2011) vs Essenhigh (2009) is exactly this — and they must not share a
caption.** (Also: ¹⁵C is radioactive, t½ ≈ 2.4 s. For a public panel, "tagged carbon" beats
an isotope number a curious student will look up.)

## 2026-08-21 (evening) — Pulse-partition prototype for the app panel, and two traps it walked into

Marcus asked for an app panel: perturbation curve on top, reservoir-partition bar chart
underneath, dense to 2100 then point estimates at 2200…3000. `calibration/diag_pulse_partition.R`
is the feasibility prototype — not the panel, but the answer to the three questions the panel
cannot be built without.

**It works, and the partition closes EXACTLY.** 100 GtC in 2030 on SSP2-4.5, run to 3000:
the four reservoirs account for the pulse to **0.000 %** from 2050 onward. Two coupled runs
1750–3000 take **1.7 s**, so it is live-in-Shiny territory with no precomputation.

| year | atmosphere | land | surface ocean | deep ocean | ppm left |
|---|---|---|---|---|---|
| 2100 | 0.506 | 0.233 | 0.024 | 0.237 | 23.8 |
| 2300 | 0.292 | 0.352 | 0.016 | 0.339 | 13.8 |
| 3000 | 0.164 | 0.396 | 0.011 | 0.429 | 7.7 |

**TRAP 1 — the SSP emissions table is DECADAL past 2020.** Adding the pulse to the year-2030
row of the raw table adds 100 GtC/yr to a decadal knot, and `ccx_annual_to_monthly()` then
ramps through it for twenty years — delivering about **ten times** the pulse, smeared. The
first run of this file reported **242 ppm** of perturbation from 100 GtC, which is 5× what
100 GtC can produce even with zero uptake. `app/server.R` already interpolates to an annual
grid first and is NOT affected. Now gated: the two emission series must differ in exactly one
year and sum to exactly the pulse.

**TRAP 2 — `deep_C_{NH,SH}` is the BOTTOM BOX, not the ocean interior.** `R/model.R:48` says
so; those columns exist for the DIC/δ¹³C gradient likelihood terms and carry one of ten
interior layers. Summing `ml + deep` as if it were the ocean accounts for **31 %** of
`ocean_C` and loses 69 %, which showed up as the pulse partition failing to close by 32 %.
The split that works with no model change takes the interior as a **remainder**:
`ocean_C − (ml_C_NH + ml_C_SH)`.

**TRAP 3, mine, in the benchmark rather than the model.** The Joos comparison row was typed
from recall and had 50 yr and 100 yr wrong by 0.05–0.06 (0.44/0.35 against 0.487/0.409) —
the same size as the difference it was being used to judge. Now EVALUATED from the Table 5
fit recorded in DESIGN §6 gate 12 (a₀ 0.2173; aᵢ 0.2240/0.2824/0.2763; τᵢ 394.4/36.54/4.304).
And relabelled: an SSP2-4.5 pulse in 2030 is **not** Joos's PD100 protocol (100 GtC onto a
background HELD at 389 ppm), and DESIGN prices that difference at more than most of the
disagreement. **The gate is `diag_joos_irf.R`, which runs the right protocol and PASSES** —
integrated IRF 12.4 / 25.5 / 41.9 yr inside Joos's 5–95 % at all three horizons, though at
the low end of each, with the point IRF 0.077–0.118 BELOW the multi-model mean throughout.

**What the panel still needs from the model:** `land_C` is leaf + wood + soil_fast +
soil_slow AGGREGATED, so a vegetation-vs-soil bar needs those four exposed as output columns.
The state vector has them; `ccx_run_fast()` does not return them. A column, not a mechanism.

## 2026-08-21 (later still) — §2's ridge is real and aimed at the wrong coordinate; §3's blocker was a false alarm

### §2 step 1 — the falsification test PASSES, and inverts the causal story

`diag_seas_T_amp_q10_ridge.R amp`, PAIRSH tier (q10 + `seas_T_amp_SH` free — the honest
minimal test, since q10 is SHARED between hemispheres and freezing the SH breaks its own
product by construction):

| `A_T` (K) | q10 | product | Δ(seas4) | Δ(rest) |
|---|---|---|---|---|
| 5.0 | 1.4997 | 2.026 | −12.0 | **−100.2** |
| 11.445 | 1.2135 | 2.214 | −0.01 | −12.6 |
| 14.32 (prior centre) | 1.1685 | 2.230 | 0.00 | −5.8 |
| 25.94 (mode) | 1.0905 | 2.248 | −0.33 | −0.1 |
| 50.0 | 1.0461 | 2.251 | −0.58 | −1.0 |

**The four seasonal rows move 0.6 log-units across 11.4 → 50 K** while the product holds to
1.7 %. The coordinates trade one-for-one. The ridge is REAL, exactly as §2 said.

**But the profile is not flat, and all of the non-flatness is in `rest`** — which is the
second of the three outcomes the script pre-registered. The per-stream table names the
payers at `A_T` = 5: `co2_level_MLO` −30.5, `co2_level_SPO` −18.3, `d13c_level_MLO` −13.8,
`co2_icecore` −7.9. Annual and level rows, through q10's `q10^(gmst/10)` duty.

**So the causal story inverts.** It is not two priors fighting over a shared product. It is:
the ANNUAL rows pin q10 near 1.09; the SEASONAL rows pin the product near 2.25; and
`A_T` = 2.25/ln(1.09) ≈ 26 K is then DERIVED. `seas_T_amp_NH` is not being fought over at
all — it is a readout of q10. The seasonal channel is the side that is INDIFFERENT.

**§2 steps 2–4 are therefore NOT run**, and the 15-hour refit is not spent. Re-anchoring
`seas_T_amp_NH`'s prior downward cannot deliver §2's own stated success criterion ("q10
back near 2.0"): it will move `A_T` and leave q10 where it is. The transpose test —
profile q10, re-optimise the amplitudes — separates the two claims in about an hour and is
what decides whether the defect is the amplitude prior or the respiration model itself.
Running.

### §2, CONTINUED — two corrections to what I wrote above, and a computed answer

**Correction 1: the "352 log-units" is an artefact of a frozen block.** The BLOCK tier
freezes `beta_max`, `fert_k` and `luc_scale`. Raising q10 releases more soil carbon under
the observed warming, and the classic β–γ compensation — more fertilisation drawing it
back — is exactly the repair BLOCK forbids. Freeing the three (`land` tier) drops the cost
of q10 = 2.0 from **352 to 50.3** log-units. **The fertilisation pair absorbs 85 % of it.**
This is `match_incumbents_optim` biting: I read a frozen-block profile as if it bounded the
posterior.

**Correction 2: a pure-likelihood objective lets the NUISANCE parameters escape too.** In
the first `land` run `seas_T_amp_SH` went to 1e-23 and `sst_seas_amp_NH` to 1e-31 in EVERY
row — both channels switched off, z = −37.5 apiece — and reported a spread of 15.9. That
profile was internally consistent and it was a profile of a DIFFERENT MODEL. Fixed by an
objective `partial` that drops the priors on the two parameters UNDER TEST and keeps every
other one, with a GATE 3 that prints which are dropped and which kept and checks the
arithmetic at the mode. Under `partial` the parameters stay physical (`seas_T_amp_SH`
0.28–1.31, `sst_seas_amp_NH` 0.38–0.45) and the answer is **50.3**.

**What survives both corrections, unchanged:**

- **The ridge is exact.** The product holds to 2.2609–2.2663 across q10 = 1.09 → 2.0 in the
  PAIRSH tier, and the re-optimised `A_T` at q10 = 2.0 is 3.2695 K against the analytic
  2.2513/ln 2 = 3.2479. Four significant figures.
- **The seasonal rows barely identify q10** — 4.3 log-units across the range (PAIRSH),
  18.5 (`land`, which travels further in `A_T`).
- **cor(q10, `seas_T_amp_NH`) = −0.972** from the Hessian, agreeing with the profile.

**And the arithmetic §2 step 3 was going to spend 15 hours to discover**
(`calibration/diag_seas_reanchor_arithmetic.R`, exact — it re-scores the `land` points
under a re-anchored prior set; no model runs):

| q10 | `A_T` (K) | Δ logpost, CURRENT priors | Δ logpost, DAMPED priors |
|---|---|---|---|
| 1.0907 (mode) | 26.49 | 0.00 | 0.00 |
| 1.35 | 7.81 | −20.2 | **+19.7** |
| 1.50 | 5.86 | −31.2 | +18.1 |
| 2.00 (literature) | 3.45 | **−63.7** | +4.0 |

with the damping applied to **both** land amplitude priors (NH centre 14.32 → 4.06 K, SH
5.05 → 1.43 K; the bracket ends scale, so the centre scales and the width does not).

**So §2's repair does have leverage, and it does not reach its own success criterion.**
The re-anchor flips the sign of the comparison — q10 = 2.0 goes from losing by 63.7 to
winning by 4.0 — but the interior optimum lands at **q10 ≈ 1.35–1.5, `A_T` ≈ 6–8 K**, not
at 2.0. And the decisive lever is the **SH** prior as much as the NH one: `seas_T_amp_SH`
has to fall to 0.28 K to hold the SH product at a large q10, and that is where most of the
50.3 sits.

**Two caveats on that table, both stated rather than buried.** The damping factor 0.2838 is
DERIVED to put the mode's product at the literature q10, so it is the most favourable value
the hypothesis could have — it is not an independent measurement, and §2 step 2's
requirement for provenance stands. And the `land` points were optimised under the CURRENT
priors, so each row is conditioned on the wrong prior and the damped column is a LOWER
bound on what a refit would find.

**Recommendation.** §2 steps 2–4 are worth running, amended: the damping must be applied to
`seas_T_amp_SH` as well, and the pre-registered success criterion should be "q10 moves to
1.35–1.5", not "q10 back near 2.0". If a soil-temperature climatology gives a damping far
from 0.28, that is the falsification and the refit should not be run at all.

### §3 — RESOLVED, and the blocker was smaller than it looked

`recompute_hessian.R` needed three repairs before it could answer anything: it read
`md$u_mode` and decoded it under the DEFAULT parameter table (the arm refit overrode
`h_ml`'s band in process, so this can silently land metres away — `mode_fit_pumpN.rds` as
it stands does round-trip, and GATE 1 now prints both rather than assuming either way); it
**wrote its result back over the mode file**; and its step grid stopped at 3e-4, which is
where `h_ml`'s problem starts.

**The step rule is now DERIVED, not picked off a grid.** The first version of the rewrite
took the largest step whose diagonal curvature agreed with both neighbours, which chose
eps = 1e-1 for nearly everything — a move of 313 log-units for `beta_max` — and returned a
Hessian with a **positive** eigenvalue of +86.8 in the (`beta_max`, `fert_k`) plane, whose
correlation is +0.997. A diagonal-only stability scan cannot see a cross-derivative going
bad. Replaced by

    eps_k = HESS_EPS_FRAC × sd_k,   sd_k = 1/sqrt(−∂²logpost/∂u_k²)

so the objective moves `HESS_EPS_FRAC²/2` = 0.005 log-units in EVERY direction by
construction — about 5,000× above this integrator's noise floor, with a truncation error
of a quarter of a percent. All 21 parameters are then stable to <1 % across eps/3 → 3·eps,
`h_ml` included.

**The cause is not the one §3 proposed.** §3 attributed `h_ml`'s failure to logit
compression near the lower bound. That is true about REACH and wrong about CAUSE:
`ARM_HESS_EPS` = 3e-4 is 0.5–1.8× the right step for the seven STIFF directions (`beta_max`,
`fert_k`, `q10`, `k_w`, `bomb_total`, `luc_scale`, `grad_off_d13c`) and 0.003–0.06× for the
soft ones. It was calibrated on the stiff subspace. `h_ml` is simply the SOFTEST direction
in the model — unconstrained sd 0.888 — so 3e-4 is 296× too small there. **`kz` was
under-stepped 181× and `gamma_enso` 66×, neither near a bound and neither flagged**,
because their curvature happened to survive the noise at 3e-4. The instability report was
UNDER-reporting.

**And the answer is that it barely mattered.** Recomputed against stored:

- `log|−H|` **127.0986 vs 127.1280** — a change of 0.03, against arm margins of 5.6–10.6.
- `h_ml`'s sd moves **2 %**. Every other parameter moves **< 0.5 %**.
- −H is positive-definite; all 21 eigenvalues negative.

**So the handoff's "⚠ NO UNCERTAINTIES ARE QUOTABLE" was over-cautious.** The right call on
the evidence available then, but the actual damage is 2 % on one parameter's sd. The
uncertainties in `mode_fit_pumpN.rds` were usable all along. What the work buys is that
they are now VERIFIED rather than assumed, that the step is derived and recorded, and that
the instability flag would now catch something real.

**Two numbers worth carrying forward, both new:**

- **`q10` = 1.0907 ± 0.0193.** The literature 2.0 is **47 posterior sd away**. The prior
  (logsd 0.25) is nowhere near strong enough to matter; this is a model-vs-literature
  conflict on q10, not a prior-tuning question, and no re-anchoring of a seasonal
  amplitude will touch it.
- **cor(`q10`, `seas_T_amp_NH`) = −0.972** — the ridge, quantified from second-order
  information, independently of the profile. Strong, and NOT degenerate: a pure product
  ridge would be −0.999 or tighter.

Also: cor(`beta_max`, `fert_k`) = **+0.997**, the Michaelis-Menten pair, which is the
tightest degeneracy in the model and the one that broke the naive step rule.

`mode_fit_pumpN.rds` is NOT modified; the second-order block is written beside it as
`mode_fit_pumpN_hess.rds` and `--update` is required to write it back.



## 2026-08-09 — Project created; design locked (no code yet)

- Repo created as a sibling of FaIRtoFrEDI (design conversation ran from a FaIRtoFrEDI
  session; this project is independent of that pipeline).
- Core design decisions made by Marcus:
  - **R end-to-end** (model + MCMC + Shiny), Rcpp core only if speed demands it.
  - **Box-diffusion ocean** (Oeschger-style column per hemisphere) over discrete-box and
    HILDA alternatives — bomb-¹⁴C penetration is the key ventilation constraint.
  - **¹²C + ¹³C + ¹⁴C** — δ¹³C added for the Suess land/ocean partition constraint;
    Δ¹⁴C fractionation-corrected data lets ¹⁴C run without fractionation bookkeeping.
  - **App = historical + scenarios**: counterfactual toggles, SSPs, stylized pathways, and
    matched pulse/baseline experiments. Public deployment on shinyapps.io.
  - **Audience: undergrad environmental-studies major.**
- Alternatives considered and set aside (with reasons) are recorded in DESIGN.md §2 and
  the v2 backlog (§10): discrete-box ocean (weaker use of bomb spike), HILDA (too many
  parameters to communicate), Python-calibrate/R-port (port-parity risk), Julia+Shiny
  bridge (deployment fragility on shinyapps.io), user-drawn emissions (deferred).
- DESIGN.md written; awaiting Marcus sign-off before any model code.

## 2026-08-09 (later) — Design approved; data layer built

Marcus took the defaults on all four open questions (§9): GCB land sink as a soft
constraint, joint-calibrated seasonal harmonics, reuse of RCMIP SSP CSVs, Rcpp core
permitted with a bit-parity test.

**Acquired 14 datasets** (`data-raw/download_data.R` → `MANIFEST.csv` with URL, access
date, SHA-256, citation; parsed by `data-raw/build_calibration_data.R` → `data/*.rds`).

**Source substitutions forced by upstream availability — all flagged, none silent:**

- **Scripps CO₂ Program is unreachable.** Every `scrippsco2.ucsd.edu/assets/...` path
  returns 404 (tested with and without a browser user-agent; search engines still index
  the old URLs). Consequences: South Pole CO₂ comes from the NOAA CCGG flask record and
  therefore **starts 1975 instead of 1957**, and Scripps δ¹³C (1977+) is unavailable.
  *Not treated as fixed* — revisit; the 1957–1975 SH gap is a real loss for the bomb era.
- **δ¹³C is thinner than planned.** NOAA/INSTAAR monthly flask δ¹³C runs **1990–2014
  only** (MLO; SPO 1993–2014). With Law Dome ending 1993 there is no δ¹³C constraint
  after 2014. The Suess sink-partition constraint is correspondingly weaker; the post-2014
  gap must not be read as agreement.
- **MEI.ext has been retired by NOAA PSL** (404), so the planned MEIv2 + MEI.ext splice is
  impossible. Both MEIv2 (1979+) and Niño 3.4 (1948+, anomalized against a 1991–2020
  climatology) were acquired. **Choice of which drives the ENSO term is deferred to
  Marcus** — Niño 3.4 is the only option covering the full dense-CO₂ era in one product.
- **Law Dome δ¹³C lives in a separate NCEI file** (`law2018d13c-co2.txt`), and the spline
  composite (`law2018splines.txt`) provides smooth annual CO₂ (154–1996 CE) and δ¹³C
  (1020–1993 CE) series — better pre-instrumental targets than the raw sample list.
  Parser gotcha: that file has **two different columns both named `age_CO2`** (CO₂ and
  δ¹³C splines are on different time axes), so it must be parsed positionally.
- **Hua et al. (2022) Δ¹⁴C obtained via `SoilR::Hua2021`** — the package ships the paper's
  Supplementary Material 2 (5 zones, monthly mean + sd, 1941–2019), which avoids a
  publisher-supplementary download and fits the R-end-to-end constraint.

**Sanity-gate targets are now data-derived, replacing recalled values in DESIGN.md §6.**
Where they differ from the working values written at design time, the data wins:
NH Zone 1 bomb peak is **944.6 ‰ at 1963.625** (design said "order 1000 ‰"); post-peak
e-folding **15.4 yr** (design said ~16); airborne fraction **0.431** over 1959–2024
(design said "mid-0.40s"); preindustrial CO₂ **276.88 ppm** and δ¹³C **−6.469 ‰**.
MLO seasonal amplitude grows 5.95 → 6.86 ppm (1960s → 2010s), and the MLO−SPO gradient
grows 1.70 → 4.36 ppm (1970s → 2020s).

**Still outstanding:** bomb ¹⁴C production history (atmospheric test-yield series) and the
optional ocean bomb-¹⁴C inventory constraint.

## 2026-08-09 (later still) — Carbonate chemistry module

`R/carbonate.R` + `data-raw/build_carbonate_tables.R` + `tests/testthat/test-carbonate.R`.

**Approach:** dissociation constants are NOT hand-copied from papers. `seacarb` (a
maintained, cited implementation) is queried over the model's temperature range and
polynomials in T are fitted to ln K0/K1/K2/Kb/Kw. seacarb is the cited authority; the
fitted coefficients are a reproducible derivative; the test suite gates the fast solver
against seacarb's full system. The solver itself is a closed-form carbonate-alkalinity
quadratic seed plus Newton refinement — pure arithmetic, so it ports to Rcpp unchanged.

**Final accuracy vs seacarb:** pCO₂ to **2.2e-5** relative, Revelle factor to **1.3e-6**,
over DIC 1900–2400 µmol/kg × T 10–30 °C. Test tolerances set at 1e-4 (≈5× and ≈75×
headroom) so a real regression trips them.

**Three bugs found and fixed by the seacarb gate — each would have survived a plausibility
check.** Recorded because all three are the "looks fine, is wrong" class:

1. **Missing OH⁻ in the alkalinity balance → −4.5 % in pCO₂.** The water term is only
   ~0.25 % of total alkalinity, but pCO₂ amplifies an alkalinity error by roughly the
   Revelle factor (~10×). Do not "simplify" it away.
2. **[CO2*]/K0 is fugacity fCO₂, not partial pressure pCO₂** — a systematic −0.30 to
   −0.38 % bias, temperature-dependent. Fixed by storing an effective
   K0_eff = K0 × φ(T), with φ = 0.99572 (2 °C) … 0.99717 (35 °C) taken from seacarb.
   This one matters because it biases the air–sea gradient and hence the ocean sink in
   one direction at all times.
3. **Polynomial fits in raw T are badly conditioned** once T⁵ ~ 5e7; fitting in centred,
   scaled x = (T−T₀)/Ts improved K0/K1/K2/Kb from ~1e-7 to ~1e-9. The scaling is stored
   with the coefficients, and evaluation always applies it.

**Not a bug — a wrong test.** The Revelle factor is *not* monotonic in DIC all the way up:
it peaks near DIC ≈ 2250 µmol/kg (at ALK 2300) and falls beyond, because carbonate ion is
nearly exhausted at pH ~7.1. seacarb reproduces the turnover identically, so the assertion
was corrected to the DIC < ALK range the model actually visits, rather than the code.

**Kw carries a documented tolerance waiver.** seacarb's own Kw output has a ~1.7e-3
oscillatory wiggle (largest at 2–12 °C) that is unchanged by raising the polynomial degree
to 10 or by using the physical (1/T, lnT, T) basis — i.e. upstream numerical noise, not a
fitting failure. Kw is therefore allowed 5e-3 while the others are held to 1e-6, and the
waiver is gated by a test that perturbs Kw by a full tolerance width and requires the pCO₂
response to stay under 1e-4.

**Also added:** `R/paths.R` (`ccx_root`/`ccx_path`) so scripts, testthat (which runs from
`tests/testthat/`) and the Shiny app (which will run from `app/`) all resolve `data/`
identically; `tests/run_tests.R` as the suite entry point.

## 2026-08-09 (cont.) — Three flagged choices resolved by Marcus

- **ENSO index = Niño 3.4 (1948+)**, anomalized against a 1991–2020 climatology. One
  homogeneous product covering the whole dense-CO₂ era, no splice. MEIv2 stays in `data/`
  as a sensitivity option. (MEI.ext retirement made the original plan impossible.)
- **Δ¹⁴C zone → hemisphere aggregation = AREA-WEIGHTED**, with the zone latitude
  boundaries to be read out of Hua et al. (2022) rather than assumed. Note the tropical
  zone boundaries follow the ITCZ and migrate seasonally — the weighting scheme must state
  how it handles that (fixed annual-mean boundaries is the intended simplification).
- **Bomb ¹⁴C = prescribed yield-history SHAPE with calibrated total P_bomb.** The model
  therefore *predicts* the Δ¹⁴C spike rather than fitting it, keeping ¹⁴C as an
  independent check and preserving the app's isotope narrative. Outstanding dependency:
  a citable annual atmospheric-test-yield series.

## 2026-08-09 (cont.) — Scripps South Pole records supplied; both gaps closed

Marcus supplied the four Scripps South Pole files by hand (the website is still 404
site-wide). They live in **`data-raw/manual/`** and are **committed to git** — unlike
`data-raw/downloads/`, they cannot be regenerated, so losing them loses the data.
`data-raw/manual/README.md` records contents, citation, and the column trap.

**Both previously-flagged gaps are closed:**
- **SH CO₂ now 1957-06 → 2024** (n=711 real monthly values) instead of NOAA's 1975+
  (n=583). This recovers the entire bomb era on the SH side.
- **SH δ¹³C now 1977-03 → 2024** (n=528) instead of NOAA's 1993–2014 (n=258). The
  post-2014 hole is gone and the record extends 16 years further back.
- NOAA's SPO CO₂ and δ¹³C are retained as **independent cross-checks**, not extra
  likelihood terms.

**Column trap, documented in code and README.** The Scripps monthly files have 10 columns;
**only column 5 is a real observation** — columns 7–10 are fit, seasonally-adjusted and
gap-filled reconstructions that are fully populated even where nothing was measured (the
1957 row has CO₂ = NaN but fit = filled = 312.74). Parsing a filled column would have
invented ~100 monthly "observations", including all but 11 of the 36 months in the 1950s,
and would have understated calibration uncertainty. The parser takes column 5 and keeps
the NaNs.

**Scripps SPO Δ¹⁴C (1999–2007, n=81) is VALIDATION ONLY, not a likelihood term.** Its
range (51.9–97.9 ‰) sits on top of Hua et al.'s SHZone1-2 over the same window
(53–95.9 ‰) because this station is one of the records feeding that compilation. Using
both would double-count the same measurements. Saved to
`data/obs_d14c_spo_validation.rds` for checking the zonal aggregation independently.

**New finding — inter-network scale offset.** Over 543 months where both networks report
at South Pole, **Scripps − NOAA = −0.134 ± 0.262 ppm** (2012 SIO manometric vs WMO scale).
Because MLO is NOAA and SPO is Scripps, this offset lands directly inside the MLO−SPO
gradient — 3–8 % of a gradient that is a primary constraint on τ_ex. **Open item:** obtain
Scripps *Mauna Loa* records so both stations share one scale, or carry a calibrated
network-offset nuisance parameter. Not silently absorbed.

**Updated data-derived benchmark — the interhemispheric gradient now spans the full
record:** 0.04 ppm [9 paired months] (1950s) → 1.05 [75] → 1.65 [113] → 2.31 [117] →
2.61 [118] → 3.09 [115] → 3.83 [117] → 4.38 [45] (2020s partial). It grows from
essentially zero at the start of the record to 4.4 ppm today, tracking cumulative NH
fossil emissions. Earlier decades shifted modestly versus the NOAA-based numbers (1970s
1.70 → 1.65, 2000s 2.74 → 3.09) — mostly different month sampling rather than the scale
offset, so the paired-month estimate above is the reliable one. δ¹³C Suess trajectory
is now −6.469 ‰ (preindustrial) → −8.580 ‰ (2024).

The `daily_flask_co2_isotopes_spo.csv` file (daily CO₂, CH₄, CO, ¹³C, ¹⁸O, ¹⁴C) is
retained as provenance but unused in v1, which is a monthly model.

## 2026-08-10 — Scripps Mauna Loa records added; both stations on one scale

Marcus supplied the MLO counterparts. There is no MLO "merge" file — MLO has a genuine
**in-situ continuous** record (`monthly_in_situ_co2_mlo.csv`, 1958–2026, n=812 real), which
is better than a merge; SPO is flask-dominated, hence its merge product. Also added:
`monthly_flask_c13_mlo.csv` (1980–2024, n=532), `monthly_flask_co2_mlo.csv` (cross-check),
`intermittent_flask_c14_mlo.csv` (2001–2007, validation only — feeds Hua's NH zones).

**Both stations now sit on the 2012 SIO manometric scale (CO₂) and the Scripps isotope
scale (δ¹³C).** NOAA records are retained as cross-checks, not extra likelihood terms.

**Parser trap:** missing-value markers differ *between Scripps files*. The merge and flask
files use `NaN`; `monthly_in_situ_co2_mlo.csv` uses **−99.99**. Left unhandled, −99.99
sails through as a real observation and poisons every mean it touches. Both are handled.

### Finding 1 — the inter-network offset is NOT a constant

Measured where both networks report: Scripps − NOAA = **−0.201 ± 0.217 ppm** at MLO
(n=812) and **−0.134 ± 0.262 ppm** at SPO (n=543). By decade, though, the MLO offset runs
0.000, 0.000, +0.04, −0.36, −0.31, −0.38, −0.17, −0.29 ppm — it **wanders by ~0.3 ppm**,
so no single constant corrects it. SPO behaves similarly (+0.25, −0.22, −0.24, −0.28,
−0.06, +0.06).

The exact **0.000 ± 0.002 ppm for 1958–1969** is itself informative: NOAA's early MLO
product *is* the Scripps record, so those years were never an independent cross-check.
Worth remembering before treating NOAA-vs-Scripps agreement as corroboration anywhere.

Using Scripps for both stations removes the mixed-network bias (which would have been
+0.134 ppm on the gradient). What remains is a ~0.07 ppm genuine disagreement between
networks about the gradient — absorbed by the error model as uncertainty, not corrected.

### Finding 2 — my own gradient benchmark was aliasing the seasonal cycle (BUG, FIXED)

The MLO−SPO gradient was being computed from **raw** monthly means over whatever months
happened to be paired. MLO has a ~6 ppm seasonal cycle against SPO's ~1 ppm, so uneven
month coverage injects seasonality straight into the "gradient". The 1950s were the
extreme case: 8 paired months, 5 of them Aug/Sep (MLO's seasonal minimum), producing a
spurious **negative** gradient of −0.30 ppm — physically backwards, and it had already
been written into DESIGN.md §6 as a data-derived target.

Fixed by computing the gradient from the **seasonally adjusted** column both Scripps
products ship. Effect by decade (raw − adjusted): 1950s **−0.77**, 1960s +0.20,
2020s +0.13, and ≤0.03 ppm for every well-covered decade — i.e. concentrated exactly where
coverage is sparse, as the diagnosis predicted.

**Corrected benchmark, seasonally adjusted, both stations on the Scripps scale:**
0.47 [8 paired months] (1950s) → 0.85 [75] → 1.66 [113] → 1.96 [117] → 2.32 [118] →
2.72 [115] → 3.66 [117] → 3.97 ppm [45] (2020s partial). The 1950s entry remains
indicative only.

δ¹³C Suess trajectory is now two-hemisphere on one isotope scale: −6.469 ‰ (preindustrial,
Law Dome) → −8.700 ‰ (MLO 2024) / −8.580 ‰ (SPO 2024).

## 2026-08-10 — Nuclear-industry ¹⁴C source PROMOTED to v1 (assumption overturned)

Marcus proposed the Bristol/Zenodo compilation of nuclear-industry gaseous ¹⁴C emissions.
It is **not** the bomb source — it covers routine reactor and reprocessing releases — but
checking it against the v1 spec overturned an assumption I had written there.

DESIGN.md §3.5 previously said "Nuclear-industry ¹⁴C source: omitted in v1 (small), v2".
That "small" was never verified. It is wrong in the way that matters.

**Magnitude check.** Summing the annual files (GBq → mol via λ = ln2/5700 yr;
1 GBq = 4.309e-4 mol ¹⁴C): total industry release is **1.165 kmol**, i.e. **1.14 % of the
~102 kmol bomb production** — which is what makes "small" superficially plausible. But the
*time profiles are opposite*. Industry releases grow monotonically —
0.20 → 1.10 → 4.12 → 8.08 → 17.51 → 25.62 → **42.47 mol/yr** by the 2010s — while the bomb
spike decays and is absorbed.

Against a 2010s atmospheric inventory of **86.1 kmol ¹⁴C** (880 GtC at R_std = 1.176e-12 —
note this is comparable to total bomb production, consistent with the bomb roughly doubling
atmospheric ¹⁴C at its ~+900 ‰ peak), 42.5 mol/yr is **+0.49 ‰/yr**. The observed NHZone1
trend over 2005–2019 is **−4.30 ‰/yr**. So the industry source is **~11 % of the modern
observed tendency** — far too large to drop from a model whose whole point is to reproduce
the Δ¹⁴C record.

Two bounding caveats push opposite ways: +0.49 ‰/yr is an **upper** bound (assumes all
released ¹⁴C stays airborne; it actually partitions into ocean and land), while the
emissions sum is a **lower** bound (coverage gaps — USA only 2010–2023, France NPP 2005+).
11 % is the right order of magnitude, not a precise number.

Emissions are almost entirely Northern Hemisphere, so this term also projects onto the
NH−SH Δ¹⁴C difference — the same signal that constrains τ_ex. Added to
`download_data.R` (9 annual files, CC-BY-4.0, doi:10.5281/zenodo.15034663).

**Bomb-source prior now sourced.** Naegler & Levin (2006), *Closing the global radiocarbon
budget 1945–2005*, JGR 111, doi:10.1029/2005JD006758: total bomb ¹⁴C production 1945–1980
= **99.3–104.9 kmol** (598–632 × 10²⁶ atoms). That fixes the prior on the calibrated
P_bomb. **Still outstanding: the time SHAPE** — an annual atmospheric test-yield series
(UNSCEAR 2000 Annex C is the standard compilation).

## 2026-08-10 — Model core: 84-state box model, conservation gates, mutation testing

`R/model.R` (two-hemisphere, monthly, ¹²C/¹³C/¹⁴C), `R/constants.R` (provenance-tagged
constants), `tests/testthat/test-conservation.R`, `tests/testthat/test-constants.R`.
Suite: **120 passing**.

**Conservation by construction, not by accuracy.** Every internal transfer is emitted once
by `add_flux()` and applied with opposite sign to its two boxes, so total carbon has zero
derivative at every RK stage and is conserved to roundoff at *any* step size. Measured:
**2.2e-16** relative drift over a 100-year integration, and identical at 1, 4 and 16
substeps per month — a step-size-*dependent* conservation error would prove the flux form
was broken.

**Tracer scaling.** ¹⁴C is carried as C × (R14/R14_STD), i.e. "GtC carrying standard ¹⁴C
content", so Δ¹⁴C = 1000·(C14/C − 1) falls out directly and state values stay O(1–1000)
rather than O(1e-12). ¹³C carries fractionation on every flux; **¹⁴C deliberately does
not**, because Δ¹⁴C is fractionation-corrected by convention and C14/C *is* that corrected
ratio. Both facts are stated in the file header — the ¹⁴C one is easy to "fix" into a bug.

### Mutation testing found an inert gate (and a real bug)

The suite passed on first run, so the gates were deliberately attacked by mutating the
source and checking the tests fail. Against a 1e-10 threshold and a 2.2e-16 baseline:

| Mutant | Drift | Result |
|---|---|---|
| One-sided diffusive flux | 3.9e-01 | caught |
| Receiver flux +1 % | 3.6e-02 | caught |
| Receiver flux +0.001 % | 3.5e-05 | caught |
| ¹⁴C decay with Libby 5568 yr | **identical to baseline** | **MISSED** |

The flux gates are extremely sensitive — a 0.001 % asymmetry lands eleven orders above
threshold. But the ¹⁴C decay gate was **inert**, and the reason was a genuine bug:
`LAMBDA_C14` was written as the literal `log(2)/5700` while being *labelled* "derived" from
`T_HALF_C14`. It was an independent copy, so changing the half-life left the decay rate
untouched. `MOL_C14_PER_GBq` had the same flaw.

Fixed by defining `.T_HALF_C14`, `.M_C`, `.SEC_PER_YR`, `.AVOGADRO` once at the top and
referencing them — the constants-file analogue of the standing "labels derive from named
constants" rule. The Libby mutant now produces 1.4e-04 against a 4.7e-10 baseline, and
`test-constants.R` asserts each derivation directly so the decoupling cannot return.

**Lesson recorded:** a passing suite says nothing about whether the gates can fail. Mutate
before trusting.

### Performance: pure R is 527× off target, as expected

A 350-year monthly run (4,200 months, 67,200 derivative evaluations) takes **26.4 s**
against the 50 ms target. Pure R stays as the readable *reference implementation*; the
production core goes to Rcpp under the approved Q4 default, with a bit-parity test against
this reference. Known R-side overheads to remove in the port: `ccx_const()` does a string
lookup per flux per stage, `carb_constants()` re-evaluates five polynomials per hemisphere
per stage, and `add_flux()` is a closure using `<<-`.

**Still provisional (8 constants, ledgered in `test-constants.R`):** ocean areas and depth,
surface alkalinity, seawater density, preindustrial NPP, the SST–pCO₂ sensitivity (which
must be checked for double-counting against the carbonate module's own T dependence), and
the 1750 Δ¹⁴C, which is currently **set to 0 by construction** rather than measured.

## 2026-08-10 — Natural ¹⁴C production, IntCal20 background, and a gross-flux physics fix

Marcus asked whether a natural ¹⁴C source and background rate were needed. Both yes, and
answering it exposed a structural bug in the derivative. Suite: **138 passing**.

### Natural production is not optional

Unbalanced decay (λ = 1.216e-4/yr) drifts atmospheric Δ¹⁴C by **−24.0 ‰ over 200 yr** and
**−41.7 ‰ over 350 yr**. The pre-bomb Suess decline the model must reproduce is
**−26.6 ‰** (IntCal20, 1750→1950). Without a cosmogenic source the artefact is *larger
than the signal*.

**It is solved for, not prescribed.** `ccx_spinup()` finds the production rate that holds
atmospheric Δ¹⁴C at its 1750 value in steady state, given the model's own inventory and
ventilation. The canonical cosmogenic estimate (~2.04 atoms/cm²/s ≈ 545 mol ¹⁴C/yr) is
therefore an **independent validation**, not an input. Derived value: **360 mol/yr,
ratio 0.66**. Consistent with the model's ocean inventory (32,827 GtC) sitting ~14 % below
the canonical ~38,000 GtC, plus the published spread in production (1.6–2.5 atoms/cm²/s).
A factor-2 miss would have meant a units bug; 0.66 does not. Gated at 0.5–2.0.

### Background level: IntCal20 replaces a placeholder

`D14C_PI` was **0 by construction**. IntCal20 (via `rintcal`) gives **+2.16 ‰ at 1750** —
the placeholder was wrong by ~8 % of the whole pre-bomb decline it has to reproduce.
IntCal20 also supplies a **1700–1950 pre-bomb Δ¹⁴C target**, covering the 1750–1941 window
Hua et al. leaves empty. Conversion uses both reporting constants — F14C = exp(−age/8033)
(Libby mean life, age convention) and Δ¹⁴C = 1000(F14C·exp(calBP/8267) − 1) (5730-yr mean
life, Stuiver–Polach convention) — **neither of which is the model's decay constant**,
which uses the true 5700-yr half-life. All three coexist correctly; conflating them is a
classic ¹⁴C error, so it is spelled out in the parser.

**Independent cross-check:** IntCal20 vs Hua NHZone1 over their 1941–1950 overlap agree to
**0.90 ‰ mean absolute difference** — tree rings vs atmospheric compilation.

### Physics bug: isotopes need GROSS fluxes, not net

The spinup's isotope operator came out **exactly singular**. Cause: isotopes were carried
at the source box's ratio on the **net** carbon flux, and at equilibrium the net fluxes are
zero — so no isotope crossed any interface. Physically wrong: air–sea gross exchange is
~80 GtC/yr each way against a ~2 GtC/yr net, and it is the *gross* exchange that
equilibrates ¹³C and ¹⁴C. Fixed by:

- **air–sea** emitted as two one-way gross fluxes (invasion and evasion), which also
  required splitting the ¹³C fractionation into a kinetic factor on invasion and an
  equilibrium factor on evasion — a single "net" α cannot represent two-way exchange;
- **interhemispheric exchange** likewise gross both ways (this is what carries the
  bomb-spike NH→SH propagation signal);
- **ocean diffusion** applied to each tracer on **its own gradient**, not to the net carbon
  flux times a ratio — this is what builds deep-ocean ¹⁴C depletion where net flux vanishes.

Conservation was unaffected (all gates still exact); the rewrite is antisymmetric per tracer.

### Free check that passed

Deep-ocean Δ¹⁴C emerges at **−194.7 ‰** against observations of roughly −150 to −200 ‰.
Nothing in the spinup targets it — it falls out of Kz, ocean geometry and decay. Now gated.

Spinup residuals: |dC/dt| 6.3e-09 GtC/yr, |dC13/dt| 8.9e-16, |dC14/dt| 6.6e-14; CO₂, δ¹³C
and Δ¹⁴C reproduce their targets to 1e-6. Integrating the spinup state forward 50 yr moves
CO₂ by <1e-4 relative and Δ¹⁴C by <0.05 ‰.

## 2026-08-10 — Forcing assembly, first end-to-end run, and DATA.md

`R/forcing.R`, `tests/testthat/test-forcing.R`, and **[DATA.md](DATA.md)** — a single
document covering every source, its traps, and the code that assembles it.
Suite: **167 passing**.

### Two conservation bugs in the forcing assembly, both silent

Annual→monthly interpolation must preserve annual totals: emissions drive cumulative
carbon, so an interpolation that changes annual sums changes the answer while looking
perfectly smooth.

1. **Splining the bomb-¹⁴C series inflated its prescribed total by 4.3 %.** A natural
   spline undershoots either side of the sharp 1962 peak; clipping those negatives back to
   zero *adds* mass. Fixed with a `method = "constant"` (piecewise-constant, exactly
   conserving, cannot undershoot) branch, now used for all sharply peaked non-negative
   sources. The underlying data are annual anyway, so smoothing was never justified.
2. **Masking source records with decimal time dropped the entire final year of each.**
   Month-centred `t` for year Y runs Y.04…Y.96, all of which satisfy `t > Y`. Cost another
   0.28 % of the bomb total, and silently truncated the last year of nuclear ¹⁴C. Masks now
   compare integer years.

Both are gated: cumulative fossil emissions must match GCB to 1e-10, and the bomb total
must be set by its citable prior rather than by the provisional shape (tested at three
different totals, since a shape that set the amplitude would pass a single-value test).

### First full historical run, 1750–2024

Runs end to end in 20 s. With **uncalibrated** default parameters:

| Quantity | Model | Observed |
|---|---|---|
| CO₂ 2024 | 464 ppm | 421 |
| Airborne fraction 1959–2024 | 0.519 | 0.431 |
| Ocean / land sink 2015–24 | 2.82 / 1.97 GtC/yr | 3.22 / 2.36 |
| δ¹³C 2024 NH | −9.30 ‰ | −8.70 |
| Δ¹⁴C peak | +998 ‰ at 1963.0 | +945 ‰ at 1963.6 |
| Δ¹⁴C 2019 NH | +14 ‰ | ~+5 |

Every discrepancy points the **same direction** and reduces to one cause: sinks too weak →
airborne fraction too high → CO₂ too high → δ¹³C too depleted (extra fossil carbon left
airborne). That internal consistency is the reassuring part — CO₂ high *with* δ¹³C
enriched would indicate a bug rather than a parameter miss. β, k_w and Kz are guesses.

The Δ¹⁴C bomb peak landing within 5 % of observed in both height and timing is encouraging
given the provisional shape, but **must not be read as validation** — the shape is a
placeholder and the amplitude comes from the Naegler & Levin prior.

### DATA.md

Documents the three-stage pipeline (acquire → parse → assemble), all calibration targets,
all forcings, the cross-checks that compare independent datasets, every assembly decision
as a named constant, the outstanding gaps, and licences. Records the traps found so far:
the Scripps column-5 rule, per-file missing-value markers, duplicate `age_CO2` columns,
non-constant inter-network offsets, the seasonal-aliasing rule for the gradient, the three
distinct ¹⁴C time constants, and why MLO flask data cannot replace the in-situ record.

## 2026-08-10 — Rcpp production core: 479× speedup, parity gated and mutation-tested

`src/ccx_core.cpp` + `R/cpp.R` + `tests/testthat/test-parity.R`. Suite: **177 passing**.

**Performance.** A full 1750–2024 monthly run drops from **26.4 s to 0.019 s** — 479×,
and comfortably inside the 50 ms budget that keeps a 1e5-evaluation MCMC under ~1.5 h.
R/model.R remains the reference implementation; the C++ is a port, and any physics change
must be made in both.

**"Bit-parity" was optimistic — the honest number is roundoff.** The two implementations
are NOT bit-identical. Measured over an 81-year integration (15,552 derivative
evaluations): CO₂ agrees to **8.3e-16 relative**, δ¹³C to 7.8e-13 ‰, Δ¹⁴C to 1.1e-12 ‰,
final state to 2.8e-13 absolute against state values of ~5.5e3.

The irreducible source is **catastrophic cancellation in deep-ocean ¹⁴C tendencies**, where
the diffusive flux and decay very nearly cancel: an ulp there is unbounded in *relative*
terms while staying ~1e-16 absolute. Tried and rejected: switching the carbonate polynomial
from an incremental `xp *= x` to `std::pow(x, i)` to match R's `x^i` exactly — this changed
the disagreement **not at all** (2.842e-13 either way), so the ulp difference is elsewhere,
and the incremental form was kept for being ~15 % faster. The gate therefore uses
scale-relative tolerances rather than per-cell relative ones, since a cell whose value is
1e-16 has meaningless relative error.

**The parity gate is mutation-tested,** because a tolerance chosen for roundoff must be
shown to still catch real porting errors:

| Mutant | CO₂ rel | δ¹³C abs | Δ¹⁴C abs | |
|---|---|---|---|---|
| (unmutated) | 8.3e-16 | 7.8e-13 | 1.1e-12 | passes, correctly |
| P1 wrong hemisphere on nuclear ¹⁴C share | 8.3e-16 | 7.8e-13 | **3.3e-01** | caught |
| P2 dropped ¹³C equilibrium fractionation on evasion | 8.3e-16 | **5.9e+00** | 1.1e-12 | caught |
| P3 off-by-one in ocean diffusion index | **5.0e+00** | 6.4e+00 | 9.0e+02 | caught |
| P4 one Newton iteration instead of six | **3.1e-02** | 1.2e-01 | 3.0e+01 | caught |

Real porting errors land 10–15 orders of magnitude above the roundoff floor.

**A flaw in my own mutation harness, worth recording.** The first pass scored mutants on
CO₂ and Δ¹⁴C only, and reported P2 as MISSED. P2 perturbs the ocean→atmosphere ¹³C
fractionation and therefore shows up *only* in δ¹³C — which the real test file does check,
but my harness did not. The lesson is the same one as the earlier inert-gate finding: a
mutation test is only as good as the observables it scores. Each of P1/P2/P3 is caught by a
*different* tracer, so all three must be scored.

**Also gated independently of R:** the C++ core conserves carbon to 1e-12 over a century on
its own terms (not merely by inheritance from the reference), and the runtime budget itself
is asserted, so a future slowdown fails the suite rather than being discovered during
calibration.

## 2026-08-10 — Calibration machinery; two findings that changed the design

`R/likelihood.R`, `R/calibrate.R`, `calibration/run_pilot.R`. 18 parameters,
0.058 s per posterior evaluation (spinup + 275-yr run + likelihood).

### Finding 1 — Δ¹⁴C zone→hemisphere weighting is NOT immaterial

Marcus chose area-weighted aggregation (2026-08-09) with the boundaries to be read from
Hua et al. (2022) rather than assumed. Reading them: the zones are **not latitude bands**.
Boundaries follow the polar jet and the tropical low-pressure belt, move seasonally, and
differ by longitude — in some regions the Equator is used, in others the mean DJF TLPB
position. The paper explicitly calls for more sites to pin them down.

Measured spread of the NH aggregate across defensible schemes:

| Scheme | bomb peak | max diff vs Hua-2013 bands | post-1970 |
|---|---|---|---|
| area, 40/15 bands | 853.2 ‰ | — | — |
| area, 47/20 bands | 829.9 ‰ | 25.7 ‰ | 3.9 ‰ |
| equal weights | 834.4 ‰ | 20.8 ‰ | 4.2 ‰ |
| NHZone1 alone | 944.6 ‰ | 94.3 ‰ | 20.9 ‰ |

Hua's own reported sd is 0.5–6.7 ‰, so the weighting spread during the bomb peak is
**4–50× the measurement uncertainty** — precisely where the bomb constraint operates. It
is therefore added in quadrature as representation error (25 ‰ in 1955–1970, 4 ‰
elsewhere) rather than ignored.

### Finding 2 — a likelihood decomposition stopped a placeholder from driving the posterior

Decomposing the log-likelihood at the default parameters:

| stream | n | logLik | share |
|---|---|---|---|
| Δ¹⁴C NH + SH | 1875 | −165,214 | **90 %** |
| CO₂ ice core | 255 | −14,551 | 8 % |
| CO₂ MLO + SPO | 1523 | −4,234 | 2 % |
| everything else | ~400 | ~−800 | <1 % |

Δ¹⁴C carried **90 % of all the information while the bomb injection shape is still a
placeholder**. Calibrating in that state would have laundered a provisional input into
every parameter, and nothing in the output would have looked wrong. Three changes:

- **Bomb-window Δ¹⁴C (1950–1975) excluded by default** (`LIK_USE_BOMB_WINDOW = FALSE`),
  with a message printed whenever it is dropped. Pre-bomb IntCal20 and post-recovery Δ¹⁴C
  are kept, so ¹⁴C still constrains ventilation through the Suess decline and post-peak
  decay.
- **Total bomb production `bomb_total` is now a calibrated parameter** with the citable
  Naegler & Levin (2006) prior (99.3–104.9 kmol, entered as lognormal σ=0.10). This was
  always the design's intent, and it lets shape error be partly absorbed into magnitude
  so post-peak Δ¹⁴C remains usable rather than being discarded. **Residual shape
  dependence remains** — see DATA.md §8.
- **Ice-core error inflated** by 4 ppm in quadrature. Law Dome's stated errors are
  analytical only (~0.02–1 ppm) and exclude gas-age, firn-smoothing and
  model-vs-ice representation error; uninflated, 255 samples at ~9σ contributed 8 % of the
  total from the sparsest, least direct record in the set. Its contribution fell
  −14,551 → −1,589.

### Data-layer bug found while wiring the likelihood

`fread(skip = "SampleID")` on the Law Dome sample files matched the NOAA
**variable-description block** (`## SampleID<tab>Sample ID, ...`) tens of lines above the
real header, parsing comment text as data: 334 rows of junk in `V1..V14`. It had been
latent since the first build because the benchmarks use the splines and nothing read the
samples until now. Fixed by anchoring on `^SampleID`; now yields 321 CO₂ and 105 δ¹³C
samples with their proper columns.

### Design notes carried in the likelihood

AR(1) residuals on the dense CO₂ and δ¹³C series with calibrated ρ (1500 monthly points
against 18 parameters are not independent); GCB sinks as a **partition** constraint only,
since atmospheric growth is already pinned by the CO₂ series; land sink at 3× inflated
σ per Marcus's Q1 default; station-vs-box representation error on CO₂ and δ¹³C.
Parameters are sampled on transformed scales with the **Jacobian applied explicitly** —
omitting it silently reshapes every prior.

## 2026-08-10 — Pilot MCMC: NOT converged (the pilot doing its job)

1500 iters × 4 chains, seed 2026, 4.4 min → `calibration/output/pilot_fit.rds`.

| Diagnostic | Value | Target |
|---|---|---|
| worst R̂ | **4.53** | < 1.05 |
| min ESS (bulk) | **4** of 3000 draws | ≥ 400 |
| acceptance | 0.045–0.063 | ~0.234 |
| log-posterior | −93,775 → −6,727 (best −6,469) | — |

The chains gained ~87,000 log-units and were **still climbing at the last iteration** —
they are in transient burn-in, not sampling the posterior. **No posterior numbers from
this run are usable**, and none are recorded anywhere. This is a too-short-chain and
bad-start problem, not evidence of a broken posterior: the likelihood decomposition and
single-parameter scans both show sensible, well-scaled responses.

Fix order for the next session (detail in `notes/handoff_2026-08-10_calibration.md` §4):
mode-find with `optim()` and start chains dispersed around the mode; then 50k × 4 chains
(~3.2 h at 0.058 s/eval); if acceptance stays ~5 % after that, the ocean-uptake parameters
(`k_w`, `h_ml`, `kz`) are probably on a narrow ridge and want reparameterisation or a
Hessian-scaled proposal. Gate production on R̂ < 1.05 **and** ESS ≥ 400.

Handoff note written at `notes/handoff_2026-08-10_calibration.md`.

## 2026-08-10 (later) — Bomb ¹⁴C source replaced: it was a physics error, not just a gap

Marcus supplied two references (Graven et al. 2017 GMD 10:4405; Tans 1981 SCOPE 16
pp. 131–157). Neither is the UNSCEAR 2000 Annex C yield table that §8 of DATA.md said was
needed — and it turned out not to be needed at all.

**What the placeholder actually got wrong.** `R/model.R` gives each hemisphere one
well-mixed troposphere and **no stratospheric box**, so `forc$c14_bomb` is a *delivery*
rate. The placeholder was shaped like *production*: 54.0 % of all bomb ¹⁴C in 1961–62 and
2.2 % in 1963, delivered with no stratospheric residence. Telegadas' measurements (Tans
Table 2) say 56–60 % of the Naegler & Levin total was still **in the stratosphere** in
Dec 62 – Feb 63 and that 1963 was the largest delivery year. So this was a mistimed
forcing, not merely an uncited one.

**What was built.** `data-raw/build_bomb_c14_source.R` → `data/forcing_bomb_c14.rds`,
monthly, unit integral. Part A (≥1963.04): two exponentials fitted to Table 2, separating
into **39.97 kmol at τ = 1.00 yr** and **27.75 kmol at τ = 10.15 yr** (RMSE 1.2 kmol / 15
points); the analytic derivative is the delivery flux and is positive by construction.
Part B (<1963.04): the fit leaves 34.28 kmol already delivered, which pins the pre-1963
integral with no yield inventory; its shape comes from Table 1's tropospheric inventory
plus first-order removal `λ·N14`, with λ solved in closed form to close that budget.

**The check that makes Part B credible.** Uptake is 39 % of pre-1963 delivery, far too
large to drop. Budget closure gives λ = 0.1687 /yr (5.93 yr); gross air-sea exchange
alone, from Tans' own 19 mol/m²/yr, gives 0.1495 /yr (6.69 yr) — 89 % of it, biosphere as
the remainder. Two independent routes to 13 %.

**Effect.** Benchmarked against the *area-weighted hemispheric* observations
(`ccx_zone_weights()`), not the DESIGN §6 Zone-1 gate, which is not comparable to the
model's `d14c_NH`. Observed NH 853.2 ‰ @ 1963.708, SH 659.4 ‰ @ 1965.042, lag 1.33 yr.
New shape: NH +0.75 yr, SH +0.58 yr, lag 1.17. Old: NH −0.67 yr, SH **−1.42 yr**, lag
0.58. NH timing error is a wash in magnitude; **SH timing and the interhemispheric lag
are decisively better**, and DESIGN §6 names that lag as the `tau_ex` constraint. The old
peak (996.9 ‰) also exceeded every observed zone including Zone 1.

**Tried and rejected along the way.**
- *Graven 2017 as the bomb source* — it is an observation product, not a source term, and
  at 3 zones / annual it is coarser than the Hua et al. 2022 record already in
  `obs_d14c_zonal.rds`. Kept only as a δ¹³C cross-check back to 1850.
- *Raw quarterly differencing of Table 2* — gives 16.8 kmol for 1963 against the fit's
  27.7, because it inherits the Dec 62 – Feb 63 point that Tans explicitly calls "much too
  low". Superseded by the two-exponential fit, which extrapolates that burden upward
  (59.12 → 67.72 kmol). Keeping the low point instead worsens NH peak timing (+1.00 vs
  +0.75 yr), so Tans' advice and the data agree.
- *`hyman` spline for the pre-1963 buildup* — rejects the 1959–1960 tie in Table 1.
  Replaced with `monoH.FC`, which is also the non-overshooting choice that DATA.md §6
  demands for this series.
- *Pre-bomb Suess baseline* — varying it −30 → −20 ‰ moves NH peak timing not at all and
  amplitude 0.5 %. Immaterial; left at the Table 1 SH Dec-54 value.

**Left open.** A 4.5× one-month step survives at the Part A / Part B join. A steep rise
there is real (autumn-1962 tests descending in spring 1963) but a *step* is an artifact of
Part B resting on December-only anchors. Monthly pre-1963 Δ¹⁴C exists in
`obs_d14c_zonal.rds` and would remove it — at the cost of deriving the forcing from the
record the likelihood scores against. Awaiting direction.

`ccx_bomb_c14_annual()` is now the annual aggregate of the monthly series; the placeholder
survives as `ccx_bomb_c14_annual_SUPERSEDED()` purely so the size of the correction stays
reproducible. Test suite unchanged at 174 pass / 0 fail / 2 skip (seacarb absent) —
verified equal on HEAD before and after.

### Bomb window admitted to the likelihood

`LIK_USE_BOMB_WINDOW` FALSE → **TRUE**. It was excluded only because the shape was a
placeholder carrying 90 % of the likelihood information; that reason is gone. DESIGN.md
§6 gained an explicit warning not to gate on the Hua **Zone 1** numbers — the model has
one area-weighted hemispheric box, so the comparable benchmark is the weighted aggregate
(NH 853.2 ‰ @ 1963.708), and using Zone 1 flattered the old shape, whose 996.9 ‰ peak
exceeded every observed zone.

DESIGN.md's bomb-source spec called for injection "through the τ_strat delay kernel",
which was never implemented. The Table 2 fit **is** that kernel, measured rather than
parameterised — so this closes the spec rather than departing from it, and adds no
parameter.

Carried caveat, recorded at the switch: at uncalibrated defaults the modelled NH peak is
still +0.75 yr late, and the Part A/B join step sits inside the admitted window. Both bear
on `tau_ex` and the ocean-uptake parameters; treat posterior shifts in those as suspect
until the join is resolved.

## 2026-08-10 (later still) — Sub-annual bomb shape from observed Δ¹⁴C; two metric traps caught

Marcus: *"If we don't have the raw sub-annual emission data, then I'm okay using the
observed concentration data to get the sub-annual pattern to supplement the annual emission
data."* Implemented, and applied more broadly than first scoped once the data were checked.

**Table 2's quarterly resolution is illusory.** Its quarter-on-quarter releases are
`7, 48, 29, 17, 30, 42, 13, 0, 14, 5, 7, −2, 15, 3` units. Telegadas reports inventories
to ~3 figures, so everything below ~15 is rounding — including a **`0`, because "170" is
printed twice in succession**, which produced three months of exactly zero delivery. Annual
sums (101 / 85 / 24) are far above that floor. So the interval totals are now annual
throughout and the concentration record supplies sub-annual shape everywhere, rather than
only before 1963.

**Trap 1 — suspicious uniformity was real, but not where I first looked.** The modelled NH
peak sat at exactly 1964.625 in all nine runs of a `k_w`/`kz`/`h_ml`/`tau_ex` sweep spanning
2–4×, while amplitude and interhemispheric lag both responded strongly. That pointed at the
zero-delivery notch — but removing the notch did not move the peak, so the hypothesis was
wrong.

**Trap 2 — the metric, not the model.** The observed NH aggregate is **double-peaked**:
850.3 ‰ @ 1963.625, dipping to 741.9, then 832.6 @ 1964.625. The two maxima differ by 2 %,
so `which.max()` flips between lobes and manufactured a "+0.92 yr timing error" that no
parameter could move *because it was not a timing error*. The model reproduces the
double-peak structure and picks the other lobe. Peak timing is now explicitly disowned as a
score in DATA.md §9; the metrics are debiased scatter and correlation over 1962–1972,
because a constant level offset is exactly what `bomb_total` and the uptake parameters
absorb.

**Result on those metrics** (uncalibrated defaults, area-weighted hemispheric obs):

| Bomb source | debiased sd NH | debiased sd SH | corr NH |
|---|---|---|---|
| Measured input function, concentration sub-annual shape | **34.5 ‰** | **36.1 ‰** | **0.970** |
| Two-exponential fit, no concentration input | 48.0 ‰ | 39.5 ‰ | 0.951 |
| Superseded placeholder | 233.4 ‰ | 186.1 ‰ | **0.121** |

The placeholder correlated with the observed bomb transient at **0.12**. The earlier
two-exponential version is superseded: fitting a smooth decay to Table 2 destroyed the
Apr–Jul release maximum that appears in *both* 1963 and 1964 (48 and 42 units, the two
largest quarterly releases) — the spring stratosphere-troposphere intrusion.

**Also rejected:** using the observed record for the annual totals as well. Keeping the
totals from Tans confines the circularity to within-year timescales, so annual and longer
behaviour remains an independent test. Recorded as a caveat rather than papered over.

Smoothing window (`CCX_BOMB_SMOOTH`) is immaterial: 3, 5, 9 months agree to <1 %.
λ moved 0.1687 → 0.1996 /yr; the independent gross-air-sea check is 0.1495 /yr, now 75 % of
it (was 89 %), a more plausible ocean/biosphere split. Tests unchanged: 174 / 0 / 2.

## 2026-08-10 (session B close) — Mode found; posterior is pathological; production run BLOCKED

Mode-finding works: +81,718 log-units on the pre-bomb-window likelihood, beating the
original pilot's best on restart 1 — that pilot never left burn-in, as suspected. On the
final likelihood, init −84,837.5 → mode −8,736.6 (103 min, 135,585 evals @ 0.046 s).

**But the previous handoff's diagnosis was wrong.** It said the failed pilot was "a
too-short-chain and bad-starting-point problem, not evidence of a broken posterior." It is
evidence of a broken posterior.

- **My bug first:** `MODE_HESS_EPS = 1e-3` produced a non-PD Hessian with entries like
  −5.4e61. Stepping `log(kz)` by 1e-3 costs 49,000 log-units; the true second derivative at
  1e-4 is −41.3. Now 3e-4, with `calibration/recompute_hessian.R` sweeping the step and
  checking curvature stability before any covariance is trusted. Also fixed a
  condition-number print taking max/min of negative eigenvalues.
- **Suspected ridge REFUTED.** With a valid Hessian the strongest correlations are
  `beta`↔`q10` (+0.817) and `k_w`↔`bomb_total` (+0.813), not the guessed
  `k_w`/`h_ml`/`kz`. Condition number ~2.4e6; `h_ml` is the least-constrained parameter.
- **Re-pilot from the mode:** acceptance `0.000, 0.000, 0.205, 0.187`, worst R̂ 9.672.
  All four chains start at `lp = -Inf` even at 0.5 posterior-sd dispersion. Chains 3–4
  reached ~0.2 only because from `-Inf` the first finite proposal is always accepted.
- **Root cause:** the mode's `kz = 175,790` is within ~1 % of a hard feasibility boundary
  whose posterior sd is ~20 %. The `-Inf` is **solver failure, not zero probability** —
  the spinup is fine (`prod_c14` ≈ 333 throughout); `ccx_run_fast()` returns NAs in
  `co2_NH` above kz ≈ 177,000 and the `anyNA` guard converts that to `-Inf`. The optimiser
  maximised into a numerical wall. **The posterior is silently truncated by numerics.**
- **The mode is not physically credible:** `q10` = 0.280 (−7.9σ, and Q10 < 1 means
  respiration falls with warming), `kz` +6.3σ, `sigma_co2` = 0.074 ppm (−4.3σ),
  `k_w` −4.3σ, `rho` railed at 0.998.
- **Probable cause — the AR(1) error model.** As `rho`→1 the innovation becomes
  `(r_t − r_{t−1})/sd`, so optimal `sd` collapses to the RMS of residual *increments*, not
  the level. Profiles confirm genuine interior maxima, not runaway: `rho` prefers 0.998
  over 0.90 by **3,916 log-units**; `sigma_co2` peaks at 0.074 ppm. The AR(1) term absorbs
  systematic mismatch as correlated noise, removing the penalty on bias — which also
  explains why the −118 ‰ bomb-window bias survives untouched.

**PRODUCTION MCMC IS BLOCKED** pending (1) a real fix for the solver limit — an `-Inf`
meaning "the integrator broke" must not serve as a prior bound — and (2) a decision on the
AR(1)/σ error model, which is a methodological choice for Marcus, not one to pick silently.

Handoff: `notes/handoff_2026-08-10b_bomb14c_and_sampler.md`.

## 2026-08-11 — Blocker 1 CLEARED: the solver wall is diagnosed, controlled, and gated

Marcus's call on the app: **fix the §5 blockers before building the Shiny app**, so the app
runs on a physically credible parameter set rather than on uncalibrated defaults (which read
**467.8 ppm NH at 2024 against ~424 observed**) or on the discredited 2026-08-10 mode.

**The `-Inf` wall was the textbook RK4 explicit-diffusion stability limit — nothing else.**
Interior diffusion is integrated explicitly, so a fixed substep count caps `kz`. Predicting
the cap from the largest eigenvalue of the discrete diffusion operator and comparing against
bisection on the actual NA threshold:

| h_ml (m) | substeps | empirical NA threshold | analytic | ratio |
|---|---|---|---|---|
| 75 | 4 | 155,319 | 155,366 | 1.000 |
| 75 | 8 | 310,694 | 310,732 | 1.000 |
| 75 | 16 | 621,433 | 621,464 | 1.000 |
| 30 | 4 | 92,896 | 93,754 | 0.991 |
| 200 | 4 | 178,231 | 177,409 | 1.005 |

Agreement to 0.1–1 % across both `h_ml` and `substeps`, and the eigenvalue is exactly linear
in `kz` and independent of the state — so this is a closed form for the whole trajectory, not
an estimate at one point.

**Fix:** `ccx_substeps_for()` chooses the substep count from that criterion
(`CCX_RK4_STAB_LIMIT` 2.7853, `CCX_STAB_SAFETY` 0.85, floored at `CCX_SUBSTEPS_MIN` = 4L).
`ccx_run()` and `ccx_run_fast()` now default to `substeps = "auto"`.

**This changes no existing result.** `kz` must clear ~155,000 m²/yr — **+6.2σ on its
lnorm(log 4000, 0.6) prior** — before the count moves off 4. Gated: `ccx_substeps_for()`
returns 4 across the prior's central 99.99 % at `h_ml` ∈ {30, 75, 200}.

**Air-sea gas exchange is deliberately NOT in the criterion.** It can dominate the Jacobian
at low `kz` (measured up to 15× the diffusion eigenvalue at `k_w` = 6000, `h_ml` = 30) but in
absolute terms stays ~13× below the RK4 budget there, and would need `k_w` ≈ 80,000 (+11σ) to
bind. Adding a second closed form would have meant carrying a fudge factor for its
Revelle-driven growth along the trajectory (measured up to 3.9× from 1750 to 2100 on
SSP5-8.5). Instead `ccx_run_fast()` escalates: on NA it doubles the substeps and retries up to
`CCX_SUBSTEPS_MAX` = 256L. An `-Inf` from the posterior now means the model failed, not that
the integrator broke.

**Also considered and set aside:** (a) simply raising the fixed count to 8 or 16 — moves the
wall instead of removing it, and doubles or quadruples MCMC cost at every draw for a case that
almost never arises; (b) an implicit/operator-split diffusion step — numerically the right
answer, but it breaks the "emit each flux once, apply antisymmetrically" structure that makes
conservation exact at any step size, and would need the C++ parity gate rebuilt; (c) bounding
the `kz` prior below the limit — that is the disease, not the cure: a numerics-derived bound
masquerading as a prior is exactly what went wrong.

New gate `tests/testthat/test-stability.R` (34 assertions), including a **mutation test**: with
the controller forced back to the old fixed 4 and the retry disabled, `kz` ∈ {175,790, 4e5,
1e6} must all still produce NA. Without it the "no NAs" test could pass for the trivial reason
that the cases were never unstable. Also asserts accuracy, not just stability: doubling the
substeps beyond the controller's choice moves CO₂ by < 1e-6 relative.

Suite **208 / 0 / 2** (was 174 / 0 / 2; the 2 skips are still seacarb).

**Still blocked:** the AR(1) error-model pathology (§4 of the handoff) — a methodological
choice for Marcus. Nothing is re-run until that is settled, since re-running mode-find on the
current likelihood would just find the same `q10` = 0.28 with a slightly higher `kz`.

## 2026-08-11 (later) — Blocker 2 CLEARED: AR(1) retired for annual + explicit seasonal

Marcus's call among four options: **annual means with independent errors, plus the seasonal
cycle restored as an explicit statistic**. Rejected alternatives: capping `rho` at 0.90 (the
cap becomes the answer — an analyst-chosen effective sample size wearing a fitted parameter's
clothes); adding explicit per-stream bias parameters (4+ more parameters on an 18-parameter
problem whose Hessian condition number is already 2.4e6, and `rho` would still rail);
continuous-time AR(1) `rho^dt` (fixes the irregular-sampling defect but leaves the level-bias
loophole unchanged in kind).

**What the AR(1) was actually costing**, measured at the 2026-08-10 mode on MLO CO₂:

| ρ | n_eff (of 812 monthly) | log-units lost to a +50 ppm bias |
|---|---|---|
| 0.998 (the mode) | **0.8** | **13.7** |
| 0.95 | 20.8 | 3,390.7 |
| 0 (independent) | 812 | 1,274,217.9 |
| annual means, σ = 2 ppm | 69 | 27,461.7 |

67 years of the Keeling curve carried the weight of **less than one independent observation**.
The residuals really are that autocorrelated — measured lag-1 **0.998** at MLO, **0.9998** at
SPO — so AR(1) was describing them faithfully. That is the point: they are model *discrepancy*,
not noise, and AR(1) reclassified discrepancy as free noise. δ¹³C had it worse — `sigma_d13c`
collapsed to 0.007 ‰, giving those streams *positive* log-likelihood (+766, +1025).

**Two further defects found while measuring it**, either fatal alone: the AR(1) was applied on
**observation index, not time**, so SPO's 16-month gap counted as a 1-month step; and a single
`rho` was shared across four series of quite different sampling density.

**What replaced it.** `ccx_year_harmonic()` fits, per calendar year,
`v ~ 1 + (t − midyear) + sin(2πφ) + cos(2πφ)`. Its intercept is a deseasonalised, detrended
annual level; its sin/cos coefficients are the seasonal statistic. **The same estimator runs on
model and observations**, so neither NOAA's deseasonalisation nor the model's seasonal shape has
to be trusted separately. The level is immune to partial month coverage — gated on synthetic
data where a naive mean of Apr–Dec is biased 0.20 ppm and of Jul–Dec 0.5+ ppm, while the
harmonic recovers the truth to 1e-9.

Scored terms fell **4,713 → 632**. `rho` is retired; 18 parameters → **17**.

**Δ¹⁴C went annual too, as a consequence, not an afterthought.** The Hua et al. (2022) zonal
record is a *smoothed monthly compilation* fitted to sparser discrete samples, so its 939
monthly values per hemisphere were never 939 independent measurements. Leaving them monthly
while thinning CO₂ would have relocated the swamping rather than removed it. Monthly errors are
**not** reduced by √n on averaging — the dominant term is systematic representation error. The
model side now uses its own annual **mean** rather than a mid-year sample; during the bomb rise
the two differ by several ‰.

**Tried and rejected mid-implementation:** scoring the seasonal cycle as the multi-year *mean*
harmonic (4 terms total). It made the seasonal cycle weaker than its own side effect — moving
`seas_amp_NH` from 20 to 24 GtC/yr cost 1.2 log-units on the seasonal term but 6 on the CO₂
*level* term, because a larger seasonal cycle rectifies against the log CO₂-fertilisation term
and shifts the annual mean. The amplitude would have been set by its rectification side-effect.
Per-year scoring (~50 term pairs per station) restores the intended ordering: the seasonal term
now moves 62 log-units over that same amplitude change against the level term's 6.

**Performance regression caught and fixed.** The first implementation called `ccx_year_harmonic()`
(a `qr.solve` and a data.frame per year) on four model series inside the MCMC loop, taking the
posterior evaluation **0.046 s → 0.718 s** — 40 hours for a production run. The model, unlike the
observations, is on an exact monthly grid, so every full year shares one design matrix and the
reduction is a single 4×12 by 12×N product. Back to **0.046 s**. `test-likelihood.R` gates the
fast path against the general estimator so the two cannot drift.

`ccx_loglik(..., by_stream = TRUE)` now returns the 12-stream decomposition — a single number
cannot show which constraint a fit is paying for. At uncalibrated defaults:

```
co2_level_MLO -8138.2  co2_level_SPO -6909.8  co2_seasonal_MLO -1024.6  co2_seasonal_SPO -107.9
co2_icecore   -1589.2  d13c_level_MLO -511.8  d13c_level_SPO    -294.2  d14c_NH        -3079.5
d14c_SH       -3515.4  d14c_intcal    -674.1  gcb_ocean_sink     -17.4  gcb_land_sink   -126.2
```

New gate `tests/testthat/test-likelihood.R`: estimator correctness, partial-coverage immunity,
fast-path equality, and **regression tests for the specific historical failure** — a +50 ppm bias
must cost > 10,000 log-units (it cost 13.7), `sigma_co2`'s profile must have an interior maximum
(it collapsed to 0.0744 ppm), and the seasonal term must have interior optima in both amplitude
and phase. Suite **264 / 0 / 2**.

Pre-fix calibration outputs quarantined to
`calibration/output/quarantine/20260811_ar1_pathology_and_solver_wall/` with a README. They carry
18 parameters against the current 17, so loading one and feeding `u_mode` to a current
`ccx_make_logpost()` would silently misalign every parameter.

## 2026-08-11 (later still) — Future temperature comes from FaIR

Marcus's call for the app's Futures tab: **use FaIR to estimate future temperatures.**

**The bug this fixes.** `ccx_build_forcing()` interpolated GMST with `rule = 2`, so past
IGCC's 2024 end it held the last observed value **flat**. An SSP5-8.5 run to 2100 sat at
+1.53 °C throughout, with the q10 respiration and ocean-solubility feedbacks silently
switched off. It now warns, and `ccx_run_coupled()` supersedes it for any future run.

**Structure.** CarbonCycleEmulator stays R-only with no FaIR dependency (its CLAUDE.md makes
that a hard rule), so FaIR runs offline in FaIRtoFrEDI and crosses the repo boundary as a
provenance-stamped CSV set: `FaIRtoFrEDI/run_fair_ssps_for_ccx.py` →
`data-raw/downloads/fair_v145_ssp/` (FaIR 2.2.4 calib1.4.5, 841 configs, ensemble mean,
1750–2500, 5 SSPs, 73 s total).

**Why more than a prescribed GMST path.** The tab has to answer "what does a 100 GtC pulse
do", on scenarios FaIR was never run on. A prescribed temperature path cannot respond to a
pulse — it would show a pulse changing CO₂ while leaving the climate untouched, the exact
misconception the tab exists to dispel. So temperature is rebuilt from **our own** CO₂:

```
erf_total = erf_co2(CO2 from this model) + erf_nonco2(scenario, prescribed from FaIR)
T         = impulse_response(erf_total)
```

The non-CO₂ half — aerosols, CH₄, N₂O, ozone, volcanic, solar — stays prescribed, because
this model has none of it. That is ~1.1 of SSP2-4.5's 4.7 W/m² at 2100 and the app must say
plainly that the user is changing CO₂ only.

| fit | result |
|---|---|
| CO₂ → ERF, quadratic in ln(CO₂/CO₂_PI), no intercept | rmse **0.029**, max 0.132 W/m²; **F₂ₓ = 3.85 W/m²** |
| ERF → T, 3-timescale impulse response | q = 0.160 / 0.328 / 0.354 K/(W/m²), d = **1.56 / 14.2 / 261 yr**; ECS-equivalent **3.24 K** |
| vs FaIR GMST, per scenario | rmse 0.028–0.036 °C; **rmse ≥2050 only 0.010–0.030 °C** |

**Tried and rejected — twice, both my errors, both caught by the gate:**

1. **Interpolating the pooled (CO₂, erf_co2) pairs** instead of fitting. Wrong twice over.
   The pairs are ensemble means over 841 configs with differing CO₂ forcing scale factors, so
   mean(erf_co2) ≠ f(mean(CO₂)) and the cloud has real width (0.025 W/m² at 900 ppm). And
   CO₂ is **not monotone in time** — SSP1-1.9 and SSP1-2.6 peak and decline — so sorting by
   CO₂ interleaves the rising and falling limbs, giving **334 descending steps, worst −0.147
   W/m²**, which `monoH.FC` cannot repair because it is monotone only for monotone *input*.
   The residual printed at the time was **0.000, and that diagnostic was vacuous**: a spline
   through every point interpolates by construction and can never show scatter. The real test
   is cross-scenario spread at matched CO₂ (0.025 W/m²), now a separate gate.
2. **A pure log law** (degree 1): rmse 0.078 vs 0.024 W/m², F₂ₓ 4.003 vs 3.889. The quadratic
   term is Meinshausen et al. (2020)'s band correction and is not optional. Degrees 3–4 buy
   nothing (0.0233, 0.0231).

**Outer-loop coupling, not an in-loop climate module.** CO₂ → T → carbon cycle is closed
inside `ccx_run_coupled()` by iterating whole runs — converges in **6 passes, ~0.17 s** —
rather than porting a climate module into `ccx_core.cpp` and rebuilding the parity gate for
it. **The feedback is not negligible:** SSP5-8.5 at 2100 is **+111 ppm and +0.32 °C** coupled
versus a single uncoupled pass.

Uncalibrated CO₂ at 2100 runs above FaIR's own (SSP2-4.5: 620 vs 530 ppm; SSP5-8.5: 1126 vs
960), consistent with the model reading ~27 ppm high over the historical record at defaults.
Recheck after calibration. Note separately that FaIR's *emissions-driven* SSP CO₂ is itself
well below the SSP database's concentration projections (~530 vs ~600 ppm for SSP2-4.5 at
2100) — flagged, not explained, and not something this project needs to resolve.

`ccx_build_forcing()` gains an `emissions=` override (the route stylised pathways and pulses
take; annual totals still conserved exactly through the monthly interpolation). New gate
`tests/testthat/test-climate.R`: IRF-vs-FaIR skill, CO₂→ERF residual **and** the
concentration-alone check, a future run must actually warm (the regression test for the flat
extrapolation), the historical splice must reproduce IGCC to 1e-10, and the carbon-climate
feedback must be measurably engaged. Suite **298 / 0 / 2**.

The IRF's single worst year is **1817**, after Tambora, where a 1-year box cannot track a
−5 W/m² one-year volcanic spike (max |err| 0.192 °C, identical across scenarios because 1817
is shared history). Bounded by the gate rather than pretended away.

## 2026-08-11 (evening) — Recalibrated on the fixed posterior; CO₂ now fits, ¹⁴C does not

Mode-find re-run on the 17-parameter annual/seasonal posterior with the stability controller
in place: **126 min, 164,635 evaluations at 0.046 s/eval, init −25,999 → mode −2,359.3.**
`calibration/output/mode_fit.rds`.

**Both blockers are demonstrably gone.**

| | 2026-08-10 mode | 2026-08-11 mode |
|---|---|---|
| `q10` | **0.280** (Q10 < 1: respiration *falls* with warming) | **4.14** |
| `kz` | 175,790 — ~1 % from the solver wall | **8,354**, substeps needed = 4 (the floor) |
| `sigma_co2` | 0.0744 ppm (collapsed) | 0.301 ppm |
| Hessian condition number | 2.4e6 | **8.29e4** |
| MLO CO₂ annual residual | mean +6.6, rms 13.6 ppm | **mean −0.15, rms 0.99 ppm** |

**The CO₂ side now fits well.** CO₂ at 2024 is **422.2 ppm against ~424 observed** (uncalibrated
defaults gave 467.8). Ocean sink 2014–23 **3.26 vs GCB 3.19** GtC/yr; land sink 2.98 vs 2.47
(high, but inside the deliberately inflated land-sink uncertainty).

**The ¹⁴C side does not, and the new plausibility screen caught it.** `run_modefind.R` now
reports each parameter's position in its own prior's tail and flags |z| > 3. Three fired:

| flagged | mode | z | reading |
|---|---|---|---|
| `bomb_total` | **151.2 kmol** | **+4.60σ** | prior is lnorm(log 102, 0.10) from Naegler & Levin's citable 99.3–104.9 kmol. The fit wants **48 % more bomb ¹⁴C than was produced.** |
| `sigma_d14c` | 45.8 ‰ | +3.01σ | the Δ¹⁴C error term inflating to absorb a poor fit |
| `q10` | 4.14 | +3.46σ | right sign at last, but well above the ~1.5–2.5 usually quoted for soil respiration |

Δ¹⁴C residuals: NH rms **47 ‰** overall, **69 ‰ inside the 1960–70 bomb window**, against a
bomb-window mean bias of only −5.3 ‰. So inflating `bomb_total` has fixed the LEVEL and left the
SHAPE wrong — which is the failure mode the 2026-08-10 handoff §2 predicted ("treat any
posterior shift in those specifically as suspect until the join is resolved").

Two independent diagnostics point the same way and are almost certainly the same defect:

- **Natural ¹⁴C production solves to 382 mol/yr against the canonical ~545** (ratio 0.70) — and
  this is the free validation the spinup was built to provide (see spinup.R's header).
- **Deep-ocean Δ¹⁴C is −104 ‰ against an observed −150 to −200 ‰** — the deep ocean is too well
  ventilated, consistent with `kz` sitting at +1.45σ and `h_ml` at a thin 37.7 m.

**PRODUCTION MCMC NOT LAUNCHED.** Sampling for 2.6 h around a mode whose bomb source is 48 %
above a tightly-constrained citable prior would produce a posterior whose ¹⁴C-derived quantities
— which is to say the ocean ventilation timescale, the thing ¹⁴C is in the model *for* — are not
believable. Flagged for Marcus rather than resolved: the candidates are the residual bomb-shape
problem at the Part A/B join, the ¹⁴C bookkeeping between production and inventory, and the ocean
grid, and choosing among them is a modelling decision.

## 2026-08-11 (night) — The ocean excess-¹⁴C constraint, and a ¹⁴C source nobody declared

Handoff §7 step 1: put the Naegler & Levin (2006) ocean inventory into the likelihood, because
every other ¹⁴C term is atmospheric and an atmospheric decline can be bought with a bigger bomb
source instead of a faster sink. Done — and validating the definition first turned up a
separate defect that changes one of 2026-08-11's conclusions.

### The constraint

`data-raw/build_calibration_data.R` now parses `data-raw/manual/naegler_levin_2006_budget.csv`
into `data/obs_excess_c14.rds`; `ccx_loglik()` gains `excess_c14_ocean`. Both cores emit
`ocean_C14` / `land_C14` / `atm_C14` (state units — kmol is the likelihood's business), gated by
`test-parity.R`. Tests **371 → 384 pass**, 0 fail, 2 skip.

**The natural baseline is free.** The run's first row *is* the 1750 steady state by
construction, so no counterfactual run is needed and the posterior evaluation stays at
**0.046 s**. Measured against the expensive alternative — a full no-fossil/no-LUC/no-bomb/
no-nuclear counterfactual carrying the observed GMST and ENSO — the two differ by **0.27 kmol
(1975) and 0.58 (1995)**, under 1 % of the excess against a ~16 kmol observational spread.
Removing the climate forcing as well reproduces the spinup state to 0.003 kmol, which is the
fixed point behaving as it must.

**The units were checked before the term was trusted**, on the one row where N&L have real
observations. Rebuilding the *atmospheric* excess from the CO₂ and Δ¹⁴C observations alone under
our convention gives **37.3 kmol (1975) and 25.6 (1995)** against their troposphere-plus-
stratosphere **35.6 and 21.7**: **+4.8 % and +18.0 %**. That measured spread — not a chosen
number — sets `LIK_EXCESS_C14_REP_FRAC = 0.15`, carried as a **rank-one shared method bias**
across the two years rather than per-year quadrature, because two estimates from overlapping
reconstructions do not carry twice the information. (An earlier working note put the 1995 figure
at 15.3 %; that was arithmetic on the wrong denominator. 18.0 % is correct, and the fraction was
raised from 0.10 to 0.15 to cover it.)

### The finding: land-use-change emissions inject ¹⁴C ex nihilo

Excess ¹⁴C can only come from the prescribed sources minus decay, so the reservoir excesses must
sum to the cumulative bomb input. **Ours do not.** From `dE/dt = sources − λE`, with no
assumption about where the extra comes from:

| | excess | declared sources | decay | **undeclared** |
|---|---|---|---|---|
| 1975 | 167.85 | 144.38 | −0.45 | **+23.93 kmol (14.3 %)** |
| 1995 | 178.84 | 151.45 | −0.88 | **+28.27 kmol (15.8 %)** |

**Cause:** `R/model.R` emits LUC with `add_source()` at the **vegetation box's own ¹⁴C ratio**
while the vegetation box is not debited — 273 GtC of LUC carbon at a land Δ¹⁴C of +221 ‰ is a
real ¹⁴C source. Fossil carbon is emitted at Δ¹⁴C = −1000 and correctly carries none. Two
independent estimates agree: the closure residual above, and integrating the LUC flux against the
run's own vegetation ratio (24.0 / 27.9 kmol).

Whether this is a bug or a defensible consequence of LUC being exogenous to two *responsive*
land pools is **a modelling decision for Marcus, not resolved here.** The physical objection is
that the real ¹⁴C leaving a cleared forest was taken up from the atmosphere earlier and is
already in the bomb budget, so injecting it again double-counts.

**What it does and does not contaminate**, from `calibration/diag_excess_c14.R` §3:

- **The ocean is barely affected.** Paired bomb-only 72.6 / 94.3 kmol against total-minus-natural
  75.9 / 95.4 — a 1–4 % gap, far inside the observational spread. The ocean constraint stands.
- **The land is affected a great deal, and this CORRECTS 2026-08-11 §6.4(e).** At the citable
  102 kmol our land excess is 43.8 kmol under total-minus-natural but **29.6 kmol** paired
  against N&L's 18.9 — so "our land holds 2–3× their biosphere" becomes **~1.6×**. Still high,
  and still consistent with the `tau_veg` tension, but not the dramatic gap it looked like.

### Size of the effect — real, not decisive

At the quarantined mode's `bomb_total` = 151.2 the term scores **−15.10**; at the citable 102 it
scores **−7.26**. That is **~7.8 log-units** in favour of the citable total, against the **116
log-units** it costs to pin `bomb_total` at 102 (§6.4(c)). **The constraint sharpens the
diagnosis; it does not resolve it.** The bomb delivery *shape* remains the thing to fix, exactly
as the handoff ordered it — step 1 has not made step 2 unnecessary.

### FLAGGED FOR MARCUS — the target set is worth ~130 log-units

Two published observational reconstructions, and choosing between them dwarfs everything above:

| set | 1975 | 1995 | term at `bomb_total` 151.2 |
|---|---|---|---|
| **`table4_obs_range`** (default) | 48.6 ± 7.9 | 51.4 ± 7.6 | −15.1 |
| `table2_peacock` | 43.9 ± 4.3 | 56.5 ± 2.5 | ≈ −149 |

Both are stored in `data/obs_excess_c14.rds`; `LIK_EXCESS_C14_TARGET` picks by name. **The wide
one is the default** on the grounds that the span between two published reconstructions is method
spread, not measurement noise, and adopting one of them as if the other did not exist would put
that much leverage on a choice of paper. If Marcus prefers the tight set, the mode-find must be
re-run — and `bomb_total` would then be driven hard toward the citable value by this term alone,
which is a *result* only if the target is believed.

### State

`calibration/output/mode_fit.rds` and its log are **quarantined** to
`calibration/output/quarantine/20260811b_pre_excess_c14/` with a README: the parameter vector is
still a fine starting point, but its **logpost −2359.3 must not be quoted** (the same vector
scores −2378.6 under the current posterior) and its Hessian is of the old posterior. A mode-find
against the new posterior is running.

### Recalibrated with the constraint in — and it does not move `bomb_total`

Mode-find against the new posterior: **118.8 min, 151,536 evaluations at 0.047 s/eval,
−26,005.8 → −2,374.1.** `calibration/output/mode_fit.rds`.

| | pre-constraint mode | post-constraint mode |
|---|---|---|
| `bomb_total` | 151.25 (+4.60σ) | **149.81 (+4.54σ)** |
| `k_w` | 2950 | 2921 |
| `kz` | 8354 | 8267 |
| `q10` | 4.143 (+3.41σ) | 4.093 |
| `sigma_d14c` | 45.84 (+3.01σ) | 45.86 |
| ocean excess ¹⁴C @1975 / @1995 | 76.9 / 95.7 | **75.8 / 94.3** kmol |
| MLO CO₂ annual rms | 0.986 ppm | 0.983 |
| bomb-window Δ¹⁴C rms | 69.1 ‰ | 67.9 |
| Hessian condition number | 8.29e4 | 7.69e4 |

**Every parameter moved by about 1 %.** The same three flags fire (`q10`, `bomb_total`,
`sigma_d14c`). The fit simply **pays** the ocean-inventory penalty — `excess_c14_ocean` sits at
−14.55 at the mode, against observed targets of 48.6 ± 7.9 and 51.4 ± 7.6 that it misses by
+27 and +43 kmol — rather than give up any of the atmospheric fit.

That is a **clean negative result, and it is worth more than a positive one would have been.**
The constraint was added on the hypothesis that ¹⁴C's ocean sink was underdetermined because
every term was atmospheric. It is not underdetermined; it is *contradicted*. The model cannot
simultaneously match the atmospheric Δ¹⁴C decline and the observed ocean inventory, at any
`bomb_total` — which is the ocean-side twin of §6.4(c)'s atmospheric-side finding that it cannot
match the observed Δ¹⁴C curve at any `bomb_total` either. **Two independent constraints now say
the same thing about the same defect**, and neither is a parameter problem.

`calibration/profile_bomb_total.R` was written to close the remaining loophole — whether the
failure to bite is the *width* of the wide target set or something structural — by profiling
`bomb_total` under both target sets with everything else re-optimised at each point.

### The `bomb_total` profile: the target-set choice dissolves, and the constraint cannot win

`calibration/profile_bomb_total.R`, 91.7 min, `bomb_total` ∈ {102, 120, 135, 150, 165} kmol with
every other parameter re-optimised at each point, under **both** target sets.

| `bomb_total` | logpost | ocean term | ocean excess 1975/1995 | bomb-window Δ¹⁴C rms | MLO CO₂ rms |
|---|---|---|---|---|---|
| 102 | −2483.1 | −7.21 | 52.7 / 64.4 | **190.6 ‰** | 0.98 |
| 120 | −2433.7 | −8.93 | 60.8 / 75.4 | 119.9 | 0.99 |
| 135 | −2393.0 | −11.24 | 67.8 / 84.7 | 74.7 | 0.99 |
| **150** | **−2374.1** | −14.60 | 75.9 / 94.4 | **68.1** | 0.98 |
| 165 | −2393.4 | −19.07 | 85.0 / 104.3 | 90.6 | 0.96 |

(`table4_obs_range`; the `table2_peacock` column is within 1.3 log-units at every point.)

**Both target sets choose `bomb_total` = 150.** The flagged choice was flagged on the wrong
grounds: the earlier "~130 log-units" estimate for it assumed **per-year quadrature**, and the
term does not use per-year quadrature. Once the shared method error is modelled as the rank-one
common term it is — which is the correct structure, since the model overshoots **both** years in
the same direction — the two sets differ by **0.7 log-units at the mode**, not 130.

`calibration/diag_excess_c14_leverage.R` locates the real lever. The bar to clear is **116.4
log-units** (what the rest of the likelihood pays to move 150 → 102, almost all of it the bomb
window: **68.1 → 190.6 ‰**):

| `LIK_EXCESS_C14_REP_FRAC` | `table4_obs_range` | `table2_peacock` |
|---|---|---|
| 0.00 | 20.4 | **135.4** ← clears |
| 0.02 | 19.7 | 108.7 |
| 0.05 | 16.9 | 53.3 |
| 0.10 | 11.3 | 18.9 |
| **0.15 (in use)** | **7.4** | 9.1 |
| 0.20 | 5.1 | 5.3 |

**One corner of this table flips the answer: the tight target with essentially zero method
error.** Even 2 % of shared bias closes it. And what that corner buys is not a model that fits
both — it is the ocean inventory purchased at 190 ‰ of atmospheric bomb-window misfit. Choosing
it would be choosing which observation to disbelieve, not resolving anything.

**Conclusion: no admissible setting of this constraint resolves the ¹⁴C problem.** It either does
nothing (any plausible shared method error) or it trades one 14C misfit for another. Handoff §7
steps 2 and 4 — the bomb delivery shape at the 1963.04 Part A/B join, and the single ventilation
timescale — are where the resolution has to come from. Step 1 is complete and its answer is
that step 1 was never going to be enough.

## 2026-08-12 (later) — The ¹⁴C defect is a PARTITION error, not a delivery-shape error

Handoff §7 sent this session to the bomb delivery shape, "starting at the Part A / Part B join
at 1963.04, where a 4.5× one-month step survives."

**That entry point is stale.** The join step was already reduced **4.5× → 1.59×** on 2026-08-10
by the sub-annual rebuild, and both `DATA.md` §9 and `notes/handoff_2026-08-10b` record what
remains as *defensible real acceleration* (the autumn-1962 tests descending in spring 1963), not
a method artefact. `Rscript data-raw/build_bomb_c14_source.R` prints `join step: 16.38 → 26.05
kmol/yr = 1.59x in one month`. The 4.5× was carried forward through two handoffs after the thing
it described had been fixed.

So the shape question was re-opened on its merits instead, with a new diagnostic.

### `calibration/diag_bomb_partition.R` — the same budget, split three ways

N&L Table 4 partitions their cumulative bomb input across stratosphere / troposphere /
biosphere / ocean at 1975 and 1995. Run at **their own citable total (102 kmol)** our model
receives the same input, so the partition is a like-for-like test that is **independent of
`bomb_total`**: not how much ¹⁴C there is, but where it went.

**Compared like with like.** `R/model.R` has no stratospheric box and the bomb source is a
*delivery rate to the troposphere* — the stratospheric residence is already inside the source.
So the model's atmosphere box is a **troposphere**, and N&L's stratosphere is removed from their
atmosphere *and from their total*. Scoring against troposphere+stratosphere instead would credit
the model for ¹⁴C it has by construction already delivered, and would inflate the deficit from
−40 % to −54 %.

Paired bomb-only, kmol:

| | model 1975 | N&L 1975 | | model 1995 | N&L 1995 | |
|---|---|---|---|---|---|---|
| troposphere | 16.13 | 26.80 | **−40 %** | 9.82 | 17.50 | **−44 %** |
| biosphere | 32.80 | 21.70 | **+51 %** | 29.88 | 18.90 | **+58 %** |
| ocean | 48.73 | 42.10 | +16 % | 63.34 | 60.00 | +6 % |
| SUM delivered | 97.67 | 90.60 | +8 % | 103.04 | 96.40 | +7 % |

Observational brackets bound the two rows that have them: troposphere 26.0–28.0 and 16.0–18.0;
ocean 39.6–48.2 and 54.0–59.0 (Peacock, N&L-corrected). The model's troposphere is outside its
bracket at both years; its ocean is inside at both.

**Two errors, an order of magnitude apart.** The **sum** is +7–8 % — a real delivery-timing
error, and the *most* a re-shaped source could ever repair. Inside that budget the troposphere
is 40–44 % short and the biosphere 51–58 % long, **in the same direction at both reference
years, twenty years apart**. Re-timing the delivery moves ¹⁴C between years; it cannot move it
between reservoirs. This is why `bomb_total` sits at +4.5σ: the fit is buying atmospheric Δ¹⁴C
it cannot otherwise have, and paying for it in the ocean-inventory term (2026-08-11).

### The land is the wrong shape, not the wrong size

Model land carbon is **1678 GtC (1975) / 1721 (1995) against N&L's 2200 PgC biosphere, −22 to
−24 %** — a *smaller* pool holding *51–58 % more* bomb ¹⁴C. Capacity is not the defect; residence
structure is. `R/model.R:177-185` is a strictly serial cascade atm → veg (`tau_veg` 10 yr) → soil
(`tau_soil` 15 yr) → atm with **no fast autotrophic-respiration return**: every atom taken up by
NPP is locked for the full 25 yr before it can come back. The real biosphere returns roughly half
of GPP within the year. N&L's has four pools.

This is the same defect the `tau_veg` sweep already saw from the other side and did not name:
3 yr gives bomb rms 59.5 but CO₂ rms 11.98; 10 yr gives 69.1 and 0.99. A single serial chain has
to serve the decadal ¹⁴C transient and the centennial CO₂ uptake with one timescale — structurally
the same bind as one `kz` serving the bomb transient and the deep age (2026-08-11 §6.4(b)).

### The LUC ¹⁴C leak does not contaminate this

Measured, not assumed, in `[C]`: the leak's **paired** part is **0.52 kmol (1975) / 1.22 (1995)**
against a total injection of 23.84 / 27.70. It enters the atmosphere, so removing it would widen
the tropospheric deficit to −11.19 / −8.91 — the conclusion survives either resolution of the
open decision, and the partition test did not need to wait on it. (The *unpaired* total still
matters for §5's inventory comparison; nothing there changes.)

### Consequence for the plan

Handoff §7 steps 2 and 3 swap places, and step 6 is no longer optional. The land structure — a
third fast pool, or an explicit GPP/autotrophic-respiration loop — is now the highest-value work,
and it is what freeing `tau_veg` was always standing in for. Test suite unchanged at
**384 pass / 0 fail / 2 skip**; this session added a diagnostic and no model or likelihood code.

## 2026-08-12 (night) — LUC debits the vegetation box; the model becomes carbon-conservative

Marcus' decision on the open item from §5 of the 2026-08-12 handoff: **debit the vegetation
box** — "physically cleanest, but changes the land carbon trajectory and so the CO₂ fit."
Branch `luc-veg-debit`, **not merged**: two guard tests fail (below).

`R/model.R:226` and `src/ccx_core.cpp` — land-use change stops being an `add_source()` and
becomes `add_flux(iveg, iatm, e_luc)`. Fossil carbon stays a source: geology *is* outside the
modelled system. LUC never was.

`d13c_bio` (−25 ‰, "provisional") is **removed from both cores and from `ccx_cpp_par()`**:
`add_flux` carries the vegetation box's own emergent ¹³C ratio, so the prescribed value has no
remaining use. Clearing a forest does not fractionate, so `alpha13 = 1`. Historical `e_luc` is
strictly positive (min 0.68, max 2.41 GtC/yr over 3300 months), so the transfer never reverses;
a comment records that a negative scenario value would transfer at the atmosphere's ratio
*without* the photosynthetic fractionation it should carry.

**The model is now carbon-conservative, and was not before.** Total carbon change 1750→2024 is
**503.79 GtC against 504.67 GtC of cumulative fossil input — residual −0.88 GtC** (0.2 %, a
one-step `cumsum` alignment). Previously the same run created **321.6 GtC** of land-use carbon
out of nothing, alongside the ~28 kmol of ¹⁴C.

### It costs the old mode everything, and that is recoverable

The pre-change mode scores **−2374.1 → −56,349.7**, almost all of it `co2_level_MLO` (−26,748)
and `co2_level_SPO` (−24,664). CO₂ at 2020 falls from a good fit to **372.8 ppm against ~414
observed**. The mechanism is second-order and expected: the atmosphere receives the same LUC
carbon either way, but the vegetation box now *pays* for it, so litterfall and heterotrophic
respiration both fall while `npp0` does not — the land becomes a far stronger net sink.

A 1-D scan over `beta` with everything else held at the stale mode:

| `beta` | CO₂ @2020 | logpost | land C 2024 |
|---|---|---|---|
| 0.00 | 449.9 | −27,048.8 | 1363 |
| 0.10 | 436.1 | −11,981.8 | 1414 |
| 0.20 | 424.1 | **−6,216.3** | 1459 |
| 0.30 | **413.7** | −6,617.8 | 1499 |
| 0.40 | 404.6 | −11,095.4 | 1533 |
| 0.883 (mode) | 372.8 | −56,349.7 | 1656 |

**This is the fix removing an implausible parameter, not breaking a good one.** The old mode
needed `beta = 0.883` — far above the literature range for the log formulation — precisely
because 321.6 GtC of phantom carbon had to be absorbed by *something*. With the leak closed,
β ≈ 0.25–0.30 reproduces CO₂ @2020 to ~0.3 ppm, and everything else in the vector is still tuned
for the old bookkeeping. A full mode-find has not been run.

### Two guard tests fail, and they are right to

`test-likelihood.R:114` and `:117` ("a CO₂ level bias is expensive") assert that a +1 ppm bias
costs > 100 log-units; `cost(1)` is now **−534.6**, i.e. +1 ppm *improves* the fit. The fixture
uses `ccx_default_params()`, whose `beta = 0.40` now leaves CO₂ ~12 ppm low. **The tests are
detecting a stale default parameter set, not a likelihood loophole** — the AR(1) pathology they
were written to catch has not returned. Per the standing rule they have **not** been modified or
skipped. Resolving them means re-centring `ccx_default_params()` on the new bookkeeping, which is
a decision, not a fix. Suite: **382 pass / 2 fail / 2 skip**.

### An inconsistency this exposes

The debit removes vegetation *carbon* but not vegetation *productive capacity*: `npp` is
`npp0 * (1 + beta ln(chi/chi0))`, so clearing a forest does not reduce NPP and the land
over-recovers. Options are to tie NPP to the veg stock (`npp0 * veg/veg0 * ...`), or to accept it
and let `beta` absorb it — which is what the scan above is doing. **Not resolved**; it should be
settled as part of the land restructure, which changes the pool layout anyway.

## 2026-08-12 (night, later) — NPP capacity tie and a GPP loop; two predictions falsified

Marcus: tie NPP to the veg stock; and on GPP — *"leaf growth and decay will release the same
amount of isotopes back that it absorbs, whereas other components of GPP will be more like the
ocean where exchanging CO₂ back and forth leads to equilibrating isotopes faster than the net
CO₂ flux."* Both implemented in both cores; parity holds at 4.5e-13 on CO₂.

- **`npp_veg_frac` (φ)** — `NPP = npp0 · [(1−φ) + φ·veg/veg0] · (1 + β ln(χ/χ₀))`. Default 0.5.
- **`ra_ratio`** — `GPP = NPP·(1+ra_ratio)` down, `Ra = NPP·ra_ratio` back up at **veg's own
  ratio**. Default **0**, which reproduces the previous model exactly. Marcus' distinction is
  exactly what the parameter means: respiring carbon fixed days ago returns the *atmosphere's*
  ratio and is a null loop; respiring from the pool returns the *pool's* ratio and is the
  ocean-gross-exchange analogue. `add_flux` takes the source box's ratio, i.e. the second case,
  so `ra_ratio` is the fraction of GPP that genuinely cycles **through the pool** — his two
  regimes are its endpoints. Leaf growth-and-decay is not this flux; it is the existing
  veg → soil → atm cascade, lagged rather than equilibrating.

`calibration/diag_land_structure.R` tests three claims. **Two of my three predictions were wrong.**

### ✗ "φ cannot be 1" — falsified

The decoupled algebra says the veg coefficient is `(φ·f − 1)/tau_veg`, so `φ·f > 1` diverges.
It does not. φ up to **1.10 (φ·f = 1.25) is stable**, because **χ is not exogenous**: a growing
veg pool draws CO₂ down, which lowers `f`. CO₂ @2024 falls monotonically 413.7 → 322.2 ppm across
the scan — that column *is* the feedback. The false bound has been removed from the comments in
both cores; the diagnostic is kept live so it is not reinstated from algebra.

### ✓ `ra_ratio` is isotopes-only — confirmed

`max|ΔCO₂| ≤ 2.3e-13 ppm` and `max|Δland C| ≤ 9.1e-13 GtC` across `ra_ratio` ∈ [0, 1.5], while
Δ¹⁴C moves. The net carbon flux is NPP by construction and the implementation honours it.

### ✗ "the GPP loop shrinks the biosphere's bomb ¹⁴C" — falsified, and Marcus' caution was right

| `ra_ratio` | trop 1975 | bio 1975 | trop 1995 | bio 1995 |
|---|---|---|---|---|
| 0.00 | 21.04 | 39.74 | 11.02 | 42.55 |
| 0.50 | 20.68 | 42.47 | 11.76 | 42.43 |
| 1.50 | 21.09 | **44.12** | 12.30 | 42.26 |

The biosphere **rises** at 1975 and the troposphere barely moves. In 1975 the atmosphere is still
far above natural, so a *lagging* veg pool is still catching up and holds **less** than
equilibrium; equilibrating harder closes that gap upward. **Equilibrating faster is the wrong
lever while the source is still elevated.** `ra_ratio` is correct physics and stays, defaulted to
0 — it is simply not what closes the partition gap.

### What does set the land's bomb ¹⁴C: it is multi-pool or nothing

N&L: 21.7 / 18.9 kmol on a **2200 PgC** biosphere = **0.986 / 0.859 kmol per 100 GtC**.

| tau_veg | tau_soil | bio 1975 | bio 1995 | land C 1975 | kmol/100 GtC |
|---|---|---|---|---|---|
| 10 | 25 | 39.74 | 42.55 | 2095 | 1.897 |
| 10 | 3 | 30.49 | 23.69 | 786 | 3.880 |
| 3 | 3 | 19.69 | 11.53 | 367 | 5.363 |
| 20 | 50 | 42.52 | 52.01 | 4184 | **1.016** |

The excess is strongly **sub-linear** in pool size — a bigger, slower pool dilutes the bomb signal
faster than it accumulates it. N&L's ratio is reached only at a pool **twice theirs**. Matching
their absolute inventory (tau 3/3) needs a pool **six times too small**. **One responsive soil
pool cannot match their carbon stock and their ¹⁴C inventory simultaneously** — which is the
signature of a multi-pool biosphere: fast pools cycle the bomb ¹⁴C, a large slow pool holds carbon
while barely seeing it. That is the structural change the partition finding actually implies.

### φ = 0.5 breaks the airborne fraction, and this is a physical benchmark

`test-pulse.R:112/113` ("the airborne fraction is in the right ballpark", against recalled
Joos et al. 2013 IRF values 0.59 / 0.41 at 20 / 100 yr) now **fails**: 0.402 and 0.243.

| φ | AF @20 yr | AF @100 yr |
|---|---|---|
| **0.00** | **0.597** | **0.423** |
| 0.25 | 0.517 | 0.344 |
| 0.50 | 0.402 | 0.243 |

**φ = 0 reproduces Joos almost exactly.** The capacity term is doing two jobs at once and only one
was wanted: it makes clearing reduce productivity (wanted), but it *also* amplifies CO₂
fertilisation on the way up (more veg → more NPP → more veg), and that positive feedback is what
over-drains the pulse. Suite: **380 pass / 4 fail / 2 skip** — the two likelihood fixtures from
the LUC commit, plus these two. Not modified, not skipped, per the standing rule.

**Unresolved, for Marcus.** Separating the two jobs is the obvious move — e.g. clamping the
capacity factor at `min(veg/veg0, 1)` so clearing costs capacity while growth does not add it.
Not implemented: at defaults the land pool stays *above* veg0 all century, so the clamp would be
inert historically, and whether it bites depends on a calibrated β. It needs deciding together
with the multi-pool land, not before it.

---

## 2026-08-12 (later) — Four-pool land: the ¹⁴C partition error is closed

### The prescribed fix was wrong, and an offline tool caught it before the rebuild

The previous entry sent the next step to "split the single responsive soil pool into fast
and slow". `calibration/diag_land_topology.R` was written to choose a pool layout *before*
restructuring the state vector — it integrates a candidate topology's bomb-¹⁴C inventory
directly from an atmospheric Δ¹⁴C history, at ~1 ms per candidate, with no core rebuild.
It validates against the full model on the live land parameters first (**−0.9 % / −0.6 %**
at 1975 / 1995 on the four-pool land; −6.5 % / −3.1 % on the two-pool one it replaced).

**A soil-only split cannot work.** Its best is 30.0 / 19.5 kmol on 2214 GtC against N&L's
21.7 / 18.9 on 2200 — 1995 right, **1975 38 % high**. The reason is arithmetic: a single
600 GtC vegetation pool at `tau_veg` 10 already holds ~20 kmol at 1975, essentially N&L's
entire biosphere, so *no soil layout beneath it can help*. **The vegetation had to be split
too.** Driven by the OBSERVED atmosphere, not the model's own — the model's troposphere was
40–44 % short *because* its land took too much, so designing against it would have
understated how inert the land must be.

### The structure

`leaf` (60 % of NPP, τ 1 yr) → `wood` (τ 20 yr) → litter split 95/5 → `soil_fast` (τ 2 yr)
and `soil_slow` (τ 500 yr). NB 28 → 32. Vegetation 516 GtC, responsive soil 114, passive
soil 1500, total 2130 — every pool independently defensible, on a **flat** misfit surface
(0.60/30/0.04 and 0.70/40/0.04 both ~6 %), so these are a defensible centre, not a fit.

Routing, all stated in the derivative: capacity keys on leaf+wood; the Ra loop runs per
vegetation pool at each pool's own ratio; litter is split **per source pool** so the two
¹⁴C ratios are not averaged before the split; seasonal NEP through leaf; ENSO out of
`soil_fast`; **LUC debits wood** (Marcus 2026-08-12). Calibration keeps exactly one land
degree of freedom — `tau_soil_fast` replaces `tau_soil`; the other five are held fixed so
a CO₂ fit cannot undo the partition fix. *That is a choice, and it will need revisiting.*

### Result

Paired bomb-only at `bomb_total` 102, vs Naegler & Levin Table 4:

| | before (2-pool, at the mode fit) | after (4-pool, at defaults) | N&L |
|---|---|---|---|
| biosphere 1975 | 32.80 (+51 %) | **21.73 (+0 %)** | 21.70 |
| biosphere 1995 | 29.88 (+58 %) | **20.83 (+10 %)** | 18.90 |
| troposphere 1975 | 16.13 (−40 %) | 31.34 (+17 %) | 26.80 |
| troposphere 1995 | 9.82 (−44 %) | 15.91 (−9 %) | 17.50 |
| SUM delivered | +8 % / +7 % | +7 % / +6 % | — |

**The 40–58 % partition error is gone.** What remains is the delivery error alone, which
was always the ceiling on what a re-shaped source could repair. The four-pool land is
**not calibrated** — read the partition, not the level.

### φ resolved itself

`test-pulse.R:112/113` — the Joos airborne-fraction benchmark that φ = 0.5 broke — **now
pass unmodified.** The capacity term's runaway (more veg → more NPP → more veg) was an
artefact of a single 600 GtC vegetation pool with a 10-yr turnover; with the fast leaf pool
carrying most of NPP, the positive loop no longer over-drains the pulse. No clamp needed,
and φ stays at 0.5. The open decision from the previous entry is **closed by the
restructure**, not by a decision.

### What it cost, measured rather than argued

γ_L, the land carbon-climate feedback, **fell from −57.6 to −19.6 GtC/K** (land carbon at
2100, q10 = 2 vs q10 = 1, on coupled SSP5-8.5, over GMST at 2100; measured in both models,
like for like). Two tests record it, neither modified: `test-climate.R:122` (feedback
0.091 °C, bound 0.1) and `test-mechanisms.R:32` (ENSO switch moves CO₂ 0.28 ppm, bound 0.5).

Both trace to one number. Only soil respires with q10, and a q10 anomaly can only move
carbon a pool can release on the horizon in question — *responding carbon*,
Σ C_j (1 − e^(−100/τ_j)). The two-pool land had ~1470 GtC of it, the four-pool land ~390.
Factor 3.8, against factor 2.9 in γ_L: the metric explains the loss.

**An intermediate soil pool (τ 30–100 yr) was tried offline and does not rescue it**
(`diag_land_topology.R` [4], soil stock held fixed). The trade is ~+0.7 kmol at 1975 — 3 %
of the target — per +100 GtC of responding carbon. Doubling responding carbon to ~730 still
leaves it at half the two-pool value while pushing 1975 from exact to +13 %.
**The bomb ¹⁴C bounds the soil-respiration carbon-climate feedback from above.**

**The escape this model does not have.** Its only carbon-climate feedback is q10 on
heterotrophic respiration. Real land models draw much of γ_L from productivity decline and
disturbance — a temperature dependence of NPP, which this model lacks entirely. If γ_L
needs to be larger, that is where it should come from; the soil route is the one the ¹⁴C
has closed. (γ_L ≈ −20 is at the low edge of what I recall of CMIP6 C4MIP values, roughly
−34 ± 20 GtC/K from Arora et al. 2020 — **recollection, not verified against the paper**;
`gamma_enso`, by contrast, is a *calibrated* parameter with room to absorb its own test.)

### Quarantine

`calibration/output/quarantine/20260812_luc_debit_and_2pool_land/` — `mode_fit.rds`,
`profile_bomb_total.rds` and the run logs, with a README. They were fitted to a model that
created 321.6 GtC and ~28 kmol of ¹⁴C from nothing, **and** to a land whose parameters no
longer exist. `R/cpp.R` now errors on a pre-four-pool parameter list rather than silently
substituting a land the caller did not ask for.

Suite: **380 pass / 4 fail / 2 skip** — same count as the parent, different set.

### Would a stratospheric layer help? — and a framing question it exposed

`calibration/diag_stratosphere.R`, written to answer that, turned up something larger.

**As a DELAY, no.** A one-way stratospheric reservoir of residence τ convolves the source with
an exponential. No single τ reconciles the delivered sum at both reference years: the 1995
column barely moves at any τ (+5.6 % from τ 0.5 to 3), because the source is over by 1980 and a
one-way reservoir has emptied fifteen years later. τ ≈ 3 fixes 1975 exactly and does nothing for
1995. **N&L's own stratosphere is not a delay line either** — holding 4.7 kmol in 1995 from
8.6 kmol in 1975 needs τ ≈ **33 yr** against ~1–2 yr observed exchange, and their
stratosphere/troposphere ratio *falls* 0.321 → 0.269, relaxing toward a **mass** ratio. It is a
co-equilibrating reservoir carrying its share of the excess.

**The framing question.** `diag_bomb_partition.R` compares the model's atmosphere box to N&L's
troposphere alone, and removes their stratosphere from their total, because the bomb source is a
delivery *rate to the troposphere*. **That argument is about timing; it says nothing about
mass.** The box carries `GtC_PER_PPM = 2.124` — the whole atmosphere — while `likelihood.R` fits
its Δ¹⁴C to surface stations. Its *inventory* is whole-atmosphere mass × tropospheric Δ¹⁴C, so
the like-for-like target is troposphere **plus** stratosphere:

| | A (current) | B (proposed) |
|---|---|---|
| atmosphere 1975 | +16.9 % | −11.5 % |
| atmosphere 1995 | −9.1 % | −28.3 % |
| SUM 1975 | +7.2 % | **−2.1 %** |
| SUM 1995 | +5.6 % | **+0.7 %** |

**Under B the budget closes** — the SUM error collapses to the model's own input excess over N&L
(+2.8 % / +0.9 %; the model runs at 102 kmol against their decay-corrected 99.2 / 101.1). That is
what a model which conserves ¹⁴C and is given a prescribed input *must* do, and a "+6–7 %
delivery error" was never physically sensible for one — its apparent existence is what has been
sending sessions after the bomb source shape. **Not changed; flagged for decision**, because B
over-corrects at 1975 (N&L's stratosphere really was more enriched than their troposphere then).
Reporting both framings and scoring on neither is probably right.

**If B holds, the residual is a different defect**: atmosphere short (−11 / −28 %), ocean long
(+4.7 / +8.6 %), biosphere fine. Too much bomb ¹⁴C into the ocean — a ventilation problem.

**Which is also the real case FOR a stratospheric box**, from the other side: the model must
satisfy *tropospheric* Δ¹⁴C observations with a box holding *whole-atmosphere* carbon, so during
the spike it cannot hold the atmosphere's true inventory and the surplus is pushed into the
ocean. Splitting the box lets the troposphere match observations while the stratosphere holds the
enriched remainder — which predicts exactly that signature. It would **not** touch γ_L, the ocean
carbon inventory, or the ¹⁴C production shortfall (a stratosphere adds <1 % of system inventory
against a ~34 % gap). **Cost:** NB 32 → 34, *and* the bomb source rebuilt as an injection rate
rather than a delivery rate, or the delay is double-counted. A package, not a box.

## 2026-08-12 (later still) — The framing question is settled: it is neither A nor B, and the ¹⁴C budget closes

The previous entry left the atmospheric comparison as an A-vs-B decision and recommended
"reporting both framings and scoring on neither." That was the right instinct and the wrong
resolution: **there is a third framing that is actually like-for-like, and it is computable
rather than a matter of taste.**

**The argument.** `R/model.R`'s atmosphere is one box carrying `GtC_PER_PPM` = *whole*-atmosphere
carbon, while `likelihood.R` fits its Δ¹⁴C to `obs_d14c_zonal` = *surface* stations, i.e.
tropospheric air. Its excess-¹⁴C inventory is therefore whole-atmosphere **mass** at a
tropospheric **ratio**. So:

- **A** (vs N&L troposphere alone) is wrong by the entire stratospheric mass.
- **B** (vs troposphere + stratosphere) credits the box with an enrichment a single well-mixed
  box cannot carry.
- **C** (vs N&L troposphere scaled to whole-atmosphere mass) is the like-for-like target, and
  removes from their total only the stratosphere's *enrichment excess over its mass share*.

**The mass ratio is read from N&L's own model, not assumed.** Their Figure 2 (p. 4) puts the
GRACE tropopause at **9 km poleward of 30°, 15 km equatorward** — which is what "22 boxes, six in
the troposphere, 16 in the stratosphere" over six latitude bands means. With the US Standard
Atmosphere at those altitudes, the troposphere is **78.8 %** of atmospheric mass and the
strat/trop mass ratio is **0.2686**. Computed in `diag_bomb_partition.R` from named constants,
not hardcoded.

**An independent check that it is right.** N&L's own stratosphere/troposphere ¹⁴C ratio falls
0.321 (1975) → **0.269** (1995) — landing on the derived mass ratio 0.2686 to three decimals. By
1995 their stratosphere carries exactly its mass share of the excess, so **B and C coincide at
1995** and diverge only at the spike. This confirms both the Figure-2 reading and the physical
claim (from `diag_stratosphere.R`) that the stratosphere is a co-equilibrating reservoir, not a
delay line.

**Result, four-pool land at defaults, `bomb_total` = 102:**

| | 1975 | 1995 |
|---|---|---|
| atmosphere | −7.7 % | −28.2 % |
| biosphere | −0.3 % | +9.6 % |
| ocean | +4.8 % | +8.6 % |
| **SUM** | **−0.7 %** | **+0.7 %** |

**The budget closes to within ±1 % at both years.** The "+6–7 % delivery error" that sent two
handoffs after the bomb source shape **does not exist** — it was the artefact of scoring a
whole-atmosphere box against a tropospheric target. There is nothing for a re-shaped source to
repair, and `data-raw/build_bomb_c14_source.R` does not need reopening on these grounds.

**What the residual actually is:** atmosphere **short** (−8 % / −28 %), ocean **long**
(+5 % / +9 %), biosphere fine. Too much bomb ¹⁴C in the ocean — a **ventilation** problem. The
1995 atmospheric shortfall is the robust number; the 1975 one is sensitive to the tropopause
assumption (−0.6 % to −8.8 % across strat mass fractions 0.15–0.22) and should not be quoted
alone. This is exactly the signature the stratospheric-box mechanism predicts, so that item is
real — but it sits behind the ocean work, not in front of it.

Also noted: the script's own header had claimed the atmosphere "is compared to
troposphere+stratosphere" while the code compared to troposphere **alone**. The prose was closer
to right than the code and neither was exact — a comment that had drifted from its own function.

### γ_L against C4MIP — the recollection was wrong, and it changes the conclusion

The previous entry flagged that "γ_L ≈ −20 is at the low edge of CMIP6" rested on an
**unverified recollection** of "~−34 ± 20 GtC/K, Arora et al. 2020" and was worth ten minutes.
Checked, against two independent sources ([Biogeosciences 17:4173](https://bg.copernicus.org/articles/17/4173/2020/)
and [OSTI 1695755](https://www.osti.gov/pages/biblio/1695755), both quoting the abstract verbatim):

> γ_L = **−45.1 ± 50.6 PgC °C⁻¹**, γ_O = −17.2 ± 5.0 PgC °C⁻¹ (11 CMIP6 models, 1pctCO2 to
> 4×CO₂, BGC−COU approach)

The recollection was wrong on the central value (−45.1, not −34) and wrong on the spread by
**2.5×** (±50.6, not ±20). The spread is the consequential error:

| | γ_L | distance from CMIP6 mean |
|---|---|---|
| two-pool land | −57.6 GtC/K | −0.25 σ |
| **four-pool land** | **−19.6 GtC/K** | **+0.50 σ** |

**Both sit inside ±1 σ.** So the four-pool land's weaker γ_L is *not* an outlier against C4MIP,
and §7's "at the low edge" framing was an artefact of the misremembered spread. The honest
statement is that CMIP6 does not constrain γ_L tightly enough to call this a regression **or** a
correction — the bomb-¹⁴C constraint is the more informative one.

**Consequence for the queue:** temperature-dependent NPP is no longer motivated by a C4MIP
comparison. It remains a genuine structural gap (this model's only carbon-climate pathway is q10
on heterotrophic respiration), but it is a modelling choice, not a defect to be fixed under
deadline.

**Caveat on comparability, stated because it is not innocuous:** Arora's γ_L is 1pctCO2-to-4×CO₂
over 140 years via BGC−COU; ours is land carbon at 2100, q10 = 2 vs q10 = 1, coupled SSP5-8.5,
over GMST at 2100. Different protocol and different warming path. The comparison is fair as
"this model's *total* carbon-climate feedback vs C4MIP's", because q10 is the only such pathway
the model has — but it is not a protocol-matched number and should not be presented as one.

## 2026-08-12 (later still, ii) — Ocean scoping: the ¹⁴C "production shortfall" is arithmetic, not a defect

Mode-independent findings from scoping the ocean-ventilation item while the mode-find runs.
Recorded now, separately from the ventilation scoping itself, because these do **not** depend on
the new mode and one of them **corrects a claim already standing in this file**.

### `prod_c14` is DERIVED, not fitted — the "34 % shortfall" mis-frames a diagnostic

The queue carries "¹⁴C production **359** vs ~545 mol/yr — note it got *worse* with the new land,
382 → 359, and is unexplained" as a large open defect. Measured at the 1750 steady state:

```
total 14C inventory   2955 kmol
implied decay         359.3 mol/yr
model prod_c14        359.3 mol/yr
balance (decay/prod)  1.0000
```

**The model conserves ¹⁴C exactly.** `prod_c14` is whatever balances decay of the model's own
carbon inventory at its own Δ¹⁴C distribution — it is a *readout of the inventory*, not an
independent quantity that can be short. Scoring it against a cosmogenic production estimate
compares two different things.

**And 382 → 359 is the fix working, not a regression.** The four-pool land holds less ¹⁴C, so the
inventory it must sustain is smaller. Reporting that as "it got worse" inverted the sign of the
result.

**Where the gap actually goes.** At 32,827 GtC ocean + 2,130 land + 589 atm = 35,546 GtC total.
Raising the ocean to a realistic ~38,000 GtC gives ~40,700 GtC and **~410 mol/yr**, closing about
a third of the gap (approximate: it assumes the added carbon enters at the current mean Δ¹⁴C,
whereas a biological pump would add it *more* depleted, so the true figure is a little lower).
Reaching 535 mol/yr would require a total inventory of **52,930 GtC, ~1.3× the real world** — so
the residual is not something this model can absorb by fixing its ocean.

**NOT CLOSED, and deliberately not.** The residual is a discrepancy between the carbon-inventory
route and the cosmogenic-production route, and published production estimates span roughly
1.6–2.5 atoms cm⁻² s⁻¹ (≈430–670 mol/yr). **Where the ~545 target came from has NOT been
verified** — that provenance check is what would settle whether there is anything left to explain.
Until then: item (h)'s production line is *mostly arithmetic*, not "large and unexplained", but it
is not resolved.

(Checked in passing and found correct: `T_HALF_C14` = 5700 ± 30 yr, the Cambridge-revised value
used by IntCal and Hua et al. 2022, with `LAMBDA_C14` properly derived from it.)

### Uniform DIC is EXPECTED, and is a different gap from the ventilation one

"DIC exactly uniform with depth" is listed alongside the ocean carbon deficit as an anomaly. A
pure-diffusion ocean with no biological pump and surface-only sources **must** homogenise at
steady state — the uniformity is the *signature of the missing soft-tissue/carbonate pump*, which
is also what makes the inventory ~16 % low. That is a **different missing structure** from the
missing advection behind the ventilation item, and the two should not be merged into one "the
ocean is too simple" task: they have different fixes and only one of them is gated on the mode.

### State of the ventilation machinery (facts, not conclusions)

- `R/model.R`'s interior transport is `add_diffusion` and **nothing else** — there is no advective
  or overturning term. A single `kz` carries the whole column. (`tau_ex` is interhemispheric
  *atmospheric* exchange, not ocean.) Grid: mixed layer `h_ml` over `N_INTERIOR` geometrically
  graded layers, `growth = 1.4`.
- `calibration/profile_kz_ventilation.R` already asks the right question and states its own
  falsification criterion. It is **2 of 7 grid points complete**, those two on the superseded
  two-pool land, and the results are in the quarantine at
  `20260812_luc_debit_and_2pool_land/profile_kz.log`:

  | kz | deep Δ¹⁴C | ocean bomb | bomb_total | bombwin rms |
  |---|---|---|---|---|
  | 500 | −635.7 ‰ | 32.0 kmol | 111.9 | 42.1 |
  | 1000 | −471.1 ‰ | 39.2 kmol | 115.6 | 46.3 |
  | 8354 (old mode) | −115 ‰ | — | 151 | — |
  | *observed* | *−150 to −200* | | *99.3–104.9* | |

- **It is hard-gated on the mode**: line 51 does `readRDS(.../mode_fit.rds)` unconditionally and
  errors without it, and `PROF_KZ_GRID` is centred on the *old* mode's kz = 8354. Re-running it
  before the new mode lands answers a superseded question at ~2.5 h of cost.
- Two cautions for whoever runs it: the bomb-window RMS is **non-monotonic** in kz (42.1 at 500,
  46.3 at 1000), so the grid is not a smooth single-optimum curve; and the profile is a
  **conditional maximum, not a marginal** — the script says so, and it must not be quoted as a
  likelihood.

The mode-dependent half of the ocean scoping — whether one `kz` can serve both the decadal bomb
penetration and the millennial deep age, and therefore whether the fix is a retune or a second
ventilation pathway — is deliberately **not** written down yet. It turns on the new mode's `kz`,
and at defaults the deep ocean is already −194.7 ‰, inside the observed range.

## 2026-08-13 — δ¹³C: the fossil source is fixed, the Suess overshoot is structural, and step 1's premise was backwards

Handoff 12d §0 laid out three steps and said to do them in order. Step 1 — fix the
three σ's — rested on a stated mechanism: the fit loosens `sigma_d13c` to escape "the
one term that would discipline the land sink", so tightening it would discipline `q10`.
That mechanism was argued, not measured. Pricing it before spending a 4 h refit turned
up a different model.

### The measurement that inverted it

`calibration/diag_q10_stream_direction.R` scans `q10` with everything else held, at
fixed σ's, and reports `ccx_loglik(by_stream = TRUE)`. Relative to `q10 = 2.0`, moving
to `q10 = 0.2`:

| stream | at defaults | at the 16-par mode's other parameters |
|---|---|---|
| `d13c_level_MLO` | **+254.4** | **+345.8** |
| `d13c_level_SPO` | **+157.6** | **+293.5** |
| `co2_level_MLO` | −1533.6 | +1169.8 |

**δ¹³C pushes `q10` DOWN at both parameter vectors.** Tightening `sigma_d13c` from the
mode's 0.44 to the prior median 0.1 does not discipline the land sink — it *strengthens*
the force driving the inversion. Step 1 is still worth running; its prediction is
inverted.

### Why δ¹³C wants a bigger land sink

`calibration/diag_d13c_suess.R`. The δ¹³C residual is neither scatter nor a constant
offset: obs − model grows monotonically from ~0 ‰ in 1850 to **+0.58 ‰ by 2020** at MLO
(+0.43 at SPO), with 0.07 ‰ of year-to-year scatter around it. The model reproduces the
*shape* of the Suess decline and overshoots its *magnitude* by ~30 %. Photosynthesis
discriminates against ¹³C, so a bigger land sink is what relieves a too-depleted
atmosphere — hence the pull on `q10`.

### The fossil source: fixed, and worth 3 % of the bias

Sensitivity of the 2015–2024 MLO bias to every provisional ¹³C constant put the fossil
source far ahead of the rest: −28 → −24 ‰ takes it +0.577 → +0.048 with the CO₂ bias
unmoved at +2.33 ppm, where `alpha_photo`, `alpha_as_up` and `alpha_as_down` move it
0.014–0.035 ‰ per ‰. Two concrete defects in the shipped −28, both pushing the same way:

- GCB's `fossil` column is fossil-fuel-**and-industry**, so ~4–5 % of it is **cement** —
  calcined limestone at ~0 ‰, not fuel at −28.
- the value was **constant** across 1750–2024, but the fuel mix ran from all-coal (~−24)
  to gas-inclusive (gas ~−44).

Now built per year from GCB 2025's own by-fuel split (`data-raw/build_calibration_data.R`
[5b]) with citable endmembers — coal −24, oil −26.5, gas −44, cement 0 (Graven, Keeling
& Rogelj 2020; Tans 1981 / Andres et al. 2000 via Bush, Pataki & Ehleringer 2007) — and
carried on the **forcing table**, since it is no longer an invariant. The series runs
**−24.0 (1850) → −28.3 (2024)**, landing on both ends of the −28 to −24 ‰ envelope
Graven et al. state for the global fossil-plus-cement signature.

**It moved the bias 0.577 → 0.561 ‰. Three per cent.** Emission weighting is why: the
early years where the old constant was most wrong carry almost no emissions. The
correction is right and it stays — it was wrong twice over — but the prediction that it
would explain the overshoot was **falsified**, and the sensitivity scan that motivated it
was measuring a counterfactual (the whole history at −24) that the real fuel mix cannot
deliver.

### What else was tried and closed

- **Sink partition** (diag [3]). Closing the δ¹³C bias needs a **~72 % land share**
  (β ≈ 0.9) against GCB's 42 %; that costs **+40 ppm** of CO₂ and a 4.7 GtC/yr land sink
  against GCB's 2.4. δ¹³C and CO₂ cannot both be satisfied by any partition this model
  can reach.
- **Weak isotopic disequilibrium damping** (diag [4]). `ra_ratio`, the gross land loop,
  is the ideal lever — it changes gross exchange while leaving net carbon untouched. It
  moves the bias **0.10 ‰ across its whole plausible range**, and Δ¹⁴C, which is the right
  constraint on gross exchange, goes **+2.7 → −14.6 ‰** over the same range and forbids
  the large values.

### Where that leaves it

The model over-depletes atmospheric δ¹³C by ~0.55 ‰ and none of the source signature, the
fractionation constants, the reachable sink partition, or the gross land exchange
accounts for it. **This is the structural misfit 12d §7 inferred from the whack-a-mole
pattern, now located**: the calibration's only remaining way to relieve δ¹³C is to
manufacture land sink, which is what `q10` → 0.169 is doing. Untested candidate: the
ocean-side disequilibrium, in a pure-diffusion ocean with no biological pump whose DIC
inventory is ~16 % low (§ 12d.4).

**Consequence for step 1, flagged rather than resolved:** Marcus chose the prior medians
(1.5 / 0.1 / 5), partly on my statement that 0.1 ‰ would become the *honest* σ_d13c once
the fossil source was fixed — the residual's year-to-year scatter is only 0.07 ‰. That
premise is now false: the 0.55 ‰ bias survives, so σ_d13c = 0.1 fixes ~450 log-units of
weight onto a residual the model structurally cannot remove.

### Mechanics

The forcing table gains a 10th column. `R/cpp.R` states `CCX_FORCING_COLS` as the
positional contract with `src/ccx_core.cpp` (which reads `f[9]`), since a reorder there is
silent garbage rather than an error. `ccx_forcing_d13c_foss()` returns 0 for a hand-built
zero-emission forcing (the spinup's, the conservation tests') and **errors** for one that
carries emissions without a signature, rather than defaulting to a number nobody chose.

Suite **400 pass / 4 fail / 2 skip** — the same four failures as 12d, plus 12 new guard
assertions. One of those guards exists because the fossil sensitivity scan in diag [2]
went **inert** the moment `d13c_foss` left `aux`: it reported six identical rows while
looking live, until it was rewritten to override the forcing column.

## 2026-08-13 (later) — The δ¹³C overshoot is the price of the pure-diffusion ocean

`calibration/diag_d13c_levers.R` scans the two families the previous entry left untested
— the ocean (`k_w`, `h_ml`, `kz`) and the land **lag** (`tau_wood`, `tau_soil_slow`,
`litter_slow_frac`, `npp_veg_frac`, i.e. the *age* of returning carbon rather than the
gross magnitude `ra_ratio` already covered). Every row carries the CO₂ bias, the Δ¹⁴C bias
and the land-sink share, because a lever that closes δ¹³C by breaking those has closed
nothing.

**`k_w` is the only lever not paid for elsewhere:**

| k_w | δ¹³C bias | CO₂ bias | Δ¹⁴C bias | land share |
|---|---|---|---|---|
| 1500 (default) | +0.548 | +2.33 | +2.65 | 46 % |
| 2500 | +0.259 | +3.63 | +4.59 | 46 % |
| **4000** | **+0.075** | +4.38 | +1.52 | 45 % |
| 6000 | −0.034 | +4.81 | −1.62 | 45 % |

`h_ml` moves the bias 0.085 ‰ across 30–200 m. Every land-lag knob that helps costs
15–50 ‰ of Δ¹⁴C (`tau_wood` 150 → +43.8 ‰; `litter_slow_frac` 0.5 → +51.5 ‰).

**And 4000 is not available.** 1500 m/yr *is* the Wanninkhof global-mean CO₂ transfer
velocity the prior is centred on (DESIGN.md line 102; ~16.5 cm/hr = 1450 m/yr), so 4000
is 2.7× it, **+2.45 σ**.

**The reading.** The model needs more gross exchange than a real piston velocity delivers
because its ocean cannot *maintain* the isotopic disequilibrium. The real ocean does that
by circulation: upwelling continually presents water last in contact with a preindustrial
atmosphere, so the return flux stays isotopically old. A diffusive column has no
upwelling — it smears the Suess signal downward, the water at the surface is already
partly loaded, and the return flux is too depleted. Raising `k_w` fakes it by talking
faster to a reservoir that is too equilibrated; raising `kz` fakes it by burying the
signal, at +13 ppm and +22 ‰ Δ¹⁴C by `kz` = 10,000.

**This is the same missing term ¹⁴C already found.** 12d §2 closed the ¹⁴C budget with the
residual "atmosphere short / ocean long ⇒ **ventilation**". Two isotopes, one gap.
DESIGN §2 rejected HILDA as "too many parameters to communicate" and 12d §10 lists ocean
advection among the deliberate omissions — so this is a **known, chosen limitation now
priced in per mil**, not a new defect. That is the right thing for a communications model
to be able to say about itself.

## 2026-08-13 (later still) — The ventilation term, built and measured: it does not help

The previous entry ended with a suggestion: "the cheapest structural candidate is not full
HILDA but a single prescribed upwelling velocity through the column (one parameter, one
number a reader can be told). Nothing here has costed that." **It is now costed.** The
mechanism was built, gated, and scanned — and the answer is that it is a second knob on
the trade `kz` already makes, not the missing process.

**Built** (`w_up`, m/yr, `R/model.R` + `src/ccx_core.cpp`): the classical
upwelling–diffusion column — water rises through every interface at `w_up` and returns
from the mixed layer to the bottom box in one step (Hoffert et al. 1980; Harvey &
Schneider 1985). One parameter. It cost ~30 lines each side and **nothing else**: the
advective limbs go through `add_flux`, so conservation is structural; a uniform column is
still an exact fixed point, so `ccx_spinup()`'s analytic ¹²C equilibrium and both isotope
solves stand unchanged; and at physical values the substep controller does not move
(the added Gershgorin bound `ccx_advection_eigbound()` is exactly 0 at `w_up` = 0).

**`w_up` is 0 in `ccx_default_params()` and absent from `CCX_PARAM_TABLE`.** The
pure-diffusion model is reproduced *exactly*, and `test-ocean-advection.R` holds that —
with a mutation test, because an inert mechanism would pass the inertness gate trivially.

**Measured** (`calibration/diag_ocean_upwelling.R`). Both knobs buy δ¹³C damping by making
the deep ocean younger; per ‰ of deep-ocean Δ¹⁴C spent, upwelling is **worse**:

| axis | ‰ of δ¹³C bias per ‰ of deep Δ¹⁴C |
|---|---|
| `kz` (w_up 0, kz 3830 → 6200) | **−0.00220** |
| `w_up` (kz 5000, 0 → 2) | −0.00107 (0.5×) |
| `w_up` (kz 500, 0 → 2) | −0.00052 (0.2×) |

Over the whole (`w_up`, `kz`) surface, the best δ¹³C bias among cells whose deep ocean is
still inside the observed −150/−200 ‰ bracket is **+0.501 ‰, at `w_up` = 0**. Holding the
deep age fixed by bisecting `kz`, adding upwelling makes δ¹³C **worse**: +0.548 → +0.628
at `w_up` = 1 (the compensating `kz` falls 5000 → 3062 and stops burying the depleted
carbon faster than the upwelling limb removes it). At `w_up` ≥ 2 the deep age is
unreachable at *any* `kz` — the sinking limb alone over-ventilates the bottom box.

**Why, in one number.** For upwelling to hold the mixed layer out of isotopic equilibrium
it has to flush it faster than the atmosphere re-equilibrates it. Measured at defaults:
gross air-sea exchange **27.1 GtC/yr** against a **284 GtC** NH mixed layer = **10.5 yr**
(the textbook ~10 yr). Flushing at 4 m/yr through 75 m takes **18.8 yr — 1.8× too slow**;
the crossover is `w_up` ≈ 7 m/yr, ~80 Sv, about **4× the real overturning** (20 Sv over
this model's ocean area is 1.75 m/yr). A global-mean overturning cannot outrun air-sea
exchange, and it is not close.

**The mechanism works and still loses, which is the actual finding.** At `w_up` 4 /
`kz` 1000 the upwelled water genuinely arrives old — the ml→oc1 δ¹³C gap widens 0.167 →
0.584 ‰ — and the mixed layer still ends up *more* depleted (−1.910 vs −1.619 ‰) than with
no upwelling at all, because the `kz` that lets the advective signal survive is the same
`kz` that was burying the depletion. **No purely vertical rearrangement can decouple "the
surface stays undepleted" from "the deep stays old" in a single column. They are the same
transport.** That retires "just add advection" with a measurement rather than a judgment,
and it means the ventilation caveat in the previous entry stands as written.

**Where it points instead, untested and needing a citation first.** The model's mixed
layer declines **1.619 ‰** over 1750–2024 against an atmospheric **2.834 ‰**, a ratio of
**0.57**. My *recollection* of the observed oceanic Suess effect is a surface-DIC decline
of ~0.6–0.9 ‰ against the atmosphere's ~1.9, a ratio near 0.35–0.45 — i.e. the model's
surface ocean would be tracking the atmosphere about twice as closely as the real one
does. **That number is unverified** (nothing in DATA.md, nothing in the local Papers
folder; Quay et al. and Eide et al. 2017 are where to look). If it survives checking, the
gap is not a transport term at all but the single well-mixed surface box: the real ocean
keeps its disequilibrium with *horizontal* structure, and a global mean of a product is
not the product of the global means. That is a second surface box — the outcrop/HILDA
structure DESIGN §2 rejected — and a bigger decision than a diagnostic can take.

Suite **418 pass / 4 fail / 2 skip** — the same four failures, plus 18 new guards.

## 2026-08-13 (later still, cont.) — The other configuration: deep water straight to the surface

Marcus asked for the mechanism the previous entry did **not** test: deep water reaching the
surface *without passing through the intermediate layers*, as a Southern Ocean outcrop. The
entry above built the mirror image — its non-local limb runs **downward** (ml → bottom),
with a layer-by-layer ascent. So the ask was a different operator, and in the way that
matters: under `w_up` the water arriving at the mixed layer comes from `oc1`, which is
diffusively slaved to it (an ml→oc1 δ¹³C gap of only 0.167 ‰), while an outcrop delivers
bottom water at the full preindustrial contrast.

**Built** as `w_out_NH` / `w_out_SH` (m/yr, per hemisphere — the real outcrop is a Southern
Ocean feature and the two ocean columns exchange only through the atmosphere). Both default
0, both absent from `CCX_PARAM_TABLE`.

**It ties the first configuration exactly, and that is the finding.** At equal `w` the two
give identical CO₂, δ¹³C, Δ¹⁴C, ocean and land carbon — to **~1e-10**, at every `kz` from
10 to 5000. Not similar: *tied*. They are the same closed loop traversed in opposite
directions, so their transport operators satisfy

> **A_out = D · A_upᵀ · D⁻¹**,  D = diag(dz)  — verified to **1.7e-18**

and interior diffusion is self-adjoint in the same weighting (**2.2e-16**), so it does not
break the relation. A transpose preserves the *diagonal* elements of the propagator, and
**the mixed layer is the only box through which the ocean touches the rest of the model** —
air-sea exchange acts at `iml` and nowhere else. So the atmosphere sees the column
exclusively through an ml→ml response that is invariant under reversing the circulation:
`|ml→ml difference|` = **4e-17** over 100 yr, against a largest difference anywhere in the
propagator of **0.27**.

**This is what makes the negative result general.** It is no longer "one advection scheme
failed" but "no reversal or rerouting of a closed vertical loop can change what the
atmosphere sees". Only something that changes the **mixed layer's own budget** can: a second
surface box, or the air-sea flux itself. The direct check agrees — with `kz` bisected to
hold the deep age, the outcrop makes δ¹³C **worse** (+0.548 → +0.608 at 4 m/yr SH-only),
exactly as the classic UD did (+0.628 at 1 m/yr).

**A correction to the previous entry's "one number".** The 10.5 yr equilibration vs 18.8 yr
flush ratio bounds how *fast* the mixed layer is renewed, not how much good the renewal
does; those come apart when the arriving water is very different from the ml. Renewing with
fully preindustrial water would leave the ml at τ_flush/(τ_flush + τ_eq) = **0.64** of full
equilibrium at 4 m/yr — a 36 % cut. So that argument alone did **not** rule out a non-local
deep-to-surface path; the operator symmetry is what rules it out.

**The off-diagonals are not tied, and there the outcrop is the better-behaved one.** At
4 m/yr the deep ocean sits at **−108 ‰** (both hemispheres) or **−135 ‰** (SH only) against
**−100 ‰** for classic UD, because the descending limb has to traverse the whole column
(~depth/w years) instead of injecting modern surface water into the bottom box directly —
and in the preindustrial steady state the water then ages monotonically downward, the
observed sense of the profile rather than its inverse. None of that reaches the atmosphere.
An SH-only outcrop also leaves the MLO−SPO δ¹³C gradient essentially untouched
(−0.226 ‰ vs −0.218 ‰ at `w_out_SH` = 4, against an observed −0.074 ‰ over 1993–2014).

Suite **426 pass / 4 fail / 2 skip** — the same four failures, plus 8 more guards.

## 2026-08-13 (later still, cont.) — The oceanic Suess effect, measured at last: the mixed layer is right and the atmosphere is not

Handoff 13b §6 left one lead open: *"the oceanic-Suess lead is still unverified. Model ml
declines 1.619 ‰ over 1750–2024 vs the atmosphere's 2.834 (ratio 0.57); my recollection of
the observed ratio is 0.35–0.45. No source in DATA.md, none in ClaudeDocs/Papers. If it
holds it is independent evidence for §4 [the conveyor]."* Marcus (2026-08-13) chose to
verify this **before** deciding whether to build the conveyor. **The lead does not hold,
and it fails in the direction that matters.**

**Two observational anchors acquired** (`DATA.md` §2b, `data-raw/download_data.R` [6b],
`build_calibration_data.R` [8b] → `data/obs_oceanic_suess.rds`):

- **Quay et al. 2003** (GBC 17(1):1004): global mean surface DIC δ¹³C fell
  **0.16 ± 0.02 ‰/decade** between the 1970s and 1990s. Has an error bar, and is
  independent of the atmospheric δ¹³C target the model already fits.
- **Eide et al. 2017** (GBC 31:492–514; data PANGAEA 871993, CC-BY): the gridded full
  ¹³C Suess effect. Reduced here to an area-weighted depth profile — **0.916 ‰ at 0 m,
  0.782 ‰ over 0–75 m**, preindustrial → GLODAPv1.1 era.

**The recollected ratio was wrong in both value and sign.** Measured, the observed ocean/
atmosphere ratio is **0.56** (cumulative, Eide) to **0.71** (rate, Quay); the model's is
**0.53–0.55**. The real ocean tracks the atmosphere *at least as closely* as the model's
does, not less closely. **Retracted as evidence for the conveyor.**

**And the ratio was the wrong statistic — it hid which limb is broken.** Split:

| | mixed layer | atmosphere |
|---|---|---|
| default params (`h_ml` 75 m) | **0.156 ‰/dec vs Quay's 0.160 ± 0.020 (−0.2 σ)** | **+25 % too fast** |
| posterior mode (`h_ml` 179 m) | 0.145 (−0.8 σ) | +21 % too fast |

The ml result is **window-insensitive** (0.153–0.160 across six plausible Quay windows) and
the atmospheric result **reproduces against Scripps flask** as well as Law Dome (model
0.291 ‰/dec over 1980–2014 against MLO 0.256 / SPO 0.233), so it is not an ice-core
smoothing artefact. Cumulatively the ml is +17 % too depleted at 75 m; the mode's +54 % at
179 m is **not a fair test** — a well-mixed 179 m box against a depth-average crossing the
real thermocline is not apples to apples, and is one more sign the fitted `h_ml` is not a
mixed-layer depth.

**The model's ocean takes up ¹³C at the observed rate. The δ¹³C misfit is not the ocean
failing to absorb the depleted signal.**

**Consequence for the conveyor, computed before building it** (`diag_oceanic_suess.R`
part 4). §4.3's mechanism *is* a reduction in ml depletion — the ml sits at
τ_flush/(τ_flush + τ_eq) of full equilibrium. Applying that factor to a ml Suess rate that
is already correct:

| Sv | equilibrium fraction | ml rate after | vs Quay |
|---|---|---|---|
| 15 | NH 0.70, SH 0.77 | 0.115 ‰/dec | **−2.2 σ** |
| 27 | NH 0.57, SH 0.65 | 0.095 ‰/dec | **−3.2 σ** |

**The conveyor pays for the atmosphere with the one ocean quantity that is currently
correct.** Both figures are conservative: the neglected feedback (a less depleted
atmosphere gives the ml less signal to follow) pushes the same way. The deep-age benefit is
not in question — the diagnostic reproduces §4.3's 1536 yr transit at 27 Sv exactly, an
independent check that the two scripts share constants.

**The caveat that keeps this honest, stated because it cuts both ways.** An atmosphere
declining 25 % too fast, driving a mixed layer that lands *exactly* on the observed rate,
implies the model's air–sea ¹³C transfer is ~20 % too **weak**: the ml looks right partly
through compensating errors, not because ocean ¹³C physics is verified. So "the ocean is
right" describes the model as it stands, not a proof. What survives regardless is the
**scoring** consequence — from here, any change that lowers the ml Suess rate makes the
model worse against a real measurement with a real error bar, and **until now nothing in
the likelihood would have noticed**.

**Verified, not assumed, about the Eide product:** above 200 m its field is the 200 m
back-calculation **plus a spatially constant depth offset** (level-to-level differences
have sd exactly 0; their method builds the shallow field from the 200 m estimate plus
coral/sclerosponge surface records). The global mean is usable; **the NH/SH contrast above
200 m is inherited and must not be used to score a hemispheric gradient.** The build
re-asserts this on every rebuild rather than trusting the comment.

**Open, and Marcus' call:** promote Quay's rate to a likelihood term. It is the only new
constraint here with a stated uncertainty, it is independent of the atmospheric δ¹³C
target, and it pins the air–sea partition that `q10` has been free to trade against.
**`sigma_d13c` remains unset and still blocking; this does not change the 0.45 ‰ argument**
(it removes a hoped-for route to shrinking the gap rather than shrinking it).

**Where the conveyor pre-check is weak, said plainly.** It applies §4.3's own equilibrium
fraction to the *current* ml rate, which treats the pre-conveyor mixed layer as if it were
at full isotopic equilibrium — §4.3 derives its "37 % cut" the same way, so the two are
consistent, but both ignore that the model **already** ventilates the ml diffusively. The
offsetting term is real and points the other way: §4.5 step 3 expects `kz` to fall a long
way once a conveyor carries the ventilation, and a smaller `kz` exports less depleted
carbon out of the ml, pushing its depletion back **up**. **So −3.2 σ is an upper bound on
the damage, not a prediction.** What the pre-check establishes is the **sign**, and the
fact that the trade is now scoreable at all — not the size of the miss. Only the run
settles that, which is why this is **a gate to run the conveyor against, not a veto**.

## 2026-08-13 (later still, cont.) — Conveyor APPROVED; configuration red team finds §4.3 divided by the wrong volume

Marcus approved building the conveyor and asked for a red-team review of the available
configurations through four lenses (ocean / atmosphere / isotope / reduced-complexity),
explicitly including the refit: *"once it is in properly, the other constants might all
shuffle around into a new equilibrium and I would like to test that."* Review in
`notes/redteam_2026-08-13_conveyor_configurations.md`; arithmetic folded into
`calibration/scoping_conveyor_arithmetic.R` so every number regenerates.

**§4.3's headline arithmetic divides by a volume the §4.2 plumbing does not traverse.** It
uses `V_deep` = the whole sub-mixed-layer ocean (1.309e18 m³); under §4.2's own four limbs
the water path is NH bottom → SH bottom → up the SH column → SH ml → NH ml =
**9.13e17 m³, 70 %**. **NH `oc1`–`oc9`, 30 % of the deep ocean, receives no advective flux
at all.**

**Correcting that and §4.3's own source-water caveat, the two errors nearly cancel:**

| basis | Sv for deep Δ¹⁴C = −170 ‰ |
|---|---|
| `V_deep`, no source correction (§4.3's headline) | 27.1 |
| `V_deep`, source −51.2 ‰ (§4.3's own hedge) | 37.7 |
| `V_path`, no source correction | 18.9 |
| **`V_path`, source −51.2 ‰ — the honest number** | **26.3** |

So the headline survives but **§4.3's hedge ("moves the −170 point to ~37 Sv") is too
pessimistic by 11 Sv**. The conveyor's strongest selling point is in better shape than the
handoff thought.

**But 27 Sv is far above the AMOC that actually has an error bar** — RAPID 26°N gives
**16.9 ± 1.2 Sv** (2004–2020). At 16.9 Sv on the real path the deep goes to **−230 ‰**,
outside the model's own [−150, −200] bracket. **The "27 Sv reproduces −170 ‰ from transit
alone" headline is retired**; the claim that survives is a **joint (Q, `kz`)** result —
transit sets the floor, diffusion mixes back the other way. Weaker, true, and still a large
improvement on bounding `kz` until the deep age came out right.

**The strongest case for building is not δ¹³C — it is `kz`.** At 5000 m²/yr it is **~9× the
measured thermocline diapycnal diffusivity**: Ledwell's NATRE tracer release gives
(1.7 ± 0.2) × 10⁻⁵ m² s⁻¹ = 536 m²/yr. A conveyor is what lets `kz` become an eddy
diffusivity instead of a fiction.

**Verified and consequential: the preindustrial column is EXACTLY uniform in DIC**
(2.0379 mol/m³ at all 11 levels, spread 2e-14 %). Advection is therefore a **pure isotope
operator** preindustrially — which is the clean decoupling on offer, and equally means it
**cannot** fix the ~14 % low ocean carbon inventory and **is not a biological pump**. The
limb is not small either: **20.8 GtC/yr at 27 Sv against 27.1 GtC/yr of gross air–sea
exchange.**

**Configurations.** A (§4.2 as written) is rejected as a final answer: sinking NH ml
straight to `oc10` leaves `oc1`–`oc9` on `kz` alone, so once `kz` falls the NH gets young
bottom water under anomalously old mid-depth water — an inversion the Atlantic does not
have — and it plumbs a limb named "NADW" to AABW depth. **Recommended: build C (sink to
NADW depth, `oc8`/`oc9`), with B (distributed descent) as the cheap comparison and A as the
intermediate they are diffed against; F (build nothing) stays the scored baseline.** D
(two-cell NADW+AABW) and E (second surface box / HILDA-lite) deferred.

**The refit is the point, and it needs prerequisites.** `kz`'s [3830, 6200] bracket **must
be deleted, not carried across** (12d §6 derives it on the pure-diffusion column), so the
honest accounting is *one parameter added and one constraint removed*. Q and `kz` are a
degenerate pair — both ventilate — so the deep-Δ¹⁴C likelihood term (12d §0 step 2) is now
a **prerequisite**, with Quay's ml Suess rate as the second leg. **Four predictions stated
in advance so they cannot be retrofitted:** `kz` falls toward 500–2000; `h_ml` falls from
179 m (currently 88 % of the way up its [30, 200] bound); `tau_ex` rises as the ocean takes
over part of the interhemispheric transport; MLO−SPO δ¹³C shrinks from −0.218 ‰ toward the
observed −0.074 ‰ **and may overshoot past zero**. *If `kz` does not fall and `h_ml` does
not come down, the conveyor is not doing the job it was proposed to do, whatever happens to
the log-posterior.*

**Cost corrected: 2–3 days, not §4.2's half a day** — the plumbing is half a day, but the
per-hemisphere deep diagnostic, the reverse-conveyor gate, the new likelihood terms, the
`kz` re-derivation and **~4 h per `run_modefind.R` refit × 4 refits** are not.

**One self-correction folded in.** `diag_oceanic_suess.R` inferred that air–sea ¹³C transfer
is ~20 % too weak. That is in tension with τ_eq = C_ml/F_gross = 10.5 yr (NH) / 10.0 (SH),
which is the textbook mixed-layer ¹³C equilibration timescale — isotopes ride the gross flux
unbuffered, so this is one of the model's better-grounded numbers. If τ_eq is right the
20 % lives elsewhere, most likely `h_ml`. Left open; the refit is what separates them.

## 2026-08-13 (later still, cont.) — The conveyor built and measured: the ml-Suess objection is dead, §4.4's own prediction fails

Marcus approved the red team's recommendation (build C, B as comparison, A as intermediate).
Built, tested, and measured. `R/model.R`, `src/ccx_core.cpp`, `R/spinup.R`,
`tests/testthat/test-conveyor.R`, `calibration/diag_conveyor.R`.

**§4.2's spinup claim is wrong, and it would have been invisible.** The handoff states
`ccx_spinup()` "needed no change at all" because a uniform ocean is still an exact fixed
point. **True within a column, false between them:** the two columns sit at different DIC
(SST 18 vs 16 °C → 2.03786 vs 2.05570 mol/m³), so the interhemispheric limbs see a real
gradient and converge 0.135 GtC/yr into the NH at 20 Sv. Skipping the solve leaves a
1.35e-01 residual and **−0.915 ‰ of spurious δ¹³C drift** over a zero-emission 1750–2024
run — nearly **twice** the entire misfit the conveyor was proposed to fix. Diagnosed, not
guessed: `sst_NH = sst_SH = 17` returns both to their conveyor-off values exactly. An
ocean-only solve was tried first and was *also* wrong — pinning both atmospheres at 278 ppm
left 0.1226 GtC/yr in the two atmosphere boxes, because the conveyor makes one hemisphere
outgas and the other ingas and the preindustrial atmosphere must carry a small gradient.
`ccx_c12_steady_conveyor()` is a Newton on the **full state** using `ccx_deriv()` itself as
the residual, global CO₂ pinned and the split free. Residual 1e-13, drift 0, R/C++ parity
exact. **Physically this also means the conveyor is not the pure isotope operator between
columns that it is within one — it is a crude solubility pump.**

**The reverse-conveyor gate passes.** Reversed, the atmosphere differs (0.15 ppm CO₂,
1.8 ‰ Δ¹⁴C) and the deep ages **swap**: forward NH −113 / SH −157, reversed NH −159 /
SH −120; conveyor off they are equal (−170.8 / −169.5). Read off an **integrated** run —
the conveyor touches no atmospheric box directly, so a derivative-level assertion could
never fail, which is how the first version of the gate was written and why it "tied".

**The red team's ml-Suess objection was wrong by 4×, in the way the red team said it might
be.** It estimated −3.2 σ against Quay while flagging that as an upper bound because a
falling `kz` pushes back. Measured at fixed `kz`: 0.156 → **0.147 at 20 Sv (−0.6 σ)**. And
once `kz` falls the rate goes the **other way and overshoots from above** — 0.185 at
kz 2000, 0.212 at kz 1000, 0.237 at kz 500. **`kz` is now squeezed from both sides** (deep
age wants it small, ml Suess wants it large), which is a better position than the
degenerate ridge that was predicted.

**The structural win is real: the deep ocean goes bipolar.** Off, both hemispheres are the
same age. On (C, 20 Sv): kz 5000 → NH −113 / SH −157; **kz 2000 → NH −159 / SH −223**;
kz 1000 → NH −214 / SH −277. That is the observed sense (young ventilated end, old far
end). **But `CCX_PARAM_TABLE`'s [−150, −200] bracket is a global-average target derived on
a single-column ocean and is the wrong yardstick for a bipolar one** — the deep-Δ¹⁴C target
must be chosen *before* the refit, not after seeing this table. **Flagged for Marcus, not
resolved.**

**Two results against the proposal:**

1. **§4.4's falsifiable prediction FAILS.** It states the conveyor should shrink the NH−SH
   δ¹³C gradient and that "if the gradient does not shrink, the mechanism is not doing what
   this section says." MLO−SPO goes **−0.218 → −0.221 (20 Sv) → −0.223 (27 Sv)** — very
   slightly the *wrong* way, against an observed −0.074. Falling `kz` recovers only −0.215.
2. **`kz` cannot actually fall far**, which was the strongest argument for building at all.
   Dropping it degrades both remaining constraints: δ¹³C bias +0.500 → +0.678 (kz 2000) →
   +0.820 (kz 1000), CO₂ bias +5.4 → −5.8 → −12.5 ppm. At *fixed* kz the conveyor helps
   δ¹³C (+0.548 → +0.500 at 20 Sv, +0.483 at 27 Sv) — real, and about a **third** of §4.3's
   hoped 0.15–0.25 ‰.

**None of this is a verdict.** Every parameter except `q_conv` and `kz` is frozen at its
default; `k_w`, `h_ml`, `beta` and `q10` are all free to absorb some of it. **The refit is
the experiment** and the red team's four advance predictions are still the scorecard — on
this evidence the fourth is already in trouble.

Suite **462 pass / 4 fail / 2 skip** — the same four pre-existing failures, +36 assertions.
`CCX_PARAM_TABLE` untouched; `sigma_d13c` still open and still blocking.

**Preindustrial interhemispheric gradient — is it observable?** (Marcus asked, 2026-08-13.)
The conveyor gives the preindustrial atmosphere a gradient it did not have: **+0.149 ppm
CO₂** and **+2.40 ‰ Δ¹⁴C** at 20 Sv (both exactly 0 and +1.00 ‰ with it off).

- **CO₂, Greenland vs Antarctic ice: NO, and not marginally.** Greenland ice CO₂ runs
  **20–30 ppm above** the Antarctic composite with a standard deviation of **6–10 ppm**
  (Antarctic 2–3), from **in-situ production** by carbonate–acid reactions and oxidation of
  organics on Greenland's much higher carbonate load (~0.4 ± 0.2 µmol/L). Anklin et al.
  1995; Barnola et al. 1995; Tschumi & Stauffer 2000. **The artefact is ~150× the predicted
  signal and the scatter alone ~50×.** Antarctic cores are the reliable CO₂ record
  *precisely because* Greenland's are not, so no ice-core pair constrains this.
- **Δ¹⁴C: YES, and it is the apposite test.** **SHCal20 puts the SH 36 ± 27 ¹⁴C yr older**
  than the NH = **+4.49 ± 3.38 ‰** on the Libby mean life. The model goes from **+1.00 ‰
  (22 % of central, z −1.04)** to **+2.40 ‰ (53 %, z −0.62)**. Right direction, about half
  the gap closed — and it matters more than the arithmetic suggests, because the observed
  offset is driven substantially by **Southern Ocean upwelling of ¹⁴C-depleted water**,
  exactly the limb the conveyor adds. Honest limit: ±27 yr is too wide to discriminate
  strongly, and OFF is also inside 1 σ. **This is the independent, already-observed test
  §4.4 wanted and did not get** — a third candidate likelihood term for Marcus.
- **One unverified lead, flagged not adopted:** a search result attributed to a CanESM1
  preindustrial control states the preindustrial CO₂ gradient was **reversed** from today's
  (SH higher). If true our +0.149 ppm has the wrong **sign**. From a model paper via a
  search snippet, not observations, and not read. Check before the sign is ever quoted.

Handoff: `notes/handoff_2026-08-13c_conveyor_built.md`.

## 2026-08-13 (d) — Expert panel: model structure against the PEDAGOGICAL spec

Marcus asked for a **carbon-cycle expert** added to the ocean / atmosphere / ecosystem /
isotope / pedagogical / reduced-complexity lenses, to settle the best model structure given
the goal of matching monthly CO₂ and isotopes *understandably* — motivated by the "**5-year
CO₂ residence time**" and "**CO₂ correlates with temperature**" arguments. **That motivation
had never been written down as a specification**; DESIGN §1's four goals do not contain it.
This session treats the two fallacies as design requirements and measures the model against
them. Panel: `notes/expertpanel_2026-08-13_structure_for_pedagogy.md`; every number
reproduced by `calibration/diag_pedagogy.R` (~3 s), which carries its results in its header.

**The structure the two fallacies demand is already built.** From one spinup, one parameter
set, two paired perturbations — a **100 GtC mass pulse** and a pure **¹⁴C label pulse**:

| yr | mass airborne | label remaining |
|---|---|---|
| 1 | 0.893 | 0.811 |
| 10 | 0.604 | 0.292 |
| 100 | **0.262** | **0.058** |
| 300 | 0.171 | 0.029 |

**Instantaneous label decay time 4.32 yr** — *the model hands you the sceptic's own number,
computed correctly, as a property of gross exchange* — against a mass 1/e of **40.3 yr** and
a **4.5× gap at 100 yr**. The gross-flux architecture that does this exists **because the
isotopes forced it** (`model.R:278`, the singular preindustrial isotope operator, 2026-08-10).

**Temperature → CO₂ is real, right-signed, and an order of magnitude too small.** +1 K held
with zero emissions gives **+5.19 ppm @10 yr, +10.74 @300 yr** ≈ **10.7 ppm/K**; against the
model's own 1.20 K of 1960–2023 warming that is **12.9 of the 102.5 ppm rise — 13 %**.
**The isotopes decide it by sign:** splitting the +1 K response at 300 yr, the solubility
limb (ocean outgassing) moves δ¹³C **+0.0354 ‰ — UP**, the land limb −0.0760, both −0.0410,
against an observed/model **−1.773 ‰**. *"The warm ocean is outgassing it" predicts δ¹³C
rising; it falls, by 1.77 ‰, and even the right-signed land limb is 43× too small.* Model
ocean is a **net sink**: +172.6 GtC cumulative, +2.60 GtC/yr over 2015–2024.

**The model reproduces the sceptic's headline statistic.** cor(CO₂ **growth rate**, GMST) =
**+0.930** over 1960–2023 while 100 % of its trend is emissions-driven; detrend both and
r = **0.582** — the genuine ENSO link, which explains wobbles, not the rise.

**The ocean-structure debate is nearly irrelevant to any of this.** Conveyor C at 20 Sv with
`kz` 2000 moves AF@100 **0.262 → 0.284**; choosing a **2024 background** instead of
preindustrial moves it **further, to 0.298** (turnover 7.13 → 9.25 yr). **A control the app
already exposes outweighs the whole conveyor question.** Decide the conveyor on
oceanography — but **it is not blocking the app**, and the panel endorses handoff 13c §0.1
that `sigma_d13c` must not be blocked on it either.

**The one structural gap that does matter: `ccx_run()` emits no fluxes.** It returns stocks
and ratios only; `add_flux()` computes the gross fluxes and discards them. So the central
pedagogical quantity (τ_turn = M_atm / F_gross) is not computable from model output — above
it had to be recovered *indirectly* from a label-pulse slope — and the "Under the hood" box
diagram (`app/server.R:213`) draws **six unlabelled arrows**. **R1: an opt-in flux trace.**
No physics changes and the conservation test gains a free extra check.

**Two defects found while measuring.**
- **74.1 GtC of pre-1850 LUC emissions are invented, silently.** GCB's LUC is `NA` for
  **1750–1849**; `ccx_annual_to_monthly()`'s `approx(rule = 2)` holds the 1850 value flat
  backwards. The forcing carries **321.6 GtC of LUC against 247.5 in the source — 23 % is
  extrapolation.** Not a conservation error (LUC is a veg→atm transfer) and a nonzero
  pre-1850 flux is defensible; **the objection is that nobody chose it** — GMST's identical
  flat-hold warns on every build and `d13c_foss`'s carries a justifying comment. **R3,
  flagged as a methodological choice for Marcus, not resolved.**
- The box diagram says **"Vegetation / Soil"** against a **four-pool** land model
  (`model.R:80`, since 2026-08-12) — labels-vs-structure drift. **R6.**

**Also recommended:** **R2** a "no emissions" counterfactual (the switch list lets a user
turn off every *sink* but not the *source*); **R4/R5** the two tabs the project's stated
purpose actually lives in — *"How long does it last?"* and *"Does temperature cause CO₂?"* —
neither of which exists in DESIGN §7; **R7** adopt the Joos et al. (2013) CO₂ IRF as a §6
sanity gate, because **nothing in the eleven gates scores the pulse response**, which is the
quantity the app's flagship tab reports. *(The model's AF@100 on a 2024 background is 0.298;
my recollection of the multi-model IRF is ~0.4, which would make this pulse decay too fast —
**stated as a test to run, not a finding**, and the paper has not been checked.)*

**Everything here is at `ccx_default_params()`, not the posterior mode** (`h_ml` 179 m,
`kz` 6031, both pushing toward more uptake and a shorter adjustment time). **The
pedagogical curves must be recomputed at the mode before anything ships.** Ocean uptake at
defaults is 2.60 GtC/yr against GCB's 3.22 — 19 % low, a known consequence of not using the
mode, not a new finding.

**Verdict: the model is at the right complexity and the risk now is drift upward.** The
highest-value remaining work is an output layer, a two-line switch, a provenance fix and two
tabs of existing material — **none of them adds a box or a parameter.**

## 2026-08-13 (e) — Marcus' four directives from the expert panel

All four of the panel's blocking items answered. **Suite 490 pass / 4 fail / 2 skip** — the
same four pre-existing failures throughout.

### 1. The flux trace (R1) — approved and built

`ccx_run(fluxes = TRUE)` now returns the gross and net fluxes `add_flux()` was discarding.
The recorder is a **tap inside `ccx_deriv`'s own** `add_flux`/`add_source`/`add_diffusion`,
not a second derivation: `test-fluxes.R` asserts the recorded per-box carbon equals
`dy[, "C"]` **exactly**, which is the completeness check *and* a free extra conservation
check on the core. Edges are classified by the **reservoir type of their endpoints**, so a
flux added later is captured automatically; explicit labels exist only for the three cases
where one endpoint pair carries two processes (seasonal NEP vs GPP, land-use vs autotrophic
respiration, ENSO vs heterotrophic). `ccx_run_fast()` — the C++ core the sampler calls — is
untouched and `fluxes` defaults `FALSE`.

**The app's box diagram now carries the numbers** (R6): ~72 GtC/yr photosynthesis and
~95/93 each way air–sea against ~11 of emissions, and land boxes that admit to four pools.

**And it corrected a number in a deliverable.** τ_turn = M_atm ÷ gross outflux = **4.69 yr
at 1750, 5.32 by 2024** — not the 4.32 yr the panel note and `diag_pedagogy.R` reported
from a one-month label slope. Seasonal NEP is a real atm→leaf flux that integrates to zero
annually, so it is excluded from the gross outflux: right for the annual mean, wrong for a
January finite difference, which the January drawdown biases fast. **Tested, not argued** —
with seasonality off the two independent routes agree to **0.2 %** (4.700 vs 4.692).

**Also:** `gamma_enso = 0` added to `ccx_default_params()`. It was **absent**, so
`ccx_deriv()` died with "argument is of length zero" on default parameters while
`ccx_cpp_par()` silently substituted 0 — an **R-vs-C++ divergence about what the defaults
mean**, which is what the bit-parity rule exists to prevent. 0 is behaviour-preserving; the
table's init of 0.5 would have silently changed every existing default-parameter result.

### 2. Pre-1850 land-use emissions (R3) — sourced

GCB's LUC column is **empty before 1850**; `approx(rule = 2)` held the 1850 value flat
backwards, **inventing 74.1 GtC** — 23 % of the model's land-use carbon. Replaced with
**OSCAR v3.1** (Gasser et al. 2020, *Biogeosciences* 17:4075, doi:10.5194/bg-17-4075-2020;
data doi:10.5281/zenodo.7313542, CC-BY), which runs from 1701 and reproduces that paper's
headline **206 ± 57 PgC** exactly — the check that the right column was read.

**Rescaled, not spliced raw:** OSCAR's 1850–2018 total is 34 % below GCB's, so grafting its
absolute values on would put a **62 % step** at the join. OSCAR supplies the shape and the
pre/post share, rescaled over an 1850–1900 overlap adjacent to the splice. **41.8 GtC, 6 %
step.** Scored against Law Dome 1750–1850 (`diag_pre1850_luc.R`): adopted **2.00** ppm RMSE,
flat-hold 2.48, OSCAR absolute 2.77, **zero 4.50 — zero is excluded by the data**. The
flat-hold was not absurd, just the right integral over the wrong shape (too big too early:
+3.8 ppm at 1775 against the adopted series' +1.0).

**Two things it does NOT fix:** every option is **~6.5 ppm low at 1900** and none reproduces
the full 18th-century rise — a separate 19th-century deficit, larger than this question.
And **`mode_fit.rds` now predates the forcing and is stale.**
`ccx_build_forcing()` warns on any NA emissions year inside the window so this cannot recur.

### 3. Joos et al. 2013 (R7) — DESIGN §6 gate 12, and future pulses

Marcus supplied the paper. **Two answers, pointing different ways, both reported:** the
**point** IRF is below the multi-model mean at every horizon (0.313 vs **0.409** at 100 yr —
so the recollection recorded as an unverified test was right about Joos), but the
**time-integrated** IRF, the quantity Joos actually puts ranges on, is **inside the 5–95 %
range at 20, 50 and 100 yr** (12.6 / 26.2 / 43.6 against 12.2–16.3 / 24.0–36.6 / 39.5–65.2).
**The honest headline is the second with the first as caveat** — the panel note's flat
"decays too fast" overstated it. The model is on the **low side of the literature but within
it**, which is the *conservative* direction for the app's argument.

It also reproduces Joos's **PI < PD ordering** (39.2 vs 46.3 yr against his 34–47 / 45–62) —
a Revelle result — and on **coupled** SSP backgrounds IRF@100 rises monotonically
**0.342 (ssp126) → 0.512 (ssp585)**, with IRF@20 of 0.62–0.71 against Joos's "~70 % within
two decades in every scenario".

**Three method failures, recorded because two looked correct.** An online controller for
Joos's diagnosed compatible emissions needs `ccx_deriv` in the stepping loop (~60k pure-R
calls per run). A **Newton step on the monthly drift diverges to 2e34 ppm** — the response
operator is lower-triangular, not diagonal, so per-month correction compounds; a
least-squares solve on a relaxation-exponential basis holds the background to 0.26 % in
0.3 s (**a polynomial basis must not be added back — ill-conditioned, diverges**). And the
**SSP emissions table is decadal**, so adding the pulse to the 2050 row delivered **1000 GtC
for a nominal 100**, giving an IRF of 6.9 — impossible by inspection, since an IRF cannot
exceed 1. Densified to annual; delivered mass now asserted. Separately, `sprintf()` with a
zero-length argument returns `character(0)` and `cat()` prints nothing, so a mistyped field
name dropped an entire table **silently with exit status 0**. Guarded.

### 4. The two tabs (R4/R5) — specced, with Marcus' framing

**"Concentrate on the positive learning and not on the debunking"** (Marcus). So DESIGN §7
gains **tab 5 "How long does it last?"** (two curves from one model; the observed bomb
spike beside the observed Keeling curve; the background slider) and **tab 6 "What drives
CO₂?"** (the correlation, then detrended, then the two counterfactuals, closing on δ¹³C's
sign). The fallacious arguments are a **short signposting appendix inside "Under the hood"**
(§7a), not a tab — *published claim → published response → which panel bears on it*, naming
arguments rather than characterising people. Essenhigh (2009) `doi:10.1021/ef800581r` with
**Cawley (2011)** `doi:10.1021/ef200914u`; Harde (2017) `doi:10.1016/j.gloplacha.2017.02.009`
with **Köhler et al. (2018)** `doi:10.1016/j.gloplacha.2017.09.015`; Salby and Spencer as
non-peer-reviewed links. All four DOIs verified against Crossref, not recalled.
**Cawley (2011) is the anchor for tab 5** — its whole point is that a short residence time
and a long adjustment time are both consequences of the same model, which is exactly what
the paired ¹⁴C-label and mass pulses show here. **Spencer's is the subtle one**: not wrong
arithmetic but a **fixed-equilibrium assumption**, and the model's equilibrium point is not
a parameter — it emerges from carbonate chemistry, which the "frozen Revelle" switch already
isolates. **DESIGN §1 gains the fifth goal.** Tab implementation is NOT done; the appendix
wording is Marcus' call.

**R2 built:** a **"no emissions"** switch — every existing switch turned off a *sink*, none
the *source*. Over 1750–2024 it gives **−134 ppm** (back to 285, essentially preindustrial)
against the warming feedback's **−10 ppm**. That contrast is the whole of tab 6 and it is
now pinned by a test.

## 2026-08-13 (f) — Handoff, and the ocean's missing vertical structure

`notes/handoff_2026-08-13e_marcus_directives.md`.

**Measured while answering Marcus' question about a biological pump, and it is a finding in
its own right:** at the preindustrial spinup the ocean's **DIC is exactly uniform at
1986.3 µmol/kg and δ¹³C exactly uniform at +1.560 ‰ through all eleven layers**. Only Δ¹⁴C
has a vertical gradient (−51 → −187 ‰), because that one is built by decay plus diffusion
and needs no biology. **1986 µmol/kg is a realistic *surface* value applied to 3700 m of
ocean.**

Total ocean carbon 32,827 GtC; to reach the canonical ~38,000 the model would need a
volume-weighted mean DIC of **2299 µmol/kg**. **So the ~14 % inventory deficit and the
missing vertical DIC gradient are the same number, and that number is the soft-tissue
pump.** *(The 2299 is the model's own arithmetic. Observed deep DIC/δ¹³C values quoted in
the handoff are recollection — GLODAPv2 is the source to pull before any of it is scored.)*

**New and previously unlisted: the model's deep ocean is ~1–1.5 ‰ too enriched in DIC
δ¹³C** — in the tracer this project has spent a fortnight fighting, and nothing has ever
scored it.

**The structural consequence bounds what a pump could do here.** The interior carries **no
carbonate chemistry** (`pco2_from_dic()` is called only for the mixed layer), and in steady
state the mixed layer's DIC is **chemistry-pinned** by ALK, SST and the spinup's pCO₂
target. So a pump cannot change surface DIC, cannot change the Revelle factor, and cannot
change the IRF to first order — it changes the interior, and the interior reaches the
atmosphere only through what ventilation brings back up. **A pump alone is mostly
bookkeeping; a pump plus a return path is a mechanism.**

**Why it is nonetheless the most interesting option on the table:** the observed
surface-to-deep DIC and δ¹³C gradients are **currently exactly zero in the model and
therefore entirely unused as constraints**. A pump turns both into observables, and because
a pump's gradient is set by **export ÷ ventilation**, they constrain ventilation directly —
which is what handoff 13c §5 says the refit needs and cannot get, **without requiring the
deep-Δ¹⁴C target to be settled first.** Costs: +2 parameters on a model the panel just
called correctly sized, and a pump injects surface-¹⁴C carbon into the deep non-locally,
making it *younger* and working against the deep-age constraint — **magnitude unmeasured.**
Pedagogically it passes the test the conveyor failed: one famous sentence, and it explains
the 50× ocean:atmosphere stock ratio the app already displays.

## 2026-08-13 (g) — The 1900 deficit diagnosed: land-use carbon has an airborne fraction of ZERO

`calibration/diag_1900_deficit.R`. Discharges handoff 13e §0.4 — "a NEW, UNDIAGNOSED
MISFIT ... larger than the question that surfaced it and nobody has looked at it."

**It is not a 19th-century problem and it is not about the 19th century.** The model
undershoots Law Dome by ~6.5 ppm at 1900 because **land-use emissions have an airborne
fraction of 0.002 at 100 years**: the land takes back every tonne deforestation releases.

**THE CLUE WAS INSIDE `diag_pre1850_luc.R`'s OWN TABLE AND WAS READ PAST.** Four pre-1850
LUC options spanning **0 → 74.1 GtC** of cumulative emissions land within **0.38 ppm** of
each other at 1900, having been **6.09 ppm** apart at 1850. Fifty years erased 94 % of a
74 GtC forcing difference, against the model's own 50-yr point IRF of 0.397. Suspicious
uniformity, per the standing rule, is a code path until disproven — and it was.

**THE MECHANISM.** LUC is a transfer out of the wood pool (`98c1783`, 2026-08-12, and
right on its own terms: `add_source()` created ¹⁴C ex nihilo). But wood has a restoring
fixed point, so what deforestation removes, the model **regrows**:

```
d(δW)/dt = φ(1−f)·npp0/veg0 · δW − δW/tau_wood
         = 0.5·0.4/8.6 − 1/20 = −0.0267 /yr   →   37.4 yr
```

**MEASURED, NOT ARGUED** (§3, and it depends on no historical forcing, no observation and
no fit): 100 GtC in 1760, zero-emission background, GMST and ENSO frozen, control flat to
+0.027 ppm over 275 yr.

| airborne fraction at lag | 10 | 25 | 50 | 100 | 150 |
|---|---|---|---|---|---|
| external source | 0.605 | 0.445 | 0.337 | **0.262** | 0.226 |
| wood transfer | 0.577 | 0.260 | 0.072 | **0.002** | −0.003 |

**A fossil emission is permanent in this model; an LUC emission is a transient the land
takes back in full.** GCB reports E_LUC and S_LAND as separate terms (`gcb_budget.rds`
carries them as separate columns) and the model's β-fertilisation uptake is the analogue of
S_LAND — so regrowing what E_LUC removed adds a second, unbudgeted land sink on top of the
one already parameterised. Whatever share of regrowth E_LUC does or does not net out,
**full recovery to the preindustrial stock is not defensible: converted land is farmed.**

**IT IS A REGRESSION, dated.** `98c1783` landed 2026-08-12; the deficit was noticed
2026-08-13 and mis-attributed to the pre-1850 LUC question, which cannot touch it.

**HOW BIG, over the whole record** (default parameters, LUC routed as an external source
being mass-exact and isotopically meaningless, which is all §2/§5 read off it):

| | 1900 | 1930 | 1960 | 1990 | 2010 | 2024 |
|---|---|---|---|---|---|---|
| shipped (LUC = transfer) | −6.51 | −9.08 | −4.01 | −5.65 | −5.37 | −6.02 |
| LUC permanent | +1.62 | +3.22 | +13.44 | +19.02 | +24.29 | +27.44 |

**The regrowth path accounts for 125 % of the 1900 deficit — handled permanently the model
OVERSHOOTS — so this is not a missing source.** Cumulative land 1750–2024: model **+29.4
GtC** against GCB 2025's **−57.4**. *The model's land is a net **sink** where the budget
says net **source**.*

**AND IT IS INSIDE THE LIKELIHOOD.** Scanning β at fixed everything-else against the CO₂
record (Law Dome then MLO, 1850–2024): the transfer path prefers **β = 0.30**, a permanent
LUC prefers **β = 0.70**. **The treatment biases β down by ~2.3×.** Stated with its limit:
`mode_fit.rds` has β = 0.088, *below* even the 0.30 the transfer path prefers, so the LUC
defect is a **contributing** bias and not the whole story — the other 15 parameters and the
δ¹³C/¹⁴C streams are not in a 1-D scan. **Do not read §6 as attributing the mode.**

**NOT FIXED HERE, and deliberately.** The fix is not reversion — the ¹⁴C-ex-nihilo reason
for the transfer stands. It is to make the **debit permanent**, which means the land's
equilibrium stock must fall as land is converted: a structural change to a model the expert
panel just called correctly sized, and therefore Marcus'. Options and costs are in
`notes/handoff_2026-08-13f_luc_regrowth_double_count.md`.

**Sharpens `mode_fit.rds` is stale from "the forcing moved" to "the forcing moved AND the
model gives land-use carbon away".** A refit before this is settled would fit the defect.

## 2026-08-13 (h) — The converted-land term: the land-use debit is made permanent

Marcus chose **route A** from `notes/handoff_2026-08-13f` §4. DESIGN §3.3 gains the
converted-land term; `calibration/diag_1900_deficit.R` is rewritten around it;
`tests/testthat/test-luc-permanence.R` is the gate. **Suite 505 pass / 2 fail / 2 skip**,
up from 490 / 4 — and *which* two stopped failing is a finding in itself (below).

**THE TERM.** Cumulative land-use carbon defines a cleared fraction
`c(t) = f_luc_perm · cumLUC(t) / land0`; NPP₀ and veg₀ are both scaled by `(1 − c)`.

**`land0` IS TOTAL LAND CARBON, ALL FOUR POOLS — NOT `veg0`, AND THE DIFFERENCE IS THE
WHOLE POINT.** Scaling NPP₀ scales every pool's equilibrium, so the land's equilibrium
carbon falls by `c · land0`. Setting `c = cumLUC / land0` makes that fall equal what
deforestation removed — the debit is permanent *by construction*, with `f_luc_perm = 1` as
the mass-consistent point rather than a fitted one. Using `veg0` would shrink the
equilibrium by a quarter of what was taken and the land would re-absorb the rest.

**MEASURED, and the fix is not tuned to any of it:**

| airborne fraction at lag | 10 | 25 | 50 | 100 | 150 | 264 |
|---|---|---|---|---|---|---|
| fossil | 0.605 | 0.445 | 0.337 | **0.262** | 0.226 | 0.180 |
| LUC, `f_luc_perm = 0` (the bug) | 0.577 | 0.260 | 0.072 | **0.002** | −0.003 | −0.001 |
| LUC, shipped | 0.646 | 0.362 | 0.193 | **0.130** | 0.127 | 0.131 |

**THE INDEPENDENT CHECK NOBODY AIMED AT.** Cumulative land 1750–2024 goes **+29.4 →
−53.6 GtC** against GCB 2025's **−57.4**, and the ocean **+169.1 → +202.2** against
**+209.8**. The fix was derived from the pulse argument and the budget's own column layout;
that it lands the *partition* on GCB is a result, not a target.

**WHY ~50 % AND NOT 100 %, tested rather than argued.** The debit lands on wood (37 yr)
while the equilibrium reduction is pro rata, 70 % of it in a 500-yr passive soil. Predicted
consequence: shorten that pool and the ratio should go to 1. **At `tau_soil_slow = 20` it
is 1.02 at 100 yr and 1.01 at 150 and 264.** Confirmed. Closing the remainder means
debiting the pools **pro rata**, which trades against the 2026-08-12 call that the emitted
carbon carries wood's lagged ¹⁴C — **an open decision for Marcus, recorded, not taken.**

**TWO SUITE FAILURES WERE NEVER A STALE FIXTURE.** `test-likelihood.R:114/117` ("a CO₂
level bias is expensive") were written off as an AR(1)-era leftover in handoffs 12d, 13,
13b, 13c and 13e. They now pass, and the link is **causal, not coincidental**: at
`f_luc_perm = 0` the test's own quantity is `cost(+1 ppm) = −183.1` — adding a positive
bias *improved* the fit, because the model was systematically low — and at `f_luc_perm = 1`
it is **+534.5**. The suite had been reporting this bug since the day it landed and the
report was relabelled five times. *A failing test you have explained away is still data.*

**WHAT THIS COSTS.** At the default β = 0.38 the model now runs **+17.5 ppm high at 2024**,
because that default was centred against the bug. The CO₂ record's preferred β on a 1-D
scan moves **0.30 → 0.50**. And δ¹³C moves the **wrong** way: the 1900→2020 Suess decline
goes −2.209 → −2.366 ‰, **7.1 % faster**, against a model already ~25 % too fast. Both
arms keep LUC as a wood transfer, so unlike 13f §3's proxy this comparison is isotopically
clean. **The 13b/13c ocean conclusions must be re-measured on the fixed model.**

**Three things the change caught on its way in, all real:**

1. **`quiet_forcing()` in `test-conveyor.R` zeroed the LUC *flux* and not the LUC *stock*,**
   which asks the model to relax a pristine spinup toward a smaller land — a genuine drift
   the conveyor tests would have read as a conveyor failure. Zeroing only the flux is not
   "quiet".
2. **The `emissions` mechanism switch had the same hole**, and it is worse there because it
   is user-facing: "what if we had never emitted" would have left the land relaxing toward
   an equilibrium shrunk by ~290 GtC of clearing the counterfactual never did. Fixed in
   `R/mechanisms.R`; `test-mechanisms.R:54` was the gate that caught it.
3. **A window that starts mid-record no longer begins at a fixed point.** `ccx_spinup()`
   supplies preindustrial land; a run starting in 1900 hands it a land already shrunk by
   88 GtC of clearing. `ccx_build_forcing()` now **warns** (`FORC_LUC_PRE_WARN`). Honest
   rather than silent — but it means windowed drivers carry a start-up transient, and the
   48 warnings in a suite run are all real ones.

**Layout contracts touched, both stated on both sides:** `CCX_FORCING_COLS` gains
`cum_luc_NH`/`cum_luc_SH` **appended** (10 → 12, `N_FORCING` in `src/ccx_core.cpp`), and
`CCX_LUC_CLEARED_MAX` is duplicated as `LUC_CLEARED_MAX` in the C++ because the two
implementations are independent by design — *nothing catches a disagreement in that one,
so if one moves the other must move in the same commit.* The parity fixtures now carry a
**non-zero** `cum_luc`, because at zero the new term collapses to `(1 − 0)` and the gate
would be inert — cf. "mutation-test your gates".

**`ccx_spinup()` is untouched and every pre-2026-08-13 spinup result is bit-identical:**
the spinup's zero forcing has no LUC flux, so `ccx_forcing_cum_luc()` returns zero and the
cleared fraction is zero. A forcing that carries LUC emissions and *no* `cum_luc` is an
**error**, not a zero-default — defaulting it would restore the bug through a code path
nobody chose.

## 2026-08-13 (i) — Answering "is there a path forward?": the q10 inversion was the LUC bug

Two diagnostics, both written to answer Marcus' question, and one of them **overturns an
attribution this repo has carried since 2026-08-12**.

### `diag_d13c_partition_refit.R` — the obvious hope, tested and FAILED

`diag_d13c_suess.R` §3's verdict — "δ¹³C and CO₂ cannot both be satisfied by any partition
this model can reach" — was computed on the model whose land had the **wrong sign**
(+29.4 GtC where GCB says −57.4). It had to be re-run. **It survives.**

| | β that zeroes δ¹³C | β that zeroes CO₂ | gap |
|---|---|---|---|
| `f_luc_perm = 0` | 0.93 | 0.36 | **0.57** |
| `f_luc_perm = 1` | 1.18 | 0.59 | **0.59** |

Both crossings move up by ~0.24; **the gap does not close.** The converted-land term does
not relieve the δ¹³C misfit, and no one should expect it to. Recorded as a **measured
negative** so the hope is not re-formed later.

*A unit trap this file fixes:* §3 compared `mean(diff(land_C))` with GCB's `land_sink`.
Those were nearly the same quantity while LUC was being regrown and are **not** now —
`diff(land_C)` is the net land flux (sink *minus* LUC), GCB's `land_sink` is the residual
sink alone. The gross sink is `diff(land_C) + LUC`, and that is what the share uses here.

### `diag_which_stream_pays.R` — and this one is the finding

`diag_d13c_suess.R` states: "the calibration's only remaining way to relieve [the δ¹³C
bias] is to manufacture land sink — which is what q10 → 0.17 is doing." That is an
attribution, and it had never been measured. A (β, q10) slice at the mode, scoring each
stream separately via `ccx_loglik(by_stream = TRUE)`:

| stream | optimum, `f_luc_perm = 0` | optimum, `f_luc_perm = 1` |
|---|---|---|
| CO₂ | β 0.10, q10 0.20 | β 0.50, **q10 1.50** |
| δ¹³C | β 0.70, q10 0.50 | β 0.90, q10 0.20 |
| Δ¹⁴C | β 0.30, q10 2.50 | β 0.70, q10 2.50 |
| **total** | **β 0.10, q10 0.20** | **β 0.50, q10 1.50** |
| `mode_fit.rds` (fitted on `f_luc_perm = 0`) | β 0.088, q10 0.169 | |

**δ¹³C is not what drives q10 down.** At the mode's own `sigma_d13c` = 0.44 ‰ its surface
is flat to **~3 log-units** across the entire q10 range, while CO₂'s falls **3200**. CO₂ is
the sharp stream in q10 — and on the fixed model it wants **q10 = 1.5 and β = 0.50, both
defensible**. Cost of moving to β 0.5 / q10 2.0: CO₂ 39.9 log-units, δ¹³C 2.8, Δ¹⁴C 0.2.

**The control is what makes it an attribution.** On the buggy model the same slice puts the
total optimum at the grid **corner** (0.10, 0.20) — at or beyond the edge — reproducing
`mode_fit.rds`'s (0.088, 0.169). **The q10 inversion was the land-use regrowth bug forcing
a compensating low-β/low-q10 pair.** With the land illegitimately absorbing every tonne of
LUC carbon, the sampler had to kill the other land sink (β) and then invert the soil
temperature response (q10 < 1 makes respiration *fall* as soil warms — the wrong sign) to
recover the CO₂ trajectory.

**Bounded, not settled:** the other 14 parameters are held at values themselves fitted to
the bug. The refit decides it. Two claims deliberately *not* made: no comparison of this
model's β to C4MIP's (different quantity — `reference_arora2020_c4mip_gamma` is γ_L), and
q10's indefensibility is argued from its **sign**, which needs no citation.

### What still does not match, and where that points

At the slice optimum the model's 2015–2024 **land sink is 3.41 GtC/yr against GCB's 2.36,
and its ocean sink 2.99 against 3.22.** Land too strong, ocean too weak — and the ocean is
the reservoir with the known structural deficiency (inventory ~14 % low, **no vertical DIC
or δ¹³C gradient at all**, `kz` 9× Ledwell's NATRE value). That is where the biological
pump case now lives, and it is a stronger case than before: those two gradients are
**exactly zero** in the model and therefore entirely unused as constraints, so any pump
improves two measured mismatches — and its gradient is set by export ÷ ventilation, which
constrains ventilation **without** first settling the deep-Δ¹⁴C target.

**The pump's effect on atmospheric δ¹³C remains sign-unknown** (13e §7 said so; nothing
here changes it). Do not adopt it expecting the δ¹³C misfit to close.

## 2026-08-13 (j) — PHASE 1 of the sequenced plan: measured, and two of its own claims withdrawn

Works handoff 13h's PHASE 1 and stops where 13h says to stop. Full record in
`notes/handoff_2026-08-13i_phase1_measured.md`.

### `beta` re-centred 0.38 → 0.60, and it is not one criterion's answer

0.38 was set 2026-08-12 as the 1-D log-posterior optimum of the model that **preceded**
`404d66d` — i.e. against the bug. On the shipped model it leaves CO₂ 20.0 ppm high.
Four criteria agree to within 0.02 (`diag_recentre_beta.R`): CO₂-bias zero **0.591**,
CO₂ stream's own optimum **0.597–0.599**, full posterior at `mode_fit`'s σ **0.597**, at
the table's σ **0.617**. That last row is the useful one — the answer barely moves when
`sigma_d13c` moves 0.44 → 0.10, so the default could be set with that decision still open.

### WITHDRAWN: "the converted-land fix makes δ¹³C 7.1 % worse"

13h §2.2d measured it at a **stale β**. Like for like, at each model's own CO₂-consistent
β, the 2015-2024 MLO δ¹³C bias goes **+0.580 (pre-fix, β 0.358) → +0.529 (post, β 0.591)**.
The fix **improved** the δ¹³C misfit by 0.05 ‰. And `diag_conveyor.R`'s deep-Δ¹⁴C columns
are **bit-identical** across the fix, so the 13b/13c ocean conclusions were never at risk.
Re-measured at β 0.60 the ocean is *better* than 13c recorded: mixed-layer Suess
**0.153 (−0.4 sd vs Quay)**, atmosphere **+18 %** rather than +25–30 %.

### NEW STRUCTURAL MISFIT: the CO₂ record vs the GCB budget

`diag_luc_prorata.R` §5. Against GCB 2015-2024 (gross land 2.36, ocean 3.22 GtC/yr):

| debit | β | CO₂ bias | cum land 1750-2024 | gross land | ocean |
|---|---|---|---|---|---|
| wood only | 0.38 | −20.0 ppm | −52.2 (GCB −57.4) | 2.74 | 2.87 |
| wood only | **0.60** | **+0.8 ppm** | **+21.7** | **3.99 (+69 %)** | 2.52 (−22 %) |
| pro rata | 0.38 | −35.0 ppm | −108.8 | 2.36 | 3.00 |
| pro rata | 0.70 | −1.0 ppm | +11.1 | 4.31 | 2.45 |

**Matching GCB's cumulative land costs ~21 ppm under BOTH debits** — the debit choice moves
where β sits on the line, it does not relieve the line. Size explained, not hand-waved:
the model closes its own budget exactly (E_foss 504.7 = Δatm 303.8 + Δland 21.7 + Δocean
178.3, residual 0.9 GtC) while GCB's own table carries **+35.6 GtC of cumulative imbalance
over 1959-2024 alone**. *Provenance flag: the −57.4 / +209.8 GtC figures come from
`404d66d`'s commit message and cannot be recomputed here — `obs_gcb.rds` starts in 1959.*

### `f_luc_wood`: the pro-rata debit, built as a switch and measured

Default 1 = the shipped wood-only behaviour, bit-identical, with its own parity gate (the
default never reaches the new branch, so the existing gate could not see it).

| LUC airborne fraction ÷ fossil's | 50 yr | 100 yr | 150 yr | 200 yr |
|---|---|---|---|---|
| wood only | 0.549 | 0.496 | 0.569 | 0.647 |
| **pro rata** | **1.025** | **1.024** | **1.023** | **1.024** |

Cost: the emitted carbon stops carrying wood's ¹⁴C. At 2024 the debit's Δ¹⁴C goes
**+57.1 → −10.1 ‰** — in the bomb era it flips from enriched to depleted. Pool equilibrium
shares are leaf 1.7 / wood 22.5 / soil_fast 5.4 / **soil_slow 70.4 %**.
*Correction:* the debit does **not** land on "wood (37 yr)" as 13h §2.1b and `404d66d`'s
message say — `tau_wood` is **20 yr**, and 35.5 yr is `land0/npp0`, the whole land's bulk
turnover. The two were conflated.

### The `kz` bracket: 13h §2.1a's *reason* does not survive, and the bound is not binding

13h §2.1a deletes `[3830, 6200]` as "conditional on the pure-diffusion column" — but PHASE
2 is conveyor-OFF, i.e. that exact column, which is the same fact 13h §3.2 relies on.
What survives is 12d §8's different reason (the bound leaks), whose prescription is a
**likelihood term**, not a bare deletion. Measured (`diag_kz_bracket.R`): the bracket
**re-bisects to [3828.9, 6201.0]**, unmoved by `404d66d` or the β change; the leak is
**+7.0 to +8.1 ‰** uniformly, re-bisecting to [3601, 5703] at `mode_fit`'s vector; and the
1-D log-posterior in kz has an **interior maximum at 5000** under both candidate σ_d13c.
Bare deletion is priced: kz 10,686 gives deep Δ¹⁴C **−112.7 ‰**. There is still no
deep-Δ¹⁴C term in `R/likelihood.R`.

### A units trap that was live in a shipped diagnostic

`mean(diff(land_C))` is the **net** land flux (sink − E_LUC); GCB's `land_sink` is the
**gross** residual sink. Nearly the same quantity while land-use carbon was being regrown,
and not since `404d66d`. Fixed in `diag_d13c_suess.R` §3 (still live there), the two new
diagnostics, and the `beta` comment. **It changed a conclusion:** at β 0.60 the land sink
is +69 % against GCB, not the +11 % first written.

### Six failing tests, three new, all deliberately left failing

Re-derived rather than labelled, per "carry the evidence, not the label":
`test-likelihood.R:114/117` — the fixture's 12.65 ppm bias is gone, not the property; the
symmetric curvature `(cost(+1)+cost(−1))/2` is **+26.40 at both β** and `cost(+50)` is
64,439, so the AR(1) loophole is still shut. Station CO₂ residuals went **RMS 13.28 → 1.09
ppm**, and they are structured, not noise (+0.036 / +0.051 ppm/yr trends, p 3e-14 / 4e-20).
`test-likelihood.R:135` — at RMS 1.09 the ML σ_co2 is ≈ 0.4, so the hard-coded "sane" 5 is
no longer sane. `test-climate.R:121` joins `:122` as one phenomenon: higher β damps the
carbon-climate loop gain, and the header's ~111 ppm / ~0.3 °C was never met.
`test-mechanisms.R:32` — the ENSO switch is weak on the level *and* on the right statistic:
growth-rate sd 0.584 vs observed 0.712 at `gamma_enso` 0.5, matching at γ ≈ 1.5–2
(`mode_fit` chose 0.927), with the posterior nearly flat 0.5 → 1.0.

## 2026-08-14 — Marcus' decisions; pro rata adopted; and the Pulse Lab reversal

Decisions: `kz` → delete the bracket **and** add a deep-Δ¹⁴C likelihood term (**blocked**,
below); `sigma_d13c` → **left free**; the failing-test re-derivations → **none written**;
the LUC debit → **delegated on physical realism**.

**LUC debit: PRO RATA.** `f_luc_wood` default 1 → 0. Reasoning in full at
`CCX_F_LUC_WOOD_DEFAULT`: it is the mass-consistent partner to the converted-land term
(which already lowers all four pools' equilibria); GCB's E_LUC is **already timing-resolved**
and carries legacy soil loss, so the model must not re-impose a vegetation-only timing on
it; and wood-only leaves half of each land-use tonne coming back (AF ratio 0.50 vs 1.02).
It gives up the wood-¹⁴C call. Caveat logged not built: a **single** clearing event should
be fast out of vegetation and slow out of soil, and pro rata takes 70 % out of a 500-yr
pool instantly — right for the historical E_LUC record, wrong for the app's "what if we
cleared X". That forced a second β re-centring, **0.60 → 0.75**.

### CORRECTION: the β re-centring left TEN failing tests, not six

The 2026-08-13 (j) entry says six. Bad grep — `test-pulse.R:83/100/101/113` were in the
same output. **`:100/:101` is the consequential one: the Pulse Lab's Revelle-saturation
claim REVERSES.** 100 GtC at 2050, airborne fraction at 2150, ssp585 − ssp119:

| β | 0.38 | 0.50 | 0.60 | 0.75 |
|---|---|---|---|---|
| hi − lo | **+0.204** | **+0.085** | **−0.011** | **−0.109** |

The LUC debit is irrelevant to it — both debits agree to three decimals at every β.
**Mechanism, and it is a model limitation not a threshold problem:**
`NPP = NPP0(1 + β ln(χ/χ0))` has **no saturation**, so on SSP5-8.5 at 1998 ppm the land
runs at **2.48× preindustrial NPP** at β 0.75 (1.75× at 0.38). That sink overwhelms the
ocean's buffer and flips the sign. **Above β ≈ 0.53 the Pulse Lab teaches the opposite of
its own lesson**, and none of the four calibration criteria sees this. Either the default
stays below ~0.53 and accepts a CO₂ bias, or the fertilisation gets a saturating form —
which is model structure, i.e. PHASE-3-class work.

*Nearly missed twice:* scanning β by monkey-patching `ccx_default_params()` and calling
`test_file()` returned **byte-identical numbers at β 0.38/0.50/0.55/0.60** — the override
never reached the tests. Suspicious uniformity as a bug signal, working.

### The `kz` decision is BLOCKED on provenance, deliberately not implemented

The `[−150, −200] ‰` target appears **once** in the repo, in `DATA.md` §5, as *"roughly
−150 to −200"* — no paper, no dataset, no access date. Hard rule 2 forbids an uncited
value in code, and a term in the **objective** is a stronger use than the bound it
replaces. **The bracket is therefore NOT deleted**, since bare deletion is the
measured-and-rejected option (kz → 10,686, deep Δ¹⁴C −112.7 ‰). **GLODAPv2 unblocks it**,
and 13h §4.3 already needs the same pull for PHASE 3's deep DIC and δ¹³C targets.

## 2026-08-14 (b) — Stop before PHASE 2: a step-back architecture review is queued

Marcus called a halt before the conveyor-OFF refit. `notes/handoff_2026-08-14_step_back_architecture_review.md`
sets the terms of reference: **targets** (what are we asking the model to reproduce, and are
the stream weights defensible), **inputs** (fossil, LUC, bomb/nuclear/cosmogenic ¹⁴C, ENSO,
GMST — and the four provisional hemispheric shares), **components** (how many land pools;
how land and LUC interact; pump vs conveyor vs neither; how fertilisation is handled; how
temperature and ENSO interact; gross vs net exchange for each), and **whether the assembled
thing works** — pulse lifetime, expected to be the weakest test, and pedagogy. The
inventories in it are verified against the code; the questions are deliberately unanswered.
13h §§3–4 stay on the shelf, unchanged, until the review says whether they are still right.

### FOUND WHILE TAKING INVENTORY, NOT FIXED: `gcb_land_sink` compares net to gross

`R/likelihood.R` scores `diff(land_C)` — the model's **NET** land flux, sink minus E_LUC —
against GCB's **GROSS** residual sink. This is the same trap fixed in the diagnostics at
`cc3abd5`, but **inside the objective the MCMC will optimise**: the model is asked to
over-absorb by exactly E_LUC (~1.37 GtC/yr recently).

| β | as shipped | corrected (`mod_ld + E_LUC`) | mean model−GCB, net | gross |
|---|---|---|---|---|
| 0.38 | −139.6 | **−125.7** | −1.75 | **−0.07** |
| 0.75 | −127.6 | −134.9 | −0.31 | +1.37 |
| 0.85 | **−127.8** | −139.6 | −0.00 | +1.68 |

**The bug inverts the term's pull.** As shipped it wants β to *rise*, bottoming near 0.85;
corrected, its own optimum is β ≈ 0.39 and it *resists* rising β. It went unnoticed because
it was pushing the same way as the CO₂ streams. It is a bug, not a choice — the only choice
attached is the σ (`0.9 × 3.0 = 2.7` GtC/yr, traceable to `DESIGN.md` §9 Q1). **Left
unfixed deliberately**: the fix changes what the model is fitted to, the refit is blocked
anyway, and it belongs in front of the review rather than quietly applied. **Fix before any
refit.** Second-order and also review material: even corrected the term moves ~9 log-units
across β 0.38→0.75 against the CO₂ streams' ~12,000, so the partition constraint is nearly
decorative. `gcb_ocean_sink` has no E_LUC analogue and is unaffected.

## 2026-08-14 (later) — THE ARCHITECTURE REVIEW: two DESIGN hard gates are failing, and the objective's weighting is why

`notes/review_2026-08-14_architecture.md`. Discharges §2 of
`handoff_2026-08-14_step_back_architecture_review.md` — a written review of targets,
inputs, components and whether the assembled model works. **No model code, no fixtures
and no defaults were changed.** Three diagnostics added; everything below is measured.

**HEADLINE — the shipped default fails two of DESIGN §6's own hard gates.**

| gate | target | at `ccx_default_params()` (β 0.75) | |
|---|---|---|---|
| **7 — sinks 2015–2024** | land 2.36 ± 0.9, ocean 3.22 ± 0.4 GtC/yr | **4.57 / 2.38** | **+2.5σ / −2.1σ** |
| **12 — Joos IRF, TH 20/50/100** | 12.2–16.3 / 24.0–36.6 / 39.5–65.2 yr | **10.4 / 19.9 / 31.2** | **FAIL ×3** |

Gate 12's recorded status in DESIGN ("inside at all three, 12.6/26.2/43.6") was measured
at β 0.38 and is **stale**. `diag_joos_beta_scan.R` puts the gate's ceiling at **β ≈ 0.50**
— which independently agrees with the Pulse Lab's Revelle ceiling of ≈0.53 (13i §A1).
Neither criterion was used to set the default, which tracks the CO₂ record alone.

**WHY — measured, `diag_stream_leverage.R`.** A stream's weight is its LEVERAGE (log-units
per one-prior-sd parameter step), not its logL LEVEL. Across a step in β: CO₂ streams
1,565, ice core 118, `gcb_ocean_sink` 36, `gcb_land_sink` **2.0** (7.3 corrected). The
partition constraint loses **40 : 1**, so the sampler always buys CO₂ level with land sink.
Both β re-centrings did exactly that, correctly following the objective as written.

Four further findings from the same matrix:
- **`excess_c14_ocean` failed at its stated job.** Design note 5 added it so `bomb_total`
  could not absorb ventilation error. It has **0.8** log-units of leverage on `bomb_total`
  against the atmospheric Δ¹⁴C streams' **1,247**. Outvoted 1,500 : 1; the loophole is open.
- **A large level with no leverage is a constant offset.** `d14c_intcal` carries −670 of
  logL and **2.8** of leverage. Never quote a stream's level as evidence of its weight.
- **`q10` is decided by δ¹³C** — the one stream with a known unclosed 0.53 ‰ misfit. The two
  CO₂ station terms oppose and cancel (+7.2 / −6.9); δ¹³C supplies 31 of ~70 available
  log-units, pulling `q10` down. This is the `q10` → 0.169 pathology seen directly, and it
  confirms `diag_which_stream_pays.R`'s hypothesis with a cleaner instrument.
- **Free σ let a misfitting stream de-weight itself.** Three σ are calibrated, every other
  stream's is fixed. A +0.7 log-sd move in `sigma_d13c` GAINS the δ¹³C streams 510 log-units.
- **τ_ex is set by the seasonal cycle, not by the gradient.** DESIGN §6 gate 9 says the
  MLO−SPO gradient is "the main constraint on τ_ex". There is **no gradient term in
  `ccx_loglik()`**; 66 % of τ_ex's leverage comes from `co2_seasonal_*`.

**§1's `gcb_land_sink` net-vs-gross defect — CONFIRMED and PRICED.** Real, and it must be
fixed because the objective is wrong — but at 7.3 log-units corrected against CO₂'s 1,565
it **will change essentially nothing about the fit**. Do not mistake its landing for having
addressed the weighting. A second, smaller defect found alongside it: both sink terms
compare `diff()` of ANNUAL-MEAN stocks to GCB's CALENDAR-YEAR flux — a half-year offset,
negligible in bias, but it aliases exactly the interannual variability a partition
constraint is supposed to use. Same three lines.

**THE CHEAPEST FIX IS AN INPUT, NOT A PARAMETER — `diag_luc_scale.R`.** `E_LUC` is
prescribed exact while `DATA.md` §3a already records GCB 2025 at 239.8 GtC (1850–2018)
against OSCAR v3.1's 178.9 for the same period — a **34 % product spread** — and OSCAR's
own headline is **206 ± 57 PgC** = ±27 ppm. The model's largest structural misfit (13i §2's
"CO₂ level vs GCB budget", ~30 ppm) is **smaller than one input's stated uncertainty.**
At matched CO₂ bias:

| | β 0.75, LUC × 1.00 (shipped) | β 0.50, LUC × 0.65 (= 188 GtC) |
|---|---|---|
| CO₂ level | +3.3 ppm | −2.6 ppm |
| gate 7 land / ocean | **4.57 (+2.5σ)** / **2.38 (−2.1σ)** | 3.06 (+0.8σ) / 2.63 (−1.5σ) |
| gate 12 Joos | **FAIL ×3** | inside ×3 |
| Pulse Lab Revelle | **reversed** | holds |
| δ¹³C bias | +0.382 | +0.542 |

The LUC route wins on four criteria and **loses on δ¹³C by 0.16 ‰** — stated because it is
the one place the shipped default is better. 188 GtC sits inside OSCAR's published 206 ± 57.
**Not adopted as a fixture:** a uniform scale is crude, GCB's own E_LUC uncertainty has not
been pulled from source (rule 2), and this is a measurement of what is available.

**FERTILISATION IS THE BINDING STRUCTURAL DEFECT, with the arithmetic stated.**
`NPP = NPP₀(1 + β ln(χ/χ₀))` has one parameter controlling both the INTEGRAL (historical
uptake) and the DERIVATIVE at today's CO₂ (`β·NPP₀/χ` = 0.116 GtC/yr/ppm at β 0.75, against
the 0.062–0.077 the Joos gate needs). The data want a large integral and a small derivative;
the log form fixes their ratio. **A two-parameter saturating form is required**, to an
explicit design target: β ≈ 0.7's integral with β ≈ 0.5's marginal slope at 388 ppm.
Corroboration that this is a model defect and not a threshold problem: on the SSP protocol
the model leaves **9.6 %** of an ssp585 pulse airborne at 100 yr where Joos's Bern3D-LPJ has
RCP8.5 above 80 % at year 1000. Same cause as the Pulse Lab reversal.

**THE OCEAN IS RE-MOTIVATED AND NOW FALSIFIABLE.** At the β 0.50 / LUC 0.65 settlement the
ocean sink is the ONLY remaining gate miss (2.63 vs 3.22, −1.5σ) — a better case for the
pump than 13h §4.3 had. **Pre-registered before it is adopted on sink grounds:** build it,
measure the 2015–2024 ocean sink and surface DIC. > 0.1 GtC/yr toward 3.22 = mechanism;
otherwise 13h §4.3's "mostly bookkeeping" stands and it ships on pedagogy alone (where it
passes the one-sentence test and the conveyor fails).

**Components left alone, with reasons:** 4 land pools (free none — 13i priced one free
timescale at +3.6σ and nothing scores the ¹⁴C partition it would break); `ra_ratio` = 0
(no stream could identify it); temperature × ENSO interaction (`gamma_enso`'s max leverage
anywhere is 16.3); conveyor off (fails its own falsification test and the one-sentence test).

**ORDERING.** 1 fix §1 + the half-year alignment → 2 re-take β against DESIGN's gates
(Marcus') → 3 `luc_scale` as a 17th parameter → 4 GLODAPv2 (unblocks the `kz` decision AND
the pump's targets, one pull) → 5 gradient terms → 6 re-take the free-σ and
`LIK_EXCESS_C14_TARGET` decisions on the leverage evidence → 7 saturating fertilisation →
8 THEN the refit (~18 params) → 9 pump. **Do NOT** hand-tune stream weights, delete the
decorative terms, free land turnover, delete the `kz` bracket bare, or adopt LUC × 0.65.

**Failing tests:** `test-pulse.R:83/:100/:101/:112` now have EXTERNAL corroboration (the
Joos scan reproduces the defect at the same β). They are the model reporting a real failure
— leave them failing until the fertilisation form changes. **Add gate 12 to the suite**: it
is a hard gate whose only implementation is a diagnostic nobody runs, which is how its
status went stale across two β moves.

**Proposed DESIGN amendments written out but deliberately NOT applied** (review §8) — each
encodes a choice that is Marcus'. Includes a proposed **gate 13, stream-leverage screen**:
no calibrated parameter may be decided by a stream carrying a known unclosed structural
misfit. That is the general form of the `q10`/δ¹³C finding and would have caught it.

**Not re-measured, flagged as stale:** `diag_pedagogy.R`'s turnover-vs-adjustment numbers
(4.69 yr against a 40.3 yr mass 1/e) predate both β moves exactly as the Joos gate did, and
the mass 1/e time is precisely what §4.1 shows moving with β. The app's headline pedagogical
claim is currently uncorroborated at the shipped default.

**Non-obvious state:** `calibration/output/recentre_beta_scan.rds` was OVERWRITTEN by
re-running `diag_recentre_beta.R` at the current defaults (it was last written at β 0.60 /
wood-only). Every number in the review is at `gamma_enso` = 0, which is
`ccx_default_params()` and is **not** what `app/global.R:71` runs.

## 2026-08-14 (later still) — PRIORITY 1 + 3: the objective is fixed, and land-use uncertainty is a parameter instead of a burden on beta

Works items 1 and 3 of the architecture review's ordering. **Suite: 11 fail, the same 11
as before** (see the correction below) plus 34 new passing assertions.

### The objective (review item 1)

Three fixes in `R/likelihood.R`, all in the GCB-sink block:

1. **NET vs GROSS — the bug.** The model's `d(land_C)/dt` is net of E_LUC; GCB's
   `land_sink` column is the gross residual sink. The term is now reconstructed as
   `net + E_LUC`, using the **model's own** land-use flux (a new `luc` argument), not
   GCB's — otherwise a `luc_scale`-scaled run would be scored against an unscaled flux.
   NULL keeps GCB's column, which is **bit-identical to the forcing at scale 1**
   (verified 1959–2024, max |diff| = 0), so every existing caller stays correct.
2. **YEAR ALIGNMENT.** The old code diffed annual MEANS of the stock — the flux over
   [mid-year *y*−1, mid-year *y*], half a year off from GCB's calendar-year flux. Stocks
   are now interpolated to calendar-year **boundaries**, with linear extrapolation at the
   two ends (the monthly grid puts the first and last boundary half a month outside the
   run; `rule = 2` would hold flat and under-count the end years).
3. **`LIK_GCB_LAND_SD` 0.9 → 0.5.** It was labelled "GCB stated land-sink uncertainty"
   with **no provenance anywhere in the repo**, while GCB 2025's own header states ±0.5.
   Corrected to the cited value, with the whole uncertainty block now quoted verbatim
   from `data-raw/downloads/gcb2025_global_budget.csv` (ocean ±0.4, land ±0.5, E_LUC
   ±0.7 GtC/yr, fossil ±5 %, all 1σ). This is a **change to the objective** and is
   recorded as one — a constant tracking its source, not a reweighting. DESIGN §9 Q1's
   inflation multiplier is untouched and still rides on top.

**Effect, measured.** `gcb_land_sink` leverage on β: **2.0 → 24.3** log-units per
one-prior-sd step (12×, from the sign fix plus the σ correction) — now comparable to
`gcb_ocean_sink`'s 35.6, which is the right relationship. Still 1,565 : 24 against CO₂,
so the review's headline stands: **fixing this was necessary and did not fix the model.**

**And gate 7 is worse than the review said.** Against GCB's *stated* 0.5 rather than the
uncited 0.9, the shipped default's land sink is **+4.4σ**, not +2.5σ. Ocean unchanged at
−2.1σ.

**A counter-intuitive fact, pinned in `test-luc-scale.R` so nobody "fixes" it back:** at
β 0.75 the **buggy NET comparison scores BETTER** than the correct gross one (−97.3 vs
−122.0), because the model over-absorbs (gross sink 4.57 against GCB's 2.36). **The bug
was flattering the high-β model**, which is exactly why nothing objected as β rose.

### Land-use input uncertainty (review item 3)

**`luc_scale` is now the 17th calibrated parameter** — `ccx_build_forcing(luc_scale=)`
applied to the **annual** series (so the monthly flux, the in-window cumulative and the
pre-window `luc_pre` all scale together; scaling monthly columns alone would leave the
converted-land term's cleared fraction inconsistent with the flux). Inside
`ccx_make_logpost()` it is an equivalent column multiply for speed, gated against the
rebuild path by `test-luc-scale.R`.

**The prior has two independent receipts that agree — lognormal, median 1, sdlog 0.28:**
- OSCAR v3.1's own cumulative uncertainty, **206 ± 57 PgC (1750–2018)** → 27.7 %;
- the **GCB-vs-OSCAR product spread over the identical 1850–2018 window**, 239.8 vs
  178.9 GtC → ratio 0.746, |ln| = 0.293.

One is a stated uncertainty, one an observed disagreement between products; both land on
~0.28, which puts OSCAR's central estimate at ~1σ below GCB's. Centred at 1 (= GCB, the
standing convention) so the prior is not a silent re-basing. GCB's **annual** ±0.7 GtC/yr
(51 % of a 1.372 mean) is deliberately *not* the width — that is a single year's flux,
only partly correlated across years, so an upper bound on the cumulative fraction.

### The pre-registered prediction: MET, but conditionally, and the condition matters

Review §3.3 predicted, before the code existed: *with `luc_scale` free, β falls to
0.40–0.55 and `luc_scale` settles at 0.6–0.8.* `calibration/diag_beta_luc_profile.R`,
a 2-D slice of the **full** log-posterior (priors and Jacobians included):

| σ_d13c | argmax β | argmax `luc_scale` | cum LUC | CO₂ bias | land | ocean |
|---|---|---|---|---|---|---|
| 0.10 (table init) | 0.70 | 0.90 | 260 GtC | +3.53 ppm | +3.8σ | −2.0σ |
| **0.44 (mode_fit)** | **0.55** | **0.70** | **203 GtC** | **−0.40 ppm** | +2.0σ | −1.6σ |
| 5.00 (muted) | 0.55 | 0.70 | 203 GtC | −0.40 ppm | +2.0σ | −1.6σ |
| *any, `luc_scale` pinned at 1* | **0.75** | — | 289 GtC | +3.34 | +4.4σ | −2.1σ |

**The first run REFUTED the prediction** (β 0.70) and is left in the file's header rather
than deleted. The refutation was conditional on σ_d13c = 0.10: at that width δ¹³C
contributes ~740 log-units in favour of high β, far more than the `luc_scale` prior can
resist — and δ¹³C is the one stream carrying a known unclosed ~0.53 ‰ **structural**
misfit, so σ = 0.10 asserts that misfit is measurement noise. At 0.44 (what `mode_fit`
chose) and at 5.00 the answer is **identical**, so 0.10 is the outlier, not 0.44.

**Three things this establishes.** (i) The (β, `luc_scale`) ridge is real and steep — the
objective does use the input uncertainty rather than ignoring it. (ii) With LUC pinned,
β = 0.75 at **every** σ_d13c: pinning the input is what made the high β look robust.
(iii) The settlement's cumulative LUC of **203 GtC lands on OSCAR's central 206** without
being told to — the prior only supplied a width.

**Not oversold.** β 0.55 is still above gate 12's ≈0.50 ceiling and the Pulse Lab's ≈0.53,
and the land sink is still +2.0σ high. `luc_scale` gets most of the way and **does not
remove the need for review item 7, the saturating fertilisation form.** And a 2-D slice at
the other 15 parameters' inits bounds the answer; it does not decide it.

**It also means Marcus' 2026-08-14 "leave `sigma_d13c` free" decision is now load-bearing
on β**, which it was not when taken — free, the sampler picks ~0.44 and the prediction
holds; pinned at the table's 0.10 it does not. That is review item 6, now with a number.

### Corrections to the record

- **The pre-change suite was 11 failures, not 10.** `test-pulse.R:113` was already
  failing; handoff 13i §A1's text listed it and §A5's summary list did not, and the "10"
  propagated from there. Verified by running the suite on the stashed pre-change tree.
- `test-likelihood.R:165` (the parameter count) is the **only** newly-failing test and it
  is the tripwire doing its job. Updated to 17 **with the reason written in**, plus two
  new guards: `luc_scale` must be in `CCX_PARAM_NAMES` and must **never** appear in
  `ccx_default_params()`, where it would silently rescale every diagnostic that does not
  know about it.
- `calibration/diag_stream_leverage.R` no longer carries its hand-rolled "CORRECTED" land
  term — `ccx_loglik()` is now correct. Review numbers quoted as "corrected" (7.3 on β)
  are at the old σ = 0.9; the file now reports 24.3.

### Still open, and deliberately not done here

Fossil emissions carry GCB's stated **±5 %** (≈±25 GtC ≈ ±12 ppm cumulative) and are still
prescribed exact. A `foss_scale` is the obvious sibling of `luc_scale`, but the two are
strongly degenerate against a CO₂ record that mostly constrains their **sum**, and adding
a second emission scalar without measuring that degeneracy first is precisely what this
project's discipline forbids. Flagged, with the arithmetic, not taken.

## 2026-08-14 (cont.) — emission inputs: degeneracy measured, the LUC hemispheric share is TIME-VARYING, and the omitted input seasonality is NOT negligible

Three diagnostics, no model changes. `diag_emission_scale_degeneracy.R`,
`diag_emission_split_and_season.R`.

### `foss_scale` — identifiable, but low value. NOT added.

The two emission scales are **not degenerate**, and the discriminator is the one predicted
before the run: **Δ¹⁴C**. Walking along the iso-carbon line (fossil × 504.7 + LUC × 289.3 =
const) at β 0.75, foss +0.08 / LUC −0.14 costs **82 log-units**, of which Δ¹⁴C supplies
−104 (NH −61, SH −43) and the ice core −51, partly offset by CO₂ level +45. Fossil carbon
is ¹⁴C-free by definition; land-use carbon carries the vegetation pool's own ¹⁴C. δ¹³C
contributes almost nothing (−4), as expected — the two source signatures are similar.

**But the identification is ~10–20× weaker ALONG the iso-carbon direction than across it**
(hundreds vs thousands of log-units), so a `foss_scale` would be strongly anti-correlated
with `luc_scale`. And GCB's fossil prior is ±5 % = **25 GtC** against LUC's ±28 % = **81
GtC**, so the fossil prior admits **3.2× less** carbon movement and would dominate its own
posterior. **Verdict: add `foss_scale` only if the refit drives `luc_scale` to a prior
edge** — that is the signal that total-emission error is being forced entirely onto LUC.
Noted: at β 0.55 the grid argmax sits at foss_scale 0.95, exactly −1σ of GCB's ±5 %; at
β 0.75 it sits at 1.00. Confounded with β, so not evidence on its own.

### The land-use hemispheric share is TIME-VARYING, and the constant 0.55 is wrong at BOTH ENDS

From OSCAR v3.1's **Regional** sheet — the same sourced file `DATA.md` §3a already uses,
11 regions, 1701–2018, whose 1750–2018 total reproduces the paper's 206 PgC headline.
Within-region NH fractions are geographic judgements, not sourced, so everything is carried
as a bracket:

| period | E_luc GtC | NH lo | **NH central** | NH hi | model uses |
|---|---|---|---|---|---|
| 1750–1849 | 27.5 | 0.797 | **0.838** | 0.880 | 0.55 |
| 1850–1899 | 30.4 | 0.719 | **0.766** | 0.812 | 0.55 |
| 1900–1949 | 57.2 | 0.600 | **0.668** | 0.735 | 0.55 |
| 1950–1989 | 54.6 | 0.428 | **0.527** | 0.627 | 0.55 |
| 1990–2018 | 36.8 | 0.267 | **0.398** | 0.528 | 0.55 |
| **1750–2018** | **206.4** | 0.539 | **0.620** | 0.700 | 0.55 |

**The share falls monotonically ~0.84 → ~0.40** as clearing moves from temperate NH
(North America, Europe, FSU, China) to the tropics (Latin America, Sub-Saharan Africa,
Indonesia). **The conclusion survives the whole bracket:** before 1950 even the LOW bracket
is ≥ 0.60, and after 1990 even the HIGH bracket is ≤ 0.53. So the model puts **too much
early land-use carbon in the SH (~23 GtC over 1750–1949) and too much modern land-use
carbon in the NH (~5 GtC since 1990)**. A constant cannot represent this, whatever value
it takes.

### ...and the objective cannot see it, which is review §2.3 made concrete

| | MLO−SPO CO₂ grad | δ¹³C grad | Δ logL |
|---|---|---|---|
| **observed** (gate 9, 2020s / 13i) | **3.97 ppm** | **−0.074 ‰** | — |
| as shipped (0.95 / 0.55) | 5.06 | −0.240 | — |
| LUC NH share 0.40 | 4.66 | −0.223 | **+33.4** |
| LUC NH share 0.70 | 5.46 | −0.258 | −40.1 |
| fossil NH share 0.90 | 4.46 | −0.213 | **+3.1** |
| fossil NH share 0.97 | 5.30 | −0.251 | −2.0 |

**The fossil share moves the CO₂ gradient by 0.84 ppm across 0.90→0.97 — most of the
model's 1.09 ppm gradient error — for 5.1 log-units of objective.** The share is
effectively unconstrained by the likelihood while strongly controlling an observable that
is badly wrong. That is the missing gradient term (review item 5), priced.

**And it answers review §3.4's question negatively:** the provisional shares are **NOT** the
cause of the δ¹³C gradient miss. Across the whole plausible range the modelled δ¹³C
gradient moves only −0.213 to −0.258 against an observed −0.074. The 3× error is
structural, and this line of enquiry is now closed rather than left open.

### The omitted emission seasonality is NOT negligible — it biases the fitted NEP amplitude by ~8 %

Neither input carries any seasonal cycle (DESIGN §3.6, "smooth annual→monthly"). Bounding
test — amplitudes deliberately **not** sourced, phases from tropical burning (NH dry season
Dec–Feb, SH Aug–Oct) and NH winter heating:

| imposed | MLO p-p | Δ p-p | Δ seasonal logL |
|---|---|---|---|
| LUC A = 0.3 | 4.553 | +0.084 | **+67.0** |
| LUC A = 0.6 | 4.637 | +0.169 | **+130.1** |
| *LUC A = 0.6, NH phase Jul (control)* | 4.329 | −0.140 | **−39.9** |
| fossil A = 0.06 | 4.588 | +0.120 | +61.3 |
| fossil A = 0.10 | 4.668 | +0.200 | +100.3 |
| **both (LUC 0.6, fossil 0.10)** | 4.838 | **+0.369** | **+225.8** |

**The headline: +0.369 ppm of omitted input seasonality is almost exactly what moving
`seas_amp_NH` from 12 to 13 GtC/yr does (+0.373 ppm).** So an omitted input seasonality of
plausible size is absorbed one-for-one by the single free NEP amplitude, **biasing it high
by ~8 %** — a physical signal reassigned to the wrong mechanism, which is overfitting in
its precise sense, in the highest-leverage stream in the whole objective.

**The phase control is what makes this more than "any extra variance helps":** flipping the
NH land-use peak from January to July turns +130 into **−40**. The gain is phase-specific,
not amplitude-generic.

**Honest confound, stated:** at default parameters the model's MLO peak-to-peak is 4.47 ppm
against gate 6's observed 6.86 (2010s), so the seasonal term rewards almost any correctly
phased amplitude. `seas_amp_NH` is calibrated and would rise to close that gap — which is
exactly the mechanism of the bias: it rises to cover an amplitude deficit that partly
belongs to the inputs.

**What this needs: a sourced monthly product for each input** — GFED for biomass burning
(the seasonal part of E_LUC), and a monthly fossil product for the NH winter cycle. Until
then the amplitudes above are a bound, not an estimate. **This is a new item for the
review's ordering**, and on the numbers it belongs alongside item 5 (the gradient terms):
both are about the model being scored on the wrong statistic.

## 2026-08-14 (cont.) — GLODAPv2 pulled (review item 4): the deep targets are sourced, and the σ turns out to BE the kz decision

`data-raw/build_glodap_deep_targets.R`, MANIFEST key `glodap_v2_2023`. GLODAPv2.2023
Merged Master File (110 MB zipped / 853 MB), glodap.info, doi:10.25921/z7hc-v261;
Lauvset et al. 2024, ESSD 16:2047, doi:10.5194/essd-16-2047-2024. 50,634 bottles carry
δ¹³C or Δ¹⁴C; 42,331 / 37,511 / 37,394 usable (flag 2) for Δ¹⁴C / δ¹³C / TCO₂.

**The model's "deep" is a specific layer, not a mood.** `ccx_ocean_grid(75)` puts the
bottom box at **2627.2–3700 m**, and `diagnostics$d14c_deep_by_hemi` — the quantity the kz
bracket was bisected on — *is* that layer. Observations are binned 5°×10°×250 m and the
cells weighted by cos(lat), because GLODAP over-samples the Atlantic relative to its volume.

| quantity, 2627–3700 m, volume-weighted | model | observed | spread |
|---|---|---|---|
| **Δ¹⁴C** | (kz-dependent) | **−175.3 ‰** (N-Atl cut −178.2) | ±45.9 |
| **δ¹³C** | **+1.560 ‰ UNIFORM** | **+0.424 ‰** | ±0.3 |
| **DIC** | **1986.3 µmol/kg UNIFORM** | **2273.1 µmol/kg** | ±53.9 |

**[a] The uncited bracket was RIGHT, and now has a source.** DATA.md §5's "roughly −150 to
−200 ‰" has a midpoint of −175, which is **within 0.3 ‰ of the measurement**. The recalled
number was good; it simply had no receipt. It has one now.

**[b] But the pull does NOT unblock the kz decision — it relocates it into σ.** 13i §A3
assumed GLODAP would supply "a real spatial spread for the sigma". It supplies the spread;
**the spread is not the sigma.** A one-box model is scored against the volume-weighted
*mean*, whose uncertainty is the spread ÷ an effective sample size — and deep water masses
are basin-coherent, so n_eff is of order tens, not the 3,592 cells. Measured against the
runaway that bare deletion produces (kz → 10,686, deep Δ¹⁴C −112.7 ‰):

| candidate σ | ‰ | runaway sits at | verdict |
|---|---|---|---|
| measurement error alone | 3.0 | 20.9σ | HOLDS kz |
| SE of the weighted mean, n_eff = 20 | 10.3 | 6.1σ | HOLDS kz |
| SE of the weighted mean, n_eff = 5 | 20.5 | 3.0σ | HOLDS kz |
| **full spatial spread (n_eff = 1)** | **45.9** | **1.4σ** | **DOES NOT HOLD kz** |

**And note what that means for the incumbent bracket:** [3830, 6200] is effectively a HARD
±25 ‰ box, **tighter than every candidate except the most aggressive n_eff**. Deleting it
in favour of an "honest" term would *loosen* the constraint, not tighten it. That inverts
the framing 13i §A3 was working under. **The σ is a methodological choice about
representation error and it is Marcus'** — it is now the whole of decision 1.

**[c] The pump's targets are quantified, and they are large.** The model's interior is
uniform in both tracers: the observed surface→deep DIC gradient is **+233 µmol/kg**
(2040 → 2273) against the model's **exactly 0**, and the observed δ¹³C gradient is
**−0.861 ‰** (surface +1.285 → deep +0.424) against the model's **0, at a uniform +1.560**.
The model's deep DIC is **12.6 % below** observed, which independently reproduces 13e §6's
"~14 % ocean inventory deficit" from a completely different measurement. Both observed
gradients are the signature a biological pump produces, so 13h §4.3's pump case now has
quantified targets rather than a direction — and the pre-registered ocean-sink test from
review §4.2 still gates whether it is a mechanism or bookkeeping.

**Correction to the repo's recollection:** the interior δ¹³C gradient was recorded as
"observed ~1–1.5 ‰". Volume-weighted over the model's own layers it is **0.861 ‰** — right
order, high by ~30 %. The model is +1.14 ‰ too enriched at depth and +0.28 ‰ at the surface,
so it is wrong in offset *and* in having no structure at all.

## 2026-08-14 (cont.) — DECISION 1 TAKEN: the deep-Δ¹⁴C term lands at σ = 10.3 ‰, the kz bracket STAYS, and the layer was mismatched

**Marcus took all three of the queued decisions on the recommended options:**

| | decision | taken |
|---|---|---|
| 1 | deep-Δ¹⁴C σ | **10.3 ‰** = spread ÷ √(n_eff = 20); **KEEP the kz bracket** |
| 2 | β default | **defer until item 7 lands** — no change, 0.75 still ships and still fails gates 7 and 12 |
| 3 | `sigma_d13c` | **stays free** — no change |

Only decision 1 is code. Decisions 2 and 3 are recorded no-ops, deliberately: the review's
headline is unmoved and nothing about the failing gates has been quietly improved.

### The term

`d14c_deep_ocean`, one scalar and one Gaussian, in `ccx_loglik()` behind a new `deep`
argument (`NULL` → the term is **ABSENT** under `by_stream`, not a silent zero). It is the
first term in the objective that prices ocean **ventilation**; until now nothing but δ¹³C
touched `kz`, which is why `kz` carries a hard bracket at all.

σ is **derived** from `LIK_D14C_DEEP_NEFF`, not typed twice — `ccx_deep_d14c_target()`
reads the GLODAPv2 build product and divides. A test asserts n_eff = 1 reproduces the raw
spread, so the constant cannot drift away from the number the likelihood uses.

### The bug this found: the target and the diagnostic were DIFFERENT LAYERS

`data-raw/build_glodap_deep_targets.R` measured GLODAPv2 over **2627–3700 m** and asserted
in its header that `diagnostics$d14c_deep_by_hemi` *is* that layer. **It is not.** That
diagnostic takes `tail(aux$idx[[h]]$oc, 3)` — the bottom **three** interior boxes,
**1313.6–3700 m** — which is better ventilated and runs 13.5–20.4 ‰ enriched across the kz
bracket (kz 5000: −170.1 against the bottom box's −186.4).

Scoring the 2627–3700 m target against the 3-box average would have been a ~1.6 σ layer
mismatch baked permanently into the objective. `diagnostics$d14c_bottom_box` (and
`d14c_bottom_by_hemi`) added to `R/spinup.R` for the term; the 3-box diagnostics are
**unchanged**, because the kz bracket and every pre-2026-08-14 result were derived from
them. The build script's header claim is corrected in place, not deleted.

**Consequence to carry:** handoff 2026-08-14b §4.1's "runaway at 6.1 σ" is the mismatched
pairing. Like for like it is **5.3 σ**. *The decision survives the correction* — 5.3 still
holds kz, and the verdict column of the σ table is identical either way — which is the only
reason this is a footnote rather than a re-take.

### Two things measured rather than assumed

- **Scoring the spinup steady state against 1972–2021 bottle data is legitimate.** The
  bottom box moves **+0.012 to +0.100 ‰** between 1750 and 2024 across the bracket, i.e.
  under 0.01 σ — the layer is effectively pre-bomb. So the term costs no transient
  integration. (The 3-box slab drifts up to **+2.49 ‰**, 25× more: a second reason the two
  layers are not swappable.)
- **The term is univariate in kz**, to the same standard `calibrate.R`'s bracket note
  claimed for the 3-box quantity. Across the *whole* `h_ml` prior [30, 200] the bottom box
  moves 5.3 ‰ (0.52 σ) and the layer's own top moves 50 m on a ~1070 m box, against the
  57 ‰ the kz bracket spans.

### Why the bracket stays — and where the term and the bracket disagree

Expressed on the bottom box, the incumbent bracket [3830, 6200] maps to [−220.4, −163.5] ‰:
a hard box of half-width **28.4 ‰**, tighter than every σ candidate but the most aggressive.
**Deleting it in favour of an "honest" likelihood term would LOOSEN kz, not tighten it** —
the inversion of 13i §A3's plan, and the reason decision 1 had to be re-taken.

But the bracket is centred at −191.9 ‰, **16.7 ‰ below** the sourced target. So:

| | kz | bottom box | z |
|---|---|---|---|
| bracket lower end | 3830 | −220.4 | **−4.40** |
| shipped default | 5000 | −186.4 | −1.08 |
| **term's own optimum** | **5525** | −175.3 | 0.00 |
| bracket upper end | 6200 | −163.5 | +1.15 |
| unbounded 17-par mode | 10686 | −120.9 | **+5.30** |

The term pushes kz **up inside** the bracket. That is one stream's preference at 9.0
log-units end-to-end — against the CO₂ streams' 1,565 per prior-sd step — so it is *not* a
counterweight to the CO₂ level; it acts on a parameter the CO₂ streams barely touch.
**kz is not re-centred by hand. The refit weighs it.**

### Methodological choice flagged, not buried

`LIK_D14C_DEEP_MASK_NATL = FALSE`. Masking the North Atlantic (the one place below 2000 m
with appreciable bomb ¹⁴C) moves the target −175.3 → −178.2 ‰ = 0.28 σ. The unmasked global
mean is used because the model's bottom box is a global quantity; the switch exists so the
alternative is one edit away rather than a re-derivation.

σ is also **not** inflated for model representation error, which the build script had
anticipated doing. 10.3 is the bare SE Marcus chose; inflating it silently would move his
number. If representation error is wanted it belongs in that constant, visibly.

### Files

`R/likelihood.R` (constants, `ccx_deep_d14c_target()`, the term, the `deep` argument),
`R/spinup.R` (`d14c_bottom_box`, report line with live z), `R/calibrate.R` (passes
`sp$diagnostics$d14c_bottom_box`; the kz bracket note now records why it was retained),
`data-raw/build_glodap_deep_targets.R` (header correction),
`calibration/diag_deep_d14c_term.R` (**new** — reproduces every number above),
`tests/testthat/test-likelihood.R` (4 new tests; 3 guard the decision, 1 the arithmetic).

**Suite still 11 failing, the same 11.** No new failures.

**Second positional-argument hazard.** `ccx_loglik()` now reads
`(out, obs, err, luc, deep, by_stream)`. Every caller in the repo passes `by_stream =` by
name so nothing broke, but a positional 5th argument now means `by_stream` and a positional
4th means `luc`. Name them.

## 2026-08-14 (cont.) — REVIEW ITEM 7: the saturating fertilisation form is BUILT, and it does what the log form provably cannot

**Status: mechanism built, gates measured, DEFAULT NOT MOVED.** `fert_form` still
selects `CCX_FERT_LOG` and `beta` is still 0.75, so nothing in the repo has changed value.
Marcus deferred the β default *to* this item (decision 2), and flipping it here would resolve
his decision for him — the numbers are below and the decision is his.

### The defect, restated as arithmetic

`NPP = NPP₀(1 + β ln(χ/χ₀))` locks the **enhancement** at today's CO₂ and the **slope** at
today's CO₂ into a fixed ratio (χ/χ₀), so β slides along it and cannot move one without the
other. The CO₂ record wants β 0.75; Joos gate 12 and the Revelle lesson both want ≤ 0.50.

### The replacement

Michaelis–Menten, `CCX_FERT_MM`: `NPP = NPP₀(1 + β_max·Δχ/(K + Δχ))`, Δχ = χ − χ₀, with
`beta_max` = fractional enhancement at infinite CO₂ and `fert_k` = the CO₂ increment above
preindustrial delivering half of it. Chosen over a bounded exponential because carboxylation
*is* an enzyme reaction, so the saturation has a one-sentence undergraduate explanation.

**Not a limit of the log form.** As `fert_k → ∞` MM goes *linear*, not logarithmic, so `beta`
does not map onto (`beta_max`, `fert_k`) by any substitution and a fit under one form is not
a fit under the other.

### The decoupling, measured on the design-target locus

Fixing `beta_max` by criterion (a) — match log β 0.70's enhancement at 388 ppm — and sweeping
`fert_k`:

| | enh@388 | slope@388 | ratio@1998 |
|---|---|---|---|
| log β 0.50 | 0.169 | 0.0773 | 1.99 |
| log β 0.75 (shipped) | 0.253 | **0.1160** | **2.48** |
| MM K=60 | 0.236 | 0.0447 | 1.35 |
| MM K=120 | 0.236 | 0.0662 | 1.46 |
| MM K=300 | 0.236 | 0.0931 | 1.74 |

The log rows move enhancement and slope **together**; the MM rows hold enhancement fixed
while the slope varies **2.1×**. Criterion (b) — slope ≤ β 0.50's 0.0773 — caps `fert_k` at
**171**; criterion (c) is met with room at every K.

### The gates, all four, at the shortlist

| case | loglik | CO₂ bias | z_land | z_ocean | gate 12 (Joos IRF 20/50/100) | Revelle lesson |
|---|---|---|---|---|---|---|
| **log β 0.75 (shipped)** | −3793 | **+3.34** | **+4.57** | −2.13 | **10.4/19.9/31.2 FAIL ×3** | **−0.113 REVERSED** |
| log β 0.50 | −9790 | −20.9 | +1.71 | −1.11 | 12.2/25.0/41.1 on the floor | +0.078 holds |
| MM K=100 | −3847 | +0.52 | +2.03 | −1.46 | — | +0.590 HOLDS |
| **MM K=120** | **−3760** | **+0.14** | **+2.28** | −1.52 | **12.4/25.6/41.9 INSIDE ×3** | **+0.566 HOLDS** |
| MM K=140 | −3725 | −0.12 | +2.50 | −1.57 | 12.2/25.0/40.8 inside, on the floor | +0.540 HOLDS |
| MM K=171 | **−3720** | −0.40 | +2.76 | −1.64 | 12.0/24.3/**39.4 FAIL** @20 & @100 | +0.498 HOLDS |

(Joos Table 4 5–95 %: 12.2–16.3 / 24.0–36.6 / 39.5–65.2. z on GCB's stated σ: land 0.5,
ocean 0.4.)

**MM K=120 beats the shipped default on the log-likelihood (−3760 vs −3793) while cutting the
CO₂ bias from +3.34 to +0.14 ppm, halving the land-sink miss (4.57σ → 2.28σ), passing gate 12
at all three horizons with margin, and restoring the Revelle lesson from −0.113 to +0.566.**
No value of β can do any two of those at once — that is the structural claim, discharged.

Gate 12 caps `fert_k` at ≈150 on the criterion-(a) locus, so the likelihood's own preference
(K 171) is just outside it. **That residual tension is real and is what the refit must settle.**

### Two things that came out NEGATIVE, recorded as such

- **`luc_scale` does NOT stack with this.** The obvious move — MM to fix the pulse, `luc_scale`
  to close gate 7 — makes things worse: at `luc_scale` 0.70 the CO₂ bias goes +0.14 → **+15.5
  ppm** and z_land gets *worse* (2.28 → 2.46). With the fertilisation parameters held there is
  no β left to relax, so the CO₂ bias absorbs the whole change. The two levers are partially
  **redundant** — MM at `luc_scale` = 1 already delivers the near-zero CO₂ bias `luc_scale` was
  introduced to buy. **The handoff's β 0.55 / `luc_scale` 0.70 settlement does not carry over
  to this form**; item 8's joint refit is what decides between them.
- **Matching the enhancement at 388 ppm does NOT match the historical integral.** The two forms
  cross at 388 by construction and disagree on both sides (MM is more responsive below, less
  above), and `cum_land` is not independent of `co2_bias` anyway. The integral is bought
  *through* the CO₂ record, so `co2_bias`/loglik are the columns that price it. The shortlist
  is built on those, not on `cum_land`.

### Flagged, not resolved

The high-background airborne fraction MM produces is **large and unbenchmarked** — 0.78 at
+100 yr on SSP5-8.5 (~1998 ppm) against the log form's 0.10. Gate 12 and Joos et al. (2013)
are both at a ~389 ppm background, so nothing in the literature set scores this. What the form
asserts is that at ~7× preindustrial CO₂ the land sink is close to saturated. That is a **model
claim at the far end of the app's own slider**, not a fitted result — but the log form's answer
there is not a safe fallback: it says the same pulse nearly vanishes in 100 years, which is
worse and in the direction that flatters the scenario.

### Files

`R/model.R` (`CCX_FERT_LOG`/`CCX_FERT_MM`, `CCX_FERT_FORM_DEFAULT`, `ccx_fert_factor()`,
three new params, the `ccx_deriv()` call site), `src/ccx_core.cpp` (the only other copy of the
factor), `R/cpp.R` (packing + defaults for pre-today parameter lists),
`calibration/diag_fert_saturating.R` (**new** — the locus, historical runs, gate 7, the
`luc_scale` negative result), `calibration/diag_fert_pulse_gates.R` (**new** — the Revelle
lesson), `calibration/diag_joos_beta_scan.R` (`CCX_FERT_*` env vars),
`tests/testthat/test-fertilisation.R` (**new**, 25 assertions).

**Suite still 11 failing, the same 11** — the default did not move, so nothing could. The five
`test-pulse.R` failures are exactly what the MM form fixes, and they will keep failing until
the default flips. **Leave them failing until then.**

## 2026-08-14 (cont.) — DECISION 2 TAKEN: the default IS the saturating form, `fert_k` 120 — and the flip caught three silent-inertness bugs

Marcus: *"Flip the default to MM."* `CCX_FERT_FORM_DEFAULT = CCX_FERT_MM`,
`beta_max` 0.4913, `fert_k` 120. This resolves the deferred β default: **`beta` is no longer
a live parameter and has left `CCX_PARAM_TABLE`** (17 → 18 parameters; `beta_max` + `fert_k`
in, `beta` out). The log form is **kept, not deleted** — `p$fert_form <- CCX_FERT_LOG`
reproduces every pre-flip result, and that is what makes the β-era record reproducible.

**The criterion was gate 12, not the likelihood.** `fert_k` 120 passes Joos at all three
horizons with margin (12.4/25.6/41.9); the log-posterior's own optimum on the design-target
locus is `fert_k` 171, which *fails* at TH20 and TH100. DESIGN §6 opens "all must pass before
headline claims", so the gate wins. **That is a choice and it is stated as one** — the gate
and the likelihood still pull apart, and the refit is what settles it.

### What the suite says: 11 failing → 8

**Six resolved by the flip**, and they are the ones that mattered:

- `test-climate.R:121, :122` — carbon-climate feedback, weakened by β 0.75. Now pass.
- `test-pulse.R:83, :100, :101, :112` — **the Pulse Lab**. `:100`/`:101` are the Revelle
  lesson, which was teaching the *opposite* of what the tab says (−0.113); it is now +0.566.

**Three genuinely new**, all one cause: the model now fits the CO₂ record so much better that
fixtures asserting "a bias is expensive" no longer start from an unbiased model. Measured on
the MLO annual record, model vs obs: **residual RMS 3.04 → 0.99 ppm**, mean residual
−1.49 → +0.80.

- `test-likelihood.R:114, :117` — `cost(1)` is now **−69.4**: shifting the model up 1 ppm
  moves it *toward* the observations. The AR(1)-pathology content these guard is intact and
  emphatic — `cost(50)` = **61,206** against the 10,000 threshold.
- `test-luc-scale.R:125` — wants the gross-vs-net gap > 10, gets 8.6. **That test's own
  comment predicted this**: the gap is large *because the model over-absorbs* (gross land
  4.57 vs GCB 2.36), and under MM it is 3.50, so the gap shrinks. "Do not fix this test by
  asserting gross beats net; that holds only for a model whose sink is right."
- `test-likelihood.R:135` — the `sigma_co2` profile peaks near the residual RMS, which moved
  3.04 → 0.99, so the bracketing sigmas are stale.

**NONE OF THE FOUR WAS EDITED TO PASS.** They are stale fixtures on an improved model, but
that is a judgement, and re-baselining a failing assertion is exactly how a real regression
gets absorbed. **Flagged for Marcus; left failing.**

### THREE SILENT-INERTNESS BUGS, all the same shape

Flipping the default made `beta` inert, and **every caller that set `beta` without setting
`fert_form` silently became a no-op.** All three were caught by *suspicious uniformity* —
identical rows where there should have been a spread — not by anything failing loudly.

1. **`R/mechanisms.R` — the app's "CO₂ fertilisation (the land sink)" switch.** `p$beta <- 0`
   moved CO₂ at 2100 by **exactly 0.00 ppm** while still rendering as a live control.
   `test-mechanisms.R`'s "every switch is wired up and CHANGES the answer" caught it. Now
   zeroes **both** `beta` and `beta_max`, which is correct under either form and cannot go
   stale at the next flip.
2. **`calibration/diag_fert_pulse_gates.R`** — its own log-form reference rows printed the MM
   answer to three decimals for every β. Caught by three identical rows.
3. **`calibration/diag_joos_beta_scan.R`** — `CCX_JOOS_BETA=0.50` would have returned the MM
   answer. It now implies `CCX_FERT_LOG`.

**Nine legacy diagnostics are pinned to `CCX_FERT_LOG`** (`diag_recentre_beta`,
`diag_beta_luc_profile`, `diag_luc_scale`, `diag_luc_prorata`, `diag_d13c_suess`,
`diag_d13c_partition_refit`, `diag_emission_scale_degeneracy`, `diag_1900_deficit`,
`diag_which_stream_pays`) with a comment saying why. They reproduce their recorded numbers
exactly — verified: `diag_fert_saturating.R`'s log-reference rows are bit-identical pre- and
post-flip. **The pin does not make them current**: anything there that fed a live decision
must be re-run under the saturating form.

### Quarantined

`calibration/output/mode_fit.rds` → `calibration/output/quarantine/20260814_pre_mm_fertilisation/`
with a README. Not a bug — a **model-structure change**. It is a 17-parameter posterior for a
model that no longer exists, and **no substitution carries it across** (MM → linear, not
logarithmic, as `fert_k → ∞`). `app/global.R`'s `identical(md$param_names, CCX_PARAM_NAMES)`
guard already rejected it; the quarantine stops anything else splicing it. The app now
correctly reports "uncalibrated defaults". **There is no canonical replacement until item 8
runs.**

### Also updated

- **`DESIGN.md` §6 gate 12 status** — was `12.6 / 26.2 / 43.6`, measured at **β 0.38, two
  re-centrings stale**, which is *why the failure at β 0.75 stayed invisible*. Now the
  measured pass, with the history written in and an instruction to re-measure on any
  fertilisation default change. **§6 gate 10** is no longer a "free check": it is the sourced
  GLODAPv2 term from earlier today.
- **`app/server.R`** — parameter labels for `beta_max` ("CO₂ fertilisation, maximum boost")
  and `fert_k` ("CO₂ needed for half that boost").
- **`app/global.R`** — the uncalibrated-defaults blurb said "β is set to the 1-D posterior
  optimum", false twice over now. Same failure mode as the deleted "about 27 ppm high" string.

### Priors, and why they are wide

Both new entries are uniform: `beta_max` on [0, 3.0], `fert_k` on [20, 2000]. **Nothing in
the literature set pins either at the ECOSYSTEM scale** — leaf-level Rubisco kinetics do not
transfer, and FACE experiments and CMIP6 models disagree by more than any prior width would
encode. The bounds are implausibility limits, not beliefs. If a sourced ecosystem-scale
constraint is ever found it belongs there with its citation.

## 2026-08-14 (cont.) — REFIT READINESS: item 8 is NOT unblocked, and two of the blockers got priced

Marcus asked to move to the refit "if that is the logical next step". **It is not**, and the
reasoning is measured rather than asserted. Handoff §6 blocks item 8 on items 2, 5, 5b, 5c, 6
and 7. **2 and 7 are now cleared.** The rest:

| blocker | priced | verdict |
|---|---|---|
| **5c** — omitted monthly seasonality in the emission inputs | **101 log-units** | **REAL. Blocks.** |
| **5 + 5b** — interhemispheric-gradient terms + time-varying LUC share | 5.1 log-units *today* | **Blocks, but only as a pair** |
| **6** — `LIK_EXCESS_C14_TARGET` | **0.7–1.4 log-units** | **NOT a blocker** — see below |

### 5c has teeth, and they are sharp

Measured directly: moving `seas_amp_NH` from 12 → 13 GtC/yr — an **8.3 %** change, which is
exactly the bias the handoff measured omitted LUC + fossil seasonality to induce — moves the
objective by **+101.1 log-units**, of which `co2_seasonal_MLO` supplies **+131.5**. So the
one free NEP amplitude absorbs the missing input seasonality one-for-one, in the objective's
most sharply-curved stream. **A refit today would bake an ~8 % input error into a fitted
parameter**, which is the same error class `luc_scale` was created to fix. The objective also
already *prefers* 13 to 12 by 101 log-units, so the fit will move `seas_amp_NH` up while the
input correction would move it back down — the two are directly confounded.

### 5 and 5b block only as a pair, and 5 is what makes 5b matter

The objective still barely sees the interhemispheric gradient — 5.1 log-units for 0.84 ppm.
So fixing the LUC hemispheric share alone (5b) changes essentially nothing in a fit, and the
review was right that it must land *with* 5. But **5 adds a stream**, and adding a stream
after a fit invalidates the fit. Either both before the refit, or both after — not split.

### 6 is CHEAPER than the ordering assumed, and a repo claim did not survive checking

`R/likelihood.R` asserted that choosing between the two published excess-¹⁴C reconstructions
"would put **~130 log-units** of leverage on a choice of paper". **That number has no receipt
anywhere in the repo and does not reproduce.** Measured at the current default and swept
across `bomb_total` 80–130 kmol, `table4_obs_range` and `table2_peacock` differ by
**0.7–1.4 log-units** — the model's own excess inventory sits between them and both terms are
weak there (−6 to −10). The *direction* survives (`table2_peacock` is ~3× tighter and would
constrain harder as a fit moved away from it); the *magnitude* was pattern-matched. The
comment now says so and asks for a receipt or a correction. **Practical consequence: item 6's
remaining half is not a blocker on the refit.** `sigma_d13c` was already decided (stays free).

### What IS worth running now, and is running

A **MAP mode-find** — `calibration/run_modefind.R`, regenerating the canonical
`calibration/output/mode_fit.rds` the flip quarantined. Cheap relative to MCMC (~0.060 s per
posterior evaluation), and it answers the one question the flip left open: **where do
(`beta_max`, `fert_k`) sit under the FULL objective**, given that gate 12 caps `fert_k` near
150 while the 1-D likelihood on the design-target locus preferred 171. It is explicitly a
point, not a posterior, and does **not** discharge item 8.

### Recommended ordering

1. the mode-find (running) — gives the app a calibrated point and settles the `fert_k` tension
2. **5c** — sourced monthly seasonality for both emission inputs (GFED + a monthly fossil
   product). The only blocker measured to bias a fitted parameter today.
3. **5 + 5b together** — the gradient terms and the time-varying LUC hemispheric share
4. **8** — the refit, ~2 h wall-clock on 4 parallel chains at 0.060 s/eval

### Also

`DESIGN.md` §6 **gate 7** now carries a measured status line (**still failing**: land +2.28σ,
ocean −1.52σ, down from +4.57σ / −2.13σ) with the gross-vs-net trap named and a note that
`luc_scale` does *not* close the remainder under the saturating form.

## 2026-08-14 (cont.) — THE MAP MODE UNDER THE SATURATING FORM: gates 7 AND 12 both pass, for the first time

`calibration/run_modefind.R`, 18 parameters, 293.6 min / 291,832 posterior evaluations at
0.060 s each. **Log-post −3774.0 → −2221.3, a gain of 1552.8** — of which 1532 came in the
first restart, since the hand-set start carried two brand-new parameters against an objective
that had also gained the deep-Δ¹⁴C term and the corrected GCB land term. Hessian
positive-definite, condition number 6.8e5. **No parameter beyond 3 prior sds.** Written to
the canonical `calibration/output/mode_fit.rds`; the app now reports "posterior mode / single
best fit" instead of uncalibrated defaults.

### The headline: the review's two failing hard gates both pass

| | review §0 (β 0.75) | MM default (`fert_k` 120) | **MAP mode** |
|---|---|---|---|
| **gate 7** land | **+4.57σ** | +2.28σ | **+1.54σ** (3.13 GtC/yr) |
| **gate 7** ocean | −2.13σ | −1.52σ | **−0.35σ** (3.08) |
| **gate 12** Joos IRF | **10.4/19.9/31.2 FAIL×3** | 12.4/25.6/41.9 | **12.6/26.0/43.0 INSIDE×3** |
| Revelle lesson | **−0.113 REVERSED** | +0.566 | **+0.515 HOLDS** |

**Gate 7 has never passed before.** DESIGN §6 opens "all must pass before headline claims";
on this evidence the two that were blocking do.

Paired sanity suite at the mode (per the `climate-modeling` discipline): **zero-pulse
max|ΔCO₂| = exactly 0**; sign-flip +19.78 / −18.71 ppm at +100 yr (correctly asymmetric);
halving ratio **0.4931** against 0.5 (correctly sublinear — larger pulses see a stiffer
Revelle factor).

### The fertilisation pair barely moved where it counts

`beta_max` 0.4913 → **0.5087**, `fert_k` 120 → **153.1**. `fert_k` moved 28 % — past the ~150
gate-12 cap measured on the *design-target locus* — **but the gate did not break, and the
reason is the point of the whole form change.** `beta_max` moved with it, so the marginal
slope at 388 ppm went 0.0662 → **0.0669**, essentially unchanged and still well under the
0.077 ceiling. The fit slid *along* the decoupled direction the log form does not have. The
apparent likelihood-vs-gate tension recorded at the flip was an artefact of scanning a
one-parameter locus.

### THREE THINGS THAT MUST NOT BE BURIED

**1. `sigma_co2` collapses to its prior tail (0.223, z −2.56) — and the cause is not the AR(1)
pathology.** The MLO residual RMS at the mode is **0.642 ppm**, so RMS/`sigma_co2` = 2.88,
which reads like the collapse this repo has history with. It is not: the likelihood uses
`sqrt(sigma_co2² + LIK_CO2_REP_ERR²)` and **`LIK_CO2_REP_ERR` is fixed at 1.0 ppm**, so the
effective sd is 1.025 — *larger* than the residual it is explaining. **The model now fits the
CO₂ record better than the assumed station-vs-hemispheric-box representation error**, leaving
`sigma_co2` nothing to do. That 1.0 ppm constant is now the binding term in the objective's
highest-leverage stream and needs re-deriving, not the free parameter. (δ¹³C is healthy by
comparison: RMS 0.383 against `sigma_d13c` 0.336, ratio 1.14.)

**2. Both ocean-uptake parameters are pressed against their bounds, and that points at the
pump.** `kz` = **6119**, which is **96.6 %** of the way to its bracket's upper bound; `h_ml` =
**184.0 m**, **90.6 %** of the way up a uniform [30, 200] prior and far deeper than any
plausible global-mean mixed layer. The deep-Δ¹⁴C term is being overridden to get there — the
bottom box lands at −157.8 ‰, **z +1.70** against its own target. So the ocean is being forced
to absorb more carbon by whatever means the parameters allow, which is exactly the signature
review §4.2's pre-registered pump test predicts. **The `kz` bracket Marcus retained this
morning is now demonstrably load-bearing**: without it this mode would have run `kz` away
again.

**3. `luc_scale` = 1.0049 — it does not move.** The parameter added this morning to give
E_LUC its own uncertainty sits *on* its prior median. Under the saturating form the fit does
not want it, which confirms from the fit side what §5 of `diag_fert_saturating.R` measured
by hand: **MM and `luc_scale` are redundant, and MM won.** The handoff's β 0.55 / `luc_scale`
0.70 settlement is now doubly superseded. `luc_scale` should be kept (it costs nothing and it
prices a real input uncertainty) but it should stop being described as the lever that closes
the sink partition.

### Still outstanding, and the mode sharpens one of them

`seas_amp_NH` fits to **19.66** GtC/yr against a default of 12 — a 64 % move, in the stream
where an 8 % shift is worth 101 log-units. Item **5c** (sourced monthly seasonality for both
emission inputs) is confounded with this parameter and remains the blocker with teeth.
**This is a MAP point, not a posterior**, and items 5, 5b and 5c would each invalidate one —
so it does not discharge item 8. `bomb_total` fits to 113.97 (z +2.50), the highest-tail
parameter in the vector, and is worth watching when a posterior does exist.

## 2026-08-15 — ITEM 5c: the emission inputs now carry sourced monthly seasonality

Both emission inputs reached the model with **no within-year cycle at all** —
`ccx_annual_to_monthly()` interpolates the annual *trend* smoothly and leaves every month
within a whisker of its annual mean. Real fossil emissions peak in NH January and real
land-use fire peaks in the burning hemisphere's dry season, and the model's single free NEP
amplitude was absorbing the difference.

### Sources

| | dataset | citation |
|---|---|---|
| **fire** | GFED4.1s, monthly 0.25°, **2001–2016** | van der Werf et al. 2017, ESSD 9:697–720, doi:10.5194/essd-9-697-2017 |
| **fossil** | EDGAR v4.3.2 monthly, by country × IPCC sector, 1970–2012 | Crippa et al. 2020, Sci Data 7:121, doi:10.1038/s41597-020-0462-2 |

Both in `MANIFEST.csv`. The bulk inputs (1.2 GB of GFED HDF5, a 26 MB EDGAR xlsx) are
gitignored; `data-raw/extract_emission_seasonality.py` reduces them to two ~30 KB CSVs which
**are** committed, so a fresh clone can rebuild without re-downloading.

GFED beta years (2017+) are excluded — the product's own header says they are extrapolated
and "not suitable for trend analyses". 2001 is the start of the MODIS record it is built on.

### The weights, and the phase checks that make them falsifiable

| | J | F | M | A | M | J | J | A | S | O | N | D |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| fossil NH | **1.29** | 1.12 | 1.06 | 0.93 | 0.87 | 0.86 | 0.88 | 0.87 | 0.89 | 0.97 | 1.05 | 1.21 |
| fossil SH | 0.94 | 0.95 | 0.93 | 0.95 | 0.98 | 1.07 | **1.21** | 1.05 | 1.04 | 0.99 | 0.95 | 0.94 |
| LUC fire NH | 1.84 | 1.90 | **3.15** | 1.29 | 0.74 | 0.66 | 0.75 | 0.63 | 0.13 | 0.10 | 0.16 | 0.64 |
| LUC fire SH | 0.02 | 0.02 | 0.03 | 0.02 | 0.21 | 0.57 | 0.87 | 3.26 | **5.03** | 1.64 | 0.25 | 0.07 |

Fossil NH peaks in January and fossil SH in July — **opposed, because the driver is winter
heating**. LUC fire SH peaks in September — the southern-Africa / Amazon / Indonesia dry
season. Both are asserted in `test-emission-seasonality.R`, because a sign or index error
sails straight past a conservation test.

### THE LOAD-BEARING DECISION: E_LUC is not fire

GFED's deforestation-and-peat carbon is **0.367 PgC/yr** (2001–2016) against GCB's E_LUC of
**1.699 GtC/yr** — so **only 21.6 % of E_LUC burns**. The rest is wood harvest, product decay
and soil-carbon loss, with no comparable cycle. The land-use weight is therefore **damped**:

> `w_eff(m) = 1 + f_fire · (w_fire(m) − 1)`, with `f_fire = 0.216` **measured, not assumed**

Applying the raw fire shape to all of E_LUC would have overstated the correction by ~4.6× —
**in the direction that looks like success**, since a bigger input seasonality pulls
`seas_amp_NH` further and would read as a bigger fix. Fossil is *not* damped: all of it is
combustion. `f_fire = 0` reduces exactly to the incumbent model, which is what makes the
change auditable. Savanna and agricultural-waste burning are excluded on purpose — they are
recurring cycles whose regrowth returns the carbon, not land-use *change*.

### What it bought

At the MAP mode's other parameters, profiling `seas_amp_NH`:

| | `seas_amp_NH` | log-post |
|---|---|---|
| seasonality OFF | **19.66** GtC/yr | −2194.0 |
| seasonality ON | **18.65** | −2195.3 |

**−1.01 GtC/yr, −5.1 %**, in the predicted direction. (The OFF value reproduces the
mode-find's fitted 19.66 exactly — an independent check that the profile machinery and the
MCMC agree.) The handoff's bounding test predicted ≤8 %; the sourced version comes in at
5.1 %, which is right, because that bound used an undamped "plausible size" and the measured
`f_fire` is 0.216.

**BE CLEAR ABOUT WHAT THIS IS: a bias correction, not a fit improvement.** The log-posterior
is **1.3 units WORSE** at the new optimum. The model fitted the seasonal cycle slightly better
when it could pour all the seasonality into one free parameter. The value of the change is
that `seas_amp_NH` now means what its name says — biosphere NEP amplitude — instead of
"biosphere NEP plus whatever the inputs should have contributed". Anyone hoping 5c would raise
the log-posterior should stop expecting that.

### Conservation

Seasonality redistributes within a year and must create nothing. `ccx_seasonalise()`
multiplies by the weight and then rescales each calendar year back to its own pre-weighting
mean. Measured: **max |Δ annual total| = 1.8e-15 GtC/yr** (fossil), 4.4e-16 (LUC), and the
final cumulative land-use carbon matches to 6.8e-13 GtC. `cum_luc` is now integrated **per
hemisphere from the seasonalised flux** rather than split from a global series — the two agree
at every year boundary but not within a year, and the converted-land term reads it monthly.

### Bonus finding, for item 5

The EDGAR country aggregation measures the **NH share of fossil CO₂ at 0.9201**, against
`FORC_FOSS_NH_SHARE = 0.95`, which has carried a "PROVISIONAL" comment since it was written.
**Not changed here** — it feeds the interhemispheric gradient (item 5), where the handoff
prices 0.90 → 0.97 at 0.84 ppm of MLO−SPO for 5.1 log-units. That is item 5's decision, and
the measurement is now waiting for it.

### Files

`R/forcing.R` (`FORC_USE_EMIS_SEASONALITY`, `ccx_emission_seasonality()`,
`ccx_seasonalise()`, per-hemisphere `cum_luc`), `data-raw/extract_emission_seasonality.py`
(**new**), `data-raw/build_emission_seasonality.R` (**new**),
`data/forcing_emission_seasonality.rds` (**new**), `tests/testthat/test-emission-seasonality.R`
(**new**, 41 assertions), `MANIFEST.csv`, `.gitignore`.

**Suite still 8 failing, the same 8.** No new failures.

---

## 2026-08-15 (later) — ITEMS 5b AND 5: the hemispheric shares are sourced, and the gradient is finally in the objective

Review items **5b** and **5** landed together, in that order, because 5 is the only thing
that can score 5b. With 5c already done on the same day, the review ordering now has
**items 1–5c and 7 discharged** and item 8 (the refit) unblocked on everything except the
four test failures still waiting on Marcus.

### 5b — the land-use hemispheric share (`98f0457`)

`FORC_LUC_NH_SHARE = 0.55` had carried a "provisional" comment since it was written and is
wrong at **both** ends. OSCAR v3.1's *Regional* sheet — the same workbook DATA.md §3a already
uses for the pre-1850 E_LUC segment, whose 1750–2018 total reproduces the paper's 206 PgC
headline — gives a flux-weighted NH share of **0.838 (1750–1849) → 0.398 (1990–2018)** as
clearing moved from temperate NH forests to the tropics. Against the constant that is
**+31 GtC** of cumulative land-use carbon misplaced by 1959.

The within-region NH fractions are geographic judgements, not data, so the product ships a
lo/central/hi bracket — and **the direction survives all of it**: pre-1950 even the low end is
≥ 0.60, post-1990 even the high end is ≤ 0.53. The two ends do not overlap under any
admissible judgement, which is what makes *"no constant works"* a measurement. 0.55 is not
even the flux-weighted mean (0.620).

Three properties that could each have been silently wrong, all gated by
`test-luc-nh-share.R` (22 assertions), two of them mutation-tested:

- **One share per calendar year, held, not interpolated to months** — keeps
  `mean_year(luc_NH) = share(y)·mean_year(luc)` exact and puts the only discontinuity on the
  year boundary, where the per-year harmonic estimator cannot alias it into the seasonal
  statistic.
- **The pre-window cumulative takes its own flux-weighted share.** A run from 1900 splits
  ~58 GtC of prior clearing on the pre-1900 share (~0.79), not the window's (~0.49). Getting
  this wrong misplaces ~14 GtC of converted land and **nothing else in the suite would see
  it** — the flux still conserves.
- **Outside 1750–2018 the end value is held**, stated as extrapolation: every SSP run splits
  on a frozen 2018 share. Extrapolating the decline forward runs it negative before 2260.

`FORC_USE_LUC_NH_SHARE_TS = FALSE` reproduces every earlier result, max |diff| **exactly 0**
across every numeric column of both a full-record and a windowed forcing.

**What it bought, and what it did not.** Gradient 5.26 → 5.03 ppm (obs 3.97). δ¹³C gradient
barely moved (−0.245 → −0.238 vs −0.074), **confirming the shares are not the cause of that
3× miss** — that lead is dead. **Log-posterior DOWN 17.2**, almost all in `co2_seasonal_MLO`.
A bias correction, not a fit improvement, exactly as 5c was.

### 5 — the measurement first (`abf8e3b`), then the terms

`calibration/diag_gradient_terms.R` measured the five things the σ depends on before anything
was written, because **the σ is the decision**:

1. **The likelihood's own estimator reproduces gate 9** to ≤ 0.02 ppm on every decade it
   covers, and drops the 1950s entry (8 paired months, "indicative only" by gate 9's own
   note). No new estimator; design note 1b's same-machinery-both-sides property preserved.
2. **Observational floor ~0.23 ppm, measured** — Scripps vs NOAA disagree by 0.225 ppm RMS on
   the annual gradient. And it is a *lower* bound: handoff 15 §4.1's flag is **confirmed**,
   `MLO` and `MLO_NOAA` agree to **0.002 ppm RMS over 189 months** — one series under two
   names. So 0.225 is the two SPO records alone. For δ¹³C the floor is 0.0152 ‰ and *that* one
   is a genuine two-station two-network comparison (the records share no month timestamps).
3. **The miss is not one thing, and the two species differ.** CO₂: intercept **and** slope
   rejected — a stable −0.45 ± 0.10 ppm offset (the sign and size a station-below-the-source-
   region argument predicts) *plus* a real shape error whose sign changes across the record
   (b = 0.845 at defaults, 1.14–1.23 at the mode). δ¹³C: **b = 1 admissible in all four fits**,
   only the +0.10 ‰ intercept rejected — a pure offset, and **8× larger** than scaling CO₂'s
   19 % predicts, so it is absorbing the known structural δ¹³C misfit rather than a
   representation constant.
4. **The double count is second-order.** The two station levels imply a gradient sd of 1.45 ppm
   (2.55 at σ_co2 = 1.5); a term at 0.35 outweighs that ~17× in variance. **Adding** a term is
   correct; rotating the (MLO, SPO) pair would rewrite the two highest-leverage streams to fix
   something that is not binding.
5. **The leverage is large and points the other way** — +193/−643 log-units per prior sd of
   τ_ex at σ = 0.35, against τ_ex's whole prior leverage of ~350, and **opposite in sign** to
   what the rest of the objective wants (−207/+105).

**Marcus's three decisions, all taken on those numbers:** level + offset parameter for CO₂;
same treatment for δ¹³C; and move `FORC_FOSS_NH_SHARE` 0.95 → **0.9201** (measured, EDGAR
v4.3.2) — the gradient term prefers it by +95 log-units and the rest of the objective is
indifferent (−1.5).

**Shipped.** Streams `co2_gradient` and `d13c_gradient`; parameters **18 → 20**
(`grad_off_co2` N(0, 0.5) ppm, `grad_off_d13c` N(0, 0.15 ‰), both **shrinkage priors centred
at zero** — centring them on the measured offsets would tell the model the answer and then
credit it for agreeing). σ = the measured model-vs-obs scatter about a constant offset,
floored by the observations' own precision: **0.35 ppm / 0.025 ‰**. Both terms start near
χ²/dof ≈ 0.6.

**The offsets ride in `err`, and their ABSENCE skips the terms** rather than defaulting to
zero — the same contract `deep` uses. A zero offset is not a neutral default: it asserts the
box gradient *is* the station gradient, which the measurement rejects at 95 %. Every
diagnostic written before today therefore shows the streams as ABSENT under `by_stream`,
which is visible, instead of scoring them wrong.

**Effect.** τ_ex's constraint is now dominated by the gradient (+366/−950 log-units per prior
sd) and it pulls **opposite** to everything else (−208/+107). DESIGN's decade-old claim that
gate 9 constrains τ_ex is true for the first time.

### Tried and NOT done

- **Rotating (MLO, SPO) → (mean, gradient).** Statistically the cleanest answer to double
  counting, and rejected on measurement: the overlap is second-order (§4 above), so the
  rotation would rewrite the objective's two highest-leverage streams to fix something that is
  not binding.
- **Interpolating the land-use share smoothly to months.** Would cost the exact annual
  identity and buy nothing — the share moves ~0.0016/yr, so the calendar-year step is
  ~0.003 GtC/yr and, being *on* the year boundary, cannot alias into the seasonal statistic.
- **Making `FORC_FOSS_NH_SHARE` a calibrated parameter.** Offered and declined: it would
  correlate hard with the land-use share and τ_ex, and the sampler already has an r = −0.907
  pair to manage.
- **Centring the offset priors on the measured intercepts.** That is a measurement wearing a
  prior's clothes. Both are centred at zero and the prior *widths* were chosen so the measured
  values sit near 1 sd.

### Quarantined

`calibration/output/mode_fit.rds` → `calibration/output/quarantine/20260815_pre_gradient_terms/`
with a README. Not a bug — the 18-parameter mode belongs to a model with a different input
(5b) and an objective with two fewer streams, and its log-posterior is **not on the same scale**
as anything computed after today. The canonical path is **empty** until item 8 runs.

**Files:** `R/likelihood.R`, `R/calibrate.R`, `R/forcing.R`, `DATA.md` (§6, new §6a),
`DESIGN.md` (gate 9), `data-raw/build_luc_nh_share.R` (**new**),
`data/forcing_luc_nh_share.rds` (**new**), `calibration/diag_gradient_terms.R` (**new**),
`calibration/output/gradient/` (**new**), `tests/testthat/test-luc-nh-share.R` (**new**, 22),
`tests/testthat/test-gradient.R` (**new**, 28), `tests/testthat/test-likelihood.R`
(the 18 → 20 tripwire, recorded not bumped, per that test's own convention).

**Suite still 8 failing, the same 8.** The parameter-count tripwire fired as designed and was
recorded; no new failures.

### Later the same day — three of the four flagged tests, RE-EXPRESSED not re-baselined

Marcus took all three. Each repair replaced a hard-coded fixture with a **derived** quantity,
and each was mutation-tested. **Suite 8 → 4 failing, 695 passing.**

| test | was | now |
|---|---|---|
| `test-likelihood.R` CO₂-bias | `cost(1) > 100` measured **from zero** | cost measured **from the fitted offset**; the guard is the **curvature**, A > 10 log-units/ppm² (AR(1) pathology was ~0.0055, so a ~1800× margin) |
| `test-likelihood.R` σ_co2 profile | collapsed value must lose to a hand-picked σ = 5 | the profile optimum, as an **effective sd**, within 1.5× the **measured residual RMS** |
| `test-luc-scale.R` gross-vs-net | `abs(gross − net) > 10` | the **closed-form E_LUC displacement**, asserted to 1e-8, plus a materiality check |

**Every one had gone stale for the same reason: the model improved.** The CO₂-bias test was
measuring the model's own level bias rather than the price of a bias (MLO residual mean is now
+0.97 ppm, so a +1 ppm shift is an *improvement* and "cost(1)" is −68), and it broke twice as
the level fit got better. σ = 5 stopped being a sane comparator once the residual RMS fell to
~1.13 against a *fixed* `LIK_CO2_REP_ERR` of 1.0 — and handoff §4.1 had already established
that σ_co2 → 0 is the **correct** inference here, not the AR(1) pathology it resembles. The
gross-vs-net gap is large *because the model over-absorbs*, so it shrinks as the sink improves
(4.57 → 3.50 → 3.48 GtC/yr): that test used a symptom of the old bug as a proxy for the fix and
would have failed **harder** the more the refit succeeded.

**Mutation tests.** Reverting `gcb_land_sink` to the NET comparison → 2 failures in
`test-luc-scale.R`. Inflating the CO₂-level sd 30× (the AR(1) loophole in effect) → 3 failures
in `test-likelihood.R`. Both gates have teeth.

**The 4 that remain were never flagged for Marcus and are untouched:** `test-luc-permanence.R`
(the fossil reference arm; and a case needing `f_luc_wood = 1` that sets only `f_luc_perm`),
`test-mechanisms.R` (ENSO switch weak, 0.30 vs > 0.5), `test-pulse.R` (ssp119 airborne
fraction, an *unbenchmarked* ballpark check on a declining background while the
protocol-matched gate 12 passes).

### The refit is HELD

Item 8 is structurally unblocked by 5 + 5b. **Marcus held it** pending the `sigma_co2` decision
(unidentified, pinned at a boundary, "fix it or drop it, do not sample it"). ~6–7 h at 20
parameters and 0.083 s/eval. `calibration/output/mode_fit.rds` stays **empty** until it runs.

## 2026-08-15 (later still) — ITEM 6b MEASURED: the case against `sigma_co2` largely does not hold

`calibration/diag_sigma_co2.R` (new, ~1 min, output `calibration/output/sigma_co2/`). **No code
changed.** This is the measurement the `sigma_co2` decision was waiting on, and it was run
before touching the parameter because the previous two handoffs asserted a pathology from a
single number (σ_co2 = 0.223 at the MAP mode, z ≈ −2.6) without testing the claims that number
was taken to imply.

**The analytic frame, first, because it reorganises everything.** The CO₂ level terms use
sd = √(σ_co2² + `LIK_CO2_REP_ERR`²) with the constant fixed at 1.0 ppm. Writing v = σ² + c²,
the ML solution is v = R² for pooled residual mean-square R², so **σ*² = R² − c² — which has no
real solution whenever the pooled residual RMS falls below 1.0.** "Pinned at a boundary" is
therefore not a property of `sigma_co2`; it is a statement about R.

**And R is not one number.** The repo straddles the threshold:

| parameter point | R_MLO | R_SPO | R_pool | interior optimum? |
|---|---|---|---|---|
| `ccx_default_params()` | 1.127 | 1.750 | **1.454** | **YES**, σ* = 1.056 |
| pre-gradient MAP mode | 0.650 | 0.571 | **0.614** | NO — likelihood monotone decreasing |

The same model at two points in its own parameter space sits on opposite sides. That is also
why `test-likelihood.R`'s interior-maximum assertions still pass: its fixture is on the other
side. The margin at the mode is **0.789 ppm** of additional sustained bias — well inside an
MCMC chain's early excursions.

**Three of the four stated grounds are refuted:**

- **"Pinned at a boundary."** Not in the coordinates the sampler uses. `sigma_co2` is
  log-transformed; σ → 0 is u → −∞ and the lognormal prior closes it off smoothly. The
  posterior mode is **interior and unimodal on the log scale at both points** (0.226 at the
  mode, 1.072 at defaults). There is no edge to be pinned against.
- **"Will hurt covariance conditioning."** Measured from the stored Laplace correlation:
  **max |r| = 0.043** (with `luc_scale`), against a worst pair of **0.907** (`luc_scale`–`fert_k`)
  in the same matrix. `sigma_co2` is very nearly orthogonal to every other parameter.
- **"Unidentified."** The data tighten it **2.08×** relative to prior at the mode and **5.79×**
  at defaults. It ranks 4th of 18 by posterior width (0.324 unconstrained) — behind
  `npp_frac_NH` (1.318), `h_ml` (0.984) and `kz` (0.978), none of which is proposed for removal.

**One objection survives, and it is a different one — none of the handoffs made it.**
`sigma_co2` is a free error scale on the stream that already outvotes the partition terms 40:1,
which makes it **self-weighting**: the better CO₂ is fitted, the smaller σ goes, and the louder
the CO₂ stream becomes. Measured across the two points, as R fell 1.454 → 0.614 the effective
sd fell 1.4659 → 1.0251, i.e. the CO₂ level stream got **2.04× louder in variance terms**.
Positive feedback on the dominant constraint, in the direction that worsens the imbalance the
whole review is about. Nothing in the objective asked for it.

**What each option costs**, in the only currency that matters (the effective sd *is* the stream
weight):

| option | σ_co2 | effective sd | weight vs free | implied gradient sd | vs `LIK_GRAD_CO2_SD` |
|---|---|---|---|---|---|
| DROP (fix at 0) | 0.000 | 1.0000 | 1.05× | 1.414 | 16.3× |
| FIX at the MAP value | 0.223 | 1.0246 | 1.00× | 1.449 | 17.1× |
| FIX at the prior median | 1.500 | 1.8028 | 0.32× | 2.550 | 53.1× |

The first two are within 5 % of each other and of the status quo, so the `LIK_GRAD_*` "re-measure
if σ_co2 moves" condition is satisfied either way — the ~17× that justified *adding* a gradient
term rather than *rotating* the (MLO, SPO) pair survives at 16.3×. The prior-median option is a
real 3× re-weighting and is not a null choice.

**Stated cost of fixing it, since it is not zero:** the free σ is also the only adaptive valve on
the CO₂ level stream, and part 2 shows chains will cross back into R > 1.0 where a fixed σ prices
a bad CO₂ fit at full volume with no give.

**Decision goes to Marcus** (stream weighting, per the standing rule that weighting choices are
never resolved silently). The refit stays HELD.

## 2026-08-15 (later still, part 2) — ITEM 6b TAKEN: `sigma_co2` retired, 20 → 19 parameters

**Marcus's call on the measurement above: fix at 0.** The CO₂ level sd is now
`LIK_CO2_REP_ERR` = 1.0 ppm alone — the half of the old √(σ_co2² + c²) that has a receipt
(co-located independent programmes at MLO disagree by 0.39–0.59 ppm RMS, n = 702 months). **The
refit remains HELD**; item 6b is discharged, so item 8 is now unblocked on the objective side.

**The reason is recorded in three places (`R/calibrate.R`, `R/likelihood.R`,
`test-likelihood.R`'s parameter ledger) because it is NOT the reason the two prior handoffs
gave.** Those grounds — boundary-pinned, unidentified, bad for covariance conditioning — were
measured and failed on all three counts. What retired it is that a free error scale on the
stream that already outvotes the partition terms 40:1 is **self-weighting**: as the pooled
residual fell 1.454 → 0.614 ppm the effective sd fell 1.4659 → 1.0251, making the CO₂ level
stream **2.04× louder**. Positive feedback on the dominant constraint.

**Changes.**

- `CCX_PARAM_TABLE$sigma_co2` removed; `ccx_make_logpost()` omits the field **explicitly**
  rather than passing a zero — the two are identical arithmetic today, so passing 0 would let a
  future contract change silently revert to the old branch.
- `ccx_loglik()` gains a two-branch contract on the CO₂ level sd: **absent → `LIK_CO2_REP_ERR`**
  (the objective), **present → the old quadrature** (legacy parity). The absence being the *new*
  behaviour inverts this repo's usual absence-skips-a-stream idiom, deliberately: an updated
  caller says so by dropping the field, and a stale one keeps its old weight instead of being
  silently re-weighted. **Verified: `diag_sigma_co2.R` reproduces bit-for-bit across the change.**
- `LIK_CO2_REP_ERR`'s comment now carries its receipt and states that it is **conservative, not
  tight** — χ²/dof ≈ 0.38 against the last mode's residual. Lowering it would give the loudest
  stream *more* leverage and is flagged as a stream-weight change, not taken.
- Objective re-checked end to end: 19 parameters, finite log-posterior at init (−4057.94).

**What was given up, stated because it is not nothing:** the free σ was the only adaptive valve
on the CO₂ level stream, and the margin at the mode is 0.789 ppm of extra bias, so chains *will*
cross into R > 1.0 where a fixed sd prices a bad CO₂ fit at full volume. If the refit shows that
biting — CO₂ level dominating the trace, or a chain unable to leave a bad-CO₂ region — this is
the first thing to look at. Recorded in `R/calibrate.R` next to the retirement.

**Tests: +5 assertions blocks, all three mutation-tested, suite still 4 failing (unchanged).**

| new gate | asserts |
|---|---|
| `test-likelihood.R` absent-σ contract | the sd is **exactly** `LIK_CO2_REP_ERR`, is *not* some other constant, and σ_co2 = 0 agrees to 1e-12 |
| `test-likelihood.R` legacy parity | σ_co2 ∈ {0.223, 1.5, 5} still reproduces √(s² + c²) |
| `test-likelihood.R` direction + magnitude | retirement **hardened** the stream (strict, both σ), weight change < 1.10×, and `sigma_co2` is gone from `CCX_PARAM_NAMES` |
| `test-gradient.R` case 6 | the double-count ratio, **re-measured** at 16.3× — a pure constants check now that `LIK_CO2_REP_ERR` is its only input |

**Mutations, all caught:** loosening the absence branch to 1.5× → 4 failures; dropping the
quadrature from the legacy branch → 5; lowering `LIK_CO2_REP_ERR` to 0.4 → 2 in `test-gradient.R`.
The parameter-ledger test fired on the count as designed and was **recorded, not merely bumped**.

**DESIGN.md §5.2 corrected.** It still described the AR(1) model retired on 2026-08-11 *and* a
free σ_add for CO₂. Both corrections are dated in place, with §5.1's draft table marked
unmaintained and `R/likelihood.R` / `CCX_PARAM_TABLE` named as authoritative. Gate 9's standing
"re-measure on any change to … σ_co2" instruction now names `LIK_CO2_REP_ERR` and records the
re-measurement it asked for.

## 2026-08-15 (later still, part 3) — ITEM 9's PREREQUISITE: h_ml is a capacity-side workaround for an export deficit, and the pump case gets STRONGER

`calibration/diag_h_ml_roles.R` (new, ~3 min, output `calibration/output/h_ml_roles/`). **No
model code changed.** Run before the refit at Marcus's direction: handoff §4.2 listed a cheap
h_ml test as item 9's prerequisite, and if it motivated a pump that would be a *structural*
change, throwing away any mode found first.

### The first design was invalid, and is quarantined rather than deleted

Handoff §4.2 proposed "hold the mixed-layer carbon inventory fixed while varying its depth". The
first implementation did that by driving `aux$ml_mass_kg` (capacity) and `grid$dz[0]` (geometry)
at **different** depths. **That is not a decomposition.** The two are encodings of one
quantity — the core reads the chemistry's concentration as `y_ml/ml_mass_kg` and the diffusion's
as `y_ml/dz[0]` — so making them disagree makes "mixed-layer concentration" mean two different
things inside one timestep.

It announced itself: at h = 184 m the arms gave BOTH **+425.9**, CAPACITY **−26,203.8**, EXPORT
**−29,035.3** — an **interaction of +55,665 against an effect of +426**. Diagnosed rather than
interpreted, and the sign pattern confirms the artefact exactly (CAPACITY arm over-ventilates:
deep Δ¹⁴C −216, sink 4.84; EXPORT arm under-ventilates: deep −133, sink 1.53). Post-mortem in
`calibration/output/quarantine/20260815_h_ml_inconsistent_grid_arms/README.md`. A second, smaller
defect in the same file: the deep-Δ¹⁴C confound control filtered on `d14c_deep` when the stream
is **`d14c_deep_ocean`**, so it was a silent no-op — caught only because the diagnostic printed
both columns and they were identical everywhere. **A `ccx_spinup(grid=)` argument added to
support the invalid design was reverted**; leaving API surface whose only known use is refuted
invites its reuse.

### The replacement uses only consistent grids, and the two pre-registered tests DISAGREED

| step | result |
|---|---|
| **1. signs, off the grid alone** | 75 → 184 m: ML capacity **×2.45**, ML→interior conductance **×0.54**. The two channels have *opposite* signs, which is what makes them separable without surgery. |
| **2–3. where the carbon goes** | +32 GtC extra in the **mixed layer**, **−19 GtC** in the interior. Ocean sink 2.87 → 3.06. → **CAPACITY signature** |
| **4. kz, the pure export knob** | preferred depth across a 6× kz range: 220, 220, **184**, 50, 50, 50 m. At kz ×1.4 the model wants a **50 m** mixed layer. → **EXPORT signature** |

**Both are true at different levels, and the reconciliation is the finding:** what the objective
is short of is ocean **uptake**; h_ml = 184 m is a **capacity-side workaround for an export
deficit**, reached for because `kz` is bracket-limited (96.6 % of the way up). So h_ml is not
evidence against the pump — it is a symptom of the same shortage. The Laplace r(h_ml, kz) =
**−0.211** is consistent: they substitute, weakly, in exactly this way.

### Why kz cannot simply be freed — and why that is the pump's case

Diffusion ventilates ¹⁴C in proportion to the carbon it moves. Buying uptake with kz drives the
deep-Δ¹⁴C term from **z +1.70 → +4.47**, away from a target (−175.3 ± 10.3 ‰) the model already
misses on the under-depleted side; at kz ×1.4 the CO₂ level streams lose 712 log-units between
them (over-absorption, sink 3.37). **A biological pump exports carbon as sinking particles and
remineralises it at depth — adding uptake without mixing surface water down.** No knob currently
in the model can do that. **The pump case comes out of this stronger than handoff §4.2 had it,
not weaker.**

### Item 9's pre-registered test is AMENDED

It was: *does h_ml relax below ~163 m and kz off the top of its bracket, while the ocean sink
holds near 3.1?* Part 4 makes the h_ml clause **measured-plausible** rather than speculative —
but it is not sufficient. **Third clause added: does deep Δ¹⁴C move TOWARD −175.3 rather than
away?** That is the clause the kz route fails, and therefore the one the pump must beat to be an
improvement rather than a re-arrangement. Recorded in the diagnostic's own output, not only here.

**Still standing:** the conveyor is still NO (falsified twice in-repo). The `kz` bracket is still
load-bearing — this run is further evidence, since without it the fit would buy uptake by
wrecking deep Δ¹⁴C.

---

## 2026-08-15 (later still, part 4) — THE DIC-GRADIENT DIAGNOSTIC: all three of item 9's clauses PASS, and the uptake argument for the pump is dead

`calibration/diag_dic_gradient.R` (new, ~15 min, output `calibration/output/dic_gradient/`).
**No model file was touched** — the pump is a shim over `ccx_deriv()` in the diagnostic's own
environment, with **zero fitted parameters**: the export field is *solved* as the source that
makes GLODAPv2's own observed DIC profile an exact steady state of the model's own diffusion
operator. No Martin curve is chosen; no export magnitude is fitted.

Also: **`kz(z)` depth-dependence and the high-latitude outcrop were added to the candidate list**
(Marcus 2026-08-15). They now live in **DESIGN.md §3.4a** together with the pump and the
conveyor, and with the five observables that discriminate them. §10's v2 backlog points there.

### Two of my own predictions were measured and FAILED. Both are recorded, not dropped.

1. **The Revelle/capacity channel does not exist.** I proposed this diagnostic on the argument
   that the missing gradient means preindustrial *surface* DIC is too high, hence the buffer
   factor is too high, hence the mixed layer absorbs too little. **Measured:** the model's ML is
   1986.3 µmol/kg; GLODAPv2's 0–75 m volume-weighted mean is 2028.9 µmol/kg **modern**, i.e.
   ≈1979 preindustrial once ~50 µmol/kg of anthropogenic carbon is allowed for. The model's
   surface is right to ~7 µmol/kg. **The entire 244.7 µmol/kg deficit is interior.**
2. **The pump makes deep Δ¹⁴C MORE depleted, not less.** I argued the opposite — that sinking
   particles carry the mixed layer's young (−51 ‰) ratio down and dilute the deep. Wrong: the
   pumped carbon is delivered young but leaves only by the same slow diffusive return, so deep
   inventory rises ~12 % while the ventilation flux rises much less, mean age goes up, and decay
   beats the injection value. **The residence-time channel dominates the injection-value channel.**
   This flips the sign of clause 3 between operating points and is why part 6 scores at the mode.

### The pre-registered prediction, and it came out EXACT

Stated before part 3 ran: the interior is a passive tracer with no chemistry and diffusion is
linear in concentration, so a static background DIC profile superposes on the anthropogenic
perturbation and cannot change how it propagates. **Therefore a nutrient-limited (constant-mass)
pump must change the ocean sink by exactly zero.**

**Measured: +0.000000 GtC/yr.** Only a DIC-limited export moves it, and only by **+0.130 GtC/yr**
at 22.0 GtC/yr of export. **The "pump supplies the export deficit" argument of handoff 15c §3.3
is therefore wrong as stated** — in this model the pump is not an uptake mechanism at all. What
it moves is the isotopes and the background state, and — via the *background state* changing
which `h_ml` the objective wants — it moves `h_ml`.

### All three of item 9's amended clauses PASS, at the mode, at zero fitted parameters

At the pre-gradient MAP mode's other parameters, each arm at its own best depth:

| | pump OFF | pump ON |
|---|---|---|
| `h_ml` | 184 m | **100 m** |
| logL | −2269.7 | −2283.4 |
| ocean sink | 3.063 | 3.052 GtC/yr |
| deep Δ¹⁴C | −157.8 (z **+1.70**) | −164.2 (z **+1.08**) |

- **CLAUSE 1 PASS** — `h_ml` relaxes 184 → 100 m. The pump *does* supply what `h_ml` was faking.
- **CLAUSE 2 PASS** — the sink holds at 3.05 against 3.06, i.e. the same sink at a physical
  mixed-layer depth instead of an unphysical one.
- **CLAUSE 3 PASS** — deep Δ¹⁴C moves **toward** −175.3, z +1.70 → +1.08.
- **Cost: −13.7 log-units with nothing refitted.** The largest single loss channel is atmospheric
  Δ¹⁴C (−30/−31 NH/SH), and `bomb_total` — the free parameter that absorbs exactly that — is held
  fixed here. −13.7 across a 19-parameter objective is plausibly refit-recoverable; it is **not**
  a measurement that the pump is worse.

**At `ccx_default_params()` clause 3 FAILS instead (z −1.08 → −1.52), and this is not a
contradiction.** At defaults `kz` is low and the model is already *over*-depleted, so more
depletion is a loss; at the mode `kz` sits 96.6 % up its bracket and the model is *under*-depleted,
which is the miss 15c §3.3 is about. Scoring clause 3 at defaults would have returned the opposite
verdict for a reason with nothing to do with the pump. **Both are printed; they are not averaged.**

### Two scoping facts that any pump design must now answer

1. **The implied export is 22.0 GtC/yr — 2.6× the literature global POC export (5–12 GtC/yr).**
   The export needed is set by how fast the model's diffusion *destroys* the gradient, i.e. by
   `kz`, and `kz` = 5000 is **9× Ledwell's NATRE 536 m²/yr**. An effective diffusivity tuned to
   emulate 3-D advective *transport* also spuriously destroys *gradients*, so a pump inside this
   column must work several times harder than the real one does. **This is the same observation
   as the NATRE ratio, seen twice — and it is why depth-dependent `K_z` (§3.4a A) and the pump
   are complements, not alternatives.**
2. **A soft-tissue-only pump cannot fit the DIC and δ¹³C gradients at once, and this is
   arithmetic.** Mixing 244.7 µmol/kg of organic carbon at ε = −20 ‰ predicts a −2.153 ‰
   depletion against an observed −0.938 ‰: an overshoot of **2.3×**, and arm N measured **2.3×**.
   No single ε removes it. The implied two-component split (CaCO₃ at +2 ‰) is **≈45 % soft-tissue
   / 55 % carbonate** — order-of-magnitude only, since it also absorbs preformed-δ¹³C and air-sea
   disequilibrium structure a two-box contrast cannot separate. **A carbonate limb also moves
   alkalinity, which this model holds fixed at `ALK_SURFACE`** — a second structural commitment
   hiding behind the first.

### Controls and gates, because the shim is new code

- **PARITY GATE**: `dg_spinup()` (a near-verbatim copy of `ccx_spinup()` with the full-state
  Newton solve made unconditional) reproduces `ccx_spinup()` to **6.5e-07 GtC** over 96 states
  and **4.1e-08 mol/yr** on `prod_c14` with the pump off. It `stop()`s above 1e-6.
- **FRACTIONATION CONTROL (arm N0)**: with ε = 0 the deep δ¹³C does not move from +1.560 at all —
  unfractionated particles deliver surface-*enriched* carbon. Printed beside arm N so the one
  structural choice in the file is visible rather than assumed.
- The observed profile's slight mid-depth maximum (1314–1861 m is ~3 µmol/kg above the bottom)
  makes two boxes per hemisphere need a **negative** source, which is not remineralisation.
  **Reported with magnitudes (min S ≈ −0.14 GtC/yr), not smoothed away.**
- **Free validations, neither in the objective and both flagged as such:** ocean inventory
  32,827 → 36,467 GtC (canonical ~38,000) and natural ¹⁴C production 0.672 → 0.736 of canonical.

### What this does NOT settle

The C++ core does not know about the pump — every run here goes through the R reference
integrator, which is why it costs ~15 min. Porting is a *shipping* decision and this file exists
to inform it, not to pre-empt it. Nothing was refitted; the −13.7 is a fixed-parameter number.
And §3.4a's candidates A and B1 (`w_out_NH`/`w_out_SH`, already built and defaulting to 0) have
**not** been run against the same five rows — that comparison is the obvious next step and would
cost far less than the pump.

---

## 2026-08-15 (later still, part 5) — CANDIDATES A AND B1 SCORED: K(z) fixes the deep age, the outcrop fixes nothing, and the B2 gate does not fire

`calibration/diag_ocean_candidates.R` (new, ~40 min, output
`calibration/output/ocean_candidates/`). Scores DESIGN.md §3.4a's candidates **A**
(depth-dependent `K_z`) and **B1** (outcrop `w_out_*`) on the **same five rows** as the pump.
B1 needs **no new code** — it runs through the C++ core. A is a shim over `ccx_deriv()` with a
bit-exact no-op mutation gate. **No model file touched.**

### The prediction that was worth more than the scan

Derived before running: **DIC and ¹³C are conserved and have no interior source, so any steady
state of any transport operator has a uniform interior ratio.** ¹⁴C differs only because decay
*is* an interior sink. **Measured: A and B1 move the DIC gradient by 0.00e+00 µmol/kg and the
δ¹³C gradient by 2.2e-13 ‰.** Rows 4 and 5 are structurally reserved to biology. **The pump was
never in competition with A, B1 or B2** — the question is which *combination*, and the
objective cannot see two of the five rows at all.

### B1 — the outcrop FAILS, and it closes a general statement

Nine `w_out` values × three hemisphere allocations. **Every configuration moves deep Δ¹⁴C AWAY
from target, monotonically:** z +1.70 → +2.26 at the best-logL point (SH-only 0.5 m/yr,
Δ logL +0.1, i.e. noise) → +6.69 at 20 m/yr. `h_ml` does not relax.

**`kz`, `w_up` and `w_out` all buy ocean sink by moving surface water down, and all three pay
the same deep-Δ¹⁴C bill.** `w_up` was already measured this way (CHANGELOG 2026-08-13: "at
`w_up` ≥ 2 the deep age is unreachable at *any* `kz`"). The escape is not more ventilation —
it is changing its **depth distribution** (A) or adding an **interior source** (C).

### A — PASSES clause 3 decisively, FAILS clause 1

Form: `K(z) = kz·exp(−(z − h_ml)/z_K)`, anchored `f` = 1 at the ML base so `kz` keeps a
NATRE-comparable meaning; `z_K` → ∞ is the shipped model exactly.

**Compared ISO-SINK**, `kz` solved per `z_K` to carry the incumbent's ocean sink:

| `z_K` | `kz` | deep Δ¹⁴C z | Δ logL |
|---|---|---|---|
| ∞ (incumbent) | 6119 | **+1.70** | — |
| 5000 | 6404 | **−0.17** | **+0.9** |
| 3000 | 6601 | −1.76 | −1.6 |
| 2000 | 6857 | −4.21 | −10.5 |
| 1200 | 7400 | −11.15 | −68.5 |

A very gentle decay (K → 0.61·`kz` at the bottom) lands the deep **on target at an identical
sink, at slightly better logL**, with one parameter and only `kz` re-optimised. But **`h_ml`
stays at 184 m** — A does not supply what the deep mixed layer is faking. Only the pump has.

**`z_K` would be WEAKLY IDENTIFIED.** The iso-sink logL spread from `z_K` ∞ to 3000 is ~2 units
while deep Δ¹⁴C moves ~3.5σ. That is the term behaving correctly (a 1.9σ gain *is* ~1.4
log-units) — but adopting A puts real weight on the deep-Δ¹⁴C **n_eff choice
`build_glodap_deep_targets.R` left UNRESOLVED** (five sigmas spanning 15×). Resolve first.

### Marcus narrowed the pedagogy constraint, and the gate it created did NOT fire

**Marcus 2026-08-15:** added complexity is a real drawback, but *complexity forced by the
observations is its own pedagogical result*. B2 is therefore gated on **evidence**, not
parameter count. **The gate ran: candidate A reaches |z| = 0.17, so B2 is NOT indicated on the
deep-Δ¹⁴C row.** Not excluded — clause 1 is unmet by everything but the pump, and B2 is the only
untested candidate that does A and B together — but the argument that a single column *cannot*
reach the target is now measured false.

### THREE CORRECTIONS TO THIS REPO'S OWN CLAIMS, all mine, all from today

1. **"A lets C be built at a defensible export" (DESIGN §3.4a) — RETRACTED, measured false.**
   The export is set by the flux across the **top** interface, where A's shape is anchored at
   `f` = 1, so `K(z)` does not reduce it at fixed `kz`; and A's iso-sink solution wants
   `kz` = 6404 vs 6119, making the requirement *worse* (14.6 → 15.3 GtC/yr at `h_ml` = 184).
   A and C are complements for a **measured division of labour** instead: A owns clause 3,
   C owns clause 1 and rows 4–5.
2. **The "2.6× literature export" headline needed its conditioning stated.** It is a strong
   function of BOTH `kz` and `h_ml`, running **4.8–35 GtC/yr** across the plausible box, and
   inside the literature range only for `kz` ≲ 2500–3000. It is ~2.6× (22.5 GtC/yr) at the
   pump's own preferred point (`kz` 6119, `h_ml` 100), so the headline survives — but the 22.0
   first quoted was at `(5000, 75)` and agreed only by offsetting differences.
3. **A first-pass finding that "the objective prefers deep Δ¹⁴C at −9.75σ" — RETRACTED.** It
   came from a coarse `(kz, z_K)` grid in which the **incumbent sat at its own fitted
   `kz` = 6119.2 and no challenger did**. The size of that artifact is in the file's own control
   column: the *same constant-K model* at `kz` = 5000 scores **309 log-units worse**. An
   unmatched comparison measures the grid, not the candidate. Hence the iso-sink design.

### The decision block was wrong TWICE and both failures are recorded in it

- **v1** read the `z_K` = ∞ **control** as if it were candidate A, so it "passed" on the
  incumbent, and never checked clause 2.
- **v2** indexed the iso-sink winner out of the **wrong list** with an iso-sink key. R returns
  `NULL` for a missing name, `abs(NULL$z14)` is `numeric(0)`, and **`min()` silently dropped
  it** — so the rule scored B1 alone and fired the OPPOSITE way. A zero-length vector vanishing
  inside `min()` does not error; it quietly removes a candidate from the comparison. Explicit
  length assertions added.

### Gates

- **SHIM GATE**: `f` ≡ 1 is bit-exact (max|Δ| = 0.000e+00); `f` = exp(−z/1500) moves the
  derivative by 4.4e-01. Both directions asserted.
- **ENGINE GATE**: cpp and R agree to **7.5e-11** in logL and **0.00e+00** in sink, so the
  C++-scored B1 table and the R-scored A table are commensurable.
- Suite unchanged: FAIL 4 | PASS 708.

---

## 2026-08-16 — `LIK_D14C_DEEP_NEFF` MEASURED: the asserted 20 survives, the range narrows 15× → ~4×, and it lands ACROSS the decision threshold

`calibration/diag_deep_d14c_neff.R` (new, ~1 min, output
`calibration/output/deep_d14c_neff/`). Marcus 2026-08-16: measure `n_eff`, don't pick from the
five asserted candidates. **This file changes nothing** — `LIK_D14C_DEEP_NEFF` is still 20.

**The estimand, written down because the estimators answer different questions.**
`Var(x̄_w) = σ²·[ΣΣ w_i w_j ρ(d_ij)]/(Σw)²`, so `n_eff = (Σw)²/[ΣΣ w_i w_j ρ(d_ij)]`, which
collapses to Kish when ρ = δ. Measured on the **build script's own cells** (5°×10°×250 m,
cos-lat weights), gated to reproduce the shipped target exactly (Δ = 0.00e+00 on both the mean
and `sd_w`) so σ = `sd_w`/√`n_eff` is the shipped formula with a measured denominator.

### The gate caught a target-definition surprise

The shipped deep target is **everything below 2627.2 m**, not the model's 2627–3700 m box —
`build_glodap_deep_targets.R` calls `gd_binned(..., zmax = 1e5)`, so bottles *deeper than the
model's floor* are in it. Restricting to the model's actual box gives **−177.81 ‰ over 1,805
cells against the shipped −175.26 ‰, i.e. 0.25σ**. Flagged, not changed — it is a target
definition and it is Marcus'. The gate is what surfaced it; assuming the layer would have
measured `n_eff` for a different quantity.

### Results

Correlogram (no detrending — the basin gradient is *why* more Atlantic bottles don't pin the
global mean): **ρ < 0.5 by ~5,500 km, ρ < 0 by ~9,000 km**, reaching −0.37 at 15,000+ km.

| estimator | n_eff | σ (‰) |
|---|---|---|
| Kish, weights only (ρ = δ) | 3408 | 0.79 |
| correlogram ESS, empirical ρ | 110.1 | 4.37 |
| **correlogram ESS, ρ floored at 0** | **6.4** | **18.15** |
| block bootstrap, 10° | 148.5 | 3.76 |
| block bootstrap, 20° | 45.5 | 6.80 |
| block bootstrap, 30° | 26.0 | 9.00 |
| block bootstrap, 60° | 11.9 | 13.28 |
| *asserted incumbent* | *20* | *10.26* |

**The block bootstrap must be read against the decorrelation scale.** A block bootstrap is
valid only when the block exceeds it; 10° ≈ 1,100 km breaks correlation *inside* its own blocks
and is biased high, 60° ≈ 6,700 km does not. The monotone decline with block size is the
expected signature. **The 30–60° rows (12–26) are the methodologically valid ones and also the
noisiest** (33 and 16 blocks).

**The correlogram estimate is a BRACKET, not a point.** Flooring ρ at 0 moves n_eff **110 → 6.4,
a factor of 17** — the negative tail does all the work. Which end is right is a question about
the ocean, not the arithmetic: if the young-Atlantic/old-Pacific contrast is *deterministic
structure we have sampled*, the global mean is well determined and ~110 is right; if the basins
are better treated as a handful of exchangeable water masses, ~6 is. **The correlated-mean
formula is a random-field formula, and this field has large deterministic structure — which is
exactly where it stops being well posed.** Stated, not resolved.

### What it does to candidate A

A's net is +0.86 log-units at the sigma in use, of which the deep term supplies **+1.43** and
everything else **−0.57** (σ-independent). Closed form: **A is adopted for any σ < 16.30 ‰,
i.e. n_eff > 7.9.**

**The measurement brackets that threshold rather than clearing it** — defensible range ~6.4 to
~26 against a crossover at 7.9. What it *does* settle:

- **Ruled out: the full spread, σ = 45.88 (n_eff = 1)** — the only one of the five original
  candidates that rejected A. And **Kish's 3408**, which assumes an independence the correlogram
  refutes outright.
- **The asserted 20 survives**: inside the measured range, on the adopting side, and
  conservative relative to the correlogram's unfloored 110.
- Range narrows from **15× asserted to ~4× measured**.
- **Every candidate σ still HOLDS `kz`** against the −112.7 ‰ runaway (z 4.7–79.6), so the job
  the sigma was originally chosen for remains insensitive to all of this.

Leave-one-basin-out: the mean is hostage to the Pacific (44 % of weight, −211.5 ‰; dropping it
moves the global mean to −146.4). Full leave-one-out span **46.2 ‰**. That is the physical
reason n_eff is tens rather than thousands.

### Two estimators failed and are recorded rather than dropped

- **The detrended-residual variant returned n_eff = −4630.** A negative effective sample size
  is not a small n_eff, it is a broken estimator: the interpolated binned empirical ρ is not
  guaranteed positive semi-definite on a nonstationary field, and the double sum went negative.
  Now guarded and reported as UNUSABLE.
- A first version of the correlogram block printed "margin is 0.9 %, so the estimate is not a
  near-cancellation" — **wrong reasoning**: `S/(Σw)²` *is* `1/n_eff` by construction, so a small
  ratio is what a large n_eff means, not evidence about robustness. The real robustness check is
  the floored-vs-unfloored comparison, which is what replaced it.

### Still not measured, and both push σ UP

Model **representation error** (a one-box deep ocean against a field spanning −234 to −87 ‰;
`R/likelihood.R` records it as deliberately zero) and **unsampled volume** (part 5 has no
bathymetry denominator). **A measured n_eff sets a CEILING on the term's weight, not the weight
itself.** Both open questions are Marcus'.

---

## 2026-08-16 (later) — The n_eff measurement turned into a sigma: 20 is MEASUREMENT-CONSISTENT, and marginalising costs margin rather than correctness

`calibration/diag_deep_d14c_sigma_choice.R` (new, <5 s). Marcus 2026-08-16: "an n_eff median
and sigma to be used in the MCMC". That can mean two different things and they were both
built, because they are not the same answer:

- **Option 1 — a POINT sigma.** Summarise the admissible estimators, keep the Gaussian term.
- **Option 2 — MARGINALISE the sigma uncertainty.** For a scaled-inv-χ² prior on σ² the
  single-observation marginal is a **Student-t** in closed form — one line in the likelihood.

**`LIK_D14C_DEEP_NEFF` is unchanged at 20.** Its comment block in `R/likelihood.R` is rewritten
from *asserted* to *measured-consistent*, carrying the admissible set and both open questions.
That is the only edit to model code, and it changes no behaviour. Suite: FAIL 4 | PASS 708.

### The admissible set is the judgement call, so it is written down

A median over all seven estimators would be arithmetic dressed as a decision — two are
known-invalid and would drag it. Excluded with reasons: **Kish 3408** (assumes an independence
the correlogram refutes) and the **10°/20° block bootstraps** (block ≪ the ~5,500 km
decorrelation scale, biased high). Admissible: **6.4, 11.9, 26.0, 110.1**.

| summary | n_eff | σ (‰) |
|---|---|---|
| median | 18.9 | 10.54 |
| geometric mean | 21.6 | 9.87 |
| **incumbent (in use)** | **20** | **10.26** |
| conservative end | 6.4 | 18.15 |

**Every reasonable summary lands within 8 % of the asserted 20.** The value does not move:
changing 20 → 19 buys a 2.7 % σ change and costs comparability with every logL in the repo.
**The defect was provenance, and provenance is fixed by the receipt, not by moving the number.**

n_eff is known to a factor of **3.4** (1 sd on log n_eff); σ to a factor of **1.85**.

### Option 2 measured — and I expected it to fail and it does not

ν calibrated from the measured spread via Var(log σ) = trigamma(ν/2)/4 → **ν = 2.12**, scale
9.87 ‰. Near-Cauchy, which is what a 17× bracket on σ actually implies.

| deviation | Gaussian | Student-t |
|---|---|---|
| **kz runaway, 62.6 ‰** | **20.08** | **4.67** |
| 30 ‰ | 4.62 | 2.62 |
| 50 ‰ | 12.83 | 4.02 |

Against the build script's own "HOLDS `kz`" threshold (z > 3 = 4.50 log-units), **the Student-t
still HOLDS, at 4.67.** I had expected it to break the term's founding purpose; it does not.
What it does is cut the runaway penalty **4.3×**, leaving a **4 % margin where there was a 4×
one**. So the objection to option 2 is not that it fails — it is that **under option 2 this term
could never replace the `kz` bracket**, which would then stay load-bearing indefinitely.
*(Caveat: scoring a t against a Gaussian-derived threshold is like-for-like only in the
operational sense of log-units paid, not as a tail probability.)*

Option 2 also changes nothing about candidate A (net **+0.82**, still adopted). It shrinks A's
gain and the runaway penalty together — **a term that says less about everything**, not a thumb
on the scale.

| option | σ | A net logL | adopted? |
|---|---|---|---|
| option 1, median | 10.54 | +0.79 | yes |
| option 1, geometric mean | 9.87 | +0.98 | yes |
| option 1, incumbent | 10.26 | +0.86 | yes |
| **option 1, conservative end** | **18.15** | **−0.11** | **no** |
| option 2, Student-t | 9.87 | +0.82 | yes |

### Recommendation and what stays open

**Option 1 at the incumbent 20, re-documented as measured** — which is what was applied. Option
2 is the better-posed error model and is a real alternative; the trade is *honest error model*
vs *ability to retire the `kz` bracket*, and it is not mine to make.

Still Marcus': **(1) representation error, still zero** — it adds in quadrature and at the
conservative end (σ 18.15) candidate A stops being adopted, so this constant is now load-bearing
on a structural decision in a way it was not when it was chosen; **(2)** whether candidate A's
`kz` = 6404 outside the [3830, 6200] bracket is a blocker or a re-derivation — and note the
coupling, since option 2 makes that question *harder* by removing the term's ability to stand in
for the bracket.

---

## 2026-08-16 (later still) — MARCUS: the DIC and δ¹³C gradient terms go into the next round

Decision taken. Design, traps and ordering consequence in
`notes/handoff_2026-08-16_candidates_neff_and_gradient_terms.md` §4. Nothing implemented yet —
two sub-decisions block it (below).

**Why it is the right call.** Two of the five discriminating rows were not in the objective, and
they are the two only a pump can move. The refit could therefore never arbitrate the pump *no
matter how long it ran*, and `diag_dic_gradient.R`'s pump had zero fitted parameters precisely
because there was nothing to fit them against. **These terms are what make a fittable pump
possible.** Sanctioned direction: the architecture review's rule is add missing constraints,
not reweight existing ones.

**Their leverage on the current 19 parameters is EXACTLY ZERO — measured, not assumed.**
Perturbing each of `beta_max, fert_k, q10, k_w, h_ml, kz, tau_ex, npp_frac_NH, seas_amp_*,
gamma_enso, sst_scale` by 10 % moves the deep-box DIC and δ¹³C by ≤ **5.3e-12**. Baseline deep
DIC **1996.2555 µmol/kg**, deep δ¹³C **1.55953 ‰**, both parameter-independent (ML value set by
carbonate equilibrium at fixed `ALK_SURFACE` and SST; interior uniform by conservation).
Consequences: **no posterior distortion and no parameter hijacking**; logL shifts by a constant
**~384 log-units** (deep DIC z −23.0, penalty 264; deep δ¹³C z +15.5, penalty 120) and becomes
incomparable with every prior run; and **the zero-leverage property must be GATED**, because the
pump breaks it on purpose.

**The ordering conclusion that follows:** the terms are unfittable until a pump exists, so
**add the terms AND build the pump in the same round, then refit once against the complete
objective.** Terms-first is harmless but useless; pump-first fits the pump against an objective
blind to its two signature rows — the exact failure the terms are being added to prevent.

**GRADIENTS, not levels, and δ¹³C is the reason.** The model's surface DIC is *right*
(1986.3 vs a GLODAP 0–75 m mean of 2028.9 modern ≈ 1979 preindustrial), so level and gradient
are ~7 µmol/kg apart there. But the model's uniform ocean δ¹³C is **+1.560 ‰** against a
preindustrial surface nearer **+2.0 ‰** — a ~0.4 ‰ *level* offset owed to air–sea fractionation
constants and the preindustrial atmospheric value, nothing to do with the pump. A level term
would conflate that with the pump signal; a gradient term is immune.

**THE TRAP, unresolved:** the observed surface is anthropogenically contaminated in both fields
(~+50 µmol/kg Cant; Suess-depleted δ¹³C), so the raw modern gradients — **+244.7 µmol/kg** and
**−0.938 ‰** — are LOWER BOUNDS and bias *against* the pump. Three options: raw-and-documented;
corrected (**`data-raw/downloads/eide2017_c13_suess_effect.nc` is already in the repo** and is
exactly the δ¹³C correction; DIC needs a Cant estimate we do not carry); or score the transient
2010s gradient against the modern observation. **Target definition, Marcus'.**

**Two sub-decisions block implementation:** the target definition above, and per-field `n_eff`
(measured for Δ¹⁴C, not for DIC/δ¹³C; `sd_w` is 53.9 µmol/kg and 0.327 ‰;
`diag_deep_d14c_neff.R` generalises with a field argument, ~1 min).

**Also noted:** the existing deep-Δ¹⁴C target is *everything below 2627.2 m*, not the model's
2627–3700 m box (`zmax = 1e5` in the build script). Restricting to the model's actual box moves
it −175.26 → −177.81 ‰, i.e. 0.25σ. The new terms should not inherit that inconsistency without
a decision.

Handoff written; ordering table amended (item 12 = the terms, item 11 = outcrop, DEAD).

## 2026-08-16 (evening) — §6's two blockers MEASURED: the gradient target is not one number, and the contrast's σ is not the levels' σ

`calibration/diag_gradient_target_and_neff.R` (~25 s). Answers handoff §6 decisions 1 and 2.
**Nothing shipped; both decisions remain Marcus'.** Full tables in DESIGN.md §5.2a.

**Two gates first, both PASS.** (A) the cells reproduce all six shipped targets
(3 fields × 2 layers) to 0.00e+00; (B) Δ¹⁴C run through the *generalised* code path
reproduces `diag_deep_d14c_neff.R` exactly (Kish 3408.2032, correlogram 110.0893,
ρ-floored 6.3904, all |d| = 0). So the generalisation is a regression test on itself, and
the Δ¹⁴C rows below are a control, not a new result.

**DECISION 1 — the repo already carries TWO gradient targets and they differ by ~1σ.**
Handoff §4.4's +244.7 µmol/kg / −0.938 ‰ come from the model's own boxes **at `h_ml` = 75**
(the *default*); the shipped `obs_glodap_deep.rds` gives **+233.11 / −0.8610** on fixed
depths (0–100 m / >2627.2 m). Tracked down and reproduced exactly, so this is a layer
choice, not a discrepancy.

**And a hazard that was not visible before: a model-anchored target is a FUNCTION OF `h_ml`.**
`ccx_ocean_grid()` puts the ML box at 0–`h_ml`, so the observed gradient reads
+244.7 (h_ml 75) → +235.0 (100) → **+212.8 (184, the FITTED value)**. It moves
**+22.2 µmol/kg** as `h_ml` falls 184 → 100 — *exactly* the move the pump makes (15d).
See the correction appended below: my first statement of this hazard's DIRECTION was wrong.

**DECISION 2 — the estimand is a CONTRAST, and I predicted its covariance sign WRONG.**
Var(Δ) = Var(D) + Var(S) − 2 Cov(D,S). I argued in the file header, *before measuring*, that
the two layers share cruises so a sampling excursion biases both the same way and **cancels**,
i.e. that ignoring the covariance would make the terms weaker than the data warrant.
**Measured, by two estimators sharing no machinery — block bootstrap on the contrast, and
a paired-column correlation on the raw field — and they AGREE on the sign for all three
fields:**

| field | corr(surf, deep) | effect on σ_Δ | σ_Δ (blocks ≥30°) | deep-LEVEL n_eff |
|---|---|---|---|---|
| DIC | **−0.38 to −0.60** | **INFLATES ~25 %** | **19.8 – 25.3 µmol/kg** | 10.2 – 23.3 |
| δ¹³C | +0.09 to +0.12 | cancels ~4–8 % | 0.075 – 0.115 ‰ | 10.2 – 23.5 |
| Δ¹⁴C (control) | ≈ 0 | none | 11.9 – 15.0 ‰ | 11.7 – 25.8 |

For DIC — the field that matters most — the naive independent-layer calculation would have
made the term **~25 % STRONGER** than the data warrant, the opposite of what I claimed.
**Mechanism (and it is the same physics as the deep-Δ¹⁴C correlogram's negative tail, read on
a different pair of layers):** surface DIC is highest where the water is cold and dense — the
high latitudes — and that is precisely where the deep water is *youngest* and lowest in
respired carbon. Basins trade the two ends of the gradient against each other, so a
basin-skewed sample misses the **gradient** by more than it misses either **level**.

**§4.6's worry does NOT bite for the LEVEL terms.** It asked whether `n_eff` = 20, measured
for Δ¹⁴C, transfers to DIC and δ¹³C. It does: deep-level `n_eff` is 10.2–23.3 (DIC),
10.2–23.5 (δ¹³C), 11.7–25.8 (Δ¹⁴C) — **20 sits inside the bracket for all three.** The fields
do have their own spatial structure and it does not move `n_eff` enough to matter. The worry
bites only for the **contrast**.

**§4.2's ~384-log-unit constant does not reproduce, twice over.** (a) It is a *level*
formulation; **gradient** terms on the shipped layers cost **71–136 log-units**, because the
contrast's σ is larger than a level's. (b) Its model baseline (deep DIC 1996.2555 µmol/kg)
does not reproduce — the default spinup gives a column uniform at **1986.3340** (NH) /
**2003.7207** (SH). Recomputed live here rather than copied. The zero-leverage result itself
is confirmed and sharpened: the interior is uniform to **machine precision** in both
hemispheres, so **the gradient IS the miss, in full.**

**Caveat carried, not buried:** the bootstrap SE has **not plateaued** in block size
(30° → 60° still rising), so σ_Δ is a range, not a point. The 60° row is the most defensible
and the noisiest (16 blocks); that tension is unresolved.

**Written:** `calibration/output/gradient_target_neff/diag_gradient_target_and_neff.{rds,log}`,
DESIGN.md §5.2a. No model file and no likelihood constant changed.

## 2026-08-16 (evening, correction) — the h_ml-anchoring hazard runs the OTHER WAY, and freezing is not free either

Marcus asked whether freezing the target at the `h_ml` = 75 grid has drawbacks. Pricing it
did — and it caught a **directional claim of mine that was wrong**, made earlier the same
evening in this CHANGELOG, DESIGN.md §5.2a and `diag_gradient_target_and_neff.R`.

**RETRACTED:** "a model-anchored target would reward shrinking `h_ml` through the target's
motion". **MEASURED (part 2b, new):** the opposite. Pre-pump the model's gradient is **0 at
every `h_ml`** — the interior is uniform by conservation and the ML value is carbonate
equilibrium at fixed `ALK_SURFACE` and SST, which does not involve `h_ml` — so the penalty is
target²/2σ², and the target *falls* with `h_ml`. Penalty therefore falls **81 → 53 log-units**
across `h_ml` 50 → 220: **model-anchoring rewards a LARGE `h_ml` and pushes AGAINST clause 1**,
the thing the pump exists to fix. A worse hazard than the one I claimed, in the opposite
direction. I reasoned about the target's motion and never checked the sign of its effect on
the penalty.

**And freezing is not free either — its bias points the other way.** Freezing at `h_ml` = 75
overstates the miss by **1.61 σ_Δ** at the fitted `h_ml` = 184, because the model's ML box then
spans 0–184 m while the target is built on 0–75 m water. That bias is **in favour of adopting a
pump, and a stronger one** — i.e. it points at the conclusion the term exists to test.

| `h_ml` | like-for-like | frozen @75 | freezing costs (σ_Δ) | anchoring gives (log-u) |
|---|---|---|---|---|
| 75 | 244.71 | 244.71 | 0.00 | 76.2 |
| 100 *(pump)* | 234.98 | 244.71 | 0.49 | 70.3 |
| 184 *(fitted)* | 212.79 | 244.71 | **1.61** | **57.6** |
| 220 | 203.66 | 244.71 | 2.07 | 52.8 |

**Neutral on both counts:** freeze the layers at the `h_ml` the refit actually lands on —
frozen kills the feedback, matched kills the representation bias — for one iteration and a
gate on |`h_ml`_posterior − `h_ml`_target|. **Coincidence worth using:** at `h_ml` = 100, the
value the pump delivers (15d), the like-for-like target is +234.98 against the shipped rds's
**+233.11 — a mismatch of 0.09 σ_Δ**. If the pump lands `h_ml` near 100 the shipped
fixed-depth layers *are* the like-for-like choice and freeze-vs-anchor dissolves.

**MARCUS DECIDED (contamination axis):** option 3 — **score the model's transient gradient at
the observations' epoch** against the modern observation, rather than correcting the surface
for anthropogenic carbon and Suess. No C_ant product needed, which matters because the
GLODAPv2.2023 bottle master carries **no C_ant column** (checked) — option 2 would have meant a
new download or a ΔC* build for DIC, while only δ¹³C had its correction in-repo
(`eide2017_c13_suess_effect.nc`). GLODAP's cell-weighted mean sampling year is **1999.8**
(surface) / **2002.4** (deep). Implementation cost, stated honestly: `ccx_run_fast()` returns
only the **final** state, so this needs one recorded interior state at the obs epoch — a small
output-contract addition, not free, but far cheaper than a C_ant build. **Layer axis still open.**

## 2026-08-16 (night) — THE GRADIENT TERMS ARE IN THE OBJECTIVE (task 12). Both §6 decisions taken; suite back to its pre-existing 4 failures

Marcus took the layer axis on the amended recommendation: **fixed depths + an `h_ml` gate**,
rather than freezing at the `h_ml` = 75 grid, because at `h_ml` = 100 (the value the pump
delivers) fixed depths are already like-for-like to **0.09 σ_Δ** — so the gate defers the
choice to the refit instead of pre-judging it. Contamination axis: **transient at the
observations' epoch**. Details in DESIGN.md §5.2b.

**Shipped.** Streams `ocean_grad_dic` / `ocean_grad_d13c`. Targets +233.109 µmol/kg and
−0.8610 ‰ on fixed depths (0–100 m / >2627.2 m); σ_Δ 25.25 and 0.1115 from the block
bootstrap **on the contrast**; epochs 1999.8 / 2002.4 (surf / deep), measured per field *and*
per layer because the observed gradient is itself a difference of two differently-timed means.
`LIK_OCEAN_GRAD_HML_OK` = [85, 120] m; outside it both terms go **absent**, not zero.

**MARCUS' EPOCH DECISION IS MEASURABLY EQUIVALENT TO THE CORRECTION HE DECLINED**, which was
worth testing rather than assuming (part 5b). Because the model takes up anthropogenic carbon
too, the contamination cancels on *both* sides:

| route | miss (µmol/kg) | σ_Δ |
|---|---|---|
| **option 3 — transient at obs epoch (SHIPPED)** | **278.29** | **11.02** |
| option 2 — preindustrial + ~50 µmol/kg C_ant | 283.11 | 11.21 |
| option 1 — raw modern vs preindustrial model | 233.11 | 9.23 |

**0.19 σ_Δ apart.** The cheap route is not a compromise. Option 1 would have understated the
miss by **1.98 σ**, all of it in the direction that hides the pump — §4.4's trap, quantified.

**A CONSEQUENCE §4.2 DID NOT ANTICIPATE: THE TERMS ARE NO LONGER A PURE CONSTANT.** §4.2's
"leverage exactly zero ⇒ no posterior distortion and no parameter hijacking" is a property of
the **preindustrial** gradient — still 0 to machine precision for every parameter, and now
gated. But the **transient** gradient depends on anthropogenic uptake and therefore on the
ocean parameters. **Measured: ≤ 0.09 σ_Δ per 10 % perturbation** across `kz`, `h_ml`, `k_w`,
`beta_max`, `q10`, `tau_ex`, against an 11 σ miss — ~120× too weak to hijack anything, but not
zero. So §4.2's requested zero-leverage gate was re-aimed: the **exact-zero** assertion sits on
the preindustrial gradient (the property the pump breaks), and the transient gets a **bound**
(`LEV_MAX` = 0.25 σ). Asserting exact zero on the shipped quantity would have failed.

**Model cores changed, both of them.** `CCX_OCEAN_BOX_COLS` — mixed-layer and bottom-box C and
¹³C per hemisphere, raw GtC, emitted as a **time series** (the terms score the obs epoch, not
the run's end). Order is load-bearing: `ccx_run_fast()` names the C++ matrix positionally.
Parity gated to ~1e-13 with an added anti-degeneracy check, so a transposed pair cannot pass.

**logL moves by ~199 log-units** (DIC 64.9, δ¹³C 134.5 at `h_ml` = 100) and is now incomparable
with every prior run. Expected. **δ¹³C is the STRONGER term** (z +16.5 vs −11.0) and will
dominate the pump's fit — worth knowing before the refit, since the pump was designed against
the DIC row.

**A TEST FAILED AND IT WAS NOT A REGRESSION — reported rather than quietly fixed.**
`test-ocean-advection.R:152` asserted `expect_equal(as.matrix(out$out), ...)` over the WHOLE
frame, under a comment saying "the atmosphere, the land and the ocean TOTALS are tied ... the
INTERIOR is not". Those were the same set only because `out` carried no interior quantity; the
new columns broke the coincidence and the assertion began contradicting its own next line
(which asserts the deep DOES move). Measured at the split: **every pre-existing column ties to
≤ 1.5e-10, the MIXED-LAYER columns tie to ≤ 2.9e-13, and only the BOTTOM-BOX ones differ**
(deep_C_NH by 3.68 GtC). Physics untouched; the assertion's scope was wrong. Re-scoped, and
**strengthened** — the mixed-layer tie is now asserted explicitly, which is the test's own
mechanism claim ("air-sea acts at `iml` and nowhere else") measured directly rather than
inferred from totals that could tie by cancellation, and the bottom-box columns are now
asserted to DIFFER.

**Suite: 4 failing, 746 passing** (was 4 failing, 737 passing). The four are the pre-existing
ones, unchanged and unflagged.

**Gate C added** to `diag_gradient_target_and_neff.R`: the diagnostic now checks itself against
the shipped build product — targets exact, σ within a 3 % Monte Carlo tolerance (gating a
bootstrap SE on equality would test RNG call order, not the estimator).

**NOT DONE, and it is the other half of the round:** the pump. Handoff §4.5's ordering
conclusion is terms + pump in the SAME round, then one refit. The terms are the harmless half;
**the refit still waits for the pump.**

---

## 2026-08-16 (later, night) — §6 item 2 ANSWERED: the DIC pump does NOT close δ¹³C, but it misses by a hair — and the *preindustrial* arithmetic that says otherwise is a trap

`calibration/diag_pump_vs_gradient_terms.R` (new, ~3.5 min), `calibration/pump_shim.R` (new,
extraction), output in `calibration/output/pump_vs_gradient/`. Handoff `2026-08-16b` §6 item 2:
the pump was designed against the DIC row, δ¹³C is now the **stronger** term, and nobody had
checked whether the pump that closes one closes the other. **Scored through the SHIPPED
streams** — `ccx_ocean_grad_scored()` + `ccx_loglik(ocean_grad = )`, i.e. the transient
gradient at the observations' epoch on fixed depths at the block-bootstrap σ. These numbers are
**not** comparable with `diag_dic_gradient.R` part 3's, which scored the spinup's bottom box
against a preindustrial target under the old `n_eff` = 20 convention.

At the pre-gradient MAP mode's parameters with `h_ml` forced to 100 m (inside the gate; asserted
before anything runs), nothing refitted:

| arm | export GtC/yr | z_DIC | z_δ¹³C | z_deep¹⁴C | Δ logL |
|---|---|---|---|---|---|
| pump OFF | 0 | **−11.10** | **+16.84** | +1.48 | 0 |
| soft-tissue, ε = −20, sized to the observed gradient | 25.2 | **−1.87** | **−2.42** | +1.08 | **+245.9** |
| ε = −8.40 (the preindustrial arithmetic's answer) | 25.2 | −1.87 | **+8.47** | +1.08 | +213.0 |
| ε = 0 (control) | 25.2 | −1.87 | +16.36 | +1.08 | +115.2 |
| **ε\* = −14.55, g\* = 1.2021 (solved to close both)** | 30.3 | **+0.00** | **+0.19** | +1.00 | **+252.3** |

**VERDICT: NO — and the failure is a FRACTIONATION failure, not a size failure.** The DIC row
demands the export field × **1.202**; the δ¹³C row demands × **0.874**. They are **1.37× apart**,
so no single export scale closes both, and 1.37 = 20 / 14.55 is exactly the fractionation gap.

**But the gap is far smaller than the observed pair implies, and that is the finding.** The
effective fractionation the *observed* pair (+233.109 µmol/kg, −0.8610 ‰, deep DIC 2273.1)
implies is **−8.40 ‰** — a 2.38× overshoot against soft-tissue's −20, i.e. 56 % carbonate limb.
Under the shipped **transient** scoring the demand is **−14.55 ‰**, a **74 % soft-tissue share**.
The reason is that the pump-OFF model does not start at zero gradient at the obs epoch: the
mixed layer carries anthropogenic carbon and the Suess depletion the bottom box has not seen, so
the pump must supply **+280.2 µmol/kg and −1.8777 ‰** rather than the observed +233.1 / −0.861 —
and that ratio is not the observed ratio. **An arm built on the preindustrial arithmetic
(ε = −8.40) is 105.9 log-units WORSE on `ocean_grad_d13c` than plain soft-tissue.** Designing
the pump's fractionation from the observed pair alone would have got it badly wrong; this is the
same trap as §4.4's, one field over.

**Pre-registration scored.** Prediction 1 (naive, preindustrial: δ¹³C overshoots to z ≈ −10.7)
**WRONG**, as the header expected — and its wrongness is the trap above. Prediction 2 (transient:
both rows near −2 σ, g\* ≈ 1.19, ε\* ≈ −15) **RIGHT** — measured −1.87 / −2.42, 1.202, −14.55.
Pump-OFF rows reproduce handoff §2's quoted −11.0 / +16.5 to −11.10 / +16.84.

**A verdict-logic error I wrote, caught by the run itself, kept visible in the file.** I first
classified the failure by comparing the **signs of the two z**. Both came out negative, which the
sign test read as "same-sign miss, one export scale fixes both" — the **opposite** of the truth.
Equal signs of z are opposite corrections here: the DIC target is positive (z < 0 = pump too
**small**) while the δ¹³C target is negative (z < 0 = **too much** depletion). Replaced with the
test that actually answers the question — what scale does each row demand of the same field —
and the trap is documented in the file rather than edited away.

**An unasked-for result, flagged and NOT banked: nutrient-limited vs DIC-limited is not a free
choice.** Same ε, same export field, mode **D** gains **+441.3** against mode **N**'s +245.9, and
the whole **+195.4** difference is the CO₂ record (`co2_level_SPO` +107.3, `co2_level_MLO` +93.6,
`co2_icecore` −9.1); sink 2.913 → 3.051 GtC/yr. **The two gradient rows cannot tell N from D —
they move identically.** A refit has `beta_max` and `kz` free and could reallocate all of it, so
this is not evidence for D; it does mean the N/D choice must be made deliberately in the port
(task 9) rather than inherited from the shim.

**Clause 3 reproduces, including its sign flip.** At the mode the pump moves deep Δ¹⁴C **toward**
the target (z +1.48 → +1.08, and +1.00 at ε\*/g\*); at defaults it moves **away** (−1.01 → −1.42).
Same operating-point dependence `diag_dic_gradient.R` part 6 documented.

**The export required is a statement about `kz`, and a large one.** 20.6 GtC/yr at defaults
(`kz` 5000) vs 25.2 at the mode (`kz` 6119), and **30.3** for the arm that closes both — **3.6×**
the 5–12 GtC/yr literature POC midpoint. A 1-D effective `kz` standing in for 3-D ventilation
also destroys gradients, so the pump must work that much harder than the real one. **Do not quote
the required export as an estimate of real POC export.**

**Refactor, with a bit-identical regression check.** The shim, `dg_export_field()`, `dg_spinup()`,
`dg_parity_gate()` and the GLODAP profile helpers moved from `diag_dic_gradient.R` into
`calibration/pump_shim.R` so the two diagnostics cannot drift apart; the only added code is a
double-source guard (sourcing twice would otherwise capture the already-wrapped `ccx_deriv()` and
recurse). `diag_dic_gradient.R` re-run end-to-end afterwards: `all.equal()` against the saved
pre-refactor `.rds` is **TRUE** across all five arms and the `h_ml` profile.

**Still NOT done: the pump itself (task 9).** This measures a shim through the R reference core;
the C++ core still knows nothing about it, and the refit (task 8) still waits.

---

## 2026-08-16 (later still) — "Should we stop holding alkalinity fixed?" — NO, and the reason is that GLODAP's alkalinity gradient does the job without freeing anything

`calibration/diag_alk_gradient.R` (new, ~2 min first run, seconds after the subset caches),
output in `calibration/output/alk_gradient/`. Marcus' reply to the pump-form question.

**Two questions, different answers, plus the thing that turned out to matter.**

**Q1 — is a carbonate limb blocked by fixed alkalinity? NO, and my own DESIGN §5.2c line saying
otherwise is CORRECTED there.** Checked by grep rather than recalled: `ALK_SURFACE` enters the
**mixed-layer carbonate solve and nowhere else**; the interior has no alkalinity and no carbonate
chemistry. A carbonate limb is a second export field with its own δ¹³C signature, received by
the interior as passive tracer exactly like the soft-tissue limb. Nothing needs freeing.

**Q2 — would an alkalinity tracer change uptake? Barely, and because the model is already
right.** `ALK_SURFACE` = 2300 µmol/kg against GLODAP's **2303.4** on the shipped 0–100 m layer.
A tracer cannot improve the present-day level; it can only let the modelled surface value
*drift*, and alkalinity is near-conserved on this timescale. Priced: **d(Revelle)/d(ALK) =
−0.0005 per µmol/kg**, so 10 µmol/kg of drift moves the buffer factor **0.05 %**. Not competitive
with `h_ml`, which handoff 15c argues is faking uptake at the ~150 m level.

**THE PRIZE, which nobody had looked at: `G2talk` is in the 894 MB GLODAP master this repo
already downloaded.** Extracted on the shipped fixed depths with the same cos(lat) cell
weighting: **2303.4 µmol/kg (0–100 m, 829 cells) and 2382.3 (>2627.2 m, 5886 cells), gradient
+79.0**. With ΔALK = 2·C_carb − (N:C)·C_org at N:C = 16/117, that is a **20–22 % carbonate
share** — against 26 % from the transient δ¹³C demand and **56 %** from the preindustrial
arithmetic.

**It adjudicates transient-vs-preindustrial from an observation that was not used to decide it.**
Alkalinity carries no Suess signal and essentially no C_ant, so the contamination that trapped
the δ¹³C arithmetic does not bite. Fix the split by ALK, the fractionation by ε_org = −20, and
the δ¹³C gradient is a **prediction with nothing left to tune**:

| scoring | predicted δ¹³C | required | ratio |
|---|---|---|---|
| preindustrial (D = observed +233.1) | −1.578 ‰ | −0.861 | **1.83** |
| **transient (D = the model's +280.2)** | **−1.965 ‰** | **−1.878** | **1.05** |

**Three independent GLODAP gradients are mutually consistent only under the transient scoring.**
Independent corroboration of Marcus' 2026-08-16 epoch decision.

**CONSEQUENCE FOR TASK 9, and it inverts what I recommended an hour earlier: the TWO-LIMB pump
is now the CHEAP option.** The split is pinned by an observation, ε_org stays at the canonical
−20, and the effective-ε stand-in (−14.55, which sits outside the −20 to −22 range and hides the
carbonate limb) is no longer needed. Zero fitted parameters either way.

**NOT done, and required before this could ever be a likelihood term:** the ALK gradient's σ has
not been block-bootstrapped **on the contrast**. The cell spread is reported instead and labelled
as such. DIC's cross-layer covariance inflated its σ_Δ 25 %, so composing σ any other way is a
known error of that size.

---

## 2026-08-16 (night) — The ALKALINITY gradient is the FOURTH likelihood term (`ocean_grad_alk`), and its model side is a steady-state solve rather than a fourth tracer

Marcus: make it a term unless there is a good reason not to. There was not one, but there was
a design fork and a population hazard, both measured rather than assumed.

**THE TARGET, built the same way the other two were** (`data-raw/build_glodap_deep_targets.R`,
new block; `G2talk` extracted from the master into `glodap_dic_talk_subset.csv`, 464,590 usable
bottles):

| | value |
|---|---|
| target | **+78.5927 µmol/kg** (0–100 m vs >2627.2 m, fixed depths) |
| σ | **19.199** — block bootstrap **on the contrast**, 4000 draws, seed 20260816, conservative of the two valid block sizes (30° gives 13.879) |
| epochs | 2002.4 surf / 2002.5 deep (recorded for provenance; alkalinity has no transient) |
| **miss with no pump** | **4.09 σ, −12.25 log-units** |

**Every pre-existing field of `obs_glodap_deep.rds` is bit-identical** (`all.equal(tolerance = 0)`
against the pre-build copy). `gd_grad_boot()` re-seeds per call, so the new bootstrap cannot
perturb the shipped ones.

**THE POPULATION HAZARD, measured because the first report mixed two samples.** The shipped DIC
target comes from the isotope subset ("bottles carrying δ¹³C or Δ¹⁴C", 2897/533 cells);
alkalinity is measured on far more bottles (5886/829). Forming the carbonate share as
ALK-gradient ÷ DIC-gradient across the two compares different samples of the ocean. Recomputed
the DIC gradient **on the alkalinity population**: **+225.81 vs the shipped +233.11**, a
**−0.29 σ** move, and the carbonate share goes **22 % → 23 %**. Immaterial — but it is now
measured, and `gradient$tco2_alkpop` is stored for it. **The shipped DIC target is unchanged.**

**THE MODEL SIDE IS THE INTERESTING DECISION, and it is NOT a fourth tracer.** Alkalinity in
this model has **no air-sea flux, no decay, no anthropogenic source** — so unlike DIC it has **no
transient**, and its profile is fully determined at every date by the export field. A state
column would carry the same information at the cost of the state, the C++ core, the Newton
spinup and the parity tests. Shipped instead:

- `ccx_steady_profile_from_source()` — source field → the profile it holds, **the exact inverse
  of `dg_export_field()`**. That inverse relationship is what makes the row testable *before a
  pump exists*: a round-trip test composes the two and must return the profile it started from.
- `ccx_model_ocean_alk_gradient(spin, pump = NULL)` — **returns exactly 0 today, for every
  parameter, and that is a model PREDICTION, not a placeholder**: `ALK_SURFACE` enters the
  mixed-layer carbonate solve and nowhere else, so with no carbonate pump nothing can separate
  the two layers. Pass the pump's per-limb export fields when task 9 ships one and the row goes
  live with no other change.
- Stoichiometry as named constants: `LIK_ALK_PER_CARB` = 2 (CaCO₃ dissolution),
  `LIK_ALK_NC_RATIO` = 16/117 (nitrate release). Working values, not fitted, not cited.

**HOW THIS ROW DIFFERS FROM THE OTHER TWO, stated in the code so it cannot be misread.** DIC and
δ¹³C are state variables whose gradients already move (transient leverage ≤ 0.09 σ). The
alkalinity row is a **literal constant with zero leverage** until a carbonate pump exists. It is
shipped anyway for the reason the DIC row was shipped before the pump — the constraint has to be
in the objective for the pump to be scored against it — and the code says **do not quote it as
evidence about anything** until it is given a pump.

**+4 test blocks** (`test-likelihood.R`): the Gaussian and absence contract; **the exact-zero
assertion across h_ml × kz**, which is the property a carbonate pump breaks on purpose; the
round-trip solver test; and a **hand-built pump** that must move the row by the stoichiometry —
a pure organic limb NEGATIVE at −(N:C)×, a pure carbonate limb at exactly +2×.

**A latent bug the new row exposed in the row I shipped this morning.** The term loop used
`is.finite(ocean_grad[[field]])`, and every caller written before today passes an `ocean_grad`
with no `alk` element — `is.finite(NULL)` is `logical(0)`, which is an **error** in `if`, not
FALSE. Guarded with `length(v) == 1L`, which also keeps the absence contract: a row the caller
does not supply is **absent**, not zero.

**logL moves by another −12.25 log-units** and is again incomparable with runs before tonight.

---

## 2026-08-16 (night, later) — TASK 9: the pump is PORTED into both cores, OFF by default — and the port caught a 15 % sampling bias in the shim's export

Marcus: start the port. It is in `R/model.R` + `src/ccx_core.cpp`, not a shim over `ccx_deriv()`.

**OFF BY DEFAULT, AND OFF MEANS BIT-REPRODUCED.** `pump_grad = 0` → `aux$pump` is NULL → not one
line of pump code runs. Same contract `w_up = 0` has carried since 2026-08-13, and the whole
suite is the gate: **4 failing / 858 passing**, the same pre-existing four (was 4 / 767).

| parameter | default | what it is |
|---|---|---|
| `pump_grad` | **0** | preindustrial bottom-minus-ML DIC gradient held, µmol/kg |
| `pump_carb_frac` | **0.23** | carbonate share, **pinned by the alkalinity gradient**, not fitted |
| `pump_mode` | `"N"` | nutrient- vs DIC-limited; **both ported, choice deferred to the refit** |

**Still zero fitted parameters in the export field.** It is solved as the source that makes
GLODAP's observed DIC shape an exact steady state of the model's own diffusion operator. The
shape moved into a build product (`dic_profile`, fixed bins, 25 m near the surface) and is
integrated onto whatever layers a draw asks for — re-binning 50,634 bottles per likelihood
evaluation was never an option. `pump_grad` is **re-normalised on each grid's own layers**, so it
delivers exactly the gradient it names (without that step 233.109 landed at 235.7).

**Emitted through `add_flux()` rather than by touching `dy`** — conservative by the same
construction as every other flux, isotopes at the source ratio, and it appears in the flux trace
as its own `pump` channel. The shim could do none of this and errored under `record = TRUE`.

**Verified**: R↔C++ parity **~1e-15** in both modes; spinup still an exact fixed point (the Newton
branch now fires on the pump as well as the conveyor); `pump_grad` delivered exactly across
`h_ml` ∈ {85, 100, 120} × three magnitudes; and the pre-registered **zero-uptake property** of a
constant-mass pump is now a standing test rather than a diagnostic's one-off finding.

**THE PORT CAUGHT A REAL BIAS IN THE SHIM, and my first diagnosis of it was WRONG.** Port parity
(`calibration/diag_pump_port_parity.R`) agrees to **0.66 % on every row the likelihood scores**
(DIC 0.00 %, δ¹³C 0.66 %, deep Δ¹⁴C 0.23 %) but the **export** disagreed by 28 %. I assumed the
fixed-bin profile was too coarse near the surface and refined it — 250 m → 50 m → 25 m moved the
disagreement **28 % → 8.8 % → 15.2 %**, *not* monotonically toward the shim, which is what said
the diagnosis was wrong rather than under-resolved.

**Measured cause.** Total export is the diffusive flux across the topmost interface alone (the sum
telescopes), so it is set by the **mixed layer's mean DIC**. The shim's `dg_bin()` assigns cells by
`floor(depth/250)`, so all of 0–100 m is **one cell** and its mean is weighted by **bottle
density** — and GLODAP over-samples the shallowest water, where DIC rises fastest (25 m sub-bin
means run 2017.7 → 2083.9 across 0–100 m). The shim's ML is therefore **10.04 µmol/kg too low**
(2038.29 vs a thickness-weighted **2048.33**), its ML-to-box-1 gradient too steep, and its
required export **~15 % too high**. A model mixed layer is a well-mixed slab, so the
thickness-weighted value is correct and the **port is the better estimator, not the deviant one**.

**CONSEQUENCE — numbers reported earlier today are corrected.** The shim's export figures (20.6
GtC/yr at defaults, 25.2 at the pre-gradient mode, 30.3 at g\*) are high by ~15 %; at defaults the
port gives **17.4**, and the literature-POC ratio is nearer **3.1×** than the 3.6× quoted in
DESIGN §5.2c. The mode and g\* figures have not been re-measured. **No row the likelihood scores
is affected** — those agree to 0.66 %.

**As shipped** (`pump_grad` 233.109, h_ml 100, 23 % carbonate): z_DIC −1.79, z_δ¹³C **+2.02**,
z_ALK **+0.21**. The carbonate limb is doing its job — the same DIC gradient costs δ¹³C −0.636
against the single limb's −1.132. **The alkalinity row is no longer a constant**: it is read off
`spin$aux$pump`, the same field the derivative integrated, so it cannot be scored against a pump
the run did not use.

**Two test-infrastructure fixes made along the way.** `skip_if_no_cpp()` was defined in
`test-climate.R`, so it existed only for files testthat happened to run *after* that one and
`test_file()` on any other file failed outright — moved to `setup.R`. And the provisional-constants
**ledger** in `test-constants.R` failed on the two new fractionations, which is the ledger doing
its job; updated deliberately.

**One test of mine was wrong twice, both kept visible.** I asserted mode N and mode D differ at
the preindustrial state — they are **identical** there, because the mixed layer holds exactly
`ml_C0` and the DIC-limited scaling is 1; they diverge only once it is loaded, which is the
mechanism. And the corrected version asserted equality to 1e-14 when the Newton spinup lands the
ML on `ml_C0` to ~1e-7 GtC, making the scaling 1 + O(1e-11). Both now assert what is actually true.

**NOT DONE:** the refit (task 8). And `pump_grad`'s value is still a DESIGN decision, not a
default's to make — the observed gradient is 233.1, the transient rows want ~1.20× that.

---

## 2026-08-16d — the `pump_grad` profile: the four-row objective wants ~1.18× the observed gradient, and all three ocean rows close at once

`calibration/diag_pump_grad_profile.R` (NEW, ~9 min), `DESIGN.md` §5.2g. Handoff 16c §7 item 1 is
the decision "what should `pump_grad` be, and is it fitted?" — **this file measures the profile the
decision needs and does not take the decision. `pump_grad` is still 0 in `R/model.R`.**

**THE HEADLINE.** At the quarantined pre-gradient mode with `h_ml` forced to 100 (the same
operating point as `diag_pump_vs_gradient_terms.R`, which is what makes them comparable), the full
objective puts `pump_grad` at **274.5 ± 13.1 µmol/kg** — **1.178 ± 0.056 × the observed 233.109** —
and the three ocean rows on their own put it at **271.3 ± 14.3**. At the best grid arm (280) **all
three rows close simultaneously**: z_DIC −0.01, z_δ¹³C −0.42, z_ALK +1.08, deep Δ¹⁴C +1.04, with
**zero fitted parameters in the export field**.

**THE FRACTIONATION GAP IS CLOSED BY THE CARBONATE LIMB, AS DESIGNED.** The shim's DIC and δ¹³C
rows wanted export scales **1.37× apart** (= 20/14.55, the fractionation gap — that is why 16b §2
called the failure structural rather than a size error). With two limbs at the pinned 23 % share
the effective ε is −15.2 ‰ and the gap is **1.03×**: DIC demands 1.202×, δ¹³C 1.168×. **ALK is now
the dissenting row at 0.951×**, and it dissents inside its own σ — it is the loosest of the three
(σ = 54.1 in `pump_grad`, against δ¹³C's 18.4).

**+259.4 log-units from OFF, of which +48.2 is rows the pump was never built against**:
`d14c_NH` +25.0, `d14c_SH` +13.9, `d13c_level_MLO` +4.4, `d13c_level_SPO` +3.5 (the gradient rows
are +211.2 of the total). **The margin is an UPPER BOUND, not a verdict** — every arm including OFF
sits at the same unrefitted mode, so the no-pump incumbent never gets the refit that `beta_max`,
`kz` and `h_ml` would give it. This is the iso-observable-slice discipline the ocean-candidate
round cost 309 log-units to learn: read the *shape* and the per-row scales, not the margin.

**THE PINNED CARBONATE SHARE CHECKS OUT INDEPENDENTLY.** Scanning `pump_carb_frac` at fixed
`pump_grad` = 280 gives a quadratic vertex of **0.214 ± 0.026** against the **0.23** that GLODAP's
alkalinity gradient pinned — **0.61 σ**. The transient likelihood and the observed ALK/DIC
stoichiometry agree about the split, arriving from opposite directions. Not a licence to fit it.

**A GATE OF MINE WAS WRONG AND IS FIXED THE RIGHT WAY, NOT THE CONVENIENT WAY.** The zero-uptake
gate was written on logL at 1e−6 log-units — **tighter than the spinup's own convergence** — and
duly reported FAIL at 2.16e−6. Loosening the threshold until it passed would have been the
explaining-away move. Instead the gate now reads the **physical** quantity: max |ΔCO₂(2024)| across
the whole scan is **2.24e−08 ppm**, six orders inside any meaningful leak, and the logL footprint
is printed as context rather than as the test. **PASS.** Second estimator bug caught the same way:
the δ¹³C row is a *ratio* and departs 4.6 % from linear, so a line through the endpoint arms put
its demand at 287.8 against the bracketing pair's **272.3** — a 6 % error, larger than the
row-to-row disagreement the part exists to measure. Both DIC and ALK are exactly linear
(3.2e−11, 2.0e−16), which is what a fixed source under linear transport must be.

**PREDICTIONS.** All four pre-registered predictions held: P1 zero uptake, P2 linearity, P3 the
per-row scales (predicted DIC ~1.19, δ¹³C ~1.15, ALK the dissenter at ~0.95; measured 1.202,
1.168, 0.951), P4 identifiability (predicted σ 15–25, measured 13.1).

**NOT DONE / DELIBERATELY NOT TAKEN:** whether `pump_grad` is fixed or fitted; whether the pump
ships ON; N vs D (not scanned here — the gradient rows cannot tell them apart, so a D column would
duplicate these rows while re-opening a question already deferred to the refit); the refit itself.

---

## 2026-08-16e — `pump_grad` × `kz` is NOT degenerate; the pump-ON decision is taken, its wiring is staged, and 7 tests block it

`calibration/diag_pump_kz_degeneracy.R` (NEW, ~15 min), `DESIGN.md` §5.2h.

**THE PREREQUISITE, PASSED.** §5.2g profiled `pump_grad` with all 19 parameters held — the
condition under which a new parameter always looks best. Over the whole `kz` bracket [3830, 6200]:
**ρ = −0.167**, and `pump_grad`'s marginal σ is **1.01×** its conditional σ (13.0 vs 12.8). Fitting
it buys a direction `kz` cannot supply, exactly as the structural result (transport cannot move the
DIC/δ¹³C gradients) predicts. At `kz` = 6200 — where the posterior actually sits — the optimum is
**270.7**, within **1.4 %** of the 1-D profile's 274.5.

**TWO INTERNAL CHECKS FELL OUT FREE.** `ocean_grad_alk` is *exactly* `kz`-independent across every
column (it reads the export field alone), and the ocean sink is identical down every pump column at
fixed `kz` — the zero-uptake property holding across the whole bracket, not just at one mode. Also
verified directly at DEFAULT parameters: pump ON vs OFF gives CO₂(2024) identical to **2.0e−08 ppm**
and 1750–2024 uptake identical to **1.2e−07 GtC**, while adding **+3,457 GtC** of preindustrial
interior inventory.

**A PREDICTION OF MINE CAME BACK UNRESOLVED, NOT FALSE, AND THE FILE NOW SAYS SO.** P3 predicted the
optimum would move < 15 % across the bracket. Three of four `kz` columns peaked at the **top of my
pump grid**, so their optima are lower bounds and the first run's "20.2 % — FAIL" was a property of
the grid, not the model. Rather than widen the grid, part 5 measures the mechanism: at `kz` = 3830,
`pump_grad` 290 → 335 gains **+34.1 on atmospheric radiocarbon** while the three gradient rows
**lose** 5.2 — an under-ventilated column uses the constant-mass pump as a **bomb-¹⁴C sink**. Real,
and off the posterior's support: at `kz` = 6200 the same channel changes sign.

**P2 HELD.** `kz` prefers the bracket's top with the pump both OFF and ON; the pump makes deep water
older at every `kz`, which at 6200 moves that row toward its target (+1.60 → +1.15). The bracket was
bisected at default parameters on a model with **no pump**, on the very row the pump moves — it is a
refit question, not something to inherit.

**MARCUS'S DECISION (2026-08-16d): the pump ships ON, and `pump_grad` is FITTED** with its prior
anchored on the observed 233.109. Wiring written: `PUMP_GRAD_OBS` in `constants.R` (with the
observed value, not §5.2g's fitted 274.5 — that is a fit at a `kz` the refit will move), the
default in `model.R`, and the 20th `CCX_PARAM_TABLE` entry, `tr = "log"`,
`dlnorm(log(PUMP_GRAD_OBS), 0.25)`. The prior mildly double-counts GLODAP and says so in place:
its ±25 % width is ~4.5× the likelihood's own 13.1 µmol/kg.

**THE WIRING IS NOT COMMITTED, AND THAT IS THE POINT.** Pump-ON takes the suite **4 → 19 failing
expectations across 11 tests**. Attributed by running the full suite at HEAD and with the change:
the **4 are pre-existing and unchanged**; **7 tests are new**. One of the seven pre-declares this
event in its own comment and fails at exactly 233.109 — the pump installing precisely the gradient
it names. **No test was edited.** Two of the seven — "single derivative agrees to roundoff" and
"the pro-rata land-use debit agrees to roundoff" — could be a genuine parity break rather than a
stale expectation, and are the first thing to diagnose.

**ONE MIS-ATTRIBUTION OF MINE, CORRECTED BY MEASUREMENT.** I first read the `test-luc-permanence.R`
failures as caused by the pump, since a constant-mass pump should not move a fossil pulse's airborne
fraction. Measured at `pump_grad = 0`: af = **0.1513** at lag 100, **identical to the pump-ON arm at
every lag** (1, 10, 50, 100, 150, 250 yr). They were already failing at HEAD. The property was never
in question; my attribution was.

## 2026-08-16e — The seven tests re-derived; the pump wiring COMMITTED; the advection hypothesis on record was WRONG

**The blocker from 16d is cleared.** All seven new failures re-derived, suite back to the
pre-existing 4 — **855 passing against 802 at HEAD**. `git checkout -- R/` is no longer the escape
hatch; the pump ships. **No test was re-expressed to make a model change pass**: five of the seven
now assert *more* than before, and two ended up catching real defects (below). DESIGN §5.2i.

**MY OWN HYPOTHESIS WAS WRONG, AND KILLING IT COST NOTHING BECAUSE IT WAS FLAGGED AS A GUESS.**
Handoff 16d §5 offered "the export field is solved per hemisphere, so reversing which hemisphere
sinks is no longer a symmetry" for `test-ocean-advection.R`. **Inapplicable, on inspection before
any run**: `w_up` is a single *global* parameter and the test sets `w_out_NH = w_out_SH`, so **no
hemisphere is ever swapped** — each column is reversed separately and identically. Both hemispheres
break in the *same* direction, at the ratio of their ocean areas (1.24 measured vs 1.33), which a
swap cannot produce.

**WHAT IS ACTUALLY HAPPENING** (`calibration/diag_pump_advection_symmetry.R`, ~1 min, five
pre-registered predictions, all confirmed). `e^{A_out t} = D (e^{A_up t})^T D^-1`, so propagator
element (i,j) maps to (j,i): the mixed layer's **(1,1) is preserved BIT-EXACTLY** (|gap| =
**0.000e+00** at 10 and 60 yr) and **interior→ML elements differ by O(1)** (0.402, 0.220).
**The atmosphere's invariance was always conditional on the ocean having no interior source — the
test said so in its own words — and the pump is the model's first interior source.** Premise
falsified, theorem intact. **NOT A BUG:**

- **CO₂, the mixed layer and the land still tie EXACTLY** (≤ 1.8e-12) at every `pump_grad` from 0 to
  466.2. The break does not scale with the pump at all.
- `ocean_C`'s **1351.8 GtC** gap is a *preindustrial-inventory offset*, flat to **7.3e-11** across
  the run — a different steady state, not a different response.
- What breaks is the **isotopes**: δ¹³C **1.7e-3 ‰** against a 0.44 ‰ σ — **0.4 % of one sigma**.

**AND THE MECHANISM HAS ITS OWN MUTATION TEST.** In `pump_mode` "N" the export *mass* is fixed, so
12C's interior source is a **constant field** and cancels from the linear anomaly equation. Mode N
does not fix the export's *isotopic ratio*, which rides the Suess effect. **Mode "D" makes 12C's
export state-dependent too and CO₂ moves 5.3e-2 ppm — 6e10× mode N.** State-*dependence*, not mere
presence, is what reaches the atmosphere.

**TWO TESTS CAUGHT REAL DEFECTS, WHICH IS THE ARGUMENT FOR RE-DERIVING RATHER THAN RE-BASELINING:**

- The **`PUMP_GRAD_OBS` ↔ `ocean_grad_dic` consistency test** promised in 16d §4 was written and
  **failed on its first run**: the constant was hand-typed **233.109** against a shipped target of
  **233.109378176267**. 1.6e-6 relative — physically nothing, and *exactly* the drift the test
  exists to prevent. Both the constant and `CCX_PARAM_TABLE$pump_grad$init` now carry the target's
  own digits.
- **`test-parity.R` was NEVER a parity break** (16d already retracted that priority call on
  measurement) and the tolerance is now **derived, not re-baselined**: the pump emits into `nl` = 10
  boxes on both limbs = **20 extra terms** carrying **18.83 GtC/yr**, so reassociation is bounded by
  20 × ε × 18.83 = **8.36e-14** against a **measured 8.53e-14 — 1.02×**. The disagreement is the
  pump's own fluxes summed in a different order and nothing else. Tolerance = 4× the derived bound,
  with a **pump-OFF arm retained at the original 1e-15** so a real break cannot hide in the budget.

**THE REST.** The `test-likelihood.R` tripwire fired as designed and split into two arms — OFF keeps
the zero-uniformity claim unweakened, ON asserts the interior gradient **equals `pump_grad` to 1e-13
for every parameter perturbed**, including `kz` and `h_ml`, which is a strictly stronger statement
than "nonzero". The leverage test's **guard**, not its bound, is what failed: the pump closed the
miss **11.02 σ → 1.79 σ**, so `expect_gt(miss, 5)` fired while every leverage stayed inside
`LEV_MAX`; restated as the ratio it always meant (≤ 0.049 measured against a 0.10 gate). **The pump
does not touch the leverage at all** — identical to three digits on and off — which is the
level-vs-sensitivity separation the pump was adopted for, and is now gated. `test-pump.R` was
testing the *default* under a title about *bit-reproduction*; split, and the reproduction claim
strengthened to run against a parameter list carrying no `pump_grad` at all.

**NOT DONE.** `test-parity.R`'s frozen-Revelle arm still carries a bare `1e-15` and **passes** with
the pump on, so it was left alone rather than swept into `PARITY_REL_TOL` — a passing gate is not
something to loosen on tidiness grounds. It is the one place the derivation above is not yet
applied, and it will fire if a future mechanism raises the flux count through that branch.

## 2026-08-16f — kz re-bisected for the pump; the two-arm refit is BUILT and SMOKE-TESTED but NOT LAUNCHED

**Marcus 2026-08-16e: fit `pump_mode` "N" and "D" and compare** — DESIGN §5.2f deferred that to the
refit and this is it. `ccx_make_logpost()` gained `base_params` so a STRUCTURAL choice that is not a
fitted parameter can be varied between two otherwise identical objectives; the default path is
bit-identical (`identical()` on the log-posterior at init). N and D differ by **314 log-units at the
hand-set init**, which is precisely why they must be *refitted* rather than compared there.

**THE `kz` BRACKET WAS RE-BISECTED FIRST, and Marcus took the decision on the numbers.** It would
otherwise have decided the answer: §5.2h P2 measured `kz` **pinning to the bracket's top**, so the
top is the refit's `kz`, and [3830, 6200] was bisected on a model with **no pump** against the very
row the pump moves. **The pump-OFF control reproduces the shipped bracket to 1.3 / 0.8 m²/yr**, so
the recipe is faithful; pump-ON gives **[3942.5, 6528]**, the top **+328 m²/yr (+5.3 %)** — the pump
makes deep water older, so it *buys* `kz` headroom. **N and D give the identical bracket** (at the
preindustrial steady state D's scale factor is 1 by construction, so the arms differ only in the
transient) — it cannot bias the comparison. On the **bottom box**, the layer actually scored, the new
bracket is −219.8 / −162.8 against −220.4 / −163.5: nearly a no-op on the scored quantity.

**THE RUN IS NOT LAUNCHED, AND THE SMOKE TEST IS WHY.** A truncated two-arm run (1 restart, 60
iterations) was cheap and it surfaced a blocker that would have wasted ~11 h:

- **`h_ml`'s init is 75 and `LIK_OCEAN_GRAD_HML_OK` is [85, 120] — the objective STARTS with all
  three ocean-gradient rows ABSENT.** This is handoff 16d §7 item 7 ("where does the refit's `h_ml`
  land?") arriving with teeth.
- **The switch is a real discontinuity and it pays to be outside.** Measured at otherwise-init
  parameters: crossing 84.99 → 85.00 (absent → live) **costs 10.07 log-units**; crossing
  119.99 → 120.01 (live → absent) **gains 9.6**. A mode-finder is rewarded for leaving the band.
- **And `h_ml`'s own likelihood pulls it well below the band anyway** — the log-posterior falls
  monotonically from −4105 at `h_ml` = 70 to −4703 at 150. The previous mode's `h_ml` was **183.95**;
  the truncated arm landed at **exactly 85.00**, sitting on the edge from the outside.
- **The rows are what constrain `pump_grad`, so this is not cosmetic.** With them LIVE (`h_ml` = 100)
  the best `pump_grad` is **250.0 — 0.28 prior sd**, close to both the observation (233.1) and the
  1-D optimum (274.5). With them ABSENT the parameter is held by its prior plus weak leverage: the
  truncated 20-parameter arm ran it to **963.6, |z| = 6.27**.

So a refit launched as-is would very likely compare N against D **in the regime where the pump's
main constraint is switched off**, for both arms — apples-to-apples, but the wrong apples. Put to
Marcus rather than resolved here; `calibration/run_modefind_pump_arms.R` is written, gated
(it refuses to run if the two arms differ in anything but `pump_mode`), and ready.

## 2026-08-16g — The `h_ml` cliff DECOMPOSED: it is not why `h_ml` leaves the band, and the taper does not fix the part that matters

`calibration/diag_hml_band_discontinuity.R` (~4 min, 5 pre-registered predictions, 4 gates).
Handoff 16f §5 measured the cliff and offered four options; it did not decompose it. **Nothing was
proposed and `R/likelihood.R` is unchanged** — the four options stay Marcus's call. DESIGN.md §5.2k
has the full account.

**Four gates first, so the decomposition is of the real objective and not of a lookalike.** The
by-stream split needs a replica of `ccx_make_logpost()`; GATE B asserts the replica's total equals
the real objective's at an in-band and an out-of-band point (**gap 0.000e+00 at both**). GATE C: the
out-of-band counterfactual row values reproduce the gated ones in-band to **0.000e+00** over 11
points. GATE D: part 4's cell recipe reproduces both shipped GLODAP targets to **0.00e+00** before
any `h_ml` moves.

- **THE CLIFF IS EXACTLY "THE ROWS APPEARED", TO 1e-12.** The identity
  `Δ total = (rows that appeared) + (continuous drift)` closes to **−6.4e-13** at the floor and
  **−2.4e-12** at the ceiling. Only the three `ocean_grad_*` streams jump; the other 16 plus the
  prior are continuous, and the jump is **85×/60×** the drift the same 0.02 m step produces. So
  `h_ml` = 85 does not *fit worse* than 84.99 — **it is scored on more data.**
- **TWO SEPARABLE DEFECTS WEAR ONE NUMBER.** **(A) a barrier** — the discontinuity, 16f §5.4's MCMC
  hazard. **(B) an incentive** — the objective is *paid* to discard rows, since a skipped Gaussian
  contributes 0 where a live one contributes a negative number.
- **A TAPER FIXES (A) AND NOT (B), and that is an identity rather than a measurement:** for any
  weight on a negative row sum, the objective is monotone the wrong way. Measured at ramp
  half-widths 15/30/60 m, the argmax over `h_ml` is **32 m in every case** — identical to the
  shipped hard skip, to the rows deleted, and to the rows always live.
- **THE HEADLINE: THE ROWS ARE NOT WHY `h_ml` LEAVES THE BAND.** The objective's argmax over `h_ml`
  is **32 m** (30 is the prior bound, where `qlogis(0)` = −Inf) against a best in-band 85.01 — a
  **236 log-unit pull against a 10.0 log-unit cliff, 24×** — and **deleting the three rows moves the
  argmax not at all (32 → 32 m)**. No formulation of the rows can pull `h_ml` back in. **Option 1 is
  therefore not a tie-breaker between formulations; it is a hard constraint costing ~236 log-units**
  at init parameters — an **UPPER BOUND** (same caveat class as §5.2g's pump margin: `beta_max`, `kz`
  and `k_w` can reallocate some of it in a refit).
- **A FIFTH OPTION, NOT ON 16f's LIST: σ-INFLATION.** The band encodes a **representation error**, and
  the honest way to carry one is in quadrature — `σ_eff² = σ_obs² + σ_rep(h)²` **with dnorm's
  normalisation retained**, so inflating is charged for rather than free and the gain is bounded. Not
  a tuning knob: `σ_rep(h)` is **measured** as the shipped-minus-like-for-like target gap.
  **DIC `σ_rep/σ_obs` 0.04–0.87 over `h_ml` 32–192, δ¹³C 0.01–1.11** (in-band DIC 0.04–0.34) — i.e.
  **the mismatch the band exists to prevent never exceeds ~1σ anywhere in the prior support.**
  Alkalinity's is **UNQUANTIFIED**: the GLODAP subset carries no `talk` column.
- **TWO PREDICTIONS FAILED, BOTH INFORMATIVELY, AND NEITHER BAR WAS LOOSENED.** P4 predicted
  inflation would recover >50 % of what the skip gives away; measured **21 %** (2.14 of 10.01) — the
  *reasoning* was wrong, not the bar: at ~1.8σ misses `z²/2 ≈ 1.6` while `−log(σ√2π)` carries the
  bulk, so inflation is a **stronger** remedy than predicted. P5 predicted `σ_rep` would exceed
  `σ_obs`; it barely does, which is what reframes the band as disproportionate.
- **P1's first bar was measuring a slope and was RE-DERIVED, not re-baselined.** An absolute
  0.05 log-unit bar on "nothing else moves discontinuously" failed at 0.0696 — on the objective's
  ordinary ~8 log-units/m gradient in `h_ml`, which over a 0.02 m straddle is ~0.16 of legitimate
  drift. Restated as the claim actually being made: the jump must dwarf the drift the same step
  produces (85×/60× against a 20× bar). P2 likewise became an **exact identity** (bar 1e-6, residual
  1e-12) rather than a 0.10 tolerance.
- **RECEIPT CHECK: `R/likelihood.R`'s own "1.61 σ at 184" is ~2× overstated.** The "0.09 σ at 100"
  half reproduces (0.07). The other half does not: against the gate's own quantity and the σ the
  gate's own term uses, `h_ml` = 184 is **0.80 σ**. 1.61 is the *frozen-at-75* contrast divided by
  the **tighter blk30** σ (20.16) — the shipped rds carries
  `sd_by_block = c(blk30 = 20.16, blk60 = 25.25)` and ships the conservative 25.25, while
  `diag_gradient_target_and_neff.R` called `part2b()` with `min(...)` over valid blocks. Reproduced
  to **1.58 vs 1.61**. **Not a code defect — the band still guards a real mismatch** — but the band's
  severity has been argued from 1.61 in three handoffs.

**Two bugs in this file's own first drafts, both caught by its gates rather than by inspection.**
`ccx_par_to_unc(ccx_default_params())` errors, because `bomb_total`, `luc_scale`, the two sigmas and
the two gradient offsets are fitted parameters with **no field in `ccx_default_params()`** — the init
vector must come from `ccx_init_unc()`. And `ccx_loglik(by_stream = TRUE)` returns a **named numeric
vector, not a list**, so `[[missing_name]]` *errors* instead of returning NULL — which for a file
about absent streams would have been fatal.

**PART 7 — who pays the 236 (added same day).** The pull is **not a consensus**: between `h_ml` = 100
and 32, `co2_level_SPO` (+144.5), `co2_level_MLO` (+98.0) and `d14c_SH` (+68.0) carry **96 %** of
+324.5, while `d13c_level_MLO` (−26.4), `d13c_level_SPO` (−18.5) and `gcb_ocean_sink` (−10.8) pull the
**other way**. A thinner mixed layer absorbs less carbon, so airborne CO₂ rises — **the CO₂-level
streams want `h_ml` small because the model at init OVER-ABSORBS**, and `co2_level_SPO` is −256
log-units at `h_ml` = 100, i.e. init is a bad fit to the CO₂ record. Since `kz`, `k_w` and `beta_max`
move ocean and land uptake directly — serving exactly those three streams — **`h_ml` is simply the
cheapest single knob available while the other 19 are frozen, so part 6's 236 is an upper bound AND
probably a large overstatement** of what bounding `h_ml` would cost a refit. **What survives
unconditionally is the negative result: the gradient rows are irrelevant to where `h_ml` goes, so no
re-formulation of them fixes the pull.**

## 2026-08-17 — The "1.61 σ at 184" prose corrected in `R/likelihood.R` (16g open item 5)

**Comment-only. Nothing in the objective changed, and the two-arm refit launched 2026-08-16g was
running throughout** (comments cannot reach a process that sourced the file at startup, and the diff
was verified to touch no executable line).

16g §2.5 receipt-checked `R/likelihood.R`'s own justification for the `h_ml` band and found the
number it argues from is ~2× overstated, but left correcting the prose as open item 5 — "small, but it
is load-bearing prose". Discharged:

- **The `h_ml` gate paragraph** now reads **"0.07 σ at `h_ml` = 100 and 0.80 σ at the fitted 184"**,
  and says explicitly that those are *this gate's own quantity* —
  `(shipped target − like-for-like target at h_ml) / shipped sd`. It also now carries what 16g §2.4
  measured and the file never stated: the mismatch the band exists to prevent is **sub-1σ everywhere
  in `h_ml`'s prior support** (DIC `σ_rep/σ_obs` 0.04–0.34 in band, 0.22–0.87 out).
- **The fixed-depth TARGET bullet** dropped the bare "1.61 σ" and now gives the frozen-at-75 contrast
  on the σ this term actually ships (blk60, 25.25) — **1.26 σ** — with a pointer to where 1.61 came
  from. The bullet's *argument* is untouched: freezing at 75 still overstates the miss and still
  biases in favour of adopting a pump, which is why fixed depths were chosen.
- Both sites cite `calibration/diag_hml_band_discontinuity.R` part 5 as the receipt.

**`HB_REF_MISMATCH_184 <- 1.61` in the diagnostic is deliberately NOT changed** — part 5 *divides* by
it to recover the σ it implies (19.83 ≈ blk30's 20.16 to 2 %), which is the step that identifies
where 1.61 came from. Only its comment moved, from "R/likelihood.R's own figure" (now stale) to "the
HISTORICAL figure this part receipt-checks".

**Not done here:** the band itself is unchanged (`LIK_OCEAN_GRAD_HML_OK` is still `c(85, 120)`), and
σ-inflation (16g §2.4, open item 4) remains unimplemented and Marcus's call. This commit corrects
what the file *claims*, not what it *does*.

## 2026-08-17 — The "1.61 σ at 184" prose corrected in `R/likelihood.R` (16g open item 5)

**Comment-only. Nothing in the objective changed, and the two-arm refit launched 2026-08-16g was
running throughout** (comments cannot reach a process that sourced the file at startup, and the diff
was verified to touch no executable line).

16g §2.5 receipt-checked `R/likelihood.R`'s own justification for the `h_ml` band and found the
number it argues from is ~2× overstated, but left correcting the prose as open item 5 — "small, but it
is load-bearing prose". Discharged:

- **The `h_ml` gate paragraph** now reads **"0.07 σ at `h_ml` = 100 and 0.80 σ at the fitted 184"**,
  and says explicitly that those are *this gate's own quantity* —
  `(shipped target − like-for-like target at h_ml) / shipped sd`. It also now carries what 16g §2.4
  measured and the file never stated: the mismatch the band exists to prevent is **sub-1σ everywhere
  in `h_ml`'s prior support** (DIC `σ_rep/σ_obs` 0.04–0.34 in band, 0.22–0.87 out).
- **The fixed-depth TARGET bullet** dropped the bare "1.61 σ" and now gives the frozen-at-75 contrast
  on the σ this term actually ships (blk60, 25.25) — **1.26 σ** — with a pointer to where 1.61 came
  from. The bullet's *argument* is untouched: freezing at 75 still overstates the miss and still
  biases in favour of adopting a pump, which is why fixed depths were chosen.
- Both sites cite `calibration/diag_hml_band_discontinuity.R` part 5 as the receipt.

**`HB_REF_MISMATCH_184 <- 1.61` in the diagnostic is deliberately NOT changed** — part 5 *divides* by
it to recover the σ it implies (19.83 ≈ blk30's 20.16 to 2 %), which is the step that identifies
where 1.61 came from. Only its comment moved, from "R/likelihood.R's own figure" (now stale) to "the
HISTORICAL figure this part receipt-checks".

**Not done here:** the band itself is unchanged (`LIK_OCEAN_GRAD_HML_OK` is still `c(85, 120)`), and
σ-inflation (16g §2.4, open item 4) remains unimplemented and Marcus's call. This commit corrects
what the file *claims*, not what it *does*.

## 2026-08-17 (later) — Alkalinity's `σ_rep` MEASURED: 16g's "would need a new download" was wrong, and the row is the best-behaved of the three

`calibration/diag_alk_sigma_rep.R`, ~30 s, **3 gates + 3 pre-registered predictions, all passing**.
Nothing proposed; `R/likelihood.R` unchanged; the two-arm refit was running throughout and this was
sized to not compete with it (one 19 MB CSV read, no model evaluation).

**THE BLOCKER WAS A FILE-POINTER MISTAKE, NOT MISSING DATA.** 16g §2.4 left σ-inflation (open item 4)
with two of three inputs, recording that "alkalinity's `σ_rep` is UNQUANTIFIED — the GLODAP subset
carries no `talk` column, so it would need a new download or a stated assumption." The first clause is
true of the file 16g's part 4 reads (`glodap_c13c14_subset.csv`); **the inference is not.** The shipped
ALK target was never built from that file — `data-raw/build_glodap_deep_targets.R:324` reads
`glodap_dic_talk_subset.csv`, **464,590 QC-passed bottles already on disk**, because (its own comment)
"alkalinity is measured on far more bottles" than the isotope cruises. Part 4 pointed at one file while
the target came from another. No download, no assumption.

**GATES.** The recipe is copied from part 4 (itself copied from `diag_gradient_target_and_neff.R`) and
not re-chosen. **G1/G2** reproduce **both** shipped targets from this file's own cells before any `h_ml`
moves — `talk` **78.5927** and `tco2_alkpop` **225.8087**, each to **0.00e+00**. Two fields are gated,
not one, because a recipe reproducing only `talk` could be right by luck about the cells and wrong about
the cosine weighting. **G3** asserts `ccx_ocean_grid(100)`'s surface box *is* the shipped 0–100 m layer
to 1e-9, which is what makes the curve's floor interpretable as the closed-vs-open edge convention
rather than a depth mismatch.

**THE RESULT — the row feared unquantified carries the SMALLEST representation error of the three:**

| row | in band | all `h_ml` | source |
|---|---|---|---|
| DIC | 0.04–0.34 | 0.04–0.87 | 16g part 4 |
| δ¹³C | 0.01–0.55 | 0.01–1.11 | 16g part 4 |
| **ALK** | **0.02–0.07** | **0.02–0.34** | **this file** |

At the quarantined mode's `h_ml` = 184 the ALK mismatch is **0.17 σ**; in band it never exceeds
**0.07 σ**. The DIC/δ¹³C comparators are **read from 16g's own saved rds**, not transcribed from its
handoff, so the table cannot inherit a prose typo — and doing so filled in a cell 16g's handoff left
blank (δ¹³C in-band, 0.01–0.55).

**This STRENGTHENS 16g §2.4 rather than qualifying it.** The band switches all three rows off together,
and every one of them is sub-1σ across `h_ml`'s entire prior support — a 10-log-unit switch enforcing,
at worst, a 1.11 σ mismatch and at best a 0.02 σ one. **Predictions: 3/3 PASS** (Q1 max ratio 0.342 vs
bar 1.20; Q2 in-band 0.067 vs 0.40; Q3 r = 0.922 vs 0.90 — ALK's `σ_rep` tracks DIC's in shape, as two
gradients of carbon-like tracers read on the same box edges should).

**NOT done, and still Marcus's call:** σ-inflation remains **unimplemented**. This supplies its missing
input; it does not price it. 16g's "inflation recovers 21 % of the skip's gain" is untouched — that
needs the model's own gradient at each `h_ml`, and the refit owns the machine.

## 2026-08-18 — THE TWO-ARM REFIT LANDED. §5.3 took the good branch; N favoured by 5.62; and the pre-refit per-stream reading REVERSED

`calibration/run_modefind_pump_arms.R`, launched 2026-08-16g, **23 h 57 m wall** (N 753.5 min /
303,661 evals; D 683.0 min / 297,804 evals). Outputs at `calibration/output/pump_arms/`:
`mode_fit_pump{N,D}.rds` + `pump_arms_comparison.rds`. **This is the first serious calibration this
model has ever had** — `calibration/output/mode_fit.rds` is still absent and every previous "at the
mode" number came from the pre-gradient-terms quarantine.

**§5.3 — THE CO₂-LEVEL STREAMS RECOVERED, so the bound was cheap and the comparison is readable.**
Verified against 16g's saved rds rather than its prose:

| stream | 16g @ `h_ml` = 100, else init | arm-N mode | recovery |
|---|---|---|---|
| `co2_level_SPO` | −255.94 | **−62.87** | **+193.1** |
| `co2_level_MLO` | −182.72 | **−73.75** | **+109.0** |

Biggest movers: `co2_seasonal_MLO` **+676.3**, `d13c_gradient` **+490.0**, `d14c_SH` +166.7,
`d13c_level_MLO` +166.1. Only three streams worsened, all trivially (≤ 3.2).

**AND `h_ml` LANDED INTERIOR IN BOTH ARMS — 94.36 (N), 91.16 (D) — with the gradient rows LIVE.**
Nobody pre-registered this and it is the cleanest confirmation available: had the 236-log-unit pull
survived a refit, `h_ml` would sit pinned at the 85 bound. It does not, in either arm. **§3's "236 is
an upper bound and probably a large overstatement" is CONFIRMED — the pull was an artefact of holding
the other 19 parameters at init**, and `kz`/`k_w`/`beta_max` absorb the CO₂-level misfit directly.

**`pump_grad` IS CONSTRAINED IN BOTH ARMS** — 289.60 (N), 282.26 (D), against **963.6 / 1431.0** in
16f's rows-off truncated arms. Both sit near the old mode's 1-D optimum (274.5) and above the observed
233.11. The gradient rows are doing the job they were added to do.

### The comparison

| | N | D | D − N |
|---|---|---|---|
| log-posterior at MAP | −2091.16 | −2096.26 | −5.10 |
| ½ log|−H| | 61.43 | 61.96 | +0.52 |
| **Laplace log-evidence** | | | **−5.62** |

**N is favoured by 5.62 log-units.** Both Hessians PD (cond 6.8e5 / 5.5e5), so `recompute_hessian.R`
was not needed for either arm. The `(d/2)log 2π` term cancels (same 20 parameters) and 16g §4's prior
renormalisation constant (+1.5805) is identical in both arms, so it cancels too.

### THE PER-STREAM TABLE REVERSED THE PRE-REFIT READING — and 16g §5.4 was right to insist on reading it fresh

16f's *truncated, unconverged* table hinted D gains on `co2_seasonal_MLO`, `d14c_NH` and
`d13c_level_SPO`. Two held. **The third reversed outright: `d13c_level_SPO` is D's single biggest
LOSS (−9.74), not a gain.** And the framing "D's gain was entirely the CO₂ record" is **wrong**:

| what D buys | Δ | what D sells | Δ |
|---|---|---|---|
| `gcb_ocean_sink` | +2.51 | `d13c_level_SPO` | **−9.74** |
| `gcb_land_sink` | +1.93 | `d13c_level_MLO` | **−7.30** |
| `d14c_NH` | +1.92 | | |
| `d14c_SH` | +1.80 | | |
| `co2_seasonal_MLO` | +0.90 | | |
| `d14c_deep_ocean` | +0.77 | | |

**The CO₂ LEVELS are essentially tied** (−0.43 MLO, −0.16 SPO) and `d13c_gradient` is tied to
**+0.00**. So the contest is **δ¹³C levels (N wins, −17.04) against sinks + ¹⁴C (D wins, +10.91)**,
net loglik −6.13. **This independently corroborates the pump × advection symmetry result**
(`project_ccx_pump_advection_symmetry`: the reversal ties CO₂ and breaks only the ISOTOPES) — at two
modes that differ in all 20 parameters, CO₂ ties and the isotopes decide.

### Caveats, none of them dismissible

- **The driver's own words: "READ THIS AS INDICATIVE, NOT AS A BAYES FACTOR."** `kz` sits 96.6 % (N)
  and 88.9 % (D) up the re-bisected bracket, so the posterior is non-Gaussian in that direction and
  the Hessian reports the transformed coordinate's curvature.
- **BOTH ARMS HIT THE 20-RESTART CAP WHILE STILL GAINING** and both are flagged NOT CONVERGED.
  `ARM_TOL` = 1e-4 is unreachable for a 20-parameter Nelder-Mead here. Practical movement is tiny
  (N moved 0.7 log-units over restarts 8→19; BFGS polish gained 0.09), so these are plateaus, not
  climbs — **but that ~0.7 plateau wander is the noise floor, and 5.62 is only ~8× it.**
- `bomb_total` sits at **z = +3.01** in N and is flagged; D flags nothing.
- One `conveyor 12C spinup did not converge` warning, |resid| = 1.79e-06.
- **`ARM_HESS_EPS` = 3e-4 is still inherited from an 18-parameter run** and un-re-derived at 20
  (16g item 3, still open even though both Hessians came back PD).

**Open: N or D is Marcus's call** (16g item 2). The evidence points to N; whether 5.62 against a
0.7 noise floor and a pinned `kz` is decisive enough is the judgement.

## 2026-08-18 (decision) — **ARM N ADOPTED, PROVISIONALLY** (16g open item 2 — Marcus 2026-08-18)

**Decision: adopt N as the mode and unblock the critical path, with the choice recorded as
PROVISIONAL and revisited once the sampler produces a real posterior.**

**The case for N:** favoured on Laplace evidence (**5.62 log-units**, ~8× the ~0.7 plateau noise
floor), favoured on MAP height (−2091.16 vs −2096.26), and it wins the **δ¹³C levels** (+17.04 over D)
— the stream class the gradient rows and the pump were added to constrain in the first place.

**WHAT "PROVISIONAL" IS CARRYING, and it is not a formality.** Every one of these stands unresolved:

- **The driver's own verdict: "INDICATIVE, NOT A BAYES FACTOR."** `kz` sits **96.6 %** (N) / **88.9 %**
  (D) up the re-bisected bracket, so the posterior is non-Gaussian in that direction and the Hessian
  reports the transformed coordinate's curvature rather than a free one's.
- **BOTH arms hit the 20-restart cap while still gaining** and are flagged NOT CONVERGED. They are
  plateaus rather than climbs (N moved 0.7 log-units over restarts 8→19; BFGS polish +0.09), **but
  that ~0.7 wander is the noise floor and 5.62 is only ~8× it.**
- **`bomb_total` sits at z = +3.01 in N and is FLAGGED; D flags nothing.** The adopted arm is the one
  in a prior tail.
- **`ARM_HESS_EPS` = 3e-4 is still inherited from an 18-parameter run**, un-re-derived at 20, and the
  evidence contrast depends on the Hessian it produces.

**Nothing downstream is expensive to redo** if a converged posterior disagrees — which is the whole
reason this is defensible as a provisional call rather than a deferral. **The mode is
`calibration/output/pump_arms/mode_fit_pumpN.rds`.** Note `calibration/output/mode_fit.rds` is
**still absent** and this does NOT create it; do not conflate the two paths.

**NOT decided by this:** whether the σ-inflation redesign ships (open item 4 — its cost still needs
re-deriving over all three rows), and whether a **posterior** run keeps the `h_ml` bound. A hard bound
is defensible for a mode-find and is a **weaker claim for a sampler**; that question is re-opened by,
not settled by, this decision.

## 2026-08-18 (later) — `luc-veg-debit` MERGED into `main` at last (16g item 9)

**Done on Marcus's instruction 2026-08-18, immediately after the refit freed the machine.** The branch
had been carried unmerged since well before the pump work and was flagged in eight consecutive
handoffs.

**It was a STRICT FAST-FORWARD, which is easier than every one of those handoffs implied.** `main` was
a direct ancestor of `luc-veg-debit` — 99 ahead, **0 behind**, no conflicts, and therefore **no
working-tree change at all**. Verified before executing (`git merge-base --is-ancestor`), then run as
`git merge --ff-only`.

| | before | after |
|---|---|---|
| `main` | `0b7371c` | **`e2c9238`** |
| `luc-veg-debit` | `e2c9238` | `e2c9238` (unchanged) |
| HEAD | `luc-veg-debit` | **`main`** |

**FAST-FORWARD WAS CHOSEN OVER A SQUASH, and the reason is recoverability rather than taste:** a
squashed history can always be produced later from preserved commits, while an un-squash is
impossible. This project also leans hard on per-commit provenance — bisecting the pump and gradient
work, and answering "when did this number change" — which a squash would destroy.

**`luc-veg-debit` is KEPT, not deleted.** `0b7371c` is the recovery ref for `main`'s pre-merge state
(`git branch -f main 0b7371c`) if this ever needs undoing.

**The 4 known test failures rode along onto `main`** (`test-pulse.R` af(100) = 0.213 vs > 0.30;
`test-luc-permanence.R` ×2; `test-mechanisms.R` ENSO 0.30 vs > 0.5). They are pre-existing, not
pump-related, and **still undiagnosed since 2026-08-15** — the merge did not create them, but `main`
now carries them. **Diagnosing them is the next queued job**, and the standing rule applies: treat
"plausibly stale gate" as the hypothesis to attack, not the answer — a stale-fixture label has
already hidden a real bug in this project for five handoffs. Repair by deriving the bar, never by
re-baselining it to wherever the code lands.

No remote is configured, so nothing was pushed.

## 2026-08-18 (job B) — The 4 test failures DIAGNOSED: 3 mis-specified bars, 1 stale test premise, and no code bug

**Suite baseline MEASURED rather than inherited: `FAIL 4 | WARN 53 | SKIP 2 | PASS 857`** on `main` at
`ea06f1f`. **Nothing was changed** — no test edited, no bar moved, no source touched. Full account:
`notes/diag_2026-08-18_test_failures.md`.

**16f's triage was "all four are plausibly stale gates … that is an assessment, not a verdict."
Attacking rather than accepting that label is what produced the finding below.**

**HOW THE BARS WERE ADJUDICATED — re-measured `diag_joos_irf.R` (PD100 protocol).** This is the
evidence that established the airborne-fraction numbers are right; it is **not** a finding about a
model defect, and an earlier draft of this entry wrongly promoted it to one (see the retraction below).
The model runs on the low side of Joos, by:

| horizon | integrated IRF (model / Joos best) | point IRF (model / Joos T5) |
|---|---|---|
| 20 yr | 12.4 / 14.2 — **12.7 % low** | 0.520 / 0.596 — 12.8 % low |
| 50 yr | 25.6 / 30.3 — **15.5 % low** | 0.378 / 0.487 — 22.4 % low |
| 100 yr | 41.9 / 52.4 — **20.0 % low** | 0.292 / 0.409 — 28.6 % low |
| 300 yr | — | 0.207 / 0.322 — 35.7 % low |

**MARCUS 2026-08-18, AND HE IS RIGHT:** *"for a very simple model that is calibrated to historical
data, matching Joos within 25 % at each probability threshold is pretty good."* On the **integrated**
IRF — the quantity gate 12 actually scores — the model is **12.7 / 15.5 / 20.0 % low and inside all
three of Joos's 5–95 % bands**. Agreeing with a 15-model ensemble that closely, from a box model tuned
only to the historical record, is a **good result**. "Within 25 %" does not hold for the **point** IRF
at long horizons (28.6 % at 100 yr, 35.7 % at 300) — but that is the tail of a pulse-decay curve,
where a simple model is least expected to track, and it is a different metric from the gate's.

Joos §4.4.1's TH100 integrated IRF is **34–47 yr preindustrial** / **45–62 present-day**; the model
reads **25.6** and **44.7**. The PI value is **24.7 % below the floor of its range** — i.e. right at
the boundary of the same tolerance, not clearly outside it. **Gate 12's secondary check is scoped to
the PI < PD *ordering*, which the model satisfies.**

**PREDICTIONS: I got both halves WRONG and recorded them before looking.** I predicted the pump
(shipped 08-16e, after gate 12's status line was last measured 08-14) had lowered the integrated IRF,
possibly below the floor: it reproduced **12.4 / 25.6 / 41.9 exactly — the line is NOT stale.** I
predicted PD100 af(100) ≈ 0.33–0.36; measured **0.292**.

**THE FOUR, each bar DERIVED at the protocol it should have been stated at — none re-baselined:**

1. **`test-pulse.R:113`** (af(100) 0.213 vs > 0.30) — **bar mis-specified.** Its own comment cites
   "recalled … **NOT verified**" Joos values, which are **PD100** (389 ppm held); the test measures on
   **SSP1-1.9**. The model's own diagnostic gives PD-held 0.297, PD-decaying 0.244, ssp126 0.267,
   PI 0.152 — **0.213 on ssp119 is exactly where it belongs.** No code defect.
2. **`test-luc-permanence.R:88`** (`af_foss` 0.151 vs > 0.2) — **bar mis-specified, and the match is
   exact.** `lp_background()` is zero-emission with GMST and ENSO frozen = a **preindustrial**
   background, and `LP_PULSE`/`LP_LAG` are the Joos 100 GtC / 100 yr shape. **`diag_joos_irf.R`'s
   "PI, background HELD" IRF@100 = 0.152; the test measures 0.151** — agreement to 0.001 from an
   independent diagnostic. No code defect.
3. **`test-mechanisms.R:32`** (ENSO 0.30 vs > 0.5) — **wrong statistic.** One endpoint bar is applied
   to all six mechanisms. Five are monotone and clear it by 36–450× (emissions 212, fertilisation 200,
   ocean_sink 116, revelle 34, warming_feedback 18). **ENSO is the only OSCILLATORY one**, so its 2100
   value reads *phase*, not wiring — its **max over the series is 0.537 at 2032**, above the bar.
   ENSO is wired. No code defect.
4. **`test-luc-permanence.R:104`** (|af| 0.074 vs < 0.02) — **stale test premise.** Reproducing the
   pre-2026-08-13 model needs **both** `f_luc_perm = 0` **and** `f_luc_wood = 1`; the test sets one.
   With both: af@100 = **−0.0032**, af@150 = **−0.0026**, reproducing the recorded signature
   (0.002 / −0.003) and passing. `CCX_F_LUC_WOOD_DEFAULT` was flipped 1 → 0 after the test was written.
   **16f's triage already said "a case needing `f_luc_wood = 1`" — it was right and nobody acted.**

**A REAL DEFECT FOUND ALONGSIDE (4).** `R/cpp.R:104-105` asserts *"this default IS the old behaviour,
because `f_luc_wood` = 1 is the incumbent decision"* while **`R/model.R:159` sets
`CCX_F_LUC_WOOD_DEFAULT <- 0`** — a comment claiming a default the code does not have, **in the very
block that exists to stop the R and C++ cores silently running different models** ("which is exactly
what `gamma_enso` did"). Behaviour is correct (both read the same constant); the comment misleads.

**Repairs 1–5 are specified but NOT applied** (`notes/diag_…` §5), because the standing rule is to
report rather than edit a test into passing.

**RETRACTED SAME DAY — item 6, "gate 12 should gain a LEVEL check on Joos §4.4.1, which the model
currently fails."** Withdrawn on Marcus's assessment above. Scoring the integrated IRF against a
5–95 % band is a **reasonable scope for this model**, and adding a level check would manufacture a
failure out of agreement that is actually decent. **The error was mine and it was one of emphasis, not
arithmetic:** the Joos comparison was the *evidence* that the failing tests' numbers were correct, and
I promoted it to the headline finding — "a REAL under-gated model bias" — which the ratios do not
support. **What stands:** the model runs low, DESIGN already says so, and that belongs in prose rather
than a new gate. Repairs 1–5 rest on their own reasoning (wrong background, wrong statistic, a premise
needing two knobs, a stale comment) and are untouched by this retraction.

## 2026-08-18 (job B, applied) — The 5 test repairs LANDED, and a mutation test moved one of the new bars before it shipped

**Marcus gave the go-ahead and chose the two open bars** (`test-pulse.R` → re-protocol to PD100;
`test-luc-permanence.R:88` → a preindustrial band). All five repairs from
`notes/diag_2026-08-18_test_failures.md` §5 are applied.

**Suite: `FAIL 4 | WARN 53 | SKIP 2 | PASS 857` → `FAIL 0 | WARN 53 | SKIP 2 | PASS 870`.** The
baseline was MEASURED before touching anything and reproduced the diag exactly.

**Repairs 3, 4, 5** (`a12ecee`) — the wiring statistic (`max|ΔCO₂|` over the series against a new
derived `MECH_WIRED_MIN` = 1e-3 ppm, because ENSO is the only oscillatory switch and an endpoint read
its *phase*); the two-knob premise (`f_luc_wood = 1` alongside `f_luc_perm = 0`); and the stale
`f_luc_wood` comment. **Repair 5 was bigger than diagnosed:** the diag caught `R/cpp.R:104-105`, but
`R/model.R:442-443` carried the identical defect, tagging `1 = wood alone (shipped)` when `0` ships.
Traced: `b3108d7` added the switch defaulting to 1, `ea7c70b` adopted pro rata and flipped the
constant without updating either prose site. Both corrected.

**Repair 1 forced a dedup worth having on its own.** Running Joos's protocol inside the test needed
`ccx_hold_forcing` and friends, which existed as **byte-identical copies in both `diag_joos_irf.R`
and `diag_joos_beta_scan.R`**. All four helpers and every shared constant were verified identical
function-by-function, then promoted to a new **`R/joos_irf.R`** (−244 lines, +124). Both diagnostics
re-run clean and reproduce their recorded numbers exactly (0.520/0.378/0.292; 12.4/25.6/41.9), so the
move changed nothing. A third copy in `tests/` was the alternative and would have made drift worse.

### THE PART THAT MATTERS MORE THAN THE GREEN SUITE — the gates were mutation-tested

Full account: `notes/diag_2026-08-18_gate_mutation_tests.md`. **A green suite is not evidence a
rewritten gate works** — it is also what a gate that can never fire produces. Each new numeric bar was
attacked. Two of three came back weaker than their comments claimed.

- **`MECH_WIRED_MIN` — SOUND.** A disconnected switch trips it; live ENSO clears it 537×.
- **`LP_FOSS_PI_REF` 0.152 ± 30 % — constant KEPT, comment rewritten.** It holds at both modes
  (N 0.1622, D 0.1646) and across a 13× `kz` range (0.1852 → 0.1458) — but that *is* its limit: it is
  a sanity and cross-check gate on the reference arm, not a sensitivity gate, and now says so.
- **`JOOS_POINT_TOL` — THE BAR WAS DERIVED AT THE WRONG CONFIGURATION, and this is the reusable
  lesson.** Set to 0.35 from the gap at **package defaults** (0.287). But the **adopted arm-N mode**
  sits at **0.325** — 0.025 from firing, i.e. a flaky gate that would go red on ordinary re-fitting
  rather than on a regression. **Re-derived at the shipping configuration: 0.35 → 0.40.** Still a
  derivation, not a re-baseline; what changed is *which configuration the bar is derived at*.

**STANDING GAP THIS EXPOSES, not fixed here:** the suite derives bars from `ccx_default_params()`
while the project's adopted parameters live in `calibration/output/pump_arms/mode_fit_pumpN.rds`.
Every default-derived bar inherits that discrepancy. Coupling tests to a calibration output is its own
problem and was **not** done — but it is now measured for this gate and is worth checking before
trusting another default-derived bar.

### AND A RESULT THAT IS NOT ABOUT TESTS AT ALL

The scan behind the tolerance shows the Joos point IRF is **monotone decreasing in `kz`**, and **the
direction the calibration pins `kz` is the direction that makes the Joos agreement worse**:
bracket floor 3942.5 → −25 % at 100 yr; **arm-N mode 6439.2 → −33 %**; `kz` ≈ 500–800 would put the
model essentially **on** Joos's multi-model mean, an order of magnitude below the bracket.

**This gives the standing "`kz` pinned near its bracket top" question (handoff §7 item 5) a concrete
cost for the first time** — ~8 percentage points of Joos agreement at 100 yr, floor to mode.
**⚠ It is a one-at-a-time scan** (other 19 parameters at defaults; the two mode rows are a 14-of-20
overlay, since `bomb_total`, `luc_scale`, both sigmas and both gradient offsets have no field in
`ccx_default_params()`). It does **NOT** show a low-`kz` model would score better overall — the
likelihood pins `kz` high for reasons this scan does not evaluate, and the isotope and sink streams are
what would pay. **Do not read it as "lower `kz`."**

**Tried and caught, worth recording:** the first `kz` scan returned **bit-identical IRFs at all eight
values over a 13× range** — the "suspicious uniformity ≈ bug signal" pattern, and it was a bug in the
scan: `within(p0, kz <- kz)` **self-assigns**, the list's own `kz` shadowing the loop variable, so
every row ran the default. `within()` is an attractive idiom for one-at-a-time scans and it fails
silently into a flat, plausible-looking table.

## 2026-08-18 (drivers) — The seasonal cycle moves onto its PHYSICAL DRIVERS: insolation-shaped NPP + Q10 on seasonal temperature

**Marcus's proposal, replacing the "add a second harmonic" fork**: rather than fitting the
cycle's shape, derive it — NPP follows insolation, respiration follows seasonal land
temperature through the SAME `q10` the decadal feedback uses. The asymmetry then EMERGES
from Q10's exponential nonlinearity and the growing-season shape.

**OFFLINE FIRST** (`calibration/diag_seasonal_drivers_offline.R`), and the sequence of fits is
the story: (1) unconstrained fluxes found a MIRROR solution — shape right, both fluxes
negative, physics inside out; (2) sign-constrained without a phenology lag collapsed to
RMS 1.68 with the cycle peaking in March — both failures saying the same thing, that canopy
uptake LAGS insolation; (3) with the lag, RMS 0.202, better than the descriptive 2-harmonic
fit; (4) **the decisive test — fluxes PINNED at the model's own NPP (36 GtC/yr NH), zero free
fluxes: RMS 0.357 vs the fitted sine's 0.608, amp1 96 % of observed, amp2/amp1 = 0.21 vs the
observed 0.24, EMERGED not fitted.**

**WIRED into both cores** behind `seas_drivers` (default 1; **0 = the sine, bit-exact** — the
f_luc_perm escape idiom, and `mode_fit_pumpN.rds` reproduces to 0.000e+00 through it; cpp.R
absence-default is 0 so pre-change parameter lists run the model they were fitted to).
Driver-path R↔C++ parity 2.4e-15. Structural constants from the offline interior optimum:
`CCX_SEAS_PHI_EFF` = (75 N, −30 S), `CCX_SEAS_T_LAG` = 2.0 mo; the light threshold optimised
to ZERO (polar night rectifies the boreal growing season by itself) so no threshold constant
exists. **Parameters 20 → 19**: seas_amp/seas_phase ×2 OUT of the table (fields kept for the
escape path), `seas_T_amp_NH/SH` + `seas_lag_p` IN.

**What the full model now does that it could not:** NH amp2 = 0.94 ppm (was 0.03 — the
sawtooth exists); and the **seasonal-amplitude trend emerges from fertilisation: +17 % from
1960-80 to 2000-20 vs the observed ~15-20 %, with nothing fitted to it** — the NPP-side
amplitude is `npp × (shape − 1)`, a prediction, not a knob. At UNCALIBRATED defaults amp1
overshoots (5.0 vs 3.0 ppm; d13C 0.37 vs 0.18 permil) — that is the refit's job (`seas_T_amp`
is the counter-cycle), and the refit is HELD per Marcus.

**Tried, measured, and half-kept — the zero-emission control drift.** The driver control
drifts +0.43 ppm/275 yr where the sine drifted +0.044. Decomposed by ablation (`beta_max = 0`):
**+0.33 is the fertilisation RECTIFIER** — the seasonal CO2 swing modulates NPP and the product
has nonzero annual mean — real, amplitude-dependent physics that shrinks with the refit;
**+0.10 is integrator quadrature over the polar-night kinks**, already cut from +0.22 by moving
the shape norms from 12 to 720 points in both cores (the residual is the integrator's own and
no norm choice removes it). First norm attempt (12-point) documented as superseded; my first
test comment claimed "(amp/5)^2" scaling for the sine's rectifier — WRONG, measurement replaced
it. `test-luc-permanence.R`'s flatness-gated control now runs seasonless, gate unloosened.

**Five test sites thought they had turned seasonality off by zeroing `seas_amp_*`** — inert on
the driver path; they now pin `seas_drivers = 0` (conservation, fluxes, conveyor, spinup, and
the seasonal-statistic instrument). `test-gradient.R` item 5 and `test-parity.R`'s strict
1e-15 arm instrument pre-driver logic and pin the sine likewise, each with the reason written
in. `ccx_spinup` zeroes BOTH seasonal paths (driver terms are zero-mean over a year but not at
the single t the isotope solve evaluates — left on, the operator is singular).

**Also this arc, earlier commits:** `sigma_d13c` retired / `rep_dC` added (`6219df7`), d13C
seasonality scored (`53efc93`), each with its own entry-level detail in the commit messages;
suite green at every step. **The objective and the model have BOTH changed; nothing is
comparable across 2026-08-18, and no headline number exists until the held refit runs.**

**Next driver candidate, identified in the same census (Marcus's question):** SST — currently
`sst_h + 0.8 × GMST`, could take observed hemispheric SST plus the climatological seasonal SST
cycle, which is the OCEAN half of the seasonal story (SPO's cycle is substantially oceanic;
the land-only drivers make `seas_T_amp_SH` fake it, and the d13C seasonal ratio can now
DETECT that mis-attribution because ocean seasonal flux carries no photosynthetic
fractionation). After the refit.

## 2026-08-18 (drivers, part 2) — SEASONAL SST lands BEFORE the refit (Marcus), and a SH phase bug is caught before it could calibrate

**Marcus overturned the "SST after the refit" ordering, and the argument is refit economics
plus attribution**: a land-only refit would calibrate `seas_T_amp_SH` to fake the ocean's
contribution at SPO, and the post-SST refit would have to un-learn it. Reversed; both halves
of the seasonal cycle now calibrate together.

**A REAL BUG CAUGHT WHILE DESIGNING THE SST PHASE GEOMETRY**: the seasonal land-temperature
sine had NO hemisphere phase flip — SH respiration was modulated as if austral summer were in
July. The insolation side was correct (the declination formula antiphases at −30°); only the
T sine was wrong. **And the sampler could never have repaired it**: `seas_T_amp_SH` is
log-transformed, positive-only, so the refit's only recourse would have been shrinking the SH
amplitude to zero — a wrong-phased mechanism quietly zeroing itself out. Fixed in both cores
with a hemisphere sign (the norm is sign-invariant by symmetry); verified mid-Jan/mid-Jul
respiration factors NH 0.56/1.28, SH 1.18/0.78.

**Seasonal SST**: `sst += ±sst_seas_amp_h · sin(2π(t − (3.5 + CCX_SST_SEAS_LAG)/12))`, lag
2.5 mo (ocean inertia > land's 2.0), under the SAME `seas_drivers` switch — so spinup's
zeroing covers it and `seas_drivers = 0` remains the exact pre-08-18 model (rds gate re-run:
0.000e+00). Zero-mean driver; the annual-mean pCO2 shift through carbonate nonlinearity is
ACCEPTED as physics, the same call as the fertilisation rectifier. **Params 19 → 21**
(`sst_seas_amp_NH/SH`, log, shrinkage priors at rough climatology ~2 K / ~1.2 K — the
seasonal streams, including the newly scored d13C whose ocean flux carries no photosynthetic
fractionation, apportion land vs ocean). Parity 1.45e-15.

**Probe at (uncalibrated) defaults**: the ocean term OPPOSES the land cycle in the NH — MLO
box amp 4.77 → 4.41 ppm, toward the observed 3.02 — and adds at SPO (0.90 → 1.09 vs obs
0.55); apportioning is the refit's job.

**Deferred, needs a decision**: the OTHER half of the SST fix — observed hemispheric SST over
the historical record replacing `0.8 × GMST` — requires a data product choice (HadSST4 vs
ERSST) and a download into `data-raw/` + MANIFEST. Flagged, not resolved.

## 2026-08-18 (drivers, part 3) — Observed SST: HadSST4 historical + constant-ratio forward scaling (Marcus)

**Marcus: HadSST4 for the historical record.** The annual-mean SST is now the OBSERVED
hemispheric HadSST4 anomaly (v4.2.0.0, 1850–2025, re-based 1961-90 → 1850-1900 to match the
IGCC GMST convention) instead of `0.8 × GMST`; beyond the record it follows the gmst column
incrementally at fixed ratios, seam-matched over 10 years (never one year).

**The forward-scaling question (CMIP6 warming-level ratios vs constant obs ratios) was
MEASURED, not opined** (`calibration/diag_hemis_t_ratios.R`, HadSST4 + CRUTEM5 on IGCC GMST,
no intercept, common base): the ratio's window-to-window spread (SST_NH 0.61–1.10 across
1880–2024) is **forcing-pattern history — mid-century NH aerosols — not warming-level
dependence**, so neither option captures what drove the historical variation, and on
GHG-dominated futures the cheap option is defensible: last-30-yr ≈ full-record (NH 0.82 vs
0.79). **Adopted: constant last-30-yr ratios (NH 0.819, SH 0.762) as named constants**, with
`ccx_sst_anom_from_gmst()` the single seam where a CMIP6-derived scaling can drop in later.
CMIP6 effort estimate: ~a day from pre-digested sources (check the FaIRtoFrEDI PAI pipeline
first), a week+ from raw ESGF — deferred. CRUTEM5 land ratios (NH 1.54, SH 1.14) measured and
MANIFESTED for the same question; **land-T into q10 is NOT wired** (a further structural
change, not ordered).

**Plumbing**: `forcing_sst.rds` (new builder + 4 MANIFEST rows incl. CRUTEM5);
`sst_anom_{NH,SH}` forcing columns (appended LAST, N_FORCING 12 → 14; NaN = absent → legacy
fallback); `sst_obs` structural switch (default 1; **absence-default 0** so old parameter
lists run the model they were fitted to); `ccx_run_coupled()` re-derives the columns after
EVERY gmst update so the coupled future follows the evolving climate; **`ccx_hold_climate()`**
replaces the hand-rolled `F$gmst <- F$gmst[1]` idiom at 7 sites (tests + diagnostics) because
a "frozen climate" that leaves real SST warming in the columns is frozen in name only; the
`warming_feedback` mechanism switch sets `sst_obs = 0` — zeroed `sst_scale` alone would have
HALF-removed the response it claims to remove.

**Caught by the probe, worth recording:** first full-run R↔C++ parity came back at **9e-4** —
the pure-R runner's per-step forcing list is an explicit field list and did not carry the new
columns, so R ran legacy while C++ ran obs. One line; parity back to 1.1e-15. The absence
contract cuts both ways: a column the matrix carries but the list omits is a silent model
fork.

**Effect at defaults**: recent-mean CO2 moves −0.06 ppm (the 0.8 scale was itself fit to this
record); the gain is the interannual structure and the hemispheric asymmetry, which the
gradient and d13C streams can now see. rds gate still 0.000e+00 (sst_obs pinned 0 in the
mode-reconstruction diagnostics).

## 2026-08-18 (pre-refit) — The Hessian step is validated at 21 parameters, and the check finds a KINK in `h_ml`

**Marcus released the refit hold with one condition: check `ARM_HESS_EPS` at the new parameter
count first.** `calibration/diag_hess_eps_21par.R`. The step survived; the check did not come
back empty.

**Why the check was worth an hour.** The two-arm comparison's primary statistic is a Laplace
evidence, whose distinguishing term `-0.5 log|-H|` is computed from ONE fixed central-difference
step. The driver does not sweep it: a non-PD Hessian degrades that arm's evidence to `NA` and the
~11 h buys a comparison that cannot be made. Three things had changed since 3e-4 was last
exercised — 18 → 21 parameters with six coordinates that did not previously exist; `rep_dC` on the
IDENTITY scale with the smallest curvature in the table (the roundoff-vulnerable case); and `h_ml`
bounded to [85, 120], a logit support 4.9× narrower than the shipped [30, 200], i.e. a different
unconstrained scale, and a step size is a statement about a scale.

**Method.** No mode exists on the post-08-18 model, so the sweep runs at TWO points instead of
guessing one: `init` (where both arms start) and `lifted` (the adopted arm-N mode's 15 surviving
parameters, defaults for the 6 new — NOT a mode of anything, but physically different in the 15
directions carrying most of the curvature). Six steps, 1e-5 to 3e-3. A step failing at either
point is disqualified for 1 minute of compute instead of 11 hours; passing at both is not proof
it holds at the mode. That asymmetry is the design.

**VERDICT: `ARM_HESS_EPS = 3e-4` KEPT.** Inside a stable window (rel. spread < 0.25) at both
points for every coordinate whose curvature is a step-size question at all — 18/21 at `init`,
19/21 at `lifted`. The exclusions are named rather than swept: `sst_seas_amp_NH` (both points) and
`pump_grad` (init) have POSITIVE, step-STABLE curvature, which means only that neither probe point
is a maximum in that direction — a category the first draft of the verdict conflated with
step-size failure, and the table now splits. **The 1e-5 end is genuinely bad and should never be
used**: it moves `gamma_enso` by 7× and flips the sign of `kz`.

**THE FINDING — `h_ml` IS NOT A STEP-SIZE PROBLEM. IT IS A KINK.** Its second difference scales as
**1/eps across six decades** (−170,900 at 1e-5 → −578 at 3e-3, a factor 3.0 per factor 3.0 of
step). A discontinuity in the VALUE would scale as 1/eps²; roundoff would not scale at all. 1/eps
is the signature of a continuous function with a discontinuous FIRST derivative — confirmed
directly, the one-sided slopes at h_ml = 100 are **−16.21 and −17.92**, each stable over six
decades.

**Traced to `ccx_pump_shape()`, and it is NOT a bug.** The observed 25 m GLODAP DIC bins are
remapped onto model layers by overlap integration, `pmax(0, pmin(b, bot) - pmax(a, top))` — the
conservative, correct way to do it. But `h_ml` IS the first layer boundary, so as it moves the
clamp switches on and off against fixed observed bin edges, and a clamped overlap is a |x|.
**It reaches the isotopes and not CO2**, which is the pump's own signature: in `pump_mode = N` the
export is constant-mass, so `d13c_level_MLO`/`_SPO` carry **−0.153 / −0.115** of the −0.270 total
slope jump while `co2_level` carries −5e-4. Same channel as the pump × advection reversal.

**The structure is SPARSE, which is why this is a caveat and not a blocker.** Derived from the
shape function alone, no model runs: exactly **three kinks in [85, 120] — h_ml = 98.41, 100.00,
101.29 m** (5 of 3499 probe points; smooth in between). They are the first three layer boundaries
crossing the 100 / 150 / 225 m bin edges. `ARM_HESS_EPS` reaches ~2e-3 m of h_ml, so a mode must
land within ~2 mm of one to contaminate the row.

**`ARM_HML_INIT = 100` sits EXACTLY on the largest kink** — an unlucky coincidence with the pump's
own reference depth. **Left at 100 deliberately**: Nelder-Mead is derivative-free, so the start
point's differentiability is irrelevant, and moving it would change the refit trajectory for no
gain.

**What was NOT done, stated so it is a choice and not an oversight.** Smoothing the remap (PCHIP
through bin midpoints instead of overlap averaging) would make the objective C1 in `h_ml` — but it
changes the pump field, i.e. the MODEL, on the eve of a refit, to remove a risk of order 1e-4.
Rejected. Raised for Marcus as a standing item, not actioned.

**Driver hardened instead** (`run_modefind_pump_arms.R`), all at the driver level so the objective
is untouched:
1. The kink list is **DERIVED in-driver** from `ccx_pump_shape()`, not typed, so it cannot drift
   from the code that creates the kinks; a count ≠ 3 prints a re-run warning.
2. **Kink-proximity check at the found mode**, with `ARM_HESS_EPS` converted from the
   unconstrained scale to METRES at wherever in the band the mode actually sits. A straddle prints
   loudly that this arm's `log|-H|` and Laplace evidence are not reliable.
3. **Diagonal step-stability re-measured AT the mode** (eps × 1/3, 1, 3) — the pre-refit sweep
   could only run at non-modes; this is the same test at the point that carries the evidence.
   Unstable coordinates are named rather than silently entering the determinant.
4. All of it recorded into each arm's `.rds` (`hess_eps`, `hess_diag_by_step`, `hess_unstable`,
   `hml_kinks`, `hml_kink_gap`, `hml_hess_reach`, `hml_kink_hit`) so a later reader need not take
   `log|-H|` on faith.

Suite at the time of the check: **FAIL 0 | WARN 55 | SKIP 2 | PASS 889** (884 + 5 from the SST
commits).

### 2026-08-18 (refit in flight) — runtime measured at 3× the planned figure; the 20-parameter modes snapshotted before they could be overwritten

**The driver header's "~5-6 h per arm" is wrong at 21 parameters.** Measured on the running
job: **100,010 evaluations in 4 h 28 m = 0.161 s/eval**, against the 0.060 s/eval the header
carried from the 18-parameter refit. At 20 restarts × `ARM_MAXIT` that is **~18 h per arm,
~36 h for the pair**. What changed since 0.060 was taken: 18 → 21 parameters, two new
likelihood streams (the d13C seasonal pair), driver seasonality on BOTH land and SST, and
observed-SST columns re-derived per draw. Header corrected in place, with the old figure kept
beside it because the comparison is the point.

**Marcus's call: let it run** (sequential, ~36 h) rather than restart. Recorded because the
sequential-arms argument in the header does NOT survive measurement — the running arm's RSS is
**158 MB**, not the near-half-of-16-GB the swap-thrashing worry assumed, so two concurrent arms
would be ~320 MB and would halve wall-clock. The arms stay sequential for this run by decision,
not because the reasoning holds. That is the first thing to change if a future refit is
wall-clock bound.

**The 20-parameter modes were snapshotted before the run could overwrite them.**
`run_modefind_pump_arms.R` writes `mode_fit_pump{N,D}.rds` and `pump_arms_comparison.rds` to
FIXED paths, so the in-flight job would have replaced this morning's modes in place —
**including the arm-N mode Marcus provisionally adopted**, and the source of the `lifted` probe
point in `diag_hess_eps_21par.R`. Copied to
`calibration/output/pump_arms/pre_refit_20260818d/` with a README stating what they are, that
they are modes of a DIFFERENT objective, and that no logL / evidence / per-stream number may be
compared across the 20 → 21 boundary. Caught after launch, not before — the fixed-path write
should have been checked against the quarantine discipline first.

**Progress at the time of writing:** arm N, restart 5 of 20, no flags fired. The gain sequence
is NOT decaying monotonically — 33.4, 26.7, 9.2, **20.2** — so an early-convergence estimate
from the first few restarts is not reliable, and hitting the restart cap while still gaining
remains a live possibility.

## 2026-08-20 — THE 21-PARAMETER TWO-ARM REFIT LANDED. Both arms non-converged, the arms are near-identical in parameters, D's gain is now ENTIRELY THE SEASONAL ROWS — and the tail crashed on an operator error

**Run:** launched 2026-08-18, finished 2026-08-20. Arm N 907.6 min / 377,286 evals; arm D
1049.8 min / 380,746 evals. **~32.6 h total**, against the header's original 11 h — see the
2026-08-18 runtime correction.

### The operator error, first, because it shaped what had to be rebuilt

**`run_modefind_pump_arms.R` was edited WHILE IT WAS RUNNING** (the runtime-header correction,
`9f5bf71`) on the stated but false premise that "the running R process already has the script
parsed". **Rscript parses INCREMENTALLY.** Inserting ~15 comment lines near the top shifted every
later byte offset, and the process resumed mid-expression ~30 h later:
`Error: unexpected symbol in: "  dd <- sort(dd[is.finite(dd) & abs(dd) > 0.5]..."`.

**What survived, which is nearly everything**: both arms had already finished and written
`mode_fit_pump{N,D}.rds` (29 fields each — modes, Hessians, per-stream decompositions, and the
new kink/step-stability records), and the COMPARISON block had already printed in full to the
log. **Lost: the standing-questions print and `pump_arms_comparison.rds`** — a repackaging of the
two arm files carrying no information they lack.

**Rebuilt by `calibration/finish_pump_arms_comparison.R`**, which reads ONLY the two rds files and
re-derives the tail, so it cannot introduce a number the run did not produce. It also gates that
the two files are the same run (same params, same seed, right arms) before comparing, since they
sit at fixed paths any later run overwrites.

**RULE: never edit a script a long job is executing. Copy it and edit the copy.**

### Results

**BOTH ARMS HIT THE RESTART CAP WHILE STILL GAINING — neither mode is converged.** And they did
not stop in the same condition: at the cap N was gaining **0.45–1.24** per restart, D **0.10–0.12**.
**N is the further from its mode**, and that asymmetry runs in D's favour — the
`match_incumbents_optim` failure mode, where a less-optimised challenger buys a margin that is
search residue. BFGS then gained **31.3 (N)** and **35.2 (D)**, an order more than any single
restart, confirming Nelder-Mead was well short in both.

**LAPLACE log-evidence D − N = +10.61** (MAP +10.69, 0.5 log|-H| +0.08). **NOT quotable**: two
non-converged modes, `kz` pinned in both, and the optimisation asymmetry above points the same way
as the margin.

**THE ARMS ARE NEAR-IDENTICAL IN PARAMETERS — the strongest result of the run.** Every one of the
21 coordinates agrees between arms within ~0.1 prior-sd except `h_ml` (0.8σ; 95.66 vs 88.39 m).
**A structural switch that leaves 20 of 21 coordinates inside a tenth of a sd is not being resolved
by these data.** That is the pre-registered reading for a close comparison, and it rests on
parameter agreement rather than on an evidence difference computed from two bad Hessians.

**THE PER-STREAM READING REVERSES AGAIN, and this is new.** Pre-refit it was "D's gain is entirely
the CO2 record"; the 08-18 morning refit made it "CO2 ties, δ¹³C levels (N) vs sinks+¹⁴C (D)".
**Now D's gain is ENTIRELY THE SEASONAL ROWS**: `co2_seasonal_MLO` **+12.68**, `d13c_seasonal_SPO`
+9.56, `d13c_seasonal_MLO` +5.45, `co2_seasonal_SPO` +4.36 — **+32.1 of seasonal** — against
`gcb_ocean_sink` −7.36, `d14c_SH` −4.67, `d13c_level_MLO` −3.14, `d14c_NH` −2.88, `co2_icecore`
−2.42. CO2 levels essentially tie (+1.10 / +0.57). The arms now differ where the 08-18 rework
added the new physics.

**FIVE PARAMETERS BEYOND 3σ, AND THE SAME FIVE IN BOTH ARMS** (N / D):

| parameter | N | D |
|---|---|---|
| `rep_dC` | **+6.44** | **+6.67** |
| `sst_seas_amp_NH` | **−6.03** | **−6.06** |
| `sst_seas_amp_SH` | **−4.72** | **−4.63** |
| `seas_T_amp_NH` | **+3.83** | **+3.78** |
| `bomb_total` | **+3.24** | **+3.33** |

Reproducing to two decimals under a different pump structure makes these **structural, not search
artifacts**.

1. **THE SST SEASONAL AMPLITUDES ARE BEING DRIVEN TO ZERO** while the land respiration
   counter-cycle inflates. Both are log-transformed and positive-only, so negative z = shrinking
   toward zero — **the same signature as the SH phase bug caught on 08-18**, where a wrong-phased
   mechanism could only zero itself out because no sampler could repair a log-amplitude. The
   seasonal cycle is being carried almost entirely by land. **NOT diagnosed — a hypothesis with
   tests attached** (phase check at the mode, hemisphere-flip/sign geometry vs
   `ccx_sst_anom_from_gmst()`, and an iso-observable profile of `sst_seas_amp_NH` with the land
   terms frozen). That the arms differ mainly in the SEASONAL rows makes this the priority.
2. **`rep_dC` at ~6.5σ is past the threshold its own design tried to make unaffordable.** The
   parameter-table comment sizes the d13C common-mode bias at ~4.2 sd and argues the
   N(0, 1.0 ppm) prior "resists a structural error wearing its clothes". It went further anyway,
   so on this evidence it IS absorbing the Suess overshoot — the outcome choosing `rep_dC` over a
   free d13C offset was meant to prevent. Directly on Marcus's isotopes-first priority.

**Standing questions answered.** `kz` PINNED in both (98.8 % / 98.2 % of the re-bisected bracket)
— §5.2h P2 confirmed again. `h_ml` INTERIOR and the gradient rows LIVE in both (95.66 / 88.39 m).
`pump_grad` 310.71 (N) / 319.23 (D), both **above** the 233.11 prior centre and above the old 1-D
optimum of 274.5 — moved from the prior, not sitting on it.

**The Hessian checks added this session earned their place.** `h_ml` was clear of the kinks in
BOTH arms (gaps 2.75 m and 10.02 m against steps reaching 2.2e-3 and 9.2e-4 m), so the kink
caveat did not bite. But step-stability flagged **`kz` in N, and `h_ml` AND `kz` in D** — D's
`h_ml` sits 3.4 m off the band's lower bound, so its curvature reads the bound, not the data.
**D's log|-H| therefore has two unreliable rows to N's one**, which is a further reason the +10.61
is not a number to quote.

## 2026-08-20 (post-refit diagnostics) — The seasonal PHASE is 1–2 months late; `rep_dC` is a CO2 LEVEL bias, not a δ¹³C sink. TWO OF MY OWN READINGS OVERTURNED.

Marcus asked for the SST-zeroing and `rep_dC` questions to be measured.
`calibration/diag_sst_seas_zeroing.R`, `calibration/diag_rep_dC_pinned.R`.

### The seasonal phase — and the correction that matters most

**MY FIRST READING, "degeneracy, not a phase bug", WAS WRONG, and so was the line the script
printed.** That direction test compared **amplitudes only**. `ccx_year_harmonic()` returns sin
and cos coefficients, so every seasonal row scores **amplitude AND PHASE**. Moving
`sst_seas_amp_NH` from its fitted 0.089 K to the physical 2.0 K, per stream: **`co2_seasonal_MLO`
−673.4**, `co2_seasonal_SPO` +88.7, `d13c_seasonal_MLO` +29.4, `co2_level_MLO` −1.1 — while the
peak-to-peak amplitude *improves*, 5.30 → 3.89 ppm against obs 3.02. **Amplitude gets better and
phase rotates away.** The script's conclusion line is rewritten to refuse that verdict.

**The annual-mean rectifier hypothesis is also dead**: mean CO2 1990–2014 moves 379.41 → 379.35
ppm, and `co2_level_MLO` pays only −1.1.

**MEASURED PEAK MONTHS** — NH: seasonal SST **Oct** (expect Aug–Sep), land seasonal T **Sep**
(expect Jul), insolation/NPP **Aug** (expect Jun–Jul). SH: Mar / **Mar** (expect Jan) / **Feb**
(expect Dec–Jan). **Systematically 1–2 months late in both hemispheres.** The `(3.5 + LAG)/12`
convention puts the zero-lag land-T peak at mid-July and `CCX_SEAS_T_LAG = 2.0` pushes it to
mid-September, while the constant's own comment says "seasonal land T peak after Jun" — August.
Code and stated intent disagree by ~1 month. *(The "expected" column is a statement of
climatology and should itself be checked against HadSST4's monthly climatology, which the repo
has.)*

**THE EXISTING GATE CANNOT CATCH IT**: the 08-18 verification checked mid-Jan vs mid-Jul
respiration factors (NH 0.56 / 1.28), and both sit on the same side of a 1–2 month phase error.
`mutation_test_gates` again.

**The profile is an INTERIOR optimum, not a rail**: Δlogpost −165 at 1e-4 K, −2.6 at 0.05,
fitted 0.089, −13 at 0.25, **−513 at 2.0 K**. So the likelihood genuinely wants ~0.09 K and the
mode-find is not at fault — **the −6σ is against the PRIOR**. A parameter can sit deep in its
prior tail *and* at a clean likelihood optimum; those are different statements.

**`seas_T_amp_NH` = 48.07 K is a degeneracy with `q10`**, which fell 2.2275 → **1.2613**. Only
the product enters; the realised respiration swing is **9.3×**, peaking in **September** —
consistent with the phase lateness. 18c §5.1's watch-item resolving into an unphysical corner.
Neither parameter is individually interpretable at this mode.

### `rep_dC`

**MY SECOND WRONG READING: "it is absorbing the Suess overshoot".** Fitted **+5.9554 ppm ≈ 6σ**;
pinning to zero costs **3,959 log-units**; and it pays in ALL FOUR level streams —
`co2_level_SPO` **+1082.0**, `co2_level_MLO` **+1072.3**, `d13c_level_MLO` +950.8,
`d13c_level_SPO` +605.2. The criterion registered before the numbers was that a bias sink pays in
δ¹³C and **CHARGES** CO2. **It pays hugely in CO2, so it is not that signature.**

**The reading: the mode carries a ~6 ppm roughly uniform CO2 LEVEL bias, and `rep_dC` is the only
free parameter that shifts CO2 level directly.** The δ¹³C partner offset (−0.2917 ‰ via the
measured −0.04898 ‰/ppm coupling) rides along and helps too. Profile is a clean interior optimum
(−138 at 5 ppm, +1.8 at 6 ppm, −66 at 7 ppm), so the data really do want it. Connects to the
standing `ccx_co2_level` and `ccx_luc_input` threads; some share is incomplete optimisation.

**Note the prior's sizing argument failed in an unexpected direction.** `R/calibrate.R` predicted
absorbing the d13C bias would "drag the CO2 level stream 4 ppm off its own fit" — it expected CO2
to be the victim. CO2 is the beneficiary. The prior resisted the failure mode it was designed
against and lost to a different one.

**Also fixed**: `diag_rep_dC_pinned.R` read `p$bomb_total` / `p$luc_scale` from
`ccx_default_params()`, where neither is a field — same class of bug as the earlier `rep_dC`
lift. Now reads `md$par_mode`.

### N vs D — a reason beyond fit

DESIGN.md line 723 labels them **`"N"` nutrient-limited (mass fixed) / `"D"` DIC-limited**.
Marine export is limited by N/P/Fe, not carbon, so N is the conventional box-model assumption;
D implies export rises with DIC, a negative CO2 feedback mainstream models do not carry.
*(Conventional position, NOT backed here by a citation — check before publishing.)*
**Pedagogically**, DESIGN.md line 740: a constant-mass pump changes the ocean sink by **exactly
zero** and D does not, so N keeps "the pump sets the gradient, not the uptake" true for the app.
**Recommendation: keep N — as the defensible default, not as the winner of a comparison.**

## 2026-08-20 (later) — The seasonal-phase hypothesis fails its own decisive test, and the observed amplitude reference was a factor of 2 out

Handoff `handoff_2026-08-20_refit_landed_seasonal_phase.md` §3a named one test as the one
that would settle whether the seasonal geometry is a bug: compare the MODELLED MLO CO2
seasonal phase against the OBSERVED phase the likelihood already scores. It ran, and it
went against the hypothesis.

**`calibration/diag_seasonal_phase_obs_vs_model.R` (new).** Same estimator on both sides
(`ccx_seasonal_target()`, `LIK_SEAS_WINDOW` = 1975–2024); `a·sin + b·cos` peaks at
`atan2(a, b)/2π`, which is the whole conversion.

- **The scored observable is NOT 1–2 months late.** At the arm-N mode the model peaks
  **0.09 months (2.7 days) EARLY** at `co2_seasonal_MLO`; SPO −0.51 mo, `d13c_seasonal_MLO`
  +0.40 mo, `d13c_seasonal_SPO` −0.21 mo. Every scored stream is inside half a month. The
  drivers being late does not propagate to what the likelihood sees.
- **Cost decomposition** (each row's own Gaussian cost, re-evaluated at the observed phase
  with the model's radius, and at the observed radius with the model's phase): three of the
  four seasonal rows are **AMPLITUDE-dominated** — `co2_MLO` 228 vs 58, `co2_SPO` 116 vs 63,
  `d13c_SPO` 361 vs 35. Only `d13c_MLO` is phase-dominated (202 vs 59).

**THE FACTOR OF 2, and it inverts the 08-18/08-20 reading.** `diag_sst_seas_zeroing.R`
compared PEAK-TO-PEAK model amplitudes (`2·mean(sqrt(a²+b²))`) against "obs 3.02 ppm /
0.55 ppm / 0.178 ‰", which are the SEMI-amplitudes. Peak-to-peak observed is **MLO 6.764,
SPO 1.196, d13C MLO 0.358** — and the raw NOAA monthly climatology (`co2_ppm − co2_deseas`,
1990–2014) independently gives an MLO peak-to-trough of **6.61 ppm**. So:

- The model **UNDERSHOOTS** MLO (5.24 vs 6.76, −22 %); it does not overshoot.
- "Two mechanisms with the same sign of effect on the dominant stream ⇒ degeneracy" fails
  with it. The ocean seasonal term is zeroed because it **damps an already-too-small cycle**
  (5.28 off → 5.24 fitted → **4.50** at the physical 2.0 K, i.e. further below obs) — no
  phase bug required. The −673 on `co2_seasonal_MLO` is amplitude AND phase both moving the
  wrong way, not "amplitude improves while phase rotates away".
- Correction block + named `SSTZ_OBS_P2P` constants added to `diag_sst_seas_zeroing.R`; the
  original premise is left in place and marked WRONG rather than rewritten. The inline
  literals are what let a factor of 2 survive — *labels derive from named constants*.

**`calibration/diag_seas_lag_profile.R` (new) — the convention is RIGHT and the COMMENT is
wrong.** `CCX_SEAS_T_LAG` / `CCX_SST_SEAS_LAG` are compile-time constants with hardcoded
twins in `src/ccx_core.cpp` (`static const double`), so each point needs a source patch, a
rebuild and a fresh process; the script does this in a `tempdir()` copy and never touches the
working tree, and gates that the patch took before spending a run. At the mode, seasonal-row
logL:

| `CCX_SEAS_T_LAG` | 0.0 | 0.5 | 1.0 | 1.5 | **2.0** | 2.5 | 3.0 |
|---|---|---|---|---|---|---|---|
| seasonal logL | −19466 | −10841 | −4764 | −1411 | **−521** | −1507 | −3650 |

The shipped 2.0 is a clean **interior optimum**, beating the "climatologically correct"
mid-July peak (LAG = 0) by **18,944 log-units**. The slice is biased toward the incumbent
(`match_incumbents_optim`: fitted incumbent, un-reoptimised challengers, which bought 309
log-units of artifact last time) — but 19,000 is not 309, and the profile is smooth and
single-peaked at the shipped value. **The constant multiplies SOIL respiration through
`q10`, not air temperature, and soil temperature genuinely lags air temperature by weeks to
months — so a September peak is defensible and the comment ("seasonal land T peak after
Jun") is what is wrong.** `CCX_SST_SEAS_LAG` is nearly FLAT (−490 to −532 across 0.5–3.5 mo)
— unidentified at this mode, which follows from `sst_seas_amp` being ~0.09 K.

**Abandoned:** the plan to fix `(3.5 + LAG)/12` and redo the ~33 h refit. The data reject the
"corrected" phase by four orders of magnitude in log-units. Open decision 1 is answered NO.

**Not done:** Torch. `ssh torch` reaches `login.torch.hpc.nyu.edu` through the gateway but
the final hop is refused (`Permission denied`, agent has no identities), so R availability
and version there are still unmeasured. Noted for Marcus rather than worked around.

**Scale note for the Torch question anyway:** one full 1750–2024 monthly run plus its
per-stream likelihood is ~2 s, and 14 patch-rebuild-evaluate points took 32 s wall clock. The
32.6 h refit is Nelder-Mead's eval COUNT, not per-eval cost — which is exactly why §6's
parallel dispersed multi-start is the right restructuring rather than a port.

## 2026-08-20 (later still) — Torch verified; and an `h_ml` "corruption" that was my reader, not the files

**Torch works end to end.** R 4.5.1 under SLURM (the `/share/apps/r/4.5.1` wrapper is a
Singularity container binding `${SLURM_TMPDIR}/rtmp-$$` onto `/tmp`, so it **fails on login
nodes** and must be run through `sbatch`); `src/ccx_core.cpp` compiles in 4.1 s; Rcpp 1.1.0,
Matrix 1.7.4, testthat 3.2.3 present, **`adaptMCMC` missing**. **Torch reproduces the Mac's
logpost to all 9 decimals** on an identical subset. Per-eval the **Mac is ~2x faster** (0.141 s
vs 0.294 s) — Torch's case is core count, not per-core speed. Probe at
`/scratch/ms17839/ccx-probe/`, job 16075825.

**The false alarm, recorded because the reasoning is the point.** Recomputing the arm modes'
log-posteriors from `u_mode` gave +2.38 (N) and −42.93 (D), flipping the D − N margin from
+10.69 to −34.63 — deterministic, asymmetric, localised to `h_ml` alone. I wrote it up as a
corrupt artifact. **It was not.** `run_modefind_pump_arms.R` overrides `CCX_PARAM_TABLE$h_ml`
in-process to `ARM_HML_BOUND = c(85, 120)` (Marcus 2026-08-16g, with GATE H1), the repo default
is `[30, 200]`, and **the rds does not record the band**. Under the refit's band
`ccx_unc_to_par(u_mode)` reproduces `par_mode` to **0.000e+00** for all 21 parameters in both
arms and both log-posteriors reproduce to ~5e-10, margin exactly +10.6914.

**Pinned by solving for it, not guessing:** two arms give two equations
`x = lo + plogis(u)(hi − lo)` in two unknowns → `lo = 85.0000, hi = 120.0000`, i.e. the driver's
constant recovered from the stored numbers alone. Two independent pairs agreeing on one hidden
constant is proof; one pair would have been a hypothesis.

**Tried and discarded on the way** (each ruled out by measurement, none of them the cause):
parameter-name reordering (`param_names` is identical to `CCX_PARAM_NAMES` in both files);
code drift (`git diff de771be..c9e2478 -- R src data` is empty); nondeterminism in the objective
(bit-identical on repeat); the untracked `data-raw/downloads/nuclear14c/` inputs (unchanged
since Aug 10 — they explain only the full-repo vs subset offset, 6.15 log-units); and a
`u`-mutating Hessian loop (it perturbs copies).

**The one real defect, and it is small:** the rds records `kz_bracket` but not the h_ml band.
Fix = store `hml_bound` in the `out` list and gate the round-trip on read. **Not applied yet** —
it changes the driver that produced the current outputs, so it waits for Marcus.

**Method lesson, promoted to memory:** "implausible result = bug" is right, but the bug can be
in the READER. The producing script documents this override at length and gates it; I indicted
the artifact before reading the producer. **`par_mode` is band-independent and always safe;
`u_mode`, `hessian`, `cov`, `sd_unc`, `eigen`, `logdet_negH` are u-space and band-dependent.**

## 2026-08-20d — Input-driver audit: the seasonal cycle is fitted where it could be measured

Marcus, opening the seasonal-amplitude work of handoff `2026-08-20c` §2: *"checking all the
input drivers to make sure we are using all available information (e.g. land versus ocean in
the southern hemisphere) is a first step."* Done as
`calibration/diag_driver_audit.R` — ten measurement blocks, no fitting. 889 tests still pass.

**The audit's finding, in one line: every seasonal driver in the model is a free parameter,
and none of them is read from data.** The emission side is exemplary (EDGAR fossil shares,
OSCAR time-varying LUC shares, GFED fire seasonality — all sourced and hemispheric). The
*climate* side of the seasonal cycle is not sourced at all.

- **No seasonal climatology exists anywhere in the repo.** HadSST4 and CRUTEM5 are both on
  disk as ANNUAL hemispheric ANOMALY series, and the monthly summary series of both products
  are anomalies too — an anomaly has its monthly climatology subtracted, so the seasonal
  cycle is removed by construction. `seas_T_amp_{NH,SH}` and `sst_seas_amp_{NH,SH}` cannot be
  checked against anything currently held. CRUTEM5 is tagged in MANIFEST.csv as "ratio
  diagnostics only, NOT yet a forcing", and that is still true.
- **Their priors are recollections, not measurements** ("NH flux-weighted seasonal land T
  half-amplitude ~10–14 K"; "hemispheric-mean SST cycles are ~2 K NH / milder SH"), and the
  fit went straight through them: `sst_seas_amp_NH` **−6.03 σ**, `sst_seas_amp_SH` **−4.72 σ**,
  `seas_T_amp_NH` **+3.83 σ** (48.07 K — a soil told its seasonal temperature swings ±48 K).
  The two largest prior-z in the whole 21-parameter vector after `rep_dC` are the two ocean
  seasonal amplitudes, both pinned at zero.
- **The ocean seasonal channel is off below the numerical noise of its own input.** Priced
  through the repo's own `SST_PCO2_SENSITIVITY`, the fitted `sst_seas_amp_NH` is 3.0 µatm
  peak-to-peak against 67.7 at the prior centre. Its 0.178 K peak-to-peak is the same order
  as the **0.066 K spline-interpolation wiggle** that `ccx_annual_to_monthly()` leaves in the
  annual `sst_anom_NH` column it sits on top of (block 7 projects that wiggle onto the scored
  annual harmonic: 0.025 K, so it does not alias into the seasonal rows — but nobody chose it).
- **Land versus ocean in the SH, as Marcus framed it, is worse than "unfitted".** The model's
  own geometry makes the SH **19.2 % land** and the NH **39.2 %** (NH holds 67.1 % of global
  land area). `npp_frac_NH` fits to **0.4662** — 53 % of global NPP on the ocean hemisphere,
  making **SH land 2.34× as productive per m² as NH land**. Its prior is UNIFORM[0.4, 0.8]:
  zero observational content on a quantity global NPP products resolve directly.
- **But the profile inverts the obvious story, and this is the useful part.** Raising
  `npp_frac_NH` toward physical values *helps* the NH deficit (`co2_seasonal_MLO` **+197 / +216
  / +160** at 0.55 / 0.60 / 0.65) and is vetoed by **`d13c_seasonal_MLO` (−463 / −835 / −1277)**,
  with `co2_seasonal_SPO` also paying. Net −312 / −794 / −1494. The NH NPP share is held down
  by the **NH δ¹³C seasonal cycle**, not by the CO₂ cycle.
- **Which points at a partition diagnostic needing no new data.** Photosynthesis moves CO₂ at
  −18 ‰; air-sea exchange at −2 (invasion) / −10 (evasion). So seasonal δ¹³C amplitude *per ppm*
  of seasonal CO₂ amplitude measures how photosynthetic the modelled cycle is, unit-free, both
  sides from the likelihood's own harmonic estimator in one expression (the
  `amp_definition_mismatch` rule):

  | station | CO₂ obs | CO₂ model | err | δ¹³C/CO₂ obs | model | ratio |
  |---|---|---|---|---|---|---|
  | MLO | 6.764 ppm | 5.242 | −22.5 % | 0.0529 ‰/ppm | 0.0809 | **1.53×** |
  | SPO | 1.196 ppm | 1.670 | +39.6 % | 0.0374 ‰/ppm | 0.0947 | **2.54×** |

  (The CO₂ column reproduces `diag_seasonal_phase_obs_vs_model.R` exactly — the estimator is
  the same one.) **The modelled seasonal cycle is 1.5× (NH) to 2.5× (SH) too isotopically
  depleted per ppm.** Too much of it is land, at BOTH stations — including the hemisphere
  that *undershoots* in CO₂. That is a partition statement the "NH too small, SH too big"
  amplitude table alone cannot make, and it is the reason the fit cannot fix the NH deficit
  by growing NPP: the isotopes see it.
- **Other unsourced hemispheric splits found by the same sweep** (block 10): `enso_share`
  hardcoded 50/50 in `ccx_aux()` with no comment and no source, when the interannual land-flux
  anomaly it drives is overwhelmingly tropical and GFED4.1s is *already on disk*;
  `FORC_NUC_NH_SHARE` 0.95 and `FORC_BOMB_NH_SHARE` 0.90 still PROVISIONAL; `OCEAN_AREA_{NH,SH}`
  still `provisional` / "NEEDS a cited geographic source"; `sst_{NH,SH}` = 18/16 °C fixed with
  no source while setting K0/K1/K2 and the Revelle factor; `CCX_SEAS_PHI_EFF["NH"] = 75°` an
  offline-fitted *effective* knob rather than a measured NPP centroid, and `["SH"] = −30°`
  asserted outright.

**Not done, awaiting Marcus:** no download was made and no parameter, prior or constant was
changed. The audit is measurement only.

## 2026-08-20e — The seasonal climatology, downloaded: the fitted amplitudes are wrong by 4× and 25×

Marcus, on the audit: *"Which products are most compatible with the IGCC historical data? …
If there are obvious winners, go ahead and pull them. I would actually do the ¹³C after the
downloads, because I think that getting this data right is necessary regardless."* Pulled;
¹³C decomposition deliberately **not** started. 889 tests pass, 0 fail.

**Product choice, on the IGCC criterion.** IGCC's GMST is a 4-dataset mean (HadCRUT5,
NOAAGlobalTemp, GISTEMP, Berkeley Earth). On the **ocean** side the criterion is decisive and
also, awkwardly, forced: **HadSST4 — the repo's own annual anomaly source, and HadCRUT5's
ocean component — publishes no absolute form at all**, so no absolute product can be
mask-consistent with what we already use. **ERSSTv5** is the best available: it is the ocean
component of **two of IGCC's four** datasets (NOAAGlobalTemp and GISTEMP). On the **land**
side there is a clean winner: CRU's `absolute.nc` is the *designed* absolute companion to the
CRUTEM anomalies already held — same 5° grid, same 1961–90 baseline.

Three files (`MANIFEST.csv` updated), built by `data-raw/build_seasonal_climatology.R` →
`data/obs_seasonal_clim.rds`; full provenance and caveats in **DATA.md §3b**.

**The comparison, block 11 of `diag_driver_audit.R` — half-amplitudes, K:**

| parameter | fitted | prior mid | **observed** | obs/fitted | prior-z |
|---|---|---|---|---|---|
| `seas_T_amp_NH` | 48.07 | 12.0 | **11.45** (>30N 15.7, >45N 17.9) | 0.2× | +3.83 |
| `seas_T_amp_SH` | 11.18 | 6.0 | **3.59** (>30S 7.1, >45S 9.0) | 0.3× | +1.25 |
| `sst_seas_amp_NH` | 0.0892 | 2.0 | **2.237** | **25.1×** | −6.03 |
| `sst_seas_amp_SH` | 0.0637 | 1.2 | **1.746** | **27.4×** | −4.72 |

**The priors were close to right and the fit rejected them anyway** (12 vs 11.4; 2.0 vs 2.24;
1.2 vs 1.75). This is not a mis-set prior. **Both land amplitudes are 3–4× too big and both
ocean amplitudes ~25× too small** — the same land-over/ocean-under signature the δ¹³C-per-ppm
ratio found independently on 08-20d (1.53× MLO, 2.54× SPO too isotopically depleted). Two
diagnostics, different data, same direction.

**A sourced correction to a constant that was never fitted.** Converting observed peak months
into the model's own `(3.5 + LAG)/12` units:

- `CCX_SEAS_T_LAG` shipped 2.00, observed NH land **air** T 0.04 — **not** a discrepancy. That
  constant multiplies *soil* respiration, `R/model.R` says so, and the 18,944-logL profile
  rejects exactly the air-temperature value. **Left alone.**
- `CCX_SST_SEAS_LAG` shipped 2.50, observed NH SST **1.32** — **a real one, and checkable**,
  because `sst_seas_amp` modulates SST itself rather than a lagged flux, so the observed SST
  phase *is* its phase. The shipped value is **1.18 months late** and `R/model.R` calls it "a
  prior belief", unidentifiable because the amplitude it phases is ~0. It no longer has to be
  identified from the fit. **Not applied — awaiting Marcus.** It bears directly on the −673
  logL that raising `sst_seas_amp_NH` to 2.0 cost on 08-20: part of that may be phase.

**Two structural assumptions the climatology also tests, both survive:** hemispheres are
antiphase to 5.78 mo (land) / 5.79 (SST) against the model's exact 6.00 — small and real; and
observed amp2/amp1 is 0.06/0.14/0.08/0.05, so the drivers really are near-sinusoidal and the
observed sawtooth must come from Q10 and the growing season, as designed.

**Three traps, each of which produced a plausible wrong answer first** (DATA.md §3b): (1)
`absolute.nc` is *spatially complete* with no `missing_value` — unmasked it gave an "NH land"
14.59 °C / 6.68 K, and the tell was NH and SH returning **exactly 1296 of 2592 cells each**;
(2) the two 5° grids run latitude in **opposite order** with matching dimensions, so an order
assumption would have masked Antarctica with the Arctic's coverage
(`nameless_matrix_order`); (3) full-cell-area weighting put "land" at **41.9 %** of the globe,
since a 5° cell with one coastal station counts as wholly land — now weighted by a land
fraction derived from ERSSTv5's own ocean mask (26.8 % vs a true ~29 %), which biases the land
amplitude *low*, the conservative direction.

**The NH/SH NPP split, asked in the same message: nothing on disk measures it.** GFED (fire),
OSCAR (land-use) and GCB (global sink) all speak to land fluxes, none to NPP's hemispheric
partition. And it is a **single scalar applied at 1750** (`npp_frac_NH`), not a time series:
the realised share evolves only through hemisphere-specific clearing, and barely — **0.4662
(1750) → 0.4600 (1850) → 0.4479 (1950) → 0.4466 (2024)**. Fertilisation is a common
multiplier at a given CO₂ and cancels out of the share entirely. No product pulled for this;
options are MODIS MOD17, TRENDY, or FLUXCOM, and the choice is Marcus'.

## 2026-08-20f — The ¹³C channel decomposition: the NH "deficit" inverts at observed drivers

Marcus: *"Once that is done, then start the 13C channel decomposition."* Done, plus the
2×3 factorial the downloads made possible. **889 tests pass, 0 fail**, including after a core
edit. Two new diagnostics, no refit.

**A core edit, with an identity default.** Two of the three seasonal channels could already be
switched off exactly by parameters (`seas_T_amp = 0`, `sst_seas_amp = 0`); the NEP channel
could not, because `CCX_SEAS_PHI_EFF` is a compile-time constant in `src/ccx_core.cpp`. Added
`seas_npp_amp_{NH,SH}` to both cores — a per-hemisphere multiplier on the seasonal NEP term,
**default 1 = the shipped model bit for bit**, absent-means-1 in `ccx_cpp_par()`, not in
`CCX_PARAM_TABLE` and never fitted. Same idiom as `seas_drivers` / `revelle_frozen` / `sst_obs`.
R↔C++ bit-parity re-verified at 1.7e-13.

### The amplitude budget (`diag_seas_channel_decomp.R`)

Contributions are **vector** differences of the scored (sin, cos) pair, not scalar amplitudes —
scalar reading is what made the 08-20 test wrong in both directions. **The channels sum to the
all-off case within 0.9 % (MLO) / 0.2 % (SPO)**, so the budget is genuinely additive.

MLO, peak-to-peak contribution and each channel's own δ¹³C-per-ppm signature:

| channel | ΔCO₂ ppm | peak mo | signature | (observed total: 0.0528) |
|---|---|---|---|---|
| NEP NH | 11.767 | 4.51 | 0.0636 | photosynthetic, as expected |
| resp NH | 7.708 | **11.09** | 0.0352 | **6.6 months antiphase to NEP** |
| air-sea NH | **0.050** | 11.21 | 0.0045 | 1 % of the cycle |
| emissions | 0.355 | 3.60 | 0.0495 | EDGAR/GFED, was not on the 08-20c channel list |
| **all six** | **4.955** | 3.47 | 0.0848 | |

**The two big land channels are each larger than the total and nearly antiphase.** They cancel.
That is the mechanism behind the 08-20b non-monotonicity ("more respiration swing gives LESS
MLO amplitude"), and it explains the isotopic excess: the cancellation suppresses net CO₂
amplitude *more* than net δ¹³C amplitude, so the model's net signature (0.0848) is **higher than
either contributing channel** (0.0636, 0.0352). The excess is a property of the cancellation
geometry, not of any one channel. Meanwhile the ocean channel — the only isotopically neutral
one available (0.0045) — contributes **0.05 ppm**, because it is fitted 25× below observation.

Turning the ocean channel off *improves* the objective (+11.8 NH, +7.2 SH): at its fitted
amplitude it is not merely inert but slightly harmful.

### The 2×3 factorial (`diag_seas_obs_drivers.R`)

Amplitude and phase varied **separately**, because the 08-20 amplitude-only test could not tell
them apart. `CCX_SST_SEAS_LAG` is compile-time, so this patches + rebuilds + runs in a fresh
process in a `tempdir()` copy (idiom from `diag_seas_lag_profile.R`), gating that the patch took.

| SST lag | amplitudes | seas logL | MLO p2p | sig MLO | sig SPO |
|---|---|---|---|---|---|
| 2.50 shipped | fitted | −576.7 | 5.309 | 0.0825 | 0.0963 |
| 2.50 shipped | ocean=obs | −2039.7 | 4.454 | 0.0973 | 0.0893 |
| 2.50 shipped | ocean+land=obs | −6590.4 | 8.778 | 0.0684 | 0.0815 |
| **1.32 observed** | fitted | **−558.0** | 5.297 | 0.0827 | 0.0977 |
| 1.32 observed | ocean=obs | −1399.2 | 4.114 | 0.1053 | 0.1641 |
| 1.32 observed | ocean+land=obs | −6883.6 | 8.805 | 0.0683 | 0.1037 |

*(observed: MLO 6.754 ppm, sig 0.0528; SPO 1.170 ppm, sig 0.0288)*

1. **The lag correction is real, free, and small: +18.7 log-units** for a constant that was
   never fitted. Confirms it is mis-set; the effect is small precisely because the amplitude it
   phases is ~0.
2. **Phase was 44 % of the ocean term's rejection.** The penalty for observed ocean amplitude
   falls from −1463 to −823 once the phase is right. The 08-20c §2d warning was correct — the
   amplitude-only test could not separate them — but **56 % of the rejection survives**, so
   phase is not the whole story.
3. **The headline inverts.** At observed land *and* ocean amplitudes the NH cycle **overshoots**
   — 8.78 ppm against an observed 6.754, +30 % — where the mode undershoots by −22 %. **The NH
   "deficit" is not a deficit of drivers.** It is what two over-large antiphase land channels
   look like after being tuned to cancel, with `seas_T_amp_NH = 48 K` (4.2× observed) doing the
   cancelling. Restore the observed 11.45 K and the cancellation weakens and the cycle blows up.
4. **The isotopes move the right way and do not close.** Observed drivers take the MLO signature
   0.0825 → 0.0684 against an observed 0.0528. So observed drivers genuinely improve the
   land/ocean partition — while breaking the amplitude, which the fit had been buying with them.

**Caveat, and it bounds every loss above:** these are profiles at a mode fitted **under the
shipped constants**, so the challengers are scored on the incumbent's home ground
(`match_incumbents_optim`). A loss is weak evidence against; the **+18.7 win** is strong evidence for.

**Next suspect, stated as a hypothesis:** `CCX_SEAS_PHI_EFF["NH"] = 75°` gives the NEP shape a
unit-mean peak-to-peak of **2.80**, which at 28 GtC/yr of NH NPP is a 78 GtC/yr swing. It was
fitted offline against MLO **under the pre-08-18 sine respiration**, and audit block 10 already
flagged it as an effective knob rather than a measured NPP centroid. If the NEP channel is
over-driven, that is where it comes from — and MOD17's higher NH NPP share (0.594 vs the model's
realised 0.446) would make the overshoot *worse*, not better, which sharpens the conflict.

**Two bugs found and fixed in the harness**, both silent-wrong-answer class: the worker copied
`diag_seas_lag_profile.R`'s `intersect(names(p), names(par_mode))` idiom, which **drops
`bomb_total`, `rep_dC`, `sigma_d14c` and `grad_off_*`** because `ccx_default_params()` has no
fields for them (that script never reads them, so never noticed) — now assigns every name and
asserts; and `system2(stderr = FALSE)` swallowed the resulting error into a row of NAs — now captured.

## 2026-08-20g — The measured drivers applied, on Marcus' standing instruction

> *"Keep adding in the more physically correct data even if it moves the fit in the slightly
> wrong direction."*

Acted on. **918 tests pass, 1 fails** — see the last section; the failure is diagnosed and left
standing rather than made to pass.

**`CCX_SST_SEAS_LAG` 2.50 → 1.32, both cores.** A measurement replacing a stated belief, in a
constant that was never fitted, and it *gains* +18.7 log-units. The C++ twin `SST_SEAS_LAG` was
changed in lockstep. **`CCX_SEAS_T_LAG` deliberately left at 2.0** — the climatology's NH land
*air* T lag of 0.04 looks like a discrepancy and is not, because that constant multiplies *soil*
respiration and the 18,944-logL profile rejects exactly the air-temperature value.

**The four seasonal amplitude priors re-anchored on the measurements.** Observations added to
`R/constants.R` as `data`-status scalars (the `PUMP_GRAD_OBS` idiom); priors in `R/calibrate.R`
now read them. **The land widths are derived, not chosen**: `ccx_bracket_lnorm()` builds the
lognormal whose ±1σ spans the measured area-weighted-to-boreal bracket, so the width *is* the
weighting ambiguity. NH uses all-land ↔ >45N; **SH uses all-land ↔ >30S, because >45S is
Antarctica and has no respiring soil to weight toward**. The ocean width `SST_SEAS_LOGSD = 0.25`
is a **stated judgement** covering the unmeasured area- vs gas-exchange-weighting gap, and lives
in `calibrate.R` rather than the constants registry because a prior width is a calibration
choice, not a physical quantity.

**⚠ This changes the objective.** `mode_fit_pump{N,D}.rds`: `par_mode` is still a valid
parameter vector, but `logpost`, `prior_z`, `hessian`, `cov`, `sd_unc`, `eigen`, `logdet_negH`
and the Laplace evidence now describe a posterior that no longer exists. **A refit is owed.**
The mode is far outside the new priors — log-prior −17.9 (`seas_T_amp_NH`), **−80.2 and −84.5**
for the two ocean amplitudes — which is the point rather than a problem: the fit was buying its
seasonal cycle with values the data exclude.

**Three self-inflicted failures found and fixed before reporting:** the new constants were
written as named length-2 vectors, which breaks the registry's `is.finite(k$value)` scalar
contract (`test-constants.R:18`, 3 assertions); and `SST_SEAS_AMP_LOGSD` as a `provisional`
constant would have forced an edit to the provisional-constant **ledger** (`test-constants.R:63`)
— avoided by putting the prior width where it belongs instead.

**One test left failing, deliberately: `test-fluxes.R:99`** (`on$tau_flux` vs `off$tau_flux`,
tolerance 1e-3, "seas excluded"). Passed at lag 2.5, fails at 1.32 (4.684 vs 4.692, rel 1.72e-3).
**Not modified — reported.** Diagnosed: `tau_turn` is not perfectly seasonality-free; the
discrepancy is **exactly 0** at `sst_seas_amp = 0` and scales with it (5.4e-5 at 0.089, 7.2e-4 at
1.0, 1.72e-3 at the default 2.0), so the leak is the seasonal SST term and the tolerance was
accommodating it. `tau_turn[1]` samples the **first month**, whose seasonal-SST factor goes
−0.2588 → **−0.7705** between the two lags (2.98×) — the whole of the move. **The tolerance was
silently encoding `CCX_SST_SEAS_LAG = 2.5`.** Options in the handoff §4d; evaluating `tau_turn`
on an annual mean instead of month 1 looks right, and would make the test stronger.

## 2026-08-20h — The NPP-weighted effective latitude, measured: 38.35 N, not 75

Handoff 20d §6 named `CCX_SEAS_PHI_EFF["NH"] = 75°` as the prime suspect behind the antiphase
NEP/respiration cancellation, on the argument that 75 N is far poleward of any plausible
NPP-weighted latitude. `calibration/diag_npp_eff_latitude.R` turns that impression into a number
from the MOD17 field already on disk — **no new download**.

**The measurement is a SHAPE match, not a weighted mean latitude, and the two differ.** The
constant does not enter the model as a latitude; it enters as the assertion
`NPP_h(t) = NPP_h · insol(φ_eff, t−lag) / mean insol`. Apply that same premise per grid cell and
aggregate with each cell's annual NPP as the weight; φ_eff is then the latitude whose own
normalised shape best matches the aggregate. Insolation is strongly nonlinear in latitude, so
this is **not** the NPP-weighted mean latitude — both are reported so the gap is visible.

| | φ | unit-mean peak-to-peak | rms resid |
|---|---|---|---|
| NH aggregate (MOD17-weighted) | — | **0.998** | — |
| NH shipped | 75.00 | **2.801** | 0.704 |
| NH shape-matched | **38.35** | 1.003 | 0.014 |
| NH NPP-weighted mean latitude | 34.29 | 0.871 | 0.049 |
| SH aggregate | — | **0.366** | — |
| SH shipped | −30.00 | **0.742** | 0.134 |
| SH shape-matched | **−15.75** | 0.366 | 0.002 |
| SH NPP-weighted mean latitude | −15.12 | 0.351 | 0.006 |

**The shipped constants over-drive the NEP seasonal shape by 2.81× (NH) and 2.03× (SH).** At the
arm-N mode that is a **78.4 GtC/yr** NH seasonal swing where the measured shape supports 28.1 —
against an observed MLO cycle worth ~14 GtC of atmospheric carbon peak-to-trough. This is the
over-driving that would *require* an over-large antiphase respiration channel to cancel it, which
is exactly the pair `diag_seas_channel_decomp.R` found.

**Phase carries no information about φ_eff, and the table looks like a bug until that is said.**
Daily-mean insolation is symmetric about the solstice at every extratropical latitude, so every
candidate peaks in the same month as the aggregate and every best time shift is 0. The
"phase-matched only" row is degenerate — it returns the lowest latitude whose peak still lands on
the solstice, a property of the tropics. **All the information is in the peak-to-peak**, and
`seas_lag_p` has nothing to absorb if φ moves. (The fit is nonetheless done lag-invariantly, by
FFT cross-correlation, and the FFT is **gated against a brute-force loop** rather than trusted.)

**⚠ WHAT THIS DOES NOT MEASURE, because MOD17A3HGF is an ANNUAL product.** It gives the *spatial*
distribution of NPP, not its seasonal cycle. So it cannot test the model's premise that NPP
follows insolation; it takes the premise as given and answers only the aggregation question.
If real NPP is instead strongly **rectified** (a growing season that switches on and off, which
boreal NPP is), then a poleward φ_eff is a legitimate *emulation of rectification* — and the
offline fit that produced 75 says as much, noting that "at 75 N the polar night rectifies the
growing season by itself". **So 38.35 is the honest reading of the constant's stated meaning, and
75 is defensible only under a different meaning that the constant's name and comment do not
claim.** Settling that properly needs a sub-annual product (MOD17A2H 8-day GPP); what the CO₂ and
δ¹³C data say about it is the profile below.

**Independent check on the read:** this script re-derives the global total and NH share from the
raw files by its own path and gets **52.75 PgC/yr, share 0.5938** against
`build_npp_hemispheric.R`'s 52.75 / 0.5942 (the residual is mean-of-ratio vs ratio-of-means).

## 2026-08-20i — The 8-day product: rectification is real, and it is not worth 75

Marcus authorised the sub-annual download. **MOD17A2HGF C6.1 8-daily**, same algorithm, same
ICDC 0.5° regrid, CC-BY-4.0, no registration (doi:10.25592/uhhfdm.14449); five years spread
across the record (2001, 2006, 2011, 2016, 2021 — 2022 absent upstream). It removes the premise
that 20h had to assume: the hemispheric aggregate seasonal shape is now **observed**, not
reconstructed from insolation, and φ_eff is fitted to that. Both `gpp` and `net_photosynthesis`
(PsnNet) are carried, as a **bracket** — GPP is less rectified than NPP so its φ is biased
equatorward, PsnNet is closer but still omits growth and live-wood respiration.

| | φ (shape) | sd yr | φ (amplitude) | obs p2p | unexplained |
|---|---|---|---|---|---|
| NH `gpp` | 49.26 | 2.62 | 54.60 | 1.699 | 10.8 % |
| NH `psnnet` | **49.96** | 2.93 | **55.49** | 1.747 | 11.4 % |
| SH `gpp` | −10.86 | 4.22 | −28.17 | 0.736 | 14.3 % |
| SH `psnnet` | **−16.14** | 2.67 | **−32.15** | 0.845 | 12.8 % |

**Both of 20h's readings were wrong, in opposite directions.** Rectification is genuine — the
observed NH shape sits ~11° poleward of the insolation-weighted aggregate, so a poleward φ was
never indefensible — but the shipped 75 over-drives the *observed* peak-to-peak by ~1.6× and the
annual-product 38.35 under-delivers it by ~0.6×.

**Shape and amplitude disagree, and neither is the whole answer.** No insolation shape can match
a rectified one: 11 % (NH) and 13–14 % (SH) of the observed cycle is residual that *no* single
latitude explains. The SH is the sharp case — shape wants −11 to −16, amplitude wants −28 to −32,
and the shipped −30 sits on the amplitude answer while getting the shape wrong. SH productivity
is tropical and water-limited, so the insolation premise is weakest exactly where the shipped
constant looked best.

**By-product: `seas_lag_p` is now measured.** Insolation peaks at the solstice at every
extratropical latitude, so the observed-productivity-minus-insolation offset IS that parameter.
NH **+0.8 to +1.0 months** against a fitted 2.17; SH **−2.1 to −2.9 months**, a *lead*. **One
global `seas_lag_p` cannot be both** — a structural limitation of the term, not a mis-set value.

**Gates.** Global totals 91.7 (GPP) / 59.3 (PsnNet) PgC/yr as the read-the-file check; and the
fitting operator is gated by recovering a known (φ, lag) from a synthetic target, because a
circular shift applied in the wrong direction returns a plausible φ with a sign-flipped lag and
no error. The model shape is **window-integrated**, not point-sampled, and the last composite of
each year is 5–6 days, not 8 — treating it as 8 inflates the winter end of the NH cycle, which is
the end that carries the rectification signal.

## 2026-08-20j — The φ_eff profile: 75 loses by ~390, but the hemispheres interact

`calibration/diag_phi_eff_profile.R`, 10 cases, each patching both cores, rebuilding in its own
tempdir, passing three gates, and **re-optimising the seven parameters the seasonal cycle
identifies** (`seas_T_amp_{NH,SH}`, `seas_lag_p`, `sst_seas_amp_{NH,SH}`, `npp_frac_NH`, `q10`)
on the full post-08-20g posterior. A frozen profile would have been worthless: moving φ while
holding `seas_T_amp_NH` at 48 K breaks the NEP/respiration cancellation by construction.

**The gate that matters was mutation-tested.** Disabling the C++ patch while leaving the R patch
in place makes the R-vs-C++ derivative parity check fire (`max|dR-dC|/max|dR| < 1e-12 is not
TRUE`), so a worker cannot run the incumbent's constant under a challenger's label.

**At the shipped SH, the shipped NH is rejected.** φ_NH = 75 scores −2576.0 against −2184.2 at
38.35 and −2187.3 at 45 — a **~390 log-unit loss**, and this is the challenger winning on the
incumbent's own ground rather than the reverse.

**And `seas_T_amp_NH` comes home.** Re-optimised it lands at 38.6 K at φ=75, 18.3 at 55,
**10.8 at 45** — against an observed **11.45**. The respiration channel returns to its measured
amplitude exactly where the data want φ, which is the strongest single piece of evidence that
the 48 K was buying cancellation for an over-driven NEP channel.

**But the 1D profile is a slice of a surface with an interaction, and it must not be read as the
answer.** Moving the SH from −30 to the measured −15.75 gains **+458.8** at φ_NH = 75 and only
+10.4 at 38.35 — enough to *reverse* the NH ordering, so (75, −15.75) is the best cell in this
set at −2117.2. The coupling is real: `seas_lag_p`, `q10` and `npp_frac_NH` are global, not
per-hemisphere. **The region everything else points at — NH 45–55 at SH ≈ −16 — was not tested**,
so a 2D fill-in pass is running before anything is concluded.

**This does bear on §5.** Re-optimised `npp_frac_NH` runs 0.459 at φ_NH = 75, 0.684 at 45, 0.728
at 38.35, and **0.619 at (38.35, −15.75)** — against MOD17's 0.594 and a self-consistent 1750
anchor of 0.5986. The audit's −794 veto on raising `npp_frac_NH` was **an artefact of φ = 75**:
de-amplify NEP and the fit asks for the observed share by itself.

**`sst_seas_amp_NH` is unmoved by any of this** — 0.33–0.54 at every φ, against an observed
2.237. The NH ocean channel's rejection is not a φ_eff problem.

**Caveat on convergence:** φ = 25 was still gaining at its third restart (+73.2) and its block is
pathological (`q10` 0.948, `seas_T_amp_SH` 101.9). That row is not trustworthy; the rest settle
to gains under 1 log-unit.

## 2026-08-20k — `npp_frac_NH` re-anchored on MOD17 (Marcus)

> *"This is a pedagogical product. As long as the approach is physically reasonable and uses as
> much of the observed data as possible, it is fine to make choices that are designed to make the
> model easier to calibrate and run."*

**Option (a) taken: a prior on the 1750 parameter, not a likelihood term on the modern realised
share.** The objection to (a) was circularity — the anchor is MOD17's *modern* share walked back
through the model's own clearing, so it rides on `luc_scale`. That objection is now **priced**
(`calibration/diag_npp_frac_anchor.R`) rather than argued:

| perturbation | anchor | Δ |
|---|---|---|
| **self-consistent fixed point** | **0.5986119** | — |
| `luc_scale` ×0.70 / ×1.30 | 0.597294 / 0.599930 | ∓0.00132 |
| `tau_soil_slow` ×0.70 / ×1.30 | 0.599789 / 0.597846 | ±0.0012 |
| `tau_wood` ×0.70 / ×1.30 | 0.598930 / 0.598334 | ±0.0003 |

**Every model-dependence is an order of magnitude below the 0.04 prior width**, and below MOD17's
own 0.0135 interannual sd. Option (b) — scoring the modern realised share — would have *relocated*
the circularity into a direct `npp_frac_NH`↔`luc_scale` correlation in the posterior, added a
likelihood stream and a per-draw readout, and made the model harder to calibrate, not easier.

**It is the FIXED POINT, not the audit's 0.6136.** The inversion is implicit — the cleared
fraction is `cum_luc / land0` and `land0` is proportional to `npp_frac_NH` itself — so evaluating
it at the incumbent's fitted 0.4662 is not self-consistent. Iterating gives **0.5986119**, and the
+0.0149 difference is **larger than every other model-dependence in the table**, which is why the
one-shot inversion is not what ships.

**Prior:** `dnorm(x, NPP_FRAC_NH_ANCHOR_1750, 0.04)`, replacing `UNIFORM[0.4, 0.8]` (zero
observational content). Bounds unchanged — ±3σ is [0.479, 0.719], well inside them, so the logit
transform does no prior work. **The width 0.04 is a stated JUDGEMENT**, like `SST_SEAS_LOGSD`:
MOD17's interannual sd is the *wrong* uncertainty (one product's spread about its own mean, not
the product-to-product ambiguity), and no bracket exists on disk. Building one from a second NPP
product is a real improvement someone could make.

**The old mode now sits at −3.31 σ.** That is the point, not a problem.

**Constants:** `NPP_FRAC_NH_OBS` (0.5942187, `data`) and `NPP_FRAC_NH_ANCHOR_1750` (`provisional`,
because it is an observation inverted through the model). The latter joins the provisional
**ledger** in `test-constants.R` deliberately — it keeps a model-dependent prior centre visible.
`init` is a **literal**, because `R/calibrate.R` sources before `R/constants.R`; `test-likelihood.R`
ties the literal to the constant, checks the prior is centred there rather than merely started
there, and asserts the anchor sits **above** the modern share (an equality would mean someone
centred on the wrong quantity).

**933 pass, 1 fail** — the fail is still `test-fluxes.R:99` from 08-20g, unchanged and untouched.
No new failures; the count rose 918 → 933 on the 15 new assertions.

## 2026-08-20l — The φ_eff answer: the latitudes were right, the amplitude was not

Four profile passes (`calibration/diag_phi_eff_profile.R`, 21 cells, seasonal block re-optimised
in every one) plus an offline form test on the observed shape (`diag_seas_rectification.R`).

**A light THRESHOLD buys nothing.** Fitted to the observed 8-day shape it optimises to **c = 0**
in 3 of 4 cases — it *chooses* to be the incumbent form. (The original offline fit recorded the
same thing and it was never followed up.) A power form buys 4–9 %. **A free AMPLITUDE buys 34–35 %
in the NH**, and its latitude is an **interior minimum at the shipped 75 with A ≈ 0.49** (7.5 %
residual against 11.4 % at φ = 50). **The SH latitude is not determined once amplitude is free.**

**So the offline fit that chose 75 was right about the SHAPE** — polar night at 75 N emulates a
rectified boreal growing season better than any lower latitude's smooth curve. The model had no
way to *scale* it, so 75's shape arrived with 75's amplitude, and `seas_T_amp_NH = 48 K` was the
cancellation that fixed the difference.

**The calibration agrees, and the arithmetic is unambiguous:**

| φ NH | φ SH | amp NH | amp SH | REOPT | `seas_T_amp_NH` |
|---|---|---|---|---|---|
| 75 | −40 | 0.49 | 0.36 | −2025.2 | 10.75 |
| **75** | **−30** | **0.49** | **0.50** | **−2027.7** | **10.77** |
| 50 | −15.75 | 1 | 1 | −2071.4 | 11.68 |
| **75** | **−30** | 1 | 1 | **−2576.0** | 38.61 |

**+548 log-units for two MEASURED constants and no latitude change at all**, and `seas_T_amp_NH`
lands on its observed 11.45 — 20d §6's cancellation hypothesis confirmed by its own repair.
`seas_npp_amp_{NH,SH}` (added 08-20f with an identity default, never fitted) turns out to be
exactly the knob; it should become **measured constants**, not fitted parameters.

**The hemispheres INTERACT and pass 1 was misleading on its own.** At SH −30 the NH optimum is
38–45 and 75 loses by ~390; at SH −15.75 the ordering **reverses**. `seas_lag_p`, `q10` and
`npp_frac_NH` are global, not per-hemisphere. A 1D slice of a surface with an interaction reads
as an answer — fill the plane.

**STILL OPEN, and it is Marcus':** ship (i) the shipped latitudes + measured amplitudes, with the
constant **renamed** to say it is a shape proxy rather than an NPP centroid; or (ii) the measured
latitudes (50, −16) with unit amplitudes, which costs ~44 log-units and buys a constant that means
what its name says. Nothing is committed to the model either way.

**NOT explained by any of this:** `sst_seas_amp_NH` sits at 0.33–0.54 in **every** cell against an
observed 2.237. That is the next real defect and this arc did not touch it.

## 2026-08-20m — The SH latitude, and the amplitude convention the data reject

**Marcus' SH prior — "the weighted latitude of the non-Antarctic land mass, because that's where
the biomass is" — checks out** (`calibration/diag_sh_land_latitude.R`), and three independent
weightings land within 3.4° of each other:

| weighting | SH | NH |
|---|---|---|
| **land area, Antarctica EXCLUDED** | **−18.08** | 37.70 |
| land area, Antarctica *included* | −35.93 | 37.70 |
| vegetated area (MOD17 valid pixels) | −18.47 | 40.59 |
| NPP flux (MOD17) | −15.12 | 34.29 |

Next to the 8-day shape-matched −16.14, that is four readings clustered at −15 to −18.5. **And the
Antarctica-included row is −35.93, close to the shipped −30** — suggestive of where the shipped
value came from, though not proof. Note the direction of the gaps: deserts are subtropical, so
"where the land is" and "where the biomass is" are *not* the same latitude, and the NEP term
represents the flux, not the acreage.

**But the proposed NAMING does not survive the test.** Marcus suggested describing the pair as the
"best amplitude fit" and "best shape fit" between NH land NPP and insolation. The second is
accurate (with the qualifier that φ = 75 is the best shape fit *once amplitude is free* — at unit
amplitude it is 50). **The first is not**, and the gap is not cosmetic: 0.49 is the *least-squares*
scale, and the factor that would make the model's swing EQUAL the observed swing is **0.624** (NH,
φ 75) and **1.995** (SH, φ −18). So the two conventions were run against each other:

| φ NH | φ SH | amp NH | amp SH | REOPT | `seas_T_amp_NH` |
|---|---|---|---|---|---|
| 75 | −40 | 0.49 | 0.36 | **−2025.2** | 10.75 |
| 75 | −15.75 | 0.49 | 1 | −2037.5 | 10.92 |
| **75** | **−18** | **0.49** | **0.97** | **−2043.5** | **11.45** |
| 75 | −18 | 0.62 | 0.97 | −2059.9 | 17.29 |
| 75 | −30 | 0.62 | 1.14 | −2382.4 | 20.25 |
| 75 | −18 | 0.62 | 1.99 | −2388.2 | 20.36 |

**The amplitude-matching convention is rejected by ~345 log-units**, almost all of it the SH
factor; the NH 0.62-vs-0.49 difference is ~16. **So the constants are residual-minimising scales,
not amplitude-matching ones, and the name has to say so.** The model deliberately delivers **78 %**
of the observed NH seasonal swing: the insolation shape is too peaked, so matching peak-to-peak
would put carbon in the wrong months, and both the shape data and the CO₂ record prefer a damped
version of the right shape over an undamped version of the wrong one.

**At (75, −18, 0.49, 0.97) the re-optimised `seas_T_amp_NH` is 11.4539 against a measured
11.4450.** That is the closest any cell has come, and it is Marcus' SH latitude.

## 2026-08-20n — The measured ridge: 75 wins, but only by 35, and at 50 the amplitude knob vanishes

Marcus asked two things: **what IS the NH NPP-weighted latitude, and could the NH optimum move now
that the SH has**. Both were live gaps.

**The NH NPP centroid is 34.29 — the shipped constant is 40.7° away from it.**

| NH weighting | lat | insolation p2p | vs observed 1.747 |
|---|---|---|---|
| **NPP flux (MOD17)** | **34.29** | 0.871 | **0.50×** |
| land area | 37.70 | 0.981 | 0.56× |
| vegetated area | 40.59 | 1.081 | 0.62× |
| best shape fit at unit amplitude | 49.96 | 1.458 | 0.83× |
| amplitude-matching latitude | 55.49 | 1.747 | 1.00× |
| **shipped** | **75.00** | 2.801 | **1.60×** |

**No latitude has both the observed amplitude and the observed shape.** At the biomass centroid the
light cycle is half as seasonal as productivity actually is; at 75 it is 1.6× too seasonal. What 75
buys is **polar night** — a hard zero, the only thing in the insolation family resembling a growing
season switching off.

**And yes, the NH ranking DID depend on the SH.** The earlier "NH optimum is 38–45" was measured at
SH −30, and most of its cells carried amplitude 1 while 75 and 65 carried their measured factors —
a comparison rigged in 75's favour and then read as if it were not. Both flaws are fixed by
profiling **along the measured ridge**: every NH latitude carries *its own* rms-optimal amplitude
factor, SH pinned at −18 / 0.97.

| φ NH | measured A | REOPT | `seas_T_amp_NH` |
|---|---|---|---|
| 34.29 | 1.53* | −2091.1 | 10.16 |
| 45 | 1.12 | −2081.1 | 11.26 |
| **50** | **0.96** | **−2078.2** | **11.32** |
| 55 | 0.83 | −2074.4 | 11.57 |
| 65 | 0.62 | −2065.3 | 11.84 |
| **75** | **0.49** | **−2043.5** | **11.45** |

*(\*34.29's A is extrapolated — the shape scan started at 38.35, A = 1.38.)*

**The ridge is monotone toward 75 with no interior optimum, and it is NOT flat — but it is
shallow: 47.6 log-units across 40° of latitude**, against the 548 that separates the shipped
configuration from any repaired one. Every cell converged to under 1 log-unit on its last restart,
so that spread is signal, not optimiser noise. Polar night is doing real work, modestly.

**The new fact that matters for the choice: at φ = 50 the measured amplitude factor is 0.96 —
within 4 % of 1.** Site the shape at 50 and the amplitude knob is very nearly redundant: **one
constant instead of two, for 34.7 log-units.** And `seas_T_amp_NH` lands on its observed 11.45 at
both ends of the ridge (11.32 at 50, 11.45 at 75), so that diagnostic does not discriminate.

**STILL MARCUS'.** The trade is now priced from end to end: 75 + 0.49 is the best fit and misnames
the flux centroid by 40.7°; 50 + 0.96 costs 34.7, needs no amplitude correction worth the name, and
sits 15.7° from the biomass. **Nothing is committed to the model.**

## 2026-08-20o — Banding the NH land: the ecosystems ARE different, and splitting them buys nothing

Marcus: *"It seems like the problem is that we are trying to apply a single insolation curve to
some very different ecosystems. The atmosphere can still be at the hemispheric level, but the NPP
can be a bit more complicated."* Tested offline, no model runs
(`calibration/diag_npp_bands.R`, MOD17A2HGF 8-day PsnNet, 5 years, four ecosystem-motivated bands).

**The test was designed to be decisive either way.** If the 11.4 % single-curve residual is an
AGGREGATION artefact, each band on its own should be well described by its own insolation curve
and the per-band residuals should collapse. If each band is individually just as badly matched,
the PREMISE is wrong and banding buys parameters instead of physics.

| NH band | NPP share | NPP centroid | own p2p | best-fit φ | best-fit A | residual |
|---|---|---|---|---|---|---|
| 0–23.5 | 32.6 % | 9.93 | 0.944 | 18.2 | 1.53 | **11.5 %** |
| 23.5–40 | 19.7 % | 32.13 | 1.299 | 5.1 | 4.00\* | **13.7 %** |
| 40–55 | 28.9 % | 47.83 | 2.659 | 67.8 | 1.06 | **8.3 %** |
| 55–90 | 18.8 % | 61.42 | 3.964 | 86.5 | 1.08 | **9.5 %** |

*(\*at the amplitude grid's ceiling — that band's per-band residual is grid-limited. The aggregate
fits below solve for amplitude by least squares and are unaffected.)*

**The per-band residuals are NOT smaller than the whole-hemisphere 11.4 % — two are worse.** So the
misfit is not an aggregation artefact. Whole-hemisphere fits to the same observed aggregate:

| model | NH | SH | params |
|---|---|---|---|
| 1 band, φ + amplitude free | **7.4 %** | 11.5 % | 2 |
| 4 bands at NPP centroids, amplitudes = 1 | **14.6 %** | 12.9 % | **0** |
| 4 bands at NPP centroids, amplitudes free | **7.1 %** | 10.5 % | 4 |

**Banding buys 0.3 points for two extra parameters.** And the no-free-parameter version — honest
spatial aggregation, the one most likely to be assumed correct — is **twice as bad as one curve**.

**Marcus' physical reading is nonetheless RIGHT, and the bands prove it.** They are genuinely
different: peak-to-peak spans 0.94 → 3.96 (4×) and best-fit φ spans 5 → 86. The pattern is
readable: **40–55 and 55–90 want φ POLEWARD of their own centroids (47.8→67.8, 61.4→86.5) with
A ≈ 1** — rectification, showing up independently in each boreal band and confirming what the
whole-hemisphere fit found. **0–23.5 and 23.5–40 are not light-shaped at all** (the subtropical
band wants φ = 5 with the amplitude pegged at the grid ceiling), because their cycle is
water-driven, not light-driven. **The errors partly CANCEL in the aggregate**, which is why one
curve does better than four honest ones.

**And Marcus' SH prediction is confirmed by the numbers:** 75.9 % of SH NPP lies equatorward of
23.5 S and **0.0 % south of 55 S**. There is no boreal-equivalent band to separate, so there is
nothing for banding to fix.

**Conclusion: do NOT band.** The residual is the insolation premise, not the aggregation, and it is
~10 % at every latitude. Closing it needs a different driver for the water-limited tropics
(precipitation or soil moisture), which is a much larger change than a band split and is NOT
justified by 0.3 points.

## 2026-08-20p — Dropping the low latitudes from the cycle: it derives the poleward φ, it doesn't beat it

Marcus: *"what about not including the low-latitudes in the annual cycle at all, and just using the
higher latitudes that are truly insolation driven? And maybe fewer than 4 bands?"* This is NOT the
banding proposal — banding kept the badly-behaved low-latitude bands and gave them curves; **this
deletes them from the seasonal term.** Tested offline, `calibration/diag_npp_seasonal_fraction.R`.

Model: `n(t) = 1 + w(L)·A·(I(φ(L),t)/mean I − 1)`, with **both** `w(L)` (the NPP share poleward of
the cutoff) and `φ(L)` (that share's NPP centroid) **measured from MOD17**. Equatorward of `L`, NPP
is aseasonal — a statement, not a fudge: that carbon's cycle is water-driven. With `A = 1` this is a
**zero-parameter** seasonal driver. The annual budget is untouched at every `L`.

| NH cutoff | w(L) | φ(L) | resid, A = 1 (0 params) | resid, A free | A | w·A |
|---|---|---|---|---|---|---|
| 0 | 1.000 | 34.96 | 16.8 % | 13.1 % | 1.54 | 1.54 |
| 23.5 | 0.674 | 47.04 | 16.2 % | 11.7 % | 1.56 | 1.05 |
| 40 | 0.478 | 53.18 | 17.9 % | 11.0 % | 1.83 | 0.88 |
| 55 | 0.188 | 61.42 | 24.4 % | 9.9 % | 3.65 | 0.69 |
| **60** | **0.108** | **64.41** | 27.1 % | **9.4 %** | 5.85 | **0.63** |

*(benchmarks on the same target: one curve, φ + amplitude free = **7.4 %**; four bands at their
centroids with A = 1 = 14.6 %)*

**The zero-parameter version fails — 16–27 %, worse than everything.** Extratropical insolation is
not steep enough: at L = 23.5 the model delivers `w·p2p(φ)` ≈ 0.90 against an observed 1.75.
**The A-free version improves monotonically with the cutoff but never reaches the single free
curve** (9.4 % at L = 60 vs 7.4 %). **And "fewer bands" changes nothing**: two bands above 23.5,
split at 55, give **7.5 %** — the same as one curve, for one more term.

**But it DERIVES the poleward φ that the calibration independently prefers, which is the real
result.** At L = 60 the model is a curve at **φ = 64.4 with an effective single-curve amplitude of
0.63** — essentially the (φ 65, A 0.62) cell of the measured ridge, reached from a completely
different direction. So the shipped configuration's poleward latitude and damped amplitude are
**not two tuned constants**: they are *"the seasonal cycle is carried by the ~11 % of NH NPP
poleward of 60 N, whose centroid is 64 N"*. That is a statable physical claim.

**And `A` measures the rectification directly**: 1.54 at L = 0 rising to **5.85 at L = 60** — the
boreal band's NPP swings ~6× harder than its own insolation, because it goes to zero in winter
while insolation at 64 N only falls to ~10 % of its mean.

**Marcus' SH prediction is confirmed again, and more strongly.** 62 % of SH NPP is equatorward of
10 S, 0.0 % south of 55 S, and **at L = 60 there is no NPP at all** — the row is reported as
"NO NPP POLEWARD OF THIS CUT" rather than fitted. Every SH cutoff leaves ~12 % residual regardless.
Restricting to high southern latitudes is not merely unhelpful, it is empty.

**Three self-inflicted failures found and fixed rather than tolerated:** an unconstrained
least-squares amplitude returned **negative** values at low cutoffs — an *inverted* seasonal cycle,
which fits a badly-shaped target better than an upright one — now clamped at zero, with the clamp
reported; `qr.solve` on a near-empty band returns coefficients of order 1e3–1e6 **without
erroring**, so non-finite candidates are skipped and **counted**; and an empty poleward cut gives
`0/0` for the centroid, whose NaN killed the run several frames from its cause.

## 2026-08-20q — The two-box test, and a CORRECTION to 20o's four-box number

Marcus: *"So a single NPP box with a seasonal cycle based on 75 degrees outperforms a dual NPP box
where 0–60 has a weak seasonal cycle and 60–90 has a strong one?"* **That configuration had never
been run** — 20o tested four boxes, and 20p tested two boxes with the tropics *deleted*. Run now
(`calibration/diag_npp_twobox.R`): two boxes spanning the whole hemisphere, weights and centroids
measured, amplitudes tested fixed and free.

| NH split | w_lo | φ_lo | w_hi | φ_hi | A = 1 | A free (≥0) | A_lo | A_hi |
|---|---|---|---|---|---|---|---|---|
| 40 | 0.522 | 18.30 | 0.478 | 53.18 | 15.1 % | 11.0 % | **0.00** | 1.83 |
| 55 | 0.812 | 28.83 | 0.188 | 61.42 | 15.5 % | 9.9 % | **0.00** | 3.65 |
| **60** | 0.892 | 31.40 | 0.108 | 64.41 | 15.9 % | **9.4 %** | **0.00** | 5.85 |
| 70 | 0.994 | 34.75 | 0.006 | 71.74 | 16.8 % | 7.8 % | 0.09 | 90.99 |

*(one box, φ + amplitude free = **7.4 %**)*

**The low-latitude box's amplitude is driven to ZERO at every split up to 60.** Given a
non-negativity constraint the two-box model *deletes its own low box* and becomes the cutoff model
of 20p — and never reaches 7.4 %. **So yes: a single box at 75 with a damped amplitude does
outperform the dual-box arrangement.**

### ⚠ CORRECTION: 20o's "four boxes = 7.1 %, beating 7.4 %" was UNCONSTRAINED

The two-box scan exposed that unconstrained solves in this family reach for **negative amplitudes**
— a productivity box run backwards through the year, which fits and cannot exist. 20o's four-box
number came from a bare `qr.solve`. Re-derived under non-negativity, exactly, by enumerating all
2⁴ active sets:

| | unconstrained | **non-negative** | fitted A |
|---|---|---|---|
| NH four boxes | 7.1 % | **9.9 %** | 0.00 0.00 0.00 3.65 |
| SH four boxes | 10.5 % | **11.7 %** | 0.20 0.00 0.00 1633 |

**The four-box model does NOT beat the single curve — it loses, 9.9 % against 7.4 %.** And its
non-negative solution sets three of four boxes to zero, keeping only 55–90: it *is* the cutoff
model at L = 55, which independently gave 9.9 %. The two diagnostics agree exactly, which is the
check that the correction is right rather than a second error.

**Withdraw the claim that banding "beat the single curve by 0.3 points".** No physically admissible
multi-box model beats one curve, and the earlier statement was an artefact of an absent constraint.

**Why one rectified curve beats the boreal box alone**, which is not obvious: at φ 75 with A 0.49
the whole hemisphere's NPP carries a heavily rectified shape at half strength; the boreal-only
model has 11 % of the NPP carrying its own shape at 5.9× strength. Similar amplitude, different
distribution — and the observed aggregate prefers the rectified shape **spread across all the
carbon** to a sharper one concentrated in a tenth of it.

## 2026-08-20r — SHIPPED: the measured NEP amplitude factors (Marcus)

> *"If 75 + 0.49 is the better fit, go with the better fit."*

**`seas_npp_amp_{NH,SH}` 1 → 0.4969 / 0.5027**, as `SEAS_NPP_AMP_{NH,SH}` in `R/constants.R`
(`data`). **`CCX_SEAS_PHI_EFF` is UNCHANGED at (75, −30)** — applying Marcus' own rule to the SH
lands on the shipped latitude too (−30 + 0.50 scores −2027.7 against −18 + 0.97 at −2043.5), so no
latitude moves at all. **Two measured constants, +548 log-units.** The SH is available at −18 for
15.8 log-units if the physical reading is preferred; say the word.

**The factors are the least-squares scale of the shipped latitude's insolation curve onto the
observed productivity cycle** (MOD17A2HGF 8-day PsnNet, 5 years, window-integrated, free shift):
NH **0.4969** (sd 0.046; GPP gives 0.487), SH **0.5027** (sd 0.087; GPP gives 0.352 — a 1.4×
bracket, because SH productivity is water-driven). No C++ edit was needed: both cores already read
these from the parameter list, so **parity is untouched**.

**`CCX_SEAS_PHI_EFF`'s comment is rewritten, because it was wrong by forty degrees.** It called
itself "flux-weighted effective"; the NH NPP-weighted mean latitude is **34.29**. It is the
latitude whose insolation SHAPE best matches observed productivity *once the amplitude is free*,
and 75 wins that as a clean interior optimum because polar night supplies a hard zero. **The pair
is ONE (shape, size) unit** — `test-likelihood.R` now RE-FITS both factors from the observation
product at the *current* φ and asserts agreement, with a mutation check that the gate fails at
φ = 50. Move φ without redoing them and the test says so.

### ⚠ A SECOND TEST NOW FAILS, AND IT IS NOT MODIFIED

**947 pass, 2 fail.** `test-fluxes.R:99` is the known one from 08-20g. **`test-fluxes.R:100` is
new**: `expect_lt(on$tau_label, off$tau_label - 0.2)` — "seasonality matters" — now gives 4.523
against a 4.500 bar. **Reported, not fixed**, per the standing rule.

Diagnosed, and it is the direct physical consequence of the change rather than a defect:

| `seas_npp_amp` | `tau_label` | gap vs seasonality-off |
|---|---|---|
| 1.00 (old default) | 3.994 | 0.705 |
| 0.70 | 4.293 | 0.407 |
| **0.4969 (shipped)** | **4.523** | **0.177** |
| 0.30 | 4.771 | **−0.071** |

**The 0.2 threshold silently encoded `seas_npp_amp = 1`** — the same failure mode as line 99's
1e-3 tolerance silently encoding `CCX_SST_SEAS_LAG = 2.5`, in the same test, found the same way.
The direction is still right (seasonality does shorten the label turnover) and the magnitude simply
halved with the amplitude. Note also that the gap **changes sign below ~0.35**, so the assertion is
not merely mis-scaled — it is testing a quantity that is not monotone in the thing it varies.
**Options for Marcus, not resolved here:** (i) derive the threshold from `seas_npp_amp` instead of
hardcoding it; (ii) assert the sign only; (iii) run the case at the amplitude the assertion was
written for and say so.

**CONFIRMED at the exact constants** (the profile used the rounded 0.49 / 0.50): the shipped pair
scores **−2027.3**, marginally better than the rounded −2027.7, so the **+548.7** gain over the old
−2576.0 stands. Converged in 5.7 min, 2 restarts, last gain +0.1. There `seas_T_amp_NH` re-optimises
to **11.084 against a measured 11.445** — within 3 %, and closer than any other cell tested. It sits
2.0 below the best cell in the 30-cell set, (75, −40), which has no physical support: only 2.2 % of
SH NPP lies poleward of 40 S. **`sst_seas_amp_NH` is 0.410 against an observed 2.237, unmoved.**

**⚠ WHAT THIS INVALIDATES.** The model has changed. Diagnostics that rebuild a mode from
`mode_fit_pump{N,D}.rds` now run it under different NEP amplitudes — `par_mode` does not carry
`seas_npp_amp`, so it picks up the new default — and will NOT reproduce pre-08-20r numbers. Same
class as the 08-20g lag change. **The refit that 20d §4 owes is now doubly owed.**

## 2026-08-21 — THE REFIT LANDED. The seasonal rows transformed; the mode is NOT converged

One arm (N), 919 min, 378,880 evaluations, 0.146 s/eval. Mode at
`calibration/output/pump_arms/mode_fit_pumpN.rds`; the 08-18 mode is preserved under
`pre_refit_20260820r/`. **`hml_bound` = [85, 120] is now recorded in the file.**

### The seasonal streams transformed — this is what the arc bought

| stream | 08-18 | **08-20r** |
|---|---|---|
| `co2_seasonal_MLO` | −232.2 | **−39.1** |
| `co2_seasonal_SPO` | −95.6 | **+35.1** |
| `d13c_seasonal_MLO` | −141.6 | **+116.6** |
| `d13c_seasonal_SPO` | −107.2 | **+94.7** |
| **seasonal total** | **−576.6** | **+207.3** |

**~784 log-units on the four seasonal rows.** (The priors changed between these runs, so the
*posterior* is not comparable; these are per-stream LIKELIHOOD contributions and two fitted error
parameters touch them, so read the size, not the third digit.) The CO₂-**level** rows also improved
(`co2_level_MLO` −79.6 → −74.1, `SPO` −68.5 → −64.2), so the `h_ml` bound remains cheap — the
check that mattered most from the 08-18 run passes again.

### `seas_T_amp_NH` = 25.94 against a measured 11.45 — and that is the q10 DEGENERACY, not a failure

At small amplitude the identified quantity is **`seas_T_amp` × ln(`q10`)**, not either alone:

| | `seas_T_amp_NH` | `q10` | **A·ln(q10)** |
|---|---|---|---|
| 08-18 mode | 48.07 | 1.2613 | **11.16** |
| profile, 7 params free | 11.08 | 1.2201 | **2.205** |
| **08-20r refit, 21 free** | **25.94** | **1.0907** | **2.251** |

**The refit and the profile agree to 2 % on the identified product**, and both are ~5× below the
08-18 mode. **The amplitude fix worked exactly as intended** — the respiration modulation collapsed
from 11.16 to 2.25. What is left is that `q10` slid to **1.0907** (z = −2.01, and physically low for
soil respiration), which drags `seas_T_amp_NH` back up the degeneracy ridge to hold the product.
**So the +3.29 σ flag is a prior on the wrong coordinate**: the prior constrains A alone while the
data identify A·ln(q10). That is the next structural thing to fix, and it was invisible until the
amplitude excess was removed.

### ⚠ THE MODE IS NOT CONVERGED, and the driver says so

`*** [N] HIT THE RESTART CAP WHILE STILL GAINING`. Worse: after Nelder-Mead stalled at gains of
0.07–0.27 per restart, **the BFGS polish gained 16.08** — two orders of magnitude more than any
recent restart. A polish that large means the simplex had collapsed in a direction the gradient
could still exploit; the reported mode is a good parameter vector but not a located optimum.
**`hessian` is UNSTABLE at `h_ml`** (mode 87.56 m, 2.6 m above the bound), so `logdet_negH` and any
Laplace evidence from this file are NOT usable — the same caveat the driver has always carried,
now actually triggered.

### The other three standing checks

- **`sst_seas_amp_NH` = 0.467, z = −5.97.** It moved 5× (from 0.089) and is still **4.8× below** the
  observed 2.237. **Confirmed independent of everything this arc did.** Still the largest misfit.
- **`npp_frac_NH` = 0.559, z = −0.99.** The re-anchored prior is doing its job with no fight — the
  data sit inside 1 σ of the MOD17-derived anchor. §20k is vindicated.
- **`kz` = 6461.4, 97.4 % up the re-bisected bracket.** Still pinned. The standing question from
  DESIGN §5.2h is UNRESOLVED and this run does not settle it.

Also flagged: `seas_T_amp_SH` −3.70, `sst_seas_amp_SH` −3.95, `bomb_total` +3.08, `rep_dC` +5.75
(the known CO₂-level bias sink). Two `ccx_c12_steady_conveyor` non-convergence warnings, worst
|resid| 2.2e-02.

**RECOMMENDED NEXT: a continuation, not a fresh run.** Restart Nelder-Mead from the polished mode
and re-polish, iterating until the polish gain is small — the 16.08 says there is more there, and
starting from the mode should cost hours rather than 15 h. **Do not quote this mode's evidence or
uncertainties until it converges.**

## 2026-08-21b — The continuation: the mode was ALREADY converged. My reasoning for running it was wrong

15.6 min, 5,235 evaluations, warm-started from the 08-20r mode.

```
[N] cycle 1 restart 1: log-post = -1877.9  (gain 0.0000)  evals 2927
[N] cycle 1 restart 2: log-post = -1877.9  (gain 0.0000)  evals 5109
[N] cycle 1 polish:    log-post = -1877.9  (gain 0.0000)
[N] CONVERGED: cycle gain below ARM_CYCLE_TOL (0.5)
```

**The mode did not move: max relative parameter change 2.3e-4, log-post identical at −1877.9475.**
Nelder-Mead converged inside 2,927 and 2,182 evaluations against a 20,000 cap — it is a genuine
local optimum for both methods, not a point BFGS happened to stop at. **`hit_cap` is now FALSE.**

### ⚠ CORRECTION to 20-08-21's recommendation

I read the 16.08 BFGS polish gain as *"there is more there"* and recommended a continuation on that
basis. **That inference was wrong.** The large polish gain meant BFGS had *finished the job Nelder-
Mead could not* — the simplex had collapsed in narrow directions and the gradient walked straight
to the optimum — not that further climbing remained. The correct reading of a large polish gain
after stalled NM restarts is "NM stalled", not "the mode is elsewhere".

**The run was still worth its 15.6 minutes**, but for a different reason than the one given: it
converts "NOT converged" from the driver's own flag into **converged, verified by an independent
restart from the mode**. That is a real upgrade in what can be said about the file — it just is not
the upgrade that was predicted.

### What is still not quotable, and why — now ONE reason, not two

**`hessian` remains UNSTABLE at `h_ml`** (curvature changes across eps × 1/3, 1, 3). So
`logdet_negH`, `sd_unc`, `cov` and any Laplace evidence from this file are still NOT usable. Note
what it is NOT: the mode sits at **87.56 m**, **10.85 m from the nearest kink**, so this is not the
piecewise-C1 problem `ccx_hml_kink` documents. It is a parameter **2.56 m above its bound** in a
direction whose curvature the central difference cannot resolve at any of the three steps tried.
Laplace covariance is PD with condition number 4.42e5.

**So the mode is converged and its uncertainties are not.** `par_mode` is usable; the second-order
block is not. Fixing it needs a step-size study for `h_ml` specifically (or a Hessian on the other
20 with `h_ml` profiled), and it is NOT done.
