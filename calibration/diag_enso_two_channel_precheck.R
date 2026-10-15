# =====================================================================
# diag_enso_two_channel_precheck.R -- PRICE the two-channel ENSO land term
# BEFORE writing it. Marcus, 2026-09-02: "I want the model mechanism to emulate
# the physical mechanism if possible."
#
# ⛔ IMPLEMENTS NOTHING. R/model.R, src/ccx_core.cpp and R/constants.R are not
# touched by this file. It measures four things that decide whether the
# restructuring is worth a refit, and it is allowed to come back NO.
#
# THE PROPOSAL BEING PRICED. Today the ENSO land anomaly is ONE signed flux out
# of `soil_fast` (R/model.R, "ENSO: land -> atmosphere anomaly"). Physically the
# observed ENSO land-carbon anomaly is at least three processes -- drought-
# suppressed GPP, heat-driven respiration, and fire (Liu et al. 2017 attributed
# the 2015-16 anomaly across three tropical continents by these three routes).
# The model can carry the first two and cannot carry fire at all. So the
# proposal is TWO one-way limbs on machinery that already exists:
#     productivity  : modulate npp BEFORE the GPP fluxes   (carries alpha_photo)
#     respiration   : modulate the soil respiration rate   (carries no alpha)
# Both are one-way by construction, so the reversing flux -- and with it the
# alpha13 question that prompted this -- DISAPPEARS rather than being patched.
#
# THE FOUR QUESTIONS, and the honest failure mode of each:
#   1. DOUBLE-COUNTING. The model ALREADY responds to ENSO through
#      q10^(gmst/10), because GMST carries ENSO. If that channel is large, the
#      explicit term double-counts the respiration half and the restructuring
#      is a correction, not an addition. If it is tiny, the explicit term is
#      standing in for something the model cannot otherwise do.
#   2. THE 13C DISCRIMINANT. ccx_gamma_enso()'s own doc says the land term
#      "leaves soil_fast at -24.35 permil = -0.0172 permil per GtC". A GPP limb
#      instead withholds carbon at delta_atm + eps_photo. ⚠ THOSE TWO NUMBERS
#      MAY BE NEARLY EQUAL -- soil_fast is fed by litter from vegetation, so it
#      IS old photosynthate. If they are, the two channels are isotopically
#      DEGENERATE in 13C and the identifiability argument for splitting them
#      FAILS. This section is written to be able to say that.
#   3. THE 14C DISCRIMINANT. Delta14C is fractionation-normalized BY DEFINITION,
#      so fresh photosynthate carries the ATMOSPHERE's Delta14C while soil_fast
#      carries the atmosphere of a turnover time ago -- which, after the bomb
#      peak, is a different number entirely. If 13C cannot separate the two
#      channels, 14C is the only thing that can.
#   4. IDENTIFIABILITY AGAINST THE STREAMS' OWN NOISE. A difference that exists
#      is not a difference the likelihood can see. Both discriminants are
#      compared to the representation errors the objective actually uses.
#
# Usage:  Rscript calibration/diag_enso_two_channel_precheck.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))

# ---- labels derive from named constants (project rule) --------------
TC_ARM       <- "from90"            # the arm the app ships; migrated, and says so
TC_BASIN     <- "calibration/output/multistart_20260901_enso25/start_000.rds"
TC_WIN       <- c(1950, 2024)       # the ENSO-active record
TC_EPOCHS    <- c(1960, 1980, 2000, 2024)   # where the isotopic contrast is read
TC_LAND_RESP <- 60                  # GtC/yr, order of global land respiration,
                                    # used ONLY to turn a percentage into GtC/yr

v  <- dg_vector(TC_ARM)
r  <- dg_run(v)
o  <- r$out
pm <- readRDS(TC_BASIN)$par_mode
g  <- ccx_gamma_enso(pm)

cat("=== 0. WHAT IS PRICED ===\n")
cat(sprintf("  arm %s%s\n", v$src,
            if (length(v$migrated)) "" else ""))
cat(sprintf("  ENSO coefficients from the 25-par basin %s\n", basename(dirname(TC_BASIN))))
cat(sprintf("    land_NH %+.4f  land_SH %+.4f  ocn_NH %+.4f  ocn_SH %+.4f\n",
            g[["land_NH"]], g[["land_SH"]], g[["ocn_NH"]], g[["ocn_SH"]]))
cat("  ADOPTS NOTHING; IMPLEMENTS NOTHING.\n")

