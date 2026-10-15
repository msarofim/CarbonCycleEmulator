# Handoff — 2026-09-08f. `hilda31` ADOPTED as the canonical (the first fitted under a structure; the mode file now carries it); the ASSESSMENT says the model is NOT yet acceptable — the ENSO ocean sign is still the broken link — and ranks the options; two diagnostics (F, H) point at the deep's missing light carbon and at the LAND as the lifetime's owner.
# **Every number GENERATED at the adopted file (`diag_adoption_read_hilda31.R`, `diag_whole_model_scorecard.R` arm C, the F/H one-liners in CHANGELOG 09-08f). Martin's exponent and Joos's 1000-yr split are SOURCED from the papers' text; Ledwell's diffusivity is the one labeled recollection.**

Read first: `notes/assessment_2026-09-08_acceptable_state.md` (the verdict and options A–J), CHANGELOG 2026-09-08f, and for the
round that produced the canonical `notes/handoff_2026-09-08e_round5_launched.md` §3b. Memory: [[ccx_hilda31_adopted]],
[[ccx_assessment_20260908]], [[ccx_round5_result]], [[never_reship_mid_array]].

## 1. The adoption (Marcus: "adopt the round 5 winner as the canonical")
`CCX_MODE_CANONICAL = "hilda31"` → `calibration/output/refit_20260908_hilda31/mode_fit_pumpN.rds` (31 par, `struct = "hilda"`,
logpost −1478.6595, promoted from round 5's id 3 of 24; Hessian via `recompute_hessian.R --update`: −H PD, cond 3.6e5, **`h_ml` step-UNSTABLE 12.5 %** — a posterior is not unblocked here). `ent26` retired
(`CCX_MODE_RETIRED`, quarantined under `calibration/output/quarantine/20260908_hilda31_adopted/`) and kept as the like-for-like
column control by PATH: **`CCX_MODE_COLUMN_CONTROL`**.
**The one thing to know:** a mode file now carries `struct`, and **every base list must come from `ccx_mode_base(md)`** —
`ccx_default_params()` has `hs_frac = 0` and the same vector scores −23,306,061 there. Routed: `ccx_load_mode`, `dg_vector`,
`app/global.R`, `sl_*` (`struct=`), `diag_joos_irf.R`, `recompute_hessian.R`, two tests; ~55 diagnostics still overlay
directly (a ratchet lint is owed, modeled on `test-overlay-idiom-lint.R`).
Exposed and fixed: the HS pump's `lab = "pump_hs"` named no flux channel (the flux trace and the app died with the structure
ON) → `"pump"`; promote/hessian re-imposed a uniform `h_ml` prior from the recorded band → only when it differs.
Tests: the nine round-3-era failures now pass (one pre-existing seas-lag-split error remains); `test-enso-demean` gap
re-derived 45.16 → 43.84 at the new canonical (the 09-04 precedent); **`test-alpha-as` GATE Q is RED at the canonical and is
left red on purpose** — the adopted mode fails Q at 2.44σ (see §3).

## 2. What the canonical is (adoption read + scorecard arm C)
`u_hs` 24.2 m/yr (44 Sv, z +0.42), `hs_asx_frac` 0.780 (z +1.2), `k_w` 1661, `h_ml` 49.2, `h_hs` 401, `kz` 11,698 (K_deep 129),
export 91 gC m⁻² yr⁻¹ (5.3 GtC/yr, z +2.3); likelihood −1439.4 (common rows −1429.0 vs ent26 −1652.6, hilda30 −1427.6).
Gates: V −2.77 / H +6.51 / 5 +2.17 FAIL; G +1.57 / 7 / S (8.96 mo) PASS; **Q 0.844 vs 0.60 ± 0.10 FAIL**; ENSO 0.53× obs
(solubility-only r −0.52); IRF(100) 0.279. Seasonal limbs unchanged from ent26 (SH-land 1.66×, δ¹³C/ppm SPO 1.19).
Strained: `rep_dC` +3.40, `sst_seas_amp_NH` −2.96, `kz_deep_frac` −2.51, `pump_hs` +2.31, `q10` −2.22.

