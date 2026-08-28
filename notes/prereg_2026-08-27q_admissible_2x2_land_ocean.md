# PREREG 2026-08-27q — **THE 2×2 WITH THE ADMISSIBLE LEVER**
# `seas_T_amp_SH` × `ent_seas_amp_SH`, on the REPAIRED (q10-pinned) slice.
# Written and committed BEFORE the driver exists. **No gate below may move.**

**State when written:** repo clean at `a5caa94`, nothing running, suite **1157 / 0** (re-run today).

---

## 0. THE CLAIM, AND WHY IT IS A REPLICATION AND NOT A NEW HYPOTHESIS

27j ran this 2×2 with `seas_npp_amp_SH` as the land lever and got **INTERACTION +64.99** against a
pre-registered +39.59: the entrainment channel supplied what the land reduction vacated, reaching
**8.105 (inside 5–30 for the first time)** and rotating the SH ocean limb **4.13 → 9.24 mo** (obs
8.52). **27l then ruled that lever INADMISSIBLE** — the GPP/PsnNet bracket is ORDERED and GPP was
never available — so 27j's LAND and JOINT arms survive only as a **structural claim about coupling**,
not as configurations.

**27p supplies the admissible replacement and, crucially, shows the two levers now produce the SAME
DEFECT AT THE SAME PRICE:**

| | `seas_npp_amp_SH` (27j, INADMISSIBLE) | `seas_T_amp_SH` (27p, ADMISSIBLE) |
|---|---|---|
| SH-land vacated | 0.3828 ppm | **0.4489 ppm** |
| marginal cost, first rung | 206.8 /ppm | **193.0 /ppm** |
| `sst_seas_amp_SH` driven to | 0.176, z −9.18 | **0.1553, z −9.68** |

⇒ **The question is a clean replication: does the channel repair the collapse the ADMISSIBLE lever
causes, as it repaired the one the inadmissible lever caused?**

⚠ **THE MOTIVATION IN 27o §6 IS DEAD AND IS NOT BEING REUSED.** That note said *"P6 is what makes it
worth running"* — `sst_seas_amp_SH` moving "only" to z −1.19, read as *the ocean limb still has
room*. 27p §4(b) falsified it: that room was the `q10` leak, and at full lever strength the limb
collapses **past** 27j's. The arm is worth running for the OPPOSITE reason.

## 1. THE FOUR (SIX) ARMS, AND THE PARAMETER BALANCE

**Base slice, all arms, `q10` PINNED at the mode's 1.13579** (27p S0: the pin costs −1.36 and moves
`gcb_land_sink` by 0.03 %; the NH product still spans its range through `seas_T_amp_NH` alone):

    BASE = c("sst_seas_amp_NH", "sst_seas_amp_SH", "seas_T_amp_NH", "seas_lag_p")   # 4

| arm | `seas_T_amp_SH` | `ent_seas_amp_SH` | npar |
|---|---|---|---|
| **INCUMBENT** | FREE | 0 | 5 |
| **LAND_only** | PINNED | 0 | 4 |
| **OCEAN_only** | FREE | FREE | 6 |
| **JOINT** | PINNED | FREE | 5 |

    INTERACTION = JOINT - LAND_only - OCEAN_only + INCUMBENT,   npar 5 - 4 - 6 + 5 = 0

**Parameter-balanced, so interpretable** where a bare Δlogpost is not — `ent_seas_amp_SH` is a free
scalar with no prior, which is exactly why 27g refused to read one.

⚠ **ONE STRUCTURAL DIFFERENCE FROM 27j, STATED UP FRONT.** There the land lever was a **CONSTANT**
(no d.o.f.: LAND had the same npar as INCUMBENT). Here it is a **CALIBRATED PARAMETER**, so pinning
it **REMOVES** one. The interaction still balances — that is the point of using it — but the two
single-arm gaps are **not** comparable to 27j's line for line, and this note does not compare them.

**⚠ THE BRACKET END IS A METHODOLOGICAL CHOICE, SO IT IS MEASURED, NOT PICKED.** `seas_T_amp_SH`'s
measured bracket is [3.5915 (all SH land), 7.1012 (SH land >30S)]. 27j used the FAR end of its
bracket; 27n's prior centre is the geometric mean 5.0502. **Both LAND and JOINT are therefore run at
BOTH `a_t = 5.0502` (`_mid`) and `a_t = 7.1012` (`_hi`)**, giving two independently balanced
interactions. INCUMBENT and OCEAN_only are shared. **Six arms. If the two interactions disagree in
sign or gate verdict, that is the finding and neither is quoted alone.**

Fitting is 27j's `fit_arm` unchanged (Nelder-Mead maxit 1500 → BFGS polish → restarts until the
gain dies, `RESTOL` 0.02, max 6). `ent` bounds **(0.5, 60)** and init **10**, both 27j's, unchanged
— **BOUNDS, not a prior.**

## 2. THE PRE-REGISTERED GATES

