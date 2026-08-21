# =====================================================================
# diag_seas_T_amp_q10_ridge.R -- IS THE seas_T_amp_NH x ln(q10) CONFLICT A
#                                RIDGE? A FALSIFICATION TEST, RUN BEFORE ANY
#                                REPAIR.
#
# THE CLAIM UNDER TEST (handoff 2026-08-21 sec.2). The seasonal respiration
# channel enters as q10^(A_T sin(...)/10), so at small modulation only the
# PRODUCT A_T * ln(q10) is identified -- R/model.R says so in as many words.
# The two priors jointly ask for a product the fit refuses:
#
#   prior CENTRE  14.3215 K x ln(2.00) = 9.927     <- sqrt(LO*HI), the actual prior
#   prior LO      11.4450 K x ln(2.00) = 7.933     <- the handoff's number
#   the mode      25.9371 K x ln(1.0907) = 2.251
#
# so the joint prior implies 4.41x the modulation the likelihood accepts (the
# handoff said 3.52x because it used the LO bracket where the prior is centred
# on the geometric mean of the bracket -- see ccx_bracket_lnorm). Both
# parameters are then fought in OPPOSITE directions along the putative ridge.
#
# WHAT WOULD MAKE THAT A RIDGE, AND WHAT WOULD REFUTE IT. If it is a ridge, then
# fixing A_T anywhere in 5-50 K and re-optimising costs nothing, and q10 moves
# to hold the product. If the profile is NOT flat, the conflict is NOT a
# two-parameter degeneracy and the soil-damping repair in sec.2 is aimed at the
# wrong thing -- STOP THERE.
#
# THE OBJECTIVE DROPS THE PRIORS ON THE TWO PARAMETERS UNDER TEST AND KEEPS
# EVERY OTHER ONE. The priors on A_T and q10 are the two things in conflict, so
# an objective containing them cannot say whether the DATA distinguish the pair
# -- that much was the design from the start. What the first pass got wrong was
# dropping ALL of them: with a pure likelihood the nuisance parameters escape,
# and they did. In the LAND tier, `seas_T_amp_SH` went to 1e-23 and
# `sst_seas_amp_NH` to 1e-31 in EVERY row -- both channels switched off, at
# z = -37.5 apiece. The profile was internally consistent (the same two channels
# were dead in the reference row too) but it was a profile of a DIFFERENT MODEL,
# and quoting its flatness as a statement about this one would have been wrong.
#
# So `partial` (the default) is lp(u) minus the prior and Jacobian of the
# profiled parameter and its partner, and nothing else. `lik` reproduces the
# 2026-08-21 first pass and is kept only for that. GATE 2 checks the
# subtraction against an independently computed ccx_loglik either way, and the
# full log-posterior is carried alongside, never optimised.
#
# q10 HAS TWO JOBS AND THE SECOND ONE IS WHY THIS MIGHT NOT BE FLAT. Besides the
# seasonal modulation it carries the ANNUAL climate-carbon feedback,
# q10^(gmst/10). Sliding A_T from 5 to 50 K forces ln(q10) through a factor of
# ten, which moves the annual land sink by far more than the seasonal rows care
# about. So the profile is decomposed into the FOUR SEASONAL ROWS and
# EVERYTHING ELSE, and that split is the second finding this script can return:
#
#   flat in both            -> ridge confirmed, sec.2's repair is well aimed
#   flat in seasonal only   -> the ridge is real but q10's ANNUAL duty pays for
#                              it; the repair is not a prior re-anchoring, it is
#                              splitting q10's seasonal and annual sensitivities
#   flat in neither         -> not a ridge; sec.2 is wrong, stop
#
# TWO TIERS, because a 2-parameter ridge and a 7-parameter one are different
# claims and the handoff only asserts the first:
#   PAIR   -- q10 alone free. The literal (A_T, q10) ridge as sec.2 states it.
#             It is also the UNFAIR one, and deliberately so: q10 is SHARED
#             between hemispheres, so moving it while seas_T_amp_SH is frozen
#             breaks the SH product by construction and charges the NH profile
#             for an SH misfit it did not cause.
#   PAIRSH -- q10 and seas_T_amp_SH. The minimal HONEST pair test: each
#             hemisphere may hold its own product. PAIR minus PAIRSH is the size
#             of the shared-q10 artefact, printed rather than argued about.
#   BLOCK  -- the whole seasonal block. What the fit could actually do.
#
# NOTHING HERE IS COMPILE-TIME. Unlike diag_phi_eff_profile.R, seas_T_amp_NH is
# a FITTED parameter, so there is no core to patch and no rebuild -- the cases
# fork in-process.
#
# h_ml IS BOUNDED TO [85, 120] IN THIS PROCESS, as the refit did, so the
# log-posterior column reproduces mode_fit_pumpN.rds exactly (GATE 1). The
# LIKELIHOOD is band-independent, so the primary result does not rest on it.
#
# WHAT THE amp AXIS ANSWERED (2026-08-21, PAIRSH tier, the honest one). The four
# seasonal rows move by 0.6 log-units across 11.4 -> 50 K while the product
# holds to 1.7 % -- the ridge is REAL and the two coordinates DO trade
# one-for-one. But the total is NOT flat, and essentially all of the
# non-flatness is in `rest`: -12.6 at 11.4 K and -100.2 at 5 K. So it is the
# ANNUAL rows, through q10's `q10^(gmst/10)` duty, that pin the pair -- not the
# seasonal channel, which is indifferent.
#
# WHICH IS WHY THE q10 AXIS EXISTS. Read the amp profile the other way round:
# the annual rows pin q10 near 1.09, the seasonal rows pin the PRODUCT near
# 2.25, and A_T = 2.25 / ln(1.09) = 26 K is then DERIVED rather than fought
# over. If that is right, re-anchoring `seas_T_amp_NH`'s prior downward cannot
# deliver sec.2's stated success criterion ("q10 back near 2.0") -- it will move
# A_T and leave q10 where it is. Profiling q10 with the amplitudes re-optimised
# is the transpose, and it separates the two claims for about half an hour
# against the 15 hours a refit costs.
#
# Usage:  Rscript calibration/diag_seas_T_amp_q10_ridge.R [axis] [tag]
#         axis = "amp" (default; profiles seas_T_amp_NH) or "q10"
# Writes: calibration/output/seas_T_amp_q10_ridge_<axis>[_tag].rds
# RUNTIME ~1.5 h on 4 workers for `amp`, ~40 min for `q10`.
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

