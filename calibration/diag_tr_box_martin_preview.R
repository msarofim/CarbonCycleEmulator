# =====================================================================
# diag_tr_box_martin_preview.R -- 2026-09-14 (g). THE PREVIEW the review recommended
# before committing to a tropical column (T5) or to option D+E: is the pump
# field the ROOT of the cell's B1 excess? The 09-14 (f) probe measured that
# the cell's source layer is diffusively slaved to the cold mixed layer (3.1
# /yr vs the loop's 0.045 /yr) and that the pump's divergence field is 45.5
# GtC/yr at the canonical. If that field is what the cell exposes, shrinking
# it (T-D0's Martin shapes at the model's OWN K(z), lib_martin_shape.R: the
# tail arm ~16 GtC/yr, the full arm ~1.4) must move B1 toward +55.5 WITHOUT
# any tropical box; if B1 stays > +90 the root is elsewhere (the kz itself).
# Same vector and arms as diag_tr_box_probe.R (start_011, w_eq 27, gamma
# 0.60, unrefitted, periodic spinup); nothing in R/ is touched; nothing adopted.
# ⚠ The Martin arms are UNREFITTED (their unrefitted price is T-D0b's -17 /
# -47); B1 is read as a STRUCTURAL number, the likelihood only as context.
# Usage: Rscript calibration/diag_tr_box_martin_preview.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R")); source(ccx_path("calibration", "lib_martin_shape.R"))
`%||%` <- function(a, b) if (is.null(a)) b else a
MP_DIR   <- "calibration/output/multistart_20260913_eqcell_hilda_eq_seasml1_pin_ent_seas_amp_SH=0_sd1.0452"
MP_START <- "start_011.rds"
MP_ARMS  <- c("glodap", "martin_tail", "martin_full")
MP_STRUCT <- c("hilda_eq", "hilda_tr")
MP_OUT   <- ccx_path("outputs", "diagnostics", sprintf("tr_box_martin_preview_%s", format(Sys.Date(), "%Y%m%d")))
sink_log <- file(paste0(MP_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)

b <- readRDS(file.path(MP_DIR, MP_START)); obs_eq <- ccx_eq_cell_obs(); obs_tr <- ccx_tr_box_obs()
W0 <- obs_eq$w0_prior$mean_sv; GM <- b$par_mode$gamma_eq; pins <- c(ent_seas_amp_SH = 0)
make_vec <- function(struct) {
  base <- ccx_apply_structure(ccx_default_params(), struct, seas_ml = 1); base$pump_mode <- b$pump_mode
  for (n in names(pins)) base[[n]] <- pins[[n]]
  pm <- b$par_mode; p <- base
  for (n in intersect(names(p), names(pm))) p[[n]] <- pm[[n]]
  p <- ccx_set_enso(p, pm); p$w_eq <- W0; p$gamma_eq <- GM
  list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total, sigma_d14c = pm$sigma_d14c,
       rep_dC = pm$rep_dC, grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c,
       spinup = ccx_periodic_spinup, spinup_label = "periodic", md = NULL, migrated = character(0),
       pins = pins, src = file.path(MP_DIR, MP_START))
}
tg <- ccx_eq_b1_target()
en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))); en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
obs <- ccx_prepare_obs(); g <- obs$gcb; mg <- merge(g[, c("year", "ocean_sink")], en_ann, by = "year")
mg <- mg[stats::complete.cases(mg) & mg$year >= 1959 & mg$year <= 2024, ]
OBS_SLOPE <- coef(stats::lm(ocean_sink ~ year + nino34_anom, data = mg))[["nino34_anom"]]
enso_stat <- function(r) { s <- dg_annual_sinks(r); d <- merge(data.frame(year = s$year, oc = s$ocean), en_ann, by = "year")
  d <- d[d$year >= 1959 & d$year <= 2024, ]; f <- stats::lm(oc ~ year + nino34_anom, d)
  c(slope = coef(f)[["nino34_anom"]], r = stats::cor(residuals(stats::lm(oc ~ year, d)), d$nino34_anom)) }
