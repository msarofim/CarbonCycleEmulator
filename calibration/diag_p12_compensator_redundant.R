# =====================================================================
# diag_p12_compensator_redundant.R -- PREREG P12: does the seasonal mixed
# layer make `ent_seas_amp_SH` REDUNDANT, or merely ADD to it?
#
# THE QUESTION, AND WHY IT DECIDES SOMETHING. Option A is being adopted as
# the REPLACEMENT for the fitted compensator -- that is what justifies
# retiring the parameter (31 -> 30). If instead the fit still wants a large
# compensator with the mechanism ON, then A is an ADDITION to the shim, the
# two are doing different jobs, and retiring the parameter is NOT justified.
# Nothing in round 6 tested this.
#
# ⛔⛔ P12 AS ORIGINALLY WRITTEN -- "refitting must drive the compensator
# toward ZERO" -- IS NOT TESTABLE BY A REFIT, and this had to be caught
# before measuring rather than after:
#   * `ent_seas_amp_SH` is `tr = "log"` with a LOGNORMAL prior centred
#     10.95 (R/calibrate.R). Under a log transform the value 0 is
#     UNREPRESENTABLE in the encoded space, and `dlnorm(0) = 0` gives it
#     PRIOR PROBABILITY ZERO -- the prior ASSERTS the mechanism is present
#     ([[runnable_is_not_encodable]]). A refit therefore CANNOT reach zero
#     and its logpost can never favour it.
#   ⭐ BUT ZERO IS REPRESENTABLE IN THE MODEL: `R/model.R` skips the shim
#     entirely at `ent_seas_amp_SH == 0`. So a LIKELIHOOD PROFILE can visit
#     the off state even though a refit cannot -- which makes the profile
#     MORE informative here than a refit would be.
#   ⇒ SCORE ON THE LIKELIHOOD, NEVER THE LOGPOST. A logpost profile would
#     measure the prior's pull toward 10.95 and report it as evidence for
#     the compensator.
#
# THE METRIC, FIXED BEFORE THE RUN. For each arm, G = max over the grid of
# loglik, minus loglik at ent = 0: the likelihood the compensator still
# BUYS. The prediction is an ORDERING between two MEASURED quantities, not
# an invented threshold:
#        G(seas_ml = 1)  <<  G(seas_ml = 0)
# and the arm-1 argmax should sit far below the fitted 19.0 / 21.2.
# ⛔ If G is UNCHANGED, option A does not replace the compensator.
#
# ⚠ THIS IS A CONDITIONAL PROFILE, NOT A REFIT. Every other parameter is
# held at the canonical, so the other 30 cannot compensate. That ATTENUATES
# the lever -- the 08-27p lesson, where a slice leaked 64 % of its lever
# through a shared parameter ([[ccx_seas_slice_q10_leak]]). ⇒ it BOUNDS the
# question, it does not settle it; the refit still owes the final answer.
#
# ⭐ ONE SPINUP SERVES EVERY VARIANT, and that is not an assumption: the
# spinup sets `seas_drivers <- 0` (R/spinup.R:227), which switches OFF both
# the shim and the seasonal mixed layer, so neither can touch the
# preindustrial equilibrium. ASSERTED below rather than trusted.
#
# ⚠ THE R CORE, DELIBERATELY: ccx_run_fast() / dg_run() use the C++ twin,
# which has no seasonal mixed layer and now STOPS rather than diverge.
#
# Usage:  Rscript calibration/diag_p12_compensator_redundant.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
source("calibration/lib_design_gates.R")

TAG      <- "20260909"
OUT_RDS  <- file.path("outputs", "diagnostics", paste0("p12_compensator_", TAG, ".rds"))
OUT_LOG  <- sub("[.]rds$", ".log", OUT_RDS)
# The grid spans OFF to well above the fitted value, so the profile's shape --
# not just its endpoints -- is visible. 0 is included because the MODEL admits
# it even though the ENCODER does not.
ENT_GRID <- c(0, 2, 5, 8, 11, 14, 17, 19, 21, 25)
ENT_FIT  <- c(winner_r3 = 21.2, ent26 = 19.0, prior_centre = 10.95)

con <- file(OUT_LOG, open = "wt")
say <- function(...) { m <- sprintf(...); cat(m, "\n"); cat(m, "\n", file = con) }

v <- dg_vector(CCX_MODE_CANONICAL)
say("PREREG P12 -- does the seasonal mixed layer make the compensator REDUNDANT?")
say("mode: %s (%s)", CCX_MODE_CANONICAL, v$src)
say("⛔ scored on the LIKELIHOOD, never the logpost: ent_seas_amp_SH is tr='log' with a")
say("   lognormal prior centred %.2f, so dlnorm(0) = 0 and a logpost can never favour OFF.",
    ENT_FIT[["prior_centre"]])
