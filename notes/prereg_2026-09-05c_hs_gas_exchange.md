# PRE-REGISTRATION — HS's depletion is set by **`k_w` ALONE**, not by thickness.
# Written 2026-09-05c, AFTER the thickness test ran and BEFORE the gas-exchange
# test was written. States a RETRACTION first, then the prediction it implies.

## 0. ⛔ RETRACTION: `notes/collect_2026-09-05_hilda_boxes.md` §2 IS HALF WRONG

That section explained HS's −80.3 ‰ (against HILDA's −111) with **two** terms — a **1.97×** gas
exchange and a **1.79×** thickness — and said "both push the same way".

**MEASURED, and the thickness term does not exist.** `calibration/diag_hilda_hs_thickness.R`, at
HILDA's own `u` and `τ_q`, iso-deep:

| HS thickness | residence `h/u` | HS Δ¹⁴C | HD Δ¹⁴C | LS ML | scored mean \|z\| |
|---|---|---|---|---|---|
| 134.1 m (= `h_ml`) | 3.53 yr | **−80.3** | −109.2 | −29.8 | 2.05 |
| 100 m | 2.63 yr | −80.2 | −109.2 | −29.8 | 2.05 |
| **75 m (HILDA's)** | 1.97 yr | **−80.1** | −109.2 | −29.8 | 2.05 |
| 50 m | 1.32 yr | −80.1 | −109.2 | −29.8 | 2.05 |

**0.2 ‰ across a 2.7× change in thickness.** P1b (HS below −95) and P2b's HD clause are
**FALSIFIED**; the crossover does not move either.

⭐⭐ **AND IT IS ANALYTIC, WHICH IS WHY IT SHOULD HAVE BEEN DERIVED, NOT PREDICTED.** In steady
state HS's isotope ratio is set by a balance of **rates per unit volume**, and BOTH of them carry the
same `1/h_hs`:

* supply from HD and loss to HD go as `u / h_hs`
* air-sea equilibration goes as `gx / (A · h_hs)`

**The ratio is independent of `h_hs`.** Thickness sets the box's INVENTORY, hence how fast it
*reaches* steady state — not what the steady state IS. The collect note treated "residence" (h/u)
and "equilibration time" (∝ h/k_w) as independently movable when both are linear in h and the h
cancels exactly. ⇒ **The 1.79 was never a term. Only the 1.97 is.**

⇒ **STANDING RULE THIS EARNS: a ratio of two timescales that share a factor is not a lever. Cancel
the algebra before pricing the mechanism.**

## 1. ⛔ A SECOND, SMALLER RETRACTION — MY OWN SCRIPT SCORED A NO-CHANGE AS A PASS

`diag_hilda_hs_thickness.R` printed **"P4b -- mean|z| below the 09-05 build's 2.05? 2.05 ->
CONFIRMED"**. It compared a live value against a **constant rounded to 2 dp from the previous run's
printout**, and a difference in the fourth decimal cleared it. **The arm changed nothing and the
gate said it passed.** Fixed: the script now recomputes the baseline arm in the same run and reports
the DELTA against a tolerance. ⇒ **Never gate on a threshold typed from another run's rounded
output** — this is `derived_must_mean_computed` in a new costume.

## 2. THE PREDICTION

If the gas exchange is the ONLY term, it is quantitative and there is nothing left to hide behind.
HILDA's Table 1 gives **15.1 ± 1.2 mol m⁻² yr⁻¹ at 280 ppm**; ours at `ent26` is **29.80**, so their
gas exchange corresponds to

  **`k_w` = 1787.8 × 15.1 / 29.80 = 906 m/yr.**

### P1c — THE ENDMEMBER, at HILDA's gas exchange
**PREDICT: with `k_w` = 906 and everything else at HILDA's values, HS lands within 15 ‰ of their
−111 ‰**, i.e. in **[−126, −96]** — and therefore inside their −120 ± 30 as well.
**FALSIFIER: HS stays above −96** ⇒ the gas exchange is not the remaining term either, and the
difference is in something not yet identified (alkalinity, salinity, the 16 % allocation, or the
buffer chemistry at 2 °C).

### P2c — DOES IT MOVE THE CROSSOVER, WHICH IS WHAT P4 ACTUALLY NEEDS?
**PREDICT: HD falls below −125 ‰ and the HD-minus-interior crossover moves DEEPER than 1160 m.**
**FALSIFIER: the crossover stays at 1160 m** ⇒ the `q` sign problem is structural in the attachment
of `q` and NOT reachable through HS's endmember at all, however depleted HS becomes. **That would
make the attachment depth the only remaining candidate**, and it is a departure from HILDA's Fig. 1.

### P4c — the scored band
**PREDICT: mean |z| falls below the 09-05 build's value by more than 0.02** (a tolerance, not a
rounded constant — see §1). ⚠ **Beating the reduced form's 1.81 is NOT predicted.**

## 3. ⚠ WHAT THIS IS NOT

**`k_w` = 906 IS A DIAGNOSTIC PROBE, NOT A PROPOSAL.** `k_w` = 1787.8 is a FITTED parameter of the
low-latitude column, carrying the bomb-¹⁴C uptake and the air-sea disequilibrium the likelihood
scores. Nothing here proposes moving it, and the arm is reported as "what HILDA's gas exchange would
give", never as an alternative model. **If HS needs a different gas exchange from the LS box, that
is a claim about HIGH-LATITUDE gas exchange — and HILDA explicitly assumes the opposite
(`g_l = g_h`, their Table 1), so it would be a departure from the source and must be labelled.**
