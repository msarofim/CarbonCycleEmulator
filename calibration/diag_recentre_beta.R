# =====================================================================
# diag_recentre_beta.R -- what `ccx_default_params()$beta` should be on the
# CONVERTED-LAND model, and by which criterion.
#
# WHY THIS EXISTS. `beta`'s default (and `CCX_PARAM_TABLE$beta$init`, which
# tracks it) was re-centered to 0.38 on 2026-08-12 "to the 1-D posterior
# optimum". That was measured on the model that preceded `404d66d`, in which
# land-use emissions had an airborne fraction of 0.002 -- i.e. against the bug.
# On the shipped model 0.38 leaves CO2 ~20 ppm high at 2015-2024. This is an
# app and test fixture, not a calibrated value, and DESIGN's app panels should
# not be built on it as it stands (handoff 13h sec.2.2e).
#
# WHY IT IS MEASURED AND NOT SET. Three criteria disagree, and which one the
# default should track is a methodological choice, not a lookup:
#   [A] the CO2 record alone -- the zero of the 2015-2024 MLO bias;
#   [B] the CO2 STREAM's own 1-D log-likelihood optimum (level + seasonal +
#       ice core), which weights the whole record, not one decade;
#   [C] the FULL 1-D log-posterior optimum, which is what the 2026-08-12
#       re-centering claims to have used -- and which depends on sigma_d13c,
#       the parameter handoff 13h sec.2.1c leaves open. So [C] is reported at
#       more than one sigma, deliberately: if the answer moves with a number
#       that is not yet decided, the default should not be pinned to it.
#
# WHAT IT DOES NOT DO. It does not touch q10, which is held at its default
# 2.0. A 2-D (beta, q10) re-centering is the REFIT's job (PHASE 2), and doing
# it here would pre-empt the pre-registered test.
#
# RUNTIME ~3 min.
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
RB_YEARS     <- c(1750, 2024)
RB_BOMB_REF  <- 102
RB_BIAS_WIN  <- c(2015, 2024)          # window every "bias" below is meaned over
# the grid runs past the CO2 crossing to the d13C one, because the DISTANCE
# between those two crossings is the structural misfit and a grid that stops
# before the second reports it as NA
RB_BETA_GRID <- seq(0.20, 1.35, by = 0.05)
RB_INCUMBENT <- ccx_default_params()$beta
# sigma sets the 1-D posterior is profiled under. "table init" is what
# CCX_PARAM_TABLE ships; "mode" is mode_fit.rds's, where sigma_d13c has been
# inflated to 0.44 permil (+2.20 sigma) to absorb the structural d13C misfit.
RB_ERR_SETS  <- list(
  `table init`  = list(sigma_co2 = 1.500, sigma_d13c = 0.100, sigma_d14c = 5.00),
  `mode_fit`    = list(sigma_co2 = 0.301, sigma_d13c = 0.440, sigma_d14c = 4.16),
  `d13c muted`  = list(sigma_co2 = 1.500, sigma_d13c = 5.000, sigma_d14c = 5.00)
)
RB_FAMILY <- list(CO2 = "^co2_", d13C = "^d13c_", D14C = "^d14c_")

obs <- ccx_prepare_obs()
base_forcing <- ccx_build_forcing("historical", RB_YEARS, prod_c14 = 0,
                                 bomb_total_kmol = RB_BOMB_REF)

rb_run <- function(p) {
  s <- ccx_spinup(p)
  F <- base_forcing; F$c14_cosmo <- s$prod_c14
  ccx_run_fast(s, F)$out
}

# mean(obs - model) over RB_BIAS_WIN, on the annual statistics
rb_bias <- function(o, m, col = "level") {
  k <- match(o$year, m$year)
  g <- !is.na(k) & o$year >= RB_BIAS_WIN[1] & o$year <= RB_BIAS_WIN[2]
  mean(o[[col]][g] - m$level[k[g]])
}

# annual-mean sink fluxes, GtC/yr, over RB_BIAS_WIN.
#
# UNITS TRAP, and it is one this repo has already fallen into once: GCB's
# `land_sink` column is the RESIDUAL sink alone, while mean(diff(land_C)) is the
# NET land flux -- that sink MINUS E_LUC. The two were nearly the same quantity
# while land-use carbon was being regrown and are not now. The gross sink, which
# is what GCB's column means, is diff(land_C) + E_LUC, and that is what is
# returned as `land`. `land_net` is kept alongside because it is the quantity
# the cumulative-vs-GCB comparison uses.
RB_ELUC <- local({
  em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
  mean(em$luc_GtC[em$year >= RB_BIAS_WIN[1] & em$year <= RB_BIAS_WIN[2]])
})
rb_partition <- function(out) {
  yr  <- floor(out$t + 1e-9)
  ann <- stats::aggregate(cbind(ocean_C, land_C) ~ yr, data = out, FUN = mean)
  ann <- ann[order(ann$yr), ]
  k   <- ann$yr[-1] >= RB_BIAS_WIN[1]
  net <- mean(diff(ann$land_C)[k])
  c(land = net + RB_ELUC, land_net = net, ocean = mean(diff(ann$ocean_C)[k]))
}

# linear interpolation of the beta at which `y` crosses zero, on a grid that
# is monotone in beta over the crossing. Reported to 3 dp; the grid is 0.05, so
# the third digit is interpolation, not resolution.
rb_cross <- function(beta, y) {
  i <- which(diff(sign(y)) != 0)
  if (!length(i)) return(NA_real_)
  i <- i[1]
  beta[i] - y[i] * (beta[i + 1] - beta[i]) / (y[i + 1] - y[i])
}

