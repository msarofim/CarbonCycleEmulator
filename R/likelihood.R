# =====================================================================
# likelihood.R — compare a model run to the observations.
#
# Design notes that matter for interpreting posteriors:
#
# 1. ANNUAL RESOLUTION, INDEPENDENT ERRORS -- NOT AR(1). (Changed 2026-08-11;
#    the AR(1) scheme it replaces is described in, and kept runnable by,
#    ccx_ll_ar1_SUPERSEDED().)
#
#    The original problem was real: ~1500 monthly CO2 observations against ~17
#    parameters would swamp every other constraint if treated as independent,
#    and they plainly are not independent. The AR(1) fix was worse than the
#    problem. Model-data residuals are dominated not by noise but by slowly
#    varying MODEL DISCREPANCY -- measured lag-1 autocorrelation 0.998 at MLO
#    and 0.9998 at SPO -- so a calibrated rho ran to the bound and reclassified
#    that discrepancy as free correlated noise. Measured at the 2026-08-10 mode:
#
#      rho     n_eff (of 812 MLO monthly)   log-units lost to a +50 ppm bias
#      0.998                          0.8                              13.7
#      0.95                          20.8                           3,390.7
#      0       (independent)          812                       1,274,217.9
#      annual means, sd 2 ppm          69                          27,461.7
#
#    At the mode, 67 years of the Keeling curve carried the weight of LESS THAN
#    ONE independent observation, and a 50 ppm level error cost 13.7 log-units.
#    That is why the mode had q10 = 0.28 and kz at the solver wall: nothing was
#    holding them. See CHANGELOG 2026-08-11.
#
#    The replacement addresses the swamping directly instead of via a fitted
#    nuisance parameter. Dense series are reduced to ANNUAL values scored with
#    INDEPENDENT errors, so the effective sample size is set by the data's real
#    information content (69 years for MLO) rather than by an autocorrelation
#    parameter free to decide the data barely count. The seasonal cycle, which
#    annual means discard and which is the only thing seas_amp_*/seas_phase_*
#    exist to fit, comes back as an EXPLICIT statistic -- two harmonic
#    coefficients per station -- rather than as 812 monthly likelihood terms.
#
#    A side benefit: the AR(1) was applied on OBSERVATION INDEX, not time, so a
#    16-month SPO gap was treated as a 1-month step. Annual values make the
#    sampling regular by construction.
#
# 1b. THE SAME ESTIMATOR RUNS ON MODEL AND OBSERVATIONS. ccx_year_harmonic()
#    fits, per calendar year, `v ~ 1 + (t - midyear) + sin(2*pi*phi) +
#    cos(2*pi*phi)`. Its intercept is a deseasonalised, detrended annual level
#    that is immune to partial month coverage (SPO has 8 sparse years, and the
#    DESIGN 6 note records raw partial-year means shifting the 1950s by
#    -0.77 ppm); its sin/cos coefficients are the seasonal statistic. Applying
#    one estimator to both sides means neither NOAA's deseasonalisation method
#    nor the model's seasonal shape has to be trusted separately.
#
# 1c. D14C IS REDUCED TO ANNUAL MEANS FOR THE SAME REASON. The Hua et al. (2022)
#    zonal record is a SMOOTHED MONTHLY COMPILATION fitted to sparser discrete
#    samples (DATA.md), so its 939 monthly values per hemisphere are not 939
#    independent measurements. Leaving them monthly while thinning CO2 would
#    have relocated the swamping, not removed it. Annual means keep the bomb
#    spike's amplitude and decay -- the ventilation signal -- and only discard
#    sub-annual structure the compilation interpolated in anyway. The monthly
#    error terms are NOT reduced by sqrt(n) on averaging, because the dominant
#    term is systematic representation error (note 3), not measurement noise.
#
# 2. GCB SINKS ARE A PARTITION CONSTRAINT, NOT A GROWTH ONE. Atmospheric growth
#    is already pinned by the CO2 series, so using GCB's full budget again would
#    double-count. Only the OCEAN sink enters at its stated uncertainty; the LAND
#    sink is deliberately given inflated uncertainty (Marcus, Q1 default).
#
# 3. D14C ZONE AGGREGATION CARRIES REPRESENTATION ERROR LARGER THAN THE
#    MEASUREMENT ERROR. Hua's five zones are bounded by the polar jet and the
#    tropical low-pressure belt -- not latitude circles -- and those boundaries
#    move seasonally and with longitude. Aggregating them to two hemispheric
#    boxes therefore has no uniquely right weighting. Measured spread across
#    defensible schemes: 21-26 permil during the bomb peak, ~4 permil after
#    1970, against Hua's reported sd of 0.5-6.7 permil. That spread is added in
#    quadrature rather than ignored, otherwise the bomb peak would dominate the
#    posterior on the strength of a weighting choice.
#
# 4. STATION-VS-BOX REPRESENTATION ERROR. MLO is not the NH mean and SPO is not
#    the SH mean. A fixed representation term is added to the CO2 error model.
#
# 5. THE OCEAN EXCESS-14C INVENTORY IS A CONSTRAINT THE D14C SERIES CANNOT GIVE.
#    Added 2026-08-11. Every other 14C term here is atmospheric, so the ocean's
#    ventilation is only ever inferred from how fast the atmosphere loses its
#    bomb spike -- and that can be bought with a larger bomb source instead of a
#    faster sink. Naegler & Levin (2006) give an observation-based ocean
#    inventory at two reference years, which prices the sink directly. See the
#    LIK_EXCESS_C14_* block for the definition traps, which are the whole story.
# =====================================================================

# ---- named constants -------------------------------------------------
# Area weights use the Hua et al. (2013) nominal band boundaries (NH1/NH2 at
# ~40 N, NH2/NH3 at ~15 N, NH3/SH at the Equator). Hua et al. (2022) refine the
# NH1/NH2 boundary to lie between 45.1 N and 48.0 N in north-western America and
# note it varies seasonally; that alternative is what the representation error
# below is calibrated against.
LIK_ZONE_BOUNDS_NH <- c(40, 15)      # degrees N
LIK_ZONE_BOUNDS_SH <- c(15)          # degrees S, SH3/SH1-2 split
LIK_D14C_REP_BOMB  <- 25             # permil, 1955-1970 (weighting spread)
LIK_D14C_REP_OTHER <- 4              # permil, elsewhere
LIK_D14C_BOMB_WIN  <- c(1955, 1970)
# THE WHOLE sd OF THE CO2 LEVEL STREAM, since 2026-08-15 (review item 6b).
# It was the fixed half of sqrt(sigma_co2^2 + LIK_CO2_REP_ERR^2); `sigma_co2`
# is retired (R/calibrate.R) and this constant now stands alone.
#
# ITS RECEIPT, which is why it was the half that survived: co-located
# INDEPENDENT programmes at Mauna Loa -- NOAA in-situ against SIO flask,
# n = 702 months -- disagree by 0.39-0.59 ppm RMS. That is a floor on
# measurement error alone, and a station-vs-hemispheric-BOX term must exceed
# it. 1.0 ppm is a plausible value for that quantity, measured on 2026-08-15
# (handoff sec.4.1). The retired `sigma_co2` had no comparable receipt.
#
# IT IS CONSERVATIVE, NOT TIGHT. The pooled annual level residual at the last
# mode is 0.614 ppm, so chi2/dof ~ 0.38: this stream is scored SOFTER than the
# fit it achieves. Lowering the constant would give the loudest stream in the
# objective MORE leverage and is a stream-WEIGHT change, not housekeeping --
# flagged in calibration/diag_sigma_co2.R and deliberately not taken.
LIK_CO2_REP_ERR    <- 1.0            # ppm, station-vs-hemispheric-box
LIK_D13C_REP_ERR   <- 0.05           # permil

# ---- STATION-vs-BOX LEVEL OFFSET (2026-08-18, Marcus) ---------------
# MLO and SPO are not exact measures of hemispheric concentration, so a LEVEL
# offset between the station and the model's box is physically expected. Until
# now the likelihood carried GRADIENT offsets and no level offset at all, which
# was an arbitrary asymmetry: nothing makes the MLO-SPO differential
# representable while the common mode is not.
#
# IT IS ONE PARAMETER FOR BOTH SPECIES, AND THAT IS THE WHOLE POINT.
# Representation is one physical thing -- the box holds continental boundary
# layer air the remote marine station never sees, carrying extra CO2 that is
# ISOTOPICALLY LIGHT. So it must move CO2 and d13C TOGETHER, in a ratio set by
# mass balance and the excess carbon's signature, not independently:
#
#   box = station + `rep_dC` ppm of carbon at LIK_REP_SOURCE_D13C
#   predicted station CO2  = model_box_CO2  - rep_dC
#   predicted station d13C = model_box_d13C - rep_dC (d_s - d13C_box) / CO2_box
#
# The d13C conversion is evaluated from the MODEL's own CO2 and d13C at each
# scored year rather than from a frozen background pair, so it cannot go stale.
#
# WHY A SHARED PARAMETER RATHER THAN A FREE d13C OFFSET, which is the entire
# reason this is safe: calibration/diag_station_representation.R measured the
# common-mode biases at the arm-N mode as CO2 -0.138 ppm and d13C +0.194 permil.
# The SIGN agrees -- the mechanism is real -- but mass balance says the measured
# CO2 bias predicts only +0.0064 permil of d13C. The measured d13C bias is
# 30.3x that. Explaining it as representation needs a -4.19 ppm CO2 offset,
# against a station-vs-box scale of 1.0 ppm. So the residue is STRUCTURAL (the
# Suess overshoot, project note d13c_suess_overshoot_structural), and a FREE
# d13C level offset would have swallowed it whole and reported a good fit.
# Tying the two species together means absorbing the d13C bias costs 4.2 sd on
# the prior AND is rejected by the CO2 level stream, which sees the same knob.
#
# ABSENCE CONTRACT, same as `deep` and the gradient offsets: a NULL `rep_dC`
# SKIPS the offset rather than defaulting it to zero -- except that here zero IS
# the no-offset behaviour, so absence and zero coincide numerically. The
# contract is kept anyway so every pre-2026-08-18 caller reproduces exactly.
LIK_REP_SOURCE_D13C <- -26.5         # permil, fossil+respired excess carbon.
                                     # Midpoint of [-25 respired, -28 fossil];
                                     # the bracket moves the conversion by 8 %,
                                     # far below the 30x this term is used to
                                     # adjudicate.
LIK_LAND_SINK_INFLATE <- 3.0         # multiplier on GCB land-sink sigma (Q1)

# ---- the mid-century discrepancy window (2026-08-23) ----------------
# OFF by default. See the block in ccx_loglik() for what it is and why it is
# not a tuning knob. The window brackets the published plateau with a small
# margin for the 4.5-7.0 yr air-age spectral width either side.
LIK_ICE_DISCREPANCY_WIN     <- c(1935, 1960)
LIK_ICE_DISCREPANCY_INFLATE <- as.numeric(Sys.getenv("CCX_ICE_DISCREPANCY", "1"))

