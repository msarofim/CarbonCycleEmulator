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
.SST_PCO2_DLNDT <- 0.0423          # 1/degC, d ln pCO2 / dT (Takahashi). Hoisted
                                   # 2026-09-03: SST_PCO2_SENSITIVITY and the
                                   # entrainment chain below BOTH need it, and
                                   # the entrainment chain had re-typed it --
                                   # the very duplication the audit was for.

# ---- inputs to the Southern-Ocean entrainment amplitude (2026-09-03) --
# ⛔ NAMED HERE AND COMPUTED BELOW, NOT TYPED AS AN ANSWER. The entry that
# replaced them carried `value = 30` with the arithmetic only in its prose
# `source`, i.e. it was labelled "derived" while being an independent copy --
# THE EXACT LAMBDA_C14 BUG this file's header warns about. Computing it moved
# the number 30 -> 29.68, which is the drift a typed "derived" value hides.
.ENT_SO_SST_AMP   <- 3.0      # K, seasonal SST half-amplitude of the 40-90 S
                              # BAND (ERSSTv5). ⚠ NOT SST_SEAS_AMP_SH_OBS
                              # (1.746 K), which is the SH HEMISPHERIC MEAN and
                              # a different quantity -- the band is colder and
                              # swings harder than the hemisphere containing it.
                              # Named apart so the two are never conflated.
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
.ENT_SO_PCO2_AMP  <- 19.45    # uatm, OBSERVED 40-90 S pCO2 seasonal amplitude
                              # (Landschutzer/Laruelle NCEI 0209633), the same
                              # product CCX_ENT_SEAS_PEAK_MO's 7.50 comes from
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
                   "eps_DIC-g and 1 % of its temperature slope.")),
  # THE KINETIC LIMB, linear through the paper's two measured temperatures.
  # ⚠ TWO POINTS ONLY -- this line is an interpolation the paper does not
  # itself draw, and it is used only inside its own 5-21 degC span.
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
    status = "provisional",
    source = paste("d ln pCO2 / dT ~ 4.23 %/degC (Takahashi). NEEDS the exact citation;",
                   "note the carbonate module already carries the full T dependence of",
                   "K0/K1/K2, so check for DOUBLE COUNTING before applying this factor.")),

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
    source = paste("⛔ RETIRED 2026-09-04h. The two-signature inversion that produced this number CANNOT BE RUN at the canonical mode: the 2026-09-02 temperature-dependent air-sea 13C alphas make the ocean limb's isotopic signature ROTATE seasonally, so it is no longer the signed SCALAR the method assumes, and all four ocean channels now fail the inversion's own antiphase gate (s_O = NaN). Setting alpha_as_tdep=0 restores it and reproduces this value exactly, so the cause is isolated -- but that reverts a model improvement. PROVENANCE ONLY: do not use as a live target. Gate S was rebased on the independent pCO2 route (SO_DPCO2_PEAK_MO). ",
                   "⛔ RETIRED 2026-09-04h. The two-signature inversion that produced this number CANNOT BE RUN at the canonical mode: the 2026-09-02 temperature-dependent air-sea 13C alphas make the ocean limb's isotopic signature ROTATE seasonally, so it is no longer the signed SCALAR the method assumes, and all four ocean channels now fail the inversion's own antiphase gate (s_O = NaN). Setting alpha_as_tdep=0 restores it and reproduces this value exactly, so the cause is isolated -- but that reverts a model improvement. PROVENANCE ONLY: do not use as a live target. Gate S was rebased on the independent pCO2 route (SO_DPCO2_PEAK_MO). ",
                   "Ocean area of the 40-90 S band as a fraction of TOTAL SH",
                   "ocean area, from the 2026-08-27g entrainment pre-check's",
                   "own area weighting. ⚠ PROVISIONAL: it is a GEOGRAPHIC area",
                   "ratio and NEEDS a cited source, exactly as OCEAN_AREA_NH/SH",
                   "do. It was a free-floating literal in three files until",
                   "2026-09-03; registering it is what makes the two entries",
                   "below computable rather than typed.",
                   "⭐ It also sets the PRIOR WIDTH: 1/this is the no-dilution",
                   "limit, i.e. every SH ocean square metre behaving like the",
                   "observed band. See ENT_SEAS_LOGSD in R/calibrate.R.")),
  ENT_SEAS_AMP_SH_INBAND = list(
    value = (.ENT_SO_SST_AMP * .ENT_PCO2_DLNDT * .ENT_PCO2_REF + .ENT_SO_PCO2_AMP) /
            .ENT_PCO2_REF * .ENT_DIC_SURF / .ENT_REVELLE,
    units = "umol/kg, half-amplitude, WITHIN the 40-90 S band",
    status = "derived",
    source = paste("COMPUTED from the named inputs at the head of this file, not",
                   "typed. The Southern Ocean's own solubility cycle has to be",
                   "OVERCOME before the observed signal is left, and the two are",
                   "close to antiphase: solubility =",
                   ".ENT_SO_SST_AMP x .ENT_PCO2_DLNDT x .ENT_PCO2_REF = 46.95",
                   "uatm at month 1.94, against an OBSERVED 19.45 uatm at month",
                   "7.50, so entrainment carries 66.40 uatm in band. Through the",
                   "buffer factor that is dDIC = (66.40/370) x 2150 / 13 =",
                   "29.68 umol/kg.",
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
                   "before it can be a prior centre. Gives 10.95 umol/kg.",
                   "⚠ It INHERITS a provisional input (the area fraction) and",
                   "the pCO2 product's own caveat: that product omits the",
                   "seasonality of gas transfer and K0.",
                   "⚠ The recorded plausibility band 'far outside ~5-30 is a",
                   "fudge factor' MIXES the two scales -- 30 is the in-band",
                   "value, ~11 the box mean -- which is why both are registered",
                   "separately and why the prior width is NOT read off that",
                   "band's unsourced lower endpoint."))
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
