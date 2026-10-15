# =====================================================================
# THE LAND-SINK BIAS -- IS IT A MODEL DEFECT, A SPLIT ERROR, OR GCB's OWN SLACK?
# (Follows handoff 2026-09-24 (d) §2. Q3's regrowth hypothesis died on its
#  discriminating test; what survived is a land sink running ~+0.3 GtC/yr high
#  across the whole record. THIS asks what that number is measured AGAINST.)
#
# ⭐⭐ THE METHOD IS AN IDENTITY, NOT A COMPARISON. Both budgets close, so the
# land difference is not a free-floating "bias" -- it is the exact sum of the
# differences in every OTHER term. Model conservation is exact by construction:
#
#     E_foss + E_luc  =  G + S_land(resid) + S_ocean                    (model)
#     E_foss + E_luc  =  G + S_land + S_ocean + cement + IMBALANCE      (GCB)
#
# Subtract, and the quantity the handoff calls the bias decomposes with NO
# residual of its own:
#
#     S_land(mdl) - S_land(GCB)
#        = dE_foss + dE_luc - dG - dS_ocean + cement(GCB) + IMBALANCE(GCB) + num
#
# ⇒ every arm below is one term of that sum. The sum is GATED to close.
#
# ⚠ `num` IS CARRIED, NOT HIDDEN IN A TOLERANCE. The model's own budget closes
# to ~1e-6 GtC/yr in the 1750s and drifts to ~0.03 by 2021 -- PROPORTIONAL to
# the flux, i.e. a discretization term, not a leak (the state has no fourth
# reservoir: ccx_core.cpp sums all four land pools into `land_C` and mixed
# layer + interior into `ocean_C`, and the atmosphere is the rest). It arises
# because dg_annual_sinks() interpolates MONTHLY-sampled stocks to January-1
# boundaries while the emissions are calendar-year means. Rather than widen a
# tolerance until the identity "closes", the term is printed in its own column
# and GATED against the quantity under test ([[tolerance_scaled_to_spread]]).
# ⚠ 1750 carries a much larger 0.37 -- the START-boundary linear extrapolation
# in stock(). It is outside this script's window (GCB starts 1959) and is not
# relied on anywhere below.
#
# ⛔⛔ TWO QUANTITIES, NEVER MIXED (the project's own 32 % bug,
# [[ccx_app_luc_budget_convention]]). This script is entirely in the RESIDUAL
# SINK convention -- land-use emissions OUTSIDE the sink -- because that is the
# convention the identity above is written in, the one gate 7 scores, and the
# one Q1 is about. The NET land flux (LUC inside) is what crosses zero and is
# NOT used here. `diag_q3_regrowth_vs_fertilisation.R` reports both.
#
# ⚠ ANCHOR FIRST: gate 7's own dg_annual_sinks() / dg_gate7(), and the recorded
# land 3.09 must reproduce before any arm is read ([[ccx_diag_must_use_mode_base]]).
# =====================================================================

suppressWarnings(suppressMessages({
  for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)
}))
ccx_load_cpp()
source(file.path("calibration", "lib_design_gates.R"))

# ---- named constants; every label below derives from these ----------
LB_DECADES    <- seq(1960, 2020, by = 10)
LB_G7_RECORD  <- 3.09          # gate 7's RECORDED model land sink, the anchor
LB_G7_TOL     <- 0.02          # anchor tolerance, GtC/yr
LB_CLOSE_TOL  <- 1e-9          # GtC/yr; GCB's OWN identity is arithmetic and must close exactly
LB_NUM_FRAC   <- 0.10          # the numerical term may not exceed this FRACTION of the
                               # mean land excess -- a tolerance derived from the
                               # quantity it guards, never a hand-picked absolute
LB_EARLY      <- c(1959, 1989) # "early record" = start .. the measured crossing
LB_LATE       <- c(2015, 2023) # = DG_SINK_WIN, gate 7's own window
LB_RECENT     <- c(2020, 2024) # the flagged-not-interpreted tail
LB_CONVENTION <- "RESIDUAL SINK (land-use emissions OUTSIDE the sink)"

cat(sprintf("\n%s\nLAND-SINK BIAS: what is it measured against?\nconvention: %s\n%s\n",
            strrep("=", 72), LB_CONVENTION, strrep("=", 72)))

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

# ---- ANCHOR ---------------------------------------------------------
a   <- dg_annual_sinks(r)
g7  <- dg_gate7(r)
gcb <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$budget)
cat(sprintf("\n[ANCHOR] gate 7 %d-%d: model land %.2f, ocean %.2f GtC/yr (recorded land %.2f)\n",
            DG_SINK_WIN[1], DG_SINK_WIN[2], g7$land, g7$ocean, LB_G7_RECORD))
