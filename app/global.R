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
# ⚠ RENAMED 2026-09-22, ruling R3 (Marcus: "rename everything" -> scoped to the
# TITLE and the DEPLOYED URL; the repo name and the `ccx_` code prefix stay).
# Was "The Carbon Cycle, Assembled". ⭐ THE URL MOVES WITH IT and that is the
# part that is expensive to undo -- renaming after the post circulates breaks
# every link anyone has shared. Deploy target: carbotope.shinyapps.io/carbotope
# (app/DEPLOY.md). Nothing else in the app types a name: every label derives
# from APP_TITLE.
APP_TITLE        <- "CarboTope"
APP_SUBTITLE     <- "A calibrated carbon-cycle model you can take apart"
APP_HIST_YEARS   <- c(1750, 2024)
APP_FUTURE_YEARS <- c(1750, 2100)
APP_PULSE_YEARS  <- c(1750, 2300)
# ⚠ NO INSTITUTIONAL AFFILIATION HERE, AND IT IS A RULING, NOT AN OVERSIGHT
# (Marcus 2026-09-22, review U3 / ruling R4): "Marron Institute is for
# professional output (posters, talks, papers), but not for Substack output,
# comments on rules, or other less official output." This app is Substack-facing.
APP_AUTHOR       <- "Marcus C. Sarofim"

# ---- THE BETA AND ITS REVIEW (2026-09-22) ---------------------------------
# The model is frozen and tagged; what is under review is whether its remaining
# flaws are deal-breakers, fixable or acceptable for a pedagogical model. The
# "Known issues" tab asks that question card by card, so these constants are
# what every label, banner and link in that tab derives from (project rule:
# labels derive from named constants, never literals at the point of use).
APP_VERSION      <- "v1.0-hilda29l"
APP_STAGE        <- "beta"
APP_STAGE_NOTE   <- paste("Beta. The model is frozen at this version; what is",
                          "under review is how much its remaining flaws matter.",
                          "Teaching software — not peer-reviewed, not for citation.")
# ⚠ STARTUP IS SLOW AND THE USER MUST BE TOLD BEFORE THEY WAIT. Measured on an
# M4: 73 s idle, 116 s at load ~2.5 (2026-09-22), 2.8 min under load (four Julia
# jobs). DEPLOY.md's older "~20 s" was a warm-cache number. shinyapps.io
# cold-starts a fresh container per idle process, so a visitor arriving from a
# post pays this.
# ⚠ EVERY PROCESS START RECOMPILES THE C++ CORE, and that is most of the wait.
# Rcpp::sourceCpp()'s cacheDir defaults to the R session's own tempdir, so
# nothing is reused across starts -- a container is always a cold start. Once the
# process is listening the first page is essentially instant: 0.4 s from navigate
# to the takeaway text and the first rendered plot (measured 2026-09-22). So the
# note below is about the PROCESS, not the page, and "three minutes" is kept as
# an upper bound that covers the contended case rather than the best one.
APP_WARMUP_NOTE  <- paste("First load compiles the model and runs a 1750 spin-up:",
                          "allow up to three minutes. After that every panel is a",
                          "live model run, not a stored picture.")

# ⛔ BOTH URLS ARE PLACEHOLDERS UNTIL SET, AND THE APP SAYS SO ON SCREEN.
# A dead link in a public beta costs exactly the feedback the beta exists to
# collect, and a URL typed once into a tab is the kind of thing that ships
# broken because nothing checks it. app_link_ok() below is that check; ui.R
# renders a visible warning instead of a link when it fails.
# APP_FEEDBACK_URL is the Substack post the review comments live under
# (Marcus 2026-09-22: the feedback channel is the Substack post on the model).
APP_FEEDBACK_URL <- "SET-BEFORE-DEPLOY"
APP_REPO_URL     <- "SET-BEFORE-DEPLOY"
APP_FEEDBACK_HOW <- paste("Comments are public on the post and I read all of",
                          "them. Please lead your comment with the card number",
                          "so the threads stay separable. Anyone whose comment",
                          "changes the model or the write-up will be credited",
                          "in the acknowledgements for the tool and any potential",
                          "future publication.")
app_link_ok <- function(u) is.character(u) && length(u) == 1L &&
  nzchar(u) && !identical(u, "SET-BEFORE-DEPLOY")

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
# ⚠ W2 (Marcus 2026-09-22): "a note that deforestation added to emissions up to
# [DATE] but was a net sink after that." COMPUTED, not recalled -- and the
# computation says the premise does not hold for this driver. Land-use emissions
# are POSITIVE IN EVERY YEAR 1750-2024 (GCB 2025 bookkeeping + OSCAR before
# 1850); they never turn negative, so there is no such date. What DOES cross is
# the land AS A WHOLE, once growth elsewhere outweighs what clearing releases.
# That crossing is what the note reports, and it is computed at render time from
# the running model and from GCB, on this window.
APP_LUC_SMOOTH_YR <- 11   # centred years; the land-sink series is noisy enough
                          # that a single year's sign is meaningless

