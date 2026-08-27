# PRE-REGISTRATION — §7c-3, opening move: WHO GENERATES THE MODEL'S SH SEASONAL
# CYCLE, and does any scored row have POWER over the SH partition?

**Written 2026-08-27, BEFORE either script was run.** Against
`notes/handoff_2026-08-27c_suite_green_partition_next.md` §3–§4, which set the constraint this
design has to satisfy: *the CO2 seasonal rows have NO POWER to reject the seasonal partition —
they are ALREADY matched at the mode, so a partition test scored on the CO2 amplitude is
structurally guaranteed to return null* ([[no_power_null]]).

**This is NOT yet the SH land box.** Building a box is a structural change; §3 says to measure
the test's power first, and §4's third bullet warns that a frozen 1-D scan will overstate the
cost of any SH amplitude because `seas_T_amp`×`q10` sit on an exact ridge ([[ccx_seas_q10_ridge]])
and `beta_max`/`fert_k` absorb 85 % of a frozen cost. So the deliverable here is **two
measurements and a verdict on which observable to score a box on** — not a box.

---

## The two measurements

**A. CROSS-HEMISPHERE CHANNEL DECOMPOSITION** — extends `calibration/diag_seas_channel_decomp.R`,
which already switches each of the six per-hemisphere seasonal channels off exactly and
differences them VECTORIALLY. Three cases added: all-3-NH-off, all-3-SH-off, SH-LAND-only-off
(`seas_npp_amp_SH` + `seas_T_amp_SH`). The difference `base − (NH off)` read AT SPO is the
**NH-origin** part of the model's SH cycle; `base − (SH off)` is the **SH-local** part.
Emission seasonality is a global forcing flag and cannot be split by hemisphere — the existing
`emissions off` row sizes what that leaves in the residual.

**B. THE ISO-CO2 PARTITION SLICE.** A frozen 1-D scan of `seas_T_amp_SH` is the wrong instrument
for the reason §4 gives *and* for a second one: it moves the SPO CO2 amplitude, so the CO2 rows
would price it and the isotope rows' verdict would be buried under a CO2 objection. Instead scan
the SH LAND amplitude and, at each node, **re-tune `sst_seas_amp_SH` to hold the model's SPO CO2
peak-to-peak at its base value** — an ISO-OBSERVABLE slice ([[match_incumbents_optim]]). Along
that slice the CO2 amplitude is fixed BY CONSTRUCTION, so whatever the rows still say is a
statement about the PARTITION and nothing else. Report per-stream Δ logL and both drivers' prior z.

---

## P1 — the model's SH seasonal CO2 cycle is NOT predominantly SH-local

**Predicted: the NH-origin contribution at SPO is ≥ 30 % of the base SPO peak-to-peak.**
Point estimate ~40–70 %.

Analytic basis, two well-mixed atmospheric boxes exchanging at `tau_ex` = 1.3 yr with a seasonal
source in NH only. With `u = C_N − C_S`, `v = C_N + C_S`: `u = A/(iω + 2/τ)`, `v = A/(iω)`, so

    C_S / C_N = (1/τ) / (iω + 1/τ)
    |C_S/C_N| = (1/1.3) / sqrt((2π)² + (1/1.3)²) = 0.7692 / 6.3301 = 0.1215
    lag = atan(ωτ) = atan(8.168) = 83.0° = 2.77 months

At the mode's `co2_NH` peak-to-peak of **6.36 ppm** that is **0.773 ppm** arriving in the SH —
**71 % of the model's 1.09 ppm SPO cycle**, before any SH sink damps it. The 30 % floor is set
well below the point estimate precisely because that damping is not in the arithmetic.

**If P1 FAILS** (NH-origin < 30 %) the leakage account is wrong, the SH cycle really is SH-made,
and §3's "no power" finding needs a different explanation than the one I am about to build on.

## P2 — the leak arrives in the WRONG SEASON, so the local part must be larger than the total

**Predicted: the NH-origin component at SPO peaks ≥ 2 months before the base SPO cycle does.**

