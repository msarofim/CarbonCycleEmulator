# Scoping — 2026-09-14 (g). Option D + E: replacing "diffusion holds the gradient" with "export + ventilation"

**Why this note exists.** The review (`notes/review_2026-09-14g_open_calls_and_nonphysics.md` §A3, §B5) put D + E first; the preview
(`diag_tr_box_martin_preview.R`, CHANGELOG 09-14 g) then measured that the export field is ~45 % of the cell's B1 excess and the kz
coupling to the cold mixed layer the rest — so D is necessary, not sufficient, and E is the other half. E cannot be previewed with the
dormant limbs (`w_up` returns to the bottom; `w_out` outcrops; the conveyor is interhemispheric; the T-A probes were anomaly-only
wrappers and "the price of a MEAN W0 at depth is NOT answered"). It is a build, and the build needs rulings. This is the scoping
for them. Nothing here is built.

## 1. The structure as it stands, in four numbers (canonical `hilda30c`, its own vector; this session)
| | value | the physical number |
|---|---|---|
| kz at the ML base | **10,964 m²/yr** (3.5 cm²/s), decaying to 129 at depth (`kz_deep_frac` 0.0105, scale 253 m) | diapycnal thermocline ~0.1 cm²/s; the effective value stands in for isopycnal SUBDUCTION |
| the pump's divergence field | **45.5 GtC/yr net export** (NH 19.5: 7.8 / 7.0 / 2.4 / 1.5 / 0.5 …), solved to hold `pump_grad` 314 against that kz | POC export 5–13 GtC/yr (Nowicki et al. 2022: 10.2, the number `diag_td0b` cites) |
| surface ↔ layer-1 exchange | **2.9–3.6 /yr** against air–sea DIC equilibration **2.65 /yr** | every warm surface box tracks the interior |
| the bomb-¹⁴C row's demand | the dz-weighted kz over the top 300 m is 6,923; T-D0b's scan at kz × 0.5 (the export field halving with it, 9.9 GtC/yr) lost 1,265 log-units, most of it on the CO₂-level and Δ¹⁴C rows | the real penetration is by subduction of surface water, not diffusion |
The three are ONE object: diffusion carries the bomb ¹⁴C, so kz is large; a large kz needs a large export to hold the gradient; a large
export recycled through a large kz exposes cold-equilibrated DIC on any warm box. D alone (T-D0b) "starves": at the same kz a Martin
field holds the gradient with 16 GtC/yr but the deep loses its light carbon (−17 to −47 unrefitted), and cutting kz to make 10 GtC/yr
enough kills the bomb rows. **E is what lets kz fall: a subduction/upwelling loop that carries the bomb ¹⁴C (and the anthropogenic
CO₂) into the thermocline advectively, so the diffusive kz can be the diapycnal value and the export the observed one.**

