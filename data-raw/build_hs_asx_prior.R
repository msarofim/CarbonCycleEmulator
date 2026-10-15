# =====================================================================
# build_hs_asx_prior.R -- the OBSERVATION prior on `hs_asx_frac`, the cold box's
# air-sea exchange-area factor relative to the low-latitude box (2026-09-08e;
# round 5, Marcus: "design round 5").
#
# WHY. Round 4 freed u_hs under the observed overturning and the fit took it
# to 15 m/yr -- by rebuilding the modern sink in hs_asx_frac, 0.82 -> 1.83,
# nearly its box top and 2.8x the value MEASURED from ice x wind x Schmidt
# (data/obs_hs_exchange_factor.rds, 09-06d: 0.653). The factor had a uniform
# box and no prior, so it was the free compensator. Round 5 puts its own
# observation on it and asks where the sink goes next.
#
# CENTER: the product's headline `factor` (0.653; NOT re-typed). WIDTH: the
# product carries two SAMPLED spreads -- across time windows (1961-90 ...
# 1991-2020, log-sd ~0.04) and across hemispheres (NH 0.32 / SH 0.78, log-sd
# 0.44). The hemispheric spread is the REPRESENTATION error of one factor
# serving two hemispheres, not uncertainty in the global number, and at 0.44 the
# fit would keep 1.83 for 2.7 log-units -- the round would answer nothing. The
# shipped width is a JUDGMENT, HSA_LOGSD_JUDGEMENT = 0.15, ~2.5x the measured
# component spread (windows + the Schmidt-at-model-T alternative, in
# quadrature), stated here and in the prereg so it can be vetoed. Both
# alternatives are carried in the product for the record.
# Usage: Rscript data-raw/build_hs_asx_prior.R   -> data/obs_hs_asx_prior.rds
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
HSA_OBS <- readRDS(ccx_path("data", "obs_hs_exchange_factor.rds"))
HSA_LOGSD_JUDGEMENT <- 0.15
centre <- HSA_OBS$factor
win <- vapply(HSA_OBS$windows, function(w) w$res$global$factor, 0)
sd_windows <- stats::sd(log(win))
sd_schmidt <- abs(log(HSA_OBS$headline$global$sc_ratio_model_t / HSA_OBS$headline$global$sc_ratio))
sd_component <- sqrt(sd_windows^2 + sd_schmidt^2)
sd_hemis <- log(HSA_OBS$headline$SH$factor / HSA_OBS$headline$NH$factor) / 2
out <- list(centre = centre, log_sd = HSA_LOGSD_JUDGEMENT, log_sd_kind = "JUDGEMENT (2026-09-08e), ~2.5x the measured component spread",
            spreads = c(windows = sd_windows, schmidt_T = sd_schmidt, component = sd_component, hemispheric = sd_hemis),
            windows = win, hemis = c(NH = HSA_OBS$headline$NH$factor, SH = HSA_OBS$headline$SH$factor),
            z_of = c(round3 = (log(0.8175) - log(centre)) / HSA_LOGSD_JUDGEMENT, round4 = (log(1.835) - log(centre)) / HSA_LOGSD_JUDGEMENT, hilda_1 = (log(1) - log(centre)) / HSA_LOGSD_JUDGEMENT),
            q = stats::qlnorm(c(0.025, 0.16, 0.5, 0.84, 0.975), log(centre), HSA_LOGSD_JUDGEMENT),
            source = paste("data/obs_hs_exchange_factor.rds (Wanninkhof 2014 k ~ <U^2> Sc^-1/2 over open water; HadISST1 ice, NCEP R1 winds, ERSST v5 SST; built", HSA_OBS$built, ")"),
            built = format(Sys.time(), "%Y-%m-%d %H:%M"))
cat(sprintf("hs_asx_frac prior: centre %.3f (the measured factor); spreads: windows %.3f, Schmidt-T %.3f (component %.3f), hemispheric %.3f\n", centre, sd_windows, sd_schmidt, sd_component, sd_hemis))
cat(sprintf("  shipped log-sd %.2f (JUDGEMENT); 2.5/16/50/84/97.5 %%: %s\n  z: round 3's 0.818 %+.2f, round 4's 1.835 %+.2f, HILDA's 1 %+.2f\n", HSA_LOGSD_JUDGEMENT, paste(sprintf("%.3f", out$q), collapse = " / "), out$z_of[["round3"]], out$z_of[["round4"]], out$z_of[["hilda_1"]]))
saveRDS(out, ccx_path("data", "obs_hs_asx_prior.rds")); cat("saved data/obs_hs_asx_prior.rds\n")
