# PREREG 2026-08-29 — **THE CONTROLLED `q10` TEST**
# Is the channel-recovery fraction (83.6 % vs 42.9 %) a property of the CHANNEL,
# or of `q10` being free? Written and committed BEFORE the driver exists.
# **No gate below may move.**

**State when written:** repo `main` at `d3ce7da`; four uncommitted files, all of them the finished
`refit_20260828_sigma_eff` outputs (not adopted, `ccx_mode_file()` still resolves `from90`).
Nothing running. Suite 1206 / 0 as of 08-29.

---

## 0. THE CONFOUND, STATED EXACTLY

`handoff_2026-08-29` §4 and `INDEX_ccx_seas.md` both name this as step 1 and both say it is cheap
and NOT RUN. The contrast at issue:

| | land lever | `q10` | land cost | INTERACTION | **recovered** |
|---|---|---|---|---|---|
| **27j** | `seas_npp_amp_SH` 0.5027 → 0.352 (a CONSTANT, no d.o.f.) | **FREE** | 80.443 | +67.280 | **83.6 %** |
| **27q mid** | `seas_T_amp_SH` PINNED 5.0502 (a CALIBRATED param) | **PINNED** | 80.420 | +34.470 | **42.9 %** |
| **27q hi** | `seas_T_amp_SH` PINNED 7.1012 | **PINNED** | 162.142 | +70.887 | **43.7 %** |

recovered ≡ INTERACTION ÷ land cost, land cost ≡ logpost(INCUMBENT) − logpost(LAND).
Both designs are internally parameter-balanced (npar difference exactly 0).

**TWO things differ at once**: the slice (`q10` free/pinned) and the lever (which parameter opens
the vacancy). The fraction cannot be attributed to either until one is held.

⚠ **A THIRD FACT MAKES THIS SHARPER THAN THE HANDOFF SAYS.** Three of 27j's four arms reproduce
27q's to within 0.05 log units — INCUMBENT −1546.195 vs −1546.195, OCEAN_only −1533.627 vs
−1533.660, LAND −1626.638 vs −1626.615 (mid). **The whole 83.6-vs-42.9 gap lives in ONE arm:**
JOINT, −1546.790 vs −1579.610. Whatever explains the contrast has to act there and nowhere else.

**The ridge signature confirms the leak is live in 27j and suppressed in 27q.** The identified
product `seas_T_amp_NH · ln(q10)` (`model.R:194-195`):

    27j (q10 free):   INC 2.9868 -> LAND 2.9989 (+0.4 %)   OCEAN 3.0222   JOINT 3.0339
    27q (q10 pinned): INC 2.9868 -> LAND 3.1249 (+4.6 %) / 3.1944 (+7.0 %, hi)

## 1. THE DESIGN — ONE AXIS MOVES

**27q's driver, byte-for-byte, with `q10` added to the base slice in EVERY arm.** Same six arms,
same two bracket ends, same `ent` bounds (0.5, 60) and init 10, same `fit_arm`, same `AQ_CASES`
knockouts, same PEAK-TO-PEAK `amp()`, same `ccx_adopt_mode_band(md)` decode.

| arm | `seas_T_amp_SH` | `ent_seas_amp_SH` | `q10` | npar |
|---|---|---|---|---|
| **INCUMBENT** | FREE | 0 | **FREE** | 6 |
| **LAND_mid / _hi** | PINNED 5.0502 / 7.1012 | 0 | **FREE** | 5 |
| **OCEAN_only** | FREE | FREE | **FREE** | 7 |
| **JOINT_mid / _hi** | PINNED | FREE | **FREE** | 6 |

    INTERACTION = JOINT - LAND - OCEAN + INCUMBENT,    npar 6 - 5 - 7 + 6 = 0   (still balanced)

⚠ **FOUR OF THE SIX ARMS HAVE ALREADY BEEN MEASURED BY OTHER DRIVERS** and are therefore
REPRODUCTION GATES, not results: INCUMBENT and OCEAN_only are 27j's own two shared arms
(−1546.195, −1533.627); LAND_mid and LAND_hi are **27p's free-slice conditional points**
(`seas_T_amp_sh_power.rds$cond`: −1575.950 at 5.0502, −1589.795 at 7.1012). **Only JOINT_mid and
JOINT_hi are new.** They are re-run anyway — spliced numbers from three drivers are not a
controlled comparison ([[explained_away_test]]).

