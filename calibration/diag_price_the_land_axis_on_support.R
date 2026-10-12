# ⛔ HELD-ERA RECORD (2026-10-12). This script builds its Joos PD100 by hand with the climate HELD
# (`gmst <- gmst[1]`), which is no longer the live protocol: card 5, gate L, the scorecard and
# diag_joos_irf.R now run R/joos_irf.R ccx_pd100() with the climate FREE (Marcus 2026-10-12, "free
# everywhere"; scope "Builder + live consumers"). Its hand-held table also leaves the observed-SST
# columns running and restarts T_deep at 0 -- both FIXED in the builder (ccx_pulse_forcings,
# ccx_pulse_ref_state), NOT here. Kept unconverted as the record of what it printed: do not quote its
# IRFs or partitions as the canonical's.
# =====================================================================
# THE LAND AXIS, RE-PRICED ON THE MODEL'S OWN SUPPORT
#
# WHY THIS EXISTS. `diag_price_the_gates.R` PART 2 reports that gate 7 closes
# at beta_max = 0.35 for -232 log-units, and handoff 2026-08-31 s.8.3 puts that
# number to Marcus as a judgement call. THE NUMBER IS MEASURED OFF-SUPPORT.
#
# That frontier re-optimises `kz`, `fert_k` and `q10` as `exp(u)` -- an
# UNBOUNDED log parameterisation. But `kz` is a LOGIT parameter on a hard
# support [3942.5, 6528]. Every row of the published land axis except the
# anchor sits above the top of it:
#
#     beta_max   kz published    on support?
#     0.5552        6486.0       yes (u = 4.105, prior -7.858)
#     0.5000        6608.1       NO  (u = NaN,   prior -Inf)
#     0.4500        6799.6       NO
#     0.4000        7121.6       NO
#     0.3500        7666.6       NO   <- the row that "closes gate 7" for -232
#     0.3000        8601.1       NO
#
# So part of gate 7's closure was bought with ocean mixing the model is NOT
# ALLOWED TO HAVE: at beta_max 0.35 the frontier uses kz = 7667, 17 % above the
# top of its own bracket, where the prior is -Inf and `.to_unc()` is NaN. The
# posterior price of that point is INFINITE, and the likelihood-only price of
# -232 is a LOWER BOUND on the on-support cost.
#
# ⚠ THE DEFECT CLASS. The 08-31 session added a self-check gate pinning the
# frontier's LIKELIHOOD to the objective's, after a truncated likelihood cost
# 253 log-units of construction artifact. That gate is necessary and it passes
# here. But nothing pinned the frontier's PARAMETERS to the objective's
# SUPPORT, and `loglik_of()` never evaluates a prior, so there was nothing to
# object. Same family, one level up: the challenger was scored on the right
# function at points the function's own domain excludes.
#
# ⚠ THE OCEAN AXIS IS NOT DAMAGED BY THIS. It also leaves the support (kz 3000
# and below are under lo = 3942.5), but it leaves it in the direction that
# makes the optimiser's job EASIER and still got worse on every gate. "kz is
# not the lever" survives; only the favourable price on the land axis does not.
#
# WHAT THIS SCRIPT DOES. The same land axis, with every re-optimised parameter
# moving in ITS OWN transform, so the search cannot leave the support -- plus a
# gate that refuses to report any point that does. Reports both the likelihood
# price (comparable with the published table) and the POSTERIOR price, which is
# the decision-relevant total.
#
# Run:  Rscript calibration/diag_price_the_land_axis_on_support.R   (~12 min)
# =====================================================================

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

PG_MODE   <- file.path("calibration", "output", "refit_20260830_gamma_diff_remap",
                       "from90", "mode_fit_pumpN.rds")
PG_KZ     <- c(6400, 5000, 4000, 3000, 2000, 1200, 800, 500)
PG_FREE   <- c("beta_max", "fert_k", "q10")   # re-optimised at every kz
PG_WIN    <- c(2015, 2023)                    # gate 7 window, GCB decade
PG_MAXIT  <- 400
PG_OUT    <- "outputs/diagnostics/price_the_gates.rds"

