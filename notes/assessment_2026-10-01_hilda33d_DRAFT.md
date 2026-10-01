# ASSESSMENT — CarbonCycleEmulator at `hilda33d`, release BETA v1.0 CarboTope (2026-10-01) — ⚠ DRAFT EVIDENCE, NOT A VERDICT

**Marcus (10-01, review 10-01c item 12 / B8): "Draft after 1-11 are done."** Rulings 1–11 are applied (CHANGELOG
10-01 (j), (k), (l)). This note follows the 09-21 freeze record (`notes/assessment_2026-09-21_product_ready.md`).
It gives the model as it stands, judged against the 09-03 standard, with every remaining flaw named and classed.
**§5, the VERDICT, and §6, the acts, are Marcus's and are left as placeholders.**

Every number comes from the post-flip scorecard (`outputs/diagnostics/whole_model_scorecard_20261001_hilda33d_emisconst.{log,rds}`,
run on a frozen `git archive` of `508b2bf`) unless cited otherwise. The objective is **#14 with the piecewise-constant
emissions interpolation** (10-01 k). Every logpost below is comparable only within it, and the adoption-time
scorecard (`…_20261001_hilda33d.*`, spline) is NOT.

---

## 0. The standard (unchanged; 09-21 §0)
A pedagogical model, not an emulator: **the product is the CHAIN**. Constraining the model with seasonal and isotopic
data should make long perturbation lifetimes emerge. A defect BLOCKS release only if it breaks a link. A benchmark
miss with the right mechanism is a research question. Joos 2013 never scores the model (gates 12 and L are
comparisons).

## 1. What changed since the 09-21 freeze (`hilda29l`, objective #13)
- **The canonical is `hilda33d`** (adopted 10-01 c on Marcus's conditional ruling). Its label is `hilda_csl3v0kaidgb`:
  hilda29l's structure with the vegetation-capacity loop off (φ = 0), the `fert_k` shape prior, the inert soil pool
  (0–1 m), AOD in anomaly mode, and the D2/D3 gate open. That gate means three things:
  - N-deposition retention: `ndep_ret` 10.19 kg C per kg N, GROSS (net ~7.0);
  - a sign-free greening term: `npp_tsens` −0.0079 /K;
  - a fitted allocation of GCB's imbalance: land 0.593, ocean 0.085.
  33 names are fitted and the same nine held.
- **The emissions interpolation is piecewise-constant** (10-01 k: "I think apply it now").
  - Every registered mode was restamped at its priced move, with no refit.
  - hilda33d's stored logpost is **−1405.411447**, and its likelihood −1369.3386 on 26 rows reproduces to 6e−12.
- **The app** (10-01 j):
  - release **BETA v1.0 CarboTope**, gated against the mode it loads;
  - the AIC card (card 6) retired (its premise turned), and the cards renumbered 1–7 (the app was never deployed);
  - the copy corrected wherever hilda33d had made it false.
- **Uncertainty** (10-01 l): a Laplace band was built and **failed its own check**, so it is held. The MCMC check is
  built and not yet run (§4.3).

## 2. The gates at `hilda33d`
| gate | reads | verdict | class |
|---|---|---|---|
| D | hemispheric air–sea δ¹³C disequilibrium asymmetry +0.097 vs the bottles' +0.286 ± 0.029, z −6.51 | FAIL | structural (09-21 §1, unchanged) |
| GL / H | the MLO−SPO δ¹³C gradient 1.99× observed (−0.1326 vs −0.0668), z −8.31; R_co2 0.890 | FAIL | structural (09-21 §1) |
| V | interannual sd 0.555 vs 0.933 ± 0.084, **0.59×**, z −4.52 | FAIL | structural (09-21 §1; a FAIL is not a blocker, Marcus) |
| the AIC gate | the canonical vs the seas_ml-0 control on the comparable rows (`ccx_comparable_rows()`, B3) | **PASS: the red TURNED** | accounting |
| 5 | bomb-¹⁴C phase / lag | PASS | — |
| G | ocean anthropogenic-C inventory: se 18.6, z −0.064 (inventory +2.26 %) | PASS | — |
| Q | global air–sea δ¹³C disequilibrium 0.551 vs Quay 0.60 ± 0.10 | PASS | — |
| 7 | 2010s sinks: ocean 3.11 (z −0.23), land 3.02 (z +1.22) GtC/yr | PASS | — |
| S | SPO seasonal ocean limb 0.280 ppm at month 8.83, in [7.41, 10.41] | PASS | — |
| P7 | the seasonal ML is not a vertical-gradient lever (0.27× its bound) | PASS | — |

**The AIC gate in numbers.**
- On the scorecard's shared rows (all three arms, the two moved GCB rows excluded), the canonical leads the control
  by **+4.18**.
- On `test-mode-file`'s comparable rows it led by +4.68, measured at `2cee507` before the flip.
- The pre-flip scorecard also read +4.18 to two decimals, so the flip did not move the comparison.
- With two more fitted names, that is ΔAIC ≈ −4.4 in the canonical's favour.

**The free parent.** `CCX_MODE_PINNED_PARENT` is hilda29l's (`hilda32f`, #13). **hilda33d has none** (B3b, option
(i)): the pins' price under #14 has not been measured (option (ii), not ruled).

