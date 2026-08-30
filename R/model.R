# =====================================================================
# model.R — two-hemisphere, monthly, 12C/13C/14C box carbon cycle model
#
# BOXES, per hemisphere h in {NH, SH}:
#   atm                              1  well-mixed troposphere
#   leaf, wood, soil_fast, soil_slow 4  land pools (see LAND STRUCTURE below)
#   ml + interior                   11  ocean column: mixed layer + NL layers
# = 16 boxes/hemisphere x 2 = 32; x 3 tracers = 96 states.
#
# LAND STRUCTURE. Four pools, not two, because two CANNOT hold the observed
# carbon stock and the observed bomb-14C inventory at the same time. Naegler &
# Levin (2006) Table 4 put 21.7 kmol of bomb 14C in a 2200 PgC biosphere at
# 1975; a single vegetation pool of 600 GtC turning over in 10 yr holds ~20 kmol
# by itself, so no soil layout underneath it can help, and re-tuning tau_soil
# alone trades pool size against inventory without ever meeting both
# (diag_land_structure.R [4], diag_land_topology.R [2], 2026-08-12).
#
#   atm --NPP--> leaf (tau ~1 yr)  --.
#            \-> wood (tau ~20 yr) --+--litter--> soil_fast (tau ~2 yr)  --Rh--> atm
#                                    \                soil_slow (tau ~500 yr) --Rh-> atm
#
# Fast pools cycle the bomb 14C straight back; the large passive soil pool holds
# carbon while barely seeing the bomb. That separation is the whole point of the
# structure -- collapsing any pair of pools reinstates the defect.
#
# TRACERS. All three are carried as MASSES so the budget is linear:
#   C    total carbon, GtC
#   C13  13C mass expressed as C * R13            (R13 ~ 0.0112)
#   C14  14C expressed as C * (R14 / R14_STD)     -- i.e. "GtC carrying standard
#        14C content", so Delta14C = 1000 * (C14/C - 1) directly, and values stay
#        O(1-1000) instead of O(1e-12). Only C14 decays.
#
# FRACTIONATION. 13C fluxes carry a fractionation factor. 14C fluxes DO NOT:
# Delta14C is fractionation-corrected by convention (Stuiver & Polach 1977), and
# C14/C is exactly that corrected ratio, so transporting it unfractionated is
# correct. This is the standard trick and is easy to "fix" into a bug.
#
# CONSERVATION BY CONSTRUCTION. Every internal transfer is emitted once as a
# flux and applied with opposite sign to its two boxes (see `add_flux`). The
# total therefore has zero derivative at EVERY RK stage, so mass is conserved to
# floating-point roundoff regardless of step size -- conservation is a property
# of the formulation, not of integrator accuracy. Do not rewrite the derivative
# to update boxes independently.
# =====================================================================

N_INTERIOR <- 10L      # ocean interior layers below the mixed layer
HEMIS      <- c("NH", "SH")

# Extra `out` columns carrying the mixed-layer and bottom-box C and 13C per
# hemisphere, in STATE units (GtC). Added 2026-08-16 for the ocean DIC / d13C
# GRADIENT terms, which are scored at the OBSERVATIONS' epoch and so need a time
# series, not the final state. ORDER IS LOAD-BEARING: ccx_run_fast() names the
# C++ matrix positionally from this vector, and src/ccx_core.cpp emits
# (ml_C, ml_C13, deep_C, deep_C13) for NH then SH. test-parity.R gates it.
CCX_OCEAN_BOX_COLS <- unlist(lapply(HEMIS, function(h)
  paste0(c("ml_C_", "ml_C13_", "deep_C_", "deep_C13_"), h)))

# 1 Sv = 1e6 m3/s. The conveyor is parameterised by VOLUME flux because the two
# hemispheres have different ocean areas -- see ccx_default_params()$q_conv.
CCX_SV_TO_M3YR <- 1e6 * 365.25 * 86400

# ---------------------------------------------------------------------
#' Resolve the conveyor geometry from the parameters, or NULL if it is off.
#'
#' ONE function so that ccx_deriv(), ccx_advection_eigbound() and the C++ core
#' cannot disagree about which layer sinks, which way round the cell runs, or
#' how fast each hemisphere's limb moves. `q_conv` <= 0 (or absent, for a
#' parameter list built before 2026-08-13) returns NULL and nothing is emitted.
ccx_conveyor_geom <- function(p, grid) {
  q <- if (is.null(p$q_conv)) 0 else p$q_conv
  if (!isTRUE(q > 0)) return(NULL)
  s <- if (is.null(p$conv_sink)) grid$nl else as.integer(p$conv_sink)
  if (is.na(s) || s < 1L || s > grid$nl)
    stop("conv_sink must be an interior layer index in 1..", grid$nl, ", got ", s)
  rev <- isTRUE(!is.null(p$conv_reverse) && as.integer(p$conv_reverse) == 1L)
  list(Q    = q * CCX_SV_TO_M3YR,       # m3/yr
       s    = s,                         # interior layer the sinking limb feeds
       distributed = isTRUE(!is.null(p$conv_descent) && as.integer(p$conv_descent) == 1L),
       down = if (rev) "SH" else "NH",   # hemisphere whose mixed layer sinks
       up   = if (rev) "NH" else "SH")   # hemisphere that upwells
}

# ---------------------------------------------------------------------
# State layout
# ---------------------------------------------------------------------
#' Land pool names, in state order. The C++ core hard-codes this order and this
#' count as a stride (src/ccx_core.cpp), so it is a structural constant, not a
#' presentational one.
CCX_LAND_POOLS <- c("leaf", "wood", "soil_fast", "soil_slow")

#' Land-use permanence: the default, and the ceiling on how much land the model
#' will let cumulative land-use change clear.
#'
#' 1 = the land's equilibrium carbon falls by exactly the carbon that land-use
#' change removed. Stated as a named constant because BOTH ccx_default_params()
#' and ccx_cpp_par()'s fallback must use it -- if they disagreed, a hand-built
#' parameter list would silently run a different model through the C++ core than
#' through the R one, which is exactly the divergence gamma_enso produced.
#'
#' The ceiling is a numerical guard, not physics: at f_luc_perm = 1 the shipped
#' historical forcing reaches a cleared fraction of ~0.14 by 2024, nowhere near
#' it. It exists so a runaway scenario or a sampled f_luc_perm cannot drive the
#' land's productive capacity to zero or negative inside an RK4 substep.
CCX_F_LUC_PERM_DEFAULT <- 1
CCX_LUC_CLEARED_MAX    <- 0.9

#' WHERE the land-use debit comes from: the share taken out of the WOOD pool.
#'
#' 1 = wood alone, which is Marcus' 2026-08-12 call and the shipped behaviour --
#' deforestation removes standing woody biomass, and the emitted carbon should
#' carry that pool's lagged 14C. 0 = split PRO RATA across all four land pools
#' by their preindustrial equilibrium shares, which is the split that leaves
#' every pool exactly at its new (cleared) equilibrium.
#'
#' The two differ because scaling npp0 by (1 - c) lowers every pool's
#' equilibrium pro rata while a wood-only debit lands entirely on a 37-yr pool:
#' wood is left BELOW its new equilibrium and the soils ABOVE theirs, and the
#' redistribution that follows re-releases part of the debit on soil timescales.
#' Measured consequence: the 100-yr airborne fraction of a land-use pulse is
#' about HALF a fossil pulse's at f_luc_wood = 1 (calibration/diag_luc_prorata.R).
#'
#' DECIDED 2026-08-13: PRO RATA (0). Marcus delegated this one on the grounds of
#' physical realism; the three reasons, in the order they carry weight:
#'
#' 1. It is the mass-consistent partner to the term it lives with. The
#'    converted-land term says a fraction c of the land is no longer forest and
#'    lowers ALL FOUR pools' equilibria by c. Clearing a fraction of the land
#'    physically removes that fraction of what is on AND in it -- the wood and
#'    the soil carbon under it. Taking the whole debit from wood removes
#'    c * land0 of carbon from a pool that holds 22.5 % of it, which leaves the
#'    surviving land's wood depleted against its own unchanged per-area
#'    equilibrium. Nothing physical does that.
#' 2. E_LUC IS ALREADY TIMING-RESOLVED. GCB's bookkeeping models track the slow
#'    post-clearing soil-carbon decline explicitly, so a given year's E_LUC is a
#'    mixture of fast vegetation loss and legacy soil loss from clearing decades
#'    earlier. The model does not need to re-impose a vegetation-only timing on
#'    a flux that already carries the real one; it needs to take the carbon from
#'    where the bookkeeping took it, which integrated over the legacy is close to
#'    stock-weighted.
#' 3. Wood-only leaves a weakened version of the bug 404d66d was written to fix.
#'    Measured: the LUC/fossil airborne-fraction ratio is 0.50 at 100 yr under
#'    wood-only and 1.02 under pro rata, at every horizon 50-200 yr. Half of
#'    each land-use tonne still comes back.
#'
#' WHAT IT GIVES UP, stated because it is a real cost and not a small one: the
#' 2026-08-12 call that the emitted carbon carries WOOD's lagged 14C. Pro rata
#' it carries a stock-weighted mixture the 500-yr soil dominates, and at 2024
#' the debit's own D14C goes +57.1 -> -10.1 permil -- in the bomb era it flips
#' from bomb-enriched to depleted. That is defensible for a flux that includes
#' legacy soil respiration, and it is a prediction the 14C streams can score.
#'
#' THE CAVEAT THIS DOES NOT SOLVE, and it is reason 2's limit. For a SINGLE
#' clearing event the debit should be fast out of vegetation and slow out of
#' soil; pro rata takes 70 % of it out of a 500-yr pool instantaneously. That is
#' wrong for the app's "what if we cleared X" scenario even though it is right
#' for the historical E_LUC record. A timing-resolved debit -- fast from veg,
#' slow from soil, with the split a function of years since clearing -- is the
#' third option nobody has costed. Logged, not built.
CCX_F_LUC_WOOD_DEFAULT <- 0

# ---------------------------------------------------------------------
# Seasonal-cycle DRIVERS (2026-08-18, Marcus): insolation + Q10 on seasonal T
# ---------------------------------------------------------------------
#' The seasonal NEP cycle was a prescribed sine with 4 fitted knobs
#' (seas_amp/seas_phase per hemisphere) -- a description, and being a single
#' harmonic, structurally unable to produce the observed asymmetry of the
#' cycle (MLO second harmonic 0.83 ppm, 28 % of the first; the model made
#' 0.03). Replaced by its physical drivers:
#'
#'   NPP(t)  = npp * n(t),  n = insolation at an effective boreal latitude,
#'             lagged by a PHENOLOGY parameter (leaf area develops over weeks),
#'             normalised to unit annual mean;
#'   R_h(t)  = the existing q10 soil respiration, modulated by
#'             q10^(T_seas/10) with T_seas a climatological seasonal land
#'             temperature of FREE amplitude, renormalised to unit annual mean
#'             so the annual carbon budget is untouched (Jensen term removed).
#'
#' The sawtooth then EMERGES from Q10's exponential nonlinearity and the
#' growing-season shape. Feasibility was established OFFLINE FIRST
#' (calibration/diag_seasonal_drivers_offline.R): with NPP and R_h pinned at
#' the model's own 36 GtC/yr, five shape knobs reproduce the observed MLO
#' cycle to RMS 0.357 ppm (fitted sine: 0.608) with amp2/amp1 = 0.21 vs the
#' observed 0.24 -- EMERGED, not fitted. The constants below are that
#' diagnostic's interior optimum (extended-grid re-run; nothing sits at a
#' grid edge). The light threshold optimised to ZERO -- at 75 N the polar
#' night rectifies the growing season by itself -- so no threshold constant
#' exists.
#'
#' WHAT THIS BUYS BEYOND SHAPE. The NPP-side amplitude is npp * (n - 1): no
#' longer a fitted number but a PREDICTION carrying the model's own NPP, so
#' fertilisation GROWS the cycle and land clearing SHRINKS it (the old
#' npp/npp0 scaling, inherited); and q10 gains a cross-timescale duty. The
#' contamination risk of that duty is limited by construction: seas_T_amp_*
#' absorbs the LINEAR seasonal response (at small amplitude only the product
#' A_T * ln(q10) is identified), leaving q10 only the nonlinear part.
#'
#' SH is UNFITTED: the offline work fitted MLO only (SPO's 0.55 ppm cycle is
#' substantially oceanic, which this land-only term does not model).
#' CCX_SEAS_PHI_EFF["SH"] is the SH land centroid, and seas_T_amp_SH is free
#' to absorb the amplitude. Revisit if the SPO seasonal stream misfits.
#'
#' The old sine remains REACHABLE at seas_drivers = 0 (the f_luc_perm escape
#' idiom): every pre-2026-08-18 result -- including mode_fit_pump{N,D}.rds --
#' reproduces only on that path. Diagnostics reconstructing those modes must
#' set it explicitly.
# NOT A FLUX-WEIGHTED LATITUDE -- that is what this comment used to claim and it
# is wrong by forty degrees. MEASURED 2026-08-20: the NH NPP-weighted mean
# latitude is 34.29 (calibration/diag_npp_eff_latitude.R, MOD17A3HGF), and the
# SH's is -15.12. This constant is the latitude whose INSOLATION SHAPE best
# matches observed land productivity once the amplitude is free, which is a
# different quantity and a defensible one: 75 wins that contest as a clean
# interior optimum because POLAR NIGHT gives the curve a hard zero, the only
# thing in the insolation family resembling a boreal growing season switching
# off. At unit amplitude the best shape match would be 50.
# The size that goes with the shape is seas_npp_amp_{NH,SH} (0.497 / 0.503,
# MEASURED) -- the pair is ONE (shape, size) unit and neither may move alone.
# Splitting the hemisphere into latitude bands was tested and REJECTED: under a
# non-negativity constraint every multi-box fit deletes its own low-latitude
# boxes and loses to this single curve (calibration/diag_npp_twobox.R).
CCX_SEAS_PHI_EFF <- c(NH = 75, SH = -30)   # deg; SHAPE latitude, not a centroid
# LAG CONVENTION: sin(2*pi*(t - (3.5 + LAG)/12)) peaks at t = 0.25 + (3.5 + LAG)/12,
# so the 3.5 ALREADY places the zero-lag NH peak at mid-July and LAG is measured
# from there, not from the solstice.
#
# CCX_SEAS_T_LAG = 2.0 therefore puts the NH peak in mid-SEPTEMBER, which is later
# than NH land AIR temperature -- and that is correct, because this term multiplies
# SOIL respiration (the tau_soil_fast/slow fluxes below), not air temperature.
# MEASURED 2026-08-20, calibration/diag_seas_lag_profile.R: profiled at the arm-N
# mode, the seasonal rows give -19466 / -10841 / -4764 / -1411 / -521 / -1507 / -3650
# at LAG = 0.0 / 0.5 / 1.0 / 1.5 / 2.0 / 2.5 / 3.0. A clean interior optimum at 2.0,
# 18,944 log-units above the mid-July peak an air-temperature reading would want.
# An earlier comment here claimed "seasonal land T peak after Jun"; that was the
# air-temperature reading and it is wrong. DO NOT "correct" the 2.0 to match it.
CCX_SEAS_T_LAG   <- 2.0                    # months past the mid-July zero-lag peak
# MEASURED 2026-08-20g and CHANGED FROM 2.5. Unlike CCX_SEAS_T_LAG above, this
# one IS directly checkable against observation: sst_seas_amp modulates SST
# ITSELF, not a lagged flux, so the observed SST phase IS this constant's phase.
# ERSSTv5's area-weighted NH hemispheric climatology (1975-2024, = LIK_SEAS_WINDOW)
# peaks at month 7.82, which in this file's (3.5 + LAG)/12 convention is
# LAG = 1.32. The shipped 2.5 was 1.18 months LATE and was never fitted -- the
# comment here used to call it "a prior belief (ocean thermal inertia exceeds
# land's), not a fitted quantity", unidentifiable because the amplitude it
# phases sits at ~0.09 K. It no longer has to be identified from the fit.
# WORTH +18.7 log-units on the seasonal rows at the arm-N mode, for free
# (calibration/diag_seas_obs_drivers.R). It also recovers 44 % of the penalty
# for raising sst_seas_amp to its observed value -- the 08-20 test that read
# that penalty as "the ocean term is redundant" was amplitude-only and could not
# separate amplitude from phase.
# DO NOT read the 2.5 back in from ocean-thermal-inertia reasoning: the lag is
# measured from the mid-July zero-lag peak, and the ocean's inertia is ALREADY
# in the observed peak month this value is derived from.
CCX_SST_SEAS_LAG <- 1.32                   # months past the mid-July zero-lag peak;
                                           # ERSSTv5 NH 1975-2024. MEASURED, not
                                           # believed. Twin: SST_SEAS_LAG in
                                           # src/ccx_core.cpp -- change both.
