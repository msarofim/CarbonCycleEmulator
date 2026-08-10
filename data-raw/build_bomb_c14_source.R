# =====================================================================
# build_bomb_c14_source.R -- derive the bomb 14C input function to the
# TROPOSPHERE from Tans (1981) SCOPE 16 Tables 1 and 2.
#
# Run from repo root:  Rscript data-raw/build_bomb_c14_source.R
#
# WHY THIS EXISTS
# ---------------
# The model's atmosphere is a single well-mixed troposphere per hemisphere
# (R/model.R) with no stratospheric box. forc$c14_bomb is therefore a DELIVERY
# rate to the troposphere, not a production rate. The superseded placeholder in
# ccx_bomb_c14_annual() was shaped like production: it put 54.0 % of all bomb
# 14C into 1961-62 and 2.2 % into 1963. Telegadas' measurements say 56-60 % of
# the Naegler & Levin total was still IN THE STRATOSPHERE in Dec 62 - Feb 63,
# and that 1963 was the largest single year of delivery to the troposphere.
# The placeholder is mistimed by roughly a year, in the direction that matters:
# DESIGN sec.6 gates the observed tropospheric D14C peak at 1963.625.
#
# METHOD (the "hybrid measured input function", Marcus 2026-08-10)
# ---------------------------------------------------------------
# Part A, 1963.04 onward -- DIRECT. Tans p.133: "The input of bomb 14C into the
#   troposphere is then simply equal to the stratospheric decrease." Two
#   decaying exponentials are fitted to the Table 2 stratospheric inventory
#   (two reservoirs; the raw differences already show a fast early and a slow
#   late timescale). The analytic derivative is the delivery flux: positive by
#   construction, so the one non-monotone pair in the raw table
#   (9/65-11/65 -> 12/65-2/66, which Tans himself dismisses as insignificant
#   seasonality) cannot produce a negative source.
#
# Part B, pre-1963 -- BUDGET-CLOSED. The Table 2 fit gives the burden still
#   aloft at 1963.04; the rest of the Naegler & Levin total must already have
#   reached the troposphere. That fixes the pre-1963 delivery INTEGRAL with no
#   test-yield inventory. Its TIME SHAPE comes from the tropospheric 14C
#   inventory implied by Tans Table 1, plus a first-order removal term
#   lambda*N14 for ocean and biosphere uptake -- uptake is about HALF of
#   pre-1963 delivery, so it cannot be dropped. lambda is not tuned: it is the
#   unique value closing the measured budget, in closed form. It is then
#   checked against an INDEPENDENT gross-air-sea-flux estimate built from Tans'
#   own 19 mol/m2/yr (Broecker et al. 1978).
#
# UNSCEAR 2000 Annex C is NOT required by this construction.
#
# Output: data/forcing_bomb_c14.rds -- monthly, unit-integral shape.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

MANUAL <- "data-raw/manual"
OUT    <- "data"

# ---- named constants: every choice in the derivation is declared here ----
BOMB_T1_FILE        <- file.path(MANUAL, "tans1981_scope16_table1_tropospheric_d14c.csv")
BOMB_T2_FILE        <- file.path(MANUAL, "tans1981_scope16_table2_stratospheric_inventory.csv")
BOMB_OUT_FILE       <- file.path(OUT, "forcing_bomb_c14.rds")

BOMB_TOTAL_REF_KMOL <- 102      # Naegler & Levin (2006) central, 1945-1980.
                                # Only sets the pre/post-1963 SPLIT; the model
                                # rescales the unit-integral shape by the
                                # calibrated bomb_total.
# The two judgement calls in this derivation are exposed as environment
# overrides so their effect can be measured rather than argued about:
#   CCX_BOMB_DROP_FIRST=0  CCX_BOMB_PREBOMB=-25  Rscript data-raw/build_bomb_c14_source.R
BOMB_T2_DROP_FIRST  <- as.logical(as.integer(Sys.getenv("CCX_BOMB_DROP_FIRST", "1")))
                                # Tans p.133 says the 12/62-2/63 value is "much
                                # too low" (early flights missed high-latitude
                                # 14C). Excluded from the fit; the fitted curve
                                # extrapolates the true t0 burden upward.
BOMB_PREBOMB_D14C   <- as.numeric(Sys.getenv("CCX_BOMB_PREBOMB", "-30"))
                                # permil. Suess-depleted pre-bomb level, taken
                                # as the Dec-1954 SH value of Tans Table 1 (the
                                # SH had no detectable bomb signal then).
