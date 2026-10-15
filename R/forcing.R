# =====================================================================
# forcing.R — assemble every external driver onto the model's monthly axis.
#
# This is the single place where acquired data (data/*.rds, written by
# data-raw/build_calibration_data.R) becomes model input. Every choice made
# here -- hemispheric splits, interpolation, gap handling, unit conversion --
# is a modelling decision, so each is stated inline rather than buried.
#
# See DATA.md for the provenance of every input and a summary of this pipeline.
#
# THE CENTRAL NUMERICAL CARE: annual -> monthly interpolation must CONSERVE the
# annual total. Emissions drive cumulative carbon, so an interpolation that
# quietly changes annual sums changes the answer. `ccx_annual_to_monthly()`
# interpolates smoothly and then corrects each year additively so its 12 monthly
# values average exactly to the annual value. Gated by test-forcing.R.
# =====================================================================

# ---- named constants: every split and gap rule is declared here -----
# WITHIN-YEAR EMISSION SEASONALITY (2026-08-15, review item 5c). TRUE applies
# the sourced hemispheric monthly climatologies; FALSE reproduces every result
# produced before this date, bit for bit, because the weights are the only thing
# that changes and w == 1 is the incumbent. The switch exists so that "what does
# the seasonality buy?" is one flag rather than a git checkout.
FORC_USE_EMIS_SEASONALITY <- TRUE
# ---- artificial mid-century sink (2026-08-23) -----------------------
# OFF by default (rate 0). See the block in ccx_build_forcing() for what it is
# and what it is for.
# Window brackets the published 1940-1955 plateau; rate in GtC/yr.
CCX_ARTIFICIAL_SINK_WIN  <- c(1942, 1949)
CCX_ARTIFICIAL_SINK_RATE <- as.numeric(Sys.getenv("CCX_SINK_RATE", "0"))
# THE ISOTOPIC ARM (added 2026-08-23c). The same CO2 removal, routed three
# different ways, because the two hypotheses Marcus posed -- "an artificial
# ocean sink" versus "reduce emissions during that period" -- produce the SAME
# CO2 trajectory at the point of removal and differ ONLY isotopically. The
# discriminator is therefore d13C and D14C, which is also how the published
# double-deconvolution attributes the 1940s plateau.
#
#   "foss"  negative FOSSIL emission. Removed carbon is 14C-FREE and -28 permil,
#           so removing it UNDOES Suess dilution and D14C RISES. This is the
#           2026-08-23 incumbent and it is what the pre-bomb record REJECTED
#           (+0.6 -> +13.5 permil residual, ~52 log-units).
#   "luc"   the land-use flux is reduced instead, so the carbon simply stays in
#           the WOOD pool and never reaches the atmosphere. It leaves at the
#           vegetation box's own emergent ratio (~-25 permil, and NOT 14C-free),
#           an intermediate case. Note this ALSO reduces the model E_LUC that
#           ccx_forcing_eluc_annual() feeds the gcb_land_sink term -- correct for
#           the hypothesis, but it means this arm perturbs a scored stream by a
#           second route that the other two do not.
#   "ocean" the flux is routed atmosphere -> MIXED LAYER through add_flux at the
#           model's OWN air-sea downward fractionation, carrying 14C
#           unfractionated at the source ratio. This is the only arm that is a
#           real UPTAKE rather than a negative emission: carbon stays in the
#           system, ocean inventory and excess-14C stay meaningful, and the
#           mixed layer can give some of it back. It is the arm both the 14C
#           result and the published d13C deconvolution favour.
#
# "foss" is the default so that every result produced before 2026-08-23c
# reproduces bit for bit. At rate 0 all three modes are the untouched model.
CCX_ARTIFICIAL_SINK_MODES <- c("foss", "luc", "ocean")
CCX_ARTIFICIAL_SINK_MODE  <- local({
  m <- Sys.getenv("CCX_SINK_MODE", "foss")
  if (!m %in% CCX_ARTIFICIAL_SINK_MODES)
    stop("CCX_SINK_MODE must be one of ",
         paste(CCX_ARTIFICIAL_SINK_MODES, collapse = ", "), "; got ", m)
  m
})

FORC_FOSS_NH_SHARE <- 0.9201 # fossil CO2 emitted in the NH. MEASURED (Marcus,
                             # 2026-08-15, review item 5) by the EDGAR v4.3.2
                             # country aggregation in
                             # data-raw/extract_emission_seasonality.py --
                             # Crippa et al. 2020, Sci Data 7:121. Supersedes a
                             # 0.95 that had carried a "PROVISIONAL" comment
                             # since it was written. It moves the modelled
                             # 2015-24 MLO-SPO gradient 5.03 -> 4.67 ppm toward
                             # the observed 3.74, the new gradient term prefers
                             # it by +95 log-units, and the rest of the
                             # objective is essentially indifferent (-1.5) --
                             # a bias correction, the same shape as 5b and 5c.
                             # 0.95 is recoverable by setting this constant.

# ---- OBSERVED SST (HadSST4) and its forward scaling (2026-08-18) -----
# Historical hemispheric SST anomalies are PRESCRIBED from HadSST.4.2.0.0
# (data/forcing_sst.rds, re-based to 1850-1900); beyond the observed record the
# anomaly follows the gmst column INCREMENTALLY at a fixed ratio:
#   sst_anom_h(t) = <obs over seam> + CCX_SST_RATIO_h * (gmst(t) - <gmst over seam>)
# with both seam means taken over the last CCX_SST_SPLICE_YR observed years --
# never a single year (standing baselining rule). The ratios are the LAST-30-YR
# observed regressions of HadSST4 on IGCC GMST, no intercept, common 1850-1900
# base (calibration/diag_hemis_t_ratios.R, 1995-2024 row). MEASURED, and the
# choice is documented there: the window-to-window spread of that regression
# (NH 0.61-1.10 over the record) is FORCING-PATTERN history (mid-century NH
# aerosols), not warming-level dependence, so constant-forward is the honest
# simple rule; a CMIP6-derived warming-level scaling can replace this function
# without touching anything else. Marcus 2026-08-18: HadSST4; constant ratios.
FORC_SST_PRE1850_MEAN <- TRUE   # FALSE = the pre-09-16 d single-year-1850 hold (for pricing / reproduction only)
CCX_SST_RATIO_NH <- 0.819
CCX_SST_RATIO_SH <- 0.762
CCX_SST_SPLICE_YR <- 10

# TIME-VARYING LAND-USE HEMISPHERIC SHARE (2026-08-15, review item 5b). TRUE
# uses the OSCAR-sourced per-year series in data/forcing_luc_nh_share.rds; FALSE
# falls back to the constant below and reproduces every result produced before
# this date, bit for bit. Same switch discipline as FORC_USE_EMIS_SEASONALITY.
FORC_USE_LUC_NH_SHARE_TS <- TRUE
FORC_LUC_NH_SHARE  <- 0.55   # land-use change is far more tropical/SH-weighted
                             # than fossil. THE FALLBACK, not the default, since
                             # 2026-08-15: measured against OSCAR's regional
                             # E_LUC the true share falls 0.84 -> 0.40 across the
                             # record and a constant is wrong at BOTH ends (0.55
                             # is not even the flux-weighted mean, which is
                             # 0.620). Retained because it is what every result
                             # before 2026-08-15 was produced under.
FORC_NUC_NH_SHARE  <- 0.95   # nuclear-industry 14C: the 22 reporting countries
                             # are overwhelmingly NH. PROVISIONAL.
FORC_BOMB_NH_SHARE <- 0.90   # atmospheric weapons tests were overwhelmingly NH.
FORC_GMST_PRE1850  <- 0      # IGCC starts 1850; earlier GMST anomaly set to 0
                             # (the model's own baseline is the 1750 spinup).
FORC_LUC_PRE_WARN  <- 5      # GtC of pre-window land-use carbon above which a
                             # windowed run is warned that ccx_spinup()'s
                             # preindustrial land is no longer its fixed point.
FORC_LAND0_NOMINAL <- 2130   # GtC, preindustrial EXCHANGING land carbon at the
                             # default parameters (diag_land_topology.R [3]) --
                             # the land that land use can clear. With the inert
                             # soil pool on (2026-09-30) total land is ~292 more;
                             # the warning's denominator deliberately excludes it.
                             # PRESENTATIONAL -- used only to express the
                             # warning above as a percentage. aux$land0 is the
                             # value the model actually integrates.
FORC_ENSO_PRE1948  <- 0      # Nino 3.4 starts 1948; no ENSO term before that.
                             # A DISCONTINUITY IN CONSTRAINT, not in physics:
                             # pre-1948 residuals lack an ENSO explanation.
                             # ⭐ AFTER FORC_ENSO_DEMEAN this zero is genuinely
                             # NEUTRAL -- it is the 1948-2024 mean state. Before
                             # it, zero was +0.218 degC of El Nino relative to
                             # the index's own mean.
FORC_ENSO_POST     <- 0      # ⛔ AFTER THE RECORD THE ANOMALY IS TAPERED TO THIS,
                             # NOT HELD (Marcus 2026-09-12: "taper ENSO to zero").
                             # Until 09-12 `approx(rule = 2)` held the LAST
                             # OBSERVED MONTH (+1.79 in 2026) for every later
                             # year -- at the hilda31s coefficients a permanent
                             # +1.98 GtC/yr land source and +0.69 ocean uptake,
                             # net +1.29 GtC/yr into the atmosphere in every SSP,
                             # coupled run and app run. The taper's e-folding time
                             # is the index's OWN, measured from its autocorrelation
                             # at build time (ccx_enso_efold_yr(), not a typed
                             # number): an anomaly of +1.79 is at 1/e after ~7 mo
                             # and gone within ~2 yr, as an observed event would be.
# ---- RULING A, ADOPTED 2026-09-02 (Marcus) --------------------------
# ⭐ THE MEAN OF THE Nino 3.4 INDEX IS A BASE-PERIOD CONVENTION, NOT A SIGNAL,
# AND IT IS REMOVED. `build_calibration_data.R` pins ENSO_CLIM_BASE to the WMO
# normal 1991-2020 -- fixed and RECENT -- so the Nino 3.4 box's own warming puts
# the early decades below zero BY CONSTRUCTION: mean -0.2178 over 1948-2024.
# Feeding that to a ONE-WAY GPP modulation loads a 35.5 yr chain instead of a
# 2 yr pool, which is the whole -65.74 the one-way term cost.
#
# THE EVIDENCE IS OBSERVATIONAL, not an inference from the build script: MEI.ext
# and Nino 3.4 correlate r = 0.896 over the same 696 months and their means have
# OPPOSITE SIGN (+0.140 vs -0.274). Two indices of one phenomenon, agreeing on
# the variability and disagreeing on the sign of the mean.
#
# AND IT WAS TESTED, with each candidate given its OWN four refitted
# `gamma_enso` coordinates so the comparison could not rank AMPLITUDE instead of
# INDEX (diag_enso_index_bakeoff.R, 09-02). `demean` won on BOTH SST products
# and BOTH spans with the same ordering each time -- v6 -1494.32 / -1490.86, v5
# -1493.13 -- worth +14.4 over `asis`; additionally removing the TREND costs
# 5-7. At the 09-01 basin vector, unrefitted, it is -1512.02 against `asis`
# -1568.49, recovering +56.48 = 86 % of the -65.74.
#
# ⚠ THE MEAN IS TAKEN OVER THE INDEX'S OWN RECORD, NOT OVER THE REQUESTED RUN
# WINDOW. A mean that moved with `yrs` would make the forcing depend on the span
# a caller asked for -- a 1750-2300 build and a 1948-2024 build would then see
# different ENSO, silently. The window is FIXED and named.
FORC_ENSO_DEMEAN     <- TRUE          # ⛔ FALSE reproduces the pre-adoption
                                      # model BIT FOR BIT. Same reproduction
                                      # path as ALPHA_AS_*_LEGACY; it is not a
                                      # tuning knob and nothing but a
                                      # provenance run should set it.
FORC_ENSO_DEMEAN_WIN <- c(1948, 2024) # the span the bake-off priced, = the
                                      # ENSO-active record. Changing it changes
                                      # what was tested.
