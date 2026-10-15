# Handoff — 2026-09-08h. PHASE 1 RAN: the seven cheap tests of handoff 09-08g §1, at the canonical `hilda31`, NOTHING ADOPTED. Three predictions confirmed (T-L, T-G, T-ALK's "not a lever"), three falsified in an informative direction (T-D0's deep δ¹³C, T-hml's "no kink", T-I's sign), T-A0 partly (§1.7). Round 6 = C + D is confirmed as ONE refit, but D's mechanism reads differently from the assessment's.
# **Every model number here is GENERATED at `hilda31` by the scripts named in each section (`outputs/diagnostics/*_20260908.{log,rds}`); every observation number is generated from the data files by the same scripts. The one recollection (Hoffert 1980's 4 m/yr) is labeled in T-A0.**

Read first: `notes/handoff_2026-09-08g_next_steps_cheap_tests_first.md` (the plan and the predictions),
`notes/assessment_2026-09-08_acceptable_state.md` (options A–J). Memory: [[ccx_phase1_cheap_tests_20260908g]],
[[sigma_table_step_scales_with_residual]], [[ccx_assessment_20260908]].

## 0. What shipped with the tests (all default-off or objective-side; the canonical's numbers are bit-identical)
- **`alk_hs`** — a per-box alkalinity for the COLD box, in both cores (`R/model.R` ccx_prepare + the live HS pCO₂ site,
  `R/spinup.R`, `R/cpp.R`, `src/ccx_core.cpp`). ABSENT = `ALK_SURFACE`, bit-exact (asserted in `test-alk-hs.R` on the
  spinup state and a 50-yr transient; R/C++ parity at an explicit value to 1e-12; errors by name). One scalar for both
  hemispheres' cold boxes — the per-hemisphere form is a follow-up only if T-ALK had said "lever" (it did not).
- **GATE L** (`dg_gateL_partition()` / `dg_gateL_verdict()`, ledger id "L") and **GATE GL** (`dg_gateGL_verdict()`,
  ledger id "GL") in `calibration/lib_design_gates.R`, kernel mutation-tested both ways in `test-gate-bounds.R`.
- Scripts: `calibration/diag_{td0_martin_shape, talk_hs_alkalinity, tl_land_share_gate, tg_gradient_level_gate,
  thml_profile, thml_kink_source, thml_kink_rows, thml_sigma_step, ti_bomb_nh_delay, ta0_enso_upwelling_sign}.R`.
- Suite: **2208 pass / 3 fail / 4 skip** — the three are the pre-existing set (`test-alpha-as.R:116-117`, gate Q's
  deliberate red at the canonical; `test-seas-lag-split.R:199`). ⚠ The pure-R carbonate path warns below its 2 °C fit
  range whenever the cold box's SST anomaly is negative; pre-existing, ~30 k warnings across the suite's R-path tests.

## 1. The seven results (prediction → result)
### 1.1 T-D0 — Martin remineralization shape, unrefitted (`diag_td0_martin_shape.R`)
The pump SHAPE is a DIC-excess profile whose diffusive return flux `ccx_pump_export()` turns into a source; a Martin
shape is therefore F(z_k) = F(z_s)(z_k/z_s)^−0.858 at the interfaces, integrated with the model's OWN K(z). Two arms:
`martin_tail` (GLODAP above the interface nearest 1000 m, Martin below, flux-continuous) and `martin_full` (Martin from
the ML base). `pump_grad` held. ⚠ The handoff's "below the GLODAP profile's span" is moot — the profile spans 0–3700 m
and is FLAT below ~1000 m (0.985 of its span by 1000–1250), which is what "99.5 % above 1000 m" was.

| arm | export GtC/yr (below 1000 m) | layer-1 step µmol/kg | C's derived amplitude SH / NH | deep δ¹³C (bottom LS) | Q n_sd | lik |
|---|---|---|---|---|---|---|
| glodap | 37.05 (0.14) | +44.3 | [10.6, 16.5] / [8.8, 13.6] | +1.22 | 2.44 FAIL | 0 |
| martin_tail | 16.33 (0.07) | +20.8 (**−53 %**) | −53 % | **+1.43** | 2.15 FAIL | −17.3 |
| martin_full | 1.43 (0.11) | +3.8 (**−91 %**) | −91 % | **+1.57** | **1.96 PASS** | −47.3 |

