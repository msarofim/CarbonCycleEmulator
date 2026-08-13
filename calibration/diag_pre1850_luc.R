# =====================================================================
# diag_pre1850_luc.R -- what to do about the 100 years of land-use emissions
# GCB does not supply. HEADLINE: THE OLD FLAT-HOLD INVENTED 74.1 GtC, ZERO IS
# EXCLUDED BY THE ICE CORE, AND THE SOURCED SERIES FITS BEST.
#
# WRITTEN 2026-08-13 on Marcus' instruction ("look for an estimate for pre-1850
# LUC"), discharging recommendation R3 of
# notes/expertpanel_2026-08-13_structure_for_pedagogy.md.
#
# THE PROBLEM. GCB 2025's historical budget carries fossil emissions from 1750
# but its LUC column is EMPTY before 1850 -- verified in the raw CSV, not
# assumed. ccx_annual_to_monthly() strips NAs and then approx(rule = 2) holds
# the 1850 value (0.741 GtC/yr) flat backwards, which INVENTED 74.1 GtC across
# 1750-1849: 23 % of all the land-use carbon the model burns, chosen by nobody.
# GMST's identical flat-hold warns on every build (forcing.R) and d13c_foss's
# carries a justifying comment; this one was silent.
#
# THE CANDIDATES. OSCAR v3.1's E_luc (Gasser et al. 2020, doi:10.5194/bg-17-
# 4075-2020; data doi:10.5281/zenodo.7313542, CC-BY) runs from 1701. It gives
# 27.5 PgC over 1750-1849 against 178.9 over 1850-2018, reproducing that paper's
# headline 206 +/- 57 PgC for 1750-2018 EXACTLY -- which is the check that the
# right column was read, and it is why this file trusts the spreadsheet.
#
# But OSCAR's 1850-2018 total is 34 % BELOW GCB 2025's 239.8 GtC, because they
# are different products (GCB averages three bookkeeping models including BLUE;
# OSCAR is observationally constrained and low). Grafting OSCAR's ABSOLUTE
# values onto a GCB post-1850 series puts a 61 % step at the join. So the
# adopted option rescales OSCAR by the GCB/OSCAR level ratio over an 1850-1900
# overlap -- the window adjacent to the splice -- giving 41.8 GtC and a 6 % step.
#
# SCORED AGAINST THE LAW DOME ICE CORE, 1750-1850, at default parameters:
#
#     option              cum GtC   RMSE ppm   bias ppm
#     flat-hold (old)        74.1     2.48      +1.58
#     OSCAR absolute         27.5     2.77      -1.80
#     OSCAR scaled  <-- ADOPTED 41.8   2.00      -0.90
#     zero                    0.0     4.50      -3.53
#
# [1] ZERO IS EXCLUDED, and that is the cleanest result here. Pre-1850 land-use
#     emissions are NOT negligible and the ice core says so: 4.50 ppm RMSE and a
#     -3.53 ppm bias, against 2.00 for the sourced series.
# [2] THE ADOPTED OPTION HAS THE BEST RMSE AND IS THE ONLY ONE WITH A CITATION.
# [3] BUT THE FLAT-HOLD WAS NOT ABSURD, and saying so is the honest version. It
#     scores 2.48 -- second best -- because it is roughly the right INTEGRAL
#     spread over the wrong SHAPE. It is too big too early: at 1775 it overshoots
#     Law Dome by +3.83 ppm where the sourced series is +0.96, because 18th-
#     century clearing was a fraction of 1850's rate and a flat hold denies that.
# [4] AND THE FINDING THIS DOES *NOT* FIX, recorded so it is not mistaken for
#     one that does: EVERY option undershoots Law Dome by ~6.5 ppm at 1900, and
#     none reproduces the full 18th-century rise (Law Dome +8.44 ppm 1750->1850;
#     best option +5.10). There is a separate 19th-century deficit here, larger
#     than the entire pre-1850 LUC question, and it is untouched by this choice.
#     Do not read the RMSE column as "the forcing is now right".
#
# CAVEATS THAT BOUND ALL OF THE ABOVE. Default parameters, NOT the posterior
# mode. The ice core is IN the likelihood, so a refit would absorb part of any
# misfit -- these are forcing comparisons at fixed parameters, not calibrations.
# And the Law Dome spline is firn-smoothed, so only the centennial shape is
# meaningful, not year-to-year structure.
#
# CONSEQUENCE FOR THE CALIBRATION: this changes the historical forcing, so
# calibration/output/mode_fit.rds now PREDATES it. The mode is stale with
# respect to the emissions the model is driven with.
#
# RUNTIME ~15 s.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
suppressWarnings(suppressMessages(library(readxl)))

