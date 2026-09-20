# =====================================================================
# diag_whole_model_scorecard.R -- THE MODEL AGAINST ITS GOALS, like-for-like at
# three arms (2026-09-08d; re-pointed 2026-09-12 for the `hilda31s` evaluation;
# Marcus: "continue to judge the model overall in the context of the overall
# goals: seasonal cycle, hemispheric differences, isotopic variables, physical
# intuition; driven by CO2 emissions, ENSO, volcanic aerosol, global
# temperatures; a pedagogical tool").
#   arm A  `ent26`, the column control (26 par, structure OFF; by PATH,
#          CCX_MODE_COLUMN_CONTROL; aseasonal spinup, as fitted)
#   arm B  the registered seas_ml = 0 control, CCX_MODE_SEASML0_CONTROL
#          (`hilda31p` on 09-12; periodic spinup, as fitted)
#   arm C  the canonical, CCX_MODE_CANONICAL (`hilda31s`; seas_ml 1)
# ⚠ EVERY ARM IS SPUN UP THE WAY ITS FILE SAYS IT WAS FITTED (dg_spinup(), the
# file's `spinup` label). The 09-08 version called ccx_spinup() everywhere; at a
# periodic-fitted seas_ml = 1 mode that reads 2447 log-units off the mode.
# Section 0 PROVES each arm reproduces its own stored streams before anything
# is read off it ([[like_for_like_forcing]]).
# ⚠ ONE RUN PER ARM (2026-09-12, review B5): R[[a]] is handed to dg_streams,
# dg_gateH, dg_gateS (base arm) and dg_gateG (spinup + surface reads) through
# their `r =` argument; only the knockout arms (gate S, the ENSO patch-off) and
# gate G's end-of-epoch state still run. Logs diffed bit-identical at the change.
# Every gate the ledger keeps (V, H, 5, G, Q, 7, S, GL, P7), the two
# COMPARISONS (12 = the Joos IRF, L = the pulse partition), the ENSO ocean slope
# (full and solubility-only, the 09-04g estimator), the likelihood by stream
# GROUP, and the strained priors. Adopts nothing.
# Usage: Rscript calibration/diag_whole_model_scorecard.R | tee outputs/diagnostics/whole_model_scorecard_<date>.log
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R")); source(ccx_path("calibration", "lib_glodap_obs.R"))
SC_ARM_A <- CCX_MODE_COLUMN_CONTROL; SC_ARM_B <- CCX_MODE_SEASML0_CONTROL; SC_ARM_C <- CCX_MODE_CANONICAL
SC_ARM_A_NAME <- "ent26"
SC_GROUPS <- list(co2_level = "^co2_level_|^co2_icecore", co2_seasonal = "^co2_seasonal_", d13c_level = "^d13c_level_", d13c_seasonal = "^d13c_seasonal_",
                  gradients = "gradient", bomb_d14c = "^d14c_(NH|SH)$", d14c_profile = "^d14c_profile_", excess_c14 = "excess", gcb_sinks = "^gcb_", ocean_deep = "^ocean_grad_", hs_surface = "^hs_surf_")
