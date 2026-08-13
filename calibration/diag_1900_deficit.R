# =====================================================================
# diag_1900_deficit.R -- the ~6.5 ppm the model is short of Law Dome at 1900.
#
# HEADLINE: IT IS NOT A 19th-CENTURY MISFIT AND IT IS NOT ABOUT THE 19th
# CENTURY. LAND-USE EMISSIONS HAVE AN AIRBORNE FRACTION OF 0.002 AT 100 YEARS
# IN THIS MODEL -- THE LAND TAKES BACK EVERY TONNE DEFORESTATION RELEASES --
# AND THE DEFECT WAS INTRODUCED ON 2026-08-12 BY 98c1783.
#
# WRITTEN 2026-08-13, discharging handoff_2026-08-13e sec.0.4: "A NEW,
# UNDIAGNOSED MISFIT ... it is larger than the question that surfaced it and
# nobody has looked at it."
#
# WHAT IT MEASURES (all at default parameters unless stated):
#
#   [3] 100 GtC pulse, zero-emission background, frozen GMST. Airborne
#       fraction at 100 yr: EXTERNAL SOURCE 0.262, WOOD TRANSFER 0.002.
#       At 150 yr the transfer is -0.003. Control flat to +0.027 ppm/275 yr.
#   [2] 1900 residual -6.51 ppm shipped, +1.62 with LUC made permanent. The
#       regrowth path accounts for 125 % of the deficit -- it OVERSHOOTS.
#   [5] The bias runs the whole record: -6.5 (1900) to -6.0 ppm (2024).
#   [5b] Cumulative land 1750-2024: model +29.4 GtC, GCB 2025 -57.4 GtC. The
#       model's land is a net SINK where the budget says net SOURCE.
#   [6] beta preferred by the CO2 record: 0.30 under the transfer, 0.70 under
#       a permanent LUC. The treatment biases beta DOWN by ~2.3x.
#   [7] Land-use carbon is LIGHT, so it took part of the Suess forcing with
#       it: the 1900-2020 decline is -2.209 permil shipped, -2.353 permanent.
#       Fixing this makes the d13C misfit WORSE, by ~6.5 % of the decline.
#
# THE CLUE THAT STARTS IT is inside diag_pre1850_luc.R's own residual table and
# was read past. Four pre-1850 LUC options spanning 0 -> 74.1 GtC of cumulative
# emissions land within 0.38 ppm of each other AT 1900, having been 6.09 ppm
# apart at 1850. Fifty years erased 94 % of a 74 GtC forcing difference. The
# model's own point IRF at 50 yr is 0.397 (diag_joos_irf.R), so a 74 GtC
# difference SHOULD still be worth ~13 ppm at 1900 and ~10 ppm of that should
# still be there fifty years on. Suspicious uniformity, per the standing rule,
# is a code path until disproven.
#
# THE HYPOTHESIS. LUC emissions are a TRANSFER out of the wood pool (model.R,
# 2026-08-12, and correctly so -- add_source() created 14C ex nihilo). But the
# wood pool has a restoring fixed point, so what deforestation removes, the
# model REGROWS:
#
#   d(dW)/dt = phi (1-f) npp0/veg0 * dW - dW/tau_wood
#            = 0.5*0.4/8.6 - 1/20 = 0.02326 - 0.05 = -0.0267 /yr  (37.4 yr)
#
# GCB's E_LUC is already a NET flux -- gross clearing minus regrowth on
# abandoned land. Debiting a pool that then regrows applies regrowth a SECOND
# time. A fossil emission in this model is permanent (partitioned, IRF 0.31 at
# 100 yr); an LUC emission decays to ~zero on ~37 yr. Over 1750-1900 LUC is
# 88 % of cumulative emissions, so the deficit should be almost entirely a LUC
# deficit -- and should be nearly INVARIANT to the pre-1850 LUC choice, which
# is exactly the invariance that raised the question.
#
# CONFIRMED, and sec.3 is the test that does it: the pulse pair depends on no
# historical forcing, no observation and no fit. A wood transfer and an
# external source of the same size, on the same flat background, differ by a
# factor of 130 in airborne fraction at 100 years.
#
# WHY THE STRUCTURE IS WRONG, from the budget's own layout rather than from
# recollection. GCB reports E_LUC (bookkeeping) and S_LAND (the residual land
# sink) as SEPARATE terms -- data/gcb_budget.rds carries them as separate
# columns. The model's beta-fertilisation uptake is the analogue of S_LAND. So
# letting the wood pool regrow what E_LUC removed adds a second, unbudgeted
# land sink on top of the one already parameterised. Whatever share of
# regrowth E_LUC does or does not net out, FULL recovery to the preindustrial
# stock is not defensible: converted land is farmed, not left to reforest.
#
# WHAT THIS DOES *NOT* SAY. The 2026-08-12 change was right on its own terms
# and must not be reverted -- add_source() created 14C ex nihilo, ~28 kmol by
# 1995 (diag_excess_c14.R). The transfer is conservative; what is missing is
# that the debit must be PERMANENT. See notes/handoff_2026-08-13f.
#
# AND WHAT IT DOES NOT EXPLAIN. mode_fit.rds has beta = 0.088, BELOW even the
# 0.30 the transfer path prefers here, so the LUC defect is a contributing
# bias to the low beta and not the whole of it. The other 15 parameters and
# the d13C/14C streams are not in this scan. Do not read sec.6 as attributing
# the mode.
#
# RUNTIME ~5 s.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- labels derive from constants (project rule) --------------------
DF_WINDOW  <- c(1750, 1900)     # the window the deficit is quoted over
DF_FULL    <- c(1750, 2024)     # the full historical run, for sec.5
DF_MARKS   <- c(1775, 1800, 1825, 1850, 1875, 1900)
DF_MARKS2  <- c(1900, 1930, 1960, 1990, 2010, 2024)
DF_PULSE   <- 100               # GtC, the idealised pulse
DF_PYEAR   <- 1760              # pulse year; leaves 264 yr of response
DF_PLAGS   <- c(10, 25, 50, 100, 150, 264)
DF_PPM_GTC <- 0.4707            # ppm per GtC, whole atmosphere

