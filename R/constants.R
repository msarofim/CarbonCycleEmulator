# =====================================================================
# constants.R — every physical constant in the model, with provenance.
#
# Each entry carries a `status`:
#   "derived"     computed here from stated inputs; the derivation is the source
#   "cited"       a literature value with a specific citation
#   "data"        read from an acquired dataset (see data-raw/)
#   "provisional" a working value NOT yet traced to a source -- must not
#                 survive into published results
#
# ccx_check_constants() lists anything still provisional. ⚠ NOTHING GATES ON
# THAT LIST BEING EMPTY (header corrected 2026-09-12, review C -- the text that
# stood here claimed calibration and headline runs were gated on it, and no
# such gate exists). What IS true: tests/testthat/test-constants.R keeps the
# list as a LEDGER -- a pinned expected set that fails when an entry is added
# or retired without the test being updated deliberately -- and most of the
# entries on it are read from fitted code today. The ledger keeps that
# VISIBLE; it does not refuse it. "Must not survive into published results"
# is the standard, enforced by reading the ledger, not by a gate.
# This exists because "small", "standard" and "canonical" have already been
# wrong once in this project (the nuclear-industry 14C term).
# =====================================================================

# Values that other constants are DERIVED FROM must be defined once, here, and
# referenced -- never re-typed as a literal further down. A mutation test
# (2026-08-10) caught exactly that bug: LAMBDA_C14 was written as log(2)/5700
# and so was labelled "derived" while actually being an independent copy of the
# half-life. Changing T_HALF_C14 left the decay rate silently unchanged.
.T_HALF_C14   <- 5700              # yr, true half-life (see T_HALF_C14 entry)
.SEC_PER_YR   <- 365.25 * 86400
.AVOGADRO     <- 6.02214076e23
.M_C          <- 12.011            # g/mol
.SST_PCO2_DLNDT <- 0.0423          # 1/degC, d ln pCO2 / dT (Takahashi). Hoisted
                                   # 2026-09-03: SST_PCO2_SENSITIVITY and the
                                   # entrainment chain below BOTH need it, and
                                   # the entrainment chain had re-typed it --
                                   # the very duplication the audit was for.

# ---- inputs to the inert soil fraction (2026-09-30) ------------------
# Copard et al. 2025 radiocarbon-free ("aOC") soil carbon, Gt, by layer, on the
# global SOC stocks: 0-30 cm and 30-100 cm. SOIL_INERT_FRAC derives from these.
.AOC_0_30_GT   <- 77;   .SOC_0_30_GT   <- 704
.AOC_30_100_GT <- 216;  .SOC_30_100_GT <- 801

# ---- inputs to the D2 non-CO2 land-sink drivers (2026-09-30) ----------
# notes/lit_2026-09-30_nonco2_land_sink_drivers.md (subagent; spot-checked by the
# main session 2026-09-30: every arithmetic item reproduced; MAGICC6 Table B4 and
# Varney 2024 read in the primary text). Named here, derived below.
# Standard atomic weights, g/mol: CIAAW abridged 2024 (ciaaw.org, read 2026-09-30):
# H 1.0080(2), N 14.007(1), O 15.999(1). (.M_C above is the same table's 12.011.)
.M_H <- 1.0080; .M_N <- 14.007; .M_O <- 15.999
# N RETENTION (the ruled form, 2026-09-30): whole-FOREST carbon sequestered per unit
# N deposited, kg C/kg N. Du & de Vries 2024 book ch. (doi:10.1016/B978-0-323-91140-5.
# 00016-6; full text) Tables 4.1-4.2: boreal / temperate / tropical 40 / 31 / 12 (de
# Vries 2014) and 24 / 10 / 6 (Du & de Vries 2018); the lit note's central "~13" is a
# round central of those (the note's judgement, lit note sec. 2a(iv)).
.NDEP_RET_FOREST_CENTRAL <- 13
# The LAND-MEAN range, kg C/kg N (lit note sec. 2a(iv) table): 0.6 = aboveground wood
# only (Schulte-Uebbing 2022 world 2 kg C/kg N x forest share 0.30) up to 8.7 = the
# 15N-retention ceiling (Gurmesa 2022 Nat. Commun. 13:880, 0.72 PgC/yr as a forest
# ceiling, x forest share). The floor is aboveground wood only, i.e. a LOWER bound on
# whole-ecosystem retention; the ceiling is its authors' "likely ceiling".
.NDEP_RET_LAND_RANGE <- c(0.6, 8.7)
# Forest share of LAND deposition: 23.1 Tg N/yr on forests in 2010 (Schulte-Uebbing
# et al. 2022, GCB 28:899, doi:10.1111/gcb.15960, Methods) over land deposition
# 63.9 (Tian 2022 ESSD 14:4551 Table 2, CMIP6 CCMI 2010s) to 92.7 Tg N/yr (Zhu 2025
# Nat. Commun. 16:46, 2020, obs) = 0.25-0.36; the central 0.30 is the note's.
.NDEP_FOREST_SHARE <- 0.30
# MAGICC6 C4MIP emulations, sigma_NPP (K^-1 of GLOBAL-MEAN temperature, Eq. A21
# F = F0 exp(sigma dT)): Meinshausen et al. 2011 ACP 11:1417, Table B4, ten models
# (BERNcc, CSM1, CLIMBER2LPJ, FRCGC, HadCM3LC, IPSLCM2C, LLNL, MPI, UMD, UVIC27).
# Read from the PDF by the main session 2026-09-30.
.NPP_TSENS_C4MIP <- c(0.01, 0.01, 0.04, 0.02, 0.00, -0.06, 0.00, -0.03, -0.03, -0.02)

# ---- inputs to the Southern-Ocean entrainment amplitude (2026-09-03) --
# ⛔ NAMED HERE AND COMPUTED BELOW, NOT TYPED AS AN ANSWER. The entry that
# replaced them carried `value = 30` with the arithmetic only in its prose
# `source`, i.e. it was labelled "derived" while being an independent copy --
# THE EXACT LAMBDA_C14 BUG this file's header warns about. Computing it moved
# the number 30 -> 29.68, which is the drift a typed "derived" value hides.
# ⛔⛔ BOTH BAND AMPLITUDES BELOW ARE NOW READ FROM data/ PRODUCTS, NOT TYPED
# (2026-09-09w, ruled by Marcus). The two legs of this chain were each wrong in
# a DIFFERENT way, and both were invisible because the number was a literal:
#   SST  -- the typed 3.0 was the BAND PEAK-TO-PEAK carrying the label
#           "half-amplitude". A true factor of 2, flagged by the 09-09t review
#           and confirmed by recomputation. The band half-amp is 1.4995 K.
#           ⛔ AND THE COMMENT THAT STOOD HERE -- "the band is colder and swings
#           HARDER than the hemisphere containing it" -- IS FALSIFIED
#           like-for-like: 1.4995 < 1.7464. It read true only by comparing a
#           p2p against a half-amp ⇒ [[like_for_like_forcing]].
#   pCO2 -- the typed 19.45 was the PER-CELL harmonic reduction. A well-mixed
#           BOX needs the harmonic of the AREA-MEAN series, 16.26 uatm, which is
#           also what the SST leg uses ⇒ [[amp_definition_mismatch]] (third
#           incident). ⚠ The review ALSO called this leg a p2p and that is
#           REFUTED -- a p2p would be ~39; its defect was 4.8 %, not 2x.
# ⇒ The two legs are now like-for-like: both BAND, both HALF-AMPLITUDE, both
#   read from a product with a reproduction gate ([[derived_must_mean_computed]]).
# ⚠ SOURCE ORDER, and it is HANDLED rather than worked around. constants.R
# sorts BEFORE paths.R under the alphabetical `list.files("R", ...)` bootstrap,
# and the registry below needs a FINITE number at source time
# (test-constants.R asserts `is.finite(k$value)` on every entry), so a lazy
# accessor of the `ccx_h_ml_prior()` kind is not available here. `ccx_path()` is
# therefore hoisted into R/aaa_root.R, which sorts first. ⛔ Do NOT replace this
# with a relative "data/..." path: testthat runs from tests/testthat/ and the
# app from app/, and that fallback took the whole suite down on 09-09w.
.ccx_obs_rds <- function(f) readRDS(ccx_path("data", f))
.ENT_SO_SST_AMP   <- .ccx_obs_rds("obs_so_sst_seas_amp.rds")$band_half_amp_K
                              # K, seasonal SST HALF-amplitude of the 40-90 S
                              # BAND (ERSSTv5 1975-2024, cos-lat weighted, first
                              # annual harmonic), COMPUTED by
                              # data-raw/build_so_sst_seas_amp.R, whose GATE 1
                              # reproduces the registered SST_SEAS_AMP_SH_OBS
                              # (1.74644) from the same product to 1.9e-05 --
                              # so the band row is like-for-like with the
                              # hemispheric constant beside it, not a second
                              # convention. ⚠ NOT SST_SEAS_AMP_SH_OBS, which is
                              # the SH HEMISPHERIC MEAN: named apart so the two
                              # are never conflated.
.ENT_PCO2_DLNDT   <- .SST_PCO2_DLNDT   # ⛔ NOT re-typed: this IS
                              # SST_PCO2_SENSITIVITY, which was already
                              # registered, and the 2026-09-03 audit caught this
                              # chain having typed 0.0423 a second time. The one
                              # THERMODYNAMIC input here; the rest is geometry or
                              # observation. ⚠ That entry warns about DOUBLE
                              # COUNTING against the carbonate module's own
                              # K0/K1/K2 temperature dependence -- not a risk
                              # here, because this factor is used ONLY in a
                              # back-of-envelope PRIOR CENTRE and never applied
                              # inside the model.
.ENT_PCO2_REF     <- 370      # uatm, reference surface pCO2 the % is taken on
.ENT_SO_PCO2_AMP  <- .ccx_obs_rds("obs_so_pco2_seas_amp.rds")$band_amp_uatm
                              # uatm, OBSERVED 40-90 S pCO2 seasonal amplitude
                              # (Landschutzer/Laruelle NCEI 0209633), the same
                              # product CCX_ENT_SEAS_PEAK_MO's 7.50 comes from.
                              # The harmonic of the AREA-MEAN series (16.26),
                              # which is what a well-mixed BOX requires; the
                              # per-cell reduction is 19.68 and the shipped
                              # literal was 19.45. Promoted from the diagnostic
                              # by data-raw/build_so_pco2_seas_amp.R.
                              # ⛔ NEVER the SH hemispheric row (3.69): that is a
                              # 4.4x ANTIPHASE cancellation between a thermal
                              # subtropical limb and the Southern Ocean.
                              # ⚠ pCO2, NOT flux -- no k or K0 seasonality.
.ENT_DIC_SURF     <- 2150     # umol/kg, surface DIC. ⚠ UNCITED, and it sits
                              # ~5.6 % above the GLODAP surface value GATE G
                              # scores against (~2035). Left as inherited rather
                              # than switched, because the impact is measured and
                              # negligible: 2150 -> 2035 moves the prior centre
                              # by log(2035/2150)/ENT_SEAS_LOGSD = 0.11 sigma.
                              # Stated rather than quietly reconciled.
.ENT_REVELLE      <- 13       # buffer factor. ⛔ DELIBERATELY NOT read off the
                              # model's own carbonate chemistry: this number
                              # sets a PRIOR CENTRE, and a prior derived from
                              # the code under test can never disagree with it
                              # ([[gate_reads_its_own_output]]).
.ENT_BAND_AREA_FR <- 0.369    # 40-90 S ocean area as a fraction of SH ocean area

