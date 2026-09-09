# Handoff — 2026-09-09u. **THE 09-09t BLOCKER IS FIXED (one mechanism, one gate) AND THE CONTAMINATED OUTPUTS ARE QUARANTINED. ⛔ THE NEXT SESSION RE-RUNS P10/P11/P12/P1c ON A CLEAN SPINUP — until it does, those four have NO canonical values, and the refit is still stopped.**

Read first: **`notes/review_2026-09-09t_whole_model_code_review.md`** (the whole review; §1 is the
blocker, §8 is the list of leads I did NOT verify), then **CHANGELOG 09-09t → 09-09u**.
Memory: [[two_gates_one_mechanism]] (the transferable lesson), [[ccx_seasonal_h_ml_option]] (the arc,
now carrying the four review findings), `INDEX_ccx_seas.md`, [[ccx_pedagogical_not_emulator]].

---

## 0. ⛔ THE INSTRUCTION, IN ORDER
1. **RE-RUN the five quarantined diagnostics** (§3). They are the only way to learn what round 6
   actually does, and **every number in the 09-09 record for them is void**.
2. **THEN re-read P12 and P10 from scratch** (§4) — their headline conclusions were the bug's own
   signature, so they must be re-derived, not re-confirmed.
3. **THEN the refit**, with the target restated per review §2 (§5). ⛔ Still NOT before.
4. `hilda31` remains canonical; `seas_ml` remains DEFAULT 0. **Nothing was adopted.**

---

## 1. STATE OF THE TREE
- **`main`**, tree clean, **not pushed** (this repo has no remote). Commits this session:
  `23e6481` (the review) and the fix commit at the tip.
- **Suite: re-run at `a73edb3` before any change = PASS 2381 / FAIL 3 / SKIP 4**, the three being the
  pre-existing set (`test-alpha-as.R:116,117`, `test-seas-lag-split.R:199`). **The full suite has NOT
  been re-run since the fix** — `test-parity.R` alone passes **78/0**. ⛔ **Run the full suite first.**
- `hilda31` canonical, **no stored logpost moved**, `seas_ml` default 0.

## 2. WHAT THE FIX IS
**The predicate is resolved ONCE, in R, by the function the R core itself calls**, and shipped:
`ccx_cpp_par()` sets `p$seas_ml_on <- as.integer(ccx_seas_ml_on(p))`; both C++ gate sites
(`src/ccx_core.cpp:442` geometry/entrainment, `:849` the conveyor's up-hemisphere ML) read
`A.seas_ml != 0 && P.seas_ml_on != 0`. **`A.seas_ml` survives only as a data-presence conjunct.**
- ⚠ **`seas_ml_on` also had to be named in `ccx_cpp_par()`'s CURATED RETURN LIST** (`p[c(...)]` at the
  end of the function). Injecting the field without naming it there reaches the core as an
  **out-of-bounds read, not a value** — a curated marshalling list is a SECOND place absence is
  decided, and both had to be edited. **Remember this for the next parameter.**
- ⭐ **The mirror case is refused loudly**: `ccx_seas_ml_marshal_check(p, aux)` (`R/cpp.R:119`, called
  from `ccx_run_fast` and `ccx_deriv_fast`) stops when `p` says ON and `aux` has no `mld_coef`, which
  would otherwise run **f = 0 — a mixed layer of zero thickness**. `ccx_prepare()` is the ONLY builder
  of `mld_coef` (`R/model.R:2867`) and both R consumers sit behind the same predicate, so this closes
  the only desync route.
- ✅ **VERIFIED IN THE QUANTITY THAT WAS WRONG**: the spinup equilibrium is now **bit-identical**
  across `seas_ml` (`max|Δ|` over all 36×3 state = **0**) at **37 894.163 GtC** — the correct
  aseasonal value, not a compromise. Pre-fix: 35 953.939, a **−1 940.224 GtC** displacement.

## 3. ⛔ WHAT MUST BE RE-RUN, AND AGAINST WHAT
Quarantine: **`outputs/quarantine/20260909t_seas_ml_spinup_leak/`** (9 files + a README naming the
bug, the files and the canonical replacement path). Re-run each to its **same basename** in
`outputs/diagnostics/`, then **diff against the quarantined copy** — that diff is the only measure of
the bug's size, per stream, and the refit's target depends on it.

