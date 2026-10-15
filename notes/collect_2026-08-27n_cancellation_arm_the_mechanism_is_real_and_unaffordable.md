# Collect 2026-08-27n — **THE CANCELLATION MECHANISM IS REAL, EXACTLY AS PREDICTED, AND UNAFFORDABLE**
# **P0 ✓ P1 ✓ P2 ✓ P3 ✓ · P4 ✗ P5 ✗ P7 ✗ · P6 ✓ · P8 = 1.79× observed, 15.3 % of the excess closed.**
# ⚠ **I PREDICTED P4 WOULD BE POSITIVE. IT LANDED AT −35.11. THAT PREDICTION WAS WRONG.**

> ## ⚠ RE-RUN 2026-08-28 AFTER THE `h_ml` BAND-DECODE FIX — **THE CONCLUSION HOLDS**
>
> Every number below was produced with `h_ml = 85.73 m` (`ccx_unc_to_par(md$u_mode)` under the
> SHIPPED band) where the canonical mode's `h_ml` is **96.47 m**. Fixed by `ccx_adopt_mode_band()`
> (`R/paths.R`, commit `abc9704`); pre-fix outputs are in
> `outputs/quarantine/20260828_hml_band_decode/`. **The driver was re-run and NO VERDICT CHANGED.**
> **P8 1.79× → 1.78× observed**, excess closed 15.3 % → **14.7 %**. ⚠ A SECOND latent bug surfaced here — the per-stream table's `sprintf(" %>10s")` is an invalid format that ABORTS; it had never executed because the original run took the try-error branch (the streams bug §7 records). Fixed.
>
> The SPO seasonal decomposition turns out to be nearly insensitive to `h_ml` — the mixed layer
> sets the ocean's carbon CAPACITY, while the SPO seasonal AMPLITUDE is driven by
> `sst_seas_amp_SH` and the entrainment channel. **The harness offset is now −1.5805, not −3.3223**;
> the 1.7418 difference was the wrong decode, and what remains is the bounded refit's
> narrowed-prior constant.

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
1.0780** against an observed **1.168**. Canceling SH land pulls the total DOWN and AWAY. The total
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

## ⚠ WHY THE CONDITIONAL ARM IS SO SLOW — A DESIGN FLAW IN THIS DRIVER

Points 1 and 2 took ~10 and ~70 min; **point 3 has taken over 2.5 hours.** The cause is on the
books and it is my slice: **`TA_COND_BLOCK` contains BOTH `seas_T_amp_NH` AND `q10`, and
`seas_T_amp_NH x ln(q10)` is an EXACT PRODUCT RIDGE** — held to **2.2609–2.2663** across
q10 = 1.09 → 2.0, Hessian **cor = −0.972**, and "the four seasonal rows move 4.3 log-units across
that whole range... they do NOT identify q10" (`diag_seas_T_amp_q10_ridge.R`, 2026-08-21).
[[ccx_seas_q10_ridge]]

**Nelder-Mead crawls along a flat direction, making gains too small to trip `TA_RESTOL` quickly and
too large to stop.** ⚠ 27i's block had the SAME pair and ran 3 points in ~50 min, so the ridge alone
is not sufficient — what compounds it here is the **warm-start step**: 27i moved a constant in small
sd increments, while this grid jumps `seas_T_amp_SH` by **3.5× then 1.4× then 1.4×**, throwing the
simplex far enough onto the ridge that it has to walk back.

**FIX FOR THE NEXT RUN (not applied — the run is live):** either reparameterize to
`(seas_T_amp_NH x ln q10)` and a ratio, or **drop `q10` from the conditional slice** and say so — the
seasonal rows do not identify it anyway, which is exactly what makes it free to wander. Adding
intermediate warm-start rungs would also help. **Do not simply raise `TA_RESTOL`**; that would buy
speed by accepting under-convergence, which is the failure 27h's discarded run already made once.

## THE CONDITIONAL ARM — COMPLETE, ALL FOUR POINTS CONVERGED (re 1, last gain 0.0000)

