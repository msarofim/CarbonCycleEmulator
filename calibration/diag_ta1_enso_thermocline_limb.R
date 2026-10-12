# =====================================================================
# T-A1 (prereg notes/prereg_2026-09-13e_optionA_nino34_thermocline_limb.md):
# option A's UNREFITTED probe at the canonical (hilda30c, the pinned canonical)
# -- the Nino3.4-modulated upwelling limb on `ml_lo` WITH A THERMOCLINE RETURN
# (option B ruling 2). Decides whether the ocean's ENSO sign and magnitude are
# reachable at a physical gamma without a refit.
#
# THE LIMB, WITHOUT TOUCHING EITHER CORE. A two-way exchange V between the
# mixed layer and layer 1 (V C_1/dz_1 up, V C_ml/dz_ml down) IS the model's
# own interface diffusion F = K (C_ml/dz_ml - C_1/dz_1)/dz_mid with
# V = K/dz_mid, tracer by tracer. So the limb's MEAN is already the fitted kz
# and only the anomaly is added:  V_eff = V0 - gamma_A * Nino3.4, V0 =
# kz_int[1]/dz_mid[1] (187 m/yr at hilda30c), gamma_A in m/yr per index unit.
# El Nino WEAKENS the exchange: less thermocline water reaches the mixed layer,
# its DIC relaxes toward air-sea equilibrium, uptake RISES (right sign) -- IF
# layer 1 is DIC-richer than the ML in the annual mean (prereg P1, RECORDED).
# gamma_A = 0 is the canonical bit for bit (the zero-perturbation identity).
#
# HOW: the pure-R transient with a session wrapper on ccx_deriv() that sets
# aux$kz_int[1] <- max(0, kz_int[1] - gamma_A * forc$enso * dz_mid[1]) per
# call (the T-A0 device, diag_ta0_enso_upwelling_sign.R). The spinup is the
# file's own (dg_spinup, periodic) and is taken BEFORE the wrapper is installed.
# Both hemispheres modulated equally (Nino3.4 is 5S-5N; no tropical box).
# The estimator is the scorecard's (09-04g): annual ocean uptake ~ year +
# Nino3.4, 1959-2024, dg_annual_sinks -- so P0's references are the 09-13 (d)
# scorecard's numbers, like-for-like.
# Usage: Rscript calibration/diag_ta1_enso_thermocline_limb.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
TA1_GAMMA   <- c(-1, 0.5, 1, 2, 3, 4, 8)   # m/yr per Nino3.4 unit; 0 is the reference (C++ and R)
TA1_WIN     <- c(1959, 2024)               # = SC_ENSO_WIN (diag_whole_model_scorecard.R)
TA1_P0_TOL  <- 1e-6                        # ppm, R-vs-C++ at gamma_A 0
# 2026-10-12: moved to the held-PD100 quarantine (its README). Only its ENSO section is read here, which is valid.
TA1_P0_REF  <- ccx_path("outputs", "quarantine", "20261012_pd100_held_sst", "whole_model_scorecard_20260913_hilda30c.rds")
TA1_P2_R    <- 0.3;  TA1_P2_GAMMA <- 3     # prereg P2
TA1_P3_TOL  <- 0.10                        # P3 mirror tolerance (fraction)
TA1_P4_LIK  <- -10                         # P4: price at the obs-matching gamma_A, log-units
TA1_P5_GAIN <- 0.100; TA1_P5_BAND <- 2     # P5: T-A0's gain, GtC/yr per (m/yr) per index; within 2x
TA1_ROW_SHOW <- 1                          # print stream rows moving more than this
TA1_OUT <- ccx_path("outputs", "diagnostics", sprintf("ta1_enso_thermocline_limb_%s.rds", format(Sys.Date(), "%Y%m%d")))
SV_PER_M3S <- 1e6; SEC_PER_YR <- 365.25 * 86400

v <- dg_vector(CCX_MODE_CANONICAL); obs <- ccx_prepare_obs()
cat(sprintf("arm %s: %s\n  pins: %s; migrated: %s; spinup: %s\n", CCX_MODE_CANONICAL, v$src,
            if (length(v$pins)) paste(sprintf("%s=%g", names(v$pins), v$pins), collapse = ",") else "none",
            if (length(v$migrated)) paste(v$migrated, collapse = ",") else "none", v$spinup_label))