# ---- INTERHEMISPHERIC GRADIENT (2026-08-15, review item 5) -----------
# DESIGN sec.6 gate 9 has said since it was written that the MLO-SPO gradient is
# "the main constraint on tau_ex". It was not in the objective at all: MLO and
# SPO were scored as two independent levels, which prices their difference only
# implicitly, at an effective sd of 1.41 ppm (1.45 before `sigma_co2` was
# retired on 2026-08-15; 2.55 at the old free sigma's prior median) against a
# model miss that never exceeded 1.3. Nothing had ever objected to it because
# nothing could. 66 % of tau_ex's leverage came instead from the seasonal
# harmonics -- the interhemispheric exchange time was being set by the shape of
# the Keeling sawtooth.
#
# ⚠ THAT 66 % IS ONLY THE LOWER JAW, MEASURED 2026-08-27h. It was written here
# on 2026-08-15 as the justification for adding this term, from a DOWNWARD
# profile, and downward it still holds overwhelmingly: at 0.79 tau_0 the cost is
# `co2_seasonal_SPO` -57.00 and `co2_seasonal_MLO` -28.31. UPWARD it inverts. At
# 1.26 tau_0 with the offsets re-optimised, the bill is annual-mean isotopes and
# levels -- d13c_level_MLO -20.43, d13c_level_SPO -14.44, d14c_NH -12.06,
# co2_level_MLO -9.54, d14c_SH -7.98, co2_gradient -7.49 -- while the FOUR
# SEASONAL ROWS NET ONLY -3.40 and `co2_seasonal_SPO` actively IMPROVES by
# +9.74. tau_ex sits in a two-sided vice with a different jaw on each side.
# Do not cite the 66 % for an upward move.
# Receipt: notes/collect_2026-08-27h_tau_ex_has_no_power_and_the_wrong_sign.md sec.2
#          (diag_tau_ex_seasonal_power.R; outputs/diagnostics/tau_ex_seasonal_power.rds).
#
# THE REASON THIS TERM CARRIES AN OFFSET PARAMETER. A two-box model's
# NH-box-minus-SH-box is NOT the quantity MLO minus SPO measures. MLO sits at
# 19.5 N, south of the northern mid-latitude source region, so the station
# gradient MUST come out smaller than the box gradient. Regressing
# obs ~ a + b*model over the paired years (calibration/diag_gradient_terms.R
# part 3) measures a = -0.39 (defaults) / -0.55 (MAP mode) ppm, stable across
# both and rejected from zero at 95 %, with the sign the physics predicts.
# Scoring the LEVEL against a fixed zero offset would force the model to absorb
# that representation constant into tau_ex and the hemispheric shares -- which
# is the "bound the observable, not the parameter" failure this project keeps
# finding. The offsets are therefore ESTIMATED (CCX_PARAM_TABLE$grad_off_*),
# the same move `luc_scale` makes for E_LUC uncertainty.
LIK_USE_GRADIENT <- TRUE
# Sigmas: THE MEASURED MODEL-VS-OBS SCATTER ABOUT A CONSTANT OFFSET, FLOORED BY
# THE OBSERVATIONS' OWN PRECISION. Neither is a round number chosen for feel.
#   CO2  -- scatter 0.272 (defaults) / 0.283 (mode) ppm. Observational floor:
#           Scripps and NOAA disagree about the annual gradient by 0.225 ppm
#           RMS, and that is a LOWER bound because `MLO` and `MLO_NOAA` in this
#           dataset are one series under two names (0.002 ppm RMS over 189
#           months) -- so 0.225 is the two SPO records alone, and doubling it in
#           quadrature for a comparable MLO term gives 0.318. Take 0.35.
#   d13C -- scatter 0.0196 / 0.0198 permil, floor 0.0152 (and THAT one is a
#           genuine two-station two-network comparison: the Scripps and NOAA
#           d13C records share no month timestamps at all). Take 0.025.
# Both terms therefore start near chi2/dof ~ 0.6: informative, not overfit, and
# not asserting the model resolves more than the data do.
LIK_GRAD_CO2_SD    <- 0.35           # ppm
LIK_GRAD_D13C_SD   <- 0.025          # permil
# The window is the paired record itself; no extra restriction. CO2 gives 59
# years (1962-2023) and d13C 43 (1980-2023) once ccx_year_harmonic()'s 9-month
# minimum has dropped the partial years -- including gate 9's 1950s entry, which
# rests on 8 paired MONTHS and which gate 9's own note calls indicative only.
#
# DOUBLE COUNTING, MEASURED AND ACCEPTED. These terms score information the two
# station-level terms already contain. The size of the overlap decides whether
# the honest form is an added term or a rotation of the (MLO, SPO) pair, and it
# was measured: the pair implies a gradient sd of 1.45 ppm, so a term at 0.35
# outweighs it ~17x in variance. The overlap is second-order and adding a term
# is correct; a rotation would rewrite the two highest-leverage streams to fix
# something that is not binding.
# RE-MEASURED 2026-08-15 on the retirement of `sigma_co2`, which was the one
# thing that could move this: the implied gradient sd goes 1.449 -> 1.414 ppm
# and the ratio 17.1x -> 16.3x. The conclusion is unchanged. Re-measure again
# if LIK_CO2_REP_ERR moves -- it is now the only input to it
# (calibration/diag_sigma_co2.R part 6).

# ---- annual reduction and the seasonal statistic (2026-08-11) --------
# A calendar year needs this many months for its harmonic fit (4 parameters:
# level, within-year trend, sin, cos). 9 leaves MLO 67 of 69 years and SPO 60
# of 68; the dropped years are the 1957-61 SPO start-up and partial end years.
LIK_ANNUAL_MIN_MONTHS <- 9L
# Window for the seasonal statistic. Starts at 1975 because that is when the
# SPO monthly record begins (the Scripps 1957-1975 SH record is unreachable --
# see CHANGELOG 2026-08-09), so both stations contribute over the same years.
LIK_SEAS_WINDOW <- c(1975, 2024)

# ---- WHICH AMPLITUDE ESTIMATOR REPORTS A SEASONAL CYCLE (2026-08-27, Marcus)
# The likelihood scores the per-year sin/cos COEFFICIENTS and never forms an
# amplitude, so this constant governs DIAGNOSTICS AND REPORTING ONLY -- no
# objective, no gate in the suite, moves.
#
# There are two ways to reduce a set of per-year harmonics (a_y, b_y) to one
# amplitude and they are not the same statistic:
#
#   "mean_vector"    |mean over years of (a, b)|   -- the coherent cycle
#   "mean_magnitude" mean over years of |(a, b)|   -- the cycle PLUS the
#                                                     year-to-year scatter
#
# mean_magnitude cannot separate a coherent cycle from interannual noise, and
# on the noisiest series in this problem the two disagree badly. Measured
# 2026-08-27d over LIK_SEAS_WINDOW, mean_magnitude / mean_vector:
#
#     MLO CO2 1.00x | MLO d13C 1.00x | SPO CO2 1.02x | SPO d13C 1.33x
#
# and all four MODEL series sit at 1.00x, because the model carries one fixed
# amplitude and phase and so has no scatter to inflate. The 1.33x therefore
# lands entirely in the DENOMINATOR of the SPO d13C-per-ppm partition residual,
# and mean_magnitude is the estimator that FLATTERS the model: it reports that
# residual as 1.48x where the noise-immune one reports 1.93x (1.93 / 1.33 =
# 1.45). ADOPTED: mean_vector, and the standing SPO partition target is 1.93x.
# See [[amp_definition_mismatch]] and notes/handoff_2026-08-27d.
CCX_SEAS_AMP_ESTIMATOR <- "mean_vector"

#' Reduce per-year first-harmonic coefficients to ONE semi-amplitude
#'
#' The single reduction applied to both observations and model output, for the
#' same reason ccx_year_harmonic() is the single harmonic estimator (design
#' note 1b): a residual between two series reduced by two different statistics
#' is not a residual.
#'
#' @param h data.frame from ccx_year_harmonic() (columns year, a, b).
#' @param years optional year vector to restrict to -- pass the OBSERVATIONS'
#'   own years when comparing a model series to them, so both sides reduce over
#'   exactly the same set.
#' @param estimator "mean_vector" (default, and the adopted one) or
#'   "mean_magnitude" (retained so a diagnostic can PRINT both and show the
#'   inflation rather than assert it).
#' @return the SEMI-amplitude in the series' own units; peak-to-peak is 2x it.
ccx_harmonic_amp <- function(h, years = NULL,
                             estimator = CCX_SEAS_AMP_ESTIMATOR) {
  estimator <- match.arg(estimator, c("mean_vector", "mean_magnitude"))
  k <- if (is.null(years)) seq_len(nrow(h)) else match(years, h$year)
  k <- k[!is.na(k)]
  if (!length(k)) return(NA_real_)
  a <- h$a[k]; b <- h$b[k]
  if (estimator == "mean_vector") sqrt(mean(a)^2 + mean(b)^2)
  else mean(sqrt(a^2 + b^2))
}

#' Peak month of the window-mean first harmonic, in the same month convention
#' the observational climatology diagnostics use (month 0 = 1 Jan).
#' a*sin(2*pi*phi) + b*cos(2*pi*phi) peaks at phi = atan2(a, b) / (2*pi).
ccx_harmonic_peak_month <- function(h, years = NULL) {
  k <- if (is.null(years)) seq_len(nrow(h)) else match(years, h$year)
  k <- k[!is.na(k)]
  if (!length(k)) return(NA_real_)
  ((atan2(mean(h$a[k]), mean(h$b[k])) / (2 * pi)) %% 1) * 12
}

# ---- d13C SEASONAL CYCLE (2026-08-18, Marcus priority rework item 3) --
# Scored from today. The d13C level block's old justification for not scoring
# it -- "a derived consequence of the same NEP harmonic the CO2 seasonal
# statistic already constrains, so scoring it again would double-count one
# mechanism" -- conflates two different claims. The CO2 cycle constrains the
# NEP harmonic's amplitude and phase; the d13C cycle measures that SAME flux
# through a DIFFERENT observable, whose amplitude carries the photosynthetic
# discrimination and the air-sea contribution on top. The RATIO of the two
# amplitudes is therefore an independent constraint the objective never had:
# measured 2026-08-18 at package defaults, NH ratio 0.0738 permil/ppm against
# MLO obs 0.178/3.02 = 0.0591 -- same order, not equal, i.e. information.
# Two instruments measuring two species is not one measurement scored twice.
#
# Sigma is the interannual sd of the OBSERVED harmonic coefficients, exactly
# as the CO2 seasonal statistic does it -- no free error scale (sigma_d13c is
# retired, and this stream never met it anyway).
LIK_USE_D13C_SEAS <- TRUE
# The seasonal constraint is scored PER YEAR -- each year's two first-harmonic
# coefficients are one observation pair -- with sigma set to the INTERANNUAL SD
# of those coefficients. Not the standard error of their multi-year mean: the
# model carries one fixed amplitude and phase, so year-to-year variation is
# structural discrepancy, and sigma has to cover it.
#
# Scoring the multi-year MEAN instead (4 terms in total) was tried and rejected:
# it made the seasonal cycle weaker than its own side effect. Measured at
# defaults, moving seas_amp_NH from 20 to 24 GtC/yr cost 1.2 log-units on the
# seasonal term but 6 on the CO2 LEVEL term, because a bigger seasonal cycle
# rectifies against the log CO2-fertilisation term and shifts the annual mean.
# The seasonal amplitude would then have been set by its rectification
# side-effect rather than by the seasonal cycle. Per-year scoring puts ~50 term
# pairs per station behind it and restores the intended ordering.

# BOMB-WINDOW D14C IS NOW INCLUDED (2026-08-10). It was excluded while the
# injection shape was a placeholder: a likelihood decomposition at the default
# parameters showed the two D14C streams contributing -165,214 of a -183,666
# total -- 90 % of ALL the information -- so calibrating against the peak would
# have let a placeholder drive essentially the entire posterior and laundered it
# into every parameter.
#
# That shape is now a measured stratosphere->troposphere delivery function built
# from Tans (1981) SCOPE 16 Tables 1-2 (DATA.md 9), so the window is admitted.
#
# CAVEAT that rides with it: at uncalibrated defaults the modelled NH peak is
# still +0.75 yr late against the area-weighted observed aggregate, and a 4.5x
# one-month step survives at the Part A / Part B join in 1963.04 -- inside this
# window. Both push on tau_ex and the ocean-uptake parameters. Treat any
# posterior shift in those specifically as suspect until the join is resolved.
LIK_USE_BOMB_WINDOW <- TRUE
LIK_BOMB_EXCLUDE    <- c(1950, 1975)   # window dropped when the switch is FALSE

# Law Dome stated errors are ANALYTICAL only (~0.02-1 ppm) and exclude gas-age
# and firn-smoothing uncertainty plus model-vs-ice representation error. Left
# uninflated, 255 ice samples at ~9 sigma each contributed -14,551 -- 8 % of the
# total from the sparsest, least direct record in the set.
LIK_ICE_REP_ERR <- 4.0               # ppm, added in quadrature
# GCB 2025's OWN stated 1-sigma uncertainties, quoted verbatim from the header
# of data-raw/downloads/gcb2025_global_budget.csv (MANIFEST.csv carries the URL,
# access date and SHA-256; Friedlingstein et al. 2025, doi:10.18160/GCP-2025):
#   "All uncertainties represent +/- 1 sigma error"
#   "The ocean sink (uncertainty of +/-0.4 GtC/yr on average)"
#   "The land sink (uncertainty of +/-0.5 GtC/yr on average)"
#   "Emissions from land-use change (uncertainty of +/-0.7 GtC/yr)"
#   "fossil fuel combustion and industrial processes (uncertainty of +/-5%)"
# LIK_GCB_LAND_SD was 0.9 from this term's creation until 2026-08-14, described
# in this file as "GCB stated land-sink uncertainty" while GCB states 0.5, with
# no provenance anywhere in the repo for the 0.9. Corrected to the cited value.
# This makes the term 1.8x stronger, which is a CHANGE TO THE OBJECTIVE and is
# recorded as such in CHANGELOG -- it is a constant tracking its source, not a
# reweighting. The soft-constraint POLICY is separate and unchanged: DESIGN sec.9
# Q1's inflation multiplier still rides on top (LIK_LAND_SINK_INFLATE).
LIK_GCB_OCEAN_SD   <- 0.4            # GtC/yr, GCB 2025 stated ocean-sink 1 sigma
LIK_GCB_LAND_SD    <- 0.5            # GtC/yr, GCB 2025 stated land-sink 1 sigma
# GCB 2025 stated 1 sigma on E_LUC, GtC/yr. Not used in the likelihood -- it is
# the receipt behind the luc_scale prior in calibrate.R, kept beside its
# siblings so the four numbers stay together and traceable to one header.
LIK_GCB_LUC_SD     <- 0.7            # GtC/yr
LIK_GCB_FOSS_FRAC  <- 0.05           # fraction, 1 sigma

