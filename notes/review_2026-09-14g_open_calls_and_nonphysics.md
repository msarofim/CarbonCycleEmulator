# Review — 2026-09-14 (g). The three open calls (pros / cons / a recommendation each), and a triage of the model's non-physical behaviour

**Basis.** The tr-box build and probe (CHANGELOG 09-14 f; `outputs/diagnostics/tr_box_probe_20260914.log`), a fresh read of the canonical
`hilda30c` at its own vector (numbers below, aseasonal twin for the PI structure), a read-only scan of every flag the code and notes carry
(93 items; the raw inventory is in this session's transcript and summarised in §B), and the 09-12 assessment. Every number is measured or
quoted with its source; where I recommend, I say so and why. Nothing here is built or adopted.

## A. The three open calls

### A1. R5 — `sst_tr_enso`: the tropical box's own Niño3.4 SST term (+0.20 K/index) ON, or 0
Measured this session: the HadSST4 hemispheric annual anomaly — which EVERY surface box already receives — itself regresses on Niño3.4 at
**+0.112 ± 0.031 (NH) / +0.092 ± 0.018 (SH) K/index** (1950–2024, detrended). The tr product's slope (annual +0.27 / +0.24; monthly +0.20)
is the box's ABSOLUTE slope, so switching it on double-counts ~0.1 K/index. (The cell's 0.97 has the same construction; there it is 10 %.)

| | ON at the product's 0.20 (cell idiom) | 0 (ML idiom) | ON at the EXCESS over the hemispheric anomaly (~0.10–0.16) |
|---|---|---|---|
| Physics | the tropics do warm more than the hemisphere in El Niño; local solubility is real | the hemispheric anomaly already carries ENSO; no local term for the ML either | the right decomposition: local = box − hemisphere |
| Sign | wrong-signed for the sink (warming ⇒ outgassing); it OPPOSES the cell's right-signed loop | — | same, smaller |
| Probe | ENSO slope **1.53× obs** (r +0.49) | **2.50× obs** (r +0.69) | between |
| Risk | the 1.53× is closer to obs BECAUSE a wrong-signed term cancels an over-strong right-signed one — the compensating-errors pattern [[ccx_enso_compensating_errors]] | leaves the loop's over-response visible (2.5×) — honest | needs a product rebuild (one regression), then the same double-count-free number for the cell |
| Consistency | matches the cell as built | matches the ML | matches neither until the cell is re-based too |
| Cost | 0 | 0 | ~1 h (regress `box SST − HadSST_h` on Niño3.4 in `build_tr_box_targets.R`; same for the cell) |

**Recommendation: the third — rebuild both slopes as the EXCESS over the hemispheric anomaly and switch them on.** The term is physical,
but as built it is double-counted, and its only effect in the probe is to hide the loop's over-response. If a choice must be made today
without a rebuild: **0**, so the array (if any) sees the loop's response undisguised. Either way this is a ~5 % effect on the ENSO slope
and does not move B1 (+101.6 → +101.7); it is not what the array's verdict turns on.

### A2. R6 — `kz_tr_frac`: the tr–layer-1 interface at the ML base's K (1, as ruled), a fraction, or fitted
What the interface does (NH, at `start_011`): exchange **5.62 /yr** at kz 11,319 against the box's own air–sea DIC equilibration **4.72 /yr**,
so the box tracks layer 1's cold-equilibrated DIC and sits **+68 µatm over the global surface** (obs +7.6). The lever:

| `kz_tr_frac` | tr − global (PI) | B1 (z) | Δlik vs first build | what happens |
|---|---|---|---|---|
| **1** (ruled) | +67.6 | +101.6 (+6.8) | −75.6 | the T-DIC disease moves from the cell onto the box |
| 0.3 | +0.5 | +131.6 (+11.2) | −119 (d14c_NH −57, d13c_MLO −48) | the box lands at obs by accident; the bomb-¹⁴C row loses 40 % of its surface intake |
| 0.1 / 0 | −73 / −170 | +161 / +194 | −270 / −788 | the box is DRAINED by its pump share (D2) with no resupply |

