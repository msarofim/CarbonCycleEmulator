# =====================================================================
# OFFLINE EMULATOR: can insolation + seasonal temperature REPLACE the
# prescribed seasonal-NEP sine? (Marcus 2026-08-18)
#
# THE QUESTION. The model's seasonal cycle is amp*sin(2pi(t-phase/12)) -- a
# description with 4 free parameters (amp/phase per hemisphere) and, being a
# single harmonic, structurally unable to produce the observed asymmetry of
# the cycle (MLO second harmonic 0.83 ppm, 28 % of the first). Marcus's
# proposal: drive it physically instead --
#   NPP(t)  follows INSOLATION (deterministic astronomy, zero data cost),
#   R_h(t)  follows SEASONAL LAND TEMPERATURE through the SAME q10 the
#           decadal carbon-climate feedback already uses.
# The sawtooth should then EMERGE: an exponential Q10 response to a
# sinusoidal temperature is not sinusoidal, and a light-driven growing
# season is not either.
#
# THE DISCIPLINE. Offline first (memory: offline_emulator) -- fit the driver
# model to the OBSERVED mean monthly cycle before touching model structure.
# The gate is not just RMS: the fitted NPP and R_h annual fluxes must come
# out PHYSICALLY PLAUSIBLE (tens of GtC/yr, not hundreds or fractions),
# because a shape-fit at absurd flux magnitudes is a curve dressed as physics.
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

# ---- 1. The observed target: mean monthly detrended cycle ----------
obs <- ccx_prepare_obs()
target <- function(st, y0 = 1995, y1 = 2024) {
  o <- obs$co2[obs$co2$station == st, ]
  o <- o[o$year >= y0 & o$year <= y1, ]
  h <- ccx_year_harmonic(o$decimal_date, o$co2_ppm)
  o$resid <- NA
  for (i in seq_len(nrow(h))) {
    k <- floor(o$decimal_date) == h$year[i]
    o$resid[k] <- o$co2_ppm[k] -
      (h$level[i] + h$trend[i] * (o$decimal_date[k] - (h$year[i] + 0.5)))
  }
  a <- aggregate(resid ~ month, o, mean)
  a$resid - mean(a$resid)
}
tgt_mlo <- target("MLO")

# ---- 2. Deterministic daily-mean TOA insolation at latitude phi ----
# Standard flat-sun formula; S0 cancels in the normalized shape.
insol_month <- function(phi_deg) {
  phi <- phi_deg * pi / 180
  d   <- (seq(15, 365, by = 30.4))[1:12]              # mid-month day-of-year
  dec <- -23.44 * pi / 180 * cos(2 * pi * (d + 10) / 365.25)
  h0  <- acos(pmin(pmax(-tan(phi) * tan(dec), -1), 1))
  (h0 * sin(phi) * sin(dec) + cos(phi) * cos(dec) * sin(h0)) / pi
}

# ---- 3. The driver model -------------------------------------------
# NPP shape: light above a compensation threshold, rectified --
#   n(t) ~ max(I(t) - c*max(I), 0), unit annual mean.
# R_h shape: q10^(T_seas/10), unit annual mean (Jensen renormalized), with
#   T_seas = A_T * sin(2pi(t - t_lag)) lagging insolation.
# CO2 cycle = -(1/M_hem) * integral(NPP_ann*(n-1) - R_ann*(r-1)) dt,
# integrated monthly, zero-mean. NPP_ann, R_ann solved by LINEAR least
# squares given the nonlinear knobs (phi, c, A_T, lag) -- so the physical
# magnitudes are OUTPUTS the data chooses, not inputs I assert.
M_HEM  <- 2.123 / 2                                    # GtC per ppm, one hemisphere
Q10    <- 2.2275                                       # the arm-N mode value, FIXED
mon    <- (seq_len(12) - 0.5) / 12

