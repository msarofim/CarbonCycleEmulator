# ccx_prior_z is PER-PARAMETER and takes the PHYSICAL value.
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
D <- "calibration/output/multistart_20260902_demean25"
S <- readRDS(file.path(D, "survey_summary.rds"))
iA <- which(S$group=="A")[which.max(S$logpost[S$group=="A"])]
p  <- ccx_unc_to_par(setNames(S$U[iA,], CCX_PARAM_NAMES))
nm <- intersect(CCX_PARAM_NAMES, names(CCX_PARAM_TABLE))
z  <- vapply(nm, function(k) tryCatch(ccx_prior_z(k, p[[k]]), error=function(e) NA_real_), numeric(1))
z  <- z[is.finite(z)]
cat(sprintf("\n  prior-z at the refit winner (id %d, logpost %.4f), %d coordinates\n",
            S$id[iA], S$logpost[iA], length(z)))
cat(sprintf("  |z| > 2 : %d    |z| > 3 : %d\n\n", sum(abs(z)>2), sum(abs(z)>3)))
o <- order(abs(z), decreasing=TRUE)
cat(sprintf("  %-24s %8s\n", "parameter", "z"))
for (k in o[1:10]) cat(sprintf("  %-24s %+8.2f%s\n", names(z)[k], z[k],
                               if (abs(z[k])>3) "   <-- |z| > 3" else if (abs(z[k])>2) "   <-- |z| > 2" else ""))
