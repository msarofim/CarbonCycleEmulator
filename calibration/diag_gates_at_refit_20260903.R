# ===================================================================
# THE DESIGN GATES AT THE 2026-09-03 REFIT WINNER.
# ⛔ EVERY GATE NUMBER ON RECORD PREDATES THIS VECTOR. The ledger was measured
# at `from90` (a 21-parameter ancestor) and before three 09-02 objective
# changes; the refit then moved the logpost +61.07. Quoting those numbers as
# "the state of the model" would be reporting a model that no longer exists.
# ===================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

D  <- "calibration/output/multistart_20260902_demean25"
S  <- readRDS(file.path(D, "survey_summary.rds"))
iA <- which(S$group == "A")[which.max(S$logpost[S$group == "A"])]
res <- readRDS(S$files[iA])
pm  <- res$par_mode
# CONVERTED ON TOUCH 2026-09-03 (Ruling B). The bare `intersect()` loop this
# replaces assigns NULL for any name the fitted set lacks, which DELETES the
# element and drops the run on a NAMED DEFAULT with nothing said. It was inert
# while the stored vector and the build both had 25 names; `ent_seas_amp_SH`
# entering the table the same day made it live. ccx_overlay_par() migrates,
# copies, calls ccx_set_enso(), and ASSERTS the overlay deleted nothing.
p   <- ccx_overlay_par(ccx_default_params(), pm)
p$pump_mode <- res$pump_mode
v <- list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total,
          sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC,
          grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c,
          md = NULL, migrated = character(0),
          src = sprintf("refit id %d (logpost %.4f)", res$id, res$logpost))
cat(sprintf("\n=== GATES AT %s ===\n", v$src))
r <- dg_run(v)

g4 <- dg_gate4(r, v)
cat("\n-- GATE 4 (airborne fraction): RETIRED 2026-09-04, REPORTED ONLY --\n")
cat(sprintf("   %s\n", DG_G4_RETIRED))
cat(sprintf("   AF %.4f vs GCB %.4f;  decadal sd %.4f vs %.4f\n",
            g4$all, DG_AF_OBS, stats::sd(g4$dec), stats::sd(DG_AF_OBS_DEC)))
cat("\n-- GATE V (interannual CO2 growth variability) --\n")
print(dg_gateV_verdict(dg_gateV(r), dg_gateV_obs()))
g5 <- dg_gate5(r); ob <- dg_obs_gate5(); sp <- dg_obs_gate5_spread()
cat("\n-- GATE 5 (bomb 14C) --\n"); print(dg_gate5_verdict(g5, ob, sp))
DG_TGT <- dg_gcb_target(DG_SINK_WIN)
g7 <- dg_gate7(r); cat(sprintf("\n-- GATE 7 (sinks), GCB %d-%d --\n", DG_SINK_WIN[1], DG_SINK_WIN[2]))
print(g7); print(dg_gate7_verdict(g7, DG_TGT))
cat("\n-- GATE Q (air-sea d13C disequilibrium) --\n"); print(dg_gateQ(r, v))
gr <- tryCatch(ccx_glodap_grid(), error = function(e) NULL)
if (!is.null(gr)) { ob2 <- dg_gateG_obs(gr)
  cat("\n-- GATE G (ocean surface DIC vs GLODAP) --\n")
  print(dg_gateG_verdict(dg_gateG(v, ob2), ob2)) } else cat("\n-- GATE G: grid unavailable --\n")
