# =====================================================================
# diag_periodic_spinup.R -- DOES A PERIODIC SPINUP REMOVE THE +2.45 ppm
# RECTIFIED OFFSET, OR MERELY RELOCATE IT?
#
# Ruled by Marcus 2026-09-09w. This is the measurement `R/periodic_spinup.R`
# was built for, and the question is open in BOTH directions: the spinup PINS
# atmospheric CO2, so a limit-cycle solve may absorb the offset into the OCEAN
# state instead of leaving it in the air ⇒ [[ccx_f2_periodic_spinup_owed]].
#
# ⛔ NO VERDICT IS RETURNED ON AN INVENTED NUMBER. Every threshold below is
# either an IDENTITY (exact, by construction) or a co-located measurement of the
# same quantity on the arm whose flatness the repo already gates
# ([[threshold_from_obs_or_law]], [[tolerance_scaled_to_spread]]):
#   * GATE P1 -- the periodic state is a FIXED POINT of the one-year map. An
#     identity, so its tolerance is the solver's own PS_TOL, not a judgement.
#   * GATE P2 -- the QUIET run from the periodic state is FLAT. Its noise floor
#     is the SAME quantity measured on the seas_ml = 0 arm, which is
#     `diag_f2_periodic_spinup.R`'s own construction and the arm
#     test-conveyor.R already gates. A co-located instrument, not a guess.
#   * THE RELOCATION READING is an ORDERING between two measured quantities
#     (how much of the offset left the air vs how much appeared in the ocean),
#     reported with both numbers, never as a pass/fail.
# Every gate is MUTATION-TESTED ([[mutation_test_gates]]).
#
# ⚠ AND IT PRICES THE OBJECTIVE, which is the point: P12's -514 on the CO2
# LEVEL rows was attributed to this offset (09-09v, size-checked at +2.857 ppm
# uniform against F2's +2.45). Section 4 re-scores the historical transient from
# the periodic state and reports what actually moved, BY STREAM.
#
# Usage: Rscript calibration/diag_periodic_spinup.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()
# `ccx_periodic_spinup()` lives in `R/periodic_spinup.R` since its adoption
# 09-09x and is sourced by the R/ bootstrap above -- no second copy.
source(ccx_path("calibration", "lib_design_gates.R"))

# ---- named constants: every label, gate and filename derives from these
DP_TAG      <- "20260909"
DP_OUT      <- ccx_path("outputs", "diagnostics", paste0("periodic_spinup_", DP_TAG, ".rds"))
DP_LOG      <- sub("[.]rds$", ".log", DP_OUT)
DP_QUIET_YR <- c(1750, 2250)      # as diag_f2_periodic_spinup.R, for like-for-like
DP_PROBE    <- c(1750, 1770, 1800, 1900, 2000, 2249)
DP_HIST_YR  <- c(1750, 2024)      # the objective's own window
DP_F2_OFFSET <- 2.4507            # ppm, the offset F2 measured (log, 09-09)
DP_P12_PENALTY <- -514.38         # the CO2-level penalty P12 attributed to it

con <- file(DP_LOG, open = "wt")
say <- function(...) { m <- sprintf(...); cat(m, "\n"); cat(m, "\n", file = con) }

md <- readRDS(ccx_mode_file())
p1 <- ccx_overlay_par(ccx_mode_base(md), ccx_mode_params(md))
p1$ent_seas_amp_SH <- 0            # as F2: the shim cannot confound the reading
p1$seas_ml <- 1
p0 <- p1; p0$seas_ml <- 0          # the co-located control

say("PERIODIC SPINUP -- does the limit cycle REMOVE the offset, or RELOCATE it?")
say("mode %s | h_ml %.3f | ent_seas_amp_SH forced 0 on every arm", CCX_MODE_CANONICAL, p1$h_ml)