obs  <- ccx_prepare_obs()
gcb  <- local({ g <- as.data.frame(obs$gcb); k <- g$year >= PG_WIN[1] & g$year <= PG_WIN[2]
                list(land = mean(g$land_sink[k]), ocean = mean(g$ocean_sink[k])) })
GCB_LAND_SD <- 0.50; GCB_OCEAN_SD <- 0.40    # GCB 2025 stated 1 sigma
cat(sprintf("GATE 7 targets on %d-%d: land %.3f +/- %.2f, ocean %.3f +/- %.2f\n",
            PG_WIN[1], PG_WIN[2], gcb$land, GCB_LAND_SD, gcb$ocean, GCB_OCEAN_SD))
joos_irf_at <- function(y) with(JOOS_T5, a0 + sum(a * exp(-y / tau)))
JOOS_100 <- joos_irf_at(100)
cat(sprintf("GATE 12a target: IRF(100) = %.3f (Joos T5 multi-model mean)\n\n", JOOS_100))

md <- readRDS(PG_MODE); ccx_adopt_mode_band(md)
p0 <- ccx_mode_params(PG_MODE)
# ⚠ MIGRATE BEFORE OVERLAYING. `p0` is a 21-parameter list (the mode predates
# the 08-31 split) and `base` is a 22-parameter one, so the plain
# `intersect(names(base), names(p0))` overlay this script inherited SILENTLY
# DROPS the fitted NPP lag and leaves `base` at the DEFAULT 2.25 instead of the
# fitted 1.7502. intersect() does not error; it just omits. Measured: the
# objective's own gate below then reads -3187.902 against -1494.871, i.e.
# **1693 log-units**, because the seasonal CO2 streams carry the model's
# highest leverage (co2_seasonal_MLO 4118, memory ccx_stream_leverage).
p0 <- ccx_migrate_par_set(p0)
# ⚠ AND KEEP THE FULL FITTED VECTOR. `ccx_default_params()` has no slot for six
# of the fitted parameters (bomb_total, luc_scale, sigma_d14c, rep_dC,
# grad_off_co2, grad_off_d13c), so the overlay below drops them from `base` too
# -- the documented two-parameter-lists trap (memory ccx_two_param_lists), and
# the same one app/global.R's own comment describes. The LIKELIHOOD is fine:
# loglik_of() passes them explicitly via `err` and the forcing build. But the
# PRIOR is defined over all 22, so it is evaluated on this vector instead.
p0_fitted <- p0
base <- ccx_default_params()
for (n in intersect(names(base), names(p0))) base[[n]] <- p0[[n]]
stopifnot(identical(base$seas_lag_p_NH, p0$seas_lag_p),
          identical(base$seas_lag_p_SH, p0$seas_lag_p))
base <- ccx_set_enso(base, p0)
# ⚠ THE OBJECTIVE'S OWN err, NOT THE DIAGNOSTIC DEFAULTS. A first version of
# this script passed list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5)
# and dropped `luc`, `deep` and `ocean_grad` -- a DIFFERENT likelihood from the
# one the mode was fitted under, which read -1748.09 at the mode's own kz where
# the objective reads -1494.87. That is 253 log-units of pure construction
# artifact, the same trap as [[match_incumbents_optim]] wearing a new hat: a
# re-optimised challenger scored on a truncated likelihood. Replicated exactly
# from R/calibrate.R:918-931 and :943-945 instead.
err <- list(sigma_d14c = p0$sigma_d14c, rep_dC = p0$rep_dC,
            grad_off_co2 = p0$grad_off_co2, grad_off_d13c = p0$grad_off_d13c)

