# Handoff — CarbonCycleEmulator, 2026-09-04
# **THE 26-PARAMETER MODE IS ADOPTED. `CCX_MODE_CANONICAL` = `ent26`.**
# **⭐ THE SUITE IS FULLY GREEN — 1737 / 0 / 0 / 4 — for the first time in this arc.**
# **⛔ P5 IS STILL FALSIFIED, AND GATE 4 GOT WORSE. Neither is fixed by the adoption.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, commits
`5150cf9..6933e1d` (4).
⚠ **Sessions launch from `FaIRtoFrEDI/`; ALL of this is in `CarbonCycleEmulator/`.** Use `git -C <abspath>`.

**Read before this one:** `handoff_2026-09-03_ent26_refit_and_the_spinup.md` — the refit this adopts.

---

## 0. WHAT THIS SESSION DID

1. **Pulled the refit off Torch** — ⚠ it had never been pulled; the local outdir was EMPTY.
2. **Promoted and ADOPTED** the 26-par mode; quarantined `from90` and `pin90`.
3. **Re-measured all five pre-registered claims AT THE ADOPTED FILE.** All reproduce.
4. **Found three silent gates**, none in the model.
5. **Answered the `kz` question** (Marcus): tested the observation instead of the bracket.
6. **Cleaned memory** and took the suite to **0 problems**.

---

## 1. ⭐⭐ THE ADOPTION

`calibration/output/refit_20260903_ent26/mode_fit_pumpN.rds`, **26 par, logpost −1446.7627**,
promoted from **start id 18** of 40 by the new `calibration/promote_multistart_mode.R` (5 gates; the
start is **COMPUTED from the directory**, never typed — 39 of 40 agree to 3.93e-4, so "the best one"
is a fact about the directory, not something to remember). First multistart result ever promoted,
which is why no such tool existed.

| | 25-par incumbent | **ent26** | |
|---|---|---|---|
| P2 `sst_seas_amp_SH` z | −5.139 | **+0.237** | ✅ |
| P1 GATE S | 0.330 ppm @ 4.19, z −12.30 | **0.437 @ 8.87, z +1.00** | ✅ **FAIL → PASS** |
| P3 SPO land limb | 2.475× | **1.683×** | ⚠ better, not closed |
| P3 `npp_frac_NH` z | −2.153 | **−0.051** | ✅ |
| P5 IRF(100) | 0.276 | **0.276** | ⛔ **unmoved** |
| \|z\|>2 / \|z\|>3 | 5 / 3 | **3 / 2** | |

⭐ **AND THE HALF THE PREVIOUS HANDOFF COULD NOT STATE: THE LIKELIHOOD MOVED +20.41.** The logposts
are NOT comparable (different spaces) but the 21 streams and their sigmas are identical across the
builds, so the likelihood is. ⇒ **The fit improved; the prior was not merely paid.** Use this form
for every future space change.

⚠ **P3's ratio needs the LAND-inverted denominator** (`SPO_SEAS_AMP_LAND_INV` = 0.683), not
`DG_S_AMP_OBS` (the OCEAN one). Using the wrong one overstates it by a constant **1.31×** — the
same factor on two independent vectors, which is the tell.

⭐ **THE HESSIAN BLOCKER MOVED.** −H is PD, **condition number 7.394e+04**, softest/stiffest
eigen-sd ratio **272×**, and **NO parameter is step-unstable** — `h_ml`'s own eps/3–3eps
disagreement is **1.20 %** against a 2 % tolerance. `h_ml` = 134.15 m ± 16.20 on [30, 200], so the
nearest bound is **4.1σ** away, not the 1.5σ that was the stated reason a sampler would fail.
⚠ **The 1.11e6 on record is `from90`, on an objective three changes older — INDICATIVE, not
like-for-like.** ⇒ **A posterior is worth re-attempting.**

---

## 2. ⛔ WHAT THE ADOPTION DID **NOT** FIX

- ⛔⛔ **P5 STILL FALSIFIED.** IRF(100) 0.276 → 0.276. Fixing the seasonal ocean physics bought **no**
  extra perturbation lifetime. The three problems are INDEPENDENT; **Fix C needs its own mechanism**
  (the permanent-land-sink hypothesis, still untested). This is the pedagogically important failure.
- ⛔ **GATE 4 FAILS AND ITS MARGIN GOT WORSE.** The AF *level* is fine (0.425 vs GCB 0.431); the bound
  is on decadal SPREAD, "must not be SMOOTHER than observed": **sd 0.025 vs GCB 0.051, ratio 0.48**,
  against **0.76 for the uncalibrated defaults measured in the SAME run**. The visible culprit is
  the **2020s** — model 0.40 where GCB gives 0.50. ⚠ The 0.032 recorded at `from90` crosses an
  objective change, so "worse than from90" is INDICATIVE; "worse than defaults" is measured.
