# =====================================================================
# THE TROPICAL SURFACE BOX, UNREFITTED PROBE (prereg notes/prereg_2026-09-14f_
# tr_box_build.md §4: PT1, PT6, R3's read, PT7, N-T1's measured form -- and
# the R6 lever, kz_tr_frac). Everything runs at the FIRST ARRAY'S BEST VECTOR
# (Torch 17769990, start_011: the 30 free names + gamma_eq 0.600) with w_eq
# put at Meinen's 27 Sv -- the point the second build exists to make
# admissible -- and the "hilda_tr" structure applied on top. NOTHING is
# refitted, so every price is an upper bound on what the array will pay.
#
#   REF   hilda_eq at that vector (the first build's +133 at 27 Sv, reproduced)
#   R3    hilda_tr with tr_frac = 0: the MASK CHANGE alone (sst_NH/SH 17.18/15.35,
#         sst_eq re-based) -- a price, reported, not gated
#   T1    hilda_tr as built (kz_tr_frac 1, sst_tr_enso the product's)
#   R6    kz_tr_frac 0.3 / 0.1 / 0 -- the tr / layer-1 interface's K
#   R5    sst_tr_enso 0 at the T1 point (PT7)
#   N-T1  q_tr = 1000 Sv (tr == ml) -- the measured negative control
# Read per arm: B1 (model, z on sigma 6.77; the halves), PI tr - global and
# eq - global (the product's CHECK +7.6 for tr), the ENSO ocean slope and r,
# the common-row likelihood against REF, the CO2 LEVEL rows, pump_grad's
# rows; PT6: tr's DIC at GLODAP's epoch against 1963 +/- 49.7 (cluster sd)
# and its d13C against the tropical surface band.
# Usage: Rscript calibration/diag_tr_box_probe.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
`%||%` <- function(a, b) if (is.null(a)) b else a
TB_DIR   <- "calibration/output/multistart_20260913_eqcell_hilda_eq_seasml1_pin_ent_seas_amp_SH=0_sd1.0452"
TB_START <- "start_011.rds"            # the first array's best (id 0 CONVERGED there)
TB_W0    <- NULL                       # NULL = Meinen's prior mean from the product (27 Sv)
TB_GAMMA <- NULL                       # NULL = the first array's fitted gamma_eq (0.600)
TB_KZ_TR <- c(1, 0.3, 0.1, 0)          # R6's lever; 1 = the ML idiom as ruled
TB_QTR_INF <- 1000                     # Sv, N-T1's "tr == ml"
TB_WIN   <- c(1959, 2024)              # the ENSO regression window (= SC_ENSO_WIN)
TB_PT1_Z <- 2                          # PT1: |z| <= this on B1
TB_PE6_LAT <- 5; TB_PE6_DEPTH <- 50; TB_PE6_FLAG <- 2
TB_GLODAP <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
TB_ROW_SHOW <- 0.5
TB_OUT   <- ccx_path("outputs", "diagnostics", sprintf("tr_box_probe_%s", format(Sys.Date(), "%Y%m%d")))
sink_log <- file(paste0(TB_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)

b <- readRDS(file.path(TB_DIR, TB_START))
stopifnot(identical(b$struct, "hilda_eq"), b$seas_ml == 1)
obs_eq <- ccx_eq_cell_obs(); obs_tr <- ccx_tr_box_obs()
W0 <- TB_W0 %||% obs_eq$w0_prior$mean_sv
GM <- TB_GAMMA %||% b$par_mode$gamma_eq
pins <- c(ent_seas_amp_SH = 0)
make_vec <- function(struct, mod = identity) {
  base <- ccx_apply_structure(ccx_default_params(), struct, seas_ml = 1); base$pump_mode <- b$pump_mode
  for (n in names(pins)) base[[n]] <- pins[[n]]
  pm <- b$par_mode; p <- base
  for (n in intersect(names(p), names(pm))) p[[n]] <- pm[[n]]
  p <- ccx_set_enso(p, pm)
  # the structure's SST overrides must WIN over the file's par_mode (which
  # carries none of sst_NH/SH/sst_eq: they are base parameters, not fitted)
  p$w_eq <- W0; p$gamma_eq <- GM
  p <- mod(p)
  list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total, sigma_d14c = pm$sigma_d14c,
       rep_dC = pm$rep_dC, grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c,
       spinup = ccx_periodic_spinup, spinup_label = "periodic", md = NULL, migrated = character(0),
       pins = pins, src = file.path(TB_DIR, TB_START))
}
cat(sprintf("vector: %s (logpost %.4f; fitted w_eq %.3f, gamma_eq %.4f); probe at w_eq %g Sv, gamma_eq %.3f\n",
            file.path(TB_DIR, TB_START), b$logpost, b$par_mode$w_eq, b$par_mode$gamma_eq, W0, GM))
