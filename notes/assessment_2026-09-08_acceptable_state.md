# ASSESSMENT — is CarbonCycleEmulator in an acceptable state, and if not what are the best options? (2026-09-08f)
# Written at the ADOPTION of the round-5 winner as the HILDA canonical (Marcus, 2026-09-08). **Every model number is GENERATED** at that vector (`diag_whole_model_scorecard.R` arm C, `diag_hilda31asx_predictions.R`, the spinup read in CHANGELOG 09-08f); the Martin exponent was SOURCED while writing it (Martin et al. 1987 DSR 34:267, 1.53 (z/100)^−0.858, r² 0.81, n 48); the one remaining recollection (Ledwell's pycnocline diffusivity) is labelled.

## 0. The standard (Marcus, 09-03; `notes/assessment_2026-09-04_public_readiness.md` §0)
A pedagogical model, not an emulator: **the product is the CHAIN** — "constrain the model with seasonal and isotopic data ⇒
long perturbation lifetimes emerge." A defect blocks release if it breaks a link: an observable matched by CANCELLATION, or a
wrong-signed mechanism cancelled by a fitted coefficient. A benchmark miss with the right mechanism is a research question.

## 1. VERDICT: NOT YET ACCEPTABLE — one chain link is still broken, and it is the same one as on 09-04
The ocean-structure arc (09-04 → 09-08e, rounds 1–5) delivered a deep ocean the model never had: the Δ¹⁴C profile inside 1σ,
deep DIC/δ¹³C/ALK gradients with a physical source, a cold end-member at the observed DIC, and — after round 5 — every
structural ocean quantity at or inside its own observation (`u_hs` 24 m/yr vs 19–26 observed; `hs_asx_frac` 0.78 vs 0.65;
`h_ml` 49 vs 60/118; `k_w` 1661 inside its prior) at ZERO cost on the transient rows. That is real progress on **physical
intuition** and on the **isotopic** variables of the deep. **It moved nothing on the chain.** The ENSO ocean response is still
a wrong-signed solubility path (r −0.52) overturned by fitted coefficients to 0.53× the observed sensitivity; the seasonal NH
strain is unchanged; the hemispheric δ¹³C contrast fails at 6.5σ; the bomb NH peak is 2.2σ late; and the arc added one
failure, gate Q. **A student switching ENSO on still sees roughly the right answer produced by the wrong physics.** That was
the release blocker on 09-04 and it is the release blocker today.

## 2. The state at the new canonical (arm C of `outputs/diagnostics/whole_model_scorecard_20260908e.log`)
| link / goal | measure | status | since |
|---|---|---|---|
| **Seasonal cycle — ocean phase** | GATE S: SPO ocean limb 0.415 ppm @ 8.96 mo, bracket [7.41, 10.41] | ✅ PASS | 09-04 |
| Seasonal — partition (land/ocean limbs) | adoption read: SPO SH-land limb 1.66× the inverted land (ent26 1.68×), SH-ocean 0.415 @ 8.96, δ¹³C-per-ppm SPO 1.19 / MLO 0.97 | ✅ weak pass, unchanged | 09-04 |
| Seasonal — NH strain | `sst_seas_amp_NH` prior-z **−2.96** (no NH entrainment channel) | ⚠ strained | 09-03 |
| **ENSO → ocean** | slope 0.53× obs; solubility-only **r −0.52 (wrong sign)** cancelled by `gamma_enso_ocn` | ⛔ **BROKEN LINK — the blocker** | 09-04 |
| Interannual variability | GATE V −2.77σ (too smooth) | FAIL, non-blocking (downstream of ENSO) | 09-04 |
| **Hemispheric differences** | GATE H contrast +6.51σ: δ¹³C gradient **1.97×** observed, absorbed by a fitted offset; CO₂ control passes | ⛔ FAIL | 09-04i |
| **Isotopes — bomb ¹⁴C** | GATE 5: NH peak **+2.17σ late**; lag and orderings fine | FAIL | 09-02 |
| Isotopes — air-sea δ¹³C disequilibrium | GATE Q **0.844 vs 0.60 ± 0.10 (2.44σ)**; HS surface δ¹³C +2.41 vs +1.31 | ⛔ FAIL (NEW with the cold box) | 09-08 |
| Isotopes — deep Δ¹⁴C profile | z −1.15 / +1.24 / +0.50 | ✅ | 09-08 |
| Sinks | GATE 7 ocean 2.98 / land 3.38 GtC/yr | ✅ | — |
| Surface DIC | GATE G +1.57 | ✅ | — |
| Perturbation lifetime | IRF(100) **0.279** vs Joos 0.409 (a comparison) | reported; hypothesis still owed | 08-18 |
| Drivers | CO₂ emissions ✅; GMST ✅ (q10 −2.2 strained); volcanic diffuse light ✅ (γ 0.25); ENSO ⛔ (above); solar declined 09-04f | — | — |
| Strained priors | `rep_dC` +3.40 (CO₂ level bias ~3 ppm), `sst_seas_amp_NH` −2.96, `kz_deep_frac` −2.51, `pump_hs` +2.31, `q10` −2.22 | | |
| Release mechanics | LICENSE present; README status corrected; `DESIGN.md` §6 still says "all must pass" against a retired gate set; no CITATION | ⚠ | 09-04 |

