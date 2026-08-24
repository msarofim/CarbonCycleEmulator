# =====================================================================
# THE OCEAN-PROBE RATE SCAN -- does relieving the plateau decade relax the fit?
#
# Marcus 2026-08-24: "I was worried that fitting to the plateau was making the
# pre- and post-plateau model worse ... some combination of reducing emissions
# or artificially injected atmospheric carbon into the oceans should be able to
# take the tension off of that decade."
#
# THAT IS A LEVERAGE QUESTION AND ONLY A RE-OPTIMISATION ANSWERS IT. A residual
# is the OUTCOME of a fit, so a good in-window residual is the SYMPTOM of the
# distortion, not evidence against it -- the mistake made and recorded on
# 2026-08-23 (handoff 23c sec.5.2). Hence four refits, not four model runs.
#
# WHY THE OCEAN ROUTING RATHER THAN THE FOSSIL ONE. The `foss` probe does two
# jobs at once: a plateau-decade correction AND a permanent level shift (42 % of
# its 1950 CO2 effect survives to 2024). The second job belongs to `luc_scale`
# and `rep_dC`, which is why `luc_scale` routed around it twice. The ocean
# probe retains 3.3 % by 2024, so it isolates the decade. It is also
# isotopically near-silent, so `sigma_d14c` does not inflate absorbing an
# artefact of the instrument and contaminate the very leverage read we want.
#
# ITS IMPLAUSIBLE MAGNITUDE IS NOT A DEFECT. As a physical ocean sink 9.4 GtC/yr
# is absurd (today's whole global ocean sink is ~3). As a PROBE it is
# prescribed, unfitted, carries no free parameter and is labelled artificial --
# it asks a counterfactual, not a mechanism.
#
# EVERY VERDICT BELOW IS AGAINST A PREDICTION WRITTEN BEFORE LAUNCH:
#   notes/prereg_2026-08-24b_ocean_probe_rate_scan.md
#
# Usage:  Rscript calibration/diag_ocean_probe_scan.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# CCX_SCAN_DIR exists so the PINNED reporting path can be exercised against a
# throwaway tree before the real arms land -- the live _PINLUC directories are
# mid-run, and writing a fake pump_arms_comparison.rds into one of them would
# make the completion test read the SEED copy, which is exactly the trap this
# driver already had to fix once. Same pattern as CCX_ARM_OUTDIR.
SCAN_DIR   <- local({
  d <- Sys.getenv("CCX_SCAN_DIR", NA_character_)
  if (is.na(d) || !nzchar(d)) ccx_path("calibration", "output", "ocean_probe_scan")
  else { cat(sprintf("OVERRIDE CCX_SCAN_DIR = %s\n", d)); d }
})
SCAN_RATES <- c("0", "2.5", "9.434", "15")     # GtC/yr; "0" is the matched zero
SCAN_REF   <- "0"
# THE PINNED ARMS (added after P3 was falsified -- see the addendum in the
# pre-registration). `luc_scale` moved +2.94 sd at rate 15 with it free, so the
# free arms cannot separate "the plateau does not drive rep_dC" from
# "luc_scale absorbed the relief first". These close that route.
#
# *** A PINNED ARM'S LAPLACE EVIDENCE IS NOT COMPARABLE TO AN UNPINNED ONE ***
# its `luc_scale` prior has been replaced by a near-delta, so the logposts below
# are NOT on the same scale as the free arms'. Read PARAMETERS and PER-STREAM
# logL across the pin boundary, never evidence and never logpost.
SCAN_PINNED <- c("9.434", "15")
SCAN_PIN_AT <- 0.8983759151                   # = the rate-0 arm's own converged value
SINK_WIN   <- CCX_ARTIFICIAL_SINK_WIN
# The pre-registered thresholds, as named constants so the verdict text and the
# test cannot drift apart.
PRE_REP_DC     <- 0.5   # sd; P1
PRE_LUC_SCALE  <- 1.0   # sd; P3 point prediction
PRE_LUC_FALSIF <- 2.0   # sd; P3 falsifier -- above this the shape argument is WRONG
PRE_SIGMA_D14C <- 1.0   # sd; P4
# What the `foss` probe did, at the SAME window-end CO2 effect (-6.51 ppm).
# Receipts: handoff 2026-08-23c sec.2 table (free and pinned runs).
FOSS_REP_DC_FREE <- 5.126; FOSS_REP_DC_PIN <- 4.102; FOSS_REP_DC_OFF <- 5.566
FOSS_LUC_SD      <- 5.52 ; FOSS_SIGMA_D14C_SD <- 3.85

