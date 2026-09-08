# =====================================================================
# T-L (handoff 2026-09-08g §1): COMPARISON L (a gate until the 09-08h ruling) -- the LAND share of a 100 GtC pulse at
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
# ⛔ RULED 2026-09-08h (Marcus), after this script first ran: "Do not use Joos as a scoring
# mechanism: the long lifetime is meant to be an emergent property, not something we fit to."
# GATE L is therefore a COMPARISON: the partition and its z's are REPORTED; nothing passes.
RES <- list()
for (a in TL_ARMS) {
  t0 <- Sys.time(); g <- dg_gateL_partition(arm_of(a)); cm <- dg_compareL(g)
  RES[[a]] <- list(g = g[setdiff(names(g), "share_at")], shares = t(vapply(TL_HORIZONS, g$share_at, numeric(3))), compare = cm)
  cat(sprintf("\n  %-14s background held to %.3f ppm; closure at %d yr %.6f; %.0f s\n", a, g$hold_dev, DG_L_HORIZON, g$closure, as.numeric(Sys.time() - t0, units = "secs")))
  for (k in seq_along(TL_HORIZONS)) cat(sprintf("    %5d yr: land %5.1f  ocean %5.1f  air %5.1f %%\n", TL_HORIZONS[k], RES[[a]]$shares[k, "land"], RES[[a]]$shares[k, "ocean"], RES[[a]]$shares[k, "air"]))
  cat(sprintf("    COMPARISON L at %d yr: land %.1f %% (Joos %g +/- %g: %+.2f sd), ocean %+.2f sd, air %+.2f sd -- REPORTED, not gated\n", DG_L_HORIZON, cm$share[["land"]], DG_L_JOOS$land[["mean"]], DG_L_JOOS$land[["sd"]], cm$z[["land"]], cm$z[["ocean"]], cm$z[["air"]]))
}
cat("\n=== READING (no verdict by ruling) ===\n")
cat(sprintf("  the canonical's land share at %d yr sits %+.2f ensemble-sd from Joos's mean; the land-off arm %+.2f; the column control %+.2f.\n", DG_L_HORIZON, RES$canonical$compare$z[["land"]], RES$land_off$compare$z[["land"]], RES$column_control$compare$z[["land"]]))
saveRDS(list(arms = RES, horizons = TL_HORIZONS, joos = DG_L_JOOS, mode = CCX_MODE_CANONICAL, date = Sys.time()), TL_OUT)
cat(sprintf("saved %s\n⛔ Nothing adopted; L is a comparison.\n", TL_OUT))
