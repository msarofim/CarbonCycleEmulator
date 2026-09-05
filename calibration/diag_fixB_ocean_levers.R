# =====================================================================
# diag_fixB_ocean_levers.R -- FIX B: re-score the BUILT ocean structures
#   against the two observables that did not exist when the candidate
#   list in DESIGN sec.3.4a was scored.
#
# Pre-registered in notes/prereg_2026-09-04i_fixB_ocean_candidates.md,
# written before this file existed.
#
# ⭐ MEASURE THE LEVER BEFORE BUILDING THE MACHINERY. An ENSO-modulated
# upwelling term needs a forcing column, R and C++ twins, a parity test
# and an N_FORCING bump. A STATIC scan costs a minute and answers the
# same question -- the method that killed the conveyor on 2026-09-01.
# NOTHING IS IMPLEMENTED, FITTED OR ADOPTED HERE.
#
# ⚠ EVERY ROW IS A CONDITIONAL PRICE: the other 25 parameters are held at
# ent26 and nothing is re-optimised. A conditional price has been ~100 %
# wrong twice in this repo. A promising row licenses a re-optimised
# follow-up, never an adoption.
#
# Usage:  Rscript calibration/diag_fixB_ocean_levers.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))

FB_YEARS   <- DG_YEARS
FB_SINK_WIN <- c(2015, 2023)          # the gate-7 window, not a new one
# The levers, ALL ALREADY BUILT and defaulting to 0. `q_conv` is a CONTROL
# with a known answer (+0.0101 GtC/yr per Sv, 2026-09-01) -- if the harness
# does not reproduce its sign the harness is wrong.
FB_LEVERS <- list(
  w_up   = c(0, 0.5, 1, 2, 5),                  # m/yr
  w_out  = c(0, 0.5, 1, 2, 5),                  # m/yr, NH = SH
  q_conv = c(0, 5, 10, 20))                     # Sv  -- CONTROL
# The ENSO target and the solubility path's own slope, both MEASURED
# 2026-09-04g in diag_gateS_indep_and_fixB.R sec.B4. Carried as constants so
# this file never recomputes them under a different estimator.
FB_ENSO_OBS   <- 0.1153
FB_ENSO_OBS_SE<- 0.0246
FB_ENSO_SOLUB <- -0.1274              # model, patch OFF
FB_ENSO_NEED  <- FB_ENSO_OBS - FB_ENSO_SOLUB   # what a lever must supply
# GLODAP deep target, the row B1 and w_up already failed on.
# READ FROM THE LIKELIHOOD'S OWN ACCESSOR, not retyped -- this is the same
# target the objective scores, so a drift between them is impossible.
.fb_deep    <- ccx_deep_d14c_target()
FB_DEEP_OBS <- .fb_deep$target
FB_DEEP_SD  <- .fb_deep$sd

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
obs <- ccx_prepare_obs()
OH  <- dg_gateH_obs(obs)
en  <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds")))
en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
gcb <- obs$gcb

v0 <- dg_vector(CCX_MODE_CANONICAL)
cat(sprintf("mode %s | %d-%d | levers held against ent26, NOTHING re-optimised\n",
            basename(ccx_mode_file()), FB_YEARS[1], FB_YEARS[2]))

#' Every scored row at one parameter override, in ONE run
fb_row <- function(mods) {
  v <- v0; for (n in names(mods)) v$p[[n]] <- mods[[n]]
  r  <- dg_run(v)
  o  <- r$out
  ms <- ccx_model_stats(o, obs)
  # --- ocean sink over the gate-7 window, and its ENSO sensitivity ---
  yy <- floor(o$t)
  ag <- stats::aggregate(ocean_C ~ yy, data.frame(yy = yy, ocean_C = o$ocean_C), FUN = mean)
  sk <- data.frame(year = ag$yy[-1], sink = diff(ag$ocean_C))
  sink_win <- mean(sk$sink[sk$year >= FB_SINK_WIN[1] & sk$year <= FB_SINK_WIN[2]])
  m <- merge(sk, en_ann, by = "year")
  m <- m[m$year >= min(gcb$year) & m$year <= max(gcb$year), ]
  m <- m[stats::complete.cases(m), ]
  stopifnot(nrow(m) == length(unique(m$year)))
  enso_slope <- unname(coef(stats::lm(sink ~ year + nino34_anom, data = m))["nino34_anom"])
  # --- the d13C level bias at MLO, and GATE H ---
  k <- merge(data.frame(year = ms$d13$MLO$year, mod = ms$d13$MLO$level),
             data.frame(year = obs$d13_ann$MLO$year, ob = obs$d13_ann$MLO$level), by = "year")
  d13_bias <- mean(k$mod - k$ob)
  gh <- dg_gateH(v, obs, OH); vh <- dg_gateH_verdict(gh, OH)
  # --- the GUARD row: deep ocean D14C ---
  deep <- r$sp$diagnostics$d14c_bottom_box
  list(sink = sink_win, enso = enso_slope, d13 = d13_bias,
       contrast = vh$d, zH = vh$z, deep = deep,
       z_deep = (deep - FB_DEEP_OBS) / FB_DEEP_SD)
}

