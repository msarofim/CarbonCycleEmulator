# ASSESSMENT — CarbonCycleEmulator at `hilda33p`, release BETA v1.0 CarboTope (2026-10-06) — ⚠ DRAFT EVIDENCE, NOT A VERDICT

**Marcus (2026-10-06), on the 10-06 handoff's open item 2: "Assessment → hilda33p (Recommended)"**, put to him as
"re-base the 10-04 draft's evidence sections (§1–4, 6, 8) on hilda33p … §5 verdict and §7 acts stay your
placeholders". This note SUPERSEDES `notes/assessment_2026-10-04_hilda34g_DRAFT.md`, which now points here, and keeps
its sections. It gives the model as it stands, judged against the 09-03 standard, with every remaining flaw named
and classed.
**§5, the VERDICT, and §7, the acts, are Marcus's and are left as placeholders.**

**Sources.**
- Unless cited otherwise, every number comes from the scorecard with hilda33p as the canonical and hilda34g as the
  comparison arm, `outputs/diagnostics/whole_model_scorecard_20261006_hilda33p.{log,rds}`, at `7915464` (clean).
  - It reproduces 10-05 (p)'s scorecard of the same vector (then the extra arm "obj16", at `263d5f0+dirty`)
    **line for line**: all 18 of the arm's gate, comparison, prior and reproduction lines are identical.
- Modern NPP: `outputs/diagnostics/d4_readout_20261006.{log,csv}` (same tree).
- The adoption's reads: `obj16_refit_read_20261005.log` (the likelihood, the futures, the land's net climate
  effect), `obj16_row_split_20261006.log`, `ocean_climate_gobm_20261005_obj16.{log,rds}`,
  `app_wobble_shares_20261006_hilda33p.log`, `pulse_vs_tcre_20261006.log`,
  `warming_switch_split_20261006_hilda33p.log`, all under `outputs/diagnostics/`; the Hessian,
  `calibration/output/refit_20261005_hilda33p_obj16_hilda_csl3v0kaidgbem/hessian_20261005.log`.
- The objective is **#16**. Every logpost is comparable only within it, and **arms are compared on LIKELIHOOD over
  its 27 rows**: hilda33p's logpost carries the pinned `npp_tsens`'s own prior term, which no #15 mode has.

---

## 0. The standard (unchanged; 09-21 §0)
A pedagogical model, not an emulator: **the product is the CHAIN**. Constraining the model with seasonal and isotopic
data should make long perturbation lifetimes emerge. A defect BLOCKS release only if it breaks a link. A benchmark
miss with the right mechanism is a research question. Joos 2013 never scores the model (gates 12 and L are
comparisons).