## 3. What the arc taught about the model's structure (the reading behind the options)
1. **One sink demand, three unpriced knobs.** Rounds 3–5 moved 0.15 GtC/yr of modern uptake from the declared flush
   (70 Sv) to the cold-box exchange (1.83) to the piston velocity (+31 %): each time the fit took the cheapest quantity
   without a prior. Pinning both structure quantities to their observations left `k_w` — inside its prior — so nothing is
   strained by the sink now. But the lesson generalises: **any quantity without an observation prior is a compensator.**
2. **The LS column ventilates only by diffusion, and the diffusivity is 4–40× real.** At the winner K(100 m) = 11,700 m²/yr
   = 3.7 cm²/s, K(1000 m) 0.4 cm²/s, K_deep 0.04 (Ledwell et al. 1993's pycnocline 0.1 cm²/s is a RECOLLECTION). Every
   gradient must be held against it, so the LS pump exports **37 GtC/yr** (real global ~10, Nowicki 2022) concentrated above
   400 m, and only 0.18 GtC/yr reaches below 1000 m (real ~1.2 over the LS area; Martin et al. 1987 b = 0.858, SOURCED). The HS pump
   (5.3 GtC/yr, +2.3σ) then has to supply the entire deep. The same missing thing — subduction / mode-water ventilation
   and its upwelling return — is what the 09-04i reading named behind the δ¹³C gradient, the δ¹³C over-depletion and the
   ENSO ocean sign: **"the model has no ocean upwelling."**
3. **The cold surface is heavy because the deep is heavy** (option F, run 09-08f). With the air-sea alphas made
   T-independent the HS surface drops +2.41 → +0.70 and gate Q goes wrong-signed (−0.03) — so the term is the 2 °C EQUILIBRIUM
   fractionation, shipped correctly on 09-02. By box at PI (SH): ML +2.57, HS +3.22, HD/bottom +1.29 against an observed deep
   ~+0.4 — the whole ocean is 0.4–1.3 ‰ heavy and the HS box equilibrates a heavy deep toward a cold equilibrium. Switching the
   HS pump OFF makes the deep HEAVIER (+2.51), so the pump is doing its job and the deep simply lacks remineralised light carbon
   below 1000 m (0.18 GtC/yr from the LS pump vs ~1.2 real) — **option D is the candidate for Q and the HS δ¹³C**, not the
   alphas. Neither the flush nor the exchange moves it (u_hs ×2: +2.37; hs_asx ×2: +2.45).
4. **The short lifetime is a LAND question** (option H, run 09-08f). Pulse partition at the canonical: 100 yr air 0.28 /
   ocean 0.32 / land 0.41; 300 yr 0.20 / 0.37 / 0.43. Joos 2013's multi-model split (abstract, SOURCED): at 1000 yr the ocean
   has absorbed 59 ± 12 %, the land 16 ± 14 %, 25 ± 9 % airborne. Even allowing the horizon, the model's land share is ~2.5×
   the ensemble's and the ocean's 0.6× — consistent with the pulse-partition panel's "40 % of a pulse in the land at 3000 yr
   with no gate on it" ([[ccx_pulse_partition_panel]]). The hypothesis owed since 08-18: the land sink of a perturbation does
   not saturate/return; the IRF gap is not an ocean-capacity question.

## 4. Options, ranked by payoff to the CHAIN per unit cost (each with the test that decides it)
| # | option | what it fixes | cost | pre-check / decisive test | ruling? |
|---|---|---|---|---|---|
| **A** | **ENSO-modulated upwelling limb** ("Fix B-lite"): scale the interior→ML exchange at the ML base by (1 − γ·Niño3.4) in the existing hemispheric boxes, γ ≥ 0 by construction, so the ocean's ENSO response is upwelling suppression (right sign) and `gamma_enso_ocn` (the additive flux) retires | link 2 (the blocker), and V downstream | 1–2 days, both cores | Probe unrefitted at the canonical: does the solubility-only r flip from −0.52 to ≥ +0.3 at a γ the observed +55 µatm reservoir (`ccx_fixB_reservoir_priced`) implies? Prereg before building | **yes** — A vs B |
| **B** | **Fix B proper: a tropical box** (equatorial upwelling reservoir, +55.5 µatm; the model's representable tropical-minus-global contrast is exactly 0) | link 2; the δ¹³C gradient (H) if the upwelled water is light; the ventilation root (§3.2) partly | 1–2 weeks (structure, spinup, parity, app) | Same probe as A on the built box; H's z at the refit | **yes** |
| **C** | **The seasonal mixed layer, option B** (`notes/options_2026-09-08d_seasonal_h_ml.md`): entrainment amplitude DERIVED from the Holte cycle × the model's sub-ML DIC step, both hemispheres, ¹³C carried; `ent_seas_amp_SH` retires | the NH strain (−2.96), the mean-vs-max `h_ml` ambiguity, the seasonal isotope rows | 1 day + refit | Pre-checked: SH 10–17 / NH 8–14 µmol/kg untuned. P2: the NH strain relaxes; P4: `d13c_seasonal_*` must not pay | yes (round 6?) |
| **D** | **Martin-curve remineralisation for the LS pump** (a SOURCED exponent replaces GLODAP's shallow shape below the profile's span) | the 4× LS export, the deep supply (0.18 → ~1 GtC/yr below 1000 m), and hence the HS export's +2.3σ | 1 day + refit | Pre-check: with b = 0.86 the LS pump at its current 37 GtC/yr puts 5 GtC/yr below 1000 m — too much; the test is whether the refit lowers `pump_grad`/`kz` together and the HS export falls toward its prior | yes |
| **E** | **A ventilation (mode-water) limb**: subduction from the LS ML into layers 2–5 with an upwelling return, sized on Talley's 8 Sv SAMW/AAIW + subtropical subduction | the §3.2 root: lets `kz` fall toward real values; H, the export, the ENSO sign share this mechanism with B | weeks | Falsifiable prediction: `kz` at the refit falls > 3× with the deep row still held | yes — the long-term structure |
| **F** | ✅ DONE 09-08f (§3.3): the term is the 2 °C equilibrium fractionation on a deep 0.85 ‰ too heavy ⇒ the fix is **D**, not the alphas | gate Q, HS δ¹³C | done | — | — |
| **G** | **Gate the δ¹³C gradient LEVEL** (objective: the gradient rows score variation through a fitted offset) | H becomes fittable; nothing physical | hours | Mutation-tested row; then read what the fit pays to close 1.97× | yes (objective) |
| **H** | ✅ DONE 09-08f (§3.4): land 0.41 / ocean 0.32 at 100 yr vs Joos's 1000-yr 16 % / 59 % ⇒ the lifetime is a LAND-saturation question; next: a gate on the land share of a pulse (an ordering against Joos's split) and a land-return mechanism scoped | the Joos hypothesis | done | — | the gate is objective work |
| **I** | Hemisphere-specific `tau_ex` or a stratospheric bomb reservoir (the NH peak is 0.95 yr late; "one scalar serving two things" — `tau_ex`, `seas_lag_p`) | gate 5 | 1 day | Probe: a 1–2 yr NH stratospheric lag on the bomb input alone moves the NH peak; if not, it is the exchange | yes |
| **J** | Release mechanics: `DESIGN.md` §6 rewritten against the 09-04 ledger with the two standing failures named; CITATION + DOI | documents | hours | — | J is Marcus's text |

**Recommended order.** F and H are done (above); G is cheap objective work and can run without a ruling. **A before B**:
A is the one-day probe of the same physics B builds; if A flips the sign at a physically sized γ, B's case is made (or A
suffices for the pedagogy); if A cannot, the reservoir contrast is essential and B is the build. **C** is the next refit
either way (round 6) — it is pre-checked, cheap, and repairs a strained prior rather than a benchmark. **D** should ride with C
(one refit, both mechanistic, both with sourced inputs — the Martin exponent is now SOURCED: 0.858, Martin et al. 1987). **E** is the structural direction A/B/D all point to and is the research question, not the next round.

## 5. What is explicitly acceptable as-is
The IRF gap (a comparison, hypothesis owed — option H); gate V (non-blocking, downstream of A/B); `rep_dC` +3.4 (a CO₂ level
bias absorbed by a fitted offset, previously traced to the LUC INPUT — a data question); K_deep 129 vs HILDA's 465 (HILDA's
was a 1992 fit; the deep row and the profile contrast are inside 1–2σ here); the HS export +2.3σ IF option D lands; the
absence of a posterior (both Hessian blockers gone at `ent26`; not re-measured at the HILDA canonical — an upgrade, not a gate).
