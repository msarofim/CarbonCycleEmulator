# =====================================================================
# diag_obj14_refit_read.R -- READING THE OBJECTIVE-#14 REFIT (2026-10-01; handoff
# notes/handoff_2026-09-30d_refit_infra.md §3 step 2).
#
# THE REFIT: 24 starts on the Mac (multistart_20260930q_hilda_csl3v0kaidgb_..., 24/24
# CONVERGED), promoted from id 10 to calibration/output/refit_20261001_obj14_hilda_csl3v0kaidgb/
# (GATES 1-5). Label hilda_csl3v0kaidgb (D2 + D3 fitted; R/calibrate.R).
#
# WHAT IT READS, against THE ALIGNMENT CONTROL (09-30 g: the 09-28c phi = 0 basin under
# the kai label with its 11 land names re-fit; the reference every D2/D3 screen and every
# pre-registered prediction was stated against):
#   1. THE SCORECARD of both vectors -- the screen's own score() (diag_alignment_screen.R
#      at 58cd91c), COPIED here as score_p() and GATED: at the control it must reproduce
#      the screen's STORED control scorecard (43 fields), and its N-sink-per-N must
#      reproduce the stored DNTb value, before anything it says about the refit counts.
#   2. D4: modern NPP (2001-2023) against the ruled target 56.1 +/- 7.75.
#   3. The pre-registered predictions (notes/prereg_2026-09-30c_nonco2_drivers_imbalance.md
#      §4.2): P-D2-1..5. P-D3-1..4 were written for D3-ALONE arms and are REPORTED, not
#      scored, at a combined refit.
#   4. THE FUTURES DECOMPOSITION (handoff 09-30c §3 step 3: "decompose the futures
#      (fertilisation shape vs luc_scale's scenario land use vs ocean) before attributing
#      the Koven move"). Every fitted name is in exactly one group; each group is SWAPPED
#      both ways (control + the refit's group = add-one; refit - the group = remove-one), so
#      an interaction shows as the two disagreeing. The likelihood-only group must move the
#      futures by EXACTLY 0 (a built-in check that the swap touches only what it names).
#
# ⚠ The control-to-refit change is NOT "what D2/D3 did": the refit frees all 33 names,
# the control re-fit 11. A like-for-like attribution of D2/D3 alone needs a full kai refit,
# which does not exist. The decomposition says which PARAMETERS carry the change.
# No RNG. Usage: Rscript calibration/diag_obj14_refit_read.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source("calibration/lib_design_gates.R")          # dg_annual_sinks()
RD_DRIVER <- "calibration/diag_obj14_refit_read.R"
RD_DATE   <- format(Sys.Date(), "%Y%m%d")
RD_OUT    <- ccx_path("outputs", "diagnostics", sprintf("obj14_refit_read_%s", RD_DATE))
RD_REFIT  <- ccx_path("calibration", "output", "refit_20261001_obj14_hilda_csl3v0kaidgb", "mode_fit_pumpN.rds")
RD_SCREEN <- ccx_path("outputs", "diagnostics", "alignment_screen_d2ret_20260930.rds")
RD_SCREEN_MODE <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
RD_SCREEN_STRUCT <- "hilda_csl3v0kai"
RD_CTRL_PROFILE  <- ccx_path("outputs", "diagnostics", "tau_soil_slow_profile_fixedstock_stock8053_20260929.rds")
RD_CTRL_VALUE    <- 500
RD_FEX_PROXY     <- 0.8053
RD_SCORE_TOL     <- 1e-8          # relative; the copy must REPRODUCE the stored scorecard
# ---- the scorecard's definitions, VERBATIM from diag_alignment_screen.R (58cd91c) ----
AS_KEENAN <- c(y0 = 1981, y1 = 2020, mean = 0.135, sd = 0.035)
AS_G564   <- c(c0 = 400, c1 = 564, mean = 0.169, sd = 0.062)
AS_SHI    <- c(mean = -244, sd = 48, year = 2000)
AS_KOVEN  <- list(w = list(c(2015L, 2100L), c(2100L, 2200L), c(2200L, 2300L)),
                  mean = c(264, -29, -178), sd = c(172, 264, 251))
