# PRE-REGISTRATION — is the SPO seasonal partition ONE fix?
# The land reduction and the ocean channel, scored as a 2×2 with an INTERACTION term

**Written 2026-08-27, BEFORE a line of the driver existed.** Authorized by Marcus 2026-08-27 after
`collect_2026-08-27i_the_land_and_ocean_fix_is_one_fix.md`. Slice, mode and matched design are
27g's, unchanged, so the arms are comparable to that run.

---

## The claim under test, stated so it can fail

Two experiments have now each moved ONE half of SPO's seasonal cycle and each been charged for
breaking a cancellation:

| | what moved | result |
|---|---|---|
| **27g** | ocean: `ent_seas_amp_SH` free | worked mechanically (P1 PASS), but the fit spent it as a COUNTERWEIGHT; net ocean got WORSE (0.236 → 0.124). **+11.62** |
| **27i** | land: `seas_npp_amp_SH` to the GPP end | closes 67 % of the land excess, δ¹³C row IMPROVES **+2.99** — but costs **−79.01** conditionally, of which `co2_seasonal_SPO` is the ENTIRE bill |

**The model's SPO total is right BY CANCELLATION** — 1.141 against observed **1.168** (−2.3 %) —
from a land component **1.92×** too big and an ocean component **0.45×** too small, ~5 months apart.

> **HYPOTHESIS: these are not two candidate fixes but ONE. The land reduction vacates amplitude at
> the wrong phase; the entrainment channel supplies it at the right one. Neither can be scored
> alone, and the JOINT arm should beat the SUM of the two singles.**

The joint arithmetic, computed in advance: the GPP end leaves the total **0.286 ppm short** (0.882
vs 1.168), and 27g's P1 measured the channel moving the ocean limb **0.247 @ mo 3.68 → 0.614 @ mo
9.91** at 10 µmol/kg — **≈ +0.37 ppm within 1.4 months of the observed ocean peak of 8.52.** Right
size, right phase. That is the prediction, and it is arithmetic, not hope.

## The design — a 2×2, because the claim is an INTERACTION

| arm | `seas_npp_amp_SH` | `ent_seas_amp_SH` | free params |
|---|---|---|---|
| **INCUMBENT** | 0.5027 (PsnNet, shipped) | 0 | 6 |
| **LAND-only** | **0.352 (GPP end)** | 0 | 6 |
| **OCEAN-only** | 0.5027 | free in [0.5, 60] | 7 |
| **JOINT** | **0.352** | free in [0.5, 60] | 7 |

Slice in every arm, identical to 27g's `RF_BLOCK`: `sst_seas_amp_NH`, `sst_seas_amp_SH`,
`seas_T_amp_NH`, `seas_T_amp_SH`, `seas_lag_p`, `q10`. **`tau_ex` is deliberately NOT in it** —
27h measured it inert on the SPO total (−1.7 % over an 8× range) and unaffordable; adding it would
buy a dimension and no power. The gradient offsets are out for the same reason.

**⇒ THE HEADLINE STATISTIC IS THE INTERACTION, AND IT IS PARAMETER-BALANCED:**

    INTERACTION = JOINT − LAND-only − OCEAN-only + INCUMBENT

Counts: 7 − 6 − 7 + 6 = **0**. So unlike a bare challenger-minus-incumbent Δlogpost — which 27g
correctly refused to call a model comparison, because `ent_seas_amp_SH` is a free scalar with no
prior — **this contrast holds the parameter count fixed and IS interpretable.** That is the whole
reason for running four arms instead of two.

⚠ `seas_npp_amp_SH` is a MEASURED CONSTANT moved to the far end of its own measured bracket
(PsnNet 0.5027 ± 0.087 vs GPP 0.352 = −1.73 sd). It is **fixed, not fitted**, in every arm — it
adds no degree of freedom. Whether the model is *entitled* to that end of a 1.4× product
disagreement is a separate question Marcus has flagged and this run does not settle.

⚠ Everything is scored by ONE harness and read as DIFFERENCES. `ccx_make_logpost()` sits −3.3223
below the stored mode logpost, pre-existing and undiagnosed. No absolute logpost is quoted.

---

## P0 — METHOD CONTROL, SCORED FIRST. If it fails, nothing below is read.

