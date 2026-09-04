# ASSESSMENT — what CarbonCycleEmulator still needs before it can go public
# Written 2026-09-04g. **Every model number below was MEASURED today at `CCX_MODE_CANONICAL`
# (`ent26`)**, not recalled: `diag_design_gates_at_mode.R`, `lib_seas_limbs.R`,
# `diag_gateS_indep_and_fixB.R`, and direct reads of `R/constants.R`. Suite 1757/0/0/4.

## 0. THE STANDARD THIS IS JUDGED AGAINST — Marcus's own, 2026-09-03

> "This is a pedagogical model, not an emulator. Missing Joos is not a dealbreaker... for a
> pedagogical model, having non-physical ENSO and seasonal behavior is problematic. We are trying to
> show how in order to match observed seasonal and isotopic variables certain behaviors (like long
> perturbation lifetimes) are **emergent**."

⇒ **The product is the CHAIN, not the endpoint.** A defect blocks release if it breaks the chain:
- **an observable matched BY CANCELLATION is a broken link, however good the match;**
- **a wrong-signed mechanism cancelled by a fitted coefficient is worse than a visible miss** — a
  reader takes the wrong physics away, the one thing a teaching model must not do;
- **a benchmark miss with the right mechanism is acceptable, and is a research question.**

## 1. VERDICT

**Not ready — but the gap is now much narrower than the record says, and it is not where the record
says it is.** Of the three broken links stated on 09-03, **one is fixed, one is partly fixed but
still ungated on its larger half, and one is unchanged and is the real blocker.**

The heaviest remaining work is **not** scientific. It is that **the two public-facing documents
describe a different model from the one in the repo** (§3), and that the repo has **no licence** (§4).

---

## 2. TIER 1 — THE CHAIN. Two links, one of them the release blocker

### 2a. ✅ FIXED — the seasonal OCEAN limb's phase
`ent26` puts the SPO ocean limb at **8.87 months against an observed 8.52 [7.82, 9.20]**, z **+1.00,
GATE S PASSES** — from **3.35 months and z −12.30** before the 26-parameter refit. And 09-04g
corroborated the target itself against a product that never passes through the model (SOM-FFN
ΔpCO₂, bracket [7.41, 10.41]) ⇒ `collect_2026-09-04g`. **This link is repaired and independently
checked.**

### 2b. ⚠ PARTLY FIXED, AND ITS LARGER HALF IS UNGATED — the seasonal partition

| SPO limb | model `ent26` | observed (inverted) | ratio | phase | obs phase | gated? |
|---|---|---|---|---|---|---|
| **SH land** | **1.1495** | 0.6830 | **1.683×** | **11.19 mo** | 9.29 mo | ⛔ **NO** |
| SH ocean | 0.4373 | 0.5220 | 0.838× | 8.87 mo | 8.52 mo | ✅ GATE S |
| NH origin | 1.0554 | — | — | 6.38 mo | — | no |
| **TOTAL** | **1.1513** | 1.1680 | **0.984×** | 9.03 mo | 9.01 mo | scored |

⭐ **The total is matched to 1.6 % and 0.02 months. That is the problem, not the achievement:**
the scalar sum of the limbs is **2.6457 against a vector total of 1.1513 — 56 % CANCELS.** The land
limb **alone** is 0.98× the entire observed seasonal cycle.

⛔ **AND NOTHING SCORES THE LAND HALF.** `SPO_SEAS_AMP_LAND_INV` (0.683) and
`SPO_SEAS_LAND_PHASE_INV` (9.29) are **registered constants read by no gate** — only by
`diag_adoption_read_ent26.R` and a constants-tie test (verified by grep, not recalled). Gate S
scores the ocean limb only. So the model is **1.683× too large and 1.90 months late on the half of
the partition that no test looks at.**
⇒ **THE CHEAPEST HIGH-VALUE ITEM IN THE REPO: a gate L, the mirror of gate S.** The estimator
(`lib_seas_limbs.R`), the knockout (`SL_CASES$SH_land`) and the observed constants all already
exist. ⚠ **One thing must be derived first**: the land constants carry **no registered interval**
(only `..._OCEAN_PHASE_INV` has `_LO`/`_HI`), so a bound has to come from the same bootstrap that
produced the ocean's — **not invented after seeing the model's 11.19.**

