# =====================================================================
# calibrate.R — priors, posterior, and the MCMC driver.
#
# Parameters are sampled on a TRANSFORMED scale (log for positive scale
# parameters, logit for bounded ones) so the proposal can be an unconstrained
# Gaussian and adaptive Metropolis never has to reject for being out of bounds.
# The prior densities below are stated on the NATURAL scale, and the Jacobian of
# the transform is added explicitly -- omitting it silently reshapes every prior.
# =====================================================================

# ---- parameter table -------------------------------------------------
# transform: "log" (positive), "logit" (bounded by lo/hi), "id" (unbounded)
#' Lognormal prior whose +/- 1 sigma spans a measured [LO, HI] bracket.
#'
#' The width is then the MEASURED ambiguity rather than a chosen number. Used
#' for seas_T_amp_*, where what the model wants is respiration-weighted and what
#' can be measured is area-weighted, and the gap is boundable but not knowable.
ccx_bracket_lnorm <- function(x, stem) {
  lo <- ccx_const(paste0(stem, "_LO")); hi <- ccx_const(paste0(stem, "_HI"))
  stats::dlnorm(x, log(sqrt(lo * hi)), log(hi / lo) / 2, log = TRUE)
}

# PRIOR WIDTH on sst_seas_amp_*, log space (~ +/- 28 %). A JUDGEMENT, not a
# measurement, and labelled as one: it stands in for the gap between the
# area-weighted hemispheric mean ERSSTv5 gives and the gas-exchange-weighted
# mean the parameter actually is. Nothing measures that gap today; the land pair
# gets a DERIVED width instead because its bracket IS measured. Replacing this
# with a flux-weighted estimate is a real improvement someone could make.
SST_SEAS_LOGSD <- 0.25

# PRIOR WIDTH on npp_frac_NH, on the natural (share) scale. A JUDGEMENT, and
# labelled as one for the same reason SST_SEAS_LOGSD is: MOD17's interannual sd
# of 0.0135 measures one product's spread about its own mean, not the
# product-to-product ambiguity that actually bounds the NH share. See the
# npp_frac_NH entry below.
NPP_FRAC_NH_SD <- 0.04

# PRIOR WIDTH on ent_seas_amp_SH, log space. ⭐ DERIVED FROM A PHYSICAL
# CEILING, NOT FROM THE RECORDED BAND -- re-derived 2026-09-03 during a
# provenance audit of this arc's own numbers.
#
# ⛔ WHAT IT IS NOT, AND WHY THAT MATTERS. The first version read the recorded
# plausibility band -- "a fitted value far outside ~5-30 is the channel being
# used as a fudge factor" -- as a 2 sigma statement and took log(30/5)/4 = 0.45.
# That rests on the number **5**, WHICH HAS NO DERIVATION ANYWHERE. A width
# resting on an unsourced endpoint is a chosen number wearing a measurement's
# clothes. [[threshold_from_obs_or_law]]
#
# ⭐ WHAT IT IS. The parameter is the IN-BAND anomaly DILUTED onto the SH box by
# the 40-90 S ocean-area fraction. So there is a hard geometric ceiling: the box
# mean cannot exceed the in-band amplitude, and it reaches it only if EVERY SH
# ocean square metre behaves like the observed 40-90 S band. That no-dilution
# limit sits at exactly log(1 / ENT_SEAS_BAND_AREA_FRAC) = 0.99696 above the
# centre, and reading THAT ceiling as 2 sigma gives
#
#     ENT_SEAS_LOGSD = log(1 / ENT_SEAS_BAND_AREA_FRAC) / 2 = 0.49848
#
# -- one named, registered quantity, no unsourced endpoint. ⚠ The "2 sigma"
# remains a CONVENTION (the project's shared strictness), and is labelled one.
#
# ✅ AND IT CORROBORATES THE RECORDED BAND RATHER THAN DISCARDING IT: under this
# width the band's own endpoints land at z -1.57 (5) and +2.02 (30). The 30
# lands at 2 sigma BY CONSTRUCTION -- it IS the in-band value -- and the 5
# falling near -1.6 is the independent check that the two readings agree.
#
# ⚠ MARCUS APPROVED 0.45 ON 2026-09-03, BEFORE THIS AUDIT. The change is
# 0.45 -> 0.49848 and it is a PROVENANCE repair, not a retuning: the band both
# readings encode is the same to within a fifth of a sigma. Flagged, not slipped in.
# ⚠ Typed literally because CCX_PARAM_TABLE is built before ccx_const() exists;
# test-ent-seas-fitted.R ties it to log(1/ENT_SEAS_BAND_AREA_FRAC)/2.
ENT_SEAS_LOGSD <- 0.49848

#' The literature prior on the HS pump's export (data-raw/build_hs_export_prior.R),
#' read lazily and cached: the table above is built before R/paths.R is sourced.
ccx_hs_export_prior <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) cache <<- readRDS(ccx_path("data", "obs_hs_export_prior.rds"))
    cache
  }
})

#' The OBSERVATION prior on the low-latitude pump's PRESCRIBED export (option
#' D + E, 2026-09-14 h; ruling E4): Nowicki et al. 2022's ensemble, integrated
#' over the model's LS band by data-raw/build_pump_export_prior.R. Same idiom.
ccx_pump_export_prior <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) cache <<- readRDS(ccx_path("data", "obs_pump_export_prior.rds"))
    cache
  }
})

#' The LITERATURE prior on the ventilation loop's volume flux (option E; the
#' prereg's owed source, discharged 2026-09-14 h): the global annual subduction
#' rate into the permanent pycnocline outside the equatorial band, two readings
#' a factor 3 apart (climatological ~160 Sv vs SODA 506 Sv), each at 1 sigma.
#' data-raw/build_w_vent_prior.R. Same idiom.
ccx_w_vent_prior <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) cache <<- readRDS(ccx_path("data", "obs_w_vent_prior.rds"))
    cache
  }
})

#' The OBSERVATION priors on the cold box's flush and the mixed-layer thickness
#' (2026-09-08d, Marcus: "free u_hs"; "either free h_ml or ..."), the same lazy
#' idiom: data-raw/build_u_hs_prior.R and data-raw/build_h_ml_prior.R.
ccx_u_hs_prior <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) cache <<- readRDS(ccx_path("data", "obs_u_hs_prior.rds"))
    cache
  }
})
ccx_hs_asx_prior <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) cache <<- readRDS(ccx_path("data", "obs_hs_asx_prior.rds"))
    cache
  }
})
#' The SHAPE prior on fert_k (2026-09-28, Marcus): lognormal, median 545.7 ppm (the
#' geometric mean of Walker 2021's canopy-physiology K 511 and Varney 2024's CMIP6-NPP
#' K 583), log-sd 0.35 (a RULING). data-raw/build_fert_k_prior.R; the same lazy idiom as
#' ccx_h_ml_prior(). LIVE ONLY where p$fert_k_prior == 1, i.e. under the structure label
#' "hilda_csl3v0k"; everywhere else fert_k keeps its flat prior, bit-exact.
ccx_fert_k_prior <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) cache <<- readRDS(ccx_path("data", "prior_fert_k.rds"))
    cache
  }
})
ccx_h_ml_prior <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) cache <<- readRDS(ccx_path("data", "obs_h_ml_prior.rds"))
    cache
  }
})
#' The OBSERVATION prior on h_hs (2026-09-16 d): the Holte HS mixed layer's
#' annual MEAN (115 m) and MAX (268 m) as the 16 / 84 % points of a lognormal
#' -- the original h_ml construction, because the HS box's own seasonal cycle
#' (option B) is off at the canonical, so the mean-vs-max ambiguity stands.
#' data-raw/build_h_hs_prior.R; the same lazy idiom as ccx_h_ml_prior().
ccx_h_hs_prior <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) cache <<- readRDS(ccx_path("data", "obs_h_hs_prior.rds"))
    cache
  }
})
#' The value the HILDA structure DECLARED for u_hs before it was fitted (HILDA
#' Table 1, K(z) version: 38 +/- 17 m/yr) -- what every ancestor RAN, so it is
#' what ccx_migrate_par_set() fills; the fitted search starts there too.
CCX_U_HS_DECLARED <- 38

