# =====================================================================
# diag_which_stream_pays.R -- which observational stream is buying the
# indefensible parameters, and what would each one choose on its own?
#
# THE QUESTION, Marcus 2026-08-13: "is there a path forward that is both
# scientifically justified and will improve the matches to observations?"
#
# THE SETUP. mode_fit.rds sits at beta = 0.088 and q10 = 0.169.
#
# WHY THOSE ARE INDEFENSIBLE, stated so each claim carries its own receipt
# rather than an adjective. q10 = 0.169 is not merely small: q10 < 1 makes
# heterotrophic respiration FALL as the soil warms, which is the wrong SIGN,
# and the sign is the part that needs no citation. beta = 0.088 is scored below
# against GCB's own land sink over 2015-2024 -- measured here, not recalled.
# (Deliberately NOT justified by "C4MIP's beta range": this model's beta is the
# coefficient in NPP = NPP0(1 + beta ln(chi/chi0)), which is not C4MIP's beta in
# GtC/ppm, and the two must not be compared without a conversion nobody has
# done. reference_arora2020_c4mip_gamma is about gamma_L, a different quantity.)
#
# diag_d13c_suess.R already established that the model
# over-depletes atmospheric d13C by ~0.55 permil and that NONE of the source
# signature, the fractionation constants, the reachable sink partition or the
# gross land loop closes it -- and that "the calibration's only remaining way
# to relieve it is to manufacture land sink, which is what q10 -> 0.17 is
# doing." That is a HYPOTHESIS about who is paying. This file measures it.
#
# WHY IT IS WORTH MEASURING RATHER THAN INHERITING. Two of the load-bearing
# claims in this repo turned out to be conditional on a defect this week:
# diag_d13c_suess [3]'s partition verdict was computed on a model whose land
# had the WRONG SIGN (diag_d13c_partition_refit.R re-ran it -- the verdict
# survived, but nobody knew that until it was re-run), and
# test-likelihood.R:114/117 spent five handoffs labeled a stale fixture while
# reporting a real bias. Inherited attribution is cheap to check and this is
# the cheapest possible check.
#
# WHAT IT DOES. A 2-D (beta, q10) slice, everything else at the MODE, scoring
# each observational stream SEPARATELY via ccx_loglik(by_stream = TRUE). If
# each stream's own optimum sits in a different place, that difference is the
# tension the sampler is resolving by moving physics -- and the size of the
# difference is how much physics it has to move.
#
# WHAT IT IS NOT. A 2-D slice at fixed everything-else is not a refit and its
# optima are grid-coarse. It bounds the attribution; the MCMC decides it.
#
# RUNTIME ~2 min.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- PINNED TO THE LOG FERTILIZATION FORM (2026-08-14) --------------
# This diagnostic was written against NPP = NPP0(1 + beta ln(chi/chi0)) and
# every number in its header is a LOG-FORM number. On 2026-08-14 the default
# flipped to CCX_FERT_MM, under which `beta` is INERT -- so without this pin the
# file would still run, still print a beta column, and silently report the same
# MM answer for every beta. (That is not hypothetical: it happened to
# diag_fert_pulse_gates.R and to the app's fertilization switch on the day of
# the flip, and identical rows are what caught both.)
#
# The pin makes this file reproduce its recorded numbers exactly. It does NOT
# make them current: the shipped model is now the saturating form, and anything
# here that fed a live decision must be re-run under it.
local({
  .orig <- ccx_default_params
  assign("ccx_default_params", function() {
    p <- .orig(); p$fert_form <- CCX_FERT_LOG; p
  }, envir = globalenv())
})

# ---- labels derive from constants (project rule) --------------------
WS_YEARS  <- c(1750, 2024)
WS_BETAS  <- c(0.1, 0.2, 0.3, 0.4, 0.5, 0.7, 0.9, 1.2)
WS_Q10S   <- c(0.2, 0.5, 1.0, 1.5, 2.0, 2.5)
WS_MODE   <- ccx_path("calibration", "output", "mode_fit.rds")

mode_fit <- readRDS(WS_MODE)
# par_mode carries ONLY the 16 calibrated names -- it is not a usable parameter
# list on its own (ccx_spinup dies inside the carbonate solve on the missing
# sst_NH). Overlay it on the defaults, and take only the names the model knows:
# bomb_total and the three sigmas belong to the likelihood, not to ccx_deriv.
pm_raw <- mode_fit$par_mode
pm  <- utils::modifyList(ccx_default_params(),
                         pm_raw[intersect(names(pm_raw), names(ccx_default_params()))])
