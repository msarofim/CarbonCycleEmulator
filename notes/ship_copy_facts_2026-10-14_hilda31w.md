# The band ship at hilda31w: FACTS for Marcus's copy, 2026-10-14

**FACTS, NOT COPY.** The wording is Marcus's. This note **supersedes the numbers in
`notes/ship_copy_facts_2026-10-09.md`**, which were measured at `hilda29e`. That note's structure
(A–D, F1–F5) is kept so the two can be read side by side. The four copy items and the lift rule are
unchanged: one commit, with `APP_RIBBONS_HOLD <- NULL` alongside A–D.

Every number below was read on 2026-10-14 from a committed artifact by a scratch script (not committed),
at `4c6de5c`:
- the shipped band `data/futures_ribbons.rds` (md5 `66c81912c84eb71a00528d353268beb6`, `4acb215`);
- the 200k read: `outputs/mcmc_check_20261014_hilda31w_200k/diag_20261014_drop0.csv` and
  `mcmc_identifiability_20261014_hilda31w.log`;
- CHANGELOG 2026-10-13 (p), (q) and 2026-10-14 (a), (e), (f).

---

## What the band IS (for A, B, C): what changed since hilda29e

| | hilda29e (10-09) | **hilda31w (now)** |
|---|---|---|
| runs | 17 000 | **17 000** (0 failed) |
| parameters varied | 29 | **31** |
| values held | 14 | **14**, the same names and values |
| line inside its band | 5614 of 5614 | **5614 of 5614** |
| vvH CO₂ 2150: band / median / line | 812.2–834.7 / 822.0 / 824.9 | **814.9–837.9 / 825.8 / 827.9** |

- **Sampler:** unchanged. Adaptive Metropolis on the Mac, 4 chains × 200 000 iterations. The first
  30 000 are discarded, every 20th iteration is kept, then every 2nd of those.
- **The 31 varied:** the 29 at hilda29e, plus `seas_T_lag` and `bomb_share_NH`.
- **The 14 held:**
  - `lag_enso_land` 5.93, `gamma_enso_land_NH` / `_SH` 0.66 / 0.64, `w_enso_l2` 16.8;
  - `w_eq` 27, `gamma_eq` 1, `pump_export` 9.08;
  - seven at 0: `w_vent`, `gamma_vent`, `w_thc`, `gamma_enso_ocn_NH` / `_SH`, `ent_seas_amp_SH`, `npp_tsens`.
- **Still NOT varied:** the climate response (fitted to FaIR), the non-CO₂ forcing, the structure.

## A. The label

- The caption still renders "Shaded: the 5–95% range of 17000 model runs — a `<label>`." The count
  prints without a thousands separator (`%d`), and the frame is unruled template text.
- The current label is unchanged and carried with `label_ruled = FALSE`: "MCMC posterior draws
  (supplied), conditional on the fourteen held values". "Fourteen" is still correct.
- **Visibility, NOT re-measured:** at 10-09 the band was visible only on High at the default
  selection, about 8 px at 2150 in an 800 px viewport, for a 22.5 ppm width. The width is now
  22.95 ppm, which scales to about 8 px. This was not re-checked in a browser.
- **The command, with hilda31w paths** (the bands do not change; the driver asserts it):

```
Rscript calibration/promote_futures_ribbons.R --from=outputs/diagnostics/futures_ribbons_mcmc_20261014_hilda31w_200k.rds --draws=outputs/mcmc_check_20261014_hilda31w_200k/pooled_u_thin2.rds --label="<wording>"
```

## B. Card 6 (`app/R/review.R`, id 6, key "bands")

The title "There are no uncertainty bands, anywhere" is already false: FaIR bands are drawn on card 5a
and in the pulse lab (worklist A2, 10-12). The rest presupposes no band.

**F1. "…so the band would have been too wide."**
- Still not re-measurable, and for a harder reason than at hilda29e. **A Gaussian band cannot be
  built at hilda31w:** the P8 wall censors Laplace draws (4 of 20 failed), and the builder refuses
  above 1 % (CHANGELOG 10-13 p).
- The ~2× factor (CO₂ 0.41×, GMST 0.58×) is still `hilda33d`'s, from 10-02.

**F2. "…well-behaved enough to quote individual standard errors…"**

Sampled sd over the curvature's (Laplace) marginal sd, in the fitting coordinates:

| | hilda29e | **hilda31w** |
|---|---|---|
| `beta_max` | 1.04× | **1.37×** |
| `fert_k` | 0.90× | **1.14×** |
| `ndep_ret` | 1.15× | **0.96×** |
| `h_ml` | 5.2× (center −4.4 sd) | **2.94×** (center −2.36 sd) |
| next largest | 1.4× (`kz_deep_frac`, `h_hs`, `imb_share_ocean_rest`) | **1.54×** `bomb_share_NH`, **1.54×** `seas_lag_p_NH`; 1.33–1.36× `h_hs`, `imb_share_ocean_rest`, `kz_deep_frac` |

- The other 22 names fall between 0.95× and 1.25×.
- **`h_ml` sits against a different wall now.** It was the 42.5 m floor (about 1 draw in 10 at hilda29e).
  - At hilda31w the floor is rarely reached: 0.1 % of draws within 1 m, 9.2 % within 5 m.
  - The upper tail is cut by the substep cap: `CCX_SUBSTEPS_MAX` = 256, at 75.02 m at the mode.
    2.7 % of draws are within 1 m of it, and 15.1 % within 5 m.
  - Posterior 2.5 / 50 / 97.5 %: 44.8 / 62.4 / 74.1 m (mode 69.5).
  - This is open design question 4 in the handoff.