# h_ml's box floor (2026-09-16 b, Marcus): the Holte prior's 16 % point --
# ccx_h_ml_prior()$q[2] = 42.52 m (exp(log 59.69 - 0.341) = 42.44) -- to 0.1 m.
# Read by CCX_PARAM_TABLE$h_ml below; test-hml-floor.R holds it to the prior.
CCX_HML_FLOOR_M <- 42.5
CCX_PARAM_TABLE <- list(
  # ---- CO2 fertilisation ---------------------------------------------
  # `beta` LEFT THE TABLE on 2026-08-14 when fert_form flipped to CCX_FERT_MM.
  # It is not merely renamed: MM is NOT a reparameterisation of the log form (as
  # fert_k -> Inf, MM goes LINEAR, not logarithmic), so no substitution carries
  # a beta posterior across. Any beta posterior in calibration/output/ is a
  # posterior for a DIFFERENT MODEL and must not be spliced into a new chain.
  # The entry is reproducible from git if the log form is ever refitted:
  #   beta = list(tr = "logit", lo = 0, hi = 1.5, init = 0.75,
  #               prior = function(x) dunif(x, 0, 1.5, log = TRUE))
  #
  # BOTH PRIORS ARE DELIBERATELY WIDE AND UNINFORMATIVE, for the same reason the
  # beta prior was: nothing in the literature set pins either quantity at the
  # ECOSYSTEM scale (leaf-level Rubisco kinetics do not transfer, and FACE
  # experiments and CMIP6 models disagree by more than any prior width would
  # encode). The data in the objective are what should set them, and the four
  # DESIGN gates are what should audit the answer -- NOT a prior standing in for
  # evidence nobody has cited. If a sourced ecosystem-scale constraint on either
  # is ever found, it belongs here with its citation.
  #
  # beta_max: asymptotic fractional NPP enhancement. Upper bound 3.0 is a hard
  # implausibility bound (NPP quadrupling at infinite CO2), not a belief; the
  # init is ccx_default_params()$beta_max.
  beta_max    = list(tr = "logit", lo = 0.0,  hi = 3.0,  init = 0.4913,
                     prior = function(x) dunif(x, 0, 3.0, log = TRUE)),
  # fert_k: ppm above preindustrial delivering half of beta_max. LOGIT on
  # [20, 2000], not log: the upper end is where MM has gone effectively linear
  # over the whole observed range and the form degenerates into the log form's
  # problem, so it is a real boundary rather than a scale. The lower end keeps
  # the pole (chi = chi0 - fert_k) far below any reachable CO2.
  fert_k      = list(tr = "logit", lo = 20,   hi = 2000, init = 120,
                     # FLAT unless the arm's structure switches the SHAPE prior on
                     # (p$fert_k_prior == 1, label "hilda_csl3v0k", 2026-09-28). The box
                     # stays [20, 2000] either way; the lognormal lives inside it.
                     prior = function(x, p = NULL) {
                       if (!is.null(p) && isTRUE(p$fert_k_prior == 1)) {
                         pr <- ccx_fert_k_prior()
                         dlnorm(x, log(pr$median_ppm), pr$log_sd, log = TRUE)
                       } else dunif(x, 20, 2000, log = TRUE) }),
  q10         = list(tr = "log",   init = 2.0,
                     prior = function(x) dlnorm(x, log(2.0), 0.25, log = TRUE)),
  # k_w: CITED 2026-10-02 (W5; objective #15; Marcus: "1446, log-sd 0.2"). Was lognormal(1500,
  # 0.4), "Wanninkhof global mean", uncited from 08-09. Naegler (2009)'s corrected four-study mean,
  # 16.5 cm/h -- R/constants.R KW_PRIOR_CENTRE / KW_PRIOR_LOGSD carry the sources and the ice /
  # water-vapour caveats. `init` is a LITERAL (the pump_grad idiom: this table is built before
  # R/constants.R is sourced); test-enso-lag.R ties it to the constant.
  k_w         = list(tr = "log",   init = 1446,
                     prior = function(x) dlnorm(x, log(ccx_const("KW_PRIOR_CENTRE")),
                                                ccx_const("KW_PRIOR_LOGSD"), log = TRUE)),
  # h_ml: OBSERVATION PRIOR since 2026-09-08d (Marcus). The box [30, 200] stays;
  # the flat density inside it is replaced by a lognormal whose 16 % / 84 %
  # points WERE the two defensible readings of the Holte 2017 Argo climatology
  # for a time-constant thickness -- the LS annual MEAN (59.7 m) and the LS
  # annual MAXIMUM (118 m) -- median 83.9, log-sd 0.341, both COMPUTED from
  # data/obs_mld.rds by data-raw/build_h_ml_prior.R and read lazily through
  # ccx_h_ml_prior(). The prior ENCODED the mean-vs-max ambiguity a seasonal
  # mixed layer would resolve (notes/options_2026-09-08d_seasonal_h_ml.md).
  #
  # ⭐⭐ RE-CENTRED ON THE ANNUAL MEAN 59.7 m, 2026-09-09w (ruled by Marcus).
  # Round 6 BUILT that seasonal mixed layer, so the ambiguity is DISCHARGED and
  # the constant is the annual MEAN; keeping the geometric-mean centre would be
  # a prior compensating for a mechanism the model now has. It was also costing
  # starts: P8 stops at 76.146 m and 61.3 % of the old prior lay past it, ITS
  # MEDIAN 83.94 INCLUDED, so ~3 starts in 5 died at the guard. Now 23.8 %.
  # ⚠ The WIDTH is deliberately UNCHANGED and is a FLAGGED CHOICE, not a
  # derivation -- it still spans an ambiguity that no longer exists. See the
  # header of data-raw/build_h_ml_prior.R.
  # ⚠ Every stored logpost moves with this change; compare on LIKELIHOOD.
  # MEASURED at the canonical mode: log-prior -39.2347 -> -40.0457 (-0.8110)
  # with BOTH 09-09w prior moves; the likelihood is untouched at -1439.4248.
  # h_ml's own z goes -1.577 -> -0.57; ent_seas_amp_SH's +1.310 -> +2.34.
  #
  # ⭐ THE BOX FLOOR IS THE PRIOR'S 16 % POINT, 42.5 m, SINCE 2026-09-16 (b)
  # (ruled by Marcus; was 30). The E array (09-15) and the O5 arm-C probes
  # (09-15 g) bought their rows with h_ml on the 30-m floor -- the prior's
  # ~3rd percentile, a mixed layer no Holte reading supports -- and the floor
  # measured 09-16 showed O5 keeps 93 % of its gain at 42.5 m. CCX_HML_FLOOR_M
  # below is that point; test-hml-floor.R asserts it against ccx_h_ml_prior()
  # so the two cannot drift apart. ⚠ A LOGIT BAND CHANGE MOVES EVERY STORED
  # LOGPOST by the Jacobian difference (canonical -0.362, hilda31s2 -0.368,
  # hilda31p -2.105 -- it sits 1.6 m above the new floor); the LIKELIHOOD is
  # untouched. ccx_mode_start() carries the difference in `logpost_shift` when a
  # file's recorded `hml_bound` differs from the live table, so every gate-4
  # reproduction still closes without restamping the files. Compare on
  # likelihood, as always. The array driver takes its band from THIS table
  # (run_dispersed_multistart.R `.ship`), so port_targets.csv must be
  # regenerated with it (calibration/make_port_targets.R).
  h_ml        = list(tr = "logit", lo = CCX_HML_FLOOR_M,  hi = 200,   init = 75,
                     prior = function(x) { pr <- ccx_h_ml_prior()
                       dlnorm(x, log(pr$centre_m), pr$log_sd, log = TRUE) }),
  # OCEAN VENTILATION, BOUNDED (2026-08-12, Marcus). kz was log-transformed with
  # a lognormal prior and no bound; the 17-parameter mode ran it to 10,686, which
  # puts the deep ocean at -129.9 permil against an observed -150 to -200. One
  # diffusivity has to serve both the decadal bomb-14C penetration and the
  # millennial deep age, and unbounded the bomb window wins.
  #
  # The deep age is the more teachable quantity ("the deep ocean has not seen the
  # surface for centuries"), so kz is bounded to the range that keeps it inside the
  # observed bracket and the bomb window absorbs the cost. MEASURED, not assumed:
  # the kz -> deep-D14C relation is essentially univariate -- h_ml moves it under
  # 1.5 permil across h_ml 39.7-100 -- so a bound on kz alone is sufficient.
  # Bisected at the default parameters:
  #   kz 3828.8 -> -200.00 permil  |  kz 5000 -> -170.1  |  kz 6200.7 -> -150.00
  # Bounds rounded INWARD to [3830, 6200], which lands at -199.96 / -150.01, i.e.
  # inside the bracket at both ends. init 5000 (bracket centre is 5015).
  # Deliberately NOT a point value: kz also drives ocean CO2 uptake, and pinning it
  # would push all of that onto k_w and h_ml. Re-bisect if OCEAN_DEPTH, the grid,
  # or the observed bracket changes -- these are measured numbers, not settings.
  #
  # RETAINED 2026-08-14, DELIBERATELY, alongside the new `d14c_deep_ocean`
  # likelihood term. 13i sec.A3 planned to delete this bracket once GLODAPv2
  # supplied a sourced sigma; the measurement INVERTED that plan. Expressed on
  # the bottom box -- the layer the term actually scores -- this bracket is a
  # hard box of half-width 28.4 permil, tighter than every sigma candidate but
  # the most aggressive, so deleting it would LOOSEN kz rather than tighten it.
  # Marcus re-took the decision on those numbers: keep the bracket, add the term
  # at n_eff = 20. Delete it only after a refit shows the term holding kz alone.
  #
  # TWO CAVEATS ON THE BISECTION ABOVE. It was done on `d14c_deep_ocean` = the
  # bottom THREE boxes (1313.6-3700 m), and the "-150 to -200" bracket it was
  # bisected against was an uncited recollection. GLODAPv2 has since confirmed
  # the recollection (2627-3700 m: -175.3, within 0.3 of that bracket's
  # midpoint) but on the BOTTOM BOX, where these same bounds give -220.4 to
  # -163.5. So the bracket is centred 16.7 permil BELOW the sourced target and
  # the new term pushes kz up inside it (own optimum 5525). Both facts are live;
  # neither is a reason to move the bounds by hand ahead of the refit.
  #
  # ---- RE-BISECTED 2026-08-16e FOR THE PUMP (Marcus). [3830, 6200] -> below.
  # NOT a hand adjustment: the SAME recipe, re-run on the model that now ships.
  # calibration/diag_kz_bracket_pump.R, ~3 min. The bounds above were bisected on
  # a model with NO PUMP, and the pump moves the very row they were bisected on
  # (DESIGN sec.5.2h: it makes deep water older at every `kz`). It also BINDS --
  # sec.5.2h P2 measured `kz` pinning to the bracket's TOP with the pump both off
  # and on -- so a stale top is not a loose guard rail, it IS the refit's answer.
  #
  #   THE PUMP-OFF ARM IS THE CONTROL AND IT PASSES: re-bisecting at
  #   `pump_grad` = 0 returns 3828.7 / 6200.8 against the shipped 3830 / 6200,
  #   i.e. 1.3 and 0.8 m2/yr. The recipe is faithful; what moves is the pump.
  #
  #   PUMP ON: 3942.5 / 6528.0. The top moves +328 m2/yr (+5.3 %), in the
  #   direction sec.5.2h predicted -- older deep water needs MORE mixing to reach
  #   the same D14C, so the pump BUYS `kz` headroom rather than costing it.
  #
  #   ARM-INDEPENDENT, and that is a check rather than luck: `pump_mode` "N" and
  #   "D" give the IDENTICAL bracket, because at the preindustrial steady state
  #   D's scale factor y[iml,"C"]/ml_C0 is 1 by construction. The two arms can
  #   differ only in the TRANSIENT, so this bracket cannot bias the N-vs-D
  #   comparison either way.
  #
  #   ON THE BOTTOM BOX -- the layer `d14c_deep_ocean` actually scores -- the new
  #   bracket is -219.8 / -162.8 against the old -220.4 / -163.5. Nearly a no-op
  #   on the scored quantity, which is what makes this a low-risk correction: it
  #   moves WHICH `kz` delivers the observed deep age, not the deep age.
  #
  # Bounds NOT rounded inward this time -- the bisection tolerance is 0.5 m2/yr
  # and rounding would be smaller than the number's own meaning. init = the
  # bracket centre, as before (was 5000 for a centre of 5015).
  #
  # ---- RE-BISECTED WIDE 2026-09-01 (Marcus). [3942.5, 6528] -> below.
  # ⛔ THE DEFECT THIS FIXES IS THE TARGET, NOT THE RECIPE. Everything above
  # bisected an observational recipe against an UNCITED RECOLLECTION,
  # "[-200, -150] permil", and did it on the bottom THREE boxes -- while the
  # `d14c_deep_ocean` likelihood term added 2026-08-14 scores the BOTTOM BOX
  # against GLODAPv2's sourced -175.26 +/- 10.259 permil (n_eff 20, layer
  # 2627.2-3700 m, [[ccx_glodap_deep]]). Expressed on the layer that is actually
  # scored, the old bracket was z in [-4.34, +1.22]: a box 5.55 sigma WIDE,
  # centred 1.56 sigma BELOW the target, and TRUNCATING it at the top. That top
  # is where every constrained row of the land axis railed, so the -285/-298
  # price of gate 7 was being set by the recollection rather than by the data.
  #
  # THE SAME RECIPE, RUN AGAINST THE SOURCED TARGET at k = 3 sigma, at the
  # DEFAULT parameters exactly as every earlier bisection was:
  #   calibration/diag_kz_bracket_on_the_sourced_target.R PART 2 (2026-08-31c,
  #   re-run and reproduced 2026-09-01).
  #     k = 1 sigma  [5211.9, 6373.9]
  #     k = 2 sigma  [4763.5, 7146.6]
  #     k = 3 sigma  [4379.1, 8109.9]   <- SHIPPED
  # k = 3 is the ruling: a 3-sigma box on a sourced observation, so the support
  # is the observation's own, and a turnover inside it is a turnover inside every
  # narrower one. ⚠ The FLOOR RISES as well as the ceiling (3942.5 -> 4379.1) --
  # this is a RE-CENTRING on the sourced target, not only a widening. Every mode
  # file on disk stays strictly interior (kz 6169-6400).
  #
  # ⭐ AND IT IS NOT THE BRACKET THAT WAS HOLDING `kz`: on this support the
  # anchor row turns over INTERIOR at 6486.1 = 56 % of the box, with
  # `fert_k`/`q10` re-optimised (PART 3). The exit condition R/calibrate.R states
  # above -- "delete it only after a refit shows the term holding kz alone" -- is
  # therefore CLOSER but still not met by a refit; the bracket stays.
  #
  # ⚠ THE UNIVARIATE JUSTIFICATION WAS RE-MEASURED BEFORE THIS SHIPPED, because
  # the sentence it rests on ("h_ml moves it under 1.5 permil across h_ml
  # 39.7-100") was measured over a window that NO LONGER CONTAINS the better
  # basin's h_ml = 143.9 m. calibration/diag_kz_bracket_hml_sensitivity.R:
  # inside the original window the claim REPRODUCES (0.99 permil); across the
  # whole live band [35, 195] the D14C at fixed `kz` moves 6.25 permil = 0.61
  # sigma = 10.2 % of the 3-sigma box, and the bracket ends move -87 / -165
  # m2/yr between the default h_ml and 143.9. An order of magnitude below the
  # box, so a bound on `kz` alone remains sufficient AT THIS WIDTH -- it would
  # not obviously remain so at k = 1.
  #
  # init = the bracket centre, as before.
  # ---- RE-BISECTED 2026-09-06d ON THE 36-BOX STRUCTURE (Marcus's ruling,
  # prereg_2026-09-07 sec.4). [4379.1, 8109.9] -> below. The column bracket
  # above was bisected where `kz` ALONE set the bottom box; with HILDA's HS/HD
  # boxes and K(z) ON, the bottom box is set by K_deep = kz_deep_frac * kz and
  # the conduit, so the same recipe (default parameters, pump ON at the
  # observed gradient, mode N, the SOURCED GLODAP bottom-box target, k = 3
  # sigma) run with the structure DECLARED at its refit values and the two
  # fitted structure parameters at their table inits gives a box 24x wide:
  #   calibration/diag_kz_bracket_hilda36.R (2026-09-06d):
  #     k = 1 sigma  [3774.7, 11519.4]
  #     k = 2 sigma  [2094.4, 18461.3]
  #     k = 3 sigma  [1161.6, 27808.0]   <- SHIPPED
  # ⚠ A bracket on `kz` AT FIXED f: in the refit f is free and the deep row
  # pins the PRODUCT, so this is a SUPPORT (the role the bracket always had),
  # not an identification. Prediction R6 -- `kz` lands INTERIOR -- is the test.
  # init = the GEOMETRIC centre, sqrt(1161.6 * 27808.0) = 5683.5, because the
  # arithmetic centre (14485) of a 24x box is 2.3x the working arm's 6356 and
  # would start the cold control with the deep far too young.
  # ⛔ THE PRIOR READS THE TABLE'S OWN BOX (2026-10-12, code review sec.5). It was the literal
  # dunif(x, 1161.6, 27808.0): ccx_adopt_mode_band() moves `lo`/`hi` to a mode file's recorded
  # `kz_bracket` and could not move a literal, so a file fitted under a WIDER bracket would decode
  # kz outside the literal box and score a prior of -Inf. Dormant: every registered mode records
  # exactly this box (checked 2026-10-12), so the value is unchanged everywhere.
  kz          = list(tr = "logit", lo = 1161.6, hi = 27808.0, init = 5683.5,
                     prior = function(x) dunif(x, CCX_PARAM_TABLE[["kz"]]$lo,
                                           CCX_PARAM_TABLE[["kz"]]$hi, log = TRUE)),
  # ---- THE FITTED STRUCTURE PARAMETERS (2026-09-06d; 26 -> 28; h_hs 09-07;
  # u_hs 09-08d) ----------
  # Marcus's ruling on prereg_2026-09-07 sec.3-4: HILDA's attachment, z_K,
  # tau_q, hs_frac and sst_hs are DECLARED (ccx_apply_structure() below); the
  # deep floor f is FITTED with no prior beyond its box (dunif, as beta_max /
  # kz); the cold box's exchange-area factor got its OBSERVATION prior 09-08e;
  # h_hs joined 09-07 and the flush u_hs 09-08d (with an observation prior, below).
  # ⚠ The design said "log scale, box"; this table has no log-spaced box, so
  # both are `logit` on the box with a uniform prior on the NATURAL scale. The
  # logit Jacobian pulls toward the box centre by ~1.7 log-units between
  # f = 0.05 and 0.5 -- the same convention h_ml and kz carry, and an order
  # of magnitude below the rows that pin f (the deep row + the profile
  # contrast). Stated, not hidden.
  # kz_deep_frac: K_deep / kz. 1 = the uniform column (bit-exact, the shipped
  # default) and it is the box's UPPER BOUND, so a migrated ancestor (which
  # ran at 1) cannot be ENCODED and is seeded at init by ccx_seed_unencodable()
  # -- the ent_seas_amp_SH precedent. init 0.05 = the 09-06c working arm
  # (f 0.049, K_deep 309; HILDA's own K0 465 / 6356 = 0.073).
  kz_deep_frac = list(tr = "logit", lo = 0.005, hi = 1.0, init = 0.05,
                      prior = function(x) dunif(x, 0.005, 1.0, log = TRUE)),
  # hs_asx_frac: the HS air-sea exchange AREA factor. 1 = HILDA's assumption
  # (the shipped default) and it is INTERIOR, so ancestors encode. The
  # observation-and-law value is 0.653 (data/obs_hs_exchange_factor.rds) and
  # is deliberately NOT the prior: it is the out-of-sample cross-check
  # (prereg sec.4, ruled 2026-09-06: cross-check only).
  # FLOOR LOWERED 0.2 -> 0.02 on 2026-09-07 (Marcus): the first refit sat at
  # 0.220, effectively AT the floor, so the box was choosing the answer. If
  # the fit now drives it toward zero, that is a "the cold box wants no
  # air-sea exchange" signal to read, not a fit to adopt.
  # hs_asx_frac: OBSERVATION PRIOR since 2026-09-08e (round 5). Round 4 freed
  # u_hs and the fit rebuilt the modern sink HERE, 0.82 -> 1.83 (2.8x the value
  # measured from ice x wind x Schmidt, 0.653, data/obs_hs_exchange_factor.rds)
  # -- the factor had a box and no prior, so it was the free compensator. Now
  # lognormal on the measured 0.653, log-sd 0.15 (a JUDGEMENT, ~2.5x the
  # measured component spread; the hemispheric split 0.32/0.78 is a
  # representation error, not carried), read lazily through ccx_hs_asx_prior().
  # Box unchanged. 1.83 sits at z +6.9; round 3's 0.82 at +1.5.
  hs_asx_frac  = list(tr = "logit", lo = 0.02, hi = 2.0, init = 1.0,
                      prior = function(x) { pr <- ccx_hs_asx_prior()
                        dlnorm(x, log(pr$centre), pr$log_sd, log = TRUE) }),
  # h_hs: the cold box's thickness, FITTED since 2026-09-07 (28 -> 29). It was
  # declared to FOLLOW h_ml (choice C2), which coupled the HS bomb capacity to
  # the low-latitude mixed layer; every basin of the first refit then moved
  # h_ml to an extreme (37-47 or 184-200 m). Box [20, 500] (the 09-06c
  # identifiability run's); init 75 = HILDA's (one remove, the cold control
  # only -- a migrated ancestor starts at ITS OWN h_ml, what it ran).
  # ⭐ OBSERVATION PRIOR since 2026-09-16 (d) (the hygiene batch; the 09-08d /
  # 09-11 (3) ruling "must go under the HS Holte prior", never built until the
  # 09-16 c review named it): lognormal, median 175.4 m, log-sd 0.422 -- the
  # Holte HS annual MEAN 115 m and MAX 268 m as its 16 / 84 % points, COMPUTED
  # by data-raw/build_h_hs_prior.R and read lazily through ccx_h_hs_prior().
  # The canonical's 393 m on 2026-09-16 sat at z +1.91 (it was FLAT-prior free);
  # the canonical hilda31w's 293.5 m sits at z +1.22 (2026-10-15). Re-centre
  # on the MEAN when option B (the HS seasonal cycle) is adopted, as h_ml's
  # was on 09-09w. Every stored logpost moves by this prior's value at its
  # h_hs minus the flat density's; the likelihood is untouched.
  h_hs         = list(tr = "logit", lo = 20, hi = 500, init = 75,
                      prior = function(x) { pr <- ccx_h_hs_prior()
                        dlnorm(x, log(pr$centre_m), pr$log_sd, log = TRUE) }),
  # u_hs: THE COLD BOX'S FLUSH, FITTED since 2026-09-08d (30 -> 31; Marcus:
  # "free u_hs") -- the HS <-> HD exchange velocity in m/yr over the HS area
  # (38 m/yr = a 70 Sv two-way flush). HILDA declared 38 +/- 17 from a 1992
  # fit to 1970s GEOSECS 14C; the 09-08c tests showed the CO2-LEVEL rows, not
  # the deep, hold it there (fixed export: 24 m/yr costs 189, sink 3.03 -> 2.88),
  # while the deep rows alone want the HS export proportional to it. Box
  # [5, 150]: 5 is a flush too slow to ventilate HD on any GEOSECS timescale,
  # 150 is 4x HILDA's. Prior LOGNORMAL on the OBSERVED deep-water formation,
  # NADW + AABW 34-47 Sv (Talley 2013; Lumpkin & Speer 2007 via Cessi 2019)
  # = 18.6-25.7 m/yr over the model's own HS area: median 21.84, log-sd 0.242,
  # COMPUTED by data-raw/build_u_hs_prior.R, read lazily through
  # ccx_u_hs_prior(); the declared 38 sits at z +2.29. The init is a LITERAL
  # tied to the product by tests/testthat/test-u-hs-fitted.R. ⚠ Migrated
  # ancestors carry 38 (what they RAN), which ENCODES, so the search STARTS at
  # 38 and the prior pulls toward 22 -- that contest IS round 4's question.
  # ⚠ THE PRIOR IS ON A VOLUME FLUX (Sv); the parameter is a VELOCITY over the
  # model's HS area (2026-09-16 d, review contradiction 1). The product stores
  # the m/yr centre at the hs_frac it was built with (0.16); under a structure
  # with another hs_frac ("hilda_c", 0.128) the same Sv is hs_frac_built/hs_frac
  # times the velocity -- 21.84 -> 27.3 m/yr. The prior therefore takes the
  # parameter LIST as an optional second argument and converts at the live
  # area; without it (an old caller, ccx_prior_z) it is the product's own.
  # .ccx_prior_eval() dispatches on the arity, so one-argument priors are
  # untouched. Under "hilda" (every registered mode) this is bit-exact.
  u_hs         = list(tr = "logit", lo = 5, hi = 150, init = 21.84,
                      prior = function(x, p = NULL) { pr <- ccx_u_hs_prior()
                        hf <- if (!is.null(p) && is.numeric(p$hs_frac) && is.finite(p$hs_frac) && p$hs_frac > 0) p$hs_frac else pr$hs_frac
                        dlnorm(x, log(pr$centre_m_yr * pr$hs_frac / hf), pr$log_sd, log = TRUE) }),
  # ---- THE EQUATORIAL UPWELLING CELL'S TWO FITTED NAMES (2026-09-13i; 31 -> 33)
  # Fix B proper: mirror cells NH_eq / SH_eq under the "hilda_eq" structure
  # label (prereg notes/prereg_2026-09-13g_equatorial_cell_build.md §1; built
  # 09-13h). ONE parameter set for both cells (ruling 1). Both are BASE
  # parameters with default 0 in ccx_default_params(): absent = 0 = no loop,
  # which is what every ancestor RAN (the cell did not exist), so the
  # migration contract below fills 0 and ccx_seed_unencodable() starts the
  # search at init -- the pump_hs_gcm2 precedent. ⚠ Under "hilda" (eq_frac 0)
  # neither name reaches the model; they are identifiable ONLY under hilda_eq.
  #
  # w_eq: the WHOLE-BAND mean upwelling volume flux, Sv, split between the two
  # cells by area (equal velocity: 27 Sv = 8.52e14 m3/yr over sum(a_eq) 1.477e13
  # m2 = 57.7 m/yr -- the prereg's "63" was an arithmetic slip, caught by the
  # 09-14 review; the CODE never carried it). Box [5, 60]: 5 Sv is a
  # fifth of the observed mean (effectively no cell); 60 Sv is above Johnson et
  # al. 2001's 57 +/- 16, which INCLUDES the 1997-99 event. PRIOR: OBSERVATION,
  # N(27, 3) Sv (ruling 4) -- Meinen, McPhaden & Johnson 2001 JPO 31:3230,
  # 24 +/- 3 Sv over 155-95W and ~30 over 165E-95W across 50 m -- carried in
  # obs_eq_cell.rds$w0_prior (data-raw/build_eq_cell_targets.R) and read
  # lazily; the init is a LITERAL tied to the product by
  # tests/testthat/test-eq-cell.R. B1 (the +55.5 uatm reservoir row, sigma
  # 6.77) scores the SAME parameter from the other side, so the two can
  # disagree (PE8) -- that disagreement is the array's finding, not something
  # to pre-empt with a wider prior. The unrefitted probe (09-13h) read B1 at
  # +144 at 27 Sv; W0 alone would need ~8 Sv (z -6) to reach +55.
  w_eq         = list(tr = "logit", lo = 5, hi = 60, init = 27,
                      prior = function(x) { pr <- ccx_eq_cell_obs()$w0_prior
                        dnorm(x, pr$mean_sv, pr$sd_sv, log = TRUE) }),
  # gamma_eq: the Nino3.4 modulation of the cell's transport, per index unit,
  # W(t) = W x max(0, 1 - gamma_eq x enso) -- the T-A0 floor form (the loop is
  # OFF at enso >= 1/gamma_eq). Box [0, 2] with a FLAT prior (prereg §1): 0 =
  # a mean cell with no interannual signal (the N1 control); 2 = the loop
  # shuts at a +0.5 index, well past the observed 1997-99 bracket of 14-25 Sv
  # per index unit against 24-30 Sv (gamma ~0.5-1.0; PE7 reads [0.4, 1.1]).
  # ⚠ The handoff wrote "id [0, 2]"; an `id` entry has no box in this table,
  # and a hard box under `id` would be a -Inf cliff for Nelder-Mead, so the
  # bounds are carried the way every other boxed name carries them -- logit --
  # and the FLAT prior is the table's dunif-on-the-box idiom (beta_max, the
  # deep floor). The migrated 0 sits ON the box's floor and does not encode;
  # seeded at init 1 (the probe's PE1 point).
  gamma_eq     = list(tr = "logit", lo = 0, hi = 2, init = 1,
                      prior = function(x) dunif(x, 0, 2, log = TRUE)),
  # ---- OPTION D + E (2026-09-14 h; notes/prereg_2026-09-14h_option_e_ventilation.md) ----
  # Three names that reach the model ONLY under pump_field = "martin" (the
  # prescribed-export field), where `pump_grad` is in turn INERT -- the
  # w_eq-under-"hilda" contract, and the array pins the inert side.
  #
  # pump_export: the LS export in GtC/yr (both hemispheres, split by a_ls
  # share), remineralised on the Martin profile below the mixed layer. PRIOR:
  # OBSERVATION (ruling E4, Marcus 09-14 h: "Nowicki if it includes uncertainty
  # bounds") -- Nowicki, DeVries & Siegel 2022's 124-member ensemble, integrated
  # over the model's LS band (|lat| < 57.14) on its own grid: median 9.08, log-sd
  # 0.148 from the sum-of-per-cell-p25/p75 bracket [8.12, 9.92] -- an OUTER
  # bracket of the ensemble's IQR, and ensemble-INTERNAL (the cross-method
  # literature spread 5-13 global is wider; the prior's 2 sigma 6.8-12.1 is
  # where the two meet). data-raw/build_pump_export_prior.R; read lazily. The
  # init REPEATS the product's median (the table is built before ccx_path()
  # exists); test-option-e.R ties the two. Today's SOLVED field (45.5 GtC/yr)
  # sits at z = +10.9 under this prior -- the prior is what breaks the
  # kz / export / W_E degeneracy triangle, and it is meant to.
  pump_export  = list(tr = "log", init = 9.08,
                      prior = function(x) { pr <- ccx_pump_export_prior()
                        dlnorm(x, log(pr$centre_gtc), pr$log_sd, log = TRUE) }),
  # w_vent: the mode-water loop's whole-LS subduction volume flux, Sv, split
  # by a_ls share. PRIOR: LITERATURE (the prereg's owed source, discharged
  # 09-14 h) -- the global annual SUBDUCTION rate from the mixed layer into the
  # permanent pycnocline outside the equatorial band has two defensible
  # readings a factor 3.2 apart: ~160 Sv from the climatologies (Qiu & Huang
  # 1995; Karstensen & Quadfasel 2002) and 505.8 Sv from SODA year-by-year
  # fields (Liu & Huang 2012 J. Climate 25:1096, who attribute the gap to the
  # nonlinearity climatological-mean fields miss). Lognormal, geometric-mean
  # centre 284 Sv, log-sd 0.575 (each reading at 1 sigma) -- the h_ml precedent
  # -- COMPUTED by data-raw/build_w_vent_prior.R and read lazily; the init
  # REPEATS the product's median (test-option-e.R ties the two). WIDE BY
  # DESIGN: the mapping from the real subduction/obduction field to a closed
  # one-column loop is itself uncertain; the data rows (bomb 14C, deep d13C)
  # are meant to set it. Box [0, 1500] (2.5-97.5 % is 92-879). ⚠ Even at the
  # climatological 160 Sv the loop replaces layers 1-3 at 0.07 /yr against the
  # canonical kz's ~3 /yr: the ORDER says kz must fall (PE-1), not that the
  # loop is small. 0 = OFF, on the floor, does not encode -> seeded at init.
  w_vent       = list(tr = "logit", lo = 0, hi = 1500, init = 284,
                      prior = function(x) { pr <- ccx_w_vent_prior()
                        dlnorm(x, log(pr$centre_sv), pr$log_sd, log = TRUE) }),
  # gamma_vent: the loop's Nino3.4 modulation, W(t) = W max(0, 1 - gamma x
  # enso) -- the cell's floor form and the cell's box [0, 2], flat. One limb
  # carries the mean and the modulation (ruling E3), so `gamma_enso_ocn_*`
  # are pinned at 0 in the E array (option A is subsumed).
  gamma_vent   = list(tr = "logit", lo = 0, hi = 2, init = 0.5,
                      prior = function(x) dunif(x, 0, 2, log = TRUE)),
  # w_thc: THE HS-ROUTE DEEP RETURN (option O1 arm THC, 2026-09-15 d) -- the
  # overturning as a mean limb, Sv both hemispheres, split by a_hs. Reaches the
  # model only under pump_field = "martin" WITH the HS boxes. Box [0, 60] and a
  # FLAT prior for the probe; ⚠ PRIOR SOURCE OWED before any array frees it (an
  # observed overturning strength with a bracket, the E4 standard). 0 = OFF, on
  # the floor, does not encode -> seeded at init.
  w_thc        = list(tr = "logit", lo = 0, hi = 60, init = 20,
                      prior = function(x) dunif(x, 0, 60, log = TRUE)),
  # w_enso_l2: THE LAYER-2 NINO3.4 LIMB (review avenue 1, 2026-09-17 k) -- the
  # Nino3.4 modulation of equatorial upwelling in Sv PER INDEX UNIT, whole band,
  # split equally; the limb's floor is w0_l2 = 27 Sv (Meinen, McPhaden & Johnson
  # 2001 through obs_eq_cell.rds$w0_prior), a structure constant. Reaches the
  # model only under a structure with k_l2 > 0 ("hilda_cl2" / "hilda_cl3" and
  # descendants: the canonical hilda31w runs k_l2 = 3 with w_enso_l2 HELD (pinned)
  # at 16.79); INERT (k_l2 = 0) under the structures without the limb, so it is in
  # CCX_PARAM_ABSENT_OK and PINNED in any array without the limb. Box [0, 60] = 2.4x the observed bracket's
  # top (14-25 Sv/index, the 1997-99 swing) and 1.9x the unrefitted need at
  # hilda30h (32.2); FLAT by ruling R3 (the 09-14 b gamma_eq precedent: the
  # bracket is the VERDICT, not the prior). Init = the bracket's geometric centre.
  # 0 = OFF, on the floor, does not encode -> seeded at init.
  w_enso_l2    = list(tr = "logit", lo = 0, hi = 60, init = 18.7,
                      prior = function(x) dunif(x, 0, 60, log = TRUE)),
  # pump_hs_gcm2: THE HIGH-LATITUDE PUMP, FITTED since 2026-09-07e (29 -> 30) --
  # HS export per unit area in gC m-2 yr-1, remineralised in HD (pays choice C9).
  # The end-member probe put HS's DIC AT the observed high-latitude surface and
  # the deep +12 above it against an observed +116-185; at the round-2 winner
  # 60 gC m-2 yr-1 (3.5 GtC/yr) lands HD - HS at +127 and gains +17 log-units
  # with nothing refitted (diag_hs_pump_probe.R, prereg 09-07d). Box [0.5, 200]:
  # 0.5 = 0.03 GtC/yr, effectively OFF; 200 = 11.6 GtC/yr, above the whole real
  # ocean's export.
  # PRIOR: LITERATURE, LOGNORMAL (Marcus 2026-09-07f) -- built by
  # data-raw/build_hs_export_prior.R from the float-based polar-Antarctic-zone
  # export of Liniger et al. 2025 (2.01 molC m-2 yr-1) and Arteaga et al. 2019
  # (1.80): median 22.9 gC m-2 yr-1, log-sd 0.6 (2.5-97.5 %: 7-74), the width
  # carrying the NH subpolar half of the box and the export horizon (the box's
  # own thickness, not the sources' 100-500 m). The probe's 60 sits at +1.6
  # sigma: the data rows and this prior will disagree, and that is the finding
  # to read, not to pre-empt. init = the prior median (a START, and NOT the
  # probe point -- no centre off the code under test). An ancestor that ran 0
  # cannot be ENCODED under logit (lo 0.5) and is seeded at init by
  # ccx_seed_unencodable(), the kz_deep_frac precedent. The init is a LITERAL
  # because this table is built before R/paths.R is sourced; it is TIED to the
  # build product by tests/testthat/test-pump-hs.R (the ent_seas_amp_SH
  # precedent), and the prior reads the product lazily through
  # ccx_hs_export_prior().
  pump_hs_gcm2 = list(tr = "logit", lo = 0.5, hi = 200, init = 22.9,
                      prior = function(x) { pr <- ccx_hs_export_prior()
                        dlnorm(x, log(pr$centre_gcm2), pr$log_sd, log = TRUE) }),
  # THE BIOLOGICAL PUMP'S MAGNITUDE -- the 20th parameter (Marcus 2026-08-16d).
  # The preindustrial surface-to-bottom DIC gradient the pump holds, umol/kg.
  # ⚠ (code review 2026-10-12) EXACTLY that only in the pure LS column. Under the
  # HILDA HS conduit (tau_q > 0) the SPUN-UP bottom-box-minus-mixed-layer DIC at
  # hilda29e (the canonical until 2026-10-13) is 372.6 (NH) / 363.0 (SH) umol/kg
  # against its fitted pump_grad 314.7; with tau_q = 0 it is 315.4 / 315.6
  # (review-measured; not re-measured at hilda31w, pump_grad 330.7). So
  # under the conduit `pump_grad` is the SOLVED FIELD's magnitude knob, not the
  # model's realised gradient (see ccx_pump_export() in R/model.R).
  # Everything else about the pump stays structural: the export SHAPE is GLODAP's
  # own profile solved against the model's diffusion, and the carbonate share is
  # PINNED by GLODAP's alkalinity gradient. This is the one number the data are
  # asked to set.
  #
  # WHY FITTED RATHER THAN FIXED. calibration/diag_pump_grad_profile.R found the
  # four-row objective prefers 274.5 +/- 13.1 -- 1.178x the observed gradient --
  # at the pre-gradient mode. But the export field is solved against the model's
  # OWN diffusion, so that optimum is conditional on `kz`, which the refit moves.
  # Fixing the parameter at 274.5 would freeze a fit at a stale `kz`; fixing it
  # at the observed 233.109 would assert the model's effective 1-D column needs
  # exactly the real ocean's gradient, which the same profile says it does not
  # (the 18 % excess is the 1-D column's gradient-destroying kz, the same effect
  # behind the ~3x literature-POC ratio in DESIGN sec.5.2c). Fitting it lets the
  # refit resolve the two together.
  #
  # AND THEY ARE NOT DEGENERATE -- MEASURED, NOT ASSUMED.
  # calibration/diag_pump_kz_degeneracy.R scans pump_grad x kz over the whole kz
  # bracket: rho = -0.17, and the marginal sd of `pump_grad` is 1.01x its
  # conditional sd. Fitting it buys a direction `kz` cannot supply, which is what
  # the transport result (diag_ocean_candidates.R: transport CANNOT move the
  # DIC/d13C gradients) predicts structurally.
  #
  # THE PRIOR MILDLY DOUBLE-COUNTS GLODAP, AND THAT IS DELIBERATE AND STATED.
  # Its centre `PUMP_GRAD_OBS` is the same observation the `ocean_grad_dic`
  # likelihood row scores. The width is what keeps that harmless: sd = 0.25 in
  # log-space is +/- 25 %, about 4.5x the likelihood's own 13.1 umol/kg, so the
  # data dominate by a wide margin and the prior only excludes absurd magnitudes.
  # A dunif on a generous bracket would avoid the double-count entirely and is
  # the alternative if this ever looks like it is doing work -- check the
  # posterior against the prior before quoting a pump magnitude as "constrained".
  # `init` REPEATS PUMP_GRAD_OBS rather than reading it, and only because it has
  # to: this table is built at source time and R/calibrate.R sorts BEFORE
  # R/constants.R, so `ccx_const()` does not exist yet. The digits are therefore
  # the constant's in full -- typed short, it drifted 3.8e-4 from the target on
  # the first day -- and tests/testthat/test-likelihood.R ties the two, which is
  # what makes the repetition safe rather than a second place to go stale.
  pump_grad   = list(tr = "log",   init = 233.109378176267,
                     prior = function(x) dlnorm(x, log(ccx_const("PUMP_GRAD_OBS")),
                                                0.25, log = TRUE)),
  # tau_ex: CITED 2026-10-02 (W5; objective #15; Marcus: "Mass basis 0.8 / 0.26"). Was
  # lognormal(1.3, 0.25), "SF6-derived", uncited -- a STATION-pair value for boxes that are whole
  # hemispheric masses. ⚠ The mass basis rests on transport MODELS (Denning et al. 1999 TransCom 2;
  # Patra et al. 2009 ACTM): R/constants.R TAU_EX_PRIOR_CENTRE says so and names them.
  tau_ex      = list(tr = "log",   init = 0.8,
                     prior = function(x) dlnorm(x, log(ccx_const("TAU_EX_PRIOR_CENTRE")),
                                                ccx_const("TAU_EX_PRIOR_LOGSD"), log = TRUE)),
  # RE-ANCHORED ON MOD17 2026-08-20k (Marcus). Was UNIFORM[0.4, 0.8] -- zero
  # observational content, and the fit used the freedom: 0.4662, i.e. 53 % of
  # global NPP on the hemisphere holding 19 % of the land.
  #
  # THE CENTRE IS THE 1750 ANCHOR, NOT THE OBSERVATION. MOD17 measures the
  # MODERN share (NPP_FRAC_NH_OBS = 0.594) and this parameter is a 1750 split;
  # NPP_FRAC_NH_ANCHOR_1750 is that observation walked back through the model's
  # own clearing, as a fixed point. Centring on the raw observation would
  # UNDERSTATE the target, because NH-heavy clearing lowers the NH share over
  # time. See R/constants.R for the derivation and its circularity pricing.
  #
  # THE WIDTH IS A JUDGEMENT, like SST_SEAS_LOGSD and labelled as one. MOD17's
  # own interannual sd (0.0135) is the WRONG uncertainty -- it is the spread of
  # one product about its own mean, and the real ambiguity is product-to-product
  # (MOD17's global total already sits below the model's NPP_GLOBAL_PI). 0.04
  # covers that; it is not derived from a bracket, because no bracket exists on
  # disk. Building one from a second NPP product would be a real improvement.
  #
  # THE BOUNDS ARE UNCHANGED at [0.4, 0.8]: +/- 3 sigma is [0.479, 0.719], well
  # inside them, so the logit transform is not doing prior work.
  # `init` is a LITERAL, not ccx_const(): R/calibrate.R sources BEFORE
  # R/constants.R, so the table cannot call it at construction time -- the
  # prior closure can, because it runs later. Same idiom as pump_grad, and
  # test-likelihood.R ties the literal to the constant so they cannot drift.
  npp_frac_NH = list(tr = "logit", lo = 0.4, hi = 0.8, init = 0.5986118987,
                     prior = function(x) stats::dnorm(x, ccx_const("NPP_FRAC_NH_ANCHOR_1750"),
                                                      NPP_FRAC_NH_SD, log = TRUE)),
  # THE SEASONAL SINE'S 4 KNOBS (seas_amp/seas_phase per hemisphere) were
  # RETIRED 2026-08-18 when the cycle moved onto its physical drivers --
  # insolation-shaped NPP and Q10 on a seasonal land temperature (Marcus; see
  # the CCX_SEAS_PHI_EFF block in R/model.R and
  # calibration/diag_seasonal_drivers_offline.R for the offline feasibility).
  # They survive as fields of ccx_default_params(), live only on the
  # seas_drivers = 0 escape path; mode_fit_pump{N,D}.rds carries their fitted
  # values and reproduces only there. 4 descriptive parameters out, 3 physical
  # ones in -- and the NPP-side amplitude is now a PREDICTION (npp * shape),
  # not a fitted number.
  #
  # SEASONAL AMPLITUDE PRIORS -- RE-ANCHORED ON MEASUREMENTS 2026-08-20g
  # (Marcus: "keep adding in the more physically correct data even if it moves
  # the fit in the slightly wrong direction").
  #
  # WHAT THEY WERE: shrinkage around REMEMBERED climatology -- "NH flux-weighted
  # seasonal land T half-amplitude ~10-14 K", "hemispheric-mean SST cycles are
  # ~2 K NH / milder SH". Nothing in the repo could check them, because HadSST4
  # and CRUTEM5 are held as ANNUAL ANOMALY series and an anomaly has its monthly
  # climatology subtracted by construction.
  #
  # WHAT THEY ARE NOW: the observed climatology (R/constants.R, built by
  # data-raw/build_seasonal_climatology.R from CRU absolute + CRUTEM5 mask and
  # ERSSTv5). The land widths are DERIVED -- the lognormal whose +/-1 sigma spans
  # the measured area-weighted-to-boreal bracket, so the width is the weighting
  # ambiguity itself. The ocean width is a stated JUDGEMENT
  # (SST_SEAS_LOGSD), because no bracket for it exists.
  #
  # THE RECOLLECTIONS WERE CLOSE TO RIGHT: 12 vs an observed 11.4, 2.0 vs 2.24,
  # 1.2 vs 1.75. The re-anchoring is therefore NOT a large move in the priors --
  # it is a large move in what they are ENTITLED TO CLAIM, and a tightening.
  #
  # THIS CHANGES THE OBJECTIVE. calibration/output/pump_arms/mode_fit_pump{N,D}.rds
  # were fitted under the OLD priors: their `par_mode` remains a valid parameter
  # vector, but their `logpost`, `prior_z`, `hessian`, `cov` and Laplace evidence
  # now describe a posterior that no longer exists. A REFIT IS OWED. The mode is
  # very far out under the new priors -- seas_T_amp_NH +5.4 sigma,
  # sst_seas_amp_NH -12.9 -- and that is the point: the fit was buying its
  # seasonal cycle with values the data exclude.
  #
  # `init` is typed literally because CCX_PARAM_TABLE is built before
  # ccx_const() exists; test-likelihood.R ties each literal to its constant, the
  # same guard PUMP_GRAD_OBS carries.
  seas_T_amp_NH = list(tr = "log", init = 14.3214,
                     prior = function(x) ccx_bracket_lnorm(x, "SEAS_T_AMP_NH_OBS")),
  seas_T_amp_SH = list(tr = "log", init = 5.0503,
                     prior = function(x) ccx_bracket_lnorm(x, "SEAS_T_AMP_SH_OBS")),
  # Phenology lag, months: leaf area develops over weeks, so NPP peaks after
  # peak light. Offline optimum 2.25; a negative lag (canopy leading the sun)
  # is unphysical and priced accordingly by the prior rather than bounded.
  # UNCHANGED 2026-08-20g -- no observation of it was acquired.
  # ⚠ SPLIT PER HEMISPHERE 2026-08-31 (Marcus's design call, option A of
  # notes/status_2026-08-29_whole_model_assessment.md). It was ONE SCALAR
  # serving both hemispheres while `seas_npp_amp` and `seas_T_amp` were already
  # [2] arrays a few lines above -- and that asymmetry was measured to cost
  # -838.3 conditional at lag 2.25, of which THE NH PAID 94 %
  # (notes/collect_2026-08-29d). Both entries keep the ORIGINAL prior, so the
  # split adds a degree of freedom without smuggling in a new belief.
  seas_lag_p_NH = list(tr = "id", init = 2.25,
                     prior = function(x) dnorm(x, 2.25, 0.75, log = TRUE)),
  seas_lag_p_SH = list(tr = "id", init = 2.25,
                     prior = function(x) dnorm(x, 2.25, 0.75, log = TRUE)),
  # SST_SEAS_LOGSD is a PRIOR WIDTH, so it lives here and not in R/constants.R:
  # it is a calibration choice, not a physical quantity, and the registry's
  # provisional-constant LEDGER exists to track uncited PHYSICS.
  sst_seas_amp_NH = list(tr = "log", init = 2.23739,
                     prior = function(x) dlnorm(x, log(ccx_const("SST_SEAS_AMP_NH_OBS")),
                                                SST_SEAS_LOGSD, log = TRUE)),
  sst_seas_amp_SH = list(tr = "log", init = 1.74644,
                     prior = function(x) dlnorm(x, log(ccx_const("SST_SEAS_AMP_SH_OBS")),
                                                SST_SEAS_LOGSD, log = TRUE)),
  # ---- SOUTHERN-OCEAN ENTRAINMENT, FITTED SINCE 2026-09-03 (Marcus) ---
  # 25 -> 26 parameters. The channel has existed since 2026-08-27g, IMPLEMENTED,
  # DEFAULTED TO 0 AND NOT IN THIS TABLE -- the textbook shape of
  # [[default_off_hides_the_bug]] -- while the model's WORST prior violation was
  # `sst_seas_amp_SH` two lines up, strained to prior-z -5.14, and the SH ocean
  # seasonal limb still landed 4.33 months from the observed one (GATE S, first
  # measured 2026-09-03 at the refit winner: z -12.30, FAIL).
  #
  # ⭐ THE HYPOTHESIS THIS ENTRY EXISTS TO TEST: the fit is straining SOLUBILITY
  # 5 sigma against its prior to do ENTRAINMENT's job, and still lands in the
  # wrong season -- so it cannot, and the LAND has to run 2.48x observed to make
  # up the amplitude. One missing mechanism would explain the worst prior
  # violation, the seasonal partition error and the land limb's excess at once.
  #
  # ⛔ THE ACCEPTANCE TEST IS **NOT** THE LOGPOST. Freeing a parameter cannot
  # lower it, and a mechanism that improves a fit is not thereby right. The
  # pre-registered test (P2) is whether `sst_seas_amp_SH`'s prior-z RELAXES from
  # -5.14. If it does not move, the hypothesis is WRONG and solubility was never
  # doing entrainment's job. P1 (the limb's PHASE, now scored by GATE S) and P3
  # (`npp_frac_NH` back inside its bounds) are corroboration, not the test.
  #
  # THE PRIOR CENTRE IS DERIVED, NOT CHOSEN: ENT_SEAS_AMP_SH_DERIV is
  # ENT_SEAS_AMP_SH_INBAND diluted onto the SH box by the registered 40-90 S
  # ocean-area fraction ENT_SEAS_BAND_AREA_FRAC (R/constants.R). ⭐ BOTH ARE
  # COMPUTED from named inputs since the 2026-09-03 provenance audit -- they
  # were typed answers with the arithmetic in prose, which is how two typed
  # copies had already drifted from their own chain -- and the inputs moved
  # AGAIN on 2026-09-09w (the band SST half-amplitude and band pCO2 amplitude
  # are read from data/ products since then), so NO VALUE IS TYPED HERE
  # (2026-09-12, review C; the numbers that stood in this comment were the
  # pre-09-09w ones). Print ccx_const("ENT_SEAS_AMP_SH_DERIV") for the live
  # centre, which the `init` below must equal -- test-ent-seas-fitted.R ties
  # them. The WIDTH is derived too, from the no-dilution ceiling -- see
  # ENT_SEAS_LOGSD above.
  # `init` is typed literally because CCX_PARAM_TABLE is built before ccx_const()
  # exists; test-likelihood.R ties each literal to its constant, as seas_T_amp_*
  # and PUMP_GRAD_OBS already are.
  #
  # ⚠ `tr = "log"` MEANS 0 IS NOT A POINT OF THIS SPACE, and that is a real
  # consequence rather than a technicality: the channel's OFF state is no longer
  # representable in the fitted coordinates. A 25-parameter ancestor genuinely
  # RAN at 0, so ccx_migrate_par_set() fills 0 and says so -- and such a migrated
  # vector can be RUN and MEASURED but not ENCODED. That is the honest refusal,
  # not a defect to route around. ⚠ `tau_ex_seas_amp` is STILL implemented,
  # defaulted 0 and unfitted; it was deliberately NOT freed here, so that P2 has
  # one mechanism to attribute to.
  # ⚠ `init` MOVED 10.952353 -> 6.552465 ON 2026-09-09w, with the prior centre it
  # must track. It stays a LITERAL only because CCX_PARAM_TABLE is built in this
  # file, which the alphabetical bootstrap sources BEFORE constants.R, so
  # `ccx_const()` does not exist yet -- the `prior` closure below CAN call it
  # because it runs later. test-ent-seas-fitted.R:27 ties the two at the typed
  # precision (half a unit in the sixth decimal) and CAUGHT this drift on the day
  # the centre moved, which is exactly the guard working ⇒ [[derived_must_mean_computed]].
  ent_seas_amp_SH = list(tr = "log", init = 6.552465,
                     prior = function(x) dlnorm(x, log(ccx_const("ENT_SEAS_AMP_SH_DERIV")),
                                                ENT_SEAS_LOGSD, log = TRUE)),
  # ENSO, FOUR COEFFICIENTS SINCE 2026-09-01 (Marcus's design call). GtC/yr per
  # unit Nino3.4 index. `gamma_enso` was ONE scalar moving LAND ONLY, split
  # 50/50 by a hardcoded share -- and the ocean half of the model's ENSO
  # response was measured ANTI-correlated with the observed one (r = -0.51
  # against +0.535, both basins, detrend-invariant). See ccx_gamma_enso() in
  # R/model.R for the full measurement, the compensating-error state that hid
  # it, and why the per-path fractionation is what makes these identifiable.
  #
  # ⚠ EACH ENTRY KEEPS THE ORIGINAL N(0, 2) PRIOR, the same call as the
  # `seas_lag_p` split: the split adds degrees of freedom without smuggling in
  # a new belief about any one of them. It is NOT scale-preserving on the SUM
  # -- two independent N(0,2) halves imply N(0, 2*sqrt(2)) on the land total
  # where the scalar had N(0,2) -- i.e. the land prior is WIDER by sqrt(2).
  # That is deliberate and it is a WIDENING, not a shift; at a fitted 0.85 the
  # prior is weak either way. The alternative (2/sqrt(2) on each half, exactly
  # preserving the total) is the choice to revisit if the land pair ever runs
  # to the prior rather than to the data.
  #
  # THE OCEAN PAIR IS CENTRED ON ZERO, which is the incumbent model: the prior
  # does not presume the mechanism exists.
  # ⚠ WHERE THE MEASUREMENT PUTS IT (corrected 09-01j): closing the observed
  # ocean-sink slope needs +0.326 in EACH hemisphere, not the +0.137 an earlier
  # reading implied -- that number was a SLOPE gap wearing a coefficient's name,
  # and the coefficient->slope transfer is ~0.43, not 1. The OBJECTIVE's own
  # conditional optimum is nearer +0.10 each, about a third of what the
  # partition asks for; that trade is what the refit is for.
  gamma_enso_land_NH = list(tr = "id", init = 0.25,
                     prior = function(x) dnorm(x, 0, 2, log = TRUE)),
  gamma_enso_land_SH = list(tr = "id", init = 0.25,
                     prior = function(x) dnorm(x, 0, 2, log = TRUE)),
  gamma_enso_ocn_NH  = list(tr = "id", init = 0,
                     prior = function(x) dnorm(x, 0, 2, log = TRUE)),
  gamma_enso_ocn_SH  = list(tr = "id", init = 0,
                     prior = function(x) dnorm(x, 0, 2, log = TRUE)),
  # LAND TURNOVER: ZERO degrees of freedom (2026-08-12, Marcus). The whole land
  # layout -- npp_leaf_frac, tau_leaf, tau_wood, litter_slow_frac, tau_soil_fast,
  # tau_soil_slow -- is now FIXED at its structural values in ccx_default_params().
  #
  # `tau_soil_fast` used to be the one calibrated land timescale, and the comment
  # here used to argue that freezing the OTHER five was enough to stop "a CO2 fit
  # undoing the partition fix that motivated the restructure". That prediction was
  # correct and the mitigation was insufficient: one DOF was enough. The
  # 17-parameter mode drove tau_soil_fast to 11.16 yr (+3.61 sigma, FLAGGED by
  # run_modefind.R's own screen) and put the biosphere bomb-14C back to +50 % /
  # +64 % -- i.e. all the way back to the two-pool land's defect. Quarantined at
  # calibration/output/quarantine/20260812b_free_tau_soil_fast_unbounded_kz/.
  #
  # WHY IT ESCAPED: Naegler & Levin's biosphere row has NO observational estimate,
  # so there is no 14C-partition term in the likelihood. Nothing scores the thing
  # the four-pool land was built to fix. Rather than add a model-vs-model target,
  # the layout is treated as STRUCTURE. For a model whose job is communication,
  # citable turnover times a reader can look up beat a fitted value at +3.6 sigma
  # that nobody can defend -- and the partition stays a demonstrated property
  # instead of something that degrades under calibration.
  # Total bomb 14C production, kmol, 1945-1980. Calibrated (as DESIGN intended),
  # with a CITABLE prior: Naegler & Levin (2006) give 99.3-104.9 kmol. Treating
  # it as free lets error in the still-provisional injection SHAPE be partly
  # absorbed into magnitude, so the post-peak D14C decay can still constrain
  # ocean ventilation instead of being discarded outright. Residual shape
  # dependence remains -- see DATA.md 8.
  bomb_total  = list(tr = "log",   init = 102,
                     prior = function(x) dlnorm(x, log(102), 0.10, log = TRUE)),
  # ---- INPUT UNCERTAINTY: the land-use emission scale (2026-08-14) ----
  # WHY IT EXISTS. E_LUC was prescribed EXACT while being the least certain
  # input in the forcing table, so its uncertainty had nowhere to go except into
  # `beta`. Measured (calibration/diag_luc_scale.R): the model's largest
  # structural misfit -- ~30 ppm of CO2 level against GCB's sink partition --
  # is SMALLER THAN E_LUC'S OWN STATED UNCERTAINTY, and closing it with beta
  # instead costs DESIGN sec.6 gate 7 (sinks, +2.5 / -2.1 sigma) and gate 12
  # (Joos IRF, failing at all three horizons). A parameter with an honest prior
  # is the anti-overfit move here: it stops physics absorbing an input error.
  #
  # THE PRIOR, and it has two INDEPENDENT receipts that agree:
  #  (1) OSCAR v3.1's own cumulative uncertainty, 206 +/- 57 PgC for 1750-2018
  #      (Gasser et al. 2020, Biogeosciences 17:4075, doi:10.5194/bg-17-4075-2020,
  #      DATA.md sec.3a) -> 57/206 = 27.7 % fractional 1 sigma.
  #  (2) the GCB-vs-OSCAR product spread over the IDENTICAL 1850-2018 window,
  #      239.8 vs 178.9 GtC (DATA.md sec.3a) -> ratio 0.746, |ln| = 0.293.
  # Both land on ~0.28, from different arguments -- one a stated uncertainty,
  # one an observed disagreement between products. sdlog = 0.28 therefore puts
  # OSCAR's central estimate at ~1 sigma below GCB's, which is the honest
  # statement of what is known.
  #
  # CENTRED AT 1, i.e. on GCB, because GCB is the standing convention for this
  # repo's emissions and a prior centred anywhere else would be a silent
  # re-basing. GCB's ANNUAL +/-0.7 GtC/yr (LIK_GCB_LUC_SD) against a 2015-2024
  # mean of 1.372 is 51 % -- deliberately NOT used as the width: that is the
  # uncertainty of a single year's flux, only partly correlated across years, so
  # it is an upper bound on the cumulative fraction rather than an estimate of it.
  #
  # NOT a free-for-all: it scales one sourced series, it cannot change its SHAPE,
  # and the pre-1850 / post-1850 segments (different provenance, DATA.md sec.3a)
  # move together. Splitting them is a later question, flagged not taken.
  luc_scale   = list(tr = "log",   init = 1.0,
                     prior = function(x) dlnorm(x, log(1.0), 0.28, log = TRUE)),
  # ---- error model ---------------------------------------------------
  # These are MODEL-STRUCTURAL error at ANNUAL scale, added in quadrature to the
  # fixed representation terms in likelihood.R. They cannot collapse the way
  # sigma_co2 did at the 2026-08-10 mode (0.0744 ppm): with independent errors
  # the maximum-likelihood sigma is just the residual RMS. The collapse needed
  # the AR(1) term, which is retired -- see likelihood.R design note 1.
  #
  # `sigma_co2` RETIRED 2026-08-15 (Marcus, review item 6b). The CO2 level sd is
  # now LIK_CO2_REP_ERR alone, 1.0 ppm, which is the half of the old quadrature
  # that has a receipt. 20 parameters -> 19.
  #
  # THE STATED GROUNDS FOR RETIRING IT WERE MEASURED AND DID NOT HOLD, and this
  # is recorded here so no one re-derives the wrong reason from the two handoffs
  # that asserted them (calibration/diag_sigma_co2.R):
  #   * "pinned at a boundary" -- not on the scale the sampler uses. sigma_co2
  #     was log-transformed, so sigma -> 0 is u -> -Inf and the lognormal prior
  #     closes it off smoothly; the posterior mode was INTERIOR and unimodal at
  #     both points tested. The apparent edge was an artefact of natural units.
  #   * "will hurt covariance conditioning" -- max |r| with any other parameter
  #     was 0.043, against 0.907 for the worst pair in the same Laplace matrix.
  #     It was very nearly orthogonal to everything.
  #   * "unidentified" -- the data tightened it 2.08x vs prior at the mode and
  #     5.79x at defaults; 4th of 18 by posterior width, behind npp_frac_NH,
  #     h_ml and kz, none of which is proposed for removal.
  # The underlying analytic fact is real but is a statement about the RESIDUAL,
  # not about the parameter: sd = sqrt(s^2 + c^2) gives s* = sqrt(R^2 - c^2), so
  # there is no interior optimum whenever the pooled residual RMS R < c. The
  # repo straddles that threshold (R = 1.454 at defaults, 0.614 at the mode).
  #
  # THE REASON IT WAS ACTUALLY RETIRED. A free error scale on the stream that
  # already outvotes the partition terms 40:1 is SELF-WEIGHTING: the better the
  # model fitted CO2, the smaller sigma went, and the LOUDER the CO2 stream
  # became -- 2.04x in variance terms across the two points measured. Positive
  # feedback on the dominant constraint, in the direction that worsens the
  # imbalance the 2026-08-14 review is about. Fixing it costs 1.05x of weight
  # at the current fit and stops the weight tracking the residual thereafter.
  #
  # WHAT WAS GIVEN UP, since it is not nothing: the free sigma was the only
  # adaptive valve on the CO2 level stream, and the margin at the mode is only
  # 0.789 ppm of extra bias, so chains WILL cross back into R > 1.0 where a
  # fixed sd prices a bad CO2 fit at full volume with no give. If the refit
  # shows that biting -- CO2 level dominating the trace, or the chain unable to
  # leave a bad-CO2 region -- this is the first thing to look at.
  #
  # `sigma_d13c` RETIRED 2026-08-18, overturning the 2026-08-15 decision quoted
  # below. That decision said the self-weighting argument "is specific to the
  # dominant stream; a free scale on a MINOR stream is a robustness valve rather
  # than a feedback loop". calibration/diag_fit_at_mode.R MEASURED the premise
  # and it fails: the d13C residual is BIAS, not scatter, and a free error scale
  # cannot distinguish them. De-biased scatter is 0.033 / 0.036 permil -- BELOW
  # the 0.05 permil representation floor the stream already carries -- while the
  # parameter fitted 0.1931. It was explaining no scatter whatever; its entire
  # value was absorbing a +0.19 permil structural bias at 4x the representation
  # error. On a stream Marcus has prioritised, that is a valve venting the
  # signal. ccx_loglik() still honours the field if supplied (absence contract),
  # so every pre-2026-08-18 diagnostic reproduces exactly.
  #
  # `sigma_d14c` STAYS FREE, and the same measurement is the reason: its
  # de-biased scatter is 14.0 / 12.1 permil against an observational sd of ~4.2,
  # so it has genuine excess scatter to explain. Retiring both would have been
  # a slogan; the data separate them.
  sigma_d14c  = list(tr = "log",   init = 5,
                     prior = function(x) dlnorm(x, log(5), 0.7, log = TRUE)),

  # ---- station-vs-box representation offset (2026-08-18, Marcus) -----
  # ONE parameter generating BOTH species' level offsets through mass balance --
  # see the LIK_REP_SOURCE_D13C block in R/likelihood.R for the physics and for
  # the 30x measurement that says a FREE d13C level offset would have swallowed
  # the Suess overshoot.
  #
  # PRIOR sd = 1.0 ppm, which is LIK_CO2_REP_ERR: the repo's own station-vs-box
  # scale, and the one number here with a receipt (co-located NOAA in-situ vs
  # SIO flask at Mauna Loa disagree 0.39-0.59 ppm RMS over 702 months, so a
  # station-vs-BOX term must exceed it). Centred at ZERO, a shrinkage prior, for
  # the same reason the gradient offsets are: centring on the measured offset
  # would tell the model the answer and then congratulate it for agreeing.
  #
  # THE DIAL THIS SETS. Absorbing the measured +0.194 permil d13C common-mode
  # bias needs rep_dC = -4.19 ppm = 4.2 sd, AND would drag the CO2 level stream
  # 4 ppm off its own 0.6 ppm fit. The prior admits a representation constant
  # and resists a structural error wearing its clothes -- the grad_off_co2 idiom.
  # ⚠ SUPERSEDED AS A DESCRIPTION OF THE CANONICAL (code review 2026-10-12; the
  # paragraph above is kept as history): `hilda29e` fit rep_dC = +4.21 ppm and
  # the canonical since 2026-10-13, `hilda31w`, fits +4.24 -- the OPPOSITE sign to
  # the -4.19 above; at hilda29e its CO2 level rows fit at rms z 0.53
  # (review-measured) -- the level stream did not reject it. See the matching
  # note in R/likelihood.R's rep_dC block.
  #
  # NOTE the prior body resolves LIK_CO2_REP_ERR at CALL time. R/calibrate.R is
  # sourced before R/likelihood.R (alphabetical), so the constant does not exist
  # yet when this list is built; it does by the time any prior is evaluated.
  rep_dC      = list(tr = "id",    init = 0,
                     prior = function(x) dnorm(x, 0, LIK_CO2_REP_ERR, log = TRUE)),

  # ---- interhemispheric-gradient offsets (2026-08-15, review item 5) --
  # NUISANCE PARAMETERS, and the point of them is what they STOP happening.
  # The model's NH-box-minus-SH-box is not the quantity MLO minus SPO measures
  # (R/likelihood.R, the LIK_GRAD_* block). Fixing that offset at zero would
  # push a measured, physically expected representation constant onto tau_ex and
  # the hemispheric shares -- i.e. would report as a calibrated exchange time
  # what is really a station's latitude. Same argument, and the same idiom, as
  # `luc_scale` absorbing E_LUC uncertainty instead of letting `fert_k` claim it.
  #
  # BOTH PRIORS ARE CENTRED AT ZERO. They are shrinkage priors, not measurements
  # dressed as priors: centring them on the measured offsets would tell the
  # model the answer and then congratulate it for agreeing.
  #
  # grad_off_co2, sd 0.5 ppm. Chosen so the MEASURED intercepts (-0.386 at
  # defaults, -0.549 at the MAP mode; calibration/diag_gradient_terms.R part 3)
  # sit near 1 sd, while absorbing the whole 1.29 ppm recent miss would cost
  # 2.6 sd. That is the intended dial: the prior admits a representation
  # constant and resists a model error wearing its clothes. ⚠ The canonical
  # hilda31w fits grad_off_co2 = +0.248 ppm -- the OPPOSITE sign to the measured
  # intercepts and to the station-latitude argument (verified 2026-10-15).
  #
  # grad_off_d13c, sd 0.15 permil -- DELIBERATELY LOOSER IN RELATIVE TERMS, and
  # not for the same reason. The CO2 offset is 19 % of its gradient, which the
  # station-latitude argument predicts; the same fraction applied to d13C
  # predicts 0.013 permil against a measured 0.10. Eight times over. So this one
  # is absorbing the repo's known STRUCTURAL d13C misfit, the term's own
  # measurement said its slope is indistinguishable from 1, and pretending
  # otherwise with a tight prior would just move the misfit somewhere less
  # visible. A wide prior here is the honest statement that the d13C gradient
  # contributes SHAPE and not level.
  grad_off_co2  = list(tr = "id", init = 0,
                       prior = function(x) dnorm(x, 0, 0.5,  log = TRUE)),
  grad_off_d13c = list(tr = "id", init = 0,
                       prior = function(x) dnorm(x, 0, 0.15, log = TRUE))
  # `rho` RETIRED 2026-08-11. It was the AR(1) autocorrelation shared across
  # MLO/SPO CO2 and d13C. It railed at its 0.998 bound, driving the effective
  # sample size of 812 MLO monthly observations down to 0.8 and letting a
  # +50 ppm level bias cost 13.7 log-units. Anything reading a saved fit from
  # before this date will find 18 parameters where there are now 17; those
  # outputs are quarantined under calibration/output/quarantine/.
)