CCX_CONSTANTS <- list(

  # ---- unit conversions ---------------------------------------------
  GtC_PER_PPM = list(
    value = 2.124, units = "GtC per ppm CO2",
    status = "cited",
    source = paste("Value used by the Global Carbon Budget to convert its own budget",
                   "(Friedlingstein et al. 2026). Adopted for CONSISTENCY WITH GCB,",
                   "whose sink estimates are calibration targets.")),

  GtC_PER_PPM_DERIVED = list(
    value = 5.1352e18 / 0.0289647 * 1e-6 * (.M_C / 1000) / 1e12,
    units = "GtC per ppm CO2",
    status = "derived",
    source = paste("Dry atmospheric mass 5.1352e18 kg (Trenberth & Smith 2005),",
                   "M_air 28.9647 g/mol, M_C 12.011 g/mol. Gives 2.130, i.e. 0.3 % above",
                   "the GCB value. Kept only to document the discrepancy -- the model",
                   "uses GtC_PER_PPM.")),

  MOL_C_PER_GtC = list(
    value = 1e15 / .M_C, units = "mol C per GtC",
    status = "derived", source = "1e15 g/GtC divided by M_C"),

  # ---- isotopes ------------------------------------------------------
  T_HALF_C14 = list(
    value = .T_HALF_C14, units = "yr",
    status = "cited",
    source = paste("True (Cambridge-revised) half-life, 5700 +/- 30 yr, as used by IntCal",
                   "and Hua et al. (2022). NOT the Libby 5568 yr, which is an age-REPORTING",
                   "convention only (Stuiver & Polach 1977) and must never be used for decay.")),

  LAMBDA_C14 = list(
    value = log(2) / .T_HALF_C14, units = "1/yr",
    status = "derived", source = "ln(2) / T_HALF_C14 -- derives from .T_HALF_C14, never re-typed"),

  R13_VPDB = list(
    value = 0.0111802, units = "13C/12C",
    status = "cited",
    source = "VPDB reference ratio, 0.0111802 +/- 0.000028 (Chang & Li, via NBS 19)."),

  R14_STD = list(
    value = 1.176e-12, units = "14C/12C",
    status = "cited",
    source = paste("Absolute International Standard Activity corresponding to Delta14C = 0",
                   "(Stuiver & Polach 1977).")),

  MOL_C14_PER_GBq = list(
    value = 1e9 / (log(2) / (.T_HALF_C14 * .SEC_PER_YR)) / .AVOGADRO,
    units = "mol 14C per GBq",
    status = "derived",
    source = "N = A/lambda with lambda from T_HALF_C14; used for nuclear-industry emissions"),

  # ---- preindustrial state (from data, not memory) --------------------
  CO2_PI_PPM = list(
    value = 276.88, units = "ppm",
    status = "data",
    source = paste("Law Dome spline (Rubino et al. 2019), 1745-1755 mean, computed by",
                   "data-raw/build_calibration_data.R.")),

  D13C_PI = list(
    value = -6.469, units = "per mil",
    status = "data",
    source = "Law Dome d13C spline (Rubino et al. 2019), 1745-1755 mean."),

  D14C_PI = list(
    value = 2.16, units = "per mil",
    status = "data",
    source = paste("IntCal20 (Reimer et al. 2020) at 1750 CE, via the rintcal package;",
                   "converted from conventional 14C age with F14C = exp(-age/8033) and",
                   "Delta14C = 1000(F14C exp(calBP/8267) - 1). Replaces an earlier",
                   "0-by-construction placeholder, which was wrong by this full 2.16 per mil",
                   "-- ~8 % of the 26.6 per mil pre-bomb Suess decline it has to reproduce.",
                   "Validated against Hua et al. (2022) over 1941-1950: mean |diff| 0.90 per mil.")),

  # ---- ocean geometry -------------------------------------------------
  OCEAN_AREA_NH = list(
    value = 1.55e14, units = "m2",
    status = "cited",
    source = paste("Ocean = 60.7 % of the NH surface (Pidwirny 2006, Fundamentals of Physical",
                   "Geography, ch. 8(o), physicalgeography.net; the figure every geographic",
                   "reference carries) x a hemisphere's 2.551e14 m2 = 1.548e14, 1.55e14 to 3 s.f.;",
                   "NH + SH = 3.61e14 vs Eakins & Sharman (2010, NOAA NGDC, Volumes of the",
                   "World's Oceans from ETOPO1) 3.619e14 m2 (0.2 %). Cited 2026-09-21 h at the",
                   "value it always had -- a value change is a model change, not a citation.")),

  OCEAN_AREA_SH = list(
    value = 2.06e14, units = "m2",
    status = "cited",
    source = paste("Ocean = 80.9 % of the SH surface (Pidwirny 2006, as OCEAN_AREA_NH) x",
                   "2.551e14 m2 = 2.064e14, 2.06e14 to 3 s.f.; the pair sums to Eakins &",
                   "Sharman (2010)'s 3.619e14 within 0.2 %. Cited 2026-09-21 h, value unchanged.")),

  OCEAN_DEPTH = list(
    value = 3700, units = "m",
    status = "provisional",
    source = paste("Working value. Eakins & Sharman (2010, NOAA NGDC, ETOPO1): volume 1.335e9 km3",
                   "over 3.619e8 km2 = 3690 m mean depth -- 0.3 % under the working 3700. STAYS",
                   "provisional at 3700 (2026-09-21 h): the column depth sets every deep-row",
                   "mass, so moving it is a model change and a restamp, not a citation.")),

  ALK_SURFACE = list(
    value = 2300e-6, units = "mol/kg",
    status = "provisional",
    source = paste("Surface total alkalinity, held FIXED (alkalinity is near-conserved on",
                   "these timescales). NEEDS a cited global-mean surface value.")),

  # ---- biological pump (task 9) ---------------------------------------
  # STRUCTURAL, not fitted. The pump's magnitude and its carbonate share live in
  # ccx_default_params() because a refit might touch them; these two do not.
  #
  # PUMP_GRAD_OBS is the exception that proves that rule: it is not the pump's
  # magnitude but the OBSERVATION the magnitude's prior is anchored on, and it is
  # here rather than typed into calibrate.R so there is one place to change it.
  # It MUST equal the shipped `ocean_grad_dic` target -- tests/testthat/
  # test-constants.R asserts exactly that against obs_glodap_deep.rds, so the two
  # cannot drift apart silently if the target is ever re-derived.
  # FULL PRECISION, and that is not fussiness: typed at the 233.109 the handoffs
  # quote, it sat 3.8e-4 umol/kg off the shipped target and the consistency test
  # below caught it on its first run. The digits here are the target's own.
  PUMP_GRAD_OBS = list(
    value = 233.109378176267, units = "umol/kg",
    status = "data",
    source = paste("GLODAPv2 deep-minus-surface DIC gradient on the shipped",
                   "fixed depths (0-100 m vs >2627.2 m), = the `ocean_grad_dic`",
                   "likelihood target. The PRIOR CENTRE for the fitted",
                   "`pump_grad` (Marcus 2026-08-16d), NOT the value it takes.")),

  # ---- TERRESTRIAL PHOTOSYNTHETIC 13C DISCRIMINATION (registered 2026-09-14 g) ----
  # Carried since the model's first day as the literal `1 - 18/1000` in
  # ccx_prepare()'s aux (`alpha_photo`), whose comment cited "the constants.R
  # note" -- a note that never existed (review 09-14 g, root cause #3). The
  # VALUE is the C3 GPP-weighted global mean; the WHOLE-biosphere value is
  # lower because C4 plants (~20-23 % of GPP) discriminate ~3.6 permil:
  #   Lloyd & Farquhar (1994) Oecologia 99:201-215, abstract: C3 GPP-weighted
  #   17.8 permil (12.9 xerophytic woods/shrub to 19.6 cool deciduous forest);
  #   C4 3.6; TOTAL 14.8 at 21 % C4. Still et al. 2003 GBC 17:1006 give 16.5 at
  #   C4 = 23 % of GPP; Suits et al. 2005 GBC 19:GB1017 15.9 (C3 19.2).
  #   ⚠ CORRECTED 2026-10-12 (citation rulings rows 11-12; notes/photo_eps_sources_
  #   2026-10-12.md): this note had "25 % C4" for Lloyd & Farquhar (it is 21 %) and a
  #   "15-18" bracket attributed to Still / Suits that is in NEITHER paper.
  #   The label hilda_csl3v0kaidgbemwtc reads ALPHA_PHOTO_EPS_STILL2003 (16.2).
  # STATUS PROVISIONAL DELIBERATELY: the number in use (18) is the C3-only
  # value, ~3 permil ABOVE the biosphere-wide 14.8-16.5, and moving it re-scales
  # the land sink's isotopic signature -- the quantity that separates land from
  # ocean uptake in every d13C row -- so it belongs in the constants batch of the
  # NEXT refit (review 09-14 g §B5 item 3), not in a point edit of the canonical.
  # ⚠ SUPERSEDED IN PRACTICE (code review 2026-10-12, text-only fix): 18 is now
  # only the ABSENT-FIELD DEFAULT -- ccx_prepare() reads this ledger value when
  # `p$alpha_photo_eps` is NULL (ccx_default_params() and the plain "hilda"
  # block leave it absent). Every adopted mode since 09-14 h, the canonical
  # `hilda29e` included, runs 15.6 permil: the `hilda_c` structure block sets
  # `alpha_photo_eps` = CCX_ALPHA_PHOTO_EPS_BIOSPHERE (R/calibrate.R,
  # ccx_struct_hilda_c(); the ruled mid-bracket, cited there). Measured
  # 2026-10-12: the canonical's run parameters carry alpha_photo_eps 15.6. The
  # `source` string below says so (its "IN USE: 18" was corrected 2026-10-12).
  ALPHA_PHOTO_EPS = list(
    value = 18, units = "permil",
    status = "provisional",
    source = paste("Lloyd & Farquhar (1994) Oecologia 99:201-215: C3 GPP-weighted",
                   "13C discrimination 17.8 permil; C4 3.6; total 14.8 at 21 % C4 (corrected 2026-10-12",
                   "from '25 %'). Still et al. (2003) GBC 17:1006: 16.5 at C4 23 %; Suits et al. (2005)",
                   "GBC 19:GB1017: 15.9 (the old '15-18' bracket is in neither). LEDGER DEFAULT 18 (the",
                   "C3-only value), read only where a parameter set leaves alpha_photo_eps absent. Labels",
                   "from 09-14 h to #18 (the canonical hilda29e included) run 15.6, the mid-point of",
                   "14.8-16.5 (CCX_ALPHA_PHOTO_EPS_BIOSPHERE); label hilda_csl3v0kaidgbemwtc runs",
                   "ALPHA_PHOTO_EPS_STILL2003 (16.2).")),

  # ---- THE MARTIN REMINERALISATION EXPONENT (registered 2026-09-14 h, option
  # D + E) ----
  # The shape of the PRESCRIBED export field under `pump_field = "martin"`:
  # F(z) = F(z_s) (z / z_s)^-b, the open-ocean composite of Martin et al. 1987.
  # SOURCED from the paper text 2026-09-08f (memory overturning_and_mld_
  # literature; handoff 09-08b): p. 273 / Fig. 5, "1.53 (z/100)^-0.858
  # (r^2 = 0.81)", n = 48. Carried as a literal in calibration/lib_martin_shape.R
  # from 09-08h until today; the library now reads it from here.
  # ⚠ Nowicki et al. 2022's own gravitational POC profile attenuates with an
  # effective b = 0.744 (94 -> 919 m, data-raw/build_pump_export_prior.R) --
  # shallower. Recorded, not adopted: the shape's exponent is the sourced one.
  MARTIN_B = list(
    value = 0.858, units = "dimensionless",
    status = "cited",
    source = paste("Martin, Knauer, Karl & Broenkow (1987) Deep-Sea Res. 34(2):267-285,",
                   "p. 273 / Fig. 5: open-ocean composite flux F(z) = 1.53 (z/100)^-0.858",
                   "mol C m-2 yr-1 (r^2 = 0.81, n = 48). Read from the paper text 2026-09-08f.")),

  PUMP_EPS13_ORG = list(
    value = -20, units = "permil",
    status = "provisional",
    source = paste("Photosynthetic fractionation of marine organic matter",
                   "relative to the DIC it is fixed from, ~20-22 permil.",
                   "WORKING VALUE, recollected, NEEDS a cited source.")),

  PUMP_EPS13_CARB = list(
    value = 1, units = "permil",
    status = "provisional",
    source = paste("Biogenic CaCO3 relative to the DIC it precipitates from --",
                   "SMALL and POSITIVE, unlike the organic limb. Expressed as a",
                   "FRACTIONATION, not the ~+2 permil absolute value quoted in",
                   "calibration/diag_alk_gradient.R: the absolute figure is",
                   "surface DIC (+1.29 observed) plus this. WORKING VALUE.")),

  RHO_SEAWATER = list(
    value = 1025, units = "kg/m3",
    status = "cited",
    source = paste("Surface seawater at S 35, T 15 degC, 0 dbar: 1025.97 kg/m3 by the UNESCO",
                   "EOS-80 equation of state (Millero & Poisson 1981, Deep-Sea Res. 28A, 625-629;",
                   "UNESCO Tech. Pap. Mar. Sci. 44, 1983) -- 1025 to the 0.1 % the model's",
                   "mass bookkeeping resolves. Cited 2026-09-21 h, value unchanged.")),

  # ---- land -----------------------------------------------------------
  NPP_GLOBAL_PI = list(
    value = 60, units = "GtC/yr",
    status = "provisional",
    # ⚠ PROVISIONAL BY RULING (Marcus 2026-09-29, option 1 of four), NOT for want of a
    # search: notes/lit_2026-09-29_npp_global_pi.md opened every candidate and NONE gives
    # a 1750 value. What the model means by it (R/model.R npp0): NPP at 1750 CO2 BEFORE
    # clearing. The model has NO pre-1750 clearing, so this IS its 1750 NPP (measured: 60.00
    # at both modes). Every cited number is PRESENT-DAY.
    # ⚠ MEASURED TENSION (calibration/diag_model_npp_modern.R, 2026-09-29): the model's own
    # 2001-2023 NPP is 69.8 (hilda29l) / 70.0 (phi = 0 v0k) against MOD17 52.7 over the SAME
    # years (+33 %) and Haberl's 59.2 actual. The follow-up is to FIT it against a
    # modern-NPP likelihood row (option 4).
    source = paste("Global terrestrial NPP, total (above + below ground). Value from IPCC TAR",
                   "WG1 Ch.3 (Prentice et al. 2001) sec. 3.2.1: 'about 60 PgC/yr through",
                   "integration of field measurements'; Table 3.2 totals 59.9 (Atjay 1979/WBGU)",
                   "and 62.6 (Mooney, Roy & Saugier 2001). Bracketed by Ito 2011 GCB 17:3161",
                   "(doi:10.1111/j.1365-2486.2011.02450.x; abstract only) 56.2 +/- 14.3 (n=251,",
                   "present day), Haberl et al. 2007 PNAS 104:12942 (doi:10.1073/pnas.0704243104)",
                   "Table 1: actual 59.22, potential 65.51 (LPJ, yr-2000 CO2/climate), and",
                   "MOD17A3HGF C6.1 52.7 (2001-2023, data/obs_npp_hemispheric.rds). SCOPE",
                   "CAVEAT: all PRESENT-DAY; no opened source gives a 1750 value (AR5 Fig 6.1 /",
                   "AR6 Fig 5.12 give preindustrial GPP only, 108.9 / 113). TAR is the OLDEST",
                   "source. Used as NPP0 before model clearing. Cited 2026-09-29, value unchanged.")),

  # ---- INERT SOIL CARBON, 0-1 m (2026-09-30, Marcus: depth 0-1 m) -----
  # The carve-out share of the PASSIVE pool (soil_inert_frac, R/model.R). 0-1 m
  # because the passive pool's 1500 GtC IS the 0-1 m inventory (J&J 2000 1502;
  # Copard's own 0-1 m denominator 1505); 0-2 m (f 0.313) would also need a
  # ~2415 GtC passive stock. CHANGELOG 2026-09-30 (b).
  SOIL_INERT_FRAC = list(
    value = (.AOC_0_30_GT + .AOC_30_100_GT) / (.SOC_0_30_GT + .SOC_30_100_GT),
    units = "fraction",
    status = "cited",
    source = paste("Radiocarbon-free (F14C = 0) share of global SOC, 0-1 m: (77 + 216) / (704 + 801)",
                   "= 0.195. Copard et al. 2025, Global Change Biol. 31(9):e70482,",
                   "doi:10.1111/gcb.70482 (PMC12405676): aOC ratios 0.11 +/- 0.10 (0-30 cm) and",
                   "0.27 +/- 0.18 (30-100 cm) in Table 3 (313 profiles, 261 ISRaD + 52 LSCE); the",
                   "layer masses 77 of 704 Gt and 216 of 801 Gt are PRINTED in sec. 3.1, on the",
                   "Batjes 1996 / Jobbagy & Jackson 2000 stocks. The 0-1 m sum is OURS: the paper",
                   "prints no 0-1 m fraction. Its +/- is unlabelled (a spread, not an SE).",
                   "Verified against the PMC full text 2026-09-30.",
                   "notes/lit_2026-09-29_passive_soil_stock.md. SINGLE-STUDY and method-dependent",
                   "(a two-end-member mixing split); it contradicts the Shi 2020 / He 2016 reading",
                   "of old bulk soil. A +/-1 sigma propagated with the layers fully correlated",
                   "spans ~0.05-0.34 (CHANGELOG 2026-09-29 v; our propagation, not Copard's).",
                   "Cited 2026-09-30.")),

  # ---- D2: NON-CO2 LAND-SINK DRIVERS (Marcus 2026-09-30) -------------------
  # Rulings 2026-09-30: (a) N deposition from the EMISSIONS PROXY; (b) climate greening
  # with a SIGN-FREE prior; (c) recovery NOT built (the evidence contradicts a 1750
  # deficit, and land-use regrowth is already inside GCB's net E_LUC). CHANGELOG 09-30 (k).
  NDEP_N_PER_NO2 = list(
    value = .M_N / (.M_N + 2 * .M_O), units = "g N per g NO2",
    status = "derived",
    source = paste("Mass fraction of N in NO2 from CIAAW 2024 abridged standard atomic weights",
                   "(N 14.007, O 15.999). NOx emissions (CEDS / RCMIP / CMIP7 ScenarioMIP) are",
                   "reported as NO2 mass: the van Vuuren v1.1.1 file states 'Mt NO2/yr';",
                   "RCMIP's 'Mt NOx/yr' is on the same basis (C, 2026-09-30: the two",
                   "histories agree to 10 % at 2014 only on an NO2 basis).")),
  NDEP_N_PER_NH3 = list(
    value = .M_N / (.M_N + 3 * .M_H), units = "g N per g NH3",
    status = "derived",
    source = paste("Mass fraction of N in NH3 from CIAAW 2024 abridged standard atomic weights",
                   "(N 14.007, H 1.0080).")),
  NDEP_LAND_FRAC = list(
    value = 0.60, units = "fraction of global NOx-N + NH3-N emission deposited on land",
    status = "cited",
    source = paste("Land share of global inorganic N deposition. Galloway et al. 2004",
                   "Biogeochem. 70:153 Table 1: 63.5 of 103 Tg N/yr, early 1990s (0.62; 1860",
                   "0.55). Kanakidou et al. 2016 JAS 73:2039 Table 1: 58 of 99, 2005 (0.59).",
                   "Tan et al. 2018 ACP 18:6847 Table 5 (HTAP II): 73.7 inland of 113.3, 2010",
                   "(0.65; 0.80 with coastal cells). 0.60 is the value RULED with the proxy",
                   "(Marcus 2026-09-30), inside the modern 0.59-0.65. Deposition ~= emission:",
                   "dep/(NOx+NH3 emission) 0.94-0.99 (Galloway T1; Lamarque 2013; Tan T5), so",
                   "no separate factor. DEGENERATE with ndep_ret, whose prior width carries it.")),
  NDEP_NH_SHARE = list(
    value = 0.83, units = "fraction of land deposition in the NH",
    status = "cited",
    source = paste("NH share of LAND N deposition. No published hemispheric split (lit note",
                   "sec. 1d); from Tan et al. 2018 ACP 18:6847 Table 5 regional inland",
                   "deposition: SH = (1.0 + 7.3 + 0.5 x 8.1) / 73.7 = 0.17 (the equatorial",
                   "region split half and half) -- OUR arithmetic on a verified table, and",
                   "rough. Applied as a constant in time.")),
  # ---- the k_w and tau_ex PRIORS, cited at last (W5, RULED 2026-10-02; objective #15) ----
  # Both were bare [VERIFY] literals in CCX_PARAM_TABLE from 08-09 to 10-02 (k_w lognormal
  # 1500 m/yr / 0.4, "Wanninkhof global mean"; tau_ex 1.3 yr / 0.25, "SF6-derived"); the
  # 10-02 audit (C1) found neither had a citation. Sources read 10-02 by a literature
  # subagent (full text unless marked), numbers verified against the ruling question.
  KW_PRIOR_CENTRE = list(
    value = 1446, units = "m/yr",
    status = "cited",
    source = paste("Centre of the k_w prior (Marcus 2026-10-02: '1446, log-sd 0.2'). Naegler (2009)",
                   "Tellus B 61:372, doi:10.1111/j.1600-0889.2008.00408.x, abstract + Table 2: the",
                   "global-mean CO2 piston velocity <k> = 16.5 cm/h, the mean of four bomb-14C /",
                   "inversion studies after his corrections (range 15.1-18.2), UNNORMALISED (in situ",
                   "Schmidt number) -- the right comparison for a model with no Schmidt term; x 87.66",
                   "m/yr per cm/h = 1446. Wanninkhof et al. (2013) Biogeosciences 10:1983 eq. 4:",
                   "15.95 cm/h (1398). CAVEATS: the literature mean is over the ICE-FREE ocean with no",
                   "water-vapour term; the model applies k_w over the whole ocean area and takes",
                   "pCO2 = xCO2, so its equivalent is ~3-10 % lower (1309-1446). NOT the 15.9 +- 3.2",
                   "an earlier record quotes: that is Naegler's average of the UNcorrected originals.")),
  # ⚠ CORRECTED 2026-10-12 (code review): the `source` below said "+-3.2 cm/h on 16.5", but
  # KW_PRIOR_CENTRE's own source puts the +-3.2 on the UNcorrected 15.9, not on the corrected
  # 16.5. On 15.9 the arithmetic is CV 3.2 / 15.9 = 0.201, sqrt(log(1 + 0.201^2)) = 0.199 --
  # so the ruled 0.2 stands either way; only the attribution in the string was wrong.
  KW_PRIOR_LOGSD = list(
    value = 0.2, units = "log-sd",
    status = "derived",
    source = paste("Width of the k_w prior (ruled 2026-10-02): Naegler (2009)'s +-3.2 cm/h, which belongs to",
                   "the UNcorrected 15.9 (CV 0.201, sqrt(log(1 + 0.201^2)) = 0.199; on the corrected 16.5",
                   "it would be 0.19) and Wanninkhof (2014) L&O Methods",
                   "12:351, doi:10.4319/lom.2014.12.351, abstract, +-20 % (0.198); 0.2. Replaces 0.4,",
                   "2.1x the literature's width, which had no recorded reason.")),
  TAU_EX_PRIOR_CENTRE = list(
    value = 0.8, units = "yr",
    status = "cited",
    source = paste("Centre of the tau_ex prior on the HEMISPHERIC-MASS basis (Marcus 2026-10-02:",
                   "'Mass basis 0.8 / 0.26'): the model's two atmosphere boxes are whole hemispheric",
                   "air masses (GtC_PER_PPM / 2 each), so the matching quantity is the MASS-based",
                   "two-box exchange time, not a surface-station one. ⚠ MODEL-DERIVED (the hierarchy's",
                   "last resort, named here as the rule requires): Denning et al. (1999) Tellus B",
                   "51:266, doi:10.3402/tellusb.v51i2.16286, Table 4, TransCom-2 models' true",
                   "hemispheric-mass tau 0.55-1.26 yr, median 0.785; Patra et al. (2009) ACP 9:1209,",
                   "doi:10.5194/acp-9-1209-2009, ACTM tropospheric mass 0.70 +- 0.01. The OBSERVED",
                   "station-pair SF6 value is ~1.34 yr (Geller et al. 1997 GRL 24:675 1.3 +- 0.1,",
                   "abstract; Denning 1999 obs 1.34; Patra 2009 BRW+MLO vs SMO+SPO 1.33 +- 0.18;",
                   "Patra et al. 2011 ACP 11:12813 1.39 +- 0.18; Yang et al. 2019 GRL ~1.4); the models'",
                   "mass/station ratio is ~0.6 (Denning 1999 Table 4: 0.42-0.79), surface stations",
                   "seeing vertically trapped air. The then-canonical hilda33d fitted 0.898 yr (2026-10-02);",
                   "hilda29e, canonical since 2026-10-08 (e), fits 0.893 (measured 2026-10-12).")),
  TAU_EX_PRIOR_LOGSD = list(
    value = 0.26, units = "log-sd",
    status = "derived",
    source = paste("Width of the tau_ex prior (ruled 2026-10-02): the log-sd of the TransCom-2",
                   "models' mass-based exchange times (Denning et al. 1999 Table 4), 0.26. Replaces",
                   "0.25, uncited.")),

  # ---- THE STRATIFICATION FEEDBACK (DESIGN §3.4a S; RULED 2026-10-04, Marcus) ----
  # g(t) = (1 + s * T_key)^(-q/2) multiplies the UPPER part of K(z); T_key = max(0, T - T_deep),
  # T_deep = T lagged exponentially at MIX_TDEEP_TAU. Rulings (verbatim): "Thermocline mixing
  # only", "Obs x law, fixed", "GMST minus lagged deep ocean", "History + futures, one #16 refit".
  # Proposal + literature: notes/proposal_2026-10-04_warming_weakens_mixing.md. All three are
  # STRUCTURAL (set by a label block, never fitted); test-mixing-strat.R ties MIX_STRAT_S to its
  # derivation from data/forcing_gmst.rds and MIX_TDEEP_TAU to data/climate_module.rds.
  MIX_STRAT_S = list(
    value = 0.052198, units = "1/K (fractional change in N^2 per K of T_key)",
    status = "derived",
    source = paste("Observed stratification trend over the ruled key's trend. Cheng et al. 2025,",
                   "Nat. Rev. Earth Environ. 6:637-655, doi:10.1038/s43017-025-00715-5, abstract +",
                   "Table 1: global 0-2,000 m N^2 rising 0.8 +/- 0.1 %/decade (90 % CI, three-dataset",
                   "ensemble, 1960-2024, % of the 2005-2020 climatology). Divided by the 1960-2024 OLS",
                   "trend of T_key = max(0, GMST - T_deep): 0.153264 K/decade (IGCC 2024 GMST,",
                   "data/forcing_gmst.rds, 0 before 1850; T_deep its annual exponential lag at",
                   "MIX_TDEEP_TAU from 0 in 1750). 0.008 / 0.153264 = 0.052198; the CI gives",
                   "0.045673-0.058722. Cross-check: Li et al. 2020, Nat. Clim. Change 10:1116,",
                   "doi:10.1038/s41558-020-00918-2, 0.90 %/decade (1960-2018, IAP). Both verified in",
                   "the papers' own text 2026-10-04. CAVEAT: N^2 trends are relative to a modern",
                   "climatology, not preindustrial -- a second-order difference.")),
  MIX_STRAT_Q = list(
    value = 1, units = "exponent q in K ~ N^-q",
    status = "cited",
    source = paste("Gargett 1984, J. Mar. Res. 42:359-393, doi:10.1357/002224084788502756, eq. 25",
                   "(p. 381): Kv = a0 N^-q with q of order 1; basin budgets give q = 0.8-1.2",
                   "(pp. 364-367; ELA lakes 0.88 +/- 0.16, fjords 1.2). Bounds for the app's range:",
                   "q = 2 (Osborn 1980 at fixed dissipation, as restated by Gargett & Holloway 1984,",
                   "J. Mar. Res. 42:15, eq. 21) and q = 1/2 (Garrett-Munk broadband, Gargett &",
                   "Holloway 1984 p. 25). Read in full (Yale EliScholar, open access) 2026-10-04.")),
  MIX_STRAT_Q_LO = list(value = 0.5, units = "exponent", status = "cited",
    source = "The Garrett-Munk broadband case, K ~ N^-0.5 (Gargett & Holloway 1984 p. 25); the app's low end."),
  MIX_STRAT_Q_HI = list(value = 2, units = "exponent", status = "cited",
    source = "Osborn 1980 at fixed dissipation, K = Gamma eps / N^2 (Gargett & Holloway 1984 eq. 21); the app's high end."),
  MIX_TDEEP_TAU = list(
    value = 194.938955, units = "yr",
    status = "derived",
    source = paste("MODEL-DERIVED (named, as the threshold rule requires): the SLOW timescale of",
                   "CCX's own climate module, data/climate_module.rds irf_d[3] -- a 3-timescale",
                   "impulse response fitted to FaIR 2.2.4 (calib 1.6.0), 841 configs, ensemble mean,",
                   "built 2026-09-24. Used as the deep ocean's lag behind the surface: stratification",
                   "is a surface-minus-deep contrast and relaxes as the deep ocean catches up (CMIP6",
                   "SSP1-2.6 0-200 m stratification FALLS after 2050 at near-flat GMST; Cheng et al.",
                   "2025 Table 1). No observation fixes this lag; a two-layer model's deep relaxation",
                   "time is shorter than its slow mode, so this is the slow end.")),

  NDEP_RET_PRIOR_CENTRE = list(
    value = .NDEP_RET_FOREST_CENTRAL * .NDEP_FOREST_SHARE,
    units = "kg C retained per kg N deposited on land",
    status = "derived",
    source = paste("Centre of the ndep_ret prior (the N-retention flux, ruled 2026-09-30): the",
                   "LAND-MEAN carbon sequestered per unit N deposited = whole-forest ~13 kg C/kg N",
                   "(Du & de Vries 2024 Tables 4.1-4.2; the lit note's central) x the forest share",
                   "of land deposition 0.30 (Schulte-Uebbing 2022 23.1 Tg N on forests over",
                   "63.9-92.7 Tg N on land) = 3.9. At this centre the implied sink is 0.11 / 0.17 /",
                   "0.17 GtC/yr for 1960-89 / 1990-2009 / 2010-23, 7-9 % of GCB 2025's S_LAND (lit",
                   "note sec. 2a(iv); reproduced by the main session). Du & de Vries 2024's global",
                   "forest estimate is '~0.3' PgC/yr (range 0.25-0.72).")),
  NDEP_RET_PRIOR_LOGSD = list(
    value = log(.NDEP_RET_LAND_RANGE[2] / .NDEP_RET_LAND_RANGE[1]) / 4,
    units = "log-sd",
    status = "derived",
    source = paste("Width of the ndep_ret prior: the log-width of the literature's land-mean",
                   "range 0.6-8.7 kg C/kg N (aboveground-wood floor to the 15N ceiling; lit note",
                   "sec. 2a(iv)) taken as +/- 2 sigma, log(8.7 / 0.6) / 4 = 0.67, as ruled",
                   "('2-sigma spanning 0.6-8.7'). Centred on the literature central 3.9 rather",
                   "than the range's geometric midpoint 2.3, so the interval sits HIGH: 1.0-15.",
                   "The floor (aboveground wood only) is a lower bound on whole-ecosystem",
                   "retention, which is why the centre is not moved down to meet it.")),
  NPP_TSENS_PRIOR_SD = list(
    value = stats::sd(.NPP_TSENS_C4MIP), units = "1/K (global-mean temperature)",
    status = "derived",
    source = paste("Width of the SIGN-FREE prior on the NPP temperature sensitivity (NPP x",
                   "exp(npp_tsens x GMST)): SD of MAGICC6's sigma_NPP across its ten C4MIP",
                   "emulations, Meinshausen et al. 2011 ACP 11:1417 Table B4 (median 0.00,",
                   "mean -0.006, range -0.06..+0.04; Eq. A21 is on GLOBAL-MEAN temperature).",
                   "Centre 0 (the median), ruled sign-free by Marcus 2026-09-30. The evidence",
                   "leans negative: CMIP6 gamma_NPP < 0 in 8 of 10 ESMs (Varney 2024 BG 21:2759",
                   "sec. 3.3, verified); GCB 2025 net climate effect on the land sink -0.8 +/- 0.7",
                   "GtC/yr. Read from the Table B4 PDF by the main session 2026-09-30.")),

  # ---- the NH/SH split of terrestrial NPP (2026-08-20k) ----------------
  # npp_frac_NH was fitted under UNIFORM[0.4, 0.8] -- zero observational content
  # -- and landed at 0.4662, putting 53 % of global NPP on the hemisphere that
  # holds 19 % of the land. MOD17A3HGF now measures it (DATA.md section 3c).
  NPP_FRAC_NH_OBS = list(
    value = 0.5942187005, units = "fraction",
    status = "data",
    source = paste("MOD17A3HGF C6.1 (Running & Zhao, doi:10.5067/MODIS/MOD17A3HGF.061;",
                   "ICDC 0.5 deg regrid doi:10.25592/uhhfdm.14635), NH share of global",
                   "NPP, mean over 2001-2023, sd 0.0135. The MODERN share -- NOT the",
                   "1750 parameter. Built by data-raw/build_npp_hemispheric.R.")),
  # THE PRIOR CENTRE, and it is NOT the observation above. `npp_frac_NH` is a
  # 1750 split and MOD17 is 2001-2023; the model walks between them through
  # hemispheric clearing, so the anchor is the observation walked BACK through
  # that clearing. Hence status "provisional": it rides on the model's own
  # `luc_scale` and land turnover times, which are fitted.
  #
  # IT IS THE FIXED POINT, not the inversion evaluated at the incumbent's fit.
  # The walk depends on cleared fraction = cum_luc / land0, and land0 is
  # proportional to npp_frac_NH itself, so the inversion is implicit. Evaluated
  # at the fitted 0.4662 it gives 0.6136 (the number handoff 20d section 5
  # quotes); iterated to self-consistency it gives the value below. The
  # difference, +0.0149, is larger than every other model-dependence here, which
  # is why the fixed point rather than the one-shot inversion is shipped.
  #
  # AND THE CIRCULARITY IS PRICED, in calibration/diag_npp_frac_anchor.R:
  # luc_scale +/- 30 % moves it by 0.0013, tau_soil_slow +/- 30 % by 0.0012,
  # tau_wood +/- 30 % by 0.0003 -- an order of magnitude below the 0.04 prior
  # width and below MOD17's own 0.0135 interannual sd. Re-derive it if
  # `luc_scale` ever moves by much more than that.
  NPP_FRAC_NH_ANCHOR_1750 = list(
    value = 0.5986118987, units = "fraction",
    status = "provisional",
    source = paste("NPP_FRAC_NH_OBS inverted through the model's own hemispheric",
                   "clearing to 1750, as a fixed point. The PRIOR CENTRE for the",
                   "fitted `npp_frac_NH` (Marcus 2026-08-20k), NOT the value it takes.",
                   "Derived by calibration/diag_npp_frac_anchor.R at the arm-N mode.")),

  # ---- the NEP seasonal amplitude factors (2026-08-20r) ----------------
  # WHAT CCX_SEAS_PHI_EFF ACTUALLY IS, because its name misleads and its own
  # comment used to. It is NOT the NPP centroid: the NH NPP-weighted mean
  # latitude is 34.29 and this constant is 75, forty degrees poleward. It is the
  # insolation latitude whose SHAPE best matches observed land productivity ONCE
  # THE AMPLITUDE IS FREE -- and 75 wins that contest as a clean interior
  # optimum (7.5 % residual against 11.4 % at 50; calibration/
  # diag_seas_rectification.R). What it buys is POLAR NIGHT: a hard zero, the
  # only thing in the insolation family that resembles a boreal growing season
  # switching off. At unit amplitude the best shape match is 50, not 75.
  #
  # SO THE CURVE IS RIGHT AND ITS SIZE IS NOT. At 75 the unit-mean curve has a
  # peak-to-peak of 2.801 against an observed 1.747, and until 2026-08-20r the
  # model had no way to scale it -- so seas_T_amp_NH was fitted to 48 K, 4.2x
  # its measured 11.45, purely to cancel the excess (handoff 20d section 3).
  # These two factors are that missing scale, MEASURED.
  #
  # THEY ARE CONDITIONAL ON CCX_SEAS_PHI_EFF and must be re-derived if it moves
  # -- the pair is a (shape, size) unit, not two independent numbers.
  # test-likelihood.R re-fits them from data/obs_npp_seasonal_shape.rds at the
  # CURRENT phi and asserts agreement, so the two cannot drift apart silently.
  #
  # THE SH IS MUCH LESS WELL DETERMINED and that is not a defect in the fit but
  # a property of the hemisphere: 76 % of SH NPP lies equatorward of 23.5 S and
  # its cycle is water-driven, not light-driven. PsnNet gives 0.503 and GPP
  # 0.352 -- a 1.4x bracket, against 0.497/0.487 in the NH.
  SEAS_NPP_AMP_NH = list(
    value = 0.4969, units = "1",
    status = "data",
    source = paste("Least-squares scale of the CCX_SEAS_PHI_EFF['NH'] = 75 insolation",
                   "shape onto the OBSERVED NH land productivity cycle, MOD17A2HGF C6.1",
                   "8-daily net_photosynthesis, 5 years (sd 0.046). Window-integrated,",
                   "free time shift. Derived by calibration/diag_seas_rectification.R;",
                   "GPP gives 0.487 as the other end of the bracket.")),
  SEAS_NPP_AMP_SH = list(
    value = 0.5027, units = "1",
    status = "data",
    source = paste("As SEAS_NPP_AMP_NH at CCX_SEAS_PHI_EFF['SH'] = -30 (sd 0.087).",
                   "GPP gives 0.352 -- a far wider bracket than the NH's, because SH",
                   "productivity is tropical and water-driven.")),

  # ---- observed seasonal amplitudes (2026-08-20g) ----------------------
  # ONE SCALAR PER ENTRY. The registry's contract is is.finite(k$value)
  # (test-constants.R:18), which a named length-2 vector fails -- the first
  # version of this block used c(lo =, hi =) and broke three assertions.
  # THE OBSERVATIONS BEHIND THE SEASONAL PRIORS in R/calibrate.R. They live here
  # rather than typed into that file for the same reason PUMP_GRAD_OBS does:
  # one place to change, and tests/testthat/test-likelihood.R ties the prior's
  # literal `init` to the constant so the two cannot drift.
  #
  # ALL FOUR ARE HALF-AMPLITUDES, K -- the model's own parameter convention, not
  # peak-to-peak. Built by data-raw/build_seasonal_climatology.R; provenance and
  # the mask/weighting caveats in DATA.md section 3b.
  #
  # THE LAND PAIR CARRIES A BRACKET, AND THE BRACKET IS THE PRIOR'S WIDTH.
  # `seas_T_amp_*` multiplies SOIL RESPIRATION, so its honest counterpart is
  # respiration-weighted and what we can measure is AREA-weighted. The gap is not
  # guessable, but it is BOUNDABLE: NH heterotrophic respiration is boreal-
  # weighted, so the >45N band bounds it from above and the all-land mean from
  # below. The prior is then the lognormal whose +/- 1 sigma spans exactly that
  # bracket -- the width is the MEASURED weighting ambiguity rather than a
  # chosen number.
  #
  # THE SH BRACKET USES >30S, NOT >45S, and that asymmetry is deliberate: south
  # of 45 is Antarctica, which has no respiring soil to weight toward. Using it
  # would put the upper bound on ice.
  SEAS_T_AMP_NH_OBS_LO = list(
    value = 11.44502, units = "K, half-amplitude",
    status = "data",
    source = paste("CRU 1961-90 absolute climatology (Jones et al. 1999,",
                   "doi:10.1029/1999RG900002) masked by CRUTEM5 coverage and weighted by an",
                   "ERSSTv5-derived land fraction. ALL NH land -- the LOWER bracket.")),
  SEAS_T_AMP_NH_OBS_HI = list(
    value = 17.92095, units = "K, half-amplitude",
    status = "data",
    source = paste("As SEAS_T_AMP_NH_OBS_LO but NH land >45N -- the UPPER bracket, because",
                   "NH heterotrophic respiration is boreal-weighted.")),
  SEAS_T_AMP_SH_OBS_LO = list(
    value = 3.59155, units = "K, half-amplitude",
    status = "data",
    source = "As SEAS_T_AMP_NH_OBS_LO but all SH land -- the LOWER bracket."),
  SEAS_T_AMP_SH_OBS_HI = list(
    value = 7.10118, units = "K, half-amplitude",
    status = "data",
    source = paste("As SEAS_T_AMP_NH_OBS_LO but SH land >30S -- the UPPER bracket.",
                   ">45S is Antarctica and carries no respiring soil, so it is NOT used.")),
  # THE OCEAN PAIR HAS NO MEASURED BRACKET, so its width is a JUDGEMENT and is
  # labelled as one: 0.25 in log space (~ +/- 28 %), covering the difference
  # between the area-weighted mean we can compute and the gas-exchange-weighted
  # mean the parameter actually is. Nothing measures that gap today. Replacing
  # this with a flux-weighted estimate would be a real improvement.
  SST_SEAS_AMP_NH_OBS = list(
    value = 2.23739, units = "K, half-amplitude",
    status = "data",
    source = paste("NOAA ERSSTv5 (Huang et al. 2017, doi:10.1175/JCLI-D-16-0836.1),",
                   "area-weighted NH hemispheric monthly climatology 1975-2024",
                   "(= LIK_SEAS_WINDOW).")),
  SST_SEAS_AMP_SH_OBS = list(
    value = 1.74644, units = "K, half-amplitude",
    status = "data",
    source = "As SST_SEAS_AMP_NH_OBS, southern hemisphere."),

  # ---- air-sea 13C fractionation (2026-09-02) --------------------------
  # THESE REPLACE TWO LITERALS. Until today `alpha_as_down` = 1 - 2/1000 and
  # `alpha_as_up` = 1 - 10/1000 sat inside ccx_prepare()'s aux (R/model.R),
  # carrying the word "provisional" WITHOUT being in this ledger -- so the audit
  # that exists to find provisional constants could not find them. They were
  # also readable from nowhere else, which made setting them on a parameter list
  # a SILENT NO-OP. Both defects are fixed here and in R/model.R.
  #
  # THE STRUCTURE, and why it is two limbs and not one net alpha: BOTH
  # directions carry the kinetic effect; only EVASION also carries the
  # equilibrium DIC-gas offset. That is Quay et al. (2003) eq.(2), and it is
  # what makes the steady-state d_ml - d_atm come out AT eps_DIC-g.
  #     eps_down = eps_k(T)                  eps_up = eps_k(T) - eps_DIC-g(T)
  #
  # ⚠ THE PAPER PRINTS ITS SEAWATER FIT TWICE WITH DIFFERENT COEFFICIENTS --
  # abstract (0.014, -0.105), conclusions (0.0144, -0.107) -- and the two T
  # coefficients are EXACTLY ONE STATED SIGMA APART. Nothing in the text
  # prefers one. The ABSTRACT form is registered because it is the form the
  # secondary literature quotes; the difference moves d(eps_up)/dT by 1.7 %,
  # which is below every verdict it has been used for
  # (calibration/diag_alpha_as_up_precheck.R sec.2 prints both).
  ALPHA_AS_ZHANG_A = list(
    value = 0.014, units = "permil/degC per unit fCO3",
    status = "data",
    source = paste("Zhang J., Quay P. D., Wilbur D. O. (1995), Geochim.",
                   "Cosmochim. Acta 59(1), 107-114, seawater fit",
                   "eps_DIC-g = a*T*fCO3 + b*T + c, ABSTRACT printing;",
                   "valid 5-25 degC and 0.05 < fCO3 < 0.20. See",
                   "ALPHA_AS_ZHANG_B for the two-printing discrepancy.")),
  ALPHA_AS_ZHANG_B = list(
    value = -0.105, units = "permil/degC",
    status = "data",
    source = paste("Zhang et al. (1995), as ALPHA_AS_ZHANG_A. ABSTRACT gives",
                   "-(0.105 +- 0.002); the CONCLUSIONS section of the same",
                   "paper gives -(0.107 +- 0.002) with a = 0.0144. The two are",
                   "one stated sigma apart and the text prefers neither.")),
  ALPHA_AS_ZHANG_C = list(
    value = 10.53, units = "permil",
    status = "data",
    source = "Zhang et al. (1995), as ALPHA_AS_ZHANG_A; +- 0.05, both printings."),
  # fCO3 IS HELD CONSTANT RATHER THAN SOLVED, and the approximation is priced.
  # Carrying it properly needs [CO3=]/DIC from the carbonate solve at every
  # step, on both the R and C++ paths. Its whole contribution is
  # a*T*fCO3 ~ 0.014 * 17 * 0.082 = 0.020 permil against an eps_DIC-g of ~8.7
  # and a stated uncertainty of +- 0.05, and its contribution to the SLOPE is
  # a*fCO3 = 0.0011 permil/K against 0.105 -- i.e. 1 % of the term this whole
  # change is about. Held, said, and quantified.
  ALPHA_AS_FCO3 = list(
    value = 0.082, units = "1",
    status = "provisional",
    source = paste("Surface [CO3=]/DIC held fixed rather than solved per step.",
                   "Measured at the 25-parameter mode's own surface state",
                   "(NH 0.0856, SH 0.0786; mean 0.082) -- INSIDE Zhang's stated",
                   "0.05-0.20. Contributes 0.020 permil of an ~8.7 permil",
                   "eps_DIC-g and 1 % of its temperature slope.",
                   "RE-MEASURED 2026-10-13 at hilda31w from the model's own",
                   "surface state (calibration/diag_fco3_at_mode.R): 0.0926 in",
                   "2024 (NH 0.0981, SH 0.0871), 0.1190 in 1750; hilda29e",
                   "0.0922 / 0.1186. The 0.0106 shift is worth ~0.0025 permil,",
                   "a twentieth of Zhang's +- 0.05. KEPT at 0.082 (Marcus:",
                   "\"Keep 0.082, record it (Recommended)\").")),
  # THE KINETIC LIMB, linear through the paper's two measured temperatures.
  # ⚠ TWO POINTS ONLY -- this line is an interpolation the paper does not
  # itself draw. ⚠ CORRECTED 2026-10-12 (code review, CHANGELOG 2026-10-12 (s)):
  # this comment used to say the line is "used only inside its own 5-21 degC
  # span". It is NOT -- nothing clamps the SST, and at the canonical it
  # EXTRAPOLATES at both ends: the NH low-latitude SST is above 21 degC in 85 %
  # of months, and every HS-box evaluation sits at 1.6-3.3 degC (measured by the
  # review). The line's slope is (-0.81 - -0.95) / 16 = 0.00875 permil/K, so
  # each degree beyond an end moves eps_k by under 0.01 permil.
  ALPHA_AS_KIN_5 = list(
    value = -0.95, units = "permil",
    status = "data",
    source = paste("Zhang et al. (1995), kinetic fractionation during CO2 gas",
                   "transfer, -0.95 +- 0.20 permil at 5 degC.")),
  ALPHA_AS_KIN_21 = list(
    value = -0.81, units = "permil",
    status = "data",
    source = paste("Zhang et al. (1995), kinetic fractionation during CO2 gas",
                   "transfer, -0.81 +- 0.16 permil at 21 degC.")),
  # THE RETIRED SCALARS, kept so `alpha_as_tdep = 0` reproduces the pre-09-02
  # model BIT FOR BIT and so the value that produced every shipped result is
  # recoverable by name rather than from a git blame.
  ALPHA_AS_DOWN_LEGACY = list(
    value = -2, units = "permil",
    status = "provisional",
    source = paste("The pre-2026-09-02 invasion fractionation, a literal in",
                   "ccx_prepare()'s aux. Measured against Zhang et al. (1995)",
                   "it is 2.4x TOO LARGE (eps_k ~ -0.84 at the model's SST).",
                   "Retained ONLY as the behaviour-preserving path.")),
  ALPHA_AS_UP_LEGACY = list(
    value = -10, units = "permil",
    status = "provisional",
    source = paste("The pre-2026-09-02 evasion fractionation, a literal in",
                   "ccx_prepare()'s aux. Right to 3-5 % against Zhang et al.",
                   "(1995) (-9.50/-9.72 at the model's SST).",
                   "Retained ONLY as the behaviour-preserving path.")),
  # Quay et al. (2003)'s observational constraint, registered because GATE Q
  # scores against it and a gate's target may not be a literal in the gate.
  AIRSEA_D13C_DISEQ_OBS = list(
    value = 0.60, units = "permil",
    status = "data",
    source = paste("Quay P. et al. (2003), Global Biogeochem. Cycles 17(1),",
                   "doi:10.1029/2001GB001817: global mean air-sea d13C",
                   "disequilibrium in 1995, 0.60 +- 0.10 permil. That paper",
                   "takes its own fractionation factors from Zhang et al.",
                   "(1995), so the gate and the constants share a lineage --",
                   "said here because it means this is NOT a fully",
                   "independent check of the coefficients, only of the",
                   "model state they produce.")),
  AIRSEA_D13C_DISEQ_SD = list(
    value = 0.10, units = "permil",
    status = "data", source = "Quay et al. (2003), as AIRSEA_D13C_DISEQ_OBS."),
  AIRSEA_D13C_DISEQ_YEAR = list(
    value = 1995, units = "year",
    status = "data", source = "Quay et al. (2003), as AIRSEA_D13C_DISEQ_OBS."),

  # ---- temperature ----------------------------------------------------
  SST_PCO2_SENSITIVITY = list(
    value = .SST_PCO2_DLNDT, units = "1/degC",
    status = "data",
    source = paste("Takahashi T., Olafsson J., Goddard J.G., Chipman D.W., Sutherland S.C.",
                   "(1993), Global Biogeochem. Cycles 7(4), 843-878, doi:10.1029/93GB02263:",
                   "d ln pCO2 / dT = 0.0423 +- 0.0002 per degC, a laboratory determination on",
                   "North Atlantic surface water at eight temperatures, 2.1-24.5 degC (cited",
                   "2026-09-21 h; was 'provisional -- NEEDS the exact citation'). ⚠ The",
                   "carbonate module already carries the full T dependence of K0/K1/K2 --",
                   "this constant is a CHECK quantity (gate route 1's out-of-sample 0.99x),",
                   "never applied as a factor; check for DOUBLE COUNTING before it ever is.")),

  # ---- the SPO seasonal partition (registered 2026-09-02) -------------
  # WHY THEY ARE HERE. These four are the targets ~13 seasonal diagnostics
  # score against, and until now every one of them re-typed the literal. Same
  # argument as AIRSEA_D13C_DISEQ_OBS: a gate's target may not be a literal in
  # the gate. `calibration/lib_seas_limbs.R` extracted the ESTIMATOR for this
  # arc and said in its header that the four constants were "not this file's to
  # fix silently -- registering them is a constants-registry decision". This is
  # that decision.
  #
  # ⚠ THREE OF THE FOUR ARE PROVISIONAL, AND NOT FOR WANT OF A SOURCE. They are
  # OBSERVATIONS INVERTED THROUGH THE MODEL's own d13C signatures -- exactly the
  # standing that NPP_FRAC_NH_ANCHOR_1750 has, and for the same reason: the
  # ledger is where a model-dependent target stays visible. The inversion solves
  #     CO2 = L + O ; d13 = s_L L + s_O O
  # on the OBSERVED first-harmonic vectors, and only s_L / s_O come from the
  # model (measured from its own channels, -0.04733 vs -0.00461 permil/ppm, a
  # 10.3x separation, with their spreads propagated). The dependence is real and
  # small: re-measuring at a different `tau_ex` moved the land limb 0.683 ->
  # 0.676, i.e. -1 % (notes/collect_2026-08-27h).
  #
  # ⚠ THE THREE INVERTED LIMBS ARE BOOTSTRAP MEDIANS, NOT POINT ESTIMATES, so
  # THEY DO NOT CLOSE ON THE TOTAL AND ARE NOT SUPPOSED TO. The inversion sets
  # O = CO2 - L, so at the POINT estimate the identity holds by construction --
  # but the reported limbs are the medians of 2000 bootstrap draws, and a median
  # does not commute with the nonlinear amp()/ang_mo(). Measured: the two limbs'
  # vector sum at the printed values is 1.181, i.e. 1.1 % above the total, while
  # the printed rounding admits only +-0.002. ⛔ THAT 1.1 % IS NOT A GATE. Do
  # not write a closure test against it -- the only bound available would be the
  # residual itself, which is [[gate_reads_its_own_output]]. Stated so the next
  # reader does not mistake it for a defect and "fix" a limb to make it close.
  # The TOTAL, by contrast, was re-measured model-free on 2026-09-02 and returns
  # 1.1684 -- so it is the total that is solid and the limbs that carry the bar.
  #
  # ⛔ DO NOT SILENTLY RE-MEASURE THESE AT A NEW MODE. Every number the seasonal
  # arc is quoted in -- the 2.01x land excess, the 0.45x ocean deficit, the 5.17
  # month phase gap -- is a ratio against these. Moving them at the same time as
  # the model moves is re-baselining, and the ratio would not show it.
  # ---- THE INDEPENDENT OCEAN-PHASE ROUTE (2026-09-04h) ----------------
  # GATE S's replacement target after the two-signature inversion was retired
  # (see the six *_INV entries below). This route uses NO model output and no
  # d13C signature: a surface-ocean pCO2 climatology gives the phase of the
  # FLUX, and a PHYSICAL LAW converts it to a bound on the atmospheric limb.
  SO_DPCO2_PEAK_MO = list(
    value = 7.4107, units = "month of year (peak of the first harmonic)",
    status = "data",
    source = paste("Peak month of the Southern Ocean (40-90 S) air-sea pCO2",
                   "DIFFERENCE, area-weighted, first harmonic by the magnitude",
                   "of the mean vector. Ocean side: Landschutzer, Laruelle,",
                   "Roobaert & Regnier (2020) ESSD 12:2537, NOAA NCEI accession",
                   "0209633 (doi:10.25921/qb25-f418) -- a monthly pCO2",
                   "CLIMATOLOGY. Atmospheric side: the observed SPO CO2 seasonal",
                   "harmonic. Computed in calibration/diag_gateS_indep_and_fixB.R",
                   "and TIED to that computation by test-gate-bounds.R, which",
                   "recomputes it from the NetCDF when the file is present.",
                   "⭐ NO MODEL IN THE LOOP -- this is the whole point: it",
                   "replaces a target that was an observation inverted through",
                   "the model's own d13C signatures.",
                   "⭐ ROBUST TO THE BAND EDGE: 7.448 / 7.411 / 7.385 / 7.440",
                   "for 35/40/45/50 S, a spread of 0.063 months, far inside the",
                   "lag bound below.",
                   "⚠ pCO2 IS NOT FLUX: F = k*K0*dpCO2, and neither the wind",
                   "seasonality in k nor the temperature seasonality in K0 is in",
                   "this number. Both modulate AMPLITUDE strongly; their effect",
                   "on PHASE is second-order but not zero. That is one reason",
                   "the bound below is an INTERVAL and not a sigma.")),
  SO_DPCO2_LAG_MAX_MO = list(
    value = 12 / 4, units = "months",
    status = "derived",
    source = paste("A QUARTER CYCLE of a 12-month year, and it is a PHYSICAL",
                   "LAW rather than a fitted or chosen number: a first-order",
                   "box forced sinusoidally at omega, dC/dt = F(t) - C/tau,",
                   "lags its forcing by arctan(omega*tau), which is bounded",
                   "above by 90 degrees and reached only in the LOSSLESS limit.",
                   "So an atmospheric concentration limb lags its driving flux",
                   "by BETWEEN 0 AND 3 MONTHS, and the admissible interval for",
                   "the ocean-signatured limb is",
                   "[SO_DPCO2_PEAK_MO, SO_DPCO2_PEAK_MO + this].",
                   "⚠ It is deliberately NOT narrowed by an assumed tau: doing",
                   "so with tau_ex alone lands 1.56 months late, because tau_ex",
                   "is an UPPER BOUND on the box's loss time (sinks drain it",
                   "too) and biases the implied lag LATE. Narrowing it needs the",
                   "model's OWN measured flux-to-atmosphere lag, which would",
                   "reintroduce a model dependence this route exists to avoid.")),
  SPO_SEAS_AMP_OBS = list(
    value = 1.168, units = "ppm CO2, peak-to-peak",
    status = "data",
    source = paste("Observed South Pole seasonal CO2 cycle, FIRST HARMONIC,",
                   "peak-to-peak = 2*sqrt(a^2+b^2) of the mean vector, 1975-2024,",
                   "measured in calibration/diag_seas_signature_inversion.R",
                   "(2026-08-27d). NO MODEL IN THE LOOP -- the inversion's",
                   "CO2 = L + O closes on the observed total, so this one is",
                   "data where the three limbs below are not.",
                   "⚠ THE AMPLITUDE DEFINITION IS A FLAGGED, UNRESOLVED CHOICE",
                   "([[amp_definition_mismatch]]): magnitude-of-mean-vector,",
                   "NOT mean-of-per-year-magnitudes, which inflates a noisy",
                   "series by Jensen. Quote nothing against this constant that",
                   "was measured the other way.")),
  SPO_SEAS_AMP_LAND_INV = list(
    value = 0.683, units = "ppm CO2, peak-to-peak",
    status = "retired",
    source = paste("⛔ RETIRED 2026-09-04h. The two-signature inversion that produced this number CANNOT BE RUN at the canonical mode: the 2026-09-02 temperature-dependent air-sea 13C alphas make the ocean limb's isotopic signature ROTATE seasonally, so it is no longer the signed SCALAR the method assumes, and all four ocean channels now fail the inversion's own antiphase gate (s_O = NaN). Setting alpha_as_tdep=0 restores it and reproduces this value exactly, so the cause is isolated -- but that reverts a model improvement. PROVENANCE ONLY: do not use as a live target. Gate S was rebased on the independent pCO2 route (SO_DPCO2_PEAK_MO). ",
                   "The LAND-signatured part of SPO_SEAS_AMP_OBS, from the d13C",
                   "signature inversion at the canonical mode",
                   "(calibration/diag_seas_signature_inversion.R, 2026-08-27d;",
                   "collect note the same day). Observed peak month 9.29.",
                   "PROVISIONAL because it is an observation inverted through",
                   "the model's own signatures -- see the section header --",
                   "not because it lacks a source.")),
  SPO_SEAS_AMP_OCEAN_INV = list(
    value = 0.522, units = "ppm CO2, peak-to-peak",
    status = "retired",
    source = paste("⛔ RETIRED 2026-09-04h. The two-signature inversion that produced this number CANNOT BE RUN at the canonical mode: the 2026-09-02 temperature-dependent air-sea 13C alphas make the ocean limb's isotopic signature ROTATE seasonally, so it is no longer the signed SCALAR the method assumes, and all four ocean channels now fail the inversion's own antiphase gate (s_O = NaN). Setting alpha_as_tdep=0 restores it and reproduces this value exactly, so the cause is isolated -- but that reverts a model improvement. PROVENANCE ONLY: do not use as a live target. Gate S was rebased on the independent pCO2 route (SO_DPCO2_PEAK_MO). ",
                   "The OCEAN-signatured part of SPO_SEAS_AMP_OBS, same",
                   "inversion and same provisional standing as",
                   "SPO_SEAS_AMP_LAND_INV. Land 0.683 at month 9.29 plus ocean",
                   "0.522 at month 8.52 are 0.77 months apart and sum to 103 %",
                   "of the total: nature ADDS two nearly in-phase pieces where",
                   "the model SUBTRACTS two nearly antiphase ones.")),
  SPO_SEAS_LAND_PHASE_INV = list(
    value = 9.29, units = "month of year (peak of the first harmonic)",
    status = "retired",
    source = paste("⛔ RETIRED 2026-09-04h. The two-signature inversion that produced this number CANNOT BE RUN at the canonical mode: the 2026-09-02 temperature-dependent air-sea 13C alphas make the ocean limb's isotopic signature ROTATE seasonally, so it is no longer the signed SCALAR the method assumes, and all four ocean channels now fail the inversion's own antiphase gate (s_O = NaN). Setting alpha_as_tdep=0 restores it and reproduces this value exactly, so the cause is isolated -- but that reverts a model improvement. PROVENANCE ONLY: do not use as a live target. Gate S was rebased on the independent pCO2 route (SO_DPCO2_PEAK_MO). ",
                   "Peak month of the land-signatured SPO component, same",
                   "inversion and same standing as SPO_SEAS_AMP_LAND_INV.",
                   "The model puts this limb at 8.82 -- a 0.47 month miss,",
                   "against the ocean limb's 5.17.")),
  SPO_SEAS_OCEAN_PHASE_INV = list(
    value = 8.52, units = "month of year (peak of the first harmonic)",
    status = "retired",
    source = paste("⛔ RETIRED 2026-09-04h. The two-signature inversion that produced this number CANNOT BE RUN at the canonical mode: the 2026-09-02 temperature-dependent air-sea 13C alphas make the ocean limb's isotopic signature ROTATE seasonally, so it is no longer the signed SCALAR the method assumes, and all four ocean channels now fail the inversion's own antiphase gate (s_O = NaN). Setting alpha_as_tdep=0 restores it and reproduces this value exactly, so the cause is isolated -- but that reverts a model improvement. PROVENANCE ONLY: do not use as a live target. Gate S was rebased on the independent pCO2 route (SO_DPCO2_PEAK_MO). ",
                   "Peak month of the ocean-signatured SPO component, same",
                   "inversion, 95 % CI [7.82, 9.20] bootstrapped over YEARS",
                   "crossed with the signature spreads, 2000 draws, seed",
                   "20260827; angles averaged as VECTORS. The model's only SH",
                   "air-sea seasonal channel peaks at 3.35 -- a 5.17 month gap.",
                   "⚠ IT HAS NO INDEPENDENT OBSERVATIONAL CONFIRMATION YET:",
                   "the phase comes from ATMOSPHERIC station data, and the",
                   "surface-ocean pCO2 climatology pulled to check it from the",
                   "ocean side (data-raw/download_data.R sec.6c) is a pCO2",
                   "product, so it omits the seasonality of gas transfer and",
                   "K0. Until that closes the phase gap is a hypothesis.")),
  SPO_SEAS_OCEAN_PHASE_INV_LO = list(
    value = 7.82, units = "month of year",
    status = "retired",
    source = paste("Lower 95 % bootstrap bound of SPO_SEAS_OCEAN_PHASE_INV,",
                   "as that entry -- and RETIRED 2026-09-04h with it, for the",
                   "same reason: the two-signature inversion that produced this",
                   "bootstrap cannot be run at the canonical mode. PROVENANCE",
                   "ONLY. Gate S was rebased on SO_DPCO2_PEAK_MO.")),
  SPO_SEAS_OCEAN_PHASE_INV_HI = list(
    value = 9.20, units = "month of year",
    status = "retired",
    source = paste("Upper 95 % bootstrap bound of SPO_SEAS_OCEAN_PHASE_INV,",
                   "as that entry -- and RETIRED 2026-09-04h with it, for the",
                   "same reason: the two-signature inversion that produced this",
                   "bootstrap cannot be run at the canonical mode. PROVENANCE",
                   "ONLY. Gate S was rebased on SO_DPCO2_PEAK_MO.")),

  # ---- Southern-Ocean entrainment amplitude (2026-09-03) --------------
  # REGISTERED BECAUSE IT BECAME A PRIOR CENTRE. `ent_seas_amp_SH` entered
  # CCX_PARAM_TABLE on 2026-09-03 (25 -> 26 parameters), and its prior is
  # centred here. Until then the derivation lived only in a comment beside
  # ccx_default_params(), which is exactly the free-floating-number class the
  # registry exists to close: a prior centre that is not a named constant
  # cannot be tied to its own arithmetic by a test.
  ENT_SEAS_BAND_AREA_FRAC = list(
    value = .ENT_BAND_AREA_FR, units = "fraction, dimensionless",
    status = "provisional",
    source = paste("LIVE GEOGRAPHIC RATIO: the ocean area of the 40-90 S band",
                   "as a fraction of TOTAL SH ocean area, from the 2026-08-27g",
                   "entrainment pre-check's own area weighting. It multiplies",
                   "ENT_SEAS_AMP_SH_INBAND to give the prior centre",
                   "ENT_SEAS_AMP_SH_DERIV, and 1/it is the no-dilution limit",
                   "(every SH ocean square metre behaving like the observed",
                   "band) that sets the PRIOR WIDTH ENT_SEAS_LOGSD in",
                   "R/calibrate.R. ⚠ PROVISIONAL: a GEOGRAPHIC area ratio that",
                   "NEEDS a cited source, exactly as OCEAN_AREA_NH/SH do. It",
                   "was a free-floating literal in three files until",
                   "2026-09-03; registering it is what makes the two entries",
                   "below computable rather than typed. (The 'RETIRED",
                   "2026-09-04h two-signature inversion' boilerplate that was",
                   "pasted into this entry twice belonged to the",
                   "SPO_SEAS_OCEAN_PHASE_INV entries above and was removed",
                   "2026-09-12; nothing about this constant is retired.)")),
  ENT_SEAS_AMP_SH_INBAND = list(
    value = (.ENT_SO_SST_AMP * .ENT_PCO2_DLNDT * .ENT_PCO2_REF + .ENT_SO_PCO2_AMP) /
            .ENT_PCO2_REF * .ENT_DIC_SURF / .ENT_REVELLE,
    units = "umol/kg, half-amplitude, WITHIN the 40-90 S band",
    status = "derived",
    source = paste("COMPUTED from the named inputs at the head of this file, not",
                   "typed: (.ENT_SO_SST_AMP x .ENT_PCO2_DLNDT x .ENT_PCO2_REF",
                   "+ .ENT_SO_PCO2_AMP) / .ENT_PCO2_REF x .ENT_DIC_SURF /",
                   ".ENT_REVELLE. The Southern Ocean's own solubility cycle",
                   "(the first product, in uatm) has to be OVERCOME before the",
                   "observed pCO2 amplitude (.ENT_SO_PCO2_AMP) is left, and the",
                   "two are close to antiphase -- the band SST and band pCO2",
                   "peak about half a year apart (the `band_peak_month` fields",
                   "of obs_so_sst_seas_amp.rds and obs_so_pco2_seas_amp.rds,",
                   "the products the two inputs are read from) -- so",
                   "entrainment carries their SUM in band; the buffer factor",
                   "then converts uatm to umol/kg of DIC.",
                   "⛔ NO VALUE IS TYPED HERE (2026-09-12, review C): the prose",
                   "used to walk the arithmetic with numbers whose inputs moved",
                   "on 2026-09-09w, and had drifted. Print",
                   "ccx_const('ENT_SEAS_AMP_SH_INBAND') for the live value;",
                   "tests/testthat/test-ent-seas-fitted.R re-derives it from",
                   "the same inputs.",
                   "⚠ This is the IN-BAND value and NOT the parameter -- see",
                   "ENT_SEAS_AMP_SH_DERIV, which dilutes it onto the SH box.",
                   "⚠ The near-antiphase geometry is what licenses ADDING the",
                   "two amplitudes; at a smaller phase separation the sum would",
                   "overstate the entrainment term.")),
  ENT_SEAS_AMP_SH_DERIV = list(
    value = (.ENT_SO_SST_AMP * .ENT_PCO2_DLNDT * .ENT_PCO2_REF + .ENT_SO_PCO2_AMP) /
            .ENT_PCO2_REF * .ENT_DIC_SURF / .ENT_REVELLE * .ENT_BAND_AREA_FR,
    units = "umol/kg, half-amplitude, SH BOX MEAN",
    status = "derived",
    source = paste("ENT_SEAS_AMP_SH_INBAND times ENT_SEAS_BAND_AREA_FRAC --",
                   "COMPUTED from the same named inputs, never re-typed from",
                   "the in-band number. `ent_seas_amp_SH` perturbs the WHOLE SH",
                   "mixed layer, so the band value must be diluted onto the box",
                   "before it can be a prior centre. Print",
                   "ccx_const('ENT_SEAS_AMP_SH_DERIV') for the live value: the",
                   "`init` literal of ent_seas_amp_SH in R/calibrate.R must",
                   "equal it and test-ent-seas-fitted.R ties the two (the",
                   "typed value that stood here was the pre-2026-09-09w one).",
                   "⚠ It INHERITS a provisional input (the area fraction) and",
                   "the pCO2 product's own caveat: that product omits the",
                   "seasonality of gas transfer and K0.",
                   "⚠ The recorded plausibility band 'far outside ~5-30 is a",
                   "fudge factor' MIXES the two scales -- its upper end is the",
                   "IN-BAND scale, the box mean is ENT_SEAS_BAND_AREA_FRAC of",
                   "it -- which is why both are registered",
                   "separately and why the prior width is NOT read off that",
                   "band's unsourced lower endpoint.")),
  # ---- Remineralisation N:C for the alkalinity row (registered 2026-09-12) --
  # Was a typed `16 / 117` in R/likelihood.R described as "an
  # Anderson-Sarmiento-type recollection rather than a citation" (review C);
  # the citation was checked against the published abstract on 2026-09-12 and
  # the value moved here. R/likelihood.R reads it as LIK_ALK_NC_RATIO.
  ALK_NC_RATIO = list(
    value = 16 / 117, units = "mol N per mol C, organic-matter remineralisation",
    status = "cited",
    source = paste("Anderson, L. A. & Sarmiento, J. L. (1994), Redfield ratios",
                   "of remineralization determined by nutrient data analysis,",
                   "Global Biogeochemical Cycles 8(1), 65-80,",
                   "doi:10.1029/93GB03318. Abstract: P : N : C_org : -O2 =",
                   "1 : 16 +/- 1 : 117 +/- 14 : 170 +/- 10 between 400 and",
                   "4000 m, approximately constant with depth and basin",
                   "(denitrification-corrected). Used ONLY by the alkalinity",
                   "gradient row: soft-tissue remineralisation removes ~1 mol",
                   "alkalinity per mol N released, so N:C converts the organic",
                   "export to its alkalinity debit.")),
  # ---- Schmidt number of CO2 in seawater (2026-09-06, for hs_asx_frac) ----
  # Sc(t) = A + B t + C t^2 + D t^3 + E t^4, t in degC, salinity 35, as FIVE
  # scalar entries (the registry's contract is one finite number per entry;
  # test-constants.R). Used ONLY by data-raw/build_hs_exchange_factor.R to price
  # the cold box's gas exchange relative to the warm box's (k ~ Sc^-1/2,
  # Wanninkhof 2014 eq. 4). The model itself has NO Schmidt dependence: `k_w`
  # is one fitted piston velocity per unit area, which is exactly why the
  # HS/LL ratio needs this factor. Check: Sc(20 C) = 668.
  # ⚠ Sourced at one remove: the Wiley full text was unreachable (403) on
  # 2026-09-06; the coefficients were read from pySeaFlux
  # (github.com/lukegre/pySeaFlux, gas_transfer_velocity.py), which reproduces
  # Wanninkhof (2014) Table 1 and cites it. Verify against the paper when a PDF
  # is available; the values agree with the author's recollection of Table 1.
  SC_CO2_W14_A = list(
    value = 2116.8, units = "dimensionless per degC^0 (Sc polynomial term)",
    status = "cited",
    source = paste("Wanninkhof R. (2014), Limnol. Oceanogr. Methods 12, 351-362,",
                   "doi:10.4319/lom.2014.12.351, Table 1 (CO2, seawater), as reproduced",
                   "in pySeaFlux gas_transfer_velocity.py (accessed 2026-09-06).")),
  SC_CO2_W14_B = list(
    value = -136.25, units = "dimensionless per degC^-1 (Sc polynomial term)",
    status = "cited",
    source = paste("Wanninkhof R. (2014), Limnol. Oceanogr. Methods 12, 351-362,",
                   "doi:10.4319/lom.2014.12.351, Table 1 (CO2, seawater), as reproduced",
                   "in pySeaFlux gas_transfer_velocity.py (accessed 2026-09-06).")),
  SC_CO2_W14_C = list(
    value = 4.7353, units = "dimensionless per degC^-2 (Sc polynomial term)",
    status = "cited",
    source = paste("Wanninkhof R. (2014), Limnol. Oceanogr. Methods 12, 351-362,",
                   "doi:10.4319/lom.2014.12.351, Table 1 (CO2, seawater), as reproduced",
                   "in pySeaFlux gas_transfer_velocity.py (accessed 2026-09-06).")),
  SC_CO2_W14_D = list(
    value = -0.092307, units = "dimensionless per degC^-3 (Sc polynomial term)",
    status = "cited",
    source = paste("Wanninkhof R. (2014), Limnol. Oceanogr. Methods 12, 351-362,",
                   "doi:10.4319/lom.2014.12.351, Table 1 (CO2, seawater), as reproduced",
                   "in pySeaFlux gas_transfer_velocity.py (accessed 2026-09-06).")),
  SC_CO2_W14_E = list(
    value = 0.0007555, units = "dimensionless per degC^-4 (Sc polynomial term)",
    status = "cited",
    source = paste("Wanninkhof R. (2014), Limnol. Oceanogr. Methods 12, 351-362,",
                   "doi:10.4319/lom.2014.12.351, Table 1 (CO2, seawater), as reproduced",
                   "in pySeaFlux gas_transfer_velocity.py (accessed 2026-09-06).")),

  # ---- THE CITED VALUES OF LABEL hilda_csl3v0kaidgbemwtc (2026-10-12) ----------------------
  # notes/citation_rulings_2026-10-12.md; routed by label ("New label (a) (Recommended)"), so each
  # LEGACY entry above (ALK_SURFACE, OCEAN_DEPTH, ALPHA_PHOTO_EPS, PUMP_EPS13_ORG) stays as the
  # ABSENT-FIELD DEFAULT every registered mode runs, and the label's structure block reads these.
  # The data-derived ones are tied to their products by tests/testthat/test-wtc-label.R.
  ALK_SURFACE_GLODAP = list(
    value = 2303.4e-6, units = "mol/kg",
    status = "data",
    source = paste("GLODAPv2.2023 (Lauvset et al. 2024, ESSD 16:2047-2072) 0-100 m, flag 2, 5x10x250 cells,",
                   "cos-lat weighted, all latitudes: 2303.38 umol/kg (829 cells), ruled at 2303.4",
                   "(citation rulings row 3, 'Adopt 2303.4 (Recommended)').",
                   "data/obs_glodap_surface_alk_sal.rds, data-raw/build_glodap_surface_alk_sal.R.")),
  SALINITY_SURFACE_GLODAP = list(
    value = 34.760, units = "PSS-78",
    status = "data",
    source = paste("GLODAPv2.2023 0-100 m, ALK's recipe and domain: 34.7602 (913 cells); the LS-only",
                   "(|lat| < 57.14) 35.005 reported, not adopted (row 30, 'Compute from GLODAP, adopt').",
                   "The carbonate table data/carbonate_coefs_s34760.rds is built at it. RHO_SEAWATER",
                   "(S 35) checked: TEOS-10 density at S 34.76 is 0.18-0.19 kg/m3 lower (0.018 %).")),
  OCEAN_DEPTH_CS2010 = list(
    value = 3682.2, units = "m",
    status = "cited",
    source = paste("Charette M.A. & Smith W.H.F. (2010), The volume of Earth's ocean, Oceanography",
                   "23(2):112-114, Table 2 p. 114: mean depth 3682.2 m (+/-1.2 %, 1 sigma), volume /",
                   "area from SRTM30_PLUS V5. Row 5, 'Adopt 3682.2 (Recommended)'.")),
  ALPHA_PHOTO_EPS_STILL2003 = list(
    value = 16.2, units = "permil",
    status = "cited",
    source = paste("Still, Berry, Collatz & DeFries (2003) GBC 17(1):1006, doi:10.1029/2001GB001807,",
                   "abstract: assimilation-weighted terrestrial discrimination Delta = 16.5 permil at C4",
                   "= 23 % of GPP (verified via EarthRef ERR 74609). In CCX's alpha = 1 - eps/1000 form",
                   "eps = Delta/(1 + Delta/1000) = 16.23 -> 16.2 (row 11-12, 'Adopt 16.2 = Still's 16.5').",
                   "LIMITATION: the CO2-fertilised net sink is C3-dominated; one eps serves gross and net.")),
  PUMP_EPS13_ORG_CLARET2021 = list(
    value = -22, units = "permil",
    status = "cited",
    source = paste("Claret, Sonnerup & Quay (2021) GBC 35:e2020GB006757, sec. 3.2.1: deep-Pacific",
                   "d13C-PO4 slope -1.01 +/- 0.02 permil per umol/kg; at C:P 117 remineralised OM is",
                   "-20.07 permil vs DEEP DIC (checked against the PDF), ~-22.0 vs SURFACE DIC, the",
                   "reference this model's export uses. Corroborated by export-weighted eps_p fits",
                   "(-20.7 to -23.4) and isotope models (-21.5 to -23.1). Row 1, 'Adopt -22, one",
                   "constant'. LIMITATIONS: high-latitude export is more negative (-25 to -28);",
                   "eps_p has risen since the 1960s.")),
  BOMB_NH_SHARE_PRIOR_LO = list(
    value = 0.77, units = "fraction",
    status = "cited",
    source = paste("UNSCEAR 2000 Report Vol. I, Annex C, Table 7 pp. 210-211: measured 90Sr",
                   "hemispheric deposition, NH 470 / SH 142 PBq -> 0.768, the closest analogue of",
                   "stratosphere -> troposphere delivery (fission-weighted, particulate). Lower bound",
                   "of the FITTED bomb share's uniform prior (row 19, 'Fit it, prior U[0.77, 0.98]').")),
  BOMB_NH_SHARE_PRIOR_HI = list(
    value = 0.98, units = "fraction",
    status = "cited",
    source = paste("UNSCEAR 2000 Annex C, Table 2 p. 205: fusion yield by test site, NH 0.982 with",
                   "sites assigned by latitude (0.953 with Christmas Island split, 0.932 with",
                   "Johnston too). Upper bound of the fitted bomb share's uniform prior (row 19).")),
  P_CANON_KOVALTSOV2012 = list(
    value = 1.88, units = "atoms cm-2 s-1",
    status = "cited",
    source = paste("Kovaltsov, Mishev & Usoskin (2012) EPSL 337-338:114-120, 1750-1900 mean global",
                   "cosmogenic 14C production (arXiv v1 p. 5 lines 126-128). Roth & Joos (2013) Clim.",
                   "Past 9:1879 p. 1894 give 1.75 from the carbon-cycle budget. DIAGNOSTIC ONLY",
                   "(ccx_spinup_diagnostics()'s comparison value; never an input). Rows 21-22.")),
  EARTH_AREA_GRS80 = list(
    value = 5.10066e14, units = "m2",
    status = "cited",
    source = paste("Moritz (2000) Geodetic Reference System 1980, J. Geodesy 74:128-133, sec. 4 p. 131:",
                   "R2 = 6 371 007.1810 m (the equal-area sphere), area 4 pi R2^2. Rows 21-22.")),
  SEC_PER_YR = list(
    value = .SEC_PER_YR, units = "s/yr",
    status = "derived",
    source = "Julian year, 365.25 x 86400 s -- derives from .SEC_PER_YR, never re-typed"),
  AVOGADRO = list(
    value = .AVOGADRO, units = "1/mol",
    status = "cited",
    source = "CODATA 2018 / SI 2019: exact by definition -- derives from .AVOGADRO, never re-typed")
)