pi_surface <- function(o, aux) {
  rows <- o$t < 1760; A <- c(); P <- c()
  for (bx in CCX_SURFACE_BOXES) for (h in HEMIS) {
    col <- o[[paste0(bx, "_pco2_", h)]]; if (is.null(col) || anyNA(col[rows])) next
    A[paste(bx, h)] <- switch(bx, ml = aux$a_ml[[h]], hs = aux$a_hs[[h]], eq = aux$a_eq[[h]], tr = aux$a_tr[[h]]); P[paste(bx, h)] <- mean(col[rows]) }
  glob <- sum(A * P) / sum(A)
  c(global = glob, ml = mean(P[grepl("^ml", names(P))]) - glob, eq = mean(P[grepl("^eq", names(P))]) - glob,
    tr = if (any(grepl("^tr", names(P)))) mean(P[grepl("^tr", names(P))]) - glob else NA_real_)
}
cat(sprintf("vector %s; w_eq %g, gamma_eq %.3f; target B1 %+.2f +/- %.2f\n\n", MP_START, W0, GM, tg$target, tg$sd))
cat(sprintf("%-10s %-9s | %7s %6s | %8s %8s %8s | %8s %8s %8s | %10s %7s | %8s %8s\n", "arm", "struct", "export", "K_deep", "B1", "z", "PI eq-g", "PI tr-g", "PI ml-g", "DIC oc2", "ENSO/obs", "r", "lik", "d eq_b1"))
RES <- list(); ref_lik <- NULL
for (arm in MP_ARMS) for (st in MP_STRUCT) {
  v <- make_vec(st); MS_ARM <<- arm; MS_P <<- v$p
  re <- dg_run(v); o <- re$out; aux <- re$sp$aux; grid <- re$sp$grid; y <- re$sp$y
  stv <- unlist(dg_streams(re, v)); e <- enso_stat(re)
  b1 <- ccx_model_eq_b1(o[o$t < DG_SINK_LAST + 1, ], aux); z <- (b1$value - tg$target) / tg$sd
  ps <- pi_surface(o, aux)
  E <- sum(unlist(lapply(HEMIS, function(h) aux$pump[[h]]$org + aux$pump[[h]]$carb)))
  dic2 <- mean(vapply(HEMIS, function(h) y[aux$idx[[h]]$oc[2], "C"] * aux$mol_per_GtC / (aux$a_ls[[h]] * grid$dz[3] * ccx_const("RHO_SEAWATER")) * 1e6, numeric(1)))
  if (is.null(ref_lik)) ref_lik <- stv
  cm <- intersect(names(stv), names(ref_lik))
  cat(sprintf("%-10s %-9s | %7.1f %6.0f | %+8.1f %+8.2f %+8.1f | %+8.1f %+8.1f %8.0f | %9.2fx %+7.3f | %+8.1f %+8.1f\n", arm, st, E, aux$kz_int[grid$nl],
              b1$value, z, ps[["eq"]], ps[["tr"]], ps[["ml"]], dic2, e[["slope"]] / OBS_SLOPE, e[["r"]], sum(stv[cm] - ref_lik[cm]),
              (stv["eq_b1"] %||% NA) - (ref_lik["eq_b1"] %||% NA)))
  RES[[paste(arm, st)]] <- list(arm = arm, struct = st, export = E, b1 = b1, z = z, pi = ps, dic_oc2 = dic2, enso = e, streams = stv)
}
MS_ARM <<- "glodap"
cat("\n=== READING ===\n")
g_eq <- RES[["glodap hilda_eq"]]; t_eq <- RES[["martin_tail hilda_eq"]]; f_eq <- RES[["martin_full hilda_eq"]]
cat(sprintf("hilda_eq B1 across the export field: %.1f GtC/yr -> %+.1f | %.1f -> %+.1f | %.1f -> %+.1f  (slope %+.2f uatm per GtC/yr of export)\n",
            g_eq$export, g_eq$b1$value, t_eq$export, t_eq$b1$value, f_eq$export, f_eq$b1$value, (g_eq$b1$value - f_eq$b1$value) / (g_eq$export - f_eq$export)))
g_tr <- RES[["glodap hilda_tr"]]; t_tr <- RES[["martin_tail hilda_tr"]]; f_tr <- RES[["martin_full hilda_tr"]]
cat(sprintf("hilda_tr B1: %+.1f | %+.1f | %+.1f; tr - global %+.1f | %+.1f | %+.1f (obs +7.6)\n", g_tr$b1$value, t_tr$b1$value, f_tr$b1$value, g_tr$pi[["tr"]], t_tr$pi[["tr"]], f_tr$pi[["tr"]]))
cat(sprintf("verdict: at the no-pump limit (martin_full) B1 is %+.1f on hilda_eq -- %s\n", f_eq$b1$value,
            if (f_eq$b1$value < 70) "the pump field IS the root; D+E before any tropical column" else "the root is NOT the export field alone: the diffusive exchange itself (kz) sets the cell's source"))
saveRDS(list(res = RES, vector = MP_START, w0 = W0, gamma = GM, commit = tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) NA), date = Sys.time()), paste0(MP_OUT, ".rds"))
cat("saved", paste0(MP_OUT, ".{log,rds}"), "\n")
