# =====================================================================
# diag_fixB_route1_solubility.R -- FIX B ROUTE 1: IS THE ENSO->OCEAN
#   SOLUBILITY PATH OVER-AMPLIFIED?
#
# The conveyor memo (2026-09-01) left three routes open for the ocean ENSO
# sign error. Route (a) -- "the SST/solubility path may simply be
# over-amplified -- testable by scaling it" -- has never been tested.
# 2026-09-04i killed routes via w_up/w_out on SIGN, so this is now the
# cheapest live option. Marcus: "Do route 1 first."
#
# THE PATH, AND WHERE IT COULD BE WRONG. ENSO reaches the ocean only through
#   nino34 -> (observed) hemispheric SST -> carbonate chemistry -> pCO2 -> flux
# The first arrow is DATA (HadSST4 via forcing_sst.rds), so it is not free to
# be wrong in amplitude. The second is the model's own emergent chemistry.
# ⇒ THE TESTABLE CLAIM IS THE CHEMISTRY: d ln pCO2 / dT against Takahashi's
# 4.23 %/degC, which this repo registers as SST_PCO2_SENSITIVITY and which the
# MODEL DOES NOT USE -- the carbonate module carries the full T dependence of
# K0/K1/K2 and the sensitivity is EMERGENT. So the constant is a genuine
# out-of-sample check, not a restatement.
#
# ⚠ NOTHING IS IMPLEMENTED, FITTED OR ADOPTED.
# Usage:  Rscript calibration/diag_fixB_route1_solubility.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))

R1_TAKAHASHI <- ccx_const("SST_PCO2_SENSITIVITY")   # 0.0423 /degC, PROVISIONAL
R1_DT        <- 0.5                                  # centred difference, degC
R1_ENSO_SOLUB<- -0.1274        # model slope, patch OFF (2026-09-04g sec.B4)
R1_ENSO_OBS  <-  0.1153        # GCB on Nino3.4, same measurement
R1_SCALES    <- c(0, 0.25, 0.5, 0.75, 1, 1.5)   # scale on the ENSO part of SST

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
obs <- ccx_prepare_obs()
v0  <- dg_vector(CCX_MODE_CANONICAL)

# ---------------------------------------------------------------------
sep("1. THE MODEL'S EMERGENT d ln pCO2 / dT, AT ITS OWN MIXED-LAYER STATE")
cat("  Pure chemistry: pco2_from_dic(DIC, ALK, T) at the model's own surface\n")
cat("  DIC and ALK, differenced in T. This is the Takahashi quantity -- at\n")
cat("  CONSTANT DIC and alkalinity -- so the comparison is like-for-like.\n\n")
sp  <- ccx_spinup(v0$p); aux <- sp$aux
grid <- ccx_ocean_grid(v0$p$h_ml); rho <- ccx_const("RHO_SEAWATER")
alk <- ccx_const("ALK_SURFACE")
cat(sprintf("  %-6s %8s %10s %12s %12s %10s\n",
            "hemis", "SST C", "DIC umol/kg", "pCO2(T-dT)", "pCO2(T+dT)", "dlnp/dT"))
sens <- c()
for (h in HEMIS) {
  ix  <- aux$idx[[h]]$ml
  dic <- sp$y[ix, "C"] * aux$mol_per_GtC / aux$ml_mass_kg[[h]]
  Tc  <- aux$sst[[h]]
  p1  <- pco2_from_dic(dic, alk, Tc - R1_DT)
  p2  <- pco2_from_dic(dic, alk, Tc + R1_DT)
  s   <- (log(p2) - log(p1)) / (2 * R1_DT)
  sens[h] <- s
  cat(sprintf("  %-6s %8.2f %10.1f %12.2f %12.2f %10.5f\n",
              h, Tc, dic * 1e6, p1, p2, s))
}
# area-weighted, the same weighting the flux uses
sw <- (sens[["NH"]] * aux$a_oc$NH + sens[["SH"]] * aux$a_oc$SH) /
      (aux$a_oc$NH + aux$a_oc$SH)
cat(sprintf("\n  area-weighted model  %.5f /degC\n", sw))
cat(sprintf("  Takahashi (registered) %.5f /degC   ->  MODEL IS %.2fx OBSERVED\n",
            R1_TAKAHASHI, sw / R1_TAKAHASHI))
cat("  ⚠ SST_PCO2_SENSITIVITY is status = 'provisional' and its own source note\n")
cat("    asks for the exact citation. The RATIO is the result; treat the\n")
cat("    denominator as the best available number, not as settled.\n")

