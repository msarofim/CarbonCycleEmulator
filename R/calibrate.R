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
                     prior = function(x) dunif(x, 20, 2000, log = TRUE)),
  q10         = list(tr = "log",   init = 2.0,
                     prior = function(x) dlnorm(x, log(2.0), 0.25, log = TRUE)),
  k_w         = list(tr = "log",   init = 1500,
                     prior = function(x) dlnorm(x, log(1500), 0.4, log = TRUE)),
  h_ml        = list(tr = "logit", lo = 30,  hi = 200,   init = 75,
                     prior = function(x) dunif(x, 30, 200, log = TRUE)),
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
  kz          = list(tr = "logit", lo = 3830, hi = 6200, init = 5000,
                     prior = function(x) dunif(x, 3830, 6200, log = TRUE)),
  # THE BIOLOGICAL PUMP'S MAGNITUDE -- the 20th parameter (Marcus 2026-08-16d).
  # The preindustrial surface-to-bottom DIC gradient the pump holds, umol/kg.
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
  tau_ex      = list(tr = "log",   init = 1.3,
                     prior = function(x) dlnorm(x, log(1.3), 0.25, log = TRUE)),
  npp_frac_NH = list(tr = "logit", lo = 0.4, hi = 0.8,   init = 0.60,
                     prior = function(x) dunif(x, 0.4, 0.8, log = TRUE)),
  seas_amp_NH = list(tr = "log",   init = 12,
                     prior = function(x) dlnorm(x, log(12), 0.6, log = TRUE)),
  seas_amp_SH = list(tr = "log",   init = 2,
                     prior = function(x) dlnorm(x, log(2), 0.8, log = TRUE)),
  seas_phase_NH = list(tr = "logit", lo = 0, hi = 12,    init = 3.5,
                     prior = function(x) dunif(x, 0, 12, log = TRUE)),
  seas_phase_SH = list(tr = "logit", lo = 0, hi = 12,    init = 9.5,
                     prior = function(x) dunif(x, 0, 12, log = TRUE)),
  gamma_enso  = list(tr = "id",    init = 0.5,
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
  # `sigma_d13c` and `sigma_d14c` are DELIBERATELY LEFT FREE. The self-weighting
  # argument is specific to the dominant stream; a free scale on a minor stream
  # is a robustness valve rather than a feedback loop, and sigma_d13c's freedom
  # was a separate decision taken 2026-08-15 (handoff sec.1, decision 3).
  sigma_d13c  = list(tr = "log",   init = 0.1,
                     prior = function(x) dlnorm(x, log(0.1), 0.7, log = TRUE)),
  sigma_d14c  = list(tr = "log",   init = 5,
                     prior = function(x) dlnorm(x, log(5), 0.7, log = TRUE)),

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
  # constant and resists a model error wearing its clothes.
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
.log_jac <- function(u, s) switch(s$tr,
  log   = u,
  logit = log(s$hi - s$lo) + plogis(u, log.p = TRUE) + plogis(-u, log.p = TRUE),
  id    = 0)

ccx_par_to_unc <- function(p) vapply(CCX_PARAM_NAMES,
  function(n) .to_unc(p[[n]], CCX_PARAM_TABLE[[n]]), numeric(1))

ccx_unc_to_par <- function(u) {
  out <- lapply(CCX_PARAM_NAMES, function(n) .from_unc(u[[n]], CCX_PARAM_TABLE[[n]]))
  names(out) <- CCX_PARAM_NAMES
  out
}

ccx_init_unc <- function() ccx_par_to_unc(
  lapply(CCX_PARAM_TABLE, function(s) s$init))

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
ccx_make_logpost <- function(years = c(1750, 2024), obs = ccx_prepare_obs(),
                             verbose = FALSE,
                             base_params = ccx_default_params()) {
  ccx_load_cpp()
  # Built once at a REFERENCE bomb total; the bomb column scales linearly with
  # the total, so a draw only rescales it rather than rebuilding the table.
  BOMB_REF <- 102
  base_forcing <- ccx_build_forcing("historical", years, prod_c14 = 0,
                                    bomb_total_kmol = BOMB_REF)
  # Land-use is rescaled per draw as a COLUMN multiply rather than by rebuilding
  # the forcing, which would cost more than the model run. Exact, because
  # ccx_build_forcing() applies luc_scale to the annual series and every
  # downstream LUC quantity -- monthly flux, in-window cumulative, and the
  # pre-window `luc_pre` folded into it -- is linear in that series.
  # test-luc-scale.R gates the two paths against each other so they cannot drift.
  LUC_COLS  <- c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")
  ELUC_BASE <- ccx_forcing_eluc_annual(base_forcing)

  function(u) {
    names(u) <- CCX_PARAM_NAMES
    pv <- ccx_unc_to_par(u)

    lp <- 0
    for (n in CCX_PARAM_NAMES) {
      s <- CCX_PARAM_TABLE[[n]]
      lp <- lp + s$prior(pv[[n]]) + .log_jac(u[[n]], s)
    }
    if (!is.finite(lp)) return(-Inf)

    p <- base_params
    for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
    p$gamma_enso <- pv$gamma_enso

    sp <- tryCatch(ccx_spinup(p), error = function(e) NULL)
    if (is.null(sp) || !is.finite(sp$prod_c14) || sp$prod_c14 <= 0) return(-Inf)

    F <- base_forcing
    F$c14_cosmo <- sp$prod_c14
    F$c14_bomb  <- base_forcing$c14_bomb * (pv$bomb_total / BOMB_REF)
    for (cc in LUC_COLS) F[[cc]] <- base_forcing[[cc]] * pv$luc_scale
    attr(F, "luc_scale") <- pv$luc_scale
    eluc <- ELUC_BASE
    eluc$eluc <- eluc$eluc * pv$luc_scale
    # ccx_run_fast() defaults to substeps = "auto" and escalates on NA, so this
    # -Inf now means the MODEL failed, not that the integrator hit its explicit-
    # diffusion stability limit. Until 2026-08-11 it meant the latter, and the
    # mode-finder maximised straight into it: kz = 175,790 sat ~1 % below the
    # fixed-substep wall at ~155,000-178,000 (h_ml-dependent), so the posterior
    # was truncated by numerics wearing a prior's clothes. See test-stability.R.
    r <- tryCatch(ccx_run_fast(sp, F), error = function(e) NULL)
    if (is.null(r) || anyNA(r$out$co2_NH)) return(-Inf)

    # NOTE THE ABSENCE OF sigma_co2. Retired 2026-08-15; ccx_loglik() still
    # honours the field if it is supplied, so the objective omits it EXPLICITLY
    # rather than passing a zero -- passing 0 would give the same number today
    # and would silently reacquire the old branch if the contract ever changed.
    err <- list(sigma_d13c = pv$sigma_d13c, sigma_d14c = pv$sigma_d14c,
                # The gradient offsets ride in `err` because that is the channel
                # for likelihood-side parameters (the sigmas already do). Their
                # ABSENCE skips the gradient terms rather than zeroing them --
                # see the LIK_GRAD_* block -- so this line is what turns them on
                # for the objective while leaving every legacy diagnostic
                # visibly, rather than silently, without them.
                grad_off_co2 = pv$grad_off_co2,
                grad_off_d13c = pv$grad_off_d13c)
    # `luc` is the MODEL's own land-use flux, so the gross-sink reconstruction
    # in the gcb_land_sink term follows luc_scale instead of silently reverting
    # to GCB's unscaled column.
    # `deep` is the BOTTOM-BOX D14C of this draw's spinup -- free, since the
    # spinup has already run, and the layer moves 0.04 permil over the transient
    # so the steady state is the right thing to score (see LIK_D14C_DEEP_NEFF).
    # `ocean_grad` is the model's (bottom box - mixed layer) DIC and d13C at the
    # OBSERVATIONS' epoch, not at the run's end and not from the spinup -- the
    # gradient terms score the transient (Marcus 2026-08-16). Unlike `deep`, it
    # is therefore NOT free: it reads the CCX_OCEAN_BOX_COLS time series. It
    # returns NULL, skipping both terms visibly, when h_ml leaves
    # LIK_OCEAN_GRAD_HML_OK -- the band in which fixed-depth targets are
    # like-for-like with the model's boxes.
    ll <- ccx_loglik(r$out, obs, err, luc = eluc,
                     deep = sp$diagnostics$d14c_bottom_box,
                     ocean_grad = ccx_ocean_grad_scored(r$out, sp))
    if (verbose) cat(sprintf("  ll %.1f  prior %.1f\n", ll, lp))
    if (!is.finite(ll)) return(-Inf)
    lp + ll
  }
}

# ---- MCMC driver -----------------------------------------------------
#' Run adaptive-Metropolis chains
#' @param n_iter iterations per chain
#' @param n_chains number of chains (dispersed starts)
#' @param seed base RNG seed; chain i uses seed + i
ccx_run_mcmc <- function(n_iter = 5000, n_chains = 4, seed = 2026,
                         years = c(1750, 2024), adapt_frac = 0.5, acc_rate = 0.234) {
  if (!requireNamespace("adaptMCMC", quietly = TRUE))
    stop("adaptMCMC required: install.packages('adaptMCMC')")
  obs <- ccx_prepare_obs()
  lp  <- ccx_make_logpost(years, obs)
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
       years = years, seed = seed)
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