CCX_SEAS_DRIVERS_DEFAULT <- 1

# ---- SOUTHERN-OCEAN ENTRAINMENT CHANNEL (2026-08-27g, version 4a) -----
# MEASURED, not fitted -- the same standing as CCX_SST_SEAS_LAG above, and for
# the same reason: it is a phase, and a phase is observable.
#
# WHY THE CHANNEL EXISTS. sst_seas_amp_* modulates SST and NOTHING else, so
# every air-sea cycle the model can build follows solubility and peaks in its
# hemisphere's late summer. The observed SH ocean is TWO regimes 5.88 months
# apart (calibration/diag_so_pco2_phase.R, Landschutzer/Laruelle NCEI 0209633
# + ERSSTv5, ocean-area weighted over LIK_SEAS_WINDOW):
#
#     subtropical 0-40 S   11.70 uatm at month 1.38   0.78 mo from its SST
#     Southern Ocean 40-90 S  7.18 uatm at month 7.50  5.56 mo from its SST
#     SH mean (VECTOR)      4.56 uatm at month 1.20 -- a 76 % CANCELLATION
#
# so a solubility-only channel matches the hemispheric RESIDUAL while matching
# NEITHER regime, and SPO sees the Southern Ocean. The missing physics is
# wintertime mixed-layer deepening entraining DIC-rich water, which raises
# surface pCO2 in the season solubility alone is lowering it.
#
# THE NH IS THE CONTROL AND GETS NO SUCH CHANNEL: NH-mean pCO2 sits 0.30 mo
# from NH-mean SST. The NH really is solubility-dominated at the hemispheric
# mean, and banding it on this evidence would be unfounded. The asymmetry here
# is MEASURED, not a convenience.
#
# THE PHASE. Peak month of the ocean-area-weighted 40-90 S pCO2 first harmonic.
# Band spread is the honest error scale: 40-60 S peaks 7.10, 60-90 S peaks 7.79
# -- a climatology carries no bar of its own. NO hemispheric sign flip: unlike
# the SST term this phase was measured IN the Southern Hemisphere and is
# absolute.
CCX_ENT_SEAS_PEAK_MO <- 7.50   # month of peak entrainment-driven surface DIC;
                               # MEASURED. Twin: ENT_SEAS_PEAK_MO in
                               # src/ccx_core.cpp -- change both.

#' Daily-mean top-of-atmosphere insolation at latitude phi, flat-sun formula.
#' S0 is omitted -- every use divides by the annual mean, so it cancels.
#' Periodic in t with period exactly 1 (the +10 day offset rides inside the
#' cosine), so callers pass continuous model time directly.
ccx_insol <- function(phi_deg, tt) {
  phi <- phi_deg * pi / 180
  dec <- -23.44 * pi / 180 * cos(2 * pi * (tt * 365.25 + 10) / 365.25)
  h0  <- acos(pmin(pmax(-tan(phi) * tan(dec), -1), 1))
  (h0 * sin(phi) * sin(dec) + cos(phi) * cos(dec) * sin(h0)) / pi
}

#' Unit-mean normalisers for the two driver shapes, on a 720-POINT midpoint
#' grid. BOTH cores must use exactly this definition (the C++ core precomputes
#' it in unpack_par) or bit-parity breaks.
#'
#' WHY 720 AND NOT 12 (measured 2026-08-18, /tmp-scratch drift decomposition,
#' numbers preserved in the CHANGELOG entry): the insolation shape has KINKS at
#' the polar-night edges of the 75 N effective latitude, so a 12-point norm
#' disagrees with the integrator's effective annual mean by enough to leak
#' +0.22 ppm over 275 zero-emission years -- pure quadrature, on top of the
#' +0.25 ppm the fertilisation rectifier genuinely produces. At 720 points the
#' norm is the continuous mean to well beyond the integrator's own accuracy,
#' and only the physical rectifier remains.
ccx_seas_norms <- function(p) {
  mid <- (seq_len(720) - 0.5) / 720
  lapply(c(NH = "NH", SH = "SH"), function(h) {
    a_t <- if (h == "NH") p$seas_T_amp_NH else p$seas_T_amp_SH
    list(n = mean(ccx_insol(CCX_SEAS_PHI_EFF[[h]], mid - p$seas_lag_p / 12)),
         r = mean(p$q10^(a_t * sin(2 * pi * (mid - (3.5 + CCX_SEAS_T_LAG) / 12)) / 10)))
  })
}

# ---------------------------------------------------------------------
# CO2 fertilisation: the functional FORM
# ---------------------------------------------------------------------
#' Fertilisation form codes. Structural, like `revelle_frozen` and the conveyor
#' geometry: they select a mechanism, they do not tune one.
CCX_FERT_LOG <- 0L    # NPP = NPP0 (1 + beta ln(chi/chi0))       -- the incumbent
CCX_FERT_MM  <- 1L    # NPP = NPP0 (1 + beta_max dchi/(K + dchi)) -- saturating

#' WHY A SECOND FORM EXISTS (review 2026-08-14 sec.4.1, item 7).
#'
#' The log form has ONE parameter controlling TWO things the data want to set
#' independently:
#'   * the INTEGRAL -- cumulative historical land uptake, which the CO2 record
#'     and GCB's land sink both bear on;
#'   * the DERIVATIVE at today's CO2, dNPP/dchi = beta NPP0 / chi, which is what
#'     a PULSE sees, and therefore what DESIGN sec.6 gate 12 (Joos IRF) and the
#'     Pulse Lab's Revelle lesson both bear on.
#' The ratio between them is fixed by the functional form; beta only slides
#' along it. At beta 0.75, chi 388: 0.75 * 60 / 388 = 0.116 GtC/yr/ppm, where
#' gate 12 passes only at 0.062-0.077. TWO INDEPENDENT CRITERIA -- a 15-model
#' literature benchmark (Joos et al. 2013, via diag_joos_beta_scan.R) and the
#' app's own pedagogical claim -- put the same ceiling on beta at ~0.50, and
#' neither was used to set it. That is a structural failure, not a tuning miss.
#'
#' MICHAELIS-MENTEN, and not merely "something that saturates". Photosynthetic
#' carboxylation is an enzyme reaction, and enzyme reactions saturate in exactly
#' this shape -- so the replacement is the one form whose one-sentence
#' explanation an undergraduate already has ("Rubisco can only work so fast").
#' A bounded exponential would also decouple integral from derivative, but it
#' saturates far harder in the tail and has no comparable story.
#'
#' THE PARAMETERS ARE BOTH READABLE, which matters for a teaching model:
#'   beta_max  the fractional NPP enhancement at INFINITE CO2 (asymptote - 1)
#'   fert_k    the CO2 increment ABOVE PREINDUSTRIAL, in ppm, at which HALF of
#'             beta_max is realised
#'
#' NOT A LIMIT OF THE LOG FORM. As fert_k -> Inf with beta_max/fert_k fixed, MM
#' goes LINEAR, not logarithmic. So `beta` does not map onto (beta_max, fert_k)
#' by any substitution, and a fit under one form is not a fit under the other.
#' Both parameter sets are carried; `fert_form` selects which is live and the
#' other is INERT (gated by test-fertilisation.R in both directions).
#'
#' DEFAULT FLIPPED TO MM ON 2026-08-14 (Marcus), and it is the resolution of his
#' deferred decision 2 -- "flip the default to MM". The log form is kept, not
#' deleted, because every result in this repo before today was produced under it
#' and the switch is what makes those reproducible.
#'
#' WHAT THE FLIP BOUGHT, at fert_k 120 / beta_max 0.4913 against the log form at
#' the beta 0.75 it replaced (calibration/diag_fert_saturating.R,
#' diag_fert_pulse_gates.R, diag_joos_beta_scan.R):
#'
#'                        loglik   CO2 bias   land sink   Joos IRF 20/50/100
#'   log beta 0.75         -3793     +3.34      +4.57 sd   10.4/19.9/31.2 FAIL x3
#'   MM K=120 bmax 0.4913  -3760     +0.14      +2.28 sd   12.4/25.6/41.9 INSIDE x3
#'
#'   Revelle lesson (ssp585 - ssp119 airborne fraction at +100 yr):
#'   log 0.75  -0.113 REVERSED   ->   MM K=120  +0.566 HOLDS
#'
#' It is BETTER ON THE LIKELIHOOD as well as on the gates, which is the part
#' that makes it a structural fix rather than a trade: no value of beta could
#' buy any two of those at once, because the log form's enhancement and slope
#' are locked in a fixed ratio chi/chi0.
#'
#' WHAT IT DID NOT FIX. Gate 7 still misses -- the land sink is +2.28 sd against
#' GCB, down from +4.57 but still outside. And gate 12 caps fert_k near 150
#' while the log-posterior's own preference on this locus is 171, so the
#' likelihood and the pulse gate still pull apart, just far less. THE REFIT IS
#' WHAT SETTLES THAT; these are a default, not a calibration.
CCX_FERT_FORM_DEFAULT <- CCX_FERT_MM

# VOLCANIC DIFFUSE-LIGHT FERTILISATION, adopted 2026-08-29 (Marcus).
# Fractional NPP enhancement per unit stratospheric AOD. Named here and used by
# BOTH ccx_default_params() and ccx_cpp_par(), the same way CCX_FERT_FORM_DEFAULT
# is, so R and C++ cannot disagree about what a parameter list without the field
# means -- the divergence the bit-parity rule exists to prevent.
#
# ⚠ 0.25 IS AN ADOPTION, NOT A DEFAULT-PRESERVING VALUE. Everything fitted before
# 2026-08-29 was fitted at 0 and is NON-COMPARABLE with anything fitted after.
# Chosen at the CONDITIONAL price -7.42 (r 0.571 -> 0.624, and the r gain survives
# refitting); gamma = 0.97, which matches the Pinatubo feature, costs 14x more and
# fits the record WORSE. FACE-gated: the implied response moves 8.61% -> 8.87%,
# still at the mature-forest end of the observed bracket.
CCX_GAMMA_DIFF_DEFAULT <- 0.25

#' The fertilisation multiplier on NPP0, as a function of atmospheric CO2.
#'
#' Factored out of ccx_deriv() so that diagnostics, the app and the design-target
#' arithmetic all read the SAME function the model integrates, rather than a
#' re-typed copy of it. `src/ccx_core.cpp` carries the only other copy and
#' test-parity.R gates the two against each other.
#'
#' @param chi atmospheric CO2, ppm (vectorised)
#' @param p   parameter list; uses `fert_form` and then either `beta` or
#'   (`beta_max`, `fert_k`)
#' @param chi0 preindustrial CO2, ppm -- `aux$chi0` inside the model
ccx_fert_factor <- function(chi, p, chi0 = ccx_const("CO2_PI_PPM")) {
  form <- if (is.null(p$fert_form)) CCX_FERT_FORM_DEFAULT else as.integer(p$fert_form)
  if (form == CCX_FERT_LOG)
    return(1 + p$beta * log(pmax(chi, 1e-6) / chi0))
  # MM. The denominator is floored because dchi -> -fert_k is a pole: it sits at
  # chi = chi0 - fert_k, ~106 ppm at the provisional default, which no scenario
  # reaches but a sampler or an app slider could. Below the pole NPP would flip
  # sign, so the factor is floored at 0 as well -- NPP cannot be negative, and
  # a hard floor fails visibly where an unguarded pole fails as a fitted value.
  # (The log path is left EXACTLY as it was, pole and all, so this commit cannot
  # move a single existing number.)
  d  <- chi - chi0
  kk <- max(p$fert_k, 1e-6)
  pmax(1 + p$beta_max * d / pmax(kk + d, 1e-6), 0)
}

#' Pro-rata shares of the four land pools, by preindustrial equilibrium stock.
#'
#' These are exactly the terms `aux$land0` sums, normalised -- so a debit split
#' on them removes carbon in the same proportion as scaling npp0 by (1 - c)
#' lowers the equilibrium. Derived from the parameters rather than stored, so a
#' land-structure change cannot leave a stale weight vector behind.
#' Order: leaf, wood, soil_fast, soil_slow (= CCX_LAND_POOLS).
ccx_luc_pool_shares <- function(p) {
  w <- c(p$npp_leaf_frac * p$tau_leaf,
         (1 - p$npp_leaf_frac) * p$tau_wood,
         (1 - p$litter_slow_frac) * p$tau_soil_fast,
         p$litter_slow_frac * p$tau_soil_slow)
  w / sum(w)
}

#' Names of the 32 boxes, in state order
ccx_box_names <- function(nl = N_INTERIOR) {
  unlist(lapply(HEMIS, function(h)
    c(paste0(h, "_atm"), paste0(h, "_", CCX_LAND_POOLS),
      paste0(h, "_ml"), paste0(h, "_oc", seq_len(nl)))))
}

CCX_TRACERS <- c("C", "C13", "C14")

#' Build an empty state: matrix [box x tracer]
ccx_new_state <- function(nl = N_INTERIOR) {
  bn <- ccx_box_names(nl)
  matrix(0, nrow = length(bn), ncol = length(CCX_TRACERS),
         dimnames = list(bn, CCX_TRACERS))
}

# ---------------------------------------------------------------------
# Ocean grid
# ---------------------------------------------------------------------
#' Ocean layer thicknesses: mixed layer plus interior layers whose thickness
#' grows geometrically with depth (fine near the surface, where the bomb-14C
#' penetration gradient lives; coarse at depth, which barely ventilates).
ccx_ocean_grid <- function(h_ml, total_depth = ccx_const("OCEAN_DEPTH"),
                           nl = N_INTERIOR, growth = 1.4) {
  w <- growth^(seq_len(nl) - 1)
  dz_int <- (total_depth - h_ml) * w / sum(w)
  list(h_ml = h_ml, dz = c(h_ml, dz_int), nl = nl,
       depth_mid = cumsum(c(h_ml, dz_int)) - c(h_ml, dz_int) / 2)
}