KEY <- c("rep_dC", "luc_scale", "sigma_d14c", "beta_max", "fert_k",
         "kz", "k_w", "h_ml", "pump_grad", "bomb_total", "q10")

mode_path <- function(r) file.path(SCAN_DIR, paste0("rate_", r), "mode_fit_pumpN.rds")
# COMPLETION IS `pump_arms_comparison.rds`, NOT the mode file.
# Every scan dir was SEEDED with a copy of the adopted mode so the warm-start
# path runs exactly as production does -- so `mode_fit_pumpN.rds` EXISTS in an
# arm that has not started yet, and it is the UNPERTURBED reference. Keying on
# it reported the still-running rate-15 arm as finished, with every delta
# exactly +0.00 and its logpost identical to rate 0's. Caught by the
# all-exactly-zero column, which is a code path and never nature.
# `pump_arms_comparison.rds` is written once, at the very end of the driver.
done_path <- function(r) file.path(SCAN_DIR, paste0("rate_", r), "pump_arms_comparison.rds")
have <- SCAN_RATES[file.exists(vapply(SCAN_RATES, done_path, "")) &
                   file.exists(vapply(SCAN_RATES, mode_path, ""))]
# pinned arms carry a "P" suffix in every table below so no row can be read as a
# free arm; their directory is rate_<r>_PINLUC
pin_dir  <- function(r) file.path(SCAN_DIR, paste0("rate_", r, "_PINLUC"))
pin_tag  <- function(r) paste0(r, "P")
have_pin <- SCAN_PINNED[file.exists(file.path(pin_dir(SCAN_PINNED),
                                              "pump_arms_comparison.rds"))]
if (!SCAN_REF %in% have) stop("the reference arm (rate ", SCAN_REF, ") has not finished")
if (length(have) < length(SCAN_RATES))
  cat(sprintf("*** PARTIAL SCAN: %s of %s arms finished (%s). Verdicts below are\n",
              length(have), length(SCAN_RATES), paste(have, collapse = ", ")),
      "*** PROVISIONAL -- the largest rate is the one that can still falsify P3.\n\n")

M <- lapply(stats::setNames(have, have), function(r) readRDS(mode_path(r)))
for (r in have_pin)
  M[[pin_tag(r)]] <- readRDS(file.path(pin_dir(r), "mode_fit_pumpN.rds"))
ref <- M[[SCAN_REF]]
# GATE: a pinned arm must actually sit at the pin. A pin that silently failed to
# bind would look exactly like "the parameter chose to stay put", which is the
# conclusion these arms exist to test.
for (r in have_pin) {
  got <- M[[pin_tag(r)]]$par_mode$luc_scale
  if (abs(got - SCAN_PIN_AT) > 1e-6)
    stop("pinned arm rate ", r, " has luc_scale = ", format(got, digits = 10),
         ", not the pin ", format(SCAN_PIN_AT, digits = 10), " -- the pin did NOT bind.")
}
if (length(have_pin))
  cat(sprintf("PINNED arms present (%s), tagged with a trailing P. luc_scale held at %.10f;\n  their logposts are NOT comparable to the free arms'.\n\n",
              paste(pin_tag(have_pin), collapse = ", "), SCAN_PIN_AT))
# BELT AND BRACES on the same trap: an arm whose parameters are BIT-IDENTICAL to
# the reference is the seed copy, not a result. A real refit at a non-zero rate
# cannot reproduce the reference mode to the last bit.
for (r in setdiff(have, SCAN_REF))
  if (identical(M[[r]]$par_mode, ref$par_mode))
    stop("arm rate ", r, " is bit-identical to the reference -- that is the ",
         "SEED copy of mode_fit_pumpN.rds, not a fit. Its refit has not written yet.")
# sd from the REFERENCE arm throughout: a Delta measured in each arm's own sd
# would change units between columns, and "moved 2 sd" would mean two things.
sd_u <- ref$sd_unc
u_of <- function(m) unlist(ccx_par_to_unc(m$par_mode))
u0   <- u_of(ref)

