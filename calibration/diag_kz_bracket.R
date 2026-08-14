# =====================================================================
# diag_kz_bracket.R -- should CCX_PARAM_TABLE's kz = [3830, 6200] bracket be
# deleted before the conveyor-OFF refit, and if so what replaces it?
#
# WHY THIS IS NOT THE ONE-LINE CHANGE THE PLAN CALLS FOR. Handoff 13h sec.2.1a
# says delete the bracket, citing 12d sec.6 -- "conditional on the pure-diffusion
# column it was bisected on". That rationale is CONVEYOR-CONDITIONAL: it says the
# bracket must not be carried across to a model whose ocean has an advective
# limb. But PHASE 2 is explicitly conveyor-OFF (13h sec.3.2), i.e. exactly the
# single-column ocean the bracket WAS bisected on, and 13h sec.3.2 leans on that
# same fact to argue the deep-D14C target is not blocking here. The two sections
# cannot both be right about the same column.
#
# The rationale that DOES survive is 12d sec.8, and it is a different one: the
# bound LEAKS. kz sat obediently inside [3830, 6200] at the 16-parameter mode and
# the deep ocean still came out at -145.0 permil, outside the bracket, because
# the kz -> deep-D14C mapping shifts bodily when the OTHER parameters move.
# 12d sec.8's conclusion -- "do not bound a parameter as a proxy for an
# observable; deep D14C is observed, constrain it where observations live" -- is
# a prescription for a LIKELIHOOD TERM, not for an unaccompanied deletion.
#
# THE COST OF GETTING THIS WRONG IS MEASURED, NOT ASSUMED: unbounded, kz ran to
# 10,686 and put the deep ocean at -129.9 permil (12d sec.6). Deleting the
# bracket with nothing in its place restores that.
#
# WHAT THIS SCRIPT MEASURES, so the three options can be priced:
#   [1] the kz -> deep-D14C map on the CURRENT model (converted land, beta 0.60),
#       and a re-bisection of the [-200, -150] bracket. Does 404d66d move it?
#   [2] the LEAK, re-measured here rather than inherited: how far the same map
#       moves when the rest of the parameter vector moves to mode_fit's.
#   [3] which way the likelihood pulls kz at fixed everything-else, so we can see
#       whether the bound is binding or decorative.
#
# It does NOT decide anything. The choice is Marcus' (13h sec.5, decision 2).
# RUNTIME ~2 min: [1] and [2] are spinups only; [3] runs the model.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- labels derive from constants (project rule) --------------------
KB_YEARS    <- c(1750, 2024)
KB_BOMB_REF <- 102
KB_DEEP_OBS <- c(-200, -150)          # the bracket CCX_PARAM_TABLE targets
KB_INCUMBENT <- c(CCX_PARAM_TABLE$kz$lo, CCX_PARAM_TABLE$kz$hi)
KB_GRID     <- c(1000, 2000, 3000, 3830, 5000, 6200, 8000, 10686, 16000)
KB_NATRE    <- 536                    # m2/yr, Ledwell NATRE -- the physical scale
KB_MODE     <- ccx_path("calibration", "output", "mode_fit.rds")

A_NH <- ccx_const("OCEAN_AREA_NH"); A_SH <- ccx_const("OCEAN_AREA_SH")
gmean <- function(a, b) (a * A_NH + b * A_SH) / (A_NH + A_SH)

# deep-ocean preindustrial D14C at a given kz, on a given base parameter vector.
# It comes out of the SPINUP diagnostics, so no forward run is needed -- this is
# a property of the steady state, which is what the observed bracket describes.
kb_deep <- function(kz, base = ccx_default_params()) {
  p <- base; p$kz <- kz; p$q_conv <- 0
  s <- try(ccx_spinup(p), silent = TRUE)
  if (inherits(s, "try-error")) return(NA_real_)
  dh <- s$diagnostics$d14c_deep_by_hemi
  gmean(dh[["NH"]], dh[["SH"]])
}

