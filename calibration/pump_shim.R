# =====================================================================
# pump_shim.R -- THE ZERO-PARAMETER BIOLOGICAL PUMP, AS A SHIM. Shared by
# calibration/diag_dic_gradient.R (where it was written, 2026-08-15) and
# calibration/diag_pump_vs_gradient_terms.R (2026-08-16c).
#
# EXTRACTED VERBATIM on 2026-08-16 -- the code below is byte-for-byte the
# shim diag_dic_gradient.R carried inline, moved here so the two files cannot
# drift apart. Nothing about the physics changed in the move; the only addition
# is the double-source guard on the ccx_deriv() wrapper.
#
# NO MODEL FILE IS TOUCHED. The pump is a wrapper around ccx_deriv() installed
# in the GLOBAL environment, OFF by default (`.dg$on`), and it is NOT proposed
# for the objective by this file. It has ZERO FITTED PARAMETERS: the export
# profile is SOLVED for as the field that makes an observed DIC profile an exact
# steady state of the model's own diffusion operator. No Martin curve is chosen,
# no export formulation is fitted.
#
# THE C++ CORE DOES NOT KNOW ABOUT THE PUMP. Every run that uses this shim must
# go through the R reference integrator ccx_run(), which is why the callers cost
# ~50 s per arm rather than ~1 s. Porting to src/ccx_core.cpp is a shipping
# decision (task 9), and these diagnostics exist to decide whether to ship.
#
# REQUIRES: the R/ sources and ccx_load_cpp() already loaded. Source this AFTER
# them -- the wrapper captures whatever ccx_deriv() is bound at source time.
# =====================================================================

# Marine organic matter is ~20-22 permil depleted relative to the DIC it is
# fixed from. This is the one structural choice in the pump and callers run it
# BOTH WAYS rather than resolving it.
PUMP_EPS_ORG <- -20                    # permil, photosynthetic fractionation
# 14C rides the export WITHOUT fractionation, by the same Stuiver-Polach
# convention the rest of the model uses (DESIGN sec.3.5): Delta14C observations
# are already fractionation-corrected. That is a CONVENTION, not a choice.

# ---------------------------------------------------------------------
# THE OBSERVED PROFILE, ON THE MODEL'S OWN LAYERS. The export field is solved
# against a TARGET PROFILE, so the binning that produces that profile is part of
# the pump's construction -- but it is PURE DATA, and since 2026-09-02 GATE G
# needs the same helpers. They moved VERBATIM to calibration/lib_glodap_obs.R so
# there is one binning, not two; this file is not sourceable from a gate report
# because it wraps ccx_deriv(), which is exactly why they had to leave.
# ---------------------------------------------------------------------
source(ccx_path("calibration", "lib_glodap_obs.R"))

#' Export field that holds `target_dic` (umol/kg, length nl+1) as a steady state
#'
#' The diffusion code's concentration is y_k/dz_k, and y_k = DIC_k * A * dz_k *
#' rho / mol_per_GtC, so y_k/dz_k is EXACTLY proportional to DIC_k with the layer
#' thickness cancelling. That is what makes this solve a two-line calculation
#' rather than a fit.
#'
#' Steady state requires the source in box k to cancel the diffusive convergence
#' there:  S_k = -[F(k-1,k) - F(k,k+1)],  F(a,b) = kz (c_a - c_b) / dz_mid[a].
#' The sum telescopes, so the TOTAL export leaving the mixed layer is just the
#' flux across the topmost interface -- and THAT is a number with a literature
#' value attached, which makes this a validation and not only a construction.
#'
#' @return list(S = GtC/yr into each interior box, E = total export, ok = signs)
dg_export_field <- function(p, aux, grid, h, target_dic) {
  kappa <- aux$a_oc[[h]] * ccx_const("RHO_SEAWATER") / aux$mol_per_GtC  # GtC/m per (mol/kg)
  cc    <- kappa * target_dic * 1e-6                                    # GtC/m
  nl    <- grid$nl
  Fi    <- p$kz * (cc[-length(cc)] - cc[-1]) / aux$dz_mid               # nl interfaces
  S     <- numeric(nl)
  for (k in seq_len(nl)) S[k] <- -(Fi[k] - if (k < nl) Fi[k + 1] else 0)
  list(S = S, E = sum(S), n_neg = sum(S < 0), min_S = min(S))
}

