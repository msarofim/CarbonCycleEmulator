# =====================================================================
# diag_luc_prorata.R -- WHERE the land-use debit should come from: wood alone
# (the incumbent) or pro rata across the four land pools.
#
# THE DECISION THIS SERVES is handoff 13h sec.2.1b, and it is Marcus'. It is
# BLOCKING on the refit, because it changes the model materially and a refit
# run before it lands would be voided by it.
#
# THE TRADE, stated so the numbers below can be read against it.
#   * The converted-land term (404d66d) lowers EVERY land pool's equilibrium pro
#     rata, because it scales npp0 by (1 - c). The debit, though, comes entirely
#     out of wood -- a 37-yr pool -- while ~70 % of the equilibrium reduction
#     sits in a 500-yr soil pool. So wood is left below its new equilibrium and
#     the soils above theirs, and the redistribution that follows re-releases
#     part of the debit. Measured consequence: a land-use pulse's airborne
#     fraction at 100 yr is about HALF a fossil pulse's, not equal to it.
#   * Debiting pro rata closes that -- and it costs the 2026-08-12 call that the
#     emitted carbon carries WOOD's lagged 14C. Pro rata the emission carries a
#     stock-weighted mixture, and the slow soil pool dominates the stock, so the
#     emitted carbon is markedly OLDER. That is a real isotopic claim, not a
#     bookkeeping detail, and [3] below prices it.
#
# WHAT IS MEASURED, in the order the decision needs it:
#   [1] the pool shares themselves, and the timescale each debit lands on
#   [2] the pulse-pair airborne fraction at 50 / 100 / 150 / 200 yr, for a
#       fossil pulse and for a land-use pulse under both debits. Same
#       construction as test-luc-permanence.R: flat background, frozen GMST and
#       ENSO, so the control is flat and nothing is measured against drift.
#   [3] the 14C and 13C consequence -- the signature of the emitted carbon, and
#       what the historical run's atmosphere does about it.
#   [4] the historical carbon budget against GCB 2025, which is the check
#       nobody aimed at when the converted-land term went in.
#
# RUNTIME ~3 min.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- PINNED TO THE LOG FERTILIZATION FORM (2026-08-14) --------------
# This diagnostic was written against NPP = NPP0(1 + beta ln(chi/chi0)) and
# every number in its header is a LOG-FORM number. On 2026-08-14 the default
# flipped to CCX_FERT_MM, under which `beta` is INERT -- so without this pin the
# file would still run, still print a beta column, and silently report the same
# MM answer for every beta. (That is not hypothetical: it happened to
# diag_fert_pulse_gates.R and to the app's fertilization switch on the day of
# the flip, and identical rows are what caught both.)
#
# The pin makes this file reproduce its recorded numbers exactly. It does NOT
# make them current: the shipped model is now the saturating form, and anything
# here that fed a live decision must be re-run under it.
local({
  .orig <- ccx_default_params
  assign("ccx_default_params", function() {
    p <- .orig(); p$fert_form <- CCX_FERT_LOG; p
  }, envir = globalenv())
})

# ---- labels derive from constants (project rule) --------------------
LP_YRS     <- c(1750, 2024)
LP_PULSE   <- 100           # GtC, same size as test-luc-permanence.R
LP_YEAR    <- 1760          # leaves 264 yr of response inside the record
LP_PPM     <- 0.4707        # ppm per GtC, whole atmosphere
LP_LAGS    <- c(50, 100, 150, 200)
LP_BOMB    <- 102
LP_WOOD    <- c(`wood only (shipped)` = 1, `pro rata` = 0)
LP_BUDGET_YR <- 2024
# GCB 2025 cumulative 1750-2024, GtC. Quoted from data/obs_gcb.rds's own
# cumulative sums where available; the two land/ocean figures below are the
# numbers 404d66d's message reports, kept here so [4] is a like-for-like check.
LP_GCB_LAND  <- -57.4
LP_GCB_OCEAN <- 209.8

obs <- ccx_prepare_obs()

# ---------------------------------------------------------------------
cat("[1] THE POOL SHARES, AND WHAT EACH DEBIT LANDS ON\n")
p0 <- ccx_default_params()
sh <- ccx_luc_pool_shares(p0)
taus <- c(p0$tau_leaf, p0$tau_wood, p0$tau_soil_fast, p0$tau_soil_slow)
for (k in seq_along(CCX_LAND_POOLS))
  cat(sprintf("    %-10s  equilibrium share %5.1f %%   tau %6.1f yr\n",
              CCX_LAND_POOLS[k], 100 * sh[k], taus[k]))
