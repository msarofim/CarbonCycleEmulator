# =====================================================================
# diag_eq_cell_levers.R -- 2026-09-14 (c). SIZING THE SECOND BUILD'S LEVERS at the
# first array's best vector (Torch 17769990, start_011: w_eq 10.72 Sv, gamma_eq
# 0.600; PE8 FAIL -- w_eq at z -5.4 on Meinen's 27 +/- 3 Sv).
#
# The question: what does the B1 reservoir row read at W0 = 27 Sv (the
# observation) under each of the named lacks -- a colder cell (the cold-surfacing
# proxy: the whole cell at a lower air-sea temperature), a shallower source
# (k_eq = 1), both -- and WHAT the cell's excess is made of at 27 Sv: the
# temperature term (the mixed layer's DIC exposed at the cell's SST) versus the
# DIC term (the cell's DIC above the mixed layer's, at the cell's SST). The
# decomposition is exact to the carbonate routine's own arithmetic:
#   excess = [pco2(DIC_ml, alk_ml, T_eq) - pco2(DIC_ml, alk_ml, T_ml)]   (T term)
#          + [pco2(DIC_eq, alk_eq, T_eq) - pco2(DIC_ml, alk_ml, T_eq)]   (DIC + alk term)
# Every number goes to outputs/diagnostics/eq_cell_levers_<date>.{log,rds}.
# NOTHING is adopted; no core is touched.
# =====================================================================
suppressMessages({ source("tests/testthat/setup.R", chdir = TRUE); source("calibration/lib_design_gates.R") })
`%||%` <- function(a, b) if (is.null(a)) b else a
LV_DIR   <- "calibration/output/multistart_20260913_eqcell_hilda_eq_seasml1_pin_ent_seas_amp_SH=0_sd1.0452"
LV_START <- "start_011.rds"            # the array's best (10 tasks at -1450.5178 to 4 dp; id 0 CONVERGED there)
LV_W0    <- NULL                       # NULL = the Meinen prior mean from the product
LV_COLD  <- c(2, 4)                    # degC colder than the band mean, the cold-tongue bracket
LV_WIN   <- c(1959, 2024)              # the ENSO regression window (= SC_ENSO_WIN)
LV_OUT   <- ccx_path("outputs", "diagnostics", sprintf("eq_cell_levers_%s", format(Sys.Date(), "%Y%m%d")))
sink_log <- file(paste0(LV_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)

b <- readRDS(file.path(LV_DIR, LV_START))
stopifnot(identical(b$struct, "hilda_eq"), identical(b$seas_ml, 1L) || b$seas_ml == 1)
obs_eq <- ccx_eq_cell_obs(); W0 <- if (is.null(LV_W0)) obs_eq$w0_prior$mean_sv else LV_W0
base <- ccx_apply_structure(ccx_default_params(), "hilda_eq", seas_ml = 1); base$pump_mode <- b$pump_mode
pins <- c(ent_seas_amp_SH = 0); for (n in names(pins)) base[[n]] <- pins[[n]]
pm <- b$par_mode; p <- base
for (n in intersect(names(p), names(pm))) p[[n]] <- pm[[n]]
p <- ccx_set_enso(p, pm)
v0 <- list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total, sigma_d14c = pm$sigma_d14c,
           rep_dC = pm$rep_dC, grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c,
           spinup = ccx_periodic_spinup, spinup_label = "periodic", md = NULL, migrated = character(0),
           pins = pins, src = file.path(LV_DIR, LV_START))
cat(sprintf("vector: %s (logpost %.4f); w_eq %.3f Sv, gamma_eq %.4f; ML SST NH %g / SH %g C, cell %.2f C\n",
            v0$src, b$logpost, pm$w_eq, pm$gamma_eq, p$sst_NH, p$sst_SH, p$sst_eq))
tg <- ccx_eq_b1_target()
en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))); en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
obs <- ccx_prepare_obs(); g <- obs$gcb; mg <- merge(g[, c("year", "ocean_sink")], en_ann, by = "year")
mg <- mg[stats::complete.cases(mg) & mg$year >= LV_WIN[1] & mg$year <= LV_WIN[2], ]
OBS_SLOPE <- coef(stats::lm(ocean_sink ~ year + nino34_anom, data = mg))[["nino34_anom"]]
enso_stat <- function(r) { s <- dg_annual_sinks(r); d <- merge(data.frame(year = s$year, oc = s$ocean), en_ann, by = "year")
  d <- d[d$year >= LV_WIN[1] & d$year <= LV_WIN[2], ]; f <- stats::lm(oc ~ year + nino34_anom, d)
  c(slope = coef(f)[["nino34_anom"]], r = stats::cor(residuals(stats::lm(oc ~ year, d)), d$nino34_anom)) }
cat(sprintf("target B1 %+.2f +/- %.2f uatm; obs ENSO ocean slope %+.4f GtC/yr per index (%d-%d)\n\n", tg$target, tg$sd, OBS_SLOPE, LV_WIN[1], LV_WIN[2]))

