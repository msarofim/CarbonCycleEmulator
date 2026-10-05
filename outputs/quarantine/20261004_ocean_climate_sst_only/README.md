# QUARANTINE 2026-10-04 — the ocean climate-effect emulation that varied SST ONLY

## 1. The defect (a wrong premise in the driver, not in the model)
`calibration/diag_ocean_climate_gobm.R` @`85b7052` emulated GCB 2025's GOBM protocols (sim A minus sim C,
CO2 prescribed) by varying only the two HadSST4 SST anomaly columns between A and C. Its header claimed SST is
all the climate CCX's ocean reads at `hilda34g`, and a guard checked that four ENSO coefficients were 0
(`sst_eq_enso`, `sst_tr_enso`, `gamma_enso_ocn_NH/SH`).
- **The premise is false.** The canonical's ocean also reads the Nino3.4 index through the **L2 ENSO limb**
  (`w_enso_l2` = 12.93 Sv per index unit, `aux$l2_on` = 1; R/model.R, the `w_enso_l2` block). El Nino suppresses
  an upwelling limb. The guard never looked at it.
- **How it was found:** the CO2-effect control B came out with a POSITIVE 2015–24 sink (+0.04 to +0.08 GtC/yr)
  under a normal year WARMER than its spinup, where outgassing is expected. Splitting B by forcing column
  (SST and GMST held, CO2 matched to the pre-industrial orbit) showed that the historical ENSO index alone moves
  +0.096 GtC/yr into the ocean, while GMST, AOD, N deposition and land use each move 0.
- **What it did to the headline:** the A − C effect omitted the ENSO limb's +0.10 GtC/yr. The ensemble read
  −0.453 ± 0.026 GtC/yr (2.3× GCB's −0.20) instead of −0.357 ± 0.027 (1.8×).

## 2. The files
- `ocean_climate_gobm_20261004.log`: the committed driver's run (20:17, from a frozen copy, md5-identical,
  `nice 10`, BLAS pinned). Its tables were `identical()` across two runs.
- `ocean_climate_gobm_20261004.rds`: the protocol table, the ensemble, the R0–R2 decomposition, the annual
  series, and checks 1–4 (chemistry, linearity, Bunsen 2024, pathways).

## 3. What IS still usable, and the canonical replacement
- **Every SST-only number is valid as the THERMAL part** of CCX's ocean climate effect. The fixed driver
  reproduces all ten protocols' SST-only effects to a difference of exactly 0 (`effect_sst_only` there equals
  `effect` here). That includes the 3.4× against Bunsen 2024's warming-only part (FESOM protocol, 2000–2019:
  −0.304 vs 0.09 PgC/yr).
- R0 (the §D identity, −0.430496), R1 and R2 are unaffected; R3 is new in the fix.
- Check 4 here scaled `w_eq`. That name is INERT at the canonical (the equatorial cell is off, `aux$eq_on` 0),
  so its elasticity of exactly 0 is correct but uninformative. The fix scales `w_enso_l2` instead.
- **The canonical result is `outputs/diagnostics/ocean_climate_gobm_20261004.{log,rds}`**
  (`calibration/diag_ocean_climate_gobm.R` @`d006ba9`; CHANGELOG 10-04 p). It varies SST AND ENSO. Its CHECK 0
  PROVES that column list complete: with every listed column held, all else historical and CO2 matched, the
  ocean moves −2.9e-6 GtC/yr against an allowance of 2.2e-4. CHECK 0 also mutation-tests itself: leave ENSO
  historical and it reads +0.096 and fails.
