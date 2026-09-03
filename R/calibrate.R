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
  kz          = list(tr = "logit", lo = 4379.1, hi = 8109.9, init = 6244.5,
                     prior = function(x) dunif(x, 4379.1, 8109.9, log = TRUE)),
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
  # THE PRIOR CENTRE IS DERIVED, NOT CHOSEN: ENT_SEAS_AMP_SH_DERIV = 10.9524
  # umol/kg is the in-band 29.68 diluted onto the SH box by the registered
  # 40-90 S ocean-area fraction. ⭐ BOTH ARE COMPUTED from named inputs since
  # the 2026-09-03 provenance audit -- they were typed answers with the
  # arithmetic in prose, which is how 30 and 11.07 had already drifted from
  # their own chain (29.68 and 10.9524). The WIDTH is derived too, from the
  # no-dilution ceiling -- see ENT_SEAS_LOGSD above.
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
  ent_seas_amp_SH = list(tr = "log", init = 10.952353,
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
    if (is.null(p$seas_lag_p))
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
    if (is.null(p$gamma_enso))
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

  still <- setdiff(absent, filled)
  if (length(still))
    stop("ccx_migrate_par_set(): no migration contract for: ",
         paste(still, collapse = ", "),
         ". Add one here, next to the split it mirrors.")
  structure(p, migrated = filled)
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
  nm <- md$param_names
  if (identical(nm, CCX_PARAM_NAMES)) return(invisible(TRUE))
  extra <- setdiff(nm, CCX_PARAM_NAMES); missing <- setdiff(CCX_PARAM_NAMES, nm)
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
  if (is.null(nm)) nm <- CCX_PARAM_NAMES
  unknown <- setdiff(nm, CCX_PARAM_NAMES)
  if (length(unknown))
    stop("ccx_unc_to_par(): u carries names this build does not know: ",
         paste(unknown, collapse = ", "),
         ". It was encoded under a different parameter set.")
  out <- lapply(nm, function(n) .from_unc(u[[n]], CCX_PARAM_TABLE[[n]]))
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
ccx_load_mode <- function(arm = CCX_MODE_CANONICAL, base = ccx_default_params()) {
  f  <- ccx_mode_file(arm)
  md <- readRDS(f)
  if (!identical(md$param_names, CCX_PARAM_NAMES))
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
  pm <- md$par_mode
  p  <- base
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pm[[n]]
  # THROUGH THE RESOLVER: a pre-2026-09-01 `par_mode` carries the retired
  # scalar, and intersect() would drop it in silence.
  p <- ccx_set_enso(p, pm)
  p$pump_mode  <- md$pump_mode
  # `hml_bound` IS CARRIED because the driver overrides CCX_PARAM_TABLE$h_ml
  # IN-PROCESS to [85, 120], and a logpost recomputed under the default band is
  # off by ~1.1 while `u_mode` stops decoding (max |u - u(par_mode)| = 1.7).
  # It is NULL on the older arm files, which did not record it -- callers that
  # recompute a logpost must assert on it rather than assume the band.
  list(p = p, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total,
       err = list(sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC,
                  grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c),
       hml_bound = md$hml_bound, md = md, file = f)
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
CCX_HESS_FALLBACK   <- 3e-4    # only for directions with no stable plateau

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
    d <- D[k, ]
    for (i in seq_along(d)) {
      if (i == 1L || i == length(d)) next
      tri <- d[c(i - 1L, i, i + 1L)]
      if (anyNA(tri) || !all(is.finite(tri)) || tri[2] == 0) next
      if (max(abs(tri - tri[2])) / abs(tri[2]) < CCX_HESS_STABLE_TOL)
        return(c(d = tri[[2]], idx = i))
    }
    c(d = NA_real_, idx = NA_real_)
  }
  PL <- t(vapply(seq_len(n), plateau, numeric(2))); rownames(PL) <- nm
  SDV <- ifelse(PL[, "d"] < 0, 1 / sqrt(-PL[, "d"]), NA_real_)
  eps <- CCX_HESS_EPS_FRAC * SDV
  no_plateau <- nm[is.na(eps)]
  eps[is.na(eps)] <- CCX_HESS_FALLBACK
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
      cat(sprintf("  ** no plateau, fell back to %.0e: %s\n",
                  CCX_HESS_FALLBACK, paste(no_plateau, collapse = ", ")))
  }
  list(H = H, eps = eps, sd_diag = SDV, curvature_by_step = D, verify = V,
       no_plateau = no_plateau, unstable = unstable, eps_frac = CCX_HESS_EPS_FRAC)
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
  # `.ccx_make_luc_scaler()` keeps the plain multiply for every arm except
  # "luc", where the columns are AFFINE in luc_scale and it composes them
  # exactly instead (see its block above ccx_scaled_forcing).
  LUC_SCALER <- .ccx_make_luc_scaler(base_forcing, "historical", years)
  ELUC_BASE  <- LUC_SCALER$eluc_tbl

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
    p <- ccx_set_enso(p, pv)

    sp <- tryCatch(ccx_spinup(p), error = function(e) NULL)
    if (is.null(sp) || !is.finite(sp$prod_c14) || sp$prod_c14 <= 0) return(-Inf)

    F <- base_forcing
    F$c14_cosmo <- sp$prod_c14
    F$c14_bomb  <- base_forcing$c14_bomb * (pv$bomb_total / BOMB_REF)
    .cols <- LUC_SCALER$cols(pv$luc_scale)
    for (cc in CCX_LUC_COLS) F[[cc]] <- .cols[[cc]]
    attr(F, "luc_scale") <- pv$luc_scale
    eluc <- ELUC_BASE
    eluc$eluc <- LUC_SCALER$eluc(pv$luc_scale)
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
    # is therefore NOT free: it reads the CCX_OCEAN_BOX_COLS time series.
    # ⚠ It no longer returns NULL for an out-of-band h_ml: since 2026-08-28 the
    # rows are scored at EVERY h_ml, at an inflated sigma that carries the
    # fixed-depth-vs-model-box mismatch, and it attaches that sigma as `sd_eff`.
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
