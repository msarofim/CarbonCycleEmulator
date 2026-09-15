# =====================================================================
# diag_o1_deep_return_scan.R -- THE O1 PROBE of
# notes/prereg_2026-09-15d_o1_deep_return_probe.md §3-4: the MEAN DEEP RETURN
# in two arms, scanned jointly in RETURN DEPTH k x kz with the export
# PRESCRIBED (martin, Nowicki 9.08), unrefitted at the canonical (hilda30c),
# on the C++ objective under the file's pins.
#   Arm THC -- the HS-route limb (w_thc, k_thc): LS ML -> HS -> HD -> bottom ->
#              up through every interface below k -> layer k -> ML.
#   Arm STC -- the local loop (E's w_vent at k_e1 = k_e2 = k, gamma_vent 0).
#   CONTROL -- the canonical structure (solved field, no limb) at the same kz.
#   Stage 1  RAW: every grid point, one C++ run; the 25 rows vs the canonical,
#            the WOCE 1975/1995 bomb inventory and its z, the modern DIC
#            gradient and its z, the PI profile (layer 2 / 6 / bottom - ML),
#            the bomb / CO2 / profile rows, the sink.
#   Stage 2  ARM C: per (arm, k) the (W, f) point with the best raw dlik,
#            re-optimised over {beta_max, fert_k, q10, kz_deep_frac, h_ml,
#            k_w, bomb_total, sigma_d14c} (the PK-2 machinery); the CONTROL
#            re-optimised the same way at every f.
#   Stage 3  the overlap check: the best THC point at tau_q x {0.5, 2}.
#   The decision rule (prereg §4) is evaluated and printed; nothing adopted.
# Usage: Rscript calibration/diag_o1_deep_return_scan.R      (DR_SMOKE=1 for a 3-point smoke)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
DR_ARM     <- CCX_MODE_CANONICAL
DR_EXPORT  <- ccx_pump_export_prior()$centre_gtc          # 9.08, Nowicki's LS median -- READ, not typed
DR_KZ_FAC  <- c(1, 0.7, 0.5, 0.35, 0.2)                    # kz multipliers (0.2 ~ 2,200 m2/yr)
DR_THC_K   <- c(1L, 2L, 3L, 4L, 6L, 8L, 10L)               # THC return layers (the whole axis)
DR_THC_W   <- c(10, 20, 30)                                # Sv, both hemispheres
DR_STC_K   <- c(1L, 2L, 3L, 4L)                            # STC: the thermocline only (its physics)
DR_STC_W   <- c(10, 20, 40)                                # Sv, whole-LS
DR_LAND    <- c("beta_max", "fert_k", "q10")
DR_SURF    <- c("kz_deep_frac", "h_ml", "k_w", "bomb_total", "sigma_d14c")
DR_ARMC    <- c(DR_LAND, DR_SURF)
DR_NM_MAXIT <- 1500; DR_BFGS_MAXIT <- 100
DR_GATE_TOL <- 1e-4                                       # harness gate: rebuilt logpost vs stored
DR_D_ALONE  <- -894.8                                      # E probe 09-14: martin w0 g0, d lik on the 25 rows (option_e_probe_20260914.log)
DR_TAUQ_FAC <- c(0.5, 2)
DR_SMOKE   <- nzchar(Sys.getenv("DR_SMOKE", ""))
if (DR_SMOKE) { DR_KZ_FAC <- c(1, 0.5); DR_THC_K <- c(1L, 6L); DR_THC_W <- 20; DR_STC_K <- 2L; DR_STC_W <- 20; DR_NM_MAXIT <- 20; DR_BFGS_MAXIT <- 5 }
DR_OUT     <- ccx_path("outputs", "diagnostics", sprintf("o1_deep_return_scan_%s%s", format(Sys.Date(), "%Y%m%d"), if (DR_SMOKE) "_smoke" else ""))
sink_log <- file(paste0(DR_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)
cat(sprintf("== O1 deep-return probe at %s (prereg 2026-09-15d) -- commit %s ==\n", DR_ARM,
            tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")))
cat(sprintf("export %.2f GtC/yr (martin); kz x %s; THC k %s x W %s Sv; STC k %s x W %s Sv; arm C = %s\n\n", DR_EXPORT,
            paste(DR_KZ_FAC, collapse = "/"), paste(DR_THC_K, collapse = "/"), paste(DR_THC_W, collapse = "/"),
            paste(DR_STC_K, collapse = "/"), paste(DR_STC_W, collapse = "/"), paste(DR_ARMC, collapse = ",")))

# ---- the observations the decision rule reads (READ, never typed) --------
obs <- ccx_prepare_obs()
exc_obs <- obs$excess_c14                      # year / centre / half_width (Peacock + Key)
tg <- ccx_ocean_gradient_target()
cat(sprintf("obs: ocean bomb excess %s kmol; DIC gradient target %.1f (sd %.1f, cluster %.1f)\n\n",
            paste(sprintf("%d: %.1f +- %.1f", exc_obs$year, exc_obs$centre, exc_obs$half_width), collapse = ", "),
            tg$dic$target, tg$dic$sd, tg$dic$sd_cluster))

# ---- stage 1 machinery: the dg path (p directly; exact zeros) ----------
v0 <- dg_vector(DR_ARM); kz0 <- v0$p$kz
r_ref <- dg_run(v0); ref <- unlist(dg_streams(r_ref, v0))
md <- v0$md
cat(sprintf("HARNESS GATE 1: dg streams at the canonical vs stored: sum %.4f vs %.4f -> %s\n", sum(ref[names(md$streams)]), sum(md$streams),
            if (abs(sum(ref[names(md$streams)]) - sum(md$streams)) < DR_GATE_TOL) "PASS" else "FAIL"))
if (abs(sum(ref[names(md$streams)]) - sum(md$streams)) >= DR_GATE_TOL) stop("harness gate 1 failed")
conc_layer <- function(y, aux, grid, h, k) {   # umol/kg of interior layer k (0 = ML), y-based (PI, annual mean = the spinup)
  m <- if (k == 0) aux$a_ml[[h]] * grid$dz[1] else aux$a_ls[[h]] * grid$dz[k + 1]
  i <- if (k == 0) aux$idx[[h]]$ml else aux$idx[[h]]$oc[k]
  y[i, "C"] * aux$mol_per_GtC / (m * ccx_const("RHO_SEAWATER")) * 1e6 }
point_p <- function(arm, k, W, f) {
  v <- v0; p <- v$p; p$kz <- kz0 * f
  if (arm != "CONTROL") {
    p$pump_field <- "martin"; p$pump_export <- DR_EXPORT
    p$gamma_enso_ocn_NH <- 0; p$gamma_enso_ocn_SH <- 0; p$gamma_vent <- 0
    if (arm == "THC") { p$w_thc <- W; p$k_thc <- k; p$w_vent <- 0 }
    if (arm == "STC") { p$w_vent <- W; p$k_e1 <- k; p$k_e2 <- k; p$w_thc <- 0 }
  }
  v$p <- p; v
}
read_point <- function(v) {
  r <- dg_run(v); sp <- r$sp; aux <- sp$aux; grid <- sp$grid; y <- sp$y; out <- r$out; yr <- floor(out$t + 1e-9)
  stv <- unlist(dg_streams(r, v)); cm <- intersect(names(stv), names(ref)); d <- stv[cm] - ref[cm]
  exc <- vapply(exc_obs$year, function(Y) ccx_c14_kmol(mean(out$ocean_C14[yr == Y]) - out$ocean_C14[1]), numeric(1))
  z_exc <- (exc - exc_obs$centre) / exc_obs$half_width
  g <- ccx_ocean_grad_scored(out, sp); z_dic <- (g$dic - tg$dic$target) / g$sd_eff[["dic"]]
  pr <- rowMeans(sapply(HEMIS, function(h) c(conc_layer(y, aux, grid, h, 2), conc_layer(y, aux, grid, h, 6), conc_layer(y, aux, grid, h, grid$nl)) - conc_layer(y, aux, grid, h, 0)))
  s7 <- dg_gate7(r)
  rows <- function(pat) sum(d[grep(pat, cm)])
  spin_resid <- if (!is.null(sp$periodic)) sp$periodic$resid_carbon else NA_real_   # the prereg: a non-converging spinup is a FINDING, recorded
  list(d = d, dlik = sum(d), exc = exc, z_exc = z_exc, dic_grad = g$dic, z_dic = z_dic, prof = pr, sink = s7$ocean, spin_resid = spin_resid,
       bomb = rows("^d14c_(NH|SH)$"), co2 = rows("^co2"), d14prof = rows("^d14c_profile"), d13 = rows("^d13c"),
       substeps = ccx_substeps_for(v$p), export = sum(unlist(lapply(HEMIS, function(h) aux$pump[[h]]$org + aux$pump[[h]]$carb))))
}
fmt <- function(lab, rp) sprintf("%-26s | dlik %+8.1f | exc75/95 %5.1f/%5.1f (z %+4.1f/%+4.1f) | DIC grad %5.1f (z %+4.1f) | PI L2/L6/bot-ML %+5.0f/%+5.0f/%+5.0f | bomb %+6.1f co2 %+7.1f d14prof %+6.1f d13 %+6.1f | sink %.2f | ss %d%s",
                                lab, rp$dlik, rp$exc[1], rp$exc[2], rp$z_exc[1], rp$z_exc[2], rp$dic_grad, rp$z_dic, rp$prof[1], rp$prof[2], rp$prof[3],
                                rp$bomb, rp$co2, rp$d14prof, rp$d13, rp$sink, rp$substeps,
                                if (is.finite(rp$spin_resid) && rp$spin_resid >= PS_TOL) sprintf(" | SPINUP NOT CONVERGED resid %.1e", rp$spin_resid) else "")

# HARNESS GATE 2/3: the limb at 0 is E's D exactly, and k is inert at W = 0
g_thc0 <- read_point(point_p("THC", 1L, 0, 1)); g_thc0b <- read_point(point_p("THC", 10L, 0, 1)); g_stc0 <- read_point(point_p("STC", 2L, 0, 1))
cat(sprintf("HARNESS GATE 2: martin, no limb: dlik %+.1f vs the E probe's D-alone %+.1f -> %s\n", g_thc0$dlik, DR_D_ALONE,
            if (abs(g_thc0$dlik - DR_D_ALONE) < 0.5) "PASS" else "FAIL (a different D-alone: the code path moved since 09-14)"))
cat(sprintf("HARNESS GATE 3: k inert at W = 0 (THC k1 vs k10, STC k2): %.2e / %.2e -> %s\n\n", max(abs(g_thc0$d - g_thc0b$d)), max(abs(g_thc0$d - g_stc0$d)),
            if (max(abs(g_thc0$d - g_thc0b$d)) < 1e-9 && max(abs(g_thc0$d - g_stc0$d)) < 1e-9) "PASS" else "FAIL"))

# ---- stage 1: the grid -------------------------------------------------
grid1 <- rbind(expand.grid(arm = "CONTROL", k = 0L, W = 0, f = DR_KZ_FAC, stringsAsFactors = FALSE),
               expand.grid(arm = "THC", k = DR_THC_K, W = DR_THC_W, f = DR_KZ_FAC, stringsAsFactors = FALSE),
               expand.grid(arm = "STC", k = DR_STC_K, W = DR_STC_W, f = DR_KZ_FAC, stringsAsFactors = FALSE))
cat(sprintf("== STAGE 1: %d points ==\n", nrow(grid1)))
S1 <- vector("list", nrow(grid1)); t_all <- proc.time()[["elapsed"]]
for (i in seq_len(nrow(grid1))) {
  g1 <- grid1[i, ]; lab <- sprintf("%s k%-2d W%-2g f%.2f", g1$arm, g1$k, g1$W, g1$f)
  rp <- tryCatch(read_point(point_p(g1$arm, g1$k, g1$W, g1$f)), error = function(e) { cat(sprintf("%-26s | FAILED: %s\n", lab, conditionMessage(e))); NULL })
  if (!is.null(rp)) { cat(fmt(lab, rp), "\n"); S1[[i]] <- rp }
}
cat(sprintf("stage 1 done in %.0f s\n\n", proc.time()[["elapsed"]] - t_all))
tab1 <- cbind(grid1, do.call(rbind, lapply(S1, function(r) if (is.null(r)) data.frame(dlik = NA, exc95 = NA, z_exc95 = NA, dic_grad = NA, z_dic = NA, L2 = NA, bomb = NA, co2 = NA)
  else data.frame(dlik = r$dlik, exc95 = r$exc[2], z_exc95 = r$z_exc[2], dic_grad = r$dic_grad, z_dic = r$z_dic, L2 = r$prof[1], bomb = r$bomb, co2 = r$co2))))

# P1 / P2 / P3 from stage 1
cat("== P1 (not inert where kz falls): |dlik(W=20) - dlik(W=0)| at f <= 0.5 ==\n")
W0 <- list()   # martin, no limb, at each f -- ONE run per f (k is inert at W = 0, gate 3; both arms share it)
for (f in DR_KZ_FAC[DR_KZ_FAC <= 0.5]) W0[[as.character(f)]] <- read_point(point_p("THC", 1L, 0, f))$dlik
for (arm in c("THC", "STC")) for (k in unique(grid1$k[grid1$arm == arm])) for (f in DR_KZ_FAC[DR_KZ_FAC <= 0.5]) {
  d0 <- W0[[as.character(f)]]
  W1 <- 20
  d1 <- tab1$dlik[tab1$arm == arm & tab1$k == k & tab1$W == W1 & abs(tab1$f - f) < 1e-9]
  if (length(d1) == 1 && is.finite(d1)) cat(sprintf("  %s k%-2d f%.2f: W0 %+8.1f  W%g %+8.1f  |diff| %6.1f -> %s\n", arm, k, f, d0, W1, d1, abs(d1 - d0),
                                             if (abs(d1 - d0) > 5) "MOVES" else "inert"))
}
cat("\n== P2 (return depth, THC at W 20): the CO2 rows by k ==\n")
for (f in DR_KZ_FAC) { s <- tab1[tab1$arm == "THC" & tab1$W == 20 & abs(tab1$f - f) < 1e-9, ]
  if (nrow(s)) cat(sprintf("  f%.2f: %s\n", f, paste(sprintf("k%d %+.0f", s$k, s$co2), collapse = "  "))) }
p3 <- tab1[tab1$arm == "THC" & tab1$k == 1 & tab1$W == 20 & abs(tab1$f - 1) < 1e-9, ]
if (nrow(p3)) cat(sprintf("\n== P3: THC k1 W20 f1 (T-A0's geometry with HS water): dlik %+.1f, d14c_profile rows %+.1f vs T-A0's -135 / -104 -> %s ==\n\n",
                          p3$dlik, S1[[which(grid1$arm == "THC" & grid1$k == 1 & grid1$W == 20 & abs(grid1$f - 1) < 1e-9)]]$d14prof,
                          if (p3$dlik > -135) "PASS (cheaper than the ML-sourced limb)" else "FAIL (HS water does not help at this geometry)"))

# ---- stage 2: arm C at the best raw point per (arm, k), and the control ---
cat("== STAGE 2: arm C re-optimisation ==\n")
rm_pins <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm_pins), add = TRUE)
bp0 <- ccx_mode_base(md); bp0$pump_mode <- md$pump_mode
st <- ccx_mode_start(md, "o1_scan"); pm0 <- st$p
lp_solved <- ccx_make_logpost(base_params = bp0, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
v_s <- lp_solved(st$u); ref_st <- attr(v_s, "streams")
cat(sprintf("HARNESS GATE 4: rebuilt logpost %.4f (shift %+.4f) vs stored %.4f -> %s\n", as.numeric(v_s) - st$logpost_shift, st$logpost_shift, md$logpost,
            if (abs(as.numeric(v_s) - st$logpost_shift - md$logpost) < DR_GATE_TOL) "PASS" else "FAIL"))
if (abs(as.numeric(v_s) - st$logpost_shift - md$logpost) >= DR_GATE_TOL) stop("harness gate 4 failed")
ccx_unpin_params(rm_pins); rm_pins <- list()
# per arm: the OFF names PINNED (0 is off every logit floor and cannot ride in u), the structural k on base_params
arm_pins <- function(arm) {
  base <- ccx_mode_pins(md)
  off <- if (arm == "THC") c(w_vent = 0, gamma_vent = 0, gamma_enso_ocn_NH = 0, gamma_enso_ocn_SH = 0)
         else if (arm == "STC") c(w_thc = 0, gamma_vent = 0, gamma_enso_ocn_NH = 0, gamma_enso_ocn_SH = 0)
         else c(w_thc = 0, w_vent = 0, gamma_vent = 0, pump_export = 0)   # CONTROL: solved, every martin name inert anyway
  c(base, off)
}
reopt_point <- function(arm, k, W, f) {
  pins <- arm_pins(arm); rm <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rm), add = TRUE)
  bp <- bp0; for (n in names(pins)) bp[[n]] <- pins[[n]]
  if (arm != "CONTROL") { bp$pump_field <- "martin"; if (arm == "THC") bp$k_thc <- k else { bp$k_e1 <- k; bp$k_e2 <- k } }
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
  pm <- pm0[setdiff(names(pm0), names(pins))]; pm$kz <- kz0 * f
  if (arm != "CONTROL") { pm$pump_export <- DR_EXPORT; if (arm == "THC") pm$w_thc <- W else pm$w_vent <- W }
  u <- ccx_par_to_unc(pm); stopifnot(all(is.finite(u)))
  idx <- match(DR_ARMC, CCX_PARAM_NAMES); stopifnot(!any(is.na(idx)))
  fobj <- function(z) { uu <- u; uu[idx] <- z; x <- -as.numeric(lp(uu)); if (!is.finite(x)) 1e10 else x }
  v_raw <- lp(u)
  o1 <- stats::optim(u[idx], fobj, method = "Nelder-Mead", control = list(maxit = DR_NM_MAXIT, reltol = 1e-10))
  o2 <- stats::optim(o1$par, fobj, method = "BFGS", control = list(maxit = DR_BFGS_MAXIT, reltol = 1e-12))
  best <- if (o2$value < o1$value) o2 else o1; uu <- u; uu[idx] <- best$par
  v <- lp(uu); pmb <- ccx_unc_to_par(uu)
  st_raw <- attr(v_raw, "streams"); st_c <- attr(v, "streams"); cm <- intersect(names(st_c), names(ref_st))
  list(arm = arm, k = k, W = W, f = f, pm = pmb, dlik_raw = sum(st_raw[cm] - ref_st[cm]), dlik = sum(st_c[cm] - ref_st[cm]),
       d = st_c[cm] - ref_st[cm], n_eval = o1$counts[1] + o2$counts[1],
       # the decision-rule reads at the re-optimised point, on the dg path (same physics, the harness the prereg names)
       # the decision-rule reads at the re-optimised point, on the dg path (same physics, the harness the prereg names):
       # the fitted names are written onto the point's p directly (the pinned OFF names stay as point_p set them; the
       # ocean gammas at 0 -- ccx_set_enso() is NOT used because it would default an absent pinned gamma)
       read = { vv <- point_p(arm, k, W, f); for (n in names(pmb)) if (n %in% names(vv$p)) vv$p[[n]] <- pmb[[n]]
                for (n in c("luc_scale", "bomb_total", "sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c")) if (!is.null(pmb[[n]])) vv[[n]] <- pmb[[n]]
                read_point(vv) })
}
sel <- NULL
for (arm in c("THC", "STC")) for (k in unique(grid1$k[grid1$arm == arm])) {
  s <- tab1[tab1$arm == arm & tab1$k == k & is.finite(tab1$dlik), ]; if (!nrow(s)) next
  b <- s[which.max(s$dlik), ]; sel <- rbind(sel, data.frame(arm = arm, k = k, W = b$W, f = b$f, dlik_raw = b$dlik))
}
for (f in DR_KZ_FAC) sel <- rbind(sel, data.frame(arm = "CONTROL", k = 0L, W = 0, f = f, dlik_raw = tab1$dlik[tab1$arm == "CONTROL" & abs(tab1$f - f) < 1e-9]))
cat("selected for arm C (best raw per arm x k; the control at every f):\n"); print(sel)
S2 <- list()
for (i in seq_len(nrow(sel))) {
  s <- sel[i, ]; t0 <- proc.time()[["elapsed"]]
  r2 <- tryCatch(reopt_point(s$arm, s$k, s$W, s$f), error = function(e) { cat(sprintf("armC %s k%d W%g f%.2f FAILED: %s\n", s$arm, s$k, s$W, s$f, conditionMessage(e))); NULL })
  if (is.null(r2)) next
  S2[[i]] <- r2
  cat(sprintf("armC %-7s k%-2d W%-2g f%.2f: raw %+8.1f -> armC %+8.1f (%d evals; kz_deep_frac %.4f h_ml %.1f k_w %.0f bomb_total %.1f sigma_d14c %.2f) | %s  [%.0f s]\n",
              s$arm, s$k, s$W, s$f, r2$dlik_raw, r2$dlik, r2$n_eval, r2$pm$kz_deep_frac, r2$pm$h_ml, r2$pm$k_w, r2$pm$bomb_total, r2$pm$sigma_d14c,
              sub("^.*? \\| ", "", fmt("", r2$read)), proc.time()[["elapsed"]] - t0))
  cat(sprintf("        largest rows: %s\n", paste(sprintf("%s %+.1f", names(sort(r2$d))[1:5], sort(r2$d)[1:5]), collapse = ", ")))
}

