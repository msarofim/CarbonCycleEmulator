# =====================================================================
# GOODNESS OF FIT AT THE ADOPTED MODE, per stream, in OBSERVABLE UNITS.
#
# WHY THIS EXISTS. The only per-stream number the project has is the logL
# vector stored in mode_fit_pump{N,D}.rds, and **logL LEVEL IS NOT FIT**: it
# carries n and sigma, so a long stream with a tight sigma dominates the list
# without being the worst-fitting one. Ranking improvement work off that list
# ranks by leverage, not by misfit. This computes what "how well does it match"
# actually means: n, the RMS normalised residual (z), the mean z (BIAS, which
# is the part a structural error shows up in), and the residual in the
# stream's own physical units.
#
# THE GATE. Every stream is reconstructed from the same obs/model/sd the
# likelihood uses, and its logL is RECOMPUTED and checked against the value
# stored in the rds. If the reconstruction does not reproduce the stored logL
# to 1e-6, the residuals below are wrong and the row is marked. That check is
# the whole reason to trust this file.
#
# Usage:  Rscript calibration/diag_fit_at_mode.R [<mode name>]
#         mode names come from ccx_mode_file() (R/paths.R); default = canonical
# =====================================================================
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ARM REPOINTED 2026-08-27. "N"/"D" were the PRE-FIX pump arms; the 2026-08-25f
# seasonal-NEP isotope fix changed the objective and quarantined them, and
# ccx_mode_file() refuses those names with the reason.
ARM <- (function(a) if (length(a) && a[1] %in% names(CCX_MODE_FILES)) a[1]
        else CCX_MODE_CANONICAL)(commandArgs(TRUE))
M   <- ccx_load_mode(ARM)          # R/calibrate.R: carries gamma_enso, pump_mode,
pm  <- M$md$par_mode               # the 2 forcing params and the 4 likelihood ones
m   <- M$md

# THE seas_drivers/sst_obs ESCAPE HATCH WAS REMOVED 2026-08-22, and it had been
# WRONG since the 2026-08-20 refit. It read:
#     p_mode$sst_obs <- 0 ; p_mode$seas_drivers <- 0
# on the argument that "this mode was fitted under the pre-2026-08-18 seasonal
# SINE (its seas_amp/phase are in par_mode)". That was true of the 08-18 mode and
# false of the one on disk: mode_fit_pumpN.rds (08-21) carries the DRIVER
# parameters -- seas_T_amp_{NH,SH}, seas_lag_p, sst_seas_amp_{NH,SH}, npp_frac_NH
# -- and no sine knobs at all, so the hatch was running the diagnostic at a
# DIFFERENT MODEL from the fit it claimed to describe.
#
# Four more staleness defects were found with it, all on 2026-08-22, and all of
# them silent:
#   (A `gamma_enso` defect was ALSO claimed here on 2026-08-22 and WITHDRAWN the
#   same day: `gamma_enso` IS a field of ccx_default_params() and IS in
#   CCX_PARAM_NAMES, so intersect() picks it up and it was never dropped. The
#   six parameters intersect() really does drop are bomb_total, luc_scale,
#   sigma_d14c, rep_dC, grad_off_co2 and grad_off_d13c -- none of which have a
#   slot in ccx_default_params(). app/global.R's explicit gamma_enso line is
#   redundant on the mode path, not load-bearing.)
#   * `rep_dC` was never applied. The likelihood predicts the STATION as
#     `box - rep_dC` (R/likelihood.R, the LIK_REP_SOURCE_D13C block); this file
#     compared observations to the bare box, so both CO2 level streams showed a
#     -5.29 ppm "bias" that was just the 5.18 ppm offset, unmodelled.
#   * `sigma_d13c` was RETIRED 2026-08-18, so `pm$sigma_d13c` is NULL and
#     `sqrt(NULL^2 + REP^2)` is numeric(0): both d13C level rows silently
#     reported n = 0 and were dropped from every ranking this file prints.
#   * the ice term still read `co2_NH`, stale since `d6adb58`.
#
# AND THE GATE DID NOT STOP ANY OF IT. Every one of the 14 rows printed
# "MISMATCH" while the file went on to print its rankings, and memory
# `ccx_fit_at_mode` was written from those rankings. The gate is now FATAL at the
# end of the report -- see the stopifnot() there.