The INCUMBENT arm at its starting vector must reproduce 27h/27i's measured numbers on this harness:
SPO total **1.141**, SH-local land **1.308**, NH-origin **0.821**, δ¹³C-per-ppm **1.930**, and the
harness offset **−3.3223 ± 0.5**. All four arms must use the same `ccx_prepare_obs()` and the same
window. Every optimizer arm must report `converged` with its restart count and last gain — 27h had
to discard a run for a silent `maxit`.

## P1 — THE INTERACTION IS POSITIVE AND LARGE  ← the test

**PREDICT `INTERACTION ≥ 0.5 × |LAND-only cost|`.**

Derived, not chosen: the land-only arm's cost is almost entirely `co2_seasonal_SPO` paying for
amplitude the reduction vacated. If the channel genuinely replaces that amplitude at the right
phase, the interaction must recover a substantial share of it; half is the conservative half of
"substantial". At 27i's measured land-only cost of 79.01 this sets the gate at **≥ +39.5**.

**FALSIFIER `INTERACTION < 0.5 × |LAND-only cost|`.** That is a REAL FINDING and is to be reported
as one: it would mean the entrainment channel cannot supply the ocean amplitude at the phase the
land reduction vacates, and **4b — a genuine second SH ocean column — becomes the live question**,
on a residual that has finally had both levers available.

## P2 — the channel lands INSIDE its physical band

**PREDICT `ent_seas_amp_SH` ∈ [5, 30] µmol/kg** in the JOINT arm — the pre-check band prereg 27g
derived for a mean over the SH box. 27g's ocean-only fit landed at **4.16, below it**, and the
27g script flagged it. If the joint arm still lands below 5, the channel is again doing work a
Southern-Ocean entrainment cycle of that size could not do. **FALSIFIER: < 5.**

## P3 — the standing partition target, 27g's own unmet gate

**PREDICT SPO δ¹³C-per-ppm ≤ 1.70** in the JOINT arm. This is **27g's own P4 gate, reused
unchanged** — it scored 1.77 there and was recorded INCONCLUSIVE, so it is the standing unmet
target rather than a new number. Reference points on this harness: incumbent **1.930/1.940**,
ocean-only **1.77**, land-only conditional **1.834**. A "one fix" claim must beat BOTH singles.

## P4 — the total is PRESERVED, which is the thing both singles broke

**PREDICT SPO total ∈ [1.114, 1.222] ppm.** Derived from the incumbent's own miss: it sits at 1.141
against an observed 1.168, an error of 0.027, and the gate is twice that either side. Land-only
alone gives **0.882 (−25 %)**; 27g's ocean-only pushed the total to **+5.8 %**. The joint arm's
whole claim is that it does neither.

## P5 — the ocean component RISES toward observed

**PREDICT SPO ocean ratio ≥ 0.75×** (from 0.45× at the mode; 27g's ocean-only made it **worse**, at
0.23×). Derived: 27g's P1 measured the channel reaching 0.614 against an observed 0.522, i.e. 1.18×,
at 10 µmol/kg — so at least halfway from 0.45 to 1.00 is the conservative reading of its own
measured power.

## P6 — MLO CONTROL, so the SH fix is not bought at the NH's expense

**PREDICT MLO δ¹³C-per-ppm ∈ [0.90, 1.10]** — 27g's own MLO control gate, which scored 0.97, and
which 27i measured invariant at 0.965 across the whole land grid. If MLO moves out of that band the
SH result is contaminated and is not read.

---

## What is NOT claimed, whatever the outcome

- **Not a model comparison between 6- and 7-parameter arms.** Only the parameter-balanced
  INTERACTION is read that way. Bare arm-minus-arm gaps are reported as differences, not evidence.
- **Not a verdict on `phi_eff`.** `seas_npp_amp_SH` is half of a (shape, size) unit with
  `CCX_SEAS_PHI_EFF['SH'] = −30`, and `R/constants.R` says the pair must be re-derived together.
  Nothing here moves phi, so every number is CONDITIONAL on it.
- **Not a license to adopt the GPP end.** Even a clean P1 pass shows only that the two corrections
  interact as predicted. Whether the model may use that end of the PsnNet–GPP disagreement is
  Marcus's call, on the measurement's terms, not on the fit's.
