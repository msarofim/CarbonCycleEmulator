# =====================================================================
# T-D0 (handoff 2026-09-08g §1): the LS biological pump under a MARTIN
# remineralisation shape, UNREFITTED, at the canonical hilda31.
#
# WHAT IT DECIDES. Whether option D (Martin-curve remineralisation) lightens
# the deep and gate Q (assessment 09-08f §3.3), and HOW MUCH option C's
# derived entrainment amplitude changes under D -- the C x D interaction
# (handoff §3): C's amplitude is (C_1 - C_ml) x f(month), the sub-mixed-layer
# DIC step, which is set by where the LS pump remineralises.
#
# PRE-REGISTERED (handoff §1): deep d13C falls >= 0.3 permil toward the
# observed deep; gate Q's mean falls; the layer-1 DIC step shrinks by > 25 %.
# FALSIFIED IF: deep d13C unmoved, or the step unchanged.
#
# HOW. ccx_pump_shape() returns the DIC-excess PROFILE (0 at the mixed layer,
# 1 at the bottom) whose diffusive return flux ccx_pump_export() turns into a
# per-layer remineralisation source S_k = -(F_k - F_{k+1}), F_k = K_k dC/dz at
# interface k. So a remineralisation SHAPE is a profile: with the model's OWN
# K(z) (ccx_kz_profile), set the interface flux to Martin's
#   F(z_k) = F(z_s) (z_k / z_s)^(-b),  b = 0.858 (Martin et al. 1987, SOURCED)
# and integrate C(z) = sum F dz / K back to a profile. Two arms beside the
# canonical GLODAP shape: 'martin_tail' keeps GLODAP's profile above the model
# interface nearest TD0_SPLICE_M (GLODAP's shape is FLAT below ~1000 m -- 0.985
# of its span by 1000-1250 m -- which is the '99.5 % above 1000 m' of the
# assessment) and continues with Martin below, flux-continuous at the splice;
# 'martin_full' is Martin from the mixed-layer base down. `pump_grad` -- the
# ML-to-bottom DIC excess -- is the canonical's own in every arm: the SHAPE
# changes, the total gradient does not, so the export E is an OUTPUT.
# ⚠ The handoff's "below the GLODAP profile's span" is moot: the profile
# spans 0-3700 m. 'martin_tail' is the reading that matches its intent.
#
# NOTHING IS ADOPTED. The override lives in this script's session only.
# Usage: Rscript calibration/diag_td0_martin_shape.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R")); source(ccx_path("calibration", "lib_glodap_obs.R"))
try_or <- function(expr, what) tryCatch(expr, error = function(e) { cat(sprintf("  (%s: %s)\n", what, conditionMessage(e))); NULL })

TD0_MARTIN_B  <- 0.858     # Martin et al. 1987 DSR 34:267: F(z) = 1.53 (z/100)^-0.858, r2 0.81, n 48
TD0_SPLICE_M  <- 1000      # 'martin_tail' splices at the model interface nearest this depth
TD0_ARMS      <- c("glodap", "martin_tail", "martin_full")
TD0_P_STEP    <- 0.25      # prediction: layer-1 step SHRINKS by more than this fraction
TD0_P_D13C    <- 0.30      # prediction: deep d13C FALLS by at least this, permil
TD0_DEEP_M    <- 1000      # the 'below 1000 m' export share
TD0_ROW_SHOW  <- 2         # print per-stream deltas with |d logL| above this
TD0_C8_LAT_HI <- 55; TD0_C8_DEEP_M <- 2000; TD0_C8_SURF_M <- 50; TD0_C8_FLAG <- 2   # = diag_hs_endmember_probe.R's bins
TD0_C13_CSV   <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
TD0_OUT <- ccx_path("outputs", "diagnostics", sprintf("td0_martin_shape_%s.rds", format(Sys.Date(), "%Y%m%d")))

# ---- the switchable shape: calibration/lib_martin_shape.R (shared with the kz scan, 09-08h) ----
source(ccx_path("calibration", "lib_martin_shape.R"))
stopifnot(identical(MS_MARTIN_B, TD0_MARTIN_B), identical(MS_SPLICE_M, TD0_SPLICE_M), identical(MS_ARMS, TD0_ARMS))

