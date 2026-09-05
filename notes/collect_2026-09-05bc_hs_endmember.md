# COLLECT — 2026-09-05b/c. **THE HS ENDMEMBER IS SETTLED, AND IT IS NOT THE LEVER.**
# ⛔ **THICKNESS IS NOT A TERM AT ALL — collect_2026-09-05 §2 IS HALF RETRACTED.**
# ⭐⭐ **AT HILDA'S OWN GAS EXCHANGE WE GET HILDA'S OWN HS (−107.5 vs −111).**
# ⛔⛔ **AND IT BUYS 0.025 OF mean|z|, WHILE AN OBSERVATION EXCLUDES THE ARM.**

Scores `notes/prereg_2026-09-05b_hs_thickness.md` and
`notes/prereg_2026-09-05c_hs_gas_exchange.md`.
`calibration/diag_hilda_hs_thickness.R`, `calibration/diag_hilda_hs_gasexchange.R`.
**Nothing fitted, nothing adopted.**

---

## 1. ⛔ RETRACTION: THE THICKNESS TERM DOES NOT EXIST

`collect_2026-09-05_hilda_boxes.md` §2 explained HS's −80.3 ‰ (against HILDA's −111) with **two**
terms — gas exchange **1.97×** and thickness **1.79×** — and said "both push the same way".

