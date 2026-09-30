# =====================================================================
# diag_ndep_form_efficiency.R -- DOES THE NPP-MULTIPLIER FORM TURN N DEPOSITION INTO
# THE SINK THE LITERATURE MEASURES? (2026-09-30 l)
#
# ⛔ A RECORD, NOT A LIVE DRIVER. It answered NO (0.37-0.70 kg C/kg N at the prior
# centre, gate 0.6-8.7; ndep_form_efficiency_20260930.log), and Marcus ruled the
# RETENTION FLUX the same day (CHANGELOG 09-30 m). `gamma_ndep` was then REMOVED from
# both cores, so re-running this at a later commit would set a field nothing reads and
# report ZERO effect -- the silent-gate shape. Run it only at 74896c5.
#
# The D2 (a) smoke (alignment_screen_smoke_d2) read 0.40 kg C per kg N at the gamma
# prior centre, below the pre-registered gate 0.6-8.7 (P-D2-2). Hypothesis, stated
# before this run: the multiplier NPP x (1 + gamma ndep) makes the sink track the
# RATE OF CHANGE of deposition (pools relax to a new equilibrium), while the
# literature's kg C/kg N is a STEADY ratio of sink RATE to deposition RATE (N
# retained in wood and SOM binds C for as long as deposition continues). If so, the
# form's sink per N is front-loaded (largest in the decades deposition rose fastest,
# 1950-1980) and small after ~1990, whatever gamma is.
#
# WHAT: the alignment control (as diag_imb_alloc_preview.R builds it), run with
# gamma_ndep = k x the prior centre for k in {0, 1, 5}; residual land sink, NPP and
# land deposition by window. Sink per N = (sink(k) - sink(0)) / deposition.
# No fit, no RNG. USAGE: Rscript calibration/diag_ndep_form_efficiency.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source("calibration/lib_design_gates.R")
NF_DRIVER <- "calibration/diag_ndep_form_efficiency.R"
NF_OUT    <- ccx_path("outputs", "diagnostics", sprintf("ndep_form_efficiency_%s", format(Sys.Date(), "%Y%m%d")))
NF_MODE   <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
NF_STRUCT <- "hilda_csl3v0kai"
NF_CTRL_PROFILE <- ccx_path("outputs", "diagnostics", "tau_soil_slow_profile_fixedstock_stock8053_20260929.rds")
NF_CTRL_VALUE <- 500; NF_FEX_PROXY <- 0.8053
NF_FREE11 <- c("beta_max", "fert_k", "luc_scale", "q10", "seas_T_amp_NH", "seas_T_amp_SH",
               "seas_lag_p_NH", "seas_lag_p_SH", "npp_frac_NH", "kz", "rep_dC")
NF_K      <- c(0, 1, 5)                                   # multiples of the prior centre
NF_WIN    <- list(c(1950L, 1979L), c(1980L, 1999L), c(2000L, 2023L), c(1990L, 2023L))
NF_GATE   <- c(0.6, 8.7)                                  # kg C/kg N, land mean (lit note sec. 2a(iv))
NF_CENTRE <- ccx_const("GAMMA_NDEP_PRIOR_R") * 1e-3 / ccx_const("NPP_GLOBAL_PI")
COMMIT <- tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")

md <- readRDS(ccx_mode_file(NF_MODE)); invisible(ccx_apply_pins(md$pins))
cp <- readRDS(NF_CTRL_PROFILE); ctrl <- cp[[which(vapply(cp, `[[`, numeric(1), "value") == NF_CTRL_VALUE)]]
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
bp <- ccx_apply_structure(bp, NF_STRUCT, as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
for (n in names(ctrl$over)) bp[[n]] <- ctrl$over[[n]]
bp$litter_slow_frac <- ctrl$over$litter_slow_frac / NF_FEX_PROXY
p0 <- as.list(ccx_unc_to_par(md$u_mode)); for (n in NF_FREE11) p0[[n]] <- ctrl$par[[n]]
pv <- ccx_unc_to_par(ccx_par_to_unc(unlist(p0)[md$param_names]))
nd <- readRDS(ccx_path("data", CCX_NDEP_FILE)); nd <- as.data.frame(nd[nd$scenario == "historical", ])

run_k <- function(k) {
  p <- ccx_overlay_par(bp, pv); p$gamma_ndep <- k * NF_CENTRE
  sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
  F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = pv$bomb_total,
                          luc_scale = pv$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
  r <- ccx_run_fast(sp, F); r$F <- F
  a <- dg_annual_sinks(r)
  npp <- tapply(r$npp$npp_NH + r$npp$npp_SH, floor(r$npp$t), mean)
  list(a = a, npp = npp)
}
R <- lapply(NF_K, run_k); names(R) <- NF_K

sink(paste0(NF_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE === %s @%s, run %s; %s control (%s tau %g); gamma centre %.4g per Tg N/yr; no RNG\n",
            NF_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), NF_STRUCT, basename(NF_CTRL_PROFILE), NF_CTRL_VALUE, NF_CENTRE))
cat("residual land sink and NPP differences vs gamma 0, by window (GtC/yr); deposition onto land (Tg N/yr)\n")
cat(sprintf("%-11s %8s %9s | %s\n", "window", "ndep", "d(ndep)/dt", paste(sprintf("k=%-3g dSink  dNPP  kgC/kgN", NF_K[-1]), collapse = " | ")))
for (w in NF_WIN) {
  kk <- nd$year >= w[1] & nd$year <= w[2]; dep <- mean(nd$ndep_land[kk])
  slope <- unname(stats::coef(stats::lm(ndep_land ~ year, nd[kk, ]))[2])
  cells <- vapply(NF_K[-1], function(k) {
    a1 <- R[[as.character(k)]]$a; a0 <- R[["0"]]$a; ka <- a1$year >= w[1] & a1$year <= w[2]
    ds <- mean(a1$land[ka] - a0$land[ka])
    yy <- as.character(w[1]:w[2]); dn <- mean(R[[as.character(k)]]$npp[yy] - R[["0"]]$npp[yy])
    sprintf("%9.4f %5.3f %7.2f", ds, dn, ds * 1e3 / dep)
  }, "")
  cat(sprintf("%d-%d %8.2f %9.3f | %s\n", w[1], w[2], dep, slope, paste(cells, collapse = " | ")))
}
cat(sprintf("literature gate (land-mean sink per N): %.1f-%.1f kg C/kg N; central 3.9 (lit note sec. 2a(iv))\n", NF_GATE[1], NF_GATE[2]))
sink()
