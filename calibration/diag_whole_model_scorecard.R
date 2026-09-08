# =====================================================================
# diag_whole_model_scorecard.R -- THE MODEL AGAINST ITS GOALS, like-for-like at
# two arms (2026-09-08d; Marcus: "continue to judge the model overall in the
# context of the overall goals: seasonal cycle, hemispheric differences,
# isotopic variables, physical intuition; driven by CO2 emissions, ENSO,
# volcanic aerosol, global temperatures; a pedagogical tool").
#   arm A  `ent26`, the canonical column mode (26 par, structure OFF)
#   arm B  the round-3 HILDA winner (30 par, HS/HD boxes + HS pump, id 24)
# Every gate the 09-04 ledger keeps (V, H, 5, G, Q, 7, S), the ENSO ocean
# slope (full and solubility-only, the 09-04g estimator), the Joos IRF as a
# COMPARISON, the likelihood by stream GROUP, and the strained priors. Adopts
# nothing. Usage: Rscript calibration/diag_whole_model_scorecard.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R")); source(ccx_path("calibration", "lib_glodap_obs.R"))
SC_HILDA_DIR <- ccx_path("calibration", "output", "multistart_20260907f_hilda30"); SC_ARM <- "N"
SC_GROUPS <- list(co2_level = "^co2_level_|^co2_icecore", co2_seasonal = "^co2_seasonal_", d13c_level = "^d13c_level_", d13c_seasonal = "^d13c_seasonal_",
                  gradients = "gradient", bomb_d14c = "^d14c_(NH|SH)$", d14c_profile = "^d14c_profile_", excess_c14 = "excess", gcb_sinks = "^gcb_", ocean_deep = "^ocean_grad_|^hs_surf_")
SC_PRIOR_STRAIN <- 2; SC_ENSO_WIN <- c(1959, 2024)
SC_JOOS_HORIZON <- 300   # yr followed, as calibration/diag_joos_irf.R (JOOS_HORIZON lives there, not in R/joos_irf.R)
SC_OUT <- ccx_path("outputs", "diagnostics", "whole_model_scorecard_20260908.rds")
mk_v <- function(p, pmv, src) list(p = p, pm = pmv, luc_scale = pmv$luc_scale, bomb_total = pmv$bomb_total, sigma_d14c = pmv$sigma_d14c, rep_dC = pmv$rep_dC, grad_off_co2 = pmv$grad_off_co2, grad_off_d13c = pmv$grad_off_d13c, src = src)
vA <- dg_vector(CCX_MODE_CANONICAL); vA$p$hs_frac <- 0; vA$src <- paste("ent26", CCX_MODE_CANONICAL); zA <- vA$md$prior_z
fs <- list.files(SC_HILDA_DIR, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE); S <- lapply(fs, readRDS); best <- S[[which.max(vapply(S, `[[`, 0, "logpost"))]]
pB <- ccx_apply_structure(ccx_default_params(), "hilda"); pB$pump_mode <- SC_ARM; vB <- mk_v(ccx_overlay_par(pB, best$par_mode), best$par_mode, sprintf("hilda30 winner id %d", best$id)); zB <- best$prior_z
ARMS <- list(ent26 = vA, hilda30 = vB); obs <- ccx_prepare_obs()
cat(sprintf("ARMS: A = %s (h_ml %.1f, %d par)   B = %s (h_ml %.1f, u_hs %g, pump_hs %.1f, %d par)\n", vA$src, vA$p$h_ml, length(vA$pm), vB$src, vB$p$h_ml, vB$p$u_hs, vB$p$pump_hs_gcm2, length(vB$pm)))
R <- lapply(ARMS, dg_run); ST <- Map(dg_streams, R, ARMS)
try_or <- function(expr, lab) tryCatch(expr, error = function(e) { cat(sprintf("  ⚠ %s FAILED: %s\n", lab, conditionMessage(e))); NULL })

