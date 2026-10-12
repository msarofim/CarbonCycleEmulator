source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3/load.R")
S <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3"
d <- ccx_default_params(); d$seas_drivers <- 1; d$seas_ml <- 1
cat("defaults (h_ml", d$h_ml, ", kz", d$kz, ") seas_ml=1 substeps:", ccx_substeps_for(d), "\n")
p <- readRDS(file.path(S, "rp.rds"))$p
for (hm in c(64.63, 68, 70, 72, 73)) { q <- p; q$h_ml <- hm; cat("canonical at h_ml", hm, "substeps:", tryCatch(ccx_substeps_for(q), error = function(e) conditionMessage(e)), "\n") }
print(CCX_PARAM_TABLE$h_ml[c("lo","hi","init")]); print(CCX_PARAM_TABLE$kz[c("lo","hi","init")])
