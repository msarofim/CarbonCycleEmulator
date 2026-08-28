# =====================================================================
# finish_pump_arms_comparison.R -- rebuild the tail of the 2026-08-18 two-arm
# refit that its own process never reached.
#
# WHY THIS EXISTS, stated plainly because it was an operator error and not a
# model one. `run_modefind_pump_arms.R` was edited WHILE IT WAS RUNNING (the
# 2026-08-19 runtime-header correction, commit 9f5bf71) on the false premise
# that Rscript parses a script fully before evaluating it. IT DOES NOT -- it
# parses incrementally, so inserting ~15 lines near the top shifted every later
# byte offset and the process resumed mid-expression ~30 h later, dying with
# "unexpected symbol" in the standing-questions block.
#
# WHAT WAS AND WAS NOT LOST. Both arms had already finished and written
# `mode_fit_pump{N,D}.rds` -- 29 fields each, modes, Hessians, per-stream
# decompositions, and the kink/step-stability records intact. The COMPARISON
# block had already PRINTED in full (log: refit_20260818.log). Only two things
# died: the standing-questions print, and `pump_arms_comparison.rds`, which is
# a repackaging of the two arm files and carries no information they lack.
# NOTHING HERE IS RECOMPUTED FROM THE MODEL -- this script only reads the two
# rds files and re-derives what the tail would have printed, so it cannot
# introduce a number the run did not produce.
#
# THE LESSON, for the CHANGELOG and for next time: never edit a script that a
# long job is executing. Copy it, edit the copy.
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

FIN_OUTDIR <- ccx_path("calibration", "output", "pump_arms")
FIN_MODES  <- c("N", "D")
FIN_SEED   <- 2026            # ARM_SEED of the run being completed
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

fits <- lapply(FIN_MODES, function(m)
  readRDS(file.path(FIN_OUTDIR, sprintf("mode_fit_pump%s.rds", m))))
names(fits) <- FIN_MODES
N <- fits$N; D <- fits$D

# GATE: these must be the two arms of the SAME run, or the comparison is
# between different objectives. Checked rather than assumed, because the files
# sit at fixed paths that any later run overwrites.
stopifnot(identical(N$param_names, D$param_names),
          identical(N$seed, D$seed), identical(N$seed, FIN_SEED),
          identical(N$pump_mode, "N"), identical(D$pump_mode, "D"))
cat(sprintf("both arms: %d parameters, seed %d, %s\n",
            length(N$param_names), N$seed, paste(N$param_names, collapse = ", ")))

ev_d <- (D$logpost - N$logpost) - 0.5 * (D$logdet_negH - N$logdet_negH)

sep("COMPARISON (rebuilt from the two arm files)")
cat(sprintf("%-30s %12s %14s %14s\n", "", "N", "D", "D - N"))
cat(sprintf("%-30s %12.2f %14.2f %+14.2f\n", "log-posterior at MAP",
            N$logpost, D$logpost, D$logpost - N$logpost))
cat(sprintf("%-30s %12.2f %14.2f %+14.2f\n", "0.5 log|-H|",
            0.5 * N$logdet_negH, 0.5 * D$logdet_negH,
            0.5 * (D$logdet_negH - N$logdet_negH)))
cat(sprintf("%-30s %12s %14s %+14.2f\n", "LAPLACE log-evidence D-N", "", "", ev_d))

sep("THE STANDING QUESTIONS THIS RUN WAS ALSO MEANT TO ANSWER")
for (m in FIN_MODES) {
  f <- fits[[m]]; kb <- f$kz_bracket
  cat(sprintf("[%s] kz = %.1f (%.1f %% up the re-bisected bracket [%g, %g])\n",
              m, f$par_mode$kz, 100 * (f$par_mode$kz - kb[1]) / (kb[2] - kb[1]), kb[1], kb[2]))
  cat(sprintf("[%s] h_ml = %.2f -- gradient rows LIVE only inside [%g, %g]: %s\n",
              m, f$par_mode$h_ml, LIK_OCEAN_GRAD_HML_OK_RETIRED[1], LIK_OCEAN_GRAD_HML_OK_RETIRED[2],
              if (f$par_mode$h_ml >= LIK_OCEAN_GRAD_HML_OK_RETIRED[1] &&
                  f$par_mode$h_ml <= LIK_OCEAN_GRAD_HML_OK_RETIRED[2]) "LIVE" else "*** ABSENT ***"))
  cat(sprintf("[%s] pump_grad = %.2f  (prior centre %.2f, 1-D optimum at the old mode 274.5)\n",
              m, f$par_mode$pump_grad, ccx_const("PUMP_GRAD_OBS")))
}

# ADDED HERE, not in the original tail: the Hessian-trust record this session's
# checks produced. The evidence above is a determinant, so which rows are
# unreliable belongs beside it rather than three screens away in the log.
sep("HESSIAN TRUST (this session's checks -- read BEFORE the evidence)")
for (m in FIN_MODES) {
  f <- fits[[m]]
  cat(sprintf("[%s] h_ml %.4f m, nearest kink %.2f m, step reaches %.2e m -> kink_hit %s\n",
              m, f$par_mode$h_ml, f$hml_kink_gap, f$hml_hess_reach, f$hml_kink_hit))
  cat(sprintf("[%s] step-UNSTABLE coordinates: %s\n", m,
              if (length(f$hess_unstable)) paste(f$hess_unstable, collapse = ", ") else "none"))
  cat(sprintf("[%s] converged? %s\n", m, if (isTRUE(f$hit_cap))
      "NO -- hit the restart cap while still gaining" else "yes"))
}

saveRDS(list(fits = fits, evidence_D_minus_N = ev_d, seed = FIN_SEED,
             modes = FIN_MODES, param_names = N$param_names,
             rebuilt_by = "calibration/finish_pump_arms_comparison.R",
             rebuilt_reason = "mid-run edit desynchronised Rscript's incremental parse"),
        file.path(FIN_OUTDIR, "pump_arms_comparison.rds"))
cat(sprintf("\nwritten: %s\n", file.path(FIN_OUTDIR, "pump_arms_comparison.rds")))
