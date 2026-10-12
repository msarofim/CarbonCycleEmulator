source("/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/04e20996-bd05-4d13-9da3-fa0c74359cf1/scratchpad/early_drawdown/lib_ed.R")
OUT <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/04e20996-bd05-4d13-9da3-fa0c74359cf1/scratchpad/early_drawdown/out"
cat("commit:", ccx_git_stamp(), " mode:", CCX_MODE_CANONICAL, "\n")
v <- dg_vector(CCX_MODE_CANONICAL); spin <- dg_spinup(v); p <- v$p
o <- ed_pd100(v, spin)

# ===== TEST A: Joos's smoothing (sec. 3, p. 2801) applied to CarboTope's own IRF =====
# Joos: spline (Enting 1987), cut-off period = 50 % attenuation; 4 / 20 / 50 / 250 yr for
# 0-10 / 10-50 / 50-100 / 100-300 yr. Emulated by a Whittaker-Henderson smoother (2nd-difference
# penalty, the discrete cubic smoothing spline) on ANNUAL samples: H(w) = 1/(1 + lam (2 sin(w/2))^4),
# so lam = 1 / (2 sin(pi / P))^4 for 50 % at period P.
JS_CUT <- data.frame(lo = c(0, 10, 50, 100), hi = c(10, 50, 100, 300), P = c(4, 20, 50, 250))
wh <- function(y, lam) { n <- length(y); D <- diff(diag(n), differences = 2)
  as.vector(solve(diag(n) + lam * crossprod(D), y)) }
ann_t <- 0:310
irf_ann <- o$irf[match(ann_t, round(o$t, 6))]
stopifnot(!anyNA(irf_ann))
sm <- rep(NA_real_, length(ann_t))
for (i in seq_len(nrow(JS_CUT))) {
  lam <- 1 / (2 * sin(pi / JS_CUT$P[i]))^4
  s <- wh(irf_ann, lam)
  k <- ann_t >= JS_CUT$lo[i] & ann_t <= JS_CUT$hi[i]
  sm[k & is.na(sm)] <- s[k & is.na(sm)]
}
# variant: annual MEANS (as from annual-mean ESM output), assigned to the year's mid-point
irf_mean <- sapply(0:309, function(y) mean(o$irf[o$t >= y - 1e-9 & o$t < y + 1 - 1e-9]))
cat("\n=== TEST A: Joos-style smoothing of CarboTope's IRF (annual point samples) ===\n")
for (h in c(1, 2, 5, 10, 20, 50, 100, 300)) {
  k <- which(ann_t == h)
  cat(sprintf("  t=%3d raw %.4f  smoothed %.4f  (diff %+.4f)   Joos T5 %.4f\n", h, irf_ann[k], sm[k], sm[k] - irf_ann[k], joos_irf(h)))
}
th_sm <- function(th) { k <- ann_t <= th; x <- ann_t[k]; y <- sm[k]; sum(diff(x) * (head(y, -1) + tail(y, -1)) / 2) }
th_raw_ann <- function(th) { k <- ann_t <= th; x <- ann_t[k]; y <- irf_ann[k]; sum(diff(x) * (head(y, -1) + tail(y, -1)) / 2) }
cat(sprintf("  TH20: monthly %.3f, annual-trapezoid raw %.3f, smoothed %.3f\n", ed_th(o, 20), th_raw_ann(20), th_sm(20)))
cat(sprintf("  annual-MEAN variant: year 1 mean %.4f, year 2 %.4f, year 20 %.4f\n", irf_mean[1], irf_mean[2], irf_mean[20]))

# ===== TEST B: gas exchange at the CITED observational centre (R/constants.R KW_PRIOR_CENTRE) =====
kw_obs <- ccx_const("KW_PRIOR_CENTRE")
cat(sprintf("\n=== TEST B: k_w %.0f (canonical) vs %.0f (Naegler 2009 centre) and x0.905 of it (the constant's own -10 %% caveat) ===\n",
            p$k_w, kw_obs))
