# =====================================================================
# T-L (handoff 2026-09-08g §1): GATE L -- the LAND share of a 100 GtC pulse at
# 100 and 1000 yr against Joos et al. 2013's multi-model split, at the
# canonical hilda31, with its mutation arm (land CO2 fertilisation OFF).
#
# PRE-REGISTERED: the canonical FAILS (land > 30 % at 1000 yr).
# FALSIFIED IF: it passes -- then option H's reading is wrong.
# MUTATION: a land-off arm (beta_max 0) must fail the OTHER way (< 2 %).
#
# The gate itself is dg_gateL_partition() / dg_gateL_verdict() in
# lib_design_gates.R (ledger id "L"); kernel mutation tests in
# tests/testthat/test-gate-bounds.R. Nothing is adopted.
# Usage: Rscript calibration/diag_tl_land_share_gate.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

TL_HORIZONS <- c(20, 100, 300, 1000)
TL_ARMS <- c("canonical", "land_off", "column_control")
TL_OUT <- ccx_path("outputs", "diagnostics", sprintf("tl_land_share_gate_%s.rds", format(Sys.Date(), "%Y%m%d")))

v <- dg_vector(CCX_MODE_CANONICAL)
arm_of <- function(a) switch(a,
  canonical = v,
  land_off  = { w <- v; w$p$beta_max <- 0; w },         # no CO2 fertilisation: the land cannot take up the pulse
  column_control = dg_vector(CCX_MODE_COLUMN_CONTROL))
cat(sprintf("GATE L at %s: Joos 2013 1000-yr split land %g +/- %g, ocean %g +/- %g, air %g +/- %g %% (%s); bound |z_land| <= %g -> [%g, %g] %%\n",
            CCX_MODE_CANONICAL, DG_L_JOOS$land[["mean"]], DG_L_JOOS$land[["sd"]], DG_L_JOOS$ocean[["mean"]], DG_L_JOOS$ocean[["sd"]], DG_L_JOOS$air[["mean"]], DG_L_JOOS$air[["sd"]], DG_L_JOOS$src, DG_L_NSD,
            DG_L_JOOS$land[["mean"]] - DG_L_NSD * DG_L_JOOS$land[["sd"]], DG_L_JOOS$land[["mean"]] + DG_L_NSD * DG_L_JOOS$land[["sd"]]))
RES <- list()
for (a in TL_ARMS) {
  t0 <- Sys.time(); g <- dg_gateL_partition(arm_of(a)); vd <- dg_gateL_verdict(g)
  RES[[a]] <- list(g = g[setdiff(names(g), "share_at")], shares = t(vapply(TL_HORIZONS, g$share_at, numeric(3))), verdict = vd)
  cat(sprintf("\n  %-14s background held to %.3f ppm; closure at %d yr %.6f; %.0f s\n", a, g$hold_dev, DG_L_HORIZON, g$closure, as.numeric(Sys.time() - t0, units = "secs")))
  for (k in seq_along(TL_HORIZONS)) cat(sprintf("    %5d yr: land %5.1f  ocean %5.1f  air %5.1f %%\n", TL_HORIZONS[k], RES[[a]]$shares[k, "land"], RES[[a]]$shares[k, "ocean"], RES[[a]]$shares[k, "air"]))
  cat(sprintf("    GATE L at %d yr: land %.1f %% -> z %+.2f (ocean z %+.2f, air z %+.2f) -> %s%s\n", DG_L_HORIZON, vd$share[["land"]], vd$z[["land"]], vd$z[["ocean"]], vd$z[["air"]], if (vd$pass) "PASS" else "FAIL",
              if (!vd$pass) sprintf(" (%s edge)", if (vd$z[["land"]] > 0) "UPPER" else "LOWER") else ""))
}
cat("\n=== VERDICT ===\n")
vc <- RES$canonical$verdict; vm <- RES$land_off$verdict
cat(sprintf("  prediction 'the canonical FAILS, land > %g %% at %d yr': land %.1f %% -> %s\n", vc$hi, DG_L_HORIZON, vc$share[["land"]], if (!vc$pass && vc$z[["land"]] > 0) "CONFIRMED" else if (vc$pass) "FALSIFIED (it passes: H's reading is wrong)" else "FAILS, but at the LOWER edge"))
cat(sprintf("  mutation 'land-off fails the other way (< %g %%)': land %.1f %% -> %s\n", vm$lo, vm$share[["land"]], if (!vm$pass && vm$z[["land"]] < 0) "PASS (the gate has power both ways)" else "THE MUTATION DID NOT FAIL THE LOWER EDGE -- the gate is blind there"))
cat(sprintf("  at 2 sd of the ensemble spread the canonical would %s (band [%g, %g]).\n", if (abs(vc$z[["land"]]) <= 2) "PASS" else "still FAIL", DG_L_JOOS$land[["mean"]] - 2 * DG_L_JOOS$land[["sd"]], DG_L_JOOS$land[["mean"]] + 2 * DG_L_JOOS$land[["sd"]]))
saveRDS(list(arms = RES, horizons = TL_HORIZONS, joos = DG_L_JOOS, n_sd = DG_L_NSD, mode = CCX_MODE_CANONICAL, date = Sys.time()), TL_OUT)
cat(sprintf("saved %s\n⛔ Nothing adopted.\n", TL_OUT))