# ---- the three measurements, at one parameter vector -----------------
sinks_of <- function(r) {
  o <- r$out; yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  tt <- o$t; n <- length(tt)
  stock <- function(v) {
    y <- stats::approx(tt, v, xout = bnd)$y
    lo <- bnd < tt[1]; hi <- bnd > tt[n]
    if (any(lo)) y[lo] <- v[1] + (bnd[lo] - tt[1]) * (v[2] - v[1]) / (tt[2] - tt[1])
    if (any(hi)) y[hi] <- v[n] + (bnd[hi] - tt[n]) * (v[n] - v[n-1]) / (tt[n] - tt[n-1])
    diff(y)
  }
  el <- ccx_forcing_eluc_annual(r$F); k <- yrs >= PG_WIN[1] & yrs <= PG_WIN[2]
  list(ocean = mean(stock(o$ocean_C)[k]),
       land  = mean((stock(o$land_C) + el$eluc[match(yrs, el$year)])[k]))
}
# joos_build_forcing() lives in diag_joos_irf.R, not R/, so it is replicated
# here EXACTLY. ⚠ AND SO IS ITS ARM HANDLING: that script sets JOOS_LUC_SCALE
# and JOOS_BOMB_TOTAL from the ARM'S OWN FITTED VALUES (diag_joos_irf.R:159-160),
# not from the 1 / 102 literals it initialises them to for the "defaults" arm.
# Using the literals here would score this frontier's IRF on a different
# background from the gate 12 numbers it is meant to be compared against.
# JOOS_HORIZON also lives in diag_joos_irf.R rather than R/. Matched exactly:
# it sets the window ccx_hold_forcing() solves the held background over, so a
# shorter one would move the background and make these IRFs incomparable with
# the gate 12 numbers.
JOOS_HORIZON    <- 300
JOOS_LUC_SCALE  <- p0$luc_scale
JOOS_BOMB_TOTAL <- p0$bomb_total
joos_build_forcing <- function(scenario, years, ...) {
  args <- list(...)
  if (is.null(args$bomb_total_kmol)) args$bomb_total_kmol <- JOOS_BOMB_TOTAL
  if (is.null(args$luc_scale))       args$luc_scale       <- JOOS_LUC_SCALE
  do.call(ccx_build_forcing, c(list(scenario, years), args))
}
irf100_of <- function(p) {
  sp <- ccx_spinup(p)
  Fh <- joos_build_forcing("historical", c(1750, JOOS_REF_YEAR), prod_c14 = sp$prod_c14)
  spr <- sp; spr$y <- ccx_run_fast(sp, Fh)$state
  Ff <- suppressWarnings(joos_build_forcing("historical",
        c(JOOS_REF_YEAR, JOOS_REF_YEAR + JOOS_HORIZON + 10),
        prod_c14 = sp$prod_c14, bomb_total_kmol = 0))
  for (cc in c("e_foss_NH","e_foss_SH","e_luc_NH","e_luc_SH","enso",
               "c14_bomb","c14_nuclear")) Ff[[cc]] <- 0
  Ff$gmst <- Ff$gmst[1]
  o <- ccx_irf_pd(spr, ccx_hold_forcing(spr, Ff, verbose = FALSE))
  o$irf[which.min(abs(o$t - 100))]
}
loglik_of <- function(p) {
  sp <- tryCatch(ccx_spinup(p), error = function(e) NULL)
  if (is.null(sp) || !is.finite(sp$prod_c14) || sp$prod_c14 <= 0) return(list(ll = -Inf))
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14,
                         bomb_total_kmol = p0$bomb_total, luc_scale = p0$luc_scale)
  r <- ccx_run_fast(sp, F); r$F <- F
  if (anyNA(r$out$co2_NH)) return(list(ll = -Inf))
  # all four extra arguments the objective passes -- `luc` is the MODEL's own
  # scaled land-use flux (so the gcb_land_sink reconstruction follows
  # luc_scale), `deep` the spinup's bottom-box D14C, `ocean_grad` the
  # sigma_eff-scored gradient rows.
  ll <- ccx_loglik(r$out, obs, err,
                   luc = ccx_forcing_eluc_annual(F),
                   deep = sp$diagnostics$d14c_bottom_box,
                   ocean_grad = ccx_ocean_grad_scored(r$out, sp))
  list(ll = ll, r = r)
}

# ---- the frontier ----------------------------------------------------
# ---- GATE: the frontier's likelihood must BE the objective's ---------
# At the mode's own parameters this must reproduce the stored stream sum. If it
# does not, every "price" below is measured on the wrong function.
.chk <- loglik_of(base)$ll
cat(sprintf("GATE: loglik at the mode's own vector = %.3f (objective's recomputed value -1494.871)\n",
            .chk))
