# =====================================================================
# build_calibration_data.R — parse raw downloads into tidy calibration
# inputs, and derive the empirical benchmark values used as sanity gates.
#
# Everything here reads from data-raw/downloads/ (see MANIFEST.csv) and
# writes .rds to data/. No numbers are hard-coded from memory: the
# benchmark block at the end is COMPUTED FROM THE DATA and printed so it
# can be pasted into DESIGN.md §6 with provenance.
#
# Run from repo root:  Rscript data-raw/build_calibration_data.R
# =====================================================================

suppressWarnings(suppressMessages(library(data.table)))
suppressWarnings(suppressMessages(library(readxl)))  # OSCAR pre-1850 LUC, block [5a]

DL     <- "data-raw/downloads"   # reproducible by download_data.R
MANUAL <- "data-raw/manual"      # hand-supplied, tracked in git (Scripps site is down)
OUT    <- "data"
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

# ---- named constants (labels and filters derive from these) ----------
ENSO_CLIM_BASE   <- c(1991, 2020)   # WMO normal used to anomalize Nino 3.4 SST
GtCO2_PER_GtC    <- 3.664           # GCB 2025 stated conversion
MISSING_NOAA_CO2 <- c(-9.99, -0.99, -999.99)
MEI_MONTH_RULE   <- "second"        # bimonthly MEI season assigned to its 2nd month
D14C_ZONES       <- c("NHZone1", "NHZone2", "NHZone3", "SHZone1-2", "SHZone3")

cat("\n=== build_calibration_data.R ===\n")
cat("ENSO climatology base:", paste(ENSO_CLIM_BASE, collapse = "-"), "\n\n")

# =====================================================================
# 1. Instrumental CO2
# =====================================================================
mlo <- fread(file.path(DL, "co2_mm_mlo.csv"), skip = "year,month")
setnames(mlo, c("year", "month", "decimal_date", "co2_ppm", "co2_deseas",
                "ndays", "sdev", "unc"))
mlo[co2_ppm %in% MISSING_NOAA_CO2, co2_ppm := NA_real_]
mlo[sdev    %in% MISSING_NOAA_CO2, sdev    := NA_real_]
mlo[unc     %in% MISSING_NOAA_CO2, unc     := NA_real_]
mlo[, station := "MLO"][, hemisphere := "NH"]

spo_noaa <- fread(file.path(DL, "co2_spo_surface-flask_1_ccgg_month.txt"),
                  skip = "SPO", header = FALSE,
                  col.names = c("site", "year", "month", "co2_ppm"))
spo_noaa[, `:=`(station = "SPO_NOAA", hemisphere = "SH",
                decimal_date = year + (month - 0.5) / 12,
                co2_deseas = NA_real_, sdev = NA_real_, unc = NA_real_)]
spo_noaa[, site := NULL]

# --- Scripps South Pole (PRIMARY SH target) --------------------------
# 10-column Scripps monthly format. COLUMN 5 IS THE ONLY REAL OBSERVATION:
# columns 7-10 are fit / seasonally-adjusted / GAP-FILLED reconstructions.
# Reading a filled column here would silently invent ~100 monthly "observations"
# (and every one of the sparse 1950s months), so col 5 it is, NaN and all.
# Missing-value markers differ ACROSS Scripps files: the merge/flask files use
# "NaN" but monthly_in_situ_co2_mlo.csv uses -99.99. Handle both, or -99.99 sails
# through as a real observation and poisons every mean it touches.
SCRIPPS_MISSING <- -99.99

read_scripps_monthly <- function(path, value_name) {
  ln  <- readLines(path)
  hdr <- grep("^ *Yr, *Mn,", ln)[1]
  d <- fread(text = paste(ln[(hdr + 3):length(ln)], collapse = "\n"), header = FALSE,
             na.strings = "NaN", strip.white = TRUE, fill = TRUE)
  setnames(d, 1:6, c("year", "month", "excel_date", "decimal_date",
                     value_name, paste0(value_name, "_deseas")))
  d <- d[, 1:6, with = FALSE]
  for (cl in c(value_name, paste0(value_name, "_deseas"))) {
    set(d, which(d[[cl]] == SCRIPPS_MISSING), cl, NA_real_)
  }
  d[!is.na(year)]
}

# --- PRIMARY pair: both stations on the 2012 SIO manometric scale -----
# MLO has a true in-situ continuous record (denser and far less noisy than flask);
# SPO is flask-dominated, hence its "merge" product. Using Scripps for BOTH removes
# the inter-network scale offset from the MLO-SPO gradient, which is a primary
# constraint on tau_ex.
mlo_sio <- read_scripps_monthly(file.path(MANUAL, "monthly_in_situ_co2_mlo.csv"), "co2_ppm")
mlo_sio[, `:=`(station = "MLO", hemisphere = "NH", sdev = NA_real_, unc = NA_real_)]
setnames(mlo_sio, "co2_ppm_deseas", "co2_deseas")

spo_sio <- read_scripps_monthly(file.path(MANUAL, "monthly_merge_co2_spo.csv"), "co2_ppm")
spo_sio[, `:=`(station = "SPO", hemisphere = "SH", sdev = NA_real_, unc = NA_real_)]
setnames(spo_sio, "co2_ppm_deseas", "co2_deseas")

# --- cross-checks (NOT extra likelihood terms) ------------------------
mlo_noaa <- copy(mlo)[, station := "MLO_NOAA"]
mlo_flask <- read_scripps_monthly(file.path(MANUAL, "monthly_flask_co2_mlo.csv"), "co2_ppm")
mlo_flask[, `:=`(station = "MLO_SIO_FLASK", hemisphere = "NH", sdev = NA_real_, unc = NA_real_)]
setnames(mlo_flask, "co2_ppm_deseas", "co2_deseas")

