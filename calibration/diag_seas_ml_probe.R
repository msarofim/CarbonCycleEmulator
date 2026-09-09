# ---------------------------------------------------------------------------
# diag_seas_ml_probe.R -- ROUND 6 PREDICTION P1, probed UNREFITTED at the
# canonical, before any Torch array. The T-D0 pattern: if the mechanism does not
# size to the observed order with nothing tuned, the round stops HERE.
#
# ⛔⛔ P1's BAND WAS RETIRED AS A GATE (Marcus, 2026-09-09m): "I'm fine getting
# rid of a pre-registered bound if and when we determine that the pre-registered
# bound was flawed in the first place." The band [10,17]/[8,14] is still COMPUTED
# and REPORTED below, but it no longer decides anything. Why it was retired
# (notes/options_2026-09-09l_p1_yardstick.md), all true independently of which
# side the model landed on, and three of the four true the day it was written:
#   (a) its SCALE leg (dC = 42-70) is the CODE UNDER TEST, and FITTED;
#   (b) its upper edge assumes the winter ML reaches layer 2, which it does not
#       (82.7 / 82.5 m against a layer-1 base of 101.4) -- dC is a POINT, +44.2;
#   (c) `f_ent x dC` is the wrong ALGEBRA for a moving boundary (see P1a);
#   (d) its target -- the ON-minus-OFF difference -- is UNOBSERVABLE IN
#       PRINCIPLE, because nature runs no seas_ml = 0 arm.
#
# ⭐ WHAT DECIDES NOW: two ORDERINGS from the physics (P1a, P1b), which is the
# standing rule's last resort when no external number is available -- assert an
# ordering between measured quantities rather than inventing a value. The
# OBSERVATIONAL replacement (SOM-FFN pCO2 amplitude, GATE S's own product and
# convention) is prepared in calibration/diag_so_pco2_amplitude.R but is BLOCKED
# on two rulings named there.
#
# ⭐ THE QUANTITY IS THE ON-MINUS-OFF DIFFERENCE IN ML DIC, not the raw seasonal
# cycle of ML DIC. The raw cycle also carries solubility and biology; the
# compensator it replaces was a pure ADDED anomaly, so the like-for-like
# comparison is the anomaly this mechanism ADDS. Comparing the raw cycle against
# the compensator's amplitude would be the like-for-like error this project has
# made three times.
#
# ⚠ The retired shim is held OFF in BOTH arms, so the difference is the seasonal
# mixed layer alone and not a swap of one channel for another.
# ---------------------------------------------------------------------------

TAG        <- "20260909"
OUT_RDS    <- file.path("outputs", "diagnostics", paste0("seas_ml_probe_", TAG, ".rds"))
OUT_LOG    <- sub("[.]rds$", ".log", OUT_RDS)
PROBE_YRS  <- c(1990, 2000)      # a modern decade; the last year is the one read
P1_BAND    <- list(NH = c(8, 14), SH = c(10, 17))   # the PRE-REGISTERED bands
COMPENSATOR <- c(winner_r3 = 21.2, ent26 = 19.0, prior_centre = 10.95)

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

con <- file(OUT_LOG, open = "wt")
say <- function(...) { m <- sprintf(...); cat(m, "\n"); cat(m, "\n", file = con) }

md <- readRDS(ccx_mode_file())
p0 <- ccx_overlay_par(ccx_mode_base(md), ccx_mode_params(md))
say("ROUND 6 -- PREDICTION P1, unrefitted at the canonical")
say("mode file : %s", ccx_mode_file())
say("h_ml %.3f m | probe window %d-%d | ⚠ UNREFITTED: nothing here is a fit",
    p0$h_ml, PROBE_YRS[1], PROBE_YRS[2])

## ---- the two arms: the retired shim is OFF in BOTH ------------------------
arm <- function(seas_ml) {
  p <- p0
  p$ent_seas_amp_SH <- 0      # the compensator is OFF in both arms
  p$seas_ml         <- seas_ml
  p
}

