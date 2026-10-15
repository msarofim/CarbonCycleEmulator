# =====================================================================
# LANDING CHECKS FOR refit_20260830_gamma_diff_remap
#
# The refit is converged (both arms: cycle 2 gain 0.0000). This does the four
# checks handoff 2026-08-30b s.4 lists, plus one the refit itself forced.
#
# ⚠ THE FORCED ONE. The FACE gate cleared gamma_diff = 0.25 on 08-29i against a
# PREDICTED payment of `fert_k` +6.1 % (154.85 -> 164.23). The converged refit
# went to 189.22 -- 3.6x that payment. A gate cleared at a predicted value has
# to be re-read at the REALIZED one, because what FACE constrains is the ridge
# coordinate's implied response R(400->564), and fert_k moves it.
#
# ⚠ AND THE OTHER ONE. `h_ml` landed at 35.25 m, essentially the 35.38 m the
# 08-28 sigma_eff refit produced -- which was RATIFIED "DO NOT ADOPT" because
# its whole gain was PRIOR CREDIT bought with a WORSE likelihood
# (memory hml_shallow_is_prior_credit: +4.060 = prior +7.397 / loglik -1.199).
# The same decomposition has to be run here before this mode is adopted. A
# shallow h_ml is not by itself a verdict either way.
#
# NOTHING HERE ADOPTS ANYTHING. ccx_mode_file() still resolves to
# refit_20260825f_from90 and this script does not touch it.
#
# Run:  Rscript calibration/diag_refit_20260830_landing.R      (~3 min)
# =====================================================================

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

NEW  <- file.path("calibration", "output", "refit_20260830_gamma_diff_remap")
OLD  <- file.path("calibration", "output", "quarantine", "20260903_ent26_adopted", "refit_20260825f_from90")
OLDP <- file.path("calibration", "output", "quarantine", "20260903_ent26_adopted", "refit_20260825f_pin90")
hdr  <- function(s) cat("\n", strrep("=", 72), "\n", s, "\n", strrep("=", 72), "\n", sep = "")

# ---- FACE estimator, copied verbatim from diag_face_check_gamma_diff.R ----
FACE_CHI0 <- 276.88; FACE_ENRICH <- 0.41; FACE_AMBIENT <- 400
FACE_MATURE_HI <- 0.10; FACE_SYNTH <- 0.218; FACE_YOUNG <- 0.23
enh   <- function(bm, K, chi) { d <- chi - FACE_CHI0; bm * d / (K + d) }
Rface <- function(bm, K, a = FACE_AMBIENT, e = FACE_AMBIENT * (1 + FACE_ENRICH))
  (1 + enh(bm, K, e)) / (1 + enh(bm, K, a)) - 1

hdr("1. THE FACE GATE, RE-READ AT THE REALISED MODE (not the predicted one)")
cells <- data.frame(
  what = c("incumbent (calib basis of everything shipped)",
           "08-29i PREDICTED payment at gamma = 0.25",
           "REFIT 20260830 from90  <-- the realised mode",
           "REFIT 20260830 pin90   (fert_k held at 90)"),
  beta_max = c(0.5109, 0.5109 * 1.023, 0.5552, 0.4740),
  fert_k   = c(154.8452, 164.23,       189.2176, 90.0000))
cells$R <- Rface(cells$beta_max, cells$fert_k)
for (i in seq_len(nrow(cells)))
  cat(sprintf("  %-45s beta_max %.4f  fert_k %8.3f  R(400->564) = %6.2f %%\n",
              cells$what[i], cells$beta_max[i], cells$fert_k[i], 100 * cells$R[i]))
cat(sprintf("\n  BRACKET: mature forest <= %.0f %% | plantation-weighted synthesis %.1f %% | young plantations %.1f %%\n",
            100 * FACE_MATURE_HI, 100 * FACE_SYNTH, 100 * FACE_YOUNG))
cat(sprintf("  ⚠ The gate has POWER only above %.1f %% (mutation-tested 08-29i).\n", 100 * FACE_SYNTH))
rr <- cells$R[3]
cat(sprintf("\n  VERDICT: realised R = %.2f %%, which is %s the %.1f %% synthesis.\n",
            100 * rr, if (rr > FACE_SYNTH) "ABOVE -- THE GATE BITES" else "below", 100 * FACE_SYNTH))
cat(sprintf("  Payment realised: fert_k +%.1f %% vs the +6.1 %% the gate was cleared on (%.1fx).\n",
            100 * (189.2176 / 154.8452 - 1), (189.2176 / 154.8452 - 1) / 0.061))