## 3. The chain, link by link
1. **Seasonal cycle.** The NH cycle is carried by the seasonal mixed layer's entrainment channel; the SH ocean limb
   is inside the GATE S bracket. `sst_seas_amp_*` stays a named shim (§6).
2. **Isotopes.** The bomb curve, the deep Δ¹⁴C profile, the Suess decline and the ocean's ¹³C gradient (P7 PASS).
   The two isotopic reds are D and GL, both ¹³C hemispheric structure.
3. **The sinks and their variability.** GATE 7 PASSES.
   - The ENSO ocean slope is **0.85× GCB** (+0.0979 ± 0.0408 vs +0.115), carried by the layer-3 limb at
     **11.91 Sv per index unit**. That is a little BELOW Meinen's [14, 25], where hilda29l sat inside at 1 sd. The
     solubility path is still wrong-signed on its own (−0.180).
   - GATE V FAILS at 0.59×.
4. **What emerges** (a comparison, not a gate):
   - IRF(20 / 100 / 300) **0.508 / 0.360 / 0.271** against Joos 2013's 0.596 / 0.409 / 0.322. The lifetime is still
     SHORTER than the multi-model mean, but the gap at 100 yr has halved since hilda29l (0.288).
   - The 1000-yr partition is **land 18 / ocean 60 / air 22 %** against 16 ± 14 / 59 ± 12 / 25 ± 9, i.e. z +0.14 /
     +0.07 / −0.31: close to the mean on every term. (hilda29l was 34 / 48 / 18.)
   - The pulse box's warming per 1000 GtC is **about 1.4 °C** at +20 to +200 yr (1.44 / 1.37 / 1.36 / 1.41), 2.5 %
     across pulse sizes. That is nearly flat in horizon: the slower decay now balances the thermal lag.

## 4. Named tensions and open quantitative statements
1. **D4, modern NPP** (`outputs/diagnostics/d4_readout_20261001.*`, after the flip): **67.67 GtC/yr, z +1.50** against
   56.1 ± 7.75, read EXCLUSIVE as ruled (B1). Beside it: **+0.50 GtC/yr retained via N deposition** (gross:
   10.19 kg C/kg N × 48.9 Tg N/yr). It stays a named tension (D4 ruling).