CCX_PARAM_NAMES <- names(CCX_PARAM_TABLE)

# THE SIX FITTED NAMES WITH NO MODEL SLOT (named 2026-10-15): two FORCING parameters and four
# LIKELIHOOD ones. ccx_default_params() has no field for them, so they reach a run only through
# ccx_make_logpost()'s own reads and ccx_load_mode()'s ([[ccx_two_param_lists]]).
# test-dormant-fixes.R holds this list equal to setdiff(CCX_PARAM_NAMES, names(ccx_default_params())).
CCX_NUISANCE_NAMES <- c("bomb_total", "luc_scale", "sigma_d14c", "rep_dC",
                        "grad_off_co2", "grad_off_d13c")

# ---- LABEL-GATED FITTED NAMES (2026-09-30; OBJECTIVE #14) --------------
# THE FOUR NAMES OF D2 AND D3 (Marcus 2026-09-30: the non-CO2 land-sink drivers and
# the GCB imbalance allocation; CHANGELOG 09-30 h-n). They are FITTED under a
# structure that OPENS the gate (its block carries `d2d3_free = 1`; the first is
# "hilda_csl3v0kaidgb") and HELD under every other label at their base value,
# which is 0 = OFF by the model's and the likelihood's own absence contracts
# (CCX_NDEP_RET_DEFAULT and CCX_NPP_TSENS_DEFAULT in R/model.R; no shares = the two
# GCB sink rows exactly as objective #13 scores them, test-imb-alloc.R).
#
# ⭐ WHY A GATE, AND NOT FOUR TABLE ENTRIES PINNED UNDER EVERY OLDER LABEL. For the
# OBJECTIVE the two are the same thing: a held name has no prior term and no
# Jacobian, and the model reads its base value, which is exactly a pin. They differ
# in what every EXISTING CONSUMER sees. As entries of CCX_PARAM_TABLE, every
# registered file would LACK them, and the w_eq precedent (migrate 0, then seed the
# unencodable value at init) would put ndep_ret at 3.9 and the shares at 1/3 and 1/2
# IN THE MODEL. Unlike w_eq's cell, which does not exist under those files'
# structure, these four act under EVERY label, so the seeded vector would be a
# different model and every "stored streams reproduce" test would move. Held by the
# label instead, they are simply not in the fitted set until a label opens the gate.
# Every older objective, file, pin record, port target and output label is then
# untouched BY CONSTRUCTION, not by a tolerance.
#
# ⛔ THE FAILURE A GATE INVITES, AND ITS GUARD. A structure that opens the gate,
# scored in a process where the gate was never applied, would run the four at their
# base value (OFF) and report a D2/D3 fit that never happened
# ([[default_off_hides_the_bug]]). ccx_make_logpost() therefore REFUSES both
# mismatches by name: an open structure whose names are not fitted (or pinned), and
# a holding structure whose names are.
#
# PRIORS, as ruled 2026-09-30 (CHANGELOG 09-30 l/m; the constants in R/constants.R):
#   ndep_ret   kg C retained per kg N deposited on land (the retention flux). LOG;
#              lognormal, centre NDEP_RET_PRIOR_CENTRE (3.9), log-sd
#              NDEP_RET_PRIOR_LOGSD (0.67). 0 (OFF) is not a point of this space,
#              which is one more reason a holding label must HOLD it, not encode it.
#   npp_tsens  1/K of GMST: NPP x exp(npp_tsens x GMST). ID; N(0, NPP_TSENS_PRIOR_SD),
#              the ruled sign-free prior.
#   imb_share_land, imb_share_ocean_rest   the D3 shares, stick-broken
#              (ccx_imb_shares(): s_ocean = (1 - s_land) x rest). LOGIT on [0, 1];
#              Beta(1, 2) x Uniform(0, 1) is the FLAT simplex, Dirichlet(1, 1, 1),
#              i.e. the ruling's "freedom to move it". ⚠ The logit Jacobians are
#              part of THIS objective. The screens (09-30 k/n) maximised the shares'
#              LIKELIHOOD with no Jacobian, so the refit's shares will sit slightly
#              off the screen's.
# `init` values are LITERALS because this table is built before R/constants.R is
# sourced (the pump_grad idiom), and test-gated-params.R ties each to its source:
# ndep_ret = the prior centre; npp_tsens = the prior centre 0; the shares = the flat
# simplex's CENTROID (1/3, 1/3, 1/3), i.e. land 1/3 and ocean_rest 1/2. No init is
# taken from a screen: a start is never a centre read off the code under test.
CCX_PARAM_GATED <- list(
  ndep_ret             = list(tr = "log", init = 3.9,
                              prior = function(x) dlnorm(x, log(ccx_const("NDEP_RET_PRIOR_CENTRE")),
                                                         ccx_const("NDEP_RET_PRIOR_LOGSD"), log = TRUE)),
  npp_tsens            = list(tr = "id", init = 0,
                              prior = function(x) dnorm(x, 0, ccx_const("NPP_TSENS_PRIOR_SD"), log = TRUE)),
  imb_share_land       = list(tr = "logit", lo = 0, hi = 1, init = 1 / 3,
                              prior = function(x) dbeta(x, 1, 2, log = TRUE)),
  imb_share_ocean_rest = list(tr = "logit", lo = 0, hi = 1, init = 1 / 2,
                              prior = function(x) dunif(x, 0, 1, log = TRUE))
)
#' The block field that OPENS the D2/D3 gate. Read only through ccx_gate_open().
CCX_GATE_FLAG <- "d2d3_free"

# ---- THE SECOND GATE: THE LAND ENSO LAG (W1, 2026-10-02; objective #15) ----
# `lag_enso_land`, months (R/model.R ccx_enso_lagged()): DESIGN's L_MEI, never built
# until today (CHANGELOG 10-02 x/z). Gated for the reason the D2/D3 names are, and more
# so: absent = 0 = the model every registered file RAN, but 0 is the logit floor, so as
# a table entry the migration would seed it at init (6 months) -- a different model
# under every old label. Held under every label but the ones that open this gate.
# ⚠ WHY A SECOND FLAG AND NOT A FIFTH D2/D3 NAME: the D2/D3 gate is one flag over ONE
# all-or-nothing set, and `hilda33d`'s own label opens it. A fifth name there would make
# every hilda33d consumer demand a lag it does not carry. So each gate has its own flag
# and set (CCX_PARAM_GATES); a label opens any subset; "hilda_csl3v0kaidgbe" opens both.
# PRIOR: U(0, CCX_ENSO_LAG_MAX = 12) months, DESIGN's, on a LOGIT transform over the same
# interval; its Jacobian is part of the objective, as the shares' are. INIT: the prior
# MIDPOINT, 6 months -- not 10-02 (x)'s measured 5, which would be a start taken from a
# screen (see the D2/D3 note above). `lo`/`hi`/`init` are LITERALS (this file is sourced
# before R/model.R defines CCX_ENSO_LAG_MAX); test-enso-lag.R ties them to it.
CCX_PARAM_GATED_ENSO_LAG <- list(
  lag_enso_land = list(tr = "logit", lo = 0, hi = 12, init = 6,
                       prior = function(x) dunif(x, 0, CCX_ENSO_LAG_MAX, log = TRUE))
)
#' The block field that OPENS the lag gate.
CCX_GATE_FLAG_ENSO_LAG <- "enso_lag_free"

# ---- THE THIRD GATE: THE CITATION BATCH'S TWO FITTED NAMES (2026-10-12; label ...wtc) ----
# notes/citation_rulings_2026-10-12.md rows 19 and 16. Gated for the lag's reason: both act under
# EVERY label (the bomb split and the respiration phase), so as table entries the migration would
# seed every registered file at init -- a different model under every old label. Held (absent =
# FORC_BOMB_NH_SHARE 0.90 and CCX_SEAS_T_LAG 2.0) under every label but hilda_csl3v0kaidgbemwtc.
#   bomb_share_NH  NH share of bomb-14C DELIVERY to the troposphere. Marcus: "Fit it, prior U[0.77,
#                  0.98] (Recommended)". UNIFORM between the UNSCEAR 2000 Annex C proxies (90Sr
#                  deposition 0.768; fusion yield by site 0.982: BOMB_NH_SHARE_PRIOR_LO/_HI), on a
#                  LOGIT over the same interval. After the refit: an identifiability check (posterior
#                  sd, correlation with tau_ex and bomb_total), with a fixed proxy as the fallback.
#   seas_T_lag     the respiration lag, months past the mid-July zero-lag peak (R/model.R
#                  ccx_seas_t_lag()). Marcus: "Fit it in the refit (Recommended)", prior "Uniform
#                  [0, 6] months (Recommended)": respiration cannot lead its driver, and a lag past
#                  half a cycle aliases. LOGIT on the box, like kz / h_ml. NOT centred on the old 2.0
#                  (a profile at an ancestral mode), which would be circular.
# INIT = each box's MIDPOINT (0.875; 3 months), the gates' rule: a start is never a value read
# off the code under test. `lo`/`hi` are LITERALS (this file is sourced before R/constants.R and
# R/model.R); test-wtc-label.R ties them to BOMB_NH_SHARE_PRIOR_LO/_HI.
CCX_PARAM_GATED_WTC <- list(
  bomb_share_NH = list(tr = "logit", lo = 0.77, hi = 0.98, init = 0.875,
                       prior = function(x) dunif(x, ccx_const("BOMB_NH_SHARE_PRIOR_LO"),
                                                 ccx_const("BOMB_NH_SHARE_PRIOR_HI"), log = TRUE)),
  seas_T_lag    = list(tr = "logit", lo = 0, hi = 6, init = 3,
                       prior = function(x) dunif(x, 0, 6, log = TRUE))
)
#' The block field that OPENS the citation batch's gate.
CCX_GATE_FLAG_WTC <- "wtc_free"
#' EVERY GATE, flag -> its set, in the order a label's names are appended. A label opens
#' any subset; ccx_gated_names() is what a given structure fits.
CCX_PARAM_GATES <- stats::setNames(list(CCX_PARAM_GATED, CCX_PARAM_GATED_ENSO_LAG, CCX_PARAM_GATED_WTC),
                                   c(CCX_GATE_FLAG, CCX_GATE_FLAG_ENSO_LAG, CCX_GATE_FLAG_WTC))
#' Every gated name's spec, whichever gate holds it (decode, migration, ordering).
CCX_PARAM_GATED_ALL <- do.call(c, unname(CCX_PARAM_GATES))
stopifnot(!anyDuplicated(names(CCX_PARAM_GATED_ALL)))

#' The gate FLAGS a structure (a label, or a base parameter list carrying its block)
#' opens. A label is resolved through ccx_struct_block(), so an unknown label is an
#' error by name rather than a quiet "none".
ccx_gates_open <- function(p) {
  if (is.character(p)) p <- ccx_struct_block(p)
  names(CCX_PARAM_GATES)[vapply(names(CCX_PARAM_GATES), function(f) isTRUE(p[[f]] == 1), logical(1))]
}
#' Does a structure OPEN a gate? `flag` names which; the default is the D2/D3 gate, the
#' meaning this function has had since 09-30 (likelihood.R reads it for the D3 rows).
ccx_gate_open <- function(p, flag = CCX_GATE_FLAG) flag %in% ccx_gates_open(p)
#' The gated names a structure FITS, in the order ccx_apply_gate() appends them.
ccx_gated_names <- function(p)
  unlist(lapply(CCX_PARAM_GATES[ccx_gates_open(p)], names), use.names = FALSE)
#' Put the gated names into the fitted set, for every gate the structure opens.
#' A holding structure is a no-op. The names go at the END of the table (the order
#' of every older name, and of every stored `u`, is unchanged).
#' @param struct a structure label, or a base parameter list
#' @return invisibly, the names added (what ccx_unapply_gate() needs)
ccx_apply_gate <- function(struct) {
  add <- ccx_gated_names(struct)
  if (!length(add)) return(invisible(character(0)))
  env <- environment(ccx_apply_pins)
  tab <- get("CCX_PARAM_TABLE", envir = env)
  already <- intersect(add, c(names(tab), names(get("CCX_PINS", envir = env))))
  if (length(already))
    stop("ccx_apply_gate(): ", paste(already, collapse = ", "), " are already in the fitted set ",
         "(or pinned). The gate is applied ONCE per process; undo it with the handle it returned.")
  tab <- c(tab, CCX_PARAM_GATED_ALL[add])
  assign("CCX_PARAM_TABLE", tab, envir = env)
  assign("CCX_PARAM_NAMES", names(tab), envir = env)
  invisible(add)
}
#' Take the gated names back out of the fitted set (the handle ccx_apply_gate() returned).
#' Refuses while any of them is PINNED: the pin's restore would put it back under no gate.
ccx_unapply_gate <- function(added) {
  if (!length(added)) return(invisible(NULL))
  env <- environment(ccx_apply_pins)
  held <- intersect(added, names(get("CCX_PINS", envir = env)))
  if (length(held))
    stop("ccx_unapply_gate(): ", paste(held, collapse = ", "), " are PINNED; ",
         "ccx_unpin_params() first, then undo the gate.")
  tab <- get("CCX_PARAM_TABLE", envir = env)
  tab[intersect(added, names(tab))] <- NULL
  assign("CCX_PARAM_TABLE", tab, envir = env)
  assign("CCX_PARAM_NAMES", names(tab), envir = env)
  invisible(NULL)
}

