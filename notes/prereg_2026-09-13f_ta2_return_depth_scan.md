# PRE-REGISTRATION — T-A2: the limb's RETURN DEPTH, scanned unrefitted at `hilda30c`

**Written 2026-09-13 (f), BEFORE `calibration/diag_ta2_enso_return_depth.R` was written or run.** Ruled by
Marcus 09-13 ("Run the T-A2 scan first, and then scope the equatorial cell"). Follows T-A1
(`prereg_2026-09-13e_optionA_nino34_thermocline_limb.md`, memory `ccx_ta1_thermocline_limb_probe`): the
Niño3.4-modulated limb with a LAYER-1 return is right-signed, exactly linear and free, and 4× too weak
(gain 0.0250 GtC/yr per (m/yr) per index; T-A0's whole-column limb 0.100).

## 1. The limb, generalized to a return at layer k — ANOMALY ONLY
Signed exchange between the mixed layer and layer k, ΔV(t) = −γ_A·Niño3.4(t) (m/yr per index unit),
each tracer at its own gradient: F_tr(k → ML) = ΔV·(y[k,tr]/dz_k − y[ml,tr]/dz_ml(t)). El Niño (N > 0)
⇒ ΔV < 0 ⇒ less layer-k water reaches the mixed layer. **k = 1 IS T-A1** (there ΔK = ΔV·dz_mid on the
fitted interface diffusion), so k = 1 must reproduce T-A1's γ_A = 3 slope (−0.0945) — the identity check.
Added AFTER the base `ccx_deriv()` in a session wrapper (dy is a boxes × tracers matrix); no core touched;
both hemispheres equally; spinup = the file's own periodic one, taken before the wrapper.

**Why anomaly-only, with no mean W0 (stated, with its evidence).** The periodic spinup integrates in C++
(`ps_phi` → `ccx_run_fast`), so a MEAN limb to layer k ≥ 2 cannot be put in the equilibrium without the
core, and a transient started off its own equilibrium would drift — a mean-state artifact, not the limb.
T-A0's table (re-read today, `ta0_enso_upwelling_sign_20260908.rds`) shows the response is a function of
W0·γ ALONE: slope = −0.1628 + 0.0998·(W0·γ), R² 0.9996 across W0 = 0.5–4 m/yr, residuals < 0.006; the
γ = 0 intercepts at W0 = 0.5 / 1 / 2 / 4 are −0.16287 / −0.16284 / −0.16279 / −0.16274 — a mean limb up to
4 m/yr moved the solubility-only slope by 1e-4. ⇒ **the GAIN is a property of the anomaly, not the mean**,
and the anomaly-only scan measures it at the canonical mean state. The PRICE of a mean W0 at layer k
(the Δ¹⁴C / gradient rows — T-A0's −135 at the bottom) is a DIFFERENT question, answerable only with the
limb in the C++ core; this scan does not answer it and says so.

## 2. What T-A1 implies, before the run (the hypothesis T-A2 tests)
T-A1's 14.5 % conversion (gain 0.0250 of a 0.172 GtC/yr per (m/yr) supply anomaly) was read as "the
layer-1 ↔ ML coupling (V0 = 187 m/yr, ~0.35 yr) refills the deficit". But that coupling refills a ML
deficit WHATEVER its source — a limb returning at layer 5 still leaves a ML deficit that layer 1 refills.
So the alternative reading is: **the efficiency is ~constant in k, and T-A0's 4× came from the CONTRAST** —
the bottom box is ~5× richer than layer 1 relative to the ML (the fitted deep − surface DIC gradient is
~230 µmol/kg against layer 1's +46), so the same 14.5 % of a 5× larger supply anomaly ≈ 0.100. Check:
109 Sv × 46/230 ≈ 22 Sv per index — T-A0's "26 Sv" was a BOTTOM-WATER number. If this reading holds, the
design question is not "which interface short-circuits" but **"how DIC-rich is the water the real
equatorial upwelling delivers, relative to the surface"** — an observation (a GLODAP tropical profile), and
the return layer is chosen to match it.

## 3. Predictions
| id | prediction | falsified if |
|---|---|---|
| **P0** | k = 1 at γ_A 3 reproduces T-A1: slope −0.0945 ± 0.001, Δlik +2.80 ± 0.05 | any mismatch — the wrapper's limb is not T-A1's; STOP |
| **P1** | the annual-mean layer-k − ML DIC contrast rises monotonically with k (1959–2024, each box over its mass at the time) | non-monotone — the pump's divergence construction has a negative layer |
| **P2** | conversion efficiency = gain / (100 %-supply from the recorded contrast) is **0.10–0.20 at every k** (T-A1's 0.145 ± a third) | efficiency rises > 0.25 at deep k — the short circuit IS interface-specific and the return depth matters beyond the contrast |
| **P3** | gain ∝ contrast: the bottom return (k = 10) gives 0.08–0.13 GtC/yr per (m/yr) per index — T-A0's 0.100 recovered from a DIRECT exchange | outside — T-A0's whole-column cascade (layer 1 refilled from layer 2, …) carried part of the gain |
| **P4** | the anomaly's price stays POSITIVE at every k (the ENSO rows pay; the anomaly has zero mean), with the Δ¹⁴C rows moving < 1 log-unit even at k = 10 | a Δ¹⁴C row moves > 1 — a zero-mean modulation of ¹⁴C-depleted water is visible in the bomb-era record, and a mean W0 at that depth would cost more still |

## 4. Scan and outputs
k ∈ {1, 2, 3, 4, 5, 6, 8, 10} at γ_A = 3 m/yr per index (T-A1's linear regime; its k = 1 reads −0.0945),
`gamma_enso_ocn_NH/SH` = 0 in every arm. Per k: slope, r, gain = (slope − slope₀)/3, contrast, efficiency,
γ_A and Sv the obs slope needs, Δlik and its rows. Layer geometry printed (depth of each layer's top and
bottom at the fitted `h_ml`). Output `outputs/diagnostics/ta2_enso_return_depth_20260913.{log,rds}`.
