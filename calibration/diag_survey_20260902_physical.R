for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
D <- "calibration/output/multistart_20260902_demean25"
S <- readRDS(file.path(D, "survey_summary.rds"))
iA <- which(S$group=="A")[which.max(S$logpost[S$group=="A"])]
iB <- which(S$group=="B")[which.max(S$logpost[S$group=="B"])]
pa <- ccx_unc_to_par(setNames(S$U[iA,], CCX_PARAM_NAMES))
pb <- ccx_unc_to_par(setNames(S$U[iB,], CCX_PARAM_NAMES))
cat(sprintf("\n  h_ml: cluster A %.2f m   vs   cluster B %.2f m   (%.1f %% apart)\n",
            pa$h_ml, pb$h_ml, 100*abs(pb$h_ml/pa$h_ml - 1)))
cat(sprintf("  and the whole logpost gap between them is %.4f\n\n",
            max(S$logpost[S$group=="A"]) - max(S$logpost[S$group=="B"])))
# the h_ml spread WITHIN cluster A, for scale
hA <- vapply(iAall <- which(S$group=="A"), function(i)
  ccx_unc_to_par(setNames(S$U[i,], CCX_PARAM_NAMES))$h_ml, numeric(1))
cat(sprintf("  h_ml WITHIN cluster A: %.2f - %.2f m (n=%d)\n", min(hA), max(hA), length(hA)))
cat("\n  === THE ADOPTED-CANDIDATE VECTOR (best of 46, id ", S$id[iA], ") ===\n", sep="")
key <- c("h_ml","kz","tau_ex","fert_k","beta_max","rep_dC","npp_frac_NH",
         "gamma_enso_land_NH","gamma_enso_land_SH","gamma_enso_ocn_NH","gamma_enso_ocn_SH")
for (k in key) if (!is.null(pa[[k]])) cat(sprintf("    %-22s %12.4f\n", k, pa[[k]]))