# ---- 1. solve -------------------------------------------------------
say("\n== 1. the solve ==")
sp_ase <- ccx_spinup(p1)
t0 <- Sys.time()
sp_per <- ccx_periodic_spinup(p1, seed = sp_ase, verbose = TRUE)
say("  converged in %d iterations, %.2f s | max|Phi(y) - y| = %.3e",
    sp_per$periodic$iterations, as.numeric(difftime(Sys.time(), t0, units = "secs")),
    sp_per$periodic$resid_state)

# ---- GATE P1: it IS a fixed point of the one-year map (an IDENTITY) --
say("\n== GATE P1 -- is the periodic state a fixed point of Phi? (identity; tol = solver's own PS_TOL) ==")
# ⛔ CORRECTED 2026-09-09x: this compared `resid_state` -- a max over all three
# tracers with NO pin substitution -- against `PS_TOL`, which is the CARBON
# NEWTON's absolute tolerance. It PASSED here (9.663e-12) but only because this
# mode's raw atmospheric one-period change happened to be small: at
# `ccx_init_unc()` the same quantity is 1.354e-09 on a 3.9e+04 GtC inventory
# (3.5e-14 RELATIVE, a floating-point floor) and the comparison FAILS a converged
# solve ⇒ [[verify_the_quantity_not_the_word]]. The solver's own criterion is
# `resid_carbon`; the state residual is reported, and judged RELATIVE to the
# inventory it sits on.
gate_p1 <- function(sp) sp$periodic$resid_carbon < PS_TOL
say("  periodic state : max|Phi(y) - y| = %.3e  -> %s",
    sp_per$periodic$resid_state, if (gate_p1(sp_per)) "PASS" else "FAIL")
# MUTATION: the ASEASONAL state must FAIL this gate, or the gate has no power.
F1 <- ps_year_forcing(sp_ase$prod_c14)
ase_resid <- max(abs(ps_phi(sp_ase$y, p1, sp_ase$aux, sp_ase$grid, F1)$state - sp_ase$y))
say("  MUTATION aseasonal state: max|Phi(y) - y| = %.3e -> %s (want FAIL)",
    ase_resid, if (ase_resid < PS_TOL) "PASS" else "FAIL")
stopifnot(gate_p1(sp_per), ase_resid >= PS_TOL)
say("  ⇒ the gate has POWER: it separates the two states by %.1f orders of magnitude.",
    log10(ase_resid / max(sp_per$periodic$resid_state, .Machine$double.xmin)))

# ---- 2. the QUIET run, from each state -------------------------------
say("\n== 2. the QUIET run (%d-%d), the SAME construction F2 used ==", DP_QUIET_YR[1], DP_QUIET_YR[2])
quiet_forcing <- function(s) {
  F <- ccx_build_forcing("historical", DP_QUIET_YR, prod_c14 = 0, bomb_total_kmol = 0)
  F$e_foss_NH <- 0; F$e_foss_SH <- 0; F$e_luc_NH <- 0; F$e_luc_SH <- 0
  F$cum_luc_NH <- 0; F$cum_luc_SH <- 0
  F <- ccx_hold_climate(F, value = 0); F$c14_bomb <- 0; F$c14_nuclear <- 0
  F$c14_cosmo <- s$prod_c14; F$aod_NH <- 0; F$aod_SH <- 0
  F
}
co2_of <- function(o) (o$co2_NH + o$co2_SH) / 2
annual <- function(o) { yr <- floor(o$t + 1e-9)
  tapply(co2_of(o), yr, mean) }            # ANNUAL MEANS: a seasonal orbit is not flat month to month
arms <- list(
  `seas_ml 0, aseasonal` = list(p = p0, sp = ccx_spinup(p0)),
  `seas_ml 1, aseasonal` = list(p = p1, sp = sp_ase),
  `seas_ml 1, PERIODIC`  = list(p = p1, sp = sp_per))
