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
# exact linear solves, because both tracers enter the derivative LINEARLY once the
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
#' the DERIVATIVE ITSELF as the residual so the solve cannot disagree with the
#' model it is solving. GLOBAL preindustrial CO2 is the pin; the split is free.
#' Started from the analytic equilibrium, which is within ~1 %.
#' The 13C/14C solves downstream need no change: they invert whatever linear
#' operator the carbon field presents, exactly as before.
ccx_c12_steady_conveyor <- function(p0, aux, grid, chi0, y, forc,
                                    tol = 1e-9, maxit = 30L, prep = NULL) {
  boxes <- seq_len(nrow(y))
  # flattened ONCE: the forcing is constant across the ~70 derivative calls
  fv <- ccx_cpp_forcing_vec(forc)
  atm   <- c(aux$idx$NH$atm, aux$idx$SH$atm)
  # Global preindustrial CO2 is the physical pin. The interhemispheric SPLIT is
  # not pinned -- it is what has to move, and forbidding it is what left the
  # 0.1226 GtC/yr residual sitting in the two atmosphere boxes.
  c_atm_target <- chi0 * aux$gtc_per_ppm_hemi * length(atm)
  ii      <- ccx_inert_idx(aux)
  c_inert <- unlist(aux$soil_inert[HEMIS], use.names = FALSE)[seq_along(ii)]

  resid <- function(cv) {
    yy <- y; yy[, "C"] <- cv
    r  <- ccx_deriv_fast(yy, 1750, p0, fv, grid, aux, prep = prep)[, "C"]
    # The operator conserves carbon, so the steady-state system is rank
    # deficient by one. Trade one equation for the pin; the dropped row is then
    # implied by the other 31 plus conservation.
    r[atm[1]] <- sum(cv[atm]) - c_atm_target
    # the INERT soil boxes (2026-09-30): no fluxes, so their rows and columns
    # are zero and the Jacobian would be singular -- pin them to their stock.
    if (length(ii)) r[ii] <- cv[ii] - c_inert
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

# ---- WHY THIS FILE CALLS `ccx_deriv_fast()`, NOT `ccx_deriv()` (2026-09-03) --
# ⭐ THE SPINUP WAS 84 % OF EVERY OBJECTIVE EVALUATION, AND 91 % OF THE SPINUP WAS
# THE INTERPRETED DERIVATIVE. Profiled, not assumed: the transient -- 275 years,
# 13,200 RK4 steps, 52,800 derivative calls -- runs in the C++ core in 0.028 s,
# while re-deriving the 1750 equilibrium cost 0.125 s. The spinup makes ~135
# derivative calls per evaluation, and every one of them went through R:
#   * 68 in ccx_c12_steady_conveyor()'s Newton -- a 32-column finite-difference
#     Jacobian, which runs whenever the PUMP is on, not just the conveyor;
#   * 67 building the two isotope operators one column at a time, plus the
#     closing residual.
# `ccx_deriv_fast()` is the SAME SIGNATURE and the same model, so this is a
# substitution and not a reformulation.
#
# ⚠ THE TWO CORES ARE **NOT** BIT-IDENTICAL, AND THAT IS PRICED, NOT ASSUMED.
# test-parity.R bounds their disagreement ANALYTICALLY at 8.5e-15 relative --
# floating-point reassociation of the pump's own 20 flux terms, nothing else --
# which is five orders below this Newton's 1e-9 residual tolerance and eight
# below its 1e-7 finite-difference step, so neither the Jacobian nor the
# convergence test can feel it.
# MEASURED END TO END at the 26-parameter mode: the logpost moves
# **+1.155e-10 absolute, 7.98e-14 relative** -- against the port gate's own
# 1e-8, i.e. inside it by five orders. Spinup 0.1252 -> 0.0178 s (7.0x), full
# evaluation 0.1404 -> 0.0483 s (**2.9x**).
# ⇒ Stored logposts, port targets and checkpoint `ref_logpost` stamps all remain
#   valid: every one of those gates is 1e-8 relative and this is 8e-14.
#
# MARSHALLED ONCE (2026-09-12, review B2). Each of those ~190 calls re-ran
# `ccx_cpp_par(p0)` and `ccx_cpp_aux(aux, grid)` -- about half the spinup's
# wall time. `ccx_deriv_prepare()` builds both once from the SAME `(p0, aux,
# grid)` and the calls pass the prepared pair; the forcing is flattened once
# per constant forcing. The bytes reaching `ccx_deriv_cpp` are unchanged, so
# this is bit-identical by construction and was measured so at hilda31s/p.

# ---------------------------------------------------------------------
#' THE spinup diagnostics, computed ONCE for both spinups
#'
#' WHY THIS IS A FUNCTION AND NOT A BLOCK INSIDE `ccx_spinup()`. There are now
#' TWO spinups -- the aseasonal fixed point here and the periodic (limit-cycle)
#' solve in `R/periodic_spinup.R` -- and the second was built by
#' inheriting the first's `$diagnostics` list and overwriting the six fields it
#' recomputed. Everything else silently carried the SEED's value: `d13c_atm`,
#' `d14c_atm`, every deep/bottom/HS D14C row, the land inventories, and -- the
#' sharpest of them -- `prod_c14_mol_yr` and `prod_ratio`, which disagreed with
#' the object's OWN `$prod_c14` because the periodic solve re-solves production.
#' A caller could read a plausible number that belonged to a different state.
#' ⇒ ONE producer, ONE definition of every row that is a pure function of the
#' state ([[two_gates_one_mechanism]] -- the same defect family as the 09-09t
#' leak, where two cores read two different objects).
#'
#' ⚠ THE TWO ESTIMATOR-DEPENDENT ROWS ARE REQUIRED ARGUMENTS, NOT DEFAULTS.
#' `residuals` and `co2_ppm` mean genuinely different things in the two solves --
#' an instantaneous |dy/dt| against |Phi(y) - y| over one period, and an
#' instantaneous atmospheric burden against an ANNUAL MEAN over the orbit. A
#' default for either would let one caller inherit the other's convention, which
#' is exactly the failure this refactor exists to remove
#' ⇒ [[verify_the_quantity_not_the_word]]. Every OTHER row is a pure function of
#' `(y, prod, aux, grid)` and is computed here for both.
#'
#' @param y     state matrix
#' @param prod  the 14C production this state was solved at, mol/yr
#' @param residuals named list(C=, C13=, C14=) -- the CALLER's own convergence
#'   measure, on the caller's own definition.
#' @param co2_ppm the CALLER's own atmospheric CO2 estimator, ppm.
ccx_spinup_diagnostics <- function(y, prod, aux, grid, residuals, co2_ppm) {
  if (!all(c("C", "C13", "C14") %in% names(residuals)))
    stop("ccx_spinup_diagnostics(): `residuals` needs elements C, C13 and C14 ",
         "-- the caller's own convergence measure, since the two spinups do not ",
         "share a definition of one.")
  if (!is.numeric(co2_ppm) || length(co2_ppm) != 1L || !is.finite(co2_ppm))
    stop("ccx_spinup_diagnostics(): `co2_ppm` must be the caller's own single ",
         "finite atmospheric estimator; there is deliberately no default.")

  atm_idx <- c(aux$idx$NH$atm, aux$idx$SH$atm)
  d14c_atm <- 1000 * (sum(y[atm_idx, "C14"]) / sum(y[atm_idx, "C"]) - 1)
  d13c_atm <- 1000 * (sum(y[atm_idx, "C13"]) /
                        (sum(y[atm_idx, "C"]) * ccx_const("R13_VPDB")) - 1)
  # HS and HD ARE ocean carbon and belong in the inventory; `$hs`/`$hd` are NULL
  # when the structure is off, and c() drops them, so this is the same vector.
  ocean_idx <- unlist(lapply(HEMIS, function(h)
    c(aux$idx[[h]]$ml, aux$idx[[h]]$oc, aux$idx[[h]]$hs, aux$idx[[h]]$hd, aux$idx[[h]]$eq,
      aux$idx[[h]]$tr)))
  deep_idx  <- unlist(lapply(HEMIS, function(h) tail(aux$idx[[h]]$oc, 3)))
  bot_idx   <- unlist(lapply(HEMIS, function(h) tail(aux$idx[[h]]$oc, 1)))

  # canonical cosmogenic production, for comparison ONLY
  P_canon <- 2.04 * (5.1e14 * 1e4) * 365.25 * 86400 / 6.02214076e23

  list(
    max_abs_dCdt      = residuals$C,
    max_abs_dC13dt    = residuals$C13,
    max_abs_dC14dt    = residuals$C14,
    co2_ppm           = co2_ppm,
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
    # THE HIGH-LATITUDE BOXES, reported SEPARATELY and NOT folded into any row
    # above. `d14c_bottom_box` is the quantity every iso-deep protocol in this
    # repo re-solves kz against, and the kz bracket was derived from it; a
    # structural change that quietly redefined it would make every stored
    # number non-comparable in exactly the way nothing would catch.
    # NA when the structure is off, so a caller cannot read a stale 0 as data.
    d14c_hs = if (aux$hs_on == 1L) vapply(HEMIS, function(h) {
      k <- aux$idx[[h]]$hs; 1000 * (y[k, "C14"] / y[k, "C"] - 1)
    }, numeric(1)) else stats::setNames(rep(NA_real_, length(HEMIS)), HEMIS),
    d14c_hd = if (aux$hs_on == 1L) vapply(HEMIS, function(h) {
      k <- aux$idx[[h]]$hd; 1000 * (y[k, "C14"] / y[k, "C"] - 1)
    }, numeric(1)) else stats::setNames(rep(NA_real_, length(HEMIS)), HEMIS),
    ocean_C_GtC       = sum(y[ocean_idx, "C"]),
    land_C_GtC        = sum(y[unlist(lapply(HEMIS, function(h)
                          aux$idx[[h]]$land)), "C"]),
    veg_C_GtC         = sum(y[unlist(lapply(HEMIS, function(h)
                          c(aux$idx[[h]]$leaf, aux$idx[[h]]$wood))), "C"]),
    soil_slow_C_GtC   = sum(y[unlist(lapply(HEMIS, function(h)
                          aux$idx[[h]]$soil_slow)), "C"]),
    # the INERT soil pool (2026-09-30), 0 when absent. `land_C_GtC` above
    # already includes it (aux$idx$land does); this row names it.
    soil_inert_C_GtC  = sum(y[ccx_inert_idx(aux), "C"]),
    prod_c14_mol_yr   = prod,
    prod_canonical    = P_canon,
    prod_ratio        = prod / P_canon
  )
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
  y    <- ccx_new_state(grid$nl, ccx_hs_on(p), ccx_eq_on(p), ccx_tr_on(p), ccx_inert_on(p))

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
    # The passive share is the EXCHANGING one (ccx_litter_slow_eff(), the inert
    # carve-out of 2026-09-30); the inert stock is aux$soil_inert and has no
    # fixed point to solve.
    npp0 <- aux$npp0[[h]]
    lsf  <- ccx_litter_slow_eff(p)
    y[i$leaf, "C"] <- npp0 * p$npp_leaf_frac * p$tau_leaf
    y[i$wood, "C"] <- npp0 * (1 - p$npp_leaf_frac) * p$tau_wood
    y[i$soil_fast, "C"] <- npp0 * (1 - lsf) * p$tau_soil_fast
    y[i$soil_slow, "C"] <- npp0 * lsf * p$tau_soil_slow
    # the INERT soil box, when it exists: its stock is fixed, not solved
    if (!is.null(i[[CCX_LAND_INERT]])) y[i[[CCX_LAND_INERT]], "C"] <- aux$soil_inert[[h]]

    # ocean: mixed layer in Henry equilibrium with the atmosphere; the interior
    # is at uniform CONCENTRATION, so C_k scales with layer thickness (this is
    # exactly the zero-flux condition of the diffusion discretisation).
    # STILL EXACT WITH OVERTURNING ON (w_up > 0): the upwelling limb carries
    # w_up * A * conc across every interface and the sinking limb returns the
    # same volume flux at the same concentration, so a uniform column has zero
    # advective tendency too. The 13C/14C solves need no change either -- they
    # invert whatever linear operator the derivative presents. test-ocean-advection.R
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
    # GtC per metre of the INTERIOR column. With the equatorial cell on (D1,
    # 2026-09-13g) the mixed layer covers a_ml < a_ls, so "the ML's carbon per
    # metre" is scaled up by a_ls/a_ml to be the interior's; with the cell
    # off the ratio is not formed and this is the 09-13d line, bit for bit.
    conc <- y[i$ml, "C"] / grid$dz[1]
    # `d1_on`, not `eq_on` (review 09-16 c, finding 7): the tropical box ALONE
    # also shrinks a_ml below a_ls (the 09-15 d audit's class); the Newton
    # absorbed the wrong guess, so no result moved -- the guess is now right.
    if (isTRUE(aux$d1_on == 1L)) conc <- conc * (aux$a_ls[[h]] / aux$a_ml[[h]])
    y[i$oc, "C"] <- conc * grid$dz[-1]

    # THE HIGH-LATITUDE COLUMN, when it exists: HS in Henry equilibrium with the
    # atmosphere at ITS OWN temperature, HD uniform beneath it. This is only a
    # STARTING GUESS and cannot be the fixed point -- HS is colder than the
    # mixed layer, so the two columns sit at different DIC and the exchange
    # limbs see a real gradient, exactly as the conveyor does between
    # hemispheres. ccx_c12_steady_conveyor() below finishes the job, and its
    # gate is widened to include this structure for that reason.
    if (!is.null(i$hs)) {
      dic_h <- ccx_dic_for_pco2(chi0,
                                if (is.null(aux$alk_hs)) ccx_const("ALK_SURFACE") else aux$alk_hs,
                                aux$sst_hs)
      y[i$hs, "C"] <- dic_h * aux$hs_mass_kg[[h]] / aux$mol_per_GtC
      y[i$hd, "C"] <- dic_h * aux$a_hs[[h]] * (if (is.null(aux$thick_hd)) aux$dz_hd else aux$thick_hd[[h]]) *   # per-hemisphere HD thickness (2026-09-21 e)
                      ccx_const("RHO_SEAWATER") / aux$mol_per_GtC
    }

    # THE EQUATORIAL CELL, when it exists: in Henry equilibrium with the
    # atmosphere at ITS OWN temperature and alkalinity (the HS idiom). A
    # STARTING GUESS only -- the cell is warmer than the mixed layer, so the
    # loop sees a real gradient and ccx_c12_steady_conveyor() finishes it;
    # its gate below includes the cell for that reason (prereg 09-13g, (b)).
    if (!is.null(i$eq)) {
      dic_e <- ccx_dic_for_pco2(chi0, aux$alk_eq, aux$sst_eq)
      y[i$eq, "C"] <- dic_e * aux$eq_mass_kg[[h]] / aux$mol_per_GtC
    }
    # THE TROPICAL SURFACE BOX (2026-09-14f), the same idiom: its own Henry
    # point at its own SST and alkalinity as the starting guess; the diffusive
    # interface with layer 1 and the loop see a real gradient, so the Newton
    # solve below finishes it (its gate includes the box).
    if (!is.null(i$tr)) {
      dic_t <- ccx_dic_for_pco2(chi0, aux$alk_tr, aux$sst_tr)
      y[i$tr, "C"] <- dic_t * aux$tr_mass_kg[[h]] / aux$mol_per_GtC
    }
  }

  # ---- forcing at equilibrium: nothing external ----------------------
  zero_forc <- function(prod = 0) {
    # `land_enso` (W1, 2026-10-02): a CONSTANT, ENSO-free forcing's lagged index is the
    # index itself, 0. Without it a lagged parameter set is refused by ccx_deriv() --
    # correctly for a bare point forcing, but this one is constant by construction.
    list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
         gmst = 0, enso = 0, land_enso = 0, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = prod)
  }
  p0 <- p; p0 <- ccx_set_enso(p0, list(gamma_enso = 0))
  # seasonal term integrates to zero over a year; evaluate the annual-mean state.
  # BOTH seasonal paths must be off here: the sine via its amplitudes, and the
  # 2026-08-18 driver path via its switch -- n(t)-1 and the Q10 modulation are
  # zero-mean over a year but NOT zero at the single t this solve evaluates,
  # and leaving them on makes the isotope operator singular.
  p0$seas_amp_NH <- 0; p0$seas_amp_SH <- 0
  p0$seas_drivers <- 0
  # the marshalled (p0, aux, grid), built once for every derivative call below
  prep <- ccx_deriv_prepare(p0, aux, grid)

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
  if (!is.null(ccx_conveyor_geom(p, grid)) || !is.null(aux$pump) || aux$hs_on == 1L ||
      aux$eq_on == 1L || aux$tr_on == 1L)
    y <- ccx_c12_steady_conveyor(p0, aux, grid, chi0, y, zero_forc(0), prep = prep)

  nb <- nrow(y)

  # ---- helper: linear operator of ccx_deriv acting on one isotope -----
  # dy_iso/dt = A %*% y_iso + b, exact because the isotope enters linearly.
  iso_operator <- function(tracer, forc) {
    fv <- ccx_cpp_forcing_vec(forc)
    y0 <- y; y0[, tracer] <- 0
    b  <- ccx_deriv_fast(y0, 1750, p0, fv, grid, aux, prep = prep)[, tracer]
    A  <- matrix(0, nb, nb)
    for (j in seq_len(nb)) {
      yj <- y0; yj[j, tracer] <- 1
      A[, j] <- ccx_deriv_fast(yj, 1750, p0, fv, grid, aux, prep = prep)[, tracer] - b
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
  # the INERT soil boxes: a zero row (13C conserved, no exchange) -- pin to 0,
  # then give them the passive pool's ratio. Nothing reads them, so it is exact.
  ii <- ccx_inert_idx(aux)
  for (k in ii) { A13[k, ] <- 0; A13[k, k] <- 1; rhs[k] <- 0 }
  y[, "C13"] <- solve(A13, rhs)
  y <- ccx_inert_c13(y, aux)

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
  # Every row that is a pure function of the state comes from the ONE producer
  # `ccx_spinup_diagnostics()`, shared with the periodic spinup. The two rows
  # that are estimator-dependent are supplied HERE, on THIS solve's own
  # definitions: an instantaneous derivative, and the instantaneous atmospheric
  # burden (which on an aseasonal fixed point is trivially also its annual mean).
  resid <- ccx_deriv_fast(y, 1750, p0, zero_forc(prod), grid, aux, prep = prep)

  list(
    y = y, prod_c14 = prod, aux = aux, grid = grid, params = p,
    diagnostics = ccx_spinup_diagnostics(
      y, prod, aux, grid,
      residuals = list(C   = max(abs(resid[, "C"])),
                       C13 = max(abs(resid[, "C13"])),
                       C14 = max(abs(resid[, "C14"]))),
      co2_ppm   = sum(y[c(aux$idx$NH$atm, aux$idx$SH$atm), "C"]) /
                    ccx_const("GtC_PER_PPM"))
  )
}

#' EVERY carbon stock in a state, GtC, from the model's own index map (2026-09-30)
#'
#' The ONE stock readout for comparisons against inventories and ESMs
#' (Marcus 2026-09-30: "make sure the stock readouts contain all the carbon pools
#' to make it consistent with whatever comparisons we are doing"). Built from
#' `aux$idx`, never from names or positions, so a box added later cannot be
#' dropped silently: the reservoir sums must add up to the whole state, and the
#' function STOPS if they do not.
#'
#' Rows: atmosphere; vegetation (leaf + wood); soil_fast (responsive); soil_slow
#' (the EXCHANGING passive pool); soil_inert (radiocarbon-free, 0 when absent);
#' soil_total (all three); land_total (vegetation + soil_total, = the out
#' column land_C); ocean_surface (mixed layer + hs/eq/tr); ocean_interior
#' (interior layers + hd); ocean_total (= ocean_C); total.
#' ⚠ WHAT IT CANNOT HOLD: carbon the model does not represent at all -- permafrost
#' (AR6 WG1 Fig. 5.12: ~1200 PgC), soil below the passive pool's 0-1 m scope,
#' marine sediments, fossil reserves. A comparison against those needs them added
#' on the OTHER side, not here.
ccx_stock_readout <- function(y, aux) {
  ix  <- function(nm) unlist(lapply(HEMIS, function(h) aux$idx[[h]][[nm]]), use.names = FALSE)
  s   <- function(i) if (length(i)) sum(y[i, "C"]) else 0
  atm <- s(ix("atm")); veg <- s(c(ix("leaf"), ix("wood")))
  sf  <- s(ix("soil_fast")); ss <- s(ix("soil_slow")); si <- s(ix(CCX_LAND_INERT))
  surf <- s(c(ix("ml"), ix("hs"), ix("eq"), ix("tr"))); intr <- s(c(ix("oc"), ix("hd")))
  out <- c(atmosphere = atm, vegetation = veg, soil_fast = sf, soil_slow = ss, soil_inert = si,
           soil_total = sf + ss + si, land_total = veg + sf + ss + si,
           ocean_surface = surf, ocean_interior = intr, ocean_total = surf + intr,
           total = atm + veg + sf + ss + si + surf + intr)
  covered <- sort(c(ix("atm"), ix("leaf"), ix("wood"), ix("soil_fast"), ix("soil_slow"), ix(CCX_LAND_INERT),
                    ix("ml"), ix("hs"), ix("eq"), ix("tr"), ix("oc"), ix("hd")))
  if (!identical(covered, seq_len(nrow(y))))
    stop("ccx_stock_readout(): the reservoir map does not cover the state exactly once -- ",
         "a box was added without a readout class (boxes ", nrow(y), ", covered ", length(covered), ")")
  land_idx <- unlist(lapply(HEMIS, function(h) aux$idx[[h]]$land), use.names = FALSE)
  if (!isTRUE(all.equal(out[["land_total"]], sum(y[land_idx, "C"]), tolerance = 1e-12)))
    stop("ccx_stock_readout(): land_total disagrees with aux$idx$land")
  out
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
  cat(sprintf("  land carbon          %.0f GtC  (vegetation %.0f, passive soil %.0f, inert soil %.0f)\n",
              d$land_C_GtC, d$veg_C_GtC, d$soil_slow_C_GtC,
              if (is.null(d$soil_inert_C_GtC)) 0 else d$soil_inert_C_GtC))
  cat(sprintf("  natural 14C prod     %.0f mol/yr   vs canonical %.0f  (ratio %.2f)\n",
              d$prod_c14_mol_yr, d$prod_canonical, d$prod_ratio))
  invisible(d)
}
