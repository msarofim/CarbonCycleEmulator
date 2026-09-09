# CODE REVIEW — the whole model, 2026-09-09t. ⛔ **THE REFIT IS BLOCKED: `ccx_spinup()` SOLVES THE PREINDUSTRIAL EQUILIBRIUM WITH THE SEASONAL MIXED LAYER ON, BECAUSE THE TWO CORES GATE `seas_ml` ON DIFFERENT THINGS. EVERY `seas_ml = 1` RESULT FROM 09-09 (P10, P11, P12, P1c) RESTS ON IT.**

Ordered by what it changes. Commissioned by Marcus 09-09s: review first, refit only when the code
is judged clean, against BOTH correctness AND physical/pedagogical defensibility
([[ccx_pedagogical_not_emulator]]).

**Baseline confirmed before reviewing**: suite re-run at `a73edb3` = **PASS 2381 / FAIL 3 / SKIP 4**,
the three being exactly the pre-existing set the handoff names. Tree clean, nothing modified by this
review.

⚠ **PROVENANCE OF EACH FINDING IS MARKED.** `[V]` = I reproduced it myself from the code or by
measurement, and the reproduction is in the entry. `[R]` = reported by a review pass and **NOT
independently verified by me** — treat as a lead, not a fact, and verify before acting.

---

## 1. ⛔⛔ THE BLOCKER — `seas_ml` LEAKS INTO THE ASEASONAL SPINUP. `[V]`

**The two cores gate the mechanism on different objects.**
- R gates per call on `ccx_seas_ml_on(p)` (`R/model.R:853`), which **requires `p$seas_drivers > 0`**.
- C++ gates on `A.seas_ml` (`src/ccx_core.cpp:433`), and that flag is
  `seas_ml = as.integer(!is.null(aux$mld_coef))` (`R/cpp.R:50`) — **a function of `aux` ALONE**.

`ccx_spinup()` builds `aux <- ccx_prepare(p)` from the **un-zeroed** `p` (`R/spinup.R:151`) and only
*then* sets `p0$seas_drivers <- 0` (`R/spinup.R:227`) — and every equilibrium solve runs through the
**C++** path. **So the zeroing is honoured by R and ignored by C++.**

**MEASURED (mine).** At the canonical `hilda31`, `ccx_prepare()` then the spinup's own zeroing:

| | |
|---|---|
| `aux$mld_coef` present | `TRUE` |
| R gate `ccx_seas_ml_on(p0)` | **`FALSE`** |
| C++ flag actually sent | **`1`** |

and the spinup's returned equilibrium — which is **defined** aseasonal — moves with `seas_ml`:

| spinup equilibrium | `seas_ml = 0` | `seas_ml = 1` | Δ |
|---|---|---|---|
| ocean C (GtC) | 37 894.163 | 35 953.939 | **−1 940.224** |
| max abs Δ over all 36×3 state | — | — | **489.2** |

⇒ **The "preindustrial equilibrium" for every `seas_ml = 1` run is the state that balances a spurious
entrainment limb frozen at the spinup epoch.** The atmosphere is unchanged (588.093 both) because it
is pinned to `CO2_PI_PPM`; the whole displacement lands in the ocean.

⛔ **WHAT THIS PUTS IN DOUBT.** P11 (parity), P12 (the compensator profile), P1c (the ΔpCO₂
comparison) and P10 (rectification) were all produced at `seas_ml = 1`.
⭐ **P12's headline — "it succeeds on the seasonal cycle and PAYS −514 ON THE TWO CO₂ LEVEL ROWS" —
is the exact signature a ~1 940 GtC ocean-carbon deficit at t₀ would produce.** The 09-09n reading
that this is "the most REFITTABLE kind of error" and the 09-09k reading that the mechanism "CHANGES
ANTHROPOGENIC UPTAKE — a RESULT, not a defect" must both be re-examined after the fix. This is the
[[explained_away_test]] pattern: a plausible physical story was available for a number a bug also
explains.

⚠ **WHY PARITY DID NOT CATCH IT.** `test-parity.R` compares the two cores at ONE `(p, aux)` pair.
The divergence requires `p` to be mutated **after** `ccx_prepare()` — which is precisely and only
what `ccx_spinup()` does. **A parity test that never mutates `p` after building `aux` cannot see an
aux-vs-p gate disagreement.**

