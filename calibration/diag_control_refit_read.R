# =====================================================================
# diag_control_refit_read.R -- THE seas_ml-0 CONTROL's REFIT READ (the Mac wave of
# 2026-09-17 17:48 -> 23:34; objective #12, hilda_c, the six inert pins, the SHIM FREE
# (31 names); 24 starts, 24 CONVERGED; collector: 3 basins, 12 starts on the best,
# the h_ml twin 0.35 behind). THE QUESTION (handoff 09-17 k s2.1): how much of the
# canonical hilda30h's "+11.60 over the control" survives when the control is a #12
# fit on hilda_c rather than hilda31p restamped. Reads: the control's basin, its
# likelihood on the common rows vs the canonical AND vs the registered control
# hilda31p (each on ITS OWN structure + spinup), h_ml, the shim's fitted value, the
# land sink, gates 7 / H / GL / Q / S. Arms:
#   canonical  hilda30h (hilda_c, seas_ml 1, 7 pins incl. the shim at 0)
#   ctl_reg    hilda31p, the REGISTERED control (hilda, seas_ml 0, shim free 18.69)
#   c1         basin 1's rank-1 start (id 18; 12 starts incl. the incumbent id 1 agree)
#   c1b        the h_ml twin (id 4, -0.35: h_ml 55 vs 49.5 -- the round-6b pair)
#   c2         basin 2 (id 19, -7.1: h_ml 156, kz 10984 -- read for what it is)
# Section 0 proves BOTH registered files reproduce their stored streams before
# anything is read. Compare on LIKELIHOOD over common rows, never the logposts: the
# control's is a 31-name/6-pin number, the canonical's a 30-name/7-pin one.
# READ, not gated -- nothing is adopted; promotion of the refit control as the
# registered control (CCX_MODE_SEASML0_CONTROL) is a ruling.
# Usage: Rscript calibration/diag_control_refit_read.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
HR_DIR  <- ccx_path("calibration", "output", "multistart_20260917_hilda_c_seasml0_pin_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_sd1.0452")
HR_JOB  <- "Mac wave 2026-09-17 17:48 -> 23:34 (frozen tree ~/ccx_frozen/20260917j_control_refit = the bundle at 955a774; launcher launch_now.sh)"
HR_B1 <- 18L; HR_B1_TWIN <- 1L; HR_B2 <- 4L; HR_B3 <- 19L
HR_OUT  <- ccx_path("outputs", "diagnostics", sprintf("control_refit_read_%s", format(Sys.Date(), "%Y%m%d")))
HR_REPRO_TOL <- 1e-3
HR_SST_SH_OBS <- 1.746
HR_UHS_CENTRE <- 27.3
HR_GROUPS <- list(co2_level = "^co2_level_|^co2_icecore", co2_seasonal = "^co2_seasonal_", d13c_level = "^d13c_level_", d13c_seasonal = "^d13c_seasonal_",
                  gradients = "gradient", bomb_d14c = "^d14c_(NH|SH)$", d14c_profile = "^d14c_profile_", excess_c14 = "excess", gcb_sinks = "^gcb_", ocean_deep = "^ocean_grad_", hs = "^hs_")
HR_NAMES <- c("beta_max", "fert_k", "q10", "kz", "kz_deep_frac", "h_hs", "u_hs", "h_ml", "ent_seas_amp_SH", "sst_seas_amp_NH", "sst_seas_amp_SH", "pump_hs_gcm2", "pump_grad",
              "hs_asx_frac", "k_w", "tau_ex", "rep_dC", "bomb_total", "sigma_d14c", "luc_scale", "grad_off_co2", "grad_off_d13c",
              "gamma_enso_land_NH", "gamma_enso_land_SH", "gamma_enso_ocn_NH", "gamma_enso_ocn_SH")
