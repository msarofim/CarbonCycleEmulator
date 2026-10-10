# The band ship: FACTS for Marcus's copy, 2026-10-09

**FACTS, NOT COPY.** The wording is Marcus's. Every number below comes from a committed artifact:
- the shipped band `data/futures_ribbons.rds` (`e1711dc`);
- the 200k read `outputs/mcmc_check_20261009_hilda29e_200k/` (`diag_20261009_drop0.csv`, `read_20261009_drop0_pool2.log`);
- the side-by-side `outputs/diagnostics/mcmc_band_compare_hilda29e_20261009.log`;
- CHANGELOG 2026-10-09 (e), (f).

**Supersedes the numbers in `notes/card6_facts_2026-10-02.md`.** Those were measured at `hilda33d`, stage 1, on Torch. The structure of that note (F1–F5) is kept here.

**Ruled 10-09:** "Ship the 200k band (Recommended)". **What the lift waits on** (one line, `APP_RIBBONS_HOLD <- NULL`, in the same commit as these four):
- A. the label;
- B. card 6;
- C. the parameter panel's clause;
- D. ~~how to present the temperature band~~ **RULED 2026-10-10: "Omit it on temperature"** (`dff90c5`). What it now waits on is **the temperature view's sentence** (`APP_RIBBON_NOTE_TEMP`, NULL until worded). See D below.

`test-futures-ribbons.R` fails a lift while A, B or C still describes an app with no band, or while D's sentence is unworded.

---

## What the band IS (for A, B, C)

- **17 000 runs** of the full model, one per posterior draw, 5–95 % shaded. The app's caption reads `n_ok`, so it would print "17000 model runs".
- The draws come from an adaptive Metropolis sampler run on the Mac:
  - 4 chains, 200 000 iterations each;
  - the first 30 000 iterations are discarded (adaptation);
  - every 20th iteration is kept, then every 2nd of those.
- **What is varied:** the 29 fitted carbon-cycle parameters.
- **What is held:** 14 values, fixed at the fit's own numbers:
  - the land ENSO module: `lag_enso_land` 5.93, `gamma_enso_land_NH` / `_SH` 0.66 / 0.64, `w_enso_l2` 16.8;
  - `w_eq` 27, `gamma_eq` 1, `pump_export` 9.08;
  - seven held at 0: `w_vent`, `gamma_vent`, `w_thc`, `gamma_enso_ocn_NH` / `_SH`, `ent_seas_amp_SH`, `npp_tsens`.
- **What is NOT varied at all:**
  - the climate response (fitted to FaIR, fixed);
  - the non-CO₂ forcing;
  - the model's structure.
- **The app's line sits inside the band in every cell:** 5614 of 5614 (7 scenarios × 401 years × 2 variables).
  Example: vvH CO₂ 2150 has band 812.2–834.7 ppm, median 822.0, line 824.9.

## A. The label

The caption renders: "Shaded: the 5–95% range of 17000 model runs — a `<label>`."
- Seen in a scratch preview with the hold lifted (2026-10-10): the count prints as **"17000"**, with no thousands separator (`sprintf("%d")` in `APP_RIBBON_NOTE`). The frame around the label is also unruled template text. Both are yours to change along with the label.
- On the CO₂ view, at the default selection (Low / Medium / High), the band is visible **only on High**: about 8 px at 2150 in an 800 px viewport.

The current string, carried with `label_ruled = FALSE`: "MCMC posterior draws (supplied), conditional on the fourteen held values". It is the builder's provenance label and was never ruled copy.

Once worded, it is set by re-running:

```
Rscript calibration/promote_futures_ribbons.R --from=outputs/diagnostics/futures_ribbons_mcmc_20261009_hilda29e_200k.rds --draws=outputs/mcmc_check_20261009_hilda29e_200k/pooled_u_thin2.rds --label="<wording>"
```

The bands do not change; that is asserted.

## B. Card 6 ("There are no uncertainty bands, anywhere"; `app/R/review.R`, id 6, key "bands")

The title, "plain", "detail" and "ask" all presuppose no band.