v   <- dg_vector(CCX_MODE_CANONICAL); MS_P <- v$p
obs <- ccx_prepare_obs()
cat(sprintf("T-D0 at %s (%s, struct '%s'): h_ml %.2f, kz %.0f, kz_deep_frac %.4f, kz_zscale %g, pump_grad %.2f, pump_hs %.1f gC/m2/yr\n",
            CCX_MODE_CANONICAL, basename(v$src %||% ccx_mode_file()), attr(v$p, "struct"), v$p$h_ml, v$p$kz, v$p$kz_deep_frac, v$p$kz_zscale, v$p$pump_grad, v$p$pump_hs_gcm2))

# ---- observation: the deep d13C from the bottles, GENERATED (end-member probe recipe) ----
OBS_DEEP_D13C <- if (file.exists(TD0_C13_CSV)) {
  c13 <- read.csv(TD0_C13_CSV); c13 <- c13[c13$c13f == TD0_C8_FLAG & !is.na(c13$c13), ]
  deep <- c13$c13[c13$depth > TD0_C8_DEEP_M]; hi <- c13$c13[c13$depth <= TD0_C8_SURF_M & abs(c13$lat) >= TD0_C8_LAT_HI]
  list(deep_mean = mean(deep), deep_median = stats::median(deep), deep_sd = stats::sd(deep), deep_n = length(deep),
       hi_mean = mean(hi), hi_n = length(hi))
} else NULL
if (!is.null(OBS_DEEP_D13C)) cat(sprintf("GLODAP bottles (flag %d): deep > %d m d13C mean %+.3f median %+.3f sd %.3f n %d; high-lat (|lat| >= %d) surface <= %d m mean %+.3f n %d\n",
  TD0_C8_FLAG, TD0_C8_DEEP_M, OBS_DEEP_D13C$deep_mean, OBS_DEEP_D13C$deep_median, OBS_DEEP_D13C$deep_sd, OBS_DEEP_D13C$deep_n, TD0_C8_LAT_HI, TD0_C8_SURF_M, OBS_DEEP_D13C$hi_mean, OBS_DEEP_D13C$hi_n)) else cat("(bottle CSV absent: observed deep d13C not generated)\n")
MLD <- readRDS(ccx_path("data", "obs_mld.rds"))$seasonal

# ---- the reads ------------------------------------------------------------
box_read <- function(sp) {
  aux <- sp$aux; g <- sp$grid; y <- sp$y; rho <- ccx_const("RHO_SEAWATER")
  d13 <- function(i) 1000 * (sum(y[i, "C13"]) / sum(y[i, "C"]) / ccx_const("R13_VPDB") - 1)
  zt <- cumsum(g$dz)[seq_len(g$nl)]; zb <- cumsum(g$dz)[-1]
  setNames(lapply(HEMIS, function(h) { i <- aux$idx[[h]]
    conc <- function(ii, m) y[ii, "C"] * aux$mol_per_GtC / m * 1e6
    S <- aux$pump[[h]]$org + aux$pump[[h]]$carb
    frac_below <- pmin(pmax((zb - TD0_DEEP_M) / (zb - zt), 0), 1)
    list(ml = conc(i$ml, aux$ml_mass_kg[[h]]), int = conc(i$oc, aux$a_ls[[h]] * g$dz[-1] * rho),
         hs = conc(i$hs, aux$hs_mass_kg[[h]]), hd = conc(i$hd, aux$a_hs[[h]] * aux$dz_hd * rho),
         d13_ml = d13(i$ml), d13_int = vapply(i$oc, d13, numeric(1)), d13_hs = d13(i$hs), d13_hd = d13(i$hd),
         S = S, E = sum(S), E_below = sum(S * frac_below), zt = zt, zb = zb)
  }), HEMIS)
}
amp_C <- function(B, h) {           # option C's derived amplitude, the options-note recipe (half the f swing x the step)
  f <- MLD[[h]]$f_ent; sw <- (max(f) - min(f)) / 2
  d1 <- unname(B[[h]]$int[1] - B[[h]]$ml); d2 <- unname(B[[h]]$int[2] - B[[h]]$ml)   # the state matrix carries row names
  c(step1 = d1, step2 = d2, f_swing_half = sw, amp_lo = sw * d1, amp_hi = sw * (d1 + d2) / 2)
}
tg7 <- dg_gcb_target(DG_SINK_WIN)
read_arm <- function(arm) {
  MS_ARM <<- arm
  r <- dg_run(v)
  stopifnot(isTRUE(all.equal(diff(r$sp$grid$depth_mid), r$sp$aux$dz_mid)))
  B  <- box_read(r$sp)
  st <- dg_streams(r, v)
  q  <- dg_gateQ(r, v)
  gG <- try_or({ gr <- ccx_ocean_grid(v$p$h_ml); og <- dg_gateG_obs(gr); dg_gateG_verdict(dg_gateG(v, og), og) }, paste("gate G", arm))
  g7v <- dg_gate7(r); g7 <- c(g7v[c("ocean", "land")], dg_gate7_verdict(g7v, tg7))
  hs <- ccx_hs_surface_scored(r$out, r$sp)
  E_hs <- sum(unlist(lapply(HEMIS, function(h) r$sp$aux$pump_hs[[h]]$org + r$sp$aux$pump_hs[[h]]$carb)))
  list(arm = arm, shape = ccx_pump_shape(r$sp$grid), B = B, st = st, lik = sum(unlist(st)), Q = q, G = gG, g7 = g7, hs = hs, E_hs = E_hs,
       amp = list(NH = amp_C(B, "NH"), SH = amp_C(B, "SH")))
}
RES <- setNames(lapply(TD0_ARMS, read_arm), TD0_ARMS); MS_ARM <- "glodap"

