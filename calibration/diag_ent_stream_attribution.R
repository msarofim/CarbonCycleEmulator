# ===================================================================
# WHERE DOES SWITCHING THE ENTRAINMENT CHANNEL ON ACTUALLY COST?
#
# THE QUESTION. diag_ent_axis_profile.R found that at the DERIVED amplitude the
# likelihood is ~306 log-units worse, conditionally. Read naively that looks
# like evidence AGAINST the mechanism. This asks WHICH STREAMS object, because
# "the fit got worse" and "the fit got worse in the one row that was matched by
# cancellation" are opposite conclusions.
#
# ⛔ CONDITIONAL, like its parent: every other coordinate HELD at the
# 25-parameter refit winner, which was fitted WITHOUT this channel.
#
# THE ANSWER (2026-09-03): 100.7 % of the loss is the seasonal CO2 rows --
# co2_seasonal_SPO -290.7 and co2_seasonal_MLO -16.5 of -305.6 -- and the two
# d13c_seasonal rows move by -0.30 and -0.09, i.e. NOT AT ALL. Nothing else in
# the model notices.
# ⇒ THAT IS THE CANCELLATION THESIS, CONFIRMED RATHER THAN CONTRADICTED.
# co2_seasonal_SPO sits at +66.98 because a 2.48x land limb and a 0.63x ocean
# limb cancel. Repair the ocean limb ALONE and the cancellation goes with it,
# so the row collapses while the land is still 2.48x. The objection is to the
# LAND being left behind, not to the channel.
# ⇒ A conditional profile therefore CANNOT judge Fix A, and the refit must be
#   free to move the land -- which is exactly prediction P3.
#
# Usage:  Rscript calibration/diag_ent_stream_attribution.R
# ===================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
S  <- readRDS("calibration/output/multistart_20260902_demean25/survey_summary.rds")
iA <- which(S$group == "A")[which.max(S$logpost[S$group == "A"])]
res <- readRDS(S$files[iA]); pm <- ccx_migrate_par_set(res$par_mode)
mk <- function(ent) { p <- ccx_overlay_par(ccx_default_params(), pm)
  p$pump_mode <- res$pump_mode; p$ent_seas_amp_SH <- ent
  list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total,
       sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC,
       grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c) }
st <- function(ent) { v <- mk(ent); unlist(dg_streams(dg_run(v), v)) }
a <- st(0); b <- st(ccx_const("ENT_SEAS_AMP_SH_DERIV")); c1 <- st(1)
nm <- union(names(a), names(b))
d  <- (b[nm] - a[nm]); d[is.na(d)] <- 0
o  <- order(d)
cat(sprintf("\n  PER-STREAM logL, ent = 0  ->  ent = %.2f (the DERIVED amplitude)\n",
            ccx_const("ENT_SEAS_AMP_SH_DERIV")))
cat(sprintf("  total change %+.2f\n\n", sum(d)))
cat(sprintf("  %-26s %12s %12s %10s\n", "stream", "ent=0", "ent=10.95", "delta"))
for (k in o[1:10]) cat(sprintf("  %-26s %12.2f %12.2f %+10.2f\n", nm[k], a[nm[k]], b[nm[k]], d[nm[k]]))
cat("  ...\n")
for (k in rev(o)[1:3]) cat(sprintf("  %-26s %12.2f %12.2f %+10.2f\n", nm[k], a[nm[k]], b[nm[k]], d[nm[k]]))
seas <- grep("seasonal", nm, value = TRUE)
cat(sprintf("\n  SEASONAL rows alone: %+.2f of %+.2f  (%.1f %%)\n",
            sum(d[seas]), sum(d), 100*sum(d[seas])/sum(d)))
d1 <- c1[nm] - a[nm]; d1[is.na(d1)] <- 0
cat(sprintf("  and at ent = 1 (the likelihood's own optimum): total %+.2f, seasonal %+.2f\n",
            sum(d1), sum(d1[seas])))