2. **The air–sea isotopic timescale is over-determined by ~15 %** (09-21 §3). Carried, not re-measured at hilda33d.
3. **Uncertainty.** The app shows no bands.
   - A Laplace band was built: 1000 draws, byte-identical twice, the seed recorded and re-run-verified.
   - Scored on the objective, the draws sit a median **25.5 log-units below the Gaussian**, and the **importance ESS
     is 8 of 1000**.
   - The Hessian is right AT the mode, but the posterior is strongly non-Gaussian along the CO₂-fertilisation ridge
     (`beta_max` / `fert_k` / `ndep_ret`): 5× the curvature at 0.2 sd, ~30× at 0.5.
   - So the band was **held** (Marcus). Any stored-covariance spread along that ridge (10-01 (a)'s ±39 ppm) is local,
     not a posterior spread.
   - The MCMC check is built for Torch (`calibration/run_mcmc_check.R`, `calibration/torch/mcmc_check.sbatch`) and
     not submitted: 4 chains × 1e5 iterations, ~16–30 h each.

## 5. VERDICT — [Marcus]
> *Placeholder.* The 09-21 question was whether this is a product-ready version despite the remaining flaws. The
> evidence above is what changed under it.

## 6. What "final" would NOT mean — the items carried OUT (re-checked 10-01)
1. **The σ audit's three objective items.** They are unchanged since 09-21 §4.1 and still unruled:
   - `gcb_ocean_sink`'s 0.4 GtC/yr uninflated σ;
   - the `excess_c14_ocean` target set;
   - `CCX_ICE_DISCREPANCY`.
   Each would mean an objective change and a restamp.
2. **The stand-ins.** The 09-16 review named five stand-ins over seven parameter names (card 7's list). At hilda33d
   three of them are HELD at 0, not fitted: `ent_seas_amp_SH` and the ocean ENSO pair.
3. **Eleven constants are still `provisional`** (of 70; `ccx_check_constants()`), the same eleven as 09-21: `OCEAN_DEPTH`,
   `ALK_SURFACE`, `ALPHA_PHOTO_EPS`, `PUMP_EPS13_ORG/CARB`, `NPP_GLOBAL_PI`, `NPP_FRAC_NH_ANCHOR_1750`, `ALPHA_AS_FCO3`,
   `ALPHA_AS_DOWN/UP_LEGACY`, `ENT_SEAS_BAND_AREA_FRAC`.
4. **Unruled items from the 10-01c review §C:**
   - the pre-launch checklist (both URLs are placeholders);
   - R2's `rep_dC` prior;
   - freeing `ra_ratio`;
   - a century-scale q10 split;
   - the P1 wording;
   - the scenario descriptors;
   - `f_luc_wood` / `kz_deep_frac`;
   - the sink→source caveat;
   - the `INDEX_ccx_phi` listing;
   - two 09-24 questions (Q2, Q5);
   - three unratified edits.

## 7. What the freeze would BE (the acts) — [Marcus]
- **The model:** canonical `hilda33d` (`calibration/output/refit_20261001_hilda33d_obj14_hilda_csl3v0kaidgb/mode_fit_pumpN.rds`,
  via `ccx_mode_file()`). 33 fitted names and nine held. Likelihood −1369.3386 on 26 rows, logpost −1405.411447.
  Hessian PD (cond 1.7e6), right at the mode, and NOT a usable Gaussian along the fertilisation ridge (§4.3).
- **The objective:** #14, with the constant emissions interpolation.
- **The suite at the final state:** `ca14204`, **5534 passed, 0 failed, 0 errors, 4 skipped** (frozen `git archive` + the two git-ignored inputs; `outputs/diagnostics/suite_20261001_ca14204_all.log`).
- **A version tag?** [Marcus.] The existing git tag `v1.0-hilda29l` marks the 09-22 freeze. The app's release name is
  now BETA v1.0 CarboTope on hilda33d.
- **The product:**
  - the app runs the canonical live;
  - no bands (held);
  - the Known-issues tab shows cards 1–7; the bands card (6) keeps its approved text plus one drafted sentence;
  - README and DEPLOY.md name the release.

## 8. What would re-open it
- a ruling on §6.1 (an objective change);
- the MCMC check (§4.3), whose posterior would replace the held band;
- an interhemispheric deep exchange (the structure the D/GL limbs stand in for);
- a refit, which Marcus does not expect soon (10-01).
