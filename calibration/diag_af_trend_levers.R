# =====================================================================
# diag_af_trend_levers.R -- WHY IS THE MODEL'S DECADAL AIRBORNE FRACTION
#                           FLAT WHEN THE OBSERVED ONE RISES?  (2026-08-25)
#
# DESIGN gate 4 fails on its second sentence: the model's decadal AF has sd
# 0.018 against the observations' 0.048, correlates r = -0.12 with them, and
# TRENDS -0.001 per decade against an observed +0.015. The level is the best the
# model has recorded (0.434 vs 0.431); the time-dependence is absent.
#
# MARCUS'S FRAMING, 2026-08-25, which this file tests rather than assumes:
# AF rises when emissions grow fast or when SINKS SATURATE. Emissions are an
# input, so the model's only freedom is in how its sinks change over time. He
# named four candidate levers -- ocean warming/stratification, surface CO2
# saturation (the Revelle buffer), fertilization saturation, and deforestation
# reducing available land -- and said there may be others.
#
# STEP 1 WAS A CODE INVENTORY, NOT A SCAN, and it already answers part of it:
#
#   ocean, solubility falls with T   PRESENT  gx = asx*k_w*K0(sst) AND
#                                             pco2_ml = pco2_from_dic(.., sst)
#                                             -- warming cuts uptake twice over
#   ocean, Revelle buffer saturates  PRESENT  emergent from pco2_from_dic;
#                                             p$revelle_frozen switches it OFF,
#                                             which makes it MEASURABLE for free
#   ocean, stratification cuts        ABSENT  R/model.R:846 -- the interior flux
#     vertical exchange                       is p$kz * gradient, with kz a
#                                             CONSTANT. w_up defaults to 0. There
#                                             is no path from temperature to
#                                             vertical transport at all.
#   land, fertilization saturates    PRESENT  Michaelis-Menten is the live form
#                                             (CCX_FERT_MM); beta_max, fert_k
#   land, clearing costs capacity    PRESENT  R/model.R:937-947 -- `cleared`
#                                             scales npp0 by (1 - c) via
#                                             f_luc_perm, and `capacity` ties NPP
#                                             to the standing vegetation stock
#   land, warming raises respiration PRESENT  q10^(gmst/10) on both soil pools
#
# So five of the six exist and ONE IS MISSING -- and it is the first one Marcus
# named. That does not license building it yet. The prior question is whether
# the five that DO exist are simply set too weak, which is a calibration
# problem, or whether they are structurally incapable of the trend, which is
# not. [[sens_scan_achievable]]: a scan RANKS the work, it is not the fix.
#
# THREE PARTS.
#
#  A ATTRIBUTION. Switch each existing mechanism OFF at the shipped mode and
#    measure what the AF trend does. This prices what the model's time-dependence
#    is ALREADY made of. If switching all of them off barely moves the trend,
#    then the trend is set by something none of these levers touches, and adding
#    a sixth would not help either -- that is the outcome that would redirect the
#    whole line, so it is measured first.
#
#  B REACH. Push each lever to the edge of its plausible range and measure how
#    far the AF trend moves. A lever that is present but worth 0.001/decade at
#    its limit cannot close a 0.016/decade gap however it is tuned.
#
#  C THE FERTILIZATION RIDGE, MOVED ALONG rather than across. fert_k cannot be
#    scanned alone: it moves the land sink's LEVEL and its SHAPE together, and
#    the level is already nearly right. The informative experiment holds the
#    present-day NPP enhancement FIXED and varies fert_k, solving beta_max for
#    each -- i.e. traveling along the rho = +0.997 ridge, which changes how
#    saturated the response is at fixed historical integral. That isolates
#    saturation SHAPE, which is the thing gate 4 is asking about.
#
# THE TARGET IS REAL AND WAS CHECKED FIRST. The observed decadal AF trend is
# +0.0148/decade and survives GCB's own stated systematics: +0.0097 at LUC
# -0.7 GtC/yr, +0.0181 at LUC +0.7, +0.0163/+0.0135 at fossil -/+5 %. It never
# approaches zero. (LUC is the term that matters, because it is nearly flat in
# absolute terms while fossil quadruples, so its SHARE falls 38 % -> 11 % and a
# constant bias in it tilts the record.)
#
# Usage:  Rscript calibration/diag_af_trend_levers.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

AL_MODE_FILE <- ccx_mode_file()
AL_YEARS     <- c(1750, 2024)
AL_WIN       <- c(1959, 2024)
AL_DECADES   <- c(1960, 1970, 1980, 1990, 2000, 2010, 2020)
AL_CHI_NOW   <- 420          # ppm, present-day CO2 for the ridge experiment
OUTDIR       <- ccx_path("calibration", "output", "af_trend_levers")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)