cat("\n=== 1. LIKELIHOOD BY STREAM GROUP (common rows; B's hs_surf rows shown separately) ===\n")
common <- intersect(names(ST$ent26), names(ST$hilda30))
cat(sprintf("  %-14s %10s %10s %8s   rows\n", "group", "ent26", "hilda30", "B - A"))
G <- lapply(SC_GROUPS, function(pat) { rows <- grep(pat, common, value = TRUE); c(A = sum(ST$ent26[rows]), B = sum(ST$hilda30[rows]), n = length(rows)) })
for (g in names(G)) cat(sprintf("  %-14s %10.2f %10.2f %+8.2f   %s\n", g, G[[g]]["A"], G[[g]]["B"], G[[g]]["B"] - G[[g]]["A"], paste(grep(SC_GROUPS[[g]], common, value = TRUE), collapse = " ")))
cat(sprintf("  %-14s %10.2f %10.2f %+8.2f\n", "TOTAL common", sum(ST$ent26[common]), sum(ST$hilda30[common]), sum(ST$hilda30[common]) - sum(ST$ent26[common])))
extra <- setdiff(names(ST$hilda30), common); if (length(extra)) cat(sprintf("  B-only rows: %s\n", paste(sprintf("%s %.2f", extra, ST$hilda30[extra]), collapse = ", ")))

cat("\n=== 2. GATES (09-04 ledger) ===\n")
verd <- list()
OV <- dg_gateV_obs(); for (a in names(ARMS)) { gv <- dg_gateV(R[[a]]); vd <- dg_gateV_verdict(gv, OV); verd[[a]]$V <- vd
  cat(sprintf("  GATE V  %-8s sd %.3f vs obs %.3f ± %.3f  ratio %.2f  z %+.2f  -> %s\n", a, vd$sd_model, OV$sd, OV$se, vd$ratio, vd$z, if (vd$pass) "PASS" else "FAIL (too smooth)")) }
OH <- dg_gateH_obs(obs); for (a in names(ARMS)) { vd <- dg_gateH_verdict(dg_gateH(ARMS[[a]], obs, OH), OH); verd[[a]]$H <- vd
  cat(sprintf("  GATE H  %-8s R_co2 %.3f (z_level %+.2f) R_d13c %.3f (z_level %+.2f)  contrast z %+.2f  -> %s\n", a, vd$R_co2, vd$z_level_co2, vd$R_d13c, vd$z_level_d13c, vd$z, if (vd$pass) "PASS" else "FAIL")) }
ob5 <- dg_obs_gate5(); sp5 <- dg_obs_gate5_spread(); for (a in names(ARMS)) { vd <- dg_gate5_verdict(dg_gate5(R[[a]]), ob5, sp5); verd[[a]]$G5 <- vd
  cat(sprintf("  GATE 5  %-8s z NH peak %+.2f, SH peak %+.2f, lag %+.2f; orderings %s/%s  -> %s\n", a, vd$z[["nh_t"]], vd$z[["sh_t"]], vd$z[["lag"]], if (vd$ord[["sh_after_nh"]]) "ok" else "VIOL", if (vd$ord[["nh_peak_higher"]]) "ok" else "VIOL", if (vd$pass) "PASS" else "FAIL")) }
for (a in names(ARMS)) { vd <- try_or({ gr <- ccx_ocean_grid(ARMS[[a]]$p$h_ml); og <- dg_gateG_obs(gr); dg_gateG_verdict(dg_gateG(ARMS[[a]], og), og) }, paste("gate G", a)); verd[[a]]$G <- vd
  if (!is.null(vd)) cat(sprintf("  GATE G  %-8s %s  -> %s\n", a, paste(sprintf("%s %s", names(vd)[vapply(vd, function(x) is.numeric(x) && length(x) == 1, TRUE)], sapply(vd[vapply(vd, function(x) is.numeric(x) && length(x) == 1, TRUE)], function(x) sprintf("%.3g", x))), collapse = ", "), if (isTRUE(vd$pass)) "PASS" else "FAIL")) }