emis <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
spl  <- as.data.frame(readRDS(ccx_path("data", "obs_icecore.rds"))$co2_spline)
obs_at <- function(y) spl$co2_ppm[which.min(abs(spl$year - y))]

annual <- function(o) stats::aggregate(
  cbind(co2, land, ocean) ~ year,
  data.frame(year = floor(o$t), co2 = (o$co2_NH + o$co2_SH) / 2,
             land = o$land_C, ocean = o$ocean_C), mean)

run_win <- function(F, s) annual(ccx_run_fast(s, F)$out)

# =====================================================================
# 1. THE BUDGET THE OBSERVATIONS ASK FOR
# =====================================================================
cat("\n=== [1] CUMULATIVE BUDGET 1750-1900 ===\n")
i19 <- emis$year <= DF_WINDOW[2]
cum_f <- sum(emis$fossil_GtC[i19]); cum_l <- sum(emis$luc_GtC[i19])
obs_air <- (obs_at(1900) - obs_at(1750)) / DF_PPM_GTC
cat(sprintf("  emissions  fossil %6.1f  LUC %6.1f  total %6.1f GtC  (LUC share %.0f %%)\n",
            cum_f, cum_l, cum_f + cum_l, 100 * cum_l / (cum_f + cum_l)))
cat(sprintf("  Law Dome   %.2f -> %.2f ppm = %.1f GtC airborne, AF = %.3f\n",
            obs_at(1750), obs_at(1900), obs_air, obs_air / (cum_f + cum_l)))

# =====================================================================
# 2. LUC AS A TRANSFER (shipped) vs LUC AS AN EXTERNAL SOURCE
#
# The second config moves e_luc into e_foss on the assembled forcing table.
# That is MASS-EXACT and is all this section scores; the isotopes are wrong in
# it by construction (LUC carbon would carry the fossil d13C and no 14C), so
# NOTHING isotopic may be read off config B. It exists to answer one question:
# is the missing CO2 the wood pool taking its carbon back?
# =====================================================================
p <- ccx_default_params(); s <- ccx_spinup(p)

F_base <- ccx_build_forcing("historical", DF_WINDOW, prod_c14 = s$prod_c14)
F_ext  <- F_base
F_ext$e_foss_NH <- F_ext$e_foss_NH + F_ext$e_luc_NH
F_ext$e_foss_SH <- F_ext$e_foss_SH + F_ext$e_luc_SH
F_ext$e_luc_NH  <- 0; F_ext$e_luc_SH <- 0

