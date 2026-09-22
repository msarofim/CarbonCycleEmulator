# =====================================================================
# review.R -- the "Known issues" tab: the model's remaining flaws, measured
# LIVE, with the three-way question the beta exists to ask.
#
# WHY THIS IS COMPUTED AND NOT TYPED. The freeze record and the 09-21 scorecard
# already hold every number on this tab. Typing them here would make eight
# public claims that no longer track the model the moment the canonical moves --
# the caption-sync bug class this project has a standing rule against, and the
# worst possible place for it is a tab whose entire purpose is to be honest
# about the model's defects. So every card's number comes from a run made by
# this app, through the SAME gate kernels the scorecard calls
# (calibration/lib_design_gates.R), and a card whose kernel will not run says so
# in place of its number rather than falling back to a literal.
#
# WHAT IS EXPENSIVE. Cards 3, 4, 5 and 6 each need a model run that the app does
# not already have (a gate run to 2025, a knockout run, a 1000-year pulse pair,
# and the control mode's own spin-up + run). Each is memoised in RV_CACHE and
# computed on FIRST VIEW, not at startup -- startup is already the app's worst
# number (APP_WARMUP_NOTE) and nobody should pay for a tab they never open.
#
# ⚠ THE GATE LIB IS SOURCED LAZILY. It lives in calibration/, not R/, so the
# app does not load it at startup; it also reads data/*.rds of its own. If it is
# absent (a deploy that excluded calibration/), rv_gates_ready() returns FALSE
# and the affected cards render their explanation without their number. That is
# a visible degradation, not a silent one.
# =====================================================================

# ---- named constants: every label on the tab derives from these -----
RV_TAB_TITLE  <- "Known issues"
# N2 (Marcus 2026-09-22): the "measured by the running model" sentence is cut
# from the lead. It is true and it is why this tab cannot go stale, but it is
# inside baseball for a reader. The DESIGN is unchanged -- every number below is
# still computed by a run this app makes.
RV_TAB_LEAD   <- paste("Eight things this model gets wrong, or does not do, or",
                       "does on purpose in a way you might disagree with. For",
                       "each, I want to know the same thing:")
RV_ASK        <- c("Deal-breaker", "Fixable", "Acceptable")
RV_ASK_GLOSS  <- c(
  "Deal-breaker" = "this invalidates the lesson the model is built to teach",
  "Fixable"      = "worth the work, and here is the mechanism I would add",
  "Acceptable"   = "a real limitation, correctly disclosed, fine for a teaching model")
RV_CLASS_GLOSS <- c(
  # U5/N6 (Marcus 2026-09-22): "one ocean column per hemisphere" read as "no
  # ocean circulation", which is false at hilda29l. The limitation that is real
  # is the INTERHEMISPHERIC one: the two oceans never touch.
  structural = paste("a consequence of the model's SHAPE -- each hemisphere has",
                     "its own ocean, and they exchange carbon only through the",
                     "air. Closing it means a different model, not a better fit."),
  accounting = paste("the fit prefers a simpler version; a mechanism was kept",
                     "over the fit, on a judgement that is open to challenge."),
  shim       = paste("a fitted stand-in for a mechanism the model does not",
                     "carry. It is named rather than hidden."),
  # N9 (Marcus 2026-09-22): his wording, which is better than mine.
  comparison = paste("we do not calibrate the model to match future projections,",
                     "so it is not surprising that we might not match perfectly.",
                     "But the long tail of carbon dioxide is robust."),
  gap        = "something the product does not have yet.",
  design     = "a choice made when the model was specified.")

# The horizons and windows the cards read. Named here so a caption cannot drift
# from the number under it.
RV_IRF_HORIZON   <- 1000    # yr followed for the partition (= DG_L_HORIZON)
RV_IRF_READ      <- c(20, 100, 300)
RV_SEAS_WINDOW   <- c(2000, 2024)   # the climatology window for the seasonal panels
RV_GRAD_WINDOW   <- c(2000, 2024)   # where the MLO-SPO gradients are read

# ---------------------------------------------------------------------
# THE STAND-INS (card 8; Marcus 2026-09-22, review N12)
#
# ⚠ THIS IS A DIFFERENT LIST FROM THE PINS, and conflating them is the bug N12
# caught. A PIN is generated -- it is a property of the mode file the app is
# running, and rv_stand_ins() reads it off that file. A STAND-IN is a
# JUDGEMENT: that a fitted name absorbs a discrepancy rather than representing
# a process. Nothing in the parameter table records that judgement, so it is
# written here, with its source, rather than derived.
#
# SOURCE: the whole-model review of 2026-09-16 (d),
# notes/review_2026-09-16c_whole_model.md, which named five stand-ins over
# seven parameter names. It is NOT re-derived here and must not be edited
# without that note being edited too.
#
# THE GATE (rv_validate_shims) is what stops this going stale the way the
# parameter label table did: every name here must still be one the build
# carries. A name that leaves CCX_PARAM_NAMES fails the check rather than
# quietly describing a parameter that no longer exists.
RV_SHIM_SOURCE <- "the whole-model review of 2026-09-16"
RV_SHIMS <- list(
  rep_dC          = "converts the model's hemispheric box to a station reading",
  grad_off_d13c   = "absorbs the north-south \u03b4\u00b9\u00b3C offset the model cannot produce",
  sst_seas_amp_NH = "a seasonal sea-surface temperature the fit chooses instead of the observed one",
  sst_seas_amp_SH = "the same, southern hemisphere",
  ent_seas_amp_SH = "a seasonal entrainment amplitude standing in for a seasonal mixed layer",
  gamma_enso_ocn_NH = "an ENSO ocean coefficient standing in for ocean transport",
  gamma_enso_ocn_SH = "the same, southern hemisphere"
)

