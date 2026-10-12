# Why CarboTope's pulse leaves the air faster early than Joos's mean — the tests (2026-10-12)

Marcus, 2026-10-12: *"Do we have a physical explanation for why CarboTope has an early faster drawdown?"*

This is a measurement record, not an answer. The diagnosis was run by a subagent on `hilda29e`, PD100, climate free.
- Its scripts and logs are in `outputs/diagnostics/early_drawdown_20261012/` (`lib_ed.R`, `s1`–`s6`, `out/*.log`).
  - ⚠ **Those scripts are UNREVIEWED.** Their unrolled PD100 reproduces `ccx_pd100()` exactly (max |ΔIRF| = 0; 0.522 / 0.379 / 0.295; TH 12.85 / 26.85 / 46.95). Mass closes to 8e-11 GtC.
  - I spot-checked `s4.log` and `s6.log` against the report and they agree. Nothing else was re-run.
- The Joos 2013 values are from the PDF in `~/Documents/2026/ClaudeDocs/Papers/`: Table 5's ocean and land fits (p. 2803), Table 4 (p. 2802), and sec. 4.3 (pp. 2806–2807).

## 1. Where the gap comes from in time

| window after release | 0–1 yr | 1–2 yr | 2–5 yr | 5–20 yr | 20–100 yr |
|---|---|---|---|---|---|
| excess drawdown vs Joos (fraction of pulse) | +0.056 | +0.018 | +0.002 | −0.002 | −0.044 |
| ocean gain vs Joos (GtC) | +4.1 | +0.9 | −0.6 | −0.9 | −2.4 |
| land gain vs Joos (GtC) | +1.9 | +1.2 | +0.9 | +0.3 | −0.4 |

**Nearly all of the IRF(20) gap is made in the first 1–2 years.** After that, CarboTope decays at Joos's rate until 20 yr.

Where the pulse sits (GtC of 100), CarboTope / Joos Table 5 fit:

| t (yr) | air | ocean | land |
|---|---|---|---|
| 1 | 88.0 / 93.5 | 7.54 / 3.48 | 4.50 / 2.55 |
| 20 | 52.2 / 59.6 | 24.12 / 20.63 | 23.65 / 19.25 |
| 100 | 37.9 / 40.9 | 34.42 / 33.34 | 27.65 / 23.66 |

## 2. What the tests support

- **Land: too strong at all times, through CO₂ fertilisation.**
  - With no fertilisation, the land takes up ≈ 0 of the pulse (−0.25 GtC at 20 yr).
  - `beta_max` × 0.75 puts the land on Joos at both 20 and 100 yr (18.6 / 22.2 against 19.25 / 23.66).
  - An independent check: the canonical's 2015–2023 land sink is 3.16 GtC/yr, against its own fitted GCB target of 2.67 (with the mode's imbalance shares). That is +0.49, about +1 gate-7 sd.
- **Ocean: too much in the first year, then less than Joos.**
  - The first-year ocean uptake is 7.5 GtC, against 3.5 in Joos's fit.
  - Gas exchange at the cited centre (k_w 1446 m/yr, Naegler 2009, against the fitted 1870) removes 1.1 GtC of the 4.1 GtC first-year excess.
- **Both together** (k_w 1446, `beta_max` × 0.70): IRF 0.570 / 0.416 / 0.322, against Joos 0.596 / 0.409 / 0.322.
  - That closes 100 and 300 yr.
  - It leaves −0.026 at 20 yr, all of it ocean (25.2 against 20.6 GtC).
- **No single lever has the gap's shape** (ΔIRF20 / ΔIRF100 = 2.45).
  - Fertilisation is about 1.2; `kz` is 1.24.
  - k_w is early-only (4.4–4.8), but small.

## 3. What the tests rule out

- Joos's smoothing, emulated on CarboTope's own IRF: +0.008 at 1 yr, −0.002 at 20 yr.
- Joos's three-exponential fit form, fitted to CarboTope's own series: about 0.02 of the first-two-year gap, and nothing at 20 yr.
- The background level (393.6 against 389 ppm), the free climate, the Revelle factor, and q10: each is the wrong sign or ≤ 0.002.
- The vegetation feedback φ: `npp_veg_frac` is 0 at `hilda29e`.

## 4. First principles (the model's own state at the release)

- **Revelle factor:** NH mixed layer 9.9, SH mixed layer 10.5, high-latitude box 14.2.
  - ⚠ Alkalinity is the PROVISIONAL 2300 µmol/kg (`R/constants.R:258-262`).
- **Surface-ocean equilibrium capacity:** 0.0895 of the airborne excess, so 8.2 GtC of the pulse. The surface-only run plateaus at 8.7 GtC, which matches.
- **Equilibration time:** about 0.6 yr for the mixed layer and 1.6 yr for the high-latitude box.
- **Initial uptake rates:** the ocean's gas-exchange limit is 12.8 GtC/yr and the model's first-quarter mean is 10.1. Joos's ocean fit has an initial slope of 3.8.
- **Land:** initial ΔNPP 6.15 GtC/yr against Joos's land-fit slope of 2.8; d ln NPP / d ln CO₂ = 0.66.
- **Thermocline diffusion** matches its analytic √t law (2.08 / 9.29 predicted, 1.96 / 10.66 modelled), so there is no sign of a transport bug.

## 5. Unexplained, and what would separate it

- **The first-year ocean excess.** About 3 GtC of it remain after k_w. Three candidates have not been separated:
  - the provisional alkalinity, which sets the Revelle factor;
  - the SH mixed layer's winter depth (1.68 × h_ml);
  - the 292 m high-latitude box.
- Joos's raw year-one ocean value per model is in the Supplement, which is not in Papers/. Only the fit is available.
- The fertilisation strength (β_eff 0.66) has not been checked against any FACE observation.
- ⚠ **Context:** CarboTope's TH20 of 12.85 yr is below EVERY individual model in Joos Table 4 (the lowest is CLIMBER2-LPJ at 13.0, p. 2802), although it is inside the 5–95 % range.

## 6. Found on the way

`calibration/diag_pulse_land_attribution.R:28-29, 55` labels Joos's split "sec. 3.2, ±1 sd", where the paper has it in sec. 4.3. `lib_design_gates.R:2136-2141` reads the same paper's ± as 2 sd. **The two files disagree.** Not touched.