if (abs(.chk - (-1494.871)) > 0.5)
  stop("the frontier's likelihood is NOT the objective's -- off by ",
       round(.chk + 1494.871, 3), " log-units. Fix before reading any price.")
cat("GATE PASSED: prices below are on the objective.\n\n")


# =====================================================================
# THE ON-SUPPORT LAND AXIS
# =====================================================================
# Every label, filename and threshold below derives from these.
LA_BETA      <- c(0.5552, 0.50, 0.45, 0.40, 0.35, 0.30)
LA_FREE      <- c("kz", "fert_k", "q10")   # re-optimised at every beta_max
LA_MAXIT     <- 400                        # matches PG_MAXIT
LA_OUT       <- "outputs/diagnostics/price_the_land_axis_on_support.rds"
LA_AXIS      <- "LAND AXIS (beta_max forced down; kz/fert_k/q10 re-optimised)"
LA_PUBLISHED <- "diag_price_the_gates.R PART 2 (2026-08-31, off-support)"
# the published numbers this corrects, for the side-by-side
LA_PUB_DLL   <- c(0.000, -8.273, -38.774, -105.863, -231.956, -449.422)
LA_PUB_KZ    <- c(6486.0, 6608.1, 6799.6, 7121.6, 7666.6, 8601.1)

cat(sprintf("\n%s\n%s\nre-optimised in each parameter's OWN transform\n\n",
            LA_AXIS, strrep("=", nchar(LA_AXIS))))

# ---- GATE: a point must be ON THE MODEL'S SUPPORT to be reportable --
# The gate whose absence produced the artifact this script corrects. It is
# derived from the objective's OWN parameter table, not from a literal, so it
# cannot go stale when a bracket is re-bisected.
on_support <- function(p, nms) {
  bad <- character(0)
  for (n in nms) {
    s <- CCX_PARAM_TABLE[[n]]
    u <- suppressWarnings(.to_unc(p[[n]], s))
    if (!is.finite(u) || !is.finite(suppressWarnings(s$prior(p[[n]]))))
      bad <- c(bad, sprintf("%s=%.4g (support [%s, %s])", n, p[[n]],
                            format(s$lo), format(s$hi)))
  }
  bad
}

# ---- the prior half of the objective, replicated from R/calibrate.R:977-979 --
# The frontier reports a LIKELIHOOD price. A parameter leaving its support does
# not change the likelihood at all -- it changes the PRIOR, to -Inf. So the
# posterior is the only quantity that can see the defect, and it is also the
# quantity the decision is actually about.
# `moved` are the only coordinates the frontier changes; every other fitted
# parameter keeps its mode value, which is what `p0_fitted` carries.
logprior_of <- function(moved) {
  pp <- p0_fitted
  for (n in names(moved)) pp[[n]] <- moved[[n]]
  s <- 0
  for (n in CCX_PARAM_NAMES) {
    sp <- CCX_PARAM_TABLE[[n]]
    v  <- pp[[n]]
    if (is.null(v)) stop("logprior_of(): no value for fitted parameter ", n)
    s <- s + sp$prior(v) + .log_jac(.to_unc(v, sp), sp)
  }
  s
}

