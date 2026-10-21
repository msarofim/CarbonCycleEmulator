# =====================================================================
# global.R -- app startup. Runs ONCE per R process, before any session.
#
# Deployment target is shinyapps.io, so this has to stay lean: no plotly, no DT,
# no shinyWidgets. shiny + bslib + ggplot2 only. The C++ core is compiled at
# startup, which buys a 479x speedup and makes every interaction a live model run.
# Since 2026-10-20 it compiles in a BACKGROUND process (ccx_cpp_prebuild(), R/cpp.R)
# and the start-up runs and the pulse lab's default are read from products built at
# the canonical (APP_PRE_* below), so the first page no longer waits for either.
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

# ⭐ THE C++ CORE COMPILES IN THE BACKGROUND (2026-10-20). Nothing at start-up needs it once the
# start-up runs are read from APP_PRE_FILES$startup (below), so its 1.7-1.8 s compile (M4) runs in a
# separate R process while the first page is served; the first live run waits for it, and any
# failure falls back to the in-process compile (R/cpp.R). options(ccx.cpp_prebuild = FALSE) compiles
# on first use instead (the precompute builder and the tests set it).
if (isTRUE(getOption("ccx.cpp_prebuild", TRUE))) ccx_cpp_prebuild()

# ---------------------------------------------------------------------
# Labels and framing constants. Every title, caption and axis label in the app
# derives from these, so changing a window or a scenario cannot leave a stale
# label behind (standing project rule).
# ---------------------------------------------------------------------
# ⚠ RENAMED 2026-09-22, ruling R3 (Marcus: "rename everything" -> scoped to the
# TITLE and the DEPLOYED URL; the repo name and the `ccx_` code prefix stay).
# Was "The Carbon Cycle, Assembled". ⭐ THE URL MOVES WITH IT and that is the
# part that is expensive to undo -- renaming after the post circulates breaks
# every link anyone has shared. Deployed on Posit Connect Cloud (account saraphreport,
# 2026-10-15); the URL is in app/DEPLOY.md. Nothing else in the app types a name: every label derives
# from APP_TITLE.
APP_TITLE        <- "CarboTope"
APP_SUBTITLE     <- "A calibrated carbon-cycle model you can take apart"
# The history's LAST year is the observed carbon budget's (GCB) last year, READ from the
# data and not typed (2026-10-12, pre-beta code review sec.4): APP_SPLICE_YEAR below was
# already read from this file, so a GCB update would have moved the splice and left the
# run, the year sliders and the history panels a year short. The two are asserted equal
# where APP_SPLICE_YEAR is defined. The FIRST year stays 1750: the run must start
# preindustrial (see F5 below).
APP_HIST_YEARS   <- c(1750, max(readRDS(file.path(CCX_ROOT, "data",
                                                  "forcing_emissions_historical.rds"))$year))
# F5 (Marcus 2026-09-22, APPROVED 09-24): Scenarios and Build-your-own show
# 1900-2150. ⭐ THE RUN SPAN AND THE VIEW SPAN ARE DIFFERENT THINGS and the
# distinction is load-bearing: the model must still START IN 1750, because a
# run begun at 1900 inherits 88 GtC of land-use carbon already emitted while
# ccx_spinup() hands it preindustrial stocks, and ccx_build_forcing() warns
# about exactly that ("expect a start-up transient"). So the RUN is
# 1750-2150 and only the PLOT is cropped to APP_FUTURE_VIEW.
# ⚠ Cropping is done by FILTERING the data rather than by coord_cartesian(),
# so the y scale trains on the years the reader can see; a zoom would keep
# training it on 1750 and quietly widen every axis.
APP_FUTURE_YEARS <- c(1750, 2150)
APP_FUTURE_VIEW  <- c(1900, 2150)
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
# ⭐ THE RELEASE NAME (Marcus 2026-10-01, review 10-01c B2: "update the version
# to BETA v1.0 CarboTope"). It read "v1.0-hilda29l" -- a literal that kept
# naming hilda29l after the adoption repointed the app at hilda33d, because no
# test pinned it. The name now carries no mode, so the mode it was cut on is
# recorded separately (APP_RELEASE_MODE) and test-app-version.R requires it to
# equal the mode the app actually loads: adopting a new canonical fails the
# suite until someone decides whether the release name moves too.
APP_VERSION      <- "v1.0"
APP_STAGE        <- "beta"
APP_RELEASE_NAME <- paste(toupper(APP_STAGE), APP_VERSION, APP_TITLE)   # "BETA v1.0 CarboTope"
APP_RELEASE_MODE <- "hilda31w"   # Marcus 2026-10-15: "Beta v1.0 is fine, because this is the first public version"
                                 # (was hilda29e 10-08, hilda33p 10-06, hilda34g 10-03, hilda33d 10-01)
# "frozen at this version" was dropped 2026-10-01: stale since the 09-30
# unfreeze, and a freeze verdict is Marcus's (the B8 assessment record).
# Marcus 2026-10-15 (comments 10.15.26b): "What is under review is how much ..." and "not for citation" deleted.
# APP_STAGE_NOTE retired 2026-10-15: the banner says "BETA" and "not peer-reviewed" on every tab.
# The start-up note (APP_WARMUP_NOTE, "First load compiles the model ... allow up to a minute") was DELETED
# 2026-10-20 (Marcus: "Delete the start-up note"): since CHANGELOG 2026-10-20 (c) the first page no longer
# waits on the compile or the spin-up. Its history is in CHANGELOG (09-22, 10-15, 10-20 c and h).

# ⛔ BOTH URLS ARE PLACEHOLDERS UNTIL SET, AND THE APP SAYS SO ON SCREEN.
# A dead link in a public beta costs exactly the feedback the beta exists to
# collect, and a URL typed once into a tab is the kind of thing that ships
# broken because nothing checks it. app_link_ok() below is that check; ui.R
# renders a visible warning instead of a link when it fails.
# APP_FEEDBACK_URL is the Substack post the review comments live under
# (Marcus 2026-09-22: the feedback channel is the Substack post on the model).
# Set 2026-10-15 to the published post 1 (Marcus sent the link). Its share link carried
# his referral code and utm_* parameters; this is the post's og:url, without them.
APP_FEEDBACK_URL <- "https://thesaraphreport.substack.com/p/the-debut-of-carbotope-beta-a-new"
# Marcus 2026-10-15: the repository goes PUBLIC before the app is deployed (his posting plan, step 1),
# so this is its GitHub address. It 404s for anyone else until that switch is made.
APP_REPO_URL     <- "https://github.com/msarofim/CarbonCycleEmulator"
# Marcus 2026-10-15: his wording ("Substack" capitalized).
APP_FEEDBACK_HOW <- paste("Comments are public on Substack. Be specific about what",
                          "issue your comment addresses (use the issue number if",
                          "appropriate). If your comment leads to a change in the",
                          "model, and you would like to be included in the",
                          "acknowledgments to the model or any future publication,",
                          "please include your full name in the comments.")
# Marcus 2026-10-21: the word in APP_FEEDBACK_HOW that links to the comment box (rv_feedback_how_ui(), app/R/review.R).
APP_FEEDBACK_LINK_WORD <- "Substack"
app_link_ok <- function(u) is.character(u) && length(u) == 1L &&
  nzchar(u) && !identical(u, "SET-BEFORE-DEPLOY")

# THE SCENARIO MENU IS VAN VUUREN (Marcus 2026-09-29): the seven CMIP7
# ScenarioMIP marker pathways (van Vuuren et al. 2026, GMD 19:2627), emissions
# from Zenodo 20713982 v1.1.1 (data-raw/build_vv_scenarios.R). They replaced the
# five CMIP6 SSPs, whose land-use history ran 90 GtC short of the budget the
# model is fitted to. The primary names are the paper's own, so a reader can look
# them up; the parentheses describe each marker's NET CO2 path in the data
# (fossil + land use, 2025-2100) and are drafts for Marcus's review.
APP_SCENARIOS <- c(
  "Very low (net zero by mid-century)"         = "vvVL",
  "Low-to-negative (cuts, then net removal)"   = "vvLN",
  "Low (net zero after mid-century)"           = "vvL",
  "Medium-to-low (net zero around 2100)"       = "vvML",
  "Medium (roughly flat to 2100)"              = "vvM",
  "High-to-low (rises, then deep cuts)"        = "vvHL",
  "High (rising to 2100)"                      = "vvH"
)
APP_SCENARIO_COMPARE <- c("vvL", "vvM", "vvH")   # the Futures tab's opening selection
APP_SCENARIO_BG      <- "vvM"                    # default background: build-your-own + pulse lab
APP_SCENARIO_SRC <- paste(
  "Scenarios are the seven marker pathways of the CMIP7 ScenarioMIP set",
  "(van Vuuren et al. 2026), the ones the next generation of climate models is",
  "running.")

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
APP_LUC_SMOOTH_YR <- 11   # centered years; the land-sink series is noisy enough
                          # that a single year's sign is meaningless

# ⛔ THE PULSE LAB RUNS ON CAUSAL INTERPOLATION, AND THE REST OF THE APP DOES NOT.
# ccx_annual_to_monthly()'s default natural spline is a GLOBAL interpolant, so a
# one-year pulse rings BACKWARDS: a 2050 pulse moved CO2 across the 26 years
# before it ([[ccx_pulse_spline_ringing]]). The pulse lab is the one tab whose
# whole claim is a DIFFERENCE between two runs, so an acausal pre-pulse
# difference is not a rounding artifact there -- it is the tab being wrong about
# what it is showing. "constant" is exactly conserving and shape-preserving.
# ⚠ WHY NOT EVERYWHERE: the default is the frozen forcing path and every stored
# logpost was produced under it (objective #13). Changing it globally is the
# `emissions-interp-constant` branch's ledger, and Marcus chose the app-only fix
# 2026-09-24. BOTH ARMS of the pair must use it or the runs differ by more than
# the pulse.
# ⚠ SUPERSEDED 2026-10-01 (k) (noted 2026-10-12, code review): the heading above is
# no longer true. CCX_EMIS_METHOD_DEFAULT (R/constants.R) was flipped to
# "constant" model-wide that day (Marcus: "apply it now"), so EVERY tab -- the
# objective, ccx_run_coupled() and the futures runs included -- now interpolates
# emissions piecewise-constant. The pulse lab's explicit "constant" below is now
# the same as the default; it is kept so the tab does not depend on the default.
APP_PULSE_EMIS_METHOD <- "constant"
APP_PULSE_GtC_DEFAULT <- 100
APP_PULSE_GTC_RANGE   <- c(10, 500, 10)   # the pulse-size slider: min, max, step (ui.R)
APP_PULSE_YEAR_RANGE  <- c(2030, 2100, 10) # the release-year slider: min, max, step (ui.R); the FaIR grid covers it
APP_PULSE_YEAR_DEFAULT <- 2050
# ⭐ THE PULSE LAB'S INPUTS, by ui.R id, at the values its controls open on (2026-10-20). This list is
# the ONE place the tab's inputs are named: server.R reads exactly these (app_pulse_inputs()), the
# computation sees only them (app_pulse_runs()), and the precomputed default is served only when
# every one of them equals its value here (app_pulse_is_default()). A new control added to the
# computation therefore has to be added here, and the default-match check then covers it.
# test-app-precompute.R checks all three and that ui.R opens on these values.
APP_PULSE_DEFAULTS <- list(p_bg = APP_SCENARIO_BG, p_year = APP_PULSE_YEAR_DEFAULT,
                           p_gtc = APP_PULSE_GtC_DEFAULT)

