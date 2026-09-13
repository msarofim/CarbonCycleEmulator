# =====================================================================
# T-A2 (prereg notes/prereg_2026-09-13f_ta2_return_depth_scan.md): the
# Nino3.4-modulated limb's RETURN DEPTH, scanned unrefitted at the canonical
# (hilda30c). Marcus 09-13: "Run the T-A2 scan first".
#
# THE LIMB, anomaly only: a signed exchange dV = -gamma_A * Nino3.4 between
# the mixed layer and layer k, each tracer at its own gradient,
#   F_tr(k -> ML) = dV * (y[k,tr]/dz_k - y[ml,tr]/dz_ml(t)).
# k = 1 IS T-A1 (dK = dV * dz_mid on the fitted interface diffusion) and must
# reproduce it. NO mean W0: the periodic spinup runs in C++, so a mean limb
# to layer k >= 2 cannot be in the equilibrium without the core, and T-A0's
# table shows the GAIN is a function of the anomaly W0*gamma alone (R2 0.9996
# across W0 0.5-4 m/yr) -- see the prereg. The price of a MEAN W0 at depth is
# NOT answered here.
# HOW: the T-A0/T-A1 device -- a session wrapper on the pure-R ccx_deriv()
# that adds the limb's dy AFTER the base derivative. Spinup = the file's own
# periodic one, taken before the wrapper. Both hemispheres equally.
# Usage: Rscript calibration/diag_ta2_enso_return_depth.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
TA2_K      <- c(1, 2, 3, 4, 5, 6, 8, 10)   # return layer (1 = just below the ML; 10 = the bottom box)
TA2_GAMMA  <- 3                            # m/yr per Nino3.4 unit -- T-A1's linear regime
TA2_WIN    <- c(1959, 2024)                # = SC_ENSO_WIN
TA2_P0_SLOPE <- -0.0945; TA2_P0_LIK <- 2.80; TA2_P0_TOL <- c(1e-3, 0.05)   # T-A1 at gamma_A 3, k = 1
TA2_P2_EFF <- c(0.10, 0.20); TA2_P3_GAIN <- c(0.08, 0.13); TA2_P4_ROW <- 1
TA2_ROW_SHOW <- 0.5
# STAGE 2 ("matched", TA2_STAGE=matched): the scan's gamma_A 3 over-drives the deep returns 3-8x the
# OBSERVED slope, and the price of an over-driven arm is not the price of the mechanism
# ([[like_for_like_forcing]]). Stage 2 re-runs each k at the gamma_A the scan says reaches the
# observed slope (g_obs, read from the scan rds), so every arm carries the SAME ENSO response and
# the prices compare like for like.
TA2_STAGE   <- Sys.getenv("TA2_STAGE", "scan")
TA2_K_MATCH <- c(2, 3, 4, 6, 10)
TA2_SCAN_RDS <- ccx_path("outputs", "diagnostics", "ta2_enso_return_depth_20260913.rds")
TA2_OUT <- ccx_path("outputs", "diagnostics", sprintf("ta2_enso_return_depth%s_%s.rds", if (TA2_STAGE == "matched") "_matched" else "", format(Sys.Date(), "%Y%m%d")))
SV_PER_M3S <- 1e6; SEC_PER_YR <- 365.25 * 86400

v <- dg_vector(CCX_MODE_CANONICAL); obs <- ccx_prepare_obs()
cat(sprintf("arm %s: %s\n  pins: %s; migrated: %s; spinup: %s\n", CCX_MODE_CANONICAL, v$src,
            if (length(v$pins)) paste(sprintf("%s=%g", names(v$pins), v$pins), collapse = ",") else "none",
            if (length(v$migrated)) paste(v$migrated, collapse = ",") else "none", v$spinup_label))
en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))); en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
g <- obs$gcb; mg <- merge(g[, c("year", "ocean_sink")], en_ann, by = "year"); mg <- mg[stats::complete.cases(mg) & mg$year >= TA2_WIN[1] & mg$year <= TA2_WIN[2], ]
fo <- stats::lm(ocean_sink ~ year + nino34_anom, data = mg); OBS_SLOPE <- coef(fo)[["nino34_anom"]]
enso_slope <- function(r) { s <- dg_annual_sinks(r); d <- merge(data.frame(year = s$year, oc = s$ocean), en_ann, by = "year")
  d <- d[d$year >= TA2_WIN[1] & d$year <= TA2_WIN[2], ]; f <- stats::lm(oc ~ year + nino34_anom, data = d)
  c(slope = coef(f)[["nino34_anom"]], se = summary(f)$coefficients["nino34_anom", 2], r = stats::cor(residuals(stats::lm(oc ~ year, d)), d$nino34_anom), sink = mean(s$ocean[s$year >= 2015 & s$year <= 2023])) }