res <- list()
for (nm in names(arms)) {
  a <- arms[[nm]]
  o <- ccx_run_fast(a$sp, quiet_forcing(a$sp))$out
  av <- annual(o); yrs <- as.numeric(names(av))
  res[[nm]] <- list(annual = av, years = yrs,
                    excursion = max(av) - min(av),
                    drift = av[[length(av)]] - av[[1]],
                    at = vapply(DP_PROBE, function(y) av[[which.min(abs(yrs - y))]], 0))
}
say("  %-22s %s", "arm", paste(sprintf("%9d", DP_PROBE), collapse = ""))
for (nm in names(res)) say("  %-22s %s", nm, paste(sprintf("%9.3f", res[[nm]]$at), collapse = ""))
say("")
for (nm in names(res)) say("  %-22s excursion %8.4f ppm | drift(end-start) %+8.4f ppm",
                           nm, res[[nm]]$excursion, res[[nm]]$drift)

# ---- GATE P2: FLAT, against the co-located seas_ml = 0 noise floor ---
say("\n== GATE P2 -- is the quiet run from the PERIODIC state flat? ==")
say("  the FLOOR is not a judgement: it is the SAME excursion measured on the")
say("  seas_ml = 0 arm, the configuration test-conveyor.R already gates.")
floor_x <- res[["seas_ml 0, aseasonal"]]$excursion
gate_p2 <- function(x) x <= floor_x
for (nm in names(res)) say("  %-22s excursion %8.4f vs floor %.4f -> %s",
                           nm, res[[nm]]$excursion, floor_x,
                           if (gate_p2(res[[nm]]$excursion)) "PASS" else "FAIL")
# MUTATION: the seas_ml = 1 ASEASONAL arm is the known-bad case and must FAIL.
stopifnot(!gate_p2(res[["seas_ml 1, aseasonal"]]$excursion),
          gate_p2(res[["seas_ml 0, aseasonal"]]$excursion))
say("  ⇒ the gate has POWER: the known-bad arm FAILS it and the control PASSES.")

# ---- 3. REMOVED or RELOCATED? an ORDERING, with both numbers ---------
say("\n== 3. removed, or relocated? ==")
say("  ⛔ Reported as an ORDERING between measured quantities. No pass/fail.")
lvl <- function(r) r$at[length(r$at)]                # the settled level, 2249
d_air <- lvl(res[["seas_ml 1, PERIODIC"]]) - lvl(res[["seas_ml 0, aseasonal"]])
d_air_ase <- lvl(res[["seas_ml 1, aseasonal"]]) - lvl(res[["seas_ml 0, aseasonal"]])
oc <- vapply(names(arms), function(nm) {
  a <- arms[[nm]]; ix <- unlist(lapply(HEMIS, function(h)
    c(a$sp$aux$idx[[h]]$ml, a$sp$aux$idx[[h]]$oc, a$sp$aux$idx[[h]]$hs, a$sp$aux$idx[[h]]$hd)))
  sum(a$sp$y[ix, "C"]) }, 0)
say("  settled ATMOSPHERIC offset vs the seas_ml = 0 control:")
say("    aseasonal seed  %+8.4f ppm   (F2 measured %+.4f)", d_air_ase, DP_F2_OFFSET)
say("    PERIODIC  seed  %+8.4f ppm", d_air)
say("  spinup OCEAN carbon (GtC):")
for (nm in names(oc)) say("    %-22s %12.3f  (%+9.3f vs the seas_ml 0 control)",
                          nm, oc[[nm]], oc[[nm]] - oc[[1]])
say("")
say("  ⇒ the air kept %+.1f %% of the aseasonal offset; the ocean moved %+.3f GtC.",
    100 * d_air / d_air_ase, oc[["seas_ml 1, PERIODIC"]] - oc[["seas_ml 0, aseasonal"]])
say("    READ IT AS: |air| shrank AND |ocean| grew  => RELOCATED, the pin absorbed it.")
say("                |air| shrank AND |ocean| flat  => REMOVED.")

