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
LIK_LAND_SINK_INFLATE <- 3.0         # multiplier on GCB land-sink sigma (Q1)

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
LIK_D14C_DEEP_NEFF <- 20             # effective sample size for the deep mean
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
       co2_seas = lapply(co2, ccx_seasonal_target))
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
                       by_stream = FALSE) {
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
    add(paste0("co2_level_", st),
        sum(stats::dnorm(o$level[good], m$level[k[good]], sd, log = TRUE)))
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

  # ---- ice-core CO2, independent ------------------------------------
  mod <- interp("co2_NH", obs$ice$year)   # SH-cored but globally well mixed pre-1900
  add("co2_icecore", sum(stats::dnorm(obs$ice$CO2ppm, mod, obs$ice$sd, log = TRUE)))

  # ---- d13C annual level ---------------------------------------------
  # Level only. The model's d13C seasonality is a derived consequence of the
  # same NEP harmonic the CO2 seasonal statistic already constrains, so scoring
  # it again would double-count one mechanism.
  for (st in c("MLO", "SPO")) {
    o <- obs$d13_ann[[st]]; m <- ms$d13[[st]]
    if (is.null(o) || !nrow(o) || is.null(m)) next
    k <- match(o$year, m$year)
    good <- !is.na(k)
    sd <- sqrt(err$sigma_d13c^2 + LIK_D13C_REP_ERR^2)
    add(paste0("d13c_level_", st),
        sum(stats::dnorm(o$level[good], m$level[k[good]], sd, log = TRUE)))
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
