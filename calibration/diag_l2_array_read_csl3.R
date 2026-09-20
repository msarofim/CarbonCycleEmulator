# =====================================================================
# diag_l2_array_read_csl3.R -- THE NINO3.4 RETURN LIMB ON THE SHIPPED STRUCTURE: the array
# read against prereg notes/prereg_2026-09-17k_l2_enso_limb_refit.md s4 PA1-PA6 (+ s8), for
# the Mac wave of 2026-09-20 07:01 -> 17:01 (label hilda_csl3 = hilda_cs + the layer-3 limb;
# the canonical's 8 pins less w_enso_l2 + the shim gamma_enso_ocn_NH/SH pinned 0; w_enso_l2
# fitted; 29 free; objective #13). 24 starts, 22 CONVERGED + 2 out of wall; collector: ONE
# h_ml ridge in three sub-modes (radius 0.24): 57.3 (the incumbent's, x9), 49.7 (x9 + a
# TIME start at the same value), 69.5-73.8 (x2, -1.5 / -2.4). Derived from
# diag_l2_array_read.R (09-18 b); the arms and thresholds are THIS wave's.
# Arms, each scored like-for-like under its own structure + the periodic spinup:
#   canonical  hilda30s (hilda_cs, seas_ml 1, the shim pair FREE at 0.44/0.04 -- the
#              reference the array's incumbent was built from, the pair then zeroed)
#   a1         the best start (id 3, -1425.3620; the incumbent's own convergence; 9 starts)
#   a2         the h_ml-49.7 sub-mode (id 0 = the cold start, -0.017; 9 starts)
#   a3         the deep sub-mode (id 2 = the hilda31pe reference's convergence, -1.49; h_ml 69.5)
# PA1 = the VERDICT in the physical unit: the fitted w_enso_l2 [Sv per index] with its
# Laplace sd (full per-direction Hessian at a1), the ENSO ocean slope vs GCB, r, and the
# likelihood on the 26 rows (#13). ⚠ Against a shim that ALREADY fits the slope (0.94x at
# hilda30s), so the limb's case is physicality (PA1) + GATE V (PA2), not fit.
# READ, not gated -- nothing is adopted; promotion is a ruling in every branch.
# Usage: Rscript calibration/diag_l2_array_read_csl3.R   (~10 min, C++ core; the Hessian is most of it)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
HR_DIR  <- list.files(ccx_path("calibration", "output"), "^multistart_20260920_hilda_csl3_seasml1", full.names = TRUE)[1]
HR_JOB  <- "Mac wave 2026-09-20 07:01 -> 17:01 (frozen tree ~/ccx_frozen/20260920p_limb_on_hilda_cs = the bundle at a15652e; objective #13; the limb on hilda_cs)"
HR_A1 <- 3L; HR_A2 <- 0L; HR_A3 <- 2L
HR_OUT  <- ccx_path("outputs", "diagnostics", sprintf("l2_array_read_csl3_%s", format(Sys.Date(), "%Y%m%d")))
HR_REPRO_TOL <- 1e-3
L2_BRACKET <- ccx_eq_cell_obs()$w0_prior$interannual$per_index_sv     # c(14, 25), Meinen 2001 through the product
L2_PARTIAL_HI <- 40                                                     # prereg s4 PA1: PARTIAL up to 40, REFUTED above
L2_SLOPE_BAND <- c(0.066, 0.165)                                        # prereg s4 PA1: GCB's slope +/- 2 se
L2_R_MIN <- 0.25
L2_LIK_MIN <- -1391.28                                                  # hilda30s's -1390.28 on the 26 #13 rows, less one log-unit per name fewer (AIC-style)
L2_V_MIN <- 0.603                                                       # PA2 (soft)
L2_PA3_ROWS <- c("co2_level_MLO", "co2_level_SPO", "co2_icecore"); L2_PA3_TOL <- 2; L2_PA3_D13C <- c("d13c_level_MLO", "d13c_level_SPO"); L2_PA3_D13C_TOL <- 3
L2_PA4_NAMES <- c("kz", "pump_grad", "kz_deep_frac"); L2_PA4_ROWS <- c("d14c_profile_level", "d14c_profile_ab", "d14c_profile_bd", "ocean_grad_dic")
L2_PA5_NAMES <- c("gamma_enso_land_NH", "gamma_enso_land_SH")
L2_PA6_MIN <- 30; L2_PA6_REF <- 17.7133                                 # test-enso-demean's price at hilda30s (09-20 o)
L2_WIN <- c(1959, 2024)
HR_GROUPS <- list(co2_level = "^co2_level_|^co2_icecore", co2_seasonal = "^co2_seasonal_", d13c_level = "^d13c_level_", d13c_seasonal = "^d13c_seasonal_",
                  gradients = "gradient", bomb_d14c = "^d14c_(NH|SH)$", d14c_profile = "^d14c_profile_", excess_c14 = "excess", gcb_sinks = "^gcb_", ocean_deep = "^ocean_grad_", hs = "^hs_")
