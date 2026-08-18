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

# ---------------------------------------------------------------------
#' 12C steady state when the CONVEYOR is on. FULL STATE, not the ocean alone.
#'
#' WHY THIS EXISTS, AND WHY THE ANALYTIC EQUILIBRIUM IS NOT ENOUGH.
#' Handoff 2026-08-13b sec.4.2 asserts that the conveyor leaves `ccx_spinup()`
#' untouched, on the grounds that every box gains Q and loses Q so a
#' uniform-concentration ocean is still an exact fixed point. **That is true
#' within a column and false between them.** The two columns are NOT at the same
#' concentration: SST 18 vs 16 degC gives preindustrial DIC 2.03786 vs 2.05570
#' mol/m3, a 0.87 % difference, so the interhemispheric limbs -- the first
#' ocean-ocean coupling in the model -- see a real gradient and converge
#' 0.135 GtC/yr into the NH at 20 Sv.
#'
#' MEASURED CONSEQUENCE of skipping this solve: the spinup residual goes from
#' 6.3e-09 to 1.35e-01 GtC/yr, and over a zero-emission 1750-2024 run the
#' atmospheric d13C DRIFTS -0.915 permil against -0.036 with the conveyor off.
#' That artefact is nearly twice the entire d13C misfit the conveyor was
#' proposed to fix. DIAGNOSED, not guessed: setting sst_NH = sst_SH = 17 returns
#' both the residual (5.15e-09) and the drift (-0.0362) to their conveyor-off
#' values exactly.
#'
#' Note what this also means physically: between columns the conveyor is NOT the
#' pure isotope operator it is within one. It carries carbon from the colder,
#' DIC-richer hemisphere to the warmer one -- a crude solubility pump the model
#' did not previously have.
#'
#' WHY THE FULL STATE AND NOT JUST THE OCEAN. An ocean-only solve with both
#' atmospheres pinned at chi0 was tried first and left exactly 0.1226 GtC/yr
#' sitting in the two atmosphere boxes, equal and opposite. That is not an
#' error to squash: the conveyor makes one hemisphere's mixed layer OUTGAS and
#' the other INGAS, so the preindustrial atmosphere must carry a small
#' interhemispheric gradient for tau_ex to move the difference back. Pinning
#' both hemispheres at chi0 forbids the very thing that has to move. The land is
#' in the solve for the same reason -- its analytic fixed point is conditional on
#' chi, and chi is no longer identical in the two hemispheres.
#'
#' So: Newton on every box's carbon, with a finite-difference Jacobian, using
#' ccx_deriv() ITSELF as the residual so the solve cannot disagree with the
#' model it is solving. GLOBAL preindustrial CO2 is the pin; the split is free.
#' Started from the analytic equilibrium, which is within ~1 %.
#' The 13C/14C solves downstream need no change: they invert whatever linear
#' operator the carbon field presents, exactly as before.
ccx_c12_steady_conveyor <- function(p0, aux, grid, chi0, y, forc,
                                    tol = 1e-9, maxit = 30L) {
  boxes <- seq_len(nrow(y))
  atm   <- c(aux$idx$NH$atm, aux$idx$SH$atm)
  # Global preindustrial CO2 is the physical pin. The interhemispheric SPLIT is
  # not pinned -- it is what has to move, and forbidding it is what left the
  # 0.1226 GtC/yr residual sitting in the two atmosphere boxes.
  c_atm_target <- chi0 * aux$gtc_per_ppm_hemi * length(atm)

  resid <- function(cv) {
    yy <- y; yy[, "C"] <- cv
    r  <- ccx_deriv(yy, 1750, p0, forc, grid, aux)[, "C"]
    # The operator conserves carbon, so the steady-state system is rank
    # deficient by one. Trade one equation for the pin; the dropped row is then
    # implied by the other 31 plus conservation.
    r[atm[1]] <- sum(cv[atm]) - c_atm_target
    r
  }

  cv <- y[, "C"]
  for (it in seq_len(maxit)) {
    r <- resid(cv)
    if (max(abs(r)) < tol) break
    J <- matrix(0, length(boxes), length(boxes))
    for (j in boxes) {
      dh <- max(1e-7 * abs(cv[j]), 1e-8)
      cp <- cv; cp[j] <- cp[j] + dh
      J[, j] <- (resid(cp) - r) / dh
    }
    step <- tryCatch(solve(J, -r), error = function(e) NULL)
    if (is.null(step)) stop("conveyor 12C spinup: singular Jacobian")
    cv <- cv + step
  }
  fin <- max(abs(resid(cv)))
  if (fin >= tol)
    warning(sprintf("conveyor 12C spinup did not converge: |resid| = %.3e", fin))
  y[, "C"] <- cv
  y
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
    # STILL EXACT WITH OVERTURNING ON (w_up > 0): the upwelling limb carries
    # w_up * A * conc across every interface and the sinking limb returns the
    # same volume flux at the same concentration, so a uniform column has zero
    # advective tendency too. The 13C/14C solves need no change either -- they
    # invert whatever linear operator ccx_deriv() presents. test-ocean-advection.R
    # holds both statements.
    #
    # NOT EXACT WITH THE CONVEYOR ON, and this is the one place the two differ.
    # w_up and w_out are WITHIN-column, where uniformity holds. The conveyor
    # couples the two columns, and they sit at DIFFERENT concentrations (SST 18
    # vs 16 degC -> DIC 2.03786 vs 2.05570 mol/m3). So the block below is only a
    # starting guess and ccx_ocean_c12_steady() finishes the job -- see its
    # header for the measured consequence of skipping it (-0.915 permil of
    # spurious d13C drift).
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
  # seasonal term integrates to zero over a year; evaluate the annual-mean state.
  # BOTH seasonal paths must be off here: the sine via its amplitudes, and the
  # 2026-08-18 driver path via its switch -- n(t)-1 and the Q10 modulation are
  # zero-mean over a year but NOT zero at the single t this solve evaluates,
  # and leaving them on makes the isotope operator singular.
  p0$seas_amp_NH <- 0; p0$seas_amp_SH <- 0
  p0$seas_drivers <- 0

  # Finish the 12C state when the conveyor couples the two columns. The analytic
  # equilibrium above is only a starting guess then -- see the function header.
  # No-op when the conveyor is off, so every pre-2026-08-13 result is
  # bit-reproduced, and it is placed HERE because it must use the same p0 and
  # zero forcing the residual diagnostic is measured with.
  # THE ANALYTIC EQUILIBRIUM ABOVE IS A UNIFORM COLUMN, and both the conveyor and
  # the biological pump stop that being a fixed point -- the pump ON PURPOSE,
  # since holding a non-zero interior gradient is the entire mechanism. Either
  # one therefore needs the full-state Newton solve. With both off it is a no-op
  # on an already-exact fixed point, which is why the branch is gated rather than
  # unconditional: the no-pump, no-conveyor model stays bit-identical.
  if (!is.null(ccx_conveyor_geom(p, grid)) || !is.null(aux$pump))
    y <- ccx_c12_steady_conveyor(p0, aux, grid, chi0, y, zero_forc(0))

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
  bot_idx   <- unlist(lapply(HEMIS, function(h) tail(aux$idx[[h]]$oc, 1)))

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
      # SPLIT PER HEMISPHERE 2026-08-13, before the conveyor was wired up. The
      # combined figure above averages BOTH columns' bottom three layers, which
      # is meaningless under a conveyor: the ventilated end should come out
      # YOUNG and the far end OLD -- the observed young-North-Atlantic /
      # old-deep-Pacific pattern, and a structural improvement on anything the
      # model has managed. Reading the average would hide exactly the signal the
      # reverse-conveyor gate is testing for. The combined value is kept because
      # every pre-conveyor result and the kz bracket were derived from it.
      d14c_deep_by_hemi = vapply(HEMIS, function(h) {
        k <- tail(aux$idx[[h]]$oc, 3)
        1000 * (sum(y[k, "C14"]) / sum(y[k, "C"]) - 1)
      }, numeric(1)),
      # THE BOTTOM BOX ALONE, added 2026-08-14 -- and it is a DIFFERENT LAYER
      # from the two above, which is why it exists.
      #
      # At h_ml 75 the 11-box column puts box 11 at 2627.2-3700 m, and that is
      # the layer data-raw/build_glodap_deep_targets.R measured GLODAPv2 over.
      # `d14c_deep_ocean` and `d14c_deep_by_hemi` average the bottom THREE
      # interior boxes, i.e. 1313.6-3700 m -- a genuinely shallower and better
      # ventilated slab. The two are 13-20 permil apart across the kz bracket
      # (kz 5000: -186.4 here against -170.1 there), so scoring the GLODAP
      # 2627-3700 m mean against the 3-box average would be a layer mismatch of
      # ~1.6 sigma. The build script's header asserted they were the same layer;
      # they are not, and that claim is corrected there.
      #
      # The transient run moves this by 0.04 permil between 1750 and 2024 at
      # default kz (measured, calibration/diag_deep_d14c_term.R), so the
      # preindustrial steady state IS the right thing to score modern bottle
      # data against and no transient integration is needed for it.
      #
      # The two older diagnostics are kept unchanged: every pre-2026-08-14
      # result and the kz bracket itself were derived from them.
      d14c_bottom_box   = 1000 * (sum(y[bot_idx, "C14"]) / sum(y[bot_idx, "C"]) - 1),
      d14c_bottom_by_hemi = vapply(HEMIS, function(h) {
        k <- tail(aux$idx[[h]]$oc, 1)
        1000 * (sum(y[k, "C14"]) / sum(y[k, "C"]) - 1)
      }, numeric(1)),
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
  cat(sprintf("  deep-ocean D14C      %+.1f permil  (bottom 3 boxes, 1314-3700 m)\n",
              d$d14c_deep_ocean))
  cat(sprintf("    by hemisphere      NH %+.1f   SH %+.1f  (equal without a conveyor;\n",
              d$d14c_deep_by_hemi[["NH"]], d$d14c_deep_by_hemi[["SH"]]))
  cat("                         under one, expect the ventilated end YOUNG)\n")
  tg <- ccx_deep_d14c_target()
  if (is.null(tg)) {
    cat(sprintf("  bottom-box D14C      %+.1f permil  (2627-3700 m; GLODAP target ABSENT)\n",
                d$d14c_bottom_box))
  } else {
    cat(sprintf("  bottom-box D14C      %+.1f permil  (2627-3700 m; GLODAPv2 %+.1f +/- %.1f = %+.2f sigma)\n",
                d$d14c_bottom_box, tg$target, tg$sd,
                (d$d14c_bottom_box - tg$target) / tg$sd))
  }
  cat(sprintf("  ocean carbon         %.0f GtC\n", d$ocean_C_GtC))
  cat(sprintf("  land carbon          %.0f GtC  (vegetation %.0f, passive soil %.0f)\n",
              d$land_C_GtC, d$veg_C_GtC, d$soil_slow_C_GtC))
  cat(sprintf("  natural 14C prod     %.0f mol/yr   vs canonical %.0f  (ratio %.2f)\n",
              d$prod_c14_mol_yr, d$prod_canonical, d$prod_ratio))
  invisible(d)
}
