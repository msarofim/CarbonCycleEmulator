for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
for (m in names(CCX_MODE_FILES)) { md <- tryCatch(readRDS(ccx_mode_file(m)), error=function(e) NULL); if (is.null(md)) next
  b <- ccx_mode_bands(md); cat(sprintf("%-10s kz %-22s h_ml %-14s kz_mode %s\n", m, paste(b$kz, collapse=","), paste(b$h_ml, collapse=","), format(md$par_mode$kz))) }
cat("table kz:", CCX_PARAM_TABLE$kz$lo, CCX_PARAM_TABLE$kz$hi, " h_ml:", CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi, "\n")