## 3. The assessment, in five lines (`notes/assessment_2026-09-08_acceptable_state.md`)
1. **Not acceptable yet.** The ocean arc delivered the deep and made every structural quantity observation-consistent at zero
   transient cost; **it moved nothing on the chain**, and the ENSO ocean response is still a wrong-signed mechanism canceled by
   fitted coefficients — the 09-04 release blocker, unchanged.
2. **F (done):** the heavy cold surface (+2.41) is the 2 °C EQUILIBRIUM fractionation acting on a deep that is 0.85 ‰ too heavy
   (deep +1.29 vs ~+0.4); the HS pump OFF makes it heavier; the deep lacks remineralized light carbon below 1000 m (LS pump
   0.18 GtC/yr vs ~1.2 real, Martin b 0.858 SOURCED). ⇒ **Option D (Martin remineralization) is the Q / HS-δ¹³C candidate.**
3. **H (done):** pulse partition at 100 yr air 0.28 / ocean 0.32 / **land 0.41**; Joos 2013 at 1000 yr ocean 59 ± 12 % /
   land 16 ± 14 % / air 25 ± 9 % (SOURCED). ⇒ the short lifetime is the LAND's; a gate on the land share (an ordering) and a
   land-return mechanism are the follow-ups.
4. **The structural root:** the LS column ventilates only by `kz` (3.7 cm²/s at 100 m; Ledwell ~0.1, RECOLLECTED), so the LS
   pump exports 37 GtC/yr (real ~10) above 400 m; a mode-water ventilation limb (E) is the direction A, B, D all point to.
5. **Options and order:** **A** ENSO-modulated upwelling limb (probe first; 1–2 d) before **B** the tropical box; **C** the
   seasonal mixed layer + **D** Martin remineralization as ROUND 6 (one refit, both sourced); **G** gate the δ¹³C gradient
   LEVEL (objective, cheap); **I** NH bomb timing; **J** DESIGN §6 / CITATION (Marcus's text). E is the research question.

## 4. Rulings owed
(1) Round 6 = C + D together, or one at a time? (2) A (the cheap probe) now, in parallel with round 6? (3) The `hs_asx_frac`
width (0.15, a JUDGMENT) and the `u_hs` width (0.242, derived) stand in the adopted canonical — ratify or revisit.
(4) `test-alpha-as`'s GATE Q assertion stays red until D (or another Q fix) lands — ratify leaving it red.

## 5. Files (this commit) and the things still owed
Code: `R/paths.R` (registry, `ccx_mode_struct/base`, `CCX_MODE_COLUMN_CONTROL`), `R/calibrate.R` (`ccx_load_mode`), `R/model.R`
(flux label), `calibration/{lib_design_gates,lib_seas_limbs,promote_multistart_mode,recompute_hessian,run_dispersed_multistart,
diag_joos_irf,diag_whole_model_scorecard,diag_adoption_read_hilda31,diag_hilda2[89]_*,diag_hilda30_predictions,diag_hs_endmember_probe}.R`,
`app/{global,server}.R`, tests `{mode-file,likelihood,enso-demean}.R`; the mode file + `_hess.rds`; the quarantine move;
`outputs/diagnostics/{adoption_read_hilda31,recompute_hessian_hilda31,whole_model_scorecard_20260908f}*`; `notes/assessment_…`,
this note, CHANGELOG. Memory: `ccx_hilda31_adopted`, `ccx_assessment_20260908`, `never_reship_mid_array`; indexes + root updated
(root at 14.3 KB content, over the 12 KB soft target — merge when convenient).
**Owed:** the ratchet lint on direct `readRDS(ccx_mode_file())` overlays; the app's 7-box diagram; the promote script's
`streams` without the profile rows; README/DESIGN §6 status lines (README line 22 says `ent26`; §6 says "all must pass" against
a retired set — J); the seasonal-shape product is built, option B's prereg is drafted in `options_2026-09-08d_seasonal_h_ml.md`.
