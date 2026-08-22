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
  kz          = list(tr = "logit", lo = 3942.5, hi = 6528, init = 5235.25,
                     prior = function(x) dunif(x, 3942.5, 6528, log = TRUE)),
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
  # (SST_SEAS_AMP_LOGSD), because no bracket for it exists.
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
  seas_lag_p = list(tr = "id", init = 2.25,
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

ccx_prior_z <- function(name, x, table = CCX_PARAM_TABLE) {
  s <- table[[name]]
  if (is.null(s)) stop("no such parameter: ", name)
  ux <- .to_unc(x, s)
  if (!is.finite(ux)) return(NA_real_)
  # log prior density in the UNCONSTRAINED coordinate, Jacobian included
  ld <- function(u) vapply(u, function(w) {
    v <- s$prior(.from_unc(w, s)) + .log_jac(w, s)
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
#' `diag_app_params.R`). NOTE `gamma_enso` is NOT one of them: it is a field of
#' `ccx_default_params()` and is in `CCX_PARAM_NAMES`, so intersect() picks it up.
#' It is assigned explicitly below only for symmetry with `app/global.R`.
#'
#' @param arm "N" or "D", or a path to a mode file
#' @param base parameter vector to overlay onto
ccx_load_mode <- function(arm = "N", base = ccx_default_params()) {
  f <- if (file.exists(arm)) arm else
    ccx_path("calibration", "output", "pump_arms", sprintf("mode_fit_pump%s.rds", arm))
  md <- readRDS(f)
  if (!identical(md$param_names, CCX_PARAM_NAMES))
    stop("mode file '", basename(f), "' was fitted on a different parameter set (",
         length(md$param_names), " names); refusing to overlay it silently.")
  pm <- md$par_mode
  p  <- base
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pm[[n]]
  p$gamma_enso <- pm$gamma_enso
  p$pump_mode  <- md$pump_mode
  list(p = p, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total,
       err = list(sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC,
                  grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c),
       md = md, file = f)
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
    ccx_build_forcing(scenario, years, prod_c14 = 0, bomb_total_kmol = CCX_BOMB_REF)
  else base
  if (!is.null(sp)) F$c14_cosmo <- sp$prod_c14
  F$c14_bomb <- F$c14_bomb * (bomb_total / CCX_BOMB_REF)
  # The single scaling, and the E_LUC derived from the UNSCALED series before it
  # -- equivalently, from the scaled columns with no second multiply. Both give
  # the same answer; doing it in one place is what makes that a fact rather than
  # a coincidence between two statements.
  eluc <- ccx_forcing_eluc_annual(F)
  eluc$eluc <- eluc$eluc * luc_scale
  for (cc in CCX_LUC_COLS) F[[cc]] <- F[[cc]] * luc_scale
  attr(F, "luc_scale") <- luc_scale
  list(F = F, eluc = eluc)
}

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
    # NOTE THE ABSENCE OF sigma_d13c TOO, retired 2026-08-18 on the same
    # absence-contract terms as sigma_co2 above.
    err <- list(sigma_d14c = pv$sigma_d14c, rep_dC = pv$rep_dC,
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
