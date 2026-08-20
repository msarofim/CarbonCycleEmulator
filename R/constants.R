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
# ccx_check_constants() lists anything still provisional. Calibration and
# headline runs are gated on that list being empty for the constants they use.
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
    status = "provisional",
    source = "Working value: NH ocean area. NEEDS a cited geographic source."),

  OCEAN_AREA_SH = list(
    value = 2.06e14, units = "m2",
    status = "provisional",
    source = "Working value: SH ocean area (SH is ocean-dominated). NEEDS a cited source."),

  OCEAN_DEPTH = list(
    value = 3700, units = "m",
    status = "provisional",
    source = "Working value: mean ocean depth. NEEDS a cited source."),

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
    status = "provisional", source = "Working value for surface seawater density."),

  # ---- land -----------------------------------------------------------
  NPP_GLOBAL_PI = list(
    value = 60, units = "GtC/yr",
    status = "provisional",
    source = "Working value: preindustrial global NPP. NEEDS a cited source."),

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

  # ---- temperature ----------------------------------------------------
  SST_PCO2_SENSITIVITY = list(
    value = 0.0423, units = "1/degC",
    status = "provisional",
    source = paste("d ln pCO2 / dT ~ 4.23 %/degC (Takahashi). NEEDS the exact citation;",
                   "note the carbonate module already carries the full T dependence of",
                   "K0/K1/K2, so check for DOUBLE COUNTING before applying this factor."))
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
