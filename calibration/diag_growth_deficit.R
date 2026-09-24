# =====================================================================
# THE RECENT GROWTH DEFICIT -- IS IT A DECADAL AF DIFFERENCE, OR THE KNOWN
# INTERANNUAL AMPLITUDE SHORTFALL?
#
# (Follows 09-24 (i). That entry showed the full-record land-sink "bias" is
#  GCB's own unclosed imbalance and is not a model defect. What SURVIVED is a
#  last-decade atmospheric-growth deficit: model minus observed growth is
#  -0.45 GtC/yr over 2015-2023 and -0.91 over 2020-2024, median ~ mean, yet the
#  cumulative level drift oscillates inside +/-1.6 ppm with NO trend.)
#
# ⭐⭐ THE TENSION THAT MOTIVATES THIS. A persistent -0.45 GtC/yr over nine years
# is -4.1 GtC = -1.9 ppm. A defect that size should be VISIBLE in the level, and
# the level does not drift. Two readings survive that, and they are separated by
# WHERE the difference sits in frequency:
#   (a) DECADAL -- the model's smooth airborne fraction differs from the
#       observed one over this stretch. Accumulates while it lasts; would have
#       to REVERSE later to leave no trend, so it predicts an oscillating AF.
#   (b) INTERANNUAL -- the model's year-to-year growth swing is too SMALL
#       (GATE V: obs sd 0.907-0.933, model arms 0.627-0.698). A pure amplitude
#       shortfall has ZERO mean by construction, so it can produce a window
#       mean that looks like a bias WITHOUT ever accumulating.
#   ⇒ (b) explains the non-accumulation for free; (a) needs a coincidence.
#      THAT is why the split is worth measuring rather than assuming.
#
# ⛔ THE DISCRIMINATING TEST IS NOT "is the model too smooth" -- GATE V ALREADY
# ANSWERS THAT, and it fails. It is whether the MEASURED shortfall is big enough
# to PRODUCE the window means observed. An amplitude deficiency of 30 % can only
# manufacture a window bias of 0.3 x (that window's mean observed anomaly), so
# the question is arithmetic and it has a number.
#
# ⚠ ONE ESTIMATOR, NOT A SECOND COPY. The smooth/anomaly split is GATE V's own
# `dg_v_anom()` (growth on emissions with a DG_V_DF-dof time-varying airborne
# fraction), applied IDENTICALLY to model and observation. A hand-rolled
# detrend here would be the caption-sync bug class one level up.
# ⚠ A GATE V FAIL IS NOT A BLOCKER (Marcus 2026-09-04) and nothing here treats
# it as one. This asks what the shortfall EXPLAINS, not whether to chase it.
# =====================================================================

suppressWarnings(suppressMessages({
  for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)
}))
ccx_load_cpp()
source(file.path("calibration", "lib_design_gates.R"))

GD_DECADES   <- seq(1960, 2020, by = 10)
GD_G7_RECORD <- 3.09        # gate 7's recorded land sink -- the build anchor
GD_G7_TOL    <- 0.02
GD_PRIOR     <- c(late = -0.45, recent = -0.91)  # 09-24 (i)'s window means
GD_PRIOR_TOL <- 0.01        # these must REPRODUCE, not merely resemble
GD_LATE      <- c(2015, 2023)
GD_RECENT    <- c(2020, 2024)
GD_DF_WALK   <- 2:5         # DG_V_DF is a SMOOTHING CHOICE; walk it, as gate V does

cat(sprintf("\n%s\nTHE GROWTH DEFICIT: decadal AF, or the interannual shortfall?\n%s\n",
            strrep("=", 72), strrep("=", 72)))

# ---- the mode, built the way app/global.R builds it -----------------
md   <- readRDS(ccx_mode_file())
pins <- ccx_mode_pins(md)
rmp  <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rmp), add = TRUE)
bp   <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
pm   <- ccx_mode_par_with_pins(md)
if (length(ccx_mode_absent(md))) pm <- ccx_migrate_par_set(pm)
for (n in intersect(names(bp), names(pm))) bp[[n]] <- pm[[n]]
bp   <- ccx_set_enso(bp, pm)
for (n in names(pins)) bp[[n]] <- pins[[n]]
spin <- ccx_spinup_from_label(ccx_mode_spinup(md))(bp)
F    <- suppressWarnings(ccx_build_forcing("historical", DG_YEARS,
                                           prod_c14 = spin$prod_c14,
                                           luc_scale = pm$luc_scale,
                                           bomb_total_kmol = pm$bomb_total))
r    <- ccx_run_fast(spin, F); r$F <- F
cat(sprintf("\nmode %s (logpost %.2f), spinup %s, luc_scale %.4f\n",
            CCX_MODE_CANONICAL, md$logpost, ccx_mode_spinup(md), pm$luc_scale))