# beta = 0 kills CO2 fertilisation; the rival hypothesis that the LAND SINK is
# simply too strong at the default beta.
p_b0 <- p; p_b0$beta <- 0; s_b0 <- ccx_spinup(p_b0)

CONFIGS <- list(
  "shipped (LUC = transfer)" = list(F = F_base, s = s),
  "LUC as external source"   = list(F = F_ext,  s = s),
  "beta = 0 (no fert.)"      = list(F = F_base, s = s_b0))

runs <- lapply(CONFIGS, function(cf) run_win(cf$F, cf$s))

cat("\n=== [2] RESIDUALS vs LAW DOME (model - obs, ppm) ===\n")
cat(sprintf("%-26s %s\n", "config", paste(sprintf("%8d", DF_MARKS), collapse = "")))
cat(sprintf("%-26s %s\n", "Law Dome ppm",
            paste(sprintf("%8.2f", vapply(DF_MARKS, obs_at, numeric(1))), collapse = "")))
for (nm in names(runs)) {
  a <- runs[[nm]]
  cat(sprintf("%-26s %s\n", nm,
      paste(sprintf("%+8.2f",
        vapply(DF_MARKS, function(y) a$co2[a$year == y] - obs_at(y), numeric(1))),
        collapse = "")))
}

cat("\n=== [2b] WHERE THE CARBON WENT, 1750-1900 (GtC) ===\n")
cat(sprintf("%-26s %8s %8s %8s %8s\n", "config", "atm", "land", "ocean", "AF"))
for (nm in names(runs)) {
  a <- runs[[nm]]; i0 <- which(a$year == DF_WINDOW[1]); i1 <- which(a$year == DF_WINDOW[2])
  d_atm <- (a$co2[i1] - a$co2[i0]) / DF_PPM_GTC
  cat(sprintf("%-26s %+8.1f %+8.1f %+8.1f %8.3f\n", nm, d_atm,
              a$land[i1] - a$land[i0], a$ocean[i1] - a$ocean[i0],
              d_atm / (cum_f + cum_l)))
}
cat(sprintf("%-26s %+8.1f %8s %8s %8.3f  <-- observations\n", "Law Dome",
            obs_air, "", "", obs_air / (cum_f + cum_l)))

# =====================================================================
# 3. THE MECHANISM TEST -- an idealised pulse pair, no historical forcing
#
# Same DF_PULSE GtC, same year, one delivered as a wood transfer and one as an
# external source, on a ZERO-emission background so the only thing moving is
# the pulse. If the hypothesis is right the two airborne fractions diverge
# with lag, the transfer decaying on ~tau_wood while the source levels off at
# the model's own IRF.
# =====================================================================
cat("\n=== [3] IDEALISED PULSE PAIR: transfer-from-wood vs external source ===\n")
cat(sprintf("  %d GtC in %d, zero-emission background, airborne fraction by lag\n",
            DF_PULSE, DF_PYEAR))

zero_emis <- data.frame(year = 1750:2024, fossil_GtC = 0, luc_GtC = 0, d13c_foss = -24)
F0 <- ccx_build_forcing("historical", DF_FULL, prod_c14 = s$prod_c14,
                        emissions = zero_emis)
F0$c14_bomb <- 0; F0$c14_nuclear <- 0        # isolate the carbon response
# GMST AND ENSO HELD AT THEIR FIRST VALUE. Left free, a zero-emission run still
# moves +8.34 ppm over 275 yr -- the prescribed-warming carbon-climate feedback,
# not integrator drift. It cancels in the pulse-minus-control difference to
# first order, but freezing it removes the nonlinear residue and makes the
# control run a genuine flat line, which is what the sec.3 gate wants to assert.
F0$gmst <- F0$gmst[1]; F0$enso <- F0$enso[1]
irow <- which(F0$year == DF_PYEAR)           # 12 months of the pulse year

# GtC/yr held for one year, split by hemisphere in the same 60/40 as the forcing
mk2 <- function(a, b, share) {
  G <- F0
  G[[a]][irow] <- G[[a]][irow] + DF_PULSE * share
  G[[b]][irow] <- G[[b]][irow] + DF_PULSE * (1 - share)
  G
}
F_ctl <- F0
F_luc <- mk2("e_luc_NH",  "e_luc_SH",  0.6)
F_fos <- mk2("e_foss_NH", "e_foss_SH", 0.6)

