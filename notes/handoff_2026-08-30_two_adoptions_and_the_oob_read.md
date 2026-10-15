# Handoff — CarbonCycleEmulator, 2026-08-30
# **BOTH OPEN CALLS ADOPTED. THE ADOPTION EXPOSED AN OUT-OF-BOUNDS READ, NOW FIXED.**
# **NEXT: 7 attributed test failures need a RULING, then the OWED 21-param refit.**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, **clean at `a2298dc`**.
**Suite 1227 pass / 7 FAIL / 2 skip.** Nothing running. 3 commits; continues
`handoff_2026-08-29c_diffuse_light_priced.md`.

⚠ **SESSION CWD WAS `FaIRtoFrEDI/`; ALL THE CODE WORK IS IN `CarbonCycleEmulator/`.**
⚠ **THE SUITE IS NOT GREEN, AND THAT IS DELIBERATE.** The 7 failures are ATTRIBUTED and were
**left untouched** — a previously passing test is not edited to make it pass. §4 lists what each
needs. **Do not "fix" them without a ruling from Marcus.**
⚠ **THE 21-PARAM REFIT IS OWED AND NOT RUN.** The calibrated 21 are a PRE-adoption vector being
read under a POST-adoption objective. Nothing quantitative from them is quotable until it lands.

---

## 0. STATE IN EIGHT LINES

1. **Memory re-cut**: root and `INDEX_ccx` were over budget; split into 2 new sub-indexes. §1
2. **The FACE gate CLEARED — and it was framed around the wrong number.** §2
3. **The "3 kinks, sparse" verdict was BAND-DEPENDENT; there are 26 on the live support.** §3
4. **A conservative C1 remap exists, kills all 26, and is NOT the free code fix the plan assumed.** §3
5. **Marcus ADOPTED both** `gamma_diff = 0.25` and the C1 remap. §4
6. ⇒ **The adoption exposed an OUT-OF-BOUNDS READ live for two days.** FIXED, mutation-tested. §5
7. **7 suite failures, all attributed to `gamma_diff`, none to the remap.** UNTOUCHED. §4
8. ⇒ **NEXT: rule on the 7, then run the refit.** §6

---

## 1. MEMORY WAS RE-CUT (in `FaIRtoFrEDI/`'s memory dir, which CCX shares)

`INDEX_ccx.md` was **18473 B, OVER its 18 KB HARD ceiling**; `MEMORY.md` was 15833 B, over soft for
a fifth session. Both fixed **structurally**, not by compression:

| file | before | after |
|---|---|---|
| `MEMORY.md` | 15833 | **11376** |
| `INDEX_ccx.md` | 18473 | **17142** |
| `INDEX_ccx_arch.md` | — | 4417 (new: closed plateau/`rep_dC` arc, superseded refits, `h_ml` band archaeology) |
| `INDEX_fair.md` | — | 6857 (new: FaIR pipeline, pulse metrics, PF/O3, H-S, emissions/obs findings) |

**Two real defects found in the split**, both worth knowing about:
- The **ocean/pump block was filed under an "ARCHIVE — consult for provenance, not live state"
  heading** while the root index pointed at `ccx_hessian_is_the_blocker` and
  `sigma_inflation_prices_the_band` as LIVE. Promoted out into its own section.
- It still read *"the 21-param refit is OWED AND NOT RUN, nothing is quarantined yet"* **after that
  refit had landed and been ratified do-not-adopt**. Corrected.

The three STANDING driver rules (2300 end year, RFF-SP = Sarofim 2024, van Vuuren real to 2500)
**stayed in the root** because they bind every project. Zero dangling links, zero orphans across
389 files. ⚠ **`INDEX_ccx.md` is back to 17.1 KB against an 18.4 KB hard ceiling — it will need
another split within a session or two.**

---

## 2. THE FACE GATE CLEARED — AND THE GATE WAS FRAMED AROUND THE WRONG NUMBER

`calibration/diag_face_check_gamma_diff.R` (seconds). Handoff 08-29c §6 gated adoption on
*"`fert_k` +28.9 % … FACE is the only thing bounding this direction."* **Both halves were wrong:**