base <- fb_row(list())
cat(sprintf("\nBASE (ent26): sink %.3f | ENSO slope %+.4f | d13C bias %+.4f | gate-H %+.3f (z %+.2f) | deep D14C %.1f (z %+.2f)\n",
            base$sink, base$enso, base$d13, base$contrast, base$zH, base$deep, base$z_deep))
cat(sprintf("  GLODAP deep target %.1f +- %.1f permil\n", FB_DEEP_OBS, FB_DEEP_SD))

R <- list()
for (lv in names(FB_LEVERS)) {
  sep(sprintf("LEVER: %s%s", lv, if (lv == "q_conv") "   [CONTROL -- known answer]" else ""))
  cat(sprintf("  %8s %9s %11s %11s %11s %11s %9s\n",
              lv, "sink", "ENSO slope", "d13C bias", "gate-H d", "deep D14C", "z deep"))
  rows <- list()
  for (x in FB_LEVERS[[lv]]) {
    mods <- if (lv == "w_out") list(w_out_NH = x, w_out_SH = x) else setNames(list(x), lv)
    rr <- fb_row(mods); rows[[as.character(x)]] <- rr
    cat(sprintf("  %8.2f %9.3f %+11.4f %+11.4f %+11.4f %11.1f %+9.2f\n",
                x, rr$sink, rr$enso, rr$d13, rr$contrast, rr$deep, rr$z_deep))
  }
  R[[lv]] <- rows
}

# ---------------------------------------------------------------------
sep("THE SCORED PREDICTIONS (prereg 2026-09-04i)")
slope_of <- function(lv, field) {
  x <- FB_LEVERS[[lv]]; y <- vapply(R[[lv]], function(r) r[[field]], 0)
  unname(coef(stats::lm(y ~ x))[2])
}
# P0 -- the harness control, scored FIRST
p0 <- vapply(c("w_up", "w_out"), function(lv) slope_of(lv, "z_deep"), 0)
cat(sprintf("  P0 CONTROL -- d(z_deep)/d(lever) > 0 (AWAY from target)?  w_up %+.3f, w_out %+.3f  ->  %s\n",
            p0[["w_up"]], p0[["w_out"]], if (all(p0 > 0)) "REPRODUCED, P1-P4 are read"
            else "NOT REPRODUCED -- the harness disagrees with 2026-08-15; STOP"))
if (!all(p0 > 0)) { cat("\n  P1-P4 ARE NOT READ.\n"); sep("DONE"); quit(save = "no") }
cat(sprintf("      (control: d(sink)/d(q_conv) = %+.5f GtC/yr per Sv; 2026-09-01 measured +0.0101)\n",
            slope_of("q_conv", "sink")))

# P1 -- THE SIGN
s_up <- slope_of("w_up", "sink"); s_out <- slope_of("w_out", "sink")
cat(sprintf("\n  P1 SIGN -- d(sink)/d(lever): w_up %+.5f, w_out %+.5f GtC/yr per (m/yr)\n", s_up, s_out))
cat(sprintf("      predicted BOTH POSITIVE (conveyor physics)  ->  %s\n",
            if (s_up > 0 && s_out > 0) "CONFIRMED -- Fix B dies the conveyor's death on this route"
            else "FALSIFIED -- read P2; an ENSO-modulated limb is VIABLE"))

# P2 -- the magnitude, meaningful only where the sign allows
cat(sprintf("\n  P2 MAGNITUDE -- a lever must supply %+.4f GtC/yr per index unit\n", FB_ENSO_NEED))
for (lv in c("w_up", "w_out")) {
  s <- slope_of(lv, "sink"); x0 <- max(FB_LEVERS[[lv]])
  need <- FB_ENSO_NEED / s          # m/yr of modulation per index unit
  cat(sprintf("      %-6s d(sink)/d(lever) %+.5f -> needs %+.2f (m/yr) per index unit = %.0f%% of %.1f\n",
              lv, s, need, 100 * abs(need) / x0, x0))
}
cat("      predicted > 100 % (the conveyor needed 136-542 %)\n")

# P3 -- the isotope row
cat(sprintf("\n  P3 ISOTOPES -- d(d13C bias)/d(lever), bias starts at %+.4f permil (want it toward 0)\n", base$d13))
i_up <- slope_of("w_up", "d13"); i_out <- slope_of("w_out", "d13")
cat(sprintf("      w_up %+.5f, w_out %+.5f permil per (m/yr)\n", i_up, i_out))
cat(sprintf("      REDUCES the depletion?  w_up %s, w_out %s\n",
            if (i_up > 0) "YES" else "no", if (i_out > 0) "YES" else "no"))
cat(sprintf("      and w_out beats w_up (the one-step limb)?  %s  (|%.5f| vs |%.5f|)\n",
            if (abs(i_out) > abs(i_up)) "CONFIRMED" else "MISSED", i_out, i_up))

# P4 -- gate H, labelled weakest in advance
cat(sprintf("\n  P4 GATE H (WEAKEST ROW) -- contrast starts at %+.3f (z %+.2f)\n", base$contrast, base$zH))
for (lv in c("w_up", "w_out"))
  cat(sprintf("      %-6s d(contrast)/d(lever) %+.5f  ->  %s\n", lv, slope_of(lv, "contrast"),
              if (slope_of(lv, "contrast") < 0) "reduces it" else "does NOT reduce it"))

sep("DONE")