pm$sigma_co2 <- pm_raw$sigma_co2; pm$sigma_d13c <- pm_raw$sigma_d13c
pm$sigma_d14c <- pm_raw$sigma_d14c; pm$bomb_total <- pm_raw$bomb_total
err <- list(sigma_co2 = pm$sigma_co2, sigma_d13c = pm$sigma_d13c,
            sigma_d14c = pm$sigma_d14c)
cat(sprintf("\nsigmas from mode_fit.rds: co2 %.3f ppm, d13c %.3f permil, d14c %.2f permil\n",
            err$sigma_co2, err$sigma_d13c, err$sigma_d14c))
cat(sprintf("mode: beta %.3f  q10 %.3f   (defaults 0.380 / 2.000)\n", pm$beta, pm$q10))
cat("EVERYTHING EXCEPT beta AND q10 IS HELD AT THE MODE, including the ocean.\n")
cat("NOTE the mode is stale in four ways (handoff 13g sec.0.5) -- this slice is\n")
cat("about the SHAPE of the tension, not about the mode's location.\n")

obs <- ccx_prepare_obs()

# stream families, by the prefix ccx_loglik(by_stream = TRUE) emits
WS_FAMILY <- list(
  CO2  = "^co2_",
  d13C = "^d13c",
  d14C = "^d14c")

score <- function(beta, q10, fp = CCX_F_LUC_PERM_DEFAULT) {
  p <- pm; p$beta <- beta; p$q10 <- q10
  p$f_luc_perm <- fp
  s <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", WS_YEARS, prod_c14 = s$prod_c14,
                         bomb_total_kmol = pm$bomb_total)
  ll <- ccx_loglik(ccx_run_fast(s, F)$out, obs, err, by_stream = TRUE)
  v <- vapply(WS_FAMILY, function(rx) sum(unlist(ll[grepl(rx, names(ll))])), numeric(1))
  c(v, total = sum(unlist(ll)))
}

mk_grid <- function(fp) {
  g <- expand.grid(beta = WS_BETAS, q10 = WS_Q10S)
  cbind(g, t(vapply(seq_len(nrow(g)),
                    function(i) score(g$beta[i], g$q10[i], fp), numeric(4))))
}
# THE CONTROL. Without it, "the optimum is at defensible values" is a statement
# about the mode's OTHER parameters and the sigmas, not about the LUC fix. The
# buggy arm is what makes it an attribution.
grid0 <- mk_grid(0)
grid  <- mk_grid(CCX_F_LUC_PERM_DEFAULT)

cat("\n=== THE CONTROL: SAME SLICE, f_luc_perm = 0 vs 1 ===\n")
cat(sprintf("  %-8s %19s %19s\n", "stream", "f_luc_perm = 0", "f_luc_perm = 1"))
cat(sprintf("  %-8s %9s %9s %9s %9s\n", "", "beta", "q10", "beta", "q10"))
for (nm in c(names(WS_FAMILY), "total")) {
  i0 <- which.max(grid0[[nm]]); i1 <- which.max(grid[[nm]])
  cat(sprintf("  %-8s %9.2f %9.2f %9.2f %9.2f%s\n", nm,
              grid0$beta[i0], grid0$q10[i0], grid$beta[i1], grid$q10[i1],
              if (nm == "total") "   <-- what the sampler sees" else ""))
}
cat(sprintf("  mode_fit.rds, fitted on the f_luc_perm = 0 model: beta %.3f  q10 %.3f\n",
            pm_raw$beta, pm_raw$q10))

cat("\n=== EACH STREAM'S OWN OPTIMUM ON THIS GRID ===\n")
cat(sprintf("  %-8s %8s %8s %14s\n", "stream", "beta", "q10", "loglik"))
for (nm in c(names(WS_FAMILY), "total")) {
  i <- which.max(grid[[nm]])
  cat(sprintf("  %-8s %8.2f %8.2f %14.1f%s\n", nm, grid$beta[i], grid$q10[i],
              grid[[nm]][i], if (nm == "total") "   <-- what the sampler sees" else ""))
}

