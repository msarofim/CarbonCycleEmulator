# Handoff — 2026-09-09v. **THE FIVE RE-RUNS ARE DONE. FOUR WERE NEVER CONTAMINATED; ONLY P1c WAS, AND THE LEAK WAS HIDING ITS PROBLEM. ⛔ F2 IS CONFIRMED — THE ASEASONAL SPINUP IS NOT A POINT ON THE SEASONAL ORBIT, SO A PERIODIC SPINUP IS OWED. THE REFIT IS NO LONGER BLOCKED ON THE RE-RUNS; IT IS BLOCKED ON FOUR RULINGS THAT ARE MARCUS'S.**

> ⚠ This header states what is DONE. For live state read `CHANGELOG.md` 09-09v and
> `INDEX_ccx_seas.md` — not this line ⇒ [[status_field_carries_the_query]].

Read first: **CHANGELOG 09-09v** (every number, with its derivation), then
`outputs/quarantine/20260909t_seas_ml_spinup_leak/README.md` (rewritten — its 09-09t attribution
was wrong). The review is still `notes/review_2026-09-09t_whole_model_code_review.md`; **§1 is
right about the bug and wrong about its blast radius, §4's second leg is refuted — see §5 below.**
Memory: [[quarantine_blast_radius_is_a_timeline]], [[ccx_f2_periodic_spinup_owed]],
[[ccx_ent_so_sst_amp_is_p2p]], [[two_gates_one_mechanism]], `INDEX_ccx_seas.md`.

---

## 0. WHAT THE NEXT SESSION SHOULD DO
1. ⛔ **Nothing that moves a prior, a constant or a canonical artifact — four rulings are owed
   (§6) and every one is Marcus's.** Ask before touching them.
2. If a ruling comes back: **build the periodic spinup first** (§4). It is the only owed item whose
   answer changes round 6's *cost*, and it is unresolved in BOTH directions.
3. Still open from the review and NOT verified: the mode file's stream set (§7).

## 1. STATE OF THE TREE
- **`main`**, tree **clean**, not pushed (no remote). This session's commit: **`f3ff278`**
  (15 files, +610/−48). Prior tips `c64cbe1` (the fix), `23e6481` (the review).
- **Suite re-run at the fix, in full: PASS 2387 / FAIL 3 / SKIP 4.** The three are exactly the
  pre-existing set (`test-alpha-as.R:116,117`, `test-seas-lag-split.R:199`). +6 over 09-09t's 2381
  are the fix's own new parity tests. **No regression.** ✅ 09-09u's §1 instruction is discharged.
- `hilda31` canonical, `seas_ml` DEFAULT 0, **no stored logpost moved, nothing adopted.**

## 2. ✅ THE FIX IS VERIFIED IN THE QUANTITY THAT WAS WRONG
`calibration/diag_seas_ml_spinup_leak_probe.R`, run in **two frozen trees** differing only by the
documented one-line mutation in `ccx_cpp_par()`:

| arm | pre-fix ocean C | post-fix |
|---|---|---|
| `ent 0, seas_ml 0` | 37 894.163 | 37 894.163 |
| `ent 21.2, seas_ml 1` | **35 953.939** (−1 940.224) | **37 894.163** (Δ = 0) |

Post-fix `max|dy|` over all 36×3 state is **exactly 0** on every arm. The review's −1940.224 is
reproduced to the digit.

## 3. ⛔ THE QUARANTINE OVER-COLLECTED — and the reasoning that produced it matters
**The C++ core had no seasonal mixed layer until `4189ff9`, 16:33.** Three lines, the third a
measurement:
1. `git show 62966de:src/ccx_core.cpp | grep -c seas_ml` → **0**.
2. At that commit `ccx_cpp_par()` **hard-stopped** on `ccx_seas_ml_on(p)`; `ccx_spinup()`'s zeroing
   meant the equilibrium solve never tripped it. **The R gate was the only gate and it was right.**
3. The re-runs, diffed against the quarantine.

| output | ran | diff |
|---|---|---|
| `seas_ml_convergence` (P9, P10) | 13:01 | ✅ **BIT-IDENTICAL** |
| `seas_ml_probe` (P1, P1a, P1b) | 14:34 | ✅ **BIT-IDENTICAL** |
| `p12_compensator` (P12) | 15:18 | ✅ **BIT-IDENTICAL** |
| `p12_streams` | 15:20 | ✅ **BIT-IDENTICAL** |
| `p1c_dpco2` (P1c) | 16:43 | ⛔ **DIFFERS** |

⭐ **The tell was an assertion that PASSED and had been read past.** P12's own log prints
`stopifnot(all.equal(sp0$y, sp1$y, tolerance = 0))` → `0.000e+00`, impossible under the leak; under
the pre-fix mutation that same line evaluates **FALSE** and halts the script.
⭐ **The 09-09t reading was [[explained_away_test]] run BACKWARDS** — a real result explained away by
a bug that had not yet been written ⇒ [[quarantine_blast_radius_is_a_timeline]].
⚠ Over-collecting was the SAFE error and the re-run was owed either way. ⚠ Also separated: a
**genuine** `ccx_substeps_for` fix rode in the same commit, so a moved number would have had two
candidate causes — it turns out to be inert at the canonical (substeps 4/4 either way).