**F1. "…so the band would have been too wide."**
- Not re-measurable at `hilda29e`. The main fit's Gaussian failed its importance check there too, as did a curvature-matched Gaussian (CHANGELOG 10-08 i), so no Gaussian band was built to compare against.
- The ~2× factor (CO₂ 0.41×, GMST 0.58×) is `hilda33d`'s, 10-02.

**F2. "…well-behaved enough to quote individual standard errors…"**
Sampled spread compared with the curvature's own marginal sd, in the fitting coordinates:
- **Near 1× along CO₂ fertilisation:** `beta_max` 1.04×, `fert_k` 0.90×, `ndep_ret` 1.15×.
- **5.2× for the mixed-layer depth `h_ml`**, with its centre shifted −4.4 curvature sds. `h_ml` sits against its 42.5 m floor (ruled 09-16 b, KEPT 10-09) in about 1 draw in 10.
- **1.4×** for `kz_deep_frac`, `h_hs` and `imb_share_ocean_rest`.

**F3. "Running a real sampler is planned … no sampler has yet converged…"**
- A sampler HAS run.
- By the strict reference (R-hat < 1.01), it has still not converged everywhere: R-hat max 1.046 (`beta_max`), 8 of 30 quantities above 1.01, min bulk ESS 105.
- In the band's own units, the four chains agree to ≤ 3.5 ppm CO₂ (21 % of the band's width; median 1.0 ppm / 15 %) and ≤ 0.018 °C.
- The band stopped moving between 100k and 200k: widths ×0.97, medians within 0.4 ppm.

**F4. The lines sit mid-band.** 5614 of 5614 cells (above).

**F5. Even the sampled band is narrow, because it varies only the fitted carbon-cycle parameters.** 5–95 % widths across the seven scenarios:

| | 2050 | 2100 | 2150 |
|---|---|---|---|
| CO₂ (ppm) | 2.2–3.1 | 3.6–10.5 | 3.9–22.5 |
| GMST (°C) | 0.010–0.013 | 0.022–0.053 | 0.030–0.098 |
| the lines span, CO₂ | 434–493 | 383–647 | 305–825 |
| the lines span, GMST | 1.84–2.11 | 1.70–3.38 | 1.25–4.61 |

The widest CO₂ band is vvH (22.5 ppm in 2150). The widest GMST band is vvLN (0.098 °C).

## C. The parameter panel (`app/global.R`, `app_params()`)

The current clause: "A single best fit, not yet a posterior — no uncertainty ranges are shown, and the fit constrains the shape of these curves more tightly than their absolute height."

What is true after the lift:
- The lines are still the single best fit (MAP).
- The Futures tab shows a sampled band around them.
- Nothing else in the app has a range.

## D. The temperature band: RULED "Omit it on temperature" (Marcus 2026-10-10)

**What is built** (`dff90c5`, behind the hold):
- The band is drawn on the CO₂ view only (`APP_RIBBON_YVARS <- "co2_ppm"`).
- On the temperature view, the caption's band sentence is replaced by `APP_RIBBON_NOTE_TEMP`. Per the ruling, that sentence says in words that the temperature spread comes only through CO₂ and is not shown.
- **The wording is yours.** It is NULL until you write it, and the lift gate blocks while it is NULL.
- The artifact still carries the GMST bands; the app just does not draw them.

**The facts for that sentence:**
- **0.02–0.10 °C wide at 2100–2150**, against lines 1.25–4.61 °C apart.
- At the app's scale that is ≈ 3 px for the widest default-selection band (High, 2150, 0.083 °C, at ≈ 40 px per °C in an 800 px viewport), about the line's own width.
- The draws vary only the 29 fitted carbon-cycle parameters. The climate response (fitted to FaIR) and the non-CO₂ forcing are fixed, so temperature moves only through the CO₂ it is handed.
- The previous draft, never ruled or shown, was mine (B7, 10-01): "It varies the carbon cycle only: how much the world warms for a given amount of CO₂ is held at the model's one fitted value." It described a DRAWN band, so it no longer fits.