The mode's `co2_NH` sits at +19.14 ppm/yr on 1 Jan against a maximum slope of 2π·(6.36/2) =
19.98 — 96 % of it — so the NH box peaks ≈ early April. Add the 2.77-month lag: the leak peaks
≈ early July. The SH box sits at −3.37 ppm/yr on 1 Jan against a maximum of 2π·(1.09/2) = 3.42
— 98.5 % — so SPO peaks ≈ early October. **≈ 3 months apart.**

**The consequence, and it is the interesting one:** two components ~90° apart cannot sum to a
resultant lying along one of them. If P1 and P2 both hold, the SH-LOCAL contribution must be
**LARGER in magnitude than the 1.09 ppm total** — it has to cancel a July-peaking 0.77 ppm leak
AND supply an October-peaking residual. **Predicted |SH-local| > 1.09 ppm, i.e. > 100 % of the
observable it produces.** That is a compensation of exactly the kind [[ccx_seas_partition]]
describes, and it would be the first time it is visible in the CO2 channel itself.

**If P2 FAILS** — the leak arrives roughly in phase — then the SH drivers being 4.9× and 3.5×
below observed is simply "the leak already does the job", a much duller finding, and the SH land
box loses most of its motivation.

## P3 — `co2_seasonal_SPO` has no power on the iso-CO2 slice; `d13c_seasonal_SPO` does

**Predicted, over a slice spanning `seas_T_amp_SH` from its fitted 1.039 up to its observed
bracket low end 3.59 (a 3.5× move):**

- `|Δ logL(co2_seasonal_SPO)|` **< 10 log-units** — near-zero by construction, and its residual
  is the measurement of how well the iso-CO2 re-tune actually holds.
- `|Δ logL(d13c_seasonal_SPO)|` **> 50 log-units**, i.e. **> 5× the CO2 row's**. The d13C rows
  carry 72 % of the ocean-amplitude veto ([[ccx_sst_seas_veto]]) and 62 of the 100 % of the
  landed-gap bias ([[ridge_veto_is_a_bias]]), so they are where a partition change has to show.

**This is the pre-registered POWER STATEMENT and it is the deliverable.** A ratio, not a level:
if it holds, §7c-3's box gets scored on `d13c_seasonal_SPO` and the CO2 rows are reported as
uninformative rather than as agreement.

## P4 — the direction: the isotope row will want MORE SH land, not less

**Predicted: `d13c_seasonal_SPO` improves monotonically as `seas_T_amp_SH` rises toward its
observed bracket, over at least the first half of the slice.**

This is the risky one and it is the one worth being wrong about. It follows from taking
[[seas_amps_hemispheric_inversion]] at face value — the fit pushed SH land to 29 % of its
bracket's low end, and if the isotope row on an iso-CO2 slice *also* wants it there, then the low
amplitude is a real model statement and the driver-bracket flags are the thing to explain, not
the structure. **P4 failing is a RESULT, not a null:** it would say the CO2 rows alone are what
reject the observed SH drivers, and the structural case for the box gets stronger, not weaker.

---

## What is NOT claimed, and the traps carried in

- **No threshold is derived from the model's own agreement.** P1/P2 come from the two-box
  transfer function and the mode's own reported harmonics; P3 is a RATIO between two rows;
  P4 is an ORDERING. [[threshold_from_obs_or_law]].
- **`ccx_hold_climate()` is NOT used** anywhere here. Its incomplete-control gap (handoff 27c §2)
  is still unaudited, and every case below switches parameters, not the climate harness.
- **Every case is run at the CANONICAL MODE with full forcing**, never at defaults — at defaults
  the SH January tendency is sign-inverted ([[seas_right_observable_wrong_drivers]]).
- **The slice is FROZEN in the other 19 parameters** and therefore OVERSTATES cost, per §4's
  third bullet. It is read for SHAPE and RATIO between rows, never as a refit's Δlogpost.
- The `SST_SEAS_LOGSD` = 0.25 caveat stands: `sst_seas_amp_SH`'s prior z is partly a statement
  about a judgement width, so the RATIO to the observed 1.746 is the robust half.
