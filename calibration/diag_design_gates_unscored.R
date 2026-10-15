# =====================================================================
# ⛔ SUPERSEDED 2026-10-02 (W4; audit 10-02 B6, Marcus: "Restore gates 6 and 11"). Gates 6 and 11
# live in calibration/lib_design_gates.R now (dg_gate6*, dg_gate11*) and run in the scorecard on
# each arm's OWN vector, structure and spinup -- this driver builds the model from DEFAULTS with the
# aseasonal spinup and cannot score a canonical. Gate 6's bound is now two-sided on the observed
# ratio's bootstrap se, and gate 11 screens the objective's own residuals (every row). Kept, unrun,
# as the 08-28 record; do not run it for a verdict.
# =====================================================================
# diag_design_gates_unscored.R -- THE FOUR DESIGN sec.6 GATES THAT NO
#                                 DIAGNOSTIC HAS EVER MEASURED.
#
# `diag_design_gates_at_mode.R` covers gates 4, 5, 7, 9; `diag_joos_irf.R`
# covers 12. Gates 1-3 are the test suite. That leaves **6, 8, 10 and 11 with
# no measurement at any fitted vector** -- and gate 6 is the SEASONAL AMPLITUDE
# GROWTH gate, i.e. the gate for the arc that has been live since 08-27f.
#
# ⚠ EVERY OBSERVED TARGET HERE IS RECOMPUTED WITH THE SAME ESTIMATOR APPLIED TO
# THE MODEL, AND CHECKED AGAINST DESIGN'S PUBLISHED TABLE BEFORE IT IS USED.
# That is the pattern gate 5 already uses (`ccx_zone_weights()` reproducing
# DESIGN's bomb table). It matters most for gate 6, where DESIGN's target is
# "PEAK-TO-TROUGH of the mean seasonal cycle" -- NOT the 2*sqrt(a^2+b^2) of a
# first-harmonic fit, which understates a non-sinusoidal cycle.
# [[amp_definition_mismatch]]
#
# ⚠ NOT AN OBJECTIVE CHANGE. Nothing here touches R/ or src/; these are gates,
# read-only, and no refit is owed by anything this file prints.
#
# Usage:  Rscript calibration/diag_design_gates_unscored.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

DGU_YEARS <- c(1750, 2024)
# ---- GATE 6, DESIGN sec.6: MLO peak-to-trough of the mean seasonal cycle.
DGU_G6_DECADES <- list("1960s" = c(1960, 1969), "1970s" = c(1970, 1979),
                       "1980s" = c(1980, 1989), "1990s" = c(1990, 1999),
                       "2000s" = c(2000, 2009), "2010s" = c(2010, 2019),
                       "2020s" = c(2020, 2024))
# DESIGN sec.6 gate 6's target row, CORRECTED 2026-08-28. The previous
# transcription -- c(5.95, 6.17, 6.40, 6.42, 6.38, 6.86, 6.66) -- is NOT what
# build_calibration_data.R:583-588 produces on data/obs_co2_monthly.rds, and the
# two differ QUALITATIVELY: the data is monotone increasing, the old row dipped at
# the 2000s (by 0.27 ppm = ~30 % of the growth signal the gate tests) and at the
# 2020s. Vintage: obs_co2_monthly.rds as of 2026-08-28, MLO 1958-2026.
DGU_G6_DESIGN  <- c(5.95, 6.13, 6.30, 6.47, 6.65, 6.83, 6.97)
DGU_G6_CHECK   <- 0.05        # ppm; the SCRIPPS-deseas route must reproduce DESIGN
DGU_G6_GROWTH  <- 0.15        # "~15 % across the record", DESIGN's own wording
DGU_G6_GROW_CHK<- 0.02        # the two OBSERVED routes must agree on GROWTH this well
# ⚠ DGU_G6_CHECK was first written against MY 12-month-MA route and FAILED at
# 0.341 ppm. That was a MIS-SPECIFIED CHECK, not a failing model: DESIGN's table
# is built from Scripps' own `co2_deseas` column (data-raw/build_calibration_data.R
# :583-588), which HAS NO MODEL COUNTERPART, so it cannot be the like-for-like
# route. The fix is to run BOTH observed routes: Scripps-deseas to reproduce
# DESIGN (provenance), and the 12-month MA -- applied identically to obs and
# model -- to compare. The gate itself is then taken on GROWTH, which is the
# quantity DESIGN's gate sentence actually tests and which survives the estimator
# change. [[derive_gate_from_the_thing]] [[amp_definition_mismatch]]
# ---- GATES 8 AND 10 ARE RETIRED (2026-09-04). Their constants are kept here as
# ---- PROVENANCE ONLY -- nothing reads them; see the retirement block below.
DGU_G8_RETIRED  <- "GATE 8 retired 2026-09-04: a restatement of d13c_level_MLO/SPO at a typed 0.10 per mil."
DGU_G10_RETIRED <- "GATE 10 retired 2026-09-04: target AND sigma came from the likelihood's own accessor, so it could not fail independently."
# ---- GATE 11: suspicious-uniformity screen thresholds.
DGU_G11_SIGN <- 0.95          # |fraction same sign| above this = flag
DGU_G11_R2   <- 0.90          # R^2 of residual ~ year above this = flag
DGU_G11_MINN <- 20

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
obs <- ccx_prepare_obs()