en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))); en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
g <- obs$gcb; mg <- merge(g[, c("year", "ocean_sink")], en_ann, by = "year"); mg <- mg[stats::complete.cases(mg) & mg$year >= TA1_WIN[1] & mg$year <= TA1_WIN[2], ]
fo <- stats::lm(ocean_sink ~ year + nino34_anom, data = mg); OBS_SLOPE <- coef(fo)[["nino34_anom"]]
enso_slope <- function(r) { s <- dg_annual_sinks(r); d <- merge(data.frame(year = s$year, oc = s$ocean), en_ann, by = "year")
  d <- d[d$year >= TA1_WIN[1] & d$year <= TA1_WIN[2], ]; f <- stats::lm(oc ~ year + nino34_anom, data = d)
  c(slope = coef(f)[["nino34_anom"]], se = summary(f)$coefficients["nino34_anom", 2], r = stats::cor(residuals(stats::lm(oc ~ year, d)), d$nino34_anom), sink = mean(s$ocean[s$year >= 2015 & s$year <= 2023])) }
cat(sprintf("GCB observed: slope %+.4f +/- %.4f GtC/yr per index, r %+.3f (n %d)\n", OBS_SLOPE, summary(fo)$coefficients["nino34_anom", 2], stats::cor(residuals(stats::lm(ocean_sink ~ year, mg)), mg$nino34_anom), nrow(mg)))

# ---- 0. the references (C++): canonical, and solubility-only ---------------
v0 <- v; v0$p$gamma_enso_ocn_NH <- 0; v0$p$gamma_enso_ocn_SH <- 0
rC <- dg_run(v); r0 <- dg_run(v0); st0 <- unlist(dg_streams(r0, v0)); stC <- unlist(dg_streams(rC, v))
REF <- list(canonical = enso_slope(rC), solubility_only = enso_slope(r0))
cat(sprintf("%s full model: slope %+.4f (r %+.3f) = %.2fx obs; solubility-only (gamma_enso_ocn 0): slope %+.4f (r %+.3f); lik %.2f / %.2f\n",
            CCX_MODE_CANONICAL, REF$canonical[["slope"]], REF$canonical[["r"]], REF$canonical[["slope"]] / OBS_SLOPE,
            REF$solubility_only[["slope"]], REF$solubility_only[["r"]], sum(stC), sum(st0)))
aux0 <- r0$sp$aux; g0 <- r0$sp$grid
V0 <- aux0$kz_int[1] / aux0$dz_mid[1]; A_LS <- sum(unlist(aux0$a_ls))
cat(sprintf("  V0 = kz_int[1]/dz_mid[1] = %.1f / %.3f = %.1f m/yr; A_ls (both hemispheres) %.3e m2: 1 m/yr = %.1f Sv; floor binds at gamma_A > %.0f m/yr (|Nino3.4| max %.2f)\n",
            aux0$kz_int[1], aux0$dz_mid[1], V0, A_LS, A_LS / SEC_PER_YR / SV_PER_M3S, V0 / max(abs(en$nino34_anom), na.rm = TRUE), max(abs(en$nino34_anom), na.rm = TRUE)))
P0 <- list(scorecard = NA)
if (file.exists(TA1_P0_REF)) {
  sc <- readRDS(TA1_P0_REF)$enso[[CCX_MODE_CANONICAL]]
  if (!is.null(sc)) { d_full <- REF$canonical[["slope"]] - sc$full[["slope"]]; d_sol <- REF$solubility_only[["r"]] - sc$sol[["r"]]
    cat(sprintf("  P0 vs scorecard 09-13 (d): full slope %+.4f vs %+.4f (d %+.1e); solubility-only r %+.3f vs %+.3f (d %+.1e): %s\n",
                REF$canonical[["slope"]], sc$full[["slope"]], d_full, REF$solubility_only[["r"]], sc$sol[["r"]], d_sol,
                if (abs(d_full) < 1e-3 && abs(d_sol) < 1e-3) "REPRODUCED" else "NOT REPRODUCED -- STOP and find out why"))
    P0$scorecard <- abs(d_full) < 1e-3 && abs(d_sol) < 1e-3 }
} else cat("  (no 09-13 (d) scorecard rds at ", TA1_P0_REF, " -- P0's scorecard leg not run)\n")