sp  <- ccx_spinup(M$p)
SF  <- ccx_scaled_forcing(sp, years = c(1750, 2024),
                          luc_scale = M$luc_scale, bomb_total = M$bomb_total)
F   <- SF$F
el  <- SF$eluc
r   <- ccx_run_fast(sp, F)
out <- r$out
obs <- ccx_prepare_obs()
err <- M$err                       # sigma_d14c, rep_dC, grad_off_co2, grad_off_d13c
ms  <- ccx_model_stats(out, obs)
interp <- function(col, tt) stats::approx(out$t, out[[col]], xout = tt, rule = 2)$y

# ---- collect (obs, model, sd) per stream, mirroring ccx_loglik ------
S <- list()
put <- function(nm, o, mo, sd, unit) S[[nm]] <<- list(o = o, m = mo, sd = sd, unit = unit)

for (st in c("MLO", "SPO")) {                                   # CO2 level
  o <- obs$co2_ann[[st]]; mm <- ms$co2[[st]]
  k <- match(o$year, mm$year); g <- !is.na(k)
  # station = box - rep_dC, mirroring R/likelihood.R. Omitting it reported the
  # 5.18 ppm offset as if it were model bias.
  put(paste0("co2_level_", st), o$level[g],
      mm$level[k[g]] - (if (is.null(err$rep_dC)) 0 else err$rep_dC),
      LIK_CO2_REP_ERR, "ppm")
}
for (st in c("MLO", "SPO")) {                                   # CO2 seasonal a,b
  o <- obs$co2_seas[[st]]; mm <- ms$co2_seas[[st]]
  k <- match(o$year, mm$year); g <- !is.na(k)
  put(paste0("co2_seasonal_", st), c(o$a[g], o$b[g]), c(mm$a[k[g]], mm$b[k[g]]),
      c(rep(o$sd_a, sum(g)), rep(o$sd_b, sum(g))), "ppm (harmonic a,b)")
}
# Law Dome is 66.7 S -> co2_SH. Was co2_NH here until 2026-08-22 (`d6adb58`).
put("co2_icecore", obs$ice$CO2ppm, interp("co2_SH", obs$ice$year), obs$ice$sd, "ppm")
for (st in c("MLO", "SPO")) {                                   # d13C level
  o <- obs$d13_ann[[st]]; mm <- ms$d13[[st]]
  k <- match(o$year, mm$year); g <- !is.na(k)
  # station = box - rep_dC * (LIK_REP_SOURCE_D13C - box) / CO2_box, on the
  # model's OWN state each year -- `rep_dC` is ONE offset serving BOTH species,
  # entering d13C through an isotopic mixing conversion rather than additively.
  # Omitted here until 2026-08-22, which is what made the d13C level rows read
  # as a +0.30 permil model bias; the fitted offset accounts for essentially all
  # of it, and memory `ccx_fit_at_mode`'s "d13C levels are pure BIAS" was written
  # off the unoffset version.
  pred <- mm$level[k[g]]
  if (!is.null(err$rep_dC) && err$rep_dC != 0) {
    cbox <- ms$co2[[st]]$level[match(o$year[g], ms$co2[[st]]$year)]
    pred <- pred - err$rep_dC * (LIK_REP_SOURCE_D13C - pred) / cbox
  }
  # `sigma_d13c` RETIRED 2026-08-18: absent from err => the objective's sd is
  # LIK_D13C_REP_ERR alone. The old sqrt(NULL^2 + REP^2) gave numeric(0) and both
  # rows silently reported n = 0.
  put(paste0("d13c_level_", st), o$level[g], pred, LIK_D13C_REP_ERR, "permil")
}
for (sp2 in list(list(nm="co2", og=obs$co2_grad, mod=ms$co2, off=err$grad_off_co2,
                      sd=LIK_GRAD_CO2_SD, u="ppm"),
                 list(nm="d13c", og=obs$d13c_grad, mod=ms$d13, off=err$grad_off_d13c,
                      sd=LIK_GRAD_D13C_SD, u="permil"))) {
  A <- sp2$mod$MLO; B <- sp2$mod$SPO
  mg <- A$level[match(sp2$og$year, A$year)] - B$level[match(sp2$og$year, B$year)]
  g <- is.finite(mg)
  put(paste0(sp2$nm, "_gradient"), sp2$og$grad[g], mg[g] + sp2$off, sp2$sd, sp2$u)
}
for (hh in c("NH", "SH")) {                                     # D14C
  o <- if (hh == "NH") obs$d14_nh_ann else obs$d14_sh_ann
  mm <- ms$d14[[hh]]; k <- match(o$year, mm$year); g <- !is.na(k)
  put(paste0("d14c_", hh), o$value[g], mm$mean[k[g]],
      sqrt(o$sd[g]^2 + err$sigma_d14c^2), "permil")
}
ic <- obs$intcal[obs$intcal$year >= 1750 & obs$intcal$year < 1950, ]
put("d14c_intcal", ic$d14c, interp("d14c_NH", ic$year + 0.5),
    sqrt(ic$err^2 + LIK_D14C_REP_OTHER^2), "permil")

