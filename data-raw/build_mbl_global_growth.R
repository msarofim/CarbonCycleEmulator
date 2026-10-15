# =====================================================================
# build_mbl_global_growth.R -- the OBSERVED global CO2 growth rate, on the
# SAME ESTIMATOR the model side uses.
#
# ⛔⛔ WHY THIS FILE EXISTS (2026-09-26). The app's growth panel compared a
# model growth computed as a DIFFERENCE OF ANNUAL MEANS (app_annual_growth())
# against GCB's `atm_growth`, which is NOAA's published `co2_gr_gl` and is a
# JAN-TO-JAN difference of the deseasonalized global series. Two different
# estimators of the same quantity -- the standing like-for-like rule
# (~/.claude/CLAUDE.md), violated in a shipped panel.
#
# ⚠ IT IS NOT A SMALL DIFFERENCE. Measured on NOAA's own two products, which
# describe the SAME global CO2: annual differences sd 0.389 ppm/yr, max 0.950,
# and at 1991 ann_inc 0.75 against Δ-annual-mean 1.340 -- a gap of 0.59.
# ⭐ It is NOT a bias: the model's RMS is 0.397 either way. What it does is
# RESHUFFLE WHICH YEAR LOOKS WORST, which for a teaching panel is worse than a
# bias. On the mismatched pairing 1991 is the worst year at +1.018; MATCHED it
# is +0.428 -- 1.1 sigma, an ordinary year, not in the worst six (those are
# 1997 +0.854, 1988 -0.803, 2016 -0.745, 1999 -0.713, 2009 +0.658, 2024 -0.612).
#
# ⛔ AND THE OBVIOUS ALTERNATIVE WAS MEASURED AND REJECTED. Differencing the
# model's stock at CALENDAR-YEAR BOUNDARIES -- which is what the objective's
# gcb_*_sink rows and GATE 4's dg_af_annual_model() do -- would match GCB's
# convention, but it RE-INJECTS the model's seasonal-cycle error into an annual
# growth rate: RMS 0.397 -> 0.491, worst year 2024 at -1.600 (an end-
# extrapolation artifact, [[app_sink_half_year_offset]]). app_annual_growth()'s
# own header already warned of exactly this. So the MODEL side is left alone
# and the OBSERVATION is put on the model's estimator. (Marcus's call, 09-26.)
#
# THE SOURCE: NOAA's Marine Boundary Layer reference, global band (90S-90N),
# 48 samples/yr from 1979 -- manifest key `mbl_zonal_gl`, already in the repo
# (data-raw/download_data.R, fetch_mbl_zonal). Nothing new is downloaded.
# ⭐ CROSS-CHECKED against NOAA's separately published co2_annmean_gl.txt: the
# annual means agree to mean -0.012 ppm (sd 0.019), and the Δ-annual-mean growth
# to sd 0.026 ppm/yr. Two NOAA products, one estimator, same answer.
#
# ⚠ THE COST, STATED: the MBL reference starts 1979, so the observed growth
# series starts 1980 and the panel loses 1959-1979. GCB's own header calls the
# growth uncertainty "variable ... around 0.2 GtC/yr FROM 1980", i.e. the years
# lost are the least certain ones -- but they are lost, and the panel says so.
#
# Run:  Rscript data-raw/build_mbl_global_growth.R
# =====================================================================
suppressWarnings(suppressMessages({ library(tools) }))

MGG_SRC <- "data-raw/downloads/mbl_zonal_co2_GL.txt"
MGG_KEY <- "mbl_zonal_gl"
MGG_OUT <- "data/mbl_global_growth.rds"
MGG_MIN_SAMPLES <- 48L      # the product's own cadence; a short year is dropped

# ⛔ THE CHECKSUM IS VERIFIED AGAINST THE MANIFEST, not recomputed and stored.
# Same pattern as build_pump_export_prior.R: a build that trusts whatever is on
# disk cannot tell a re-download from a corruption.
man <- utils::read.csv("data-raw/downloads/MANIFEST.csv", stringsAsFactors = FALSE)
row <- man[man$key == MGG_KEY, ]
if (nrow(row) != 1)
  stop("manifest has no entry ", MGG_KEY, "; run data-raw/download_data.R")
if (tools::sha256sum(MGG_SRC)[[1]] != row$sha256)
  stop("sha256 of ", MGG_SRC, " differs from the manifest entry ", MGG_KEY)

raw <- utils::read.table(MGG_SRC, comment.char = "#", header = FALSE)
# year month day decimal_date value uncertainty
names(raw)[1:6] <- c("year", "month", "day", "dec", "co2", "unc")
raw <- raw[is.finite(raw$co2) & raw$co2 > 0, ]

yr  <- as.integer(floor(raw$dec + 1e-9))
n   <- tapply(raw$co2, yr, length)
lev <- tapply(raw$co2, yr, mean)
keep <- names(n)[n >= MGG_MIN_SAMPLES]
lev  <- lev[keep]; ys <- as.integer(keep)
ord  <- order(ys); ys <- ys[ord]; lev <- as.numeric(lev)[ord]
if (any(diff(ys) != 1L)) stop("a gap in the MBL annual series; growth would span it")

growth <- data.frame(year = ys[-1], g = diff(lev))

out <- list(
  growth = growth,
  level  = data.frame(year = ys, co2 = lev),
  provenance = list(
    source      = MGG_SRC,
    manifest    = MGG_KEY,
    sha256      = row$sha256,
    accessed    = row$accessed,
    citation    = row$citation,
    estimator   = paste("difference of CALENDAR-YEAR MEANS of the NOAA MBL global",
                        "reference -- deliberately the same estimator as",
                        "app_annual_growth() applies to the model"),
    not_this    = paste("NOT GCB `atm_growth` / NOAA `co2_gr_gl`, which is a",
                        "Jan-to-Jan difference of the deseasonalised series and",
                        "differs from this by sd 0.389 ppm/yr (max 0.950)"),
    min_samples = MGG_MIN_SAMPLES,
    built       = as.character(Sys.Date()),
    units       = "ppm/yr"))

dir.create("data", showWarnings = FALSE)
saveRDS(out, MGG_OUT)
cat(sprintf("wrote %s: %d years, %d-%d\n", MGG_OUT, nrow(growth),
            min(growth$year), max(growth$year)))
cat(sprintf("  1991 = %+.3f ppm/yr   (GCB atm_growth says 0.750)\n",
            growth$g[growth$year == 1991]))
cat(sprintf("  mean %.3f, sd %.3f ppm/yr\n", mean(growth$g), stats::sd(growth$g)))