#' GATE: does the stand-in list still describe parameters this build carries?
#'
#' A function so tests/testthat/test-review-cards.R can MUTATION-TEST it.
#'
#' @param shims a list in RV_SHIMS' shape
#' @param param_names the build's fitted names, i.e. `CCX_PARAM_NAMES`
#' @return character(0) if valid, else one string per problem
rv_validate_shims <- function(shims = RV_SHIMS, param_names) {
  bad <- character(0)
  if (!length(shims)) return("the stand-in list is empty")
  if (is.null(names(shims)) || any(!nzchar(names(shims))))
    bad <- c(bad, "every stand-in must be named for its parameter")
  if (anyDuplicated(names(shims))) bad <- c(bad, "duplicate stand-in names")
  for (n in names(shims))
    if (!is.character(shims[[n]]) || length(shims[[n]]) != 1L || !nzchar(shims[[n]]))
      bad <- c(bad, sprintf("%s: the description is missing or empty", n))
  if (!missing(param_names)) {
    gone <- setdiff(names(shims), param_names)
    if (length(gone))
      bad <- c(bad, sprintf("stand-in(s) naming a parameter this build does not carry: %s",
                            paste(gone, collapse = ", ")))
  }
  bad
}

# ---------------------------------------------------------------------
# THE MEASURED STATION-vs-HEMISPHERE OFFSET (card 1; Marcus 2026-09-22, K3/N3)
#
# ⭐ THIS IS WHAT TURNS CARD 1 FROM "we fitted an offset" INTO "we fitted an
# offset and here is the measured one" -- which is exactly what Marcus asked
# for: "there should be an observed offset between Mauna Loa and hemispheric
# average: are there other sources that we could use to estimate that offset and
# compare it to the one that comes out of our model?"
#
# ⚠ WHY THESE ARE TYPED HERE RATHER THAN COMPUTED LIVE, when every other number
# on this tab is computed. They are OBSERVATIONS, not model output: they do not
# move when the model is refitted, which is the staleness this tab's design
# guards against. And they CANNOT be computed in a deployment -- they come from
# `data-raw/downloads/`, which is gitignored and does not ship. Typed, named,
# and carrying the script that produced them and the product's DOI.
#
# ⛔ NOT in R/constants.R deliberately: that registry is the MODEL's physical
# constants, and `ccx_check_constants()` feeds card 8's "N of M provisional"
# readout. Adding two observational comparanda there would move a number on
# another card for no reason.
RV_REP_OBS_SOURCE <- paste("NOAA MBL zonal reference (Lan, Tans, Thoning & NOAA GML 2024,",
                           "doi:10.15138/DVNP-F961) minus the station records the",
                           "likelihood scores, matched month by month;",
                           "calibration/diag_rep_dc_mbl_zonal.R")
RV_REP_OBS_NH   <- 0.738   # ppm, MBL 0-90N  minus Mauna Loa, 1979-2025, positive in 47/47 yr
RV_REP_OBS_SH   <- 0.814   # ppm, MBL 90S-0  minus South Pole, 1979-2024, positive in 46/46 yr
RV_REP_OBS_MEAN <- (RV_REP_OBS_NH + RV_REP_OBS_SH) / 2
# ---- and the δ¹³C side of the same parameter (N5, 2026-09-22) -------
# ⭐ `rep_dC` is ONE parameter tied across species by mass balance, so it also
# fixes a δ¹³C station offset -- one nobody had ever compared with an
# observation. NOAA publishes no zonal δ¹³C reference (measured: the MBL form
# offers CO₂/CH₄/N₂O/SF₆ only), so the hemispheric mean is BUILT from 87 flask
# sites by data-raw/build_hemispheric_flask_means.R on Marcus's ruling -- all
# sites, latitude-band-area weighted, gaps dropped -- and CO₂ is built the same
# way from the same sites so the two can be compared without comparing networks.
RV_REP_OBS_D13C_NH <- -0.092  # permil, hemispheric mean minus MLO, 1989-2014
RV_REP_OBS_D13C_SH <- -0.011  # permil, hemispheric mean minus SPO
# ⛔ THE ASYMMETRY IS THE POINT: measured, the δ¹³C offset is ~8x larger in the
# north than the south; the model's is the SAME in both (one common-mode
# parameter). And the source signature that would reconcile the measured CO₂
# and δ¹³C offsets is -35 permil in the north against -13 in the south, where
# the model assumes a single -26.5 (LIK_REP_SOURCE_D13C, itself PROVISIONAL and
# UNCITED). No one value can describe both hemispheres.
# ⚠ The SH row is the weaker of the two: NOAA's MBL reference EXCLUDES Mauna Loa
# (an altitude site) but INCLUDES South Pole, so NH-vs-MLO is independent and
# SH-vs-SPO is partly circular. Said on the card, not just here.

# ---------------------------------------------------------------------
# Lazy machinery
# ---------------------------------------------------------------------
RV_CACHE <- new.env(parent = emptyenv())