tg <- ccx_eq_b1_target()
en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))); en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
obs <- ccx_prepare_obs(); g <- obs$gcb; mg <- merge(g[, c("year", "ocean_sink")], en_ann, by = "year")
mg <- mg[stats::complete.cases(mg) & mg$year >= TB_WIN[1] & mg$year <= TB_WIN[2], ]
fo <- stats::lm(ocean_sink ~ year + nino34_anom, data = mg); OBS_SLOPE <- coef(fo)[["nino34_anom"]]
OBS_R <- stats::cor(residuals(stats::lm(ocean_sink ~ year, mg)), mg$nino34_anom)
enso_stat <- function(r) { s <- dg_annual_sinks(r); d <- merge(data.frame(year = s$year, oc = s$ocean), en_ann, by = "year")
  d <- d[d$year >= TB_WIN[1] & d$year <= TB_WIN[2], ]; f <- stats::lm(oc ~ year + nino34_anom, d)
  c(slope = coef(f)[["nino34_anom"]], r = stats::cor(residuals(stats::lm(oc ~ year, d)), d$nino34_anom),
    sink = mean(s$ocean[s$year >= 2015 & s$year <= 2023])) }
cat(sprintf("target B1 %+.2f +/- %.2f uatm; tr band pCO2 - global (CHECK) %+.2f; obs ENSO ocean slope %+.4f per index (r %+.3f, %d-%d)\n\n",
            tg$target, tg$sd, obs_tr$pco2$both$minus_global, OBS_SLOPE, OBS_R, TB_WIN[1], TB_WIN[2]))

# GLODAP's tropical surface band, for PT6's d13C half (the PE6 idiom)
gl <- utils::read.csv(TB_GLODAP)
gl <- gl[gl$c13 > -9000 & gl$c13f == TB_PE6_FLAG & abs(gl$lat) <= TB_PE6_LAT & gl$depth <= TB_PE6_DEPTH, ]
BAND <- c(mean = mean(gl$c13), sd = stats::sd(gl$c13), n = nrow(gl), yr = mean(gl$year))
DIC_T <- obs_tr$dic_tr$both

# the PI surface picture: area-weighted global pCO2 over every surface box that
# exists, and each box's contrast to it (the deriv's own pCO2 columns)
pi_surface <- function(o, aux) {
  rows <- o$t < 1760
  A <- c(); P <- c()
  for (bx in CCX_SURFACE_BOXES) for (h in HEMIS) {
    col <- o[[paste0(bx, "_pco2_", h)]]; if (is.null(col) || anyNA(col[rows])) next
    a <- switch(bx, ml = aux$a_ml[[h]], hs = aux$a_hs[[h]], eq = aux$a_eq[[h]], tr = aux$a_tr[[h]])
    A[paste(bx, h)] <- a; P[paste(bx, h)] <- mean(col[rows])
  }
  glob <- sum(A * P) / sum(A)
  c(global = glob, ml = mean(P[grepl("^ml", names(P))]) - glob, eq = mean(P[grepl("^eq", names(P))]) - glob,
    tr = if (any(grepl("^tr", names(P)))) mean(P[grepl("^tr", names(P))]) - glob else NA_real_)
}
box_at <- function(o, aux, grid, which, yr) ccx_box_annual_conc(o, aux, grid, which, yr)