SC_PRIOR_STRAIN <- 2; SC_ENSO_WIN <- c(1959, 2024)
SC_JOOS_HORIZON <- 300   # yr followed, as calibration/diag_joos_irf.R (JOOS_HORIZON lives there, not in R/joos_irf.R)
SC_L_HORIZONS <- c(100, 1000)   # the pulse partition read at both: the 09-08f table (100) and Joos 2013's own horizon (DG_L_HORIZON)
SC_REPRO_TOL <- 1e-3    # log-units: an arm must reproduce its file's stored streams to this before it is read
# DATE + CANONICAL (2026-09-13 (d)): two scorecards on one day at two canonicals
# (hilda31s2 in the morning, hilda30c after the repoint) collided on a date-only
# tag and the second silently overwrote the first's .rds (restored from git).
SC_TAG <- sprintf("%s_%s", format(Sys.Date(), "%Y%m%d"), CCX_MODE_CANONICAL)
SC_OUT <- ccx_path("outputs", "diagnostics", sprintf("whole_model_scorecard_%s.rds", SC_TAG))
vA <- dg_vector(SC_ARM_A); vA$src <- sprintf("%s (column control, quarantined)", SC_ARM_A_NAME)
vB <- dg_vector(SC_ARM_B); vB$src <- sprintf("%s (seas_ml 0 control, CCX_MODE_SEASML0_CONTROL)", SC_ARM_B)
vC <- dg_vector(SC_ARM_C); vC$src <- sprintf("%s (canonical, CCX_MODE_CANONICAL)", SC_ARM_C)
ARMS <- list(vA, vB, vC); names(ARMS) <- c(SC_ARM_A_NAME, SC_ARM_B, SC_ARM_C)
# Optional fourth arm: the best start of another multistart directory, CCX_SC_EXTRA_DIR=<path>.
# A start file records no spinup label; it is scored under CCX_OBJECTIVE_SPINUP and SAYS so.
SC_EXTRA <- Sys.getenv("CCX_SC_EXTRA_DIR", "")
if (nzchar(SC_EXTRA)) { fsC <- list.files(SC_EXTRA, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE); SC <- lapply(fsC, readRDS); bC <- SC[[which.max(vapply(SC, `[[`, 0, "logpost"))]]
  pmC <- ccx_migrate_par_set(ccx_mode_par_with_pins(bC)); pC <- ccx_mode_base(bC); pC$pump_mode <- bC$pump_mode   # a start file records `pins` too (09-13)
  ARMS[[basename(SC_EXTRA)]] <- list(p = ccx_overlay_par(pC, pmC), pm = pmC, luc_scale = pmC$luc_scale, bomb_total = pmC$bomb_total, sigma_d14c = pmC$sigma_d14c, rep_dC = pmC$rep_dC, grad_off_co2 = pmC$grad_off_co2, grad_off_d13c = pmC$grad_off_d13c,
                                    spinup = CCX_OBJECTIVE_SPINUP, spinup_label = ccx_spinup_label(CCX_OBJECTIVE_SPINUP), md = bC, pins = bC$pins, src = sprintf("%s best id %d (start file; spinup = objective's%s)", basename(SC_EXTRA), bC$id, if (length(bC$pins)) paste0("; PINNED ", ccx_pin_label(bC$pins)) else "")) }
obs <- ccx_prepare_obs()
arm_struct <- function(v) { s <- ccx_mode_struct(v$md); if (!nzchar(s)) "column" else s }
cat("ARMS (each spun up as its file records):\n")
for (a in names(ARMS)) { v <- ARMS[[a]]
  cat(sprintf("  %-8s %s   struct %s, seas_ml %d, spinup %s, %d par%s, h_ml %.1f%s\n", a, v$src, arm_struct(v), ccx_mode_seas_ml(v$md), v$spinup_label, length(v$pm) - length(v$pins),
              if (length(v$pins)) sprintf(" + %d PINNED (%s)", length(v$pins), paste(sprintf("%s=%g", names(v$pins), v$pins), collapse = ",")) else "", v$p$h_ml,
              if (arm_struct(v) == "hilda") sprintf(", u_hs %.1f, hs_asx %.3f, h_hs %.0f, pump_hs %.1f, k_w %.0f", v$p$u_hs, v$p$hs_asx_frac, v$p$h_hs, v$p$pump_hs_gcm2, v$p$k_w) else "")) }
R <- lapply(ARMS, dg_run); ST <- Map(dg_streams, R, ARMS, MoreArgs = list(obs = obs)); GR <- lapply(R, function(r) ccx_ocean_grad_scored(r$out, r$sp))
try_or <- function(expr, lab) tryCatch(expr, error = function(e) { cat(sprintf("  ⚠ %s FAILED: %s\n", lab, conditionMessage(e))); NULL })