# F4 (Marcus 2026-09-22): "the temperature/CO2 radio button should be present
# for the Build your own and Pulse lab too." ONE list of choices, named here,
# because the radio is now read by three different plot branches and the
# standing rule is that a label and the thing it labels come from the same
# constant. The VALUES are the `climate` column names plot_future() indexes
# with, which is why they are not prettier: `co2_ppm` and `gmst` have to match
# ccx_run_coupled()'s data frame, and a typo here would draw an empty panel
# rather than error (the failure mode test-future-yvar.R exists to reject).
APP_FUTURE_YVARS <- c("CO₂" = "co2_ppm", "Temperature" = "gmst")
APP_FUTURE_YVAR_DEFAULT <- "co2_ppm"

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
  # ⛔ THE LITERAL FALLBACK IS GONE (2026-10-12, pre-beta code review sec.4): a
  # second entry, `calibration/output/mode_fit.rds`, sat here beside "the ONE
  # place". It has never existed, so it was dead -- and a file that ever
  # appeared at that path would have been loaded with nothing saying which mode
  # it was. The canonical is named in R/paths.R and only there.
  mode_files <- ccx_mode_file(CCX_MODE_CANONICAL)
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
  # RE-WRITTEN 2026-08-14 with the flip to the saturating fertilization form.
  # The old text described β as "set to the 1-D posterior optimum", which is now
  # false twice over: β is not the live fertilization parameter, and the live
  # pair was set by DESIGN gate 12 rather than by any posterior. Same failure the
  # deleted "about 27 ppm high" string had -- a label stating a computed quantity
  # that stopped being computed.
  detail <- paste("Hand-set starting values, not fitted to anything. CO₂",
                  "fertilization is set to the pair that passes the pulse-response",
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
  # the value. Defaults to the no-offset behavior (zero = absent, the
  # likelihood's own absence contract).
  rep_dC <- 0
  # the GATED names the mode fits on top of the table, and the D3 imbalance shares (2026-10-01):
  # none for the defaults; a mode file under a structure that opens the gate sets both (below)
  gated_fit  <- character(0)
  imb_shares <- list()
  # 2026-10-15 review: the other likelihood-only names the mode FITS (the gradient offsets, sigma_d14c) printed
  # "fitted" with value "—"; their fitted values now ride along for the parameter table, like rep_dC
  lik_only   <- list()
  # the parameter table's "Set" column (2026-10-06): the mode file's own FITTED names and HELD
  # pins. NULL for the defaults, where nothing was fitted and the table prints no column.
  fitted_names <- NULL
  held_names   <- NULL
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
    # ONE mapping (2026-10-01): ccx_mode_run_params() (R/paths.R) holds these
    # lines -- base, overlay, ENSO block, pump mode, the two forcing parameters --
    # so the Laplace ribbons' draws go through the same arithmetic as this line.
    rp <- ccx_mode_run_params(md, pm)
    p <- rp$p
    bomb_total <- rp$bomb_total
    luc_scale  <- rp$luc_scale
    rep_dC     <- if (is.null(pm$rep_dC)) 0 else pm$rep_dC
    # the GATED names this mode fits (2026-10-01; R/calibrate.R CCX_PARAM_GATED): the parameter
    # table lists them on top of CCX_PARAM_NAMES. The D3 shares ride along for the same table.
    # (every gate the structure opens since 2026-10-02 -- the land ENSO lag's too)
    gated_fit  <- ccx_gated_names(ccx_mode_struct(md))
    imb_shares <- pm[intersect(c("imb_share_land", "imb_share_ocean_rest"), names(pm))]
    lik_only   <- pm[intersect(c("grad_off_co2", "grad_off_d13c", "sigma_d14c"), names(pm))]
    fitted_names <- md$param_names
    held_names   <- names(ccx_mode_pins(md))
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
    # 2026-10-15 review: "Maximum-a-posteriori fit of" -> "Best fit of" (jargon on a reader-facing panel)
    detail <- paste0("Best fit of ", .n_fit,
                     " parameters to CO₂, δ¹³C, Δ¹⁴C and Global Carbon Budget",
                     " sinks",
                     if (.n_pin) paste0(", with ", .n_pin,
                                        " further values held at stated numbers") else "",
                     # 2026-10-15 (Marcus's band copy): the band shipped (APP_RIBBONS_HOLD
                     # below), so "not yet a posterior -- no uncertainty ranges are shown" went
                     # with the lift; the last sentence is the approved text, unchanged.
                     ". Each line is this single best fit. On the Futures tab,",
                     " the CO\u2082 view also shades the range across runs that",
                     " vary the fitted parameters. The fit constrains the shape",
                     " of these curves more tightly than their absolute height.")
    break
  }
  if (file.exists(post_file)) {
    status <- "calibrated posterior"
    detail <- paste("Bayesian posterior from MCMC. Ribbons show the calibrated",
                    "parameter uncertainty.")
  }
  list(p = p, source = src, status = status, detail = detail,
       bomb_total = bomb_total, luc_scale = luc_scale, rep_dC = rep_dC,
       spinup_label = spinup_label, gated_fit = gated_fit, imb_shares = imb_shares, lik_only = lik_only,
       fitted_names = fitted_names, held_names = held_names,
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
# the gated names the mode fits and the D3 shares, for the parameter table (2026-10-01)
APP_GATED_FIT  <- app_params$gated_fit
APP_IMB_SHARES <- app_params$imb_shares
APP_LIK_ONLY   <- app_params$lik_only   # likelihood-only fitted values, for the parameter table (2026-10-15)
# the parameter table's "Set" column (2026-10-06): NULL when no mode file loaded
APP_FITTED_NAMES <- app_params$fitted_names
APP_HELD_NAMES   <- app_params$held_names
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
  # the STRUCTURE's ENSO index and AOD mode (2026-10-01): the objective's own reads. From hilda33d
  # on, the canonical runs aod_mode "anomaly", and a bare build stops at ccx_run_prepared()'s check.
  if (is.null(args$enso_index))      args$enso_index      <- ccx_enso_index_of(APP_PARAMS)
  if (is.null(args$aod_mode))        args$aod_mode        <- ccx_aod_mode_of(APP_PARAMS)
  if (is.null(args$nuc_share))       args$nuc_share       <- ccx_nuc_share_of(APP_PARAMS)   # 2026-10-12
  do.call(ccx_build_forcing, c(list(scenario, years), args))
}

#' ccx_run_coupled() with THIS APP'S fitted forcing parameters applied
#'
#' Same argument as app_build_forcing(): the futures, stylized and pulse tabs
#' all go through ccx_run_coupled(), which builds its own forcing internally, so
#' without this they would silently run the calibrated PARAMETERS against an
#' UNCALIBRATED forcing -- and disagree with the historical tab drawn two tabs
#' to the left.
#'
#' IT ALSO SPLICES THE PAST (2026-09-22, Marcus's ruling). Every scenario the app
#' runs carries the SSP/LUH2 harmonization over the HISTORICAL period, which is a
#' different land-use inventory from the GCB budget the Keeling tab draws and the
#' model was fitted on -- 91.4 GtC less of it, so the futures tab sat 12.05 ppm
#' below the historical tab at 2024 and the "What if..." tab 13.58 ppm below, with
#' nothing on the page to say why (`calibration/diag_app_cross_tab_step.R`,
#' CHANGELOG 09-22 (x)). Splicing here rather than at each of the four call sites
#' is the same choke-point argument as the forcing parameters above.
app_run_coupled <- function(spin, scenario, years, ...) {
  args <- list(...)
  if (is.null(args$bomb_total_kmol)) args$bomb_total_kmol <- APP_BOMB_TOTAL
  if (is.null(args$luc_scale))       args$luc_scale       <- APP_LUC_SCALE
  args$emissions <- app_splice_history(args$emissions, scenario)
  # the tag's reference run must be spliced IDENTICALLY, or the tag would carry the splice as well
  # as the pulse (R/c14_tag.R tags the emissions DIFFERENCE)
  if (!is.null(args$c14_tag_base)) args$c14_tag_base <- app_splice_history(args$c14_tag_base, scenario)
  do.call(ccx_run_coupled, c(list(spin, scenario, years), args))
}

# ---------------------------------------------------------------------
# Startup state. The spinup and the historical run are the same for every
# session and every default view, so they are computed once here -- or, since
# 2026-10-20, READ from a product built at the canonical (below).
# ---------------------------------------------------------------------

# ---- ⭐ PRECOMPUTED AT THE CANONICAL (2026-10-20; CHANGELOG 2026-10-20 c) ----
# A visitor arriving from a post waited 18-27 s on Connect Cloud's loading page and ~17 s for the
# pulse lab's default release (CHANGELOG 2026-10-20 a). calibration/build_app_precompute.R stores, at
# the canonical, the values of the start-up stages below (the spin-up, the historical run, the flux
# trace) and of the default pulse (app_pulse_lab()), computed by these same functions with the
# product switched off; the app reads them instead of computing them. The Known-issues tab has done
# the same since 2026-10-15 (app/R/review.R RV_PRE_*).
# ⛔ REFUSED, and the app then computes live as before, unless the product was built for this
# canonical's mode file (name and md5) AND at this build's run inputs (app_pre_inputs(), compared
# IDENTICAL: the parameter vector, the two forcing parameters, the spin-up, the years, the pulse
# settings). A code or data change that moves a value at the same inputs is caught by
# tests/testthat/test-app-precompute.R, which recomputes every value live and requires identity:
# rebuild the products at every adoption, and whenever that test fails.
# options(ccx.app_precompute = FALSE) turns the stored values off.
APP_PRE_FILES <- list(startup = c("data", "app_startup_precompute.rds"),
                      pulse   = c("data", "pulse_default_precompute.rds"))
APP_PRE_KEYS  <- list(startup = c("spin", "hist", "flux"), pulse = c("runs", "depth"))

#' The run inputs a product must have been built at, compared identical
app_pre_inputs <- function(product) {
  startup <- list(params = APP_PARAMS, bomb_total = APP_BOMB_TOTAL, luc_scale = APP_LUC_SCALE,
                  spinup_label = APP_SPINUP_LABEL, hist_years = APP_HIST_YEARS)
  switch(product, startup = startup,
         pulse = c(startup, list(pulse_inputs = APP_PULSE_DEFAULTS, pulse_years = APP_PULSE_YEARS,
                                 pulse_emis_method = APP_PULSE_EMIS_METHOD)),
         stop("app_pre_inputs(): no product '", product, "'"))
}

#' Why a precompute product cannot be used (character(0) if it can)
app_pre_problems <- function(x, product, mode_file = ccx_mode_file()) {
  bad <- character(0)
  if (!identical(x$provenance$mode, CCX_MODE_CANONICAL))
    bad <- c(bad, sprintf("it was built for %s, not the canonical %s", format(x$provenance$mode),
                          CCX_MODE_CANONICAL))
  if (!identical(x$provenance$mode_md5, unname(tools::md5sum(mode_file))))
    bad <- c(bad, "its mode file is not the canonical's (md5)")
  missing <- setdiff(APP_PRE_KEYS[[product]], names(x$values))
  if (length(missing)) bad <- c(bad, paste("it lacks", paste(missing, collapse = ", ")))
  want <- app_pre_inputs(product)
  moved <- names(want)[!vapply(names(want), function(n) identical(x$inputs[[n]], want[[n]]), logical(1))]
  if (length(moved)) bad <- c(bad, paste("it was built at other run inputs:", paste(moved, collapse = ", ")))
  bad
}

#' The stored values of one product; NULL (compute live) when absent, refused or switched off
app_pre_read <- function(product, file = do.call(file.path, c(list(CCX_ROOT), as.list(APP_PRE_FILES[[product]])))) {
  if (!isTRUE(getOption("ccx.app_precompute", TRUE))) return(NULL)
  if (!file.exists(file)) {
    message("app: no precomputed ", product, " values in this build; computing them live")
    return(NULL)
  }
  x <- tryCatch(readRDS(file), error = function(e) NULL)
  bad <- if (is.null(x)) "it cannot be read" else app_pre_problems(x, product)
  if (length(bad)) {
    message("app: precomputed ", product, " values refused (", paste(bad, collapse = "; "),
            "); computing them live")
    return(NULL)
  }
  x$values
}

#' The historical run every tab draws (computed at start-up when the product is refused)
app_hist_run <- function(spin) {
  F <- app_build_forcing("historical", APP_HIST_YEARS, prod_c14 = spin$prod_c14)
  r <- ccx_run_fast(spin, F)
  r$out$co2_global <- (r$out$co2_NH + r$out$co2_SH) / 2
  r$forcing <- F              # F1: the driver panel's unswitched line
  r
}