## ---- ML DIC (mol/kg) month by month over the final probe year -------------
# ⚠ THE R CORE, DELIBERATELY. ccx_run_fast() is the C++ twin and has no seasonal
# mixed layer yet -- R/cpp.R now STOPS rather than silently running the aseasonal
# one, which is the whole point of that guard. Both arms use the R core so the
# difference is the mechanism and not a change of core.
ml_dic_year <- function(p) {
  sp  <- ccx_spinup(p)
  F   <- ccx_build_forcing("historical", PROBE_YRS, prod_c14 = sp$prod_c14)
  o   <- ccx_run(sp, F)$out
  aux <- sp$aux
  co  <- if (ccx_seas_ml_on(p)) ccx_mld_shape() else NULL
  keep <- F$t >= (PROBE_YRS[2] - 1) & F$t < PROBE_YRS[2]
  out <- lapply(HEMIS, function(h) {
    mass <- aux$ml_mass_kg[[h]]
    fac  <- if (is.null(co)) rep(1, sum(keep))
            else vapply(F$t[keep], function(t) ccx_mld_eval(co[[h]], t)$f, numeric(1))
    # THE SAME definition the deriv uses: stock / (annual-mean mass x shape).
    # Using the annual-mean mass in both arms would compare a concentration
    # against a stock and manufacture the very cycle we are trying to measure.
    o[[paste0("ml_C_", h)]][keep] * ccx_const("MOL_C_PER_GtC") / (mass * fac)
  })
  stats::setNames(out, HEMIS)
}

say("")
say("running arm seas_ml = 0 (spinup + %d yr, R core) ...", diff(PROBE_YRS))
off <- ml_dic_year(arm(0))
say("running arm seas_ml = 1 ...")
on  <- ml_dic_year(arm(1))
# ⚠ Starting at 1990 rather than at the start of the emissions record raises
# ccx_build_forcing()'s start-up-transient warning. It is harmless HERE and only
# here: both arms carry the identical transient and the quantity read is their
# DIFFERENCE, so it cancels. ⛔ Do not copy this window into a probe that reads a
# LEVEL rather than a difference.

## ---- the amplitude the mechanism ADDS (REPORTED, no longer a gate) --------
say("")
say("REPORTED -- the ADDED seasonal ML DIC anomaly (on minus off), umol/kg")
say("  %-3s %10s %14s %10s   %s", "hem", "amp", "retired band", "in band?", "peak month")
res <- lapply(HEMIS, function(h) {
  d   <- (on[[h]] - off[[h]]) * 1e6
  amp <- (max(d) - min(d)) / 2
  bd  <- P1_BAND[[h]]
  say("  %-3s %10.2f   [%5.1f,%5.1f] %10s   %d", h, amp, bd[1], bd[2],
      if (amp >= bd[1] && amp <= bd[2]) "yes" else "no", which.max(d))
  list(hemi = h, amp = amp, retired_band = bd, month_max = which.max(d), series = d)
})
names(res) <- HEMIS
say("  ⚠ THE BAND IS REPORTED, NOT ENFORCED (retired as a gate 2026-09-09m).")
say("  for scale, the FITTED compensator this replaces: r3 winner %.1f, ent26 %.1f, centre %.2f",
    COMPENSATOR[["winner_r3"]], COMPENSATOR[["ent26"]], COMPENSATOR[["prior_centre"]])

