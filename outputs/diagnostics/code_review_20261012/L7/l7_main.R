# L7 review: how the app drives the model. READ-ONLY on the repo.
suppressPackageStartupMessages(library(shiny))
ROOT <- "/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator"
APPD <- file.path(ROOT, "app")
OUT  <- "/private/tmp/claude-501/-Users-MarcusMarcus-Documents-2026-CodeProjects-CarbonCycleEmulator/fa6620c3-fcfb-49a4-a787-90d23c00188e/scratchpad/review/L7"
setwd(APPD)
t0 <- Sys.time()
hdr <- function(...) cat("\n==== ", ..., " ====\n", sep = "")
try1 <- function(label, expr) tryCatch(expr, error = function(e) cat("ERROR in", label, ":", conditionMessage(e), "\n"))

testServer(APPD, {
  hdr("startup ", format(difftime(Sys.time(), t0, units = "secs")))

  # ---------------- A. switches the canonical turns on
  hdr("A. canonical switches")
  p <- APP_PARAMS
  cat("CCX_MODE_CANONICAL:", CCX_MODE_CANONICAL, " mode file:", ccx_mode_file(), "\n")
  cat("app_params source/status:", app_params$source, "/", app_params$status, "\n")
  cat("spinup:", APP_SPINUP_LABEL, " bomb_total:", APP_BOMB_TOTAL, " luc_scale:", APP_LUC_SCALE, " rep_dC:", APP_REP_DC, "\n")
  md <- readRDS(ccx_mode_file())
  cat("mode struct:", tryCatch(ccx_mode_struct(md), error = function(e) conditionMessage(e)), "\n")
  preds <- c(inert = ccx_inert_on(p), tr = ccx_tr_on(p), eq = ccx_eq_on(p), hs = ccx_hs_on(p),
             seas_ml = ccx_seas_ml_on(p), seas_ml_ls = ccx_seas_ml_ls_on(p), seas_ml_hs = ccx_seas_ml_hs_on(p),
             mix = ccx_mix_on(p), l2 = ccx_l2_on(p))
  print(preds)
  cat("enso_index:", ccx_enso_index_of(p), " aod_mode:", ccx_aod_mode_of(p), " pump_mode:", p$pump_mode, "\n")
  cat("n fitted:", length(md$param_names), " n pins:", length(ccx_mode_pins(md)), "\n")
  # independent re-derivation of the run params
  pm <- ccx_mode_par_with_pins(md); if (length(ccx_mode_absent(md))) pm <- ccx_migrate_par_set(pm)
  rp <- ccx_mode_run_params(md, pm)
  cat("APP_PARAMS identical to ccx_mode_run_params()$p:", identical(rp$p, APP_PARAMS),
      " bomb:", identical(rp$bomb_total, APP_BOMB_TOTAL), " luc:", identical(rp$luc_scale, APP_LUC_SCALE), "\n")

  # ---------------- F. ribbons hold
  hdr("F. ribbons")
  cat("APP_RIBBONS$ok:", APP_RIBBONS$ok, " held:", isTRUE(APP_RIBBONS$held), "\n")
  cat("bands NULL co2:", is.null(app_future_bands(unname(APP_SCENARIOS), "co2_ppm")),
      " gmst:", is.null(app_future_bands(unname(APP_SCENARIOS), "gmst")), "\n")
  cat("APP_RIBBON_NOTE NULL:", is.null(APP_RIBBON_NOTE), " note(co2) NULL:", is.null(app_ribbon_note("co2_ppm")),
      " note(gmst) NULL:", is.null(app_ribbon_note("gmst")), "\n")
  rib <- readRDS(APP_RIBBONS_FILE)
  cat("ribbons file problems:", paste(ccx_ribbons_problems(rib, CCX_MODE_CANONICAL, APP_SCENARIOS, APP_FUTURE_YVARS), collapse = "; "), "\n")
  cat("ribbon provenance names:", paste(names(rib$provenance), collapse = ", "), "\n")
  for (nm in intersect(c("mode", "label", "method", "years", "interp", "emis_method", "splice", "n_ok", "probs", "climate", "commit"), names(rib$provenance)))
    cat("  ", nm, ":", paste(format(rib$provenance[[nm]]), collapse = " "), "\n")

  # ---------------- G/H. futures, splice, FaIR overlay
  hdr("D. scenarios: all 7")
  session$setInputs(f_mode = "Scenarios", f_yvar = "co2_ppm", f_fair = TRUE, f_scen = unname(APP_SCENARIOS))
  rs <- future_runs()
  fin <- t(sapply(rs, function(r) { cl <- r$climate; c(year = max(cl$year), co2 = cl$co2_ppm[nrow(cl)], gmst = cl$gmst[nrow(cl)]) }))
  print(round(fin, 3))
  cat("takeaway(all 7):", output$f_takeaway, "\n")
  for (sel in list(c("vvM", "vvHL", "vvH"), c("vvVL", "vvLN"), c("vvL", "vvM", "vvH"), c("vvVL", "vvLN", "vvL"))) {
    session$setInputs(f_scen = sel)
    rr <- future_runs(); v <- sapply(rr, function(r) tail(r$climate$co2_ppm, 1)); g <- sapply(rr, function(r) tail(r$climate$gmst, 1))
    cat("sel", paste(sel, collapse = ","), "-> true CO2 span", sprintf("%.0f-%.0f", min(v), max(v)),
        " true GMST span", sprintf("%.1f-%.1f", min(g), max(g)), "\n   takeaway:", output$f_takeaway, "\n")
  }
  session$setInputs(f_scen = unname(APP_SCENARIOS))
  rs <- future_runs()
  # FaIR overlay
  fo <- app_fair_overlay(APP_SCENARIOS[APP_SCENARIOS %in% c("vvL", "vvM")], "gmst")
  cat("APP_FAIR null:", is.null(APP_FAIR), " overlay rows:", if (is.null(fo)) NA else nrow(fo), " labels:", paste(unique(fo$who), collapse = " | "), "\n")
  cat("APP_FAIR scenarios:", paste(sort(unique(APP_FAIR$scenario)), collapse = ","), "\n")
  # cross-tab past
  hdr("G. splice / cross-tab past")
  ann <- function(out) { g <- (out$co2_NH + out$co2_SH) / 2; a <- tapply(g, floor(out$t), mean); data.frame(year = as.integer(names(a)), co2 = as.numeric(a)) }
  h <- ann(APP_HIST$out)
  cat("APP_SPLICE_YEAR:", APP_SPLICE_YEAR, " APP_HIST_YEARS:", APP_HIST_YEARS, "\n")
  for (nm in names(rs)) {
    f <- ann(rs[[nm]]$out); k <- f$year <= APP_SPLICE_YEAR
    d <- f$co2[k] - h$co2[match(f$year[k], h$year)]
    cat(sprintf("  %-45s past max|d| %.4f ppm (yr %d), d@2024 %+.4f\n", nm, max(abs(d)), f$year[k][which.max(abs(d))], tail(d, 1)))
  }
  # gmst past: future run's monthly gmst vs historical forcing gmst
  Fh <- APP_HIST$forcing
  cat("  gmst column: hist forcing vs vvM coupled F (no F returned?) names(rs[[1]]):", paste(names(rs[[1]]), collapse = ","), "\n")
  saveRDS(list(fin = fin, h = h), file.path(OUT, "scen.rds"))

  # ---------------- C. pulse lab
  hdr("C. pulse lab (vvM, 2050, 100)")
  tp0 <- Sys.time()
  session$setInputs(f_mode = "Pulse lab", f_yvar = "co2_ppm", f_fair = TRUE, p_bg = "vvM", p_year = 2050, p_gtc = 100, p_go = 1)
  pr <- pulse_runs()
  cat("pulse runs took", format(difftime(Sys.time(), tp0, units = "secs")), "\n")
  cb <- pr$base$climate; cp <- pr$pulse$climate; ct <- pr$tagged$climate
  pre <- cb$year < 2050
  cat("pre-pulse annual: max|dCO2|", max(abs(cp$co2_ppm[pre] - cb$co2_ppm[pre])), " max|dT|", max(abs(cp$gmst[pre] - cb$gmst[pre])), "\n")
  km <- pr$base$out$t < 2050
  cat("pre-pulse monthly: max|dco2_NH|", max(abs(pr$pulse$out$co2_NH[km] - pr$base$out$co2_NH[km])),
      " max|dland_C|", max(abs(pr$pulse$out$land_C[km] - pr$base$out$land_C[km])), "\n")
  cat("tagged vs pulse: max|dco2_NH|", max(abs(pr$tagged$out$co2_NH - pr$pulse$out$co2_NH)),
      " max|dland|", max(abs(pr$tagged$out$land_C - pr$pulse$out$land_C)),
      " max|docean|", max(abs(pr$tagged$out$ocean_C - pr$pulse$out$ocean_C)),
      " max|dT|", max(abs(ct$gmst - cp$gmst)), "\n")
  cat("iterations base/pulse/tagged:", pr$base$iterations, pr$pulse$iterations, pr$tagged$iterations,
      " converged:", pr$base$converged, pr$pulse$converged, pr$tagged$converged, "\n")
  cat("tag gtc:", pr$tagged$tag$gtc, " s_mid:", pr$tagged$tag$s_mid, "\n")
  # carbon budget of the pulse: total system carbon difference at end
  gp <- ccx_const("GtC_PER_PPM")
  dsys <- (ccx_global_co2(pr$pulse$out) - ccx_global_co2(pr$base$out)) * gp +
          (pr$pulse$out$land_C - pr$base$out$land_C) + (pr$pulse$out$ocean_C - pr$base$out$ocean_C)
  cat("GtC_PER_PPM:", gp, " system carbon diff at end:", tail(dsys, 1), " at 2051.04:", dsys[which.min(abs(pr$base$out$t - 2051.04))], "\n")
  # AF vs FaIR
  af <- (cp$co2_ppm - cb$co2_ppm) / (100 / gp)
  fr <- app_fair_pulse("vvM", 2050, 100)
  yy <- c(2050, 2051, 2055, 2060, 2075, 2100, 2150, 2200, 2300)
  print(data.frame(year = yy, ccx_af = round(af[match(yy, cb$year)], 4), fair_af = round(fr$af_mean[match(yy, fr$year)], 4),
                   fair_dppm = round(fr$d_co2_ppm_mean[match(yy, fr$year)], 3),
                   fair_implied_GtC_per_ppm = round(100 * fr$af_mean[match(yy, fr$year)] / fr$d_co2_ppm_mean[match(yy, fr$year)], 4)))
  cat("takeaway co2:", output$f_takeaway, "\n")
  cat("fair note:", paste(as.character(output$f_fair_note$html), collapse = ""), "\n")
  session$setInputs(f_yvar = "gmst")
  cat("takeaway gmst:", output$f_takeaway, "\n")
  perm <- output$f_pulse_permanence
  cat("permanence html:", substr(gsub("<[^>]+>", " ", as.character(perm$html)), 1, 900), "\n")
  # off-grid
  cat("why(vvM,2050,100):", format(app_fair_pulse_why("vvM", 2050, 100)), "\n")
  cat("why(vvM,2050,110):", format(app_fair_pulse_why("vvM", 2050, 110)), "\n")
  cat("why(vvM,2050,100+1e-9):", format(app_fair_pulse_why("vvM", 2050, 100 + 1e-9)), "\n")
  cat("why(vvH,2100,100):", format(app_fair_pulse_why("vvH", 2100, 100)), "\n")
  # pulse base vs scenario run of the same scenario
  fM <- rs[[names(APP_SCENARIOS)[APP_SCENARIOS == "vvM"]]]$climate
  k <- match(c(2024, 2025, 2026, 2030, 2050, 2100, 2150), cb$year); k2 <- match(c(2024, 2025, 2026, 2030, 2050, 2100, 2150), fM$year)
  print(data.frame(year = cb$year[k], pulse_base = round(cb$co2_ppm[k], 3), scen_tab = round(fM$co2_ppm[k2], 3),
                   d = round(cb$co2_ppm[k] - fM$co2_ppm[k2], 4), dT = round(cb$gmst[k] - fM$gmst[k2], 5)))
  saveRDS(list(base = pr$base$climate, pulse = pr$pulse$climate, tagged = ct, fair = fr), file.path(OUT, "pulse.rds"))

  # ---------------- J. build your own
  hdr("J. build your own")
  session$setInputs(f_mode = "Build your own", f_yvar = "co2_ppm", s_kind = "constant", s_bg = "vvM", s_rate = 1, s_zero_year = 2060, s_go = 1)
  sr <- stylised_run()
  cat("stylised takeaway:", output$f_takeaway, "\n")
  fs <- ann(sr$out); k <- fs$year <= APP_SPLICE_YEAR
  cat("stylised past vs hist max|d|:", max(abs(fs$co2[k] - h$co2[match(fs$year[k], h$year)])), "\n")
  session$setInputs(f_scen = character(0))
  r <- tryCatch({ future_runs(); "ok" }, error = function(e) paste("future_runs() with no scenario:", class(e)[1], conditionMessage(e)))
  cat(r, "\n")
  session$setInputs(f_scen = unname(APP_SCENARIO_COMPARE))

  # ---------------- I. Keeling takeaway
  hdr("I. Keeling / isotope takeaway")
  o <- APP_HIST$out
  i0 <- which.min(abs(o$t - 1958)); cat("k i0 t:", sprintf("%.6f", o$t[i0]), " neighbours:", sprintf("%.6f", o$t[i0 + (-1:1)]),
                                          " abs:", sprintf("%.17g", abs(o$t[i0 + (-1:1)] - 1958)), "\n")
  cat("k_takeaway:", output$k_takeaway, "\n")
  obs_mlo <- APP_OBS$co2[APP_OBS$co2$station == "MLO", ]
  cat("MLO years >=2023:", paste(range(obs_mlo$year[obs_mlo$year >= 2023]), collapse = "-"), " n:", sum(obs_mlo$year >= 2023), "\n")
  cat("model NH last month t:", tail(o$t, 1), " co2_NH:", tail(o$co2_NH, 1), " NH 2024 annual mean:", mean(o$co2_NH[floor(o$t) == 2024]),
      " minus rep_dC:", mean(o$co2_NH[floor(o$t) == 2024]) - APP_REP_DC, "\n")
  cat("MLO 2024 annual mean:", mean(obs_mlo$co2_ppm[obs_mlo$year == 2024]), " MLO mean(2023+):", mean(obs_mlo$co2_ppm[obs_mlo$year >= 2023]), "\n")
  i1 <- which.min(abs(o$t - 1850)); cat("i_takeaway i0 t:", sprintf("%.6f", o$t[i1]), "\n")
  cat("i_takeaway:", output$i_takeaway, "\n")

  # ---------------- E. what-if
  hdr("E. what-if")
  cat("mechanisms:", paste(names(CCX_MECHANISMS), collapse = ", "), "\n")
  te <- Sys.time()
  r0 <- app_run_mechanisms(character())
  cat("empty-switch rerun vs APP_HIST: max|dco2_NH|", max(abs(r0$out$co2_NH - APP_HIST$out$co2_NH)),
      " max|dd14c_NH|", max(abs(r0$out$d14c_NH - APP_HIST$out$d14c_NH)),
      " max|dd13c_NH|", max(abs(r0$out$d13c_NH - APP_HIST$out$d13c_NH)), " (", format(difftime(Sys.time(), te, units = "secs")), ")\n")
  # forcing identity
  Fd <- sapply(intersect(names(r0$forcing), names(APP_HIST$forcing)), function(n) {
    a <- r0$forcing[[n]]; b <- APP_HIST$forcing[[n]]; if (is.numeric(a)) max(abs(a - b)) else NA })
  cat("empty-switch forcing columns differing:", paste(names(Fd)[which(Fd > 0)], collapse = ","), "\n")
  set.seed(7)
  combos <- c(as.list(names(CCX_MECHANISMS)), list(names(CCX_MECHANISMS)),
              replicate(6, sample(names(CCX_MECHANISMS), sample(2:5, 1)), simplify = FALSE))
  for (cmb in combos) {
    te <- Sys.time()
    res <- tryCatch({
      session$setInputs(c_mech = cmb, c_years = c(1850, 2024))
      rr <- cf_run()
      sprintf("ok co2@end %.2f (base %.2f) caveats %d; takeaway: %s", tail(rr$out$co2_global, 1), tail(APP_HIST$out$co2_global, 1),
              length(rr$caveats), substr(output$c_takeaway, 1, 110))
    }, error = function(e) paste("ERROR:", conditionMessage(e)))
    cat(sprintf("  [%s] %s (%.1fs)\n", paste(cmb, collapse = "+"), res, as.numeric(difftime(Sys.time(), te, units = "secs"))))
  }
  session$setInputs(c_mech = character(0))
  cat("  [none] takeaway:", output$c_takeaway, "\n")
  hdr("done ", format(difftime(Sys.time(), t0, units = "secs")))
})
