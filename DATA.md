# Data sources and the calibration-input pipeline

Every dataset the model uses, where it came from, what it costs to trust, and exactly which
code turns it into model input. Companion to [DESIGN.md](DESIGN.md) (model spec) and
[CHANGELOG.md](CHANGELOG.md) (decision log).

**Rule this file enforces:** no number enters the model from memory. Anything not derived or
read from a dataset is tagged `provisional` in [`R/constants.R`](R/constants.R) and listed
by `ccx_check_constants()`.

---

## 1. The pipeline in three stages

```
data-raw/download_data.R        fetch  -> data-raw/downloads/   + MANIFEST.csv
data-raw/manual/                 (hand-supplied; TRACKED IN GIT, not downloadable)
        |
        v
data-raw/build_calibration_data.R  parse, tidy, cross-check
        |                          -> data/*.rds
        |                          -> prints the empirical benchmarks in DESIGN.md §6
        v
R/forcing.R                      assemble onto the model's monthly axis
        |                          -> ccx_build_forcing() -> monthly forcing table
        v
R/spinup.R  ->  R/model.R        1750 steady state, then integrate
```

| Stage | Script | Output | Gated by |
|---|---|---|---|
| Acquire | `data-raw/download_data.R` | `data-raw/downloads/` + `MANIFEST.csv` (URL, access date, SHA-256, citation per file) | checksum recorded |
| Parse | `data-raw/build_calibration_data.R` | `data/*.rds` + printed benchmarks | internal cross-checks (§5) |
| Carbonate | `data-raw/build_carbonate_tables.R` | `data/carbonate_coefs.rds` | `test-carbonate.R` vs seacarb |
| Assemble | `R/forcing.R` | monthly forcing table | `test-forcing.R` |
| Spin up | `R/spinup.R` | 1750 steady state | `test-spinup.R` |

Reproduce everything:

```bash
Rscript data-raw/download_data.R && Rscript data-raw/build_carbonate_tables.R && Rscript data-raw/build_calibration_data.R && Rscript tests/run_tests.R
```

---

## 2. Calibration targets (what the model is fitted to)

| Dataset | Coverage obtained | Role | Source |
|---|---|---|---|
| Mauna Loa monthly CO₂, **in-situ** | 1958–2026, n=812 | dense NH target | Scripps CO₂ Program, `data-raw/manual/` |
| South Pole monthly CO₂, flask+in-situ merge | 1957–2024, n=711 | dense SH target | Scripps CO₂ Program, `data-raw/manual/` |
| Law Dome CO₂ spline | 154–1996 CE | pre-1958 target; **spinup anchor** | Rubino et al. 2019, NOAA/WDS 25830 |
| Law Dome δ¹³C spline | 1020–1993 CE | pre-1980 Suess target | Rubino et al. 2019 |
| MLO + SPO monthly δ¹³C | 1980–2024 (n=532), 1977–2024 (n=528) | land/ocean sink partition | Scripps, `data-raw/manual/` |
| Zonal Δ¹⁴C, 5 zones, monthly | 1941.2–2019.4, n=4689 | bomb-era target, both hemispheres | Hua et al. 2022 via `SoilR::Hua2021` |
| **IntCal20 Δ¹⁴C** | 1700–1950 | **pre-bomb Suess target** | Reimer et al. 2020 via `rintcal` |
| GCB global budget | 1959–2024 | sink partition constraint | GCB 2025 (Friedlingstein et al. 2026) |

**Cross-checks, deliberately NOT used as extra likelihood terms** (using them would
double-count the same measurements):

| Dataset | Why it is a check, not a target |
|---|---|
| NOAA GML MLO + SPO CO₂ | independent network; see the scale analysis in §4 |
| NOAA/INSTAAR MLO + SPO δ¹³C (1990–2014) | independent network |
| Scripps MLO flask CO₂ | flask vs in-situ at the same station |
| Scripps MLO + SPO Δ¹⁴C (1999–2007) | **these stations feed Hua's zonal compilation** |
| **Oceanic ¹³C Suess effect** — Quay et al. 2003 rate + Eide et al. 2017 field | **Not a target YET, and that is a live decision, not a convention** — see below |

### 2b. The oceanic ¹³C Suess effect (added 2026-08-13)

Atmospheric δ¹³C is a likelihood target; **the ocean's own δ¹³C decline never
was**, so ocean-side ¹³C uptake has been running unscored and the model could
hit the atmospheric target with the wrong air–sea partition. Two anchors now
close that hole (`calibration/diag_oceanic_suess.R`, built by
`build_calibration_data.R` [8b] → `data/obs_oceanic_suess.rds`):

| Anchor | Value | Role |
|---|---|---|
| **Quay et al. 2003**, GBC 17(1):1004, doi:10.1029/2001GB001817 | **0.16 ± 0.02 ‰/decade**, global mean surface DIC, 1970s vs 1990s | has a stated uncertainty and is independent of the atmospheric target → **the candidate likelihood term** |
| **Eide et al. 2017**, GBC 31:492–514, doi:10.1002/2016GB005472; data doi:10.1594/PANGAEA.871993 (CC-BY-3.0) | **0.916 ‰ at 0 m**, 0.782 ‰ over 0–75 m, area-weighted, preindustrial → GLODAPv1.1 era | cumulative cross-check; reduced to a 33-level depth profile, the 17 MB NetCDF is not committed |

**Caveat on Eide, verified at build and re-asserted on every rebuild:** above
200 m the field is the 200 m back-calculation **plus a spatially constant depth
offset** (level-to-level differences have sd exactly 0 — their method builds the
shallow field by combining the 200 m estimate with coral/sclerosponge surface
records). **The global mean is usable; the NH/SH contrast above 200 m is
inherited from the 200 m level and must not be used to score a hemispheric
gradient.**

**What they say:** the model's mixed layer declines at **0.156 ‰/decade against
Quay's 0.160 ± 0.020** (−0.2 σ, and window-insensitive), while its
**atmosphere declines 21–25 % too fast** against both Law Dome and Scripps
flask. The ocean is not the δ¹³C problem. Promoting Quay to a likelihood term is
a **methodological choice awaiting Marcus' call**.

