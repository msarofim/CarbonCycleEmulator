# =====================================================================
# IS THE GATE FAILURE A **WEIGHTING** PROBLEM OR A **STRUCTURAL** ONE?
#
# The 2026-08-30 refit gained +33.0 of LIKELIHOOD and moved no DESIGN gate in
# the right direction. Two readings, and they imply opposite next moves:
#
#   WEIGHTING  -- the model CAN satisfy gates 7 and 12; the objective simply
#                 does not ask it to (CO2 outvotes the partition streams 40:1,
#                 and the pulse IRF is not scored at all). Fix = re-weight.
#   STRUCTURAL -- no parameter vector satisfies them at once. Fix = structure
#                 (K_z(z), a second tau_ex, an interior source).
#
# This measures the FRONTIER between them: it walks `kz` down from the mode
# toward the Joos-consistent range and, AT EACH STEP, RE-OPTIMISES the
# fertilisation ridge so the CO2 fit is defended rather than sacrificed.
#
# ⚠ WHY NOT A ONE-AT-A-TIME SCAN. [[match_incumbents_optim]]: a fitted
# incumbent against an unfitted grid challenger manufactured 309 log-units of
# pure artifact in this very model. A raw kz scan would price the gates as
# unaffordable by construction. Re-optimising (beta_max, fert_k, q10) at each
# kz is the ISO-OBSERVABLE-SLICE discipline that experiment forced.
#
# ⚠ kz IS DRIVEN BELOW ITS FITTED BRACKET [3942.5, 6528] ON PURPOSE. The
# question is whether the bracket is standing in for a constraint, and that
# cannot be asked from inside it. Everything below therefore works in NATURAL
# parameter space and scores the LIKELIHOOD only -- no prior, no transform.
# A likelihood cost is the honest price; adding a prior that itself encodes
# the bracket would be assuming the answer.
#
# Run:  Rscript calibration/diag_price_the_gates.R      (~25 min)
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
base <- ccx_default_params()
for (n in intersect(names(base), names(p0))) base[[n]] <- p0[[n]]
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

rows <- list()
for (k in PG_KZ) {
  pk <- base; pk$kz <- k
  # re-optimise the fertilisation ridge (+q10) at THIS kz -- the iso-slice
  u0 <- log(unlist(base[PG_FREE]))
  neg <- function(u) { q <- pk
    for (i in seq_along(PG_FREE)) q[[PG_FREE[i]]] <- exp(u[i])
    v <- loglik_of(q)$ll; if (!is.finite(v)) 1e6 else -v }
  op <- stats::optim(u0, neg, method = "Nelder-Mead",
                     control = list(maxit = PG_MAXIT, reltol = 1e-10))
  pk_opt <- pk
  for (i in seq_along(PG_FREE)) pk_opt[[PG_FREE[i]]] <- exp(op$par[i])
  L <- loglik_of(pk_opt)
  s <- sinks_of(L$r); irf <- irf100_of(pk_opt)
  rows[[length(rows) + 1]] <- data.frame(
    kz = k, loglik = L$ll,
    beta_max = pk_opt$beta_max, fert_k = pk_opt$fert_k, q10 = pk_opt$q10,
    land = s$land, ocean = s$ocean,
    z_land = (s$land - gcb$land) / GCB_LAND_SD,
    z_ocean = (s$ocean - gcb$ocean) / GCB_OCEAN_SD,
    irf100 = irf)
  x <- rows[[length(rows)]]
  cat(sprintf("kz %6.0f | loglik %11.2f | land %5.2f (%+5.2f sd)  ocean %5.2f (%+5.2f sd) | IRF100 %.3f (Joos %.3f) | beta_max %.3f fert_k %7.2f q10 %.3f\n",
              x$kz, x$loglik, x$land, x$z_land, x$ocean, x$z_ocean, x$irf100, JOOS_100,
              x$beta_max, x$fert_k, x$q10))
}
res <- do.call(rbind, rows)
res$dloglik <- res$loglik - res$loglik[1]
dir.create(dirname(PG_OUT), recursive = TRUE, showWarnings = FALSE)
saveRDS(list(res = res, gcb = gcb, joos100 = JOOS_100, mode = PG_MODE), PG_OUT)