for (a in names(ARMS)) { q <- dg_gateQ(R[[a]], ARMS[[a]]); verd[[a]]$Q <- q
  cat(sprintf("  GATE Q  %-8s air-sea d13C diseq NH %+.3f SH %+.3f mean %+.3f vs %.2f ± %.2f  n_sd %.2f  -> %s\n", a, q$by_hemi[["NH"]], q$by_hemi[["SH"]], q$mean, DG_Q_OBS, DG_Q_SD, q$n_sd, if (q$pass) "PASS" else "FAIL")) }
tg7 <- dg_gcb_target(DG_SINK_WIN); for (a in names(ARMS)) { g7 <- dg_gate7(R[[a]]); vd <- dg_gate7_verdict(g7, tg7); verd[[a]]$G7 <- vd
  cat(sprintf("  GATE 7  %-8s ocean %.2f (z %+.2f) land %.2f (z %+.2f) GtC/yr  -> %s\n", a, g7$ocean, vd$z_ocean, g7$land, vd$z_land, if (isTRUE(vd$pass)) "PASS" else "FAIL")) }
for (a in names(ARMS)) { vd <- try_or({ g <- dg_gateS(ARMS[[a]], obs); dg_gateS_verdict(g) }, paste("gate S", a)); verd[[a]]$S <- vd
  if (!is.null(vd)) cat(sprintf("  GATE S  %-8s SPO ocean limb %.3f ppm @ month %.2f, bracket [%.2f, %.2f]  -> %s\n", a, vd$amp, vd$mo, vd$lo, vd$hi, if (vd$pass) "PASS" else sprintf("FAIL (%+.2f mo)", vd$d_mo))) }

cat("\n=== 3. THE ENSO OCEAN RESPONSE (09-04g estimator: annual ocean uptake ~ year + Nino3.4) ===\n")
en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))); en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
g <- obs$gcb; mg <- merge(g[, c("year", "ocean_sink")], en_ann, by = "year"); mg <- mg[stats::complete.cases(mg) & mg$year >= SC_ENSO_WIN[1] & mg$year <= SC_ENSO_WIN[2], ]
fo <- stats::lm(ocean_sink ~ year + nino34_anom, data = mg); cat(sprintf("  GCB observed: slope %+.4f ± %.4f GtC/yr per index, r %+.3f (n %d)\n", coef(fo)[["nino34_anom"]], summary(fo)$coefficients["nino34_anom", 2], stats::cor(residuals(stats::lm(ocean_sink ~ year, mg)), mg$nino34_anom), nrow(mg)))
enso_slope <- function(r) { s <- dg_annual_sinks(r); d <- merge(data.frame(year = s$year, oc = s$ocean), en_ann, by = "year"); d <- d[d$year >= SC_ENSO_WIN[1] & d$year <= SC_ENSO_WIN[2], ]
  f <- stats::lm(oc ~ year + nino34_anom, data = d); c(slope = coef(f)[["nino34_anom"]], se = summary(f)$coefficients["nino34_anom", 2], r = stats::cor(residuals(stats::lm(oc ~ year, d)), d$nino34_anom)) }
ENSO <- list(); for (a in names(ARMS)) { full <- enso_slope(R[[a]]); v2 <- ARMS[[a]]; v2$p$gamma_enso_ocn_NH <- 0; v2$p$gamma_enso_ocn_SH <- 0; sol <- enso_slope(dg_run(v2)); ENSO[[a]] <- list(full = full, sol = sol)
  cat(sprintf("  %-8s full model slope %+.4f ± %.4f (r %+.3f) = %.2fx obs;  solubility-only %+.4f (r %+.3f)  [gamma_enso_ocn NH %+.3f SH %+.3f]\n", a, full["slope"], full["se"], full["r"], full["slope"] / coef(fo)[["nino34_anom"]], sol["slope"], sol["r"], ARMS[[a]]$p$gamma_enso_ocn_NH, ARMS[[a]]$p$gamma_enso_ocn_SH)) }

