# ---------------------------------------------------------------------------
# diag_seas_ml_convergence.R -- TWO pre-checks round 6 owes and did not have.
#
# (1) SUBSTEP CONVERGENCE. `ccx_substeps_for()` bounds DIFFUSION and ADVECTION,
#     but R/model.R's own substepping rationale is the AIR-SEA timescale
#     h_ml / k_w -- and that timescale SHRINKS WITH THE MIXED LAYER. Measured at
#     the canonical: mean h_ml/k_w = 0.0296 yr (10.8 d), but at the summer
#     minimum (26.3 m) it is 0.0158 yr (5.8 d), against a substep of 30/4 = 7.6 d.
#     ⛔ So in summer the mixed layer equilibrates FASTER THAN A SUBSTEP RESOLVES,
#     and the eigenvalue bound cannot see it: it returns 4 either way, because
#     CCX_SUBSTEPS_MIN = 4 is the floor. The seasonal-ML change to that bound is
#     therefore INERT at the canonical -- an untested path guarding a real risk.
#     If P1's amplitude moves with substeps, P1 was measuring the integrator.
#
# (2) ANNUAL-MEAN RECTIFICATION. Unlike the retired pCO2-side shim, option A
#     moves REAL CARBON seasonally, so it rectifies onto the annual-mean state.
#     The design ACCEPTS that class of rectification as physics (seasonal SST,
#     the fertilization rectifier) -- but the prereg owes a MEASUREMENT that it
#     SETTLES rather than drifting, since that is the whole argument for not
#     building a periodic spinup.
#
# ⚠ Both read the SAME runs, so they cost one set of arms, not two.
# ---------------------------------------------------------------------------

TAG       <- "20260909"
OUT_RDS   <- file.path("outputs", "diagnostics", paste0("seas_ml_convergence_", TAG, ".rds"))
OUT_LOG   <- sub("[.]rds$", ".log", OUT_RDS)
SUBSTEPS  <- c(4L, 8L, 16L)      # 4 = what ccx_substeps_for() returns at the canonical
CONV_YRS  <- c(1990, 2000)
# TWO WINDOWS, because ONE CANNOT SEPARATE THE HYPOTHESES. A trend in the
# on-minus-off difference over an INDUSTRIAL window has two possible causes and
# they call for opposite responses:
#   (a) SPIN-IN -- the model has not reached its seasonal steady state, in which
#       case the aseasonal spinup is the wrong start and a PERIODIC one is owed;
#   (b) the mechanism CHANGES ANTHROPOGENIC UPTAKE -- real physics, and not a
#       spinup problem at all.
# A QUIET window (near-zero emissions) has no (b) to confound it, so a trend
# there IS spin-in. Measuring only the industrial window -- as the first version
# of this section did -- reports "STILL DRIFTING" identically for both.
DRIFT_WINDOWS <- list(quiet = c(1750, 1850), industrial = c(1900, 2000))
# CONVERGENCE TOLERANCE, scaled to the quantity it tests rather than picked:
# P1's band is 4-7 umol/kg wide, so a substep sensitivity worth 1 % of the
# amplitude (~0.1 umol/kg) is immaterial to it and 5 % would not be.
CONV_TOL_FRAC <- 0.01

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

con <- file(OUT_LOG, open = "wt")
say <- function(...) { m <- sprintf(...); cat(m, "\n"); cat(m, "\n", file = con) }

md <- readRDS(ccx_mode_file())
p0 <- ccx_overlay_par(ccx_mode_base(md), ccx_mode_params(md))
arm <- function(seas_ml) { p <- p0; p$ent_seas_amp_SH <- 0; p$seas_ml <- seas_ml; p }

say("ROUND 6 -- substep convergence and annual-mean rectification")
say("mode file : %s", ccx_mode_file())
say("h_ml %.3f m | ccx_substeps_for at seas_ml 0 / 1 : %d / %d  (CCX_SUBSTEPS_MIN = %d)",
    p0$h_ml, ccx_substeps_for(arm(0)), ccx_substeps_for(arm(1)), CCX_SUBSTEPS_MIN)

## ---- ML DIC over the final year, at a given substep count ----------------
ml_dic <- function(p, yrs, substeps) {
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", yrs, prod_c14 = sp$prod_c14)
  o  <- ccx_run(sp, F, substeps = substeps)$out
  keep <- F$t >= (yrs[2] - 1) & F$t < yrs[2]
  co <- if (ccx_seas_ml_on(p)) ccx_mld_shape() else NULL
  stats::setNames(lapply(HEMIS, function(h) {
    fac <- if (is.null(co)) rep(1, sum(keep))
           else vapply(F$t[keep], function(t) ccx_mld_eval(co[[h]], t)$f, numeric(1))
    o[[paste0("ml_C_", h)]][keep] * ccx_const("MOL_C_PER_GtC") /
      (sp$aux$ml_mass_kg[[h]] * fac)
  }), HEMIS)
}

## ---- (1) does P1's amplitude depend on the integrator? -------------------
say("")
say("(1) SUBSTEP CONVERGENCE -- P1's amplitude (umol/kg) vs substeps")
say("    %-9s %10s %10s", "substeps", "NH amp", "SH amp")
amps <- lapply(SUBSTEPS, function(ns) {
  on  <- ml_dic(arm(1), CONV_YRS, ns)
  off <- ml_dic(arm(0), CONV_YRS, ns)
  a <- vapply(HEMIS, function(h) {
    d <- (on[[h]] - off[[h]]) * 1e6; (max(d) - min(d)) / 2 }, numeric(1))
  say("    %-9d %10.3f %10.3f", ns, a[["NH"]], a[["SH"]])
  a
})
names(amps) <- as.character(SUBSTEPS)
ref <- amps[[length(amps)]]                       # the finest as reference
worst <- max(vapply(HEMIS, function(h)
  abs(amps[["4"]][[h]] - ref[[h]]) / ref[[h]], numeric(1)))