### 2c. ⛔ **UNCHANGED, AND THIS IS THE RELEASE BLOCKER — the ENSO ocean response**

The model's only physical ENSO→ocean path is SST→solubility, and it has the **wrong sign**. Measured
today (`diag_gateS_indep_and_fixB.R` §B4, model's own annual ocean uptake regressed on annual
Niño3.4 with a year term, n = 66 — the same estimator on both sides):

| arm | slope GtC/yr per index | se | r |
|---|---|---|---|
| **GCB (observed)** | **+0.1153** | 0.0246 | **+0.488** |
| model, `ent26` | **+0.0532** | 0.0303 | +0.207 |
| model, **solubility only** (patch off) | **−0.1274** | 0.0318 | **−0.432** |

⭐ **This is exactly the defect the standard in §0 names as disqualifying**: a wrong-signed mechanism
cancelled by a fitted coefficient. Four `gamma_enso_*` parameters exist to paper over it, and
**0.356 of coefficient buys only +0.181 of net slope** because it must first cancel the −0.127. The
model still ends up at **0.46× the observed sensitivity**.
⇒ A student switching ENSO on in the app sees roughly the right answer produced by the wrong
physics. **That is the one outcome a teaching model cannot ship.**

✅ **AND FIX B IS NOW SPECIFIED AND PRICED** (09-04g): the equatorial-Pacific pCO₂ reservoir is
**+55.5 µatm** above the global ocean mean, the observed sensitivity needs only **0.24×** of it, and
the model **has no tropical box at all** — two hemispheric mixed layers, so its representable
tropical-minus-global contrast is exactly zero. **The fix is structural, and its size is right.**

### 2d. Not a separate defect — variability
GATE V fails at **−2.67σ** (sd 0.698 vs 0.911 ± 0.080). ⚠ **Marcus, 09-04f: a FAIL there is not a
blocker**, and it is recorded at the gate. It is also **downstream of 2c** — a model with an
anti-phase ocean ENSO response should be short of variability — and its own knockouts point at
Fix B (ENSO 66 % of the variance). **Fix 2c and re-measure; do not chase this separately.**

---

## 3. TIER 2 — THE DOCUMENTS DESCRIBE A DIFFERENT MODEL. This is the largest single gap

Nothing here is hard; all of it is disqualifying if a reader reaches it first.

1. ⛔⛔ **`README.md` says the model is "calibrated by Bayesian MCMC". IT IS NOT.** There is no
   posterior; `calibration/output/posterior_draws.rds` does not exist. The model sits at a
   **MAP mode found by multistart optimisation**. ✅ **The app is honest about this in-product**
   ("A single best fit, not yet a posterior — no uncertainty ranges are shown"); the README is not.
2. ⛔ **`README.md`'s status line is stale**: *"model core built and running end-to-end on
   uncalibrated defaults; calibration and app pending."* Both halves are wrong — `ent26` was adopted
   2026-09-04 and the app has resolved the calibrated mode since 08-27. This is the first thing a
   visitor reads.
3. ⛔ **`DESIGN.md` §Calibration promises "posterior ensemble shipped with app"** and §5.3 specifies
   4 chains with R̂ < 1.05. Neither exists. Either the promise changes or the posterior is run.
4. ⛔⛔ **`DESIGN.md` §6 — "Sanity gates (all must pass before headline claims)" — describes a
   RETIRED gate set at a QUARANTINED mode.** It still presents **gate 4 (airborne fraction)** as a
   must-pass with a full analysis section, though gate 4 was retired 09-04 for having no power; it
   quotes **`from90` as "the canonical mode"**, though `from90` is quarantined and errors by name;
   and it contains **no gate V, S, Q or G**. ⇒ **The document that defines the model's own acceptance
   criteria is the most out-of-date file in the repo.**
5. ⚠ **"All must pass" is currently false**: at `ent26`, **GATE V fails (−2.67σ)** and **GATE 5
   fails (bomb ¹⁴C NH peak +2.17σ)**. Gate 5's miss is a known forced residual — one `tau_ex` cannot
   serve both the gradient and the bomb lag. **Either the standard is restated with its exceptions
   named, or the claims wait.** Silently leaving "all must pass" beside two failures is worse than
   either.
