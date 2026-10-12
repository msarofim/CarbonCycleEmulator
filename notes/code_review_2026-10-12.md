# Pre-beta code review, 2026-10-12

Marcus, verbatim: "Do one more full code review of the model to make sure there are no bugs or
inconsistencies. Then push it."

- **Code reviewed:** `8891c04`. No `R/`, `src/`, `app/`, `data/` or `calibration/lib_*.R` change since `54dde08`, where the full suite ran: 7279 passed, 2 failed (card 4's two, by design), 3 skipped.
- **Method:** seven read-only reviewers in parallel, one lane each. They were told to:
  - work on the canonical's live code paths first;
  - DEMONSTRATE every finding;
  - check CHANGELOG / DESIGN before calling anything a bug.
- **Verification:** the main session re-checked the findings marked **[verified]** below. The rest are the reviewers' measurements.
- **Evidence:** reviewer scripts and logs are in `outputs/diagnostics/code_review_20261012/L1…L7/`. They are UNREVIEWED as code.

The lanes:

| Lane | What it covered |
|---|---|
| L1 | Parameters, geometry, constants |
| L2 | `ccx_deriv` |
| L3 | Integrator, `ccx_prepare`, R↔C++ parity |
| L4 | Forcing, coupled climate, ¹⁴C tag, PD100 |
| L5 | Spin-up, mode resolution, provenance |
| L6 | Objective, MCMC |
| L7 | How the app drives the model |

**Bottom line.**
- The model's mechanics are clean at the canonical: conservation, R↔C++ parity, spin-up, stability, logpost reproduction, and pulse pairing.
- **One live bug is in the OBJECTIVE (§1).** It touches the fitted mode, so it is Marcus's decision.
- **Five wrong-number bugs are in the APP (§2).**
- The rest are rule debts, stale documentation, dormant paths, and test-coverage gaps.

---

## 1. LIVE, in the objective — the IntCal Δ¹⁴C row's σ is in ¹⁴C YEARS, used as ‰ [verified]

**Where:** `data-raw/build_calibration_data.R:244-250` builds `data/obs_d14c_intcal20.rds`; `R/likelihood.R:2670` scores it.

**What the code does.**
- `rintcal::ccurve(cc = 1)` returns three columns. The code names them `calBP`, `C14BP`, `err`.
- It converts `C14BP` (a radiocarbon AGE) to Δ¹⁴C correctly, but keeps `err` unconverted.
- The likelihood then uses `sqrt(err^2 + LIK_D14C_REP_OTHER^2)` (`LIK_D14C_REP_OTHER` = 4 ‰) as a σ in ‰.

**The published file** (`https://intcal.org/curves/intcal20.14c`, read 2026-10-12) has the header `CAL BP, 14C age, Sigma, Delta 14C, Sigma`. Rows from it:

| CAL BP | 14C age | Sigma (yr) | Delta 14C (‰) | Sigma (‰) |
|---|---|---|---|---|
| 250 | 110 | 9 | 16.7 | 1.2 |
| 100 | 124 | 10 | −3.4 | 1.2 |
| 0 | 199 | 11 | −24.5 | 1.4 |

So the stored `err` (9–11; the row's summary is min 9, max 11, n = 251) is the AGE sigma. The published Δ¹⁴C sigma is 1.2–1.4 ‰. CCX's Δ¹⁴C itself is right: 1700 CE gives +16.7, as published.

**Size, measured by L6 at the canonical:**

| | as coded | units-consistent |
|---|---|---|
| σ used | 10.57 ‰ | 4.18 ‰ |
| χ²/n | 0.155 | 0.995 |

- The row's weight is about 6.4× too small.
- An implausibly small χ²/n would have been the tell.
- The row's log-likelihood moves −640.62 → −543.76 at the canonical. That is a normalisation shift, not by itself a statement about fit.
- **Fixing it changes the objective**, so the fitted `hilda29e` mode, every stored logpost and the MCMC band were all fitted with the wrong weight.
- Nothing in CHANGELOG / DESIGN / memory records this choice.

**The data-correct fix:** use the published Δ¹⁴C sigma (column 5), not a derivative conversion of the age sigma. `rintcal::ccurve()` does not return column 5, and `rintcal` is no longer installed here.

**Decision owed (Marcus):** measure the impact first, refit, or ship as a documented known issue.

## 2. LIVE, in the app — numbers on screen that are computed wrongly

| # | Where | Defect | Status |
|---|---|---|---|
| A1 | `app/server.R:889-896`, Scenarios takeaway | The span is taken from the FIRST and LAST ticked scenarios, not the min and max. All 7 ticked prints "366 to 825 ppm, 1.5 to 4.6 °C"; the truth is 305–825 ppm, 1.3–4.6 °C. {VL, LN, L} prints "366 to 367"; the truth is 305–367. The default {L, M, H} happens to be right. | [verified] code |
| A2 | `app/server.R:67`, Keeling takeaway | `which.min(abs(o$t - 1958))` is an exact tie between the Dec-1957 and Jan-1958 month centres; the first wins, so it prints "in 1957". The same tie hits `server.R:685` (Dec 1849 for "since 1850"; no year is printed there). | [verified] code |
| A3 | `app/server.R:69, 92`, Keeling takeaway | "Today" is ONE month (Dec 2024) of the raw NH box (the chart's FAINT line, 427 ppm). It is set against an MLO mean over a typed `year >= 2023`: 39 months, running past the run's end. The scored line's 2024 mean is 422.8. The +3 ppm "gap" is mostly `rep_dC`, the offset the 09-22 like-for-like fix took off the chart. | reviewer |
| A4 | `app/server.R:168-169`, `w_luc_note` | The net-sink crossing year is computed from DIFFERENCED ANNUAL MEANS. That is the half-year-offset construction `app_sinks_annual` was fixed away from on 09-24 (o) for the other two panels on the tab. It prints 1970; the calendar-year construction gives 1969. | [verified] code |
| A5 | box diagram (`app/R/plots.R:1670, 1681`, from `APP_FLUX_NOW`, 2024) | Three effects on the warm "to the deep" arrow. **(a)** It double-counts the cold route: `fluxes.R:95-96` says `hs_pump` is inside `pump` and `hs_hd_net` inside `ml_int`, and the cold arrows draw them again. The printed "63 down … 61 back up" would be about 59 / 59 warm-only. **(b)** The layer-2 ENSO limb writes `dy` outside the flux trace: 0.28 GtC/yr missing in 2024, 1.06 in 2015. **(c)** The trace samples month-OPENING states, which aliases the SH seasonal-ML entrainment: trace-mean d(ML C)/dt is 1.208 against an integrated 0.431 GtC/yr (2024). `ocean_net` is unaffected. | (a) [verified] code; (b), (c) reviewer |

Also live, but it is COPY (Marcus's):
- **A6 — the pulse box's fixed sentence** "about 1.4 °C per 1000 GtC from any time period between 20 and 200 years" (`app/global.R:1058-1087`).
  - It was measured on `vvM` with a 2050 release, and it is shown under every background.
  - The measured range is 1.43–1.69 on `vvLN` and 1.12–1.47 on `vvH`. At vvH / 2100 / 500 GtC the app prints "1.12 °C per 1000 GtC", then "about 1.4".
  - The size-insensitivity half of the sentence holds.

## 3. Rule debts on the LIVE path (CLAUDE.md hard rule 2: no uncited constant in code)

- **Provisional ledger entries read by the canonical:**
  - `PUMP_EPS13_ORG` (−20 ‰, "recollected, NEEDS a cited source");
  - `PUMP_EPS13_CARB`, `ALK_SURFACE`, `ALPHA_AS_FCO3`, `OCEAN_DEPTH`, `NPP_GLOBAL_PI`.
  - All are tracked in `test-constants.R`. The constants header says provisional values "must not survive into published results", and the beta is public.
- **Uncited and outside the registry:**
  - obliquity −23.44° and the +10-day solstice offset (`R/model.R:340`, `src/ccx_core.cpp:375`);
  - `CCX_SEAS_PHI_EFF`, `CCX_SEAS_T_LAG`, `CCX_SST_SEAS_LAG`, `CCX_ENT_SEAS_PEAK_MO` (in `model.R`);
  - `FORC_BOMB_NH_SHARE` 0.90 and `FORC_NUC_NH_SHARE` 0.95 (`forcing.R:113-115`; flagged PROVISIONAL in CHANGELOG, not ruled);
  - `P_canon`'s 2.04 atoms cm⁻² s⁻¹ and Earth's area (`spinup.R:205`), which also re-types `.SEC_PER_YR` / `.AVOGADRO` (forbidden by `constants.R:24-31`);
  - `CCX_BOMB_REF` 102 (cancels);
  - `JOOS_PPM_PER` 2.123 (`joos_irf.R`).
- **`bomb_total`'s prior width** (log-sd 0.10, `calibrate.R:870`) has no source. DESIGN §5.1 still marks P_bomb [VERIFY]. The canonical fits 118.87 against Naegler & Levin's 99.3–104.9.
- **`ALPHA_PHOTO_EPS`:** the registry says "IN USE: 18" (`constants.R:301-308`). Every adopted mode runs 15.6 (`CCX_ALPHA_PHOTO_EPS_BIOSPHERE`, `calibrate.R:2303`, ruled 09-14 h and cited there) [verified]. So the live value lives outside the registry, and the registry text is false.

## 4. Inconsistencies — code vs its own docs, labels or other files (no wrong number shown)

- **Splice wording.**
  - `R/climate.R:187-190, 270-272` say the obs→model GMST splice makes "the join continuous" / "no step". It matches 11-yr MEANS, so annually there is a −0.121 K step 2024 → 2025 on vvM (2024 was a warm year).
  - It also cites `OBS_SPLICE_YEARS`, which does not exist (the window is a literal `last - 10`, copied at `joos_irf.R:363`).
  - The method is the standing multi-year convention. The WORDS are wrong, and an undergrad sees a drop.
- **PD100 time axis** (`joos_irf.R:318, 321`): the forward table's labels run a year behind real time, so AOD enters a year early and "release at 2015" is real 2016.0. Measured as negligible: IRF(100) 0.37912 → 0.37921. The held CO₂ for the free background is the Dec-2010 opening state, 0.76 ppm off the hold target (`joos_irf.R:413`).
- **Seasonal rows** compare INSTANTS at month centres with monthly MEANS. The first harmonic shrinks by sinc(π/12) = 0.9886. Undocumented; ±0.2–1.2 log-units per row at the mode.
- **Stale labels and comments:**
  - `climate.R:19`: the module is labelled "calibration 1.4.5"; the file is calib 1.6.0. The fitted range is given as 278–1687 ppm; the module says 278–1797.
  - `likelihood.R:59-62, 436-439` and `DESIGN.md:722` say the land-sink σ is inflated; `LIK_LAND_SINK_INFLATE` = 1.0 since 09-16 d.
  - `likelihood.R:151` and `calibrate.R:983` say `rep_dC` −4.19 would be needed; the canonical fits +4.21.
  - `KW_PRIOR_LOGSD`'s citation: the ±3.2 belongs to the uncorrected 15.9.
  - Defaults vs `CCX_PARAM_TABLE`: `kz` 5000 vs 5683.5 ("MUST track"), `tau_ex` 1.3 (rejected station basis), `k_w` 1500 vs 1446. All are fitted on the canonical.
  - P8 seasonal-ML guard (`model.R:1352`): it quotes a 27 m margin; at hilda29e it is 7.6 m (it trips at h_ml ≈ 75.5).
  - Entrainment amplitudes 29.68 / 10.95 vs live 17.76 / 6.55 (`model.R:2154`).
  - The fertilisation pole is "~106 ppm" (`model.R:959`); at `fert_k` 120 it is 156.9.
  - Phase comments 3 months off (`tau_ex_seas_phase`, `seas_phase_NH`; dormant).
  - "SH land centroid" −30 vs the measured −15.12 (`model.R:242`).
  - Header "32 boxes / 96 states"; the canonical has 38.
  - "auto resolves to 4 at every ordinary value" (`model.R:4716`, `cpp.R:474`, `forcing.R:1220`): seas_ml at h_ml 68–75 needs 5–22.
  - The air-sea corner is "caught by NA-retry" (`model.R:4720`); since 09-16 d a retried run is −Inf.
  - `app/global.R:436-439` says the startup flux run takes "~2 s"; the R path is ~110 s.
  - `app/global.R:164-176` and `forcing.R:669-673` say "the pulse lab runs on causal interpolation and the rest of the app does not"; false since 10-01 k (`CCX_EMIS_METHOD_DEFAULT` = "constant").
  - `plots.R:1033` names GCB `atm_growth`; the code uses NOAA MBL.
  - Card 6's title "no uncertainty bands, anywhere" (`review.R:707`) is already false: FaIR bands are drawn on card 5a and in the pulse lab. **ADD to worklist A2.**
- **`pump_grad`** is no longer "exactly the model's bottom-minus-ML gradient" under the HS conduit (calibrate.R:631-640): spun-up 372.6 / 363.0 vs 314.7. With `tau_q` = 0 it is 315.4.
- **The kinetic α_as line** is "used only inside 5–21 °C" (`constants.R:762`). The NH low-latitude SST is above 21 °C in 85 % of months, and every HS evaluation is at 1.6–3.3 °C.
- **Periodic spin-up diagnostics:** `co2` is the annual mean, but `d13c` / `d14c` are start-of-year (`periodic_spinup.R:307`); the printout says −6.473 vs target −6.469 when the annual mean is exactly −6.469. Also: "zeroes four seasonal paths", where the code zeroes three and the behaviour is still right; and stale line citations.
- **`CCX_MODE_RETIRED`** stopped growing 09-17: `hilda30c`, `30h`, `31p`, `30e`, `30s` return "unknown mode" instead of the retirement reason.
- **Typed where they should derive:**
  - `APP_HIST_YEARS <- c(1750, 2024)` (`global.R:51`), while `APP_SPLICE_YEAR` is read from data. A GCB update would move one and not the other.
  - `server.R:69`'s 2023.
  - `APP_FAIR_NOTE`'s "calibration 1.6.0" and "Before 2024" (worklist B10).
- **`app/global.R:211-212`** keeps a literal fallback mode path (`calibration/output/mode_fit.rds`, which has never existed) beside "the ONE place". It is dead, but a hazard.
- **Docs:**
  - CLAUDE.md and DESIGN §8 say `data-raw/constants.R`; the file is `R/constants.R`.
  - DESIGN §6's ledger still names `hilda30c` as the canonical.
  - DESIGN:109 specifies the LOG fertilisation form; the canonical runs MM.
  - CLAUDE.md:55 and DESIGN:613/1417 say "bit-parity"; it is roundoff parity, documented in `ccx_core.cpp:17-25`.
- **Latent `$` partial-matching hazard.** Names that prefix other names (`fert_k` / `fert_k_prior`, `beta` / `beta_max`, `kz` / `kz_*`, `tau_ex` / `tau_ex_seas_*`, `sst_eq` / `sst_eq_enso`, `sst_tr` / `sst_tr_enso`) break the stated rule at `model.R:2094`. Demonstrated: with `fert_k` deleted and `fert_k_prior` = 1, `ccx_fert_factor(400)` silently uses K = 1. Latent, because `ccx_overlay_par` refuses deletions and the canonical carries every name.
- **Misplaced roxygen blocks:** `model.R` 531, 345, 1349, 4855; `cpp.R:186`; `paths.R` 685, 760.

## 5. Dormant bugs (wrong, on a path the canonical and the app do not run)

- `ccx_is_diagnostics` with one surviving draw returns k-hat −Inf, so `k_ok` is TRUE (`importance.R:54-61`).
- `ccx_run_mcmc()` cannot sample the canonical: it stops on the open gate and starts from the table inits. The live band came from `run_mcmc_check.R`. Its docstring claims otherwise.
- A NULL `err$sigma_d14c` silently zeroes both d14c rows (`likelihood.R:2641`). The objective always supplies it; about 88 diagnostics call `ccx_loglik`.
- `ccx_adopt_mode_band` moves the band but not kz's literal `dunif` prior (`paths.R:1042`, `calibrate.R:384`).
- `ccx_comparable_rows` misses the low-pass switch (`likelihood.R:510`).
- The C++ core never checks the state's row count. Two extra rows ran silently, with d13c_NH −734 ‰; too few would read out of bounds (`ccx_core.cpp:1405-1442`, `ccx_run_prepared`).
- The NA-retry guard reads only month-opening states, so a NaN made in the final month escapes. The app ignores `retried`.
- `ccx_sst_anom_from_gmst`'s seam uses only the forcing's own years: a post-2025 start gives NaN SST, and the core silently falls back to `sst_scale`·gmst (`forcing.R:1383`).
- `ccx_build_forcing` holds emissions flat past the data end with no warning (`forcing.R:641`).
- `ccx_temperature_from_erf` does not flag a late start, contrary to its docs (`climate.R:104-112`).
- `ccx_run_coupled` returns `converged = FALSE` silently; the app never reads it. vvH took 5 passes.
- The conveyor's deep limb uses static `grid$dz` (`model.R:3746`).
- A land-use pulse passed through `emissions` is scaled by `luc_scale` (100 → 91.4 GtC).

## 6. Test-coverage gaps (each measured CLEAN at the canonical by the reviewers; no test pins it)

- `test-conservation.R` runs on the 32-box defaults. None of HS/HD, inert, seasonal-ML entrainment, L2, mix, ndep, the ENSO GPP term, LUC or GMST/SST anomalies is exercised. Its ¹⁴C check turns transport off.
- `test-parity.R` runs `ccx_default_params()`. Each canonical mechanism has its own parity test, but the canonical itself never runs through both cores.
- `test-spinup.R` runs aseasonal defaults, where RK4 steps are below float precision and drift reads exactly 0. There is no zero-emissions-drift test on the canonical's periodic state. DESIGN §6 calls gates 1–3 "mode-independent contracts".
- `test-fluxes.R` runs with L2 off, so it cannot see §2 A5(b).
- `test-c14-tag.R` does not cover spline interpolation, a full-run land-use pulse, hemispheric placement, or "air ≈ 1 at release".

## 7. Checked and CLEAN at the canonical (the review's power)

- **Conservation** (L2, `ccx_deriv`, sources zeroed): ΣdC ≤ 1.4e-14 and ΣdC13 ≤ 5e-16. For ¹⁴C, ΣdC14 + λΣC14 ≤ 8e-14, at 1750, at a Dec-1997 El Niño month with the L2 floor binding, and at a La Niña month. Uniform-concentration fixed point of every ocean transport ≤ 1.2e-15; ¹⁴C decay reaches every box.
- **Parity** (L3), canonical 1955–1975 from the same state: final state ≤ 1.3e-16 relative; all 28 out columns ≤ 9e-14. Every live branch was read line against line.
- **Stability** (L3): Jacobian peak 74.9 /yr against a controller bound of 81.7 (z 1.56 of an RK4 limit of 2.785). 4 / 8 / 16 substeps agree to 2.9e-3 ppm.
- **Spin-up** (L5): periodic Newton converges in 6 iterations to 1.4e-10 (tolerance 1e-9). A 50-yr quiet run drifts ≤ 8.5e-12 relative per box. ¹⁴C production equals decay to 1e-12 (solved, not shimmed).
- **Mode resolution** (L5): `ccx_mode_file()` → the 10-08 (e) file (md5 bf4732da…). Its record agrees with `paths.R`, and every fitted and pinned name is consumed. No hard-coded older mode acts as a default anywhere in `R/`.
- **Objective** (L6): the canonical's logpost recomputes to −1166.949732 with Δ = 0, and all 26 streams match bit for bit. Prior and Jacobian algebra is right. `run_mcmc_check.R`: symmetric proposal, frozen adaptation, distinct recorded seeds. No `R/`/`src/` change between the chain commits and HEAD.
- **Forcing** (L4): monthly → annual matches GCB to 4e-15. The bomb shape integrates to 1. The ¹⁴C tag's 2×2 solve was checked by hand, and the R/C++ shares agree. The carbonate Newton reaches 7e-15. All 7 mechanism switches conserve to ≤ 1e-10.
- **App** (L7):
  - Every precomputed product's loader refuses a mismatch.
  - The ribbon hold suppresses the band everywhere, and would pass validation if lifted. 17 000 / 17 000 draws ran.
  - The splice matches across tabs to 0.008 ppm at 2024.
  - Pulse/base runs are identical before the release. The tag carries exactly 100 GtC.
  - What-if: bit-identical with nothing off, and 21 combinations ran.

## 8. Suspected, not demonstrated as defects

- **The P8 guard truncates h_ml's posterior.** No pooled draw sits above 75.34 m (0 of 17 000), while the prior band reaches 200. The guard is ruled (10-04 a); its effect on the band's tail is not recorded.
- **The MCMC proposal is too wide.** Post-adaptation acceptance is 5.9–7.5 %, against about 23 % optimal at 29-d. That is consistent with ESS 105 / R-hat 1.046. The MH step is still valid.
- **First pulse-lab point vs FaIR.** In the release year, FaIR's annual mean is a two-endpoint trapezoid and CCX's is the mean of 12 opening states. That puts CCX about 4 % low on that one point (0.446 vs 0.465).
- **No water-vapour correction on pCO₂** (`model.R:2924`). Not ruled, not measured.
- **Absolute-unit ¹⁴C sources** (nuclear, GBq) enter with `/R14_STD` only, with no δ¹³C normalisation. Not measured.
- **The Build-your-own comparison line** is the first TICKED scenario, not the run's own background.