sink_log <- file(paste0(HR_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)
cat(sprintf("CONTROL REFIT READ  %s\n  %s\n  dir %s\n", format(Sys.time()), HR_JOB, HR_DIR))

start_file <- function(id) readRDS(file.path(HR_DIR, sprintf("start_%03d.rds", id)))
start_vector <- function(id) {
  s <- start_file(id); pins <- s$pins
  .todo <- pins[names(pins) %in% CCX_PARAM_NAMES]; if (length(.todo)) invisible(ccx_apply_pins(.todo))
  p <- ccx_default_params(); p$pump_mode <- s$pump_mode
  p <- ccx_apply_structure(p, s$struct, s$seas_ml, pump_field = s$pump_field)
  for (n in names(pins)) p[[n]] <- pins[[n]]
  pm <- s$par_mode; for (n in names(pins)) pm[[n]] <- pins[[n]]
  for (n in intersect(names(p), names(pm))) p[[n]] <- pm[[n]]
  p <- ccx_set_enso(p, pm)
  list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total, sigma_d14c = pm$sigma_d14c,
       rep_dC = pm$rep_dC, grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c,
       spinup = CCX_OBJECTIVE_SPINUP, spinup_label = "periodic", pins = pins, prior_z = s$prior_z,
       src = sprintf("start_%03d (logpost %.4f, %s, %s)", id, s$logpost, if (isTRUE(s$converged)) "CONVERGED" else "NOT converged", s$kind), s = s)
}
obs <- ccx_prepare_obs(); OH <- dg_gateH_obs(obs)
canon <- dg_vector(CCX_MODE_CANONICAL); canon$prior_z <- canon$md$prior_z
ctl   <- dg_vector(CCX_MODE_SEASML0_CONTROL); ctl$prior_z <- ctl$md$prior_z
ARMS <- list(canonical = canon, ctl_reg = ctl, c1 = start_vector(HR_B1), c1b = start_vector(HR_B2), c2 = start_vector(HR_B3))
an <- names(ARMS)

cat("\n=== A. THE BASINS IN u-SPACE ===\n")
s1 <- start_file(HR_B1); s1t <- start_file(HR_B1_TWIN); s2 <- start_file(HR_B2); s3 <- start_file(HR_B3)
du <- function(a, b) { d <- a$u_mode - b$u_mode; names(d) <- a$param_names; d }
d_twin <- du(s1, s1t); d12 <- du(s1, s2); d13 <- du(s1, s3)
cat(sprintf("  id %d vs id %d (the incumbent's own convergence -- same basin?): RMS |du| %.4f, max |du| %.4f at %s\n", HR_B1, HR_B1_TWIN, sqrt(mean(d_twin^2)), max(abs(d_twin)), names(which.max(abs(d_twin)))))
cat(sprintf("  c1 vs c1b (id %d vs id %d, -0.35): RMS |du| %.4f; the coordinates that separate them (|du| > 0.2):\n", HR_B1, HR_B2, sqrt(mean(d12^2))))
big <- sort(abs(d12), decreasing = TRUE); big <- big[big > 0.2]
for (n in names(big)) cat(sprintf("    %-20s du %+.3f   c1 %10.4g   c1b %10.4g\n", n, d12[[n]], s1$par_mode[[n]], s2$par_mode[[n]]))
cat(sprintf("  c1 vs c2 (id %d, -7.1): RMS |du| %.4f; the coordinates that separate them (|du| > 0.5):\n", HR_B3, sqrt(mean(d13^2))))
big <- sort(abs(d13), decreasing = TRUE); big <- big[big > 0.5]
for (n in names(big)) cat(sprintf("    %-20s du %+.3f   c1 %10.4g   c2 %10.4g\n", n, d13[[n]], s1$par_mode[[n]], s3$par_mode[[n]]))

cat("\n=== B. PARAMETERS (value, prior z) ===\n")
cat(sprintf("  %-20s %s\n", "name", paste(sprintf("%28s", an), collapse = " ")))
zfmt <- function(v, n) { z <- v$prior_z; if (is.null(z) || is.na(z[n])) "" else sprintf("z %+.2f", z[[n]]) }
for (n in HR_NAMES) {
  vals <- vapply(ARMS, function(v) { x <- v$pm[[n]]; if (is.null(x)) x <- v$p[[n]]; if (is.null(x)) NA_real_ else x }, numeric(1))
  cat(sprintf("  %-20s %s\n", n, paste(vapply(an, function(a) sprintf("%18.5g %9s", vals[[a]], zfmt(ARMS[[a]], n)), ""), collapse = " ")))
}
for (a in an) cat(sprintf("  %-10s struct '%s' seas_ml %s pins %s\n", a, attr(ARMS[[a]]$p, "struct"), attr(ARMS[[a]]$p, "seas_ml"), ccx_pin_label(ARMS[[a]]$pins)))
cat(sprintf("  the SHIM ent_seas_amp_SH: registered control %.3f -> refit c1 %.3f, c1b %.3f, c2 %.3f (the canonical pins it at 0; the seasonal ML replaced it)\n",
            ARMS$ctl_reg$pm$ent_seas_amp_SH, ARMS$c1$pm$ent_seas_amp_SH, ARMS$c1b$pm$ent_seas_amp_SH, ARMS$c2$pm$ent_seas_amp_SH))
