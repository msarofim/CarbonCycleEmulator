# COLLECT 2026-08-29 — **THE CONTROLLED `q10` TEST: THE RECOVERY FRACTION IS NOT A PROPERTY OF THE CHANNEL**
# Freeing `q10` moves it to **21.0 % / 17.0 %** — AWAY from 27j's 83.6 %, not toward it.
# ⇒ The 83.6-vs-42.9 contrast belongs to the **LEVER**, and the fraction measures **ESCAPE, not SUPPLY**.

**Prereg:** `notes/prereg_2026-08-29_controlled_q10_recovery.md` (`1f4f4ce`), amended `0e4f9b3`
BEFORE any arm result. **Driver:** `calibration/diag_q10_controlled_recovery.R` (`569776f`), run from
a frozen copy. **Output:** `outputs/diagnostics/q10_controlled_recovery.{rds,log}`. 6 arms, 29 min.

---

## 1. THE ANSWER

> The confound is resolved and it resolves the **opposite way** to my registered prediction, and to
> the way the handoff's framing implied. With the LEVER held and only the SLICE moved, the channel
> recovers **21.0 % / 17.0 %** of the land penalty against 27q's pinned **42.9 % / 43.7 %** and 27j's
> **83.6 %**. Freeing `q10` does not lift the fraction toward 83.6 — it **halves it again**.

| | land lever | `q10` | land cost | INTERACTION | **recovered** | vacancy | **per-ppm** |
|---|---|---|---|---|---|---|---|
| **27j** | `seas_npp_amp_SH`, a CONSTANT | free | 80.44 | +67.28 | **83.6 %** | 0.383 | **175.8** |
| **27q mid / hi** | `seas_T_amp_SH` PINNED | pinned | 80.42 / 162.14 | +34.47 / +70.89 | **42.9 / 43.7 %** | 0.305 / 0.449 | **113.0 / 157.9** |
| **THIS RUN mid / hi** | `seas_T_amp_SH` PINNED | **FREE** | **29.75 / 43.60** | **+6.24 / +7.41** | **21.0 / 17.0 %** | **0.081 / 0.092** | **77.3 / 80.8** |

**⇒ C4 → INTERMEDIATE.** Neither registered branch fires: not ≥ 65 % (`q10` EXPLAINS), not inside
33–54 % at both ends (`q10` does NOT explain). **My registered prediction was WRONG in magnitude**
— I predicted the fraction would hold at 33–54 %, and it fell to 17–21 %. What survives, *a
fortiori*, is the inference the "does not explain" branch was there to license: **`q10` cannot be
the reason 27j reached 83.6 %, because freeing it moves the fraction the WRONG WAY.** The contrast
belongs to the **LEVER** — the SHAPE of the vacancy — which is prereg 27q §4's alternative.