# --- the estimator, applied IDENTICALLY to obs and model ---------------
# 12-month centered moving average as the trend, series minus trend as the
# seasonal, monthly climatology within the decade, peak minus trough. Using MY
# OWN detrend on BOTH sides rather than Scripps' `co2_deseas` on one of them.
ptt_by_decade <- function(t, x, decades) {
  o <- order(t); t <- t[o]; x <- x[o]
  n <- length(x); tr <- rep(NA_real_, n)
  for (i in 7:(n - 6)) tr[i] <- (sum(x[(i - 5):(i + 5)]) + 0.5 * (x[i - 6] + x[i + 6])) / 12
  s <- x - tr
  mo <- floor((t %% 1) * 12) + 1
  vapply(decades, function(d) {
    k <- is.finite(s) & t >= d[1] & t < d[2] + 1
    if (sum(k) < 24) return(NA_real_)
    cl <- tapply(s[k], mo[k], mean)
    if (length(cl) < 12) return(NA_real_)
    max(cl) - min(cl)
  }, 0)
}

# THE LABEL DERIVES FROM THE CONSTANT. This element used to be named `from90`
# by hand while its VALUE resolved through CCX_MODE_CANONICAL -- so the moment
# the canonical mode is repointed, every table and message from this file would
# have gone on calling the new vector by the old arm's name.
vecs <- list(defaults = NULL)
vecs[[CCX_MODE_CANONICAL]] <- ccx_mode_file(CCX_MODE_CANONICAL)
# `pin90` IS OPTIONAL HERE and always was -- but the old guard asked
# file.exists(ccx_mode_file("pin90")), and ccx_mode_file() ERRORS on a retired
# name before file.exists() ever sees it. Once pin90 is retired that guard turns
# an intended graceful absence into a hard stop, so the registry is asked first.
if ("pin90" %in% names(CCX_MODE_FILES) && file.exists(ccx_mode_file("pin90")))
  vecs$pin90 <- ccx_mode_file("pin90")
run_vec <- function(mf) {
  p <- ccx_default_params(); bt <- CCX_PARAM_TABLE$bomb_total$init; ls_ <- 1; pv <- NULL
  if (!is.null(mf)) {
    md <- readRDS(mf)
    # ⚠ ccx_mode_params(), NOT ccx_unc_to_par(md$u_mode): h_ml's logit band is
    # overridden in process by the refits, so the shipped-table decode returns
    # 85.73 m where this mode sits at 96.47 m. This driver runs SEVERAL mode
    # files, which may carry DIFFERENT bands, so it repairs the decode per
    # vector rather than adopting one band globally. [[ccx_hml_band_decode]]
    pv <- ccx_mode_params(md)
    for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
    p <- ccx_set_enso(p, pv); p$pump_mode <- md$pump_mode
    bt <- pv$bomb_total; ls_ <- pv$luc_scale
  }
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", DGU_YEARS, prod_c14 = 0, bomb_total_kmol = CCX_BOMB_REF)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (bt / CCX_BOMB_REF)
  for (cc in CCX_LUC_COLS) F[[cc]] <- F[[cc]] * ls_
  attr(F, "luc_scale") <- ls_
  list(out = ccx_run_fast(sp, F)$out, sp = sp, pv = pv)
}
cat("running vectors:", paste(names(vecs), collapse = ", "), "\n")
R <- lapply(vecs, run_vec)

