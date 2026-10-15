# =====================================================================
# build_fert_k_prior.R -- the SHAPE prior on fert_k (2026-09-28, Marcus).
#
# WHY. The historical CO2 record cannot identify the SHAPE of CO2 fertilization:
# beta_max and fert_k correlate at 0.997, and every fit so far lands at
# fert_k 825-940 ppm, which is LOG-LIKE over 1x-4x preindustrial. Marcus ruled
# (2026-09-28): take the shape from Varney 2024, Walker 2021 and physiology,
# with CMIP6 as a COMPARISON, and leave the SIZE of the response to the record.
# notes/lit_2026-09-28_co2_fert_saturation.md is the survey.
#
# THE SHAPE METRIC. R = gain(4x) / gain(2x), both from preindustrial C0. Linear
# gives 3, log 2. For NPP/NPP0 = 1 + beta_max d/(K + d), d = CO2 - C0:
#   R = 3 (K + C0) / (K + 3 C0)   <=>   K = 3 C0 (R - 1) / (3 - R).
#
# SOURCE 1 -- Varney et al. 2024, Biogeosciences 21:2759,
#   doi:10.5194/bg-21-2759-2024, sec. 3.3 (read 2026-09-28): beta_NPP, the NPP
#   sensitivity to CO2 in 10 CMIP6 ESMs' 1pctCO2-BGC runs, ensemble mean
#   2.37 +/- 1.37 PgC/ppm at 2x and 1.44 +/- 0.933 at 4x ("some evidence of a
#   saturation of global NPP"). Both divide by the CO2 change from PI, so
#   dNPP(4x)/dNPP(2x) = 3 x 1.44 / 2.37. ⚠ A ratio of ENSEMBLE MEANS, not a mean
#   of per-model ratios; the paper gives no per-model ratio.
# SOURCE 2 -- Walker et al. 2021, New Phytologist 229:2413,
#   doi:10.1111/nph.16866, accepted manuscript OSTI 1660527, sec. II.1 (read
#   2026-09-28): the theoretical canopy-scale response ratio
#   beta = ln(y_e/y_a) / ln(CO2_e/CO2_a) is 0.60 +/- 0.3 for c. 280-400 ppm and
#   0.46 +/- 0.2 for c. 400-550 ppm (a Farquhar mix of CO2- and light-limited
#   leaves: leaf end-members 0.86 and 0.31). This IS the physiology line. The
#   two elasticities fix (beta_max, K) exactly; K is then read off. ⚠ The
#   paper does not state what the +/- is, so it is not propagated.
# SOURCE 3 (physiology proper, a leaf-level Farquhar bracket) is PENDING: its
#   constants (Bernacchi et al. 2001, PCE 24:253) are paywalled and unread.
# COMPARISON, not a source: our CMIP6 1pctCO2-bgc GPP extraction (16 ESMs),
#   median R 1.81 -> K ~ 568-580 (notes/lit_2026-09-28_cmip6_gpp/).
#
# THE PRIOR. Lognormal, median = geometric mean of the two source K values,
# log-sd 0.35 -- ⚠ A RULING (Marcus 2026-09-28, "moderate"), not a derivation:
# wider than Walker's own sensitivity band (e2 0.43-0.50 -> K 419-681), so a
# log-like K ~834 sits ~1.2 sd out and the record can still pull toward it.
# Applied ONLY under the structure label "hilda_csl3v0k" (R/calibrate.R).
#
# Usage: Rscript data-raw/build_fert_k_prior.R   (writes data/prior_fert_k.rds)
# =====================================================================

FKP_C0          <- 278          # ppm; CCX_PI_PPM's value, the d = 0 point of the MM form
FKP_VARNEY      <- c(beta_2x = 2.37, beta_4x = 1.44)
FKP_WALKER      <- c(e_280_400 = 0.60, e_400_550 = 0.46)
FKP_WALKER_CO2  <- list(c(280, 400), c(400, 550))
FKP_LOG_SD      <- 0.35         # RULING, Marcus 2026-09-28
FKP_OUT         <- file.path("data", "prior_fert_k.rds")

K_of_R <- function(R) 3 * FKP_C0 * (R - 1) / (3 - R)
R_of_K <- function(K) 3 * (K + FKP_C0) / (K + 3 * FKP_C0)
mm     <- function(c, b, K) 1 + b * (c - FKP_C0) / (K + c - FKP_C0)
elas   <- function(r, b, K) log(mm(r[2], b, K) / mm(r[1], b, K)) / log(r[2] / r[1])

# Varney
R_varney <- 3 * FKP_VARNEY[["beta_4x"]] / FKP_VARNEY[["beta_2x"]]
K_varney <- K_of_R(R_varney)

# Walker: solve the two elasticities for (beta_max, K)
obj <- function(q) { b <- exp(q[1]); K <- exp(q[2])
  (elas(FKP_WALKER_CO2[[1]], b, K) - FKP_WALKER[[1]])^2 +
  (elas(FKP_WALKER_CO2[[2]], b, K) - FKP_WALKER[[2]])^2 }
o <- optim(c(log(1.3), log(600)), obj, control = list(reltol = 1e-15, maxit = 10000))
stopifnot(o$convergence == 0, o$value < 1e-12)     # two equations, two unknowns: exact
K_walker <- exp(o$par[2]); b_walker <- exp(o$par[1])

median_K <- exp(mean(log(c(K_walker, K_varney))))
out <- list(
  median_ppm = median_K, log_sd = FKP_LOG_SD,
  K_walker = K_walker, beta_max_walker = b_walker, R_walker = R_of_K(K_walker),
  K_varney = K_varney, R_varney = R_varney,
  sources = c(
    varney = "Varney et al. 2024 Biogeosciences 21:2759 doi:10.5194/bg-21-2759-2024 sec.3.3: beta_NPP 2.37 (2x), 1.44 (4x) PgC/ppm, 10 CMIP6 ESMs",
    walker = "Walker et al. 2021 New Phytol 229:2413 doi:10.1111/nph.16866 (OSTI 1660527) sec.II.1: canopy beta 0.60 (280-400), 0.46 (400-550)"),
  comparison = "CMIP6 1pctCO2-bgc GPP, 16 ESMs, median R 1.81 (notes/lit_2026-09-28_cmip6_gpp/) -- NOT used",
  log_sd_is = "RULING Marcus 2026-09-28 ('moderate'), not derived",
  built_on = format(Sys.Date()), built_by = "data-raw/build_fert_k_prior.R")
saveRDS(out, FKP_OUT)
cat(sprintf("Walker: K %.1f ppm (beta_max %.3f, R %.3f)\nVarney: K %.1f ppm (R %.3f)\n",
            K_walker, b_walker, R_of_K(K_walker), K_varney, R_varney))
cat(sprintf("PRIOR: lognormal median %.1f ppm, log-sd %.2f -> 1-sd [%.0f, %.0f], log-like K 834 at %+.2f sd\n",
            median_K, FKP_LOG_SD, median_K * exp(-FKP_LOG_SD), median_K * exp(FKP_LOG_SD),
            log(834 / median_K) / FKP_LOG_SD))
cat("wrote ", FKP_OUT, "\n", sep = "")
