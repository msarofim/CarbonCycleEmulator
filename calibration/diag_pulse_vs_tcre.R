# =====================================================================
# diag_pulse_vs_tcre.R -- IS THE PULSE LAB'S "degC PER 1000 GtC" RIGHT?
# (Marcus, 2026-09-26: "check the pulse analysis against both the TCRE and
# against standard FaIR".)
#
# THE NUMBER UNDER TEST. `output$f_pulse_permanence` prints
#     per1000 = dT(pulse_year + 100) / pulse_GtC * 1000
# and at the app's defaults that is ~1.08 degC per 1000 GtC. The copy flags it as
# low-side against a RECOLLECTION of AR6 TCRE ~1.65, and deliberately never says
# "TCRE" because it is not that quantity.
#
# ⛔⛔ THE TWO ARE DIFFERENT QUANTITIES AND MUST NOT BE COMPARED NAIVELY.
#   TCRE  = dGMST per 1000 GtC of CUMULATIVE CO2 emission, measured AT the time
#           cumulative emissions reach that level, under CONTINUOUS CO2-only
#           emission. AR6 assesses 1.65 degC/1000 GtC, likely 1.0-2.3.
#           ⚠ THE AR6 NUMBER HERE IS A RECOLLECTION, NOT A CITATION. It is
#           carried as TCRE_AR6_* below so it can be corrected in ONE place, and
#           every verdict that uses it says so. Do not harden it into a gate
#           until someone reads AR6 WG1 and stamps the source.
#   pulse = the MARGINAL dGMST from one extra increment, measured a century
#           later, on a background scenario that keeps emitting.
# They are close in theory -- that near-equality IS the cumulative-emissions
# result -- which is exactly why a 35 % gap deserves a decomposition rather than
# a shrug.
#
# ⭐ WHAT MAKES THIS DECOMPOSABLE. CCX's climate module is NOT independent of
# FaIR: `ccx_climate_module()`'s provenance reads "FaIR 2.2.4 (calib1.6.0), RCMIP
# SSP emissions, 841 configs, ENSEMBLE MEAN". Its ERF law is fitted to FaIR's
# Meinshausen-2020 CO2 forcing and its 3-timescale IRF is fitted to FaIR's GMST.
# So:
#     dT  =  [ carbon cycle: GtC -> dCO2 ]  x  [ ERF law ]  x  [ thermal IRF ]
#             ^^^^ CCX's OWN                   ^^^^^^^^ both FITTED TO FaIR
# A CCX-vs-FaIR disagreement in dT therefore localises to the CARBON CYCLE, and
# the way to show that is to compare dCO2 FIRST and dT second -- swap the driver
# before blaming a module. This script does the CCX half and prints dCO2
# alongside dT at every horizon so the FaIR half can be differenced against it.
#
# Usage:  Rscript calibration/diag_pulse_vs_tcre.R
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
setwd(.root)

# ⭐ THE APP'S OWN OBJECTS, NOT A REBUILD. `app/global.R` is sourced so that
# APP_SPIN, APP_SSP_EMIS, APP_PULSE_* and app_run_coupled() are EXACTLY the ones
# the tab uses. Rebuilding them from ccx_default_params() is the standing trap
# [[ccx_diag_must_use_mode_base]]: every arm stays mutually consistent, the
# script completes, and the numbers are not the app's.
suppressWarnings(suppressMessages(source(file.path(.root, "app", "global.R"))))

PT_TAG   <- "pulse_vs_tcre"
PT_DATE  <- format(Sys.Date(), "%Y%m%d")
PT_LOG   <- file.path("outputs", "diagnostics", sprintf("%s_%s.log", PT_TAG, PT_DATE))
PT_OUT   <- file.path("outputs", "diagnostics", sprintf("%s_%s.csv", PT_TAG, PT_DATE))
PT_BG    <- "ssp245"                     # the app's default background
PT_YEAR  <- APP_PULSE_YEAR_DEFAULT       # the app's default release year
PT_SIZES <- c(10, 50, 100, 200, 500)     # the p_gtc slider's own range
PT_REF   <- APP_PULSE_GtC_DEFAULT        # the size the app's copy quotes
PT_HORIZ <- c(20L, 50L, 100L, 200L)      # years after release
PT_GTC_PER_PPM <- ccx_const("GtC_PER_PPM")
# ⚠ RECOLLECTION, NOT A CITATION (see header). One place, so one correction.
TCRE_AR6_BEST <- 1.65
TCRE_AR6_LO   <- 1.00
TCRE_AR6_HI   <- 2.30
TCRE_AR6_SRC  <- "AR6 WG1, per 1000 GtC -- RECOLLECTED, NOT VERIFIED"
# Linearity: how far the per-1000 number may drift across a 50x size range
# before "a per-tonne number is meaningful" stops being an honest claim. Derived
# from the SPREAD the sizes themselves produce, and reported either way.
PT_LIN_TOL_PCT <- 10