## 2. What E is (the candidate, one per hemisphere; mirror limbs, one parameter set)
A **mode-water loop**: the mixed layer subducts a volume flux `W_E` (Sv, whole-hemisphere, split by `a_ls`) into the thermocline
layers `k_E1..k_E2` (default 1–3 = 65–290 m at this grid, weights ∝ layer thickness or a Martin-like decay — a ruling), and the same
volume returns to the mixed layer from those layers (the STC's upwelling, spread across the subtropical gyres). Every limb is
`W × the SOURCE's true per-volume concentration` (the cell's idiom; a uniform column is a fixed point). Isotopes bulk, α = 1.
- **It is the mean-state twin of option A / the T-A1–T-A2 limb**: T-A2 found the ENSO limb's return at layer 2 carries the observed
  slope at 26 Sv per index for +3.09; E gives that limb a MEAN. So `W_E` and the ENSO modulation share physics (ruling E3 below).
- **With the cell on** the cell's upwelling `oc[k_eq] → eq` draws from the same thermocline E ventilates — the cell's source water
  becomes "subducted mixed-layer water + remineralisation" instead of "the diffusive field", which is the T5 (tropical column) case
  without a second column. Whether that is enough for B1 is the decisive test (§4).
- **D rides with it**: the pump becomes a PRESCRIBED export (`pump_export`, GtC/yr, fitted, prior from the literature) × a Martin
  shape (b = 0.858 sourced; `lib_martin_shape.R`), and the surface–deep gradient becomes EMERGENT and scored by `ocean_grad_dic` as
  now. `pump_grad` retires as a parameter under the new mode (the existing `pump_mode` switch keeps the solved-field mode reachable
  so every registered file reproduces). ⚠ The solved field cannot stay: with an advective limb in the column the diffusive solve is
  no longer the fixed point's operator, and the spinup's Newton would land elsewhere without error (the D1 lesson).

## 3. Rulings needed before a prereg
- **E1 — the pump's construction**: prescribed export × Martin shape with an emergent gradient (recommended: it is the physics, and
  `pump_grad`'s "the model's own gradient" definition is what made the field 45 GtC/yr), or keep the solved field and extend its
  operator to include E's limb (keeps the parameter, keeps the circularity).
- **E2 — the loop's geometry**: subduction into layers 1–3 (the ventilated thermocline; T-A2's "every return below ~300 m leaks the
  index's decadal structure into the CO₂ level") with the return from the same layers; thickness-weighted (recommended) or uniform.
- **E3 — one `W_E` or two**: the mean loop and the Niño3.4 modulation as ONE limb `W_E(t) = W_E (1 − γ_E·Niño3.4)` (the cell's form;
  then `gamma_enso_ocn_*` retires and A is subsumed), or E as the mean only and A separate. Recommended: one limb — the T-A2 gain at
  layer 2 is exactly what E's return would carry.
- **E4 — the export prior**: Nowicki et al. 2022 (10.2 GtC/yr), or a bracket 5–13 as a flat prior; which of these has a citation IN
  the repo (memory `overturning_and_mld_literature` names Nowicki; nothing else is sourced).
- **E5 — sequencing against T5**: build E first and re-read the cell (recommended); T5 only if B1 stays > +70 with E in.
- **E6 — what the refit is allowed to move**: `kz` (expected to fall > 3×, the assessment's decisive test), `kz_deep_frac`, `pump_export`,
  `W_E`, `h_ml`, `u_hs`/`h_hs` — with the deep-row set and the bomb rows held as they are scored today.

## 4. Preregistered predictions (to be stamped in the prereg; numbers from this session)
- **PE-1** at the refit, `kz` at the ML base falls below 4,000 (> 2.7×) with the bomb rows (d14c_NH/SH) within 2 log-units of today.
- **PE-2** the emergent surface–deep DIC gradient lands inside 233 ± 29 at an export inside 5–13 GtC/yr (today: 304 at 45.5).
- **PE-3** the cell's B1 at Meinen's 27 Sv, unrefitted after E's refit, falls below +80 (from +133; the preview's +1.54 µatm per GtC/yr
  gives ~+80 from the export alone; the kz fall adds the other half) — and PT1 (< +69) is the pass mark.
- **PE-4** the modern surface–deep δ¹³C gradient moves from 0.40 toward 0.89 (the light carbon reaches the deep by the return, not by
  diffusion) and GATE GL's 1.97× moves for the first time in four refits.
- **PE-5** the ENSO ocean slope at γ_E = 0 stays solubility-only (r ≈ −0.53); at the γ_E the observed 14–25 Sv per index implies, it
  flips positive (T-A2's 26 Sv/index at layer 2).
- **N-E1** (negative control) `W_E = 0` with `pump_export` set to reproduce today's 45.5 GtC/yr field's gradient must reproduce the
  canonical's 25 rows to < 1 log-unit (the prescribed-export mode is the solved mode's twin at one point).
- **Not claimed**: that E fixes GATE Q or V; that the tropical band's +7.6 is reached without T5; that the refit converges in one
  array (kz, export and W_E are a new degeneracy triangle — the prior on export is what breaks it).

## 5. Cost and order
R side (the loop in `ccx_deriv`, the prescribed-export pump with the mode switch, `ccx_prepare` guards, the substep bound, the
spinup guess), C++ twin, `cpp.R`, tests (no-op at `W_E` 0 and at the old pump mode: bit-exact; conservation; parity; fixed point;
N-E1; mutations), the unrefitted probe (PE-3, PE-5 at the canonical), one Torch array with 33 − 1 + 2 names (`pump_grad` → `pump_export`,
+ `W_E`, + `γ_E` if E3 = one limb). Two build sessions + the array; the cell's re-read after. The constants batch (`sst_NH/SH` sourced
17.18/15.35, `hs_frac` 0.126/0.130, the biosphere-wide `ALPHA_PHOTO_EPS`) goes into the same array, as ruled in the review.