# ---- THE ENSO INDEX IS A STRUCTURE AXIS (2026-09-29, Marcus) ------------
# The audit (CHANGELOG 09-29 d, item 3): demeaned is not detrended. The shipped
# index trends +0.0082 degC/yr over 1948-2024, which gamma_enso_land turns into
# a land source rising -0.26 -> +0.31 GtC/yr that every projection drops (the
# index tapers to 0). Marcus ruled "build both" detrend routes as values of one
# switch, price each, then pick one for Torch:
#   "demean"    -- RULING A, the shipped index. DEFAULT; bit-identical to before.
#   "detrend"   -- a linear fit over FORC_ENSO_DEMEAN_WIN removed from the PSL
#                  index (mean AND trend). Statistical.
#   "relsst_lp" -- ERSST v6 grid Nino 3.4 minus the 21-yr low-passed tropical
#                  mean (data-raw/build_enso_relsst.R), then demeaned over the
#                  same window. Observational. ⚠ A DIFFERENT PRODUCT's Nino 3.4:
#                  r 0.990 with nina34.data but 9 % more amplitude (slope 1.094),
#                  so only a comparison that refits the gammas ranks INDEX
#                  rather than AMPLITUDE (the 09-02 bake-off's rule).
# Every value keeps the ENSO-active span of the shipped index (from 1948): a
# relsst_lp that reached back to 1850 would add a century of ENSO constraint,
# a different experiment.
# It travels as the integer parameter `enso_index` (absent = "demean") so that
# a mode file carries it; ccx_enso_index_check() refuses a run whose forcing
# was built with a different index than its parameters name.
CCX_ENSO_INDEX_CODES <- c(demean = 0L, detrend = 1L, relsst_lp = 2L)
FORC_ENSO_RELSST_FILE <- file.path("data", "forcing_enso_relsst.rds")
# ---- THE AOD BACKGROUND IS A SECOND FORCING AXIS (2026-09-29, Marcus: "apply
# obvious fixes like the AOD background") ------------------------------------
# The CMIP7 AOD series (1850-2024) carries a non-zero QUIET stratosphere, and
# ccx_aod_at() returns 0 outside its coverage. The diffuse-light term
# npp * (1 + gamma_diff * aod) therefore sees the background as an ANOMALY: a
# step UP at 1850 (+0.031 GtC/yr) and DOWN at 2025 (-0.109 GtC/yr, the 2024
# anomaly and the background together), and the spinup year (1750) sits at 0
# while the record never does (audit-flag screen, CHANGELOG 09-29 e).
#   "legacy"  -- as shipped. DEFAULT; bit-identical, so objective #13 and every
#                registered mode are untouched.
#   "anomaly" -- subtract each hemisphere's quiet background (the mean over
#                FORC_AOD_BG_WIN, before the 1853 eruption; it equals the
#                series' own 1st percentile, 0.00210 global) inside the record,
#                0 before it, and past the record TAPER the last anomaly on the
#                series' OWN decay time (ccx_aod_efold_yr(), the ENSO-taper
#                precedent: measured, not typed).
CCX_AOD_MODE_CODES <- c(legacy = 0L, anomaly = 1L)
FORC_AOD_BG_WIN    <- c(1850, 1852)
# THE NUCLEAR-INDUSTRY 14C NH SHARE (2026-10-12; citation rulings row 20; label
# hilda_csl3v0kaidgbemwtc, field `nuc_share_ts`). "constant" = FORC_NUC_NH_SHARE (0.95), every
# mode registered before hilda31w (which runs "per_year"): the table's `nuc_share_NH` column carries that constant (the aux scalar's own
# value; a hand-built table without the column reaches both cores as NaN = the same scalar). "per_year" = the share of the 22-country files' OWN rows, year by year
# (data/forcing_nuc_nh_share.rds, data-raw/build_nuc_nh_share.R), held flat within a year and
# HELD at the nearest year outside the files (the source is zero there; the 14C tag still needs a
# number). Stamped as attr "nuc_share", checked at run time like the ENSO index.
CCX_NUC_SHARE_CODES <- c(constant = 0L, per_year = 1L)
# The nuclear-industry 14C SOURCE itself (2026-10-14): a tracked data/ input, so the
# loader can STOP without it rather than warn and run on zero (ccx_nuclear_c14_annual()).
FORC_NUC_C14_FILE <- file.path("data", "forcing_nuclear_c14.rds")

# ---------------------------------------------------------------------
#' Sourced hemispheric monthly emission seasonality, cached.
#'
#' @return the list written by data-raw/build_emission_seasonality.R, or NULL if
#'   the product is absent -- a missing optional file must degrade to the
#'   no-seasonality model rather than take the forcing down. ccx_build_forcing()
#'   then behaves exactly as it did before 2026-08-15.
ccx_emission_seasonality <- local({
  cache <- NULL
  function() {
    if (!is.null(cache)) return(cache)
    v <- tryCatch(readRDS(ccx_path("data", "forcing_emission_seasonality.rds")),
                  error = function(e) NULL)
    if (!is.null(v)) cache <<- v
    v
  }
})

#' Sourced time-varying NH share of E_LUC, cached.
#'
#' @return the list written by data-raw/build_luc_nh_share.R, or NULL if the
#'   product is absent -- a missing optional file must degrade to the constant
#'   rather than take the forcing down, exactly as the seasonality product does.
ccx_luc_nh_share_product <- local({
  cache <- NULL
  function() {
    if (!is.null(cache)) return(cache)
    v <- tryCatch(readRDS(ccx_path("data", "forcing_luc_nh_share.rds")),
                  error = function(e) NULL)
    if (!is.null(v)) cache <<- v
    v
  }
})

#' NH share of E_LUC for a set of calendar years
#'
#' The share is a per-year SCALAR applied to the whole of that calendar year, not
#' interpolated to months. Deliberate: the product is annual, and a calendar-year
#' step keeps `mean_year(luc_NH) == share(y) * mean_year(luc)` EXACT (which
#' test-luc-nh-share.R asserts) while placing the only discontinuity precisely on
#' the year boundary, where the per-year harmonic estimator cannot alias it into
#' the seasonal statistic. The step is ~0.003 GtC/yr -- the share moves ~0.0016
#' per year against an E_LUC of ~1.7 GtC/yr -- so smooth interpolation would buy
#' nothing and would cost the exact identity.
#'
#' OUTSIDE 1750-2018 THE END VALUE IS HELD, and that is an extrapolation, not a
#' measurement: every SSP run therefore splits its land-use emissions on a frozen
#' 2018 share (~0.385). Stated here because the alternative -- extrapolating the
#' 1750-2018 decline forward -- would run the NH share negative before 2260.
#'
#' @param yrs   calendar years wanted
#' @param which "share" (central), "share_lo" or "share_hi" -- the bracket ends
#'   exist so a sensitivity is one argument away, per the standing discipline.
#' @return numeric vector, one share per year; the constant FORC_LUC_NH_SHARE
#'   recycled if the switch is off or the product is missing.
ccx_luc_nh_share <- function(yrs, which = c("share", "share_lo", "share_hi")) {
  which <- match.arg(which)
  p <- if (FORC_USE_LUC_NH_SHARE_TS) ccx_luc_nh_share_product() else NULL
  if (is.null(p)) return(rep(FORC_LUC_NH_SHARE, length(yrs)))
  s <- p$share
  stats::approx(s$year, s[[which]], xout = yrs, rule = 2)$y
}

#' Impose a 12-month weight on a monthly series, CONSERVING every annual mean.
#'
#' Seasonality redistributes emissions within a year; it must not create or
#' destroy any. Multiplying by the weight does both, because the underlying
#' series is not flat within a year -- so each calendar year is rescaled back to
#' its own pre-weighting mean afterwards. That rescale is what makes the change
#' provably annual-total-neutral, which test-emission-seasonality.R asserts to
#' machine precision against the unweighted series.
#'
#' A year whose emissions are exactly zero rescales by 1 rather than 0/0.
#'
#' @param v monthly series, 12 values per year, month-major
#' @param yrs the calendar years v spans
#' @param w 12 weights; mean(w) == 1 is the no-seasonality case
ccx_seasonalise <- function(v, yrs, w) {
  stopifnot(length(w) == 12L, length(v) == 12L * length(yrs))
  yv  <- rep(yrs, each = 12)
  out <- v * w[rep(seq_len(12), length(yrs))]
  tgt <- tapply(v, yv, mean)
  got <- tapply(out, yv, mean)
  sc  <- as.numeric((tgt / got)[as.character(yv)])
  sc[!is.finite(sc)] <- 1
  out * sc
}

#' Interpolate an annual series to monthly, preserving annual means exactly
#'
#' Smooth (natural spline through year midpoints) then additively corrected so
#' each calendar year's 12 monthly values average to its annual value. Additive
#' rather than multiplicative correction because annual values can be zero or
#' negative (land-use change flux, ENSO index) and a multiplicative rescale
#' would blow up or flip sign.
#'
#' @param years  integer vector of years (need not be contiguous)
#' @param values numeric vector, same length
#' @param out_years integer vector of years to produce
#' @return numeric vector of length 12*length(out_years), month-major
ccx_annual_to_monthly <- function(years, values, out_years, method = c("spline", "constant")) {
  method <- match.arg(method)
  ok <- !is.na(values)
  years <- years[ok]; values <- values[ok]
  mid <- out_years + 0.5
  ann <- stats::approx(years + 0.5, values, xout = mid, rule = 2)$y

  if (method == "constant") {
    # Piecewise constant within each year. Exactly conserving, shape-preserving,
    # and CANNOT undershoot. Required for sharply peaked non-negative sources:
    # a spline through the bomb-14C series undershoots either side of the 1962
    # peak, and clipping those negatives back to zero ADDED 4.3 % to the
    # prescribed total -- i.e. quietly broke the calibrated magnitude.
    return(as.vector(matrix(rep(ann, each = 12), nrow = 12)))
  }

  t_m <- rep(out_years, each = 12) + (seq_len(12) - 0.5) / 12
  m   <- stats::spline(years + 0.5, values, xout = t_m, method = "natural")$y

  # additive per-year correction -> annual mean is exact
  m_mat <- matrix(m, nrow = 12)
  m_mat <- sweep(m_mat, 2, colMeans(m_mat) - ann, "-")
  as.vector(m_mat)
}

# ---------------------------------------------------------------------
#' Nuclear-industry 14C emissions, GBq/yr -> mol 14C/yr, annual
#'
#' Reads data/forcing_nuclear_c14.rds (data-raw/build_nuclear_c14_source.R): the
#' per-year sum of every annual file in data-raw/downloads/nuclear14c. Coverage is
#' incomplete by construction (e.g. USA reports only 2010-2023), so this is a
#' LOWER BOUND on the true industrial source -- stated in DATA.md, not hidden.
#'
#' ⛔ IT STOPS WITHOUT THE FILE (Marcus 2026-10-14: "Promote to data/ .rds +
#' stop() (Recommended)"; CHANGELOG 2026-10-14 h, j). Until then this summed the
#' CSVs AT RUN TIME and, when data-raw/downloads/nuclear14c was absent, WARNED
#' and set the source to ZERO: a different objective with no error. That hit
#' the Torch bundle (09-01), three frozen worktrees, and would have hit the
#' public app, whose DEPLOY.md excluded data-raw/ (Δ14C NH -3.9 permil by 2024).
#' The .rds lives in tracked data/, so every copy of the tree carries it.
#' Bit-identical to the old reader (tests/testthat/test-nuclear-c14-source.R).
#'
#' CACHED per file (2026-09-12, review B1): the periodic spinup builds three
#' forcings per objective evaluation, and re-reading the source was 12 % of an
#' evaluation. Same `local({cache})` idiom as ccx_emission_seasonality().
ccx_nuclear_c14_annual <- local({
  cache <- list()
  function(file = ccx_path(FORC_NUC_C14_FILE)) {
    key <- as.character(file)
    if (!is.null(cache[[key]])) return(cache[[key]])
    if (!file.exists(file))
      stop("the nuclear-industry 14C source ", file, " is missing. Build it with ",
           "data-raw/build_nuclear_c14_source.R; it is NOT optional (until 2026-10-14 its ",
           "absence silently set the industrial 14C source to zero).")
    r <- readRDS(file)
    v <- data.frame(year = r$year,
                    mol_per_yr = r$GBq * ccx_const("MOL_C14_PER_GBq"))
    cache[[key]] <<- v
    v
  }
})

#' The per-year GBq sum of the nuclear-14C CSVs in `dir` -- the BUILD-TIME reader
#'
#' Used by data-raw/build_nuclear_c14_source.R and its test only; nothing at run
#' time reads data-raw/. No default `dir` on purpose, so `grep 'ccx_path("data-raw"' R/`
#' still finds no run-time read (calibration/lib_run_inputs.R's header).
#' The rows kept and the sum are exactly the pre-2026-10-14 run-time reader's.
ccx_nuclear_c14_sum_files <- function(dir) {
  fs <- list.files(dir, pattern = "csv$", full.names = TRUE)
  if (length(fs) == 0) stop("no nuclear 14C files in ", dir)
  d <- do.call(rbind, lapply(fs, function(f) {
    x <- utils::read.csv2(f, stringsAsFactors = FALSE)
    data.frame(year = suppressWarnings(as.integer(x$Year)),
               GBq  = suppressWarnings(as.numeric(x$C14_tot_GBq)))
  }))
  d <- d[!is.na(d$year) & !is.na(d$GBq), ]
  aggregate(GBq ~ year, data = d, FUN = sum)
}

