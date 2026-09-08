# =====================================================================
# The NH bomb-peak LEVERS (2026-09-08h). T-I showed the model's NH peak is
# already 0.96 yr LATE and that input timing moves it 1:1 the wrong way, so the
# miss is an early-removal RATE from the NH atmosphere. Which lever? Three
# removal paths and one control, each scanned 1-D at the canonical, C++ runs:
#   tau_ex   interhemispheric atmospheric exchange (one scalar serving the CO2
#            gradient at ~1.16 and the bomb lag, memory INDEX_ccx_ocean)
#   k_w      air-sea gas transfer (both hemispheres; the model has one k_w)
#   h_ml     mixed-layer capacity (the 40 m was a bomb + CO2 capacity statement)
#   bomb_share_NH  the declared 0.9 split, as a CONTROL (timing-neutral in T-I)
# Read: gate 5 (NH peak z, SH peak z, lag z), and the rows a lever would pay:
# d14c_NH/SH, co2_gradient, d13c_gradient, co2_level_*. The question is
# whether ANY lever brings z_NH below +1 while the lag and the gradient rows
# hold (|d logL| < 5). ⚠ No Joos anything (Marcus 09-08h).
# Nothing adopted. Usage: Rscript calibration/diag_nh_bomb_levers.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
NB_LEVERS <- list(tau_ex = c(0.5, 0.75, 1, 1.5, 2), k_w = c(0.75, 1, 1.5, 2, 3), h_ml = c(0.6, 0.8, 1, 1.5, 2), bomb_share_NH = c(0.8, 0.9, 1.0))
NB_ROWS <- c("d14c_NH", "d14c_SH", "co2_gradient", "d13c_gradient", "co2_level_MLO", "co2_level_SPO", "gcb_ocean_sink")
NB_TARGET_Z <- 1; NB_ROW_TOL <- 5
NB_OUT <- ccx_path("outputs", "diagnostics", sprintf("nh_bomb_levers_%s.rds", format(Sys.Date(), "%Y%m%d")))
v <- dg_vector(CCX_MODE_CANONICAL); ob5 <- dg_obs_gate5(); sp5 <- dg_obs_gate5_spread()
read <- function(lever, x) {
  va <- v; sp_share <- NULL
  if (lever == "bomb_share_NH") sp_share <- x else va$p[[lever]] <- v$p[[lever]] * x
  sp <- ccx_spinup(va$p); if (!is.null(sp_share)) sp$aux$bomb_share_NH <- sp_share
  F <- ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp$prod_c14, bomb_total_kmol = va$bomb_total, luc_scale = va$luc_scale)
  r <- list(sp = sp, F = F, out = ccx_run_fast(sp, F)$out)
  g <- dg_gate5(r); vd <- dg_gate5_verdict(g, ob5, sp5); st <- unlist(dg_streams(r, va))
  c(x = x, value = if (lever == "bomb_share_NH") x else va$p[[lever]], nh_t = g$pk$NH[["t"]], sh_t = g$pk$SH[["t"]], lag = g$lag, nh_v = g$pk$NH[["v"]],
    z_nh = vd$z[["nh_t"]], z_sh = vd$z[["sh_t"]], z_lag = vd$z[["lag"]], lik = sum(st), st[NB_ROWS])
}
base <- read("tau_ex", 1)
cat(sprintf("canonical: tau_ex %.3f yr, k_w %.0f, h_ml %.1f m, bomb_share_NH %.2f; NH peak %.3f (obs %.3f, z %+.2f), SH %.3f (z %+.2f), lag %.3f (obs %.3f, z %+.2f)\n",
            v$p$tau_ex, v$p$k_w, v$p$h_ml, 0.9, base[["nh_t"]], ob5$NH[["t"]], base[["z_nh"]], base[["sh_t"]], base[["z_sh"]], base[["lag"]], ob5$SH[["t"]] - ob5$NH[["t"]], base[["z_lag"]]))
RES <- list()
for (lv in names(NB_LEVERS)) {
  cat(sprintf("\n=== %s ===\n  %8s %8s | %9s %6s | %9s %6s | %6s %6s | %8s | %s\n", lv, "x", "value", "NH peak", "z NH", "SH peak", "z SH", "lag", "z lag", "d lik", "rows |d| > 3 vs canonical"))
  for (x in NB_LEVERS[[lv]]) { z <- read(lv, x); RES[[sprintf("%s_%g", lv, x)]] <- c(lever = lv, z); d <- z[NB_ROWS] - base[NB_ROWS]; big <- NB_ROWS[abs(d) > 3]
    cat(sprintf("  %8.2f %8.3f | %9.3f %+6.2f | %9.3f %+6.2f | %6.3f %+6.2f | %+8.1f | %s\n", x, z[["value"]], z[["nh_t"]], z[["z_nh"]], z[["sh_t"]], z[["z_sh"]], z[["lag"]], z[["z_lag"]], z[["lik"]] - base[["lik"]], paste(sprintf("%s %+.0f", big, d[big]), collapse = ", "))) }
}
cat("\n=== READING ===\n")
T <- as.data.frame(do.call(rbind, lapply(RES, function(z) as.list(z)))); for (n in setdiff(names(T), "lever")) T[[n]] <- as.numeric(T[[n]])
for (lv in names(NB_LEVERS)) { Ta <- T[T$lever == lv, ]; s <- Ta[order(Ta$value), ]
  dz <- if (nrow(s) > 1) (s$z_nh[nrow(s)] - s$z_nh[1]) / (log(s$value[nrow(s)]) - log(s$value[1])) else NA
  ok <- Ta[Ta$z_nh < NB_TARGET_Z, ]
  cat(sprintf("  %-14s d(z NH)/d ln(value) %+.2f; %s\n", lv, dz, if (nrow(ok)) sprintf("z NH < %+.0f at x = %s (lag z %s; d lik %s)", NB_TARGET_Z, paste(ok$x, collapse = "/"), paste(sprintf("%+.2f", ok$z_lag), collapse = "/"), paste(sprintf("%+.0f", ok$lik - base[["lik"]]), collapse = "/")) else "never brings z NH below +1 in the scan")) }
saveRDS(list(base = base, table = T, levers = NB_LEVERS, mode = CCX_MODE_CANONICAL, date = Sys.time()), NB_OUT)
cat(sprintf("saved %s\n⛔ Nothing adopted.\n", NB_OUT))