HR_NAMES <- c("w_enso_l2", "gamma_enso_ocn_NH", "gamma_enso_ocn_SH", "gamma_enso_land_NH", "gamma_enso_land_SH", "h_ml", "kz", "kz_deep_frac", "pump_grad", "pump_hs_gcm2",
              "h_hs", "u_hs", "beta_max", "fert_k", "q10", "sst_seas_amp_NH", "sst_seas_amp_SH", "k_w", "tau_ex", "rep_dC", "bomb_total", "sigma_d14c", "luc_scale")
sink_log <- file(paste0(HR_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)
cat(sprintf("L2 ARRAY READ (the limb on hilda_cs)  %s\n  %s\n  dir %s\n", format(Sys.time()), HR_JOB, HR_DIR))

start_file <- function(id) readRDS(file.path(HR_DIR, sprintf("start_%03d.rds", id)))
start_vector <- function(id) {
  s <- start_file(id); pins <- s$pins
  .todo <- pins[names(pins) %in% CCX_PARAM_NAMES]; if (length(.todo)) invisible(ccx_apply_pins(.todo))
  p <- ccx_default_params(); p$pump_mode <- s$pump_mode
  p <- ccx_apply_structure(p, s$struct, s$seas_ml, pump_field = s$pump_field)
  for (n in names(pins)) p[[n]] <- pins[[n]]
  pm <- s$par_mode; for (n in names(pins)) pm[[n]] <- pins[[n]]
  p <- ccx_overlay_par(p, pm)                                          # the lint-enforced idiom (the 09-18 file predates it here)
  p <- ccx_set_enso(p, pm)
  list(p = p, pm = pm, luc_scale = pm$luc_scale, bomb_total = pm$bomb_total, sigma_d14c = pm$sigma_d14c,
       rep_dC = pm$rep_dC, grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c,
       spinup = CCX_OBJECTIVE_SPINUP, spinup_label = "periodic", pins = pins, prior_z = s$prior_z,
       src = sprintf("start_%03d (logpost %.4f, %s, %s)", id, s$logpost, if (isTRUE(s$converged)) "CONVERGED" else "NOT converged", s$kind), s = s)
}
obs <- ccx_prepare_obs()
canon <- dg_vector(CCX_MODE_CANONICAL); canon$prior_z <- canon$md$prior_z
ARMS <- list(canonical = canon, a1 = start_vector(HR_A1), a2 = start_vector(HR_A2), a3 = start_vector(HR_A3))
an <- names(ARMS)
for (a in c("a1", "a2", "a3")) stopifnot(identical(attr(ARMS[[a]]$p, "struct"), "hilda_csl3"), ccx_l2_on(ARMS[[a]]$p), ARMS[[a]]$p$k_l2 == 3L)

cat("\n=== A. THE SUB-MODES IN u-SPACE ===\n")
s1 <- start_file(HR_A1); s2 <- start_file(HR_A2); s3 <- start_file(HR_A3)
du <- function(a, b) { d <- a$u_mode - b$u_mode; names(d) <- a$param_names; d }
for (x in list(list("a1 vs a2", s1, s2), list("a1 vs a3", s1, s3), list("a2 vs a3", s2, s3))) { d <- du(x[[2]], x[[3]])
  big <- sort(abs(d), decreasing = TRUE); big <- big[big > 0.15]
  cat(sprintf("  %s: RMS |du| %.4f; |du| > 0.15: %s\n", x[[1]], sqrt(mean(d^2)), if (length(big)) paste(sprintf("%s %+.2f", names(big), d[names(big)]), collapse = ", ") else "none")) }

cat("\n=== B. PARAMETERS (value, prior z) ===\n")
cat(sprintf("  %-20s %s\n", "name", paste(sprintf("%28s", an), collapse = " ")))
zfmt <- function(v, n) { z <- v$prior_z; if (is.null(z) || is.na(z[n])) "" else sprintf("z %+.2f", z[[n]]) }
for (n in HR_NAMES) {
  vals <- vapply(ARMS, function(v) { x <- v$pm[[n]]; if (is.null(x)) x <- v$p[[n]]; if (is.null(x)) NA_real_ else x }, numeric(1))
  cat(sprintf("  %-20s %s\n", n, paste(vapply(an, function(a) sprintf("%18.5g %9s", vals[[a]], zfmt(ARMS[[a]], n)), ""), collapse = " ")))
}
for (a in an) cat(sprintf("  %-10s struct '%s' seas_ml %s k_l2 %s pins %s\n", a, attr(ARMS[[a]]$p, "struct"), attr(ARMS[[a]]$p, "seas_ml"), ARMS[[a]]$p$k_l2, ccx_pin_label(ARMS[[a]]$pins)))
for (a in an) { z <- ARMS[[a]]$prior_z; if (is.null(z)) next; s <- names(z)[abs(z) > 2]; cat(sprintf("  strained priors (|z| > 2) %-10s %s\n", a, if (length(s)) paste(sprintf("%s %+.2f", s, z[s]), collapse = ", ") else "none")) }

cat("\n=== 0. THE CANONICAL REPRODUCES ITS STORED STREAMS; the starts' logposts reproduce ===\n")
R <- lapply(ARMS, dg_run); ST <- Map(dg_streams, R, ARMS, MoreArgs = list(obs = obs))
st0 <- ARMS$canonical$md$streams; cm0 <- intersect(names(st0), names(ST$canonical)); d0 <- sum(ST$canonical[cm0]) - sum(unlist(st0[cm0]))
cat(sprintf("  canonical stored %.4f recomputed %.4f diff %+.2e over %d rows -> %s\n", sum(unlist(st0[cm0])), sum(ST$canonical[cm0]), d0, length(cm0), if (abs(d0) <= HR_REPRO_TOL) "REPRODUCES" else "DOES NOT REPRODUCE -- read nothing below"))
stopifnot(abs(d0) <= HR_REPRO_TOL)
for (a in c("a1", "a2", "a3")) { s <- ARMS[[a]]$s
  cat(sprintf("  %-4s start file logpost %.4f (final_lp_check %s)\n", a, s$logpost, if (is.null(s$final_lp_check)) "n/a" else format(s$final_lp_check))) }

cat("\n=== 1. LIKELIHOOD BY STREAM GROUP (common rows) ===\n")
common <- Reduce(intersect, lapply(ST, names))
cat(sprintf("  %-14s %s %9s   rows\n", "group", paste(sprintf("%10s", an), collapse = ""), "a1-can"))
G <- lapply(HR_GROUPS, function(pat) { rows <- grep(pat, common, value = TRUE); c(vapply(ST, function(s) sum(s[rows]), numeric(1)), n = length(rows)) })
for (g in names(G)) { x <- G[[g]]; if (x[["n"]] == 0) next
  cat(sprintf("  %-14s %s %+9.2f   %s\n", g, paste(sprintf("%10.2f", x[an]), collapse = ""), x[["a1"]] - x[["canonical"]], paste(grep(HR_GROUPS[[g]], common, value = TRUE), collapse = " "))) }
tot <- vapply(ST, function(s) sum(s[common]), numeric(1))
cat(sprintf("  %-14s %s %+9.2f\n", "TOTAL common", paste(sprintf("%10.2f", tot), collapse = ""), tot[["a1"]] - tot[["canonical"]]))
cat("\n  every common row, a1 minus canonical (sorted):\n"); print(round(sort(ST$a1[common] - ST$canonical[common]), 2))

cat("\n=== 2. THE ENSO OCEAN SLOPE (the 09-04g estimator: annual ocean sink ~ year + Nino3.4, 1959-2024) and GATE V ===\n")
en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))); en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
g <- obs$gcb; mg <- merge(g[, c("year", "ocean_sink")], en_ann, by = "year"); mg <- mg[stats::complete.cases(mg) & mg$year >= L2_WIN[1] & mg$year <= L2_WIN[2], ]
fo <- stats::lm(ocean_sink ~ year + nino34_anom, data = mg); OBS_SLOPE <- coef(fo)[["nino34_anom"]]; OBS_SE <- summary(fo)$coefficients["nino34_anom", 2]
enso_slope <- function(r) { s <- dg_annual_sinks(r); d <- merge(data.frame(year = s$year, oc = s$ocean), en_ann, by = "year")
  d <- d[d$year >= L2_WIN[1] & d$year <= L2_WIN[2], ]; f <- stats::lm(oc ~ year + nino34_anom, data = d)
  c(slope = coef(f)[["nino34_anom"]], se = summary(f)$coefficients["nino34_anom", 2], r = stats::cor(residuals(stats::lm(oc ~ year, d)), d$nino34_anom)) }