# Annual flux trace for the box diagram and the turnover-time readout -- the only
# place the app learns that photosynthesis is ~70 GtC/yr against ~11 GtC/yr of
# emissions, which is the whole residence-time lesson. ccx_run_fast() has no flux
# tap (the trace is a diagnostic; the C++ core is what the sampler calls), so the
# traced year runs on the pure-R path.
# ⭐ ONLY THE LAST YEAR IS TRACED (2026-10-12 pre-beta code review). Both readers
# take APP_FLUX_NOW, the last row, yet the whole 1750-2024 record ran on the R path
# (~110 s at the canonical, not the "~2 s" this comment said). The trace is now the
# exact RK4-weighted one (flux_method = "rk4", R/fluxes.R), which costs more per
# month, so the C++ core runs to the traced year and the R core continues from its
# state, carrying the ENSO history and T_deep -- the continuation test-enso-lag.R
# SEGMENT proves equal to the unsplit run, and test-flux-trace-exact.R runs.
app_flux_trace <- function(spin) {
  F <- app_build_forcing("historical", APP_HIST_YEARS, prod_c14 = spin$prod_c14)
  k <- which(floor(F$t + 1e-9) == APP_HIST_YEARS[2])[1] - 1L
  F1 <- F[seq_len(k), ]; F2 <- F[(k + 1L):nrow(F), ]
  sp <- spin
  sp$y <- ccx_run_fast(spin, F1)$state
  sp$enso_hist <- ccx_enso_hist_after(F1$enso, spin$enso_hist)
  if (ccx_mix_on(sp$params)) sp$tdeep0 <- ccx_mix_tdeep_after(F1$gmst, F1$t, sp$params, spin$tdeep0)
  ccx_flux_annual(ccx_run(sp, F2, fluxes = TRUE, flux_method = "rk4")$fluxes)
}

APP_STARTUP_PRE <- app_pre_read("startup")
APP_SPIN <- if (is.null(APP_STARTUP_PRE)) app_spinup(APP_PARAMS) else APP_STARTUP_PRE$spin
APP_OBS  <- ccx_prepare_obs()
APP_HIST <- if (is.null(APP_STARTUP_PRE)) app_hist_run(APP_SPIN) else APP_STARTUP_PRE$hist
APP_FLUX <- if (is.null(APP_STARTUP_PRE)) app_flux_trace(APP_SPIN) else APP_STARTUP_PRE$flux
APP_FLUX_NOW <- APP_FLUX[nrow(APP_FLUX), ]

APP_GCB <- as.data.frame(readRDS(file.path(CCX_ROOT, "data", "gcb_budget.rds"))$budget)

# ---- THE OBSERVED GROWTH RATE, ON THE MODEL'S OWN ESTIMATOR (2026-09-26) ----
# \u26d4\u26d4 DELIBERATELY NOT APP_GCB$atm_growth. That is NOAA's published
# `co2_gr_gl`, a JAN-TO-JAN difference of the deseasonalized global series, while
# app_annual_growth() differences ANNUAL MEANS -- two estimators of one quantity,
# differing by sd 0.389 ppm/yr (max 0.950) on NOAA's own products. The panel's own
# caption claimed "annual means differenced" while half its data was not.
# This object is the NOAA MBL global reference put on the model's estimator; see
# data-raw/build_mbl_global_growth.R for the measurement and the rejected
# alternative. \u26a0 It starts 1980, where GCB's atm_growth starts 1959.
APP_OBS_GROWTH <- local({
  f <- file.path(CCX_ROOT, "data", "mbl_global_growth.rds")
  if (!file.exists(f)) return(NULL)      # a checkout without it still renders
  readRDS(f)
})
APP_EMIS_HIST <- as.data.frame(
  readRDS(file.path(CCX_ROOT, "data", "forcing_emissions_historical.rds")))
APP_SCEN_EMIS <- as.data.frame(
  readRDS(file.path(CCX_ROOT, "data", "vv_emissions.rds")))
stopifnot(setequal(unique(APP_SCEN_EMIS$scenario), APP_SCENARIOS))

# ---- THE PULSE LAB'S RUNS (moved here from server.R 2026-10-20, unchanged) ----------------------
# The three runs "Release the pulse" makes. ⛔ `inp` is the ONLY way an input reaches them: this file
# has no `input`, so the computation cannot read a control that APP_PULSE_DEFAULTS does not name.
#' The pulse lab's inputs from a Shiny `input`, by APP_PULSE_DEFAULTS' names; numbers as doubles, so
#' a slider's integer 100 and the default's 100 are the same input
app_pulse_inputs <- function(input) {
  lapply(stats::setNames(nm = names(APP_PULSE_DEFAULTS)), function(n) {
    v <- input[[n]]
    if (is.numeric(v)) as.numeric(v) else v
  })
}

#' The base, pulse and tagged runs for one set of pulse-lab inputs, computed live
app_pulse_runs <- function(inp) {
  yrs <- APP_PULSE_YEARS
  bg <- APP_SCEN_EMIS[APP_SCEN_EMIS$scenario == inp$p_bg, ]
  y <- seq(yrs[1], yrs[2])
  base_em <- data.frame(
    year = y,
    fossil_GtC = stats::approx(bg$year, bg$fossil_GtC, xout = y, rule = 2)$y,
    luc_GtC    = stats::approx(bg$year, bg$luc_GtC,    xout = y, rule = 2)$y)
  pulse_em <- base_em
  # Released over a single year, so the pulse size is exactly what the slider
  # says once the annual-mean-conserving interpolation has run.
  pulse_em$fossil_GtC[pulse_em$year == inp$p_year] <-
    pulse_em$fossil_GtC[pulse_em$year == inp$p_year] + inp$p_gtc
  list(
    # ⚠ BOTH arms carry APP_PULSE_EMIS_METHOD, or the pair would differ by the
    # interpolation as well as by the pulse -- which is the one thing this
    # tab's difference is not allowed to contain.
    # keep_forcing (2026-10-16): the partition panels restart each run from saved states to
    # split the ocean by depth (app/R/ocean_depth.R), so they need the table it integrated
    base  = app_run_coupled(APP_SPIN, inp$p_bg, yrs, inp$p_bg,
                            emissions = base_em,
                            interp_method = APP_PULSE_EMIS_METHOD, keep_forcing = TRUE),
    pulse = app_run_coupled(APP_SPIN, inp$p_bg, yrs, inp$p_bg,
                            emissions = pulse_em,
                            interp_method = APP_PULSE_EMIS_METHOD, keep_forcing = TRUE),
    # Marcus 2026-10-12 ("Side by side in pulse lab"): the SAME pulse run with the pulse's own
    # carbon tagged by 14C (R/c14_tag.R). Passive, so its carbon and climate are the pulse run's;
    # only where the tagged atoms are differs. ~0.6 s.
    tagged = app_run_coupled(APP_SPIN, inp$p_bg, yrs, inp$p_bg,
                             emissions = pulse_em,
                             interp_method = APP_PULSE_EMIS_METHOD,
                             c14_tag_base = base_em, keep_forcing = TRUE),
    gtc = inp$p_gtc, year = inp$p_year, bg = inp$p_bg)
}

#' Whether a set of pulse-lab inputs is EXACTLY the default: the same names as APP_PULSE_DEFAULTS
#' and every value identical. Anything else (another value, a missing or an extra input) is not.
app_pulse_is_default <- function(inp, defaults = APP_PULSE_DEFAULTS) {
  setequal(names(inp), names(defaults)) && length(inp) == length(defaults) &&
    all(vapply(names(defaults), function(n) identical(inp[[n]], defaults[[n]]), logical(1)))
}

APP_PRE_PULSE <- new.env(parent = emptyenv())
#' The precomputed default pulse, read and checked once per process on first use (not at start-up:
#' it is 2 MB and most visitors never open the tab); NULL when absent, refused or switched off
app_pulse_precomputed <- function() {
  if (!isTRUE(getOption("ccx.app_precompute", TRUE))) return(NULL)
  if (!exists("values", envir = APP_PRE_PULSE, inherits = FALSE))
    assign("values", app_pre_read("pulse"), envir = APP_PRE_PULSE)
  get("values", envir = APP_PRE_PULSE, inherits = FALSE)
}

#' The stored default result in the shape app_pulse_runs() returns, plus its ocean-by-depth split as
#' `depth` (which server.R's pulse_depth() takes instead of restarting the runs); NULL without a product
app_pulse_default_result <- function() {
  pre <- app_pulse_precomputed()
  if (is.null(pre)) NULL else c(pre$runs, list(depth = pre$depth))
}

#' What "Release the pulse" shows: the stored default when the inputs are the default and the
#' product is accepted, the live runs otherwise. The stored runs are the live ones bit for bit
#' (test-app-precompute.R).
app_pulse_lab <- function(inp) {
  if (app_pulse_is_default(inp)) {
    r <- app_pulse_default_result()
    if (!is.null(r)) return(r)
  }
  app_pulse_runs(inp)
}

# ---- WHAT THE PULSE LAB SHOWS BEFORE AND BETWEEN CLICKS (Marcus 2026-10-20) -----------------------
# "If we have the pre-calculated default pulse, I would automatically populate the graph rather than
# waiting for a click. And then replace it if the pulse options change." Asked what "replace" means,
# he chose "Grey out, wait for the click". So (server.R): opened at the default inputs, the tab draws
# the stored result with no click; when any pulse input differs from the inputs of the result on
# screen, that result is grayed out (APP_PULSE_RESULT_IDS) with APP_PULSE_STALE_NOTE under the
# button; the click computes as before; set back to the defaults, the stored result is shown again.
# The pulse inputs are APP_PULSE_DEFAULTS' names. The FaIR box and the CO2/temperature radio change
# only the VIEW of the same runs, so they do not gray it.
#' Whether the result on screen was run at other inputs than the controls now hold (FALSE: none shown)
app_pulse_stale <- function(shown_inp, now_inp) !is.null(shown_inp) && !identical(shown_inp, now_inp)
# The outputs that draw the pulse lab's result, grayed together (ui.R's ccx_pulse_stale handler): every
# output that reads pulse_runs() (test-app-precompute.R 11 derives that set from server.R), f_notes for
# its fitted-range caveat on the run.
APP_PULSE_RESULT_IDS <- c("f_takeaway", "f_plot", "f_fair_note", "f_partition", "f_pulse_permanence", "f_notes")
# Marcus 2026-10-20: his wording, verbatim.
APP_PULSE_STALE_NOTE <- "Chart reflects previous settings. Release the pulse to update."