- **P1 FALSIFIED**: the deep gets HEAVIER (obs deep > 2000 m bottles: +0.47, n 8007). **P2 ✓** Q falls (to a PASS in the
  full arm). **P3 ✓** the step collapses ⇒ **C and D are ONE refit** (handoff §3's rule, by a factor of two).
- WHY: with the model's K(z) (11,698 at the ML base, 129 in the deep) the Martin profile holds the 262 µmol/kg gradient
  with a TENTH of the export — the gradient sits where K is small. Less export = less light carbon anywhere. The
  ⛔ RETRACTED 2026-09-08h (`notes/handoff_2026-09-08i_cheap_probes.md` §1): the sentence that stood here compared the PI
  model gradient (1.24) with MODERN bottles (0.86) — not like-for-like. At the bottles' epoch the model's surface−deep
  gradient is 0.40 vs 0.89 observed, too SMALL: the deep DOES lack light carbon relative to the surface, and Martin at a
  held `pump_grad` made it worse by starving the export. The assessment's option-F gradient reading stands.
- The unrefitted price is on `d13c_level_MLO` (−14.6 / −28.6), `ocean_grad_d13c` (−6.5 / −12.2) and `d14c_NH`
  (−4.5 / −11.3): the export sets the Suess-effect uptake. The D refit will move `kz`, `kz_deep_frac`, `pump_grad` together.

### 1.2 T-ALK — per-box alkalinity (`diag_talk_hs_alkalinity.R`)
Observed (GLODAPv2.2023 bottles ≤ 50 m, flag 2, the end-member probe's bins): high-latitude ALL median **2256** / mean
2218 (n 25,697); **SH 2296 / 2296 (n 5200)**; NH 2225 / 2198; low-latitude 2309 / 2306. ⇒ **the handoff's "2256 vs
2300" was the ALL-latitude MEDIAN, carried by NH freshwater; the SH cold box — the hemisphere of the DIC row — sits AT
the model's 2300.** Arms (one scalar for both hemispheres' cold boxes): control / explicit (bit-exact, GATE PASS) /
hs_SH 2296 / hs_all 2218 / hs_NH 2198 / mirror 2382.
- HS DIC at epoch: 2149 (control) → 2146 (SH) / 2079 (all) / 2062 (NH): **0.85 µmol DIC per µmol ALK**, and every lower
  alkalinity moves the row AWAY from 2163. Gate Q: **−0.01σ (SH) ✓ CONFIRMED not a lever**; −0.27 / −0.33σ at the
  all / NH values (between the 0.2 and 0.5 marks); likelihood −0.1 / −15.7 / −23.5 (the CO₂ level rows pay).
- ⇒ §4 of the 09-08g handoff stands ("not as a state; per-box alkalinity is the one effect that reaches a scored row") but
  its size is nil in the SH and the NH would need its own constant to matter at all. `alk_hs` stays ABSENT. Not a lever.

### 1.3 T-L — GATE L, the land share of a 100 GtC pulse (`diag_tl_land_share_gate.R`)
Protocol = the IRF comparison's (hold at 2010, pulse at the held state, closure 1.000000). Joos 2013 1000-yr split
(abstract, as sourced 09-08f): land 16 ± 14, ocean 59 ± 12, air 25 ± 9 %. Bound **|z_land| ≤ 1 sd → [2, 30] %** —
⚠ a CHOICE (1 sd of a MODEL spread, not 2 × a measurement se; at 2 sd the canonical passes).

| arm | 20 yr | 100 yr | 300 yr | 1000 yr land / ocean / air | verdict |
|---|---|---|---|---|---|
| canonical | 23.0 | 40.3 | 43.1 | **32.2** / 48.9 / 18.9 | **FAIL, upper edge** (z +1.15) ✓ predicted |
| land-off (beta_max 0) | 0 | 0 | 0 | 0 / 70.4 / 29.6 | FAIL, lower edge ✓ (power both ways) |
| column control (ent26) | 22.5 | 39.0 | 41.0 | 29.7 / 52.4 / 17.9 | PASS |

The land DOES return carbon (43 % at 300 yr → 32 % at 1000): option H's "does not saturate/return" is half right — it
returns, late. The HILDA structure moved the 1000-yr land share UP (29.7 → 32.2) by taking ocean uptake down.

### 1.4 T-G — GATE GL, the δ¹³C gradient LEVEL (`diag_tg_gradient_level_gate.R`)
Observed −0.06675 ‰ ± se 0.00484 (n 43, n_eff 40.6). Canonical raw −0.13116 (**1.965×**), `grad_off_d13c` +0.06436 absorbs
the whole miss. **z −13.31 FAIL ✓ predicted**; with the CO₂ control's representation allowance in quadrature
(|1 − R_co2| = 0.084 → se 0.00743) **−8.67, still FAIL**. Column control −13.36; defaults −24.0 (2.74×).
CHOICE for Marcus: the gate proper is the handoff's form (observation se only); the augmented form is printed beside it.

### 1.5 T-hml — the h_ml profile (`diag_thml_profile.R` + `_kink_source`, `_kink_rows`, `_sigma_step`)
The mode reproduces (diff 0); the Hessian's eps scan reproduces EXACTLY (−53.5 / −57.7 / −87.1 / −37.8 per u² at eps
3e-3 … 3e-1). The slice has a **1.5 m shelf at h_ml 49.9–51.2** (mode 49.15): −0.5 log-units, first derivative from
−0.03 to −0.75 and back. **"No kink" FALSIFIED as stated — but it is not the model.** Freezing the pump shape and the
substep count changes nothing; per stream the shelf is `ocean_grad_d13c` (d2 ratio 24.7) and `_dic` (11.9); those rows
are scored at σ_eff(h_ml) from the like-for-like table (`data/obs_glodap_sigma_rep.rds`, 1 m grid, Hermite), which
**STEPS at every 25 m GLODAP bin edge the ML base crosses: 50 m −5.1 % (d13c) / −6.3 % (dic); 100 m −4.7 / −1.5;
150 m +7.5 / +6.9; 200 m +5.6 / +6.2.** With |z| 3.34 / 2.16 on those rows the predicted shelf (−0.570 / −0.258)
matches the measured (−0.500 / −0.265). The 08-28 acceptance ("roughness at most 0.0734 log-units") was priced at a
mode with small residuals; the cost scales with z². `hml_kinks` (the pump-shape family) stays right and gone.
⇒ The posterior route is NOT blocked by a model kink; a sampler crosses a C1 shelf. **Whether to smooth / re-bin the
σ_rep table is a change of objective — a ruling.**