cat(sprintf("  GCB observed: slope %+.4f +/- %.4f GtC/yr per index, r %+.3f (n %d); PA1 band [%.3f, %.3f]\n", OBS_SLOPE, OBS_SE, stats::cor(residuals(stats::lm(ocean_sink ~ year, mg)), mg$nino34_anom), nrow(mg), L2_SLOPE_BAND[1], L2_SLOPE_BAND[2]))
ov <- dg_gateV_obs(); ES <- list(); GV <- list()
for (a in an) { e <- enso_slope(R[[a]]); V <- dg_gateV(R[[a]]); ES[[a]] <- e; GV[[a]] <- V
  cat(sprintf("  %-10s w_enso_l2 %6.2f  slope %+.4f +/- %.4f (%.2fx obs)  r %+.3f   GATE V sd %.3f vs obs %.3f +/- %.3f (z %+.2f)\n", a,
              if (is.null(ARMS[[a]]$pm$w_enso_l2)) NA_real_ else ARMS[[a]]$pm$w_enso_l2, e[["slope"]], e[["se"]], e[["slope"]] / OBS_SLOPE, e[["r"]], V$sd, ov$sd, ov$se, (V$sd - ov$sd) / ov$se)) }

cat("\n=== 3. THE LAPLACE SD OF w_enso_l2 AT a1 (full per-direction Hessian on the 29-name space) ===\n")
{ s <- ARMS$a1$s; rm <- ccx_apply_pins(s$pins[names(s$pins) %in% CCX_PARAM_NAMES])
  bp <- ARMS$a1$p; lp <- ccx_make_logpost(obs = obs, base_params = bp); u <- ccx_par_to_unc(ARMS$a1$pm); lp0 <- lp(u)
  cat(sprintf("  logpost at a1's vector: harness %.4f vs start file %.4f (diff %+.2e)\n", lp0, s$logpost, lp0 - s$logpost))
  stopifnot(abs(lp0 - s$logpost) < 1e-3)
  t0 <- Sys.time(); HD <- ccx_hessian_per_direction(lp, u, verbose = FALSE); H <- HD$H
  ev <- eigen(-H, symmetric = TRUE, only.values = TRUE)$values; pd <- all(ev > 0)
  cat(sprintf("  Hessian %dx%d in %.1f min; -H positive definite: %s (min eigen %.3g, cond %.3g); unstable directions: %s\n", nrow(H), ncol(H), as.numeric(difftime(Sys.time(), t0, units = "mins")), pd, min(ev), max(ev) / min(ev),
              if (length(HD$unstable)) paste(HD$unstable, collapse = ", ") else "none"))
  SD_U <- if (pd) sqrt(diag(solve(-H))) else HD$sd_diag; names(SD_U) <- names(u)
  iw <- match("w_enso_l2", names(u)); sw <- CCX_PARAM_TABLE$w_enso_l2
  w_hat <- ARMS$a1$pm$w_enso_l2; w_lo <- .from_unc(u[[iw]] - SD_U[[iw]], sw); w_hi <- .from_unc(u[[iw]] + SD_U[[iw]], sw)
  cat(sprintf("  w_enso_l2 = %.2f Sv per index, +/- 1 Laplace sd on the logit scale -> [%.2f, %.2f] (%s); diagonal-only sd would give [%.2f, %.2f]\n", w_hat, w_lo, w_hi,
              if (pd) "marginal, from the inverse Hessian" else "DIAGONAL ONLY -- -H not PD", .from_unc(u[[iw]] - HD$sd_diag[[iw]], sw), .from_unc(u[[iw]] + HD$sd_diag[[iw]], sw)))
  cat(sprintf("  correlation of w_enso_l2 with: %s\n", if (pd) { C <- solve(-H); C <- C / outer(sqrt(diag(C)), sqrt(diag(C))); cc <- C[iw, -iw]; names(cc) <- names(u)[-iw]; cc <- sort(cc, decreasing = TRUE); paste(sprintf("%s %+.2f", names(cc)[c(1:3, (length(cc) - 2):length(cc))], cc[c(1:3, (length(cc) - 2):length(cc))]), collapse = ", ") } else "n/a"))
  ccx_unpin_params(rm) }

