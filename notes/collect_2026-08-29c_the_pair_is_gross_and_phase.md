# COLLECT 2026-08-29c — **THE PAIR IS (GROSS × PHASE), NOT (GROSS × RESPIRATION)**
# Doubling the gross makes the observation UNREACHABLE: floor **1.183 > 0.683**.
# But the phase lever is a FITTED parameter — `seas_lag_p`, and it reaches.

**Prereg:** `notes/prereg_2026-08-29c_gross_cancellation_geometry.md` (`30320c1`), gates fixed
before the driver. **Driver:** `calibration/diag_gross_cancellation_geometry.R`. **Output:**
`outputs/diagnostics/gross_cancellation_geometry.{rds,log}`. **12 seconds**, ~60 model runs.

---

## 1. THE ANSWER

**G0 PASS** — reproduces 27n at the mode to better than 0.4 %: NEP **1.3896 @ mo 10.15**,
respiration **0.0923 @ 5.05**, vector sum **1.3080 @ 10.09**, separation **152.9°** (27n: 1.3950 /
0.0926 / 1.313 / 153°). **G1 PASS** — closed-form floor **0.6320** vs 27n's 0.633, and the MEASURED
minimum **0.6180 at 13.95 K**, −2.2 % of it, with the profile turning upward after exactly as 27n's
P2 predicted. **G2 PASS** — `a_NEP` is linear in the gross to **0.04 %** and its phase is invariant
to **0.000 mo** across a 3.5× range of A.

> **⇒ THE MODEL CANNOT CANCEL MORE THAN `1 − sin(27.1°)` = 54.5 % OF ITS GROSS AT ANY RESPIRATION
> AMPLITUDE. CT2022 needs 74.9 %.** The geometry, not the amplitude, is the binding constraint.

**G3 — THE STATISTIC.** At the CMIP6 gross A = 0.94: `a_NEP` = 2.5989, floor = **1.1826**, against
an observed **0.683**. **Registered prediction was ~1.19; measured 1.183, inside 1 %.**

| gross A | a_NEP | θ | floor | vs obs 0.683 |
|---|---|---|---|---|
| 0.5027 (shipped) | 1.3896 | 152.9° | **0.6320** | reachable — but 27n showed only at 1.56× bracket HI and −204 log units |
| **0.94 (CMIP6)** | 2.5989 | 152.9° | **1.1826** | **UNREACHABLE at any respiration amplitude** |

**⇒ THE TWO ERRORS DO NOT CANCEL TO A SOLUTION. Correcting error 1 makes error 2 IMPOSSIBLE** — a
bigger gross scales the floor with it, and the floor passes the observation on the way. A
(gross ↑, respiration ↑) 2×2 is a **guaranteed null** and was not pre-registered as one.

## 2. WHAT IS ACTUALLY MISSING — AND IT HAS A FITTED LEVER

**G4 — the specification.** To reach 0.683 the channels must be **θ ≥ 164.8°** apart at the CMIP6
gross (≥ 165.5° by CT2022's net/gross 0.251 route — the two agree to 0.7°). **The model has 152.9°**,
i.e. **11.9° = 0.40 months short of what is required.**

**§5b — and `seas_lag_p` reaches it.** θ is **NON-MONOTONE** in the lag, peaking at **176.1° at
`seas_lag_p` = 2.75**, while `a_NEP` stays within 1.37–1.43 across the whole axis — **it rotates the
channels without rescaling them, which is exactly a phase lever**:

| `seas_lag_p` | 1.50 | **1.77 (the mode)** | 2.00 | 2.25 | 2.50 | 2.75 | 3.00 |
|---|---|---|---|---|---|---|---|
| θ | 144.7° | **152.4°** | 160.2° | 168.1° | 176.0° | **176.1°** | 168.3° |
| floor | 0.810 | **0.644** | 0.468 | 0.283 | 0.095 | 0.094 | 0.279 |

**The needed 164.8° sits between `seas_lag_p` = 2.00 and 2.25** — and note where those values come
from: **2.25 is `seas_lag_p`'s own `init`**, and [[ccx_seas_phase_late]] records `CCX_SEAS_T_LAG`
profiling to **a clean interior optimum at the shipped 2.0**. **The fit has pulled the lag DOWN to
1.7677, and that is what closes the cancellation geometry off.**

⇒ **THE PAIR IS (GROSS ↑, LAG ↑).** Both members are now identified, both have levers, and the
target is specified in degrees. **NOT RUN, NOT PRE-REGISTERED.**

## 3. ⚠ WHAT I GOT WRONG INSIDE THIS RUN

**G5 as I pre-registered it asks whether θ MOVES; the question G4 poses is whether θ can move UP.**
A magnitude gate on a directional question. G5 sampled the two ends of `seas_lag_p`'s prior span —
**122.7° and 145.8°, both BELOW the mode's 152.9°** — from which I read "the lever runs the wrong
way". **The profile refutes that: θ is non-monotone with a maximum of 176.1° between the two sampled
points.** Two points cannot see a hump. **§5b is an ADDED MEASUREMENT, not a moved gate** — G5 is
scored above exactly as written.

⚠ Also: `q10`'s "prior span" evaluates at 3.15 and 22.1 — physically absurd values that the ±2
log-unit rule admits because the prior is that wide. It moves θ by 0.7–2.2°, so the conclusion
(`q10` is not the phase lever) is safe, but **do not quote those two rows as a q10 sensitivity.**

## 4. WHAT THIS DOES NOT LICENSE

- **Nothing is adopted.** `SEAS_NPP_AMP_SH` stays **0.5027** (`status="data"`); the CMIP6 0.94 is a
  DIAGNOSTIC value under Marcus's authorization 1 and is **not an observational constraint**.
  Every `seas_T_amp_SH` above 7.1012 and every lag off the mode is a MEASUREMENT under
  authorization 2, not a fitted value. `ccx_mode_file()` still resolves `from90`.
- **The likelihood cost of moving the lag is UNMEASURED here.** The fit chose 1.7677 against an
  init of 2.25 and a profiled optimum of 2.0, so something is paying for it — and `seas_lag_p` is
  GLOBAL, so it moves the NH too. **That cost is the first thing the next arm must price**, and it
  is why this is a pre-check and not a result.
- **It does not revisit the SIZE**, settled by [[sh_land_undercancels]] on two lines.