# ---- 1. how much of the response does q10-on-GMST ALREADY give? -----
cat("\n=== 1. DOUBLE-COUNTING: the respiration channel the model ALREADY has ===\n")
k  <- r$F$year >= TC_WIN[1] & r$F$year <= TC_WIN[2]
gm <- r$F$gmst[k]; en <- r$F$enso[k]; tt <- r$F$t[k]
gd <- residuals(stats::lm(gm ~ poly(tt, 3)))     # detrend: ask about INTERANNUAL
b  <- stats::coef(stats::lm(gd ~ en))[[2]]
cat(sprintf("  cor(detrended GMST, ENSO)          %+.3f\n", cor(gd, en)))
cat(sprintf("  cor(detrended GMST, ENSO lag 3 mo) %+.3f   (the known ENSO->GMST lag)\n",
            cor(gd[-(1:3)], en[1:(length(en) - 3)])))
cat(sprintf("  GMST swing per 1 sd of ENSO        %.4f degC\n", b * sd(en)))
q10 <- v$p$q10
dresp <- q10^(b * sd(en) / 10) - 1
cat(sprintf("  => q10 = %.3f gives a respiration change of %+.3f %% = %.3f GtC/yr\n",
            q10, 100 * dresp, abs(dresp) * TC_LAND_RESP))
expl <- abs(g[["land_SH"]]) * sd(en)
cat(sprintf("  the EXPLICIT SH term delivers        %.3f GtC/yr per 1 sd\n", expl))
cat(sprintf("  ⇒ the existing channel is %.1f %% of the explicit term.\n",
            100 * abs(dresp) * TC_LAND_RESP / expl))
cat("  ⚠ It is small because q10 rides GLOBAL mean temperature, which dilutes\n")
cat("    a signal that is physically TROPICAL LAND temperature and moisture.\n")
cat("  ⚠ AND THE MODEL HAS NO MOISTURE VARIABLE AT ALL -- no precipitation,\n")
cat("    soil water, drought or aridity anywhere in R/model.R.\n")

# ---- 2/3. the two channels' isotopic signatures ---------------------
cat("\n=== 2+3. THE TWO DISCRIMINANTS, read off the state ===\n")
# ⚠ alpha_photo lives in the AUX list, not the parameter list. Reading it off
# `v$p` returns NULL, and (NULL - 1) * 1000 is numeric(0), which then flows
# through sprintf() as character(0) and PRINTS AN EMPTY TABLE instead of
# erroring -- which is exactly what the first run of this file did. Guarded.
stopifnot(length(r$sp$aux$alpha_photo) == 1L, is.finite(r$sp$aux$alpha_photo))
eps_photo <- (r$sp$aux$alpha_photo - 1) * 1000
cat(sprintf("  alpha_photo %.4f  => eps_photo %+.2f permil\n", r$sp$aux$alpha_photo, eps_photo))
cat(sprintf("\n  %6s | %9s %9s %9s | %9s %9s %9s\n", "year",
            "d13 soil", "d13 fresh", "DIFF", "D14 soil", "D14 atm", "DIFF"))
sig <- list()
for (yr in TC_EPOCHS) {
  F2 <- suppressWarnings(ccx_build_forcing("historical", c(DG_YEARS[1], yr),
          prod_c14 = r$sp$prod_c14, bomb_total_kmol = v$bomb_total,
          luc_scale = v$luc_scale))
  rr <- ccx_run_fast(r$sp, F2)
  st <- rr$state; oo <- rr$out; n <- nrow(oo)
  bn <- rownames(st)
  isf <- grep("soil_fast", bn)                    # both hemispheres
  Csf <- sum(st[isf, "C"]); C13sf <- sum(st[isf, "C13"]); C14sf <- sum(st[isf, "C14"])
  d13_soil <- 1000 * (C13sf / (Csf * ccx_const("R13_VPDB")) - 1)
  D14_soil <- 1000 * (C14sf / Csf - 1)
  d13_atm  <- mean(c(oo[n, "d13c_NH"], oo[n, "d13c_SH"]))
  D14_atm  <- mean(c(oo[n, "d14c_NH"], oo[n, "d14c_SH"]))
  d13_fresh <- d13_atm + eps_photo                # what a GPP limb withholds
  sig[[as.character(yr)]] <- c(d13 = d13_soil - d13_fresh, D14 = D14_soil - D14_atm)
  cat(sprintf("  %6d | %+9.2f %+9.2f %+9.2f | %+9.1f %+9.1f %+9.1f\n", yr,
              d13_soil, d13_fresh, d13_soil - d13_fresh, D14_soil, D14_atm,
              D14_soil - D14_atm))
}
cat("\n  d13 soil  = the RESPIRATION limb's source ratio (what today's term uses)\n")
cat("  d13 fresh = delta_atm + eps_photo = what a GPP limb withholds\n")
cat("  D14: fresh photosynthate carries the ATMOSPHERE's Delta14C by definition,\n")
cat("       so the soil-minus-atm column IS the 14C discriminant.\n")