rows <- list(ed_row(o, "canonical"))
for (kw in c(kw_obs, 0.905 * kw_obs)) {
  q <- p; q$k_w <- kw
  rows[[length(rows) + 1]] <- ed_row(ed_pd100(v, spin, p_after = q), sprintf("process-only k_w %.0f", kw))
  v2 <- ed_v_with(v, list(k_w = kw))
  rows[[length(rows) + 1]] <- ed_row(ed_pd100(v2, dg_spinup(v2)), sprintf("whole-run k_w %.0f (others at mode)", kw))
}
# ===== TEST C: the surface ocean alone (no interior transport after 2010): does it saturate at the
# first-principles capacity? kz and u_hs to ~0 (process-only). =====
q <- p; q$kz <- 1e-3; q$u_hs <- 1e-3
oS <- ed_pd100(v, spin, p_after = q)
rows[[length(rows) + 1]] <- ed_row(oS, "surface-only ocean (kz, u_hs -> 1e-3)")
# ===== TEST D: an early-only lever + a uniform one: k_w at obs centre AND beta_max scaled =====
for (s in c(0.80, 0.70)) {
  q <- p; q$k_w <- kw_obs; q$beta_max <- p$beta_max * s
  rows[[length(rows) + 1]] <- ed_row(ed_pd100(v, spin, p_after = q), sprintf("k_w %.0f + beta_max x%.2f", kw_obs, s))
}
R <- do.call(rbind, rows)
R$dIRF20 <- R$irf20 - R$irf20[1]; R$dIRF100 <- R$irf100 - R$irf100[1]; R$r <- R$dIRF20 / R$dIRF100
print(format(R[, c("label", "irf1", "irf5", "irf20", "irf100", "irf300", "dIRF20", "dIRF100", "r", "th20", "th100",
                   "oc5", "ld5", "oc20", "ld20", "oc100", "ld100", "target")], digits = 4), row.names = FALSE)
cat(sprintf("Joos T5: irf1 %.4f irf5 %.4f irf20 %.4f irf100 %.4f irf300 %.4f ; ocean5/20/100 %.2f/%.2f/%.2f land %.2f/%.2f/%.2f\n",
            joos_irf(1), joos_irf(5), joos_irf(20), joos_irf(100), joos_irf(300),
            ed_joos_fit("ocean", 5), ed_joos_fit("ocean", 20), ed_joos_fit("ocean", 100),
            ed_joos_fit("land", 5), ed_joos_fit("land", 20), ed_joos_fit("land", 100)))
cat("surface-only ocean uptake series (GtC): ",
    paste(sprintf("t%g=%.2f", c(0.25, 0.5, 1, 2, 5, 10, 20), sapply(c(0.25, 0.5, 1, 2, 5, 10, 20), function(h) ed_at(oS, h, "ocean"))), collapse = " "), "\n")

# ===== FIRST PRINCIPLES, corrected for the SEASONAL mixed-layer mass (seas_ml = 1) =====
sp <- o$sp_rel; aux <- sp$aux; b <- o$b
molGtC <- ccx_const("MOL_C_PER_GtC"); gpp <- ccx_const("GtC_PER_PPM")
chi <- o$target; C_atm <- chi * gpp
yr1 <- which(o$t < 1 - 1e-9)
fp <- list()
for (h in HEMIS) for (bx in c("ml", "hs")) {
  Cc <- b[yr1, paste0(bx, "_C_", h)]
  f <- if (bx == "ml" && !is.null(aux$mld_coef)) sapply(b$t[yr1], function(tt) ccx_mld_eval(aux$mld_coef[[h]], tt)$f)
       else if (bx == "hs" && !is.null(aux$mld_hs_coef)) sapply(b$t[yr1], function(tt) ccx_mld_eval(aux$mld_hs_coef[[h]], tt)$f)
       else rep(1, length(yr1))
  mass <- (if (bx == "ml") aux$ml_mass_kg[[h]] else aux$hs_mass_kg[[h]]) * f
  dic <- mean(Cc * molGtC / mass)
  Tm <- if (bx == "ml") aux$sst[[h]] + mean(o$Fp[[paste0("sst_anom_", h)]][yr1]) else aux$sst_hs
  alk <- if (bx == "hs" && !is.null(aux$alk_hs)) aux$alk_hs else ccx_const("ALK_SURFACE")
  kc <- carb_constants(Tm); Rv <- revelle_factor(dic, alk, Tm)
  pco2_out <- mean(b[yr1, paste0(bx, "_pco2_", h)])
  g <- (if (bx == "ml") aux$asx[[h]] else aux$asx_hs[[h]]) * p$k_w * kc$K0
  Cm <- mean(Cc)
  fp[[paste(h, bx)]] <- data.frame(box = paste(h, bx), C_mean = Cm, f_range = sprintf("%.2f-%.2f", min(f), max(f)),
                                   dic = 1e6 * dic, T = Tm, alk = 1e6 * alk, R = Rv,
                                   pco2_calc = pco2_from_dic(dic, alk, Tm, k = kc), pco2_out = pco2_out,
                                   g = g, tau_yr = Cm / (g * Rv * pco2_out), cap = Cm / (Rv * C_atm))
}
FP <- do.call(rbind, fp)
cat("\n=== FIRST PRINCIPLES (annual means over the first year after release, baseline run) ===\n")
print(format(FP, digits = 4), row.names = FALSE)
capT <- sum(FP$cap); gT <- sum(FP$g)
cat(sprintf("sum capacity dC_surf/dC_atm = %.4f -> equilibrium surface share of a 100 GtC pulse = %.2f GtC\n", capT, 100 * capT / (1 + capT)))
cat(sprintf("initial gas-exchange-limited ocean uptake g_tot * (100/%.3f ppm) = %.2f GtC/yr (Joos ocean fit slope at 0: %.2f GtC/yr)\n",
            gpp, gT * 100 / gpp, -sum(ED_JOOS_T5$ocean$a / ED_JOOS_T5$ocean$tau)))
