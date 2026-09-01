# =====================================================================
# profile_kz_ventilation.R -- is the 14C misfit wrong PARAMETERS or a wrong MODEL?
#
# THE QUESTION. The 2026-08-11 mode fits CO2 well (MLO annual rms 0.99 ppm) and
# 14C badly: bomb_total rails at +4.60 sigma (151 kmol against Naegler & Levin's
# citable 99.3-104.9), sigma_d14c inflates to 45.8 permil, and the deep ocean
# comes out at -115 permil against an observed -150 to -200 -- roughly 600 years
# too young. The hypothesis (Marcus, 2026-08-11) is that a single kz is being
# asked to serve two processes that are distinct in the real ocean: decadal,
# surface-intensified bomb-14C penetration, and millennial overturning age.
#
# THE TEST. Fix kz on a grid. At each value re-optimise EVERY other parameter, so
# the rest of the model gets its best possible chance to compensate. Then read
# off, together:
#
#   * deep-ocean Delta14C  -- can any kz reach the observed -150 to -200?
#   * the bomb window fit  -- what does getting there cost?
#   * bomb_total           -- does it still need 48 % more 14C than was produced?
#   * the CO2 fit          -- does the ocean still take up the right amount of carbon?
#
# WHAT WOULD FALSIFY THE HYPOTHESIS. If some kz gives a defensible deep-ocean
# Delta14C AND a bomb-window fit no worse than the mode AND bomb_total inside its
# prior, then the problem is parameters, the mode-finder simply missed it, and no
# structural change is needed. If instead the deep-ocean value and the bomb window
# improve at OPPOSITE ends of the kz range, one diffusivity cannot serve both and
# the fix has to be structural -- an advective term, or a second ventilation
# timescale -- not a retune.
#
# This is a PROFILE, not a posterior. The conditional maximum over the other
# parameters at fixed kz is a diagnostic of the fit surface's shape; it is not a
# marginal likelihood and must not be quoted as one.
#
# Usage: Rscript calibration/profile_kz_ventilation.R
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

PROF_KZ_GRID   <- c(500, 1000, 2000, 4000, 8354, 16000, 32000)  # 8354 = the mode
PROF_MAXIT     <- 8000
PROF_SEED      <- 2026
PROF_PENALTY   <- 1e6
PROF_BOMB_WIN  <- c(1960, 1970)   # the window quoted in the handoff
PROF_DEEP_OBS  <- c(-200, -150)   # observed deep-ocean Delta14C range, permil
PROF_OUT       <- file.path("calibration", "output", "profile_kz.rds")

set.seed(PROF_SEED)
obs <- ccx_prepare_obs()
lp_full <- ccx_make_logpost(obs = obs)

md <- readRDS(file.path("calibration", "output", "mode_fit.rds"))
u_mode <- md$u_mode
i_kz <- match("kz", CCX_PARAM_NAMES)
free <- setdiff(seq_along(CCX_PARAM_NAMES), i_kz)

# log-posterior as a function of the 16 free parameters, at fixed kz
make_obj <- function(kz_val) {
  u_fixed <- .to_unc(kz_val, CCX_PARAM_TABLE$kz)
  function(v) {
    u <- numeric(length(CCX_PARAM_NAMES))
    u[free] <- v; u[i_kz] <- u_fixed
    names(u) <- CCX_PARAM_NAMES
    val <- lp_full(u)
    if (!is.finite(val)) return(PROF_PENALTY)
    -val
  }
}

# diagnostics that are NOT in the likelihood -- the free checks the whole test
# turns on
diagnose <- function(u) {
  names(u) <- CCX_PARAM_NAMES
  pv <- ccx_unc_to_par(u)
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  p <- ccx_set_enso(p, pv)
  sp <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14,
                         bomb_total_kmol = pv$bomb_total)
  r <- ccx_run_fast(sp, F)
  out <- r$out
  ms <- ccx_model_stats(out, obs)

  # bomb-window Delta14C rms, NH
  o <- obs$d14_nh_ann; m <- ms$d14$NH
  k <- match(o$year, m$year); g <- !is.na(k)
  res <- o$value[g] - m$mean[k[g]]
  yy <- o$year[g]
  kb <- yy >= PROF_BOMB_WIN[1] & yy <= PROF_BOMB_WIN[2]

  # CO2 annual level rms, MLO
  oc <- obs$co2_ann$MLO; mc <- ms$co2$MLO
  kc <- match(oc$year, mc$year); gc <- !is.na(kc)
  rc <- oc$level[gc] - mc$level[kc[gc]]

  # ocean bomb-14C inventory at 2024, by the paired with/without construction
  F0 <- F; F0$c14_bomb <- 0
  s0 <- ccx_run_fast(sp, F0)$state
  ocean_idx <- unlist(lapply(HEMIS, function(h) c(sp$aux$idx[[h]]$ml, sp$aux$idx[[h]]$oc)))
  mol_per_GtCeq <- ccx_const("MOL_C_PER_GtC") * ccx_const("R14_STD")
  bomb_ocean <- sum(r$state[ocean_idx, "C14"] - s0[ocean_idx, "C14"]) * mol_per_GtCeq / 1000

  list(par = pv,
       deep_d14c = sp$diagnostics$d14c_deep_ocean,
       prod_c14  = sp$prod_c14,
       prod_ratio = sp$diagnostics$prod_ratio,
       ocean_C   = sp$diagnostics$ocean_C_GtC,
       d14c_bomb_rms = sqrt(mean(res[kb]^2)),
       d14c_bomb_bias = mean(res[kb]),
       d14c_all_rms  = sqrt(mean(res^2)),
       co2_rms = sqrt(mean(rc^2)), co2_bias = mean(rc),
       bomb_ocean_kmol = bomb_ocean,
       ll_parts = ccx_loglik(out, obs, list(sigma_co2 = pv$sigma_co2,
                                            sigma_d13c = pv$sigma_d13c,
                                            sigma_d14c = pv$sigma_d14c),
                             by_stream = TRUE))
}

