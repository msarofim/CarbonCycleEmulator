# =====================================================================
# diag_hygiene_refit_read.R -- THE HYGIENE-BATCH REFIT READ (the Mac wave of
# 2026-09-16 22:31 -> 09-17 09:19; 24 starts, 23 CONVERGED + 1 out of time;
# collector: 3 basins, the top two 0.45 log-units apart, inside the optimizer's
# 0.5 convergence bound). Reads, in the order handoff_2026-09-16f §2.5 asks:
#   gcb_land_sink and what paid (beta_max / q10 / fert_k / the CO2-level rows);
#   kz under the every-box D14C rows; h_hs under its Holte prior; u_hs at the
#   converted center; gates 7 / H / GL / Q (+ S); sst_seas_amp_SH's z.
# Arms, each scored LIKE-FOR-LIKE under its own structure + spinup:
#   canonical  hilda30c, restamped under objective #12, on ITS OWN struct (hilda);
#              section 0 proves it reproduces its stored streams before it is read
#   b1         basin 1's rank-1 start (id 20; ids 1/3/16/17 agree to 1e-4) --
#              the basin the INCUMBENT converged into, under hilda_c
#   b2         basin 2 (id 2 = the hilda31p start; ids 0/4/5/8/12/14/19/21/22 agree)
#   b3         basin 3 (id 23, -30.9 below; read for what it is, not compared)
# ⚠ The canonical's LOGPOST is on `hilda` with one pin; the starts' are on
# `hilda_c` with seven (six inert). Compare on the LIKELIHOOD over common rows,
# never the logposts ([[ccx_hilda30c_adopted]]: a pinned logpost is not a free one).
# ⚠ The seas_ml = 0 control is NOT in this array (every start ran at seas_ml 1);
# "does the control still lose" needs its own refit and is reported as OWED.
# READ, not gated -- nothing is adopted here; no mode is promoted.
# Usage: Rscript calibration/diag_hygiene_refit_read.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
HR_DIR  <- ccx_path("calibration", "output", "multistart_20260916_hilda_c_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_sd1.0452")
HR_JOB  <- "Mac wave 2026-09-16 22:31 -> 09-17 09:19 (frozen tree = the Torch bundle at 19be01f; launcher calibration/mac/run_multistart_mac.sh)"
HR_B1 <- 20L; HR_B1_TWIN <- 1L; HR_B2 <- 2L; HR_B3 <- 23L
HR_OUT  <- ccx_path("outputs", "diagnostics", sprintf("hygiene_refit_read_%s", format(Sys.Date(), "%Y%m%d")))
HR_REPRO_TOL <- 1e-3
HR_SST_SH_OBS <- 1.746     # the obs SH SST seasonal amplitude the shim stood in for (INDEX_ccx: 1.288 +- 0.188 fitted, 2.4 sigma off)
HR_UHS_CENTRE <- 27.3      # m/yr, the u_hs prior center converted at the LIVE hs_frac (handoff 09-16 f)
HR_GROUPS <- list(co2_level = "^co2_level_|^co2_icecore", co2_seasonal = "^co2_seasonal_", d13c_level = "^d13c_level_", d13c_seasonal = "^d13c_seasonal_",
                  gradients = "gradient", bomb_d14c = "^d14c_(NH|SH)$", d14c_profile = "^d14c_profile_", excess_c14 = "excess", gcb_sinks = "^gcb_", ocean_deep = "^ocean_grad_", hs_surface = "^hs_surf_")
HR_NAMES <- c("beta_max", "fert_k", "q10", "kz", "kz_deep_frac", "h_hs", "u_hs", "h_ml", "sst_seas_amp_NH", "sst_seas_amp_SH", "pump_hs_gcm2", "pump_grad",
              "hs_asx_frac", "k_w", "tau_ex", "rep_dC", "bomb_total", "sigma_d14c", "luc_scale", "grad_off_co2", "grad_off_d13c",
              "gamma_enso_land_NH", "gamma_enso_land_SH", "gamma_enso_ocn_NH", "gamma_enso_ocn_SH")
