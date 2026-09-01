# =====================================================================
# diag_excess_c14.R -- everything behind the ocean excess-14C constraint.
#
# Reproduces, in one run, the four measurements that R/likelihood.R design
# note 5 cites, plus the 14C budget-closure test that found the land-use-change
# leak. Nothing here is a likelihood term; this is the evidence the term's
# definition rests on, kept runnable so it can be re-checked after any change to
# the land, the ocean, or the bomb source.
#
#   [1] WHICH NATURAL BASELINE?  the 1750 spinup state versus a full
#       no-fossil / no-LUC / no-bomb / no-nuclear counterfactual.
#   [2] BUDGET CLOSURE.          excess 14C can only come from the prescribed
#       sources minus decay. It does not: land-use-change emissions inject 14C
#       ex nihilo, because they are an external source carried at the
#       VEGETATION box's own 14C ratio while the vegetation box is not debited.
#   [3] BOMB-ONLY vs TOTAL.      Naegler & Levin's model partition sums exactly
#       to their cumulative bomb input, i.e. it is a paired difference; their
#       OBSERVATIONS are total-minus-natural. Does the choice matter?
#   [4] UNITS CROSS-CHECK.       rebuild the ATMOSPHERIC excess from the CO2 and
#       D14C observations alone and compare to N&L's observed troposphere. This
#       is the only row where their number and ours meet with no model between
#       them, so it is what calibrates LIK_EXCESS_C14_REP_FRAC.
#
# Run from the repo root:  Rscript calibration/diag_excess_c14.R
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants (every label below derives from these) ----------
DIAG_YEARS      <- c(1750, 2024)
DIAG_REF_YEARS  <- c(1975, 1995)     # GEOSECS and WOCE reference years
DIAG_MODE_FILE  <- file.path("calibration", "output", "mode_fit.rds")
DIAG_MODE_ALT   <- file.path("calibration", "output", "quarantine",
                             "20260811b_pre_excess_c14", "mode_fit.rds")
DIAG_BOMB_ALT   <- 102               # kmol, the citable Naegler & Levin total
DIAG_MOUCHET_UPLIFT <- 1.20          # Mouchet 2013: the observational excess
                                     # carries ~10% CO2 increase + ~10% air-sea
                                     # flux on top of the bomb inventory

# ---- parameters: the current mode if there is one --------------------
mode_fit <- if (file.exists(DIAG_MODE_FILE)) readRDS(DIAG_MODE_FILE) else
            if (file.exists(DIAG_MODE_ALT))  readRDS(DIAG_MODE_ALT)  else NULL
p <- ccx_default_params()
if (!is.null(mode_fit)) {
  for (n in intersect(names(p), names(mode_fit$par_mode))) p[[n]] <- mode_fit$par_mode[[n]]
  p <- ccx_set_enso(p, mode_fit$par_mode)
  cat(sprintf("parameters: mode fit, bomb_total %.1f kmol\n", mode_fit$par_mode$bomb_total))
} else {
  p <- ccx_set_enso(p, list(gamma_enso = 0))
  cat("parameters: ccx_default_params() -- NO mode fit found\n")
}
BOMB_FIT <- if (!is.null(mode_fit)) mode_fit$par_mode$bomb_total else DIAG_BOMB_ALT

sp <- ccx_spinup(p)
cat(sprintf("spinup: prod_c14 %.1f mol/yr, ocean C %.0f GtC, deep D14C %+.1f permil\n\n",
            sp$prod_c14, sp$diagnostics$ocean_C_GtC, sp$diagnostics$d14c_deep_ocean))

RES <- c("ocean", "land", "atm")
inv_kmol <- function(o, i) c(ocean = ccx_c14_kmol(o$ocean_C14[i]),
                             land  = ccx_c14_kmol(o$land_C14[i]),
                             atm   = ccx_c14_kmol(o$atm_C14[i]))
run <- function(F) ccx_run_fast(sp, F)$out
row_at <- function(o, y) which(floor(o$t + 1e-9) == y)[1]

mk_forcing <- function(bomb_total) ccx_build_forcing(
  "historical", DIAG_YEARS, prod_c14 = sp$prod_c14, bomb_total_kmol = bomb_total)

# =====================================================================
# [1] Which natural baseline?
# =====================================================================
cat("=== [1] the natural baseline: 1750 steady state vs a counterfactual ===\n")
F  <- mk_forcing(BOMB_FIT)
o_full <- run(F)
F_nat <- F
F_nat$e_foss_NH <- 0; F_nat$e_foss_SH <- 0
F_nat$e_luc_NH  <- 0; F_nat$e_luc_SH  <- 0
F_nat$c14_bomb  <- 0; F_nat$c14_nuclear <- 0
o_natB <- run(F_nat)
F_natC <- ccx_hold_climate(F_nat, value = 0)
o_natC <- run(F_natC)