- ⛔ **GATE 5 FAILS** on the NH peak YEAR (z **+2.17**). SH improved +2.07 → +1.42.
- ⚠ **`sst_seas_amp_NH` −3.558 → −3.911 is now the worst prior violation**, and explicitly **NOT the
  SH fix repeated** — the NH has no entrainment channel *by measurement*.
- ⚠ **The deep ocean is at z +1.86** — inside 2σ but on the young/better-ventilated side, with only
  ~450 m²/yr of `kz` margin. See §4.

Gates at `ent26`: ✅ 7 (ocean z −0.32), Q (1.27), G (−0.06), S (+1.00). ⛔ 4 and 5.
⇒ **The adoption fixed the SEASONAL gates and moved neither standing failure** — consistent with P5.

---

## 3. ⭐ THREE SILENT GATES, NONE IN THE MODEL

1. ⛔ **`recompute_hessian.R`'s step table printed its header and ZERO ROWS.** It indexed
   `md$hess_eps`, absent on a promoted file; `NULL / x` is `numeric(0)`, `sprintf()` returns
   `character(0)`, `cat()` prints nothing — **and the `*** UNSTABLE` step-stability verdict was in
   that row.** Both branches now mutation-tested.
2. ⛔ **Its "condition number" was the RECIPROCAL** — `max/min` over all-negative eigenvalues, the
   two signs canceling into a plausible 1.352e-05 for a true 7.394e+04. **Wrong for every mode this
   script ever produced.** (`run_modefind_pump_arms.R` used `abs()` and is unaffected.) `21x21` was
   also a typed label in a 26-par build.
3. ⛔ **Retiring an arm silently UN-LINTS its path.** The hardcode lint builds its directory list
   from `CCX_MODE_FILES`, so quarantining two arms dropped them from scope at exactly the moment
   **seven live lines across four files** went stale. ⚠ **Widening that lint was the WRONG fix** (it
   swallows the `luc_arm_*`/`ridge_pin*` scratch arms its own SCOPE paragraph excludes) and is
   recorded as such. **"Should this go through the accessor?" and "does this path still EXIST?" are
   two questions and need two tests.** The second found an **eighth** occurrence stale since 08-25.

---

## 4. ⭐ THE `kz` RULING — AND IT GENERALIZES

**Marcus: "the only tests that matter are the ones against observations or physics."**
Applied to the one standing failure it dissolved it: **`kz` is not directly observed; the deep-ocean
Δ¹⁴C is.**

`expect_lte(kz$hi, 7000)` bounded a **latent parameter's SUPPORT** and justified itself by citing
"the observed −150 to −200" — which `R/calibrate.R`'s own header records as **an uncited
recollection**, on the bottom THREE boxes rather than the bottom box the likelihood scores. The
09-01 re-bisection replaced it with GLODAPv2's sourced **−175.26 ± 10.259 ‰**, which is *why*
`kz$hi` moved past 7000. ⚠ It also had **no power**: `kz` = 6356 at the mode, BELOW its own bound.

✅ **Replaced by the observable**, within 2σ of `ccx_deep_d14c_target()` (read, never retyped).
Mutation table — and it says something the bracket does not:

| kz | 4379.1 | 5000 | **6356 (mode)** | 7000 | 8109.9 | 10686 |
|---|---|---|---|---|---|---|
| deep Δ¹⁴C | −196.94 | −181.05 | **−156.14** | −147.41 | −135.36 | −116.49 |
| z | −2.11 | −0.57 | **+1.86** | +2.71 | +3.89 | +5.73 |

It fails at the runaway that motivated the original bound. ⚠ **And at BOTH ENDPOINTS of the shipped
bracket** — not a contradiction (a prior SUPPORT is not a 2σ interval), but the retired comment's
promise was **not literally true at the bracket's own edges**. The 2σ window is `kz` ∈ ~(4400, 6800).
**KEPT** `kz$hi < 10686`: an ORDERING against a MEASURED runaway is a different KIND of claim.

---

## 5. THE SUITE: 10 PROBLEMS → **0**

⛔ **COUNT ERRORS SEPARATELY. `as.data.frame(test_dir(...))$failed` DOES NOT INCLUDE THEM**, and
reading only that field made me report "1719 / 1 / 4" for a state that had two more errors in it.
**Report fail + error.**

Adoption cleared six; the rest were repaired **at the PREMISE, never at the tolerance**:
- **`test-so-entrainment.R` (15)** — an IDENTITY control whose fixture read its zero baseline off
  `ccx_default_params()`, which the adoption flipped 0 → 10.9524. The claim (absent ≡ zero) was
  **measured intact, bit for bit, both cores**. ⚠ **Two assertions did NOT fail and were the worse
  half**: P0.2's mutation guard and the rectification bound had quietly become ON-vs-ON comparisons
  and kept passing while measuring less than they claimed.
