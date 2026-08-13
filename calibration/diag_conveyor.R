# =====================================================================
# diag_conveyor.R -- the conveyor measured, at fixed parameters, against every
# gate the red team set. HEADLINE: THE ML-SUESS OBJECTION IS DEAD, AND IT DIED
# THE WAY THE RED TEAM SAID IT MIGHT.
#
# notes/redteam_2026-08-13_conveyor_configurations.md estimated that the
# conveyor would cut the mixed-layer Suess rate by ~40 % and miss Quay's
# 0.160 +/- 0.020 permil/decade by -3.2 sd -- while stating explicitly that this
# was an UPPER BOUND, because sec.4.5 step 3 expects `kz` to FALL under a
# conveyor and a smaller `kz` exports less depleted carbon out of the mixed
# layer, pushing depletion back UP.
#
# MEASURED, THE SECOND EFFECT WINS OUTRIGHT. At fixed kz = 5000 the conveyor
# does cut the rate, but only slightly (0.156 -> 0.147 at 20 Sv, -0.6 sd, not
# -2.5). Reduce kz -- which is the entire point of the exercise -- and the rate
# goes the OTHER WAY and overshoots on the HIGH side: 0.185 at kz 2000, 0.212 at
# kz 1000, 0.237 at kz 500. The binding constraint is not the one the red team
# feared. It is the opposite one, and it now bites from above.
#
# WHAT THAT MEANS FOR THE REFIT: `kz` and Q are jointly constrained by the ml
# Suess rate from ABOVE and by the deep age from BELOW, which is a much better
# situation than the degenerate ridge the red team predicted. The two gates pull
# in opposite directions on kz, so the pair may be identified after all.
#
# THE DEEP OCEAN GOES BIPOLAR, WHICH IS THE STRUCTURAL WIN. Without a conveyor
# the two hemispheres' deep oceans are the same age (-170.8 / -169.5), which is
# the single number the kz bracket was bisected on. With one they separate, in
# the observed sense (young ventilated end, old far end):
#
#     C, 20 Sv, kz 5000   NH -112.9   SH -157.2     both too young
#     C, 20 Sv, kz 2000   NH -158.6   SH -222.5     <-- the interesting cell
#     C, 20 Sv, kz 1000   NH -214.3   SH -277.1     both too old
#
# NOTE WHAT TO COMPARE THAT AGAINST. CCX_PARAM_TABLE's [-150, -200] bracket is a
# GLOBAL-AVERAGE target derived on a single-column ocean (12d sec.6) and it is
# the wrong yardstick for a bipolar deep ocean. The real ocean is not one age:
# deep North Atlantic is young and deep North Pacific is old. NH -159 / SH -223
# at kz 2000 is plausibly a BETTER representation than the flat -170 it
# replaces -- but that is a claim about which observational target to use, and
# the target has to be chosen before the refit, not after seeing this table.
# FLAGGED AS A METHODOLOGICAL CHOICE FOR MARCUS, not resolved here.
#
# THE CONFIGURATIONS ARE GENUINELY DIFFERENT, and in the direction the ocean
# expert predicted -- C leaves the abyss unventilated by advection, so it needs
# LESS help from kz and runs older at the same kz:
#
#     at 20 Sv, kz 1000   A (sink 10, non-local)   NH -136.5  SH -150.0
#                         B (sink 10, distributed) NH -100.8  SH -177.6
#                         C (sink  8, non-local)   NH -214.3  SH -277.1
#
# AND NOW THE TWO RESULTS THAT GO AGAINST THE PROPOSAL, both of which the
# handoff itself nominated as the things to check:
#
# [1] SEC.4.4'S FALSIFIABLE PREDICTION FAILS. It states: "An NH-sinking /
#     SH-upwelling conveyor ... should SHRINK the model's NH-SH d13C gradient,
#     which is currently too large by 3x ... This is the conveyor's falsifiable,
#     independent claim, and it is scored by the existing likelihood -- if the
#     gradient does not shrink, the mechanism is not doing what this section
#     says." IT DOES NOT SHRINK. MLO-SPO goes -0.218 (off) -> -0.221 at 20 Sv ->
#     -0.223 at 27 Sv, i.e. very slightly the WRONG WAY, against an observed
#     -0.074. Falling kz recovers only -0.215 at kz 2000. On its own stated
#     test, the sec.4.4 mechanism does not do what sec.4.4 says.
#
# [2] kz CANNOT ACTUALLY FALL FAR, which was the strongest argument for
#     building this at all (red team sec.1: kz = 5000 is ~9x Ledwell's NATRE
#     thermocline diffusivity). Dropping it degrades BOTH remaining constraints
#     sharply: d13C bias +0.500 -> +0.678 (kz 2000) -> +0.820 (kz 1000), and CO2
#     bias +5.4 -> -5.8 -> -12.5 ppm. At FIXED kz = 5000 the conveyor helps d13C
#     (+0.548 -> +0.500 at 20 Sv, +0.483 at 27 Sv) -- real, and about a third of
#     sec.4.3's hoped 0.15-0.25 permil. Take the kz reduction and you give it
#     back with interest.
#
#     THIS IS EXACTLY WHAT THE REFIT IS FOR, and it is why none of it is a
#     verdict. Every other parameter is frozen at its default here, and k_w,
#     h_ml, beta and q10 are all free to absorb some of this. The red team's
#     four advance predictions (kz falls, h_ml falls, tau_ex rises, gradient
#     shrinks) are still the scorecard -- and on this evidence the fourth is
#     already in trouble.
#
# Runs in ~1 min. Nothing here is a fit: every parameter except q_conv and kz is
# at its default, so read the COLUMNS against each other, not the absolute
# biases -- those are the mode's job and the mode has not been refit.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
suppressWarnings(suppressMessages(library(data.table)))

