# COLLECT 2026-08-27q — **THE MECHANISM REPLICATES IN FULL. THE ARITHMETIC DOES NOT.**
# P1 FALSIFIED at both bracket ends — and every physical gate that describes the
# mechanism PASSES. The channel recovers **42 %** of the land penalty, not 27j's 82 %.

**Prereg:** `notes/prereg_2026-08-27q_admissible_2x2_land_ocean.md`, committed **`36e4051` BEFORE**
the driver existed. **No gate moved.** Driver `calibration/diag_admissible_2x2_land_ocean.R`,
output `outputs/diagnostics/admissible_2x2_land_ocean.rds`. **`R/` and `src/` untouched.**
All six arms converged (1 restart, last gain 0.0000). 70–207 s per arm.

    P0 ✓  ·  P1 ✗ ✗  ·  P2 ✓✓ P3 ✓✓ P6 ✓✓ P7 ✓✓ P8 ✓✓  ·  P4 ✗✗ P5 ✗✗

**P0 reproduced ALL FOUR of 27j's control values to three decimals** — total 1.141, SH-land 1.308,
NH-origin 0.821, SPO ratio 1.930, offset −3.3223. A three-session reproducibility check, and the
LAND arms land within **0.07** of 27p's independently-fitted conditional profile (−80.08 vs −80.15,
−161.65 vs −161.72).

---

## 1. THE SIX ARMS

| arm | `a_t` | `ent` | logpost vs `u_mode` | npar |
|---|---|---|---|---|
| INCUMBENT | 1.0416 (free) | 0 | +0.07 | 5 |
| LAND_mid | 5.0502 | 0 | −80.08 | 4 |
| LAND_hi | 7.1012 | 0 | −161.65 | 4 |
| OCEAN_only | 1.2443 (free) | **4.342** | +12.41 | 6 |
| JOINT_mid | 5.0502 | **5.886** | −34.92 | 5 |
| JOINT_hi | 7.1012 | **7.046** | −81.54 | 5 |

    INTERACTION = JOINT - LAND - OCEAN + INCUMBENT,  npar 5-4-6+5 = 0  (asserted, not printed)

| | land cost | INTERACTION | gate (0.5×) | **recovered** |
|---|---|---|---|---|
| **mid** | 80.15 | **+32.81** | 40.07 | **40.9 %** |
| **hi** | 161.72 | **+67.76** | 80.86 | **41.9 %** |
| *27j, productivity, ⚠ different slice* | *79.18* | *+64.99* | *39.59* | *82.1 %* |

**⇒ P1 FAILS at both ends, at 82 % and 84 % of its gate — and the RECOVERED FRACTION is 40.9 % and
41.9 % across a 2× range of land cost.** That stability is itself a measurement: **the channel
supplies a fixed FRACTION of what the cancellation lever vacates, not a fixed amount.**

## 2. THE MECHANISM REPLICATES — EVERY QUALITATIVE FEATURE OF 27j

This is not a null. **Five of the seven physical gates pass at both ends**, and they are precisely
the ones that describe the coupling:

- **THE CHANNEL IS SUPPRESSED BY THE LAND ERROR AND RELEASED WHEN IT IS FIXED — 27j's central
  structural claim, replicated with the ADMISSIBLE lever.** `ent` sits at **4.342, BELOW the 5–30
  band, in OCEAN_only** (27g got 4.16 — reproduced), and rises **INSIDE** the band the moment the
  land is pinned: **5.886 (mid), 7.046 (hi)**. **P2 ✓✓.** The release even scales with how much land
  is fixed.
- **The SH ocean limb ROTATES 4.13 → 8.94 / 9.42 mo** (obs 8.52); 27j got 9.24.
- **P7 ✓✓ the collapse IS repaired.** 27p showed the pinned land lever alone crushes
  `sst_seas_amp_SH` to **0.1553 (z −9.68)**. In JOINT it recovers to **0.5515 / 0.4856**, against a
  gate of 0.26 derived before the run.
- **P8 ✓✓ and this one matters most.** JOINT SH-land is **1.003 / 0.859** — *identical* to LAND_mid
  / LAND_hi. **The joint refit does NOT undo the land correction.** The 42 % shortfall is a genuine
  residual cost, not the 27n failure mode of buying the cost back by restoring the signal.
- **P3 ✓✓** partition 1.936 → **1.524 / 1.432** (gate ≤1.70; 27j 1.390). **P6 ✓✓** MLO control 0.961.
- **The interaction is carried by the vetoed row.** Row-wise, `co2_seasonal_SPO` supplies **+50.36 of
  the +67.76 (74 %)**; no other stream exceeds 1.1. **The row that punishes each single move is the
  row that pays for the joint one** — which is what "the land and ocean corrections are ONE fix"
  has to mean mechanically. [[land_and_ocean_are_one_fix]]

## 3. WHY IT STILL FAILS — THE LIMBS NOW ADD ALMOST PERFECTLY

**P4 ✗✗ and it fails WORSE than 27j: SPO total 1.326 / 1.376 against 27j's 1.267 and an observed
1.168.** The reason is geometric, and it is the arc's own thesis turned up one notch:

| arm | SH-land | mo | SH-ocean | mo | **gap** | total |
|---|---|---|---|---|---|---|
| INCUMBENT | 1.308 | 10.09 | 0.250 | 4.13 | **5.96 mo** | 1.137 |
| LAND_hi | 0.859 | 9.59 | 0.106 | 4.13 | 5.46 mo | 1.088 |
| **JOINT_hi** | 0.859 | 9.59 | 0.278 | 9.42 | **0.17 mo** | **1.376** |
| *27j JOINT* | *0.906* | *10.08* | *0.258* | *9.24* | *0.84 mo* | *1.267* |
| OBSERVED | 0.683 | — | 0.522 | 8.52 | — | 1.168 |

The incumbent's total is right **because the two limbs are 5.96 months apart and SUBTRACT**. Rotating
the ocean into place is physically correct — nature's land and ocean both peak ~8.5–9.3 — but it
**removes the cancellation**, and what it exposes is that **SH land is STILL 1.26× observed and SH
ocean STILL 0.53× observed.** With the limbs antiphase those two errors hid each other; in phase they
**add**. **P5 ✗✗ (0.532 of the observed ocean, gate 0.75): the channel supplies PHASE, not
AMPLITUDE**, exactly as predicted.

⚠ **AND THE CANCELLATION LEVER MAKES THIS WORSE THAN THE PRODUCTIVITY LEVER DID.** It rotates the
**land** limb too (10.09 → **9.59**), where the productivity lever left it at 10.08. So the gap
closes to **0.17 mo** against 27j's 0.84, the limbs add more completely, and the overshoot grows.

## 4. DOES THIS SUPPORT THE PREREG'S FALSIFIER? **PARTLY — AND THE CLEAN TEST WAS NOT RUN**

Prereg §4 said a P1 failure "would localise the coupling in the SHAPE of the vacancy, not its size."
**The phase table above is direct evidence for exactly that** — the two levers vacate within 15 % of
the same ppm at within 7 % of the same marginal price, but one rotates the land limb half a month and
the other does not.

⚠ **BUT THE 82 % vs 42 % CONTRAST IS CONFOUNDED AND I WILL NOT QUOTE IT AS CONTROLLED.** 27j ran a
**6-free + ent** slice with `q10` FREE; this ran **4–5 free + ent** with `q10` PINNED. Each
interaction is balanced *within* its own design, but the recovered FRACTION is not a controlled
comparison across designs. **What IS controlled here is that the fraction is 40.9 % and 41.9 % at two
bracket ends of the same design.**

**⇒ THE CONTROLLED TEST, NOT RUN AND NOT PRE-REGISTERED: re-run 27j's `seas_npp_amp_SH` lever on
THIS pinned slice.** Same slice, same pin, same `ent` handling, only the land knob differs. That is
the one experiment that separates "the lever" from "the design", and it is cheap — the arms here
took 70–207 s.

## 5. MY PREDICTIONS, SCORED — **2 OF 4, AND THE MISS WAS A SCALAR ERROR ON VECTOR QUANTITIES**

| # | prediction | outcome |
|---|---|---|
| 1 | P1 passes at both ends | ✗ **WRONG** (failed at both, at 82 %/84 % of gate) |
| 2 | P4 passes at `_hi` | ✗ **WRONG** — 1.376, *worse* than 27j's 1.267 |
| 3 | P7 passes, P5 still fails | ✓ right, both |
| 4 | `_hi` interaction > `_mid` | ✓ right (67.76 > 32.81) |

⚠ **Prediction 2's reasoning was the error worth recording.** I wrote that the land lever "pulls the
total DOWN to 1.0876" while the channel "pushes up", so "the two errors now oppose". **That treats
two limbs as SCALARS when they are VECTORS, and the driver computes `amp` AND `ang_mo` for exactly
that reason.** They do not oppose — rotating the ocean makes them ADD. I had 27p's phase columns in
front of me. **A magnitude that moves in the wanted direction can still be a phase error making the
sum worse; check the angle before predicting a sum.**

## 6. WHERE THIS LEAVES THE ARC

**Three levers have now been tested on `co2_seasonal_SPO`, and the residual has survived all three.**
`seas_npp_amp_SH` (27i, inadmissible), `seas_T_amp_SH` (27n/27p, admissible, vetoed at −161.72), and
now the joint land+ocean fix, which **repairs the phase and the partition but overshoots the total by
18 %**. The remaining, and now sharply-posed, defect is an **AMPLITUDE pair**: with the limbs finally
in phase, **SH land is 1.26× observed and SH ocean 0.53× observed**, and those no longer hide each
other. That is a much better-posed target than the arc has had at any point.

**Open, in order:**
1. The **controlled lever contrast** of §4 — cheap, and it decides whether §3's shape reading holds.
2. **4b** (the SH ocean AMPLITUDE, as distinct from the phase channel), which P5 has now failed three
   times — 27g, 27j and here — always for the same reason.
3. Unchanged and still Marcus's: the **basis decision** (27o §8) and the **`SEAS_NPP_AMP_SH` sd
   restatement**.

⚠ **NOTHING HERE IS ADOPTED.** `ent_seas_amp_SH` has no prior and `seas_T_amp_SH` sat at a pinned
bracket value in every arm that passed anything. No constant and no prior was edited.