**Fix direction (NOT applied — Marcus's call):** make the C++ gate read the same source as R (send
`seas_ml` through `Par`, or rebuild `aux` from `p0` inside `ccx_spinup()`), then add the missing
test: build `aux` seasonal, zero `seas_drivers`, and demand `ccx_deriv == ccx_deriv_fast`.

⛔ **QUARANTINE OBLIGATION** (`~/.claude/CLAUDE.md`): the 09-09 `seas_ml = 1` diagnostics under
`outputs/` are pre-fix outputs. Move them to `outputs/quarantine/20260909_seas_ml_spinup_leak/` with
a README naming the bug, the files, and the canonical post-fix path. **Do not delete them** — they
are the regression test for the fix and the measure of its impact.

---

## 2. ⛔ THE REFIT'S TARGET RESTS ON A NUMBER THIS REPO RETRACTED SIX DAYS EARLIER. `[V]`

Handoff 09-09s §3/§4 and `CHANGELOG.md:32` set the refit's target as: *cut the SH ΔpCO₂ amplitude
~2.6× by relaxing the fitted solubility amplitude (`sst_seas_amp_SH` — the parameter whose prior-z
was **−5.14** precisely because it stood in for entrainment)*.

**MEASURED at `hilda31` (mine), using the lognormal median as the centre:**

| | prior centre | fitted | prior-z |
|---|---|---|---|
| `sst_seas_amp_NH` | 2.23739 K | 1.0668 K | **−2.96** |
| `sst_seas_amp_SH` | 1.74644 K | **1.9110 K** | **+0.36** |

✅ **The estimator is validated**: it reproduces the handoff's own NH figure (−2.96) exactly, so the
SH reading is like-for-like.

⛔ **−5.14 is a PRE-09-03 value and this repo already recorded its supersession.**
`CHANGELOG.md:2528` and `notes/handoff_2026-09-03_ent26_refit_and_the_spinup.md:35` carry the row
**"P2 `sst_seas_amp_SH` prior-z | −5.14 | +0.24 | ✅ the 5σ strain is GONE"**, and
`notes/assessment_2026-09-04h:131` repeats it. **P2 was tested and PASSED on 09-03.** The live source
of the stale number is the code comment `R/calibrate.R:529`, which correctly says "first measured
2026-09-03 at the refit winner" — the qualifier was dropped on the way into the handoff.

⇒ **THE STATED ROUTE DOES NOT EXIST.** There is no SH solubility strain to relax; at +0.36 the
parameter sits *above* its prior centre, so "relaxing" it toward the prior would **increase** the
swing, not cut it. Two consequences for the refit:
- The SH over-swing is **DIC-side**: `ent_seas_amp_SH` is fitted **21.04** against a derived prior
  centre of **10.95** (1.92×). Retiring the shim is the lever that cuts the amplitude.
- ⭐ **The live strain is the NH** (−2.96; fitted 1.067 K against an observed 2.237 K, less than
  half) — the hemisphere the SH-only shim never served and the new **bi-hemispheric** mechanism does.
  **The refit's acceptance test should be NH-centred.**

⚠ **One nuance kept, which the gist would delete**: `R/constants.R:340-344` declares the ocean pair's
prior *width* a **judgement**, not a measurement (0.25 log, ±28 %), explicitly covering the gap
between "the area-weighted mean we can compute and the gas-exchange-weighted mean the parameter
actually is". So −2.96 is measured against a centre the file itself flags as the wrong estimator.
The strain is real; its exact size is not.

---

## 3. ⛔ ROUND 6 IS INCOMPATIBLE WITH THE MAJORITY OF `h_ml`'s OWN PRIOR. `[V]`

`ccx_seas_ml_guard()` **STOPS** (it does not clamp) when the winter mixed layer reaches layer 1's
base. **MEASURED by bisection (mine): the stop is at `h_ml = 76.146 m`** — matching the prereg's
"~76.1" — and the approach to it is a cliff, not a margin:

| `h_ml` | layer-1 base | winter ML | residual `dz_1` | guard |
|---|---|---|---|---|
| 49.15 (canonical) | 101.44 | 82.65 | 18.789 | ok |
| 70.00 | 122.00 | 117.72 | 4.278 | ok |
| **75.00** | 126.92 | 126.13 | **0.798** | ok |
| **76.00** | 127.91 | 127.81 | **0.102** | ok |
| 80.00 | 131.85 | 134.53 | −2.682 | **STOP** |