a_ctl <- run_win(F_ctl, s); a_luc <- run_win(F_luc, s); a_fos <- run_win(F_fos, s)

cat(sprintf("  %-10s %s\n", "lag yr", paste(sprintf("%9d", DF_PLAGS), collapse = "")))
af <- function(a) vapply(DF_PLAGS, function(L) {
  j <- which(a$year == DF_PYEAR + L); k <- which(a_ctl$year == DF_PYEAR + L)
  (a$co2[j] - a_ctl$co2[k]) / DF_PPM_GTC / DF_PULSE }, numeric(1))
cat(sprintf("  %-10s %s\n", "external", paste(sprintf("%9.3f", af(a_fos)), collapse = "")))
cat(sprintf("  %-10s %s\n", "wood xfer", paste(sprintf("%9.3f", af(a_luc)), collapse = "")))
cat(sprintf("  %-10s %s\n", "ratio", paste(sprintf("%9.2f", af(a_luc) / af(a_fos)), collapse = "")))

cat("\n  control-run flatness (zero emissions, frozen GMST/ENSO, 275 yr): ")
cat(sprintf("%+.4f ppm\n", a_ctl$co2[nrow(a_ctl)] - a_ctl$co2[1]))
cat("  READ THE 100-yr COLUMN. A fossil emission is permanent in this model; an\n")
cat("  LUC emission is a transient the land takes back in full. That is the\n")
cat("  regrowth GCB's NET E_LUC has ALREADY subtracted, applied a second time.\n")

# =====================================================================
# 4. WHAT AN EXTERNAL-SOURCE LUC WOULD COST ELSEWHERE
#
# The transfer is not going back: it was adopted because add_source() created
# 14C from nothing. So the fix, if the hypothesis holds, is NOT to revert but
# to stop the model regrowing what deforestation removed. This section sizes
# the two ends of that: the shipped model, and the same run with the wood
# pool's restoring term disabled by making the debit permanent -- approximated
# here by giving LUC its own sink that the land cannot refill (external
# source), which sec.2 already ran. Reported here as the residual to close.
# =====================================================================
cat("\n=== [4] THE GAP TO CLOSE ===\n")
r_ship <- runs[["shipped (LUC = transfer)"]]
r_ext  <- runs[["LUC as external source"]]
g <- function(a, y) a$co2[a$year == y] - obs_at(y)
cat(sprintf("  1900 residual, shipped            %+.2f ppm\n", g(r_ship, 1900)))
cat(sprintf("  1900 residual, external-source    %+.2f ppm\n", g(r_ext, 1900)))
cat(sprintf("  explained by the regrowth path    %+.2f ppm of %.2f  (%.0f %%)\n",
            g(r_ext, 1900) - g(r_ship, 1900), -g(r_ship, 1900),
            100 * (g(r_ext, 1900) - g(r_ship, 1900)) / -g(r_ship, 1900)))
cat("  The regrowth path accounts for MORE than the whole deficit: handled\n")
cat("  permanently, the model OVERSHOOTS 1900. So this is not a missing source.\n")

# =====================================================================
# 5. WHAT IT DOES TO THE MODERN RUN -- and therefore to the CALIBRATION
#
# THIS IS THE SECTION THAT MATTERS. The ice core and the Mauna Loa record are
# both IN the likelihood. If the shipped model fits modern CO2 while losing
# 88 % of pre-1900 emissions down the regrowth path, then the fit is being
# bought somewhere else -- by a weaker beta, a weaker ocean, or both -- and
# every posterior parameter carries that compensation.
# =====================================================================
cat("\n=== [5] THE FULL HISTORICAL RUN, 1750-2024 ===\n")
Fb <- ccx_build_forcing("historical", DF_FULL, prod_c14 = s$prod_c14)
Fe <- Fb
Fe$e_foss_NH <- Fe$e_foss_NH + Fe$e_luc_NH; Fe$e_foss_SH <- Fe$e_foss_SH + Fe$e_luc_SH
Fe$e_luc_NH  <- 0; Fe$e_luc_SH <- 0
full <- list("shipped (LUC = transfer)" = run_win(Fb, s),
             "LUC as external source"   = run_win(Fe, s))

