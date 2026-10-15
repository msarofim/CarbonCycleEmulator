# =====================================================================
# diag_emission_split_and_season.R -- are the emission inputs put in the right
# HEMISPHERE, and at the right TIME OF YEAR?
#
# THE QUESTION (Marcus, 2026-08-14): check the hemispheric split of fossil and
# land-use emissions, and -- especially for land use -- the seasonal cycle.
#
# WHY IT MATTERS HERE AND NOT ONLY IN PRINCIPLE. Both inputs are prescribed
# with a CONSTANT hemispheric share (FORC_FOSS_NH_SHARE 0.95,
# FORC_LUC_NH_SHARE 0.55, both flagged "provisional" in DATA.md sec.6) and with
# NO SEASONALITY AT ALL (DESIGN sec.3.6, "smooth annual->monthly"). Two ways
# that can hurt:
#   * the modeled MLO-SPO gradient is already wrong -- ~1.1 ppm in CO2 and
#     -0.210 vs -0.074 permil in d13C -- and a wrong share is the most obvious
#     candidate. Nothing in the likelihood scores the gradient (review sec.2.3),
#     so a wrong share is currently UNOBSERVABLE to the calibration.
#   * an omitted INPUT seasonality does not vanish: it is absorbed by the
#     fitted NEP harmonics, which are the only free seasonal parameters. That
#     is overfitting in its precise sense -- a physical signal reassigned to the
#     wrong mechanism -- and co2_seasonal_MLO is the single highest-leverage
#     stream in the objective (4,118 log-units on seas_phase_NH).
#
# THREE PARTS:
#  1. LUC hemispheric share from OSCAR v3.1's REGIONAL sheet -- a real,
#     time-varying number, against the constant 0.55.
#  2. Sensitivity of the objective AND of the modeled gradient to both shares.
#  3. What an omitted seasonal cycle in each input would do, as a BOUNDING test.
#
# RUNTIME ~5 min.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

ES_YEARS <- c(1750, 2024)
ES_WIN   <- c(2015, 2024)
ES_SIGMA <- list(sigma_co2 = 1.5, sigma_d13c = 0.44, sigma_d14c = 5)

# ---------------------------------------------------------------------
# PART 1 -- the land-use hemispheric share, from OSCAR's regional breakdown
#
# Source: the SAME file DATA.md sec.3a already uses for the pre-1850 segment --
# data-raw/downloads/oscar_gcb2020_eluc.xlsx, "Regional" sheet, 11 regions,
# 1701-2018. Gasser et al. 2020, doi:10.5194/bg-17-4075-2020. Its 1750-2018
# total reproduces the paper's 206 PgC headline, which is the check that the
# right column is being read.
#
# WHAT IS SOURCED AND WHAT IS NOT, stated plainly. The REGIONAL E_luc series is
# sourced. The NH fraction WITHIN each straddling region is NOT -- OSCAR's
# regions are political aggregates, not hemispheres, and nothing in this repo
# resolves them. The fractions below are geographic judgments, so they are
# carried as a BRACKET and every number in this part is reported lo/central/hi.
# The conclusion to trust is the one that survives the whole bracket.
# ---------------------------------------------------------------------
ES_NH_FRAC <- list(
  # region long name                       lo   central  hi     why
  `North America`                    = c(1.00, 1.00, 1.00),  # entirely NH
  `Europe`                           = c(1.00, 1.00, 1.00),  # entirely NH
  `Former Soviet Union`              = c(1.00, 1.00, 1.00),  # entirely NH
  `China`                            = c(1.00, 1.00, 1.00),  # entirely NH
  `North Africa and the Middle East` = c(1.00, 1.00, 1.00),  # entirely NH
  `East Asia`                        = c(1.00, 1.00, 1.00),  # Japan/Korea/Mongolia
  # Brazil dominates Latin American clearing and is ~93 % SH; Mexico, Central
  # America, the Caribbean and northern Colombia/Venezuela are NH.
  `Latin America`                    = c(0.15, 0.25, 0.35),
  # Straddles: Sahel, Nigeria, Ethiopia and northern Congo basin NH; southern
  # Congo, Angola, Zambia, southern Tanzania and southern Africa SH.
  `Sub-Saharan Africa`               = c(0.35, 0.50, 0.65),
  # Mainland (India, Indochina, Philippines) NH; Indonesia -- a large share of
  # the region's clearing -- is largely SH (Java, southern Sumatra, Papua).
  `South and Southeast Asia`         = c(0.55, 0.70, 0.85),
  `Oceania`                          = c(0.00, 0.05, 0.10),  # Australia/NZ/PNG
  `Unknown`                          = c(0.50, 0.50, 0.50)   # zero flux anyway
)

