# =====================================================================
# diag_shim_conditional_price.R -- test (b) of the 09-18 control result: the PIN's
# price ALONE, conditionally. The refit seas_ml-0 control (shim FREE 18.03) beats
# the canonical hilda30h (seasonal ML ON, shim PINNED 0) by +10.31 on the 25 rows,
# +7.25 of it on d13c_seasonal_MLO. Two things differ between the arms: the ML and
# the pin. This scans the shim `ent_seas_amp_SH` at the CANONICAL's point with every
# other coordinate FROZEN (ML on) and reads the likelihood by row. It prices the pin
# CONDITIONALLY -- a lower bound on what a refit with the shim free would recover
# ([[ccx_gates_priced]]: frozen slices misprice; the refit is test (a), running).
# Also the mirror: the refit control c1's point (ML off) with the shim set to 0.
# Usage: Rscript calibration/diag_shim_conditional_price.R   (~1 min, C++ core)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
SC_GRID <- c(0, 2, 5, 10, 15, 18.03, 20, 25)          # 18.03 = the refit control's fitted shim
SC_C1   <- 18L                                        # the control refit's rank-1 start
SC_DIR  <- ccx_path("calibration", "output", "multistart_20260917_hilda_c_seasml0_pin_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_sd1.0452")
SC_OUT  <- ccx_path("outputs", "diagnostics", sprintf("shim_conditional_price_%s", format(Sys.Date(), "%Y%m%d")))
SC_ROWS <- c("d13c_seasonal_MLO", "d13c_seasonal_SPO", "co2_seasonal_MLO", "co2_seasonal_SPO", "ocean_grad_dic", "ocean_grad_d13c")
sink_log <- file(paste0(SC_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE); on.exit({ sink(); close(sink_log) }, add = TRUE)
obs <- ccx_prepare_obs()
v <- dg_vector(CCX_MODE_CANONICAL)
st0 <- unlist(dg_streams(dg_run(v), v, obs = obs)); d0 <- sum(st0[names(v$md$streams)]) - sum(unlist(v$md$streams))
cat(sprintf("canonical %s reproduces its %d stored rows to %.1e (lik %.4f)\n", CCX_MODE_CANONICAL, length(v$md$streams), d0, sum(st0))); stopifnot(abs(d0) < 1e-3)
scan <- function(v, grid, label) {
  cat(sprintf("\n=== %s: ent_seas_amp_SH scanned, every other coordinate FROZEN ===\n", label))
  cat(sprintf("%8s %10s %8s   %s\n", "shim", "lik", "d vs 0", paste(sprintf("%18s", SC_ROWS), collapse = "")))
  out <- list()
  for (a in grid) { vv <- v; vv$p$ent_seas_amp_SH <- a; vv$pm$ent_seas_amp_SH <- a
    st <- unlist(dg_streams(dg_run(vv), vv, obs = obs)); out[[length(out) + 1]] <- list(shim = a, st = st)
    if (a == grid[1]) base <- st
    cat(sprintf("%8.2f %10.2f %+8.2f   %s\n", a, sum(st), sum(st) - sum(base), paste(sprintf("%+18.2f", st[SC_ROWS] - base[SC_ROWS]), collapse = ""))) }
  out
}
S1 <- scan(v, SC_GRID, sprintf("the CANONICAL's point (seasonal ML ON), shim from its pin 0"))
# the mirror: the refit control's point, ML off, shim from its fitted value down to 0
s <- readRDS(file.path(SC_DIR, sprintf("start_%03d.rds", SC_C1))); pins <- s$pins
p <- ccx_default_params(); p$pump_mode <- s$pump_mode; p <- ccx_apply_structure(p, s$struct, s$seas_ml, pump_field = s$pump_field)
for (n in names(pins)) p[[n]] <- pins[[n]]; pm <- s$par_mode; for (n in names(pins)) pm[[n]] <- pins[[n]]
for (n in intersect(names(p), names(pm))) p[[n]] <- pm[[n]]; p <- ccx_set_enso(p, pm)
vc <- list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total, sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC, grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c,
           spinup = CCX_OBJECTIVE_SPINUP, spinup_label = "periodic", pins = pins, src = sprintf("start_%03d", SC_C1))
S2 <- scan(vc, rev(SC_GRID), sprintf("the REFIT CONTROL c1's point (seasonal ML OFF), shim from its fitted %.2f down to 0", pm$ent_seas_amp_SH))
best1 <- S1[[which.max(vapply(S1, function(x) sum(x$st), numeric(1)))]]; base1 <- S1[[1]]
cat(sprintf("\nCONDITIONAL price of the pin at the canonical: the best shim on the grid is %.2f, worth %+.2f over the pin at 0 (of the +10.31 the refit control has over the canonical)\n",
            best1$shim, sum(best1$st) - sum(base1$st)))
cat("  -> the remainder is what a REFIT with the shim free must recover, or is the ML's own cost; test (a) (the free parent's refit) decides.\n")
saveRDS(list(canonical = S1, control_c1 = S2, grid = SC_GRID, built = format(Sys.time())), paste0(SC_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}\n", SC_OUT))
