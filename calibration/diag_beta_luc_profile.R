# =====================================================================
# diag_beta_luc_profile.R -- does the objective USE the land-use input
# uncertainty, or does beta still absorb it?
#
# THE PRE-REGISTERED PREDICTION (review 2026-08-14 sec.3.3, written before this
# ran): with `luc_scale` free, BETA FALLS TO 0.40-0.55 AND luc_scale SETTLES AT
# 0.6-0.8, because the CO2 stream's ~1,565 log-units will take the cheaper of
# two ways to close the same ~30 ppm gap and the land-use route costs no gate.
# It is written here so it can be wrong.
#
# WHY THIS IS A REAL TEST AND NOT A TAUTOLOGY. `luc_scale` carries a PRIOR
# (lognormal, median 1, sdlog 0.28, two independent receipts in
# CCX_PARAM_TABLE), so the objective has to pay for moving it. If the prior
# outweighs the CO2 gain, luc_scale stays near 1 and beta stays high -- which
# would say the 30 ppm is NOT an input error and the review's sec.3 is wrong.
#
# PROFILED THROUGH ccx_make_logpost() DELIBERATELY, not through a hand-built
# likelihood: that is the actual objective the MCMC will optimize, priors and
# Jacobians included, so a slice cannot flatter itself by omitting a term.
#
# WHAT IT IS NOT. A 2-D slice at fixed everything-else is not a refit; its
# optima are grid-coarse and conditional on the other 15 parameters sitting at
# their inits. It bounds the answer; the MCMC decides it.
#
# RUNTIME ~4 min.
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

BL_YEARS  <- c(1750, 2024)
BL_BETAS  <- seq(0.30, 0.90, by = 0.05)
BL_SCALES <- c(0.50, 0.60, 0.70, 0.80, 0.90, 1.00, 1.10)
BL_WIN    <- c(2015, 2024)              # window every "bias"/sink below is meaned over
BL_GCB_LAND  <- 2.36                    # GtC/yr, DESIGN sec.6 gate 7
BL_GCB_OCEAN <- 3.22
BL_GATE12_MAX_BETA <- 0.50              # diag_joos_beta_scan.R: gate 12 fails above this
BL_REVELLE_MAX_BETA <- 0.53             # handoff 13i sec.A1: the Pulse Lab lesson reverses
# THE SLICE IS REPEATED AT THREE sigma_d13c, and that is not a robustness
# garnish -- the FIRST run of this file (sigma_d13c pinned at the table init
# 0.10) put the argmax at beta 0.70 and REFUTED the pre-registered prediction.
# The refutation turned out to be conditional: d13C at sigma 0.10 contributes
# ~740 log-units in favor of high beta across 0.50 -> 0.75, which is far more
# than the luc_scale prior can resist -- and d13C is the ONE stream carrying a
# known unclosed ~0.53 permil structural misfit, so sigma 0.10 is asserting
# that misfit is measurement noise. The three values below are the ones
# diag_recentre_beta.R already uses: the table init, the value mode_fit chose
# (which inflates to absorb the misfit), and a muted control.
BL_SIGMA_D13C <- c(`table init` = 0.10, `mode_fit` = 0.44, `muted` = 5.00)

cat(sprintf("\n2-D SLICE of the FULL log-posterior over (beta, luc_scale)\n"))
cat(sprintf("all other parameters at CCX_PARAM_TABLE inits; %d-%d\n",
            BL_YEARS[1], BL_YEARS[2]))
cat(sprintf("gate 12 (Joos IRF) needs beta <= %.2f; the Pulse Lab lesson needs <= %.2f\n\n",
            BL_GATE12_MAX_BETA, BL_REVELLE_MAX_BETA))

lp <- ccx_make_logpost(years = BL_YEARS)
u0 <- ccx_init_unc()
ib <- match("beta",      CCX_PARAM_NAMES)
il <- match("luc_scale", CCX_PARAM_NAMES)
tb <- CCX_PARAM_TABLE$beta
tl <- CCX_PARAM_TABLE$luc_scale

is <- match("sigma_d13c", CCX_PARAM_NAMES)
ts <- CCX_PARAM_TABLE$sigma_d13c
grids <- list(); argmax <- list()

for (sn in names(BL_SIGMA_D13C)) {
  M <- matrix(NA_real_, nrow = length(BL_BETAS), ncol = length(BL_SCALES),
              dimnames = list(sprintf("%.2f", BL_BETAS), sprintf("%.2f", BL_SCALES)))
  for (i in seq_along(BL_BETAS)) {
    u <- u0
    u[ib] <- .to_unc(BL_BETAS[i], tb)
    u[is] <- .to_unc(BL_SIGMA_D13C[[sn]], ts)
    for (j in seq_along(BL_SCALES)) {
      u[il] <- .to_unc(BL_SCALES[j], tl)
      M[i, j] <- lp(u)
    }
  }
  grids[[sn]] <- M
  k  <- which(M == max(M, na.rm = TRUE), arr.ind = TRUE)[1, ]
  argmax[[sn]] <- c(beta = BL_BETAS[k[1]], luc_scale = BL_SCALES[k[2]])
  j1 <- match("1.00", colnames(M))

  cat(sprintf("\n\n== sigma_d13c '%s' = %.2f permil ==\n", sn, BL_SIGMA_D13C[[sn]]))
  cat("log-posterior relative to this grid's maximum; rows = beta, cols = luc_scale\n")
  print(round(M - max(M, na.rm = TRUE), 1))
  cat(sprintf("  GRID ARGMAX: beta = %.2f, luc_scale = %.2f\n",
              argmax[[sn]][["beta"]], argmax[[sn]][["luc_scale"]]))
  cat(sprintf("  at luc_scale = 1 (the pre-2026-08-14 objective): best beta = %.2f\n",
              BL_BETAS[which.max(M[, j1])]))
  cat(sprintf("  cost of moving to (beta 0.50, luc_scale 0.60): %.1f log-units\n",
              M[match("0.50", rownames(M)), match("0.60", colnames(M))] - max(M)))
}