(The 0.798 m at `h_ml` 75 reproduces the handoff's own figure, validating the setup.)

⛔⛔ **`h_ml`'s prior is lognormal, centre 83.94 m, log-sd 0.341** ⇒ **its MEDIAN LIES PAST THE STOP,
and P(h_ml > 76.146) = 61.3 %.** A dispersed 24-start Torch array drawing `h_ml` from its prior puts
~3 starts in 5 into an immediate `stop()`.

⭐⭐ **AND THE PRIOR SAYS SO ITSELF.** `R/calibrate.R:148-155`: its 16 %/84 % points are the two
defensible readings of Holte 2017 **"for a time-constant thickness"** — LS annual **mean 59.7 m** and
LS annual **max 118 m** — and *"the prior ENCODES the mean-vs-max ambiguity **a seasonal mixed layer
would resolve**"*. **Round 6 resolves exactly that ambiguity by construction** (mean-preserving:
`h_ml` now IS the annual mean, the max is supplied by the climatology). ⇒ **the prior is wrong by
construction the moment the mechanism is adopted, and nobody re-centred it.**

**Priced (mine):** re-centring on the LS annual mean 59.7 m drops guard exposure 61.3 % → **23.8 %**
at the same width, and to **11.2 % / 5.2 %** at log-sd 0.20 / 0.15 — a narrowing the discharged
ambiguity independently justifies.

---

## 4. ⛔ A FACTOR-OF-TWO IN ONE LEG OF `ent_seas_amp_SH`'s PRIOR CENTRE. `[V]`

`.ENT_SO_SST_AMP <- 3.0` is documented `R/constants.R:38` as *"K, seasonal SST **half-amplitude** of
the 40-90 S BAND (ERSSTv5)"*. **It is the PEAK-TO-PEAK.**

**MEASURED (mine), ERSSTv5 1975–2024, the repo's own `sc_harm` estimator and cos-lat weighting:**

| band | half-amp | peak-to-peak |
|---|---|---|
| **40–90 S** | **1.4995 K** | **2.9990 K** ⇒ the shipped "3.0" |
| SH hemisphere | **1.7464 K** | 3.4928 K |

✅ **Validation**: the SH hemispheric half-amplitude reproduces the registered
`SST_SEAS_AMP_SH_OBS = 1.74644` to five significant figures, so the same pipeline on the band is
like-for-like.

The consumer needs a **half**-amplitude: `ent_seas_amp_SH` is the coefficient of `sin(...)` in both
cores (`R/model.R:2008`, `src/ccx_core.cpp:582`).

⚠ **The tell was in the prose.** `R/constants.R:41-42` claims *"the band is colder and swings harder
than the hemisphere containing it"* — **falsified like-for-like**: 1.4995 < 1.7464, the band swings
**less**. It only reads true because it compares a p2p against a half-amp. **This is exactly the
"two numbers claiming to be the same quantity" sweep that found the 19.45/16.26 split.**

⛔ **DO NOT FIX ONE LEG ALONE** (the 09-09q discipline). `[R]` reports `.ENT_SO_PCO2_AMP = 19.45` is
*also* p2p *and* the phase-blind per-cell estimator, so the two biases **do not cancel** — they run
the same way on top of a shared factor of 2, putting the shipped centre 10.95 at **≈2.1–2.3× too
large**. **I did not verify the pCO₂ leg.** Verify both, then re-derive in one edit.

⇒ Against a corrected centre (~5), the fitted **21.04** is not 1.9× but **~4×** its prior — which
**strengthens** the §2 reading that the shim is doing DIC-side work the physics does not support, and
strengthens the case for retiring it.

⚠ **REFINEMENT of the handoff's §5a.** The handoff says `.ENT_SO_SST_AMP`'s "per-cell-vs-area-mean
convention is not stated". The **band IS stated** (`R/constants.R:38-39`, and it explicitly warns
"⚠ NOT SST_SEAS_AMP_SH_OBS"). What is unstated is the **estimator**, and what is *wrong* is the
**half-vs-peak-to-peak units label**. Narrower and more serious than the handoff's version.