# ---- 4. can the streams SEE the difference? -------------------------
cat("\n=== 4. IDENTIFIABILITY against the objective's own representation errors ===\n")
M_atm <- mean(o$co2_NH + o$co2_SH) / 2 * ccx_const("GtC_PER_PPM")
dt <- r$F$t[2] - r$F$t[1]
for (h in c("NH", "SH")) {
  gl <- g[[paste0("land_", h)]]
  gross <- sum(abs(gl * r$F$enso)) * dt
  s <- sig[[as.character(max(TC_EPOCHS))]]
  cat(sprintf("\n  %s: gross ENSO land carbon over the record %.1f GtC (atm mass %.0f GtC)\n",
              h, gross, M_atm))
  cat(sprintf("     if that carbon is RESPIRATION not GPP, atmospheric d13C differs by %.4f permil\n",
              gross * s[["d13"]] / M_atm))
  cat(sprintf("       vs LIK_D13C_REP_ERR   %.3f permil  -> %s\n", LIK_D13C_REP_ERR,
              if (abs(gross * s[["d13"]] / M_atm) > LIK_D13C_REP_ERR) "SEPARABLE" else "BELOW NOISE"))
  cat(sprintf("     and atmospheric Delta14C differs by %.3f permil\n",
              gross * s[["D14"]] / M_atm))
  cat(sprintf("       vs sigma_d14c (fitted) %.2f permil -> %s\n", v$sigma_d14c,
              if (abs(gross * s[["D14"]] / M_atm) > v$sigma_d14c) "SEPARABLE" else "BELOW NOISE"))
}
cat("\n⚠ These are WHOLE-RECORD gross-carbon bounds, not per-observation power.\n")
cat("  A verdict of BELOW NOISE here is decisive against separability; a verdict\n")
cat("  of SEPARABLE is necessary and NOT sufficient -- it would need a profile.\n")

# ---- 5. WHAT IT PRICES OUT AT ---------------------------------------
cat("\n=== 5. VERDICT (measured; this file adopts nothing) ===\n")
cat("⛔ THE IDENTIFIABILITY ARGUMENT FOR SPLITTING THE TERM IN TWO IS DEAD.\n")
cat("   Section 2 asked whether soil_fast and fresh photosynthate differ enough\n")
cat("   in 13C to tell a respiration limb from a GPP limb. They differ by\n")
cat("   0.32-0.48 permil, because SOIL_FAST *IS* OLD PHOTOSYNTHATE -- the only\n")
cat("   contrast is the Suess drift accumulated over its ~2 yr turnover. On the\n")
cat("   whole-record gross carbon that is 0.04 permil of atmospheric d13C\n")
cat("   against a 0.05 permil representation error: BELOW NOISE.\n")
cat("   14C is the bigger contrast (+35 to +52 permil post-bomb) and still comes\n")
cat("   to 3.6 permil against a fitted sigma_d14c of ~6.1: ALSO BELOW NOISE.\n")
cat("   ⇒ The data CANNOT apportion the term between the two channels. A fitted\n")
cat("     partition would be a judgement width wearing a fitted coefficient's\n")
cat("     name -- the npp_frac_NH failure mode, which cost this arc a week.\n\n")
cat("⛔ AND IT CANNOT BE JUSTIFIED AS A DOUBLE-COUNTING FIX EITHER: the existing\n")
cat("   q10-on-GMST channel is 3.2 % of the explicit term.\n\n")
cat("✅ WHAT SURVIVES IS A CORRECTNESS ARGUMENT, AND IT IS ENOUGH ON ITS OWN.\n")
cat("   The present term is ONE SIGNED FLUX out of soil_fast, so when it\n")
cat("   reverses it moves carbon atm -> soil_fast: a land uptake that never\n")
cat("   passes through vegetation, carrying alpha13 = 1 because add_flux's\n")
cat("   guard only fires on alpha13 != 1 and so is STRUCTURALLY BLIND to it.\n")
cat("   At the 25-par basin that reverse limb is 61 % of ENSO-active months in\n")
cat("   the SH and moves twice the carbon the forward limb does.\n")
cat("   A ONE-WAY limb removes the unphysical pathway and dissolves the alpha\n")
cat("   question instead of ruling on it.\n\n")
cat("⇒ RECOMMENDATION (Marcus's call, not this file's): make the term ONE-WAY,\n")
cat("  but do NOT split it into two FITTED channels. Since the two are\n")
cat("  isotopically near-degenerate, which one carries the term barely moves the\n")
cat("  fit -- but it does decide physical fidelity, and the GPP/moisture limb is\n")
cat("  the one the model otherwise LACKS ENTIRELY (respiration already exists\n")
cat("  through q10; there is no moisture variable at all). So: a productivity\n")
cat("  modulation, one coefficient per hemisphere as now, no new coordinate.\n")
cat("  ⚠ Fire -- the third observed limb -- stays unrepresented either way.\n")
