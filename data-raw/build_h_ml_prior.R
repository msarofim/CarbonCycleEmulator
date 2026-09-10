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
# was built, the prior ENCODED THE AMBIGUITY rather than resolving it: a
# lognormal whose 16 % and 84 % points ARE the two readings -- median = their
# geometric mean (83.94 m), log-sd = half their log ratio. The old uniform
# [30, 200] stays as the box (the transform's support); this prior replaces the
# flat density inside it.
#
# ⭐⭐ RE-CENTRED ON THE ANNUAL MEAN, 2026-09-09w (ruled by Marcus). ROUND 6
# BUILT THE SEASONAL MIXED LAYER, so the ambiguity this prior existed to encode
# is DISCHARGED: with `h_ml` modulated by the Holte MLD cycle, the constant is
# the annual MEAN and no longer has to stand in for the maximum as well.
# Keeping the geometric-mean centre after that would be a prior compensating for
# a mechanism the model now has.
#
# ⛔ AND IT WAS COSTING STARTS. P8's stopping condition is 76.146 m; under the
# old centre 61.3 % of the prior lay past it -- ITS MEDIAN 83.94 INCLUDED -- so
# roughly 3 multistart starts in 5 died at the guard. Re-centring drops that
# exposure to 23.8 %.
#
# ⚠⚠ THE WIDTH IS DELIBERATELY UNCHANGED, AND THAT IS A FLAGGED CHOICE, NOT A
# DERIVATION. `log_sd` is still half the log ratio of the two readings, i.e. a
# width that was built to SPAN an ambiguity now discharged. Re-deriving it (from
# `sd_cell_m`, the spatial spread across cells, say) would be a SECOND
# methodological move, and the 23.8 % exposure Marcus ruled on was computed at
# THIS width. Left standing, and named here so it is not mistaken for measured
# ([[tolerance_scaled_to_spread]] -- the open half of it).
# Usage: Rscript data-raw/build_h_ml_prior.R   -> data/obs_h_ml_prior.rds
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
HP_MLD <- readRDS(ccx_path("data", "obs_mld.rds"))
h_mean <- HP_MLD$ls$mean_dt$value; h_max <- HP_MLD$ls$max_dt$value
# CENTRE = the LS annual MEAN, read from the product (not the geometric mean of
# the two readings, which was the pre-09-09w ambiguity encoding, kept below for
# provenance). WIDTH unchanged -- see the flagged choice above.
centre <- h_mean; log_sd <- log(h_max / h_mean) / 2
centre_ambiguity <- sqrt(h_mean * h_max)   # the RETIRED centre, 83.94 m
out <- list(centre_m = centre, log_sd = log_sd,
            centre_basis = "LS annual MEAN (round 6 discharged the mean-vs-max ambiguity, 2026-09-09w)",
            centre_retired_m = centre_ambiguity,
            width_basis = "UNCHANGED: half the log ratio of the two readings, a width built to span an ambiguity now discharged. A FLAGGED CHOICE, not a derivation.",
            p8_stop_m = 76.146,
            p8_exposure = 1 - stats::plnorm(76.146, log(centre), log_sd),
            p8_exposure_retired = 1 - stats::plnorm(76.146, log(centre_ambiguity), log_sd),
            readings_m = c(mean = h_mean, max = h_max), sd_cell_m = c(mean = HP_MLD$ls$mean_dt$sd_cell, max = HP_MLD$ls$max_dt$sd_cell),
            z_of = function(h) (log(h) - log(centre)) / log_sd, z_hilda40 = (log(39.8) - log(centre)) / log_sd, z_ent26 = (log(134.15) - log(centre)) / log_sd,
            q = stats::qlnorm(c(0.025, 0.16, 0.5, 0.84, 0.975), log(centre), log_sd),
            source = paste("data/obs_mld.rds (Holte et al. 2017 GRL 44:5618, Argo_mixedlayers_monthlyclim_04142022.nc), LS |lat| <", sprintf("%.2f", HP_MLD$consts$lat_hs), "deg, 12-month cells, threshold MLD"),
            built = format(Sys.time(), "%Y-%m-%d %H:%M"))
cat(sprintf("h_ml prior: readings mean %.1f / max %.1f m -> lognormal median %.1f m, log-sd %.3f; 2.5/16/50/84/97.5 %%: %s\n", h_mean, h_max, centre, log_sd, paste(sprintf("%.1f", out$q), collapse = " / ")))
cat(sprintf("  the HILDA rounds' 39.8 m sits at z %+.2f; ent26's 134.15 at z %+.2f\n", out$z_hilda40, out$z_ent26))
cat(sprintf("  RE-CENTRED: %.2f m (was the geometric mean %.2f m). Exposure past P8's %.3f m stop: %.1f %% (was %.1f %%)\n",
            centre, centre_ambiguity, out$p8_stop_m, 100 * out$p8_exposure, 100 * out$p8_exposure_retired))
saveRDS(out[setdiff(names(out), "z_of")], ccx_path("data", "obs_h_ml_prior.rds")); cat("saved data/obs_h_ml_prior.rds\n")
