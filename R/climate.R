# =====================================================================
# climate.R -- temperature from the emulator's OWN CO2.
#
# The carbon cycle in model.R needs a GMST path (q10 respiration, SST, and
# through SST the ocean's solubility and Revelle response). Historically that
# path is prescribed observations -- IGCC, per the standing obs conventions.
# For the FUTURE there is nothing to prescribe, and until 2026-08-11 the
# forcing assembler silently extrapolated IGCC's last value flat: an SSP5-8.5
# run to 2100 held the climate at its 2024 temperature. That is not a
# conservative default, it is a wrong one, and it is invisible in the output.
#
# Marcus's call (2026-08-11): use FaIR. Concretely --
#
#   erf_total(t) = erf_co2(CO2 from THIS model) + erf_nonco2(scenario, from FaIR)
#   T(t)         = impulse_response(erf_total)          [fitted to FaIR GMST]
#
# so a user's emissions change CO2, which changes forcing, which changes
# temperature, which feeds back into the carbon cycle. Both pieces are fitted in
# data-raw/build_climate_module.R against FaIR 2.2.4 (calibration 1.4.5), 841
# configs, ensemble mean, GMST relative to 1850-1900.
#
# WHY THE NON-CO2 HALF IS PRESCRIBED. This model has no methane, no N2O, no
# aerosols, no ozone. Those are ~1.1 W/m2 of SSP2-4.5's 4.7 W/m2 at 2100 and
# cannot be derived from anything the emulator computes. They come from FaIR for
# the chosen background scenario and do not respond to the user. The app must
# say so plainly: the user is changing CO2 only.
#
# WHY AN OUTER LOOP AND NOT A COUPLED INTEGRATION. CO2 -> T -> carbon cycle is a
# closed loop, but a weak one, and closing it inside ccx_deriv() would mean
# porting a climate module into ccx_core.cpp and re-establishing the parity gate
# for it. Iterating whole runs instead costs ~0.04 s each and converges in 2-4
# passes (ccx_run_coupled below reports the number). The physics is identical at
# convergence; only the route differs.
# =====================================================================

CLIMATE_MODULE_FILE <- "climate_module.rds"
CLIMATE_SSP_FILE    <- "forcing_climate_ssp.rds"
# The seven van Vuuren ScenarioMIP-CMIP7 markers (2026-09-29; data-raw/build_vv_scenarios.R).
# Same schema; each marker's prescribed non-CO2 ERF only -- the MODULE stays fitted to the SSPs.
CLIMATE_VV_FILE     <- "forcing_climate_vv.rds"
CLIMATE_SCENARIO_FILES <- c(CLIMATE_SSP_FILE, CLIMATE_VV_FILE)

#' Every scenario's FaIR climate record, SSPs and van Vuuren markers together
#'
#' A scenario key must occur in exactly ONE file; a key in both would make the
#' lookup depend on file order, so it is an error rather than a silent pick.
ccx_climate_table <- function() {
  ps <- ccx_path("data", CLIMATE_SCENARIO_FILES)
  ps <- ps[file.exists(ps)]
  if (!length(ps)) return(NULL)
  ds <- lapply(ps, function(p) as.data.frame(readRDS(p)))
  dup <- Reduce(intersect, lapply(ds, function(d) unique(d$scenario)))
  if (length(ds) > 1L && length(dup))
    stop("scenario key(s) in more than one climate file: ", paste(dup, collapse = ", "))
  do.call(rbind, ds)
}
# Convergence of the outer loop, in degrees C of max |change| between passes.
# 1e-4 C is far below anything the carbon cycle resolves and is reached in 2-4
# passes; the cap exists so a pathological parameter set cannot spin forever.
CLIM_TOL      <- 1e-4
CLIM_MAX_ITER <- 12L
# How far outside the fitted CO2->forcing range counts as a real extrapolation
# worth warning about. 5 ppm: the curve's lower end is FaIR's 1750 value and the
# model's own preindustrial sits ~1 ppm below it, which is not extrapolation in
# any meaningful sense.
CLIM_ERF_RANGE_SLACK <- 5

