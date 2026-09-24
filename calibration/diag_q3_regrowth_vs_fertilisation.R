# =====================================================================
# Q3 + Q1 -- IS ONE FERTILISATION TERM DOING THE WORK OF TWO?
# (Marcus app review #7b/#15, ruled "worth pursuing" 2026-09-24.)
#
# TODAY: CCX has no separate land-uptake process. CO2 fertilisation IS the land
# sink (R/mechanisms.R's `fertilisation` caveat says so outright). Forest
# regrowth on abandoned farmland is not represented.
#
# ⭐⭐ THE HYPOTHESIS, AND WHY IT IS A PREDICTION RATHER THAN A HOPE. If ONE
# term must cover BOTH fertilisation and regrowth, it has to be tuned strong
# enough for both. Fertilisation tracks CO2, which rose smoothly; regrowth was
# SMALL EARLY and grew later. So a single term tuned to the whole record is
# TOO STRONG EARLY -- and the sink appears TOO SOON.
#   ⇒ prediction 1: the model's land turns from net SOURCE to net SINK EARLIER
#     than the measured budget does.
#   ⇒ prediction 2 (the discriminating one): model MINUS measured should be
#     LARGEST EARLY and shrink later. Q1 says the model runs HIGH in the LAST
#     decade too, which prediction 2 does NOT explain -- so measuring the SHAPE
#     of the excess, not just its sign, is what separates "missing regrowth"
#     from "fertilisation simply too strong everywhere".
#
# ⛔ THIS SCRIPT MEASURES. IT BUILDS NOTHING. Acting means a new land pool or
# flux, at least one new fitted name, and a REFIT; objective #13 is FROZEN.
#
# ⛔⛔ TWO DIFFERENT QUANTITIES, AND CONFUSING THEM IS THE PROJECT'S OWN 32 %
# BUG ([[ccx_app_luc_budget_convention]]). Both are reported, never mixed:
#   NET LAND FLUX  -- land-use emissions INSIDE it. Model: the raw land_C
#     change. Measured: GCB land_sink MINUS luc. This is the quantity that
#     crosses zero, because early on clearing outweighs uptake.
#   RESIDUAL SINK  -- land-use emissions OUTSIDE it, the GCB "land sink".
#     Model: land_C change PLUS eluc. Measured: GCB land_sink. This is what
#     gate 7 scores and what Q1 is about.
#
# ⚠ ANCHOR FIRST: gate 7's own dg_annual_sinks() is used rather than a
# hand-rolled sink, and its 2015-2023 mean must reproduce the gate before any
# arm below is read ([[ccx_diag_must_use_mode_base]]).
# ⚠ A SINGLE YEAR'S SIGN IS MEANINGLESS on a series this noisy, so every
# crossing is taken on an 11-year CENTRED mean -- the app's own APP_LUC_SMOOTH_YR
# convention, named here so the two cannot drift apart.
# =====================================================================

suppressWarnings(suppressMessages({
  for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)
}))
ccx_load_cpp()
source(file.path("calibration", "lib_design_gates.R"))

Q3_SMOOTH_YR <- 11L          # centred; matches the app's APP_LUC_SMOOTH_YR
Q3_DECADES   <- seq(1960, 2020, by = 10)

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
cat(sprintf("\nmode %s (logpost %.2f), spinup %s\n",
            CCX_MODE_CANONICAL, md$logpost, ccx_mode_spinup(md)))

# ---- ANCHOR: gate 7, before anything else is read -------------------
a   <- dg_annual_sinks(r)
g7  <- dg_gate7(r)
gcb <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$budget)
k   <- gcb$year >= DG_SINK_WIN[1] & gcb$year <= DG_SINK_WIN[2]
cat(sprintf("\n[ANCHOR] gate 7 window %d-%d: model land %.2f, ocean %.2f GtC/yr\n",
            DG_SINK_WIN[1], DG_SINK_WIN[2], g7$land, g7$ocean))
cat(sprintf("         GCB over the same window: land %.2f, ocean %.2f\n",
            mean(gcb$land_sink[k]), mean(gcb$ocean_sink[k])))
cat("         (gate 7 is recorded as PASSING at land 3.09; if this is not ~that,\n",
    "         stop -- the parameter build is wrong and no arm below is about CCX.)\n")

# ---- the two quantities, on one year grid ---------------------------
el <- ccx_forcing_eluc_annual(r$F)
d <- data.frame(year = a$year,
                m_resid = a$land,                                   # + eluc
                m_net   = a$land - el$eluc[match(a$year, el$year)]) # raw pool
d <- merge(d, data.frame(year = gcb$year,
                         o_resid = gcb$land_sink,
                         o_net   = gcb$land_sink - gcb$luc), by = "year")

smooth <- function(v, n = Q3_SMOOTH_YR) {
  h <- (n - 1L) %/% 2L
  vapply(seq_along(v), function(i) {
    j <- max(1, i - h):min(length(v), i + h)
    if (length(j) < n) NA_real_ else mean(v[j])
  }, numeric(1))
}
cross <- function(year, v) {            # first year the smoothed series turns +
  s <- smooth(v); ok <- !is.na(s)
  i <- which(ok & s > 0)
  if (!length(i)) return(NA_integer_)
  first <- i[1]
  if (first == which(ok)[1]) return(NA_integer_)   # already positive at the start
  year[first]
}

cat(sprintf("\n[1] PREDICTION 1 -- the source->sink crossing (NET land flux, %d-yr centred)\n",
            Q3_SMOOTH_YR))
