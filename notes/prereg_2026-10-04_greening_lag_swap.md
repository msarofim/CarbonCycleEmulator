# Pre-registration 2026-10-04: does the land ENSO lag set the SIGN of the greening term?

> **Status.** Written (09:37) BEFORE the driver `calibration/diag_greening_lag_swap.R` ran anything. Committed after one
> SMOKE run (09:42–09:44): every cell at a tiny optimizer budget, to exercise every section. It is NOT a result.
> - ⚠ Two parts of the smoke DID run for real, because neither depends on the cells:
>   - the identity gates (§2), which pass;
>   - §3 C, which reads only the two bases. Its orderings were therefore SEEN before this commit: (i) yes, +6 vs 0 months; (ii) yes, r +0.57.
> - Nothing in this note was changed after the smoke, except this status block.
> - Handoff `notes/handoff_2026-10-04_hilda34g_adopted.md` §4, open item 3.
> - A diagnostic only. It adopts nothing, restamps nothing and moves no stored value. No RNG.

## 0. The reading under test (CHANGELOG 2026-10-03 g, recorded there as UNTESTED)

Adding the lag re-arranged the land's long-term response:
- `npp_tsens` −0.0079 → **+0.0089 /K** (−91 ppm at SSP5-8.5 2300);
- `beta_max` 2.23 → **1.83** (+71 ppm).

The reading: without the lag, a slightly NEGATIVE greening term supplied a LATE El Niño source, because a warm year means less NPP and GMST trails Niño 3.4. That patched the too-early ENSO response. With the timing fixed, the negative term is no longer needed.

Why the mechanism is plausible before any run:
- `npp_tsens` multiplies NPP by exp(`npp_tsens` × GMST), on the IGCC annual-mean GMST column (`R/model.R`).
- That column is a natural spline through the annual means, centered on each year's midpoint (`ccx_annual_to_monthly()`, `R/forcing.R`).
- So a warm year's signal peaks around mid-year, roughly 6 months after a December Niño 3.4 peak. The observed growth peaks 5 months after the index (10-02 x).

## 1. Hypotheses

- **H1 (the reading):** the lag sets the sign of `npp_tsens`, through the year-to-year GMST channel.
- **H2:** the lag does NOT set the sign. The flip rode on the OTHER names' moves in the joint refit, a re-arrangement along the greening–fertilization ridge that the lag did not cause.
- **H3:** the lag sets the sign through a DIFFERENT channel, e.g. the seasonal rows (the lag buys `co2_seasonal_SPO` +4.43) or the land-sink level rows.

## 2. Design

**Two bases, three lags.**
- Bases:
  - LAG = `hilda34g`, the lag arm, L = 2.644 months;
  - CTL = the lag-0 control refit, `refit_20261003_obj15_hilda_csl3v0kaidgb/`.