keep <- c("station", "hemisphere", "year", "month", "decimal_date",
          "co2_ppm", "co2_deseas", "sdev", "unc")
co2_obs <- rbind(mlo_sio[, ..keep], spo_sio[, ..keep],
                 mlo_noaa[, ..keep], spo_noaa[, ..keep], mlo_flask[, ..keep])
co2_obs <- co2_obs[!is.na(co2_ppm)]
saveRDS(co2_obs, file.path(OUT, "obs_co2_monthly.rds"))

for (st in c("MLO", "SPO", "MLO_NOAA", "SPO_NOAA", "MLO_SIO_FLASK")) {
  s <- co2_obs[station == st]
  tag <- if (st %in% c("MLO", "SPO")) "  PRIMARY (Scripps, 2012 SIO scale)" else "  cross-check"
  cat(sprintf("[1] CO2 %-14s %d-%d  n=%-4d%s\n", st, min(s$year), max(s$year), nrow(s), tag))
}

# --- inter-network offset at the SAME station -------------------------
# MLO comes from NOAA GML (WMO scale) but SPO from Scripps (2012 SIO manometric
# scale). The MLO-SPO gradient is a primary constraint on interhemispheric
# exchange time, so any scale offset between the networks propagates straight
# into tau_ex. Measuring it at South Pole, where both networks report, isolates
# the network difference from any real gradient.
net_offset <- function(sio_st, noaa_st, label) {
  ov <- merge(co2_obs[station == sio_st,  .(year, month, sio  = co2_ppm)],
              co2_obs[station == noaa_st, .(year, month, noaa = co2_ppm)],
              by = c("year", "month"))
  d <- ov$sio - ov$noaa
  cat(sprintf("    %-4s Scripps - NOAA: %+.3f ppm  sd %.3f  se %.3f   (n=%d, %d-%d)\n",
              label, mean(d), sd(d), sd(d) / sqrt(length(d)), nrow(ov),
              min(ov$year), max(ov$year)))
  mean(d)
}
cat("    Inter-network scale offsets, measured where both networks report:\n")
off_mlo <- net_offset("MLO", "MLO_NOAA", "MLO")
off_spo <- net_offset("SPO", "SPO_NOAA", "SPO")
cat(sprintf("    => MIXED networks (MLO=NOAA, SPO=Scripps) would bias the gradient %+.3f ppm.\n", -off_spo))
cat(sprintf("    => Using Scripps for BOTH removes that. What remains is the networks'\n"))
cat(sprintf("       genuine disagreement about the gradient itself, %+.3f ppm: irreducible\n", off_mlo - off_spo))
cat(sprintf("       inter-network uncertainty for the error model to absorb, not a bias to correct.\n"))

# =====================================================================
# 2. Law Dome ice core / firn — spline composite + raw samples
# =====================================================================
# Wide file with paired (age, value, growth) blocks for CO2, CH4, N2O, d13CO2.
# Columns 1 and 10 are BOTH named "age_CO2" (different time axes: the CO2 spline
# starts 154 CE, the d13C spline 1020 CE), so parse positionally, not by name.
spl_lines <- readLines(file.path(DL, "law2018splines.txt"))
spl_hdr   <- grep("^age_CO2", spl_lines)[1]
spl_raw   <- as.data.table(read.table(
  text = paste(spl_lines[(spl_hdr + 1):length(spl_lines)], collapse = "\n"),
  sep = "\t", header = FALSE, fill = TRUE, na.strings = c("", "NA")))
co2_spline  <- spl_raw[, .(year = V1,  co2_ppm = V2)][!is.na(co2_ppm)]
d13c_spline <- spl_raw[, .(year = V10, d13c    = V11)][!is.na(d13c)]

# Parse from the line that BEGINS with "SampleID". Using skip="SampleID" matches
# the NOAA variable-description block ("## SampleID<tab>Sample ID, ...") tens of
# lines earlier, which parses the comment text as data and yields 334 rows of
# junk in V1..V14. That went unnoticed until the likelihood first used these
# samples, because the benchmarks use the splines.
read_law_samples <- function(path) {
  ln  <- readLines(path)
  hdr <- grep("^SampleID", ln)[1]
  d <- fread(text = paste(ln[hdr:length(ln)], collapse = "\n"),
             sep = "\t", header = TRUE, fill = TRUE)
  d[!is.na(d[[3]])]
}
ice_co2  <- read_law_samples(file.path(DL, "law2018co2.txt"))
ice_d13c <- read_law_samples(file.path(DL, "law2018d13c-co2.txt"))
cat(sprintf("    ice-core samples: CO2 n=%d (%s), d13C n=%d\n",
            nrow(ice_co2), paste(names(ice_co2), collapse=","), nrow(ice_d13c)))

saveRDS(list(co2_spline = co2_spline, d13c_spline = d13c_spline,
             co2_samples = ice_co2, d13c_samples = ice_d13c),
        file.path(OUT, "obs_icecore.rds"))
cat(sprintf("[2] Law Dome: CO2 spline %.0f-%.0f CE (n=%d); d13C spline %.0f-%.0f (n=%d)\n",
            min(co2_spline$year), max(co2_spline$year), nrow(co2_spline),
            min(d13c_spline$year), max(d13c_spline$year), nrow(d13c_spline)))

