# Handoff — 2026-09-14 (e). **THE EQUATORIAL CELL'S FIRST ARRAY IS READ AND CLOSED (PE8 FAIL: `w_eq` 10.7 Sv, z −5.4 — the cell's excess at 27 Sv is the mixed layer's cold-equilibrated DIC exposed at 27 °C, measured); the SECOND BUILD IS RULED (T1, a TROPICAL SURFACE BOX; the 26 °C isotherm; `seas_ml` off then on; `q_tr` 0 then observation-based) and its DATA PRODUCT IS BUILT (`data/obs_tr_box.rds`). The `hilda_tr` model build is the next session's whole job. Canonical `hilda30c` unchanged; nothing adopted.**

> Self-contained. HEAD `c4f1792` (product `2ea5ea5`). CHANGELOG 09-14 (a)–(e). Memory: [[ccx_eq_cell_first_array_tdic]], [[ccx_tr_box_rulings_bound]],
> [[ccx_eq_cell_prelaunch_review]] (all in `INDEX_ccx_ocean_circ`; `INDEX_ccx` live line updated). Prereg (scoping tier, rulings stamped):
> `notes/prereg_2026-09-14c_equatorial_cell_tdic.md`. Previous handoffs: `handoff_2026-09-14a_eq_cell_prelaunch_review.md` (§1–§9 is this
> session's running log), `handoff_2026-09-13i_eq_cell_array_launch_commit.md`, `handoff_2026-09-13h_eq_cell_built_probed.md`.

## 1. Where the arc stands
1. **The first cell array (Torch 17769990, launch tree `11e2b7a`, results `317fc9f`)**: 24/24 exit 0, 8 CONVERGED; best −1450.518 (10 tasks; id 0,
   the cold start, converged there); the `h_ml` ridge again (74 / 70 / 65 / 50 m within 3 log-units) with the pair INVARIANT across it:
   **`w_eq` 10.72 Sv (z −5.4 on Meinen's 27 ± 3 ⇒ PE8 FAIL), `gamma_eq` 0.600** (PE7 pass by number, but 6.4 Sv/index vs the observed 14–25).
   PE1 on the fitted vector 1.12× obs (r +0.44); PE4 pass; PE2 partial (`gamma_enso_ocn` 0.34/0.05 → 0.20/0.13); `pump_grad` 314 → 258 in
   every basin; 25 common rows −0.46 vs `hilda30c`; B1 at the fit +73, z +2.65 (the row's −6.34 includes the Gaussian constant).
   **NOT promoted (ruled)** — a PE8 FAIL is not a canonical. Outdir + `summary.csv` + `collect_round1.log` + Torch logs committed.
2. **The lesson, measured** (`calibration/diag_eq_cell_levers.R` → `outputs/diagnostics/eq_cell_levers_20260914.{log,rds}`), at the best
   vector with `w_eq` = 27: B1 **+133** (z +11.5); decomposition on PI annual means (the ruled reader — NOT at an instant; the first cut read
   the orbit's opening point and got the NH ML at its winter 2187): excess +116/+128 = **T-term +124/+159** (the ML's DIC at the cell's SST)
   + DIC-term −8/−31. **Cell at the ML's SST: +60.7 (z +0.8).** Cold surfacing 7.9 µatm/°C; `k_eq` = 1 −30; both −45 — quarter-gap levers.
   The fit's 10.7 Sv STARVES the cell until its DIC deficit (−64/−93) cancels the T-term: a construct, not Meinen's quantity.
3. **Rulings (Marcus, 09-14 d/e)**: R1 = **T1**, a tropical surface box `tr` per hemisphere (mirror boxes, one parameter set) that the cell's
   loop closes through: `oc[k_eq] → eq → tr → oc[k_eq]`; NO shim (T2 not even as a diagnostic). R2 = the **26 °C** annual-mean SST isotherm
   (ERSSTv5 1991–2020) inside the LS domain, cell removed. R3 = **`seas_ml` OFF on `tr` first**, ON as the registered follow-up; the mask
   change read on the UNREFITTED vector first. R4 = **`q_tr` (lateral tr–ml surface exchange) structural 0 first**; "structural from an
   observation" is a LATER test paired with the `seas_ml`-on follow-up; NEVER fitted while B1 is the only row that sees it.
4. **The product** (`data-raw/build_tr_box_targets.R` → `data/obs_tr_box.rds`, `.log` beside it; in the run-input manifest): SOM-FFN 1° grid
   (the `eq_frac` grid; `eq_frac` reproduces to 1e-6), every surface SST RE-BASED to 1850–1900 by HadSST4 (−0.702/−0.701).
   | | NH | SH |
   |---|---|---|
   | `tr_frac` (of hemispheric ocean, cell removed) | 0.3966 (to 29°N) | 0.2149 (to 23°S) |
   | residual ML fraction (LS − tr − eq) | 0.4296 | 0.6191 |
   | SST PI-based: `tr` / residual ML / cell | 27.24 / **17.18** / 26.57 | 27.18 / **15.35** / 26.09 |
   | Holte MLD dt mean/max: tr; residual ML | 40.2/66.8; 57.9/131.2 | 45.9/73.2; 77.1/158.7 |
   | pCO₂ − global (CHECK, not a row): tr; residual ML | +6.7; −8.8 | +8.8; −4.2 |
   | GLODAP ≤ 50 m alk; DIC | 2296.2; 1964.0 | 2305.9; 1961.5 |
   | Niño3.4 SST slope, monthly | +0.204 ± 0.011 | +0.200 ± 0.013 |
   Product elements: `iso_C, clim, pi_base, rebase_C, ls_lat, geom, tr_frac, ml_frac, sst{tr,ml,eq,clim}, sst_enso, h_tr, h_ml_resid (+ today_ls),
   pco2, alk_tr, dic_tr, files, cite, built`.

## 2. Findings that need Marcus's eye (not acted on)
- **`sst_NH/SH` under `hilda_tr` = 17.18 / 15.35** — the first SOURCED values; ~0.7 °C cooler than the typed 18/16 (which were treated as PI).
  A mean-state move every registered mode feels (~+6 µmol/kg on the ML's Henry point). Price it separately (R3's unrefitted read).
- **`hs_frac` 0.16 vs the ocean's 0.126 / 0.130 poleward of 57.14°**: 57.14° was derived on a uniform SPHERE (`build_mld_targets.R`); HILDA's
  HS is ~25 % larger than the ocean in its own mask. A structural constant of every registered mode — a ruling, untouched.
- The first build's `sst_eq` 27.04 is the un-re-based climatology (the cell runs ~0.7 °C warm today, ~5 µatm on B1). `hilda_eq` keeps it
  (documented; the closed array stays reproducible); `hilda_tr` reads the re-based 26.57/26.09 from `obs_tr_box.rds`, not `obs_eq_cell.rds`.
- Also on the ledger from 09-14 (a): D1 closes only the cell's own limbs — `ccx_prepare()` refuses cell + (`w_up`|`w_out_*`|`q_conv`) > 0; the
  same guard must cover `tr`. Pump `kappa` sized on `a_ls` under D1 (unstated choice). `hilda30e` never registered.

## 3. Machinery this session added (all committed, suite 2957 / 2 F / 1 E = the known GATE Q pair + the 08-30 arm error)
- `CCX_PARAM_ABSENT_OK = c("w_eq","gamma_eq")`, `ccx_mode_carries_build()`, `ccx_mode_absent()`, `ccx_mode_start(md|name, who)` (migrate →
  seed → encode, returns `logpost_shift` = −0.8236) in `R/calibrate.R` after `.CCX_PARAM_ORDER`; consumers `ccx_load_mode` (migrates, does
  NOT seed), `ccx_check_mode_decode`, `app/global.R`, six test files; `test-param-absent-ok.R` keeps the list LIVE. Any new fitted name that
  lands ahead of its refit goes on the list with its three conditions, not a count bump.
- sbatch: NO struct default (exits 1 unset), `unset CCX_MS_ID`, preflight = the production ids; the banner prints the structure block.
- `calibration/diag_eq_cell_levers.R`, `data-raw/diag_tr_box_bound_sensitivity.R` (the 25/26/27 °C + ±20° table), `data-raw/build_tr_box_targets.R`.

## 4. NEXT SESSION — build `hilda_tr` (start from HEAD; a BUILD-tier prereg with hooks by file:line first, the cell's precedent)
Order (prereg 09-14c §5): 
1. **Model (`R/model.R`)**: `ccx_box_names(nl, hs, eq, tr)` — `tr` AFTER `eq` (40 boxes with all on; no existing index moves); `ccx_tr_on(p)`
   (both `tr_frac_*` > 0, mixed pair errors "MIRROR BOXES"); defaults zeros = OFF; `ccx_prepare()`: `a_tr = tr_frac·a_oc`, **`a_ml = a_ls − a_eq
   − a_tr`** (ML mass/asx/ML–oc1 interface follow `a_ml`; the interior keeps `a_ls`; the layer-1 effective thickness `dz_1·a_ls/a_ml` and
   `ccx_grid_at_h_ml(share = a_ml/a_ls)` already do the right thing — CHECK they see the new `a_ml`); extend the D1 guard to `tr`. `tr`'s own
   air–sea at `sst_tr + sst_anom_h(t)` (R side to RULE: + the box's own β 0.20·enso, or not), `alk_tr`; a diffusive interface `tr`–layer 1 over
   `a_tr` (the ML idiom, same `kz`), `q_tr` = 0; NO seasonal cycle (R3), NO pump; the cell's loop re-routed: divergence `eq → tr` (over
   `a_tr·h_tr`), subduction `tr → oc[k_eq]`; `sst_NH/SH` OVERRIDDEN by the structure with the residual's 17.18/15.35 — `ccx_struct_hilda_tr()`
   reads EVERYTHING from `obs_tr_box.rds` (+ the cell's geometry from `obs_eq_cell.rds` except its SST, which comes re-based from the tr product).
2. **Outputs**: `tr_C_, tr_C13_, tr_pco2_` columns (NA when off); `ccx_box_mass_at("tr")`; `ccx_surface_annual_conc` = ml + eq + tr by mass;
   B1's "all surface" and `hs_surf` by area include `tr`; `CCX_SURFACE_BOXES` gains `tr`. Substep bound: the tr–layer-1 interface.
3. **Spinup**: analytic guess puts `tr` at its own Henry point (the cell's idiom); Newton gate `|| aux$tr_on`. Periodic spinup dimensions on `nrow(y)`.
4. **C++ twin** (`src/ccx_core.cpp`: runtime `ITR`, the block beside the eq block; `R/cpp.R` every field BY NAME, zero-filled off).
5. **Tests** (`test-tr-box.R`): no-op at `tr_frac` 0 (bit-exact with `hilda_eq`); conservation with tr on at three enso values; R/C++ parity at
   seas_ml 1 over four months; reader no-op; mirror lint; fixed point (uniform column + loop); D1 guard; **N-T1**: `tr` merged into `ml`
   (`q_tr → ∞` or `tr_frac` → 0 with the loop on `ml`) reproduces the first build's +133 at 27 Sv to 1 %; mutation per limb.
6. **Unrefitted probe** (`diag_tr_box_probe.R`, the eq probe's idiom): PT1 (B1 within 2σ of +55.5 at `w_eq` 27, γ 0.6 — the counterfactual says
   +61), PT6 (`tr` DIC/δ¹³C vs GLODAP 1964 / the band), the mask-change read on the unrefitted vector (R3), the ENSO slope.
7. **The residual-ML products**: `obs_mld$ls` / `obs_h_ml_prior` on the new mask (from `h_ml_resid`: mean 70.2 both / 57.9 NH / 77.1 SH) — one
   `h_ml` for both hemispheres means the SH residual (77 m) is where option M starts to bind; flag, don't resolve.
8. **Array** under `CCX_MS_STRUCT=hilda_tr CCX_MS_SEAS_ML=1 CCX_MS_PIN=ent_seas_amp_SH=0`, 33 names (no new fitted name: `q_tr` is 0); new
   `port_targets.csv`; proposed mode name `hilda30t`. Then PT2–PT5.
Torch: `/scratch/ms17839/CarbonCycleEmulator` is still the first array's bundle (`11e2b7a`); re-bundle at launch (`make_bundle.sh`).

## 5. Non-obvious state
- `ccx_load_mode()` RUNS a registered file with the pair migrated to 0 (no loop); `ccx_mode_start()` SEEDS it at 27/1 — different questions.
- `ccx_require_param_set()` (Hessian-class diags) still refuses a migrated file, deliberately; the ~35 `diag_*.R` on it are still owed.
- The first array's start files record `struct = "hilda_eq"` and read the geometry from `obs_eq_cell.rds` at load — that product is UNCHANGED, so
  `start_011` still reproduces (−1450.5177 by_stream, checked).
- GATE Q pair (`test-alpha-as`) and `test-seas-lag-split:205` are the standing reds; everything else green.
- Still owed after the tr build: M (per-hemisphere MLD), pin-vs-retire of `ent_seas_amp_SH`, option K, the `OCEAN_AREA_*` provenance one-liner
  (the tr product now carries measured 1.543/2.064e14 — the same source can close it), the `hs_frac` ruling.
