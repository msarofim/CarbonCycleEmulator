# COLLECT 2026-08-29h — **DIFFUSE LIGHT IS CHEAP (−7.4) AND THE CORRELATION GAIN IS REAL**
# ⚠ But the price is paid by **`fert_k` +29 %**, the one parameter with an EXTERNAL constraint —
# and my "level offset" mechanism was **REFUTED by the gate I wrote to catch exactly that**.

**Prereg:** `notes/prereg_2026-08-29h_price_gamma_diff.md`. **Driver:** `calibration/diag_price_gamma_diff.R`.
**Output:** `outputs/diagnostics/price_gamma_diff.{rds,log}`.

---

## 1. THE PRICE — THE FROZEN COST WAS AN 82 % OVERSTATEMENT

| `gamma_diff` | frozen | **conditional** | buy-back | 1992 | **r** | land sink |
|---|---|---|---|---|---|---|
| 0 | 0 | 0 | — | +0.043 | 0.571 | 3.558 |
| 0.125 | — | **−1.96** | — | −0.211 | 0.606 | 3.564 |
| **0.25** | −40.5 | **−7.42** | **82 %** | −0.464 | **0.624** | 3.570 |
| 0.50 | −160.8 | −28.72 | 82 % | −0.969 | **0.626** | 3.584 |
| 0.75 | −360.4 | −63.67 | 82 % | −1.470 | 0.602 | 3.600 |
| 0.97 | −601.3 | −105.54 | 82 % | **−1.910** | 0.575 | 3.615 |

- **H0 PASS** (γ = 0 returns exactly 0.0000).
- **H1 → CHEAP.** −7.42 at γ = 0.25, against pre-registered bands CHEAP ≤ 20 / MODERATE ≤ 100.
- **H4 PASS — and this is the one that matters.** **r rises 0.571 → 0.626 and SURVIVES REFITTING.**
  The gain was not borrowed from the frozen parameters; the mechanism supplies real signal.
  ⚠ Contrast [[ccx_variability_gap]]: ENSO's r was FLAT across an 11× amplitude range.
- **H5 PASS.** Land sink moves ≤ 0.057 GtC/yr — no secular bias; 2015–2023 is volcanically quiet.

**⇒ the frozen cost overstated the price by 82 % at every γ**, which is the handoff-08-25b §7 lesson
landing again: *never read a frozen conditional optimum as a price.*

## 2. ⚠ H3 REFUTED MY MECHANISM — AND THAT IS THE GATE WORKING

08-29g §4 proposed, untested, that the frozen cost was a **cumulative CO₂ level offset**. I put
`rep_dC` (a ~6 ppm CO₂ level bias) in the slice specifically so the story could be refuted, and
added **H3 as a separate MECHANISM gate** with the note *"this is the gate that stops H2 being read
as a mechanism when it is only an arithmetic."*

**H2 passed on the number (82 % ≥ 40 %). H3 FAILED: `rep_dC` moved −0.01 prior-sd.**
⇒ **the level-offset story is REFUTED, and H2's printed verdict "LEVEL OFFSET CONFIRMED" is WRONG.**

**THE ACTUAL ABSORBER IS THE FERTILISATION PAIR**, moving along its ρ = +0.998 ridge:

    gamma_diff 0 -> 0.97 :  fert_k +28.90 %   beta_max +11.59 %   q10 +0.04 %   rep_dC -1.14 %

Adding episodic volcanic uptake is compensated by **re-tuning the SECULAR fertilisation**, not by
shifting the level.

## 3. ⚠ SO "CHEAP" NEEDS A CAVEAT, AND IT IS NOT A SMALL ONE

**`fert_k` is the one parameter in that slice carrying an EXTERNAL constraint.**
[[ccx_face_fert_k_ceiling]]: *"FACE caps `fert_k`, it cannot prior `beta_max`"* — both priors are
UNIFORM and the pair is ρ = +0.998, so **FACE is the only thing bounding this direction**, and it
informs *"SHAPE and REALISTIC LIMITS"* ([[face_ceiling_is_the_headline_in_disguise]]).

⇒ **The −7.42 is cheap in LOGPOST and is bought by a +29 % move in the very parameter whose realistic
range is set outside the likelihood. "Cheap in logpost" is not "cheap in provenance."**
**NOT YET CHECKED, and it is the next thing to check before any adoption:** does
`fert_k` = 199.58 (γ = 0.97) — or 164.23 (γ = 0.25) — still sit inside the FACE-informed range?

## 4. WHO PAYS — AND IT IS NOT THE INSTRUMENTAL RECORD

At γ = 0.25, conditional, each row minus γ = 0:

    co2_icecore        -4.53      <- the LARGEST payer
    co2_level_MLO      -1.63
    co2_level_SPO      -1.57
    gcb_land_sink      -1.05
    co2_seasonal_MLO   +1.13      <- IMPROVES

**The cost is concentrated in the PRE-INSTRUMENTAL era.** The AOD series' largest event is
**Krakatau 1884 (global AOD 0.110, marginally bigger than Pinatubo's 0.107)**, and the 1850–1958
period is constrained by 255 smoothed ice-core points that do not show volcanic wiggles.
⇒ **the amplitude is being constrained by Krakatau against ice cores more than by Pinatubo against
MLO** — worth knowing, because it is not the comparison anyone would assume.

## 5. THE THREE OPTIMA STILL DISAGREE, NOW WITH PRICES

| target | γ | price | r |
|---|---|---|---|
| cheapest useful | **0.25** | **−7.4** | 0.624 |
| max correlation | 0.50 | −28.7 | **0.626** |
| match Pinatubo | 0.97 | **−105.5** | 0.575 (WORSE than γ = 0.25) |

**Matching the Pinatubo feature costs 14× more than γ = 0.25 and fits the record WORSE.** Third time
today that "reproduce a feature" and "fit the record" have pulled apart.

## 6. RECOMMENDATION

**γ ≈ 0.25 is the defensible operating point** — 84 % of the available correlation gain at 7 % of the
Pinatubo-matching cost. **But do NOT adopt until §3's FACE check is done**, and note that adoption
means making `gamma_diff` the 22nd FITTED parameter, which is a full refit and a separate decision.
Nothing is adopted; `gamma_diff` stays 0.