# ---- 4. what it does to the OBJECTIVE, by stream ---------------------
say("\n== 4. the objective, re-scored from each spinup (%d-%d) ==", DP_HIST_YR[1], DP_HIST_YR[2])
say("  ⚠ LIKELIHOOD only -- the prior is identical across arms and cancels")
say("    ([[compare_gaps_not_absolute_logposts]]).")
v <- dg_vector(CCX_MODE_CANONICAL)
score <- function(sp, pp) {
  SF <- ccx_scaled_forcing(sp, years = DP_HIST_YR, luc_scale = v$luc_scale,
                           bomb_total = v$bomb_total)
  o <- ccx_run_fast(list(y = sp$y, params = pp, aux = sp$aux, grid = sp$grid), SF$F)$out
  ccx_loglik(o, ccx_prepare_obs(),
             list(sigma_d14c = v$sigma_d14c, rep_dC = v$rep_dC,
                  grad_off_co2 = v$grad_off_co2, grad_off_d13c = v$grad_off_d13c),
             luc = SF$eluc, deep = sp$diagnostics$d14c_bottom_box,
             ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE,
             d14c_mid = ccx_model_d14c_slabs(sp))
}
st <- lapply(names(arms), function(nm) unlist(score(arms[[nm]]$sp, arms[[nm]]$p)))
names(st) <- names(arms)
say("  %-22s %12s", "arm", "total logL")
for (nm in names(st)) say("  %-22s %12.3f", nm, sum(st[[nm]]))
lvlrows <- c("co2_level_MLO", "co2_level_SPO")
say("")
say("  ⛔ FIRST, REPRODUCE P12 -- the mechanism's cost on the ASEASONAL seed.")
say("     If this does not return %.2f, nothing below is about P12's finding.", DP_P12_PENALTY)
d10 <- st[["seas_ml 1, aseasonal"]] - st[["seas_ml 0, aseasonal"]]
for (nm in names(sort(abs(d10), decreasing = TRUE))[1:6]) say("    %-22s %+12.3f", nm, d10[[nm]])
say("    %-22s %+12.3f   vs P12's %+.2f -> %s", "CO2 LEVEL rows", sum(d10[lvlrows]),
    DP_P12_PENALTY, if (abs(sum(d10[lvlrows]) - DP_P12_PENALTY) < 0.05) "REPRODUCED" else "DOES NOT REPRODUCE")
stopifnot(abs(sum(d10[lvlrows]) - DP_P12_PENALTY) < 0.05)
say("")
say("  BY STREAM, PERIODIC minus seas_ml 1 aseasonal (the question round 6 asks):")
d <- st[["seas_ml 1, PERIODIC"]] - st[["seas_ml 1, aseasonal"]]
for (nm in names(sort(abs(d), decreasing = TRUE))[1:8])
  say("    %-22s %+12.3f", nm, d[[nm]])
say("")
say("  ⇒ the CO2 LEVEL rows move %+.2f of the %.2f P12 attributed to this offset (%.1f %%).",
    sum(d[lvlrows]), DP_P12_PENALTY, 100 * sum(d[lvlrows]) / abs(DP_P12_PENALTY))
say("")
say("  AND THE NET, PERIODIC minus seas_ml 0 -- what the mechanism is actually worth:")
dp0 <- st[["seas_ml 1, PERIODIC"]] - st[["seas_ml 0, aseasonal"]]
for (nm in names(sort(abs(dp0), decreasing = TRUE))[1:6]) say("    %-22s %+12.3f", nm, dp0[[nm]])
say("    %-22s %+12.3f  (aseasonal seed gave %+.3f)", "TOTAL", sum(dp0), sum(d10))
say("  ⚠ UNREFITTED, and with `ent_seas_amp_SH` FORCED TO 0 on every arm. This is NOT")
say("    a refit result and must not be quoted as one.")

saveRDS(list(quiet = res, ocean_C = oc, streams = st, delta = d,
             periodic = sp_per$periodic, floor = floor_x,
             d_air_periodic = d_air, d_air_aseasonal = d_air_ase,
             mode = CCX_MODE_CANONICAL, built = format(Sys.time())), DP_OUT)
say("\nsaved %s\n  ⛔ Adopts nothing: no prior moved, no constant changed, no artifact repaired.", DP_OUT)
close(con)
