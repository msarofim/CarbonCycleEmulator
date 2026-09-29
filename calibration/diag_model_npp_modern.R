# =====================================================================
# diag_model_npp_modern.R -- the model's OWN global NPP (GPP - Ra from the
# flux recorder), 1750 and modern, at the canonical and the phi = 0 mode.
# WHY (Marcus 2026-09-29, NPP_GLOBAL_PI option 4): the fit target for option 4
# is a MODERN observed NPP; first measure what the model now produces there,
# replacing the hand estimate (60 x 0.87 x 1.31 ~ 68) in R/constants.R.
# Compared against MOD17A3HGF C6.1 over the SAME years (data/obs_npp_hemispheric.rds).
# USAGE: Rscript calibration/diag_model_npp_modern.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
NM_ARMS <- c(hilda29l = "hilda29l",
  v0k = ccx_path("calibration", "output",
    "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
    "promoted_basin1", "mode_fit_pumpN.rds"))
NM_YEARS   <- c(1750, 2023)
NM_MOD_WIN <- c(2001, 2023)        # MOD17A3HGF C6.1 coverage (DATA.md 3c)
NM_OUT     <- ccx_path("outputs", "diagnostics", sprintf("model_npp_modern_%s", format(Sys.Date(), "%Y%m%d")))
obs <- readRDS(ccx_path("data", "obs_npp_hemispheric.rds"))
sink(paste0(NM_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE === driver calibration/diag_model_npp_modern.R, commit %s, run %s\n",
            system("git rev-parse --short HEAD", intern = TRUE), format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  NPP = gpp - ra channels of ccx_run(fluxes = TRUE), GtC/yr; historical forcing %d-%d; obs MOD17 %d-%d\n",
            NM_YEARS[1], NM_YEARS[2], NM_MOD_WIN[1], NM_MOD_WIN[2]))
cat("  obs object fields: ", paste(names(obs), collapse = ", "), "\n", sep = "")
res <- list()
for (a in names(NM_ARMS)) {
  md <- readRDS(ccx_mode_file(NM_ARMS[[a]]))
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(md))
  p  <- ccx_overlay_par(ccx_mode_base(md), pm); p$pump_mode <- md$pump_mode
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  F  <- ccx_build_forcing("historical", NM_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale,
                          enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
  fa <- ccx_flux_annual(suppressWarnings(ccx_run(sp, F, fluxes = TRUE))$fluxes)
  fa$npp <- fa$gpp - fa$ra
  k <- fa$year >= NM_MOD_WIN[1] & fa$year <= NM_MOD_WIN[2]
  res[[a]] <- c(npp_1750 = fa$npp[fa$year == 1750], npp_1850 = fa$npp[fa$year == 1850],
                npp_mod_win = mean(fa$npp[k]), gpp_mod_win = mean(fa$gpp[k]),
                npp0_const = ccx_const("NPP_GLOBAL_PI"))
  cat(sprintf("  %-8s NPP 1750 %.2f | 1850 %.2f | %d-%d mean %.2f (GPP %.1f) GtC/yr | constant %.0f\n", a,
              res[[a]][["npp_1750"]], res[[a]][["npp_1850"]], NM_MOD_WIN[1], NM_MOD_WIN[2],
              res[[a]][["npp_mod_win"]], res[[a]][["gpp_mod_win"]], res[[a]][["npp0_const"]]))
}
R <- data.frame(arm = names(res), do.call(rbind, res)); rownames(R) <- NULL
utils::write.csv(R, paste0(NM_OUT, ".csv"), row.names = FALSE)
cat(sprintf("  saved %s.{log,csv}\n", NM_OUT)); sink()
