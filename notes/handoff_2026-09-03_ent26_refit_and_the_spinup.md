# Handoff — CarbonCycleEmulator, 2026-09-03 (evening)
# **FIX A WORKED: THE 5σ STRAIN IS GONE AND THE OCEAN LIMB IS IN THE RIGHT SEASON.**
# **⛔ BUT P5 IS FALSIFIED — THE LONG LIFETIME DOES *NOT* EMERGE FROM FIXING THE SEASONAL PHYSICS.**
# **⭐ AND THE FIT'S COST WAS NEVER THE PARAMETER COUNT: IT WAS THE SPINUP, RUNNING IN R.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, commits
`88ee23c..63ce981` (12).
⚠ **Sessions launch from `FaIRtoFrEDI/`; ALL of this is in `CarbonCycleEmulator/`.** Use `git -C <abspath>`.

**Read before this one:** `handoff_2026-09-03_pedagogical_reframe_and_the_cancellation_arc.md` — the
pedagogical reframe and the Fix A/B/C arc this session executed step 1 of.

---

## 0. WHAT THIS SESSION DID

1. **Built GATE S** — the bound the seasonal arc was missing.
2. **Freed `ent_seas_amp_SH`** (25 → 26 params) and **ran the refit on Torch** (`16837149`, 40 tasks;
   round 2 `16905918`/`16905919`).
3. **Audited every number this arc introduced** for provenance, on Marcus's instruction. Four did not
   trace; all four were mine.
4. **Profiled the objective** and took **2.9×** off every evaluation.

⛔ **NOTHING IS ADOPTED. `CCX_MODE_CANONICAL` is STILL `from90`**, a 21-parameter ancestor.
⛔ **Nothing is running on Torch.**

---

## 1. ⭐⭐ THE RESULT, AGAINST THE PRE-REGISTRATION

Measured at a converged task of `16837149`; **39 of 40 tasks agree to 4e-4**.

| | 25-par winner | 26-par refit | |
|---|---|---|---|
| **P2** `sst_seas_amp_SH` prior-z | **−5.14** | **+0.24** | ✅ **the 5σ strain is GONE** |
| **P1** GATE S ocean limb | 0.330 ppm @ mo 4.19, z −12.30 | **0.438 @ 8.87, z +0.99** | ✅ **PASS** |
| **P3** SPO land limb | 2.48× obs | **1.68×** | ⚠ better, not closed |
| **P3** `npp_frac_NH` prior-z | −2.15 | **−0.05** | ✅ back at its prior |
| **P5** IRF(100) | 0.276 | **0.276** | ⛔ **unmoved** |
| `ent_seas_amp_SH` | — | **19.03 µmol/kg, z +1.11** | ✅ NOT strained |
| \|z\|>2 / \|z\|>3 | 5 / 3 | **3 / 2** | |

⭐ **THE HYPOTHESIS HELD.** One missing mechanism explained the worst prior violation, the seasonal
partition error and the land limb's excess **at once**, and it landed at a physically plausible
amplitude inside its own prior — not at a fudge-factor value.

⭐ **AND THE PRE-REGISTERED RISK DID NOT MATERIALIZE.** A conditional profile (everything else held)
put the optimum at ent ≈ 2, prior-z −3.41, and warned the strain might simply MOVE onto the new
coordinate. It did not. **That is the third time on this project a frozen slice has overstated a
cost** — treat conditional slices as hypotheses about a refit, never as predictions of one.

⛔ **DO NOT COMPARE −1446.763 TO THE 25-PAR −1482.6144.** Different space; the ancestors' own
reference points moved too (−1764.55 / −1812.23). The case rests on P1/P2/P3, not on that difference.

---

## 2. ⛔ WHAT DID **NOT** CLOSE — read this before claiming the arc is finished

- ⛔⛔ **P5 IS FALSIFIED. IRF(100) 0.276 → 0.276; ∫IRF@100 39.23 → 39.26.** Fixing the seasonal ocean
  physics did **not** lengthen the perturbation lifetime **by any amount**. ⇒ **The three problems
  are INDEPENDENT.** The handoff's hope — "constrain the seasonal and isotopic observables with the
  right mechanisms and the long lifetime falls out" — **does not happen**, and Fix C needs its own
  mechanism (the permanent-land-sink hypothesis, still untested).
  ⚠ **This is the pedagogically important failure**, because the emergent-lifetime claim is what the
  model exists to demonstrate.
