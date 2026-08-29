# =====================================================================
# diag_gamma_enso_profile.R -- IS THE ENSO AMPLITUDE A TUNING JOB OR A
#   STRUCTURE JOB?
#
# PRE-REGISTERED: notes/prereg_2026-08-29f_profile_gamma_enso.md, committed
# BEFORE this file existed. Gates copied unchanged.
#
# 08-29e: the model carries 33 % of the observed interannual CO2 growth-rate sd
# (0.301 vs 0.900 ppm/yr) at r = 0.571 -- right timing, wrong amplitude. The
# flux is LINEAR in gamma_enso (ccx_core.cpp:396-397), so closing the gap on
# ENSO alone needs gamma_enso ~ 3.05, 3.6x the fitted 0.85119. This asks what
# that costs and who refuses.
#
# ⚠ E6 IS THE ONE THAT MATTERS FOR THE TOOL: a larger amplitude at unchanged r
# makes the model LOUDER, not more RIGHT.
#
# Usage:  Rscript calibration/diag_gamma_enso_profile.R      # ~15 min
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

GE_YEARS  <- c(1750, 2024)
GE_WIN    <- c(1959, 2023)
GE_GRID   <- c(0, 0.4, 0.85119, 1.5, 2.0, 3.05, 4.0)
GE_SLICE  <- c("beta_max", "fert_k", "q10")     # E5's conditional carbon slice
GE_MAXIT  <- 1500; GE_RESTARTS <- 4; GE_RESTOL <- 0.05
# ---- gates, from prereg 29f sec.1
GE_OBS_SD   <- 0.8996        # measured 08-29e, GCB detrended growth-rate sd
GE_MODE_SD  <- 0.3006; GE_OFF_SD <- 0.1725; GE_MODE_R <- 0.571
GE_E1_LIN   <- 0.03
GE_E2_ARG   <- 0.4
GE_E3_CHEAP <- 20; GE_E3_PROHIB <- 100
GE_E4_SHARE <- 0.50
GE_TARGET_G <- 3.05
GE_LEVEL_ROWS <- c("co2_level_MLO", "co2_level_SPO")

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
md <- readRDS(ccx_mode_file()); ccx_adopt_mode_band(md); pv0 <- ccx_mode_params(md)
u0 <- md$u_mode; names(u0) <- CCX_PARAM_NAMES
i_g <- match("gamma_enso", CCX_PARAM_NAMES); i_s <- match(GE_SLICE, CCX_PARAM_NAMES)
stopifnot(!is.na(i_g), !anyNA(i_s), !(i_g %in% i_s))
cat(sprintf("gamma_enso at the mode %.5f | slice: %s\n", pv0$gamma_enso, paste(GE_SLICE, collapse=", ")))

obs_gcb <- as.data.frame(ccx_prepare_obs()$gcb)
run_of <- function(pv) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso; p$pump_mode <- md$pump_mode
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", GE_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  list(out = ccx_run_fast(sp, F)$out, F = F, sp = sp, pv = pv)
}
# growth-rate anomaly statistics, the SAME estimator on both sides
gr_stats <- function(r) {
  o <- as.data.frame(r$out); yr <- floor(o$t)
  ann <- tapply((o$co2_NH + o$co2_SH) / 2, yr, mean)
  y <- as.numeric(names(ann))
  d <- data.frame(year = y[-1], m = diff(as.numeric(ann)))
  d <- merge(d, obs_gcb[, c("year", "atm_growth")], by = "year")
  k <- d$year >= GE_WIN[1] & d$year <= GE_WIN[2]
  ma <- d$m - predict(lm(m ~ poly(year, 3), d[k, ]), d)
  oa <- d$atm_growth - predict(lm(atm_growth ~ poly(year, 3), d[k, ]), d)
  ev <- function(Y) { i <- which(d$year == Y); if (length(i)) ma[i] else NA }
  list(sd = sd(ma[k]), r = cor(ma[k], oa[k]), y1998 = ev(1998), y1992 = ev(1992),
       obs_sd = sd(oa[k]))
}
lp <- ccx_make_logpost(years = GE_YEARS,
        base_params = local({ b <- ccx_default_params(); b$pump_mode <- md$pump_mode; b }))
