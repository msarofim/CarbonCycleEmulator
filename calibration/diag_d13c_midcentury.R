# =====================================================================
# diag_d13c_midcentury.R -- WHAT KIND OF CARBON IS THE MID-CENTURY SWING?
#
# handoff 21d sec.10a leaves ONE open question: whether the mid-century CO2
# feature is real atmosphere or an enclosure artefact common to the whole Law
# Dome site. TEST 1 ruled out core-SPECIFIC artefacts; it cannot rule out a
# shared firn process, and there is no independent core on disk.
#
# THE DISCRIMINATOR IS ALREADY ON DISK AND IS NOT IN THE OBJECTIVE.
# data/obs_icecore.rds carries 105 Law Dome d13C samples (Rubino et al. 2019,
# the repo's own confirmed source), 37 of them in 1900-1960, stated errors
# 0.01-0.19 permil. R/likelihood.R scores co2_icecore and NO ice d13C term:
# the only d13C levels in the objective start in 1978.
#
# WHY d13C SEPARATES THE HYPOTHESES. The candidate causes of a CO2 residual
# carry DIFFERENT isotopic signatures:
#
#   emissions-inventory error  fossil ~ -28, biomass ~ -25 permil
#                              -> CO2 and d13C move together, LARGE signal
#   land sink anomaly          photosynthetic discrimination ~ -18 permil
#                              -> CO2 down, d13C UP strongly
#   ocean sink anomaly         air-sea equilibrium ~ -2 permil, and isotopic
#                              equilibration is ~10x slower than chemical
#                              -> CO2 moves with ALMOST NO d13C signature
#   firn / sampling artefact   firn diffusion is near species-INDEPENDENT, so a
#                              smoothing or sampling artefact PRESERVES the
#                              atmosphere's own ratio -> the residual ratio is
#                              UNCHANGED from its neighbouring windows
#
# So the statistic is the RATIO of the d13C residual to the CO2 residual, window
# by window, from the SAME core set -- and the mid-century window is compared to
# its own neighbours rather than to an absolute expectation, which cancels any
# constant model bias in either species.
#
# PRE-REGISTERED, because with 3-14 samples per decade a free choice of window
# would be a garden of forking paths:
#   - 20-year windows, fixed below in DM_WINDOWS, chosen for sample count only.
#   - The test window is 1940-1960 (where GATE 1 of diag_swing_estimator.R puts
#     the raw growth-rate minimum); the reference windows are those either side.
#   - The verdict is read off the SIGN and MAGNITUDE of the ratio change, and
#     "no significant change" is a REAL RESULT that closes sec.12c's programme.
#
# Usage:  Rscript calibration/diag_d13c_midcentury.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

DM_MODE_FILE <- file.path("calibration", "output", "pump_arms", "mode_fit_pumpN.rds")
DM_YEARS     <- c(1750, 2024)
DM_WINDOWS   <- list(c(1860, 1900), c(1900, 1920), c(1920, 1940),
                     c(1940, 1960), c(1960, 1980), c(1980, 1994))
DM_TEST_WIN  <- c(1940, 1960)
DM_MIN_N     <- 3
# endmember signatures, permil, for reading the ratio (see header)
DM_SIG_FOSS  <- -28.0
DM_SIG_BIO   <- -25.0
DM_SIG_LAND  <- -18.0
DM_SIG_OCEAN <-  -2.0
# GATE 5 mutation: the LUC pulse a terrestrial explanation of the swing needs
DM_MUT_WIN   <- c(1930, 1965)
DM_MUT_SCALE <- 1.60
# Law Dome air-age spectral width, Trudinger et al. (2002b) via Bastos et al.
# (2016) sec.2.1: 4.5 yr DE08/DE08-2, 5.8 DSS, 7.0 DSSW20K. One width is used
# for the clustering because the windows mix cores; 5.0 is the sample-weighted
# mean over the 1940-1960 window. Larger widths give FEWER independent draws
# and a LARGER sigma, so 5.0 is the conservative end of the published range.
DM_SPECTRAL_WIDTH <- 5.0

md <- readRDS(DM_MODE_FILE); pm <- md$par_mode
p <- ccx_default_params()
for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pm[[n]]
p$pump_mode <- md$pump_mode
sp <- ccx_spinup(p)
F  <- ccx_build_forcing("historical", DM_YEARS, prod_c14 = sp$prod_c14,
                        bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale)