# ---- report ---------------------------------------------------------------
G0 <- RES$glodap
cat(sprintf("\n=== 1. THE SHAPES (DIC-excess profile, 0 at ML, 1 at the bottom) and the export they imply (SH) ===\n"))
cat(sprintf("  %-14s", "layer (m)")); for (a in TD0_ARMS) cat(sprintf(" %10s %8s", a, "S GtC/yr")); cat("\n")
zt <- G0$B$SH$zt; zb <- G0$B$SH$zb
for (k in seq_along(zt)) { cat(sprintf("  %5.0f-%-8.0f", zt[k], zb[k])); for (a in TD0_ARMS) cat(sprintf(" %10.4f %8.3f", RES[[a]]$shape[k + 1], RES[[a]]$B$SH$S[k])); cat("\n") }
for (a in TD0_ARMS) cat(sprintf("  %-12s export NH %.2f + SH %.2f = %.2f GtC/yr; below %d m %.2f GtC/yr (%.1f %%); HS pump (unchanged) %.2f GtC/yr\n", a,
  RES[[a]]$B$NH$E, RES[[a]]$B$SH$E, RES[[a]]$B$NH$E + RES[[a]]$B$SH$E, TD0_DEEP_M, RES[[a]]$B$NH$E_below + RES[[a]]$B$SH$E_below,
  100 * (RES[[a]]$B$NH$E_below + RES[[a]]$B$SH$E_below) / (RES[[a]]$B$NH$E + RES[[a]]$B$SH$E), RES[[a]]$E_hs))

cat("\n=== 2. THE PREINDUSTRIAL COLUMN, by arm (umol/kg; d13C permil) ===\n")
cat(sprintf("  %-12s %7s %7s %7s %7s %7s | %7s %7s %7s %7s %7s | %8s %8s\n", "arm", "ML", "L1", "L2", "L10", "HS/HD", "d13 ML", "d13 L1", "d13 L10", "d13 HS", "d13 HD", "step1", "step2"))
for (a in TD0_ARMS) for (h in HEMIS) { b <- RES[[a]]$B[[h]]
  cat(sprintf("  %-9s %s %7.0f %7.0f %7.0f %7.0f %3.0f/%-4.0f | %+7.2f %+7.2f %+7.2f %+7.2f %+7.2f | %+8.1f %+8.1f\n", a, h, b$ml, b$int[1], b$int[2], b$int[10], b$hs, b$hd,
              b$d13_ml, b$d13_int[1], b$d13_int[10], b$d13_hs, b$d13_hd, b$int[1] - b$ml, b$int[2] - b$ml)) }

cat("\n=== 3. OPTION C's DERIVED AMPLITUDE under each shape (the C x D interaction; umol/kg) ===\n")
for (a in TD0_ARMS) for (h in HEMIS) { z <- RES[[a]]$amp[[h]]
  cat(sprintf("  %-12s %s step1 %+6.1f step2 %+6.1f  half-swing %.3f  amplitude [%.1f, %.1f]%s\n", a, h, z[["step1"]], z[["step2"]], z[["f_swing_half"]], z[["amp_lo"]], z[["amp_hi"]],
              if (a == "glodap") "" else sprintf("  (step1 %+.0f %%, amplitude %+.0f %%)", 100 * (z[["step1"]] / G0$amp[[h]][["step1"]] - 1), 100 * (z[["amp_lo"]] / G0$amp[[h]][["amp_lo"]] - 1)))) }

