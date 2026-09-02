# =====================================================================
# diag_gate_g_mutation.R -- MUTATION TEST for GATE G, on the MODEL side.
#
# "A gate that passes is not a gate that works" ([[mutation_test_gates]]), and
# GATE G passes at every shipped arm, so the pass tells us nothing until the fail
# has been demonstrated. `tests/testthat/test-gate-bounds.R` mutates the gate's
# own OUTPUT, which tests the BOUND. This file mutates the MODEL, which tests
# whether the gate has power over the thing it claims to be about.
#
# WHAT IS MUTATED, AND WHY THAT KNOB. GATE G's claim is that the model's
# mixed-layer DIC level is out-of-sample against GLODAP because it is set by
# carbonate equilibrium with the 1750 atmosphere at `ALK_SURFACE` -- a FIXED
# constant whose own status string still says it "NEEDS a cited global-mean
# surface value". If that claim is true, moving `ALK_SURFACE` must move the gate,
# and by an amount the carbonate system predicts. If moving it does NOT move the
# gate, the gate is not measuring what its header says it is.
#
# ⚠ THE MUTATION IS TEMPORARY AND RESTORED, and the restoration is CHECKED. A
# diagnostic that leaves a constant perturbed would poison every later run in the
# same session.
#
# ⚠ THIS FILE ADOPTS NOTHING and proposes no change to ALK_SURFACE. The
# alkalinity value is a known open item; this is a sensitivity, not a fit.
#
# Usage:  Rscript calibration/diag_gate_g_mutation.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
source(ccx_path("calibration", "lib_glodap_obs.R"))

# ---- labels derive from named constants (project rule) --------------
GM_ARM   <- "from90"                       # the shipped arm
# Multipliers on ALK_SURFACE. The range is deliberately WIDE at the ends: the
# point is to find where the gate flips, not to propose a value.
GM_ALK_MULT <- c(0.96, 0.98, 0.99, 1.00, 1.01, 1.02, 1.04)

cat(sprintf("\n%s\nGATE G MUTATION TEST -- does the gate have power over ALK_SURFACE?\n  arm %s; |z| <= %g at n_eff = %d. ADOPTS NOTHING.\n%s\n",
            strrep("=", 78), GM_ARM, DG_GD_NSD, DG_GD_NEFF, strrep("=", 78)))

v   <- dg_vector(GM_ARM)
gr  <- ccx_ocean_grid(v$p$h_ml)
obs <- dg_gateG_obs(gr)
alk0 <- ccx_const("ALK_SURFACE")
cat(sprintf("  unmutated ALK_SURFACE = %.6g mol/kg\n", alk0))
cat(sprintf("  observed surface DIC  = %.1f umol/kg (cell sd %.1f), epoch %.0f\n",
            obs$surf, obs$surf_sd, round(obs$epoch_mean)))

cat(sprintf("\n  %8s %14s %11s %9s %8s  %s\n", "x ALK", "ALK mol/kg",
            "surf DIC", "d vs obs", "z", "verdict"))
res <- list()
for (m in GM_ALK_MULT) {
  # ⚠ MUTATE, RUN, RESTORE -- in that order, and the restore is unconditional.
  # ⚠ `<-` AND NOT `<<-`. This loop runs at top level, so its environment IS
  # globalenv, and `<<-` there starts its search in globalenv's PARENT -- the
  # attached packages -- and never finds CCX_CONSTANTS at all. Caught by the
  # error on the first run, but the shape is worth naming: a superassignment at
  # top level is not "assign globally".
  CCX_CONSTANTS[["ALK_SURFACE"]]$value <- alk0 * m
  g  <- tryCatch(dg_gateG(v, obs), error = function(e) e)
  CCX_CONSTANTS[["ALK_SURFACE"]]$value <- alk0
  if (inherits(g, "error")) {
    cat(sprintf("  %8.2f %14.6g %11s %9s %8s  ERROR: %s\n", m, alk0 * m, "--", "--",
                "--", conditionMessage(g)))
    next
  }
  vd <- dg_gateG_verdict(g, obs)
  res[[as.character(m)]] <- c(alk = alk0 * m, surf = g$surf, z = vd$z)
  cat(sprintf("  %8.2f %14.6g %11.1f %+9.1f %+8.2f  %s\n", m, alk0 * m, g$surf,
              vd$d_umol, vd$z, if (vd$pass) "PASS" else "FAIL"))
}
stopifnot(identical(ccx_const("ALK_SURFACE"), alk0))
cat(sprintf("\n  ALK_SURFACE restored to %.6g -- checked, not assumed.\n",
            ccx_const("ALK_SURFACE")))

# ---- what the carbonate system says the response SHOULD be ----------
# QUANTITATIVE PRE-CHECK, not a post-hoc rationalisation. At fixed pCO2 the
# mixed layer re-equilibrates, and to first order dDIC/DIC = (dALK/ALK) x R,
# where R is the ratio the carbonate system sets. Measuring R and stating it is
# what turns "the gate responds" into "the gate responds by the right amount".
if (length(res) >= 2) {
  d <- do.call(rbind, res)
  fit <- stats::lm(d[, "surf"] ~ d[, "alk"])
  slope <- stats::coef(fit)[[2]]
  R <- slope * alk0 / d[which.min(abs(d[, "alk"] - alk0)), "surf"]
  # ⚠ REPORTED AS A RATIO, NOT A RAW SLOPE. ALK is carried in mol/kg and DIC in
  # umol/kg, so the bare regression coefficient is ~8e5 and means nothing to a
  # reader; the dimensionless elasticity is the quantity with a prediction
  # attached. (Both are computed from the same fit; only R is printed.)
  cat(sprintf("\n  RESPONSE: %.2f umol/kg of DIC per 1 %% of ALK_SURFACE\n",
              slope * alk0 / 100))
  cat(sprintf("    = ELASTICITY R = %.3f (%% of DIC per %% of ALK).\n", R))
  cat("  ⚠ R NEAR 1 IS THE EXPECTED ANSWER at fixed pCO2 -- adding alkalinity to a\n")
  cat("    solution held at the atmosphere's pCO2 draws in very nearly the same\n")
  cat("    proportion of DIC. A response far from 1 would say the mutation is\n")
  cat("    reaching the gate through something other than carbonate equilibrium.\n")
  flip <- d[abs(d[, "z"]) > DG_GD_NSD, , drop = FALSE]
  if (nrow(flip)) {
    cat(sprintf("\n  ⇒ THE GATE FAILS once ALK_SURFACE moves by about %.1f%%,\n",
                100 * min(abs(flip[, "alk"] / alk0 - 1))))
    cat("    so the gate HAS POWER over the surface carbonate state.\n")
  } else {
    cat("\n  ⛔ THE GATE DID NOT FAIL ANYWHERE IN THIS RANGE. Widen GM_ALK_MULT\n")
    cat("    before believing it -- a bound nothing in the sweep can break is\n")
    cat("    not yet a demonstrated bound. [[mutation_test_gates]]\n")
  }
}

cat("\n=== DONE ===\n")
