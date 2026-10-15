# =====================================================================
# diag_d13c_partition_refit.R -- does diag_d13c_suess.R [3]'s structural verdict
# survive the converted-land term?
#
# THE CLAIM UNDER TEST, and it is load-bearing. diag_d13c_suess.R [3] concluded:
# "closing the d13C bias needs a ~72 % land share (beta ~0.9) against GCB's
# 42 %, and it puts CO2 40 ppm high and the land sink at 4.7 GtC/yr against
# GCB's 2.4. d13C and CO2 CANNOT both be satisfied by any partition this model
# can reach." Everything downstream leans on it -- the sigma_d13c argument, the
# conveyor's motivation, the biological-pump case, and the reading that q10 ->
# 0.17 is the calibration manufacturing land sink to relieve d13C.
#
# WHY IT HAS TO BE RE-RUN. It was measured on the model that gave land-use
# carbon back to the land (98c1783). On that model the cumulative land
# 1750-2024 was +29.4 GtC where GCB says -57.4 -- a net SINK where the budget
# says net SOURCE. A verdict about whether the model can reach the observed
# PARTITION is exactly the verdict a partition bug invalidates.
#
# WRITTEN 2026-08-13, answering Marcus: "is there a path forward that is both
# scientifically justified and will improve the matches to observations?"
#
# A UNIT TRAP THIS FILE FIXES, and it did not exist before the converted-land
# term. diag_d13c_suess.R [3] compares mean(diff(land_C)) with GCB's
# `land_sink`. Those were nearly the same quantity while LUC was being regrown;
# they are NOT the same now. diff(land_C) is the NET land flux -- the residual
# sink MINUS land-use emissions -- while GCB's `land_sink` is the residual sink
# alone, reported beside `luc`. So the model's GROSS sink is diff(land_C) + LUC,
# and that is what the share is computed from here. Comparing net with gross
# would make the fixed model look ~1.2 GtC/yr short of GCB when it is not.
#
# RUNTIME ~40 s.
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
DP_YEARS    <- c(1750, 2024)
DP_WIN      <- c(2015, 2024)          # same window as diag_d13c_suess.R [3]
DP_BOMB_REF <- 102
DP_BETAS    <- c(0.2, 0.38, 0.5, 0.6, 0.75, 0.9, 1.2)
DP_ARMS     <- c(0, 1)                # f_luc_perm: the bug, then shipped

obs  <- ccx_prepare_obs()
gcb  <- as.data.frame(obs$gcb)
emis <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))

g  <- gcb$year >= DP_WIN[1] & gcb$year <= DP_WIN[2]
ge <- emis$year >= DP_WIN[1] & emis$year <= DP_WIN[2]
gcb_land  <- mean(gcb$land_sink[g])
gcb_ocean <- mean(gcb$ocean_sink[g])
gcb_luc   <- mean(gcb$luc[g])
mod_luc   <- mean(emis$luc_GtC[ge])   # what the MODEL is driven with

cat(sprintf("\nGCB %d-%d: land sink %.2f  ocean sink %.2f  (land share %.0f %%)  LUC %.2f GtC/yr\n",
            DP_WIN[1], DP_WIN[2], gcb_land, gcb_ocean,
            100 * gcb_land / (gcb_land + gcb_ocean), gcb_luc))
cat(sprintf("The model is driven with LUC = %.2f GtC/yr over the same window.\n", mod_luc))

# ---------------------------------------------------------------------
run_at <- function(fp, beta) {
  p <- ccx_default_params(); p$f_luc_perm <- fp; p$beta <- beta
  s <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", DP_YEARS, prod_c14 = s$prod_c14,
                         bomb_total_kmol = DP_BOMB_REF)
  out <- ccx_run_fast(s, F)$out
  ms  <- ccx_model_stats(out, obs)

  yr  <- floor(out$t + 1e-9)
  ann <- stats::aggregate(cbind(ocean_C, land_C) ~ yr, data = out, FUN = mean)
  ann <- ann[order(ann$yr), ]
  k   <- ann$yr[-1] >= DP_WIN[1] & ann$yr[-1] <= DP_WIN[2]
  net_land <- mean(diff(ann$land_C)[k])
  ocean    <- mean(diff(ann$ocean_C)[k])

  win <- function(o, m, col) {
    j  <- match(o$year, m$year)
    gg <- !is.na(j) & o$year >= DP_WIN[1] & o$year <= DP_WIN[2]
    mean(o[[col]][gg] - m$level[j[gg]])
  }
  c(gross_land = net_land + mod_luc, net_land = net_land, ocean = ocean,
    d13c = win(obs$d13_ann$MLO, ms$d13$MLO, "level"),
    co2  = win(obs$co2_ann$MLO, ms$co2$MLO, "level"))
}

for (fp in DP_ARMS) {
  cat(sprintf("\n=== f_luc_perm = %d %s ===\n", fp,
              if (fp == 0) "(the bug -- reproduces diag_d13c_suess [3])" else "(SHIPPED)"))
  cat(sprintf("  %-6s %10s %9s %8s %8s %11s %10s\n", "beta", "gross land",
              "net land", "ocean", "share", "d13C bias", "CO2 bias"))
  rows <- lapply(DP_BETAS, function(b) run_at(fp, b))
  for (i in seq_along(DP_BETAS)) {
    r <- rows[[i]]
    cat(sprintf("  %-6.2f %10.2f %9.2f %8.2f %7.0f %% %+11.3f %+9.2f\n",
                DP_BETAS[i], r[["gross_land"]], r[["net_land"]], r[["ocean"]],
                100 * r[["gross_land"]] / (r[["gross_land"]] + r[["ocean"]]),
                r[["d13c"]], r[["co2"]]))
  }
  # where each observable is satisfied, by linear interpolation on the grid
  cross <- function(v) {
    y <- vapply(rows, function(r) r[[v]], numeric(1))
    if (all(y > 0) || all(y < 0)) return(NA_real_)
    i <- which(diff(sign(y)) != 0)[1]
    DP_BETAS[i] + (DP_BETAS[i + 1] - DP_BETAS[i]) * (0 - y[i]) / (y[i + 1] - y[i])
  }
  b13 <- cross("d13c"); bco2 <- cross("co2")
  cat(sprintf("  beta that zeroes d13C: %s   beta that zeroes CO2: %s",
              if (is.na(b13)) "off grid" else sprintf("%.2f", b13),
              if (is.na(bco2)) "off grid" else sprintf("%.2f", bco2)))
  if (!is.na(b13) && !is.na(bco2))
    cat(sprintf("   -> gap %.2f (ratio %.2fx)", abs(b13 - bco2), max(b13, bco2) / min(b13, bco2)))
  cat("\n")
}

cat("\nREAD THE GAP, NOT THE LEVELS. The question diag_d13c_suess [3] asked is\n")
cat("whether ONE beta can satisfy both observables. The distance between the\n")
cat("two crossings is that answer, and it is the number the converted-land\n")
cat("term moves. Everything here is at the DEFAULT q10 and the default ocean,\n")
cat("so this is a 1-D slice and not a refit -- it bounds the verdict, it does\n")
cat("not replace the MCMC.\n")