# ---------------------------------------------------------------------
#' Bomb 14C DELIVERY to the troposphere, monthly, mol 14C/yr
#'
#' Reads the measured input function built by
#' data-raw/build_bomb_c14_source.R from Tans (1981) SCOPE 16 Tables 1 and 2.
#'
#' NOT a production rate. The model's atmosphere is a single well-mixed
#' troposphere per hemisphere with no stratospheric box (R/model.R), so what
#' belongs here is the stratosphere->troposphere flux. Tans (p.133): the input
#' of bomb 14C into the troposphere equals the stratospheric decrease. Feeding
#' a production series into this slot delivers the 1961-62 tests to the
#' troposphere about a year early -- see the superseded shape below.
#'
#' The stored series is normalised to unit integral, so `total_kmol` alone sets
#' the magnitude and the calibrated bomb_total (Naegler & Levin 2006 prior)
#' continues to carry it.
ccx_bomb_c14_monthly <- function(total_kmol = 102) {
  b <- readRDS(ccx_path("data", "forcing_bomb_c14.rds"))
  data.frame(year = b$year, month = b$month,
             mol_per_yr = b$shape_per_yr * total_kmol * 1000)
}

#' Annual aggregate of the monthly delivery -- diagnostics and back-compat
ccx_bomb_c14_annual <- function(total_kmol = 102, years = 1945:1980) {
  b <- ccx_bomb_c14_monthly(total_kmol)
  a <- tapply(b$mol_per_yr, b$year, mean)
  out <- data.frame(year = years, mol_per_yr = 0)
  i <- match(as.character(years), names(a))
  out$mol_per_yr[!is.na(i)] <- as.numeric(a)[i[!is.na(i)]]
  out
}

# ---------------------------------------------------------------------
#' SUPERSEDED 2026-08-10 -- the provisional production-shaped placeholder.
#'
#' Kept only so the size of the correction can be reproduced. It put 54.0 % of
#' all bomb 14C into 1961-62 and 2.2 % into 1963; the measured input function
#' puts 13.2 % into 1961-62 and 27.2 % into 1963. Do not wire this back in.
#'
#' *** PROVISIONAL SHAPE -- see DATA.md "Outstanding data gaps". ***
#'
#' The design (Marcus, 2026-08-09) is a prescribed time SHAPE from atmospheric
#' test yields with the TOTAL calibrated, so the model PREDICTS the Delta14C
#' spike rather than fitting it. The total has a citable prior: Naegler & Levin
#' (2006) give 99.3-104.9 kmol for 1945-1980. The SHAPE does not: UNSCEAR 2000
#' Annex C holds the annual atmospheric test yields, but only as a PDF table
#' with no machine-readable release found.
#'
#' Until that is digitised, the shape below is a documented placeholder built
#' from the qualitative test history (peak testing 1961-62, with 1954, 1958 and
#' 1961-62 the most active years; total atmospheric yield ~440 Mt). It is
#' NORMALISED to unit integral, so `total_kmol` alone sets the magnitude and the
#' placeholder cannot silently set the amplitude. Do not report bomb-era 14C
#' results on this shape.
ccx_bomb_c14_annual_SUPERSEDED <- function(total_kmol = 102, years = 1945:1980) {
  # relative annual atmospheric test activity -- PROVISIONAL
  shape <- c(
    `1945` = 0.2, `1946` = 0.3, `1947` = 0.0, `1948` = 0.4, `1949` = 0.2,
    `1950` = 0.0, `1951` = 0.9, `1952` = 1.2, `1953` = 0.9, `1954` = 4.0,
    `1955` = 2.0, `1956` = 3.5, `1957` = 3.0, `1958` = 8.0, `1959` = 0.0,
    `1960` = 0.2, `1961` = 15.0, `1962` = 22.0, `1963` = 1.5, `1964` = 0.4,
    `1965` = 0.3, `1966` = 0.6, `1967` = 0.5, `1968` = 0.6, `1969` = 0.3,
    `1970` = 0.5, `1971` = 0.3, `1972` = 0.2, `1973` = 0.3, `1974` = 0.4,
    `1975` = 0.1, `1976` = 0.3, `1977` = 0.1, `1978` = 0.1, `1979` = 0.0,
    `1980` = 0.2)
  yr <- as.integer(names(shape))
  w  <- as.numeric(shape) / sum(as.numeric(shape))
  out <- data.frame(year = years, mol_per_yr = 0)
  idx <- match(out$year, yr)
  out$mol_per_yr[!is.na(idx)] <- w[idx[!is.na(idx)]] * total_kmol * 1000
  out
}

# ---------------------------------------------------------------------
#' A scenario's own annual CO2 emissions, from whichever file carries it
#'
#' The SSPs (RCMIP v5.1.0) and the van Vuuren markers (Zenodo v1.1.1, 2026-09-29)
#' live in two files with ONE schema. Both are stored UNSPLICED: the observed GCB
#' history is put over a scenario's past by the caller (app_splice_history()), so
#' the seam lives in one place. A key present in both files is an error.
CCX_SCENARIO_EMIS_FILES <- c("RCMIP v5.1.0" = "ssp_emissions.rds",
                             "van Vuuren 2026 (Zenodo v1.1.1)" = "vv_emissions.rds")
ccx_scenario_emissions <- function(scenario) {
  hit <- NULL
  for (src in names(CCX_SCENARIO_EMIS_FILES)) {
    p <- ccx_path("data", CCX_SCENARIO_EMIS_FILES[[src]])
    if (!file.exists(p)) next
    d <- as.data.frame(readRDS(p))
    d <- d[d$scenario == scenario, ]
    if (!nrow(d)) next
    if (!is.null(hit)) stop("scenario '", scenario, "' is in more than one emissions file")
    hit <- data.frame(year = d$year, fossil_GtC = d$fossil_GtC, luc_GtC = d$luc_GtC)
    attr(hit, "source") <- src
  }
  if (is.null(hit)) stop("Unknown scenario '", scenario, "'")
  hit
}

#' Which ENSO index a parameter list names (CCX_ENSO_INDEX_CODES; absent = "demean")
ccx_enso_index_of <- function(p) {
  v <- p$enso_index
  if (is.null(v)) return("demean")
  nm <- names(CCX_ENSO_INDEX_CODES)[match(as.integer(v), CCX_ENSO_INDEX_CODES)]
  if (length(nm) != 1 || is.na(nm))
    stop("ccx_enso_index_of(): enso_index = ", paste(v, collapse = ","),
         " is not one of ", paste(CCX_ENSO_INDEX_CODES, collapse = "/"))
  nm
}
#' Refuse a run whose forcing carries a different ENSO index than its parameters
#' name. A table with no stamp is taken as "demean" only when the parameters ask
#' for "demean": every pre-2026-09-29 caller keeps working, and a non-default arm
#' fed a hand-assembled table fails loudly instead of silently running the
#' shipped index ([[intersect_is_a_silent_default]]).
#' `p` is a parameter list or an index name. A table stamped "none" carries no
#' ENSO at all (its column is identically zero; ps_year_forcing() asserts that)
#' and is valid under every index.
ccx_enso_index_check <- function(p, F) {
  want <- if (is.character(p)) p else ccx_enso_index_of(p)
  have <- attr(F, "enso_index")
  if (identical(have, "none")) return(invisible(TRUE))
  if (is.null(have) && want == "demean") return(invisible(TRUE))
  if (!identical(have, want))
    stop("ENSO index mismatch: the parameters name '", want, "' but the forcing carries '",
         if (is.null(have)) "<unstamped>" else have,
         "'. Build it with ccx_build_forcing(enso_index = ccx_enso_index_of(params)).")
  invisible(TRUE)
}

#' The Nino 3.4 anomaly's own e-folding time, in years, from its autocorrelation
#'
#' The lag at which the monthly ACF first falls below 1/e, linearly
#' interpolated between the bracketing lags. DERIVED FROM THE DATA, never
#' typed ([[threshold_from_obs_or_law]]): on the 1948-2026 record it is ~0.6 yr
#' (between lags 7 and 8). ⚠ NOT the AR(1) lag-1 fit (-1/log(r1) = 1.29 yr on
#' the same record): ENSO is quasi-periodic, its ACF is not an exponential, and
#' the lag-1 fit overstates the persistence of a 2-7 yr oscillation by ~2x
#' (the ACF is 0.03 at 12 months and negative by 18).
#' @param x the monthly anomaly series (NA rows removed)
ccx_enso_efold_yr <- function(x) {
  x <- x[is.finite(x)]
  r <- stats::acf(x, lag.max = 60, plot = FALSE)$acf[-1]
  k <- which(r < exp(-1))[1]
  if (is.na(k)) stop("ccx_enso_efold_yr(): the ACF never falls below 1/e within 60 months.")
  # lag k-1 is the last one >= 1/e, lag k the first below; interpolate between.
  # At k == 1 the bracket is lag 0, where the ACF is 1 (2026-10-15, dormant bug 6: the branch read
  # k (r1 - 1/e) / (r1 - 1/e), which is 1 month whatever r1 is). The shipped record has k = 8.
  lag <- if (k == 1L) (1 - exp(-1)) / (1 - r[1]) else
    (k - 1) + (r[k - 1] - exp(-1)) / (r[k - 1] - r[k])
  lag / 12
}

#' Evaluate `expr` with the emissions interpolation's DEFAULT bound to `method`
#' (2026-10-01, the flip to "constant", review 10-01c B6).
#'
#' ⭐ FOR A HISTORICAL IDENTITY. An artifact produced before the flip -- a screen,
#' a session knock-out -- was produced under "spline", so its method is one of
#' its INPUTS: reproducing it exactly means re-supplying that input, not
#' re-pinning the artifact to today's numbers (which would turn an identity
#' with an external record into a pin on the code under test). Every caller
#' that builds a forcing without naming a method (the objective, the coupled
#' runs) sees the bound value; the binding is restored on exit, error or not.
#' The same idiom as test-enso-demean's FORC_ENSO_DEMEAN binding.
ccx_with_emis_method <- function(method, expr) {
  method <- match.arg(method, c("spline", "constant"))
  env <- environment(ccx_build_forcing)
  old <- get("CCX_EMIS_METHOD_DEFAULT", envir = env)
  assign("CCX_EMIS_METHOD_DEFAULT", method, envir = env)
  on.exit(assign("CCX_EMIS_METHOD_DEFAULT", old, envir = env), add = TRUE)
  force(expr)
}