cat(sprintf("\n=== 0. EACH ARM REPRODUCES ITS OWN STORED STREAMS (tol %g; the like-for-like guard) ===\n", SC_REPRO_TOL))
REPRO <- list()
for (a in names(ARMS)) { st <- ARMS[[a]]$md$streams
  if (is.null(st)) { cat(sprintf("  %-8s no stored streams in the file\n", a)); next }
  cm <- intersect(names(st), names(ST[[a]])); d <- sum(ST[[a]][cm]) - sum(unlist(st[cm])); REPRO[[a]] <- c(stored = sum(unlist(st[cm])), now = sum(ST[[a]][cm]), diff = d, n = length(cm))
  cat(sprintf("  %-8s stored %.4f  recomputed %.4f  diff %+.2e over %d rows  -> %s\n", a, sum(unlist(st[cm])), sum(ST[[a]][cm]), d, length(cm),
              if (abs(d) <= SC_REPRO_TOL) "REPRODUCES" else if (length(ARMS[[a]]$migrated)) "MIGRATED file: its stored streams are PROVENANCE (restamp_mode_objective.R cannot encode a pre-migration vector); not gated" else "⚠ DOES NOT REPRODUCE (objective moved since the file was stamped, or the wrong spinup)"))
  dropped <- c(setdiff(names(st), cm), setdiff(names(ST[[a]]), cm)); if (length(dropped)) cat(sprintf("           rows not in both (excluded from the sum): %s\n", paste(dropped, collapse = " "))) }

cat("\n=== 1. LIKELIHOOD BY STREAM GROUP (common rows; rows absent from an arm shown after) ===\n")
common <- Reduce(intersect, lapply(ST, names)); an <- names(ARMS)
cat(sprintf("  %-14s %s %9s %9s   rows\n", "group", paste(sprintf("%10s", substr(an, 1, 10)), collapse = ""), "B-A", "C-B"))
G <- lapply(SC_GROUPS, function(pat) { rows <- grep(pat, common, value = TRUE); c(vapply(ST, function(s) sum(s[rows]), numeric(1)), n = length(rows)) })
for (g in names(G)) { x <- G[[g]]; if (x[["n"]] == 0) next
  cat(sprintf("  %-14s %s %+9.2f %+9.2f   %s\n", g, paste(sprintf("%10.2f", x[an]), collapse = ""), x[[an[2]]] - x[[an[1]]], x[[an[3]]] - x[[an[2]]], paste(grep(SC_GROUPS[[g]], common, value = TRUE), collapse = " "))) }
tot <- vapply(ST, function(s) sum(s[common]), numeric(1))
cat(sprintf("  %-14s %s %+9.2f %+9.2f\n", "TOTAL common", paste(sprintf("%10.2f", tot), collapse = ""), tot[[2]] - tot[[1]], tot[[3]] - tot[[2]]))
for (a in an) { extra <- setdiff(names(ST[[a]]), common); if (length(extra)) cat(sprintf("  %s-only rows: %s\n", a, paste(sprintf("%s %.2f", extra, ST[[a]][extra]), collapse = ", "))) }
ncommon <- setdiff(Reduce(union, lapply(ST, names)), common)
if (length(ncommon)) cat(sprintf("  rows not common to every arm: %s  (TOTAL incl. them: %s)\n", paste(ncommon, collapse = " "), paste(sprintf("%s %.2f", an, vapply(ST, sum, numeric(1))), collapse = ", ")))

cat("\n=== 2. GATES (the ledger, INDEX_ccx_gates) ===\n")
verd <- list()
OV <- dg_gateV_obs(); for (a in an) { gv <- dg_gateV(R[[a]]); vd <- dg_gateV_verdict(gv, OV); verd[[a]]$V <- vd
  cat(sprintf("  GATE V  %-8s sd %.3f vs obs %.3f ± %.3f  ratio %.2f  z %+.2f  -> %s\n", a, vd$sd_model, OV$sd, OV$se, vd$ratio, vd$z, if (vd$pass) "PASS" else "FAIL (too smooth)")) }
