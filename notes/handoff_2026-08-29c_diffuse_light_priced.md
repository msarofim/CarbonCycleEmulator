# Handoff — CarbonCycleEmulator, 2026-08-29c
# **THE SEASONAL ARC HIT A STRUCTURAL WALL; A NEW MECHANISM LANDED AND IS CHEAP.**
# **NEXT: one small FACE check on `fert_k`, then plan item ② (`h_ml` C1).**

**Repo:** `~/Documents/2026/CodeProjects/CarbonCycleEmulator/`, trunk `main`, **clean at `8f8394f`**.
**Suite 1222 pass / 2 skip / 0 fail.** Nothing running. 41 commits today; continues
`handoff_2026-08-29b_q10_closed_nh_import_next.md` (itself continuing `handoff_2026-08-29_*`).

⚠ **SESSION CWD WAS `FaIRtoFrEDI/`; ALL THIS WORK IS IN `CarbonCycleEmulator/`.**
⚠ **NOTHING ADOPTED ALL DAY.** `ccx_mode_file()` still resolves `from90`; `gamma_diff` = 0;
`seas_npp_amp_SH` = 0.5027; `seas_lag_p` at the mode. The calibrated 21 are untouched and comparable.

---

## 0. STATE IN EIGHT LINES

1. **The `q10` confound is CLOSED — the wrong way.** Recovery 42.9 % → **21.0/17.0 %**. §1
2. **The seasonal pair is (gross × PHASE), and the phase lever is PROHIBITIVE** at −838. §2
3. ⇒ **The blocker is MODEL STRUCTURE: one scalar `seas_lag_p` serves BOTH hemispheres.** §2
4. **Whole-model status re-measured**: CO₂ excellent, the defects are all structure. §3
5. **AOD series acquired** (CMIP7, hemispheric, 1850–2024). §4
6. **ENSO is a dead end for variability** — r flat across an 11× range. §4
7. **Diffuse-light fertilization BUILT and PRICED: CHEAP (−7.4), and r 0.571 → 0.624.** §5
8. ⇒ **ONE CHECK GATES ADOPTION: `fert_k` +29 % vs the FACE range.** §6

## 1. THE `q10` TEST (item 1 of the old queue) — CLOSED

`diag_q10_controlled_recovery.R`. Lever held, slice moved: recovery **83.6 % (27j) / 42.9–43.7 %
(27q pinned) / 21.0–17.0 % (free)**. **`q10` is NOT the explanation — freeing it moves the number the
WRONG way.** The fraction measures **how much escape the slice allows**, not what the channel
supplies: free `q10` lets the LAND arm run `seas_T_amp_NH` to **4× its observed high end** and stop
imposing the defect (vacancy 0.449 → 0.092 ppm). **Never quote a recovery fraction without its
slice.** [[q10_recovery_is_escape]]

⚠ **Step 2 of that queue (the NH import) has a MEASURED near-null** — 27h's τ grid already cut
NH_origin **0.821 → 0.219 (−73 %)** for a **−1.8 %** move in the SPO total, with SH-local land going
the WRONG way. The import HIDES the overshoot; it does not cause it. [[tau_ex_hides_not_causes]]

## 2. THE SEASONAL ARC — DIAGNOSED, AND THE WALL IS STRUCTURAL

**`diag_gross_cancellation_geometry.R` (12 s).** The two SH land channels at SPO are **152.9° apart**
(NEP 1.3896 @ mo 10.15, respiration 0.0923 @ 5.05), flooring the net at **0.454 × gross**:
**the model cannot cancel more than 54.5 % where CT2022 needs 74.9 %.** At the CMIP6 gross the floor
is **1.183, ABOVE the observed 0.683** ⇒ **correcting the gross makes the cancellation IMPOSSIBLE**;
a (gross, respiration) 2×2 is a guaranteed null. Missing: **11.9° = 0.40 months.**
[[gross_phase_not_amplitude]]

**`diag_price_the_lag.R` (10 min).** `seas_lag_p` is the only free lever that reaches (θ peaks 176.1°
at lag 2.75). **Conditional price −838.3 at lag 2.25 — 24× 27n's lever. The NH pays 94 %**
(`co2_seasonal_MLO` −587, `d13c_seasonal_MLO` −202). **`ccx_core.cpp:386`: `seas_lag_p` is a SCALAR**
shifting NPP phase in BOTH hemispheres, while `seas_npp_amp[2]` / `seas_T_amp[2]` are already
per-hemisphere arrays. ⚠ **The fit WANTS the fix** — at lag 2.25 it raised `seas_T_amp_SH`
**1.04 → 3.49 unprompted**, taking SH-land **1.308 → 1.071**. [[one_lag_two_hemispheres]]

⇒ **Indicated fix: `seas_lag_p` → `seas_lag_p[2]`. Prediction to pre-register: the NH's −788
disappears, leaving ~−35 to −50 against SH-land → ~1.07.** ⚠ **A DESIGN call (22nd parameter), and
`SEAS_T_LAG` — the respiration phase, also global, also compile-time at `ccx_core.cpp:168` — is an
equally valid place to open the same angle. NOT STARTED, and it now sits BEHIND ②/③ (see §7).**

