# =====================================================================
# diag_o5_seasonal_export_scan.R -- THE O5 PROBE of
# notes/prereg_2026-09-15f_o5_seasonal_export.md §3-4: a SEASONAL EXPORT
# (pump_seas_amp x pump_seas_lag, the summer-peaked zero-mean factor on every
# pump limb) under the PRESCRIBED field (martin, Nowicki 9.08), unrefitted at
# the canonical (hilda30c), on the C++ objective under the file's pins.
#   Gate 0   the canonical's and the martin-9.08 point's SPO first harmonic vs
#            obs (amplitude in ppm, phase in months); the harness gate: martin
#            amp 0 reproduces A2's -895.
#   Stage 1  RAW grid: amp x lag under martin 9.08 (15 points) + the CONTROL
#            (solved field, the canonical) at amp {0.5, 1}; per point the 25
#            rows vs the canonical, the SPO / MLO seasonal rows, the CO2-level,
#            bomb and profile rows, the SPO harmonic, the PI layer 2/6 - ML,
#            the 1995 bomb excess, the annual-mean export (P0b in situ).
#   Stage 2  ARM C at the best grid point AND at martin amp 0 (its baseline),
#            re-optimised over the PK-2 names.
#   The decision rule (prereg §4) is evaluated and printed; nothing adopted.
# Usage: Rscript calibration/diag_o5_seasonal_export_scan.R      (O5_SMOKE=1 for a smoke)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