natA <- inv_kmol(o_full, 1)          # the run's own first row = the spinup state
cat(sprintf("  natural A (1750 steady state): ocean %.2f  land %.2f  atm %.2f kmol\n",
            natA["ocean"], natA["land"], natA["atm"]))
for (y in DIAG_REF_YEARS) {
  i <- row_at(o_full, y)
  a <- inv_kmol(o_full, i); b <- inv_kmol(o_natB, i); cc <- inv_kmol(o_natC, i)
  cat(sprintf("  %d ocean excess:  vs A %6.2f   vs B %6.2f   vs C %6.2f   (A-B %+.3f, A-C %+.3f)\n",
              y, a["ocean"] - natA["ocean"], a["ocean"] - b["ocean"],
              a["ocean"] - cc["ocean"], natA["ocean"] - b["ocean"],
              natA["ocean"] - cc["ocean"]))
}
cat("  -> B is the expensive definition (a second full run per likelihood call);\n")
cat("     A is free, and C confirms A is the zero-forcing fixed point.\n\n")

# =====================================================================
# [2] Budget closure -- the land-use-change 14C leak
# =====================================================================
# Excess E obeys  dE/dt = bomb + nuclear + (any other input) - lambda*E,
# so any input the model does not declare shows up as
#     leak(t) = E(t) - int(bomb + nuclear) + lambda * int(E).
# That is a derivation, not an assumption: it needs no knowledge of where the
# extra 14C comes from, only that 14C decays.
cat("=== [2] budget closure: does the excess match the declared sources? ===\n")
dt   <- 1 / 12
Etot <- ccx_c14_kmol(o_full$ocean_C14 + o_full$land_C14 + o_full$atm_C14)
Etot <- Etot - Etot[1]
src_cum   <- cumsum(F$c14_bomb + F$c14_nuclear) * dt / 1000      # mol/yr -> kmol
decay_cum <- cumsum(Etot) * dt * ccx_const("LAMBDA_C14")
leak      <- Etot - src_cum + decay_cum
for (y in DIAG_REF_YEARS) {
  i <- row_at(o_full, y)
  cat(sprintf("  %d  excess %7.2f = declared %7.2f - decay %.2f + UNDECLARED %6.2f kmol (%.1f %% of the excess)\n",
              y, Etot[i], src_cum[i], decay_cum[i], leak[i], 100 * leak[i] / Etot[i]))
}
luc_cum <- cumsum(F$e_luc_NH + F$e_luc_SH) * dt
cat(sprintf("  cumulative LUC carbon to %d: %.0f GtC; land D14C there %+.1f permil\n",
            max(DIAG_REF_YEARS), luc_cum[row_at(o_full, max(DIAG_REF_YEARS))],
            1000 * (o_full$land_C14[row_at(o_full, max(DIAG_REF_YEARS))] /
                      o_full$land_C[row_at(o_full, max(DIAG_REF_YEARS))] - 1)))
cat("  -> LUC is emitted by add_source() at the VEGETATION box's own 14C ratio\n")
cat("     while the vegetation box is NOT debited, so it is a 14C source. Fossil\n")
cat("     carbon is emitted at D14C = -1000 and correctly carries none.\n\n")

# =====================================================================
# [3] Bomb-only (paired) vs total-minus-natural
# =====================================================================
cat("=== [3] paired bomb-only vs total-minus-natural, per reservoir ===\n")
for (BT in c(BOMB_FIT, DIAG_BOMB_ALT)) {
  Fb  <- mk_forcing(BT)
  Fnb <- Fb; Fnb$c14_bomb <- 0; Fnb$c14_nuclear <- 0
  ob  <- run(Fb); onb <- run(Fnb)
  cat(sprintf("  bomb_total = %.1f kmol\n", BT))
  for (y in DIAG_REF_YEARS) {
    i <- row_at(ob, y)
    a <- inv_kmol(ob, i); b <- inv_kmol(onb, i); n0 <- inv_kmol(ob, 1)
    Et <- a - n0; Eb <- a - b
    cat(sprintf("    %d  ocean %6.2f / %6.2f   land %6.2f / %6.2f   atm %6.2f / %6.2f  (total / bomb-only)\n",
                y, Et["ocean"], Eb["ocean"], Et["land"], Eb["land"], Et["atm"], Eb["atm"]))
    cat(sprintf("          SUM %6.2f / %6.2f  -- bomb-only must not exceed the input %.1f\n",
                sum(Et), sum(Eb), BT))
    cat(sprintf("          ocean bomb-only x %.2f (Mouchet Suess/invasion allowance) = %6.2f\n",
                DIAG_MOUCHET_UPLIFT, DIAG_MOUCHET_UPLIFT * Eb["ocean"]))
  }
}
cat("\n")