RES <- list(); st_ref <- NULL
run_arm <- function(label, struct, mod = identity, ref = FALSE) {
  t0 <- Sys.time(); v <- make_vec(struct, mod); re <- dg_run(v); o <- re$out; aux <- re$sp$aux; grid <- re$sp$grid
  st <- unlist(dg_streams(re, v)); e <- enso_stat(re)
  b1 <- ccx_model_eq_b1(o[o$t < DG_SINK_LAST + 1, ], aux); z <- (b1$value - tg$target) / tg$sd
  ps <- pi_surface(o, aux)
  d <- if (is.null(st_ref)) NULL else { cm <- intersect(names(st), names(st_ref)); st[cm] - st_ref[cm] }
  lev <- if (is.null(d)) NA else sum(d[grepl("co2_level|co2_icecore", names(d))])
  big <- if (is.null(d)) character(0) else { bb <- names(d)[order(-abs(d))]; bb[abs(d[bb]) > TB_ROW_SHOW] }
  pt6 <- if (aux$tr_on == 1L) {
    dc <- box_at(o, aux, grid, "tr", DIC_T$epoch); d13 <- box_at(o, aux, grid, "tr", round(BAND[["yr"]]))
    c(dic = dc[["dic"]], z_dic = (dc[["dic"]] - DIC_T$target) / DIC_T$sd_cluster,
      d13c = d13[["d13c"]], z_d13c = (d13[["d13c"]] - BAND[["mean"]]) / BAND[["sd"]])
  } else c(dic = NA, z_dic = NA, d13c = NA, z_d13c = NA)
  cat(sprintf("%-34s B1 %+6.1f (NH %+6.1f / SH %+6.1f) z %+5.2f | PI: global %5.1f, ml %+6.1f, eq %+6.1f, tr %+6.1f | ENSO slope %+.4f = %.2fx obs (r %+.3f), sink %.2f | lik vs REF %s [CO2-level %s; %s] | PT6 tr DIC %s (z %s), d13C %s (z %s) | %.0f s\n",
              label, b1$value, b1$by_hemi[["NH"]], b1$by_hemi[["SH"]], z, ps[["global"]], ps[["ml"]], ps[["eq"]], ps[["tr"]],
              e[["slope"]], e[["slope"]] / OBS_SLOPE, e[["r"]], e[["sink"]],
              if (is.null(d)) "(REF)" else sprintf("%+.2f", sum(d)), if (is.na(lev)) "-" else sprintf("%+.2f", lev),
              if (length(big)) paste(sprintf("%s %+.2f", big, d[big]), collapse = ", ") else "no row > 0.5",
              if (is.na(pt6[["dic"]])) "-" else sprintf("%.0f", pt6[["dic"]]), if (is.na(pt6[["z_dic"]])) "-" else sprintf("%+.2f", pt6[["z_dic"]]),
              if (is.na(pt6[["d13c"]])) "-" else sprintf("%.2f", pt6[["d13c"]]), if (is.na(pt6[["z_d13c"]])) "-" else sprintf("%+.2f", pt6[["z_d13c"]]),
              as.numeric(Sys.time() - t0, units = "secs")))
  if (ref) st_ref <<- st
  RES[[label]] <<- list(label = label, struct = struct, p_changes = mod, b1 = b1, z = z, pi = ps, enso = e, streams = st,
                        dlik = if (is.null(d)) NA else sum(d), rows = d, pt6 = pt6, pump_grad = v$p$pump_grad)
  invisible(re)
}

cat("=== the arms (all at w_eq", W0, "Sv, gamma_eq", GM, "; unrefitted) ===\n")
run_arm("REF hilda_eq (first build)", "hilda_eq", ref = TRUE)
run_arm("R3 mask change only (tr_frac 0)", "hilda_tr", function(p) { p$tr_frac_NH <- 0; p$tr_frac_SH <- 0; p })
run_arm("T1 hilda_tr as built (kz_tr 1)", "hilda_tr")
for (f in TB_KZ_TR[-1]) run_arm(sprintf("R6 kz_tr_frac %g", f), "hilda_tr", local({ ff <- f; function(p) { p$kz_tr_frac <- ff; p } }))
run_arm("R5 sst_tr_enso 0 (kz_tr 1)", "hilda_tr", function(p) { p$sst_tr_enso <- 0; p })
run_arm(sprintf("N-T1 q_tr %g Sv (tr == ml)", TB_QTR_INF), "hilda_tr", function(p) { p$q_tr <- TB_QTR_INF; p })