RQ_ARGS      <- commandArgs(TRUE)
RQ_AXIS      <- if (length(RQ_ARGS) >= 1 && nzchar(RQ_ARGS[1])) RQ_ARGS[1] else "amp"
RQ_TAG       <- if (length(RQ_ARGS) >= 2) RQ_ARGS[2] else ""
# args 3 and 4 narrow the run: which tiers, and which grid points. They exist
# because the LAND tier below is three times the cost of BLOCK and is only worth
# paying on part of the grid.
RQ_ONLY      <- if (length(RQ_ARGS) >= 3 && nzchar(RQ_ARGS[3]))
                  strsplit(RQ_ARGS[3], ",")[[1]] else NULL
RQ_GRID_ARG  <- if (length(RQ_ARGS) >= 4 && nzchar(RQ_ARGS[4]))
                  as.numeric(strsplit(RQ_ARGS[4], ",")[[1]]) else NULL
RQ_OBJ       <- if (length(RQ_ARGS) >= 5 && nzchar(RQ_ARGS[5])) RQ_ARGS[5] else "partial"
stopifnot(RQ_AXIS %in% c("amp", "q10", "sst"), RQ_OBJ %in% c("partial", "lik"))
RQ_MODE_FILE <- file.path("calibration", "output", "pump_arms", "mode_fit_pumpN.rds")
RQ_OUT       <- file.path("calibration", "output",
                          sprintf("seas_T_amp_q10_ridge_%s%s.rds", RQ_AXIS,
                                  if (nzchar(RQ_TAG)) paste0("_", RQ_TAG) else ""))
RQ_WORKERS   <- 4          # = performance cores on this machine
RQ_NM_MAXIT  <- 3000       # per Nelder-Mead restart; the LAND tier is 9-D
RQ_NM_TRIES  <- 3          # restarts; stops early when a restart gains < RQ_NM_TOL
RQ_NM_TOL    <- 1.0        # log-units
# Brent brackets for the 1-parameter PAIR tier, per free parameter. q10's lower
# end is just above 1: at q10 = 1 the seasonal respiration channel switches off
# entirely and the product is 0 for EVERY amplitude, a degenerate point rather
# than an optimum.
RQ_BRACKET   <- list(q10 = c(1.0005, 6.0), seas_T_amp_NH = c(0.05, 400))
RQ_SEAS_ROWS <- c("co2_seasonal_MLO", "co2_seasonal_SPO",
                  "d13c_seasonal_MLO", "d13c_seasonal_SPO")
# THE TWO AXES ARE TRANSPOSES OF ONE ANOTHER: whichever of the pair is profiled,
# the other leads the free block. Everything downstream reads these, so adding
# an axis is a table entry and not a second script.
# THE AXIS TABLE. `amp` and `q10` are transposes of one another and share a
# PARTNER -- the other half of the pair whose prior is also dropped. `sst`
# (handoff 2026-08-21 sec.4) has no partner: `sst_seas_amp_NH` is one parameter
# against its own observation, so only its prior comes out.
RQ_PROFILED <- switch(RQ_AXIS, amp = "seas_T_amp_NH", q10 = "q10",
                      sst = "sst_seas_amp_NH")