AS_GCB_WIN <- list(c(1960L, 2023L), c(2010L, 2023L))
AS_SPLICE <- c(ssp585 = FALSE, vvH = TRUE)
AS_ENH_C  <- 410
AS_NDEP_WIN  <- c(1990L, 2023L)
AS_NDEP_GATE <- c(0.6, 8.7)
AS_PD2_NPP_MAX <- 1.0
AS_PD2_KOVEN2  <- 1.5
AS_PD2_ENH_RANGE <- c(0.03, 0.12)     # P-D2-1: enh(410) falls by 3-12 % (a range, not a gate)
AS_PD3_OCN_MIN <- 0.05
AS_PD3_FUT_TOL <- 20
AS_PD3_ROW_MIN <- 8
AS_IMB_ROWS <- c("gcb_land_sink", "gcb_ocean_sink")
COMMIT <- tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")
sink(paste0(RD_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s\n", RD_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))

enh  <- function(b, K, c) b * (c - ccx_const("CO2_PI_PPM")) / (K + c - ccx_const("CO2_PI_PPM"))
gain <- function(b, K, c0, c1) (1 + enh(b, K, c1)) / (1 + enh(b, K, c0)) - 1
gcb <- readRDS(ccx_path("data", "gcb_budget.rds"))$budget
tg_npp <- ccx_npp_modern_target()
hist_em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))[, c("year", "fossil_GtC", "luc_GtC")]
emis <- function(s) { if (!AS_SPLICE[[s]]) return(NULL); e <- ccx_scenario_emissions(s)
  rbind(hist_em, e[e$year > max(hist_em$year), c("year", "fossil_GtC", "luc_GtC")]) }