cat("=== THE SCAN ===\n")
cat(sprintf("%-8s %12s %10s %9s %8s\n", "rate", "logpost", "vs rate0", "minutes", "evals"))
for (r in have) cat(sprintf("%-8s %12.2f %10.2f %9.1f %8d\n", r, M[[r]]$logpost,
                            M[[r]]$logpost - ref$logpost, M[[r]]$minutes, M[[r]]$n_eval))

cat("\n=== PARAMETERS, in sd of the rate-0 posterior (UNCONSTRAINED coord) ===\n")
cat("(sd_unc is the UNCONSTRAINED sd and par_mode is NATURAL -- dividing one by\n")
cat(" the other gave a nonsense '+2202 sd' on 2026-08-23. Both sides are\n")
cat(" transformed here before differencing.)\n")
cat(sprintf("%-13s %10s", "param", "rate0"))
cols <- c(setdiff(have, SCAN_REF), pin_tag(have_pin))
for (r in cols) cat(sprintf(" %9s", r)); cat("\n")
allarms <- c(have, pin_tag(have_pin))
D <- matrix(NA_real_, length(KEY), length(allarms), dimnames = list(KEY, allarms))
for (r in allarms) { u <- u_of(M[[r]]); D[, r] <- (u[KEY] - u0[KEY]) / sd_u[KEY] }
for (k in KEY) {
  cat(sprintf("%-13s %10.4f", k, ref$par_mode[[k]]))
  for (r in cols)
    cat(sprintf(" %+9.2f", D[k, r]))
  cat("\n")
}

cat("\n=== P1 -- DOES RELIEVING THE DECADE RELAX `rep_dC`? ===\n")
cat(sprintf("  the `foss` probe, at the SAME window-end CO2 effect: %.3f -> %.3f free, %.3f pinned\n",
            FOSS_REP_DC_OFF, FOSS_REP_DC_FREE, FOSS_REP_DC_PIN))
cat(sprintf("  %-8s %10s %10s\n", "rate", "rep_dC", "d(sd)"))
for (r in allarms) cat(sprintf("  %-8s %10.4f %+10.2f%s\n", r, M[[r]]$par_mode$rep_dC, D["rep_dC", r],
    if (grepl("P$", r)) "   <- luc_scale PINNED" else ""))
free <- have
p1 <- max(abs(D["rep_dC", free]))
cat(sprintf("  worst |d| = %.2f sd against a pre-registered %.2f  ==>  P1 %s\n",
            p1, PRE_REP_DC, if (p1 < PRE_REP_DC) "HOLDS" else "FAILS"))
if (p1 < PRE_REP_DC && all(D["rep_dC", free] >= 0))
  cat("  NOTE every arm moves rep_dC the WRONG WAY (up). Relieving the plateau\n",
      " decade does not relax the level offset -- it is not the plateau's doing.\n")

cat("\n=== P3 -- DOES THE MODEL ROUTE AROUND IT VIA `luc_scale`? ===\n")
cat(sprintf("  the `foss` probe moved it +%.2f sd at the same CO2 effect\n", FOSS_LUC_SD))
for (r in setdiff(have, SCAN_REF))
  cat(sprintf("  rate %-8s %+6.2f sd\n", r, D["luc_scale", r]))
p3 <- max(abs(D["luc_scale", free]))
cat(sprintf("  worst |d| = %.2f sd; predicted < %.1f, falsifier > %.1f  ==>  %s\n", p3,
            PRE_LUC_SCALE, PRE_LUC_FALSIF,
            if (p3 < PRE_LUC_SCALE) "P3 HOLDS"
            else if (p3 < PRE_LUC_FALSIF) "P3 MISSED (not falsified) -- the escape route is NARROWED, not closed"
            else "P3 FALSIFIED -- the shape argument is WRONG"))
cat(sprintf("  ratio to `foss` at matched CO2 effect: %.2fx\n", p3 / FOSS_LUC_SD))

cat("\n=== P4 -- DO THE ISOTOPES STAY QUIET? ===\n")
cat(sprintf("  the `foss` probe inflated sigma_d14c +%.2f sd (6.13 -> 8.96)\n", FOSS_SIGMA_D14C_SD))
for (r in setdiff(have, SCAN_REF))
  cat(sprintf("  rate %-8s sigma_d14c %.4f (%+.2f sd)\n", r, M[[r]]$par_mode$sigma_d14c,
              D["sigma_d14c", r]))
