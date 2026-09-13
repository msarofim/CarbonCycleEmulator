# SCOPING — an EQUATORIAL UPWELLING CELL for CCX (Fix B proper), and whether it needs mirror cells

**2026-09-13 (f). A scope, not a prereg and not a build.** Written after T-A1 / T-A2 (CHANGELOG 09-13 (e), (f); memories
`ccx_ta1_thermocline_limb_probe`, `ccx_ta2_return_depth`), on Marcus's instruction "then scope the equatorial cell (and
whether we need mirror cells on either side of the equator)". Every number below is either a T-A1/T-A2 measurement at
`hilda30c`, a Fix B measurement (`ccx_fixB_reservoir_priced`, 09-04g), or a GLODAP/SOM-FFN cut named by file; the
items marked **DATA TASK** or **SOURCE NEEDED** are not numbers yet.

## 0. What the probes established, and what they leave for a cell to do
1. The ocean's ENSO response IS upwelling suppression of a DIC-rich source into the surface: right-signed, exactly linear
   in the modulation, and the objective's ENSO-year rows PAY for it (+3 to +5 log-units unrefitted) — T-A1, T-A2.
2. The source layer is the model's own low-latitude thermocline, **layer 2 (117–190 m, +97 µmol/kg over the ML)**, possibly
   layer 3 (190–292, +135): GLODAP's equatorial-Pacific source water at 100–200 m is +115 to +176 over its surface. At layer 2
   the observed slope needs **2.73 m/yr over `ml_lo` = 26 Sv per Niño3.4 unit**, price **+3.09**. Layer 1 needs 109 Sv (4×
   too weak); returns below ~300 m leak the index's decadal structure into the CO₂ level rows (−14 to −59 at equal slope).
3. **So the MAGNITUDE does not need a cell.** A limb on `ml_lo` at layer 2 carries it. What a limb CANNOT do (ruling 2 said
   so and accepted it "for now"): (a) represent the **+55.5 µatm equatorial reservoir** (SOM-FFN B1: eq. Pacific − global
   mean; tropics +15.2; SO −3.0) — the model's tropical-minus-global contrast is EXACTLY ZERO with two hemispheric boxes;
   (b) give the mean upwelling **W0 an observable**. On `ml_lo` a mean limb is indistinguishable from `kz` at the mean state
   (T-A0: W0 up to 4 m/yr moved the solubility-only slope by 1e-4, and the mean-state cost was all Δ¹⁴C profile), so a refit
   would trade it against `kz` / `pump_grad` — a degeneracy, not a constraint. In a cell, W0 SETS the cell's pCO₂ excess
   over the surrounding surface, and B1's +55.5 µatm becomes a likelihood row (or gate) with power: at W0 = 0 the cell is
   `ml_lo` and the contrast is 0.
   ⇒ **The case for the cell is representability and identifiability, not magnitude.** That is the ruling's axis.

## 1. The two builds on the table
| | **"lite": mean + modulated limb on `ml_lo`** | **the equatorial cell** |
|---|---|---|
| state | none new | 2 boxes (`NH_eq`, `SH_eq`) — see §2 |
| parameters | `w_eq` (mean, m/yr over `ml_lo`), `gamma_eq` (per index unit), `k_eq` (return layer, a STRUCTURE choice: 2) | + `eq_frac` (area, OBSERVED), `h_eq` (thickness, Holte — DATA TASK), `sst_eq` (DATA TASK), `alk_eq` (GLODAP cut — DATA TASK); `w_eq` becomes Sv INTO the cell |
| what it represents | the flux (0.64 µatm swing over 84 % of the surface) | the reservoir (13 µatm swing over 4.1 %) AND the mean +55.5 µatm excess |
| new observable rows | none (the GCB slope is already in the ENSO rows) | **B1: cell pCO₂ − surface mean +55.5 µatm** (mean state; pins W0); the cell's pCO₂ swing per index unit (13.15 µatm from B3 — pins γ); tropical Δ¹⁴C stations from `obs_d14c_station_validation` (held out by everything today) |
| retires | `gamma_enso_ocn_NH/SH` → fitted first, read → 0 (ruling-4 idiom, [[no_power_null]]) | same |
| cores | R + C++ + parity; spinup unchanged (the limb is one more advective idiom like `w_up`) | R + C++ + parity; `ccx_box_names`/`ccx_new_state`; `aux` areas (`a_ls` shrinks by `eq_frac` — the fitted mean state moves); spinup Newton (32 → 36 columns); `cpp.R` marshalling; likelihood readers (§4); tests; the app |
| cost | days | weeks (option B's scale; option B's R side `5ed31cf` is the closest scaffold — the HS box is the idiom) |
| refit | one Torch array (hilda30c space + 2) | one array (+ 2–3 free, several pinned to observations) |
| risk | W0–`kz` degeneracy; nothing new is TESTED | the mean state moves (area, a new source box) — the deep/HS rows may re-price; the A_ls change touches GATE S's SO limb (`seas_ml` is whole-model) |

