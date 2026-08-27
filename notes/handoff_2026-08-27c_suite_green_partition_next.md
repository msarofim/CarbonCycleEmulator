# Handoff — CarbonCycleEmulator, 2026-08-27c: THE SUITE IS GREEN, and the CO2 seasonal
# rows have NO POWER to test the partition

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, clean.
**Nothing is running.** **Suite: 1122 pass / 0 fail** (from 2 failing at `5777955`).

**Supersedes** `notes/handoff_2026-08-27b_quality_phase_7a7b_done.md` for its decisions 6a and 6b,
both now ANSWERED. Its §1–§5 (the mode repointing, DESIGN §6, the rank-one d13C identity, the
seasonal-amplitude flags, the non-obvious state) all still stand and are NOT repeated here.
Detail: `notes/collect_2026-08-27_post_fix_model_quality.md`, CHANGELOG 2026-08-27 / b / c.
Commits `aa1c5e1`, `2779463`, `b5d482d`, `6377b91`, `f48526b`, `e816700`, + this one.

---

## 0. STATE IN SIX LINES

1. **§7a, §7b, §7c-1, §7c-2 DONE** (handoff 27b). **Decisions 6a and 6b now ANSWERED.**
2. **6a:** gate 7's window is **2015–2023**, both sides, both reconstructions agreeing to 1e-4.
   The cause was **half a month**, not a missing year. §1
3. **6b:** `test-fluxes.R` is green. Line 99 repaired by **completing its control**; line 100's
   magnitude gate **WITHDRAWN**. §2
4. **NEW STANDING RULE (Marcus): a threshold must come from an OBSERVATION or a PHYSICAL LAW.** §2
5. **THE FINDING THAT SHOULD SHAPE THE NEXT STEP: the CO2 seasonal rows have NO POWER to reject
   the seasonal partition — they are already matched at the mode.** §3
6. **⇒ §7c-3 (the SH land box) is the next step, and §3 constrains how to pose it.** §4

---

## 1. Decision 6a — ANSWERED: gate 7 is scored on 2015–2023

Both reconstructions now agree to **1e-4**. `from90` land **3.558 (+2.30σ)**, ocean **2.970
(−0.58σ)**; defaults 3.51 / +2.21 and 2.63 / −1.43; `pin90` 3.85 / +2.87 and 3.02 / −0.46.
Verdict unchanged (FAIL land, PASS ocean) — the change was worth 0.02σ.

**The diagnosis narrowed on measurement and my first framing was wrong.** The run ends at
t = 2024.958, so the 2025 boundary is **0.0417 yr — half a month — past the last state**, not a
missing year. What makes half a month worth **0.65 GtC/yr** is that it falls where the land
stock's slope is most negative (NH December respiration). Fixed two ways: the window drops 2024,
AND `diag_design_gates_at_mode.R` now extrapolates the ends LINEARLY to match
`R/likelihood.R:1422-1428`'s stated convention — it was the one file out of line, and dropping the
year alone would only have hidden today's instance. Observed means are recomputed on the same
window (2.410 / 3.202), with an assertion that GCB's published window still returns 2.363 / 3.221.

**The objective is UNCHANGED and no refit is owed.** Its `gcb_land_sink` stream still scores 2024;
that row is z **+0.86** against a 1959–2023 mean |z| of **0.64** — 1.3×, not an outlier.

---

## 2. Decision 6b — ANSWERED: the suite is green, and there is a new threshold rule

**LINE 99 was NOT the isotope fix** — the probe is bit-identical either side of `6bda464`.
`tau_turn` genuinely excludes seasonal NEP (with the seasonal SST off, toggling seasonal NEP moves
it by **exactly zero**); what broke it is that `seas_drivers` is a MASTER switch that also kills
the seasonal SST, and **`ccx_hold_climate()` does not suppress that cycle** because it is generated
from the `sst_seas_amp_*` PARAMETERS, not read from a forcing column. Repaired by holding the
seasonal SST off in BOTH arms. The tolerance was not loosened.

**LINE 100's 0.2 yr GATE IS WITHDRAWN. NEW STANDING RULE (Marcus):**

> **Thresholds should be derived from observations or from physical laws.**

