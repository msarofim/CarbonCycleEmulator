# =====================================================================
# diag_rep_dc_mass_weighting.R -- T3: HOW BIG IS THE SURFACE-vs-MASS-WEIGHTED
# TERM, and which way does it push `rep_dC`?
#
# WHY (Marcus, 2026-09-22: "how can we test its potential impact?"). Appendix A
# §A4 of the app review flagged that the model's box is converted as a
# MASS-WEIGHTED WHOLE-ATMOSPHERE mean while every observational comparator is a
# SURFACE mean, said the correction is NEGATIVE, and never put a number on it.
# Appendix B repeated the flag and called it "a modeling question, not a
# measurement, and nothing here settles it." That is half right: the SIZE is
# arithmetic from stated inputs, and the size is what decides whether this term
# is a footnote or a third of the discrepancy the prior is being asked to carry.
#
# ⛔ THE MODEL'S CODE DISAGREES WITH ITSELF ABOUT WHICH MEAN THE BOX IS, and the
# disagreement lies exactly on this axis:
#   * R/model.R:3874  `gtc_per_ppm_hemi = GtC_PER_PPM / 2` -- GtC_PER_PPM is the
#     WHOLE-ATMOSPHERE conversion (dry air mass 5.1352e18 kg), so the box's ppm
#     is a mass-weighted whole-atmosphere mean.
#   * R/forcing.R:347 "The model's atmosphere is a single well-mixed TROPOSPHERE
#     per hemisphere with NO STRATOSPHERIC BOX", which is why the bomb-14C input
#     is a stratosphere-to-troposphere FLUX and not a production rate.
# Both statements are load-bearing where they sit. They cannot both describe the
# same box, and `rep_dC` is the parameter that absorbs the difference.
#
# WHAT IS COMPUTED, and every input is labeled OBSERVED / DERIVED / ASSUMED:
#   f_strat   the stratosphere's share of atmospheric mass        DERIVED
#   gamma     the CO2 growth rate over the comparison window      OBSERVED
#   Gamma     the MASS-WEIGHTED mean age of stratospheric air     ASSUMED (band)
#   D_strat = -f_strat * gamma * Gamma, the amount by which a mass-weighted mean
#             sits BELOW a tropospheric/surface mean for a tracer growing at
#             gamma whose stratospheric air is Gamma years old.
#
# ⚠ Gamma IS THE WEAK INPUT AND IT IS CARRIED AS A BAND, NOT A POINT. Mid- and
# upper-stratospheric mean ages of ~5 yr (Andrews et al. 2001,
# doi:10.1029/2001JD000465, as cited in Appendix A) are NOT the mass-weighted
# figure: stratospheric mass falls off with height, so roughly half of it sits
# in the lowermost stratosphere where air is much younger. Using 5 yr flat -- as
# a first pass at this number did -- overstates the term. The band is reported
# and the point estimate is the middle of it, never a single confident number.
#
# ⛔ NOTHING IS ADOPTED. This changes no parameter and no prior; it sizes a term
# so that R2 can be ruled on the right quantity.
#
# Usage:  Rscript calibration/diag_rep_dc_mass_weighting.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
MW_COMMIT <- ccx_git_stamp()
.root <- normalizePath(".")

MW_DATE <- format(Sys.Date(), "%Y%m%d")
MW_OUT  <- file.path(.root, "outputs", "diagnostics",
                     sprintf("rep_dc_mass_weighting_%s.log", MW_DATE))

# ---- INPUTS, each labeled ------------------------------------------
# ASSUMED. Textbook tropopause pressures, stated as inputs rather than measured
# here. The sensitivity to both is reported below, so the answer never rests on
# either being exactly right.
MW_PTROP_EQ   <- 100      # hPa, tropical tropopause
MW_PTROP_POLE <- 300      # hPa, polar tropopause
MW_PSURF      <- 1013.25  # hPa, standard surface pressure
# ASSUMED. The MASS-WEIGHTED mean age of stratospheric air, as a BAND. The low
# end is a lowermost-stratosphere value, the high end the mid/upper-stratosphere
# figure that a flat assumption would apply everywhere.
MW_AGE_BAND   <- c(1.5, 5.0)   # years
# The comparison window, matched to the flask-vs-MBL work (d13C stops 2014).
MW_WIN        <- c(1989, 2014)
# MEASURED elsewhere and reused, not re-derived: the marine hemispheric mean
# minus the station, from NOAA's MBL zonal reference over 1979-2025
# (calibration/diag_rep_dc_mbl_zonal.R, Appendix B of the 09-22 review).
MW_MBL_OFF    <- c(NH = 0.738, SH = 0.814)
# MEASURED 09-22 (z): what adding the continental sites does to the NH offset at
# their AREA weight. Used only to bound the continental term at its MASS share.
MW_CONT_AREA  <- c(NH = 0.493, SH = -0.018)
# ASSUMED/DERIVED. Continental boundary-layer air as a share of hemispheric
# atmospheric mass: land fraction x the BL's share of the column.
MW_LAND_FR    <- c(NH = 0.39, SH = 0.19)
MW_BL_MASS_FR <- 0.15