# ---------------------------------------------------------------------
# Parameters
# ---------------------------------------------------------------------
#' Default (central) parameter set. Everything a calibration would vary lives
#' here; everything structural lives in constants.R.
ccx_default_params <- function() {
  list(
    # ---- CO2 fertilisation --------------------------------------------
    # `beta` IS NO LONGER LIVE AT THE DEFAULT. fert_form flipped to CCX_FERT_MM
    # on 2026-08-14 (Marcus), so the parameters that act are beta_max and
    # fert_k below, and this whole block is the history of the parameter they
    # replaced. It is KEPT, not deleted: every result in this repo before
    # 2026-08-14 was produced under the log form at one of these values, and
    # `p$fert_form <- CCX_FERT_LOG` is what reproduces them.
    #
    # WHY IT WAS REPLACED, in one line: no value of beta can satisfy both the
    # CO2 record (which wants 0.75) and DESIGN gate 12 plus the Revelle lesson
    # (which independently want <= 0.50), because the log form locks the
    # enhancement at today's CO2 and the slope at today's CO2 into the fixed
    # ratio chi/chi0. See the note above CCX_FERT_FORM_DEFAULT.
    #
    # CO2 fertilization, NPP = NPP0 (1 + beta ln(chi/chi0)).
    # RE-CENTRED TWICE ON 2026-08-13, and the second move is the one that
    # stands. 0.38 was set on 2026-08-12 as the 1-D log-posterior optimum of the
    # model that PRECEDED 404d66d, in which land-use emissions had an airborne
    # fraction of 0.002 -- i.e. against the bug. On the converted-land model
    # with the wood-only debit that criterion gave 0.60; the debit then went
    # PRO RATA (see CCX_F_LUC_WOOD_DEFAULT), which lowers CO2 again, and the
    # same criterion now gives 0.75.
    #
    # Measured (calibration/diag_recentre_beta.R, 0.05 grid, q10 at 2.0), at
    # f_luc_wood = 0:
    #   CO2 stream's own 1-D optimum (level+seasonal+icecore)  0.753-0.757
    #   full 1-D log-posterior at mode_fit's sigmas            0.753
    #   full 1-D log-posterior at the CCX_PARAM_TABLE sigmas   0.770
    #   zero of the 2015-2024 MLO CO2 bias                     0.712
    # THE SPREAD WIDENED. Under the wood-only debit all four agreed to 0.006;
    # under pro rata the decade-level criterion sits 0.04 below the three
    # whole-record ones. The default tracks the 1-D log-posterior optimum, which
    # is the criterion it has always tracked, and the three whole-record numbers
    # cluster at ~0.755 -- so 0.75. The 2015-2024 level bias there is +3.3 ppm.
    #
    # sigma_d13c is left FREE (Marcus 2026-08-13) and moves this by 0.017, less
    # than the grid, so the default does not depend on how the refit sets it.
    #
    # WHAT IT COSTS, and it is not small. GCB's `land_sink` is the RESIDUAL sink
    # alone; the model's mean(diff(land_C)) is the NET land flux, sink MINUS
    # E_LUC. Comparing them directly is a unit trap this repo has fallen into
    # before (see diag_d13c_partition_refit's note). Like for like, 2015-2024,
    # against GCB's gross land 2.36 and ocean 3.22 GtC/yr:
    #   f_luc_wood 1, beta 0.60   gross land 3.99 (+69 %)   ocean 2.52 (-22 %)
    #   f_luc_wood 0, beta 0.75   gross land 4.57 (+94 %)   ocean 2.38 (-26 %)
    # So the beta that matches the CO2 RECORD makes the sink PARTITION worse,
    # and pro rata makes it worse still -- pro rata lowers CO2, which buys a
    # higher beta, which buys more land sink. IT IS NOT RESOLVABLE BY beta OR BY
    # THE DEBIT: diag_luc_prorata.R sec.5 measures that matching GCB's
    # cumulative land costs ~21 ppm of CO2 bias under BOTH debits. It is the
    # residual PHASE 3, the biological pump, is aimed at.
    #
    # This is a DEFAULT, i.e. an app and test fixture chosen by ONE stated
    # criterion -- not a claim that the model's carbon partition is right.
    # beta is calibrated; the mode-find is what actually sets it. See
    # R/calibrate.R.
    beta      = 0.75,
    # ---- the LIVE fertilisation parameters (2026-08-14, review item 7) -
    # fert_form = CCX_FERT_MM, so these two act and `beta` above does not;
    # test-fertilisation.R gates that in both directions, because a parameter
    # that quietly becomes live (or quietly stops being live) is the failure
    # mode this switch creates.
    #
    # ARITHMETIC, NOT A FIT -- and that is the one caveat on the flip. They are
    # the pair that solves review sec.4.1's design target exactly:
    #   (a) match the log form at beta 0.70's NPP enhancement at 388 ppm
    #       (0.70 ln(388/276.88) = 0.2363), so the historical INTEGRAL is
    #       preserved -- that is what the CO2 record and GCB's land sink buy;
    #   (b) hold dNPP/dchi at 388 ppm at or below the beta-0.50 value
    #       0.5 * 60/388 = 0.0773 GtC/yr/ppm, which is what gate 12 and the
    #       Revelle lesson buy.
    # (a) fixes beta_max given fert_k; (b) then caps fert_k at 171.
    #
    # fert_k 120 IS THE CHOSEN VALUE and the reason is gate 12, not the target
    # arithmetic. Measured on the criterion-(a) locus (diag_joos_beta_scan.R,
    # integrated IRF at TH 20/50/100 against Joos Table 4's 12.2-16.3 /
    # 24.0-36.6 / 39.5-65.2):
    #
    #   K=120  12.4 / 25.6 / 41.9   INSIDE all three, with margin
    #   K=140  12.2 / 25.0 / 40.8   inside, but TH20 sits ON the 5th percentile
    #   K=171  12.0 / 24.3 / 39.4   FAILS at TH20 and TH100
    #
    # So gate 12 caps fert_k near 150 -- BELOW the log-posterior's own optimum
    # on this locus, which is K=171 (loglik -3720 against K=120's -3760). The
    # gate and the likelihood still pull apart; K=120 takes the gate, because
    # DESIGN sec.6 opens "all must pass before headline claims" and a default
    # that ships a failing hard gate is what item 7 existed to end.
    #
    # THE FIT IS WHAT SHOULD SET THESE, and it has not run yet. These are a
    # DEFAULT chosen by one stated criterion, exactly as beta was; they are not
    # calibrated and must not be quoted as such. CCX_PARAM_TABLE now carries
    # both, so the refit will move them.
    fert_form = CCX_FERT_FORM_DEFAULT,
    beta_max  = 0.4913,   # fractional NPP enhancement at infinite CO2
    fert_k    = 120,      # ppm above preindustrial for half of beta_max
    q10       = 2.0,      # heterotrophic respiration temperature sensitivity
    # ---- land pool structure ------------------------------------------
    # Defaults chosen by diag_land_topology.R [3], the layout of lowest misfit
    # against BOTH of Naegler & Levin's biosphere targets at once -- 2200 PgC of
    # carbon and 21.7 / 18.9 kmol of bomb 14C at 1975 / 1995. It lands at
    # 2130 GtC and 21.2 / 17.4 kmol, 5.2 % RMS, with pool sizes that are
    # independently defensible: vegetation 516 GtC, responsive soil 114 GtC,
    # passive soil 1500 GtC. The scan surface is FLAT (0.60/30/0.04 and
    # 0.70/40/0.04 both sit near 6 %), so these are a defensible centre and not
    # a knife-edge optimum -- do not treat them as fitted values.
    npp_leaf_frac = 0.60, # share of NPP allocated to leaves and fine roots;
                          # the rest goes to wood
    tau_leaf  = 1,        # yr, leaf and fine-root turnover
    tau_wood  = 20,       # yr, woody biomass turnover
    litter_slow_frac = 0.05,  # share of total litter entering the PASSIVE soil
                          # pool; the rest enters the responsive one
    tau_soil_fast = 2,    # yr, responsive soil turnover
    tau_soil_slow = 500,  # yr, passive soil turnover -- long enough that the
                          # pool holds carbon without seeing the bomb spike
    npp_veg_frac = 0.5,   # phi: fraction of NPP that scales with the standing
                          # vegetation stock (the rest is stock-independent), so
                          # that clearing a forest costs capacity and not only
                          # carbon. Sub-linear because leaf area saturates with
                          # biomass. Stable well past 1 -- see the derivative.
    ra_ratio  = 0,        # Ra/NPP routed THROUGH the vegetation pool, i.e. the
                          # equilibrating part of GPP. 0 = no gross loop, which
                          # reproduces the pre-2026-08-12 model exactly. Affects
                          # isotopes only; the net carbon flux is NPP regardless.
    # LAND-USE PERMANENCE, added 2026-08-13. See the "converted land" block in
    # ccx_deriv() for the mechanism. 1 = the land's equilibrium carbon falls by
    # EXACTLY the carbon land-use change removed, i.e. the debit is permanent;
    # 0 reproduces the 2026-08-12--13 model, in which land-use emissions had an
    # airborne fraction of 0.002 at 100 years (calibration/diag_1900_deficit.R).
    # It is NOT a fudge factor with a convenient value: 1 is the mass-consistent
    # point, and it is the default for that reason rather than by fit.
    f_luc_perm = CCX_F_LUC_PERM_DEFAULT,
    # WHERE the debit comes from, added 2026-08-13 as a switch defaulting to
    # the then-incumbent wood-only -- see CCX_F_LUC_WOOD_DEFAULT, which ea7c70b
    # flipped to 0 when pro rata was adopted. 1 = wood alone, 0 = pro rata
    # across the four pools (SHIPPED).
    f_luc_wood = CCX_F_LUC_WOOD_DEFAULT,
    k_w       = 1500,     # m/yr, gas transfer velocity
    h_ml      = 75,       # m, mixed-layer depth
    # OVERTURNING, m/yr. 0 = the pure-diffusion ocean, reproduced EXACTLY (no
    # flux is emitted at all), which is what every result before 2026-08-13 was
    # computed on. See the "ocean overturning" block in ccx_deriv() for what a
    # non-zero value does and why it is not a second diffusivity. Whether this
    # becomes a calibrated parameter, a fixed structural value, or stays off is
    # a decision for DESIGN.md section 10, NOT for this default.
    w_up      = 0,
    # OUTCROPPING, m/yr, PER HEMISPHERE (Marcus 2026-08-13). The OTHER way to
    # make the column non-diffusive, and the one that matches where the real
    # ocean does it: deep water reaches the surface in ONE step -- a Southern
    # Ocean outcrop -- and the return path is distributed downward. `w_up` above
    # is the mirror image of this (distributed up, non-local down), and the two
    # are NOT interchangeable: see the block in ccx_deriv(). Per hemisphere
    # because the outcrop is a Southern Ocean feature and the two ocean columns
    # are otherwise independent -- an SH-only value is a testable claim about
    # the MLO-SPO gradient, which the likelihood already scores.
    # Both 0 = the pure-diffusion ocean, exactly.
    w_out_NH  = 0,
    w_out_SH  = 0,
    # ---- THE BIOLOGICAL PUMP (task 9, ported 2026-08-16 from the shim in
    # calibration/pump_shim.R) --------------------------------------------
    # THE PUMP SHIPS ON, AND `pump_grad` IS A FITTED PARAMETER (Marcus
    # 2026-08-16d, on calibration/diag_pump_grad_profile.R + _kz_degeneracy.R).
    # It was OFF by default from the port until that decision.
    #
    # `pump_grad` is the PREINDUSTRIAL surface-to-bottom DIC gradient the pump
    # holds, in umol/kg. The export field is not a parameter: it is SOLVED as the
    # source that makes the observed profile SHAPE (data/obs_glodap_deep.rds
    # $dic_profile, a build product) an exact steady state of the model's OWN
    # diffusion operator, so it scales with `kz` and re-solves on every draw.
    #
    # THE DEFAULT IS THE OBSERVATION, NOT THE FIT. `PUMP_GRAD_OBS` = 233.109 is
    # GLODAP's own gradient and is also this parameter's prior centre. The
    # four-row objective prefers ~274.5 +/- 13.1 (1.178x) at the pre-gradient
    # mode, but that optimum is a fit at a `kz` the refit will move, so putting
    # it here would launder a fit as a structural constant. The refit is what
    # moves this number.
    #
    # SETTING IT TO 0 STILL TURNS THE PUMP FULLY OFF and bit-reproduces every
    # pre-2026-08-16 result -- the `is.null(aux$pump)` guard is unchanged, and
    # tests/testthat/test-pump.R holds it.
    pump_grad = ccx_const("PUMP_GRAD_OBS"),
    # Carbonate share of that gradient. PINNED BY OBSERVATION, not fitted:
    # GLODAP's alkalinity gradient (+78.59 umol/kg) with
    # d(ALK) = 2 C_carb - (N:C) C_org gives 23 % (diag_alk_gradient.R). The d13C
    # row independently wants 26 % under transient scoring. Kept as a parameter
    # rather than a constant because it is the thing the alkalinity row can move.
    pump_carb_frac = 0.23,
    # "N" = nutrient-limited, export mass FIXED (the standard steady-pump
    # assumption, and the one whose zero-uptake property is proved).
    # "D" = DIC-limited, export scales with the mixed layer's carbon -- the ONLY
    # way the pump touches uptake. BOTH ARE PORTED AND THE CHOICE IS DEFERRED TO
    # THE REFIT (Marcus 2026-08-16): mode D gains +195 log-units over N on the
    # CO2 record with nothing refitted, but a refit has `beta_max` and `kz` free
    # and could reallocate all of it, so banking it here would be premature.
    pump_mode = "N",
    # ---- THE CONVEYOR (Marcus 2026-08-13, built after the configuration red
    # team in notes/redteam_2026-08-13_conveyor_configurations.md) ----------
    # NH sinking -> deep interhemispheric flow -> SH upwelling -> surface
    # return. THE FIRST OCEAN-OCEAN COUPLING IN THE MODEL: the two columns were
    # otherwise independent, and the only interhemispheric term was atmospheric.
    #
    # WHY IT IS NOT A THIRD `w_up`. Handoff 2026-08-13b sec.2 proved that
    # reversing or rerouting a CLOSED vertical loop is invisible to the
    # atmosphere (A_out = D A_up^T D^-1, verified to 1.7e-18), because a
    # transpose preserves diagonal elements and the mixed layer is the only box
    # through which the ocean touches anything else. The conveyor breaks BOTH
    # premises: each column becomes OPEN (net throughflow sustained by the
    # interhemispheric limbs), and the ocean touches the atmosphere at TWO
    # boxes. A transpose SWAPS off-diagonals, so NH->SH and SH->NH responses
    # exchange rather than being preserved -- the conveyor is distinguishable
    # from its own reverse, which is the free decisive wiring check in
    # tests/test-conveyor.R.
    #
    # PARAMETERISED BY VOLUME FLUX, NOT VELOCITY. The hemispheres have different
    # ocean areas (1.55e14 vs 2.06e14 m2), so one velocity would not conserve
    # volume across the basin. Each box gains Q and loses Q, so a
    # uniform-concentration ocean is STILL an exact fixed point and
    # ccx_spinup()'s analytic 12C equilibrium stands untouched.
    q_conv    = 0,        # Sv. 0 = off, and NOTHING is emitted, so the
                          # pure-diffusion model is bit-reproduced.
    # ---- structural switches, NOT calibrated parameters -----------------
    # (same standing as `revelle_frozen` below: they select a mechanism, they do
    # not tune one. The three red-team configurations are points in this pair.)
    #
    #   Config A  conv_sink = N_INTERIOR, conv_descent = 0   handoff 13b sec.4.2
    #   Config B  conv_sink = N_INTERIOR, conv_descent = 1   distributed descent
    #   Config C  conv_sink = 8,          conv_descent = 0   sink to NADW depth
    #
    # DEFAULT IS C, the red team's recommendation. A sinks the NH mixed layer
    # straight to the bottom box, which leaves NH oc1..oc9 -- 30 % of the deep
    # ocean -- with no advective flux at all; once `kz` falls (which is the
    # point of the exercise) that produces young bottom water under anomalously
    # old mid-depth water, an inversion the Atlantic does not have. It also
    # plumbs a limb named "NADW" to the depth of AABW, which forms at the other
    # end of the world. Layer 8 spans 1314-1861 m at h_ml = 75, which is NADW.
    conv_sink    = 8L,    # interior layer receiving the NH sinking limb (1..nl)
    conv_descent = 0L,    # 0 = non-local plume (NADW forms in a narrow region
                          # and sinks fast), 1 = distributed layer-by-layer
    conv_reverse = 0L,    # 1 = run the whole cell BACKWARDS (SH sinking, NH
                          # upwelling). Exists ONLY for the wiring gate: by the
                          # sec.2 theorem it MUST give a different atmosphere,
                          # and if it ties, the loop has been accidentally
                          # closed within a column. Never a physical setting.
    kz        = 5000,     # m2/yr, interior eddy diffusivity. RE-CENTRED
                          # 2026-08-12 from 4000, to the centre of the range that
                          # puts deep-ocean D14C inside the observed -150 to -200
                          # (4000 sat at the -195 edge; 5000 gives -170). MUST
                          # track CCX_PARAM_TABLE$kz's init and [lo, hi] -- see
                          # the derivation in that entry. Default-parameter 14C
                          # numbers computed before this date are at kz 4000.
    tau_ex    = 1.3,      # yr, interhemispheric atmospheric exchange
    sst_NH    = 18,       # degC, hemispheric-mean SST (inside the K1/K2 fit range)
    sst_SH    = 16,
    sst_scale = 0.8,      # SST anomaly per unit GMST anomaly
    npp_frac_NH = 0.60,   # NH share of global NPP
    # THE SINE'S KNOBS, live only at seas_drivers = 0 (the escape hatch; see
    # the CCX_SEAS_PHI_EFF block). Kept so pre-2026-08-18 parameter lists --
    # mode_fit_pump{N,D}.rds included -- reach the core as the model they were
    # fitted to. NOT in CCX_PARAM_TABLE any more; do not re-add them.
    seas_amp_NH = 12,     # GtC/yr, seasonal NEP amplitude (sine path only)
    seas_amp_SH = 2,
    seas_phase_NH = 3.5,  # month of peak uptake (sine path only)
    seas_phase_SH = 9.5,
    # THE DRIVER PATH'S KNOBS (see CCX_SEAS_PHI_EFF block for the physics and
    # the offline provenance of the inits).
    seas_drivers = CCX_SEAS_DRIVERS_DEFAULT,
    seas_T_amp_NH = 12,   # K, seasonal land temperature half-amplitude
    seas_T_amp_SH = 6,
    seas_lag_p = 2.25,    # months, phenology lag of NPP behind insolation
    # DIAGNOSTIC CHANNEL SWITCH (2026-08-20f). Scales the seasonal NEP term and
    # NOTHING else. 1 = the shipped model, bit for bit. 0 turns that one channel
    # off while leaving the annual carbon budget untouched, because the term is
    # zero-annual-mean by construction (the / nrm$n normaliser is what makes it
    # so). NOT in CCX_PARAM_TABLE and never fitted -- it is the missing third
    # switch in a channel decomposition whose other two channels can already be
    # isolated exactly (seas_T_amp = 0 kills the respiration modulation,
    # sst_seas_amp = 0 kills the air-sea one). It exists because
    # CCX_SEAS_PHI_EFF is a compile-time constant in src/ccx_core.cpp and so
    # cannot be varied inside one R session. See
    # calibration/diag_seas_channel_decomp.R.
    # MEASURED 2026-08-20r and CHANGED FROM 1 (Marcus: "if 75 + 0.49 is the
    # better fit, go with the better fit"). These are the scale the 75 / -30
    # insolation SHAPES need to match observed productivity -- see the
    # SEAS_NPP_AMP_* block in R/constants.R for what CCX_SEAS_PHI_EFF actually
    # is and why its curve is 1.6x too big without them. Worth +548 log-units
    # at the arm-N mode with the seasonal block re-optimised
    # (calibration/diag_phi_eff_profile.R), and seas_T_amp_NH then falls from a
    # fitted 48.07 to 10.8, against a MEASURED 11.45.
    # RE-DERIVE BOTH IF CCX_SEAS_PHI_EFF MOVES -- they are conditional on it.
    seas_npp_amp_NH = ccx_const("SEAS_NPP_AMP_NH"),
    seas_npp_amp_SH = ccx_const("SEAS_NPP_AMP_SH"),
    # Seasonal SST (2026-08-18, same session, Marcus: do the SST fix BEFORE the
    # refit). Hemispheric-mean SST seasonal half-amplitudes, K. These are the
    # OCEAN half of the seasonal cycle -- winter solubility uptake, summer
    # outgassing -- which the land-only drivers otherwise force seas_T_amp_SH
    # to fake at SPO. Inits are rough climatology (NH ~2 K, SH milder, more
    # ocean); free with shrinkage priors, for the seasonal streams to choose.
    sst_seas_amp_NH = 2.0,
    sst_seas_amp_SH = 1.2,
    # Southern-Ocean entrainment channel (2026-08-27g, version 4a). Amplitude
    # of the zero-mean seasonal DIC anomaly it imposes on the SH mixed layer,
    # umol/kg, peaking at CCX_ENT_SEAS_PEAK_MO. See that constant for what the
    # channel is and why the NH has no twin.
    #
    # DEFAULT 0 = the channel is OFF and the model is the shipped one BIT FOR
    # BIT. It is switched on deliberately, by a scan or a fit, never by
    # accident. NOT in CCX_PARAM_TABLE: adding it would change the length of
    # the calibrated vector and invalidate the stored mode and its Hessian.
    #
    # SCALE, from a pre-check done before the channel was written: the Southern
    # Ocean's own solubility cycle (SST amp 3.0 K x ~4.23 %/K x ~370 uatm ~
    # 47 uatm at month 1.94) has to be OVERCOME to leave the observed 19.45
    # uatm at month 7.50, so the entrainment term is ~66 uatm in-band, i.e.
    # dDIC ~ (66/370) x 2150 / 13 ~ 30 umol/kg -- and ~11 umol/kg averaged over
    # the SH box after the 0.369 ocean-area weight of the band. A fitted value
    # far outside ~5-30 is the channel being used as a fudge factor.
    ent_seas_amp_SH = 0,
    # 1 = annual-mean SST from the forcing's OBSERVED HadSST4 columns (with the
    # ratio-scaled extension beyond the record); 0 = the legacy
    # sst_scale * gmst map. Structural switch, not calibrated.
    sst_obs = 1,
    # ENSO COEFFICIENT: 0, NOT the CCX_PARAM_TABLE init of 0.5, and this is a
    # deliberate asymmetry with beta/q10/kz (which do take their table inits).
    # Until 2026-08-13d it was ABSENT here, so ccx_deriv() -- which multiplies it
    # straight into add_flux -- died with "argument is of length zero" on default
    # parameters, while ccx_cpp_par() silently substituted 0. That is an R-vs-C++
    # divergence about what ccx_default_params() MEANS, which is precisely what
    # the bit-parity rule exists to prevent, and it cost three debugging cycles
    # (handoff 2026-08-13c sec.7 records the first). 0 is the behaviour-preserving
    # value: it is what every ccx_run_fast() call on default parameters has been
    # using all along. Setting it to the table's 0.5 would silently change every
    # existing default-parameter result.
    gamma_enso = 0,
    # VOLCANIC DIFFUSE-LIGHT FERTILISATION (2026-08-29). Fractional NPP
    # enhancement per unit stratospheric AOD. 0 = OFF, and 0 is deliberate:
    # it makes every pre-2026-08-29 result bit-identical and keeps the
    # calibrated 21 comparable. Turning it on is an explicit act, and whether
    # it becomes a FITTED parameter is a separate decision (it is a
    # base_param, like ent_seas_amp_SH).
    # ⚠ ADOPTED AT 0.25 on 2026-08-29 -- see CCX_GAMMA_DIFF_DEFAULT. It is no
    # longer the behaviour-preserving value, and that is deliberate.
    gamma_diff = CCX_GAMMA_DIFF_DEFAULT,
    # ---- mechanism switch, NOT a calibrated parameter -----------------
    # FROZEN REVELLE. 0 = normal carbonate chemistry. 1 = the ocean's buffer
    # factor is held at its preindustrial value instead of rising as the ocean
    # takes up carbon. This is the counterfactual DESIGN section 7 tab 3 asks
    # for, and it cannot be expressed as a parameter change, because Revelle
    # saturation is an emergent property of the carbonate system rather than a
    # coefficient anywhere. Temperature-dependent SOLUBILITY (K0) is deliberately
    # left alone, so the switch isolates the buffer effect and nothing else.
    revelle_frozen = 0
  )
}

