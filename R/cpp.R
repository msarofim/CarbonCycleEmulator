# =====================================================================
# cpp.R — compile and drive the C++ core (src/ccx_core.cpp).
#
# The C++ core is a PORT of R/model.R, not a replacement for it. R stays the
# reference implementation; test-parity.R gates the two against each other on
# both a single derivative and a multi-decade integration. If they disagree,
# the C++ is wrong until proven otherwise.
# =====================================================================

# NB: parent must NOT be emptyenv() -- sourceCpp() evaluates assignments in this
# environment and needs `<-` resolvable from it.
.ccx_cpp_env <- new.env(parent = globalenv())

#' Compile the C++ core (once per session) and expose its functions
ccx_load_cpp <- function(quiet = TRUE) {
  if (isTRUE(.ccx_cpp_env$loaded)) return(invisible(TRUE))
  if (!requireNamespace("Rcpp", quietly = TRUE)) stop("Rcpp is required for the C++ core.")
  Rcpp::sourceCpp(ccx_path("src", "ccx_core.cpp"), env = .ccx_cpp_env,
                  verbose = FALSE, rebuild = FALSE, showOutput = !quiet)
  .ccx_cpp_env$loaded <- TRUE
  invisible(TRUE)
}

#' Flatten the R-side aux/grid/constants into the plain list the C++ unpacks
#'
#' Everything the core needs is resolved HERE, once, rather than looked up per
#' flux per RK stage as the R reference does -- that string-keyed lookup is a
#' large part of why the R version is slow, and it must not be reproduced in
#' the hot loop.
ccx_cpp_aux <- function(aux, grid, carb_iter = 6L) {
  cc <- carb_coefs()
  list(
    gtc_per_ppm_hemi = aux$gtc_per_ppm_hemi,
    chi0 = aux$chi0, mol_per_GtC = aux$mol_per_GtC,
    npp0 = c(aux$npp0$NH, aux$npp0$SH),
    veg0 = c(aux$veg0$NH, aux$veg0$SH),
    land0 = c(aux$land0$NH, aux$land0$SH),
    ml_mass_kg = c(aux$ml_mass_kg$NH, aux$ml_mass_kg$SH),
    asx = c(aux$asx$NH, aux$asx$SH),
    sst = c(aux$sst$NH, aux$sst$SH),
    dz = grid$dz, dz_mid = aux$dz_mid,
    a_oc = c(aux$a_oc$NH, aux$a_oc$SH),
    enso_share = c(aux$enso_share$NH, aux$enso_share$SH),
    dic0 = c(aux$dic0$NH, aux$dic0$SH),
    revelle0 = c(aux$revelle0$NH, aux$revelle0$SH),
    pco2_0 = c(aux$pco2_0$NH, aux$pco2_0$SH),
    alpha_photo = aux$alpha_photo,
    alpha_as_down = aux$alpha_as_down, alpha_as_up = aux$alpha_as_up,
    bomb_share_NH = aux$bomb_share_NH, nuc_share_NH = aux$nuc_share_NH,
    R13 = ccx_const("R13_VPDB"), R14STD = ccx_const("R14_STD"),
    lambda = ccx_const("LAMBDA_C14"), alk = ccx_const("ALK_SURFACE"),
    cK0 = cc$coefs$K0, cK1 = cc$coefs$K1, cK2 = cc$coefs$K2,
    cKb = cc$coefs$Kb, cKw = cc$coefs$Kw,
    t_centre = cc$t_centre, t_scale = cc$t_scale, boron = cc$boron_total,
    carb_iter = as.integer(carb_iter)
  )
}

#' Parameters in the flat form the C++ unpacks (gamma_enso defaults to 0)
ccx_cpp_par <- function(p) {
  if (is.null(p$gamma_enso)) p$gamma_enso <- 0
  if (is.null(p$revelle_frozen)) p$revelle_frozen <- 0
  # Land-structure parameters added 2026-08-12. Defaulted here as well as in
  # ccx_default_params() so that a hand-built or older parameter list cannot
  # reach the C++ with a missing name -- which unpacks as garbage, not an error.
  if (is.null(p$npp_veg_frac)) p$npp_veg_frac <- 0
  if (is.null(p$ra_ratio)) p$ra_ratio <- 0
  # Ocean overturning added 2026-08-13, default OFF. Same reasoning as above: a
  # parameter list built before that date must reach the core as the
  # pure-diffusion model it was written for, not as garbage.
  # Land-use permanence, added 2026-08-13. UNLIKE the switches above this does
  # NOT default to the old behaviour: a parameter list built before the fix is a
  # list built against a bug (land-use carbon with an airborne fraction of 0.002
  # at 100 years), so it defaults to the SAME named constant ccx_default_params()
  # uses. If the two ever disagree, the C++ core silently runs a different model
  # from the R one -- which is exactly what gamma_enso did.
  if (is.null(p$f_luc_perm)) p$f_luc_perm <- CCX_F_LUC_PERM_DEFAULT
  # WHERE the debit comes from. Unlike f_luc_perm this default IS the old
  # behaviour, because f_luc_wood = 1 is the incumbent decision, not a bug.
  if (is.null(p$f_luc_wood)) p$f_luc_wood <- CCX_F_LUC_WOOD_DEFAULT
  if (is.null(p$w_up)) p$w_up <- 0
  if (is.null(p$w_out_NH)) p$w_out_NH <- 0
  if (is.null(p$w_out_SH)) p$w_out_SH <- 0
  # The conveyor, added 2026-08-13, same reasoning again. NOTE the structural
  # switches must reach the C++ as INTEGERS -- unpack_par reads them into int.
  if (is.null(p$q_conv)) p$q_conv <- 0
  if (is.null(p$conv_sink)) p$conv_sink <- N_INTERIOR
  if (is.null(p$conv_descent)) p$conv_descent <- 0L
  if (is.null(p$conv_reverse)) p$conv_reverse <- 0L
  p$conv_sink <- as.integer(p$conv_sink)
  p$conv_descent <- as.integer(p$conv_descent)
  p$conv_reverse <- as.integer(p$conv_reverse)
  # The four-pool land REPLACED tau_veg/tau_soil, so an older parameter list
  # reaches here with the wrong names entirely. That is a structural mismatch,
  # not a missing default -- fail loudly rather than silently substituting a
  # land the caller did not ask for.
  need <- c("npp_leaf_frac", "tau_leaf", "tau_wood",
            "litter_slow_frac", "tau_soil_fast", "tau_soil_slow")
  miss <- need[!need %in% names(p)]
  if (length(miss)) {
    extra <- if (any(c("tau_veg", "tau_soil") %in% names(p)))
      " (it carries tau_veg/tau_soil: a PRE-4-POOL parameter list)" else ""
    stop("parameter list is missing the land structure: ",
         paste(miss, collapse = ", "), extra)
  }
  p[c("beta", "q10", "k_w", "kz", "w_up", "w_out_NH", "w_out_SH", "tau_ex",
      "q_conv", "conv_sink", "conv_descent", "conv_reverse",
      "npp_leaf_frac", "tau_leaf", "tau_wood",
      "litter_slow_frac", "tau_soil_fast", "tau_soil_slow",
      "npp_veg_frac", "ra_ratio", "f_luc_perm", "f_luc_wood",
      "sst_scale", "gamma_enso", "seas_amp_NH", "seas_amp_SH",
      "seas_phase_NH", "seas_phase_SH", "revelle_frozen")]
}

