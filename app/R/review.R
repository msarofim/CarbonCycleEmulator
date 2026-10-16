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
# WHAT IS EXPENSIVE. Cards 2, 3, 4 and 5 each need a model run that the app does
# not already have (a gate run to 2025, a knockout run, a 1000-year pulse pair).
# (2026-10-15 review: card 2 added -- rv_gradients() reads the same gate run as card 3.)
# Each is memoized in RV_CACHE and computed on FIRST VIEW, not at startup --
# startup is already the app's worst number (APP_WARMUP_NOTE) and nobody should
# pay for a tab they never open. (The old card 6, the one that spun up a second mode,
# was RETIRED 2026-10-01; see the ledger.)
#
# ⚠ THE GATE LIB IS SOURCED LAZILY. It lives in calibration/, not R/, so the
# app does not load it at startup; it also reads data/*.rds of its own. If it is
# absent (a deploy that excluded calibration/), rv_gates_ready() returns FALSE
# and the affected cards render their explanation without their number. That is
# a visible degradation, not a silent one.
# =====================================================================

# ---- named constants: every label on the tab derives from these -----
RV_TAB_TITLE  <- "Known issues"
# RV_TAB_LEAD is defined AFTER the ledger (below RV_CARDS): its count is the
# ledger's length, not a typed word. It read "Eight things" as a literal and
# would have kept saying eight when card 6 was retired (2026-10-01).
RV_ASK        <- c("Deal-breaker", "Fixable", "Acceptable")
RV_ASK_GLOSS  <- c(
  "Deal-breaker" = "this invalidates the lesson the model is built to teach",
  "Fixable"      = "worth the work, and here is the mechanism I would add",
  "Acceptable"   = "any differences with other sources are limited, appropriately disclosed, and fine for a teaching model")   # Marcus 2026-10-15
RV_CLASS_GLOSS <- c(
  # U5/N6 (Marcus 2026-09-22): "one ocean column per hemisphere" read as "no
  # ocean circulation", which is false at hilda29l. The limitation that is real
  # is the INTERHEMISPHERIC one: the two oceans never touch.
  # 2026-10-15 review: " -- " -> " — " in reader-visible strings (mechanical cleanup, approved).
  # Marcus 2026-10-15 ("Apply all the app text suggestions"): the two-oceans clause left the CLASS gloss, which issue 4
  # (a variance shortfall) also carries; issues 2 and 3 say it in their own text.
  structural = paste("a consequence of the model's shape. Closing it means a different model,",
                     "not a better fit."),
  # `accounting` ("the fit prefers a simpler version ...") went with the old card 6, its
  # only user, when that card was retired (2026-10-01).
  # Marcus 2026-10-15: "Shims are model corrections that are not based on physical mechanisms." -- put in
  # the glosses' fragment form, since each renders as "SHIM -- <gloss>".
  shim       = "a model correction that is not based on a physical mechanism.",
  # N9 (Marcus 2026-09-22): his wording, which is better than mine.
  # Marcus 2026-10-15: his wording (lower-case "we" for the fragment form).
  comparison = paste("we do not calibrate the model to match future projections,",
                     "so the alignment between CarboTope and FaIR is an emergent",
                     "property of having a physical model tuned to observed variables."),
  gap        = "something the product does not have yet.",
  # 2026-10-08 (j), card 8: neither "structural" (the hemispheres' separate oceans) nor "comparison" (written for the
  # pulse) describes it. ⚠ CLAUDE'S DRAFT, FOR MARCUS'S WORDING.
  response   = paste("the process is in the model, but it reacts by the wrong amount, and",
                     "refitting the same model does not fix it."),
  design     = "a choice made when the model was specified.")

# The horizons and windows the cards read. Named here so a caption cannot drift
# from the number under it.
RV_IRF_HORIZON   <- 1000    # yr followed for the partition (= DG_L_HORIZON)
RV_IRF_READ      <- c(20, 100, 300)
# card 5's PD100 climate (Marcus 2026-10-12: "free everywhere", as Joos: "the climate is evolving freely")
RV_PD_CLIMATE    <- CCX_PD_CLIMATE_DEFAULT
# card 5a's FaIR line (Marcus 2026-10-11: FaIR on Joos's PD100, 841-config mean, climate free);
# built by data-raw/build_fair_pd100.R, its protocol pinned by tests/testthat/test-fair-pd100.R
RV_FAIR_PD100_FILE <- "fair_pd100.rds"
RV_FAIR_LAB_FMT    <- "%s, %d-configuration mean"   # legend: the file's own label and config count
# the FaIR band (Marcus 2026-10-12, "Draw the band"): the file's own 5th-95th percentile across configs
RV_FAIR_BAND_COLS  <- c(lo = "irf_p05", hi = "irf_p95")
RV_FAIR_BAND_FMT   <- "%s, 5\u201395 %% of configurations"   # legend: label, then the percentiles above
# 2026-10-15 review: RV_SEAS_WINDOW and RV_GRAD_WINDOW (both c(2000, 2024)) REMOVED -- nothing in app/, tests/,
# R/ or calibration/ read them, and RV_GRAD_WINDOW was false: card 2 reads the gradients over every year the gate's
# own observed record has (dg_gateH_obs(): CO2 from 1962, d13C from 1980), which its caption now prints.

