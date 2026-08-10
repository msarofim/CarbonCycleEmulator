# =====================================================================
# model.R — two-hemisphere, monthly, 12C/13C/14C box carbon cycle model
#
# BOXES, per hemisphere h in {NH, SH}:
#   atm            1  well-mixed troposphere
#   veg, soil      2  effective responsive land pools
#   ml + interior 11  ocean column: mixed layer + NL diffusive layers
# = 14 boxes/hemisphere x 2 = 28; x 3 tracers = 84 states.
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
#' Names of the 28 boxes, in state order
ccx_box_names <- function(nl = N_INTERIOR) {
  unlist(lapply(HEMIS, function(h)
    c(paste0(h, "_atm"), paste0(h, "_veg"), paste0(h, "_soil"),
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
    beta      = 0.40,     # CO2 fertilization, NPP = NPP0 (1 + beta ln(chi/chi0))
    q10       = 2.0,      # heterotrophic respiration temperature sensitivity
    tau_veg   = 10,       # yr, vegetation turnover
    tau_soil  = 25,       # yr, responsive soil turnover
    k_w       = 1500,     # m/yr, gas transfer velocity
    h_ml      = 75,       # m, mixed-layer depth
    kz        = 4000,     # m2/yr, interior eddy diffusivity
    tau_ex    = 1.3,      # yr, interhemispheric atmospheric exchange
    sst_NH    = 18,       # degC, hemispheric-mean SST (inside the K1/K2 fit range)
    sst_SH    = 16,
    sst_scale = 0.8,      # SST anomaly per unit GMST anomaly
    npp_frac_NH = 0.60,   # NH share of global NPP
    seas_amp_NH = 12,     # GtC/yr, seasonal NEP amplitude
    seas_amp_SH = 2,
    seas_phase_NH = 3.5,  # month of peak uptake
    seas_phase_SH = 9.5
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
    iatm <- aux$idx[[h]]$atm; iveg <- aux$idx[[h]]$veg
    isol <- aux$idx[[h]]$soil; iml <- aux$idx[[h]]$ml
    ioc  <- aux$idx[[h]]$oc

    chi <- y[iatm, "C"] / aux$gtc_per_ppm_hemi          # ppm in this hemisphere

    # ---- land -------------------------------------------------------
    npp <- aux$npp0[[h]] * (1 + p$beta * log(max(chi, 1e-6) / aux$chi0))
    add_flux(iatm, iveg, npp, alpha13 = aux$alpha_photo)

    litter <- y[iveg, "C"] / p$tau_veg
    add_flux(iveg, isol, litter)

    rh <- (y[isol, "C"] / p$tau_soil) * p$q10^(forc$gmst / 10)
    add_flux(isol, iatm, rh)

    # ---- seasonal NEP: zero annual integral, amplitude scales with NPP
    amp   <- if (h == "NH") p$seas_amp_NH else p$seas_amp_SH
    phase <- if (h == "NH") p$seas_phase_NH else p$seas_phase_SH
    seas  <- amp * sin(2 * pi * (t - phase / 12)) * (npp / aux$npp0[[h]])
    add_flux(iatm, iveg, seas, alpha13 = aux$alpha_photo)

    # ---- ENSO: land -> atmosphere anomaly (El Nino = source) ---------
    if (aux$enso_share[[h]] != 0) {
      add_flux(isol, iatm, p$gamma_enso * forc$enso * aux$enso_share[[h]])
    }

    # ---- air-sea ----------------------------------------------------
    sst    <- aux$sst[[h]] + p$sst_scale * forc$gmst
    dic_ml <- y[iml, "C"] * aux$mol_per_GtC / aux$ml_mass_kg[[h]]   # mol/kg
    k      <- carb_constants(sst)
    pco2_ml <- pco2_from_dic(dic_ml, ccx_const("ALK_SURFACE"), sst, k = k)
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

    # ---- prescribed emissions ---------------------------------------
    add_source(iatm, forc$e_foss[[h]], aux$d13c_foss, -1000)   # fossil: 14C-free
    add_source(iatm, forc$e_luc[[h]],  aux$d13c_bio,
               1000 * (y[iveg, "C14"] / max(y[iveg, "C"], 1e-30) - 1))
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
  idx <- lapply(HEMIS, function(h) list(
    atm  = which(bn == paste0(h, "_atm")),
    veg  = which(bn == paste0(h, "_veg")),
    soil = which(bn == paste0(h, "_soil")),
    ml   = which(bn == paste0(h, "_ml")),
    oc   = which(bn %in% paste0(h, "_oc", seq_len(grid$nl)))))
  names(idx) <- HEMIS

  a_oc <- list(NH = ccx_const("OCEAN_AREA_NH"), SH = ccx_const("OCEAN_AREA_SH"))
  npp0 <- list(NH = ccx_const("NPP_GLOBAL_PI") * p$npp_frac_NH,
               SH = ccx_const("NPP_GLOBAL_PI") * (1 - p$npp_frac_NH))

  list(
    idx = idx,
    # each hemisphere holds half the atmosphere, so ppm per hemisphere uses half
    gtc_per_ppm_hemi = ccx_const("GtC_PER_PPM") / 2,
    chi0        = ccx_const("CO2_PI_PPM"),
    mol_per_GtC = ccx_const("MOL_C_PER_GtC"),
    npp0        = npp0,
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
    d13c_foss   = -28,               # provisional
    d13c_bio    = -25,               # provisional
    enso_share  = list(NH = 0.5, SH = 0.5),
    bomb_share_NH = 0.9,
    nuc_share_NH  = 0.95,
    grid = grid
  )
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