# ---------------------------------------------------------------------
sep("GATE 6 -- MLO SEASONAL AMPLITUDE BY DECADE (peak-to-trough)")
mlo <- obs$co2[obs$co2$station == "MLO", ]
# ROUTE A -- DESIGN's exact recipe: Scripps' own seasonal adjustment. Provenance
# only; there is no model counterpart to `co2_deseas`.
kA <- is.finite(mlo$co2_ppm) & is.finite(mlo$co2_deseas)
rA <- mlo$co2_ppm[kA] - mlo$co2_deseas[kA]; tA <- mlo$decimal_date[kA]; moA <- mlo$month[kA]
o_scr <- vapply(DGU_G6_DECADES, function(d) {
  k <- tA >= d[1] & tA < d[2] + 1
  if (sum(k) < 24) return(NA_real_)
  cl <- tapply(rA[k], moA[k], mean); max(cl) - min(cl) }, 0)
# ROUTE B -- the 12-month centered MA, applied IDENTICALLY to obs and model.
o_ptt <- ptt_by_decade(mlo$decimal_date, mlo$co2_ppm, DGU_G6_DECADES)
cat("  TWO OBSERVED ROUTES. A reproduces DESIGN; B is the like-for-like one.\n\n")
cat(sprintf("  %-14s", "decade")); for (d in names(DGU_G6_DECADES)) cat(sprintf(" %7s", d))
cat(sprintf(" | %9s\n", "2010s/60s"))
cat(sprintf("  %-14s", "DESIGN table")); for (v in DGU_G6_DESIGN) cat(sprintf(" %7.2f", v))
cat(sprintf(" | %9.3f\n", DGU_G6_DESIGN[6] / DGU_G6_DESIGN[1]))
cat(sprintf("  %-14s", "A Scripps")); for (v in o_scr) cat(sprintf(" %7.2f", v))
cat(sprintf(" | %9.3f\n", o_scr[["2010s"]] / o_scr[["1960s"]]))
cat(sprintf("  %-14s", "B 12-mo MA")); for (v in o_ptt) cat(sprintf(" %7.2f", v))
cat(sprintf(" | %9.3f\n", o_ptt[["2010s"]] / o_ptt[["1960s"]]))
dA <- abs(o_scr - DGU_G6_DESIGN)
okA <- all(is.finite(dA)) && max(dA) <= DGU_G6_CHECK
cat(sprintf("\n  PROVENANCE: route A vs the DGU_G6_DESIGN table, max |diff| %.3f ppm (gate %.2f) -> %s\n",
            max(dA, na.rm = TRUE), DGU_G6_CHECK, if (okA) "REPRODUCED" else "⚠ DOES NOT REPRODUCE"))
if (!okA) {
  cat("  ⚠ Route A IS build_calibration_data.R:583-588 run verbatim, and it reproduces\n")
  cat("  exactly off data/obs_co2_monthly.rds -- so `ccx_prepare_obs()` is faithful and\n")
  cat("  the DISAGREEMENT IS WITH THE TRANSCRIBED TABLE, not with the data path. The two\n")
  cat("  differ QUALITATIVELY, not by rounding: the data is MONOTONE INCREASING while the\n")
  cat("  transcribed table dips at the 2000s and 2020s. DESIGN sec.6 says these targets\n")
  cat("  are regenerated by re-running that script; DGU_G6_DESIGN above is the value to\n")
  cat("  update, WITH its data vintage recorded.\n")
}
dlev <- max(abs(o_scr - o_ptt), na.rm = TRUE)
dgro <- abs(o_scr[["2010s"]] / o_scr[["1960s"]] - o_ptt[["2010s"]] / o_ptt[["1960s"]])
ok6 <- dgro <= DGU_G6_GROW_CHK   # ROBUSTNESS only; provenance is reported separately
cat(sprintf("\n  ESTIMATOR SENSITIVITY (route A vs route B on the SAME observed data):\n"))
cat(sprintf("  LEVELS differ by up to %.3f ppm, but the GROWTH RATIO differs by only %.4f\n", dlev, dgro))
cat(sprintf("  (gate %.2f) -> %s\n", DGU_G6_GROW_CHK,
            if (ok6) "GROWTH IS ESTIMATOR-ROBUST" else "⚠ GROWTH IS NOT ESTIMATOR-ROBUST"))
cat(sprintf("  ⚠ %.2f ppm is ~%.0f %% of the amplitude and comparable to the %.2f ppm growth\n",
            dlev, 100 * dlev / mean(o_scr, na.rm = TRUE),
            o_scr[["2010s"]] - o_scr[["1960s"]]))
