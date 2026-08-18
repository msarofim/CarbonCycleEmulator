# =====================================================================
# diag_1900_deficit.R -- the ~6.5 ppm the model was short of Law Dome at 1900,
# what caused it, and what fixing it costs.
#
# HEADLINE: IT WAS NOT A 19th-CENTURY MISFIT. LAND-USE EMISSIONS HAD AN AIRBORNE
# FRACTION OF 0.002 AT 100 YEARS -- THE LAND TOOK BACK EVERY TONNE
# DEFORESTATION RELEASED -- A REGRESSION INTRODUCED ON 2026-08-12 BY 98c1783
# AND FIXED ON 2026-08-13 BY THE CONVERTED-LAND TERM.
#
# WRITTEN 2026-08-13, discharging handoff_2026-08-13e sec.0.4: "A NEW,
# UNDIAGNOSED MISFIT ... it is larger than the question that surfaced it and
# nobody has looked at it."
#
# THE THREE ARMS. All at default parameters, all with LUC as a wood transfer,
# so all three are isotopically honest and sec.7 can be read as well as sec.2:
#
#   f_luc_perm = 0    the bug: cumulative clearing costs the land nothing
#   f_luc_perm = 1    SHIPPED: the land's equilibrium falls by exactly the
#                     carbon land-use change removed
#   external source   the BOUND: LUC routed into e_foss, i.e. permanent AND
#                     costing the land no capacity. Mass-exact, isotopically
#                     meaningless -- read sec.2 off it, never sec.7.
#
# WHAT IT MEASURES:
#
#   [3] 100 GtC pulse, zero-emission background, frozen GMST. Airborne fraction
#       at 100 yr: fossil 0.262; LUC 0.002 pre-fix, 0.130 shipped.
#   [2] 1900 residual -6.51 pre-fix, -2.08 shipped.
#   [5] The bias ran the whole record: -6.5 (1900) to -6.0 ppm (2024) pre-fix.
#   [4] The fix is exactly permanent in the limit (ratio 1.01 at
#       tau_soil_slow = 20) and ~50 % on a century, because the debit lands on
#       wood and 70 % of the equilibrium reduction sits in a 500-yr soil pool.
#   [5b] Cumulative land 1750-2024: +29.4 GtC pre-fix against GCB 2025's -57.4
#       -- a net SINK where the budget says net SOURCE. Shipped: -53.6.
#       Ocean +169.1 -> +202.2 against GCB's +209.8. NEITHER WAS TARGETED.
#   [6] beta preferred by the CO2 record: 0.30 pre-fix, 0.50 shipped.
#   [7] Land-use carbon is LIGHT, so the bug took part of the Suess forcing
#       with it. The 1900-2020 decline goes -2.209 -> -2.366 permil, 7.1 %
#       FASTER, and the model's was already ~25 % too fast. Fixing the carbon
#       defect makes the d13C misfit WORSE, not better.
#
# THE CLUE WAS INSIDE diag_pre1850_luc.R's OWN TABLE AND WAS READ AS
# REASSURING. Four pre-1850 LUC options spanning 0 -> 74.1 GtC of cumulative
# emissions landed within 0.38 ppm of each other AT 1900, having been 6.09 ppm
# apart at 1850. Fifty years erased 94 % of a 74 GtC forcing difference,
# against the model's own 50-yr point IRF of 0.397. Suspicious uniformity, per
# the standing rule, is a code path until disproven.
#
# THE MECHANISM. LUC is a transfer out of the wood pool (98c1783, and right on
# its own terms -- add_source() created 14C ex nihilo). But wood had a
# restoring fixed point, so what deforestation removed, the model regrew:
#
#   d(dW)/dt = phi (1-f) npp0/veg0 * dW - dW/tau_wood
#            = 0.5*0.4/8.6 - 1/20 = -0.0267 /yr   ->   37.4 yr
#
# WHY THE STRUCTURE WAS WRONG, from the budget's own layout rather than from
# recollection: GCB reports E_LUC (bookkeeping) and S_LAND (the residual land
# sink) as SEPARATE terms, and data/gcb_budget.rds carries them as separate
# columns. The model's beta-fertilisation uptake is the analogue of S_LAND, so
# regrowing what E_LUC removed added a second, unbudgeted land sink on top of
# the one already parameterised.
#
# RUNTIME ~10 s.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- PINNED TO THE LOG FERTILISATION FORM (2026-08-14) --------------
# This diagnostic was written against NPP = NPP0(1 + beta ln(chi/chi0)) and
# every number in its header is a LOG-FORM number. On 2026-08-14 the default
# flipped to CCX_FERT_MM, under which `beta` is INERT -- so without this pin the
# file would still run, still print a beta column, and silently report the same
# MM answer for every beta. (That is not hypothetical: it happened to
# diag_fert_pulse_gates.R and to the app's fertilisation switch on the day of
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
DF_WINDOW  <- c(1750, 1900)     # the window the deficit was quoted over
DF_FULL    <- c(1750, 2024)     # the full historical run
DF_MARKS   <- c(1775, 1800, 1825, 1850, 1875, 1900)
DF_MARKS2  <- c(1900, 1930, 1960, 1990, 2010, 2024)
DF_PULSE   <- 100               # GtC, the idealised pulse
DF_PYEAR   <- 1760              # pulse year; leaves 264 yr of response
DF_PLAGS   <- c(10, 25, 50, 100, 150, 264)
DF_PPM_GTC <- 0.4707            # ppm per GtC, whole atmosphere
DF_BETAS   <- c(0, 0.05, 0.1, 0.2, 0.3, 0.38, 0.5, 0.7, 1.0)
DF_D13     <- c(1900, 1950, 1980, 2000, 2020)