# ---- GCB sinks: the DESIGN gate 7 pair, on the likelihood's own flux ----
local({
  bnd <- sort(unique(c(floor(min(out$t)), floor(obs$gcb$year), max(floor(obs$gcb$year)) + 1)))
  tt <- out$t; n <- length(tt)
  stock_at <- function(v) {
    y  <- stats::approx(tt, v, xout = bnd)$y
    lo <- bnd < tt[1]; hi <- bnd > tt[n]
    if (any(lo)) y[lo] <- v[1] + (bnd[lo]-tt[1])*(v[2]-v[1])/(tt[2]-tt[1])
    if (any(hi)) y[hi] <- v[n] + (bnd[hi]-tt[n])*(v[n]-v[n-1])/(tt[n]-tt[n-1])
    y
  }
  flux <- data.frame(year = utils::head(bnd, -1),
                     ocean = diff(stock_at(out$ocean_C)), land = diff(stock_at(out$land_C)))
  g <- merge(as.data.frame(obs$gcb)[, c("year","ocean_sink","land_sink")], flux, by = "year")
  g <- merge(g, el, by = "year")
  put("gcb_ocean_sink", g$ocean_sink, g$ocean, LIK_GCB_OCEAN_SD, "GtC/yr")
  put("gcb_land_sink",  g$land_sink,  g$land + g$eluc,
      LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE, "GtC/yr")
  # DESIGN gate 7 is stated on a DECADE MEAN, not the year-by-year scatter.
  #
  # THE WINDOW ENDS AT 2023 (Marcus, 2026-08-27). The run ends at 2024-12, so the
  # 2025 year boundary is half a month past the last model state, and that half
  # month lands entirely on 2024 -- at the point in the seasonal cycle where the
  # land stock's slope is most negative. It is worth 0.65 GtC/yr there and under
  # 0.001 everywhere else, which is what put this file 0.13 sigma from
  # diag_design_gates_at_mode.R. Both files now use FIT_SINK_WIN and both
  # recompute the target on it. Note the objective's OWN gcb_land_sink stream
  # still scores 2024 (R/likelihood.R:1419) and is unchanged by this: its 2024
  # row sits at z +0.86 against a 1959-2023 mean |z| of 0.64, i.e. 1.3x, so it is
  # not an outlier there and no refit is owed. This is a GATE window, not the
  # objective.
  FIT_SINK_WIN <- c(2015, 2023)
  w <- g$year >= FIT_SINK_WIN[1] & g$year <= FIT_SINK_WIN[2]
  cat(sprintf("\n--- DESIGN gate 7 (%d-%d mean sinks, GtC/yr; n = %d yr) ---\n",
              FIT_SINK_WIN[1], FIT_SINK_WIN[2], sum(w)))
  # SIGMAS FROM THE NAMED CONSTANTS, not literals. The land figure here was a
  # hardcoded 0.9 until 2026-08-22 -- LIK_GCB_LAND_SD's value BEFORE it was
  # changed to 0.5 on 2026-08-14. The stale literal turned DESIGN gate 7's land
  # miss from +2.0 sigma (FAIL) into +1.1 sigma (PASS), and memory
  # `ccx_fit_at_mode`'s "gate 7 PASSES" was written from it. Exactly the failure
  # the project's "labels derive from named constants" rule exists to prevent.
  cat(sprintf("  ocean: model %.2f vs GCB %.2f (target sd %.2f)  => %+.1f sigma\n",
              mean(g$ocean[w]), mean(g$ocean_sink[w]), LIK_GCB_OCEAN_SD,
              (mean(g$ocean[w]) - mean(g$ocean_sink[w]))/LIK_GCB_OCEAN_SD))
  cat(sprintf("  land : model %.2f vs GCB %.2f (target sd %.2f)  => %+.1f sigma\n",
              mean((g$land+g$eluc)[w]), mean(g$land_sink[w]), LIK_GCB_LAND_SD,
              (mean((g$land+g$eluc)[w]) - mean(g$land_sink[w]))/LIK_GCB_LAND_SD))
})

