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
RV_TAB_LEAD   <- paste("Eight things this model gets wrong, or does not do, or",
                       "does on purpose in a way you might disagree with. Each",
                       "one is measured below by the running model, not quoted",
                       "from a note. For each, I want to know the same thing:")
RV_ASK        <- c("Deal-breaker", "Fixable", "Acceptable")
RV_ASK_GLOSS  <- c(
  "Deal-breaker" = "this invalidates the lesson the model is built to teach",
  "Fixable"      = "worth the work, and here is the mechanism I would add",
  "Acceptable"   = "a real limitation, correctly disclosed, fine for a teaching model")
RV_CLASS_GLOSS <- c(
  structural = paste("a consequence of the model's SHAPE -- one ocean column per",
                     "hemisphere, no interhemispheric deep exchange. Closing it",
                     "means a different model, not a better fit."),
  accounting = paste("the fit prefers a simpler version; a mechanism was kept",
                     "over the fit, on a judgement that is open to challenge."),
  shim       = paste("a fitted stand-in for a mechanism the model does not",
                     "carry. It is named rather than hidden, which is the most",
                     "that naming buys."),
  comparison = paste("not a gate. Nothing from this source is allowed to score",
                     "the model, so this is a difference reported, not a test",
                     "failed."),
  gap        = "something the product does not have yet.",
  design     = "a choice made when the model was specified.")

# The horizons and windows the cards read. Named here so a caption cannot drift
# from the number under it.
RV_IRF_HORIZON   <- 1000    # yr followed for the partition (= DG_L_HORIZON)
RV_IRF_READ      <- c(20, 100, 300)
RV_SEAS_WINDOW   <- c(2000, 2024)   # the climatology window for the seasonal panels
RV_GRAD_WINDOW   <- c(2000, 2024)   # where the MLO-SPO gradients are read

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
  list(model_anom = dg_v_anom(dg_af_annual_model(r)),
       obs_anom   = dg_v_anom(DG_AF_OBS_ANNUAL),
       years      = DG_AF_OBS_ANNUAL$year[DG_AF_OBS_ANNUAL$year >= DG_V_WIN[1] &
                                          DG_AF_OBS_ANNUAL$year <= DG_V_WIN[2]],
       verdict    = dg_gateV_verdict(gv, ov), gv = gv, ov = ov)
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
  list(pins = pins,
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
                      "value sits well outside that prior, which is the flag."),
       ask = paste("Is a fitted station-vs-box offset acceptable in a teaching",
                   "model, at this size? If not, what would you constrain it with?")),
  list(id = 2, key = "gradient", class = "structural",
       title = "The north-south δ¹³C gradient is twice the observed one",
       plain = paste("Between Mauna Loa and the South Pole, the model's δ¹³C",
                     "difference is about twice what is measured -- as a nearly",
                     "constant offset, not a drift. The CO₂ gradient between the",
                     "same two stations is close to right."),
       detail = paste("Closing it needs a persistent north-minus-south isotopic",
                      "flux the model has no carrier for: one ocean column per",
                      "hemisphere, with no interhemispheric deep exchange, cannot",
                      "produce one. Every lever tried moved the LEVELS of the two",
                      "hemispheres and not the DIFFERENCE between them. That the",
                      "CO₂ gradient is right while the isotopic one is not is the",
                      "diagnostic: the transport is not obviously wrong, the",
                      "isotopic loading of it is."),
       ask = paste("Is a 2x hemispheric isotope gradient a deal-breaker for a",
                   "model whose CO₂ gradient and both Suess trends are right?",
                   "What carrier would you expect to close it?")),
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
                      "the solubility path still has the wrong sign. What is",
                      "missing is the variance the record carries BEYOND ENSO --",
                      "volcanic and land-side -- for which there is no mechanism",
                      "here."),
       ask = paste("Is a model that gets the ENSO sensitivity right but 60 % of",
                   "the variance acceptable for teaching what makes CO₂ wobble?")),
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
       ask = paste("When a named mechanism loses to a stand-in by a few AIC, is",
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
       detail = paste("Each is named in the code and listed below rather than",
                      "quietly absorbed, which is the most that naming buys: a",
                      "named stand-in is still a stand-in. The ones that matter",
                      "most for what this app claims are the station offset",
                      "(card 1), the δ¹³C gradient offset (card 2 is scored net of",
                      "it), and a seasonal sea-surface-temperature amplitude",
                      "fitted well under the observed one."),
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