o  <- ccx_run_fast(sp, F)$out
# Law Dome is ANTARCTIC -- SH box for both species (see diag_ice_hemisphere.R)
mco2 <- function(yr) stats::approx(o$t, o$co2_SH,  xout = yr, rule = 2)$y
md13 <- function(yr) stats::approx(o$t, o$d13c_SH, xout = yr, rule = 2)$y

ic <- readRDS(file.path("data", "obs_icecore.rds"))
c2 <- as.data.frame(ic$co2_samples);  c2$year <- as.numeric(c2$age_CO2)
d3 <- as.data.frame(ic$d13c_samples); d3$year <- as.numeric(d3$age_CO2)
c2 <- c2[!is.na(c2$year), ]; d3 <- d3[!is.na(d3$year), ]
c2$core <- sub("[ ].*$", "", c2$SampleID); d3$core <- sub("[ ].*$", "", d3$SampleID)

cat(sprintf("mode %s\n", basename(DM_MODE_FILE)))
cat(sprintf("  CO2  samples %d over %d-%d\n", nrow(c2), min(c2$year), max(c2$year)))
cat(sprintf("  d13C samples %d over %d-%d   (NOT in the objective)\n",
            nrow(d3), min(d3$year), max(d3$year)))
cat(sprintf("  d13C stated error %.2f-%.2f permil\n\n",
            min(d3$d13CO2err), max(d3$d13CO2err)))

# ---- GATE 1: residuals and their ratio, window by window --------------
cat("GATE 1 -- model-minus-ice residuals by window, and their RATIO\n")
cat(sprintf("  %-11s %4s %9s %4s %9s %9s %10s\n",
            "window", "nC", "dCO2", "nI", "dd13C", "se(d13C)", "permil/ppm"))
rows <- data.frame()
for (w in DM_WINDOWS) {
  kc <- c2$year >= w[1] & c2$year < w[2]
  ki <- d3$year >= w[1] & d3$year < w[2]
  if (sum(kc) < DM_MIN_N || sum(ki) < DM_MIN_N) next
  rc <- mean(mco2(c2$year[kc]) - c2$CO2ppm[kc])
  ri <- mean(md13(d3$year[ki]) - d3$d13CO2[ki])
  # se ON n_eff, NOT n. VALIDATED AND CORRECTED 2026-08-23 after Bastos et al.
  # (2016) sec.1 quoted Francey et al. (1995): Law Dome d13C "scatter and
  # uncertainty in the data are relatively high and they affect how well it is
  # possible to partition the biospheric and oceanic fluxes", and recorded
  # Trudinger et al. (2002a) finding the terrestrial explanation's d13C peak
  # inconsistent with measurements "although the differences are not large
  # compared to the measurement uncertainties" -- in direct tension with the
  # 12.7 sigma this file used to report.
  #
  # THE DEFECT: sd/sqrt(n) treats every sample as an independent draw of the
  # atmosphere. They are not. Bastos sec.2.1 gives Law Dome's air-age spectral
  # width as 4.5 yr (DE08, DE08-2), 5.8 (DSS) and 7.0 (DSSW20K) -- samples
  # closer together than that measure OVERLAPPING air-age distributions. The
  # 1940-1960 window's 13 samples sit in four tight groups (1957-58, 1955,
  # 1947-50, 1940-41) spanning 18 yr: span/width = 3.6 independent draws, and
  # clustering at one width gives 2. Not 13. This is the same non-independence
  # the 2026-08-22 panel flagged for the CO2 ice term, in the isotope term.
  yrs <- sort(d3$year[ki])
  n_eff <- max(1L, sum(diff(yrs) > DM_SPECTRAL_WIDTH) + 1L)
  se <- stats::sd(md13(d3$year[ki]) - d3$d13CO2[ki]) / sqrt(n_eff)
  rows <- rbind(rows, data.frame(lo = w[1], hi = w[2], nc = sum(kc), ni = sum(ki),
                                 dco2 = rc, dd13 = ri, se = se, n_eff = n_eff,
                                 ratio = ri / rc))
  cat(sprintf("  %d-%-6d %4d %+9.2f %4d %+9.3f %9.3f %+10.4f\n",
              w[1], w[2], sum(kc), rc, sum(ki), ri, se, ri / rc))
}

