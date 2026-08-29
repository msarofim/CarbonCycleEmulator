# Handoff — CarbonCycleEmulator, 2026-08-29b: **THE `q10` CONFOUND IS CLOSED, THE OPPOSITE WAY**
# The channel-recovery fraction measures **ESCAPE, not SUPPLY** — 83.6 % / 42.9 % / **21.0 %**.
# **NEXT STEP: I RECOMMEND REORDERING — step 2 has a MEASURED near-null (§4).**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, at `1454350`.
Continues `handoff_2026-08-29_refit_landed_hml_is_an_artefact.md`, whose §4 step 1 this executes.

⚠ **SESSION CWD WAS `FaIRtoFrEDI/`; ALL THIS WORK IS IN `CarbonCycleEmulator/`.**
⚠ **NOTHING ADOPTED, QUARANTINED OR REPOINTED.** `ccx_mode_file()` still resolves `from90`; the
`refit_20260828_sigma_eff` decision from 08-29 stands unchanged (do not adopt).

---

## 0. STATE IN SIX LINES

1. **Step 1 (the controlled `q10` test) is DONE and it closed the confound the OPPOSITE way.** §1
2. **Recovery goes 42.9/43.7 % → 21.0/17.0 % with `q10` free — AWAY from 27j's 83.6 %.** §1
3. ⇒ **`q10` is NOT the explanation; the LEVER is.** The fraction is not a channel property. §2
4. ⚠ **I mis-specified two gates and repaired both on the record, one BEFORE seeing results.** §3
5. ⚠ **BOTH of my registered predictions were wrong in magnitude.** §3
6. ⚠ **STEP 2 OF THE QUEUE HAS A MEASURED NEAR-NULL — I recommend reordering. §4**

## 1. THE RESULT

`calibration/diag_q10_controlled_recovery.R` = 27q's six arms with **ONE axis moved**, `q10` FREE in
every arm. 6 arms, 29 min. Output `outputs/diagnostics/q10_controlled_recovery.{rds,log}`.

| | lever | `q10` | land cost | INTERACTION | **recovered** | vacancy | per-ppm |
|---|---|---|---|---|---|---|---|
| 27j | `seas_npp_amp_SH` (INADMISSIBLE) | free | 80.44 | +67.28 | **83.6 %** | 0.383 | 175.8 |
| 27q | `seas_T_amp_SH` pinned | pinned | 80.42 / 162.14 | +34.47 / +70.89 | **42.9 / 43.7 %** | 0.305 / 0.449 | 113.0 / 157.9 |
| **NEW** | same lever | **FREE** | 29.75 / 43.60 | +6.24 / +7.41 | **21.0 / 17.0 %** | 0.081 / 0.092 | 77.3 / 80.8 |

**C4 → INTERMEDIATE**: neither registered branch fires (not ≥65 %, not inside 33-54 % at both ends).
The inference the "does not explain" branch existed to license survives *a fortiori* — freeing `q10`
moves the number the WRONG WAY, so it cannot be why 27j reached 83.6 %.

## 2. WHY — AND THIS IS THE MORE USEFUL FINDING

**With `q10` free, the LAND arm stops IMPOSING the defect.** SH-land 1.308 → **1.216** (hi),
vacating **0.092 ppm** against the pinned arm's 0.449. It escapes instead: `seas_T_amp_NH` runs to
**57.5 / 75.5 K = 321-421 % of its measured 17.92 K high end** while `ln q10` falls 59-69 %, holding
the identified product `seas_T_amp_NH · ln(q10)` to **0.4 %**. Pinned, the same arm sits at 137-140 %.

⇒ **The three slices order by HOW MUCH ESCAPE THEY ALLOW, and recovery falls monotonically along
that order. The fraction measures how much the fit was PREVENTED from escaping — not what the
channel supplies. Never quote a recovery fraction without its slice.**

The MECHANISM replicates a THIRD time: `ent` 4.78 / 4.87, `sst_seas_amp_SH` 0.29 → 0.65 in JOINT.
P1 falsified at both ends again (+6.24 vs a 14.88 gate; +7.41 vs 21.80).

