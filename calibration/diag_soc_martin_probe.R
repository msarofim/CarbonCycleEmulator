# =====================================================================
# diag_soc_martin_probe.R -- THE SOUTHERN OCEAN ONE-PASS WINDOW (option
# B-minimal) PROBED UNDER THE MARTIN FIELD,
# notes/prereg_2026-09-21e_so_window_probe.md §3-5. Unrefitted at the
# canonical (hilda29l), C++ objective under the file's pins.
#   The window: w_soc [Sv, SH ONLY] -- SH interior layer k_soc_up (CDW) ->
#   HD_SH -> HS_SH (the outcrop) -> SH interior layer k_soc_dn (the return
#   AT DEPTH; never the ML), the SH column's interior transport k_dn -> k_up
#   closing the volume. hs_h_fac_SH thins the SH cold box (the pass length
#   a_hs h_hs / W without the volume). Built for the SO SURFACE -- the SH
#   cold box's D (+0.14 vs the bottles' -1.06), hs_surf_d13c, the SO
#   surface's age -- explicitly NOT for gate D's asymmetry (NH-side, 09-21 c).
#   Stage 1  RAW: W x (k_up, k_dn) x fac, one C++ run each; per point the four
#            regional D's, GATE Q, the 26-row dlik vs the canonical with the
#            named rows, the MLO-SPO D14C (2001-2007), the d13C gradient
#            residual, the cold boxes' and the SH bottom's PI D14C, the pass
#            residence, the spinup residual.
#   Stage 2  ARM C (T1's 11-name set: the PK-2 eight + u_hs, pump_hs_gcm2,
#            h_hs) at W = 0 (each fac) and the best RAW W per (k_dn, fac)
#            (selection by raw dlik, stated).
#   The reject rule (prereg §5) is evaluated and printed; nothing adopted.
# Usage: Rscript calibration/diag_soc_martin_probe.R      (SP_SMOKE=1 for a 3-point smoke)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
SP_ARM     <- CCX_MODE_CANONICAL
SP_EXPORT  <- ccx_pump_export_prior()$centre_gtc          # 9.08, Nowicki's LS median -- READ, not typed
SP_W       <- c(0, 5, 10, 15, 20, 30)                      # Sv, the SH window's volume
SP_GEO     <- list(c(8L, 10L), c(8L, 6L))                  # (k_up, k_dn): CDW (1302-1852 m) in; the AABW (bottom) / AAIW (628-909 m) return
SP_FAC     <- c(1, 1/3)                                    # hs_h_fac_SH: the SH cold box at h_hs / a third of it (the short pass)
SP_LAND    <- c("beta_max", "fert_k", "q10")
SP_SURF    <- c("kz_deep_frac", "h_ml", "k_w", "bomb_total", "sigma_d14c")
SP_VENT    <- c("u_hs", "pump_hs_gcm2", "h_hs")            # T1's set: the HILDA ventilation free beside the window (they overlap by construction)
SP_ARMC    <- c(SP_LAND, SP_SURF, SP_VENT)
SP_NM_MAXIT <- 1500; SP_BFGS_MAXIT <- 100
SP_GATE_TOL <- 1e-4                                       # harness gate: rebuilt logpost vs stored
SP_GTHC_RDS <- ccx_path("outputs", "diagnostics", "gthc_martin_probe_20260920.rds")   # the loop probe's W = 0 point: the SAME frame at the SAME canonical -> asserted equal
SP_D14C_VAL <- ccx_path("data", "obs_d14c_station_validation.rds")   # held-out MLO + SPO monthly, 2001+
SP_D14C_YEARS <- 2001:2007
SP_P1_MIN_FALL <- 0.3; SP_P1_W <- 15                        # prereg P1: the SH cold box's D falls by >= 0.3 at W = 15
SP_P2_ML_TOL <- 0.05                                       # prereg P2: the SH ML's D within 0.05 of its W = 0 value (else a BUG)
SP_P3_MIN_AGE <- 20                                        # prereg P3: the SH cold box's PI D14C falls by >= 20 permil at W = 15
SP_P4_MIN_FALL <- 0.3                                      # prereg P4: SH hs d13C (1995) falls by >= 0.3 at W = 15
SP_P6_TOL <- 0.005                                         # prereg P6: the residual within +-0.005 of W = 0
SP_P7_FREE <- -10; SP_P7_DEAD_W <- 20                      # prereg P7: the profile rows within -10 of W = 0; dead as a class if no W <= 20 is free
SP_SMOKE   <- nzchar(Sys.getenv("SP_SMOKE", ""))
SP_STAGE1  <- nzchar(Sys.getenv("SP_STAGE1", ""))          # stage 1 only (seconds): the raw grid and the predictions, no arm C, no verdict
if (SP_SMOKE) { SP_W <- c(0, 15); SP_GEO <- list(c(8L, 10L)); SP_FAC <- c(1, 1/3); SP_NM_MAXIT <- 20; SP_BFGS_MAXIT <- 5 }
SP_OUT     <- ccx_path("outputs", "diagnostics", sprintf("soc_martin_probe_%s%s%s", format(Sys.Date(), "%Y%m%d"), if (SP_STAGE1) "_stage1" else "", if (SP_SMOKE) "_smoke" else ""))
sink_log <- file(paste0(SP_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)
SP_COMMIT <- if (file.exists("FROZEN_FROM_COMMIT.txt")) substr(trimws(readLines("FROZEN_FROM_COMMIT.txt")[1]), 1, 7) else   # a frozen copy has no .git
             tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")
cat(sprintf("== SOUTHERN OCEAN WINDOW, martin probe at %s (prereg 2026-09-21e) -- commit %s, %s ==\n", SP_ARM, SP_COMMIT, format(Sys.time())))
cat(sprintf("export %.2f GtC/yr (martin); W %s Sv x geometry %s x fac %s; arm C = %s\n\n", SP_EXPORT,
            paste(SP_W, collapse = "/"), paste(vapply(SP_GEO, function(g) sprintf("(%d,%d)", g[1], g[2]), ""), collapse = "/"),
            paste(format(SP_FAC, digits = 3), collapse = "/"), paste(SP_ARMC, collapse = ",")))

# ---- the observations the reads use (READ, never typed) ---------------
obs <- ccx_prepare_obs(); do_D <- dg_gateD_obs()
d14v <- as.data.frame(readRDS(SP_D14C_VAL)); a14 <- aggregate(d14c ~ station + year, d14v[d14v$year %in% SP_D14C_YEARS, ], mean)
w14 <- reshape(a14, idvar = "year", timevar = "station", direction = "wide"); w14 <- w14[complete.cases(w14), ]
OBS_D14_MLO_SPO <- mean(w14$d14c.MLO - w14$d14c.SPO); OBS_D14_SD <- sd(w14$d14c.MLO - w14$d14c.SPO)
cat(sprintf("obs: gate D asym %+.3f +- %.3f (NH ml %+.2f hs %+.2f, SH ml %+.2f hs %+.2f); gate Q %.2f +- %.2f; MLO-SPO D14C %d-%d %+.2f +- %.2f permil (n %d)\n\n",
            do_D$asym, do_D$asym_se, do_D$region$NH_ml$mean, do_D$region$NH_hs$mean, do_D$region$SH_ml$mean, do_D$region$SH_hs$mean,
            DG_Q_OBS, DG_Q_SD, min(w14$year), max(w14$year), OBS_D14_MLO_SPO, OBS_D14_SD, nrow(w14)))

# ---- stage 1 machinery: the dg path (p directly; exact zeros) ----------
v0 <- dg_vector(SP_ARM); md <- v0$md
r_ref <- dg_run(v0); ref <- unlist(dg_streams(r_ref, v0))
cat(sprintf("HARNESS GATE 1: dg streams at the canonical vs stored: sum %.4f vs %.4f -> %s\n", sum(ref[names(md$streams)]), sum(md$streams),
            if (abs(sum(ref[names(md$streams)]) - sum(md$streams)) < SP_GATE_TOL) "PASS" else "FAIL"))
if (abs(sum(ref[names(md$streams)]) - sum(md$streams)) >= SP_GATE_TOL) stop("harness gate 1 failed")
gD_ref <- dg_gateD_verdict(dg_gateD(r_ref, v0)); gQ_ref <- dg_gateQ(r_ref, v0)
mg <- function(mod, years) mod$MLO$level[match(years, mod$MLO$year)] - mod$SPO$level[match(years, mod$SPO$year)]
grad_resid <- function(out) {   # diag_d13c_gradient_offset.R s1's estimator: mean over the overlap years of model MLO-SPO d13C minus observed
  ms <- ccx_model_stats(out, obs); g <- obs$d13c_grad; mean(mg(ms$d13, g$year) - g$grad, na.rm = TRUE) }
d14_mlo_spo <- function(out) { yr <- floor(out$t + 1e-9); mean(vapply(SP_D14C_YEARS, function(Y) mean((out$d14c_NH - out$d14c_SH)[yr == Y]), 0)) }
d13_hs <- function(out, h, Y = DG_Q_YEAR) { yr <- floor(out$t + 1e-9); j <- yr == Y
  mean(1000 * (out[[paste0("hs_C13_", h)]][j] / (out[[paste0("hs_C_", h)]][j] * ccx_const("R13_VPDB")) - 1)) }
pi_d14 <- function(sp, i) 1000 * (sp$y[i, "C14"] / sp$y[i, "C"] - 1)
cat(sprintf("canonical (solved): gate D asym %+.3f z %+.2f [NH ml %+.2f hs %+.2f | SH ml %+.2f hs %+.2f]; gate Q %.3f n_sd %.2f; MLO-SPO D14C %+.2f; d13C grad resid %+.4f; hs d13C NH %.2f SH %.2f; PI D14C hs %+.0f/%+.0f, SH bottom %+.0f\n\n",
            gD_ref$asym, gD_ref$z, gD_ref$region[["NH_ml"]], gD_ref$region[["NH_hs"]], gD_ref$region[["SH_ml"]], gD_ref$region[["SH_hs"]],
            gQ_ref$mean, gQ_ref$n_sd, d14_mlo_spo(r_ref$out), grad_resid(r_ref$out), d13_hs(r_ref$out, "NH"), d13_hs(r_ref$out, "SH"),
            pi_d14(r_ref$sp, r_ref$sp$aux$idx$NH$hs), pi_d14(r_ref$sp, r_ref$sp$aux$idx$SH$hs), pi_d14(r_ref$sp, r_ref$sp$aux$idx$SH$oc[r_ref$sp$grid$nl])))
point_p <- function(W, ku, kd, fac) {
  v <- v0; p <- v$p
  p$pump_field <- "martin"; p$pump_export <- SP_EXPORT
  p$gamma_enso_ocn_NH <- 0; p$gamma_enso_ocn_SH <- 0; p$gamma_vent <- 0; p$w_vent <- 0; p$w_thc <- 0; p$w_gthc <- 0
  p$w_soc <- W; p$k_soc_up <- ku; p$k_soc_dn <- kd; p$hs_h_fac_SH <- fac
  v$p <- p; v
}
read_point <- function(v) {
  r <- dg_run(v); sp <- r$sp; out <- r$out
  stv <- unlist(dg_streams(r, v)); cm <- intersect(names(stv), names(ref)); d <- stv[cm] - ref[cm]
  gD <- dg_gateD_verdict(dg_gateD(r, v)); gQ <- dg_gateQ(r, v)
  rows <- function(pat) sum(d[grep(pat, cm)])
  spin_resid <- if (!is.null(sp$periodic)) sp$periodic$resid_carbon else NA_real_
  W <- v$p$w_soc * CCX_SV_TO_M3YR
  list(d = d, dlik = sum(d), gD = gD, gQ = gQ, d14 = d14_mlo_spo(out), resid = grad_resid(out),
       hs13 = c(NH = d13_hs(out, "NH"), SH = d13_hs(out, "SH")), spin_resid = spin_resid,
       bomb = rows("^d14c_(NH|SH)$"), co2 = rows("^co2"), d14prof = rows("^d14c_(profile|deep)"), d13 = rows("^d13c"),
       hs_rows = c(d13 = unname(d["hs_surf_d13c"]), dic = unname(d["hs_surf_dic"])), grad_rows = rows("^ocean_grad"), exc = unname(d["excess_c14_ocean"]),
       hs14 = vapply(HEMIS, function(h) pi_d14(sp, sp$aux$idx[[h]]$hs), 0),           # the cold boxes' PI D14C
       bot14 = pi_d14(sp, sp$aux$idx$SH$oc[sp$grid$nl]),                              # the SH bottom layer's PI D14C (the pre-check's number)
       col13 = { d13 <- function(i) 1000 * (sp$y[i, "C13"] / (sp$y[i, "C"] * ccx_const("R13_VPDB")) - 1)
                 c(hs = d13(sp$aux$idx$SH$hs), hd = d13(sp$aux$idx$SH$hd), k6 = d13(sp$aux$idx$SH$oc[6]), k8 = d13(sp$aux$idx$SH$oc[8]), k10 = d13(sp$aux$idx$SH$oc[10])) },   # the SH column's PI d13C
       col14 = c(hd = pi_d14(sp, sp$aux$idx$SH$hd), k6 = pi_d14(sp, sp$aux$idx$SH$oc[6]), k8 = pi_d14(sp, sp$aux$idx$SH$oc[8]), k10 = pi_d14(sp, sp$aux$idx$SH$oc[10]),
                 NHbot = pi_d14(sp, sp$aux$idx$NH$oc[sp$grid$nl])),                     # the SH column the window touches, PI D14C (recirculation vs remote water)
       pass = if (W > 0) sp$aux$a_hs$SH * sp$aux$thick_hs$SH / W else NA_real_,       # yr, the cold box's residence under the window alone
       h_hs_SH = sp$aux$thick_hs$SH, substeps = ccx_substeps_for(v$p))
}
fmt <- function(lab, rp) sprintf("%-16s | dlik %+8.1f | D asym %+.3f z %+5.2f [NHml %+.2f NHhs %+.2f | SHml %+.2f SHhs %+.2f] | Q %.3f n_sd %.2f | hs13 %.2f/%.2f | resid %+.4f | D14 %+.2f | rows: co2 %+6.1f bomb %+5.1f d14prof %+6.1f d13 %+5.1f hs %+5.1f/%+5.1f grad %+5.1f exc %+5.1f | PI D14C hs %+.0f/%+.0f SH hd %+.0f k6 %+.0f k8 %+.0f bot %+.0f NHbot %+.0f | PI d13C SH hs %.2f hd %.2f k6 %.2f k8 %.2f bot %.2f | pass %s yr h_hs,SH %.0f ss %d%s",
                                lab, rp$dlik, rp$gD$asym, rp$gD$z, rp$gD$region[["NH_ml"]], rp$gD$region[["NH_hs"]], rp$gD$region[["SH_ml"]], rp$gD$region[["SH_hs"]],
                                rp$gQ$mean, rp$gQ$n_sd, rp$hs13[["NH"]], rp$hs13[["SH"]], rp$resid, rp$d14,
                                rp$co2, rp$bomb, rp$d14prof, rp$d13, rp$hs_rows[["d13"]], rp$hs_rows[["dic"]], rp$grad_rows, rp$exc, rp$hs14[["NH"]], rp$hs14[["SH"]], rp$col14[["hd"]], rp$col14[["k6"]], rp$col14[["k8"]], rp$bot14, rp$col14[["NHbot"]],
                                rp$col13[["hs"]], rp$col13[["hd"]], rp$col13[["k6"]], rp$col13[["k8"]], rp$col13[["k10"]],
                                if (is.finite(rp$pass)) sprintf("%.1f", rp$pass) else "-", rp$h_hs_SH, rp$substeps,
                                if (is.finite(rp$spin_resid) && rp$spin_resid >= PS_TOL) sprintf(" | SPINUP NOT CONVERGED resid %.1e", rp$spin_resid) else "")

# HARNESS GATES 2/3: the layers inert at W = 0 (each fac); the martin / W = 0 / fac 1 point equals the loop probe's
G0 <- lapply(SP_FAC, function(fac) read_point(point_p(0, SP_GEO[[1]][1], SP_GEO[[1]][2], fac))); names(G0) <- format(SP_FAC, digits = 3)
g0alt <- read_point(point_p(0, 3L, 6L, SP_FAC[1]))
cat(sprintf("HARNESS GATE 2: (k_up, k_dn) inert at W = 0 ((8,10) vs (3,6), fac 1): %.2e -> %s\n", max(abs(G0[[1]]$d - g0alt$d)), if (max(abs(G0[[1]]$d - g0alt$d)) < 1e-9) "PASS" else "FAIL"))
if (max(abs(G0[[1]]$d - g0alt$d)) >= 1e-9) stop("harness gate 2 failed")
if (file.exists(SP_GTHC_RDS)) {
  gx <- readRDS(SP_GTHC_RDS); g0_loop <- gx$tab1$dlik[gx$tab1$W == 0][1]
  cat(sprintf("HARNESS GATE 3: martin / W = 0 / fac 1 dlik %+.4f vs the loop probe's W = 0 %+.4f (same frame, same canonical %s): %.1e -> %s\n",
              G0[[1]]$dlik, g0_loop, gx$canonical, abs(G0[[1]]$dlik - g0_loop), if (abs(G0[[1]]$dlik - g0_loop) < 1e-6) "PASS" else "FAIL"))
  if (abs(G0[[1]]$dlik - g0_loop) >= 1e-6) stop("harness gate 3 failed: the frame is not the loop probe's")
} else cat("HARNESS GATE 3: the loop probe's rds is absent -- not asserted\n")
for (i in seq_along(SP_FAC)) cat(fmt(sprintf("W0 fac%s", names(G0)[i]), G0[[i]]), "\n")
cat(sprintf("(the thin cold box ALONE, W = 0: fac %s costs %+.1f vs fac 1 -- its own price, before any window)\n\n",
            names(G0)[length(G0)], G0[[length(G0)]]$dlik - G0[[1]]$dlik))

# ---- stage 1: the grid -------------------------------------------------
grid1 <- expand.grid(W = SP_W, geo = seq_along(SP_GEO), fac = SP_FAC)
grid1$ku <- vapply(grid1$geo, function(i) SP_GEO[[i]][1], 1L); grid1$kd <- vapply(grid1$geo, function(i) SP_GEO[[i]][2], 1L)
grid1 <- grid1[!(grid1$W == 0 & grid1$geo != 1), ]   # W = 0 once per fac
cat(sprintf("== STAGE 1: %d points ==\n", nrow(grid1)))
S1 <- vector("list", nrow(grid1)); t_all <- proc.time()[["elapsed"]]
for (i in seq_len(nrow(grid1))) {
  g1 <- grid1[i, ]; lab <- sprintf("W%-2g (%d,%d) f%s", g1$W, g1$ku, g1$kd, format(g1$fac, digits = 3))
  rp <- if (g1$W == 0) G0[[match(g1$fac, SP_FAC)]] else tryCatch(read_point(point_p(g1$W, g1$ku, g1$kd, g1$fac)), error = function(e) { cat(sprintf("%-16s | FAILED: %s\n", lab, conditionMessage(e))); NULL })
  if (!is.null(rp)) { cat(fmt(lab, rp), "\n"); S1[[i]] <- rp }
}
cat(sprintf("stage 1 done in %.0f s\n\n", proc.time()[["elapsed"]] - t_all))
tab1 <- cbind(grid1, do.call(rbind, lapply(S1, function(r) if (is.null(r)) data.frame(dlik = NA, D_asym = NA, D_z = NA, SHhs = NA, SHml = NA, NHhs = NA, Q_nsd = NA, resid = NA, d14 = NA, hs14_SH = NA, bot14 = NA, hs13_SH = NA, d14prof = NA, co2 = NA, pass = NA)
  else data.frame(dlik = r$dlik, D_asym = r$gD$asym, D_z = r$gD$z, SHhs = r$gD$region[["SH_hs"]], SHml = r$gD$region[["SH_ml"]], NHhs = r$gD$region[["NH_hs"]], Q_nsd = r$gQ$n_sd, resid = r$resid, d14 = r$d14,
                  hs14_SH = r$hs14[["SH"]], bot14 = r$bot14, hs13_SH = r$hs13[["SH"]], d14prof = r$d14prof, co2 = r$co2, pass = r$pass))))
print(tab1[, setdiff(names(tab1), "geo")], digits = 4, row.names = FALSE)

# ---- P1-P8 from stage 1 --------------------------------------------------
cat("\n== THE PREDICTIONS (prereg s5), stage 1 -- every W > 0 point read RELATIVE to W = 0 at the SAME fac ==\n")
for (fac in SP_FAC) for (gi in seq_along(SP_GEO)) {
  ku <- SP_GEO[[gi]][1]; kd <- SP_GEO[[gi]][2]; tag <- sprintf("(%d,%d) fac %s", ku, kd, format(fac, digits = 3))
  s <- tab1[tab1$fac == fac & (tab1$geo == gi | tab1$W == 0), ]; s <- s[order(s$W), ]; b0 <- s[s$W == 0, ]
  if (nrow(b0) != 1) next
  p1 <- s[s$W == SP_P1_W, ]; has15 <- nrow(p1) == 1
  fall <- if (has15) b0$SHhs - p1$SHhs else NA
  cat(sprintf("%s P1: SH hs D by W: %s -> %s; fall at W %g = %.3f (>= %.1f: %s); NH hs D moves %s\n", tag,
              paste(sprintf("%+.2f", s$SHhs), collapse = " "), if (all(diff(s$SHhs) < 0)) "MONOTONE FALL" else "NOT monotone", SP_P1_W, fall,
              SP_P1_MIN_FALL, if (is.finite(fall) && fall >= SP_P1_MIN_FALL) "HOLDS" else "FAILS -> inert on its target",
              paste(sprintf("%+.3f", s$NHhs - b0$NHhs), collapse = " ")))
  ml_mv <- s$SHml - b0$SHml
  cat(sprintf("%s P2: SH ml D moves by W: %s (within %.2f everywhere: %s)\n", tag, paste(sprintf("%+.3f", ml_mv), collapse = " "), SP_P2_ML_TOL,
              if (all(abs(ml_mv) <= SP_P2_ML_TOL)) "yes -- the ML is not in the cell" else "NO -> a misrouted leg, a BUG before a finding"))
  cat(sprintf("%s P3: SH hs PI D14C by W: %s (falls >= %g at W %g: %s); MLO-SPO D14C by W: %s (obs %+.2f +- %.2f; moves POSITIVE: %s)\n", tag,
              paste(sprintf("%+.0f", s$hs14_SH), collapse = " "), SP_P3_MIN_AGE, SP_P1_W,
              if (has15 && (b0$hs14_SH - p1$hs14_SH) >= SP_P3_MIN_AGE) "HOLDS" else "FAILS",
              paste(sprintf("%+.2f", s$d14), collapse = " "), OBS_D14_MLO_SPO, OBS_D14_SD, if (all(diff(s$d14) > 0)) "yes, monotone" else if (has15 && p1$d14 > b0$d14) "at W 15" else "NO"))
  cat(sprintf("%s P4: SH hs d13C (1995) by W: %s (target 1.31; falls >= %.1f at W %g: %s); hs_surf_d13c row dlik: %s\n", tag,
              paste(sprintf("%.2f", s$hs13_SH), collapse = " "), SP_P4_MIN_FALL, SP_P1_W, if (has15 && (b0$hs13_SH - p1$hs13_SH) >= SP_P4_MIN_FALL) "HOLDS" else "FAILS",
              paste(sprintf("%+.1f", vapply(seq_len(nrow(s)), function(i) { r <- S1[[which(grid1$W == s$W[i] & grid1$fac == fac & (grid1$geo == gi | grid1$W == 0))[1]]]; r$hs_rows[["d13"]] }, 0)), collapse = " ")))
  cat(sprintf("%s P5: gate D asym by W: %s; z: %s (predicted NOT to improve; improves by > 1: %s)\n", tag,
              paste(sprintf("%+.3f", s$D_asym), collapse = " "), paste(sprintf("%+.2f", s$D_z), collapse = " "),
              if (any(abs(s$D_z[-1]) < abs(b0$D_z) - 1)) "YES -> contradicts the 09-21 c ruling, a finding to chase" else "no, as predicted"))
  cat(sprintf("%s P6: d13C gradient residual by W: %s (W0 %+.4f; within +-%.3f everywhere: %s)\n", tag,
              paste(sprintf("%+.4f", s$resid), collapse = " "), b0$resid, SP_P6_TOL, if (all(abs(s$resid - b0$resid) <= SP_P6_TOL)) "yes, flat as predicted" else "NO"))
  free <- s$W[s$W > 0 & (s$d14prof - b0$d14prof) >= SP_P7_FREE]
  cat(sprintf("%s P7: d14c profile + deep rows dlik by W: %s (rel. W0: %s); SH bottom PI D14C: %s (target -175); free (>= %g) at W: %s\n", tag,
              paste(sprintf("%+.1f", s$d14prof), collapse = " "), paste(sprintf("%+.1f", s$d14prof - b0$d14prof), collapse = " "),
              paste(sprintf("%+.0f", s$bot14), collapse = " "), SP_P7_FREE, if (length(free)) paste(free, collapse = ",") else "NONE"))
  cat(sprintf("%s P8: gate Q n_sd by W: %s (predicted to worsen or stay)\n\n", tag, paste(sprintf("%.2f", s$Q_nsd), collapse = " ")))
}
# P7's fac contrast: at every W the fac-1/3 point is predicted CHEAPER on the deep rows than the fac-1 point (the short pass returns older water)
if (length(SP_FAC) == 2) for (gi in seq_along(SP_GEO)) {
  a <- tab1[tab1$fac == SP_FAC[1] & tab1$geo == gi & tab1$W > 0, ]; b <- tab1[tab1$fac == SP_FAC[2] & tab1$geo == gi & tab1$W > 0, ]
  b0a <- tab1$d14prof[tab1$fac == SP_FAC[1] & tab1$W == 0]; b0b <- tab1$d14prof[tab1$fac == SP_FAC[2] & tab1$W == 0]
  cm <- intersect(a$W, b$W); da <- a$d14prof[match(cm, a$W)] - b0a; db <- b$d14prof[match(cm, b$W)] - b0b
  cat(sprintf("(%d,%d) P7 fac contrast: deep-row bill rel. own W0 at W %s: fac 1 %s | fac 1/3 %s -> the short pass is cheaper at every W: %s\n",
              SP_GEO[[gi]][1], SP_GEO[[gi]][2], paste(cm, collapse = "/"), paste(sprintf("%+.1f", da), collapse = " "), paste(sprintf("%+.1f", db), collapse = " "),
              if (all(db >= da)) "yes" else "NO -> the pre-check's mechanism is not what the model does; a bug hunt before a finding"))
}

# ---- stage 2: arm C at W = 0 (each fac) and the best raw point per (k_dn, fac) ------------
if (SP_STAGE1) { saveRDS(list(grid = grid1, S1 = S1, tab1 = tab1, G0 = G0, ref = ref, provenance = list(commit = SP_COMMIT, built = format(Sys.time()), stage1_only = TRUE)), paste0(SP_OUT, ".rds"))
                 cat(sprintf("\nSTAGE 1 ONLY: saved %s.{log,rds}\n", SP_OUT)); quit(save = "no") }
cat("\n== STAGE 2: arm C re-optimisation ==\n")
rm_pins <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm_pins), add = TRUE)
bp0 <- ccx_mode_base(md); bp0$pump_mode <- md$pump_mode
st <- ccx_mode_start(md, "soc_probe"); pm0 <- st$p
lp_solved <- ccx_make_logpost(base_params = bp0, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
v_s <- lp_solved(st$u); ref_st <- attr(v_s, "streams")
cat(sprintf("HARNESS GATE 4: rebuilt logpost %.4f (shift %+.4f) vs stored %.4f -> %s\n", as.numeric(v_s) - st$logpost_shift, st$logpost_shift, md$logpost,
            if (abs(as.numeric(v_s) - st$logpost_shift - md$logpost) < SP_GATE_TOL) "PASS" else "FAIL"))
if (abs(as.numeric(v_s) - st$logpost_shift - md$logpost) >= SP_GATE_TOL) stop("harness gate 4 failed")
ccx_unpin_params(rm_pins); rm_pins <- list()
reopt_point <- function(W, ku, kd, fac) {
  pins <- ccx_mode_pins(md)   # the canonical's own: the six inert names + the shim pair at 0 (w_thc, w_vent, gamma_vent among them)
  rm <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rm), add = TRUE)
  bp <- bp0; for (n in names(pins)) bp[[n]] <- pins[[n]]
  bp$pump_field <- "martin"; bp$w_gthc <- 0; bp$w_soc <- W; bp$k_soc_up <- ku; bp$k_soc_dn <- kd; bp$hs_h_fac_SH <- fac   # STRUCTURAL: on the base list, never in u
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
  pm <- pm0[setdiff(names(pm0), names(pins))]
  u <- ccx_par_to_unc(pm); stopifnot(all(is.finite(u)))
  idx <- match(SP_ARMC, CCX_PARAM_NAMES); stopifnot(!any(is.na(idx)))
  fobj <- function(z) { uu <- u; uu[idx] <- z; x <- -as.numeric(lp(uu)); if (!is.finite(x)) 1e10 else x }
  v_raw <- lp(u)
  o1 <- stats::optim(u[idx], fobj, method = "Nelder-Mead", control = list(maxit = SP_NM_MAXIT, reltol = 1e-10))
  o2 <- stats::optim(o1$par, fobj, method = "BFGS", control = list(maxit = SP_BFGS_MAXIT, reltol = 1e-12))
  best <- if (o2$value < o1$value) o2 else o1; uu <- u; uu[idx] <- best$par
  v <- lp(uu); pmb <- ccx_unc_to_par(uu)
  st_raw <- attr(v_raw, "streams"); st_c <- attr(v, "streams"); cm <- intersect(names(st_c), names(ref_st))
  list(W = W, ku = ku, kd = kd, fac = fac, pm = pmb, dlik_raw = sum(st_raw[cm] - ref_st[cm]), dlik = sum(st_c[cm] - ref_st[cm]),
       d = st_c[cm] - ref_st[cm], n_eval = o1$counts[1] + o2$counts[1],
       read = { vv <- point_p(W, ku, kd, fac); for (n in names(pmb)) if (n %in% names(vv$p)) vv$p[[n]] <- pmb[[n]]
                for (n in c("luc_scale", "bomb_total", "sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c")) if (!is.null(pmb[[n]])) vv[[n]] <- pmb[[n]]
                read_point(vv) })
}
sel <- NULL
for (fac in SP_FAC) {
  b0 <- tab1[tab1$fac == fac & tab1$W == 0, ]
  sel <- rbind(sel, data.frame(W = 0, ku = SP_GEO[[1]][1], kd = SP_GEO[[1]][2], fac = fac, dlik_raw = b0$dlik))
  for (gi in seq_along(SP_GEO)) { s <- tab1[tab1$fac == fac & tab1$geo == gi & tab1$W > 0 & is.finite(tab1$dlik), ]
    if (nrow(s)) { b <- s[which.max(s$dlik), ]; sel <- rbind(sel, data.frame(W = b$W, ku = b$ku, kd = b$kd, fac = fac, dlik_raw = b$dlik)) } }
}
cat("selected for arm C (W = 0 per fac; the best raw W per (k_dn, fac)):\n"); print(sel, row.names = FALSE)
S2 <- list()
for (i in seq_len(nrow(sel))) {
  s <- sel[i, ]; t0 <- proc.time()[["elapsed"]]
  r2 <- tryCatch(reopt_point(s$W, s$ku, s$kd, s$fac), error = function(e) { cat(sprintf("armC W%g (%d,%d) f%s FAILED: %s\n", s$W, s$ku, s$kd, format(s$fac, digits = 3), conditionMessage(e))); NULL })
  if (is.null(r2)) next
  S2[[i]] <- r2
  cat(sprintf("armC W%-2g (%d,%d) f%-5s: raw %+8.1f -> armC %+8.1f (%d evals; kz_deep_frac %.4f h_ml %.1f k_w %.0f bomb_total %.1f sigma_d14c %.2f q10 %.2f; u_hs %.1f pump_hs %.1f h_hs %.0f) [%.0f s]\n  %s\n",
              s$W, s$ku, s$kd, format(s$fac, digits = 3), r2$dlik_raw, r2$dlik, r2$n_eval, r2$pm$kz_deep_frac, r2$pm$h_ml, r2$pm$k_w, r2$pm$bomb_total, r2$pm$sigma_d14c, r2$pm$q10,
              r2$pm$u_hs, r2$pm$pump_hs_gcm2, r2$pm$h_hs, proc.time()[["elapsed"]] - t0, fmt("", r2$read)))
  cat(sprintf("        largest rows: %s\n", paste(sprintf("%s %+.1f", names(sort(r2$d))[1:5], sort(r2$d)[1:5]), collapse = ", ")))
}

