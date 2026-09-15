# diag_port_gate_id1_20260914.R -- WHY does Torch reproduce the incumbent port target
# only to rel 2.16e-8 (tol 1e-8) while the cold and new-basin points reproduce at 1e-11?
# Hypothesis: a DISCRETE choice in the evaluation (substep count via ceiling(need), the
# NaN-retry doubling, or the periodic spinup's Newton iteration count against PS_TOL)
# flips on roundoff at that point. Test: (1) report the discrete quantities at each of the
# three reference points; (2) perturb u at ROUNDOFF scale and measure the objective's jump
# -- a smooth objective moves ~1e-9 relative, a flipped discrete choice ~1e-5 absolute.
# Run with the array's env: CCX_MS_STRUCT=hilda_c CCX_MS_SEAS_ML=1 CCX_MS_PUMP_FIELD=martin
#   CCX_MS_PIN=ent_seas_amp_SH=0,pump_grad=314.1031,gamma_enso_ocn_NH=0,gamma_enso_ocn_SH=0
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
PINS <- ccx_parse_pins(Sys.getenv("CCX_MS_PIN", "")); invisible(ccx_apply_pins(PINS))
source(ccx_path("calibration", "lib_run_inputs.R")); ccx_require_run_inputs()
bp <- ccx_default_params(); bp$pump_mode <- "N"
bp <- ccx_apply_structure(bp, Sys.getenv("CCX_MS_STRUCT"), Sys.getenv("CCX_MS_SEAS_ML"),
                          pump_field = Sys.getenv("CCX_MS_PUMP_FIELD", "solved"))
for (n in names(PINS)) bp[[n]] <- PINS[[n]]
lp <- ccx_make_logpost(base_params = bp)
refs <- list(cold = NULL, incumbent = CCX_MODE_FILES[[CCX_MODE_CANONICAL]],
             new_basin = CCX_MODE_FILES[["hilda31p"]])
u_of <- function(f) {
  if (is.null(f)) return(ccx_init_unc())
  md <- readRDS(ccx_path(f))
  pmv <- ccx_seed_unencodable(ccx_migrate_par_set(ccx_mode_par_with_pins(md)), "diag")
  ccx_par_to_unc(pmv)
}
TORCH <- c(cold = -16020.0716742163, incumbent = -2666.7197790059, new_basin = -2495.5813468771)
for (nm in names(refs)) {
  u <- u_of(refs[[nm]]); pv <- ccx_unc_to_par(u)
  p <- bp; for (n in names(pv)) p[[n]] <- pv[[n]]
  grid <- ccx_ocean_grid(p$h_ml)
  ss <- ccx_substeps_for(p, grid)
  # `need` before the ceiling, recomputed the same way
  sp <- ccx_periodic_spinup(p)
  v0 <- lp(u)
  cat(sprintf("\n== %s: logpost %.10f (Torch %.10f, diff %+.3e, rel %.2e)\n", nm, v0, TORCH[[nm]],
              v0 - TORCH[[nm]], abs(v0 - TORCH[[nm]]) / abs(v0)))
  cat(sprintf("   substeps %d; periodic spinup: %d Newton iterations, resid history %s, resid_carbon %.3e (PS_TOL %.1e), resid_state %.3e\n",
              ss, sp$periodic$iterations, paste(sprintf("%.2e", sp$periodic$resid_history), collapse = " "),
              sp$periodic$resid_carbon, PS_TOL, sp$periodic$resid_state))
  # roundoff-scale perturbations: each coordinate by +-1e-12 relative (~ 1e4 ulp)
  set.seed(1); jumps <- numeric(0)
  for (k in 1:12) {
    du <- u; j <- sample(length(u), 1); du[j] <- du[j] * (1 + sample(c(-1, 1), 1) * 1e-12)
    jumps <- c(jumps, lp(du) - v0)
  }
  cat(sprintf("   roundoff-scale jumps (12 draws): max |d logpost| %.3e, median %.3e; values: %s\n",
              max(abs(jumps)), median(abs(jumps)), paste(sprintf("%+.1e", jumps), collapse = " ")))
}

# --- (3) SCALING at the incumbent: does |d logpost| scale with the perturbation (a gradient,
# smooth objective) or stay flat (a roundoff floor)? Same 6 coordinates at 1e-12 / 1e-10 / 1e-8.
u <- u_of(refs$incumbent); v0 <- lp(u)
set.seed(2); js <- sample(length(u), 6)
for (eps in c(1e-12, 1e-10, 1e-8)) {
  d <- vapply(js, function(j) { du <- u; du[j] <- du[j] * (1 + eps); lp(du) - v0 }, numeric(1))
  cat(sprintf("   incumbent, eps %.0e: d logpost = %s  (max |.| %.2e)\n", eps,
              paste(sprintf("%+.2e", d), collapse = " "), max(abs(d))))
}
cat(sprintf("host %s, R %s\n", Sys.info()[["nodename"]], paste(R.version$major, R.version$minor, sep = ".")))