### 1.6 T-I — NH bomb timing (`diag_ti_bomb_nh_delay.R`)
No core edit: the ¹⁴C state is linear in its sources at fixed ¹²C, so "NH limb delayed, SH as shipped" is a superposition
of fast C++ runs — GATED (whole-column delay vs its four-part sum: 2.7e-12 ‰). Observed NH peak 1963.68 (855 ‰), model
1964.64 (864): **already 0.96 yr LATE**. A pure NH delay of 0.25 … 2 yr moves the NH peak **later, 1.00 yr per yr**
(z +2.17 → +2.73 … +6.64); a first-order stratospheric reservoir (τ 0.5–2 yr) does the same and lowers the peak (827 →
683). The SH peak follows 1:1 (it gets its bomb carbon through the NH); the lag barely moves (+0.04).
⇒ **FALSIFIED IN SIGN. Option I is ruled OUT as built**: a reservoir can only delay, and the model is late with
instantaneous injection. Timing IS a 1:1 lever, but the miss needs FASTER early removal from the NH atmosphere —
the exchange (`tau_ex` 0.91, one scalar serving the gradient and the bomb), or the NH land.

### 1.7 T-A0 — the ENSO-upwelling SIGN (`diag_ta0_enso_upwelling_sign.R`)
Session wrapper on the pure-R `ccx_deriv()` (bit-parity with C++ to 3e-13 ppm): `p$w_up = W0 × max(0, 1 − γ·Niño3.4)`,
`gamma_enso_ocn_* = 0`, the scorecard's own regression (annual ocean uptake ~ year + Niño3.4, 1959–2024). W0 ∈ {0.5, 1,
2, 4} m/yr (4 = the classical upwelling-diffusion value, Hoffert et al. 1980 — a RECOLLECTION), γ ∈ {0.25, 0.5, 1}.
⚠ Ruling (2) of 09-08g — γ sized from the Fix B reservoir — is still owed; this is a scan.
| W0 m/yr | γ 0 (C++) slope / lik vs solubility-only | γ 0.25 | γ 0.5 | γ 1.0 |
|---|---|---|---|---|
| 0.5 | −0.163 / **−135** (`d14c_profile_bd` −104) | −0.151 (r −0.49) | −0.138 (r −0.44) | −0.115 (r −0.36) |
| 1 | −0.163 / **−596** | −0.138 | −0.113 | −0.066 (r −0.19) |
| 2 | −0.163 / **−1615** | −0.112 | −0.062 | **+0.034 (r +0.07)** |
| 4 | −0.163 / **−4001** | −0.060 | **+0.042 (r +0.09)** | **+0.235 (r +0.31, 2.04× obs)** |

