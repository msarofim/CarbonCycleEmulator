# =====================================================================
# diag_kz_railed.R -- IS THE MODE RAILED AGAINST THE kz BRACKET?
#                     ANSWER: NO. THE BRACKET IS REDUNDANT, NOT BINDING,
#                     AND kz IS NOT THE PARTITION LEVER IT LOOKED LIKE.
#
# ***THE FILENAME AND THE FIRST DRAFT OF THIS HEADER BOTH ASSERTED "RAILED".
# THE SCRIPT DISPROVED IT. The header is rewritten rather than the finding,
# per the standing rule that a label stating a computed quantity has to be
# computed.***
#
# THE PREMISE THAT MOTIVATED IT, which was reasonable and wrong. `kz` is
# logit-bounded to [3942.5, 6528] and the arm-N mode sits at 6461.5 -- u_mode
# 3.634, sigmoid 0.974, 97.4 % of the way to the ceiling. That LOOKS like an
# optimiser pressed against a wall, and it mattered because
# diag_land_eagerness.R TEST E had just found `kz` to be the model's ONLY
# PARTITION LEVER: it moves land DOWN, ocean UP and CO2 DOWN together, which is
# exactly the combination the mode's three misses call for (land +2.04 sd,
# ocean -0.62 sd, CO2 ~+5 ppm). kz 6461 -> 8000 lands the ocean sink on 3.20
# against GCB's 3.22 +/- 0.40 and takes 4.2 ppm off the level.
#
# WHY THE BRACKET EXISTS, from R/calibrate.R's own block: it is NOT a physical
# prior on mixing. It is a BOUND USED AS A PROXY FOR AN OBSERVABLE -- deep-ocean
# Delta14C, bisected so kz maps into the observed [-200, -150] permil bracket,
# because at the time nothing in the likelihood scored that layer. That block
# states the exit condition explicitly:
#
#     "keep the bracket, add the term at n_eff = 20. DELETE IT ONLY AFTER A
#      REFIT SHOWS THE TERM HOLDING kz ALONE."
#
# The term (`d14c_deep_ocean`) now exists, so this asks the exit condition
# directly, without a refit: outside the bracket, does kz run away?
#
# WHAT IT FOUND, in three parts:
#
#  1. THE LIKELIHOOD TURNS OVER AT 6462 -- INSIDE the bracket. kz sits at 97.4 %
#     of the range because that is where the DATA put it, not because it is
#     against a wall. The bracket is REDUNDANT (nothing needs it) and NOT
#     BINDING (removing it changes nothing).
#
#  2. WHAT HOLDS kz IS THE CO2 LEVEL STREAMS, by two orders of magnitude --
#     -138 at the mode against -581 at kz 8000, while `d14c_deep_ocean` moves
#     5.8 log-units and `gcb_ocean_sink` 1.9. The deep-14C term PREFERS LOWER kz
#     and the ocean-sink term prefers HIGHER; the CO2 record outvotes both.
#
#  3. AND rep_dC DOES NOT RESCUE IT. Since the CO2 level streams are fitted
#     through a free +5.18 sd offset, the obvious suspicion was that the pin is
#     an artefact of freezing that offset -- 21c sec.2c's trap, committed by me.
#     Profiled with rep_dC re-optimised at every kz, the optimum moves 6462 ->
#     6528, worth +0.6 log-units. THE PIN SURVIVES: rep_dC can TRANSLATE the
#     record and raising kz changes its SHAPE, and a free offset does not
#     rescue a curvature miss.
#
# SO TEST E's DOOR IS CLOSED. The partition knob exists and the data hold it
# shut. Any fix for the land/ocean partition has to come from somewhere else.
#
# ONE COROLLARY WORTH KEEPING, and it is a good-news one. The bracket ceiling
# 6528 was bisected so kz maps to the observed deep-Delta14C bracket edge,
# -150 permil. The CO2 record's own optimum lands at 6462 INDEPENDENTLY. Two
# unrelated observables -- the shape of the atmospheric CO2 record and the
# radiocarbon age of the deep ocean -- put kz in the same place to within 1 %.
#
# FROZEN, and the caveat is the same as everywhere (21c sec.2c): a conditional
# profile is not a posterior statement and cannot say where a refit would land.
# It CAN say whether a bound is binding, which is the exit condition -- and
# point 3 is the compensation check that keeps that claim honest.
#
# Usage:  Rscript calibration/diag_kz_railed.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

