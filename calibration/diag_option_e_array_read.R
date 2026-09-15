# =====================================================================
# diag_option_e_array_read.R -- THE E ARRAY READ (Torch 17839702, 2026-09-15):
# PE-1 / PE-2 / PE-4 / PE-5 (prereg notes/prereg_2026-09-14h_option_e_ventilation.md
# §4) at the array's best start, side by side with the canonical hilda30c on ITS
# OWN (solved-field) objective, and with the incumbent-seeded basin. Streams are
# scored like-for-like (each vector under its own structure + spinup). READ, not
# gated -- nothing is adopted here; the mode is not promoted.
# Usage: Rscript calibration/diag_option_e_array_read.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
EA_DIR  <- ccx_path("calibration", "output", "multistart_20260913_eqcell_hilda_c_seasml1_martin_pin_ent_seas_amp_SH=0_pump_grad=314.1031_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452")
EA_JOB  <- "Torch 17839702"
EA_BEST <- 14L    # the collector's rank 1 (10 starts agree to 1e-4)
EA_INC  <- 1L     # the incumbent-seeded basin, -7.5 below
EA_OUT  <- ccx_path("outputs", "diagnostics", sprintf("option_e_array_read_%s", format(Sys.Date(), "%Y%m%d")))
PE1_KZ  <- 4000;  PE2_TGT <- ccx_ocean_gradient_target()$dic;  PE4_FROM <- 0.40; PE4_TO <- 0.89
EXPORT_2SD <- exp(log(ccx_pump_export_prior()$centre_gtc) + c(-2, 2) * ccx_pump_export_prior()$log_sd)
sink_log <- file(paste0(EA_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)

# a start file -> a dg vector (mirrors dg_vector() for a mode file; the start's own struct/seas_ml/field/pins)
start_vector <- function(id) {
  s <- readRDS(file.path(EA_DIR, sprintf("start_%03d.rds", id)))
  pins <- s$pins
  .todo <- pins[names(pins) %in% CCX_PARAM_NAMES]   # idempotent: the second start file finds them pinned already
  if (length(.todo)) invisible(ccx_apply_pins(.todo))
  p <- ccx_default_params(); p$pump_mode <- s$pump_mode
  p <- ccx_apply_structure(p, s$struct, s$seas_ml, pump_field = s$pump_field)
  for (n in names(pins)) p[[n]] <- pins[[n]]
  pm <- s$par_mode; for (n in names(pins)) pm[[n]] <- pins[[n]]
  for (n in intersect(names(p), names(pm))) p[[n]] <- pm[[n]]
  p <- ccx_set_enso(p, pm)
  list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total, sigma_d14c = pm$sigma_d14c,
       rep_dC = pm$rep_dC, grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c,
       spinup = CCX_OBJECTIVE_SPINUP, spinup_label = "periodic", pins = pins,
       src = sprintf("%s start_%03d (logpost %.4f, %s)", EA_JOB, id, s$logpost, s$kind), s = s)
}
conc <- function(y, aux, grid, h, k) {
  m <- if (k == 0) aux$a_ml[[h]] * grid$dz[1] else aux$a_ls[[h]] * grid$dz[k + 1]
  i <- if (k == 0) aux$idx[[h]]$ml else aux$idx[[h]]$oc[k]
  y[i, "C"] * aux$mol_per_GtC / (m * ccx_const("RHO_SEAWATER")) * 1e6 }
en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))); en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
obs <- ccx_prepare_obs(); g <- obs$gcb; mg <- merge(g[, c("year", "ocean_sink")], en_ann, by = "year")
mg <- mg[stats::complete.cases(mg) & mg$year >= 1959 & mg$year <= 2024, ]
OBS_SLOPE <- coef(stats::lm(ocean_sink ~ year + nino34_anom, data = mg))[["nino34_anom"]]
enso_stat <- function(r) { s <- dg_annual_sinks(r); d <- merge(data.frame(year = s$year, oc = s$ocean), en_ann, by = "year")
  d <- d[d$year >= 1959 & d$year <= 2024, ]; f <- stats::lm(oc ~ year + nino34_anom, d)
  c(slope = coef(f)[["nino34_anom"]], r = stats::cor(residuals(stats::lm(oc ~ year, d)), d$nino34_anom)) }
OH <- dg_gateH_obs(obs)