# ---- PINNED ARMS (2026-09-13) ----------------------------------------
# A PIN removes a name from the FITTED set and carries its value in the base
# parameters instead, so the objective is evaluated on the remaining names with
# that coordinate held. This is what `CCX_MODE_PINNED` (R/paths.R) was always
# meant to record and, until today, nothing could produce: `pin90` was a
# near-delta PRIOR, which is not a pin (its +11.67 prior credit polluted every
# comparison). A pin has NO prior term and NO Jacobian for the held name -- the
# objective on the reduced set is exactly the full objective's conditional
# slice at the pinned value, minus the held name's own prior, which is a
# constant. ⚠ THAT CONSTANT IS WHY A PINNED ARM'S LOGPOST IS NOT COMPARABLE
# TO A FREE ARM'S: compare on LIKELIHOOD (streams), never on the stored value.
#
# First use: C' -- `ent_seas_amp_SH` (the pCO2-side entrainment SHIM, which
# moves no carbon) pinned to 0 against `hilda31s2`, to ask whether the real
# seasonal mixed layer carries the SH ocean limb's DIC side on its own
# (assessment 2026-09-12 option C'). Under `tr = "log"` 0 is off the support,
# so a pin is the ONLY way to put the shim at 0.
#
# The globals are mutated IN THE ENVIRONMENT THE TABLE LIVES IN, so every
# consumer (ccx_par_to_unc, ccx_unc_to_par, ccx_make_logpost's prior loop,
# ccx_init_unc, ccx_migrate_par_set) sees the reduced set; ccx_unpin_params()
# restores it (tests run in one process).
#' @param pins a named numeric: value per pinned parameter name
#' @return invisibly, the removed table entries (what ccx_unpin_params needs)
ccx_apply_pins <- function(pins) {
  # THE GATE RIDES WITH A MODE FILE'S PINS (2026-10-01). ccx_mode_pins() of a file fitted under a
  # structure that OPENS the gate (CCX_PARAM_GATED) carries attr "gate_struct": the four gated
  # names are part of that file's fitted set, so applying its pins applies the gate FIRST -- the
  # idiom every consumer already writes, ccx_apply_pins(ccx_mode_pins(md)), then reads the file's
  # own space with no second call to forget. The returned handle carries the gate, and
  # ccx_unpin_params() undoes both. A gate some caller already applied is left to that caller.
  gs <- attr(pins, "gate_struct")
  # (2026-10-02: every gate the file's structure opens -- ccx_gated_names() -- not one set)
  gate <- if (!is.null(gs) && length(setdiff(ccx_gated_names(gs), c(CCX_PARAM_NAMES, names(CCX_PINS)))))
            ccx_apply_gate(gs) else character(0)
  if (is.null(pins) || !length(pins)) return(invisible(structure(list(), gate = gate)))
  if (is.null(names(pins)) || any(!nzchar(names(pins))) || !is.numeric(pins))
    stop("ccx_apply_pins(): `pins` must be a NAMED numeric vector, e.g. c(ent_seas_amp_SH = 0).")
  env <- environment(ccx_apply_pins)
  tab <- get("CCX_PARAM_TABLE", envir = env)
  unknown <- setdiff(names(pins), names(tab))
  if (length(unknown))
    stop("ccx_apply_pins(): not a fitted parameter of this build: ", paste(unknown, collapse = ", "),
         " (a pin holds a FITTED name; a base parameter is set on base_params directly).")
  if (!all(is.finite(pins))) stop("ccx_apply_pins(): every pin value must be finite.")
  removed <- tab[names(pins)]
  tab[names(pins)] <- NULL
  assign("CCX_PARAM_TABLE", tab, envir = env)
  assign("CCX_PARAM_NAMES", names(tab), envir = env)
  assign("CCX_PINS", pins, envir = env)
  invisible(structure(removed, gate = gate))
}
#' Restore the pinned names to the table, in their ORIGINAL order.
ccx_unpin_params <- function(removed) {
  gate <- attr(removed, "gate")              # the gate the pins applied (2026-10-01), undone LAST
  if (!length(removed)) { if (length(gate)) ccx_unapply_gate(gate); return(invisible(NULL)) }
  env <- environment(ccx_apply_pins)
  tab <- get("CCX_PARAM_TABLE", envir = env)
  full <- c(tab, removed)
  # the original order is CCX_PARAM_TABLE's definition order, which the tests
  # and the mode files' `param_names` both depend on
  ord <- .CCX_PARAM_ORDER[.CCX_PARAM_ORDER %in% names(full)]
  assign("CCX_PARAM_TABLE", full[ord], envir = env)
  assign("CCX_PARAM_NAMES", ord, envir = env)
  assign("CCX_PINS", NULL, envir = env)
  if (length(gate)) ccx_unapply_gate(gate)
  invisible(NULL)
}
# the table's definition order, then the gated names (appended by ccx_apply_gate(), so a
# pinned gated name is restored to the same place)
.CCX_PARAM_ORDER <- c(CCX_PARAM_NAMES, names(CCX_PARAM_GATED_ALL))

# ---- NAMES A REGISTERED FILE MAY LACK (2026-09-13i) -------------------
#' `w_eq` / `gamma_eq` entered the table on 2026-09-13i, AFTER every registered
#' mode was fitted, and the equatorial cell they drive does not exist under those
#' files' own structure ("hilda": eq_frac 0). A registered file lacking exactly
#' these is therefore still THIS BUILD's vector in every coordinate the model
#' READS: ccx_migrate_par_set() fills 0 = what it RAN, and its 25 stream
#' likelihoods reproduce to the bit (test-eq-cell P0a). What does NOT carry over
#' is the ENCODING: 0 sits on each box's floor, so a START point built from such
#' a file is seeded at init (27 Sv, 1 per index) and its logpost moves by a KNOWN
#' constant -- ccx_mode_start() returns both, and a test that reproduces a stored
#' logpost subtracts it rather than loosening a tolerance.
#' ⛔ This is NOT a general "tolerate any old file" switch: a name is listed here
#' only while (a) it has a migration contract, (b) the registered files predate
#' it, and (c) the model it drives is ABSENT under those files' own structure, so
#' the migrated vector is the file's vector. A file fitted under "hilda_eq" MUST
#' carry the pair (its param_names says so; the array's start files do). Shrink
#' this set as files are refit or retired; empty it when none remain.
CCX_PARAM_ABSENT_OK <- c("w_eq", "gamma_eq",
                         # option D + E (2026-09-14 h): the three reach the model only
                         # under pump_field = "martin"; every registered file is "solved"
                         "pump_export", "w_vent", "gamma_vent",
                         # option O1 arm THC (2026-09-15 d): likewise "martin"-only
                         "w_thc",
                         # the layer-2 Nino3.4 limb (2026-09-17 k): reaches the model only
                         # under k_l2 > 0 ("hilda_cl2"/"hilda_cl3"...; the canonical hilda31w
                         # runs k_l2 = 3, w_enso_l2 pinned at 16.79); k_l2 = 0 elsewhere
                         "w_enso_l2")
# ⚠ The GATED names (2026-09-30, CCX_PARAM_GATED) are NOT listed here: this set is
# static and every name on it must be fitted (test-param-absent-ok.R), which a gated
# name is only while a structure opens the gate. Their tolerance is DYNAMIC instead,
# in ccx_param_absent_ok(): a file whose OWN structure holds the gate ran them OFF,
# so it may lack them exactly when the process has the gate open (an open-label
# START). A file whose own structure OPENS the gate must carry all four.
#' The names a mode file may lack in THIS process: the static list, plus the gated
#' names when the gate is open and the FILE's own structure holds it.
ccx_param_absent_ok <- function(md) {
  # per GATE since 2026-10-02: the gated names fitted in this process that the FILE's own
  # structure HELD (a kaidgb file read with the lag gate open lacks only the lag)
  gated <- intersect(names(CCX_PARAM_GATED_ALL), CCX_PARAM_NAMES)
  held  <- setdiff(gated, ccx_gated_names(ccx_mode_struct(md)))
  if (length(held)) c(CCX_PARAM_ABSENT_OK, held) else CCX_PARAM_ABSENT_OK
}

#' A mode file fitted under a structure that OPENS the gate carries the gated names in
#' its `param_names`; read in a process where the gate is closed, it would look like a
#' file from another parameter set ("retired names") and every consumer would refuse it
#' for the wrong reason. Say the right one. (An OLDER file read with the gate open is
#' legitimate: that is an open-label START, and the migration fills what it ran.)
ccx_gate_require <- function(md, who) {
  miss <- setdiff(ccx_gated_names(ccx_mode_struct(md)), c(CCX_PARAM_NAMES, names(CCX_PINS)))
  if (length(miss))
    stop(who, ": this mode file was fitted under '", ccx_mode_struct(md), "', which OPENS the ",
         "gate (", paste(ccx_gates_open(ccx_mode_struct(md)), collapse = ", "), "), but ",
         paste(miss, collapse = ", "), " are not in this process's fitted set. ",
         "Call ccx_apply_gate(ccx_mode_struct(md)) BEFORE applying its pins.")
  invisible(TRUE)
}

#' THE BUILD'S FITTED SET FOR A FILE'S OWN STRUCTURE (2026-10-01): the live table, plus -- when
#' the file's structure OPENS the gate and this process has not applied it -- the gated names, in
#' the order ccx_apply_gate() appends them. "Does this file carry the build" is a question about
#' the file's structure, not about whether some earlier caller happened to open the gate.
ccx_build_names_for <- function(md) {
  c(CCX_PARAM_NAMES, setdiff(ccx_gated_names(ccx_mode_struct(md)), c(CCX_PARAM_NAMES, names(CCX_PINS))))
}
#' The names this build fits that a mode file lacks, pins excluded
ccx_mode_absent <- function(md)
  setdiff(setdiff(ccx_build_names_for(md), names(md$pins)), md$param_names)

#' Does a mode file carry THIS BUILD's parameter set? TRUE when its param_names
#' equal the build's set minus its pins, or differ from it ONLY by names in
#' CCX_PARAM_ABSENT_OK (order preserved). Every consumer that used to compare
#' `identical(md$param_names, setdiff(CCX_PARAM_NAMES, names(md$pins)))` reads this.
ccx_mode_carries_build <- function(md) {
  want   <- setdiff(ccx_build_names_for(md), names(md$pins))
  # a FREE file scored under pins applied IN-PROCESS carries the held name; the
  # encoder ignores it (ccx_par_to_unc), so the comparison does too (test-pinned-arm)
  have   <- setdiff(md$param_names, names(CCX_PINS))
  absent <- setdiff(want, have)
  identical(have, setdiff(want, absent)) && all(absent %in% ccx_param_absent_ok(md))
}

#' A mode file as a START POINT of this build's space: migrated (what it RAN),
#' seeded where that does not encode, encoded, and the logpost shift the seeding
#' costs -- the driver's own start path (run_dispersed_multistart.R), in one place.
#' ⚠ A PINNED file must have its pins APPLIED (ccx_apply_pins(ccx_mode_pins(md)))
#' before this is called, exactly as for ccx_par_to_unc(); the held name it
#' carries is then ignored by the encoder.
#' @param md a loaded mode file, or a mode name known to ccx_mode_file()
#' @return list(p = the seeded vector, u = its encoding, absent = the names the
#'   file lacked, logpost_shift = sum over `absent` of prior(seed) + log-Jacobian
#'   -- the constant by which this build's logpost at `u` exceeds the file's own)
ccx_mode_start <- function(md = CCX_MODE_CANONICAL, who = "mode start") {
  if (is.character(md)) md <- readRDS(ccx_mode_file(md))   # a mode NAME, as ccx_mode_params()
  # a malformed parameter set first (the file is wrong whatever the gate), then the gate (the file is
  # fine, but this process cannot encode its gated names) -- 2026-10-01
  if (!ccx_mode_carries_build(md))
    stop("ccx_mode_start(): this mode file was fitted on a different parameter set (",
         length(md$param_names), " names; this build fits ", length(CCX_PARAM_NAMES),
         " and tolerates only ", paste(ccx_param_absent_ok(md), collapse = ", "), " absent).")
  ccx_gate_require(md, "ccx_mode_start()")
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(md))
  pm <- suppressWarnings(ccx_seed_unencodable(pm, who))
  u  <- ccx_par_to_unc(pm)
  # the FULL list (structure + fitted values) for the priors that read the
  # structure (u_hs's live hs_frac, 2026-09-16 d) -- the mode's own base
  p_full <- tryCatch(ccx_mode_base(md), error = function(e) list())
  for (n in names(pm)) p_full[[n]] <- pm[[n]]
  absent <- intersect(attr(pm, "migrated"), CCX_PARAM_NAMES)
  shift <- if (length(absent)) sum(vapply(absent, function(n) {
    s <- CCX_PARAM_TABLE[[n]]; .ccx_prior_eval(s, pm[[n]], p_full) + .log_jac(u[[n]], s) }, numeric(1))) else 0
  # THE BAND TERM (2026-09-16 b). A file fitted under a recorded bracket
  # (ccx_mode_bands(): hml_bound / kz_bracket) that differs from the LIVE table
  # was scored with THAT bracket's logit Jacobian; this build scores the same
  # natural value with the live one. The prior density is on the natural scale
  # and does not move; the Jacobian does, by .log_jac(live) - .log_jac(recorded).
  # Added when the h_ml floor moved 30 -> 42.5 m, so every gate-4 reproduction
  # closes without restamping the files. Only logit transforms have a band.
  band_shift <- 0
  for (bn in names(ccx_mode_bands(md))) {
    s <- CCX_PARAM_TABLE[[bn]]
    if (is.null(s) || !identical(s$tr, "logit") || !bn %in% names(u) || bn %in% names(CCX_PINS)) next
    rec <- ccx_mode_bands(md)[[bn]]
    if (isTRUE(all.equal(rec, c(s$lo, s$hi)))) next
    s_rec <- s; s_rec$lo <- rec[1]; s_rec$hi <- rec[2]
    u_rec <- qlogis((pm[[bn]] - s_rec$lo) / (s_rec$hi - s_rec$lo))
    band_shift <- band_shift + .log_jac(u[[bn]], s) - .log_jac(u_rec, s_rec)
  }
  list(p = pm, u = u, absent = absent, logpost_shift = shift + band_shift, band_shift = band_shift)
}
CCX_PINS <- NULL
#' Parse a pin specification of the form "name=value[,name=value]" (CCX_MS_PIN).
#' "" or NA means no pins. Values must parse as finite numbers.
ccx_parse_pins <- function(spec) {
  if (is.null(spec) || is.na(spec) || !nzchar(trimws(spec))) return(NULL)
  parts <- strsplit(trimws(spec), ",", fixed = TRUE)[[1]]
  kv <- strsplit(trimws(parts), "=", fixed = TRUE)
  if (any(lengths(kv) != 2L))
    stop("ccx_parse_pins(): expected name=value[,name=value]; got '", spec, "'.")
  vals <- suppressWarnings(as.numeric(vapply(kv, `[[`, "", 2L)))
  if (any(!is.finite(vals))) stop("ccx_parse_pins(): non-numeric pin value in '", spec, "'.")
  stats::setNames(vals, trimws(vapply(kv, `[[`, "", 1L)))
}
#' The label a pin set contributes to an outdir / file name: "_pin_<name>=<value>".
ccx_pin_label <- function(pins) {
  if (is.null(pins) || !length(pins)) return("")
  paste0("_pin_", paste(sprintf("%s=%s", names(pins), format(pins, trim = TRUE)), collapse = "_"))
}

# ---- transforms ------------------------------------------------------
.to_unc <- function(v, s) switch(s$tr,
  log   = log(v),
  logit = qlogis((v - s$lo) / (s$hi - s$lo)),
  id    = v)

.from_unc <- function(u, s) switch(s$tr,
  log   = exp(u),
  logit = s$lo + (s$hi - s$lo) * plogis(u),
  id    = u)

# log|d natural / d unconstrained| -- the Jacobian. Omitting this reshapes the
# priors without any error being raised, so it is applied explicitly.
# Evaluate a table prior at a natural value, passing the parameter LIST to the
# priors that take one (2026-09-16 d: u_hs's Sv-to-m/yr conversion needs the
# live hs_frac). One-argument priors are called as before. Every prior
# evaluation in R/ goes through here; a hand-rolled `s$prior(x)` in a
# diagnostic still works and silently gets the product's own area.
.ccx_prior_eval <- function(s, x, p = NULL) {
  if (length(formals(s$prior)) >= 2L) s$prior(x, p) else s$prior(x)
}

.log_jac <- function(u, s) switch(s$tr,
  log   = u,
  logit = log(s$hi - s$lo) + plogis(u, log.p = TRUE) + plogis(-u, log.p = TRUE),
  id    = 0)

# ⚠ THE ENCODE-SIDE MIRROR of ccx_unc_to_par()'s parameter-set guard, and it
# was left unhardened when that one was fixed on 2026-08-31. It iterates the
# BUILD's names, so a `par_mode` stored under an older parameter set reaches
# `.to_unc(NULL, ...)` and dies inside vapply as "values must be length 1, but
# FUN(X[[12]]) result is length 0" -- an INDEX, three frames below the cause,
# naming nothing. Found on the WARM-START path of the 22-parameter refit, where
# it would have killed a 14 h run in its first seconds. Say which names are
# absent, and say that a parameter SET is what changed.
ccx_par_to_unc <- function(p) {
  absent <- CCX_PARAM_NAMES[vapply(CCX_PARAM_NAMES,
                                   function(n) is.null(p[[n]]), logical(1))]
  if (length(absent))
    stop("ccx_par_to_unc(): p lacks parameters this build fits: ",
         paste(absent, collapse = ", "),
         ". It was written under a different parameter set -- bring it forward ",
         "with ccx_migrate_par_set() first.")
  u <- vapply(CCX_PARAM_NAMES,
              function(n) .to_unc(p[[n]], CCX_PARAM_TABLE[[n]]), numeric(1))
  # ⚠ THE SECOND WAY THIS ENCODER CAN LIE, HARDENED 2026-09-03. The guard above
  # catches an ABSENT name. It does not catch a name that is PRESENT but sits
  # outside its transform's domain -- log(0), or a logit at its own bound --
  # which returns -Inf QUIETLY and hands a non-finite start vector to an
  # optimiser three frames away. It became reachable the moment
  # `ent_seas_amp_SH` entered the table with `tr = "log"`: a 25-parameter
  # ancestor migrates to 0 (what it RAN), and 0 is not a point of a log space.
  # Refusing here, by name and with the value, is the difference between "this
  # ancestor's OFF state is unrepresentable, seed the coordinate" and a run that
  # dies in its first seconds naming an index. [[broken_gate_reports_nothing]]
  bad <- CCX_PARAM_NAMES[!is.finite(u)]
  if (length(bad))
    stop("ccx_par_to_unc(): ", length(bad), " parameter(s) lie OUTSIDE their ",
         "transform's domain and encode to a non-finite value: ",
         paste(sprintf("%s = %g (tr = %s)", bad,
                       vapply(bad, function(n) as.numeric(p[[n]]), 0),
                       vapply(bad, function(n) CCX_PARAM_TABLE[[n]]$tr, "")),
               collapse = ", "),
         ". A value the model can RUN is not automatically a point of the ",
         "FITTED space -- a migrated ancestor whose mechanism was OFF is the ",
         "usual case. Seed the coordinate at its table init if you meant this ",
         "vector as a START point; measure at it directly if you meant it as a ",
         "vector to RUN.")
  u
}

#' Bring a stored parameter list onto THIS build's fitted set.
#'
#' A stored `par_mode` is only as current as the parameter set it was written
#' under. When a parameter SPLITS, the model already holds an opinion about what
#' the retired scalar means -- and that opinion is READ FROM the model's own
#' resolver here, never restated, so the two cannot drift apart. That is the
#' 2026-08-30 `gamma_diff` lesson (one resolver, every consumer through it)
#' applied to the calibration side.
#'
#' Migration is for a fitted ancestor, not for a blank slate: a name that no
#' stored field can supply is an ERROR, never a silent fill from the named
#' default. Warm-starting from an invented default is not a warm start.
#'
#' Returns `p` with every fitted name present and a `migrated` attribute naming
#' what was filled.
ccx_migrate_par_set <- function(p) {
  absent <- CCX_PARAM_NAMES[vapply(CCX_PARAM_NAMES,
                                   function(n) is.null(p[[n]]), logical(1))]
  if (!length(absent)) return(structure(p, migrated = character(0)))
  filled <- character(0)

  # 2026-08-31: seas_lag_p -> seas_lag_p_NH / seas_lag_p_SH. ccx_seas_lag_p()
  # IS the absence contract; ask it rather than re-deciding what a legacy
  # scalar means. Refuse when there is no legacy scalar to read.
  split_nm <- c("seas_lag_p_NH", "seas_lag_p_SH")
  if (any(split_nm %in% absent)) {
    # `[[` NOT `$` (fixed 2026-09-25): `$` partial-matches, so with exactly ONE
    # half absent this refusal was UNREACHABLE -- `p$seas_lag_p` resolved to the
    # surviving half and the migration mirrored it across instead of refusing.
    # It fired only when BOTH were absent, i.e. when the prefix was ambiguous.
    if (is.null(p[["seas_lag_p"]]))
      stop("ccx_migrate_par_set(): ", paste(intersect(split_nm, absent), collapse = ", "),
           " absent and no legacy `seas_lag_p` to migrate from. This list ",
           "carries no NPP lag at all; it is not a fitted ancestor.")
    lag <- ccx_seas_lag_p(p)
    for (h in c("NH", "SH")) {
      n <- paste0("seas_lag_p_", h)
      if (n %in% absent) { p[[n]] <- unname(lag[[h]]); filled <- c(filled, n) }
    }
    # DROP the retired scalar, exactly as the gamma_enso branch below does and
    # for the same reason: a list carrying both is what ccx_seas_lag_p() now
    # refuses, and a migrated list must be usable without a second thought.
    # ⚠ THIS WAS MISSING UNTIL 2026-09-02 while the gamma_enso branch had it.
    # The tell was the parameter COUNT: migrating a 21-parameter ancestor
    # returned 26 names against CCX_PARAM_NAMES' 25, and the extra one was this
    # scalar. Numerically inert to drop -- the split fields were filled FROM it,
    # so they carry the same value -- but while it stayed, every migrated
    # ancestor was a list carrying both names, i.e. the one shape no resolver
    # should ever have to guess about.
    p$seas_lag_p <- NULL
  }

  # 2026-09-01: gamma_enso -> gamma_enso_land_NH/_SH + gamma_enso_ocn_NH/_SH.
  # ccx_gamma_enso() IS the absence contract, exactly as above: ask it, never
  # restate it. It gives the LAND pair the legacy scalar times the retired
  # 0.5/0.5 share and the OCEAN pair 0 -- the mechanism did not exist, so a
  # fitted ancestor holds no opinion about it and must not be given one.
  enso_nm <- CCX_ENSO_PARAMS
  if (any(enso_nm %in% absent)) {
    # STRICT, like the lag above: a legacy scalar is what makes this a fitted
    # ancestor. Filling an absent LAND coefficient from the named default would
    # be an invented coordinate wearing a fitted vector's name. The OCEAN pair
    # migrating to 0 is NOT such an invention -- 0 is what the ancestor RAN.
    # `[[` NOT `$` -- same partial-matching fix as the lag branch above.
    if (is.null(p[["gamma_enso"]]))
      stop("ccx_migrate_par_set(): ", paste(intersect(enso_nm, absent), collapse = ", "),
           " absent and no legacy `gamma_enso` to migrate from. This list ",
           "carries no ENSO response at all; it is not a fitted ancestor.")
    g <- ccx_gamma_enso(p)
    for (n in intersect(enso_nm, absent)) {
      key <- sub("^gamma_enso_", "", n)
      p[[n]] <- unname(g[[key]]); filled <- c(filled, n)
    }
    # DROP the retired scalar: a list carrying both is what ccx_gamma_enso()
    # refuses, and a migrated list must be usable without a second thought.
    p$gamma_enso <- NULL
  }

  # 2026-09-03: ent_seas_amp_SH entered the table (25 -> 26). A 25-parameter
  # ancestor holds no opinion about it because THE CHANNEL WAS OFF WHEN IT WAS
  # FITTED -- so 0 is not an invented coordinate, it is what the ancestor RAN,
  # exactly as the ENSO OCEAN pair migrating to 0 was. The absence contract is
  # the model's own (`R/cpp.R`, and the `!is.null()` guard in R/model.R): absent
  # = 0 = the pre-2026-08-27g model, bit for bit. Asked here rather than
  # restated, in the sense that this branch fills the SAME value those guards
  # would have produced had the name simply been left absent.
  # ⚠ AND THE FILLED VECTOR CANNOT BE ENCODED. `tr = "log"` excludes 0, so
  # ccx_par_to_unc() on a migrated ancestor gives -Inf in this coordinate. That
  # is CORRECT and it is the point: a vector whose own value is unrepresentable
  # in this build's space is not a point of this build's space. Such a vector is
  # still a legitimate thing to RUN and MEASURE -- which is what every gate
  # driver does with it -- and refusing to encode it is the honest answer rather
  # than a bug to route around. [[ccx_require_param_set]]'s standing: refusal is
  # often right; refusing without saying what changed never is.
  if ("ent_seas_amp_SH" %in% absent) {
    p$ent_seas_amp_SH <- 0
    filled <- c(filled, "ent_seas_amp_SH")
  }

  # 2026-09-06d: kz_deep_frac and hs_asx_frac entered the table (26 -> 28).
  # A 26-parameter ancestor RAN the uniform column with HILDA's exchange
  # assumption -- both absent = 1 by the model's own contracts
  # (ccx_kz_profile(): NULL -> rep(kz, nl); ccx_prepare(): NULL -> factor 1) --
  # so 1 is what it ran, not an invented coordinate. kz_deep_frac = 1 is the
  # box's upper bound and does not ENCODE; ccx_seed_unencodable() seeds it at
  # init for a START point, exactly as ent_seas_amp_SH above.
  for (nm in c("kz_deep_frac", "hs_asx_frac")) if (nm %in% absent) {
    p[[nm]] <- 1
    filled <- c(filled, nm)
  }
  # 2026-09-07: h_hs entered the table (28 -> 29). Absent = 0 = FOLLOW h_ml in
  # the model's own contract (ccx_prepare()), so what the ancestor RAN is its
  # own h_ml -- filled from the list itself, never from a named default.
  if ("h_hs" %in% absent) {
    if (is.null(p$h_ml)) stop("ccx_migrate_par_set(): h_hs absent and no h_ml to follow.")
    p$h_hs <- p$h_ml
    filled <- c(filled, "h_hs")
  }
  # 2026-09-07e/f: pump_hs_gcm2 entered the table (29 -> 30). Absent = 0 = OFF in
  # the model's own contract (ccx_pump_export_hs(): NULL -> nothing emitted), so
  # 0 is what every ancestor RAN. 0 is below the box's floor and does not
  # ENCODE; ccx_seed_unencodable() seeds it at init for a START point.
  if ("pump_hs_gcm2" %in% absent) {
    p$pump_hs_gcm2 <- 0
    filled <- c(filled, "pump_hs_gcm2")
  }
  # 2026-09-08d: u_hs entered the table (30 -> 31). Every ancestor RAN the
  # structure's declared 38 (CCX_U_HS_DECLARED; the column ancestors carry the
  # same 38 from ccx_default_params()), which is interior to the box and
  # ENCODES, so ccx_seed_unencodable() is a no-op here (the h_hs situation).
  if ("u_hs" %in% absent) {
    p$u_hs <- CCX_U_HS_DECLARED
    filled <- c(filled, "u_hs")
  }
  # 2026-09-13i: w_eq and gamma_eq entered the table (31 -> 33), the equatorial
  # cell's two fitted names. Absent = 0 = NO LOOP in the model's own contract
  # (ccx_default_params(): both 0; ccx_cpp_par(): NULL -> 0), which is what
  # every ancestor RAN -- under "hilda" the cell does not even exist. 0 is ON
  # each box's floor (w_eq [5, 60], gamma_eq [0, 2]) and does not ENCODE;
  # ccx_seed_unencodable() seeds both at init (27 Sv, 1 per index) for a START
  # point -- the pump_hs_gcm2 precedent.
  for (nm in c("w_eq", "gamma_eq")) if (nm %in% absent) {
    p[[nm]] <- 0
    filled <- c(filled, nm)
  }
  # 2026-09-14 h: pump_export, w_vent and gamma_vent entered the table (33 ->
  # 36), option D + E's three names. Absent = 0 = OFF in the model's own
  # contract (ccx_default_params(): all 0; the loop and the prescribed field
  # both emit nothing at 0), which is what every ancestor RAN -- and under
  # every registered file's pump_field = "solved" none of the three reaches the
  # model at all. 0 is on w_vent's / gamma_vent's floor and pump_export's log
  # pole and does not ENCODE; ccx_seed_unencodable() seeds at init for a START
  # point -- the w_eq precedent.
  for (nm in c("pump_export", "w_vent", "gamma_vent", "w_thc")) if (nm %in% absent) {
    p[[nm]] <- 0
    filled <- c(filled, nm)
  }
  # 2026-09-17 k: w_enso_l2 entered the table (36 -> 37). Absent = 0 = OFF, and
  # under a structure with k_l2 = 0 the limb is absent anyway. (A file whose
  # structure HAS the limb -- the canonical hilda31w, k_l2 = 3 -- carries
  # w_enso_l2 among its pins, 16.79, so it is not absent there.)
  if ("w_enso_l2" %in% absent) { p[["w_enso_l2"]] <- 0; filled <- c(filled, "w_enso_l2") }
  # 2026-09-30: the GATED names (CCX_PARAM_GATED) are in the table only under a
  # structure that opens the gate. Every file fitted under any other structure HELD
  # them at their base value, 0 = OFF in the model's own contracts (ndep_ret,
  # npp_tsens) and in the likelihood's (shares (0, 0) = no allocation = objective
  # #13, bit for bit) -- so 0 is what the file RAN. ⚠ UNLIKE w_eq, THESE ACT UNDER
  # EVERY LABEL: ccx_seed_unencodable() moves ndep_ret and the two shares (0 does not
  # encode under log / on the logit floor) to their table inits, and at an open label
  # the seeded vector is a DIFFERENT MODEL from the file's. It is a START, never a
  # reproduction; a reproduction scores the file under its OWN label, gate closed.
  # 2026-10-02: the LAG gate's `lag_enso_land` the same way -- 0 = the index read at t,
  # what every file before objective #15 ran; 0 is its logit floor, so it seeds at init.
  # ⛔ 2026-10-12: NOT the citation batch's two (CCX_PARAM_GATED_WTC). Their OFF state is not 0:
  # every file ran the bomb split at FORC_BOMB_NH_SHARE (0.90) and the respiration lag at
  # CCX_SEAS_T_LAG (2.0 months), and 0 would be a different model (all bomb 14C in the SH; no
  # lag). The generic loop below filled 0 for them, and ccx_seed_unencodable() then moved both
  # to their box midpoints -- so an open-label START from hilda29e began at (0.875, 3), not at
  # the file's own model as the WTC refit's ruling requires. Ask the model's absence contracts
  # (the seas_lag_p rule); both values sit inside their boxes, so a start ENCODES them unseeded.
  for (nm in intersect(names(CCX_PARAM_GATED_WTC), absent)) {
    p[[nm]] <- switch(nm, bomb_share_NH = ccx_bomb_share_nh(p), seas_T_lag = ccx_seas_t_lag(p),
                      stop("ccx_migrate_par_set(): no absence contract for the WTC gate's '", nm, "'"))
    filled <- c(filled, nm)
  }
  for (nm in setdiff(names(CCX_PARAM_GATED_ALL), names(CCX_PARAM_GATED_WTC))) if (nm %in% absent) {
    p[[nm]] <- 0
    filled <- c(filled, nm)
  }

  still <- setdiff(absent, filled)
  if (length(still))
    stop("ccx_migrate_par_set(): no migration contract for: ",
         paste(still, collapse = ", "),
         ". Add one here, next to the split it mirrors.")
  structure(p, migrated = filled)
}