# ---- the futures of one vector (the screen's `fut` block) -------------
futures_p <- function(p, pv, sp_fn) {
  sp <- sp_fn(p)
  fut <- lapply(names(AS_SPLICE), function(s) {
    rr <- suppressWarnings(ccx_run_coupled(sp, s, c(1750L, 2300L), emissions = emis(s), bomb_total_kmol = pv$bomb_total, luc_scale = pv$luc_scale))
    o <- rr$out; yr <- floor(o$t); land <- tapply(o$land_C, yr, mean); co2 <- tapply((o$co2_NH + o$co2_SH) / 2, yr, mean)
    dl <- vapply(AS_KOVEN$w, function(w) land[[as.character(w[2])]] - land[[as.character(w[1])]], 0)
    stats::setNames(c(co2[["2300"]], dl, land[["2300"]] / land[["1750"]]), paste0(s, c("_co2_2300", "_dL1521", "_dL2122", "_dL2223", "_landxPI"))) })
  unlist(fut)
}
# ---- the scorecard of one vector (the screen's score(), on a model list) ----
score_p <- function(p, pv, sp_fn, keen_c = NULL) {
  sp <- sp_fn(p)
  st <- ccx_stock_readout(sp$y, sp$aux)
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = pv$bomb_total,
                         luc_scale = pv$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
  r <- ccx_run_fast(sp, F); r$F <- F
  n <- r$npp; kn <- floor(n$t) >= tg_npp$win[1] & floor(n$t) <= tg_npp$win[2]
  a <- dg_annual_sinks(r); el <- ccx_forcing_eluc_annual(F)
  sinks <- unlist(lapply(AS_GCB_WIN, function(w) { k <- a$year >= w[1] & a$year <= w[2]; kg <- gcb$year >= w[1] & gcb$year <= w[2]
    ke <- el$year >= w[1] & el$year <= w[2]; tag <- sprintf("%d_%d", w[1], w[2])
    stats::setNames(c(mean(a$land[k]) - mean(gcb$land_sink[kg]), mean(a$ocean[k]) - mean(gcb$ocean_sink[kg]),
                      mean(el$eluc[ke]) - mean(gcb$luc[kg])), paste0(c("dLand_", "dOcean_", "dEluc_"), tag)) }))
  co2y <- tapply((r$out$co2_NH + r$out$co2_SH) / 2, floor(r$out$t), mean)
  F2 <- ccx_build_forcing("historical", c(1750, AS_SHI[["year"]]), prod_c14 = sp$prod_c14, bomb_total_kmol = pv$bomb_total,
                          luc_scale = pv$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
  y2 <- ccx_run_fast(sp, F2)$state
  soil <- unlist(lapply(HEMIS, function(h) unlist(sp$aux$idx[[h]][c("soil_fast", "soil_slow", CCX_LAND_INERT)])))
  soil_d14 <- 1000 * (sum(y2[soil, "C14"]) / sum(y2[soil, "C"]) - 1)
  fut <- futures_p(p, pv, sp_fn)
  b <- pv$beta_max; K <- pv$fert_k; ra <- if (is.null(p$ra_ratio)) 0 else p$ra_ratio
  kc <- if (is.null(keen_c)) co2y[as.character(AS_KEENAN[c("y0", "y1")])] else keen_c
  npp_mod <- mean(n$npp_NH[kn] + n$npp_SH[kn])
  c(st, npp_modern = npp_mod, npp0 = ccx_const("NPP_GLOBAL_PI"), ra_ratio = ra,
    gpp_pi = ccx_const("NPP_GLOBAL_PI") * (1 + ra), gpp_modern = npp_mod * (1 + ra), sinks,
    soil_d14c_2000 = soil_d14, keenan_c0 = unname(kc[1]), keenan_c1 = unname(kc[2]),
    g_keenan = unname(gain(b, K, kc[[1]], kc[[2]])), g_400_564 = unname(gain(b, K, AS_G564[["c0"]], AS_G564[["c1"]])),
    g_2x = unname(enh(b, K, 2 * ccx_const("CO2_PI_PPM"))), g_4x = unname(enh(b, K, 4 * ccx_const("CO2_PI_PPM"))),
    beta_max = unname(b), fert_k = unname(K), q10 = unname(pv$q10), luc_scale = unname(pv$luc_scale), fut)
}
# the N-deposition sink per unit N over AS_NDEP_WIN (the screen's ndep_sink_per_n, on a model list)
ndep_sink_p <- function(p, pv, sp_fn) {
  run_land <- function(pp) { sp <- sp_fn(pp)
    F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = pv$bomb_total,
                           luc_scale = pv$luc_scale, enso_index = ccx_enso_index_of(pp), aod_mode = ccx_aod_mode_of(pp))
    r <- ccx_run_fast(sp, F); r$F <- F; dg_annual_sinks(r) }
  p0 <- p; p0$ndep_ret <- 0
  a1 <- run_land(p); a0 <- run_land(p0)
  k  <- a1$year >= AS_NDEP_WIN[1] & a1$year <= AS_NDEP_WIN[2]
  nd <- readRDS(ccx_path("data", CCX_NDEP_FILE)); nd <- nd[nd$scenario == "historical" & nd$year >= AS_NDEP_WIN[1] & nd$year <= AS_NDEP_WIN[2], ]
  sink <- mean(a1$land[k] - a0$land[k])
  c(sink_GtC = sink, ndep_TgN = mean(nd$ndep_land), kgC_per_kgN = sink * 1e3 / mean(nd$ndep_land))
}

# ---- the CONTROL and the screen's DNTb vector, exactly as the screen built them ----
ds <- readRDS(RD_SCREEN)
mdS <- readRDS(RD_SCREEN_MODE)
cp <- readRDS(RD_CTRL_PROFILE); ctrl <- cp[[which(vapply(cp, `[[`, numeric(1), "value") == RD_CTRL_VALUE)]]
rmS <- ccx_apply_pins(mdS$pins)
bp0 <- ccx_mode_base(mdS); bp0$pump_mode <- mdS$pump_mode
bp0 <- ccx_apply_structure(bp0, RD_SCREEN_STRUCT, as.character(mdS$seas_ml), pump_field = mdS$pump_field)
for (n in names(mdS$pins)) bp0[[n]] <- mdS$pins[[n]]
for (n in names(ctrl$over)) bp0[[n]] <- ctrl$over[[n]]
bp0$litter_slow_frac <- ctrl$over$litter_slow_frac / RD_FEX_PROXY
model_of <- function(u, d2 = NULL) { pv <- ccx_unc_to_par(u); p <- ccx_overlay_par(bp0, pv); p$ra_ratio <- 0
  for (n in names(d2)) p[[n]] <- d2[[n]]; list(p = p, pv = pv) }