#' Memoise one expensive review computation under `key`
#'
#' Errors are cached too, as a `rv_failed` object, so a kernel that cannot run
#' is reported once and does not re-throw on every re-render.
rv_memo <- function(key, fn) {
  if (!exists(key, envir = RV_CACHE, inherits = FALSE)) {
    v <- tryCatch(fn(), error = function(e)
      structure(list(msg = conditionMessage(e)), class = "rv_failed"))
    assign(key, v, envir = RV_CACHE)
  }
  get(key, envir = RV_CACHE, inherits = FALSE)
}

rv_failed <- function(x) inherits(x, "rv_failed")

#' Source the gate kernels once. Returns TRUE if the dg_* family is available.
rv_gates_ready <- function() {
  rv_memo("gates_ready", function() {
    f <- ccx_path("calibration", "lib_design_gates.R")
    if (!file.exists(f)) return(FALSE)
    # sourced into the global env deliberately: lib_design_gates.R itself
    # source()s lib_seas_limbs.R and expects its own constants visible.
    suppressWarnings(source(f, local = FALSE))
    exists("dg_vector") && exists("dg_run")
  })
}

rv_need_gates <- function() {
  if (!isTRUE(rv_gates_ready()))
    stop("the gate kernels (calibration/lib_design_gates.R) are not available ",
         "in this deployment, so this card cannot show its measurement")
  invisible(TRUE)
}

#' The canonical arm, as the gate kernels see it (params + the three nuisances
#' + the spin-up the file was fitted under).
rv_arm <- function(mode) rv_memo(paste0("arm_", mode), function() {
  rv_need_gates(); dg_vector(mode)
})

#' A gate run (1750-2025, the gate window) for one arm.
rv_run <- function(mode) rv_memo(paste0("run_", mode), function() {
  rv_need_gates(); dg_run(rv_arm(mode))
})

# ---------------------------------------------------------------------
# CARD 1 -- the model box sits above Mauna Loa (`rep_dC`)
#
# Cheap: it reads the run the app already made. The number that matters is not
# the gap but the comparison the LIKELIHOOD made, which is the box MINUS the
# offset; the panel shows both, and the residual of each.
# ---------------------------------------------------------------------
rv_rep_dc <- function() rv_memo("rep_dc", function() {
  o <- APP_HIST$out
  mlo <- APP_OBS$co2[APP_OBS$co2$station == "MLO", ]
  # model NH box at each observation's own date, so the residual is a matched
  # difference rather than two series sampled on different grids
  box <- stats::approx(o$t, o$co2_NH, xout = mlo$decimal_date)$y
  ok <- is.finite(box) & is.finite(mlo$co2_ppm)
  raw <- box[ok] - mlo$co2_ppm[ok]
  list(year = mlo$decimal_date[ok],
       resid_box = raw,                    # what the PANEL used to show
       resid_scored = raw - APP_REP_DC,    # what the LIKELIHOOD scored
       rep_dC = APP_REP_DC,
       prior_sd = ccx_const_or(LIK_CO2_REP_ERR, 1),
       mean_box = mean(raw), mean_scored = mean(raw - APP_REP_DC),
       rmse_scored = sqrt(mean((raw - APP_REP_DC)^2)),
       n = sum(ok))
})

# LIK_CO2_REP_ERR is defined in R/likelihood.R; this guards a deployment that
# somehow lacks it rather than letting a card die on a missing constant.
ccx_const_or <- function(x, default) tryCatch(
  if (is.numeric(x) && length(x) == 1L) x else default, error = function(e) default)

# ---------------------------------------------------------------------
# CARD 2 -- the interhemispheric d13C gradient (gates H / GL)
# ---------------------------------------------------------------------
rv_gradients <- function() rv_memo("gradients", function() {
  rv_need_gates()
  v <- rv_arm(CCX_MODE_CANONICAL); r <- rv_run(CCX_MODE_CANONICAL)
  obs <- ccx_prepare_obs()
  ho <- dg_gateH_obs(obs)
  g  <- dg_gateH(v, obs, ho, r = r)
  list(g = g, ho = ho,
       verdict_H  = dg_gateH_verdict(g, ho),
       verdict_GL = dg_gateGL_verdict(g, ho, rep_frac = dg_gl_rep_frac(g, ho)))
})

# ---------------------------------------------------------------------
# CARD 3 -- the hemispheric air-sea d13C disequilibrium (gate D)
# ---------------------------------------------------------------------
rv_gateD <- function() rv_memo("gateD", function() {
  rv_need_gates()
  do <- dg_gateD_obs()
  dg_gateD_verdict(dg_gateD(rv_run(CCX_MODE_CANONICAL),
                            rv_arm(CCX_MODE_CANONICAL), do), do)
})

# ---------------------------------------------------------------------
# CARD 4 -- interannual variance (gate V) and the ENSO slope
#
# TWO DIFFERENT QUANTITIES AND THE CARD MUST NOT MERGE THEM: the SENSITIVITY of
# the ocean sink to the ENSO index (0.89x observed, carried by a physical
# upwelling limb) and the VARIANCE of the year-to-year growth anomaly (0.59x).
# The model has the first and not the second. The knockout run below zeroes
# EVERY ocean ENSO mechanism -- the shim pair AND the layer-3 limb -- because a
# knockout that misses one reads the full model as its own control.
# ---------------------------------------------------------------------
RV_ENSO_WIN <- c(1959, 2024)