GtC_PER_PPM <- ccx_const("GtC_PER_PPM")

# ---- the observed target, recomputed from the budget, not quoted -----
gcb <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$historical)
gcb <- gcb[gcb$year >= AL_WIN[1] & gcb$year <= AL_WIN[2], ]
af_obs <- vapply(AL_DECADES, function(d) {
  k <- gcb$year >= d & gcb$year <= min(d + 9, AL_WIN[2])
  sum(gcb$atm_growth[k]) / sum((gcb$fossil + gcb$luc)[k])
}, numeric(1))
al_stats <- function(dec) c(
  af   = NA_real_,
  sd   = stats::sd(dec),
  tr   = unname(stats::coef(stats::lm(dec ~ AL_DECADES))[2]) * 10,
  r    = stats::cor(dec, af_obs),
  rmse = sqrt(mean((dec - af_obs)^2)))
OBS <- al_stats(af_obs)
cat(sprintf("\nTARGET (GCB 2025, recomputed): AF %.3f | decadal sd %.4f | trend %+.4f/dec\n",
            sum(gcb$atm_growth) / sum(gcb$fossil + gcb$luc), OBS[["sd"]], OBS[["tr"]]))

# ---- the mode ---------------------------------------------------------
md <- readRDS(AL_MODE_FILE)
ccx_require_param_set(md, "the airborne-fraction trend-lever diagnostic")
P0 <- ccx_default_params()
for (n in intersect(names(P0), CCX_PARAM_NAMES)) P0[[n]] <- md$par_mode[[n]]
P0 <- ccx_set_enso(P0, md$par_mode)
P0$pump_mode  <- md$pump_mode
LUC0  <- md$par_mode$luc_scale
BOMB0 <- md$par_mode$bomb_total
cat(sprintf("mode arm %s (logpost %.2f): beta_max %.4f  fert_k %.1f  q10 %.3f  kz %.0f  f_luc_perm %.3f\n",
            CCX_MODE_CANONICAL,
            md$logpost, P0$beta_max, P0$fert_k, P0$q10, P0$kz, P0$f_luc_perm))