# =====================================================================
# THE SHIM. No model file is touched.
# =====================================================================
.dg <- new.env(parent = emptyenv())
.dg$on <- FALSE; .dg$S <- NULL; .dg$mode <- "N"; .dg$eps <- PUMP_EPS_ORG
.dg$c_ml0 <- NULL

# DOUBLE-SOURCE GUARD, the one thing added in the extraction. Sourcing this file
# twice without it would capture the ALREADY-WRAPPED ccx_deriv() as the base and
# recurse forever. Re-sourcing the R/ directory rebinds a bare ccx_deriv(), which
# drops the attribute, so the guard correctly re-installs after that.
if (!isTRUE(attr(ccx_deriv, "ccx_pump_shim"))) {
  .dg_deriv_base <- ccx_deriv
  ccx_deriv <- function(y, t, p, forc, grid, aux, record = FALSE) {
    dy <- .dg_deriv_base(y, t, p, forc, grid, aux, record = record)
    if (!.dg$on) return(dy)
    if (record) stop("pump shim: the flux tap does not see the pump")
    a13 <- 1 + .dg$eps / 1000
    for (h in HEMIS) {
      i   <- aux$idx[[h]]
      S   <- .dg$S[[h]]
      # NUTRIENT-LIMITED ("N"): export mass is fixed, as in the standard
      # steady-pump assumption. DIC-LIMITED ("D"): export scales with the mixed
      # layer's carbon, which is the ONLY way channel 1 is non-zero.
      sc  <- if (.dg$mode == "D") y[i$ml, "C"] / .dg$c_ml0[[h]] else 1
      r13 <- y[i$ml, "C13"] / y[i$ml, "C"]
      r14 <- y[i$ml, "C14"] / y[i$ml, "C"]
      E   <- sum(S) * sc
      dy[i$ml, "C"]   <- dy[i$ml, "C"]   - E
      dy[i$ml, "C13"] <- dy[i$ml, "C13"] - E * r13 * a13
      dy[i$ml, "C14"] <- dy[i$ml, "C14"] - E * r14        # no fractionation
      f <- S * sc
      dy[i$oc, "C"]   <- dy[i$oc, "C"]   + f
      dy[i$oc, "C13"] <- dy[i$oc, "C13"] + f * r13 * a13
      dy[i$oc, "C14"] <- dy[i$oc, "C14"] + f * r14
    }
    dy
  }
  attr(ccx_deriv, "ccx_pump_shim") <- TRUE
}

