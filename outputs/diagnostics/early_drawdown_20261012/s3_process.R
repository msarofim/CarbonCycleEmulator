source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/04e20996-bd05-4d13-9da3-fa0c74359cf1/scratchpad/early_drawdown/lib_ed.R")
OUT <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/04e20996-bd05-4d13-9da3-fa0c74359cf1/scratchpad/early_drawdown/out"
cat("commit:", ccx_git_stamp(), " mode:", CCX_MODE_CANONICAL, "\n")
v <- dg_vector(CCX_MODE_CANONICAL); spin <- dg_spinup(v); p <- v$p

# ---- PROCESS-ONLY changes, applied from JOOS_REF_YEAR (2010) with the arm's own history/state ----
# (the background is re-held by diagnosed emissions for every row, as ccx_pd100 does)
mod <- function(...) { q <- p; a <- list(...); for (n in names(a)) q[[n]] <- a[[n]]; q }
TESTS <- list(
  "canonical (p_after = p, null test)" = list(p_after = p),
  "kz x0.50"            = list(p_after = mod(kz = p$kz * 0.50)),
  "kz x0.75"            = list(p_after = mod(kz = p$kz * 0.75)),
  "kz x1.50"            = list(p_after = mod(kz = p$kz * 1.50)),
  "kz_deep_frac x0.5"   = list(p_after = mod(kz_deep_frac = p$kz_deep_frac * 0.5)),
  "k_w x0.50"           = list(p_after = mod(k_w = p$k_w * 0.50)),
  "k_w x2.00"           = list(p_after = mod(k_w = p$k_w * 2.00)),
  "hs_asx_frac x0.5"    = list(p_after = mod(hs_asx_frac = p$hs_asx_frac * 0.5)),
  "u_hs x0.5"           = list(p_after = mod(u_hs = p$u_hs * 0.5)),
  "beta_max x0.75"      = list(p_after = mod(beta_max = p$beta_max * 0.75)),
  "beta_max x0.50"      = list(p_after = mod(beta_max = p$beta_max * 0.50)),
  "tau_wood x0.5 [unfitted]" = list(p_after = mod(tau_wood = p$tau_wood * 0.5)),
  "npp_leaf_frac 0.8 [unfitted]" = list(p_after = mod(npp_leaf_frac = 0.8)),
  "NO fertilisation (beta_max 0)" = list(p_after = mod(beta_max = 0)),
  "NO ocean sink (k_w 1e-3)"      = list(p_after = mod(k_w = OCEAN_OFF_K_W)),
  "Revelle frozen at 1750"        = list(p_after = mod(revelle_frozen = 1)),
  "q10 = 1 (no resp. T-feedback)" = list(p_after = mod(q10 = 1)),
  "climate HELD (no pulse warming)" = list(p_after = NULL, climate = "held"))
rows <- list(); keep <- list()
for (nm in names(TESTS)) {
  tt <- TESTS[[nm]]
  o <- ed_pd100(v, spin, climate = if (is.null(tt$climate)) ED_CLIMATE else tt$climate, p_after = tt$p_after)
  rows[[nm]] <- ed_row(o, nm)
  keep[[nm]] <- o$d[o$t %in% c(0, ED_MARKS) | abs(o$t - round(o$t)) < 1e-9, ]
  cat(".")
}
cat("\n")
P <- do.call(rbind, rows); c0 <- P[1, ]
P$dIRF20 <- P$irf20 - c0$irf20; P$dIRF100 <- P$irf100 - c0$irf100; P$r20_100 <- P$dIRF20 / P$dIRF100
cat("=== PROCESS-ONLY (from 2010) ===\n")
print(format(P[, c("label", "irf1", "irf5", "irf20", "irf100", "dIRF20", "dIRF100", "r20_100", "th20", "th100",
                   "oc5", "ld5", "oc20", "ld20", "oc100", "ld100", "hold_dev", "target")], digits = 4), row.names = FALSE)
saveRDS(list(P = P, keep = keep), file.path(OUT, "s3_process.rds"))

