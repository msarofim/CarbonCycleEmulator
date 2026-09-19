# =====================================================================
# diag_enso_slope_gamma_scan.R -- IS THE #13 REFIT's SLOPE GAIN REAL? (2026-09-19). The
# canonical's refit under objective #13 moved the ENSO ocean slope 0.040 -> 0.109 (0.35x ->
# 0.94x GCB) with gamma_enso_ocn_NH 0.36 -> 0.45 (+26 %) and gamma_enso_ocn_SH 0 -> 0.015,
# every other name < 5 % -- a slope that more than doubles on a quarter-turn of one knob reads
# like a kink or a bug until measured ([[implausible_result_is_a_bug]]). This scans the ocean
# ENSO pair ONE COORDINATE AT A TIME at the canonical hilda30h's point (everything else held),
# reading the slope through THE one estimator and the #13 row + the other 25 rows.
# Output: outputs/diagnostics/enso_slope_gamma_scan_<date>.{log,rds}
# Usage: Rscript calibration/diag_enso_slope_gamma_scan.R   (~1 min, C++ core)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f); ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
GS_OUT <- ccx_path("outputs", "diagnostics", sprintf("enso_slope_gamma_scan_%s", format(Sys.Date(), "%Y%m%d")))
GS_W1_NH <- 0.4516; GS_W1_SH <- 0.01531          # the #13 canonical refit's pair (obj13_canonical_refit_read_20260919)
GS_NH_GRID <- c(0.30, 0.40, 0.50, 0.60); GS_SH_GRID <- c(-0.02, 0.02, 0.05)
GS_TA2_SOLUBILITY_ONLY <- -0.1873                # the 09-17 k T-A2 scan at hilda30h: the slope with the shim OFF
sink_log <- file(paste0(GS_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE); on.exit({ sink(); close(sink_log) }, add = TRUE)
obs <- ccx_prepare_obs(); can <- dg_vector(CCX_MODE_CANONICAL)
cat(sprintf("ENSO SLOPE vs THE OCEAN ENSO PAIR, at %s's point  %s\n  obs slope %+.4f +- %.4f; T-A2 solubility-only slope at this mode %+.4f\n", CCX_MODE_CANONICAL, format(Sys.time()), obs$enso_slope[["slope"]], obs$enso_slope[["se"]], GS_TA2_SOLUBILITY_ONLY))
res <- list()
sl <- function(v, lab) { r <- dg_run(v); s <- dg_annual_sinks(r); es <- ccx_enso_slope(s$year, s$ocean, obs$enso_idx); st <- dg_streams(r, v, obs = obs)
  o <- c(nh = v$p$gamma_enso_ocn_NH, sh = v$p$gamma_enso_ocn_SH, slope = es[["slope"]], row = st[["gcb_ocean_enso_slope"]], other25 = sum(st[setdiff(names(st), "gcb_ocean_enso_slope")]))
  cat(sprintf("  %-34s gNH %+.4f gSH %+.5f  slope %+.4f (%.2fx)  row %+.2f  other 25 rows %.2f\n", lab, o[["nh"]], o[["sh"]], o[["slope"]], o[["slope"]] / obs$enso_slope[["slope"]], o[["row"]], o[["other25"]]))
  res[[lab]] <<- o }
set_g <- function(v, nh, sh) { v$pm$gamma_enso_ocn_NH <- nh; v$pm$gamma_enso_ocn_SH <- sh; v$p <- ccx_set_enso(v$p, v$pm); v }
sl(can, "canonical as stored")
sl(set_g(can, GS_W1_NH, can$p$gamma_enso_ocn_SH), "NH -> w1's only")
sl(set_g(can, can$p$gamma_enso_ocn_NH, GS_W1_SH), "SH -> w1's only")
sl(set_g(can, GS_W1_NH, GS_W1_SH), "both -> w1's pair")
for (g in GS_NH_GRID) sl(set_g(can, g, 0), sprintf("NH -> %.2f, SH 0", g))
for (g in GS_SH_GRID) sl(set_g(can, can$p$gamma_enso_ocn_NH, g), sprintf("NH as stored, SH -> %+.2f", g))
nh <- do.call(rbind, res[grep("^NH -> [0-9]", names(res))]); fit <- stats::lm(slope ~ nh, data = as.data.frame(nh))
cat(sprintf("\n  the slope is LINEAR in gamma_enso_ocn_NH over [%.2f, %.2f]: %+.4f per unit, intercept %+.4f (max residual %.1e)\n", min(nh[, "nh"]), max(nh[, "nh"]), coef(fit)[[2]], coef(fit)[[1]], max(abs(residuals(fit)))))
cat(sprintf("  the intercept vs the T-A2 solubility-only slope %+.4f: %s -- the shim ADDS a linear term to the solubility slope; the canonical's 0.36 sat where they nearly cancel\n", GS_TA2_SOLUBILITY_ONLY, if (abs(coef(fit)[[1]] - GS_TA2_SOLUBILITY_ONLY) < 0.01) "AGREE (< 0.01)" else "DISAGREE"))
cat(sprintf("  the other 25 rows across the NH grid: range %.2f .. %.2f (%.2f log-units) -- the objective WITHOUT the row is flat in this coordinate, which is why it was never set (09-18 b/e)\n", max(nh[, "other25"]), min(nh[, "other25"]), max(nh[, "other25"]) - min(nh[, "other25"])))
saveRDS(list(res = res, fit = coef(fit), built = format(Sys.time())), paste0(GS_OUT, ".rds")); cat(sprintf("\nsaved %s.{log,rds}\n", GS_OUT))
