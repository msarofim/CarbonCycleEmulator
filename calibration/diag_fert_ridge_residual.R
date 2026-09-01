# =====================================================================
# diag_fert_ridge_residual.R -- AFTER rep_dC RE-OPTIMISES, WHAT STILL OBJECTS?
# (2026-08-25)
#
# diag_fert_ridge_repdc.R showed rep_dC gives back a flat ~67 % of the
# saturation cost at every cell, and falls MONOTONICALLY to its prior centre:
# 5.566 (mode) -> 4.98 (K=400) -> 2.87 (180) -> 1.37 (120) -> 0.15 (90) ->
# -1.75 (60). At fert_k ~ 90 the 5.6-sigma blocker is ZERO.
#
# But 33 % of the cost survives -- 1550 log-units at K=90, 913 at K=120. That
# residue decides what a refit should be asked to do, so it has to be named
# rather than attributed to "the frozen vector" as a blanket excuse. Two very
# different possibilities:
#
#   * still the CO2 LEVEL streams => the miss is a SHAPE the offset cannot
#     reach (an offset is one number; a wrong trajectory is not), and a refit
#     would have to find that shape elsewhere;
#   * something else => the offset has done its job and a different stream is
#     the binding constraint.
#
# Usage:  Rscript calibration/diag_fert_ridge_residual.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

FD_MODE_FILE <- ccx_mode_file()
FD_YEARS <- c(1750, 2024); FD_CHI_NOW <- 420
FD_KGRID <- c(60, 90, 120, 180)
FD_GRID  <- seq(-12, 12, by = 0.01)
OUTDIR   <- ccx_path("calibration", "output", "fert_ridge_gates")
CHI0 <- ccx_const("CO2_PI_PPM")

md <- readRDS(FD_MODE_FILE)
P0 <- ccx_default_params()
for (n in intersect(names(P0), CCX_PARAM_NAMES)) P0[[n]] <- md$par_mode[[n]]
P0 <- ccx_set_enso(P0, md$par_mode); P0$pump_mode <- md$pump_mode
LUC0 <- md$par_mode$luc_scale; BOMB0 <- md$par_mode$bomb_total; REP0 <- md$par_mode$rep_dC
OBS <- ccx_prepare_obs()
d_now <- FD_CHI_NOW - CHI0
ENH0  <- P0$beta_max * d_now / (P0$fert_k + d_now)

fd_cell <- function(K) {
  p <- P0
  if (!is.na(K)) { p$fert_k <- K; p$beta_max <- ENH0 * (K + d_now) / d_now }
  sp <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", FD_YEARS, prod_c14 = sp$prod_c14,
                         bomb_total_kmol = BOMB0, luc_scale = LUC0)
  o <- ccx_run_fast(sp, F)$out
  el <- ccx_forcing_eluc_annual(F); dp <- sp$diagnostics$d14c_bottom_box
  og <- ccx_ocean_grad_scored(o, sp)
  st <- function(r) unlist(ccx_loglik(o, OBS,
         list(sigma_d14c = md$par_mode$sigma_d14c, rep_dC = r,
              grad_off_co2 = md$par_mode$grad_off_co2,
              grad_off_d13c = md$par_mode$grad_off_d13c),
         luc = el, deep = dp, ocean_grad = og, by_stream = TRUE))
  v <- vapply(FD_GRID, function(r) sum(st(r)), numeric(1)) +
       stats::dnorm(FD_GRID, 0, LIK_CO2_REP_ERR, log = TRUE)
  rb <- FD_GRID[which.max(v)]
  list(rep = rb, s = st(rb))
}

ref <- fd_cell(NA)
cat(sprintf("\n=== RESIDUAL AFTER rep_dC RE-OPTIMISES (reference = mode, rep_dC %.3f) ===\n", ref$rep))
C <- lapply(FD_KGRID, fd_cell); names(C) <- sprintf("K=%g", FD_KGRID)
D <- vapply(C, function(c_) c_$s[names(ref$s)] - ref$s, numeric(length(ref$s)))
cat(sprintf("rep_dC at each cell: %s\n\n",
            paste(sprintf("%s %.3f", names(C), vapply(C, function(c_) c_$rep, numeric(1))), collapse = ",  ")))
cat(sprintf("%-22s %10s | %s\n", "stream", "mode logL",
            paste(sprintf("%9s", colnames(D)), collapse = "")))
for (nm in names(ref$s)[order(D[, 1])]) {
  if (max(abs(D[nm, ])) < 0.5) next
  cat(sprintf("%-22s %10.1f | %s\n", nm, ref$s[[nm]],
              paste(sprintf("%+9.1f", D[nm, ]), collapse = "")))
}
cat(sprintf("%-22s %10.1f | %s\n", "TOTAL (likelihood)", sum(ref$s),
            paste(sprintf("%+9.1f", colSums(D)), collapse = "")))
cat(sprintf("%-22s %10s | %s\n", "  CO2 station levels", "",
            paste(sprintf("%+9.1f", colSums(D[grepl("^co2_level", rownames(D)), , drop = FALSE])), collapse = "")))
cat(sprintf("%-22s %10s | %s\n", "  everything else", "",
            paste(sprintf("%+9.1f", colSums(D[!grepl("^co2_level", rownames(D)), , drop = FALSE])), collapse = "")))
saveRDS(list(ref = ref, C = C, D = D), file.path(OUTDIR, "fert_ridge_residual.rds"))
cat(sprintf("\nwritten: %s\n", file.path(OUTDIR, "fert_ridge_residual.rds")))