---

## 5. ⚠ P1c's STRUCTURAL DIAGNOSIS NAMES THE WRONG CAUSE. `[V]`

09-09r concluded: the low-latitude box carries a high-latitude regime *"because its MLD driver is an
**SH-wide mean dominated by high-latitude winter mixing**."*

⛔ **The driver is already LS-masked.** `data/obs_mld.rds$seasonal$def` reads verbatim:
*"dt; f_ent = per-cell (h_m − h_min)/h_m, **cos-lat mean over 12-month LS cells**"*, and
`$consts` gives `lat_hs = 57.1401196211109`, itself derived from `hs_frac`. The `h_ml` prior carries
the same mask (`data/obs_h_ml_prior.rds$source`: *"LS |lat| < 57.14 deg"*). **The SH LS band really
does peak in August** (`month_max = 8`); that is not an aggregation artefact.

⇒ The A1 phase gap is better explained by **A1's own 0–90 °S aggregation** mixing the January-peaking
thermal subtropics with the July/August-peaking Southern Ocean — the 4.4× antiphase cancellation
09-09p already quantified — than by the model's driver. **The finding that the comparison is
structural still stands; its stated mechanism does not.**

⭐⭐ **AND THE MASK EXPOSES A REAL ASYMMETRY THE MODEL CANNOT REPRESENT.** The same product gives
**per-hemisphere LS annual means: NH 49.1 m, SH 68.0 m** (maxima 82.6 / 114). The model has **ONE
scalar `h_ml`**, mean-preserving, fitted at **49.15 m** — i.e. it has landed essentially exactly on
the **NH** value and leaves the **SH mixed layer 38 % too thin**.