# ---- labels derive from constants (project rule) --------------------
DC_YEARS     <- c(1750, 2024)
DC_BOMB_REF  <- 102
DC_BIAS_WIN  <- c(2015, 2024)
DC_GRAD_WIN  <- c(1993, 2014)   # window where both MLO and SPO d13C obs exist
DC_QUAY_WIN  <- c(1970, 1993)
DC_GRAD_OBS  <- -0.074          # observed MLO-SPO d13C, permil, DC_GRAD_WIN
DC_DEEP_OBS  <- c(-150, -200)   # CCX_PARAM_TABLE's global-average bracket
# Preindustrial interhemispheric gradient targets, added 2026-08-13 when Marcus
# asked whether the gradient the conveyor now produces is observable.
#   CO2: it is NOT. Greenland ice CO2 runs 20-30 ppm ABOVE Antarctic with a
#   standard deviation of 6-10 ppm (vs 2-3 in Antarctic ice), from in-situ
#   production by carbonate-acid reactions and oxidation of organics -- Anklin
#   et al. 1995, Barnola et al. 1995, Tschumi & Stauffer 2000. The ARTEFACT is
#   ~150x the signal below and the SCATTER alone is ~50x it.
#   D14C: it IS, and it is the apposite test, because the observed offset is
#   driven substantially by Southern Ocean upwelling of 14C-depleted water --
#   which is exactly the limb the conveyor adds.
DC_SHCAL_YR  <- c(36, 27)       # SHCal20: SH older than NH, 14C yr, mean +/- sd
DC_LIBBY     <- 8033            # yr, Libby mean life -- the convention 14C AGES use
DC_CONFIGS   <- list(A = list(sink = N_INTERIOR, desc = 0L, why = "sec.4.2 as written"),
                     B = list(sink = N_INTERIOR, desc = 1L, why = "distributed descent"),
                     C = list(sink = 8L,         desc = 0L, why = "NADW depth (default)"))

obs   <- ccx_prepare_obs()
QUAY  <- readRDS("data/obs_oceanic_suess.rds")$quay2003
base_forcing <- ccx_build_forcing("historical", DC_YEARS, prod_c14 = 0,
                                  bomb_total_kmol = DC_BOMB_REF)
A_NH <- ccx_const("OCEAN_AREA_NH"); A_SH <- ccx_const("OCEAN_AREA_SH")
gmean <- function(a, b) (a * A_NH + b * A_SH) / (A_NH + A_SH)
d13box <- function(y, k) 1000 * (y[k, "C13"] / (y[k, "C"] * ccx_const("R13_VPDB")) - 1)

