# =====================================================================
# mechanisms.R -- the counterfactual switches behind the app's "What if...?" tab.
#
# Each switch turns ONE mechanism off. They live here, not in the app, for two
# reasons: they are statements about the model rather than about the interface,
# and they need testing (a switch that silently does nothing, or that turns off
# more than it claims, would be a plausible-looking lie told to students).
#
# THE SOURCE SWITCH WAS MISSING UNTIL 2026-08-13. Every switch here turned off a
# SINK; none turned off the SOURCE, which is the single most-wanted
# counterfactual in the whole "what drives CO2?" argument (DESIGN sec.7 tab 6):
# turn the warming feedback off and the trend barely moves; turn EMISSIONS off
# and it disappears. Without both halves the comparison is unmakeable.
#
# WHAT IS DELIBERATELY NOT HERE. DESIGN section 7 lists six toggles, including
# "no CO2 fertilization" and "no land sink" as separate items. Until hilda33d
# they were the same switch, because NPP rising with CO2 (beta) was the model's
# only long-term land uptake. ⚠ THAT IS NO LONGER TRUE (2026-10-01): the D2
# canonical also retains carbon from nitrogen deposition (`ndep_ret`), a second
# long-term land sink. Marcus ruled (review 10-01c B5) that the fertilization
# switch stays SPECIFICALLY CO2 fertilization, with nitrogen effects a different
# arm "(even though they matter for CO2 fertilization limits)" -- so its words
# changed, not its behavior, and the app's "no separate land-sink switch" box
# was deleted (A3). There is still no N-deposition switch of its own.
# =====================================================================

# Each entry: what the user sees, what it does, and the caveat it carries.
# `apply` receives (p, F) -- parameters and the assembled forcing table -- and
# returns both, so a switch can act on either.
# =====================================================================
# THE PRESCRIBED DRIVERS (2026-09-24, Marcus review F1: "a third panel
# showing the driver itself -- volcanic AOD by year, the ENSO index by year,
# emissions by year").
#
# These live here, beside the switches, for the reason the switches do: WHICH
# driver a switch acts on is a statement about the MODEL, not about the
# interface, and it needs testing. A panel drawing the wrong series under a
# switch's name would be a plausible-looking lie of exactly the kind this file
# exists to prevent.
#
# ⛔ THREE SWITCHES HAVE NO DRIVER, AND THAT IS NOT AN OMISSION. `fertilisation`,
# `ocean_sink` and `revelle` change a PARAMETER -- how strongly the model
# responds to carbon it already has. There is no prescribed input series behind
# them, and putting atmospheric CO2 in that slot would be drawing a model OUTPUT
# in a panel labeled "the driver". The app says so instead.
#
# ⛔ NOTHING HERE DECLARES WHETHER A SWITCH REMOVES ITS DRIVER, and that is
# deliberate: it is MEASURED, by differencing the series either side of
# ccx_apply_mechanisms() (ccx_driver_series()). It is also the interesting half
# of the panel. ⭐ SINCE 2026-10-02 EVERY DRIVER SWITCH ZEROES ITS INPUT (Marcus,
# "Zero the index (Recommended)"): `enso` and `warming_feedback` used to leave the
# input untouched and remove only a RESPONSE, and for `enso` that response was not
# all of it -- the ocean's upwelling path (w_enso_l2) and the equatorial cell kept
# reading the index, so "the model simply stops responding" was false (0.47 ppm).
# `warming_feedback` was already exactly equivalent (0 ppm) and now zeroes gmst too,
# so its chart draws the zero line it effectively had. A declared flag would be a
# second copy of a fact the code already holds, free to drift from it.
#
# ⚠ EVERY SERIES IS ZERO BEFORE ITS RECORD STARTS, WHICH IS COVERAGE AND NOT
# PHYSICS, and the panel must say so: the Nino 3.4 index begins 1948
# (FORC_ENSO_PRE1948), IGCC temperature 1850 (FORC_GMST_PRE1850) and the CMIP7
# AOD series 1850 (ccx_aod_at). On the tab's default 1850-2024 window a reader
# not told this sees a flat zero and reads it as "no El Nino happened".
# =====================================================================
CCX_DRIVERS <- list(
  emissions = list(
    label = "Emissions: fossil fuels, cement and land-use change",
    unit  = "GtC per year",
    # The emissions record covers the model's whole span, so there is no
    # coverage zero to disclose. NA rather than a year, and the app branches on
    # it rather than on a sentinel year that would print.
    since = NA_integer_,
    of    = function(F) F$e_foss_NH + F$e_foss_SH + F$e_luc_NH + F$e_luc_SH
  ),
  enso = list(
    label = "El Ni\u00f1o / La Ni\u00f1a: the Ni\u00f1o 3.4 sea-surface temperature anomaly",
    unit  = "\u00b0C",
    since = 1948L,
    of    = function(F) F$enso
  ),
  aod = list(
    label = "Volcanic aerosols: stratospheric aerosol optical depth",
    unit  = "AOD (dimensionless)",
    since = 1850L,
    of    = function(F) (F$aod_NH + F$aod_SH) / 2
  ),
  gmst = list(
    label = "The observed global temperature record this model is driven by",
    unit  = "\u00b0C above 1850\u20131900",
    since = 1850L,
    of    = function(F) F$gmst
  )
)