emis <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
spl  <- as.data.frame(readRDS(ccx_path("data", "obs_icecore.rds"))$co2_spline)
obs_at <- function(y) spl$co2_ppm[which.min(abs(spl$year - y))]
co2m <- as.data.frame(readRDS(ccx_path("data", "obs_co2_monthly.rds")))
inst <- stats::aggregate(co2_ppm ~ year, co2m[co2m$station == "MLO", ], mean)
obs2 <- function(y) if (y >= min(inst$year)) inst$co2_ppm[inst$year == y] else obs_at(y)

annual <- function(o) stats::aggregate(
  cbind(co2, d13c, land, ocean) ~ year,
  data.frame(year = floor(o$t), co2 = (o$co2_NH + o$co2_SH) / 2,
             d13c = (o$d13c_NH + o$d13c_SH) / 2,
             land = o$land_C, ocean = o$ocean_C), mean)
run_win <- function(F, s) annual(ccx_run_fast(s, F)$out)

# externalise LUC on an assembled forcing: mass-exact, isotopically meaningless
externalise <- function(F) {
  F$e_foss_NH <- F$e_foss_NH + F$e_luc_NH; F$e_foss_SH <- F$e_foss_SH + F$e_luc_SH
  F$e_luc_NH <- 0; F$e_luc_SH <- 0; F$cum_luc_NH <- 0; F$cum_luc_SH <- 0
  F
}
params_at <- function(fp) { p <- ccx_default_params(); p$f_luc_perm <- fp; p }

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
# 2. THE THREE ARMS OVER 1750-1900
# =====================================================================
s0 <- ccx_spinup(params_at(0))       # the bug
s1 <- ccx_spinup(params_at(1))       # shipped
F19_0 <- ccx_build_forcing("historical", DF_WINDOW, prod_c14 = s0$prod_c14)
F19_1 <- ccx_build_forcing("historical", DF_WINDOW, prod_c14 = s1$prod_c14)

ARMS19 <- list("f_luc_perm = 0 (the bug)" = run_win(F19_0, s0),
               "f_luc_perm = 1 (SHIPPED)" = run_win(F19_1, s1),
               "external source (bound)"  = run_win(externalise(F19_1), s1))