KR_MODE_FILE <- ccx_mode_file()
KR_YEARS     <- c(1750, 2024)
KR_DEEP_OBS  <- c(-200, -150)      # the observed bracket the bound was bisected on
KR_SINK_WIN  <- c(2015, 2024)
KR_GCB_LAND  <- 2.36; KR_GCB_OCEAN <- 3.22
KR_GRID      <- c(5000, 6000, 6461.5, 6528, 7000, 8000, 10000, 12000, 16000, 20000)

md <- readRDS(KR_MODE_FILE); pm <- md$par_mode
KR_LO <- md$kz_bracket[1]; KR_HI <- md$kz_bracket[2]
p0 <- ccx_default_params()
for (n in intersect(names(p0), CCX_PARAM_NAMES)) p0[[n]] <- pm[[n]]
p0$pump_mode <- md$pump_mode
obs <- ccx_prepare_obs()

cat(sprintf("mode %s\n  kz %.1f in bracket [%.1f, %.1f] -> %.1f %% of the range\n",
            basename(KR_MODE_FILE), pm$kz, KR_LO, KR_HI,
            100 * (pm$kz - KR_LO) / (KR_HI - KR_LO)))
cat(sprintf("  deep-ocean Delta14C observed bracket the bound was bisected on: [%d, %d] permil\n\n",
            KR_DEEP_OBS[1], KR_DEEP_OBS[2]))

kr_eval <- function(kz) {
  p <- p0; p$kz <- kz
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", KR_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale)
  r <- ccx_run_fast(sp, F)
  if (is.null(r) || anyNA(r$out$co2_NH)) return(NULL)
  o <- r$out
  eluc <- ccx_forcing_eluc_annual(F)
  err <- list(sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC,
              grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c)
  bs <- ccx_loglik(o, obs, err, luc = eluc,
                   deep = sp$diagnostics$d14c_bottom_box,
                   ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE)
  gv <- function(n) if (is.na(bs[n])) 0 else as.numeric(bs[n])
  yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  sa <- function(v) stats::approx(o$t, v, xout = bnd, rule = 2)$y
  k <- yrs >= KR_SINK_WIN[1] & yrs <= KR_SINK_WIN[2]
  e <- eluc$eluc[match(yrs[k], eluc$year)]
  # PRIOR WITHOUT THE BRACKET. Every other parameter is frozen, so only kz's own
  # prior term differs across the grid -- and the bracket is a HARD logit bound,
  # so outside it there is no density to evaluate. Reporting the likelihood plus
  # the non-kz priors (a constant here) is therefore the correct "bracket
  # removed" object: it is what the posterior would be if kz's only constraint
  # were the observations.
  list(kz = kz, ll = sum(bs), deep = sp$diagnostics$d14c_bottom_box,
       d14deep = gv("d14c_deep_ocean"), ocn = gv("gcb_ocean_sink"),
       lnd = gv("gcb_land_sink"),
       co2 = gv("co2_level_MLO") + gv("co2_level_SPO"),
       d14 = gv("d14c_NH") + gv("d14c_SH"),
       grad = gv("ocean_grad_dic") + gv("ocean_grad_d13c") + gv("ocean_grad_alk"),
       land_s = mean(diff(sa(o$land_C))[k] + e),
       ocean_s = mean(diff(sa(o$ocean_C))[k]),
       co2_2024 = mean(o$co2_SH[floor(o$t + 1e-9) == 2024]))
}

res <- Filter(Negate(is.null), lapply(KR_GRID, kr_eval))
ll0 <- res[[which.min(abs(vapply(res, function(x) x$kz, 0) - pm$kz))]]$ll

cat(sprintf("%-8s %8s %9s %9s %9s %9s %9s %8s %8s %9s\n", "kz", "deepD14",
            "d_loglik", "d14deep", "ocn_sink", "lnd_sink", "co2_lev", "land", "ocean", "CO2 2024"))
for (x in res) {
  mark <- if (abs(x$kz - pm$kz) < 1) " <- mode" else if (x$kz > KR_HI) "" else ""
  cat(sprintf("%-8.0f %8.1f %+9.1f %9.1f %9.1f %9.1f %9.1f %8.2f %8.2f %9.1f%s%s\n",
              x$kz, x$deep, x$ll - ll0, x$d14deep, x$ocn, x$lnd, x$co2,
              x$land_s, x$ocean_s, x$co2_2024,
              if (x$kz > KR_HI) "  [OUTSIDE]" else "", mark))
}