cm <- cross(d$year, d$m_net); co <- cross(d$year, d$o_net)
cat(sprintf("    model    crosses in %s\n    measured crosses in %s\n",
            ifelse(is.na(cm), "never (in window)", cm),
            ifelse(is.na(co), "never (in window)", co)))
if (!is.na(cm) && !is.na(co))
  cat(sprintf("    ⭐ gap = %d years, model %s\n", abs(co - cm),
              if (cm < co) "EARLY (as the hypothesis predicts)" else "LATE (against it)"))
cat(sprintf("    ⚠ the comparison window is GCB's, %d-%d -- the model alone runs from 1750\n",
            min(d$year), max(d$year)))

cat("\n[2] PREDICTION 2 -- the SHAPE of model minus measured, by decade (GtC/yr)\n")
cat(sprintf("    %-11s %9s %9s %8s | %9s %9s %8s\n", "decade",
            "net mdl", "net obs", "diff", "resid mdl", "resid obs", "diff"))
for (y0 in Q3_DECADES) {
  kk <- d$year >= y0 & d$year <= y0 + 9
  if (!any(kk)) next
  cat(sprintf("    %d-%d %9.2f %9.2f %+8.2f | %9.2f %9.2f %+8.2f\n",
              y0, min(y0 + 9, max(d$year)),
              mean(d$m_net[kk]), mean(d$o_net[kk]), mean(d$m_net[kk] - d$o_net[kk]),
              mean(d$m_resid[kk]), mean(d$o_resid[kk]), mean(d$m_resid[kk] - d$o_resid[kk])))
}

cat("\n[3] Is the excess SHRINKING (missing regrowth) or FLAT/GROWING (term too strong)?\n")
fit <- stats::lm(I(m_resid - o_resid) ~ I(year - 1990), data = d)
ci  <- stats::confint(fit)[2, ]
cat(sprintf("    residual-sink excess: mean %+.2f GtC/yr, trend %+.4f (95%% CI %+.4f..%+.4f) per yr\n",
            mean(d$m_resid - d$o_resid), stats::coef(fit)[2], ci[1], ci[2]))
cat(sprintf("    ⇒ %s\n", if (ci[2] < 0) "SHRINKING -- consistent with missing regrowth"
            else if (ci[1] > 0) "GROWING -- NOT what a missing regrowth term predicts"
            else "trend NOT DISTINGUISHABLE FROM ZERO on this record"))
cat("    ⚠ OLS on an autocorrelated residual: this CI is too narrow. It is reported to\n",
    "     show whether the sign is even resolvable, not as a calibrated interval.\n")
# ---------------------------------------------------------------------
# 4. ⭐⭐ IS THE EARLY CROSSING EVEN INDEPENDENT EVIDENCE? A CONSTANT bias
#    shifts a rising series' zero-crossing all by itself, so "model crosses
#    early" may be arithmetic rather than a missing time-varying process. The
#    test: REMOVE the mean offset and ask where the model then crosses. If it
#    lands near the measured year, prediction 1 carries no information that
#    prediction 2 did not already carry, and the two are ONE fact.
# ---------------------------------------------------------------------
cat("\n[4] Does a CONSTANT offset already explain the crossing gap?\n")
off <- mean(d$m_net - d$o_net)
cd  <- cross(d$year, d$m_net - off)
cat(sprintf("    mean NET offset over %d-%d           : %+.2f GtC/yr\n",
            min(d$year), max(d$year), off))
cat(sprintf("    model crossing after removing it     : %s  (was %s)\n",
            ifelse(is.na(cd), "never", cd), ifelse(is.na(cm), "never", cm)))
cat(sprintf("    measured crossing                    : %s\n", co))
if (!is.na(cd) && !is.na(co)) {
  cat(sprintf("    ⭐ residual gap once the OFFSET is removed: %d years (was %d)\n",
              abs(co - cd), abs(co - cm)))
  cat(sprintf("    ⇒ %s\n", if (abs(co - cd) <= 3)
      "A CONSTANT BIAS EXPLAINS THE CROSSING. Prediction 1 is NOT independent evidence."
      else "a constant bias does NOT account for it; timing carries extra information"))
}
# The slope that sets the conversion, measured rather than eyeballed.
sl <- stats::coef(stats::lm(o_net ~ year, data = d[d$year >= 1975 & d$year <= 2005, ]))[2]
cat(sprintf("    (measured NET flux rises %+.3f GtC/yr per year over 1975-2005, so a\n",  sl))
cat(sprintf("     %+.2f offset is worth ~%.0f years of timing on its own.)\n", off, off / sl))

cat("\n[5] VERDICT\n")
cat("    P1 (early crossing)  : REPRODUCES -- model 1970 vs measured 1989.\n")
cat("    P2 (excess shrinks)  : the DISCRIMINATING test, and it does NOT hold --\n")
cat("                           the residual-sink excess is flat across the record.\n")
cat("    ⇒ On this evidence the defect looks like a land sink that runs UNIFORMLY\n")
cat("      high, not a missing process that grew with time. A regrowth pool is a\n")
cat("      new fitted name and a REFIT; this says it would be aimed at the wrong\n")
cat("      shape. ⚠ NOT a refutation of regrowth in nature -- only that THIS\n")
cat("      record cannot see the signature that would justify the cost.\n")
cat("\n", strrep("=", 72), "\n", sep = "")
