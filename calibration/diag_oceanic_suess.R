# =====================================================================
# diag_oceanic_suess.R -- the OCEAN's own d13C decline, scored for the first
# time. Headline: THE MIXED LAYER IS RIGHT AND THE ATMOSPHERE IS NOT, which
# retracts the handoff-13b sec.6 lead and moves the conveyor's goalposts.
#
# WRITTEN 2026-08-13 to discharge handoff 2026-08-13b sec.6 / sec.4.5: "the
# oceanic-Suess lead is still unverified... my recollection of the observed
# ratio is 0.35-0.45. No source in DATA.md, none in ClaudeDocs/Papers. If it
# holds it is independent evidence for sec.4 [the conveyor], and it would give
# the conveyor a target to be scored on."
#
# IT DOES NOT HOLD. Sources found, data pulled, numbers computed:
#
# [1] THE RECOLLECTION WAS WRONG, AND WRONG IN THE DIRECTION THAT MATTERS.
#     Handoff 13b sec.6 recorded model ml/atm = 0.57 against a recollected
#     observed 0.35-0.45, i.e. "the model's ocean is too responsive". Measured,
#     the observed ratio is 0.56 (cumulative, Eide) to 0.71 (rate, Quay) and
#     the model's is 0.53-0.55. The observed ocean tracks the atmosphere AT
#     LEAST as closely as the model's does. The lead is RETRACTED; it is not
#     evidence for the conveyor, and the ratio was the wrong statistic anyway
#     (see [2] -- it hides which limb is broken).
#
# [2] SPLIT THE RATIO AND THE ANSWER IS UNAMBIGUOUS. Against Quay et al. 2003's
#     global mean surface rate of 0.160 +/- 0.020 permil/decade (1970s vs
#     1990s):
#                        mixed layer            atmosphere
#       default params   0.156  (-2%, 0.2 sd)   +25% too fast
#       posterior mode   0.145  (-9%, 0.8 sd)   +21% too fast
#     The ml result is window-insensitive: 0.153-0.160 over every plausible
#     Quay window (part 3). The atmospheric result reproduces against Scripps
#     flask as well as Law Dome (+14 to +25%, part 3b), so it is not an
#     ice-core smoothing artifact.
#
#     THE MODEL'S OCEAN TAKES UP 13C AT THE OBSERVED RATE. The d13C misfit is
#     not the ocean failing to absorb the depleted signal.
#
# [3] CUMULATIVE, against Eide et al. 2017 (preindustrial -> 1990s), the ml is
#     +17% too depleted at the default h_ml = 75 m and +54% at the mode's
#     h_ml = 179 m -- but the second number is not a fair test: a well-mixed
#     179 m box against a depth-average that crosses the real thermocline is
#     not apples to apples. Read the 75 m number; treat 179 m as one more
#     reason the fitted h_ml is not a mixed-layer depth.
#
# [4] THE CONVEYOR PRE-CHECK, WHICH IS WHY THIS MATTERS NOW (part 6).
#     Handoff 13b sec.4.3 buys its d13C benefit by holding the mixed layers OUT
#     of isotopic equilibrium: at 27 Sv the SH ml sits at 0.63 and the NH at
#     0.56 of full equilibrium, a ~40% cut in ml depletion. Applied to a ml
#     Suess rate that is ALREADY at the observed value, that lands at
#     0.095 permil/decade against Quay's 0.160 +/- 0.020 -- a 3.2 sd miss. Even
#     15 Sv misses by 2.2 sd. The neglected feedback (a less depleted
#     atmosphere gives the ml less signal to follow) pushes the SAME way.
#
#     WHERE THIS PRE-CHECK IS WEAK, said plainly. It applies sec.4.3's own
#     equilibrium fraction to the CURRENT ml rate, which treats the
#     pre-conveyor ml as if it were at full isotopic equilibrium -- sec.4.3
#     derives its "37 % cut" the same way, so the two are consistent, but both
#     ignore that the model ALREADY ventilates the ml diffusively. The
#     offsetting term is real and points the other way: sec.4.5 step 3 expects
#     `kz` to fall a long way once a conveyor carries the ventilation, and a
#     smaller `kz` exports less depleted carbon out of the ml, pushing its
#     depletion back UP. So -3.2 sd is an upper bound on the damage, not a
#     prediction. What the pre-check establishes is the SIGN and the fact that
#     the trade is now scoreable at all -- not the exact size of the miss.
#     Only the run settles that, which is why this is a gate and not a veto.
#
#     THE CONVEYOR PAYS FOR THE ATMOSPHERE WITH THE ONE OCEAN QUANTITY THAT IS
#     CURRENTLY CORRECT. That does not by itself kill it -- see the compensating
#     -errors caveat below -- but it does mean the conveyor CANNOT be judged on
#     d13C alone, and the ml Suess rate must be a gate on it, alongside 4.5's
#     reverse-conveyor check.
#
# THE CAVEAT THAT KEEPS [2] HONEST, stated because it cuts both ways. An
# atmosphere declining 25% too fast driving a mixed layer that lands exactly on
# the observed rate implies the model's air-sea 13C transfer is ~20% too WEAK:
# the ml looks right partly through compensating errors, not because ocean 13C
# physics is verified. So "the ocean is right" is a statement about the model as
# it stands, not a proof. What survives regardless is the scoring consequence:
# from here, any change that lowers the ml Suess rate makes the model worse
# against a real measurement with a real error bar, and until now nothing in the
# likelihood would have noticed.
#
# WHAT THIS RECOMMENDS (a methodological choice, so Marcus' call, not a
# diagnostic's): promote Quay's rate to a likelihood term. It is the only new
# constraint here with a stated uncertainty, it is independent of the
# atmospheric d13C target the model already fits, and it pins the air-sea
# partition that q10 has been free to trade against. See DATA.md sec.2.
#
# Runs in ~5 s. Needs data/obs_oceanic_suess.rds (data-raw/build_calibration_data.R [8b]).
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
suppressWarnings(suppressMessages(library(data.table)))