---

## 3. Forcings (what drives the model)

| Forcing | Coverage | Units into the model | Source |
|---|---|---|---|
| Fossil CO₂ | 1750–2024 | GtC/yr | GCB 2025 historical budget |
| Land-use change CO₂ | 1750–2024 | GtC/yr | GCB 2025 bookkeeping **1850–2024**; **1750–1849 from OSCAR v3.1 rescaled to GCB's level** (§4a) |
| Future emissions | 1750–2500, 5 SSP markers | GtC/yr | RCMIP v5.1.0 (`Mt CO2/yr` ÷ 1000 ÷ 3.664) |
| GMST anomaly | 1850–2024 | °C | IGCC (standing obs convention) |
| ENSO (Niño 3.4) | 1948–2026 | SST anomaly, 1991–2020 base | NOAA PSL |
| Nuclear-industry ¹⁴C | 1950–2023, 22 countries | GBq/yr → mol ¹⁴C/yr | Laemmel et al. 2025, doi:10.5281/zenodo.15034663 |
| Bomb ¹⁴C | 1952–1980, monthly | mol ¹⁴C/yr **delivered to the troposphere** | Tans 1981 SCOPE 16 Tables 1–2 (Table 2 after Telegadas 1971), via `data-raw/build_bomb_c14_source.R`; total still from Naegler & Levin 2006 |
| Cosmogenic ¹⁴C | all | mol ¹⁴C/yr | **solved by the spinup**, not prescribed (§7) |

---

## 3b. Seasonal climatology (added 2026-08-20e)

**The gap this fills.** HadSST4 and CRUTEM5 are held as **annual anomaly** series, and an
anomaly has its monthly climatology subtracted — so nothing in this repo could check the
model's four seasonal temperature knobs (`seas_T_amp_{NH,SH}`, `sst_seas_amp_{NH,SH}`).
The audit in `calibration/diag_driver_audit.R` found the fit sitting at −6.03 / −4.72 /
+3.83 prior-σ on priors that were recollections. These two products supply the **absolute**
climatology those anomalies are anomalies *from*.

| Dataset | Coverage | Role | Source |
|---|---|---|---|
| **CRU 1961–90 absolute climatology**, 5°, monthly | 12 months, global grid | land seasonal cycle → `seas_T_amp_*` | Jones et al. 1999, Rev. Geophys. 37:173–199, doi:10.1029/1999RG900002 |
| **CRUTEM5 gridded anomalies**, 5° | 1850–2025 | **land mask** for the above | Osborn et al. 2021, JGR-Atmos 126:e2019JD032352 |
| **NOAA ERSSTv5** monthly absolute SST, 2° | 1854–present | ocean seasonal cycle → `sst_seas_amp_*`; also the ocean mask used to derive land fraction | Huang et al. 2017, J. Climate 30:8179–8205, doi:10.1175/JCLI-D-16-0836.1 |

Built by `data-raw/build_seasonal_climatology.R` → `data/obs_seasonal_clim.rds`.