# ---------------------------------------------------------------------
# Derivative
# ---------------------------------------------------------------------
#' Time derivative of the state.
#'
#' @param y      state matrix [box x tracer]
#' @param t      time, decimal years
#' @param p      parameter list
#' @param forc   list of forcing values ALREADY interpolated to time t:
#'               e_foss, e_luc (GtC/yr, per hemisphere), gmst (degC),
#'               enso (index), c14_bomb, c14_nuclear, c14_cosmo (mol 14C/yr)
#' @param grid   ocean grid from ccx_ocean_grid()
#' @param aux    precomputed invariants from ccx_prepare()
ccx_deriv <- function(y, t, p, forc, grid, aux, record = FALSE) {
  dy <- y * 0
  nb <- nrow(y)

  # --- optional flux tap (R/fluxes.R) ---------------------------------
  # OFF by default and behind a single branch inside add_flux/add_source, so
  # the integrated model is untouched. When on, it accumulates BOTH the named
  # channels and a per-box carbon net -- the second exists so test-fluxes.R can
  # assert the recorded edges reproduce dy[, "C"] exactly, which is what makes
  # the trace provably the same fluxes the model integrates rather than a
  # parallel derivation of them.
  if (record) {
    .fx  <- ccx_flux_zero()
    .net <- numeric(nb)
    .cls <- ccx_flux_boxclass(aux, nb)
    .atmN <- aux$idx$NH$atm
  }
  .rec <- function(from, to, F_C, lab) {
    cs <- ccx_flux_channel(from, to, lab, .cls, .atmN)
    if (is.null(cs))
      stop("ccx_deriv(record): unclassified flux ", from, " -> ", to,
           " -- add a rule to ccx_flux_channel()")
    # int_exch is a GROSS magnitude: the interior has no single "downward" once
    # the conveyor's deep interhemispheric limb exists, so summing signed values
    # would report a near-cancelling number that means nothing.
    .fx[[cs$ch]] <<- .fx[[cs$ch]] + if (cs$ch == "int_exch") abs(F_C) else cs$sign * F_C
    if (from > 0L) .net[from] <<- .net[from] - F_C
    .net[to] <<- .net[to] + F_C
    invisible(NULL)
  }

  # --- flux helper: emit once, apply twice, opposite signs ------------
  # `alpha13` is the 13C fractionation factor on this flux (1 = none).
  #
  # GROSS, NOT NET. Isotopes are carried at the SOURCE box's ratio, so an
  # interface represented only by its NET carbon flux transfers no isotope at
  # all when that net is zero -- which is exactly the preindustrial state. Air-sea
  # gross exchange is ~80 GtC/yr each way against a ~2 GtC/yr net, and it is the
  # gross exchange that equilibrates 13C and 14C. Representing only the net made
  # the preindustrial isotope operator singular (caught by ccx_spinup, 2026-08-10).
  # So every bidirectional interface is emitted as TWO one-way gross fluxes.
  # A signed net flux is still fine where the process really is one-way at a time
  # (seasonal NEP, ENSO), and add_flux handles the sign by swapping the source.
  add_flux <- function(from, to, F_C, alpha13 = 1, lab = NULL,
                       alpha13_signed = FALSE) {
    if (F_C == 0) return(invisible(NULL))
    # A SIGNED FLUX MAY NOT CARRY A FRACTIONATION. Swapping the source box (two
    # lines down) is the right thing for the RATIO and the wrong thing for
    # `alpha13`: the reverse limb of a fractionating exchange is a different
    # process with a different alpha, and reusing the forward one discriminates
    # the returning carbon twice. That is exactly the 2026-08-25e seasonal-NEP
    # bug, which no test could see -- this function is antisymmetric, so total
    # 13C is conserved for ANY alpha, and a conservation gate is blind to a
    # mis-partition. Resolve alpha at the CALL SITE, per direction.
    # `alpha13_signed = TRUE` means THIS CALL SITE HAS BEEN REVIEWED FOR THE
    # NEGATIVE CASE. Two kinds of site qualify and both must say WHICH in a
    # comment at the call:
    #   (a) ONE-WAY BY CONSTRUCTION -- the flux can only go negative in a
    #       numerically broken state (the air-sea gross limbs, when a diverging
    #       RK4 stage drives pCO2 below zero). The run is rejected anyway, and a
    #       hard stop here would break ccx_run_fast()'s NA-retry escalation and
    #       test-stability.R, which explores that regime ON PURPOSE.
    #   (b) GENUINELY SIGNED AND STILL OPEN -- the biological pump.
    # It is NOT a general escape hatch. The default (stop) is what catches the
    # case this guard exists for: a flux that changes sign in a HEALTHY run
    # while carrying a fractionation. That was the 2026-08-25e seasonal-NEP bug.
    if (F_C < 0 && alpha13 != 1 && !alpha13_signed)
      stop("add_flux: a negative flux may not carry alpha13 != 1 (from ", from,
           " to ", to, ", F_C ", format(F_C), "). The reverse limb is a ",
           "different process: resolve alpha13 at the call site, per direction. ",
           "If the same alpha genuinely applies both ways, say so explicitly ",
           "with alpha13_signed = TRUE.")
    if (record) .rec(from, to, F_C, lab)
    # ratios taken from the SOURCE box; for a negative flux the source is `to`
    src <- if (F_C > 0) from else to
    r13 <- if (y[src, "C"] > 0) y[src, "C13"] / y[src, "C"] else 0
    r14 <- if (y[src, "C"] > 0) y[src, "C14"] / y[src, "C"] else 0
    f13 <- F_C * r13 * alpha13
    f14 <- F_C * r14                       # NO fractionation -- see header
    dy[from, "C"]   <<- dy[from, "C"]   - F_C
    dy[to,   "C"]   <<- dy[to,   "C"]   + F_C
    dy[from, "C13"] <<- dy[from, "C13"] - f13
    dy[to,   "C13"] <<- dy[to,   "C13"] + f13
    dy[from, "C14"] <<- dy[from, "C14"] - f14
    dy[to,   "C14"] <<- dy[to,   "C14"] + f14
    invisible(NULL)
  }

  # --- diffusion acts on EACH TRACER's own gradient -------------------
  # Not on the net carbon flux times a ratio: 13C and 14C diffuse down their own
  # concentration gradients, which is what builds the deep-ocean 14C depletion
  # even where the net carbon flux vanishes. Antisymmetric, so still exactly
  # conservative for every tracer.
  add_diffusion <- function(a, b, dz_a, dz_b, dz_mid) {
    for (tr in CCX_TRACERS) {
      F_t <- p$kz * (y[a, tr] / dz_a - y[b, tr] / dz_b) / dz_mid
      if (record && tr == "C" && F_t != 0) .rec(a, b, F_t, NULL)
      dy[a, tr] <<- dy[a, tr] - F_t
      dy[b, tr] <<- dy[b, tr] + F_t
    }
    invisible(NULL)
  }

  # --- external source: enters one box, no counterpart ----------------
  add_source <- function(box, F_C, d13c, d14c) {
    if (record && F_C != 0) .rec(0L, box, F_C, NULL)
    dy[box, "C"]   <<- dy[box, "C"]   + F_C
    dy[box, "C13"] <<- dy[box, "C13"] + F_C * ccx_const("R13_VPDB") * (1 + d13c / 1000)
    dy[box, "C14"] <<- dy[box, "C14"] + F_C * (1 + d14c / 1000)
    invisible(NULL)
  }

  # Resolved ONCE: the within-column limbs below and the interhemispheric limbs
  # after the loop must agree about which layer sinks and which way the cell
  # runs, and re-deriving it in two places is how they would drift apart.
  cg <- ccx_conveyor_geom(p, grid)

  for (hi in seq_along(HEMIS)) {
    h    <- HEMIS[hi]
    iatm <- aux$idx[[h]]$atm
    ilef <- aux$idx[[h]]$leaf; iwod <- aux$idx[[h]]$wood
    isf  <- aux$idx[[h]]$soil_fast; iss <- aux$idx[[h]]$soil_slow
    iml  <- aux$idx[[h]]$ml
    ioc  <- aux$idx[[h]]$oc

    chi <- y[iatm, "C"] / aux$gtc_per_ppm_hemi          # ppm in this hemisphere

    # ---- land -------------------------------------------------------
    # PRODUCTIVE CAPACITY. NPP scales partly with the standing vegetation stock,
    # so clearing a forest reduces what the land can fix. Without this the
    # land-use debit (see the emissions block) removes veg CARBON but not veg
    # CAPACITY, and the land over-recovers.
    #
    # `npp_veg_frac` (phi) is PARTIAL because leaf area saturates with biomass,
    # so productivity is sub-linear in standing stock rather than proportional
    # to it. It is NOT partial for stability.
    #
    # A DECOUPLED STABILITY ARGUMENT FOR phi < 1/f WAS WRONG, and the correction
    # is worth keeping. Under the previous SINGLE vegetation pool, spinup set
    # veg0 = npp0 * tau_veg exactly, so the veg coefficient was (phi*f - 1)/tau_veg
    # and the algebra predicted divergence for phi*f > 1. It did not happen:
    # diag_land_structure.R [1] ran phi up to 1.10 (phi*f = 1.25) and every case
    # was stable, because chi is NOT exogenous -- a growing vegetation pool draws
    # CO2 down, which lowers f, a negative feedback the fixed-chi algebra omits.
    # With TWO vegetation pools the decoupled coefficient on wood is
    #   (1 - npp_leaf_frac) * f * phi / (npp_leaf_frac * tau_leaf
    #                                    + (1 - npp_leaf_frac) * tau_wood)
    #   - 1 / tau_wood,
    # i.e. the same shape and the same order of magnitude, and the same CO2
    # feedback still sits underneath it.
    # Do not reinstate a hard phi bound without re-running that diagnostic.
    #
    # CAPACITY IS KEYED ON TOTAL STANDING VEGETATION, leaf plus wood, against the
    # same total at spinup. Keying it on wood alone would make the fast leaf pool
    # invisible to the feedback; keying it on leaf alone would make LUC -- which
    # debits wood -- cost no capacity at all, which is the thing the term exists
    # to prevent.
    # CONVERTED LAND. `npp_veg_frac` above makes clearing cost capacity only
    # while the vegetation stock is DOWN -- and the stock comes back, because
    # the pools relax to a fixed point that does not know a forest became a
    # field. Measured: land-use emissions had an airborne fraction of 0.002 at
    # 100 years, against 0.262 for a fossil emission on the same background
    # (calibration/diag_1900_deficit.R, 2026-08-13). The land took back every
    # tonne deforestation released, which is the regrowth GCB's NET E_LUC has
    # already subtracted, applied a second time.
    #
    # So the FIXED POINT itself has to move. Cumulative land-use carbon defines
    # a cleared fraction, and npp0 -- which sets every land pool's equilibrium
    # -- is scaled by what is left. `veg0` is scaled with it so the capacity
    # term keeps measuring the remaining vegetation against the equilibrium of
    # the remaining LAND, not against a forest that no longer exists; without
    # that, capacity would read the debited stock as a deficit and drive NPP up
    # exactly when the land has less of it.
    #
    # WHY THE DENOMINATOR IS `land0` AND NOT `veg0`: see the aux note. It is
    # what makes the debit permanent in TOTAL rather than by a quarter.
    #
    # WHAT THIS DOES *NOT* CLAIM. The debit still comes out of wood alone
    # (Marcus 2026-08-12: deforestation removes standing woody biomass, and the
    # emitted carbon should carry that pool's lagged 14C), while the
    # equilibrium falls across all four pools pro rata. So wood is left BELOW
    # its new equilibrium and the soils ABOVE theirs, and the internal
    # redistribution that follows is a real deforestation legacy -- fast
    # regrowth against slow passive-soil drainage -- not an artefact. It nets
    # to zero in total carbon by construction; its TIMING is a model claim and
    # is what test-luc-permanence.R measures rather than assumes.
    cleared <- min(p$f_luc_perm * ccx_forcing_cum_luc(forc)[[h]] / aux$land0[[h]],
                   CCX_LUC_CLEARED_MAX)
    npp0_h  <- aux$npp0[[h]] * (1 - cleared)
    veg0_h  <- aux$veg0[[h]] * (1 - cleared)

    veg_C <- y[ilef, "C"] + y[iwod, "C"]
    capacity <- (1 - p$npp_veg_frac) + p$npp_veg_frac * veg_C / veg0_h
    # FERTILISATION -- the form is selected by p$fert_form, and the ONE
    # implementation lives in ccx_fert_factor() so this line and the C++ core
    # cannot drift apart from the diagnostics that price them.
    # VOLCANIC DIFFUSE-LIGHT FERTILISATION -- twin of the block in
    # src/ccx_core.cpp. Absence of the column reads as zero, and gamma_diff
    # defaults to 0, so this line is an identity unless BOTH are supplied.
    aod_h <- forc[[paste0("aod_", h)]]          # h is "NH"/"SH", as enso_share is
    if (is.null(aod_h) || !is.finite(aod_h)) aod_h <- 0
    gdiff <- if (is.null(p$gamma_diff)) 0 else p$gamma_diff
    npp <- npp0_h * capacity * ccx_fert_factor(chi, p, aux$chi0) *
      (1 + gdiff * aod_h)

    # GROSS PHOTOSYNTHESIS AND AUTOTROPHIC RESPIRATION. `ra_ratio` is Ra/NPP, so
    # GPP = NPP * (1 + ra_ratio) down and Ra = NPP * ra_ratio back up. The NET
    # atm->veg carbon flux is exactly NPP either way, so the CARBON budget is
    # untouched by this parameter -- and so is the 13C steady state, since at
    # equilibrium r_veg = r_atm * alpha_photo makes the net 13C flux npp * r_atm *
    # alpha again. What it changes is the GROSS isotope exchange, which is what
    # sets how fast veg equilibrates with the atmosphere.
    #
    # WHAT ra_ratio MEANS, and why it is not simply Ra/NPP from the literature
    # (Marcus 2026-08-12): GPP is not one thing. Respiration of carbon fixed days
    # ago still carries the ATMOSPHERE's ratio, so returning it is a null loop
    # that equilibrates nothing. Respiration drawing on the plant's stored carbon
    # carries the POOL's ratio, and that is the ocean-gross-exchange analogue
    # which equilibrates isotopes faster than the net flux. add_flux takes the
    # source box's ratio, i.e. the second case -- so ra_ratio is the fraction of
    # GPP that genuinely cycles THROUGH the vegetation pool, and Marcus' two
    # regimes are its endpoints (0 = null loop, literature Ra/NPP = upper bound).
    # Leaf growth-and-decay is NOT this flux: it is already the leaf -> soil ->
    # atm cascade below, lagged rather than equilibrating.
    #
    # APPLIED PER VEGETATION POOL, at each pool's own share of NPP, so the
    # returning carbon carries the ratio of the pool it actually came from.
    # Routing the whole loop through one pool would let wood's lagged ratio leak
    # into a flux that is physically leaf-dominated.
    #
    # Default 0 reproduces a model with no gross loop. The value is for the 14C
    # data to choose, not for this file to assume.
    npp_leaf <- npp * p$npp_leaf_frac
    npp_wood <- npp * (1 - p$npp_leaf_frac)
    ra_leaf  <- npp_leaf * p$ra_ratio
    ra_wood  <- npp_wood * p$ra_ratio
    # alpha13_signed, reason (a): ONE-WAY BY CONSTRUCTION. Photosynthesis only
    # ever runs atmosphere -> vegetation; these go negative only if `npp` does,
    # i.e. if a diverging stage has driven CO2 below zero. Declared so that such
    # a state keeps returning its old (rejected) value instead of becoming a
    # hard stop -- the guard must not quietly shrink the optimiser's feasible
    # set, which is how the pre-2026-08-11 substep wall truncated the posterior.
    add_flux(iatm, ilef, npp_leaf + ra_leaf, alpha13 = aux$alpha_photo,
             alpha13_signed = TRUE)                                      # GPP, leaf
    add_flux(ilef, iatm, ra_leaf)                                        # Ra, at leaf's ratio
    add_flux(iatm, iwod, npp_wood + ra_wood, alpha13 = aux$alpha_photo,
             alpha13_signed = TRUE)                                      # GPP, wood
    add_flux(iwod, iatm, ra_wood)                                        # Ra, at wood's ratio

    # LITTER. Both vegetation pools shed into the SAME two soil pools, split by
    # litter_slow_frac. The split is applied to each source separately rather
    # than to a pooled total, because the two sources carry different 14C ratios
    # and pooling them first would average those ratios before the split.
    lit_leaf <- y[ilef, "C"] / p$tau_leaf
    lit_wood <- y[iwod, "C"] / p$tau_wood
    add_flux(ilef, isf, lit_leaf * (1 - p$litter_slow_frac))
    add_flux(ilef, iss, lit_leaf * p$litter_slow_frac)
    add_flux(iwod, isf, lit_wood * (1 - p$litter_slow_frac))
    add_flux(iwod, iss, lit_wood * p$litter_slow_frac)

    # HETEROTROPHIC RESPIRATION, both soil pools, same q10. The passive pool's
    # temperature sensitivity is not separately identified by anything the model
    # is calibrated against, so it shares the parameter rather than inventing a
    # second one that the data cannot constrain.
    q10f <- p$q10^(forc$gmst / 10)
    # DRIVER PATH: respiration breathes with the seasonal land temperature,
    # through the SAME q10, unit-annual-mean so the budget is untouched (see
    # the CCX_SEAS_PHI_EFF block). Sine path (seas_drivers = 0): unmodulated,
    # bit-identical to the pre-2026-08-18 model.
    if (isTRUE(p$seas_drivers > 0)) {
      a_t  <- if (h == "NH") p$seas_T_amp_NH else p$seas_T_amp_SH
      # HEMISPHERE SIGN, and it is load-bearing: austral summer is in January,
      # so the SH seasonal temperature is the NH's ANTIPHASE. Without the sign
      # the SH respiration cycle peaks in austral WINTER -- and because the
      # amplitude is log-transformed (positive-only), no sampler could repair
      # the phase; it could only shrink the amplitude to zero. Caught
      # 2026-08-18 before any refit ran. The norm needs no sign: the annual
      # mean of q10^(A sin) equals that of q10^(-A sin) by symmetry.
      sgn  <- if (h == "NH") 1 else -1
      nrm  <- ccx_seas_norms(p)[[h]]
      q10f <- q10f * p$q10^(sgn * a_t * sin(2 * pi * (t - (3.5 + CCX_SEAS_T_LAG) / 12)) / 10) / nrm$r
    }
    add_flux(isf, iatm, (y[isf, "C"] / p$tau_soil_fast) * q10f)
    add_flux(iss, iatm, (y[iss, "C"] / p$tau_soil_slow) * q10f)

    # ---- seasonal NEP through the LEAF pool: the drawdown is foliage growth
    # and senescence, which is what that pool is.
    if (isTRUE(p$seas_drivers > 0)) {
      # DRIVER PATH: npp * (n(t) - 1), n = phenology-lagged insolation at the
      # effective latitude, unit annual mean. The amplitude is NOT a knob: it
      # is the model's own NPP, so fertilisation grows the cycle and clearing
      # shrinks it -- the old npp/npp0 scaling, now carried by npp itself.
      nrm  <- ccx_seas_norms(p)[[h]]
      seas <- (if (h == "NH") p$seas_npp_amp_NH else p$seas_npp_amp_SH) * npp *
        (ccx_insol(CCX_SEAS_PHI_EFF[[h]], t - p$seas_lag_p / 12) / nrm$n - 1)
    } else {
      amp   <- if (h == "NH") p$seas_amp_NH else p$seas_amp_SH
      phase <- if (h == "NH") p$seas_phase_NH else p$seas_phase_SH
      # DENOMINATOR IS THE UNCLEARED npp0, deliberately. The seasonal amplitude
      # tracks how much the land is fixing, so clearing land must SHRINK it;
      # dividing by the cleared npp0_h would hold the ratio near 1 and keep a
      # forest's seasonal cycle on a field.
      seas <- amp * sin(2 * pi * (t - phase / 12)) * (npp / aux$npp0[[h]])
    }
    # PHOTOSYNTHESIS DISCRIMINATES; RESPIRATION DOES NOT. `seas` is ZERO-MEAN by
    # construction, so it is negative for half of every year, and add_flux
    # resolves a negative flux by swapping the SOURCE box (see its header) --
    # the autumn limb is carbon leaving the leaf pool at the leaf pool's own
    # ratio. Applying alpha_photo to it discriminated that carbon a SECOND time.
    #
    # FIXED 2026-08-25e. It had been wrong since the flux was written, and the
    # receipt needs no model: a closed two-box system with one zero-mean
    # sinusoid returned carbon to 9e-13 GtC and drifted d13C by -0.124 permil
    # PER CYCLE, forever, pumping the atmosphere light and the leaf pool heavy.
    # At the pre-fix mode the leaf pool sat +5.000 permil above r_atm*alpha,
    # flat across 1770/1860/1960/2014 -- that offset WAS the bug. After the fix
    # it is +0.012 to +0.025 permil, i.e. the leaf tracks equilibrium as a
    # ~4-month pool must. calibration/diag_seas_isotope_rectification.R.
    #
    # WHY THIS FORM AND NOT TWO EXPLICIT LIMBS, which would read better and give
    # identical numbers: the two-limb version swaps `from`/`to` and so re-enters
    # ccx_flux_channel() with the opposite sign, silently changing what the
    # `seas` channel means in the flux trace and in test-fluxes.R.
    #
    # WHY NOT alpha on BOTH halves at the ATMOSPHERE's ratio (the "modulation of
    # gross photosynthesis" reading): the leaf pool's CARBON oscillates by 38 %
    # of its own mass peak-to-trough, so carbon really does flow leaf -> atm
    # here. A GPP modulation never reverses its flux; adopting it would mean
    # changing the CARBON side too, by folding `seas` into the GPP limb above.
    add_flux(iatm, ilef, seas,
             alpha13 = if (seas > 0) aux$alpha_photo else 1, lab = "seas")

    # ---- ENSO: land -> atmosphere anomaly (El Nino = source) ---------
    # Out of the RESPONSIVE soil pool. The interannual anomaly is drought and
    # fire-driven respiration of recently fixed carbon, not a draw on the
    # millennial passive pool.
    if (aux$enso_share[[h]] != 0) {
      add_flux(isf, iatm, p$gamma_enso * forc$enso * aux$enso_share[[h]],
               lab = "enso")
    }

    # ---- air-sea ----------------------------------------------------
    # Annual-mean SST: observed (HadSST4 columns) when the switch is on AND the
    # forcing carries them; otherwise the legacy linear-in-GMST map. Hand-built
    # test forcings carry no columns and land on the fallback unchanged.
    sa <- forc[[paste0("sst_anom_", h)]]
    sst <- aux$sst[[h]] +
      (if (isTRUE(p$sst_obs > 0) && !is.null(sa) && is.finite(sa)) sa
       else p$sst_scale * forc$gmst)
    # Seasonal SST, under the SAME seas_drivers switch as the land drivers --
    # so ccx_spinup()'s zeroing covers it and seas_drivers = 0 stays the exact
    # pre-2026-08-18 model. Zero-mean sine; the annual-mean pCO2 shift it
    # induces through carbonate-chemistry nonlinearity (~(0.042 A)^2/4, a few
    # tenths of a percent) is ACCEPTED as physics, the same call as the
    # fertilisation rectifier -- the driver is zero-mean, the response is not.
    # Hemisphere sign as for the land T: austral summer is January.
    if (isTRUE(p$seas_drivers > 0)) {
      a_s <- if (h == "NH") p$sst_seas_amp_NH else p$sst_seas_amp_SH
      sst <- sst + (if (h == "NH") 1 else -1) * a_s *
             sin(2 * pi * (t - (3.5 + CCX_SST_SEAS_LAG) / 12))
    }
    dic_ml <- y[iml, "C"] * aux$mol_per_GtC / aux$ml_mass_kg[[h]]   # mol/kg
    # SOUTHERN-OCEAN ENTRAINMENT CHANNEL (2026-08-27g, 4a). SH only; see
    # CCX_ENT_SEAS_PEAK_MO for the measurement and the NH control that says
    # the NH gets no twin. Under the SAME seas_drivers switch as every other
    # seasonal driver, so ccx_spinup()'s zeroing covers it and seas_drivers = 0
    # is still the exact aseasonal model.
    #
    # WHAT IT DOES AND DOES NOT DO. It perturbs the DIC that enters the pCO2
    # calculation; it does NOT touch the state vector, so it moves no carbon
    # vertically and adds no box -- this is version 4a, a seasonal-flux channel,
    # NOT a second ocean column. It reaches the atmosphere only through the
    # evasion limb below, which already carries aux$alpha_as_up, so the carbon
    # it adds is OCEAN-signatured. That is the entire point: the model's SPO
    # seasonal cycle is too photosynthetic, and this is the one channel that can
    # add ocean-signatured CO2 in austral winter.
    #
    # The driver is zero-mean; the response is not, because carbonate chemistry
    # is nonlinear in DIC. That rectification is ACCEPTED AS PHYSICS -- the same
    # call already made for the seasonal SST term ten lines up and for the
    # fertilisation rectifier. It is the ocean's own nonlinearity, not an
    # artefact of the discretisation.
    #
    # The peak month is absolute (no hemispheric sign flip): a sine peaks a
    # quarter cycle after its zero crossing, so peak month M is phase M/12-1/4.
    if (isTRUE(p$seas_drivers > 0) && h == "SH" && !is.null(p$ent_seas_amp_SH) &&
        p$ent_seas_amp_SH != 0) {
      dic_ml <- dic_ml + p$ent_seas_amp_SH * 1e-6 *
                sin(2 * pi * (t - (CCX_ENT_SEAS_PEAK_MO / 12 - 0.25)))
    }
    k      <- carb_constants(sst)
    pco2_ml <- if (isTRUE(p$revelle_frozen > 0)) {
      # Buffer factor pinned at its preindustrial value: pCO2 responds to DIC
      # linearly, with the slope the ocean HAD in 1750 and never loses. The
      # ocean therefore keeps absorbing at its preindustrial efficiency.
      aux$pco2_0[[h]] * (1 + aux$revelle0[[h]] * (dic_ml - aux$dic0[[h]]) / aux$dic0[[h]])
    } else {
      pco2_from_dic(dic_ml, ccx_const("ALK_SURFACE"), sst, k = k)
    }
    pco2_at <- chi                                                  # ppm ~ uatm at 1 atm
    # GROSS both ways (see add_flux header): invasion and evasion separately.
    gx <- aux$asx[[h]] * p$k_w * k$K0
    # alpha13_signed, reason (a): ONE-WAY BY CONSTRUCTION. gx > 0 always, so
    # these go negative only when pCO2 itself does, i.e. in a diverging
    # intermediate state that ccx_run_fast() is about to reject. The two limbs
    # already carry their own directional alphas, which is the correct pattern.
    add_flux(iatm, iml, gx * pco2_at, alpha13 = aux$alpha_as_down,
             alpha13_signed = TRUE)                                  # invasion
    add_flux(iml, iatm, gx * pco2_ml, alpha13 = aux$alpha_as_up,
             alpha13_signed = TRUE)                                  # evasion

    # ---- ARTIFICIAL MID-CENTURY OCEAN SINK (2026-08-23c) -------------
    # OFF unless the forcing carries a non-zero `sink_ocean`, which only
    # happens under CCX_SINK_RATE != 0 AND CCX_SINK_MODE == "ocean". See the
    # constants block in R/forcing.R for the three arms and what they test.
    #
    # WHY IT IS HERE AND NOT IN THE EMISSIONS. The hypothesis is an ocean
    # UPTAKE, not a smaller emission, and the two differ ONLY isotopically --
    # which is the whole discriminator. Emitted through add_flux so it is
    # conservative by the same construction as every other flux in this
    # function, takes 13C at the SOURCE (atmosphere) ratio with the model's own
    # air-sea downward fractionation, and carries 14C UNFRACTIONATED at the
    # source ratio (Stuiver-Polach, DESIGN sec.3.5). That last property is the
    # pre-registered prediction: removing carbon at the atmosphere's OWN 14C/C
    # leaves D14C nearly untouched, where removing 14C-free fossil carbon
    # raises it by ~10 permil. `alpha_as_down` is REUSED, not invented -- it is
    # the same factor the invasion limb two lines up already applies, and
    # reusing it is what makes this an ocean uptake rather than a number
    # somebody chose.
    #
    # SPLIT ON OCEAN AREA (aux$asx, which is area x rho / mol_per_GtC and so is
    # proportional to a_oc), NOT on the fossil share: the fossil share is where
    # the coal is burned and has nothing to do with where the ocean takes up.
    #
    # `lab` is deliberately NULL, so the flux trace classifies it as `as_down`
    # and `ocean_net` counts it. It IS an atmosphere -> mixed-layer flux; giving
    # it a private channel would leave the derived net ocean uptake wrong by
    # exactly the sink whenever the instrument is on.
    sk <- forc$sink_ocean
    if (!is.null(sk) && is.finite(sk) && sk != 0) {
      # alpha13_signed, reason (a): one-way by construction -- `sk` is a
      # prescribed uptake and is checked non-zero above; a negative value would
      # be a broken forcing, not a reversal.
      add_flux(iatm, iml,
               sk * aux$asx[[h]] / (aux$asx$NH + aux$asx$SH),
               alpha13 = aux$alpha_as_down, alpha13_signed = TRUE)
    }

    # ---- ocean interior diffusion -----------------------------------
    # F = Kz (C_k/dz_k - C_k+1/dz_k+1) / dz_mid  -- area cancels, exactly
    # conservative, and each flux is applied to both layers by add_flux.
    col <- c(iml, ioc)
    for (kk in seq_len(grid$nl)) {
      add_diffusion(col[kk], col[kk + 1], grid$dz[kk], grid$dz[kk + 1], aux$dz_mid[kk])
    }

    # ---- the biological pump: mixed layer -> interior, per box --------
    # TWO LIMBS, and the split is an OBSERVATION rather than a knob: GLODAP's
    # alkalinity gradient pins the carbonate share at ~23 % (DESIGN sec.5.2d).
    # They differ ONLY in their 13C signature, which is the whole reason both
    # are needed -- soft tissue is ~20 permil DEPLETED relative to the DIC it is
    # fixed from, biogenic CaCO3 is slightly ENRICHED. A single-limb pump sized
    # to the DIC row overshoots the d13C row by 1.37x
    # (calibration/diag_pump_vs_gradient_terms.R).
    #
    # 14C RIDES BOTH LIMBS UNFRACTIONATED, by the Stuiver-Polach convention the
    # rest of the model uses (DESIGN sec.3.5): Delta14C observations are already
    # fractionation-corrected. add_flux does exactly that.
    #
    # EMITTED THROUGH add_flux, NOT by touching dy: that makes the pump
    # conservative by the same construction as every other flux here, carries
    # both isotopes at the SOURCE box's ratio, and puts it in the flux trace
    # (the shim in calibration/pump_shim.R could do none of these -- it stopped
    # with an error under record = TRUE).
    #
    # `is.null(aux$pump)` emits nothing at all, so the no-pump model is BIT-
    # reproduced. Same contract as w_up = 0 below.
    if (!is.null(aux$pump)) {
      pf <- aux$pump[[h]]
      # NUTRIENT-LIMITED ("N"): export mass fixed, the standard steady-pump
      # assumption. DIC-LIMITED ("D"): export scales with the mixed layer's
      # carbon, the ONLY channel through which the pump touches uptake.
      sc <- if (identical(p$pump_mode, "D")) y[iml, "C"] / aux$ml_C0[[h]] else 1
      for (kk in seq_len(grid$nl)) {
        # alpha13_signed: GRANDFATHERED 2026-08-25e, BEHAVIOUR UNCHANGED, AND
        # OPEN. `S[k]` is built in ccx_pump_export() as the DIVERGENCE of the
        # diffusive flux that would hold the observed DIC profile, so it is
        # NEGATIVE by construction in some layers -- 2 of 10 at the adopted
        # mode, carrying 0.4 % of the field's gross magnitude (0.039 of 9.58
        # GtC/yr). The field does NOT sum to zero: it nets +12.3 GtC/yr into
        # the interior, balanced in steady state by upward diffusion.
        # The add_flux guard fires here, correctly: on a negative layer this sends carbon
        # UP to the mixed layer and depletes it by a further eps_org, which is
        # not what "organic matter sinks and remineralises" means.
        #
        # NOT CHANGED HERE, because unlike the seasonal-NEP case it is not
        # obvious what the reverse limb should be -- a negative S[k] is an
        # artifact of the divergence construction rather than a named process,
        # and PUMP_EPS13_ORG is itself flagged "provisional, recollected, NEEDS
        # a cited source" in constants.R. Priced in
        # calibration/diag_pump_signed_alpha.R; Marcus's call.
        add_flux(iml, ioc[kk], pf$org[kk] * sc,
                 alpha13 = 1 + ccx_const("PUMP_EPS13_ORG") / 1000, lab = "pump",
                 alpha13_signed = TRUE)
        add_flux(iml, ioc[kk], pf$carb[kk] * sc,
                 alpha13 = 1 + ccx_const("PUMP_EPS13_CARB") / 1000, lab = "pump",
                 alpha13_signed = TRUE)
      }
    }

    # ---- ocean overturning (advective, NOT a second diffusivity) -----
    # Water upwells through EVERY interface at the same velocity w_up and
    # returns from the mixed layer to the bottom box in one step ("polar
    # sinking"). That is the classical upwelling-diffusion column
    # (Hoffert et al. 1980; Harvey & Schneider 1985), and it is ONE parameter.
    #
    # WHY IT IS NOT DIFFUSION. Diffusion is local and symmetric: it can only
    # smear a surface signal downward through adjacent layers, so the water in
    # contact with the atmosphere is always water that has already been partly
    # loaded. Advection is directional and NON-LOCAL: the upwelling limb
    # continually presents water that left the surface ~depth/w_up years ago and
    # is therefore still isotopically preindustrial, while the sinking limb
    # removes loaded surface water to the bottom without passing it through the
    # layers in between. It is the renewal RATE of the surface reservoir that
    # this changes, not its size -- which is exactly the axis diag_d13c_levers.R
    # found the model short on (h_ml, the size axis, moves the d13C bias 0.085
    # permil across 30-200 m; k_w, the rate axis, needs 2.7x Wanninkhof).
    #
    # CARRIED AT THE SOURCE BOX'S RATIO, unfractionated, because this is bulk
    # water transport: it moves DIC and both isotopes together. add_flux does
    # exactly that, so the transport is conservative by the same construction as
    # every other flux here.
    #
    # VOLUME IS CONSERVED: every interface carries the same volume flux
    # w_up * A upward, and the pipe returns w_up * A from the mixed layer to the
    # bottom. So a column at UNIFORM CONCENTRATION is still an exact fixed point
    # -- which is what lets ccx_spinup()'s analytic 12C equilibrium stand
    # unchanged (see its ocean block).
    #
    # w_up = 0 emits nothing, so the pure-diffusion model is bit-reproduced.
    # `isTRUE`, not `>`, so a parameter list built before 2026-08-13 (no w_up at
    # all) is the pure-diffusion model rather than an error -- the same
    # convention `revelle_frozen` uses above.
    if (isTRUE(p$w_up > 0)) {
      for (kk in seq_len(grid$nl)) {                       # upwelling limb
        add_flux(col[kk + 1], col[kk], p$w_up * y[col[kk + 1], "C"] / grid$dz[kk + 1])
      }
      add_flux(iml, col[grid$nl + 1], p$w_up * y[iml, "C"] / grid$dz[1])  # sinking
    }

    # ---- ocean outcropping: the non-local limb runs UPWARD ------------
    # THE MIRROR IMAGE OF `w_up`, AND NOT A RELABELLING OF IT. Here the deep box
    # ventilates to the mixed layer in ONE step, and the compensating flow
    # descends through every interface. Which limb is the non-local one decides
    # everything, in both directions:
    #
    #   WHAT ARRIVES AT THE SURFACE. Under `w_up` the mixed layer is renewed from
    #   the layer directly beneath it -- and that layer is diffusively slaved to
    #   the mixed layer (kz/(dz dz_mid) ~ 1.5/yr at kz 5000), so the water
    #   arriving is already loaded and carries almost no disequilibrium
    #   (measured: an ml-to-oc1 d13C gap of 0.167 permil). Here the arriving
    #   water comes from the bottom box, which the anthropogenic signal has not
    #   reached, so it carries the FULL preindustrial contrast.
    #
    #   WHAT HAPPENS TO THE DEEP OCEAN. Under `w_up` the sinking limb injects
    #   modern surface water straight into the bottom box, which destroys the
    #   deep 14C age within decades (-170 -> -100 permil at 4 m/yr). Here the
    #   descending limb has to traverse the whole column, ~depth/w_out years, so
    #   over the industrial period the bottom box never sees the perturbation --
    #   and in the preindustrial steady state the water ages monotonically
    #   downward, which is the observed sense of the profile rather than its
    #   inverse.
    #
    # PER HEMISPHERE, because the real outcrop is a Southern Ocean feature and
    # the two ocean columns exchange only through the atmosphere.
    w_out <- if (h == "NH") p$w_out_NH else p$w_out_SH
    if (isTRUE(w_out > 0)) {
      ideep <- col[grid$nl + 1]
      add_flux(ideep, iml, w_out * y[ideep, "C"] / grid$dz[grid$nl + 1])  # outcrop
      for (kk in seq_len(grid$nl)) {                       # distributed return
        add_flux(col[kk], col[kk + 1], w_out * y[col[kk], "C"] / grid$dz[kk])
      }
    }

    # ---- THE CONVEYOR: the two WITHIN-COLUMN limbs -------------------
    # The other two limbs are interhemispheric and are emitted OUTSIDE this
    # loop, next to tau_ex -- see there. Splitting them is not cosmetic: the
    # two ocean columns are indexed per hemisphere and only the code outside
    # this loop can see both at once.
    #
    # The effective velocity is Q / A_h, so the SAME volume flux gives the
    # smaller-area NH the faster limb. That asymmetry is the mechanism, not an
    # artefact: it is why the conveyor is predicted to shrink the NH-SH d13C
    # gradient (handoff 13b sec.4.4), which the likelihood already scores.
    if (!is.null(cg)) {
      w <- cg$Q / aux$a_oc[[h]]
      if (h == cg$down) {
        # SINKING. Non-local by default: NADW forms in a narrow region and sinks
        # fast, so the plume does not equilibrate with the layers it passes.
        # `conv_descent = 1` spreads it layer by layer instead (Config B), which
        # removes the advectively dead interior Config A leaves behind.
        if (cg$distributed) {
          for (kk in seq_len(cg$s))
            add_flux(col[kk], col[kk + 1], w * y[col[kk], "C"] / grid$dz[kk])
        } else {
          add_flux(iml, col[cg$s + 1], w * y[iml, "C"] / grid$dz[1])
        }
      } else {
        # UPWELLING, always broad and distributed -- the return limb of the real
        # cell is slow and spread over the whole basin. Runs from the sink layer
        # to the mixed layer; layers BELOW it are left to diffusion, which is
        # the abyss Config C deliberately does not ventilate.
        for (kk in seq_len(cg$s))
          add_flux(col[kk + 1], col[kk], w * y[col[kk + 1], "C"] / grid$dz[kk + 1])
      }
    }

    # ---- prescribed emissions ---------------------------------------
    # Fossil carbon comes from OUTSIDE the modelled system (geology), so it is a
    # true external source, and it is 14C-free.
    #
    # Its d13C is TIME-VARYING (2026-08-12) and arrives on the forcing table,
    # not in `aux`: the emission-weighted fuel mix moved from ~-24 permil in
    # 1850 (all coal) to ~-28 today (gas and cement in the total). Holding it at
    # a single modern value made the Suess decline ~30 % too steep -- see
    # calibration/diag_d13c_suess.R and forcing.R's note.
    add_source(iatm, forc$e_foss[[h]], ccx_forcing_d13c_foss(forc), -1000)
    # Land-use change does NOT: it moves carbon that is already in the modelled
    # biosphere. Emitting it with add_source() while leaving the vegetation box
    # intact created carbon AND 14C ex nihilo -- ~28 kmol of 14C by 1995, 14-16 %
    # of the system excess (diag_excess_c14.R [2], 2026-08-12). As a transfer it
    # is conservative by construction, and add_flux carries the source pool's OWN
    # 13C and 14C ratios, so the prescribed `d13c_bio` is no longer needed:
    # clearing a forest does not fractionate, hence alpha13 = 1 (the default).
    #
    # IT COMES OUT OF WOOD (Marcus 2026-08-12) at the default f_luc_wood = 1.
    # Deforestation removes standing woody biomass, so that is the pool that
    # should pay -- and it is the pool whose 14C ratio the emitted carbon should
    # carry, which is more lagged than the leaf pool's. Debiting leaf, or
    # debiting both pro rata, would let the fast pool absorb clearing it does
    # not physically suffer.
    #
    # AT f_luc_wood < 1 the remainder is split PRO RATA over the four pools by
    # ccx_luc_pool_shares(), which is the split that leaves every pool at its
    # new cleared equilibrium and so makes the debit permanent on the pools'
    # own timescales rather than only in total. It costs the 14C argument above:
    # the emitted carbon then carries a stock-weighted mixture dominated by the
    # slow soil. Handoff 13h sec.2.1b; measured in calibration/diag_luc_prorata.R.
    #
    # NOTE: historical e_luc is strictly positive. Should a scenario ever supply a
    # negative (net-regrowth) value, add_flux swaps the source correctly but the
    # uptake would not carry the photosynthetic fractionation it should.
    if (p$f_luc_wood >= 1) {
      add_flux(iwod, iatm, forc$e_luc[[h]], lab = "luc")
    } else {
      sh   <- ccx_luc_pool_shares(p)
      pool <- c(ilef, iwod, isf, iss)
      # wood's own share is (1 - f) * sh[2] from the pro-rata part PLUS all of
      # the f-weighted part; the others get only their (1 - f) pro-rata share.
      wts  <- (1 - p$f_luc_wood) * sh
      wts[2] <- wts[2] + p$f_luc_wood
      for (k in seq_along(pool))
        add_flux(pool[k], iatm, forc$e_luc[[h]] * wts[k], lab = "luc")
    }
  }

  # ---- interhemispheric atmospheric exchange -------------------------
  # Gross both ways, for the same reason as air-sea: the NH-SH isotope gradient
  # (the bomb-spike propagation signal) is set by gross exchange, not by the
  # small net flux.
  iN <- aux$idx$NH$atm; iS <- aux$idx$SH$atm
  add_flux(iN, iS, y[iN, "C"] / p$tau_ex)
  add_flux(iS, iN, y[iS, "C"] / p$tau_ex)

  # ---- THE CONVEYOR: the two INTERHEMISPHERIC limbs ------------------
  # Emitted here, not in the hemisphere loop, because they are the first
  # ocean-ocean coupling in the model and the loop can only see one column.
  #
  # Note what these two limbs do to the sec.2 symmetry argument. The deep limb
  # exports the sinking hemisphere's water to the OTHER hemisphere's interior,
  # where no diffusive path returns it -- that is what makes each column an OPEN
  # system, and it is why the outcrop configuration tied classic upwelling while
  # this does not. The surface return then gives the ocean a SECOND box in
  # contact with an atmosphere. Both premises of the theorem are gone, so
  # reversing the cell must change what the atmosphere sees; test-conveyor.R
  # asserts exactly that, and a TIE means the wiring is wrong.
  #
  # Concentration is per unit VOLUME here, hence the division by area as well as
  # thickness -- unlike the within-column limbs, where the hemisphere's area
  # cancels between the two boxes.
  if (!is.null(cg)) {
    i_deep_dn <- aux$idx[[cg$down]]$oc[cg$s]
    i_deep_up <- aux$idx[[cg$up]]$oc[cg$s]
    add_flux(i_deep_dn, i_deep_up,
             cg$Q * y[i_deep_dn, "C"] / (aux$a_oc[[cg$down]] * grid$dz[cg$s + 1]))
    add_flux(aux$idx[[cg$up]]$ml, aux$idx[[cg$down]]$ml,
             cg$Q * y[aux$idx[[cg$up]]$ml, "C"] / (aux$a_oc[[cg$up]] * grid$dz[1]))
  }

  # ---- 14C sources (mol/yr -> GtC-equivalent units) and decay ---------
  # A mol of pure 14C carries R14_STD^-1 times as much "C14 signal" as a mol of
  # standard-ratio carbon, hence the division by R14_STD.
  c14_to_state <- 1 / (aux$mol_per_GtC * ccx_const("R14_STD"))
  dy[aux$idx$NH$atm, "C14"] <- dy[aux$idx$NH$atm, "C14"] +
    (forc$c14_bomb * aux$bomb_share_NH + forc$c14_nuclear * aux$nuc_share_NH +
       forc$c14_cosmo * 0.5) * c14_to_state
  dy[aux$idx$SH$atm, "C14"] <- dy[aux$idx$SH$atm, "C14"] +
    (forc$c14_bomb * (1 - aux$bomb_share_NH) + forc$c14_nuclear * (1 - aux$nuc_share_NH) +
       forc$c14_cosmo * 0.5) * c14_to_state

  dy[, "C14"] <- dy[, "C14"] - ccx_const("LAMBDA_C14") * y[, "C14"]

  if (record) attr(dy, "fluxes") <- list(channels = .fx, boxnet = .net)
  dy
}

