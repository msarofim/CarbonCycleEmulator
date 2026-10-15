# =====================================================================
# diag_hs_pump_probe.R -- THE HS PUMP AT THE ROUND-2 WINNER (2026-09-07d). Scan in gC m-2 yr-1
# (second run; the first, sized relative to the LS field, is _run1_rel.log and the prereg amendment).
# Judged on notes/prereg_2026-09-07d_hs_pump_probe.md P1-P7. Nothing refitted,
# nothing adopted. Usage: Rscript calibration/diag_hs_pump_probe.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
HQ_DIR   <- ccx_path("calibration", "output", "multistart_20260907b_hilda29")
HQ_GS    <- c(0, 15, 30, 45, 60, 90, 120)   # gC m-2 yr-1 (120 = 6.9 GtC/yr = the first run's "rel 0.5")
# JUDGED POINT (prereg amendment 2026-09-07d): the first run judged "rel 1" = 14 GtC/yr and failed P1 on SIZE
# (+443); the prereg's alternative is "some point in the scan with P1 inside". The judged point is the scan
# value whose HD - HS lands nearest the CENTER of the observed window -- chosen by P1's own statistic, not by
# any other prediction, so P2-P7 remain out-of-sample.
HQ_YR_BOXES <- 2008                     # the end-member probe's DIC-bottle epoch
HQ_P1 <- c(70, 185); HQ_P2 <- -0.5; HQ_P3 <- 20; HQ_P4 <- 2; HQ_P5_Z <- 2; HQ_P6 <- 0.2; HQ_P7 <- 2
HQ_PROFILE_ROWS <- c("d14c_profile_level", "d14c_profile_ab", "d14c_profile_bd")
HQ_OUT <- ccx_path("outputs", "diagnostics", "hs_pump_probe_20260907.rds")
fs <- list.files(HQ_DIR, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE)
R <- lapply(fs, readRDS); lp <- vapply(R, `[[`, 0, "logpost"); best <- R[[which.max(lp)]]
cat(sprintf("winner id %d, logpost %.2f\n", best$id, best$logpost))
mk_v <- function(p, pmv) list(p = p, pm = pmv, luc_scale = pmv$luc_scale, bomb_total = pmv$bomb_total, sigma_d14c = pmv$sigma_d14c,
                              rep_dC = pmv$rep_dC, grad_off_co2 = pmv$grad_off_co2, grad_off_d13c = pmv$grad_off_d13c)
v_of <- function(st, g) { p <- ccx_apply_structure(ccx_default_params(), "hilda"); p$pump_mode <- st$pump_mode
  v <- mk_v(ccx_overlay_par(p, st$par_mode), st$par_mode); v$p$pump_hs_gcm2 <- g; v }
