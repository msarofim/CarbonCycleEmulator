# =====================================================================
# global.R -- app startup. Runs ONCE per R process, before any session.
#
# Deployment target is shinyapps.io, so this has to stay lean: no plotly, no DT,
# no shinyWidgets. shiny + bslib + ggplot2 only. The C++ core is compiled here at
# startup (~20 s cold), which buys a 479x speedup and makes every interaction a
# live model run rather than a lookup into precomputed output.
#
# THE PARAMETER SET IS NOT A DETAIL. Whatever this app draws, it draws with one
# specific parameter vector, and the honest thing is to say which and how far it
# has been tested. app_params() below resolves that once and records where it
# came from; ui.R renders it as a banner that cannot be dismissed.
# =====================================================================

library(shiny)
library(bslib)
library(ggplot2)

APP_ROOT <- normalizePath(file.path(dirname(getwd()), basename(getwd())),
                          mustWork = FALSE)
# The app lives in app/; the model lives one level up. Resolve from the file
# tree rather than from getwd(), which differs between runApp() and shinyapps.io.
.find_root <- function() {
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:6) {
    if (file.exists(file.path(d, "DESIGN.md"))) return(d)
    d <- dirname(d)
  }
  stop("cannot locate the repository root from ", getwd())
}
CCX_ROOT <- .find_root()
for (f in list.files(file.path(CCX_ROOT, "R"), pattern = "\\.R$", full.names = TRUE))
  source(f)

ccx_load_cpp()

# ---------------------------------------------------------------------
# Labels and framing constants. Every title, caption and axis label in the app
# derives from these, so changing a window or a scenario cannot leave a stale
# label behind (standing project rule).
# ---------------------------------------------------------------------
APP_TITLE        <- "The Carbon Cycle, Assembled"
APP_SUBTITLE     <- "A calibrated carbon-cycle model you can take apart"
APP_HIST_YEARS   <- c(1750, 2024)
APP_FUTURE_YEARS <- c(1750, 2100)
APP_PULSE_YEARS  <- c(1750, 2300)
APP_REPO_URL     <- "https://github.com/msarofim/CarbonCycleEmulator"
APP_AUTHOR       <- "Marcus C. Sarofim, NYU Marron Institute"

APP_SSPS <- c(
  "SSP1-1.9  (very low emissions)"  = "ssp119",
  "SSP1-2.6  (low emissions)"       = "ssp126",
  "SSP2-4.5  (middle of the road)"  = "ssp245",
  "SSP3-7.0  (high emissions)"      = "ssp370",
  "SSP5-8.5  (very high emissions)" = "ssp585"
)

# Pulse size. 100 GtC is roughly a decade of current fossil emissions -- large
# enough that the response is visible against the background without a log axis,
# and a round number a student can hold onto.
APP_PULSE_GtC_DEFAULT <- 100
APP_PULSE_YEAR_DEFAULT <- 2050

# ---------------------------------------------------------------------
# Which parameters is this app running on, and how well tested are they?
# ---------------------------------------------------------------------
app_params <- local({
  mode_file <- file.path(CCX_ROOT, "calibration", "output", "mode_fit.rds")
  post_file <- file.path(CCX_ROOT, "calibration", "output", "posterior_draws.rds")
  p <- ccx_default_params()
  p$gamma_enso <- CCX_PARAM_TABLE$gamma_enso$init
  src <- "uncalibrated defaults"
  status <- "provisional"
  detail <- paste("Hand-set starting values, not fitted to anything. The model",
                  "reads about 27 ppm high against the observed CO₂ record.")
  if (file.exists(mode_file)) {
    md <- tryCatch(readRDS(mode_file), error = function(e) NULL)
    if (!is.null(md) && identical(md$param_names, CCX_PARAM_NAMES)) {
      pm <- md$par_mode
      for (n in intersect(names(p), names(pm))) p[[n]] <- pm[[n]]
      p$gamma_enso <- pm$gamma_enso
      src <- "posterior mode"
      status <- "single best fit"
      detail <- paste0("Maximum-a-posteriori fit of ", length(CCX_PARAM_NAMES),
                       " parameters to CO₂, δ¹³C, Δ¹⁴C and",
                       " Global Carbon Budget sinks. A single best fit, not yet a",
                       " posterior — no uncertainty ranges are shown.")
    }
  }
  if (file.exists(post_file)) {
    status <- "calibrated posterior"
    detail <- paste("Bayesian posterior from MCMC. Ribbons show the calibrated",
                    "parameter uncertainty.")
  }
  list(p = p, source = src, status = status, detail = detail,
       has_posterior = file.exists(post_file))
})

