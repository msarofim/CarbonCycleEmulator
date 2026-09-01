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
# "no CO2 fertilization" and "no land sink" as separate items. In THIS model they
# are the same switch: the land takes up carbon because NPP rises with CO2
# (beta), and there is no other land-uptake mechanism to remove. Offering them as
# two controls would imply a distinction the model does not have. They are merged,
# and the app says so.
# =====================================================================

# Each entry: what the user sees, what it does, and the caveat it carries.
# `apply` receives (p, F) -- parameters and the assembled forcing table -- and
# returns both, so a switch can act on either.
CCX_MECHANISMS <- list(
  fertilisation = list(
    label = "CO₂ fertilisation (the land sink)",
    blurb = paste("Plants grow faster when there is more CO₂ in the air, and",
                  "that extra growth is what pulls carbon into the land. Switch",
                  "it off and the land stops taking up carbon."),
    caveat = paste("In this model CO₂ fertilisation IS the land sink — there",
                   "is no separate land-uptake mechanism to remove."),
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
    label = "Warming's effect on the carbon cycle",
    blurb = paste("A warmer world respires soil carbon faster and holds less CO₂",
                  "in seawater, so warming pushes carbon back into the air.",
                  "Switch it off and the carbon cycle stops noticing the warming."),
    caveat = paste("The climate still warms — only the carbon cycle's RESPONSE",
                   "to it is removed, so the two effects can be told apart."),
    apply = function(p, F) {
      p$q10 <- 1; p$sst_scale <- 0
      # sst_obs = 0, or the observed HadSST4 columns would carry real SST
      # warming straight past the zeroed sst_scale and the switch would only
      # HALF-remove the response it claims to remove (2026-08-18).
      p$sst_obs <- 0
      list(p = p, F = F)
    }
  ),
  enso = list(
    label = "El Niño / La Niña",
    blurb = paste("ENSO moves carbon in and out of tropical land -- and, since",
                  "2026-09-01, in and out of the surface ocean -- year by year.",
                  "It is why the Keeling curve wobbles around its trend.",
                  "Switch it off and the wobbles go."),
    caveat = "Affects year-to-year variability, not the long-term trend.",
    apply = function(p, F) { p <- ccx_set_enso(p, list(gamma_enso = 0)); list(p = p, F = F) }
  ),
  ocean_sink = list(
    label = "The ocean sink",
    blurb = paste("The ocean has absorbed roughly a quarter of all our CO₂.",
                  "Switch it off and that carbon stays in the air."),
    caveat = paste("This closes the air-sea interface completely, which also stops",
                   "the ocean exchanging ¹³C and ¹⁴C. The isotope panels are",
                   "not meaningful with this switch on."),
    apply = function(p, F) { p$k_w <- OCEAN_OFF_K_W; list(p = p, F = F) }
  ),
  emissions = list(
    label = "Our emissions",
    blurb = paste("Everything people put into the air: burning coal, oil and gas,",
                  "making cement, and clearing land. Switch it off and the model",
                  "runs the same 270 years with nature alone."),
    caveat = paste("Nature's own carbon cycle keeps running, including its",
                   "response to the observed warming \u2014 so what is left is",
                   "what temperature and El Ni\u00f1o do on their own."),
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
    apply = function(p, F) {
      for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH",
                   "cum_luc_NH", "cum_luc_SH")) F[[cc]] <- 0
      list(p = p, F = F)
    }
  ),
  revelle = list(
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

#' Named list of switch labels, for building UI controls
ccx_mechanism_choices <- function() {
  stats::setNames(names(CCX_MECHANISMS),
                  vapply(CCX_MECHANISMS, `[[`, character(1), "label"))
}