O5_ARM     <- CCX_MODE_CANONICAL
O5_EXPORT  <- ccx_pump_export_prior()$centre_gtc          # 9.08, Nowicki's LS median -- READ, not typed
O5_AMP     <- c(0, 0.25, 0.5, 0.75, 1)
O5_LAG     <- c(-2, 0, 2)                                  # months from the SST convention's mid-summer peak
O5_CTRL_AMP <- c(0.5, 1)                                   # the solved field (canonical) with the factor on
O5_LAND    <- c("beta_max", "fert_k", "q10")
O5_SURF    <- c("kz_deep_frac", "h_ml", "k_w", "bomb_total", "sigma_d14c")
O5_ARMC    <- c(O5_LAND, O5_SURF)
O5_NM_MAXIT <- 1500; O5_BFGS_MAXIT <- 100
O5_GATE_TOL <- 1e-4
O5_D_ALONE  <- -894.8                                      # A2 / the E probe: martin 9.08, no limb, no seasonality (o1_deep_return_scan_20260915.log)
O5_RULE_A   <- 0.5                                         # (a) SPO recovers >= this share of its martin-9.08 cost
O5_RULE_B   <- 100                                         # (b) the martin total improves by >= this over amp 0
O5_SMOKE   <- nzchar(Sys.getenv("O5_SMOKE", ""))
if (O5_SMOKE) { O5_AMP <- c(0, 1); O5_LAG <- 0; O5_CTRL_AMP <- 1; O5_NM_MAXIT <- 20; O5_BFGS_MAXIT <- 5 }
O5_OUT     <- ccx_path("outputs", "diagnostics", sprintf("o5_seasonal_export_scan_%s%s", format(Sys.Date(), "%Y%m%d"), if (O5_SMOKE) "_smoke" else ""))
sink_log <- file(paste0(O5_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)
cat(sprintf("== O5 seasonal-export probe at %s (prereg 2026-09-15f) -- commit %s ==\n", O5_ARM,
            tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")))
cat(sprintf("export %.2f GtC/yr (martin); amp %s x lag %s mo; control (solved) amp %s; arm C = %s\n\n", O5_EXPORT,
            paste(O5_AMP, collapse = "/"), paste(O5_LAG, collapse = "/"), paste(O5_CTRL_AMP, collapse = "/"), paste(O5_ARMC, collapse = ",")))

# ---- observations (READ) -------------------------------------------------
obs <- ccx_prepare_obs()
exc_obs <- obs$excess_c14
harm <- function(h) c(amp = sqrt(h$a_mean^2 + h$b_mean^2), phase_mo = (atan2(h$b_mean, h$a_mean) / (2 * pi)) * 12)
o_spo <- obs$co2_seas$SPO; o_mlo <- obs$co2_seas$MLO
cat(sprintf("obs SPO first harmonic: amp %.3f ppm, phase %.2f mo (a %.3f +- %.3f, b %.3f +- %.3f, %d yr); MLO amp %.3f ppm\n",
            harm(o_spo)[1], harm(o_spo)[2], o_spo$a_mean, o_spo$sd_a, o_spo$b_mean, o_spo$sd_b, o_spo$n_years, harm(o_mlo)[1]))

# ---- machinery: the dg path ------------------------------------------------
v0 <- dg_vector(O5_ARM); md <- v0$md
r_ref <- dg_run(v0); ref <- unlist(dg_streams(r_ref, v0))
cat(sprintf("HARNESS GATE 1: dg streams at the canonical vs stored: sum %.4f vs %.4f -> %s\n", sum(ref[names(md$streams)]), sum(md$streams),
            if (abs(sum(ref[names(md$streams)]) - sum(md$streams)) < O5_GATE_TOL) "PASS" else "FAIL"))
if (abs(sum(ref[names(md$streams)]) - sum(md$streams)) >= O5_GATE_TOL) stop("harness gate 1 failed")
conc_layer <- function(y, aux, grid, h, k) {
  m <- if (k == 0) aux$a_ml[[h]] * grid$dz[1] else aux$a_ls[[h]] * grid$dz[k + 1]
  i <- if (k == 0) aux$idx[[h]]$ml else aux$idx[[h]]$oc[k]
  y[i, "C"] * aux$mol_per_GtC / (m * ccx_const("RHO_SEAWATER")) * 1e6 }
point_p <- function(field, amp, lag) {
  v <- v0; p <- v$p
  if (field == "martin") { p$pump_field <- "martin"; p$pump_export <- O5_EXPORT
    p$gamma_enso_ocn_NH <- 0; p$gamma_enso_ocn_SH <- 0; p$gamma_vent <- 0; p$w_vent <- 0; p$w_thc <- 0 }
  p$pump_seas_amp <- amp; p$pump_seas_lag <- lag
  v$p <- p; v
}
read_point <- function(v) {
  r <- dg_run(v); sp <- r$sp; aux <- sp$aux; grid <- sp$grid; y <- sp$y; out <- r$out; yr <- floor(out$t + 1e-9)
  stv <- unlist(dg_streams(r, v)); cm <- intersect(names(stv), names(ref)); d <- stv[cm] - ref[cm]
  exc <- vapply(exc_obs$year, function(Y) ccx_c14_kmol(mean(out$ocean_C14[yr == Y]) - out$ocean_C14[1]), numeric(1))
  z_exc <- (exc - exc_obs$centre) / exc_obs$half_width
  ms <- ccx_model_stats(out[out$t < DG_SINK_LAST + 1, ], obs)
  hs <- harm(ms$co2_seas$SPO); hm <- harm(ms$co2_seas$MLO)
  pr <- rowMeans(sapply(HEMIS, function(h) c(conc_layer(y, aux, grid, h, 2), conc_layer(y, aux, grid, h, 6)) - conc_layer(y, aux, grid, h, 0)))
  rows <- function(pat) sum(d[grep(pat, cm)])
  spin_resid <- if (!is.null(sp$periodic)) sp$periodic$resid_carbon else NA_real_
  list(d = d, dlik = sum(d), exc95 = exc[2], z_exc95 = z_exc[2], spo = d[["co2_seasonal_SPO"]], mlo = d[["co2_seasonal_MLO"]],
       spo_amp = hs[["amp"]], spo_phase = hs[["phase_mo"]], mlo_amp = hm[["amp"]], L2 = pr[1], L6 = pr[2], spin_resid = spin_resid,
       bomb = rows("^d14c_(NH|SH)$"), co2 = rows("^co2_level"), d14prof = rows("^d14c_profile"), d13 = rows("^d13c"), sink = dg_gate7(r)$ocean)
}
fmt <- function(lab, rp) sprintf("%-24s | dlik %+8.1f | SPO %+7.1f MLO %+6.1f | SPO harm %.3f ppm @ %+5.2f mo (MLO %.3f) | co2lev %+7.1f bomb %+6.1f d14prof %+5.1f d13 %+5.1f | L2/L6-ML %+4.0f/%+4.0f | exc95 %5.1f (z %+4.1f) | sink %.2f%s",
                                lab, rp$dlik, rp$spo, rp$mlo, rp$spo_amp, rp$spo_phase, rp$mlo_amp, rp$co2, rp$bomb, rp$d14prof, rp$d13, rp$L2, rp$L6, rp$exc95, rp$z_exc95, rp$sink,
                                if (is.finite(rp$spin_resid) && rp$spin_resid >= PS_TOL) sprintf(" | SPINUP NOT CONVERGED %.1e", rp$spin_resid) else "")

# ---- gate 0 ---------------------------------------------------------------
g_can <- read_point(point_p("solved", 0, 0)); cat(fmt("canonical (solved)", g_can), "\n")
g_m0  <- read_point(point_p("martin", 0, 0));  cat(fmt("martin 9.08, amp 0", g_m0), "\n")
cat(sprintf("HARNESS GATE 2: martin amp 0 dlik %+.1f vs A2's %+.1f -> %s\n", g_m0$dlik, O5_D_ALONE, if (abs(g_m0$dlik - O5_D_ALONE) < 0.5) "PASS" else "FAIL (the code path moved)"))
cat(sprintf("GATE 0: SPO amplitude obs %.3f / canonical %.3f / martin-9.08 %.3f ppm; phase obs %+.2f / canonical %+.2f / martin %+.2f mo; the martin deficit is %.3f ppm (%.0f %% of obs)\n\n",
            harm(o_spo)[1], g_can$spo_amp, g_m0$spo_amp, harm(o_spo)[2], g_can$spo_phase, g_m0$spo_phase, g_can$spo_amp - g_m0$spo_amp, 100 * (g_can$spo_amp - g_m0$spo_amp) / harm(o_spo)[1]))

# ---- stage 1: the grid + control -----------------------------------------
grid1 <- rbind(expand.grid(field = "martin", amp = O5_AMP, lag = O5_LAG, stringsAsFactors = FALSE),
               expand.grid(field = "solved", amp = O5_CTRL_AMP, lag = 0, stringsAsFactors = FALSE))
cat(sprintf("== STAGE 1: %d points ==\n", nrow(grid1))); t_all <- proc.time()[["elapsed"]]
S1 <- vector("list", nrow(grid1))
for (i in seq_len(nrow(grid1))) {
  g1 <- grid1[i, ]; lab <- sprintf("%s amp %.2f lag %+d", g1$field, g1$amp, as.integer(g1$lag))
  rp <- tryCatch(read_point(point_p(g1$field, g1$amp, g1$lag)), error = function(e) { cat(sprintf("%-24s | FAILED: %s\n", lab, conditionMessage(e))); NULL })
  if (!is.null(rp)) { cat(fmt(lab, rp), "\n"); S1[[i]] <- rp }
}
cat(sprintf("stage 1 done in %.0f s\n\n", proc.time()[["elapsed"]] - t_all))
tab1 <- cbind(grid1, do.call(rbind, lapply(S1, function(r) if (is.null(r)) data.frame(dlik = NA, spo = NA, mlo = NA, spo_amp = NA, spo_phase = NA, co2 = NA, L2 = NA, z_exc95 = NA)
  else data.frame(dlik = r$dlik, spo = r$spo, mlo = r$mlo, spo_amp = r$spo_amp, spo_phase = r$spo_phase, co2 = r$co2, L2 = r$L2, z_exc95 = r$z_exc95))))
mt <- tab1[tab1$field == "martin", ]
cat("== the SPO row across the grid (martin), dlik vs the canonical; the amp-0 row is A2 ==\n"); print(mt[, c("amp", "lag", "dlik", "spo", "mlo", "spo_amp", "spo_phase", "co2", "L2")], digits = 4, row.names = FALSE)
best <- mt[which.max(mt$dlik), ]; best_spo <- mt[which.max(mt$spo), ]
cat(sprintf("\nbest total: amp %.2f lag %+d (dlik %+.1f, SPO %+.1f); best SPO row: amp %.2f lag %+d (SPO %+.1f, dlik %+.1f)\n\n",
            best$amp, as.integer(best$lag), best$dlik, best$spo, best_spo$amp, as.integer(best_spo$lag), best_spo$spo, best_spo$dlik))

# ---- stage 2: arm C at the best grid point and at martin amp 0 -------------
cat("== STAGE 2: arm C re-optimisation (best total point; martin amp 0 as its baseline) ==\n")
rm_pins <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm_pins), add = TRUE)
bp0 <- ccx_mode_base(md); bp0$pump_mode <- md$pump_mode
st <- ccx_mode_start(md, "o5_scan"); pm0 <- st$p
lp_solved <- ccx_make_logpost(base_params = bp0, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
v_s <- lp_solved(st$u); ref_st <- attr(v_s, "streams")
cat(sprintf("HARNESS GATE 4: rebuilt logpost %.4f (shift %+.4f) vs stored %.4f -> %s\n", as.numeric(v_s) - st$logpost_shift, st$logpost_shift, md$logpost,
            if (abs(as.numeric(v_s) - st$logpost_shift - md$logpost) < O5_GATE_TOL) "PASS" else "FAIL"))
if (abs(as.numeric(v_s) - st$logpost_shift - md$logpost) >= O5_GATE_TOL) stop("harness gate 4 failed")
ccx_unpin_params(rm_pins); rm_pins <- list()
reopt_point <- function(amp, lag) {
  pins <- c(ccx_mode_pins(md), c(w_thc = 0, w_vent = 0, gamma_vent = 0, gamma_enso_ocn_NH = 0, gamma_enso_ocn_SH = 0))
  rm <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rm), add = TRUE)
  bp <- bp0; for (n in names(pins)) bp[[n]] <- pins[[n]]
  bp$pump_field <- "martin"; bp$pump_seas_amp <- amp; bp$pump_seas_lag <- lag
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
  pm <- pm0[setdiff(names(pm0), names(pins))]; pm$pump_export <- O5_EXPORT
  u <- ccx_par_to_unc(pm); stopifnot(all(is.finite(u)))
  idx <- match(O5_ARMC, CCX_PARAM_NAMES); stopifnot(!any(is.na(idx)))
  fobj <- function(z) { uu <- u; uu[idx] <- z; x <- -as.numeric(lp(uu)); if (!is.finite(x)) 1e10 else x }
  v_raw <- lp(u)
  o1 <- stats::optim(u[idx], fobj, method = "Nelder-Mead", control = list(maxit = O5_NM_MAXIT, reltol = 1e-10))
  o2 <- stats::optim(o1$par, fobj, method = "BFGS", control = list(maxit = O5_BFGS_MAXIT, reltol = 1e-12))
  bst <- if (o2$value < o1$value) o2 else o1; uu <- u; uu[idx] <- bst$par
  v <- lp(uu); pmb <- ccx_unc_to_par(uu)
  st_raw <- attr(v_raw, "streams"); st_c <- attr(v, "streams"); cm <- intersect(names(st_c), names(ref_st))
  list(amp = amp, lag = lag, pm = pmb, dlik_raw = sum(st_raw[cm] - ref_st[cm]), dlik = sum(st_c[cm] - ref_st[cm]), d = st_c[cm] - ref_st[cm],
       spo_raw = st_raw[["co2_seasonal_SPO"]] - ref_st[["co2_seasonal_SPO"]], spo = st_c[["co2_seasonal_SPO"]] - ref_st[["co2_seasonal_SPO"]],
       n_eval = o1$counts[1] + o2$counts[1],
       read = { vv <- point_p("martin", amp, lag); for (n in names(pmb)) if (n %in% names(vv$p)) vv$p[[n]] <- pmb[[n]]
                for (n in c("luc_scale", "bomb_total", "sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c")) if (!is.null(pmb[[n]])) vv[[n]] <- pmb[[n]]
                read_point(vv) })
}
S2 <- list()
for (pt in list(c(0, 0), c(best$amp, best$lag))) {
  t0 <- proc.time()[["elapsed"]]
  r2 <- tryCatch(reopt_point(pt[1], pt[2]), error = function(e) { cat(sprintf("armC amp %.2f lag %+d FAILED: %s\n", pt[1], as.integer(pt[2]), conditionMessage(e))); NULL })
  if (is.null(r2)) next
  S2[[length(S2) + 1]] <- r2
  cat(sprintf("armC amp %.2f lag %+d: raw %+8.1f -> armC %+8.1f (SPO %+.1f -> %+.1f; %d evals; kz_deep_frac %.4f h_ml %.1f k_w %.0f bomb_total %.1f sigma_d14c %.2f) | %s  [%.0f s]\n",
              pt[1], as.integer(pt[2]), r2$dlik_raw, r2$dlik, r2$spo_raw, r2$spo, r2$n_eval, r2$pm$kz_deep_frac, r2$pm$h_ml, r2$pm$k_w, r2$pm$bomb_total, r2$pm$sigma_d14c,
              sub("^.*? \\| ", "", fmt("", r2$read)), proc.time()[["elapsed"]] - t0))
  cat(sprintf("        largest rows: %s\n", paste(sprintf("%s %+.1f", names(sort(r2$d))[1:5], sort(r2$d)[1:5]), collapse = ", ")))
}