- ⚠ **`sst_seas_amp_NH` got WORSE: −3.56 → −3.91, and is now the model's worst prior violation.**
  ⛔ **This is NOT "do the same fix in the NH".** The NH has no entrainment channel *by measurement*:
  NH-mean pCO₂ sits **0.30 months** from NH-mean SST (`CCX_ENT_SEAS_PEAK_MO`'s own derivation), so
  the NH really is solubility-dominated at the hemispheric mean. **A new question.**
- ⚠ The SH **land limb is 1.68×** and its phase is **11.19 against an observed 9.29** — ~2 months
  late. Improved, not right.
- `rep_dC` **+3.38**, still > 3.

---

## 3. ⛔ TWO BASINS, NOT ONE — AND I HAD IT BACKWARDS

Round 1's outlier **id 12 at −1508.7786** was labeled `CONVERGED` while its last restarts were
**wall-shortened with gain 0.0000**, so I flagged the label as overstating and leaned "budget
artifact". **Resumed with a 300 min budget (`16905918`) it ran cycle 3 with two FULL-LENGTH restarts
— 4,521 and 8,634 evals — both gaining exactly 0.0000, finishing in 44 of 300 min.**
⇒ **A GENUINE LOCAL OPTIMUM, 61.9 log-units above the main basin, found by 1 of 34 draws.**

| dispersion | draws | dominant basin | second basin |
|---|---|---|---|
| sd 1.0466 (measured) | 34 | 33 | **1** |
| sd 0.5233 (half, `16905919`) | 5 | 5 | 0 |

The second basin is reached only from the **wider** dispersion ⇒ consistent with it being genuinely
distant in u-space. ⚠ **5 narrow draws is a weak bound: it failed to find, it does not rule out.**
⇒ **Quote the survey as "one DOMINANT basin plus a second at −1508.78", never "one basin".**

---

## 4. ⭐ THE SPINUP — 2.9× OFF EVERY EVALUATION, AND WHAT IS LEFT

Marcus asked whether a 15-hour array for a "simple model" was just the parameter count. **It was not.**

| piece of one evaluation | before | after |
|---|---|---|
| `ccx_spinup()` | 0.1252 s (**84 %**) | **0.0178 s** (7.0×) |
| transient, 1750–2024 | 0.0282 s | unchanged |
| `ccx_loglik()`, ~20 streams | 0.0025 s | unchanged |
| **full objective** | 0.1404 s | **0.0483 s** (**2.9×**) |

**The physics was never the cost.** 96 state numbers, 13,200 RK4 steps / 52,800 derivative calls for
275 years in 0.028 s — **0.5 µs per call**, because the transient runs in C++. Re-deriving the 1750
equilibrium cost **4.4× the entire historical simulation**, because `ccx_spinup()` made **135
interpreted `ccx_deriv` calls**: 68 in the carbon Newton's 32-column finite-difference Jacobian
(**which runs whenever the PUMP is on, not just the conveyor**) and 67 building the two isotope
operators one column at a time.

**FIXED** by pointing the four call sites at **`ccx_deriv_fast()`** — same signature, same model, the
compiled twin `test-parity.R` already exercised.
⭐ **The objective moved 7.98e-14 relative (+1.155e-10 absolute)** — five orders **inside** the port
gate's own 1e-8 — so stored logposts, `port_targets.csv` and checkpoint `ref_logpost` stamps all
stayed valid. Consistent with the parity test's **analytic** bound of 8.5e-15 (reassociation of the
pump's 20 flux terms), which is 5 orders below the Newton's 1e-9 residual tolerance and 8 below its
1e-7 finite-difference step.

⇒ **WHAT IS LEFT, and it is a real piece of work:** the transient is now ~58 % of an evaluation and
the spinup ~37 %. Further gain has to come from building the two **isotope operators ANALYTICALLY** —
both tracers enter the derivative **linearly** (`R/spinup.R`'s own header says so) — instead of by 32
finite-difference columns each. That would remove ~66 of the remaining calls.

---

## 5. THE PROVENANCE AUDIT — four numbers that did not trace, all mine

1. ⛔ **`ENT_SEAS_AMP_SH_INBAND` said `"derived"` with a TYPED `value = 30`**, arithmetic in prose
   only — the exact `LAMBDA_C14` bug `constants.R`'s own header warns about. Computing it from named
   inputs gives **29.68**, and the prior center **10.9524** rather than 11.07: **the typed pair had
   already drifted from its own chain.**
2. **`0.369` was a free literal in three files** → registered as `ENT_SEAS_BAND_AREA_FRAC`,
   **provisional** (a geographic ratio with no cited source), and a test guards the *label*.
3. ⭐ **The prior width was re-derived, 0.45 → `ENT_SEAS_LOGSD` = 0.49848.** The approved 0.45 read
   the recorded "5–30" band at 2σ, but **the number 5 has no derivation anywhere**. It now comes from
   a geometric ceiling: the box mean cannot exceed the in-band amplitude, so the no-dilution limit
   sits at `log(1/area fraction)` above the center. **The in-band value lands at +2.000σ by
   construction**, and the recorded band corroborates at z −1.57 / +2.02.
4. **Invented test tolerances** (`z ∈ (1.5, 2.5)`, `|z| > 10`, `< 0.05 mo`) replaced by exact
   predictable quantities or **propagated typed precision**.

⭐ **The audit caught itself twice more through the repo's own ledgers:** the Takahashi coefficient
was **already registered** as `SST_PCO2_SENSITIVITY` (I had committed the very duplication I was
auditing for), and `test-constants.R`'s provisional ledger fired on the new area fraction.
⚠ Two inputs **stated rather than reconciled**: 3.0 K is the 40–90 S **band**, not
`SST_SEAS_AMP_SH_OBS`'s 1.746 K hemispheric mean; and the uncited 2150 µmol/kg surface DIC sits 5.6 %
above the GLODAP value GATE G scores against — worth a measured **0.11 σ**, so left as inherited.

---

## 6. ⚠ NON-OBVIOUS STATE

* **Torch: nothing running.** Outdirs on `/scratch`: `multistart_20260903_ent26` (round 1, 40 tasks)
  and `multistart_20260903_ent26_sd0p5` (5). Jobs `16837149` (ids 40–45 **canceled deliberately**),
  `16905918` (id 12 resume), `16905919` (half dispersion). `port_targets.csv` is at commit `80f212f`,
  **26 parameters, regenerated under the fast spinup** — shipped.
* ⭐ **`ccx_seed_unencodable()` (R/calibrate.R) is new and it is SEPARATE from the migration ON
  PURPOSE.** `ccx_migrate_par_set()` says what the ancestor **RAN** (which is why gates at stored
  modes read identically across 25 → 26); the seeder says where a **SEARCH** begins.
  ⚠ **`tr = "log"` has no 0, so a pre-26 ancestor's own state has PRIOR PROBABILITY ZERO** — not
  merely unencodable. `ccx_par_to_unc()` was hardened to refuse a non-finite encoding **by name**.
* ⛔ **SUITE: 1710 pass / 10 fail / 2 skip.** Two causes:
  - **SIX pre-existing**: five are "stored modes are 21-parameter files in a 26-parameter build"
    (`test-mode-decode.R:15/:29`, `test-mode-file.R:109×2/:203`) — **ADOPTION resolves these**; the
    sixth is `test-likelihood.R:596`'s `kz$hi <= 7000` guard rail, left failing for Marcus since 09-01.
  - **FOUR from this session** (`test-enso-demean.R:105`, `test-enso-split.R:236`,
    `test-seas-lag-split.R:150`/`:174`) — each migrates an ancestor then **ENCODES** it.
    ⭐ **Marcus ruled 09-03 that the migrated-ancestor question is NOT relevant** — once a 26-par mode
    is adopted it becomes the reference and nothing encodes a pre-26 ancestor again.
    ⚠ **BUT `test-enso-demean.R:105` deserves separating out**: it is the **Ruling A regression
    guard** ("the one that says we shipped the thing that was TESTED") and it is currently **DARK**,
    because its two anchors (−1568.4936 / −1512.0151, gain +56.4785) are stale in a 26-name space.
    ⛔ **No fill repairs it** — measured: seeded at the init it reads −1880.10 / −1829.09, gain
    +51.0081. It needs **re-measuring**, which is what a parameter-count change always demands.
* **`%in%` at 7.3 % of spinup self-time** is a free win nobody has taken.
* ⚠ **`tau_ex_seas_amp` is STILL implemented, defaulted 0 and unfitted** — deliberately not freed, so
  P2 had one mechanism to attribute to. Freeing it next reruns the whole 26 → 27 migration story.
* `ccx_default_params()$ent_seas_amp_SH` **stays 0 deliberately** — flip it to the init **when the
  refit is adopted**, not before.

---

## 7. ⇒ THE OPEN DECISIONS, IN ORDER

1. ⭐⭐ **ADOPT THE 26-PARAMETER MODE?** It is the live question. Adoption also clears five of the ten
   failing tests and lets the port-target reference points move off the 08-31 ancestors.
2. ⭐ **`sst_seas_amp_NH` at −3.91** — the new worst violation, and explicitly **not** the SH fix
   again. Needs its own diagnosis.
3. **Fix C on its own terms.** P5 says the lifetime problem is independent. The pre-registered
   measurement — **the pulse partition at 1000+ yr on the Joos PD100 background** — is still owed and
   still void from the 09-03 attempt.
4. **Fix B** (the ENSO ocean sign error) is untouched; its cheap pre-test — the model's tropical
   surface pCO₂ disequilibrium against the climatology already on disk — has not been run.
5. **Re-measure `test-enso-demean.R:105`'s anchors** so the Ruling A guard stops being dark.
6. **Analytic isotope operators** (§4) if more speed is wanted.
7. **Still owed from the previous handoff:** the 34 tied SPO copies on touch; the bare-overlay lint's
   remaining occurrences; `test-likelihood.R:596`'s `kz$hi <= 7000` guard rail.

⛔ **AND THE STANDING RULE THIS ARC DID NOT BREAK, WORTH KEEPING:** every fix here ADDS a mechanism
that makes an observable easier to match. **A mechanism that improves a fit is not thereby right.**
Fix A was judged on whether it relaxed a STRAINED PRIOR (P2: −5.14 → +0.24) and shrank a FITTED
COMPENSATOR (P3: 2.48× → 1.68×) — not on Δlogpost, which was never quoted as evidence.