rows <- list()
for (bm in LA_BETA) {
  pb <- base; pb$beta_max <- bm
  # ⚠ OPTIMISE IN EACH PARAMETER'S OWN TRANSFORM, not in log. This is the whole
  # correction: .from_unc() maps the real line onto the parameter's support, so
  # a logit parameter physically cannot be proposed outside its bracket.
  u0  <- vapply(LA_FREE, function(n) .to_unc(base[[n]], CCX_PARAM_TABLE[[n]]), numeric(1))
  put <- function(u) { q <- pb
    for (i in seq_along(LA_FREE))
      q[[LA_FREE[i]]] <- .from_unc(u[i], CCX_PARAM_TABLE[[LA_FREE[i]]])
    q }
  neg <- function(u) { v <- loglik_of(put(u))$ll; if (!is.finite(v)) 1e6 else -v }
  op  <- stats::optim(u0, neg, method = "Nelder-Mead",
                      control = list(maxit = LA_MAXIT, reltol = 1e-10))
  pb_opt <- put(op$par)

  bad <- on_support(pb_opt, LA_FREE)
  if (length(bad))
    stop("GATE FAILED -- a reported point is off-support: ", paste(bad, collapse = "; "),
         ". The transform-space search should have made this impossible.")

  L  <- loglik_of(pb_opt); sk <- sinks_of(L$r); irf <- irf100_of(pb_opt)
  rows[[length(rows) + 1]] <- data.frame(
    beta_max = bm, loglik = L$ll,
    logprior = logprior_of(c(list(beta_max = bm), pb_opt[LA_FREE])),
    kz = pb_opt$kz, fert_k = pb_opt$fert_k, q10 = pb_opt$q10,
    land = sk$land, ocean = sk$ocean,
    z_land  = (sk$land  - gcb$land)  / GCB_LAND_SD,
    z_ocean = (sk$ocean - gcb$ocean) / GCB_OCEAN_SD,
    irf100 = irf)
  x <- rows[[length(rows)]]
  cat(sprintf("beta_max %.4f | loglik %11.2f | land %5.2f (%+5.2f sd)  ocean %5.2f (%+5.2f sd) | IRF100 %.3f | kz %7.1f (%.0f%% of bracket) fert_k %7.2f\n",
              x$beta_max, x$loglik, x$land, x$z_land, x$ocean, x$z_ocean, x$irf100,
              x$kz, 100 * (x$kz - CCX_PARAM_TABLE$kz$lo) /
                    (CCX_PARAM_TABLE$kz$hi - CCX_PARAM_TABLE$kz$lo), x$fert_k))
}
res <- do.call(rbind, rows)
res$dloglik  <- res$loglik  - res$loglik[1]
res$dlogpost <- (res$loglik + res$logprior) - (res$loglik[1] + res$logprior[1])
dir.create(dirname(LA_OUT), recursive = TRUE, showWarnings = FALSE)
saveRDS(list(land_axis_on_support = res, gcb = gcb, joos100 = JOOS_100,
             mode = PG_MODE, published = LA_PUBLISHED), LA_OUT)

cat(sprintf("\n%s\n", strrep("=", 78)))
cat(sprintf("THE PRICE ON SUPPORT, against %s\n", LA_PUBLISHED))
cat(sprintf("%s\n", strrep("=", 78)))
cat(sprintf("%9s %11s %11s %11s %9s %9s %9s\n",
            "beta_max", "d loglik", "PUBLISHED", "d logpost", "z_land", "z_ocean", "IRF100"))
for (i in seq_len(nrow(res)))
  cat(sprintf("%9.4f %11.2f %11.2f %11.2f %9.2f %9.2f %9.3f\n",
              res$beta_max[i], res$dloglik[i], LA_PUB_DLL[i], res$dlogpost[i],
              res$z_land[i], res$z_ocean[i], res$irf100[i]))

cat(sprintf("\nkz, published vs on-support (bracket top %.0f):\n", CCX_PARAM_TABLE$kz$hi))
for (i in seq_len(nrow(res)))
  cat(sprintf("  beta_max %.4f: published %7.1f %-12s -> on-support %7.1f\n",
              res$beta_max[i], LA_PUB_KZ[i],
              if (LA_PUB_KZ[i] > CCX_PARAM_TABLE$kz$hi) "(OFF-SUPPORT)" else "(on support)",
              res$kz[i]))

g7 <- which(abs(res$z_land) < 1 & abs(res$z_ocean) < 1)
cat("\nREAD IT AS: gate 7 closes where BOTH |z| < 1.\n")
if (length(g7)) {
  i <- g7[1]
  cat(sprintf("ON SUPPORT, gate 7 first closes at beta_max %.4f for %.1f log-units of\n",
              res$beta_max[i], res$dloglik[i]))
  cat(sprintf("likelihood (%.1f of posterior), against the published %.1f.\n",
              res$dlogpost[i], LA_PUB_DLL[i]))
} else {
  cat("ON SUPPORT, GATE 7 NEVER CLOSES on this axis at any tested beta_max.\n")
  cat("The published closure was bought with off-support kz; there is no\n")
  cat("on-support point on this axis where both sinks sit inside 1 sigma.\n")
}