# =====================================================================
# 3. Modern d13C (NOAA/INSTAAR flask)
# =====================================================================
d13c_noaa <- rbindlist(lapply(c("mlo", "spo"), function(stn) {
  f <- file.path(DL, sprintf("co2c13_%s_surface-flask_1_sil_month.txt", stn))
  d <- fread(f, skip = toupper(stn), header = FALSE,
             col.names = c("site", "year", "month", "d13c"))
  d[, .(station = paste0(toupper(stn), "_NOAA"),
        hemisphere = ifelse(stn == "mlo", "NH", "SH"),
        year, month, decimal_date = year + (month - 0.5) / 12, d13c)]
}))

# Scripps d13C, BOTH stations — PRIMARY isotope targets, one isotope scale.
# Same column-5-only rule as CO2.
sio_d13c <- rbindlist(list(
  read_scripps_monthly(file.path(MANUAL, "monthly_flask_c13_mlo.csv"), "d13c"
    )[!is.na(d13c), .(station = "MLO", hemisphere = "NH", year, month, decimal_date, d13c)],
  read_scripps_monthly(file.path(MANUAL, "monthly_flask_c13_spo.csv"), "d13c"
    )[!is.na(d13c), .(station = "SPO", hemisphere = "SH", year, month, decimal_date, d13c)]
))

d13c_obs <- rbind(sio_d13c, d13c_noaa)[!is.na(d13c)]
saveRDS(d13c_obs, file.path(OUT, "obs_d13c_monthly.rds"))
for (st in unique(d13c_obs$station)) {
  s <- d13c_obs[station == st]
  cat(sprintf("[3] d13C %-10s %d-%d  n=%-4d%s\n", st, min(s$year), max(s$year), nrow(s),
              if (grepl("NOAA", st)) "  cross-check" else "  PRIMARY (Scripps isotope scale)"))
}

# Scripps SPO D14C: 1999-2007 station record. NOT added to the likelihood --
# this station feeds Hua et al.'s SHZone1-2 compilation, so using both would
# double-count the same measurements. Stored for independent validation of the
# zonal aggregation.
read_c14 <- function(file, station) {
  d <- fread(file.path(MANUAL, file), header = FALSE, col.names = c("date_str", "d14c"))
  d <- d[!is.na(d14c)]
  d[, date := as.Date(date_str, format = "%d-%b-%y")]
  d[, `:=`(year = as.integer(format(date, "%Y")), month = as.integer(format(date, "%m")))]
  d[, .(station = station, year, month, decimal_date = year + (month - 0.5) / 12, d14c)]
}
c14_val <- rbind(read_c14("intermittent_flask_c14_mlo.csv", "MLO"),
                 read_c14("intermittent_flask_c14_spo.csv", "SPO"))
saveRDS(c14_val, file.path(OUT, "obs_d14c_station_validation.rds"))
for (st in c("MLO", "SPO")) {
  s <- c14_val[station == st]
  cat(sprintf("[3b] Scripps %s D14C %d-%d n=%-3d -- VALIDATION ONLY (feeds Hua zonal compilation)\n",
              st, min(s$year), max(s$year), nrow(s)))
}

# =====================================================================
# 4. Delta14C — Hua et al. 2022 zonal compilation
# =====================================================================
hua <- readRDS(file.path(DL, "hua2022_zonal_d14c.rds"))
d14c_obs <- rbindlist(lapply(D14C_ZONES, function(z) {
  d <- as.data.table(hua[[z]])
  setnames(d, c("Year", "mean.Delta14C", "sd.Delta14C", "mean.F14C", "sd.F14C"),
           c("decimal_date", "d14c", "d14c_sd", "f14c", "f14c_sd"))
  d[, zone := z][, hemisphere := ifelse(grepl("^NH", z), "NH", "SH")][]
}))
saveRDS(d14c_obs, file.path(OUT, "obs_d14c_zonal.rds"))
cat(sprintf("[4] Hua D14C: %d zones, %.2f-%.2f, n=%d\n",
            length(D14C_ZONES), min(d14c_obs$decimal_date), max(d14c_obs$decimal_date),
            nrow(d14c_obs)))
cat("    NOTE: NH/SH box aggregation weights across zones are a FLAGGED choice\n")
cat("          (zone areas differ); all 5 zones stored, weighting deferred to the likelihood.\n")

# --- IntCal20 pre-bomb atmospheric Delta14C ---------------------------
# Hua et al. starts 1941, which leaves 1750-1941 -- the whole pre-bomb Suess
# decline -- unconstrained. IntCal20 (tree rings) covers it. Conversion from
# the published conventional radiocarbon age uses BOTH reporting constants:
#   F14C = exp(-C14age / 8033)      8033 = Libby mean life, the AGE convention
#   D14C = 1000 (F14C exp(calBP/8267) - 1)   8267 = 5730-yr mean life, the
#                                            Stuiver-Polach D14C convention
# NEITHER is the model's decay constant, which uses the true 5700-yr half-life.
# All three coexist correctly; conflating them is a classic 14C error.
if (requireNamespace("rintcal", quietly = TRUE)) {
  ic <- as.data.frame(rintcal::ccurve(cc = 1))
  names(ic)[1:3] <- c("calBP", "C14BP", "err")
  ic <- as.data.table(ic)
  ic[, year_CE := 1950 - calBP]
  ic[, F14C := exp(-C14BP / 8033)]
  ic[, d14c := 1000 * (F14C * exp(calBP / 8267) - 1)]
  intcal <- ic[year_CE >= 1700 & year_CE <= 1950, .(year = year_CE, d14c, err)]
  saveRDS(intcal, file.path(OUT, "obs_d14c_intcal20.rds"))
  cat(sprintf("[4b] IntCal20 pre-bomb D14C: %d-%d, n=%d; 1750 = %+.2f permil\n",
              min(intcal$year), max(intcal$year), nrow(intcal),
              intcal[year == 1750, d14c]))
  # cross-check against Hua over the overlap -- independent datasets
  ovh <- merge(d14c_obs[zone == "NHZone1" & decimal_date < 1951,
                        .(year = floor(decimal_date), h = d14c)][, .(h = mean(h)), by = year],
               intcal[, .(year, i = d14c)], by = "year")
  cat(sprintf("     cross-check vs Hua NHZone1 over %d overlapping yr: mean |diff| = %.2f permil\n",
              nrow(ovh), mean(abs(ovh$h - ovh$i))))
} else {
  warning("rintcal not installed; IntCal20 pre-bomb D14C target skipped")
}

