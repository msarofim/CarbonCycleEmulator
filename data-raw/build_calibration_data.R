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
read_scripps_monthly <- function(path, value_name) {
  ln  <- readLines(path)
  hdr <- grep("^ *Yr, *Mn,", ln)[1]
  d <- fread(text = paste(ln[(hdr + 3):length(ln)], collapse = "\n"), header = FALSE,
             na.strings = c("NaN", "NA", ""))
  setnames(d, 1:5, c("year", "month", "excel_date", "decimal_date", value_name))
  d[, 1:5, with = FALSE]
}

spo_sio <- read_scripps_monthly(file.path(MANUAL, "monthly_merge_co2_spo.csv"), "co2_ppm")
spo_sio[, `:=`(station = "SPO", hemisphere = "SH",
               co2_deseas = NA_real_, sdev = NA_real_, unc = NA_real_)]

keep <- c("station", "hemisphere", "year", "month", "decimal_date",
          "co2_ppm", "co2_deseas", "sdev", "unc")
co2_obs <- rbind(mlo[, ..keep], spo_sio[, ..keep], spo_noaa[, ..keep])
co2_obs <- co2_obs[!is.na(co2_ppm)]
saveRDS(co2_obs, file.path(OUT, "obs_co2_monthly.rds"))

for (st in c("MLO", "SPO", "SPO_NOAA")) {
  s <- co2_obs[station == st]
  cat(sprintf("[1] CO2 %-8s %d-%d  n=%d%s\n", st, min(s$year), max(s$year), nrow(s),
              if (st == "SPO_NOAA") "   (cross-check only; SPO = Scripps is primary)" else ""))
}

# --- inter-network offset at the SAME station -------------------------
# MLO comes from NOAA GML (WMO scale) but SPO from Scripps (2012 SIO manometric
# scale). The MLO-SPO gradient is a primary constraint on interhemispheric
# exchange time, so any scale offset between the networks propagates straight
# into tau_ex. Measuring it at South Pole, where both networks report, isolates
# the network difference from any real gradient.
ov <- merge(co2_obs[station == "SPO",      .(year, month, sio  = co2_ppm)],
            co2_obs[station == "SPO_NOAA", .(year, month, noaa = co2_ppm)],
            by = c("year", "month"))
cat(sprintf("    Scripps - NOAA at SPO over %d overlapping months (%d-%d): mean %+.3f ppm, sd %.3f\n",
            nrow(ov), min(ov$year), max(ov$year), mean(ov$sio - ov$noaa), sd(ov$sio - ov$noaa)))

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

ice_co2  <- fread(file.path(DL, "law2018co2.txt"), skip = "SampleID", fill = TRUE)
ice_d13c <- fread(file.path(DL, "law2018d13c-co2.txt"), skip = "SampleID", fill = TRUE)

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

# Scripps South Pole d13C — PRIMARY SH isotope target. Same column-5-only rule.
spo_d13c <- read_scripps_monthly(file.path(MANUAL, "monthly_flask_c13_spo.csv"), "d13c")
spo_d13c <- spo_d13c[!is.na(d13c),
                     .(station = "SPO", hemisphere = "SH", year, month, decimal_date, d13c)]

d13c_obs <- rbind(spo_d13c, d13c_noaa)[!is.na(d13c)]
saveRDS(d13c_obs, file.path(OUT, "obs_d13c_monthly.rds"))
for (st in unique(d13c_obs$station)) {
  s <- d13c_obs[station == st]
  cat(sprintf("[3] d13C %-10s %d-%d  n=%d%s\n", st, min(s$year), max(s$year), nrow(s),
              if (grepl("NOAA", st)) "  (cross-check / NH)" else "  (PRIMARY SH target)"))
}