cat("\n=== [2] RESIDUALS vs LAW DOME (model - obs, ppm) ===\n")
cat(sprintf("%-26s %s\n", "arm", paste(sprintf("%8d", DF_MARKS), collapse = "")))
cat(sprintf("%-26s %s\n", "Law Dome ppm",
            paste(sprintf("%8.2f", vapply(DF_MARKS, obs_at, numeric(1))), collapse = "")))
for (nm in names(ARMS19)) {
  a <- ARMS19[[nm]]
  cat(sprintf("%-26s %s\n", nm,
      paste(sprintf("%+8.2f",
        vapply(DF_MARKS, function(y) a$co2[a$year == y] - obs_at(y), numeric(1))),
        collapse = "")))
}
cat("  The pre-1850 LUC choice cannot touch the 1900 column -- every option in\n")
cat("  diag_pre1850_luc.R sits within 0.4 ppm there. This does.\n")

cat("\n=== [2b] WHERE THE CARBON WENT, 1750-1900 (GtC) ===\n")
cat(sprintf("%-26s %8s %8s %8s %8s\n", "arm", "atm", "land", "ocean", "AF"))
for (nm in names(ARMS19)) {
  a <- ARMS19[[nm]]; i0 <- 1; i1 <- nrow(a)
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
# external source, on a ZERO-emission background with GMST AND ENSO FROZEN.
# Left free, a zero-emission run moves +8.34 ppm over 275 yr -- the
# prescribed-warming carbon-climate feedback, not integrator drift. It nearly
# cancels in the pulse-minus-control difference, but freezing it makes the
# control a genuine flat line, which is what a gate wants.
#
# THE LUC ARM MUST MOVE THE CUMULATIVE COLUMN TOO. A pulse that moved e_luc
# alone would emit the carbon and clear no land -- i.e. it would test the bug.
# =====================================================================
cat("\n=== [3] IDEALISED PULSE PAIR: transfer-from-wood vs external source ===\n")
cat(sprintf("  %d GtC in %d, zero-emission background, frozen GMST/ENSO\n",
            DF_PULSE, DF_PYEAR))

background <- function(s) {
  ze <- data.frame(year = seq(DF_FULL[1], DF_FULL[2]),
                   fossil_GtC = 0, luc_GtC = 0, d13c_foss = -24)
  F <- ccx_build_forcing("historical", DF_FULL, prod_c14 = s$prod_c14, emissions = ze)
  F$c14_bomb <- 0; F$c14_nuclear <- 0
  F <- ccx_hold_climate(F)   # incl. observed-SST columns (2026-08-18)
  F
}
add_pulse <- function(F, luc) {
  ir <- which(F$year == DF_PYEAR)
  sh <- if (luc) FORC_LUC_NH_SHARE else FORC_FOSS_NH_SHARE
  a  <- if (luc) "e_luc_NH" else "e_foss_NH"; b <- if (luc) "e_luc_SH" else "e_foss_SH"
  F[[a]][ir] <- F[[a]][ir] + DF_PULSE * sh
  F[[b]][ir] <- F[[b]][ir] + DF_PULSE * (1 - sh)
  if (luc) {
    add <- rep(0, nrow(F)); add[ir] <- DF_PULSE * seq_len(12) / 12
    add[seq(max(ir) + 1, nrow(F))] <- DF_PULSE
    F$cum_luc_NH <- F$cum_luc_NH + add * sh
    F$cum_luc_SH <- F$cum_luc_SH + add * (1 - sh)
  }
  F
}
af_of <- function(s, F, ctl) vapply(DF_PLAGS, function(L)
  (F$co2[F$year == DF_PYEAR + L] - ctl$co2[ctl$year == DF_PYEAR + L]) /
    DF_PPM_GTC / DF_PULSE, numeric(1))

cat(sprintf("  %-24s %s\n", "lag yr", paste(sprintf("%9d", DF_PLAGS), collapse = "")))
for (fp in c(1, 0)) {
  s <- if (fp == 1) s1 else s0
  F0 <- background(s); ctl <- run_win(F0, s)
  a_luc  <- run_win(add_pulse(F0, TRUE),  s)
  a_foss <- run_win(add_pulse(F0, FALSE), s)
  if (fp == 1)
    cat(sprintf("  %-24s %s\n", "external source",
                paste(sprintf("%9.3f", af_of(s, a_foss, ctl)), collapse = "")))
  cat(sprintf("  %-24s %s\n",
              sprintf("wood xfer, f_luc=%d", fp),
              paste(sprintf("%9.3f", af_of(s, a_luc, ctl)), collapse = "")))
  if (fp == 1) {
    cat(sprintf("  %-24s %s\n", "  ratio to external",
                paste(sprintf("%9.2f", af_of(s, a_luc, ctl) / af_of(s, a_foss, ctl)),
                      collapse = "")))
    cat(sprintf("  control flatness: %+.4f ppm over %d yr\n",
                ctl$co2[nrow(ctl)] - ctl$co2[1], diff(DF_FULL)))
  }
}
cat("  PRE-FIX, A FOSSIL EMISSION WAS PERMANENT AND AN LUC EMISSION WAS A\n")
cat("  TRANSIENT THE LAND TOOK BACK IN FULL. Post-fix it is permanent -- the\n")
cat("  AF stops decaying -- at about half the fossil value. The residual is\n")
cat("  MEASURED, not assumed: see test-luc-permanence.R and sec.4.\n")

# =====================================================================
# 4. WHY THE FIX IS ~50 % AND NOT 100 % -- measured, not argued
#
# The debit leaves WOOD alone (Marcus 2026-08-12: deforestation removes
# standing woody biomass and the emitted carbon should carry that pool's lagged
# 14C), while the equilibrium falls across all four pools pro rata. Wood is
# therefore left BELOW its new equilibrium and the soils ABOVE theirs, and 70 %
# of the land's equilibrium sits in a pool that drains in 500 yr. Wood regrows
# in 37.
#
# THE TEST: shorten the passive soil. If the timescale gap is the cause, the
# ratio should go to 1. It does.
# =====================================================================
cat("\n=== [4] IS THE RESIDUAL THE WOOD/SOIL TIMESCALE GAP? ===\n")
cat(sprintf("  %-24s %s\n", "lag yr", paste(sprintf("%9d", DF_PLAGS), collapse = "")))
for (tss in c(500, 20)) {
  p <- params_at(1); p$tau_soil_slow <- tss; s <- ccx_spinup(p)
  F0 <- background(s); ctl <- run_win(F0, s)
  r <- af_of(s, run_win(add_pulse(F0, TRUE), s), ctl) /
       af_of(s, run_win(add_pulse(F0, FALSE), s), ctl)
  cat(sprintf("  %-24s %s%s\n", sprintf("tau_soil_slow = %d", tss),
              paste(sprintf("%9.2f", r), collapse = ""),
              if (tss == 500) "   <-- default" else "   <-- gap closed"))
}
cat("  CONFIRMED. The fix is exactly permanent in the infinite-time limit; on a\n")
cat("  century it delivers about half, because the debit and the equilibrium\n")
cat("  reduction land on pools 25x apart in turnover. Closing the rest means\n")
cat("  debiting the pools PRO RATA -- which trades against the 2026-08-12 call\n")
cat("  that the emitted carbon carries WOOD's 14C. That is a decision, not a bug.\n")

# =====================================================================
# 5. THE FULL HISTORICAL RUN, AND THEREFORE THE CALIBRATION
# =====================================================================
cat("\n=== [5] THE FULL HISTORICAL RUN, 1750-2024 ===\n")
Fb0 <- ccx_build_forcing("historical", DF_FULL, prod_c14 = s0$prod_c14)
Fb1 <- ccx_build_forcing("historical", DF_FULL, prod_c14 = s1$prod_c14)
FULL <- list("f_luc_perm = 0 (the bug)" = list(a = run_win(Fb0, s0), s = s0),
             "f_luc_perm = 1 (SHIPPED)" = list(a = run_win(Fb1, s1), s = s1),
             "external source (bound)"  = list(a = run_win(externalise(Fb1), s1), s = s1))
cat(sprintf("%-26s %s\n", "arm", paste(sprintf("%8d", DF_MARKS2), collapse = "")))
cat(sprintf("%-26s %s   (Law Dome < %d, MLO after)\n", "observed ppm",
            paste(sprintf("%8.1f", vapply(DF_MARKS2, obs2, numeric(1))), collapse = ""),
            min(inst$year)))
for (nm in names(FULL)) {
  a <- FULL[[nm]]$a
  cat(sprintf("%-26s %s\n", nm,
      paste(sprintf("%+8.2f",
        vapply(DF_MARKS2, function(y) a$co2[a$year == y] - obs2(y), numeric(1))),
        collapse = "")))
}
cat("  The SHIPPED arm is high at the DEFAULT beta, which is the point of\n")
cat("  sec.6: the default was centred against the bug.\n")

cat("\n=== [5b] CUMULATIVE PARTITION 1750-2024 (GtC) ===\n")
cum_f2 <- sum(emis$fossil_GtC); cum_l2 <- sum(emis$luc_GtC)
cat(sprintf("  emissions  fossil %6.1f  LUC %6.1f  total %6.1f GtC\n",
            cum_f2, cum_l2, cum_f2 + cum_l2))
cat(sprintf("%-26s %8s %8s %8s %8s\n", "arm", "atm", "land", "ocean", "AF"))
for (nm in names(FULL)) {
  a <- FULL[[nm]]$a; d_atm <- (a$co2[nrow(a)] - a$co2[1]) / DF_PPM_GTC
  cat(sprintf("%-26s %+8.1f %+8.1f %+8.1f %8.3f\n", nm, d_atm,
              a$land[nrow(a)] - a$land[1], a$ocean[nrow(a)] - a$ocean[1],
              d_atm / (cum_f2 + cum_l2)))
}
h <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$historical)
ig <- h$year %in% seq(DF_FULL[1], DF_FULL[2])
cat(sprintf("%-26s %+8.1f %+8.1f %+8.1f %8s  <-- GCB 2025 budget\n", "observed",
            sum(h$atm_growth[ig], na.rm = TRUE),
            sum(h$land_sink[ig], na.rm = TRUE) - sum(h$luc[ig], na.rm = TRUE),
            sum(h$ocean_sink[ig], na.rm = TRUE), ""))