say("⚠ CONDITIONAL PROFILE, not a refit: the other 30 parameters are held, which ATTENUATES")
say("   the lever. It BOUNDS the question; the refit still owes the final answer.")

## ---- ONE spinup, and the claim that it serves both arms is ASSERTED --------
mk <- function(ent, seas_ml) { p <- v$p; p$ent_seas_amp_SH <- ent; p$seas_ml <- seas_ml; p }
sp0 <- ccx_spinup(mk(0, 0))
sp1 <- ccx_spinup(mk(21.2, 1))
stopifnot(isTRUE(all.equal(sp0$y, sp1$y, tolerance = 0)))
say("")
say("✅ ASSERTED: the spinup is IDENTICAL across arms (max|diff| %.3e) -- seas_drivers = 0",
    max(abs(sp0$y - sp1$y)))
say("   at spinup switches BOTH the shim and the seasonal ML off. One spinup, %d runs.",
    2 * length(ENT_GRID))

F <- ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp0$prod_c14,
                       bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
obs  <- ccx_prepare_obs()
err  <- list(sigma_d14c = v$sigma_d14c, rep_dC = v$rep_dC,
             grad_off_co2 = v$grad_off_co2, grad_off_d13c = v$grad_off_d13c)
eluc <- ccx_forcing_eluc_annual(F)

score <- function(ent, seas_ml) {
  p   <- mk(ent, seas_ml)
  aux <- ccx_prepare(p)                     # aux carries mld_coef, so per-arm
  sp  <- list(y = sp0$y, aux = aux, grid = aux$grid, params = p,
              prod_c14 = sp0$prod_c14, diagnostics = sp0$diagnostics)
  o   <- ccx_run(sp, F)$out
  st  <- unlist(ccx_loglik(o, obs, err, luc = eluc,
                           deep = sp0$diagnostics$d14c_bottom_box,
                           ocean_grad = ccx_ocean_grad_scored(o, sp),
                           by_stream = TRUE, d14c_mid = ccx_model_d14c_slabs(sp)))
  list(total = sum(st), streams = st)
}

## ---- the two profiles ------------------------------------------------------
say("")
say("LIKELIHOOD PROFILE over ent_seas_amp_SH (umol/kg), both arms")
say("  %8s %16s %16s %14s", "ent", "seas_ml = 0", "seas_ml = 1", "difference")
prof <- lapply(ENT_GRID, function(e) {
  a0 <- score(e, 0); a1 <- score(e, 1)
  say("  %8.1f %16.4f %16.4f %14.4f", e, a0$total, a1$total, a1$total - a0$total)
  list(ent = e, off = a0, on = a1)
})
tot0 <- vapply(prof, function(z) z$off$total, numeric(1))
tot1 <- vapply(prof, function(z) z$on$total,  numeric(1))

G0 <- max(tot0) - tot0[ENT_GRID == 0]
G1 <- max(tot1) - tot1[ENT_GRID == 0]
say("")
say("THE METRIC -- G = likelihood the COMPENSATOR still BUYS (best on the grid, minus OFF)")
say("  seas_ml = 0 : argmax ent %5.1f, G = %10.4f", ENT_GRID[which.max(tot0)], G0)
say("  seas_ml = 1 : argmax ent %5.1f, G = %10.4f", ENT_GRID[which.max(tot1)], G1)
say("  G(on) / G(off) = %.3f", G1 / G0)
say("  for scale, the FITTED compensator sat at %.1f (r3 winner) / %.1f (ent26)",
    ENT_FIT[["winner_r3"]], ENT_FIT[["ent26"]])
say("")
say("VERDICT (an ORDERING between two measured quantities):")
say("  %s", if (G1 < 0.5 * G0)
      "REDUNDANT -- the mechanism absorbs most of what the compensator bought; retiring the parameter is supported" else
      "*** NOT REDUNDANT -- option A ADDS to the shim rather than REPLACING it; retiring the parameter is NOT justified on this evidence ***")
say("⚠ Conditional profile. A refit can still move the answer, in EITHER direction.")

dir.create(dirname(OUT_RDS), showWarnings = FALSE, recursive = TRUE)
saveRDS(list(mode = CCX_MODE_CANONICAL, grid = ENT_GRID, profile = prof,
             total_off = tot0, total_on = tot1, G_off = G0, G_on = G1,
             fitted = ENT_FIT, built = Sys.time()), OUT_RDS)
say("")
say("wrote %s", OUT_RDS)
close(con)
