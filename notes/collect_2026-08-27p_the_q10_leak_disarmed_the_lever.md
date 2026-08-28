# COLLECT 2026-08-27p — **THE CONDITIONAL SLICE WAS LEAKING 64 % OF THE LEVER THROUGH `q10`**
# All six pre-registered gates PASS. Two of 27o's own readings are overturned.

**Prereg:** `notes/prereg_2026-08-27p_q10_pin_slice_repair.md`, committed **`a92aa5f` BEFORE the
driver existed**. **No gate moved.** Driver `calibration/diag_seas_slice_q10_pin.R`, output
`outputs/diagnostics/seas_slice_q10_pin.rds`. **Nothing in `R/` or `src/` was touched**, so the
1157/0 suite is untouched by construction.

    S0 ✓ S1 ✓ S2 ✓ S3 ✓ S4 ✓ S5 ✓   ·   ~60 s/point, against 27n's 10 / 70 / 150+ min.

---

## 1. THE MECHANISM, MEASURED

`R/model.R:194-195`, written before this arc: *"seas_T_amp_* absorbs the LINEAR seasonal response
(**at small amplitude only the product `A_T · ln(q10)` is identified**), leaving q10 only the
nonlinear part."* `q10` is **GLOBAL** — one parameter for both hemispheres.

⇒ In 27n's five-parameter slice the optimiser rode that documented ridge:

| a_t (K) | q10 | seas_T_amp_NH | **NH product** | **SH product** | SH-land |
|---|---|---|---|---|---|
| MODE | 1.13579 | 23.4574 | 2.98679 | 0.13231 | — |
| 1.0391 | 1.10920 | 28.6327 | 2.96745 | 0.10769 | 1.3234 |
| 3.5915 | 1.06276 | 49.0455 | 2.98550 | 0.21863 | 1.2552 |
| 5.0502 | 1.04956 | 61.7339 | 2.98638 | 0.24430 | 1.2395 |
| 7.1012 | 1.03834 | **79.3466** | 2.98556 | 0.26719 | 1.2256 |

**The NH product is held to 2.98122 ± 0.00919 = 0.31 % while its two factors move 2.77× and 2.75×.**
Sliding `q10` down that ridge cancels the SH perturbation, because `q10` is shared. **The SH product
— the thing the arm perturbs — rose 2.48× where a pinned `q10` gives 6.83×: THE ARM DELIVERED 36.3 %
OF ITS OWN LEVER.** The bill was `seas_T_amp_NH` running to **79.35 K, prior z +7.65** (mode z +2.19).

## 2. THE REPAIR, AND ITS PRICE

Pin `q10` at the **mode's 1.13579**; leave `seas_T_amp_NH` free. The NH product still spans its
whole range through `seas_T_amp_NH` alone, so **nothing the seasonal rows identify is removed** —
what is removed is `q10`'s nonlinear part and its cross-timescale duty (`model.R:1086`), which the
LEVEL rows and `gcb_land_sink` identify and a seasonal arm has no business dragging.

- **S0 ✓ the pin costs −1.36** at the landed point (band [−5, 0]; the sign is an exact requirement).
- **S5 ✓ `gcb_land_sink` moves −0.04 = 0.03 % of the bill.** The pin does not trade a seasonal
  problem for a budget one — the risk it carried by construction did not materialise.

## 3. THE RESULT

    a_t      pinned Δlp   27n free Δlp    SH-land   ×obs   SPO tot   sTaNH    sstSH (z)
    1.0391       +0.00         +0.00       1.3084   1.92    1.1372   23.39   0.3663 (-6.25)
    3.5915      -37.96        -12.72       1.1118   1.63    1.1182   24.11   0.2420 (-7.90)
    5.0502      -80.15        -22.56       1.0036   1.47    1.1032   24.51   0.1975 (-8.72)
    7.1012     -161.72        -35.11       0.8595   1.26    1.0876   25.06   0.1553 (-9.68)

- **S1 ✓ (the headline).** Pinned SH-land at bracket HI = **0.8595**, gate ≤ 1.05, against the free
  slice's **1.2256** — and it lands **below the full-frozen 0.8728**. The four remaining slice
  members are two OCEAN amplitudes, the **NH** land amplitude and a LAG; **none of them can restore
  SH-LOCAL land, and measurably none of them does.**
- **S2 ✓** `seas_T_amp_NH` stays **25.06 K (z +2.49)** against the free slice's 79.35 (z +7.65).
- **S3 ✓** the honest cost is **−161.72**, 4.6× the leaked slice's −35.11.
- **S4 ✓ SAME ROW, SAME DIRECTION.** `co2_seasonal_SPO` carries **−104.91 = 73.6 %** of the
  likelihood bill (27i: 87 %; 27n frozen: 87 %). Nothing else exceeds 9.3 %.

**⇒ SH-land VACATED = 0.4489 ppm, closing 71.8 % of the excess — not the 15.3 % 27n reported.
27n's P8 headline was measured on a lever running at just over a third of its strength.**

## 4. WHAT THIS OVERTURNS IN 27o — TWO THINGS, AND THE SECOND MATTERS MORE