APP_PULSE_GtC_DEFAULT <- 100
APP_PULSE_YEAR_DEFAULT <- 2050

# ---------------------------------------------------------------------
# Which parameters is this app running on, and how well tested are they?
# ---------------------------------------------------------------------
app_params <- local({
  # RESOLUTION ORDER, most-preferred first. `mode_fit.rds` has NEVER EXISTED --
  # the adopted mode is the pump-arm file, and until 2026-08-21 this list held
  # only the name that is not on disk, so the app shipped uncalibrated defaults
  # while its banner correctly, and unread, said so. A path that resolves to
  # nothing fails SILENTLY here by design (the banner is the report), which is
  # exactly why the list must be checked against the disk and not against
  # memory. See calibration/diag_app_params.R.
  # REPOINTED 2026-08-27 via ccx_mode_file() (R/paths.R), which is now the ONE
  # place the canonical mode is named. The literal that used to sit here,
  # `pump_arms/mode_fit_pumpN.rds`, was fitted before the 2026-08-25f
  # seasonal-NEP isotope fix changed the objective and is quarantined. Because
  # a path that resolves to nothing fails SILENTLY in this block, a stale
  # literal here does not error -- it ships uncalibrated defaults behind a
  # banner nobody reads, which is exactly what happened until 2026-08-21.
  mode_files <- c(ccx_mode_file(CCX_MODE_CANONICAL),
                  file.path(CCX_ROOT, "calibration", "output", "mode_fit.rds"))
  post_file <- file.path(CCX_ROOT, "calibration", "output", "posterior_draws.rds")
  p <- ccx_default_params()
  # ENSO: FOUR inits since 2026-09-01, read off CCX_PARAM_TABLE rather than
  # written as literals -- this is the app's only source of an uncalibrated
  # ENSO response, and a literal here would go stale the first time the table
  # moved. ccx_set_enso() is not used: there is no source list to read, and the
  # table IS the contract for "nothing has been fitted yet".
  for (.n in CCX_ENSO_PARAMS) p[[.n]] <- CCX_PARAM_TABLE[[.n]]$init
  src <- "uncalibrated defaults"
  status <- "provisional"
  spinup_label <- "aseasonal"   # the defaults' spinup; a mode file overrides it with its own (below)
  # NO HARDCODED BIAS NUMBER. This string used to claim "about 27 ppm high",
  # which by 2026-08-12 was wrong in SIGN as well as magnitude -- it had been
  # written once and never re-derived while the LUC debit and the four-pool land
  # moved the model underneath it. A label that states a computed quantity has to
  # be computed, or it decays into a confident falsehood. The direction and size
  # of the residual is exactly what the app's own CO2 panel shows the user.
  # RE-WRITTEN 2026-08-14 with the flip to the saturating fertilisation form.
  # The old text described β as "set to the 1-D posterior optimum", which is now
  # false twice over: β is not the live fertilisation parameter, and the live
  # pair was set by DESIGN gate 12 rather than by any posterior. Same failure the
  # deleted "about 27 ppm high" string had -- a label stating a computed quantity
  # that stopped being computed.
  detail <- paste("Hand-set starting values, not fitted to anything. CO₂",
                  "fertilisation is set to the pair that passes the pulse-response",
                  "gate (Joos et al. 2013) while matching the historical CO₂",
                  "record, with every other parameter at its starting value — so",
                  "the CO₂ curve is close but not calibrated. Compare it against",
                  "the observations shown alongside it.")
  # THE FORCING PARAMETERS. Six of the 21 fitted parameters have no slot in
  # `ccx_default_params()`, and the `intersect()` below drops all six. Four of
  # them (sigma_d14c, rep_dC, grad_off_co2, grad_off_d13c) are LIKELIHOOD
  # parameters that score the model against observations and cannot move a
  # trajectory, so dropping them is correct. The other two are FORCING
  # parameters that `ccx_make_logpost()` applies by rescaling columns, and
  # dropping them silently would run the fitted parameters against a forcing the
  # fit never saw: worth +5.8 ppm at 2024 on its own. They are carried out of
  # this block and passed to every ccx_build_forcing() call in the app.
  bomb_total <- CCX_PARAM_TABLE$bomb_total$init
  luc_scale  <- 1
  # `rep_dC` IS A THIRD ONE, AND IT IS A DISPLAY PARAMETER AS WELL AS A
  # LIKELIHOOD ONE (2026-09-22). It cannot move a trajectory -- that is why the
  # comment above is right to drop it from `p` -- but it is the offset the
  # likelihood applied when it compared the model BOX to the Mauna Loa STATION,
  # so a panel that draws the raw box against station data is not drawing the
  # comparison the fit was scored on. plot_keeling() now draws both, and needs
  # the value. Defaults to the no-offset behaviour (zero = absent, the
  # likelihood's own absence contract).
  rep_dC <- 0
  for (mode_file in mode_files) {
    if (!file.exists(mode_file)) next
    md <- tryCatch(readRDS(mode_file), error = function(e) NULL)
    # a PINNED canonical (2026-09-13, hilda30c) carries the set MINUS its pins;
    # the held value comes back through ccx_mode_par_with_pins(). Before this
    # line the app would have SKIPPED the canonical and shipped the fallback.
    if (is.null(md) || !ccx_mode_carries_build(md)) {   # tolerates CCX_PARAM_ABSENT_OK (2026-09-13i)
      message("app: skipping mode file ", basename(mode_file), ": it does not carry this build's parameter set")
      next
    }
    pm <- ccx_mode_par_with_pins(md)
    if (length(ccx_mode_absent(md))) pm <- ccx_migrate_par_set(pm)   # 0 = what it RAN (the cell is absent under "hilda")
    # THE FILE'S OWN STRUCTURE (2026-09-08f): the canonical is a HILDA mode.
    p <- ccx_mode_base(md)
    for (n in intersect(names(p), names(pm))) p[[n]] <- pm[[n]]
    p <- ccx_set_enso(p, pm)
    # `pump_mode` is a STRUCTURAL choice, not a fitted parameter, so it is not
    # in par_mode and the loop above cannot carry it. It matches the default
    # today (both "N"); setting it explicitly is what keeps that a fact rather
    # than a coincidence if the default ever moves.
    p$pump_mode <- md$pump_mode
    bomb_total <- pm$bomb_total
    luc_scale  <- pm$luc_scale
    rep_dC     <- if (is.null(pm$rep_dC)) 0 else pm$rep_dC
    # THE FILE'S OWN SPINUP (2026-09-21 h). Every mode since 09-09x is fitted under
    # the PERIODIC spinup (a seasonal mixed layer spun to its own annual cycle);
    # started from the aseasonal equilibrium instead, the canonical hilda29l runs
    # 3-5 ppm HIGH over the whole record (+3.3 at 2024, measured) -- the 09-09t
    # leak's mechanism, which the scorecard fixed on 09-12 and the app had not.
    spinup_label <- ccx_mode_spinup(md)
    src <- "posterior mode"
    status <- "single best fit"
    # WHAT THIS SENTENCE MAY NOT SAY. Not "reproduces the record": the CO2 LEVEL
    # streams are fitted through a free station-vs-box offset (`rep_dC`), so the
    # calibration constrains the SHAPE of the Keeling curve more tightly than its
    # absolute height. See calibration/diag_rep_dC_shape.R.
    # ⚠ RE-MEASURED 2026-09-22: this comment read "+5.2 sd of its own prior" and
    # "the model box runs ~4 ppm above Mauna Loa". Both were STALE, not wrong
    # when written: +5.176 was the value at the arm-N mode ([[ccx_rep_dc_co2_bias]],
    # 08-21). At `hilda29l` the offset is 3.515 ppm and the raw box runs +3.40 ppm
    # above Mauna Loa in the mean (RMS 0.73 ppm once the offset the likelihood
    # applied is taken off).
    # ⚠ NOTE the prior sd is 1.0 ppm (LIK_CO2_REP_ERR), so the offset in ppm and
    # its prior z are NUMERICALLY THE SAME and the two are easy to confuse:
    # 5.176 ppm = 5.18 sd then, 3.515 ppm = 3.52 sd now.
    # No number is typed here any more -- card 1 of the review tab COMPUTES all
    # three, which is the point: a mode-dependent value in a comment goes stale
    # every refit.
    # ⚠ THE COUNT IS THE FILE'S OWN, NOT THE TABLE'S (corrected 2026-09-22).
    # This read `length(CCX_PARAM_NAMES)` = 38, the size of the whole parameter
    # TABLE, and printed "fit of 38 parameters" on the public banner while the
    # canonical fits 29 with 9 held -- contradicting README, the freeze record
    # and card 6 of the review tab, all of which say 29. Same failure as the
    # deleted "about 27 ppm high" string two comments up: a label stating a
    # computed quantity, computed from the wrong thing.
    .n_fit <- length(md$param_names)
    .n_pin <- length(ccx_mode_pins(md))
    detail <- paste0("Maximum-a-posteriori fit of ", .n_fit,
                     " parameters to CO₂, δ¹³C, Δ¹⁴C and Global Carbon Budget",
                     " sinks",
                     if (.n_pin) paste0(", with ", .n_pin,
                                        " further values held at stated numbers") else "",
                     ". A single best fit, not yet a posterior — no",
                     " uncertainty ranges are shown, and the fit constrains the",
                     " shape of these curves more tightly than their absolute",
                     " height.")
    break
  }
  if (file.exists(post_file)) {
    status <- "calibrated posterior"
    detail <- paste("Bayesian posterior from MCMC. Ribbons show the calibrated",
                    "parameter uncertainty.")
  }
  list(p = p, source = src, status = status, detail = detail,
       bomb_total = bomb_total, luc_scale = luc_scale, rep_dC = rep_dC,
       spinup_label = spinup_label,
       has_posterior = file.exists(post_file))
})

