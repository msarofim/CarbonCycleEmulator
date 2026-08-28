# =====================================================================
# diag_p3_sigma_d14c_contamination.R -- IS THE luc ARM'S rep_dC MOVE BOUGHT
# BY AN INFLATED sigma_d14c?  (2026-08-25)
#
# P3 of prereg_2026-08-24c predicted `sigma_d14c` would stay within 0.5 sd and
# named 1.5 sd as the falsifier. It moved +1.671, so the pre-registration's own
# consequence applies: P1's -5.014 sd `rep_dC` move must be reported as possibly
# contaminated rather than quoted clean. THIS FILE MEASURES BY HOW MUCH.
#
# The worry is concrete. `sigma_d14c` is a FITTED error term on the two
# Delta14C station streams. Inflating it relaxes every 14C residual, and the
# 2026-08-23 pinned `foss` run inflated it +3.85 sd while absorbing a 14C-free
# artefact. If the luc arm is doing a smaller version of the same thing, some of
# the `rep_dC` relief is being bought with a widened error bar rather than with
# the mechanism under test.
#
# FOUR TESTS, cheapest first. Each is diagnostic on its own.
#
#  T1 STRUCTURAL. `rep_dC` enters the CO2 station levels and the d13C station
#     levels (R/likelihood.R:1105, 1251) and NOTHING ELSE. It does not appear in
#     any Delta14C term. So a direct route does not exist and any coupling must
#     run through the posterior. Reported as the measured correlation.
#
#  T2 COVARIANCE-PREDICTED. If `rep_dC` merely slid along the posterior while
#     its partners moved, the reference covariance already predicts how far, with
#     NO new information. Condition the reference Gaussian on the OTHER 20
#     coordinates' observed displacements and compare the predicted `rep_dC`
#     move with the measured -5.014. A large unexplained residual is the arm
#     doing real work; a small one means the ridge slid.
#
#  T3 THE CONDITIONAL RE-OPTIMISATION, WHICH IS THE DECISIVE ONE. Hold every
#     coordinate at the landed luc mode, RESET `sigma_d14c` to the reference
#     6.1251, and re-optimise `rep_dC` ALONE in 1-D. If `rep_dC` stays near
#     4.346, the inflated sigma bought nothing and P1 survives. If it springs
#     back toward 5.566, the relief was the error bar.
#
#  T4 THE SAME 1-D PROFILE IN THE REFERENCE ARM, which is the control. T3
#     without T4 cannot tell "the sigma reset moved rep_dC" from "rep_dC's 1-D
#     optimum is not where the 21-D mode is".
#
# Usage:  Rscript calibration/diag_p3_sigma_d14c_contamination.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

P3_REF  <- ccx_mode_file()
P3_LUC  <- file.path("calibration", "output", "luc_arm_pinluc", "mode_fit_pumpN.rds")
P3_SINK <- list(mode = "luc", rate = 2.5)      # the arm the luc file was fitted under
P3_GRID <- seq(-3, 3, by = 0.02)               # rep_dC offsets, ppm, around each start
OUTDIR  <- ccx_path("calibration", "output", "p3_sigma_d14c")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)

ref <- readRDS(P3_REF); luc <- readRDS(P3_LUC)

# ---- PROVENANCE, BEFORE ANY NUMBER IS READ -------------------------
# The luc file must be the ARM, not the seeded reference (08-24b's seed-copy
# trap), and both must decode under the SAME h_ml bound or every sd is wrong
# (memory ccx_hml_band_provenance).
stopifnot(!is.null(ref$hml_bound), !is.null(luc$hml_bound))
if (!isTRUE(all.equal(ref$hml_bound, luc$hml_bound)))
  stop("h_ml bounds differ: ", paste(ref$hml_bound, collapse = "-"), " vs ",
       paste(luc$hml_bound, collapse = "-"))
if (isTRUE(all.equal(unlist(ref$par_mode), unlist(luc$par_mode))))
  stop("the luc file IS the reference -- seed copy, not a fitted arm")