#' Fetch a constant's value, erroring on unknown names
ccx_const <- function(name) {
  if (!name %in% names(CCX_CONSTANTS)) {
    stop("Unknown constant '", name, "'. Known: ", paste(names(CCX_CONSTANTS), collapse = ", "))
  }
  CCX_CONSTANTS[[name]]$value
}

#' List constants that are still provisional
#' @param quiet if TRUE, return the names invisibly without printing
ccx_check_constants <- function(quiet = FALSE) {
  prov <- names(Filter(function(x) identical(x$status, "provisional"), CCX_CONSTANTS))
  if (!quiet) {
    if (length(prov) == 0) {
      cat("All constants are derived, cited, or data-sourced.\n")
    } else {
      cat(sprintf("%d PROVISIONAL constants (not yet traced to a source):\n", length(prov)))
      for (p in prov) cat(sprintf("  %-24s %s\n", p, CCX_CONSTANTS[[p]]$units))
      cat("These must not survive into published results.\n")
    }
  }
  invisible(prov)
}

# Reference bomb-14C total and the four land-use forcing columns. Both were
# repeated as literals in ccx_make_logpost() and in a dozen diagnostics; named
# here so ccx_scaled_forcing() and its callers cannot drift apart (promoted
# 2026-08-22 with the luc_scale double-scaling fix).
CCX_BOMB_REF <- 102
CCX_LUC_COLS <- c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")

