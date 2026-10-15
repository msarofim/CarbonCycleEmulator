# PREREG (build tier) — the TROPICAL SURFACE BOX `tr`: the equatorial cell's second build (`hilda_tr`)

**2026-09-14 (f). Written BEFORE any core edit, from HEAD `f5cb1b2`.** Implements the four rulings of 09-14 (d)/(e)
(CHANGELOG; `notes/prereg_2026-09-14c_equatorial_cell_tdic.md` §2) on the data product `data/obs_tr_box.rds`
(`data-raw/build_tr_box_targets.R`, commit `2ea5ea5`). Every number below is read from that product, from
`data/obs_eq_cell.rds`, or from the first array's reading (`calibration/diag_eq_cell_levers.R` →
`outputs/diagnostics/eq_cell_levers_20260914.{log,rds}`) — nothing is recalled. Hooks are named by file:line as of `f5cb1b2`.
`hilda30c` stays canonical; `hilda_eq` and the first array's `start_011` stay reproducible; nothing is adopted here.

## 0. The rulings this build implements (Marcus, 09-14 d/e)
- **R1 = T1.** A tropical surface box `tr` per hemisphere, MIRROR BOXES with one parameter set (the cell's precedent), through
  which the cell's loop closes: `oc[k_eq] → eq → tr → oc[k_eq]`. NO shim (T2 not even as a diagnostic).
- **R2 = the 26 °C annual-mean SST isotherm** (ERSSTv5 1991–2020) inside the LS domain (|lat| ≤ 57.14°), cell removed.
- **R3 = `seas_ml` OFF on `tr` first**, ON on `tr` as the registered follow-up. The MASK CHANGE (the residual ML's SST
  17.18/15.35 in place of the typed 18/16) is read on the UNREFITTED vector first, priced separately.
- **R4 = `q_tr` (lateral `tr`–`ml` surface exchange) STRUCTURAL 0 first**; "structural from an observation" is a LATER test
  paired with the `seas_ml`-on follow-up; NEVER fitted while B1 is the only row that sees it.

## 1. What is built — state, geometry, parameters
**State.** One box per hemisphere appended AFTER `eq` in `ccx_box_names()` (`R/model.R:781-786`): order per hemisphere
`atm | 4 land | ml | oc1..oc10 | [hs, hd] | [eq] | [tr]` — 20 boxes with all three structures on, **40 total**; no existing
index moves. Tracers `C, C13, C14`. C++: a runtime `ITR` set in `unpack_aux()` beside `IEQ` (`src/ccx_core.cpp:951-954`).
**Resolver.** `ccx_tr_on(p)`: TRUE iff `tr_frac_NH` AND `tr_frac_SH` finite and > 0; a MIXED pair errors "MIRROR BOXES" by name
(the `ccx_eq_on()` idiom, `R/model.R:799-810`). Absence ≡ 0 ≡ no boxes. `tr` does NOT require `eq`: with `eq` off and `tr` on the
box is a passive warm surface box (no loop); with `eq` on and `tr` off the loop closes through `ml` — the first build, bit-exact.
**Geometry (OBSERVED, pinned structure — never fitted; read by `ccx_struct_hilda_tr()`, never typed).**
| name | value (NH / SH) | from `obs_tr_box.rds` |
|---|---|---|
| `tr_frac_NH/SH` | **0.3966 / 0.2149** of each hemisphere's ocean area | `$tr_frac$value` |
| `h_tr` | **42.6 m** (both; NH 40.2, SH 45.9) | `$h_tr$both$mean` (the Holte annual mean, the `h_eq` convention) |
| `sst_tr` | **27.24 / 27.18 → 27.21 °C** (both, area-weighted) | `$sst$tr` (RE-BASED to 1850–1900, −0.70) |
| `sst_tr_enso` | **+0.204 / +0.200 K per Niño3.4 unit → 0.202** (both) | `$sst_enso$NH/SH$beta_monthly` — **R5 below** |
| `alk_tr` | **2299 µmol/kg** | `$alk_tr$both$target` (GLODAP ≤ 50 m, flag 2) |
| `q_tr` | **0 Sv** (R4) | structural |
| **and the structure OVERRIDES** `sst_NH/SH` = **17.18 / 15.35** (the residual ML's re-based SST) and `sst_eq` = **26.57 / 26.09 → 26.33** (re-based; the cell's product carried the un-re-based 27.04) | `$sst$ml`, `$sst$eq` |
The cell's other geometry (`eq_frac`, `h_eq`, `sst_eq_enso`, `alk_eq`, `k_eq`) stays the `hilda_eq` block's, read from `obs_eq_cell.rds`
(`R/calibrate.R:1734-1743`). ⚠ `hs_frac` stays 0.16 (the product measures 12.6/13.0 % — a ruling owed, NOT taken here).
**Areas — D1 extended, stated.** `a_tr[h] = tr_frac_h × a_oc[h]`; **`a_ml = a_ls − a_eq − a_tr`** (the ML's mass, `asx`, `ml_C0`,
the ML–layer-1 diffusive/entrainment contact all follow `a_ml`; `R/model.R:3102-3104, 3187-3200`); **the INTERIOR keeps `a_ls`**.
`tr`'s only interior contacts are the loop's two limbs and its own diffusive interface with layer 1 over `a_tr`. Under
`seas_ml` = 1 layer 1 still absorbs the ML's excursion as a VOLUME with `share = a_ml/a_ls` (`:1896`, `src:474`) — `a_ml` is
simply smaller; NOTHING on `tr` is seasonal (R3). Residual ML fraction of the hemisphere = 1 − 0.16 − eq − tr = **0.395 / 0.589**
(the product's 0.430/0.619 differ by exactly the `hs_frac` ruling).
**Fitted.** NO new fitted name (33 stays 33; `w_eq`, `gamma_eq` as before; `q_tr` is 0 and not in the table).

## 2. The plumbing (per hemisphere, inside the `for (hi ...)` loop, under `if (aux$tr_on == 1L)`)
1. **The loop re-routed** (`R/model.R:2720-2727`; `src:846-853`): upwelling `oc[k_eq] → eq` unchanged; surface divergence
   **`eq → tr`**: `W × y[ieq,"C"]/(a_eq h_eq)` (label `eq_ml` — both boxes class "ml", `R/fluxes.R:60-63`); subduction **`tr → oc[k_eq]`**:
   `W × y[itr,"C"]/(a_tr h_tr)`. With `tr` off the two limbs are the 09-13g ones (`eq → ml`, `ml → oc[k_eq]`), bit for bit.
2. **`tr`'s air–sea** (the cell's idiom, `:2735-2753`; `src:856-873`): `sst_tr(t) = sst_tr + sst_anom_h(t) + sst_tr_enso × enso(t)`;
   `dic_tr = C_tr × mol_per_GtC / tr_mass_kg`; pCO₂ from the carbonate routine at (`sst_tr(t)`, `alk_tr`), frozen-Revelle branch mirrored;
   `gx_tr = asx_tr × k_w × K0`; two gross limbs with `ccx_alpha_as(sst_tr)`, `alpha13_signed = TRUE`, with ITS hemisphere's atmosphere.
   No seasonal SST, no entrainment shim, no pump on `tr`.
3. **The diffusive `tr`–layer-1 interface** (the ML idiom at the SAME `kz_int[1]`, `:2350-2355`; `src:663-676`). Areas differ, so the
   effective-thickness form: `F = K (C_tr/h_tr − C_1/(dz_1(t) × a_ls/a_tr)) / dz_mid_tr`, `dz_mid_tr = (h_tr + dz_1(t))/2`; `dz_1(t)`
   is layer 1's thickness NOW (moves under `seas_ml`). A uniform column is exactly flux-free (P0g′).
4. **`q_tr` lateral exchange `tr ↔ ml`** (R4: coded, VALUE 0): two limbs `q × C_tr/(a_tr h_tr)` and `q × C_ml/(a_ml h_ml(t))`, alpha 1.
   `q_tr = 0` emits nothing. Built so N-T1's `q_tr → ∞` form and R4's later test are one number away, not a build.
5. Isotopes: bulk transport only (α = 1; ¹⁴C unfractionated). **Contracts:** (a) a UNIFORM column with `eq` and `tr` at the same
   concentration has ZERO tendency from the loop, the `tr` interface and `q_tr`; (b) the spinup's analytic guess puts `tr` at its own
   Henry point (`R/spinup.R:356-359`) and the Newton gate (`:389-391`) adds `|| aux$tr_on == 1L`; (c) the periodic spinup
   dimensions on `nrow(y)` — nothing to do.
**Outputs.** `CCX_OCEAN_BOX_COLS` (`R/model.R:69-70`) → 14 per hemisphere: `..., eq_C13_, tr_C_, tr_C13_, ml_pco2_, hs_pco2_, eq_pco2_, tr_pco2_`
(NA when off); `CCX_SURFACE_BOXES` (`:74`) gains `tr`; C++ `out` 11 + 28 = 39 wide, `pco2_rec[8]` (`src:384-386, 1122, 1186`); the R fill
(`R/forcing.R:969-1019`); `ccx_box_mass_at("tr")` (`R/likelihood.R:1144-1155`); `ccx_surface_annual_conc` = ml + eq + tr by mass (`:1210-1218`);
B1's "all surface" takes `tr` by area (`:1411-1437`); `ccx_flux_boxclass` classes `tr` as "ml" (`R/fluxes.R:142`); `ccx_out_na_guard_cols`
and the run guard drop `tr_*` when off (`R/cpp.R:436, 450`).
**Substep bound** (`R/model.R:3490-3501, 3543`): `ccx_tr_box_eigbound(p, grid)` = 2 × max(the `tr` interface's diffusion rates
K/(h_tr dz_mid_tr), K/(dz_1_eff dz_mid_tr) at each seasonal grid extreme; the loop's `tr` drain `W_h/(a_tr h_tr)` × (1 + |γ| × 3);
`q_tr`'s rates). Exactly 0 with `tr` off, so no registered trajectory changes.
**The D1 guard** (`:3038-3057`) extends to `tr`: `tr_frac > 0` with `w_up`/`w_out_*`/`q_conv` > 0 is refused by name.
**Label.** `ccx_apply_structure(p, "hilda_tr")` (`R/calibrate.R:1770-1781`; `run_dispersed_multistart.R:409`; `multistart.sbatch:185`;
`test-mode-file.R:183-185`): HILDA's block + the cell's block + the `tr` block + the three SST overrides above.

## 3. Likelihood changes — NONE new. (B1 and the gradient's surface reader widen to `tr` as stated; no new row, no new prior.)
The residual-ML `h_ml` prior (`obs_h_ml_prior.rds`, 70.2 m mean on the new mask vs the LS mask's) is **NOT re-cut in this build** —
flagged (handoff item 7; one `h_ml` for both hemispheres means the SH residual's 77 m is where option M starts to bind).

## 4. Predictions — P0 first; nothing below is read if P0 fails
### P0 — the contracts (`tests/testthat/test-tr-box.R`)
- **P0a NO-OP**: `tr_frac = 0` with every `tr` parameter set ⇒ `expect_identical(y)` with `hilda_eq`, 38 boxes, both cores; the substep
  count unchanged; `hilda30c`'s 25 stored streams reproduce to the bit (the eq file's P0a idiom).
- **P0b CONSERVATION**: closed system, `tr` + `eq` on, `w_eq` 27, `gamma_eq` 1, at enso −1.7 / 0 / +1.7; transient 1750–1752 to 1e-10.
- **P0c PARITY**: R vs C++ deriv < 1e-10, transient < 1e-12, all three structures on, `seas_ml` 1, two months.
- **P0d READER NO-OP**: `ccx_surface_annual_conc` identical (0.0) at `tr_frac = 0`; with `tr` present the surface is the three-box mass mixture.
- **P0e READER–DERIV**: `tr_pco2_` equals the deriv's recorded value to 1e-9, both cores; B1 with a hand-built `out` returns the
  four-box area contrast exactly.
- **P0f MIRROR LINT**: a mixed `tr_frac` pair errors "MIRROR BOXES" in both cores; box order (`tr` = `eq` + 1; stride 20) and
  `a_ml + a_eq + a_tr + a_hs == a_oc`; every geometry value range-checked by NAME; the D1 guard refuses the three older limbs with `tr` on.
- **P0g FIXED POINT**: a uniform column with `eq` and `tr` at the same concentration has zero tendency (loop + `tr` interface + `q_tr` = 1 Sv)
  to 1e-12; POWER: `tr` 10 % richer is not.
- **N-T1 (negative control, the bit-exact form)**: `tr_frac = 0` with the `hilda_eq` SSTs restored IS `hilda_eq` (P0a). The MEASURED form —
  `tr_frac = 0` under `hilda_tr`'s re-based SSTs, and `q_tr` = 1000 Sv (tr ≡ ml) — is read by the probe, not asserted.
- **Mutation per limb**: `w_eq` 0 (loop), `q_tr` 0 → 1 (lateral), `sst_tr_enso` 0, `kz` on the `tr` interface, `tr_frac` → the first build.
### PT — the science (`calibration/diag_tr_box_probe.R`, UNREFITTED at the array's incumbent, `w_eq` 27, `gamma_eq` 0.6)
- **PT1**: B1 within **2σ (±13.5) of +55.5** at `w_eq` 27, γ 0.6 (the counterfactual said +61 with the T-term off). FAIL above +69 ⇒
  `tr`'s DIC does not equilibrate warm enough (its layer-1 diffusive exchange too fast, or the source contrast wrong).
- **PT6**: `tr`'s own surface DIC lands inside GLODAP's band — target **1963** µmol/kg (`$dic_tr$both$target`, σ_cluster 49.7, epoch 2009);
  δ¹³C inside the tropical surface band (the PE6 idiom).
- **R3's read**: the MASK CHANGE alone (`hilda_tr` with `tr_frac` 0, i.e. `sst_NH/SH` 17.18/15.35 and `sst_eq` 26.33 in the first build) on the
  25 common rows vs `hilda_eq` at the same vector — a price, reported, not gated.
- **PT7 (R5's measurement)**: the solubility-only ENSO r and slope with `sst_tr_enso` at the product's 0.202 vs 0.
- **PT2–PT5** (the array, `hilda30t` proposed): fitted `w_eq` inside Meinen's 21–33 (PE8 re-run); fitted `gamma_eq` DROPS below 0.60
  (registered tension: ~0.3–0.35 = 8–9.5 Sv per index, below the observed 14–25); `pump_grad` returns toward 314; the 25 common rows
  move < 2 log-units vs the canonical.

## 5. Rulings still owed BEFORE the array (flagged, not resolved here)
- **R5 — `sst_tr_enso`**: the box's OWN Niño3.4 SST slope (+0.20 K/index, measured) ON (the cell's idiom, the build's default, read from
  the product) or 0 (the ML's idiom: no local ENSO SST term). PT7 measures both; Marcus's call before launch.
- The residual-ML `h_ml` prior / `obs_mld$ls` re-cut (§3). The `hs_frac` 0.16 vs 0.126/0.130 ruling. The `seas_ml`-on-`tr` follow-up (R3).

## 6. Not claimed
Not that T1 fixes GATE V; not that 14–25 Sv per index is reproduced (PT3 predicts NOT); not that `h_ml`'s ridge resolves; not that the
SH-heavy asymmetry is representable. `hilda_eq` and `start_011` remain reproducible provenance; `hilda30c` is canonical throughout.

## 7. Order and artifacts
R side (`model.R`: names, resolver, defaults, prepare/aux, deriv block, outputs, bound; `spinup.R`; `likelihood.R`; `fluxes.R`; `forcing.R`;
`calibrate.R`: `ccx_struct_hilda_tr()` + the label) → C++ twin + `cpp.R` marshaling → `test-tr-box.R` (P0a–g, N-T1, mutations) → the full
suite (the standing reds: the GATE Q pair + `test-seas-lag-split:205`) → `diag_tr_box_probe.R` (PT1, PT6, R3's read, PT7) → R5 → the array
under `CCX_MS_STRUCT=hilda_tr CCX_MS_SEAS_ML=1 CCX_MS_PIN=ent_seas_amp_SH=0`, new `port_targets.csv`, proposed mode name `hilda30t` → PT2–PT5.
Logs and rds under `outputs/diagnostics/tr_box_*_2026MMDD.*`.

## 8. AMENDMENTS made DURING the build, before the transient probe ran (stamped 2026-09-14 f, commit `c4a13be`)
Both were forced by the PI spinup picture at the canonical vector (an aseasonal `ccx_spinup()` read, not a PT number), and both are
STATED choices with a knob, not silent resolutions:
- **D2 — `tr` carries its AREA SHARE of the LS pump export** (`aux$ml_pump_share = a_ml/(a_ml + a_tr)`; the cell stays pump-free as
  built, so `hilda_eq` reproduces). Measured before it: with the export drawn from the mixed layer alone (the prereg's literal "NO pump
  on tr"), the residual ML — 40 % of the LS surface — sat at **194 / 240 µatm** at PI and `tr` at **360 / 396**: the pump's 50 GtC/yr
  divergence field (sized on `a_ls`, which both boxes overlie) had one surface box to drain and one to outgas through. A per-area export
  must be drawn per area. Priced: it moves `tr` from +73 to +68 over the global surface at PI (not the fix, the correction).
- **R6 — `kz_tr_frac`** (structural; 1 = the tr–layer-1 interface at the ML base's own K, the design as RULED; 0 = no interface). Added
  because at 1 the box sits **+68 µatm over the global surface at PI even with `w_eq` = 0** (obs +7.6): the interface's exchange, 5.6 /yr
  at kz 11,300, exceeds the box's air–sea equilibration (4.7 /yr), so `tr` tracks layer 1's cold-equilibrated DIC. The probe scans
  1 / 0.3 / 0.1 / 0. **A ruling owed.** ⚠ At 0.3 the box lands at +0.5 over global but B1 does not move (+132) and the likelihood
  pays −119; at ≤ 0.1 the box is drained by its pump share (D2) with no resupply (−73 / −170 over global).
- A naming trap fixed on the way: `aux$pump` is ABSENT when the pump is off and R's `$` partial-matched it to `pump_ml_share`; the
  field is `ml_pump_share`. Never name an aux field `pump_*`.

## 9. The probe's reading (2026-09-14 f; `outputs/diagnostics/tr_box_probe_20260914.log`) — PT1 FAILS, and the mechanism is measured
At `start_011` (w_eq 27, γ 0.60): B1 **+101.6 (z +6.8)** as built vs the first build's +133.2; the mask change alone −4.9 on the common
rows (B1 +132.1); `tr ≡ ml` (q_tr 1000 Sv) +100.2 — the whole B1 move is the "all-surface" mean rising by the tr box's own +68–80, not
the cell's DIC falling. PT6 PASS (tr DIC 2009 vs 1963 ± 50, z +0.9 — the cluster σ hides the 46 µmol/kg that IS the +68). PT7: `sst_tr_enso`
0.20 → 0 takes the ENSO slope from 1.53× to 2.50× obs. **Why the hypothesis fails as built: layer 2's diffusive exchange is 3.14 /yr
against the loop's 0.045 /yr replacement (69×; NH, kz_int 9240 / 6961) — the DIC the cell exposes at 26 °C is set by pump + diffusion,
not by what the loop returns.** The counterfactual's +61 (cell air–sea at the ML's SST) removed the T-exposure itself; no return-path
design reproduces it. Design question for Marcus: a tropical COLUMN (tr over its own thermocline layers, the cell upwelling from the
tropical layer 2) vs a kz lever on the cell's source; R5 and R6 rulings; the array is NOT launched.