- **`test-ent-seas-fitted.R:157` (1)** — a POLICY assertion that named itself as the thing to change.
  ⚠ Its replacement was first written one assertion too strong (default == the derived constant to
  1e-9); that fails by **4.41e-07** because `init` must be a six-decimal literal — `R/calibrate.R` is
  sourced before `R/constants.R`. Removed; the file's first test already bounds that drift by the
  literal's own typed precision.
- **`test-mode-decode.R` (4)** — a PROVENANCE guard asserting the h_ml band trap is PRESENT. ⭐ **It
  is gone**: `ent26` was fitted on the shipped support, so `u_mode` decodes to `par_mode` exactly.
  Deleting the tests would leave the trap-handling code exercised by NOTHING, so the trap half now
  runs against an **explicit override fixture** (with a mutation guard on the fixture itself).
- **The ANCESTOR ENCODING (2 errors)** — `test-seas-lag-split.R:174`, `test-enso-demean.R:105`. Both
  migrated a pre-26 ancestor and ENCODED it; `ent_seas_amp_SH = 0` has no image under `tr = "log"`.
  **Asserting it encodes was asserting something FALSE about the model.** Now they assert the
  **REFUSAL, by name** (the 09-03 hardening nothing was testing), and the Ruling A guard scores at
  the canonical mode asserting **the GAP**: **+56.4785 → +45.1618**, the expected direction, because
  the refit absorbed part of the ENSO mean into other coordinates.
- **The PARITY TIMING GATE (1)** — `el < 0.05` s. Never a parity test: it measured the MACHINE, at a
  **median 0.0490 s with 7 of 15 over**. Removed, not widened.

**4 skips, all declared**, incl. `test-mode-file.R`'s free-vs-pinned check reporting itself DARK.

---

## 6. ⚠ NON-OBVIOUS STATE

* **Torch: nothing running.** The ent26 outdirs are now LOCAL as well as on `/scratch`.
* ⛔ **`pin90` RETIRED and `PIN_PRIOR_CREDIT` retired WITH it** — both sides were the model's own
  arms scored by its own objective against a prior this project chose. ⚠ **Cost stated:** the
  free-vs-pinned check now has **NO POWER** (one arm) and reports DARK. **A 26-par PINNED refit is
  what restores it.**
* ⚠ **`ccx_default_params()$ent_seas_amp_SH` is now 10.9524**, the derived prior center — NOT the
  fitted 19.029. `R/model.R`'s guard is `!= 0`, so zero SHORT-CIRCUITS the whole entrainment path.
* ⚠ **`tau_ex_seas_amp` is STILL implemented, defaulted 0 and unfitted.** Freeing it next reruns the
  whole 26 → 27 migration story.
* **`%in%` at 7.3 % of spinup self-time** is still a free win nobody has taken; the analytic isotope
  operators (~66 of the remaining `ccx_deriv` calls) are the real remaining speedup.
* **Memory**: `MEMORY.md` 16.6 KB and `INDEX_ccx.md` 17.0 KB against 12/14 KB soft targets — both
  were already over before this session, both under the 18 KB hard ceiling. 509 files, **0 dangling
  links, 0 orphans**. A restructure is its own job.
* ⚠ **The machine had an unrelated `slr-refresh-2025` pymagicc/MAGICC job running** (load 11.85 on
  10 cores). Check `uptime` before timing anything.

---

## 7. ⇒ THE OPEN DECISIONS, IN ORDER

1. ⭐⭐ **GATE 4: why did the AF decadal spread get SMOOTHER?** 0.48× observed against defaults'
   0.76×, with the 2020s the visible culprit. This is the clearest new lead the adoption produced.
2. ⭐ **Fix C on its own terms.** P5 says the lifetime problem is INDEPENDENT. The pre-registered
   measurement — the pulse partition at 1000+ yr on the Joos PD100 background — is **still owed**.
3. ⭐ **`sst_seas_amp_NH` at −3.91**, the new worst violation. Needs its own diagnosis; it is **not**
   the SH fix again.
4. **Fix B** (the ENSO ocean sign error) is untouched; its cheap pre-test — the model's tropical
   surface pCO₂ disequilibrium against the climatology already on disk — has **not been run**.
5. **A posterior.** §1 says the two stated blockers are gone at the adopted mode.
6. **A 26-par PINNED refit**, if the free-vs-pinned check is worth having back.
7. **Still owed:** the 34 tied SPO copies on touch; the bare-overlay lint's remaining occurrences.

⛔ **AND THE STANDING RULE THIS SESSION ADDED TO:** a mechanism that improves a fit is not thereby
right — judge it on the STRAINED PRIOR it releases and the COMPENSATOR it shrinks. To which:
⭐ **a test that cites an observation to justify bounding a latent parameter should test the
observation instead**, and ⭐ **a check that measures the machine, or that cannot fail, is not a
check** — remove it or give it power, never widen it.