rv_variability <- function() rv_memo("variability", function() {
  rv_need_gates()
  v <- rv_arm(CCX_MODE_CANONICAL); r <- rv_run(CCX_MODE_CANONICAL)
  gv <- dg_gateV(r); ov <- dg_gateV_obs()
  ma <- dg_v_anom(dg_af_annual_model(r))
  oa <- dg_v_anom(DG_AF_OBS_ANNUAL)
  yr <- DG_AF_OBS_ANNUAL$year[DG_AF_OBS_ANNUAL$year >= DG_V_WIN[1] &
                              DG_AF_OBS_ANNUAL$year <= DG_V_WIN[2]]
  # N7 (Marcus 2026-09-22): "commonalities between the years the model over- and
  # undershoots?" The sharpest version of that question is whether what is
  # MISSING from the model's variance is ENSO-shaped -- and it is not. Costs no
  # extra run: both anomaly series are already here and the index is on disk.
  # ⚠ ON THE GATE'S OWN ESTIMATOR (dg_v_anom: growth regressed on emissions with
  # a time-varying airborne fraction, GtC/yr), NOT the ppm/yr spline the "What
  # if…?" tab uses. The two agree qualitatively; their numbers are not
  # interchangeable and neither may be quoted as the other.
  ens <- tryCatch({
    en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds")))
    ea <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
    k <- match(yr, ea$year)
    ok <- !is.na(k) & is.finite(ma) & is.finite(oa)
    if (sum(ok) < 20) NULL else {
      cm <- stats::cor.test(ma[ok], ea$nino34_anom[k[ok]])
      co <- stats::cor.test(oa[ok], ea$nino34_anom[k[ok]])
      list(n = sum(ok), r_model = unname(cm$estimate), p_model = cm$p.value,
           r_obs = unname(co$estimate), p_obs = co$p.value)
    }
  }, error = function(e) NULL)
  list(model_anom = ma, obs_anom = oa, years = yr, enso = ens,
       verdict = dg_gateV_verdict(gv, ov), gv = gv, ov = ov)
})

rv_enso_slope <- function() rv_memo("enso_slope", function() {
  rv_need_gates()
  en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds")))
  en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
  win <- function(d) d[d$year >= RV_ENSO_WIN[1] & d$year <= RV_ENSO_WIN[2], ]
  fit <- function(d, y) {
    d <- win(stats::na.omit(merge(d, en_ann, by = "year")))
    names(d)[names(d) == y] <- "v"
    f <- stats::lm(v ~ year + nino34_anom, data = d)
    list(slope = stats::coef(f)[["nino34_anom"]],
         se = summary(f)$coefficients["nino34_anom", 2],
         anom = stats::residuals(stats::lm(v ~ year, data = d)),
         index = d$nino34_anom, year = d$year)
  }
  gcb <- ccx_prepare_obs()$gcb
  obs <- fit(gcb[, c("year", "ocean_sink")], "ocean_sink")
  sk  <- dg_annual_sinks(rv_run(CCX_MODE_CANONICAL))
  full <- fit(data.frame(year = sk$year, oc = sk$ocean), "oc")
  # the knockout: every ocean-side ENSO mechanism to zero, then re-run
  v2 <- rv_arm(CCX_MODE_CANONICAL)
  v2$p$gamma_enso_ocn_NH <- 0; v2$p$gamma_enso_ocn_SH <- 0
  if (!is.null(v2$p$w_enso_l2)) v2$p$w_enso_l2 <- 0
  sk2 <- dg_annual_sinks(dg_run(v2))
  sol <- fit(data.frame(year = sk2$year, oc = sk2$ocean), "oc")
  list(obs = obs, full = full, sol = sol,
       ratio = full$slope / obs$slope,
       w_enso_l2 = if (is.null(v2$p$w_enso_l2)) 0 else
         rv_arm(CCX_MODE_CANONICAL)$p$w_enso_l2)
})