cat("\n=== 4. PA3-PA5: the level rows, the deep names, the land pair vs the canonical ===\n")
d_lvl <- ST$a1[L2_PA3_ROWS] - ST$canonical[L2_PA3_ROWS]; d_13 <- ST$a1[L2_PA3_D13C] - ST$canonical[L2_PA3_D13C]
pa3 <- all(abs(d_lvl) < L2_PA3_TOL) && all(abs(d_13) < L2_PA3_D13C_TOL)
cat(sprintf("  PA3 %s: %s; %s\n", if (pa3) "PASS" else "FAIL", paste(sprintf("%s %+.2f", L2_PA3_ROWS, d_lvl), collapse = ", "), paste(sprintf("%s %+.2f", L2_PA3_D13C, d_13), collapse = ", ")))
sdc <- ARMS$canonical$md$sd_unc; uc <- ARMS$canonical$md$u_mode; names(uc) <- ARMS$canonical$md$param_names

{ s <- ARMS$a1$s; ua <- s$u_mode; names(ua) <- s$param_names }
pa4_ok <- TRUE
for (n in L2_PA4_NAMES) { z <- (ua[[n]] - uc[[n]]) / sdc[[n]]; ok <- abs(z) < 1; pa4_ok <- pa4_ok && ok
  cat(sprintf("  PA4 %-14s canonical %10.4g  a1 %10.4g   du %+.3f = %+.2f canonical sd -> %s\n", n, ARMS$canonical$pm[[n]], ARMS$a1$pm[[n]], ua[[n]] - uc[[n]], z, if (ok) "ok" else "MOVED")) }