cat("  signal itself, so DESIGN's absolute decadal levels are NOT quotable to 0.01 ppm;\n")
cat("  the growth the gate tests IS. The model is compared to route B below.\n")
if (!ok6) cat("  ⚠ GROWTH is estimator-dependent -- do NOT read the model rows as verdicts.\n")

cat("\n  MODEL (co2_NH, same estimator; amplitude is offset-invariant so the MLO\n")
cat("  representation offset does not enter):\n")
cat(sprintf("  %-10s", "vector")); for (d in names(DGU_G6_DECADES)) cat(sprintf(" %7s", d))
cat(sprintf(" | %8s %8s\n", "2010s/60s", "verdict"))
cat(sprintf("  %-10s", "OBSERVED")); for (v in o_ptt) cat(sprintf(" %7.2f", v))
cat(sprintf(" | %8.3f %8s\n", o_ptt[["2010s"]] / o_ptt[["1960s"]], ""))
g6 <- list()
for (nm in names(R)) {
  m <- ptt_by_decade(R[[nm]]$out$t, R[[nm]]$out$co2_NH, DGU_G6_DECADES)
  gr <- m[["2010s"]] / m[["1960s"]]
  pass <- is.finite(gr) && (gr - 1) >= DGU_G6_GROWTH
  g6[[nm]] <- list(ptt = m, growth = gr, pass = pass)
  cat(sprintf("  %-10s", nm)); for (v in m) cat(sprintf(" %7.2f", v))
  cat(sprintf(" | %8.3f %8s\n", gr, if (pass) "PASS" else "FAIL"))
}
cat(sprintf("\n  GATE: growth >= %.0f %% across the record, PRODUCED not prescribed (obs %+.1f %%).\n",
            100 * DGU_G6_GROWTH, 100 * (o_ptt[["2010s"]] / o_ptt[["1960s"]] - 1)))

# =====================================================================
# ⛔⛔ GATES 8 AND 10 ARE RETIRED (2026-09-04, Marcus). NEITHER IS REPLACED.
#
# Both were OBSERVATIONAL in source and both were RESTATEMENTS of a stream the
# objective already scores, so neither could tell us anything the fit had not
# already been asked for -- the "SCORED?" column of DG_LEDGER turned into a
# decision [[ccx_gate4_no_power]].
#
#   GATE 8 (d13C SUESS ENDPOINTS) took the modeled minus preindustrial d13C
#   decline at MLO 2024 and SPO 2024 against Scripps/Law Dome. Those exact
#   station-years are inside `d13c_level_MLO` and `d13c_level_SPO`, which score
#   EVERY year of the same records; differencing two of them and re-checking the
#   result at a hand-picked 0.10 per mil (DGU_G8_TOL, a typed round number with no
#   derivation) re-judges a fitted stream at a tolerance nobody derived.
#
#   GATE 10 (NATURAL DEEP-OCEAN D14C) is the clearest case in the set: its own
#   header said the target AND the sigma came from `ccx_deep_d14c_target()`, "the
#   LIKELIHOOD's own accessor, so this gate cannot drift from the stream that
#   scores it". A gate deliberately tied to the stream it checks CANNOT FAIL
#   INDEPENDENTLY of the optimizer -- it reports that the fit ran. The
#   observation itself is not lost: `d14c_deep_ocean` scores it, and
#   `test-likelihood.R` bounds `kz` THROUGH it (2026-09-04, the ruling that
#   replaced the kz bracket with the observable).
#
# ⚠ WHAT IS LOST, SAID OUT LOUD. Gate 8 was the only place the PREINDUSTRIAL
# d13C and CO2 levels were printed beside their targets for every arm; gate 10
# was the only place the spinup's bottom-box D14C was printed beside the kz
# bracket. Both are DIAGNOSTIC prints, not tests, and both quantities remain
# available (`sp$diagnostics`, `ccx_deep_d14c_target()`). If a future session
# wants them back, bring back the PRINT, not the verdict.
# =====================================================================