Six of the eight are **27j's own gates reused unchanged**, so this arm cannot pass on a softer bar.

- **P0 — METHOD CONTROL. If it fails, nothing below is read.** At `u_mode` with `ent = 0`, reproduce
  27j's four P0 values to **0.5 %**: total **1.141**, SH-land **1.308**, NH-origin **0.821**, SPO
  ratio **1.930**; and the harness offset **−3.3223 ± 0.5** `[[ccx_mode_logpost_offset]]`.
- **P1 — THE INTERACTION. THE HEADLINE.** `INTERACTION ≥ 0.5 × |INCUMBENT − LAND_only|`, **27j's
  `JR_P1_FRAC = 0.5` reused unchanged** (27j: +64.99 vs a 39.59 gate, 82 % of the land penalty
  recovered). Scored separately for `_mid` and `_hi`.
- **P2 — `ent_seas_amp_SH` ∈ [5, 30]**, 27g's physical band, 27j's gate unchanged (27g landed 4.16,
  below; 27j 8.105, inside).
- **P3 — SPO d13C-per-ppm ≤ 1.70**, 27g's own unmet gate, reused by 27j unchanged (27j: 1.390).
- **P4 — SPO total ∈ [1.114, 1.222]** (obs 1.168; 2× the incumbent's own 0.027 miss). 27j's gate,
  which 27j **FAILED at 1.267**.
- **P5 — SPO ocean ratio ≥ 0.75** of the observed 0.522. 27j's gate, which 27j **FAILED at 0.495**.
- **P6 — MLO control, d13C-per-ppm ∈ [0.90, 1.10]**. 27j's gate (27j: 0.966).
- **P7 — NEW. THE COLLAPSE MUST BE REPAIRED, and this is what 27p makes testable.** JOINT
  `sst_seas_amp_SH` **≥ 0.26**. *Derived, not picked:* the midpoint of 27p's measured pinned-land
  collapse **0.1553** and its pinned incumbent **0.3663** — i.e. **more than half the collapse
  undone**. 27j's JOINT reached 0.6563 from a 0.176 collapse.
- **P8 — NEW. THE LAND FIX MUST SURVIVE THE JOINT REFIT.** JOINT SH-land **≤ 1.05**, 27p's S1 gate
  reused unchanged. **This is the anti-27n gate:** if the joint refit lets SH-land creep back toward
  the incumbent's 1.31, the interaction is being bought by UNDOING the land correction, which is
  exactly how 27n's conditional slice bought back 84 % of its cost.

## 3. PREDICTIONS, RECORDED SO THEY CAN BE WRONG

1. **P1 PASSES at both bracket ends.** The defect is the same and the channel is the same.
2. **P4 has a better chance than it did in 27j.** 27j overshot at **1.267** because its land lever
   left the total high; 27p's pinned land lever pulls the total **DOWN to 1.0876**, below the band,
   and the channel pushes up. So the two errors now oppose. **I predict P4 PASSES at `_hi`.**
3. **P7 PASSES, P5 still FAILS.** The channel rotates the limb but 27j reached only 0.495 of the
   observed ocean amplitude, and nothing in this design adds amplitude the way it adds phase.
4. **`_hi` gives the larger interaction than `_mid`**, since it vacates more.

⚠ **I got a pre-registered prediction WRONG on 27n (P4, "predicted positive", landed −35.11), and
27p then showed that call was made on a lever running at 36 % strength.** Predictions 2 and 4 above
are the ones most likely to repeat that; they are stated so the record shows which.

## 4. THE FALSIFIER, AND WHY A FAILURE IS INFORMATIVE

**P1 FAILS ⇒** the channel cannot supply what the ADMISSIBLE lever vacates, although it could supply
what the inadmissible one vacated. Since the two vacate within 15 % of the same ppm at within 7 % of
the same marginal price (§0), **that difference would localise the coupling in the SHAPE of the
vacancy, not its size** — a productivity cut removes NEP amplitude, a cancellation increase adds
antiphase respiration, and only the first is replaceable by an ocean channel. That is a real result
and 4b becomes the live question on a residual that has now had three levers.

## 5. WHAT THIS RUN DOES NOT DO

- **It edits no constant and no prior.** `SEAS_NPP_AMP_SH`, `phi_eff`, the `q10` prior and the
  `seas_T_amp_SH` prior are as shipped. Nothing in `R/` or `src/` is touched.
- **It does not settle the basis decision** (27o §8) or the **`SEAS_NPP_AMP_SH` sd restatement**.
  Both remain Marcus's.
- **A PASS is not adoption.** `ent_seas_amp_SH` has no prior and `seas_T_amp_SH` would be sitting at
  a pinned bracket value; adopting either into the shipped configuration is a separate call on
  provenance, not a consequence of any gate here.
- ⚠ **No absolute logpost may be quoted against the mode file** (offset −3.3223). Everything is a
  within-harness difference.