con <- file(MW_OUT, open = "wt")
say <- function(fmt, ...) {
  s <- if (length(list(...))) sprintf(fmt, ...) else fmt
  cat(s, "\n", sep = ""); cat(s, "\n", sep = "", file = con)
}

say("=====================================================================")
say("T3 -- THE SURFACE vs MASS-WEIGHTED TERM IN `rep_dC`")
say("  run     %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
say("  commit  %s", MW_COMMIT)
say("  window  %d-%d", MW_WIN[1], MW_WIN[2])
say("=====================================================================")

# ---- 0. WHAT THE BOX IS, from the code ------------------------------
say("\n0. WHAT THE MODEL'S BOX IS -- read off the code, not assumed")
say("  GtC_PER_PPM           %.4f  (%s)", ccx_const("GtC_PER_PPM"),
    CCX_CONSTANTS$GtC_PER_PPM$status)
say("  GtC_PER_PPM_DERIVED   %.4f  from dry atmospheric mass 5.1352e18 kg",
    ccx_const("GtC_PER_PPM_DERIVED"))
say("  ⇒ the conversion is WHOLE-ATMOSPHERE mass, so the box's ppm is a")
say("    mass-weighted whole-atmosphere mean (R/model.R:3874).")
say("  ⛔ BUT R/forcing.R:347 calls the same box 'a single well-mixed TROPOSPHERE")
say("    per hemisphere with no stratospheric box' -- which is why the bomb-14C")
say("    input is a stratosphere-to-troposphere FLUX. Both are load-bearing.")
say("    The two readings differ by exactly the term computed below.")

# ---- 1. f_strat, DERIVED --------------------------------------------
say("\n1. f_strat -- the stratosphere's share of atmospheric mass   [DERIVED]")
# Area-weighted mean tropopause pressure with p(phi) = p_eq + (p_pole-p_eq)sin^2(phi).
# Area weight is cos(phi) dphi, and int sin^2 cos / int cos = 1/3 over a hemisphere,
# so the area-weighted mean is p_eq + (p_pole - p_eq)/3 -- done as an integral
# anyway so the shape can be changed without redoing the algebra.
phi <- seq(0, pi / 2, length.out = 2001)
ptrop_phi <- MW_PTROP_EQ + (MW_PTROP_POLE - MW_PTROP_EQ) * sin(phi)^2
w <- cos(phi)
ptrop_bar <- sum(ptrop_phi * w) / sum(w)
f_strat <- ptrop_bar / MW_PSURF
say("  tropopause %g hPa at the equator to %g hPa at the pole   [ASSUMED]",
    MW_PTROP_EQ, MW_PTROP_POLE)
say("  area-weighted mean tropopause pressure  %.1f hPa", ptrop_bar)
say("  f_strat = p_trop / p_surf               %.4f", f_strat)
say("  sensitivity: a FLAT tropopause at %g hPa gives %.4f; at %g hPa gives %.4f",
    MW_PTROP_EQ, MW_PTROP_EQ / MW_PSURF, MW_PTROP_POLE, MW_PTROP_POLE / MW_PSURF)

# ---- 2. gamma, OBSERVED ---------------------------------------------
say("\n2. gamma -- the CO2 growth rate over the window             [OBSERVED]")
co2obs <- ccx_prepare_obs()$co2
gam <- sapply(c(MLO = "MLO", SPO = "SPO"), function(st) {
  d <- co2obs[co2obs$station == st & co2obs$year >= MW_WIN[1] & co2obs$year <= MW_WIN[2], ]
  unname(stats::coef(stats::lm(co2_ppm ~ decimal_date, data = d))[2])
})
gamma <- mean(gam)
say("  MLO %.3f   SPO %.3f   mean %.3f ppm/yr  (repo's own station series)",
    gam[["MLO"]], gam[["SPO"]], gamma)

# ---- 3. the term ----------------------------------------------------
say("\n3. D_strat = -f_strat * gamma * Gamma                       [Gamma ASSUMED]")
say("  Gamma = the MASS-WEIGHTED mean age of stratospheric air, carried as a band")
d_strat <- -f_strat * gamma * MW_AGE_BAND
say("  Gamma %.1f yr  ->  D_strat %+.2f ppm", MW_AGE_BAND[1], d_strat[1])
say("  Gamma %.1f yr  ->  D_strat %+.2f ppm", MW_AGE_BAND[2], d_strat[2])
say("  band  [%+.2f, %+.2f] ppm, midpoint %+.2f", d_strat[1], d_strat[2], mean(d_strat))
say("  ⚠ NEGATIVE: a mass-weighted mean sits BELOW a surface/tropospheric mean,")
say("    because the stratosphere is a few years behind a rising tracer.")

# ---- 4. the continental term at its MASS share ----------------------
say("\n4. the continental term, at MASS share rather than AREA share")
say("  09-22 (z) measured the continental sites' effect at their AREA weight:")
say("    NH %+.3f ppm   SH %+.3f ppm", MW_CONT_AREA[["NH"]], MW_CONT_AREA[["SH"]])
cont_mass <- MW_CONT_AREA * MW_LAND_FR * MW_BL_MASS_FR / 1
say("  continental BL as a share of hemispheric mass: NH %.3f   SH %.3f  [ASSUMED]",
    MW_LAND_FR[["NH"]] * MW_BL_MASS_FR, MW_LAND_FR[["SH"]] * MW_BL_MASS_FR)
say("  ⚠ an ORDER-OF-MAGNITUDE bound, not a measurement: it rescales an")
say("    area-weighted network difference by a mass fraction, which is right to")
say("    within a factor of a few and no better. NH %+.3f   SH %+.3f ppm",
    cont_mass[["NH"]], cont_mass[["SH"]])

# ---- 5. what the box SHOULD sit above its station by ----------------
say("\n5. ⭐ WHAT `rep_dC` SHOULD BE, and what it is")
md <- ccx_load_mode(CCX_MODE_CANONICAL)
rep_dC <- md$err$rep_dC
grad_off <- md$err$grad_off_co2
model_off <- c(NH = rep_dC - grad_off / 2, SH = rep_dC + grad_off / 2)
say("  %-42s %9s %9s", "", "NH", "SH")
say("  %-42s %+9.3f %+9.3f", "marine hemispheric mean - station [OBSERVED]",
    MW_MBL_OFF[["NH"]], MW_MBL_OFF[["SH"]])
say("  %-42s %+9.3f %+9.3f", "  + continental, at mass share [BOUND]",
    cont_mass[["NH"]], cont_mass[["SH"]])
say("  %-42s %+9.3f %+9.3f", "  + stratospheric deficit, midpoint",
    mean(d_strat), mean(d_strat))
exp_mid <- MW_MBL_OFF + cont_mass + mean(d_strat)
exp_lo  <- MW_MBL_OFF + cont_mass + d_strat[2]
exp_hi  <- MW_MBL_OFF + cont_mass + d_strat[1]
say("  %-42s %+9.3f %+9.3f", "= EXPECTED box - station", exp_mid[["NH"]], exp_mid[["SH"]])
say("  %-42s %9s %9s", "  (band over Gamma)",
    sprintf("%+.2f/%+.2f", exp_lo[["NH"]], exp_hi[["NH"]]),
    sprintf("%+.2f/%+.2f", exp_lo[["SH"]], exp_hi[["SH"]]))
say("  %-42s %+9.3f %+9.3f", "MODEL box - station (rep_dC -/+ grad/2)",
    model_off[["NH"]], model_off[["SH"]])
say("  %-42s %+9.3f %+9.3f", "DISCREPANCY", model_off[["NH"]] - exp_mid[["NH"]],
    model_off[["SH"]] - exp_mid[["SH"]])

say("\n  for contrast, the discrepancy WITHOUT this term (marine offset alone):")
say("  %-42s %+9.3f %+9.3f", "", model_off[["NH"]] - MW_MBL_OFF[["NH"]],
    model_off[["SH"]] - MW_MBL_OFF[["SH"]])
grew <- (model_off - exp_mid) / (model_off - MW_MBL_OFF)
say("  ⇒ the mass-weighting term makes the residue %.0f%% (NH) / %.0f%% (SH) LARGER.",
    100 * (grew[["NH"]] - 1), 100 * (grew[["SH"]] - 1))

# ---- 6. against what re-centering the prior would buy ----------------
# R2's cheapest option is to re-center the prior from 0 on the measured offset.
# That moves the prior's mean by exactly the measured offset, so the two terms
# are directly comparable in ppm -- and they point opposite ways.
say("\n6. AGAINST R2's CHEAPEST OPTION")
for (h in c("NH", "SH")) {
  relief <- MW_MBL_OFF[[h]]
  say("  %s: re-centring the prior on the measured offset moves it %+.2f ppm;", h, relief)
  say("      the mass-weighting term moves the TARGET %+.2f ppm the other way.",
      mean(d_strat))
  say("      ratio %.2f -- the term is %s than the whole relief re-centring buys.",
      abs(mean(d_strat)) / relief,
      if (abs(mean(d_strat)) > relief) "LARGER" else "smaller")
}

say("\n=====================================================================")
say("READING. The correction goes the WRONG WAY for `rep_dC`: it does not")
say("explain any of the offset, it enlarges what has to be explained -- and by")
say("more than re-centring the prior would relieve. So R2 should be ruled")
say("against the LARGER residue, not the smaller one. ⚠ Gamma is the weak input")
say("and is a BAND; an observational mass-weighted stratospheric age would")
say("close it, and is the one download that would sharpen this.")
say("⛔ Nothing adopted; no parameter and no prior is changed here.")
say("=====================================================================")
close(con)
cat("\nwritten: ", MW_OUT, "\n", sep = "")