# ---------------------------------------------------------------------
# Precomputed invariants
# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
# THE BIOLOGICAL PUMP (task 9)
# ---------------------------------------------------------------------
# ZERO FITTED PARAMETERS IN THE FIELD ITSELF, which is the pump's whole claim to
# not being an arbitrary knob. The export profile is SOLVED as the field that
# makes GLODAPv2's observed DIC SHAPE an exact steady state of the model's own
# diffusion operator; only the gradient's MAGNITUDE (`pump_grad`) and its
# CARBONATE SHARE (`pump_carb_frac`, pinned by the alkalinity row) are set from
# outside, and the shape comes from a build product.
#
# THE SOLVE. Steady state needs the source in box k to cancel the diffusive
# convergence there: S_k = -[F(k-1,k) - F(k,k+1)], F(a,b) = kz (c_a - c_b)/dz_mid.
# The concentration the diffusion code sees is y_k/dz_k, and y_k is proportional
# to DIC_k * dz_k, so the layer thickness cancels exactly and this is arithmetic
# rather than a fit. The sum telescopes, so the TOTAL export leaving the mixed
# layer is the flux across the topmost interface alone.
#
# IT SCALES WITH kz, AND THAT IS A REAL PROPERTY RATHER THAN AN ARTEFACT. A 1-D
# effective diffusivity standing in for 3-D ventilation also destroys gradients,
# so holding a given gradient costs more export the larger kz is. At the
# pre-gradient mode this needs ~25 GtC/yr against a 5-12 GtC/yr literature POC
# export -- see DESIGN sec.5.2c. Do NOT read the solved export as an estimate of
# real POC export.