RQ_PARTNER  <- switch(RQ_AXIS, amp = "q10", q10 = "seas_T_amp_NH",
                      sst = character(0))
RQ_SEAS_BLOCK <- c("seas_T_amp_SH", "seas_lag_p",
                   "sst_seas_amp_NH", "sst_seas_amp_SH", "npp_frac_NH")
# THE LAND TIER, added 2026-08-21 after the q10 axis returned. BLOCK freezes
# `beta_max`, `fert_k` and `luc_scale`, so the 352 log-units it charges for
# q10 = 2.0 is an UPPER BOUND: raising q10 releases more soil carbon under the
# observed warming, and the classic beta-gamma compensation -- more
# fertilisation drawing it back down -- is exactly the repair BLOCK forbids.
# Freeing the three is what turns "the fit will not go there" into "the DATA
# will not go there". The ocean parameters (`k_w`, `kz`, `h_ml`, `tau_ex`) stay
# frozen, so it is a tighter upper bound and not the refit itself.
RQ_TIERS <- if (RQ_AXIS == "sst") list(
  # FROZEN is one evaluation and it is the incumbent's home ground in its purest
  # form -- the number every previous "turning the ocean channel off HELPS"
  # reading was made on. It is here to be BEATEN by `seas`, and the gap between
  # them is the size of that home-ground advantage (match_incumbents_optim).
  frozen = character(0),
  seas   = setdiff(c(RQ_PARTNER, "q10", "seas_T_amp_NH", RQ_SEAS_BLOCK), RQ_PROFILED),
  land   = setdiff(c(RQ_PARTNER, "q10", "seas_T_amp_NH", RQ_SEAS_BLOCK,
                     "beta_max", "fert_k", "luc_scale"), RQ_PROFILED)
) else list(
  pair   = RQ_PARTNER,
  pairSH = c(RQ_PARTNER, "seas_T_amp_SH"),
  block  = c(RQ_PARTNER, RQ_SEAS_BLOCK),
  land   = c(RQ_PARTNER, RQ_SEAS_BLOCK, "beta_max", "fert_k", "luc_scale"))
if (!is.null(RQ_ONLY)) {
  stopifnot(all(RQ_ONLY %in% names(RQ_TIERS)))
  RQ_TIERS <- RQ_TIERS[RQ_ONLY]
}

md <- readRDS(ccx_path(RQ_MODE_FILE))

# ---- the anchors this profile is read against, all DERIVED --------------
RQ_OBS_LO  <- ccx_const("SEAS_T_AMP_NH_OBS_LO")     # all NH land, CRU 1961-90
RQ_OBS_HI  <- ccx_const("SEAS_T_AMP_NH_OBS_HI")     # NH land > 45N
RQ_PRIOR_C <- sqrt(RQ_OBS_LO * RQ_OBS_HI)           # ccx_bracket_lnorm's centre
RQ_PRIOR_S <- log(RQ_OBS_HI / RQ_OBS_LO) / 2
RQ_Q10_C   <- 2.0                                   # CCX_PARAM_TABLE q10 prior
RQ_Q10_S   <- 0.25
RQ_MODE_A  <- md$par_mode$seas_T_amp_NH
RQ_MODE_Q  <- md$par_mode$q10
RQ_MODE_X  <- md$par_mode[[RQ_PROFILED]]
# amp: 5 to 50 as sec.2 specifies, with the four points that MEAN something --
#      the two bracket ends, the prior centre and the mode -- exactly on grid.
# q10: the mode up to and past the LITERATURE 2.0, which is the value sec.2's
#      success criterion is stated in terms of, plus the amplitude-implied
#      2.25/ln(q10) = 11.445 point (q10 = 1.2160) so the two axes intersect.
RQ_SST_OBS <- ccx_const("SST_SEAS_AMP_NH_OBS")
RQ_GRID <- sort(unique(round(switch(RQ_AXIS,
  amp = c(5, 8, RQ_OBS_LO, RQ_PRIOR_C, RQ_OBS_HI, 20, RQ_MODE_A, 30, 36, 43, 50),
  q10 = c(1.02, 1.05, RQ_MODE_Q, 1.15,
          exp(RQ_MODE_A * log(RQ_MODE_Q) / RQ_OBS_LO),
          1.35, 1.5, 1.7, RQ_Q10_C, 2.3, 2.6),
  # sec.4: the mode up to the OBSERVED value, plus points BELOW it -- under a
  # pure likelihood this parameter ran to 1e-31, so "how much lower does the
  # objective want it" is a real question and not a formality.
  sst = c(0.05, 0.15, 0.30, RQ_MODE_X, 0.65, 0.90, 1.20, 1.55, 1.90, RQ_SST_OBS)), 4)))