# ---- THE FUTURES RIBBONS (Marcus 2026-10-01, review 10-01c B7: "Laplace first, MCMC as the check") ----
# PRECOMPUTED by calibration/build_futures_ribbons.R and only READ here: the app
# never runs draws. ccx_ribbons_problems() (R/paths.R) is the ONE validity check,
# shared with test-futures-ribbons.R -- bands built at another parameter vector
# are NOT drawn, and the caption says so, rather than shading the wrong
# uncertainty around the right line. ⚠ NOT calibration/output/posterior_draws.rds:
# that path would relabel the whole app "calibrated posterior" (app_params above),
# and a Gaussian at the mode is not one.
APP_RIBBONS_FILE <- file.path(CCX_ROOT, "data", "futures_ribbons.rds")
# ⛔ HELD (Marcus 2026-10-01: "Hold the bands (Recommended)"), and KEPT after the MCMC
# check (Marcus 2026-10-02: "Stop here; keep holding (Recommended)"; CHANGELOG 10-02 s-u).
# - The Laplace band was built and FAILED its own check: scored on the objective, the 1000
#   draws sat a median 25 log-units below the Gaussian (importance ESS 8 / 1000), the
#   posterior strongly non-Gaussian along the fertilization ridge.
# - The MCMC check (calibration/run_mcmc_check.R, Torch stage 1) measured the band at about
#   HALF the Laplace width (CO2 0.41x, GMST 0.58x), but did NOT converge on that ridge
#   (beta_max R-hat 1.21); no stage 2 was run.
# The evidence is outputs/diagnostics/futures_ribbons_laplace_held_20261001.rds and
# futures_ribbons_mcmc_stage1_20261002.rds. While this is set the loader draws NOTHING and
# says nothing, even if a ribbons file appears in data/; test-futures-ribbons.R asserts it.
# ⭐ SHIP RULED (Marcus 2026-10-09: "Ship the 200k band (Recommended)"; CHANGELOG 10-09 e-f), and
# RE-SHIPPED at the canonical hilda31w (Marcus 2026-10-14: "Ship the hilda31w band (Recommended)";
# CHANGELOG 10-14 e-f): the hilda31w MCMC band (4 chains to 200k, 17 000 draws; chains agree to
# <= 4.76 ppm, 21 % of the width, median 11 %) is in data/futures_ribbons.rds
# (calibration/promote_futures_ribbons.R).
# ⭐ LIFTED 2026-10-15 with Marcus's copy (drafted on "Draft all four for me to edit", his one edit
# applied; notes/band_copy_drafts_2026-10-15.md): the band's label (provenance$label, label_ruled),
# card 6 (app/R/review.R), the parameter panel's clause above and APP_RIBBON_NOTE_TEMP below, in ONE
# commit. test-futures-ribbons.R asserts all four are consistent with a lift and pins their numbers.
# To hold again, set a string here: the loader then draws nothing and says nothing.
APP_RIBBONS_HOLD <- NULL
APP_RIBBONS <- local({
  if (!is.null(APP_RIBBONS_HOLD)) return(list(ok = FALSE, held = TRUE, why = APP_RIBBONS_HOLD))
  if (!file.exists(APP_RIBBONS_FILE))
    return(list(ok = FALSE, why = "this build has no ribbons file"))
  r <- readRDS(APP_RIBBONS_FILE)
  md_ok <- file.exists(ccx_mode_file(CCX_MODE_CANONICAL))
  bad <- if (!md_ok) "the canonical mode file is not in this build" else
    ccx_ribbons_problems(r, CCX_MODE_CANONICAL, APP_SCENARIOS, APP_FUTURE_YVARS)
  if (length(bad)) {
    message("app: futures ribbons NOT drawn: ", paste(bad, collapse = "; "))
    return(list(ok = FALSE, why = bad[1]))
  }
  c(list(ok = TRUE), r)
})
# The caption sentence, from the artifact's own record (label, probabilities, draws).
# 2026-10-15 (Marcus's band copy): the frame is "..., <label>." -- the label continues the sentence
# and carries its own second one -- and the count prints with a thousands separator ("17,000").
APP_RIBBON_NOTE <- if (isTRUE(APP_RIBBONS$ok)) with(APP_RIBBONS$provenance, sprintf(
  "Shaded: the %g–%g%% range of %s model runs, %s.",
  100 * probs[1], 100 * probs[length(probs)], formatC(n_ok, format = "d", big.mark = ","), label)) else
  if (isTRUE(APP_RIBBONS$held)) NULL else       # held: silent -- card 6 (the bands card) says why there is no band
  sprintf("No uncertainty band is drawn: %s.", APP_RIBBONS$why)
# ⚠ THE TEMPERATURE BAND IS NOT DRAWN (RULED 2026-10-10, Marcus: "Omit it on
# temperature"). The draws vary the CARBON CYCLE's fitted parameters only; the
# climate module (fitted to FaIR) and the non-CO2 forcing are fixed, so
# temperature moves only through the CO2 it is handed. The shipped band is
# 0.020-0.085 degC wide at 2100-2150 and at most 0.085 anywhere in 1750-2150
# (hilda31w; notes/ship_copy_facts_2026-10-14_hilda31w.md, D), about 3 px at the app's scale: a razor-thin band reads as "the warming is
# known this precisely". So the band is drawn on APP_RIBBON_YVARS only. The
# artifact still carries the GMST bands (ccx_ribbons_problems() checks every
# APP_FUTURE_YVARS); the app just does not draw them.
APP_RIBBON_YVARS <- "co2_ppm"
# The temperature view's sentence in place of the band's label: in words, its
# spread comes only through CO2 and is not shown. Marcus's wording (2026-10-15).
# "less than 0.1 °C" is pinned against the shipped band's widest GMST cell by test-futures-ribbons.R.
APP_RIBBON_NOTE_TEMP <- paste(
  "No uncertainty band is drawn for temperature. The runs vary only the carbon-cycle",
  "parameters, which change the warming by less than 0.1 \u00b0C. How strongly the climate",
  "responds to CO\u2082 is held fixed, so a band would understate the uncertainty in future warming.")
app_ribbon_note <- function(yvar)
  if (isTRUE(APP_RIBBONS$ok) && !yvar %in% APP_RIBBON_YVARS) APP_RIBBON_NOTE_TEMP else APP_RIBBON_NOTE
#' The ribbons for the selected scenarios and y-variable, in plot_future()'s
#' `bands` shape, labeled with the DISPLAY names the runs carry; NULL if none
#' (always NULL off APP_RIBBON_YVARS).
app_future_bands <- function(scen_ids, yvar) {
  if (!isTRUE(APP_RIBBONS$ok) || !length(scen_ids) || !yvar %in% APP_RIBBON_YVARS) return(NULL)
  b <- APP_RIBBONS$bands
  b <- b[b$scenario %in% scen_ids & b$var == yvar, , drop = FALSE]
  if (!nrow(b)) return(NULL)
  data.frame(year = b$year, lo = b$q05, hi = b$q95,
             who = names(APP_SCENARIOS)[match(b$scenario, APP_SCENARIOS)])
}

# ---------------------------------------------------------------------
# FOREST REGROWTH, REPORTED (REGROWTH TIER 1; Marcus 2026-09-24)
# ---------------------------------------------------------------------
# ⭐⭐ The model already CONTAINS forest regrowth, netted invisibly: the
# prescribed land-use series is GCB's NET bookkeeping flux, which the three
# bookkeeping models compute as gross clearing MINUS gross regrowth before the
# model sees a number. This product is that column split back apart
# (data-raw/build_luc_gross_split.R). The two halves sum to the prescribed net
# in every year, so NOTHING the model integrates changes.
#
# ⚠⚠ THE SPLIT IS ASSERTED FROM GCB's BOOKKEEPING MODELS, NOT MEASURED BY THIS
# MODEL, and the panel says so in its own copy. The one thing this record cannot
# do is see the split for itself (CHANGELOG 2026-09-24 h).
#
# ⚠ `luc_scale` is NOT baked into the product -- it is a FITTED name, so both
# halves are multiplied here, together. Scaling one is the mutation the gate
# checks for.
# ---- SECTION HEADINGS THAT ARE CROSS-REFERENCED ---------------------
# ⚠ These are h5() headings in ui.R AND quoted by name in server.R copy that
# sends a reader to them. Two files, one string: exactly the caption-sync bug
# class the project keeps hitting, so the string lives here and neither file
# retypes it. ⛔ test-luc-regrowth-panel.R asserts ui.R uses the constants
# rather than literals.
APP_CMAP_TAB      <- "What pins down what?"
APP_CMAP_HEADING  <- "Which parts of the model have the most influence on measured values?"
APP_CMAP_TENSION_HEADING <- "Where the measurements disagree"
APP_REGROWTH_HEADING  <- "Forest regrowth, on its own"
# The regrowth takeaway's "roughly level" (Marcus 2026-10-02): said only while every decade's mean
# gross deforestation emission is within 15 % of their average -- a WORDING rule, not a physical
# gate, so it is a stated convention; at hilda33d the decades sit within +-5 %. A partial decade
# of fewer than 5 years (GCB's 1959 alone) is not a decade.
REGROWTH_LEVEL_TOL    <- 0.15
REGROWTH_DECADE_MIN_N <- 5L
APP_IMBALANCE_HEADING <- "Is the model's land sink too high?"

# ---- UI helpers shared by ui.R AND server.R -------------------------
# ⚠ These lived in ui.R until 2026-09-24. Both files use them now -- the
# land-use regrowth section is assembled in server.R through uiOutput -- and a
# function defined at the top level of ui.R is not reliably in scope inside the
# server function. global.R is the one file both are guaranteed to see.
takeaway <- function(...) div(class = "takeaway", ...)

# ---- NAMING A SET OF MECHANISM SWITCHES (Marcus 2026-09-25) ---------
# The "What if...?" tab went multi-select, so every sentence and legend key that
# used to interpolate ONE switch's label now has to name between zero and seven.
# ⛔ TWO functions, not one, because the two jobs have opposite constraints:
# a sentence wants every name spelled out, and a LEGEND KEY must stay short --
# "Without: CO2 fertilization (the land sink), El Niño / La Niña and volcanic
# haze (the diffuse-light effect)" is 100+ characters into a legend that
# app_text_px() has to fit, which is the clipping class this app has already
# been bitten by twice ([[subtitles_clip_too]]).
# ⚠ At n = 1 the key is byte-identical to what the tab printed before, so
# the single-switch case is unchanged.

# Marcus 2026-10-11 (CarboTopecomments.10.11.26): "don't capitalize Warming, Volcanic, or Our".
# The labels are written for the checkboxes and the legend, where they start a line; inside a
# sentence each takes its lower-case form unless it begins with a proper noun or a symbol.
MECH_LABEL_KEEP_CASE <- c("El Niño", "CO₂", "Revelle")
app_mech_inline <- function(lb) {
  keep <- vapply(lb, function(x) any(startsWith(x, MECH_LABEL_KEEP_CASE)), logical(1),
                 USE.NAMES = FALSE)
  ifelse(keep, lb, paste0(tolower(substr(lb, 1L, 1L)), substring(lb, 2L)))
}

#' The labels of a set of mechanism switches, as an English list for use INSIDE a
#' sentence; `sentence_start = TRUE` capitalizes its first letter only.
app_mech_list <- function(off, sentence_start = FALSE) {
  if (!length(off)) return("")
  lb <- app_mech_inline(vapply(off, function(n) CCX_MECHANISMS[[n]]$label, character(1),
                               USE.NAMES = FALSE))
  s <- if (length(lb) == 1L) lb else
    paste(paste(utils::head(lb, -1L), collapse = ", "), "and", utils::tail(lb, 1L))
  if (sentence_start) paste0(toupper(substr(s, 1L, 1L)), substring(s, 2L)) else s
}

# The resolution of the "What if...?" takeaway's ppm sentence. ⚠ It is the
# rounding of that sentence's OWN "%.0f", not a tolerance: below this the
# numeric form prints "+0" and has to be replaced by words. Standing rule --
# labels derive from named constants (~/.claude/CLAUDE.md).
TAKEAWAY_PPM_RESOLUTION <- 0.5

#' The legend key for the counterfactual line: short by construction
app_mech_key <- function(off) {
  if (!length(off)) return("Without: nothing")
  if (length(off) == 1L) return(paste("Without:", CCX_MECHANISMS[[off]]$label))
  sprintf("Without %d mechanisms", length(off))
}

info_box <- function(title, ...) {
  tags$details(class = "moreinfo", tags$summary(title), div(...))
}

# ---- THE CONSTRAINT MAP (Marcus 2026-09-25) -------------------------
# Built by calibration/diag_constraint_map.R, which is where every
# methodological choice behind it is argued. Conditional on the file existing so
# a checkout without it still renders, exactly as APP_LUC_SPLIT is.
# ⚠ NOTHING IS RE-DERIVED HERE. The shares, the ordering and the tension pairs
# below are read or summed from the product, so the app cannot disagree with the
# diagnostic that produced it.
# ⛔ AND IT MUST BE THE CANONICAL'S (2026-10-11 b). This read the file with no check, so a map
# built at a retired mode would have been drawn, silently, for as long as test-constraint-map 6
# was not run. Refused exactly as the ribbons are: no map, and the tab says why
# (ccx_cmap_problems(), R/paths.R, shared with test-constraint-map.R).
APP_CMAP_FILE <- file.path(CCX_ROOT, "data", "constraint_map.rds")
APP_CMAP_LOAD <- local({
  if (!file.exists(APP_CMAP_FILE)) return(list(cm = NULL, why = "it is not built in this checkout"))
  cm <- readRDS(APP_CMAP_FILE)
  bad <- if (!file.exists(ccx_mode_file(CCX_MODE_CANONICAL))) "the canonical mode file is not in this build" else
    ccx_cmap_problems(cm, CCX_MODE_CANONICAL)
  if (length(bad)) {
    message("app: constraint map NOT shown: ", paste(bad, collapse = "; "))
    return(list(cm = NULL, why = bad[1]))
  }
  list(cm = cm, why = NULL)
})
APP_CMAP     <- APP_CMAP_LOAD$cm
APP_CMAP_WHY <- APP_CMAP_LOAD$why   # NULL when the map is shown