#' The observed DIC profile shape, integrated onto a model grid.
#'
#' Returns the layer-mean shape (0 at the mixed layer, 1 at the deepest bin),
#' length nl + 1. Depth-weighted, so a model layer spanning several observed
#' bins gets their thickness-weighted mean rather than a point sample.
ccx_pump_shape <- local({
  cache <- NULL
  function(grid) {
    if (is.null(cache)) {
      g <- tryCatch(readRDS(ccx_path("data", "obs_glodap_deep.rds")),
                    error = function(e) NULL)
      if (is.null(g) || is.null(g$dic_profile)) return(NULL)
      pr <- g$dic_profile
      # THE REMAP IS C1 IN EVERY LAYER BOUNDARY, ADOPTED 2026-08-29 (Marcus).
      #
      # It used to be a conservative OVERLAP INTEGRAL of the 25 m observed bins,
      #     ov <- pmax(0, pmin(b, pr$bot) - pmax(a, pr$top))
      # which is correct and conservative but treats the shape as piecewise
      # CONSTANT inside a bin. Its antiderivative is then only piecewise LINEAR,
      # so the layer mean (S(b)-S(a))/(b-a) has a SLOPE JUMP wherever a boundary
      # crosses a bin edge. `h_ml` IS the first boundary and the deeper ones
      # scale with it, so the log-posterior was not C1 in `h_ml`: 26 kinks over
      # the live support [30,200], clustered on the bin edges (50/75/100/125/
      # 150/175 m). That is the recorded reason there is no posterior --
      # `h_ml` is the softest direction of a Hessian conditioned 1.11e6.
      #
      # THE FIX INTERPOLATES THE CUMULATIVE INTEGRAL, NOT THE SHAPE. The bin
      # averages pin S EXACTLY at every bin EDGE, so a monotone C1 spline through
      # those edges (monoH.FC -- S is monotone because shape >= 0) is C1 AND
      # conservative: whenever a model layer spans whole bins this reproduces the
      # old overlap answer to machine precision (3.3e-16). Interpolating the
      # SHAPE through bin MIDPOINTS instead is C1 but NOT conservative (2.0e-3)
      # and overshoots 4x harder -- measured, and rejected for that reason.
      #
      # ⚠ THIS IS NOT A PURE CODE FIX AND WAS NOT ADOPTED AS ONE. It moves the
      # pump field by 9.6-15.8% of the median layer step (15.4% at the incumbent
      # mode), and the export is a DIFFERENCE of adjacent layers, so that is the
      # scale the pump uses. What a remap does BETWEEN bin edges is a SUB-BIN
      # MODEL the data do not contain: this one exceeds its local 3-bin range in
      # 10 of 29 intervals (worst 42% of a bin step at ~450 m, the thermocline),
      # and the old piecewise-CONSTANT assumption is equally absent from the data
      # and is exactly what made it kinked. Neither is "the observations".
      # Priced in calibration/diag_hml_c1_remap_price.R; adopted by Marcus.
      edge   <- c(pr$top[1], pr$bot)
      s_edge <- c(0, cumsum((pr$bot - pr$top) * pr$shape))
      cache <<- list(pr = pr, fS = stats::splinefun(edge, s_edge, method = "monoH.FC"),
                     z0 = edge[1], z1 = edge[length(edge)],
                     S0 = s_edge[1], S1 = s_edge[length(s_edge)],
                     sh0 = pr$shape[1], sh1 = pr$shape[nrow(pr)])
    }
    cc <- cache
    # Outside the observed span the shape is held FLAT, which reproduces the old
    # overlap function's own behaviour there (a layer entirely below the deepest
    # bin returned pr$shape[nrow(pr)]).
    Scum <- function(z) {
      if (z <= cc$z0) return(cc$S0 + (z - cc$z0) * cc$sh0)
      if (z >= cc$z1) return(cc$S1 + (z - cc$z1) * cc$sh1)
      cc$fS(z)
    }
    zb <- c(0, cumsum(grid$dz))
    vapply(seq_along(grid$dz), function(k) {
      a <- zb[k]; b <- zb[k + 1]
      if (b <= a) return(cc$sh1)
      (Scum(b) - Scum(a)) / (b - a)
    }, numeric(1))
  }
})

