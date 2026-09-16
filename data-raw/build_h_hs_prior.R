# =====================================================================
# build_h_hs_prior.R -- the OBSERVATION prior for `h_hs`, the HILDA cold box's
# thickness, from the Holte 2017 Argo climatology product data/obs_mld.rds
# (2026-09-16 d, the hygiene batch; the 09-08d / 09-11 (3) ruling "h_hs must go
# under the HS Holte prior" was never built -- the table carried dunif[20, 500]
# and the canonical fitted 393 m, 3-4x the observed HS mixed layer).
#
# THE SAME CONSTRUCTION AS THE ORIGINAL h_ml PRIOR (build_h_ml_prior.R, before
# its 09-09w re-centring), for the same reason it had then: a TIME-CONSTANT
# thickness has two defensible observations -- the HS annual MEAN (115 m,
# poleward of 57.14 deg, both hemispheres, cos-lat weighted) and the HS annual
# MAXIMUM (268 m; the water ventilated at all) -- and the mechanism that would
# resolve the ambiguity (the HS box's own seasonal cycle, `seas_ml = 2`, option
# B) is BUILT BUT OFF at the canonical. So the prior encodes the ambiguity: a
# lognormal whose 16 % and 84 % points ARE the two readings -- median = their
# geometric mean, log-sd = half their log ratio. The box [20, 500] stays as the
# transform's support. When option B is adopted, re-centre on the MEAN as
# h_ml's was (09-09w) -- the same discharge, the same move.
# Usage: Rscript data-raw/build_h_hs_prior.R   -> data/obs_h_hs_prior.rds
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
HP_MLD <- readRDS(ccx_path("data", "obs_mld.rds"))
h_mean <- HP_MLD$hs$mean_dt$value; h_max <- HP_MLD$hs$max_dt$value
centre <- sqrt(h_mean * h_max); log_sd <- log(h_max / h_mean) / 2
out <- list(centre_m = centre, log_sd = log_sd,
            centre_basis = "geometric mean of the HS annual MEAN and annual MAX (the mean-vs-max ambiguity ENCODED; option B, the HS seasonal cycle, is off at the canonical)",
            width_basis = "half the log ratio of the two readings: the 16 % / 84 % points ARE the readings",
            readings_m = c(mean = h_mean, max = h_max),
            sd_cell_m = c(mean = HP_MLD$hs$mean_dt$sd_cell, max = HP_MLD$hs$max_dt$sd_cell),
            by_hemi_m = c(NH_mean = HP_MLD$seasonal_hs$NH$h_mean, NH_max = HP_MLD$seasonal_hs$NH$h_max,
                          SH_mean = HP_MLD$seasonal_hs$SH$h_mean, SH_max = HP_MLD$seasonal_hs$SH$h_max),
            z_of = function(h) (log(h) - log(centre)) / log_sd,
            z_hilda30c = (log(393.46) - log(centre)) / log_sd, z_hilda75 = (log(75) - log(centre)) / log_sd,
            q = stats::qlnorm(c(0.025, 0.16, 0.5, 0.84, 0.975), log(centre), log_sd),
            box = c(20, 500),
            source = paste("data/obs_mld.rds (Holte et al. 2017 GRL 44:5618, Argo_mixedlayers_monthlyclim_04142022.nc), HS poleward of",
                           sprintf("%.2f", HP_MLD$consts$lat_hs), "deg, both hemispheres, cos-lat weighted; density-threshold MLD (dt)"),
            built = format(Sys.time(), "%Y-%m-%d %H:%M"))
cat(sprintf("h_hs prior: readings mean %.1f / max %.1f m -> lognormal median %.1f m, log-sd %.3f; 2.5/16/50/84/97.5 %%: %s\n",
            h_mean, h_max, centre, log_sd, paste(sprintf("%.0f", out$q), collapse = " / ")))
cat(sprintf("  the canonical's 393.5 m sits at z %+.2f; HILDA's 75 m at z %+.2f\n", out$z_hilda30c, out$z_hilda75))
saveRDS(out, ccx_path("data", "obs_h_hs_prior.rds"))
cat("wrote data/obs_h_hs_prior.rds\n")
