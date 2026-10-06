#!/usr/bin/env Rscript
# =====================================================================
# diag_net_climate_co2_feedback.R -- IS THE MODEL'S "NET CLIMATE EFFECT" LIKE-FOR-LIKE WITH GCB's TRENDY S2 - S1?
# (2026-10-04, before the P3 preview runs.)
#
# THE TRIGGER (an implausible number, so a check before any physics): lib_block_reopt.R's br_net_climate() at
# hilda34g gives +0.118 GtC/yr (2015-24) and, with q10 raised 1.06 -> 1.4 and nothing else moved, only -0.075:
# a -0.19 GtC/yr response where ~1 K of warming on ~55 GtC/yr of soil respiration predicts ~-1.5. The two runs
# also differ in CO2 (+3 ppm in 2024 at q10 1.4): CO2 is INTERACTIVE here, and TRENDY PRESCRIBES it (S1 and S2 see
# the SAME observed CO2). A warmer run outgasses more, so its land is fertilised more, which biases the model's
# full - held difference UP. br_net_climate() called that "second-order" without measuring it.
#
# THE MEASUREMENT: the full and held runs' 2015-24 CO2 difference (dCO2), and the model's own land response to CO2
# with climate HELD -- a held run with extra fossil emissions SHAPED LIKE THE WARMING (k x the GMST anomaly above
# its 1901-20 mean, so the extra CO2 builds as dCO2 does), scaled once so its CO2 bump matches dCO2. The like-for-
# like (TRENDY) net effect is then  net - s x dCO2,  s = d(land gain)/d(CO2) from that pair. LINEAR: one rescale,
# one sensitivity; stated, not hidden.
# Output: outputs/diagnostics/net_climate_co2_feedback_<date>.{log,rds}. No RNG.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()
NF_DRIVER <- "calibration/diag_net_climate_co2_feedback.R"
NF_MODE   <- "hilda34g"
NF_WIN    <- c(2015L, 2024L); NF_CLIM <- c(1901L, 1920L)
NF_Q10    <- c(canonical = NA, high = 1.4)              # NA = the mode's own; 1.4 = Mahecha 2010 (lit G14)
NF_K0     <- 1                                         # GtC/yr per K: the first try at the bump's scale (rescaled once)
NF_GCB    <- c(mean = -0.8, sd = 0.7)                  # GCB 2025 TRENDY S2 - S1, 2015-24 (lit note G3)
NF_OUT    <- file.path("outputs", "diagnostics", sprintf("net_climate_co2_feedback_%s", format(Sys.Date(), "%Y%m%d")))
COMMIT <- ccx_git_stamp()
sink(paste0(NF_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s | mode %s | window %d-%d vs %d-%d climate held\n", NF_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"),
            NF_MODE, NF_WIN[1], NF_WIN[2], NF_CLIM[1], NF_CLIM[2]))

v0 <- dg_vector(NF_MODE)
mean_win <- function(out, col) { at <- out$t >= NF_WIN[1] & out$t < NF_WIN[2] + 1; mean(out[[col]][at]) }
gain_win <- function(out) { at <- function(t) stats::approx(out$t, out$land_C, xout = t)$y
  (at(NF_WIN[2] + 1) - at(NF_WIN[1])) / (NF_WIN[2] + 1 - NF_WIN[1]) }
co2_win <- function(out) { at <- out$t >= NF_WIN[1] & out$t < NF_WIN[2] + 1; mean(((out$co2_NH + out$co2_SH) / 2)[at]) }
one <- function(q10) {
  v <- v0; if (!is.na(q10)) { v$p$q10 <- q10; v$pm$q10 <- q10 }
  sp <- dg_spinup(v)
  F <- suppressWarnings(ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp$prod_c14, bomb_total_kmol = v$bomb_total,
                                          luc_scale = v$luc_scale, enso_index = ccx_enso_index_of(v$p), aod_mode = ccx_aod_mode_of(v$p)))
  base <- mean(F$gmst[F$year >= NF_CLIM[1] & F$year <= NF_CLIM[2]])
  F0 <- F; sel <- F0$year >= NF_CLIM[1]; F0$gmst[sel] <- base
  full <- ccx_run_fast(sp, F)$out; held <- ccx_run_fast(sp, F0)$out
  dco2 <- co2_win(full) - co2_win(held); net <- gain_win(full) - gain_win(held)
  # the bump: extra fossil emissions shaped like the warming, split as the fossil source is
  shape <- pmax(F$gmst - base, 0) * sel
  bump <- function(k) { Fb <- F0; tot <- F0$e_foss_NH + F0$e_foss_SH; nh <- ifelse(tot > 0, F0$e_foss_NH / tot, FORC_FOSS_NH_SHARE)
    Fb$e_foss_NH <- F0$e_foss_NH + k * shape * nh; Fb$e_foss_SH <- F0$e_foss_SH + k * shape * (1 - nh); ccx_run_fast(sp, Fb)$out }
  b1 <- bump(NF_K0); d1 <- co2_win(b1) - co2_win(held)
  k2 <- NF_K0 * dco2 / d1; b2 <- bump(k2); d2 <- co2_win(b2) - co2_win(held)
  s <- (gain_win(b2) - gain_win(held)) / d2
  c(q10 = v$p$q10, net_interactive = net, dco2_ppm = dco2, bump_k = k2, bump_dco2 = d2, land_per_ppm = s,
    feedback = s * dco2, net_like_for_like = net - s * dco2)
}
RES <- t(vapply(NF_Q10, one, numeric(8)))
print(round(RES, 4))
cat(sprintf("\n  GCB 2025 TRENDY S2 - S1: %+.1f +/- %.1f GtC/yr\n", NF_GCB[["mean"]], NF_GCB[["sd"]]))
for (r in rownames(RES)) cat(sprintf("  %-9s q10 %.3f: interactive %+.3f, of it the CO2 feedback %+.3f (dCO2 %+.2f ppm x %.4f GtC/yr per ppm) => like-for-like %+.3f GtC/yr (z %+.2f vs GCB)\n",
  r, RES[r, "q10"], RES[r, "net_interactive"], RES[r, "feedback"], RES[r, "dco2_ppm"], RES[r, "land_per_ppm"], RES[r, "net_like_for_like"],
  (RES[r, "net_like_for_like"] - NF_GCB[["mean"]]) / NF_GCB[["sd"]]))
sink()
saveRDS(list(table = RES, provenance = sprintf("%s @%s; mode %s; window %d-%d vs %d-%d held; bump = k x warming shape, k rescaled once; no RNG",
                                               NF_DRIVER, COMMIT, NF_MODE, NF_WIN[1], NF_WIN[2], NF_CLIM[1], NF_CLIM[2])), paste0(NF_OUT, ".rds"))
