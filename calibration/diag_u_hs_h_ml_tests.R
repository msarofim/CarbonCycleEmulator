# =====================================================================
# diag_u_hs_h_ml_tests.R -- THE u_hs / h_ml TESTS T1-T7 (2026-09-08c), judged on
# notes/prereg_2026-09-08c_u_hs_h_ml_tests.md P1-P7. At the round-3 winner (job
# 17150003, id 24), structure hilda, the multistart's OWN objective
# (ccx_make_logpost: objective #10 + #11 with priors). Adopts nothing.
#   T1  u_hs in {38, 30, 24, 18}: profile in pump_hs_gcm2 (1-D optimum, rest held)
#   T2  h_hs in {winner, 75}: the same profile
#   T3  net conduit carbon flux interior <-> HD at the winner's spinup (a read)
#   T4  remineralisation below 1000 m, LS + HS, vs the literature (a read)
#   T5  h_ml pinned at the OBSERVED LS annual-mean MLD, nothing refitted
#   T6  h_ml pinned at the OBSERVED LS annual-maximum MLD, nothing refitted
#   T7  the 40 m vs 180-200 m families of round 3, per stream (a diff of the scorer)
# ADDED AFTER THE FIRST RUN (all seven pre-registered predictions FAILED, all
# through the CO2-level rows; prereg sec. "post-hoc"): T1(i) the flush at FIXED
# export; T1(ii) the export optimum against the 8 DEEP rows alone (the powered
# H1 test); T2(0) HILDA's thickness at the SAME export (steady state must not
# move); the CO2 trajectory shift behind T5/T6.
# Usage: Rscript calibration/diag_u_hs_h_ml_tests.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
UH_DIR <- ccx_path("calibration", "output", "multistart_20260907f_hilda30")
UH_ARM <- "N"                                   # MS_ARM of the round-3 launch
UH_GATE_TOL <- 1e-2                             # harness: reproduce the stored logpost
UH_UHS <- c(38, 30, 24, 18)                     # m/yr; 38 = the declared value
UH_HHS_ALT <- 75                                # m, HILDA's own surface-box thickness
UH_PROFILE_LOG_RANGE <- log(c(1, 199))          # pump_hs_gcm2 box is [0.5, 200]
UH_PROFILE_TOL <- 1e-3
UH_MLD <- readRDS(ccx_path("data", "obs_mld.rds"))
UH_T5_H <- UH_MLD$ls$mean_dt$value; UH_T6_H <- UH_MLD$ls$max_dt$value   # READ from the product, not typed
UH_LIT_REMIN_1000 <- 1.4                        # GtC/yr, Nowicki 2022 10.2 x Martin et al. 1987 (DSR 34:267; 1.53 (z/100)^-0.858, SOURCED 09-08f) F(1000)/F(100) 0.139
UH_P1_BAND24 <- c(74, 100); UH_P1_BAND18 <- c(55, 75); UH_P3_BAND <- c(0.7, 1.4); UH_P4_MAX <- 100
UH_P5_TOL <- 0.10; UH_P6_MAX <- 10; UH_P7_MAX <- 30; UH_P7_ROW_MAX <- 2
UH_SINK_BOMB <- c("gcb_ocean_sink", "d14c_NH", "d14c_SH"); UH_BAD_ROWS_P6 <- c("d14c_NH", "d14c_SH", "co2_icecore", "co2_seasonal_MLO", "co2_seasonal_SPO", "d13c_seasonal_MLO", "d13c_seasonal_SPO", "gcb_ocean_sink")
UH_PROFILE_ROWS <- c("d14c_profile_level", "d14c_profile_ab", "d14c_profile_bd")
UH_DEEP_ROWS <- c("ocean_grad_dic", "ocean_grad_d13c", "ocean_grad_alk", "hs_surf_dic", "hs_surf_d13c", UH_PROFILE_ROWS)
UH_P1B_RATIO_TOL <- 0.10; UH_CO2_WIN <- c(1959, 2024); UH_CO2_YEAR <- 2020
UH_SCORER <- ccx_path("outputs", "diagnostics", "hilda30_predictions_20260908.rds")
UH_OUT <- ccx_path("outputs", "diagnostics", "u_hs_h_ml_tests_20260908.rds")

