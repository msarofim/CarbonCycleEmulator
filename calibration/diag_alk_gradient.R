# =====================================================================
# diag_alk_gradient.R -- SHOULD WE STOP HOLDING ALKALINITY FIXED?
# (Marcus 2026-08-16, in reply to the pump-form question raised by
#  calibration/diag_pump_vs_gradient_terms.R)
#
# THE QUESTION IS TWO QUESTIONS AND THEY HAVE DIFFERENT ANSWERS. Conflating
# them is what makes "free alkalinity" sound like one decision:
#
#   Q1. Is a CARBONATE LIMB blocked by fixed alkalinity?  (a representability
#       question about the pump)
#   Q2. Would an ALKALINITY TRACER change the model's UPTAKE?  (a physics
#       question about the mixed layer's buffer capacity)
#
# AND THERE IS A THIRD THING, WHICH IS THE ACTUAL PRIZE. GLODAPv2.2023 carries
# `G2talk`, on disk in the master file this repo already downloaded. The
# OBSERVED alkalinity gradient sizes the carbonate limb DIRECTLY, on the same
# fixed depths as the shipped DIC and d13C targets -- so the carbonate share
# does not have to be inferred from d13C at all. That is a free observation
# nobody has looked at, and it does not require freeing anything.
#
# WHAT ALKALINITY DOES IN THIS MODEL TODAY, checked rather than recalled
# (grep ALK_SURFACE): it enters the MIXED-LAYER carbonate solve and nowhere
# else -- ccx_dic_for_pco2() in the spinup, pco2_from_dic() in the air-sea
# flux, and a revelle_factor() diagnostic. THE INTERIOR HAS NO ALKALINITY AND
# NO CARBONATE CHEMISTRY; interior DIC is a passive tracer.
#
# THE ANSWER TO Q1, WHICH FOLLOWS FROM THAT AND NEEDS NO RUN. A carbonate limb
# is a second export field with its own d13C signature. The interior receives
# it as passive tracer, exactly as it receives the soft-tissue limb. The mixed
# layer's DIC is pinned by (pCO2, ALK, SST), so removing carbon from it is
# replenished by air-sea exchange with the same zero effect on the anthropogenic
# perturbation that diag_dic_gradient.R part 3 measured for the soft-tissue limb
# (+0.000000 GtC/yr). SO THE CARBONATE LIMB IS NOT BLOCKED BY FIXED ALKALINITY,
# and DESIGN sec.5.2c's "second structural commitment" overstated it -- corrected
# there. What fixed alkalinity suppresses is the RETURN: deep alkalinity rising
# and diffusing back to the surface. That is Q2, and it is what this file prices.
#
# RUNTIME ~2 min, dominated by one pass over the 894 MB GLODAP master.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "pump_shim.R"))

# ---- named constants -------------------------------------------------
AK_MASTER   <- ccx_path("data-raw", "downloads",
                        "GLODAPv2.2023_Merged_Master_File.csv")
AK_SUBSET   <- ccx_path("data-raw", "downloads", "glodap_talk_subset.csv")
AK_FLAG_OK  <- PUMP_FLAG_OK          # GLODAP: 2 = acceptable measurement
AK_DLAT <- PUMP_DLAT; AK_DLON <- PUMP_DLON; AK_DZ <- PUMP_DZ
# Redfield-type alkalinity bookkeeping. CaCO3 dissolution adds 2 mol ALK per mol
# C; soft-tissue remineralization RELEASES nitrate and so REMOVES ~1 mol ALK per
# mol N, i.e. ~N:C per mol C. Both are standard; the N:C is the Anderson-Sarmiento
# stoichiometry this file takes as a recollected working value, NOT a fitted one.
AK_ALK_PER_CARB <- 2.0
AK_NC_RATIO     <- 16 / 117          # ~0.137 mol N per mol C
AK_PCO2_PI      <- ccx_const("CO2_PI_PPM")
AK_D13C_CARB    <- 2.0               # permil, marine biogenic CaCO3, as
                                     # calibration/diag_dic_gradient.R part 5
# What the TRANSIENT terms say the pump must supply, from
# calibration/diag_pump_vs_gradient_terms.R part 3 (mode, h_ml = 100).
D13_TRA         <- -1.8777           # permil
AK_OUTDIR       <- ccx_path("calibration", "output", "alk_gradient")