APP_PARAMS     <- app_params$p
APP_BOMB_TOTAL <- app_params$bomb_total
APP_LUC_SCALE  <- app_params$luc_scale
# The station-vs-box representation offset the likelihood scored through. ppm.
APP_REP_DC     <- app_params$rep_dC
# ONE spinup for every run the app makes -- the one the parameter set was fitted
# under (periodic for every registered mode; aseasonal only for the defaults).
# The counterfactual reruns below go through the same function, so a switched-off
# mechanism is compared against the same equilibrium the base run started from.
APP_SPINUP_LABEL <- app_params$spinup_label
app_spinup <- ccx_spinup_from_label(APP_SPINUP_LABEL)

#' Build a forcing with THIS APP'S fitted forcing parameters applied
#'
#' Every forcing in the app goes through here. `ccx_build_forcing()` defaults to
#' bomb_total_kmol = 102 and luc_scale = 1, which are the RIGHT defaults for the
#' package and the WRONG ones for a calibrated run -- so a direct call is a
#' silent 5.8 ppm error that nothing would catch. Routing every call through one
#' wrapper is what makes the fitted values structurally impossible to forget.
app_build_forcing <- function(scenario, years, ...) {
  args <- list(...)
  if (is.null(args$bomb_total_kmol)) args$bomb_total_kmol <- APP_BOMB_TOTAL
  if (is.null(args$luc_scale))       args$luc_scale       <- APP_LUC_SCALE
  do.call(ccx_build_forcing, c(list(scenario, years), args))
}