| script | what it re-establishes |
|---|---|
| `calibration/diag_p12_compensator_redundant.R` | P12 — does `ent_seas_amp_SH` collapse with the mechanism on? |
| `calibration/diag_p12_streams.R` | P12's per-stream split (**reads p12's rds — run it second**) |
| `calibration/diag_p1c_dpco2_comparison.R` | P1c — SH ΔpCO₂ amplitude and phase vs SOM-FFN |
| `calibration/diag_seas_ml_probe.R` | P1 — the unrefitted ML DIC anomaly, and P1a/P1b |
| `calibration/diag_seas_ml_convergence.R` | P9 substep convergence, P10 rectification |

✅ **NOT quarantined and NOT to be re-run: `seasonal_ml_geometry_20260909.*`** — pure geometry, no
`ccx_spinup`/`ccx_run` call, so the P8 bound and layer-1 arithmetic in it stand.
⚠ **"It ran in the R core" is NOT an exemption** — every one of these takes its initial state from
`ccx_spinup()`, which uses the C++ path whichever core then integrates.

## 4. ⛔ THE TWO CONCLUSIONS THAT MUST BE RE-DERIVED, NOT RE-CONFIRMED
⭐⭐ **P12's "+518 on `co2_seasonal_SPO`, −514 on the two CO₂ LEVEL rows" and P10's "the mechanism
CHANGES ANTHROPOGENIC UPTAKE — a RESULT, not a defect" are BOTH the exact signature of a ~1940 GtC
ocean-carbon deficit at t₀.** Two diagnostics agreed and their agreement read as corroboration when
it was a **shared cause** ⇒ [[explained_away_test]]. Approach the re-run with the null hypothesis
that the level penalty was the bug, and let the numbers say otherwise.
⚠ **09-09j/k's "no periodic spinup is needed" was argued BY CONSTRUCTION from the very
`seas_drivers` zeroing that C++ ignored.** The argument does not survive its own premise being false.
**Re-test it** — this is review §8's lead F2, which claims a real +19.6 ppm shock at 1750 remains
after the gate fix because the mechanism changes the state→concentration map (`ml_mass · f(t)`), not
just a rate. ⛔ **If F2 holds, round 6 owes a periodic (limit-cycle) spinup and its cost changes.**