# =====================================================================
# 5. Global Carbon Budget
# =====================================================================
gcb <- fread(file.path(DL, "gcb2025_global_budget.csv"), skip = "Year")
setnames(gcb, c("year", "fossil", "luc", "atm_growth", "ocean_sink",
                "land_sink", "cement_carbonation", "imbalance"))
gcb_hist <- fread(file.path(DL, "gcb2025_historical_budget.csv"), skip = "Year")
setnames(gcb_hist, names(gcb)[seq_len(ncol(gcb_hist))])
saveRDS(list(budget = gcb, historical = gcb_hist), file.path(OUT, "gcb_budget.rds"))
cat(sprintf("[5] GCB 2025: budget %d-%d, historical %d-%d (GtC/yr)\n",
            min(gcb$year), max(gcb$year), min(gcb_hist$year), max(gcb_hist$year)))

# ---- prescribed historical emissions forcing -------------------------
emis_hist <- gcb_hist[, .(year, fossil_GtC = fossil, luc_GtC = luc)]
emis_hist <- emis_hist[!is.na(fossil_GtC) | !is.na(luc_GtC)]

# ---- [5a] PRE-1850 LAND-USE EMISSIONS, SOURCED (2026-08-13) ----------
# GCB's fossil column starts 1750; its LUC column starts 1850 and is NA before.
# Until this block existed, ccx_annual_to_monthly()'s approx(rule = 2) held the
# 1850 value (0.741 GtC/yr) FLAT backwards to 1750, inventing 74.1 GtC of
# land-use emissions -- 23 % of all the LUC the model burns -- that nobody chose.
# GMST's identical flat-hold at least warns on every build; this one was silent.
#
# THE REPLACEMENT: OSCAR v3.1's E_luc (Gasser et al. 2020), which runs from 1701
# and gives 27.5 PgC over 1750-1849 against 178.9 over 1850-2018 -- reproducing
# that paper's headline 206 +/- 57 PgC for 1750-2018 exactly, which is the check
# that the right column was read.
#
# IT IS SCALED, NOT SPLICED RAW, and that is a methodological choice worth
# stating. OSCAR's 1850-2018 total (178.9) sits 34 % BELOW GCB 2025's (239.8)
# because they are different products -- GCB averages three bookkeeping models
# including BLUE, OSCAR is observationally constrained and on the low side.
# Grafting OSCAR's ABSOLUTE pre-1850 values onto a GCB post-1850 series would
# put a 61 % step at the join (OSCAR 0.459 at 1849 against GCB 0.741 at 1850).
# So OSCAR supplies the SHAPE and the pre/post SHARE, rescaled by the ratio of
# the two products over an 1850-1900 overlap window -- the window ADJACENT to the
# splice, chosen for continuity there rather than for agreement in the mean.
# Ratio 1.518; result 41.8 GtC. (The whole-record 1850-2018 ratio is 1.341 and
# would give 36.9 GtC; the difference between the two windows, ~5 GtC, is an
# honest measure of how much this construction is worth arguing about.)
#
# SCORED, NOT ASSERTED (calibration/diag_pre1850_luc.R, against the Law Dome
# ice core over 1750-1850, at default parameters):
#     option              cum GtC   RMSE     bias
#     flat-hold (old)        74.1   2.48   +1.58
#     OSCAR absolute         27.5   2.77   -1.80
#     OSCAR scaled  <-- this 41.8   2.00   -0.90
#     zero                    0.0   4.50   -3.53
# Zero is EXCLUDED by the data: pre-1850 land-use emissions are not negligible
# and Law Dome says so. The scaled option has the best RMSE and is the only one
# with a citation. NOTE the diagnostic's other finding, which this does not fix:
# every option undershoots Law Dome by ~6.5 ppm at 1900, so there is a separate
# 19th-century deficit that the pre-1850 LUC choice does not touch.
PRE1850_OVERLAP <- 1850:1900   # window the OSCAR->GCB level ratio is taken over
oscar <- as.data.table(readxl::read_excel(
  file.path(DL, "oscar_gcb2020_eluc.xlsx"), sheet = "Global"))
os_scale <- emis_hist[year %in% PRE1850_OVERLAP, sum(luc_GtC)] /
            oscar[year %in% PRE1850_OVERLAP, sum(E_luc)]
pre <- oscar[year >= min(emis_hist$year) & year < min(emis_hist[!is.na(luc_GtC), year]),
             .(year, luc_new = E_luc * os_scale)]
emis_hist[pre, luc_GtC := i.luc_new, on = "year"]
if (anyNA(emis_hist$luc_GtC))
  stop("[5a] pre-1850 LUC still NA after the OSCAR splice -- check coverage")