cat("\n=== VERDICTS (prereg 2026-09-14f §4, unrefitted) ===\n")
t1 <- RES[["T1 hilda_tr as built (kz_tr 1)"]]
PT1 <- abs(t1$z) <= TB_PT1_Z
cat(sprintf("PT1  B1 within %g sigma of %+.1f at w_eq %g, gamma_eq %.2f: model %+.1f, z %+.2f -> %s (REF first build %+.1f)\n",
            TB_PT1_Z, tg$target, W0, GM, t1$b1$value, t1$z, if (PT1) "PASS" else "FAIL", RES[[1]]$b1$value))
best <- RES[sapply(RES, function(x) identical(x$struct, "hilda_tr") && !grepl("tr_frac 0|N-T1", x$label))]
zz <- sapply(best, function(x) x$z)
cat(sprintf("     across the R6 lever the smallest |z| is %+.2f at '%s'\n", zz[which.min(abs(zz))], names(zz)[which.min(abs(zz))]))
PT6 <- abs(t1$pt6[["z_dic"]]) <= 2 && abs(t1$pt6[["z_d13c"]]) <= 2
cat(sprintf("PT6  tr DIC at %d: %.0f vs GLODAP %.0f +/- %.1f (z %+.2f); d13C at %d: %.2f vs band %.2f +/- %.2f (z %+.2f) -> %s\n",
            DIC_T$epoch, t1$pt6[["dic"]], DIC_T$target, DIC_T$sd_cluster, t1$pt6[["z_dic"]], round(BAND[["yr"]]),
            t1$pt6[["d13c"]], BAND[["mean"]], BAND[["sd"]], t1$pt6[["z_d13c"]], if (PT6) "PASS" else "FAIL"))
r3 <- RES[["R3 mask change only (tr_frac 0)"]]
cat(sprintf("R3   the mask change alone (re-based SSTs, no box): common rows %+.2f vs REF; B1 %+.1f (REF %+.1f)\n", r3$dlik, r3$b1$value, RES[[1]]$b1$value))
r5 <- RES[["R5 sst_tr_enso 0 (kz_tr 1)"]]
cat(sprintf("PT7  sst_tr_enso %.3f -> 0: ENSO slope %+.4f -> %+.4f (r %+.3f -> %+.3f); common rows %+.2f -> %+.2f\n",
            make_vec("hilda_tr")$p$sst_tr_enso, t1$enso[["slope"]], r5$enso[["slope"]], t1$enso[["r"]], r5$enso[["r"]], t1$dlik, r5$dlik))
nt <- RES[[grep("^N-T1", names(RES))]]
cat(sprintf("N-T1 tr == ml (q_tr %g Sv): B1 %+.1f vs the first build's %+.1f (%.0f %% of it)\n", TB_QTR_INF, nt$b1$value, RES[[1]]$b1$value, 100 * nt$b1$value / RES[[1]]$b1$value))
cat(sprintf("tr - global at PI (CHECK, obs %+.1f): %s\n", obs_tr$pco2$both$minus_global,
            paste(sprintf("%s %+.1f", names(best), sapply(best, function(x) x$pi[["tr"]])), collapse = "; ")))
saveRDS(list(vector = file.path(TB_DIR, TB_START), w0 = W0, gamma = GM, target = tg, obs_slope = OBS_SLOPE, band = BAND, dic_target = DIC_T,
             arms = lapply(RES, function(x) x[setdiff(names(x), "p_changes")]), verdicts = list(PT1 = PT1, PT6 = PT6),
             commit = tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) NA), date = Sys.time()),
        paste0(TB_OUT, ".rds"))
cat("\nsaved", paste0(TB_OUT, ".{log,rds}"), "\n")
