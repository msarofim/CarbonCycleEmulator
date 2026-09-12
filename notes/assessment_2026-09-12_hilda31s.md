# ASSESSMENT — CarbonCycleEmulator at the `hilda31s` canonical: is it in an acceptable state, and what are the best options? (2026-09-12)
# The FULL MODEL EVALUATION owed by `handoff_2026-09-11c` §2, written the session after `hilda31s` (the HILDA space with the SEASONAL MIXED LAYER ON, `seas_ml` 1, periodic spinup, corrected annual-mean observables) was adopted. **Every model number is GENERATED** this session at the three arms of `calibration/diag_whole_model_scorecard.R` → `outputs/diagnostics/whole_model_scorecard_20260911.{log,rds}` (run 2026-09-11 23:50–2026-09-12 00:30 local; the tag is `Sys.Date()` at launch), plus the limb decompositions in this session's scratch scripts (reproduced in CHANGELOG 2026-09-12). The last full evaluation was 09-08f at `hilda31` (`assessment_2026-09-08_acceptable_state.md`). **Adopts nothing.**

## 0. The standard (Marcus, 09-03; `notes/assessment_2026-09-04_public_readiness.md` §0)
A pedagogical model, not an emulator: **the product is the CHAIN** — "constrain the model with seasonal and isotopic data ⇒
long perturbation lifetimes emerge." A defect blocks release if it breaks a link: an observable matched by CANCELLATION, or a
wrong-signed mechanism cancelled by a fitted coefficient. A benchmark miss with the right mechanism is a research question.
Nothing derived from Joos 2013 may score the model (Marcus 09-08h): 12 and L are comparisons.

## 1. VERDICT: NOT YET ACCEPTABLE — the same link is broken as on 09-04 and 09-08, and the seasonal mixed layer did not touch it
The seasonal mixed layer is the first structural change since 09-04 that moved a CHAIN link, and it moved the right one: the
NH seasonal cycle now has a real entrainment channel (0.63 ppm at MLO, in phase with the cycle), the SH ocean limb's DIC side is
carried 62 % by entrained water instead of 100 % by a pCO₂-side shim, `sst_seas_amp_NH` (−2.89 → −1.73) and `ent_seas_amp_SH`
(+2.10 → +0.44) are no longer strained, and GATE P7 says the mechanism is not a vertical-gradient lever (0.17× its bound,
toward the observation). It did this at zero likelihood cost (−0.43 on the common rows vs the control) and with the Hessian's
`h_ml` instability gone. **It moved nothing on the release blocker.** The ENSO → ocean link is still a wrong-signed solubility
path (r **−0.525**, slope −0.169 GtC/yr per index) overturned by fitted coefficients to **0.57×** the observed sensitivity
(0.53× at the control); the hemispheric δ¹³C contrast fails at **+6.52σ** with the gradient at **1.97×**; GATE Q is slightly
WORSE (2.41 → **2.63σ**); GATE V is unchanged (−2.63). **A student switching ENSO on still sees roughly the right answer
produced by the wrong physics.** That was the blocker on 09-04 and 09-08 and it is the blocker today.