spS <- ccx_spinup_from_label(ccx_mode_spinup(mdS))
C <- model_of(ds$control$u)
a_dntb <- ds$arms[[which(vapply(ds$arms, `[[`, "", "arm") == "DNTb")]]
Dn <- model_of(a_dntb$u, a_dntb$d2)
ccx_unpin_params(rmS)

cat("\n=== GATE: the copied scorecard reproduces the screen's STORED control scorecard ===\n")
sc_C <- score_p(C$p, C$pv, spS)
ref <- ds$control$score
stopifnot(identical(names(sc_C), names(ref)))
rel <- max(abs(sc_C - ref) / pmax(abs(ref), 1e-12))
cat(sprintf("  %d fields, max relative difference %.3e (tol %g)\n", length(ref), rel, RD_SCORE_TOL))
if (!(rel <= RD_SCORE_TOL)) stop("the copied scorecard does NOT reproduce the screen's: nothing below can be trusted")
ns_D <- ndep_sink_p(Dn$p, Dn$pv, spS)
reln <- max(abs(ns_D - a_dntb$ndep_sink) / abs(a_dntb$ndep_sink))
cat(sprintf("  N sink per N at the screen's DNTb vector: %.6f kg C/kg N (stored %.6f), max rel diff %.3e\n",
            ns_D[["kgC_per_kgN"]], a_dntb$ndep_sink[["kgC_per_kgN"]], reln))
if (!(reln <= RD_SCORE_TOL)) stop("the copied N-sink measure does NOT reproduce the screen's")
KEEN_C <- sc_C[c("keenan_c0", "keenan_c1")]          # fixed for every vector, as in the screen

# ---- the REFIT ----------------------------------------------------------
md <- readRDS(RD_REFIT)
gR <- ccx_apply_gate(ccx_mode_struct(md)); rmR <- ccx_apply_pins(ccx_mode_pins(md))
stopifnot(identical(md$param_names, CCX_PARAM_NAMES))
bpR <- ccx_mode_base(md); bpR$pump_mode <- md$pump_mode
R <- list(p = ccx_overlay_par(bpR, md$par_mode), pv = md$par_mode)
spR <- ccx_spinup_from_label(ccx_mode_spinup(md))
lpR <- ccx_make_logpost(base_params = bpR, by_stream = TRUE, spinup_fn = spR)(ccx_par_to_unc(md$par_mode))
cat(sprintf("\nrefit: %s\n  logpost %.6f (stored %.6f), loglik %.6f on %d rows; struct %s; %d fitted names\n",
            RD_REFIT, as.numeric(lpR), md$logpost, sum(attr(lpR, "streams")), length(attr(lpR, "streams")),
            ccx_mode_struct(md), length(md$param_names)))
stopifnot(abs(as.numeric(lpR) - md$logpost) < 1e-8)
sc_R <- score_p(R$p, R$pv, spR, keen_c = KEEN_C)
ns_R <- ndep_sink_p(R$p, R$pv, spR)

# ---- 1. the scorecard side by side --------------------------------------------
cat("\n=== 1. SCORECARD (control = 09-30 g's alignment control under kai; refit = #14, 33 names) ===\n")
show <- c("vegetation", "soil_total", "land_total", "npp_modern", "dLand_1960_2023", "dOcean_1960_2023", "dEluc_1960_2023",
          "dLand_2010_2023", "dOcean_2010_2023", "soil_d14c_2000", "g_keenan", "g_400_564", "g_2x", "g_4x",
          "beta_max", "fert_k", "q10", "luc_scale", "ssp585_co2_2300", "ssp585_dL1521", "ssp585_dL2122", "ssp585_dL2223",
          "ssp585_landxPI", "vvH_co2_2300", "vvH_landxPI")