cat(sprintf("    stock-weighted mean turnover of a pro-rata debit: %.1f yr\n",
            sum(sh * taus)))
cat(sprintf("    the wood-only debit lands on a single %.1f yr pool\n", p0$tau_wood))

# ---------------------------------------------------------------------
# [2] the pulse pair. Construction copied from test-luc-permanence.R so the
# gate and the diagnostic cannot disagree about what they are measuring.
lp_background <- function(s) {
  ze <- data.frame(year = seq(LP_YRS[1], LP_YRS[2]),
                   fossil_GtC = 0, luc_GtC = 0, d13c_foss = -24)
  F <- ccx_build_forcing("historical", LP_YRS, prod_c14 = s$prod_c14, emissions = ze)
  F$c14_bomb <- 0; F$c14_nuclear <- 0
  F <- ccx_hold_climate(F)   # incl. observed-SST columns (2026-08-18)
  F
}
lp_pulse <- function(F, luc) {
  ir <- which(F$year == LP_YEAR)
  shn <- if (luc) FORC_LUC_NH_SHARE else FORC_FOSS_NH_SHARE
  a <- if (luc) "e_luc_NH" else "e_foss_NH"
  b <- if (luc) "e_luc_SH" else "e_foss_SH"
  F[[a]][ir] <- F[[a]][ir] + LP_PULSE * shn
  F[[b]][ir] <- F[[b]][ir] + LP_PULSE * (1 - shn)
  if (luc) {
    add <- rep(0, nrow(F))
    add[ir] <- LP_PULSE * seq_len(12) / 12
    add[seq(max(ir) + 1, nrow(F))] <- LP_PULSE
    F$cum_luc_NH <- F$cum_luc_NH + add * shn
    F$cum_luc_SH <- F$cum_luc_SH + add * (1 - shn)
  }
  F
}
lp_co2 <- function(s, F) {
  o <- ccx_run_fast(s, F)$out
  stats::aggregate(co2 ~ year,
    data.frame(year = floor(o$t), co2 = (o$co2_NH + o$co2_SH) / 2), mean)
}
lp_af <- function(a, ctl, lag)
  (a$co2[a$year == LP_YEAR + lag] - ctl$co2[ctl$year == LP_YEAR + lag]) /
    LP_PPM / LP_PULSE

cat(sprintf("\n[2] AIRBORNE FRACTION OF A %g GtC PULSE AT %d, flat background, frozen GMST\n",
            LP_PULSE, LP_YEAR))
p <- ccx_default_params()
s <- ccx_spinup(p); F0 <- lp_background(s); ctl <- lp_co2(s, F0)
cat(sprintf("    control drift over %d yr: %+.4f ppm (must be ~0)\n",
            diff(range(LP_YRS)), ctl$co2[nrow(ctl)] - ctl$co2[1]))
af_foss <- lp_co2(s, lp_pulse(F0, luc = FALSE))
cat("                                ")
cat(paste(sprintf("%8s", paste0(LP_LAGS, " yr")), collapse = ""), "\n")
cat(sprintf("    %-27s", "FOSSIL (reference)"))
cat(paste(sprintf("%8.3f", vapply(LP_LAGS, function(L) lp_af(af_foss, ctl, L), 0)),
          collapse = ""), "\n")
af_ref <- vapply(LP_LAGS, function(L) lp_af(af_foss, ctl, L), 0)
luc_af <- list()
for (nm in names(LP_WOOD)) {
  pw <- ccx_default_params(); pw$f_luc_wood <- LP_WOOD[[nm]]
  sw <- ccx_spinup(pw); Fw <- lp_background(sw); cw <- lp_co2(sw, Fw)
  a  <- lp_co2(sw, lp_pulse(Fw, luc = TRUE))
  luc_af[[nm]] <- vapply(LP_LAGS, function(L) lp_af(a, cw, L), 0)
  cat(sprintf("    %-27s", paste0("LUC, ", nm)))
  cat(paste(sprintf("%8.3f", luc_af[[nm]]), collapse = ""), "\n")
}
cat("    ratio LUC / FOSSIL:\n")
for (nm in names(LP_WOOD)) {
  cat(sprintf("    %-27s", nm))
  cat(paste(sprintf("%8.3f", luc_af[[nm]] / af_ref), collapse = ""), "\n")
}
cat("    (1.00 = a land-use tonne is as permanent as a fossil tonne. THE POINT.)\n")

