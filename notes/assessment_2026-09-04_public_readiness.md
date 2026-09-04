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

### 2b. ⛔ **CORRECTED 2026-09-04g — THIS SECTION'S ORIGINAL CLAIM WAS WRONG, AND WHAT REPLACED IT IS WORSE FOR A DIFFERENT REASON**

**WHAT I ORIGINALLY WROTE HERE:** *"the SPO land limb is 1.683× observed and 1.90 months late, and
56 % of the seasonal amplitude cancels."* ⛔ **RETRACTED.** That compared `SL_CASES$SH_land` — an
**ORIGIN** split, SH-land only — against `SPO_SEAS_AMP_LAND_INV`, a **TYPE** split covering *all*
land by δ¹³C signature. Three different things are called "the land limb"
([[verify_the_quantity_not_the_word]]). The 56 % cancellation is real but belongs to the ORIGIN
split, where an antiphase `NH_origin` limb cancels against SH — **interhemispheric transport, not
the land/ocean partition the pedagogical claim rests on.**

**LIKE-FOR-LIKE AT `ent26`** (channel-sum route, the same channel sets the observed constants use):

| SPO limb | model | observed (95 % bootstrap) | ratio | phase err | inside interval? |
|---|---|---|---|---|---|
| **land** | 0.7153 @ 8.86 | 0.681 [0.479, 0.905] @ 9.30 [8.78, 9.77] | **1.05×** | −0.44 mo | ✅ both |
| **ocean** | 0.4046 @ 9.17 | 0.524 [0.309, 0.728] @ 8.52 [7.83, 9.20] | **0.77×** | +0.65 mo | ✅ both |
| total | 1.1513 @ 9.03 | 1.168 @ 9.01 | 0.98× | +0.02 mo | — |

⭐ **The limbs ADD, they do not cancel**: scalar sum 1.1199 vs vector total 1.1513 = **−3 %**.
⭐ **The δ¹³C-per-ppm partition test agrees**: **MLO 0.97×, SPO 1.21×** at `ent26`, against the
recorded **1.53× / 2.54×**. The cycle is mildly too photosynthetic at SPO, not 2.5×.
⚠ **The observed intervals are WIDE** (±30 % on amplitude) because the inversion propagates the
signature spread, so this is a **weak pass, not a tight one**. But it is the opposite of an excess.

⇒ **The seasonal link is in much better shape than the 09-03 record says, and "gate L" is NOT the
priority I claimed.**

### 2b-bis. ⛔⛔ **THE REAL TIER-1 FINDING: THE METHOD THAT PRODUCES THE SEASONAL TARGETS NO LONGER RUNS**

`diag_seas_signature_inversion.R` — which produced **gate S's target 8.52** and all four
`SPO_SEAS_*_INV` constants — **errors out at the canonical mode** (`Error: sO < 0 is not TRUE`).
Its own antiphase gate drops **all four ocean channels** (1.4–5.6 months off, tolerance 1.0), so
`s_O` is NaN.

**The cause is isolated, not guessed.** `alpha_as_tdep = 0` (the bit-exact pre-2026-09-02 model)
restores it — two channels pass, `s_O` = −0.00461, separation 10.2× — and it **reproduces the
registered interval exactly** (8.52 [7.83, 9.20] vs the registered [7.82, 9.20]). ⇒ **the 09-02
temperature-dependent air-sea ¹³C alphas falsified the inversion's ocean premise.** That is
**physics, not a bug**: a fractionation varying with seasonal SST makes the ocean limb's isotopic
signature rotate over the year, so it is no longer a signed scalar.

⇒ **Consequences for release:**
1. **The four `SPO_SEAS_*_INV` constants are PROVENANCE, not reproducible targets.** A reader who
   re-runs the named script gets an error.
2. ⭐⭐ **The 09-04g pCO₂ corroboration is now LOAD-BEARING**: the SOM-FFN bracket [7.41, 10.41] is
   the **only live support** for gate S's target. Gate S survives on it — but only because that work
   happened to be done first.
3. ⚠ **Nothing noticed for two days, and gate S was BUILT on 09-03 — after the premise broke.** The
   suite is green because this is a diagnostic, not a test. ⇒ **a constant's provenance script
   belongs in the suite, at minimum as a "does it still run" smoke test.**

🐛 **And a second bug in the same file, now fixed:** `p0$ent_seas_amp_SH <- Sys.getenv("CCX_ENT_AMP",
"0")` was **unconditional**, overwriting the FITTED 19.029 with 0 on every run while the banner
printed the canonical mode's filename. Its justifying comment went stale on 09-03 when the parameter
became fitted (25 → 26). The mode's value is now used unless an override is set *and announced*, with
a guard that errors if a fitted parameter arrives absent.

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
5. **Decide what replaces the two-signature inversion** (§2b-bis). It is the provenance of four
   registered constants and it no longer runs. Options, none of them free — **this is a
   methodological choice and it is Marcus's**:
   (a) **retire it** and rebase the seasonal targets on independent products (the SOM-FFN route is
   already built and already carries gate S);
   (b) **generalise it** to a rotating ocean signature — a two-vector rather than two-scalar
   inversion, which is the physically honest version of the same idea;
   (c) **freeze it at `alpha_as_tdep = 0`** as declared provenance only, and say so at every constant.
   ⚠ A "gate L" depends on this and should NOT be built before it is settled.
6. **Re-measure gate V after 4.** Do not chase it before.
7. **Put the provenance scripts in the suite** as run-only smoke tests, so a constant whose
   generator has stopped working cannot go unnoticed for days again.

**Upgrades, not gates**
8. A posterior (now unblocked); a Joos hypothesis; the provisional-constant triage; CITATION + DOI.

⚠ **One caution on ordering.** Steps 4 and 5 both change the seasonal/ENSO partition, and step 5's
bound must be derived **before** step 4 runs — otherwise gate L is being written against a model it
has already seen, which is the failure `gate_reads_its_own_output` records.
