# =====================================================================
# diag_fert_pulse_gates.R -- the PULSE-side gates for review item 7, which is
# where the log form actually fails.
#
# diag_fert_saturating.R measures the historical side (CO2 record, sink
# partition, log-likelihood). That side never diagnosed the defect: the log
# form fits the CO2 record BEST at the beta that fails the pulse gates worst.
# This file runs the two pulse criteria the review named:
#
#   [1] THE PULSE LAB'S REVELLE LESSON. An identical 100 GtC pulse must persist
#       LONGER on a high-CO2 background, because the ocean's buffer is already
#       stretched. At the shipped default it is REVERSED (-0.113 at 100 yr),
#       so the tab currently teaches the opposite of what it says. This is
#       test-pulse.R:100-101, and it fails.
#
#   [2] DESIGN sec.6 GATE 12 is NOT run here -- it is diag_joos_beta_scan.R,
#       which now takes the same CCX_FERT_* env vars. Section 3 prints the
#       commands and the results already measured, so the two files stay one
#       gate each rather than duplicating a 4-minute run.
#
# THE PROTOCOL SUBTLETY THE REVIEW FLAGGED, and it is not a quibble. The
# PI-vs-PD ordering (HELD backgrounds) survives at every beta; it is only the
# RISING-background SSP comparison that reverses. The app's background slider
# spans both protocols, which is why the tab can be simultaneously right and
# wrong depending on where the user is on its own slider. This file measures
# the SSP protocol, which is the one that fails.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

FP_PULSE_GTC  <- 100                 # GtC, matching test-pulse.R and Joos PD100
FP_PULSE_YEAR <- 2050
FP_SPAN       <- c(1750, 2300)
FP_HORIZON    <- 100                 # yr after the pulse, the reported point
FP_BG_LO      <- "ssp119"
FP_BG_HI      <- "ssp585"
FP_LESSON_MIN <- 0.05                # test-pulse.R:101's threshold
FP_K_GRID     <- c(100, 120, 140, 171)
FP_BETA_REFS  <- c(0.50, 0.75)
FP_BETA_INT   <- 0.70                # the integral anchor, as in diag_fert_saturating.R
FP_CHI_NOW    <- 388

FP_CHI0 <- ccx_const("CO2_PI_PPM")
fp_bmax <- function(K) {
  d <- FP_CHI_NOW - FP_CHI0
  FP_BETA_INT * log(FP_CHI_NOW / FP_CHI0) * (K + d) / d
}

fp_pair <- function(p, gtc, bg) {
  sp <- ccx_spinup(p)
  y  <- seq(FP_SPAN[1], FP_SPAN[2])
  e  <- as.data.frame(readRDS(ccx_path("data", "ssp_emissions.rds")))
  e  <- e[e$scenario == bg, ]
  base <- data.frame(year = y,
                     fossil_GtC = stats::approx(e$year, e$fossil_GtC, xout = y, rule = 2)$y,
                     luc_GtC    = stats::approx(e$year, e$luc_GtC,    xout = y, rule = 2)$y)
  pul <- base
  pul$fossil_GtC[pul$year == FP_PULSE_YEAR] <-
    pul$fossil_GtC[pul$year == FP_PULSE_YEAR] + gtc
  b <- ccx_run_coupled(sp, bg, FP_SPAN, bg, emissions = base)$climate
  q <- ccx_run_coupled(sp, bg, FP_SPAN, bg, emissions = pul)$climate
  data.frame(year = b$year,
             frac = (q$co2_ppm - b$co2_ppm) / (gtc / ccx_const("GtC_PER_PPM")),
             bg_ppm = b$co2_ppm)
}

fp_lesson <- function(p, label) {
  lo <- fp_pair(p, FP_PULSE_GTC, FP_BG_LO)
  # suppressWarnings: SSP5-8.5 to 2300 passes 1687 ppm, the top of FaIR's own
  # SSP range, so the CO2->forcing curve extrapolates and says so. It moves the
  # temperature, not the airborne fraction read here -- the warning is the
  # feature working, and silencing it anywhere else would be wrong.
  hi <- suppressWarnings(fp_pair(p, FP_PULSE_GTC, FP_BG_HI))
  i  <- which(lo$year == FP_PULSE_YEAR + FP_HORIZON)
  d  <- hi$frac[i] - lo$frac[i]
  data.frame(case = label, bg_lo_ppm = lo$bg_ppm[i], bg_hi_ppm = hi$bg_ppm[i],
             frac_lo = lo$frac[i], frac_hi = hi$frac[i], diff = d,
             verdict = if (d > FP_LESSON_MIN) "HOLDS"
                       else if (d > 0) "weak" else "REVERSED")
}