gcb <- as.data.frame(obs$gcb)
g   <- gcb$year >= RB_BIAS_WIN[1] & gcb$year <= RB_BIAS_WIN[2]
GCB_LAND  <- mean(gcb$land_sink[g])
GCB_OCEAN <- mean(gcb$ocean_sink[g])

cat(sprintf("\nBETA RE-CENTRING on the converted-land model (f_luc_perm = %g)\n",
            ccx_default_params()$f_luc_perm))
cat(sprintf("incumbent default beta = %.3f, set 2026-08-12 against the pre-404d66d model\n",
            RB_INCUMBENT))
cat(sprintf("q10 held at its default %.2f; every other parameter at ccx_default_params()\n",
            ccx_default_params()$q10))
cat(sprintf("biases are mean(obs - model) over %d-%d\n\n", RB_BIAS_WIN[1], RB_BIAS_WIN[2]))
cat(sprintf("GCB %d-%d: land %.2f  ocean %.2f GtC/yr  (land share %.0f %%)\n\n",
            RB_BIAS_WIN[1], RB_BIAS_WIN[2], GCB_LAND, GCB_OCEAN,
            100 * GCB_LAND / (GCB_LAND + GCB_OCEAN)))

res <- list()
for (b in RB_BETA_GRID) {
  p <- ccx_default_params(); p$beta <- b
  out <- rb_run(p)
  ms  <- ccx_model_stats(out, obs)
  s   <- rb_partition(out)
  row <- list(beta = b,
              co2  = rb_bias(obs$co2_ann$MLO, ms$co2$MLO),
              d13  = rb_bias(obs$d13_ann$MLO, ms$d13$MLO),
              land = s[["land"]], land_net = s[["land_net"]], ocean = s[["ocean"]])
  for (en in names(RB_ERR_SETS)) {
    ll <- ccx_loglik(out, obs, RB_ERR_SETS[[en]], by_stream = TRUE)
    for (fn in names(RB_FAMILY))
      row[[paste0(en, "|", fn)]] <- sum(ll[grepl(RB_FAMILY[[fn]], names(ll))])
    row[[paste0(en, "|TOTAL")]] <- sum(ll)
  }
  res[[length(res) + 1]] <- row
  cat(sprintf("  beta %.2f  CO2 bias %+7.2f ppm  d13C bias %+6.3f permil  gross land %5.2f  ocean %5.2f\n",
              b, row$co2, row$d13, row$land, row$ocean))
}
# check.names = FALSE: the column names carry a "|" separator, and make.names()
# would rewrite them to "table.init.CO2" so every later df[[...]] silently
# returns NULL -- which sprintf() prints as nothing rather than as an error.
df <- do.call(rbind, lapply(res, function(r)
  as.data.frame(r, check.names = FALSE, stringsAsFactors = FALSE)))

cat("\n[A] THE CO2 RECORD ALONE -- zero of the 2015-2024 MLO bias\n")
bA <- rb_cross(df$beta, df$co2)
cat(sprintf("    beta_A = %.3f\n", bA))
cat(sprintf("    for reference, the d13C bias crosses zero at beta = %.3f\n",
            rb_cross(df$beta, df$d13)))
cat("    (the gap between those two is diag_d13c_suess sec.3's structural misfit,\n")
cat("     expressed as a beta rather than as a permil)\n")

cat("\n[B] and [C] 1-D LOG-LIKELIHOOD PROFILES\n")
cat("    argmax on a 0.05 grid is fragile on a flat optimum, so the PROFILE is\n")
cat("    printed and a parabola through the argmax and its two neighbours gives\n")
cat("    the sub-grid location. Read the curve, not just the number.\n")
for (en in names(RB_ERR_SETS)) {
  cat(sprintf("\n  -- sigma set '%s' (co2 %.3f, d13c %.3f, d14c %.2f) --\n", en,
              RB_ERR_SETS[[en]]$sigma_co2, RB_ERR_SETS[[en]]$sigma_d13c,
              RB_ERR_SETS[[en]]$sigma_d14c))
  cat("     beta      CO2 stream     d13C stream    D14C stream    TOTAL\n")
  for (i in seq_len(nrow(df)))
    cat(sprintf("     %.2f   %13.1f  %13.1f  %13.1f  %13.1f\n", df$beta[i],
                df[[paste0(en, "|CO2")]][i], df[[paste0(en, "|d13C")]][i],
                df[[paste0(en, "|D14C")]][i], df[[paste0(en, "|TOTAL")]][i]))
  for (fn in c("CO2", "TOTAL")) {
    y <- df[[paste0(en, "|", fn)]]
    stopifnot(is.numeric(y), length(y) == nrow(df), !anyNA(y))
    i <- which.max(y)
    sub <- if (i > 1 && i < length(y)) {
      d <- y[i - 1] - 2 * y[i] + y[i + 1]
      df$beta[i] + if (d < 0) 0.5 * (y[i - 1] - y[i + 1]) / d * diff(df$beta[1:2]) else 0
    } else NA_real_
    cat(sprintf("     argmax %-5s grid %.2f  parabolic %.3f  (%s)\n", fn, df$beta[i],
                sub, if (i == 1 || i == length(y)) "AT A GRID EDGE" else "interior"))
  }
}

cat("\nTHE POINT OF THE THREE SIGMA SETS: a default is a fixture, and it should\n")
cat("not be pinned to a criterion that moves when an undecided sigma moves.\n")
saveRDS(df, ccx_path("calibration", "output", "recentre_beta_scan.rds"))
cat(sprintf("\nscan written to %s\n",
            ccx_path("calibration", "output", "recentre_beta_scan.rds")))
