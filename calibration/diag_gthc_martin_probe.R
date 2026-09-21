# =====================================================================
# diag_gthc_martin_probe.R -- THE GLOBAL THERMOHALINE LOOP PROBED UNDER THE
# MARTIN FIELD, notes/prereg_2026-09-20v_global_thc_probe.md §3-4. Unrefitted
# at the canonical (hilda29l), C++ objective under the file's pins.
#   The loop: w_gthc [Sv, ONE global volume] -- ML_NH -> HS_NH -> HD_NH -> the
#   NH bottom layer -> the SH bottom layer -> up to layer k_gthc -> HD_SH ->
#   HS_SH -> ML_SH -> ML_NH. NH sinks, SH upwells. Built for GATE D.
#   Stage 1  RAW: W x k, one C++ run each; per point GATE D (asym, z, the four
#            regional D's), GATE Q, the 26-row dlik vs the canonical with the
#            named rows, the MLO-SPO d14C (2001-2007) and the d13C gradient
#            residual, the SH cold box's d13C, the spinup residual.
#   Stage 2  ARM C: per k the best RAW W (selection by raw dlik, stated) and
#            W = 0, re-optimised over {beta_max, fert_k, q10, kz_deep_frac,
#            h_ml, k_w, bomb_total, sigma_d14c} (the PK-2 machinery).
#   The reject rule (prereg §4) is evaluated and printed; nothing adopted.
# Usage: Rscript calibration/diag_gthc_martin_probe.R      (GP_SMOKE=1 for a 3-point smoke)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
GP_ARM     <- CCX_MODE_CANONICAL
GP_EXPORT  <- ccx_pump_export_prior()$centre_gtc          # 9.08, Nowicki's LS median -- READ, not typed
GP_W       <- c(0, 5, 10, 15, 20, 30)                      # Sv, ONE global volume
GP_K       <- c(10L, 8L)                                   # the SH return layer: the bottom; the CDW analogue (1.3-1.9 km)
GP_LAND    <- c("beta_max", "fert_k", "q10")
GP_SURF    <- c("kz_deep_frac", "h_ml", "k_w", "bomb_total", "sigma_d14c")
GP_ARMC    <- c(GP_LAND, GP_SURF)
GP_NM_MAXIT <- 1500; GP_BFGS_MAXIT <- 100
GP_GATE_TOL <- 1e-4                                       # harness gate: rebuilt logpost vs stored
GP_D_ALONE_0915 <- -894.8                                  # the 09-15 d martin/no-limb D-alone at hilda30c (o1_deep_return_scan_20260915_smoke.log) -- printed beside, NOT asserted (a different canonical)
GP_D14C_VAL <- ccx_path("data", "obs_d14c_station_validation.rds")   # held-out MLO + SPO monthly, 2001+
GP_D14C_YEARS <- 2001:2007
GP_P1_MIN_FALL <- 0.3; GP_P1_W <- 15                        # prereg P1: the SH cold box's D falls by >= 0.3 at W = 15
GP_P6_FREE <- -10                                          # prereg P6: the profile rows within -10 of W = 0
GP_SMOKE   <- nzchar(Sys.getenv("GP_SMOKE", ""))
# T1 (Marcus 09-21, "Try T1"): arm C WITH the HILDA ventilation names free -- u_hs (the HS <-> HD
# exchange velocity), pump_hs_gcm2 (the HS export) and h_hs (the cold box's thickness; all three set the
# cold box's residence time, which leg 1 collapses). tau_q is STRUCTURAL (not in the table) and stays at
# 538. Arm C at EVERY grid point (W {0, 5, 15} x k {10, 8}), not the best raw per k -- the question is
# whether the ventilation retunes around the loop, at each W.
GP_T1      <- nzchar(Sys.getenv("GP_T1", ""))
if (GP_T1) { GP_ARMC <- c(GP_ARMC, "u_hs", "pump_hs_gcm2", "h_hs"); GP_W <- c(0, 5, 15) }
# T2 (Marcus 09-21, "Try T2"; prereg s5): the NH sink fed from an aged interior layer -- kn_gthc {3, 6} at
# k_gthc 10, T1's arm C. GP_T2 implies GP_T1's arm-C set and grid; the kn axis replaces the k axis.
GP_T2      <- nzchar(Sys.getenv("GP_T2", ""))
GP_KN      <- if (GP_T2) c(3L, 6L) else 0L
if (GP_T2) { GP_T1 <- TRUE; GP_ARMC <- c(GP_ARMC, "u_hs", "pump_hs_gcm2", "h_hs"); GP_W <- c(0, 5, 15); GP_K <- 10L }
if (GP_SMOKE) { GP_W <- c(0, 15); GP_K <- 10L; GP_NM_MAXIT <- 20; GP_BFGS_MAXIT <- 5 }
GP_OUT     <- ccx_path("outputs", "diagnostics", sprintf("gthc_martin_probe_%s%s%s", format(Sys.Date(), "%Y%m%d"), if (GP_T2) "_t2" else if (GP_T1) "_t1" else "", if (GP_SMOKE) "_smoke" else ""))
sink_log <- file(paste0(GP_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)
GP_COMMIT <- if (file.exists("FROZEN_FROM_COMMIT.txt")) substr(trimws(readLines("FROZEN_FROM_COMMIT.txt")[1]), 1, 7) else   # a frozen copy has no .git
             tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")
cat(sprintf("== GLOBAL THC LOOP, martin probe at %s (prereg 2026-09-20v) -- commit %s, %s ==\n", GP_ARM, GP_COMMIT, format(Sys.time())))
cat(sprintf("export %.2f GtC/yr (martin); W %s Sv x k %s; arm C = %s\n\n", GP_EXPORT,
            paste(GP_W, collapse = "/"), paste(GP_K, collapse = "/"), paste(GP_ARMC, collapse = ",")))

# ---- the observations the reads use (READ, never typed) ---------------
obs <- ccx_prepare_obs(); do_D <- dg_gateD_obs()
d14v <- as.data.frame(readRDS(GP_D14C_VAL)); a14 <- aggregate(d14c ~ station + year, d14v[d14v$year %in% GP_D14C_YEARS, ], mean)
w14 <- reshape(a14, idvar = "year", timevar = "station", direction = "wide"); w14 <- w14[complete.cases(w14), ]
OBS_D14_MLO_SPO <- mean(w14$d14c.MLO - w14$d14c.SPO); OBS_D14_SD <- sd(w14$d14c.MLO - w14$d14c.SPO)
cat(sprintf("obs: gate D asym %+.3f +- %.3f (NH ml %+.2f hs %+.2f, SH ml %+.2f hs %+.2f); gate Q %.2f +- %.2f; MLO-SPO D14C %d-%d %+.2f +- %.2f permil (n %d)\n\n",
            do_D$asym, do_D$asym_se, do_D$region$NH_ml$mean, do_D$region$NH_hs$mean, do_D$region$SH_ml$mean, do_D$region$SH_hs$mean,
            DG_Q_OBS, DG_Q_SD, min(w14$year), max(w14$year), OBS_D14_MLO_SPO, OBS_D14_SD, nrow(w14)))

# ---- stage 1 machinery: the dg path (p directly; exact zeros) ----------
v0 <- dg_vector(GP_ARM); md <- v0$md
r_ref <- dg_run(v0); ref <- unlist(dg_streams(r_ref, v0))
cat(sprintf("HARNESS GATE 1: dg streams at the canonical vs stored: sum %.4f vs %.4f -> %s\n", sum(ref[names(md$streams)]), sum(md$streams),
            if (abs(sum(ref[names(md$streams)]) - sum(md$streams)) < GP_GATE_TOL) "PASS" else "FAIL"))
if (abs(sum(ref[names(md$streams)]) - sum(md$streams)) >= GP_GATE_TOL) stop("harness gate 1 failed")
gD_ref <- dg_gateD_verdict(dg_gateD(r_ref, v0)); gQ_ref <- dg_gateQ(r_ref, v0)
mg <- function(mod, years) mod$MLO$level[match(years, mod$MLO$year)] - mod$SPO$level[match(years, mod$SPO$year)]
grad_resid <- function(out) {   # diag_d13c_gradient_offset.R s1's estimator: mean over the overlap years of model MLO-SPO d13C minus observed
  ms <- ccx_model_stats(out, obs); g <- obs$d13c_grad; mean(mg(ms$d13, g$year) - g$grad, na.rm = TRUE) }
d14_mlo_spo <- function(out) { yr <- floor(out$t + 1e-9); mean(vapply(GP_D14C_YEARS, function(Y) mean((out$d14c_NH - out$d14c_SH)[yr == Y]), 0)) }
d13_hs <- function(out, h, Y = DG_Q_YEAR) { yr <- floor(out$t + 1e-9); j <- yr == Y
  mean(1000 * (out[[paste0("hs_C13_", h)]][j] / (out[[paste0("hs_C_", h)]][j] * ccx_const("R13_VPDB")) - 1)) }
cat(sprintf("canonical (solved): gate D asym %+.3f z %+.2f [NH ml %+.2f hs %+.2f | SH ml %+.2f hs %+.2f]; gate Q %.3f n_sd %.2f; MLO-SPO D14C %+.2f; d13C grad resid %+.4f; hs d13C NH %.2f SH %.2f\n\n",
            gD_ref$asym, gD_ref$z, gD_ref$region[["NH_ml"]], gD_ref$region[["NH_hs"]], gD_ref$region[["SH_ml"]], gD_ref$region[["SH_hs"]],
            gQ_ref$mean, gQ_ref$n_sd, d14_mlo_spo(r_ref$out), grad_resid(r_ref$out), d13_hs(r_ref$out, "NH"), d13_hs(r_ref$out, "SH")))
point_p <- function(W, k, kn = 0L) {
  v <- v0; p <- v$p; p$kn_gthc <- kn
  p$pump_field <- "martin"; p$pump_export <- GP_EXPORT
  p$gamma_enso_ocn_NH <- 0; p$gamma_enso_ocn_SH <- 0; p$gamma_vent <- 0; p$w_vent <- 0; p$w_thc <- 0
  p$w_gthc <- W; p$k_gthc <- k
  v$p <- p; v
}
read_point <- function(v) {
  r <- dg_run(v); sp <- r$sp; out <- r$out
  stv <- unlist(dg_streams(r, v)); cm <- intersect(names(stv), names(ref)); d <- stv[cm] - ref[cm]
  gD <- dg_gateD_verdict(dg_gateD(r, v)); gQ <- dg_gateQ(r, v)
  rows <- function(pat) sum(d[grep(pat, cm)])
  spin_resid <- if (!is.null(sp$periodic)) sp$periodic$resid_carbon else NA_real_
  list(d = d, dlik = sum(d), gD = gD, gQ = gQ, d14 = d14_mlo_spo(out), resid = grad_resid(out),
       hs13 = c(NH = d13_hs(out, "NH"), SH = d13_hs(out, "SH")), spin_resid = spin_resid,
       bomb = rows("^d14c_(NH|SH)$"), co2 = rows("^co2"), d14prof = rows("^d14c_(profile|deep)"), d13 = rows("^d13c"),
       hs_rows = c(d13 = unname(d["hs_surf_d13c"]), dic = unname(d["hs_surf_dic"])), grad_rows = rows("^ocean_grad"), exc = unname(d["excess_c14_ocean"]),
       vel_hs = v$p$w_gthc * CCX_SV_TO_M3YR / sp$aux$a_hs$NH,     # m/yr through the SINKING cold box (like-for-like with 09-15 d: w_thc / sum a_hs)
       hs14 = vapply(HEMIS, function(h) { i <- sp$aux$idx[[h]]$hs; 1000 * (sp$y[i, "C14"] / sp$y[i, "C"] - 1) }, 0),   # the cold boxes' PI D14C (09-21: the residence-time read)
       substeps = ccx_substeps_for(v$p))
}
fmt <- function(lab, rp) sprintf("%-14s | dlik %+8.1f | D asym %+.3f z %+5.2f [NHml %+.2f NHhs %+.2f | SHml %+.2f SHhs %+.2f] | Q %.3f n_sd %.2f | hs13 %.2f/%.2f | resid %+.4f | D14 %+.2f | rows: co2 %+6.1f bomb %+5.1f d14prof %+6.1f d13 %+5.1f hs %+5.1f/%+5.1f grad %+5.1f exc %+5.1f | PI hs D14C %+.0f/%+.0f | u_hs %.0f m/yr ss %d%s",
                                lab, rp$dlik, rp$gD$asym, rp$gD$z, rp$gD$region[["NH_ml"]], rp$gD$region[["NH_hs"]], rp$gD$region[["SH_ml"]], rp$gD$region[["SH_hs"]],
                                rp$gQ$mean, rp$gQ$n_sd, rp$hs13[["NH"]], rp$hs13[["SH"]], rp$resid, rp$d14,
                                rp$co2, rp$bomb, rp$d14prof, rp$d13, rp$hs_rows[["d13"]], rp$hs_rows[["dic"]], rp$grad_rows, rp$exc, rp$hs14[["NH"]], rp$hs14[["SH"]], rp$vel_hs, rp$substeps,
                                if (is.finite(rp$spin_resid) && rp$spin_resid >= PS_TOL) sprintf(" | SPINUP NOT CONVERGED resid %.1e", rp$spin_resid) else "")

# HARNESS GATES 2/3: k inert at W = 0; the martin / no-loop D-alone printed beside the 09-15 d number
g0a <- read_point(point_p(0, 10L)); g0b <- read_point(point_p(0, 8L))
cat(sprintf("HARNESS GATE 2: k inert at W = 0 (k10 vs k8): %.2e -> %s\n", max(abs(g0a$d - g0b$d)), if (max(abs(g0a$d - g0b$d)) < 1e-9) "PASS" else "FAIL"))
cat(sprintf("HARNESS GATE 3 (printed, not asserted): martin, no loop, D-alone dlik %+.1f at %s vs %+.1f at hilda30c (09-15 d)\n\n", g0a$dlik, GP_ARM, GP_D_ALONE_0915))

# ---- stage 1: the grid -------------------------------------------------
grid1 <- expand.grid(W = GP_W, k = GP_K, kn = GP_KN); grid1 <- grid1[!(grid1$W == 0 & (grid1$k != GP_K[1] | grid1$kn != GP_KN[1])), ]   # W = 0 once
cat(sprintf("== STAGE 1: %d points ==\n", nrow(grid1)))
S1 <- vector("list", nrow(grid1)); t_all <- proc.time()[["elapsed"]]
for (i in seq_len(nrow(grid1))) {
  g1 <- grid1[i, ]; lab <- sprintf("W%-2g k%-2d kn%d", g1$W, g1$k, g1$kn)
  rp <- if (g1$W == 0) g0a else tryCatch(read_point(point_p(g1$W, g1$k, g1$kn)), error = function(e) { cat(sprintf("%-14s | FAILED: %s\n", lab, conditionMessage(e))); NULL })
  if (!is.null(rp)) { cat(fmt(lab, rp), "\n"); S1[[i]] <- rp }
}
cat(sprintf("stage 1 done in %.0f s\n\n", proc.time()[["elapsed"]] - t_all))
tab1 <- cbind(grid1, do.call(rbind, lapply(S1, function(r) if (is.null(r)) data.frame(dlik = NA, D_asym = NA, D_z = NA, SHhs = NA, NHhs = NA, Q_nsd = NA, resid = NA, d14 = NA, d14prof = NA, co2 = NA)
  else data.frame(dlik = r$dlik, D_asym = r$gD$asym, D_z = r$gD$z, SHhs = r$gD$region[["SH_hs"]], NHhs = r$gD$region[["NH_hs"]], Q_nsd = r$gQ$n_sd, resid = r$resid, d14 = r$d14, d14prof = r$d14prof, co2 = r$co2))))
print(tab1, digits = 4, row.names = FALSE)

# ---- P1-P7 from stage 1 --------------------------------------------------
cat("\n== THE PREDICTIONS (prereg s4), stage 1 ==\n")
# the scanned AXIS: k (the SH return layer) in (v)/T1, kn (the NH subduction layer) in T2; the other is fixed
AXIS <- if (GP_T2) "kn" else "k"; AXIS_VALS <- if (GP_T2) GP_KN else GP_K
at <- function(W, ax) { j <- which(tab1$W == W & tab1[[AXIS]] == (if (W == 0) AXIS_VALS[1] else ax)); if (length(j) == 1) tab1[j, ] else NULL }
b0 <- at(0, AXIS_VALS[1])
row_at <- function(s, i, ax) S1[[which(grid1$W == s$W[i] & grid1[[AXIS]] == (if (s$W[i] == 0) AXIS_VALS[1] else ax))]]
for (k in AXIS_VALS) {
  s <- tab1[tab1[[AXIS]] == k | tab1$W == 0, ]; s <- s[order(s$W), ]
  mono_SH <- all(diff(s$SHhs) < 0); p1 <- at(GP_P1_W, k)
  fall <- if (!is.null(p1)) b0$SHhs - p1$SHhs else NA; nh_move <- if (!is.null(p1)) p1$NHhs - b0$NHhs else NA
  cat(sprintf("%s%-2d P1: SH hs D by W: %s -> %s; fall at W %g = %.3f (>= %.1f: %s); NH hs D moves %+.3f (within 0.2: %s)\n", AXIS, k,
              paste(sprintf("%+.2f", s$SHhs), collapse = " "), if (mono_SH) "MONOTONE FALL" else "NOT monotone", GP_P1_W, fall,
              GP_P1_MIN_FALL, if (is.finite(fall) && fall >= GP_P1_MIN_FALL) "HOLDS" else "FAILS -> inert on its target", nh_move, if (is.finite(nh_move) && abs(nh_move) <= 0.2) "yes" else "NO"))
  cat(sprintf("%s%-2d P2: gate D z by W: %s (|z| <= 2 at: %s); SH ml D: %s (obs %+.2f)\n", AXIS, k, paste(sprintf("%+.2f", s$D_z), collapse = " "),
              { w <- s$W[abs(s$D_z) <= DG_D_NSD]; if (length(w)) paste(w, collapse = ",") else "none" },
              paste(sprintf("%+.2f", vapply(seq_len(nrow(s)), function(i) { r <- row_at(s, i, k); r$gD$region[["SH_ml"]] }, 0)), collapse = " "), do_D$region$SH_ml$mean))
  cat(sprintf("%s%-2d P3: gate Q n_sd by W: %s (falls from W0: %s)\n", AXIS, k, paste(sprintf("%.2f", s$Q_nsd), collapse = " "), if (all(diff(s$Q_nsd) < 0)) "yes, monotone" else if (any(s$Q_nsd[-1] < s$Q_nsd[1])) "at some W" else "NO"))
  cat(sprintf("%s%-2d P4: hs_surf_d13c row dlik by W: %s; hs d13C SH: %s (target 1.31)\n", AXIS, k,
              paste(sprintf("%+.1f", vapply(seq_len(nrow(s)), function(i) { r <- row_at(s, i, k); r$hs_rows[["d13"]] }, 0)), collapse = " "),
              paste(sprintf("%.2f", vapply(seq_len(nrow(s)), function(i) { r <- row_at(s, i, k); r$hs13[["SH"]] }, 0)), collapse = " ")))
  cat(sprintf("%s%-2d P5: model MLO-SPO D14C (%d-%d) by W: %s (obs %+.2f +- %.2f, NH lower); predicted to move POSITIVE: %s\n", AXIS, k, min(GP_D14C_YEARS), max(GP_D14C_YEARS),
              paste(sprintf("%+.2f", s$d14), collapse = " "), OBS_D14_MLO_SPO, OBS_D14_SD, if (all(diff(s$d14) > 0)) "yes" else "NO"))
  cat(sprintf("%s%-2d P6: d14c profile + deep rows dlik by W: %s (free, >= %g, at W: %s)\n", AXIS, k, paste(sprintf("%+.1f", s$d14prof), collapse = " "), GP_P6_FREE,
              { w <- s$W[s$W > 0 & s$d14prof - b0$d14prof >= GP_P6_FREE]; if (length(w)) paste(w, collapse = ",") else "NONE -> dies on w_thc's rock" }))
  cat(sprintf("%s%-2d P7: d13C gradient residual by W: %s (W0 %+.4f; closes 0.01-0.03 at W: %s; FULL closure would be a finding)\n\n", AXIS, k, paste(sprintf("%+.4f", s$resid), collapse = " "), b0$resid,
              { dr <- s$resid - b0$resid; w <- s$W[s$W > 0 & dr >= 0.01 & dr <= 0.03]; if (length(w)) paste(w, collapse = ",") else "none" }))
}

# ---- stage 2: arm C at the best raw point per k, and at W = 0 ------------
cat("== STAGE 2: arm C re-optimisation ==\n")
rm_pins <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm_pins), add = TRUE)
bp0 <- ccx_mode_base(md); bp0$pump_mode <- md$pump_mode
st <- ccx_mode_start(md, "gthc_probe"); pm0 <- st$p
lp_solved <- ccx_make_logpost(base_params = bp0, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
v_s <- lp_solved(st$u); ref_st <- attr(v_s, "streams")
cat(sprintf("HARNESS GATE 4: rebuilt logpost %.4f (shift %+.4f) vs stored %.4f -> %s\n", as.numeric(v_s) - st$logpost_shift, st$logpost_shift, md$logpost,
            if (abs(as.numeric(v_s) - st$logpost_shift - md$logpost) < GP_GATE_TOL) "PASS" else "FAIL"))
if (abs(as.numeric(v_s) - st$logpost_shift - md$logpost) >= GP_GATE_TOL) stop("harness gate 4 failed")
ccx_unpin_params(rm_pins); rm_pins <- list()
reopt_point <- function(W, k, kn = 0L) {
  pins <- ccx_mode_pins(md)   # the canonical's own: the six inert names + the shim pair at 0 (w_thc, w_vent, gamma_vent among them)
  rm <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rm), add = TRUE)
  bp <- bp0; for (n in names(pins)) bp[[n]] <- pins[[n]]
  bp$pump_field <- "martin"; bp$w_gthc <- W; bp$k_gthc <- k; bp$kn_gthc <- kn   # STRUCTURAL: on the base list, never in u
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
  pm <- pm0[setdiff(names(pm0), names(pins))]
  u <- ccx_par_to_unc(pm); stopifnot(all(is.finite(u)))
  idx <- match(GP_ARMC, CCX_PARAM_NAMES); stopifnot(!any(is.na(idx)))
  fobj <- function(z) { uu <- u; uu[idx] <- z; x <- -as.numeric(lp(uu)); if (!is.finite(x)) 1e10 else x }
  v_raw <- lp(u)
  o1 <- stats::optim(u[idx], fobj, method = "Nelder-Mead", control = list(maxit = GP_NM_MAXIT, reltol = 1e-10))
  o2 <- stats::optim(o1$par, fobj, method = "BFGS", control = list(maxit = GP_BFGS_MAXIT, reltol = 1e-12))
  best <- if (o2$value < o1$value) o2 else o1; uu <- u; uu[idx] <- best$par
  v <- lp(uu); pmb <- ccx_unc_to_par(uu)
  st_raw <- attr(v_raw, "streams"); st_c <- attr(v, "streams"); cm <- intersect(names(st_c), names(ref_st))
  list(W = W, k = k, kn = kn, pm = pmb, dlik_raw = sum(st_raw[cm] - ref_st[cm]), dlik = sum(st_c[cm] - ref_st[cm]),
       d = st_c[cm] - ref_st[cm], n_eval = o1$counts[1] + o2$counts[1],
       read = { vv <- point_p(W, k, kn); for (n in names(pmb)) if (n %in% names(vv$p)) vv$p[[n]] <- pmb[[n]]
                for (n in c("luc_scale", "bomb_total", "sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c")) if (!is.null(pmb[[n]])) vv[[n]] <- pmb[[n]]
                read_point(vv) })
}
sel <- data.frame(W = 0, k = GP_K[1], dlik_raw = b0$dlik)
sel$kn <- GP_KN[1]
if (GP_T1) { s <- tab1[tab1$W > 0 & is.finite(tab1$dlik), ]; sel <- rbind(sel, data.frame(W = s$W, k = s$k, dlik_raw = s$dlik, kn = s$kn)) } else
for (k in GP_K) { s <- tab1[tab1$k == k & tab1$W > 0 & is.finite(tab1$dlik), ]; if (nrow(s)) { b <- s[which.max(s$dlik), ]; sel <- rbind(sel, data.frame(W = b$W, k = k, dlik_raw = b$dlik, kn = b$kn)) } }
cat("selected for arm C (W = 0; the best raw W per k):\n"); print(sel, row.names = FALSE)
S2 <- list()
for (i in seq_len(nrow(sel))) {
  s <- sel[i, ]; t0 <- proc.time()[["elapsed"]]
  r2 <- tryCatch(reopt_point(s$W, s$k, s$kn), error = function(e) { cat(sprintf("armC W%g k%d kn%d FAILED: %s\n", s$W, s$k, s$kn, conditionMessage(e))); NULL })
  if (is.null(r2)) next
  S2[[i]] <- r2
  cat(sprintf("armC W%-2g k%-2d kn%d: raw %+8.1f -> armC %+8.1f (%d evals; kz_deep_frac %.4f h_ml %.1f k_w %.0f bomb_total %.1f sigma_d14c %.2f q10 %.2f%s) [%.0f s]\n  %s\n",
              s$W, s$k, s$kn, r2$dlik_raw, r2$dlik, r2$n_eval, r2$pm$kz_deep_frac, r2$pm$h_ml, r2$pm$k_w, r2$pm$bomb_total, r2$pm$sigma_d14c, r2$pm$q10,
              if (GP_T1) sprintf("; u_hs %.1f pump_hs %.1f h_hs %.0f", r2$pm$u_hs, r2$pm$pump_hs_gcm2, r2$pm$h_hs) else "", proc.time()[["elapsed"]] - t0,
              fmt("", r2$read)))
  cat(sprintf("        largest rows: %s\n", paste(sprintf("%s %+.1f", names(sort(r2$d))[1:5], sort(r2$d)[1:5]), collapse = ", ")))
}