cat(sprintf(paste0("[5a] pre-1850 LUC: OSCAR v3.1 x %.3f (level ratio over %d-%d) -> ",
                   "%.1f GtC for %d-%d, replacing %.1f GtC of rule=2 flat-hold\n"),
            os_scale, min(PRE1850_OVERLAP), max(PRE1850_OVERLAP),
            pre[, sum(luc_new)], min(pre$year), max(pre$year),
            nrow(pre) * emis_hist[year == 1850, luc_GtC]))

# ---- [5b] TIME-VARYING d13C OF THE FOSSIL SOURCE ---------------------
# ADDED 2026-08-12. The model used a single d13c_foss = -28 permil for
# 1750-2024. calibration/diag_d13c_suess.R measured what that costs: the
# atmospheric Suess decline came out ~30 % too steep, obs - model growing
# monotonically to +0.58 permil at MLO by 2020, and that too-depleted
# atmosphere is relieved by a larger land sink -- so it was actively pushing
# q10 below 1 (calibration/diag_q10_stream_direction.R).
#
# -28 is wrong in two ways, both in the same direction:
#   (a) `fossil` above is GCB's fossil-fuel-AND-INDUSTRY column, which includes
#       CEMENT. Cement CO2 is calcined limestone, d13C ~ 0 permil, not fuel.
#   (b) the fuel mix moved. 1850 emissions are essentially pure coal (~-24);
#       gas (~-44) is a post-1900 addition. One modern-mix value applied to the
#       whole industrial period over-depletes cumulatively -- which is exactly
#       the growing-residual signature.
#
# So the signature is rebuilt as an emission-weighted mean of per-fuel
# endmembers, using GCB's own by-fuel split. Cross-check on the result:
# Graven et al. (2020) state the global fossil-plus-cement average "has been
# -28 permil to -24 permil", shifting more negative as gas displaces coal.
D13C_COAL   <- -24.0   # permil. Graven, Keeling & Rogelj (2020), GBC 34,
D13C_OIL    <- -26.5   # e2019GB006170: coal ~-24, gas ~-44, cement ~0 (calcined
D13C_GAS    <- -44.0   # carbonate). The oil value is the global modal crude-
D13C_CEMENT <-   0.0   # petroleum estimate of Tans (1981) / Andres, Marland,
D13C_FLARE  <- -44.0   # Boden & Bischof (2000), as quoted by Bush, Pataki &
D13C_OTHER  <- -24.0   # Ehleringer (2007), Appl. Geochem. 22:715-723.
# Flaring is vented/burned associated gas -> the gas endmember. "Other"
# (non-cement industrial process emissions) is put on the coal endmember; it is
# under 1.2 % of the total in every year, so the choice cannot matter.
# Pre-1850 is not covered by the by-fuel sheet. Emissions there are essentially
# pure coal and under 0.4 % of the cumulative total, so the FIRST YEAR's value
# is held back rather than extrapolated.
foss_fuel <- fread(file.path(DL, "gcb2025_fossil_emissions_by_fuel.csv"),
                   skip = "Year")
setnames(foss_fuel, c("year", "fossil_excl_carbonation", "coal", "oil", "gas",
                      "cement", "flaring", "other", "per_capita"))
foss_fuel[, d13c_foss := (coal * D13C_COAL + oil * D13C_OIL + gas * D13C_GAS +
                          cement * D13C_CEMENT + flaring * D13C_FLARE +
                          other * D13C_OTHER) /
                         (coal + oil + gas + cement + flaring + other)]
d13c_foss_hist <- foss_fuel[is.finite(d13c_foss), .(year, d13c_foss)]
emis_hist <- merge(emis_hist, d13c_foss_hist, by = "year", all.x = TRUE)
setorder(emis_hist, year)
# back-fill pre-1850, forward-fill any trailing gap; both are held, not trended
emis_hist[, d13c_foss := nafill(nafill(d13c_foss, "locf"), "nocb")]
saveRDS(emis_hist, file.path(OUT, "forcing_emissions_historical.rds"))
cat(sprintf("[5b] fossil source d13C: %.2f permil (%d, %.0f %% coal) -> %.2f (%d, %.0f %% coal, %.0f %% gas, %.1f %% cement)\n",
            d13c_foss_hist$d13c_foss[1], d13c_foss_hist$year[1],
            100 * foss_fuel[1, coal / (coal + oil + gas + cement + flaring + other)],
            d13c_foss_hist$d13c_foss[.N], d13c_foss_hist$year[.N],
            100 * foss_fuel[.N, coal / (coal + oil + gas + cement + flaring + other)],
            100 * foss_fuel[.N, gas  / (coal + oil + gas + cement + flaring + other)],
            100 * foss_fuel[.N, cement / (coal + oil + gas + cement + flaring + other)]))

# =====================================================================
# 6. GMST (IGCC) and ENSO
# =====================================================================
gmst <- fread(file.path(DL, "igcc2024_gmst_4dataset_mean.csv"))
gmst <- gmst[, .(year = as.integer(floor(time)), gmst_anom = GMST)]
saveRDS(gmst, file.path(OUT, "forcing_gmst.rds"))