**F3. "Running a real sampler is planned … no sampler has yet converged…"**
- A sampler has run.
- **It is further from strict convergence than hilda29e's was.**

  | | hilda29e | **hilda31w** |
  |---|---|---|
  | R-hat max | 1.046 (`beta_max`) | **1.241 (`seas_T_lag`)** |
  | quantities above 1.01 | 8 of 30 | **14 of 32** |
  | min bulk ESS | 105 | **13 (`seas_T_lag`)** |

  - The cause is the seasonal-lag ridge: chain 4's 50–115k excursion (CHANGELOG 10-14 a).
  - The other two ridge names: `seas_lag_p_NH` 1.199, `seas_lag_p_SH` 1.150.
  - Then `beta_max` 1.057, `h_ml` 1.054, `npp_frac_NH` 1.050, `q10` 1.049.
- **In the band's own units it is on the same footing as hilda29e:**

  | | hilda29e | **hilda31w** |
  |---|---|---|
  | chains agree to (CO₂) | ≤ 3.5 ppm, 19–21 % of the width | **≤ 4.76 ppm, 21 %** (median 11 %) |
  | chains agree to (GMST) | ≤ 0.018 °C | **≤ 0.018 °C** |
  | cell R-hat | — | **≤ 1.036** (median 1.017) |
  | bulk ESS, min | 143 | **130** |

  - The worst hilda31w cell is chain 4's 5 % edge at vvH 2150: the excursion's footprint.
  - Late/early width: median 1.03, z +0.4, so the band is not widening (CHANGELOG 10-14 e).
- The ridge's effect on the band is bounded at ≤ 0.28 of the width (10-14 a). The landed chain
  spread is 0.21.

**F4. The lines sit mid-band.** In all 5614 of 5614 cells.

**F5. The band is narrow because it varies only the fitted carbon-cycle parameters.** 5–95 % widths
across the seven scenarios at hilda31w; the 10-09 values are in brackets.

| | 2050 | 2100 | 2150 |
|---|---|---|---|
| CO₂ (ppm) | 2.0–2.8 [2.2–3.1] | 3.5–10.0 [3.6–10.5] | 4.0–23.0 [3.9–22.5] |
| GMST (°C) | 0.009–0.012 [0.010–0.013] | 0.020–0.047 [0.022–0.053] | 0.030–0.085 [0.030–0.098] |
| the lines span, CO₂ | 434–493 | 385–648 | 308–828 |
| the lines span, GMST | 1.84–2.11 | 1.70–3.38 | 1.27–4.62 |

- The widest CO₂ band is still vvH, 22.95 ppm in 2150.
- **The widest GMST band in 2150 is now vvH (0.0847 °C), with vvLN just behind (0.0844).** At hilda29e
  it was vvLN (0.098).

## C. The parameter panel (`app/global.R`, `app_params()`)

- The clause is unchanged ("A single best fit, not yet a posterior — no uncertainty ranges are shown,
  …"), and so is what is true after the lift.
- The lines are the single best fit (MAP); the Futures tab's CO₂ view shows a sampled band around them.
- Elsewhere, ranges are drawn now: FaIR's 5–95 % on card 5a and in the pulse lab (10-12 i, k).
- The panel's own count is computed (`length(md$param_names)`, `ccx_mode_pins(md)`), so it follows the mode.

## D. The temperature sentence (`APP_RIBBON_NOTE_TEMP`, NULL until worded; ruled "Omit it on temperature")

- **Widths: 0.020–0.085 °C at 2100–2150** (10-09: 0.02–0.10), against lines 1.27–4.62 °C apart.
- **Scale:**
  - The widest band at the default selection (Low / Medium / High) is High 2150, 0.085 °C.
  - At the 10-09 scale of about 40 px per °C, that is about 3.4 px. This was not re-measured.
  - For comparison at 2150: Medium 0.051 °C, Low 0.037 °C.
- **Why:** the draws vary only the 31 fitted carbon-cycle parameters, and the climate response and
  non-CO₂ forcing are fixed. So temperature moves only through the CO₂ it is handed.

## Also open on the copy list (not band blockers)

- **The takeaway's tie phrase** (`app_cmap_holder_phrase()`, `app/global.R:939`):
  - It reads "influenced about equally by %s (%.0f%%) and %s (%.0f%%)".
  - At hilda31w it renders "CO₂ level — influenced about equally by Land uptake (34%) and Mixed layer
    & vertical mixing (22%)". That is a tie under the ruled posterior-stability rule: the mode's winner
    loses the row in 12 % of draws, against a 5 % threshold.
  - "About equally" beside 34 / 22 is the wording question. The rule does not depend on it.
- **Card 7's "slightly"** (`app/R/review.R:772`, "The data slightly prefer the literature value"):
  - Measured at hilda31w as **+6.21 log-likelihood** for `k_w` = 1446, against +2.75 at hilda34g
    (CHANGELOG 10-13 q).
  - `hs_asx_frac`'s prior is 88 % of what holds `k_w` higher.
- **Card 8's draft** (`app/R/review.R:781`, key "ocean_climate"): unchanged; see worklist C.