one <- lp(u0)
ll_of <- function(r) unlist(ccx_loglik(r$out, ccx_prepare_obs(),
  list(sigma_d14c = r$pv$sigma_d14c, rep_dC = r$pv$rep_dC,
       grad_off_co2 = r$pv$grad_off_co2, grad_off_d13c = r$pv$grad_off_d13c),
  luc = ccx_forcing_eluc_annual(r$F), deep = r$sp$diagnostics$d14c_bottom_box,
  ocean_grad = ccx_ocean_grad_scored(r$out, r$sp), by_stream = TRUE))

sep("1. THE FROZEN PROFILE")
cat(sprintf("  %9s %11s %8s %8s %8s %9s %9s\n",
            "gamma", "d logpost", "sd", "sd_ENSO", "r", "1998", "1992(Pin)"))
FR <- lapply(GE_GRID, function(g) {
  u <- u0; u[i_g] <- if (CCX_PARAM_TABLE$gamma_enso$tr == "log") log(max(g, 1e-8)) else g
  pv <- ccx_unc_to_par(u); pv$gamma_enso <- g          # exact, incl. g = 0
  r <- run_of(pv); s <- gr_stats(r)
  list(g = g, dlp = lp(u) - one, s = s, ll = ll_of(r)) })
off_sd <- FR[[1]]$s$sd
for (f in FR) {
  sdE <- suppressWarnings(sqrt(max(f$s$sd^2 - off_sd^2, 0)))
  cat(sprintf("  %9.4f %11.2f %8.4f %8.4f %8.3f %9.3f %9.3f%s\n", f$g, f$dlp, f$s$sd, sdE,
              f$s$r, f$s$y1998, f$s$y1992,
              if (abs(f$g - pv0$gamma_enso) < 1e-4) "   <- THE MODE" else
              if (abs(f$g - GE_TARGET_G) < 1e-4) "   <- closes the sd gap" else "")) }
cat(sprintf("\n  OBSERVED sd %.4f, and the model's non-ENSO baseline is %.4f\n",
            FR[[1]]$s$obs_sd, off_sd))
# E1 linearity of sd_ENSO in gamma
sdE <- vapply(FR, function(f) sqrt(max(f$s$sd^2 - off_sd^2, 0)), 0)
kk <- GE_GRID > 0
slope <- sdE[kk] / GE_GRID[kk]
E1 <- (max(slope) - min(slope)) / mean(slope) <= GE_E1_LIN
cat(sprintf("  E1  sd_ENSO/gamma spread %.2f %% (gate %.0f %%) -> %s\n",
            100 * (max(slope) - min(slope)) / mean(slope), 100 * GE_E1_LIN,
            if (E1) "PASS -- linear, as the flux is" else "FAIL -- the response SATURATES"))
gbest <- GE_GRID[which.max(vapply(FR, function(f) f$dlp, 0))]
E2 <- abs(gbest - pv0$gamma_enso) < GE_E2_ARG
cat(sprintf("  E2  frozen argmax gamma = %.4f vs the fitted %.5f -> %s\n", gbest, pv0$gamma_enso,
            if (E2) "PASS" else "⚠ FAIL -- the profile does NOT peak where the fit left it"))
ft <- FR[[which.min(abs(GE_GRID - GE_TARGET_G))]]
band <- if (abs(ft$dlp) <= GE_E3_CHEAP) "CHEAP" else
        if (abs(ft$dlp) <= GE_E3_PROHIB) "MODERATE" else "PROHIBITIVE"
cat(sprintf("  E3  closing the sd gap (gamma %.2f) costs %+.2f FROZEN -> **%s**\n",
            ft$g, ft$dlp, band))
lv <- sum(vapply(GE_LEVEL_ROWS, function(n) ft$ll[[n]] - FR[[3]]$ll[[n]], 0))
E4 <- lv / ft$dlp >= GE_E4_SHARE
cat(sprintf("  E4  the two co2_level rows carry %+.2f of %+.2f = %.0f %% (gate >= %.0f %%) -> %s\n",
            lv, ft$dlp, 100 * lv / ft$dlp, 100 * GE_E4_SHARE, if (E4) "PASS" else "FAIL"))