# Observations: Law Dome spline before the instrumental record, the global
# monthly mean after. Overlap resolved in favour of the instrument.
co2m <- as.data.frame(readRDS(ccx_path("data", "obs_co2_monthly.rds")))
inst <- stats::aggregate(co2_ppm ~ year, co2m[co2m$station == "MLO", ], mean)
obs2 <- function(y) if (y >= min(inst$year)) inst$co2_ppm[inst$year == y] else obs_at(y)

cat(sprintf("%-26s %s\n", "config", paste(sprintf("%8d", DF_MARKS2), collapse = "")))
cat(sprintf("%-26s %s   (Law Dome < %d, MLO after)\n", "observed ppm",
            paste(sprintf("%8.1f", vapply(DF_MARKS2, obs2, numeric(1))), collapse = ""),
            min(inst$year)))
for (nm in names(full)) {
  a <- full[[nm]]
  cat(sprintf("%-26s %s\n", nm,
      paste(sprintf("%+8.2f",
        vapply(DF_MARKS2, function(y) a$co2[a$year == y] - obs2(y), numeric(1))),
        collapse = "")))
}

cat("\n=== [5b] CUMULATIVE PARTITION 1750-2024 (GtC) ===\n")
cum_f2 <- sum(emis$fossil_GtC); cum_l2 <- sum(emis$luc_GtC)
cat(sprintf("  emissions  fossil %6.1f  LUC %6.1f  total %6.1f GtC\n",
            cum_f2, cum_l2, cum_f2 + cum_l2))
cat(sprintf("%-26s %8s %8s %8s %8s\n", "config", "atm", "land", "ocean", "AF"))
for (nm in names(full)) {
  a <- full[[nm]]; i0 <- 1; i1 <- nrow(a)
  d_atm <- (a$co2[i1] - a$co2[i0]) / DF_PPM_GTC
  cat(sprintf("%-26s %+8.1f %+8.1f %+8.1f %8.3f\n", nm, d_atm,
              a$land[i1] - a$land[i0], a$ocean[i1] - a$ocean[i0],
              d_atm / (cum_f2 + cum_l2)))
}
h <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$historical)
ig <- h$year %in% seq(DF_FULL[1], DF_FULL[2])
cat(sprintf("%-26s %+8.1f %+8.1f %+8.1f %8s  <-- GCB 2025 budget\n", "observed",
            sum(h$atm_growth[ig], na.rm = TRUE),
            sum(h$land_sink[ig], na.rm = TRUE) - sum(h$luc[ig], na.rm = TRUE),
            sum(h$ocean_sink[ig], na.rm = TRUE), ""))
cat("  (GCB's own LUC is 247.5 GtC -- it carries no pre-1850 column, so the\n")
cat("   model burns 41.8 GtC more than GCB inventories. Even crediting ALL of\n")
cat("   that to the land, the shipped land is a NET SINK where the budget says\n")
cat("   NET SOURCE.)\n")

# =====================================================================
# 6. IS THE CALIBRATION ALREADY COMPENSATING?
#
# The mode has beta = 0.0877 against a default of 0.38 and an h_ml of 178 m,
# 88 % up its bound (handoff 13c sec.5). The hypothesis this section TESTS
# rather than asserts: with the land quietly taking LUC carbon back, the
# sampler must weaken the OTHER land sink to avoid overshooting CO2, so beta
# is absorbing a structural defect.
#
# The test: scan beta under each LUC treatment, all else at defaults, and ask
# which beta best reproduces the CO2 record. If the transfer path prefers a
# beta near the mode's 0.088 and the permanent path prefers one near the
# literature range, the compensation is real and measured.
# =====================================================================
cat("\n=== [6] WHAT beta EACH LUC TREATMENT DEMANDS ===\n")
DF_BETAS <- c(0, 0.05, 0.1, 0.2, 0.3, 0.38, 0.5, 0.7, 1.0)
DF_SCORE <- seq(1850, DF_FULL[2])       # window with continuous observations