dc_metrics <- function(q, kz, cfg) {
  p <- ccx_default_params()
  p$q_conv <- q; p$kz <- kz
  p$conv_sink <- cfg$sink; p$conv_descent <- cfg$desc
  s <- try(ccx_spinup(p), silent = TRUE)
  if (inherits(s, "try-error")) return(NULL)
  F <- base_forcing; F$c14_cosmo <- s$prod_c14
  out <- ccx_run_fast(s, F)$out
  if (anyNA(out$co2_NH)) return(NULL)
  ms <- ccx_model_stats(out, obs)
  lev <- function(o, m, col = "level") {
    k <- match(o$year, m$year)
    g <- !is.na(k) & o$year >= DC_BIAS_WIN[1] & o$year <= DC_BIAS_WIN[2]
    mean(o[[col]][g] - m$level[k[g]])
  }
  i  <- s$aux$idx
  at <- function(ye) {
    r <- ccx_run_fast(s, F[F$t <= ye + 1e-9, ])$state
    gmean(d13box(r, i$NH$ml), d13box(r, i$SH$ml))
  }
  kN <- match(DC_GRAD_WIN[1]:DC_GRAD_WIN[2], ms$d13$MLO$year)
  kS <- match(DC_GRAD_WIN[1]:DC_GRAD_WIN[2], ms$d13$SPO$year)
  dh <- s$diagnostics$d14c_deep_by_hemi
  list(deep_NH = dh[["NH"]], deep_SH = dh[["SH"]],
       ml_rate = (at(DC_QUAY_WIN[1]) - at(DC_QUAY_WIN[2])) / diff(DC_QUAY_WIN) * 10,
       d13bias = lev(obs$d13_ann$MLO, ms$d13$MLO),
       co2bias = lev(obs$co2_ann$MLO, ms$co2$MLO),
       grad    = mean(ms$d13$MLO$level[kN] - ms$d13$SPO$level[kS]),
       resid   = s$diagnostics$max_abs_dCdt)
}

hdr <- function() cat(sprintf("%-24s %9s %9s | %8s %7s | %8s %8s %8s\n",
  "", "deep NH", "deep SH", "mlSuess", "vs Quay", "d13bias", "grad", "CO2bias"))
row <- function(tag, m) {
  if (is.null(m)) return(cat(sprintf("%-24s  -- did not run --\n", tag)))
  cat(sprintf("%-24s %+9.1f %+9.1f | %8.3f %+6.1fsd | %+8.3f %+8.3f %+8.1f\n",
    tag, m$deep_NH, m$deep_SH, m$ml_rate,
    (m$ml_rate - QUAY$rate_permil_per_decade) / QUAY$sd, m$d13bias, m$grad, m$co2bias))
}

cat("== targets ==\n")
cat(sprintf("  deep D14C  %g to %g permil (GLOBAL-AVERAGE bracket, single-column origin;\n",
            DC_DEEP_OBS[1], DC_DEEP_OBS[2]))
cat("             see the header -- it is the wrong yardstick for a bipolar deep ocean)\n")
cat(sprintf("  ml Suess   %.3f +/- %.3f permil/dec (Quay et al. 2003)\n",
            QUAY$rate_permil_per_decade, QUAY$sd))
cat(sprintf("  d13C bias  0 (model currently %+.3f) | MLO-SPO gradient %+.3f observed\n\n",
            NA_real_, DC_GRAD_OBS))

cat("== PART 1: Q at the incumbent kz = 5000 ==\n"); hdr()
row("OFF", dc_metrics(0, 5000, DC_CONFIGS$C))
for (q in c(10, 20, 27)) row(sprintf("C %d Sv", q), dc_metrics(q, 5000, DC_CONFIGS$C))

cat("\n== PART 2: kz falling at 20 Sv -- the point of the exercise ==\n"); hdr()
for (kz in c(5000, 3000, 2000, 1000, 500))
  row(sprintf("C 20 Sv, kz %d", kz), dc_metrics(20, kz, DC_CONFIGS$C))