cat("\n\n== WHERE THE ARGMAX SITS vs sigma_d13c ==\n")
for (sn in names(BL_SIGMA_D13C))
  cat(sprintf("  sigma_d13c %-12s %.2f  ->  beta %.2f, luc_scale %.2f\n",
              sn, BL_SIGMA_D13C[[sn]], argmax[[sn]][["beta"]],
              argmax[[sn]][["luc_scale"]]))

M <- grids[[1]]
b_hat <- argmax[[1]][["beta"]]; l_hat <- argmax[[1]][["luc_scale"]]

# ---- what the two settlements actually deliver ----------------------
bl_diag <- function(beta, scale) {
  p <- ccx_default_params(); p$beta <- beta
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", BL_YEARS, prod_c14 = sp$prod_c14,
                          luc_scale = scale)
  out <- ccx_run_fast(sp, F)$out
  obs <- ccx_prepare_obs()
  ms  <- ccx_model_stats(out, obs)
  o <- obs$co2_ann$MLO; m <- ms$co2$MLO
  kk <- match(o$year, m$year)
  gg <- !is.na(kk) & o$year >= BL_WIN[1] & o$year <= BL_WIN[2]
  co2b <- mean(o$level[gg] - m$level[kk[gg]])
  o13 <- obs$d13_ann$MLO; m13 <- ms$d13$MLO
  k13 <- match(o13$year, m13$year)
  g13 <- !is.na(k13) & o13$year >= BL_WIN[1] & o13$year <= BL_WIN[2]
  d13b <- mean(o13$level[g13] - m13$level[k13[g13]])
  el <- ccx_forcing_eluc_annual(F)
  yr <- floor(out$t + 1e-9)
  ann <- stats::aggregate(cbind(ocean_C, land_C) ~ yr, data = out, FUN = mean)
  ann <- ann[order(ann$yr), ]
  kw  <- ann$yr[-1] >= BL_WIN[1]
  net <- mean(diff(ann$land_C)[kw]); oc <- mean(diff(ann$ocean_C)[kw])
  elw <- mean(el$eluc[el$year >= BL_WIN[1] & el$year <= BL_WIN[2]])
  c(co2_bias = co2b, d13c_bias = d13b, land = net + elw, ocean = oc,
    cum_luc = sum(el$eluc))
}

cat(sprintf("\n== WHAT EACH SETTLEMENT DELIVERS (%d-%d means) ==\n", BL_WIN[1], BL_WIN[2]))
cat(sprintf("%-28s %10s %10s %11s %11s %11s\n",
            "", "CO2 bias", "d13C bias", "gross land", "ocean", "cum LUC"))
cat(sprintf("%-28s %10.2f %10.3f %11.2f %11.2f %11.1f\n",
            "GCB / observed", 0, 0, BL_GCB_LAND, BL_GCB_OCEAN, NA))
for (cs in list(c(0.75, 1.00), c(b_hat, l_hat))) {
  d <- bl_diag(cs[1], cs[2])
  cat(sprintf("beta %.2f, luc_scale %.2f      %10.2f %10.3f %11.2f %11.2f %11.1f\n",
              cs[1], cs[2], d[["co2_bias"]], d[["d13c_bias"]],
              d[["land"]], d[["ocean"]], d[["cum_luc"]]))
}

cat(sprintf("\ngate 7 (sinks, GCB 1 sigma land 0.5 / ocean 0.4):\n"))
for (cs in list(c(0.75, 1.00), c(b_hat, l_hat))) {
  d <- bl_diag(cs[1], cs[2])
  cat(sprintf("  beta %.2f, luc_scale %.2f -> land %+.1f sigma, ocean %+.1f sigma\n",
              cs[1], cs[2], (d[["land"]] - BL_GCB_LAND) / LIK_GCB_LAND_SD,
              (d[["ocean"]] - BL_GCB_OCEAN) / LIK_GCB_OCEAN_SD))
}
cat(sprintf("\ngate 12 / Pulse Lab: beta %.2f is %s the <= %.2f ceiling.\n",
            b_hat, if (b_hat <= BL_GATE12_MAX_BETA) "INSIDE" else "ABOVE",
            BL_GATE12_MAX_BETA))

cat(sprintf("\nSETTLEMENTS AT EACH sigma_d13c ARGMAX:\n"))
for (sn in names(BL_SIGMA_D13C)) {
  d <- bl_diag(argmax[[sn]][["beta"]], argmax[[sn]][["luc_scale"]])
  cat(sprintf("  sigma %-11s beta %.2f luc %.2f -> CO2 %+6.2f ppm, land %+.1f sd, ocean %+.1f sd, cumLUC %.0f\n",
              sn, argmax[[sn]][["beta"]], argmax[[sn]][["luc_scale"]], d[["co2_bias"]],
              (d[["land"]] - BL_GCB_LAND) / LIK_GCB_LAND_SD,
              (d[["ocean"]] - BL_GCB_OCEAN) / LIK_GCB_OCEAN_SD, d[["cum_luc"]]))
}

saveRDS(list(grids = grids, betas = BL_BETAS, scales = BL_SCALES,
             sigma_d13c = BL_SIGMA_D13C, argmax = argmax),
        ccx_path("calibration", "output", "beta_luc_profile.rds"))
cat("\nsaved to calibration/output/beta_luc_profile.rds\n")
