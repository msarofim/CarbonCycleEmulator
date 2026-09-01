# =====================================================================
# diag_price_gamma_diff.R -- WHAT DOES VOLCANIC DIFFUSE-LIGHT ACTUALLY COST?
#
# PRE-REGISTERED: notes/prereg_2026-08-29h_price_gamma_diff.md, committed BEFORE
# this file existed. Gates copied unchanged.
#
# 08-29g measured the FROZEN cost (-40.5 at gamma_diff 0.25). A frozen cost is
# an UPPER BOUND, not a price -- "the refit recovered 15-19x more than the frozen
# scan predicted" (handoff 08-25b sec.7). This asks what it costs with a carbon
# slice free.
#
# ⚠ `rep_dC` IS IN THE SLICE ON PURPOSE. 08-29g sec.4 proposed, untested, that
# the cost is a CUMULATIVE CO2 LEVEL OFFSET. rep_dC IS a CO2 level bias, so it
# either absorbs the cost (story right) or it does not (story refuted). H3 then
# checks that rep_dC ACTUALLY MOVED, so a passing H2 cannot be read as a
# mechanism when it is only an arithmetic.
#
# Usage:  Rscript calibration/diag_price_gamma_diff.R      # ~15 min
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

PG_YEARS <- c(1750, 2024)
PG_GRID  <- c(0, 0.125, 0.25, 0.50, 0.75, 0.97)
PG_SLICE <- c("beta_max", "fert_k", "q10", "rep_dC")
PG_MAXIT <- 1500; PG_RESTARTS <- 4; PG_RESTOL <- 0.05
PG_WIN   <- c(1959, 2023)
PG_SINK_WIN <- c(2015, 2023)
# ---- gates, from prereg 29h sec.2
PG_H0_TOL   <- 0.05
PG_H1_CHEAP <- 20; PG_H1_PROHIB <- 100
PG_H2_YES   <- 0.40; PG_H2_NO <- 0.15
PG_H3_SD    <- 1.0                    # rep_dC must move >= 1 prior-sd by 0.97
PG_H4_R0    <- 0.571                  # r at gamma_diff = 0
PG_H5_SINK  <- 0.10                   # GtC/yr
# ---- the FROZEN costs measured 08-29g, the comparison set. NOT recomputed.
PG_FROZEN <- c("0"=0, "0.125"=NA, "0.25"=-40.48, "0.5"=-160.78, "0.75"=-360.40, "0.97"=-601.26)

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
md <- readRDS(ccx_mode_file()); ccx_adopt_mode_band(md); pv0 <- ccx_mode_params(md)
u0 <- md$u_mode; names(u0) <- CCX_PARAM_NAMES
i_s <- match(PG_SLICE, CCX_PARAM_NAMES); stopifnot(!anyNA(i_s))
cat(sprintf("mode %s | slice: %s\n", basename(ccx_mode_file()), paste(PG_SLICE, collapse = ", ")))
cat(sprintf("rep_dC at the mode %.4f | beta_max %.4f | fert_k %.2f | q10 %.5f\n",
            pv0$rep_dC, pv0$beta_max, pv0$fert_k, pv0$q10))
# rep_dC's prior sd, for H3 -- DERIVED from its own prior, not asserted
rep_sd <- local({
  pf <- CCX_PARAM_TABLE$rep_dC$prior; tr <- CCX_PARAM_TABLE$rep_dC$tr
  x0 <- if (tr == "log") log(pv0$rep_dC) else pv0$rep_dC
  gr <- seq(x0 - 6, x0 + 6, length.out = 2001); v <- vapply(gr, pf, 0)
  w <- exp(v - max(v)); w <- w / sum(w)
  sqrt(sum(w * (gr - sum(w * gr))^2))
})
cat(sprintf("rep_dC prior sd (unconstrained, derived) %.4f\n", rep_sd))

obs_gcb <- as.data.frame(ccx_prepare_obs()$gcb)
lp_of <- local({ .c <- new.env(parent = emptyenv())
  function(gd) { k <- sprintf("%.6f", gd)
    if (is.null(.c[[k]])) { b <- ccx_default_params(); b$pump_mode <- md$pump_mode
      b$gamma_diff <- gd; .c[[k]] <- ccx_make_logpost(years = PG_YEARS, base_params = b) }
    .c[[k]] } })