# ---- GATE 2: is the test window's ratio different from its neighbours? -
tw <- rows$lo == DM_TEST_WIN[1] & rows$hi == DM_TEST_WIN[2]
nb <- !tw
cat(sprintf("\nGATE 2 -- test window %d-%d vs its neighbours\n", DM_TEST_WIN[1], DM_TEST_WIN[2]))
if (!any(tw)) {
  cat("  test window has too few samples -- INCONCLUSIVE\n")
} else {
  r_t <- rows$ratio[tw]; r_n <- rows$ratio[nb]
  cat(sprintf("  test window ratio      %+.4f permil/ppm\n", r_t))
  cat(sprintf("  neighbour ratios       %s\n",
              paste(sprintf("%+.4f", r_n), collapse = "  ")))
  cat(sprintf("  neighbour mean +/- sd  %+.4f +/- %.4f\n", mean(r_n), stats::sd(r_n)))
  cat(sprintf("  departure              %+.2f sd of the neighbour spread\n",
              (r_t - mean(r_n)) / stats::sd(r_n)))
}

# ---- GATE 3: what the d13C residual WOULD be under each hypothesis ----
cat("\nGATE 3 -- predicted d13C residual for the observed CO2 residual\n")
if (any(tw)) {
  dc <- rows$dco2[tw]; co2b <- mean(mco2(seq(DM_TEST_WIN[1], DM_TEST_WIN[2])))
  d13b <- mean(md13(seq(DM_TEST_WIN[1], DM_TEST_WIN[2])))
  cat(sprintf("  CO2 residual %+.2f ppm on a %.1f ppm background at %.2f permil\n",
              dc, co2b, d13b))
  for (nm in c("fossil", "biomass/LUC", "land sink", "ocean sink")) {
    sg <- switch(nm, "fossil" = DM_SIG_FOSS, "biomass/LUC" = DM_SIG_BIO,
                 "land sink" = DM_SIG_LAND, "ocean sink" = DM_SIG_OCEAN)
    # mass balance: adding dc ppm of carbon at signature sg to the background
    pred <- dc * (sg - d13b) / (co2b + dc)
    cat(sprintf("    %-14s (%+5.1f permil)  predicts %+7.3f permil  [obs %+7.3f, se %.3f]\n",
                nm, sg, pred, rows$dd13[tw], rows$se[tw]))
  }
  cat(sprintf("\n  detectability: stated d13C error %.2f permil, n = %d, se = %.3f\n",
              mean(d3$d13CO2err[d3$year >= DM_TEST_WIN[1] & d3$year < DM_TEST_WIN[2]]),
              rows$ni[tw], rows$se[tw]))
}

# ---- GATE 4: THE EXCURSION TEST (the sound version of GATE 2) ---------
# GATE 2's ratio is UNSTABLE by construction: the CO2 residual passes through
# zero inside the test window (-0.77 ppm), so dividing by it inflates the ratio
# and the "+5.70 sd" there is an artefact of the denominator, NOT evidence.
# Do NOT quote GATE 2's departure.
#
# The sound statistic does not divide. The CO2 residual CHANGES by a large
# amount across the mid-century; if that change is real carbon, it carries an
# isotopic signature and the d13C residual must show a matching EXCURSION away
# from its own trend. So: fit the d13C residual's trend on the windows OUTSIDE
# the mid-century, predict the test window, and compare the observed departure
# against what each hypothesis requires.
cat("\nGATE 4 -- EXCURSION test (GATE 2's ratio is confounded; this is not)\n")
mid <- which(rows$lo == DM_TEST_WIN[1])
out <- setdiff(seq_len(nrow(rows)), mid)
rows$mid_yr <- (rows$lo + rows$hi) / 2
tr <- stats::lm(dd13 ~ mid_yr, data = rows[out, ])
pred <- stats::predict(tr, newdata = rows[mid, ])
resid_mid <- rows$dd13[mid] - pred
cat(sprintf("  d13C residual by window: %s permil\n",
            paste(sprintf("%+.3f", rows$dd13), collapse = " ")))
cat(sprintf("  CO2  residual by window: %s ppm\n",
            paste(sprintf("%+.2f", rows$dco2), collapse = " ")))
cat(sprintf("\n  the d13C residual is MONOTONE; the CO2 residual CHANGES SIGN.\n"))
cat(sprintf("  d13C trend fitted off the mid-century windows: %+.4f permil/yr\n",
            stats::coef(tr)[2]))