d_pa4 <- ST$a1[L2_PA4_ROWS] - ST$canonical[L2_PA4_ROWS]
cat(sprintf("  PA4 rows (a1 - canonical, log-units): %s  [the prereg's '1 posterior sigma' has no row-level sd; read as a magnitude]\n", paste(sprintf("%s %+.2f", L2_PA4_ROWS, d_pa4), collapse = ", ")))
pa5_ok <- TRUE
for (n in L2_PA5_NAMES) { z <- (ua[[n]] - uc[[n]]) / sdc[[n]]; ok <- abs(z) < 1; pa5_ok <- pa5_ok && ok
  cat(sprintf("  PA5 %-20s canonical %.4f  a1 %.4f   du %+.3f = %+.2f canonical sd -> %s\n", n, ARMS$canonical$pm[[n]], ARMS$a1$pm[[n]], ua[[n]] - uc[[n]], z, if (ok) "ok" else "MOVED")) }

cat("\n=== 5. PA6: the demean flag's price at a1 (test-enso-demean's scoring, transcribed) ===\n")
{ s <- ARMS$a1$s; rm <- ccx_apply_pins(s$pins[names(s$pins) %in% CCX_PARAM_NAMES]); bp <- ARMS$a1$p; u <- ccx_par_to_unc(ARMS$a1$pm)
  sc <- function(dm) { old <- FORC_ENSO_DEMEAN; assign("FORC_ENSO_DEMEAN", dm, envir = globalenv()); on.exit(assign("FORC_ENSO_DEMEAN", old, envir = globalenv()), add = TRUE)
    ccx_make_logpost(obs = obs, base_params = bp, spinup_fn = ccx_periodic_spinup)(u) }
  on_ <- sc(TRUE); off_ <- sc(FALSE); price <- on_ - off_
  cat(sprintf("  demean ON %.4f, OFF %.4f -> price %.4f (at hilda30s %.4f; PA6 bound >= %g) -> %s\n", on_, off_, price, L2_PA6_REF, L2_PA6_MIN, if (price >= L2_PA6_MIN) "PASS" else "FAIL"))
  ccx_unpin_params(rm); PA6 <- price }