dir.create(AK_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

tg <- ccx_ocean_gradient_target()
stopifnot(!is.null(tg))

# =====================================================================
# PART 1. THE OBSERVED ALKALINITY GRADIENT, ON THE SHIPPED FIXED DEPTHS
# =====================================================================
# Same binning and cos(lat) cell weighting as the shipped DIC/d13C targets
# (pump_shim.R's dg_bin), so the three gradients are commensurable.
sep("PART 1. GLODAPv2.2023 ALKALINITY ON THE SHIPPED LAYERS")
if (!file.exists(AK_SUBSET)) {
  cat("extracting G2talk from the master file (one pass, ~1 min)...\n")
  need <- c("G2latitude", "G2longitude", "G2depth", "G2talk", "G2talkf")
  hdr  <- strsplit(readLines(AK_MASTER, n = 1), ",")[[1]]
  stopifnot(all(need %in% hdr))
  cls  <- ifelse(hdr %in% need, "numeric", "NULL")
  d    <- utils::read.csv(AK_MASTER, colClasses = cls)
  names(d) <- c("lat", "lon", "depth", "talk", "talkf")[
    match(names(d), c("G2latitude", "G2longitude", "G2depth", "G2talk", "G2talkf"))]
  utils::write.csv(d, AK_SUBSET, row.names = FALSE)
  cat(sprintf("written: %s (%d rows)\n", AK_SUBSET, nrow(d)))
}
alk <- utils::read.csv(AK_SUBSET)

#' Volume-weighted mean alkalinity over a depth slab, same recipe as dg_bin()
ak_bin <- function(zmin, zmax) {
  ok <- is.finite(alk$talk) & alk$talk > -900 &
        is.finite(alk$talkf) & alk$talkf == AK_FLAG_OK &
        alk$depth >= zmin & alk$depth < zmax
  x    <- alk[ok, ]
  id   <- paste(floor(x$lat / AK_DLAT), floor(x$lon / AK_DLON),
                floor(x$depth / AK_DZ))
  cell <- tapply(x$talk, id, mean)
  w    <- cos(tapply(x$lat, id, mean) * pi / 180)
  list(n = sum(ok), n_cells = length(cell), raw = mean(x$talk),
       vw = sum(cell * w) / sum(w), sd = stats::sd(cell))
}
a_s <- ak_bin(tg$dic$layer_surf[1], tg$dic$layer_surf[2])
a_d <- ak_bin(tg$dic$layer_deep[1], tg$dic$layer_deep[2])
# THE SHIPPED TARGET IS AUTHORITATIVE, not this file's recomputation. They differ
# by ~0.4 umol/kg for a reason worth knowing: pump_shim.R's dg_bin() takes
# `depth < zmax` and the build script's gd_binned() takes `depth <= zmax`, so the
# bottles sitting exactly at 100 m are in one and not the other. Everything below
# uses the build product; the local number is printed beside it as a cross-check.
d_alk_local <- a_d$vw - a_s$vw
d_alk <- if (!is.null(tg$alk)) tg$alk$target else d_alk_local

cat(sprintf("%-10s %8s %8s %10s %10s %8s\n", "layer", "n", "cells", "ALK vw", "ALK raw", "cell sd"))
cat(sprintf("%-10s %8d %8d %10.1f %10.1f %8.1f\n",
            sprintf("%g-%g m", tg$dic$layer_surf[1], tg$dic$layer_surf[2]),
            a_s$n, a_s$n_cells, a_s$vw, a_s$raw, a_s$sd))
cat(sprintf("%-10s %8d %8d %10.1f %10.1f %8.1f\n",
            sprintf(">%g m", tg$dic$layer_deep[1]),
            a_d$n, a_d$n_cells, a_d$vw, a_d$raw, a_d$sd))
cat(sprintf("\nSHIPPED ALKALINITY GRADIENT (the build product): %+.4f umol/kg\n", d_alk))
cat(sprintf("this file's own recomputation:                   %+.4f  (diff %+.4f)\n",
            d_alk_local, d_alk_local - d_alk))
cat("  -- the difference is the depth-boundary convention, not a disagreement:\n")
cat("     dg_bin() takes `depth < zmax`, gd_binned() takes `depth <= zmax`, so the\n")
cat("     bottles exactly at 100 m are in one and not the other. Build wins.\n")
cat(sprintf("model's fixed ALK_SURFACE:                       %.1f umol/kg\n",
            ccx_const("ALK_SURFACE") * 1e6))
if (!is.null(tg$alk))
  cat(sprintf("\nSIGMA is now a BLOCK BOOTSTRAP ON THE CONTRAST: %.4f umol/kg (30 deg %.4f),\n",
              tg$alk$sd, tg$alk$sd_by_block[["blk30"]]))
cat(sprintf("i.e. the model's zero gradient is a %.2f sigma miss and the row is in the\n",
            if (is.null(tg$alk)) NA_real_ else tg$alk$target / tg$alk$sd))
cat("objective as `ocean_grad_alk`. The cell spread printed above is NOT that sigma.\n")

# =====================================================================
# PART 2. THE CARBONATE LIMB, SIZED THREE WAYS
# =====================================================================
# ALK bookkeeping:  d(ALK) = 2 * C_carb - (N:C) * C_org,  with C_carb + C_org
# the DIC gradient the pump must supply. Solve for the carbonate share implied
# by the OBSERVED alkalinity gradient, and set it beside the two shares the
# d13C row implies under the two scorings.
sep("PART 2. HOW BIG IS THE CARBONATE LIMB? THREE INDEPENDENT ANSWERS")
# from ALK: 2*Cc - r*(D - Cc) = d_alk  =>  Cc = (d_alk + r*D) / (2 + r)
ak_share <- function(D) (d_alk + AK_NC_RATIO * D) / ((AK_ALK_PER_CARB + AK_NC_RATIO) * D)
D_obs <- tg$dic$target                       # +233.109, the observed gradient
D_tra <- 280.2                               # what the TRANSIENT terms demand
                                             # (diag_pump_vs_gradient_terms.R part 3)
cat(sprintf("%-46s %12s %12s\n", "route", "carbonate %", "C_carb"))
cat(sprintf("%-46s %11.0f %% %11.1f\n",
            "OBSERVED alkalinity gradient, on the obs DIC gradient",
            100 * ak_share(D_obs), ak_share(D_obs) * D_obs))
cat(sprintf("%-46s %11.0f %% %11.1f\n",
            "OBSERVED alkalinity gradient, on the transient demand",
            100 * ak_share(D_tra), ak_share(D_tra) * D_tra))
cat(sprintf("%-46s %11.0f %% %11.1f\n",
            "d13C row, PREINDUSTRIAL arithmetic (eps_eff -8.40)", 56, 130.6))
cat(sprintf("%-46s %11.0f %% %11.1f\n",
            "d13C row, TRANSIENT demand (eps* -14.55)", 26, 0.26 * D_tra))
cat("\nTHE COMPARISON IS THE POINT. The alkalinity gradient is a DIFFERENT\n")
cat("observation from d13C and it is not contaminated the way d13C is: ALK is\n")
cat("near-conserved, so it carries no Suess signal and essentially no C_ant, and\n")
cat("the preindustrial/transient distinction that trapped the d13C arithmetic\n")
cat("does not bite here. If the ALK-implied share matches the TRANSIENT d13C\n")
cat("share, two independent observations agree and the two-limb pump is pinned.\n")
cat("If it matches the PREINDUSTRIAL one instead, the transient reasoning in\n")
cat("diag_pump_vs_gradient_terms.R is wrong and that is the finding.\n")

# ---------------------------------------------------------------------
# PART 2b. CLOSE THE LOOP: does the ALK-implied split PREDICT the d13C row?
# ---------------------------------------------------------------------
# Three gradients, three independent observations, one pump. The split is fixed
# by ALK; the fractionation is fixed by stoichiometry; so the d13C gradient is
# then a PREDICTION with nothing left to tune. Run it against BOTH scorings --
# that is the test that separates them, and it uses no model output at all
# beyond the two numbers the model says the pump must supply.
sep("PART 2b. THE d13C GRADIENT, PREDICTED FROM THE ALK SPLIT")
d13_surf  <- dg_bin("c13", "c13f", tg$d13c$layer_surf[1], tg$d13c$layer_surf[2])$vw
dic_deep  <- dg_bin("tco2", "tco2f", tg$dic$layer_deep[1], tg$dic$layer_deep[2])$vw
ak_pred_d13 <- function(D) {
  f  <- ak_share(D)
  (PUMP_EPS_ORG * (1 - f) * D + (AK_D13C_CARB - d13_surf) * f * D) / dic_deep
}
cat(sprintf("observed surface d13C %+.3f permil, deep DIC %.1f umol/kg, CaCO3 at %+.1f\n\n",
            d13_surf, dic_deep, AK_D13C_CARB))
cat(sprintf("%-42s %12s %12s %8s\n", "scoring", "predicted", "required", "ratio"))
cat(sprintf("%-42s %+12.3f %+12.3f %8.2f\n", "PREINDUSTRIAL (D = observed gradient)",
            ak_pred_d13(D_obs), tg$d13c$target, ak_pred_d13(D_obs) / tg$d13c$target))
cat(sprintf("%-42s %+12.3f %+12.3f %8.2f\n", "TRANSIENT (D = what the model needs)",
            ak_pred_d13(D_tra), D13_TRA, ak_pred_d13(D_tra) / D13_TRA))
cat("\nCAVEAT, stated rather than buried: the surface d13C used above is MODERN and\n")
cat("therefore Suess-depleted, which is the right value for the transient row and\n")
cat("the wrong one for the preindustrial row. It enters only through the small\n")
cat("carbonate term, so it cannot manufacture the difference between the rows.\n")

# =====================================================================
# PART 3. WHAT AN ALKALINITY TRACER WOULD BUY -- Q2, PRICED
# =====================================================================
# Fixed ALK suppresses ONE channel: deep alkalinity rising under a carbonate
# pump and diffusing back to the mixed layer, which raises ML DIC at fixed pCO2
# and changes the buffer capacity. Price it BEFORE building a fourth tracer
# through the state, the C++ core, the Newton spinup and the parity tests.
sep("PART 3. THE ML SENSITIVITY TO ALKALINITY -- THE CHANNEL FIXED ALK SUPPRESSES")
sst <- ccx_prepare(ccx_default_params())$sst
A0  <- ccx_const("ALK_SURFACE")
cat(sprintf("%-6s %9s %12s %12s %12s %10s\n", "hemi", "SST", "DIC(A0)",
            "dDIC/dALK", "Revelle(A0)", "dR/dALK"))
sens <- lapply(HEMIS, function(h) {
  dA  <- 10e-6
  d0  <- ccx_dic_for_pco2(AK_PCO2_PI, A0, sst[[h]])
  d1  <- ccx_dic_for_pco2(AK_PCO2_PI, A0 + dA, sst[[h]])
  r0  <- revelle_factor(d0, A0, sst[[h]])
  r1  <- revelle_factor(d1, A0 + dA, sst[[h]])
  cat(sprintf("%-6s %9.2f %12.1f %12.3f %12.3f %10.4f\n", h, sst[[h]], d0 * 1e6,
              (d1 - d0) / dA, r0, (r1 - r0) / dA * 1e-6 * 1e6))
  c(dDIC_dALK = (d1 - d0) / dA, R0 = r0, dR_dALK = (r1 - r0) / dA)
})
names(sens) <- HEMIS
dR <- mean(vapply(sens, function(s) s[["dR_dALK"]], numeric(1)))
R0 <- mean(vapply(sens, function(s) s[["R0"]], numeric(1)))
cat(sprintf("\nRevelle factor at ALK_SURFACE: %.3f.  d(Revelle)/d(ALK) = %.4f per umol/kg\n",
            R0, dR * 1e-6))
cat("\nTHE BOUND, AND WHY IT IS SMALL. The model already sets ALK_SURFACE to the\n")
cat(sprintf("OBSERVED surface value (%.0f vs GLODAP's %.0f umol/kg on the shipped\n",
            A0 * 1e6, a_s$vw))
cat("surface layer). A tracer cannot improve on that at the PRESENT DAY -- it can\n")
cat("only let the modelled surface ALK DRIFT away from it. The channel is\n")
cat("therefore the TRANSIENT drift in surface ALK over 1750-2024, and alkalinity\n")
cat("is near-conserved on that timescale. For each 10 umol/kg of surface-ALK\n")
cat(sprintf("drift the Revelle factor moves %.4f (%.2f %%), i.e. the buffer capacity\n",
            10 * dR * 1e-6, 100 * 10 * dR * 1e-6 / R0))
cat("moves by about that in the opposite direction. Set that against `h_ml`,\n")
cat("which handoff 15c argues is faking uptake at the ~150 m level.\n")
cat("\nSO: Q1 needs no tracer, and Q2's channel is the drift, not the level.\n")
cat("A tracer is the honest way to GET the drift -- but part 2 above is the\n")
cat("cheaper prize and it needs nothing freed at all.\n")

saveRDS(list(surf = a_s, deep = a_d, d_alk = d_alk,
             share_obs = ak_share(D_obs), share_transient = ak_share(D_tra),
             sens = sens),
        file.path(AK_OUTDIR, "diag_alk_gradient.rds"))
cat(sprintf("\n\nwritten: %s\n", file.path(AK_OUTDIR, "diag_alk_gradient.rds")))