BOMB_EXCESS_ZERO_YR <- 1952.0   # bomb excess anchored to zero here: pre-1952
                                # atmospheric tests were small fission devices
                                # with negligible 14C yield relative to the
                                # 1952 (Ivy Mike) and later thermonuclear tests.
BOMB_SERIES_END_YR  <- 1980     # matches the range the forcing builder and
                                # tests/testthat/test-forcing.R assume.
BOMB_STRAT_AIR_KG   <- 1.02e18  # Telegadas' stratosphere, quoted by Tans p.133
BOMB_TOTAL_AIR_KG   <- 5.20e18  # ... out of this total atmospheric mass
BOMB_M_AIR_KG_MOL   <- 28.96e-3 # mean molar mass of dry air
BOMB_GROSS_AS_FLUX  <- 19       # mol CO2 /m2/yr, Broecker et al. (1978), the
                                # value Tans himself used (p.134)
NA_AVOGADRO         <- 6.02214076e23

cat("\n=== build_bomb_c14_source.R ===\n")
cat("Source: Tans (1981) SCOPE 16 pp.131-157, Tables 1 and 2\n")
cat(sprintf("Reference total: %.0f kmol (Naegler & Levin 2006)\n\n", BOMB_TOTAL_REF_KMOL))

# =====================================================================
# Part A -- stratospheric inventory -> delivery flux
# =====================================================================
t2 <- read.csv(BOMB_T2_FILE, comment.char = "#")
t2$kmol <- t2$inventory_1e26_atoms * 1e26 / NA_AVOGADRO / 1000
t0 <- t2$t_mid[1]

fit_rows <- if (BOMB_T2_DROP_FIRST) seq(2, nrow(t2)) else seq_len(nrow(t2))
cat(sprintf("Part A: fitting 2 exponentials to %d of %d Table 2 points%s\n",
            length(fit_rows), nrow(t2),
            if (BOMB_T2_DROP_FIRST) " (12/62-2/63 excluded, Tans p.133)" else ""))

# I(t) = A1 exp(-(t-t0)/tau1) + A2 exp(-(t-t0)/tau2); positive params via log.
sse <- function(th) {
  A1 <- exp(th[1]); tau1 <- exp(th[2]); A2 <- exp(th[3]); tau2 <- exp(th[4])
  pred <- A1 * exp(-(t2$t_mid[fit_rows] - t0) / tau1) +
          A2 * exp(-(t2$t_mid[fit_rows] - t0) / tau2)
  sum((pred - t2$kmol[fit_rows])^2)
}
best <- NULL
for (s1 in c(0.3, 0.5, 0.7)) for (s2 in c(1.0, 2.0)) for (s3 in c(5, 10, 20)) {
  th0 <- c(log(59 * s1), log(s2), log(59 * (1 - s1)), log(s3))
  f <- tryCatch(optim(th0, sse, method = "Nelder-Mead",
                      control = list(maxit = 20000, reltol = 1e-14)),
                error = function(e) NULL)
  if (!is.null(f) && (is.null(best) || f$value < best$value)) best <- f
}
A1 <- exp(best$par[1]); tau1 <- exp(best$par[2])
A2 <- exp(best$par[3]); tau2 <- exp(best$par[4])
# order so component 1 is the fast one
if (tau1 > tau2) { tmp <- c(A1, tau1); A1 <- A2; tau1 <- tau2; A2 <- tmp[1]; tau2 <- tmp[2] }
I_t0 <- A1 + A2
rmse <- sqrt(best$value / length(fit_rows))

cat(sprintf("  fast reservoir: %6.2f kmol, tau = %5.2f yr\n", A1, tau1))
cat(sprintf("  slow reservoir: %6.2f kmol, tau = %5.2f yr\n", A2, tau2))
cat(sprintf("  burden at t0=%.3f: %.2f kmol (raw Table 2 first point %.2f, a known floor)\n",
            t0, I_t0, t2$kmol[1]))
cat(sprintf("  fit RMSE %.3f kmol over %d points\n", rmse, length(fit_rows)))

strat_flux <- function(t) {                       # kmol/yr into the troposphere
  ifelse(t < t0, 0, A1 / tau1 * exp(-(t - t0) / tau1) + A2 / tau2 * exp(-(t - t0) / tau2))
}