one <- lp_of(0)(u0)
run_of <- function(pv, gd) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p <- ccx_set_enso(p, pv); p$pump_mode <- md$pump_mode; p$gamma_diff <- gd
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", PG_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  list(out = ccx_run_fast(sp, F)$out, F = F, sp = sp, pv = pv)
}
stats_of <- function(r) {
  o <- as.data.frame(r$out); yr <- floor(o$t)
  ann <- tapply((o$co2_NH + o$co2_SH) / 2, yr, mean); y <- as.numeric(names(ann))
  d <- data.frame(year = y[-1], m = diff(as.numeric(ann)))
  d <- merge(d, obs_gcb[, c("year", "atm_growth")], by = "year")
  k <- d$year >= PG_WIN[1] & d$year <= PG_WIN[2]
  ma <- d$m - predict(lm(m ~ poly(year, 3), d[k, ]), d)
  oa <- d$atm_growth - predict(lm(atm_growth ~ poly(year, 3), d[k, ]), d)
  # gate-7 sinks, dg_sinks()'s estimator
  tt <- o$t; n <- length(tt); yrs <- floor(tt[1]):floor(tt[n])
  bnd <- c(yrs, yrs[length(yrs)] + 1)
  stock <- function(v) { yv <- stats::approx(tt, v, xout = bnd)$y
    lo <- bnd < tt[1]; hi <- bnd > tt[n]
    if (any(lo)) yv[lo] <- v[1] + (bnd[lo]-tt[1])*(v[2]-v[1])/(tt[2]-tt[1])
    if (any(hi)) yv[hi] <- v[n] + (bnd[hi]-tt[n])*(v[n]-v[n-1])/(tt[n]-tt[n-1])
    diff(yv) }
  el <- ccx_forcing_eluc_annual(r$F)
  ks <- yrs >= PG_SINK_WIN[1] & yrs <= PG_SINK_WIN[2]
  list(sd = sd(ma[k]), r = cor(ma[k], oa[k]), y1992 = ma[d$year == 1992],
       land = mean((stock(o$land_C) + el$eluc[match(yrs, el$year)])[ks]),
       ll = unlist(ccx_loglik(r$out, ccx_prepare_obs(),
              list(sigma_d14c = r$pv$sigma_d14c, rep_dC = r$pv$rep_dC,
                   grad_off_co2 = r$pv$grad_off_co2, grad_off_d13c = r$pv$grad_off_d13c),
              luc = ccx_forcing_eluc_annual(r$F), deep = r$sp$diagnostics$d14c_bottom_box,
              ocean_grad = ccx_ocean_grad_scored(r$out, r$sp), by_stream = TRUE)))
}
fit_arm <- function(objf, v0) {
  ft <- optim(v0, objf, method = "Nelder-Mead", control = list(maxit = PG_MAXIT, reltol = 1e-12))
  v <- ft$par; best <- ft$value; n <- 0
  repeat { bf <- try(optim(v, objf, method = "BFGS", control = list(maxit = 200)), silent = TRUE)
    if (!inherits(bf, "try-error") && bf$value < best) { v <- bf$par; best <- bf$value }
    ft <- optim(v, objf, method = "Nelder-Mead", control = list(maxit = PG_MAXIT, reltol = 1e-12))
    g <- best - ft$value; if (ft$value < best) { v <- ft$par; best <- ft$value }
    n <- n + 1; if (g < PG_RESTOL || n >= PG_RESTARTS) break }
  list(par = v, value = best) }

sep("1. THE CONDITIONAL PROFILE")
cat(sprintf("  %8s %11s %11s %9s | %8s %7s %8s %8s %9s\n", "gamma_d", "frozen",
            "conditional", "buy-back", "1992", "r", "sd", "land", "rep_dC"))
