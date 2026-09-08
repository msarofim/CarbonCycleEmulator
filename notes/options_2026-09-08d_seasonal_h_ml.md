# OPTIONS — a SEASONAL mixed-layer thickness for CCX (2026-09-08d). Marcus: "either free `h_ml` or explore pinning it to a seasonal shape so that it can capture both the annual mean and the annual max."
# **⛔ Nothing built. Every model number is GENERATED at the round-3 winner (id 24) from `outputs/diagnostics/u_hs_h_ml_tests_20260908.rds` / the winner's spinup; every observation number is from `data/obs_mld.rds` or computed from the Holte product in this note's own one-liners. Ruling owed.**

## 0. What the question really is
The model has ONE time-constant `h_ml` and the observation has two numbers for it — the LS annual mean **59.7 m**
and the annual maximum **118 m** (09-08c). But the model ALREADY carries a seasonal mixed-layer mechanism in
disguise: `ent_seas_amp_SH` (26th parameter, freed 09-03, [[ccx_seasonal_entrainment_hypothesis]]) adds a prescribed
sinusoidal DIC anomaly to the SH mixed layer's pCO₂ computation (`R/model.R:1848`, `ccx_core.cpp:534`), peaking at the
registered `CCX_ENT_SEAS_PEAK_MO` 7.50, with a FITTED amplitude (winner **21.2 µmol/kg**, `ent26` 19.0, prior centre
10.95 derived from the in-band 29.68 × the band's area fraction). That parameter IS "winter entrainment of DIC-rich
water when the mixed layer deepens" — represented as a fitted compensator with no physical link to how deep the
mixed layer goes. And the NH has no such channel at all, which is where the strain now sits (`sst_seas_amp_NH`
prior-z **−2.83** at the winner, −3.91 at `ent26`; [[ccx_refit_20260903_ent26]]).

⇒ **"Pin `h_ml` to a seasonal shape" = replace the fitted entrainment amplitude with the entrainment the MLD
climatology and the model's own vertical DIC gradient IMPLY.** That is the pedagogical standard exactly
([[ccx_pedagogical_not_emulator]]): a mechanism with no fitted amplitude, in both hemispheres, carrying an isotopic
signature the solubility cycle cannot fake.

## 1. The observation: the seasonal shape (computed from the Holte product, 12-month LS cells, cos-lat weighted)
| | J | F | M | A | M | J | J | A | S | O | N | D | mean | max | min |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **NH** threshold MLD, m | 76.5 | **82.6** | 73.6 | 50.7 | 34.8 | 30.1 | 29.7 | 29.7 | 32.0 | 38.3 | 48.8 | 62.6 | 49.1 | 82.6 (Feb) | 29.7 |
| **SH** threshold MLD, m | 36.4 | 37.9 | 43.5 | 53.2 | 67.0 | 84.1 | 102.2 | **114.0** | 107.8 | 79.3 | 51.0 | 39.2 | 68.0 | 114.0 (Aug) | 36.4 |
| NH per-cell entrainment fraction f = (h − h_min)/h | .652 | .643 | .587 | .485 | .374 | .285 | .257 | .276 | .362 | .452 | .542 | .616 | .461 | .652 (Jan) | .257 |
| SH f | .202 | .239 | .332 | .434 | .541 | .623 | .671 | **.680** | .646 | .542 | .376 | .244 | .461 | .680 (Aug) | .202 |
max/mean = 1.68 in both hemispheres; the hemispheric MEANS differ (49 vs 68) because the SH has more 40–57° ocean.
The per-cell fraction is the dilution-honest form: it averages each cell's own (h − h_min)/h, so tropical cells with
a 10 m cycle and 45° cells with a 150 m cycle each contribute what they entrain. (The area-mean-h form gives the
same maximum, 0.64 / 0.68.) ⚠ The SH peak (Aug, month 8.0 → a sine peaking at 8.0) is 0.5 mo LATER than the
registered driver 7.50; the NH peak is Jan–Feb.

## 2. The model side: what the mixed layer would entrain (winner's preindustrial spinup, `h_ml` 39.8)
| | ML | layer 1 (40–92 m) | layer 2 (92–166 m) | C₁ − ML | C₂ − ML |
|---|---|---|---|---|---|
| NH DIC, µmol/kg | 1990 | 2033 | 2087 | **+42** | +97 |
| SH | 2007 | 2049 | 2104 | **+42** | +97 |
A winter mixed layer of 83 (NH) / 114 m (SH) reaches through layer 1 into layer 2, so the entrained water is +42 to
~+70 µmol/kg above the mixed layer. **Pre-check of the seasonal DIC amplitude the mechanism implies** (half the
f-swing × ΔC): SH (0.680 − 0.202)/2 × 42–70 = **10–17 µmol/kg**; NH (0.652 − 0.257)/2 × 42–70 = **8–14 µmol/kg**.
Against: the fitted SH amplitude 21.2 (winner) / 19.0 (`ent26`), the prior centre 10.95, the in-band observation
29.68 before dilution. ⇒ **The mechanism sizes to the observed order with nothing tuned** — the same out-of-sample
support criterion the HS pump met ([[ccx_hs_pump_probe]]). ⚠ These are first-principles pre-checks at the winner's
gradient; the gradient itself is a fitted quantity (the LS pump, `kz`), so the number is model-conditional.

## 3. The options
**(A) A true time-varying mixed layer.** `h_ml(t)` follows the monthly climatology per hemisphere (scaled so its
annual mean is the fitted or pinned `h_ml`); the first interior layer absorbs the change; entrainment when deepening
brings layer-1 water (C, ¹³C, ¹⁴C) into the ML at layer-1 concentrations; detrainment when shoaling leaves ML water
below. Both cores (R `ccx_deriv`, C++ `ccx_core.cpp`), the spinup (a periodic steady state — today's spinup zeroes
seasonality and solves a fixed point), the bomb-¹⁴C capacity, the parity tests. **Cost: days; risk: the spinup.**
Buys: conservation, the isotopes, and the NH channel, all mechanically.
**(B) Derived-amplitude entrainment (the shim, made honest).** Keep the grid and today's shim FORM, but replace the
fitted amplitude with `(C₁ − C_ml)(t) × f_h(month)` from a data product (`data/obs_mld_seasonal.rds`: the two
12-month f rows above), in BOTH hemispheres, and carry the ¹³C step the same way (layer-1 δ¹³C is lighter than the
ML's, so entrainment lowers ML δ¹³C in winter — a signal solubility cannot produce and the `d13c_seasonal_*` rows
CAN score). `ent_seas_amp_SH` RETIRES (26 → 25 in that family; the objective/space changes again — comparable on
LIKELIHOOD only). Cost: one day incl. tests; both cores touch one expression each. ⚠ It remains a pCO₂-side anomaly
(carbon is moved only through the flux it induces), as today's shim is.
**(C) Free `h_ml` with a prior spanning both readings** (no mechanism): lognormal, median √(59.7 × 118) = 83.9 m,
log-sd ln(118/59.7)/2 = 0.341 so the mean and the max are ±1σ. Cheapest; answers nothing about the seasonal cycle.

## 4. Pre-registered predictions for (B), to be written into the prereg BEFORE it is built
- P1 at the winner, unrefitted, SH amplitude lands in [10, 17]; the `co2_seasonal_SPO` / `d13c_seasonal_SPO` rows move
  by < the fitted shim's 21.2 would predict (the mechanism is smaller than the compensator).
- P2 the NH gains an amplitude in [8, 14] peaking Jan–Feb, and `sst_seas_amp_NH`'s strain (−2.83) RELAXES on refit —
  the load-bearing test, the NH analogue of 09-03's P2.
- P3 the SPO ocean limb's phase stays inside GATE S's bracket [7.41, 10.41] with the peak moved from 7.50 to 8.0.
- P4 the `d13c_seasonal_*` rows IMPROVE or hold — entrainment's isotopic signature is the discriminant;
  if they PAY, the mechanism is wrong in the isotope and (B) is refuted as built.
- P5 IRF(100) reported, not gated (a comparison since 09-04e).

## 5. Recommendation
Round 4 (launching now) carries `u_hs` freed and `h_ml` under option (C)'s prior — the ruling Marcus gave, and it
keeps round 4 a ONE-question experiment (does `u_hs` run back to 38?). **(B) is the round-5 candidate**: build it
after round 4 is read, prereg P1–P5 first, probe unrefitted at the round-4 winner, then refit. (A) only if (B)'s
isotope test (P4) says the pCO₂-side form is what fails. The seasonal shape product is cheap to build now
(`data-raw/build_mld_targets.R` can emit the 2 × 12 rows) and is built with this note.