**(a) 27o §7 called this a SPEED problem.** It was also an ATTENUATION problem. Points now take
**~60 s** instead of 10 / 70 / 150+ min, so the speed diagnosis was right — but the same flat
direction was silently disarming the arm, and the speed symptom is what made it look benign.
This is `[[no_power_null]]` in a new dress: **not a null with no lever, but a lever attenuated by a
route back through a SHARED parameter.** ⚠ 27n's **P4 (−35.11, "the prediction was wrong")** and its
**P8 (1.79× obs, 15.3 % closed)** must not be quoted as the cancellation mechanism's reach.

**(b) ⚠ 27o §5's "P6 ✓ — the one clean result" IS FALSIFIED, and §6 was built on it.** 27o read
`sst_seas_amp_SH` moving "only 0.3596 → 0.3046, z −1.19" as *"the improvement is EARNED, not
bought — and the ocean limb still has room"*, and then wrote **"P6 is what makes it worth running."**
With the leak closed the limb goes **0.3663 → 0.1553, z −6.25 → −9.68** — **past 27j's LAND-only
collapse to 0.176 (z −9.18).** The ocean limb has NO room. The apparent room was the q10 leak.

## 5. THE EXCHANGE RATE — WHY THE TWO VETOED LEVERS FAILED ON THE SAME ROW

Cost per ppm of SH-land removed, rung to rung:

| segment | PINNED `seas_T_amp_SH` | 27n FREE (leaked) |
|---|---|---|
| 1.0391 → 3.5915 | **193.0** | 186.5 |
| 3.5915 → 5.0502 | 389.9 | 628.5 |
| 5.0502 → 7.1012 | 566.1 | 904.7 |
| chord | 360.2 | 359.2 |

`seas_npp_amp_SH` (27j LAND-only, **INADMISSIBLE**): **206.8 per ppm** for 0.3828 ppm.

⇒ **THE TWO LEVERS COST THE SAME AT THE MARGIN — 193.0 vs 206.8, 7 % apart — AND DIFFER ONLY IN HOW
LONG THEY STAY CHEAP.** The productivity lever holds ~207/ppm out to 0.383 ppm; the cancellation
lever's rate has already doubled by 0.2 ppm and trebles by 0.45. That is what a **single row pricing
the SH-land amplitude regardless of which knob moves it** looks like, and it is a sharper form of
27o §6's "a row with no power punishing motion."

⚠ **The two chords agreeing at 359 / 360 is chord ARITHMETIC over different arcs on a convex curve,
NOT an invariance.** Do not quote it as one.

## 6. WHAT THIS DOES **NOT** DO

- **It does not rehabilitate `seas_T_amp_SH`.** FULL-FROZEN at bracket HI is **−204.45**
  (`co2_seasonal_SPO` −187.21) and conditionally it is now **−161.72**, *worse* than the −35.11 that
  27o already called a veto. **The 27o §6 veto is STRENGTHENED, not weakened.**
- It edits **no constant and no prior**. `SEAS_NPP_AMP_SH`, `phi_eff` and the `q10` prior are as
  shipped. The **basis decision** and the **`SEAS_NPP_AMP_SH` sd restatement** remain Marcus's.
- ⚠ **S3 was mis-argued in the prereg.** I wrote it was EXACT "for the same reason as S0". It is
  not: S0 compares pinned vs free *at one point* (exact — removing a d.o.f. cannot improve a fit),
  whereas S3 is a difference of differences and carries no sign constraint. It passed on its stated
  band and its stated reference. **The genuinely exact check is `pinned(a) ≤ free(a)` at every rung,
  and it holds at all four** (−1.36, −26.60, −58.95, −127.97). The gate stands as scored; the
  reasoning behind it was mine and was wrong.

## 7. THE NEXT ARM — RE-DERIVED, NOT INHERITED

27o §6's 2×2 in **`seas_T_amp_SH` × `ent_seas_amp_SH`** is still the right experiment, but **its
stated motivation is gone and must be replaced, not reused**:

- **DEAD motivation:** "P6 says the ocean limb still has room." §4(b) — it does not.
- **LIVE motivation, and it is stronger:** on the repaired slice the admissible lever now vacates
  **0.4489 ppm** of SH land against the inadmissible one's **0.3828** — **within 15 %** — and
  collapses `sst_seas_amp_SH` to **z −9.68** against **z −9.18**. **The two levers now produce the
  same defect at the same price.** 27j is the one experiment that ever repaired that defect: its
  JOINT arm pushed `sst_seas_amp_SH` back UP to 0.6563 with `ent` at **8.105, inside 5–30**, and
  rotated the ocean limb **4.13 → 9.24 mo** (obs 8.52), for **INTERACTION +64.99**.

⇒ **The 2×2 is now a genuine replication test with an admissible lever**, and it must be built on
the **PINNED** slice. Parameter balance survives the swap: with `seas_T_amp_SH` pinned in the LAND
and JOINT arms and `ent` free in the OCEAN and JOINT arms, `npar` counts **k − (k−1) − (k+1) + k = 0`**.
**NOT pre-registered. NOT run.**

⚠ **Every earlier conditional slice containing BOTH `seas_T_amp_NH` and `q10` is suspect on this
ground and should be re-read before being quoted.** 27j's four arms were CHECKED and are CLEAN —
its NH product spans 2.9705–3.0224 (1.7 %) with `q10` staying 1.094–1.109 and `seas_T_amp_NH`
29.1–33.3 — because `seas_T_amp_SH` was FREE there and absorbed the SH adjustment itself.
