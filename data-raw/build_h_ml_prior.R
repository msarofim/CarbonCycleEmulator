# =====================================================================
# build_h_ml_prior.R -- the OBSERVATION prior for `h_ml`, the low-latitude
# mixed-layer thickness, from the Holte 2017 Argo climatology product
# data/obs_mld.rds (2026-09-08d; Marcus: "either free h_ml or explore
# pinning it to a seasonal shape so that it can capture both the annual mean
# and the annual max").
#
# A time-constant thickness has TWO defensible observations -- the LS annual
# MEAN (59.7 m) and the LS annual MAXIMUM (118 m; the water ventilated at all)
# -- and the choice between them is the very thing a seasonal mixed layer
# would resolve (options_2026-09-08d_seasonal_h_ml.md, option B). Until that
# is built, the prior ENCODES THE AMBIGUITY rather than resolving it: a
# lognormal whose 16 % and 84 % points ARE the two readings -- median = their
# geometric mean, log-sd = half their log ratio. Both DERIVED from the product,
# not typed. The old uniform [30, 200] stays as the box (the transform's
# support); this prior replaces the flat density inside it.
# Usage: Rscript data-raw/build_h_ml_prior.R   -> data/obs_h_ml_prior.rds
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
HP_MLD <- readRDS(ccx_path("data", "obs_mld.rds"))
h_mean <- HP_MLD$ls$mean_dt$value; h_max <- HP_MLD$ls$max_dt$value
centre <- sqrt(h_mean * h_max); log_sd <- log(h_max / h_mean) / 2
out <- list(centre_m = centre, log_sd = log_sd, readings_m = c(mean = h_mean, max = h_max), sd_cell_m = c(mean = HP_MLD$ls$mean_dt$sd_cell, max = HP_MLD$ls$max_dt$sd_cell),
            z_of = function(h) (log(h) - log(centre)) / log_sd, z_hilda40 = (log(39.8) - log(centre)) / log_sd, z_ent26 = (log(134.15) - log(centre)) / log_sd,
            q = stats::qlnorm(c(0.025, 0.16, 0.5, 0.84, 0.975), log(centre), log_sd),
            source = paste("data/obs_mld.rds (Holte et al. 2017 GRL 44:5618, Argo_mixedlayers_monthlyclim_04142022.nc), LS |lat| <", sprintf("%.2f", HP_MLD$consts$lat_hs), "deg, 12-month cells, threshold MLD"),
            built = format(Sys.time(), "%Y-%m-%d %H:%M"))
cat(sprintf("h_ml prior: readings mean %.1f / max %.1f m -> lognormal median %.1f m, log-sd %.3f; 2.5/16/50/84/97.5 %%: %s\n", h_mean, h_max, centre, log_sd, paste(sprintf("%.1f", out$q), collapse = " / ")))
cat(sprintf("  the HILDA rounds' 39.8 m sits at z %+.2f; ent26's 134.15 at z %+.2f\n", out$z_hilda40, out$z_ent26))
saveRDS(out[setdiff(names(out), "z_of")], ccx_path("data", "obs_h_ml_prior.rds")); cat("saved data/obs_h_ml_prior.rds\n")
