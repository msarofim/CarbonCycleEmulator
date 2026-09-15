# PREREG (build + probe tier) — O5: a SEASONAL EXPORT under the prescribed (martin) field — does the SPO seasonal row recover at the observed mean export, and does the layer-2 inversion clear?

**2026-09-15 (f). Written BEFORE any core edit, from HEAD `da76e27` (the O6 read). Implements Marcus's ruling of 09-15 (f): "do 1
[O5], not 2 [the land quarter]"; O2 and T5 / the cell / `hilda_c` wait. Every number below is read from the tree; nothing is
recalled. `hilda30c` stays canonical; every registered mode stays bit-reproducible; nothing is adopted here.**

## 0. What O5 has to beat
- A2 (09-15 e, [[ccx_o1_deep_return_probe_0915d]]): under the martin field with NO limb, `co2_seasonal_SPO` costs −252 / −137 / −6 at
  export 9.08 / 20 / 45.5 GtC/yr (totals −895 / −3491 / −18429; the CO₂-level rows nearly flat). The export is CONSTANT in the
  deriv (`R/model.R` pump block: `sc` rescales it only under `pump_mode` D); the SH seasonal atmospheric CO₂ amplitude is generated
  by the seasonal mixed layer entraining the SUB-ML DIC gradient, which ∝ export / K. So the row prices the ANNUAL-MEAN export
  because the model has no seasonal ocean biology to price instead.
- O5's claim: give the model the seasonal biology — an export that peaks in local summer at the observed mean (Nowicki's 9.08) —
  and the SPO row should be priced by the SEASONAL flux, not by the mean gradient. The PI layer-2 inversion (−66 µmol/kg below the
  ML in every martin arm) is the annual-mean field's; a zero-mean seasonal factor leaves the annual-mean export unchanged.

## 1. The mechanism and its build (STRUCTURAL names, not table names — the `k_thc` idiom; registered only if a build tier follows)
`s_h(t) = 1 + pump_seas_amp × σ_h × sin(2π (t − (3.5 + pump_seas_lag) / 12))`, σ_NH = +1, σ_SH = −1 — the SST convention
(`R/model.R` ~2373: lag 0 peaks mid-July NH / mid-January SH). Zero-mean by construction, so ∫ s_h dt over any whole year = 1 ×
the year. `pump_seas_amp ∈ [0, 1]` (the export never reverses; `ccx_prepare()` refuses outside by name), `pump_seas_lag` in
months (any finite). The factor multiplies EVERY pump limb — the LS pump's org + carb legs from BOTH surface boxes (ml, tr) and the
HS pump (`pump_hs`) — one statement about export production, no per-box knob. Both cores; marshalled by exact name; 0 = OFF emits
NOTHING (bit-exact; the `w_thc` contract). Under `seas_ml` the ML thickness moves independently; nothing else is touched.
**P0 contracts:** (a) `amp = 0` bit-exact incl. the canonical's 25 streams; (b) annual-mean pump flux at amp 1 = the constant
export to 1e-6 relative (a whole-year integral); (c) R/C++ parity ≤ 1e-10 at amp {0.5, 1} × lag {0, 2} × `seas_ml` {0, 1};
(d) conservation (every limb through `add_flux`, both isotopes at the source ratio); (e) guards by name; (f) MUTATION: a
sign-flipped σ_SH moves the SH seasonal phase by 6 months (the test must FAIL on it).

## 2. Quantitative pre-check (the expected magnitude, computed before the run)
At amp 1 the SH LS ML's seasonal DIC anomaly is E_SH × amp / 2π = 9.08 × 0.571 / 6.28 = 0.83 GtC on an ML of ~330 GtC
(65 m × ~2.0e14 m² × 1025 kg/m³ × ~2.0 mmol/kg) ≈ 0.25 % ≈ 5 µmol/kg ⇒ ΔpCO₂ ≈ 5/2000 × 10 (Revelle) × 350 µatm ≈ 9 µatm ⇒
an air–sea flux amplitude k_w K₀ Δp A ≈ 1637 m/yr × 3.5e-5 mol m⁻³ µatm⁻¹ × 9 × 2.0e14 ≈ 1.0e14 mol/yr ≈ 1.2 GtC/yr ⇒ an SH
atmospheric amplitude ≤ 1.2 / 2π / 1.06 GtC/ppm ≈ 0.18 ppm, BEFORE the ML's own air-equilibration damps it. The observed SPO
first-harmonic amplitude is ~0.5 ppm (read at gate 0 from `obs$co2_seas$SPO`, not typed here). **Prediction: O5 recovers a
FRACTION of the −252 (≤ 50 %) and does NOT clear the layer-2 inversion.** The probe decides; the prediction is stated so that a
surprise is visible.

## 3. The probe (Mac, unrefitted at `hilda30c`; the dg path; ~15 min)
- Gate 0: the canonical's SPO harmonic (a, b) vs obs (amplitude, phase, in ppm and months); the martin-9.08 point's deficit.
  Harness gate: martin / amp 0 reproduces A2's −895 (± 0.5).
- Grid (martin, export 9.08, no limb): amp ∈ {0, 0.25, 0.5, 0.75, 1} × lag ∈ {−2, 0, +2} months = 15 points; read dlik vs the
  canonical, the SPO and MLO seasonal rows, the CO₂-level rows, the bomb rows, the SPO harmonic amplitude/phase, the PI layer-2
  and layer-6 minus ML, the 1995 ocean bomb excess.
- Control (solved field, the canonical): amp ∈ {0.5, 1} × lag 0 — how much the canonical's own SPO row moves (recorded; the
  canonical was fitted at amp 0, so a cost is expected and is NOT a criterion).
- Arm C at the best grid point: the PK-2 surface names (`beta_max, fert_k, q10, kz_deep_frac, h_ml, k_w, bomb_total,
  sigma_d14c`) re-optimised — does the SPO recovery survive a refit of the names that also move the seasonal rows?
## 4. Decision rule (stated before the run)
O5 PASSES as posed iff at some grid point (a) `co2_seasonal_SPO` recovers ≥ 50 % of its martin-9.08 cost (≥ −126 vs the
canonical) AND (b) the martin total improves by ≥ 100 log-units over the amp-0 martin point (the recovery is not paid for by
MLO / the level rows) AND (c) after arm C the SPO row is within 2× its amp-0 arm-C cost's improvement (i.e. the refit does not
undo it). Otherwise O5 is REFUTED AS BUILT and O2's §6 statement is the honest end state (owed if Marcus rules O2). The layer-2
inversion is READ, not a criterion (predicted to persist). Nothing is promoted by this probe.
