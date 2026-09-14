# =====================================================================
# diag_option_e_probe.R -- THE UNREFITTED PROBE of option D + E at the
# canonical vector (prereg notes/prereg_2026-09-14h_option_e_ventilation.md
# §4 "unrefitted probe": READ, not gated). The canonical hilda30c vector with
# pump_field = "martin" at the prior's median export, the ventilation loop at
# w_vent in PE_W and gamma_vent in PE_G, against the solved-field reference.
# Per arm: the 25 rows (delta vs the reference, likelihood only -- the
# canonical is PINNED), the PI DIC profile (ML, layer 2, bottom), the modern
# surface-deep d13C gradient, the bomb rows, the deep D14C, the ENSO ocean
# slope vs GCB (the preview's statistic). Expected reading (prereg): the
# thermocline gradient collapses (5x less export at the old kz) and the bomb
# rows hold; the array is what moves kz (PE-1). Nothing adopted.
# Usage: Rscript calibration/diag_option_e_probe.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
PE_ARM   <- CCX_MODE_CANONICAL
PE_EXPORT <- ccx_pump_export_prior()$centre_gtc     # 9.08, the prior's median
PE_W     <- c(0, 40, 160, 284, 506)                 # Sv: 0, the first probe's top, the prior's two READINGS and its median
PE_G     <- c(0, 0.5)                               # per Nino3.4 unit
PE_OUT   <- ccx_path("outputs", "diagnostics", sprintf("option_e_probe_%s", format(Sys.Date(), "%Y%m%d")))
sink_log <- file(paste0(PE_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)

v0 <- dg_vector(PE_ARM)
cat(sprintf("arm %s: %s\n  canonical kz %.0f (deep %.0f), pump_grad %.1f, h_ml %.1f; spinup %s\n",
            PE_ARM, v0$src, v0$p$kz, v0$p$kz * v0$p$kz_deep_frac, v0$p$pump_grad, v0$p$h_ml, v0$spinup_label))
cat(sprintf("  martin arms: pump_export %.2f GtC/yr (Nowicki LS median; log-sd %.3f), MARTIN_B %.3f, layers %d-%d\n\n",
            PE_EXPORT, ccx_pump_export_prior()$log_sd, ccx_const("MARTIN_B"), v0$p$k_e1, v0$p$k_e2))
en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))); en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
obs <- ccx_prepare_obs(); g <- obs$gcb; mg <- merge(g[, c("year", "ocean_sink")], en_ann, by = "year")
mg <- mg[stats::complete.cases(mg) & mg$year >= 1959 & mg$year <= 2024, ]
OBS_SLOPE <- coef(stats::lm(ocean_sink ~ year + nino34_anom, data = mg))[["nino34_anom"]]
enso_stat <- function(r) { s <- dg_annual_sinks(r); d <- merge(data.frame(year = s$year, oc = s$ocean), en_ann, by = "year")
  d <- d[d$year >= 1959 & d$year <= 2024, ]; f <- stats::lm(oc ~ year + nino34_anom, d)
  c(slope = coef(f)[["nino34_anom"]], r = stats::cor(residuals(stats::lm(oc ~ year, d)), d$nino34_anom)) }
conc <- function(y, aux, grid, h, k) {   # umol/kg of interior layer k (0 = ML)
  m <- if (k == 0) aux$a_ml[[h]] * grid$dz[1] else aux$a_ls[[h]] * grid$dz[k + 1]
  i <- if (k == 0) aux$idx[[h]]$ml else aux$idx[[h]]$oc[k]
  y[i, "C"] * aux$mol_per_GtC / (m * ccx_const("RHO_SEAWATER")) * 1e6 }
# Every martin arm PINS gamma_enso_ocn_* at 0 (ruling E3: one limb; option A is
# subsumed), so the ENSO column reads the LOOP's modulation alone; "solved ocn0"
# is the solubility-only reference PE-5 names (r ~ -0.53 expected).
arms <- list(list(lab = "solved", field = "solved", w = 0, g = 0, ocn0 = FALSE),
             list(lab = "solved ocn0", field = "solved", w = 0, g = 0, ocn0 = TRUE))