- Lags: L ∈ {0, 2.644, 5}. 5 is the observed growth timing (10-02 x); that column is descriptive only (§4, for open item 2).
- Scoring:
  - L = 0 is scored EXACTLY, under the lag-0 label `hilda_csl3v0kaidgb`.
  - L > 0 is scored under `hilda_csl3v0kaidgbe`.
  - Both use the arms' common nine pins.
  - Cells are compared on LIKELIHOOD (#15's 27 rows) across lags, since the lag's flat prior and logit Jacobian sit in the logpost.

**The land block, re-optimized in every cell on the #15 logpost; all other names held at the base:**
- the 8 names `npp_tsens`, `beta_max`, `fert_k`, `gamma_enso_land_NH`, `gamma_enso_land_SH`, `luc_scale`, `imb_share_land`, `ndep_ret`.

**POWER, measured before the design was fixed** (each base's stored Hessian):
- With this block free and the rest held, `npp_tsens`'s sd is 0.00832 /K at LAG and 0.00751 at CTL. That is **0.93 and 0.94 of its MARGINAL sd**.
- The 5-name block {`npp_tsens`, `beta_max`, `fert_k`, the two amplitudes} reaches only 0.77–0.78. Its "follows the base" answer would have been a null with no power.
- The observed flip (+0.01675 /K) is 1.9–2.1 marginal sds, so it is reachable.

**Optimizer:**
- The search runs in coordinates whitened by the base's block precision (the stored Hessian): BFGS, then a Nelder–Mead polish.
- Convergence: every whitened slope at the optimum is < 0.1 (the optimum lies < 0.1 conditional sd away, the refit read's `RD_MODE_TOL` convention).
- **Two starts per cell**: the base's own block, and the OTHER arm's block.
  - The other arm's block is H1's answer as a start in the cross cells; the own block is H2's.
  - If both reach the same point, the answer does not depend on the start. If not, a second basin is reported, not resolved.

**Identity gates (must hold, or the read stops):**
- Each base at its own lag with its own block reproduces its stored logpost to 1e-6 (LAG −1182.991369, CTL −1196.101711).
- There, the optimizer does not move (every slope < 0.1).
- Each base's own-cell run reproduces the refit read's timing (growth peak +1 / −2 months) and SSP5-8.5 2300 CO₂ (1448.6 / 1476.2 ppm).

## 3. Predictions and how they are read

**A (primary). The lag's share of the flip.**
- For base B: f_B = [ν*(B, 2.644) − ν*(B, 0)] / (ν_LAG − ν_CTL), where ν* is the block-optimal `npp_tsens`.
- H1 predicts f ≈ 1; H2 predicts f ≈ 0.
- **The criterion is an ORDERING of two measured quantities, not an invented number.** Does the lag (with the block free) carry MORE of the flip than the held names do?
  - **f > 0.5 in BOTH bases, and ν* < 0 at L = 0 and > 0 at L = 2.644 in both** ⇒ the lag sets the sign. **H1 or H3; B decides which.**
  - **f < 0.5 in both** ⇒ the held names carry the flip. **H2.**
  - **Otherwise** ⇒ AMBIGUOUS, reported as such, with both bases' numbers.

**B (channel). Which rows carry the npp_tsens move**, at the two cross cells (LAG at L = 0, CTL at L = 2.644).
- The gain from freeing `npp_tsens` = the cell's streams minus the same cell re-optimized with `npp_tsens` HELD at the base's value (the other 7 names free).
- Groups:
  - SEASONAL (`*seasonal*`);
  - LEVEL (`co2_level_*`, `d13c_level_*`);
  - GCB (`gcb_*`);
  - ICE (`*icecore*`);
  - the rest.
- H1 predicts LEVEL + GCB carry the larger share; H3-seasonal predicts SEASONAL does.
- Read by ordering: whichever group carries the largest positive share names the channel.
- ⚠ A LEVEL or GCB row sees the trend and the year-to-year content at once. B cannot split them inside one row; C speaks to the timing.

**C (the mechanism's premise).**
- At each base, the greening term's own growth signal is growth(ν) − growth(ν = 0), all else held.
- It is set against the land ENSO term's own signal, growth(γ) − growth(γ = 0).
- Both use section 6's estimator of the refit read (centered 12-month difference, ns(df 5) detrended, 1980–2024), cross-correlated with Niño 3.4 over −6 … 18 months.
- H1 requires two ORDERINGS:
  - (i) the greening signal's peak lag is LATER than the ENSO term's at the control;
  - (ii) at ν < 0, its correlation at that peak is POSITIVE (El Niño ⇒ more growth).
- The amplitude ratio sd(greening) / sd(ENSO term) is reported; no threshold is set on it.

## 4. Descriptive, for open item 2 (no prediction)

At L = 5 the read reports for each base:
- the block's optimum;
- the likelihood cost against L = 2.644;
- the growth timing;
- SSP5-8.5 2300 and vvH 2300 CO₂ (section 7's conventions).

This shows what pushing the lag toward the observed growth timing would do to the greening–fertilization split and the futures. It is a conditional slice, not a refit.

## 5. What this cannot show

- It is CONDITIONAL. 26 names stay at each base. The joint answer is a refit's.
- An "H1 or H3" verdict says the lag DRIVES the sign. It does not say which sign is right for the future. The greening–fertilization split is still weakly identified by the historical record (`laplace_fails_on_fertilisation_ridge`).