**⚠ THE DENOMINATOR COLLAPSES, AND THAT IS THE WHOLE DIFFICULTY.** 27p already measured what a free
`q10` does to this lever: the land cost falls **162.14 → 43.60** at hi and **80.42 → 29.76** at mid,
and the SH-land defect is barely imposed at all (`sl` 0.859 → **1.216** at hi, against an incumbent
1.308). **With `q10` free the LAND arm mostly does not impose the defect — it leaks it.** So a
"recovered fraction" computed here is a fraction OF A MUCH SMALLER BASE, and the arithmetic is
capable of returning >100 % without anything physical improving. That is the reason for §3.

## 2. THE PRE-REGISTERED GATES

- **C0 — METHOD CONTROL.** At `u0`: SPO total 1.1402, SH_land 1.3080, NH_origin 0.821, ratio 1.930
  (each within 0.5 %), harness offset within 0.5 of −1.5805. **FAIL ⇒ nothing below is read.**
- **C1 — REPRODUCTION.** |INCUMBENT + 1546.195| ≤ 0.10, |OCEAN_only + 1533.627| ≤ 0.10,
  |LAND_mid + 1575.950| ≤ 0.30, |LAND_hi + 1589.795| ≤ 0.30. A miss is an OPTIMISER verdict, not a
  physical one, and voids the arm.
- **C2 — NESTING.** Every free-`q10` arm ≥ its 27q pinned counterpart − 0.02 (`RESTOL`); the pinned
  point is feasible in the free arm's space. Any violation ⇒ optimiser failure.
- **C3 — POWER, BEFORE ANY NULL IS BELIEVED** ([[no_power_null]]). `q10` must actually move and the
  ridge must actually be ridden: in **both** LAND arms, |ln q10_fit / ln q10_pin − 1| ≥ 0.03 **and**
  the product `seas_T_amp_NH · ln(q10)` within 2 % of the INCUMBENT's. If `q10` does not move, C4
  is a no-power null and is not read as evidence for anything.
- **C4 — THE STATISTIC.** recovered_free at mid and hi, against pinned 42.9 % / 43.7 %:
  - **≥ 65 % at either end ⇒ `q10` EXPLAINS the contrast.** The recovery fraction is a slice
    artefact and 42.9 % is the number that survives; 27j's 83.6 % is not a channel property.
  - **within [33, 54] % at BOTH ends ⇒ `q10` does NOT explain it.** The fraction is stable under the
    slice, so the 83.6-vs-42.9 gap belongs to the **LEVER** — the SHAPE of the vacancy, prereg 27q
    §4's alternative — and the arc's target moves to what distinguishes a productivity vacancy from
    a temperature-amplitude one.
  - anything else ⇒ INTERMEDIATE; both ends quoted, neither alone.
- **C5 — DIRECTION.** land cost falls ≥ 5 % at both ends (the leak operating). Predicted from 27p:
  ≈ 29.8 (mid) and ≈ 43.6 (hi).
- **C6 — PHYSICAL.** SH_land in LAND_hi ≥ 1.15 (27p says 1.216, vs 0.859 pinned) — i.e. confirm on
  this harness that a free `q10` means **the defect is not imposed**, not merely not penalised.

## 3. ⚠ THE SECONDARY STATISTIC, AND WHY IT IS THE HONEST ONE

`~/.claude/CLAUDE.md`: **"A ratio is not a magnitude until you multiply its BASE."** A recovery
fraction whose denominator moved 3.7× is exactly that failure mode. So the run also reports

    per-ppm interaction  =  INTERACTION  /  (SH_land[INCUMBENT] - SH_land[LAND])      [log units / ppm]

which normalises by the vacancy actually opened rather than by its price. On the existing runs:

    27j    67.280 / 0.3828 = 176 /ppm
    27q    34.470 / 0.305  = 113 /ppm   (mid)      70.887 / 0.449 = 158 /ppm  (hi)