# ---- stage 3: the overlap check at the best THC point --------------------
S3 <- list()
best_thc <- Filter(function(r) !is.null(r) && r$arm == "THC", S2)
if (length(best_thc)) {
  bt <- best_thc[[which.max(vapply(best_thc, function(r) r$dlik, numeric(1)))]]
  cat(sprintf("\n== STAGE 3: tau_q x %s at the best THC point (k%d W%g f%.2f), raw path ==\n", paste(DR_TAUQ_FAC, collapse = "/"), bt$k, bt$W, bt$f))
  for (tf in DR_TAUQ_FAC) { v <- point_p("THC", bt$k, bt$W, bt$f); v$p$tau_q <- v0$p$tau_q * tf
    rp <- read_point(v); S3[[as.character(tf)]] <- rp; cat(fmt(sprintf("THC best, tau_q x%.1f", tf), rp), "\n") }
}

# ---- THE DECISION RULE (prereg §4) ---------------------------------------
cat("\n== THE DECISION RULE (a) |z exc1995| <= 1; (b) |z DIC grad| <= 1; (c) armC dlik >= CONTROL armC dlik at the same f; (d) PI layer 2 not inverted (L2 - ML >= 0) ==\n")
ctrl <- Filter(function(r) !is.null(r) && r$arm == "CONTROL", S2)
ctrl_at <- function(f) { x <- Filter(function(r) abs(r$f - f) < 1e-9, ctrl); if (length(x)) x[[1]]$dlik else NA }
verdict <- NULL
for (r in Filter(function(r) !is.null(r) && r$arm != "CONTROL", S2)) {
  a <- abs(r$read$z_exc[2]) <= 1; b <- abs(r$read$z_dic) <= 1; cc <- is.finite(ctrl_at(r$f)) && r$dlik >= ctrl_at(r$f); d <- r$read$prof[1] >= 0
  verdict <- rbind(verdict, data.frame(arm = r$arm, k = r$k, W = r$W, f = r$f, armC = r$dlik, control = ctrl_at(r$f),
                                       z_exc95 = r$read$z_exc[2], z_dic = r$read$z_dic, L2mML = r$read$prof[1], a = a, b = b, c = cc, d = d, PASS = a && b && cc && d))
}
print(verdict, digits = 3)
pass <- verdict[verdict$PASS, ]
cat(sprintf("\nVERDICT: %s\n", if (!nrow(pass)) "NO point passes (a)-(d): O1 is REFUTED AS BUILT under this probe; O2 (document) is the honest end state -- reported, not patched."
                               else sprintf("%d point(s) pass: %s", nrow(pass), paste(sprintf("%s k%d W%g f%.2f (armC %+.1f)", pass$arm, pass$k, pass$W, pass$f, pass$armC), collapse = "; "))))
saveRDS(list(grid = grid1, S1 = S1, tab1 = tab1, sel = sel, S2 = S2, S3 = S3, verdict = verdict, ref = ref, ref_st = ref_st, export = DR_EXPORT,
             kz_fac = DR_KZ_FAC, armc = DR_ARMC, canonical = DR_ARM, md_logpost = md$logpost, obs_exc = exc_obs, dic_target = tg$dic,
             commit = tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) NA), built = format(Sys.time())), paste0(DR_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n", DR_OUT))