#' Spinup that ALWAYS runs the full-state Newton solve.
#'
#' A NEAR-VERBATIM COPY of ccx_spinup(), with exactly two deltas, both marked
#' DELTA below. It exists because ccx_spinup()'s analytic equilibrium is a
#' uniform column, which stops being a fixed point the moment the pump is on,
#' and the Newton branch it already contains is gated on the conveyor.
#' THE COPY IS GATED: dg_parity_gate() asserts it reproduces ccx_spinup() with
#' the pump OFF, and it is run before anything else uses this function.
dg_spinup <- function(p = ccx_default_params(),
                      chi0  = ccx_const("CO2_PI_PPM"),
                      d13c0 = ccx_const("D13C_PI"),
                      d14c0 = ccx_const("D14C_PI")) {
  aux <- ccx_prepare(p); grid <- aux$grid; y <- ccx_new_state(grid$nl)
  for (h in HEMIS) {
    i <- aux$idx[[h]]
    y[i$atm, "C"] <- chi0 * aux$gtc_per_ppm_hemi
    npp0 <- aux$npp0[[h]]
    y[i$leaf, "C"] <- npp0 * p$npp_leaf_frac * p$tau_leaf
    y[i$wood, "C"] <- npp0 * (1 - p$npp_leaf_frac) * p$tau_wood
    y[i$soil_fast, "C"] <- npp0 * (1 - p$litter_slow_frac) * p$tau_soil_fast
    y[i$soil_slow, "C"] <- npp0 * p$litter_slow_frac * p$tau_soil_slow
    dic  <- ccx_dic_for_pco2(chi0, ccx_const("ALK_SURFACE"), aux$sst[[h]])
    y[i$ml, "C"] <- dic * aux$ml_mass_kg[[h]] / aux$mol_per_GtC
    conc <- y[i$ml, "C"] / grid$dz[1]
    y[i$oc, "C"] <- conc * grid$dz[-1]
  }
  zero_forc <- function(prod = 0)
    list(e_foss = list(NH = 0, SH = 0), e_luc = list(NH = 0, SH = 0),
         gmst = 0, enso = 0, c14_bomb = 0, c14_nuclear = 0, c14_cosmo = prod)
  p0 <- p; p0 <- ccx_set_enso(p0, list(gamma_enso = 0)); p0$seas_amp_NH <- 0; p0$seas_amp_SH <- 0

  # DELTA 1: the Newton solve is UNCONDITIONAL, not gated on the conveyor. With
  # the pump off it is a no-op on an already-exact fixed point (measured
  # max|dy| 1.0e-07 GtC), which is what the parity gate checks.
  y <- ccx_c12_steady_conveyor(p0, aux, grid, chi0, y, zero_forc(0))

  nb <- nrow(y)
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
  # DELTA 2: none in the isotope solves. They invert whatever linear operator
  # ccx_deriv() presents, and the pump term is linear in the ML's isotope
  # state, so they pick it up with no change at all.
  op13  <- iso_operator("C13", zero_forc(0))
  iatmN <- aux$idx$NH$atm
  A13 <- op13$A; rhs <- -op13$b
  A13[iatmN, ] <- 0; A13[iatmN, iatmN] <- 1
  rhs[iatmN] <- y[iatmN, "C"] * ccx_const("R13_VPDB") * (1 + d13c0 / 1000)
  y[, "C13"] <- solve(A13, rhs)

  op14 <- iso_operator("C14", zero_forc(1))
  u    <- solve(op14$A, -op14$b)
  atm_idx <- c(aux$idx$NH$atm, aux$idx$SH$atm)
  prod <- sum(y[atm_idx, "C"]) * (1 + d14c0 / 1000) / sum(u[atm_idx])
  y[, "C14"] <- prod * u

  resid    <- ccx_deriv(y, 1750, p0, zero_forc(prod), grid, aux)
  deep_idx <- unlist(lapply(HEMIS, function(h) tail(aux$idx[[h]]$oc, 3)))
  bot_idx  <- unlist(lapply(HEMIS, function(h) tail(aux$idx[[h]]$oc, 1)))
  ocean_idx<- unlist(lapply(HEMIS, function(h) c(aux$idx[[h]]$ml, aux$idx[[h]]$oc)))
  P_canon  <- 2.04 * (5.1e14 * 1e4) * 365.25 * 86400 / 6.02214076e23
  list(y = y, prod_c14 = prod, aux = aux, grid = grid, params = p,
       diagnostics = list(
         max_abs_dCdt    = max(abs(resid[, "C"])),
         max_abs_dC13dt  = max(abs(resid[, "C13"])),
         max_abs_dC14dt  = max(abs(resid[, "C14"])),
         co2_ppm         = sum(y[atm_idx, "C"]) / ccx_const("GtC_PER_PPM"),
         d14c_deep_ocean = 1000 * (sum(y[deep_idx, "C14"]) / sum(y[deep_idx, "C"]) - 1),
         d14c_bottom_box = 1000 * (sum(y[bot_idx,  "C14"]) / sum(y[bot_idx,  "C"]) - 1),
         d13c_bottom_box = 1000 * (sum(y[bot_idx, "C13"]) /
                                     (sum(y[bot_idx, "C"]) * ccx_const("R13_VPDB")) - 1),
         dic_bottom_box  = sum(y[bot_idx, "C"]) * aux$mol_per_GtC * 1e6 /
                             sum(vapply(HEMIS, function(h)
                               aux$a_oc[[h]] * grid$dz[grid$nl + 1] *
                                 ccx_const("RHO_SEAWATER"), numeric(1))),
         ocean_C_GtC     = sum(y[ocean_idx, "C"]),
         prod_c14_mol_yr = prod, prod_canonical = P_canon,
         prod_ratio      = prod / P_canon))
}

#' HARD GATE: the copy must reproduce the shipped spinup with the pump off.
dg_parity_gate <- function() {
  .dg$on <- FALSE
  a <- ccx_spinup(); b <- dg_spinup()
  worst <- max(abs(a$y - b$y)); dp <- abs(a$prod_c14 - b$prod_c14)
  cat(sprintf("\nPARITY GATE (pump OFF): max|dg_spinup - ccx_spinup| = %.3e GtC over %d states\n",
              worst, length(a$y)))
  cat(sprintf("                        |d prod_c14| = %.3e mol/yr\n", dp))
  if (worst > 1e-6 || dp > 1e-6)
    stop("dg_spinup() has drifted from ccx_spinup() -- fix the copy before reading anything below")
  cat("                        PASS -- the copy is the shipped spinup.\n")
  invisible(TRUE)
}