# ---- ANCHOR 1: the parameter build -----------------------------------
g7 <- dg_gate7(r)
cat(sprintf("\n[ANCHOR 1] gate 7 land %.2f (recorded %.2f)\n", g7$land, GD_G7_RECORD))
if (abs(g7$land - GD_G7_RECORD) > GD_G7_TOL)
  stop("ANCHOR 1 FAILED: the parameter build is wrong; nothing below is about CCX.")

# ---- the two growth series, on gate V's own annual construction ------
am <- dg_af_annual_model(r)
ao <- DG_AF_OBS_ANNUAL
d  <- merge(data.frame(year = am$year, g_m = am$grow, e_m = am$foss + am$luc),
            data.frame(year = ao$year, g_o = ao$grow, e_o = ao$foss + ao$luc),
            by = "year")
d$dg <- d$g_m - d$g_o
win <- function(w) d$year >= w[1] & d$year <= w[2]

# ---- ANCHOR 2: 09-24 (i)'s window means must REPRODUCE ---------------
# ⚠ A DIFFERENT estimator of the same quantity is a finding, not a rounding
# difference: dg_af_annual_model() and dg_annual_sinks() build the model's
# growth by separate routes. If they disagree, ONE OF THEM IS WRONG.
got <- c(late = mean(d$dg[win(GD_LATE)]), recent = mean(d$dg[win(GD_RECENT)]))
cat(sprintf("[ANCHOR 2] growth deficit %d-%d %+.2f (recorded %+.2f); %d-%d %+.2f (recorded %+.2f)\n",
            GD_LATE[1], GD_LATE[2], got["late"], GD_PRIOR["late"],
            GD_RECENT[1], GD_RECENT[2], got["recent"], GD_PRIOR["recent"]))
if (any(abs(got - GD_PRIOR) > GD_PRIOR_TOL))
  stop("ANCHOR 2 FAILED: this script's growth differs from 09-24 (i)'s. ",
       "Two estimators of one quantity disagree -- fix that before reading on.")
# ---- ANCHOR 3: GATE V, the statistic this script reinterprets --------
gv <- dg_gateV(r); ov <- dg_gateV_obs()
cat(sprintf("[ANCHOR 3] GATE V sd: model %.3f, obs %.3f (ratio %.2f), z %+.2f -- %s\n",
            gv$sd, ov$sd, gv$sd / ov$sd, (gv$sd - ov$sd) / ov$se,
            if (dg_gateV_verdict(gv, ov)$pass) "PASS" else "FAIL"))
cat("           (a GATE V FAIL is NOT a blocker -- Marcus 2026-09-04. Reported, not chased.)\n")
cat("           all anchors OK.\n")

# ---- [1] is the deficit even outside the record's own wander? --------
# ⛔ A bias needs an error bar before it needs an explanation -- and the bar must
# come from an OBSERVATION, not from a number typed from memory
# ([[threshold_from_obs_or_law]]). GCB publishes an uncertainty on the
# atmospheric-growth term, but this file has no citation for it, so it is NOT
# used. The scale used instead is MEASURED on this record: the sd of the OBSERVED
# interannual growth anomaly, gate V's own estimator. That is how far a single
# year's growth naturally wanders, and the window mean's error follows from it.
# ⚠ Legitimate only because the observed anomaly is WHITE (gate V records lag-1
# rho +0.014), so sqrt(n) applies; it is re-measured below rather than trusted.

# ---- [2] ONSET: is the recent window even unusual? -------------------
cat("\n[2] IS THE RECENT WINDOW UNUSUAL? (growth deficit by decade, GtC/yr)\n")
for (y0 in GD_DECADES) {
  k <- d$year >= y0 & d$year <= y0 + 9
  if (any(k)) cat(sprintf("    %d-%d %+8.2f\n", y0, min(y0 + 9, max(d$year)), mean(d$dg[k])))
}
cat("    ⚠ read the 1980s before calling the 2010s an onset.\n")

# ---- [3] how much of 2020-2024 is 2024? ------------------------------
cat("\n[3] LEVERAGE OF THE SINGLE WORST YEAR\n")
k <- win(GD_RECENT); yy <- d$year[k]; vv <- d$dg[k]
wi <- which.max(abs(vv))
cat(sprintf("    %d-%d mean %+.2f; worst year %d (%+.2f); WITHOUT it %+.2f\n",
            GD_RECENT[1], GD_RECENT[2], mean(vv), yy[wi], vv[wi], mean(vv[-wi])))