dir.create(dirname(PT_LOG), showWarnings = FALSE, recursive = TRUE)
say <- function(...) { t <- sprintf(...); cat(t); cat(t, file = PT_LOG, append = TRUE) }

say("\n=== %s (%s) ===\n", PT_TAG, PT_DATE)
say("climate module provenance: %s\n", ccx_climate_module()$provenance)
say("background %s, release year %d, sizes {%s} GtC, GtC/ppm %.4f\n",
    PT_BG, PT_YEAR, paste(PT_SIZES, collapse = ", "), PT_GTC_PER_PPM)

# ---------------------------------------------------------------------
# The app's pulse, reproduced exactly (server.R `pulse_runs`).
# ---------------------------------------------------------------------
pt_pulse <- function(gtc, year = PT_YEAR, bg = PT_BG) {
  yrs <- APP_PULSE_YEARS
  b <- APP_SSP_EMIS[APP_SSP_EMIS$scenario == bg, ]
  y <- seq(yrs[1], yrs[2])
  base_em <- data.frame(
    year = y,
    fossil_GtC = stats::approx(b$year, b$fossil_GtC, xout = y, rule = 2)$y,
    luc_GtC    = stats::approx(b$year, b$luc_GtC,    xout = y, rule = 2)$y)
  pulse_em <- base_em
  pulse_em$fossil_GtC[pulse_em$year == year] <-
    pulse_em$fossil_GtC[pulse_em$year == year] + gtc
  # ⚠ BOTH arms carry APP_PULSE_EMIS_METHOD, exactly as the tab does, or the
  # pair would differ by the interpolation as well as by the pulse.
  list(base = app_run_coupled(APP_SPIN, bg, yrs, bg, emissions = base_em,
                              interp_method = APP_PULSE_EMIS_METHOD),
       pulse = app_run_coupled(APP_SPIN, bg, yrs, bg, emissions = pulse_em,
                               interp_method = APP_PULSE_EMIS_METHOD),
       gtc = gtc, year = year)
}

pt_read <- function(pr) {
  b <- pr$base$climate; p <- pr$pulse$climate
  data.frame(year = b$year, dT = p$gmst - b$gmst, dC = p$co2_ppm - b$co2_ppm)
}

# ---------------------------------------------------------------------
# GATE ZERO-PULSE: a zero-size pulse must reproduce the baseline EXACTLY.
# Without it, any difference below could be the interpolation, the spinup or
# solver noise rather than the pulse. This is the sanity test the project's
# climate-modeling skill requires before any headline number.
# ---------------------------------------------------------------------
z <- pt_read(pt_pulse(0))
gz <- max(abs(z$dT)) == 0 && max(abs(z$dC)) == 0
say("\n=== GATE ZERO-PULSE === max|dT| %.3e, max|dCO2| %.3e -> %s\n",
    max(abs(z$dT)), max(abs(z$dC)), if (gz) "PASS (bit-identical)" else "*** FAIL ***")
if (!gz) stop("a zero pulse did not reproduce the baseline; the pair is contaminated")

# ---------------------------------------------------------------------
# The sweep: size x horizon.
# ---------------------------------------------------------------------
rows <- list()
for (g in PT_SIZES) {
  pr <- pt_pulse(g); d <- pt_read(pr)
  at <- function(y, col) d[[col]][which.min(abs(d$year - y))]
  pk <- max(d$dT, na.rm = TRUE); pky <- d$year[which.max(d$dT)]
  yend <- max(d$year)
  for (h in PT_HORIZ) {
    y <- PT_YEAR + h
    if (y > yend) next
    rows[[length(rows) + 1]] <- data.frame(
      gtc = g, horizon = h, year = y,
      dT = at(y, "dT"), dC_ppm = at(y, "dC"),
      per1000 = at(y, "dT") / g * 1000,
      af = at(y, "dC") * PT_GTC_PER_PPM / g,
      peak_dT = pk, peak_year = pky,
      end_frac = at(yend, "dT") / pk)
  }
  say("  %3d GtC: peak dT %.4f at %d; dT(2300) %.4f = %.0f %% of peak\n",
      g, pk, pky, d$dT[d$year == yend], 100 * d$dT[d$year == yend] / pk)
}
R <- do.call(rbind, rows)
write.csv(R, PT_OUT, row.names = FALSE)