cat("\n=== 6. GATE 7 and the chain (H / GL / Q / S), for the record ===\n")
tg7 <- dg_gcb_target(DG_SINK_WIN); OH <- dg_gateH_obs(obs); verd <- list(); G7 <- list(); GH <- list()
for (a in an) { g7 <- dg_gate7(R[[a]]); vd <- dg_gate7_verdict(g7, tg7); G7[[a]] <- list(g = g7, v = vd)
  cat(sprintf("  GATE 7  %-10s ocean %.2f (z %+.2f) land %.2f (z %+.2f) -> %s\n", a, g7$ocean, vd$z_ocean, g7$land, vd$z_land, if (isTRUE(vd$pass)) "PASS" else "FAIL")) }
for (a in an) { gh <- dg_gateH(ARMS[[a]], obs, OH, r = R[[a]]); GH[[a]] <- gh; vd <- dg_gateH_verdict(gh, OH); verd[[a]]$H <- vd
  cat(sprintf("  GATE H  %-10s R_co2 %.3f R_d13c %.3f contrast z %+.2f -> %s\n", a, vd$R_co2, vd$R_d13c, vd$z, if (vd$pass) "PASS" else "FAIL")) }
for (a in an) { vd <- dg_gateGL_verdict(GH[[a]], OH); verd[[a]]$GL <- vd; cat(sprintf("  GATE GL %-10s ratio %.2f z %+.2f -> %s\n", a, vd$ratio, vd$z, if (vd$pass) "PASS" else "FAIL")) }
for (a in an) { q <- dg_gateQ(R[[a]], ARMS[[a]]); verd[[a]]$Q <- q; cat(sprintf("  GATE Q  %-10s mean %+.3f n_sd %.2f -> %s\n", a, q$mean, q$n_sd, if (q$pass) "PASS" else "FAIL")) }
for (a in an) { vd <- tryCatch({ g <- dg_gateS(ARMS[[a]], obs, r = R[[a]]); dg_gateS_verdict(g) }, error = function(e) NULL); verd[[a]]$S <- vd
  if (!is.null(vd)) cat(sprintf("  GATE S  %-10s SPO limb %.3f ppm @ %.2f [%.2f, %.2f] -> %s\n", a, vd$amp, vd$mo, vd$lo, vd$hi, if (vd$pass) "PASS" else "FAIL")) }