# ---- ocean excess-14C inventory (2026-08-11; DATA.md 10) -------------
# Naegler & Levin (2006), Tables 2 and 4: the excess (= total minus natural)
# radiocarbon inventory of the ocean at the GEOSECS (1975) and WOCE (1995)
# reference years. This is the first constraint in the likelihood that prices
# the ocean 14C SINK directly rather than through the atmosphere's decline.
#
# THREE DEFINITION QUESTIONS, all measured rather than assumed
# (calibration/diag_excess_c14.R reproduces every number below):
#
# (a) WHAT IS "NATURAL"? The observational excess is total minus a
#     pre-anthropogenic natural component. The model's counterpart is the run
#     minus its own 1750 steady state, and the run's FIRST ROW *is* that steady
#     state by construction -- so the baseline is free, with no counterfactual
#     run and no doubling of the MCMC cost. Measured against the alternative (a
#     full no-fossil / no-LUC / no-bomb / no-nuclear counterfactual carrying the
#     observed GMST and ENSO) the two differ by 0.27 kmol at 1975 and 0.58 at
#     1995 -- under 1 % of the excess, against a ~16 kmol observational spread.
#     A counterfactual with the climate forcing also removed reproduces the
#     spinup state to 0.003 kmol, which is the fixed point behaving as it must.
#
# (b) BOMB-ONLY OR TOTAL? N&L's Table 4 model partition sums EXACTLY to their
#     cumulative bomb input at both years, i.e. it is a paired bomb-only
#     difference. Their observational estimates are not: Peacock and Key
#     separate natural from excess without being able to separate bomb from
#     Suess, and Mouchet (2013) puts the CO2 increase and the air-sea CO2 flux
#     at ~10 % each of the 1990 ocean bomb inventory. For the OCEAN the choice
#     turns out not to matter: the paired bomb-only difference is 72.6 / 94.3
#     kmol against 75.9 / 95.4 for total-minus-natural, a 1-4 % gap. (For the
#     LAND it matters a great deal -- see the LUC note in DATA.md 10.)
#
# (c) IS OUR kmol THE SAME kmol? Checked on the one row where N&L have real
#     observations. Rebuilding the ATMOSPHERIC excess from the CO2 and D14C
#     observations under this convention gives 37.3 kmol (1975) and 25.6 (1995)
#     against their troposphere-plus-stratosphere 35.6 and 21.7: agreement to
#     +4.8 % and +18.0 %. That is the basis for LIK_EXCESS_C14_REP_FRAC below --
#     it is a measured definitional/representation error, not a chosen one.
#     The check is one-sided in one respect: their stratosphere is a MODEL value
#     (only the troposphere row is observed), so part of the 1995 gap could be
#     their stratosphere rather than our convention. That is a reason to carry
#     the spread as uncertainty, not a reason to discount it.
LIK_USE_EXCESS_C14 <- TRUE
# WHICH observational target. The two sets differ by far more than the model
# does between definitions, so this switch matters more than anything above:
#   "table4_obs_range"  48.6 +/- 7.9 (1975), 51.4 +/- 7.6 (1995). The full
#                       Peacock-to-Key span corrected for missing ocean areas.
#   "table2_peacock"    43.9 +/- 4.3, 56.5 +/- 2.5. One method with its stated
#                       uncertainty -- roughly 3x tighter, and it implies a much
#                       steeper 1975->1995 uptake.
# DEFAULT IS THE WIDE ONE. The span between the two published reconstructions is
# method spread, not measurement noise, and adopting one of them as if the other
# did not exist would put leverage on a choice of paper rather than on data.
# FLAGGED FOR MARCUS -- see CHANGELOG 2026-08-11.
#
# THE "~130 LOG-UNITS" THAT USED TO BE ASSERTED HERE DOES NOT REPRODUCE, and it
# had no receipt anywhere in the repo. Measured 2026-08-14 at the current
# default and swept across bomb_total 80-130 kmol, the two target sets differ by
# 0.7-1.4 log-units, not 130 -- because the model's own excess inventory sits
# between them and both terms are weak there (-6 to -10). The DIRECTION of the
# argument survives (table2_peacock is ~3x tighter, so it constrains harder as a
# fit moves away from it) but the MAGNITUDE was pattern-matched, not measured.
# Either produce a receipt on whichever axis gives 130, or drop the number. The
# practical consequence is that this decision is CHEAPER than the review's
# ordering assumed: it is not a blocker on the refit.
LIK_EXCESS_C14_TARGET <- "table4_obs_range"
# The run's first row is the preindustrial steady state only if the run starts
# here. The term is SKIPPED, not silently mis-baselined, if it does not; the
# standard pipeline is gated by test-likelihood.R to make sure it is present.
LIK_EXCESS_C14_BASE_YEAR <- 1750
# Shared definitional/representation error, as a fraction of the target. Applied
# as a RANK-ONE common term across the two years rather than in quadrature per
# year, because it is a method bias: it moves 1975 and 1995 together, and
# treating it as independent would claim twice the information it carries.
# Set to cover the measured +4.8 % / +18.0 % spread of note (c) -- above their
# midpoint, deliberately, because only two comparisons exist and one of the two
# is against a modelled stratosphere.
LIK_EXCESS_C14_REP_FRAC <- 0.15

# ---- deep-ocean D14C (2026-08-14; GLODAPv2.2023) ---------------------
# The second term that prices the ocean 14C sink directly, and the FIRST that
# prices ocean VENTILATION rather than inventory. Until now nothing but d13C
# constrained `kz`, which is why it carries a hard bracket (calibrate.R).
#
# WHAT IT SCORES: the model's BOTTOM BOX (2627-3700 m at h_ml 75) against the
# cos(lat)-and-thickness-weighted GLODAPv2.2023 mean over the same depth range.
# NOT `d14c_deep_ocean`, which is the bottom THREE boxes (1313.6-3700 m) and
# runs 13-20 permil enriched -- see the note in spinup.R. The steady state is
# scored rather than a transient value because the bottom box moves 0.04 permil
# between 1750 and 2024 (measured, diag_deep_d14c_term.R), i.e. the layer is
# effectively pre-bomb and modern bottle data is a fair target for it.
#
# THE SIGMA IS A DECISION, NOT A MEASUREMENT, and it decides the kz question
# outright. 13i sec.A3 assumed GLODAPv2 would "supply a real spatial spread for
# the sigma". It supplies the spread; THE SPREAD IS NOT THE SIGMA. A one-box
# model is scored against the volume-weighted MEAN, whose uncertainty is the
# spread divided by an EFFECTIVE sample size -- and deep water masses are
# basin-coherent, so n_eff is of order tens, not the 3,592 filled cells.
# Measured against the kz runaway (kz -> 10,686, bottom box -120.9 permil):
#
#   sigma 3.0  permil  measurement error alone            18.1 sigma  HOLDS kz
#   sigma 10.3 permil  SE of the weighted mean, n_eff 20   5.3        HOLDS kz
#   sigma 20.5 permil  SE of the weighted mean, n_eff 5    2.7        HOLDS kz
#   sigma 45.9 permil  full spatial spread, n_eff 1        1.2        does NOT
#
# (Those z-scores are on the BOTTOM BOX. The handoff's 6.1 sigma for n_eff = 20
# was computed on the 3-box average against the 1-box target -- the same layer
# mismatch corrected here. The decision survives it: 5.3 still holds kz.)
#
# MARCUS 2026-08-14 CHOSE n_eff = 20, and with it chose to KEEP the kz bracket.
# The reasoning that made that non-obvious: the incumbent bracket [3830, 6200]
# is itself a hard box on this same quantity -- bottom box -220.4 to -163.5, a
# half-width of 28.4 permil -- i.e. TIGHTER than every sigma candidate but the
# most aggressive, so deleting it in favour of an "honest" likelihood term would
# LOOSEN the constraint, not tighten it. The bracket stays until a refit shows
# this term holding kz without it.
#
# THE TWO DISAGREE ABOUT WHERE INSIDE THE BRACKET kz BELONGS, and that is the
# term's actual content. The bracket is centred at -191.9 permil, 16.7 below the
# observation; this term's own optimum is kz = 5525 (bottom box -175.3, z 0.00)
# against the shipped default 5000 (-186.4, z -1.08), and it puts the bracket's
# lower end at -4.40. So it pushes kz UP within the bracket rather than out of
# it. Do not read that as a licence to re-centre kz by hand -- it is one stream
# among many and the refit is what weighs it.
#
# NOT inflated for model representation error. The build script anticipated
# doing so; 10.3 is the bare SE and inflating it silently would move a number
# Marcus chose. If representation error is wanted it belongs in this constant,
# visibly.
#
# ---- 2026-08-16: 20 WAS ASSERTED; IT HAS NOW BEEN MEASURED, AND IT SURVIVES --
# `calibration/diag_deep_d14c_neff.R` estimates n_eff seven ways from the same
# GLODAPv2 cells the target is built from (gated to reproduce it exactly).
# The correlogram puts rho = 0.5 at ~5500 km and rho = 0 at ~9000 km, so the
# cells are nowhere near independent and Kish's 3408 is out; the block bootstrap
# is only valid above the decorrelation scale, so its 10 and 20 degree rows are
# out too. The ADMISSIBLE set (`diag_deep_d14c_sigma_choice.R` part 1) is
#   6.4  correlogram with rho floored at 0   (basins as exchangeable masses)
#  11.9  block bootstrap, 60 deg
#  26.0  block bootstrap, 30 deg
# 110.1  correlogram with the empirical rho  (basin contrast as sampled structure)
# median 18.9, geometric mean 21.6. **20 sits between them, within 8 %.** The
# value does not move: the defect was provenance, and changing 20 to 19 would
# buy a 2.7 % sigma change while making every logL in the repo incomparable.
#
# TWO THINGS THAT MEASUREMENT DOES NOT SETTLE, both still open for Marcus:
#  * n_eff is only known to a factor of ~3.4 (1 sd on log n_eff), i.e. sigma to
#    a factor of ~1.85. Marginalising that out gives a Student-t with nu ~ 2.1,
#    which changes NEITHER live decision but cuts the kz-runaway penalty 4.3x
#    (20.1 -> 4.67 against a 4.50 threshold) -- so under it this term could
#    never replace the kz bracket. Measured in diag_deep_d14c_sigma_choice.R.
#  * representation error is STILL ZERO (see the paragraph above). At the
#    conservative end of the admissible set, sigma 18.15, candidate A stops
#    being adopted -- so this constant is now load-bearing on a structural
#    decision, which it was not when it was chosen.
LIK_D14C_DEEP_NEFF <- 20             # MEASURED-CONSISTENT (see above), not asserted
# Mask the North Atlantic (lat > 40N) out of the observed mean? Deep water forms
# there, so it is the one place below 2000 m carrying appreciable bomb 14C, and
# the model's bottom box is a global preindustrial mean. Masking moves the
# target -175.3 -> -178.2 permil, i.e. 0.28 sigma -- small enough that the
# UNMASKED global mean is used (it is the like-for-like global quantity) and
# large enough to be worth stating rather than burying.
LIK_D14C_DEEP_MASK_NATL <- FALSE
LIK_USE_D14C_DEEP <- TRUE

#' Deep-ocean D14C target, with the sigma resolved from LIK_D14C_DEEP_NEFF.
#'
#' Reads the GLODAPv2 build product and DERIVES the sigma rather than carrying a
#' second copy of it, so changing `LIK_D14C_DEEP_NEFF` cannot leave a stale
#' literal behind. Cached: the file is small but the likelihood is in the MCMC
#' inner loop through ccx_prepare_obs(), and re-reading an rds per call is how
#' a term with 3 numbers in it becomes a profiling entry.
#'
#' @return list(target, sd, sd_spread, n_eff, layer, masked) or NULL if the
#'   dataset is absent -- a missing optional file must not take the posterior
#'   down with it, and by_stream then shows the term ABSENT, which is visible.
ccx_deep_d14c_target <- local({
  cache <- NULL
  function(n_eff = LIK_D14C_DEEP_NEFF, mask_natl = LIK_D14C_DEEP_MASK_NATL) {
    key <- paste(n_eff, mask_natl)
    if (!is.null(cache) && identical(attr(cache, "key"), key)) return(cache)
    g <- tryCatch(readRDS(ccx_path("data", "obs_glodap_deep.rds")),
                  error = function(e) NULL)
    if (is.null(g) || is.null(g$d14c)) return(NULL)
    d <- if (mask_natl) g$d14c$deep_no_natl else g$d14c$deep
    out <- list(target = d$vw, sd = d$sd_w / sqrt(n_eff), sd_spread = d$sd_w,
                n_eff = n_eff, layer = g$model_layer, masked = mask_natl,
                n_cells = d$n_cells, source = g$source)
    attr(out, "key") <- key
    cache <<- out
    out
  }
})