tab <- data.frame(field = show, control = unname(sc_C[show]), refit = unname(sc_R[show]))
tab$change <- tab$refit - tab$control
print(format(tab, digits = 5), row.names = FALSE)
enhC <- enh(sc_C[["beta_max"]], sc_C[["fert_k"]], AS_ENH_C); enhR <- enh(sc_R[["beta_max"]], sc_R[["fert_k"]], AS_ENH_C)
zK <- function(sc, i) (sc[[c("ssp585_dL1521", "ssp585_dL2122", "ssp585_dL2223")[i]]] - AS_KOVEN$mean[i]) / AS_KOVEN$sd[i]
cat(sprintf("  enh(%d ppm): %.4f -> %.4f (%+.1f %%)\n", AS_ENH_C, enhC, enhR, 100 * (enhR / enhC - 1)))
cat(sprintf("  Koven z (SSP5-8.5 land-C windows 2015-2100 / 2100-2200 / 2200-2300): control %+.2f / %+.2f / %+.2f; refit %+.2f / %+.2f / %+.2f\n",
            zK(sc_C, 1), zK(sc_C, 2), zK(sc_C, 3), zK(sc_R, 1), zK(sc_R, 2), zK(sc_R, 3)))
cat(sprintf("  soil D14C 2000 vs Shi 2020 (%g +/- %g): control z %+.2f, refit z %+.2f\n", AS_SHI[["mean"]], AS_SHI[["sd"]],
            (sc_C[["soil_d14c_2000"]] - AS_SHI[["mean"]]) / AS_SHI[["sd"]], (sc_R[["soil_d14c_2000"]] - AS_SHI[["mean"]]) / AS_SHI[["sd"]]))
cat(sprintf("  Keenan gain 1981-2020 (%.3f +/- %.3f): control %.4f (z %+.2f), refit %.4f (z %+.2f); G564 (%.3f +/- %.3f): %.4f (z %+.2f) -> %.4f (z %+.2f)\n",
            AS_KEENAN[["mean"]], AS_KEENAN[["sd"]], sc_C[["g_keenan"]], (sc_C[["g_keenan"]] - AS_KEENAN[["mean"]]) / AS_KEENAN[["sd"]],
            sc_R[["g_keenan"]], (sc_R[["g_keenan"]] - AS_KEENAN[["mean"]]) / AS_KEENAN[["sd"]],
            AS_G564[["mean"]], AS_G564[["sd"]], sc_C[["g_400_564"]], (sc_C[["g_400_564"]] - AS_G564[["mean"]]) / AS_G564[["sd"]],
            sc_R[["g_400_564"]], (sc_R[["g_400_564"]] - AS_G564[["mean"]]) / AS_G564[["sd"]]))

# ---- 2. D4 -----------------------------------------------------------------------
cat("\n=== 2. D4: modern NPP (2001-2023) against the ruled target ===\n")
zN <- function(x) (x - tg_npp$centre) / tg_npp$sd
cat(sprintf("  target %.2f +/- %.2f GtC/yr; control %.2f (z %+.2f); refit %.2f (z %+.2f); change %+.2f\n",
            tg_npp$centre, tg_npp$sd, sc_C[["npp_modern"]], zN(sc_C[["npp_modern"]]), sc_R[["npp_modern"]], zN(sc_R[["npp_modern"]]),
            sc_R[["npp_modern"]] - sc_C[["npp_modern"]]))

# ---- 3. the fitted D2/D3 names and the predictions ------------------------------------
cat("\n=== 3. THE D2/D3 NAMES AT THE REFIT, AND THE PRE-REGISTERED PREDICTIONS ===\n")
pm <- md$par_mode; sh <- ccx_imb_shares(pm)
pz <- function(n) ccx_prior_z(n, pm[[n]], p = bpR)
cat(sprintf("  ndep_ret %.4f kg C/kg N (prior z %+.2f); implied sink %.4f GtC/yr over %d-%d = %.3f kg C/kg N\n",
            pm$ndep_ret, pz("ndep_ret"), ns_R[["sink_GtC"]], AS_NDEP_WIN[1], AS_NDEP_WIN[2], ns_R[["kgC_per_kgN"]]))
cat(sprintf("  npp_tsens %+.5f /K (prior z %+.2f)\n", pm$npp_tsens, pz("npp_tsens")))
cat(sprintf("  shares: s_land %.4f, s_ocean %.4f, rest %.4f (imb_share_land %.4f, ocean_rest %.4f)\n",
            sh[["land"]], sh[["ocean"]], 1 - sum(sh), pm$imb_share_land, pm$imb_share_ocean_rest))