#' Load the fitted climate module (cached per session)
.ccx_clim_env <- new.env(parent = emptyenv())
ccx_climate_module <- function() {
  if (is.null(.ccx_clim_env$mod)) {
    p <- ccx_path("data", CLIMATE_MODULE_FILE)
    if (!file.exists(p))
      stop("climate module missing: ", p,
           "\nRun: Rscript data-raw/build_climate_module.R")
    .ccx_clim_env$mod <- readRDS(p)
  }
  .ccx_clim_env$mod
}

#' CO2 effective radiative forcing, W/m2, relative to the preindustrial state
#'
#' Quadratic in u = ln(CO2/CO2_PI) with no intercept, so it is exactly zero at
#' the preindustrial concentration and monotone over the fitted range. NOT a
#' pure log law -- the quadratic term carries Meinshausen et al. (2020)'s band
#' correction, and dropping it triples the error. Fitted in
#' data-raw/build_climate_module.R; see the note there on why interpolating the
#' pooled pairs was wrong.
#'
#' Outside the fitted range (278-1687 ppm) this extrapolates; ccx_run_coupled()
#' warns rather than failing silently, because the app lets users build
#' scenarios FaIR never saw.
ccx_erf_co2 <- function(co2_ppm, mod = ccx_climate_module()) {
  u <- log(co2_ppm / mod$co2_pi)
  b <- unname(mod$co2_erf_beta)   # qr.solve() names its coefficients; a named
                                  # forcing value propagates into every plot label
  b[1] * u + b[2] * u^2
}

#' Temperature from a forcing path, via the fitted 3-timescale impulse response
#'
#' @param erf   annual effective radiative forcing, W/m2, same length as `years`
#' @param years integer years, contiguous and ascending
#' @param baseline two-element year range to express the anomaly against; the
#'   default matches what the module was fitted to (1850-1900, FaIR's own).
#'   If the run starts after the baseline window there is nothing to subtract,
#'   so the anomaly is returned relative to the first year and flagged.
ccx_temperature_from_erf <- function(erf, years, mod = ccx_climate_module(),
                                     baseline = mod$baseline) {
  q <- mod$irf_q; d <- mod$irf_d
  decay <- exp(-1 / d); gain <- q * (1 - decay)
  S <- numeric(length(q)); T <- numeric(length(erf))
  for (i in seq_along(erf)) {
    S <- S * decay + gain * erf[i]
    T[i] <- sum(S)
  }
  k <- years >= baseline[1] & years <= baseline[2]
  if (any(k)) T - mean(T[k]) else T - T[1]
}

#' Prescribed non-CO2 forcing for a background scenario, on a year grid
#'
#' Returns FaIR's erf_total - erf_co2 for that scenario, interpolated to `years`
#' and held flat outside the FaIR record. ⚠ THE RECORD'S SPAN IS A PROPERTY OF
#' THE BUILD, NOT A CONSTANT: the calib-1.4.5 export ran to 2501, and the
#' calib-1.6.0 one stops at 2301 because that calibration's volcanic/solar
#' forcing ends at 2302 and the standing rule makes 2300 the end year for all
#' our work. The old comment here said "1750-2500" and justified the flat hold
#' by the SSP extensions having gone constant by then -- which is no longer the
#' year being held at. The hold is therefore WARNED about rather than assumed
#' correct, because a silent flat extrapolation of non-CO2 forcing is exactly
#' the kind of thing that reads as a result.
ccx_erf_nonco2 <- function(scenario, years) {
  p <- ccx_path("data", CLIMATE_SSP_FILE)
  if (!file.exists(p))
    stop("SSP climate table missing: ", p,
         "\nRun: Rscript data-raw/build_climate_module.R")
  d <- ccx_climate_table()
  if (identical(scenario, "historical")) {
    # The historical period is shared by every SSP by construction, so any of
    # them serves; ssp245 is used and the choice only matters after 2014.
    d <- d[d$scenario == "ssp245", ]
  } else {
    d <- d[d$scenario == scenario, ]
    if (!nrow(d)) stop("no FaIR climate record for scenario '", scenario, "'")
  }
  hi <- max(d$year)
  if (max(years) > hi)
    warning(sprintf(paste0("non-CO2 forcing is recorded only to %d; %d-%d will be ",
                           "HELD FLAT at its %d value. Rebuild the climate module ",
                           "from an export that covers the window, or shorten it."),
                    hi, hi + 1L, max(years), hi), call. = FALSE)
  stats::approx(d$year, d$erf_nonco2, xout = years, rule = 2)$y
}