fs <- list.files(UH_DIR, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE)
S <- lapply(fs, readRDS); best <- S[[which.max(vapply(S, `[[`, 0, "logpost"))]]; pm0 <- best$par_mode
cat(sprintf("winner: id %d, logpost %.4f, pump_hs_gcm2 %.2f, h_ml %.2f, h_hs %.1f, u_hs (declared) %g\n", best$id, best$logpost, pm0$pump_hs_gcm2, pm0$h_ml, pm0$h_hs, CCX_U_HS_DECLARED))
base_p <- function(u_hs = CCX_U_HS_DECLARED) { bp <- ccx_default_params(); bp$pump_mode <- UH_ARM; bp <- ccx_apply_structure(bp, "hilda"); bp$u_hs <- u_hs; bp }
LP <- list(); lp_of <- function(u_hs) { k <- as.character(u_hs); if (is.null(LP[[k]])) LP[[k]] <<- ccx_make_logpost(base_params = base_p(u_hs)); LP[[k]] }
lp0 <- lp_of(38)(best$u_mode)
cat(sprintf("HARNESS GATE: rebuilt logpost at the winner's u %.4f vs stored %.4f (diff %.2e) -> %s\n", lp0, best$logpost, lp0 - best$logpost, if (abs(lp0 - best$logpost) < UH_GATE_TOL) "PASS" else "FAIL"))
if (abs(lp0 - best$logpost) >= UH_GATE_TOL) stop("harness gate failed: the objective is not round 3's")

mk_v <- function(p, pmv) list(p = p, pm = pmv, luc_scale = pmv$luc_scale, bomb_total = pmv$bomb_total, sigma_d14c = pmv$sigma_d14c, rep_dC = pmv$rep_dC, grad_off_co2 = pmv$grad_off_co2, grad_off_d13c = pmv$grad_off_d13c)
v_of <- function(pm, u_hs = CCX_U_HS_DECLARED) mk_v(ccx_overlay_par(base_p(u_hs), pm), pm)
spec <- ccx_profile_d14c_spec(); tgh <- ccx_hs_surface_target(); tg7 <- dg_gcb_target(DG_SINK_WIN)
umol <- function(aux, c_gtc_m3) c_gtc_m3 * aux$mol_per_GtC / ccx_const("RHO_SEAWATER") * 1e6
conduit <- function(sp, p) { aux <- sp$aux; grid <- sp$grid; y <- sp$y
  do.call(rbind, lapply(HEMIS, function(h) { ix <- aux$idx[[h]]; ioc <- ix$oc; ihd <- ix$hd; ihs <- ix$hs
    conc_hd <- y[ihd, "C"] / (aux$a_hs[[h]] * aux$dz_hd); conc_hs <- y[ihs, "C"] / (aux$a_hs[[h]] * aux$h_hs)
    to_hd <- sum(y[ioc, "C"] / p$tau_q); from_hd <- sum(aux$a_ls[[h]] * grid$dz[-1] / p$tau_q * conc_hd)
    fl_hs <- p$u_hs * y[ihs, "C"] / aux$h_hs; fl_hd <- p$u_hs * y[ihd, "C"] / aux$dz_hd
    ex <- aux$pump[[h]]$org + aux$pump[[h]]$carb; zb <- cumsum(grid$dz)[-1]
    data.frame(h = h, dic_hs = umol(aux, conc_hs), dic_hd = umol(aux, conc_hd), cond_gross = to_hd, cond_net_int_to_hd = to_hd - from_hd,
               flush_gross_hs_to_hd = fl_hs, flush_net_hs_to_hd = fl_hs - fl_hd, e_hs = if (is.null(aux$pump_hs)) 0 else aux$pump_hs[[h]]$org + aux$pump_hs[[h]]$carb,
               e_ls = sum(ex), ls_remin_below_1000 = sum(ex[zb > 1000])) })) }
read_state <- function(v) { r <- dg_run(v); st <- dg_streams(r, v); sp <- r$sp; sl <- ccx_model_d14c_slabs(sp); lev <- c(sl[[1]], sl[[2]], sp$diagnostics$d14c_bottom_box)
  hs <- ccx_ocean_grad_scored(r$out, sp)$hs_surf; cd <- conduit(sp, v$p); g7 <- dg_gate7(r); yr <- floor(r$out$t)
  list(st = st, lik = sum(st), deep = sum(st[UH_DEEP_ROWS]), co2 = r$out$co2_NH[yr >= UH_CO2_WIN[1] & yr <= UH_CO2_WIN[2]], co2_yr = mean(r$out$co2_NH[yr == UH_CO2_YEAR]), z = c(level = (mean(lev) - spec$level) / spec$level_sd, ab = ((lev[1] - lev[2]) - spec$ab) / spec$ab_sd, bd = ((lev[2] - lev[3]) - spec$bd) / spec$bd_sd),
       hs_d13c = hs$d13c, hs_dic = hs$dic, cd = cd, sink = g7$ocean, e_hs = sum(cd$e_hs), e_ls = sum(cd$e_ls), hd_minus_hs = mean(cd$dic_hd - cd$dic_hs), cond_net_hd_to_int = -sum(cd$cond_net_int_to_hd)) }