# ---------------------------------------------------------------------
#' Assemble the full monthly forcing table
#'
#' @param scenario "historical", or a scenario key in CCX_SCENARIO_EMIS_FILES
#'   (the SSP names in data/ssp_emissions.rds, the van Vuuren keys vvVL..vvH in
#'   data/vv_emissions.rds)
#' @param years    integer range c(first, last)
#' @param prod_c14 cosmogenic 14C production (mol/yr) -- from ccx_spinup()
#' @param bomb_total_kmol total bomb 14C production, 1945-1980
#' @param emissions optional data.frame(year, fossil_GtC, luc_GtC) REPLACING the
#'   scenario's emissions entirely. This is how the app's stylised pathways
#'   ("linear to zero by 2060", "+2 %/yr") and its pulse experiments are built:
#'   the caller assembles the annual series and everything downstream --
#'   hemispheric split, monthly interpolation, annual-total conservation -- is
#'   applied identically to a custom path and to an SSP. `scenario` still names
#'   the run for labelling and still selects the non-CO2 climate background.
#'   ⚠ ITS `luc_GtC` IS MULTIPLIED BY `luc_scale` like any other land-use series
#'   (code review 2026-10-12 sec.5): a 100 GtC LAND-USE pulse placed in this column
#'   arrives as 100 x luc_scale (94.2 GtC at the canonical hilda31w; 91.4 at
#'   hilda29e). No caller does this -- the
#'   app's pulses are fossil -- so it is documented, not changed; divide a land-use
#'   perturbation by `luc_scale`, or put it in `fossil_GtC`, to keep its size.
#' @param sink_rate,sink_mode the artificial mid-century sink (2026-08-23c).
#'   ARGUMENTS, not just env constants, so a diagnostic can build all three arms
#'   in ONE process -- CCX_ARTIFICIAL_SINK_{RATE,MODE} are resolved when this
#'   file is sourced, so driving the arms by Sys.setenv would require re-sourcing
#'   and would silently test the OFF state if anyone forgot. The constants remain
#'   the defaults, so an env-driven refit is unchanged.
#'   NOTE the "luc" arm subtracts from the land-use series AFTER `luc_scale` has
#'   been applied to it, so the reduction is an absolute 2.5 GtC/yr in the
#'   MODEL's own flux and the three arms are magnitude-matched. That is why
#'   ccx_scaled_forcing() and ccx_make_logpost(), which apply `luc_scale` as a
#'   column MULTIPLY on an already-built base, refuse to run that arm: an affine
#'   column is not linear in `luc_scale` and the multiply would rescale the
#'   perturbation along with the flux.
#' @param luc_scale multiplier on the land-use emission series (added 2026-08-14).
#'   E_LUC is the least certain input in the table -- GCB 2025 states +/-0.7
#'   GtC/yr on it (LIK_GCB_LUC_SD), and GCB's own 1850-2018 total is 34 % above
#'   OSCAR v3.1's for the identical period (DATA.md sec.3a). Prescribing it exact
#'   forced that uncertainty onto `beta`, which absorbed ~30 ppm of it. This is
#'   the knob that lets it be a calibrated quantity instead; see
#'   CCX_PARAM_TABLE$luc_scale for the prior and its receipts.
#'   Applied to the ANNUAL series before interpolation, so the monthly flux, the
#'   in-window cumulative AND the pre-window `luc_pre` all scale together --
#'   which is what makes the equivalent post-hoc column rescale used inside
#'   ccx_make_logpost() exact (gated by test-luc-scale.R).
#' @param enso_index which ENSO index the `enso` column carries: "demean" (the
#'   shipped RULING A index, default), "detrend" or "relsst_lp" -- see
#'   CCX_ENSO_INDEX_CODES. Stamped as attr "enso_index". Callers running a
#'   parameter set should pass `ccx_enso_index_of(params)`.
#' @param aod_mode "legacy" (default) or "anomaly" -- see CCX_AOD_MODE_CODES.
#'   Stamped as attr "aod_mode"; pass `ccx_aod_mode_of(params)`.
#' @param emis_method "constant" (piecewise-constant within the year; the default,
#'   CCX_EMIS_METHOD_DEFAULT since 2026-10-01) or "spline" (the pre-flip natural
#'   spline) -- how annual emissions are interpolated to months; see
#'   CCX_EMIS_METHOD_DEFAULT in R/constants.R.
#' @param nuc_share "constant" (default: FORC_NUC_NH_SHARE every year) or "per_year"
#'   (the nuclear-industry 14C NH share year by year) -- see CCX_NUC_SHARE_CODES.
#'   Stamped as attr "nuc_share"; callers running a parameter set should pass
#'   `ccx_nuc_share_of(params)` (the canonical hilda31w runs "per_year").
#' @return data.frame, one row per month, with everything ccx_deriv() needs
ccx_build_forcing <- function(scenario = "historical",
                              years = c(1750, 2024),
                              prod_c14 = NA_real_,
                              bomb_total_kmol = 102,
                              emissions = NULL,
                              luc_scale = 1,
                              sink_rate = CCX_ARTIFICIAL_SINK_RATE,
                              sink_mode = CCX_ARTIFICIAL_SINK_MODE,
                              emis_method = CCX_EMIS_METHOD_DEFAULT,
                              enso_index = "demean",
                              aod_mode = "legacy",
                              nuc_share = "constant") {
  emis_method <- match.arg(emis_method, c("spline", "constant"))
  nuc_share   <- match.arg(nuc_share, names(CCX_NUC_SHARE_CODES))

  yrs <- seq(years[1], years[2])
  n   <- length(yrs) * 12
  t   <- rep(yrs, each = 12) + (seq_len(12) - 0.5) / 12
  ndep <- ccx_ndep_forcing(yrs, scenario)       # D2 (a), 2026-09-30

  # ---- emissions ----------------------------------------------------
  if (!is.null(emissions)) {
    e <- as.data.frame(emissions)
    need <- c("year", "fossil_GtC", "luc_GtC")
    if (!all(need %in% names(e)))
      stop("`emissions` needs columns: ", paste(need, collapse = ", "))
    src <- paste("caller-supplied emissions,", scenario)
  } else if (identical(scenario, "historical")) {
    e <- readRDS(ccx_path("data", "forcing_emissions_historical.rds"))
    e <- as.data.frame(e)
    src <- "GCB 2025 historical budget"
  } else {
    e <- ccx_scenario_emissions(scenario)
    src <- paste(attr(e, "source"), scenario)
  }
  # NA GUARD (2026-08-13). ccx_annual_to_monthly() strips NAs and then
  # approx(rule = 2) holds the nearest value flat across the gap. That is the
  # right behaviour for a short trailing gap and a SILENT FABRICATION for a long
  # leading one: GCB supplies no LUC before 1850, and the flat hold invented
  # 74.1 GtC across 1750-1849 -- 23 % of the model's land-use carbon -- with no
  # warning anywhere. The gap is now filled from a source at build time
  # (data-raw/build_calibration_data.R [5a]); this guard exists so the next
  # dataset with a hole cannot repeat it quietly.
  for (nm in c("fossil_GtC", "luc_GtC")) {
    gap <- e$year[is.na(e[[nm]]) & e$year >= min(yrs) & e$year <= max(yrs)]
    if (length(gap))
      warning(sprintf(paste0("%s is NA for %d year(s) in %d-%d (%d-%d); those years ",
                             "will be filled by HOLDING the nearest value flat. ",
                             "Supply a sourced series or set them to zero -- do not ",
                             "let approx(rule = 2) choose."),
                      nm, length(gap), min(yrs), max(yrs), min(gap), max(gap)),
              call. = FALSE)
  }
  # LAND-USE UNCERTAINTY, applied on the ANNUAL series (see @param luc_scale).
  # Deliberately here and not on the monthly columns: `luc_pre` below integrates
  # the annual series OUTSIDE the window, so scaling later would leave the
  # pre-window cumulative unscaled and the converted-land term would see a
  # cleared fraction inconsistent with the flux -- a silent partial application.
  if (!is.finite(luc_scale) || luc_scale < 0)
    stop("luc_scale must be a finite non-negative multiplier; got ", luc_scale)
  if (luc_scale != 1) e$luc_GtC <- e$luc_GtC * luc_scale

  # ⛔⛔ THE SPLINE IS A GLOBAL INTERPOLANT, SO A ONE-YEAR SPIKE RINGS BACKWARDS.
  # A 2050 pulse moved CO2 in 2049 and earlier -- 3.06 ppm over the 26 years
  # BEFORE it ([[ccx_pulse_spline_ringing]], found 2026-09-24 by asking whether a
  # paired experiment's arms agree BEFORE the perturbation; they did not).
  # The additive correction below fixes each year's MEAN exactly and does NOT
  # fix the AMPLITUDE, so the carbon is conserved while arriving at the wrong
  # time. `method = "constant"` is exactly conserving AND shape-preserving --
  # the same reason the bomb-14C series already uses it, where a spline
  # undershot either side of the 1962 peak.
  # ⚠ THE DEFAULT IS DELIBERATELY UNCHANGED. Flipping it here would re-baseline
  # every stored logpost against a FROZEN objective (#13); that is the
  # `emissions-interp-constant` branch's ledger to pay, and this parameter is
  # the same switch, so that branch becomes a DEFAULT change rather than a code
  # change. Callers that need causality -- the app's pulse lab -- opt in.
  # ⚠ SUPERSEDED 2026-10-01 (k) (noted 2026-10-12, code review): the default WAS
  # flipped that day -- CCX_EMIS_METHOD_DEFAULT is "constant" (R/constants.R),
  # restamped on every registered mode at its priced move, no refit -- so every
  # caller that names no method is now causal; the pulse lab no longer differs.
  # ⛔ PAST THE LAST YEAR OF DATA THE SERIES IS HELD FLAT (approx(rule = 2) inside
  # ccx_annual_to_monthly()), which used to happen with nothing said (code review 2026-10-12
  # sec.5). Every registered run stays inside its data (GCB to its last year, van Vuuren to
  # 2500); a run past the end now says so, as the GMST block below already did -- in the same
  # "held FLAT" words, so lib_design_gates.R's dg_run(), whose final year is held BY DESIGN,
  # muffles both with its one filter.
  for (nm in c("fossil_GtC", "luc_GtC")) {
    e_end <- max(e$year[is.finite(e[[nm]])])
    if (max(yrs) > e_end)
      warning(sprintf(paste0("%s (%s) ends %d; years %d-%d are held FLAT at the %d value. ",
                             "Supply the series to %d, or end the run at %d."),
                      nm, src, e_end, e_end + 1L, max(yrs), e_end, max(yrs), e_end),
              call. = FALSE)
  }
  foss <- ccx_annual_to_monthly(e$year, e$fossil_GtC, yrs, method = emis_method)
  luc  <- ccx_annual_to_monthly(e$year, e$luc_GtC,    yrs, method = emis_method)

  # ---- WITHIN-YEAR SEASONALITY (2026-08-15, review item 5c) ----------
  # Until now both emission inputs reached the model with NO seasonal cycle:
  # ccx_annual_to_monthly() interpolates the annual TREND smoothly and leaves
  # every month of a year within a whisker of its annual mean. Real fossil
  # emissions peak in NH January (heating) and real land-use fire peaks in the
  # dry season of whichever hemisphere is burning. The model's ONE free NEP
  # amplitude absorbed the difference -- seas_amp_NH was then the objective's
  # most sharply curved parameter, and it fit to 19.66 GtC/yr against a default
  # of 12. (That knob was RETIRED 2026-08-18, when the seasonal NEP sine gave way
  # to the insolation + Q10 drivers; seas_amp_NH survives only on the
  # seas_drivers = 0 escape-hatch path -- see CCX_SEAS_PHI_EFF in R/model.R.)
  #
  # Weights are hemispheric monthly climatologies from GFED4.1s (fire) and
  # EDGAR v4.3.2 (fossil); see data-raw/build_emission_seasonality.R for the
  # sources, the periods and the DEFO+PEAT choice.
  #
  # THE LAND-USE WEIGHT IS DAMPED BY f_fire, and that is the load-bearing
  # decision: only 21.6 % of GCB's E_LUC is fire (0.367 of 1.699 GtC/yr,
  # 2001-2016). The other 78 % is wood harvest, product decay and soil-carbon
  # loss, which have no comparable seasonal cycle. Applying the raw fire shape
  # to all of E_LUC would overstate the correction ~4.6x, in the direction that
  # would LOOK like a bigger fix. Fossil is not damped: all of it is combustion.
  # ---- HEMISPHERIC SPLIT OF E_LUC (2026-08-15, review item 5b) --------
  # The land-use share is TIME-VARYING and always has been; only the model's
  # representation of it was constant. Clearing moved from temperate NH forests
  # to the tropics over the industrial period, so OSCAR's regional E_LUC gives an
  # NH share falling 0.84 (1750s) -> 0.385 (2010s). Against the old constant 0.55
  # that is ~23 GtC of early land-use carbon emitted into the wrong hemisphere
  # and ~5 GtC of modern carbon into the wrong one the other way, and it is
  # exactly the kind of error the interhemispheric gradient sees.
  # One share per calendar year, held across that year -- see ccx_luc_nh_share().
  luc_sh_y <- ccx_luc_nh_share(yrs)
  luc_sh_m <- rep(luc_sh_y, each = 12)

  sea <- ccx_emission_seasonality()
  if (FORC_USE_EMIS_SEASONALITY && !is.null(sea)) {
    damp <- function(w) 1 + sea$f_fire * (w - 1)
    foss_NH <- ccx_seasonalise(foss * FORC_FOSS_NH_SHARE,       yrs, sea$weights$fossil_NH)
    foss_SH <- ccx_seasonalise(foss * (1 - FORC_FOSS_NH_SHARE), yrs, sea$weights$fossil_SH)
    luc_NH  <- ccx_seasonalise(luc  * luc_sh_m,                 yrs, damp(sea$weights$luc_NH))
    luc_SH  <- ccx_seasonalise(luc  * (1 - luc_sh_m),           yrs, damp(sea$weights$luc_SH))
  } else {
    foss_NH <- foss * FORC_FOSS_NH_SHARE
    foss_SH <- foss * (1 - FORC_FOSS_NH_SHARE)
    luc_NH  <- luc  * luc_sh_m
    luc_SH  <- luc  * (1 - luc_sh_m)
  }

  # ---- OPTIONAL ARTIFICIAL MID-CENTURY SINK (added 2026-08-23) --------
  # Marcus: "an artificial short-term ocean sink ... our fit to the modern
  # period should be best, and I am concerned that the model fit is being
  # tweaked to match the 1935-1960 window when we know that models don't
  # explain that period well."
  #
  # A LEVERAGE INSTRUMENT, NOT A FIT. It prescribes a FIXED removal over a
  # FIXED window at a magnitude taken from the literature and carries NO free
  # parameter, so the model cannot tune it. It exists to answer a
  # counterfactual a residual table cannot: if the plateau were explained,
  # where would the other 20 parameters go? The plateau window fits WELL
  # (mean |resid| 2.22 ppm against 3.14 elsewhere) and the whole point is that
  # it may fit well BECAUSE the parameters were bent to it.
  #
  # NOT the withdrawn sec.12c programme: that fitted a free E_LUC SHAPE to the
  # swing and would have reported it as a mechanism. This is prescribed,
  # unfitted, externally sized and labelled artificial.
  #
  # THE MODE SELECTS THE ISOTOPIC SIGNATURE, and that is the entire point --
  # see CCX_ARTIFICIAL_SINK_MODE at the top of this file for the three arms and
  # why the isotopes are the discriminator. The MAGNITUDE is identical across
  # arms by construction: one `sk` vector, three destinations.
  #
  # THE "foss" ARM'S LIMITATION, kept because it is the incumbent and its
  # numbers are already quoted: the carbon leaves the SYSTEM rather than
  # entering a box, so ocean inventory, excess-14C and the closed-system budget
  # are not right under it, and it carries the FOSSIL d13C where a real ocean
  # sink is near-neutral. That limitation is exactly what "ocean" removes.
  # 2026-08-23c CORRECTION to an earlier claim of mine: the "foss" arm does NOT
  # break conservation -- the cumulative budget gap is identical with and
  # without it (+260.95 GtC either way) because the carbon is simply never
  # emitted. It is a valid test of a real hypothesis, just not of the ocean one.
  #
  # OFF by default (rate 0) -- every existing result reproduces exactly, in
  # every mode.
  sink_ocean <- rep(0, n)
  if (!sink_mode %in% CCX_ARTIFICIAL_SINK_MODES)
    stop("sink_mode must be one of ",
         paste(CCX_ARTIFICIAL_SINK_MODES, collapse = ", "), "; got ", sink_mode)
  if (sink_rate != 0) {
    wy <- yrs >= CCX_ARTIFICIAL_SINK_WIN[1] & yrs <= CCX_ARTIFICIAL_SINK_WIN[2]
    sk <- rep(ifelse(wy, sink_rate, 0), each = 12)
    if (sink_mode == "foss") {
      foss_NH <- foss_NH - sk * FORC_FOSS_NH_SHARE
      foss_SH <- foss_SH - sk * (1 - FORC_FOSS_NH_SHARE)
    } else if (sink_mode == "luc") {
      # Split on the LUC share, not the fossil one: this arm's claim is that
      # the LAND-USE flux was overstated, so the reduction must be apportioned
      # the way land-use carbon is. `luc` is reduced too so that the cumulative
      # converted-land integral below follows -- clearing that did not happen
      # also did not shrink the land's equilibrium.
      luc_NH <- luc_NH - sk * luc_sh_m
      luc_SH <- luc_SH - sk * (1 - luc_sh_m)
      luc    <- luc    - sk
    } else {
      # "ocean": carried as its OWN forcing column and routed into the mixed
      # layer inside ccx_deriv(), which is where the air-sea fractionation and
      # the ocean-area split live. A GLOBAL rate: the hemispheric apportionment
      # is done there, on the same ocean-area shares the air-sea exchange uses
      # (aux$asx), because a sink whose split came from the fossil share would
      # be an ocean uptake in name only.
      sink_ocean <- sk
    }
  }

  # ---- CUMULATIVE land-use carbon (2026-08-13) -----------------------
  # Drives the converted-land term in ccx_deriv(): the land's equilibrium
  # carbon falls with the carbon land-use change has taken. See
  # calibration/diag_1900_deficit.R for why it exists.
  #
  # ACCUMULATED FROM THE START OF THE EMISSIONS RECORD, NOT FROM THE START OF
  # THE REQUESTED WINDOW. A run that begins in 1900 is a run on land that two
  # centuries of clearing have already shrunk; restarting the integral at the
  # window would hand it a pristine biosphere and quietly make every short-window
  # run a different model from the long one. The pre-window part is integrated
  # off the ANNUAL series directly, so it does not depend on the monthly grid.
  #
  # A caller-supplied `emissions` table that itself starts at the window start
  # cannot express pre-window clearing, and nothing here can invent it -- that
  # is a property of the input, and the idealised-pulse diagnostics rely on it
  # (they supply a zero-emission record and get a cleared fraction of zero).
  e_pre    <- e$year < min(yrs)
  luc_pre  <- if (any(e_pre)) sum(e$luc_GtC[e_pre], na.rm = TRUE) else 0
  cum_luc  <- luc_pre + cumsum(luc) / 12          # GtC/yr on a monthly grid
  # PER HEMISPHERE, integrating the SEASONALISED flux rather than splitting the
  # global cumulative. The two agree exactly at every year BOUNDARY (seasonality
  # conserves annual totals) but differ WITHIN a year, and the converted-land
  # term reads cum_luc every month -- so splitting the global series would hand
  # it a cleared fraction inconsistent with the flux it is paired with. Same
  # trap `luc_scale` had to avoid, one level down.
  #
  # THE PRE-WINDOW PART TAKES ITS OWN FLUX-WEIGHTED SHARE (2026-08-15, item 5b),
  # not the window's and not a constant. This is where a time-varying share bites
  # hardest: a run starting in 1900 has ~58 GtC of pre-window clearing that went
  # ~0.79 NH, while the same run's in-window flux averages ~0.49. Splitting the
  # pre-window carbon on either the constant 0.55 or on the window's own share
  # would misplace ~14 GtC of converted land. A weighted mean of a share weighted
  # by a flux that can be negative is undefined, so the denominator is guarded
  # and falls back to the unweighted mean of the same years.
  luc_pre_sh <- if (any(e_pre)) {
    w <- e$luc_GtC[e_pre]; w[!is.finite(w)] <- 0
    s <- ccx_luc_nh_share(e$year[e_pre])
    if (sum(w) > 0) sum(s * w) / sum(w) else mean(s)
  } else FORC_LUC_NH_SHARE
  cum_luc_NH <- luc_pre * luc_pre_sh       + cumsum(luc_NH) / 12
  cum_luc_SH <- luc_pre * (1 - luc_pre_sh) + cumsum(luc_SH) / 12

  # A WINDOW THAT STARTS MID-RECORD NO LONGER BEGINS AT A FIXED POINT, and it is
  # worth saying out loud. ccx_spinup() returns PREINDUSTRIAL land stocks with a
  # cleared fraction of zero; a run starting in 1900 hands those stocks a land
  # whose equilibrium has already shrunk by a century and a half of clearing, so
  # the land relaxes toward the smaller equilibrium and the run carries a
  # transient that is not in the emissions. That is honest -- the model is
  # saying you cannot start it mid-history from a pristine biosphere -- but
  # before 2026-08-13 it did not arise at all, so a caller reusing an old
  # windowed driver deserves to be told rather than to find a drift.
  if (luc_pre > FORC_LUC_PRE_WARN)
    warning(sprintf(paste0("window starts at %d with %.1f GtC of land-use carbon ",
                           "already emitted, so the land's equilibrium is %.1f %% ",
                           "below preindustrial at the first step while ccx_spinup() ",
                           "supplies preindustrial stocks. Expect a start-up ",
                           "transient. Start at the beginning of the emissions ",
                           "record, or spin up against the cleared land yourself."),
                    min(yrs), luc_pre, 100 * luc_pre / FORC_LAND0_NOMINAL),
            call. = FALSE)

  # ---- d13C of the fossil source, TIME-VARYING (2026-08-12) ----------
  # Built in data-raw/build_calibration_data.R [5b] from GCB's own by-fuel
  # split: -24.0 permil in 1850 (essentially pure coal) to -28.3 by 2024 as gas
  # displaced coal and cement (limestone, ~0 permil) entered the total. It
  # replaces a single -28 applied to the whole industrial period, which made the
  # modelled Suess decline ~30 % too steep -- see calibration/diag_d13c_suess.R.
  #
  # Only the historical table carries the column. SSPs and caller-supplied
  # pathways do not: the future fuel mix is a scenario property nobody has
  # supplied, so the last historical value is HELD FLAT, the same placeholder
  # convention the GMST column uses below. d13C is not scored past 2024, so this
  # affects reported d13C only, never the carbon budget.
  if (!is.null(e$d13c_foss)) {
    d13c_foss <- ccx_annual_to_monthly(e$year, e$d13c_foss, yrs, method = "constant")
  } else {
    h <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
    d13c_foss <- ccx_annual_to_monthly(h$year, h$d13c_foss, yrs, method = "constant")
  }

  # ---- temperature: IGCC, zero before its record starts --------------
  # AFTER the record ends this HOLDS THE LAST OBSERVED VALUE FLAT. That is a
  # placeholder, not a projection: an SSP5-8.5 run to 2100 built here sits at
  # the 2024 temperature throughout, silently, which suppresses the q10
  # respiration and ocean-solubility feedbacks entirely. Anything running past
  # the observational record must go through ccx_run_coupled() (R/climate.R),
  # which computes temperature from the model's own CO2 and overwrites this
  # column. The warning fires once per build so the placeholder cannot be used
  # by accident.
  g <- as.data.frame(readRDS(ccx_path("data", "forcing_gmst.rds")))
  gm <- ccx_annual_to_monthly(g$year, g$gmst_anom, yrs)
  yv <- rep(yrs, each = 12)          # integer year of each month
  gm[yv < min(g$year)] <- FORC_GMST_PRE1850
  if (max(yrs) > max(g$year))
    warning(sprintf(paste0("GMST observations end %d; years %d-%d are held FLAT ",
                           "at the last observed value. Use ccx_run_coupled() ",
                           "for an interactive climate."),
                    max(g$year), max(g$year) + 1L, max(yrs)), call. = FALSE)

  # ---- ENSO: Nino 3.4 anomaly, zero before 1948 ----------------------
  enso_index <- match.arg(enso_index, names(CCX_ENSO_INDEX_CODES))
  en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds")))
  en <- en[!is.na(en$nino34_anom), ]
  if (enso_index != "demean" && !FORC_ENSO_DEMEAN)
    stop("ccx_build_forcing: enso_index '", enso_index, "' is defined on top of RULING A; ",
         "FORC_ENSO_DEMEAN = FALSE is the pre-adoption reproduction path only.")
  if (enso_index == "relsst_lp") {
    # same ENSO-active span as the shipped index (see CCX_ENSO_INDEX_CODES)
    rs <- readRDS(ccx_path(FORC_ENSO_RELSST_FILE))
    rs <- rs[rs$year >= min(en$year), ]
    en <- data.frame(year = rs$year, month = rs$month, nino34_anom = rs$nino34_relsst_lp)
  }
  # RULING A -- see FORC_ENSO_DEMEAN above for what this is and what it is worth.
  if (FORC_ENSO_DEMEAN) {
    kb <- en$year >= FORC_ENSO_DEMEAN_WIN[1] & en$year <= FORC_ENSO_DEMEAN_WIN[2]
    if (sum(kb) < 12)
      stop(sprintf(paste0("ccx_build_forcing: the ENSO index covers %d months of ",
                          "the %d-%d demeaning window, too few to define a mean. ",
                          "The index record is %d-%d."),
                   sum(kb), FORC_ENSO_DEMEAN_WIN[1], FORC_ENSO_DEMEAN_WIN[2],
                   min(en$year), max(en$year)))
    en$nino34_anom <- en$nino34_anom - mean(en$nino34_anom[kb])
    if (enso_index == "detrend") {
      # A linear fit is only valid inside its window (lib_enso_index.R,
      # eix_detrend: extrapolated over 1854-1947 it fabricated +1.39 sd). The
      # index runs past the window's end by a few months, not decades; refuse
      # anything more.
      if (mean(!kb) > 0.05)
        stop(sprintf("ccx_build_forcing: %.0f%% of the ENSO index lies outside the %d-%d detrend window.",
                     100 * mean(!kb), FORC_ENSO_DEMEAN_WIN[1], FORC_ENSO_DEMEAN_WIN[2]))
      tt <- en$year + (en$month - 0.5) / 12
      b  <- stats::coef(stats::lm(en$nino34_anom[kb] ~ tt[kb]))
      en$nino34_anom <- en$nino34_anom - (b[[1]] + b[[2]] * tt)
    }
  }
  en_t <- en$year + (en$month - 0.5) / 12
  enso <- stats::approx(en_t, en$nino34_anom, xout = t, rule = 2)$y
  enso[yv < min(en$year)] <- FORC_ENSO_PRE1948
  # ⛔ TAPER, NOT A HOLD, past the record (FORC_ENSO_POST above). Exponential on
  # the index's own e-folding time from its last observed month; rule = 2 has
  # already placed that month's value on every later t, so the taper multiplies
  # it. Inside the record nothing changes.
  k_post <- t > max(en_t)
  if (any(k_post)) {
    tau <- ccx_enso_efold_yr(en$nino34_anom)
    enso[k_post] <- FORC_ENSO_POST +
      (enso[k_post] - FORC_ENSO_POST) * exp(-(t[k_post] - max(en_t)) / tau)
  }

  # ---- 14C sources ---------------------------------------------------
  nuc <- ccx_nuclear_c14_annual()
  c14_nuc <- if (nrow(nuc)) ccx_annual_to_monthly(nuc$year, nuc$mol_per_yr, yrs,
                                                 method = "constant") else rep(0, n)
  # Compare INTEGER years. Using decimal t here silently dropped the FINAL year
  # of every source record: month-centred t for year Y runs Y.04..Y.96, all of
  # which satisfy t > Y. That cost 0.28 % of the prescribed bomb total.
  if (nrow(nuc)) c14_nuc[yv < min(nuc$year) | yv > max(nuc$year)] <- 0

  # method="constant": the bomb series is sharply peaked and must stay
  # non-negative, and its underlying data are annual anyway. See the note in
  # ccx_annual_to_monthly() -- splining then clipping inflated the total 4.3 %.
  # The bomb source is now NATIVELY MONTHLY (data/forcing_bomb_c14.rds, built by
  # data-raw/build_bomb_c14_source.R from Tans 1981 Tables 1-2), so it is placed
  # on the axis by month rather than round-tripped through an annual series.
  # ccx_annual_to_monthly() is still the right tool for genuinely annual inputs.
  bomb <- ccx_bomb_c14_monthly(bomb_total_kmol)
  key  <- yv * 12L + rep(seq_len(12), length(yrs))
  c14_bomb <- rep(0, n)
  m <- match(key, bomb$year * 12L + bomb$month)
  c14_bomb[!is.na(m)] <- bomb$mol_per_yr[m[!is.na(m)]]

  out <- data.frame(
    t = t, year = rep(yrs, each = 12), month = rep(seq_len(12), length(yrs)),
    e_foss_NH = foss_NH,
    e_foss_SH = foss_SH,
    e_luc_NH  = luc_NH,
    e_luc_SH  = luc_SH,
    cum_luc_NH = cum_luc_NH,
    cum_luc_SH = cum_luc_SH,
    gmst = gm, enso = enso, d13c_foss = d13c_foss,
    c14_bomb = c14_bomb, c14_nuclear = c14_nuc,
    c14_cosmo = rep(prod_c14, n),   # NA here is filled from the spinup by the runners (ccx_fill_prod_c14, 09-16 d)
    # VOLCANIC stratospheric AOD, hemispheric (2026-08-29). ZERO outside the
    # series' coverage -- which means ZERO BEFORE 1850, so Laki 1783 and
    # TAMBORA 1815 are absent and any pre-1850 volcanic claim is unsupported.
    # See data-raw/build_volcanic_aod.R.
    aod_NH = ccx_aod_forcing(t, "aod_NH", aod_mode), aod_SH = ccx_aod_forcing(t, "aod_SH", aod_mode),
    # N DEPOSITION onto LAND, Tg N/yr above 1750 (D2 (a), 2026-09-30). ZEROS until
    # data/forcing_ndep.rds carries this scenario; harmless at ndep_ret 0 (the
    # default) and REFUSED by ccx_run_prepared() otherwise (ccx_ndep_check()).
    ndep_NH = ndep$NH, ndep_SH = ndep$SH,
    # the nuclear 14C NH share (2026-10-12): "constant" emits FORC_NUC_NH_SHARE itself -- the SAME
    # double the aux scalar holds, so both cores' arithmetic is unchanged -- because a BUILT forcing
    # carries no NA (test-forcing.R). NaN is only the absent value of a HAND-BUILT table.
    nuc_share_NH = if (nuc_share == "per_year") ccx_nuc_nh_share_monthly(yrs) else rep(FORC_NUC_NH_SHARE, n),
    # artificial mid-century OCEAN sink, GtC/yr, atmosphere -> mixed layer.
    # Identically zero unless CCX_SINK_RATE is set AND CCX_SINK_MODE == "ocean".
    sink_ocean = sink_ocean,
    stringsAsFactors = FALSE
  )
  # observed SST columns, derived from the gmst column just built (see
  # ccx_sst_anom_from_gmst for the seam rule and the ratio provenance)
  out <- ccx_sst_anom_from_gmst(out)
  # Stamped so a forcing carries its own provenance: the sink terms in
  # ccx_loglik() need the MODEL's land-use flux, not GCB's, and a run whose LUC
  # was scaled must not be scored against an unscaled one. Project convention --
  # emit the basis, do not make the caller remember it.
  attr(out, "luc_scale") <- luc_scale
  # Same reason again: which ENSO index this table carries (CCX_ENSO_INDEX_CODES).
  # ccx_enso_index_check() reads it against the parameters at run time.
  attr(out, "enso_index") <- enso_index
  attr(out, "aod_mode")   <- aod_mode
  attr(out, "nuc_share")  <- nuc_share
  # which N-deposition series the ndep columns carry ("none" = zeros)
  attr(out, "ndep_source") <- ndep$source
  # Same reason as luc_scale: a forcing built under an arm of the artificial
  # sink is a DIFFERENT INPUT and a table comparing arms must be able to say
  # which it holds rather than infer it from a filename.
  attr(out, "sink") <- if (sink_rate == 0) "off"
    else sprintf("%s %.4g GtC/yr %d-%d", sink_mode, sink_rate,
                 CCX_ARTIFICIAL_SINK_WIN[1], CCX_ARTIFICIAL_SINK_WIN[2])
  # Same reason, for the hemispheric split: a forcing built under the sourced
  # time-varying share and one built under the constant are different inputs, and
  # a diagnostic comparing them must be able to say which it has rather than
  # infer it from the date on the file.
  attr(out, "luc_nh_share") <- if (FORC_USE_LUC_NH_SHARE_TS &&
                                   !is.null(ccx_luc_nh_share_product()))
    sprintf("OSCAR time-varying (%.3f-%.3f over %d-%d)",
            min(luc_sh_y), max(luc_sh_y), min(yrs), max(yrs))
  else sprintf("constant %.2f", FORC_LUC_NH_SHARE)
  out
}