if (abs(g7$land - LB_G7_RECORD) > LB_G7_TOL)
  stop(sprintf("ANCHOR FAILED: model land %.3f vs recorded %.2f (tol %.2f). ",
               g7$land, LB_G7_RECORD, LB_G7_TOL),
       "The parameter build is wrong and nothing below is about CCX.")
cat("         anchor OK.\n")

# ---- the model's OWN emissions, read off the forcing it actually burned ----
# ⚠ NOT re-read from GCB: `luc_scale` is a FITTED name, so the model's E_luc is
# not GCB's, and scoring a scaled run against an unscaled flux is the trap
# ccx_forcing_eluc_annual()'s own docstring warns about.
el   <- ccx_forcing_eluc_annual(r$F)
foss <- stats::aggregate(list(efoss = r$F$e_foss_NH + r$F$e_foss_SH),
                         by = list(year = r$F$year), FUN = mean)

d <- data.frame(year = a$year, m_land = a$land, m_ocean = a$ocean,
                m_growth = a$growth_ppm * ccx_const("GtC_PER_PPM"))
d <- merge(d, el, by = "year"); d <- merge(d, foss, by = "year")
d <- merge(d, gcb, by = "year")

# ---- GATE A: how far is the MODEL's budget from closing? ------------
# Measured and carried as `num` below; gated in GATE C against the land excess.
d$close <- d$efoss + d$eluc - d$m_growth - d$m_land - d$m_ocean
# ⇒ S_land(mdl) = E - G - S_ocean - close, so the term that enters the
#   decomposition of (model MINUS GCB) is MINUS the conservation residual.
d$num <- -d$close
cat(sprintf("\n[GATE A] model conservation residual over %d-%d: mean %+.4f, max |.| %.4f GtC/yr\n",
            min(d$year), max(d$year), mean(d$close), max(abs(d$close))))

# ---- GATE B: is GCB's land sink a RESIDUAL, or is the IMBALANCE one? ----
# ⭐ The handoff's §2 step 1 assumed GCB's land sink "absorbs the budget
# imbalance". If that were so, `imbalance` could not be an independent column
# with a nonzero value. Tested rather than assumed.
d$g_close <- d$fossil + d$luc - d$atm_growth - d$ocean_sink - d$land_sink -
             d$cement_carbonation - d$imbalance
cat(sprintf("[GATE B] GCB identity  F+L-G-O-Land-cement-imbalance: max |.| = %.2e GtC/yr (tol %.0e)\n",
            max(abs(d$g_close)), LB_CLOSE_TOL))
if (max(abs(d$g_close)) > LB_CLOSE_TOL)
  stop("GCB's stated identity does not close in the shipped data; ",
       "the convention assumed here is wrong.")
cat("         ⇒ the IMBALANCE is the residual. GCB's land sink is an INDEPENDENT\n")
cat("           estimate (DGVM ensemble), so it carries its own error, and the\n")
cat("           imbalance is carbon the published budget CANNOT place.\n")

# ---- the decomposition ----------------------------------------------
d$d_land  <- d$m_land   - d$land_sink       # the quantity under investigation
d$d_ocean <- d$m_ocean  - d$ocean_sink
d$d_grow  <- d$m_growth - d$atm_growth
d$d_foss  <- d$efoss    - d$fossil
d$d_luc   <- d$eluc     - d$luc
d$recon   <- d$d_foss + d$d_luc - d$d_grow - d$d_ocean +
             d$cement_carbonation + d$imbalance + d$num

cat(sprintf("\n[GATE C] decomposition closes: max |dLand - sum(terms)| = %.2e GtC/yr (tol %.0e)\n",
            max(abs(d$d_land - d$recon)), LB_CLOSE_TOL))
if (max(abs(d$d_land - d$recon)) > LB_CLOSE_TOL)
  stop("the identity decomposition does not close; do not read the table below.")
cat(sprintf("         numerical term %+.4f GtC/yr = %.1f %% of the %+.2f land excess (cap %.1f %%)\n",
            mean(d$num), 100 * abs(mean(d$num) / mean(d$d_land)), mean(d$d_land),
            100 * LB_NUM_FRAC))
if (abs(mean(d$num)) > LB_NUM_FRAC * abs(mean(d$d_land)))
  stop("the discretisation term is not small against the excess it would explain; ",
       "refine dg_annual_sinks() before reading this decomposition.")

