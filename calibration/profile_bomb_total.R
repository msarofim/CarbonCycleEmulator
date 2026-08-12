# =====================================================================
# profile_bomb_total.R -- can the ocean inventory constraint reach bomb_total?
#
# THE QUESTION. The ocean excess-14C term went into the likelihood on
# 2026-08-11 precisely to price the ocean 14C sink independently of the
# atmospheric decline, in the hope that it would pull bomb_total back from
# +4.6 sigma toward Naegler & Levin's citable 99.3-104.9 kmol. Re-running the
# mode-find moved it 151.2 -> 149.8. It did not.
#
# THE TEST. Fix bomb_total on a grid; at each value re-optimise every other
# parameter so the rest of the model gets its best chance to compensate; and do
# it under BOTH observational target sets, because which one to score against is
# an open choice worth roughly 130 log-units (LIK_EXCESS_C14_TARGET).
#
# WHAT IT SETTLES. Whether the constraint's failure to bite is
#   (a) a WIDTH problem -- the wide target set simply cannot outvote the
#       atmospheric fit, and the tight one would; or
#   (b) a STRUCTURAL one -- the model overshoots the observed ocean inventory at
#       every bomb_total, so no target set can locate a consistent value, and
#       the defect is in the bomb delivery shape or the sink, as 2026-08-11
#       section 6.4(c) argued from the atmospheric side.
#
# Read the ocean-excess columns against the target being scored, NOT against the
# other one: the two sets disagree about 1975 and 1995 in opposite directions.
#
# This is a PROFILE, not a posterior. The conditional maximum over the other
# parameters at fixed bomb_total is a diagnostic of the fit surface's shape; it
# is not a marginal likelihood and must not be quoted as one.
#
# Usage: Rscript calibration/profile_bomb_total.R
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

PROF_BT_GRID  <- c(102, 120, 135, 150, 165)   # 102 = the citable N&L total
PROF_TARGETS  <- c("table4_obs_range", "table2_peacock")
PROF_MAXIT    <- 8000
PROF_RESTARTS <- 2
PROF_SEED     <- 2026
PROF_PENALTY  <- 1e6
PROF_BOMB_WIN <- c(1960, 1970)
PROF_REF_YRS  <- c(1975, 1995)
PROF_OUT      <- file.path("calibration", "output", "profile_bomb_total.rds")

set.seed(PROF_SEED)
md <- readRDS(file.path("calibration", "output", "mode_fit.rds"))
i_bt <- match("bomb_total", CCX_PARAM_NAMES)
free <- setdiff(seq_along(CCX_PARAM_NAMES), i_bt)

# The target set is read at ccx_prepare_obs() time, so switching it means
# rebuilding obs and the posterior closure -- done once per target, not per grid
# point.
make_ctx <- function(target) {
  old <- LIK_EXCESS_C14_TARGET
  assign("LIK_EXCESS_C14_TARGET", target, envir = globalenv())
  on.exit(assign("LIK_EXCESS_C14_TARGET", old, envir = globalenv()), add = TRUE)
  obs <- ccx_prepare_obs()
  stopifnot(identical(obs$excess_c14$target, target))
  list(obs = obs, lp = ccx_make_logpost(obs = obs))
}

make_obj <- function(ctx, bt) {
  u_fixed <- .to_unc(bt, CCX_PARAM_TABLE$bomb_total)
  function(v) {
    u <- numeric(length(CCX_PARAM_NAMES))
    u[free] <- v; u[i_bt] <- u_fixed
    names(u) <- CCX_PARAM_NAMES
    val <- ctx$lp(u)
    if (!is.finite(val)) return(PROF_PENALTY)
    -val
  }
}