#' The model's own annual land-use emission, as ccx_loglik() wants it
#'
#' The gross-sink reconstruction needs E_LUC as the MODEL burned it, which is
#' `luc_scale` times GCB's. Derived from the forcing rather than re-read from
#' GCB, so a scaled run cannot be scored against an unscaled flux.
#' @param forc a forcing from ccx_build_forcing() (or one column-rescaled from it)
#' @return data.frame(year, eluc) in GtC/yr
ccx_forcing_eluc_annual <- function(forc) {
  tot <- forc$e_luc_NH + forc$e_luc_SH
  stats::aggregate(list(eluc = tot), by = list(year = forc$year), FUN = mean)
}

#' Resolve the fossil-source d13C of a forcing, including hand-built ones
#'
#' ccx_build_forcing() always supplies `d13c_foss`, but several callers assemble
#' a forcing list literally -- ccx_spinup()'s zero forcing and the conservation
#' tests' closed system -- and those carry no emissions at all, so the value
#' would multiply a zero flux.
#'
#' Rather than default silently (which would let a REAL run missing the column
#' pick a number nobody chose), this returns 0 only when there is genuinely no
#' fossil flux to label, and errors otherwise.
ccx_forcing_d13c_foss <- function(forc) {
  if (!is.null(forc$d13c_foss)) return(forc$d13c_foss)
  if (any(unlist(forc$e_foss) != 0))
    stop("forcing carries fossil emissions but no `d13c_foss`; ",
         "build it with ccx_build_forcing()")
  0
}