**PREDICTION (mine, on the record): C4 lands in the "does NOT explain" branch and the per-ppm
statistic is the more stable of the two.** Reasons: (a) 27q measured the fraction stable at
42.9/43.7 % across a 2× range of the same lever, and this run extends that same range 3.7× further;
(b) the whole 27j-vs-27q gap sits in the JOINT arm, whereas `q10`'s measured effect is on the LAND
arm, where it made no difference at all between the two designs (80.443 vs 80.420). Registered
quantitative form: **per-ppm interaction inside 110-200 at both ends.**

I record the opposite outcome explicitly so it cannot be reinterpreted afterwards: if C4 fires
"explains", then the leak is transferring through the channel and not only through the lever, and
[[ccx_seas_2x2_admissible]]'s 42 % is the only fraction that was ever controlled.

## 4. WHAT NO OUTCOME OF THIS RUN LICENSES

- **It cannot rehabilitate `seas_T_amp_SH`.** The full-frozen cost at bracket HI is −204.45 and that
  veto is untouched by anything here.
- **It cannot adopt `ent_seas_amp_SH`**, which has no prior; a gate is not a provenance decision.
- **It does not re-open the `h_ml` question.** `ccx_mode_file()` stays on `from90`; this run reads
  the same mode every other diagnostic reads.
- **It is not a test of the NH-import channel** (step 2), which remains the biggest unexplained term
  at 0.821 of 1.373 and is untouched by this design.

---

## AMENDMENT 1 (2026-08-29, written after P0 and BEFORE any arm result)

**⚠ C1 AND C2 AS WRITTEN ARE MIS-SPECIFIED, AND I WROTE THEM THAT WAY.** They compare ABSOLUTE
logposts here against values STORED by 27j / 27p / 27q — and **the objective changed in between**.
`2153bd6` (08-28, "ADOPT OPTION 5") rescores the ocean-gradient rows at `sigma_eff`; every one of
27j/27p/27q ran on 08-27, i.e. on the RETIRED objective. This is exactly the defect
`handoff_2026-08-29` §5 flags in `test-mode-file.R`: *across the objective change that is
MEANINGLESS, not merely false.* I reproduced it while writing a driver whose header cites it.

**MEASURED, not inferred:** this run's harness gives **−1546.2766** at `u0` where 27q recorded
**−1546.195** — a **0.0816** shift, and the offset prints −1.6618 against the known −1.5805.

**THE PREMISE IS REWRITTEN, NOT RELAXED TO GREEN.** C1 and C2 are restated in **GAP form**, which
is invariant to any part of the objective change that is common to the arms:

    gap(arm) = logpost(arm) - logpost(INCUMBENT of THIS run)

- **C1′ — REPRODUCTION, in gaps.** OCEAN_only **+12.568**, LAND_mid **−29.755**, LAND_hi **−43.600**
  (27j and 27p, each minus its own INCUMBENT −1546.195). Tolerances unchanged: 0.10 / 0.30 / 0.30.
  INCUMBENT is 0 by construction and so drops out as a gate — its absolute value is instead
  REPORTED as the measurement of the objective shift.
- **C2′ — NESTING, in gaps.** gap_free(arm) ≥ gap_pinned(arm) − 0.02, against 27q's own gaps
  (LAND_mid −80.420, LAND_hi −162.143, OCEAN_only +12.535, JOINT_mid −33.415, JOINT_hi −78.720).
- **The as-registered absolute-form results are REPORTED ANYWAY**, next to the gap form, so the size
  of the objective shift is visible rather than hidden by the repair.

**⚠ THE RESIDUAL RISK IS NAMED AND WILL BE MEASURED, NOT ASSUMED.** Gap form is exact only if the
option-5 reweighting contributes the SAME amount in every arm. `sigma_eff` is a function of `h_ml`
ALONE, and `h_ml` is FROZEN at 96.4737 m in every arm here, so the reweighting is fixed; but the
ocean-gradient RESIDUAL could still respond to the seasonal slice. **Gate C7: the ocean-gradient
rows' by-stream loglik must vary by ≤ 0.05 across all six arms.** If it varies more, the gap-form
comparison to 27j/27p is contaminated too and NO cross-run gate is read.

**C4 is affected only at second order** — it is a ratio of within-run differences, and both its
numerator and denominator are computed entirely inside this run. The cross-run part of C4 is the
comparison to 42.9 / 43.7 %, which inherits whatever C7 measures.