# PHENOLOGY LAG, added after the first two fits bracketed the physics: the
# unconstrained fit went MIRROR (it wanted the drawdown on the LAGGED shape and
# had only the temperature one to use), and the sign-constrained fit without a
# lag collapsed to RMS 1.68 with the cycle peaking in March -- both are the same
# message, that canopy carbon uptake lags insolation. Leaf area develops over
# weeks; peak LAI and peak NPP sit ~a month after peak light. So the NPP shape
# gets its own lag knob, interpolated on the mid-month insolation curve.
lag_shape <- function(v, lag_mo) {
  x <- (seq_len(12) - 0.5)
  stats::approx(c(x - 12, x, x + 12), rep(v, 3), xout = x - lag_mo)$y
}
shapes <- function(phi, cfrac, A_T, lag_T, lag_p) {
  I  <- lag_shape(insol_month(phi), lag_p)
  n  <- pmax(I - cfrac * max(I), 0); n <- n / mean(n)
  Tt <- A_T * sin(2 * pi * (mon - (3.5 + lag_T) / 12)) # lag_T = 0 -> T peaks Jul
  r  <- Q10^(Tt / 10); r <- r / mean(r)
  list(n = n, r = r)
}
cyc_of <- function(flux) {                              # GtC/yr monthly -> ppm cycle
  x <- cumsum(flux / 12) / M_HEM
  x - mean(x)
}
fit_at <- function(phi, cfrac, A_T, lag_T, lag_p, tgt) {
  s <- shapes(phi, cfrac, A_T, lag_T, lag_p)
  # columns: response to 1 GtC/yr of seasonal NPP; of seasonal R_h
  Xn <- cyc_of(-(s$n - 1)); Xr <- cyc_of(s$r - 1)
  X  <- cbind(Xn, Xr)
  # SIGN-CONSTRAINED least squares, and the constraint is physics, not taste:
  # NPP_ann and R_ann are gross annual fluxes, so both are >= 0. The first
  # (unconstrained) run of this script found the MIRROR solution -- both
  # coefficients negative, i.e. "photosynthesis" wearing the respiration shape
  # and vice versa, with knobs pinned at grid edges and the T peak LEADING
  # insolation. RMS 0.243, shape right, physics inside out: exactly the failure
  # mode the plausibility gate exists to catch. For 2 parameters, constrained
  # LS is exact by case analysis: unconstrained solution if feasible, else the
  # best single-column fit with the other at zero.
  cf <- tryCatch(qr.solve(X, tgt), error = function(e) c(NA, NA))
  if (any(is.na(cf))) return(list(npp = NA, rh = NA, rms = NA, fit = NULL))
  if (any(cf < 0)) {
    c1 <- max(0, sum(Xn * tgt) / sum(Xn^2))   # rh = 0
    c2 <- max(0, sum(Xr * tgt) / sum(Xr^2))   # npp = 0
    r1 <- sqrt(mean((tgt - Xn * c1)^2)); r2 <- sqrt(mean((tgt - Xr * c2)^2))
    cf <- if (r1 <= r2) c(c1, 0) else c(0, c2)
  }
  res <- tgt - X %*% cf
  list(npp = cf[1], rh = cf[2], rms = sqrt(mean(res^2)),
       fit = as.vector(X %*% cf))
}

# ---- 4. Grid over the nonlinear knobs ------------------------------
grid <- expand.grid(phi = seq(35, 70, 5), cfrac = seq(0, 0.6, 0.1),
                    A_T = seq(2, 20, 2), lag = seq(0, 2, 0.5),
                    lag_p = seq(0, 2, 0.25))
best <- NULL
for (i in seq_len(nrow(grid))) {
  g <- grid[i, ]
  f <- fit_at(g$phi, g$cfrac, g$A_T, g$lag, g$lag_p, tgt_mlo)
  if (!is.na(f$rms) && (is.null(best) || f$rms < best$rms))
    best <- c(as.list(g), f)
}

cat("=== OFFLINE DRIVER MODEL vs OBSERVED MLO MEAN CYCLE (1995-2024) ===\n\n")
cat(sprintf("baselines: 1-harmonic RMS 0.608 ppm | 2-harmonic RMS 0.217 ppm (4 resp. 6 dof)\n\n"))
cat(sprintf("best driver fit: RMS %.3f ppm with %d nonlinear knobs + 2 linear fluxes\n",
            best$rms, 5))
cat(sprintf("  phi_eff %.0f degN | light thresh %.0f %% | A_T %.1f K | T lag %+.1f mo | phenology lag %+.2f mo\n",
            best$phi, 100 * best$cfrac, best$A_T, best$lag, best$lag_p))
cat(sprintf("  FITTED FLUXES (the plausibility gate): seasonal NPP %.1f GtC/yr, R_h %.1f GtC/yr\n",
            best$npp, best$rh))