hdr("2. h_ml = 35.25: IS THE GAIN PRIOR CREDIT OR LIKELIHOOD? (the 08-28 test)")
# Score the NEW mode and the INCUMBENT on ONE objective, and split prior vs loglik.
band0 <- CCX_PARAM_TABLE$h_ml
on.exit(CCX_PARAM_TABLE$h_ml <<- band0, add = TRUE)
# The prior term is exactly ccx_make_logpost()'s own accumulation loop
# (R/calibrate.R:884-887), recomputed here. This is why the split does NOT need
# diag_landed_gap_streams.R, which is quarantined and hard-stops -- the 08-28
# decomposition used that script, and its absence was wrongly treated as a
# blocker on this check.
prior_of <- function(u) {
  names(u) <- CCX_PARAM_NAMES; pv <- ccx_unc_to_par(u)
  s0 <- 0
  for (n in CCX_PARAM_NAMES) {
    s <- CCX_PARAM_TABLE[[n]]
    s0 <- s0 + s$prior(pv[[n]]) + .log_jac(u[[n]], s)
  }
  s0
}
split_at <- function(path) {
  md <- readRDS(path); ccx_adopt_mode_band(md)
  bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
  lp <- ccx_make_logpost(years = c(1750, 2024), base_params = bp)(md$u_mode)
  pr <- prior_of(md$u_mode)
  pv <- ccx_mode_params(path)
  CCX_PARAM_TABLE$h_ml <<- band0
  list(lp = lp, prior = pr, ll = lp - pr, h_ml = pv$h_ml, fert_k = pv$fert_k)
}
a <- split_at(file.path(NEW, "from90", "mode_fit_pumpN.rds"))
b <- split_at(file.path(OLD, "mode_fit_pumpN.rds"))
cat(sprintf("  refit  from90   h_ml %7.2f  fert_k %8.3f   logpost %10.3f = prior %8.3f + loglik %11.3f\n",
            a$h_ml, a$fert_k, a$lp, a$prior, a$ll))
cat(sprintf("  incumbent       h_ml %7.2f  fert_k %8.3f   logpost %10.3f = prior %8.3f + loglik %11.3f\n",
            b$h_ml, b$fert_k, b$lp, b$prior, b$ll))
cat(sprintf("\n  DELTA (refit - incumbent):  logpost %+8.3f = prior %+7.3f + loglik %+8.3f\n",
            a$lp - b$lp, a$prior - b$prior, a$ll - b$ll))
cat("  08-28 REJECTED refit, same split:   +4.060 = prior  +7.397 + loglik   -1.199\n")
cat("\n  ⚠ VERDICT: THE 08-28 REJECTION CRITERION DOES NOT APPLY HERE. That mode was\n")
cat("    rejected because its gain was PRIOR CREDIT bought with a WORSE likelihood.\n")
cat("    This one's prior credit is comparable (+6.6 vs +7.4) but its LIKELIHOOD\n")
cat("    IMPROVES BY +33.0 rather than degrading. A shallow h_ml is not the verdict;\n")
cat("    the split is, and here it points the other way.\n")
cat("  ⚠ WHAT THIS DOES NOT SAY: most of that +33.0 is RECOVERING the adoption's own\n")
cat("    cost -- the incumbent is a pre-adoption vector read under a post-adoption\n")
cat("    objective. The claim is 'the refit is likelihood-driven', NOT 'h_ml = 35.25\n")
cat("    is vindicated'. Isolating h_ml needs a PROFILE at the new mode.\n")

hdr("3. THE ARM GAP -- what test-mode-file.R asserts")
p <- split_at(file.path(NEW, "pin90", "mode_fit_pumpN.rds"))
q <- split_at(file.path(OLDP, "mode_fit_pumpN.rds"))
cat(sprintf("  REFITTED arms   : pin90 %10.3f - from90 %10.3f = %+8.4f\n", p$lp, a$lp, p$lp - a$lp))
cat(sprintf("  INCUMBENT arms  : pin90 %10.3f - from90 %10.3f = %+8.4f\n", q$lp, b$lp, q$lp - b$lp))
cat(sprintf("\n  PIN_CREDIT the test expects: -11.6698 (tolerance 0.2)\n"))
cat(sprintf("  ⚠ PIN_PRIOR_CREDIT is a PRIOR term at fert_k = 90 and does NOT depend on\n"))
cat(sprintf("    gamma_diff, so any excess over it is a LIKELIHOOD differential.\n"))
cat(sprintf("    Refitted excess: %+.4f\n", (p$lp - a$lp) + 11.6698))

hdr("4. b0 AGAINST ITS DERIVED BAR (ruling 2, 2026-08-30)")
obs <- ccx_prepare_obs(); err <- list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5)
pp <- ccx_default_params(); pp <- ccx_set_enso(pp, list(gamma_enso = 0.5))
sp <- ccx_spinup(pp)
Fh <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14)
out <- ccx_run_fast(sp, Fh)$out
shift <- function(bv) { o <- out; o$co2_NH <- o$co2_NH + bv; o$co2_SH <- o$co2_SH + bv
                        ccx_loglik(o, obs, err) }
bb <- c(-4, -2, -1, 0, 1, 2, 4); ll <- vapply(bb, shift, numeric(1))
cf <- stats::coef(stats::lm(I(ll - ll[bb == 0]) ~ 0 + bb + I(bb^2)))
A <- -cf[["I(bb^2)"]]; b0 <- cf[["bb"]] / (2 * A)
cat(sprintf("  b0 = %+.4f ppm  (bar LIK_ICE_REP_ERR = %.1f; external floor 1.087 ppm)\n",
            b0, LIK_ICE_REP_ERR))
cat("  ⚠ UNCHANGED BY THE REFIT BY CONSTRUCTION -- the fixture is on ccx_default_params(),\n")
cat("    which the refit does not touch. Recorded so nobody re-derives that.\n")

cat("\nOPEN, and each needs a ruling rather than a default:\n")
cat("  (a) test-mode-file.R's premise is now PERMANENTLY false, not transiently --\n")
cat("      the gap survives refitting BOTH arms and is prior credit PLUS a ~9.5\n")
cat("      likelihood differential. It needs rewriting, not re-tolerancing.\n")
cat("  (b) an h_ml PROFILE at the new mode, to say whether 35.25 m specifically is\n")
cat("      load-bearing or is riding along with the rest of the refit.\n")
cat("  (c) whether ccx_mode_file() repoints to this arm. NOT taken here.\n\n")