# ---------------------------------------------------------------------
# GATE ANCHOR: reproduce the number the APP prints at its own defaults.
# ---------------------------------------------------------------------
a <- R[R$gtc == PT_REF & R$horizon == 100L, ]
say("\n=== GATE ANCHOR === at the app's defaults (%d GtC, +100 yr): dT %.4f degC, %.3f degC/1000 GtC\n",
    PT_REF, a$dT, a$per1000)
say("    the app's permanence box prints 0.108 degC and 1.08 degC/1000 GtC -> %s\n",
    if (abs(a$per1000 - 1.08) < 0.02) "PASS, this script is reading the same model"
    else "*** MISMATCH -- resolve before reading anything below ***")

say("\n== dGMST per 1000 GtC, by pulse size and horizon ==\n")
say("   %6s", "GtC")
for (h in PT_HORIZ) say(" %11s", sprintf("+%dyr", h))
say("\n")
for (g in PT_SIZES) {
  say("   %6d", g)
  for (h in PT_HORIZ) {
    v <- R$per1000[R$gtc == g & R$horizon == h]
    say(" %11s", if (length(v)) sprintf("%.3f", v) else "-")
  }
  say("\n")
}
say("   ⭐ READ DOWN a column for LINEARITY in pulse size (the app's copy says the\n")
say("     proportionality is \"stated, not shown\" -- this shows it). READ ACROSS a\n")
say("     row for how the marginal warming EVOLVES: TCRE's near-constancy in time\n")
say("     is the thing a pulse response is supposed to approximate.\n")

# LINEARITY, measured and judged against the spread it produces
say("\n== LINEARITY across a %gx size range, at +100 yr ==\n", max(PT_SIZES)/min(PT_SIZES))
v <- R$per1000[R$horizon == 100L]
say("   per-1000 ranges %.3f to %.3f, spread %.1f %% of the mean -> %s\n",
    min(v), max(v), 100 * (max(v) - min(v)) / mean(v),
    if (100 * (max(v) - min(v)) / mean(v) < PT_LIN_TOL_PCT)
      sprintf("within %g %%: quoting a per-tonne number is honest here", PT_LIN_TOL_PCT)
    else sprintf("EXCEEDS %g %%: the per-tonne framing needs a size caveat", PT_LIN_TOL_PCT))

# ---------------------------------------------------------------------
# AIRBORNE FRACTION -- the carbon-cycle half, printed so the FaIR comparison can
# difference it separately from dT. ⚠ If dCO2 matches FaIR and dT does not, the
# fault is the ERF law or the IRF; if dCO2 differs, it is the carbon cycle.
# ---------------------------------------------------------------------
say("\n== AIRBORNE FRACTION of the pulse (dCO2 in GtC / pulse GtC) ==\n")
say("   %6s", "GtC")
for (h in PT_HORIZ) say(" %11s", sprintf("+%dyr", h))
say("\n")
for (g in PT_SIZES) {
  say("   %6d", g)
  for (h in PT_HORIZ) {
    x <- R$af[R$gtc == g & R$horizon == h]
    say(" %11s", if (length(x)) sprintf("%.4f", x) else "-")
  }
  say("\n")
}

# ---------------------------------------------------------------------
# AGAINST THE AR6 TCRE -- stated as a RATIO, with the caveat attached.
# ---------------------------------------------------------------------
say("\n== against the AR6 TCRE (%s) ==\n", TCRE_AR6_SRC)
say("   AR6 best %.2f, likely %.2f-%.2f degC/1000 GtC\n",
    TCRE_AR6_BEST, TCRE_AR6_LO, TCRE_AR6_HI)
say("   CCX pulse, %d GtC at +100 yr: %.3f  = %.0f %% of the AR6 best estimate, %s its likely range\n",
    PT_REF, a$per1000, 100 * a$per1000 / TCRE_AR6_BEST,
    if (a$per1000 >= TCRE_AR6_LO && a$per1000 <= TCRE_AR6_HI) "INSIDE" else "OUTSIDE")