#' Resolve the cumulative land-use carbon of a forcing, including hand-built ones
#'
#' Same contract, and the same reason, as ccx_forcing_d13c_foss() above: the
#' spinup's zero forcing and the conservation tests' closed system are assembled
#' literally and carry no emissions, so there is genuinely nothing to accumulate.
#'
#' A forcing that DOES carry land-use emissions and no `cum_luc` is a different
#' matter and errors. Defaulting it to zero there would silently restore the
#' pre-2026-08-13 model -- land-use carbon with an airborne fraction of 0.002 at
#' 100 years -- through a code path nobody chose, which is precisely the failure
#' this project keeps finding.
ccx_forcing_cum_luc <- function(forc) {
  if (!is.null(forc$cum_luc)) return(forc$cum_luc)
  if (any(unlist(forc$e_luc) != 0))
    stop("forcing carries land-use emissions but no `cum_luc`; ",
         "build it with ccx_build_forcing()")
  list(NH = 0, SH = 0)
}

#' Hemispheric stratospheric AOD on the model's monthly axis
#'
#' ZERO outside the source series' coverage. The series is CMIP7 (NASA GISS
#' tau_reff_CMIP7-2-2-1.nc) and starts in 1850, so ⚠ **every eruption before
#' 1850 is missing** -- Laki 1783, the 1808/09 unknown and TAMBORA 1815 -- and
#' a run that starts in 1750 sees a volcanically silent first century. Filling
#' that needs eVolv2k. See data-raw/build_volcanic_aod.R.
ccx_aod_at <- local({
  .cache <- NULL
  function(t, col = c("aod_NH", "aod_SH", "aod_global")) {
    col <- match.arg(col)
    f <- ccx_path("data", "forcing_volcanic_aod.rds")
    if (is.null(.cache)) {
      if (!file.exists(f)) return(rep(0, length(t)))   # absence = quiet stratosphere
      .cache <<- readRDS(f)
    }
    v <- stats::approx(.cache$t, .cache[[col]], xout = t, rule = 1)$y
    v[!is.finite(v)] <- 0                            # outside coverage = quiet
    v
  }
})

#' The AOD series' own decay time, in years: from the largest peak in the
#' record, the time until the global anomaly (over the quiet background) first
#' falls below 1/e of its peak. DERIVED FROM THE DATA, never typed
#' ([[threshold_from_obs_or_law]]); the ENSO taper's precedent.
ccx_aod_efold_yr <- function() {
  a  <- readRDS(ccx_path("data", "forcing_volcanic_aod.rds"))
  bg <- mean(a$aod_global[a$t >= FORC_AOD_BG_WIN[1] & a$t < FORC_AOD_BG_WIN[2] + 1])
  an <- a$aod_global - bg
  k  <- which.max(an)
  j  <- which(seq_along(an) > k & an < an[k] / exp(1))[1]
  if (is.na(j)) stop("ccx_aod_efold_yr(): the anomaly never decays below 1/e of its peak")
  a$t[j] - a$t[k]
}
#' The AOD column a forcing carries, under `aod_mode` (CCX_AOD_MODE_CODES)
ccx_aod_forcing <- function(t, col, aod_mode = "legacy") {
  aod_mode <- match.arg(aod_mode, names(CCX_AOD_MODE_CODES))
  v <- ccx_aod_at(t, col)
  if (aod_mode == "legacy") return(v)
  a  <- readRDS(ccx_path("data", "forcing_volcanic_aod.rds"))
  bg <- mean(a[[col]][a$t >= FORC_AOD_BG_WIN[1] & a$t < FORC_AOD_BG_WIN[2] + 1])
  inside <- t >= min(a$t) & t <= max(a$t)
  v[inside] <- v[inside] - bg
  v[t < min(a$t)] <- 0
  post <- t > max(a$t)
  if (any(post))
    v[post] <- (a[[col]][which.max(a$t)] - bg) * exp(-(t[post] - max(a$t)) / ccx_aod_efold_yr())
  v
}
# ---- N DEPOSITION (D2 (a), Marcus 2026-09-30) ------------------------------
# data/forcing_ndep.rds, built by data-raw/build_ndep_forcing.R: one ANNUAL series
# per scenario, columns scenario / year / ndep_NH / ndep_SH, in Tg N/yr of
# ANTHROPOGENIC deposition onto each hemisphere's LAND above 1750.
CCX_NDEP_FILE <- "forcing_ndep.rds"

#' The N-deposition columns of a forcing: list(NH, SH, source), monthly on `years`
#'
#' ABSENT FILE or ABSENT SCENARIO = ZEROS stamped source "none". That is harmless
#' while ndep_ret is 0, the default, and ccx_ndep_check() REFUSES it otherwise,
#' so a nonzero retention can never run silently on no deposition.
#' PIECEWISE CONSTANT within each year (ccx_annual_to_monthly "constant"): the
#' annual means are exact and the series cannot undershoot below zero near 1750,
#' where a spline through a series starting at 0 would.
ccx_ndep_forcing <- function(years, scenario) {
  n <- 12L * length(years)
  none <- list(NH = rep(0, n), SH = rep(0, n), source = "none")
  f <- ccx_path("data", CCX_NDEP_FILE)
  if (!file.exists(f)) return(none)
  d0 <- readRDS(f)
  d <- as.data.frame(d0)[d0$scenario == scenario, ]
  if (!nrow(d)) return(none)
  # PARTIAL COVERAGE (e.g. a "historical" table built past the last GCB year) is
  # ZEROS stamped "none (...)": harmless at ndep_ret 0, REFUSED otherwise. A
  # stop() here would break every retention-0 caller for a series it never reads.
  if (min(d$year) > min(years) || max(d$year) < max(years)) {
    none$source <- sprintf("none (%s covers %d-%d, the table needs %d-%d)", scenario,
                           min(d$year), max(d$year), min(years), max(years))
    return(none)
  }
  src <- attr(d0, "source"); if (is.null(src)) src <- CCX_NDEP_FILE
  list(NH = ccx_annual_to_monthly(d$year, d$ndep_NH, years, "constant"),
       SH = ccx_annual_to_monthly(d$year, d$ndep_SH, years, "constant"),
       source = paste0(src, " [", scenario, "]"))
}

