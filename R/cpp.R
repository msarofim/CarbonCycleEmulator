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
    ml_mass_kg = c(aux$ml_mass_kg$NH, aux$ml_mass_kg$SH),
    asx = c(aux$asx$NH, aux$asx$SH),
    sst = c(aux$sst$NH, aux$sst$SH),
    dz = grid$dz, dz_mid = aux$dz_mid,
    enso_share = c(aux$enso_share$NH, aux$enso_share$SH),
    alpha_photo = aux$alpha_photo,
    alpha_as_down = aux$alpha_as_down, alpha_as_up = aux$alpha_as_up,
    d13c_foss = aux$d13c_foss, d13c_bio = aux$d13c_bio,
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
  p[c("beta", "q10", "tau_veg", "tau_soil", "k_w", "kz", "tau_ex",
      "sst_scale", "gamma_enso", "seas_amp_NH", "seas_amp_SH",
      "seas_phase_NH", "seas_phase_SH")]
}

#' Forcing table -> the 9-column matrix the C++ expects, in its column order
ccx_cpp_forcing <- function(F) {
  as.matrix(F[, c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH",
                  "gmst", "enso", "c14_bomb", "c14_nuclear", "c14_cosmo")])
}

#' Run the model using the C++ core. Same signature and return shape as ccx_run().
ccx_run_fast <- function(spin, F, substeps = 4L) {
  ccx_load_cpp()
  res <- .ccx_cpp_env$ccx_run_cpp(
    spin$y, ccx_cpp_par(spin$params), ccx_cpp_forcing(F), F$t,
    ccx_cpp_aux(spin$aux, spin$grid), as.integer(substeps))
  out <- as.data.frame(res$out)
  names(out) <- c("co2_NH", "co2_SH", "d13c_NH", "d13c_SH",
                  "d14c_NH", "d14c_SH", "ocean_C", "land_C")
  out <- cbind(t = F$t, out)
  state <- res$state
  dimnames(state) <- list(ccx_box_names(spin$grid$nl), CCX_TRACERS)
  list(state = state, out = out)
}

#' Single derivative via the C++ core (used by the parity gate)
ccx_deriv_fast <- function(y, t, p, forc, grid, aux) {
  ccx_load_cpp()
  f <- c(forc$e_foss$NH, forc$e_foss$SH, forc$e_luc$NH, forc$e_luc$SH,
         forc$gmst, forc$enso, forc$c14_bomb, forc$c14_nuclear, forc$c14_cosmo)
  d <- .ccx_cpp_env$ccx_deriv_cpp(y, t, ccx_cpp_par(p), f, ccx_cpp_aux(aux, grid))
  dimnames(d) <- dimnames(y)
  d
}
