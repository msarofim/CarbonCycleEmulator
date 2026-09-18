# =====================================================================
# diag_enso_slope_row_price.R -- OBJECTIVE #13 (2026-09-18 e) PRICED: the GCB ENSO
# ocean-slope row `gcb_ocean_enso_slope` at every registered mode and at the two
# 09-18 refit results (the control c1, the limb array a1), each on its own
# structure + the periodic spinup. Prints the row, the model's slope vs GCB's
# +0.1153 +/- 0.0246, and the 25-row likelihood with and without the row (the
# switch flipped in-process). The numbers feed restamp_mode_objective.R's
# <expected_delta> for the three registered files.
# Usage: Rscript calibration/diag_enso_slope_row_price.R   (~2 min, C++ core)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
PR_OUT <- ccx_path("outputs", "diagnostics", sprintf("enso_slope_row_price_%s", format(Sys.Date(), "%Y%m%d")))
PR_C1_DIR <- ccx_path("calibration", "output", "multistart_20260917_hilda_c_seasml0_pin_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_sd1.0452"); PR_C1 <- 18L
PR_A1_DIR <- list.files(ccx_path("calibration", "output"), "^multistart_20260918_hilda_cl3_seasml1", full.names = TRUE)[1]; PR_A1 <- 19L
sink_log <- file(paste0(PR_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE); on.exit({ sink(); close(sink_log) }, add = TRUE)
obs <- ccx_prepare_obs()
cat(sprintf("THE ROW: GCB ocean sink ~ year + Nino3.4 (annual means), %d-%d: slope %+.4f +/- %.4f (r %+.3f, n %d); sigma = the se\n",
            LIK_ENSO_SLOPE_WIN[1], LIK_ENSO_SLOPE_WIN[2], obs$enso_slope[["slope"]], obs$enso_slope[["se"]], obs$enso_slope[["r"]], as.integer(obs$enso_slope[["n"]])))
start_vector <- function(dir, id) {
  s <- readRDS(file.path(dir, sprintf("start_%03d.rds", id))); pins <- s$pins
  .todo <- pins[names(pins) %in% CCX_PARAM_NAMES]; if (length(.todo)) invisible(ccx_apply_pins(.todo))
  p <- ccx_default_params(); p$pump_mode <- s$pump_mode; p <- ccx_apply_structure(p, s$struct, s$seas_ml, pump_field = s$pump_field)
  for (n in names(pins)) p[[n]] <- pins[[n]]; pm <- s$par_mode; for (n in names(pins)) pm[[n]] <- pins[[n]]
  for (n in intersect(names(p), names(pm))) p[[n]] <- pm[[n]]; p <- ccx_set_enso(p, pm)
  list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total, sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC, grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c,
       spinup = CCX_OBJECTIVE_SPINUP, spinup_label = "periodic", pins = pins, md = NULL, src = sprintf("%s start_%03d (logpost %.4f)", basename(dir), id, s$logpost))
}
ARMS <- list()
for (m in names(CCX_MODE_FILES)) { v <- dg_vector(m); ARMS[[m]] <- v }
ARMS$control_c1 <- start_vector(PR_C1_DIR, PR_C1)
ARMS$limb_a1    <- start_vector(PR_A1_DIR, PR_A1)
toggle <- function(on, f) { old <- LIK_USE_GCB_ENSO_SLOPE; assign("LIK_USE_GCB_ENSO_SLOPE", on, envir = globalenv()); on.exit(assign("LIK_USE_GCB_ENSO_SLOPE", old, envir = globalenv()), add = TRUE); f() }
cat(sprintf("\n%-12s %-9s %8s %10s %10s %8s %10s %10s %10s\n", "arm", "struct", "seas_ml", "model", "z", "row", "lik #12", "lik #13", "stored"))
res <- list()
for (a in names(ARMS)) { v <- ARMS[[a]]; r <- dg_run(v)
  st13 <- toggle(TRUE, function() unlist(dg_streams(r, v, obs = obs))); st12 <- toggle(FALSE, function() unlist(dg_streams(r, v, obs = obs)))
  row <- st13[["gcb_ocean_enso_slope"]]; z <- -sqrt(pmax(0, -2 * (row + log(obs$enso_slope[["se"]] * sqrt(2 * pi)))))
  ms <- obs$enso_slope[["slope"]] + z * obs$enso_slope[["se"]]     # the model slope, recovered from the row (sign: below obs)
  stored <- if (!is.null(v$md)) sum(unlist(v$md$streams)) else NA_real_
  if (!is.null(v$md)) stopifnot(abs(sum(st12[names(v$md$streams)]) - stored) < 1e-3)     # the registered files reproduce under #12 first
  res[[a]] <- c(row = row, model_slope = ms, z = z, lik12 = sum(st12), lik13 = sum(st13), stored = stored)
  cat(sprintf("%-12s %-9s %8s %+10.4f %+10.2f %8.3f %10.4f %10.4f %10s\n", a, attr(v$p, "struct"), attr(v$p, "seas_ml"), ms, z, row, sum(st12), sum(st13), if (is.na(stored)) "-" else sprintf("%.4f", stored))) }
cat("\n  (the model slope is recovered from the row assuming the model is BELOW the obs, which every arm here is; 'stored' = the file's #12 streams, reproduced to 1e-3 before pricing)\n")
cat(sprintf("\nRESTAMP deltas for the registered files (= the row): %s\n", paste(sprintf("%s %+.4f", names(CCX_MODE_FILES), vapply(names(CCX_MODE_FILES), function(a) res[[a]][["row"]], numeric(1))), collapse = ", ")))
cat(sprintf("the canonical beats the registered control under #13 by %+.2f (was %+.2f under #12); the refit control c1 beats the canonical by %+.2f under #13 (was %+.2f)\n",
            res[[CCX_MODE_CANONICAL]][["lik13"]] - res[[CCX_MODE_SEASML0_CONTROL]][["lik13"]], res[[CCX_MODE_CANONICAL]][["lik12"]] - res[[CCX_MODE_SEASML0_CONTROL]][["lik12"]],
            res$control_c1[["lik13"]] - res[[CCX_MODE_CANONICAL]][["lik13"]], res$control_c1[["lik12"]] - res[[CCX_MODE_CANONICAL]][["lik12"]]))
saveRDS(list(obs_slope = obs$enso_slope, arms = res, built = format(Sys.time()), commit = system("git rev-parse --short HEAD", intern = TRUE)), paste0(PR_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}\n", PR_OUT))