## 3. WHOLE-MODEL STATUS (`notes/status_2026-08-29_whole_model_assessment.md`)

Re-measured at `from90` on the current objective. **CO₂ is excellent** — 0.577/0.532 ppm RMS at
MLO/SPO, all CO₂ RMSz ≤ 0.78. **Both isotopes show an ANTISYMMETRIC interhemispheric contrast error**
(δ¹³C ~0.085 ‰, Δ¹⁴C ~5.6 ‰ **too strong**) that the fitted-offset gradient rows are **blind to by
construction**. **Gate 7 land +2.30 σ.** **Gate 5: one `tau_ex` cannot serve both the gradient (1.159)
and the bomb lag (~2.3), and the gradient outvotes it 1000:1.** Decadal AF spread 0.026 vs GCB 0.051.
**No posterior** (Hessian 1.11e6, `h_ml` not C1). **Five of six |prior z| > 2 are seasonal.**

⇒ **THE PATTERN: one scalar serving two things that need different values** — `tau_ex`,
`seas_lag_p`, and the compile-time seasonal lags. **The amplitudes are already per-hemisphere arrays;
the timing parameters are not.**

## 4. THE VARIABILITY ARC

**`diag_seasonal_fix_vs_gate7.R`** — the seasonal and land-sink defects are **INDEPENDENT** (gate 7
moves +0.001 where it needs −1.148; `seas_r_norm` removes the Jensen rectification by construction).

**`diag_gamma_enso_profile.R`** — **the model has 33 % of the observed interannual growth-rate sd**
(0.301 vs 0.900) at r 0.571. Across γ = 0.4 → 4.0 **r stays FLAT**: louder, not righter. The fit was
asked and refuses at −62.6 (MODERATE). Largest objector: **`gcb_land_sink` −21.72** — an untested
link to gate 7. [[ccx_variability_gap]]

**AOD acquired** — `data/forcing_volcanic_aod.rds` from NASA GISS `tau_reff_CMIP7-2-2-1.nc`, CMIP7
for like-for-like with the FaIR calib 1.6.0 drivers. Gates pass (Pinatubo 0.1070). ⚠ **PRE-1850 IS
ZERO: Laki 1783, 1808/09 and TAMBORA 1815 are ABSENT** — the biggest event in the model's window is
**Krakatau 1884**, and "the year without a summer" needs eVolv2k. Provenance in `MANIFEST.csv`.

## 5. DIFFUSE-LIGHT FERTILIZATION — BUILT, TESTED, PRICED

`NPP_h = npp0_h * capacity * fert * (1 + gamma_diff * AOD_h)` (Gu 2003; Mercado 2009). Six sites,
R+C++ twins, `tests/testthat/test-volcanic-diffuse.R`. **`gamma_diff` defaults to 0** so every
pre-today result is bit-identical (logpost at `u_mode` **−1546.276578**); it is a **`base_param` like
`ent_seas_amp_SH`, not one of the fitted 21.**

| γ | frozen | **conditional** | buy-back | **r** |
|---|---|---|---|---|
| 0 | 0 | 0 | — | 0.571 |
| **0.25** | −40.5 | **−7.42 CHEAP** | **82 %** | **0.624** |
| 0.50 | −160.8 | −28.7 | 82 % | **0.626** |
| 0.97 (matches Pinatubo) | −601.3 | **−105.5** | 82 % | 0.575 |

**The frozen column overstated the price by 82 %** and **the r gain SURVIVES refitting** — the first
change all day that makes the model *more right* rather than louder. Land sink moves ≤ 0.057 GtC/yr.
**Matching the Pinatubo feature costs 14× more than γ = 0.25 and fits the record WORSE.**
[[ccx_diffuse_light]]

## 6. ⇒ THE NEXT STEP, AND IT IS SMALL

**CHECK `fert_k` AGAINST THE FACE-INFORMED RANGE.** The −7.42 is paid by **`fert_k` +28.9 %**
(154.84 → 199.58 at γ = 0.97; **164.23 at γ = 0.25**) with `beta_max` +11.6 % along their ρ = +0.998
ridge — **NOT by `rep_dC`, which moved 0.01 prior-sd, refuting my "level offset" story.**
**`fert_k` is the ONE parameter in that slice with an EXTERNAL constraint**: FACE caps `fert_k` and
cannot prior `beta_max`, so FACE is the only thing bounding this direction
([[ccx_face_fert_k_ceiling]], [[face_ceiling_is_the_headline_in_disguise]]).
⇒ **Cheap in logpost is not cheap in provenance. If `fert_k` ≈ 164 clears FACE, γ ≈ 0.25 is the
defensible operating point (84 % of the correlation gain at 7 % of the Pinatubo cost). If it does
not, the cheap price was illusory.**

**Then plan item ② (`h_ml` C1), then ③ (seasonal `tau_ex`). ④ four-box is HELD by Marcus.**