# ---------------------------------------------------------------------
# [3] the isotopic price. Two separate things, and they must not be conflated:
# the SIGNATURE of the carbon leaving the land, and what the atmosphere does.
cat("\n[3] THE 14C AND 13C PRICE OF DEBITING PRO RATA\n")
# C14 is carried as "GtC at the standard ratio" (R/model.R's state note), so a
# box's D14C is (C14/C - 1) * 1000 with no fractionation correction needed --
# 14C transport in this model carries none, deliberately (CLAUDE.md hard rule 5).
d14_box <- function(state, nm) 1000 * (state[nm, "C14"] / state[nm, "C"] - 1)
d13_box <- function(state, nm)
  1000 * (state[nm, "C13"] / state[nm, "C"] / ccx_const("R13_VPDB") - 1)

cat("    3a. the SIGNATURE of the carbon a debit removes, at the end of the run\n")
sh_full <- c(sh[1], sh[2], sh[3], sh[4])
for (yy in c(1900, 2024)) {
  pw <- ccx_default_params()
  sw <- ccx_spinup(pw)
  Fh <- ccx_build_forcing("historical", c(LP_YRS[1], yy), prod_c14 = sw$prod_c14,
                          bomb_total_kmol = LP_BOMB)
  st <- ccx_run_fast(sw, Fh)$state
  bx <- paste0("NH_", CCX_LAND_POOLS)
  d14 <- vapply(bx, function(b) d14_box(st, b), 0)
  d13 <- vapply(bx, function(b) d13_box(st, b), 0)
  cat(sprintf("      %d  pools D14C: %s\n", yy,
              paste(sprintf("%s %+.1f", CCX_LAND_POOLS, d14), collapse = "  ")))
  cat(sprintf("            wood-only debit D14C %+8.2f | pro-rata debit D14C %+8.2f  (diff %+.2f permil)\n",
              d14[2], sum(sh_full * d14), sum(sh_full * d14) - d14[2]))
  cat(sprintf("            wood-only debit d13C %+8.3f | pro-rata debit d13C %+8.3f  (diff %+.3f permil)\n",
              d13[2], sum(sh_full * d13), sum(sh_full * d13) - d13[2]))
}
cat("      NB these are the NH boxes; the debit is stock-weighted, so the\n")
cat("      pro-rata number is dominated by whichever pool holds the carbon.\n")

cat("\n    3b. what the ATMOSPHERE does about it, over the full historical run\n")
for (nm in names(LP_WOOD)) {
  pw <- ccx_default_params(); pw$f_luc_wood <- LP_WOOD[[nm]]
  sw <- ccx_spinup(pw)
  Fh <- ccx_build_forcing("historical", LP_YRS, prod_c14 = sw$prod_c14,
                          bomb_total_kmol = LP_BOMB)
  r  <- ccx_run_fast(sw, Fh)
  o  <- r$out
  ms <- ccx_model_stats(o, obs)
  win <- function(ob, m) {
    kk <- match(ob$year, m$year)
    g  <- !is.na(kk) & ob$year >= 2015 & ob$year <= 2024
    mean(ob$level[g] - m$level[kk[g]])
  }
  k <- o$t >= 2015 & o$t <= 2024
  cat(sprintf("      %-20s model 2015-2024: CO2 %7.2f ppm  d13C %+7.3f  D14C %+8.2f\n",
              nm, mean((o$co2_NH[k] + o$co2_SH[k]) / 2),
              mean((o$d13c_NH[k] + o$d13c_SH[k]) / 2),
              mean((o$d14c_NH[k] + o$d14c_SH[k]) / 2)))
  cat(sprintf("      %-20s biases (obs-model): CO2 MLO %+7.2f ppm  d13C MLO %+6.3f permil\n",
              "", win(obs$co2_ann$MLO, ms$co2$MLO), win(obs$d13_ann$MLO, ms$d13$MLO)))
  # [4] the historical budget, in the same loop -- one run, two answers
  cum_land  <- o$land_C[nrow(o)]  - o$land_C[1]
  cum_ocean <- o$ocean_C[nrow(o)] - o$ocean_C[1]
  cat(sprintf("      %-20s cumulative %d-%d: land %+8.1f (GCB %+.1f)  ocean %+8.1f (GCB %+.1f) GtC\n",
              "", LP_YRS[1], LP_BUDGET_YR, cum_land, LP_GCB_LAND, cum_ocean, LP_GCB_OCEAN))
}
cat("\n[4] is folded into 3b's last line: the GCB cumulative check, which is the\n")
cat("    independent test the converted-land term passed and which a change of\n")
cat("    debit must not break.\n")