cat(sprintf("  h_ml: canonical %.1f, registered control %.1f, c1 %.1f, c1b %.1f, c2 %.1f (box floor %.1f)\n", ARMS$canonical$p$h_ml, ARMS$ctl_reg$p$h_ml, ARMS$c1$p$h_ml, ARMS$c1b$p$h_ml, ARMS$c2$p$h_ml, CCX_PARAM_TABLE$h_ml$lo))
cat(sprintf("  sst_seas_amp_SH vs obs %.3f: canonical %.3f, ctl_reg %.3f, c1 %.3f\n", HR_SST_SH_OBS, ARMS$canonical$p$sst_seas_amp_SH, ARMS$ctl_reg$p$sst_seas_amp_SH, ARMS$c1$p$sst_seas_amp_SH))
for (a in an) { z <- ARMS[[a]]$prior_z; if (is.null(z)) next; s <- names(z)[abs(z) > 2]; cat(sprintf("  strained priors (|z| > 2) %-10s %s\n", a, if (length(s)) paste(sprintf("%s %+.2f", s, z[s]), collapse = ", ") else "none")) }

cat("\n=== 0. BOTH REGISTERED FILES REPRODUCE THEIR STORED STREAMS (the like-for-like guard) ===\n")
R <- lapply(ARMS, dg_run); ST <- Map(dg_streams, R, ARMS, MoreArgs = list(obs = obs))
for (a in c("canonical", "ctl_reg")) { st0 <- ARMS[[a]]$md$streams; cm0 <- intersect(names(st0), names(ST[[a]])); d0 <- sum(ST[[a]][cm0]) - sum(unlist(st0[cm0]))
  cat(sprintf("  %-10s stored %.4f recomputed %.4f diff %+.2e over %d rows -> %s\n", a, sum(unlist(st0[cm0])), sum(ST[[a]][cm0]), d0, length(cm0), if (abs(d0) <= HR_REPRO_TOL) "REPRODUCES" else "DOES NOT REPRODUCE -- read nothing below")) }
for (a in c("c1", "c1b", "c2")) { s <- ARMS[[a]]$s
  cat(sprintf("  %-4s start file logpost %.4f (final_lp_check %s); the LIKELIHOOD below is recomputed\n", a, s$logpost, if (is.null(s$final_lp_check)) "n/a" else format(s$final_lp_check))) }

cat("\n=== 1. LIKELIHOOD BY STREAM GROUP (common rows) ===\n")
common <- Reduce(intersect, lapply(ST, names))
cat(sprintf("  %-14s %s %9s %9s   rows\n", "group", paste(sprintf("%10s", an), collapse = ""), "c1-can", "c1-ctlreg"))
G <- lapply(HR_GROUPS, function(pat) { rows <- grep(pat, common, value = TRUE); c(vapply(ST, function(s) sum(s[rows]), numeric(1)), n = length(rows)) })
for (g in names(G)) { x <- G[[g]]; if (x[["n"]] == 0) next
  cat(sprintf("  %-14s %s %+9.2f %+9.2f   %s\n", g, paste(sprintf("%10.2f", x[an]), collapse = ""), x[["c1"]] - x[["canonical"]], x[["c1"]] - x[["ctl_reg"]], paste(grep(HR_GROUPS[[g]], common, value = TRUE), collapse = " "))) }