sep("GATE 11 -- SUSPICIOUS-UNIFORMITY SCREEN on annual residuals")
cat("  Screens model-minus-observed for the two bug signatures in the standing\n")
cat("  discipline: ALL-SAME-SIGN, and EXACTLY-LINEAR. The mean is reported\n")
cat("  separately and removed before the linearity test, so a known LEVEL bias\n")
cat("  does not masquerade as a trend. [[ccx_fit_at_mode]]\n\n")
ann <- function(o, col) { y <- floor(o$t); tapply(o[[col]], y, mean) }
series <- list(
  co2_MLO  = list(col = "co2_NH",  st = "MLO", src = "co2",  val = "co2_ppm"),
  co2_SPO  = list(col = "co2_SH",  st = "SPO", src = "co2",  val = "co2_ppm"),
  d13c_MLO = list(col = "d13c_NH", st = "MLO", src = "d13",  val = "d13c"),
  d13c_SPO = list(col = "d13c_SH", st = "SPO", src = "d13",  val = "d13c"))
cat(sprintf("  %-10s %-10s %5s %9s %9s %7s %s\n", "vector", "series", "n",
            "mean res", "frac same", "R2(t)", "flag"))
g11 <- list()
for (nm in names(R)) {
  o <- R[[nm]]$out
  for (sn in names(series)) {
    S <- series[[sn]]; d <- obs[[S$src]]; d <- d[d$station == S$st, ]
    oa <- tapply(d[[S$val]], d$year, mean); ma <- ann(o, S$col)
    yr <- intersect(names(oa), names(ma)); if (length(yr) < DGU_G11_MINN) next
    r  <- as.numeric(ma[yr]) - as.numeric(oa[yr]); ty <- as.numeric(yr)
    fs <- max(mean(r > 0), mean(r < 0))
    r2 <- summary(lm(I(r - mean(r)) ~ ty))$r.squared
    fl <- c(if (fs >= DGU_G11_SIGN) "ALL-SAME-SIGN", if (r2 >= DGU_G11_R2) "LINEAR")
    g11[[paste(nm, sn)]] <- list(n = length(yr), mean = mean(r), frac = fs, r2 = r2, flag = fl)
    cat(sprintf("  %-10s %-10s %5d %+9.3f %9.3f %7.3f %s\n", nm, sn, length(yr),
                mean(r), fs, r2, if (length(fl)) paste("⚠", paste(fl, collapse = "+")) else "ok"))
  }
}
cat(sprintf("\n  thresholds: same-sign >= %.2f, R2 >= %.2f, min n = %d\n",
            DGU_G11_SIGN, DGU_G11_R2, DGU_G11_MINN))
cat("  ⚠ A flag here is a SIGNAL TO INVESTIGATE, not a verdict: a genuine, already\n")
cat("  diagnosed level bias will trip ALL-SAME-SIGN legitimately.\n")

sep("SUMMARY at the canonical mode")
# ⛔ `cn` WAS THE TYPED LITERAL "from90" -- an arm QUARANTINED on 2026-09-04, so
# every g6/g8/g10/g11 lookup below indexed a NULL and this summary could not run
# at all. THE LABEL DERIVES FROM THE CONSTANT, which is the rule this same file
# already states at `vecs` and which was applied there and not here.
cn <- CCX_MODE_CANONICAL
cat(sprintf("  gate  6 (MLO seasonal growth)  %s   growth %+.1f %% vs observed %+.1f %%\n",
            if (g6[[cn]]$pass) "PASS" else "FAIL", 100 * (g6[[cn]]$growth - 1),
            100 * (o_ptt[["2010s"]] / o_ptt[["1960s"]] - 1)))
cat(sprintf("  gate  8 (d13C Suess decline)   ⛔ %s\n", DGU_G8_RETIRED))
cat(sprintf("  gate 10 (deep natural D14C)    ⛔ %s\n", DGU_G10_RETIRED))
fl <- unlist(lapply(g11[grep(paste0("^", cn), names(g11))], function(x) length(x$flag) > 0))
cat(sprintf("  gate 11 (uniformity screen)    %s   %d of %d series flagged\n",
            if (!any(fl)) "CLEAN" else "FLAGS", sum(fl), length(fl)))

OUTDIR <- ccx_path("outputs", "diagnostics")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(g6 = g6, g6_obs = o_ptt, g6_obs_scripps = o_scr, g6_design = DGU_G6_DESIGN, g6_estimator_ok = ok6,
             g8 = DGU_G8_RETIRED, g10 = DGU_G10_RETIRED, g11 = g11),
        file.path(OUTDIR, "design_gates_unscored.rds"))
cat(sprintf("\nwritten: %s\n\n\n=== DONE ===\n", file.path(OUTDIR, "design_gates_unscored.rds")))