Two things this evaluation found about the EVALUATION MACHINERY, both fixed this session and both objective-neutral:
- ⛔ **The scorecard was spinning every arm up ASEASONALLY.** `dg_run`, `dg_gateG`, `dg_gateL_partition` and the IRF block
  called `ccx_spinup()`; a mode fitted under the periodic spinup (every file since 09-09x) does not reproduce under it, and at
  `seas_ml` 1 the miss is not small: `hilda31s` reads **−3889.6 vs its stored −1442.4** (2447 log-units off its own mode — the
  09-09t leak's exact mechanism, a seasonal box started from an aseasonal equilibrium). Every gate now spins an arm up the way
  its file says it was fitted (`dg_spinup()`, the file's `spinup` label), and section 0 of the scorecard PROVES each arm
  reproduces its stored streams (`hilda31p` +1.1e−9, `hilda31s` +1.7e−11; `ent26` −6.9e−3, the objective having moved under
  it since 09-03). ⚠ The one number this had already put on the record: GATE Q "6.38 vs 3 × 2.42" at the canonical (CHANGELOG
  09-11 (8), `test-alpha-as`) was an off-mode read; on-mode it is **6.2 vs 3 × 2.63**, same verdict (the pair stays red).
  No output file carried the off-mode read; the 09-08 scorecard logs are all aseasonal-fitted arms and stand.
- ⛔ **GATE S had a blind spot, and it fired.** Its knockout zeroed the SST sine and the entrainment shim — the two SH-ocean
  seasonal drivers the model HAD. `seas_ml` added a third (the mixed layer's own entrainment), so the "SH ocean limb by
  knockout" at `hilda31s` read the residual of a partial cancellation: **0.410 ppm @ 4.53 mo, FAIL** (−2.88 mo outside the
  bracket) — while the WHOLE limb is **0.465 @ 8.96, PASS**, and hemisphere-clean (the NH mixed layer's 0.107 ppm leak into
  SPO removed by a diagnostic-only override) **0.451 @ 9.41, PASS**. The 27g bug's exact class ("a one-limb knockout gates a
  limb that is not the one named"), one limb later — and the test that guarded 27g pinned the two-name list, so it passed.
  `SL_CASES$SH_ocean` now carries `seas_ml = 0`; the test guards three names and a POWER check (the switch moves the limb by
  4.4 months at the canonical; mutation-tested: dropping the switch fails both). ⚠ `seas_ml` is a whole-model switch, so
  the gate's limb includes the NH mixed layer's leak (0.45 mo of phase, both readings inside the bracket); a PER-HEMISPHERE
  handle on the MLD cycle is OWED (§4, option M) — and until it exists the 27q three-limb decomposition is incomplete at
  `seas_ml` 1 (`NH_origin` cannot include the NH mixed layer).

## 2. The state at the canonical (arm C of the scorecard; the control `hilda31p` = arm B, `ent26` = arm A)
| link / goal | measure at `hilda31s` | vs `hilda31p` | status | since |
|---|---|---|---|---|
| **Seasonal cycle — ocean phase** | GATE S: SPO ocean limb **0.465 ppm @ 8.96 mo**, bracket [7.41, 10.41] (hemisphere-clean 0.451 @ 9.41) | 0.365 @ 8.95 | ✅ PASS | 09-04 |
| Seasonal — the SH ocean limb's ANATOMY | SST sine 0.898 @ 4.13 **opposed by** entrained water 0.824 @ 9.68 + shim 0.503 @ 9.80 → net 0.465 @ 8.96 | SST 0.817 @ 4.01 vs shim 1.142 @ 9.69 → 0.365 | ⚠ two RIGHT-signed mechanisms in opposition (Takahashi-type thermal vs DIC), only their NET is gated; the shim still carries **38 %** of the DIC side | 09-12 |
| Seasonal — NH entrainment channel | the NH mixed layer contributes **0.63 ppm @ 3.8 mo** at MLO, in phase with the 6.87 ppm cycle; `sst_seas_amp_NH` z **−1.73** (1.45 K vs 2.25 observed) | absent; z −2.89 | ✅ the 09-03 "NH has no entrainment channel" is CLOSED | 09-11 |
| Seasonal — what the ML shows a reader | h(t) 35–109 m (mean 64.8); DIC cycle **±13 µmol/kg** (NH max Feb, SH max Aug), surface δ¹³C **±0.07–0.08 ‰** | ±2 µmol/kg, ±0.01 ‰ | ✅ (the handoff's "±40 µmol/kg" does NOT reproduce under the annual-mean reader; the prereg's untuned 8–17 does) | 09-12 |
| **ENSO → ocean** | slope +0.0658 = **0.57× obs**; solubility-only **−0.169, r −0.525 (wrong sign)** cancelled by `gamma_enso_ocn` NH 0.341 / SH 0.045 | 0.53×; r −0.523; γ 0.306 / 0.092 | ⛔ **BROKEN LINK — the blocker** | 09-04 |
| Interannual variability | GATE V −2.63σ (too smooth, 0.77×) | −2.72 | FAIL, non-blocking (downstream of ENSO) | 09-04 |
| **Hemispheric differences** | GATE H contrast **+6.52σ**; GATE GL z **−8.68** (bare −13.32): δ¹³C gradient **1.97×**; CO₂ control −1.03 se PASS | +6.53 / −8.72 | ⛔ FAIL | 09-04i |
| **Isotopes — bomb ¹⁴C** | GATE 5 (trough form since 09-09b): NH trough z **−1.79**, SH peak +1.48, lag −0.94, orderings ok | −1.81 | ✅ PASS (was FAIL in the retired peak-time form; the NH first-peak TIME matches obs) | 09-09b |
| Isotopes — air-sea δ¹³C disequilibrium | GATE Q **0.863 vs 0.60 ± 0.10 = 2.63σ** (NH 0.833, SH **0.893**) | 0.841 / 2.41σ | ⛔ FAIL, slightly worse: the SH surface got heavier | 09-08 |
| Isotopes — vertical δ¹³C gradient | P7: −0.300 → **−0.327**, move 0.17× the bound, TOWARD −0.861; DIC 300 → 304 (target 233; the deep row scores −17.4) | | ✅ PASS; the ocean_deep group is the arc's remaining cost (−1.78 vs control) | 09-11 |
| Isotopes — deep Δ¹⁴C profile | group −9.38 (ent26 −241.6) | −9.15 | ✅ | 09-08 |
| Sinks | GATE 7 ocean 2.99 (z −0.53) / land 3.36 (+0.63) GtC/yr | same | ✅ | — |
| Surface DIC | GATE G z **+1.24** (+22.6 µmol/kg) | +1.56 | ✅ improved | — |
| Perturbation lifetime (comparison 12) | IRF(20/100/300) **0.480 / 0.279 / 0.202** vs Joos 0.596 / 0.409 / 0.322 | identical | reported; unmoved by the seasonal physics (as 09-03 found) | 08-18 |
| Pulse partition (comparison L) | @100 yr land 40 / ocean 31 / air 28 %; **@1000 yr land 32 / ocean 49 / air 19 %** vs Joos 16 ± 14 / 59 ± 12 / 25 ± 9: z **+1.16 / −0.84 / −0.68** | identical | reported: at Joos's own horizon the split is INSIDE the ensemble spread; the miss is the first century | 09-12 |
| Drivers | CO₂ emissions ✅; GMST ✅ (`q10` −2.11); volcanic ✅; ENSO ⛔ (above) | | | |
| Strained priors (|z| > 2) | `rep_dC` **+3.11**, `pump_hs_gcm2` +2.39, `kz_deep_frac` −2.38, `q10` −2.11 — **four, down from six** | + `sst_seas_amp_NH` −2.89, `ent_seas_amp_SH` +2.10 | ⚠ | |
| Posterior | Hessian PD, cond 3.4e5, `h_ml` 64.8 ± 2.3 m (P8 wall 75 m at 4σ); a posterior SAMPLE would hit the wall | `h_ml` step-unstable | ⚠ an upgrade, not a gate | 09-11 |
| Release mechanics | as 09-08: `DESIGN.md` §6 against a retired gate set; no CITATION; ⚠ `R/model.R` `ccx_seas_ml_on()`'s comment still says "no periodic spinup is needed" | | ⚠ | |

Likelihood by group, C − B (the arc's own accounting): gradients +0.47, d13c_seasonal +0.58, co2_level +0.38, d13c_level
+0.35, bomb +0.21, co2_seasonal −0.61, **ocean_deep −1.78**, hs_surface −0.18; total common −0.43. Priors +5.8.

## 3. What this evaluation taught about the model (the reading behind the options)
1. **The seasonal link is now matched by two right-signed mechanisms in opposition, and only their net is gated.** Inside the
   SH ocean limb the thermal term (0.90 ppm at SPO, peaking month 4.1) opposes the DIC-side term (entrained water 0.82 + shim
   0.50, month 9.7–9.8), netting 0.465 @ 8.96. That is the real Southern-Ocean anatomy (thermal vs non-thermal pCO₂ in
   antiphase), so it is NOT the cancellation the standard forbids — but the RATIO of the two is unconstrained, and a reader
   shown the anatomy could be shown the wrong ratio. At the control the same net was produced by the SST sine against a shim
   that moves no carbon (0.82 vs 1.14). ⇒ the shim is smaller (18.7 → 8.2) but still 38 % of the DIC side; whether the real
   entrainment can carry ALL of it is a one-refit question (option C′).
2. **The seasonal physics and the ENSO physics are independent, again.** Round 6b moved the seasonal rows and the priors and
   left the ENSO slope, its solubility-only sign, GATE V, GATE H, the IRF and the pulse partition where 09-08 left them.
   `gamma_enso_ocn_SH` halved (0.092 → 0.045) and `gamma_enso_ocn_NH` grew (0.306 → 0.341): the fitted patch re-balanced
   across hemispheres with no change in what it is patching. Three refits (09-03, 09-08, 09-11) have now shown that no
   amount of seasonal or ocean-structure work reaches the ENSO link — it needs its own mechanism (option A = option B's
   ruling 2, the Niño3.4 limb on `ml_lo`).
3. **The deep is the arc's only cost, and it is where the mechanism entrains from.** ocean_deep −1.78 (the DIC gradient 300 →
   304 against 233 ± 29; the deep DIC row was already the model's worst structural row), GATE Q +0.22σ worse with the SH
   surface heavier (+0.893). Entraining sub-ML water into a seasonal ML pulls on the vertical gradients, so the LS column's
   ventilation-by-diffusion-only root (09-08 §3.2: `kz` 4–40× real, the LS pump 37 GtC/yr above 400 m) is now load-bearing
   for the seasonal link too. Option D (Martin remineralisation) and E (a ventilation limb) gain a second motivation.
4. **The lifetime miss is a first-century miss.** At Joos's own 1000-yr horizon the partition is inside the ensemble's
   spread (land +1.16σ, ocean −0.84σ, air −0.68σ); at 100 yr the land holds 40 % and IRF(100) is 0.279 vs 0.409. The
   09-08 reading ("the land share is ~2.5× the ensemble's") was a 100-yr share against a 1000-yr benchmark; like-for-like the
   land is +1.2σ high, not 2.5×. The hypothesis owed since 08-18 narrows: a land sink that takes up too FAST in the first
   century (and/or an ocean that takes up too slowly there), not one that never returns.
5. **The bomb link is no longer a defect.** GATE 5 in its 09-09b trough form passes at every arm (z −1.79 to −1.81); the NH
   first-peak time matches to z +0.0008 (ledger). Option I (hemispheric `tau_ex` / a stratospheric reservoir) is RETIRED as
   a chain fix; the `lag`-inherits-the-argmax caveat stands as recorded.
6. **Two diagnostic numbers disagree and neither has been arbitrated**: the solubility-only ENSO correlation at `ent26` is
   **−0.432** in the 09-04g diagnostic (`diag_gateS_indep_and_fixB.R` PART B, the number in memory) and **−0.522** in the
   scorecard (both claim the 09-04g estimator: annual uptake ~ year + Niño3.4, 1959–2024). Same sign, same verdict, 20 %
   apart. Not chased here; the test is to run both at the same arm and diff the index annualisation / window / detrend.

## 4. Options, re-ranked by payoff to the CHAIN per unit cost (each with the test that decides it)
The 09-08f list, updated: **C is DONE**; **A/B are option B's rulings 1–2** (`ccx_option_b_rulings`); **P7′ is no longer B's
motivation**; **G is built** (GATE GL) and **I is retired**.
| # | option | what it fixes | cost | decisive test | ruling? |
|---|---|---|---|---|---|
| **A** | **The Niño3.4-modulated upwelling LIMB on `ml_lo`** (option B ruling 2; "Fix B-lite"): scale the interior → ML exchange by (1 − γ·Niño3.4), γ ≥ 0, so the ocean's ENSO response is upwelling suppression with the RIGHT sign and `gamma_enso_ocn_*` retires | link 2 — the blocker; V downstream | 1–2 days, both cores + parity | UNREFITTED probe at `hilda31s`: does the solubility-only r flip from −0.525 to ≥ +0.3 at a γ the +55 µatm reservoir implies (`ccx_fixB_reservoir_priced`)? Prereg first | **yes — A before anything else** |
| **B** | Option B proper: `ml_hi` = the HS box with its own poleward MLD cycle (rulings 1, 3–6; R side written, C++/parser/`h_hs` prior/tests owed) | P1c box identity (a low-latitude box carrying a high-latitude cycle); the HS δ¹³C / Q via a seasonal cold box | weeks | its prereg §2a–2c; the HS Holte prior must land `h_hs` 417 → ~103–128 m first | yes — after A |
| **C′** | **Retire the shim**: refit `hilda31s` with `ent_seas_amp_SH` PINNED to 0 (one Torch array, `seas_ml` 1) | tells whether entrained water carries the whole DIC side of the SH ocean limb | one array | GATE S must still pass; `co2_seasonal_SPO` / `d13c_seasonal_SPO` must not pay > 1 log-unit each; the thermal:DIC ratio (option K) read before and after | yes — cheap, and it is P12's original promise |
| **D** | Martin-curve remineralisation for the LS pump (b = 0.858 SOURCED) | the deep DIC row (−17.4), Q (the heavy deep), `pump_hs` +2.39, `kz_deep_frac` −2.38 — and now the entrainment source (§3.3) | 1 day + refit | the refit lowers `pump_grad`/`kz` together and the HS export falls toward its prior; P7 re-read | yes |
| **E** | A mode-water ventilation limb (subduction from the LS ML with an upwelling return) | the §3.3 root; shares physics with A | weeks | `kz` falls > 3× at the refit with the deep row held | research direction |
| **G′** | Price closing GATE GL (an iso-fit frontier re-optimising at each step, the `ccx_gates_priced` method) | says what the 1.97× costs the rest of the objective — H/GL cannot be fixed by fitting (three refits have not moved it 0.01) | hours | the frontier's likelihood pinned to the objective's (the 253-log-unit self-check) | no ruling needed (diagnostic) |
| **K** | **Gate the thermal : non-thermal ratio inside the SH ocean limb** against an OBSERVATION (Takahashi et al. 2002's decomposition, or SOM-FFN's thermal/non-thermal pCO₂ split over the same 40–90 °S product GATE S uses) | §3.1: two opposing right-signed terms with an ungated ratio | a data task, then a gate | source first (none in the repo yet); power measured on the record (`hilda31p` vs `hilda31s` anatomy) before adoption | yes (a new gate is a ruling) |
| **M** | A per-hemisphere knockout HANDLE on the MLD cycle (zero one hemisphere's harmonics in `ccx_prepare`, R + C++ parity) — a diagnostic switch, not a mechanism | GATE S hemisphere-clean; completes the 27q decomposition at `seas_ml` 1 | hours + parity test | the override read this session (0.451 @ 9.41) reproduces through the handle | no ruling needed |
| **N** | Resolve §3.6 (the two ENSO estimators) | diagnostic hygiene before A's probe is read | an hour | both scripts at one arm, diffed | no |
| F, H, I | done / done / **retired** (GATE 5 passes) | | | | |
| **J** | Release mechanics: `DESIGN.md` §6 against the live ledger; CITATION; the stale `ccx_seas_ml_on()` comment | documents | hours | — | J is Marcus's text |

**Recommended order.** **N, then A's unrefitted probe** (the one-day test of the blocker's fix; everything else waits on
whether the sign flips at a physical γ). **C′** can run on Torch concurrently — it is one array and answers P12. **M** is
hours and should precede any GATE S reading that will be quoted. **K** needs its source before it is anything. **D** rides
with the next structural refit, whichever of A/B that is. **B** is the build after A's answer. **E** is the research question.

## 5. What is explicitly acceptable as-is
The IRF gap (a comparison; §3.4 narrows the hypothesis to the first century and the partition is inside Joos's spread at
1000 yr); GATE V (non-blocking, downstream of A); `rep_dC` +3.11 (the CO₂ level bias, a data question, unchanged by every
refit); `q10` −2.11; the deep DIC gradient 304 vs 233 ± 29 (inside 2.5σ_eff and the arc's declared cost, owed to D); the
shim at 8.16 IF C′ is run (it is 1.25× its centre, z +0.44, not strained — but a reader must be told it moves no carbon);
GATE G +1.24; the NH mixed-layer leak in GATE S (0.45 mo, both readings inside the bracket) until M lands; the absence of a
posterior sample (the Hessian is now clean; the P8 wall at 4σ is the sampling hazard, not a mode hazard).