R <- list()
for (gd in PG_GRID) {
  LP <- lp_of(gd)
  ft <- fit_arm(function(v) { u <- u0; u[i_s] <- v; -LP(u) }, u0[i_s])
  u_h <- u0; u_h[i_s] <- ft$par; pv <- ccx_unc_to_par(u_h)
  s <- stats_of(run_of(pv, gd))
  cond <- -ft$value - one
  fr <- PG_FROZEN[[sprintf("%g", gd)]]
  bb <- if (!is.na(fr) && fr != 0) 1 - cond / fr else NA
  R[[sprintf("%g", gd)]] <- list(gd = gd, cond = cond, frozen = fr, bb = bb, s = s, pv = pv,
                                 dz = (log(pv$rep_dC) - log(pv0$rep_dC)) / rep_sd)
  cat(sprintf("  %8.3f %11.2f %11.2f %8s | %8.3f %7.3f %8.4f %8.3f %9.4f\n", gd,
              ifelse(is.na(fr), NA, fr), cond,
              ifelse(is.na(bb), "--", sprintf("%.0f %%", 100 * bb)),
              s$y1992, s$r, s$sd, s$land, pv$rep_dC))
}
sep("2. SCORED")
H0 <- abs(R[["0"]]$cond) <= PG_H0_TOL
cat(sprintf("  H0  gamma_diff = 0 conditional = %+.4f (gate |.| <= %.2f) -> %s\n",
            R[["0"]]$cond, PG_H0_TOL, if (H0) "PASS" else "FAIL -- STOP"))
stopifnot(H0)
a <- R[["0.25"]]
band <- if (abs(a$cond) <= PG_H1_CHEAP) "CHEAP" else
        if (abs(a$cond) <= PG_H1_PROHIB) "MODERATE" else "PROHIBITIVE"
cat(sprintf("  H1  price at gamma_diff 0.25 = %+.2f -> **%s**\n", a$cond, band))
H2 <- if (a$bb >= PG_H2_YES) "LEVEL OFFSET CONFIRMED" else
      if (a$bb < PG_H2_NO) "LEVEL OFFSET REFUTED -- it is a SHAPE mismatch" else "INTERMEDIATE"
cat(sprintf("  H2  buy-back %.0f %% (>= %.0f confirms, < %.0f refutes) -> %s\n",
            100 * a$bb, 100 * PG_H2_YES, 100 * PG_H2_NO, H2))
z97 <- R[["0.97"]]$dz
H3 <- abs(z97) >= PG_H3_SD
cat(sprintf("  H3  rep_dC moved %.2f prior-sd by gamma_diff 0.97 (gate >= %.1f) -> %s\n",
            z97, PG_H3_SD, if (H3) "PASS -- rep_dC IS the absorber" else
            "⚠ FAIL -- rep_dC did NOT move; H2's number is arithmetic, not mechanism"))
rbest <- max(vapply(R, function(x) x$s$r, 0))
H4 <- rbest > PG_H4_R0
cat(sprintf("  H4  best conditional r = %.3f vs %.3f at gamma_diff 0 -> %s\n", rbest, PG_H4_R0,
            if (H4) "PASS -- the correlation gain SURVIVES refitting" else
            "⚠ FAIL -- the gain was borrowed from the frozen parameters"))
dl <- max(abs(vapply(R, function(x) x$s$land, 0) - R[["0"]]$s$land))
H5 <- dl < PG_H5_SINK
cat(sprintf("  H5  max |d land sink| = %.3f GtC/yr (gate < %.2f) -> %s\n", dl, PG_H5_SINK,
            if (H5) "PASS -- no secular land bias" else "⚠ FAIL -- a SECULAR land-uptake bias"))
cat("\n  H6  who pays at gamma_diff 0.25 (conditional, each row minus gamma_diff 0):\n")
dd <- sort(vapply(names(a$s$ll), function(n) a$s$ll[[n]] - R[["0"]]$s$ll[[n]], 0))
for (n in names(dd)[abs(dd) > 1]) cat(sprintf("    %-22s %+10.2f\n", n, dd[[n]]))
cat(sprintf("\n  ⇒ %s\n", if (band == "PROHIBITIVE")
  "THE MECHANISM IS UNAFFORDABLE AT TODAY'S OBJECTIVE." else
  sprintf("THE MECHANISM IS %s at gamma_diff 0.25.%s", band,
          if (H4) " And the correlation gain is REAL -- it survives refitting." else "")))
cat("\n  ⚠ NOTHING ADOPTED. gamma_diff stays 0; making it the 22nd FITTED parameter is a\n")
cat("    separate decision needing a full refit, not a conditional slice.\n")
saveRDS(list(grid = PG_GRID, slice = PG_SLICE, res = R, rep_sd = rep_sd,
             verdicts = list(H0=H0, H1=band, H2=H2, H3=H3, H4=H4, H5=H5)),
        ccx_path("outputs", "diagnostics", "price_gamma_diff.rds"))
cat("\n\n=== DONE ===\n")