cat(sprintf("GCB observed: slope %+.4f +/- %.4f GtC/yr per index, r %+.3f (n %d)\n", OBS_SLOPE, summary(fo)$coefficients["nino34_anom", 2], stats::cor(residuals(stats::lm(ocean_sink ~ year, mg)), mg$nino34_anom), nrow(mg)))

# ---- the solubility-only reference (C++) and the geometry ------------------
v0 <- v; v0$p$gamma_enso_ocn_NH <- 0; v0$p$gamma_enso_ocn_SH <- 0
r0 <- dg_run(v0); st0 <- unlist(dg_streams(r0, v0)); e0 <- enso_slope(r0)
aux0 <- r0$sp$aux; g0 <- r0$sp$grid; A_LS <- sum(unlist(aux0$a_ls))
cat(sprintf("%s solubility-only: slope %+.4f (r %+.3f), lik %.2f; A_ls %.3e m2 (1 m/yr = %.1f Sv)\n", CCX_MODE_CANONICAL, e0[["slope"]], e0[["r"]], sum(st0), A_LS, A_LS / SEC_PER_YR / SV_PER_M3S))
zb <- cumsum(g0$dz); zt <- c(0, zb[-length(zb)])
cat("  layers at the fitted h_ml (annual-mean geometry): ML", sprintf("%.0f-%.0f m", zt[1], zb[1]), "; ")
for (k in seq_len(g0$nl)) cat(sprintf("k%d %.0f-%.0f%s", k, zt[k + 1], zb[k + 1], if (k < g0$nl) ", " else "\n"))
UMOL <- function(h) aux0$mol_per_GtC / (aux0$a_ls[[h]] * ccx_const("RHO_SEAWATER")) * 1e6   # GtC/m -> umol/kg
supply_per_myr <- function(con) sum(vapply(HEMIS, function(h) aux0$a_ls[[h]] * ccx_const("RHO_SEAWATER") * con[[h]] * 1e-6 / aux0$mol_per_GtC, numeric(1)))

# ---- the wrapper: base derivative, then the limb -----------------------------
.ta2_deriv_base <- ccx_deriv; TA2_K_CUR <- 1L; TA2_G_CUR <- 0; TA2_CON <- list(NH = c(0, 0), SH = c(0, 0))
ccx_deriv <- function(y, t, p, forc, grid, aux, record = FALSE) {
  dy <- .ta2_deriv_base(y, t, p, forc, grid, aux, record)
  dV <- -TA2_G_CUR * forc$enso
  rec <- t >= TA2_WIN[1] && t < TA2_WIN[2] + 1
  for (h in HEMIS) {
    f  <- if (ccx_seas_ml_ls_on(p)) ccx_mld_eval(aux$mld_coef[[h]], t)$f else 1
    gr <- if (f != 1) ccx_grid_at_h_ml(grid, grid$h_ml * f) else grid
    iml <- aux$idx[[h]]$ml; ik <- aux$idx[[h]]$oc[TA2_K_CUR]; dzk <- gr$dz[TA2_K_CUR + 1]; dzm <- gr$dz[1]
    if (rec) TA2_CON[[h]] <<- TA2_CON[[h]] + c((y[ik, "C"] / dzk - y[iml, "C"] / dzm) * UMOL(h), 1)
    if (dV != 0) for (tr in CCX_TRACERS) {
      F_t <- dV * (y[ik, tr] / dzk - y[iml, tr] / dzm)
      dy[ik, tr] <- dy[ik, tr] - F_t; dy[iml, tr] <- dy[iml, tr] + F_t
    }
  }
  dy
}
run_R <- function(k, G) {
  TA2_K_CUR <<- as.integer(k); TA2_G_CUR <<- G; TA2_CON <<- list(NH = c(0, 0), SH = c(0, 0))
  o <- suppressWarnings(ccx_run(r0$sp, r0$F))$out; TA2_G_CUR <<- 0
  list(sp = r0$sp, F = r0$F, out = o) }