#' The pump's export fields, per hemisphere, in GtC/yr into each interior box.
#'
#' @return NULL when the pump is off (`pump_grad` == 0) -- and NULL is what makes
#'   ccx_deriv() emit no flux at all, so the pure-diffusion model is bit-
#'   reproduced rather than reproduced to within an epsilon. Otherwise
#'   list(NH = list(org =, carb =), SH = ...).
ccx_pump_export <- function(p, aux, grid) {
  if (!isTRUE(p$pump_grad > 0)) return(NULL)
  shape <- ccx_pump_shape(grid)
  if (is.null(shape)) return(NULL)
  # RE-NORMALISE ON THIS GRID'S OWN LAYERS, not on the build product's bins.
  # The stored shape spans exactly 1 between its first and last BIN, but a model
  # layer is a thickness-weighted average of several bins, so the bottom LAYER's
  # mean shape is not 1 (it reads 1.011 at h_ml = 100, which would deliver a
  # 235.7 umol/kg gradient for a pump_grad of 233.1). Dividing by the realised
  # span makes `pump_grad` mean exactly what its name says: the model's
  # preindustrial bottom-box-minus-mixed-layer DIC gradient, directly comparable
  # with the target the likelihood scores.
  span <- shape[length(shape)] - shape[1]
  if (!is.finite(span) || span <= 0) return(NULL)
  prof <- (shape - shape[1]) / span * p$pump_grad
  fc <- p$pump_carb_frac
  out <- lapply(HEMIS, function(h) {
    kappa <- aux$a_oc[[h]] * ccx_const("RHO_SEAWATER") / aux$mol_per_GtC
    cc <- kappa * prof * 1e-6                                # GtC/m
    Fi <- p$kz * (cc[-length(cc)] - cc[-1]) / aux$dz_mid     # nl interfaces
    S <- numeric(grid$nl)
    for (k in seq_len(grid$nl))
      S[k] <- -(Fi[k] - if (k < grid$nl) Fi[k + 1] else 0)
    list(org = S * (1 - fc), carb = S * fc)
  })
  names(out) <- HEMIS
  out
}