W <- read_state(v_of(pm0)); cat(sprintf("winner re-read: lik %.2f (logpost %.2f), HS d13C %+.2f, HD-HS %.0f, E_hs %.2f, E_ls %.2f GtC/yr\n", W$lik, lp0, W$hs_d13c, W$hd_minus_hs, W$e_hs, W$e_ls))

profile <- function(pm, u_hs) { lp <- lp_of(u_hs); f <- function(lz) { pm$pump_hs_gcm2 <- exp(lz); -lp(ccx_par_to_unc(pm)) }
  o <- stats::optimize(f, UH_PROFILE_LOG_RANGE, tol = UH_PROFILE_TOL); pm$pump_hs_gcm2 <- exp(o$minimum); list(g = exp(o$minimum), lp = -o$objective, pm = pm) }

cat("\n=== T1: profile in pump_hs_gcm2 at u_hs in {", paste(UH_UHS, collapse = ", "), "} m/yr (Sv = u_hs * a_hs / 3.156e13) ===\n")
a_hs_tot <- sum(unlist(W$cd$e_hs)) * 1e15 / pm0$pump_hs_gcm2   # m2, derived from the winner's own export
cat(sprintf("  %5s %6s | %8s %8s %8s | %6s %6s | %7s %6s %6s | %+6s %+6s %+6s | %5s %7s | %8s\n", "u_hs", "Sv", "g_opt", "E_hs", "E_ls", "lp", "lik", "HS13", "HD-HS", "cond", "z_lev", "z_AB", "z_BD", "sink", "co2_20", "d_lik_vs_W"))
T1 <- lapply(UH_UHS, function(u) { pr <- profile(pm0, u); Sx <- read_state(v_of(pr$pm, u))
  cat(sprintf("  %5g %6.1f | %8.1f %8.2f %8.2f | %6.1f %6.1f | %+7.2f %6.0f %6.2f | %+6.2f %+6.2f %+6.2f | %5.2f %7.2f | %+8.2f\n", u, u * a_hs_tot / 3.156e13, pr$g, Sx$e_hs, Sx$e_ls, pr$lp, Sx$lik, Sx$hs_d13c, Sx$hd_minus_hs, Sx$cond_net_hd_to_int, Sx$z[1], Sx$z[2], Sx$z[3], Sx$sink, Sx$co2_yr, Sx$lik - W$lik))
  c(list(u_hs = u, g = pr$g, lp = pr$lp), Sx) })
g1 <- vapply(T1, `[[`, 0, "g"); lp1 <- vapply(T1, `[[`, 0, "lp"); hs1 <- vapply(T1, `[[`, 0, "hs_d13c"); cn1 <- vapply(T1, `[[`, 0, "cond_net_hd_to_int")
cat("  rows paying most at u_hs 24 vs the winner (|d| > 1):\n"); d24 <- T1[[which(UH_UHS == 24)]]$st - W$st; for (n in names(d24)[order(-abs(d24))][abs(sort(-abs(d24))) > 1]) cat(sprintf("    %-24s %+7.2f\n", n, d24[[n]]))

cat("\n=== T1(i) [post-hoc]: the flush at FIXED export 137.5 -- what u_hs alone does ===\n")
cat(sprintf("  %5s | %8s %8s %8s | %6s %+6s %6s %7s %6s\n", "u_hs", "lik", "deep8", "rest", "HD-HS", "HS13", "sink", "co2_20", "cond"))
T1i <- lapply(UH_UHS, function(u) { Sx <- read_state(v_of(pm0, u))
  cat(sprintf("  %5g | %8.1f %8.1f %8.1f | %6.0f %+6.2f %6.2f %7.2f %6.2f\n", u, Sx$lik, Sx$deep, Sx$lik - Sx$deep, Sx$hd_minus_hs, Sx$hs_d13c, Sx$sink, Sx$co2_yr, Sx$cond_net_hd_to_int)); c(list(u_hs = u), Sx) })