# ---- labels derive from constants (project rule) --------------------
PL_OVERLAP  <- 1850:1900        # must match data-raw/build_calibration_data.R [5a]
PL_WINDOW   <- c(1750, 1900)    # run window
PL_SCORE    <- 1750:1850        # window where the choice actually acts
PL_SCORE2   <- 1750:1900
PL_MARKS    <- c(1775, 1800, 1825, 1850, 1875, 1900)
PL_OSCAR    <- ccx_path("data-raw", "downloads", "oscar_gcb2020_eluc.xlsx")

oscar <- as.data.frame(read_excel(PL_OSCAR, sheet = "Global"))
emis  <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
spl   <- as.data.frame(readRDS(ccx_path("data", "obs_icecore.rds"))$co2_spline)

# The shipped series ALREADY carries the adopted option, so the alternatives are
# reconstructed from source here rather than read back from it.
pre_yrs  <- emis$year[emis$year < min(PL_OVERLAP)]
os_pre   <- oscar$E_luc[match(pre_yrs, oscar$year)]
os_scale <- sum(emis$luc_GtC[emis$year %in% PL_OVERLAP]) /
            sum(oscar$E_luc[oscar$year %in% PL_OVERLAP])
flat     <- rep(emis$luc_GtC[emis$year == min(PL_OVERLAP)], length(pre_yrs))

OPTIONS <- list(
  "flat-hold (old)" = flat,
  "OSCAR absolute"  = os_pre,
  "OSCAR scaled"    = os_pre * os_scale,
  "zero"            = rep(0, length(pre_yrs)))

cat(sprintf("\nOSCAR->GCB level ratio over %d-%d: %.3f\n",
            min(PL_OVERLAP), max(PL_OVERLAP), os_scale))
cat(sprintf("OSCAR E_luc: %.1f PgC (1750-1849), %.1f (1850-2018), %.1f total",
            sum(oscar$E_luc[oscar$year %in% 1750:1849]),
            sum(oscar$E_luc[oscar$year %in% 1850:2018]),
            sum(oscar$E_luc[oscar$year %in% 1750:2018])))
cat("  <-- reproduces Gasser et al. 2020's 206 +/- 57\n")

p <- ccx_default_params(); s <- ccx_spinup(p)
obs_at <- function(y) spl$co2_ppm[which.min(abs(spl$year - y))]

runs <- lapply(OPTIONS, function(v) {
  ee <- emis; ee$luc_GtC[ee$year < min(PL_OVERLAP)] <- v
  F  <- ccx_build_forcing("historical", PL_WINDOW, prod_c14 = s$prod_c14, emissions = ee)
  o  <- ccx_run_fast(s, F)$out
  a  <- stats::aggregate(co2 ~ year,
          data.frame(year = floor(o$t), co2 = (o$co2_NH + o$co2_SH) / 2), mean)
  list(cum = sum(v), ann = a)
})

score <- function(a, yrs) {
  d <- vapply(yrs, function(y) a$co2[a$year == y] - obs_at(y), numeric(1))
  c(rmse = sqrt(mean(d^2)), bias = mean(d))
}