cat("\n=====================================================================\n")
cat("THE PRICE, read off the frontier\n")
cat("=====================================================================\n")
cat(sprintf("%8s %12s %10s %10s %9s\n", "kz", "d loglik", "z_land", "z_ocean", "IRF100"))
for (i in seq_len(nrow(res)))
  cat(sprintf("%8.0f %12.2f %10.2f %10.2f %9.3f\n",
              res$kz[i], res$dloglik[i], res$z_land[i], res$z_ocean[i], res$irf100[i]))
cat(sprintf("\nJoos IRF(100) = %.3f; gate 7 passes at |z| < 1 on BOTH sinks.\n", JOOS_100))

# =====================================================================
# PART 2 -- THE OTHER AXIS. Part 1 walks the OCEAN lever and finds it cannot
# close anything: as kz falls the optimiser raises beta_max/fert_k and the LAND
# takes over the drawdown, so the total is preserved (the CO2 record pins it),
# IRF(100) does not improve, and BOTH sinks get worse. That is a substitution
# degeneracy, and it means the ocean axis is the wrong one to have tested alone.
#
# So walk the LAND lever instead: weaken fertilisation and let kz re-optimise.
# If gate 7's land excess and gate 12a's fast pulse are the SAME defect, this is
# the axis on which both move together.
# =====================================================================
cat("\n\n=====================================================================\n")
cat("PART 2 -- THE LAND AXIS (beta_max forced down, kz/fert_k/q10 re-optimised)\n")
cat("=====================================================================\n")
PG_BETA  <- c(0.5552, 0.50, 0.45, 0.40, 0.35, 0.30)
PG_FREE2 <- c("kz", "fert_k", "q10")
rows2 <- list()
for (bm in PG_BETA) {
  pb <- base; pb$beta_max <- bm
  u0 <- log(unlist(base[PG_FREE2]))
  neg <- function(u) { q <- pb
    for (i in seq_along(PG_FREE2)) q[[PG_FREE2[i]]] <- exp(u[i])
    v <- loglik_of(q)$ll; if (!is.finite(v)) 1e6 else -v }
  op <- stats::optim(u0, neg, method = "Nelder-Mead",
                     control = list(maxit = PG_MAXIT, reltol = 1e-10))
  pb_opt <- pb
  for (i in seq_along(PG_FREE2)) pb_opt[[PG_FREE2[i]]] <- exp(op$par[i])
  L <- loglik_of(pb_opt); sk <- sinks_of(L$r); irf <- irf100_of(pb_opt)
  rows2[[length(rows2) + 1]] <- data.frame(
    beta_max = bm, loglik = L$ll, kz = pb_opt$kz, fert_k = pb_opt$fert_k,
    q10 = pb_opt$q10, land = sk$land, ocean = sk$ocean,
    z_land = (sk$land - gcb$land) / GCB_LAND_SD,
    z_ocean = (sk$ocean - gcb$ocean) / GCB_OCEAN_SD, irf100 = irf)
  x <- rows2[[length(rows2)]]
  cat(sprintf("beta_max %.4f | loglik %11.2f | land %5.2f (%+5.2f sd)  ocean %5.2f (%+5.2f sd) | IRF100 %.3f | kz %7.1f fert_k %7.2f\n",
              x$beta_max, x$loglik, x$land, x$z_land, x$ocean, x$z_ocean, x$irf100,
              x$kz, x$fert_k))
}
res2 <- do.call(rbind, rows2); res2$dloglik <- res2$loglik - res2$loglik[1]
saveRDS(list(ocean_axis = res, land_axis = res2, gcb = gcb, joos100 = JOOS_100,
             mode = PG_MODE), PG_OUT)
cat("\nREAD PART 2 AS: if z_land walks toward 0 while IRF100 walks toward 0.409,\n")
cat("the land sink and the pulse lifetime are ONE defect and this is the lever.\n")
cat("If z_land closes but IRF100 does not, they are two, and the pulse needs\n")
cat("something neither axis carries.\n")
cat("READ IT AS: if the gates close for a few tens of log-units it is WEIGHTING;\n")
cat("if closing them costs hundreds, or they never close at any kz, it is STRUCTURAL.\n")