# ---------------------------------------------------------------------
# THE STAND-INS (card 7 since the 2026-10-01 renumbering; card 8 at review N12, Marcus 2026-09-22)
#
# ⚠ THIS IS A DIFFERENT LIST FROM THE PINS, and conflating them is the bug N12
# caught. A PIN is generated -- it is a property of the mode file the app is
# running, and rv_stand_ins() reads it off that file. A STAND-IN is a
# JUDGMENT: that a fitted name absorbs a discrepancy rather than representing
# a process. Nothing in the parameter table records that judgment, so it is
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
  grad_off_d13c   = "absorbs the north\u2013south \u03b4\u00b9\u00b3C offset the model cannot produce",
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
# constants, and `ccx_check_constants()` feeds card 7's "N of M provisional"
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
# A signed number with a true minus (U+2212), as the typed ones beside it (−35‰): sprintf prints a hyphen.
rv_signed <- function(fmt, x) sub("-", "\u2212", sprintf(fmt, x), fixed = TRUE)
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

# ---- the PRECOMPUTED values (Marcus 2026-10-15: "Precompute the known issues") ----
# The tab's first view ran the canonical's gate run, the ENSO knockout and the pulse (PD100 + the
# 1000-year partition) live: 30.7 s once on Connect Cloud's 1 CPU. calibration/build_review_precompute.R
# stores the results of the keys below at the canonical; rv_memo() takes a stored value on a cache miss.
# The product is REFUSED (and the tab computes live, as before) unless it was built for this canonical's
# mode file (name and md5). A code change that moves a value is caught by test-review-precompute.R, which
# recomputes every key live and compares; options(ccx.rv_precompute = FALSE) turns the stored values off.
RV_PRE_FILE <- c("data", "review_precompute.rds")
# key -> the function whose rv_memo() value is stored (cards 2, 3, 4 and 4b, 5)
RV_PRE_KEYS <- c(gradients = "rv_gradients", gateD = "rv_gateD", variability = "rv_variability",
                 enso_slope = "rv_enso_slope", pulse = "rv_pulse")
RV_PRE <- new.env(parent = emptyenv())

#' Why a precompute product cannot be used (character(0) if it can)
rv_pre_problems <- function(x, mode_file) {
  bad <- character(0)
  if (!identical(x$provenance$mode, CCX_MODE_CANONICAL))
    bad <- c(bad, sprintf("it was built for %s, not the canonical %s", x$provenance$mode, CCX_MODE_CANONICAL))
  if (!identical(x$provenance$mode_md5, unname(tools::md5sum(mode_file))))
    bad <- c(bad, "its mode file is not the canonical's (md5)")
  missing <- setdiff(names(RV_PRE_KEYS), names(x$values))
  if (length(missing)) bad <- c(bad, paste("it lacks", paste(missing, collapse = ", ")))
  bad
}

#' The stored values, read and checked once per process; NULL when absent, refused or switched off
rv_precomputed <- function() {
  if (!isTRUE(getOption("ccx.rv_precompute", TRUE))) return(NULL)
  if (!exists("values", envir = RV_PRE, inherits = FALSE)) {
    v <- tryCatch({
      x <- readRDS(do.call(ccx_path, as.list(RV_PRE_FILE)))
      if (length(rv_pre_problems(x, ccx_mode_file()))) NULL else x$values
    }, error = function(e) NULL)
    assign("values", v, envir = RV_PRE)
  }
  get("values", envir = RV_PRE, inherits = FALSE)
}

