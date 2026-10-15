# =====================================================================
# diag_d13c_gradient_offset.R -- THE d13C GRADIENT MISS IS AN ADDITIVE OFFSET, NOT A 2x RATIO (2026-09-20 s)
#
# diag_d13c_gradient_levers.R (09-20 r) scanned every multiplicative lever the handoff named
# (ra_ratio, d13c_foss, the LUC split, k_w) and NONE moved R_d13c by more than 10 %. This script
# asks the prior question: WHAT SHAPE is the miss? "R_d13c = 2.0" is a RATIO of the model's
# MLO-SPO d13C gradient to the observed mean; it is the right statistic only if the miss SCALES
# with the gradient. Sections:
#   [1] additive vs multiplicative: the residual (model - obs) year by year against the model's
#       own CO2 gradient. ADDITIVE predicts slope 0 and a constant residual; MULTIPLICATIVE
#       (R = 2) predicts slope = the model's own d13C-per-ppm signature (~ -0.034 permil/ppm).
#   [2] is the observation robust? The MLO-SPO gradient from the NOAA/INSTAAR records (an
#       independent lab, in the bundle as *_NOAA cross-checks) against Scripps on their overlap.
#   [3] the model's isoflux GAIN: permil of atmospheric gradient per GtC-permil/yr of hemispheric
#       isoflux asymmetry, MEASURED by the d13c_foss +2 permil perturbation (a known isoflux).
#   [4] the model's own hemispheric air-sea d13C disequilibrium isoflux (each surface box, 1995,
#       Quay's definition) and the asymmetry it implies for the gradient.
#   [5] the observation-side counterpart: Quay et al. 2003 Fig. 8 (the meridional disequilibrium,
#       DIGITIZED here by eye from the figure -- approximate, flagged as such), weighted by an
#       APPROXIMATE ocean-fraction-by-latitude table, with and without a crude wind-speed
#       gas-exchange weighting. An ORDER-OF-MAGNITUDE pre-check, not a measurement.
# Output: outputs/diagnostics/d13c_gradient_offset_<date>.{log,rds}
# Usage: Rscript calibration/diag_d13c_gradient_offset.R   (~1 min, C++ core)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f); ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
GO_OUT <- ccx_path("outputs", "diagnostics", sprintf("d13c_gradient_offset_%s", format(Sys.Date(), "%Y%m%d")))
GO_FOSS_SHIFT <- 2                # permil, the isoflux perturbation used to MEASURE the gain
GO_DISEQ_YEAR <- DG_Q_YEAR        # 1995, gate Q's year (Quay's reference year)
# Quay et al. 2003 GBC 17(1) Fig. 8: air-sea d13C disequilibrium (permil) by 5-deg band, three basins.
# DIGITIZED BY EYE from the printed figure (ClaudeDocs/Papers/...Quay...pdf p.12), 3-basin average, +-0.2 permil.
GO_QUAY_LAT   <- seq(-70, 70, by = 10)
GO_QUAY_DISEQ <- c(-1.9, -1.5, -0.7, 0.3, 0.8, 1.3, 1.6, 1.7, 1.85, 1.6, 1.2, 0.8, 0.4, 0.1, -0.1)
# APPROXIMATE ocean fraction by 10-deg band (center latitude), typed from general knowledge, +-0.1;
# the Arctic band is set to an EFFECTIVE (ice-free) 0.3.
GO_OCEAN_FRAC <- c(0.85, 0.98, 0.97, 0.90, 0.77, 0.78, 0.76, 0.77, 0.74, 0.63, 0.58, 0.53, 0.43, 0.31, 0.30)
# crude gas-exchange weight ~ wind speed^2 (Wanninkhof 1992): Southern Ocean windy, tropics calm; +-30 %
GO_K_WEIGHT   <- c(1.6, 1.7, 1.6, 1.3, 1.0, 0.8, 0.7, 0.6, 0.7, 0.9, 1.1, 1.3, 1.4, 1.3, 1.0)
sink_log <- file(paste0(GO_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE); on.exit({ sink(); close(sink_log) }, add = TRUE)
obs <- ccx_prepare_obs(); ho <- dg_gateH_obs(obs); can <- dg_vector(CCX_MODE_CANONICAL); r <- dg_run(can); ms <- ccx_model_stats(r$out, obs)
cat(sprintf("THE SHAPE OF THE d13C GRADIENT MISS, at %s  %s\n  %s\n", CCX_MODE_CANONICAL, format(Sys.time()), can$src))
mg <- function(mod, years) mod$MLO$level[match(years, mod$MLO$year)] - mod$SPO$level[match(years, mod$SPO$year)]
g <- merge(obs$co2_grad, obs$d13c_grad, by = "year", suffixes = c("_co2", "_d13c"))
g$mod_co2 <- mg(ms$co2, g$year); g$mod_d13c <- mg(ms$d13, g$year); g$resid <- g$mod_d13c - g$grad_d13c; g$dec <- floor(g$year / 10) * 10

cat("\n[1] ADDITIVE vs MULTIPLICATIVE, on the years both stations have d13C (", min(g$year), "-", max(g$year), ", n ", nrow(g), ")\n", sep = "")
a <- aggregate(cbind(grad_co2, mod_co2, grad_d13c, mod_d13c, resid) ~ dec, g, mean); a$R_co2 <- a$mod_co2 / a$grad_co2; a$R_d13c <- a$mod_d13c / a$grad_d13c
cat("  by decade:\n"); print(round(a, 4), row.names = FALSE)
f1 <- lm(resid ~ mod_co2, g); s <- summary(f1)$coefficients
rho <- stats::acf(residuals(f1), lag.max = 1, plot = FALSE)$acf[2]; neff <- nrow(g) * (1 - rho) / (1 + rho); infl <- sqrt(nrow(g) / max(neff, 2))
slope_sig <- coef(lm(mod_d13c ~ mod_co2, g))[[2]]
cat(sprintf("  residual ~ model CO2 gradient: intercept %+.4f +- %.4f permil, slope %+.4f +- %.4f permil/ppm (n_eff %.1f)\n", s[1, 1], s[1, 2] * infl, s[2, 1], s[2, 2] * infl, neff))
cat(sprintf("  the model's own d13C-per-ppm signature across years: %+.4f permil/ppm (obs: %+.4f)\n", slope_sig, coef(lm(grad_d13c ~ grad_co2, g))[[2]]))
cat(sprintf("  => slope is %.1f se from ADDITIVE (0) and %.1f se from MULTIPLICATIVE (%+.4f). Mean residual %+.4f, sd %.4f permil; obs gradient sd %.4f.\n",
            s[2, 1] / (s[2, 2] * infl), (s[2, 1] - slope_sig) / (s[2, 2] * infl), slope_sig, mean(g$resid), sd(g$resid), sd(g$grad_d13c)))
offset <- -mean(g$resid)
cat(sprintf("  THE MISS IS A CONSTANT: the model's NH is %.4f permil TOO LIGHT relative to its SH, in every decade (R_d13c runs %.1f -> %.1f only because the observed gradient grew).\n", offset, max(a$R_d13c), min(a$R_d13c)))
early <- r$out$t < 1800
cat(sprintf("  the model's preindustrial (1750-1800) gradient: CO2 %+.4f ppm, d13C %+.5f permil -- it has NO background offset.\n", mean((r$out$co2_NH - r$out$co2_SH)[early]), mean((r$out$d13c_NH - r$out$d13c_SH)[early])))

cat("\n[2] IS THE OBSERVATION ROBUST? Scripps vs NOAA/INSTAAR on their overlap, same estimator (ccx_year_harmonic levels, differenced)\n")
d <- as.data.frame(readRDS(ccx_path("data", "obs_d13c_monthly.rds")))
ann <- lapply(c(MLO = "MLO", SPO = "SPO", MLO_NOAA = "MLO_NOAA", SPO_NOAA = "SPO_NOAA"), function(st) { o <- d[d$station == st, ]; ccx_year_harmonic(o$decimal_date, o$d13c) })
gr <- function(x, y) { m <- merge(x[, c("year", "level")], y[, c("year", "level")], by = "year"); data.frame(year = m$year, grad = m$level.x - m$level.y) }
both <- merge(gr(ann$MLO, ann$SPO), gr(ann$MLO_NOAA, ann$SPO_NOAA), by = "year", suffixes = c("_sio", "_noaa"))
se <- function(x) sd(x) / sqrt(length(x)); dd <- both$grad_noaa - both$grad_sio
cat(sprintf("  overlap %d-%d (n %d): Scripps %+.4f +- %.4f, NOAA %+.4f +- %.4f; NOAA - Scripps %+.4f +- %.4f permil (%.1f se); r = %.2f\n",
            min(both$year), max(both$year), nrow(both), mean(both$grad_sio), se(both$grad_sio), mean(both$grad_noaa), se(both$grad_noaa), mean(dd), se(dd), mean(dd) / se(dd), cor(both$grad_sio, both$grad_noaa)))
cat(sprintf("  => two independent labs agree on the gradient to %.3f permil; the %.3f permil offset is in the ATMOSPHERE, not in a station calibration.\n", abs(mean(dd)), offset))

cat(sprintf("\n[3] THE MODEL'S ISOFLUX GAIN, measured: d13c_foss %+d permil on the forcing table (transient only)\n", GO_FOSS_SHIFT))
r2 <- r; r2$F$d13c_foss <- r2$F$d13c_foss + GO_FOSS_SHIFT; r2$out <- ccx_run_fast(r2$sp, r2$F)$out; ms2 <- ccx_model_stats(r2$out, obs)
dgrad <- mean(mg(ms2$d13, g$year)) - mean(mg(ms$d13, g$year))
Fk <- r$F[floor(r$F$t) %in% g$year, ]; dE <- mean(Fk$e_foss_NH - Fk$e_foss_SH)
dI <- dE * GO_FOSS_SHIFT; gain <- dgrad / dI
cat(sprintf("  mean fossil E_NH - E_SH over the obs years %.2f GtC/yr -> isoflux change %+.1f GtC-permil/yr -> gradient change %+.4f permil\n", dE, dI, dgrad))
cat(sprintf("  GAIN = %.5f permil per (GtC-permil/yr). Two-box check: 1/(2 k C_hemi) with tau_ex %.2f yr and C_hemi %.0f GtC = %.5f\n",
            gain, can$p$tau_ex, mean(r$out$co2_NH[floor(r$out$t) %in% g$year]) * ccx_const("GtC_PER_PPM") / 2, 1 / (2 / can$p$tau_ex * mean(r$out$co2_NH[floor(r$out$t) %in% g$year]) * ccx_const("GtC_PER_PPM") / 2)))
need <- offset / gain
cat(sprintf("  => the %.4f permil offset needs a persistent NH-minus-SH isoflux asymmetry of %+.0f GtC-permil/yr that the model lacks.\n", offset, need))

cat(sprintf("\n[4] THE MODEL'S OWN AIR-SEA DISEQUILIBRIUM ISOFLUX BY HEMISPHERE, calendar %d (Quay's definition: d13C of air in equilibrium with the box, minus the air)\n", GO_DISEQ_YEAR))
o <- r$out; aux <- r$sp$aux; p <- can$p
tt <- ccx_epoch_year_samples(GO_DISEQ_YEAR + 0.5); j <- vapply(tt, function(t1) which.min(abs(o$t - t1)), integer(1))
eps <- function(sst) ccx_const("ALPHA_AS_ZHANG_A") * sst * ccx_const("ALPHA_AS_FCO3") + ccx_const("ALPHA_AS_ZHANG_B") * sst + ccx_const("ALPHA_AS_ZHANG_C")
boxes <- c(ml = "asx", hs = "asx_hs", eq = "asx_eq", tr = "asx_tr")
iso <- list(); Fg <- list()
for (h in HEMIS) { iso[[h]] <- 0; Fg[[h]] <- 0
  for (b in names(boxes)) { ax <- aux[[boxes[[b]]]]; if (is.null(ax) || is.null(ax[[h]]) || ax[[h]] <= 0) next
    cC <- o[[paste0(b, "_C_", h)]][j]; c13 <- o[[paste0(b, "_C13_", h)]][j]; if (is.null(cC)) next
    d_box <- 1000 * (c13 / (cC * ccx_const("R13_VPDB")) - 1)
    # box annual-mean SST: aux$sst is per hemisphere; the HILDA/cell boxes carry ONE scalar (annual mean, no GMST anomaly here: 0.1 permil/K on eps)
    sst_b <- if (b == "ml") aux$sst[[h]] else { x <- aux[[paste0("sst_", b)]]; if (is.list(x)) x[[h]] else x }
    D <- mean(d_box - eps(sst_b) - o[[paste0("d13c_", h)]][j])
    K0 <- carb_constants(sst_b)$K0; Fgross <- ax[[h]] * p$k_w * K0 * mean(o[[paste0("co2_", h)]][j])   # invasion, GtC/yr
    cat(sprintf("  %s %-2s  gross invasion %6.2f GtC/yr  disequilibrium %+.3f permil  isoflux %+7.2f GtC-permil/yr\n", h, b, Fgross, D, Fgross * D))
    iso[[h]] <- iso[[h]] + Fgross * D; Fg[[h]] <- Fg[[h]] + Fgross } }
dI_model <- iso$NH - iso$SH
cat(sprintf("  model: gross invasion NH %.1f / SH %.1f GtC/yr; isoflux NH %+.1f / SH %+.1f; ASYMMETRY %+.1f GtC-permil/yr -> %+.4f permil of gradient (%.0f %% of the offset)\n",
            Fg$NH, Fg$SH, iso$NH, iso$SH, dI_model, dI_model * gain, 100 * dI_model * gain / offset))

cat("\n[5] THE OBSERVATION-SIDE COUNTERPART: Quay 2003 Fig. 8's meridional disequilibrium, hemisphere-averaged (DIGITIZED + APPROXIMATE areas -- an order-of-magnitude pre-check)\n")
w_area <- GO_OCEAN_FRAC * cos(GO_QUAY_LAT * pi / 180); nh <- GO_QUAY_LAT > 0; sh <- GO_QUAY_LAT < 0   # the equator band is split below
w_area_n <- w_area * ifelse(nh, 1, ifelse(sh, 0, 0.5)); w_area_s <- w_area * ifelse(sh, 1, ifelse(nh, 0, 0.5))
for (lab in c("area-weighted", "area x gas-exchange weighted")) {
  wk <- if (lab == "area-weighted") rep(1, length(w_area)) else GO_K_WEIGHT
  wn <- w_area_n * wk; ws <- w_area_s * wk
  D_N <- sum(wn * GO_QUAY_DISEQ) / sum(wn); D_S <- sum(ws * GO_QUAY_DISEQ) / sum(ws); f_N <- sum(wn) / (sum(wn) + sum(ws))
  D_glob <- (sum(wn * GO_QUAY_DISEQ) + sum(ws * GO_QUAY_DISEQ)) / (sum(wn) + sum(ws))
  for (Ftot in c(model = Fg$NH + Fg$SH, quay = 74)) {
    dI_obs <- Ftot * (f_N * D_N - (1 - f_N) * D_S)
    cat(sprintf("  %-30s D_NH %+.2f D_SH %+.2f (global %+.2f; Quay's %+.2f) NH share of exchange %.2f; F_gross %s %.0f GtC/yr -> asymmetry %+.1f GtC-permil/yr -> %+.4f permil (%.0f %% of the offset)\n",
                lab, D_N, D_S, D_glob, DG_Q_OBS, f_N, names(which(c(model = Fg$NH + Fg$SH, quay = 74) == Ftot))[1], Ftot, dI_obs, dI_obs * gain, 100 * dI_obs * gain / offset)) } }
cat(sprintf("  vs the model's own asymmetry %+.1f: the REAL ocean's meridional disequilibrium pattern (positive tropics, negative poleward of ~50 deg, Quay's Fig. 8 -- and 'a similar trend likely existed preindustrially', Quay para. 26)\n  is SH-light because the Southern Ocean is where the negative values are; the model's two columns are the SAME physics at two areas and produce an asymmetry of the WRONG SIGN.\n", dI_model))
saveRDS(list(by_decade = a, regression = s, offset = offset, gain = gain, need = need, model_iso = list(iso = iso, Fg = Fg, dI = dI_model),
             noaa = both, quay = list(lat = GO_QUAY_LAT, diseq = GO_QUAY_DISEQ, ocean_frac = GO_OCEAN_FRAC, k_weight = GO_K_WEIGHT), built = format(Sys.time())), paste0(GO_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n", GO_OUT))