kb_bisect <- function(target, base = ccx_default_params(), lo = 500, hi = 40000) {
  f <- function(k) kb_deep(k, base) - target
  if (is.na(f(lo)) || is.na(f(hi)) || f(lo) * f(hi) > 0) return(NA_real_)
  stats::uniroot(f, c(lo, hi), tol = 0.5)$root
}

cat(sprintf("\n[1] kz -> DEEP D14C ON THE CURRENT MODEL (conveyor OFF, beta %.2f)\n",
            ccx_default_params()$beta))
cat(sprintf("    incumbent bracket [%g, %g], targeting D14C in [%g, %g] permil\n",
            KB_INCUMBENT[1], KB_INCUMBENT[2], KB_DEEP_OBS[1], KB_DEEP_OBS[2]))
cat(sprintf("    for scale: Ledwell's NATRE thermocline diffusivity is %g m2/yr\n\n", KB_NATRE))
cat("        kz     deep D14C (global mean, permil)\n")
for (k in KB_GRID)
  cat(sprintf("    %7.0f     %+9.2f%s\n", k, kb_deep(k),
              if (k == 10686) "   <- where UNBOUNDED kz ran in 12d sec.6" else ""))
lo_now <- kb_bisect(KB_DEEP_OBS[1]); hi_now <- kb_bisect(KB_DEEP_OBS[2])
cat(sprintf("\n    RE-BISECTED on this model: D14C %g at kz %.1f ; %g at kz %.1f\n",
            KB_DEEP_OBS[1], lo_now, KB_DEEP_OBS[2], hi_now))
cat(sprintf("    incumbent          [%g, %g]\n", KB_INCUMBENT[1], KB_INCUMBENT[2]))
cat(sprintf("    shift from 404d66d + the beta re-centring: lo %+.1f, hi %+.1f\n",
            lo_now - KB_INCUMBENT[1], hi_now - KB_INCUMBENT[2]))

# ---------------------------------------------------------------------
cat("\n[2] THE LEAK, re-measured (12d sec.8 said the map SHIFTS with the vector)\n")
if (!file.exists(KB_MODE)) {
  cat("    mode_fit.rds absent -- skipped\n")
} else {
  mr <- readRDS(KB_MODE)$par_mode
  pm <- utils::modifyList(ccx_default_params(),
                          mr[intersect(names(mr), names(ccx_default_params()))])
  cat(sprintf("    mode vector: beta %.3f  q10 %.3f  h_ml %.1f  k_w %.0f  tau_ex %.3f\n",
              pm$beta, pm$q10, pm$h_ml, pm$k_w, pm$tau_ex))
  cat("    NB mode_fit.rds is stale in five ways now (13g sec.0.5 plus the beta\n")
  cat("    re-centring) -- it is used here ONLY as a DIFFERENT parameter vector,\n")
  cat("    to measure how far the map moves, not as a fit.\n\n")
  cat("        kz     defaults     at the mode      shift\n")
  for (k in KB_GRID[KB_GRID <= 10686]) {
    a <- kb_deep(k); b <- kb_deep(k, pm)
    cat(sprintf("    %7.0f    %+9.2f     %+9.2f    %+7.2f\n", k, a, b, b - a))
  }
  lo_m <- kb_bisect(KB_DEEP_OBS[1], pm); hi_m <- kb_bisect(KB_DEEP_OBS[2], pm)
  cat(sprintf("\n    bracket re-bisected AT THE MODE: [%.1f, %.1f]\n", lo_m, hi_m))
  cat(sprintf("    against [%.1f, %.1f] at the defaults -- the bracket is not a\n",
              lo_now, hi_now))
  cat("    property of the model, it is a property of (model, parameter vector).\n")
  cat(sprintf("    A kz pinned at the incumbent hi bound %g gives D14C %+.2f at the\n",
              KB_INCUMBENT[2], kb_deep(KB_INCUMBENT[2], pm)))
  cat(sprintf("    mode vs %+.2f at the defaults: THAT difference is the leak.\n",
              kb_deep(KB_INCUMBENT[2])))
}