| | 1 as ruled | a fixed fraction (0.3) | a fitted stratification parameter |
|---|---|---|---|
| Pro | the column's own K; no new parameter; the "ML idiom" | puts the box where the observation is | lets d14c_NH, a tr-band pCO₂ row (+7.6, σ ≈ the mask floor) and B1 price it |
| Con | 10× the observed band excess; physically the effective K (a bomb-¹⁴C-fitted VENTILATION diffusivity, 3.5 cm²/s) stands in for extratropical subduction and has no business under the tropical thermocline (diapycnal ~0.1 cm²/s) | hand-picked; B1 does not move; the interaction with D2 makes any fraction < ~0.3 unphysical (a box drained by an export it cannot be fed) | a 34th name registered nowhere; identifiable, but it would be fitting a symptom of the pump field (§A3) |
| Verdict on PT1 | FAIL | FAIL | would not change the FAIL |

**Recommendation: do not rule R6 in isolation — it is subordinate to A3.** Whatever value it takes, T1 cannot reach +55.5, and the reason
(§A3) is upstream of the interface. If an array is nevertheless wanted as a record, run it at **1** (the design as ruled, so the array tests the
ruling and not a tuned fraction) with the tr-band pCO₂ contrast added as a CHECK row, not scored.

### A3. The design question — T1 as ruled cannot reach +55.5. What next?
The measured chain (NH, `start_011`): layer 2 (117–190 m, the cell's source) exchanges diffusively at **3.14 /yr** (kz_int 9240 up / 6961 down);
the 27-Sv loop replaces it at **0.045 /yr** — **69×** slower. The pump's divergence field at the canonical is **45.5 GtC/yr net export**
(NH 19.5: layers 7.8 / 7.0 / 2.4 / 1.5 / 0.5 …), against a literature POC export of 5–13 GtC/yr (the code's own note: "Do NOT read the solved
export as an estimate of real POC export"). So the DIC the cell exposes at 26 °C is set by a 45 GtC/yr export recycled through a 3 /yr
diffusive exchange; the loop is a 1.5 % perturbation on it. A second surface box cannot change that. Three routes:

| | **T5 — a tropical COLUMN** (tr over its own thermocline layers; the cell upwells from the tropical layer 2; lateral exchange with the extratropical column) | **a kz / source lever on the cell** (a factor on layer 2's exchange under the cell's footprint, or "the cell's source DIC = layer 2 − X") | **fix the root — the pump / kz structure** (option D: a Martin-shaped export of ~10–16 GtC/yr; option E: an advective ventilation limb so the gradient is held by export + slow ventilation, not by 11,000 m²/yr of diffusion) |
|---|---|---|---|
| Physics | the STC: subtropical water subducts warm, flows equatorward in the thermocline, upwells at the equator — the source water IS warm-equilibrated + remineralisation; gives the DIC-term-only B1 (+56/+43 by the 09-14c decomposition, i.e. ~+50–60 at obs) | none — layer 2 is one box; a "source correction" is the T2 shim by another name (declined 09-14 d) | the real ocean holds its gradient with ~10 GtC/yr of export against slow ventilation; the model holds it with 45 GtC/yr against fast diffusion; every warm surface box exposes the difference |
| What it fixes | B1 and the tropical band level; gives the tropics a stratified thermocline naturally | B1 by construction (fitted) | B1's root, the deep DIC gradient miss (304 vs 233 ± 29), the δ¹³C gradient level (0.40 vs 0.89), GATE H/GL's 1.97× — the assessment's own "options D / E" |
| Cost | 2 tropical layers per hemisphere (+4 boxes → 44) or a full column (+20 → 60); ≥ 1 lateral exchange parameter per layer or one bulk; area-weighted readers for every interior row (Δ¹⁴C profile, GLODAP gradient are global means); the pump field per column; a refit; 2–3 build sessions + an array | 1 session; no physics | the largest: the bomb-¹⁴C penetration that kz 11,000 buys must then come from ventilation limbs, and T-A0/T-A1/T-A2 showed each advective limb costs on the Δ¹⁴C profile (−104 at the bottom return); a re-bisection of kz; every registered mode moves; several sessions and arrays |
| Risk | new degeneracies (two kz's, the exchange); the tropical column's own kz inherits the same 11,000 unless D/E is done too — i.e. the T-DIC disease may reappear INSIDE the tropical column at a smaller amplitude | a shim in the canonical of a pedagogical model | the arc's largest refit; could fail on bomb ¹⁴C the way the conveyor did on Δ¹⁴C |
| Pedagogy | a tropical column is explainable (STCs are in every textbook) | not explainable | "export ~10 GtC/yr" is the number a student knows; 45 is a liability on every flux diagram |

**Recommendation: fix the root first (D + E), then decide whether T5 is still needed.** My reading of the numbers: T5 without D/E would
inherit the 11,000 m²/yr exchange inside the tropical column and land somewhere between +60 and +100 — better, not right — while D/E alone
might take the single-column cell to +60–70 (the DIC-term at a realistic export is smaller than +56/+43, which was measured at the 45 GtC/yr
field). A cheap preview before committing to either: **re-run `diag_tr_box_probe.R` at a Martin-shaped export capped at 12 GtC/yr with kz
refit by hand to hold the bomb-¹⁴C row** (option D's T-D0 idiom, one afternoon) and read B1 on the existing `hilda_eq` and `hilda_tr`. If B1
drops below +70 on D alone, T5 is unnecessary; if it stays > +90, T5 is the physics and D is still owed for the gradient rows. I would not
launch the T1 array: it would fit `w_eq` back toward 10 Sv for the same reason the first one did, and we already know why.

## B. Non-physical behaviour — the triage
93 flagged items were read (code comments with OPEN / grandfathered / provisional / shim / artefact / accepted-as-physics, DESIGN §6,
the 09-12 assessment, the gate ledger, the ocean and seasonal sub-indexes). Grouped by what I would DO about them. "Cost" is my estimate.

### B1. Root causes worth fixing — each generates several of the symptoms below
| # | what | measured | symptoms it explains | fix / cost |
|---|---|---|---|---|
| 1 | **The pump / kz structure**: export is "the divergence that holds `pump_grad` against kz", so with kz 10,964 m²/yr at the ML base the field is **45.5 GtC/yr net** (obs 5–13); surface exchange 2.9–3.6 /yr vs air–sea 2.65 /yr | `ccx_pump_export()`; this session | the T-DIC disease on every warm box (cell +133, tr +68); deep DIC 304 vs 233 ± 29 (−17.4); δ¹³C surface–deep 0.40 vs 0.89; GATE H +11.6 / GL −10.1 (gradient 1.97×); the grandfathered negative-layer pump (2 of 10 layers); GATE G's circularity; "kz 4–40× real" | options D (Martin shape: 16 / 1.4 GtC/yr holds the gradient) + E (ventilation limb). The arc's biggest item; §A3 |
| 2 | **ENSO → ocean is a wrong-signed solubility path cancelled by fitted `gamma_enso_ocn` 0.34 / 0.05** | r −0.525 solubility-only; net 0.57× obs | GATE V −2.5σ; "a student switching ENSO on sees the right answer from the wrong physics" | the cell arc IS the fix, and it is blocked by #1 (the cell's B1). Keep the arc; sequence it after D/E |
| 3 | **`alpha_photo` = 1 − 18/1000 is an unregistered literal** (`model.R:3435` cites a constants.R note that does not exist) | leaf δ¹³C −24.35 ‰ vs atm −6.47 at PI ⇒ Δ 17.9 ‰ | every δ¹³C row | register it in `data-raw/constants.R` with a source (Farquhar et al. 1989 C3 discrimination ~18–20 ‰, or a biome-weighted value); 30 min. The number is plausible; the ledger gap is the defect |
| 4 | **The HS surface δ¹³C is too heavy: 3.09 ‰ at PI** (SH surface 0.893 vs 0.60 ± 0.10 modern: GATE Q FAIL 2.63–2.88σ) | this session; ledger | GATE Q; d13c_seasonal_SPO | tied to #1 (the HS pump 86.6 gC/m²/yr strained +2.39) and to the alphas' lineage sharing GATE Q's data; re-measure after D |
| 5 | **Surface SST constants**: `sst_NH/SH` 18/16 typed, sourced 17.18/15.35 (0.7 K warm); `hs_frac` 0.16 vs the ocean's 0.126/0.130 (uniform-sphere derivation); `sst_hs` 2 °C a chemistry floor | 09-14 e; this session | every ML pCO₂ / α; HS rows | a constants batch in the NEXT refit (they move the mean state; each is a measured number now); the 2 °C floor needs the Waters 2014 k1k2 (+0.14 % LS pCO₂) — a separate ruling |

### B2. Pedagogical liabilities — the model's stated purpose (Marcus 09-03: pedagogical, not an emulator)
| # | what | why it matters to a student | fix / cost |
|---|---|---|---|
| 6 | "Biological pump (export)" reads **50.5 GtC/yr** in the flux trace / app | textbook 10 | = #1 |
| 7 | GMST held FLAT past 2024 in a bare `ccx_build_forcing()` future (`forcing.R:722`); `d13c_foss` flat; LUC NH share frozen at 2018 | ⚠ CORRECTED after writing (09-14 g, checked `app/server.R:118-151`): the app's futures / stylised / pulse tabs ALL run through `app_run_coupled()` → `ccx_run_coupled()` (R/climate.R), which overwrites the column with the model's own temperature; the flat hold is a placeholder for direct callers only and warns once per build. NOT a live app liability; the `d13c_foss` / LUC-share holds remain (unscored past 2024) | nothing to build; the review's "a day" was wrong |
| 8 | `gamma_enso_ocn` (a fitted additive term with no mechanism) in the canonical; the cell was meant to REPLACE it (PE2 partial: 0.34/0.05 → 0.20/0.13) | the ENSO panel's ocean response is a knob | retire with the cell once #1 lets the cell work |
| 9 | `ent_seas_amp_SH` shim: PINNED at 0 in the canonical (C′) but the free parent carries 8.16 µmol/kg = 38 % of the SH DIC side; moves no carbon, no isotope | the SPO seasonal panel's anatomy | keep pinned; document that the control's shim is what makes it scorable; the ratio of the two right-signed SH limbs is ungated (option K) — needs a source |
| 10 | `sst_seas_amp_SH` fitted 1.29 ± 0.19 vs observed 1.75 (2.4σ off, "confidently pulled down") | the SH seasonal SST is wrong by 26 % to make the ocean cycle fit | a mechanism (thermal:DIC ratio, option K) or pin to obs and price it |
| 11 | Revelle-frozen switch (a linearised pCO₂(DIC)) and the ocean-off switch (`k_w` 1e-3) | deliberate counterfactuals — fine, if labelled | label in the app; no model change |

### B3. Accept and document (priced, bounded, or below the noise)
| # | what | number | why accept |
|---|---|---|---|
| 12 | Land takes up too FAST in the first century: IRF(20/100/300) 0.480/0.279/0.202 vs Joos 0.596/0.409/0.322; inside Joos's spread at 1000 yr | z +1.16 / −0.84 / −0.68 @1000 | the assessment's §5 "acceptable"; kz is NOT the lever, the land axis is; a 4-pool land with one Q10 |
| 13 | The 1940s plateau: `rep_dC` +3.11, MLO mean residual +3.7 ppm, all-same-sign on four stations | | "a data question, unchanged by every refit"; no model reproduces it |
| 14 | `q10` 1.18 (prior −2.11σ), pushed down by the δ¹³C Suess over-decline (+0.214 ‰ MLO) | | structural (the Suess overshoot has no ocean upwelling to dilute it — #1 again); accepted in §5 |
| 15 | GATE V −2.5σ (variability 0.77×; Pinatubo +0.04 vs −1.94) | | non-blocking by ruling; downstream of #2 |
| 16 | Seasonal-ML interpolant overshoots the samples by 0.6 %; the SST-sine / entrainment rectifiers (~0.1 % of pCO₂); the polar-night quadrature | | guarded, priced, "accepted as physics" — physics, not artefact |
| 17 | Δ¹⁴C carries no fractionation (α₁₄ = α₁₃²; ~0.09 ‰ residual) | | the Stuiver–Polach convention; correct |
| 18 | Bomb window scored at σ_eff 25.7 ‰ (7× Hua); `bomb_total` 118.4 vs N&L ≤ 104.9; GATE 5's argmax on a bimodal peak (lump flip 1.86σ) | | rulings taken (T2 bias reverted); the peak-time miss is a forced residual of one `tau_ex` |
| 19 | Provisional constants that are PRICED: `fCO3` 0.082 (0.020 ‰), the kinetic-α two-point line (1.7 %), `PUMP_EPS13_*` (−20 / +1 ‰), `LIK_REP_SOURCE_D13C` −26.5 (8 % leverage), `FORC_NUC_NH_SHARE` 0.95, ocean areas/depth/ALK/ρ | | each carries its price; the ledger gap (nothing gates on the list being empty) is the defect — a source per constant is an afternoon's work and worth it for a published model |
| 20 | Deep Δ¹⁴C row `n_eff` 20 known to ×3.4; representation error 0 | | load-bearing on structure — a σ audit item (with the three from the 09-10 audit: ocean sink uninflated, `excess_c14_ocean` target set, `CCX_ICE_DISCREPANCY` off) — a ruling batch, not a build |

### B4. Dormant, retired, or provenance-only (no action beyond documentation debt)
| # | what | status |
|---|---|---|
| 21 | The conveyor (`q_conv`), `w_up`, `w_out_*`: all 0 at every registered mode; dead on sign for ENSO; Config A leaves NH oc1–9 advectively dead; their ML legs do not close under D1 (refused by name) | dormant; if E is built, rewrite them as volume × source concentration first |
| 22 | Legacy air–sea alphas (−2/−10 ‰; invasion 2.4× too large; GATE Q 6.4σ wrong sign pre-09-02) | behaviour-preserving path only |
| 23 | SPO seasonal targets inverted through the model (`SPO_SEAS_*_INV`); the inversion cannot run at the canonical | retired; GATE S on the pCO₂ bracket |
| 24 | Gates 4 / 8 / 10 retired; DESIGN §6 still lists them at `from90`; the bomb-shape message text still says "provisional" | documentation debt (option J); an hour |
| 25 | Option B (seasonal HS box, `seas_ml = 2`) has no C++ twin; `q_attach_from` > 1 departs from HILDA; `tau_ex_seas_amp` measured, not adopted | paused / declined by ruling |

### B5. What I would actually do, in order
1. **D + E on the pump / kz structure** (B1 #1) — the one change that touches B1, the deep gradient, the δ¹³C level, GATE H/GL and the pedagogy at once. Preview it with the one-afternoon T-D0 read in §A3 before committing.
2. Then the **cell** (B1 #2) on the fixed column — re-run `diag_eq_cell_probe.R` and `diag_tr_box_probe.R` as they stand; decide T5 on those numbers.
3. **The constants batch** (B1 #3, #5; B3 #19): `alpha_photo` registered, `sst_NH/SH`, `hs_frac`, a source per provisional constant — cheap, and they move the mean state, so they belong in the same refit as (1).
4. ~~The app's future forcing (B2 #7)~~ — withdrawn on checking: the app already runs its futures coupled (`ccx_run_coupled()`).
5. The σ-audit rulings (B3 #20) and the documentation debt (B4 #24) — rulings and an hour of editing.
Not worth doing: the kz lever on the cell (a shim), a fitted `kz_tr_frac` (fits a symptom), the T1 array (we know its answer).