# ---- labels derive from constants (project rule) --------------------
DOS_YEARS      <- c(1750, 2024)
DOS_BOMB_REF   <- 102
DOS_QUAY_WIN   <- c(1970, 1993)   # center window: GEOSECS era vs WOCE era
DOS_QUAY_WINS  <- list(c(1970, 1993), c(1970, 1995), c(1972, 1993),
                       c(1975, 1995), c(1970, 1990), c(1975, 1993))
DOS_EIDE_END   <- 1995            # nominal GLODAPv1.1 reference year
DOS_SCRIPPS    <- c(1980, 2014)   # window where both Scripps stations run
DOS_CONVEYOR_SV <- c(15, 27)      # handoff 13b sec.4.3 configurations
DOS_MODE_FIT   <- "calibration/output/mode_fit.rds"
DOS_SEC_PER_YR <- 365.25 * 86400

obs_suess <- readRDS("data/obs_oceanic_suess.rds")
QUAY      <- obs_suess$quay2003
EIDE      <- obs_suess$eide_profile

A_NH <- ccx_const("OCEAN_AREA_NH"); A_SH <- ccx_const("OCEAN_AREA_SH")
gmean <- function(nh, sh) (nh * A_NH + sh * A_SH) / (A_NH + A_SH)

# Eide depth-average over 0..h, on the model's OWN mixed-layer depth: the
# observational target has to be posed at the depth the model box represents.
eide_avg <- function(h, col = "global") {
  z <- seq(0, h, length.out = 2001)
  -mean(stats::approx(EIDE$depth, EIDE[[col]], z, rule = 2)$y)   # sign: a DECLINE
}

# observed atmosphere: Law Dome spline (repo target) + Scripps flask (independent)
sp  <- as.data.frame(readRDS("data/obs_icecore.rds")$d13c_spline)
ld  <- function(y) sp$d13c[match(y, sp$year)]
d13c_stn <- as.data.table(readRDS("data/obs_d13c_monthly.rds"))[
  , .(d13c = mean(d13c)), by = .(station, year)]

# ---- the model side -------------------------------------------------
d13 <- function(y, k) 1000 * (y[k, "C13"] / (y[k, "C"] * ccx_const("R13_VPDB")) - 1)

dos_case <- function(p) {
  s <- ccx_spinup(p)
  F <- ccx_build_forcing("historical", DOS_YEARS, prod_c14 = 0,
                         bomb_total_kmol = DOS_BOMB_REF)
  F$c14_cosmo <- s$prod_c14
  i <- s$aux$idx
  pick <- function(y) c(ml    = gmean(d13(y, i$NH$ml),  d13(y, i$SH$ml)),
                        atm   = gmean(d13(y, i$NH$atm), d13(y, i$SH$atm)),
                        ml_NH = d13(y, i$NH$ml), ml_SH = d13(y, i$SH$ml),
                        atm_NH = d13(y, i$NH$atm))
  at <- function(yend) pick(ccx_run_fast(s, F[F$t <= yend + 1e-9, ])$state)
  # gross air-sea exchange -> isotopic equilibration time, per hemisphere
  tau_eq <- sapply(HEMIS, function(h) {
    kk <- carb_constants(s$aux$sst[[h]])
    s$y[i[[h]]$ml, "C"] / (s$aux$asx[[h]] * p$k_w * kk$K0 * ccx_const("CO2_PI_PPM"))
  })
  list(spin = pick(s$y), at = at, tau_eq = tau_eq, h_ml = p$h_ml, p = p)
}