cat("  (GCB's own LUC is 247.5 GtC -- it carries no pre-1850 column -- so the\n")
cat("   model burns 41.8 GtC more than GCB inventories. Even crediting ALL of\n")
cat("   that to the land, the BUG's land is a net SINK where the budget says\n")
cat("   net SOURCE. That sign error is the headline of this section.)\n")

# =====================================================================
# 6. WHAT beta EACH TREATMENT DEMANDS
#
# A 1-D scan at fixed everything-else is NOT a refit and its minimum is coarse.
# What it establishes is the DIRECTION and that it is large.
# =====================================================================
cat("\n=== [6] WHAT beta EACH TREATMENT DEMANDS ===\n")
DF_SCORE <- seq(1850, DF_FULL[2])
score_beta <- function(fp, b) {
  p <- params_at(fp); p$beta <- b; s <- ccx_spinup(p)
  a <- run_win(ccx_build_forcing("historical", DF_FULL, prod_c14 = s$prod_c14), s)
  d <- vapply(DF_SCORE, function(y) a$co2[a$year == y] - obs2(y), numeric(1))
  c(rmse = sqrt(mean(d^2)), r2024 = d[length(d)])
}
cat(sprintf("  %-6s | %18s | %18s\n", "beta", "f_luc_perm = 0", "f_luc_perm = 1"))
cat(sprintf("  %-6s | %8s %9s | %8s %9s\n", "", "RMSE", "res 2024", "RMSE", "res 2024"))
tab <- t(vapply(DF_BETAS, function(b) c(score_beta(0, b), score_beta(1, b)), numeric(4)))
for (i in seq_along(DF_BETAS))
  cat(sprintf("  %-6.2f | %8.2f %+9.2f | %8.2f %+9.2f%s\n", DF_BETAS[i],
              tab[i, 1], tab[i, 2], tab[i, 3], tab[i, 4],
              if (DF_BETAS[i] == ccx_default_params()$beta) "   <-- default" else ""))
