# PREREG 2026-08-29d — **PRICE `seas_lag_p`**
# What does the phase lever COST, who pays, and does it BUY anything on its own?
# Written and committed BEFORE the driver. **No gate below may move.**

**State when written:** `main` at `011f79e`, clean, suite **1210 / 2 skip / 0 fail**.
Nothing running; load 2.65 (the Julia workers finished).

## 0. WHY THIS RUNS BEFORE THE 2×2

29c identified the pair as **(gross ↑, `seas_lag_p` ↑)**: θ must reach **164.8°** and the lag is the
only free parameter that gets there (peak 176.1° at lag 2.75), against a mode at **1.7677 → 152.4°**.
**But `seas_lag_p` is GLOBAL — it moves the NH too — and the fit chose 1.7677 against its own `init`
of 2.25 and a profiled optimum of 2.0** ([[ccx_seas_phase_late]]). Something is paying for that, and
if the bill is 27n-sized (−204) the pair is dead before the 2×2 is written.

⚠ **AND THE LAG BUYS NOTHING BY ITSELF, WHICH IS THE POINT.** At the mode the respiration channel is
**0.0923 ppm against NEP's 1.3896**, so rotating the two relative to each other moves the SUM by at
most ~0.09. **The floor is what moves; the NET does not.** The lag OPENS the door; respiration walks
through it; the gross sets the scale. A driver that reported only the net would call the lag useless.

## 1. THE DESIGN

**Frozen profile** over `seas_lag_p` ∈ {1.50, 1.7677, 1.90, 2.00, 2.10, 2.25, 2.40, 2.50, 2.75},
everything else at the mode: logpost, by-stream decomposition, θ, SH-land net, SPO total, and the
SPO d13C-per-ppm ratio.

**Conditional arms** at lag ∈ {1.7677 = INCUMBENT, 2.00, 2.25, 2.50}, re-optimising

    SLICE = c("sst_seas_amp_NH", "sst_seas_amp_SH", "seas_T_amp_NH", "seas_T_amp_SH")

with **`q10` PINNED at the mode** (27p's repair — free `q10` leaks 64 % of any SH lever and runs
`seas_T_amp_NH` to 4× its high end, [[q10_recovery_is_escape]]) and `seas_lag_p` PINNED at the grid
value. **`seas_T_amp_SH` is FREE**: the arm is allowed to buy the geometry if it wants it.

⚠ **Frozen costs are UPPER BOUNDS and this repo has been burned by reading them as predictions** —
"the refit recovered 15-19× more than the frozen scan predicted" (handoff 08-25b §7). The
conditional is the load-bearing measurement; the frozen profile is shape, not price.

**Secondary block, DIAGNOSTIC-ONLY** (Marcus's authorisation 1, 2026-08-29): the same conditional
arms at the **CMIP6 gross `seas_npp_amp_SH` = 0.94**. That is the configuration in which the target
is actually reachable, and it is labelled as diagnostic everywhere it appears. The shipped constant
stays **0.5027**.

## 2. THE GATES

- **Q0 — METHOD CONTROL.** At the mode: SPO total **1.140**, SH-land **1.308**, NEP **1.3896 @
  10.15**, resp **0.0923 @ 5.05**, θ **152.9°**, r_SPO **1.93**, each within 1 % (phases 0.05 mo).
  **FAIL ⇒ nothing below is read.**
- **Q1 — WHO PAYS.** The NH rows (`co2_seasonal_MLO` + `d13c_seasonal_MLO`) carry **≥ 50 %** of the
  FROZEN cost at lag 2.25. **PREDICTED: they do** — the lever is global and the NH cycle is the one
  the model already fits well.
- **Q2 — THE LAG BUYS NOTHING ALONE.** Frozen SH-land net at lag 2.25 stays within **5 %** of 1.308,
  while the FLOOR falls to ~0.28. **PREDICTED: it does** — pre-registered so that "the net did not
  move" is read as *confirmation*, not as the lever failing.
- **Q3 — DOES THE FIT WANT THE GEOMETRY?** Conditionally at lag 2.25, does `seas_T_amp_SH` rise?
  **PREDICTED: NO — it stays below 2× the mode's 1.0391**, because the CO2 seasonal rows are matched
  by cancellation and have NO POWER to ask for the partition fix ([[seas_right_observable_wrong_drivers]]).
  If it DOES rise, that is a much stronger result than anything this run was designed to find.
- **Q4 — THE PRICE.** Conditional cost at lag 2.25, on the SHIPPED gross. Bands fixed here:
  **CHEAP ≤ 20 log units | MODERATE 20–100 | PROHIBITIVE > 100** (27n's cancellation lever cost
  −204.45 frozen / −35.11 conditional; that is the scale). **PREDICTED: MODERATE, −20 to −60.**
- **Q5 — THE PARTITION OBSERVABLE.** r_SPO (SPO d13C-per-ppm, 1.93 at the mode, 1.00 = observed)
  improves by **≤ 5 %** without a respiration move. **PREDICTED: yes, ≤ 5 %** — the same no-power
  argument. r_SPO is the row that *would* have power ([[ccx_seas_partition]]), so it is reported at
  every arm whichever way it goes.
- **Q6 — BUY-BACK.** Report conditional ÷ frozen at each lag. No gate: this repo has no stable prior
  for it (27h ~30 %, 27n 84 %), and inventing one would be a number pulled from nothing.

## 3. WHAT NO OUTCOME LICENSES

- **No adoption.** `seas_lag_p` stays at the mode; `SEAS_NPP_AMP_SH` stays 0.5027; `ccx_mode_file()`
  stays on `from90`. The CMIP6 block is diagnostic and may not be quoted as a fitted configuration.
- **It is not the 2×2**, and it cannot confirm the pair — only price one member and say whether the
  2×2 is worth writing.
- **It does not revisit θ's target** (164.8°, measured 29c) or the SIZE ([[sh_land_undercancels]]).
