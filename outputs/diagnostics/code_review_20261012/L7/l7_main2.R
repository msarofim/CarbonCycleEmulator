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

  pe <- new.env(parent = environment())
  for (f in list.files(file.path(APPD, "R"), pattern = "[.]R$", full.names = TRUE)) sys.source(f, envir = pe)
  ccx_global_co2 <- pe$ccx_global_co2
  ann <- function(out) { g <- (out$co2_NH + out$co2_SH) / 2; a <- tapply(g, floor(out$t), mean); data.frame(year = as.integer(names(a)), co2 = as.numeric(a)) }
  h <- ann(APP_HIST$out)
  session$setInputs(f_mode = "Scenarios", f_yvar = "co2_ppm", f_fair = TRUE, f_scen = unname(APP_SCENARIOS))
  rs <- future_runs()
  # ---------------- W. land crossing year (w_luc_note)
  hdr("W. w_luc_note crossing")
  session$setInputs(w_years = c(1850, 2024))
  cat("w_luc_note:", output$w_luc_note, "\n")
  k <- APP_LUC_SMOOTH_YR
  cross <- function(year, v) { sm <- stats::filter(v, rep(1 / k, k), sides = 2); i <- which(!is.na(sm) & sm > 0)
    if (!length(i)) return(NA_integer_); if (i[1] == which(!is.na(sm))[1]) return(NA_integer_); year[i[1]] }
  Fh <- app_build_forcing("historical", APP_HIST_YEARS, prod_c14 = APP_SPIN$prod_c14)
  pt <- pe$partition_table(APP_HIST$out, Fh)
  a <- stats::aggregate(list(g = pt$land_gross), list(year = floor(pt$t)), mean)
  cat("app construction (diff of annual means, labelled y):", cross(a$year[-1], diff(a$g)), "\n")
  sa <- pe$app_sinks_annual(APP_HIST$out, Fh); el <- ccx_forcing_eluc_annual(Fh)
  net <- sa$land_sink - el$eluc[match(sa$yr, el$year)]
  cat("calendar-year construction (app_sinks_annual, GCB convention):", cross(sa$yr, net), "\n")
  cat("GCB:", cross(APP_GCB$year, APP_GCB$land_sink - APP_GCB$luc), "\n")
  sm1 <- stats::filter(diff(a$g), rep(1/k, k), sides = 2); sm2 <- stats::filter(net, rep(1/k, k), sides = 2)
  yy <- 1960:1975
  print(data.frame(year = yy, app = round(sm1[match(yy, a$year[-1])], 4), calendar = round(sm2[match(yy, sa$yr)], 4)))
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

  hdr("C2. pulse lab (vvH, 2100, 500)")
  session$setInputs(f_mode = "Pulse lab", f_yvar = "co2_ppm", f_fair = TRUE, p_bg = "vvH", p_year = 2100, p_gtc = 500, p_go = 2)
  pr2 <- pulse_runs()
  cat("takeaway co2:", output$f_takeaway, "\n")
  cat("fair note:", gsub("<[^>]+>", " ", paste(as.character(output$f_fair_note$html), collapse = "")), "\n")
  cat("notes:", gsub("<[^>]+>", " ", paste(as.character(output$f_notes$html), collapse = "")), "\n")
  session$setInputs(f_yvar = "gmst"); cat("takeaway gmst:", output$f_takeaway, "\n")
  perm <- output$f_pulse_permanence
  cat("permanence:", substr(gsub("<[^>]+>", " ", as.character(perm$html)), 1, 500), "\n")
  # a change of inputs WITHOUT pressing the button: the pulse outputs must still describe the run
  session$setInputs(p_bg = "vvL", p_year = 2030, p_gtc = 10, f_yvar = "co2_ppm")
  cat("after moving sliders w/o pressing, takeaway:", substr(output$f_takeaway, 1, 80), "\n")
  cat("fair note after moving sliders:", gsub("<[^>]+>", " ", paste(as.character(output$f_fair_note$html), collapse = "")), "\n")
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