OH <- dg_gateH_obs(obs); GH <- list(); for (a in an) { gh <- dg_gateH(ARMS[[a]], obs, OH, r = R[[a]]); GH[[a]] <- gh; vd <- dg_gateH_verdict(gh, OH); verd[[a]]$H <- vd
  cat(sprintf("  GATE H  %-8s R_co2 %.3f (z_level %+.2f) R_d13c %.3f (z_level %+.2f)  contrast z %+.2f  -> %s\n", a, vd$R_co2, vd$z_level_co2, vd$R_d13c, vd$z_level_d13c, vd$z, if (vd$pass) "PASS" else "FAIL")) }
for (a in an) { vd <- dg_gateGL_verdict(GH[[a]], OH); verd[[a]]$GL <- vd
  cat(sprintf("  GATE GL %-8s d13C gradient %.4f vs obs %.4f ± %.4f (ratio %.2f); rep_frac %.3f (derived from R_co2 %.3f) -> se %.4f, z %+.2f (bare z %+.2f)  -> %s\n", a, vd$model, vd$obs, vd$se_obs, vd$ratio, vd$rep_frac, vd$R_co2, vd$se, vd$z, vd$z_bare, if (vd$pass) "PASS" else "FAIL")) }
ob5 <- dg_obs_gate5(); sp5 <- dg_obs_gate5_spread(); for (a in an) { vd <- dg_gate5_verdict(dg_gate5(R[[a]]), ob5, sp5); verd[[a]]$G5 <- vd
  num <- vapply(vd$z, function(x) is.finite(x), TRUE)
  cat(sprintf("  GATE 5  %-8s %s; orderings %s  -> %s\n", a, paste(sprintf("%s z %+.2f", names(vd$z)[num], vd$z[num]), collapse = ", "), paste(sprintf("%s %s", names(vd$ord), ifelse(unlist(vd$ord), "ok", "VIOL")), collapse = " "), if (vd$pass) "PASS" else "FAIL")) }
for (a in an) { vd <- try_or({ gr <- ccx_ocean_grid(ARMS[[a]]$p$h_ml); og <- dg_gateG_obs(gr); dg_gateG_verdict(dg_gateG(ARMS[[a]], og, r = R[[a]]), og) }, paste("gate G", a)); verd[[a]]$G <- vd
  if (!is.null(vd)) cat(sprintf("  GATE G  %-8s %s  -> %s\n", a, paste(sprintf("%s %s", names(vd)[vapply(vd, function(x) is.numeric(x) && length(x) == 1, TRUE)], sapply(vd[vapply(vd, function(x) is.numeric(x) && length(x) == 1, TRUE)], function(x) sprintf("%.3g", x))), collapse = ", "), if (isTRUE(vd$pass)) "PASS" else "FAIL")) }
for (a in an) { q <- dg_gateQ(R[[a]], ARMS[[a]]); verd[[a]]$Q <- q
  cat(sprintf("  GATE Q  %-8s air-sea d13C diseq NH %+.3f SH %+.3f mean %+.3f vs %.2f ± %.2f  n_sd %.2f  -> %s\n", a, q$by_hemi[["NH"]], q$by_hemi[["SH"]], q$mean, DG_Q_OBS, DG_Q_SD, q$n_sd, if (q$pass) "PASS" else "FAIL")) }
DO <- try_or(dg_gateD_obs(), "gate D obs"); if (!is.null(DO)) for (a in an) { vd <- try_or(dg_gateD_verdict(dg_gateD(R[[a]], ARMS[[a]], DO), DO), paste("gate D", a)); verd[[a]]$D <- vd   # 2026-09-20 t
  if (!is.null(vd)) cat(sprintf("  GATE D  %-8s hemispheric diseq NH %+.3f SH %+.3f (ml/hs NH %+.2f/%+.2f SH %+.2f/%+.2f; obs %+.2f/%+.2f %+.2f/%+.2f) asym %+.3f vs obs %+.3f ± %.3f  z %+.2f  -> %s\n", a, vd$hemi[["NH"]], vd$hemi[["SH"]], vd$region[["NH_ml"]], vd$region[["NH_hs"]], vd$region[["SH_ml"]], vd$region[["SH_hs"]], vd$obs_region[["NH_ml"]], vd$obs_region[["NH_hs"]], vd$obs_region[["SH_ml"]], vd$obs_region[["SH_hs"]], vd$asym, vd$obs_asym, vd$se, vd$z, if (vd$pass) "PASS" else "FAIL")) }
