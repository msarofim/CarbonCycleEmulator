#!/usr/bin/env Rscript
# diag_app_ssp585_ref.R -- an INDEPENDENT reference for diag_h2_futures_stake.R's gate G1b (2026-10-08 j).
# Usage: Rscript calibration/diag_app_ssp585_ref.R   (~1.5 min; writes outputs/diagnostics/app_ssp585_ref_<date>_<canonical>.log)
# The app's OWN parameter + spin-up construction (app_params(), app_spinup(), APP_BOMB_TOTAL, APP_LUC_SCALE), ssp585
# UNSPLICED (as diag_h2_futures_stake.R's gate arm), CO2 in 2300: an independent reference for that driver's G1b.
ROOT <- normalizePath(getwd()); setwd(file.path(ROOT, "app"))
invisible(capture.output(suppressMessages(suppressWarnings(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv())))))
setwd(ROOT)
rr <- suppressWarnings(ccx_run_coupled(APP_SPIN, "ssp585", c(1750L, 2300L),
                                       bomb_total_kmol = APP_BOMB_TOTAL, luc_scale = APP_LUC_SCALE))
co2 <- tapply((rr$out$co2_NH + rr$out$co2_SH) / 2, floor(rr$out$t), mean)
LINE <- sprintf("canonical %s | mode md5 %s | commit %s | app path, ssp585 unspliced: CO2 2300 = %.4f ppm (2100 %.4f)\n",
            CCX_MODE_CANONICAL, unname(tools::md5sum(ccx_mode_file())), ccx_git_stamp(), co2[["2300"]], co2[["2100"]])
cat(LINE)
OUT <- file.path("outputs", "diagnostics", sprintf("app_ssp585_ref_%s_%s.log", format(Sys.Date(), "%Y%m%d"), CCX_MODE_CANONICAL))
writeLines(c("calibration/diag_app_ssp585_ref.R", LINE), OUT)