# The sentence that keeps the map honest, printed on the chart AND asserted by
# test-constraint-map-panel.R.
# 2026-10-15 review: the technical clause ("a step of one conditional Hessian standard deviation, which costs every
# parameter the same 0.5 log-units") moved off the main panel into APP_CMAP_STEP_DETAIL, shown in the sidebar's
# "How this is measured" box (ui.R).
APP_CMAP_NOTE <- paste(
  "Leverage at one parameter set — the fitted mode — for a nudge to each",
  "parameter that costs the fit the same amount. It says which measurements",
  "would notice a change, not what a different model structure would do.")
APP_CMAP_STEP_DETAIL <- paste(
  "Technically, each nudge is one conditional Hessian standard deviation, which",
  "costs every parameter the same 0.5 log-units.")
# ⭐ 2026-10-08 (h) (Marcus: "Main fit only"). At an interannual-CUT canonical (hilda29e) the El Niño settings
# are fitted in a SEPARATE step and held while everything on the map is fitted, so they are not on it -- and nor
# is the measurement that step scores. COMPUTED from the product's `module` record (gated by
# diag_constraint_map.R's GATE MODULE against the likelihood itself), so a canonical without the cut prints
# nothing. A module row with no plain-language text here is an ERROR, never a silent omission.
# ⚠ CLAUDE'S DRAFT, FOR MARCUS'S WORDING.
APP_CMAP_MODULE_ROW_TEXT <- c(gcb_ocean_enso_slope = "how strongly the ocean sink follows El Niño")
app_cmap_module_note <- function(cm = APP_CMAP) {
  m <- cm$module
  if (is.null(m) || !length(m$names)) return(NULL)
  miss <- setdiff(m$rows, names(APP_CMAP_MODULE_ROW_TEXT))
  if (length(miss))
    stop("app_cmap_module_note(): no plain-language text for module row(s) ", paste(miss, collapse = ", "))
  n <- length(m$names)
  nw <- if (n <= 9L) c("one", "two", "three", "four", "five", "six", "seven", "eight", "nine")[n] else
    as.character(n)
  sprintf(paste(" Not on this map: the model's %s El Niño settings. They are fitted in a separate",
                "step, to the month-to-month wobble in CO₂'s growth rate (%d–%d) and to %s, and",
                "are held fixed while everything shown here is fitted."),
          nw, m$growth_window[1], m$growth_window[2],
          paste(APP_CMAP_MODULE_ROW_TEXT[m$rows], collapse = " and "))
}
# Which family each parameter belongs to, as a lookup for the parameter-level view.
APP_CMAP_OF_PAR <- if (is.null(APP_CMAP)) NULL else {
  stats::setNames(rep(names(APP_CMAP$component), lengths(APP_CMAP$component)),
                  unlist(APP_CMAP$component, use.names = FALSE))
}

#' The strongest opposing pair of observation families for each parameter
#'
#' ⭐ THIS IS THE "HOW" THE MAP ON ITS OWN CANNOT SAY. A leverage number says a
#' measurement would notice a parameter move; it does not say WHICH WAY the
#' measurement wants it. Where two families want opposite directions, the fitted
#' value is a compromise between them, and that is a structural statement about
#' the model: one degree of freedom is being asked to satisfy two measurements.
#' ⚠ Uses the product's own signed central slope; nothing is re-simulated.
app_cmap_tensions <- function(cm = APP_CMAP, n = 6L) {
  if (is.null(cm)) return(NULL)
  fam <- cm$family
  # family-level signed slope: sum over the family's streams, which is the
  # derivative of the family's own total log-likelihood
  S <- vapply(fam, function(ss) colSums(cm$SLOPE[ss, , drop = FALSE]), numeric(ncol(cm$SLOPE)))
  out <- do.call(rbind, lapply(rownames(S), function(par) {
    v <- S[par, ]
    hi <- names(which.max(v)); lo <- names(which.min(v))
    # an OPPOSED pair only: both signs must be real, or there is no disagreement
    if (v[[hi]] <= 0 || v[[lo]] >= 0) return(NULL)
    data.frame(par = par, component = APP_CMAP_OF_PAR[[par]],
               up = hi, up_pull = v[[hi]], down = lo, down_pull = v[[lo]],
               opposed = min(v[[hi]], -v[[lo]]), stringsAsFactors = FALSE)
  }))
  if (is.null(out) || !nrow(out)) return(NULL)
  out <- out[order(-out$opposed), , drop = FALSE]
  utils::head(out, n)
}

APP_LUC_SPLIT <- local({
  f <- file.path(CCX_ROOT, "data", "forcing_luc_gross_split.rds")
  if (!file.exists(f)) return(NULL)
  p <- readRDS(f)
  for (nm in c("gross_GtC", "regrowth_GtC", "net_GtC")) {
    p$historical[[nm]] <- p$historical[[nm]] * APP_LUC_SCALE
    p$futures[[nm]]    <- p$futures[[nm]]    * APP_LUC_SCALE
  }
  p$luc_scale_applied <- APP_LUC_SCALE
  p
})
# The window the split is OBSERVED over, read from the product rather than typed
# -- the panel's own caption depends on it and a GCB update must move both.
APP_LUC_SPLIT_OBS <- if (is.null(APP_LUC_SPLIT)) NULL else APP_LUC_SPLIT$obs_window
# 2026-10-02: Marcus deleted the chart's pre-1959 part (carbotopecomment), so the chart now
# shows only the OBSERVED years and the back-extension / decay clause describes nothing on it.
# "Gross clearing" follows his "deforestation".
# 2026-10-02 (carbotopecomments.10.2.26, Marcus): "Change to" -- his wording, verbatim. The
# observed window and the fitted land-use scale left the sentence with it; both are still on the
# chart's own axis and in its legend respectively.
APP_LUC_SPLIT_NOTE <- if (is.null(APP_LUC_SPLIT)) NULL else paste(
  "The split of the land-use input into deforestation and forest regrowth is based on the",   # Marcus 2026-10-15 ("Apply all the app text suggestions"): missing noun
  "Global Carbon Budget\u2019s \u201cforest regrowth (total)\u201d estimate from its three bookkeeping models.")

# ---------------------------------------------------------------------
# ONE PAST FOR EVERY TAB (2026-09-22, Marcus's ruling: splice + caption).
# ---------------------------------------------------------------------
# The observed budget runs out here; a scenario takes over after it. Read from
# the data rather than typed, so a GCB update moves the handover and every label
# below with it.
APP_SPLICE_YEAR <- max(APP_EMIS_HIST$year)
# ONE end year: the run, the sliders and the splice all read the same file (APP_HIST_YEARS above).
stopifnot(APP_HIST_YEARS[2] == APP_SPLICE_YEAR)
# Marcus 2026-10-11 (CarboTopecomments.10.11.26): the second sentence -- the scenarios were
# harmonized a couple of years earlier, so the handover steps total emissions by at most
# APP_SPLICE_STEP (0.5 GtC/yr) -- was DELETED "as extraneous detail", and the step's
# computation with it (it fed nothing else).
APP_SPLICE_NOTE <- sprintf(paste(
  "History is the observed carbon budget (GCB) through %d on every tab; the",
  "scenario takes over from %d."),
  APP_SPLICE_YEAR, APP_SPLICE_YEAR + 1L)

#' Replace a scenario's historical segment with the observed budget
#'
#' Returns an annual emissions table on a MIXED grid on purpose: the GCB years
#' are annual, the scenario's own rows are kept at whatever years it reports
#' (the SSPs are annual to 2015 and decadal after), and ccx_annual_to_monthly()
#' interpolates across the join exactly as it already does between two decadal
#' scenario nodes. So the handover is a ramp to the scenario's next node, not a
#' one-year step -- which matters, because by the handover year the scenarios
#' have diverged from the observed record by as much as 2.5 GtC/yr in either
#' direction (measured at 2024: ssp119 -2.48, ssp585 +1.82 GtC/yr of fossil).
#'
#' @param em an emissions table a caller built (the stylized and pulse tabs), or
#'   NULL for "the scenario's own", which is then read here so that path gets
#'   spliced too.
#' @param scenario the SSP whose future is wanted. "historical" is returned
#'   untouched: it IS the observed budget.
app_splice_history <- function(em, scenario) {
  if (identical(scenario, "historical")) return(em)
  if (is.null(em)) {
    ssp <- APP_SCEN_EMIS[APP_SCEN_EMIS$scenario == scenario, ]
    if (!nrow(ssp)) return(NULL)          # unknown scenario: let ccx_ handle it
    em <- data.frame(year = ssp$year, fossil_GtC = ssp$fossil_GtC,
                     luc_GtC = ssp$luc_GtC)
  }
  h <- APP_EMIS_HIST[APP_EMIS_HIST$year <= APP_SPLICE_YEAR,
                     c("year", "fossil_GtC", "luc_GtC")]
  fut <- em[em$year > APP_SPLICE_YEAR, c("year", "fossil_GtC", "luc_GtC")]
  # A caller-built table already anchored to the observed record over history
  # (app_stylised_emissions takes its fossil from there) still has the SSP's
  # land use, so it is spliced like any other.
  # `d13c_foss` is deliberately NOT carried across. ccx_build_forcing() falls
  # back to the historical file's own column when the supplied table lacks it,
  # which is exactly the series this splice would have passed; carrying it would
  # instead put NAs on the scenario rows, which is worse.
  out <- rbind(h, fut)
  out[order(out$year), ]
}
APP_FAIR <- tryCatch(
  ccx_climate_table(),
  error = function(e) NULL)

