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
# Usage:  Rscript calibration/diag_fit_at_mode.R [N|D]
# =====================================================================
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)
ccx_load_cpp()

ARM <- (function(a) if (length(a) && a[1] %in% c("N", "D")) a[1] else "N")(commandArgs(TRUE))
m   <- readRDS(sprintf("calibration/output/pump_arms/mode_fit_pump%s.rds", ARM))
pm  <- m$par_mode

bp <- ccx_default_params(); bp$pump_mode <- ARM
p_mode <- bp
for (n in intersect(names(p_mode), CCX_PARAM_NAMES)) p_mode[[n]] <- pm[[n]]
p_mode$seas_drivers <- 0  # THE ESCAPE HATCH, load-bearing: this mode was
# fitted under the pre-2026-08-18 seasonal SINE (its seas_amp/phase are in
# par_mode); the drivers path would ignore them and substitute defaults. The
# rds-reproduction gate below is what catches this line going missing.


sp <- ccx_spinup(p_mode)
F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = 102)
F$c14_cosmo <- sp$prod_c14
F$c14_bomb  <- F$c14_bomb * (pm$bomb_total / 102)
for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
  F[[cc]] <- F[[cc]] * pm$luc_scale
attr(F, "luc_scale") <- pm$luc_scale
el <- ccx_forcing_eluc_annual(F); el$eluc <- el$eluc * pm$luc_scale
r   <- ccx_run_fast(sp, F)
out <- r$out
obs <- ccx_prepare_obs()
err <- list(sigma_d13c = pm$sigma_d13c, sigma_d14c = pm$sigma_d14c,
            grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c)
ms  <- ccx_model_stats(out, obs)
interp <- function(col, tt) stats::approx(out$t, out[[col]], xout = tt, rule = 2)$y

# ---- collect (obs, model, sd) per stream, mirroring ccx_loglik ------
S <- list()
put <- function(nm, o, mo, sd, unit) S[[nm]] <<- list(o = o, m = mo, sd = sd, unit = unit)

for (st in c("MLO", "SPO")) {                                   # CO2 level
  o <- obs$co2_ann[[st]]; mm <- ms$co2[[st]]
  k <- match(o$year, mm$year); g <- !is.na(k)
  put(paste0("co2_level_", st), o$level[g], mm$level[k[g]], LIK_CO2_REP_ERR, "ppm")
}
for (st in c("MLO", "SPO")) {                                   # CO2 seasonal a,b
  o <- obs$co2_seas[[st]]; mm <- ms$co2_seas[[st]]
  k <- match(o$year, mm$year); g <- !is.na(k)
  put(paste0("co2_seasonal_", st), c(o$a[g], o$b[g]), c(mm$a[k[g]], mm$b[k[g]]),
      c(rep(o$sd_a, sum(g)), rep(o$sd_b, sum(g))), "ppm (harmonic a,b)")
}
put("co2_icecore", obs$ice$CO2ppm, interp("co2_NH", obs$ice$year), obs$ice$sd, "ppm")
for (st in c("MLO", "SPO")) {                                   # d13C level
  o <- obs$d13_ann[[st]]; mm <- ms$d13[[st]]
  k <- match(o$year, mm$year); g <- !is.na(k)
  put(paste0("d13c_level_", st), o$level[g], mm$level[k[g]],
      sqrt(err$sigma_d13c^2 + LIK_D13C_REP_ERR^2), "permil")
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
  # DESIGN gate 7 is stated on the 2015-2024 MEAN, not the year-by-year scatter.
  w <- g$year >= 2015
  cat(sprintf("\n--- DESIGN gate 7 (2015-2024 mean sinks, GtC/yr) ---\n"))
  cat(sprintf("  ocean: model %.2f vs GCB %.2f (target sd 0.4)  => %+.1f sigma\n",
              mean(g$ocean[w]), mean(g$ocean_sink[w]),
              (mean(g$ocean[w]) - mean(g$ocean_sink[w]))/0.4))
  cat(sprintf("  land : model %.2f vs GCB %.2f (target sd 0.9)  => %+.1f sigma\n",
              mean((g$land+g$eluc)[w]), mean(g$land_sink[w]),
              (mean((g$land+g$eluc)[w]) - mean(g$land_sink[w]))/0.9))
})

# ---- report, with the reconstruction gate ---------------------------
cat(sprintf("\n=== FIT AT THE ARM-%s MODE (adopted arm is N) ===\n", ARM))
cat("logL_rec vs logL_rds is the GATE: if it does not match, the row is wrong.\n\n")
cat(sprintf("%-18s %5s %7s %7s %7s   %10s %10s  %-16s %s\n",
            "stream", "n", "RMSz", "bias_z", "max|z|", "RMSresid", "bias", "unit", "gate"))
rows <- list()
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
}
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