# ---- report, with the reconstruction gate ---------------------------
cat(sprintf("\n=== FIT AT THE %s MODE (canonical arm is %s) ===\n",
            toupper(ARM), CCX_MODE_CANONICAL))
cat("logL_rec vs logL_rds is the GATE: if it does not match, the row is wrong.\n\n")
cat(sprintf("%-18s %5s %7s %7s %7s   %10s %10s  %-16s %s\n",
            "stream", "n", "RMSz", "bias_z", "max|z|", "RMSresid", "bias", "unit", "gate"))
rows <- list(); bad <- character()
for (nm in names(S)) {
  s <- S[[nm]]; z <- (s$o - s$m) / s$sd
  z <- z[is.finite(z)]; res <- (s$o - s$m)[is.finite(s$o - s$m)]
  ll_rec <- sum(stats::dnorm(s$o, s$m, s$sd, log = TRUE), na.rm = TRUE)
  ll_rds <- m$streams[[nm]]
  gate <- if (is.null(ll_rds)) "absent in rds"
          else if (abs(ll_rec - ll_rds) < 1e-6) "OK"
          else sprintf("MISMATCH %.3f", ll_rec - ll_rds)
  cat(sprintf("%-18s %5d %7.2f %+7.2f %7.2f   %10.4g %+10.4g  %-16s %s\n",
              nm, length(z), sqrt(mean(z^2)), mean(z), max(abs(z)),
              sqrt(mean(res^2)), mean(res), s$unit, gate))
  rows[[nm]] <- c(n = length(z), rmsz = sqrt(mean(z^2)), bias = mean(z))
  if (!is.null(ll_rds) && abs(ll_rec - ll_rds) >= 1e-6) bad <<- c(bad, nm)
}
# THE GATE IS FATAL FROM 2026-08-22. It used to print "MISMATCH" in a column and
# carry on to the rankings below -- and on 2026-08-22 all 14 rows were
# mismatching while those rankings were being quoted into memory. A gate that
# does not stop anything is a label. NOTE the expected-mismatch case: the ice
# term moved to co2_SH in `d6adb58` AFTER these modes were fitted, so
# `co2_icecore` legitimately differs by ~+16.9 until the owed refit; it is named
# here rather than tolerated by a magnitude threshold, so a SECOND objective
# change cannot hide inside the allowance.
# EMPTY, AND THAT IS THE POINT. This list held two rows on the morning of
# 2026-08-22 -- `co2_icecore` (the `d6adb58` ice co2_NH -> co2_SH change) and
# `gcb_land_sink` (the luc_scale-SQUARED bug in the refit driver). Both were
# repaired that afternoon by calibration/repair_arm_streams.R, which recomputed
# the stored decomposition under the current objective, so all 14 streams now
# reproduce to 1e-6 and NOTHING should be tolerated. Add a name here only with a
# dated reason, and delete it the moment the owed refit clears it: an allowance
# that outlives its cause is how the next objective change hides.
STALE_BY_OBJECTIVE <- character(0)
unexpected <- setdiff(bad, STALE_BY_OBJECTIVE)
if (length(unexpected))
  stop("reconstruction does not reproduce the stored logL for: ",
       paste(unexpected, collapse = ", "),
       "\n  The residual columns above are WRONG for those rows. Fix the ",
       "reconstruction before reading anything below.")