APP_PARAMS <- app_params$p

# ---------------------------------------------------------------------
# Startup state. The spinup and the historical run are the same for every
# session and every default view, so they are computed once here.
# ---------------------------------------------------------------------
APP_SPIN <- ccx_spinup(APP_PARAMS)
APP_OBS  <- ccx_prepare_obs()

app_hist <- local({
  F <- ccx_build_forcing("historical", APP_HIST_YEARS, prod_c14 = APP_SPIN$prod_c14)
  r <- ccx_run_fast(APP_SPIN, F)
  r$out$co2_global <- (r$out$co2_NH + r$out$co2_SH) / 2
  r
})
APP_HIST <- app_hist

APP_GCB <- as.data.frame(readRDS(file.path(CCX_ROOT, "data", "gcb_budget.rds"))$budget)
APP_EMIS_HIST <- as.data.frame(
  readRDS(file.path(CCX_ROOT, "data", "forcing_emissions_historical.rds")))
APP_SSP_EMIS <- as.data.frame(
  readRDS(file.path(CCX_ROOT, "data", "ssp_emissions.rds")))
APP_FAIR <- tryCatch(
  as.data.frame(readRDS(file.path(CCX_ROOT, "data", "forcing_climate_ssp.rds"))),
  error = function(e) NULL)

# ---------------------------------------------------------------------
# Run helpers used by more than one tab
# ---------------------------------------------------------------------

#' Run with a set of mechanisms switched off, over the historical period
app_run_mechanisms <- function(off = character(), years = APP_HIST_YEARS,
                               scenario = "historical") {
  F0 <- suppressWarnings(
    ccx_build_forcing(scenario, years, prod_c14 = 0))
  m <- ccx_apply_mechanisms(APP_PARAMS, F0, off)
  sp <- ccx_spinup(m$p)
  F <- m$F; F$c14_cosmo <- sp$prod_c14
  r <- ccx_run_fast(sp, F)
  r$out$co2_global <- (r$out$co2_NH + r$out$co2_SH) / 2
  r$caveats <- m$caveats
  r$spin <- sp
  r
}

#' Build an annual emissions table for a stylised pathway
#'
#' Historical emissions up to the last observed year, then the chosen shape.
#' Land-use emissions follow the background scenario throughout, because the
#' stylised controls describe fossil-fuel policy and pretending they govern
#' deforestation too would overstate what the user is choosing.
app_stylised_emissions <- function(kind, years, to_zero_year = 2060,
                                   rate_pct = 0, background = "ssp245") {
  yrs <- seq(years[1], years[2])
  hist <- APP_EMIS_HIST
  bg <- APP_SSP_EMIS[APP_SSP_EMIS$scenario == background, ]
  luc <- stats::approx(bg$year, bg$luc_GtC, xout = yrs, rule = 2)$y
  last_obs <- max(hist$year)
  foss <- stats::approx(hist$year, hist$fossil_GtC, xout = yrs, rule = 2)$y
  e0 <- hist$fossil_GtC[hist$year == last_obs]
  fut <- yrs > last_obs
  n <- yrs[fut] - last_obs
  foss[fut] <- switch(kind,
    constant = e0,
    to_zero  = pmax(0, e0 * (1 - n / max(1, to_zero_year - last_obs))),
    rate     = e0 * (1 + rate_pct / 100)^n,
    scenario = stats::approx(bg$year, bg$fossil_GtC, xout = yrs[fut], rule = 2)$y
  )
  data.frame(year = yrs, fossil_GtC = foss, luc_GtC = luc)
}

#' Cumulative emissions, GtC, from an assembled forcing table
app_cumulative_emissions <- function(F) {
  e <- (F$e_foss_NH + F$e_foss_SH + F$e_luc_NH + F$e_luc_SH) / 12
  cumsum(e)
}