cat(sprintf("profiling kz over %s\n", paste(PROF_KZ_GRID, collapse = ", ")))
cat(sprintf("mode is kz = %.0f, logpost %.1f\n\n", md$par_mode$kz, md$logpost))

rows <- list()
t_start <- Sys.time()
for (kzv in PROF_KZ_GRID) {
  t0 <- Sys.time()
  obj <- make_obj(kzv)
  v <- u_mode[free]
  best <- obj(v)
  for (rep in 1:3) {
    fit <- optim(v, obj, method = "Nelder-Mead",
                 control = list(maxit = PROF_MAXIT, reltol = 1e-11))
    if (fit$value < best) { v <- fit$par; best <- fit$value }
  }
  pol <- tryCatch(optim(v, obj, method = "BFGS", control = list(maxit = 300)),
                  error = function(e) NULL)
  if (!is.null(pol) && pol$value < best) { v <- pol$par; best <- pol$value }

  u <- numeric(length(CCX_PARAM_NAMES))
  u[free] <- v; u[i_kz] <- .to_unc(kzv, CCX_PARAM_TABLE$kz)
  d <- diagnose(u)
  d$kz <- kzv; d$logpost <- -best; d$u <- u
  rows[[length(rows) + 1]] <- d
  cat(sprintf(paste0("kz %6.0f | logpost %9.1f | deep D14C %+7.1f | prod %5.0f (%.2fx) | ",
                     "bomb_total %6.1f | bombwin rms %5.1f | CO2 rms %5.2f | ocean bomb %5.1f kmol",
                     " | %4.1f min\n"),
              kzv, d$logpost, d$deep_d14c, d$prod_c14, d$prod_ratio,
              d$par$bomb_total, d$d14c_bomb_rms, d$co2_rms, d$bomb_ocean_kmol,
              as.numeric(Sys.time() - t0, units = "mins")))
}

saveRDS(list(grid = PROF_KZ_GRID, rows = rows, mode = md,
             bomb_window = PROF_BOMB_WIN, deep_obs = PROF_DEEP_OBS,
             built = as.character(Sys.Date())), PROF_OUT)

cat(sprintf("\ntotal %.1f min; wrote %s\n",
            as.numeric(Sys.time() - t_start, units = "mins"), PROF_OUT))

# ---- the verdict, stated explicitly ---------------------------------
deep <- vapply(rows, function(r) r$deep_d14c, numeric(1))
bomb <- vapply(rows, function(r) r$d14c_bomb_rms, numeric(1))
btot <- vapply(rows, function(r) r$par$bomb_total, numeric(1))
co2  <- vapply(rows, function(r) r$co2_rms, numeric(1))
ok_deep <- deep >= PROF_DEEP_OBS[1] & deep <= PROF_DEEP_OBS[2]
ok_bomb <- bomb <= min(bomb) * 1.15
ok_prior <- btot <= 104.9 & btot >= 99.3

cat("\n=== VERDICT ===\n")
cat(sprintf("kz reaching the observed deep-ocean range [%g, %g]: %s\n",
            PROF_DEEP_OBS[1], PROF_DEEP_OBS[2],
            if (any(ok_deep)) paste(PROF_KZ_GRID[ok_deep], collapse = ", ") else "NONE"))
cat(sprintf("kz within 15%% of the best bomb-window fit: %s\n",
            paste(PROF_KZ_GRID[ok_bomb], collapse = ", ")))
cat(sprintf("kz with bomb_total inside the Naegler & Levin prior [99.3, 104.9]: %s\n",
            if (any(ok_prior)) paste(PROF_KZ_GRID[ok_prior], collapse = ", ") else "NONE"))
if (any(ok_deep & ok_bomb & ok_prior)) {
  cat("=> A single kz CAN satisfy all three. The problem is parameters, not structure.\n")
} else {
  cat("=> NO single kz satisfies all three. One diffusivity cannot serve both the\n")
  cat("   decadal bomb transient and the millennial deep-ocean age: the fix is\n")
  cat("   STRUCTURAL (advection, or a second ventilation timescale), not a retune.\n")
}