Deriving a gate from the code's own numerical agreement is re-baselining in disguise. Both
principled routes were TRIED AND MEASURED here, and both fail *in this test's configuration*:
the observation cannot anchor it (at defaults with climate held the model's NH seasonal amplitude
is 1.66 ppm against MLO's 5.72 and the **SH January tendency has the wrong sign**), and the obvious
law does not transfer (the 12-month label contamination is **0.2307 yr, LARGER** than the 1-month
0.1805 — the label is rectified into and out of the leaf pool, so "seasonal NEP is zero-mean" says
nothing about it). What is asserted instead carries **no threshold**: seasonality must make the
one-month estimator WORSE than it is without seasonality. Measured 0.1727 against 0.0078.

**The old number was tracking a driver**, which is what a gate must never do: `f85ef7b`
(2026-08-20) took the shortening **0.7079 → 0.1805 in ONE commit** by shipping the MEASURED NEP
amplitude factors, `seas_npp_amp` 1 → 0.4969/0.5027.

⚠ **`ccx_hold_climate()`'s gap is NOT audited beyond this one test.** Anything else calling it to
get a clean aseasonal control has the same incomplete control. **Unchecked.**

---

## 3. ⇒ THE FINDING THAT SHOULD SHAPE THE NEXT STEP

Checking the seasonal phase at the **CANONICAL MODE with full forcing** (not at defaults):

| | pk-pk ppm | dC/dt at 1 Jan |
|---|---|---|
| model `co2_NH` | 6.36 | +19.14 |
| obs MLO (NH) | 5.72 | +16.75 |
| model `co2_SH` | **1.09** | **−3.37** |
| obs SPO (SH) | **1.08** | **−3.40** |

**The model reproduces the observed seasonal CO2 cycle — SH to ~1 % in both amplitude and phase.**
Consistent with [[ccx_seas_phase_late]]. (At DEFAULTS the SH sign is INVERTED; that is the harness,
and I nearly reported it as a model defect. **Check seasonal-phase claims at the MODE.**)

**It does this while running its drivers far outside their observed brackets** (§7c-2, handoff 27b):

| param | fitted | observed | |
|---|---|---|---|
| `seas_T_amp_SH` | 1.039 | bracket 3.59–7.10 | **29 % of the LOW end** |
| `sst_seas_amp_SH` | 0.360 | 1.746 | **21 %** |
| `sst_seas_amp_NH` | 0.937 | 2.237 | 42 % |
| `seas_T_amp_NH` | 23.46 | bracket 11.45–17.92 | **131 % of the HIGH end** |

⇒ **THE CO2 SEASONAL ROWS HAVE NO POWER TO REJECT THE PARTITION. They are ALREADY MATCHED.** A
test of the seasonal partition run on the CO2 amplitude will return "no effect" whether the
partition is right or wrong ([[no_power_null]]). **It must run on the ISOTOPES (d13C per ppm) or on
the DRIVERS (the bracket ratios above).** This is the compensation [[ccx_seas_partition]] describes,
seen from the CO2 side for the first time.

---

## 4. THE NEXT STEP: §7c-3, the SH land box — and §3 says how to pose it

The evidence now pointing the same way, from three independent directions:
- **Prior flags:** two of the three worst-flagged parameters in the 21-parameter fit are SH
  seasonal amplitudes; the isotope fix INVERTED the hemispheric asymmetry (`sst_seas_amp_NH`
  −6.22 → −3.48 relieved, `sst_seas_amp_SH` −4.25 → **−6.32** worse).
- **Driver ratios:** SH land at 29 % of its bracket's low end, SH ocean at 21 % of observed.
- **The surviving partition residual:** SPO ~1.5× (was 2.45× pre-fix), still open.

**Marcus's named structural candidates** (handoff 27, §7c-3), all still untested: **latitude bands
within each hemisphere**, stratosphere, high-latitude mixing. A **single SH land box at an
effective latitude** is the obvious suspect and §3 upgrades it from a hunch to the direction three
measurements agree on.

**HOW TO POSE IT, given §3:**
1. **Score it on the isotopes or the drivers, never on the CO2 seasonal amplitude.** Measure the
   test's POWER first — a CO2-amplitude test is structurally guaranteed to return null.
2. **Pre-register**, as the 08-25f refit was. The last three seasonal conclusions that were not
   pre-registered were retracted by their own refits.
3. **Note the confound:** `seas_T_amp` and `q10` sit on an EXACT ridge ([[ccx_seas_q10_ridge]] —
   product held to 0.2 % over a 2.5× `q10` range), and `beta_max`/`fert_k` absorb 85 % of a frozen
   cost. A frozen 1-D scan of an SH land amplitude will overstate its cost.

**Still open behind it, unchanged from handoff 27:** the d13C Suess overshoot re-check; whether
`gcb_land_sink` SHOULD be decisive (surviving objection at −7.94 and +2.30σ, and it carries
`LIK_LAND_SINK_INFLATE` = 3.0 plus a known GCB closure error); `kz` railing (6332 against a bracket
top of 6528); the pump's `alpha13_signed` (b) case; `alpha_as_*`; the Hessian condition number;
**the sampler** — still the project's oldest open item, and there is STILL NO POSTERIOR.

**Also owed:** `INDEX_ccx.md` is over its stated 14 KB budget (was already ~16.5 KB before
2026-08-27; four lines added, two compacted since). A consolidation pass.