win <- function(w) d$year >= w[1] & d$year <= w[2]
row <- function(lab, k) cat(sprintf(
  "  %-13s %+7.2f | %+7.2f %+7.2f %+7.2f %+7.2f %+7.2f %+7.2f %+7.3f\n", lab,
  mean(d$d_land[k]), mean(d$d_foss[k]), mean(d$d_luc[k]), mean(-d$d_grow[k]),
  mean(-d$d_ocean[k]), mean(d$cement_carbonation[k]), mean(d$imbalance[k]),
  mean(d$num[k])))

cat(sprintf("\n[1] WHERE THE LAND EXCESS COMES FROM -- an exact identity, GtC/yr\n"))
cat("    (model minus GCB; the six terms on the right SUM to the left)\n\n")
cat(sprintf("  %-13s %7s | %7s %7s %7s %7s %7s %7s %7s\n", "window", "dLAND",
            "dFoss", "dLuc", "-dGrow", "-dOcn", "cement", "IMBAL", "num"))
row(sprintf("%d-%d", min(d$year), max(d$year)), rep(TRUE, nrow(d)))
row(sprintf("%d-%d", LB_EARLY[1], LB_EARLY[2]), win(LB_EARLY))
row(sprintf("%d-%d", LB_LATE[1],  LB_LATE[2]),  win(LB_LATE))
row(sprintf("%d-%d", LB_RECENT[1], LB_RECENT[2]), win(LB_RECENT))
cat("\n  by decade:\n")
for (y0 in LB_DECADES) {
  k <- d$year >= y0 & d$year <= y0 + 9
  if (any(k)) row(sprintf("%d-%d", y0, min(y0 + 9, max(d$year))), k)
}

# ---- [2] the observational error bar the handoff asked for ----------
cat(sprintf("\n[2] IS +%.2f INSIDE GCB's OWN SLACK, AND ON WHICH SIDE?\n",
            mean(d$d_land)))
cat(sprintf("    mean land excess        %+.2f GtC/yr\n", mean(d$d_land)))
cat(sprintf("    mean GCB imbalance      %+.2f GtC/yr  (%d-%d)\n",
            mean(d$imbalance), min(d$year), max(d$year)))
cat(sprintf("    early-record imbalance  %+.2f GtC/yr  (%d-%d)\n",
            mean(d$imbalance[win(LB_EARLY)]), LB_EARLY[1], LB_EARLY[2]))
cat(sprintf("    ⇒ the excess is %.0f %% of the mean imbalance, and they have the %s sign.\n",
            100 * mean(d$d_land) / mean(d$imbalance),
            if (sign(mean(d$d_land)) == sign(mean(d$imbalance))) "SAME" else "OPPOSITE"))
cat("    ⚠ SIGN IS THE WHOLE POINT. A POSITIVE imbalance means GCB's sources exceed\n")
cat("      everything it can place: its identified sinks are collectively TOO SMALL\n")
cat("      to close its own budget. A model sink LARGER than GCB's therefore moves\n")
cat("      TOWARD closure, not away from it.\n")

# ---- [3] is the TOTAL right and only the SPLIT wrong? ---------------
cat("\n[3] TOTAL UPTAKE vs THE SPLIT\n")
tot_m <- d$m_land + d$m_ocean
tot_g <- d$land_sink + d$ocean_sink
cat(sprintf("  %-13s %8s %8s %8s | %8s %8s\n", "window",
            "tot mdl", "tot GCB", "diff", "dLand", "dOcean"))
for (w in list(c(min(d$year), max(d$year)), LB_EARLY, LB_LATE, LB_RECENT)) {
  k <- win(w)
  cat(sprintf("  %-13s %8.2f %8.2f %+8.2f | %+8.2f %+8.2f\n",
              sprintf("%d-%d", w[1], w[2]), mean(tot_m[k]), mean(tot_g[k]),
              mean(tot_m[k] - tot_g[k]), mean(d$d_land[k]), mean(d$d_ocean[k])))
}
cat(sprintf("\n    partition, model  : land %.1f %% of total uptake (%d-%d)\n",
            100 * mean(d$m_land[win(LB_LATE)]) / mean(tot_m[win(LB_LATE)]),
            LB_LATE[1], LB_LATE[2]))
cat(sprintf("    partition, GCB    : land %.1f %% of total uptake (same window)\n",
            100 * mean(d$land_sink[win(LB_LATE)]) / mean(tot_g[win(LB_LATE)])))