cat("\n=== VERDICT (prereg 2026-09-17k s4 PA1, in the physical unit) ===\n")
w1 <- ARMS$a1$pm$w_enso_l2; e1 <- ES$a1
in_br <- w1 >= L2_BRACKET[1] && w1 <= L2_BRACKET[2]; partial <- w1 > L2_BRACKET[2] && w1 <= L2_PARTIAL_HI
slope_ok <- e1[["slope"]] >= L2_SLOPE_BAND[1] && e1[["slope"]] <= L2_SLOPE_BAND[2]; r_ok <- e1[["r"]] > L2_R_MIN; lik_ok <- tot[["a1"]] >= L2_LIK_MIN
cat(sprintf("  w_enso_l2 %.2f [%.2f, %.2f] Sv/index vs Meinen [%g, %g]: %s\n", w1, w_lo, w_hi, L2_BRACKET[1], L2_BRACKET[2], if (in_br) "INSIDE" else if (w1 < L2_BRACKET[1]) "BELOW the bracket" else if (partial) "ABOVE (the PARTIAL band)" else "ABOVE 40"))
cat(sprintf("  slope %+.4f in [%.3f, %.3f]: %s;  r %+.3f > %.2f: %s;  likelihood %.2f >= %.1f: %s (canonical %.2f; a1 - canonical %+.2f)\n", e1[["slope"]], L2_SLOPE_BAND[1], L2_SLOPE_BAND[2], if (slope_ok) "PASS" else "FAIL", e1[["r"]], L2_R_MIN, if (r_ok) "PASS" else "FAIL", tot[["a1"]], L2_LIK_MIN, if (lik_ok) "PASS" else "FAIL", tot[["canonical"]], tot[["a1"]] - tot[["canonical"]]))
cat(sprintf("  PA2 GATE V sd %.3f >= %.3f: %s (soft)\n", GV$a1$sd, L2_V_MIN, if (GV$a1$sd >= L2_V_MIN) "PASS" else "FAIL"))
cat(sprintf("  PA3 %s   PA4 names %s   PA5 %s   PA6 %s\n", if (pa3) "PASS" else "FAIL", if (pa4_ok) "PASS" else "FAIL", if (pa5_ok) "PASS" else "FAIL", if (PA6 >= L2_PA6_MIN) "PASS" else "FAIL"))
verdict <- if (in_br && slope_ok && r_ok && lik_ok && pa3 && pa4_ok) "PASS" else if (partial && slope_ok && lik_ok) "PARTIAL -- the reservoir is needed (rank 3 next)" else "REFUTED (as the prereg's rule reads)"
cat(sprintf("  PA1 -> %s\n", verdict))
if (w1 < L2_BRACKET[1]) cat("  NOTE the prereg names only PASS / PARTIAL-ABOVE / REFUTED; a fitted value BELOW the bracket is the REFUTED branch by the rule's letter,\n       but it is a different finding from 'above 40': the refit wants LESS limb than the observation needs, not more.\n")
cat("  Promotion is a ruling in every branch; nothing is adopted here.\n")
saveRDS(list(job = HR_JOB, dir = HR_DIR, ids = c(a1 = HR_A1, a2 = HR_A2, a3 = HR_A3), params = lapply(ARMS, function(v) list(p = v$p, pm = v$pm, prior_z = v$prior_z, src = v$src)),
             streams = ST, groups = G, enso = ES, gateV = GV, obs_slope = c(slope = OBS_SLOPE, se = OBS_SE), hessian = list(H = H, sd_unc = SD_U, pd = pd, w_ci = c(w_lo, w_hi)),
             pa = list(pa3 = pa3, pa4 = pa4_ok, pa5 = pa5_ok, pa6 = PA6), gate7 = G7, verdicts = verd, verdict = verdict, built = format(Sys.time())), paste0(HR_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n⛔ NOTHING IS ADOPTED; no mode is promoted.\n", HR_OUT))