d24i <- T1i[[which(UH_UHS == 24)]]$st - W$st; cat("  rows at u_hs 24, fixed export (|d| > 2): "); for (n in names(d24i)[order(-abs(d24i))][abs(sort(-abs(d24i))) > 2]) cat(sprintf("%s %+.1f; ", n, d24i[[n]])); cat("\n")
cat("\n=== T1(ii) [post-hoc]: the export optimum against the 8 DEEP rows ALONE (the powered H1 test) ===\n")
cat(sprintf("  %5s | %8s %8s | %6s %+6s %6s | %8s\n", "u_hs", "g_opt", "deep8", "HD-HS", "HS13", "cond", "g/u_hs"))
T1ii <- lapply(UH_UHS, function(u) { f <- function(lz) { pm <- pm0; pm$pump_hs_gcm2 <- exp(lz); -read_state(v_of(pm, u))$deep }
  o <- stats::optimize(f, UH_PROFILE_LOG_RANGE, tol = 2 * UH_PROFILE_TOL); pm <- pm0; pm$pump_hs_gcm2 <- exp(o$minimum); Sx <- read_state(v_of(pm, u))
  cat(sprintf("  %5g | %8.1f %8.1f | %6.0f %+6.2f %6.2f | %8.2f\n", u, exp(o$minimum), Sx$deep, Sx$hd_minus_hs, Sx$hs_d13c, Sx$cond_net_hd_to_int, exp(o$minimum) / u)); c(list(u_hs = u, g = exp(o$minimum)), Sx) })
g1b <- vapply(T1ii, `[[`, 0, "g"); ratio1b <- g1b / UH_UHS

cat(sprintf("\n=== T2: profile at h_hs %g (winner) vs %g (HILDA), u_hs 38 ===\n", pm0$h_hs, UH_HHS_ALT))
pm75 <- pm0; pm75$h_hs <- UH_HHS_ALT; pr75 <- profile(pm75, 38); S75 <- read_state(v_of(pr75$pm))
cat(sprintf("  h_hs %5.0f: g_opt %6.1f  lp %8.2f  lik %8.2f  HS13 %+.2f  HD-HS %.0f  z %+.2f/%+.2f/%+.2f\n", pm0$h_hs, g1[1], lp1[1], T1[[1]]$lik, hs1[1], T1[[1]]$hd_minus_hs, T1[[1]]$z[1], T1[[1]]$z[2], T1[[1]]$z[3]))
cat(sprintf("  h_hs %5.0f: g_opt %6.1f  lp %8.2f  lik %8.2f  HS13 %+.2f  HD-HS %.0f  z %+.2f/%+.2f/%+.2f\n", UH_HHS_ALT, pr75$g, pr75$lp, S75$lik, S75$hs_d13c, S75$hd_minus_hs, S75$z[1], S75$z[2], S75$z[3]))

pm75$pump_hs_gcm2 <- pm0$pump_hs_gcm2; S75_0 <- read_state(v_of(pm75))
cat(sprintf("  T2(0) [post-hoc] h_hs %g at the SAME export %.1f: HD-HS %.1f vs %.1f (steady state %s), HS13 %+.2f, sink %.2f vs %.2f, co2_%d %.2f vs %.2f, lik %+.2f; rows |d| > 2: ", UH_HHS_ALT, pm0$pump_hs_gcm2, S75_0$hd_minus_hs, W$hd_minus_hs, if (abs(S75_0$hd_minus_hs - W$hd_minus_hs) < 0.5) "CANCELS" else "MOVES", S75_0$hs_d13c, S75_0$sink, W$sink, UH_CO2_YEAR, S75_0$co2_yr, W$co2_yr, S75_0$lik - W$lik))
d75 <- S75_0$st - W$st; for (n in names(d75)[order(-abs(d75))][abs(sort(-abs(d75))) > 2]) cat(sprintf("%s %+.1f; ", n, d75[[n]])); cat("\n")

