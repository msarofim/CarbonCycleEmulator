# PREREG 2026-08-29c — **THE PRE-CHECK ON THE (GROSS × CANCELLATION) PAIR**
# Can the pair reach the observed SPO land 0.683 on AMPLITUDES alone, or does the
# 153° channel geometry put a FLOOR above it? Written and committed BEFORE the driver.
# **No gate below may move.**

**State when written:** `main` at `58f23ca`. Nothing running. Suite **1205 pass / 2 skip / 1 FAIL**
(`test-mode-file.R:57`, pre-existing from `b496b8a`, reported not fixed).

## 0. AUTHORIZATIONS ON THE RECORD (Marcus, 2026-08-29)

1. **A CMIP6 ENSEMBLE VALUE for `SEAS_NPP_AMP_SH` is AUTHORIZED — for a DIAGNOSTIC ARM ONLY, never
   as a shipped constant.** Same footing as the pedagogical-tool acceptance already recorded in
   [[sh_land_undercancels]]: model-derived and circular, and **it may not be called an observational
   constraint**. The shipped constant stays 0.5027 (`status="data"`).
2. **A DIAGNOSTIC ARM MAY RUN OUTSIDE A PARAMETER'S BRACKET — for MEASUREMENT, not adoption.**
   27n established the cancellation lever needs **1.56× its bracket HI** to reach the observation;
   refusing to leave the bracket makes this arm a guaranteed null that teaches nothing.
   **Nothing measured outside a bracket may be adopted, shipped, or quoted as a fitted value.**

## 1. THE CLAIM UNDER TEST — AN ARITHMETIC TENSION, NOT A HYPOTHESIS ABOUT NATURE

Two numbers already in the repo cannot both describe the same system:

- **27n MEASURED the two SH land channels at SPO as VECTORS**, `base − channel-off`:
  **NEP 1.3950 ppm @ mo 10.15** and **respiration 0.0926 @ mo 5.05** — **5.10 months = 153° apart**.
  That geometry gives a **hard floor** on the net, `min|NEP + resp| = a_NEP · sin(180° − 153°)`
  = 1.3950 · sin(27°) = **0.633 ppm**, reached at `seas_T_amp_SH` = 13.95 K and RISING after —
  a non-monotonicity 27n pre-registered as P2 and CONFIRMED (0.6181 at 13.95 K, 0.8107 at 20.0).
- **CT2022 requires net/gross = 0.251** ([[sh_land_undercancels]]): SH land cancels **74.9 %** of
  its gross swing. **But the model's geometry cannot cancel more than 1 − sin(27°) = 54.6 %**, at
  ANY respiration amplitude.

⇒ **The model's floor ratio (0.454) is 1.81× the observed ratio (0.251).** And the tension gets
WORSE, not better, under the pair's own premise: **if the gross roughly doubles to the CMIP6 A =
0.94, the floor scales with it to ≈1.19 ppm — ABOVE the observed 0.683.** The closure arithmetic
`2.61 × 0.251 = 0.655` transfers CT2022's FLUX ratio to an SPO SIGNATURE, which
[[sh_land_undercancels]] already flags as **an APPROXIMATION, not an identity**; this run tests
whether the model can realize it.

**If the floor is above 0.683, then a (gross ↑, respiration ↑) 2×2 is a GUARANTEED NULL and must not
be pre-registered as one** — the pair's second member has to be the **PHASE SEPARATION**, not the
respiration amplitude. Measuring that BEFORE writing a prereg is exactly what killed `tau_ex` fork
(a) on 27h. [[no_power_null]]

## 2. THE GATES

- **G0 — REPRODUCTION.** At the mode: NEP SH **1.3950 @ 10.15**, resp SH **0.0926 @ 5.05**, vector
  sum **1.313 @ 10.09**, SH-land knockout **1.308**. Each within **1 %** (phases within 0.05 mo).
  **FAIL ⇒ nothing below is read.**
- **G1 — THE FLOOR AT THE SHIPPED GROSS.** Separation θ and `a_NEP·sin(180°−θ)` must reproduce
  27n's **0.633** within 2 %, and the MEASURED minimum over a `seas_T_amp_SH` sweep must agree with
  the closed form within **3 %** (27n's own P1 tolerance).
- **G2 — LINEARITY AND PHASE INVARIANCE OF THE GROSS.** Over `seas_npp_amp_SH` ∈ {0.352, 0.5027,
  0.70, 0.94, 1.22}: `a_NEP` linear in A within **2 %**, and its phase drifts **≤ 0.25 mo** across
  the whole range. If the phase moves, the floor is not a simple scaling and G3 is read differently.
- **G3 — THE STATISTIC.** floor(A = 0.94) against the observed **0.683**:
  - **floor > 0.683 ⇒ AMPLITUDES ALONE CANNOT CLOSE IT.** The pair is **(gross, PHASE)**; a
    (gross, respiration) 2×2 is vetoed before it is written.
  - **floor ≤ 0.683 ⇒ reachable on amplitudes**, and the 2×2 is the next step as proposed.
  - **REGISTERED PREDICTION: floor ≈ 1.19 ppm, i.e. the first branch.** Stated so it cannot be
    reinterpreted afterwards.
- **G4 — WHAT WOULD BE NEEDED.** Report `θ_needed = 180° − arcsin(0.683 / a_NEP)` in degrees AND
  months, at both the shipped and the CMIP6 gross. This is the specification the next arm must meet,
  and it is reported whichever way G3 falls.
- **G5 — IS THERE A LEVER ON θ AT ALL?** ([[no_power_null]] again: a target with no lever is not a
  target.) Measure d(separation)/d(parameter) for `seas_lag_p` and `q10` over their sampled ranges.
  ⚠ `CCX_SEAS_PHI_EFF["SH"]` is a **compile-time constant in `src/ccx_core.cpp`**, so it is REPORTED
  as a constraint, not swept here. **If no free parameter moves θ by more than 0.1 mo, say so** —
  that makes the phase a STRUCTURAL defect, and the next step is a model change, not a fit.

## 3. WHAT NO OUTCOME LICENSES

- **No adoption of anything.** `SEAS_NPP_AMP_SH` stays 0.5027; `ccx_mode_file()` stays on `from90`.
- **It does not re-open `SEAS_NPP_AMP_SH`'s SIZE**, which [[sh_land_undercancels]] settled as
  "should go UP" on two lines; this run uses that value, it does not test it.
- **It is not the 2×2.** It decides only whether a 2×2 is worth pre-registering and in which pair.