say("    worst |4 - %d| / %d = %.3f %%  (tolerance %.1f %% of the amplitude)",
    max(SUBSTEPS), max(SUBSTEPS), 100 * worst, 100 * CONV_TOL_FRAC)
say("    VERDICT: %s", if (worst <= CONV_TOL_FRAC)
      "CONVERGED at the shipped substep count -- P1 is NOT measuring the integrator" else
      "*** NOT CONVERGED -- P1's number is substep-dependent and must be re-read ***")

## ---- (2) does the mechanism drift the annual mean? -----------------------
# ⛔ THE QUANTITY IS A TREND, NOT A LEVEL. A first version of this section
# reported the mean on-minus-off shift over the final year and called it "the
# drift". That is a LEVEL: a rectification that settled 200 years ago and one
# still growing produce the SAME number. The design's claim is that the shift
# SETTLES, so what must be measured is whether it is still moving at the end.
ml_dic_annual <- function(p, yrs, substeps) {
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", yrs, prod_c14 = sp$prod_c14)
  o  <- ccx_run(sp, F, substeps = substeps)$out
  co <- if (ccx_seas_ml_on(p)) ccx_mld_shape() else NULL
  yr <- floor(F$t)
  stats::setNames(lapply(HEMIS, function(h) {
    fac <- if (is.null(co)) rep(1, length(F$t))
           else vapply(F$t, function(t) ccx_mld_eval(co[[h]], t)$f, numeric(1))
    dic <- o[[paste0("ml_C_", h)]] * ccx_const("MOL_C_PER_GtC") /
           (sp$aux$ml_mass_kg[[h]] * fac)
    tapply(dic, yr, mean)                      # ANNUAL means, one per year
  }), HEMIS)
}

say("")
say("(2) ANNUAL-MEAN RECTIFICATION -- LEVEL, TREND, and WHICH HYPOTHESIS THE TREND SUPPORTS")
# ORDERING, not an invented number: the trend must be SMALL COMPARED WITH the
# seasonal amplitude it rides on. 5 % of the amplitude per century is the line.
TREND_FRAC <- 0.05
res2 <- lapply(names(DRIFT_WINDOWS), function(wn) {
  yrs <- DRIFT_WINDOWS[[wn]]
  on_l  <- ml_dic_annual(arm(1), yrs, max(SUBSTEPS))
  off_l <- ml_dic_annual(arm(0), yrs, max(SUBSTEPS))
  say("")
  say("  [%s window %d-%d]", wn, yrs[1], yrs[2])
  say("    %-3s %12s %12s %15s %14s", "hem", "1st decade", "last decade",
      "trend /century", "|trend| vs amp")
  tr <- vapply(HEMIS, function(h) {
    d  <- (on_l[[h]] - off_l[[h]]) * 1e6
    yy <- as.numeric(names(d))
    # SECOND HALF only: the first decades carry the spin-in an aseasonal start
    # necessarily produces, and including them measures that transient instead
    # of whether the shift has settled.
    half <- yy >= (yrs[1] + diff(yrs) / 2)
    t100 <- unname(stats::coef(stats::lm(d[half] ~ yy[half]))[2]) * 100
    say("    %-3s %12.3f %12.3f %15.4f %13.2f %%", h, mean(head(d, 10)),
        mean(tail(d, 10)), t100, 100 * abs(t100) / mean(ref))
    t100
  }, numeric(1))
  list(window = yrs, trend = tr,
       settled = max(abs(tr)) < TREND_FRAC * mean(ref))
})
names(res2) <- names(DRIFT_WINDOWS)

say("")
say("  ⭐ THE QUIET WINDOW IS THE ONE THAT DECIDES THE SPINUP.")
say("  quiet      settled? %-5s  -> %s", res2$quiet$settled,
    if (res2$quiet$settled)
      "NO SPIN-IN: the aseasonal spinup STANDS, no periodic spinup owed" else
      "*** SPIN-IN: a PERIODIC SPINUP IS OWED -- the 09-09i claim does not hold ***")
say("  industrial settled? %-5s  -> %s", res2$industrial$settled,
    if (res2$industrial$settled) "no anthropogenic-uptake effect either" else
      "the mechanism CHANGES ANTHROPOGENIC UPTAKE (real physics, not a spinup fault)")
say("  ⚠ A quiet-settled / industrial-drifting pair is the EXPECTED and ACCEPTABLE outcome:")
say("    it says the seasonal mixed layer alters how the ocean takes up anthropogenic carbon,")
say("    which is a RESULT to report, not a numerical defect to fix.")

dir.create(dirname(OUT_RDS), showWarnings = FALSE, recursive = TRUE)
saveRDS(list(mode_file = ccx_mode_file(), substeps = SUBSTEPS, amps = amps,
             worst_rel = worst, tol = CONV_TOL_FRAC, rectification = res2, trend_frac = TREND_FRAC,
             conv_window = CONV_YRS, drift_windows = DRIFT_WINDOWS, built = Sys.time()), OUT_RDS)
say("")
say("wrote %s", OUT_RDS)
close(con)
