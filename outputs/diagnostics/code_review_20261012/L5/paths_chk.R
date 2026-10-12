setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
md <- readRDS(ccx_mode_file())
cat(md$promoted_from$kind, "\n\n", md$promoted_from$why, "\n\n", md$promoted_from$file, "\n")
cat("registered files exist:\n"); for (n in names(CCX_MODE_FILES)) cat(sprintf("  %-10s %s\n", n, file.exists(ccx_mode_file(n))))
for (v in ls(pattern = "^CCX_MODE_.*QUARANTINED$|^CCX_MODE_COLUMN_CONTROL$|MODULE_FILE$|MODULE_CHECK$")) cat(sprintf("  %-34s exists=%s\n", v, file.exists(ccx_path(get(v)))))
cat("PINNED registry vs file:\n"); for (n in names(CCX_MODE_FILES)) { m <- readRDS(ccx_mode_file(n)); cat(sprintf("  %-10s registry=%s file=%s struct=%s seas_ml=%s spinup=%s npins=%d nfit=%d\n", n, CCX_MODE_PINNED[[n]], ccx_mode_pinned(m), ccx_mode_struct(m), ccx_mode_seas_ml(m), ccx_mode_spinup(m), length(m$pins), length(m$param_names))) }
setdiff(names(CCX_MODE_FILES), names(CCX_MODE_PINNED)); setdiff(names(CCX_MODE_PINNED), names(CCX_MODE_FILES))
cat("free name:", ccx_mode_free_name(), "\n")
r <- readRDS(ccx_path("data","futures_ribbons.rds")); cat("ribbons mode:", r$provenance[["mode"]], "\n")
print(ccx_ribbons_problems(r, scenarios = unique(r$bands$scenario), vars = unique(r$bands$var)))
cm <- readRDS(ccx_path("data","constraint_map.rds")); cat("cmap mode:", cm$provenance[["mode"]], "\n"); print(ccx_cmap_problems(cm))
mc <- readRDS(ccx_path(CCX_MODE_CANONICAL_MODULE_CHECK)); cat("module check names:", names(mc), "\n")
# check the decode gate
print(tryCatch(ccx_check_mode_decode(md), error=function(e) conditionMessage(e)))
# ccx_mode_params with pins equals par_mode + pins
pp <- ccx_mode_params(md); cat("mode_params n:", length(pp), " has pins:", all(names(md$pins) %in% names(pp)), "\n")
# file.exists precedence: a relative path
cat(ccx_mode_file("hilda29e"), "\n")