# ---- THE EXIT CONDITION ---------------------------------------------
kzs <- vapply(res, function(x) x$kz, 0); lls <- vapply(res, function(x) x$ll, 0)
dps <- vapply(res, function(x) x$deep, 0)
best <- res[[which.max(lls)]]
cat(sprintf("\nEXIT CONDITION -- does `d14c_deep_ocean` hold kz once the bracket is gone?\n"))
cat(sprintf("  best kz on the grid, bracket removed : %.0f  (%+.1f log-units over the mode)\n",
            best$kz, best$ll - ll0))
cat(sprintf("  its deep Delta14C                    : %.1f permil  -> %s the observed [%d, %d]\n",
            best$deep, if (best$deep >= KR_DEEP_OBS[1] && best$deep <= KR_DEEP_OBS[2])
              "INSIDE" else "OUTSIDE", KR_DEEP_OBS[1], KR_DEEP_OBS[2]))
cat(sprintf("  deep Delta14C at the bracket ceiling : %.1f permil\n",
            res[[which.min(abs(kzs - KR_HI))]]$deep))
turns <- best$kz < max(kzs)
interior <- turns && best$kz <= KR_HI
inobs <- best$deep >= KR_DEEP_OBS[1] && best$deep <= KR_DEEP_OBS[2]
cat(sprintf("  log-posterior turns over inside the grid: %s\n", if (turns) "YES" else "NO"))
cat(sprintf("  and the turnover is %s the bracket ceiling %.0f\n",
            if (interior) "INSIDE" else "ABOVE", KR_HI))
cat(sprintf("  => %s\n", if (interior && inobs)
    "BRACKET NOT BINDING. The likelihood turns over INSIDE it, so kz sits at 97.4 % of the range because that is where the DATA put it, not because it is against a wall. The bracket is redundant -- and it is NOT what holds the partition lever shut."
  else if (turns && inobs)
    "BRACKET IS TRUNCATING: the unbounded optimum is ABOVE the ceiling and its deep box is still inside the observed range. Exit condition MET."
  else if (turns)
    "Turns over, but lands the deep box OUTSIDE the observed range -- the bracket is doing work the term does not."
  else
    "TERM FAILS. kz runs to the grid ceiling; the bracket is still load-bearing."))
cat(sprintf("\n  sinks at that kz: land %.2f (%+.2f sd)  ocean %.2f (%+.2f sd)  vs mode %.2f / %.2f\n",
            best$land_s, (best$land_s - KR_GCB_LAND) / LIK_GCB_LAND_SD,
            best$ocean_s, (best$ocean_s - KR_GCB_OCEAN) / LIK_GCB_OCEAN_SD,
            res[[which.min(abs(kzs - pm$kz))]]$land_s, res[[which.min(abs(kzs - pm$kz))]]$ocean_s))


# ---- SO WHAT IS HOLDING kz? AND IS THAT HOLD REAL? ------------------
# Read the per-stream columns above rather than the total. Across kz 6462 ->
# 8000 the three candidate holders move by:
#
#   co2_level (MLO+SPO)   -138 -> -581     443 log-units   <- dominates
#   d14c_deep_ocean        -6.0 -> -11.8     5.8           (and it prefers LOWER kz)
#   gcb_ocean_sink        -11.0 -> -12.9     1.9           (its own optimum is ~7000)
#
# **kz is pinned by the CO2 LEVEL streams, by two orders of magnitude.** And
# those are exactly the streams fitted through `rep_dC`, which sits at +5.18 sd
# of its prior (diag_rep_dC_shape.R) precisely because it is free to translate
# them bodily. Raising kz LOWERS CO2 uniformly -- 4.2 ppm from 6462 to 8000 --
# which is a translation, which is the one thing `rep_dC` exists to absorb.
#
# SO THE PROFILE ABOVE IS THE MISTAKE 21c sec.2c WARNS ABOUT, COMMITTED BY ME:
# a frozen-block profile read as if it bounded the posterior, when the frozen
# block contains the exact compensating parameter. Re-run it with `rep_dC`
# PROFILED -- re-optimised at every kz, which is free because it enters the
# likelihood as a pure offset -- and see whether the pin survives.
cat("\n\nkz PROFILED WITH rep_dC FREE (re-optimised at each kz)\n")
kr_eval_free <- function(kz) {
  p <- p0; p$kz <- kz
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", KR_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale)
  r <- ccx_run_fast(sp, F)
  if (is.null(r) || anyNA(r$out$co2_NH)) return(NULL)
  o <- r$out; eluc <- ccx_forcing_eluc_annual(F)
  og <- ccx_ocean_grad_scored(o, sp)
  # Objective INCLUDING rep_dC's own prior, since rep_dC is what is being
  # re-optimised -- otherwise the profile would buy level fit for free.
  f <- function(rd) {
    e <- list(sigma_d14c = pm$sigma_d14c, rep_dC = rd,
              grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c)
    -(ccx_loglik(o, obs, e, luc = eluc, deep = sp$diagnostics$d14c_bottom_box,
                 ocean_grad = og) +
      stats::dnorm(rd, 0, LIK_CO2_REP_ERR, log = TRUE))
  }
  op <- stats::optimize(f, c(-15, 20), tol = 1e-4)
  yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  sa <- function(v) stats::approx(o$t, v, xout = bnd, rule = 2)$y
  k <- yrs >= KR_SINK_WIN[1] & yrs <= KR_SINK_WIN[2]
  e <- eluc$eluc[match(yrs[k], eluc$year)]
  list(kz = kz, obj = -op$objective, rep = op$minimum,
       deep = sp$diagnostics$d14c_bottom_box,
       land_s = mean(diff(sa(o$land_C))[k] + e),
       ocean_s = mean(diff(sa(o$ocean_C))[k]),
       co2_2024 = mean(o$co2_SH[floor(o$t + 1e-9) == 2024]))
}
rf <- Filter(Negate(is.null), lapply(KR_GRID, kr_eval_free))
o0 <- rf[[which.min(abs(vapply(rf, function(x) x$kz, 0) - pm$kz))]]$obj
cat(sprintf("%-8s %9s %9s %9s %8s %8s %9s\n", "kz", "d_objpost", "rep_dC", "deepD14",
            "land", "ocean", "CO2 2024"))