6. ⚠ **20 of 48 registered constants carry `status = "provisional"`**, including `ALK_SURFACE`,
   `CO2_PI_PPM`, `OCEAN_AREA_*`, `NPP_GLOBAL_PI` and all the `SPO_SEAS_*` family. Many are
   conservative labelling rather than genuinely unsourced — but **a public release needs that triage
   done and the label to mean one thing.**

**Current gate status at `ent26`, measured today** — PASS: **G** (−0.06), **Q** (+1.27),
**7** (land +0.59 / ocean −0.32), **S** (+1.00). FAIL: **V** (−2.67), **5** (+2.17).
Retired: 4, 8, 10. Comparison only: 12/12a/12b.

---

## 4. TIER 3 — REPO MECHANICS

1. ⛔⛔ **THERE IS NO LICENCE FILE.** Without one the code is "all rights reserved" by default and
   nobody may legally reuse it. **This is the single hardest blocker in the document and the
   cheapest to clear.** It is also a decision only Marcus can make.
2. ⚠ **No git remote.** 82 MB of `.git`, 1043 tracked files — publishable as-is once a home is chosen.
3. ✅ **The data story is already right**, and is better than most released models: `data-raw/` is
   3.5 GB and gitignored, with a tracked **`MANIFEST.csv` (URL + access date + SHA-256 + citation)**
   and a one-line reproduce command in the README. The two small seasonality extracts are
   deliberately un-ignored so a fresh clone runs without a 1.2 GB download. **Leave this alone.**
4. ⚠ **`app/DEPLOY.md` exists but the app has never been deployed.** A smoke test today: `app/global.R`
   sources clean and resolves the canonical mode.
5. ⚠ **No CITATION file and no archived DOI** (Zenodo). Needed if the app is to be cited in teaching.

---

## 5. WHAT IS EXPLICITLY **NOT** A BLOCKER

- ⛔ **The Joos IRF gap.** IRF(100) **0.276 vs 0.409**. Gate 12 was demoted to a **comparison** on
  09-04e: Joos is another *model*, and **no observation constrains a CO₂ perturbation lifetime**.
  ⚠⚠ **"P5 FALSIFIED" is a withdrawn label; every record carrying it predates 09-04e.** What is
  still owed is a **hypothesis** for why the lifetime is short — Marcus asked for one explicitly —
  not a passing number. The tail *shape* is already inside the band (0.710 vs 0.787).
- **GATE V** (§2d) — Marcus ruled it non-blocking, at the gate.
- **The absence of a posterior** is not a *scientific* blocker for a pedagogical release, provided
  §3.1 and §3.3 are corrected so nothing claims one. ⭐ **Both stated Hessian blockers are gone at
  `ent26`** (cond 7.394e+04, nothing step-unstable), so it is now worth attempting — but as an
  upgrade, not a gate.

---

## 6. RECOMMENDED ORDERING

**Before anything is public**
1. **Licence.** Marcus's decision; blocks everything else. (§4.1)
2. **Correct `README.md`** — the MCMC claim and the status line. Two sentences. (§3.1, §3.2)
3. **Rewrite `DESIGN.md` §6** against the 09-04 ledger, and restate or qualify "all must pass".
   (§3.4, §3.5)

**The science that decides whether it should be public**
4. **Fix B — give the ocean an ENSO path with the right sign.** The blocker (§2c). Specified,
   priced, structural: scope the tropical box before writing code.
5. **Gate L — the mirror of gate S on the land limb.** Cheap, and it is the test that would have
   caught 1.683× / 1.90 months. Derive its interval from the ocean's bootstrap FIRST. (§2b)
6. **Re-measure gate V after 4.** Do not chase it before.

**Upgrades, not gates**
7. A posterior (now unblocked); a Joos hypothesis; the provisional-constant triage; CITATION + DOI.

⚠ **One caution on ordering.** Steps 4 and 5 both change the seasonal/ENSO partition, and step 5's
bound must be derived **before** step 4 runs — otherwise gate L is being written against a model it
has already seen, which is the failure `gate_reads_its_own_output` records.
