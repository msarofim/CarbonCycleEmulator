# =====================================================================
# build_mbl_global_growth_monthly.R -- the OBSERVED global CO2 growth, MONTHLY: the
# interannual module's target (objective #17, RULED 2026-10-06 n).
#
# WHY. Marcus 2026-10-06: "What about having a 12-month smoothed CO2 growth that is used only for
# calibrating the ENSO and volcanic aerosol parameters?" Ruled: "Monthly (Recommended)" (the
# estimator) and "Build: land + ocean module (Recommended)". The module (R/likelihood.R,
# ccx_iav_module_loglik()) scores the model's centred 12-month growth against THIS series, both
# detrended over LIK_IAV_WIN. Until today the series was rebuilt inline by every diagnostic that
# used it (calibration/lib_block_reopt.R br_obs_growth()); an objective's target is a versioned
# product instead (Hard rule 3).
#
# THE SOURCE: NOAA's Marine Boundary Layer reference, global band (90S-90N), 48 samples/yr from
# 1979 -- manifest key `mbl_zonal_gl`, already in the repo (data-raw/download_data.R). Nothing new is
# downloaded, so there is no new MANIFEST row: the checksum is VERIFIED against the existing one.
# The annual sibling is data-raw/build_mbl_global_growth.R (the app's growth panel).
#
# THE ESTIMATOR, verbatim from br_obs_growth() (the refit read's s. 6; every 10-02 / 10-04 / 10-06
# timing diagnostic and the 10-06 preview read it):
#   - month means of the reference's value column (V5), grouped by its OWN year and month columns
#     (V1, V2) -- not the decimal date; the two agree on the year for every row (checked below);
#   - the CENTRED 12-month difference g[t] = co2[t + 6] - co2[t - 6] (R/likelihood.R ccx_cen12()),
#     NA within six months of either end. It removes the annual cycle; the module's spline removes
#     the trend.
# ⚠ Months carry 3-5 weekly samples (mostly 4; 48/yr do not divide evenly), and the record's last
# month may be partial: the column `n` records each month's count. Nothing is dropped, exactly as
# br_obs_growth() drops nothing -- a partial month can only reach g six months inside the end, and
# the module's window ends LIK_IAV_WIN[2] = 2024, a year before the product's.
#
# GATES (the build stops on any):
#   - the source's sha256 equals the manifest's;
#   - no missing or non-positive value;
#   - V1 equals floor(decimal date) on every row;
#   - no month missing between the first and the last;
#   - `g` equals br_obs_growth()'s, computed independently here from the raw table, to the bit.
#
# Run:  Rscript data-raw/build_mbl_global_growth_monthly.R
# =====================================================================
suppressWarnings(suppressMessages({ library(tools) }))

MGM_SRC <- "data-raw/downloads/mbl_zonal_co2_GL.txt"
MGM_KEY <- "mbl_zonal_gl"
MGM_OUT <- "data/mbl_global_growth_monthly.rds"
MGM_HALF <- 6L                 # the centred difference reaches this many months each side

man <- utils::read.csv("data-raw/downloads/MANIFEST.csv", stringsAsFactors = FALSE)
row <- man[man$key == MGM_KEY, ]
if (nrow(row) != 1)
  stop("manifest has no entry ", MGM_KEY, "; run data-raw/download_data.R")
if (tools::sha256sum(MGM_SRC)[[1]] != row$sha256)
  stop("sha256 of ", MGM_SRC, " differs from the manifest entry ", MGM_KEY)

wk <- utils::read.table(MGM_SRC, comment.char = "#")
# year month day decimal_date value uncertainty
if (ncol(wk) != 6L) stop("expected 6 columns in ", MGM_SRC, ", got ", ncol(wk))
if (any(!is.finite(wk$V5) | wk$V5 <= 0)) stop("missing or non-positive values in ", MGM_SRC)
if (any(wk$V1 != floor(wk$V4 + 1e-9))) stop("the year column disagrees with the decimal date")

# month means, grouped by the product's own year / month columns (br_obs_growth's grouping)
mo <- stats::aggregate(list(co2 = wk$V5), list(year = wk$V1, month = wk$V2), mean)
mo <- mo[order(mo$year, mo$month), ]
nn <- stats::aggregate(list(n = wk$V5), list(year = wk$V1, month = wk$V2), length)
mo$n <- nn$n[match(mo$year * 12L + mo$month, nn$year * 12L + nn$month)]
mo$k <- mo$year * 12L + mo$month
if (any(diff(mo$k) != 1L)) stop("a month is missing from the MBL series; the centred difference would span it")

cen <- function(x, h = MGM_HALF) {
  n <- length(x); g <- rep(NA_real_, n)
  i <- (h + 1L):(n - h); g[i] <- x[i + h] - x[i - h]; g
}
mo$g <- cen(mo$co2)

# THE PARITY GATE: br_obs_growth() as it stands in calibration/lib_block_reopt.R, re-implemented from
# the raw table (it reads a global the calibration drivers set), must give the same g, bit for bit.
br_ref <- local({
  m2 <- stats::aggregate(list(co2 = wk$V5), list(year = wk$V1, month = wk$V2), mean)
  m2 <- m2[order(m2$year, m2$month), ]
  x <- m2$co2; n <- length(x); g <- rep(NA_real_, n); i <- 7:(n - 6); g[i] <- x[i + 6] - x[i - 6]
  data.frame(k = m2$year * 12L + m2$month, g = g)
})
if (!identical(br_ref$k, mo$k) || !identical(br_ref$g, mo$g))
  stop("the product does not reproduce br_obs_growth() bit for bit")

monthly <- data.frame(year = as.integer(mo$year), month = as.integer(mo$month), k = as.integer(mo$k),
                      co2 = mo$co2, n = as.integer(mo$n), g = mo$g)
out <- list(
  monthly = monthly,
  provenance = list(
    source      = MGM_SRC,
    manifest    = MGM_KEY,
    sha256      = row$sha256,
    accessed    = row$accessed,
    citation    = row$citation,
    estimator   = paste("monthly means of the NOAA MBL global reference (V5, grouped by its year/month",
                        "columns), then the CENTRED 12-month difference co2[t+6] - co2[t-6], ppm/yr;",
                        "NA within six months of either end. = lib_block_reopt.R br_obs_growth(),",
                        "verified bit for bit at build"),
    used_by     = paste("R/likelihood.R ccx_iav_module_loglik() (objective #17's interannual module,",
                        "RULED 2026-10-06 n), detrended with ns(df = LIK_IAV_TREND_DF) over LIK_IAV_WIN"),
    samples     = "3-5 weekly samples per month (48/yr); column n; the last month may be partial",
    built       = as.character(Sys.Date()),
    units       = "ppm (co2), ppm/yr (g)"))

dir.create("data", showWarnings = FALSE)
saveRDS(out, MGM_OUT)
ok <- monthly[is.finite(monthly$g), ]
cat(sprintf("wrote %s: %d months %d-%02d to %d-%02d; g defined %d-%02d to %d-%02d (%d months)\n", MGM_OUT,
            nrow(monthly), monthly$year[1], monthly$month[1], monthly$year[nrow(monthly)], monthly$month[nrow(monthly)],
            ok$year[1], ok$month[1], ok$year[nrow(ok)], ok$month[nrow(ok)], nrow(ok)))
cat(sprintf("  samples per month: %s\n", paste(sprintf("%s:%d", names(table(monthly$n)), table(monthly$n)), collapse = "  ")))
cat(sprintf("  g mean %.3f, sd %.3f ppm/yr; br_obs_growth() parity: identical\n", mean(ok$g), stats::sd(ok$g)))