**Recommendation.** Build the CELL, as mirror cells (§2), because the lite limb answers a question T-A2 has already
answered (the sign and magnitude are reachable) and adds nothing testable, while the cell converts the one Fix B number the
model cannot currently see (+55.5 µatm) into a row with power on the one parameter the limb leaves free. If weeks are not
available before the next milestone, the lite limb at layer 2 is the correct stopgap and its W0 should be PINNED (to the
B3 arithmetic: 0.24 × 55.5 µatm ≡ 13.15 µatm over 4.1 % ⇒ 2.7 m/yr over `ml_lo`), never fitted.

## 2. Mirror cells — yes, and it costs nothing extra
**The question.** Niño3.4 is 5 °S–5 °N: ONE region straddling the equator. The model is two hemispheric columns, each with
its own atmosphere box, and every loop in both cores is `for (h in HEMIS)`; the HS/HD boxes are per hemisphere
(`hs_frac` of EACH hemisphere's area). A single straddling cell would have to exchange gas with BOTH atmosphere boxes
(50/50) and draw area from BOTH columns — breaking the per-hemisphere idiom in `ccx_deriv` (both cores), the spinup
Newton, `ccx_cpp_aux`, `ccx_run`'s ocean bookkeeping, and every hemispheric observable reader, for no physical gain.
**Mirror cells `NH_eq` / `SH_eq`**, each `eq_frac` of its hemisphere's ocean area (the 0–5° half of the band), each fed by
its OWN column's layer `k_eq`, both driven by the same Niño3.4 with ONE shared parameter set (`w_eq`, `gamma_eq`, `h_eq`,
`sst_eq`, `alk_eq`, `eq_frac`) — are the HS idiom exactly, and identical forcing on two near-symmetric columns makes the
split a bookkeeping fiction with no observable consequence at first order. ⚠ **The cold tongue is SH-heavy** (the real
upwelling and the +55 µatm excess sit mostly 0–5 °S; the 160 °E–80 °W band is symmetric only because the INDEX is). An
asymmetric split (`eq_frac_SH` > `eq_frac_NH`, or an SH-only cell) is the **pre-registered sensitivity, not the default** —
the same rule `hs_frac`'s comment already states for the HS allocation. ⇒ **Build mirror cells, one parameter set; test the
asymmetry once, as a sensitivity, on the interhemispheric CO₂ gradient row (`co2_gradient`), which is the only place it can
show.**