cat("\n  who refuses, at the gap-closing gamma (each row minus the mode):\n")
dd <- sort(vapply(names(ft$ll), function(n) ft$ll[[n]] - FR[[3]]$ll[[n]], 0))
for (n in names(dd)[abs(dd) > 1]) cat(sprintf("    %-22s %+10.2f\n", n, dd[[n]]))

sep("2. E5 -- CONDITIONAL: does a carbon slice buy it back?")
fit_arm <- function(objf, v0) {
  ftt <- optim(v0, objf, method = "Nelder-Mead", control = list(maxit = GE_MAXIT, reltol = 1e-12))
  v <- ftt$par; best <- ftt$value; n <- 0
  repeat { bf <- try(optim(v, objf, method = "BFGS", control = list(maxit = 200)), silent = TRUE)
    if (!inherits(bf, "try-error") && bf$value < best) { v <- bf$par; best <- bf$value }
    ftt <- optim(v, objf, method = "Nelder-Mead", control = list(maxit = GE_MAXIT, reltol = 1e-12))
    gg <- best - ftt$value; if (ftt$value < best) { v <- ftt$par; best <- ftt$value }
    n <- n + 1; if (gg < GE_RESTOL || n >= GE_RESTARTS) break }
  list(par = v, value = best)
}
cat(sprintf("  %9s %11s %11s %9s | %8s %8s\n", "gamma", "frozen", "conditional", "buy-back", "sd", "r"))
CO <- list()
for (g in c(0.85119, 2.0, GE_TARGET_G)) {
  ua <- u0; ua[i_g] <- if (CCX_PARAM_TABLE$gamma_enso$tr == "log") log(g) else g
  o1 <- fit_arm(function(v) { u <- ua; u[i_s] <- v; -lp(u) }, ua[i_s])
  u_h <- ua; u_h[i_s] <- o1$par; pv <- ccx_unc_to_par(u_h); pv$gamma_enso <- g
  s <- gr_stats(run_of(pv))
  fr <- FR[[which.min(abs(GE_GRID - g))]]$dlp
  CO[[sprintf("%.4f", g)]] <- list(g = g, cond = -o1$value - one, frozen = fr, s = s, pv = pv)
  cat(sprintf("  %9.4f %11.2f %11.2f %8.0f %% | %8.4f %8.3f\n", g, fr, -o1$value - one,
              if (fr != 0) 100 * (1 - (-o1$value - one) / fr) else NA, s$sd, s$r))
}

sep("3. E6 -- LOUDER, OR MORE RIGHT?")
cat(sprintf("  r at the mode %.3f | r at gamma %.2f %.3f | change %+.3f\n",
            FR[[3]]$s$r, ft$g, ft$s$r, ft$s$r - FR[[3]]$s$r))
cat(sprintf("  sd goes %.4f -> %.4f (obs %.4f)\n", FR[[3]]$s$sd, ft$s$sd, FR[[1]]$s$obs_sd))
cat(sprintf("\n  ⇒ %s\n", if (abs(ft$s$r - FR[[3]]$s$r) < 0.05)
  "AMPLITUDE ONLY: r is unchanged, so more ENSO makes the model LOUDER, NOT MORE RIGHT.\n     The missing variance is NOT ENSO amplitude." else
  "r MOVES with the amplitude -- the ENSO channel is carrying real signal that was suppressed."))

sep("4. SCORED")
cat(sprintf("  E1 %s | E2 %s | E3 %s | E4 %s\n", ifelse(E1,"PASS","FAIL"), ifelse(E2,"PASS","FAIL"),
            band, ifelse(E4,"PASS","FAIL")))
cat(sprintf("\n  ⇒ %s\n", if (band == "PROHIBITIVE")
  "STRUCTURE JOB: the likelihood refuses the amplitude the variability needs." else
  "TUNING JOB: the amplitude is affordable and the fit was simply never asked for it."))
cat("\n  ⚠ NOTHING ADOPTED. gamma_enso stays at 0.85119.\n")
saveRDS(list(grid = GE_GRID, frozen = FR, conditional = CO, off_sd = off_sd,
             verdicts = list(E1 = E1, E2 = E2, E3 = band, E4 = E4)),
        ccx_path("outputs", "diagnostics", "gamma_enso_profile.rds"))
cat("\n\n=== DONE ===\n")