tg7 <- dg_gcb_target(DG_SINK_WIN); for (a in an) { g7 <- dg_gate7(R[[a]]); vd <- dg_gate7_verdict(g7, tg7); verd[[a]]$G7 <- vd
  cat(sprintf("  GATE 7  %-8s ocean %.2f (z %+.2f) land %.2f (z %+.2f) GtC/yr  -> %s\n", a, g7$ocean, vd$z_ocean, g7$land, vd$z_land, if (isTRUE(vd$pass)) "PASS" else "FAIL")) }
for (a in an) { vd <- try_or({ g <- dg_gateS(ARMS[[a]], obs, r = R[[a]]); dg_gateS_verdict(g) }, paste("gate S", a)); verd[[a]]$S <- vd
  if (!is.null(vd)) cat(sprintf("  GATE S  %-8s SPO ocean limb %.3f ppm @ month %.2f, bracket [%.2f, %.2f]  -> %s\n", a, vd$amp, vd$mo, vd$lo, vd$hi, if (vd$pass) "PASS" else sprintf("FAIL (%+.2f mo)", vd$d_mo))) }
# GATE P7: the seasonal mixed layer (ON = arm C) must not be a vertical-gradient lever against its OFF control (arm B).
tgP <- ccx_ocean_gradient_target()
P7 <- dg_gateP7_verdict(GR[[SC_ARM_B]], GR[[SC_ARM_C]]); verd[[SC_ARM_C]]$P7 <- P7
cat(sprintf("  GATE P7 %-8s modern surface-deep d13C gradient OFF (%s) %.3f -> ON (%s) %.3f: move %+.3f vs bound (OFF sd_eff) %.3f = %.2fx, target %.3f; DIC %.1f -> %.1f (%+.1f, %.2fx its sd_eff %.1f; reported)  -> %s\n",
            SC_ARM_C, SC_ARM_B, P7$d13c_off, SC_ARM_C, P7$d13c_on, P7$move_d13c, P7$sd_eff_d13c, P7$ratio_d13c, tgP$d13c$target, P7$dic_off, P7$dic_on, P7$move_dic, P7$ratio_dic, P7$sd_eff_dic, if (P7$pass) "PASS" else "FAIL"))
for (a in an) cat(sprintf("  (gradient rows) %-8s d13C %.3f (target %.3f, sd_eff %.3f)  DIC %.1f (target %.1f, sd_eff %.1f)  ALK %.1f\n", a, GR[[a]]$d13c, tgP$d13c$target, GR[[a]]$sd_eff[["d13c"]], GR[[a]]$dic, tgP$dic$target, GR[[a]]$sd_eff[["dic"]], GR[[a]]$alk))

cat("\n=== 3. THE ENSO OCEAN RESPONSE (09-04g estimator: annual ocean uptake ~ year + Nino3.4) ===\n")
en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))); en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
g <- obs$gcb; mg <- merge(g[, c("year", "ocean_sink")], en_ann, by = "year"); mg <- mg[stats::complete.cases(mg) & mg$year >= SC_ENSO_WIN[1] & mg$year <= SC_ENSO_WIN[2], ]
fo <- stats::lm(ocean_sink ~ year + nino34_anom, data = mg); cat(sprintf("  GCB observed: slope %+.4f ± %.4f GtC/yr per index, r %+.3f (n %d)\n", coef(fo)[["nino34_anom"]], summary(fo)$coefficients["nino34_anom", 2], stats::cor(residuals(stats::lm(ocean_sink ~ year, mg)), mg$nino34_anom), nrow(mg)))
enso_slope <- function(r) { s <- dg_annual_sinks(r); d <- merge(data.frame(year = s$year, oc = s$ocean), en_ann, by = "year"); d <- d[d$year >= SC_ENSO_WIN[1] & d$year <= SC_ENSO_WIN[2], ]
  f <- stats::lm(oc ~ year + nino34_anom, data = d); c(slope = coef(f)[["nino34_anom"]], se = summary(f)$coefficients["nino34_anom", 2], r = stats::cor(residuals(stats::lm(oc ~ year, d)), d$nino34_anom)) }