# ---- [4] does the model reproduce OBSERVED atmospheric growth? ------
# ⭐ The handoff's step 2: if growth is reproduced, the TOTAL is pinned by the
# emissions input and only the SPLIT can be wrong. Measured, not assumed.
cat("\n[4] ATMOSPHERIC GROWTH -- the term that pins the total\n")
cat(sprintf("  %-13s %9s %9s %8s\n", "window", "mdl", "GCB obs", "diff"))
for (w in list(c(min(d$year), max(d$year)), LB_EARLY, LB_LATE, LB_RECENT)) {
  k <- win(w)
  cat(sprintf("  %-13s %9.2f %9.2f %+8.2f\n", sprintf("%d-%d", w[1], w[2]),
              mean(d$m_growth[k]), mean(d$atm_growth[k]), mean(d$d_grow[k])))
}
gf <- stats::lm(d_grow ~ I(year - 1990), data = d)
cat(sprintf("    growth difference: mean %+.3f GtC/yr, trend %+.4f (95%% CI %+.4f..%+.4f)/yr\n",
            mean(d$d_grow), stats::coef(gf)[2],
            stats::confint(gf)[2, 1], stats::confint(gf)[2, 2]))
cat("    ⚠ OLS on an autocorrelated residual: the CI is too narrow, and is read for\n")
cat("      whether the SIGN resolves, not as a calibrated interval.\n")
cat("\n  growth difference by decade (model minus GCB observed, GtC/yr):\n")
for (y0 in LB_DECADES) {
  k <- d$year >= y0 & d$year <= y0 + 9
  if (any(k)) cat(sprintf("    %d-%d %+8.2f\n", y0, min(y0 + 9, max(d$year)),
                          mean(d$d_grow[k])))
}

# ---- [4b] the recent window, YEAR BY YEAR ---------------------------
# ⚠ The handoff flags 2020-2024 as GCB's least-constrained years and says
# FLAGGED, NOT INTERPRETED. A window mean can be one year wearing a disguise,
# so the years are shown rather than summarized.
cat(sprintf("\n[4b] THE RECENT WINDOW YEAR BY YEAR -- is it a signal or one year?\n"))
cat(sprintf("  %6s %8s %8s %8s %8s %8s\n", "year", "G mdl", "G obs", "dGrow", "dLand", "IMBAL"))
for (y in seq(max(d$year) - 9, max(d$year))) {
  i <- which(d$year == y); if (!length(i)) next
  cat(sprintf("  %6d %8.2f %8.2f %+8.2f %+8.2f %+8.2f\n", y, d$m_growth[i],
              d$atm_growth[i], d$d_grow[i], d$d_land[i], d$imbalance[i]))
}

# ---- [6] does the growth miss ACCUMULATE into a level drift? --------
# ⭐ A flux difference of 0.45 GtC/yr is only meaningful once integrated: the
# question a CO2 record can answer is whether the LEVEL has gone wrong. The
# ABSOLUTE level is a separate, already-known disagreement ([[ccx_co2_level]]);
# what is measured here is the DRIFT this budget implies, which is independent
# of any starting offset.
cat("\n[6] DOES THE GROWTH MISS ACCUMULATE? (cumulative, ppm, anchored at the window start)\n")
d$cum_ppm <- cumsum(d$d_grow) / ccx_const("GtC_PER_PPM")
# ⚠ co2_global is NOT a column of every run ([[ccx_co2_global_not_a_column]]);
# derived the same way dg_annual_sinks() derives its growth, so the two cannot drift.
co2g <- stats::aggregate(list(co2 = (r$out$co2_NH + r$out$co2_SH) / 2),
                         by = list(year = floor(r$out$t + 1e-9)), FUN = mean)
d <- merge(d, co2g, by = "year")
cat(sprintf("  %6s %12s %12s\n", "year", "cum drift", "mdl CO2"))
for (y in c(1970, 1980, 1990, 2000, 2010, 2015, 2020, max(d$year))) {
  i <- which(d$year == y); if (!length(i)) next
  cat(sprintf("  %6d %+12.2f %12.1f\n", y, d$cum_ppm[i], d$co2[i]))
}
cat(sprintf("    ⇒ over %d-%d the model accumulates %+.2f ppm of drift against the\n",
            min(d$year), max(d$year), d$cum_ppm[nrow(d)]))
cat(sprintf("      observed growth, of which %+.2f ppm arrives after %d.\n",
            d$cum_ppm[nrow(d)] - d$cum_ppm[which(d$year == 2014)], 2014))

# ---- [5] the emissions input, which is NOT GCB's ---------------------
cat("\n[5] THE EMISSIONS THE MODEL ACTUALLY BURNED vs GCB's\n")
cat(sprintf("  %-13s %8s %8s %8s | %8s %8s %8s\n", "window",
            "foss m", "foss g", "diff", "luc m", "luc g", "diff"))