# ---------------------------------------------------------------------
# ⭐ FaIR ON THE PULSE LAB'S OWN PULSE (Marcus 2026-10-12, "Keep card 5; FaIR on same pulse
# (Recommended)"): precomputed by FaIRtoFrEDI/scripts/run_fair_vv_pulse_grid_for_ccx.py over the
# seven markers x release years at one size, imported by data-raw/build_fair_pulse_grid.R, and drawn
# ONLY when the pulse the user ran is a grid point. Off the grid there is no FaIR answer, and the note
# says so rather than drawing the nearest one.
# ---------------------------------------------------------------------
APP_FAIR_PULSE_FILE <- "fair_pulse_grid.rds"
APP_FAIR_PULSE_LOAD <- local({
  p <- ccx_path("data", APP_FAIR_PULSE_FILE)
  if (!file.exists(p)) list(d = NULL, why = paste(APP_FAIR_PULSE_FILE, "is not built in this checkout")) else {
    d <- readRDS(p); pv <- attr(d, "provenance")
    bad <- c(if (is.null(pv)) "it carries no provenance",
             if (!all(unique(d$scenario) %in% APP_SCENARIOS)) "its scenarios are not the app's",
             if (!is.null(pv) && !(as.numeric(pv$pulse_gtc) %in% seq(APP_PULSE_GTC_RANGE[1], APP_PULSE_GTC_RANGE[2], APP_PULSE_GTC_RANGE[3])))
               "its pulse size is not one the slider offers")
    if (length(bad)) list(d = NULL, why = paste(bad, collapse = "; ")) else list(d = d, why = NULL)
  }
})
APP_FAIR_PULSE <- APP_FAIR_PULSE_LOAD$d
#' Why FaIR has no answer for the pulse the user ran: NULL when it has one, else the reason
app_fair_pulse_why <- function(bg, year, gtc) {
  if (is.null(APP_FAIR_PULSE)) return(APP_FAIR_PULSE_LOAD$why)
  g <- as.numeric(attr(APP_FAIR_PULSE, "provenance")$pulse_gtc); yrs <- sort(unique(APP_FAIR_PULSE$release_year))
  # The release-year slider IS the grid's years and the menu IS its scenarios (APP_PULSE_YEAR_RANGE), so in
  # the app only the SIZE can be off the grid; the second message is for any other caller.
  if (!isTRUE(all.equal(as.numeric(gtc), g))) return(sprintf(APP_FAIR_PULSE_OFFGRID_FMT[["size"]], g, g))
  if (!(year %in% yrs) || !(bg %in% APP_FAIR_PULSE$scenario))
    return(sprintf(APP_FAIR_PULSE_OFFGRID_FMT[["other"]], g, min(yrs), max(yrs), diff(yrs[1:2])))
  NULL
}
#' FaIR's answer for the pulse the user ran (its rows, labeled), or NULL off the grid
app_fair_pulse <- function(bg, year, gtc) {
  if (!is.null(app_fair_pulse_why(bg, year, gtc))) return(NULL)
  pv <- attr(APP_FAIR_PULSE, "provenance")
  d <- APP_FAIR_PULSE[APP_FAIR_PULSE$scenario == bg & APP_FAIR_PULSE$release_year == year, ]
  attr(d, "label") <- sprintf(APP_FAIR_PULSE_LAB_FMT[["band"]], pv$model, as.integer(pv$n_configs))
  # 2026-10-15 review: the TEMPERATURE view's key -- the grid stores only the mean of d_gmst (no 5-95 %)
  attr(d, "label_mean") <- sprintf(APP_FAIR_PULSE_LAB_FMT[["mean"]], pv$model, as.integer(pv$n_configs))
  d
}
# The pulse's temperature SHAPE (Marcus 2026-10-15): his explanation, with the comparison sentence he chose
# ("Name FaIR, hedge the shape"). MEASURED 2026-10-15 at hilda31w, 100 GtC released 2030: this model peaks +16 yr
# (0.147 K), dips to 0.135 at +90, rises to 0.140 by 2300 (vvM); FaIR peaks +15, dips at +82, rises above its
# early peak by 2300. vvH dips until ~+200 and barely rises; vvL never rises here before 2300 (FaIR does). No
# "multiple models" claim: no literature source was verified, and this model's CO2-to-temperature step is FITTED
# to FaIR, so FaIR is not independent evidence for the temperature half.
APP_PULSE_SHAPE_NOTE <- paste(
  "Temperature peaks in the first couple of decades after the pulse, as the ocean surface",
  "equilibrates with the added heat. Then it declines, because the drop in CO\u2082 concentration",
  "is faster than the decline in ocean heat uptake, until the CO\u2082 concentration decline begins",
  "to flatten out but ocean heat uptake continues to decline, so net warming increases again.",
  "FaIR shows the same shape for the same pulse; whether temperature rises again before 2300,",
  "and by how much, depends on the background scenario.")

# ⚠ DRAFTS for Marcus's wording (2026-10-12)
# 2026-10-15 review: TWO keys from one constant -- `band` for the CO₂ view (mean + 5-95% band), `mean` for the
# temperature view, where the grid has no band (d_gmst_mean only). "5–95%" without the space, as elsewhere.
APP_FAIR_PULSE_LAB_FMT <- c(band = "%s, %d-configuration mean (5\u201395%% shaded)",
                            mean = "%s, %d-configuration mean")
# Marcus 2026-10-15: "FaIR was only run for 100 GtC pulses: set the pulse size to 100 GtC." The size is the grid's.
APP_FAIR_PULSE_OFFGRID_FMT <- c(
  size  = "FaIR was only run for %g GtC pulses: set the pulse size to %g GtC.",
  other = paste("FaIR was only run for %g GtC pulses released in %d-%d, every %d years,",
                "on the scenarios in this menu."))
# The Futures checkbox serves TWO overlays: FaIR's scenario runs (Scenarios) and FaIR's pulse (Pulse lab). Marcus
# 2026-10-15 asked for "Compare with FaIR (100 GtC pulse only)"; that is true of the pulse lab only, so the label
# follows the pill (server.R updates it). The size is the grid's, never typed.
APP_FAIR_CHECK_LAB_SCEN  <- "Compare with standard FaIR"
APP_FAIR_CHECK_LAB_PULSE <- "Compare with FaIR (%g GtC pulse only)"
app_fair_check_label <- function(mode) {
  if (!identical(mode, "Pulse lab") || is.null(APP_FAIR_PULSE)) return(APP_FAIR_CHECK_LAB_SCEN)
  sprintf(APP_FAIR_CHECK_LAB_PULSE, as.numeric(attr(APP_FAIR_PULSE, "provenance")$pulse_gtc))
}
# 2026-10-15 review: the year is the splice's, not typed -- a FORMAT, filled in server.R as
# sprintf(APP_FAIR_PULSE_NOTE, APP_SPLICE_YEAR + 1L) (kept a literal here so the gates can evaluate it alone).
APP_FAIR_PULSE_NOTE <- paste("FaIR is shown for the same pulse on the same scenario. Before %d this",
                             "model follows the observed carbon budget and FaIR its own history, so the",
                             "two release the pulse into slightly different worlds.")

# ---------------------------------------------------------------------
# ⭐ WHEN THE CONSTRAINT MAP'S TOP HOLDER IS A TIE (Marcus 2026-09-27)
# ---------------------------------------------------------------------
# `cm_takeaway` names the component holding the largest share of each of the top
# three rows -- "mostly influenced by X". ⛔ TWO OF THOSE THREE WERE COIN FLIPS:
# measured at three arms (the canonical, the like-for-like `hilda32f`, and the
# `hilda31pe` structure contrast), the winner of δ¹³C level & gradient and of
# Δ¹⁴C bomb CHANGES with the arm (09-26, at hilda29l; at hilda29e neither flipped between its two basins). Computing the sentence makes it MOVE; it does
# not make the winner REAL. An argmax is not a finding until you print the
# runner-up ([[ccx_cmap_second_point]]).
#
# ⭐⭐ THE RULE SINCE 2026-10-14: POSTERIOR WINNER STABILITY (Marcus, verbatim: "Posterior winner stability
# (Recommended)"; CHANGELOG 2026-10-14 c, d). A row's winner is NAMED only if it holds the row in at least
# 1 - APP_CMAP_TIE_LOST_MAX of the MCMC posterior draws; otherwise the row is reported as a tie.
# ⛔ WHY NOT A MARGIN CUT ANY MORE. Every earlier rule cut on the top-two MARGIN at the mode: 09-26's
# geometric mean of flip/stable endpoints between arms (1.60 pp), then 10-12's basin spread
# (hilda29e vs hilda29a6, 1.923 pp). At hilda31w there is no near basin, so the map was re-run at 100
# posterior draws (calibration/diag_cmap_posterior_spread.R). The margin turned out NOT to predict
# whether the winner holds:
#   - Δ¹⁴C in the ocean has a 70.7 pp margin and loses in 6 % of draws;
#   - Δ¹⁴C bomb has a 10.4 pp margin and holds in 98 %.
# The stable and unstable rows' margins overlap, so no cut divides them. The posterior asks the
# question directly. The map's cells are first-order slopes (a step-scaling test, 10-14 c), and they
# move across the posterior.
# ⚠ 5 % is the band's own convention (the 5-95 % range everywhere in the app), not a fitted threshold.
# The shares are DATA (data/constraint_map_stability.rds, calibration/promote_cmap_stability.R), refused
# unless computed against THIS map (ccx_cmap_stab_problems, R/paths.R). A rebuilt map drops the tie
# rule until the stability is re-run: the takeaway is then not shown, and the log says why.
APP_CMAP_TIE_LOST_MAX <- 0.05
APP_CMAP_TIE_SRC <- "share of 100 MCMC posterior draws (hilda31w, 4 chains x 200k) in which the map's winner loses the row; calibration/diag_cmap_posterior_spread.R, 2026-10-14"
APP_CMAP_STAB_FILE <- file.path(CCX_ROOT, "data", "constraint_map_stability.rds")
APP_CMAP_STAB <- local({
  if (is.null(APP_CMAP)) return(NULL)
  if (!file.exists(APP_CMAP_STAB_FILE)) { message("app: constraint-map takeaway NOT shown: no stability file"); return(NULL) }
  st <- readRDS(APP_CMAP_STAB_FILE)
  bad <- ccx_cmap_stab_problems(st, APP_CMAP)
  if (length(bad)) { message("app: constraint-map takeaway NOT shown: ", paste(bad, collapse = "; ")); return(NULL) }
  st
})

#' How to describe who holds one row of the constraint map
#'
#' @param row one row of `MC` (named leverage per component)
#' @param lost_share the share of posterior draws in which this row's winner at the mode loses the row
#' @param lost_max the share above which the top two are reported as a tie rather than a winner
#' @return a phrase; Marcus's wording (2026-09-27) for the tie case
app_cmap_holder_phrase <- function(row, lost_share, lost_max = APP_CMAP_TIE_LOST_MAX) {
  stopifnot(length(lost_share) == 1L, is.finite(lost_share), lost_share >= 0, lost_share <= 1)
  sh <- 100 * row / sum(row)
  o  <- sort(sh, decreasing = TRUE)
  # 2026-10-15 review: "influenced about equally by X (34%) and Y (22%)" was not equal. The review's proposed
  # "though Y leads in some posterior draws" is FALSE for one shipped row: δ¹³C level & gradient's runner-up at the
  # mode (High-latitude structure, 21%) wins 0 of 100 draws -- its 8 lost draws go to Land uptake (5) and Mixed
  # layer (3) (outputs/diagnostics/cmap_posterior_spread_20261014_hilda31w_n100.rds, $winners). So the phrase says
  # only what lost_share measures: the leader does not lead in every draw. Same variables as before.
  if (length(o) >= 2 && lost_share > lost_max)
    return(sprintf("led by %s (%.0f%%, though not in every posterior draw) ahead of %s (%.0f%%)",
                   names(o)[1], o[[1]], names(o)[2], o[[2]]))
  sprintf("mostly influenced by %s (%.0f%%)", names(o)[1], o[[1]])
}

# ---------------------------------------------------------------------
# ⭐ STANDARD FaIR, AS A COMPARISON LINE ON THE FUTURES TAB (Marcus 2026-09-26)
# ---------------------------------------------------------------------
# The emulator's climate module IS FaIR's 841-config ensemble mean, so FaIR is
# what it is trying to reproduce. Drawing it turns "this emulates FaIR" from a
# claim in the provenance caption into something the reader can check.
#
# ⛔ ONLY WHERE FaIR WAS ACTUALLY RUN. `APP_FAIR` covers the seven van Vuuren markers (and the five SSPs, off the menu). It does
# NOT cover a user-built pathway, and there is no honest way to draw one: FaIR
# was never run on it. So the toggle is offered in the SCENARIOS mode and the
# PULSE LAB and withheld from "Build your own" -- a grayed-out control the reader
# can reason about beats a line that silently means something else.
APP_FAIR_LAB  <- "standard FaIR (dashed)"
# Marcus 2026-10-02 (carbotopecomment): his two sentences replace "the gap between a solid line
# and its dashed partner is this emulator's own error", which was wrong for CO2 -- the CO2
# lines come from this model's OWN carbon cycle (app_run_coupled -> ccx_run_coupled; checked
# 2026-10-02: vvH 2150 826.6 ppm here vs FaIR's 832.7), and only the CO2 -> temperature step is
# fitted to FaIR. The like-for-like warning about the historical splice is kept.
# 2026-10-15 review: "Before 2024" was a typed year, and wrong -- the runs follow the observed budget THROUGH the
# splice year (2024). Now a FORMAT, filled in server.R as sprintf(APP_FAIR_NOTE, APP_SPLICE_YEAR) (a literal here
# so test-fair-overlay.R can evaluate it alone). "calibration 1.6.0" -> "calib 1.6.0", the app's other spelling.
APP_FAIR_NOTE <- paste(
  "For CO\u2082, the solid line is this model's output, whereas the dashed lines are",
  "standard FaIR 2.2.4 (calib 1.6.0, 841-configuration ensemble mean). This is",
  "the same for temperature, but this model's CO\u2082/temperature relationship is",
  "fitted to FaIR, so they are not independent. Through %d they are not",
  "like-for-like: this model's runs are spliced onto the observed carbon budget and",
  "FaIR's are not, so a historical gap there reflects a difference in inputs.")