cat("\n=== 4. THE JOOS IRF (a COMPARISON since 09-04e, not a gate) ===\n")
irf_of <- function(v) { spin <- ccx_spinup(v$p)
  F_hist <- ccx_build_forcing("historical", c(1750, JOOS_REF_YEAR), prod_c14 = spin$prod_c14, bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  sp_ref <- spin; sp_ref$y <- ccx_run_fast(spin, F_hist)$state
  F_fwd <- suppressWarnings(ccx_build_forcing("historical", c(JOOS_REF_YEAR, JOOS_REF_YEAR + SC_JOOS_HORIZON + 10), prod_c14 = spin$prod_c14, bomb_total_kmol = 0, luc_scale = v$luc_scale))
  for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "enso", "c14_bomb", "c14_nuclear")) F_fwd[[cc]] <- 0
  F_fwd$gmst <- F_fwd$gmst[1]; F_hold <- ccx_hold_forcing(sp_ref, F_fwd, verbose = FALSE)
  o <- ccx_irf(sp_ref, F_hold); o$t <- o$t - (JOOS_PULSE_YR - JOOS_REF_YEAR); k <- o$t >= 0; at <- function(y) o$irf[k][which.min(abs(o$t[k] - y))]
  c(irf20 = at(20), irf100 = at(100), irf300 = at(300)) }
IRF <- list(); for (a in names(ARMS)) { x <- try_or(irf_of(ARMS[[a]]), paste("IRF", a)); IRF[[a]] <- x
  if (!is.null(x)) cat(sprintf("  %-8s IRF(20) %.3f  IRF(100) %.3f  IRF(300) %.3f   (Joos 2013 multi-model: %.3f / %.3f / %.3f)\n", a, x["irf20"], x["irf100"], x["irf300"], joos_irf(20), joos_irf(100), joos_irf(300))) }

cat(sprintf("\n=== 5. STRAINED PRIORS (|z| > %g) and the declared structure ===\n", SC_PRIOR_STRAIN))
for (a in names(ARMS)) { z <- if (a == "ent26") zA else zB; if (is.null(z)) { cat(sprintf("  %-8s (no prior_z stored)\n", a)); next }
  big <- names(z)[abs(z) > SC_PRIOR_STRAIN]; cat(sprintf("  %-8s %s\n", a, if (length(big)) paste(sprintf("%s %+.2f", big, z[big]), collapse = ", ") else "none")) }
cat(sprintf("  hilda30 declared: hs_frac %.2f, u_hs %g m/yr (= %.1f Sv over %.3g m2), tau_q %g yr, sst_hs %g C; fitted h_hs %.0f, pump_hs %.1f gC/m2/yr (prior-z %+.2f), hs_asx_frac %.2f\n",
            vB$p$hs_frac, vB$p$u_hs, vB$p$u_hs * (ccx_const("OCEAN_AREA_NH") + ccx_const("OCEAN_AREA_SH")) * vB$p$hs_frac / 3.156e13, (ccx_const("OCEAN_AREA_NH") + ccx_const("OCEAN_AREA_SH")) * vB$p$hs_frac, vB$p$tau_q, vB$p$sst_hs, vB$p$h_hs, vB$p$pump_hs_gcm2,
            (log(vB$p$pump_hs_gcm2) - log(readRDS(ccx_path("data", "obs_hs_export_prior.rds"))$centre_gcm2)) / readRDS(ccx_path("data", "obs_hs_export_prior.rds"))$log_sd, vB$p$hs_asx_frac))
saveRDS(list(streams = ST, groups = G, verdicts = verd, enso = ENSO, irf = IRF, prior_z = list(ent26 = zA, hilda30 = zB), arms = lapply(ARMS, `[[`, "src")), SC_OUT); cat(sprintf("\n  saved %s\n  ⛔ Nothing adopted.\n", SC_OUT))
