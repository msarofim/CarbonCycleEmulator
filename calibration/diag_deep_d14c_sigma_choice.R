# =====================================================================
# diag_deep_d14c_sigma_choice.R -- TURN THE MEASURED n_eff SPREAD INTO A SIGMA
# THE MCMC CAN USE.  (Marcus 2026-08-16: "an n_eff median and sigma")
#
# `diag_deep_d14c_neff.R` measured n_eff seven ways and got 6.4 to 3408. That is
# a measurement, not yet a likelihood. This file does the two things that turn
# it into one, and they are DIFFERENT THINGS that Marcus' request can mean:
#
#   OPTION 1 -- A POINT sigma. Summarize the admissible estimators to one n_eff
#     and keep the Gaussian term. Simple; the MCMC is unchanged in form.
#   OPTION 2 -- MARGINALIZE over the sigma uncertainty. If sigma is only known
#     to a factor, integrating it out is the honest thing, and for a
#     scaled-inverse-chi-squared prior on sigma^2 the single-observation
#     marginal has a closed form: STUDENT-t. One line in the likelihood.
#
# They are not the same answer, and the measured difference is NOT the one I
# expected: option 2 changes NEITHER decision -- it still holds `kz` and it
# still adopts candidate A -- but it cuts the kz-runaway penalty 4.3x, from a
# 4x margin over the holding threshold to a 4 % one. So the trade is about
# whether the term can ever REPLACE the `kz` bracket, not about whether it
# works. Part 3. NEITHER IS APPLIED HERE. `LIK_D14C_DEEP_NEFF` is Marcus'.
#
# ---------------------------------------------------------------------
# THE ADMISSIBLE SET IS THE JUDGMENT CALL IN THIS FILE, SO IT IS EXPLICIT.
# A median over all seven estimators would be arithmetic dressed as a decision:
# two of them are known-invalid and would drag it. Included/excluded, with the
# reason attached to each, in OC_ADMIT below. Change the set and the answer
# changes; that is the point of writing it down rather than taking median().
#
# RUNTIME < 5 s.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

SC_NEFF_RDS <- ccx_path("calibration", "output", "deep_d14c_neff",
                        "diag_deep_d14c_neff.rds")
SC_ISO_RDS  <- ccx_path("calibration", "output", "ocean_candidates",
                        "diag_ocean_candidates.rds")