read_psl <- function(path, missing) {
  ln  <- readLines(path)
  hdr <- scan(text = ln[1], quiet = TRUE)
  y0  <- hdr[1]; y1 <- hdr[2]
  body <- ln[2:(1 + (y1 - y0 + 1))]
  m <- do.call(rbind, lapply(body, function(l) scan(text = l, quiet = TRUE)))
  dt <- data.table(year = m[, 1], as.data.table(m[, -1]))
  setnames(dt, c("year", sprintf("m%02d", 1:12)))
  long <- melt(dt, id.vars = "year", variable.name = "mslot", value.name = "value")
  long[, month := as.integer(sub("m", "", mslot))][, mslot := NULL]
  long[value %in% missing | value < -90, value := NA_real_]
  long[order(year, month)]
}

mei <- read_psl(file.path(DL, "meiv2.data"), -999.00)
setnames(mei, "value", "mei")            # bimonthly season -> 2nd month (MEI_MONTH_RULE)

nino_abs <- read_psl(file.path(DL, "nina34.data"), -99.99)
clim <- nino_abs[year >= ENSO_CLIM_BASE[1] & year <= ENSO_CLIM_BASE[2],
                 .(clim = mean(value, na.rm = TRUE)), by = month]
nino <- merge(nino_abs, clim, by = "month")[, .(year, month, nino34_anom = value - clim)]

enso <- merge(nino, mei[, .(year, month, mei)], by = c("year", "month"), all = TRUE)
enso <- enso[order(year, month)]
saveRDS(enso, file.path(OUT, "forcing_enso.rds"))
cat(sprintf("[6] GMST %d-%d; ENSO: Nino3.4 %d-%d, MEIv2 %d-%d\n",
            min(gmst$year), max(gmst$year),
            min(nino[!is.na(nino34_anom)]$year), max(nino[!is.na(nino34_anom)]$year),
            min(mei[!is.na(mei)]$year), max(mei[!is.na(mei)]$year)))
cat("    NOTE: DESIGN specified MEIv2 + MEI.ext; MEI.ext is RETIRED upstream (404).\n")
cat("          Nino 3.4 (1948+) is the fallback long index -- FLAGGED choice.\n")

# =====================================================================
# 7. SSP scenarios (RCMIP v5.1.0)
# =====================================================================
rc <- fread(file.path(DL, "rcmip-emissions-annual-means-v5-1-0.csv"), header = TRUE)
ssp_keep <- c("ssp119", "ssp126", "ssp245", "ssp370", "ssp585")
vars <- c("Emissions|CO2|MAGICC Fossil and Industrial", "Emissions|CO2|MAGICC AFOLU")
rc <- rc[Region == "World" & Scenario %in% ssp_keep & Variable %in% vars]
yr_cols <- grep("^[12][0-9]{3}$", names(rc), value = TRUE)
ssp <- melt(rc, id.vars = c("Scenario", "Variable"), measure.vars = yr_cols,
            variable.name = "year", value.name = "MtCO2")
ssp[, year := as.integer(as.character(year))]
ssp <- ssp[!is.na(MtCO2)]
ssp[, component := ifelse(grepl("AFOLU", Variable), "luc", "fossil")]
ssp_wide <- dcast(ssp, Scenario + year ~ component, value.var = "MtCO2")
# Mt CO2/yr -> GtC/yr
ssp_wide[, `:=`(fossil_GtC = fossil / 1000 / GtCO2_PER_GtC,
                luc_GtC    = luc    / 1000 / GtCO2_PER_GtC)]
ssp_out <- ssp_wide[, .(scenario = Scenario, year, fossil_GtC, luc_GtC)]
saveRDS(ssp_out, file.path(OUT, "ssp_emissions.rds"))
cat(sprintf("[7] SSPs: %s; %d-%d (GtC/yr)\n", paste(ssp_keep, collapse = " "),
            min(ssp_out$year), max(ssp_out$year)))

# =====================================================================
# 8. Excess radiocarbon budget (Naegler & Levin 2006) -- DATA.md 10
#
# Hand-transcribed from the paywalled paper, so it lives in data-raw/manual/
# and is tracked in git. Parsed here rather than read directly by the
# likelihood, for the same reason as every other target: no number enters the
# model from a script that is not the data pipeline.
#
# Only the OBSERVATION-BASED rows are promoted to a calibration target. The
# Table 4 model columns (their GRACE simulation) are kept for reporting, and
# their BIOSPHERE row is deliberately excluded from `targets` -- N&L state that
# no observational estimate of the global biospheric excess exists.
# =====================================================================
# read.csv with comment.char, as for the Tans SCOPE 16 tables: these
# hand-transcribed files carry their citation as a leading comment block, which
# fread cannot skip.
nl <- as.data.table(read.csv(file.path(MANUAL, "naegler_levin_2006_budget.csv"),
                             comment.char = "#"))
# TWO candidate ocean target sets are emitted, because which one to score
# against is a live methodological choice and they differ by a lot -- see
# likelihood.R's LIK_EXCESS_C14_TARGET. The likelihood picks by name; it does
# not get to invent numbers.
#   table4_obs_range  the Table 4 "observed" row: the full Peacock-to-Key span,
#                     corrected for missing ocean areas. WIDE.
#   table2_peacock    the Table 2 Peacock multitracer estimate with N&L's own
#                     correction and its stated uncertainty. TIGHT, and its
#                     1975 and 1995 values imply a much steeper ocean uptake.
nl_ocean_target <- function(src) {
  d <- nl[source == src & quantity == "ocean"]
  d[, `:=`(centre     = fifelse(is.na(kmol_14c), (kmol_lo + kmol_hi) / 2, kmol_14c),
           half_width = (kmol_hi - kmol_lo) / 2)]
  d[, .(year, quantity, lo = kmol_lo, hi = kmol_hi, centre, half_width, source, note)]
}
nl_targets <- list(table4_obs_range = nl_ocean_target("naegler_levin_2006_t4_OBS"),
                   table2_peacock   = nl_ocean_target("naegler_levin_2006_t2_peacock_corr"))
