for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
PINS <- ccx_parse_pins(Sys.getenv("CCX_MS_PIN", "")); invisible(ccx_apply_pins(PINS))
source(ccx_path("calibration", "lib_run_inputs.R")); ccx_require_run_inputs()
bp <- ccx_default_params(); bp$pump_mode <- "N"
bp <- ccx_apply_structure(bp, Sys.getenv("CCX_MS_STRUCT"), Sys.getenv("CCX_MS_SEAS_ML"), pump_field = Sys.getenv("CCX_MS_PUMP_FIELD", "solved"))
for (n in names(PINS)) bp[[n]] <- PINS[[n]]
u_of <- function(f) { md <- readRDS(ccx_path(f)); ccx_par_to_unc(ccx_seed_unencodable(ccx_migrate_par_set(ccx_mode_par_with_pins(md)), "diag")) }
p_of <- function(u) { pv <- ccx_unc_to_par(u); p <- bp; for (n in names(pv)) p[[n]] <- pv[[n]]; p }
for (nm in c("incumbent", "new_basin")) {
  u <- u_of(if (nm == "incumbent") CCX_MODE_FILES[[CCX_MODE_CANONICAL]] else CCX_MODE_FILES[["hilda31p"]])
  sp0 <- ccx_periodic_spinup(p_of(u)); y0 <- sp0$y
  set.seed(3); rel <- NULL
  for (k in 1:4) { du <- u; j <- sample(length(u), 1); du[j] <- du[j] * (1 + 1e-12)
    y1 <- ccx_periodic_spinup(p_of(du))$y
    rel <- rbind(rel, vapply(c("C", "C13", "C14"), function(tr) max(abs(y1[, tr] - y0[, tr]) / abs(y0[, tr])), numeric(1))) }
  d13 <- ((y0[, "C13"] / y0[, "C"]) / ccx_const("R13_VPDB") - 1) * 1000
  cat(sprintf("%s: spinup max relative change per tracer under u*(1+1e-12), 4 draws:\n", nm)); print(signif(rel, 3))
  cat(sprintf("   d13C range of the spinup state: %.2f to %.2f permil; prod_c14 %.6g\n", min(d13), max(d13), sp0$prod_c14))
}