if (TA2_STAGE == "matched") {
  SC <- readRDS(TA2_SCAN_RDS)$table
  cat(sprintf("\n=== STAGE 2: each return depth at ITS obs-matching gamma_A (from the scan) -- like-for-like prices ===\n"))
  M <- list()
  for (k in TA2_K_MATCH) {
    G <- SC$g_obs[SC$k == k]; t0 <- Sys.time(); rk <- run_R(k, G); e <- enso_slope(rk); stk <- unlist(dg_streams(rk, v0)); d <- stk - st0
    big <- names(d)[order(-abs(d))]; big <- big[abs(d[big]) > TA2_ROW_SHOW]
    lev <- sum(d[grepl("co2_level|co2_icecore", names(d))]); d14 <- d[grepl("d14c|c14", names(d))]
    cat(sprintf("  k %2d (%4.0f-%4.0f m) at gamma_A %.2f m/yr (%.1f Sv per index): slope %+.4f (r %+.3f) = %.2fx obs; lik %+.2f [CO2-level rows %+.2f; gcb_ocean_sink %+.2f; max |14C row| %.2f] [%s]; %.0f s\n",
                k, zt[k + 1], zb[k + 1], G, G * A_LS / SEC_PER_YR / SV_PER_M3S, e[["slope"]], e[["r"]], e[["slope"]] / OBS_SLOPE, sum(d), lev, d[["gcb_ocean_sink"]], max(abs(d14)),
                if (length(big)) paste(sprintf("%s %+.2f", big, d[big]), collapse = ", ") else sprintf("no row > %g", TA2_ROW_SHOW), as.numeric(Sys.time() - t0, units = "secs")))
    M[[sprintf("k%d", k)]] <- list(k = k, gamma = G, sv = G * A_LS / SEC_PER_YR / SV_PER_M3S, slope = e[["slope"]], r = e[["r"]], dlik = sum(d), lev = lev, sink_row = d[["gcb_ocean_sink"]], d14max = max(abs(d14)), rows = d)
  }
  ccx_deriv <- .ta2_deriv_base
  TM <- do.call(rbind, lapply(M, function(x) data.frame(k = x$k, gamma = x$gamma, sv = x$sv, slope = x$slope, r = x$r, dlik = x$dlik, lev = x$lev, sink_row = x$sink_row, d14max = x$d14max)))
  cat("\n  READING: at equal ENSO response the price differs only through the decadal leak of the index into the CO2 level rows and the 14C rows;\n  the Sv per index unit each depth needs is the physical discriminant, against GLODAP's equatorial source-water contrast.\n")
  saveRDS(list(table = TM, res = M, ref = e0, obs = list(slope = OBS_SLOPE), scan = TA2_SCAN_RDS, mode = CCX_MODE_CANONICAL, src = v$src, date = Sys.time()), TA2_OUT)
  cat("saved", TA2_OUT, "\n"); quit(save = "no")
}

RES <- list()
for (k in TA2_K) {
  t0 <- Sys.time(); rk <- run_R(k, TA2_GAMMA); e <- enso_slope(rk); stk <- unlist(dg_streams(rk, v0)); d <- stk - st0
  con <- vapply(HEMIS, function(h) TA2_CON[[h]][1] / TA2_CON[[h]][2], numeric(1)); sup <- supply_per_myr(con)
  gain <- (e[["slope"]] - e0[["slope"]]) / TA2_GAMMA; eff <- gain / sup; g_obs <- (OBS_SLOPE - e0[["slope"]]) / gain
  big <- names(d)[order(-abs(d))]; big <- big[abs(d[big]) > TA2_ROW_SHOW]
  d14 <- d[grepl("d14c|c14", names(d))]; d14max <- if (length(d14)) max(abs(d14)) else 0
  cat(sprintf("  k %2d (%4.0f-%4.0f m): contrast NH %+6.1f SH %+6.1f umol/kg -> supply %.3f GtC/yr per (m/yr); slope %+.4f (r %+.3f); GAIN %.4f, efficiency %.3f; obs needs gamma_A %.2f m/yr = %.1f Sv per index; lik %+.2f (max |d14c row| %.2f) [%s]; %.0f s\n",
              k, zt[k + 1], zb[k + 1], con[["NH"]], con[["SH"]], sup, e[["slope"]], e[["r"]], gain, eff, g_obs, g_obs * A_LS / SEC_PER_YR / SV_PER_M3S, sum(d), d14max,
              if (length(big)) paste(sprintf("%s %+.2f", big, d[big]), collapse = ", ") else sprintf("no row > %g", TA2_ROW_SHOW), as.numeric(Sys.time() - t0, units = "secs")))
  RES[[sprintf("k%d", k)]] <- list(k = k, z = c(zt[k + 1], zb[k + 1]), contrast = con, supply = sup, slope = e[["slope"]], se = e[["se"]], r = e[["r"]], gain = gain, eff = eff, g_obs = g_obs, sv_obs = g_obs * A_LS / SEC_PER_YR / SV_PER_M3S, dlik = sum(d), d14max = d14max, rows = d)
}
ccx_deriv <- .ta2_deriv_base
T <- do.call(rbind, lapply(RES, function(x) data.frame(k = x$k, z_top = x$z[1], z_bot = x$z[2], con_NH = x$contrast[["NH"]], con_SH = x$contrast[["SH"]], supply = x$supply, slope = x$slope, r = x$r, gain = x$gain, eff = x$eff, g_obs = x$g_obs, sv_obs = x$sv_obs, dlik = x$dlik, d14max = x$d14max)))

