# =====================================================================
# diag_rep_dc_ladder_futures.R -- does rep_dC move the FUTURE? Read off the
# CONVERGED 09-23 T1 ladder, not a fresh partial rebalance.
#
# WHY (Marcus 2026-09-29, "follow up on rep dC"). The audit-flag screen
# (CHANGELOG 09-29 e) pinned rep_dC at 0 / 1 sd with an 8-11-name Nelder-Mead
# rebalance and saw vvH 2300 move +159 / +121 ppm, beta_max 1.31 -> 0.6-0.7 --
# the phi signature. But that screen also found its futures RIDGE-SENSITIVE by
# tens of ppm (beta_max/fert_k cor 0.998), and the rebalance was partial.
# The T1 ladder (calibration/diag_rep_dc_product_ladder.R, 09-23) already holds
# rep_dC PINNED at 9 rungs with the other 28 names FULLY re-optimised (all
# conv 0, NM maxit 6000, replicates return to the canonical to 1.9e-3). It
# measured the historical products and never ran a future. This does.
#
# ⚠ At hilda29l (phi 0.5), the ladder's mode. The phi = 0 base Marcus chose on
# 09-29 needs its own ladder; this says whether that is worth building.
# ⛔ R2 (the PRIOR) is RULED (09-23, unchanged) -- this is not a prior question;
# it asks whether the shim carries the future.
#
# USAGE: Rscript calibration/diag_rep_dc_ladder_futures.R   (~10 min)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

RLF_DIR      <- ccx_path("outputs", "diagnostics", "rep_dc_product_ladder_20260923")
RLF_JOBS     <- c("job01_canonical", sprintf("job%02d_rung_%s", 5:12,
                  c("3.000", "2.500", "2.000", "1.500", "1.000", "0.776", "0.000", "-0.215")))
RLF_MODE     <- "hilda29l"
RLF_SCEN     <- c("vvH", "vvL", "ssp585")
RLF_SPLICE   <- c(vvH = TRUE, vvL = TRUE, ssp585 = FALSE)   # ssp585 as in 09-29 (b): unspliced
RLF_YEARS    <- c(2100L, 2300L)
RLF_END_YEAR <- 2300L
RLF_OUT      <- ccx_path("outputs", "diagnostics", sprintf("rep_dc_ladder_futures_%s", format(Sys.Date(), "%Y%m%d")))

md <- readRDS(ccx_mode_file(RLF_MODE))
hist_em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))[, c("year", "fossil_GtC", "luc_GtC")]
emis <- function(s) { if (!RLF_SPLICE[[s]]) return(NULL); e <- ccx_scenario_emissions(s)
  rbind(hist_em, e[e$year > max(hist_em$year), c("year", "fossil_GtC", "luc_GtC")]) }
run_u <- function(u) {
  m2 <- md; pr <- as.list(ccx_unc_to_par(u))
  for (n in names(pr)) m2$par_mode[[n]] <- pr[[n]]
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(m2))
  p <- ccx_overlay_par(ccx_mode_base(m2), pm); p$pump_mode <- md$pump_mode
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  out <- list()
  for (s in RLF_SCEN) {
    r <- suppressWarnings(ccx_run_coupled(sp, s, c(1750L, RLF_END_YEAR), emissions = emis(s),
                                          bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale))$out
    yr <- floor(r$t)
    co2 <- tapply((r$co2_NH + r$co2_SH) / 2, yr, mean); ld <- tapply(r$land_C, yr, mean)
    for (y in RLF_YEARS) {
      out[[paste0(s, "_co2_", y)]]  <- as.numeric(co2[as.character(y)])
      out[[paste0(s, "_land_", y)]] <- as.numeric(ld[as.character(y)])
    }
    out[[paste0(s, "_land_1750")]] <- as.numeric(ld[["1750"]])
  }
  c(unlist(out), beta_max = pr$beta_max, fert_k = pr$fert_k, q10 = pr$q10,
    hs_asx_frac = pr$hs_asx_frac, bomb_total = pr$bomb_total)
}

sink(paste0(RLF_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE ===\n  driver calibration/diag_rep_dc_ladder_futures.R, commit %s, run %s\n",
            tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?"),
            format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  vectors: %s (T1 ladder, mode %s, all 28 other names re-optimised)\n", RLF_DIR, RLF_MODE))
cat(sprintf("  scenarios %s; spliced %s; coupled, 1750-%d; ppm global mean, land GtC (model land_C)\n\n",
            paste(RLF_SCEN, collapse = ", "), paste(RLF_SPLICE, collapse = "/"), RLF_END_YEAR))
rows <- list()
for (j in RLF_JOBS) {
  x <- readRDS(file.path(RLF_DIR, paste0(j, ".rds")))
  stopifnot(identical(x$provenance$mode, RLF_MODE), x$conv == 0L, identical(names(x$u), md$param_names))
  v <- run_u(x$u)
  rows[[j]] <- data.frame(job = j, rep_dC = ccx_unc_to_par(x$u)$rep_dC,
                          d_logpost = x$opt_logpost - md$logpost, t(v), check.names = FALSE)
  cat(sprintf("  %-18s rep_dC %+6.3f  dlogpost %8.2f  beta_max %.3f fert_k %6.0f | vvH 2300 %6.1f ppm  ssp585 2300 %6.1f ppm, land x%.2f\n",
              j, rows[[j]]$rep_dC, rows[[j]]$d_logpost, v[["beta_max"]], v[["fert_k"]],
              v[["vvH_co2_2300"]], v[["ssp585_co2_2300"]], v[["ssp585_land_2300"]] / v[["ssp585_land_1750"]]))
}
R <- do.call(rbind, rows); rownames(R) <- NULL
# IDENTITY: the canonical row must reproduce the 09-29 (b) ssp585 hilda29l numbers (875 ppm, 2.27x)
cat(sprintf("\n  [identity] canonical ssp585 2300: %.1f ppm, land %.3fx PI (09-29 b: 875, 2.27x)\n",
            R$ssp585_co2_2300[1], R$ssp585_land_2300[1] / R$ssp585_land_1750[1]))
cat("\n=== FULL TABLE ===\n"); print(R, digits = 5, row.names = FALSE)
utils::write.csv(R, paste0(RLF_OUT, ".csv"), row.names = FALSE)
cat(sprintf("  saved %s.{log,csv}\n", RLF_OUT))
sink()
