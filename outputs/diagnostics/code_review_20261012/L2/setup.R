setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
SCR <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L2"
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
pm <- ccx_mode_par_with_pins(md)
rp <- ccx_mode_run_params(md, pm, base = ccx_mode_base(md))
p <- rp$p