#' FaIR's own trajectories for the scenarios being shown, as plot_future() wants
#'
#' @param scenarios the scenarios to draw, as a slice of `APP_SCENARIOS`: VALUES are the
#'   ids `APP_FAIR` is keyed on ("vvM"), NAMES are the display labels the runs
#'   are keyed on ("SSP2-4.5  (middle of the road)"). An unnamed vector is taken
#'   as ids that are their own labels. Anything absent from `APP_FAIR` is
#'   dropped, so a user-built pathway contributes nothing rather than borrowing
#'   a line.
#' @param yvar "gmst" or "co2_ppm", the app's own names
#' @return data.frame(year, y, who) or NULL
#'
#' ⛔⛔ THE TWO KEYINGS ARE DIFFERENT AND THAT IS WHAT BROKE THIS ONCE (09-26).
#' `future_runs()` names its elements with `names(APP_SCENARIOS)` -- the DISPLAY
#' labels -- while `APP_FAIR$scenario` holds the ids. Passing `names(runs)`
#' straight in matched nothing, returned NULL, and drew no FaIR line at all --
#' which on screen is indistinguishable from "FaIR agrees perfectly". The
#' returned `who` therefore carries the LABEL, because `plot_future()` maps
#' color by `who` and the dashed line must inherit its solid partner's color.
app_fair_overlay <- function(scenarios, yvar) {
  if (is.null(APP_FAIR) || !length(scenarios)) return(NULL)
  ids <- unname(scenarios)
  labs <- if (is.null(names(scenarios))) ids else names(scenarios)
  # ⚠ THE COLUMN NAMES DIFFER BETWEEN THE TWO OBJECTS and the mapping is here,
  # once. `APP_FAIR` carries FaIR's own `gmst_C`; a run carries `gmst`. Reading
  # the wrong one would return NULL and silently draw no FaIR line at all --
  # which looks exactly like "FaIR agrees perfectly".
  col <- switch(yvar, gmst = "gmst_C", co2_ppm = "co2_ppm", NULL)
  if (is.null(col) || !col %in% names(APP_FAIR)) return(NULL)
  keep <- APP_FAIR$scenario %in% ids
  if (!any(keep)) return(NULL)
  d <- APP_FAIR[keep, , drop = FALSE]
  out <- data.frame(year = d$year, y = d[[col]],
                    who = labs[match(d$scenario, ids)],
                    stringsAsFactors = FALSE)
  out[is.finite(out$y), , drop = FALSE]
}

# ---------------------------------------------------------------------
# Run helpers used by more than one tab
# ---------------------------------------------------------------------

#' Run with a set of mechanisms switched off, over the historical period
#' (the ocean switch acts on the run only: ccx_mechanism_spinup(), R/mechanisms.R, 2026-10-11)
app_run_mechanisms <- function(off = character(), years = APP_HIST_YEARS,
                               scenario = "historical") {
  F0 <- suppressWarnings(
    app_build_forcing(scenario, years, prod_c14 = 0))
  ms <- ccx_mechanism_spinup(APP_PARAMS, F0, off, app_spinup)
  m <- ms$m; sp <- ms$spin
  F <- m$F; F$c14_cosmo <- sp$prod_c14
  r <- ccx_run_fast(sp, F)
  r$out$co2_global <- (r$out$co2_NH + r$out$co2_SH) / 2
  r$caveats <- m$caveats
  r$spin <- sp
  # THE FORCING GOES BACK WITH THE RUN (Marcus review F1, 2026-09-24). The
  # driver panel draws the model's INPUT, and reassembling the forcing at the
  # call site would build a SECOND one -- which is how two tabs end up drawing
  # different histories of the same thing (the cross-tab step, CHANGELOG 09-22
  # (x)). Same choke-point argument as app_run_coupled() above.
  r$forcing <- F
  r
}

# ---- TAKEAWAY ARITHMETIC (2026-10-12 pre-beta code review, notes/code_review_2026-10-12.md §2) ----
# Gated in tests/testthat/test-takeaway-arithmetic.R. These compute the NUMBERS the takeaways print;
# the wording around them is Marcus's and is not touched.
#
# ⛔ A YEAR IS ADDRESSED BY ITS MONTHS, NEVER BY ITS DISTANCE TO AN INTEGER. Run times are month
# CENTERS (y + (m - 0.5) / 12), so December of y - 1 and January of y are EXACTLY equidistant from y,
# and `which.min(abs(t - y))` returned the December: the Keeling takeaway printed "in 1957" for 1958,
# and "since 1850" read December 1849.
app_year_mask <- function(t, year) {
  m <- floor(t + 1e-9) == year
  if (!any(m)) stop(sprintf("app_year_mask(): the run has no month in %d", year))
  m
}
#' Annual mean of a monthly run column over one calendar year
app_annual_mean_of <- function(t, v, year) mean(v[app_year_mask(t, year)])

#' The span the Scenarios takeaway reports: the MIN and MAX end values over EVERY ticked run.
#' ⛔ It used the first and last ticked run, but the menu is not ordered by outcome (vvLN ends below
#' vvVL; vvHL below vvM), so all seven ticked printed "366 to 825 ppm" for a true 305-825.
app_scenario_span <- function(rs) {
  end_of <- function(r, v) r$climate[[v]][nrow(r$climate)]
  yrs <- vapply(rs, function(r) max(r$climate$year), numeric(1))
  if (length(unique(yrs)) != 1L) stop("app_scenario_span(): the runs end in different years")
  list(year = yrs[[1]],
       co2  = range(vapply(rs, end_of, numeric(1), v = "co2_ppm")),
       gmst = range(vapply(rs, end_of, numeric(1), v = "gmst")))
}

#' The Keeling takeaway's three numbers, LIKE FOR LIKE (Marcus 2026-10-12: "Keeling 'today'
#' like-for-like"). Every model number is the SCORED line -- the NH box less the representation
#' offset `rep_dC`, which is the chart's solid line -- and every number is a CALENDAR-YEAR MEAN.
#' "Today" is the run's last full year, read from the run, and the measured value is Mauna Loa's mean
#' over that SAME year. It was one December of the raw box (the chart's faint line) against a typed
#' `year >= 2023` window of 39 months running past the run's end, so most of its 3 ppm "gap" was
#' `rep_dC` itself.
app_keeling_numbers <- function(out, obs_mlo, rep_dC, start_year = 1958) {
  off <- if (is.null(rep_dC) || !is.finite(rep_dC)) 0 else rep_dC
  y_now <- max(floor(out$t + 1e-9))
  if (sum(app_year_mask(out$t, y_now)) != 12L)
    stop(sprintf("app_keeling_numbers(): %d is not a full year of the run", y_now))
  m_obs <- obs_mlo$year == y_now
  if (sum(m_obs) != 12L)
    stop(sprintf("app_keeling_numbers(): Mauna Loa has %d months in %d, not 12", sum(m_obs), y_now))
  list(start_year = start_year,
       start      = app_annual_mean_of(out$t, out$co2_NH, start_year) - off,
       now_year   = y_now,
       now        = app_annual_mean_of(out$t, out$co2_NH, y_now) - off,
       obs_now    = mean(obs_mlo$co2_ppm[m_obs]))
}

# The tail clause's "flat" bands, DERIVED FROM THE FORMATS, not picked: the sentence prints the
# temperature change as "%.1f", so below 0.05 degC it would print "0.0" and say nothing -- the same
# rule as TAKEAWAY_PPM_RESOLUTION. Forcing is not printed; 0.05 W/m2 is the same half-unit of the
# first decimal, i.e. "a change the run would report as one at 0.1 W/m2 resolution".
TAIL_DT_FLAT  <- 0.05   # degC
TAIL_ERF_FLAT <- 0.05   # W/m2