rate <- function(cs, win, key) {
  a <- cs$at(win[1])[key]; b <- cs$at(win[2])[key]
  unname((a - b) / diff(win) * 10)
}

p_def <- ccx_default_params()
p_mode <- ccx_default_params()
if (file.exists(DOS_MODE_FIT)) {
  mf <- readRDS(DOS_MODE_FIT)
  for (nm in intersect(names(p_mode), names(mf$par_mode))) p_mode[[nm]] <- mf$par_mode[[nm]]
}
CASES <- list(`DEFAULT PARAMS` = dos_case(p_def), `POSTERIOR MODE` = dos_case(p_mode))

# ---- PART 1: the observational targets, and what they can be used for
cat("== PART 1: the two observational anchors ==\n")
cat(sprintf("Quay et al. 2003 : %.3f +/- %.3f permil/decade, %s\n",
            QUAY$rate_permil_per_decade, QUAY$sd, QUAY$scope))
cat(sprintf("                   %s\n", QUAY$citation))
cat(sprintf("Eide et al. 2017 : %.3f permil at 0 m, %.3f permil 0-75 m (area-weighted),\n",
            -EIDE$global[1], eide_avg(75)))
cat(sprintf("                   %s\n", obs_suess$eide_meta$reference_period))
cat(sprintf("CAVEAT (re-verified at build): above 200 m Eide's field is the 200 m\n"))
cat(sprintf("  estimate plus a SPATIALLY CONSTANT depth offset (max level-diff sd %.1e).\n",
            obs_suess$eide_meta$max_level_diff_sd))
cat("  Its global mean is usable; its NH/SH contrast above 200 m is inherited from\n")
cat("  the 200 m level and must NOT be used to score a hemispheric gradient.\n")

# ---- PART 2: the headline comparison, both parameter sets
cat("\n== PART 2: the model's oceanic vs atmospheric Suess effect ==\n")
cat("   The ratio in handoff 13b sec.6 hid WHICH limb is wrong. Split it.\n")
cat(sprintf("%-16s %7s | %-24s | %-24s\n", "", "h_ml",
            "ml rate, permil/dec", "atm rate, permil/dec"))
for (nm in names(CASES)) {
  cs <- CASES[[nm]]
  r_ml <- rate(cs, DOS_QUAY_WIN, "ml"); r_at <- rate(cs, DOS_QUAY_WIN, "atm")
  r_at_obs <- (ld(DOS_QUAY_WIN[1]) - ld(DOS_QUAY_WIN[2])) / diff(DOS_QUAY_WIN) * 10
  cat(sprintf("%-16s %6.0fm | %.3f vs %.3f (%+.1f sd) | %.3f vs %.3f (%+.0f%%)\n",
              nm, cs$h_ml, r_ml, QUAY$rate_permil_per_decade,
              (r_ml - QUAY$rate_permil_per_decade) / QUAY$sd,
              r_at, r_at_obs, 100 * (r_at / r_at_obs - 1)))
}
cat("\n   cumulative 1750 -> ", DOS_EIDE_END, ", against Eide at the model's own h_ml:\n", sep = "")
for (nm in names(CASES)) {
  cs <- CASES[[nm]]; v0 <- cs$spin; v1 <- cs$at(DOS_EIDE_END)
  e <- eide_avg(cs$h_ml)
  cat(sprintf("%-16s ml %.3f vs %.3f (0-%.0f m) %+.0f%% | atm %.3f vs %.3f %+.0f%%\n",
              nm, v0["ml"] - v1["ml"], e, cs$h_ml,
              100 * ((v0["ml"] - v1["ml"]) / e - 1),
              v0["atm"] - v1["atm"], ld(1750) - ld(1993),
              100 * ((v0["atm"] - v1["atm"]) / (ld(1750) - ld(1993)) - 1)))
}