#' Seed the coordinates a MIGRATION could only fill with an unencodable state
#'
#' ⭐ WHY THIS IS SEPARATE FROM THE MIGRATION, AND MUST STAY SEPARATE. They
#' answer two different questions and conflating them is how a measurement turns
#' into a re-baselining:
#'   * `ccx_migrate_par_set()` says WHAT THE ANCESTOR RAN. That is the right
#'     answer for a vector you MEASURE at, and it is why every gate at a stored
#'     mode reads the same before and after a parameter enters the table.
#'   * this says WHERE A SEARCH BEGINS, which the ancestor has no opinion about.
#'
#' It fires ONLY for a coordinate the migration itself reported as filled AND
#' whose filled value cannot be encoded -- e.g. `ent_seas_amp_SH = 0` under
#' `tr = "log"`, where the ancestor's own state has prior probability ZERO
#' ([[runnable_is_not_encodable]]). It names the coordinate and prints BOTH
#' numbers rather than repairing anything quietly.
#'
#' ⛔ IT IS NOT A GENERAL "MAKE THIS ENCODABLE" HELPER. A coordinate that is
#' unencodable WITHOUT having been migrated is a bug in the caller, not a
#' warm-start gap, and is left to `ccx_par_to_unc()` to refuse by name.
#'
#' @param p a list returned by ccx_migrate_par_set() (carries `migrated`)
#' @param who one word naming the caller's use, printed
ccx_seed_unencodable <- function(p, who = "start") {
  for (nm in intersect(attr(p, "migrated"), CCX_PARAM_NAMES)) {
    s <- CCX_PARAM_TABLE[[nm]]
    if (is.finite(.to_unc(p[[nm]], s))) next
    cat(sprintf(paste0("SEEDING %s for the %s: the migration filled %g -- the state ",
                       "the ancestor RAN --\n     which tr = \"%s\" cannot encode. ",
                       "Starting at the table init %g.\n     The ancestor held no ",
                       "opinion about this coordinate.\n"),
                nm, who, p[[nm]], s$tr, s$init))
    p[[nm]] <- s$init
  }
  # A name the FILE HELD (its pins; ccx_mode_par_with_pins) that THIS ARM FITS -- still in
  # the live table after ccx_apply_pins() -- at a value the transform cannot encode
  # (2026-09-20 o: the canonical hilda30s holds w_enso_l2 = 0 on the logit floor; the
  # limb's arm fits it). The held value was OFF, not an opinion: seed at the table init,
  # loudly, exactly as an absent name is. A held name this arm ALSO pins is not in
  # CCX_PARAM_NAMES and is left alone.
  for (nm in setdiff(intersect(attr(p, "held_by_file"), CCX_PARAM_NAMES), attr(p, "migrated"))) {
    s <- CCX_PARAM_TABLE[[nm]]
    if (is.finite(.to_unc(p[[nm]], s))) next
    cat(sprintf(paste0("SEEDING %s for the %s: the file HELD it at %g (a pin of the file, not of ",
                       "this arm) --\n     which tr = \"%s\" cannot encode. Starting at the table ",
                       "init %g.\n     The file held it OFF; this arm fits it.\n"),
                nm, who, p[[nm]], s$tr, s$init))
    p[[nm]] <- s$init
  }
  p
}

#' Refuse a stored mode that is not on THIS build's parameter set, WITH THE REASON
#'
#' ⛔ THE BARE FORM THIS REPLACES IS A NAMED DEFECT. Seven diagnostics carried
#' `stopifnot(identical(md$param_names, CCX_PARAM_NAMES))`, which raises
#' "identical(nm, CCX_PARAM_NAMES) is not TRUE" -- a diagnostic that cannot run
#' and does not say why ([[broken_gate_reports_nothing]]). It has already
#' aborted two gates on this project (see the notes in `diag_joos_irf.R` and
#' `diag_design_gates_at_mode.R`), and after every parameter-set change it
#' aborts ALL of them at once: on 2026-09-01 the ENSO split made all seven dead
#' in the same second.
#'
#' REFUSAL IS OFTEN THE RIGHT ANSWER -- a Hessian at a MIGRATED point is not a
#' Hessian at a mode, and a ridge measured there is not the fitted ridge. What
#' is never right is refusing without saying what changed or what to do. Where
#' a MIGRATED vector genuinely is a legitimate thing to measure, use
#' `ccx_migrate_par_set()` and PRINT what was filled, as `dg_vector()` does.
#'
#' @param md a loaded mode file (needs `$param_names`)
#' @param what one line naming what the caller was about to do, used in the message
ccx_require_param_set <- function(md, what) {
  ccx_gate_require(md, what)
  nm <- md$param_names
  if (identical(nm, CCX_PARAM_NAMES)) return(invisible(TRUE))
  extra <- setdiff(nm, CCX_PARAM_NAMES); missing <- setdiff(CCX_PARAM_NAMES, nm)
  # A PINNED file (2026-09-13) is this build's set MINUS its pins: the consumer
  # must ccx_apply_pins(ccx_mode_pins(md)) BEFORE this check, so say so rather
  # than reporting the held name as "lacking".
  if (length(md$pins) && identical(nm, setdiff(CCX_PARAM_NAMES, names(md$pins))))
    stop(what, ": this mode file is a PINNED arm (", ccx_pin_label(md$pins),
         ", ", length(nm), " free names) and its pins are not applied in this process. ",
         "Call ccx_apply_pins(ccx_mode_pins(md)) first (and unpin with the object it ",
         "returns before scoring a FREE file), then score on the reduced set.")
  stop(what, ": this mode file was fitted on a DIFFERENT parameter set (",
       length(nm), " names, this build fits ", length(CCX_PARAM_NAMES), ").",
       if (length(extra)) paste0(" It carries retired names: ",
                                 paste(extra, collapse = ", "), ".") else "",
       if (length(missing)) paste0(" It lacks: ",
                                   paste(missing, collapse = ", "), ".") else "",
       " Its `par_mode` can be brought forward with ccx_migrate_par_set() -- but a",
       " MIGRATED point is not a mode of this space, so migrate only if measuring",
       " AT a migrated vector is what you mean. Otherwise refit.")
}

# ⚠ DECODES THE NAMES IT WAS GIVEN, not the build's list. It used to iterate
# CCX_PARAM_NAMES unconditionally, which is right only while the parameter SET
# never changes -- and on 2026-08-31, splitting `seas_lag_p` made every stored
# 21-parameter `u_mode` fail here with a bare "subscript out of bounds" raised
# three frames below the actual cause. A named vector carries its own contract;
# honour it, and say so loudly when a name the caller needs is simply absent.
ccx_unc_to_par <- function(u) {
  nm <- names(u)
  # An UNNAMED `u` is the live fitted set in table order, and is NAMED here (2026-10-15, dormant bug 4):
  # it used to take the names without naming `u`, so `u[[n]]` below was "subscript out of bounds".
  # The length must match, or position would assign the values to the wrong names.
  if (is.null(nm)) {
    if (length(u) != length(CCX_PARAM_NAMES))
      stop("ccx_unc_to_par(): an UNNAMED u has length ", length(u), " but this build fits ",
           length(CCX_PARAM_NAMES), " names. Name it, or pass one value per fitted name in table order.")
    nm <- CCX_PARAM_NAMES
    names(u) <- nm
  }
  # a GATED name decodes by its own transform whether or not the gate is open in this process
  # (2026-10-01): decoding a named vector needs each name's transform, not the live fitted set
  spec <- function(n) if (!is.null(CCX_PARAM_TABLE[[n]])) CCX_PARAM_TABLE[[n]] else CCX_PARAM_GATED_ALL[[n]]
  unknown <- setdiff(nm, c(CCX_PARAM_NAMES, names(CCX_PARAM_GATED_ALL)))
  if (length(unknown))
    stop("ccx_unc_to_par(): u carries names this build does not know: ",
         paste(unknown, collapse = ", "),
         ". It was encoded under a different parameter set.")
  out <- lapply(nm, function(n) .from_unc(u[[n]], spec(n)))
  names(out) <- nm
  out
}

ccx_init_unc <- function() ccx_par_to_unc(
  lapply(CCX_PARAM_TABLE, function(s) s$init))

# ---- where a value sits in its own prior's tail ----------------------
#' Prior-tail position of `x` under parameter `name`'s prior, in normal sds.
#'
#' This is the physical-plausibility screen both mode-finders print, and until
#' 2026-08-21 each carried its own copy of it that was WRONG BY A LOT. The old
#' version integrated the prior on a LINEAR grid, `seq(x/1e3, x*1e3,
#' length.out = 4001)`. For `seas_T_amp_NH` at the arm-N mode that is a grid
#' from 0.026 to 25,937 in steps of 6.5 K, against a prior whose +/- 1 sigma
#' spans 11.4-17.9 K -- ONE grid point inside the entire prior. It reported
#' +3.29 where the analytic answer is +2.65, and it reported q10 at -2.01
#' where the analytic answer is -2.43. That matters because the flagged
#' |z| > 3 list is what the 2026-08-21 handoff used to rank the next three
#' pieces of work: `seas_T_amp_NH` was on it and does not belong on it.
#'
#' THE FIX IS TO INTEGRATE IN THE UNCONSTRAINED COORDINATE. Every prior in
#' CCX_PARAM_TABLE has scale O(1) there by construction -- a lognormal in x is
#' a normal in log x with sd = its logsd (0.22-0.4 here), a uniform under
#' `logit` is a standard logistic, a normal under `id` is itself -- so ONE
#' grid spacing and ONE window serve all 21 parameters, which is exactly what
#' the natural scale could not give. The window is centred on the PRIOR's mode,
#' found by a coarse scan, not on `x`: the whole point of the statistic is that
#' `x` may be far out in the tail.
#'
#' The probability integral transform is invariant under the reparameterisation,
#' so this returns the same number the natural-scale calculation would if the
#' natural-scale calculation could be done accurately.
#'
#' @param name parameter name in CCX_PARAM_TABLE
#' @param x    value on the NATURAL scale
#' @return z such that pnorm(z) is the prior CDF at x; NA if the prior is
#'   improper or x is outside its support
CCX_PRIOR_Z_SCAN_HALF <- 60      # coarse-scan half-window, unconstrained units
CCX_PRIOR_Z_SCAN_STEP <- 0.05    # coarse-scan spacing; << the 0.22 narrowest prior sd
CCX_PRIOR_Z_HALF      <- 40      # fine-grid half-window about the prior mode
CCX_PRIOR_Z_STEP      <- 0.002   # fine-grid spacing

ccx_prior_z <- function(name, x, table = CCX_PARAM_TABLE, p = NULL) {
  s <- table[[name]]
  if (is.null(s)) stop("no such parameter: ", name)
  ux <- .to_unc(x, s)
  if (!is.finite(ux)) return(NA_real_)
  # log prior density in the UNCONSTRAINED coordinate, Jacobian included
  ld <- function(u) vapply(u, function(w) {
    v <- .ccx_prior_eval(s, .from_unc(w, s), p) + .log_jac(w, s)
    if (is.finite(v)) v else -Inf
  }, numeric(1))
  # the prior's own mode, found without assuming it is anywhere near x
  cs <- seq(ux - CCX_PRIOR_Z_SCAN_HALF, ux + CCX_PRIOR_Z_SCAN_HALF,
            by = CCX_PRIOR_Z_SCAN_STEP)
  lc <- ld(cs)
  if (!any(is.finite(lc))) return(NA_real_)
  u0 <- cs[which.max(lc)]
  us <- seq(u0 - CCX_PRIOR_Z_HALF, u0 + CCX_PRIOR_Z_HALF, by = CCX_PRIOR_Z_STEP)
  lu <- ld(us)
  d  <- exp(lu - max(lu[is.finite(lu)]))
  d[!is.finite(d)] <- 0
  if (sum(d) <= 0) return(NA_real_)
  # MIDPOINT, not right-edge: plain cumsum(d)/sum(d) evaluates the CDF at the
  # far edge of each cell and leaves a half-cell bias, +0.003 sd at this
  # spacing -- small, but systematic and free to remove.
  cdf <- (cumsum(d) - d / 2) / sum(d)
  # BOTH TAILS ARE CARRIED and the SMALLER one is used. A z of -6 is a lower
  # cumulative of 1e-9; taking it as 1 - (upper cumulative) would evaluate it as
  # the difference of two numbers within 1e-9 of each other and lose it entirely.
  lo <- stats::approx(us, cdf, xout = ux, rule = 2)$y
  hi <- 1 - lo
  if (lo <= hi) stats::qnorm(max(lo, .Machine$double.xmin))
  else         -stats::qnorm(max(hi, .Machine$double.xmin))
}

# ---------------------------------------------------------------------
# CANONICAL MODE / FORCING RECONSTRUCTION (promoted 2026-08-22)
#
# WHY THESE EXIST. Fifty-five files reconstruct "par_mode onto defaults, scale
# the forcing, call ccx_loglik", each with its own copy. On 2026-08-22 a scan of
# those copies found EIGHT that applied `luc_scale` TWICE to the gross-land-sink
# reconstruction -- the forcing's four LUC columns were scaled, and then `eluc`
# was derived from THAT already-scaled forcing and scaled again. The objective
# (ccx_make_logpost, below) never had the bug, so no fit was affected; what was
# affected is every per-stream `gcb_land_sink` those diagnostics reported, and
# the stored decomposition in mode_fit_pump{N,D}.rds that handoffs rank work
# from. Arm N's read -93.71 where the truth is -95.62.
#
# The defect is structurally invited by splitting one quantity across two
# statements. ccx_scaled_forcing() returns the forcing AND its matching annual
# E_LUC from ONE call, so they cannot disagree; ccx_load_mode() returns the
# parameter vector AND the two forcing parameters that have no slot in it.
# `test-luc-scale.R` lints the repo for the old two-statement signature, which
# is what stops it coming back -- a helper nobody is forced to use would not.

#' Load a fitted arm file into a usable parameter vector
#'
#' Returns the MODEL parameters, the two FORCING parameters that
#' `ccx_default_params()` has no slot for (`bomb_total`, `luc_scale`), and the
#' four LIKELIHOOD parameters (`sigma_d14c`, `rep_dC`, `grad_off_co2`,
#' `grad_off_d13c`) -- the six that a bare `intersect(names(p), CCX_PARAM_NAMES)`
#' silently drops, two of which move a trajectory (worth 5.79 ppm of 2024 CO2,
#' `diag_app_params.R`). NOTE the four ENSO coefficients are NOT among them for a
#' CURRENT mode file: they are fields of `ccx_default_params()` and are in
#' `CCX_PARAM_NAMES`, so intersect() picks them up. They ARE among them for a
#' pre-2026-09-01 file, which carries only the retired `gamma_enso` -- which is
#' why the overlay below goes through `ccx_set_enso()` rather than by name.
#'
#' REPOINTED 2026-08-27. The literal `pump_arms/mode_fit_pump<arm>.rds` this
#' used to build is QUARANTINED -- it was fitted before the seasonal-NEP isotope
#' fix (`6bda464`) changed the objective. Resolution now goes through
#' `ccx_mode_file()` (R/paths.R), which is the ONE place the canonical mode is
#' named, and which refuses the retired arm names with the reason rather than a
#' file-not-found.
#'
#' @param arm a mode name known to `ccx_mode_file()` (default: the canonical
#'   mode, `CCX_MODE_CANONICAL`), or a path to a mode file
#' @param base parameter vector to overlay onto
ccx_load_mode <- function(arm = CCX_MODE_CANONICAL, base = NULL) {
  f  <- ccx_mode_file(arm)
  md <- readRDS(f)
  # THE BASE COMES FROM THE FILE'S OWN STRUCTURE (2026-09-08f): a hilda mode
  # overlaid on ccx_default_params() would run as a column, silently.
  if (is.null(base)) base <- ccx_mode_base(md)
  # NO gate requirement here (2026-10-01): this RUNS the file (overlay + err), it never encodes, and
  # ccx_overlay_par() carries the gated model names and `err` the shares, gate open or not.
  # a PINNED file (2026-09-13) carries this build's set MINUS its pins; the held
  # values come back through ccx_mode_par_with_pins() so the overlay below never
  # assigns NULL (which would DELETE the name and drop the model onto its absence
  # default). Before this line hilda30c, the first pinned canonical, was refused here.
  # A registered file may LACK the names in CCX_PARAM_ABSENT_OK (2026-09-13i):
  # ccx_migrate_par_set() below fills what it RAN and the model it drives is
  # absent under the file's own structure, so the loaded vector is the file's.
  if (!ccx_mode_carries_build(md))
    stop("mode file '", basename(f), "' was fitted on a different parameter set (",
         length(md$param_names), " names, this build has ", length(CCX_PARAM_NAMES),
         "); refusing to overlay it silently.",
         if (length(md$param_names) == 22L &&
             "gamma_enso" %in% md$param_names)
           paste0(" This looks like a PRE-2026-09-01 22-parameter mode: `gamma_enso`",
                  " was split into the four `gamma_enso_land_*`/`gamma_enso_ocn_*`",
                  " coefficients. Its `par_mode` still overlays correctly via",
                  " ccx_gamma_enso()'s legacy fallback (land takes the scalar x 0.5,",
                  " ocean takes 0) -- it is the 22-vs-25 `u_mode` DECODING that is",
                  " invalid, so warm-start from `par_mode` and refit rather than",
                  " decoding `u_mode`.")
         else if (length(md$param_names) == 21L &&
             "seas_lag_p" %in% md$param_names)
           paste0(" This looks like a PRE-2026-08-31 21-parameter mode: `seas_lag_p`",
                  " was split into `seas_lag_p_NH`/`_SH`. Its `par_mode` still",
                  " overlays correctly via ccx_seas_lag_p()'s legacy fallback --",
                  " it is the 21-vs-22 `u_mode` DECODING that is invalid, so warm-start",
                  " from `par_mode` and refit rather than decoding `u_mode`.")
         else "")
  pm <- ccx_mode_par_with_pins(md)
  if (length(ccx_mode_absent(md))) pm <- ccx_migrate_par_set(pm)   # 0 = what it RAN, never a seed
  # ccx_overlay_par(), converted on touch (2026-09-30; Ruling B, test-overlay-idiom-lint.R):
  # the same copy and the same ENSO resolver as the bare loop it replaces (a pre-2026-09-01
  # `par_mode` carries the retired scalar, which the resolver reads), plus the GATED model
  # names by the file's structure and the deletion assertion. `pm` is migrated when anything
  # is absent (above), so the overlay's own migration is a no-op.
  p  <- ccx_overlay_par(base, pm)
  p$pump_mode  <- md$pump_mode
  # `hml_bound` IS CARRIED because the driver overrides CCX_PARAM_TABLE$h_ml
  # IN-PROCESS to [85, 120], and a logpost recomputed under the default band is
  # off by ~1.1 while `u_mode` stops decoding (max |u - u(par_mode)| = 1.7).
  # It is NULL on the older arm files, which did not record it -- callers that
  # recompute a logpost must assert on it rather than assume the band.
  err <- list(sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC,
              grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c)
  # the D3 shares (2026-09-30, objective #14): an open-label file's fitted pair moves the
  # two GCB rows; a caller feeding this `err` to ccx_loglik() must get them. Absent = #13.
  .sh <- ccx_imb_shares(pm)
  if (!is.null(.sh)) { err$imb_share_land <- .sh[["land"]]; err$imb_share_ocean <- .sh[["ocean"]] }
  # the structure's likelihood switches (objective #17, 2026-10-06): absent = nothing added
  err <- ccx_err_with_struct(err, p)
  list(p = p, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total,
       err = err, hml_bound = md$hml_bound, md = md, file = f)
}

# THE COLUMN-MULTIPLY PATHS CANNOT CARRY THE "luc" SINK ARM (2026-08-23c).
# Both ccx_scaled_forcing() and ccx_make_logpost() apply `luc_scale` by
# multiplying an already-built base forcing's LUC columns, which is exact ONLY
# because every LUC quantity is LINEAR in the annual series. The "luc" arm of
# the artificial mid-century sink subtracts a fixed 2.5 GtC/yr from that series,
# making the columns AFFINE -- so the multiply would rescale the artificial
# perturbation along with the flux and the three arms would stop being
# magnitude-matched (2.5 -> 2.5 * 0.8984 at the adopted mode, a 10 % error in
# the one quantity the comparison holds fixed).
#
# It ERRORS rather than correcting itself, because the correction has a right
# answer that depends on what the caller meant, and a helper that guesses is how
# `luc_scale` came to be applied twice in eight places (see above).
# Build that arm with ccx_build_forcing(luc_scale =, sink_mode = "luc") directly.
# The "foss" and "ocean" arms leave the LUC columns untouched and are unaffected.
.ccx_assert_luc_arm_safe <- function(luc_scale) {
  if (CCX_ARTIFICIAL_SINK_RATE != 0 &&
      CCX_ARTIFICIAL_SINK_MODE == "luc" && luc_scale != 1)
    stop("the \"luc\" arm of the artificial sink cannot ride a luc_scale ",
         "COLUMN MULTIPLY (luc_scale = ", luc_scale, "): the columns are ",
         "affine, not linear, so the 2.5 GtC/yr perturbation would be rescaled ",
         "too. Build it with ccx_build_forcing(luc_scale =, sink_mode = ",
         "\"luc\") instead.")
  invisible(TRUE)
}

.ccx_luc_arm_active <- function()
  CCX_ARTIFICIAL_SINK_RATE != 0 && CCX_ARTIFICIAL_SINK_MODE == "luc"

# ---------------------------------------------------------------------
# THE "luc" ARM'S AFFINE COLUMN PATH (2026-08-24c)
#
# WHAT CHANGED AND WHY IT IS NOT A GUESS. The refusal above was written because
# "the correction has a right answer that depends on what the caller meant".
# It does -- and ccx_build_forcing() has ALREADY MADE that choice and documents
# it (R/forcing.R @param luc_scale: "the `luc` arm subtracts from the land-use
# series AFTER `luc_scale` has been applied"). So the builder's columns are
#
#     F_luc(s) = s * L - S            L = the unscaled series, S = the arm
#
# which is affine in s, not linear -- exactly why the plain multiply is wrong.
# But affine is still a closed form, so the fast path does not need a rebuild:
# hold the arm-OFF base (columns L) and the perturbation d = (base - base0) =
# -S, and compose  s * L + d. Constant-time, and EXACT rather than approximate.
# test-luc-scale.R gates it against ccx_build_forcing() and MUTATION-TESTS the
# gate by scaling the perturbation too -- the precise error the refusal existed
# to prevent.
#
# THE REFUSAL IS NOT DELETED. It still fires for a caller that cannot supply the
# scenario/years needed to rebuild the arm-off base, which is the only case in
# which the composition genuinely cannot be formed.
#
# Returns a list of two closures plus the annual E_LUC table to carry `year`:
#   $cols(s)  named list of the four LUC columns at luc_scale = s
#   $eluc(s)  the annual E_LUC vector at luc_scale = s
# For every arm EXCEPT "luc" these are the original plain multiply, bit-for-bit.
.ccx_make_luc_scaler <- function(base, scenario = "historical",
                                 years = c(1750, 2024)) {
  eluc_base <- ccx_forcing_eluc_annual(base)
  nm <- function(x) { names(x) <- CCX_LUC_COLS; x }
  if (!.ccx_luc_arm_active())
    return(list(
      cols = function(s) nm(lapply(CCX_LUC_COLS, function(cc) base[[cc]] * s)),
      eluc = function(s) eluc_base$eluc * s,
      eluc_tbl = eluc_base, affine = FALSE))
  if (is.null(scenario) || is.null(years)) .ccx_assert_luc_arm_safe(0)
  base0 <- ccx_build_forcing(scenario, years, prod_c14 = 0,
                             bomb_total_kmol = CCX_BOMB_REF, sink_rate = 0)
  eluc0 <- ccx_forcing_eluc_annual(base0)
  stopifnot(identical(eluc0$year, eluc_base$year))
  d_cols <- nm(lapply(CCX_LUC_COLS, function(cc) base[[cc]] - base0[[cc]]))
  d_eluc <- eluc_base$eluc - eluc0$eluc
  # The arm must actually be PRESENT in `base`, or this composition silently
  # degrades to the plain multiply and the run would look like an arm it is not.
  if (max(abs(d_eluc)) <= 0)
    stop("the \"luc\" arm is active (rate ", CCX_ARTIFICIAL_SINK_RATE,
         ") but the supplied base forcing carries no perturbation: its E_LUC is ",
         "identical to the arm-off build. The base was built with the arm OFF.")
  list(
    cols = function(s) nm(lapply(CCX_LUC_COLS,
                                 function(cc) base0[[cc]] * s + d_cols[[cc]])),
    eluc = function(s) eluc0$eluc * s + d_eluc,
    eluc_tbl = eluc_base, affine = TRUE)
}

#' A forcing with `luc_scale`/`bomb_total` applied, AND its matching annual E_LUC
#'
#' Returns `list(F = , eluc = )`. Take BOTH from here and pass `eluc` straight to
#' `ccx_loglik(luc = )`. Do NOT re-scale the returned `eluc`: it is already the
#' model's own scaled land-use flux, which is exactly what the `gcb_land_sink`
#' term's gross reconstruction wants.
#'
#' @param sp spinup, used only for `prod_c14`; pass NULL to leave c14_cosmo alone
#' @param base an already-built base forcing at luc_scale 1 / bomb_total ref, to
#'   avoid rebuilding it per draw. Built here when NULL.
ccx_scaled_forcing <- function(sp = NULL, years = c(1750, 2024), luc_scale = 1,
                               bomb_total = CCX_BOMB_REF, scenario = "historical",
                               base = NULL) {
  F <- if (is.null(base))
    ccx_build_forcing(scenario, years, prod_c14 = 0, bomb_total_kmol = CCX_BOMB_REF,
                      enso_index = if (is.null(sp)) "demean" else ccx_enso_index_of(sp$params),
                      aod_mode = if (is.null(sp)) "legacy" else ccx_aod_mode_of(sp$params),
                      nuc_share = if (is.null(sp)) "constant" else ccx_nuc_share_of(sp$params))
  else base
  if (!is.null(sp)) F$c14_cosmo <- sp$prod_c14
  F$c14_bomb <- F$c14_bomb * (bomb_total / CCX_BOMB_REF)
  # The single scaling, and the E_LUC derived from the UNSCALED series before it
  # -- equivalently, from the scaled columns with no second multiply. Both give
  # the same answer; doing it in one place is what makes that a fact rather than
  # a coincidence between two statements.
  LUC  <- .ccx_make_luc_scaler(F, scenario, years)
  eluc <- LUC$eluc_tbl
  eluc$eluc <- LUC$eluc(luc_scale)
  cols <- LUC$cols(luc_scale)
  for (cc in CCX_LUC_COLS) F[[cc]] <- cols[[cc]]
  attr(F, "luc_scale") <- luc_scale
  list(F = F, eluc = eluc)
}

# ---------------------------------------------------------------------
# PER-DIRECTION HESSIAN (promoted 2026-08-23 from calibration/recompute_hessian.R)
#
# WHY IT IS NOT A SCALAR STEP. `run_modefind_pump_arms.R` took its Hessian with
# ONE step, ARM_HESS_EPS = 3e-4, in every direction. Measured at the 2026-08-23
# mode, that is 250x too small for `h_ml`, 167x for `kz` and 67x for
# `gamma_enso`, while being about right for the stiff directions -- so `sd_unc`,
# `cov`, `logdet_negH` and any Laplace evidence built on it were wrong in exactly
# the soft directions the evidence is most sensitive to, and NOTHING flagged it
# (memory ccx_hess_step_sd). The fix is one step per direction, sized to that
# direction's own posterior sd: eps_k = frac * sd_k, sd_k = 1/sqrt(-d2/du_k^2).
#
# WHY IT LIVES HERE. Until today the correct version existed only in
# `recompute_hessian.R`, as a manual second step someone had to remember after
# every refit -- and forgetting it silently shipped the scalar version. Both that
# script and the refit driver now call this, so there is ONE implementation. That
# is the same argument as ccx_scaled_forcing(): the duplication is the defect.
#
# Mixed steps are fine in a central cross-difference -- the a-direction is
# differenced with eps_a, the b with eps_b, and the denominator carries both.
#
# @param lp   log-posterior closure, as ccx_make_logpost() returns
# @param u    mode on the unconstrained scale (named)
# @param verbose print the per-direction table
# @return list(H, eps, sd_diag, curvature_by_step, verify, no_plateau, unstable)
CCX_HESS_EPS_GRID   <- c(1e-5, 3e-5, 1e-4, 3e-4, 1e-3, 3e-3, 1e-2, 3e-2, 1e-1, 3e-1)
CCX_HESS_STABLE_TOL <- 0.02    # max relative disagreement with EITHER neighbour
CCX_HESS_EPS_FRAC   <- 0.10    # step as a fraction of the direction's posterior sd
# NO PLATEAU (RULED 2026-10-13, Marcus: "Most-stable step (Recommended)"; CHANGELOG 2026-10-13 c). A direction with no
# 2 % plateau takes the INTERIOR GRID STEP whose curvature disagrees least with its neighbours (the plateau test's own
# metric), and stays flagged. It used to take the fixed CCX_HESS_FALLBACK, 3e-4 in u, which under the WTC label reads
# curvature noise of ~1e-5 / (3e-4)^2 ~ 110: more than kz_deep_frac's own curvature (~ -2.4), so id 17's Hessian lost
# negative-definiteness on that step alone (objective_noise_floor_20261013_wtc.log). The fixed value is now used only
# when NO interior triple is finite (every step leaves the feasible region).
CCX_HESS_FALLBACK   <- 3e-4
# THE REPRODUCE GATES (RULED 2026-10-13, Marcus: "5e-5, all three (Recommended)"; CHANGELOG 2026-10-13 c): does a STORED
# point reproduce through another evaluation path? promote_multistart_mode.R GATE 4 (logpost), recompute_hessian.R
# GATE 1 (logpost) and fit_iav_module.R GATE 0 (each row, the dg path) read this ONE value. History: a literal 1e-6
# until 2026-10-07, then 1e-5 (~6x #17's measured per-row floor). Under label hilda_csl3v0kaidgbemwtc the floor is
# ~4-5x larger in the same delta13C rows (per-row moves to 7.9e-6 under 1e-12 nudges; logpost spikes to 1.2e-5), so
# 1e-5 stopped the WTC landing at 1.18e-5 on noise. 5e-5 is ~6x that floor again. Power: four real defects move the
# rows by 2.35-1.0e3 (outputs/diagnostics/wtc_landing_20261013/gate0_diagnosis/).
CCX_REPRO_TOL       <- 5e-5