# the solubility-only knockout zeroes EVERY ocean ENSO mechanism: the shim pair AND, since 09-20 (r)
# the canonical carries the layer-3 limb, w_enso_l2 (a knockout that misses a mechanism reads the
# full model as "solubility-only" -- it did, for one scorecard, at hilda29l)
ENSO <- list(); for (a in an) { full <- enso_slope(R[[a]]); v2 <- ARMS[[a]]; v2$p$gamma_enso_ocn_NH <- 0; v2$p$gamma_enso_ocn_SH <- 0; if (!is.null(v2$p$w_enso_l2)) v2$p$w_enso_l2 <- 0; sol <- enso_slope(dg_run(v2)); ENSO[[a]] <- list(full = full, sol = sol)
  cat(sprintf("  %-8s full model slope %+.4f ± %.4f (r %+.3f) = %.2fx obs;  solubility-only %+.4f (r %+.3f)  [gamma_enso_ocn NH %+.3f SH %+.3f; w_enso_l2 %.2f]\n", a, full["slope"], full["se"], full["r"], full["slope"] / coef(fo)[["nino34_anom"]], sol["slope"], sol["r"], ARMS[[a]]$p$gamma_enso_ocn_NH, ARMS[[a]]$p$gamma_enso_ocn_SH, if (is.null(ARMS[[a]]$p$w_enso_l2)) 0 else ARMS[[a]]$p$w_enso_l2)) }