1. **+28.9 % is the γ = 0.97 payment**, and γ = 0.97 was already rejected (14× dearer, fits worse).
   At **γ = 0.25 the payment is `fert_k` +6.1 %** (154.84 → 164.23), `beta_max` +2.3 %.
2. **FACE does not cap `fert_k`.** That ceiling was **WITHDRAWN 2026-08-25** on Marcus's ruling
   ([[face_ceiling_is_the_headline_in_disguise]]). What FACE constrains is the **ridge coordinate's
   implied response** `R(400→564)`, against a BRACKET.

**R goes 8.61 % → 8.87 % (+0.26 pt)** — the mature-forest end (EucFACE ~0 %, BIFoR +10 %), far under
the 21.8 % plantation-weighted synthesis and the 32.1 % box maximum. Even γ = 0.97 reaches only
9.76 %. The withdrawn ceiling sits **8.4× above** the operating point.
**Estimator validated** against three recorded cells: design 7.8 %, old adopted mode 13.6 %,
pinned-`luc` probe 17.2 % (memory records 17.3 %).

⚠ **MEASURE THE GATE'S POWER BEFORE READING ITS PASS.** It only fires above 21.8 %: mutation-tested,
it FAILS the young-plantation cell (32.0 %) but **PASSES the pinned-`luc` probe at 17.2 %**. Correct
on Marcus's ruling — over this range FACE *brackets*, it refutes nothing — but **the pass is
informative through the DISTANCE, not the verdict.**

---

## 3. PLAN ITEM ② — MEASURED BEFORE IT WAS FIXED

**`diag_hml_c1_kinkmap.R` (~1 min).** `ccx_hml_kink` recorded **3 kinks, "sparse — 5 of 3499 probe
points"**, which is why the C1 defect was a caveat and not a blocker. **That was measured over the
refit band [85,120], and the 08-28 σ-inflation adoption RETIRED that band** — `h_ml` now has an
interior maximum over its full prior support **[30,200]**, 4.9× wider.

**26 kinks there**, density **0.086 → 0.153 per meter (1.78×)**, closest pair **0.33 m**. They
**cluster on the 25 m GLODAP bin edges** (tight groups at h_ml = 50, 75, 100, 125, 150, 175) because
`h_ml` IS the first layer boundary and the deeper ones scale with it.
⚠ **`CCX_PARAM_TABLE$h_ml$init = 75` sits EXACTLY on a kink**, as `ARM_HML_INIT = 100` already did.
No FITTED mode is contaminated (96.47 is 1.94 m clear, the rejected option-5 refit 35.38 is 11.47 m
clear) ⇒ **the landing-probability reading survives; the TRAVERSE reading does not.**

**`diag_hml_c1_remap_price.R` (~2 min).** The kink is a **box filter with hard edges** — the shape is
piecewise-CONSTANT per bin, so its antiderivative is only piecewise-linear.

| | kinks in [30,200] | reproduces a whole bin's mean | field move at the mode |
|---|---|---|---|
| incumbent (clamped overlap) | **26** | 0 by construction | — |
| MID (Hermite thru bin *midpoints*) | 0 | 2.0e−3 — **not conservative** | 26.7 % of a layer step |
| **CUM** (C1 spline of the *cumulative* integral) | **0** | **3.3e−16** | **15.4 % of a layer step** |

**CUM is the right construction**: the bin averages pin `S` exactly at every bin EDGE, so
interpolating **S** rather than **shape** is C1 *and* conservative.

⚠ **BUT IT IS NOT "A CODE FIX, NOT A SCIENCE CHANGE"**, which is what the plan note claimed. It
moves the pump field **9.6–15.8 % of the median layer step**, and the export is a DIFFERENCE of
adjacent layers, so that is the scale the pump uses. And **a remap's between-edge behavior is a
SUB-BIN MODEL the data do not contain** — CUM exceeds its local 3-bin range in 10 of 29 intervals
(worst 42 % of a bin step at ~450 m, the thermocline), while the incumbent's piecewise-CONSTANT
assumption is equally absent from the data and is exactly what made it kinked. **Neither is "the
observations."**

