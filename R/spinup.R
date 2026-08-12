# =====================================================================
# spinup.R — preindustrial (1750) steady state.
#
# WHY NATURAL 14C PRODUCTION IS NOT OPTIONAL. With no cosmogenic source, the
# whole 14C inventory simply decays: lambda = 1.216e-4/yr gives -24.0 per mil
# over 200 yr and -41.7 per mil over 350 yr of pure drift. The pre-bomb Suess
# decline the model has to reproduce is about -26.6 per mil (IntCal20,
# 1750 -> 1950). The artefact would be LARGER than the signal.
#
# HOW IT IS SET. Production is NOT prescribed from the literature. It is solved
# for, as the rate that holds atmospheric Delta14C at its 1750 value in steady
# state given the model's own carbon inventory and ventilation. That makes the
# canonical cosmogenic estimate (~2.0 atoms/cm2/s ~ 545 mol 14C/yr) an
# INDEPENDENT VALIDATION of the model's inventory and 14C bookkeeping rather
# than an input -- see ccx_spinup()$diagnostics and test-spinup.R.
#
# The 12C equilibrium is analytic; the 13C and 14C equilibria are obtained by
# exact linear solves, because both tracers enter ccx_deriv() LINEARLY once the
# carbon fluxes are fixed (transport uses ratios r = C_iso/C from the source
# box, decay is -lambda*C14, and sources are independent of the isotope state).
# Forward-integrating instead would need >10,000 yr to equilibrate 14C.
# =====================================================================

#' Mixed-layer DIC that equilibrates with a given atmospheric pCO2
#' @return DIC in mol/kg
ccx_dic_for_pco2 <- function(pco2_target, alk, sst) {
  f <- function(dic) pco2_from_dic(dic, alk, sst) - pco2_target
  uniroot(f, interval = c(1000e-6, 2600e-6), tol = 1e-12)$root
}