cat("\n=== 4. COMPARISONS, NOT GATES (Marcus 09-08h: nothing from Joos may score the model) ===\n")
irf_of <- function(v) { spin <- dg_spinup(v)
  F_hist <- ccx_build_forcing("historical", c(1750, JOOS_REF_YEAR), prod_c14 = spin$prod_c14, bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  sp_ref <- spin; sp_ref$y <- ccx_run_fast(spin, F_hist)$state
  F_fwd <- suppressWarnings(ccx_build_forcing("historical", c(JOOS_REF_YEAR, JOOS_REF_YEAR + SC_JOOS_HORIZON + 10), prod_c14 = spin$prod_c14, bomb_total_kmol = 0, luc_scale = v$luc_scale))
  for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH", "enso", "c14_bomb", "c14_nuclear")) F_fwd[[cc]] <- 0
  F_fwd$gmst <- F_fwd$gmst[1]; F_hold <- ccx_hold_forcing(sp_ref, F_fwd, verbose = FALSE)
  o <- ccx_irf(sp_ref, F_hold); o$t <- o$t - (JOOS_PULSE_YR - JOOS_REF_YEAR); k <- o$t >= 0; at <- function(y) o$irf[k][which.min(abs(o$t[k] - y))]
  c(irf20 = at(20), irf100 = at(100), irf300 = at(300)) }
IRF <- list(); for (a in an) { x <- try_or(irf_of(ARMS[[a]]), paste("IRF", a)); IRF[[a]] <- x
  if (!is.null(x)) cat(sprintf("  12 IRF   %-8s IRF(20) %.3f  IRF(100) %.3f  IRF(300) %.3f   (Joos 2013 multi-model: %.3f / %.3f / %.3f)\n", a, x["irf20"], x["irf100"], x["irf300"], joos_irf(20), joos_irf(100), joos_irf(300))) }
LP <- list(); for (a in an) { x <- try_or(dg_gateL_partition(ARMS[[a]], horizon = max(SC_L_HORIZONS)), paste("L partition", a)); if (is.null(x)) next
  LP[[a]] <- list(share_at = lapply(SC_L_HORIZONS, x$share_at), cmp = dg_compareL(x), closure = x$closure, hold_dev = x$hold_dev)
  cat(sprintf("  L split  %-8s %s   (Joos 2013 at 1000 yr: land %g ± %g / ocean %g ± %g / air %g ± %g %%; z at 1000: %s; closure %.4f)\n", a,
              paste(vapply(seq_along(SC_L_HORIZONS), function(i) { s <- LP[[a]]$share_at[[i]]; sprintf("@%d yr land %.0f / ocean %.0f / air %.0f %%", SC_L_HORIZONS[i], s[["land"]], s[["ocean"]], s[["air"]]) }, ""), collapse = ";  "),
              DG_L_JOOS$land[["mean"]], DG_L_JOOS$land[["sd"]], DG_L_JOOS$ocean[["mean"]], DG_L_JOOS$ocean[["sd"]], DG_L_JOOS$air[["mean"]], DG_L_JOOS$air[["sd"]], paste(sprintf("%s %+.2f", names(LP[[a]]$cmp$z), LP[[a]]$cmp$z), collapse = " "), LP[[a]]$closure)) }

cat(sprintf("\n=== 5. STRAINED PRIORS (|z| > %g) and the declared structure ===\n", SC_PRIOR_STRAIN))
PZ <- list(); for (a in an) { z <- ARMS[[a]]$md$prior_z; PZ[[a]] <- z; if (is.null(z)) { cat(sprintf("  %-8s (no prior_z stored)\n", a)); next }
  big <- names(z)[abs(z) > SC_PRIOR_STRAIN]; cat(sprintf("  %-8s %s\n", a, if (length(big)) paste(sprintf("%s %+.2f", big, z[big]), collapse = ", ") else "none")) }
hsp <- readRDS(ccx_path("data", "obs_hs_export_prior.rds"))
for (a in an) { v <- ARMS[[a]]; if (arm_struct(v) != "hilda") next
  cat(sprintf("  %-8s declared: hs_frac %.2f, u_hs %g m/yr (= %.1f Sv over %.3g m2), tau_q %g yr, sst_hs %g C; fitted h_hs %.0f, pump_hs %.1f gC/m2/yr (prior-z %+.2f), hs_asx_frac %.2f, h_ml %.1f, ent_seas_amp_SH %.2f, sst_seas_amp NH %.2f / SH %.2f\n", a,
              v$p$hs_frac, v$p$u_hs, v$p$u_hs * (ccx_const("OCEAN_AREA_NH") + ccx_const("OCEAN_AREA_SH")) * v$p$hs_frac / 3.156e13, (ccx_const("OCEAN_AREA_NH") + ccx_const("OCEAN_AREA_SH")) * v$p$hs_frac, v$p$tau_q, v$p$sst_hs, v$p$h_hs, v$p$pump_hs_gcm2,
              (log(v$p$pump_hs_gcm2) - log(hsp$centre_gcm2)) / hsp$log_sd, v$p$hs_asx_frac, v$p$h_ml, v$p$ent_seas_amp_SH, v$p$sst_seas_amp_NH, v$p$sst_seas_amp_SH)) }
saveRDS(list(tag = SC_TAG, streams = ST, groups = G, repro = REPRO, verdicts = verd, gradients = GR, enso = ENSO, irf = IRF, partition = LP, prior_z = PZ,
             arms = lapply(ARMS, function(v) list(src = v$src, struct = arm_struct(v), seas_ml = ccx_mode_seas_ml(v$md), spinup = v$spinup_label, logpost = v$md$logpost, h_ml = v$p$h_ml))), SC_OUT)
cat(sprintf("\n  saved %s\n  ⛔ Nothing adopted.\n", SC_OUT))