cat(sprintf("h_ml bound [%g, %g] in both files. OK\n", ref$hml_bound[1], ref$hml_bound[2]))
# ⚠ ADOPT THE MODE'S OWN h_ml BAND BEFORE DECODING (2026-08-28). The refits
# override h_ml's logit band in process, so ccx_unc_to_par() returns 85.73 m
# where this mode sits at 96.47 m. The band-equality gate above is what makes
# adopting ref's band safe for both files. [[ccx_hml_band_decode]]
ccx_adopt_mode_band(ref)

sd_u <- unlist(ref$sd_unc)
u_r  <- unlist(ref$u_mode); u_l <- unlist(luc$u_mode)
pn   <- CCX_PARAM_NAMES
d_sd <- (u_l[pn] - u_r[pn]) / sd_u[pn]

# ---- T1: the structural statement, measured -----------------------
Rr <- ref$cor; if (is.null(Rr)) { C <- ref$cov; d <- sqrt(diag(C)); Rr <- C / outer(d, d) }
cat(sprintf("\nT1  rho(rep_dC, sigma_d14c) = %+.4f in the reference posterior.\n",
            Rr["rep_dC", "sigma_d14c"]))
cat(sprintf("    rep_dC's strongest partners: %s\n",
            paste(sprintf("%s %+.3f", names(sort(abs(Rr["rep_dC", setdiff(pn,"rep_dC")]),
                                                 decreasing = TRUE))[1:4],
                          Rr["rep_dC", names(sort(abs(Rr["rep_dC", setdiff(pn,"rep_dC")]),
                                                  decreasing = TRUE))[1:4]]),
                  collapse = ", ")))

# ---- T2: conditional mean under the REFERENCE covariance ----------
# E[du_rep | du_others] = Sigma_ro Sigma_oo^-1 du_others, all in UNCONSTRAINED
# coordinates, which is where the Gaussian lives.
S  <- ref$cov
o  <- setdiff(pn, "rep_dC")
pred_u <- drop(S["rep_dC", o, drop = FALSE] %*% solve(S[o, o], (u_l[o] - u_r[o])))
cat(sprintf("\nT2  measured  d rep_dC = %+.3f sd\n", d_sd[["rep_dC"]]))
cat(sprintf("    covariance-predicted from the OTHER 20 moves = %+.3f sd\n",
            pred_u / sd_u[["rep_dC"]]))
cat(sprintf("    unexplained residual = %+.3f sd\n",
            d_sd[["rep_dC"]] - pred_u / sd_u[["rep_dC"]]))