CCX_MECHANISMS <- list(
  fertilisation = list(
    driver = NULL,  # CCX_DRIVERS; NULL = acts on a parameter, not an input
    # 2026-10-01 (Marcus, review 10-01c B5 + A3): "Reword: it should be
    # specifically about CO2 fertilization, with nitrogen effects a different
    # arm (even though they matter for CO2 fertilization limits)." The label
    # lost "(the land sink)", the blurb "the land stops taking up carbon", and
    # the caveat "CO2 fertilization IS the land sink -- there is no separate
    # land-uptake mechanism". All three were false at hilda33d: with this switch
    # on, N-deposition retention still holds ~30 GtC on land by 2024. The
    # BEHAVIOR is unchanged (beta / beta_max only; `ndep_ret` stays live).
    label = "CO₂ fertilization",
    blurb = paste("Plants grow faster when there is more CO₂ in the air, and",
                  "that extra growth pulls carbon into the land. Switch it off",
                  "and plants no longer respond to the rising CO₂."),
    caveat = paste("This switches off CO₂ fertilization only. Nitrogen",
                   "deposition, from fuel burning and farming, is a separate",
                   "and smaller land sink in this model, and it stays on here",
                   # Marcus 2026-10-02 (carbotopecomment): his wording; U.S. spelling since 2026-10-15 (Marcus)
                   "— even though, in the real world, lack of sufficient nitrogen",
                   "can also limit the response to CO₂ fertilization."),
    # MUST ZERO WHICHEVER PARAMETER IS LIVE. This read `p$beta <- 0` until
    # 2026-08-14, and the flip to CCX_FERT_MM turned it into a NO-OP -- the
    # switch moved CO2 at 2100 by exactly 0.00 ppm while still rendering as an
    # active control in the app. test-mechanisms.R caught it, which is what that
    # "every switch is wired up and CHANGES the answer" assertion is for.
    # Zeroing BOTH is deliberate: it is correct under either form and cannot go
    # stale the next time the default moves.
    apply = function(p, F) { p$beta <- 0; p$beta_max <- 0; list(p = p, F = F) }
  ),
  warming_feedback = list(
    driver = "gmst",  # CCX_DRIVERS; NULL = acts on a parameter, not an input
    label = "Warming's effect on the carbon cycle",
    blurb = paste("A warmer world respires soil carbon faster and holds less CO₂",
                  "in seawater, so warming pushes carbon back into the air.",
                  "Switch it off and this amplifying feedback goes away."),
    # C5 (Marcus 09-24): he doubts this is relevant, "we only care about
    # warming because of its carbon cycle effects". Kept, because the reader who
    # does not know the temperature is PRESCRIBED will read "switch off the
    # warming feedback" as "switch off the warming". The "so the two effects can
    # be told apart" tail IS pedantry and is dropped.
    # 2026-10-06 (Marcus: "Caveat sentence (Recommended)"): the switch also removes the
    # stratification feedback (DESIGN §3.4a S, in the canonical since hilda33p), and the blurb
    # names only the soil and seawater paths. The added sentence is DESIGN's "For the app" one.
    # "Smaller" is MEASURED, and test-mechanisms.R guards it: at hilda33p, on the app's own
    # estimator (CO2 today, 426 -> 420), the switch's 5.70 ppm splits 4.90 seawater / 0.63 soil /
    # 0.15 mixing (calibration/diag_warming_switch_split.R; outputs/diagnostics/
    # warming_switch_split_20261006_hilda33p.log).
    caveat = paste("The world still warms either way — this model is driven by",
                   "the observed temperature record. What is switched off is",
                   "only the carbon cycle's response to that warming.",
                   "It also removes a third, smaller effect: warming is strongest",
                   "at the surface, so the upper ocean becomes more layered and",
                   "mixes less, and the carbon we add is carried down into the",
                   "deep ocean more slowly."),
    # 2026-10-15 review: the driver chart's note (app/server.R output$c_driver_ui). The generic "removes this input"
    # contradicted the caveat above ("The world still warms either way"): the temperature line goes to zero because
    # the model IGNORES temperature under this switch, not because the run is cooler.
    driver_note = paste("The model ignores temperature under this switch, so its temperature input",
                        "is drawn as zero: the purple line is what the counterfactual ran with. The",
                        "world in this run still warms; only the carbon cycle's response to that",
                        "warming is removed."),
    apply = function(p, F) {
      p$q10 <- 1; p$sst_scale <- 0
      # sst_obs = 0, or the observed HadSST4 columns would carry real SST
      # warming straight past the zeroed sst_scale and the switch would only
      # HALF-remove the response it claims to remove (2026-08-18).
      p$sst_obs <- 0
      # npp_tsens = 0: NPP's own temperature response (D2's greening term,
      # NPP x exp(npp_tsens x GMST)). The SAME failure as sst_obs, a second
      # time: the term is 0 at defaults and in every #13 mode, so the switch
      # was complete until the D2 canonical made it live (hilda33d, -0.0079 /K).
      # Measured there (2026-10-01): it left +1.52 ppm of the 2024 response on,
      # so the switch removed -5.26 of -6.78 ppm. test-mechanisms.R now asserts
      # the canonical's run is BLIND to the temperature record under this switch,
      # which catches the next temperature path a refit makes live as well.
      p$npp_tsens <- 0
      # the stratification feedback (DESIGN §3.4a S, 2026-10-04): the THIRD time the lesson above
      # applies. Zeroing gmst below already holds its key at 0 (g = 1), but the switch names
      # every temperature path explicitly, so a run that bypassed the input would still be blind.
      p$mix_strat_s <- 0
      # 2026-10-02: zero the INPUT as well (Marcus, with "Zero the index"). MEASURED: with the
      # four parameters above zeroed the run is BLIND to gmst (max |dCO2| 0 against gmst = 0),
      # so this changes no number -- it makes the driver chart draw the zero line the model
      # effectively already ran with, instead of the false "the model still receives it".
      if (!is.null(F$gmst)) F$gmst <- 0
      list(p = p, F = F)
    }
  ),
  enso = list(
    driver = "enso",  # CCX_DRIVERS; NULL = acts on a parameter, not an input
    label = "El Niño / La Niña",
    # ⛔ "SWITCH IT OFF AND THE WOBBLES GO" WAS WRONG, AND THE CHART ADDED FOR
    # Marcus's C2 is what exposed it -- which is the whole argument for adding
    # it. RE-MEASURED 2026-10-02 at hilda33d, app estimator, 1980-2024 (the observed
    # NOAA MBL span): full model 0.268 ppm/yr against an observed 0.459 (58 %, card 4's
    # "about 60%"). Knockouts: ENSO (index zeroed) -28 %, temperature -29 %, volcanic
    # light -8 %; all three together -67 %; the emissions record smoothed, alone, -12 %.
    # (1959-2024 under the older mode and the old land-only switch: -23 / -22 / -8, -43 %.)
    # ⭐ RE-MEASURED 2026-10-03 at hilda34g (the land ENSO lag fitted) by a COMMITTED driver,
    # calibration/diag_app_wobble_shares.R (outputs/diagnostics/app_wobble_shares_20261003_*):
    # full 0.276 ppm/yr (60 % of 0.459); ENSO -40 %, warming -19 %, volcanic light -3 %, all
    # three -68 % (32 % remains). "About a quarter" became FALSE and the blurb says "about 40 %"
    # (Marcus 2026-10-03: "\"about 40 %\" (Recommended)"); "about a third" in the caveat holds.
    # ⚠ The numbers are the canonical's: re-run the driver at every adoption.
    # ⚠ This estimator is NOT gate V's (which regresses growth on emissions with
    # a time-varying airborne fraction); the numbers are an app-level echo and
    # must not be quoted as the gate's decomposition. That is
    # calibration/diag_gateV_variability_drivers.R.
    # Marcus 2026-10-15: "It is the largest driver of the variability in annual growth rate" is his.
    # RE-MEASURED 2026-10-15 at hilda31w (app_wobble_shares_20261015_hilda31w): ENSO off removes 38 %.
    blurb = paste("ENSO moves carbon in and out of tropical land, and in and",
                  "out of the surface ocean, year by year. It is the largest",
                  "driver of the variability in annual growth rate — switch it",
                  "off and about 40% of the wobble goes with it."),
    # ⛔ THE TEMPERATURE HALF KEEPS RUNNING, and this caveat may not be
    # shortened to "El Nino off". Marcus 2026-09-25: "it does not flatten the
    # ENSO temperature effect, so that still exists." `apply` below zeroes the
    # ENSO INDEX (2026-10-02) -- every response the model makes to it, land and
    # ocean -- but the prescribed gmst and sst_anom drivers still carry every El
    # Nino's temperature signature, and the carbon cycle's response to that
    # warming (q10, sst_scale) runs on. Structurally the SAME split as `volcanic`:
    # one pathway removed, the thermal one left alone.
    # Marcus 2026-10-02 (carbotopecomment): the pointer to the warming switch is cut (warming
    # mixes many things, so it does not isolate ENSO's own warming), and the last sentence is
    # his. "About a third" is MEASURED on the app's estimator over 1980-2024 under the switch
    # as it now is (index zeroed): ENSO + warming + volcanic light off together remove 67 % of
    # the full model's scatter (0.268 -> 0.088 ppm/yr). Under the old land-only switch it was
    # 54 % (46 % left), which is why his draft said "half". Smoothing the emissions record
    # removes 12 % on its own (old switch). CHANGELOG 10-02 (w).
    # Marcus 2026-10-15: "ENSO index" (defined) replaces "El Niño index", and the temperature
    # sentence is his. 2026-10-15 re-measure: all three switches off leave 29 % ("about a third").
    caveat = paste("This sets the ENSO index — a measure of how strong El Niño and",
                   "La Niña conditions are — to zero, which removes every",
                   "response the model makes to it, on land and in the ocean.",
                   "The ENSO temperature signal is not removed from the",
                   "temperature driver: this switch only removes the other",
                   "ENSO-related effects on carbon uptake.",
                   "Affects year-to-year variability, not the long-term trend.",
                   "In the model, even accounting for El Niño, temperature, and",
                   "aerosol light-diffusion effects, about a third of the wobble",
                   "remains, so there must be other sources of variability."),
    # 2026-10-02 (Marcus: "Zero the index (Recommended)"): the INDEX goes to zero, so EVERY
    # path that reads it stops -- land and ocean direct terms, the layer-3 upwelling anomaly
    # (w_enso_l2), the equatorial cell (gamma_eq) and the SST modulation. Zeroing the
    # coefficients as well is belt and braces, as `volcanic` zeroes both AOD and gamma_diff:
    # MEASURED, input-zeroed alone == input + coefficients zeroed, max |dCO2| 0.
    apply = function(p, F) {
      p <- ccx_set_enso(p, list(gamma_enso = 0))
      if (!is.null(F$enso)) F$enso <- 0
      list(p = p, F = F)
    }
  ),
  volcanic = list(
    driver = "aod",  # CCX_DRIVERS; NULL = acts on a parameter, not an input
    label = "Volcanic aerosols (the diffuse-light effect)",
    # Marcus 2026-10-15: the first two sentences are his ("something like"); "a climate effect" and the
    # join into the existing diffuse-light sentence are the only changes.
    blurb = paste("Some explosive volcanic eruptions put sulfate aerosols into",
                  "the stratosphere, where they reflect sunlight and can persist",
                  "long enough to have a climate effect. They also scatter light,",
                  "which sounds bad for plants but is not: scattered light reaches leaves that",
                  "would otherwise sit in shade, so the world's vegetation",
                  "grows a little faster for a year or two and pulls extra",
                  "CO₂ out of the air. Switch it off and the dips after",
                  "eruptions get shallower. The clearest case is the 1991",
                  "eruption of Mount Pinatubo, whose effect on the carbon",
                  "cycle shows up most strongly in 1992."),
    # ⛔ THE CAVEAT IS NOT OPTIONAL AND MAY NOT BE SHORTENED TO "volcanoes off".
    # This switch removes the LIGHT path only. An eruption ALSO cools the planet,
    # and this model does not compute its own temperature -- it is DRIVEN by the
    # observed IGCC record, which already contains every historical eruption's
    # cooling. Removing that would need a volcanic decomposition of the observed
    # temperature, which this repo does not have. So the thermal half keeps
    # running no matter what this switch is set to, and the panel says so.
    # (Marcus review C6, 2026-09-22; spec 2026-08-29 §3a names both halves.)
    # Marcus 2026-10-02 (carbotopecomment): lower-case, and the pointer to the warming switch
    # cut -- "warming is a mix of so many different things, it doesn't distinguish any
    # individual ENSO or volcanic warming effect out".
    # Marcus 2026-10-15: his wording.
    caveat = paste("This removes the diffuse scattering effect only. The planetary",
                   "cooling is embedded in the observed temperature record, and",
                   "is not removed by this switch."),
    apply = function(p, F) {
      # BOTH, deliberately. Zeroing the AOD columns is the physical statement
      # ("no volcanic aerosol") and would also catch a future consumer of them;
      # zeroing gamma_diff catches a future consumer that reads the coefficient
      # without the columns. Today `gamma_diff * aod` is the only term either
      # appears in (R/model.R ~2304, src/ccx_core.cpp ~591), so they agree.
      if (!is.null(F$aod_NH)) F$aod_NH <- 0
      if (!is.null(F$aod_SH)) F$aod_SH <- 0
      p$gamma_diff <- 0
      list(p = p, F = F)
    }
  ),
  ocean_sink = list(
    driver = NULL,  # CCX_DRIVERS; NULL = acts on a parameter, not an input
    label = "The ocean sink",
    # 2026-10-15 review: "roughly a quarter" -> the Where tab prints 29 % at hilda31w; and closing the ocean leaves
    # MOST of that carbon in the air, not all of it (the land takes up some of the rest)
    blurb = paste("The ocean has absorbed between a quarter and a third of all our CO₂.",
                  "Switch it off and most of that carbon stays in the air."),
    # C6 (Marcus 09-24), MEASURED: `input$c_mech` drives only c_plot, c_growth,
    # c_growth_note, c_blurb, c_takeaway and w_luc_note. The isotope panels render
    # from APP_HIST$out, the fixed historical run, so this switch NEVER reaches
    # them. The old wording ("the isotope panels are not meaningful with this
    # switch on") implied a coupling that does not exist and invited the reader
    # to go and look at a degradation they cannot see.
    caveat = paste("This closes the air-sea interface completely, which would also",
                   "stop the ocean exchanging ¹³C and ¹⁴C. That effect is not shown",
                   "anywhere in the app: the isotope panels always draw the full",
                   "historical run and do not respond to these switches."),
    apply = function(p, F) { p$k_w <- OCEAN_OFF_K_W; list(p = p, F = F) }
  ),
  emissions = list(
    driver = "emissions",  # CCX_DRIVERS; NULL = acts on a parameter, not an input
    label = "Our emissions",
    # 2026-10-15 review: "the same 270 years" was typed, and the run is 275 (1750-2024). This file is sourced before
    # app/global.R defines APP_HIST_YEARS, so "{n_years}" is filled by the app (server.R output$c_blurb).
    blurb = paste("Everything people put into the air: burning coal, oil and gas,",
                  "making cement, and clearing land. Switch it off and the model",
                  "runs the same {n_years} years with nature alone."),
    # 2026-10-02 (carbotopecomments.10.2.26, Marcus): "Change to" -- his wording, verbatim.
    caveat = paste("While the direct effect of our emissions disappears, the indirect",
                   "effect through temperature still remains. ENSO and volcanoes also",
                   "continue to have an effect."),
    # Zeroing the forcing columns rather than a parameter: emissions are
    # PRESCRIBED, so there is no coefficient to set to zero. LUC goes too --
    # it is an emission (a wood -> atmosphere transfer), not a natural flux.
    #
    # AND THE CUMULATIVE WITH IT (2026-08-13). cum_luc shrinks the land's
    # equilibrium (the converted-land term in ccx_deriv()), so zeroing only the
    # FLUX would answer a different question from the one the switch asks: not
    # "what if we had never emitted" but "what if we stopped emitting from a
    # biosphere we had already cleared", which would leave the land relaxing
    # toward a smaller equilibrium and release ~290 GtC that the counterfactual
    # never took. The switch says "nature alone", so the forest is standing.
    #
    # AND N DEPOSITION (2026-10-01). ndep_NH/ndep_SH are ANTHROPOGENIC
    # deposition above 1750, built from NOx + NH3 EMISSIONS (D2 (a), the ruled
    # "emissions proxy"), and ccx_hold_climate() already classes them as
    # emissions-driven. Left on, "nature alone" kept a human-made land sink: at
    # the D2 canonical (hilda33d, ndep_ret 10.2) it held 21 GtC on land by 2024
    # and put CO2 at 277.0 ppm instead of 282.3, so the warming release the
    # caveat below promises was almost exactly canceled. A zero column is
    # inert at ndep_ret 0, so every #13 mode is unchanged.
    apply = function(p, F) {
      for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH",
                   "cum_luc_NH", "cum_luc_SH", "ndep_NH", "ndep_SH")) F[[cc]] <- 0
      list(p = p, F = F)
    }
  ),
  revelle = list(
    driver = NULL,  # CCX_DRIVERS; NULL = acts on a parameter, not an input
    label = "Revelle buffering (ocean saturation)",
    blurb = paste("Seawater gets progressively worse at absorbing CO₂ the more",
                  "it has already absorbed. Freeze that at its 1750 value and",
                  "the ocean never tires."),
    caveat = paste("Temperature-dependent solubility is left alone, so this",
                   "isolates the chemistry of buffering and nothing else."),
    apply = function(p, F) { p$revelle_frozen <- 1; list(p = p, F = F) }
  )
)