| HS thickness | residence `h/u` | HS Δ¹⁴C | HD Δ¹⁴C | LS ML | scored mean \|z\| |
|---|---|---|---|---|---|
| 134.1 m (= `h_ml`) | 3.53 yr | **−80.3** | −109.2 | −29.8 | 2.05 |
| 100 m | 2.63 yr | −80.2 | −109.2 | −29.8 | 2.05 |
| **75 m (HILDA's)** | 1.97 yr | **−80.1** | −109.2 | −29.8 | 2.05 |
| 50 m | 1.32 yr | −80.1 | −109.2 | −29.8 | 2.05 |

**0.2 ‰ across a 2.7× change**, and the crossover does not move by one layer. **P1b and P2b's HD
clause are FALSIFIED.**

⭐⭐ **AND IT IS ANALYTIC — IT SHOULD HAVE BEEN DERIVED, NOT PREDICTED.** In steady state HS's
isotope ratio is a balance of rates **per unit volume**, and both carry the same `1/h_hs`: the
HS↔HD limbs go as `u / h_hs`, air-sea equilibration as `gx / (A · h_hs)`. **The ratio is
independent of `h_hs`.** Thickness sets the box's INVENTORY — how fast it *reaches* steady state —
not what the steady state IS. §2 treated residence (h/u) and equilibration (∝ h/`k_w`) as
independently movable when both are linear in h and the h cancels exactly.
⇒ ⭐ **STANDING RULE: A RATIO OF TWO TIMESCALES THAT SHARE A FACTOR IS NOT A LEVER. Cancel the
algebra before pricing the mechanism.**

## 2. ⛔ A SECOND RETRACTION — MY OWN GATE SCORED A NO-CHANGE AS A PASS

`diag_hilda_hs_thickness.R` printed **"P4b — mean|z| below the 09-05 build's 2.05? 2.05 →
CONFIRMED"**. It compared a live value against a constant **rounded to 2 dp out of the previous
run's printout**, and a fourth-decimal difference cleared it. **The arm changed nothing and the gate
said it passed.** Now fixed: the baseline arm is recomputed in the same run and gated on a DELTA
against an explicit materiality tolerance (`HT_MEANZ_TOL` = 0.02).
⇒ **NEVER GATE ON A THRESHOLD TYPED FROM ANOTHER RUN'S ROUNDED OUTPUT** — this is
[[derived_must_mean_computed]] in a new costume, and it is a member of the SILENT-GATE family.

## 3. ⭐⭐ THE GAS EXCHANGE IS THE WHOLE OF IT — P1c, P2c, P4c ALL CONFIRMED

`k_w` is DERIVED in the script, not typed: HILDA's Table 1 gives **15.1 ± 1.2 mol m⁻² yr⁻¹ at
280 ppm**, ours at `ent26` gives **29.80** at the same pCO₂ and 2 °C, so their gas exchange is
**`k_w` = 906 m/yr**. Iso-deep, everything else at HILDA's values:

| arm | `k_w` | flux | `kz` | HS Δ¹⁴C | HD Δ¹⁴C | scored mean \|z\| | LS ML |
|---|---|---|---|---|---|---|---|
| `ent26` | 1788 | 29.80 | **1900** | −80.3 | −109.2 | **2.048** | −29.8 ✅ |
| **HILDA** | **906** | **15.10** | **5334** | **−107.5** | **−126.7** | **2.023** | **−78.5 ⛔** |
| half HILDA | 453 | 7.55 | — | — | — | — | **no `kz` holds the deep age** |

- ✅ **P1c: HS = −107.5 against HILDA's own −111**, and inside their −120 ± 30. **The endmember
  question is settled** — one term, and it is the gas exchange.
- ✅ **P2c: HD −126.7, and the crossover moves 1160 → 1622 m.** A colder-in-¹⁴C HS really does feed
  an older HD and really does push `q`'s sign flip deeper.
- ✅ **P4c: mean|z| 2.048 → 2.023.** Confirmed — **and the delta is 0.025.**

## 4. ⛔⛔ WHY THAT IS A NEGATIVE RESULT, AND WHAT IT NAMES

**Both halves of the price show up in the same table.**

1. **`kz` GOES BACK UP: 1900 → 5334.** A weaker air-sea exchange slows the ocean's ¹⁴C uptake, so
   holding the deep age needs the diffusivity back. **Almost the entire `kz` relief — the thing P2
   and P3 won — is spent buying the endmember.** The two cannot be had at once.
2. ⛔ **AND AN OBSERVATION EXCLUDES THE ARM.** GEOSECS puts the low-latitude surface at
   **−40 ± 20 ‰** (HILDA Table 2) and nothing in our likelihood scores it. At `k_w` = 906 the LS
   mixed layer reads **−78.5**, nearly **2σ outside**. ⚠ **`k_w` is GLOBAL here**, so this arm
   lowers the low-latitude gas exchange too — and HILDA themselves assume `g_l = g_h`, so giving HS
   its own `k_w` would be a departure from the source, not an application of it.

⭐ **AND THE EXCLUSION IS ITSELF A FINDING: `k_w` AND `kz` ARE COUPLED THROUGH AN UNSCORED
OBSERVABLE.** LS surface Δ¹⁴C runs −29.8 at (`k_w` 1788, `kz` 1900) and −78.5 at (906, 5334). The
model needs a HIGH `k_w` to keep its surface young **because** its `kz` mixes so much old water up —
the same "one scalar, two jobs" pattern this arc keeps finding, and **GEOSECS's −40 ± 20 is a
candidate gate on the pair that the likelihood currently does not score.**

## 5. ⇒ WHAT IS NOW SETTLED, AND THE ONE CANDIDATE LEFT

| question | status |
|---|---|
| does an HS box under-equilibrate on its own? | ✅ **YES**, and at HILDA's gas exchange it reproduces HILDA's value |
| is HS's thickness a lever? | ⛔ **NO — analytically not a term** |
| is HS's endmember the lever on the scored band? | ⛔ **NO.** 0.025 of mean\|z\|, and it costs the whole `kz` relief |
| is `q`'s ATTACHMENT DEPTH the lever? | ⚠ **UNTESTED, and now the only candidate the diagnosis names** |

The arc's own mechanism result stands and has survived two attempts to route around it: **`q`
injects HD water into layers that are already too young, and the reduced form beat the structure
precisely because ML↔bottom-only paid none of that penalty.** Thickness cannot move the crossover;
the endmember can, but only by surrendering the `kz` relief and breaking an observation.

⇒ **THE NEXT TEST IS THE ATTACHMENT DEPTH OF `q`, AND IT IS A DEPARTURE FROM HILDA'S FIG. 1** — in
HILDA `q` exchanges with the Interior as a reservoir, *"assumed independent of depth"*. Attaching it
to the lower interior only would make the structure a boxed version of the 09-04k2 geometry that
scored 1.81. **That is a decision about departing from the published model, not a measurement**, and
it is flagged here rather than taken.
