# =====================================================================
# build_w_vent_prior.R -- THE LITERATURE PRIOR ON THE VENTILATION LOOP'S
# VOLUME FLUX `w_vent` (option E, 2026-09-14 h; prereg §5 "the w_vent prior's
# SOURCE owed" -- discharged here, from the paper text, not recalled).
#
# WHAT `w_vent` IS. The mixed layer subducts W_E into interior layers 1-3
# (65-292 m at the canonical grid: the permanent pycnocline below the
# annual-mean mixed layer) over the low-latitude column, and the same layers
# return the same volume. The observable is the ANNUAL SUBDUCTION RATE from
# the mixed layer into the permanent pycnocline, integrated over the global
# ocean OUTSIDE the equatorial band (the cell carries that) -- and it has two
# defensible readings a factor ~3 apart:
#   [LH12] Liu & Huang (2012), J. Climate 25:1096-1115, doi:10.1175/2011JCLI4228.1
#          (PDF: ~/Documents/2026/ClaudeDocs/Papers/Liu.Huang.2012.2011JCLI4228.1.pdf).
#          SODA 1959-2006, Lagrangian formula, year-by-year fields: global
#          subduction 505.8 Sv (Atlantic 157.4 / Pacific 225.7 / Indian 122.7;
#          NH 183.5 / SH 322.3, of which the Southern Ocean 177.4), obduction
#          482.1 Sv; the equatorial band 10S-10N obducts 87.1 Sv gross (net
#          gain 34.2). "errors associated with ... data assimilation could be
#          as large as 10%". THEIR OWN comparison (p. 1099): "the subduction
#          rate for the global oceans, excluding the equatorial band, is ~160 Sv
#          from the climatological datasets. It seems that our result is much
#          larger" -- and they attribute the gap to the NONLINEARITY of the
#          lateral-induction term that climatological-mean fields miss (their
#          climatological-mean SODA North Pacific gives 38.0 Sv against Qiu &
#          Huang's 35.2).
#   [CLIM] the climatological estimates LH12 cites: Qiu & Huang (1995) North
#          Pacific 35.2, North Atlantic 30.1; Karstensen & Quadfasel (2002)
#          South Atlantic 21, South Indian 35, South Pacific 44 (sum 165.3 --
#          the "~160" above); Huang & Qiu (1998) South Pacific 21.6; Qu et al.
#          (2008) South Pacific 48.8 from Argo/WOD05; Qu et al. (2002) North
#          Pacific 10-50N 61.6 from an eddy-permitting OGCM.
# CENTER: the GEOMETRIC MEAN of the two readings (the h_ml precedent, whose
# 16 %/84 % points WERE the two defensible readings); SPREAD: the log-sd that
# puts each reading at 1 sigma. ⚠ A WIDE prior BY DESIGN: the mapping from
# the real subduction/obduction field to a closed ML <-> layers-1-3 loop over
# one column is itself uncertain (observed obduction is concentrated in the
# equatorial band and the Southern Ocean, the loop's return is the STC's),
# and the prereg says the data rows -- bomb 14C, the deep d13C -- set it.
# ⚠ The ORDER matters more than the center: even at 160 Sv the loop replaces
# layers 1-3 at 0.07 /yr against the canonical kz's ~3 /yr -- kz is what must
# fall (PE-1).
# Usage: Rscript data-raw/build_w_vent_prior.R  (from the repo root)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
WVP_SODA_GLOBAL_SV  <- 505.8                     # LH12 Table 1, 1959-2006 mean
WVP_SODA_OBDUCT_SV  <- 482.1                     # LH12 Table 2
WVP_SODA_SO_SV      <- 177.4                     # LH12: the Southern Ocean's share of the 505.8
WVP_SODA_EQ_OBD_SV  <- 87.1                      # LH12: equatorial-band (10S-10N) obduction, gross
WVP_SODA_ERR_FRAC   <- 0.10                      # LH12 abstract: assimilation errors "as large as 10%"
WVP_CLIM_BASINS_SV  <- c(NP_QH95 = 35.2, NA_QH95 = 30.1, SA_KQ02 = 21, SI_KQ02 = 35, SP_KQ02 = 44)
WVP_CLIM_GLOBAL_SV  <- 160                       # LH12 p. 1099: "~160 Sv from the climatological datasets", excluding the equatorial band
WVP_CLIM_OTHER_SV   <- c(SP_HQ98 = 21.6, SP_Qu08_argo = 48.8, NP_Qu02_ogcm = 61.6)
readings <- c(clim = WVP_CLIM_GLOBAL_SV, soda = WVP_SODA_GLOBAL_SV)
centre <- exp(mean(log(readings)))
log_sd <- diff(log(readings)) / 2                # each reading at 1 sigma
prior <- list(
  centre_sv = centre, log_sd = unname(log_sd),
  q = stats::qlnorm(c(0.025, 0.16, 0.5, 0.84, 0.975), log(centre), log_sd),
  readings = readings,
  inputs = list(soda_global = WVP_SODA_GLOBAL_SV, soda_obduction = WVP_SODA_OBDUCT_SV, soda_so = WVP_SODA_SO_SV,
                soda_eq_obduction = WVP_SODA_EQ_OBD_SV, soda_err_frac = WVP_SODA_ERR_FRAC,
                clim_basins = WVP_CLIM_BASINS_SV, clim_other = WVP_CLIM_OTHER_SV),
  sources = c(LH12 = "Liu & Huang 2012 J. Climate 25:1096 doi:10.1175/2011JCLI4228.1 (SODA; the ~160 Sv climatological comparison on p. 1099)",
              QH95 = "Qiu & Huang 1995 (as cited by LH12): NP 35.2, NA 30.1 Sv",
              KQ02 = "Karstensen & Quadfasel 2002 (as cited by LH12): SA 21, SI 35, SP 44 Sv"),
  note = paste("Global annual subduction from the mixed layer into the permanent pycnocline, outside the equatorial band;",
               "two readings a factor 3.2 apart (climatological 160 vs SODA year-by-year 506); geometric-mean centre,",
               "each reading at 1 sigma. Mapping to a closed one-column loop is itself uncertain -- wide by design."),
  built = format(Sys.time(), "%Y-%m-%d %H:%M"))
cat(sprintf("w_vent prior: lognormal median %.0f Sv, log-sd %.3f (readings: climatological %.0f, SODA %.1f; basin sum of the cited climatologies %.1f)\n",
            centre, log_sd, readings[["clim"]], readings[["soda"]], sum(WVP_CLIM_BASINS_SV)))
cat(sprintf("  quantiles 2.5/16/50/84/97.5 %%: %s Sv\n", paste(sprintf("%.0f", prior$q), collapse = " / ")))
cat(sprintf("  for scale: the loop at the median replaces the ML (65 m) at %.2f /yr and layers 1-3 (227 m) at %.3f /yr over 3.03e14 m2, vs the canonical kz ~3 /yr\n",
            centre * CCX_SV_TO_M3YR / (3.03e14 * 65), centre * CCX_SV_TO_M3YR / (3.03e14 * 227)))
saveRDS(prior, ccx_path("data", "obs_w_vent_prior.rds")); cat("saved data/obs_w_vent_prior.rds\n")