# ---- [4] ⭐ THE SPLIT: decadal AF vs interannual anomaly --------------
# dg_v_anom() is gate V's estimator; the SMOOTH part is growth minus it.
split_at <- function(df) {
  em <- dg_v_anom(am, df = df); eo <- dg_v_anom(ao, df = df)
  ky <- ao$year[ao$year >= DG_V_WIN[1] & ao$year <= DG_V_WIN[2]]
  data.frame(year = ky, e_m = em, e_o = eo,
             s_m = d$g_m[match(ky, d$year)] - em,
             s_o = d$g_o[match(ky, d$year)] - eo)
}
sp <- split_at(DG_V_DF)
sp$d_smooth <- sp$s_m - sp$s_o
sp$d_anom   <- sp$e_m - sp$e_o
swin <- function(w) sp$year >= w[1] & sp$year <= w[2]
if (max(abs((sp$d_smooth + sp$d_anom) - d$dg[match(sp$year, d$year)])) > 1e-9)
  stop("GATE: the frequency split does not reconstruct the deficit. ",
       "DECADAL + interannual must equal the deficit exactly, or the table below ",
       "attributes carbon that is not there.")

cat(sprintf("\n[1] IS THE WINDOW MEAN DISTINGUISHABLE FROM THE RECORD'S OWN SCATTER?\n"))
sd_o <- stats::sd(sp$e_o); rho_o <- stats::acf(sp$e_o, plot = FALSE, lag.max = 1)$acf[2]
cat(sprintf("    observed interannual growth anomaly: sd %.3f GtC/yr, lag-1 rho %+.3f (n=%d)\n",
            sd_o, rho_o, nrow(sp)))
# ⭐ The right scale is the DEFICIT's OWN year-to-year scatter, not the
# observation's: the deficit is a difference of two series that are only partly
# correlated, so it has a distribution of its own.
sd_d  <- stats::sd(d$dg); rho_d <- stats::acf(d$dg, plot = FALSE, lag.max = 1)$acf[2]
# ⚠ AUTOCORRELATION SHRINKS THE EFFECTIVE SAMPLE. n_eff = n (1-rho)/(1+rho) for
# an AR(1); applied whenever rho is material, so sqrt(n) is never assumed.
neff <- function(n, rho) if (rho <= 0) n else n * (1 - rho) / (1 + rho)
cat(sprintf("    the DEFICIT's own scatter:           sd %.3f GtC/yr, lag-1 rho %+.3f\n",
            sd_d, rho_d))
for (w in list(GD_LATE, GD_RECENT)) {
  k <- win(w); n <- sum(k); ne <- neff(n, rho_d)
  cat(sprintf("    %d-%d  deficit %+.2f = %.1f sd of a SINGLE year; %.1f se of the mean (n=%d, n_eff=%.1f)\n",
              w[1], w[2], mean(d$dg[k]), abs(mean(d$dg[k])) / sd_d,
              abs(mean(d$dg[k])) / (sd_d / sqrt(ne)), n, ne))
}
cat("    ⛔ READ THIS BEFORE THE REST. A window mean that is ~2 se from zero is a\n")
cat("       WEAK signal, and the frequency split below is a decomposition of it,\n")
cat("       not a confirmation that it is real.\n")

cat(sprintf("\n[4] WHERE THE DEFICIT SITS IN FREQUENCY (GATE V's own estimator, df=%d)\n",
            DG_V_DF))
cat(sprintf("  %-13s %9s | %9s %9s\n", "window", "deficit", "DECADAL", "interann"))
for (w in list(DG_V_WIN, GD_LATE, GD_RECENT)) {
  k <- swin(w); if (!any(k)) next
  cat(sprintf("  %-13s %+9.2f | %+9.2f %+9.2f\n", sprintf("%d-%d", w[1], w[2]),
              mean(sp$d_smooth[k] + sp$d_anom[k]), mean(sp$d_smooth[k]), mean(sp$d_anom[k])))
}
cat("\n  by decade:\n")
for (y0 in GD_DECADES) {
  k <- sp$year >= y0 & sp$year <= y0 + 9
  if (any(k)) cat(sprintf("  %d-%d     %+9.2f | %+9.2f %+9.2f\n", y0, min(y0 + 9, max(sp$year)),
                          mean(sp$d_smooth[k] + sp$d_anom[k]), mean(sp$d_smooth[k]),
                          mean(sp$d_anom[k])))
}