al_run <- function(p, luc_scale = LUC0) {
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", AL_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = BOMB0, luc_scale = luc_scale)
  o  <- ccx_run_fast(sp, F)$out
  yrs <- sort(unique(floor(o$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
  atm <- stats::approx(o$t, (o$co2_NH + o$co2_SH) / 2 * GtC_PER_PPM, xout = bnd, rule = 2)$y
  grow <- diff(atm)
  el <- ccx_forcing_eluc_annual(F)
  ef <- stats::aggregate(list(efoss = F$e_foss_NH + F$e_foss_SH),
                         by = list(year = F$year), FUN = mean)
  luc <- el$eluc[match(yrs, el$year)]; foss <- ef$efoss[match(yrs, ef$year)]
  af <- function(k) sum(grow[k]) / sum((foss + luc)[k])
  kw <- yrs >= AL_WIN[1] & yrs <= AL_WIN[2]
  dec <- vapply(AL_DECADES, function(d)
    af(yrs >= d & yrs <= min(d + 9, AL_WIN[2]) & kw), numeric(1))
  s <- al_stats(dec); s[["af"]] <- af(kw)
  list(stats = s, dec = dec, co2_2024 = (o$co2_NH + o$co2_SH)[length(o$t)] / 2)
}

al_row <- function(lab, p, luc_scale = LUC0, base = NULL) {
  r <- al_run(p, luc_scale); s <- r$stats
  cat(sprintf("  %-34s %6.3f  %7.4f  %+8.4f  %+6.2f  %6.4f%s\n", lab,
              s[["af"]], s[["sd"]], s[["tr"]], s[["r"]], s[["rmse"]],
              if (is.null(base)) "" else sprintf("   d(trend) %+.4f", s[["tr"]] - base)))
  r
}
hdr <- function() cat(sprintf("  %-34s %6s  %7s  %8s  %6s  %6s\n",
                              "", "AF", "dec sd", "trend/dec", "r(obs)", "RMSE"))

cat("\n=== BASELINE ===\n"); hdr()
BASE <- al_row("shipped mode (arm N)", P0)
TR0  <- BASE$stats[["tr"]]
cat(sprintf("  %-34s %6.3f  %7.4f  %+8.4f  %6s  %6s\n",
            "GCB 2025 observed", sum(gcb$atm_growth) / sum(gcb$fossil + gcb$luc),
            OBS[["sd"]], OBS[["tr"]], "--", "--"))
cat(sprintf("\n  THE GAP TO CLOSE: %+.4f per decade.\n", OBS[["tr"]] - TR0))

# =====================================================================
# A  ATTRIBUTION -- switch each EXISTING mechanism off
# =====================================================================
cat("\n=== A. ATTRIBUTION: what is the model's AF trend already made of? ===\n")
cat("  Each row DISABLES one mechanism. A large NEGATIVE d(trend) means that\n")
cat("  mechanism is already supplying trend; a ~0 means it supplies none.\n")
hdr()
A <- list()
p <- P0; p$revelle_frozen <- 1
A$revelle <- al_row("Revelle buffer FROZEN at 1750", p, base = TR0)
p <- P0; p$sst_obs <- 0; p$sst_scale <- 0
A$oceanT  <- al_row("ocean warming OFF (sst held)", p, base = TR0)
p <- P0; p$q10 <- 1
A$landT   <- al_row("land warming OFF (q10 = 1)", p, base = TR0)
p <- P0; p$f_luc_perm <- 0
A$clear   <- al_row("clearing costs NO capacity", p, base = TR0)
p <- P0; p$fert_k <- 1e7; p$beta_max <- P0$beta_max * (1e7 + AL_CHI_NOW - ccx_const("CO2_PI_PPM")) /
                                        (P0$fert_k + AL_CHI_NOW - ccx_const("CO2_PI_PPM"))
A$fertsat <- al_row("fertilisation LINEARISED", p, base = TR0)
p <- P0; p$revelle_frozen <- 1; p$sst_obs <- 0; p$sst_scale <- 0; p$q10 <- 1; p$f_luc_perm <- 0
A$allsw   <- al_row("ALL FOUR SWITCHES OFF", p, base = TR0)

# =====================================================================
# B  REACH -- how far can each lever push, inside a plausible range?
# =====================================================================
cat("\n=== B. REACH: how far does each lever move the AF trend? ===\n")
B <- list()
for (nm in c("q10", "f_luc_perm", "kz")) {
  grid <- switch(nm,
    q10        = c(1.5, 2.0, P0$q10, 3.0, 4.0),
    f_luc_perm = c(0, 0.25, P0$f_luc_perm, 0.75, 1.0),
    kz         = c(2000, 3942.5, P0$kz, 6528, 9000))
  cat(sprintf("\n  -- %s (mode %.4g) --\n", nm, P0[[nm]])); hdr()
  B[[nm]] <- lapply(sort(unique(grid)), function(v) {
    p <- P0; p[[nm]] <- v
    al_row(sprintf("%s = %.4g%s", nm, v, if (isTRUE(all.equal(v, P0[[nm]]))) "  <- mode" else ""),
           p, base = TR0)
  })
}

# =====================================================================
# C  THE FERTILIZATION RIDGE, TRAVELED ALONG
# =====================================================================
cat("\n=== C. ALONG THE (beta_max, fert_k) RIDGE at FIXED present-day NPP boost ===\n")
d_now <- AL_CHI_NOW - ccx_const("CO2_PI_PPM")
enh0  <- P0$beta_max * d_now / (P0$fert_k + d_now)
cat(sprintf("  Holding enh(%d ppm) = %.4f, the mode's own value, and solving beta_max\n",
            AL_CHI_NOW, enh0))
cat("  for each fert_k. Low fert_k = STRONGLY saturating; high = nearly linear.\n"); hdr()
C <- lapply(c(60, 120, 250, P0$fert_k, 1000, 2000), function(K) {
  p <- P0; p$fert_k <- K; p$beta_max <- enh0 * (K + d_now) / d_now
  lab <- sprintf("fert_k %6.1f  beta_max %.3f%s", K, p$beta_max,
                 if (isTRUE(all.equal(K, P0$fert_k))) "  <- mode" else "")
  if (p$beta_max > 3) { cat(sprintf("  %-34s  beta_max %.2f EXCEEDS the [0,3] bound -- skipped\n", lab, p$beta_max)); return(NULL) }
  al_row(lab, p, base = TR0)
})

saveRDS(list(obs = af_obs, obs_stats = OBS, base = BASE, A = A, B = B, C = C,
             mode = list(file = AL_MODE_FILE, logpost = md$logpost,
                         beta_max = P0$beta_max, fert_k = P0$fert_k, q10 = P0$q10,
                         kz = P0$kz, f_luc_perm = P0$f_luc_perm)),
        file.path(OUTDIR, "af_trend_levers.rds"))
cat(sprintf("\nwritten: %s\n", file.path(OUTDIR, "af_trend_levers.rds")))