if (length(bad))
  cat(sprintf("\n  GATE: %s mismatches as expected (objective changed in d6adb58);\n  every other stream reproduces its stored logL to 1e-6.\n",
              paste(bad, collapse = ", ")))
# ---- DOES THE FITTED SIGMA HAVE ANY SCATTER TO EXPLAIN? --------------
# A free error scale cannot tell BIAS from SCATTER: it inflates to cover either.
# So decompose the residual and compare the DE-BIASED scatter against the FIXED
# representation floor the stream already carries.  If the scatter sits below
# the floor, the fitted sigma is explaining no scatter at all and its entire
# value is bias absorption -- which is a structural misfit wearing an error bar.
cat("\n--- de-biased SCATTER vs the fixed representation floor ---\n")
cat(sprintf("%-18s %10s %10s %10s  %s\n", "stream", "RMSresid", "bias", "scatter", "vs fixed floor"))
for (nm in c("d13c_level_MLO","d13c_level_SPO","d14c_NH","d14c_SH")) {
  s2 <- S[[nm]]; res <- s2$o - s2$m; res <- res[is.finite(res)]
  sc <- stats::sd(res)
  floor_v <- if (grepl("d13c", nm)) LIK_D13C_REP_ERR else mean(s2$sd) # d14c sd is obs+sigma
  fitted_sig <- if (grepl("d13c", nm)) err$sigma_d13c else err$sigma_d14c
  cat(sprintf("%-18s %10.4f %+10.4f %10.4f  floor %.4f, fitted sigma %.4f -> %s\n",
      nm, sqrt(mean(res^2)), mean(res), sc, floor_v, fitted_sig,
      if (sc < floor_v) "SCATTER BELOW FLOOR (sigma explains nothing)" else "real scatter present"))
}
cat("\n  d14c obs sd (median of the observational sd column), NH / SH: ")
cat(sprintf("%.2f / %.2f permil\n",
    stats::median(obs$d14_nh_ann$sd, na.rm = TRUE), stats::median(obs$d14_sh_ann$sd, na.rm = TRUE)))

cat("\nStreams NOT reconstructed here (no simple obs-vs-model form):\n  ")
cat(paste(setdiff(names(m$streams), names(S)), collapse = ", "), "\n")
cat("\nRANKED BY RMS z (worst fit first) -- this is the ranking that means\n")
cat("'badly matched', as opposed to the logL list which ranks by leverage:\n")
R <- do.call(rbind, rows); R <- R[order(-R[, "rmsz"]), , drop = FALSE]
for (i in seq_len(nrow(R)))
  cat(sprintf("  %2d. %-18s RMSz %6.2f   bias %+6.2f   n %d\n",
              i, rownames(R)[i], R[i, "rmsz"], R[i, "bias"], R[i, "n"]))