saveRDS(list(all = nl, targets = nl_targets), file.path(OUT, "obs_excess_c14.rds"))
cat(sprintf("[8] N&L 2006 excess 14C: %d rows; ocean target sets:\n", nrow(nl)))
for (nm in names(nl_targets)) {
  tt <- nl_targets[[nm]]
  cat(sprintf("      %-18s %s\n", nm,
              paste(sprintf("%d: %.1f +/- %.1f kmol", tt$year, tt$centre, tt$half_width),
                    collapse = "   ")))
}

# =====================================================================
# 8b. Oceanic 13C Suess effect -- the ocean-side cross-check on 13C uptake
#
# Added 2026-08-13. Until now NOTHING scored the model's OCEAN d13C: the
# atmospheric d13C target constrains what is left in the air, and the model can
# hit it with the wrong air-sea partition. These are the two observational
# anchors on the ocean's own decline.
#
# [a] Eide et al. 2017 gridded field, reduced HERE to an area-weighted depth
#     profile (cos-latitude weights over finite cells). The 17 MB NetCDF is not
#     committed; the 33-row profile is.
#
#     CAVEAT, verified not assumed: above 200 m the Eide field is the 200 m
#     back-calculation plus a depth offset that is constant over every ocean
#     cell (level-to-level differences have sd EXACTLY 0). Their method builds
#     the <200 m field by combining the 200 m estimate with coral/sclerosponge
#     surface records, so the shallow horizontal pattern is inherited, not
#     measured. USE THE GLOBAL MEAN; the NH/SH split above 200 m is an artifact
#     of the construction and must not be used to score a hemispheric gradient.
#
# [b] Quay et al. 2003's global mean SURFACE rate, which is a genuinely
#     independent measurement (GEOSECS-era vs WOCE-era DIC d13C) and carries a
#     stated uncertainty, so it is the one that can be scored as a likelihood
#     term. Hand-entered with its citation, same convention as N&L above.
# =====================================================================
suess_nc <- file.path(DL, "eide2017_c13_suess_effect.nc")
if (requireNamespace("ncdf4", quietly = TRUE) && file.exists(suess_nc)) {
  nc  <- ncdf4::nc_open(suess_nc)
  se  <- ncdf4::ncvar_get(nc, "c13_se")
  lon <- ncdf4::ncvar_get(nc, "lon")
  lat <- ncdf4::ncvar_get(nc, "lat")
  dep <- ncdf4::ncvar_get(nc, "depth")
  ncdf4::nc_close(nc)

  W  <- matrix(rep(cos(lat * pi / 180), each = length(lon)), nrow = length(lon))
  hemi <- function(sel) matrix(rep(sel, each = length(lon)), nrow = length(lon))
  wmean <- function(x, mask) { g <- is.finite(x) & mask; sum(x[g] * W[g]) / sum(W[g]) }

  suess_prof <- data.table(
    depth  = dep,
    global = sapply(seq_along(dep), function(k) wmean(se[, , k], TRUE)),
    NH     = sapply(seq_along(dep), function(k) wmean(se[, , k], hemi(lat > 0))),
    SH     = sapply(seq_along(dep), function(k) wmean(se[, , k], hemi(lat < 0))),
    ncell  = sapply(seq_along(dep), function(k) sum(is.finite(se[, , k]))))

  # Re-verify the constant-offset caveat on every build rather than trusting the
  # comment: if a future dataset version fixes it, this flag must change.
  shallow <- which(dep <= 200)
  off_sd  <- max(sapply(head(shallow, -1),
                        function(k) stats::sd(se[, , k] - se[, , k + 1], na.rm = TRUE)))

  suess <- list(
    eide_profile = suess_prof,
    eide_meta = list(
      constant_offset_above_200m = isTRUE(off_sd < 1e-12),
      max_level_diff_sd          = off_sd,
      reference_period = "preindustrial -> GLODAPv1.1 era (1990s; nominal 1995)",
      citation = paste("Eide M, Olsen A, Ninnemann US, Eldevik T (2017),",
                       "Global Biogeochem. Cycles 31:492-514,",
                       "doi:10.1002/2016GB005472; data doi:10.1594/PANGAEA.871993")),
    quay2003 = list(
      rate_permil_per_decade = 0.16, sd = 0.02, window = c(1970, 1993),
      scope = "global mean surface ocean DIC d13C, 1970s vs 1990s",
      citation = paste("Quay P, Sonnerup R, Westby T, Stutsman J, McNichol A (2003),",
                       "Global Biogeochem. Cycles 17(1):1004,",
                       "doi:10.1029/2001GB001817")))
  saveRDS(suess, file.path(OUT, "obs_oceanic_suess.rds"))
  cat(sprintf(paste0("[8b] oceanic Suess: Eide 0 m global %.3f permil, 0-75 m %.3f;",
                     " constant-offset-above-200m = %s\n"),
              suess_prof$global[1],
              mean(approx(suess_prof$depth, suess_prof$global,
                          seq(0, 75, length.out = 2001), rule = 2)$y),
              suess$eide_meta$constant_offset_above_200m))
} else {
  warning("[8b] oceanic Suess SKIPPED: needs the ncdf4 package and the Eide NetCDF ",
          "(run data-raw/download_data.R)")
}