# Gas transfer velocity standing in for "no ocean sink". Not zero: zero would
# make the preindustrial isotope operator singular and the spinup would fail to
# solve (the same singularity documented in model.R's add_flux header, which is
# why every bidirectional interface is emitted as gross fluxes). Small enough
# that the ocean takes up ~nothing on a century timescale.
OCEAN_OFF_K_W <- 1e-3

# ⛔ THE OCEAN SWITCH IS SPUN UP WITH THE OCEAN OPEN (2026-10-11; Marcus's comments 10-11: "I get
# an error when selecting warming, ENSO, volcanoes, and ocean sink"). Every switch used to act on
# the spin-up too. That is harmless for the others at the canonical: ENSO, volcanoes and
# emissions leave the 1750 state bit-identical, and fertilization, warming and Revelle move it
# by < 1 GtC. But closing the air-sea interface (k_w = OCEAN_OFF_K_W) IN THE SPIN-UP built a
# different preindustrial world: 268 GtC moved inside the ocean, and the solved ¹⁴C production
# fell to 7 % of the real one. With warming's effect or Revelle also off, the periodic carbon
# solve did not converge at all: 40 Newton steps at |resid| ~1e-5 against 1e-9, ending at
# NEGATIVE Southern deep-ocean carbon (SH_oc10 -8700 GtC). The ¹³C solve was then singular
# ("Lapack routine dgesv: system is exactly singular"), and 16 of the 127 combinations crashed.
# The switch asks what happens when the ocean stops absorbing OUR carbon, so the spin-up keeps
# the ocean open and the run closes it from the first step. Measured at hilda29e over all 127
# combinations: 0 errors; the 63 without the ocean switch are bit-identical to before; the 48
# with it that ran before move CO2 by <= 0.098 ppm anywhere in 1750-2024.
CCX_MECH_RUN_ONLY <- "ocean_sink"