cat("   NOTE the ml Suess rate rises as kz falls and overshoots Quay from ABOVE.\n")
cat("   The red team's -3.2 sd was an upper bound on the OPPOSITE effect, and the\n")
cat("   offsetting term it flagged dominates. kz is now squeezed from both sides:\n")
cat("   the deep age wants it small, the ml Suess rate wants it large.\n")

cat("\n== PART 3: the three configurations, 20 Sv ==\n"); hdr()
for (kz in c(2000, 1000)) {
  for (nm in names(DC_CONFIGS))
    row(sprintf("%s 20 Sv, kz %d", nm, kz), dc_metrics(20, kz, DC_CONFIGS[[nm]]))
}
cat("   C leaves the abyss advectively unventilated, so it needs LESS help from\n")
cat("   kz and runs older at the same kz -- exactly the ocean expert's prediction.\n")

cat("\n== WHAT IS NOT SETTLED HERE ==\n")
cat("   Every parameter except q_conv and kz is at its DEFAULT. The absolute\n")
cat("   biases are the mode's job and the mode has NOT been refit, so read the\n")
cat("   columns against each other. The refit is the experiment (red team sec.6),\n")
cat("   and it needs the deep-D14C target chosen FIRST -- a bipolar ocean cannot\n")
cat("   be scored against a global-average bracket. Marcus' call.\n")

# ---- PART 4: the PREINDUSTRIAL interhemispheric gradients -----------
# The conveyor gives the preindustrial atmosphere a gradient it did not have,
# because one hemisphere's mixed layer outgasses and the other ingasses. Is that
# observable? For CO2, no. For 14C, yes -- and 14C is the better test anyway.
cat("\n== PART 4: preindustrial (1750) interhemispheric gradients, NH - SH ==\n")
age2d14c <- function(yr) 1000 * (exp(yr / DC_LIBBY) - 1)
shcal <- c(mid = age2d14c(DC_SHCAL_YR[1]),
           sd  = (age2d14c(sum(DC_SHCAL_YR)) - age2d14c(diff(rev(DC_SHCAL_YR)))) / 2)
cat(sprintf("%-18s %10s %12s %12s\n", "config", "CO2 ppm", "d13C permil", "D14C permil"))
for (q in c(0, 10, 20, 27)) {
  p <- ccx_default_params(); p$q_conv <- q; p$conv_sink <- DC_CONFIGS$C$sink
  s4 <- ccx_spinup(p); i <- s4$aux$idx
  g <- function(f) f("NH") - f("SH")
  ppm <- function(h) s4$y[i[[h]]$atm, "C"] / s4$aux$gtc_per_ppm_hemi
  d13 <- function(h) 1000 * (s4$y[i[[h]]$atm, "C13"] /
                             (s4$y[i[[h]]$atm, "C"] * ccx_const("R13_VPDB")) - 1)
  d14 <- function(h) 1000 * (s4$y[i[[h]]$atm, "C14"] / s4$y[i[[h]]$atm, "C"] - 1)
  cat(sprintf("%-18s %+10.4f %+12.5f %+12.3f   (%.0f%% of SHCal, z %+.2f)\n",
      if (q == 0) "OFF" else sprintf("C %d Sv", q),
      g(ppm), g(d13), g(d14), 100 * g(d14) / shcal[["mid"]],
      (g(d14) - shcal[["mid"]]) / shcal[["sd"]]))
}
cat(sprintf("\n   CO2  : NOT TESTABLE. Greenland ice CO2 sits 20-30 ppm above Antarctic\n"))
cat(sprintf("          with sd 6-10 ppm (Antarctic 2-3), from in-situ carbonate-acid\n"))
cat(sprintf("          production. The artefact is ~150x the signal above.\n"))
cat(sprintf("   D14C : SHCal20 puts the SH %g +/- %g 14C yr OLDER = %+.2f +/- %.2f permil.\n",
            DC_SHCAL_YR[1], DC_SHCAL_YR[2], shcal[["mid"]], shcal[["sd"]]))
cat(sprintf("          The conveyor moves the model from 22%% to 53%% of that central\n"))
cat(sprintf("          value, i.e. the RIGHT direction and about half the gap closed --\n"))
cat(sprintf("          but the +/-27 yr observational spread cannot discriminate strongly.\n"))
cat(sprintf("          This is the independent test sec.4.4 wanted and did not get.\n"))