reg <- as.data.frame(readxl::read_excel(
  ccx_path("data-raw", "downloads", "oscar_gcb2020_eluc.xlsx"), sheet = "Regional"))
reg <- reg[reg$year >= 1750 & reg$year <= 2018, ]
stopifnot(all(reg$reg_land_long_name %in% names(ES_NH_FRAC)))

es_nh_share <- function(which_col) {
  f <- vapply(reg$reg_land_long_name, function(n) ES_NH_FRAC[[n]][which_col], numeric(1))
  num <- tapply(reg$E_luc * f, reg$year, sum)
  den <- tapply(reg$E_luc,     reg$year, sum)
  data.frame(year = as.integer(names(den)), share = as.numeric(num / den),
             eluc = as.numeric(den))
}
sh <- lapply(1:3, es_nh_share)
names(sh) <- c("lo", "central", "hi")

cat(sprintf("\n=== PART 1. LAND-USE NH SHARE from OSCAR regions, vs the model's constant %.2f ===\n",
            FORC_LUC_NH_SHARE))
cat("(within-region NH fractions are geographic judgements, hence the bracket)\n\n")
cat(sprintf("%12s %10s %10s %10s %10s\n", "period", "E_luc GtC", "NH lo", "NH central", "NH hi"))
per <- list(c(1750, 1849), c(1850, 1899), c(1900, 1949), c(1950, 1989), c(1990, 2018))
for (p in per) {
  k <- sh$central$year >= p[1] & sh$central$year <= p[2]
  w <- sh$central$eluc[k]
  wm <- function(x) sum(x[k] * w) / sum(w)
  cat(sprintf("%12s %10.1f %10.3f %10.3f %10.3f\n",
              sprintf("%d-%d", p[1], p[2]), sum(w),
              wm(sh$lo$share), wm(sh$central$share), wm(sh$hi$share)))
}
kk <- sh$central$year >= 1750
cat(sprintf("%12s %10.1f %10.3f %10.3f %10.3f\n", "1750-2018 all",
            sum(sh$central$eluc[kk]),
            sum(sh$lo$share[kk] * sh$central$eluc[kk]) / sum(sh$central$eluc[kk]),
            sum(sh$central$share[kk] * sh$central$eluc[kk]) / sum(sh$central$eluc[kk]),
            sum(sh$hi$share[kk] * sh$central$eluc[kk]) / sum(sh$central$eluc[kk])))