ccx_hessian_per_direction <- function(lp, u, verbose = TRUE) {
  nm <- names(u); n <- length(u); lp0 <- lp(u)
  if (!is.finite(lp0)) stop("log-posterior is not finite at the supplied mode")

  diag_at <- function(v) vapply(seq_len(n), function(k) {
    e <- numeric(n); e[k] <- v[k]
    fp <- lp(u + e); fm <- lp(u - e)
    if (!is.finite(fp) || !is.finite(fm)) return(NA_real_)
    (fp - 2 * lp0 + fm) / v[k]^2
  }, numeric(1))

  # 1. curvature vs step, to find each direction's stable plateau
  D <- sapply(CCX_HESS_EPS_GRID, function(e) diag_at(rep(e, n)))
  dimnames(D) <- list(nm, format(CCX_HESS_EPS_GRID, scientific = TRUE))
  plateau <- function(k) {
    d <- D[k, ]; best_s <- Inf; best_i <- NA_real_
    for (i in seq_along(d)) {
      if (i == 1L || i == length(d)) next
      tri <- d[c(i - 1L, i, i + 1L)]
      if (anyNA(tri) || !all(is.finite(tri)) || tri[2] == 0) next
      s <- max(abs(tri - tri[2])) / abs(tri[2])
      if (s < CCX_HESS_STABLE_TOL) return(c(d = tri[[2]], idx = i, best = NA_real_))
      if (s < best_s) { best_s <- s; best_i <- i }      # the most-stable interior step, for the no-plateau case
    }
    c(d = NA_real_, idx = NA_real_, best = best_i)
  }
  PL <- t(vapply(seq_len(n), plateau, numeric(3))); rownames(PL) <- nm
  SDV <- ifelse(PL[, "d"] < 0, 1 / sqrt(-PL[, "d"]), NA_real_)
  eps <- CCX_HESS_EPS_FRAC * SDV
  no_plateau <- nm[is.na(eps)]
  # no plateau: the most-stable interior grid step (ruled 2026-10-13); the fixed fallback only when none is finite.
  # ⚠ A STABLE but NON-NEGATIVE plateau (a direction that is not a maximum) also has no sd, so it lands here too; the
  # ruling does not cover it, and it keeps the fixed step it always had, labelled as what it is.
  eps_fb <- ifelse(is.na(PL[, "best"]), CCX_HESS_FALLBACK, CCX_HESS_EPS_GRID[PL[, "best"]])
  fallback_how <- stats::setNames(ifelse(!is.na(PL[, "idx"]), "fixed_nonneg_plateau",
                                         ifelse(is.na(PL[, "best"]), "fixed_none_finite", "most_stable")), nm)[no_plateau]
  eps[is.na(eps)] <- eps_fb[is.na(eps)]
  names(eps) <- nm

  # 2. verify the chosen step at eps/3 and 3 eps
  V <- cbind(lo = diag_at(eps / 3), mid = diag_at(eps), hi = diag_at(eps * 3))
  rownames(V) <- nm
  vspread <- apply(V, 1, function(r)
    if (anyNA(r) || r[2] == 0) Inf else max(abs(r - r[2])) / abs(r[2]))
  unstable <- nm[!(vspread < CCX_HESS_STABLE_TOL)]

  # 3. the full Hessian, mixed steps
  H <- matrix(NA_real_, n, n)
  for (a in seq_len(n)) for (b in a:n) {
    ea <- eb <- numeric(n); ea[a] <- eps[a]; eb[b] <- eps[b]
    H[a, b] <- H[b, a] <-
      (lp(u + ea + eb) - lp(u + ea - eb) - lp(u - ea + eb) + lp(u - ea - eb)) /
      (4 * eps[a] * eps[b])
  }
  dimnames(H) <- list(nm, nm)

  if (verbose) {
    cat(sprintf("  eps = %.2f x each direction's own posterior sd, verified at eps/3 and 3 eps\n",
                CCX_HESS_EPS_FRAC))
    cat(sprintf("  %-16s %10s %11s %11s\n", "parameter", "sd (unc)", "eps (u)", "curvature"))
    for (k in seq_len(n))
      cat(sprintf("  %-16s %10.5f %11.3e %11.5g%s\n", nm[k], SDV[k], eps[k], V[k, "mid"],
                  if (nm[k] %in% unstable) "  ** no stable step" else ""))
    if (length(no_plateau))
      cat(sprintf("  ** no plateau (%.0f %% test), so the most-stable grid step (the fixed %.0e only where none is finite): %s\n",
                  100 * CCX_HESS_STABLE_TOL, CCX_HESS_FALLBACK,
                  paste(sprintf("%s %.0e (%s)", no_plateau, eps[no_plateau], fallback_how), collapse = ", ")))
  }
  list(H = H, eps = eps, sd_diag = SDV, curvature_by_step = D, verify = V,
       no_plateau = no_plateau, fallback_how = fallback_how, unstable = unstable, eps_frac = CCX_HESS_EPS_FRAC)
}

# ---- THE DECLARED STRUCTURE (2026-09-06d, Marcus's ruling) -----------
#' The HILDA HS/HD + K(z) structure at its DECLARED values, applied to a base
#' parameter list. ONE definition, read by the refit driver AND by
#' make_port_targets.R, so the port gate and the run cannot disagree about
#' which structure the objective was measured on. `struct` is the label the
#' run carries (`CCX_MS_STRUCT`): "" = the 32-box column exactly as before;
#' "hilda" = the declared values below. Anything else is an error by name.
#' The four FITTED structure parameters (kz_deep_frac, hs_asx_frac, h_hs, and
#' since 2026-09-08d u_hs) are NOT set here: they come from the vector, through
#' CCX_PARAM_TABLE. u_hs's former declared value is CCX_U_HS_DECLARED (38),
#' which the migration fills for ancestors and ccx_default_params() carries.
#' Sources: notes/caveats_declared_parameters.md (each value's provenance).
CCX_STRUCT_HILDA <- list(hs_frac = 0.16, tau_q = 538, sst_hs = 2,
                         q_attach_from = 1L, kz_zscale = 253)