for (w in PE_W) for (gg in PE_G) if (!(w == 0 && gg > 0)) arms[[length(arms) + 1]] <- list(lab = sprintf("martin w%g g%g", w, gg), field = "martin", w = w, g = gg, ocn0 = TRUE)
cat(sprintf("%-16s | %8s %8s %8s | %7s %7s | %8s %8s %8s %8s | %10s %7s | %8s %8s\n", "arm", "PI oc2-ml", "oc6-ml", "bot-ml", "d13c gr", "d14c bt",
            "d lik", "d grad", "d d13c", "d bomb", "ENSO/obs", "r", "d co2", "d d14cNS"))
RES <- list(); ref <- NULL
for (a in arms) {
  v <- v0; v$p$pump_field <- a$field; v$p$pump_export <- if (a$field == "martin") PE_EXPORT else 0
  v$p$w_vent <- a$w; v$p$gamma_vent <- a$g
  if (a$ocn0) { v$p$gamma_enso_ocn_NH <- 0; v$p$gamma_enso_ocn_SH <- 0 }
  re <- tryCatch(dg_run(v), error = function(e) { cat(sprintf("%-16s | FAILED: %s\n", a$lab, conditionMessage(e))); NULL })
  if (is.null(re)) next
  sp <- re$sp; aux <- sp$aux; grid <- sp$grid; y <- sp$y; o <- re$out
  stv <- unlist(dg_streams(re, v)); e <- enso_stat(re)
  if (is.null(ref)) ref <- stv
  cm <- intersect(names(stv), names(ref)); d <- stv[cm] - ref[cm]
  pr <- sapply(HEMIS, function(h) c(conc(y, aux, grid, h, 2), conc(y, aux, grid, h, 6), conc(y, aux, grid, h, grid$nl)) - conc(y, aux, grid, h, 0))
  tg <- ccx_ocean_gradient_target()
  gr <- ccx_model_ocean_gradient(o, aux, grid, list(surf = tg$d13c$epoch_surf, deep = tg$d13c$epoch_deep))
  d13 <- if (!is.null(gr)) gr$d13c else NA
  bot14 <- mean(vapply(HEMIS, function(h) { i <- aux$idx[[h]]$oc[grid$nl]
    (y[i, "C14"] / y[i, "C"] - 1) * 1000 }, numeric(1)))
  bomb <- sum(d[grep("^d14c_(NH|SH)$", cm)]); grad <- d["ocean_grad_dic"]; dd13 <- d["ocean_grad_d13c"]
  co2 <- sum(d[grep("^co2", cm)]); d14ns <- sum(d[grep("d14c", cm)])
  cat(sprintf("%-16s | %8.0f %8.0f %8.0f | %7.2f %7.0f | %+8.1f %+8.1f %+8.1f %+8.1f | %9.2fx %+7.3f | %+8.1f %+8.1f\n", a$lab,
              mean(pr[1, ]), mean(pr[2, ]), mean(pr[3, ]), d13, bot14, sum(d), grad, dd13, bomb, e[["slope"]] / OBS_SLOPE, e[["r"]], co2, d14ns))
  RES[[a$lab]] <- list(arm = a, profile = pr, d13c_grad = d13, bottom_d14c = bot14, streams = stv, delta = d, enso = e,
                       substeps = ccx_substeps_for(v$p), export = sum(unlist(lapply(HEMIS, function(h) aux$pump[[h]]$org + aux$pump[[h]]$carb))))
}
cat("\n(d lik = likelihood change on the 25 common rows vs the solved reference; d grad/d13c/bomb/co2/d14cNS = the ocean_grad_dic, ocean_grad_d13c, d14c_NH+SH, co2* and every d14c* row; ENSO/obs = the modelled ocean-sink Nino3.4 slope over the GCB-observed; PI concentrations umol/kg minus the ML)\n")
cat("substeps per arm:", paste(sprintf("%s=%d", names(RES), vapply(RES, function(r) r$substeps, integer(1))), collapse = "  "), "\n")
saveRDS(list(arms = RES, obs_slope = OBS_SLOPE, export = PE_EXPORT, canonical = PE_ARM, built = format(Sys.time())), paste0(PE_OUT, ".rds"))
cat("saved", paste0(PE_OUT, ".rds"), "\n")