---

## 4. BOTH ADOPTED (Marcus, 2026-08-29) — AND THE 7 FAILURES ARE ATTRIBUTED

- **`CCX_GAMMA_DIFF_DEFAULT <- 0.25`** (`R/model.R`), used by BOTH `ccx_default_params()` and
  `ccx_cpp_par()` — the `CCX_FERT_FORM_DEFAULT` pattern, so R and C++ cannot disagree about what a
  parameter list without the field MEANS. **NOT behavior-preserving, deliberately.**
- **`ccx_pump_shape()` is the CUM remap.**

**Suite 1227 / 7 fail / 2 skip. ATTRIBUTION RUN: with the remap adopted but `gamma_diff` back at 0,
ALL 7 PASS.** So **the remap breaks nothing**, and every failure is `gamma_diff` invalidating a
contract written against 0:

| test | why | what it needs |
|---|---|---|
| `test-volcanic-diffuse.R` "gamma_diff defaults to 0" | asserts the OLD default | rewrite to the adopted contract |
| `test-conveyor.R` "a quiet run does not drift" ×3 | **a quiet run is no longer quiet — volcanoes now drive NPP.** Handoff 08-29c §8 predicted this exactly | **a DEFINITIONAL call: what is "quiet" post-adoption?** |
| `test-luc-permanence.R` "a pulse is not given back" | same cause | same ruling |
| `test-likelihood.R` "a CO2 level bias is expensive" | fitted offset **3.017 ppm** vs a `< 3` guard — the level moved | re-guard AFTER the refit |
| `test-mode-file.R` "stored logposts do not decide it" | stored logpost changed, as every objective change makes it | refresh provenance |

⚠ **NONE OF THESE WERE EDITED.** They are reported, not resolved. **The 08-28 precedent is that a
contract test gets deliberately INVERTED as part of the adoption commit** (the h_ml gate test) — so
that is probably the shape of the answer, but it is Marcus's to give.

⚠ **The remap breaking zero tests is NOT a clearance.** GATE B measured it moving the pump field
9.6–15.8 % of a layer step; **the suite has no guard on the pump field at all.** That is a statement
about the suite's POWER, not about the change's size.

---

## 5. ⚠ THE BUG THE ADOPTION EXPOSED — an out-of-bounds read, live two days

`ccx_deriv_fast()` builds a **flat** forcing vector the C++ indexes **BY POSITION** against
`CCX_FORCING_COLS`. When `aod_NH`/`aod_SH` were appended on 08-29g, the constant, the C++, and the
MATRIX builder `ccx_cpp_forcing()` were all extended — **this single-step builder was not.** It
stopped at `sink_ocean`, so the core read `f[15]`/`f[16]` **two slots PAST THE END of a 15-element
vector.** Neither language reported anything.

**It was invisible because `gamma_diff` defaulted to 0** — the garbage was multiplied by zero.
Adopting 0.25 turned it into an R↔C++ parity break of **~0.07 GtC/yr** in the NPP-fed pools
(18 of 96 states: atm/leaf/wood, every tracer block).

**The attribution took one step and is the reusable part:** parity was exact (**1.6e−13**) at
`gamma_diff = 0` and broke at 0.25 ⇒ it is the new term, not the co-adopted remap. **A change that
feeds BOTH paths identically cannot cause an R-vs-C++ divergence** — that eliminated the remap
without running anything.

⚠ **SECOND TIME IN THREE DAYS** that appending those two columns bit through position-indexing;
08-29f was `N_FORCING` not being bumped, equally silent. **Two silent failures from one two-column
append is a structural problem, not two mistakes.** The fix is therefore structural:
`ccx_deriv_fast()` now **ERRORS** if its vector is not `length(CCX_FORCING_COLS)`, and
`test-parity.R` pins the length, parity at **EXPLICIT** γ = 0 / 0.25 / 0.97 (so coverage does not
move if the default moves — which is exactly how this survived), a loud-AOD mutation test, and the
absence contract. **Mutation-tested: re-introducing the bug fails 7 assertions; the fix passes 53.**

