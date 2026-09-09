# ---------------------------------------------------------------------------
# diag_seas_ml_probe.R -- ROUND 6 PREDICTION P1, probed UNREFITTED at the
# canonical, before any Torch array. The T-D0 pattern: if the mechanism does not
# size to the observed order with nothing tuned, the round stops HERE.
#
# WHAT P1 SAYS (notes/prereg_2026-09-09g_round6_seasonal_ml.md):
#   the seasonal mixed-layer DIC anomaly the mechanism PRODUCES lands in
#   [10, 17] umol/kg (SH) and [8, 14] (NH) -- against the fitted compensator's
#   21.2 (round-3 winner) / 19.0 (ent26) and its derived prior centre 10.95.
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

## ---- P1: the amplitude of the anomaly the mechanism ADDS ------------------
say("")
say("P1 -- the ADDED seasonal ML DIC anomaly (on minus off), umol/kg")
say("  %-3s %10s %10s %10s   %-14s %s", "hem", "amp", "band lo", "band hi", "verdict", "peak month")
res <- lapply(HEMIS, function(h) {
  d   <- (on[[h]] - off[[h]]) * 1e6              # mol/kg -> umol/kg
  amp <- (max(d) - min(d)) / 2                   # HALF peak-to-trough, as the
                                                 # compensator's amplitude was
  bd  <- P1_BAND[[h]]
  ok  <- amp >= bd[1] && amp <= bd[2]
  say("  %-3s %10.2f %10.1f %10.1f   %-14s %d",
      h, amp, bd[1], bd[2], if (ok) "PASS" else "*** FAIL ***", which.max(d))
  list(hemi = h, amp = amp, band = bd, pass = ok, month_max = which.max(d), series = d)
})
names(res) <- HEMIS

say("")
say("for scale, the FITTED compensator this replaces: r3 winner %.1f, ent26 %.1f, prior centre %.2f",
    COMPENSATOR[["winner_r3"]], COMPENSATOR[["ent26"]], COMPENSATOR[["prior_centre"]])
say("⭐ P1 asks the mechanism to be SMALLER than the compensator and to reach the observed order.")
allpass <- all(vapply(res, `[[`, logical(1), "pass"))
say("")
say("P1 VERDICT: %s", if (allpass) "PASS in both hemispheres" else
                      "*** FAIL -- the round STOPS here, before the refit ***")

dir.create(dirname(OUT_RDS), showWarnings = FALSE, recursive = TRUE)
saveRDS(list(mode_file = ccx_mode_file(), h_ml = p0$h_ml, window = PROBE_YRS,
             band = P1_BAND, compensator = COMPENSATOR, result = res,
             dic_on = on, dic_off = off, built = Sys.time()), OUT_RDS)
say("wrote %s", OUT_RDS)
close(con)