**Why these two products, on the IGCC-compatibility criterion.** For the **land** side the
choice is forced and it is the right one: CRU's `absolute.nc` is the designed absolute
companion to the CRUTEM anomalies the repo already holds — same 5° grid, same 1961–90
baseline. For the **ocean** side, HadSST4 (which the repo uses for the annual anomaly, and
which is HadCRUT5's ocean component) publishes **no absolute form at all**, so a different
product is unavoidable. ERSSTv5 is the one to reach for: IGCC's GMST is a 4-dataset mean,
and ERSSTv5 is the ocean component of **two of the four** — NOAAGlobalTemp and GISTEMP.
No absolute SST product is common to all four, because the fourth's is HadSST4.

**Mask caveat, stated not buried.** The seasonal cycle enters the model *additively*, on top
of the HadSST4 annual anomaly (`R/model.R` ~line 1000), so an ERSST-vs-HadSST4 mask
difference perturbs the seasonal **amplitude** only, never the anomaly path — and the
amplitude it replaces is wrong by ~25×.

**Weighting caveat, and it is the load-bearing one.** These are **area-weighted** means.
The model's parameters are not area-weighted quantities: `seas_T_amp_*` multiplies **soil
respiration** (so its counterpart is respiration-weighted) and `sst_seas_amp_*` modulates
**air–sea exchange** (gas-exchange-weighted). **These are prior anchors, not values to
prescribe.** The latitude-band variants (`all`, `>30`, `>45`) exist to bracket that gap from
above, since NH heterotrophic respiration is boreal-weighted.

### Two traps found while building it

**`absolute.nc` is spatially complete and has no missing_value.** It carries an interpolated
value in *every* cell, ocean included (range −70.3 to +35.7 °C, zero NAs). Averaged unmasked
it gives an "NH land" mean of 14.59 °C and a half-amplitude of 6.68 K, both badly
ocean-contaminated. The tell was NH and SH returning **exactly 1296 of 2592 cells each** —
half the globe apiece, which no land mask produces. `sc_gate_cells()` now asserts the masked
area fraction against a plausible range rather than printing it.

**The two 5° grids disagree about latitude order.** `absolute.nc` runs N→S (+87.5 first),
CRUTEM5 runs S→N; longitude agrees. Dimensions match either way, so an order assumption
would have masked Antarctica with the Arctic's coverage and produced a plausible wrong
answer. Aligned by `match()` on the values.

**Cell-area weighting is not land weighting.** At 5°, a cell with one coastal station counts
as wholly land; weighting by full cell area put the "land" mask at **41.9 %** of the globe.
The build weights each cell by cos(lat) × **land fraction derived from ERSSTv5's own ocean
mask**, giving 26.8 % globally against a true ~29 % — the residual is small islands and
coastal smoothing at 2°. Coastal cells are maritime-damped in `absolute.nc`, so this
approximation biases the land amplitude **low**, which is the conservative direction for the
argument it is used in.

### 3c. Terrestrial NPP hemispheric split (added 2026-08-20f)

`npp_frac_NH` was fitted under a **UNIFORM[0.4, 0.8]** prior with nothing on disk able to
check it. **MOD17A3HGF Collection 6.1** — the standard satellite NPP algorithm — now does.
The LP DAAC original is 500 m sinusoidal HDF behind an Earthdata login; **ICDC Hamburg
republishes it regridded to a regular 0.5° netCDF grid, CC-BY-4.0, no registration**, one
46 MB zip covering 2001–2023. Running SW, Zhao M (2021), doi:10.5067/MODIS/MOD17A3HGF.061;
regrid doi:10.25592/uhhfdm.14635. Built by `data-raw/build_npp_hemispheric.R` →
`data/obs_npp_hemispheric.rds`.

**Result:** global **52.75 PgC/yr**, NH share **0.5942** (sd 0.0135 across 2001–2023).

**The area trap, and it is the same shape as §3b's.** `npp` is the grid-cell mean over MODIS
pixels **carrying valid data**, not an average over the whole cell. Multiplying by full 0.5°
cell area assumes every cell is wholly vegetated and gives **65.1 PgC/yr**, well above
anything MOD17 publishes. The file carries its own fix: `numberofvalidvalues` counts
contributing pixels, and because MOD17's native sinusoidal pixels are **equal-area** that
count is proportional to valid area — 14400 at the equator, 7258 at 60°N (ratio 0.504 against
cos 60° = 0.500). Valid area = `nvalid` × pixel area, pixel area derived from the grid as the
equatorial cell ÷ 14400 (= 464 m square, against MODIS's nominal 463.3 m). Total then lands
at 52.75, and the sanity gate on the global total is what catches a regression.

**Compare at the model's modern state, never at the parameter.** `npp_frac_NH` is a **1750**
split; MOD17 is 2001–2023. The model walks between them through hemispheric clearing, so the
like-for-like comparison is against the *realised* modern share and the 1750 anchor is backed
out through the same clearing. Comparing the raw parameter to MOD17 would **understate** the
gap, since NH-heavy clearing lowers the NH share over time.

| quantity | value |
|---|---|
| `npp_frac_NH`, fitted 1750 parameter | 0.4662 |
| → model's realised modern NH share | 0.4461 |
| MOD17 observed modern NH share | **0.5942** |
| gap (model − observed) | **−0.1481** |
| ⇒ 1750 anchor implied by MOD17 | **0.6136** |

The implied anchor sits comfortably **inside** the uniform prior, so nothing was bounding the
parameter away from it. Per unit vegetated area the SH genuinely *is* more productive
(tropical-dominated): MOD17 1.64× against the model's 2.34× — right sign, too extreme.


---

### 3d. The seasonal SHAPE of terrestrial productivity (added 2026-08-20i)

§3c gives the *spatial* distribution of NPP and cannot say anything about its seasonal cycle,
because MOD17A3HGF is annual. That left `CCX_SEAS_PHI_EFF` half-answered: the NPP-weighted
effective latitude is **38.35 °N** if productivity follows insolation, but boreal productivity
is **rectified** — a growing season that switches on and off — and a poleward effective
latitude is a legitimate emulation of rectification rather than an error. **MOD17A2HGF
Collection 6.1**, the 8-daily member of the same family, removes the premise: the hemispheric
aggregate seasonal shape is *observed*, and the effective latitude is fitted to that.

Same ICDC 0.5° netCDF regrid, CC-BY-4.0, no registration; doi:10.25592/uhhfdm.14449 over
Running & Zhao doi:10.5067/MODIS/MOD17A2HGF.061. Downloaded by
`data-raw/download_mod17_gpp8d.R`, built by `data-raw/build_npp_seasonal_shape.R` →
`data/obs_npp_seasonal_shape.rds`. **Five years spread across the record** (2001, 2006, 2011,
2016, 2021 — 2022 is absent upstream), so the spread across them is the reported uncertainty
rather than a pentad's worth of ENSO. **The zips are kept and the unzipped files are not**:
597 MB per year against a 70 MB zip, which also keeps the manifest SHA-256 verifiable — it is
*not* verifiable for §3c, whose zip was deleted after unzipping.

**Two variables, as a bracket, because neither is NPP.** `gpp` is gross, and autotrophic
respiration runs through the shoulder seasons, so GPP is **less** rectified than NPP and its
effective latitude is biased equatorward — toward the convenient answer.
`net_photosynthesis` is MOD17's PsnNet = GPP − leaf and fine-root maintenance respiration:
closer to NPP, still short of it (no growth respiration, no live-wood maintenance). The truth
for NPP sits at or beyond the PsnNet end.

| | φ (shape) | sd across yr | φ (amplitude) | observed p2p | unexplained |
|---|---|---|---|---|---|
| NH `gpp` | 49.26 | 2.62 | 54.60 | 1.699 | 10.8 % |
| NH `psnnet` | **49.96** | 2.93 | **55.49** | 1.747 | 11.4 % |
| SH `gpp` | −10.86 | 4.22 | −28.17 | 0.736 | 14.3 % |
| SH `psnnet` | **−16.14** | 2.67 | **−32.15** | 0.845 | 12.8 % |
| *shipped* | 75.0 / −30.0 | | | *p2p 2.801 / 0.742* | |
| *annual product (§3c)* | 38.35 / −15.75 | | | *p2p 1.003 / 0.366* | |

**Rectification is real and it is not worth 75.** The observed NH shape sits ~11° poleward of
the insolation-weighted aggregate, so the defence of a poleward φ is genuine. But the shipped
75 over-drives the *observed* peak-to-peak by ~1.6×, and 38.35 under-delivers it by ~0.6×.

**Shape and amplitude give different latitudes, and both are reported.** No insolation shape
can match a rectified one, so the SSE fit compromises and lands short on amplitude — 11 % of
the NH cycle and 13–14 % of the SH cycle is residual that *no* single latitude can explain.
The SH is the sharper case: shape wants −11 to −16 while amplitude wants −28 to −32, and the
shipped −30 sits on the amplitude answer. SH productivity is tropical and water-limited, so
the insolation premise is weakest exactly where the shipped constant looked best.

**A by-product: the phenology lag is measured.** Insolation peaks at the solstice at every
extratropical latitude, so the offset between observed productivity and insolation *is*
`seas_lag_p`. NH: **+0.8 to +1.0 months**, against a fitted 2.17. SH: **−2.1 to −2.9 months**
— a *lead*. One global `seas_lag_p` cannot be both, which is a structural limitation of the
term rather than a mis-set value.

**Read-the-file gates:** global GPP 91.7 PgC/yr and PsnNet 59.3 PgC/yr over the five years.
The fitting operator is gated separately, by recovering a known (φ, lag) from a synthetic
target — a shift applied in the wrong direction returns a plausible number and no error.

**The comparison is window-integrated, not point-sampled**, and the last composite of each
year is 5–6 days rather than 8. Point-sampling a curved shape at coarse steps biases its
amplitude, and treating the short final window as a full one would inflate precisely the
winter end of the NH cycle — the end that carries the rectification signal.

### 3a. Pre-1850 land-use emissions (added 2026-08-13)

**GCB's LUC column is empty before 1850.** Its fossil column starts 1750; the land-use
column does not — verified in `gcb2025_historical_budget.csv` itself, not assumed. Until
2026-08-13, `ccx_annual_to_monthly()` stripped the NAs and `approx(rule = 2)` held the 1850
value (0.741 GtC/yr) flat backwards, **inventing 74.1 GtC across 1750–1849 — 23 % of all
the land-use carbon the model burns.** Nobody chose it, nothing warned, and it is the same
flat-hold pattern that GMST announces loudly on every build.

**Replacement:** OSCAR v3.1's `E_luc`, which runs from 1701.
Gasser T, Crepin L, Quilcaille Y, Houghton RA, Ciais P, Obersteiner M (2020), *Historical
CO₂ emissions from land use and land cover change and their uncertainty*, **Biogeosciences
17:4075–4101, doi:10.5194/bg-17-4075-2020**; data **doi:10.5281/zenodo.7313542**, CC-BY-4.0,
`data-raw/downloads/oscar_gcb2020_eluc.xlsx`. The file gives **27.5 PgC (1750–1849)** and
**178.9 (1850–2018)**, reproducing that paper's headline **206 ± 57 PgC** for 1750–2018
exactly — the check that the right column was read.

**It is rescaled, not spliced raw, and that is a methodological choice.** OSCAR's 1850–2018
total sits **34 % below GCB 2025's 239.8 GtC** because they are different products (GCB
averages three bookkeeping models including BLUE; OSCAR is observationally constrained and
low). Grafting OSCAR's absolute values on would put a **62 % step** at the join
(0.459 → 0.741 GtC/yr). So OSCAR supplies the **shape and the pre/post share**, rescaled by
the GCB/OSCAR ratio over an **1850–1900** overlap — the window *adjacent to* the splice,
chosen for continuity there. Ratio **1.518**, result **41.8 GtC**, splice step **6 %**.
(The whole-record 1850–2018 ratio is 1.341 and would give 36.9 GtC; that ~5 GtC spread is an
honest measure of how much the construction is worth arguing about.)

**Scored against the Law Dome ice core**, 1750–1850, at default parameters
(`calibration/diag_pre1850_luc.R`):

| option | cum GtC | RMSE ppm | bias ppm |
|---|---|---|---|
| flat-hold (old) | 74.1 | 2.48 | +1.58 |
| OSCAR absolute | 27.5 | 2.77 | −1.80 |
| **OSCAR scaled — adopted** | **41.8** | **2.00** | **−0.90** |
| zero | 0.0 | 4.50 | −3.53 |

**Zero is excluded by the data** — pre-1850 land-use emissions are not negligible and the
ice core says so. The flat-hold was not absurd (second best): it is roughly the right
*integral* spread over the wrong *shape*, too big too early, overshooting Law Dome by
+3.8 ppm at 1775 where the adopted series is +1.0.

**What this does NOT fix, recorded so it is not mistaken for something it does:** every
option undershoots Law Dome by **~6.5 ppm at 1900**, and none reproduces the full
18th-century rise (Law Dome +8.44 ppm 1750→1850; best option +5.10). There is a separate
19th-century deficit, larger than this entire question, untouched by the choice.

**Consequence:** the historical forcing changed, so `calibration/output/mode_fit.rds`
**predates it and is stale.**

`ccx_build_forcing()` now **warns** if any emissions column is NA inside the requested
window, so the next dataset with a hole cannot repeat this quietly.

---

## 4. Traps in these sources

Each of these was found the hard way and would silently corrupt results.

**Scripps monthly files: only column 5 is an observation.** The 10-column format carries
fit / seasonally-adjusted / **gap-filled** series in columns 7–10, fully populated even
where nothing was measured (the 1957 CO₂ row reads `NaN` but its fit and filled columns
both read 312.74). Reading a filled column invents ~100 monthly "observations", including
all but 11 of the 36 months in the 1950s, and understates calibration uncertainty.

**Missing-value markers differ between Scripps files.** The merge and flask files use
`NaN`; `monthly_in_situ_co2_mlo.csv` uses **−99.99**. Unhandled, −99.99 reads as a real
observation and poisons every mean it touches.

**Law Dome splines: two different columns are both named `age_CO2`.** The CO₂ spline starts
154 CE and the δ¹³C spline 1020 CE — different time axes, same column name. Parse
positionally.

**Inter-network CO₂ offsets are real and NOT constant.** Measured where both networks
report: Scripps − NOAA = −0.201 ± 0.217 ppm at MLO (n=812) and −0.134 ± 0.262 ppm at SPO
(n=543). By decade the MLO offset runs 0.000, 0.000, +0.04, −0.36, −0.31, −0.38, −0.17,
−0.29 — it wanders ~0.3 ppm, so no single constant corrects it. **The exact 0.000 ± 0.002
for 1958–1969 means NOAA's early MLO product simply *is* the Scripps record** — those years
are not an independent check. The model therefore uses Scripps for *both* stations (one
scale); the residual ~0.07 ppm inter-network disagreement about the gradient goes into the
error model as uncertainty, not as a correction.

**The MLO−SPO gradient must be computed from seasonally adjusted series.** MLO's ~6 ppm
seasonal cycle against SPO's ~1 ppm means uneven paired-month coverage aliases seasonality
straight into the "gradient". Raw monthly means gave a spurious *negative* 1950s gradient
(−0.30 ppm from 8 paired months, 5 of them in MLO's Aug/Sep minimum). Raw − adjusted:
1950s −0.77, 1960s +0.20, 2020s +0.13 ppm; ≤0.03 ppm for well-covered decades.

**Three different ¹⁴C time constants coexist and none may substitute for another:**

| Constant | Value | Used for |
|---|---|---|
| Libby mean life | 8033 yr | conventional ¹⁴C **age** convention: `F14C = exp(−age/8033)` |
| 5730-yr mean life | 8267 yr | **Δ¹⁴C** convention: `Δ14C = 1000(F14C·exp(calBP/8267) − 1)` |
| **True half-life** | **5700 yr** | **the model's decay constant** |

**MLO flask data cannot substitute for the in-situ record.** At ~3.5 flasks/month against
strong seasonal and synoptic variability, flask-derived monthly means differ from NOAA with
sd 2.5–4.7 ppm and a mean offset that is not even sign-stable (+0.239 ppm over all months,
−0.218 ppm restricted to months with ≥4 flasks). South Pole is the opposite case — clean
and stable enough that its flask-based monthly product has sd 0.262 ppm.

**Nuclear-industry ¹⁴C is a lower bound.** File coverage is incomplete (USA reports only
2010–2023, France NPP only 2005+), so the summed total understates the true source.

---

## 5. Internal cross-checks the pipeline runs

These compare *independent* datasets, and are printed by `build_calibration_data.R`:

| Check | Result |
|---|---|
| IntCal20 vs Hua NHZone1, 1941–1950 overlap | **0.90 ‰** mean abs difference (tree rings vs atmospheric compilation) |
| Scripps vs NOAA at MLO | −0.201 ± 0.217 ppm (n=812) |
| Scripps vs NOAA at SPO | −0.134 ± 0.262 ppm (n=543) |
| Derived cosmogenic ¹⁴C production vs canonical | 360 vs 545 mol/yr, ratio 0.66 (§7) |
| Deep-ocean Δ¹⁴C at spinup vs observed | −194.7 ‰ vs roughly −150 to −200 ‰ |

---

## 6. Assembly decisions in `R/forcing.R`

All are declared as named constants at the top of the file, not buried in the code.

| Decision | Value | Status |
|---|---|---|
| Fossil emissions NH share | 0.95 | **provisional, and now MEASURED at 0.9201** by the EDGAR v4.3.2 country aggregation (`data-raw/extract_emission_seasonality.py`). Not changed: moving it is worth 0.84 ppm of MLO−SPO for 5.1 log-units and belongs to review item 5's decision, not to the build that measured it |
| Land-use change NH share | **time-varying, 0.88 → 0.35** | **SOURCED 2026-08-15 (review item 5b)**, `data/forcing_luc_nh_share.rds`, built by `data-raw/build_luc_nh_share.R` from OSCAR v3.1's *Regional* sheet. Supersedes the constant 0.55, which is retained as `FORC_LUC_NH_SHARE` only as the `FORC_USE_LUC_NH_SHARE_TS = FALSE` fallback. See §6a |
| Nuclear ¹⁴C NH share | 0.95 | **provisional** — the 22 reporting countries are overwhelmingly NH |
| Bomb ¹⁴C NH share | 0.90 | **provisional** |
| GMST before 1850 | 0 | IGCC starts 1850; the model's baseline is its own 1750 spinup |
| ENSO before 1948 | 0 | Niño 3.4 starts 1948. A discontinuity in *constraint*, not physics: pre-1948 residuals have no ENSO explanation available |

### 6a. The land-use hemispheric share is time-varying (2026-08-15)

**Source.** OSCAR v3.1 bookkeeping E_LUC, *Regional* sheet of
`data-raw/downloads/oscar_gcb2020_eluc.xlsx` — the same workbook §3a already uses for the
pre-1850 E_LUC segment. Gasser T, et al. (2020), *Historical CO₂ emissions from land use and
land cover change and their uncertainty*, Biogeosciences 17:4075–4101,
doi:10.5194/bg-17-4075-2020. Its 1750–2018 regional total is **206.4 PgC**, reproducing the
paper's 206 PgC headline — the check that the right column of the right sheet is being read,
and a hard `stop()` in the build script.

**What is sourced and what is not.** The *regional* E_LUC series is sourced. The NH fraction
*within* each straddling region is **not** — OSCAR's regions are political aggregates, not
hemispheres — so those fractions are geographic judgements carried as a **lo/central/hi
bracket**, and every year of the product ships all three.

| period | E_LUC (GtC) | NH lo | NH central | NH hi |
|---|---|---|---|---|
| 1750–1849 | 27.5 | 0.797 | **0.838** | 0.880 |
| 1850–1899 | 30.4 | 0.719 | **0.766** | 0.812 |
| 1900–1949 | 57.2 | 0.600 | **0.668** | 0.735 |
| 1950–1989 | 54.6 | 0.428 | **0.527** | 0.627 |
| 1990–2018 | 36.8 | 0.267 | **0.398** | 0.528 |
| 1750–2018 | 206.4 | 0.539 | **0.620** | 0.700 |

**The direction survives the whole bracket.** Pre-1950 even the *low* end is ≥ 0.60;
post-1990 even the *high* end is ≤ 0.53. The two ends do not overlap under any admissible
judgement, which is what makes *"no constant can represent this"* a measurement rather than a
preference — and note that 0.55 is not even the flux-weighted mean, which is **0.620**.
Against the retired constant, the time-varying share moves **+31 GtC** of cumulative
land-use carbon into the northern box by 1959 and leaves **+20 GtC** there by 2024.

**Three properties, all gated by `tests/testthat/test-luc-nh-share.R`:**

- **One share per calendar year, held across that year** — not interpolated to months. This
  keeps `mean_year(luc_NH) == share(y) · mean_year(luc)` exact, and puts the only
  discontinuity precisely on the year boundary where the per-year harmonic estimator cannot
  alias it into the seasonal statistic. The step is ~0.003 GtC/yr.
- **The pre-window cumulative takes its own flux-weighted share.** A run starting in 1900
  splits ~58 GtC of prior clearing on the pre-1900 share (~0.79), not on the window's
  (~0.49). Using either the window's share or the old constant would misplace ~14 GtC of
  converted land, and *nothing else in the suite would see it* — the flux would still
  conserve.
- **Outside 1750–2018 the end value is held**, and that is an extrapolation, not a
  measurement: every SSP run therefore splits its land-use emissions on a frozen 2018 share
  of ~0.385. The alternative — extrapolating the observed decline forward — runs the NH
  share negative before 2260.

**What it buys, and what it does not.** At default parameters it moves the modelled 2015–24
MLO−SPO CO₂ gradient from **5.26 → 5.03 ppm** against an observed **3.97**, i.e. it closes
about a fifth of the model's error in the right direction; the δ¹³C gradient barely moves
(−0.245 → −0.238 ‰ against an observed −0.074), confirming that the *provisional shares are
not the cause of the 3× δ¹³C gradient miss*. **The log-posterior goes DOWN by 17.2**, almost
all of it in `co2_seasonal_MLO`. That is expected and is the same shape as item 5c: it is a
**bias correction, not a fit improvement**, and until review item 5's gradient terms exist
*nothing in the objective can see the quantity it fixes*.

**Annual → monthly interpolation must conserve annual totals.** Emissions drive cumulative
carbon, so an interpolation that quietly changes annual sums changes the answer while
looking perfectly smooth. `ccx_annual_to_monthly()` offers two methods:

- `"spline"` (default): natural spline through year midpoints, then an **additive**
  per-year correction so each year's 12 values average exactly to the annual value.
  Additive rather than multiplicative because annual values can be zero or negative
  (land-use flux, ENSO index), where a multiplicative rescale would blow up or flip sign.
- `"constant"`: piecewise constant within the year. Exactly conserving, shape-preserving,
  **cannot undershoot**. Required for sharply peaked non-negative sources.

Two bugs this caught, both of which inflated a prescribed total while looking fine:

1. Splining the bomb-¹⁴C series undershot either side of the 1962 peak; clipping those
   negatives back to zero **added 4.3 %** to the calibrated total. Fixed by `"constant"`.
2. Masking source records with decimal time instead of integer years dropped the **entire
   final year** of every record — month-centred `t` for year Y runs Y.04…Y.96, all of which
   satisfy `t > Y`. Cost another 0.28 % of the bomb total.

Both are now gated: `test-forcing.R` asserts cumulative fossil emissions match GCB to 1e-10
and that the bomb total is set by its prior rather than by the provisional shape.

---

## 7. Cosmogenic ¹⁴C is solved for, not prescribed

Natural production is **not optional**: with no cosmogenic source, unbalanced decay drifts
atmospheric Δ¹⁴C by −24.0 ‰ over 200 yr and −41.7 ‰ over 350 yr, against a −26.6 ‰
pre-bomb Suess signal — the artefact would exceed the signal.

`ccx_spinup()` solves for the production rate that holds atmospheric Δ¹⁴C at its 1750 value
in steady state, given the model's own inventory and ventilation. This makes the canonical
cosmogenic estimate (~2.04 atoms/cm²/s ≈ 545 mol ¹⁴C/yr) an **independent validation rather
than an input**. Derived: **360 mol/yr, ratio 0.66** — consistent with the model's ocean
inventory (32,827 GtC) sitting ~14 % below the canonical ~38,000 GtC plus the published
spread in production (1.6–2.5 atoms/cm²/s). A factor-2 miss would indicate a units bug.

---

## 8. Outstanding data gaps

| Gap | Impact | What would close it |
|---|---|---|
| ~~**Bomb ¹⁴C time shape**~~ | **CLOSED 2026-08-10** without UNSCEAR — see §9. | — |
| ~~Ocean bomb-¹⁴C inventory~~ | **ACQUIRED 2026-08-11** — see below | — |
| 7 provisional constants | Ocean areas and depth, surface alkalinity, seawater density, preindustrial NPP, SST–pCO₂ sensitivity | Cited sources. **The SST–pCO₂ sensitivity additionally risks double-counting** the carbonate module's own temperature dependence — check before applying |
| Scripps site unreachable | `scrippsco2.ucsd.edu` returns 404 on every asset path; the files in `data-raw/manual/` are irreplaceable and therefore tracked in git | Site restoration, or an alternative mirror |

---

## 9. Licences and citation

| Source | Licence |
|---|---|
| Scripps CO₂ Program | cite Keeling et al. 2001; SIO Reference Series 01-06 |
| NOAA GML / PSL / NCEI | US Government, public domain; cite the product |
| Global Carbon Budget 2025 | CC-BY 4.0, doi:10.18160/GCP-2025 |
| Hua et al. 2022 (via SoilR) | cite Radiocarbon 64(4):723–745, doi:10.1017/RDC.2021.95 |
| IntCal20 (via rintcal) | cite Reimer et al. 2020, Radiocarbon 62(4):725–757 |
| Laemmel et al. 2025 nuclear ¹⁴C | CC-BY 4.0, doi:10.5281/zenodo.15034663 |
| Law Dome (Rubino et al. 2019) | cite ESSD 11:473–492; data doi:10.25919/5bfe29ff807fb |
| seacarb | cite Gattuso et al., R package |

---

## 9. The bomb ¹⁴C source is a DELIVERY rate, not a production rate

**Closed 2026-08-10.** The UNSCEAR 2000 Annex C digitisation listed in §8 was never
needed. Two references supplied by Marcus resolved the gap, and in doing so exposed a
physics error in the placeholder rather than merely a provenance gap.

### The error

`R/model.R` gives each hemisphere **one well-mixed troposphere and no stratospheric
box**, and `forc$c14_bomb` is added straight into it. So the quantity that belongs in
that slot is the **stratosphere→troposphere flux**, not the production rate. The
superseded placeholder was shaped like production — 54.0 % of all bomb ¹⁴C in 1961–62,
2.2 % in 1963 — which delivers the big Soviet/US test series to the troposphere with no
stratospheric residence at all, roughly a year early.

Telegadas' measurements say the opposite: **56–60 % of the Naegler & Levin total was
still in the stratosphere in Dec 62 – Feb 63**, and 1963 was the largest single year of
delivery.

### The sources

| Reference | What it gives | Verdict |
|---|---|---|
| **Tans 1981**, SCOPE 16 pp. 131–157, Tables 1 & 2 | T2: stratospheric ¹⁴C inventory, quarterly Dec 62 – Aug 66 + Jul 69 (after Telegadas 1971). T1: tropospheric Δ¹⁴C NH/SH/global, annual Dec 1954–1977 | **This is the source function.** Tans p.133: the input of bomb ¹⁴C to the troposphere equals the stratospheric decrease |
| **Graven et al. 2017**, GMD 10:4405 | Atmospheric Δ¹⁴C **and δ¹³C**, 3 zones (30–90°N / 30°S–30°N / 30–90°S), annual 1850–2015; input4MIPs doi:10.22033/ESGF/input4MIPs.1601 and .1602 | **Not a bomb source** — an observation product, and coarser than the Hua et al. 2022 5-zone monthly record already in `obs_d14c_zonal.rds`. Retained as a δ¹³C cross-check back to 1850 |

### The construction (`data-raw/build_bomb_c14_source.R`)

**Governing principle (Marcus, 2026-08-10):** inventory data set the TOTALS; the observed
Δ¹⁴C record supplies the SUB-ANNUAL PATTERN only where no sub-annual inventory exists.
This confines any circularity with the likelihood to within-year timescales — every
interval total comes from Tans' independent compilation.

- **Interval totals, annual.** From 1963.04 on, each year's total is the Table 2
  stratospheric decrease. Before that, the totals come from budget closure: the Table 2
  series says 65.92 kmol was still aloft at 1963.04, so the remaining **36.08 kmol (35 %)
  of the Naegler & Levin total had already reached the troposphere**. That pins the
  pre-1963 integral with no test-yield inventory at all. Past the last Table 2 point the
  remainder decays at the τ = 6.87 yr fitted to its late points.

- **Why annual and not quarterly, when Table 2 *is* quarterly.** Its quarterly
  *differences* are not resolved. Telegadas reports inventories to ~3 figures, and the 14
  quarter-on-quarter releases come out as `7, 48, 29, 17, 30, 42, 13, 0, 14, 5, 7, −2, 15,
  3` — the small ones are rounding. The `0` arises because "170" is reported twice in
  succession, and it produced **three months of exactly zero delivery**; that notch pinned
  the modelled NH peak in every run of a `k_w`/`kz`/`h_ml`/`tau_ex` sweep spanning 2–4×.
  Annual sums (1963: 101, 1964: 85, 1965: 24 units) sit far above the noise floor. So we
  do not in practice have sub-annual *emission* data, and the concentration record supplies
  the sub-annual pattern throughout.

- **Within-interval shape.** `g(t) = dN14/dt + λ·N14` evaluated on observed monthly Δ¹⁴C
  (Hua et al. 2022, area-weighted to hemispheres) — the tropospheric ¹⁴C inventory plus its
  removal, i.e. the delivery the concentration record implies. Only its *shape* is used;
  each interval is rescaled to its inventory total.

- **Smoothing (`CCX_BOMB_SMOOTH`, default 5 months).** Observed Δ¹⁴C carries a seasonal
  cycle from *both* the spring stratospheric intrusion — a real feature of the source — and
  seasonal biosphere/ocean exchange, which `R/model.R` already simulates and which would be
  **double-counted** if it entered the source. Unsmoothed, `g` swung 23.8 → 39.2 → 12.8
  kmol/yr in successive months of 1963. A 5-month average retains ~75 % of a 12-month cycle
  so the spring maximum survives. The window is immaterial to results: 3, 5 and 9 months
  agree to <1 %.

**Uptake is not a small correction.** Of the 36.08 kmol delivered before 1963, only 21.57
kmol was still airborne — 40 % had already gone to ocean and biosphere. λ is not tuned: it
is the unique value closing the measured budget, in closed form.

**Independent check on λ.** Budget closure gives **λ = 0.1996 /yr (5.01 yr)**. Gross
air-sea exchange alone, built from Tans' own 19 mol/m²/yr (Broecker et al. 1978) at the
1962 disequilibrium, gives **0.1495 /yr (6.69 yr)** — 75 % of it, with the terrestrial
biosphere as the remainder. Two independent routes agreeing to 25 %, with the right sign
and a plausible ocean/land split, is the main evidence that the budget-closure step is
sound.

### Effect, against the model's own comparison basis

The DESIGN §6 bomb gate (944.6 ‰ at 1963.625) is **Hua NH Zone 1**, which is *not*
comparable to the model's area-weighted hemispheric `d14c_NH`. The correct benchmark,
computed with `ccx_zone_weights()` from `obs_d14c_zonal.rds`, is **NH 853.2 ‰ @ 1963.708,
SH 659.4 ‰ @ 1965.042**.

**Do not score this with peak timing.** The observed NH aggregate is **double-peaked** —
850.3 ‰ at 1963.625, dipping to 741.9 ‰ at 1964.125, then 832.6 ‰ at 1964.625. The two
maxima differ by 2 %, so `which.max()` flips between them under trivial perturbations and
manufactured an apparent "+0.92 yr timing error" that no parameter could move. The model
reproduces the double-peak structure and merely picks the other lobe.

Score it instead on **debiased scatter and correlation** over 1962–1972. A constant level
offset is precisely what `bomb_total` and the uptake parameters absorb during calibration,
so removing the mean is the fair comparison of *shape*:

| Bomb source | debiased sd, NH | debiased sd, SH | corr with obs, NH |
|---|---|---|---|
| **Measured input function (current)** | **34.5 ‰** | **36.1 ‰** | **0.970** |
| Two-exponential fit, no concentration input | 48.0 ‰ | 39.5 ‰ | 0.951 |
| Superseded placeholder | 233.4 ‰ | 186.1 ‰ | **0.121** |

The placeholder correlates with the observed bomb transient at **0.12** — it carried
essentially no information about the event it was supposed to represent.

A **−118 ‰ mean bias** remains at uncalibrated defaults. That is a level, not a shape,
and is left for calibration.

### Judgement calls, and how much they matter

Both are exposed as environment overrides so they can be measured, not argued:

| Choice | Default | Effect on NH peak timing |
|---|---|---|
| `CCX_BOMB_DROP_FIRST` — exclude the Dec 62–Feb 63 inventory point, which Tans p.133 calls "much too low" | `1` (drop) | drop → **+0.75 yr**; keep → +1.00 yr. Tans' own advice is also the empirically better choice |
| `CCX_BOMB_PREBOMB` — pre-bomb Suess baseline subtracted from Table 1 | `-30 ‰` (Table 1 SH Dec-54) | −30 vs −20 ‰ moves NH timing **not at all** and amplitude 0.5 %. Immaterial |

### Residual caveats

- The Part A/Part B join step is down from **4.5× to 1.6×** in one month, and what remains
  is defensible as real acceleration (the autumn-1962 tests descending in spring 1963)
  rather than a method switch.
- Tans' own caveats carry over: Telegadas' aircraft data may run ~20 % high; the
  Dec 62 – Feb 63 point is a floor (it is raised, not dropped, since it sets the pre/post
  split); French and Chinese tests after 1963 add production the "input = stratospheric
  decrease" identity does not capture.
- The sub-annual pattern is derived from the same Δ¹⁴C record the likelihood scores
  against. **Annual and longer timescales are independent** — those totals are Tans' — but
  within-year structure is not, so the bomb window cannot be treated as a fully independent
  test of sub-annual ocean exchange.
- A −118 ‰ mean bias survives at uncalibrated defaults; it is a level, not a shape.
- `bomb_total` remains a **calibrated** parameter with the Naegler & Levin prior; the
  stored series is normalised to unit integral, so it still cannot set the amplitude.


## 10. Excess radiocarbon budget — Naegler & Levin (2006)

**Acquired 2026-08-11.** `data-raw/manual/naegler_levin_2006_budget.csv`, transcribed from
Naegler, T., and I. Levin (2006), *Closing the global radiocarbon budget 1945–2005*,
J. Geophys. Res. **111**, D12311, doi:10.1029/2005JD006758 — Table 2 (observation-based ocean
inventories) and Table 4 (full reservoir partition at 1975 and 1995). PDF supplied by Marcus;
paywalled, so `download_data.R` cannot regenerate it and the file lives in `data-raw/manual/`
and is tracked in git, exactly as the Scripps records are.

This closes the "optional ocean bomb-¹⁴C inventory constraint" that DESIGN §6 and §10 listed as
*not yet acquired*.

**Trap — the definition of "excess".** These inventories are *total minus natural*, so they
carry the bomb addition **and** the Suess / CO₂-invasion terms together. They are NOT
comparable to a paired bomb-only model difference. Mouchet (2013), *Radiocarbon*
**55**(3):1580–1594, doi:10.1017/S0033822200048505, puts the CO₂ increase and the air-sea CO₂
flux at **~10 % each** of the 1990 ocean bomb inventory. Compare against a full-run-minus-
natural-counterfactual, not against a bomb on/off difference.

**Second trap — the biosphere row is not an observation.** N&L state that *no* observation-based
estimate of the global biospheric excess ¹⁴C inventory exists, that simulated values *"depend
strongly on model parameters such as turnover times, NPP, pool sizes"*, and that theirs is
possibly an underestimate whose deficit would be reassigned to their ocean. Treat Table 4's
biosphere column as a model intercomparison point, never as a target.

**Reference values (kmol ¹⁴C):** ocean 40.7–56.5 at GEOSECS (1975) and 43.8–59.0 at WOCE (1995);
troposphere 27 ± 1 and 17 ± 1; total bomb production 1945–1980 99.3–104.9 (already the
`bomb_total` prior).

**Parsed 2026-08-11** by `data-raw/build_calibration_data.R` §8 into `data/obs_excess_c14.rds`,
which stores **two** candidate ocean target sets — `table4_obs_range` (the full Peacock-to-Key
span; the default) and `table2_peacock` (one method, ~3× tighter). `LIK_EXCESS_C14_TARGET` picks
by name. The choice is worth ~130 log-units and is **flagged, not settled** — see CHANGELOG
2026-08-11 (night).

**Third trap — our excess is not their excess unless the model's own ¹⁴C budget closes, and it
does not.** N&L's Table 4 model partition sums *exactly* to their cumulative bomb input at both
years, so it is a paired bomb-only difference. Ours, summed the same way, **exceeds the bomb
input by 23.9 kmol at 1975 and 28.3 at 1995**. The cause is in `R/model.R`, not in the data:
land-use-change emissions are emitted with `add_source()` at the **vegetation box's own ¹⁴C
ratio** while the vegetation box is not debited, so 273 GtC of LUC carbon at Δ¹⁴C = +221 ‰ is a
¹⁴C *source*. (Fossil carbon is emitted at Δ¹⁴C = −1000 and correctly carries none.) The ocean
row survives this — bomb-only and total-minus-natural differ by 1–4 % there — but the **land row
does not**, and the 2026-08-11 "our land holds 2–3× their biosphere" reading is corrected to
~1.6× on the paired definition. `calibration/diag_excess_c14.R` reproduces all of it.

**Units cross-check, done rather than assumed.** The troposphere row is the only one where N&L's
number and ours meet with no model in between. Rebuilding the atmospheric excess from the CO₂ and
Δ¹⁴C observations alone gives 37.3 kmol (1975) and 25.6 (1995) against their troposphere +
stratosphere 35.6 and 21.7 — **+4.8 % and +18.0 %**, which is what
`LIK_EXCESS_C14_REP_FRAC = 0.15` carries. Note their stratosphere is a *model* value, so part of
the 1995 gap may be theirs rather than ours.