tot <- vapply(ST, function(s) sum(s[common]), numeric(1))
cat(sprintf("  %-14s %s %+9.2f %+9.2f\n", "TOTAL common", paste(sprintf("%10.2f", tot), collapse = ""), tot[["c1"]] - tot[["canonical"]], tot[["c1"]] - tot[["ctl_reg"]]))
for (a in an) { extra <- setdiff(names(ST[[a]]), common); if (length(extra)) cat(sprintf("  %s-only rows: %s\n", a, paste(sprintf("%s %.2f", extra, ST[[a]][extra]), collapse = ", "))) }
cat("\n  every common row, c1 (the refit control) minus canonical (sorted):\n"); print(round(sort(ST$c1[common] - ST$canonical[common]), 2))
cat("\n  every common row, c1 minus the REGISTERED control hilda31p (what the refit bought, sorted):\n"); print(round(sort(ST$c1[common] - ST$ctl_reg[common]), 2))
cat(sprintf("\n  THE QUESTION: canonical minus registered control %+.2f (the \"+11.60\"); canonical minus REFIT control (c1) %+.2f; c1b %+.2f; c2 %+.2f  [likelihood on %d common rows]\n", tot[["canonical"]] - tot[["ctl_reg"]], tot[["canonical"]] - tot[["c1"]], tot[["canonical"]] - tot[["c1b"]], tot[["canonical"]] - tot[["c2"]], length(common)))
cat(sprintf("  AIC-style: the control fits 31 names, the canonical 30 -- one log-unit per name is the conventional allowance\n"))

cat("\n=== 2. THE LAND SINK (gate 7) ===\n")
tg7 <- dg_gcb_target(DG_SINK_WIN)
cat(sprintf("  GCB target over %d-%d (n %d): ocean %.2f (gate sd %.2f, GCB bare %.2f), land %.2f (gate sd %.2f, GCB bare %.2f) GtC/yr; gate bound %g sd\n", DG_SINK_WIN[1], DG_SINK_WIN[2], tg7$n,
            tg7$ocean, DG_G7_OCEAN_SD, DG_GCB_OCEAN_SD, tg7$land, DG_G7_LAND_SD, DG_GCB_LAND_SD, DG_G7_NSD))
G7 <- list(); for (a in an) { g7 <- dg_gate7(R[[a]]); vd <- dg_gate7_verdict(g7, tg7); G7[[a]] <- list(g = g7, v = vd)
  cat(sprintf("  GATE 7  %-10s ocean %.2f (z %+.2f, bare %+.2f) land %.2f (z %+.2f, bare %+.2f; %+.2f GtC/yr vs GCB) ; rows gcb_land_sink %.2f gcb_ocean_sink %.2f  -> %s\n", a, g7$ocean, vd$z_ocean, vd$z_ocean_bare, g7$land, vd$z_land, vd$z_land_bare, g7$land - tg7$land,
              ST[[a]][["gcb_land_sink"]], ST[[a]][["gcb_ocean_sink"]], if (isTRUE(vd$pass)) "PASS" else "FAIL")) }
cat("  c1 vs canonical: beta_max %+.3f, fert_k %+.1f, q10 %+.3f; co2_level rows %+.2f, co2_seasonal %+.2f, d13c_level %+.2f\n" |>
      sprintf(ARMS$c1$p$beta_max - ARMS$canonical$p$beta_max, ARMS$c1$p$fert_k - ARMS$canonical$p$fert_k, ARMS$c1$p$q10 - ARMS$canonical$p$q10,
              G$co2_level[["c1"]] - G$co2_level[["canonical"]], G$co2_seasonal[["c1"]] - G$co2_seasonal[["canonical"]], G$d13c_level[["c1"]] - G$d13c_level[["canonical"]]))

cat("\n=== 3. kz UNDER THE EVERY-BOX D14C ROWS (review 09-16 d finding 1: a directional pull) ===\n")
for (a in an) cat(sprintf("  %-10s kz %.0f (deep frac %.4f -> K_deep %.0f), h_ml %.1f, bomb_total %.1f, sigma_d14c %.2f; d14c_profile rows %.2f, bomb rows %.2f, excess %.2f\n", a,
                          ARMS[[a]]$p$kz, ARMS[[a]]$p$kz_deep_frac, ARMS[[a]]$p$kz * ARMS[[a]]$p$kz_deep_frac, ARMS[[a]]$p$h_ml, ARMS[[a]]$bomb_total, ARMS[[a]]$sigma_d14c,
                          G$d14c_profile[[a]], G$bomb_d14c[[a]], G$excess_c14[[a]]))