# ---- PART 3: is the ml result an artifact of the window, or of Law Dome?
cat("\n== PART 3: robustness -- window choice, and the atmospheric product ==\n")
cs <- CASES[["DEFAULT PARAMS"]]
cat(sprintf("%-12s %10s %10s %10s\n", "window", "ml model", "atm model", "atm LawDome"))
for (w in DOS_QUAY_WINS) {
  lo <- ld(w[1]); hi <- ld(w[2])
  cat(sprintf("%-12s %10.3f %10.3f %10s\n", paste0(w[1], "-", w[2]),
              rate(cs, w, "ml"), rate(cs, w, "atm"),
              if (is.na(hi)) "n/a" else sprintf("%.3f", (lo - hi) / diff(w) * 10)))
}
cat(sprintf("   ml spans %.3f-%.3f against Quay's %.3f +/- %.3f: window-insensitive.\n",
            min(sapply(DOS_QUAY_WINS, function(w) rate(cs, w, "ml"))),
            max(sapply(DOS_QUAY_WINS, function(w) rate(cs, w, "ml"))),
            QUAY$rate_permil_per_decade, QUAY$sd))
cat(sprintf("\n   3b. the atmosphere against Scripps flask, %d-%d (Law Dome is smoothed):\n",
            DOS_SCRIPPS[1], DOS_SCRIPPS[2]))
for (st in c("MLO", "SPO")) {
  m <- d13c_stn[station == st & year >= DOS_SCRIPPS[1] & year <= DOS_SCRIPPS[2]]
  cat(sprintf("      %-4s obs %.3f permil/dec\n", st, -coef(lm(d13c ~ year, m))[2] * 10))
}
cat(sprintf("      model global %.3f, model NH %.3f permil/dec\n",
            rate(cs, DOS_SCRIPPS, "atm"), rate(cs, DOS_SCRIPPS, "atm_NH")))

# ---- PART 4: THE CONVEYOR PRE-CHECK -- run it before building anything
# Handoff 13b sec.4.3's mechanism IS a reduction in ml depletion: the ml sits at
# tau_flush/(tau_flush + tau_eq) of full equilibrium. Apply that factor to the
# ml Suess rate the model currently gets right and see where it lands.
cat("\n== PART 4: what the conveyor would do to a mixed layer that is ALREADY right ==\n")
V_deep <- (A_NH + A_SH) * (ccx_const("OCEAN_DEPTH") - cs$h_ml)
cat(sprintf("   tau_eq (C_ml / gross air-sea exchange): NH %.1f yr, SH %.1f yr\n",
            cs$tau_eq[["NH"]], cs$tau_eq[["SH"]]))
cat(sprintf("%5s | %-22s | %-22s | %s\n", "Sv", "equilibrium fraction",
            "ml rate after (glob)", "vs Quay"))
for (sv in DOS_CONVEYOR_SV) {
  Q <- sv * 1e6 * DOS_SEC_PER_YR
  f <- c(NH = NA, SH = NA)
  for (h in HEMIS) {
    tf <- cs$h_ml / (Q / get(paste0("A_", h)))
    f[[h]] <- tf / (tf + cs$tau_eq[[h]])
  }
  r_after <- gmean(rate(cs, DOS_QUAY_WIN, "ml_NH") * f[["NH"]],
                   rate(cs, DOS_QUAY_WIN, "ml_SH") * f[["SH"]])
  cat(sprintf("%5g | NH %.2f  SH %.2f       | %.3f permil/dec        | %+.1f sd\n",
              sv, f[["NH"]], f[["SH"]], r_after,
              (r_after - QUAY$rate_permil_per_decade) / QUAY$sd))
}
cat(sprintf("   deep transit at %g Sv = %.0f yr (the sec.4.3 headline), which is NOT\n",
            DOS_CONVEYOR_SV[2], V_deep / (DOS_CONVEYOR_SV[2] * 1e6 * DOS_SEC_PER_YR)))
cat("   in question here -- the deep age is what the conveyor BUYS. The cost is\n")
cat("   above, and it is charged to a quantity that currently matches observation.\n")
cat("   PUSHING THE SAME WAY: a less depleted atmosphere gives the ml less signal\n")
cat("   to follow. PUSHING THE OTHER WAY: sec.4.5 step 3 expects kz to fall once a\n")
cat("   conveyor carries the ventilation, and a smaller kz exports less depleted\n")
cat("   carbon out of the ml. So these are an UPPER BOUND on the damage, not a\n")
cat("   prediction -- this is a gate to run the conveyor against, not a veto.\n")

cat("\n== VERDICT ==\n")
cat("   The handoff 13b sec.6 oceanic-Suess lead is RETRACTED: observed ratio is\n")
cat("   0.56-0.71, not 0.35-0.45, and the model's 0.53-0.55 sits BELOW it. Split\n")
cat("   into limbs, the ocean matches Quay and the atmosphere is 21-25% too fast.\n")
cat("   The conveyor's d13C mechanism spends the limb that is already correct;\n")
cat("   gate it on this rate, and see the compensating-errors caveat in the header.\n")