# ---- [4b] the DECADAL part is NOT all airborne fraction --------------
# ⛔ The model and GCB do NOT burn the same emissions (`luc_scale` = 0.8214), so
# the smooth term S = AF(y) x emissions mixes two different things:
#   S_m - S_o = (AF_m - AF_o) x em_o     <- a real airborne-fraction difference
#              + AF_m x (em_m - em_o)    <- merely the emissions INPUT differing
# Separated, because attributing an input difference to the model's physics is
# the same error class as scoring a scaled run against an unscaled flux.
sp$em_m <- d$e_m[match(sp$year, d$year)]; sp$em_o <- d$e_o[match(sp$year, d$year)]
sp$af_m <- sp$s_m / sp$em_m;              sp$af_o <- sp$s_o / sp$em_o
sp$d_af   <- (sp$af_m - sp$af_o) * sp$em_o
sp$d_emis <- sp$af_m * (sp$em_m - sp$em_o)
if (max(abs((sp$d_af + sp$d_emis) - sp$d_smooth)) > 1e-9)
  stop("GATE: the AF/emissions split does not reconstruct the DECADAL term. ",
       "Do not read [4b] -- an input difference would be attributed to physics.")
cat("\n[4b] SPLITTING THE DECADAL TERM: airborne fraction vs the emissions INPUT\n")
cat(sprintf("  %-13s %9s | %9s %9s | %8s %8s\n", "window", "DECADAL",
            "AF diff", "emis in", "AF mdl", "AF obs"))
for (w in list(DG_V_WIN, GD_LATE, GD_RECENT)) {
  k <- swin(w); if (!any(k)) next
  cat(sprintf("  %-13s %+9.2f | %+9.2f %+9.2f | %8.3f %8.3f\n", sprintf("%d-%d", w[1], w[2]),
              mean(sp$d_smooth[k]), mean(sp$d_af[k]), mean(sp$d_emis[k]),
              mean(sp$af_m[k]), mean(sp$af_o[k])))
}
cat("    ⚠ `emis in` is the FITTED luc_scale showing up, not a physics difference.\n")

# ---- [5] CAN the amplitude shortfall PRODUCE these window means? -----
# The arithmetic: if the model tracked the observed anomaly at a gain beta,
# its window bias would be (beta - 1) x (that window's MEAN OBSERVED ANOMALY).
# beta is measured, not assumed.
bfit <- stats::lm(e_m ~ 0 + e_o, data = sp)
beta <- unname(coef(bfit)[1]); bci <- stats::confint(bfit)[1, ]
cat(sprintf("\n[5] CAN A %.0f %% AMPLITUDE SHORTFALL PRODUCE THEM?\n", 100 * (1 - beta)))
cat(sprintf("    measured gain of model anomaly on observed: beta = %.3f (95%% CI %.3f..%.3f), r = %+.2f\n",
            beta, bci[1], bci[2], stats::cor(sp$e_m, sp$e_o)))
cat(sprintf("    sd(obs anomaly) %.3f, sd(model anomaly) %.3f, ratio %.2f\n",
            stats::sd(sp$e_o), stats::sd(sp$e_m), stats::sd(sp$e_m) / stats::sd(sp$e_o)))
cat(sprintf("\n  %-13s %10s %10s %10s\n", "window", "mean e_o", "PREDICTED", "ACTUAL"))
for (w in list(GD_LATE, GD_RECENT)) {
  k <- swin(w); if (!any(k)) next
  cat(sprintf("  %-13s %10.2f %10.2f %10.2f\n", sprintf("%d-%d", w[1], w[2]),
              mean(sp$e_o[k]), (beta - 1) * mean(sp$e_o[k]), mean(sp$d_anom[k])))
}
cat("    ⇒ PREDICTED is what a pure gain shortfall could manufacture; ACTUAL is the\n")
cat("      interannual part measured. The DECADAL column of [4] is what is left over.\n")

# ---- [6] the smoothing choice must not carry the verdict -------------
cat(sprintf("\n[6] DOES THE SPLIT SURVIVE THE SMOOTHING CHOICE? (walking DG_V_DF over %d-%d)\n",
            min(GD_DF_WALK), max(GD_DF_WALK)))
cat(sprintf("  %3s %9s %9s | %9s %9s\n", "df", "dec late", "ann late", "dec recent", "ann recent"))
for (df in GD_DF_WALK) {
  q <- split_at(df); q$ds <- q$s_m - q$s_o; q$da <- q$e_m - q$e_o
  kl <- q$year >= GD_LATE[1] & q$year <= GD_LATE[2]
  kr <- q$year >= GD_RECENT[1] & q$year <= GD_RECENT[2]
  cat(sprintf("  %3d %+9.2f %+9.2f | %+9.2f %+9.2f\n", df,
              mean(q$ds[kl]), mean(q$da[kl]),
              if (any(kr)) mean(q$ds[kr]) else NA, if (any(kr)) mean(q$da[kr]) else NA))
}

cat(sprintf("\n%s\n", strrep("=", 72)))
