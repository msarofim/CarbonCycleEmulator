# PREREG (build + probe tier) — O5b: the HIGH-LATITUDE pump on the data's RECTIFIED bloom — does the SPO seasonal amplitude's missing two-thirds live in the HS box?

**2026-09-16 (b). Written BEFORE any core edit, from HEAD `92dd7f8` (the 09-16 handoff). Implements Marcus's rulings of 09-16 (b):
O5b "yes: prereg, build, probe"; the `h_ml` box floor 42.5 m for arrays (the table change is a SEPARATE priced step, below);
THC PARKED. Every number below is read from the tree; nothing is recalled. `hilda30c` stays canonical; every registered mode stays
bit-reproducible; nothing is adopted here.**

## 0. What O5b has to beat, and what it is
- O5 at its SOURCE (LS sine, amp 0.5 / lag −1, [[ccx_export_seasonal_source_0916]]) under martin 9.08 after arm C: **−194.7 like-for-like,
  `co2_seasonal_SPO` −140.7, SPO first harmonic 0.334 ppm @ −5.34 mo vs obs 0.585 @ +5.99** (09-16 2×2, `o5_thc_2x2_20260916.log`). The
  remaining amplitude deficit is **0.251 ppm**. The canonical (solved field) has 0.569.
- The source says the HS boxes' export is a RECTIFIED bloom: ensemble-median unit-mean shapes `shape$NH_HS` / `SH_HS` in
  `data/obs_export_seasonal_shape_cmip6.rds`, first-harmonic amp_rel 1.39 / 1.49, peak/mean 2.95 / 3.36, winter ≈ 0.02 of the mean, lag ≈ 0;
  satellite NPP (CbPM) confirms the HS shape. The O5 build gives the HS pump the LS sine at amp ≤ 1 — a known mis-specification.