decompose <- function(v, re, epoch = 1755) {
  # ⛔ NOT at the spinup's opening instant: at seas_ml = 1 an instant box read is
  # not the annual mean ([[seasonal_box_observable_artefact]] -- the NH mixed
  # layer opens the orbit at its winter DIC, 2187 vs an annual ~1990). ANNUAL MEAN
  # over the mass at the time (ccx_box_annual_conc, the ruled reader), one PI
  # epoch year; pCO2 of the annual-mean DIC at the box's mean SST -- an
  # attribution, not the row (the row is the annual mean of the deriv's pCO2).
  aux <- re$sp$aux; grid <- re$sp$grid; alk_ml <- ccx_const("ALK_SURFACE"); alk_eq <- v$p$alk_eq * 1e-6
  t(vapply(HEMIS, function(h) {
    T_ml <- aux$sst[[h]]; T_eq <- v$p$sst_eq
    # the reader returns the mass-weighted mean over `hemis`; one hemisphere at a time here
    dic_ml <- ccx_box_annual_conc(re$out, aux, grid, "ml", epoch, hemis = h)[["dic"]] * 1e-6
    dic_eq <- ccx_box_annual_conc(re$out, aux, grid, "eq", epoch, hemis = h)[["dic"]] * 1e-6
    p_ml <- pco2_from_dic(dic_ml, alk_ml, T_ml); p_eq <- pco2_from_dic(dic_eq, alk_eq, T_eq)
    p_mlT <- pco2_from_dic(dic_ml, alk_ml, T_eq)
    c(dic_ml = dic_ml * 1e6, dic_eq = dic_eq * 1e6, pco2_ml = p_ml, pco2_eq = p_eq,
      excess = p_eq - p_ml, T_term = p_mlT - p_ml, DIC_term = p_eq - p_mlT)
  }, numeric(7)))
}
run_case <- function(label, mod) {
  v <- v0; v$p <- mod(v$p)
  re <- dg_run(v); o <- re$out
  b1 <- ccx_model_eq_b1(o[o$t < DG_SINK_LAST + 1, ], re$sp$aux)
  pi_rows <- o$t < 1760
  exc <- mean(c(o$eq_pco2_NH[pi_rows] - o$ml_pco2_NH[pi_rows], o$eq_pco2_SH[pi_rows] - o$ml_pco2_SH[pi_rows]))
  e <- enso_stat(re); dc <- decompose(v, re)
  cat(sprintf("%-40s B1 %+6.1f (z %+5.2f)  PI cell-ML %+6.1f  ENSO slope %+.3f = %.2fx obs (r %+.3f)\n      decomposition, PI annual means (NH | SH): DIC ml %.0f | %.0f, cell %.0f | %.0f umol/kg; excess %+.0f | %+.0f = T-term %+.0f | %+.0f + DIC-term %+.0f | %+.0f uatm\n",
              label, b1$value, (b1$value - tg$target) / tg$sd, exc, e[["slope"]], e[["slope"]] / OBS_SLOPE, e[["r"]],
              dc["NH", "dic_ml"], dc["SH", "dic_ml"], dc["NH", "dic_eq"], dc["SH", "dic_eq"],
              dc["NH", "excess"], dc["SH", "excess"], dc["NH", "T_term"], dc["SH", "T_term"], dc["NH", "DIC_term"], dc["SH", "DIC_term"]))
  list(label = label, b1 = b1, z = (b1$value - tg$target) / tg$sd, pi_excess = exc, enso = e, decomp = dc, p = v$p[c("w_eq", "gamma_eq", "sst_eq", "k_eq")])
}
RES <- list(
  fit      = run_case(sprintf("FIT: w_eq %.2f, gamma %.3f, k %d", pm$w_eq, pm$gamma_eq, p$k_eq), identity),
  w0       = run_case(sprintf("w_eq %g (prior mean), else the fit", W0), function(p) { p$w_eq <- W0; p }),
  cold2    = run_case(sprintf("w_eq %g, cell %g C colder", W0, LV_COLD[1]), function(p) { p$w_eq <- W0; p$sst_eq <- p$sst_eq - LV_COLD[1]; p }),
  cold4    = run_case(sprintf("w_eq %g, cell %g C colder", W0, LV_COLD[2]), function(p) { p$w_eq <- W0; p$sst_eq <- p$sst_eq - LV_COLD[2]; p }),
  k1       = run_case(sprintf("w_eq %g, k_eq 1 (layer-1 source)", W0), function(p) { p$w_eq <- W0; p$k_eq <- 1L; p }),
  k1cold2  = run_case(sprintf("w_eq %g, k_eq 1, cell %g C colder", W0, LV_COLD[1]), function(p) { p$w_eq <- W0; p$k_eq <- 1L; p$sst_eq <- p$sst_eq - LV_COLD[1]; p }),
  mlT      = run_case(sprintf("w_eq %g, cell AT the ML's SST (the T-term switched off)", W0), function(p) { p$w_eq <- W0; p$sst_eq <- mean(c(p$sst_NH, p$sst_SH)); p })
)
cat(sprintf("\nREAD: at W0 = %g Sv the cell's excess is %+.0f uatm of which the T-term (the mixed layer's DIC exposed at %.1f C instead of %g/%g C) is %+.0f/%+.0f; the cold-tongue proxy is worth %.1f uatm per degC; k_eq = 1 is worth %+.0f; both %+.0f; the cell at the ML's own SST reads %+.0f.\n",
            W0, RES$w0$b1$value, p$sst_eq, p$sst_NH, p$sst_SH, RES$w0$decomp["NH", "T_term"], RES$w0$decomp["SH", "T_term"],
            (RES$w0$b1$value - RES$cold4$b1$value) / LV_COLD[2], RES$k1$b1$value - RES$w0$b1$value, RES$k1cold2$b1$value - RES$w0$b1$value, RES$mlT$b1$value))
saveRDS(list(res = RES, start = LV_START, dir = LV_DIR, W0 = W0, target = tg, obs_slope = OBS_SLOPE, sst_ml = c(NH = p$sst_NH, SH = p$sst_SH),
             commit = tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) NA), date = Sys.time()), paste0(LV_OUT, ".rds"))
cat("saved", paste0(LV_OUT, ".{log,rds}"), "\n")