#' Refuse a nonzero ndep_ret on a forcing that carries no deposition series
ccx_ndep_check <- function(ndep_ret, F) {
  src <- attr(F, "ndep_source")
  if (isTRUE(ndep_ret != 0) && (is.null(src) || grepl("^none", src)))
    stop("ndep_ret = ", ndep_ret, " but the forcing carries NO N-deposition series ",
         "(ndep_source ", if (is.null(src)) "absent" else paste0("'", src, "'"), "). Build ",
         "data/forcing_ndep.rds for this scenario (data-raw/build_ndep_forcing.R).")
  invisible(TRUE)
}

#' Which AOD mode a parameter list names (absent = "legacy")
ccx_aod_mode_of <- function(p) {
  v <- p$aod_mode
  if (is.null(v)) return("legacy")
  nm <- names(CCX_AOD_MODE_CODES)[match(as.integer(v), CCX_AOD_MODE_CODES)]
  if (length(nm) != 1 || is.na(nm))
    stop("ccx_aod_mode_of(): aod_mode = ", paste(v, collapse = ","),
         " is not one of ", paste(CCX_AOD_MODE_CODES, collapse = "/"))
  nm
}
#' Refuse a params/forcing AOD-mode mismatch; same contract as
#' ccx_enso_index_check() (unstamped = legacy; "none" = an AOD-free table).
ccx_aod_mode_check <- function(p, F) {
  want <- if (is.character(p)) p else ccx_aod_mode_of(p)
  have <- attr(F, "aod_mode")
  if (identical(have, "none")) return(invisible(TRUE))
  if (is.null(have) && want == "legacy") return(invisible(TRUE))
  if (!identical(have, want))
    stop("AOD mode mismatch: the parameters name '", want, "' but the forcing carries '",
         if (is.null(have)) "<unstamped>" else have,
         "'. Build it with ccx_build_forcing(aod_mode = ccx_aod_mode_of(params)).")
  invisible(TRUE)
}

ccx_nuc_share_of <- function(p) {
  v <- p[["nuc_share_ts"]]
  if (is.null(v)) return("constant")
  nm <- names(CCX_NUC_SHARE_CODES)[match(as.integer(v), CCX_NUC_SHARE_CODES)]
  if (length(nm) != 1 || is.na(nm))
    stop("ccx_nuc_share_of(): nuc_share_ts = ", paste(v, collapse = ","),
         " is not one of ", paste(CCX_NUC_SHARE_CODES, collapse = "/"))
  nm
}
#' Refuse a params/forcing nuclear-share mismatch; same contract as ccx_aod_mode_check()
#' (an unstamped table is "constant"). A table stamped "none" carries no nuclear source.
ccx_nuc_share_check <- function(p, F) {
  want <- if (is.character(p)) p else ccx_nuc_share_of(p)
  have <- attr(F, "nuc_share")
  if (identical(have, "none")) return(invisible(TRUE))
  if (is.null(have) && want == "constant") return(invisible(TRUE))
  if (!identical(have, want))
    stop("nuclear 14C share mismatch: the parameters name '", want, "' but the forcing carries '",
         if (is.null(have)) "<unstamped>" else have,
         "'. Build it with ccx_build_forcing(nuc_share = ccx_nuc_share_of(params)).")
  invisible(TRUE)
}
#' The per-year nuclear 14C NH share on a monthly axis (12 rows per year of `yrs`). Cached.
ccx_nuc_nh_share_monthly <- local({
  cache <- NULL
  function(yrs) {
    if (is.null(cache)) cache <<- readRDS(ccx_path("data", "forcing_nuc_nh_share.rds"))
    d <- cache
    yy <- pmin(pmax(yrs, min(d$year)), max(d$year))     # HOLD the nearest year outside the files
    rep(d$nh_share_filled[match(yy, d$year)], each = 12)
  }
})

#' Extract one month's forcing in the shape ccx_deriv() expects
ccx_forcing_at <- function(F, i) {
  list(e_foss = list(NH = F$e_foss_NH[i], SH = F$e_foss_SH[i]),
       e_luc  = list(NH = F$e_luc_NH[i],  SH = F$e_luc_SH[i]),
       cum_luc = list(NH = F$cum_luc_NH[i], SH = F$cum_luc_SH[i]),
       gmst = F$gmst[i], enso = F$enso[i], d13c_foss = F$d13c_foss[i],
       c14_bomb = F$c14_bomb[i], c14_nuclear = F$c14_nuclear[i],
       c14_cosmo = F$c14_cosmo[i],
       # the nuclear NH share (2026-10-12): NULL on an older table, NaN under "constant";
       # ccx_deriv() reads both as the aux scalar
       nuc_share_NH = F$nuc_share_NH[i],
       # observed-SST columns (2026-08-18). NULL when the forcing predates them
       # -- the deriv's fallback handles that; omitting them HERE while the C++
       # matrix carried them broke R<->C++ parity at 9e-4 before this line.
       sst_anom_NH = F$sst_anom_NH[i], sst_anom_SH = F$sst_anom_SH[i],
       # artificial ocean sink (2026-08-23c). NULL on a forcing that predates
       # the column or on a hand-built one; ccx_deriv() reads that as zero,
       # which is the same absence contract the sst columns carry.
       sink_ocean = F$sink_ocean[i],
       # volcanic AOD (2026-08-29); NULL on a forcing that predates the columns,
       # which ccx_deriv() reads as zero -- the same absence contract as above.
       aod_NH = F$aod_NH[i], aod_SH = F$aod_SH[i],
       # N deposition (D2 (a), 2026-09-30); NULL on an older table = zero.
       ndep_NH = F$ndep_NH[i], ndep_SH = F$ndep_SH[i],
       # the LAND term's lagged ENSO input (W1, 2026-10-02). A RUNNER writes the column
       # (ccx_land_enso()); a table without it gives NULL, which ccx_deriv() reads as the
       # index itself when nothing is lagged and REFUSES when something is.
       land_enso = F[["land_enso"]][i],
       # the stratification feedback's factor g (DESIGN §3.4a S, 2026-10-04). A RUNNER writes
       # the column (ccx_mix_g_series()); NULL is read as g = 1 when the feedback is off, and
       # refused by ccx_point_mix_g() when it is on (except at GMST <= 0 from a spinup).
       mix_g = F[["mix_g"]][i])
}

# ---------------------------------------------------------------------
#' Fill an unset cosmogenic-14C production from the spinup that seeds the run
#'
#' `ccx_build_forcing()` defaults `prod_c14` to NA (the production is a property
#' of the SPINUP, which balances it against decay), and until 2026-09-16 (d) a
#' bare `ccx_run(spin, ccx_build_forcing())` returned valid CO2 / d13C and an
#' ALL-NA Delta14C with nothing said (review finding 6). Every calibration path
#' sets `F$c14_cosmo <- sp$prod_c14` by hand; this does the same thing for the
#' bare call, and only when the column is entirely NA -- a partly-set column
#' is the caller's and is left alone. Both runners call it.
ccx_fill_prod_c14 <- function(F, spin) {
  if (!is.null(F$c14_cosmo) && all(is.na(F$c14_cosmo)) &&
      is.numeric(spin$prod_c14) && length(spin$prod_c14) == 1L && is.finite(spin$prod_c14))
    F$c14_cosmo <- rep(spin$prod_c14, nrow(F))
  F
}

