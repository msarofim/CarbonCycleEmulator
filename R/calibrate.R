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
  beta        = list(tr = "logit", lo = 0.0,  hi = 1.5,  init = 0.40,
                     prior = function(x) dunif(x, 0, 1.5, log = TRUE)),
  q10         = list(tr = "log",   init = 2.0,
                     prior = function(x) dlnorm(x, log(2.0), 0.25, log = TRUE)),
  k_w         = list(tr = "log",   init = 1500,
                     prior = function(x) dlnorm(x, log(1500), 0.4, log = TRUE)),
  h_ml        = list(tr = "logit", lo = 30,  hi = 200,   init = 75,
                     prior = function(x) dunif(x, 30, 200, log = TRUE)),
  kz          = list(tr = "log",   init = 4000,
                     prior = function(x) dlnorm(x, log(4000), 0.6, log = TRUE)),
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
  tau_soil    = list(tr = "log",   init = 25,
                     prior = function(x) dlnorm(x, log(25), 0.5, log = TRUE)),
  # Total bomb 14C production, kmol, 1945-1980. Calibrated (as DESIGN intended),
  # with a CITABLE prior: Naegler & Levin (2006) give 99.3-104.9 kmol. Treating
  # it as free lets error in the still-provisional injection SHAPE be partly
  # absorbed into magnitude, so the post-peak D14C decay can still constrain
  # ocean ventilation instead of being discarded outright. Residual shape
  # dependence remains -- see DATA.md 8.
  bomb_total  = list(tr = "log",   init = 102,
                     prior = function(x) dlnorm(x, log(102), 0.10, log = TRUE)),
  # error model
  sigma_co2   = list(tr = "log",   init = 1.5,
                     prior = function(x) dlnorm(x, log(1.5), 0.7, log = TRUE)),
  sigma_d13c  = list(tr = "log",   init = 0.1,
                     prior = function(x) dlnorm(x, log(0.1), 0.7, log = TRUE)),
  sigma_d14c  = list(tr = "log",   init = 5,
                     prior = function(x) dlnorm(x, log(5), 0.7, log = TRUE)),
  rho         = list(tr = "logit", lo = 0, hi = 0.999,   init = 0.9,
                     prior = function(x) dbeta(x / 0.999, 8, 2, log = TRUE))
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
ccx_make_logpost <- function(years = c(1750, 2024), obs = ccx_prepare_obs(),
                             verbose = FALSE) {
  ccx_load_cpp()
  # Built once at a REFERENCE bomb total; the bomb column scales linearly with
  # the total, so a draw only rescales it rather than rebuilding the table.
  BOMB_REF <- 102
  base_forcing <- ccx_build_forcing("historical", years, prod_c14 = 0,
                                    bomb_total_kmol = BOMB_REF)

  function(u) {
    names(u) <- CCX_PARAM_NAMES
    pv <- ccx_unc_to_par(u)

    lp <- 0
    for (n in CCX_PARAM_NAMES) {
      s <- CCX_PARAM_TABLE[[n]]
      lp <- lp + s$prior(pv[[n]]) + .log_jac(u[[n]], s)
    }
    if (!is.finite(lp)) return(-Inf)

    p <- ccx_default_params()
    for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
    p$gamma_enso <- pv$gamma_enso

    sp <- tryCatch(ccx_spinup(p), error = function(e) NULL)
    if (is.null(sp) || !is.finite(sp$prod_c14) || sp$prod_c14 <= 0) return(-Inf)

    F <- base_forcing
    F$c14_cosmo <- sp$prod_c14
    F$c14_bomb  <- base_forcing$c14_bomb * (pv$bomb_total / BOMB_REF)
    # ccx_run_fast() defaults to substeps = "auto" and escalates on NA, so this
    # -Inf now means the MODEL failed, not that the integrator hit its explicit-
    # diffusion stability limit. Until 2026-08-11 it meant the latter, and the
    # mode-finder maximised straight into it: kz = 175,790 sat ~1 % below the
    # fixed-substep wall at ~155,000-178,000 (h_ml-dependent), so the posterior
    # was truncated by numerics wearing a prior's clothes. See test-stability.R.
    r <- tryCatch(ccx_run_fast(sp, F), error = function(e) NULL)
    if (is.null(r) || anyNA(r$out$co2_NH)) return(-Inf)

    err <- list(rho = pv$rho, sigma_co2 = pv$sigma_co2,
                sigma_d13c = pv$sigma_d13c, sigma_d14c = pv$sigma_d14c)
    ll <- ccx_loglik(r$out, obs, err)
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