# =====================================================================
# Part B -- Table 1 tropospheric inventory + budget-closed removal
# =====================================================================
t1 <- read.csv(BOMB_T1_FILE, comment.char = "#")
t1$t <- t1$year + 11.5 / 12          # all values are December

D_pre <- BOMB_TOTAL_REF_KMOL - I_t0  # kmol delivered to troposphere before t0
cat(sprintf("\nPart B: budget closure -> %.2f kmol delivered pre-%.2f (%.0f %% of total)\n",
            D_pre, t0, 100 * D_pre / BOMB_TOTAL_REF_KMOL))
if (D_pre <= 0) stop("Budget closure failed: fitted t0 burden exceeds the reference total.")

# monthly axis from the zero anchor to t0
mt <- seq(BOMB_EXCESS_ZERO_YR + 1 / 24, t0, by = 1 / 12)

# bomb excess D14C: Table 1 global column minus the pre-bomb Suess baseline,
# anchored to zero at BOMB_EXCESS_ZERO_YR.
# Anchors are restricted to t <= t0: Table 1 turns over after 1963 and a
# monotone interpolator cannot span the peak. monoH.FC (monotone Hermite)
# rather than a natural spline because the buildup must not overshoot -- the
# same trap that inflated the bomb total 4.3 % in DATA.md sec.6, and it
# tolerates the 1959-1960 tie that "hyman" rejects.
keep <- !is.na(t1$d14c_global) & t1$t <= t0
anch <- data.frame(t = c(BOMB_EXCESS_ZERO_YR, t1$t[keep]),
                   x = c(0, t1$d14c_global[keep] - BOMB_PREBOMB_D14C))
d14c_ex <- stats::splinefun(anch$t, anch$x, method = "monoH.FC")(mt)
d14c_ex[d14c_ex < 0] <- 0

# tropospheric carbon inventory, Telegadas' troposphere, on the ice-core CO2 spline
co2s <- as.data.frame(readRDS(file.path(OUT, "obs_icecore.rds"))$co2_spline)
chi  <- stats::approx(co2s$year, co2s$co2_ppm, xout = mt, rule = 2)$y
mol_air_trop <- (BOMB_TOTAL_AIR_KG - BOMB_STRAT_AIR_KG) / BOMB_M_AIR_KG_MOL
N_C_trop <- mol_air_trop * chi * 1e-6                       # mol C
N14 <- (d14c_ex / 1000) * N_C_trop * ccx_const("R14_STD") / 1000   # kmol 14C

# input = dN14/dt + lambda*N14 ; lambda closes the budget in closed form.
dt   <- 1 / 12
dN   <- c(diff(N14), NA) / dt
dN[length(dN)] <- dN[length(dN) - 1]
intN <- sum(N14) * dt
lambda <- (D_pre - (N14[length(N14)] - N14[1])) / intN
pre_flux <- dN + lambda * N14

cat(sprintf("  tropospheric bomb 14C burden at %.2f: %.2f kmol\n", t0, N14[length(N14)]))
cat(sprintf("  implied cumulative uptake pre-%.2f: %.2f kmol (%.0f %% of pre-1963 delivery)\n",
            t0, D_pre - N14[length(N14)], 100 * (D_pre - N14[length(N14)]) / D_pre))
cat(sprintf("  budget-closing removal rate lambda = %.4f /yr  (1/lambda = %.2f yr)\n",
            lambda, 1 / lambda))

# INDEPENDENT check on lambda: gross air-sea exchange alone, at the 1962
# disequilibrium, with the surface ocean still near zero excess.
A_oc <- ccx_const("OCEAN_AREA_NH") + ccx_const("OCEAN_AREA_SH")
F_as <- BOMB_GROSS_AS_FLUX * A_oc                                   # mol C/yr
loss_as_1962 <- F_as * ccx_const("R14_STD") * (d14c_ex[length(d14c_ex)] / 1000) / 1000
lambda_as <- loss_as_1962 / N14[length(N14)]
cat(sprintf("  independent check: gross air-sea alone gives lambda_ocean = %.4f /yr (%.2f yr)\n",
            lambda_as, 1 / lambda_as))
cat(sprintf("    -> ocean accounts for %.0f %% of the budget-closing removal; the\n",
            100 * lambda_as / lambda))
