for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_glodap_obs.R"))
D <- "calibration/output/multistart_20260902_demean25"
S <- readRDS(file.path(D, "survey_summary.rds"))
iA <- which(S$group=="A")[which.max(S$logpost[S$group=="A"])]
res <- readRDS(S$files[iA]); pm <- res$par_mode
p <- ccx_default_params(); for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pm[[n]]
p <- ccx_set_enso(p, pm); p$pump_mode <- res$pump_mode
v <- list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total)
gr <- ccx_ocean_grid(p$h_ml); obs <- dg_gateG_obs(gr)
g  <- dg_gateG(v, obs); vd <- dg_gateG_verdict(g, obs)
cat(sprintf("\n  GATE G at the refit winner (h_ml %.2f m)\n", p$h_ml))
str(vd, max.level = 1)