Memory: [[default_off_hides_the_bug]].

---

## 6. THE NEXT STEP, IN ORDER

1. **RULE ON THE 7 FAILING TESTS** (§4). The conveyor/LUC pair is the substantive one — it asks what
   "a quiet run" means once volcanoes drive NPP. The other three are mechanical once ruled on.
2. **RUN THE OWED 21-PARAM REFIT** on the new objective. ⚠ Before launching: `uptime` and whose job
   is already running (load was 3.23 at the time of writing, 4 users); pin BLAS threads; run from a
   **FROZEN COPY**. Consider the 20-min smoke first — 08-23's smoke found the same mode as the
   10.4-h job.
3. ⚠ **Consider quarantining pre-adoption outputs** before the refit overwrites anything at a
   canonical path. Nothing has been quarantined yet this session.
4. **Then plan item ③ (seasonal `tau_ex`).** ④ four-box remains **HELD** by Marcus.
5. The **seasonal `seas_lag_p[2]`** design call from 08-29c is still open and still sits behind ③.

---

## 7. NON-OBVIOUS STATE

- **Nothing is running.** No partial jobs, no background processes.
- ⚠ **`ccx_hold_climate()` does NOT freeze `aod_*`** (Marcus). **NEVER add an AOD → temperature
  term: `gmst` already carries the cooling.** Consequence, now LIVE rather than hypothetical since
  `gamma_diff = 0.25`: **"climate held" is a volcanically NOISY, ENSO-quiet world.** This is the same
  fact the conveyor test is now tripping over.
- ⚠ **AOD pre-1850 IS ZERO** — Laki 1783, 1808/09 and **Tambora 1815 are ABSENT**; the biggest event
  in the model's window is **Krakatau 1884**. "The year without a summer" needs eVolv2k.
- **`diag_landed_gap_streams.R` is still QUARANTINED** and HARD-STOPS; output in
  `outputs/quarantine/20260829_preadoption_landed_gap/`. No replacement by design.
- **`refit_20260828_sigma_eff` — RATIFIED "do not adopt"** (Marcus). ⚠ The pinned-96 successor is
  **NOT** a config change: `ARM_HML_BOUND` is PROVENANCE-ONLY since `2153bd6`, a BOUND ≠ a PIN, and
  both are undecided.
- **Two DIAGNOSTIC-ONLY authorizations (Marcus)**: a CMIP6 ensemble value for `SEAS_NPP_AMP_SH` may
  be USED but never shipped; a diagnostic arm may leave a bracket for MEASUREMENT, never adoption.
- **Run drivers from a FROZEN COPY** ([[never_edit_a_running_script]]).
- ⚠ The **seasonal arc's structural wall** from 08-29c is unchanged: one scalar `seas_lag_p` serves
  BOTH hemispheres, the phase lever is prohibitive at −838, and the amplitudes are already
  per-hemisphere arrays while the TIMING parameters are not.

---

## 8. HOW TO RUN WHAT THIS SESSION ADDED

    Rscript calibration/diag_face_check_gamma_diff.R     # seconds
    Rscript calibration/diag_hml_c1_kinkmap.R            # ~1 min
    Rscript calibration/diag_hml_c1_remap_price.R        # ~2 min
    Rscript tests/run_tests.R                            # ~8 min; expect 7 FAILURES, see s.4

To reproduce the attribution in §4 (all 7 pass on the remap alone), flip
`CCX_GAMMA_DIFF_DEFAULT` in `R/model.R:405` to 0 and re-run the five affected files —
**then flip it back.**

## 9. COMMITS

    a2298dc  ADOPT gamma_diff = 0.25 and the C1 cumulative remap -- and fix the OOB read
    e2ba55a  Plan item 2 MEASURED: 26 kinks on the live band, and the C1 fix is not free
    a3c0a09  FACE gate CLEARS for gamma_diff = 0.25 -- and the gate was framed around the wrong number