# ---------------------------------------------------------------------
# PART 2 -- what the model does with a different share
# ---------------------------------------------------------------------
es_run <- function(foss_share = FORC_FOSS_NH_SHARE, luc_share = FORC_LUC_NH_SHARE,
                   luc_season = 0, foss_season = 0,
                   luc_phase_NH = 1, luc_phase_SH = 9, foss_phase = 1) {
  p  <- ccx_default_params()
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", ES_YEARS, prod_c14 = sp$prod_c14)
  foss <- F$e_foss_NH + F$e_foss_SH
  luc  <- F$e_luc_NH  + F$e_luc_SH
  cuml <- F$cum_luc_NH + F$cum_luc_SH
  # zero-mean seasonal modulation, applied per hemisphere; cum_luc is left on
  # the annual path because a within-year redistribution does not change the
  # cumulative clearing the converted-land term reads.
  mo   <- (F$month - 0.5) / 12
  sNH  <- 1 + luc_season  * cos(2 * pi * (mo - (luc_phase_NH - 0.5) / 12))
  sSH  <- 1 + luc_season  * cos(2 * pi * (mo - (luc_phase_SH - 0.5) / 12))
  fNH  <- 1 + foss_season * cos(2 * pi * (mo - (foss_phase   - 0.5) / 12))
  F$e_foss_NH <- foss * foss_share       * fNH
  F$e_foss_SH <- foss * (1 - foss_share)
  F$e_luc_NH  <- luc  * luc_share        * sNH
  F$e_luc_SH  <- luc  * (1 - luc_share)  * sSH
  F$cum_luc_NH <- cuml * luc_share
  F$cum_luc_SH <- cuml * (1 - luc_share)
  out <- ccx_run_fast(sp, F)$out
  obs <- ccx_prepare_obs()
  ms  <- ccx_model_stats(out, obs)
  parts <- ccx_loglik(out, obs, ES_SIGMA, luc = ccx_forcing_eluc_annual(F),
                      by_stream = TRUE)
  k  <- ms$co2$MLO$year >= ES_WIN[1] & ms$co2$MLO$year <= ES_WIN[2]
  k2 <- ms$co2$SPO$year >= ES_WIN[1] & ms$co2$SPO$year <= ES_WIN[2]
  k3 <- ms$d13$MLO$year >= ES_WIN[1] & ms$d13$MLO$year <= ES_WIN[2]
  k4 <- ms$d13$SPO$year >= ES_WIN[1] & ms$d13$SPO$year <= ES_WIN[2]
  ks <- ms$co2$MLO$year >= 1975
  list(parts = parts, ll = sum(parts),
       grad_co2  = mean(ms$co2$MLO$level[k]) - mean(ms$co2$SPO$level[k2]),
       grad_d13c = mean(ms$d13$MLO$level[k3]) - mean(ms$d13$SPO$level[k4]),
       seas_amp  = 2 * sqrt(mean(ms$co2$MLO$a[ks])^2 + mean(ms$co2$MLO$b[ks])^2),
       seas_a = mean(ms$co2$MLO$a[ks]), seas_b = mean(ms$co2$MLO$b[ks]))
}

OBS_GRAD_CO2  <- 3.97      # ppm, DESIGN sec.6 gate 9, 2020s seasonally adjusted
OBS_GRAD_D13C <- -0.074    # permil, handoff 13i
base <- es_run()
cat(sprintf("\n\n=== PART 2. SENSITIVITY OF THE GRADIENT AND THE OBJECTIVE TO THE SHARES ===\n"))
cat(sprintf("observed: MLO-SPO CO2 gradient %.2f ppm (gate 9, 2020s), d13C %.3f permil\n\n",
            OBS_GRAD_CO2, OBS_GRAD_D13C))
cat(sprintf("%-34s %11s %12s %12s\n", "", "CO2 grad", "d13C grad", "d logL"))
cat(sprintf("%-34s %11.2f %12.3f %12s\n", "AS SHIPPED (0.95 / 0.55)",
            base$grad_co2, base$grad_d13c, "-"))
for (ls in c(0.40, 0.45, 0.50, 0.60, 0.65, 0.70)) {
  r <- es_run(luc_share = ls)
  cat(sprintf("%-34s %11.2f %12.3f %+12.1f\n",
              sprintf("  LUC NH share %.2f", ls), r$grad_co2, r$grad_d13c, r$ll - base$ll))
}
for (fs in c(0.90, 0.92, 0.97)) {
  r <- es_run(foss_share = fs)
  cat(sprintf("%-34s %11.2f %12.3f %+12.1f\n",
              sprintf("  fossil NH share %.2f", fs), r$grad_co2, r$grad_d13c, r$ll - base$ll))
}