# ---- THE DECISION RULE (prereg §4) ---------------------------------------
cat(sprintf("\n== THE DECISION RULE: (a) SPO recovers >= %.0f %% of its martin-9.08 cost (%+.1f -> >= %+.1f); (b) martin total improves >= %.0f over amp 0 (%+.1f); (c) after arm C the SPO gain over the amp-0 arm-C point survives ==\n",
            100 * O5_RULE_A, g_m0$spo, g_m0$spo * (1 - O5_RULE_A), O5_RULE_B, g_m0$dlik))
a <- best_spo$spo >= g_m0$spo * (1 - O5_RULE_A)
b <- best$dlik - g_m0$dlik >= O5_RULE_B
armc0 <- Filter(function(r) r$amp == 0, S2); armcb <- Filter(function(r) r$amp != 0, S2)
cc <- if (length(armc0) && length(armcb)) (armcb[[1]]$spo - armc0[[1]]$spo) >= 0.5 * (best$spo - g_m0$spo) && armcb[[1]]$dlik > armc0[[1]]$dlik else NA
cat(sprintf("(a) best SPO %+.1f vs %+.1f -> %s;  (b) best total %+.1f vs amp-0 %+.1f, gain %+.1f -> %s;  (c) arm C: amp-0 SPO %s / best-point SPO %s, totals %s / %s -> %s\n",
            best_spo$spo, g_m0$spo * (1 - O5_RULE_A), if (a) "PASS" else "FAIL", best$dlik, g_m0$dlik, best$dlik - g_m0$dlik, if (b) "PASS" else "FAIL",
            if (length(armc0)) sprintf("%+.1f", armc0[[1]]$spo) else "NA", if (length(armcb)) sprintf("%+.1f", armcb[[1]]$spo) else "NA",
            if (length(armc0)) sprintf("%+.1f", armc0[[1]]$dlik) else "NA", if (length(armcb)) sprintf("%+.1f", armcb[[1]]$dlik) else "NA",
            if (isTRUE(cc)) "PASS" else if (isFALSE(cc)) "FAIL" else "NA"))
cat(sprintf("layer-2 inversion (READ, predicted to persist): martin amp 0 %+.0f; best point %+.0f; canonical %+.0f\n", g_m0$L2, best$L2, g_can$L2))
cat(sprintf("\nVERDICT: %s\n", if (a && b && isTRUE(cc)) "O5 PASSES its preregistered rule (a)-(c)" else "O5 does NOT pass (a)-(c): REFUTED AS BUILT under this probe -- reported, not patched."))
saveRDS(list(grid = grid1, S1 = S1, tab1 = tab1, S2 = S2, g_can = g_can, g_m0 = g_m0, best = best, best_spo = best_spo, rule = c(a = a, b = b, c = cc),
             ref = ref, ref_st = ref_st, export = O5_EXPORT, obs_spo = o_spo, armc = O5_ARMC, canonical = O5_ARM, md_logpost = md$logpost,
             commit = tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) NA), built = format(Sys.time())), paste0(O5_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n", O5_OUT))