cat("\n=== T3: conduit and flush carbon budget at the winner's preindustrial spinup (GtC/yr) ===\n"); print(W$cd, row.names = FALSE, digits = 4)
cat(sprintf("  NET: HS pump into HD %.2f; returned HD->HS through the u_hs flush %.2f (%.0f %%); delivered HD->interior through the conduit %.2f (%.0f %%)\n", W$e_hs, -sum(W$cd$flush_net_hs_to_hd), -100 * sum(W$cd$flush_net_hs_to_hd) / W$e_hs, W$cond_net_hd_to_int, 100 * W$cond_net_hd_to_int / W$e_hs))
cat(sprintf("\n=== T4: remineralisation below 1000 m ===\n  LS pump into layers below 1000 m: %.3f GtC/yr of %.2f exported; HS pump into HD (400-3700 m, one box): %.2f; total %.2f vs literature %.1f (Nowicki 2022 x Martin; the exponent is a RECOLLECTION) = %.1fx\n  ...but the carbon that REACHES the deep interior is the conduit's net %.2f GtC/yr = %.2fx the literature number.\n",
            sum(W$cd$ls_remin_below_1000), W$e_ls, W$e_hs, sum(W$cd$ls_remin_below_1000) + W$e_hs, UH_LIT_REMIN_1000, (sum(W$cd$ls_remin_below_1000) + W$e_hs) / UH_LIT_REMIN_1000, W$cond_net_hd_to_int, W$cond_net_hd_to_int / UH_LIT_REMIN_1000))

pin <- function(h) { pm <- pm0; pm$h_ml <- h; Sx <- read_state(v_of(pm)); Sx$lp <- lp_of(38)(ccx_par_to_unc(pm)); Sx$h <- h; Sx }
report_pin <- function(Sx, lab) { d <- Sx$st - W$st; o <- names(d)[order(-abs(d))]
  cat(sprintf("\n=== %s: h_ml %.1f -> %.1f m, nothing refitted: lik %.2f (%+.2f vs winner), logpost %.2f (%+.2f; h_ml prior-z at the winner %+.2f) ===\n", lab, pm0$h_ml, Sx$h, Sx$lik, Sx$lik - W$lik, Sx$lp, Sx$lp - lp0, best$prior_z[["h_ml"]]))
  cat(sprintf("  HS13 %+.2f, HD-HS %.0f, E_ls %.2f, sink %.2f (%+.2f), co2_%d %+.2f ppm, RMS dCO2 %d-%d %.2f ppm, z %+.2f/%+.2f/%+.2f; rows |d| > 0.5:\n", Sx$hs_d13c, Sx$hd_minus_hs, Sx$e_ls, Sx$sink, Sx$sink - W$sink, UH_CO2_YEAR, Sx$co2_yr - W$co2_yr, UH_CO2_WIN[1], UH_CO2_WIN[2], sqrt(mean((Sx$co2 - W$co2)^2)), Sx$z[1], Sx$z[2], Sx$z[3]))
  for (n in o[abs(d[o]) > 0.5]) cat(sprintf("    %-24s %+7.2f\n", n, d[[n]])); list(d = d, top = o[1]) }
T5 <- pin(UH_T5_H); R5 <- report_pin(T5, "T5 (observed LS annual MEAN)")
T6 <- pin(UH_T6_H); R6 <- report_pin(T6, "T6 (observed LS annual MAXIMUM)")

cat("\n=== T7: round 3's 40 m family vs its 180-200 m family, per stream (from the scorer's saved streams) ===\n")
X <- readRDS(UH_SCORER); ag <- X$basins; k <- which(ag$h_ml > 150)[1]; s1 <- X$fam_st[[1]]; s3 <- X$fam_st[[k]]; d7 <- s1 - s3; o7 <- names(d7)[order(-abs(d7))]
cat(sprintf("  %.1f m (id %d) lik %.2f vs %.1f m (id %d) lik %.2f: diff %+.2f over %d rows with |d| > 0.5 (largest %s %+.2f; ocean_grad_d13c %+.2f)\n", ag$h_ml[1], ag$id[1], sum(s1), ag$h_ml[k], ag$id[k], sum(s3), sum(s1) - sum(s3), sum(abs(d7) > 0.5), o7[1], d7[[o7[1]]], d7[["ocean_grad_d13c"]]))
for (n in o7[abs(d7[o7]) > 0.5]) cat(sprintf("    %-24s %+7.2f\n", n, d7[[n]]))