score_beta <- function(F, b) {
  pb <- p; pb$beta <- b
  a  <- run_win(F, ccx_spinup(pb))
  d  <- vapply(DF_SCORE, function(y) a$co2[a$year == y] - obs2(y), numeric(1))
  c(rmse = sqrt(mean(d^2)), r2024 = d[length(d)])
}
cat(sprintf("  %-6s | %18s | %18s\n", "beta", "LUC = transfer", "LUC = permanent"))
cat(sprintf("  %-6s | %8s %9s | %8s %9s\n", "", "RMSE", "res 2024", "RMSE", "res 2024"))
tab <- t(vapply(DF_BETAS, function(b) c(score_beta(Fb, b), score_beta(Fe, b)), numeric(4)))
for (i in seq_along(DF_BETAS))
  cat(sprintf("  %-6.2f | %8.2f %+9.2f | %8.2f %+9.2f%s\n", DF_BETAS[i],
              tab[i, 1], tab[i, 2], tab[i, 3], tab[i, 4],
              if (DF_BETAS[i] == p$beta) "   <-- default" else ""))
cat(sprintf("\n  best beta, LUC = transfer   %.2f   (mode_fit.rds has %.3f)\n",
            DF_BETAS[which.min(tab[, 1])], readRDS(
              ccx_path("calibration", "output", "mode_fit.rds"))$par_mode$beta))
cat(sprintf("  best beta, LUC = permanent  %.2f\n", DF_BETAS[which.min(tab[, 3])]))
cat("  A 1-D scan at fixed everything-else is NOT a refit and the minimum is\n")
cat("  coarse. What it establishes is the DIRECTION and that it is large.\n")

# =====================================================================
# 7. WHAT IT DID TO THE d13C WORK -- and the sign is the bad one
#
# 98c1783 landed 2026-08-12. EVERY d13C result in this repo dated 2026-08-13 --
# the oceanic Suess measurement, the "atmosphere 21-25 % too fast" headline,
# the conveyor's evaluation, the sigma_d13c argument -- was measured AFTER it,
# on a model that gives land-use carbon back to the land. Land-use carbon is
# ISOTOPICALLY LIGHT, so the model has been running with a large part of its
# Suess forcing quietly switched off.
#
# READ THE CAVEAT. Config B gives LUC the FOSSIL d13C (-24 rising to -28.3)
# rather than the biosphere's (~-25), and no 14C at all. The 14C is
# meaningless here and is not reported. The d13C is usable for SIGN and rough
# magnitude ONLY because the two source values sit within ~3 permil of each
# other -- it is NOT a substitute for measuring this properly once the fix is
# chosen, because the regrowth limb this removes carries photosynthetic
# fractionation that no external source does.
# =====================================================================
cat("\n=== [7] ATMOSPHERIC d13C (permil) -- sign check, see the caveat ===\n")
d13 <- function(F, s) {
  o <- ccx_run_fast(s, F)$out
  stats::aggregate(d13c ~ year, data.frame(year = floor(o$t),
                   d13c = (o$d13c_NH + o$d13c_SH) / 2), mean)
}
DF_D13 <- c(1900, 1950, 1980, 2000, 2020)
db <- d13(Fb, s); de <- d13(Fe, s)
at13 <- function(a, y) a$d13c[a$year == y]
cat(sprintf("  %-26s %s\n", "config", paste(sprintf("%9d", DF_D13), collapse = "")))
for (nm in c("shipped (LUC = transfer)", "LUC as external source")) {
  a <- if (nm == "shipped (LUC = transfer)") db else de
  cat(sprintf("  %-26s %s\n", nm,
      paste(sprintf("%9.3f", vapply(DF_D13, function(y) at13(a, y), numeric(1))),
            collapse = "")))
}
cat(sprintf("  %-26s %s\n", "difference (perm - xfer)",
    paste(sprintf("%+9.3f", vapply(DF_D13, function(y) at13(de, y) - at13(db, y),
                                   numeric(1))), collapse = "")))
cat(sprintf("\n  Suess decline 1900->2020:  transfer %+.3f, permanent %+.3f permil\n",
            at13(db, 2020) - at13(db, 1900), at13(de, 2020) - at13(de, 1900)))
cat("  THE SIGN IS THE UNWELCOME ONE. Making LUC permanent leaves MORE light\n")
cat("  carbon in the atmosphere, so the Suess decline gets FASTER -- and the\n")
cat("  model's decline is ALREADY ~25 % too fast (handoff 13c sec.3). Fixing\n")
cat("  the carbon defect WORSENS the d13C misfit the project has been chasing.\n")
cat("  The ocean conclusions of 2026-08-13 must be re-measured after the fix.\n")