# ---- the wrapper ------------------------------------------------------------
.ta1_deriv_base <- ccx_deriv; TA1_G_CUR <- 0; TA1_CONTRAST <- NULL
ccx_deriv <- function(y, t, p, forc, grid, aux, record = FALSE) {
  if (TA1_G_CUR != 0) aux$kz_int[1] <- max(0, aux$kz_int[1] - TA1_G_CUR * forc$enso * aux$dz_mid[1])
  if (!is.null(TA1_CONTRAST) && t >= TA1_WIN[1] && t < TA1_WIN[2] + 1) {   # P1: record the layer-1 - ML contrast (umol/kg, each box over its mass NOW)
    for (h in HEMIS) {
      f <- if (ccx_seas_ml_ls_on(p)) ccx_mld_eval(aux$mld_coef[[h]], t)$f else 1
      gr <- if (f != 1) ccx_grid_at_h_ml(grid, grid$h_ml * f) else grid
      iml <- aux$idx[[h]]$ml; i1 <- aux$idx[[h]]$oc[1]; k <- aux$mol_per_GtC / (aux$a_ls[[h]] * ccx_const("RHO_SEAWATER")) * 1e6
      TA1_CONTRAST[[h]] <<- TA1_CONTRAST[[h]] + c(y[i1, "C"] / gr$dz[2] * k - y[iml, "C"] / gr$dz[1] * k, 1)
    }
  }
  .ta1_deriv_base(y, t, p, forc, grid, aux, record)
}
run_R <- function(G, contrast = FALSE) {
  TA1_G_CUR <<- G; TA1_CONTRAST <<- if (contrast) list(NH = c(0, 0), SH = c(0, 0)) else NULL
  o <- suppressWarnings(ccx_run(r0$sp, r0$F))$out; TA1_G_CUR <<- 0
  list(sp = r0$sp, F = r0$F, out = o) }

# ---- P0: gamma_A = 0 through R == C++ ---------------------------------------
t0 <- Sys.time(); rR0 <- run_R(0, contrast = TRUE); tR <- as.numeric(Sys.time() - t0, units = "secs")
dppm <- max(abs(rR0$out$co2_NH - r0$out$co2_NH), abs(rR0$out$co2_SH - r0$out$co2_SH)); eR0 <- enso_slope(rR0)
P0$parity <- dppm < TA1_P0_TOL
cat(sprintf("\nP0 R-vs-C++ at gamma_A 0: max |d co2| %.2e ppm (%s); R slope %+.4f (r %+.3f); %.0f s per R run\n", dppm, if (P0$parity) "PASS" else "FAIL -- STOP", eR0[["slope"]], eR0[["r"]], tR))
CON <- vapply(HEMIS, function(h) TA1_CONTRAST[[h]][1] / TA1_CONTRAST[[h]][2], numeric(1))
P1 <- all(CON > 0)
cat(sprintf("P1 annual-mean layer-1 minus ML DIC, %d-%d: NH %+.1f, SH %+.1f umol/kg -> %s; supply anomaly at 100%% conversion %.3f GtC/yr per (m/yr) per index (obs slope needs %.1f m/yr at that efficiency)\n",
            TA1_WIN[1], TA1_WIN[2], CON[["NH"]], CON[["SH"]], if (P1) "PASS (the thermocline is DIC-richer)" else "FAIL -- nothing right-signed to modulate as built",
            sum(vapply(HEMIS, function(h) aux0$a_ls[[h]] * ccx_const("RHO_SEAWATER") * CON[[h]] * 1e-6 / aux0$mol_per_GtC, numeric(1))),
            OBS_SLOPE / sum(vapply(HEMIS, function(h) aux0$a_ls[[h]] * ccx_const("RHO_SEAWATER") * CON[[h]] * 1e-6 / aux0$mol_per_GtC, numeric(1)))))
if (!P0$parity) stop("P0 parity failed; the wrapper or the spinup is off-mode")

# ---- the scan ---------------------------------------------------------------
RES <- list(); RES[["g0"]] <- c(gamma = 0, eR0, lik = sum(st0))
for (G in TA1_GAMMA) {
  t0 <- Sys.time(); rg <- run_R(G); e <- enso_slope(rg); stg <- unlist(dg_streams(rg, v0)); d <- stg - st0
  big <- names(d)[order(-abs(d))]; big <- big[abs(d[big]) > TA1_ROW_SHOW]
  cat(sprintf("  gamma_A %+5.2f m/yr (%+.1f Sv per index): slope %+.4f +/- %.4f (r %+.3f) = %.2fx obs; sink 2015-23 %.2f; lik %+.2f vs gamma 0 [%s]; %.0f s\n",
              G, G * A_LS / SEC_PER_YR / SV_PER_M3S, e[["slope"]], e[["se"]], e[["r"]], e[["slope"]] / OBS_SLOPE, e[["sink"]], sum(d),
              if (length(big)) paste(sprintf("%s %+.2f", big, d[big]), collapse = ", ") else "no row > 1", as.numeric(Sys.time() - t0, units = "secs")))
  RES[[sprintf("g%g", G)]] <- c(gamma = G, e, lik = sum(stg))
}
ccx_deriv <- .ta1_deriv_base
T <- as.data.frame(do.call(rbind, RES)); T <- T[order(T$gamma), ]

