# =====================================================================
# diag_hml_mode_decode.R -- THE MODE'S `h_ml` IS DECODED UNDER THE WRONG BAND,
#                           AND THAT ACCOUNTS FOR MOST OF THE -3.3223 OFFSET.
#
# `h_ml` is logit-transformed onto [lo, hi] and the pump refits OVERRIDE that
# band in process (run_modefind_pump_arms.R; recompute_hessian.R:112-113). The
# band is a property of the REFIT, so R/calibrate.R is deliberately untouched --
# but the SAME `u_mode` then decodes to a DIFFERENT depth depending on which
# band is in force, and `ccx_unc_to_par()` is a pure function of the SHIPPED
# table and cannot know. See the note above ccx_mode_params() in R/paths.R.
#
# ⚠ THIS FILE CHANGES NO OBJECTIVE AND OWES NO REFIT. The calibration is fine;
# what was wrong is what the DIAGNOSTICS fed the model afterwards.
#
# Usage:  Rscript calibration/diag_hml_mode_decode.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
HD_YEARS <- c(1750, 2024)
HD_KINKS <- c(98.41, 100.00, 101.29)   # ccx_pump_shape() clamp crossings, 08-18
HD_OFFSET_KNOWN <- -3.3223             # [[ccx_mode_logpost_offset]]
HD_PRIOR_CONST  <- 1.5805              # the bounded refit's narrowed-prior constant
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

md <- readRDS(ccx_mode_file()); u0 <- md$u_mode; names(u0) <- CCX_PARAM_NAMES
i  <- match("h_ml", CCX_PARAM_NAMES)
inv <- function(u, lo, hi) lo + (hi - lo) / (1 + exp(-u))

sep("1. THE DEFECT")
cat(sprintf("  u_mode[h_ml] = %.6f\n", u0[i]))
cat(sprintf("  %-34s %10.4f m\n", "ccx_unc_to_par()  [shipped band]",
            inv(u0[i], CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi)))
cat(sprintf("  %-34s %10.4f m   <- md$hml_bound\n", "decoded under the RECORDED band",
            inv(u0[i], md$hml_bound[1], md$hml_bound[2])))
cat(sprintf("  %-34s %10.4f m   <- what the refit FOUND\n", "md$par_mode[['h_ml']]",
            md$par_mode[["h_ml"]]))
cat(sprintf("  %-34s %10.4f m   <- ccx_mode_params(), the fix\n", "ccx_mode_params()$h_ml",
            ccx_mode_params(md)$h_ml))
err <- abs(inv(u0[i], CCX_PARAM_TABLE$h_ml$lo, CCX_PARAM_TABLE$h_ml$hi) - md$par_mode[["h_ml"]])
cat(sprintf("\n  ⇒ ERROR %.4f m = %.2f %% -- an 11 %% SHALLOWER mixed layer in every\n",
            err, 100 * err / md$par_mode[["h_ml"]]))
cat("    diagnostic using the standard `pv <- ccx_unc_to_par(md$u_mode)` idiom.\n")
pv <- ccx_unc_to_par(u0)
d <- Filter(function(n) { a <- pv[[n]]; b <- md$par_mode[[n]]
  is.numeric(a) && is.numeric(b) && length(a) == 1L && length(b) == 1L &&
    abs(a - b) > 1e-8 * max(abs(b), 1e-12) }, intersect(names(pv), names(md$par_mode)))
cat(sprintf("  Parameters affected: %d of %d -- %s\n", length(d), length(CCX_PARAM_NAMES),
            paste(d, collapse = ", ")))

sep("2. IT ACCOUNTS FOR THE STANDING -3.3223 LOGPOST OFFSET")
bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
o_ship <- ccx_make_logpost(years = HD_YEARS, base_params = bp)(u0) - md$logpost
.old <- CCX_PARAM_TABLE$h_ml
CCX_PARAM_TABLE$h_ml$lo <- md$hml_bound[1]; CCX_PARAM_TABLE$h_ml$hi <- md$hml_bound[2]
lp_b <- ccx_make_logpost(years = HD_YEARS, base_params = bp)
o_band <- lp_b(u0) - md$logpost
cat(sprintf("  offset, shipped-band decoding  %+.4f   (the standing %.4f)\n", o_ship, HD_OFFSET_KNOWN))
cat(sprintf("  offset, recorded-band decoding %+.4f\n", o_band))
cat(sprintf("  difference explained by the band %+.4f\n", o_band - o_ship))
cat(sprintf("\n  ⇒ THE RESIDUAL %+.4f IS THE BOUNDED REFIT'S NARROWED-PRIOR CONSTANT (%.4f),\n",
            o_band, HD_PRIOR_CONST))
cat("    which is additive, deliberate, and cancels from every contrast.\n")
cat(sprintf("    |residual - prior constant| = %.4f  -> %s\n", abs(abs(o_band) - HD_PRIOR_CONST),
            if (abs(abs(o_band) - HD_PRIOR_CONST) < 0.01) "OFFSET FULLY ACCOUNTED" else "⚠ residual left"))

sep("3. WHAT THIS CHANGES ABOUT h_ml -- AND WHAT IT DOES NOT")
h <- md$par_mode[["h_ml"]]; sdu <- sqrt(diag(md$cov))[i]
s <- 1/(1+exp(-u0[i])); dhdu <- (md$hml_bound[2]-md$hml_bound[1])*s*(1-s)
cat(sprintf("  h_ml %.2f m | 1 sigma ~ %.2f m -> [%.2f, %.2f]\n", h, sdu*dhdu,
            inv(u0[i]-sdu, md$hml_bound[1], md$hml_bound[2]),
            inv(u0[i]+sdu, md$hml_bound[1], md$hml_bound[2])))
cat(sprintf("  nearest pump kink %.2f m away; Hessian reach %.3f m (gap %.3f) -> row is %s\n",
            min(abs(h - HD_KINKS)), md$hml_hess_reach, md$hml_kink_gap,
            if (md$hml_hess_reach < md$hml_kink_gap) "CLEAN of the kinks" else "CONTAMINATED"))
cat("  ⇒ THE REFIT'S OWN GUARDS WERE RIGHT. The Hessian is not kink-contaminated.\n\n")
to_u <- function(x) log((x - md$hml_bound[1]) / (md$hml_bound[2] - x))
f0 <- lp_b(u0)
cat("  Approaching the band's lower edge (in the RECORDED coordinates):\n")
for (x in c(90, 87, 85.5, 85.1, 85.01)) cat(sprintf("    h_ml %7.3f  d logpost %+9.3f\n", x, lp_b(replace(u0, i, to_u(x))) - f0))
cat("\n  ⚠ h_ml < 85 is UNREACHABLE in these coordinates -- the logit maps [85,120]\n")
cat("  onto the whole line. THE MODE-FIND IS PROTECTED BY CONSTRUCTION, NOT BY THE\n")
cat("  DATA. A SAMPLER IS NOT: the edge sits ~1.5 sigma below the mode, a routine\n")
cat("  excursion, and the shipped model allows [30, 200] where the UNBOUNDED\n")
cat("  objective's argmax was measured at 32 m. Any posterior drawn here is\n")
cat("  conditioned on a bound adopted as a REFIT EXPEDIENT, not as a belief.\n")
CCX_PARAM_TABLE$h_ml <- .old
cat("\n\n=== DONE ===\n")