# ---- FIRST PRINCIPLES at the release state (2015.0) ----
o <- ed_pd100(v, spin)
sp <- o$sp_rel; aux <- sp$aux; y <- sp$y; idx <- aux$idx
molGtC <- ccx_const("MOL_C_PER_GtC"); gpp <- ccx_const("GtC_PER_PPM")
chi <- o$target; C_atm <- chi * gpp
sstF <- c(NH = o$Fp$sst_anom_NH[1], SH = o$Fp$sst_anom_SH[1])
cat(sprintf("\nFIRST PRINCIPLES at release: held CO2 %.2f ppm, C_atm %.1f GtC (GtC_PER_PPM %.3f)\n", chi, C_atm, gpp))
cat("aux names with mass/area/sst/alk:", paste(grep("mass|^a_|sst|alk|asx|h_hs|hs_frac", names(aux), value = TRUE), collapse = ", "), "\n")
fp_rows <- list()
for (h in HEMIS) for (bx in c("ml", "hs")) {
  k <- idx[[h]][[bx]]; if (is.null(k)) next
  C <- y[k, "C"]
  mass <- if (bx == "ml") aux$ml_mass_kg[[h]] else aux$hs_mass_kg[[h]]
  if (is.null(mass)) { cat("no mass for", h, bx, "\n"); next }
  dic <- C * molGtC / mass
  # ML: base SST + the release-year forcing anomaly; HS: its declared base SST (approximate)
  T <- if (bx == "ml") aux$sst[[h]] + sstF[[h]] else aux$sst_hs
  alk <- if (bx == "hs" && !is.null(aux$alk_hs)) aux$alk_hs else ccx_const("ALK_SURFACE")
  kc <- carb_constants(T)
  R  <- revelle_factor(dic, alk, T)
  pco2 <- pco2_from_dic(dic, alk, T, k = kc)
  asx <- if (bx == "ml") aux$asx[[h]] else aux$asx_hs[[h]]
  g <- asx * p$k_w * kc$K0                       # GtC / (yr uatm), as ccx_deriv's gx
  tau <- C / (g * R * pco2)                      # yr: d(dC)/dt = -g R pCO2 dC / C  (ocean side)
  cap <- C / (R * C_atm)                         # dC_box / dC_atm at equilibrium
  fp_rows[[paste(h, bx)]] <- data.frame(box = paste(h, bx), C_GtC = C, mass_kg = mass, dic_umolkg = 1e6 * dic,
                                        T_C = T, alk = 1e6 * alk, R = R, pco2 = pco2, K0 = kc$K0,
                                        g = g, tau_yr = tau, cap = cap)
}
FP <- do.call(rbind, fp_rows)
print(format(FP, digits = 4), row.names = FALSE)
capT <- sum(FP$cap); gT <- sum(FP$g)
cat(sprintf("surface boxes' summed capacity dC_surf/dC_atm = %.4f -> equilibrium share of a 100 GtC pulse = %.2f GtC\n",
            capT, 100 * capT / (1 + capT)))
cat(sprintf("gas-exchange-limited initial uptake rate g_total x 100 GtC / %.3f GtC/ppm = %.2f GtC/yr\n",
            gpp, gT * 100 / gpp))
cat(sprintf("atm-side relaxation 1/(g_total/%.3f) = %.3f yr ; combined e-fold with the surface = %.3f yr\n",
            gpp, gpp / gT, 1 / (gT / gpp + sum(FP$g * FP$R * FP$pco2 / FP$C_GtC) )))
Kz <- ccx_kz_profile(p, sp$grid)
cat("K(z) at interfaces (m2/yr):", paste(round(Kz), collapse = " "), "\n")
cat("kz_zscale:", p$kz_zscale, " mix_strat_s:", p$mix_strat_s, "\n")
hml <- sp$grid$h_ml
for (tt in c(1, 2, 5, 10, 20)) {
  r <- o$d[which.min(abs(o$t - tt)), ]
  int <- r$ocean - r$ml - r$hs
  cat(sprintf("t=%2d: interior/ML model %.2f ; semi-infinite diffusion 2 sqrt(K t/pi)/h_ml with K=K(z1) %.2f\n",
              tt, int / r$ml, 2 * sqrt(Kz[1] * tt / pi) / hml))
}