cat("=====================================================================\n")
cat(sprintf("PULSE GATES for the fertilisation form -- %d GtC at %d, read at +%d yr\n",
            FP_PULSE_GTC, FP_PULSE_YEAR, FP_HORIZON))
cat("=====================================================================\n\n")
cat(sprintf("The claim under test: an identical pulse must persist LONGER on the\n"))
cat(sprintf("%s background than on %s. test-pulse.R:101 wants diff > %.2f.\n\n",
            FP_BG_HI, FP_BG_LO, FP_LESSON_MIN))

res <- list()
for (b in FP_BETA_REFS) {
  # `fert_form <- CCX_FERT_LOG` IS LOAD-BEARING. The default is CCX_FERT_MM since
  # 2026-08-14, under which `beta` is inert -- omitting this line made all three
  # reference rows print the MM answer, identical to three decimal places. That
  # suspicious uniformity is what caught it; do not remove the pin.
  p <- ccx_default_params(); p$gamma_enso <- 0.5
  p$fert_form <- CCX_FERT_LOG; p$beta <- b
  res[[length(res) + 1]] <- fp_lesson(p, sprintf("log beta %.2f%s", b,
                                                 if (b == 0.75) " (superseded)" else ""))
}
for (K in FP_K_GRID) {
  p <- ccx_default_params(); p$gamma_enso <- 0.5
  p$fert_form <- CCX_FERT_MM; p$fert_k <- K; p$beta_max <- fp_bmax(K)
  res[[length(res) + 1]] <- fp_lesson(p, sprintf("MM K=%3.0f bmax=%.3f%s", K, fp_bmax(K),
                                                 if (K == 120) " (SHIPPED)" else ""))
}
res <- do.call(rbind, res)
print(format(res, digits = 4), row.names = FALSE)

cat("\n  READ THE MAGNITUDE WITH CARE, not just the sign. The sign is the gate\n")
cat("  and it is decisively restored. The high-background airborne fraction the\n")
cat("  saturating form produces is LARGE and is NOT benchmarked against anything:\n")
cat("  DESIGN gate 12 and Joos et al. (2013) are both at a ~389 ppm background,\n")
cat(sprintf("  not the ~%.0f ppm %s reaches. What the saturating form asserts is that\n",
            res$bg_hi_ppm[1], FP_BG_HI))
cat("  at 7x preindustrial CO2 the land sink is close to saturated, so a pulse has\n")
cat("  nowhere to go but the atmosphere. That is the physics being adopted, and it\n")
cat("  is a MODEL CLAIM at the far end of the app's slider rather than a fitted\n")
cat("  result. The log form's answer there is not a safe fallback -- it says the\n")
cat("  same pulse nearly VANISHES in 100 years, which is worse and in the\n")
cat("  direction that flatters the scenario.\n")

cat("\n--- gate 12 (Joos IRF), measured separately ---------------------\n")
cat("  diag_joos_beta_scan.R takes the same env vars:\n")
cat("    CCX_FERT_FORM=1 CCX_FERT_BETA_MAX=<bmax> CCX_FERT_K=<K> \\\n")
cat("      Rscript calibration/diag_joos_beta_scan.R\n")
cat("  Measured 2026-08-14, integrated IRF at TH 20/50/100 yr against Joos\n")
cat("  Table 4's 5-95 % of 12.2-16.3 / 24.0-36.6 / 39.5-65.2:\n\n")
cat("    log beta 0.75 (superseded) 10.4 / 19.9 / 31.2 FAIL x3\n")
cat("    log beta 0.50            12.2 / 25.0 / 41.1   inside, TH20 on the floor\n")
cat("    MM K=120 bmax=0.491      12.4 / 25.6 / 41.9   INSIDE x3 -- SHIPPED\n")
cat("    MM K=140 bmax=0.534      12.2 / 25.0 / 40.8   inside, TH20 on the floor\n")
cat("    MM K=171 bmax=0.600      12.0 / 24.3 / 39.4   FAIL at TH20 and TH100\n\n")
cat("  So gate 12 caps fert_k at roughly 150 on the criterion-(a) locus, and\n")
cat("  K=120 is the shortlist entry that passes it with room rather than on it.\n")