# ---- THE REJECT RULE (prereg s5) ------------------------------------------
cat(sprintf("\n== THE REJECT RULE: promote to the refit tier only if at ONE point: P1 (SH hs D falls >= %.1f at W %g, same fac), P2 (SH ml D within %.2f -- else a BUG), P3 in direction (SH hs PI D14C older), P7 free (profile rows within %g of the same-fac W 0) ==\n",
            SP_P1_MIN_FALL, SP_P1_W, SP_P2_ML_TOL, SP_P7_FREE))
verdict <- NULL
for (i in seq_len(nrow(grid1))) { r <- S1[[i]]; if (is.null(r) || grid1$W[i] == 0) next
  fac <- grid1$fac[i]; gi <- grid1$geo[i]; b0 <- tab1[tab1$fac == fac & tab1$W == 0, ]
  p1 <- tab1[tab1$fac == fac & tab1$geo == gi & tab1$W == SP_P1_W, ]; p1_ok <- nrow(p1) == 1 && (b0$SHhs - p1$SHhs) >= SP_P1_MIN_FALL
  verdict <- rbind(verdict, data.frame(W = grid1$W[i], ku = grid1$ku[i], kd = grid1$kd[i], fac = fac, D_SHhs = r$gD$region[["SH_hs"]], D_SHml_mv = r$gD$region[["SH_ml"]] - b0$SHml,
                                       hs14_SH = r$hs14[["SH"]], d14prof = r$d14prof - b0$d14prof,
                                       P1 = p1_ok, P2 = abs(r$gD$region[["SH_ml"]] - b0$SHml) <= SP_P2_ML_TOL, P3 = r$hs14[["SH"]] < b0$hs14_SH, P7 = (r$d14prof - b0$d14prof) >= SP_P7_FREE)) }