sink_log <- file(paste0(HR_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)
cat(sprintf("HYGIENE-BATCH REFIT READ  %s\n  %s\n  dir %s\n", format(Sys.time()), HR_JOB, HR_DIR))

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
ARMS <- list(canonical = canon, b1 = start_vector(HR_B1), b2 = start_vector(HR_B2), b3 = start_vector(HR_B3))
an <- names(ARMS)

cat("\n=== A. THE BASINS IN u-SPACE (the collector's clusters, by coordinate) ===\n")
s1 <- start_file(HR_B1); s1t <- start_file(HR_B1_TWIN); s2 <- start_file(HR_B2); s3 <- start_file(HR_B3)
du <- function(a, b) { d <- a$u_mode - b$u_mode; names(d) <- a$param_names; d }
d_twin <- du(s1, s1t); d12 <- du(s1, s2); d13 <- du(s1, s3)
cat(sprintf("  id %d vs id %d (same basin?): RMS |du| %.4f, max |du| %.4f at %s  (radius 0.7228)\n", HR_B1, HR_B1_TWIN, sqrt(mean(d_twin^2)), max(abs(d_twin)), names(which.max(abs(d_twin)))))
cat(sprintf("  basin 1 vs basin 2 (id %d vs id %d): RMS |du| %.4f; the coordinates that separate them (|du| > 0.2):\n", HR_B1, HR_B2, sqrt(mean(d12^2))))
big <- sort(abs(d12), decreasing = TRUE); big <- big[big > 0.2]
for (n in names(big)) cat(sprintf("    %-20s du %+.3f   b1 %10.4g   b2 %10.4g\n", n, d12[[n]], s1$par_mode[[n]], s2$par_mode[[n]]))
cat(sprintf("  basin 1 vs basin 3 (id %d): RMS |du| %.4f; largest %s %+.2f, %s %+.2f, %s %+.2f\n", HR_B3, sqrt(mean(d13^2)),
            names(sort(abs(d13), decreasing = TRUE))[1], d13[[names(sort(abs(d13), decreasing = TRUE))[1]]],
            names(sort(abs(d13), decreasing = TRUE))[2], d13[[names(sort(abs(d13), decreasing = TRUE))[2]]],
            names(sort(abs(d13), decreasing = TRUE))[3], d13[[names(sort(abs(d13), decreasing = TRUE))[3]]]))

cat("\n=== B. PARAMETERS (value, prior z) -- canonical (hilda, #12 restamp) vs the three basins (hilda_c) ===\n")
cat(sprintf("  %-20s %28s %28s %28s %28s\n", "name", "canonical", "b1 (incumbent's basin)", "b2", "b3"))
zfmt <- function(v, n) { z <- v$prior_z; if (is.null(z) || is.na(z[n])) "" else sprintf("z %+.2f", z[[n]]) }
for (n in HR_NAMES) {
  vals <- vapply(ARMS, function(v) { x <- v$pm[[n]]; if (is.null(x)) v$p[[n]] else x }, numeric(1))
  cat(sprintf("  %-20s %s\n", n, paste(vapply(an, function(a) sprintf("%18.5g %9s", vals[[a]], zfmt(ARMS[[a]], n)), ""), collapse = " ")))
}
for (a in an) cat(sprintf("  %-10s struct %s seas_ml %s pins %s\n", a, attr(ARMS[[a]]$p, "struct"), attr(ARMS[[a]]$p, "seas_ml"), ccx_pin_label(ARMS[[a]]$pins)))
cat(sprintf("  sst_seas_amp_SH vs obs %.3f: canonical %.3f, b1 %.3f, b2 %.3f (the shim's mechanism, assessment option K)\n", HR_SST_SH_OBS,
            ARMS$canonical$p$sst_seas_amp_SH, ARMS$b1$p$sst_seas_amp_SH, ARMS$b2$p$sst_seas_amp_SH))
for (a in an) cat(sprintf("  LIVE-table prior z %-10s h_hs %.1f m -> z %+.2f;  u_hs %.2f m/yr -> z %+.2f   (the file's stored h_hs z %s)\n", a, ARMS[[a]]$p$h_hs,
                          ccx_prior_z("h_hs", ARMS[[a]]$p$h_hs, p = ARMS[[a]]$p), ARMS[[a]]$p$u_hs, ccx_prior_z("u_hs", ARMS[[a]]$p$u_hs, p = ARMS[[a]]$p),
                          if (is.null(ARMS[[a]]$prior_z)) "n/a" else sprintf("%+.2f", ARMS[[a]]$prior_z[["h_hs"]])))
cat(sprintf("  u_hs vs its converted prior centre %.1f m/yr: canonical %.2f, b1 %.2f, b2 %.2f\n", HR_UHS_CENTRE, ARMS$canonical$p$u_hs, ARMS$b1$p$u_hs, ARMS$b2$p$u_hs))
for (a in an) { z <- ARMS[[a]]$prior_z; if (is.null(z)) next; s <- names(z)[abs(z) > 2]; cat(sprintf("  strained priors (|z| > 2) %-10s %s\n", a, if (length(s)) paste(sprintf("%s %+.2f", s, z[s]), collapse = ", ") else "none")) }

cat("\n=== 0. THE CANONICAL REPRODUCES ITS STORED STREAMS (the like-for-like guard) ===\n")
R <- lapply(ARMS, dg_run); ST <- Map(dg_streams, R, ARMS, MoreArgs = list(obs = obs))
st0 <- ARMS$canonical$md$streams; cm0 <- intersect(names(st0), names(ST$canonical)); d0 <- sum(ST$canonical[cm0]) - sum(unlist(st0[cm0]))
cat(sprintf("  stored %.4f recomputed %.4f diff %+.2e over %d rows -> %s\n", sum(unlist(st0[cm0])), sum(ST$canonical[cm0]), d0, length(cm0), if (abs(d0) <= HR_REPRO_TOL) "REPRODUCES" else "⚠ DOES NOT REPRODUCE -- read nothing off this arm"))
for (a in c("b1", "b2", "b3")) { s <- ARMS[[a]]$s
  cat(sprintf("  %-4s start file logpost %.4f (final_lp_check %s); the start's prior sum is not stored -- the LIKELIHOOD below is recomputed\n", a, s$logpost, if (is.null(s$final_lp_check)) "n/a" else format(s$final_lp_check))) }

cat("\n=== 1. LIKELIHOOD BY STREAM GROUP (common rows) ===\n")
common <- Reduce(intersect, lapply(ST, names))
cat(sprintf("  %-14s %s %9s %9s   rows\n", "group", paste(sprintf("%10s", an), collapse = ""), "b1-can", "b2-b1"))
G <- lapply(HR_GROUPS, function(pat) { rows <- grep(pat, common, value = TRUE); c(vapply(ST, function(s) sum(s[rows]), numeric(1)), n = length(rows)) })
for (g in names(G)) { x <- G[[g]]; if (x[["n"]] == 0) next
  cat(sprintf("  %-14s %s %+9.2f %+9.2f   %s\n", g, paste(sprintf("%10.2f", x[an]), collapse = ""), x[["b1"]] - x[["canonical"]], x[["b2"]] - x[["b1"]], paste(grep(HR_GROUPS[[g]], common, value = TRUE), collapse = " "))) }
tot <- vapply(ST, function(s) sum(s[common]), numeric(1))
cat(sprintf("  %-14s %s %+9.2f %+9.2f\n", "TOTAL common", paste(sprintf("%10.2f", tot), collapse = ""), tot[["b1"]] - tot[["canonical"]], tot[["b2"]] - tot[["b1"]]))
for (a in an) { extra <- setdiff(names(ST[[a]]), common); if (length(extra)) cat(sprintf("  %s-only rows: %s\n", a, paste(sprintf("%s %.2f", extra, ST[[a]][extra]), collapse = ", "))) }
cat("\n  every common row, b1 minus canonical (sorted):\n"); print(round(sort(ST$b1[common] - ST$canonical[common]), 2))
cat("\n  every common row, b2 minus b1 (sorted):\n"); print(round(sort(ST$b2[common] - ST$b1[common]), 2))

cat("\n=== 2. THE LAND SINK (gate 7) -- the item the batch cost -27.0 unrefitted ===\n")
tg7 <- dg_gcb_target(DG_SINK_WIN)
cat(sprintf("  GCB target over %d-%d (n %d): ocean %.2f (gate sd %.2f, GCB bare %.2f), land %.2f (gate sd %.2f, GCB bare %.2f) GtC/yr; gate bound %g sd\n", DG_SINK_WIN[1], DG_SINK_WIN[2], tg7$n,
            tg7$ocean, DG_G7_OCEAN_SD, DG_GCB_OCEAN_SD, tg7$land, DG_G7_LAND_SD, DG_GCB_LAND_SD, DG_G7_NSD))
G7 <- list(); for (a in an) { g7 <- dg_gate7(R[[a]]); vd <- dg_gate7_verdict(g7, tg7); G7[[a]] <- list(g = g7, v = vd)
  cat(sprintf("  GATE 7  %-10s ocean %.2f (z %+.2f, bare %+.2f) land %.2f (z %+.2f, bare %+.2f; %+.2f GtC/yr vs GCB) ; rows gcb_land_sink %.2f gcb_ocean_sink %.2f  -> %s\n", a, g7$ocean, vd$z_ocean, vd$z_ocean_bare, g7$land, vd$z_land, vd$z_land_bare, g7$land - tg7$land,
              ST[[a]][["gcb_land_sink"]], ST[[a]][["gcb_ocean_sink"]], if (isTRUE(vd$pass)) "PASS" else "FAIL")) }
cat("  what paid (b1 vs canonical): beta_max %+.3f, fert_k %+.1f, q10 %+.3f; co2_level rows %+.2f, co2_seasonal %+.2f, d13c_level %+.2f\n" |>
      sprintf(ARMS$b1$p$beta_max - ARMS$canonical$p$beta_max, ARMS$b1$p$fert_k - ARMS$canonical$p$fert_k, ARMS$b1$p$q10 - ARMS$canonical$p$q10,
              G$co2_level[["b1"]] - G$co2_level[["canonical"]], G$co2_seasonal[["b1"]] - G$co2_seasonal[["canonical"]], G$d13c_level[["b1"]] - G$d13c_level[["canonical"]]))

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
cat("  the seas_ml = 0 control under objective #12 / hilda_c: NOT in this array (every start ran at seas_ml 1) -- its own refit is owed before 'the control still loses' can be said.\n")
cat("  promotion is a NEW label via promote_multistart_mode.R, on Marcus's ruling.\n")
saveRDS(list(job = HR_JOB, dir = HR_DIR, ids = c(b1 = HR_B1, b1_twin = HR_B1_TWIN, b2 = HR_B2, b3 = HR_B3), du = list(twin = d_twin, b1_b2 = d12, b1_b3 = d13),
             params = lapply(ARMS, function(v) list(p = v$p, pm = v$pm, prior_z = v$prior_z, src = v$src)), streams = ST, groups = G, gate7 = G7, verdicts = verd, gradients = GR,
             built = format(Sys.time())), paste0(HR_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n⛔ NOTHING IS ADOPTED; no mode is promoted.\n", HR_OUT))