cat("\n=== 4. GATES H / GL / Q / S (the ledger's idioms) ===\n")
verd <- list(); GH <- list()
for (a in an) { gh <- dg_gateH(ARMS[[a]], obs, OH, r = R[[a]]); GH[[a]] <- gh; vd <- dg_gateH_verdict(gh, OH); verd[[a]]$H <- vd
  cat(sprintf("  GATE H  %-10s R_co2 %.3f (z_level %+.2f) R_d13c %.3f (z_level %+.2f)  contrast z %+.2f  -> %s\n", a, vd$R_co2, vd$z_level_co2, vd$R_d13c, vd$z_level_d13c, vd$z, if (vd$pass) "PASS" else "FAIL")) }
for (a in an) { vd <- dg_gateGL_verdict(GH[[a]], OH); verd[[a]]$GL <- vd
  cat(sprintf("  GATE GL %-10s d13C gradient %.4f vs obs %.4f +- %.4f (ratio %.2f) z %+.2f (bare %+.2f)  -> %s\n", a, vd$model, vd$obs, vd$se_obs, vd$ratio, vd$z, vd$z_bare, if (vd$pass) "PASS" else "FAIL")) }
for (a in an) { q <- dg_gateQ(R[[a]], ARMS[[a]]); verd[[a]]$Q <- q
  cat(sprintf("  GATE Q  %-10s air-sea d13C diseq NH %+.3f SH %+.3f mean %+.3f vs %.2f +- %.2f  n_sd %.2f  -> %s\n", a, q$by_hemi[["NH"]], q$by_hemi[["SH"]], q$mean, DG_Q_OBS, DG_Q_SD, q$n_sd, if (q$pass) "PASS" else "FAIL")) }
for (a in an) { vd <- tryCatch({ g <- dg_gateS(ARMS[[a]], obs, r = R[[a]]); dg_gateS_verdict(g) }, error = function(e) { cat(sprintf("  GATE S  %-10s FAILED TO RUN: %s\n", a, conditionMessage(e))); NULL }); verd[[a]]$S <- vd
  if (!is.null(vd)) cat(sprintf("  GATE S  %-10s SPO ocean limb %.3f ppm @ month %.2f, bracket [%.2f, %.2f]  -> %s\n", a, vd$amp, vd$mo, vd$lo, vd$hi, if (vd$pass) "PASS" else sprintf("FAIL (%+.2f mo)", vd$d_mo))) }
GR <- lapply(R, function(r) ccx_ocean_grad_scored(r$out, r$sp)); tgP <- ccx_ocean_gradient_target()
for (a in an) cat(sprintf("  (gradient rows) %-10s d13C %.3f (target %.3f) DIC %.1f (target %.1f +- %.1f, z %+.2f)\n", a, GR[[a]]$d13c, tgP$d13c$target, GR[[a]]$dic, tgP$dic$target, tgP$dic$sd, (GR[[a]]$dic - tgP$dic$target) / tgP$dic$sd))

cat("\n=== 5. OWED, NOT READ HERE ===\n")
cat("  promotion of c1 as the registered seas_ml-0 control (CCX_MODE_SEASML0_CONTROL, CCX_MODE_FILES, make_bundle.sh, test-mode-file's gate) is a RULING.\n")
saveRDS(list(job = HR_JOB, dir = HR_DIR, ids = c(c1 = HR_B1, c1_twin = HR_B1_TWIN, c1b = HR_B2, c2 = HR_B3), du = list(twin = d_twin, c1_c1b = d12, c1_c2 = d13),
             params = lapply(ARMS, function(v) list(p = v$p, pm = v$pm, prior_z = v$prior_z, src = v$src)), streams = ST, groups = G, gate7 = G7, verdicts = verd, gradients = GR,
             built = format(Sys.time())), paste0(HR_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n⛔ NOTHING IS ADOPTED; no mode is promoted.\n", HR_OUT))
