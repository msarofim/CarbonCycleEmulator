# Handoff — 2026-09-08j. WHERE THE MODEL STANDS after Phase 1 and the cheap probes, and the RECOMMENDED next step: round 6 = OPTION C ALONE (the seasonal mixed layer, derived amplitude), with the three rulings and one data check done first; B after C; E as the structural build D and the gradient both need; D shelved until E.
# **Every model number here is GENERATED at the canonical `hilda31` by scripts named in the 09-08h/i handoffs (`outputs/diagnostics/*_20260908.*`). The two recollections (Hoffert 1980's 4 m/yr; equatorial upwelling "tens of Sv") are labelled where used.**

Read first: `notes/handoff_2026-09-08i_cheap_probes.md` (the probes), `notes/handoff_2026-09-08h_phase1_results.md`
(Phase 1), `notes/assessment_2026-09-08_acceptable_state.md` (options A–J, still the option list),
`notes/options_2026-09-08d_seasonal_h_ml.md` (option C's design and P1–P5). Memory: [[ccx_cheap_probes_20260908h]],
[[ccx_gate5_argmax_on_bimodal]], [[ccx_phase1_cheap_tests_20260908g]], [[ccx_pedagogical_not_emulator]] (the standard
and the Joos ruling), [[ccx_seasonal_h_ml_option]].

## 1. State of the model (canonical `hilda31`, unchanged since 09-08f; nothing adopted since)
| chain link | at hilda31 | what the last two days changed |
|---|---|---|
| **ENSO → ocean (THE BLOCKER)** | 0.53× obs, solubility-only r −0.52 cancelled by fitted γ | T-A0: an ENSO-modulated upwelling gives the RIGHT sign, linearly, at ~26 Sv modulated (about the real equatorial upwelling — a recollection); the whole-column limb costs −135…−4001 unrefitted. **A is ruled out as built; B (a shallow tropical box with a thermocline return) is the build** |
| Seasonal NH strain | `sst_seas_amp_NH` −2.96 | unchanged; option C is the mechanism (pre-checked 8–14 µmol/kg untuned) |
| Hemispheric δ¹³C (H) | contrast +6.5σ; gradient 1.97× | GL added (level z −13.3) — FAIL, in the ledger |
| **Bomb ¹⁴C (gate 5)** | "NH peak +2.17σ late" | **an argmax on a double-peaked curve; the model's first-peak timing matches to 0.00 yr; the real miss is the trough (51 vs 111 ‰)** — the statistic needs replacing |
| Air-sea δ¹³C (Q) | 2.44σ | the level is between the two alpha pairs; the gradient is the pump's deep delivery (22 % short) |
| Deep Δ¹⁴C profile | inside 1–2σ | pins K(z): no room in `kz`/`kz_deep_frac` at all |
| Lifetime (IRF) | 0.279 vs 0.409 | **a comparison only, by ruling: never scored, never fitted to**; land share of a pulse also a comparison |
| Alkalinity / salinity | one constant | closed: not a lever; `alk_hs` default-off |
| Posterior | none | not blocked by the model; blocked by the σ_rep table's bin-edge shelf (a ruling) |

## 2. What the probes settled (so the next session need not re-derive it)
1. **D (Martin remineralisation) cannot be done without E.** At the model's K(z) the diffusive return below ~1000 m
   carries 0.004 GtC/yr; Martin at the literature export sends 0.84 through that interface (204× short). The profile
   form at a held gradient (T-D0) starves the export instead of delivering light carbon. So "round 6 = C + D" is
   withdrawn as a design: a shape change does not deliver D's physics.
2. **The δ¹³C deep miss is the pump's delivery, the surface is at equilibrium.** Like-for-like modern gradient 0.40
   vs 0.89. Any future D/E prereg goes on the modern surface−deep gradient and the deep level, never on PI numbers.
3. **The NH bomb "lateness" was the estimator**; the levers τ_ex / k_w / h_ml do not move either peak's time. The
   delivery series' tail (25 % after 1965.5, 14.6 % after 1969.5; `data-raw/build_bomb_c14_source.R`, Tans Table 2
   quarterly intervals with an exponential tail) is the open data question behind the trough.
4. **K(z) is pinned by the Δ¹⁴C profile** (+CO₂ levels): every move costs tens to thousands of log-units. Light carbon
   reaches the deep only advectively in this model — the same root as the ENSO sign, the δ¹³C gradient and the
   export: "no ocean upwelling/ventilation" (E).
5. **Alkalinity is closed**; T-hml's shelf is the σ_rep table; gate L and the IRF are comparisons.

## 3. Rulings owed BEFORE the next build (an hour of Marcus's time; each changes a number or a gate)
1. **Gate 5's NH statistic** — first-peak time (matches to 0.00 yr), trough depth (51 vs 111: FAIL), or drop the time
   bound and let the `d14c_NH` stream carry the shape. My recommendation: the trough depth as the bound (it is the miss),
   first-peak time reported.
2. **The σ_rep table** (`data/obs_glodap_sigma_rep.rds`): smooth across the 25 m bin edges / re-bin / leave. Costs 0.5
   log-units at this mode and is what blocks a Hessian-based posterior. Recommendation: re-bin on the model's own
   layer edges (removes the step at its source), an objective change to be stated in the CHANGELOG.
3. **GL's bound**: observation se (z −13) or with the CO₂ control's representation allowance (z −9). Recommendation:
   the augmented form — it is the CO₂ control that licenses reading the δ¹³C level at all.
4. **The bomb delivery tail** — a data check, not a ruling: whether `BOMB_T2_DROP_FIRST` and the post-1969 exponential
   tail are what Tans's Table 2 supports (half a day, `build_bomb_c14_source.R`).