#' The equatorial cell's data product (data-raw/build_eq_cell_targets.R), read
#' lazily and cached -- the ccx_u_hs_prior() idiom. It carries the cell's PINNED
#' GEOMETRY (ccx_struct_hilda_eq()), the B1 reservoir target (R/likelihood.R) and
#' the W0 prior (CCX_PARAM_TABLE$w_eq), so no number of the cell is typed twice.
ccx_eq_cell_obs <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) cache <<- readRDS(ccx_path("data", "obs_eq_cell.rds"))
    cache
  }
})
#' THE "hilda_eq" STRUCTURE (2026-09-13g): HILDA's declared block PLUS the
#' equatorial cell's OBSERVED geometry, every value read from the product --
#' eq_frac from the SOM-FFN mask (per hemisphere, of the MODEL's hemispheric
#' area), h_eq the Holte annual mean (ruling 6), sst_eq and its Nino3.4 slope
#' from ERSSTv5 (both hemispheres together: ONE parameter set, ruling 1), alk_eq
#' the GLODAP surface target, k_eq = 2 (ruling 2). `w_eq` and `gamma_eq` are
#' NOT set here: they are the cell's two FITTED names and come from the vector.
#' A function, not a literal list, because the table is built before R/paths.R
#' is sourced (the prior-loader precedent).
CCX_EQ_K_EQ <- 2L
ccx_struct_hilda_eq <- function() {
  o <- ccx_eq_cell_obs()
  c(CCX_STRUCT_HILDA,
    list(eq_frac_NH  = unname(o$eq_frac$value[["NH"]]),   # the prereg's $value: band area /
         eq_frac_SH  = unname(o$eq_frac$value[["SH"]]),   #   the product's OWN hemispheric area
         h_eq        = o$h_eq$both$mean_dt,
         sst_eq      = o$sst_eq$both$annual_mean_C,
         sst_eq_enso = o$sst_eq$both$beta_monthly,
         alk_eq      = o$alk_eq$both$target,
         k_eq        = CCX_EQ_K_EQ))
}
#' The tropical box's data product (data-raw/build_tr_box_targets.R), read
#' lazily and cached -- the ccx_eq_cell_obs() idiom. It carries the box's
#' PINNED GEOMETRY and the three SST overrides of ccx_struct_hilda_tr(), plus
#' PT6's DIC check target (calibration/diag_tr_box_probe.R).
ccx_tr_box_obs <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) cache <<- readRDS(ccx_path("data", "obs_tr_box.rds"))
    cache
  }
})
#' THE "hilda_tr" STRUCTURE (2026-09-14f, prereg_2026-09-14f): the "hilda_eq"
#' block PLUS the tropical surface box's OBSERVED geometry, every value read
#' from data/obs_tr_box.rds -- tr_frac from the 26 degC ERSSTv5 isotherm on the
#' SOM-FFN grid (ruling R2, of the product's own hemispheric area, cell
#' removed), h_tr the Holte annual mean (the h_eq convention), sst_tr and its
#' Nino3.4 slope (both hemispheres area-weighted: ONE parameter set, R1),
#' alk_tr the GLODAP <= 50 m target; q_tr STAYS the default 0 (R4).
#' ⚠ THREE OVERRIDES ride with it, each a MEASUREMENT the typed value lacked:
#'   sst_NH / sst_SH  <- the RESIDUAL mixed layer's SST (LS minus tr minus eq),
#'                       re-based to 1850-1900: 17.18 / 15.35 for the typed 18 / 16
#'                       (which were ~0.7 warm; the first SOURCED values);
#'   sst_eq           <- the cell RE-BASED to 1850-1900 (26.33 for hilda_eq's
#'                       27.04, the un-re-based climatology, which hilda_eq
#'                       KEEPS so the first array stays reproducible).
#' Every surface SST in this structure is on the same 1850-1900 basis as the
#' HadSST4 anomaly it is added to, and every Nino3.4 SST slope is the EXCESS
#' over that anomaly's own ENSO response (R5, resolved by measurement 09-14 g:
#' tr ~0, the cell ~0.74). A function, as ccx_struct_hilda_eq() is.
ccx_struct_hilda_tr <- function() {
  o <- ccx_tr_box_obs()
  w <- o$tr_frac$value / sum(o$tr_frac$value)            # area weights, both-hemisphere means
  blk <- ccx_struct_hilda_eq()
  # ⚠ ASSIGNED BY NAME, not c()'d: `sst_eq` is in both blocks and `[[` on a
  # list with a duplicated name returns the FIRST -- the un-re-based value.
  add <- list(tr_frac_NH  = unname(o$tr_frac$value[["NH"]]),
         tr_frac_SH  = unname(o$tr_frac$value[["SH"]]),
         h_tr        = o$h_tr$both$mean,
         sst_tr      = unname(sum(w * o$sst$tr[c("NH", "SH")])),
         # THE EXCESS slope (2026-09-14 g, review §A1): the box's Nino3.4 SST
         # response OVER the hemispheric HadSST4 anomaly every surface box
         # already receives (absolute annual +0.27/+0.24 -> excess +0.002/+0.015:
         # the band warms WITH its hemisphere, nothing local). The absolute
         # monthly slope (0.20) double-counted the hemispheric response.
         sst_tr_enso = unname(sum(w * c(o$sst_excess$tr$NH$beta_annual, o$sst_excess$tr$SH$beta_annual))),
         alk_tr      = o$alk_tr$both$target,
         # the overrides
         sst_NH      = unname(o$sst$ml[["NH"]]),
         sst_SH      = unname(o$sst$ml[["SH"]]),
         sst_eq      = {
           e <- ccx_eq_cell_obs()$eq_frac$value
           unname(sum(e / sum(e) * o$sst$eq[c("NH", "SH")]))
         },
         # ... and the cell's slope on the SAME footing under this label: the
         # annual EXCESS (0.67/0.83 -> ~0.74) for hilda_eq's absolute monthly
         # 0.97, which obs_eq_cell.rds keeps so the first array reproduces.
         sst_eq_enso = {
           e <- ccx_eq_cell_obs()$eq_frac$value
           unname(sum(e / sum(e) * c(o$sst_excess$eq$NH$beta_annual, o$sst_excess$eq$SH$beta_annual)))
         })
  blk[names(add)] <- add
  stopifnot(!anyDuplicated(names(blk)))
  blk
}
#' THE "hilda_c" STRUCTURE (2026-09-14 h; the CONSTANTS BATCH the 09-14 g review
#' ruled into the option-E refit, each value RULED by Marcus 09-14 h): the
#' "hilda" block with three of its typed / derived constants replaced by
#' MEASURED ones, every value read from data/obs_tr_box.rds (the same product
#' and re-basing hilda_tr uses) or stated as a ruled choice:
#'   sst_NH / sst_SH  <- the WHOLE-LS mixed layer's annual-mean SST (|lat| < 57.14,
#'                       ERSSTv5 1991-2020, area-weighted), RE-BASED to 1850-1900 by
#'                       the HadSST4 hemispheric anomaly: 22.3 / 18.7 for the typed
#'                       18 / 16 (which were an effective equilibration temperature,
#'                       ~4 K cold). ⚠ NOT hilda_tr's 17.18 / 15.35: that is the
#'                       RESIDUAL ML (LS minus tr minus eq), the wrong box for a
#'                       structure without the tropical box.
#'   hs_frac          <- the ocean's ACTUAL fraction poleward of 57.14 deg, area-
#'                       weighted over the two hemispheres (NH 0.126 / SH 0.130 ->
#'                       0.128) for the uniform-sphere 0.16. ⚠ The BOUNDARY stays
#'                       57.14 deg (the product's mask); only the AREA share moves.
#'   alpha_photo_eps  <- 15.6 permil, the MID-BRACKET of the biosphere-wide value
#'                       (Lloyd & Farquhar 1994 total 14.8 at 21 % C4 -- "25 %" until the
#'                       2026-10-12 correction; Still 2003 16.5 -> 14.8-16.5; the "15-18"
#'                       once quoted here is in neither Still nor Suits) for the C3-only 18 the
#'                       ledger keeps (ALPHA_PHOTO_EPS stays provisional until a
#'                       refit adopts). A RULED CHOICE, not a measurement.
#' A NEW LABEL rather than an edit of CCX_STRUCT_HILDA: that block is what every
#' registered mode's base is built from, and an in-place change would move them
#' all without error. Under "hilda" every registered file stays bit-exact.
CCX_ALPHA_PHOTO_EPS_BIOSPHERE <- 15.6   # permil; the ruled mid-bracket (09-14 h)
ccx_struct_hilda_c <- function() {
  o <- ccx_tr_box_obs()
  g <- o$geom
  a <- c(NH = g$NH$hemi_ocean_m2, SH = g$SH$hemi_ocean_m2)
  blk <- CCX_STRUCT_HILDA
  add <- list(sst_NH  = unname(g$NH$sst_ls_clim + o$rebase_C[["NH"]]),
              sst_SH  = unname(g$SH$sst_ls_clim + o$rebase_C[["SH"]]),
              hs_frac = unname(sum(a * c(g$NH$hs_frac, g$SH$hs_frac)) / sum(a)),
              alpha_photo_eps = CCX_ALPHA_PHOTO_EPS_BIOSPHERE)
  blk[names(add)] <- add
  stopifnot(!anyDuplicated(names(blk)))
  blk
}
ccx_parse_seas_ml <- function(seas_ml) {
  v <- as.character(seas_ml)
  if (length(v) != 1L || is.na(v) || !grepl("^[01]$", v))
    stop("ccx_apply_structure(): `seas_ml` must be 0 (OFF) or 1 (ON); got '",
         paste(seas_ml, collapse = ","), "' (CCX_MS_SEAS_ML if it came from the environment).")
  as.integer(v)
}
#' THE "hilda_cl2" / "hilda_cl3" STRUCTURES (2026-09-17 k / l): hilda_c + the
#' Nino3.4 return LIMB (review avenue 1; notes/prereg_2026-09-17k_l2_enso_limb_refit.md).
#' Two structure constants, never fitted: k_l2 = the RETURN LAYER the limb
#' exchanges the mixed layer with -- 2 (117-190 m at the 09-17 canonical's grid,
#' 121-194 m on hilda31w's; ruling R2 as preregistered) or 3 (190-292 m then,
#' 194-295 m on hilda31w's; the s7 amendment, RULED 09-17 l
#' after the unrefitted probe: at k = 2 the floor clips a third of the response
#' and the observed slope needs 37 Sv/index, above Meinen's 14-25; at k = 3 it
#' needs 19.3, inside) -- and w0_l2 = the Meinen 2001 mean upwelling from
#' obs_eq_cell.rds$w0_prior (27 Sv; ruling R1 -- it sets the limb's FLOOR only).
#' THE LAYER IS PART OF THE LABEL (ruled 09-17 l): one table, CCX_L2_RETURN_LAYERS,
#' is the only place a layer number lives, so every array, port target and output
#' directory NAMES its layer and a k = 2 read is reproducible by label. NEW LABELS,
#' not an edit of hilda_c: every registered file is bit-exact under its own label
#' (hilda / hilda_c stay k_l2 = 0 -- the limb ABSENT).
#' 2026-09-20 (o), ruling 3: "hilda_csl3" = the limb (k = 3) on top of hilda_cs -- the
#' shipped structure since hilda30s (the seasonal ML's NH cycle flat). The BASE of each
#' limb label is the second table; hilda_cl2 / hilda_cl3 stay on hilda_c (bit-exact for
#' the 09-17 k/l probe and the 09-18 b array).
CCX_L2_RETURN_LAYERS <- c(hilda_cl2 = 2L, hilda_cl3 = 3L, hilda_csl3 = 3L)
CCX_L2_BASE_STRUCT   <- c(hilda_cl2 = "hilda_c", hilda_cl3 = "hilda_c", hilda_csl3 = "hilda_cs")
ccx_struct_hilda_cl <- function(label) {
  k <- CCX_L2_RETURN_LAYERS[[label]]          # errors by name on an unknown label
  blk <- switch(CCX_L2_BASE_STRUCT[[label]], hilda_c = ccx_struct_hilda_c(), hilda_cs = ccx_struct_hilda_cs())
  add <- list(k_l2 = k, w0_l2 = unname(ccx_eq_cell_obs()$w0_prior$mean_sv))
  blk[names(add)] <- add
  stopifnot(!anyDuplicated(names(blk)))
  blk
}
#' THE "hilda_cs" STRUCTURE (2026-09-19 l; Marcus: "do the test" / "yes"): hilda_c
#' with the seasonal mixed layer's NH CYCLE FLATTENED (ml_nh_cycle = 0 -- the ML
#' entrains in the SH only; R/model.R ccx_seas_ml_shapes). Ruling 1's test in its
#' REFIT form: whether the ML's ~6-10 log-unit price against ML-off, all on the NH
#' seasonal rows, is the mechanism's or its NH driver's. A NEW LABEL, not an edit
#' of hilda_c (every registered file stays bit-exact); meaningful only at seas_ml 1
#' (at 0 the flag is inert and the block equals hilda_c's for the model).
ccx_struct_hilda_cs <- function() {
  blk <- ccx_struct_hilda_c()
  blk$ml_nh_cycle <- 0L
  stopifnot(!anyDuplicated(names(blk)))
  blk
}
#' THE "hilda_csl3v0" STRUCTURE (2026-09-28; Marcus: "phi = 0 only", no FACE term): the
#' shipped hilda_csl3 with the VEGETATION-CAPACITY LOOP OFF (npp_veg_frac = 0). The loop
#' NPP = npp0 [(1 - phi) + phi veg/veg0] f(CO2) multiplies the land's equilibrium CO2
#' response by 1/(1 - phi) = 2x at phi 0.5, and it is what carries the pulse's gap to Joos
#' (calibration/diag_pulse_land_attribution.R, CHANGELOG 2026-09-27 e). Land-use loss of
#' capacity is still made permanent by the CLEARED-AREA term (npp0 x (1 - cleared)), which
#' does not depend on phi. A NEW LABEL, not an edit: every registered file stays bit-exact.
ccx_struct_hilda_csl3v0 <- function() {
  blk <- ccx_struct_hilda_cl("hilda_csl3")
  blk$npp_veg_frac <- 0
  stopifnot(!anyDuplicated(names(blk)))
  blk
}
#' THE "hilda_csl3v0k" STRUCTURE (2026-09-28; Marcus): hilda_csl3v0 (phi = 0) with the
#' evidence-based SHAPE prior on fert_k switched on (ccx_fert_k_prior(); Varney 2024 +
#' Walker 2021, CMIP6 as comparison). The SIZE of the response stays free for the record.
#' The flag is read by fert_k's table prior only; the model never sees it.
ccx_struct_hilda_csl3v0k <- function() {
  blk <- ccx_struct_hilda_csl3v0()
  blk$fert_k_prior <- 1L
  stopifnot(!anyDuplicated(names(blk)))
  blk
}
#' ARM A of the NPP_GLOBAL_PI option-4 test (2026-09-29, Marcus): hilda_csl3v0k
#' with the AOD background removed (aod_mode "anomaly", RULED the improved
#' version the same day). The new BASELINE the NPP arms are compared against.
ccx_struct_hilda_csl3v0ka <- function() {
  blk <- ccx_struct_hilda_csl3v0k()
  blk$aod_mode <- CCX_AOD_MODE_CODES[["anomaly"]]
  stopifnot(!anyDuplicated(names(blk)))
  blk
}
#' ARM B1: arm A + the modern-NPP likelihood row (ccx_loglik(npp =)), NPP_GLOBAL_PI
#' FIXED at 60 -- only fertilisation and clearing can answer the row. ⚠ AN
#' OBJECTIVE CHANGE: compare with arm A on LIKELIHOOD minus the npp_modern row.
ccx_struct_hilda_csl3v0kan <- function() {
  blk <- ccx_struct_hilda_csl3v0ka()
  blk$npp_row <- 1L
  stopifnot(!anyDuplicated(names(blk)))
  blk
}
#' THE "hilda_csl3v0kai" STRUCTURE (2026-09-30, Marcus: "Go with 0-1 m; build the
#' inert pool"): arm A with the INERT SOIL CARVE-OUT on. soil_inert_frac =
#' SOIL_INERT_FRAC (Copard 2025, 0-1 m, 0.195) of the passive pool's stock is
#' radiocarbon-free and exchanges with nothing (ccx_litter_slow_eff(),
#' aux$soil_inert). No objective change: the likelihood reads no absolute soil
#' stock. A NEW LABEL, not an edit: arm A and every registered file stay bit-exact.
ccx_struct_hilda_csl3v0kai <- function() {
  blk <- ccx_struct_hilda_csl3v0ka()
  blk$soil_inert_frac <- ccx_const("SOIL_INERT_FRAC")
  stopifnot(!anyDuplicated(names(blk)))
  blk
}
#' THE "hilda_csl3v0kaidgb" STRUCTURE (2026-09-30; OBJECTIVE #14): hilda_csl3v0kai with
#' D2 and D3 FITTED (Marcus 2026-09-30: rulings D2 / D3 and the design sub-rulings of
#' 09-30 l/m). d = the N-retention flux `ndep_ret`; g = the sign-free greening term
#' `npp_tsens`; b = the budget-imbalance allocation, `imb_share_land` and
#' `imb_share_ocean_rest` (I(t) the 11-yr smooth of imbalance + cement). The block
#' changes NOTHING the model reads: it OPENS THE GATE (CCX_PARAM_GATED) and the four
#' names' fitted values do the rest. Under every other label they are held OFF, so
#' arm A, the kai label and every registered file stay bit-exact.
#' OBJECTIVE #14 = #13 + the D3 rows' moved targets + the four names' priors (and the
#' shares' logit Jacobians), and it exists ONLY under this label.
#' `imb_treatment` / `imb_with_cement` RECORD the ruled I(t) ("Smooth + cement",
#' 09-30 l). The likelihood reads LIK_IMB_TREATMENT / LIK_IMB_WITH_CEMENT at call time,
#' so the logpost REFUSES a draw where those globals disagree with the label: a label
#' has to mean one objective. ⚠ The NAME was suggested by the 09-30c handoff and is
#' the author's call.
ccx_struct_hilda_csl3v0kaidgb <- function() {
  blk <- ccx_struct_hilda_csl3v0kai()
  blk[[CCX_GATE_FLAG]] <- 1L
  blk$imb_treatment    <- LIK_IMB_TREATMENT_CODES[["smooth"]]   # RULED 2026-09-30 (l): "Smooth + cement"
  blk$imb_with_cement  <- 1L
  stopifnot(!anyDuplicated(names(blk)))
  blk
}
#' THE "hilda_csl3v0kaidgbe" STRUCTURE (W1, 2026-10-02; OBJECTIVE #15): hilda_csl3v0kaidgb
#' with the LAND ENSO LAG FITTED (Marcus 10-02: "Do it right. Option 2"). e = `lag_enso_land`,
#' DESIGN's L_MEI: the land term reads Nino3.4 L months late, the ocean channels at t
#' (R/model.R ccx_enso_lagged()). The block changes NOTHING the model reads: it opens the
#' SECOND gate (CCX_GATE_FLAG_ENSO_LAG) on top of kaidgb's, and the fitted lag does the
#' rest. Under every other label the lag is held at 0, so kaidgb -- the lag-0 CONTROL arm
#' of the #15 refit (ruled 10-02, D2) -- and every registered file stay bit-exact.
#' ⚠ The NAME was proposed in a working session and is the author's call, as kaidgb's was.
ccx_struct_hilda_csl3v0kaidgbe <- function() {
  blk <- ccx_struct_hilda_csl3v0kaidgb()
  blk[[CCX_GATE_FLAG_ENSO_LAG]] <- 1L
  stopifnot(!anyDuplicated(names(blk)))
  blk
}
#' THE "hilda_csl3v0kaidgbem" STRUCTURE (DESIGN §3.4a S, RULED 2026-10-04): hilda_csl3v0kaidgbe
#' with the STRATIFICATION FEEDBACK on -- the upper part of K(z) weakens as the surface warms
#' faster than the deep ocean, g = (1 + s T_key)^(-q/2), and the solved export is rescaled with
#' it (R/model.R ccx_mix_on() / ccx_mix_g_series()). The three constants are STRUCTURAL (Marcus:
#' "Obs x law, fixed"), from R/constants.R. Every other label leaves them absent = OFF, so every
#' registered file stays bit-exact. The gates are kaidgbe's, untouched: m opens nothing.
#' ⚠ The NAME (m = mixing) was proposed in a working session and is the author's call, as kaidgb's and kaidgbe's were.
ccx_struct_hilda_csl3v0kaidgbem <- function() {
  blk <- ccx_struct_hilda_csl3v0kaidgbe()
  blk$mix_strat_s   <- ccx_const("MIX_STRAT_S")
  blk$mix_strat_q   <- ccx_const("MIX_STRAT_Q")
  blk$mix_strat_tau <- ccx_const("MIX_TDEEP_TAU")
  stopifnot(!anyDuplicated(names(blk)))
  blk
}
#' THE "hilda_csl3v0kaidgbemw" STRUCTURE (OBJECTIVE #17, RULED 2026-10-06 n): hilda_csl3v0kaidgbem with
#' the MAIN objective's half of the INTERANNUAL CUT (R/likelihood.R, "OBJECTIVE #17"). Marcus, verbatim:
#' "Build: land + ocean module (Recommended)"; the NAME "hilda_csl3v0kaidgbemw (Recommended)" (w = wobble,
#' the app's word for the year-to-year signal the module fits). Three fields; the MODEL reads none of them:
#'   iav_cut = 1              the module's names (CCX_IAV_MODULE_NAMES) are STAGE 1's: the main objective
#'                            HOLDS them, so ccx_make_logpost() refuses them fitted (pin them, CCX_MS_PIN)
#'   gcb_land_lowpass_df = 6  `gcb_land_sink` scored on its LOW-PASS part (LIK_LAND_LOWPASS_DF)
#'   gcb_enso_slope_row = 0   `gcb_ocean_enso_slope` leaves the main objective; the module scores it
#' The gates are kaidgbem's, untouched (the lag gate stays open, so the lag is a fitted name a pin can
#' hold). Every other label leaves the three absent, so every registered file stays bit-exact.
ccx_struct_hilda_csl3v0kaidgbemw <- function() {
  blk <- ccx_struct_hilda_csl3v0kaidgbem()
  blk$iav_cut             <- 1L
  blk$gcb_land_lowpass_df <- LIK_LAND_LOWPASS_DF
  blk$gcb_enso_slope_row  <- 0L
  stopifnot(!anyDuplicated(names(blk)))
  blk
}
#' THE "hilda_csl3v0kaidgbemwt" STRUCTURE (OBJECTIVE #18, RULED 2026-10-07 f): hilda_csl3v0kaidgbemw, the
#' interannual cut, REDESIGNED (R/likelihood.R, "OBJECTIVE #18"). Marcus, verbatim: "Full redesign
#' (Recommended)"; the NAME "hilda_csl3v0kaidgbemwt (Recommended)" (t = trendless). Two fields on #17's block:
#'   enso_index = 1              the DETRENDED ENSO index (CCX_ENSO_INDEX_CODES[["detrend"]]) for both ENSO
#'                               terms. The MODEL reads it, through the forcing: every consumer builds its
#'                               table with ccx_enso_index_of(params), and ccx_enso_index_check() refuses a
#'                               table built with another index
#'   gcb_ocean_lowpass_df = 6    `gcb_ocean_sink` scored on its LOW-PASS part, the land row's projector
#'                               (LIK_LAND_LOWPASS_DF) applied unchanged
#' The gates are #17's, untouched; so is the cut (iav_cut 1: the module's four names are PINNED, at stage 1's
#' values UNDER THIS LABEL). Every other label leaves both fields absent, so every registered file -- and
#' #17's files -- stay bit-exact. The seasonal rows stay in the main objective (ruled: "No, keep them").
ccx_struct_hilda_csl3v0kaidgbemwt <- function() {
  blk <- ccx_struct_hilda_csl3v0kaidgbemw()
  blk$enso_index           <- CCX_ENSO_INDEX_CODES[["detrend"]]
  blk$gcb_ocean_lowpass_df <- LIK_LAND_LOWPASS_DF
  stopifnot(!anyDuplicated(names(blk)))
  blk
}
#' THE "hilda_csl3v0kaidgbemwtc" STRUCTURE (THE CITATION BATCH, RULED 2026-10-12): hilda_csl3v0kaidgbemwt
#' with every value the citation walkthrough CHANGED (notes/citation_rulings_2026-10-12.md). Marcus,
#' verbatim: "New label (a) (Recommended)"; the NAME "…wtc (c = cited)". Every field is read from a
#' data product or a cited registry entry -- none is typed here:
#'   alk_surface      2303.4e-6 mol/kg   ALK_SURFACE_GLODAP (row 3; GLODAPv2.2023 0-100 m)
#'   carb_salinity    34.760             SALINITY_SURFACE_GLODAP (row 30) -> data/carbonate_coefs_s34760.rds
#'   ocean_depth      3682.2 m           OCEAN_DEPTH_CS2010 (row 5) -> the grid, and the GLODAP target
#'                                       products keyed by it (R/likelihood.R ccx_glodap_file())
#'   sst_seas_lag_NH/_SH  1.325 / 1.536  ccx_sst_seas_lag_obs(): ERSSTv5 per hemisphere (row 17)
#'   nuc_share_ts     1 (per_year)       the 22-country files' own NH share, year by year (row 20)
#'   alpha_photo_eps  16.2 permil        ALPHA_PHOTO_EPS_STILL2003 (rows 11-12), replacing #18's 15.6
#'   pump_eps13_org   -22 permil         PUMP_EPS13_ORG_CLARET2021 (row 1)
#'   intcal_sd_published 1               the d14c_intcal row's published D14C sigma (ledger sec. C)
#'   wtc_free         1                  opens CCX_PARAM_GATED_WTC: bomb_share_NH, seas_T_lag FITTED
#' Every other label leaves every one of these fields absent, so every registered file -- #18's
#' included -- stays bit-exact.
ccx_struct_hilda_csl3v0kaidgbemwtc <- function() {
  blk <- ccx_struct_hilda_csl3v0kaidgbemwt()
  lag <- ccx_sst_seas_lag_obs()
  add <- list(alk_surface         = ccx_const("ALK_SURFACE_GLODAP"),
              carb_salinity       = ccx_const("SALINITY_SURFACE_GLODAP"),
              ocean_depth         = ccx_const("OCEAN_DEPTH_CS2010"),
              sst_seas_lag_NH     = lag[["NH"]],
              sst_seas_lag_SH     = lag[["SH"]],
              nuc_share_ts        = CCX_NUC_SHARE_CODES[["per_year"]],
              alpha_photo_eps     = ccx_const("ALPHA_PHOTO_EPS_STILL2003"),
              pump_eps13_org      = ccx_const("PUMP_EPS13_ORG_CLARET2021"),
              intcal_sd_published = 1,
              wtc_free            = 1)
  blk[names(add)] <- add
  stopifnot(!anyDuplicated(names(blk)))
  blk
}
#' The structure labels the objective knows, and each one's DECLARED block --
#' ONE dispatch (2026-09-14f), read by ccx_apply_structure(), the array driver's
#' banner and the tests, so no consumer keeps its own list.
CCX_STRUCT_LABELS <- c("", "hilda", "hilda_eq", "hilda_tr", "hilda_c", names(CCX_L2_RETURN_LAYERS), "hilda_cs", "hilda_csl3v0", "hilda_csl3v0k", "hilda_csl3v0ka", "hilda_csl3v0kan", "hilda_csl3v0kai", "hilda_csl3v0kaidgb", "hilda_csl3v0kaidgbe", "hilda_csl3v0kaidgbem", "hilda_csl3v0kaidgbemw", "hilda_csl3v0kaidgbemwt", "hilda_csl3v0kaidgbemwtc")
ccx_struct_block <- function(struct) {
  if (identical(struct, "")) return(list())        # the column: nothing declared
  switch(struct,
    "hilda"    = CCX_STRUCT_HILDA,
    "hilda_eq" = ccx_struct_hilda_eq(),
    "hilda_tr" = ccx_struct_hilda_tr(),
    "hilda_c"  = ccx_struct_hilda_c(),             # hilda + the constants batch (2026-09-14 h)
    "hilda_cl2" = ccx_struct_hilda_cl("hilda_cl2"),  # hilda_c + the Nino3.4 limb returning from layer 2 (2026-09-17 k)
    "hilda_cl3" = ccx_struct_hilda_cl("hilda_cl3"),  # ... from layer 3 (ruled 2026-09-17 l; the array's label)
    "hilda_csl3" = ccx_struct_hilda_cl("hilda_csl3"), # the limb (layer 3) on hilda_cs (2026-09-20 o, ruling 3)
    "hilda_cs"  = ccx_struct_hilda_cs(),           # hilda_c + the seasonal ML's NH cycle FLAT (2026-09-19 l)
    "hilda_csl3v0" = ccx_struct_hilda_csl3v0(),    # hilda_csl3 with the vegetation-capacity loop OFF (2026-09-28)
    "hilda_csl3v0k" = ccx_struct_hilda_csl3v0k(),  # ... plus the fert_k SHAPE prior (2026-09-28)
    "hilda_csl3v0ka" = ccx_struct_hilda_csl3v0ka(),  # ... plus aod_mode anomaly (2026-09-29; NPP arm A)
    "hilda_csl3v0kan" = ccx_struct_hilda_csl3v0kan(), # ... plus the modern-NPP row (2026-09-29; NPP arm B1)
    "hilda_csl3v0kai" = ccx_struct_hilda_csl3v0kai(), # arm A + the inert soil carve-out, 0-1 m (2026-09-30)
    "hilda_csl3v0kaidgb" = ccx_struct_hilda_csl3v0kaidgb(), # ... + D2 / D3 FITTED, the gate open (2026-09-30; objective #14)
    "hilda_csl3v0kaidgbe" = ccx_struct_hilda_csl3v0kaidgbe(), # ... + the land ENSO lag FITTED, the second gate (2026-10-02; objective #15)
    "hilda_csl3v0kaidgbem" = ccx_struct_hilda_csl3v0kaidgbem(), # ... + the stratification feedback (2026-10-04; DESIGN §3.4a S)
    "hilda_csl3v0kaidgbemw" = ccx_struct_hilda_csl3v0kaidgbemw(), # ... + the interannual cut's main half (2026-10-06; objective #17)
    "hilda_csl3v0kaidgbemwt" = ccx_struct_hilda_csl3v0kaidgbemwt(), # ... + the detrended ENSO index + the low-pass ocean row (2026-10-07; objective #18)
    "hilda_csl3v0kaidgbemwtc" = ccx_struct_hilda_csl3v0kaidgbemwtc(), # ... + the citation batch (2026-10-12; "New label (a)")
    stop("ccx_struct_block(): unknown structure label '", struct, "'"))
}
#' The pump field's construction is the THIRD structure axis (option D + E,
#' 2026-09-14 h): "solved" (every registered file) or "martin" (the prescribed
#' export + the ventilation loop). Parsed like `seas_ml`, recorded in the mode
#' file as `pump_field` (ccx_mode_pump_field()), read from CCX_MS_PUMP_FIELD by
#' the array driver. It composes with EVERY structure label -- E's cell re-read
#' (ruling E5) is "hilda_eq" + "martin" -- which is why it is an axis and not a
#' fifth label.
CCX_PUMP_FIELDS <- c("solved", "martin")
ccx_parse_pump_field <- function(pump_field) {
  v <- as.character(pump_field)
  if (length(v) != 1L || is.na(v) || !v %in% CCX_PUMP_FIELDS)
    stop("ccx_apply_structure(): `pump_field` must be one of ",
         paste(shQuote(CCX_PUMP_FIELDS), collapse = ", "), "; got '",
         paste(pump_field, collapse = ","), "' (CCX_MS_PUMP_FIELD if it came from the environment).")
  v
}
#' The fitted names the model does NOT READ under a pump field (2026-09-14 h):
#' under "martin" the solved field's `pump_grad` and, by ruling E3 (one limb
#' subsumes option A), `gamma_enso_ocn_*`; under "solved" the loop's three. A
#' free unidentified name is a flat likelihood direction and a singular
#' Hessian, so the array driver refuses them FREE and the reference-set logic
#' accepts them as EXTRA pins on the canonical's own.
ccx_pump_field_inert <- function(pump_field) {
  if (identical(ccx_parse_pump_field(pump_field), "martin")) c("pump_grad", "gamma_enso_ocn_NH", "gamma_enso_ocn_SH")
  else c("pump_export", "w_vent", "gamma_vent", "w_thc")
}
#' Does a pin set EXTEND the canonical's (same values on the canonical's pinned
#' names) by nothing but names inert under `pump_field`? Then the canonical is
#' the array's incumbent "under this array's pins" -- the 09-13 (d) rule, read
#' for an array whose extra pins hold names the objective cannot see anyway.
#' ... and, since 2026-09-16 (f), by the equatorial cell's two names when the
#' array's STRUCTURE has no cell (`w_eq` / `gamma_eq` are inert at eq_frac 0;
#' the E array fitted them free and they sat on their prior). `struct` follows
#' the same env var every consumer reads.
ccx_pins_extend_canonical <- function(pins, pump_field, struct = Sys.getenv("CCX_MS_STRUCT", "")) {
  ccx_pins_extend(pins, CCX_MODE_CANONICAL_PINS, pump_field, struct)
}
#' Is a pin set a PRICE arm (2026-10-04, Marcus: "Canonical incumbent, Mac (Recommended)")? The
#' canonical's pins EXACTLY, plus ONE more name that the structure READS (not inert), held at a
#' value: a refit there is the PROFILE PRICE of that value (first use: k_w at Naegler's 1446 m/yr,
#' handoff 2026-10-04 item 4). Unlike an inert extension the held name MOVES the objective, so the
#' canonical is a START of such an arm (seeded at the pin), not a mode of it -- the layer-2 arm's
#' case. Two or more extra READ names are not a price of one value and stay unruled.
#' ⚠ THE NAME ITSELF IS RULED: it must be in CCX_MS_PRICE_ARM_NAMES. Any read name would do
#' arithmetically, but test-ms-reference-set.R has refused an extension by a READ name since
#' 09-14 (h) (`pump_grad` under the solved field: a structural pin, not a price), and that guard
#' stands; each price arm's name is added here by a ruling, never by a launch.
CCX_MS_PRICE_ARM_NAMES <- c("k_w")    # 2026-10-04 (Marcus): the k_w = 1446 price arm
ccx_pins_price_canonical <- function(pins, pump_field, struct = Sys.getenv("CCX_MS_STRUCT", "")) {
  base <- CCX_MODE_CANONICAL_PINS
  if (is.null(pins) || is.null(base) || !all(names(base) %in% names(pins))) return(FALSE)
  if (!isTRUE(all.equal(unname(pins[names(base)]), unname(base)))) return(FALSE)
  extra <- setdiff(names(pins), names(base))
  length(extra) == 1L && extra %in% CCX_MS_PRICE_ARM_NAMES && extra %in% .CCX_PARAM_ORDER &&
    !extra %in% ccx_inert_names(pump_field, struct)
}
#' Does `pins` equal `base` PLUS names that are INERT under this field / structure?
#' (2026-09-18: generalised from the canonical-only form so the CONTROL's arm can
#' carry `w_enso_l2 = 0` under a limb-less structure -- the name entered the table
#' 09-17 k and the driver refuses it free without the limb.) Inert = the pump field's
#' unread names, the cell's pair without the cell, the limb's name without the limb.
ccx_pins_extend <- function(pins, base, pump_field, struct = Sys.getenv("CCX_MS_STRUCT", "")) {
  if (is.null(pins) || is.null(base)) return(FALSE)
  if (!all(names(base) %in% names(pins))) return(FALSE)
  if (!isTRUE(all.equal(unname(pins[names(base)]), unname(base)))) return(FALSE)
  extra <- setdiff(names(pins), names(base))
  length(extra) > 0 && all(extra %in% ccx_inert_names(pump_field, struct))
}
#' The fitted names a structure / pump field does NOT read -- ONE place (2026-09-19 m;
#' the same list ccx_pins_extend() had inline): the field's unread names, the cell's
#' pair without the cell, the limb's name without the limb. A pin on one of these holds
#' a coordinate the objective cannot see, so a file whose pins are ALL inert is a FREE
#' arm of the reduced space (ccx_mode_pinned) -- hilda31pe's case.
ccx_inert_names <- function(pump_field, struct = Sys.getenv("CCX_MS_STRUCT", "")) {
  inert <- ccx_pump_field_inert(pump_field)
  bp <- ccx_apply_structure(ccx_default_params(), struct, seas_ml = "0", pump_field = pump_field)
  if (!ccx_eq_on(bp)) inert <- c(inert, "w_eq", "gamma_eq")
  if (!ccx_l2_on(bp)) inert <- c(inert, "w_enso_l2")     # the limb absent (k_l2 = 0), 2026-09-17 k
  inert
}
#' Is the layer-2 Nino3.4 limb PRESENT under a base list (k_l2 > 0)? The
#' structural switch; w_enso_l2 is inert when FALSE (2026-09-17 k).
ccx_l2_on <- function(p) {
  k <- p[["k_l2"]]
  !is.null(k) && is.finite(k) && k > 0
}
#' THE REFERENCE SET of a dispersed multistart -- which registered file is the
#' INCUMBENT (id 1) and which the NEW BASIN (id 2) for an array's pins and
#' seas_ml -- in ONE place (2026-09-17 j). Until today run_dispersed_multistart.R
#' and make_port_targets.R each carried a copy of this if-chain under a comment
#' saying they MUST MATCH; the three names are the port-target KEYS, so a
#' mismatch is a port gate comparing two different points. Rules, in order:
#'   the canonical's own pins, or pins that EXTEND them by inert names
#'                          -> incumbent the canonical; new basin the control
#'   no pins (a FREE array) -> incumbent the free parent (or the canonical when
#'                          free); new basin the control
#'   the CONTROL's pins (the inert names, shim free), seas_ml 0
#'                          -> incumbent the control; new basin the free parent
#'                             (the same 31-name space, the other h_ml basin --
#'                             the round-6b pair)
#'   the CONTROL's pins, seas_ml 1
#'                          -> incumbent the free parent; new basin the control
#'   the LAYER-2 LIMB's pins (the canonical's + the shim at 0), a structure
#'   WITH the limb, seas_ml 1 (2026-09-17 k)
#'                          -> incumbent the canonical; new basin the control
#'                             (each at its point, shim zeroed, w_enso_l2 seeded)
#'   (OBJECTIVE #16's pins had a branch of their own, 2026-10-05 -- the canonical seeded at the pin, a
#'   START. Since 2026-10-06 they ARE the canonical's (hilda33p), so the first rule takes them with the
#'   canonical as a MODE; the branch was removed on Marcus's ruling "Remove, re-express its test".)
#'   OBJECTIVE #17's pins (#16's + the interannual module's four at stage 1's values; 2026-10-06 n,
#'   Marcus: "Build: land + ocean module (Recommended)"), under #17's label at seas_ml 1
#'                          -> incumbent the canonical (seeded at the pins: a start);
#'                             new basin the control
#'   OBJECTIVE #18's pins (#16's + the module's four at stage 1's values UNDER #18 at #17's basin B; 2026-10-07 i,
#'   Marcus: "Register B, seed from it (Recommended)"), under #18's label at seas_ml 1
#'                          -> incumbent #17's basin B, registered `hilda29w` (seeded at the pins: a start);
#'                             new basin the control
#'   (THE WTC REFIT's pins had a branch of their own, 2026-10-12 -- hilda29e at its own model, a START, the one
#'   ruled exception to the cut canonical's own-label guard. Since 2026-10-13 (f) the canonical is hilda31w, a
#'   file of that label, so the first rule takes them with the canonical as a MODE; the branch is removed, as
#'   #16's and #18 pass 2's were.)
#'   anything else          -> stop: a new objective with no incumbent on disk.
ccx_ms_reference_set <- function(pins, seas_ml, pump_field = Sys.getenv("CCX_MS_PUMP_FIELD", "solved"),
                                 struct = Sys.getenv("CCX_MS_STRUCT", "")) {
  seas_ml <- ccx_parse_seas_ml(seas_ml)
  same <- function(a, b) identical(ccx_pin_label(a), ccx_pin_label(b))
  # (2026-10-13 f) THE WTC REFIT's exception is REMOVED: its pins are the canonical's and its label is the canonical's since
  # hilda31w, so the guard below and the first branch take them, the canonical as a MODE (R/paths.R CCX_MODE_WTC_*: records).
  # ⛔ A CUT CANONICAL'S PINS BELONG TO ITS OWN LABEL AND MIXED LAYER (2026-10-08 e; Marcus: "Approve all five"). Since
  # hilda29e the canonical's pins carry the interannual module's four at stage 1's values, fitted UNDER its label at its
  # seas_ml; under another label (#17's: a different ENSO index) or seas_ml 0 they are values of a different objective.
  # #18 pass 2's own branch refused both; the first branch below never checked either (deliberately, for a canonical
  # without the cut: a structure arm on its pins was legal). So: only when the canonical's pins carry the module.
  if (all(CCX_IAV_MODULE_NAMES %in% names(CCX_MODE_CANONICAL_PINS)) &&
      (same(pins, CCX_MODE_CANONICAL_PINS) || ccx_pins_extend_canonical(pins, pump_field, struct))) {
    .mdc <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
    if (!identical(struct, ccx_mode_struct(.mdc)))
      stop("ccx_ms_reference_set(): the canonical's pins carry the interannual module's values, fitted under ",
           ccx_mode_struct(.mdc), "; struct '", struct, "' is not that label (a cut canonical's pins are ruled under its own).")
    if (seas_ml != ccx_mode_seas_ml(.mdc))
      stop("ccx_ms_reference_set(): the canonical's pins carry the interannual module's values, fitted at seas_ml ",
           ccx_mode_seas_ml(.mdc), "; seas_ml ", seas_ml, " is not a ruled arm for them.")
  }
  res <- if (same(pins, CCX_MODE_CANONICAL_PINS) || ccx_pins_extend_canonical(pins, pump_field, struct)) {
    list(incumbent = CCX_MODE_CANONICAL, new_basin = CCX_MODE_SEASML0_CONTROL,
         why = "the canonical, under this array's pins")
  } else if (ccx_pins_price_canonical(pins, pump_field, struct)) {
    # a PRICE arm (2026-10-04): the canonical's objective with one READ name held -- the canonical
    # is its start, seeded at the pin. Only on the canonical's own seasonal mixed layer.
    held <- setdiff(names(pins), names(CCX_MODE_CANONICAL_PINS))
    if (seas_ml != 1L)
      stop("ccx_ms_reference_set(): a PRICE arm (the canonical's pins + ", held, ") prices a value on the ",
           "CANONICAL's objective, at seas_ml 1; seas_ml ", seas_ml, " is not a ruled arm.")
    list(incumbent = CCX_MODE_CANONICAL, new_basin = CCX_MODE_SEASML0_CONTROL,
         why = sprintf(paste0("a PRICE arm: the canonical's pins plus %s held at %s (the canonical, seeded ",
                              "at the pin: a start, not a mode of this arm)"), held, format(pins[[held]])))
  } else if (same(pins, CCX_MODE_OBJ17_PINS)) {
    # OBJECTIVE #17 (2026-10-06 n, the interannual cut): #16's pins + the module's four names at stage 1's
    # values (fit_iav_module.R). They are READ names, so the canonical is a START here (seeded at the pins),
    # as #16's was before its adoption. Ruled only under #17's own label and on the canonical's seasonal
    # mixed layer.
    if (!identical(struct, CCX_MODE_OBJ17_STRUCT))
      stop("ccx_ms_reference_set(): objective #17's pins '", ccx_pin_label(pins), "' are ruled under ",
           CCX_MODE_OBJ17_STRUCT, " (the interannual cut) only; struct '", struct, "' is not a ruled arm.")
    if (seas_ml != 1L)
      stop("ccx_ms_reference_set(): OBJECTIVE #17 is ruled at seas_ml 1 (the canonical's seasonal mixed ",
           "layer); seas_ml ", seas_ml, " is not a ruled arm.")
    list(incumbent = CCX_MODE_CANONICAL, new_basin = CCX_MODE_SEASML0_CONTROL,
         why = paste0("OBJECTIVE #17 (the interannual cut, Marcus 2026-10-06): the canonical's pins plus the module's ",
                      "four names at stage 1's values (the canonical, seeded at the pins: a start, not a mode of this ",
                      "objective)"))
  } else if (same(pins, CCX_MODE_OBJ18_PINS)) {
    # OBJECTIVE #18 (2026-10-07, the redesigned cut): #16's pins + the module's four at stage 1's values under #18 at #17's
    # basin B. RULED 10-07 (i): the incumbent is basin B, registered `hilda29w` and SEEDED at the pins -- its module values
    # are #17's stage 1, so it is a START here, not a mode; the new basin is the control. Ruled only under #18's own label
    # and on the canonical's seasonal mixed layer.
    if (!identical(struct, CCX_MODE_OBJ18_STRUCT))
      stop("ccx_ms_reference_set(): objective #18's pins '", ccx_pin_label(pins), "' are ruled under ",
           CCX_MODE_OBJ18_STRUCT, " (the redesigned cut) only; struct '", struct, "' is not a ruled arm.")
    if (seas_ml != 1L)
      stop("ccx_ms_reference_set(): OBJECTIVE #18 is ruled at seas_ml 1 (the canonical's seasonal mixed ",
           "layer); seas_ml ", seas_ml, " is not a ruled arm.")
    list(incumbent = CCX_MODE_OBJ18_INCUMBENT, new_basin = CCX_MODE_SEASML0_CONTROL,
         why = paste0("OBJECTIVE #18 (the redesigned cut, Marcus 2026-10-07): the canonical's pins plus the module's four ",
                      "names at stage 1's values under #18; the incumbent is #17's basin B (", CCX_MODE_OBJ18_INCUMBENT,
                      "), seeded at the pins: a start, not a mode of this objective"))
  # (2026-10-08 e) #18 PASS 2's branch is REMOVED: its pins are the canonical's since hilda29e (the first branch takes them,
  # the canonical as a MODE, with the cut canonical's label / seas_ml guard above), as #16's branch went at hilda33p.
  } else if (is.null(pins)) {
    list(incumbent = if (is.null(CCX_MODE_PINNED_PARENT)) CCX_MODE_CANONICAL else CCX_MODE_PINNED_PARENT,
         new_basin = CCX_MODE_SEASML0_CONTROL,
         why = "the free parent of the pinned canonical: this array is FREE")
  } else if ((same(pins, CCX_MODE_CONTROL_PINS) || ccx_pins_extend(pins, CCX_MODE_CONTROL_PINS, pump_field, struct)) && seas_ml == 0L) {
    list(incumbent = CCX_MODE_SEASML0_CONTROL, new_basin = CCX_MODE_PINNED_PARENT,
         why = "the seas_ml-0 CONTROL, refit under its own arm (the inert pins, shim free)")
  } else if ((same(pins, CCX_MODE_CONTROL_PINS) || ccx_pins_extend(pins, CCX_MODE_CONTROL_PINS, pump_field, struct)) && seas_ml == 1L) {
    list(incumbent = CCX_MODE_PINNED_PARENT, new_basin = CCX_MODE_SEASML0_CONTROL,
         why = "the free parent, under the inert pins")
  # (2026-10-08 e) THE LAYER-2 LIMB's BRANCH IS REMOVED: unreachable by design since 09-20 r (its pins were an alias of the
  # canonical's, which the first branch takes), and its constant is now the limb arm's OWN nine (R/paths.R). Keeping the
  # branch would make it REACHABLE for a nine-pin (#15) array, which the 10-06 ruling refuses until its reference set is ruled.
  } else if (same(pins, CCX_MODE_FREE_PARENT_PINS)) {
    # THE FREE PARENT OF THE LIMB CANONICAL (2026-09-21 g): the six inert names only -- the
    # shim, the ocean ENSO pair and the limb's w_enso_l2 all fitted. Only where the limb
    # exists (else w_enso_l2 would be a free name the structure never reads -- the inert
    # refusal below would fire anyway; said here by name) and at seas_ml 1 (the canonical's).
    bp <- ccx_apply_structure(ccx_default_params(), struct, seas_ml = "0", pump_field = pump_field)
    if (!ccx_l2_on(bp))
      stop("ccx_ms_reference_set(): the free-parent pins '", ccx_pin_label(pins), "' under struct '", struct,
           "' (k_l2 = 0, no layer-2 limb): that is not the limb canonical's parent. Use its structure (\"hilda_csl3\").")
    if (seas_ml != 1L)
      stop("ccx_ms_reference_set(): the limb canonical's free parent is at seas_ml 1 (the canonical's ",
           "seasonal mixed layer); seas_ml ", seas_ml, " is not a ruled arm.")
    # 09-22 (k): the parent is REGISTERED (hilda32f) -- it is its own incumbent now; the
    # canonical (seeded) was the incumbent for the wave that produced it.
    list(incumbent = CCX_MODE_PINNED_PARENT, new_basin = CCX_MODE_SEASML0_CONTROL,
         why = "the FREE PARENT of the limb canonical: its structure, the six inert pins only, shim / pair / limb all fitted")
  } else stop("ccx_ms_reference_set(): no registered incumbent for pins '", ccx_pin_label(pins),
              "' at seas_ml ", seas_ml, " (the canonical's are '", ccx_pin_label(CCX_MODE_CANONICAL_PINS),
              "', the control's '", ccx_pin_label(CCX_MODE_CONTROL_PINS),
              "', objective #17's '", ccx_pin_label(CCX_MODE_OBJ17_PINS),
              "', objective #18's '", ccx_pin_label(CCX_MODE_OBJ18_PINS),
              "'); rule the reference set for this pin before launching.")
  # 2026-09-20 (r): the canonical FITS w_enso_l2, so its pin set under a structure WITHOUT the limb
  # would leave a name the structure never reads FREE -- the driver refuses such a name, and so
  # does the reference set, by name (the L2 branch's "no layer-2 limb" refusal, generalised to
  # every inert name: a registered pin set does not license an arm on a structure it does not fit)
  # (applied AFTER the set is matched, so a foreign set still says "no registered incumbent")
  # 2026-10-06 (objective #17): under the interannual CUT the module's names are stage 1's, so a pin set that
  # leaves any of them FREE is refused here, at launch, by name -- not first by ccx_make_logpost()'s guard
  # inside every task. (The canonical's ten under #17's label would otherwise take the first branch.)
  if (isTRUE(ccx_struct_block(struct)[["iav_cut"]] == 1)) {
    miss <- setdiff(CCX_IAV_MODULE_NAMES, names(pins))
    if (length(miss))
      stop("ccx_ms_reference_set(): struct '", struct, "' is the interannual CUT (objectives #17 / #18): the module's ",
           "names are stage 1's and must be PINNED; ", paste(miss, collapse = ", "), " would be free.")
  }
  if (!is.null(pins)) {
    free_inert <- setdiff(ccx_inert_names(pump_field, struct), names(pins))
    free_inert <- intersect(free_inert, CCX_PARAM_NAMES)
    if (length(free_inert))
      stop("ccx_ms_reference_set(): the pins '", ccx_pin_label(pins), "' under struct '", struct,
           "' leave ", paste(free_inert, collapse = ", "), " FREE, which this structure never reads (",
           if ("w_enso_l2" %in% free_inert) "no layer-2 limb: k_l2 = 0; " else "",
           "an inert name fitted free is an unruled arm). Pin it, or use a structure that reads it.")
  }
  res
}
#' @param seas_ml the SEASONAL MIXED LAYER switch (round 6), the SECOND axis of
#'   the objective label beside `struct` (2026-09-10). ⛔ WHY IT IS HERE AND NOT
#'   LEFT TO `ccx_default_params()`: `seas_ml` is a BASE parameter, not a fitted
#'   name, so it is invisible to `u`, absent from a mode file's `par_mode`, and
#'   silently takes its default (0 = OFF) in any driver that builds from
#'   `ccx_default_params()`. That is exactly what happened to the 2026-09-10
#'   refit (jobs 17318015 + 17325832): nobody specified it, the default carried,
#'   and both rounds fitted the shipped model with the mechanism OFF -- so the
#'   result is a new baseline and NOT the round-6 test it was launched as
#'   ⇒ [[ccx_refit_ran_at_seas_ml_0]], [[default_off_hides_the_bug]].
#'   Routing it through the SAME function as `struct` means every consumer that
#'   already builds its base list here (the driver, make_port_targets.R, the
#'   promoter, `ccx_mode_base()`) carries it without a second call to forget.
#'   It reaches the model as `p$seas_ml` and the label as `attr(, "seas_ml")`,
#'   which the driver RECORDS in every start file and the port gate VALIDATES
#'   against `port_targets.csv` -- recorded AND read, the `CCX_MS_STRUCT` pattern.
#'   Accepts 0/1 (numeric or the env var's "0"/"1"); anything else is an error
#'   by name, never a coercion.
ccx_apply_structure <- function(p, struct = Sys.getenv("CCX_MS_STRUCT", ""),
                                seas_ml = Sys.getenv("CCX_MS_SEAS_ML", "0"),
                                pump_field = Sys.getenv("CCX_MS_PUMP_FIELD", "solved")) {
  seas_ml <- ccx_parse_seas_ml(seas_ml)
  p$seas_ml <- seas_ml
  pump_field <- ccx_parse_pump_field(pump_field)
  p$pump_field <- pump_field
  if (identical(struct, "")) return(structure(p, struct = "", seas_ml = seas_ml, pump_field = pump_field))
  if (!struct %in% CCX_STRUCT_LABELS)
    stop("ccx_apply_structure(): unknown structure label '", struct,
         "'. Known: \"\" (column), \"hilda\", \"hilda_eq\" (HILDA + the equatorial cell, ",
         "2026-09-13g), \"hilda_tr\" (+ the tropical surface box, 2026-09-14f), ",
         "\"hilda_c\" (hilda + the constants batch, 2026-09-14h), \"hilda_cl2\" ",
         "(hilda_c + the Nino3.4 limb returning from layer 2, 2026-09-17k) and \"hilda_cl3\" ",
         "(the limb returning from layer 3, 2026-09-17l), \"hilda_cs\" (hilda_c with the ",
         "seasonal mixed layer's NH cycle FLAT, 2026-09-19l) and \"hilda_csl3\" (the limb from ",
         "layer 3 on hilda_cs, 2026-09-20o) and \"hilda_csl3v0\" (hilda_csl3 with npp_veg_frac = 0, ",
         "2026-09-28) and \"hilda_csl3v0k\" (hilda_csl3v0 + the fert_k shape prior, 2026-09-28) ",
         "and \"hilda_csl3v0ka\" / \"hilda_csl3v0kan\" (+ aod anomaly / + the modern-NPP row, 2026-09-29) ",
         "and \"hilda_csl3v0kai\" (arm A + the inert soil carve-out, 2026-09-30) ",
         "and \"hilda_csl3v0kaidgb\" (+ D2 / D3 fitted, objective #14, 2026-09-30) ",
         "and \"hilda_csl3v0kaidgbe\" (+ the land ENSO lag fitted, objective #15, 2026-10-02) ",
         "and \"hilda_csl3v0kaidgbem\" (+ the stratification feedback, DESIGN §3.4a S, 2026-10-04) ",
         "and \"hilda_csl3v0kaidgbemw\" (+ the interannual cut's main half, objective #17, 2026-10-06) ",
         "and \"hilda_csl3v0kaidgbemwt\" (+ the detrended ENSO index + the low-pass ocean row, objective #18, 2026-10-07) ",
         "and \"hilda_csl3v0kaidgbemwtc\" (+ the citation batch, 2026-10-12).")
  blk <- ccx_struct_block(struct)
  for (n in names(blk)) p[[n]] <- blk[[n]]
  structure(p, struct = struct, seas_ml = seas_ml, pump_field = pump_field)
}