V <- function(ok) if (isTRUE(ok)) "PASS" else "FAIL"
i24 <- which(UH_UHS == 24); i18 <- which(UH_UHS == 18)
p1 <- g1[i24] >= UH_P1_BAND24[1] && g1[i24] <= UH_P1_BAND24[2] && g1[i18] >= UH_P1_BAND18[1] && g1[i18] <= UH_P1_BAND18[2]
p2 <- all(diff(hs1) < 0)                        # UH_UHS descends, so HS13 must descend with it
p3 <- all(cn1 >= UH_P3_BAND[1] & cn1 <= UH_P3_BAND[2])
p4 <- all(lp1[-1] < lp1[1]) && (lp1[1] - lp1[i24]) < UH_P4_MAX
p5 <- abs(pr75$g - g1[1]) / g1[1] <= UH_P5_TOL
p6 <- (W$lik - T5$lik) < UH_P6_MAX && R5$top == "ocean_grad_d13c"
p7 <- (W$lik - T6$lik) < UH_P7_MAX && all(abs(R6$d[UH_SINK_BOMB]) < UH_P7_ROW_MAX)
cat("\n  PREDICTIONS (prereg_2026-09-08c_u_hs_h_ml_tests.md):\n")
cat(sprintf("  P1  g_opt at u_hs 24 in [%g, %g] and at 18 in [%g, %g]: %.1f, %.1f  -> %s\n", UH_P1_BAND24[1], UH_P1_BAND24[2], UH_P1_BAND18[1], UH_P1_BAND18[2], g1[i24], g1[i18], V(p1)))
cat(sprintf("  P2  HS d13C falls monotonically with u_hs: %s  -> %s\n", paste(sprintf("%+.2f", hs1), collapse = " > "), V(p2)))
cat(sprintf("  P3  conduit net HD->interior in [%g, %g] at every u_hs: %s  -> %s\n", UH_P3_BAND[1], UH_P3_BAND[2], paste(sprintf("%.2f", cn1), collapse = ", "), V(p3)))
cat(sprintf("  P4  logpost falls below 38 and the loss at 24 < %g: %s (loss at 24 %.1f)  -> %s\n", UH_P4_MAX, paste(sprintf("%.1f", lp1), collapse = ", "), lp1[1] - lp1[i24], V(p4)))
cat(sprintf("  P5  g_opt at h_hs 75 within %.0f %% of 400: %.1f vs %.1f (%+.1f %%)  -> %s\n", 100 * UH_P5_TOL, pr75$g, g1[1], 100 * (pr75$g - g1[1]) / g1[1], V(p5)))
cat(sprintf("  P6  T5 costs < %g and ocean_grad_d13c pays most: cost %.2f, top row %s  -> %s\n", UH_P6_MAX, W$lik - T5$lik, R5$top, V(p6)))
cat(sprintf("  P7  T6 costs < %g and sink/bomb rows move < %g: cost %.2f, moves %s  -> %s\n", UH_P7_MAX, UH_P7_ROW_MAX, W$lik - T6$lik, paste(sprintf("%s %+.2f", UH_SINK_BOMB, R6$d[UH_SINK_BOMB]), collapse = ", "), V(p7)))
p1b <- g1b[i24] >= UH_P1_BAND24[1] && g1b[i24] <= UH_P1_BAND24[2] && all(abs(ratio1b / ratio1b[1] - 1) <= UH_P1B_RATIO_TOL)
cat(sprintf("  P1b [POST-HOC, written after P1 failed] deep-rows-only g_opt at 24 in [%g, %g] and g/u_hs constant to %.0f %%: %.1f; ratios %s  -> %s\n", UH_P1_BAND24[1], UH_P1_BAND24[2], 100 * UH_P1B_RATIO_TOL, g1b[i24], paste(sprintf("%.2f", ratio1b), collapse = ", "), V(p1b)))
cat("\n  ⛔ Nothing adopted. The ruling on u_hs and h_ml is Marcus's.\n")
saveRDS(list(winner = list(id = best$id, logpost = best$logpost, lp_rebuilt = lp0, pm = pm0, W = W[setdiff(names(W), "st")], st = W$st), T1 = T1, T2 = list(h_hs = c(pm0$h_hs, UH_HHS_ALT), g = c(g1[1], pr75$g), lp = c(lp1[1], pr75$lp), S75 = S75),
             T1i = T1i, T1ii = T1ii, T2_0 = S75_0, T5 = T5, T6 = T6, T7 = list(k = k, d = d7, h_ml = c(ag$h_ml[1], ag$h_ml[k])), mld = list(t5_h = UH_T5_H, t6_h = UH_T6_H), preds = c(P1 = p1, P2 = p2, P3 = p3, P4 = p4, P5 = p5, P6 = p6, P7 = p7, P1b_posthoc = p1b), consts = mget(ls(pattern = "^UH_"))), UH_OUT)
cat(sprintf("  saved %s\n", UH_OUT))