## 3. The cell's plumbing (a shallow overturning loop, volume-conserving)
Per hemisphere, with `A_eq = eq_frac × A_hemisphere_ocean` and `W(t) = w_eq × max(0, 1 − gamma_eq × Niño3.4(t))` (the T-A0
form: a mean with a floor, so the flux never reverses — the anomaly-only probes' linearity says the response is the same):
1. **upwelling**: layer `k_eq` → `eq`, `W·A_eq·C_k/dz_k` per tracer at the source ratio (bulk transport, `add_flux`, α = 1 —
   ¹⁴C rides unfractionated by the Stuiver–Polach convention the model uses);
2. **surface divergence**: `eq` → `ml_lo`, `W·A_eq·C_eq/h_eq` (Ekman divergence poleward — the physical return path);
3. **subduction**: `ml_lo` → layer `k_eq`, `W·A_eq·C_ml/dz_ml(t)` (the subtropical cell closing in the thermocline; T-A2
   says it must close SHALLOW — a return below ~300 m leaks decadal ENSO into the CO₂ level).
   Volume: every limb carries `W·A_eq`, so a uniform column is still a fixed point (the `w_up` contract — the analytic 12C
   spinup stands). `eq_frac = 0` ⇒ no boxes, bit-exact (the `hs_frac` absence contract). ⚠ T-A2's probe was a DIRECT ML ↔ k
   exchange; the loop above routes the return through `ml_lo`. Same ML budget to first order; the difference (the cell's
   own residence time `h_eq/W`, which sets how far its pCO₂ can rise above `ml_lo`'s) is exactly what makes B1 observable.
4. **air–sea**: the cell exchanges with ITS hemisphere's atmosphere on the same `k_w` law over `A_eq`, at its own SST and
   alkalinity (the HS `asx` idiom; an `eq_asx_frac` only if a wind-speed source justifies it — default 1).
5. **seasonal cycle**: OFF on the cell in the first build (ruling-3's logic: no fitted amplitude inside a structural test).
6. **pump**: NONE of its own in the first build — the cell's DIC is set by the supply W and the air-sea leak; a cell pump is a
   second build if the B1 row cannot be met without it (the HNLC export is real but is the smaller term — SOURCE NEEDED).
7. **isotopes**: nothing new — bulk transport carries them; the cell's δ¹³C is a free prediction against the tropical surface
   δ¹³C in GLODAP's `glodap_c13c14_subset.csv` (a check, not a row).

## 4. Observables and gates the cell brings (each with its source status)
| row / gate | quantity | source | status |
|---|---|---|---|
| **B1 reservoir** (NEW row or gate) | cell pCO₂ − area-mean surface pCO₂, annual, ≈ +55.5 µatm (widening the lon mask moves it −12 %) | SOM-FFN climatology, `data-raw/downloads/MPI-ULB-SOM_FFN_clim.nc`, cut 09-04g | measured; σ = a DATA TASK (the product's own uncertainty field, or the mask sensitivity as a floor) |
| **B3 swing** | cell ΔpCO₂ per Niño3.4 unit ≈ 13.15 µatm (0.24× the reservoir) | derived from GCB slope + the model's own `k_w` — MODEL-DERIVED | a consistency check on γ, not a row |
| ENSO slope | +0.1153 ± 0.0246 GtC/yr per index, n 66 | GCB + Niño3.4 (existing ENSO rows) | in the objective |
| GATE V | interannual variance | existing | downstream; a FAIL is non-blocking (Marcus 09-04f) |
| tropical Δ¹⁴C stations | bomb-era surface Δ¹⁴C at low latitudes | `obs_d14c_station_validation` — HELD OUT, used by nothing | free out-of-sample test |
| surface DIC/δ¹³C reader | `ocean_grad_*` reads the "ml" box | likelihood | **RULING**: does the surface row become the area-weighted `ml_lo` + `eq` mean (the observation is a gridded climatology over both), or stay `ml_lo`? Recommend area-weighted — the seasonal-box reader (`ccx_box_annual_conc`) already weights hemispheres by mass and extends naturally |
| Q (air–sea δ¹³C disequilibrium) | | existing | re-read; the cell is a disequilibrium source |

## 5. Data tasks before the build (each one file, each cited)
- `eq_frac`: the 5 °S–5 °N, 160 °E–80 °W band as a fraction of each hemisphere's ocean area (B3 used 4.1 % of the GLOBAL
  ocean for the whole band) — recompute from the SOM-FFN grid's land mask, per hemisphere.
- `h_eq`: Holte MLD climatology cut to the band (`data/obs_mld.rds` builder; the HS/SO cuts exist — same script, new mask).
- `sst_eq`: annual-mean SST over the band from the SST product already in `data/forcing_sst.rds`'s source (cite it), or the
  SOM-FFN file if it carries SST; also its Niño3.4 regression coefficient (the cold-tongue warms in El Niño — this is the
  cell's OWN solubility term and it has the wrong sign locally; the cell carries both terms and their ratio is testable).
- `alk_eq`: GLODAP `glodap_talk_subset.csv` over the band, 0–50 m (the DIC cut is done: 1982.9 µmol/kg surface median).
- The source-water contrast by layer for the k_eq choice: done above (+115 / +176 at 100–150 / 150–200 m).
- **SOURCE NEEDED, not a data cut**: an EUC / STC transport and its ENSO variation, to say whether 15–26 Sv per Niño3.4 unit
  is physical. Until then the Sv figure is a MODEL requirement, labelled so.

## 6. Pre-registered predictions for the FIRST build (to be written into its prereg, not tested here)
PE1 with `w_eq` at the B1-pinned value the solubility-only ENSO r flips positive at `gamma_eq` ≤ 1 per index unit (a
per-unit-index fractional modulation ≤ 100 %: the physical form of "26 Sv per index" once W0 is ~26 Sv). PE2 `gamma_enso_ocn_*`
fitted → 0 within 1 se. PE3 GATE V improves by ≥ the 31 % Fix B's B4 promised. PE4 the CO₂ level rows move < 2 log-units
(the shallow return). PE5 `kz` / `pump_grad` / the deep rows move < 1σ each (the cell is 4 % of the surface — the mean state
should barely notice; if they move, the area accounting is wrong). PE6 the cell's surface δ¹³C lands within GLODAP's tropical
surface band (free prediction).

## 7. Order
T-A2 → (this scope) → Marcus's ruling lite / cell, mirror / single → data tasks §5 (one day) → prereg → build R side → C++ +
parity → tests (absence contract, conservation, parity, box-count lint) → one Torch array → PE1–PE6. **M** (the per-hemisphere
MLD handle) is unaffected and still owed; pin-vs-retire of `ent_seas_amp_SH` and option K unchanged.