## 4. Options for the next build, ranked on the standard (the CHAIN: fits × pedagogy per unit cost)
| option | what it fixes | cost | risk | rank |
|---|---|---|---|---|
| **C — the seasonal mixed layer, derived amplitude (option B of the 09-08d note)** | the NH strain (−2.96) by a MECHANISM; the mean-vs-max `h_ml` ambiguity; `ent_seas_amp_SH` (a fitted compensator) retires; ¹³C signature scored by the `d13c_seasonal_*` rows | 1 day + a Torch array (~2.5 h wall) | LOW: pre-checked untuned to the observed order; P1–P5 drafted | **1** |
| **B — the tropical upwelling box** (shallow, thermocline return, ~26 Sv modulated) | THE BLOCKER (ENSO sign); some of H; the first advective limb | 1–2 weeks: structure, spinup fixed point, C++ parity, app | MEDIUM: T-A0 sized it; the deep must stay untouched (the Δ¹⁴C rows) | **2** |
| **E — the ventilation limb** (subduction + deep return) | the ROOT: the export, the δ¹³C gradient/level, D's return path, K(z)'s 4–40× | weeks | HIGH: the research question | **3 (after B; B's machinery is reused)** |
| D — Martin remineralisation | the export shape | — | needs E first | shelved |
| A | — | — | ruled out as built | — |
| I | — | — | ruled out (and the miss was the estimator) | — |
| Posterior at hilda31 | the first posterior | a day after ruling 2 | low | with ruling 2 |

**Why C before B, even though B is the blocker.** C is the one build with a written prereg, an untuned pre-check that
lands at the observed order, and a one-day cost; it repairs a strained prior with a mechanism visible to the student
(winter deepening entrains DIC-rich, isotopically light water). B is weeks and touches the spinup fixed point. Doing C
first gives B a canonical whose seasonal channel is already honest, so B's refit judges ONE thing (the ENSO sign and its
price), which is what every round since 09-04 has taught: ship the structure, then refit, one question per round.
**Why not D or "C + D".** §2.1. **Why not E first.** E is the right structural answer to four defects at once, but its
design is unconstrained without B's shallow return in place; B is E's first instance, sized by T-A0.

## 5. THE RECOMMENDED NEXT STEP, concretely: round 6 = C alone
1. Rulings 1–3 (§3) and the data check (§3.4), in that order; commit each.
2. **Prereg `notes/prereg_2026-09-0X_round6_seasonal_ml.md`** from the 09-08d note's P1–P5, with two additions:
   - P6: `sst_seas_amp_NH`'s prior-z relaxes from −2.96 to inside 2σ (the load-bearing prediction, the NH analogue of
     09-03's P2), AND the SH amplitude the mechanism derives lands in [10, 17] µmol/kg at the round-5 gradient.
   - P7: the modern surface−deep δ¹³C gradient (0.40 at `hilda31`) does not move by more than the `ocean_grad_d13c`
     row's σ_eff (0.16) — entrainment is a surface-cycle mechanism and must not be a deep lever in disguise.
   - No Joos row anywhere in the prereg (ruled). IRF reported after, as a comparison.
3. **Build** option B of the 09-08d note: replace the fitted `ent_seas_amp_SH` with `(C₁ − C_ml)(t) × f_h(month)` in both
   hemispheres, ¹³C carried, from `data/obs_mld.rds$seasonal` (the two 12-month `f_ent` rows already exist). Both cores
   (R `ccx_deriv`, `src/ccx_core.cpp`), one expression each; parity test; a mutation test at an explicit non-zero
   amplitude ([[default_off_hides_the_bug]]). 31 → 30 parameters; comparable on LIKELIHOOD only.
4. **Probe unrefitted at `hilda31`** (the T-D0 pattern): the derived amplitudes, the seasonal rows, gate S, P7.
5. **Refit on Torch** (say the verdict: a 30-parameter multistart is a Torch array, not a laptop job — 24 starts, one
   wave, ~2.5 h; the 09-08e recipe, port targets committed at the launch commit, preflight 8/8, NEVER re-ship the bundle
   mid-array [[never_reship_mid_array]]).
6. Score against the prereg; adoption is Marcus's call; the whole-model scorecard arm; then B's design note.

## 6. Files and state the next session inherits
- Canonical: `hilda31` (`calibration/output/refit_20260908_hilda31/mode_fit_pumpN.rds`, 31 par, struct hilda,
  logpost −1478.66). ⚠ Its stored `streams` field has 23 rows (the promote script now writes 25 with the profile rows;
  not re-promoted).
- Shipped since 09-08f, all default-off / objective-side: `alk_hs`; gates GL (a gate) and L (a comparison); the
  struct-resolution lint (`test-mode-struct-lint.R`, 29 files / 32 sites, convert on touch); the promote script's real
  gate 5; per-edge flux recording + the seven-box app diagram; `calibration/lib_martin_shape.R` (session-local
  override, sourced by two diagnostics).
- Suite: 2208 pass / 3 fail (the pre-existing set: `test-alpha-as.R:116-117` gate Q deliberate, `test-seas-lag-split.R:199`)
  / 4 skip; the flux, lint, parity and gate-bounds files re-run green after the last edits.
- Git: `b18c29e` on `main` (CarbonCycleEmulator), tree clean, NOT pushed.
- Memory: `INDEX_ccx.md` is at 17.2 KB of its 18 KB ceiling — SPLIT before the next addition (the 09-08 arc — Phase 1,
  the probes, the gate-5 finding — is a natural block to move to `INDEX_ccx_arch` once round 6 lands).