⚠ **A TESTABLE HYPOTHESIS FOR THE OVER-SWING, offered as a hypothesis and not a conclusion:** a
thinner mixed layer gives a larger seasonal pCO₂ swing for the same forcing, and **68.0/49.15 =
1.38× against an observed over-swing of 1.33× (20.57 vs A2's 15.46)**. The proposed test is a
per-hemisphere `h_ml` (or an `h_ml_SH` scale factor), which the product supports for free. ⛔ **Do
not run it before §1 is fixed** — P1c's numbers are contaminated.

---

## 6. ⚠ `test-seas-lag-split.R:199` HAND-ROLLS A CONTRACT THE REPO IMPLEMENTS. `[V]`

The erroring pre-existing test. **Reproduced (mine):** after seeding `ent_seas_amp_SH` alone,
**two more** coordinates remain unencodable — `kz_deep_frac = 1` and `pump_hs_gcm2 = 0`, both sitting
**exactly on the rails of their logit transform**. Calling `ccx_seed_unencodable(mig, "test")`
instead resolves all three and the vector encodes finitely.

**Pre-existing and NOT this session's** — confirmed: the two extra coordinates entered
`CCX_PARAM_TABLE` on 09-06d and 09-07e, after the test was written. The handoff's label is accurate.
But the test **hand-seeds one coordinate** while its own next comment line names
`ccx_seed_unencodable()` as the function that exists to do this (`test-u-hs-fitted.R:49` calls it
correctly). ⇒ **it will re-break on every future parameter addition.** Not a model defect; a test that
duplicates a contract instead of calling it.

---

## 7. ⚠ THE TEACHING SURFACE DESCRIBES A MODEL THE CODE NO LONGER IS. `[V]`

`app/ui.R:265` tells the student the ocean is *"a mixed layer over ten diffusive layers"*, and
`app/R/plots.R:301` labels the two ocean boxes "Ocean mixed layer" / "Deep ocean (10 layers)". The
**diagram beside it was updated** to the seven-box HILDA form (`plot_box_diagram`, `hs_on` branch,
09-09g) — **the prose was not.** At the canonical, `hs_frac = 0.16` and `h_hs = 401.15 m`, so the
model a student is told about and the model that runs are different models. For a **pedagogical**
model this is a first-order defect, and it is the "labels derive from named constants" bug class: the
figure got a conditional, the sentence did not.

⚠ Related, `[V]`: `sst_hs = 2 °C` at the canonical sits **exactly on the lower edge** of the
carbonate tables' fitted range [2.0, 35.0]. The suite emitted **10 457 warnings**, overwhelmingly
`carb_constants()` extrapolation. Two costs: the cold box does its chemistry at/past the edge of its
parameterisation, and a genuinely new warning is invisible in that volume.

---

## 8. FINDINGS REPORTED BUT **NOT** VERIFIED BY ME — leads, in reported severity order. `[R]`

⚠ **Each needs verification before action.** I reproduced §1–§7 above; I did not reproduce these.

**Correctness**
- **F2** — with §1 fixed, the aseasonal equilibrium is reportedly still not a point on the seasonal
  orbit (the mechanism changes the state→concentration map via `ml_mass·f(t)`, not just a rate), so a
  **periodic spinup may be owed after all**. Reported +19.6 ppm shock at 1750 decaying over
  centuries. ⛔ **If true this reverses the 09-09j/09-09k "no periodic spinup is needed" conclusion,
  which was argued by construction from the very `seas_drivers` zeroing that §1 shows C++ ignores.**
  Verify immediately after §1.
- **F3** — the guard uses `max(f_month)` (month centres, 1.68168) but the continuous series peaks at
  1.68760, so there is reportedly a ~0.64 m window (`h_ml` 75.50–76.15) where winter `dz_1` goes
  **negative** and the guard stays silent.
- **F4** — `ccx_substeps_for()` reportedly still under-resolves: month-centre extremes rather than
  continuous, and it omits the entrainment operator's own bound entirely; ~19 returned vs ~46 needed
  at `h_ml` 75. Not live at the canonical (need ≈1.5, floor 4 dominates). ⇒ the honest claim is
  **"the floor covers the canonical"**, not "the bound is right".

**Gates / likelihood**
- **The canonical mode file's stored stream decomposition is reportedly 4.75 log-units short of its
  own stored logpost** (wrong stream set: `d14c_deep_ocean` present, the three profile rows absent).
  The *producer* was fixed 09-08g; the *artifact* was never re-promoted, and the adoption gate
  `intersect()`s the missing rows away and only **prints**. 13 sites read `md$streams`.
  ⭐ **If verified this is a second quarantine-and-regenerate obligation.**
- `ccx_loglik()` reportedly returns a **finite 0** if every stream vanishes (`sum(unlist(c()))`), and
  a zero-row stream registers in `by_stream` at exactly 0 — so the documented "check `by_stream` for
  ABSENT streams" remedy is blind to it. Same free-lunch mechanism the `h_ml` band skip already
  fixed in one place.
- GATE GL's tolerance is reportedly widened by the model's own CO₂ gradient, uncapped
  ([[gate_reads_its_own_output]]); latent, not live.
- Six of seven gate verdicts reportedly return `pass = NA` on non-finite z rather than failing.
- **GATE Q — the ledger's only out-of-sample gate, and the anchor every other strictness constant is
  pinned to — reportedly has no `test-gate-bounds.R` coverage at all.**
- Default-off and never exercised at a non-zero value: `tau_ex_seas_amp`, `tau_ex_seas_phase`,
  `ra_ratio`, `LIK_D14C_DEEP_MASK_NATL` ([[default_off_hides_the_bug]]). Reported near-miss:
  `npp_veg_frac` defaults **0.5** in R but the C++ shim back-fills **0** — the same R-vs-C++ absence
  disagreement as §1.
- Unguarded positional/dimension interfaces at the C++ boundary (`forcing.ncol()` never checked;
  `unpack_aux` fixed-count reads) and `names(u) <- CCX_PARAM_NAMES` unguarded at
  `R/calibrate.R:1514, 1615, 1632`.

**Constants / physics / pedagogy**
- `.ENT_DIC_SURF = 2150` is reportedly **correct** as a 40–90 S band value (GLODAPv2.2023 0–100 m:
  band 2149.2 vs global 2062.2) ⇒ **the "~5.6 % too high" flag on it is itself a like-for-like error,
  and acting on that flag would inject a ~5 % error into a correct constant.** Fix the citation, not
  the number.
- `.ENT_REVELLE = 13` has **no source of any kind**; band value reportedly ≈14.3.
- `ALPHA_PHOTO`-equivalent literal `1 - 18/1000` at `R/model.R:2785` cites a `constants.R` note that
  **does not exist**, and lives outside the registry so `ccx_check_constants()` is blind to it.
- `ENT_SEAS_BAND_AREA_FRAC`'s `source` string carries a duplicated "RETIRED … do not use as a live
  target" boilerplate while the constant is live and load-bearing.
- `h_hs = 401 m` under `dunif(20, 500)`: reportedly 1.5× the deepest winter MLD the model's own
  product knows and 5.3× HILDA's 75 m, with **nothing pushing back on it**. Defensible as a water
  mass; unteachable as a "surface" box beside a 49 m mixed layer.
- `q10 = 1.149` (z ≈ −2.2) — the model's headline "warming releases soil carbon" mechanism is fitted
  most of the way to its own counterfactual (`app` sets `q10 <- 1` for "off"). Pedagogically the most
  expensive fitted number in the set.
- **The `ml` box is low-latitude for AREA/MASS/CARBON but hemispheric for TEMPERATURE**
  (`sst_NH/SH = 18/16`, commented "hemispheric-mean", while `hs` at 2 °C has already removed the cold
  cap ⇒ double-counted). Reported as declared nowhere a reader would look. ⭐ **This is the handoff's
  §5b "what is the `ml` box's identity" question, and the answer is "split".**
- The frozen-Revelle branch (`R/model.R:2016`) is the **first-order expansion**
  `pco2_0·(1 + R₀·ΔDIC/DIC₀)`, not constant-Revelle `pco2_0·(DIC/DIC₀)^R`; reported ~30 % divergence
  at +10 % DIC, understating the rise. The power form costs the same.

---

## 9. WHAT CHECKED OUT — recorded so it is not re-audited

`[V]` by me: the guard's 76.146 m threshold matches its docstring; the six names dropped by
`lib_design_gates.R:551`'s `intersect()` are exactly the six documented nuisances (the "TWO LISTS,
NOT ONE" design), **not** a silent drop; `h_hs` really is 401.15 at the canonical; the stale-instruction
status headers on `notes/options_2026-09-08d…` and `notes/handoff_2026-09-08j…` are both in place.

`[R]`, not verified by me: Nyquist halving correct in both cores (reconstruction 1e-15, annual mean
exactly 1, NH peak month 2 / SH 8); two explicit entrainment limbs with correct sources in both cores
and no signed flux; `alpha13 = 1` on both limbs with no ¹⁴C term added; per-hemisphere geometry
rebuilt not assigned over (antiphase confirmed by parity to 4e-12); `dz_ML + dz_1` conserved and
`dz_mid[1]` invariant; the `seas_ml = 0` bit-identity genuine — **with the caveat that "off" is
decided by two different predicates, which is §1**; every `status = "derived"` constant genuinely
computed and matching its prose (the typed-"derived" class is fixed); no reads-its-own-output gate;
no binned-σ shelf beyond one labelled instance.

⚠ **One stale status header found** `[V]`: `notes/handoff_2026-09-08j…`'s own header still says *"the
round is stopped at P1 … and the C++ twin is not built"* — both overtaken by 09-09m and 09-09o. A
status header should point at the live document and **not restate live state**, or it goes stale in
turn ([[status_field_carries_the_query]]).

---

## 10. RECOMMENDED ORDER

1. ⛔ **Fix §1, then re-run P10/P11/P12/P1c.** Quarantine the pre-fix outputs first. **No refit until
   this lands** — §1 silently redefines the very target §2 corrects.
2. **Verify F2 immediately after** — if the periodic spinup is owed, the round's cost changes.
3. **Re-derive `ent_seas_amp_SH`'s prior centre with BOTH legs fixed** (§4), in one edit.
4. **Restate the refit's target** (§2): NH-centred, the amplitude cut coming from retiring the shim.
5. **Re-centre `h_ml`'s prior on the LS annual mean at adoption** (§3) — required by the guard,
   discharged by the mechanism. Consider the per-hemisphere `h_ml` test (§5).
6. Verify the §8 leads, worst first: the canonical mode file's stream set, then GATE Q's coverage.
7. Pedagogy: the app prose (§7), the `ml` box's identity, `q10`, `h_hs`.

⛔ **NOT DONE, DELIBERATELY: nothing was fixed.** The instruction was review first; every fix above
is Marcus's call, and several (the prior re-centring, retiring the shim, the mode-file re-promotion)
move stored logposts or canonical artifacts.