**My second registered prediction ALSO failed.** I said the per-ppm rate would be the more stable
statistic and registered the band **110–200**; it landed at **77.3 / 80.8, OUTSIDE**. It is more
stable only in relative terms — it moved **2.2×** (175.8 → 77.3) where the fraction moved **4.9×**
(83.6 → 17.0) — and it is the tighter of the two ACROSS THE BRACKET here (77.3 vs 80.8, a 1.05×
spread, against the fraction's 21.0 vs 17.0). "More stable" was right; the band was wrong.

## 2. WHAT THE FRACTION ACTUALLY MEASURES

The three slices order themselves by **how much escape the fit is allowed**, and the recovery
fraction falls monotonically along that ordering:

| slice | `seas_T_amp_NH` in the LAND arm | vs its MEASURED HIGH end (17.92 K) | recovered |
|---|---|---|---|
| 27q, `q10` PINNED | 24.5 / 25.1 K | 137 – 140 % | **42.9 / 43.7 %** |
| here, `q10` FREE | **57.5 / 75.5 K** | **321 – 421 %** | **21.0 / 17.0 %** |

**The vacancy is the mechanism.** With `q10` free the LAND arm barely imposes the defect at all —
SH-land goes 1.308 → **1.216** (hi), vacating **0.092 ppm** where the pinned arm vacates **0.449**.
There is almost nothing left for the channel to supply, so the interaction collapses from +70.89 to
+7.41 while the denominator collapses too, and the ratio falls because the numerator falls faster.

⇒ **The "recovery fraction" is not a property of the entrainment channel. It is a measure of how
much the fit was PREVENTED from escaping through the shared `q10`.** A slice that lets the fit run
the NH seasonal amplitude to 4× its observed high end is not measuring a channel; it is measuring
its own leak. This is the [[ccx_seas_q10_ridge]] escape route seen from the other side.

**The channel itself still engages, exactly as in 27q** — `ent` reaches 4.78 / 4.87 and
`sst_seas_amp_SH` recovers 0.29 → 0.65 in JOINT. The MECHANISM replicates for the third time. It is
the ARITHMETIC that is not a stable number.

## 3. GATES

- **C0 (P0) PASS.** Total 1.140, SH-land 1.308, NH-origin 0.821, ratio 1.931, all within 0.5 %.
- **C1′ REPRODUCTION — EXACT in gap form.** OCEAN **+12.57** vs 27j's +12.568; LAND_mid **−29.75**
  vs 27p's −29.755; LAND_hi **−43.60** vs 27p's −43.600. Four arms measured by three other drivers,
  reproduced to the third decimal.
- **THE OBJECTIVE SHIFT IS AN ADDITIVE CONSTANT, MEASURED AT FOUR POINTS**: absolute-form diffs
  **−0.082, −0.082, −0.080, −0.080** across arms spanning 60 log units of gap — constant to 0.002.
  That is what makes the gap form legitimate, and it is a measurement, not an assumption.
- **C2 as-registered FAILED on INCUMBENT and OCEAN_only, by −0.082 and −0.049** — i.e. by exactly
  the objective shift. **That failure is my mis-specification, not the fit's**; the amendment
  predicted it before it printed. **C2′ (gap form) PASSES** on all six.
- **C3 POWER — PASS, hard.** `ln q10` falls **59 % / 69 %** in the LAND arms while `seas_T_amp_NH`
  runs to 57.5 / 75.5 K, holding the identified product `seas_T_amp_NH · ln(q10)` to **0.4 %**. The
  ridge is ridden, so C4 is a real null and not a [[no_power_null]].
- **C5 PASS** — land cost falls 63.0 % / 73.1 %. **C6 PASS** — LAND_hi SH-land **1.216** (27p's
  1.216 exactly), confirming the defect is **not imposed**, not that it was repaired.
- **⚠ C7 AS I WROTE IT WAS MIS-SCOPED, AND I NARROWED IT ON THE COMMIT, NOT ON THE ANSWER.** I
  grepped "grad" and swept in `co2_gradient` / `d13c_gradient` — the ATMOSPHERIC station gradients,
  which option 5 does not touch. `2153bd6` and `R/likelihood.R:1541` name the rescored rows
  exactly: `ocean_grad_{dic,d13c,alk}`. Their spread across the six arms is **0.0169 ≤ 0.05, PASS**.
  The atmospheric rows do move (0.187 / 0.079) and are reported for the record.
- **P1 FALSIFIED at both ends for the third time** (+6.24 vs a 14.88 gate; +7.41 vs 21.80). P2 FAIL
  (`ent` 4.78 / 4.87, just below the 5–30 band), P3 PASS, P4 FAIL (total 1.279 / 1.285 vs obs
  1.168), P5 FAIL (ocean 0.159 / 0.146 of obs), P6 PASS, P7 PASS, P8 FAIL (SH-land 1.187 / 1.171).

## 4. WHAT THIS CLOSES, AND WHAT IT DOES NOT

**CLOSED.** Step 1 of the 08-29 handoff's ordered list. The 82-vs-42 contrast was **confounded**,
the confound has been **held**, and `q10` is **not** the explanation. The recovery fraction should
not be quoted again as a channel property; if it is quoted, it must carry its slice.

**NOT CLOSED, and untouched by this run:**
- **The SH LAND OVERSHOOT itself.** SH-land is **1.308** at the incumbent against obs 0.683 — 1.92×,
  the same 1.92× the refit left. Nothing here moved it: the only arms that reduce it do so by
  pinning a bracket value, and with `q10` free even that stops working (1.216).
- **Step 2, the NH-IMPORT channel** — 0.821 of the model's 1.373 SH land imported from the NH, the
  biggest unexplained term, still with nothing aimed at it. **This is now the next step**, and it is
  reinforced: NH_origin sits at **0.818–0.821 in all six arms**, completely inert to everything this
  design can move.
- **Step 3, the NH box's own seasonal amplitude** — still unchecked, and now more interesting: the
  leak drives `seas_T_amp_NH` to 4× its measured high end, so what the NH box does with a seasonal
  amplitude is load-bearing for the SH conclusion.
- `seas_T_amp_SH` is NOT rehabilitated; `ent_seas_amp_SH` is NOT adopted; `ccx_mode_file()` still
  resolves `from90` and no output was quarantined or repointed by this run.
