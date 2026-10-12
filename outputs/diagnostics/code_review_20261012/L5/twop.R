setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
lm <- ccx_load_mode(); md <- lm$md
rp <- ccx_mode_run_params(md, ccx_mode_par_with_pins(md))
a <- lm$p; b <- rp$p
cat("identical:", identical(a, b), "\n")
cat("names only in load_mode:", setdiff(names(a), names(b)), "\n"); cat("names only in run_params:", setdiff(names(b), names(a)), "\n")
for (n in intersect(names(a), names(b))) if (!identical(a[[n]], b[[n]])) cat(sprintf("  differ %s: %s vs %s\n", n, paste(format(a[[n]]), collapse=","), paste(format(b[[n]]), collapse=",")))
cat("attrs a:", names(attributes(a)), " b:", names(attributes(b)), "\n")
cat("bomb/luc:", lm$bomb_total, rp$bomb_total, lm$luc_scale, rp$luc_scale, "\n")