p4 <- max(abs(D["sigma_d14c", free]))
cat(sprintf("  worst |d| = %.2f sd against a pre-registered %.1f  ==>  P4 %s\n",
            p4, PRE_SIGMA_D14C, if (p4 < PRE_SIGMA_D14C) "HOLDS" else "FAILS"))

if (length(have_pin)) {
  cat("\n=== P5/P6 -- THE PINNED ARMS: does the relief reach `rep_dC` once\n")
  cat("    `luc_scale` is shut? (the `foss` probe pinned went 5.566 -> 4.102) ===\n")
  cat(sprintf("  %-8s %10s %9s %10s %10s\n", "arm", "rep_dC", "d(sd)", "beta_max", "fert_k"))
  for (r in have_pin) { a <- pin_tag(r)
    cat(sprintf("  %-8s %10.4f %+9.2f %+10.2f %+10.2f\n", a, M[[a]]$par_mode$rep_dC,
                D["rep_dC", a], D["beta_max", a], D["fert_k", a])) }
  p5 <- max(abs(D["rep_dC", pin_tag(have_pin)]))
  cat(sprintf("  P5: worst |d rep_dC| = %.2f sd; predicted < %.1f, FALSIFIER > 1.0  ==>  %s\n",
              p5, PRE_REP_DC,
              if (p5 > 1) "P5 FALSIFIED -- relieving the plateau DOES relax the level offset"
              else if (p5 < PRE_REP_DC) "P5 HOLDS -- the plateau is NOT the source of rep_dC"
              else "P5 MISSED (not falsified)"))
  p6 <- max(abs(D[c("beta_max", "fert_k"), pin_tag(have_pin)]))
  cat(sprintf("  P6: worst |d| on the (beta_max, fert_k) ridge = %.2f sd; predicted > 1.5  ==>  %s\n",
              p6, if (p6 > 1.5) "P6 HOLDS -- the ridge took over" else "P6 FAILS"))
  if (p5 < PRE_REP_DC && p6 < 1.5)
    cat("  BOTH QUIET: the probe's cost is simply NOT RECOVERABLE, i.e. the plateau\n",
        " window carries no leverage over any fitted parameter and the free arms'\n",
        " recovery was bought ENTIRELY by luc_scale.\n")
}

cat("\n=== P2 -- PER-STREAM, vs rate 0 (+ = the probe's fit is better) ===\n")
nm <- names(ref$streams)
S <- sapply(c(setdiff(have, SCAN_REF), pin_tag(have_pin)), function(r)
  unlist(M[[r]]$streams)[nm] - unlist(ref$streams)[nm])
S <- rbind(S, TOTAL = colSums(S))
ord <- c("TOTAL", setdiff(rownames(S)[order(-abs(S[, ncol(S)]))], "TOTAL"))
cat(sprintf("%-20s", "stream")); for (r in colnames(S)) cat(sprintf(" %10s", r)); cat("\n")
for (i in ord) { cat(sprintf("%-20s", i))
  for (r in colnames(S)) cat(sprintf(" %+10.2f", S[i, r])); cat("\n") }
ice <- S["co2_icecore", setdiff(have, SCAN_REF), drop = TRUE]
cat(sprintf("\n  co2_icecore by rate: %s\n", paste(sprintf("%+.2f", ice), collapse = "  ")))
cat(sprintf("  monotone in rate? %s -- pre-registered NOT monotone, because at the\n",
            if (all(diff(ice) > 0) || all(diff(ice) < 0)) "YES" else "NO"))
cat("  mode the model already sits 1.67 ppm BELOW the ice in 1942-50, so a local\n")
cat("  probe OVERSHOOTS the window it is meant to relieve.\n")

saveRDS(list(rates = have, D = D, streams = S, logpost = sapply(M, `[[`, "logpost"),
             rep_dC = sapply(M, function(m) m$par_mode$rep_dC),
             prereg = c(rep_dC = PRE_REP_DC, luc_scale = PRE_LUC_SCALE,
                        luc_falsif = PRE_LUC_FALSIF, sigma_d14c = PRE_SIGMA_D14C)),
        file.path(SCAN_DIR, "scan_summary.rds"))
cat(sprintf("\nwritten: %s\n", file.path(SCAN_DIR, "scan_summary.rds")))