# ---------------------------------------------------------------------
# OCEAN DIC AND d13C GRADIENT TERMS (task 12; Marcus 2026-08-16)
# ---------------------------------------------------------------------
# WHY THEY EXIST. Two of the five rows that discriminate the ocean structural
# candidates -- the preindustrial vertical DIC and d13C gradients -- were NOT in
# the objective, and they are the two rows only a biological pump can move
# (DESIGN sec.3.4a). A refit could therefore never arbitrate the pump no matter
# how long it ran, and diag_dic_gradient.R's pump had zero fitted parameters
# because there was nothing to fit them against. These terms are what make a
# fittable pump possible. This is the SANCTIONED direction -- add a missing
# constraint, do not reweight existing ones.
#
# GRADIENT, NOT LEVEL, and for d13C that is substantive rather than stylistic.
# The model's uniform ocean d13C is +1.560 permil against a preindustrial
# surface nearer +2.0: the LEVEL is off by ~0.4 permil for reasons that have
# nothing to do with the pump (air-sea fractionation constants and the
# preindustrial atmospheric value). A level term would conflate that with the
# pump signal; a gradient term is immune to it. For DIC the two are nearly the
# same number, so the gradient is used for both and the pair stays comparable.
#
# THE THREE NUMBERS EACH TERM NEEDS ARE ALL BUILD PRODUCTS, not literals here --
# same discipline as ccx_deep_d14c_target(). See data-raw/build_glodap_deep_targets.R.
#
#  * TARGET, on FIXED DEPTHS (0-100 m and > 2627.2 m). Marcus 2026-08-16, after
#    calibration/diag_gradient_target_and_neff.R part 2b priced both options and
#    found NEITHER neutral, with biases pointing OPPOSITE ways. A target anchored
#    on the model's own boxes is a function of h_ml (it reads +244.7 at h_ml 75
#    and +212.8 at the fitted 184) and, since the pre-pump model gradient is 0 at
#    every h_ml, its penalty FALLS 81 -> 53 log-units across h_ml 50 -> 220 --
#    i.e. it rewards a LARGE h_ml and pushes against clause 1, the thing the pump
#    exists to fix. Freezing at the h_ml = 75 grid instead overstates the miss at
#    the fitted h_ml, biasing IN FAVOUR of adopting a pump. Fixed depths are
#    neutral on both counts. (The size of that overstatement was quoted here as
#    1.61 sigma; that is part 2b's frozen-at-75 contrast on part 2b's TIGHTER
#    blk30 sigma of 20.16. On the sigma this term actually ships -- the
#    conservative blk60, 25.25 -- the same contrast is 1.26 sigma. Receipt-checked
#    by calibration/diag_hml_band_discontinuity.R part 5, 2026-08-16g.)
#
#  * SIGMA, from a block bootstrap ON THE CONTRAST. Var(Delta) = Var(D) +
#    Var(S) - 2 Cov(D,S), and the covariance is neither negligible nor
#    same-signed across fields: DIC anticorrelates at ~-0.6, INFLATING
#    sigma_Delta ~25 % (surface DIC peaks where the deep water is youngest, so
#    basins trade the two ends of the gradient), while d13C cancels weakly at
#    +0.16. Composing sigma from two per-layer n_eff would have got DIC wrong by
#    25 % in the direction that makes the term TOO STRONG. The shipped sigma is
#    the CONSERVATIVE of the two methodologically valid block sizes.
#
#  * EPOCH. The observed surface is anthropogenically contaminated (~+50 umol/kg
#    of C_ant; Suess-depleted d13C), so a preindustrial model gradient scored
#    against it is biased AGAINST the pump. Marcus 2026-08-16 resolved this by
#    scoring the model's TRANSIENT gradient at the observations' own epoch
#    instead of correcting the surface -- GLODAPv2.2023's bottle file has no
#    C_ant column, so correcting DIC would have meant a new download or a dC*
#    build. Hence these terms read a TIME SERIES (CCX_OCEAN_BOX_COLS) rather
#    than the spinup, unlike the deep-D14C term. The two layers have different
#    mean sampling years (~1999.8 surface, ~2002.4 deep) and each is scored at
#    its own, because the observed gradient is itself a difference of two
#    differently-timed means.
#
# THE h_ml REPRESENTATION ERROR, AND WHY THERE IS NO LONGER A GATE HERE.
# Fixed depths are like-for-like with the model's boxes only while h_ml is near
# the surface band's 100 m. UNTIL 2026-08-28 that was handled by SKIPPING all
# three rows outside LIK_OCEAN_GRAD_HML_OK = [85, 120]. Marcus ADOPTED option 5
# (sigma-inflation) on 2026-08-28 and the skip is GONE: the rows are scored at
# EVERY h_ml, at an inflated sigma that carries the mismatch in quadrature,
#
#     sigma_eff(h)^2 = sigma_obs^2 + (shipped target - like-for-like target(h))^2
#
# with dnorm's normalisation RETAINED, so inflating is CHARGED FOR rather than
# free and the gain is bounded by the density peak. sigma_rep is MEASURED off
# GLODAP by data-raw/build_glodap_sigma_rep.R, never tuned.
#
# WHY THE SKIP HAD TO GO -- it was not conservatism, it was a FREE LUNCH. The
# rows were ABSENT rather than zero outside the band, so leaving the band bought
# +7.30 log-units of un-scored data against a +7.39 total advantage: the
# objective did not prefer a shallower mixed layer, it preferred BEING SCORED ON
# LESS DATA (notes/collect_2026-08-28_hml_unbound_profile.md). Inflation removes
# the cause rather than walling off the symptom: MEASURED, the pull falls to
# +0.033, both cliffs vanish (+7.30 -> -0.006 at 85, +8.43 -> -0.005 at 120), and
# h_ml gains an INTERIOR maximum over its whole [30, 200] support, so it no
# longer needs a hard bound to stay put (notes/collect_2026-08-28b_...md).
# The retired band is kept below as PROVENANCE ONLY -- it must never gate again.
#
# THE SIGNED like-for-like TARGET IS WHAT SHIPS, NOT |sigma_rep| -- it is the
# quantity actually measured, and folding discards the sign for no gain. ⚠ It is
# NOT a smoothness fix: sigma_eff uses the SQUARE, so MEASURED 2026-08-28 the two
# constructions differ by at most 0.0002 sigma_obs with second differences equal
# to six decimals. An earlier comment here claimed folding would plant a kink in
# the posterior's softest direction; that was WRONG and is withdrawn.
LIK_USE_OCEAN_GRAD   <- TRUE
# ⚠ PROVENANCE ONLY, RETIRED 2026-08-28. Nothing may gate on this. It records
# what the band WAS, so a reader of an older handoff, output or quarantined arm
# can tell which regime that artifact was produced under.
LIK_OCEAN_GRAD_HML_OK_RETIRED <- c(85, 120)   # m; the skip option 5 replaced
# Alkalinity stoichiometry, for the third row (Marcus 2026-08-16b). CaCO3
# dissolution adds 2 mol alkalinity per mol C; soft-tissue remineralisation
# releases nitrate and so REMOVES ~1 mol per mol N. WORKING VALUES, not fitted,
# and the N:C is an Anderson-Sarmiento-type recollection rather than a citation.
LIK_ALK_PER_CARB <- 2
LIK_ALK_NC_RATIO <- 16 / 117          # ~0.137 mol N per mol C

#' Ocean DIC / d13C gradient targets, from the GLODAPv2 build product.
#'
#' @return list(dic = , d13c = ), each list(target, sd, epoch_surf, epoch_deep),
#'   or NULL if the dataset or its `gradient` block is absent -- a missing
#'   optional file must not take the posterior down with it, and by_stream then
#'   shows the terms ABSENT, which is visible.
ccx_ocean_gradient_target <- local({
  cache <- NULL
  function() {
    if (!is.null(cache)) return(cache)
    g <- tryCatch(readRDS(ccx_path("data", "obs_glodap_deep.rds")),
                  error = function(e) NULL)
    if (is.null(g) || is.null(g$gradient)) return(NULL)
    out <- list(dic = g$gradient$tco2, d13c = g$gradient$d13c,
                alk = g$gradient$talk)
    cache <<- out
    out
  }
})

#' The ocean-gradient REPRESENTATION error, sigma_rep(h_ml), and the inflated
#' sigma the three rows are scored at.
#'
#' Shipped by data-raw/build_glodap_sigma_rep.R as the SIGNED like-for-like
#' target on a 1 m grid over h_ml's whole support -- the quantity actually
#' measured. sigma_eff uses the SQUARE of the difference, so shipping |sigma_rep|
#' instead would change it by at most 0.0002 sigma_obs (measured); the signed
#' form is preferred for faithfulness, not for smoothness.
#'
#' Interpolation is MONOTONE HERMITE (C1) through the measured points, never a
#' parametric fit. No smoothing: the measured roughness from bottle selection is
#' a median 0.0055 and at most 0.0734 log-units on the three rows' summed logL.
#'
#' @return NULL if the file is absent -- the same visible-absence contract the
#'   target loader uses; ccx_ocean_grad_scored() then STOPS rather than silently
#'   reverting to sigma_obs, because that would be the retired objective.
ccx_ocean_sigma_rep_table <- local({
  cache <- NULL
  function() {
    if (!is.null(cache)) return(cache)
    g <- tryCatch(readRDS(ccx_path("data", "obs_glodap_sigma_rep.rds")),
                  error = function(e) NULL)
    if (is.null(g) || is.null(g$like_for_like)) return(NULL)
    # One monotone-Hermite interpolant per row, built once and closed over.
    g$fun <- lapply(names(g$like_for_like), function(n)
      stats::splinefun(g$h, g$like_for_like[[n]], method = "monoH.FC"))
    names(g$fun) <- names(g$like_for_like)
    cache <<- g
    g
  }
})

#' sigma_eff for one scored ocean-gradient row at a given h_ml.
#'
#' @param row one of "dic", "d13c", "alk".
#' @param h_ml mixed-layer depth, m. CLAMPED to the shipped grid: h_ml cannot
#'   leave its own prior support, so an out-of-range value is a caller bug, and
#'   extrapolating a monotone Hermite spline past its data would be worse than
#'   holding the endpoint.
ccx_ocean_sigma_eff <- function(row, h_ml) {
  sr <- ccx_ocean_sigma_rep_table()
  tg <- ccx_ocean_gradient_target()
  if (is.null(sr) || is.null(tg) || is.null(sr$fun[[row]]))
    stop("ccx_ocean_sigma_eff(): data/obs_glodap_sigma_rep.rds is missing or has ",
         "no '", row, "' row. Rebuild with data-raw/build_glodap_sigma_rep.R. ",
         "Falling back to sigma_obs would silently restore the RETIRED objective.")
  h <- min(max(h_ml, min(sr$h)), max(sr$h))
  sqrt(tg[[row]]$sd^2 + (sr$fun[[row]](h) - tg[[row]]$target)^2)
}

#' Steady-state interior profile implied by an interior source field.
#'
#' THE EXACT INVERSE of the export solve in calibration/pump_shim.R's
#' dg_export_field(), which is what makes it testable without a pump:
#' profile -> source -> profile must round-trip (test-likelihood.R).
#'
#' Steady state requires the source in box k to cancel the diffusive
#' convergence there, S_k = -[F(k-1,k) - F(k,k+1)] with
#' F(a,b) = kz (c_a - c_b) / dz_mid[a]. Reading that from the bottom up gives
#' the interface fluxes, and the fluxes integrate to the profile.
#'
#' WHY IT IS A STEADY-STATE SOLVE AND NOT A TRACER. Alkalinity in this model has
#' no air-sea flux, no decay and no anthropogenic source -- so unlike DIC it has
#' NO TRANSIENT, and its profile is fully determined at every date by the export
#' field. A fourth state column would carry the same information at the cost of
#' the whole state, the C++ core, the Newton spinup and the parity tests.
#'
#' @param S numeric, source into each interior box, in the units of
#'   dg_export_field()'s output (GtC/yr, or mol-equivalents/yr for alkalinity).
#' @return numeric, concentration DIFFERENCE from the mixed layer for each
#'   interior box, in umol/kg. Element `nl` is the bottom box, i.e. the gradient.
ccx_steady_profile_from_source <- function(S, p, aux, grid, hemi) {
  nl <- grid$nl
  stopifnot(length(S) == nl)
  # fluxes, from the bottom: F[nl] = -S[nl]; F[k] = F[k+1] - S[k]
  Fi <- numeric(nl)
  Fi[nl] <- -S[nl]
  for (k in seq.int(nl - 1L, 1L)) Fi[k] <- Fi[k + 1L] - S[k]
  kappa <- aux$a_oc[[hemi]] * ccx_const("RHO_SEAWATER") / aux$mol_per_GtC
  # cc[k+1] = cc[k] - F[k] dz_mid[k] / K_k, in GtC/m; /kappa/1e-6 -> umol/kg.
  # K_k is the interface's own diffusivity (2026-09-06b); uniform kz before.
  kzv <- if (is.null(aux$kz_int)) rep(p$kz, nl) else aux$kz_int
  cumsum(-Fi * aux$dz_mid / kzv) / kappa * 1e6
}