cat("  [NH NPP ~ 35-40 GtC/yr in this model (npp_frac_NH 0.64 of ~60); R_h comparable.\n")
cat("   Fluxes far outside tens of GtC/yr = shape-fit dressed as physics.]\n\n")

# harmonic content of the fitted curve -- does the SAWTOOTH emerge?
h_of <- function(v) {
  X <- cbind(sin(2*pi*mon), cos(2*pi*mon), sin(4*pi*mon), cos(4*pi*mon))
  cf <- qr.solve(X, v)
  c(amp1 = sqrt(sum(cf[1:2]^2)), amp2 = sqrt(sum(cf[3:4]^2)))
}
ho <- h_of(tgt_mlo); hf <- h_of(best$fit)
cat(sprintf("harmonic content   amp1     amp2    amp2/amp1\n"))
cat(sprintf("  observed        %.3f    %.3f     %.2f\n", ho[1], ho[2], ho[2]/ho[1]))
cat(sprintf("  driver model    %.3f    %.3f     %.2f   <- EMERGED, not fitted\n",
            hf[1], hf[2], hf[2]/hf[1]))

cat("\nmonth-by-month (ppm):\n  obs:   ", paste(sprintf("%+.2f", tgt_mlo), collapse = " "),
    "\n  model: ", paste(sprintf("%+.2f", best$fit), collapse = " "), "\n")

# ---- 5. THE DECISIVE VERSION: fluxes PINNED to the model's own ------
# In the real wiring NPP_ann and R_ann are not free -- they are the model's own
# NPP (npp0_NH = 36 GtC/yr at spinup, respiration balancing it annually). So
# the honest feasibility test fixes BOTH at 36 and asks whether the SHAPE knobs
# alone can reproduce the observed cycle, amplitude included. This also
# dissolves the R_ann*A_T degeneracy the free fit fell into (at small A_T only
# the product is identified, which is how it "chose" R_h = 142 GtC/yr).
NPP_NH <- 36
pinned <- NULL
for (i in seq_len(nrow(grid))) {
  g <- grid[i, ]
  sh <- shapes(g$phi, g$cfrac, g$A_T, g$lag, g$lag_p)
  fit <- cyc_of(-NPP_NH * (sh$n - 1) + NPP_NH * (sh$r - 1))
  rms <- sqrt(mean((tgt_mlo - fit)^2))
  if (is.null(pinned) || rms < pinned$rms)
    pinned <- c(as.list(g), list(rms = rms, fit = fit))
}
cat(sprintf("\n=== FLUXES PINNED AT THE MODEL'S OWN (NPP = R = %g GtC/yr NH) ===\n", NPP_NH))
cat(sprintf("best: RMS %.3f ppm, 5 shape knobs, ZERO free fluxes\n", pinned$rms))
cat(sprintf("  phi_eff %.0f degN | light thresh %.0f %% | A_T %.1f K | T lag %+.1f mo | phenology lag %+.2f mo\n",
            pinned$phi, 100 * pinned$cfrac, pinned$A_T, pinned$lag, pinned$lag_p))
hp <- h_of(pinned$fit)
cat(sprintf("  harmonics: amp1 %.3f (obs %.3f)  amp2 %.3f (obs %.3f)  ratio %.2f (obs %.2f)\n",
            hp[1], ho[1], hp[2], ho[2], hp[2]/hp[1], ho[2]/ho[1]))
cat("  month-by-month (ppm):\n   obs:   ", paste(sprintf("%+.2f", tgt_mlo), collapse = " "),
    "\n   model: ", paste(sprintf("%+.2f", pinned$fit), collapse = " "), "\n")

# ---- 5b. And with the threshold OFF (pure linear light) -------------
noc <- NULL
for (i in seq_len(nrow(grid[grid$cfrac == 0, ]))) {
  g <- grid[grid$cfrac == 0, ][i, ]
  f <- fit_at(g$phi, 0, g$A_T, g$lag, g$lag_p, tgt_mlo)
  if (!is.na(f$rms) && (is.null(noc) || f$rms < noc$rms)) noc <- c(as.list(g), f)
}
cat(sprintf("\nablation -- pure linear light (no growing-season threshold): RMS %.3f ppm\n", noc$rms))
cat(sprintf("  (vs %.3f with the threshold: the threshold's contribution to the shape)\n", best$rms))