arms <- list(canonical = dg_vector(CCX_MODE_CANONICAL), e_best = start_vector(EA_BEST), e_incbasin = start_vector(EA_INC))
RES <- list()
for (a in names(arms)) {
  v <- arms[[a]]; cat(sprintf("\n==== %s: %s\n", a, v$src))
  cat(sprintf("  struct %s, seas_ml %s, pump_field %s; pins %s\n", attr(v$p, "struct"), attr(v$p, "seas_ml"),
              if (is.null(v$p$pump_field)) "solved" else v$p$pump_field, ccx_pin_label(v$pins)))
  re <- dg_run(v); sp <- re$sp; aux <- sp$aux; grid <- sp$grid; y <- sp$y; o <- re$out
  stv <- unlist(dg_streams(re, v)); e <- enso_stat(re)
  pr <- sapply(HEMIS, function(h) c(conc(y, aux, grid, h, 1), conc(y, aux, grid, h, 2), conc(y, aux, grid, h, 6), conc(y, aux, grid, h, grid$nl)) - conc(y, aux, grid, h, 0))
  tg <- ccx_ocean_gradient_target()
  gr <- ccx_model_ocean_gradient(o, aux, grid, list(surf = tg$d13c$epoch_surf, deep = tg$d13c$epoch_deep))
  bot14 <- mean(vapply(HEMIS, function(h) { i <- aux$idx[[h]]$oc[grid$nl]; (y[i, "C14"] / y[i, "C"] - 1) * 1000 }, numeric(1)))
  export <- if (identical(v$p$pump_field, "martin")) v$p$pump_export else sum(unlist(lapply(HEMIS, function(h) aux$pump[[h]]$org + aux$pump[[h]]$carb)))
  gh <- dg_gateH(v, obs, OH, r = re); gl <- dg_gateGL_verdict(gh, OH)
  cat(sprintf("  kz %.0f (deep frac %.4f -> %.0f), h_ml %.1f m, substeps %d, export %.2f GtC/yr%s\n", v$p$kz, v$p$kz_deep_frac,
              v$p$kz * v$p$kz_deep_frac, v$p$h_ml, ccx_substeps_for(v$p), export,
              if (identical(v$p$pump_field, "martin")) sprintf(", w_vent %.1f Sv, gamma_vent %.3f", v$p$w_vent, v$p$gamma_vent) else " (solved field, gross)"))
  cat(sprintf("  PI DIC minus ML (umol/kg, hemi mean): layer1 %+.0f, layer2 %+.0f, layer6 %+.0f, bottom %+.0f\n", mean(pr[1, ]), mean(pr[2, ]), mean(pr[3, ]), mean(pr[4, ])))
  cat(sprintf("  modern surface-deep gradient: DIC %.1f (target %.0f +- %.1f, z %+.2f), d13C %.3f (target %.3f, z %+.2f); deep D14C %.0f\n",
              gr$dic, tg$dic$target, tg$dic$sd, (gr$dic - tg$dic$target) / tg$dic$sd, gr$d13c, tg$d13c$target, (gr$d13c - tg$d13c$target) / tg$d13c$sd, bot14))
  cat(sprintf("  ENSO ocean slope %.3f = %.2fx obs, r %+.3f\n", e[["slope"]], e[["slope"]] / OBS_SLOPE, e[["r"]]))
  cat(sprintf("  GATE GL (interhemispheric d13C level): model %.4f obs %.4f ratio %.2fx z %+.2f -> %s\n", gl$model, gl$obs, gl$ratio, gl$z, if (gl$pass) "PASS" else "FAIL"))
  cat(sprintf("  loglik (25 rows) %.2f; total logpost (own objective) %s\n", sum(stv), if (!is.null(v$s)) sprintf("%.4f", v$s$logpost) else sprintf("%.4f (stored)", v$md$logpost)))
  RES[[a]] <- list(v = list(p = v$p, pm = v$pm, src = v$src), streams = stv, profile = pr, grad = gr, bottom_d14c = bot14, enso = e, gl = gl, export = export)
}
cat("\n==== PE READS (best start vs canonical; prereg §4) ====\n")
b <- RES$e_best; c0 <- RES$canonical
bomb_d <- sum(b$streams[c("d14c_NH", "d14c_SH")]) - sum(c0$streams[c("d14c_NH", "d14c_SH")])
cat(sprintf("PE-1  kz at the ML base %.0f (canonical %.0f, x%.2f); requires < %d (> 2.7x): %s. Bomb rows d14c_NH+SH %+.2f vs the canonical (within 2 required): %s\n",
            b$v$p$kz, c0$v$p$kz, c0$v$p$kz / b$v$p$kz, PE1_KZ, if (b$v$p$kz < PE1_KZ) "PASS" else "FAIL", bomb_d, if (abs(bomb_d) <= 2) "PASS" else "FAIL"))
cat(sprintf("PE-2  emergent DIC gradient %.1f vs %.0f +- %.1f (z %+.2f) at export %.2f (prior 2sd %.1f-%.1f): %s\n", b$grad$dic, PE2_TGT$target, PE2_TGT$sd,
            (b$grad$dic - PE2_TGT$target) / PE2_TGT$sd, b$export, EXPORT_2SD[1], EXPORT_2SD[2],
            if (abs(b$grad$dic - PE2_TGT$target) <= PE2_TGT$sd && b$export >= EXPORT_2SD[1] && b$export <= EXPORT_2SD[2]) "PASS" else "FAIL"))
cat(sprintf("PE-4  d13C gradient |%.3f| (canonical |%.3f|; prereg: from %.2f toward %.2f); GATE GL ratio %.2fx (canonical %.2fx; 'moves for the first time'): %s\n",
            abs(b$grad$d13c), abs(c0$grad$d13c), PE4_FROM, PE4_TO, b$gl$ratio, c0$gl$ratio,
            if (abs(b$grad$d13c) > abs(c0$grad$d13c) && abs(b$gl$ratio - c0$gl$ratio) > 0.05) "MOVED" else "UNMOVED"))
cat(sprintf("PE-5  ENSO ocean slope %.2fx obs (r %+.3f) at gamma_vent %.3f, w_vent %.0f Sv (canonical, option A: %.2fx, r %+.3f)\n",
            b$enso[["slope"]] / OBS_SLOPE, b$enso[["r"]], b$v$p$gamma_vent, b$v$p$w_vent, c0$enso[["slope"]] / OBS_SLOPE, c0$enso[["r"]]))
cm <- intersect(names(b$streams), names(c0$streams)); d <- b$streams[cm] - c0$streams[cm]
cat(sprintf("\nstreams, best minus canonical (like-for-like, each under its own objective): total %+.1f\n", sum(d)))
print(round(sort(d), 2))
saveRDS(list(res = RES, obs_slope = OBS_SLOPE, job = EA_JOB, best_id = EA_BEST, built = format(Sys.time())), paste0(EA_OUT, ".rds"))
cat("\nsaved", paste0(EA_OUT, ".rds"), "\n⛔ NOTHING IS ADOPTED; the mode is NOT promoted.\n")