# ---------------------------------------------------------------------
# CARD 5 -- the pulse: IRF and the 1000-year partition, against Joos et al. 2013
#
# ⚠ A COMPARISON, NOT A GATE (Marcus 09-08h). Nothing from Joos scores this
# model; the card says so, and the caption may not call this a failure.
# ---------------------------------------------------------------------
rv_pulse <- function() rv_memo("pulse", function() {
  rv_need_gates()
  v <- rv_arm(CCX_MODE_CANONICAL)
  spin <- dg_spinup(v)
  F_hist <- ccx_build_forcing("historical", c(1750, JOOS_REF_YEAR),
                              prod_c14 = spin$prod_c14,
                              bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  sp_ref <- spin; sp_ref$y <- ccx_run_fast(spin, F_hist)$state
  F_fwd <- suppressWarnings(ccx_build_forcing(
    "historical", c(JOOS_REF_YEAR, JOOS_REF_YEAR + max(RV_IRF_READ) + 10),
    prod_c14 = spin$prod_c14, bomb_total_kmol = 0, luc_scale = v$luc_scale))
  for (cc in c("e_foss_NH", "e_foss_SH", "e_luc_NH", "e_luc_SH",
               "enso", "c14_bomb", "c14_nuclear")) F_fwd[[cc]] <- 0
  F_fwd$gmst <- F_fwd$gmst[1]
  o <- ccx_irf(sp_ref, ccx_hold_forcing(sp_ref, F_fwd, verbose = FALSE))
  o$t <- o$t - (JOOS_PULSE_YR - JOOS_REF_YEAR)
  k <- o$t >= 0
  at <- function(y) o$irf[k][which.min(abs(o$t[k] - y))]
  part <- dg_gateL_partition(v, horizon = RV_IRF_HORIZON)
  list(t = o$t[k], irf = o$irf[k],
       read = vapply(RV_IRF_READ, at, numeric(1)),
       joos = vapply(RV_IRF_READ, joos_irf, numeric(1)),
       horizons = RV_IRF_READ,
       partition = dg_compareL(part), closure = part$closure,
       joos_src = DG_L_JOOS$src)
})

# ---------------------------------------------------------------------
# CARD 6 -- the seas_ml-0 control fits better (the AIC accounting)
#
# The one card that needs a SECOND parameter set spun up and run. Both arms are
# run here so the seasonal panels are like-for-like: same window, same
# climatology estimator, each arm under the spin-up ITS OWN file records.
# ---------------------------------------------------------------------
rv_control <- function() rv_memo("control", function() {
  rv_need_gates()
  vC <- rv_arm(CCX_MODE_CANONICAL); vB <- rv_arm(CCX_MODE_SEASML0_CONTROL)
  rC <- rv_run(CCX_MODE_CANONICAL); rB <- rv_run(CCX_MODE_SEASML0_CONTROL)
  # THE LIKELIHOODS ARE THE FILES' OWN STORED STREAMS. They are properties of
  # the FIT, not of a run, and recomputing them here would be a second
  # implementation of the objective living inside the app -- the two-copies
  # failure this project has a standing rule against. The scorecard's reproduction
  # check is what guarantees they still describe the vector the app is running.
  # ⚠ `streams` is a LIST of per-row values: unlist before summing.
  lik <- function(v) if (is.null(v$md$streams)) NA_real_ else sum(unlist(v$md$streams))
  nrows <- function(v) if (is.null(v$md$streams)) NA_integer_ else length(unlist(v$md$streams))
  k <- function(v) length(v$md$param_names)
  list(canonical = list(name = CCX_MODE_CANONICAL, lik = lik(vC), k = k(vC),
                        out = rC$out, h_ml = vC$p$h_ml),
       control   = list(name = CCX_MODE_SEASML0_CONTROL, lik = lik(vB), k = k(vB),
                        out = rB$out),
       n_rows = nrows(vC),
       # positive = the control wins, which is the direction the card describes
       d_aic = 2 * (k(vC) - k(vB)) - 2 * (lik(vC) - lik(vB)))
})

# ---------------------------------------------------------------------
# CARD 8 -- the stand-ins and the provisional constants
# ---------------------------------------------------------------------
rv_stand_ins <- function() rv_memo("stand_ins", function() {
  v <- tryCatch(rv_arm(CCX_MODE_CANONICAL), error = function(e) NULL)
  pins <- if (is.null(v)) CCX_MODE_CANONICAL_PINS else v$pins
  # THE OVERLAP IS COMPUTED, NOT DESCRIBED (N12). Which stand-ins the canonical
  # currently holds at a value is a property of the mode file, and it has moved
  # twice already: at hilda29l three of the seven are pinned at zero, i.e.
  # switched off rather than fitted. A sentence claiming that would be a second
  # claim about the model with nothing checking it.
  list(pins = pins,
       shims = RV_SHIMS,
       shim_problems = rv_validate_shims(RV_SHIMS, CCX_PARAM_NAMES),
       shims_held = intersect(names(RV_SHIMS), names(pins)),
       provisional = ccx_check_constants(quiet = TRUE),
       n_constants = length(CCX_CONSTANTS),
       n_fitted = if (is.null(v)) NA_integer_ else length(v$md$param_names))
})

# ---------------------------------------------------------------------
# THE CARD LEDGER
#
# `id` is the number a commenter is asked to lead with, so it is a stable
# identifier and NOT the display order -- reordering the tab must not renumber
# a card somebody has already written about.
# ---------------------------------------------------------------------
RV_CARDS <- list(
  list(id = 1, key = "repdc", class = "shim",
       title = "The model's CO₂ sits above Mauna Loa",
       plain = paste("The model's northern box runs a few parts per million",
                     "above the Mauna Loa record. That gap is not an error in the",
                     "fit: the calibration scored the model through a fitted",
                     "station-vs-box offset, and until now the panel drew the box",
                     "without it. Both are now on the chart."),
       detail = paste("A hemispheric-mean box is not a remote marine station. The",
                      "mean includes continental boundary-layer air Mauna Loa never",
                      "samples, carrying extra CO₂ that is isotopically light, so",
                      "the likelihood converts box to station through one",
                      "parameter, `rep_dC`, applied to CO₂ and δ¹³C together by mass",
                      "balance. Tying the two species is deliberate: a free δ¹³C",
                      "offset would have absorbed the Suess overshoot and reported",
                      "a good fit. The prior is N(0, 1 ppm) -- the repo's own",
                      "station-vs-box scale, itself larger than the 0.39-0.59 ppm",
                      "RMS between co-located instruments at Mauna Loa. The fitted",
                      "value sits well outside that prior, which is the flag.",
                      # K3/N3 (Marcus 2026-09-22): "is there an OBSERVED offset we
                      # could compare ours against?" There is, and it is now on the
                      # chart as well as in this text.
                      # ⛔ OBSERVATIONAL FACTS ONLY IN THIS STATIC STRING. The
                      # ratio and the excess depend on the FITTED value, which
                      # moves with every refit -- they are computed on the chart
                      # instead. A literal "3.515" here is the exact staleness
                      # this tab exists to avoid, and it was written and removed
                      # once already on 2026-09-22.
                      sprintf(paste("\n\nAND THERE IS A MEASURED OFFSET TO COMPARE IT",
                                    "AGAINST. Differencing the NOAA marine-boundary-layer",
                                    "reference against these same two stations, month by",
                                    "month, gives %+.2f ppm in the north and %+.2f ppm in",
                                    "the south -- positive in every year of the record. So",
                                    "the model's SIGN is the physically expected one, and",
                                    "its north-south ORDERING is right too. What is not",
                                    "right is the SIZE, and the chart above shows the gap:",
                                    "the fitted offset is the upper dashed line, the",
                                    "measured one the lower. Re-centring the prior on the",
                                    "measured value would relabel most of that gap rather",
                                    "than remove it."),
                              RV_REP_OBS_NH, RV_REP_OBS_SH),
                      sprintf(paste("\n\nTHE SAME PARAMETER ALSO SETS A \u03b4\u00b9\u00b3C OFFSET,",
                                    "because one number is tied across both species by",
                                    "mass balance \u2014 and that side had never been checked",
                                    "against an observation at all. Built from the flask",
                                    "network, the measured \u03b4\u00b9\u00b3C offset is %+.3f permil in",
                                    "the north and %+.3f in the south. The model's is the",
                                    "same in both hemispheres, because it is one",
                                    "common-mode number. Worse, the carbon signature that",
                                    "would reconcile the measured CO\u2082 and \u03b4\u00b9\u00b3C offsets",
                                    "is about \u221235 permil in the north and \u221213 in the",
                                    "south, where the model assumes a single \u221226.5 \u2014 so no",
                                    "one value describes both. The tie itself, not just its",
                                    "size, is doing work it cannot support."),
                              RV_REP_OBS_D13C_NH, RV_REP_OBS_D13C_SH),
                      sprintf(paste("\n\nSource: %s. One asymmetry worth knowing: that",
                                    "reference EXCLUDES Mauna Loa, so the northern",
                                    "comparison is independent, but it INCLUDES the South",
                                    "Pole, so the southern one is partly circular."),
                              RV_REP_OBS_SOURCE)),
       ask = paste("The fit needs several times the station offset that is",
                   "actually measured. Is a stand-in of that size acceptable in a",
                   "teaching model -- and if not, what would you constrain it with?")),
  list(id = 2, key = "gradient", class = "structural",
       title = "The north-south δ¹³C gradient is twice the observed one",
       plain = paste("Between Mauna Loa and the South Pole, the model's δ¹³C",
                     "difference is about twice what is measured -- as a nearly",
                     "constant offset, not a drift. The CO₂ gradient between the",
                     "same two stations is close to right."),
       detail = paste("Closing it needs a persistent north-minus-south isotopic",
                      "flux the model has no carrier for. Each hemisphere has its",
                      "own ocean and they exchange only through the air, so",
                      "nothing can carry an isotopic signal from one deep ocean",
                      "to the other. Every lever tried moved the LEVELS of the two",
                      "hemispheres and not the DIFFERENCE between them. That the",
                      "CO₂ gradient is right while the isotopic one is not is the",
                      "diagnostic: the transport is not obviously wrong, the",
                      "isotopic loading of it is."),
       ask = paste("Is a 2x hemispheric isotope gradient a deal-breaker for a",
                   "model whose CO₂ gradient and both Suess trends are right?",
                   "What mechanism might help close it?")),
  list(id = 3, key = "diseq", class = "structural",
       title = "The ocean's north-south isotopic disequilibrium is too symmetric",
       plain = paste("The measured air-sea δ¹³C disequilibrium is much larger in",
                     "the northern surface ocean than the southern. The model has",
                     "the right global size but far too little of the asymmetry --",
                     "about a third of the observed difference."),
       detail = paste("This is the same structural limit as card 2, seen in a",
                      "second, independent observation (GLODAP surface bottles",
                      "rather than atmospheric stations). The deficit is on the",
                      "northern side. There is a related quantitative tension",
                      "worth knowing: the model's air-sea isotopic exchange time",
                      "is over-determined by roughly 15 % -- the surface bottles",
                      "want it longer, the atmospheric δ¹³C decline holds it where",
                      "it is -- so a fix that satisfies one moves away from the",
                      "other. Note also that the southern cold box equilibrates",
                      "with the deep ocean, so its disequilibrium is a statement",
                      "about the model's deep δ¹³C, not its surface."),
       ask = paste("Same question as card 2 -- these are one flaw with two",
                   "observables. And: would an interhemispheric deep exchange be",
                   "worth building into a teaching model to close it?")),
  list(id = 4, key = "variance", class = "structural",
       title = "Year-to-year variability is about 60 % of observed",
       plain = paste("The model's ENSO SENSITIVITY is close to right -- push the",
                     "index and the ocean sink responds by nearly the amount the",
                     "Global Carbon Budget shows. But the total year-to-year",
                     "wobble in CO₂ growth is only about 60 % of the observed",
                     "one. The app's ENSO switch is a sensitivity, not a",
                     "reconstruction."),
       detail = paste("The sensitivity is carried by a physical mechanism -- a",
                      "layer-3 upwelling anomaly driven by the Niño3.4 index,",
                      "whose fitted strength lands inside the observed range for",
                      "equatorial transport variability. It replaced a pair of",
                      "fitted coefficients that had been overturning a",
                      "wrong-signed solubility response, which is why the",
                      "mechanism was adopted even though it costs fit. On its own",
                      "the solubility path still has the wrong sign. The variance",
                      "the record carries BEYOND ENSO is where the shortfall is,",
                      # N8 (Marcus 2026-09-22): this card USED to say the
                      # volcanic and land-side variance had "no mechanism here",
                      # and that was my error -- `gamma_diff` = 0.25 is live in
                      # ccx_default_params(), neither fitted nor pinned, and the
                      # AOD -> diffuse-light -> NPP path runs. MEASURED at the
                      # canonical: zeroing gamma_diff moves CO2 by 1.53 ppm at
                      # its largest in 1991-95 and by -0.73 ppm at 2024. The
                      # corrected statement is the more interesting one.
                      "and the interesting part is that it is not all for want of",
                      "a mechanism: the volcanic path IS here and running --",
                      "stratospheric aerosol scatters sunlight, the model's plants",
                      "use that diffuse light better, and switching the path off",
                      "moves CO₂ by about one and a half parts per million in",
                      "the years after Pinatubo. It is present and the total",
                      "wobble is still short.",
                      # N7 (Marcus 2026-09-22): "can we identify any commonalities
                      # between the years the model overshoots the growth rate,
                      # and/or between the years it undershoots?" Measured in
                      # calibration/diag_growth_residual_years.R. The answer is
                      # NO for all three candidates, on n = 66, and the useful
                      # finding is the one in the chart caption. Qualitative here
                      # on purpose -- the numbers are model-dependent and belong
                      # where they are computed.
                      "\n\nWE LOOKED FOR A PATTERN IN THE MISSES AND DID NOT FIND",
                      "ONE. Year by year, the difference between the model's growth",
                      "and the measured growth shows no usable association with the",
                      "El Ni\u00f1o index, with volcanic aerosol, or with the decade:",
                      "on sixty-six years none of the three reaches significance,",
                      "and the decade averages all sit well inside one year's",
                      "scatter. The single largest overshoot is 1991 -- the model",
                      "does not draw down as much carbon after Pinatubo as the",
                      "record does -- but 1983, the other big eruption, misses the",
                      "other way, so even that is not a rule. What the caption",
                      "above reports is the finding that survives: the model's",
                      "variability is MORE El Ni\u00f1o-driven than the real record's,",
                      "so the variance it lacks is of some other kind."),
       ask = paste("Is a model that gets the ENSO sensitivity right but only part",
                   "of the variance acceptable for teaching what makes CO₂ wobble?",
                   "And if the missing variability is not El Ni\u00f1o, not volcanic and",
                   "not a trend \u2014 what would you look for next?")),
  list(id = 5, key = "pulse", class = "comparison",
       title = "A pulse of CO₂ decays faster here than in the multi-model mean",
       plain = paste("Release a pulse and this model keeps less of it in the air",
                     "at a century than the Joos et al. (2013) multi-model mean",
                     "does. The eventual split between land, ocean and air at a",
                     "thousand years is inside that study's range on every term."),
       detail = paste("This is a COMPARISON and deliberately not a test: nothing",
                      "from that study is allowed to score this model, because a",
                      "long perturbation lifetime is supposed to EMERGE from the",
                      "seasonal and isotopic constraints rather than be fitted",
                      "to. Reporting the difference and not tuning it away is the",
                      "point. Where the difference sits is visible in the",
                      "partition: the land holds a larger share here than the",
                      "multi-model mean and the ocean a smaller one."),
       ask = paste("The app teaches how long CO₂ lasts. Is a lifetime shorter",
                   "than the multi-model mean -- with the shape inside its band --",
                   "acceptable to teach, or does it undercut the lesson?")),
  list(id = 6, key = "aic", class = "accounting",
       title = "A simpler version of the model fits the data better",
       plain = paste("Switching off the seasonal mixed layer and refitting gives a",
                     "version with more free parameters that still scores better",
                     "by AIC. The mechanism was kept anyway, on the judgement",
                     "that it is a real process and the thing it replaced was a",
                     "fitted stand-in."),
       detail = paste("The seasonal mixed layer is an entrainment channel with a",
                      "depth the fit puts in the observed range; what it replaced",
                      "was a coefficient with no mechanism behind it. Holding it",
                      "costs a measurable amount of likelihood, concentrated in",
                      "the southern seasonal δ¹³C, the deep alkalinity gradient",
                      "and the northern seasonal CO₂. A free refit of the same",
                      "structure was run as a check: with the ENSO pair free, the",
                      "upwelling limb halves and a seasonal coefficient takes up",
                      "the slack -- one observable with two possible carriers,",
                      "which is the whole argument for choosing on physicality",
                      "rather than on fit."),
       ask = paste("When a physical mechanism loses to a stand-in by a few AIC, is",
                   "keeping the mechanism the right call -- in a model whose",
                   "purpose is to teach mechanisms?")),
  list(id = 7, key = "bands", class = "gap",
       title = "There are no uncertainty bands, anywhere",
       plain = paste("Every line in this app is a single best fit. There is no",
                     "posterior, so there are no ribbons, and no number here",
                     "comes with a calibrated uncertainty."),
       detail = paste("The parameters were located by dispersed multistart",
                      "optimisation, and the curvature at the optimum is",
                      "well-behaved enough to quote individual standard errors --",
                      "but a Gaussian approximation at a mode is not a posterior,",
                      "and at this model's conditioning the widest directions",
                      "would be exactly the ones that approximation handles worst.",
                      "Drawing a band from it would put a number on the chart that",
                      "reads as calibrated uncertainty and is not. Running a real",
                      "sampler is planned for the final model, not this beta: the",
                      "compute is affordable, but no sampler has yet converged on",
                      "this posterior, and that is a research problem rather than",
                      "a queue wait."),
       ask = paste("Would you want the posterior before you trusted any of this,",
                   "or is a single best fit acceptable for a teaching tool that",
                   "says so on every tab?")),
  list(id = 8, key = "shims", class = "design",
       title = "Some parameters stand in for mechanisms, and some constants are unsourced",
       plain = paste("Several fitted parameters are stand-ins: they absorb a",
                     "discrepancy rather than represent a process. Several",
                     "physical constants are still marked provisional -- their",
                     "values were inverted through the model or held, rather than",
                     "traced to a measurement."),
       # N11 + N12 (Marcus 2026-09-22): the "most that naming buys" clause is
       # cut, and the bigger fix -- the prose named the SHIMS while the table
       # below listed the PINS, and the card presented them as one list. They
       # are two different things; both are now shown, labelled, with the
       # overlap COMPUTED rather than described (rv_stand_ins()).
       detail = paste("Each is named in the code and listed below rather than",
                      "quietly absorbed. The two lists below are different things",
                      "and it is worth keeping them apart. A STAND-IN is fitted",
                      "freely and absorbs a discrepancy instead of representing a",
                      "process; a HELD parameter is one the calibration is not",
                      "allowed to move at all, carried at a stated number. Some",
                      "names are in both -- a stand-in that was switched off by",
                      "holding it at zero. The stand-ins that matter most for what",
                      "this app claims are the station offset (card 1), the",
                      "δ¹³C gradient offset (card 2 is scored net of it), and a",
                      "seasonal sea-surface-temperature amplitude fitted well",
                      "under the observed one."),
       ask = paste("Which of these would you want carried by a real mechanism",
                   "before you would use the model to teach from?"))
)

#' VALIDATE THE CARD LEDGER. A function, not inline test expectations, so that
#' tests/testthat/test-review-cards.R can MUTATION-TEST it: break a ledger and
#' confirm this rejects it. A gate that has never been shown to fail is not a
#' gate (project rule).
#'
#' @param cards a ledger in RV_CARDS' shape
#' @param ui_text the text of app/ui.R, or NULL to skip the rendering checks
#' @return character(0) if valid, else one string per problem
rv_validate_cards <- function(cards = RV_CARDS, ui_text = NULL) {
  bad <- character(0)
  need <- c("id", "key", "class", "title", "plain", "detail", "ask")
  ids <- vapply(cards, function(c_) if (is.numeric(c_$id)) c_$id else NA_real_, 0)
  if (anyNA(ids)) bad <- c(bad, "every card needs a numeric id")
  if (anyDuplicated(ids[!is.na(ids)]))
    bad <- c(bad, sprintf("duplicate card id(s): %s",
                          paste(unique(ids[duplicated(ids)]), collapse = ", ")))
  keys <- vapply(cards, function(c_) as.character(c_$key %||% NA), "")
  if (anyDuplicated(keys)) bad <- c(bad, "duplicate card keys")
  for (c_ in cards) {
    lab <- sprintf("card %s", c_$id %||% "?")
    miss <- need[!need %in% names(c_)]
    if (length(miss))
      bad <- c(bad, sprintf("%s lacks: %s", lab, paste(miss, collapse = ", ")))
    if (!is.null(c_$class) && !c_$class %in% names(RV_CLASS_GLOSS))
      bad <- c(bad, sprintf("%s has class '%s', which has no gloss", lab, c_$class))
    for (f in intersect(c("title", "plain", "detail", "ask"), names(c_)))
      if (!is.character(c_[[f]]) || !nzchar(c_[[f]]))
        bad <- c(bad, sprintf("%s: %s is empty", lab, f))
    # ⚠ THE ONE THAT MATTERS FOR THE REVIEW. A card the tab never renders is a
    # question nobody is asked, and it fails silently -- the tab still looks
    # complete. Checked against ui.R's TEXT so it needs no app startup.
    if (!is.null(ui_text) && !is.null(c_$id) &&
        !grepl(sprintf("review_card\\(%d[,)]", c_$id), ui_text))
      bad <- c(bad, sprintf("%s is in the ledger but ui.R never renders it", lab))
  }
  if (!is.null(ui_text)) {
    rendered <- as.numeric(unique(unlist(
      regmatches(ui_text, gregexpr("(?<=review_card\\()[0-9]+", ui_text, perl = TRUE)))))
    orphan <- setdiff(rendered, ids)
    if (length(orphan))
      bad <- c(bad, sprintf("ui.R renders card(s) %s that are not in the ledger",
                            paste(orphan, collapse = ", ")))
  }
  bad
}

`%||%` <- function(a, b) if (is.null(a)) b else a

#' One card by its stable id
rv_card <- function(id) {
  k <- vapply(RV_CARDS, function(c) identical(c$id, id), logical(1))
  if (!any(k)) stop("no review card with id ", id)
  RV_CARDS[[which(k)[1]]]
}

#' The per-card link into the feedback channel. Returns NULL when the channel
#' URL has not been set, which ui.R renders as a visible warning.
rv_card_url <- function(id) {
  if (!app_link_ok(APP_FEEDBACK_URL)) return(NULL)
  sprintf("%s#card-%d", APP_FEEDBACK_URL, id)
}