# ⭐ HOW ANNUAL EMISSIONS ARE SPREAD ACROSS THE MONTHS OF THEIR YEAR.
# "constant" is piecewise-constant within the year: exactly conserving,
# shape-preserving, and CAUSAL -- a one-year pulse cannot ring backwards into
# the years before it. "spline" (a natural spline, a GLOBAL interpolant) rang
# 3.06 ppm into the 26 years before a 100 GtC pulse ([[ccx_pulse_spline_ringing]]).
# ⭐⭐ FLIPPED "spline" -> "constant" 2026-10-01 (Marcus, review 10-01c B6: "I
# think apply it now: I don't expect another refit anytime soon"). Ruled 09-24
# ("option 1", branch `emissions-interp-constant`, 35f38dc) to ride with the
# next refit; it missed the #14 refit and is applied WITHOUT one. The ledger is
# paid by RESTAMPING every registered mode at its PRICED likelihood move
# (calibration/diag_emis_constant_price.R, outputs/diagnostics/
# emis_constant_price_20261001.*: hilda33d -0.1624, hilda29l -0.1367, hilda32f
# -0.1567, hilda31s2 -0.0180, hilda31pe -0.1789; the 09-24 measurement at
# hilda29l was -0.137). Every file keeps its pre-flip streams and logpost in
# `objective_history`. ⚠ It moves the objective's fossil + LUC interpolation
# AND ccx_run_coupled()'s default for both emissions and the GMST feedback, i.e.
# every futures run that does not name a method. The app's pulse lab already
# used "constant" (APP_PULSE_EMIS_METHOD) and is unchanged.
CCX_EMIS_METHOD_DEFAULT <- "constant"
