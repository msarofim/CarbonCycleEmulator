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

# ---------------------------------------------------------------------
# State layout
# ---------------------------------------------------------------------
#' Land pool names, in state order. The C++ core hard-codes this order and this
#' count as a stride (src/ccx_core.cpp), so it is a structural constant, not a
#' presentational one.
CCX_LAND_POOLS <- c("leaf", "wood", "soil_fast", "soil_slow")

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
    # CO2 fertilization, NPP = NPP0 (1 + beta ln(chi/chi0)).
    # RE-CENTRED 2026-08-12 from 0.40 to 0.38, the 1-D optimum of the REAL
    # log-posterior with every other parameter at its CCX_PARAM_TABLE init
    # (-4560.2 -> -4530.6). Set by the objective the model is scored on, not by
    # eyeballing CO2 in one year -- though the two agree here, both landing near
    # 415 ppm at 2020. The move is small because the four-pool land already
    # absorbed most of what the LUC debit had displaced; the ~12 ppm low bias
    # recorded in handoff 2026-08-12b came from the two-pool land and is gone.
    # This is a DEFAULT, i.e. an app and test fixture. beta is calibrated, so
    # the mode-find is what actually sets it -- see R/calibrate.R.
    beta      = 0.38,
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
    k_w       = 1500,     # m/yr, gas transfer velocity
    h_ml      = 75,       # m, mixed-layer depth
    # OVERTURNING, m/yr. 0 = the pure-diffusion ocean, reproduced EXACTLY (no
    # flux is emitted at all), which is what every result before 2026-08-13 was
    # computed on. See the "ocean overturning" block in ccx_deriv() for what a
    # non-zero value does and why it is not a second diffusivity. Whether this
    # becomes a calibrated parameter, a fixed structural value, or stays off is
    # a decision for DESIGN.md section 10, NOT for this default.
    w_up      = 0,
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
    seas_amp_NH = 12,     # GtC/yr, seasonal NEP amplitude
    seas_amp_SH = 2,
    seas_phase_NH = 3.5,  # month of peak uptake
    seas_phase_SH = 9.5,
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
ccx_deriv <- function(y, t, p, forc, grid, aux) {
  dy <- y * 0
  nb <- nrow(y)

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
  add_flux <- function(from, to, F_C, alpha13 = 1) {
    if (F_C == 0) return(invisible(NULL))
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
      dy[a, tr] <<- dy[a, tr] - F_t
      dy[b, tr] <<- dy[b, tr] + F_t
    }
    invisible(NULL)
  }

  # --- external source: enters one box, no counterpart ----------------
  add_source <- function(box, F_C, d13c, d14c) {
    dy[box, "C"]   <<- dy[box, "C"]   + F_C
    dy[box, "C13"] <<- dy[box, "C13"] + F_C * ccx_const("R13_VPDB") * (1 + d13c / 1000)
    dy[box, "C14"] <<- dy[box, "C14"] + F_C * (1 + d14c / 1000)
    invisible(NULL)
  }

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
    veg_C <- y[ilef, "C"] + y[iwod, "C"]
    capacity <- (1 - p$npp_veg_frac) + p$npp_veg_frac * veg_C / aux$veg0[[h]]
    npp <- aux$npp0[[h]] * capacity * (1 + p$beta * log(max(chi, 1e-6) / aux$chi0))

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
    add_flux(iatm, ilef, npp_leaf + ra_leaf, alpha13 = aux$alpha_photo)  # GPP, leaf
    add_flux(ilef, iatm, ra_leaf)                                        # Ra, at leaf's ratio
    add_flux(iatm, iwod, npp_wood + ra_wood, alpha13 = aux$alpha_photo)  # GPP, wood
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
    add_flux(isf, iatm, (y[isf, "C"] / p$tau_soil_fast) * q10f)
    add_flux(iss, iatm, (y[iss, "C"] / p$tau_soil_slow) * q10f)

    # ---- seasonal NEP: zero annual integral, amplitude scales with NPP
    # Routed through the LEAF pool: the seasonal drawdown is foliage growth and
    # senescence, which is what that pool is.
    amp   <- if (h == "NH") p$seas_amp_NH else p$seas_amp_SH
    phase <- if (h == "NH") p$seas_phase_NH else p$seas_phase_SH
    seas  <- amp * sin(2 * pi * (t - phase / 12)) * (npp / aux$npp0[[h]])
    add_flux(iatm, ilef, seas, alpha13 = aux$alpha_photo)

    # ---- ENSO: land -> atmosphere anomaly (El Nino = source) ---------
    # Out of the RESPONSIVE soil pool. The interannual anomaly is drought and
    # fire-driven respiration of recently fixed carbon, not a draw on the
    # millennial passive pool.
    if (aux$enso_share[[h]] != 0) {
      add_flux(isf, iatm, p$gamma_enso * forc$enso * aux$enso_share[[h]])
    }

    # ---- air-sea ----------------------------------------------------
    sst    <- aux$sst[[h]] + p$sst_scale * forc$gmst
    dic_ml <- y[iml, "C"] * aux$mol_per_GtC / aux$ml_mass_kg[[h]]   # mol/kg
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
    add_flux(iatm, iml, gx * pco2_at, alpha13 = aux$alpha_as_down)   # invasion
    add_flux(iml, iatm, gx * pco2_ml, alpha13 = aux$alpha_as_up)     # evasion

    # ---- ocean interior diffusion -----------------------------------
    # F = Kz (C_k/dz_k - C_k+1/dz_k+1) / dz_mid  -- area cancels, exactly
    # conservative, and each flux is applied to both layers by add_flux.
    col <- c(iml, ioc)
    for (kk in seq_len(grid$nl)) {
      add_diffusion(col[kk], col[kk + 1], grid$dz[kk], grid$dz[kk + 1], aux$dz_mid[kk])
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
    # IT COMES OUT OF WOOD (Marcus 2026-08-12). Deforestation removes standing
    # woody biomass, so that is the pool that should pay -- and it is the pool
    # whose 14C ratio the emitted carbon should carry, which is more lagged than
    # the leaf pool's. Debiting leaf, or debiting both pro rata, would let the
    # fast pool absorb clearing it does not physically suffer.
    # NOTE: historical e_luc is strictly positive. Should a scenario ever supply a
    # negative (net-regrowth) value, add_flux swaps the source correctly but the
    # uptake would not carry the photosynthetic fractionation it should.
    add_flux(iwod, iatm, forc$e_luc[[h]])
  }

  # ---- interhemispheric atmospheric exchange -------------------------
  # Gross both ways, for the same reason as air-sea: the NH-SH isotope gradient
  # (the bomb-spike propagation signal) is set by gross exchange, not by the
  # small net flux.
  iN <- aux$idx$NH$atm; iS <- aux$idx$SH$atm
  add_flux(iN, iS, y[iN, "C"] / p$tau_ex)
  add_flux(iS, iN, y[iS, "C"] / p$tau_ex)

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

  dy
}

# ---------------------------------------------------------------------
# Precomputed invariants
# ---------------------------------------------------------------------
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

  list(
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
    sst         = list(NH = p$sst_NH, SH = p$sst_SH),
    ml_mass_kg  = lapply(a_oc, function(A) A * grid$h_ml * ccx_const("RHO_SEAWATER")),
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
    grid = grid
  )
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
ccx_advection_eigbound <- function(w_up, grid) {
  if (is.null(w_up) || w_up <= 0) return(0)
  2 * max(w_up / grid$dz)
}

#' Substeps needed to keep the explicit interior transport stable over one step
#' @param dt master step, years (1/12 for the monthly integrator)
ccx_substeps_for <- function(p, grid = ccx_ocean_grid(p$h_ml), dt = 1 / 12) {
  lam <- ccx_diffusion_eigmax(p$kz, grid) + ccx_advection_eigbound(p$w_up, grid)
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