verdict$PASS <- verdict$P1 & verdict$P2 & verdict$P3 & verdict$P7
print(verdict, digits = 3, row.names = FALSE)
pass <- verdict[verdict$PASS, ]
dead <- !any(verdict$P7 & verdict$W <= SP_P7_DEAD_W)
cat(sprintf("\nVERDICT: %s\n", if (nrow(pass)) sprintf("%d point(s) pass: %s -> the REFIT tier (a second prereg; nothing adopted here)", nrow(pass), paste(sprintf("W%g (%d,%d) f%s (SH hs D %+.2f)", pass$W, pass$ku, pass$kd, format(pass$fac, digits = 3), pass$D_SHhs), collapse = "; "))
                               else if (dead) sprintf("NO W <= %g Sv is free on the deep D14C rows at ANY (k_dn, fac): the window is DEAD AS A CLASS (prereg P7) -- recorded, parked, pruned with the arc's switches.", SP_P7_DEAD_W)
                               else "NO point passes P1 + P2 + P3 + P7 together: the window is RECORDED AND PARKED (the arm-C price above)."))
cat("⛔ Gate D's verdict (z -6.60) and the gradient offset (-0.0668) are option (C)'s named reds and are NOT touched by this probe under any outcome.\n")
saveRDS(list(grid = grid1, S1 = S1, tab1 = tab1, G0 = G0, sel = sel, S2 = S2, verdict = verdict, ref = ref, ref_st = ref_st, gD_ref = gD_ref, gQ_ref = gQ_ref,
             export = SP_EXPORT, W = SP_W, geo = SP_GEO, fac = SP_FAC, armc = SP_ARMC, canonical = SP_ARM, md_logpost = md$logpost, obs_d14_mlo_spo = c(mean = OBS_D14_MLO_SPO, sd = OBS_D14_SD),
             provenance = list(commit = SP_COMMIT, built = format(Sys.time()), seed = "none (deterministic; no RNG on any path)", mode_file = ccx_mode_file(SP_ARM), prereg = "notes/prereg_2026-09-21e_so_window_probe.md")), paste0(SP_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n", SP_OUT))
