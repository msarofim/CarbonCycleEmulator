for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
md <- readRDS(ccx_mode_file()); invisible(ccx_apply_gate(ccx_mode_struct(md))); invisible(ccx_apply_pins(ccx_mode_pins(md)))
invisible(ccx_adopt_mode_band(md))
for (n in CCX_PARAM_NAMES) { cat("=====", n, " tr=", CCX_PARAM_TABLE[[n]]$tr, " lo=", CCX_PARAM_TABLE[[n]]$lo, " hi=", CCX_PARAM_TABLE[[n]]$hi, "\n"); print(CCX_PARAM_TABLE[[n]]$prior) }