#' Preindustrial steady state
#'
#' @param p     parameter list
#' @param chi0  preindustrial CO2, ppm
#' @param d13c0 preindustrial atmospheric d13C, per mil
#' @param d14c0 preindustrial atmospheric Delta14C, per mil
#' @return list(y = state matrix, prod_c14 = mol 14C/yr, aux, grid, diagnostics)
ccx_spinup <- function(p = ccx_default_params(),
                       chi0  = ccx_const("CO2_PI_PPM"),
                       d13c0 = ccx_const("D13C_PI"),
                       d14c0 = ccx_const("D14C_PI")) {

  aux  <- ccx_prepare(p)
  grid <- aux$grid
  y    <- ccx_new_state(grid$nl)

  # ---- 12C: analytic equilibrium -------------------------------------
  for (h in HEMIS) {
    i <- aux$idx[[h]]
    y[i$atm, "C"] <- chi0 * aux$gtc_per_ppm_hemi

    # LAND, four pools. Each is filled at its own share of NPP and drains at its
    # own turnover, so every fixed point is share * NPP * tau:
    #   leaf      npp_leaf_frac * NPP,            drains in tau_leaf
    #   wood      (1 - npp_leaf_frac) * NPP,      drains in tau_wood
    # total litter is then NPP again (both vegetation pools are at steady state),
    # split by litter_slow_frac between the two soil pools:
    #   soil_fast (1 - litter_slow_frac) * NPP,   drains in tau_soil_fast
    #   soil_slow litter_slow_frac * NPP,         drains in tau_soil_slow
    # aux$veg0 (model.R) must keep matching leaf + wood here EXACTLY, or the
    # capacity term makes this state stop being a fixed point of the derivative.
    npp0 <- aux$npp0[[h]]
    y[i$leaf, "C"] <- npp0 * p$npp_leaf_frac * p$tau_leaf
    y[i$wood, "C"] <- npp0 * (1 - p$npp_leaf_frac) * p$tau_wood
    y[i$soil_fast, "C"] <- npp0 * (1 - p$litter_slow_frac) * p$tau_soil_fast
    y[i$soil_slow, "C"] <- npp0 * p$litter_slow_frac * p$tau_soil_slow

    # ocean: mixed layer in Henry equilibrium with the atmosphere; the interior
    # is at uniform CONCENTRATION, so C_k scales with layer thickness (this is
    # exactly the zero-flux condition of the diffusion discretisation).
    dic <- ccx_dic_for_pco2(chi0, ccx_const("ALK_SURFACE"), aux$sst[[h]])
    y[i$ml, "C"] <- dic * aux$ml_mass_kg[[h]] / aux$mol_per_GtC
    conc <- y[i$ml, "C"] / grid$dz[1]
    y[i$oc, "C"] <- conc * grid$dz[-1]
  }

  # ---- forcing at equilibrium: nothing external ----------------------
  zero_forc <- function(prod = 0) {
    list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
         gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = prod)
  }
  p0 <- p; p0$gamma_enso <- 0
  # seasonal term integrates to zero over a year; evaluate the annual-mean state
  p0$seas_amp_NH <- 0; p0$seas_amp_SH <- 0

  nb <- nrow(y)

  # ---- helper: linear operator of ccx_deriv acting on one isotope -----
  # dy_iso/dt = A %*% y_iso + b, exact because the isotope enters linearly.
  iso_operator <- function(tracer, forc) {
    y0 <- y; y0[, tracer] <- 0
    b  <- ccx_deriv(y0, 1750, p0, forc, grid, aux)[, tracer]
    A  <- matrix(0, nb, nb)
    for (j in seq_len(nb)) {
      yj <- y0; yj[j, tracer] <- 1
      A[, j] <- ccx_deriv(yj, 1750, p0, forc, grid, aux)[, tracer] - b
    }
    list(A = A, b = b)
  }

  # ---- 13C: no external source; distribution set by fractionation -----
  # A %*% c13 = 0 is singular (13C is conserved), so pin the scale by imposing
  # the observed preindustrial atmospheric d13C on one row.
  op13 <- iso_operator("C13", zero_forc(0))
  iatmN <- aux$idx$NH$atm
  A13 <- op13$A; rhs <- -op13$b
  target13 <- y[iatmN, "C"] * ccx_const("R13_VPDB") * (1 + d13c0 / 1000)
  A13[iatmN, ] <- 0; A13[iatmN, iatmN] <- 1; rhs[iatmN] <- target13
  y[, "C13"] <- solve(A13, rhs)

  # ---- 14C: solve for the production that hits the target Delta14C ----
  # c14 responds linearly to production, so solve once at unit production and
  # rescale. (A includes the -lambda*I decay term.)
  op14 <- iso_operator("C14", zero_forc(1))       # unit mol 14C/yr
  b_unit <- op14$b                                # source vector at P = 1
  u <- solve(op14$A, -b_unit)                     # steady state at P = 1

  atm_idx <- c(aux$idx$NH$atm, aux$idx$SH$atm)
  c14_target_atm <- sum(y[atm_idx, "C"]) * (1 + d14c0 / 1000)
  prod <- c14_target_atm / sum(u[atm_idx])
  y[, "C14"] <- prod * u

  # ---- diagnostics ----------------------------------------------------
  resid <- ccx_deriv(y, 1750, p0, zero_forc(prod), grid, aux)
  d14c_atm <- 1000 * (sum(y[atm_idx, "C14"]) / sum(y[atm_idx, "C"]) - 1)
  d13c_atm <- 1000 * (sum(y[atm_idx, "C13"]) /
                        (sum(y[atm_idx, "C"]) * ccx_const("R13_VPDB")) - 1)
  ocean_idx <- unlist(lapply(HEMIS, function(h) c(aux$idx[[h]]$ml, aux$idx[[h]]$oc)))
  deep_idx  <- unlist(lapply(HEMIS, function(h) tail(aux$idx[[h]]$oc, 3)))

  # canonical cosmogenic production, for comparison ONLY
  P_canon <- 2.04 * (5.1e14 * 1e4) * 365.25 * 86400 / 6.02214076e23

  list(
    y = y, prod_c14 = prod, aux = aux, grid = grid, params = p,
    diagnostics = list(
      max_abs_dCdt      = max(abs(resid[, "C"])),
      max_abs_dC13dt    = max(abs(resid[, "C13"])),
      max_abs_dC14dt    = max(abs(resid[, "C14"])),
      co2_ppm           = sum(y[atm_idx, "C"]) / ccx_const("GtC_PER_PPM"),
      d13c_atm          = d13c_atm,
      d14c_atm          = d14c_atm,
      d14c_deep_ocean   = 1000 * (sum(y[deep_idx, "C14"]) / sum(y[deep_idx, "C"]) - 1),
      ocean_C_GtC       = sum(y[ocean_idx, "C"]),
      land_C_GtC        = sum(y[unlist(lapply(HEMIS, function(h)
                            aux$idx[[h]]$land)), "C"]),
      veg_C_GtC         = sum(y[unlist(lapply(HEMIS, function(h)
                            c(aux$idx[[h]]$leaf, aux$idx[[h]]$wood))), "C"]),
      soil_slow_C_GtC   = sum(y[unlist(lapply(HEMIS, function(h)
                            aux$idx[[h]]$soil_slow)), "C"]),
      prod_c14_mol_yr   = prod,
      prod_canonical    = P_canon,
      prod_ratio        = prod / P_canon
    )
  )
}

#' Pretty-print the spinup diagnostics
ccx_report_spinup <- function(s) {
  d <- s$diagnostics
  cat("=== preindustrial spinup ===\n")
  cat(sprintf("  residual |dC/dt|     %.3e GtC/yr  (must be ~0)\n", d$max_abs_dCdt))
  cat(sprintf("  residual |dC13/dt|   %.3e\n", d$max_abs_dC13dt))
  cat(sprintf("  residual |dC14/dt|   %.3e\n", d$max_abs_dC14dt))
  cat(sprintf("  CO2                  %.2f ppm   (target %.2f)\n",
              d$co2_ppm, ccx_const("CO2_PI_PPM")))
  cat(sprintf("  atmospheric d13C     %+.3f permil (target %+.3f)\n",
              d$d13c_atm, ccx_const("D13C_PI")))
  cat(sprintf("  atmospheric D14C     %+.3f permil (target %+.3f)\n",
              d$d14c_atm, ccx_const("D14C_PI")))
  cat(sprintf("  deep-ocean D14C      %+.1f permil  (free check: obs ~ -150 to -200)\n",
              d$d14c_deep_ocean))
  cat(sprintf("  ocean carbon         %.0f GtC\n", d$ocean_C_GtC))
  cat(sprintf("  land carbon          %.0f GtC  (vegetation %.0f, passive soil %.0f)\n",
              d$land_C_GtC, d$veg_C_GtC, d$soil_slow_C_GtC))
  cat(sprintf("  natural 14C prod     %.0f mol/yr   vs canonical %.0f  (ratio %.2f)\n",
              d$prod_c14_mol_yr, d$prod_canonical, d$prod_ratio))
  invisible(d)
}
