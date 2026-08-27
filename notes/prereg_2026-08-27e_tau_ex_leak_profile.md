# PRE-REGISTRATION — does `tau_ex` have ANY power over the SPO partition,
# and do the seasonal and gradient rows want it in OPPOSITE directions?

**Written 2026-08-27, BEFORE `calibration/diag_tau_ex_leak_profile.R` was written or run.**
Handoff 27d §5 item 2. The last three seasonal conclusions that were NOT pre-registered were
retracted by their own refits, so this one is.

---

## The design

A frozen 1-D profile of **`tau_ex`** over **0.7 – 4.0 yr** (fitted **1.159**), log-spaced. At each
node, TWO runs — the full model and an all-NH-channels-off twin — so the SPO leak is differenced
VECTORIALLY at every node rather than inferred from the endpoint. Reported per node:

1. the **NH-origin leak** at SPO (amplitude, peak month), against the analytic
   `gain(τ) = (1/τ)/√(ω² + 1/τ²)`;
2. the **inverted land / ocean components** at SPO, on `diag_seas_signature_inversion.R`'s
   signatures, and the **δ¹³C-per-ppm ratio** against observations;
3. **per-stream logL**, specifically the four seasonal rows against `co2_grad` / `d13c_grad` and
   the two CO2 level rows;
4. the prior term on `tau_ex` itself, so a preference is not confused with a prior.

**Frozen in the other 20 parameters, and therefore OVERSTATES every cost.** Read for SHAPE,
DIRECTION and RATIO between rows — never as a refit's Δlogpost.

**WHY THIS IS WORTH A RUN WHEN P2 BELOW IS NEARLY AN ARGUMENT.** Because "nearly an argument" is
how the last three retracted conclusions started. The measurement either exonerates `tau_ex` as a
partition lever — which frees the whole of §7c-3 to sit on the ocean phase — or it surprises me,
and either outcome is worth 2 minutes.

---

## P1 — the leak follows the two-box transfer function

The analytic gain at the mode's `tau_ex` = 1.159 predicted **0.897 ppm** undamped against
**0.821** measured, an 8 % damping by SH sinks. **PREDICT: that 8 % damping is roughly constant
across the profile** — specifically, at **τ = 2.318 (2× the fitted value)** the gain falls to
**0.0685** and the leak to **0.42 – 0.48 ppm** (analytic 0.452, less ~8 %).
**FALSIFIER: outside 0.35 – 0.55.** If the damping is strongly τ-dependent the two-box arithmetic
is not the right description of the leak and §2 of handoff 27d is weaker than stated.

## P2 — THE ONE THAT MATTERS: `tau_ex` has NO power over the partition

**PREDICT: the SPO δ¹³C-per-ppm ratio stays within ±10 % of 1.93× across the whole 0.7 – 4.0
range.** The reason is structural rather than empirical: **both** parts of the model's SPO cycle
carry the LAND signature — the leak is NH land (measured sig 0.0516) and the SH-local part is SH
land (0.0583) — so moving carbon between them cannot change the mixture's signature. Transport
relabels *where* the cycle was made, not *what made it*.

**If P2 HOLDS, `tau_ex` is EXONERATED as a partition lever** and handoff 27d §5 item 2 collapses
to "the leak is a size error, not the partition error". The SH ocean phase then carries §7c-3
alone.
**If P2 FAILS** — the ratio moves more than 10 % — then the leak and the local part are less
alike than their signatures say, and the decomposition in handoff 27d needs re-reading.

## P3 — the seasonal and gradient rows want OPPOSITE directions

The leak and the SH-local part are 108° apart, so the SPO CO2 amplitude is
`|L∠6.46 + 1.060∠10.07|`, which is **minimised at L = 0.331** and rises on both sides. At the
fitted L = 0.821 it gives 1.140 against an observed 1.168 — **the CO2 row wants slightly MORE
leak, i.e. a SHORTER `tau_ex`.**

**PREDICT: `co2_seasonal_SPO` improves as `tau_ex` falls below 1.159, and `co2_grad` degrades over
the same interval — the two rows disagree in DIRECTION at the fitted value.**
**FALSIFIER: both move the same way**, which would mean `tau_ex` is simply mis-set rather than
contested, and would be a much simpler and more actionable finding than the one I expect.

⚠ **`co2_grad` carries a FITTED offset (`grad_off_co2`), so it prices the gradient's SLOPE far
more than its LEVEL.** Frozen, that offset cannot re-absorb, so P3's gradient half is an
UPPER bound on the disagreement. Named here so the caveat is not discovered afterwards.

---

## What is NOT claimed

- **No refit, no posterior.** Frozen profile at the canonical mode with full forcing.
- **No threshold from the model's own agreement.** P1 is against a closed-form transfer function,
  P2 is a ±10 % INVARIANCE band on a ratio, P3 is a DIRECTION. [[threshold_from_obs_or_law]].
- **`ccx_hold_climate()` is not used.**