#' Memoize one expensive review computation under `key`
#'
#' Errors are cached too, as a `rv_failed` object, so a kernel that cannot run
#' is reported once and does not re-throw on every re-render.
rv_memo <- function(key, fn) {
  if (!exists(key, envir = RV_CACHE, inherits = FALSE)) {
    pre <- if (key %in% names(RV_PRE_KEYS)) rv_precomputed()
    v <- if (!is.null(pre[[key]])) pre[[key]] else tryCatch(fn(), error = function(e)
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
         "in this deployment, so this issue cannot show its measurement")
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
# The model has the first and not the second.
# 2026-10-15 review: those ratios were an older canonical's. At hilda31w the slope is 1.05x and the variance
# 0.88x (both printed live under card 4's charts) -- the gap between the two is smaller, the distinction the same. The knockout run below zeroes
# EVERY ocean ENSO mechanism -- the shim pair AND the layer-3 limb -- because a
# knockout that misses one reads the full model as its own control.
# ---------------------------------------------------------------------
RV_ENSO_WIN <- c(1959, 2024)
# (2026-10-15 review: at hilda31w the limb strength is HELD -- a pin from the interannual cut's module -- not
# fitted; card 4's text and caption now say so.)
# Where the canonical's fitted limb strength (`w_enso_l2`, Sv per index unit)
# sits against the observed interannual bracket (data/obs_eq_cell.rds
# w0_prior$interannual$per_index_sv: Meinen, McPhaden & Johnson 2001, 50 Sv
# peak-to-peak over the 1997-99 Nino3.4 swing). One of "below" / "inside" /
# "above", used in card 4's text; rv_enso_l2_relation() is what the test uses
# to recompute it, so a refit that moves the value fails the suite instead of
# leaving the sentence false. hilda33d: 11.91 vs [14, 25] -> "below".
# ⛔ 2026-10-08 (g): that test did NOT exist until then (no caller of
# rv_enso_l2_relation() anywhere in tests/); hilda29e's 16.79 is "inside" and the
# word stayed "below" with a green suite. It is now test-review-card-numbers.R.
# 2026-10-15 (Marcus: "Apply minimal factual fixes"): hilda31w HOLDS w_enso_l2 at 16.79 (the interannual
# cut's module), inside [14, 25], so the word is "inside" -- and "sits a little inside the range" does not
# read, so the card renders rv_enso_l2_phrase() of the word and the test checks that phrase.
RV_ENSO_L2_VS_OBS <- "inside"
rv_enso_l2_relation <- function(w, bracket)
  if (w < bracket[1]) "below" else if (w > bracket[2]) "above" else "inside"
rv_enso_l2_phrase <- function(rel)
  switch(rel, below = "a little below", above = "a little above", inside = "inside",
         stop("rv_enso_l2_phrase(): unknown relation '", rel, "'"))
rv_enso_l2_bracket <- function()
  readRDS(ccx_path("data", "obs_eq_cell.rds"))$w0_prior$interannual$per_index_sv

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
  # ⛔ 2026-10-15 review: they do NOT agree qualitatively at hilda31w. Here the model tracks the index MORE
  # closely than the record (r +0.48 vs +0.29, n = 66); on the What-if estimator it tracks it LESS (+0.18 vs
  # +0.29, reviewer-measured). So the card no longer says the missing variance "is not El Niño-shaped"; the
  # caption's comparative word is computed from r_model vs r_obs, and the detail states both readings.
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
         rv_arm(CCX_MODE_CANONICAL)$p$w_enso_l2,
       # 2026-10-15 review: whether the canonical HOLDS that strength (a pin) or fits it -- card 4b's caption
       # says which, read off the mode file rather than typed (hilda31w: held)
       w_enso_l2_held = "w_enso_l2" %in% names(rv_arm(CCX_MODE_CANONICAL)$pins),
       # the observed bracket card 4's text compares it with (A4, 2026-10-01)
       w_obs = tryCatch(rv_enso_l2_bracket(), error = function(e) NULL))
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
  # THE ONE PD100 RUNNER (R/joos_irf.R ccx_pd100, 2026-10-12), climate FREE as in Joos (Marcus
  # 2026-10-12, "free everywhere"): the background's GMST from the climate module, the pulse's own
  # warming fed back. Was held at the 2010 GMST (with the observed SST left running).
  o <- ccx_pd100(spin, JOOS_REF_YEAR + max(RV_IRF_READ) + 10, v$bomb_total, v$luc_scale,
                 climate = RV_PD_CLIMATE)
  k <- o$t >= 0
  at <- function(y) o$irf[k][which.min(abs(o$t[k] - y))]
  part <- dg_gateL_partition(v, horizon = RV_IRF_HORIZON, climate = RV_PD_CLIMATE)
  fair <- readRDS(ccx_path("data", RV_FAIR_PD100_FILE))
  fp <- attr(fair, "provenance")
  if (!startsWith(fp$climate, RV_PD_CLIMATE))
    # 2026-10-15 review: "card 5:" -> "issue 5:" (this message renders on the tab via rv_plot_unavailable())
    stop("issue 5: the FaIR line's climate (", fp$climate, ") is not the issue's (", RV_PD_CLIMATE, ")")
  list(t = o$t[k], irf = o$irf[k],
       read = vapply(RV_IRF_READ, at, numeric(1)),
       joos = vapply(RV_IRF_READ, joos_irf, numeric(1)),
       fair = data.frame(t = fair$t, irf = fair$irf_mean,
                         lo = fair[[RV_FAIR_BAND_COLS[["lo"]]]], hi = fair[[RV_FAIR_BAND_COLS[["hi"]]]]),
       fair_band_label = sprintf(RV_FAIR_BAND_FMT, fp$label),
       fair_label = sprintf(RV_FAIR_LAB_FMT, fp$label, as.integer(fp$n_configs)),
       fair_read = vapply(RV_IRF_READ, function(y) stats::approx(fair$t, fair$irf_mean, y)$y, numeric(1)),
       horizons = RV_IRF_READ, climate = o$climate,
       partition = dg_compareL(part), closure = part$closure,
       joos_src = DG_L_JOOS$src)
})