#' Run the model forward over an assembled forcing table
#'
#' (This block sat ABOVE ccx_fill_prod_c14()'s, fused onto it, until 2026-10-12 --
#' pre-beta code review sec.4.)
#'
#' @param substeps RK4 substeps per month, or "auto" to pick the smallest count
#'   that keeps the explicit diffusion term stable (see ccx_substeps_for()).
#'   Without the seasonal mixed layer "auto" resolves to CCX_SUBSTEPS_MIN = 4
#'   at every ordinary parameter value. ⚠ Under the seasonal mixed layer it
#'   depends on h_ml: 6 at the canonical hilda31w (h_ml 69.54); with hilda31w's
#'   other values 4 / 5 / 10 / 15 at h_ml 64.63 / 68 / 72 / 73 (4 at the
#'   then-canonical hilda29e, code review 2026-10-12) -- see the stability
#'   section of R/model.R. This R path has no NA-retry.
#' @param flux_method "snapshot" (default) or "rk4"; see the comment in the body.
#' @return list(state = final state, out = data.frame of monthly diagnostics)
ccx_run <- function(spin, F, substeps = "auto", fluxes = FALSE, edge_fn = NULL,
                    flux_method = c("snapshot", "rk4")) {
  # `flux_method` (2026-10-12): "snapshot" (the default, unchanged) evaluates the trace at each
  # month's opening state, the instant the NPP record reads; "rk4" weights every RK4 stage as the
  # integrator does, so a month's fluxes integrate to its state change (R/fluxes.R).
  flux_method <- match.arg(flux_method)
  F <- ccx_fill_prod_c14(F, spin)
  # `edge_fn(fl, y, t)` (2026-09-15b): an OPT-IN per-month hook on the
  # derivative's recorded attribute at the month's OPENING state -- the same
  # (y, t, forcing) the first RK4 stage evaluates. The caller keeps what it
  # wants (a pathway sum, a state slice); the core stores nothing new by
  # default. Diagnostic only; `out` and `state` are untouched by it.
  y <- spin$y; aux <- spin$aux; grid <- spin$grid; p <- spin$params
  # THE FOUR FORCING GUARDS (2026-10-14 o, Marcus: "Land them, with a test"): the forcing's
  # ENSO index, AOD mode, nuclear 14C share and N deposition must be the ones the parameters
  # name, derived exactly as ccx_run_prepare() derives them for ccx_run_prepared(). Until then
  # this core checked none, so a default-built forcing under the canonical's params ran on the
  # DEFAULT variants with no error (CHANGELOG 2026-10-14 n). Gate: test-run-r-guards.R.
  ccx_enso_index_check(p, F); ccx_aod_mode_check(p, F); ccx_nuc_share_check(p, F)
  ccx_ndep_check(if (is.null(p$ndep_ret)) CCX_NDEP_RET_DEFAULT else p$ndep_ret, F)
  substeps <- ccx_resolve_substeps(substeps, p, grid)
  n <- nrow(F)
  # THE LAND ENSO INPUT (W1, 2026-10-02): the index read lag_enso_land months late,
  # from the SAME builder ccx_run_prepared() hands the C++ core. ALWAYS rewritten
  # here, so a column a caller left on the table can never be a stale lag. The flux
  # trace below reads it through ccx_forcing_at() off this same local table.
  if (!is.null(F$enso))
    F$land_enso <- ccx_land_enso(F$enso, ccx_enso_lag_of(p), spin$enso_hist)
  # THE STRATIFICATION FEEDBACK's g (DESIGN §3.4a S, 2026-10-04): the SAME builder
  # ccx_run_prepared() uses, ALWAYS rewritten (a stale column is dropped when it is off).
  F[["mix_g"]] <- if (ccx_mix_on(p)) as.numeric(ccx_mix_g_series(F$gmst, F$t, p, spin$tdeep0)) else NULL
  atmN <- aux$idx$NH$atm; atmS <- aux$idx$SH$atm
  # HS and HD ARE ocean carbon (as spinup.R and the C++ core count them);
  # `$hs`/`$hd` are NULL with the structure off and c() drops them. Audit
  # 2026-09-06d: this line excluded them, so the R path's ocean_C / ocean_C14
  # disagreed with ccx_run_fast() by the HS+HD excess whenever hs_frac > 0.
  ocean <- unlist(lapply(HEMIS, function(h)
    c(aux$idx[[h]]$ml, aux$idx[[h]]$oc, aux$idx[[h]]$hs, aux$idx[[h]]$hd, aux$idx[[h]]$eq,
      aux$idx[[h]]$tr)))          # + the tropical box (2026-09-14f; the C++ sums IML..NPH)
  land  <- unlist(lapply(HEMIS, function(h) aux$idx[[h]]$land))

  atm   <- c(atmN, atmS)
  # 14C reservoir inventories, in STATE units ("GtC carrying standard 14C
  # content"). Carried alongside the carbon stocks because the ocean excess-14C
  # constraint (likelihood.R) is an INVENTORY at two reference years, which
  # cannot be reconstructed from the atmospheric D14C series. Converted to kmol
  # by the likelihood, not here -- the model core does not own that convention.
  out <- data.frame(t = F$t, co2_NH = NA_real_, co2_SH = NA_real_,
                    d13c_NH = NA_real_, d13c_SH = NA_real_,
                    d14c_NH = NA_real_, d14c_SH = NA_real_,
                    ocean_C = NA_real_, land_C = NA_real_,
                    ocean_C14 = NA_real_, land_C14 = NA_real_,
                    atm_C14 = NA_real_)
  # Mixed-layer and bottom-box C and 13C per hemisphere, in STATE units, for the
  # ocean DIC / d13C gradient terms. See the note in src/ccx_core.cpp: raw, not
  # umol/kg, and a TIME SERIES because those terms are scored at the
  # observations' epoch rather than at the run's end.
  for (cc in CCX_OCEAN_BOX_COLS) out[[cc]] <- NA_real_
  obox <- lapply(HEMIS, function(h)
    c(ml = aux$idx[[h]]$ml, deep = utils::tail(aux$idx[[h]]$oc, 1),
      hs = if (isTRUE(aux$hs_on == 1L)) aux$idx[[h]]$hs else NA_integer_,
      eq = if (isTRUE(aux$eq_on == 1L)) aux$idx[[h]]$eq else NA_integer_,
      tr = if (isTRUE(aux$tr_on == 1L)) aux$idx[[h]]$tr else NA_integer_))
  names(obox) <- HEMIS
  gpp <- ccx_const("GtC_PER_PPM") / 2
  # Flux trace (R/fluxes.R): OPT-IN, and never on a likelihood path. "snapshot" evaluates it at
  # each month's OPENING state; "rk4" (2026-10-12) takes the RK4-WEIGHTED MEAN over every stage the
  # integrator evaluated (ccx_step_rk4_traced()), so a month's fluxes integrate to its state change.
  # The snapshot aliases the seasonal mixed layer's entrainment (CHANGELOG 2026-10-12 (t)).
  nppm <- matrix(NA_real_, n, length(HEMIS), dimnames = list(NULL, paste0("npp_", HEMIS)))
  rk4_trace <- fluxes && flux_method == "rk4"
  ystore <- if (fluxes && !rk4_trace) vector("list", n) else NULL
  vmat <- NULL
  etrace <- if (!is.null(edge_fn)) vector("list", n) else NULL
  for (i in seq_len(n)) {
    if (!is.null(ystore)) ystore[[i]] <- y
    # ⚠ INSTANTS, NOT MONTHLY MEANS (documented 2026-10-12, code review). Each row is
    # the state at the instant F$t[i] (the month-centre label), before this month's
    # step. The station observations the likelihood compares these with are monthly
    # MEANS; see the note above .ccx_month_design in R/likelihood.R for what that
    # does to the seasonal rows (first harmonic x sinc(pi/12) = 0.98862).
    out$co2_NH[i]  <- y[atmN, "C"] / gpp
    out$co2_SH[i]  <- y[atmS, "C"] / gpp
    out$d13c_NH[i] <- 1000 * (y[atmN, "C13"] / (y[atmN, "C"] * ccx_const("R13_VPDB")) - 1)
    out$d13c_SH[i] <- 1000 * (y[atmS, "C13"] / (y[atmS, "C"] * ccx_const("R13_VPDB")) - 1)
    out$d14c_NH[i] <- 1000 * (y[atmN, "C14"] / y[atmN, "C"] - 1)
    out$d14c_SH[i] <- 1000 * (y[atmS, "C14"] / y[atmS, "C"] - 1)
    out$ocean_C[i] <- sum(y[ocean, "C"])
    out$land_C[i]  <- sum(y[land, "C"])
    out$ocean_C14[i] <- sum(y[ocean, "C14"])
    out$land_C14[i]  <- sum(y[land,  "C14"])
    out$atm_C14[i]   <- sum(y[atm,   "C14"])
    for (h in HEMIS) {
      out[[paste0("ml_C_",   h)]][i] <- y[obox[[h]]["ml"],   "C"]
      out[[paste0("ml_C13_", h)]][i] <- y[obox[[h]]["ml"],   "C13"]
      out[[paste0("deep_C_",   h)]][i] <- y[obox[[h]]["deep"], "C"]
      out[[paste0("deep_C13_", h)]][i] <- y[obox[[h]]["deep"], "C13"]
      if (!is.na(obox[[h]]["hs"])) {              # the HS box exists only with the structure on
        out[[paste0("hs_C_",   h)]][i] <- y[obox[[h]]["hs"], "C"]
        out[[paste0("hs_C13_", h)]][i] <- y[obox[[h]]["hs"], "C13"]
      }
      if (!is.na(obox[[h]]["eq"])) {              # the equatorial cell (2026-09-13g), likewise
        out[[paste0("eq_C_",   h)]][i] <- y[obox[[h]]["eq"], "C"]
        out[[paste0("eq_C13_", h)]][i] <- y[obox[[h]]["eq"], "C13"]
      }
      if (!is.na(obox[[h]]["tr"])) {              # the tropical box (2026-09-14f), likewise
        out[[paste0("tr_C_",   h)]][i] <- y[obox[[h]]["tr"], "C"]
        out[[paste0("tr_C13_", h)]][i] <- y[obox[[h]]["tr"], "C13"]
      }
    }
    # THE SURFACE pCO2 COLUMNS (2026-09-13g) come from the DERIVATIVE'S OWN
    # record at this month's opening state -- the same (y, t, forcing) the
    # first RK4 stage evaluates -- so the R path carries no second estimator
    # of the air-sea driving quantity. That first stage is then handed to
    # ccx_step_rk4() rather than recomputed; the recorded attribute is
    # stripped first so it cannot ride along on the state.
    fi <- ccx_forcing_at(F, i)
    k1 <- ccx_deriv(y, F$t[i], p, fi, grid, aux, record = TRUE)
    .fl <- attr(k1, "fluxes"); attr(k1, "fluxes") <- NULL
    if (!is.null(edge_fn)) etrace[[i]] <- edge_fn(.fl, y, F$t[i])
    for (h in HEMIS) {
      out[[paste0("ml_pco2_", h)]][i] <- .fl$pco2_ml[[h]]
      out[[paste0("hs_pco2_", h)]][i] <- .fl$pco2_hs[[h]]
      out[[paste0("eq_pco2_", h)]][i] <- .fl$pco2_eq[[h]]
      out[[paste0("tr_pco2_", h)]][i] <- .fl$pco2_tr[[h]]
      nppm[i, paste0("npp_", h)] <- .fl$npp[[h]]
    }
    if (rk4_trace) {
      st <- ccx_step_rk4_traced(y, F$t[i], 1 / 12, p, fi, grid, aux, substeps,
                                k1 = k1, v1 = ccx_flux_stage_vec(.fl, y, aux))
      y <- st$y
      if (is.null(vmat)) vmat <- matrix(NA_real_, n, length(st$v), dimnames = list(NULL, names(st$v)))
      vmat[i, ] <- st$v
    } else {
      y <- ccx_step_rk4(y, F$t[i], 1 / 12, p, fi, grid, aux, substeps, k1 = k1)
    }
  }
  # NPP per hemisphere, GtC/yr, at each month's opening state (twin of the C++
  # `npp` matrix; test-npp-record.R holds the two together).
  res <- list(state = y, out = out, npp = data.frame(t = F$t, nppm))
  if (fluxes) {
    res$fluxes <- if (rk4_trace) ccx_flux_trace_rk4(vmat, F$t[seq_len(n)], aux) else
      ccx_flux_trace(ystore, F, p, grid, aux)
  }
  if (!is.null(edge_fn)) res$edge_trace <- etrace
  res
}


#' (Re)derive the sst_anom_{NH,SH} columns from the CURRENT gmst column.
#'
#' Called by ccx_build_forcing() after the gmst column is final, and by
#' ccx_run_coupled() after EVERY gmst update -- the sst columns must follow
#' whatever gmst is current, or the coupled runner's future would silently
#' keep build-time SST. Obs years take HadSST4 directly; beyond them the
#' incremental rule above applies, seam-matched over CCX_SST_SPLICE_YR years.
ccx_sst_anom_from_gmst <- function(F) {
  so <- as.data.frame(readRDS(ccx_path("data", "forcing_sst.rds")))
  last <- max(so$year)
  for (h in c("NH", "SH")) {
    ratio <- if (h == "NH") CCX_SST_RATIO_NH else CCX_SST_RATIO_SH
    ocol  <- so[[paste0("sst_anom_", h)]]
    v <- stats::approx(so$year + 0.5, ocol, xout = F$t, rule = 2)$y
    # BEFORE THE RECORD (2026-09-16 d, review finding 5): `rule = 2` held the
    # SINGLE YEAR 1850 (-0.042 / -0.044 K) back to 1750 -- the single-year
    # baseline the standing rule forbids -- while GMST is 0 pre-1850
    # (FORC_GMST_PRE1850) and the periodic spinup runs at 0: every surface box
    # started the transient 0.04 K colder than its spun-up orbit, a ~0.5 uatm,
    # ~0.05 ppm step at 1850. The product is re-based to 1850-1900, so its
    # 1850-1900 mean IS the pre-record value (~0), consistent with GMST.
    before <- F$year < min(so$year)
    if (FORC_SST_PRE1850_MEAN && any(before)) v[before] <- mean(ocol[so$year <= min(so$year) + 50])
    beyond <- F$year > last
    if (any(beyond)) {
      # ⛔ ONE WINDOW FOR BOTH MEANS, AND A REFUSAL WHEN THERE IS NONE (code review 2026-10-12
      # sec.5). The obs mean ran over the whole seam window while the GMST mean ran over the
      # window's years the FORCING covers: a run starting inside the window matched means over
      # DIFFERENT years, and one starting after it took mean(empty) = NaN -- NaN SST, which the
      # core silently replaced with sst_scale x gmst. Both means now run over the covered years,
      # which is the whole window (and the identical arithmetic) for every run that starts by then.
      cov <- intersect(so$year[so$year > last - CCX_SST_SPLICE_YR], unique(F$year))
      if (!length(cov))
        stop(sprintf(paste0("ccx_sst_anom_from_gmst(): the forcing (%d-%d) covers none of the SST ",
                            "seam window %d-%d, so the post-%d SST cannot be matched to the record. ",
                            "Start the run by %d."),
                     min(F$year), max(F$year), last - CCX_SST_SPLICE_YR + 1L, last, last, last),
             call. = FALSE)
      seam_o <- mean(ocol[so$year %in% cov])
      seam_g <- mean(F$gmst[F$year %in% cov])
      v[beyond] <- seam_o + ratio * (F$gmst[beyond] - seam_g)
    }
    F[[paste0("sst_anom_", h)]] <- v
  }
  F
}

#' Freeze the climate columns of a forcing at their i-th value (or a constant).
#'
#' Every "held climate" construction in the repo used to write F$gmst <- ... by
#' hand; with the observed-SST columns that idiom silently leaves real SST
#' warming in a "frozen" run. This is the one place that knows the full list.
ccx_hold_climate <- function(F, i = 1L, value = NULL) {
  # ⚠ aod_NH/aod_SH are NOT held here, and that is the ARCHITECTURE, not an
  # oversight (Marcus 2026-08-29, correcting my first answer to
  # test-so-entrainment.R's inventory gate).
  #
  # THE MODEL HAS EXACTLY ONE AOD PATHWAY: diffuse light -> NPP. The volcanic
  # TEMPERATURE effect is NOT a second mechanism -- it is already IMPLICIT in
  # the observed `gmst` record this function does hold. So AOD is a radiative
  # driver, not a climate variable, and holding `gmst` is what holds the
  # volcanic climate signal.
  #
  # ⚠ DO NOT ADD AN AOD -> TEMPERATURE TERM. It would DOUBLE-COUNT the cooling
  # that `gmst` already carries. Backing the volcanic signal OUT of `gmst` (for
  # the app's volcano checkbox) is a FORCING-side job -- FaIR's volcanic-free
  # run, or a Foster-Rahmstorf regression -- not a model term.
  #
  # ⚠ CONSEQUENCE, AND IT IS REAL: once `gamma_diff` is non-zero, "climate held"
  # NO LONGER IMPLIES "no interannual variability" -- volcanic NPP pulses
  # survive this call. A diagnostic that needs a volcanically quiet run must
  # zero aod_NH/aod_SH itself. NOT moot: CCX_GAMMA_DIFF_DEFAULT is 0.25 (R/model.R)
  # and every fitted mode carries a non-zero gamma_diff.
  #
  # N DEPOSITION (ndep_NH/ndep_SH, 2026-09-30) is NOT held either, for the same
  # kind of reason: it is an EMISSIONS-driven chemical input (NOx + NH3), like the
  # CO2 emissions, not a climate state. Once ndep_ret != 0, "climate held" does
  # not mean "deposition held"; a run that needs deposition frozen must hold
  # those two columns itself. (test-so-entrainment.R's inventory gate records the
  # classification.)
  for (cc in c("gmst", "enso", "sst_anom_NH", "sst_anom_SH")) {
    if (is.null(F[[cc]])) next
    F[[cc]] <- if (is.null(value)) F[[cc]][i] else value
  }
  F
}