diagnose <- function(ctx, u) {
  names(u) <- CCX_PARAM_NAMES
  pv <- ccx_unc_to_par(u)
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p$gamma_enso <- pv$gamma_enso
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14,
                          bomb_total_kmol = pv$bomb_total)
  out <- ccx_run_fast(sp, F)$out
  ms  <- ccx_model_stats(out, ctx$obs)

  o <- ctx$obs$d14_nh_ann; m <- ms$d14$NH
  k <- match(o$year, m$year); g <- !is.na(k)
  res <- o$value[g] - m$mean[k[g]]; yy <- o$year[g]
  kb  <- yy >= PROF_BOMB_WIN[1] & yy <= PROF_BOMB_WIN[2]

  oc <- ctx$obs$co2_ann$MLO; mc <- ms$co2$MLO
  kc <- match(oc$year, mc$year); gc <- !is.na(kc)
  rc <- oc$level[gc] - mc$level[kc[gc]]

  yrv <- floor(out$t + 1e-9)
  exc <- vapply(PROF_REF_YRS, function(y)
    ccx_c14_kmol(mean(out$ocean_C14[yrv == y]) - out$ocean_C14[1]), numeric(1))

  parts <- ccx_loglik(out, ctx$obs, list(sigma_co2 = pv$sigma_co2,
                                         sigma_d13c = pv$sigma_d13c,
                                         sigma_d14c = pv$sigma_d14c),
                      by_stream = TRUE)
  list(par = pv, ocean_exc = exc, deep_d14c = sp$diagnostics$d14c_deep_ocean,
       d14c_bomb_rms = sqrt(mean(res[kb]^2)), d14c_all_rms = sqrt(mean(res^2)),
       co2_rms = sqrt(mean(rc^2)), parts = parts)
}

cat(sprintf("profiling bomb_total over %s kmol, under %s\n",
            paste(PROF_BT_GRID, collapse = ", "), paste(PROF_TARGETS, collapse = " and ")))
cat(sprintf("current mode: bomb_total %.1f, logpost %.1f (target '%s')\n\n",
            md$par_mode$bomb_total, md$logpost, LIK_EXCESS_C14_TARGET))

rows <- list(); details <- list()
t_start <- Sys.time()
for (tg in PROF_TARGETS) {
  ctx <- make_ctx(tg)
  e <- ctx$obs$excess_c14
  cat(sprintf("--- target '%s': %s ---\n", tg,
              paste(sprintf("%d %.1f +/- %.1f", e$year, e$centre, e$half_width),
                    collapse = "   ")))
  for (bt in PROF_BT_GRID) {
    t0 <- Sys.time()
    obj <- make_obj(ctx, bt)
    v <- md$u_mode[free]
    best <- obj(v)
    for (rep in seq_len(PROF_RESTARTS)) {
      fit <- optim(v, obj, method = "Nelder-Mead",
                   control = list(maxit = PROF_MAXIT, reltol = 1e-10))
      v <- fit$par; best <- fit$value
    }
    u <- numeric(length(CCX_PARAM_NAMES))
    u[free] <- v; u[i_bt] <- .to_unc(bt, CCX_PARAM_TABLE$bomb_total)
    d <- diagnose(ctx, u)
    rows[[length(rows) + 1]] <- data.frame(
      target = tg, bomb_total = bt, logpost = -best,
      excess_term = d$parts[["excess_c14_ocean"]],
      d14c_term = d$parts[["d14c_NH"]] + d$parts[["d14c_SH"]],
      ocean_exc_1975 = d$ocean_exc[1], ocean_exc_1995 = d$ocean_exc[2],
      deep_d14c = d$deep_d14c, d14c_bomb_rms = d$d14c_bomb_rms,
      co2_rms = d$co2_rms, k_w = d$par$k_w, kz = d$par$kz,
      sigma_d14c = d$par$sigma_d14c,
      minutes = as.numeric(difftime(Sys.time(), t0, units = "mins")))
    details[[paste(tg, bt)]] <- d
    r <- rows[[length(rows)]]
    cat(sprintf("  bt %5.0f  lp %9.1f  exc_term %8.2f  ocean %6.1f/%6.1f  deep %6.1f  bombRMS %5.1f  CO2rms %5.2f  (%.1f min)\n",
                r$bomb_total, r$logpost, r$excess_term, r$ocean_exc_1975,
                r$ocean_exc_1995, r$deep_d14c, r$d14c_bomb_rms, r$co2_rms, r$minutes))
  }
  cat("\n")
}

tab <- do.call(rbind, rows)
saveRDS(list(table = tab, details = details, grid = PROF_BT_GRID,
             targets = PROF_TARGETS, mode = md), PROF_OUT)
cat(sprintf("total %.1f min; wrote %s\n",
            as.numeric(difftime(Sys.time(), t_start, units = "mins")), PROF_OUT))

for (tg in PROF_TARGETS) {
  s <- tab[tab$target == tg, ]
  cat(sprintf("\nbest under '%s': bomb_total %.0f (logpost %.1f)\n",
              tg, s$bomb_total[which.max(s$logpost)], max(s$logpost)))
}