# ---- posterior -------------------------------------------------------
#' Build a closure that evaluates the log-posterior on the unconstrained scale.
#'
#' The forcing table is assembled ONCE and reused; only c14_cosmo is refreshed
#' per draw, because natural 14C production is solved by the spinup and so
#' depends on the parameters.
#' @param base_params the parameter list the fitted parameters are written INTO.
#'   Defaults to `ccx_default_params()`, which is the only thing any caller
#'   wanted until 2026-08-16e. It exists so a STRUCTURAL choice that is not a
#'   fitted parameter -- `pump_mode` "N" vs "D" is the case it was added for
#'   (Marcus deferred that choice to the refit; see DESIGN sec.5.2f) -- can be
#'   varied between two otherwise-identical objectives. Fitted parameters still
#'   overwrite their entries, so passing a list that sets one of them has no
#'   effect: this is for structure, not for pinning parameters.
#' @param by_stream FALSE (default) returns the bare scalar the sampler expects.
#'   TRUE returns that SAME scalar with the per-stream breakdown attached as
#'   `attr(, "streams")`, taken from THE OBJECTIVE'S OWN `ccx_loglik()` call.
#'
#'   ⚠ WHY THIS EXISTS RATHER THAN A HAND-REBUILT CALL. Ten diagnostics in
#'   `calibration/` re-assemble `ccx_loglik(..., by_stream = TRUE)` themselves,
#'   and on 2026-09-09w one of them (`repair_arm_streams.R`) was found to have
#'   been silently omitting `d14c_mid` -- so it had been producing a stream set
#'   for a DIFFERENT objective than the one being fitted. A breakdown that comes
#'   off the scored call cannot drift from it ⇒ [[two_gates_one_mechanism]].
#'   The default is FALSE, so no sampler path changes and no stored number moves.
#'
#' @param spinup_fn the spinup the objective seeds its transient from.
#'   ⭐⭐ **DEFAULT `CCX_OBJECTIVE_SPINUP` = `ccx_periodic_spinup` SINCE 2026-09-09x — ADOPTED, ruled by
#'   Marcus** once the three CHECK-FIRST items were measured
#'   (`calibration/diag_periodic_spinup_adoption.R`). The aseasonal fixed point
#'   `ccx_spinup` is the other admissible value and remains reachable, which is
#'   how a pre-adoption number is reproduced.
#'
#'   ⛔⛔ **THE ADOPTION MOVED THE OBJECTIVE, SO EVERY STORED `logpost`,
#'   `prior_z`, PORT TARGET AND CHECKPOINT `ref_logpost` IS NON-COMPARABLE WITH A
#'   RUN OF THIS FUNCTION TODAY.** At `hilda31` the likelihood goes
#'   −1439.424788 → −1449.582691 (−10.157904). ⚠ That is NOT evidence the
#'   periodic spinup fits worse: the mode was FITTED under the aseasonal one, so
#'   scoring it there is not like-for-like ⇒ [[like_for_like_forcing]]. Only a
#'   refit under this spinup can say. **A refit under each is NOT comparable with
#'   the other — pick before launching.** To reproduce a pre-09-09x number, pass
#'   `spinup_fn = ccx_spinup` EXPLICITLY and say so at the call site.
#'
#'   ⚠ WHY IT IS AN ARGUMENT AT ALL rather than a hard-wired call: so either
#'   spinup can be scored by **THE** objective, with no second copy of the
#'   scoring path. Re-scoring by hand — rebuilding forcing, transient and the
#'   `ccx_loglik()` call in a diagnostic — is a second definition of the
#'   objective, the defect family the 2026-09-09t leak belongs to
#'   ⇒ [[two_gates_one_mechanism]].
ccx_make_logpost <- function(years = c(1750, 2024), obs = ccx_prepare_obs(),
                             verbose = FALSE,
                             base_params = ccx_default_params(),
                             spinup_fn = CCX_OBJECTIVE_SPINUP, by_stream = FALSE) {
  if (!is.function(spinup_fn))
    stop("ccx_make_logpost(): `spinup_fn` must be a function with ccx_spinup()'s ",
         "contract (returns $y, $params, $aux, $grid, $prod_c14, $diagnostics).")
  ccx_load_cpp()
  # Built once at a REFERENCE bomb total; the bomb column scales linearly with
  # the total, so a draw only rescales it rather than rebuilding the table.
  # CCX_BOMB_REF (R/constants.R), not a local literal: the local `BOMB_REF <-
  # 102` that stood here outlived the 2026-08-22 promotion that constants.R
  # records as having removed it (review C, 2026-09-12). Numerically identical.
  base_forcing <- ccx_build_forcing("historical", years, prod_c14 = 0,
                                    bomb_total_kmol = CCX_BOMB_REF,
                                    enso_index = ccx_enso_index_of(base_params),
                                    aod_mode = ccx_aod_mode_of(base_params),
                                    nuc_share = ccx_nuc_share_of(base_params))
  # Land-use is rescaled per draw as a COLUMN multiply rather than by rebuilding
  # the forcing, which would cost more than the model run. Exact, because
  # ccx_build_forcing() applies luc_scale to the annual series and every
  # downstream LUC quantity -- monthly flux, in-window cumulative, and the
  # pre-window `luc_pre` folded into it -- is linear in that series.
  # test-luc-scale.R gates the two paths against each other so they cannot drift.
  # `.ccx_make_luc_scaler()` keeps the plain multiply for every arm except
  # "luc", where the columns are AFFINE in luc_scale and it composes them
  # exactly instead (see its block above ccx_scaled_forcing).
  LUC_SCALER <- .ccx_make_luc_scaler(base_forcing, "historical", years)
  ELUC_BASE  <- LUC_SCALER$eluc_tbl
  # the fitted names the MODEL has a slot for (computed once, not per draw)
  MODEL_SLOTS <- intersect(CCX_PARAM_NAMES, names(ccx_default_params()))
  # THE GATE'S GUARD (2026-09-30; CCX_PARAM_GATED). The fitted set must match the
  # structure, both ways. An OPEN structure scored without the gate would run the four
  # names at their base value (OFF) and call it a D2/D3 fit; a HOLDING structure with
  # them fitted would be a new objective wearing an old label.
  # Checked when the objective is built AND on every draw: the table is a global, and a
  # gate applied or undone after this closure exists would otherwise go unseen (the
  # check is a few set operations on ~40 names, against a model run).
  # ⚠ PER GATE since 2026-10-02 (the lag gate, CCX_PARAM_GATES): each flag is checked
  # against its OWN set, so a kaidgb draw with the lag fitted is refused exactly as a kai
  # draw with ndep_ret fitted is. `GATE_OPEN` keeps its 09-30 meaning, the D2/D3 gate,
  # because the I(t) check below is about the D3 rows only.
  GATE_OPEN  <- ccx_gate_open(base_params)
  GATES_OPEN <- ccx_gates_open(base_params)
  .gate_check <- function() {
    for (fl in names(CCX_PARAM_GATES)) {
      g <- names(CCX_PARAM_GATES[[fl]])
      g_fit <- intersect(g, CCX_PARAM_NAMES); g_pin <- intersect(g, names(CCX_PINS))
      if (fl %in% GATES_OPEN) {
        g_miss <- setdiff(g, c(g_fit, g_pin))
        if (length(g_miss))
          stop("ccx_make_logpost(): the structure OPENS the gate (", fl, " = 1) but ",
               paste(g_miss, collapse = ", "), " are not in the fitted set. Call ",
               "ccx_apply_gate(<struct>) first; scored as it stands, the objective would run ",
               "them at their base value, OFF.")
      } else if (length(c(g_fit, g_pin)))
        stop("ccx_make_logpost(): ", paste(c(g_fit, g_pin), collapse = ", "), " are in the fitted ",
             "set (or pinned) but the structure HOLDS them (no ", fl, "): undo the gate ",
             "(ccx_unapply_gate()) before scoring a holding structure.")
    }
  }
  .gate_check()
  # THE CUT'S GUARD (objective #17, 2026-10-06; the label hilda_csl3v0kaidgbemw). Under the interannual
  # cut the module's names are STAGE 1's (calibration/fit_iav_module.R). Fitted here, the main objective
  # would fit them on rows that cannot identify them -- with gcb_ocean_enso_slope moved to the module,
  # w_enso_l2 runs away (proposal s. 5.3) -- and a label has to mean ONE objective. So every module name
  # must be PINNED. Checked when the objective is built AND per draw, as the gate check is.
  IAV_CUT <- isTRUE(base_params[["iav_cut"]] == 1)
  .iav_check <- function() {
    if (!IAV_CUT) return(invisible(NULL))
    fit  <- intersect(CCX_IAV_MODULE_NAMES, CCX_PARAM_NAMES)
    miss <- setdiff(CCX_IAV_MODULE_NAMES, names(CCX_PINS))
    if (length(fit) || length(miss))
      stop("ccx_make_logpost(): the structure is the INTERANNUAL CUT (iav_cut = 1, objectives #17 / #18): ",
           paste(CCX_IAV_MODULE_NAMES, collapse = ", "), " are the module's names, fitted by stage 1, so ",
           "the main objective must HOLD them. ",
           if (length(fit)) paste0(paste(fit, collapse = ", "), " are FITTED here. ") else "",
           "Pin all four at the module's values (CCX_MS_PIN / ccx_apply_pins()).")
  }
  .iav_check()

  function(u) {
    .gate_check()
    .iav_check()
    # An OPEN structure records the ruled I(t) (ccx_struct_hilda_csl3v0kaidgb()); the D3
    # rows read the LIK_IMB_* globals at call time, so a draw under globals that disagree
    # would score a different objective under the same label. Refused per draw, before
    # the run (a screen may reassign the globals after this closure is built).
    if (GATE_OPEN) {
      .tr <- names(LIK_IMB_TREATMENT_CODES)[match(base_params$imb_treatment, LIK_IMB_TREATMENT_CODES)]
      if (length(.tr) != 1L || is.na(.tr) || !identical(.tr, LIK_IMB_TREATMENT) ||
          !identical(isTRUE(base_params$imb_with_cement == 1), isTRUE(LIK_IMB_WITH_CEMENT)))
        stop("ccx_make_logpost(): the structure records I(t) = '", if (length(.tr)) .tr else "?",
             "' (code ", paste(base_params$imb_treatment, collapse = ","), "), cement ",
             isTRUE(base_params$imb_with_cement == 1), ", but LIK_IMB_TREATMENT = '",
             LIK_IMB_TREATMENT, "' and LIK_IMB_WITH_CEMENT = ", LIK_IMB_WITH_CEMENT,
             ". A label means ONE objective; a different I(t) needs its own label.")
    }
    names(u) <- CCX_PARAM_NAMES
    pv <- ccx_unc_to_par(u)

    lp <- 0
    # the structure + this draw's values, for the priors that read the
    # structure (u_hs's live hs_frac, 2026-09-16 d); base_params carries it
    p_pr <- base_params; for (n in names(pv)) p_pr[[n]] <- pv[[n]]
    # ⛔ THE SIX NAMES WITH NO MODEL SLOT ARE READ FROM `p_pr`, NOT `pv` (2026-10-15, the pre-public
    # code review's dormant bug 1; the same defect as the ENSO block below). `pv` holds the FITTED
    # names only, so a PINNED one was NULL here: a pinned rep_dC scored as 0 (co2_level_MLO -70.84 ->
    # -662.42 at hilda31w), a pinned grad_off_* dropped its gradient row with nothing said, and a
    # pinned bomb_total or luc_scale stopped in the forcing rebuild. No registered mode pins one, so
    # no stored number moves: for a fitted name `p_pr` carries this draw's value, bit for bit. A
    # pinned name whose value the base does not carry is refused, since NULL would switch a row off.
    .nz_miss <- CCX_NUISANCE_NAMES[vapply(CCX_NUISANCE_NAMES, function(n) is.null(p_pr[[n]]), logical(1))]
    if (length(.nz_miss))
      stop("ccx_make_logpost(): ", paste(.nz_miss, collapse = ", "), " is neither fitted nor carried ",
           "by base_params. A PINNED name's value lives in the base list (ccx_mode_base() writes it); ",
           "set base_params$", .nz_miss[1], " to the pinned value.")
    nz <- lapply(stats::setNames(nm = CCX_NUISANCE_NAMES), function(n) p_pr[[n]])
    for (n in CCX_PARAM_NAMES) {
      s <- CCX_PARAM_TABLE[[n]]
      lp <- lp + .ccx_prior_eval(s, pv[[n]], p_pr) + .log_jac(u[[n]], s)
    }
    if (!is.finite(lp)) return(-Inf)

    p <- base_params
    # intersect() would silently DROP a fitted name absent from base_params
    # and the sampler would move a prior-only coordinate with zero leverage
    # ([[intersect_is_a_silent_default]]; audit 2026-09-06d). Refuse by name.
    # Only the fitted names that HAVE a model slot are checked: the six
    # nuisances (CCX_NUISANCE_NAMES: bomb_total, luc_scale, sigma_d14c, rep_dC, grad_off_*) never
    # enter the model list by design ([[ccx_two_param_lists]]).
    .miss <- setdiff(MODEL_SLOTS, names(p))
    if (length(.miss))
      stop("ccx_make_logpost(): base_params lacks fitted name(s) ",
           paste(.miss, collapse = ", "), "; they would never reach the model.")
    for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
    # ⛔ FROM `p_pr`, NOT `pv` (2026-10-06, found building objective #17). `pv` holds the FITTED names
    # only, so a PINNED ENSO amplitude was absent from it and ccx_gamma_enso() resolved it to
    # CCX_GAMMA_ENSO_DEFAULT (0): the pin's value, carried in base_params, was overwritten with 0. It
    # never moved a stored number -- every registered pin set holds the ocean pair at 0, the default
    # itself, and none ever held the land pair -- but #17 pins the land pair at non-zero values, and
    # the main objective would have run with the land ENSO term silently OFF (the smoke check's land
    # row read -26.62 against the pricing preview's -22.27). `p_pr` is base_params (pins included)
    # overlaid with this draw's fitted values: for a fitted name the same value as `pv`, bit for bit.
    p <- ccx_set_enso(p, p_pr)

    # `spinup_fn`, not `ccx_spinup` by name: see the argument's own block. The
    # DEFAULT is CCX_OBJECTIVE_SPINUP = ccx_periodic_spinup since 2026-09-09x
    # (it WAS ccx_spinup when this line was written, and the comment said so
    # until 2026-09-12): a caller that wants the aseasonal spinup must pass it.
    sp <- tryCatch(spinup_fn(p), error = function(e) NULL)
    if (is.null(sp) || !is.finite(sp$prod_c14) || sp$prod_c14 <= 0) return(-Inf)
    # A PERIODIC spinup that did not converge only WARNS, and a warning is not a
    # return value -- so without this the sampler would score a state that is not
    # on any orbit. Gated on the ABSENCE contract this repo uses elsewhere: the
    # aseasonal spinup has no `$periodic` field and is untouched by this branch.
    #
    # ⛔⛔ IT GATES `resid_carbon`, **NOT** `resid_state`, AND THAT DISTINCTION IS
    # THE WHOLE POINT. `PS_TOL` is the CARBON NEWTON's tolerance -- the thing the
    # solver actually drives -- and `resid_carbon` is the residual of the vector it
    # drives, one row of which is the ANNUAL-MEAN PIN rather than a period-to-period
    # difference. `resid_state` is `max|Phi(y) - y|` over every row and all three
    # tracers with NO pin substitution, so the atmosphere row's raw one-period
    # change sits in it and is constrained only in annual mean.
    # ⚠ MEASURED at `ccx_init_unc()` + a luc/bomb perturbation: `resid_carbon`
    # 3.71e-10 (CONVERGED) while `resid_state` was 1.354e-09 -- above PS_TOL, on a
    # 3.90e+04 GtC inventory, i.e. **3.5e-14 RELATIVE**, a floating-point floor and
    # not a convergence failure. The first cut of this guard gated `resid_state` and
    # returned -Inf on that perfectly good arm, which is the 2026-08-11 failure
    # reincarnated: a POSTERIOR TRUNCATED BY NUMERICS WEARING A PRIOR'S CLOTHES.
    # It broke test-luc-scale.R and test-d14c-mid.R and was caught by them
    # ⇒ [[verify_the_quantity_not_the_word]].
    # ⚠ It converges in 3-6 iterations against PS_MAXIT = 40, so a firing here is a
    # signal worth investigating rather than a routine rejection.
    if (!is.null(sp$periodic) &&
        (!is.finite(sp$periodic$resid_carbon) || sp$periodic$resid_carbon >= PS_TOL))
      return(-Inf)

    F <- base_forcing
    F$c14_cosmo <- sp$prod_c14
    F$c14_bomb  <- base_forcing$c14_bomb * (nz[["bomb_total"]] / CCX_BOMB_REF)
    .cols <- LUC_SCALER$cols(nz[["luc_scale"]])
    for (cc in CCX_LUC_COLS) F[[cc]] <- .cols[[cc]]
    attr(F, "luc_scale") <- nz[["luc_scale"]]
    eluc <- ELUC_BASE
    eluc$eluc <- LUC_SCALER$eluc(nz[["luc_scale"]])
    # ccx_run_fast() defaults to substeps = "auto" and escalates on NA, so this
    # -Inf now means the MODEL failed, not that the integrator hit its explicit-
    # diffusion stability limit. Until 2026-08-11 it meant the latter, and the
    # mode-finder maximised straight into it: kz = 175,790 sat ~1 % below the
    # fixed-substep wall at ~155,000-178,000 (h_ml-dependent), so the posterior
    # was truncated by numerics wearing a prior's clothes. See test-stability.R.
    r <- tryCatch(ccx_run_fast(sp, F), error = function(e) NULL)
    if (is.null(r) || anyNA(r$out$co2_NH)) return(-Inf)
    # 2026-09-16 (d): a transient that had to ESCALATE its substeps ran at a
    # different count from the spinup that seeded it, and that mixed-count
    # number is 3-13 log-units off a consistent evaluation (review finding 3).
    # The auto controller (ccx_substeps_for, test-stability.R) is the defence
    # against the integrator's limit; the retry is a diagnostic convenience,
    # never an objective value. -Inf here means "not evaluable at a consistent
    # count", and it is recorded so a mode-finder cannot climb into it quietly.
    if (isTRUE(r$retried)) return(-Inf)

    # NOTE THE ABSENCE OF sigma_co2. Retired 2026-08-15; ccx_loglik() still
    # honours the field if it is supplied, so the objective omits it EXPLICITLY
    # rather than passing a zero -- passing 0 would give the same number today
    # and would silently reacquire the old branch if the contract ever changed.
    # NOTE THE ABSENCE OF sigma_d13c TOO, retired 2026-08-18 on the same
    # absence-contract terms as sigma_co2 above.
    err <- list(sigma_d14c = nz[["sigma_d14c"]], rep_dC = nz[["rep_dC"]],
                # The gradient offsets ride in `err` because that is the channel
                # for likelihood-side parameters (the sigmas already do). Their
                # ABSENCE skips the gradient terms rather than zeroing them --
                # see the LIK_GRAD_* block -- so this line is what turns them on
                # for the objective while leaving every legacy diagnostic
                # visibly, rather than silently, without them.
                grad_off_co2 = nz[["grad_off_co2"]],
                grad_off_d13c = nz[["grad_off_d13c"]])
    # D3 (R/likelihood.R, LIK_IMB_*): GCB's imbalance shares. Read from `p_pr`
    # -- the structure plus this draw's fitted values -- so a screen can carry
    # them in base_params and a refit can fit them, through ONE resolver. Absent
    # = NULL = objective #13's two sink rows, bit for bit.
    .sh <- ccx_imb_shares(p_pr)
    if (!is.null(.sh)) { err$imb_share_land <- .sh[["land"]]; err$imb_share_ocean <- .sh[["ocean"]] }
    # the STRUCTURE's likelihood switches (objective #17's cut: the low-pass land row, the slope row
    # moved to the module). Absent under every other label = nothing added.
    err <- ccx_err_with_struct(err, base_params)
    # `luc` is the MODEL's own land-use flux, so the gross-sink reconstruction
    # in the gcb_land_sink term follows luc_scale instead of silently reverting
    # to GCB's unscaled column.
    # `deep` is the BOTTOM-BOX D14C of this draw's spinup -- free, since the
    # spinup has already run, and the layer moves 0.04 permil over the transient
    # so the steady state is the right thing to score (see LIK_D14C_DEEP_NEFF).
    # `ocean_grad` is the model's (bottom box - mixed layer) DIC and d13C at the
    # OBSERVATIONS' epoch, not at the run's end and not from the spinup -- the
    # gradient terms score the transient (Marcus 2026-08-16). Unlike `deep`, it
    # is therefore NOT free: it reads the CCX_OCEAN_BOX_COLS time series.
    # ⚠ It no longer returns NULL for an out-of-band h_ml: since 2026-08-28 the
    # rows are scored at EVERY h_ml, at an inflated sigma that carries the
    # fixed-depth-vs-model-box mismatch, and it attaches that sigma as `sd_eff`.
    # `d14c_mid` (2026-09-06): the two intermediate slabs, from the SAME spinup
    # as `deep`, on the same steady-state grounds.
    # `deep` reads EVERY box in the bottom layer's window since 2026-09-16 (d)
    # (HD included under HILDA; review finding 1) -- see ccx_d14c_window_read().
    ll <- ccx_loglik(r$out, obs, err, luc = eluc,
                     deep = ccx_d14c_deep_read(sp),
                     ocean_grad = ccx_ocean_grad_scored(r$out, sp),
                     d14c_mid = ccx_model_d14c_slabs(sp),
                     npp = if (isTRUE(p$npp_row == 1)) r$npp else NULL,
                     by_stream = by_stream)
    # With by_stream the SAME call returns the named vector; the objective is its
    # sum, and the breakdown rides as an attribute so the scalar contract holds.
    st <- NULL
    if (by_stream) { st <- ll; ll <- sum(ll) }
    if (verbose) cat(sprintf("  ll %.1f  prior %.1f\n", ll, lp))
    if (!is.finite(ll)) return(-Inf)
    if (by_stream) return(structure(lp + ll, streams = st, loglik = ll, logprior = lp))
    lp + ll
  }
}

# ---- MCMC driver -----------------------------------------------------
#' Run adaptive-Metropolis chains
#'
#' ⛔⛔ (CORRECTED 2026-10-12, code review) IT CANNOT SAMPLE THE CANONICAL AS IT
#' STANDS. With default arguments at `hilda29e` it STOPS inside
#' ccx_make_logpost() ("the structure OPENS the gate ... not in the fitted
#' set"): the canonical's structure opens the parameter gates, and this function
#' never calls ccx_apply_gate(), never applies the file's pins, never adopts its
#' bands, and starts every chain from the TABLE inits (ccx_init_unc()), not the
#' mode. The live posterior band was produced by calibration/run_mcmc_check.R,
#' which does those steps itself. The paragraph below states the 2026-09-12
#' INTENT (and is true of what it fixed: the base list does come from the mode
#' file), not a working path to the canonical.
#'
#' ⛔ SAMPLES THE CANONICAL MODE'S STRUCTURE, NOT THE COLUMN (2026-09-12, review
#' A14). Until then this called ccx_make_logpost(years, obs) with the default
#' `base_params = ccx_default_params()` -- the COLUMN structure at the
#' environment's seas_ml default (0) -- so calibration/run_pilot.R would have
#' sampled a model that no mode file describes. The base parameters (struct,
#' seas_ml, pump_mode) now come from a MODE FILE, default the canonical, the
#' spinup defaults to the objective's, and the labels that say WHAT was sampled
#' ride in the returned object (same field names as a mode file), so the saved
#' output is self-describing ([[like_for_like_forcing]]).
#' @param n_iter iterations per chain
#' @param n_chains number of chains (dispersed starts)
#' @param seed base RNG seed; chain i uses seed + i
#' @param mode mode name or path (ccx_mode_file()): supplies struct, seas_ml
#'   and pump_mode via ccx_mode_base() + the file's `pump_mode`.
#' @param base_params override of the model list the fitted names overlay;
#'   NULL (default) = the mode file's.
#' @param spinup_fn default CCX_OBJECTIVE_SPINUP; warns if the mode file was
#'   fitted under a different spinup, because its draws would then not be
#'   like-for-like with the file's own `streams`.
ccx_run_mcmc <- function(n_iter = 5000, n_chains = 4, seed = 2026,
                         years = c(1750, 2024), adapt_frac = 0.5, acc_rate = 0.234,
                         mode = CCX_MODE_CANONICAL, base_params = NULL,
                         spinup_fn = CCX_OBJECTIVE_SPINUP) {
  if (!requireNamespace("adaptMCMC", quietly = TRUE))
    stop("adaptMCMC required: install.packages('adaptMCMC')")
  md <- readRDS(ccx_mode_file(mode))
  if (is.null(base_params)) {
    base_params <- ccx_mode_base(md)
    # pump_mode is NOT part of ccx_apply_structure(); every consumer sets it
    # from the file by name (the precedent at ccx_mode_run_params(), R/paths.R).
    if (!is.null(md$pump_mode)) base_params$pump_mode <- md$pump_mode
  }
  if (!identical(ccx_spinup_label(spinup_fn), ccx_mode_spinup(md)))
    warning("ccx_run_mcmc(): sampling under the '", ccx_spinup_label(spinup_fn),
            "' spinup while mode '", mode, "' was fitted under '",
            ccx_mode_spinup(md), "'; the draws are not like-for-like with its streams.")
  obs <- ccx_prepare_obs()
  lp  <- ccx_make_logpost(years, obs, base_params = base_params, spinup_fn = spinup_fn)
  init <- ccx_init_unc()

  chains <- lapply(seq_len(n_chains), function(i) {
    set.seed(seed + i)
    # dispersed starts, so between-chain variance is meaningful for R-hat
    st <- init + stats::rnorm(length(init), 0, 0.15)
    names(st) <- CCX_PARAM_NAMES
    res <- adaptMCMC::MCMC(lp, n = n_iter, init = st, scale = rep(0.05, length(st)),
                           adapt = floor(adapt_frac * n_iter), acc.rate = acc_rate,
                           showProgressBar = FALSE)
    colnames(res$samples) <- CCX_PARAM_NAMES
    res
  })
  list(chains = chains, param_names = CCX_PARAM_NAMES, n_iter = n_iter,
       years = years, seed = seed,
       # WHAT WAS SAMPLED (2026-09-12): the labels a consumer needs to score
       # these draws like-for-like. Same field names as a mode file.
       mode = mode, struct = ccx_mode_struct(md), seas_ml = ccx_mode_seas_ml(md),
       pump_mode = base_params$pump_mode, spinup = ccx_spinup_label(spinup_fn))
}

#' Convert chains to natural-scale draws, dropping burn-in
ccx_posterior_draws <- function(fit, burn_frac = 0.5) {
  do.call(rbind, lapply(fit$chains, function(ch) {
    s <- ch$samples
    keep <- seq(floor(burn_frac * nrow(s)) + 1, nrow(s))
    nat <- t(apply(s[keep, , drop = FALSE], 1, function(u) {
      names(u) <- CCX_PARAM_NAMES
      unlist(ccx_unc_to_par(u))
    }))
    as.data.frame(nat)
  }))
}