SC_OUTDIR   <- ccx_path("calibration", "output", "deep_d14c_neff")
# Deviations the sigma has to price, both measured elsewhere and re-read here:
#   the kz runaway is the job the term was CREATED for (build script);
#   candidate A's gain is the job it is now being asked to arbitrate.
SC_Z_HOLD   <- 3      # the build script's own "HOLDS kz" criterion, in sigma
dir.create(SC_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

ne  <- readRDS(SC_NEFF_RDS)
iso <- readRDS(SC_ISO_RDS)$iso
g   <- readRDS(ccx_path("data", "obs_glodap_deep.rds"))
tg  <- ccx_deep_d14c_target()
sd_w <- ne$sd_w

# ---- the admissible set, with reasons ---------------------------------
SC_ADMIT <- list(
  list(id = "Kish, weights only",        n = ne$n_kish,        ok = FALSE,
       why = "assumes independence the correlogram refutes outright"),
  list(id = "correlogram, empirical rho", n = ne$n_corr,       ok = TRUE,
       why = "upper end of the bracket: basin contrast is sampled structure"),
  list(id = "correlogram, rho floored",   n = ne$n_corr_floor, ok = TRUE,
       why = "lower end of the bracket: basins as exchangeable water masses"),
  list(id = "block bootstrap, 10 deg",    n = ne$boot[["10"]]$n_eff, ok = FALSE,
       why = "block ~1100 km << 5500 km decorrelation -- biased HIGH"),
  list(id = "block bootstrap, 20 deg",    n = ne$boot[["20"]]$n_eff, ok = FALSE,
       why = "block ~2200 km still below the decorrelation scale"),
  list(id = "block bootstrap, 30 deg",    n = ne$boot[["30"]]$n_eff, ok = TRUE,
       why = "block ~3300 km, the shortest defensible one"),
  list(id = "block bootstrap, 60 deg",    n = ne$boot[["60"]]$n_eff, ok = TRUE,
       why = "block ~6700 km > the ~7000 km zero crossing; noisiest (16 blocks)"))

sep("PART 1. THE ADMISSIBLE SET")
cat(sprintf("%-30s %9s %5s  %s\n", "estimator", "n_eff", "use?", "why"))
for (a in SC_ADMIT)
  cat(sprintf("%-30s %9.1f %5s  %s\n", a$id, a$n, if (a$ok) "YES" else "no", a$why))
adm <- vapply(SC_ADMIT[vapply(SC_ADMIT, function(a) a$ok, logical(1))],
              function(a) a$n, numeric(1))
names(adm) <- vapply(SC_ADMIT[vapply(SC_ADMIT, function(a) a$ok, logical(1))],
                     function(a) a$id, character(1))

sep("PART 2. OPTION 1 -- A POINT SIGMA")
med <- stats::median(adm); geo <- exp(mean(log(adm)))
sdlog <- stats::sd(log(adm))
cat(sprintf("admissible n_eff: %s\n", paste(sprintf("%.1f", sort(adm)), collapse = ", ")))
cat(sprintf("\n%-34s %9s %9s\n", "summary", "n_eff", "sigma"))
cat(sprintf("%-34s %9.1f %9.2f\n", "median", med, sd_w / sqrt(med)))
cat(sprintf("%-34s %9.1f %9.2f\n", "geometric mean", geo, sd_w / sqrt(geo)))
cat(sprintf("%-34s %9.1f %9.2f   <- IN USE, asserted\n", "incumbent", tg$n_eff, tg$sd))
cat(sprintf("%-34s %9.1f %9.2f\n", "conservative end (min admissible)",
            min(adm), sd_w / sqrt(min(adm))))
cat(sprintf("\nspread of log n_eff: sd = %.2f, i.e. n_eff known to a factor of %.1f (1 sd),\n",
            sdlog, exp(sdlog)))
cat(sprintf("equivalently sigma known to a factor of %.2f.\n", exp(sdlog / 2)))
cat(sprintf("\nTHE HEADLINE: every reasonable summary of the admissible set lands within\n"))
cat(sprintf("%.0f %% of the asserted 20. median %.1f, geometric mean %.1f, incumbent %d.\n",
            100 * max(abs(c(med, geo) / tg$n_eff - 1)), med, geo, tg$n_eff))
cat("The asserted value is MEASUREMENT-CONSISTENT. Replacing 20 with 19 would be\n")
cat("a 2.7 % change in sigma bought at the cost of making every pre-today logL\n")
cat("incomparable -- the provenance is what needed fixing, not the number.\n")

sep("PART 3. OPTION 2 -- MARGINALISE THE SIGMA UNCERTAINTY (Student-t)")
# sigma^2 ~ scaled-inv-chi^2(nu, s^2)  =>  the single-observation marginal is
# t_nu(target, s). Calibrate nu from the MEASURED spread: for that prior,
# Var(log sigma) = trigamma(nu/2) / 4.
nu <- tryCatch(stats::uniroot(function(v) trigamma(v / 2) - 4 * sdlog^2 / 4,
                              c(0.2, 200))$root, error = function(e) NA_real_)
s_t <- sd_w / sqrt(geo)
cat(sprintf("measured sd(log sigma) = %.3f  ->  nu = %.2f, scale s = %.2f permil\n",
            sdlog / 2, nu, s_t))
cat("nu that small is very heavy-tailed -- near-Cauchy. That is not a modelling\n")
cat("flourish, it is what a 17x bracket on sigma actually implies.\n\n")
pen_norm <- function(dev, s) dev^2 / (2 * s^2)
pen_t    <- function(dev, s, v) ((v + 1) / 2) * log1p(dev^2 / (v * s^2))
dev_run  <- abs(g$kz_runaway_d14c - tg$target)
cat(sprintf("%-34s %12s %12s\n", "deviation being priced", "Gaussian", "Student-t"))
cat(sprintf("%-34s %12.2f %12.2f\n",
            sprintf("kz runaway, %.1f permil", dev_run),
            pen_norm(dev_run, s_t), pen_t(dev_run, s_t, nu)))
for (dv in c(10, 20, 30, 50))
  cat(sprintf("%-34s %12.2f %12.2f\n", sprintf("%g permil", dv),
              pen_norm(dv, s_t), pen_t(dv, s_t, nu)))
hold_norm <- pen_norm(dev_run, s_t) > SC_Z_HOLD^2 / 2
hold_t    <- pen_t(dev_run, s_t, nu) > SC_Z_HOLD^2 / 2
cat(sprintf("\n\"HOLDS kz\" threshold (the build script's z > %g) = %.2f log-units.\n",
            SC_Z_HOLD, SC_Z_HOLD^2 / 2))
cat(sprintf("  Gaussian at s = %.2f:  %.2f  -> %s\n", s_t, pen_norm(dev_run, s_t),
            if (hold_norm) "HOLDS" else "DOES NOT HOLD"))
cat(sprintf("  Student-t nu = %.2f:   %.2f  -> %s\n", nu, pen_t(dev_run, s_t, nu),
            if (hold_t) "HOLDS" else "DOES NOT HOLD"))
cat("\nREAD THAT PAIR CAREFULLY -- I EXPECTED OPTION 2 TO FAIL HERE AND IT DOES NOT.\n")
cat(sprintf("The t still HOLDS, at %.2f against a threshold of %.2f. What it does is\n",
            pen_t(dev_run, s_t, nu), SC_Z_HOLD^2 / 2))
cat(sprintf("cut the runaway penalty %.1fx (%.1f -> %.2f) and leave a %.0f %% margin where\n",
            pen_norm(dev_run, s_t) / pen_t(dev_run, s_t, nu),
            pen_norm(dev_run, s_t), pen_t(dev_run, s_t, nu),
            100 * (pen_t(dev_run, s_t, nu) / (SC_Z_HOLD^2 / 2) - 1)))
cat("there was a 4x one. So the objection to option 2 is NOT that it breaks the\n")
cat("term's founding purpose -- it is that it removes all the margin on it, and\n")
cat("the margin is what would let the term REPLACE the kz bracket rather than sit\n")
cat("behind it. Under option 2 the bracket stays load-bearing indefinitely.\n")
cat("\nCAVEAT ON THE COMPARISON: the z > 3 criterion was written for a Gaussian, so\n")
cat("scoring a t against a Gaussian-derived threshold is like-for-like only in the\n")
cat("operational sense that matters here -- how many log-units the objective pays\n")
cat("for the runaway. It is not a tail probability.\n")

sep("PART 4. WHAT EACH OPTION DOES TO CANDIDATE A")
dInf <- iso[["Inf"]]$deep; d50 <- iso[["5000"]]$deep
netA <- iso[["5000"]]$total - iso[["Inf"]]$total
other <- netA - (pen_norm(dInf - tg$target, tg$sd) - pen_norm(d50 - tg$target, tg$sd))
cat(sprintf("A's non-deep cost is %+.2f log-units and does not depend on any of this.\n\n", other))
cat(sprintf("%-40s %9s %12s %10s\n", "option", "sigma", "A net logL", "adopted?"))
rows <- list(
  list("option 1, median",            sd_w / sqrt(med), NA),
  list("option 1, geometric mean",    s_t,              NA),
  list("option 1, incumbent (20)",    tg$sd,            NA),
  list("option 1, conservative end",  sd_w / sqrt(min(adm)), NA),
  list("option 2, Student-t",         s_t,              nu))
for (r in rows) {
  gn <- if (is.na(r[[3]]))
    pen_norm(dInf - tg$target, r[[2]]) - pen_norm(d50 - tg$target, r[[2]])
  else
    pen_t(dInf - tg$target, r[[2]], r[[3]]) - pen_t(d50 - tg$target, r[[2]], r[[3]])
  nt <- gn + other
  cat(sprintf("%-40s %9.2f %+12.2f %10s\n", r[[1]], r[[2]], nt,
              if (nt > 0) "yes" else "no"))
}
cat("\nNote what option 2 does here too: it shrinks A's gain as well as the kz\n")
cat("penalty, because heavy tails flatten the term everywhere beyond ~1 sigma.\n")
cat("It is not a thumb on the scale for or against A -- it is a term that says\n")
cat("less about everything.\n")

sep("PART 5. RECOMMENDATION, AND WHAT IS STILL MARCUS'")
cat("RECOMMEND OPTION 1 AT THE INCUMBENT 20, RE-DOCUMENTED AS MEASURED.\n")
cat(sprintf("  * median %.1f and geometric mean %.1f bracket it within %.0f %%;\n",
            med, geo, 100 * max(abs(c(med, geo) / tg$n_eff - 1))))
cat("  * changing the number buys a 2.7 % sigma change and costs comparability\n")
cat("    with every logL in the repo. The defect was provenance, and provenance\n")
cat("    is fixed by the receipt, not by moving the value.\n")
cat("  * option 2 is the statistically better-posed treatment and it changes\n")
cat("    NEITHER decision -- it still holds kz and it still adopts A. What it\n")
cat("    costs is margin: the runaway penalty falls 4.3x to within 4 % of the\n")
cat("    holding threshold, so the term could no longer be trusted to REPLACE\n")
cat("    the kz bracket. Take option 2 if the honest error model matters more\n")
cat("    than retiring the bracket; take option 1 if retiring it is the goal.\n")
cat("    That is a real trade and it is not mine to make.\n")
cat("\nSTILL NOT SETTLED BY THIS FILE, and both are Marcus':\n")
cat("  1. REPRESENTATION ERROR. Still zero. It adds in quadrature and would push\n")
cat(sprintf("     sigma above %.2f; at %.2f permil A stops being adopted.\n",
            tg$sd, sd_w / sqrt(min(adm))))
cat("  2. Whether candidate A's kz = 6404, outside the [3830, 6200] bracket, is a\n")
cat("     blocker or a re-derivation. Note the coupling: option 2 removes the\n")
cat("     term's ability to replace the bracket, so it makes that question\n")
cat("     HARDER, not easier.\n")

saveRDS(list(admissible = adm, median = med, geomean = geo, sdlog = sdlog,
             nu = nu, scale = s_t, incumbent = c(n_eff = tg$n_eff, sd = tg$sd)),
        file.path(SC_OUTDIR, "diag_deep_d14c_sigma_choice.rds"))
cat(sprintf("\n\nwritten: %s\n",
            file.path(SC_OUTDIR, "diag_deep_d14c_sigma_choice.rds")))