for (w in list(c(min(d$year), max(d$year)), LB_EARLY, LB_LATE)) {
  k <- win(w)
  cat(sprintf("  %-13s %8.2f %8.2f %+8.2f | %8.2f %8.2f %+8.2f\n",
              sprintf("%d-%d", w[1], w[2]), mean(d$efoss[k]), mean(d$fossil[k]),
              mean(d$d_foss[k]), mean(d$eluc[k]), mean(d$luc[k]), mean(d$d_luc[k])))
}
cat(sprintf("    (luc_scale = %.4f; a fitted name, so E_luc is DELIBERATELY not GCB's)\n",
            pm$luc_scale))

# ---- [7] IS THE RECENT GROWTH MISS SECULAR, OR IS IT ENSO YEARS? ----
# ⭐ TWO HYPOTHESES, AND A TEST THAT SEPARATES THEM. [6] already shows the drift
# does NOT accumulate, which argues against a secular over-uptake. The competing
# reading is that the model mis-sizes the INTERANNUAL growth swing, which is an
# ENSO-amplitude question and a known open item (GATE V), not a level error.
# ⚠ Uses the objective's OWN annual index, ccx_enso_annual_index(), not a
# hand-rolled one, so this cannot disagree with the gate that scores it.
cat("\n[7] SECULAR BIAS, OR ENSO-YEAR AMPLITUDE?\n")
en <- ccx_enso_annual_index()
dz <- merge(d[, c("year", "d_grow", "d_land")], en, by = "year")
ef <- stats::lm(d_grow ~ year + nino34, data = dz)
ci <- stats::confint(ef)["nino34", ]
cat(sprintf("    growth difference on Nino3.4 (with a year term), %d-%d, n=%d:\n",
            min(dz$year), max(dz$year), nrow(dz)))
cat(sprintf("      slope %+.3f GtC/yr per index unit (95%% CI %+.3f..%+.3f), partial r = %+.2f\n",
            coef(ef)[["nino34"]], ci[1], ci[2],
            stats::cor(stats::residuals(stats::lm(d_grow ~ year, dz)), dz$nino34)))
cat(sprintf("    ⇒ %s\n", if (ci[1] > 0 || ci[2] < 0)
    "RESOLVED: the growth miss tracks ENSO -- an interannual AMPLITUDE question"
    else "NOT resolved on this record: ENSO does not explain the growth miss"))
# ⛔ A NULL IS WORTHLESS UNTIL ITS POWER IS MEASURED ([[no_power_null]]): a test
# that COULD NOT have seen the effect reports "no effect" identically to one
# that looked. So: what slope would ENSO need to produce the recent miss, and
# is that slope inside or outside the interval just measured?
mi <- mean(dz$nino34[dz$year >= LB_LATE[1] & dz$year <= LB_LATE[2]])
need <- mean(d$d_grow[win(LB_LATE)]) / mi
cat(sprintf("    POWER: mean Nino3.4 over %d-%d is %+.2f, so ENSO would need a slope of\n",
            LB_LATE[1], LB_LATE[2], mi))
cat(sprintf("      %+.2f GtC/yr per unit to produce the %+.2f miss -- against a measured\n",
            need, mean(d$d_grow[win(LB_LATE)])))
cat(sprintf("      95%% CI of %+.3f..%+.3f. That slope is %s the interval, so the null\n",
            ci[1], ci[2], if (need < ci[1] || need > ci[2]) "OUTSIDE" else "INSIDE"))
cat(sprintf("      %s\n", if (need < ci[1] || need > ci[2])
    "is INFORMATIVE: ENSO is excluded as the explanation, not merely unproven."
    else "is UNINFORMATIVE: this record cannot tell the two apart. Do not read it as a rejection."))
cat("\n    robustness of the recent window (a mean can be one year in disguise):\n")
for (w in list(LB_LATE, LB_RECENT)) {
  k <- win(w); v <- d$d_grow[k]
  cat(sprintf("      %d-%d  mean %+.2f   median %+.2f   worst year %d (%+.2f)\n",
              w[1], w[2], mean(v), stats::median(v),
              d$year[k][which.max(abs(v))], v[which.max(abs(v))]))
}
cat("    ⚠ GCB's own imbalance is at its RECORD |value| in the worst year; that year is\n")
cat("      the least-closed year of the published budget as well as the model's worst.\n")

cat(sprintf("\n%s\n", strrep("=", 72)))