cat(sprintf("combined atm+surface e-fold 1/(g_tot/gpp + sum g R p / C) = %.3f yr\n",
            1 / (gT / gpp + sum(FP$g * FP$R * FP$pco2_out / FP$C_mean))))
cat(sprintf("Joos land fit slope at 0: %.2f GtC/yr ; model initial dNPP = dNPP/dchi x 100/gpp\n",
            -sum(ED_JOOS_T5$land$a / ED_JOOS_T5$land$tau)))
chi0 <- ccx_const("CO2_PI_PPM"); dd <- chi - chi0
fpr <- p$beta_max * p$fert_k / (p$fert_k + dd)^2; npp0 <- sum(unlist(aux$npp0))
cat(sprintf("  npp0 %.2f GtC/yr, f(bkg) %.4f, dNPP/dchi %.4f GtC/yr/ppm -> initial dNPP %.2f GtC/yr ; d lnNPP/d lnCO2 %.3f\n",
            npp0, ccx_fert_factor(chi, p, chi0), npp0 * fpr, npp0 * fpr * 100 / gpp, fpr * chi / ccx_fert_factor(chi, p, chi0)))
# early rates from the model's own series
rate <- function(col, h) (ed_at(o, h, col) - 0) / h
cat(sprintf("model mean uptake rate over the first 0.25 / 1 yr: ocean %.2f / %.2f GtC/yr, land %.2f / %.2f GtC/yr\n",
            rate("ocean", 0.25), rate("ocean", 1), rate("land", 0.25), rate("land", 1)))

# ===== TEST E: the historical sinks the posterior was fitted to (gate 7 window) =====
g7 <- dg_gate7(dg_run(v))
sh <- ccx_imb_shares(v$pm)
t0 <- dg_gcb_target(DG_SINK_WIN); t1 <- dg_gcb_target(DG_SINK_WIN, shares = sh)
cat(sprintf("\n=== TEST E: %d-%d mean sinks (GtC/yr): model ocean %.3f land %.3f | GCB bare ocean %.3f land %.3f | GCB + the mode's D3 imbalance shares (land %.3f, ocean %.3f) ocean %.3f land %.3f\n",
            DG_SINK_WIN[1], DG_SINK_WIN[2], g7$ocean, g7$land, t0$ocean, t0$land, sh[["land"]], sh[["ocean"]], t1$ocean, t1$land))
cat(sprintf("gate-7 sigmas: land %.3f ocean %.3f\n", DG_G7_LAND_SD, DG_G7_OCEAN_SD))
saveRDS(list(R = R, FP = FP, smooth = data.frame(t = ann_t, raw = irf_ann, sm = sm)), file.path(OUT, "s4_tests.rds"))