- The limb itself is ENSO-blind (every γ 0 slope = the solubility-only −0.163); the modulation moves the slope
  LINEARLY: **slope = -0.163 +0.100 × (W0·γ)** GtC/yr per index (least squares over the 12 arms). Sign flip at
  W0·γ ≈ 1.6 m/yr; the observed +0.115 needs **W0·γ ≈ 2.8 m/yr = 26 Sv of MODULATED upwelling** over the
  LS area (2.99e+14 m²) — the same order as the real equatorial Pacific upwelling (tens of Sv — a RECOLLECTION).
  The likelihood gain "vs γ 0" (+3.8 … +562) is the mean-state repair of a limb that should not be there, not ENSO skill.
- **Verdict: PARTLY.** The MECHANISM (upwelling suppression under El Niño) carries the right sign at a physically sized
  volume; the whole-column upwelling-diffusion LIMB cannot host it — its one-step return of mixed-layer water to the
  bottom box floods the deep Δ¹⁴C rows (−104 at 0.5 m/yr already) and by 4 m/yr the CO₂ levels (−739 / −617). **A as
  built is ruled out on the mean state; B — a SHALLOW tropical upwelling box whose return is to the thermocline, not
  the bottom — is the build, with a size target of ~26 Sv modulated.** Ruling (2) of 09-08g (γ from the reservoir)
  is answered by the scan: W0·γ, not γ alone, is the sized quantity.

## 2. What Phase 1 changes in the plan
1. **Round 6 = C + D together, confirmed** (the step halves or vanishes under D). But D's target is the GRADIENT's shape
   and the export (37 → 16 or less), not the deep's δ¹³C level; the level needs an air-sea-equilibrium diagnosis
   (which SST the equilibrium is computed at; the equilibrium ε at 2 °C for the cold box; the atmospheric δ¹³C the
   spinup equilibrates to). Prereg D's predictions on the gradient and the export, not on "the deep lightens".
2. **Option I is dead**; gate 5's NH miss goes to the exchange / NH land — a hemispheric `tau_ex` probe is the next cheap
   test there (the 08-31 seasonal-`tau_ex` scan is the precedent).
3. **Option A is ruled out as built, B is the build** (§1.7): the sign mechanism works at ~26 Sv modulated, the whole-column limb wrecks the deep; B's box must return to the thermocline.
4. **Alkalinity is closed**: not a lever; `alk_hs` stays off; no per-hemisphere extension.
5. **The σ_rep table's bin-edge steps** are an objective defect priced at 0.5 log-units at this mode; a ruling.
6. GATE L and GATE GL are in the ledger and FAIL at the canonical; both bounds carry a stated choice.

## 3. Rulings owed
(1) GATE L's bound: 1 sd of the model spread (FAIL) vs 2 sd (PASS). (2) GATE GL's form: observation se alone vs with the
representation allowance (both FAIL). (3) The σ_rep table: smooth across bin edges / re-bin / leave (an objective change).
(4) Option A vs B in the light of §1.7. (5) Round 6's prereg (C + D) with D's predictions rewritten per §2.1.
(6) ✅ The 09-08g hygiene is DONE (CHANGELOG 09-08h): `test-mode-struct-lint.R` (29 files / 32 sites, convert on touch);
the promote script carries the profile rows and GATE 5 can fail (mutation-tested, −4.75 caught); the seven-box diagram
draws the cold boxes with their own numbers from a per-edge flux trace, and the "−40 to the deep" arrow is fixed.