# ---- T3/T4: the 1-D conditional re-optimisation -------------------
# Built by hand rather than through ccx_make_logpost() so `sigma_d14c` can be
# OVERRIDDEN independently of the u-vector: the whole point is to evaluate the
# luc arm's landed mode at a sigma it did not choose.
profile_rep <- function(u0, sigma_override, label, sink_mode, sink_rate) {
  Sys.setenv(CCX_SINK_MODE = sink_mode, CCX_SINK_RATE = as.character(sink_rate))
  # forcing/params rebuilt under THIS arm; ccx_build_forcing reads its args, not
  # the env, so the arm is passed explicitly and cannot drift from the label.
  pv <- ccx_unc_to_par(u0); names(u0) <- pn
  p  <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14,
                          bomb_total_kmol = pv$bomb_total, luc_scale = pv$luc_scale,
                          sink_rate = sink_rate, sink_mode = sink_mode)
  eluc <- ccx_forcing_eluc_annual(F)
  r  <- ccx_run_fast(sp, F)
  obs <- ccx_prepare_obs()
  sig <- if (is.na(sigma_override)) pv$sigma_d14c else sigma_override
  # THE PRIOR IS PART OF THE OBJECT. An earlier draft of this file profiled the
  # LIKELIHOOD alone, calling rep_dC's prior "flat over this range". It is not:
  # measured at 3.5 / 4.35 / 5.57 it is -7.04 / -10.38 / -16.41, a 9.4 log-unit
  # pull across the interval being scanned, and the likelihood-only argmax sat
  # 0.76 ppm ABOVE the 21-D posterior mode as a result. rep_dC's transform is
  # "id", so there is no Jacobian and the natural-coordinate posterior is simply
  # prior + loglik. (This is the profile_beats_optimum trap in miniature: a
  # profile that disagrees with the optimum usually means the profile is scoring
  # a different object.)
  rep_prior <- CCX_PARAM_TABLE$rep_dC$prior
  lp <- vapply(P3_GRID, function(dx) {
    err <- list(sigma_d14c = sig, rep_dC = pv$rep_dC + dx,
                grad_off_co2 = pv$grad_off_co2, grad_off_d13c = pv$grad_off_d13c)
    rep_prior(pv$rep_dC + dx) +
      ccx_loglik(r$out, obs, err, luc = eluc,
                 deep = sp$diagnostics$d14c_bottom_box,
                 ocean_grad = ccx_ocean_grad_scored(r$out, sp))
  }, numeric(1))
  ll   <- lp
  best <- pv$rep_dC + P3_GRID[which.max(lp)]
  if (which.max(lp) %in% c(1L, length(lp)))
    stop("rep_dC profile railed at a grid edge for ", label,
         " -- widen P3_GRID; an argmax on the boundary is not an optimum")
  cat(sprintf("%-34s start rep_dC %.4f  sigma_d14c %.4f  ->  1-D argmax %.4f\n",
              label, pv$rep_dC, sig, best))
  list(label = label, start = pv$rep_dC, sigma = sig, argmax = best,
       grid = pv$rep_dC + P3_GRID, ll = ll)
}

cat("\nT3/T4  1-D rep_dC POSTERIOR profiles (prior + loglik). The prior is NOT\n")
cat("       flat over this range and profiling the likelihood alone scores a\n")
cat("       different object -- see the note in profile_rep().\n")
pr <- CCX_PARAM_TABLE$rep_dC$prior
cat(sprintf("       prior(rep_dC) at 3.5 / 4.35 / 5.57 = %.3f / %.3f / %.3f (span %.1f)\n",
            pr(3.5), pr(4.35), pr(5.5658), pr(3.5) - pr(5.5658)))

res <- list()
res$luc_free  <- profile_rep(u_l, NA,     "T3a luc arm, sigma as fitted",  "luc", 2.5)
res$luc_reset <- profile_rep(u_l, unlist(ref$par_mode)[["sigma_d14c"]],
                                          "T3b luc arm, sigma RESET to ref", "luc", 2.5)
res$ref_free  <- profile_rep(u_r, NA,     "T4a reference, sigma as fitted", "foss", 0)
res$ref_hi    <- profile_rep(u_r, unlist(luc$par_mode)[["sigma_d14c"]],
                                          "T4b reference, sigma set to luc's", "foss", 0)

cat(sprintf("\nCONTAMINATION = how far the sigma reset drags rep_dC back:\n"))
cat(sprintf("  luc arm: %.4f (as fitted) -> %.4f (sigma reset) = %+.3f ppm = %+.2f sd\n",
            res$luc_free$argmax, res$luc_reset$argmax,
            res$luc_reset$argmax - res$luc_free$argmax,
            (res$luc_reset$argmax - res$luc_free$argmax) / sd_u[["rep_dC"]]))
cat(sprintf("  control: %.4f (as fitted) -> %.4f (sigma set high) = %+.3f ppm\n",
            res$ref_free$argmax, res$ref_hi$argmax,
            res$ref_hi$argmax - res$ref_free$argmax))

saveRDS(list(res = res, d_sd = d_sd, pred_sd = pred_u / sd_u[["rep_dC"]],
             rho = Rr["rep_dC", "sigma_d14c"], sd_rep = sd_u[["rep_dC"]],
             ref_file = P3_REF, luc_file = P3_LUC, sink = P3_SINK),
        file.path(OUTDIR, "p3_contamination.rds"))
cat(sprintf("\nwritten: %s\n", file.path(OUTDIR, "p3_contamination.rds")))