# ---------------------------------------------------------------------
# THE OLD CARD 6 (the AIC accounting) -- RETIRED 2026-10-01 (Marcus, review 10-01c A1:
# "Retire card 6"). Its id was then REUSED by the renumbering: card 6 is the bands card.
#
# It said "a simpler version of the model fits the data better": the seas_ml-0
# control beat the canonical on AIC. At hilda33d the canonical wins on the 24
# rows the two objectives share (+4.68 log-units, dAIC -5.35), so the premise
# had turned, and its caption printed "dAIC ... in the simpler version's
# favor" whatever the sign. Its run (rv_control) and its panel
# (rv_plot_control) went with it. The AIC comparison itself is still gated, in
# tests/testthat/test-mode-file.R.
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# CARD 7 (card 8 until the 2026-10-01 renumbering) -- the stand-ins and the provisional constants
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
# CARD 8 -- the ocean's climate effect against the GCB 2025 ocean models (H2; 2026-10-08 j)
#
# ⚠ A PRODUCT, NOT A LIVE RUN: emulating the ten GCB ocean-model protocols takes minutes, too slow for a card that
# renders when opened. calibration/build_ocean_climate_card.R COLLECTS three committed diagnostics made at the
# canonical (md5-gated) into data/ocean_climate_card.rds; this reads it and REFUSES one made at another mode file,
# so an adoption that does not rebuild it shows "unavailable" here and fails test-ocean-climate-card.R.
# ---------------------------------------------------------------------
RV_OCLIM_FILE <- c("data", "ocean_climate_card.rds")
RV_OCLIM_RUN  <- 11L     # the running mean drawn over the annual series: diag_h2_time_shape.R's H2_RUN
#' Why an ocean-climate product cannot back card 8 (character(0) if it can)
rv_oclim_problems <- function(x, mode_file) {
  bad <- character(0)
  if (!identical(x$provenance$mode, CCX_MODE_CANONICAL))
    bad <- c(bad, sprintf("it was built for %s, not the canonical %s", x$provenance$mode, CCX_MODE_CANONICAL))
  if (!identical(x$provenance$mode_md5, unname(tools::md5sum(mode_file))))
    bad <- c(bad, "its mode file is not the canonical's (md5)")
  bad
}
rv_ocean_climate <- function() rv_memo("ocean_climate", function() {
  x <- readRDS(do.call(ccx_path, as.list(RV_OCLIM_FILE)))
  p <- rv_oclim_problems(x, ccx_mode_file())
  # 2026-10-15 review: " -- " -> " — " (this message renders on the tab via rv_plot_unavailable())
  if (length(p)) stop(paste(p, collapse = "; "), " — rebuild it with calibration/build_ocean_climate_card.R")
  x
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
       # Marcus 2026-10-15: the last two sentences are his ("until now the panel drew the box without it" was
       # stale: the Keeling tab draws both). 2026-10-15 at hilda31w: fitted offset 5.5x the measured one.
       plain = paste("The model's northern box runs a few parts per million",
                     "above the Mauna Loa record. The calibration included an",
                     "offset between the hemispheric box and the station data that",
                     "the model could adjust. This offset is larger than the",
                     "measured offset between the station and hemispheric data."),
       detail = paste("A hemispheric-mean box is not a remote marine station. The",
                      "mean includes continental boundary-layer air Mauna Loa never",
                      "samples, carrying extra CO₂ that is isotopically light, so",
                      "the likelihood converts box to station through one",
                      "parameter, rep_dC, applied to CO₂ and δ¹³C together by mass",
                      "balance. Tying the two species is deliberate: a free δ¹³C",
                      "offset would have absorbed the Suess overshoot and reported",
                      # 2026-10-15 review: " -- " -> " — " throughout the card strings below (mechanical cleanup).
                      "a good fit. The prior is N(0, 1 ppm) — the repository's",
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
                      sprintf(paste("\n\nAnd there is a measured offset to compare it",
                                    "against. Differencing the NOAA marine-boundary-layer",
                                    "reference against these same two stations, month by",
                                    "month, gives %+.2f ppm in the north and %+.2f ppm in",
                                    "the south — positive in every year of the record. So",
                                    "the model's sign is the physically expected one, and",
                                    "its north\u2013south ordering is right too. What is not",
                                    "right is the size, and the chart above shows the gap:",
                                    # 2026-10-15 review: the measured line is DOTTED (and is the two
                                    # stations' mean; its label now says so), so "the lower" -> "the lower dotted line"
                                    "the fitted offset is the upper dashed line, the",
                                    "measured one the lower dotted line. Re-centering the prior on the",
                                    "measured value would relabel most of that gap rather",
                                    "than remove it."),
                              RV_REP_OBS_NH, RV_REP_OBS_SH),
                      sprintf(paste("\n\nThe same parameter also sets a \u03b4\u00b9\u00b3C offset,",
                                    "because one number is tied across both species by",
                                    "mass balance \u2014 and that side had never been checked",
                                    "against an observation at all. Built from the flask",
                                    # 2026-10-15 review: "permil" -> "\u2030" (the tab's own unit sign)
                                    "network, the measured \u03b4\u00b9\u00b3C offset is %s in",
                                    "the north and %s in the south. The model's is the",
                                    "same in both hemispheres, because it is one",
                                    "common-mode number. Worse, the carbon signature that",
                                    "would reconcile the measured CO\u2082 and \u03b4\u00b9\u00b3C offsets",
                                    "is about \u221235\u2030 in the north and \u221213\u2030 in the",
                                    "south, where the model assumes a single \u221226.5\u2030 \u2014 so no",
                                    "one value describes both. The tie itself, not just its",
                                    "size, is doing work it cannot support."),
                              rv_signed("%+.3f\u2030", RV_REP_OBS_D13C_NH), rv_signed("%+.3f\u2030", RV_REP_OBS_D13C_SH)),
                      sprintf(paste("\n\nSource: %s. One asymmetry: that",
                                    "reference excludes Mauna Loa, so the northern",
                                    "comparison is independent, but it includes the South",
                                    "Pole, so the southern one is partly circular."),
                              RV_REP_OBS_SOURCE)),
       ask = paste("The fit needs several times the station offset that is",
                   "actually measured. Is a stand-in of that size acceptable in a",
                   "teaching model — and if not, what do you suggest as possible ways to address this offset?")),
  list(id = 2, key = "gradient", class = "structural",
       title = "The north–south δ¹³C gradient is twice the observed one",
       # 2026-10-15 review (Marcus: "Apply all"): "close to right" / "is right" -> "about 10 % low" / "nearly
       # right". Measured at hilda31w (rv_gradients()): CO2 2.18 vs 2.43 +/- 0.059 ppm = 0.90x (z -4.3, 1962-2023);
       # d13C 1.97x (1980-2023). Card 2's caption prints both ratios live.
       plain = paste("Between Mauna Loa and the South Pole, the model's δ¹³C",
                     "difference is about twice what is measured — as a nearly",
                     "constant offset, not a drift. The CO₂ gradient between the",
                     "same two stations is about 10% low — far closer than the isotopic one."),
       detail = paste("Closing it needs a persistent north-minus-south isotopic",
                      "flux the model has no carrier for. Each hemisphere has its",
                      "own ocean and they exchange only through the air, so",
                      "nothing can carry an isotopic signal from one deep ocean",
                      "to the other. Every lever tried moved the levels of the two",
                      "hemispheres and not the difference between them. That the",
                      "CO₂ gradient is nearly right while the isotopic one is not is the",
                      "diagnostic: the transport is not obviously wrong, the",
                      "isotopic loading of it is."),
       # 2026-10-15 review: "2x" -> "2×"; "whose CO₂ gradient and both Suess trends are right" -> the 10 % qualifier
       ask = paste("Is a 2× hemispheric isotope gradient a deal-breaker for a",
                   "model whose CO₂ gradient is within about 10% and whose Suess trends are right?",
                   "What mechanism might help close it?")),
  list(id = 3, key = "diseq", class = "structural",
       title = "The ocean's north–south isotopic disequilibrium is too symmetric",
       # 2026-10-15 review (Marcus: "Apply all"): "disequilibrium" defined at first use; GLODAP expanded once.
       plain = paste("The measured air-sea δ¹³C disequilibrium (how far surface seawater's δ¹³C",
                     "sits from balance with the air above it) is much larger in",
                     "the northern surface ocean than the southern. The model has",
                     "the right global size but far too little of the asymmetry —",
                     "about a third of the observed difference."),
       # 2026-10-15 review: "The deficit is on the northern side." was half true -- on the hemisphere panel
       # (rv_gateD()$hemi vs $obs_hemi, hilda31w) the north is LOW by 0.08 permil (0.93 vs 1.01) but the south is
       # HIGH by 0.12 (0.84 vs 0.72). And "over-determined by roughly 15%" -> plain words; that 15 % was MEASURED
       # AT hilda29l and has not been re-measured at hilda31w.
       detail = paste("This is the same structural limit as issue 2, seen in a",
                      "second, independent observation (GLODAP ocean bottle samples",
                      "from the surface, rather than atmospheric stations). The miss",
                      "is on both sides: the north is too small and the south too",
                      "large, the south by more. There is a related quantitative tension:",
                      "the ocean bottles and the atmospheric δ¹³C",
                      "decline disagree by about 15% on how fast the air and sea",
                      "exchange isotopes — the surface bottles want it slower, the",
                      "atmospheric δ¹³C decline holds it where",
                      "it is — so a fix that satisfies one moves away from the",
                      "other. Note also that the southern cold box equilibrates",
                      "with the deep ocean, so its disequilibrium is a statement",
                      "about the model's deep δ¹³C, not its surface."),
       ask = paste("Same question as issue 2 — these are one flaw with two",
                   "observables. And: would an interhemispheric deep exchange be",
                   "worth building into a teaching model to close it?")),
  list(id = 4, key = "variance", class = "structural",
       # 2026-10-15 (Marcus: "Apply minimal factual fixes"): "about 60%" was 10-02's. At hilda31w it is 68 % on
       # the What-if estimator (app_wobble_shares_20261015_hilda31w, 1980-2024) and 0.88x on this card's own
       # chart (detrended, 1959-2024), so the title carries no number and the plain gives the range.
       title = "Year-to-year variability is somewhat smaller than observed",
       # Marcus 2026-10-02 (carbotopecomment): "The app's ENSO switch is a sensitivity, not a
       # reconstruction." deleted. 60% still MEASURED 10-02: 0.268 vs 0.459 ppm/yr = 58%.
       plain = paste("The model's ENSO sensitivity is close to right — push the",
                     "index and the ocean sink responds by nearly the amount the",
                     "Global Carbon Budget shows. But the total year-to-year",
                     "wobble in CO₂ growth is only about 70–90% of the observed",
                     "one, depending on the period and the method."),
                     # 2026-10-15 (Marcus: "Is this statement still true?"): NO, and REMOVED. His 10-06 timing
                     # sentence ("peaking a month after the Pacific warmth index rather than five months") was
                     # measured at hilda33p (+1 vs +5). At hilda29e (enso_growth_fit_20261008_hilda29e) and at
                     # hilda31w (enso_growth_fit_20261015_hilda31w, T2(b)) the model peaks +5 months (r 0.72),
                     # the record +5 (r 0.50): the timing miss is gone.
       # A4 (Marcus 2026-10-01, "Fix Card 4"): this said the fitted strength
       # "lands inside the observed range". True at hilda29l (13.71, inside at
       # 1 sd); at hilda33d w_enso_l2 is 11.91 against Meinen's 14-25 Sv per
       # index unit, below the range even one sd up. The relation word is a
       # named constant, RV_ENSO_L2_VS_OBS, which test-review-card-numbers.R
       # recomputes from the canonical's mode file and the data product (since
       # 10-08 g; before that no test did, whatever this said); the
       # numbers themselves are printed live in card 4b's caption.
       # 2026-10-15 review (Marcus: "Apply all"): w_enso_l2 is HELD at hilda31w (a pin from the interannual cut's
       # module), so "whose fitted strength" -> "whose strength, fixed by a separate fit to the year-to-year
       # record" (test-review-card-numbers.R still finds "sits <phrase> the range"). ENSO and Sv defined once here.
       detail = paste("The sensitivity is carried by a physical mechanism — a",
                      "layer-3 upwelling anomaly driven by the ENSO index (Niño 3.4;",
                      "ENSO is the El Niño–Southern Oscillation),",
                      sprintf("whose strength, fixed by a separate fit to the year-to-year record, sits %s the range",
                              rv_enso_l2_phrase(RV_ENSO_L2_VS_OBS)),
                      "observed for equatorial transport variability (the",
                      "numbers are under the second chart, in sverdrups, Sv: a",
                      "million cubic meters of water per second). It replaced a pair of",
                      "fitted coefficients that had been overturning a",
                      "wrong-signed solubility response, which is why the",
                      "mechanism was adopted even though it costs fit. On its own",
                      "the solubility path still has the wrong sign. The variance",
                      "the record carries beyond ENSO is where the shortfall is,",
                      # N8 (Marcus 2026-09-22): this card USED to say the
                      # volcanic and land-side variance had "no mechanism here",
                      # and that was my error -- `gamma_diff` = 0.25 is live in
                      # ccx_default_params(), neither fitted nor pinned, and the
                      # AOD -> diffuse-light -> NPP path runs. MEASURED at the
                      # canonical: zeroing gamma_diff moves CO2 by 1.53 ppm at
                      # its largest in 1991-95 and by -0.73 ppm at 2024. The
                      # corrected statement is the more interesting one.
                      # 2026-10-15 review: RE-MEASURED at hilda31w (gate run, gamma_diff 0.25 -> 0, annual mean of
                      # the two hemispheric boxes): largest 0.99 ppm, in 1993. "about one and a half" -> "about one".
                      "and the interesting part is that it is not all for want of",
                      "a mechanism: the volcanic path is here and running —",
                      "stratospheric aerosol scatters sunlight, the model's plants",
                      "use that diffuse light better, and switching the path off",
                      "moves CO₂ by about one part per million in",
                      "the years after Pinatubo. It is present and the total",
                      "wobble is still short.",
                      # Marcus 2026-10-06 (carbotopecomments.10.2.26): "Change to" -- his wording.
                      # The fitted lag is 2.61 +/- 0.41 months at hilda33p; test-review-card-numbers.R
                      # fails if the lag the canonical RUNS (fitted, or pinned by the cut's module) is more
                      # than one sd from the 2.5 written here (this named test-enso-lag.R, which never
                      # checked it; corrected 10-08 g). hilda29e pins 5.93 +/- 1.21: STALE.
                      # 2026-10-15 (Marcus: "Apply minimal factual fixes"): hilda31w HOLDS the land lag at 5.93
                      # months (the interannual cut's module, +/- 1.21), not 2.5 (his 10-06 sentence, true at
                      # hilda33p). test-review-card-numbers.R holds "six" to the lag the canonical runs.
                      "\n\nFor the land uptake, the ENSO response occurs",
                      "about six months after the index, the value a separate fit",
                      "to the year-to-year CO₂ growth record gives.",
                      # N7 (Marcus 2026-09-22): "can we identify any commonalities
                      # between the years the model overshoots the growth rate,
                      # and/or between the years it undershoots?" Measured in
                      # calibration/diag_growth_residual_years.R. The answer is
                      # NO for all three candidates, on n = 66, and the useful
                      # finding is the one in the chart caption. Qualitative here
                      # on purpose -- the numbers are model-dependent and belong
                      # where they are computed.
                      "\n\nWe looked for a pattern in the misses and did not find",
                      "one. Year by year, the difference between the model's growth",
                      # 2026-10-15 review (Marcus: "Apply all"): "El Ni\u00f1o index" -> "ENSO index"; 1983 is the year
                      # AFTER El Chich\u00f3n (April 1982), not the eruption; and the closing claim ("more El Ni\u00f1o-driven
                      # ... so the variance it lacks is of some other kind") held on the first chart's estimator
                      # (r +0.48 vs +0.29) but REVERSED on the What-if tab's (+0.18 vs +0.29), so both are stated.
                      # The ask's "is not El Ni\u00f1o" -> "is not clearly El Ni\u00f1o" to match.
                      "and the measured growth shows no usable association with the",
                      "ENSO index, with volcanic aerosol, or with the decade:",
                      "over sixty-six years none of the three reaches significance,",
                      "and the decade averages all sit well inside one year's",
                      "scatter. The single largest overshoot is 1991 \u2014 the model",
                      "does not draw down as much carbon after Pinatubo as the",
                      "record does \u2014 but 1983, the year after El Chich\u00f3n (the other",
                      "big eruption), misses the other way, so even that is not a rule.",
                      "On the first chart's measure the model's variability is more",
                      "ENSO-driven than the record's; on the What-if tab's measure it",
                      "is less \u2014 so we cannot say the missing variance is not",
                      "El Ni\u00f1o-shaped."),
       ask = paste("Is a model that gets the ENSO sensitivity right but only part",
                   "of the variance acceptable for teaching what makes CO₂ wobble?",
                   "And if the missing variability is not clearly El Ni\u00f1o, not volcanic and",
                   "not a trend \u2014 what would you look for next?")),
  list(id = 5, key = "pulse", class = "comparison",
       # Marcus 2026-10-15: title and ask are his; the plain is his own comment's statement ("We do decay
       # faster than Joos et al. 2013 in the early years, but not as fast as FaIR"), checked at hilda31w:
       # IRF 20/100/300 = 0.514/0.374/0.293 here, Joos 0.596/0.409/0.322, FaIR 0.483/0.364/0.291.
       title = "Comparing CO₂ pulse decay rates to other sources",
       plain = paste("A pulse of CO₂ leaves the air faster in this model than in the",
                     "Joos et al. (2013) multi-model mean, most of all in the early",
                     "decades, but not as fast as in FaIR."),
       detail = paste("This is a comparison and deliberately not a test: nothing",
                      "from that study is allowed to score this model, because a",
                      "long perturbation lifetime is supposed to emerge from the",
                      "seasonal and isotopic constraints rather than be fitted",
                      "to. Reporting the difference and not tuning it away is the",
                      # A5 (Marcus 2026-10-01, "Fix Card ... 5"): this said "the
                      # land holds a larger share here than the multi-model mean
                      # and the ocean a smaller one" -- hilda29l's 1000-yr split
                      # (34 / 48 / 18 %). At hilda33d it is 18 / 60 / 22 against
                      # Joos's 16 / 59 / 25 (z +0.28 / +0.15 / -0.63 in true s.d. since the 10-02 +-2 s.d. fix; scorecard
                      # 2026-10-01): the ocean is now LARGER too, and every term
                      # sits within two-thirds of one s.d. (|z| <= 0.63). The difference is in
                      # the timing, largest early: IRF(20) 0.508 vs 0.596.
                      # ⭐ RE-CHECKED 2026-10-12 at hilda29e on the climate-FREE protocol (ccx_pd100):
                      # 1000-yr split 17.4 / 57.6 / 25.0 % (z +0.20 / -0.23 / -0.01); IRF 20/100/300
                      # 0.522 / 0.379 / 0.295 vs Joos 0.596 / 0.409 / 0.322. Every claim below holds.
                      # 2026-10-15 review: RE-CHECKED at hilda31w (rv_pulse()): 1000-yr split 18.4 / 56.8 / 24.8 %
                      # (z +0.35 / -0.37 / -0.05); IRF 20/100/300 0.514 / 0.374 / 0.293. Every claim below holds.
                      "point. Where the difference sits is visible in the two",
                      "charts: the pulse leaves the air faster here, most of all",
                      "in the first few decades, but after a thousand years the",
                      "split between land, ocean and air is close to the",
                      "multi-model mean on every term."),
       ask = "What is the best comparison for long-term CO₂ decay?"),
  # ⭐ RENUMBERED 2026-10-01 (Marcus: "renumber the cards"). The AIC card (the old
  # card 6) was retired the same day and first left a hole; the app has never been
  # deployed, so no comment can lead with an old number, and the hole was closed:
  # the bands card 7 -> 6, the stand-ins card 8 -> 7. ⛔ FROM DEPLOYMENT ON, ids are
  # stable public references: retire into RV_RETIRED_IDS (a hole, never reused) and
  # never renumber again -- a comment that leads with "card N" must not land on a
  # different question.
  # B7 (Marcus 2026-10-01, "Laplace first, MCMC as the check" -- then "Hold the bands"): the card said there
  # were no bands, and that the Laplace band had FAILED its check. 2026-10-15: the hilda31w MCMC band ships,
  # and this is Marcus's copy for it (drafted on "Draft all four for me to edit"; his one edit deleted the
  # Laplace sentences; notes/band_copy_drafts_2026-10-15.md). Every number below is pinned against its
  # artifact by test-futures-ribbons.R ("issue 6's typed numbers"): change them together.
  list(id = 6, key = "bands", class = "gap",
       title = "The uncertainty band covers only the carbon-cycle parameters",
       plain = paste("Each line in this app is a single best fit. On the Futures tab,",
                     "the CO\u2082 view also shades how much the projection changes",
                     "when the carbon-cycle parameters vary within their plausible",
                     "range. The band leaves out other sources of uncertainty, so",
                     "the full range is likely wider."),
       detail = paste("The band comes from a Markov chain Monte Carlo sampler: four",
                      "chains of 200,000 steps each, from which 17,000 parameter sets",
                      "were run through the full model. It varies the 31 fitted",
                      "carbon-cycle parameters. Fourteen other parameters are held at",
                      "fixed values, and the climate response (fitted to FaIR), the",
                      "non-CO\u2082 forcing and the model's structure are not varied.",
                      "Temperature therefore changes only through CO\u2082, by less than",
                      "0.1 \u00b0C, and no band is drawn for it.",
                      "The sampler has not fully converged. Three parameters that set",
                      "how far plant growth and respiration lag behind the seasons can",
                      "compensate for one another, and one chain sampled a different",
                      "combination of them for part of its run. This has less effect",
                      "on the projections: bands computed from each chain separately",
                      "agree to within about 5 ppm, at most about a fifth of the",
                      "band's width.",
                      "The depth of the ocean's mixed layer is cut off at about 75 m",
                      "by a limit in the model's time-stepping, so its sampled range",
                      "may be narrower than the data allow."),
       ask = paste("Does a band that covers only the carbon-cycle parameters help",
                   "you read the projections, or would you want the climate response",
                   "included before relying on it?")),
  list(id = 7, key = "shims", class = "design",
       title = "Some parameters stand in for mechanisms, and some constants are unsourced",
       # 2026-10-15 review (Marcus: "Apply all"): three of the seven stand-ins are HELD at 0 at hilda31w, so
       # "fitted parameters" -> "parameters" here and "is fitted freely and" is cut from the detail; and
       # "inverted through the model" -> plain words. ("slightly", below, is Marcus's call and untouched.)
       plain = paste("Several parameters are stand-ins: they absorb a",
                     "discrepancy rather than represent a process. Several",
                     "physical constants are still marked provisional — their",
                     "values were inferred by fitting the model or simply held, rather than",
                     "traced to a measurement."),
       # N11 + N12 (Marcus 2026-09-22): the "most that naming buys" clause is
       # cut, and the bigger fix -- the prose named the SHIMS while the table
       # below listed the PINS, and the card presented them as one list. They
       # are two different things; both are now shown, labeled, with the
       # overlap COMPUTED rather than described (rv_stand_ins()).
       # Marcus 2026-10-02 (carbotopecomment): "rather than quietly absorbed" and "and it is
       # worth keeping them apart" deleted; "parameter", not "name".
       detail = paste("Each is named in the code and listed below. The two lists below",
                      "are different things. A stand-in",
                      "absorbs a discrepancy instead of representing a",
                      "process; a held parameter is one the calibration is not",
                      "allowed to move at all, carried at a stated number. Some",
                      "parameters are in both — a stand-in that was switched off by",
                      "holding it at zero. The stand-ins that matter most for what",
                      "this app claims are the station offset (issue 1), the",
                      "δ¹³C gradient offset (issue 2 is scored net of it), and a",
                      "seasonal sea-surface-temperature amplitude fitted well",
                      "under the observed one.",
                      # 2026-10-06 (Marcus: "Add a line about k_w to the known issues tab"): wording
                      # DRAFTED for his review. The record: the k_w = 1446 price arm (CHANGELOG 10-05 a)
                      # fits 2.75 BETTER on likelihood; its -20 posterior price is ONE prior,
                      # hs_asx_frac's judgment width (kept, 10-05 e). test-review-card-numbers.R ties
                      # "1,446" to KW_PRIOR_CENTRE and "about 1,850" to the canonical's fitted k_w.
                      # 2026-10-13 (g): "about 1,900" -> "about 1,850" (Marcus: "about 1,850"): hilda31w's k_w is
                      # 1835.4 (sd 52.5); 1,900 was 1.23 sd off. The next sentence's claim (the data prefer 1,446)
                      # was MEASURED at hilda34g (10-05 a; earlier notes said hilda33p, wrongly: the read's own record
                      # names hilda34g). RE-MEASURED at hilda31w 2026-10-13 (q), a two-start profile with k_w held at 1446
                      # (outputs/diagnostics/price_profile_20261013_hilda31w/read_k_w_20261013.log): the data prefer 1,446
                      # by +6.21 log-likelihood (+2.75 at hilda34g; atmospheric d14C +7.09), and hs_asx_frac's prior is
                      # -19.92 of the -22.56 prior cost (88 %); posterior price -15.40 (was -20.01). Both claims hold;
                      # whether "slightly" still fits +6.2 is Marcus's wording call.
                      "One fitted value is a compromise between two sources rather",
                      "than a measurement: the air-sea gas transfer speed comes out at",
                      "about 1,840 m per year, against the literature's 1,446 (Naegler",   # Marcus 2026-10-15 ("Apply all the app text suggestions"): 1,840 = the table
                      "2009). The data prefer the literature value; what holds",   # Marcus 2026-10-15 ("Apply all the app text suggestions"): "slightly" cut (+6.21 log-lik)
                      "it higher is the stated prior on how much gas exchange the cold",
                      "high-latitude box gets, and the two cannot both hold."),
       ask = paste("Which of these would you want carried by a real mechanism",
                   "before you would use the model to teach from?")),
  # 2026-10-08 (j) (Marcus: "go ahead with the card"): the ocean's climate effect and H2 are ONE issue (CHANGELOG
  # 10-08 i). ⚠ CLAUDE'S DRAFT, FOR MARCUS'S WORDING -- the numbers are NOT typed here: they are printed live under
  # the two charts from data/ocean_climate_card.rds. The two qualitative claims ("about twice", "decades earlier")
  # are tied to that product by test-ocean-climate-card.R.
  # (2026-10-15 review: Marcus's 10-15 plain no longer says "decades earlier"; test-ocean-climate-card.R holds that
  # phrase only where the text makes it, so "about twice" is the one claim the card's prose still carries.)
  list(id = 8, key = "ocean_climate", class = "response",
       # Marcus 2026-10-15: title, plain's second sentence and the detail's first sentence are his. "about" is
       # kept in the title: the per-K ratio is 1.8 +/- 0.4 at hilda31w, and test-ocean-climate-card.R ties it.
       title = "Ocean CO\u2082 uptake declines with warming about twice as fast in CarboTope as in ocean models",
       plain = paste("Warmer seawater holds less CO\u2082, so as the sea surface warms the ocean",
                     "takes up less. In this model that decline happens about twice as quickly",
                     "as in the Global Carbon Budget models."),
       detail = paste("CarboTope was not tuned to this mechanism. The seawater",
                      "chemistry is not the cause \u2014 how fast CO\u2082 pressure rises with",
                      # Marcus 2026-10-15: "tested but not settled," deleted; the mixing sentence and the
                      # second-chart sentence are his ("in 2300" moved to the clause that names the year).
                      # "carbon-rich" -> "has not adjusted to the warming": CLAUDE'S DRAFT answering his question
                      # (H2 is that strong mixing defeats the surface's DIC adjustment, not deep-water richness).
                      "temperature here matches the measured value. Our leading explanation",
                      "is that this model's ocean mixes vertically so strongly that the",
                      "surface keeps being refilled with water from below that has not",
                      "adjusted to the warming, where real surface water would adjust and",
                      "partly offset it. Mixing less would help this issue at the cost of",
                      "matching radiocarbon and total carbon uptake. The model also has no wind",
                      "effect, which in at least one ocean model is the largest part of the",
                      "climate effect. The second chart shows the implications of the",
                      "discrepancy between CarboTope ocean uptake and Global Carbon Budget",
                      "uptake: how much lower CO\u2082 would be in 2300 if this ocean responded",
                      "like the ocean models."),
       ask = paste("Is an ocean that over-reacts to warming acceptable for teaching how",
                   "climate change weakens the carbon sinks, or should it be fixed before",
                   "the model is used to talk about the future?"))
)
# Retired ids, never to be reused. EMPTY since the 2026-10-01 renumbering (pre-deployment);
# the mechanism is for after deployment, and test-review-cards.R keeps its power on an
# injected retirement.
RV_RETIRED_IDS <- integer(0)

# N2 (Marcus 2026-09-22): the "measured by the running model" sentence is cut
# from the lead. It is true and it is why this tab cannot go stale, but it is
# inside baseball for a reader. The DESIGN is unchanged -- every number below is
# still computed by a run this app makes.
# ⚠ THE COUNT IS THE LEDGER'S. It was the literal "Eight", which retiring card 6
# (2026-10-01) would have left false; now it cannot drift from RV_CARDS.
RV_COUNT_WORDS <- c("One", "Two", "Three", "Four", "Five", "Six", "Seven",
                    "Eight", "Nine", "Ten", "Eleven", "Twelve")
RV_TAB_LEAD   <- paste(RV_COUNT_WORDS[length(RV_CARDS)],
                       "things this model gets wrong, or does not do, or",
                       "does on purpose in a way you might disagree with. For",
                       "each, I want to know the same thing:")

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
  # a retired id is a hole, never a slot (2026-10-01)
  reused <- intersect(ids[!is.na(ids)], RV_RETIRED_IDS)
  if (length(reused))
    bad <- c(bad, sprintf("retired card id(s) reused: %s", paste(reused, collapse = ", ")))
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