# ---------------------------------------------------------------------
# [5] FOUND WHILE MEASURING [3b], AND IT IS THE REASON THIS SECTION EXISTS.
# 404d66d reports cumulative land 1750-2024 = -53.6 GtC against GCB's -57.4 --
# a close agreement, and it was measured at beta = 0.38. At the re-centered beta
# = 0.60 the same quantity is +21.7. So the CO2 LEVEL and the GCB LAND BUDGET
# want different betas, and the gap between them is ~75 GtC. Neither the beta
# re-centering nor the debit decision can be made without seeing that plane, so
# it is scanned here rather than argued about.
LP_BETA_GRID <- c(0.30, 0.38, 0.45, 0.50, 0.60, 0.70, 0.80)
cat(sprintf("\n[5] THE (beta, debit) PLANE: CO2 level vs the GCB land budget\n"))
cat(sprintf("    GCB 2025 cumulative %d-%d: land %+.1f  ocean %+.1f GtC\n",
            LP_YRS[1], LP_BUDGET_YR, LP_GCB_LAND, LP_GCB_OCEAN))
gcbo <- as.data.frame(obs$gcb)
gk   <- gcbo$year >= 2015 & gcbo$year <= 2024
cat(sprintf("    GCB 2015-2024 mean sinks: land %.2f  ocean %.2f GtC/yr\n",
            mean(gcbo$land_sink[gk]), mean(gcbo$ocean_sink[gk])))
cat("\n    'gross land' = mean(diff(land_C)) + E_LUC. GCB's land_sink is the RESIDUAL\n")
cat("    sink alone while diff(land_C) is the NET land flux (sink minus E_LUC);\n")
cat("    comparing those two directly is a unit trap this repo has hit before.\n")
cat("\n    debit        beta   CO2 bias   cum land   cum ocean  gross land  ocean sink\n")
lp_em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
LP_ELUC <- mean(lp_em$luc_GtC[lp_em$year >= 2015 & lp_em$year <= 2024])
for (nm in names(LP_WOOD)) for (b in LP_BETA_GRID) {
  pw <- ccx_default_params(); pw$f_luc_wood <- LP_WOOD[[nm]]; pw$beta <- b
  sw <- ccx_spinup(pw)
  Fh <- ccx_build_forcing("historical", LP_YRS, prod_c14 = sw$prod_c14,
                          bomb_total_kmol = LP_BOMB)
  o  <- ccx_run_fast(sw, Fh)$out
  ms <- ccx_model_stats(o, obs)
  ob <- obs$co2_ann$MLO; kk <- match(ob$year, ms$co2$MLO$year)
  gg <- !is.na(kk) & ob$year >= 2015 & ob$year <= 2024
  yr  <- floor(o$t + 1e-9)
  ann <- stats::aggregate(cbind(ocean_C, land_C) ~ yr, data = o, FUN = mean)
  ann <- ann[order(ann$yr), ]
  kw  <- ann$yr[-1] >= 2015
  cat(sprintf("    %-12s %.2f  %+8.2f  %+9.1f  %+10.1f  %9.2f  %10.2f\n", nm, b,
              mean(ob$level[gg] - ms$co2$MLO$level[kk[gg]]),
              o$land_C[nrow(o)] - o$land_C[1], o$ocean_C[nrow(o)] - o$ocean_C[1],
              mean(diff(ann$land_C)[kw]) + LP_ELUC, mean(diff(ann$ocean_C)[kw])))
}
cat("\n    READ IT AS: which beta zeroes the CO2 bias, and what that beta does to\n")
cat("    the two budget quantities GCB reports independently of the CO2 record.\n")