# ---- THE REJECT RULE (prereg s4) ------------------------------------------
cat("\n== THE REJECT RULE: promote to the refit tier only if at ONE W: P1 (SH hs D falls >= 0.3 at W 15), P2-direction (|z| < 6.60), P3 (n_sd < 3.15), P6 free (profile rows within -10 of W 0) ==\n")
verdict <- NULL
for (i in seq_len(nrow(grid1))) { r <- S1[[i]]; if (is.null(r) || grid1$W[i] == 0) next
  k <- grid1[[AXIS]][i]; p1 <- at(GP_P1_W, k); p1_ok <- !is.null(p1) && (b0$SHhs - p1$SHhs) >= GP_P1_MIN_FALL
  verdict <- rbind(verdict, data.frame(W = grid1$W[i], k = grid1$k[i], kn = grid1$kn[i], D_z = r$gD$z, Q_nsd = r$gQ$n_sd, d14prof = r$d14prof - b0$d14prof,
                                       P1 = p1_ok, P2 = abs(r$gD$z) < abs(gD_ref$z), P3 = r$gQ$n_sd < gQ_ref$n_sd, P6 = (r$d14prof - b0$d14prof) >= GP_P6_FREE)) }
verdict$PASS <- verdict$P1 & verdict$P2 & verdict$P3 & verdict$P6
print(verdict, digits = 3, row.names = FALSE)
pass <- verdict[verdict$PASS, ]
cat(sprintf("\nVERDICT: %s\n", if (!nrow(pass)) "NO W passes P1 + P2 + P3 + P6: the loop is RECORDED AND PARKED like w_thc (the arm-C price above)."
                               else sprintf("%d point(s) pass: %s -> the REFIT tier (a second prereg; nothing adopted here)", nrow(pass), paste(sprintf("W%g k%d (z %+.2f)", pass$W, pass$k, pass$D_z), collapse = "; "))))
saveRDS(list(grid = grid1, S1 = S1, tab1 = tab1, sel = sel, S2 = S2, verdict = verdict, ref = ref, ref_st = ref_st, gD_ref = gD_ref, gQ_ref = gQ_ref,
             export = GP_EXPORT, W = GP_W, k = GP_K, armc = GP_ARMC, canonical = GP_ARM, md_logpost = md$logpost, obs_d14_mlo_spo = c(mean = OBS_D14_MLO_SPO, sd = OBS_D14_SD),
             provenance = list(commit = GP_COMMIT, built = format(Sys.time()), seed = "none (deterministic; no RNG on any path)", mode_file = ccx_mode_file(GP_ARM))), paste0(GP_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n", GP_OUT))