## ---- P1a: BELOW THE UNDAMPED MOVING-BOUNDARY BOUND (a LAW) ----------------
# For a mixed layer that actually deepens, entrainment gives
#     dc/dt = (dh/dt)(c1 - c)/h  while deepening,  and  dc/dt = 0 while shoaling
# (detrainment sheds water at the ML's OWN concentration, changing stock and
# mass together and leaving the concentration untouched). Integrating the
# deepening limb gives (c1 - c) proportional to 1/h, hence
#     dc(peak-to-trough) = (c1 - c_min) * (1 - h_min/h_max).
# That is an UNDAMPED bound: a real DIC anomaly is continuously relaxed toward
# the atmosphere, which the retired pCO2-side shim never had to survive. So the
# emergent amplitude must be BELOW it and ABOVE zero. ⭐ Both quantities are
# MEASURED here, and the bound divides out nothing -- it is an ordering between
# two measured numbers, not an invented threshold.
say("")
say("P1a -- BELOW THE UNDAMPED MOVING-BOUNDARY BOUND (a LAW, not a fitted band)")
sp   <- ccx_spinup(arm(1))
gridA <- sp$aux$grid
co   <- ccx_mld_shape()
say("  %-3s %10s %10s %12s %10s %8s", "hem", "dC(L1-ML)", "1-hmin/hmax", "bound", "emergent", "ratio")
p1a <- vapply(HEMIS, function(h) {
  i    <- sp$aux$idx[[h]]
  dml  <- sp$y[i$ml, "C"] * ccx_const("MOL_C_PER_GtC") / sp$aux$ml_mass_kg[[h]] * 1e6
  m1   <- sp$aux$a_ls[[h]] * gridA$dz[2] * ccx_const("RHO_SEAWATER")
  dC   <- sp$y[i$oc[1], "C"] * ccx_const("MOL_C_PER_GtC") / m1 * 1e6 - dml
  fm   <- co[[h]]$f_month
  fac  <- 1 - min(fm) / max(fm)
  bound <- dC * fac / 2
  r    <- res[[h]]$amp / bound
  say("  %-3s %10.1f %10.4f %12.2f %10.2f %8.3f", h, dC, fac, bound, res[[h]]$amp, r)
  r
}, numeric(1))
ok_a <- all(p1a > 0 & p1a < 1)
say("    VERDICT: %s", if (ok_a)
      "PASS -- emergent amplitude is positive and below the undamped bound in BOTH hemispheres" else
      "*** FAIL -- outside (0, 1) x the undamped bound; the mechanism is not doing what the algebra says ***")

## ---- P1b: THE PEAK MUST FALL AT h_max (a LAW) -----------------------------
# The concentration rises ONLY while the layer deepens and is flat while it
# shoals, so the anomaly must peak at maximum mixed-layer depth. This is
# hemisphere-specific and sign-specific: a mechanism wired backwards fails it.
say("")
say("P1b -- THE ANOMALY MUST PEAK AT MAXIMUM MIXED-LAYER DEPTH (a LAW)")
p1b <- vapply(HEMIS, function(h) {
  mo_obs <- which.max(co[[h]]$f_month)
  mo_mod <- res[[h]]$month_max
  say("  %-3s h_max month %2d | anomaly peak month %2d | %s",
      h, mo_obs, mo_mod, if (mo_obs == mo_mod) "match" else "*** MISMATCH ***")
  mo_obs == mo_mod
}, logical(1))
say("    VERDICT: %s", if (all(p1b)) "PASS in both hemispheres" else
      "*** FAIL -- the anomaly does not peak at h_max; check the limb signs ***")

say("")
say("⛔ NEITHER P1a NOR P1b IS A SUBSTITUTE FOR AN OBSERVATION. They are orderings")
say("   the physics gives free, and they cannot reject a model that is merely the")
say("   WRONG SIZE -- only one that is wrong in SIGN, PHASE or by more than a")
say("   factor. The observational test (SOM-FFN pCO2 amplitude, GATE S's product")
say("   and convention) is prepared in calibration/diag_so_pco2_amplitude.R and is")
say("   BLOCKED on: (1) the band-to-box aggregation ruling, (2) the model exposing")
say("   mixed-layer pCO2, which no run output currently carries.")

dir.create(dirname(OUT_RDS), showWarnings = FALSE, recursive = TRUE)
saveRDS(list(mode_file = ccx_mode_file(), h_ml = p0$h_ml, window = PROBE_YRS,
             retired_band = P1_BAND, compensator = COMPENSATOR, result = res,
             p1a_ratio = p1a, p1b_match = p1b,
             dic_on = on, dic_off = off, built = Sys.time()), OUT_RDS)
say("wrote %s", OUT_RDS)
close(con)