#' The start state for a counterfactual run with switches `off`
#'
#' Spins up with every switch in `off` EXCEPT the run-only ones (CCX_MECH_RUN_ONLY), then
#' hands the run the fully switched parameters, with `aux` rebuilt from them (the
#' run-prepare marshal gate checks that pair). The ocean grid depends on `h_ml` only,
#' which no switch moves; that is asserted.
#' @param p parameters; @param F an assembled forcing table; @param off switch names
#' @param spinup_fn the spin-up the caller runs under (e.g. ccx_spinup_from_label(...))
#' @return list(spin = the start state, m = ccx_apply_mechanisms(p, F, off))
ccx_mechanism_spinup <- function(p, F, off, spinup_fn) {
  m <- ccx_apply_mechanisms(p, F, off)
  p_spin <- ccx_apply_mechanisms(p, F, setdiff(off, CCX_MECH_RUN_ONLY))$p
  sp <- spinup_fn(p_spin)
  if (!identical(p_spin, m$p)) {
    aux <- ccx_prepare(m$p)
    if (!identical(aux$grid, sp$grid))
      stop("ccx_mechanism_spinup(): the run-only switches changed the ocean grid")
    sp$params <- m$p; sp$aux <- aux
  }
  list(spin = sp, m = m)
}

#' Apply a set of mechanism switches
#' @param off character vector of names from CCX_MECHANISMS to switch OFF
#' @return list(p = parameters, F = forcing, caveats = character vector)
ccx_apply_mechanisms <- function(p, F, off = character()) {
  bad <- setdiff(off, names(CCX_MECHANISMS))
  if (length(bad)) stop("unknown mechanism(s): ", paste(bad, collapse = ", "))
  cav <- character()
  for (nm in off) {
    r <- CCX_MECHANISMS[[nm]]$apply(p, F)
    p <- r$p; F <- r$F
    cav <- c(cav, CCX_MECHANISMS[[nm]]$caveat)
  }
  list(p = p, F = F, caveats = cav)
}