# ---------------------------------------------------------------------
sep("2. IS THE ENSO SIGNAL IN THE MODEL'S SST FORCING RIGHT?")
cat("  The first arrow is DATA. Measured here so it is not assumed.\n\n")
en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds")))
en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
so <- as.data.frame(readRDS(ccx_path("data", "forcing_sst.rds")))
m  <- merge(so, en_ann, by = "year")
m  <- m[m$year >= 1959 & m$year <= 2024, ]
for (h in HEMIS) {
  f <- stats::lm(m[[paste0("sst_anom_", h)]] ~ year + nino34_anom, data = m)
  cf <- summary(f)$coefficients["nino34_anom", ]
  cat(sprintf("  d(SST_%s)/d(nino34) = %+.4f +- %.4f degC per index unit (t %+.1f)\n",
              h, cf[1], cf[2], cf[3]))
}

# ---------------------------------------------------------------------
sep("3. SCALING THE ENSO COMPONENT OF SST -- does the ocean slope follow?")
cat("  The ENSO part of each hemisphere's observed SST is isolated by\n")
cat("  regression and rescaled; everything else in the SST record is left\n")
cat("  alone. A LINEAR response confirms the path is what it looks like.\n\n")
sl <- vapply(HEMIS, function(h)
  unname(coef(stats::lm(m[[paste0("sst_anom_", h)]] ~ m$year + m$nino34_anom))[3]), 0)
enso_of <- function(F) {
  e <- stats::approx(en_ann$year + 0.5, en_ann$nino34_anom, xout = F$t, rule = 2)$y
  e - mean(e)
}
run_scaled <- function(k, patch_off = TRUE) {
  v <- v0
  if (patch_off) { v$p$gamma_enso_ocn_NH <- 0; v$p$gamma_enso_ocn_SH <- 0 }
  sp <- ccx_spinup(v$p)
  F  <- ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale)
  ee <- enso_of(F)
  for (h in HEMIS) F[[paste0("sst_anom_", h)]] <-
      F[[paste0("sst_anom_", h)]] + (k - 1) * sl[[h]] * ee
  o <- ccx_run_fast(sp, F)$out
  yy <- floor(o$t)
  ag <- stats::aggregate(ocean_C ~ yy, data.frame(yy = yy, ocean_C = o$ocean_C), FUN = mean)
  sk <- data.frame(year = ag$yy[-1], sink = diff(ag$ocean_C))
  mm <- merge(sk, en_ann, by = "year"); mm <- mm[mm$year >= 1959 & mm$year <= 2024, ]
  unname(coef(stats::lm(sink ~ year + nino34_anom, data = mm))["nino34_anom"])
}
cat(sprintf("  %8s %14s\n", "scale k", "ENSO slope"))
sc <- c()
for (k in R1_SCALES) { s <- run_scaled(k); sc[as.character(k)] <- s
  cat(sprintf("  %8.2f %+14.4f\n", k, s)) }
fit <- stats::lm(sc ~ R1_SCALES)
cat(sprintf("\n  linear in k?  intercept %+.4f, slope %+.4f, R2 %.5f\n",
            coef(fit)[1], coef(fit)[2], summary(fit)$r.squared))
cat(sprintf("  at k = 0 (ENSO removed from SST) the slope is %+.4f -- the part of the\n", sc[["0"]]))
cat("  solubility slope that is NOT the ENSO-driven SST signal.\n")

sep("4. WHAT ROUTE 1 WOULD BUY")
need <- R1_ENSO_OBS - R1_ENSO_SOLUB
cat(sprintf("  the patch must currently supply %+.4f GtC/yr per index unit\n", need))
k_zero <- -coef(fit)[1] / coef(fit)[2]
cat(sprintf("  scale that zeroes the solubility ENSO slope: k = %.2f\n", k_zero))
cat(sprintf("  scale implied by the chemistry ratio (1/%.2f): k = %.2f\n",
            sw / R1_TAKAHASHI, R1_TAKAHASHI / sw))
s_at <- coef(fit)[1] + coef(fit)[2] * (R1_TAKAHASHI / sw)
cat(sprintf("  ENSO slope at THAT scale: %+.4f (from %+.4f) -> the patch would still\n",
            s_at, sc[["1"]]))
cat(sprintf("  need %+.4f, i.e. %.0f%% of what it needs now.\n",
            R1_ENSO_OBS - s_at, 100 * (R1_ENSO_OBS - s_at) / need))
cat("\n  ⚠ CONDITIONAL: nothing re-optimised, patch held OFF. And note the sign\n")
cat("  never changes -- rescaling a wrong-signed path cannot make it right-signed,\n")
cat("  it can only make it SMALLER. Route 1 is a mitigation, not a fix.\n")

sep("DONE")