#' ccx_run_coupled() with THIS APP'S fitted forcing parameters applied
#'
#' Same argument as app_build_forcing(): the futures, stylised and pulse tabs
#' all go through ccx_run_coupled(), which builds its own forcing internally, so
#' without this they would silently run the calibrated PARAMETERS against an
#' UNCALIBRATED forcing -- and disagree with the historical tab drawn two tabs
#' to the left.
app_run_coupled <- function(spin, scenario, years, ...) {
  args <- list(...)
  if (is.null(args$bomb_total_kmol)) args$bomb_total_kmol <- APP_BOMB_TOTAL
  if (is.null(args$luc_scale))       args$luc_scale       <- APP_LUC_SCALE
  do.call(ccx_run_coupled, c(list(spin, scenario, years), args))
}

# ---------------------------------------------------------------------
# Startup state. The spinup and the historical run are the same for every
# session and every default view, so they are computed once here.
# ---------------------------------------------------------------------
APP_SPIN <- app_spinup(APP_PARAMS)
APP_OBS  <- ccx_prepare_obs()

app_hist <- local({
  F <- app_build_forcing("historical", APP_HIST_YEARS, prod_c14 = APP_SPIN$prod_c14)
  r <- ccx_run_fast(APP_SPIN, F)
  r$out$co2_global <- (r$out$co2_NH + r$out$co2_SH) / 2
  r
})
APP_HIST <- app_hist

# Annual flux trace for the box diagram and the turnover-time readout. Computed
# once at startup on the pure-R path (ccx_run_fast has no flux tap: the trace is
# a diagnostic and the C++ core is the thing the sampler calls). ~2 s, and it is
# the only place the app learns that photosynthesis is ~70 GtC/yr against ~11
# GtC/yr of emissions -- which is the whole residence-time lesson.
APP_FLUX <- local({
  F <- app_build_forcing("historical", APP_HIST_YEARS, prod_c14 = APP_SPIN$prod_c14)
  ccx_flux_annual(ccx_run(APP_SPIN, F, fluxes = TRUE)$fluxes)
})
APP_FLUX_NOW <- APP_FLUX[nrow(APP_FLUX), ]

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
    app_build_forcing(scenario, years, prod_c14 = 0))
  m <- ccx_apply_mechanisms(APP_PARAMS, F0, off)
  sp <- app_spinup(m$p)
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