## 3. WHAT I GOT WRONG, AND HOW IT WAS REPAIRED

- ⚠ **C1/C2 compared ABSOLUTE logposts across the 08-28 objective change** (`2153bd6`, option 5,
  `sigma_eff` on the ocean-gradient rows); 27j/27p/27q all ran 08-27. **The same defect the previous
  handoff §5 flags in `test-mode-file.R`, reproduced in a driver whose header cites it.** Amended
  the prereg to **GAP form before any arm result** (`0e4f9b3`). C2-as-registered then printed
  ⚠ OPTIMISER FAILURE on the two arms that were perfectly correct, by exactly −0.082 and −0.049.
- ✅ **The shift is an ADDITIVE CONSTANT, measured at four points spanning 60 log units of gap:
  −0.082, −0.082, −0.080, −0.080.** That is what licenses gap form, and it is a measurement.
  In gap form the reproduction of three other drivers is exact: **+12.57, −29.75, −43.60**.
- ⚠ **C7 was mis-scoped** — `grep("grad")` swept in the ATMOSPHERIC `co2_gradient` / `d13c_gradient`
  rows, which option 5 does not touch, and "failed". Narrowed on the COMMIT, not the answer
  (`R/likelihood.R:1541` names `ocean_grad_{dic,d13c,alk}`): spread **0.0169 ≤ 0.05, PASS**.
- ⚠ **Both registered predictions wrong in magnitude**: registered "stable, 33-54 %" (got 21.0/17.0)
  and a per-ppm band 110-200 (got 77.3/80.8). Per-ppm was more stable only RELATIVELY — it moved
  2.2× against the fraction's 4.9×, and is the tighter across the bracket (1.05× vs 1.24×).

## 4. ⇒ NEXT STEP — **AND I RECOMMEND REORDERING THE QUEUE. MARCUS'S CALL.**

**Read `INDEX_ccx_seas.md` first** — not auto-loaded, and it is the active arc.

**⚠ STEP 2 AS WRITTEN HAS A MEASURED NEAR-NULL, AND THE CLAIM THAT "NOTHING HAS BEEN AIMED AT IT"
IS WRONG.** The 08-29 handoff §4 and the sub-index both say: *quantify and attack the 0.821 NH
import directly; it is the biggest term and nothing has been aimed at it.* **I wrote that. It does
not survive its own repo.** `diag_tau_ex_seasonal_power.R` (27h) already aimed a 15-point profile at
exactly this term, and `outputs/diagnostics/tau_ex_seasonal_power.rds` holds the grid:

| τ mult | NH_origin | SPO total | **SH-local land** | SH ocean |
|---|---|---|---|---|
| 1.00 | **0.821** @ 6.46 | 1.140 | **1.308** @ 10.09 | 0.248 |
| 4.00 | **0.219** @ 6.83 | 1.119 | **1.330** @ 10.27 | 0.252 |

**A 73 % reduction of the import moves the SPO total by −1.8 % and moves SH-local land the WRONG
WAY, +1.7 %.** The mechanism is in [[tau_ex_hides_not_causes]] and is route-independent: NH_origin
peaks at 6.5 mo and SH-local land at 10.1 mo — **108° apart, so they partly CANCEL**, and removing
the import EXPOSES the overshoot rather than curing it. **The import is not causing the SH-land
overshoot; it is partly HIDING it.** Kill it entirely and SH-local land is still ~1.31 against obs
0.683 — the same 1.92×.