tg7 <- dg_gcb_target(DG_SINK_WIN); spec <- ccx_profile_d14c_spec(); rho <- ccx_const("RHO_SEAWATER")
boxes <- function(v) {
  sp <- ccx_spinup(v$p); aux <- sp$aux; grid <- sp$grid; nl <- grid$nl
  F <- ccx_build_forcing("historical", c(DG_YEARS[1], HQ_YR_BOXES), prod_c14 = sp$prod_c14, bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  y <- ccx_run_fast(sp, F)$state
  conc <- function(i, m) y[i, "C"] * aux$mol_per_GtC / m * 1e6
  d13  <- function(i) 1000 * (y[i, "C13"] / y[i, "C"] / ccx_const("R13_VPDB") - 1)
  m <- function(f) mean(vapply(HEMIS, f, numeric(1)))
  c(ml = m(function(h) conc(aux$idx[[h]]$ml, aux$ml_mass_kg[[h]])), hs = m(function(h) conc(aux$idx[[h]]$hs, aux$hs_mass_kg[[h]])),
    hd = m(function(h) conc(aux$idx[[h]]$hd, aux$a_hs[[h]] * aux$dz_hd * rho)), bot = m(function(h) conc(utils::tail(aux$idx[[h]]$oc, 1), aux$a_ls[[h]] * grid$dz[nl + 1] * rho)),
    ml13 = m(function(h) d13(aux$idx[[h]]$ml)), hs13 = m(function(h) d13(aux$idx[[h]]$hs)), hd13 = m(function(h) d13(aux$idx[[h]]$hd)), bot13 = m(function(h) d13(utils::tail(aux$idx[[h]]$oc, 1))),
    E_hs = if (is.null(aux$pump_hs)) 0 else sum(vapply(HEMIS, function(h) aux$pump_hs[[h]]$org + aux$pump_hs[[h]]$carb, numeric(1))),
    E_ls = sum(vapply(HEMIS, function(h) sum(aux$pump[[h]]$org) + sum(aux$pump[[h]]$carb), numeric(1))))
}
score <- function(v) { r <- dg_run(v); st <- dg_streams(r, v); sp <- r$sp; sl <- ccx_model_d14c_slabs(sp); lev <- c(sl[[1]], sl[[2]], sp$diagnostics$d14c_bottom_box)
  g7 <- dg_gate7(r)
  list(st = st, z = c(level = (mean(lev) - spec$level) / spec$level_sd, ab = ((lev[1] - lev[2]) - spec$ab) / spec$ab_sd, bd = ((lev[2] - lev[3]) - spec$bd) / spec$bd_sd),
       sink = g7$ocean, z7 = dg_gate7_verdict(g7, tg7)$z_ocean) }
RES <- lapply(HQ_GS, function(g) { v <- v_of(best, g); c(list(rel = g, box = boxes(v)), score(v)) })
names(RES) <- paste0("g_", HQ_GS)
cat(sprintf("\n=== HS PUMP at the winner: boxes at %d (hemisphere means), umol/kg and permil ===\n", HQ_YR_BOXES))
cat(sprintf("  %4s | %6s %6s | %6s %6s %6s %6s | %6s %6s %6s %6s | %7s %7s %7s | %7s %7s\n", "gCm2", "E_hs", "E_ls", "ML", "HS", "HD", "bot", "ML13", "HS13", "HD13", "bot13", "HD-HS", "bot-HS", "bot-ML", "HS-ML13", "bot-HS13"))
for (S in RES) { b <- S$box
  cat(sprintf("  %4.0f | %6.2f %6.1f | %6.0f %6.0f %6.0f %6.0f | %+6.2f %+6.2f %+6.2f %+6.2f | %+7.0f %+7.0f %+7.0f | %+7.2f %+7.2f\n", S$rel, b[["E_hs"]], b[["E_ls"]],
              b[["ml"]], b[["hs"]], b[["hd"]], b[["bot"]], b[["ml13"]], b[["hs13"]], b[["hd13"]], b[["bot13"]], b[["hd"]] - b[["hs"]], b[["bot"]] - b[["hs"]], b[["bot"]] - b[["ml"]], b[["hs13"]] - b[["ml13"]], b[["bot13"]] - b[["hs13"]])) }
cat("  OBS: HI surface 2069 NH / 2163 SH, deep 2279 (deep - SH surface +116, deep - HI median +185); d13C HI +1.31, deep +0.44 (-0.87)\n")
S0 <- RES[["g_0"]]
cat(sprintf("\n=== streams vs off (objective #10) ===\n  %4s | %8s %7s | %7s %7s %7s | %6s %6s %6s | %6s %6s %6s | %5s\n", "gCm2", "lik", "d_lik", "g_d13c", "g_dic", "g_alk", "z_lev", "z_AB", "z_BD", "d_sink", "d_c14N", "d_c14S", "sink"))
for (S in RES) cat(sprintf("  %4.0f | %8.1f %+7.1f | %+7.2f %+7.2f %+7.2f | %+6.2f %+6.2f %+6.2f | %+6.2f %+6.2f %+6.2f | %5.2f\n", S$rel, sum(S$st), sum(S$st) - sum(S0$st),
  S$st[["ocean_grad_d13c"]] - S0$st[["ocean_grad_d13c"]], S$st[["ocean_grad_dic"]] - S0$st[["ocean_grad_dic"]], S$st[["ocean_grad_alk"]] - S0$st[["ocean_grad_alk"]],
  S$z[1], S$z[2], S$z[3], S$st[["gcb_ocean_sink"]] - S0$st[["gcb_ocean_sink"]], S$st[["d14c_NH"]] - S0$st[["d14c_NH"]], S$st[["d14c_SH"]] - S0$st[["d14c_SH"]], S$sink))
hdhs <- vapply(RES, function(S) S$box[["hd"]] - S$box[["hs"]], numeric(1))
HQ_G_JUDGED <- HQ_GS[which.min(abs(hdhs - mean(HQ_P1)))]
B <- RES[[paste0("g_", HQ_G_JUDGED)]]; b <- B$box; b0 <- S0$box
p1 <- (b[["hd"]] - b[["hs"]]) >= HQ_P1[1] && (b[["hd"]] - b[["hs"]]) <= HQ_P1[2]
p2 <- (b[["bot13"]] - b[["hs13"]]) <= HQ_P2
p3 <- (B$st[["ocean_grad_d13c"]] - S0$st[["ocean_grad_d13c"]]) >= HQ_P3
p4 <- (B$st[["ocean_grad_dic"]] - S0$st[["ocean_grad_dic"]]) >= HQ_P4
p5 <- all(abs(B$z) < HQ_P5_Z)
p6 <- (b0[["hs13"]] - b[["hs13"]]) >= HQ_P6
p7 <- (B$st[["gcb_ocean_sink"]] - S0$st[["gcb_ocean_sink"]] > -HQ_P7) && all(B$st[c("d14c_NH", "d14c_SH")] - S0$st[c("d14c_NH", "d14c_SH")] > -HQ_P7)
V <- function(ok) if (isTRUE(ok)) "PASS" else "FAIL"
cat(sprintf("\n=== PREDICTIONS at %g gC m-2 yr-1 = %.2f GtC/yr (the scan point with HD - HS nearest the P1 window centre; prereg_2026-09-07d amendment) ===\n", HQ_G_JUDGED, b[["E_hs"]]))
cat(sprintf("  P1 HD - HS DIC in [%g, %g]: %+.0f  -> %s\n", HQ_P1[1], HQ_P1[2], b[["hd"]] - b[["hs"]], V(p1)))
cat(sprintf("  P2 bottom - HS d13C <= %g: %+.2f  -> %s\n", HQ_P2, b[["bot13"]] - b[["hs13"]], V(p2)))
cat(sprintf("  P3 ocean_grad_d13c improves >= %g: %+.2f  -> %s\n", HQ_P3, B$st[["ocean_grad_d13c"]] - S0$st[["ocean_grad_d13c"]], V(p3)))
cat(sprintf("  P4 ocean_grad_dic improves >= %g: %+.2f  -> %s\n", HQ_P4, B$st[["ocean_grad_dic"]] - S0$st[["ocean_grad_dic"]], V(p4)))
cat(sprintf("  P5 profile rows inside %g sigma: %+.2f / %+.2f / %+.2f  -> %s\n", HQ_P5_Z, B$z[1], B$z[2], B$z[3], V(p5)))
cat(sprintf("  P6 HS d13C falls >= %g toward +1.31: %+.2f -> %+.2f  -> %s\n", HQ_P6, b0[["hs13"]], b[["hs13"]], V(p6)))
cat(sprintf("  P7 sink and bomb within %g of off: sink %+.2f, d14c_NH %+.2f, d14c_SH %+.2f  -> %s\n", HQ_P7, B$st[["gcb_ocean_sink"]] - S0$st[["gcb_ocean_sink"]], B$st[["d14c_NH"]] - S0$st[["d14c_NH"]], B$st[["d14c_SH"]] - S0$st[["d14c_SH"]], V(p7)))
cat(sprintf("  PLAUSIBLE FIX (P1, P2, P3, P5): %s\n", V(p1 && p2 && p3 && p5)))
cat("  ⛔ Nothing adopted; nothing refitted.\n")
saveRDS(list(res = RES, g_judged = HQ_G_JUDGED, preds = c(P1 = p1, P2 = p2, P3 = p3, P4 = p4, P5 = p5, P6 = p6, P7 = p7), winner_id = best$id), HQ_OUT); cat(sprintf("  saved %s\n", HQ_OUT))
