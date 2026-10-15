# Handoff — 2026-09-08g. NEXT STEPS, RULED (Marcus): (1) run every CHEAP test first; (2) then the option most likely to IMPROVE THE FITS while ADDING THE MOST PEDAGOGICALLY; (3) C and D together if they interact enough that doing both makes sense; (4) salinity — is it in the model, should it matter?
# **Every model number here is GENERATED at the canonical `hilda31` (CHANGELOG 09-08f, `outputs/diagnostics/whole_model_scorecard_20260908f.log`, the F/H one-liners); the two recollections (Ledwell's pycnocline diffusivity; the size of the salinity effect on the carbonate constants) are labeled.**

Read first: `notes/assessment_2026-09-08_acceptable_state.md` (options A–J), `notes/handoff_2026-09-08f_hilda31_adopted_assessment.md`
(what the canonical is), `notes/options_2026-09-08d_seasonal_h_ml.md` (option C's design and predictions).
Memory: [[ccx_assessment_20260908]], [[ccx_hilda31_adopted]], [[ccx_seasonal_h_ml_option]].

## 1. Phase 1 — the cheap tests, all at the canonical, none needing a refit or a ruling
"Cheap" = hours, one script each, no refit, adopts nothing. Each has a pre-registered prediction and says what it decides.
Run them in this order (the first three are pure reads; the last three build a small probe).

| id | test | what it decides | prediction (falsified if) | cost |
|---|---|---|---|---|
| **T-D0** | **Martin-shape spinup, unrefitted**: give `ccx_pump_shape()` a switchable Martin form F(z) ∝ (z/100)^−0.858 (SOURCED, Martin et al. 1987) below the GLODAP profile's span, at the canonical's own `pump_grad`; read the deep DIC/δ¹³C, layers 1–2 DIC (the sub-ML step), gate Q, the HS surface δ¹³C, the deep rows | whether D lightens the deep and Q (assessment §3.3), and **how much C's derived amplitude changes under D** — the C×D interaction (§3 below) | deep δ¹³C falls ≥ 0.3 ‰ toward +0.4; gate Q's mean falls; layer-1 DIC step shrinks by > 25 % (falsified: deep δ¹³C unmoved, or the step unchanged) | ½ day |
| **T-ALK** | **Per-box alkalinity probe**: pin the cold box's alkalinity at GLODAP's high-latitude surface (SH 2256 vs the global 2300 held everywhere; the NH differs by ~94 µmol/kg of freshwater, C8) and read HS DIC, HS δ¹³C, gate Q, gate G | whether salinity/alkalinity (§4) is a lever anywhere that matters | HS DIC moves ~−40 µmol/kg (toward 2163 obs from 2149: the SIGN is the question), gate Q moves < 0.2σ (falsified: Q moves > 0.5σ — then §4's "no" is wrong) | hours |
| **T-L** | **Land-share-of-pulse gate** (an ORDERING, no typed threshold): the model's land share of a 100 GtC pulse at 100 and 1000 yr vs Joos 2013's 1000-yr split (land 16 ± 14 %, ocean 59 ± 12 %, air 25 ± 9 %; SOURCED). Mutation-test it (a land-off arm must fail the other way) | turns the H finding (land 0.41 at 100 yr) into a gate the next land change is judged on | the canonical FAILS (land > 30 % at 1000 yr) (falsified: it passes — then H's reading is wrong) | hours |
| **T-G** | **Gate the δ¹³C gradient LEVEL** (a DESIGN gate beside H, on the RAW interhemispheric δ¹³C gradient vs the observed −0.0668 ‰ ± its se; H already gates the contrast). Mutation-test | makes the 1.97× gradient a scored miss rather than an absorbed offset; tells the next refit what it costs | FAIL at the canonical (falsified: PASS — then the offset's 1.97× is a level artifact of the offset itself) | hours |
| **T-hml** | **1-D likelihood profile in `h_ml`** at the canonical, ±20 m in 2 m steps | whether the Hessian's `h_ml` step-instability (12.5 %) is curvature noise or a kink (the C1 remap removed kinks; post-adoption they must stay gone) | smooth, no kink (falsified: a kink — then `hml_kinks` is wrong and the posterior route is blocked) | hour |
| **T-I** | **NH bomb-timing probe**: delay the NH bomb-¹⁴C input column by 0.5 / 1.0 / 1.5 yr in the forcing (a diagnostic-only edit), read gate 5's NH peak z and the lag | whether a stratospheric reservoir (option I) can move the +2.17σ NH peak, or the miss is in the exchange | a 1-yr delay moves the NH peak z from +2.17 to < +1 (falsified: < 0.5σ of movement — then it is `tau_ex`, hemisphere-specific) | hours |
| **T-A0** | **The ENSO-upwelling SIGN check**: switch the conveyor's upwelling limb on (`w_up` > 0, default 0; size from the Fix B reservoir, `ccx_fixB_reservoir_priced`) and modulate it by (1 − γ·Niño3.4) with `gamma_enso_ocn_* = 0`; read the solubility-only-style regression (annual ocean uptake ~ year + Niño3.4) | whether option A can produce the RIGHT SIGN at a physically sized γ without the additive flux — decides A vs B | r flips from −0.52 to ≥ +0.3 at γ ≤ 0.5 (falsified: r stays negative — the reservoir contrast is essential and B is the build) | 1 day (the one non-trivial probe) |

Hygiene to do in the same pass (not tests): the ratchet lint on the ~55 direct `readRDS(ccx_mode_file())` overlays (the `struct` class of bug); the promote script's `streams` without the profile rows; the app's 7-box diagram.

## 2. Phase 2 — the option, by Marcus's criterion (improve the FITS × add PEDAGOGY)
| option | fit improvement it is LIKELY to buy (what it relaxes) | pedagogical payoff | cost | rank |
|---|---|---|---|---|
| **C + D** (seasonal mixed layer + Martin remineralization, one refit) | `sst_seas_amp_NH` −2.96 (C, pre-checked 8–14 µmol/kg untuned); `pump_hs` +2.31 and gate Q 2.44σ (D, if T-D0 confirms); the export 37 → toward 10 GtC/yr; `kz_deep_frac` −2.51 (a deeper supply lets the floor rise) | HIGH: a fitted compensator (`ent_seas_amp_SH`) becomes a mechanism the student can see (winter deepening entrains DIC); the deep ocean gets its carbon the way the real one does; the isotopes carry the signature | 2 days + refit | **1** |
| **A** → **B** (ENSO-modulated upwelling; the tropical box) | the CO₂-level rows (σ 1 ppm) currently miss ~0.5 ppm/yr of ENSO wiggles: a right-signed limb at 0.53× → ~1× is worth tens of log-units there; gate V | HIGHEST per link: it repairs the ONE wrong-signed mechanism the standard forbids — but the fit gain is the least certain of the three | 1 day (A probe) / weeks (B) | **2** (first if T-A0 flips the sign) |
| **G** as an objective row | H's 1.97× becomes fittable; unknown what the fit pays | modest (a truer hemispheric contrast) | hours | with the next refit |
| **I** | gate 5's NH peak | modest | 1 day | after T-I |
| **E** (ventilation limb) | `kz` 4–40× real → the export, the flush, H, Q all ease | high, but it is the research question | weeks | later |

**Recommendation.** Phase 1 first (a week at most). Then **round 6 = C + D together** (§3), pre-registered on the option-B note's
P1–P5 plus D's own (deep δ¹³C → +0.4 ± 0.3; export → < 15 GtC/yr; Q ≤ 2σ; `pump_hs` inside 2σ). **A's probe (T-A0) runs inside
Phase 1**; if it flips the sign at a physical γ, A is built right after round 6 (or as round 6b) because it repairs the release
blocker; if not, B is the next structural build and E the direction.

## 3. C and D together — yes, they interact through the vertical DIC profile
C's derived amplitude is (C₁ − C_ml)(t) × f(month): the sub-mixed-layer DIC step, which at the canonical is **+42 µmol/kg in
layer 1 (40–92 m) and +97 in layer 2** — set by where the LS pump remineralizes. D moves remineralization DEEPER (GLODAP's
shape puts 99.5 % of the 37 GtC/yr above 1000 m; Martin's puts 14 % below), so the layer-1/2 step SHRINKS and C's amplitude
with it; conversely C's winter entrainment draws on exactly those layers and changes the gradient D's refit sees. Fitting C
alone would calibrate an entrainment on a step D then removes; fitting D alone would leave the seasonal rows to re-strain the
solubility amplitude. **T-D0 measures the coupling before the build** (the step under the Martin shape); if the step changes
by > 25 % they are ONE refit, which is the prediction. Same objective, same harness, one prereg with both mechanisms' claims.

## 4. Salinity — not in the model as a state; where it would matter, and whether it should
**What is there.** No salinity state, no per-box salinity. It enters only as constants: the carbonate-constant polynomials
(`R/carbonate.R`, `build_carbonate_tables.R`) are seacarb fits in T at **`SALINITY_REF = 34.7`** (K0, K1, K2, Kb; boron from
Uppstrom 1974); the Schmidt number is Wanninkhof's S = 35 fit; **alkalinity is one constant, `ALK_SURFACE` = 2300 µmol/kg,
for every box** — both hemispheres, the LS mixed layer AND the cold box (`ccx_prepare()`, `aux$dic0_hs`). Density,
stratification and deep-water formation are STRUCTURAL (`u_hs`, `h_hs`, `h_ml`, the Holte climatology), not computed from T and S.
**Where it would matter, ranked.** (1) **Alkalinity by box** — the real high-latitude surfaces differ: SH 2163 vs NH 2069
µmol/kg of DIC, ~94 of it freshwater/alkalinity (C8), and the cold box's GLODAP alkalinity is 2256 vs the 2300 held; a −44
alkalinity is roughly −40 DIC at fixed pCO₂ — the ONE salinity-class effect large enough to see (T-ALK measures it). (2) The
carbonate constants' S-dependence within 33–36 is ~1–3 % on K1/K2 and K0 → a few µatm of pCO₂ (RECOLLECTION of the
magnitude): below the rows' σ. (3) The seasonal salinity cycle's pCO₂ term is a few µatm vs ~30 thermal: negligible for the
seasonal rows. (4) Salinity-driven density is what makes deep water and shoals the SO mixed layer — pedagogically real, but
a box model represents that outcome (the flush, the thickness) rather than the cause, and adding S would not change a flux.
**Should it matter?** Not as a state. **It should as a per-box alkalinity (and, trivially, a per-box S for the constants)**:
that is a data product (GLODAP surface alkalinity by box), a one-line change in `ccx_prepare()`, and it is the only salinity
effect that reaches an observable the objective scores (the HS surface DIC row, gate G). If T-ALK moves the HS DIC toward
2163 and leaves Q alone, ship it with round 6 as a declared, sourced constant; if it moves Q, it is a lever and gets a prereg.
⚠ The NH cold box would then want its OWN alkalinity (2069-class), which the one-water-type-per-hemisphere structure cannot
carry without a hemisphere-specific HS alkalinity — a small, declarable extension, not a new box.

## 5. Rulings owed (in Phase-2 order)
(1) Ratify the Phase-1 list (add/drop). (2) T-A0's γ sizing from the Fix B reservoir — a declared number. (3) G as an
objective row (a change of objective, #12) vs a gate only. (4) Round 6's prereg once T-D0 is in. (5) The alkalinity-by-box
constant if T-ALK says it is a lever.