if (!is.null(RQ_GRID_ARG)) RQ_GRID <- sort(unique(round(RQ_GRID_ARG, 4)))

# =====================================================================
# h_ml band override, exactly as calibration/run_modefind_pump_arms.R did
# (ARM_HML_BOUND). par_mode is band-independent; u_mode and the posterior
# fields are not (ccx_hml_band_provenance), so the file is re-encoded here
# from par_mode and never from u_mode.
# =====================================================================
RQ_HML_BOUND <- md$hml_bound
stopifnot(length(RQ_HML_BOUND) == 2L, is.finite(RQ_HML_BOUND))
CCX_PARAM_TABLE$h_ml$lo    <- RQ_HML_BOUND[1]
CCX_PARAM_TABLE$h_ml$hi    <- RQ_HML_BOUND[2]
CCX_PARAM_TABLE$h_ml$init  <- mean(RQ_HML_BOUND)
CCX_PARAM_TABLE$h_ml$prior <-
  local({ b <- RQ_HML_BOUND; function(x) stats::dunif(x, b[1], b[2], log = TRUE) })

bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
lp <- ccx_make_logpost(base_params = bp)
u0 <- ccx_par_to_unc(md$par_mode)

# ---- the prior part of the objective, subtracted exactly ---------------
# Mirrors ccx_make_logpost()'s own loop, Jacobians included. It is written out
# rather than reused because the closure returns only the SUM; if that loop ever
# changes, GATE 2 below fires rather than this drifting silently.
rq_logprior <- function(u) {
  names(u) <- CCX_PARAM_NAMES
  pv <- ccx_unc_to_par(u)
  s <- 0
  for (n in CCX_PARAM_NAMES) {
    e <- CCX_PARAM_TABLE[[n]]
    s <- s + e$prior(pv[[n]]) + .log_jac(u[[n]], e)
  }
  s
}
# The prior terms of a NAMED SUBSET only -- what `partial` subtracts.
rq_logprior_of <- function(u, which) {
  names(u) <- CCX_PARAM_NAMES
  pv <- ccx_unc_to_par(u)
  s <- 0
  for (n in which) {
    e <- CCX_PARAM_TABLE[[n]]
    s <- s + e$prior(pv[[n]]) + .log_jac(u[[n]], e)
  }
  s
}
rq_loglik <- function(u) {
  v <- lp(u)
  if (!is.finite(v)) return(-Inf)
  v - rq_logprior(u)
}
# THE OBJECTIVE. Set after RQ_PROFILED / RQ_PARTNER are known.
rq_obj <- NULL

sep <- function(s) cat(sprintf("\n%s\n%s\n", s, strrep("-", nchar(s))))

# ---- GATE 1: the stored mode reproduces under this process's table -----
sep("GATE 1: the arm-N mode reproduces")
.lp0 <- lp(u0)
cat(sprintf("h_ml band [%g, %g]; logpost at par_mode %.4f vs file %.4f (diff %.2e)\n",
            RQ_HML_BOUND[1], RQ_HML_BOUND[2], .lp0, md$logpost, .lp0 - md$logpost))
if (abs(.lp0 - md$logpost) > 1e-6)
  stop("the mode does not reproduce -- do not read anything below")