## 1. What changed since 10-04 (`hilda34g`, objective #15)
- **Objective #16** (rulings 10-04 m and 10-05 d; built 10-04 n; refit 10-05 f–p):
  - **the stratification feedback** (DESIGN §3.4a S): thermocline mixing weakens as the surface warms. Its strength
    is FIXED from an observation × a law, not fitted (s 0.0522 /K from Cheng et al. 2025's N² trend; q 1, Gargett
    1984; τ_d 195 yr, CCX's own climate module, model-derived and named);
  - **`npp_tsens` PINNED at 0** (P4): the record cannot fix the greening term's sign (0.99 sd from 0; CHANGELOG 10-06 a),
    and the futures had extrapolated it 6× to 2300.
- **The canonical is `hilda33p`**, adopted 10-06 (a) **on physics**, not on fit:
  - likelihood **−1145.0186** on the 27 rows, **−1.7678** against hilda34g (−1143.2508); ΔAIC +1.5 at one fewer
    fitted name, below the usual 2, so the record does not discriminate. The last two adoptions were won by +14.9
    and +10.7;
  - the split (`obj16_row_split`): the feedback −0.9262, the pin and the refit −0.8417. `co2_icecore`'s −1.10 is all
    the pin's and the refit's; the GCB rows' −0.31 is the feedback's;
  - **33 names are fitted and ten held** (hilda34g's nine + `npp_tsens` = 0). Logpost −1187.451837. Hessian PD,
    condition **2.73e5** (hilda34g 1.6e6), no |r| > 0.8;
  - the refit's compensations, each within 0.64 of hilda34g's marginal sd: `beta_max` 1.83 → 2.08, `luc_scale`
    0.877 → 0.900, `kz` +1.8 %;
  - the land ENSO lag **2.61 ± 0.41 months** (hilda34g 2.64 ± 0.39).
- **The release moved:** "BETA v1.0 CarboTope" is cut on hilda33p ("Move v1.0 to the new mode").
- **The `k_w` price arm was read** (10-05 a): Naegler's 1446 m/yr fits BETTER on likelihood (+2.75). Its whole −20
  posterior price is ONE prior, `hs_asx_frac`'s, at z +6.5, whose width is a stated judgement. Kept. At hilda33p
  `k_w` is 1894.7 ± 53.7.
- **H1 was tested** (10-05 c): the high-latitude box carries only ~18 % of the ocean's thermal climate effect. The
  excess lives in the low-latitude column, which leaves H2 (§4.5).
- **The What-if tab at hilda33p:**
  - ENSO off removes **36 %** of the wobble (`app_wobble_shares`); the blurb keeps "about 40 %" (ruled 10-06);
  - ENSO off moves the typical miss 0.37 → 0.41 ppm/yr, "10% further from the data" (the live app, 1980–2024;
    hilda34g 0.38 → 0.42, 11 %);
  - the warming switch now also removes the mixing slowdown, and its caveat says so (10-06 c).
- **Engineering, no mode moved:** the multistart's in-restart deadline (option A, 10-05 b); its budget on the CPU clock
  on the Mac (10-05 q); the end-of-run eval rate corrected (10-06 d); one git stamp for every driver (10-06 e).

## 2. The gates at `hilda33p`
| gate | reads | verdict | class |
|---|---|---|---|
| D | hemispheric air–sea δ¹³C disequilibrium asymmetry +0.091 vs the bottles' +0.286 ± 0.029, z −6.72 | FAIL | structural (09-21 §1, unchanged) |
| GL / H | the MLO−SPO δ¹³C gradient 1.95× observed (−0.1303 vs −0.0668), z −7.11; R_co2 0.874; contrast z +12.02 | FAIL | structural (09-21 §1) |
| V | interannual sd 0.565 vs 0.933 ± 0.084, **0.61×**, z −4.39 (hilda34g −4.60) | FAIL | structural (a FAIL is not a blocker, Marcus) |
| 5 | bomb ¹⁴C: SH peak height (`sh_v`) z +10.63, NH e-folding z −7.15; both orderings ok | FAIL | repaired 10-02 (W4); fails at every registered mode, as ruled |
| the AIC gate | the canonical vs the seas_ml-0 control (`hilda31pe`) | PASS in the suite at `fb8036a` | accounting. On the scorecard's shared rows (the two moved GCB rows excluded) the canonical leads by **+30.90** at 33 vs 31 free names (hilda34g +32.31 at 34) |
| G | ocean anthropogenic-C inventory: se 18.6, z −0.020 (inventory +1.98 %) | PASS | — |
| Q | global air–sea δ¹³C disequilibrium +0.562 vs Quay 0.60 ± 0.10, n_sd 0.38 | PASS | — |
| 7 | 2010s sinks: ocean 3.14 (z −0.27), land 3.08 (z +0.87) GtC/yr | PASS | — |
| S | SPO seasonal ocean limb 0.205 ppm at month 8.47, in [7.41, 10.41] | PASS | — |
| 6 | MLO seasonal-amplitude growth 1960s → 2010s: +14.80 % vs +15.57 % (se 3.44 pp), z −0.22 | PASS | — |
| P7 | the seasonal mixed layer is not a vertical-gradient lever (0.08× its bound) | PASS | — |
| 11 | 21 series screened; no flags | — | screen |

**No verdict flips against hilda34g.** **The free parent:** as for hilda34g, hilda33p has none, so the pins' price
under #16 is not measured.

## 3. The chain, link by link
1. **Seasonal cycle.** GATE S passes (0.205 ppm at month 8.47), and GATE 6 passes: the amplitude GROWTH is within
   0.22 se of the record. `sst_seas_amp_*` stays a named shim (§6).
2. **Isotopes.** The bomb curve, the deep Δ¹⁴C profile, the Suess decline and the ocean's ¹³C gradient (P7 PASS) hold.
   The isotopic reds are D and GL (¹³C hemispheric structure), plus gate 5's repaired bomb-shape statistics.
3. **The sinks and their variability.** GATE 7 PASSES.
   - The ENSO ocean slope is **0.86× GCB** (+0.0990 ± 0.0426 vs +0.1153 ± 0.0246). It is carried by the layer-3 limb
     at 13.18 Sv per index unit; the solubility path alone is still wrong-signed (−0.185).
   - The land ENSO term arrives 2.61 months after the index (§4.2).
   - **The land's net climate effect, 2015–24, is −0.038 GtC/yr**, the sign of GCB 2025's DGVMs (−0.8 ± 0.7, z +1.09).
     hilda34g's was +0.118 (z +1.31). The pin moved it.
   - **The ocean's climate effect, like-for-like with GCB's ocean models, is −0.375 ± 0.028 GtC/yr: 1.87× GCB's
     −0.20 ± 0.05** (−3.50 GCB sigmas; hilda34g −0.357, 1.80×). Its parts: SST −0.452, the ENSO limb +0.097, the
     stratification feedback −0.020. The GMST-historical twin reads −0.355 (1.77×). (§4.5.)
   - GATE V FAILS at 0.61×.
4. **What emerges** (a comparison, not a gate):
   - IRF(20 / 100 / 300) **0.516 / 0.366 / 0.274** against Joos 2013's 0.596 / 0.409 / 0.322. The gap at 100 yr is
     0.043 (hilda34g 0.035): slightly further below Joos.
   - The 1000-yr partition is **land 16 / ocean 61 / air 22 %** against Joos's 16 ± 7 / 59 ± 6 / 25 ± 4.5 (1 s.d.),
     z **+0.04 / +0.38 / −0.58**.
   - The pulse box reads **about 1.4 °C per 1000 GtC** (ruled: "about" = within 0.1) at +20 / 50 / 100 / 200 yr:
     1.448 / 1.379 / 1.358 / 1.402 (`pulse_vs_tcre_20261006`). The spread across pulse sizes is 2.5 %.
   - **The futures:** CO₂ in 2300 is **+12.9 ppm** under SSP5-8.5 and +7.8 under vvH against hilda34g. The
     feedback's direct part is +5.5 / +2.9; the pin and the refit's re-arrangement are +7.4 / +4.9.
   - **The What-if warming switch** removes 5.70 ppm of 2024's CO₂ (426 → 420): seawater 4.90, soil respiration
     0.63, the mixing slowdown 0.15 (`warming_switch_split_20261006_hilda33p`).

## 4. Named tensions and open quantitative statements
1. **D4, modern NPP:** **66.83 GtC/yr, z +1.39** against 56.06 ± 7.75 (exclusive, as ruled; hilda34g 66.31, z +1.32).
   Beside it, +0.63 GtC/yr is retained via N deposition (gross: `ndep_ret` 12.83 kg C/kg N × 48.9 Tg N/yr). It stays a
   named tension.
2. **The lag vs the atmosphere's timing.** The rows that set the lag want ~2.6 months; the observed growth wants ~5.
   **RULED 10-04 (j): no timing row; a card-4 disclosure instead** ("No row; draft card-4 text (Recommended)"). The
   card-4 wording is still open (§6.5).
   At hilda33p the model's growth peaks **1 month** after Niño 3.4 (r 0.68), as at hilda34g; the record's peaks at
   5 (r 0.50) (`enso_growth_fit_20261006_hilda33p`, T2(b)).
3. **The greening sign: closed by ruling.** `npp_tsens` is pinned at 0 (P4, 10-05 d). The app's parameter table
   marks it "held", with the other nine pins (10-06 c).
4. **`k_w` sits at ~1895 m/yr against Naegler's 1446.** The price arm (10-05 a) says the data alone would take 1446
   (+2.75 on likelihood); the posterior keeps ~1900 because of ONE judgement-width prior, `hs_asx_frac`'s (§6.5).
5. **The ocean's climate effect is 1.87× GCB's, like-for-like** (§3.3). The excess is THERMAL: at hilda34g the SST
   part alone (−0.45) was 3.4× one GOBM's warming part under the same protocol (10-04 p), and at hilda33p it is
   −0.452. H1 found the high-latitude box carries only ~18 % of it; **H2**, kz's strong vertical exchange, is
   deferred. H1's observed-ratio arm needs a gridded SST download (§6.5).
6. **Uncertainty.** The app shows no bands. They are HELD by ruling (10-02, after the MCMC check): the Laplace band
   failed its check, and the sampler did not converge on the fertilisation ridge.
7. **Strained priors (|z| > 2):** `q10` −2.53, `kz_deep_frac` −2.79, `pump_hs_gcm2` +2.15, **`rep_dC` +4.16**, the
   same four as at hilda34g. The last is the named shim the ice-CO₂ cut freed to take up the station offset (10-03 g).

## 5. VERDICT — [Marcus]
> *Placeholder.* The 10-01 question was whether this is a product-ready version despite the remaining flaws. The
> evidence above is what changed under it.

## 6. What "final" would NOT mean — the items carried OUT (re-checked 10-06)
1. **The σ audit's three objective items** are unchanged and unruled:
   - `gcb_ocean_sink`'s 0.4 GtC/yr uninflated σ;
   - the `excess_c14_ocean` target set;
   - `CCX_ICE_DISCREPANCY`.
2. **The stand-ins:** the 09-16 review's five, over seven names (card 7). At hilda33p three are HELD at 0
   (`ent_seas_amp_SH` and the ocean ENSO pair), as at hilda34g. `npp_tsens` is held too, but is not a stand-in.
3. **Eleven constants are still `provisional`**: 11 of the 79 entries of `CCX_CONSTANTS`, 6 of them retired
   (`ccx_check_constants()`), the same eleven as 10-01:
   `OCEAN_DEPTH`, `ALK_SURFACE`, `ALPHA_PHOTO_EPS`, `PUMP_EPS13_ORG/CARB`, `NPP_GLOBAL_PI`, `NPP_FRAC_NH_ANCHOR_1750`,
   `ALPHA_AS_FCO3`, `ALPHA_AS_DOWN/UP_LEGACY`, `ENT_SEAS_BAND_AREA_FRAC`. The five entries added since 10-04 are the
   stratification feedback's (`MIX_STRAT_S` and `MIX_TDEEP_TAU` derived; `MIX_STRAT_Q`, `_Q_LO`, `_Q_HI` cited).
4. **The 10-01c review §C items** are still unruled, as listed in the 10-01 draft §6.4, except Q5: it was answered
   10-02 (w) (no newer pulse-response quantification than Joos 2013; IPCC AR6 WG1 §7.6.1.1).
5. **New since 10-04:**
   - H2, kz's vertical exchange (deferred);
   - `hs_asx_frac`'s judgement width, which holds `k_w` at ~1900 (kept);
   - H1's observed-ratio arm (needs Marcus's permission for a gridded SST download);
   - the card-4 wording for the timing disclosure;
   - extending the substep fix's held-K rule to `ccx_tr_box_eigbound()` (optional; no registered mode would move);
   - the resume of #16's 8 sleep-affected starts (not chosen 10-06; the survey found one basin).

## 7. What the freeze would BE (the acts) — [Marcus]
- **The model:** canonical `hilda33p`
  (`calibration/output/refit_20261005_hilda33p_obj16_hilda_csl3v0kaidgbem/mode_fit_pumpN.rds`, via `ccx_mode_file()`).
  - 33 fitted names and ten held.
  - Likelihood −1145.0186 on 27 rows, logpost −1187.451837.
  - Hessian PD (cond 2.73e5).
- **The objective:** #16.
- **The suite:**
  - at `fb8036a` (the adoption's ledger): **6294 passed, 0 failed, 3 skipped, 0 errors**;
  - at `658ccd7` (10-06 c–e: the app wording, the eval-rate fix, the git-stamp merge): **6412 passed, 0 failed,
    3 skipped, 0 errors** (`outputs/diagnostics/suite_20261006_658ccd7.log`).
- **A version tag?** [Marcus.] `v1.0-hilda29l` marks the 09-22 freeze. The app's release name, BETA v1.0
  CarboTope, now runs on hilda33p.
- **The product:**
  - the app runs the canonical live, with no bands (held);
  - the Known-issues tab shows cards 1–7;
  - README and DEPLOY.md name the release.

## 8. What would re-open it
- H2, if taken up (the ocean's 1.87× climate effect);
- a different width for `hs_asx_frac`'s prior (it would move `k_w` toward 1446);
- a ruling on §6.1;
- freeing `npp_tsens` again, or a timing row (both declined; each would be an objective change and a refit);
- an interhemispheric deep exchange (declined 09-23).