| a_t (K) | cond Δlp | frozen Δlp | buy-back | SH-land | ×obs | SPO δ¹³C/ppm |
|---|---|---|---|---|---|---|
| 1.0391 (landed) | +1.43 | −0.00 | — | 1.3234 | 1.94 | 1.946 |
| 3.5915 (bracket LO) | −11.29 | −46.53 | 76 % | 1.2552 | 1.84 | 1.907 |
| 5.0502 (prior init) | −21.13 | −100.43 | 79 % | 1.2395 | 1.81 | 1.899 |
| **7.1012 (bracket HI)** | **−33.68** | −204.45 | **84 %** | **1.2256** | **1.79** | 1.893 |

- **P4 FAIL** — conditional Δlogpost at bracket HI = **−35.11**, gate > −20.
  ⚠ **I pre-registered this as PREDICTED POSITIVE**, reasoning that the prior pays +8.34 and the SPO
  land overshoot should improve. **It is −35.11. That prediction was wrong**, and P5 is why: the row
  that pays is not the row that benefits.
- **P6 PASS** — `sst_seas_amp_SH` **0.3596 → 0.3046, z −1.19**, gate |z| < 2. **The one clean result
  of the conditional arm.** 27j's LAND-only arm saw this parameter **collapse to 0.176 (z −9.18)** to
  absorb its change; nothing of the sort happens here, so **the small improvement this lever does
  deliver is EARNED, not bought.** [[ent_channel_counterweight]]
- **P7 FAIL** — SPO δ¹³C-per-ppm **1.946 → 1.893**, gate < 1.85. Right direction, misses.
- **P8** — residual **1.2256 = 1.79× observed**, closing **15.3 %** against a predicted **68.8 %**.

**⇒ THE REFIT UNDOES 78 % OF THE LAND IMPROVEMENT.** Frozen, the lever takes SH-land **1.308 →
0.873** (−0.435); conditionally it manages **1.3234 → 1.2256** (−0.098). The slice buys back 84 % of
the logpost **by restoring the very signal the lever removed** — and it need not wreck anything to do
it (P6), it simply re-inflates SH land through the other seasonal parameters. **An 84 % buy-back that
returns the diagnostic almost to its starting value is not a cheaper fix; it is a refusal.**

## ⇒ THE VERDICT

**The mechanism is real and the arithmetic that predicted it was exactly right** — P1 to 0.4–0.7 %,
and P2's non-monotone floor turning at 13.95 K is a signature only the 153° geometry produces.
**27m's diagnosis stands: SH land under-cancels.** But `seas_T_amp_SH` **cannot deliver the fix
alone**, for the reason P5 exposed and P4 confirmed: **the SPO CO₂ row vetoes any single-channel
change to SH land, because the total is right BY CANCELLATION and every one-sided move breaks it.**

**Two levers have now failed in the same place from opposite directions** — `seas_npp_amp_SH` (27i,
−113.25 of −113.87 on that row) and `seas_T_amp_SH` (−187.21 of −214.70). That is not two
coincidences; it is a row with no power punishing motion.
[[seas_right_observable_wrong_drivers]] [[land_and_ocean_are_one_fix]]

## ⇒ NEXT — 27j's STRUCTURE WITH AN ADMISSIBLE LEVER

27j solved exactly this for the productivity lever by moving **land and ocean together** (interaction
**+64.99**) — but with a `seas_npp_amp_SH` value the provenance forbids (27l/27m). **`seas_T_amp_SH`
is the admissible lever and it needs the same counterweight.**

**Proposed: a 2×2 in `seas_T_amp_SH` × `ent_seas_amp_SH`**, same parameter-balanced
`JOINT − LAND − OCEAN + INCUMBENT`. The reach is there in advance: canceling SH land drops the SPO
total ~0.06 ppm (1.1407 → 1.0780 frozen) while 27j's entrainment channel added **≈0.37 ppm at month
9.24** against an observed 8.52. **P6 is what makes it worth doing** — the ocean limb moved only
z −1.19 here, so there is room. ⚠ **NOT RUN, NOT PRE-REGISTERED.**

## ⚠ STILL OPEN

- **The driver's conditional slice should be repaired before reuse** — see the ridge diagnosis above.
- **The RDS `outputs/diagnostics/seas_T_amp_sh_power.rds` does NOT carry the per-stream breakdown**,
  because the streams bug was fixed after this run started; the P5 table came from a standalone
  re-run. Re-run the fixed driver if the streams are wanted in the archive.
- The second inversion column (27m sec.5), and the `co2_NH`→MLO seasonal-amplitude representation
  term (27k sec.7), both still untouched.