#' Forcing table -> the matrix the C++ expects, in its column order
# Column ORDER is the contract with src/ccx_core.cpp, which indexes f[] by
# position. Adding, removing or reordering a name here requires the same edit
# there; a mismatch is silent garbage, not an error, so both sides state the
# layout and test-parity.R runs them against each other.
CCX_FORCING_COLS <- c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH",
                      "gmst", "enso", "c14_bomb", "c14_nuclear", "c14_cosmo",
                      "d13c_foss", "cum_luc_NH", "cum_luc_SH")

ccx_cpp_forcing <- function(F) {
  miss <- setdiff(CCX_FORCING_COLS, names(F))
  if (length(miss))
    stop("forcing table is missing column(s): ", paste(miss, collapse = ", "),
         ". Build it with ccx_build_forcing().")
  as.matrix(F[, CCX_FORCING_COLS])
}

#' Run the model using the C++ core. Same signature and return shape as ccx_run().
#'
#' @param substeps RK4 substeps per month, or "auto" (default) for the smallest
#'   count that keeps the explicit diffusion term stable -- see the stability
#'   section of R/model.R. "auto" resolves to 4 at every ordinary parameter
#'   value, so this default does not change any existing result.
#' @param retry_na if the run still produces NAs (the air-sea corner, which the
#'   diffusion criterion deliberately does not cover), double the substep count
#'   and try again, up to CCX_SUBSTEPS_MAX. A NA that survives that is a real
#'   model failure, not an integrator artefact -- which is the whole point: a
#'   caller's `anyNA` -> -Inf guard must not double as a prior bound.
ccx_run_fast <- function(spin, F, substeps = "auto", retry_na = TRUE) {
  ccx_load_cpp()
  ss <- ccx_resolve_substeps(substeps, spin$params, spin$grid)
  one <- function(nsub) {
    res <- .ccx_cpp_env$ccx_run_cpp(
      spin$y, ccx_cpp_par(spin$params), ccx_cpp_forcing(F), F$t,
      ccx_cpp_aux(spin$aux, spin$grid), as.integer(nsub))
    out <- as.data.frame(res$out)
    names(out) <- c("co2_NH", "co2_SH", "d13c_NH", "d13c_SH",
                    "d14c_NH", "d14c_SH", "ocean_C", "land_C",
                    "ocean_C14", "land_C14", "atm_C14")
    state <- res$state
    dimnames(state) <- list(ccx_box_names(spin$grid$nl), CCX_TRACERS)
    list(state = state, out = cbind(t = F$t, out), substeps = as.integer(nsub))
  }
  r <- one(ss)
  while (retry_na && anyNA(r$out) && ss < CCX_SUBSTEPS_MAX) {
    ss <- min(2L * ss, CCX_SUBSTEPS_MAX)
    r  <- one(ss)
  }
  r
}

#' Single derivative via the C++ core (used by the parity gate)
ccx_deriv_fast <- function(y, t, p, forc, grid, aux) {
  ccx_load_cpp()
  cl <- ccx_forcing_cum_luc(forc)
  f <- c(forc$e_foss$NH, forc$e_foss$SH, forc$e_luc$NH, forc$e_luc$SH,
         forc$gmst, forc$enso, forc$c14_bomb, forc$c14_nuclear, forc$c14_cosmo,
         ccx_forcing_d13c_foss(forc), cl$NH, cl$SH)
  d <- .ccx_cpp_env$ccx_deriv_cpp(y, t, ccx_cpp_par(p), f, ccx_cpp_aux(aux, grid))
  dimnames(d) <- dimnames(y)
  d
}