## 5. THE REFIT'S TARGET, RESTATED (review §2)
⛔ **The 09-09s target is RETRACTED.** It said *cut the SH ΔpCO₂ ~2.6× by RELAXING the fitted
solubility amplitude, `sst_seas_amp_SH`, whose prior-z was −5.14*. **Measured at `hilda31`: +0.36**
(NH −2.96, which reproduces the handoff's own NH figure and so validates the estimator). **−5.14 is
pre-09-03, and `CHANGELOG.md:2528` already carries "P2 −5.14 → +0.24 ✅ the 5σ strain is GONE".**
⇒ **There is no SH solubility strain to relax, and relaxing toward the prior would INCREASE the
swing.** Restated:
- **The amplitude cut must come from RETIRING the shim** (`ent_seas_amp_SH` 21.04 against a derived
  centre of 10.95 — and see §6, that centre is itself ~2× too large, making the strain worse).
- ⭐ **The acceptance test should be NH-centred**: the live strain is `sst_seas_amp_NH` at −2.96
  (1.067 K against an observed 2.237 K), the hemisphere the SH-only shim never served and the new
  bi-hemispheric mechanism does.
- ⚠ Keep the nuance: `R/constants.R:340-344` declares that prior's WIDTH a judgement covering an
  area-weighted-vs-gas-exchange-weighted estimator gap. **The strain is real; its exact size is not.**
- ⛔ **P8 is an ENFORCED gate and the refit will hit it**: the stop is **76.146 m** (bisected), and
  **61.3 % of `h_ml`'s own prior lies past it — its MEDIAN, 83.94 m, is past it.** The prior's own
  comment (`R/calibrate.R:148-155`) says it encodes a mean-vs-max ambiguity **round 6 discharges**;
  re-centre on the LS annual mean **59.7 m** at adoption (→ 23.8 % exposure, 5–11 % at a narrower
  width). **Do this BEFORE launching a 24-start array or ~3 starts in 5 die at the guard.**

## 6. OWED, FROM THE REVIEW, NOT YET DONE
- ⭐ **`.ENT_SO_SST_AMP = 3.0` is PEAK-TO-PEAK while labelled "half-amplitude"** (40–90 S measured
  1.4995 half / 2.9990 p2p; the SH hemispheric half 1.7464 reproduces the registered
  `SST_SEAS_AMP_SH_OBS` to 5 s.f., which is the like-for-like validation). The consumer needs a half.
  ⛔ **Fix BOTH legs in one edit** — review §8 reports the pCO₂ leg is p2p AND per-cell so the biases
  do not cancel (centre ~2.1–2.3× high). **I did not verify the pCO₂ leg.**
- ⚠ **The comment at `R/constants.R:41-42`** — *"the band ... swings harder than the hemisphere"* — is
  **falsified** like-for-like and should go with the fix.
- **`test-seas-lag-split.R:199`** hand-rolls a contract `ccx_seed_unencodable()` implements; it will
  re-break on the next parameter addition. Pre-existing, not this session's.
- **The app teaches a model the code is not** (`app/ui.R:265`: "a mixed layer over ten diffusive
  layers", beside a diagram already updated to the seven-box HILDA form).
- **§8's unverified leads**, worst first: F2 (above), F3 (guard uses the month-centre max; a ~0.64 m
  window where winter `dz_1` goes negative silently), F4 (substeps), the canonical mode file's stored
  stream set being 4.75 log-units short with a printing-only adoption gate, `ccx_loglik()` returning a
  finite 0 when every stream vanishes, GATE Q having no `test-gate-bounds` coverage.
- ⭐ **`.ENT_DIC_SURF = 2150` is reportedly RIGHT** as a band value — **acting on its own "5.6 % too
  high" flag would inject a ~5 % error into a correct constant.** Fix the citation, not the number.

## 7. NON-OBVIOUS STATE
- **`seas_ml` is still NOT in `CCX_PARAM_TABLE`** — a plain switch in `ccx_default_params()`. Must not
  be freed. `seas_ml_on` is a MARSHALLING field, not a parameter: it is derived in `ccx_cpp_par()`
  every call and must never be set by hand or stored in a mode file.
- **The three pre-existing test failures are unchanged and were not fixed** (only diagnosed).
- **`INDEX_ccx_seas.md` is ~17.3 KB of an 18 KB hard ceiling** and now carries its own "split owed"
  flag ⇒ [[memory_index_split_beats_trim]].
- ⚠ **The 09-09s handoff's own status header is stale** (it still says the round is stopped at P1 and
  the C++ twin is unbuilt). A status header should point at the live document and not restate live
  state ⇒ [[status_field_carries_the_query]].
- **The three new parity tests are MUTATION-TESTED, and each fails for its OWN reason**: mutation A
  (restore the pre-fix gate, dropping the `seas_drivers` conjunct) → FAIL 2 / PASS 76 at
  `test-parity.R:483` and `:493`; mutation B (remove the `ccx_seas_ml_marshal_check()` call) →
  FAIL 1 / PASS 77 at `:506`. **Re-run both if you touch the gate.**
- **Mutation A is SLOW** (~5–8 min vs ~2.5 clean): the pre-fix gate contaminates every `seas_ml = 1`
  spinup, so the tests themselves run slower under it. Not a hang.
- ⛔ **Two process traps hit while doing this work, both already in `~/.claude/CLAUDE.md`**: a
  `pgrep -f` waiter whose pattern appeared in its OWN command line never exits (use a bracket glob,
  `[t]estthat`), and **the test file and `R/` must not be edited while a suite run is sourcing them**.

## 8. ⛔ WHAT I WOULD NOT DO NEXT
- **Do not refit before the five re-runs.** The refit's target is derived from P1c and P12, and both
  are currently void.
- **Do not treat the quarantined numbers as a baseline to reproduce.** They are a baseline to
  **diff against**; reproducing them would mean the fix did nothing.
- **Do not delete the quarantine.** It is the regression test and the only measure of the bug's size.
- **Do not act on review §8 without verifying it** — those are leads from a review pass, explicitly
  marked `[R]`, and one of them (`.ENT_DIC_SURF`) says an existing in-code warning is itself wrong.