for (x in rf)
  cat(sprintf("%-8.0f %+9.1f %9.2f %9.1f %8.2f %8.2f %9.1f%s%s\n", x$kz, x$obj - o0,
              x$rep, x$deep, x$land_s, x$ocean_s, x$co2_2024,
              if (x$kz > KR_HI) "  [OUTSIDE]" else "",
              if (abs(x$kz - pm$kz) < 1) " <- mode" else ""))
bf <- rf[[which.max(vapply(rf, function(x) x$obj, 0))]]
cat(sprintf("\nBEST kz WITH rep_dC FREE : %.0f  (%+.1f over the mode)  rep_dC %.2f = %.2f sd\n",
            bf$kz, bf$obj - o0, bf$rep, bf$rep / LIK_CO2_REP_ERR))
cat(sprintf("  land %.2f (%+.2f sd)   ocean %.2f (%+.2f sd)   deep D14C %.1f permil %s\n",
            bf$land_s, (bf$land_s - KR_GCB_LAND) / LIK_GCB_LAND_SD,
            bf$ocean_s, (bf$ocean_s - KR_GCB_OCEAN) / LIK_GCB_OCEAN_SD, bf$deep,
            if (bf$deep >= KR_DEEP_OBS[1] && bf$deep <= KR_DEEP_OBS[2]) "(inside obs)" else "(OUTSIDE obs)"))
cat(sprintf("  and it is %s the bracket ceiling %.0f\n",
            if (bf$kz > KR_HI) "ABOVE" else "below", KR_HI))

# ---- WHAT THIS SCRIPT CONCLUDED, INCLUDING AGAINST ITSELF -----------
# The rep_dC-compensation hypothesis in the block above is WRONG, and the
# profile is what says so: with rep_dC re-optimised at every kz the optimum
# moves 6462 -> 6528, worth +0.6 log-units. The pin SURVIVES. rep_dC absorbs
# part of the level shift (5.18 -> 3.32 at kz 8000) and the penalty is still
# -163.6, because raising kz changes the SHAPE of the CO2 trajectory and rep_dC
# can only TRANSLATE it. A free offset does not rescue a curvature miss.
#
# SO: kz IS WELL DETERMINED, IT IS NOT RAILED, AND IT IS NOT A LEVER.
# diag_land_eagerness.R TEST E identified it as the model's only partition knob;
# this script closes that door. The knob exists and the data hold it shut.
#
# AND ONE CORROBORATION WORTH KEEPING. The bracket ceiling 6528 was bisected so
# that kz maps to the observed deep-Delta14C bracket edge, -150 permil. The CO2
# record's own optimum lands at 6462 independently. **Two unrelated observables
# -- the shape of the atmospheric CO2 record and the radiocarbon age of the deep
# ocean -- put kz in the same place to within 1 %.** That is a real consistency
# in the model and it should be said out loud somewhere a reader will see it.