#' Build an annual emissions table for a stylized pathway
#'
#' Historical emissions up to the last observed year, then the chosen shape.
#' Land-use emissions follow the background scenario throughout, because the
#' stylized controls describe fossil-fuel policy and pretending they govern
#' deforestation too would overstate what the user is choosing.
app_stylised_emissions <- function(kind, years, to_zero_year = 2060,
                                   rate_pct = 0, background = APP_SCENARIO_BG) {
  yrs <- seq(years[1], years[2])
  hist <- APP_EMIS_HIST
  bg <- APP_SCEN_EMIS[APP_SCEN_EMIS$scenario == background, ]
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

#' The "Build your own" takeaway's second clause, as a PURE function
#'
#' ⛔⛔ WHY THIS IS NOT INLINE IN `server.R`. It was, and it carried a statement
#' that was FALSE ON THE APP'S OWN DEFAULT for a day: "a fixed rate only ever
#' approaches zero", printed for a `rate` pathway whose slider defaults to
#' **+1 %/yr** and therefore GROWS. One string was covering three pathways by
#' disjunction. A sentence buried in a `renderText` cannot be tested, so nothing
#' could have caught it; pulled out here it is gated by
#' `test-stylised-takeaway.R`, which asserts the DEFAULT pathway does not claim
#' emissions approach zero.
#'
#' @param kind one of "constant", "to_zero", "rate" (`s_kind`)
#' @param rate_pct the percent-per-year rate, signed, for `kind = "rate"`
#' @param emissions the pathway `app_stylised_emissions()` actually built
#' @param e0 today's fossil rate, GtC/yr
#' @return a single sentence, or Marcus's verbatim `to_zero` sentence
# ---------------------------------------------------------------------
# ⭐ THE PULSE LAB'S PROPORTIONALITY, MEASURED (2026-09-26)
# ---------------------------------------------------------------------
# The permanence box used to say the proportionality was "stated, not shown:
# demonstrating it would take a second pulse size". It now takes five, and the
# answer is here rather than in the prose so the sentence cannot drift from it.
#
# Measured by `calibration/diag_pulse_vs_tcre.R` at the app's own defaults
# (background APP_SCENARIO_BG = vvM since 2026-09-29, release 2050, the p_gtc
# slider's full range), reading the SAME app_run_coupled() the tab uses. dGMST
# per 1000 GtC at +100 yr, at hilda31w (2026-10-13, pulse_vs_tcre_20261013.csv @6ddf4b2):
#     10 GtC 1.355 | 50 1.353 | 100 1.350 | 200 1.345 | 500 1.327
# (hilda29e, 2026-10-11, pulse_vs_tcre_20261011.csv @4e819ad: 1.359 | 1.356 | 1.353 | 1.347 | 1.327.)
# ⛔ THESE SAT AT hilda33p FOR FIVE DAYS AFTER hilda29e WAS ADOPTED (10-08): the gate read the
# newest CSV and never asked which mode had made it (found 2026-10-11; test-pulse-linearity.R
# now requires the CSV's mode to be CCX_MODE_CANONICAL).
# (hilda33p, 2026-10-06, pulse_vs_tcre_20261006.csv @eec4aa1: 1.364 | 1.361 | 1.358 | 1.351 | 1.330.)
# (hilda34g, 2026-10-03: 1.368 | 1.365 | 1.361 | 1.354 | 1.331.)
# (hilda33d, 2026-10-01: 1.365 | 1.362 | 1.359 | 1.352 | 1.331.)
# (hilda29l, 2026-09-29: 1.041 | 1.037 | 1.032 | 1.023 | 0.998; on the old
# ssp245 background, 2026-09-26: 1.091 | 1.087 | 1.082 | 1.072 | 1.044.)
# ⚠ These are LABELS FOR A MEASUREMENT MADE ELSEWHERE, which is a staleness risk
# by construction. `test-pulse-linearity.R` re-reads the driver's own CSV and
# fails if these drift from it, so the constant cannot rot silently.
APP_PULSE_LIN_SIZES   <- c(10, 500)   # GtC, the range the claim covers
APP_PULSE_LIN_SPREAD  <- 2.1          # percent of the mean, across that range (hilda29e 2.3; hilda33p 2.5; hilda34g 2.7; hilda33d 2.5; hilda29l 4.2)
APP_PULSE_LIN_HORIZON <- 100L         # years after release
APP_PULSE_LIN_SRC     <- "calibration/diag_pulse_vs_tcre.R, 2026-10-13 (vvM background, hilda31w)"
# THE HORIZON DEPENDENCE (100 GtC). At hilda29l the per-1000 figure FELL with
# horizon -- 1.43 at +20 yr, 1.20 at +50, 1.03 at +100, 0.97 at +200 -- and the
# box said "flat in pulse size but NOT in when you look". At hilda33d it is
# nearly FLAT: the slower pulse decay (IRF(100) 0.288 -> 0.360) now balances the
# thermal lag, so it moves only about +-3 % and rises again after +100 yr.
# ⚠ +50 yr is 1.37456 -> 1.37 (review 10-01c's table said 1.38, a double
# rounding).
# hilda34g (2026-10-03): 1.458 / 1.386 / 1.361 / 1.401. ⚠ +20 yr now rounds to 1.5 at one
# decimal, so "about 1.4 ... whether you read it 20, 50, 100 or 200 years after release"
# no longer holds by the test's rounding rule -- the sentence is Marcus's (10-01c A2) and the
# change is his to rule (hilda33d: 1.44 / 1.37 / 1.36 / 1.41).
# hilda33p (2026-10-06, the adoption; outputs/diagnostics/pulse_vs_tcre_20261006.log): 1.448 / 1.379 / 1.358 /
# 1.402 -- every horizon within the ruled 0.1 of "about 1.4", and the headline (1.358) rounds to it.
# hilda29e (2026-10-11, pulse_vs_tcre_20261011.log): 1.438 / 1.370 / 1.353 / 1.401 -- every horizon
# within the ruled 0.1, and the headline (1.353) rounds to 1.4.
# hilda31w (2026-10-13, pulse_vs_tcre_20261013.log): 1.429 / 1.363 / 1.350 / 1.402 -- every horizon
# within the ruled 0.1. ⚠ The headline is 1.35026: it rounds to 1.4 by 0.0003, so a refit that moves
# it down by that much flips the box's one-decimal rule (the test's last assertion).
APP_PULSE_PER1000_BY_HORIZON <- c(`20` = 1.43, `50` = 1.36, `100` = 1.35, `200` = 1.40)
# ⭐ THE BOX'S SENTENCE (Marcus 2026-10-01, review 10-01c A2: "Say about 1.4 dC
# per 1000 GtC"). One figure for every horizon above, to one decimal.
# test-pulse-linearity.R requires every horizon's measurement, and the 100 GtC
# headline at +100 yr, to round to it -- the claim the sentence makes.
APP_PULSE_PER1000_ABOUT <- 1.4
# WHAT "ABOUT" MEANS (Marcus 2026-10-03: "Keep 'about 1.4'; about = within 0.1 (Recommended)"). At
# hilda34g the +20 yr figure is 1.458 -- 1.5 at one decimal -- so the one-decimal rule the test used
# would have changed his sentence; the ruled meaning is every horizon within 0.1 of the figure. The
# 100 GtC +100 yr headline must still ROUND to it (1.361).
APP_PULSE_PER1000_ABOUT_TOL <- 0.1
# (app_or_list(), the horizon sentence's "20, 50, 100 or 200", removed 2026-10-11 with that sentence.)

app_stylised_tail_clause <- function(kind, rate_pct, emissions, e0, climate = NULL) {
  y_end <- max(emissions$year)
  e_end <- emissions$fossil_GtC[emissions$year == y_end]
  # ⭐ "FOSSIL" ADDED 2026-09-26 on Marcus's instruction, to his own sentence.
  # Only FOSSIL emissions reach zero on `to_zero`: `app_stylised_emissions()`
  # always takes land use from the background scenario, so the pathway's total
  # CO2 emissions never reach zero and "emissions stop" overstated what the run
  # did. The slider the user moved is already labeled "Fossil emissions after
  # today", so the sentence now matches the control that produced it.
  #
  # ⭐ 2026-10-02 (Marcus, carbotopecomment + "Say it keeps rising (Recommended)"). His CO2
  # sentence, "fossil" kept per the 09-26 ruling above; it is true across the whole slider
  # (MEASURED 10-02: by 2150 CO2 is back only 13-31 % of the way to 1750's 277 ppm, stop
  # years 2100 .. 2030). His temperature sentence ("Temperatures drop even more slowly because
  # of the inertia of heat uptake in the ocean") was CONTRADICTED by every run: temperature
  # does not drop at all, it keeps RISING to 2150 (2030: 1.46 -> 2.15 degC; 2060: 1.98 -> 2.39;
  # 2100: 2.52 -> 2.71), because total forcing stays ~flat -- CO2's falls 0.3-0.65 W/m2 while
  # the background scenario's non-CO2 rises 0.2-1.1 -- and the ocean is still catching up. So
  # the temperature clause is READ OFF THE RUN (`climate`), branch by measured direction, and
  # the "other emissions" clause is only said when the run's non-CO2 forcing actually rises.
  # Without `climate` (a caller that has no run) only the CO2 sentence is said.
  if (identical(kind, "to_zero")) {
    co2_txt <- paste("Note that even after fossil emissions stop, CO₂ only returns a small",
                     "part of the way to preindustrial concentrations due to the persistence",
                     "of CO₂.")
    y_stop <- suppressWarnings(min(emissions$year[emissions$fossil_GtC <= 0]))
    if (is.null(climate) || !is.finite(y_stop) || !any(climate$year == y_stop)) return(co2_txt)
    at <- function(v, y) v[climate$year == y][1]
    y_last <- max(climate$year)
    dT  <- at(climate$gmst, y_last) - at(climate$gmst, y_stop)
    dnc <- at(climate$erf_nonco2, y_last) - at(climate$erf_nonco2, y_stop)
    t_txt <- if (dT > TAIL_DT_FLAT)
      sprintf(paste("Temperatures, though, keep rising — by %.1f °C between %d and %d",
                    "here — because the ocean is still catching up with heat already",
                    "committed%s"), dT, y_stop, y_last,
              if (dnc > TAIL_ERF_FLAT) paste(", and this scenario's other emissions add",
                                             "warming as CO₂'s pull eases.") else ".")
    else if (dT >= -TAIL_DT_FLAT)
      sprintf(paste("Temperatures, though, hardly change between %d and %d, because the",
                    "ocean is still catching up with heat already committed."), y_stop, y_last)
    else
      sprintf(paste("Temperatures drop even more slowly — by %.1f °C between %d and %d",
                    "— because of the inertia of heat uptake in the ocean."),
              -dT, y_stop, y_last)
    return(paste(co2_txt, t_txt))
  }
  # rate == 0 IS the constant pathway: e0 * 1^n. Sharing the branch keeps the app
  # from describing one pathway two different ways.
  if (identical(kind, "constant") || isTRUE(rate_pct == 0))
    # Marcus 2026-10-02 (carbotopecomment): "none of it comes back down quickly" cut, his
    # last sentence added (British spelling, as the app)
    return(sprintf(paste("Fossil emissions never stop on this pathway \u2014 they hold at",
                         "today's %.1f GtC a year all the way to %d \u2014 so carbon keeps",
                         "being added to what is already up there. Carbon emissions have",
                         # "near zero ... stay stable" (Marcus 2026-10-02, recommended): the app's
                         # own -2 %/yr run has CO2 FALLING by 2150 with fossil emissions still ~0.8
                         # GtC/yr, so "to zero to stabilise" was stronger than the model shows.
                         "to drop to near zero for concentrations to stay stable."), e0, y_end))
  if (rate_pct > 0)
    # Marcus 2026-10-02: "The warming above is what that compounding buys ..." deleted
    return(sprintf(paste("Fossil emissions never stop on this pathway \u2014 at %+.1f%% a",
                         "year they grow, reaching %.1f GtC a year by %d, %.1f times",
                         "today's rate."), rate_pct, e_end, y_end, e_end / e0))
  # Marcus 2026-10-02: "on top of what does not come back down quickly" deleted
  sprintf(paste("Fossil emissions fall on this pathway but never reach zero \u2014",
                "a steady %+.1f%% a year only ever approaches it, and by %d",
                "they are still %.2f GtC a year. So carbon is still being",
                "added at the end of the run."), rate_pct, y_end, e_end)
}

# ---------------------------------------------------------------------
# ⭐ WHEN A PATHWAY LEAVES THE RANGE THE FORCING CURVE WAS FITTED OVER
# ---------------------------------------------------------------------
# ccx_run_coupled() ALREADY warns about this -- to the R console, where no
# reader of the app will ever see it. That was tolerable while the futures ran
# to 2100; F5 takes them to 2150, and fifty more years of compounding takes
# the build-your-own "+5 %/yr" case from 3,516 ppm (2.1x the fitted top) to
# 44,172 ppm and +17.7 degC (26.2x). Measured 2026-09-24, both horizons.
#
# ⚠ The extrapolation is NOT new and F5 did not create it. What F5 changes is
# its SIZE, and 26x is past the point where a silent console warning is an
# honest way to handle it. The app's own stated principle (ui.R, on the
# "Known issues" tab) is that a reader who finds a defect before the app
# admits to it has found a HIDDEN defect.
#
# The note is CONDITIONAL and COMPUTED: it appears only when a run actually
# leaves the range, and every number in it is read from the fitted module and
# the run, so it cannot go stale when either moves.
APP_ERF_RANGE <- ccx_climate_module()$co2_erf_range

#' A caveat for pathways outside the fitted CO2->forcing range, or NULL
#'
#' @param cls a list of `climate` data frames (one per drawn run)
#' @param rng,slack the fitted range and the slack ccx_run_coupled() itself
#'   allows before warning. PARAMETERS, not globals reached from the body, so
#'   the gate can hand this function a range and check both sides of the
#'   threshold without standing the app up.
#' @return a character string, or NULL when every run stays inside the range
app_erf_range_note <- function(cls, rng = APP_ERF_RANGE,
                               slack = CLIM_ERF_RANGE_SLACK) {
  hi <- suppressWarnings(max(vapply(cls, function(cl) max(cl$co2_ppm), numeric(1))))
  lo <- suppressWarnings(min(vapply(cls, function(cl) min(cl$co2_ppm), numeric(1))))
  top <- rng[2]; bot <- rng[1]
  fmt <- function(x) format(round(x), big.mark = ",")
  # 2026-10-15 review: "%.0f times" printed "1 times" just past the top (+2 %/yr); one decimal below 10x, whole
  # numbers above it (where a decimal is false precision on an extrapolation).
  ratio <- function(r) sprintf(if (r < 10) "%.1f" else "%.0f", r)
  above <- if (is.finite(hi) && hi > top + slack)
    sprintf(paste("This pathway reaches %s ppm. The curve turning CO₂ into warming",
                  "was fitted between %s and %s ppm, so past that the temperature",
                  "shown is an extrapolation — here it runs to %s times the",
                  "highest concentration the curve has ever seen. Read it as",
                  "“very large” rather than as a number."),
            fmt(hi), fmt(bot), fmt(top), ratio(hi / top))
  # 2026-10-15 review: the BOTTOM of the range too, mirroring ccx_run_coupled()'s console warning (which fires on
  # either side at the same slack) -- a pathway drawn down below the fitted range was warned about only there.
  below <- if (is.finite(lo) && lo < bot - slack)
    sprintf(paste("This pathway falls to %s ppm. The curve turning CO₂ into warming",
                  "was fitted between %s and %s ppm, so below that the temperature",
                  "shown is an extrapolation. Read it as approximate."),
            fmt(lo), fmt(bot), fmt(top))
  if (is.null(above) && is.null(below)) return(NULL)
  paste(c(above, below), collapse = " ")
}

#' Cumulative emissions, GtC, from an assembled forcing table
app_cumulative_emissions <- function(F) {
  e <- (F$e_foss_NH + F$e_foss_SH + F$e_luc_NH + F$e_luc_SH) / 12
  cumsum(e)
}