ccx_prepare <- function(p, grid = ccx_ocean_grid(p$h_ml)) {
  bn  <- ccx_box_names(grid$nl)
  idx <- lapply(HEMIS, function(h) {
    v <- list(
      atm  = which(bn == paste0(h, "_atm")),
      ml   = which(bn == paste0(h, "_ml")),
      oc   = which(bn %in% paste0(h, "_oc", seq_len(grid$nl))))
    for (pool in CCX_LAND_POOLS) v[[pool]] <- which(bn == paste0(h, "_", pool))
    # every land index in state order, for the callers that want the land as a
    # whole (spinup diagnostics, forcing.R's budget split)
    v$land <- unlist(v[CCX_LAND_POOLS], use.names = FALSE)
    v
  })
  names(idx) <- HEMIS

  a_oc <- list(NH = ccx_const("OCEAN_AREA_NH"), SH = ccx_const("OCEAN_AREA_SH"))
  npp0 <- list(NH = ccx_const("NPP_GLOBAL_PI") * p$npp_frac_NH,
               SH = ccx_const("NPP_GLOBAL_PI") * (1 - p$npp_frac_NH))

  # Preindustrial mixed-layer reference, for the frozen-Revelle switch. Computed
  # unconditionally (it costs two uniroot solves once per spinup) so the two code
  # paths cannot diverge in what they consider "preindustrial".
  sst_l <- list(NH = p$sst_NH, SH = p$sst_SH)
  alk   <- ccx_const("ALK_SURFACE")
  dic0  <- lapply(sst_l, function(T) ccx_dic_for_pco2(ccx_const("CO2_PI_PPM"), alk, T))
  rev0  <- lapply(HEMIS, function(h) revelle_factor(dic0[[h]], alk, sst_l[[h]]))
  names(rev0) <- HEMIS

  aux <- list(
    idx = idx,
    # each hemisphere holds half the atmosphere, so ppm per hemisphere uses half
    gtc_per_ppm_hemi = ccx_const("GtC_PER_PPM") / 2,
    chi0        = ccx_const("CO2_PI_PPM"),
    mol_per_GtC = ccx_const("MOL_C_PER_GtC"),
    npp0        = npp0,
    # preindustrial standing vegetation, LEAF PLUS WOOD, the reference for the
    # NPP capacity term. Must match ccx_spinup()'s land fixed point exactly, or
    # the spinup state stops being a fixed point of the derivative.
    veg0        = lapply(npp0, function(n)
                    n * (p$npp_leaf_frac * p$tau_leaf +
                         (1 - p$npp_leaf_frac) * p$tau_wood)),
    # TOTAL preindustrial land carbon -- all FOUR pools, not just vegetation.
    # This is the denominator of the cleared fraction (see the "converted land"
    # block in ccx_deriv()), and it has to be the total for the debit to come
    # out permanent: scaling npp0 by (1 - c) scales EVERY land pool's
    # equilibrium by (1 - c), so the land's equilibrium carbon falls by
    # c * land0. Setting c = cumLUC / land0 makes that fall equal the carbon
    # land-use change actually removed. Using veg0 here instead would shrink the
    # equilibrium by only a quarter of what was taken and the land would
    # re-absorb the rest.
    # Must match ccx_spinup()'s land fixed point exactly, same as veg0.
    land0       = lapply(npp0, function(n)
                    n * (p$npp_leaf_frac * p$tau_leaf +
                         (1 - p$npp_leaf_frac) * p$tau_wood +
                         (1 - p$litter_slow_frac) * p$tau_soil_fast +
                         p$litter_slow_frac * p$tau_soil_slow)),
    sst         = list(NH = p$sst_NH, SH = p$sst_SH),
    ml_mass_kg  = lapply(a_oc, function(A) A * grid$h_ml * ccx_const("RHO_SEAWATER")),
    # Preindustrial mixed-layer CARBON, GtC. Only the DIC-limited pump reads it,
    # as the denominator of its export scaling, and it is computed here so the
    # two pump modes cannot disagree about what "preindustrial" means.
    # setNames, NOT a bare lapply: HEMIS is an unnamed character vector, so
    # lapply over it returns an UNNAMED list and every `aux$ml_C0$NH` downstream
    # silently reads NULL. (The neighbouring entries get their names from the
    # named list they map over; this one has nothing to inherit from.)
    ml_C0       = stats::setNames(lapply(HEMIS, function(h)
                    dic0[[h]] * a_oc[[h]] * grid$h_ml * ccx_const("RHO_SEAWATER") /
                      ccx_const("MOL_C_PER_GtC")), HEMIS),
    # air-sea prefactor: A [m2] * K0 [mol/(kg atm)] * rho [kg/m3] -> GtC/(yr uatm)
    asx = lapply(a_oc, function(A)
      A * ccx_const("RHO_SEAWATER") / 1e6 / ccx_const("MOL_C_PER_GtC")),
    dz_mid = (grid$dz[-length(grid$dz)] + grid$dz[-1]) / 2,
    alpha_photo = 1 - 18 / 1000,     # provisional, see constants.R note
    # air-sea 13C fractionation differs by direction: kinetic on invasion,
    # equilibrium on evasion. With gross fluxes both must be carried separately
    # -- a single "net" alpha cannot represent the two-way exchange.
    alpha_as_down = 1 -  2 / 1000,   # provisional, kinetic (atm -> ocean)
    alpha_as_up   = 1 - 10 / 1000,   # provisional, equilibrium (ocean -> atm)
    # d13c_foss MOVED TO THE FORCING TABLE 2026-08-12. It was a single -28
    # permil here, applied from 1750 to 2024. That is not one value: the
    # emission-weighted fuel mix ran from ~-24 permil (1850, essentially all
    # coal) to ~-28 (today, gas and ~0 permil cement carbon in the total), and
    # holding the modern end fixed across the whole industrial period made the
    # modelled Suess decline ~30 % too steep -- obs - model growing to +0.58
    # permil at MLO by 2020. It is now built per year in
    # data-raw/build_calibration_data.R [5b] and carried on the forcing.
    # See calibration/diag_d13c_suess.R.
    #
    # d13c_bio removed 2026-08-12: LUC is now a transfer out of the vegetation
    # box, which carries its own emergent 13C ratio, so no prescribed value is
    # needed. Fossil carbon still needs one -- geology is outside the model.
    dic0        = dic0,
    revelle0    = rev0,
    pco2_0      = list(NH = ccx_const("CO2_PI_PPM"), SH = ccx_const("CO2_PI_PPM")),
    enso_share  = list(NH = 0.5, SH = 0.5),
    bomb_share_NH = 0.9,
    nuc_share_NH  = 0.95,
    # Ocean areas, needed by the conveyor's interhemispheric limbs: those are
    # the only fluxes in the model where the hemisphere's area does NOT cancel
    # between source and sink, so they need a true per-volume concentration.
    a_oc = a_oc,
    grid = grid
  )
  # THE PUMP IS SOLVED ONCE PER PREPARE, not once per derivative evaluation.
  # It needs `aux` (areas, dz_mid, mol_per_GtC), so it cannot be built inside the
  # list above -- and it must not be built inside ccx_deriv(), which runs four
  # times per RK4 substep. NULL when pump_grad == 0, which is what makes the
  # pure-diffusion model bit-reproduced rather than reproduced to an epsilon.
  aux$pump <- ccx_pump_export(p, aux, grid)
  aux
}

# ---------------------------------------------------------------------
# Integrator stability control
# ---------------------------------------------------------------------
# WHY THIS EXISTS. Interior diffusion is integrated EXPLICITLY, so it carries a
# hard step-size stability limit: above some kz the RK4 update diverges, the run
# fills with NaN, and every caller that guards on `anyNA` turns that into -Inf.
# In the calibration that -Inf was silently doing duty as a prior bound -- the
# 2026-08-10 mode sat within ~1 % of it, so the posterior was being truncated by
# the integrator rather than by the data (handoff 2026-08-10b section 4).
#
# The limit is not a mystery, it is the textbook one. Measured NA thresholds
# match the eigenvalue prediction below to 0.1-1 % across h_ml and substeps:
#
#   h_ml 75, substeps  4 : empirical 155,319  vs analytic 155,366  (1.000)
#   h_ml 75, substeps  8 : empirical 310,694  vs analytic 310,732  (1.000)
#   h_ml 75, substeps 16 : empirical 621,433  vs analytic 621,464  (1.000)
#   h_ml 30, substeps  4 : empirical  92,896  vs analytic  93,754  (0.991)
#   h_ml 200, substeps 4 : empirical 178,231  vs analytic 177,409  (1.005)
#
# So the fix is to CHOOSE the substep count from the criterion instead of
# hard-coding 4 and hoping. At every ordinary parameter value the answer is
# still 4 -- kz has to exceed ~155,000 m2/yr (+6.2 sigma on its prior) before
# the count moves -- so no existing result changes. See test-stability.R.
#
# AIR-SEA IS NOT COVERED BY THIS CRITERION, deliberately. Gas exchange can
# dominate the Jacobian at low kz (measured up to 15x the diffusion eigenvalue
# at k_w = 6000, h_ml = 30), but in ABSOLUTE terms it stays ~13x below the RK4
# budget there and would need k_w ~ 80,000 (+11 sigma) to bind. Rather than add
# a second closed form whose Revelle-driven growth along the trajectory (up to
# 3.9x, measured on SSP5-8.5 to 2100) would need its own fudge factor, the
# air-sea corner is caught by the NA-retry escalation in ccx_run_fast().

# |h*lambda| stability limit of classical RK4 on the negative real axis: the
# largest z > 0 with |1 - z + z^2/2 - z^3/6 + z^4/24| <= 1.
CCX_RK4_STAB_LIMIT <- 2.785293563405
CCX_STAB_SAFETY    <- 0.85   # margin against the limit; empirical/analytic
                             # agreement above is ~1 %, so this is generous
CCX_SUBSTEPS_MIN   <- 4L     # the historical value; never go below it
CCX_SUBSTEPS_MAX   <- 256L   # backstop, so a pathological draw cannot hang

#' Largest |eigenvalue| of the explicit interior-diffusion operator
#'
#' The operator is tridiagonal and non-symmetric as written, but similar to a
#' symmetric matrix under D^(1/2) . D^(-1/2) with D = diag(dz), so its spectrum
#' is real and non-positive. Symmetrising first means `eigen` returns exactly
#' real values instead of real values with 1e-17 imaginary parts.
#'
#' Linear in kz and independent of the state, so this is exact for the whole
#' trajectory, not an estimate at one point.
ccx_diffusion_eigmax <- function(kz, grid) {
  dz  <- grid$dz
  dzm <- (dz[-length(dz)] + dz[-1]) / 2
  n   <- length(dz)
  A   <- matrix(0, n, n)
  for (k in seq_len(n - 1)) {
    a <- kz / (dz[k]     * dzm[k])    # out of layer k, into layer k+1
    b <- kz / (dz[k + 1] * dzm[k])    # out of layer k+1, into layer k
    A[k,     k]     <- A[k,     k]     - a
    A[k,     k + 1] <- A[k,     k + 1] + b
    A[k + 1, k]     <- A[k + 1, k]     + a
    A[k + 1, k + 1] <- A[k + 1, k + 1] - b
  }
  s <- sqrt(dz)
  S <- A * outer(1 / s, s)            # D^(-1/2) A D^(1/2), symmetric
  max(abs(eigen((S + t(S)) / 2, symmetric = TRUE, only.values = TRUE)$values))
}

#' Upper bound on the |eigenvalue| of the explicit OVERTURNING operator
#'
#' The advection operator is not symmetrisable the way diffusion is (the polar
#' sinking limb is a non-local ml -> bottom entry), so this is a Gershgorin
#' BOUND rather than the spectrum: every row's diagonal is -w/dz_k and its
#' off-diagonal mass is at most the same, giving 2 * max_k(w / dz_k). Bounding
#' rather than solving is the conservative direction -- it can only ask for more
#' substeps than strictly needed.
#'
#' Returns exactly 0 at w_up = 0, so a pure-diffusion run resolves to the same
#' substep count it always did.
ccx_advection_eigbound <- function(w_up, grid, p = NULL) {
  w <- max(c(0, unlist(w_up)), na.rm = TRUE)   # the fastest limb in either hemisphere
  # The conveyor's limbs are volume fluxes, so each hemisphere sees Q / A_h and
  # the SMALLER-area hemisphere sets the bound. Folded in here rather than given
  # its own bound because it is the same Courant-type constraint on the same
  # boxes -- and because a stability check that silently ignored a first-order
  # advective term (20.8 GtC/yr at 27 Sv, against 27.1 GtC/yr of gross air-sea
  # exchange) would be worse than no check.
  cg <- if (is.null(p)) NULL else ccx_conveyor_geom(p, grid)
  if (!is.null(cg)) {
    a_min <- min(ccx_const("OCEAN_AREA_NH"), ccx_const("OCEAN_AREA_SH"))
    w <- max(w, cg$Q / a_min)
  }
  if (w <= 0) return(0)
  2 * max(w / grid$dz)
}

#' Substeps needed to keep the explicit interior transport stable over one step
#' @param dt master step, years (1/12 for the monthly integrator)
ccx_substeps_for <- function(p, grid = ccx_ocean_grid(p$h_ml), dt = 1 / 12) {
  lam <- ccx_diffusion_eigmax(p$kz, grid) +
    ccx_advection_eigbound(c(p$w_up, p$w_out_NH, p$w_out_SH), grid, p)
  need <- dt * lam / (CCX_STAB_SAFETY * CCX_RK4_STAB_LIMIT)
  as.integer(min(max(CCX_SUBSTEPS_MIN, ceiling(need)), CCX_SUBSTEPS_MAX))
}

#' Resolve a user-supplied `substeps` argument, which may be the string "auto"
ccx_resolve_substeps <- function(substeps, p, grid, dt = 1 / 12) {
  if (identical(substeps, "auto")) ccx_substeps_for(p, grid, dt) else as.integer(substeps)
}

# ---------------------------------------------------------------------
# Integrator
# ---------------------------------------------------------------------
#' Classical RK4 over one month, with substeps.
#'
#' The air-sea exchange timescale is h_ml / k_w ~ 75/1500 = 0.05 yr ~ 18 days,
#' i.e. SHORTER than the monthly master step, so substepping is required for
#' accuracy (not for conservation, which holds exactly at any step -- see header).
ccx_step_rk4 <- function(y, t, dt, p, forc, grid, aux, substeps = 4L) {
  h <- dt / substeps
  for (s in seq_len(substeps)) {
    k1 <- ccx_deriv(y,             t,           p, forc, grid, aux)
    k2 <- ccx_deriv(y + h / 2 * k1, t + h / 2,  p, forc, grid, aux)
    k3 <- ccx_deriv(y + h / 2 * k2, t + h / 2,  p, forc, grid, aux)
    k4 <- ccx_deriv(y + h * k3,     t + h,      p, forc, grid, aux)
    y <- y + h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
    t <- t + h
  }
  y
}

#' Total carbon in the system (diagnostic for the conservation gate)
ccx_total <- function(y, tracer = "C") sum(y[, tracer])