cat("\n=== VERDICTS (prereg 2026-09-13f) ===\n")
k1 <- RES$k1; P0 <- abs(k1$slope - TA2_P0_SLOPE) <= TA2_P0_TOL[1] && abs(k1$dlik - TA2_P0_LIK) <= TA2_P0_TOL[2]
cat(sprintf("  P0 k=1 reproduces T-A1 (slope %+.4f / lik %+.2f vs %+.4f / %+.2f): %s\n", k1$slope, k1$dlik, TA2_P0_SLOPE, TA2_P0_LIK, if (P0) "PASS" else "FAIL -- the limb is not T-A1's"))
cm <- (T$con_NH + T$con_SH) / 2; P1 <- all(diff(cm) > 0)
cat(sprintf("  P1 contrast monotone in k (%s): %s\n", paste(sprintf("%+.0f", cm), collapse = ", "), if (P1) "PASS" else "FAIL"))
P2 <- all(T$eff >= TA2_P2_EFF[1] & T$eff <= TA2_P2_EFF[2])
cat(sprintf("  P2 efficiency in [%.2f, %.2f] at every k (%s): %s\n", TA2_P2_EFF[1], TA2_P2_EFF[2], paste(sprintf("%.3f", T$eff), collapse = ", "), if (P2) "PASS (the short circuit is the ML-layer-1 coupling, whatever the source)" else "FAIL (the return depth matters beyond the contrast)"))
kb <- RES[[sprintf("k%d", g0$nl)]]; P3 <- kb$gain >= TA2_P3_GAIN[1] && kb$gain <= TA2_P3_GAIN[2]
cat(sprintf("  P3 bottom-return gain %.4f in [%.2f, %.2f] (T-A0's 0.100 from a DIRECT exchange): %s\n", kb$gain, TA2_P3_GAIN[1], TA2_P3_GAIN[2], if (P3) "PASS" else "FAIL"))
P4 <- all(T$dlik > 0) && all(T$d14max < TA2_P4_ROW)
cat(sprintf("  P4 price positive at every k and no 14C row > %g (dlik %s; max 14C %s): %s\n", TA2_P4_ROW, paste(sprintf("%+.1f", T$dlik), collapse = "/"), paste(sprintf("%.2f", T$d14max), collapse = "/"), if (P4) "PASS" else "FAIL"))
saveRDS(list(table = T, res = RES, ref = e0, obs = list(slope = OBS_SLOPE, se = summary(fo)$coefficients["nino34_anom", 2], n = nrow(mg)), gamma = TA2_GAMMA, A_ls = A_LS, layers = data.frame(k = 0:g0$nl, top = zt, bot = zb),
             verdicts = list(P0 = P0, P1 = P1, P2 = P2, P3 = P3, P4 = P4), mode = CCX_MODE_CANONICAL, src = v$src, pins = v$pins, prereg = "notes/prereg_2026-09-13f_ta2_return_depth_scan.md", date = Sys.time()), TA2_OUT)
cat("saved", TA2_OUT, "\n")