# =====================================================================
# 9. EMPIRICAL BENCHMARKS (computed here; these replace DESIGN.md [VERIFY]
#    placeholders for anything that can be read off the data)
# =====================================================================
cat("\n=== EMPIRICAL BENCHMARKS (from data, this access date) ===\n")

# -- preindustrial CO2
pi_co2 <- co2_spline[year >= 1745 & year <= 1755, mean(co2_ppm)]
cat(sprintf("PI CO2 (Law Dome spline, 1745-1755 mean) : %.2f ppm\n", pi_co2))
pi_d13c <- d13c_spline[year >= 1745 & year <= 1755, mean(d13c)]
cat(sprintf("PI d13C (Law Dome spline, 1745-1755 mean): %.3f permil\n", pi_d13c))

# -- MLO seasonal amplitude by decade (peak-to-trough of the mean seasonal cycle)
mlo_seas <- co2_obs[station == "MLO" & !is.na(co2_ppm) & !is.na(co2_deseas)]  # Scripps in situ
mlo_seas[, resid := co2_ppm - co2_deseas]
mlo_seas[, decade := (year %/% 10) * 10]
amp <- mlo_seas[, .(amp_ppm = {s <- .SD[, mean(resid, na.rm = TRUE), by = month]$V1
                              max(s) - min(s)}), by = decade][order(decade)]
cat("\nMLO seasonal peak-to-trough amplitude by decade (ppm):\n")
print(amp[decade >= 1960])

# -- MLO minus SPO gradient
# The gradient MUST be computed from SEASONALLY ADJUSTED values. MLO has a ~6 ppm
# seasonal cycle against SPO's ~1 ppm, so whenever the paired months are unevenly
# distributed through the year the seasonal cycle aliases straight into the
# "gradient". The 1950s are the extreme case: 8 paired months, 5 of them Aug/Sep
# (MLO's seasonal minimum), which produced a spurious NEGATIVE gradient of
# -0.30 ppm from raw monthly means. Both Scripps products ship a seasonally
# adjusted column, so use it.
grad <- merge(co2_obs[station == "MLO" & !is.na(co2_deseas), .(year, month, mlo = co2_deseas)],
              co2_obs[station == "SPO" & !is.na(co2_deseas), .(year, month, spo = co2_deseas)],
              by = c("year", "month"))
grad_dec <- grad[, .(gradient_ppm = mean(mlo - spo), n_months = .N),
                 by = .(decade = (year %/% 10) * 10)]
cat("\nMLO - SPO gradient by decade (ppm), SEASONALLY ADJUSTED, paired-month counts:\n")
print(grad_dec[order(decade)])

# Show the size of the error that the seasonal adjustment removes.
grad_raw <- merge(co2_obs[station == "MLO", .(year, month, mlo = co2_ppm)],
                  co2_obs[station == "SPO", .(year, month, spo = co2_ppm)],
                  by = c("year", "month"))
gr <- grad_raw[, .(raw = mean(mlo - spo), n = .N), by = .(decade = (year %/% 10) * 10)]
cmp <- merge(gr, grad_dec, by = "decade")[order(decade)]
cat("  raw-vs-adjusted difference by decade (ppm):",
    paste(sprintf("%d:%+.2f", cmp$decade, cmp$raw - cmp$gradient_ppm), collapse = " "), "\n")
cat("  (the 1950s entry still rests on ~8 paired months -- indicative only.)\n")

# -- bomb 14C peak and decline, per zone
cat("\nDelta14C bomb peak by zone:\n")
pk <- d14c_obs[, .SD[which.max(d14c), .(peak_date = decimal_date, peak_d14c = d14c)], by = zone]
print(pk)
efold <- d14c_obs[zone == "NHZone1"][decimal_date > pk[zone == "NHZone1"]$peak_date]
if (nrow(efold) > 10) {
  fit <- lm(log(pmax(d14c, 1)) ~ decimal_date, data = efold[d14c > 20])
  cat(sprintf("NHZone1 post-peak e-folding time (log-linear fit, D14C>20 permil): %.1f yr\n",
              -1 / coef(fit)[2]))
}

# -- airborne fraction from GCB
gcb[, af := atm_growth / (fossil + luc)]
af_dec <- gcb[, .(airborne_fraction = mean(af, na.rm = TRUE)), by = .(decade = (year %/% 10) * 10)]
cat("\nAirborne fraction by decade (GCB 2025):\n")
print(af_dec[order(decade)])
cat(sprintf("Airborne fraction, full record %d-%d: %.3f\n",
            min(gcb$year), max(gcb$year), gcb[, sum(atm_growth) / sum(fossil + luc)]))

# -- recent-decade sinks
rec <- gcb[year >= max(year) - 9]
cat(sprintf("\nSinks, last 10 yr (%d-%d), GtC/yr:  ocean %.2f   land %.2f\n",
            min(rec$year), max(rec$year), mean(rec$ocean_sink), mean(rec$land_sink)))

# -- modern d13C
for (st in c("MLO", "SPO")) {
  s <- d13c_obs[station == st]
  cat(sprintf("\nd13C %-9s %.3f permil (%d) -> %.3f permil (%d)\n", st,
              s[which.min(decimal_date)]$d13c, s[which.min(decimal_date)]$year,
              s[which.max(decimal_date)]$d13c, s[which.max(decimal_date)]$year))
}

cat("\n=== processed inputs written to data/ ===\n")
print(data.table(file = list.files(OUT, pattern = "\\.rds$"),
                 kB = round(file.info(file.path(OUT, list.files(OUT, pattern = "\\.rds$")))$size / 1024, 1)))