#' The prescribed driver behind one switch, BEFORE and AFTER the switch acts
#'
#' Marcus review F1 (2026-09-24). Returns NULL for the three switches that act
#' on a parameter rather than on an input -- the caller must handle that and say
#' so, rather than substituting a model output.
#'
#' \u26d4 `removes_driver` IS MEASURED HERE, NOT DECLARED ANYWHERE. It is the
#' comparison itself: every driver switch zeroes its INPUT column, so the two
#' series separate. (2026-10-15 review: this said `enso` and `warming_feedback` zero
#' a COEFFICIENT and the two series lie on top of one another -- true before
#' 2026-10-02, when both began zeroing their input; see the CCX_DRIVERS header.) A
#' hand-maintained flag would be a copy of that fact free to drift from it --
#' and `enso` has already had one switch (fertilization, 2026-08-14) silently
#' become a no-op when the live parameter moved underneath it.
#'
#' @param nm one name from CCX_MECHANISMS
#' @param F  an assembled forcing table (ccx_build_forcing())
#' @param p  parameters; only needed because ccx_apply_mechanisms() takes them
#' @param F_off the switched forcing, when the caller ALREADY HAS the one its
#'   counterfactual actually ran with. The app passes it for that reason: a
#'   panel that re-derived the input would be drawing a second forcing beside
#'   the run instead of the run's own, which is the cross-tab-step failure
#'   (CHANGELOG 09-22 (x)) in miniature. Omitted, it is derived here, and
#'   test-driver-panel.R asserts the two paths agree.
#' @return NULL, or list(key, label, unit, since, t, full, off, removes_driver)
ccx_driver_series <- function(nm, F, p = ccx_default_params(), F_off = NULL) {
  if (!nm %in% names(CCX_MECHANISMS))
    stop("unknown mechanism: ", nm, call. = FALSE)
  key <- CCX_MECHANISMS[[nm]]$driver
  if (is.null(key)) return(NULL)
  d <- CCX_DRIVERS[[key]]
  if (is.null(d)) stop("mechanism ", nm, " names an unknown driver: ", key,
                       call. = FALSE)
  if (is.null(F_off)) F_off <- ccx_apply_mechanisms(p, F, nm)$F
  full <- d$of(F)
  off  <- d$of(F_off)
  c(list(key = key), d[c("label", "unit", "since")],
    list(t = F$t, full = full, off = off,
         removes_driver = !isTRUE(all.equal(full, off))))
}

#' Named list of switch labels, for building UI controls
ccx_mechanism_choices <- function() {
  stats::setNames(names(CCX_MECHANISMS),
                  vapply(CCX_MECHANISMS, `[[`, character(1), "label"))
}