cat("\n=== 4. GATES and the HS surface rows ===\n")
for (a in TD0_ARMS) { R <- RES[[a]]
  cat(sprintf("  %-12s GATE Q mean %+.3f (NH %+.3f SH %+.3f) n_sd %.2f %s | GATE G z %+.2f %s | GATE 7 ocean %.2f land %.2f %s | HS surf DIC %.0f (obs %g, z %+.2f) d13C %+.2f (obs %g, z %+.2f)\n", a,
    R$Q$mean, R$Q$by_hemi[["NH"]], R$Q$by_hemi[["SH"]], R$Q$n_sd, if (R$Q$pass) "PASS" else "FAIL",
    if (is.null(R$G)) NA else R$G$z, if (is.null(R$G)) "n/a" else if (R$G$pass) "PASS" else "FAIL",
    R$g7$ocean, R$g7$land, if (R$g7$pass) "PASS" else "FAIL",
    R$hs$dic, ccx_hs_surface_target()$dic$target, (R$hs$dic - ccx_hs_surface_target()$dic$target) / R$hs$sd_eff[["dic"]],
    R$hs$d13c, ccx_hs_surface_target()$d13c$target, (R$hs$d13c - ccx_hs_surface_target()$d13c$target) / R$hs$sd_eff[["d13c"]])) }

cat(sprintf("\n=== 5. LIKELIHOOD by stream (rows with |d| > %g vs glodap) ===\n", TD0_ROW_SHOW))
for (a in TD0_ARMS[-1]) { d <- unlist(RES[[a]]$st) - unlist(G0$st)
  cat(sprintf("  %-12s total %+.2f: ", a, RES[[a]]$lik - G0$lik)); for (n in names(d)[order(-abs(d))][abs(sort(-abs(d))) > TD0_ROW_SHOW]) cat(sprintf("%s %+.1f; ", n, d[[n]])); cat("\n") }

cat("\n=== 6. VERDICT against the pre-registered predictions ===\n")
deep_of <- function(R) mean(c(R$B$NH$d13_int[10], R$B$SH$d13_int[10]))   # the bottom LS layer, both hemispheres
hd_of   <- function(R) mean(c(R$B$NH$d13_hd, R$B$SH$d13_hd))
V <- list()
for (a in TD0_ARMS[-1]) { R <- RES[[a]]
  dd <- deep_of(R) - deep_of(G0); dhd <- hd_of(R) - hd_of(G0); dq <- R$Q$mean - G0$Q$mean
  ds <- mean(c(R$amp$NH[["step1"]] / G0$amp$NH[["step1"]], R$amp$SH[["step1"]] / G0$amp$SH[["step1"]])) - 1
  p1 <- dd <= -TD0_P_D13C; p2 <- dq < 0; p3 <- ds < -TD0_P_STEP
  V[[a]] <- c(d_deep_d13c = dd, d_hd_d13c = dhd, d_Q = dq, d_step1_frac = ds, P1 = p1, P2 = p2, P3 = p3)
  cat(sprintf("  %-12s deep (bottom LS) d13C %+.2f -> %+.2f (%+.2f; HD %+.2f -> %+.2f)%s  P1 (>= %.2f fall) %s | Q %.3f -> %.3f P2 (falls) %s | step1 %+.0f %%  P3 (< -%.0f %%) %s | lik %+.1f\n", a,
              deep_of(G0), deep_of(R), dd, hd_of(G0), hd_of(R), if (is.null(OBS_DEEP_D13C)) "" else sprintf(" vs obs deep %+.2f", OBS_DEEP_D13C$deep_mean), TD0_P_D13C, if (p1) "CONFIRMED" else "FALSIFIED",
              G0$Q$mean, R$Q$mean, if (p2) "CONFIRMED" else "FALSIFIED", 100 * ds, 100 * TD0_P_STEP, if (p3) "CONFIRMED" else "FALSIFIED", R$lik - G0$lik)) }
cat("  C x D: the handoff's rule is that a step change > 25 % makes C and D ONE refit.\n")
saveRDS(list(arms = RES, verdict = V, obs_deep_d13c = OBS_DEEP_D13C, consts = list(b = TD0_MARTIN_B, splice_m = TD0_SPLICE_M, p_step = TD0_P_STEP, p_d13c = TD0_P_D13C), mode = CCX_MODE_CANONICAL, date = Sys.time()), TD0_OUT)
cat(sprintf("\nsaved %s\n⛔ Nothing adopted. The Martin shape lives in this session's override only.\n", TD0_OUT))