# ---- verdicts ---------------------------------------------------------------
cat("\n=== VERDICTS (prereg 2026-09-13e) ===\n")
pos <- T[T$gamma > 0, ]; fit <- stats::lm(slope ~ gamma, data = T[T$gamma >= 0 & T$gamma <= 4, ])
gain <- coef(fit)[["gamma"]]; g_flip <- -coef(fit)[["(Intercept)"]] / gain; g_obs <- (OBS_SLOPE - coef(fit)[["(Intercept)"]]) / gain
cat(sprintf("  slope = %+.4f %+.4f x gamma_A (R2 %.5f on 0..4); sign flips at gamma_A %.2f m/yr (%.1f Sv per index); obs slope at %.2f m/yr (%.1f Sv)\n",
            coef(fit)[["(Intercept)"]], gain, summary(fit)$r.squared, g_flip, g_flip * A_LS / SEC_PER_YR / SV_PER_M3S, g_obs, g_obs * A_LS / SEC_PER_YR / SV_PER_M3S))
ok2 <- pos[pos$gamma <= TA1_P2_GAMMA & pos$r >= TA1_P2_R, ]
P2 <- nrow(ok2) > 0
cat(sprintf("  P2 'r flips from %+.3f to >= %+.1f at gamma_A <= %g': %s\n", REF$solubility_only[["r"]], TA1_P2_R, TA1_P2_GAMMA,
            if (P2) sprintf("CONFIRMED at gamma_A %s (r %s)", paste(ok2$gamma, collapse = "/"), paste(sprintf("%+.2f", ok2$r), collapse = "/"))
            else if (any(pos$r > 0)) sprintf("PARTLY: the sign flips (max r %+.2f at gamma_A %g) but not to %+.1f by %g m/yr", max(pos$r), pos$gamma[which.max(pos$r)], TA1_P2_R, TA1_P2_GAMMA)
            else "FALSIFIED: r stays negative at every gamma_A"))
m_pos <- T$slope[T$gamma == 1] - T$slope[T$gamma == 0]; m_neg <- T$slope[T$gamma == 0] - T$slope[T$gamma == -1]
P3 <- abs(m_pos - m_neg) <= TA1_P3_TOL * abs(m_pos)
cat(sprintf("  P3 mirror: d slope +1 %+.4f vs -1 %+.4f (asymmetry %.1f%%): %s\n", m_pos, m_neg, 100 * abs(m_pos - m_neg) / abs(m_pos), if (P3) "PASS (linear)" else "FAIL (nonlinear or floored)"))
# P4: price at the obs-matching gamma_A -- interpolate lik on the scan
lik_at <- if (g_obs > 0 && g_obs <= max(T$gamma)) stats::approx(T$gamma, T$lik - sum(st0), xout = g_obs)$y else NA
P4 <- is.finite(lik_at) && lik_at > TA1_P4_LIK
cat(sprintf("  P4 unrefitted price at the obs-matching gamma_A %.2f: %s log-units vs solubility-only (bound %+d): %s  [T-A0's plain limb: -135 at 0.5 m/yr]\n",
            g_obs, if (is.finite(lik_at)) sprintf("%+.2f", lik_at) else "off the scan", TA1_P4_LIK, if (P4) "PASS" else if (is.finite(lik_at)) "FAIL" else "NOT READ"))
P5 <- gain >= TA1_P5_GAIN / TA1_P5_BAND && gain <= TA1_P5_GAIN * TA1_P5_BAND
cat(sprintf("  P5 gain %.4f GtC/yr per (m/yr) per index vs T-A0's %.3f (within %gx): %s\n", gain, TA1_P5_GAIN, TA1_P5_BAND, if (P5) "PASS" else "FAIL"))
cat(sprintf("  P1 contrast NH %+.1f / SH %+.1f umol/kg: %s\n", CON[["NH"]], CON[["SH"]], if (P1) "PASS" else "FAIL"))
saveRDS(list(table = T, ref = REF, obs = list(slope = OBS_SLOPE, se = summary(fo)$coefficients["nino34_anom", 2], n = nrow(mg)), contrast = CON, V0 = V0, A_ls = A_LS,
             fit = list(intercept = coef(fit)[["(Intercept)"]], gain = gain, g_flip = g_flip, g_obs = g_obs), lik_at_obs = lik_at,
             verdicts = list(P0 = P0, P1 = P1, P2 = P2, P3 = P3, P4 = P4, P5 = P5), mode = CCX_MODE_CANONICAL, src = v$src, pins = v$pins,
             prereg = "notes/prereg_2026-09-13e_optionA_nino34_thermocline_limb.md", date = Sys.time()), TA1_OUT)
cat("saved", TA1_OUT, "\n")
