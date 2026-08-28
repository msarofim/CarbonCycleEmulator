# INTERIM 2026-08-27n — **THE CANCELLATION ARM: STAGE 1 IS IN, AND P5 FAILS THE SAME WAY 27i DID**
# ⚠ INTERIM. The conditional arm (P4, P6, P7, P8) is STILL RUNNING. Do not read this as the verdict.

Pre-registered `notes/prereg_2026-08-27n_...md`, committed **`11a59de` BEFORE**
`calibration/diag_seas_T_amp_sh_power.R` existed (driver `f0c7a1e`). **No gate was moved.**

## STAGE 1 — ALL FOUR FROZEN GATES PASS, AND THE CLOSED FORM WAS RIGHT

| a_t (K) | SH-land ppm | phase | resp channel | SPO total | Δlogpost | Δlogprior |
|---|---|---|---|---|---|---|
| **1.0391** (landed) | 1.3083 | 10.09 | 0.0924 | 1.1407 | −0.00 | −0.00 |
| 3.5915 (bracket LO) | 1.1144 | 9.90 | 0.3195 | 1.0831 | **−46.53** | +9.02 |
| 5.0502 (prior init) | 1.0094 | 9.77 | 0.4495 | 1.0702 | **−100.43** | +9.18 |
| **7.1012 (bracket HI)** | **0.8728** | 9.52 | 0.6324 | 1.0780 | **−204.45** | +8.34 |
| 11.08 ⚠ geometry only | 0.6719 | 8.78 | 0.9872 | 1.1754 | −497.48 | +5.73 |
| 13.95 ⚠ geometry only | **0.6181** | 8.04 | 1.2429 | 1.3010 | −782.52 | +3.72 |
| 20.00 ⚠ geometry only | 0.8107 | 6.65 | 1.7802 | 1.6623 | −1582.17 | −0.35 |

- **P0 PASS** — identity control exact (Δlogpost 0.000000); harness offset −3.3223, unmoved.
- **P1 PASS** — the pre-registered closed form matched at **0.4 / 0.4 / 0.6 / 0.7 %** against a 3 %
  gate. The two-channel decomposition and the linearity assumption are both vindicated.
- **P2 PASS** — **the geometric floor is REAL and the profile is NON-MONOTONE**: minimum
  **0.6181 at 13.95 K** (predicted 0.633), and 20.0 K gives **0.8107 > 0.6181**. Only the 153°
  near-antiphase geometry predicts that turn.
- **P3 PASS** — prior pays **+8.34**, exactly as computed.

**⇒ The mechanism is exactly what 27m said it was. The lever has the sign, the geometry, and the
prior. And it is still not affordable.**

## ⇒ P5 FAILS, AND IT FAILS IN THE PRE-REGISTERED DIAGNOSTIC WAY

Per-stream, frozen, vs the incumbent (`ccx_loglik(by_stream = TRUE)`):

| row | a_t = 3.59 | a_t = 7.10 |
|---|---|---|
| `co2_seasonal_MLO` | +0.41 | +0.55 |
| **`co2_seasonal_SPO`** | **−50.54** | **−187.21** |
| `d13c_seasonal_MLO` | −1.49 | −3.65 |
| `d13c_seasonal_SPO` | −3.76 | −20.85 |
| `co2_icecore` | −1.41 | −3.54 |
| **TOTAL** | **−56.79** | **−214.70** |

**`co2_seasonal_SPO` carries −187.21 of −214.70 — 87 % of the entire bill.** The prereg fixed this
gate as `Δ > 0` and wrote down what a failure would mean:

> *"If it punishes here too, the SPO CO2 row is vetoing ANY change to SH land and the arc's whole
> framing needs re-examining, not just this lever."*

**IT IS THE SAME SIGNATURE AS 27i**, where that single row carried **−113.25 of −113.87** against the
productivity lever. Two levers, opposite directions, same veto. The cause is already on the books:
**the mode matches observed SH seasonal CO2 to ~1 %, so `co2_seasonal_SPO` HAS NO POWER — it is
already matched and can only punish a driver that MOVES.** [[seas_right_observable_wrong_drivers]]

**AND THE PROFILE SHOWS THE MECHANISM DIRECTLY.** The SPO total goes **1.1407 → 1.0831 → 1.0702 →
1.0780** against an observed **1.168**. Cancelling SH land pulls the total DOWN and AWAY. The total
was only right in the first place **BY CANCELLATION** — land 1.92× too big against an ocean 0.45× too
small — so **any single-channel fix breaks it.** [[land_and_ocean_are_one_fix]]

## ⇒ THE READ: THIS IS 27j's LESSON AGAIN, WITH A DIFFERENT LEVER

27j solved exactly this for the productivity lever by moving **land AND ocean together** — interaction
**+64.99** — but it did so with a `seas_npp_amp_SH` value the provenance forbids (27l/27m). **The
cancellation lever is the admissible version of the same move, and it needs the same counterweight.**

**The natural next arm is a 2×2 in `seas_T_amp_SH` × `ent_seas_amp_SH`** — the same parameter-balanced
INTERACTION statistic as 27j, with the cancellation lever in place of the forbidden productivity one.
Prediction available in advance: raising respiration cuts the SPO total by ~0.06 ppm, and 27j's
entrainment channel raised the ocean limb by ~0.37 ppm at the right phase, so the counterweight has
ample reach. **NOT RUN, NOT PRE-REGISTERED YET.**

## ⚠ STILL RUNNING / STILL OPEN

- **The conditional arm is STILL RUNNING** (point 2 of 4 after ~80 min; the warm start has to travel
  3.5× in one step). **P4, P6, P7 and P8 have NO RESULT YET.** Reference point landed:
  a_t 1.0391 → cond Δlp **+1.43**, converged (1 restart, last gain 0.0000), SH-land 1.3234, ratio 1.946.
  ⚠ **Do not infer P4 from the frozen −204.45** — 27i's conditional bought back ~30 %, and the number
  must be reported as measured, not predicted.
- **A DRIVER BUG WAS FOUND AND FIXED MID-RUN.** The first version probed `attr(lp(u), "streams")`,
  got NULL, and **printed a tidy "per-stream breakdown unavailable" line while silently skipping P5 —
  the arm's own diagnostic gate.** The breakdown comes from `ccx_loglik(by_stream = TRUE)`. Fixed in
  the repo copy (the run continued from its frozen `/tmp` copy, which is what made that safe).
  **A gate that declines to run is worse than one that fails.** [[mutation_test_gates]]
  ⚠ The P5 table above was produced by a standalone re-run, so **the log in `/tmp/ccx_ta.log` still
  shows the "unavailable" line** — the RDS from this run will not carry the streams.