cat("       remainder is the terrestrial biosphere, which is the expected split.\n")
if (any(pre_flux < 0))
  cat(sprintf("  WARNING: %d negative pre-1963 flux months (min %.4f kmol/yr)\n",
              sum(pre_flux < 0), min(pre_flux)))

# =====================================================================
# Join, normalise, save
# =====================================================================
full_t <- seq(BOMB_EXCESS_ZERO_YR + 1 / 24, BOMB_SERIES_END_YR + 11.5 / 12, by = 1 / 12)
flux <- ifelse(full_t < t0,
               stats::approx(mt, pre_flux, xout = full_t, rule = 2)$y,
               strat_flux(full_t))
flux[flux < 0] <- 0

released <- sum(flux) / 12
truncated <- BOMB_TOTAL_REF_KMOL - released
cat(sprintf("\nJoin: %.2f kmol on the %.0f-%.0f axis; %.2f kmol (%.1f %%) is the post-%.0f\n",
            released, BOMB_EXCESS_ZERO_YR, BOMB_SERIES_END_YR, truncated,
            100 * truncated / BOMB_TOTAL_REF_KMOL, BOMB_SERIES_END_YR))
cat("      stratospheric tail, redistributed by the unit-integral normalisation.\n")

shape <- flux / (sum(flux) / 12)      # unit integral in years
out <- data.frame(t = full_t,
                  year = floor(full_t),
                  month = as.integer(round((full_t - floor(full_t)) * 12 + 0.5)),
                  shape_per_yr = shape)
attr(out, "provenance") <- list(
  source = "Tans (1981) SCOPE 16 pp.131-157, Tables 1 and 2 (Table 2 after Telegadas 1971)",
  method = "hybrid measured input function: Table 2 stratospheric decrease (>=1963.04) + budget-closed Table 1 tropospheric inventory (<1963.04)",
  strat_fit = list(A1 = A1, tau1 = tau1, A2 = A2, tau2 = tau2, t0 = t0,
                   burden_t0_kmol = I_t0, rmse_kmol = rmse,
                   dropped_first_point = BOMB_T2_DROP_FIRST),
  pre1963 = list(delivered_kmol = D_pre, lambda_per_yr = lambda,
                 lambda_ocean_only = lambda_as,
                 prebomb_baseline_permil = BOMB_PREBOMB_D14C,
                 zero_anchor_year = BOMB_EXCESS_ZERO_YR),
  total_ref_kmol = BOMB_TOTAL_REF_KMOL,
  truncated_frac = truncated / BOMB_TOTAL_REF_KMOL,
  built = Sys.Date())
saveRDS(out, BOMB_OUT_FILE)
cat(sprintf("\nwrote %s (%d months, %.0f-%.0f)\n", BOMB_OUT_FILE, nrow(out),
            min(out$year), max(out$year)))

# =====================================================================
# Diagnostics: annual delivery, new vs superseded placeholder
# =====================================================================
ann <- tapply(shape, out$year, function(z) sum(z) / 12)   # fraction of total per yr
old_sh <- c(0.2,0.3,0,0.4,0.2,0,0.9,1.2,0.9,4,2,3.5,3,8,0,0.2,15,22,1.5,0.4,0.3,
            0.6,0.5,0.6,0.3,0.5,0.3,0.2,0.3,0.4,0.1,0.3,0.1,0.1,0,0.2)
old_yr <- 1945:1980; old_w <- old_sh / sum(old_sh)
cat("\nAnnual delivery to the troposphere, share of total:\n")
cat(sprintf("%6s %8s %8s\n", "year", "NEW", "OLD"))
for (y in 1958:1968) {
  n <- if (as.character(y) %in% names(ann)) ann[[as.character(y)]] else 0
  o <- if (y %in% old_yr) old_w[old_yr == y] else 0
  cat(sprintf("%6d  %7.1f%% %7.1f%%\n", y, 100 * n, 100 * o))
}
pk <- out$t[which.max(shape)]
cat(sprintf("\nPeak delivery: %.3f  (DESIGN sec.6 gates the observed D14C peak at 1963.625;\n", pk))
cat("               delivery must peak at or before the concentration peak)\n")
cat(sprintf("Pre-1963 share: NEW %.0f %%, OLD %.0f %%\n",
            100 * sum(shape[full_t < t0]) / 12, 100 * sum(old_w[old_yr < 1963])))