## 7. THE PLAN AND THE APP SPEC (both in `notes/`)

**`plan_2026-08-29_implementation_order.md`** — ① diffuse light **(DONE, priced)** → ② make the
objective **C1 in `h_ml`** before any refit → ③ **seasonal `tau_ex`** as the cheap test of the
gradient-vs-lag tension → ④ four-box **HELD** → ⑤ per-box NPP lag (**demoted**: ③/④ change what "per
hemisphere" means) → ⑥ gate 7 → ⑦ ENSO shape (lowest).

**`spec_2026-08-29_app_six_tabs.md`** — Marcus's six tabs, mapped onto the existing app, with:
- **The two-path rule:** *every driver with both a direct carbon path and a temperature path needs
  TWO edits to switch off.* ENSO and volcanoes are the two, structurally identical.
- ⚠ **The `sst_anom` trap:** over the observed record `sst_anom_NH/SH` are **PRESCRIBED from HadSST4**
  and only follow `gmst` BEYOND the last observed year. **They are INDEPENDENT series historically**,
  so backing a component out of `gmst` does NOT remove it from `sst_anom` — **the ocean would keep
  seeing what the checkbox claims to have switched off.**
- **FaIR does the VOLCANIC half of the GMST split; it CANNOT do ENSO** (internal variability) —
  Foster–Rahmstorf regression is primary there.
- **Tab ④ = three charts**: total CO₂; tracer fraction by box; added CO₂ by box. ⚠ **The last two are
  the LABEL and the PERTURBATION and differ 2.8× at 100 yr — separate captions, never shared.**
- **Tab ⑤ (hemispheric) is DEFERRED until the component is fixed.** More tabs are fine.
- **`ccx_hold_climate()` is KEPT** and must NOT be replaced by the checkboxes: all 10 callers are
  diagnostics and TESTS, it FREEZES (usually at 0) rather than decomposing, and the decomposition is
  not exhaustive. Tests must not depend on a regression fit. Build the checkboxes as a separate layer.

## 8. NON-OBVIOUS STATE

- ⚠ **`ccx_hold_climate()` does NOT freeze `aod_*`** — AOD is a RADIATIVE driver, not a climate
  variable (Marcus, correcting my first answer). **NEVER add an AOD → temperature term: `gmst`
  already carries the cooling.** Consequence: once `gamma_diff` ≠ 0, **"climate held" is a
  volcanically NOISY, ENSO-quiet world.**
- ⚠ **`N_FORCING` (`ccx_core.cpp:52`) must match `length(CCX_FORCING_COLS)`, now 17.** I appended two
  columns without bumping it: `f[15]`/`f[16]` read past the buffer, effect **−0.0004 ppm instead of
  −4.1**, nothing errored. `test-forcing.R:127` pins it and would have caught it — I had not run the
  suite. **Run the suite before characterizing what a guard did or did not catch.**
- ⚠ **FOUR of my gate verdict STRINGS over-claimed a mechanism today.** The fix that worked is
  [[pair_the_inference_gate_with_a_mechanism_gate]]: gate the NUMBER and the MECHANISM separately.
  H3 (on `rep_dC`'s own movement) caught a false "LEVEL OFFSET CONFIRMED".
- **`refit_20260828_sigma_eff` — RATIFIED "do not adopt"** (Marcus). Outputs committed as provenance;
  adoption stages never run. ⚠ **The pinned-96 successor is NOT a config change**: `ARM_HML_BOUND` is
  PROVENANCE-ONLY since `2153bd6`, a BOUND (with prior renormalization) ≠ a PIN, and both are undecided.
- **`diag_landed_gap_streams.R` is QUARANTINED** — kept in place and HARD-STOPS; output in
  `outputs/quarantine/20260829_preadoption_landed_gap/`. No replacement by design.
- **Two DIAGNOSTIC-ONLY authorizations (Marcus)**: a CMIP6 ensemble value for `SEAS_NPP_AMP_SH` may
  be USED but never shipped; a diagnostic arm may leave a bracket for MEASUREMENT, never adoption.
- **Run drivers from a FROZEN COPY** ([[never_edit_a_running_script]]).
- ⚠ **`MEMORY.md` root ~19 KB (soft 12)**, over for a fifth session. `INDEX_ccx.md` 17.8 KB (soft 14,
  hard 18.4) — **close to hard, restructure soon.** `INDEX_ccx_seas.md` is under soft.

## 9. HOW TO RUN WHAT TODAY ADDED

    Rscript calibration/diag_q10_controlled_recovery.R        # ~29 min
    Rscript calibration/diag_gross_cancellation_geometry.R    # 12 s
    Rscript calibration/diag_price_the_lag.R                  # ~10 min
    Rscript calibration/diag_seasonal_fix_vs_gate7.R          # ~2 min
    Rscript calibration/diag_gamma_enso_profile.R             # ~15 min
    Rscript calibration/diag_price_gamma_diff.R               # ~15 min
    Rscript data-raw/build_volcanic_aod.R                     # seconds
