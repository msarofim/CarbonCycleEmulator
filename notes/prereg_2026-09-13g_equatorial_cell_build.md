# PREREG — the EQUATORIAL UPWELLING CELL, first build (Fix B proper)

**2026-09-13 (g). Written BEFORE any core edit.** Follows the scope (`notes/scoping_2026-09-13_equatorial_cell.md`),
the six rulings of 09-13 (g) (CHANGELOG), and the data product `data/obs_eq_cell.rds` (`data-raw/build_eq_cell_targets.R`).
Every number here is either from that product, from T-A2 (CHANGELOG 09-13 (f)), or from Meinen, McPhaden & Johnson (2001)
*JPO* 31:3230–3248 — nothing is recalled. Hooks are named by file:line as of commit `4f54b64`.

## 0. The rulings this build implements (Marcus, 09-13 g)
1. **The CELL, as MIRROR CELLS `NH_eq` / `SH_eq`, ONE fitted parameter set.** Lite limb declined; single straddling box declined.
2. **`k_eq` = LAYER 2 alone** (117–190 m at `hilda30c`'s grid).
3. **Area-weighted surface reader**: `ocean_grad_*`'s surface = `ml` + `eq` by mass, bit-exact at `eq_frac = 0`.
4. **W0 (`w_eq`) is FITTED with a Gaussian prior 27 ± 3 Sv** (Meinen et al. 2001: 24 ± 3 over 155–95 °W, ~30 over 165 °E–95 °W);
   **B1 SCORES** as a likelihood row — two independent constraints on one parameter, so B1 can reject, not just tune.
5. **B1's σ = 6.77 µatm** (the mask-sensitivity floor; the climatology carries no uncertainty field).
6. **`h_eq` = the Holte annual MEAN, 44.2 m** (the `h_ml` convention).

## 1. What is built — state, geometry, parameters
**State.** Two boxes appended per hemisphere AFTER `hs`/`hd` in `ccx_box_names()` (`R/model.R:760-765`): order per hemisphere
`atm | 4 land | ml | oc1..oc10 | [hs, hd] | [eq]` — 19 boxes with both structures on, 38 total; no existing index moves. Each
carries `C, C13, C14` (`CCX_TRACERS`, `:778`). Alkalinity stays a per-box CONSTANT (`alk_eq`, the `alk_hs` idiom `:2861-2866`).
C++: a runtime `IEQ` set in `unpack_aux()` beside `IHS/IHD` (`src/ccx_core.cpp:871-874`), `NPH` = 19 when both on.
**Resolver.** `ccx_eq_on(p)`: TRUE iff `eq_frac_NH` AND `eq_frac_SH` are finite and > 0; a MIXED pair (one 0, one > 0) is an
ERROR by name in both cores — the mirror-cell contract. Absence (NULL / 0) ≡ no boxes, the `ccx_hs_on` idiom (`:773-776`).
**Geometry (OBSERVED, pinned structure — never fitted).**
| name | value | from |
|---|---|---|
| `eq_frac_NH`, `eq_frac_SH` | **0.0480, 0.0356** of each hemisphere's ocean area | `obs_eq_cell$eq_frac$value` (SOM-FFN mask) |
| `h_eq` | **44.2 m** | `$h_eq$both$mean_dt` |
| `sst_eq` | **27.04 °C** mean; `sst_eq(t) = 27.04 + sst_anom_h(t) + sst_eq_enso × enso(t)` with **`sst_eq_enso` = 0.97 K per index** | `$sst_eq$both` (the cell's OWN solubility term; it warms in El Niño) |
| `alk_eq` | **2296 µmol/kg** | `$alk_eq$both$target` |
| `k_eq` | **2** (structural, range-checked by name like `q_attach_from`, `:2520-2525`) | ruling 2 |
**Areas — design choice D1, stated.** `a_eq[h] = eq_frac_h × a_oc[h]`. The MIXED LAYER loses that area (`a_ml = a_oc(1 − f_hs) − a_eq`;
`ml_mass_kg`, `asx`, the ML–oc1 diffusive interface all follow `a_ml`); **the INTERIOR column keeps `a_ls = a_oc(1 − f_hs)`** —
the thermocline under the cold tongue IS the low-latitude thermocline, and the cell has no "ED" box beneath it (HS has HD, which is
why `a_ls` shrinks for HS's whole column). The cell's only interior contact is the advective loop. Alternative (shrink the whole
column) is NOT built; PE5 is where D1 would show if wrong.
**Fitted (ONE set, both hemispheres).**
| name | units | bounds | prior | note |
|---|---|---|---|---|
| **`w_eq`** | **Sv, WHOLE-BAND** (both cells) | [5, 60] | **N(27, 3)** — ruling 4 | split by area: `W_h = w_eq × a_eq[h] / Σ a_eq` ⇒ EQUAL upwelling velocity in both cells (63 m/yr at 27 Sv, `Σ a_eq` 1.477e13 m²) |
| **`gamma_eq`** | per Niño3.4 unit | [0, 2] | flat | `W_h(t) = W_h × max(0, 1 − gamma_eq × enso(t))` — the T-A0 floor form; binds at `enso = 1/gamma_eq` |
`gamma_enso_ocn_NH/SH` STAY in the first array (PE2 reads them); pinned to 0 in the array after, if PE2 passes.

## 2. The plumbing (per hemisphere `h`, inside the `for (hi in seq_along(HEMIS))` loop, under `if (aux$eq_on == 1L)`)
Volume flux `W = W_h(t)` in m³/yr; every limb is `add_flux(from, to, W × conc_source)` with the SOURCE's true per-volume
concentration (the conduit's lesson, `R/model.R:2506-2509`: areas do not cancel between boxes of different area):
1. **upwelling** `oc[k_eq] → eq`: `W × y[ioc[k_eq], "C"] / (a_ls[h] × dz[k_eq + 1])`;
2. **surface divergence** `eq → ml`: `W × y[ieq, "C"] / (a_eq[h] × h_eq)`;
3. **subduction** `ml → oc[k_eq]`: `W × y[iml, "C"] / (a_ml[h] × h_ml(t))` — `h_ml(t)` the SAME thickness the ML's own limbs use at
   time t (seasonal under `seas_ml`);
4. **air–sea** on the cell: `gx_eq = asx_eq[h] × k_w × K0(sst_eq(t))`, `dic_eq = y[ieq,"C"] × mol_per_GtC / eq_mass_kg[h]`, pCO₂ from
   the carbonate routine at (`sst_eq(t)`, `alk_eq`), the frozen-Revelle branch mirrored from HS (`:2444-2451`) if that mode is on;
   two gross limbs with `ccx_alpha_as(sst_eq)` and `alpha13_signed = TRUE` (`:2454-2457`). Exchanges with ITS hemisphere's atmosphere.
5. **Isotopes**: bulk transport only (α = 1; ¹⁴C unfractionated by convention, `:1675-1704`). **No pump. No seasonal cycle. No
   diffusion** into the cell.
C++ twin: the same five items in the HS block's position (`src/ccx_core.cpp:738-799`), `Aux` fields `eq_on, a_eq[2], a_ml[2],
eq_mass_kg[2], asx_eq[2], sst_eq, sst_eq_enso, alk_eq, k_eq, dic0_eq[2], revelle0_eq[2]`, `Par` fields `w_eq, gamma_eq` — all BY
NAME through `ccx_cpp_aux()` / `ccx_cpp_par()` (`R/cpp.R:30-108, 138-301`), sent unconditionally and zero-filled when off
(`R/cpp.R:61-63`). `enso` is already `f[5]` (`R/cpp.R:308-330`) — no forcing change.
**Contracts.** (a) A UNIFORM column with the cell at the same concentration has ZERO advective tendency (each limb carries `W × c`;
`R/spinup.R:308-324`); (b) the cell's Henry equilibrium at (27.04 °C, 2296) differs from the ML's, so the analytic spinup is a
STARTING GUESS (cell at its own Henry point, the HS idiom `:337-344`) and the Newton gate (`:374-375`) adds `|| aux$eq_on == 1L`;
(c) the periodic spinup needs nothing — it dimensions on `nrow(y)` (`R/periodic_spinup.R:171`).
**Outputs.** `CCX_OCEAN_BOX_COLS` (`R/model.R:59-60`) gains `eq_C_h, eq_C13_h` (NA when off — the `hs` idiom, `src:1057-1073`,
`R/forcing.R:968-1000`); `ccx_box_mass_at()` gains `which = "eq"` (`R/likelihood.R:1127-1136`).

## 3. Likelihood changes (three, each with its power stated)
- **R1 — the B1 reservoir row (NEW).** Model: the cells' area-weighted annual pCO₂ MINUS the area-weighted pCO₂ over ALL surface
  boxes (`ml` NH/SH, `hs` NH/SH, `eq` NH/SH), averaged over **2000–2015** (the contrast is invariant to the epoch to first order —
  both sides ride the atmosphere; the product states no normalisation year, CHANGELOG 09-04g B1c). pCO₂ from box DIC via the SAME
  carbonate call the deriv uses (a parity test between reader and deriv, P0e). Target **+55.47**, σ **6.77** (ruling 5).
  Power: at `w_eq = 0` the cell IS the ML and the contrast is ~0 ⇒ z ≈ −8; the row has power on W0 by construction.
- **R2 — the surface reader (ruling 3).** `ccx_model_ocean_gradient()` (`R/likelihood.R:1175-1191`) surface term becomes the
  mass-weighted mean over `which ∈ {"ml", "eq"}` via `ccx_box_annual_conc()` (`:1149-1173`); the deep term unchanged. At
  `eq_frac = 0` the `eq` columns are NA and are dropped ⇒ bit-exact with today's reader (P0d).
- **R3 — the `w_eq` prior** in `CCX_PARAM_TABLE` (`R/calibrate.R:112`): `prior = function(x) dnorm(x, 27, 3, log = TRUE)`, the
  literal carried from `obs_eq_cell` (a lazy loader `ccx_w_eq_prior()` reading a `w0_prior` element to be ADDED to the product —
  the `ccx_u_hs_prior()` idiom `:86-89`; the number never typed in `calibrate.R`).
Not rows (checks only): the per-hemisphere B1 halves (+43.4 NH / +67.7 SH), B3's 13.15 µatm swing, the tropical Δ¹⁴C stations
(`obs_d14c_station_validation`), the cell's surface δ¹³C against GLODAP's tropical band.

## 4. Predictions — P0 first; nothing below is read if P0 fails
### P0 — the contracts (unrefitted, at `hilda30c` with `eq_frac` set)
- **P0a NO-OP**: `eq_frac_NH = eq_frac_SH = 0` ⇒ `expect_identical(y)` with `hilda30c`, 36 boxes, both cores; logpost to 1e-12.
- **P0b CONSERVATION**: closed-system `sum(dC/dt)` < 1e-9 with the cell on, `w_eq` 27, `gamma_eq` 1, at three `enso` values (−1.7, 0, +1.7).
- **P0c PARITY**: R vs C++ deriv < 1e-10, transient stocks < 1e-12, cell on (the `test-hilda-boxes.R:89-113` idiom).
- **P0d READER NO-OP**: `ocean_grad_*` model values identical (to 0.0) at `eq_frac = 0` before and after R2.
- **P0e READER–DERIV pCO₂ PARITY**: the B1 reader's cell pCO₂ equals the deriv's at the same state to 1e-9.
- **P0f MIRROR LINT**: a mixed `eq_frac` pair errors by name in both cores; box order and stride (19) asserted; `a_ml + a_eq + a_hs == a_oc`.
- **P0g FIXED POINT**: with `w_eq` 27 and a uniform cell, the advective tendency of every ocean box is 0 to 1e-12 (contract (a)).
### PE — the science (unrefitted probe FIRST at `w_eq` 27, `gamma_eq` 1; then ONE Torch array)
- **PE1** (unrefitted): with `w_eq` = 27 Sv the solubility-only ENSO r (−0.527 at hilda30c) flips POSITIVE at `gamma_eq` ≤ **1.0**
  (26/27 — the T-A2 requirement at layer 2 is 26 Sv per index; the cell's ~0.7 yr residence time may need LESS).
- **PE2** (array): `gamma_enso_ocn_NH/SH` → **0 within 1 se** each (the additive term is REPLACED, not supplemented).
- **PE3** (array): GATE V's variance deficit improves by ≥ the **31 %** Fix B's B4 promised (a FAIL is non-blocking — Marcus 09-04f).
- **PE4** (array): the CO₂ LEVEL rows move < **2 log-units** vs `hilda30c` (the shallow return, T-A2 k = 2: −1.45).
- **PE5** (array): `kz`, `pump_grad`, the deep Δ¹⁴C rows each move < **1 posterior σ** — the cell is 4 % of the surface and D1
  leaves the interior area alone; if they move, D1 or the area accounting is wrong.
- **PE6** (check): the cells' surface δ¹³C lands inside GLODAP's tropical surface band (`glodap_c13c14_subset.csv`, |lat| ≤ 5, ≤ 50 m).
- **PE7** (array): fitted `gamma_eq` in **[0.4, 1.1]** per index — the observed 1997–99 bracket (14–25 Sv per index against
  24–30 Sv) to the T-A2 requirement; BELOW 0.4 says the cell amplifies (residence time), ABOVE 1.1 says layer 2 is too lean.
- **PE8** (array): fitted `w_eq` within the prior's **2σ (21–33 Sv)** AND B1's z within ±1.5 — if the fit needs W0 outside
  Meinen's range to hit +55.5, the cell's pCO₂ excess is set by something the first build lacks (a pump, or a shallower `k_eq`).
- **PE9** (check, the asymmetry): the modelled NH/SH cell contrasts are EQUAL by construction (one velocity, near-equal areas);
  obs are +43.4 / +67.7. The pre-registered SENSITIVITY — W split SH-heavy in the observed ratio 1.56 — is run ONCE after the
  array and read on `co2_gradient`; it is NOT the default and is not fitted.
### N1 — the negative control
`gamma_eq` = 0 with `w_eq` = 27: the ENSO ocean r must stay at the solubility-only value ± 0.02 (a mean cell without modulation
carries no interannual signal; if r moves, the cell leaks the index through `sst_eq_enso` alone — which is the wrong-signed
local term and must be SMALL: predicted |Δr| < 0.05).

## 5. What is explicitly NOT claimed
Not that 26 Sv per index is the physical modulation (the observed bracket is 14–25 and the like-for-like caveats run both ways);
not that the cell fixes GATE V (PE3 may fail and is non-blocking); not that the mean state is unchanged (PE5 is a bound, D1 is a
choice); not that the SH-heavy asymmetry is representable (PE9 is a sensitivity). `gamma_enso_ocn_*` is not retired by this
prereg — PE2 decides.

## 6. Order and artefacts
Data product amendment (`w0_prior` element: 27 ± 3 Sv, Meinen 2001, into `obs_eq_cell.rds`) → R side (`model.R`: names, resolver,
aux, deriv block, outputs; `spinup.R`: guess + Newton gate; `likelihood.R`: R1, R2, `ccx_box_mass_at`; `calibrate.R`: `w_eq`,
`gamma_eq`, R3; `paths.R`: a new registered mode — **proposed name `hilda30e`**, struct = `hilda30c`'s + `eq_frac_*`, `h_eq`, `sst_eq`,
`sst_eq_enso`, `alk_eq`, `k_eq`; pins unchanged, `ent_seas_amp_SH = 0`) → C++ twin + `cpp.R` marshalling → tests
(`test-eq-cell.R`: P0a–P0g) → unrefitted probe (`calibration/diag_eq_cell_probe.R`: PE1, N1, PE6) → one Torch array (32 free
names: `hilda30c`'s 30 + `w_eq` + `gamma_eq`) → PE2–PE5, PE7–PE8 → PE9 sensitivity. Every log and rds under
`outputs/diagnostics/eq_cell_*_2026MMDD.*`; the array's incumbent follows the array's pins ([[ccx_pinned_arms]]).