cat("\n=== THE d13C SURFACE IN q10, AT EACH STREAM'S PREFERRED beta ===\n")
cat("  (if d13C is what drives q10 down, its profile must fall monotonically\n")
cat("   in q10 while CO2's does not)\n")
for (nm in names(WS_FAMILY)) {
  bi <- grid$beta[which.max(grid[[nm]])]
  k  <- grid$beta == bi
  cat(sprintf("  %-8s beta %.2f | q10 %s\n", nm, bi,
              paste(sprintf("%6.1f", WS_Q10S), collapse = "")))
  cat(sprintf("  %-8s %9s | rel %s\n", "", "",
              paste(sprintf("%6.0f", grid[[nm]][k] - max(grid[[nm]][k])), collapse = "")))
}

cat("\n=== WHAT THE MODE'S PARAMETERS DO TO THE OBSERVED SINK ===\n")
gcbo <- as.data.frame(obs$gcb)
gsel <- gcbo$year >= 2015 & gcbo$year <= 2024
emis <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
luc_now <- mean(emis$luc_GtC[emis$year >= 2015 & emis$year <= 2024])
sink_at <- function(beta, q10, fp) {
  p <- pm; p$beta <- beta; p$q10 <- q10; p$f_luc_perm <- fp
  s <- ccx_spinup(p)
  o <- ccx_run_fast(s, ccx_build_forcing("historical", WS_YEARS, prod_c14 = s$prod_c14,
                    bomb_total_kmol = pm$bomb_total))$out
  yr <- floor(o$t + 1e-9)
  a  <- stats::aggregate(cbind(ocean_C, land_C) ~ yr, data = o, FUN = mean)
  a  <- a[order(a$yr), ]; k <- a$yr[-1] >= 2015 & a$yr[-1] <= 2024
  c(land = mean(diff(a$land_C)[k]) + luc_now, ocean = mean(diff(a$ocean_C)[k]))
}
cat(sprintf("  GCB 2015-2024      land sink %5.2f  ocean sink %5.2f GtC/yr\n",
            mean(gcbo$land_sink[gsel]), mean(gcbo$ocean_sink[gsel])))
for (lab in c("mode", "slice optimum")) {
  v <- if (lab == "mode") sink_at(pm_raw$beta, pm_raw$q10, 0) else sink_at(0.5, 1.5, 1)
  cat(sprintf("  %-18s land sink %5.2f  ocean sink %5.2f   (beta %.3f q10 %.3f, f_luc_perm %d)\n",
              lab, v[["land"]], v[["ocean"]],
              if (lab == "mode") pm_raw$beta else 0.5,
              if (lab == "mode") pm_raw$q10 else 1.5,
              if (lab == "mode") 0L else 1L))
}
cat("  Gross land sink = net land change + LUC, to match GCB's reporting (see\n")
cat("  diag_d13c_partition_refit.R's unit note).\n")

cat("\n=== WHAT IT COSTS TO PUT q10 AND beta SOMEWHERE DEFENSIBLE ===\n")
cat("  Cost in log-units of moving to beta 0.5 / q10 2.0, by stream:\n")
ref <- grid[which.max(grid$total), ]
tgt <- grid[grid$beta == 0.5 & grid$q10 == 2.0, ]
cat(sprintf("  %-8s %14s %14s %12s\n", "stream", "grid optimum", "beta .5 q10 2", "cost"))
for (nm in c(names(WS_FAMILY), "total"))
  cat(sprintf("  %-8s %14.1f %14.1f %12.1f\n", nm, ref[[nm]], tgt[[nm]],
              ref[[nm]] - tgt[[nm]]))

cat("\n  RESULT, AND IT OVERTURNS THE INHERITED ATTRIBUTION. d13C is NOT what\n")
cat("  drives q10 down: its surface is flat to ~3 log-units across the whole\n")
cat("  q10 range at the mode's own sigma_d13c of 0.44 permil, while CO2's falls\n")
cat("  3200. CO2 is the sharp stream in q10, and on the FIXED model CO2 wants\n")
cat("  q10 = 1.5 and beta = 0.50 -- both defensible.\n")
cat("  THE CONTROL IS WHAT MAKES THIS AN ATTRIBUTION: on the BUGGY model the\n")
cat("  same slice puts the total optimum at the grid CORNER (0.10, 0.20) --\n")
cat("  i.e. at or beyond the edge -- reproducing mode_fit.rds's (0.088, 0.169).\n")
cat("  The q10 inversion was the land-use regrowth bug forcing a compensating\n")
cat("  low-beta/low-q10 pair, not the d13C stream manufacturing land sink.\n")
cat("  BOUNDED, NOT SETTLED: the other 14 parameters are held at values that\n")
cat("  were themselves fitted to the bug, so this slice bounds the attribution.\n")
cat("  The refit decides it.\n")