# ---------------------------------------------------------------------
cat("\n[3] WHICH WAY DOES THE LIKELIHOOD PULL kz? (1-D, everything else default)\n")
cat("    If the data want kz at or beyond a bound, the bound is load-bearing and\n")
cat("    deleting it changes the refit. If they want it inside, it is decorative.\n")
obs <- ccx_prepare_obs()
# TWO sigma sets, because sigma_d13c is the open decision (13h sec.2.1c) and
# d13C turns out to be the stream that pushes kz upward -- so how hard it pushes
# is set by a number nobody has chosen yet. Reporting one set would hide that.
KB_ERR_SETS <- list(
  `table init, sigma_d13c 0.10` = list(sigma_co2 = 1.5, sigma_d13c = 0.10, sigma_d14c = 5),
  `mode_fit,   sigma_d13c 0.44` = list(sigma_co2 = 1.5, sigma_d13c = 0.44, sigma_d14c = 5))
KB_FAMILY <- list(CO2 = "^co2_", d13C = "^d13c_", D14C = "^d14c_")
kb_ll <- list()
for (k in KB_GRID) {
  p <- ccx_default_params(); p$kz <- k; p$q_conv <- 0
  s <- try(ccx_spinup(p), silent = TRUE)
  if (inherits(s, "try-error")) { kb_ll[[as.character(k)]] <- NULL; next }
  F <- ccx_build_forcing("historical", KB_YEARS, prod_c14 = s$prod_c14,
                         bomb_total_kmol = KB_BOMB_REF)
  o <- ccx_run_fast(s, F)$out
  if (anyNA(o$co2_NH)) next
  kb_ll[[as.character(k)]] <- lapply(KB_ERR_SETS, function(e)
    ccx_loglik(o, obs, e, by_stream = TRUE))
}
for (en in names(KB_ERR_SETS)) {
  cat(sprintf("\n  -- %s --\n", en))
  cat("        kz     deep D14C      CO2        d13C        D14C       TOTAL\n")
  tot <- c()
  for (k in KB_GRID) {
    ll <- kb_ll[[as.character(k)]][[en]]
    if (is.null(ll)) { cat(sprintf("    %7.0f     no run\n", k)); next }
    fam <- vapply(KB_FAMILY, function(pat) sum(ll[grepl(pat, names(ll))]), 0)
    tot[as.character(k)] <- sum(ll)
    cat(sprintf("    %7.0f     %+9.2f  %10.1f %10.1f %10.1f %11.1f\n",
                k, kb_deep(k), fam[["CO2"]], fam[["d13C"]], fam[["D14C"]], sum(ll)))
  }
  kbest <- as.numeric(names(tot)[which.max(tot)])
  cat(sprintf("    1-D argmax at kz = %g  -- %s the incumbent bracket [%g, %g]\n",
              kbest, if (kbest >= KB_INCUMBENT[1] && kbest <= KB_INCUMBENT[2])
                       "INSIDE" else "OUTSIDE", KB_INCUMBENT[1], KB_INCUMBENT[2]))
}
cat("\n    CAVEAT, and it is the one that matters: this is 1-D at the DEFAULTS.\n")
cat("    12d sec.6's runaway to kz 10,686 was a 16-parameter conditional\n")
cat("    optimum on the PRE-404d66d model at beta 0.088. A 1-D profile cannot\n")
cat("    rule that out; it can only say the bound is not binding HERE.\n")
cat("\n    The deep-D14C column is NOT in any of those log-likelihoods -- there is\n")
cat("    no deep-D14C term in R/likelihood.R. That absence is the whole reason\n")
cat("    the bracket exists, and it is what 12d sec.8 proposed to fix.\n")