#' The MODEL's deep-minus-surface ALKALINITY gradient, umol/kg.
#'
#' RETURNS EXACTLY 0 TODAY, FOR EVERY PARAMETER, AND THAT IS A MODEL PREDICTION
#' RATHER THAN A PLACEHOLDER. `ALK_SURFACE` enters the mixed-layer carbonate
#' solve and nowhere else (ccx_dic_for_pco2(), pco2_from_dic(), the
#' revelle_factor() diagnostic); the interior has no alkalinity and no carbonate
#' chemistry. With no carbonate pump there is no mechanism that could separate
#' the two layers, so the model says zero and the observation says +78.6 -- a
#' 4.09 sigma miss the pump (task 9) exists to close.
#'
#' @param spin the spinup.
#' @param pump OPTIONAL list(S_org = , S_carb = ), the per-limb export fields per
#'   hemisphere as dg_export_field() returns them. When the pump ships, pass it
#'   here and the term becomes live with no other change: alkalinity rides the
#'   carbonate limb at +2 per mole (CaCO3 dissolution) and the organic limb at
#'   -(N:C) per mole (nitrate release), and the profile follows from the same
#'   diffusion operator the DIC gradient uses.
ccx_model_ocean_alk_gradient <- function(spin, pump = NULL) {
  if (is.null(pump)) return(0)
  aux <- spin$aux; grid <- spin$grid; p <- spin$params
  num <- 0; den <- 0
  for (h in HEMIS) {
    S <- LIK_ALK_PER_CARB * pump$S_carb[[h]] - LIK_ALK_NC_RATIO * pump$S_org[[h]]
    g <- ccx_steady_profile_from_source(S, p, aux, grid, h)[grid$nl]
    m <- aux$a_oc[[h]] * grid$dz[grid$nl + 1L] * ccx_const("RHO_SEAWATER")
    num <- num + g * m; den <- den + m       # mass-weighted, as the obs is
  }
  num / den
}

#' The MODEL's ocean gradient (bottom box - mixed layer), globally, at a year.
#'
#' Both hemispheres are combined the way the observation is: DIC as a
#' VOLUME-weighted mean concentration (equivalently, total carbon over total
#' mass), d13C as a CARBON-weighted ratio. Averaging the two hemispheres'
#' d13C values directly would be wrong whenever their carbon differs, which it
#' does -- the SH column is the larger.
#'
#' @param out  the `out` data.frame from ccx_run()/ccx_run_fast(); must carry
#'   CCX_OCEAN_BOX_COLS. Its ABSENCE is what skips the terms.
#' @param aux,grid  from the spinup, for the box volumes.
#' @param epoch list(surf, deep) decimal years; each layer is read at its own.
ccx_model_ocean_gradient <- function(out, aux, grid, epoch) {
  if (!all(CCX_OCEAN_BOX_COLS %in% names(out))) return(NULL)
  at <- function(col, tt) stats::approx(out$t, out[[col]], xout = tt, rule = 2)$y
  rho <- ccx_const("RHO_SEAWATER")
  # kg of seawater in each hemisphere's ML and bottom box
  mass <- lapply(HEMIS, function(h)
    c(ml = aux$a_oc[[h]] * grid$dz[1] * rho,
      deep = aux$a_oc[[h]] * grid$dz[length(grid$dz)] * rho))
  names(mass) <- HEMIS
  lay <- function(which, tt) {
    C   <- sum(vapply(HEMIS, function(h) at(paste0(which, "_C_",   h), tt), numeric(1)))
    C13 <- sum(vapply(HEMIS, function(h) at(paste0(which, "_C13_", h), tt), numeric(1)))
    M   <- sum(vapply(HEMIS, function(h) mass[[h]][[which]], numeric(1)))
    c(dic  = C * aux$mol_per_GtC / M * 1e6,
      d13c = 1000 * (C13 / C / ccx_const("R13_VPDB") - 1))
  }
  s <- lay("ml", epoch$surf); b <- lay("deep", epoch$deep)
  list(dic = unname(b["dic"] - s["dic"]), d13c = unname(b["d13c"] - s["d13c"]))
}

#' The model gradient as the likelihood should receive it: each field read at
#' ITS OWN epoch, and the h_ml gate applied.
#'
#' Returns NULL -- which SKIPS the terms -- when the target is unavailable or
#' the run does not carry the box columns. A NULL here is the visible-absence
#' contract, not a silent zero. ⚠ It NO LONGER returns NULL for `h_ml` outside
#' [85, 120]: that skip was retired 2026-08-28 (option 5, sigma-inflation).
#'
#' @param spin the spinup, for aux/grid/params.
#' @param pump OPTIONAL pump export fields, forwarded to
#'   ccx_model_ocean_alk_gradient(). NULL until task 9.
ccx_ocean_grad_scored <- function(out, spin, pump = NULL) {
  tg <- ccx_ocean_gradient_target()
  if (is.null(tg)) return(NULL)
  h <- spin$grid$h_ml
  # ⚠ NO BAND GATE. Retired 2026-08-28 when option 5 was adopted: the rows are
  # scored at EVERY h_ml, at sigma_eff(h). See LIK_USE_OCEAN_GRAD's block.
  # Each field at its own epochs: the two layers are not sampled at the same
  # mean time, and the two fields' means differ slightly too (deep DIC 2002.4,
  # deep d13C 2002.2). Cheap enough to do exactly rather than approximately.
  gd <- ccx_model_ocean_gradient(out, spin$aux, spin$grid,
                                 list(surf = tg$dic$epoch_surf,
                                      deep = tg$dic$epoch_deep))
  g3 <- ccx_model_ocean_gradient(out, spin$aux, spin$grid,
                                 list(surf = tg$d13c$epoch_surf,
                                      deep = tg$d13c$epoch_deep))
  if (is.null(gd) || is.null(g3)) return(NULL)
  # Alkalinity needs no epoch: it has no transient in this model (no air-sea
  # flux, no anthropogenic source), so its profile is a steady-state function of
  # the export field alone.
  #
  # THE PUMP IS READ OFF THE SPINUP RATHER THAN DEMANDED FROM THE CALLER. Every
  # caller already hands in `spin`, and `spin$aux$pump` is the SAME field the
  # derivative integrates -- so the alkalinity row cannot be scored against a
  # pump the run did not actually use. A caller that passes `pump` explicitly
  # overrides, which is what the tests use to drive a hand-built field.
  if (is.null(pump) && !is.null(spin$aux$pump))
    pump <- list(S_org  = lapply(spin$aux$pump, `[[`, "org"),
                 S_carb = lapply(spin$aux$pump, `[[`, "carb"))
  # `sd_eff` rides WITH the values, so a caller physically cannot score them at
  # the retired sigma_obs: ccx_loglik() requires it and errors without it. h_ml
  # is not otherwise visible to ccx_loglik(), and threading it through that
  # signature would have made every one of ~30 diagnostic call sites a silent
  # opt-out. `h_ml` is carried for reporting and for the tests.
  list(dic = gd$dic, d13c = g3$d13c,
       alk = ccx_model_ocean_alk_gradient(spin, pump = pump),
       sd_eff = vapply(c("dic", "d13c", "alk"), ccx_ocean_sigma_eff, numeric(1),
                       h_ml = h),
       h_ml = h)
}

#' Hemisphere-area weights for the Hua zones
ccx_zone_weights <- function(nh_bounds = LIK_ZONE_BOUNDS_NH,
                             sh_bounds = LIK_ZONE_BOUNDS_SH) {
  s <- function(d) sin(d * pi / 180)
  nh <- c(NHZone1 = 1 - s(nh_bounds[1]),
          NHZone2 = s(nh_bounds[1]) - s(nh_bounds[2]),
          NHZone3 = s(nh_bounds[2]))
  sh <- c(SHZone3 = s(sh_bounds[1]), `SHZone1-2` = 1 - s(sh_bounds[1]))
  list(NH = nh / sum(nh), SH = sh / sum(sh))
}

# ---------------------------------------------------------------------
#' Per-calendar-year level, trend and first seasonal harmonic
#'
#' The single estimator applied to BOTH observations and model output (design
#' note 1b), so no deseasonalisation method has to be trusted on one side only.
#'
#' Per year, ordinary least squares of
#'     v ~ 1 + (t - midyear) + sin(2*pi*phi) + cos(2*pi*phi),   phi = t mod 1
#' The intercept is the value at mid-year with the seasonal cycle and the
#' within-year trend both removed, which is what makes it robust to partial
#' month coverage: a year observed only in Jul-Dec would otherwise report a
#' level biased upward by half a year of trend plus a lopsided seasonal mean.
#'
#' @return data.frame(year, level, trend, a, b, n) -- `a`,`b` are the sin and
#'   cos coefficients; amplitude = 2*sqrt(a^2+b^2) peak-to-peak.
ccx_year_harmonic <- function(t, v, min_months = LIK_ANNUAL_MIN_MONTHS) {
  ok <- is.finite(t) & is.finite(v)
  t <- t[ok]; v <- v[ok]
  yr <- floor(t)
  out <- lapply(sort(unique(yr)), function(y) {
    k <- yr == y
    if (sum(k) < min_months) return(NULL)
    tt <- t[k]; vv <- v[k]; phi <- tt - y
    X <- cbind(1, tt - (y + 0.5), sin(2 * pi * phi), cos(2 * pi * phi))
    cf <- tryCatch(qr.solve(X, vv), error = function(e) NULL)
    if (is.null(cf)) return(NULL)
    data.frame(year = y, level = cf[1], trend = cf[2], a = cf[3], b = cf[4], n = sum(k))
  })
  out <- do.call(rbind, out)
  if (is.null(out)) out <- data.frame(year = integer(0), level = numeric(0),
                                      trend = numeric(0), a = numeric(0),
                                      b = numeric(0), n = integer(0))
  out
}

#' Seasonal target: the per-year first-harmonic coefficients inside the window,
#' plus the interannual SD that serves as their sigma (see LIK_SEAS_WINDOW).
#' `a_mean`/`b_mean` are for reporting only; the likelihood scores year by year.
ccx_seasonal_target <- function(h, window = LIK_SEAS_WINDOW) {
  k <- h$year >= window[1] & h$year <= window[2]
  if (sum(k) < 3) return(NULL)
  list(year = h$year[k], a = h$a[k], b = h$b[k],
       a_mean = mean(h$a[k]), b_mean = mean(h$b[k]),
       sd_a = stats::sd(h$a[k]), sd_b = stats::sd(h$b[k]), n_years = sum(k))
}

#' Plain annual mean of an irregular series, with the year's mean stated error.
#' Errors are NOT reduced by sqrt(n): for D14C the dominant term is systematic
#' representation error, and for a smoothed compilation the monthly values are
#' not independent draws anyway (design note 1c).
ccx_annual_mean <- function(t, v, sd, min_n = 1L) {
  yr <- floor(t)
  u  <- sort(unique(yr))
  n  <- vapply(u, function(y) sum(yr == y), integer(1))
  data.frame(year = u,
             value = vapply(u, function(y) mean(v[yr == y]), numeric(1)),
             sd    = vapply(u, function(y) mean(sd[yr == y]), numeric(1)),
             n     = n)[n >= min_n, ]
}

# ---------------------------------------------------------------------
#' Model 14C state units -> kmol 14C
#'
#' The state carries 14C as "GtC carrying standard 14C content" (model.R
#' header), so a mole of it is a mole of carbon times the absolute standard
#' ratio. Derived from the constants, never re-typed as a literal -- the same
#' discipline constants.R enforces on LAMBDA_C14.
ccx_c14_kmol <- function(x)
  x * ccx_const("MOL_C_PER_GtC") * ccx_const("R14_STD") / 1000

#' Build the ocean excess-14C target, with its covariance already inverted
#'
#' Covariance is diag(half_width^2) + rep rep', i.e. per-year observational
#' spread plus ONE shared method bias (design note 5, LIK_EXCESS_C14_REP_FRAC).
#' Inverted here because it depends only on the observations, and inverting a
#' 2x2 inside the MCMC loop for no reason is how 46 ms becomes 718 ms.
#'
#' @return NULL if the dataset is absent or names an unknown target set, so a
#'   missing optional file cannot take the whole posterior down with it.
ccx_excess_c14_target <- function(exc, which = LIK_EXCESS_C14_TARGET,
                                  rep_frac = LIK_EXCESS_C14_REP_FRAC) {
  if (is.null(exc) || is.null(exc$targets) || is.null(exc$targets[[which]])) return(NULL)
  d <- as.data.frame(exc$targets[[which]])
  d <- d[order(d$year), ]
  rep <- rep_frac * d$centre
  S   <- diag(d$half_width^2, nrow = nrow(d)) + outer(rep, rep)
  list(year = d$year, centre = d$centre, half_width = d$half_width, rep = rep,
       Sigma = S, prec = solve(S),
       logdet = as.numeric(determinant(S, logarithm = TRUE)$modulus),
       target = which, note = d$note)
}