cat(sprintf("  predicted at %d-%d: %+.3f    observed: %+.3f    excursion: %+.3f permil\n",
            DM_TEST_WIN[1], DM_TEST_WIN[2], pred, rows$dd13[mid], resid_mid))
cat(sprintf("  se of the observed window mean: %.3f permil\n", rows$se[mid]))

# how much CO2 residual CHANGE has to be explained, and what it would cost
dchange <- rows$dco2[max(out[out > mid])] - rows$dco2[max(out[out < mid])]
co2b <- mean(mco2(seq(DM_TEST_WIN[1], DM_TEST_WIN[2])))
d13b <- mean(md13(seq(DM_TEST_WIN[1], DM_TEST_WIN[2])))
cat(sprintf("\n  CO2 residual CHANGE across the mid-century: %+.2f ppm\n", dchange))
cat(sprintf("  %-14s %10s %10s %10s\n", "hypothesis", "requires", "observed", "sigma"))
for (nm in c("fossil", "biomass/LUC", "land sink", "ocean sink")) {
  sg <- switch(nm, "fossil" = DM_SIG_FOSS, "biomass/LUC" = DM_SIG_BIO,
               "land sink" = DM_SIG_LAND, "ocean sink" = DM_SIG_OCEAN)
  req <- dchange * (sg - d13b) / co2b
  cat(sprintf("  %-14s %+10.3f %+10.3f %10.1f\n", nm, req, resid_mid,
              abs(req - resid_mid) / rows$se[mid]))
}
cat("\n  READ: a carbon-mass explanation of the CO2 swing REQUIRES a d13C\n")
cat("  excursion of the size in column 1. The observed excursion is column 2.\n")

# ---- GATE 5: MUTATION TEST -- can this gate detect what it claims? ----
# GATE 4 returns a NEGATIVE, and a negative from an insensitive instrument is
# worthless. So: inject the carbon a terrestrial explanation would need, and
# confirm the d13C residual actually moves by the predicted amount. If it does
# not, GATE 4 is inert and its verdict must be discarded.
cat("\nGATE 5 -- MUTATION: inject the LUC pulse that closes the CO2 swing\n")
Fm <- F
kk <- Fm$year >= DM_MUT_WIN[1] & Fm$year < DM_MUT_WIN[2]
Fm$e_luc_NH[kk] <- Fm$e_luc_NH[kk] * DM_MUT_SCALE
Fm$e_luc_SH[kk] <- Fm$e_luc_SH[kk] * DM_MUT_SCALE
om <- ccx_run_fast(sp, Fm)$out
mco2m <- function(yr) stats::approx(om$t, om$co2_SH,  xout = yr, rule = 2)$y
md13m <- function(yr) stats::approx(om$t, om$d13c_SH, xout = yr, rule = 2)$y
cat(sprintf("  LUC x %.2f over %d-%d (adds %.1f GtC)\n", DM_MUT_SCALE,
            DM_MUT_WIN[1], DM_MUT_WIN[2],
            sum((Fm$e_luc_NH[kk] + Fm$e_luc_SH[kk]) -
                (F$e_luc_NH[kk] + F$e_luc_SH[kk])) / 12))
cat(sprintf("  %-11s %10s %10s %10s %10s\n", "window", "dCO2 base", "dCO2 mut", "dd13 base", "dd13 mut"))
for (i in seq_len(nrow(rows))) {
  w <- c(rows$lo[i], rows$hi[i])
  kc <- c2$year >= w[1] & c2$year < w[2]; ki <- d3$year >= w[1] & d3$year < w[2]
  cat(sprintf("  %d-%-6d %+10.2f %+10.2f %+10.3f %+10.3f\n", w[1], w[2],
              mean(mco2(c2$year[kc]) - c2$CO2ppm[kc]),
              mean(mco2m(c2$year[kc]) - c2$CO2ppm[kc]),
              mean(md13(d3$year[ki]) - d3$d13CO2[ki]),
              mean(md13m(d3$year[ki]) - d3$d13CO2[ki])))
}
kt <- d3$year >= DM_TEST_WIN[1] & d3$year < DM_TEST_WIN[2]
kct <- c2$year >= DM_TEST_WIN[1] & c2$year < DM_TEST_WIN[2]
dco2_moved <- mean(mco2m(c2$year[kct])) - mean(mco2(c2$year[kct]))
dd13_moved <- mean(md13m(d3$year[kt])) - mean(md13(d3$year[kt]))
cat(sprintf("\n  in the test window the mutation moved CO2 %+.2f ppm and d13C %+.3f permil\n",
            dco2_moved, dd13_moved))