cat(sprintf("\n=== SCORED AGAINST LAW DOME (Rubino et al. 2019 spline) ===\n"))
cat(sprintf("%-18s %9s | %8s %8s | %8s %8s\n", "option", "cum GtC",
            "RMSE", "bias", "RMSE", "bias"))
cat(sprintf("%-18s %9s | %17s | %17s\n", "", "1750-1849",
            sprintf("%d-%d", min(PL_SCORE), max(PL_SCORE)),
            sprintf("%d-%d", min(PL_SCORE2), max(PL_SCORE2))))
for (nm in names(runs)) {
  r <- runs[[nm]]; x <- score(r$ann, PL_SCORE); y <- score(r$ann, PL_SCORE2)
  cat(sprintf("%-18s %9.1f | %8.2f %+8.2f | %8.2f %+8.2f\n",
              nm, r$cum, x[1], x[2], y[1], y[2]))
}

cat("\n=== RESIDUALS AT MARKER YEARS (model - Law Dome, ppm) ===\n")
cat(sprintf("%-18s %s\n", "year", paste(sprintf("%8d", PL_MARKS), collapse = "")))
cat(sprintf("%-18s %s\n", "Law Dome ppm",
            paste(sprintf("%8.2f", vapply(PL_MARKS, obs_at, numeric(1))), collapse = "")))
for (nm in names(runs)) {
  a <- runs[[nm]]$ann
  cat(sprintf("%-18s %s\n", nm,
      paste(sprintf("%+8.2f",
        vapply(PL_MARKS, function(y) a$co2[a$year == y] - obs_at(y), numeric(1))),
        collapse = "")))
}
cat("  NOTE the LAST COLUMN: every option is ~6.5 ppm low at 1900. That is a\n")
cat("  SEPARATE 19th-century deficit, larger than this whole question, and the\n")
cat("  pre-1850 LUC choice does not touch it.\n")

cat("\n=== THE RISE LAW DOME ASKS FOR, vs what each option delivers ===\n")
rise <- function(a, y0, y1) a$co2[a$year == y1] - a$co2[a$year == y0]
cat(sprintf("  %-18s 1750->1800 %+6.2f   1750->1850 %+6.2f ppm\n", "LAW DOME",
            obs_at(1800) - obs_at(1750), obs_at(1850) - obs_at(1750)))
for (nm in names(runs))
  cat(sprintf("  %-18s 1750->1800 %+6.2f   1750->1850 %+6.2f\n", nm,
              rise(runs[[nm]]$ann, 1750, 1800), rise(runs[[nm]]$ann, 1750, 1850)))
cat("  NO option reproduces the full 18th-century rise. The flat-hold gets the\n")
cat("  1750->1800 rate closest and the 1775 LEVEL worst (+3.83 ppm): it is\n")
cat("  roughly the right integral spread over the wrong shape.\n")

cat("\n=== WHAT IS SHIPPED ===\n")
adopted <- sum(emis$luc_GtC[emis$year < min(PL_OVERLAP)])
cat(sprintf("  data/forcing_emissions_historical.rds carries %.1f GtC for 1750-1849\n", adopted))
cat(sprintf("  splice continuity: %.3f GtC/yr at 1849 -> %.3f at 1850 (%.0f %% step;\n",
            emis$luc_GtC[emis$year == 1849], emis$luc_GtC[emis$year == 1850],
            100 * (emis$luc_GtC[emis$year == 1850] / emis$luc_GtC[emis$year == 1849] - 1)))
cat(sprintf("  raw OSCAR would give %.3f -> %.3f, a %.0f %% step)\n",
            os_pre[length(os_pre)], emis$luc_GtC[emis$year == 1850],
            100 * (emis$luc_GtC[emis$year == 1850] / os_pre[length(os_pre)] - 1)))
if (abs(adopted - runs[["OSCAR scaled"]]$cum) > 0.05)
  cat("  *** WARNING: shipped total does not match the 'OSCAR scaled' option here.\n")
cat("  calibration/output/mode_fit.rds PREDATES this forcing change and is stale.\n")