mode_beta <- readRDS(ccx_path("calibration", "output", "mode_fit.rds"))$par_mode$beta
cat(sprintf("\n  best beta on this grid: %.2f with the bug, %.2f shipped",
            DF_BETAS[which.min(tab[, 1])], DF_BETAS[which.min(tab[, 3])]))
cat(sprintf("   (mode_fit.rds: %.3f)\n", mode_beta))
cat("  The mode sits BELOW even what the bug prefers, so the LUC defect is a\n")
cat("  CONTRIBUTING bias to the low beta and not the whole of it -- the other\n")
cat("  15 parameters and the d13C/14C streams are not in a 1-D scan. Do not\n")
cat("  read this as attributing the mode.\n")

# =====================================================================
# 7. WHAT IT DID TO THE d13C WORK -- and the sign is the bad one
#
# 98c1783 landed 2026-08-12. EVERY d13C result in this repo dated 2026-08-13 --
# the oceanic Suess measurement, the "atmosphere 21-25 % too fast" headline,
# the conveyor's evaluation, the sigma_d13c argument -- was measured AFTER it,
# on a model that gave land-use carbon back to the land. Land-use carbon is
# ISOTOPICALLY LIGHT, so the model was running with part of its Suess forcing
# quietly switched off.
#
# BOTH ARMS HERE KEEP LUC AS A WOOD TRANSFER, so unlike sec.2's bound this
# comparison is isotopically clean: the only difference is whether the land's
# equilibrium moves.
# =====================================================================
cat("\n=== [7] ATMOSPHERIC d13C (permil) ===\n")
cat(sprintf("  %-26s %s\n", "arm", paste(sprintf("%9d", DF_D13), collapse = "")))
d13 <- list()
for (nm in c("f_luc_perm = 0 (the bug)", "f_luc_perm = 1 (SHIPPED)")) {
  a <- FULL[[nm]]$a
  d13[[nm]] <- vapply(DF_D13, function(y) a$d13c[a$year == y], numeric(1))
  cat(sprintf("  %-26s %s\n", nm, paste(sprintf("%9.3f", d13[[nm]]), collapse = "")))
}
cat(sprintf("  %-26s %s\n", "difference (fix - bug)",
    paste(sprintf("%+9.3f", d13[[2]] - d13[[1]]), collapse = "")))
cat(sprintf("\n  Suess decline %d->%d:  bug %+.3f, shipped %+.3f permil (%.1f %% faster)\n",
            min(DF_D13), max(DF_D13),
            d13[[1]][length(DF_D13)] - d13[[1]][1],
            d13[[2]][length(DF_D13)] - d13[[2]][1],
            100 * ((d13[[2]][length(DF_D13)] - d13[[2]][1]) /
                   (d13[[1]][length(DF_D13)] - d13[[1]][1]) - 1)))
cat("  THE SIGN IS THE UNWELCOME ONE. A permanent LUC leaves MORE light carbon\n")
cat("  in the atmosphere, so the Suess decline gets FASTER -- and the model's\n")
cat("  was ALREADY ~25 % too fast (handoff 13c sec.3). Fixing the carbon defect\n")
cat("  WORSENS the d13C misfit the project has been chasing, and the ocean\n")
cat("  conclusions of 13b/13c have to be re-measured on the fixed model.\n")
