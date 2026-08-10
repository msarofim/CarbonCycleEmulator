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

---

## 3. Forcings (what drives the model)

| Forcing | Coverage | Units into the model | Source |
|---|---|---|---|
| Fossil CO₂ | 1750–2024 | GtC/yr | GCB 2025 historical budget |
| Land-use change CO₂ | 1750–2024 | GtC/yr | GCB 2025 bookkeeping |
| Future emissions | 1750–2500, 5 SSP markers | GtC/yr | RCMIP v5.1.0 (`Mt CO2/yr` ÷ 1000 ÷ 3.664) |
| GMST anomaly | 1850–2024 | °C | IGCC (standing obs convention) |
| ENSO (Niño 3.4) | 1948–2026 | SST anomaly, 1991–2020 base | NOAA PSL |
| Nuclear-industry ¹⁴C | 1950–2023, 22 countries | GBq/yr → mol ¹⁴C/yr | Laemmel et al. 2025, doi:10.5281/zenodo.15034663 |
| Bomb ¹⁴C | 1945–1980 | mol ¹⁴C/yr | **shape PROVISIONAL** (§6); total from Naegler & Levin 2006 |
| Cosmogenic ¹⁴C | all | mol ¹⁴C/yr | **solved by the spinup**, not prescribed (§7) |

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
| Fossil emissions NH share | 0.95 | **provisional** |
| Land-use change NH share | 0.55 | **provisional** — LUC is far more tropical/SH-weighted than fossil |
| Nuclear ¹⁴C NH share | 0.95 | **provisional** — the 22 reporting countries are overwhelmingly NH |
| Bomb ¹⁴C NH share | 0.90 | **provisional** |
| GMST before 1850 | 0 | IGCC starts 1850; the model's baseline is its own 1750 spinup |
| ENSO before 1948 | 0 | Niño 3.4 starts 1948. A discontinuity in *constraint*, not physics: pre-1948 residuals have no ENSO explanation available |

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
| **Bomb ¹⁴C time shape** | The shape in `ccx_bomb_c14_annual()` is a documented placeholder from the qualitative test history. It is normalised to unit integral so the (citable) total sets the magnitude and the placeholder cannot set amplitude — but **bomb-era ¹⁴C results must not be reported on it**. | UNSCEAR 2000 Annex C annual atmospheric test yields — PDF only, no machine-readable release found; needs digitising |
| Ocean bomb-¹⁴C inventory | Optional integral constraint on ventilation | GLODAP-era estimates (Key et al. 2004 / Peacock 2004) |
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
