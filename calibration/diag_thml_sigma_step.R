# =====================================================================
# T-hml follow-up 3 (2026-09-08g): the h_ml feature IS the sigma_rep table's
# bin-edge step. diag_thml_kink_rows.R put the feature in the three ocean
# gradient rows; those are scored at sigma_eff(h_ml) = sqrt(sd^2 + (lfl(h) -
# target)^2) with lfl(h) the like-for-like target on a 1 m grid
# (data/obs_glodap_sigma_rep.rds), monotone-Hermite interpolated. The table
# STEPS wherever the model's mixed-layer base crosses a 25 m GLODAP bin edge
# (50, 100, 150, 200 m). At hilda31 the d13C row is ~3 sigma off, so a small
# sigma step becomes a large log-likelihood shelf. Data-only: no model runs
# beyond the stream table already saved by diag_thml_kink_rows.R.
# Usage: Rscript calibration/diag_thml_sigma_step.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
TS_ROWS <- c("dic", "d13c", "alk"); TS_EDGES <- c(50, 100, 150, 200); TS_HALF <- 1.5
TS_KR <- ccx_path("outputs", "diagnostics", sprintf("thml_kink_rows_%s.rds", format(Sys.Date(), "%Y%m%d")))
TS_OUT <- ccx_path("outputs", "diagnostics", sprintf("thml_sigma_step_%s.rds", format(Sys.Date(), "%Y%m%d")))
sr <- ccx_ocean_sigma_rep_table(); tg <- ccx_ocean_gradient_target(); KR <- readRDS(TS_KR)
h0 <- KR$fine[which.min(abs(KR$fine - 49.153))]
cat(sprintf("sigma_rep table: h %g-%g m, 1 m grid, rows %s; interpolation %s\n", min(sr$h), max(sr$h), paste(names(sr$like_for_like), collapse = "/"), "monoH.FC"))
cat("\n=== 1. The steps in the like-for-like target at the GLODAP bin edges (value at edge-1.5 m -> edge+1.5 m), and sigma_eff's relative change ===\n")
for (e in TS_EDGES) for (r in TS_ROWS) { s1 <- ccx_ocean_sigma_eff(r, e - TS_HALF); s2 <- ccx_ocean_sigma_eff(r, e + TS_HALF)
  cat(sprintf("  edge %3d m  %-5s lfl %10.4f -> %10.4f   sigma_eff %.4f -> %.4f (%+.1f %%)\n", e, r, sr$fun[[r]](e - TS_HALF), sr$fun[[r]](e + TS_HALF), s1, s2, 100 * (s2 / s1 - 1))) }
cat("\n=== 2. At hilda31 (h_ml 49.15): the rows' z at the mode, and the shelf the 50 m step PREDICTS vs what the slice MEASURED ===\n")
lo <- 50 - TS_HALF; hi <- 50 + TS_HALF
for (r in TS_ROWS) { nm <- paste0("ocean_grad_", r); l0 <- KR$streams[which.min(abs(KR$fine - h0)), nm]
  s0 <- ccx_ocean_sigma_eff(r, h0); z2 <- 2 * (-l0 - log(s0) - 0.5 * log(2 * pi))   # logL = -z^2/2 - log sigma - log sqrt(2 pi)
  s1 <- ccx_ocean_sigma_eff(r, lo); s2 <- ccx_ocean_sigma_eff(r, hi)
  pred <- -0.5 * z2 * ((s1 / s2)^2 - 1) - log(s2 / s1)                              # residual held fixed, sigma steps
  meas <- KR$streams[which.min(abs(KR$fine - hi)), nm] - KR$streams[which.min(abs(KR$fine - lo)), nm]
  cat(sprintf("  %-16s logL at mode %+7.3f  sigma_eff %.4f  |z| %.2f | step %.1f -> %.1f m: sigma %.4f -> %.4f; predicted d logL %+.3f, measured %+.3f\n", nm, l0, s0, sqrt(max(z2, 0)), lo, hi, s1, s2, pred, meas)) }
cat("\n=== 3. Reading ===\n")
cat("  The feature is a STEP in a data product (the like-for-like sigma table) at the 25 m GLODAP bin edge the mixed-layer base crosses,\n  rendered as a 1-2 m sigmoid by the Hermite interpolant. The shipped acceptance ('measured roughness at most 0.0734 log-units') was\n  priced at a mode where the rows' residuals were small; at hilda31 the d13C row is ~3 sigma out, so the same step costs ~0.5.\n  It is NOT the pump-shape kink family (hml_kinks; those stay gone) and NOT a model discontinuity: a sampler crosses a C1 shelf; a\n  Hessian step search does not. Whether to smooth or re-bin the table is a ruling (it changes the objective).\n")
saveRDS(list(edges = TS_EDGES, h0 = h0, date = Sys.time()), TS_OUT); cat(sprintf("saved %s\n⛔ Nothing adopted.\n", TS_OUT))