**Step 3 (the NH box's own amplitude) inherits the same geometry, and has a second problem.** It is
the other route to the same term, so the phase argument applies unchanged; and **MLO land is
already 7.235 vs obs 7.717 = 0.94×**, so there is no room to shrink the NH box, while the open
question recorded in [[seas_spo_two_wrong_pieces]] is whether a HEMISPHERIC mean should be LARGER
than a station — the direction that makes SPO **worse**. Worth CHECKING (it is unchecked, and it is
cheap), but not as a repair candidate.

**⇒ WHAT I RECOMMEND INSTEAD: the SH land box's OWN INTERNAL CANCELLATION.** That is where the
arc's own evidence points and it is the one thing never attacked. [[sh_land_undercancels]]:
**CT2022 has SH land cancelling 74.9 % of its gross swing against NH's 31.8 % — a 2.72× asymmetry —
and the model UNDER-CANCELS**; and the SIZE is exonerated, with CMIP6 saying SH productivity should
roughly DOUBLE (A = 0.94 vs MOD17's 0.50, the opposite way from the assumed bracket). A model whose
gross SH swing is right and whose cancellation is 2.7× too weak lands at ~1.9× observed — **which
is what we measure, and it is the only candidate that predicts the magnitude.**
[[ccx_seas_chan_budget]] already has NEP and respiration 6.6 months antiphase as the cancellation's
mechanism, so the target is their PHASE and RELATIVE AMPLITUDE inside the SH land box.

**⚠ THIS IS A QUEUE CHANGE AND I HAVE NOT ACTED ON IT** ([[handoff_open_item_is_not_a_ruling]]).
The cheap confirming pre-check, if wanted, is a POWER measurement in 27h's own style — profile the
SH land NEP/respiration phase offset and read whether SH-local land can reach 0.683 at all — run
BEFORE any prereg, exactly as the τ pre-check killed fork (a) before its prereg was written.

## 5. NON-OBVIOUS STATE

- ⚠ **THE SUITE IS NOT GREEN, AND THE PREVIOUS HANDOFF'S "1206 pass / 0 fail" IS WRONG.**
  Measured 08-29b: **1205 pass, 2 skipped ({seacarb} not installed), 1 FAIL.**

      1. Failure ('test-mode-file.R:57:3'): no live source hardcodes a fitted-mode path
         hardcoded mode path -- use ccx_mode_file(): diag_hml_seasonal_limbs.R:63

  **It is NOT from this session** — `diag_hml_seasonal_limbs.R:63` came in with `b496b8a`
  (the 08-29a session) and I have not touched that file; my driver hardcodes no mode path.
  **NOT FIXED AND NOT SKIPPED — reported, per the standing rule on a previously passing test.**
  ⚠ It is also not a careless slip: that driver's PURPOSE is to compare the old and new `h_ml`
  modes, so it genuinely needs two mode paths and `ccx_mode_file()` returns one. **The gate and
  the driver are both right; the resolution is a decision** — teach the gate about a declared
  two-mode comparison, or give the driver a sanctioned way to name a non-canonical mode. Note it
  is the SAME test file as the owed item below, so both wants deciding together.
- Nothing running at handoff time.
- ⚠ **STILL OWED from 08-28d, and this session bears DIRECTLY on the first one:**
  (a) `test-mode-file.R`'s `expect_gt(lp[["pin90"]], lp[[CANONICAL]])` compares two STORED logposts
  across the objective change. **This session supplies both the diagnosis and the repair recipe** —
  restate in GAP form, and the shift is an additive −0.081 measured at four points. **I did NOT
  touch it: it currently PASSES, and rewriting a passing test's premise is Marcus's call**
  ([[handoff_open_item_is_not_a_ruling]]). (b) `diag_landed_gap_streams.R` re-point or quarantine
  is still an undecided decision.
- **The `refit_20260828_sigma_eff` outputs are now COMMITTED** (`_run.log`, `mode_fit_pumpN.rds`,
  `mode_fit_pumpN_progress.rds`, `pump_arms_comparison.rds`) — they were uncommitted at 08-29
  despite that handoff saying "clean". **They are provenance for a refit that is NOT adopted.**
- **Run drivers from a FROZEN COPY** ([[never_edit_a_running_script]]); this one was.
- **`MEMORY.md` root 18.6 KB (soft 12)** — over soft, flagged FOUR sessions running now.
  `INDEX_ccx_seas.md` is back UNDER soft (content 13.9 KB) after this session's trim.

## 6. HOW TO RUN WHAT THIS SESSION ADDED

    Rscript calibration/diag_q10_controlled_recovery.R      # ~29 min, 6 arms
