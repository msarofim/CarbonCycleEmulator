# ===================================================================
# THE CONDITIONAL LOGPOST PROFILE ALONG `ent_seas_amp_SH`.
#
# ⛔ CONDITIONAL: every other coordinate is HELD at the 25-parameter refit
# winner -- a vector fitted WITHOUT this channel. The hypothesis under test is
# precisely that a refit RE-ARRANGES the other coordinates, so this cannot
# decide P1-P5. What it CAN answer is the question that must be settled before
# a refit is launched: IS THE PRIOR CHOOSING THE PHYSICS?
#
# It is not. The likelihood dominates by hundreds of log-units and it costs the
# prior only ~11.5 to sit at the likelihood's own optimum -- so the fit is free
# to turn the channel down, and if it does not, that is the data speaking.
#
# ⚠ WHAT IT ALSO SHOWS, AND THIS IS A PRE-REGISTERED RISK TO P2: conditionally
# the data want the channel 5-10x SMALLER than the DERIVED amplitude, with the
# optimum at prior-z ~ -3.4. The refit may therefore MOVE the strain from
# `sst_seas_amp_SH` onto `ent_seas_amp_SH` rather than relieve it. Said before
# the run, not after.
#
# Usage:  Rscript calibration/diag_ent_axis_profile.R
# ===================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
S  <- readRDS("calibration/output/multistart_20260902_demean25/survey_summary.rds")
iA <- which(S$group == "A")[which.max(S$logpost[S$group == "A"])]
res <- readRDS(S$files[iA]); pm <- ccx_migrate_par_set(res$par_mode)
bp <- ccx_default_params(); bp$pump_mode <- res$pump_mode
lp <- ccx_make_logpost(base_params = bp)
s  <- CCX_PARAM_TABLE$ent_seas_amp_SH
pr <- function(x) s$prior(x) + log(x)          # prior + Jacobian, the u-space term
ev <- function(x) { p <- pm; p$ent_seas_amp_SH <- x; lp(ccx_par_to_unc(p)) }
G  <- c(0.01, 0.05, 0.2, 0.5, 1, 2, 4, 6, 8, 10.952353, 15, 20, 29.681175)
cat(sprintf("\n  CONDITIONAL PROFILE along `ent_seas_amp_SH` at the refit winner\n"))
cat(sprintf("  (every other coordinate HELD; the 25-par winner scored -1482.6144\n"))
cat(sprintf("   in its OWN 25-parameter space)\n\n"))
cat(sprintf("  %-10s %13s %11s %13s %9s\n", "ent", "logpost", "prior term", "= likelihood", "prior-z"))
R <- vapply(G, function(x) c(lp = ev(x), pr = pr(x)), c(0,0))
for (i in seq_along(G))
  cat(sprintf("  %-10.4f %13.4f %11.4f %13.4f %+9.2f\n",
              G[i], R[1,i], R[2,i], R[1,i]-R[2,i], ccx_prior_z("ent_seas_amp_SH", G[i])))
b <- which.max(R[1,])
cat(sprintf("\n  conditional optimum on this grid: ent = %.4f, logpost %.4f (prior-z %+.2f)\n",
            G[b], R[1,b], ccx_prior_z("ent_seas_amp_SH", G[b])))
cat(sprintf("  the LIKELIHOOD alone is maximised at ent = %.4f\n", G[which.max(R[1,]-R[2,])]))
cat(sprintf("  cost of the prior at that likelihood optimum, vs at the prior centre: %.2f log-units\n",
            pr(s$init) - pr(G[which.max(R[1,]-R[2,])])))