# =====================================================================
# [4] Units cross-check against the one observed N&L row
# =====================================================================
cat("=== [4] atmospheric excess rebuilt from observations alone ===\n")
GTC_PER_PPM <- ccx_const("GtC_PER_PPM")
nat_atm <- ccx_c14_kmol(ccx_const("CO2_PI_PPM") * GTC_PER_PPM *
                          (1 + ccx_const("D14C_PI") / 1000))

co2 <- as.data.frame(readRDS(ccx_path("data", "obs_co2_monthly.rds")))
co2 <- co2[co2$station %in% c("MLO", "SPO"), ]
co2$yr <- floor(co2$decimal_date)
co2_ann <- stats::aggregate(co2_ppm ~ yr + station, data = co2, FUN = mean)

w   <- ccx_zone_weights()
d14 <- as.data.frame(readRDS(ccx_path("data", "obs_d14c_zonal.rds")))
hemi <- function(wts) {
  sub  <- d14[d14$zone %in% names(wts), c("decimal_date", "zone", "d14c")]
  wide <- reshape(sub, idvar = "decimal_date", timevar = "zone", direction = "wide")
  vc   <- paste0("d14c.", names(wts))
  wide <- wide[stats::complete.cases(wide[, vc]), ]
  stats::aggregate(d14c ~ yr,
                   data = data.frame(yr = floor(wide$decimal_date),
                                     d14c = as.vector(as.matrix(wide[, vc]) %*% wts)),
                   FUN = mean)
}
nh <- hemi(w$NH); sh <- hemi(w$SH)

nl <- readRDS(ccx_path("data", "obs_excess_c14.rds"))$all
nl_row <- function(src, q, y) nl$kmol_14c[nl$source == src & nl$quantity == q & nl$year == y]
for (y in DIAG_REF_YEARS) {
  cN <- co2_ann$co2_ppm[co2_ann$yr == y & co2_ann$station == "MLO"]
  cS <- co2_ann$co2_ppm[co2_ann$yr == y & co2_ann$station == "SPO"]
  dN <- nh$d14c[nh$yr == y]; dS <- sh$d14c[sh$yr == y]
  obs_atm <- ccx_c14_kmol((cN * GTC_PER_PPM / 2) * (1 + dN / 1000) +
                            (cS * GTC_PER_PPM / 2) * (1 + dS / 1000)) - nat_atm
  nl_trop  <- nl_row("naegler_levin_2006_t4_OBS",  "troposphere",  y)
  nl_strat <- nl_row("naegler_levin_2006_t4_YANG", "stratosphere", y)
  cat(sprintf("  %d  obs-derived atmosphere %6.2f  vs N&L troposphere(obs) %.1f + stratosphere(model) %.1f = %.1f  -> %+.1f %%\n",
              y, obs_atm, nl_trop, nl_strat, nl_trop + nl_strat,
              100 * (obs_atm / (nl_trop + nl_strat) - 1)))
}
cat(sprintf("  -> LIK_EXCESS_C14_REP_FRAC = %.2f is set to cover this spread.\n",
            LIK_EXCESS_C14_REP_FRAC))

# =====================================================================
# [5] What the likelihood term actually scores
# =====================================================================
cat("\n=== [5] the term, at each bomb_total ===\n")
obs <- ccx_prepare_obs()
e   <- obs$excess_c14
cat(sprintf("  target set '%s': %s\n", e$target,
            paste(sprintf("%d %.1f +/- %.1f", e$year, e$centre, e$half_width),
                  collapse = "   ")))
err <- list(sigma_co2 = if (!is.null(mode_fit)) mode_fit$par_mode$sigma_co2 else 1.5,
            sigma_d13c = if (!is.null(mode_fit)) mode_fit$par_mode$sigma_d13c else 0.1,
            sigma_d14c = if (!is.null(mode_fit)) mode_fit$par_mode$sigma_d14c else 5)
for (BT in c(BOMB_FIT, DIAG_BOMB_ALT)) {
  o <- run(mk_forcing(BT))
  mod <- vapply(e$year, function(y) {
    yv <- floor(o$t + 1e-9)
    ccx_c14_kmol(mean(o$ocean_C14[yv == y]) - o$ocean_C14[1])
  }, numeric(1))
  parts <- ccx_loglik(o, obs, err, by_stream = TRUE)
  cat(sprintf("  bomb_total %6.1f -> ocean excess %6.2f / %6.2f kmol; term %8.2f log-units\n",
              BT, mod[1], mod[2], parts[["excess_c14_ocean"]]))
}