cat(sprintf("  ratio %.4f permil/ppm; GATE 4 assumed %.4f for biomass/LUC\n",
            dd13_moved / dco2_moved, (DM_SIG_BIO - d13b) / co2b))
cat(sprintf("  => the gate is %s: %.1f se of d13C signal per ppm of CO2 signal\n",
            if (abs(dd13_moved / rows$se[mid]) > 3) "LIVE" else "INERT",
            abs(dd13_moved) / rows$se[mid]))

# ---- GATE 6: THE VERDICT, on the MEASURED transfer ratio ---------------
# GATE 5 measured -0.0239 permil/ppm where GATE 4's closed-box mass balance
# assumed -0.0571 -- a factor of 2.4. The analytic number is wrong because the
# atmosphere is not closed: the injected carbon partly leaves for the ocean and
# land, and air-sea ISOTOPIC exchange damps the d13C perturbation faster than it
# damps the CO2 one. So GATE 4's sigmas are inflated ~2.4x and must not be
# quoted. The measured ratio is the honest denominator, and it is measured
# THROUGH THE MODEL'S OWN MACHINERY, so it already carries the damping.
cat("\nGATE 6 -- VERDICT on the MEASURED transfer ratio (supersedes GATE 4)\n")
ratio_meas <- dd13_moved / dco2_moved
req_meas   <- dchange * ratio_meas
cat(sprintf("  measured transfer ratio (GATE 5)      %+.4f permil/ppm\n", ratio_meas))
cat(sprintf("  CO2 residual change to be explained   %+.2f ppm\n", dchange))
cat(sprintf("  => a LUC/terrestrial explanation requires %+.3f permil of d13C excursion\n",
            req_meas))
cat(sprintf("     observed excursion                     %+.3f +/- %.3f permil\n",
            resid_mid, rows$se[mid]))
cat(sprintf("     [sigma is on n_eff, not n -- see the DM_SPECTRAL_WIDTH block.\n"))
cat(sprintf("      THE ERROR BUDGET, and what is still missing:\n"))
cat(sprintf("        1. sampling, on n_eff        the sigma quoted here\n"))
cat(sprintf("        2. trend-prediction error    ~0.006 permil, SUBDOMINANT, folded in\n"))
cat(sprintf("           by quadrature it moves the verdict by <0.1 sigma\n"))
cat(sprintf("        3. SYSTEMATIC / calibration  UNQUANTIFIED. Francey et al. (1995)\n"))
cat(sprintf("           via Bastos (2016) warn d13C errors can make terrestrial and\n"))
cat(sprintf("           oceanic fluxes spurious and correlated. A CONSTANT offset\n"))
cat(sprintf("           cancels in this excursion by construction, and a LINEAR drift\n"))
cat(sprintf("           is absorbed by the fitted trend -- so what survives is a\n"))
cat(sprintf("           NON-LINEAR calibration drift localised near mid-century.\n"))
cat(sprintf("           Nothing here bounds it.\n"))
cat(sprintf("        n_eff ESTIMATOR SENSITIVITY: clustering at one spectral width\n"))
cat(sprintf("        gives 2 draws; span/width gives 3.6. The verdict spans ~5-7\n"))
cat(sprintf("        sigma across that choice. QUOTE THE RANGE, not a point.\n"))
cat(sprintf("     departure                              %.1f sigma\n",
            abs(req_meas - resid_mid) / rows$se[mid]))
cat("\n  CAVEAT that has to ride with this. The test assumes the model's d13C is\n")
cat("  a fair probe. Memory ccx_d13c_suess records the d13C Suess overshoot as\n")
cat("  STRUCTURAL, and the monotone -0.0014 permil/yr drift in GATE 4 is very\n")
cat("  likely it. A real mid-century signal could in principle be cancelled by\n")
cat("  that bias -- but the bias is linear in time and the signal would have to\n")
cat("  be equal, opposite and localised to cancel. That is not generic, and it\n")
cat("  is itself testable by re-running this against an independent d13C\n")
cat("  product. Do NOT read this as 'the swing is not carbon'; read it as 'no\n")
cat("  terrestrial or emissions explanation of the swing survives the isotopes'.\n")