say("   ⚠ NOT LIKE-FOR-LIKE: a marginal pulse response on a scenario is not TCRE.\n")
say("     The ratio is a flag for a decomposition, not a verdict.\n")
# ---------------------------------------------------------------------
# ⭐⭐ AGAINST STANDARD FaIR -- THE TIGHTEST TEST AVAILABLE, and the one that
# LOCALISES the difference.
#
# ⛔ THIS IS NOT AN INDEPENDENT VALIDATION, and must not be reported as one.
# CCX's climate module IS FaIR's 841-config ensemble mean: the ERF law is fitted
# to FaIR's Meinshausen-2020 CO2 forcing and the 3-timescale IRF is fitted to
# FaIR's GMST. What that BUYS is a decomposition: with the ERF law and the
# thermal response shared, dT is ~proportional to dCO2, so
#     dT(CCX)/dT(FaIR)  ~=  dCO2(CCX)/dCO2(FaIR)
# and a gap in the FIRST that matches a gap in the SECOND is a CARBON-CYCLE
# result, not a climate one. Compare dCO2 FIRST.
#
# ⚠ LIKE-FOR-LIKE, and it was NOT so at first: the FaIR arm was initially run
# with the pulse in 2030 while this tab's default release year is 2050. A pulse
# twenty years later sits on a different background CO2 and a different sink
# state, which would have been charged to the carbon cycle. Re-run matched.
# The FaIR file's own name carries its release year for exactly that reason.
# ---------------------------------------------------------------------
PT_FAIR <- file.path("data-raw", "downloads", "fair_v160_pulse",
                     sprintf("fair_pulse_%dGtC_%d_%s_calib160.csv", PT_REF, PT_YEAR, PT_BG))
if (!file.exists(PT_FAIR)) {
  say("\n[no FaIR comparison file at %s -- skipping the FaIR section]\n", PT_FAIR)
} else {
  fa <- utils::read.csv(PT_FAIR, comment.char = "#")
  fa$year <- floor(as.numeric(fa$year))
  d100 <- pt_read(pt_pulse(PT_REF))
  say("\n== CCX vs STANDARD FaIR, matched: %d GtC in %d on %s, FaIR 2.2.4 calib 1.6.0, 841 configs ==\n",
      PT_REF, PT_YEAR, PT_BG)
  say("   %6s | %8s %8s %7s | %8s %8s %7s\n",
      "yr", "AF ccx", "AF fair", "ratio", "K/1000 ccx", "fair", "ratio")
  for (h in c(30L, 100L, 180L, 250L)) {
    y <- PT_YEAR + h
    fr <- fa[which.min(abs(fa$year - y)), ]
    if (!nrow(fr) || y > max(d100$year)) next
    cc_dT <- d100$dT[which.min(abs(d100$year - y))]
    cc_dC <- d100$dC[which.min(abs(d100$year - y))]
    af_c <- cc_dC * PT_GTC_PER_PPM / PT_REF
    af_f <- fr$d_co2_ppm_meandiff * PT_GTC_PER_PPM / PT_REF
    p_c  <- cc_dT / PT_REF * 1000; p_f <- fr$d_gmst_meandiff / PT_REF * 1000
    say("   %6d | %8.4f %8.4f %7.3f | %10.3f %8.3f %7.3f\n",
        y, af_c, af_f, af_c / af_f, p_c, p_f, p_c / p_f)
  }
  say("   ⭐ READ THE TWO RATIO COLUMNS TOGETHER. If they track each other, the\n")
  say("     temperature difference IS the airborne-fraction difference and the\n")
  say("     climate half (shared with FaIR by construction) is exonerated.\n")
  say("   ⚠ FaIR's per-1000 RISES with horizon while CCX's FALLS -- so the gap is\n")
  say("     not a constant offset and quoting it at one horizon understates it.\n")
  say("   ⚠ The FaIR arm is on RCMIP-native ssp245 emissions, not the CMIP7-\n")
  say("     harmonised set the 1.6.0 posterior was jointly conditioned on. That is\n")
  say("     what the CCX module itself was built from, so it is the matched choice\n")
  say("     here; it is expected to largely cancel in a MARGINAL and was not measured.\n")
  say("   ⚠ FaIR's per-config marginal is right-skewed: median(pulse-base) runs ~5 %%\n")
  say("     BELOW the mean. CCX has one ensemble-MEAN module, so the mean is the\n")
  say("     matched statistic -- but the median would narrow this gap, not widen it.\n")
}

say("\nwrote %s and %s\n", PT_OUT, PT_LOG)