#' Scenarios the climate module can supply non-CO2 forcing for
ccx_climate_scenarios <- function() {
  d <- ccx_climate_table()
  if (is.null(d)) return(character(0))
  sort(unique(d$scenario))
}

# ---------------------------------------------------------------------
#' Run the carbon cycle with an interactive temperature
#'
#' Outer-loop iteration: run at the current GMST guess, take the resulting CO2,
#' rebuild the forcing and temperature, repeat until the temperature path stops
#' moving. Returns the same shape as ccx_run_fast() plus the climate diagnostics.
#'
#' @param spin      from ccx_spinup()
#' @param scenario  emissions scenario name, passed to ccx_build_forcing()
#' @param years     c(first, last)
#' @param nonco2_scenario background scenario supplying prescribed non-CO2
#'   forcing. Defaults to `scenario` itself; for a stylised or pulse experiment
#'   the caller picks which SSP's non-CO2 world it happens in, and that choice
#'   is a real assumption the app has to surface, not a default to bury.
#' @param gmst_obs  observed GMST to use where it exists (IGCC, per the standing
#'   obs convention). The computed path is used only where observations run out,
#'   spliced with an offset so the join is continuous. Set NULL to run the
#'   modelled climate over the whole period, which is what the validation test
#'   in test-climate.R does.
#' @param emissions optional data.frame(year, fossil_GtC, luc_GtC) overriding the
#'   scenario's emissions entirely -- the app's stylised pathways and pulses.
#' @param bomb_total_kmol,luc_scale forcing parameters, passed straight through
#'   to ccx_build_forcing(). Added 2026-08-21. BOTH ARE FITTED PARAMETERS
#'   (CCX_PARAM_TABLE), and before this existed a caller running at a calibrated
#'   mode got the fitted values on a forcing it built itself and the package
#'   DEFAULTS on anything routed through here -- so the app's historical tab and
#'   its futures tab would disagree by ~5.8 ppm at 2024 with nothing to say so.
#'   The defaults are ccx_build_forcing()'s own, taken from its formals rather
#'   than retyped, so the two cannot drift apart.
ccx_run_coupled <- function(spin, scenario = "ssp245", years = c(1750, 2100),
                            nonco2_scenario = scenario,
                            gmst_obs = TRUE, emissions = NULL,
                            bomb_total_kmol = eval(formals(ccx_build_forcing)$bomb_total_kmol),
                            luc_scale = eval(formals(ccx_build_forcing)$luc_scale),
                            tol = CLIM_TOL, max_iter = CLIM_MAX_ITER,
                            substeps = "auto",
                            interp_method = CCX_EMIS_METHOD_DEFAULT) {
  interp_method <- match.arg(interp_method, c("spline", "constant"))
  mod  <- ccx_climate_module()
  yrs  <- seq(years[1], years[2])
  erf_nc <- ccx_erf_nonco2(nonco2_scenario, yrs)

  # ccx_build_forcing() warns that it holds GMST flat past the observations.
  # Correct in general, irrelevant here: the gmst column is overwritten below on
  # every pass. Suppressing only that specific warning, so any other one still
  # reaches the caller.
  F <- withCallingHandlers(
    ccx_build_forcing(scenario, years, prod_c14 = spin$prod_c14,
                      emis_method = interp_method,
                      emissions = emissions,
                      bomb_total_kmol = bomb_total_kmol,
                      luc_scale = luc_scale),
    warning = function(w) {
      if (grepl("held FLAT", conditionMessage(w))) invokeRestart("muffleWarning")
    })
  obs_g <- NULL
  if (isTRUE(gmst_obs)) {
    g <- as.data.frame(readRDS(ccx_path("data", "forcing_gmst.rds")))
    obs_g <- g[g$year >= years[1] & g$year <= years[2], ]
  }

  gmst_path <- NULL
  iter <- 0L
  repeat {
    iter <- iter + 1L
    r <- ccx_run_fast(spin, F, substeps = substeps)
    # global mean: each hemisphere holds half the atmosphere
    co2_g  <- (r$out$co2_NH + r$out$co2_SH) / 2
    co2_yr <- tapply(co2_g, floor(r$out$t), mean)
    co2_yr <- as.numeric(co2_yr[match(yrs, as.integer(names(co2_yr)))])
    erf    <- ccx_erf_co2(co2_yr, mod) + erf_nc
    tnew   <- ccx_temperature_from_erf(erf, yrs, mod)

    if (!is.null(obs_g) && nrow(obs_g)) {
      # Splice: observations where they exist, modelled climate after, joined on
      # the last OBS_SPLICE_YEARS of overlap so the seam has no step. Baselining
      # the splice to a single year would import that year's noise as a
      # permanent offset (standing rule: never baseline to one year).
      last <- max(obs_g$year)
      w <- yrs >= (last - 10) & yrs <= last
      off <- mean(obs_g$gmst_anom[obs_g$year >= last - 10]) - mean(tnew[w])
      spliced <- ifelse(yrs <= last,
                        stats::approx(obs_g$year, obs_g$gmst_anom, xout = yrs,
                                      rule = 2)$y,
                        tnew + off)
      tnew <- spliced
    }

    delta <- if (is.null(gmst_path)) Inf else max(abs(tnew - gmst_path))
    gmst_path <- tnew
    # ⛔⛔ THE FEEDBACK PATH RINGS TOO, AND FIXING ONLY THE EMISSIONS LEAVES IT.
    # This is the SECOND global-spline interpolation in a pulse's causality
    # chain: a post-pulse warming rings BACKWARDS into pre-pulse months here,
    # drives q10 respiration and SST solubility, and reappears as a pre-pulse
    # CO2 difference. Measured 2026-09-24: fixing the emissions alone left
    # 3.48e-3 ppm before a 2050 pulse, and it did NOT shrink when the outer
    # loop's tolerance was tightened 100x -- which is what proved it was a real
    # acausal path and not convergence noise.
    # ⚠ THIS IS NOT THE OBJECTIVE'S PATH. ccx_run_coupled() is the futures/pulse
    # route; the objective runs 1750-2024 on observed IGCC GMST through
    # ccx_run_fast() and never calls the climate module (CHANGELOG 09-24 g).
    # So `interp_method` here moves app tabs only -- no stored logpost.
    F$gmst <- ccx_annual_to_monthly(yrs, gmst_path, yrs, method = interp_method)
    # the observed-SST columns must FOLLOW the evolving gmst, or the coupled
    # future silently keeps build-time SST (see ccx_sst_anom_from_gmst)
    F <- ccx_sst_anom_from_gmst(F)
    if (delta < tol || iter >= max_iter) break
  }

  # Warn only on a MATERIAL excursion beyond the fitted CO2 range. The curve's
  # lower end is FaIR's 1750 concentration (278.1 ppm) and any run whose model
  # spinup sits a fraction of a ppm below that would otherwise warn on every
  # call -- a warning that fires always is a warning nobody reads.
  rng <- range(co2_yr, na.rm = TRUE)
  lo <- mod$co2_erf_range[1] - CLIM_ERF_RANGE_SLACK
  hi <- mod$co2_erf_range[2] + CLIM_ERF_RANGE_SLACK
  if (rng[1] < lo || rng[2] > hi)
    warning(sprintf(paste0("CO2 reached %.0f-%.0f ppm, more than %.0f ppm outside ",
                           "the %.0f-%.0f ppm range the CO2->forcing curve was ",
                           "fitted over; forcing is extrapolated there."),
                    rng[1], rng[2], CLIM_ERF_RANGE_SLACK,
                    mod$co2_erf_range[1], mod$co2_erf_range[2]), call. = FALSE)

  c(r, list(climate = data.frame(year = yrs, co2_ppm = co2_yr,
                                 erf_co2 = ccx_erf_co2(co2_yr, mod),
                                 erf_nonco2 = erf_nc, gmst = gmst_path),
            iterations = iter, converged = delta < tol))
}