- **O5b = the HS pump on the data's shape.** `s_hs,h(t) = 1 + pump_hs_seas_amp × (F_h(t − pump_hs_seas_lag/12) − 1)`, where `F_h` is the
  6-harmonic Fourier interpolant of the hemisphere's unit-mean HS median shape (`ccx_mld_fourier()`, the round-6 idiom: exact at the month
  centers, continuous mean EXACTLY 1). `amp ∈ [0, 1]`: 1 = the CMIP6 shape, 0 = OFF. The interpolant's continuous minimum is +0.0165 (NH) /
  +0.0089 (SH) — READ — so the export never reverses at amp ≤ 1. Zero-mean anomaly ⇒ the annual-mean HS export is unchanged. Lag in months,
  same sign convention as `pump_seas_lag` (positive = later). The LS pump keeps O5's sine (`pump_seas_amp` / `pump_seas_lag`, one pair for
  both hemispheres — the NH LS at 0.5 / −1 instead of its 0.38 / −1.8 is a stated mis-specification, unchanged from the 2×2).
  **Precedence:** with `pump_hs_seas_amp` 0 the HS pump follows the LS sine exactly as O5 built it (every O5 result reproduces bit-exact);
  with it > 0 the HS pump follows F_h INSTEAD of the sine. STRUCTURAL names (the `k_thc` idiom), not in the table; both cores; the shape
  coefficients ride in `aux` (per hemisphere, zero-filled to the C++ when the HS pump is off), the switch is on `p` (the 09-09t class:
  both cores obey `p`, never `aux`'s presence).

**P0 contracts (test-pump-hs-seas.R, gated before any probe number is read):** (a) absent vs present-at-0 BIT-EXACT in both cores, the
canonical's 25 streams reproduce, inert with `seas_drivers` 0; (b) the whole-year integral of the HS pump flux at amp 1 equals the constant
HS export (mean-1 shape; ≤ 1e-9 relative on month-center samples, ≤ 1e-6 on the transient's annual mean); (c) R/C++ parity ≤ 1e-10 at
amp {0.5, 1} × lag {0, 2} × `pump_seas_amp` {0, 0.5}; (d) conservation; (e) guards by name (amp outside [0, 1], non-finite lag, amp > 0
with the HS pump OFF are refused, never clamped); (f) MUTATION: lag 6 moves the SH HS export minimum from July to January (the shape's
power); the factor's continuous minimum at amp 1 is > 0; the LS pump is UNTOUCHED by `pump_hs_seas_amp` (its tendency identical at 0 and 1).

## 1. Quantitative pre-check (computed BEFORE the build, from the canonical's own numbers; the probe decides)
Read at `hilda30c`: HS export SH **2.856 GtC/yr** (NH 2.149; `pump_hs_gcm2` 86.64 gC m⁻² yr⁻¹ × `a_hs`), HS box carbon `hs_C0` SH
**338.0 GtC** (h_hs 393.5 m, one well-mixed box — the HS seasonal thickness `seas_ml = 2` is OFF at the canonical), Revelle 12.9,
HS SH pCO₂ 343 µatm (1975–2024 mean), `k_w` 1637 m/yr, `asx_hs` SH 3.22e-4, K₀(2 °C) 0.0581 ⇒ the HS SH air–sea exchange coefficient
**k_w·asx_hs·K₀ = 0.0306 GtC yr⁻¹ µatm⁻¹** (the LS SH ML's is 0.119); SH atmosphere 1.062 GtC/ppm.
- Seasonal HS DIC anomaly at amp 1 (first harmonic): 2.856 × 1.493 / 2π = **0.68 GtC** = 0.20 % of 338 GtC = 4.3 µmol/kg
  ⇒ HS pCO₂ first-harmonic amplitude ≈ 12.9 × 343 × 0.0020 = **8.9 µatm**, DIC (and pCO₂) maximum at the END OF WINTER (≈ month 9–10 SH).
  Its own damping is negligible (air–sea 0.40 /yr and the HS↔HD exchange against ω = 6.28 /yr).
- Air–sea flux amplitude: 8.9 × 0.0306 = **0.27 GtC/yr** ⇒ an SH atmospheric first-harmonic amplitude of AT MOST 0.27 / (2π × 1.062) =
  **0.041 ppm** before interhemispheric mixing and the LS ocean's uptake (both small at ω = 2π/yr).
- **Prediction P1: O5b at amp 1 adds ≤ 0.05 ppm to the SPO first-harmonic amplitude (0.334 → ≤ 0.38 after arm C), i.e. ≤ 20 % of the
  remaining 0.251 deficit.** The row is quadratic in the deficit: (0.205/0.251)² × 140.7 ≈ −94 ⇒ **P2: the SPO row gains +30 to +60
  log-units at amp 1; the total gains +20 to +60 raw** (the phase is already on obs, so little is available there).
- **The bottleneck is the HS box's air–sea exchange, not the pump.** Closing the 0.251 through the HS box alone needs a flux amplitude
  0.251 × 1.062 × 2π = **1.67 GtC/yr = a 55-µatm HS pCO₂ amplitude = 3.4× the observed Southern Ocean amplitude** (SOM-FFN 40–90 °S,
  `data/obs_so_pco2_seas_amp.rds`: 16.3 µatm @ month 7.5; the model's HS box is 57–90 °S, a stated geometry mismatch).
  ⇒ **The SPO row and the SO pCO₂ row have JOINT POWER: a PASS on the SPO amplitude THROUGH the HS box would fail the pCO₂ row by > 3×.**
- **P3 (out of sample): the HS SH pCO₂ first harmonic goes from the canonical's 0.5 µatm to 6–12 µatm at amp 1, peaking month 8–11** —
  a move from 3 % to ~55 % of the 40–90 °S observation, with the winter-peak phase, whatever the SPO row does.
- Surprise = P1 broken by > 2× (a gain ≥ 0.10 ppm) — then P3 must be read FIRST, because the arithmetic above says such a gain is bought
  with an HS pCO₂ amplitude the ocean does not show.

## 2. The probe (Mac, `calibration/diag_o5b_hs_seasonal_export.R`, unrefitted at `hilda30c`, the dg path; then arm C)
- Harness gates: the canonical's streams reproduce (gate 1); martin 9.08 at O5-source (0.5 / −1) with `pump_hs_seas_amp` 0 reproduces
  the 2×2's O5 cell (−797.6 raw, SPO −140.7 after arm C) to ±0.5 — the precedence contract measured, not asserted.
- Grid, raw (martin 9.08, LS sine at the source 0.5 / −1): `pump_hs_seas_amp` ∈ {0, 0.25, 0.5, 0.75, 1} × `pump_hs_seas_lag` ∈ {−1, 0, +1}
  = 15 points. Reads per point: dlik vs the canonical, the SPO and MLO seasonal rows, the SPO first harmonic (ppm, months), **the HS SH and
  NH pCO₂ first harmonics (µatm, peak month) vs the SO product**, the CO₂-level rows, the bomb rows, the 1995 bomb excess, PI layer 2/6 − ML.
- Control (the canonical, solved field, its own HS pump): amp {0.5, 1} lag 0 — how much the canonical's SPO row and HS pCO₂ move
  (recorded; the canonical was fitted at amp 0, so a cost there is expected and is NOT a criterion).
- Arm C (the PK-2 eight: `beta_max, fert_k, q10, kz_deep_frac, h_ml, k_w, bomb_total, sigma_d14c`) at the best raw grid point and at
  amp 1 lag 0 if different, with the `h_ml` band set IN PROCESS to **[42.5, 200]** (Marcus 09-16 b; the `hml_bound` idiom of
  `R/paths.R`, recorded in the output) — so the refit cannot buy the row with a 3rd-percentile mixed layer. dlik is on the LIKELIHOOD
  streams (like-for-like on the 25 rows; the band's Jacobian does not enter).
- ~20 min on the Mac (the 2×2's arm C took ~3 min a cell).

## 3. Decision rule (stated before the run; in the PHYSICAL unit this time — the 09-15 (g) lesson)
Let A = the SPO first-harmonic amplitude after arm C at the best point, P_HS = the HS SH pCO₂ first-harmonic amplitude there.
- **PASS** iff (a) **A ≥ 0.46 ppm** (≥ half of the remaining 0.251 closed from O5-at-source's 0.334) AND (b) **P_HS ≤ 33 µatm**
  (≤ 2× the 40–90 °S observation; the factor 2 is the stated geometry allowance — 57–90 °S is the more seasonal part of the band, and the
  product omits the seasonality of k and K₀) AND (c) the SPO phase within ±1 month of +5.99 AND (d) the total improves by ≥ 20 log-units
  over the O5-source cell after arm C (the gain is not paid for by MLO / the level / the bomb rows).
- **PARTIAL (the predicted outcome)** iff (b) and (d) hold and A gains ≥ 0.03 ppm but < the PASS bound: O5b is a REAL mechanism
  that moves the out-of-sample pCO₂ row toward observation but cannot carry the SPO deficit — recorded as such; the deficit's home is then
  NOT the HS pump under this geometry, and the honest next question is the LS SH mixed layer's own seasonal pCO₂ (canonical 10.8 µatm @ 7.5)
  or the sub-ML gradient the martin field inverts — not more HS export.
- **REFUTED** iff A gains < 0.03 ppm or (d) fails. If (a) passes while (b) FAILS, that is the joint-power case of §1: reported as
  "the SPO row bought with an unobserved HS pCO₂ amplitude", NOT as a pass.
Nothing is promoted by this probe. `pump_hs_seas_*` enter the table only on a PASS, with the source's amplitude bracket as the prior.

## 4. The separate priced step: `h_ml`'s box floor 30 → 42.5 m (ruled; NOT part of this probe's verdict)
A SHIPPED-TABLE change (the array driver takes its band from `CCX_PARAM_TABLE`, `run_dispersed_multistart.R:343`), so: (i) every stored
logpost moves by the logit Jacobian — compare on LIKELIHOOD (the 09-09w precedent in `R/calibrate.R`); the shift at the canonical is
MEASURED and recorded, the likelihood asserted unchanged; (ii) every registered mode's `h_ml` must lie inside the new box (checked before
the edit; `hilda30c` 65.2 m); (iii) `calibration/torch/port_targets.csv` must be regenerated (already owed — it is the E arm's) and
`make_port_targets.R` re-run before ANY array; (iv) `CCX_MODE_BAND_FIELDS` / `hml_bound` need no code change — the shipped band is what
they record. Done AFTER the probe, in its own commit, so the probe's like-for-like numbers are never confounded with the table move.