# ---------------------------------------------------------------------
# PART 3 -- the omitted seasonal cycles, as a bounding test
#
# NEITHER amplitude is sourced, and neither is meant to be: this is a BOUND.
# The land-use bracket reasons that only the immediate-combustion part of a
# bookkeeping E_LUC is seasonal (the soil-carbon legacy decays year-round), so
# an effective amplitude of 0.3-0.6 stands for a strongly seasonal fire term
# diluted by an aseasonal remainder. Phases: NH tropical burning peaks in the
# northern dry season (Dec-Feb) and SH tropical burning in Aug-Oct. Fossil peaks
# in NH winter with a small amplitude. If a BOUNDING amplitude moves the
# seasonal statistic by less than its own sigma, the omission is safe and can be
# recorded as such; if not, a sourced monthly product is required (GFED for
# burning, a monthly fossil product for fossil).
# ---------------------------------------------------------------------
obs <- ccx_prepare_obs()
sd_a <- obs$co2_seas$MLO$sd_a; sd_b <- obs$co2_seas$MLO$sd_b
cat(sprintf("\n\n=== PART 3. OMITTED INPUT SEASONALITY -- A BOUNDING TEST ===\n"))
cat(sprintf("the seasonal term's own sigma at MLO: sd_a %.4f, sd_b %.4f ppm\n",
            sd_a, sd_b))
cat(sprintf("model MLO seasonal peak-to-peak as shipped: %.3f ppm\n\n", base$seas_amp))
cat(sprintf("%-40s %10s %10s %11s %11s\n",
            "", "p-p ppm", "d(p-p)", "d seasonal", "d total"))
cases <- list(
  list(lab = "LUC seasonality A = 0.3",          luc_season = 0.3),
  list(lab = "LUC seasonality A = 0.6",          luc_season = 0.6),
  list(lab = "LUC A = 0.6, NH phase Jul not Jan", luc_season = 0.6, luc_phase_NH = 7),
  list(lab = "fossil seasonality A = 0.06",      foss_season = 0.06),
  list(lab = "fossil seasonality A = 0.10",      foss_season = 0.10),
  list(lab = "both (LUC 0.6, fossil 0.10)",      luc_season = 0.6, foss_season = 0.10)
)
for (cs in cases) {
  lab <- cs$lab; cs$lab <- NULL
  r <- do.call(es_run, cs)
  ds <- r$parts[["co2_seasonal_MLO"]] + r$parts[["co2_seasonal_SPO"]] -
        base$parts[["co2_seasonal_MLO"]] - base$parts[["co2_seasonal_SPO"]]
  cat(sprintf("%-40s %10.3f %+10.3f %+11.1f %+11.1f\n",
              lab, r$seas_amp, r$seas_amp - base$seas_amp, ds, r$ll - base$ll))
}
cat("\nFor scale: moving seas_amp_NH from 12 to 13 GtC/yr (a +8 % change in the\n")
r13 <- local({
  p <- ccx_default_params(); p$seas_amp_NH <- 13
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", ES_YEARS, prod_c14 = sp$prod_c14)
  out <- ccx_run_fast(sp, F)$out
  ms <- ccx_model_stats(out, obs)
  ks <- ms$co2$MLO$year >= 1975
  2 * sqrt(mean(ms$co2$MLO$a[ks])^2 + mean(ms$co2$MLO$b[ks])^2)
})
cat(sprintf("ONE free seasonal parameter) changes the MLO peak-to-peak by %+.3f ppm.\n",
            r13 - base$seas_amp))
cat("Compare that with the d(p-p) column: it is how much of an omitted input\n")
cat("seasonality the fitted NEP harmonic would silently absorb.\n")