# Scripps SPO D14C: 1999-2007 station record. NOT added to the likelihood --
# this station feeds Hua et al.'s SHZone1-2 compilation, so using both would
# double-count the same measurements. Stored for independent validation of the
# zonal aggregation.
c14_spo <- fread(file.path(MANUAL, "intermittent_flask_c14_spo.csv"), header = FALSE,
                 col.names = c("date_str", "d14c"))
c14_spo[, date := as.Date(date_str, format = "%d-%b-%y")]
c14_spo[, `:=`(year = as.integer(format(date, "%Y")),
               month = as.integer(format(date, "%m")))]
c14_spo[, decimal_date := year + (month - 0.5) / 12]
saveRDS(c14_spo[, .(station = "SPO", year, month, decimal_date, d14c)],
        file.path(OUT, "obs_d14c_spo_validation.rds"))
cat(sprintf("[3b] Scripps SPO D14C %d-%d n=%d -- VALIDATION ONLY (overlaps Hua SHZone1-2)\n",
            min(c14_spo$year), max(c14_spo$year), nrow(c14_spo)))

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
saveRDS(emis_hist, file.path(OUT, "forcing_emissions_historical.rds"))

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
# 8. EMPIRICAL BENCHMARKS (computed here; these replace DESIGN.md [VERIFY]
#    placeholders for anything that can be read off the data)
# =====================================================================
cat("\n=== EMPIRICAL BENCHMARKS (from data, this access date) ===\n")

# -- preindustrial CO2
pi_co2 <- co2_spline[year >= 1745 & year <= 1755, mean(co2_ppm)]
cat(sprintf("PI CO2 (Law Dome spline, 1745-1755 mean) : %.2f ppm\n", pi_co2))
pi_d13c <- d13c_spline[year >= 1745 & year <= 1755, mean(d13c)]
cat(sprintf("PI d13C (Law Dome spline, 1745-1755 mean): %.3f permil\n", pi_d13c))

# -- MLO seasonal amplitude by decade (peak-to-trough of the mean seasonal cycle)
mlo_seas <- co2_obs[station == "MLO" & !is.na(co2_ppm) & !is.na(co2_deseas)]
mlo_seas[, resid := co2_ppm - co2_deseas]
mlo_seas[, decade := (year %/% 10) * 10]
amp <- mlo_seas[, .(amp_ppm = {s <- .SD[, mean(resid, na.rm = TRUE), by = month]$V1
                              max(s) - min(s)}), by = decade][order(decade)]
cat("\nMLO seasonal peak-to-trough amplitude by decade (ppm):\n")
print(amp[decade >= 1960])

# -- MLO minus SPO gradient
grad <- merge(co2_obs[station == "MLO", .(year, month, mlo = co2_ppm)],
              co2_obs[station == "SPO", .(year, month, spo = co2_ppm)],
              by = c("year", "month"))   # SPO = Scripps, now back to 1957
grad_dec <- grad[, .(gradient_ppm = mean(mlo - spo), n_months = .N),
                 by = .(decade = (year %/% 10) * 10)]
cat("\nMLO - SPO annual-mean gradient by decade (ppm), with paired-month counts:\n")
print(grad_dec[order(decade)])
cat("  (the 1950s figure rests on a handful of paired months -- MLO starts 1958-03 --\n")
cat("   so treat it as indicative, not as a decadal mean on par with the others.)\n")

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
for (st in c("SPO", "MLO_NOAA")) {
  s <- d13c_obs[station == st]
  cat(sprintf("\nd13C %-9s %.3f permil (%d) -> %.3f permil (%d)\n", st,
              s[which.min(decimal_date)]$d13c, s[which.min(decimal_date)]$year,
              s[which.max(decimal_date)]$d13c, s[which.max(decimal_date)]$year))
}

cat("\n=== processed inputs written to data/ ===\n")
print(data.table(file = list.files(OUT, pattern = "\\.rds$"),
                 kB = round(file.info(file.path(OUT, list.files(OUT, pattern = "\\.rds$")))$size / 1024, 1)))
