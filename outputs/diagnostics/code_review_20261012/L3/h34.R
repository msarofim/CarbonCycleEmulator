source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L3/load.R")
for (m in c("hilda34g", CCX_MODE_CANONICAL)) { md <- readRDS(ccx_mode_file(m)); cat(m, ":", md$struct, " seas_ml", md$seas_ml, "\n") }
cat("canonical name:", CCX_MODE_CANONICAL, "\n")