### P1c — the only real one, and the leak was HIDING the problem
| | pre-fix | post-fix |
|---|---|---|
| SH ΔpCO₂ amp, `seas_ml = 1` | 40.76 µatm | **54.04** |
| vs A1 (0–90 S, the ruling) | 9.11× | **12.09×** |
| vs A2 (40–90 S, reference) | 2.64× | **3.50×** |
| peak month | 6.83 | 6.79 |

⛔ **The refit's amplitude cut is HARDER than 09-09s thought.** Phase barely moves, so the
box-structure finding (one SH surface box cannot carry two antiphase regimes) is untouched.

## 4. ⛔ F2 CONFIRMED — 09-09j/k IS REVERSED
New diagnostic `calibration/diag_f2_periodic_spinup.R`: a QUIET run (zero fossil, zero LUC flux
**and stock**, held climate, zero AOD — `test-conveyor.R`'s own construction) from the aseasonal
spinup, `ent_seas_amp_SH = 0` on both arms.

| year | seas_ml 0 | seas_ml 1 |
|---|---|---|
| 1750 | −0.030 | **+19.939 ppm** |
| 1770 | −0.030 | +2.509 |
| 2249 | −0.010 | +2.440 |

Excursion from year 1: **+0.021** (noise floor) vs **−17.586** — ratio **855×**. Independent
reproduction of the review's reported "+19.6 ppm", by a different construction.

⭐ **TWO components:** a SPIN-IN transient (~17.5 ppm, e-folding a few years, gone by 1770) and a
RECTIFIED LEVEL OFFSET (+2.4–2.5 ppm, flat within 0.07 ppm for 480 years).

⭐⭐ **AND THAT OFFSET IS WHAT P12's −514 IS.** The transient cannot be: `co2_level_MLO`/`SPO` score
**1959–2025 / 1962–2023**, ~190 yr later; the transient's own stream `co2_icecore` (1703–1996) paid
only **−2.84**. Size check — at `LIK_CO2_REP_ERR = 1.0` ppm over n = 126 annual points, **−514.38
implies a uniform +2.857 ppm**; F2's preindustrial residual is **+2.45**, the remainder being P10's
industrial-era uptake change. ⇒ **P10 and P12 are ONE finding and it is physics.** P10 measured the
TREND (settled), F2 the LEVEL — the distinction P10's own code comment insists on. P12's conclusion
*"a LEVEL offset is the most REFITTABLE kind of error"* stands, now with a mechanism and a size.

⚠⚠ **UNRESOLVED, AND THE HANDOFF WILL NOT GUESS: does a periodic (limit-cycle) spinup remove that
+2.45 ppm, and with it most of the −514?** It removes the transient, which costs almost nothing.
For the offset there is a real argument **both** ways — the spinup **PINS** atmospheric CO₂ to
`CO2_PI_PPM`, so a limit-cycle solve may absorb the offset into the *ocean* state instead of leaving
it in the air. ⛔ **Building one is the test. Do not price round 6 on either answer.**

## 5. REVIEW §4 — SST leg CONFIRMED, pCO₂ leg REFUTED, centre re-derived
Reproduced independently from ERSSTv5 1975–2024 with the repo's own `sc_harm` + cos-lat weighting.
**VALIDATION:** the SH hemispheric half-amp returns **1.7464 K**, reproducing the registered
`SST_SEAS_AMP_SH_OBS = 1.74644` to 5 s.f. ⇒ the band row is like-for-like.

| region | half-amp | p2p |
|---|---|---|
| SH hemisphere | 1.7464 | 3.4928 |
| **BAND 40–90 S** | **1.4995** | **2.9990** ⇒ the shipped `.ENT_SO_SST_AMP = 3.0` |
| NH hemisphere | 2.2374 | 4.4748 |

✅ **`.ENT_SO_SST_AMP = 3.0` IS the peak-to-peak**, labelled "half-amplitude" — a true factor of 2.
✅ `R/constants.R:41-42`'s *"the band … swings harder than the hemisphere"* is **FALSIFIED**
like-for-like (1.4995 < 1.7464); it only reads true comparing a p2p against a half-amp.
⛔ **BUT THE REVIEW'S SECOND LEG IS WRONG.** It reported `.ENT_SO_PCO2_AMP = 19.45` as *also* p2p,
hence "≈2.1–2.3× too large". The repo's own **uncontaminated, obs-only**
`outputs/diagnostics/so_pco2_amplitude_20260909.log` refutes it: 19.45 sits at the per-cell
**harmonic** 19.68; a p2p would be ≈39. Its defect is the per-cell-vs-area-mean split
(19.45 → 16.26), worth **4.8 %**, not 2×.

**Re-derived by COMPUTATION** ([[derived_must_mean_computed]]):

| case | in-band | centre | fitted 21.04 ÷ centre |
|---|---|---|---|
| shipped | 29.6812 | 10.9524 | 1.92 |
| SST leg only | 19.1840 | 7.0789 | 2.97 |
| **both legs fixed (1.4995 half, 16.26 area-mean)** | **17.7581** | **6.5528** | **3.21** |
| review's assumption (both p2p) | 14.8371 | 5.4749 | 3.84 |

⇒ the shim sits at **3.21×** its corrected centre. **The review's DIRECTION survives — retiring the
shim is better supported than the shipped 1.92× implied — but its MAGNITUDE was overstated.**

## 6. ⛔ THE FOUR RULINGS OWED — all Marcus's, none taken
1. **Build the periodic spinup?** (§4) Owed for correctness regardless — a 20 ppm preindustrial
   shock in a **pedagogical** model ⇒ [[ccx_pedagogical_not_emulator]]. Its refit value is unknown
   until built.
2. **The pCO₂ leg's estimator** — area-mean **16.26** (box-consistent, and what the SST leg uses)
   vs per-cell **19.68**. The 09-09 log flags this as an owed ruling. Centre 6.5528 vs 7.0789.
3. **`h_ml`'s prior re-centring** (review §3) — P8's stop is 76.146 m and **61.3 % of the prior lies
   past it, its MEDIAN 83.94 included**; re-centring on the LS annual mean 59.7 m drops exposure to
   23.8 %. Without it ~3 starts in 5 die at the guard. **Moves a prior.**
4. **Retire `ent_seas_amp_SH` (31 → 30)?** P12 reproduced unchanged and still supports it, now at
   3.21× rather than 1.92×.

## 7. OWED FROM THE REVIEW, STILL NOT DONE
- ⚠ **The mode file's stream set — NOT VERIFIED.** Measured: it stores **23** rows summing to
  **−1434.670** against a stored logpost **−1478.660**; that **43.99** gap is the **log-prior**, as
  expected, and is NOT the review's claimed "4.75 log-units short". It does carry `d14c_deep_ocean`
  with no `d14c_mid_*` profile rows, which matches the review's description of a stale producer.
  **Settling it needs a loglik at the mode, which was not run.** Review §10 item 6.
- The other §8 leads (F3 the guard's month-centre max, F4 substeps, GATE Q's missing
  `test-gate-bounds` coverage, `ccx_loglik()`'s finite 0) — untouched, still `[R]`.
- §6/§7 pedagogy: the app prose (`app/ui.R:265` still says "a mixed layer over ten diffusive
  layers"), the `ml` box's identity, `q10`, `h_hs`.
- ⭐ `.ENT_DIC_SURF = 2150` is reportedly **RIGHT**; acting on its own "5.6 % too high" flag would
  inject a ~5 % error. **Fix the citation, not the number.**

## 8. NON-OBVIOUS STATE
- **Two frozen trees remain in the session scratchpad** (`prefix_tree` with the one-line pre-fix
  mutation, `postfix_tree` clean). They are the reproduction harness for §2 and are disposable.
- **`so_pco2_amplitude_20260909` ran at 16:36 — INSIDE the contaminated window — and is correctly
  NOT quarantined**: verified observation-only, no `ccx_spinup`/`ccx_run` call. Its 19.45-vs-16.26
  finding is load-bearing for §5.
- **`INDEX_ccx_seas.md` is 18 128 B of an 18 KB hard ceiling.** The superseded 09-09r P1c paragraph
  was MOVED to `INDEX_ccx_seas_mech.md` as provenance to get back under; **the full split it has
  been flagging is still owed** ⇒ [[memory_index_split_beats_trim]].
- **Retractions were propagated in the same pass** ([[retraction_in_place_does_not_propagate]]):
  the "no periodic spinup is needed" claim and the "P10/P11/P12/P1c all rest on it" claim were
  corrected at every site — `INDEX_ccx_seas.md`, `ccx_seasonal_h_ml_option.md`,
  `two_gates_one_mechanism.md` — and an orphan sweep on `40.76` confirms all four surviving
  mentions are marked superseded.
- ⛔ **PROCESS TRAP HIT AGAIN, a NEW mode.** Two background waiters (`until grep -q "ALL DONE"
  <log>`) spun **63 minutes** on an orphaned sentinel: the run they watched was killed and
  relaunched writing to a *different* log, so their condition became permanently unreachable. It
  presents as "still running". **PID-based waiters in the same session worked correctly.** ⇒ prefer
  `wait $pid` / `kill -0 $pid`, and **kill a job's waiters in the same breath as the job**
  ⇒ [[pgrep_wait_loop_matches_itself]] (second failure mode, added today).

## 9. ⛔ WHAT I WOULD NOT DO NEXT
- **Do not re-quarantine or re-run the four bit-identical outputs.** They are canonical in
  `outputs/diagnostics/` and their quarantine copies are byte-identical provenance.
- **Do not treat the +2.45 ppm offset as a bug.** It is measured physics; the open question is only
  whether a periodic spinup relocates it.
- **Do not act on review §4 by halving both legs.** The pCO₂ leg is not p2p; §5 has the numbers.
- **Do not refit before ruling on §6.** The target depends on 2 and 4, and 3 kills 3 starts in 5.