stC <- ds$control$streams; stR <- attr(lpR, "streams")
common <- setdiff(intersect(names(stC), names(stR)), AS_IMB_ROWS)
d_rows <- unlist(stR[AS_IMB_ROWS]) - unlist(stC[AS_IMB_ROWS])
pr <- list(
  `P-D2-1 enh(410) falls (3-12 % is the range, falling is the gate)` = list(pass = enhR < enhC, val = sprintf("%+.1f %%", 100 * (enhR / enhC - 1))),
  `P-D2-2 ndep_ret in its prior's 2 sd AND sink per N in 0.6-8.7` = list(pass = abs(pz("ndep_ret")) <= 2 && ns_R[["kgC_per_kgN"]] >= AS_NDEP_GATE[1] && ns_R[["kgC_per_kgN"]] <= AS_NDEP_GATE[2],
                                                                      val = sprintf("z %+.2f; %.3f kg C/kg N", pz("ndep_ret"), ns_R[["kgC_per_kgN"]])),
  `P-D2-3 modern NPP rises by < 1 GtC/yr` = list(pass = sc_R[["npp_modern"]] - sc_C[["npp_modern"]] < AS_PD2_NPP_MAX, val = sprintf("%+.2f", sc_R[["npp_modern"]] - sc_C[["npp_modern"]])),
  `P-D2-4 npp_tsens > 0 AND q10 rises` = list(pass = pm$npp_tsens > 0 && sc_R[["q10"]] > sc_C[["q10"]], val = sprintf("%+.4f /K; q10 %.4f -> %.4f", pm$npp_tsens, sc_C[["q10"]], sc_R[["q10"]])),
  `P-D2-5 Koven z(2100-2200) > 1.5 [written for (a) ALONE]` = list(pass = zK(sc_R, 2) > AS_PD2_KOVEN2, val = sprintf("%+.2f", zK(sc_R, 2))))
for (k in names(pr)) cat(sprintf("  %-66s %s  (%s)\n", k, if (isTRUE(pr[[k]]$pass)) "PASS" else "FAIL", pr[[k]]$val))
cat("  -- written for D3-ALONE arms; REPORTED, not scored, at the combined refit:\n")
cat(sprintf("     P-D3-1 the two GCB rows gain >= +%g: %+.2f (land %+.2f, ocean %+.2f)\n", AS_PD3_ROW_MIN, sum(d_rows), d_rows[[1]], d_rows[[2]]))
cat(sprintf("     P-D3-2 enh(410) not down > 5 %%: %+.1f %%; P-D3-3 s_ocean > %.2f: %.4f; P-D3-4 |d SSP5-8.5 2300| < %g: %+.1f ppm\n",
            100 * (enhR / enhC - 1), AS_PD3_OCN_MIN, sh[["ocean"]], AS_PD3_FUT_TOL, sc_R[["ssp585_co2_2300"]] - sc_C[["ssp585_co2_2300"]]))
cat(sprintf("  the record: the COMMON rows (all but the two GCB level rows) %+.2f; the two GCB rows %+.2f (targets moved by D3)\n",
            sum(unlist(stR[common])) - sum(unlist(stC[common])), sum(d_rows)))
dr <- sort(unlist(stR[common]) - unlist(stC[common]))
cat("  largest common-row moves: ", paste(sprintf("%s %+.2f", names(dr), dr)[order(-abs(dr))][1:8], collapse = "; "), "\n")
big <- vapply(md$param_names, function(n) tryCatch(ccx_prior_z(n, pm[[n]], p = bpR), error = function(e) NA_real_), 0)
cat("  prior |z| > 2 at the refit: ", paste(sprintf("%s %+.2f", names(big)[abs(big) > 2 & !is.na(big)], big[abs(big) > 2 & !is.na(big)]), collapse = "; "), "\n")

