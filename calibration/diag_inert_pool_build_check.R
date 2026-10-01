# =====================================================================
# diag_inert_pool_build_check.R -- the in-model inert soil carve-out (2026-09-30)
# against its 09-29 (v) proxy, on arm A's REAL vector (the fixed-stock tau-500
# control, nothing re-fitted). Three identities, each able to fail:
#   I1 label "hilda_csl3v0ka" (carve-out OFF) reproduces the (v) frozen control;
#   I2 label "hilda_csl3v0kai" (ON) is BYTE-IDENTICAL to arm A with
#      litter_slow_frac scaled by (1 - SOIL_INERT_FRAC) by hand -- the proxy;
#   I3 the ON - OFF difference reproduces diag_carve_frozen_check.R's +52.0 ppm
#      at 2300 (that run used x0.8053, this one x(1 - 0.19468) = x0.80532).
# Also prints the inert stock. No RNG. USAGE: Rscript calibration/diag_inert_pool_build_check.R
# ⭐ v2 (2026-09-30 f): the inert pool is now a STATE BOX (soil_inert) in land_C.
#   I2 therefore reads: every output column EXCEPT land_C byte-identical to the
#   proxy, land_C = proxy + the inert stock, the exchanging state rows identical,
#   the inert box unchanged over 1750-2300 with 14C = 0 and the passive d13C.
#   The periodic spinup (the objective's) solves with the pinned rows.
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f); ccx_load_cpp()
COMMIT <- ccx_git_stamp()
MODE <- ccx_path("calibration","output","multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452","promoted_basin1","mode_fit_pumpN.rds")
FREE <- c("beta_max","fert_k","luc_scale","q10","seas_T_amp_NH","seas_T_amp_SH","seas_lag_p_NH","seas_lag_p_SH","npp_frac_NH","kz","rep_dC")
F_IN <- ccx_const("SOIL_INERT_FRAC")
md <- readRDS(ccx_mode_file(MODE)); invisible(ccx_apply_pins(md$pins))
prev <- read.csv(ccx_path("outputs","diagnostics","npp0_scan_20260929.csv")); r1 <- prev[prev$scale == 1, ]
p0 <- as.list(ccx_unc_to_par(md$u_mode)); for (n in FREE) p0[[n]] <- r1[[n]]
ctrl <- readRDS(ccx_path("outputs","diagnostics","tau_soil_slow_profile_fixedstock_20260929.rds"))[[2]]; stopifnot(ctrl$value == 500)
base_for <- function(label) { bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  bp <- ccx_apply_structure(bp, label, as.character(md$seas_ml), pump_field = md$pump_field)
  for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]; bp }
run <- function(label, lsf_scale = 1) { pr <- p0; for (n in FREE) pr[[n]] <- ctrl$par[[n]]
  pu <- ccx_unc_to_par(ccx_par_to_unc(unlist(pr)[md$param_names])); b <- base_for(label)
  b$litter_slow_frac <- 0.05 * lsf_scale
  p <- ccx_overlay_par(b, pu); sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  r <- suppressWarnings(ccx_run_coupled(sp, "ssp585", c(1750L, 2300L), bomb_total_kmol = pu$bomb_total, luc_scale = pu$luc_scale))$out
  list(out = r, inert = unlist(sp$aux$soil_inert), sp = sp, p = p,
       end_inert = if (length(ccx_inert_idx(sp$aux))) r_end_inert(sp, pu) else NULL) }
r_end_inert <- function(sp, pu) {     # the inert rows of the 2300 end state
  rr <- suppressWarnings(ccx_run_coupled(sp, "ssp585", c(1750L, 2300L), bomb_total_kmol = pu$bomb_total, luc_scale = pu$luc_scale))
  rr$state[ccx_inert_idx(sp$aux), "C"] }
co2y <- function(r) { co2 <- tapply((r$co2_NH + r$co2_SH)/2, floor(r$t), mean); as.numeric(co2[c("2024","2100","2300")]) }
off <- run("hilda_csl3v0ka"); on <- run("hilda_csl3v0kai"); prx <- run("hilda_csl3v0ka", 1 - F_IN)
a <- co2y(off$out); b <- co2y(on$out)
cat(sprintf("SOIL_INERT_FRAC %.6f  (Copard 2025, 0-1 m)\n", F_IN))
cat(sprintf("I1 OFF (hilda_csl3v0ka) ssp585 2300 %.4f   [(v) control 1387.8816]  %s\n", a[3], if (abs(a[3] - 1387.8816) < 5e-4) "PASS" else "FAIL"))
ii <- ccx_inert_idx(on$sp$aux); inert_tot <- sum(on$sp$y[ii, "C"])
oth <- setdiff(names(on$out), "land_C")
same_cols <- identical(on$out[oth], prx$out[oth])
same_state <- identical(on$sp$y[-ii, ], prx$sp$y)
land_d <- max(abs(on$out$land_C - prx$out$land_C - inert_tot))
cat(sprintf("I2 ON vs hand proxy lsf x (1 - f): %d other output columns byte-identical: %s; exchanging spinup rows identical: %s; land_C - proxy - inert %.2e\n",
            length(oth), same_cols, same_state, land_d))
cat(sprintf("   => %s\n", if (same_cols && same_state && land_d < 1e-9) "PASS" else "FAIL"))
iso <- on$sp$y[ii, , drop = FALSE]; pas <- on$sp$y[unlist(lapply(HEMIS, function(h) on$sp$aux$idx[[h]]$soil_slow)), , drop = FALSE]
cat(sprintf("   inert box at spinup: C %s | d13C %s vs passive %s | 14C %s\n", paste(sprintf("%.3f", iso[, "C"]), collapse = "/"),
            paste(sprintf("%.4f", 1000 * (iso[, "C13"] / iso[, "C"] / ccx_const("R13_VPDB") - 1)), collapse = "/"),
            paste(sprintf("%.4f", 1000 * (pas[, "C13"] / pas[, "C"] / ccx_const("R13_VPDB") - 1)), collapse = "/"),
            paste(format(iso[, "C14"]), collapse = "/")))
cat(sprintf("   inert box 1750 -> 2300 change: %.2e GtC\n", max(abs(on$end_inert - iso[, "C"]))))
cat(sprintf("I3 ON - OFF: 2024 %+.2f  2100 %+.1f  2300 %+.2f ppm   [(v) frozen x0.8053: +2.10 / +52.0]\n", b[1]-a[1], b[2]-a[2], b[3]-a[3]))
ex <- sapply(HEMIS, function(h) on$sp$y[on$sp$aux$idx[[h]]$soil_slow, "C"])
unc <- sapply(HEMIS, function(h) off$sp$y[off$sp$aux$idx[[h]]$soil_slow, "C"])
cat(sprintf("inert stock NH %.1f SH %.1f total %.1f GtC; exchanging passive %.1f; uncarved passive %.1f; closure %.2e\n",
            on$inert[1], on$inert[2], sum(on$inert), sum(ex), sum(unc), sum(ex) + sum(on$inert) - sum(unc)))
cat(sprintf("provenance: mode %s; FREE names from the fixed-stock tau-500 control (tau_soil_slow_profile_fixedstock_20260929.rds); forcing ssp585 1750-2300; commit %s\n",
            basename(dirname(dirname(MODE))), COMMIT))