# ---- GATE 2: the prior subtraction is exact ---------------------------
# The independent path: run the model at par_mode and score it with ccx_loglik
# directly. If the two disagree, the "likelihood" profiled below is not one.
sep("GATE 2: loglik = logpost - logprior, checked independently")
rq_run <- function(pv) {
  p <- bp; for (n in CCX_PARAM_NAMES) p[[n]] <- pv[[n]]
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- F$c14_bomb * (pv$bomb_total / 102)
  # THE ANNUAL LUC SERIES IS TAKEN BEFORE THE COLUMNS ARE SCALED, then scaled
  # once -- ccx_forcing_eluc_annual() reads e_luc_{NH,SH} straight off the
  # forcing, so taking it AFTER the column multiply and scaling again applies
  # luc_scale TWICE. ccx_make_logpost() builds its ELUC_BASE from the unscaled
  # base_forcing for exactly this reason. GATE 2 caught the double-scale here at
  # 1.91 log-units; calibration/diag_phi_eff_profile.R still carries it (its
  # by_stream/gcb_land_sink column only -- its optimisation went through
  # ccx_make_logpost() and its seasonal-row conclusions do not touch LUC).
  el <- ccx_forcing_eluc_annual(F)
  for (z in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[z]] <- F[[z]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  el$eluc <- el$eluc * pv$luc_scale
  r  <- ccx_run_fast(sp, F)
  list(sp = sp, r = r, el = el, p = p)
}
rq_score <- function(pv, by_stream = TRUE) {
  z <- rq_run(pv)
  ccx_loglik(z$r$out, ccx_prepare_obs(),
             list(sigma_d14c = pv$sigma_d14c, rep_dC = pv$rep_dC,
                  grad_off_co2 = pv$grad_off_co2, grad_off_d13c = pv$grad_off_d13c),
             luc = z$el, deep = z$sp$diagnostics$d14c_bottom_box,
             ocean_grad = ccx_ocean_grad_scored(z$r$out, z$sp), by_stream = by_stream)
}
.ll_sub <- rq_loglik(u0)
.ll_ind <- rq_score(md$par_mode, by_stream = FALSE)
cat(sprintf("subtracted %.4f   independent %.4f   diff %.2e\n",
            .ll_sub, .ll_ind, .ll_sub - .ll_ind))
if (abs(.ll_sub - .ll_ind) > 1e-6)
  stop("the prior subtraction is not exact -- the profile would not be a likelihood")

# ---- the conflict, restated from the constants rather than typed -------
sep("THE CONFLICT, from the constants")
cat(sprintf("seas_T_amp_NH prior: lognormal, centre %.4f K, logsd %.4f  (bracket %.4f-%.4f)\n",
            RQ_PRIOR_C, RQ_PRIOR_S, RQ_OBS_LO, RQ_OBS_HI))
cat(sprintf("q10 prior:           lognormal, centre %.4f,   logsd %.4f\n", RQ_Q10_C, RQ_Q10_S))
cat(sprintf("mode: A_T = %.4f K (z %+.3f), q10 = %.4f (z %+.3f)\n",
            RQ_MODE_A, log(RQ_MODE_A / RQ_PRIOR_C) / RQ_PRIOR_S,
            RQ_MODE_Q, log(RQ_MODE_Q / RQ_Q10_C) / RQ_Q10_S))
cat(sprintf("products A_T*ln(q10): prior centre %.4f | prior LO %.4f | MODE %.4f\n",
            RQ_PRIOR_C * log(RQ_Q10_C), RQ_OBS_LO * log(RQ_Q10_C),
            RQ_MODE_A * log(RQ_MODE_Q)))
cat(sprintf("=> the joint prior asks for %.2fx the modulation the mode accepts",
            RQ_PRIOR_C * log(RQ_Q10_C) / (RQ_MODE_A * log(RQ_MODE_Q))))
cat(sprintf(" (%.2fx off the LO bracket)\n",
            RQ_OBS_LO * log(RQ_Q10_C) / (RQ_MODE_A * log(RQ_MODE_Q))))
cat("\nNOTE the reported prior_z in the arm file disagrees with the analytic z\n")
cat("above (it puts A_T at +3.29 and q10 at -2.01). run_modefind_pump_arms.R's\n")
cat("prior_z() integrates the prior on a LINEAR grid from x/1e3 to x*1e3, which\n")
cat("for a tight lognormal on a large x resolves the prior with ~1 grid point.\n")
cat("The analytic values are the correct ones. Reported, not silently used.\n")

# =====================================================================
# The objective, and the gate that it is what it claims to be
# =====================================================================
RQ_DROPPED <- c(RQ_PROFILED, RQ_PARTNER)
rq_obj <- if (RQ_OBJ == "lik") rq_loglik else
  function(u) { v <- lp(u); if (!is.finite(v)) -Inf else v - rq_logprior_of(u, RQ_DROPPED) }
sep(sprintf("GATE 3: the objective is `%s`", RQ_OBJ))
cat(sprintf("priors DROPPED: %s\n", paste(RQ_DROPPED, collapse = ", ")))
cat(sprintf("priors KEPT:    %s\n",
            paste(setdiff(CCX_PARAM_NAMES, if (RQ_OBJ == "lik") CCX_PARAM_NAMES else RQ_DROPPED),
                  collapse = ", ")))
.o0 <- rq_obj(u0)
.e0 <- if (RQ_OBJ == "lik") .ll_sub else .lp0 - rq_logprior_of(u0, RQ_DROPPED)
cat(sprintf("at the mode: %.4f   expected %.4f   diff %.2e\n", .o0, .e0, .o0 - .e0))
if (abs(.o0 - .e0) > 1e-9) stop("the objective is not what it says it is")

# =====================================================================
# One case = one (A_T, tier)
# =====================================================================
rq_case <- function(job) {
  a    <- job$amp
  free <- RQ_TIERS[[job$tier]]
  ia   <- match(RQ_PROFILED, CCX_PARAM_NAMES)
  ifr  <- match(free, CCX_PARAM_NAMES)

  ub <- u0
  ub[ia] <- .to_unc(a, CCX_PARAM_TABLE[[RQ_PROFILED]])
  frozen <- rq_obj(ub)

  f <- function(x) { u <- ub; u[ifr] <- x; v <- -rq_obj(u); if (!is.finite(v)) 1e12 else v }
  gains <- numeric(0); nev <- 0; conv <- NA
  if (length(free) == 0L) {
    # FROZEN: no optimisation at all, one evaluation. The incumbent's own point.
    x <- numeric(0); best <- frozen
  } else if (length(free) == 1L) {
    # Brent, not Nelder-Mead: NM in one dimension is documented-unreliable and
    # warns. The bracket is on the unconstrained (log) scale.
    br <- log(RQ_BRACKET[[free]])
    o  <- stats::optim(ub[ifr], f, method = "Brent", lower = br[1], upper = br[2])
    x <- o$par; best <- -o$value; nev <- 1L; gains <- best - frozen; conv <- o$convergence
  } else {
    x <- ub[ifr]; best <- frozen
    # Nelder-Mead RESTARTED from its own optimum -- a collapsed simplex stops
    # moving long before the point is stationary. The per-restart gains are
    # recorded so the reader can see how converged each case is.
    for (k in seq_len(RQ_NM_TRIES)) {
      o <- stats::optim(x, f, method = "Nelder-Mead",
                        control = list(maxit = RQ_NM_MAXIT, reltol = 1e-9))
      nev  <- nev + o$counts[1]
      gain <- (-o$value) - best
      x <- o$par; best <- -o$value; conv <- o$convergence
      gains <- c(gains, gain)
      if (gain < RQ_NM_TOL) break
    }
  }

  u1 <- ub; u1[ifr] <- x
  p1 <- ccx_unc_to_par(u1)
  bs <- rq_score(p1, by_stream = TRUE)
  z  <- rq_run(p1)
  ms <- ccx_model_stats(z$r$out, ccx_prepare_obs())
  amp2 <- function(s) 2 * sqrt(mean(s$a)^2 + mean(s$b)^2)
  tot  <- sum(unlist(bs))
  seas <- sum(unlist(bs[RQ_SEAS_ROWS]))

  list(amp = a, tier = job$tier, free = free,
       frozen = frozen, loglik = best, logpost = lp(u1),
       q10 = p1$q10, A_T = p1$seas_T_amp_NH, sst_SH = p1$sst_seas_amp_SH,
       product = p1$seas_T_amp_NH * log(p1$q10),
       par = p1[free], n_eval = nev, gains = gains, conv = conv,
       by_stream = unlist(bs), loglik_bystream = tot,
       seas = seas, rest = tot - seas,
       p2p = c(MLO = amp2(ms$co2_seas$MLO), SPO = amp2(ms$co2_seas$SPO)),
       sig = c(MLO = amp2(ms$d13_seas$MLO) / amp2(ms$co2_seas$MLO),
               SPO = amp2(ms$d13_seas$SPO) / amp2(ms$co2_seas$SPO)))
}

jobs <- unlist(lapply(names(RQ_TIERS),
                      function(tn) lapply(RQ_GRID, function(a) list(amp = a, tier = tn))),
               recursive = FALSE)
sep(sprintf("PROFILE: %s over %d values, %d tiers, %d workers",
            RQ_PROFILED, length(RQ_GRID), length(RQ_TIERS), RQ_WORKERS))
cat(sprintf("grid: %s\n", paste(sprintf("%.4g", RQ_GRID), collapse = " ")))
for (tn in names(RQ_TIERS))
  cat(sprintf("tier %-5s free: %s\n", tn, paste(RQ_TIERS[[tn]], collapse = " ")))
cat(sprintf("objective = %s; logpost carried, never optimised\n", RQ_OBJ))

t0  <- Sys.time()
res <- parallel::mclapply(jobs, function(j)
         tryCatch(rq_case(j), error = function(e) {
           cat(sprintf("*** %s A_T=%.4f FAILED: %s\n", j$tier, j$amp, conditionMessage(e)))
           NULL
         }), mc.cores = RQ_WORKERS)
cat(sprintf("\n%.1f minutes\n", as.numeric(Sys.time() - t0, units = "mins")))
res <- res[!vapply(res, is.null, logical(1))]
saveRDS(list(res = res, grid = RQ_GRID, tiers = RQ_TIERS, mode = md$par_mode,
             objective = RQ_OBJ, dropped_priors = RQ_DROPPED,
             profiled = RQ_PROFILED, hml_bound = RQ_HML_BOUND,
             prior = list(A_centre = RQ_PRIOR_C, A_logsd = RQ_PRIOR_S,
                          A_lo = RQ_OBS_LO, A_hi = RQ_OBS_HI,
                          q10_centre = RQ_Q10_C, q10_logsd = RQ_Q10_S)),
        ccx_path(RQ_OUT))

# =====================================================================
# Report
# =====================================================================
RQ_XLAB  <- switch(RQ_AXIS, amp = "A_T (K)", q10 = "q10", sst = "sst_NH (K)")
RQ_YLAB  <- switch(RQ_AXIS, amp = "q10", q10 = "A_T (K)", sst = "sst_SH (K)")
rq_other <- function(x) switch(RQ_AXIS, amp = x$q10, q10 = x$A_T,
                               sst = x$sst_SH)
# The anchors worth marking on each axis, DERIVED: the mode, and on the amp
# axis the two measured bracket ends and the prior centre, on the q10 axis the
# literature value sec.2's success criterion is stated in.
RQ_MARKS <- switch(RQ_AXIS,
  amp = c("MODE" = RQ_MODE_X, "obs LO (all NH land)" = RQ_OBS_LO,
          "PRIOR CENTRE" = RQ_PRIOR_C, "obs HI (>45N)" = RQ_OBS_HI),
  q10 = c("MODE" = RQ_MODE_X, "LITERATURE / prior centre" = RQ_Q10_C,
          "product at the all-land 11.445 K" =
            exp(RQ_MODE_A * log(RQ_MODE_Q) / RQ_OBS_LO)),
  sst = c("MODE" = RQ_MODE_X, "OBSERVED (ERSSTv5, = prior centre)" = RQ_SST_OBS))
RQ_MARKS <- round(RQ_MARKS, 4)   # same rounding as RQ_GRID, or an endpoint
                                 # falls outside the range it defines

for (tn in names(RQ_TIERS)) {
  rr <- res[vapply(res, function(x) x$tier, character(1)) == tn]
  if (!length(rr)) next
  rr <- rr[order(vapply(rr, function(x) x$amp, numeric(1)))]
  bl <- max(vapply(rr, function(x) x$loglik, numeric(1)))
  bs <- max(vapply(rr, function(x) x$seas,   numeric(1)))
  br <- max(vapply(rr, function(x) x$rest,   numeric(1)))
  sep(sprintf("TIER %s -- profiling %s, free: %s", toupper(tn), RQ_PROFILED,
              paste(RQ_TIERS[[tn]], collapse = " ")))
  cat(sprintf("%9s %9s %9s %11s %9s %9s %9s %11s %7s %7s\n",
              RQ_XLAB, RQ_YLAB, "product", RQ_OBJ, sprintf("d(%s)", RQ_OBJ),
              "d(seas4)", "d(rest)", "logpost", "z(A_T)", "z(q10)"))
  for (x in rr) {
    m <- names(RQ_MARKS)[vapply(RQ_MARKS, function(v) isTRUE(all.equal(x$amp, v)), logical(1))]
    cat(sprintf("%9.4f %9.4f %9.4f %11.2f %9.2f %9.2f %9.2f %11.2f %+7.2f %+7.2f%s\n",
                x$amp, rq_other(x), x$product, x$loglik, x$loglik - bl,
                x$seas - bs, x$rest - br, x$logpost,
                ccx_prior_z("seas_T_amp_NH", x$A_T), ccx_prior_z("q10", x$q10),
                if (length(m)) paste0("  <- ", m[1]) else ""))
  }
  ll <- vapply(rr, function(x) x$loglik,  numeric(1))
  pr <- vapply(rr, function(x) x$product, numeric(1))
  se <- vapply(rr, function(x) x$seas,    numeric(1))
  re <- vapply(rr, function(x) x$rest,    numeric(1))
  aa <- vapply(rr, function(x) x$amp,     numeric(1))
  cat(sprintf("\nSPREAD over the grid: loglik %.1f | seasonal-4 %.1f | everything else %.1f\n",
              diff(range(ll)), diff(range(se)), diff(range(re))))
  # AND OVER THE PART OF THE GRID THAT IS PHYSICALLY LIVE. The far end of each
  # axis is included to bracket the optimum, not because anyone would go there,
  # and a spread quoted over the whole range is dominated by it.
  liv <- aa >= min(RQ_MARKS) & aa <= max(RQ_MARKS)
  cat(sprintf("SPREAD over %.4g-%.4g only (mode to the far anchor): loglik %.1f | seasonal-4 %.1f | rest %.1f\n",
              min(aa[liv]), max(aa[liv]), diff(range(ll[liv])),
              diff(range(se[liv])), diff(range(re[liv]))))
  cat(sprintf("argmax %s = %.4f; best %s there = %.4f\n",
              RQ_XLAB, aa[which.max(ll)], RQ_YLAB, rq_other(rr[[which.max(ll)]])))
  # The product and the damping are statements about the (A_T, q10) PAIR. On the
  # sst axis they are constants of the run and printing them there invites the
  # reader to think this profile bears on them. It does not.
  if (RQ_AXIS != "sst") {
    cat(sprintf("PRODUCT A_T*ln(q10): %.4f - %.4f (ratio %.2f); ",
                min(pr), max(pr), max(pr) / min(pr)))
    cat("perfect trade would hold it CONSTANT\n")
    cat(sprintf("A_T needed at the LITERATURE q10 = %.2f, from the mode's product: %.4f K\n",
                RQ_Q10_C, RQ_MODE_A * log(RQ_MODE_Q) / log(RQ_Q10_C)))
    cat(sprintf("  => implied soil/air damping vs the all-land %.4f K: %.3f\n",
                RQ_OBS_LO, RQ_MODE_A * log(RQ_MODE_Q) / log(RQ_Q10_C) / RQ_OBS_LO))
  }
  cat("\nseasonal amplitudes at each re-optimised point (obs: MLO 6.754, SPO 1.170;\n")
  cat("d13C-per-ppm signatures 0.0528 MLO / 0.0288 SPO):\n")
  for (x in rr)
    cat(sprintf("  %-8s %8.4f  MLO p2p %6.3f  SPO p2p %6.3f  sig %7.5f / %7.5f\n",
                RQ_XLAB, x$amp, x$p2p[["MLO"]], x$p2p[["SPO"]],
                x$sig[["MLO"]], x$sig[["SPO"]]))
  cat("\noptimiser convergence (last restart's gain should be small):\n")
  for (x in rr)
    cat(sprintf("  %-8s %8.4f  %6d evals, %d restart(s), gains %s\n",
                RQ_XLAB, x$amp, as.integer(x$n_eval), length(x$gains),
                paste(sprintf("%+.2f", x$gains), collapse = " ")))
}

# ---- which rows pay, relative to the mode's own value ------------------
sep(sprintf("WHICH STREAMS PAY FOR MOVING %s (tier %s, vs the row at the mode)",
            RQ_PROFILED, toupper(tail(names(RQ_TIERS), 1))))
RQ_STREAM_TIER <- tail(names(RQ_TIERS), 1)
rb <- res[vapply(res, function(x) x$tier, character(1)) == RQ_STREAM_TIER]
if (length(rb)) {
  rb <- rb[order(vapply(rb, function(x) x$amp, numeric(1)))]
  ref <- rb[[which.min(abs(vapply(rb, function(x) x$amp, numeric(1)) - RQ_MODE_X))]]
  nm  <- names(ref$by_stream)
  D   <- vapply(rb, function(x) x$by_stream[nm] - ref$by_stream[nm], numeric(length(nm)))
  keep <- order(-apply(abs(D), 1, max))[seq_len(min(10L, length(nm)))]
  cat(sprintf("%-20s %s\n", "stream",
              paste(sprintf("%9.4g", vapply(rb, function(x) x$amp, numeric(1))), collapse = "")))
  for (k in keep)
    cat(sprintf("%-20s %s\n", nm[k], paste(sprintf("%9.1f", D[k, ]), collapse = "")))
  cat(sprintf("\n(columns are %s; entries are log-units relative to the mode's column)\n",
              RQ_XLAB))
}

sep("READING THIS")
if (RQ_AXIS == "sst") {
  cat("handoff 2026-08-21 sec.4 pre-registered three outcomes, and the per-stream\n")
  cat("table above is what picks between them:\n\n")
  cat("  the CO2 seasonal rows veto it   -> the air-sea flux response is too STRONG;\n")
  cat("      suspect the solubility-only formulation (no seasonal MLD, no biology)\n")
  cat("      applied to a single hemispheric box\n")
  cat("  the d13C seasonal rows veto it  -> the PARTITION is wrong, not the amplitude.\n")
  cat("      The ocean channel is isotopically near-neutral (0.0045), so adding it\n")
  cat("      should HELP the signature -- a d13C veto is genuinely surprising and is\n")
  cat("      a place to STOP and think rather than push on\n")
  cat("  the annual/level rows veto it   -> the seasonal term is LEAKING into the\n")
  cat("      annual budget, which is a BUG: it is zero-annual-mean by construction\n\n")
  cat("Only if this is inconclusive is a new observational product worth it (a\n")
  cat("Takahashi seasonal air-sea flux climatology). Do NOT start there.\n")
} else {
cat("flat in loglik AND in seasonal-4        -> ridge confirmed; sec.2's repair is aimed right\n")
cat("flat in seasonal-4, NOT in `rest`       -> the ridge is real but q10's ANNUAL duty pays;\n")
cat("                                           the repair is splitting q10, not re-anchoring a prior\n")
cat("flat in neither                         -> not a ridge; STOP, sec.2 is wrong\n")
}
cat(sprintf("\nwrote %s\n", RQ_OUT))