# ---- 4. the futures decomposition ------------------------------------------------
cat("\n=== 4. FUTURES DECOMPOSITION: which parameters carry the control -> refit change ===\n")
# D2 is split into its two terms: N retention adds a sink, greening's sign is the fit's, and the
# group as a whole RAISED the 2300 CO2 on the first read (+9 to +11 ppm), so which term does it matters.
GROUPS <- list(FERT = c("beta_max", "fert_k"), Q10 = "q10", LUC = "luc_scale", D2_N = "ndep_ret", D2_T = "npp_tsens",
               OCEAN = c("k_w", "h_ml", "kz", "kz_deep_frac", "hs_asx_frac", "h_hs", "u_hs", "w_enso_l2", "pump_hs_gcm2",
                         "pump_grad", "tau_ex", "sst_seas_amp_NH", "sst_seas_amp_SH"),
               LAND_SEAS = c("npp_frac_NH", "seas_T_amp_NH", "seas_T_amp_SH", "seas_lag_p_NH", "seas_lag_p_SH",
                             "gamma_enso_land_NH", "gamma_enso_land_SH"),
               NONMODEL = c("bomb_total", "sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c", "imb_share_land", "imb_share_ocean_rest"))
stopifnot(setequal(unlist(GROUPS), md$param_names), !anyDuplicated(unlist(GROUPS)))
# a model list is the base structure's; a swap copies the group's model fields AND fitted values.
# The control's gated names are its base values (0 = OFF); its fitted list lacks them.
swap <- function(to, from, names) {
  p <- to$p; pv <- to$pv
  for (n in names) {
    if (n %in% names(p)) p[[n]] <- if (n %in% names(from$p)) from$p[[n]] else 0
    pv[[n]] <- if (!is.null(from$pv[[n]])) from$pv[[n]] else if (n %in% names(from$p)) from$p[[n]] else NULL
  }
  p <- ccx_set_enso(p, pv)
  list(p = p, pv = pv)
}
FK <- c("ssp585_co2_2300", "ssp585_dL2122", "ssp585_landxPI", "vvH_co2_2300")
f_C <- sc_C[FK]; f_R <- sc_R[FK]
dec <- lapply(names(GROUPS), function(g) {
  add <- futures_p(swap(C, R, GROUPS[[g]])$p, swap(C, R, GROUPS[[g]])$pv, spS)[FK] - f_C
  rem <- f_R - futures_p(swap(R, C, GROUPS[[g]])$p, swap(R, C, GROUPS[[g]])$pv, spR)[FK]
  data.frame(group = g, n = length(GROUPS[[g]]), what = c("add-one", "remove-one"), rbind(add, rem), check.names = FALSE)
})
dec <- do.call(rbind, dec)
tot <- data.frame(group = "TOTAL", n = length(md$param_names), what = "refit - control", t(f_R - f_C), check.names = FALSE)
sums <- data.frame(group = "SUM", n = NA, what = c("of add-ones", "of remove-ones"),
                   rbind(colSums(dec[dec$what == "add-one", FK]), colSums(dec[dec$what == "remove-one", FK])), check.names = FALSE)
D <- rbind(dec, tot, sums); D[FK] <- round(D[FK], 3)
print(D, row.names = FALSE)
nm <- dec[dec$group == "NONMODEL", FK]
cat(sprintf("  CHECK: the likelihood-only group moves the futures by max |%.3g| (must be 0)\n", max(abs(as.matrix(nm)))))
if (max(abs(as.matrix(nm))) > 1e-9) stop("a likelihood-only name moved a future: the swap touches something it does not name")
cat("  (columns: SSP5-8.5 CO2 at 2300 ppm; SSP5-8.5 land-C change 2100-2200 GtC (Koven's z window); land x PI 2300; vvH CO2 2300 ppm)\n")

sink()
out <- list(control = list(score = sc_C), refit = list(score = sc_R, ndep_sink = ns_R, logpost = as.numeric(lpR), streams = stR,
            shares = sh, par_mode = pm), predictions = pr, decomposition = D, groups = GROUPS,
            provenance = sprintf("%s @%s; refit %s; control = diag_alignment_screen.R's (58cd91c); no RNG", RD_DRIVER, COMMIT, RD_REFIT))
saveRDS(out, paste0(RD_OUT, ".rds"))
utils::write.csv(cbind(D, provenance = out$provenance), paste0(RD_OUT, "_decomposition.csv"), row.names = FALSE)
cat(sprintf("saved %s.{log,rds}, %s_decomposition.csv\n", RD_OUT, RD_OUT))