#' Pre-assemble every observation into the form the likelihood needs.
#' Done ONCE, outside the MCMC loop.
ccx_prepare_obs <- function() {
  co2  <- as.data.frame(readRDS(ccx_path("data", "obs_co2_monthly.rds")))
  d13  <- as.data.frame(readRDS(ccx_path("data", "obs_d13c_monthly.rds")))
  d14  <- as.data.frame(readRDS(ccx_path("data", "obs_d14c_zonal.rds")))
  ice  <- readRDS(ccx_path("data", "obs_icecore.rds"))
  gcb  <- readRDS(ccx_path("data", "gcb_budget.rds"))$budget
  ic20 <- tryCatch(as.data.frame(readRDS(ccx_path("data", "obs_d14c_intcal20.rds"))),
                   error = function(e) NULL)
  exc  <- tryCatch(readRDS(ccx_path("data", "obs_excess_c14.rds")),
                   error = function(e) NULL)

  # primary stations only -- the NOAA records are cross-checks, not targets
  co2 <- co2[co2$station %in% c("MLO", "SPO"), ]
  d13 <- d13[d13$station %in% c("MLO", "SPO"), ]

  # D14C: aggregate zones to hemispheres with area weights
  w <- ccx_zone_weights()
  agg <- function(zones, wts) {
    sub <- d14[d14$zone %in% names(wts), c("decimal_date", "zone", "d14c", "d14c_sd")]
    wide <- reshape(sub, idvar = "decimal_date", timevar = "zone", direction = "wide")
    vcols <- paste0("d14c.", names(wts))
    scols <- paste0("d14c_sd.", names(wts))
    keep <- stats::complete.cases(wide[, vcols])
    wide <- wide[keep, ]
    val <- as.vector(as.matrix(wide[, vcols]) %*% wts)
    # measurement error propagates as a weighted quadrature sum
    sdv <- sqrt(as.vector(as.matrix(wide[, scols])^2 %*% (wts^2)))
    data.frame(t = wide$decimal_date, d14c = val, sd_meas = sdv)
  }
  d14_nh <- agg("NH", w$NH); d14_sh <- agg("SH", w$SH)
  rep_err <- function(t) ifelse(t >= LIK_D14C_BOMB_WIN[1] & t <= LIK_D14C_BOMB_WIN[2],
                                LIK_D14C_REP_BOMB, LIK_D14C_REP_OTHER)
  d14_nh$sd <- sqrt(d14_nh$sd_meas^2 + rep_err(d14_nh$t)^2)
  d14_sh$sd <- sqrt(d14_sh$sd_meas^2 + rep_err(d14_sh$t)^2)
  if (!LIK_USE_BOMB_WINDOW) {
    drop <- function(x) x[x$t < LIK_BOMB_EXCLUDE[1] | x$t > LIK_BOMB_EXCLUDE[2], ]
    n0 <- nrow(d14_nh); d14_nh <- drop(d14_nh); d14_sh <- drop(d14_sh)
    message(sprintf("D14C bomb window %d-%d EXCLUDED (%d of %d NH points dropped): the bomb injection shape is still provisional.",
                    LIK_BOMB_EXCLUDE[1], LIK_BOMB_EXCLUDE[2], n0 - nrow(d14_nh), n0))
  }

  # ice-core CO2: use the RAW SAMPLES with their stated errors, not the spline.
  # The spline is a smoothed reconstruction; treating its annual values as
  # independent observations would massively overweight the pre-1958 record.
  ico <- as.data.frame(ice$co2_samples)
  names(ico)[names(ico) == "age_CO2"] <- "year"
  ico <- ico[!is.na(ico$year) & !is.na(ico$CO2ppm) & ico$year >= 1700, ]
  ico$sd <- sqrt(pmax(ico$CO2err, 0.5)^2 + LIK_ICE_REP_ERR^2)

  # ---- ANNUAL REDUCTION (2026-08-11; see design notes 1, 1b, 1c) -----
  # Everything below is what the likelihood actually scores. The monthly frames
  # are still returned, because diagnostics and the app plot against them.
  co2_ann <- lapply(c(MLO = "MLO", SPO = "SPO"), function(st) {
    o <- co2[co2$station == st, ]
    ccx_year_harmonic(o$decimal_date, o$co2_ppm)
  })
  d13_ann <- lapply(c(MLO = "MLO", SPO = "SPO"), function(st) {
    o <- d13[d13$station == st, ]
    if (!nrow(o)) return(NULL)
    ccx_year_harmonic(o$decimal_date, o$d13c)
  })
  co2_seas <- lapply(co2_ann, ccx_seasonal_target)
  # d13C seasonal target from the SAME per-year harmonics the level term uses --
  # nothing new is estimated (the gradient-term idiom: statistics that already
  # exist, differenced/windowed, keep model and obs on identical machinery).
  d13_seas <- lapply(d13_ann, function(h) if (is.null(h)) NULL else ccx_seasonal_target(h))

  d14_nh_ann <- ccx_annual_mean(d14_nh$t, d14_nh$d14c, d14_nh$sd)
  d14_sh_ann <- ccx_annual_mean(d14_sh$t, d14_sh$d14c, d14_sh$sd)

  # ---- INTERHEMISPHERIC GRADIENT (2026-08-15, review item 5) ---------
  # Built from the SAME per-year levels the level terms score, differenced on
  # the years where both stations have one. Nothing new is estimated: the
  # gradient is a function of statistics that already exist, which is what makes
  # the term nearly free and what keeps design note 1b's property that model and
  # observations pass through identical machinery.
  #
  # This also disposes of gate 9's first trap without a special case. Gate 9
  # warns that seasonal adjustment is "mandatory, not cosmetic" -- MLO's ~6 ppm
  # cycle against SPO's ~1 ppm means uneven month coverage aliases seasonality
  # into the difference, shifting the 1950s by -0.77 ppm to a spurious NEGATIVE
  # gradient. ccx_year_harmonic()'s level is already seasonally adjusted and
  # already de-trended within the year, so differencing two of them is the
  # adjusted quantity by construction. Verified: the decadal means of this
  # series match gate 9's table to <= 0.02 ppm on every decade it covers
  # (calibration/diag_gradient_terms.R part 1).
  ccx_pair_grad <- function(a, b) {
    if (is.null(a) || is.null(b) || !nrow(a) || !nrow(b))
      return(data.frame(year = integer(0), grad = numeric(0)))
    m <- merge(a[, c("year", "level")], b[, c("year", "level")],
               by = "year", suffixes = c("_n", "_s"))
    data.frame(year = m$year, grad = m$level_n - m$level_s)
  }
  co2_grad  <- ccx_pair_grad(co2_ann$MLO, co2_ann$SPO)
  d13c_grad <- ccx_pair_grad(d13_ann$MLO, d13_ann$SPO)

  list(co2 = co2, d13 = d13, d14_nh = d14_nh, d14_sh = d14_sh,
       ice = ico, gcb = gcb, intcal = ic20, weights = w,
       co2_ann = co2_ann, d13_ann = d13_ann, co2_seas = co2_seas,
       d13_seas = d13_seas,
       co2_grad = co2_grad, d13c_grad = d13c_grad,
       d14_nh_ann = d14_nh_ann, d14_sh_ann = d14_sh_ann,
       excess_c14_all = exc, excess_c14 = ccx_excess_c14_target(exc))
}

#' SUPERSEDED 2026-08-11 -- the AR(1) residual model. Do not wire this back in.
#'
#' Kept so the size of the correction is reproducible and so the diagnosis can
#' be re-run, exactly as ccx_bomb_c14_annual_SUPERSEDED() is kept in forcing.R.
#'
#' The exact AR(1) likelihood is correct arithmetic for a wrong premise. As
#' rho -> 1 the innovation becomes (r_t - r_{t-1})/sd, so the fitted sd collapses
#' to the RMS of the residual INCREMENTS rather than of the residual LEVEL. For a
#' smooth model against a smooth observation series that is tiny -- sigma_co2 fell
#' to 0.074 ppm -- and the level goes unpenalised. See the table in design note 1.
#'
#' Two further defects, both fatal on their own:
#'   * it is applied on OBSERVATION INDEX, so a 16-month SPO gap counts as one
#'     step (the docstring's "regular grid" premise is simply not met);
#'   * one shared rho was imposed across four series -- MLO/SPO CO2 and
#'     MLO/SPO d13C -- with quite different sampling densities.
#'
#' @param r residuals, @param sd standard deviations, @param rho AR(1) coefficient
ccx_ll_ar1_SUPERSEDED <- function(r, sd, rho) {
  n <- length(r)
  if (n == 0) return(0)
  z <- r / sd
  if (n == 1) return(-0.5 * z^2 - sum(log(sd)))
  # exact AR(1) likelihood for standardised residuals
  ll <- -0.5 * (1 - rho^2) * z[1]^2 + 0.5 * log(1 - rho^2)
  e  <- z[-1] - rho * z[-n]
  ll <- ll - 0.5 * sum(e^2)
  ll - sum(log(sd)) - 0.5 * n * log(2 * pi)
}

# ---------------------------------------------------------------------
# Model-side reduction: the SAME estimator, but computed as one matrix product.
#
# ccx_year_harmonic() is general enough for observations, which have ragged
# month coverage, but it costs a qr.solve and a data.frame per year. Called on
# four model series inside an MCMC loop that is otherwise 46 ms, it took the
# posterior evaluation to 718 ms -- 40 hours for a production run. The model,
# unlike the observations, is on an EXACT monthly grid, so every full year
# shares one design matrix and the whole reduction is a 4x12 by 12xN product.
# test-likelihood.R gates the fast path against ccx_year_harmonic() so the two
# cannot drift apart.
.ccx_month_design <- local({
  phi <- (seq_len(12) - 0.5) / 12                 # month centres within a year
  X   <- cbind(1, phi - 0.5, sin(2 * pi * phi), cos(2 * pi * phi))
  list(X = X, P = solve(crossprod(X), t(X)))      # 4 x 12 pseudo-inverse
})

#' Per-year level / trend / harmonic of one model column, on the monthly grid
ccx_model_year_stats <- function(out, col) {
  yr <- floor(out$t + 1e-9)
  u  <- unique(yr)
  n  <- tabulate(match(yr, u), nbins = length(u))
  full <- which(n == 12L)
  if (!length(full)) return(NULL)
  keep <- yr %in% u[full]
  # Guard the reshape: the matrix() below assumes 12 consecutive month-ordered
  # rows per year, which ccx_build_forcing() produces. Assert rather than trust.
  mo <- round((out$t[keep] - yr[keep]) * 12 + 0.5)
  if (!identical(as.integer(mo), rep(seq_len(12), length(full))))
    return(ccx_year_harmonic(out$t[keep], out[[col]][keep], min_months = 12L))
  M  <- matrix(out[[col]][keep], nrow = 12)
  cf <- .ccx_month_design$P %*% M
  list(year = u[full], level = cf[1, ], trend = cf[2, ],
       a = cf[3, ], b = cf[4, ], mean = colMeans(M))
}

#' Reduce a model run to the same annual/seasonal statistics as the observations
ccx_model_stats <- function(out, obs) {
  cols <- c(co2_NH = "co2_NH", co2_SH = "co2_SH",
            d13c_NH = "d13c_NH", d13c_SH = "d13c_SH",
            d14c_NH = "d14c_NH", d14c_SH = "d14c_SH")
  s <- lapply(cols, function(cc) ccx_model_year_stats(out, cc))
  co2 <- list(MLO = s$co2_NH, SPO = s$co2_SH)
  list(co2 = co2, d13 = list(MLO = s$d13c_NH, SPO = s$d13c_SH),
       d14 = list(NH = s$d14c_NH, SH = s$d14c_SH),
       co2_seas = lapply(co2, ccx_seasonal_target),
       d13_seas = lapply(list(MLO = s$d13c_NH, SPO = s$d13c_SH), ccx_seasonal_target))
}

#' Log-likelihood of one model run
#'
#' Every stream is scored with INDEPENDENT Gaussian errors on ANNUAL values.
#' There is no autocorrelation parameter -- see design note 1 for why the AR(1)
#' predecessor was retired rather than bounded.
#'
#' @param out  data.frame from ccx_run_fast()$out
#' @param obs  from ccx_prepare_obs()
#' @param err  list(sigma_d13c, sigma_d14c, grad_off_co2, grad_off_d13c).
#'   `sigma_co2` is RETIRED but still honoured if supplied -- see the CO2 level
#'   block for the two branches. The gradient offsets are NOT optional in the
#'   same sense: their absence SKIPS both gradient streams (LIK_GRAD_* block),
#'   so check `by_stream` for ABSENT streams before quoting a total.
#' @param luc  data.frame(year, eluc) -- the MODEL's own annual land-use flux,
#'   needed to turn its net land flux into the gross sink GCB reports. NULL uses
#'   GCB's own column, which is correct whenever luc_scale = 1.
#' @param deep scalar, the model's BOTTOM-BOX D14C in permil, i.e.
#'   `ccx_spinup(p)$diagnostics$d14c_bottom_box`. It is a steady-state quantity
#'   and is not recoverable from `out`, so it has to be handed in. NULL skips
#'   the term, which then shows as ABSENT under `by_stream` rather than as a
#'   silent zero. Do NOT pass `d14c_deep_ocean` here -- that is the bottom THREE
#'   boxes and a different layer from the target (see LIK_D14C_DEEP_NEFF).
#' @param by_stream if TRUE return the per-stream contributions instead of the
#'   total. Used by the calibration report and by the app's diagnostics panel;
#'   a single number cannot show which constraint a fit is actually paying for.
#'
#' POSITIONAL-ARGUMENT HAZARD, second instance. `luc` was inserted before
#' `by_stream` on 2026-08-14 and `deep` now sits after it. Every caller in the
#' repo passes `by_stream =` by name, so nothing breaks -- but a positional 5th
#' argument means `by_stream` and a positional 4th means `luc`. Name them.
ccx_loglik <- function(out, obs, err, luc = NULL, deep = NULL,
                       ocean_grad = NULL, by_stream = FALSE) {
  parts <- c()
  add <- function(name, v) parts[[name]] <<- (if (is.null(parts[[name]])) 0 else parts[[name]]) + v
  interp <- function(col, tt) stats::approx(out$t, out[[col]], xout = tt, rule = 2)$y
  ms <- ccx_model_stats(out, obs)

  # ---- CO2 annual level, independent ---------------------------------
  # LIK_CO2_REP_ERR is the fixed station-vs-box term and, since item 6b, the
  # whole sd. It is not divided by sqrt(months): it is systematic within a year
  # (design note 1c).
  #
  # `sigma_co2` RETIRED 2026-08-15 -- and it is kept REACHABLE here, under the
  # absence contract, for exactly one reason: every diagnostic and test written
  # before today passes it, and their numbers have to keep reproducing.
  #   err$sigma_co2 ABSENT  -> sd = LIK_CO2_REP_ERR          (the objective)
  #   err$sigma_co2 PRESENT -> sd = sqrt(s^2 + REP^2)        (legacy parity)
  # The absence is the NEW behaviour rather than the old, which inverts this
  # repo's usual absence-skips-a-stream idiom. That is deliberate: a caller
  # that has been updated says so by dropping the field, and one that has not
  # keeps its old weight instead of being silently re-weighted. Nothing here
  # can be read as a stream weight without checking which branch it took.
  #
  # WHY IT WAS RETIRED, in one line, because the reason is not the one the
  # earlier handoffs gave: it is a free error scale on the stream that already
  # outvotes the partition terms 40:1, so the better CO2 was fitted the LOUDER
  # the CO2 stream became (2.04x across the two points measured). Positive
  # feedback on the dominant constraint. The stated grounds -- boundary-pinned,
  # unidentified, bad for conditioning -- were measured and did NOT hold
  # (max |r| with any other parameter 0.043; posterior interior and unimodal on
  # the sampling scale; tightened 2.08-5.79x vs prior). See
  # calibration/diag_sigma_co2.R and the 2026-08-15 CHANGELOG entry.
  for (st in c("MLO", "SPO")) {
    o <- obs$co2_ann[[st]]; m <- ms$co2[[st]]
    if (is.null(o) || !nrow(o)) next
    k <- match(o$year, m$year)
    good <- !is.na(k)
    sd <- if (is.null(err$sigma_co2)) LIK_CO2_REP_ERR
          else sqrt(err$sigma_co2^2 + LIK_CO2_REP_ERR^2)
    # station = box - rep_dC  (see the LIK_REP_SOURCE_D13C block)
    pred <- m$level[k[good]] - (if (is.null(err$rep_dC)) 0 else err$rep_dC)
    add(paste0("co2_level_", st),
        sum(stats::dnorm(o$level[good], pred, sd, log = TRUE)))
  }

  # ---- CO2 seasonal cycle: per-year harmonic coefficients ------------
  # What the annual reduction discards, restored as an explicit statistic and
  # scored year by year (see the note on LIK_SEAS_WINDOW). This is the ONLY
  # thing constraining seas_amp_* and seas_phase_*.
  for (st in c("MLO", "SPO")) {
    o <- obs$co2_seas[[st]]; m <- ms$co2_seas[[st]]
    if (is.null(o) || is.null(m)) next
    k <- match(o$year, m$year); good <- !is.na(k)
    add(paste0("co2_seasonal_", st),
        sum(stats::dnorm(o$a[good], m$a[k[good]], o$sd_a, log = TRUE)) +
        sum(stats::dnorm(o$b[good], m$b[k[good]], o$sd_b, log = TRUE)))
  }

  # ---- d13C seasonal cycle (2026-08-18; see LIK_USE_D13C_SEAS) -------
  # Same shape as the CO2 seasonal term: per-year harmonic coefficients against
  # the observed interannual sd. Skips VISIBLY (stream absent under by_stream)
  # when the obs target is missing, same contract as everything else here.
  if (LIK_USE_D13C_SEAS) for (st in c("MLO", "SPO")) {
    o <- obs$d13_seas[[st]]; m <- ms$d13_seas[[st]]
    if (is.null(o) || is.null(m)) next
    k <- match(o$year, m$year); good <- !is.na(k)
    add(paste0("d13c_seasonal_", st),
        sum(stats::dnorm(o$a[good], m$a[k[good]], o$sd_a, log = TRUE)) +
        sum(stats::dnorm(o$b[good], m$b[k[good]], o$sd_b, log = TRUE)))
  }

  # ---- ice-core CO2, independent ------------------------------------
  # LAW DOME IS AT 66.7 S, so the like-for-like model series is the SH box.
  # This scored against co2_NH until 2026-08-22, on the comment "SH-cored but
  # globally well mixed pre-1900". That argument is sound for the 96 pre-1900
  # rows and fails progressively after: 159 of 255 rows are post-1900 and 52 are
  # post-1958, where the model's own NH-SH gradient over the scored years runs
  # +0.61 (1900-1940) -> +0.82 (1940-1958) -> +1.75 ppm (1958-1997).
  #
  # diag_co2_level_swing.R:66 already used co2_SH, with the same reasoning, so
  # the OBJECTIVE and the DIAGNOSTIC that produced the sec.4 GATE D swing table
  # disagreed about the same observations and were quoted interchangeably across
  # handoffs 21c and 21d.
  #
  # Measured by diag_ice_hemisphere.R at mode_fit_pumpN: worth +16.9 log-units,
  # and 1.76 ppm (16 %) of the 11.20 ppm era swing was this choice, not the
  # model. NOTE: THIS CHANGES THE OBJECTIVE -- nothing fitted before 2026-08-22
  # is comparable across it.
  # ---- OPTIONAL: a localised DISCREPANCY window on the ice term ------
  # ADDED 2026-08-23 (Marcus): "recognizing that we can't solve the mid-century
  # pause, is there an artificial correction for just that period that would let
  # the rest of the model solve better?"
  #
  # WHAT THIS IS AND IS NOT. It is NOT a fitted shape -- that is the sec.12c LUC
  # time-profile idea the 2026-08-22 panel withdrew, because a free function in
  # a model with no discrepancy term absorbs real signal and returns it as a
  # discovery. This is the OPPOSITE move: it DECLARES an interval unexplained
  # and inflates its sigma so it cannot steer parameters that have to serve the
  # other 250 years. It adds NO parameter, so it cannot fit anything.
  #
  # THE JUSTIFICATION IS EXTERNAL, WHICH IS WHAT MAKES IT LEGITIMATE. The
  # 1940-1955 plateau (Etheridge et al. 1996; Rubino et al. 2019) requires
  # 2-3 GtC/yr of uptake AFTER firn smoothing is accounted for, and Bastos et
  # al. (2016) report a 0.9-2.0 PgC/yr mismatch across state-of-the-art
  # reconstructions with four LUC datasets: NO model reproduces it. Widening the
  # sigma where the field has a known, named, unexplained feature is a statement
  # about model adequacy, not a tuning knob. See
  # notes/lit_2026-08-23_1940s_co2_plateau.md.
  #
  # DEFAULT IS OFF (inflation 1.0) so every existing result reproduces exactly.
  # Set LIK_ICE_DISCREPANCY_INFLATE > 1 to activate. IT CHANGES THE OBJECTIVE:
  # a refit is owed, and no logL is comparable across it.
  #
  # *** AND THE MEASUREMENT SAYS DO NOT POINT IT AT THE PLATEAU. *** The window
  # was built for the mid-century, then measured before being used, and the
  # premise does not hold. Per-era ice fit at the 2026-08-23 mode:
  #
  #   era          n   mean resid   logL/row
  #   1900-1935   49       -4.08      -2.90
  #   1935-1960   61       -1.21      -2.58   <- the plateau: SECOND-BEST era
  #   1960-1997   49       +4.83      -3.07   <- the worst
  #
  # The plateau window is where the model's ~8.9 ppm SWING CROSSES ZERO, so it
  # is among the BEST-fitting quarter of the record, not the worst. Inflating
  # its sigma would delete good rows, leave both bad wings, and give the swing
  # MORE freedom to steepen. The misfit is in the WINGS.
  #
  # AND NO CONSTANT FIXES A SWING, WHICH IS THE GENERAL POINT. Applying rep_dC
  # to the ice term as well -- which Test 1 of the 2026-08-23 session says is
  # the CONSISTENT thing to do, since ice - SPO = -0.31 +/- 0.15 ppm in the
  # 1962-96 overlap, i.e. they read the same air -- repairs 1960-97 (+4.83 ->
  # -0.74) and wrecks everything earlier (1750-1850: -0.93 -> -6.49), for
  # -263.0 log-units, and leaves the swing at +8.91 ppm EXACTLY UNCHANGED. A
  # constant cannot change a difference. The defect is a SHAPE error and only a
  # time-varying term reaches it -- see the handoff for why that term belongs on
  # the EMISSIONS INPUT (GCB's own imbalance is +1.30/+1.62 GtC/yr in the same
  # decades) rather than on the observations.
  ice_sd <- obs$ice$sd
  if (LIK_ICE_DISCREPANCY_INFLATE != 1) {
    kd <- obs$ice$year >= LIK_ICE_DISCREPANCY_WIN[1] &
          obs$ice$year <= LIK_ICE_DISCREPANCY_WIN[2]
    ice_sd[kd] <- ice_sd[kd] * LIK_ICE_DISCREPANCY_INFLATE
  }
  mod <- interp("co2_SH", obs$ice$year)
  add("co2_icecore", sum(stats::dnorm(obs$ice$CO2ppm, mod, ice_sd, log = TRUE)))

  # ---- d13C annual level ---------------------------------------------
  # Level here; the SEASONAL cycle is scored by its own term since 2026-08-18
  # (see LIK_USE_D13C_SEAS -- the old "would double-count one mechanism"
  # justification conflated one mechanism with one measurement).
  for (st in c("MLO", "SPO")) {
    o <- obs$d13_ann[[st]]; m <- ms$d13[[st]]
    if (is.null(o) || !nrow(o) || is.null(m)) next
    k <- match(o$year, m$year)
    good <- !is.na(k)
    # `sigma_d13c` RETIRED 2026-08-18, and kept REACHABLE under the same absence
    # contract `sigma_co2` uses, so every diagnostic written before today
    # reproduces its numbers exactly:
    #   err$sigma_d13c ABSENT  -> sd = LIK_D13C_REP_ERR      (the objective)
    #   err$sigma_d13c PRESENT -> sd = sqrt(s^2 + REP^2)     (legacy parity)
    #
    # WHY, and it overturns the 2026-08-15 decision to leave it free. That
    # decision's stated ground was that self-weighting "is specific to the
    # dominant stream; a free scale on a MINOR stream is a robustness valve
    # rather than a feedback loop". calibration/diag_fit_at_mode.R measured the
    # premise and it does not hold, because the d13C residual is BIAS, not
    # scatter, and a free scale cannot tell the two apart:
    #   de-biased scatter  MLO 0.0328 / SPO 0.0361 permil
    #   fixed rep floor                     0.0500 permil
    #   fitted sigma_d13c                   0.1931 permil
    # The scatter sits BELOW the floor the stream already carries, so
    # `sigma_d13c` was explaining no scatter at all -- its whole value was
    # absorbing a +0.19 permil structural bias, at 4x the representation error.
    # That is a robustness valve venting the signal.
    #
    # `sigma_d14c` IS NOT RETIRED, and the same measurement is why: its
    # de-biased scatter is 14.0 / 12.1 permil against an observational sd of
    # ~4.2, so it has real excess scatter to explain and is doing its job.
    sd <- if (is.null(err$sigma_d13c)) LIK_D13C_REP_ERR
          else sqrt(err$sigma_d13c^2 + LIK_D13C_REP_ERR^2)
    # station = box - rep_dC * (d_s - d13C_box) / CO2_box, evaluated on the
    # model's OWN state at each scored year.
    pred <- m$level[k[good]]
    if (!is.null(err$rep_dC) && err$rep_dC != 0) {
      cbox <- ms$co2[[st]]$level[match(o$year[good], ms$co2[[st]]$year)]
      conv <- (LIK_REP_SOURCE_D13C - pred) / cbox
      pred <- pred - err$rep_dC * conv
    }
    add(paste0("d13c_level_", st),
        sum(stats::dnorm(o$level[good], pred, sd, log = TRUE)))
  }

  # ---- INTERHEMISPHERIC GRADIENT (2026-08-15, review item 5) ---------
  # The term DESIGN gate 9 has always claimed and the objective never had.
  #
  #     obs_grad(y) ~ N(model_grad(y) + off, sigma)
  #
  # `off` is a CALIBRATED offset, not a fitted-away residual -- see the block on
  # LIK_GRAD_CO2_SD for why a two-box model's box gradient is not the station
  # gradient and what happens if that is scored as zero.
  #
  # THE OFFSET IS SUPPLIED THROUGH `err`, AND ITS ABSENCE SKIPS THE TERM rather
  # than defaulting it to zero. Same contract as `deep`: a caller that has not
  # been updated (every diagnostic written before this date passes only the
  # three sigmas) sees the stream ABSENT under by_stream, which is visible in
  # the report. A silent zero offset would be a wrong answer that looked like a
  # right one, and would put the whole -0.45 ppm representation constant onto
  # tau_ex without anything saying so.
  #
  # THE TWO OFFSETS DO NOT MEAN THE SAME THING, and the code should not pretend
  # they do. For CO2 the fractional offset is 0.45/2.43 = 19 % of the gradient,
  # which is what a station-below-the-source-region argument predicts. Applying
  # that same fraction to d13C predicts 0.013 permil; the measured d13C offset
  # is 0.10, EIGHT TIMES larger. So `grad_off_d13c` is absorbing the known
  # STRUCTURAL d13C misfit (the Suess overshoot, project note
  # d13c_suess_overshoot_structural), not a representation constant -- which is
  # exactly why its measurement said b = 1 is admissible and why its prior is
  # wide. In effect the d13C gradient term is a SHAPE term. Stated here so no
  # one later reads a fitted grad_off_d13c as a representation estimate.
  if (LIK_USE_GRADIENT) {
    for (sp in list(list(nm = "co2",  obs_g = obs$co2_grad,  mod = ms$co2,
                         off = err$grad_off_co2,  sd = LIK_GRAD_CO2_SD),
                    list(nm = "d13c", obs_g = obs$d13c_grad, mod = ms$d13,
                         off = err$grad_off_d13c, sd = LIK_GRAD_D13C_SD))) {
      if (is.null(sp$off) || !is.finite(sp$off)) next
      A <- sp$mod$MLO; B <- sp$mod$SPO
      if (is.null(A) || is.null(B) || is.null(sp$obs_g) || !nrow(sp$obs_g)) next
      mg <- A$level[match(sp$obs_g$year, A$year)] -
            B$level[match(sp$obs_g$year, B$year)]
      good <- is.finite(mg)
      if (!any(good)) next
      add(paste0(sp$nm, "_gradient"),
          sum(stats::dnorm(sp$obs_g$grad[good], mg[good] + sp$off, sp$sd,
                           log = TRUE)))
    }
  }

  # ---- D14C annual means, with representation error -------------------
  # Model side is its own annual MEAN, not a mid-year sample: the observation is
  # a mean, and during the bomb rise the two differ by several permil.
  for (hh in c("NH", "SH")) {
    o <- if (hh == "NH") obs$d14_nh_ann else obs$d14_sh_ann
    m <- ms$d14[[hh]]
    if (is.null(m)) next
    k <- match(o$year, m$year); good <- !is.na(k)
    sd <- sqrt(o$sd[good]^2 + err$sigma_d14c^2)
    add(paste0("d14c_", hh),
        sum(stats::dnorm(o$value[good], m$mean[k[good]], sd, log = TRUE)))
  }

  # ---- IntCal20 pre-bomb Suess decline -------------------------------
  if (!is.null(obs$intcal)) {
    ic <- obs$intcal[obs$intcal$year >= 1750 & obs$intcal$year < 1950, ]
    mod <- interp("d14c_NH", ic$year + 0.5)
    add("d14c_intcal", sum(stats::dnorm(ic$d14c, mod,
                           sqrt(ic$err^2 + LIK_D14C_REP_OTHER^2), log = TRUE)))
  }

  # ---- ocean excess 14C inventory (design note 5) ---------------------
  # The only term that prices the ocean 14C sink directly. Excess is measured
  # against the run's OWN first row, which is the 1750 steady state by
  # construction -- so this costs no extra integration.
  if (LIK_USE_EXCESS_C14 && !is.null(obs$excess_c14) &&
      !is.null(out$ocean_C14)) {
    e   <- obs$excess_c14
    yrv <- floor(out$t + 1e-9)
    # Refuse to score rather than mis-baseline: if the run does not start at the
    # spinup year, out$ocean_C14[1] is not the natural inventory. by_stream then
    # shows the term ABSENT, which is visible; a wrong baseline would not be.
    if (yrv[1] == LIK_EXCESS_C14_BASE_YEAR && all(e$year %in% yrv)) {
      # annual mean of the reference year, matching how every other stream is
      # scored; the ocean inventory has no seasonal cycle worth resolving.
      m <- vapply(e$year, function(y) mean(out$ocean_C14[yrv == y]), numeric(1))
      r <- ccx_c14_kmol(m - out$ocean_C14[1]) - e$centre
      add("excess_c14_ocean",
          -0.5 * (drop(crossprod(r, e$prec %*% r)) + e$logdet +
                    length(r) * log(2 * pi)))
    }
  }

  # ---- deep-ocean D14C, GLODAPv2 (see LIK_D14C_DEEP_NEFF) -------------
  # One scalar, one Gaussian. The only term in the objective that prices ocean
  # VENTILATION; everything else touching kz does so through d13C.
  if (LIK_USE_D14C_DEEP && !is.null(deep) && is.finite(deep)) {
    tg <- ccx_deep_d14c_target()
    if (!is.null(tg))
      add("d14c_deep_ocean",
          stats::dnorm(tg$target, deep, tg$sd, log = TRUE))
  }

  # ---- ocean DIC and d13C GRADIENTS, GLODAPv2 (see LIK_USE_OCEAN_GRAD) -
  # The only terms in the objective a biological pump can move. Two scalars,
  # two Gaussians. `ocean_grad` is built by ccx_ocean_grad_scored(), which owns
  # the epoch lookup and the h_ml gate; its ABSENCE skips both terms visibly.
  #
  # WHILE THE MODEL HAS NO PUMP THESE ARE A CONSTANT (~71-136 log-units): the
  # interior is uniform to machine precision, so the gradient is 0 for every
  # parameter and the terms cannot distort the posterior. test-likelihood.R
  # asserts exactly that, because the pump breaks it ON PURPOSE and the day it
  # stops being true must be visible rather than inferred.
  #
  # THE ALKALINITY ROW (third scalar, added 2026-08-16b) IS DIFFERENT IN KIND
  # AND MUST NOT BE READ AS THE OTHER TWO. DIC and d13C are STATE VARIABLES, so
  # their gradients are computed quantities that already move (transient
  # leverage <= 0.09 sigma). The model carries NO ALKALINITY at all -- it enters
  # the mixed-layer carbonate solve and nowhere else -- so its gradient is
  # EXACTLY 0 until a carbonate pump exists, and this term is a hard constant of
  # -8.38 log-units with LITERALLY zero leverage. It is shipped anyway, on
  # Marcus' instruction (2026-08-16b) and for the same reason the DIC row was
  # shipped before the pump: the constraint has to be in the objective for the
  # pump to be scored against it. Do NOT quote it as evidence about anything
  # until ccx_model_ocean_alk_gradient() is given a pump.
  if (LIK_USE_OCEAN_GRAD && !is.null(ocean_grad)) {
    tg <- ccx_ocean_gradient_target()
    # ⚠ LOUD, NOT SILENTLY SKIPPABLE. Since option 5 was adopted these rows are
    # scored at sigma_eff(h_ml), which ccx_ocean_grad_scored() attaches. A hand-
    # built `ocean_grad` without it would otherwise score at sigma_obs -- the
    # RETIRED objective -- and produce a number that looks comparable and is not.
    if (!is.null(tg) && is.null(ocean_grad$sd_eff))
      stop("ccx_loglik(): `ocean_grad` carries no `sd_eff`. Since 2026-08-28 the ",
           "ocean-gradient rows are scored at the INFLATED sigma. Build the ",
           "argument with ccx_ocean_grad_scored(out, spin), which attaches it; ",
           "scoring at sigma_obs is the retired objective, not a fallback.")
    if (!is.null(tg))
      for (k in list(c("dic", "ocean_grad_dic"), c("d13c", "ocean_grad_d13c"),
                     c("alk", "ocean_grad_alk"))) {
        # A ROW THE CALLER DID NOT SUPPLY IS ABSENT, NOT ZERO. `length(v) == 1L`
        # is doing real work here: every caller written before 2026-08-16b passes
        # an `ocean_grad` with no `alk` element, and is.finite(NULL) is
        # logical(0), which is an error in `if` rather than FALSE.
        v <- ocean_grad[[k[1]]]
        if (!is.null(tg[[k[1]]]) && length(v) == 1L && is.finite(v))
          add(k[2], stats::dnorm(tg[[k[1]]]$target, v,
                                 ocean_grad$sd_eff[[k[1]]], log = TRUE))
      }
  }

  # ---- GCB sinks: PARTITION only -------------------------------------
  # TWO TRAPS, both live from this term's creation, both fixed 2026-08-14.
  #
  # (a) NET vs GROSS -- the one that mattered. GCB's `land_sink` column is
  #     S_LAND, the residual sink ALONE. The model's d(land_C)/dt is that sink
  #     MINUS the land-use flux also removed from the pools. The two were nearly
  #     the same quantity while land-use carbon was being regrown and are not
  #     now: comparing them asked the model to over-absorb by exactly E_LUC
  #     (~1.37 GtC/yr recently) and INVERTED the term's pull on beta. As shipped
  #     it wanted beta to RISE, bottoming near 0.85; corrected, its own optimum
  #     is beta ~ 0.39 and it resists rising beta. Nothing caught it for months
  #     because the wrong sign pushed the same way as the CO2 streams.
  #     Same trap as the one fixed in the diagnostics at cc3abd5, but inside the
  #     objective the MCMC optimises.
  #     The gross sink must be reconstructed with the MODEL'S OWN land-use flux,
  #     which is luc_scale times GCB's -- hence the `luc` argument. Its NULL
  #     default is GCB's own column, bit-identical to the forcing at
  #     luc_scale = 1 (verified 1959-2024, max |diff| = 0), so every existing
  #     caller stays correct without knowing about the argument.
  #     `gcb_ocean_sink` has no E_LUC analogue and was never affected.
  #
  # (b) YEAR ALIGNMENT. The previous code diffed ANNUAL MEANS of the stock,
  #     which is the flux over [mid-year y-1, mid-year y] -- half a year off
  #     from the calendar-year flux GCB reports. Worth ~0.015 GtC/yr of bias
  #     against a sigma of 0.4-1.5, i.e. nothing; but it ALIASES exactly the
  #     interannual variability a partition constraint exists to use. The stock
  #     is now interpolated to calendar-year BOUNDARIES and differenced.
  yrs <- sort(unique(floor(out$t + 1e-9)))
  bnd <- c(yrs, max(yrs) + 1L)
  if (length(bnd) > 2) {
    # Linear, with linear EXTRAPOLATION at the two ends. On a monthly grid the
    # first and last year boundary fall half a month outside the run, and
    # approx(rule = 2) would hold the stock flat across that gap and silently
    # under-count the first and last year's flux. Half a month of a 3 GtC/yr
    # sink is 0.13 GtC -- small, but it would land entirely on the two end
    # years rather than spread out, which is the shape of a bug.
    tt <- out$t; n <- length(tt)
    stock_at <- function(v) {
      y  <- stats::approx(tt, v, xout = bnd)$y
      lo <- bnd < tt[1]; hi <- bnd > tt[n]
      if (any(lo)) y[lo] <- v[1] + (bnd[lo] - tt[1]) * (v[2] - v[1]) / (tt[2] - tt[1])
      if (any(hi)) y[hi] <- v[n] + (bnd[hi] - tt[n]) * (v[n] - v[n - 1]) /
                                     (tt[n] - tt[n - 1])
      y
    }
    flux <- data.frame(year  = utils::head(bnd, -1),
                       ocean = diff(stock_at(out$ocean_C)),
                       land  = diff(stock_at(out$land_C)))
    if (is.null(luc))
      luc <- data.frame(year = obs$gcb$year, eluc = obs$gcb$luc)
    g <- merge(as.data.frame(obs$gcb)[, c("year", "ocean_sink", "land_sink")],
               flux, by = "year")
    g <- merge(g, luc, by = "year")
    if (nrow(g) > 2) {
      add("gcb_ocean_sink",
          sum(stats::dnorm(g$ocean_sink, g$ocean, LIK_GCB_OCEAN_SD, log = TRUE)))
      add("gcb_land_sink",
          sum(stats::dnorm(g$land_sink, g$land + g$eluc,
                           LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE, log = TRUE)))
    }
  }
  if (by_stream) return(unlist(parts))
  ll <- sum(unlist(parts))
  if (!is.finite(ll)) return(-Inf)
  ll
}
