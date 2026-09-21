# =====================================================================
# diag_tau_iso_overdetermined.R -- IS THE AIR-SEA ISOTOPIC TIMESCALE MEASURED
# TWICE, 15 % APART? (handoff 09-21 (d) s3 / (e) s6.4: "the tau_iso diagnostic
# -- bomb_total vs k_w on a D row; the only quantitative loose end").
#
#   THE CLAIM (09-21 d): a symmetric k_w x0.85 puts BOTH mixed-layer air-sea
#   d13C disequilibria D on the GLODAP bottles (NH +1.17 vs obs +1.28, SH +1.04
#   vs +1.05) at -552 on d14c_NH / d13c_level_MLO / d14c_SH -- so gate D's ML
#   LEVEL says tau_iso = h (DIC/CO2*) / k_w is ~15 % too short while the
#   bomb-D14C rows, with bomb_total FITTED beside them, say it is right.
#   THE QUESTION: is the bomb rows' -552 a measurement of k_w, or of
#   (k_w, bomb_total) jointly -- i.e. how much of it does bomb_total absorb when
#   it is re-optimised at each k_w, and how much does the rest of the standard
#   nuisance arm absorb? And what weight would a D row need to move the joint
#   optimum?
#
#   Axis: k_w x TI_FAC on the canonical (hilda29l), C++ objective under the
#   file's pins, PLUS k_w pinned at the scaled value (a pin holds a fitted name;
#   the k_w prior leaves the objective with it -- every read is on LIKELIHOOD).
#   Stage 1  RAW: everything else fixed. Per point the 26-row dlik vs the
#            canonical with the named rows, the four regional D's, gate D z,
#            the model's OWN tau_iso (ML carbon / gross invasion at PI).
#   Stage 2  PROFILES: at each k_w, re-optimise (a) bomb_total alone, (b)
#            bomb_total + sigma_d14c, (c) the standard nuisance arm minus k_w
#            {beta_max, fert_k, q10, kz_deep_frac, h_ml, bomb_total, sigma_d14c}
#            (arm C of the 09-20/21 probes without the axis name; h_ml is IN it
#            because it is the other half of tau_iso -- the effective tau_iso
#            at the re-optimum is read, not assumed).
#   Stage 3  THE D ROW's PULL: a pseudo-row -1/2 sum_h ((D_ml,h - obs_h)/sigma)^2
#            on the two ML levels, at sigma = the bottles' cluster se (0.02)
#            and a ladder of representation errors; the JOINT optimum of
#            (profile c + D row) along the axis, per sigma, by quadratic fit
#            (the fit's max residual printed beside it -- a curvature needs its
#            error bar) and by the finer spline. The crossing: the sigma at
#            which the joint optimum reaches halfway to x0.85.
#   No reject rule; nothing adopted. A diagnostic of a tension, read into the
#   assessment's option-(C) statement.
# Usage: Rscript calibration/diag_tau_iso_overdetermined.R   (TI_SMOKE=1: 3 points, short optim)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
TI_ARM     <- CCX_MODE_CANONICAL
TI_FAC     <- c(0.75, 0.80, 0.85, 0.90, 0.95, 1.00, 1.05, 1.10, 1.15)   # k_w x fac; 0.85 = the 09-21 d point
TI_FAC_TARGET <- 0.85                                                   # where gate D's ML levels want k_w (09-21 d)
TI_SETS    <- list(bomb     = "bomb_total",
                   bomb_sig = c("bomb_total", "sigma_d14c"),
                   armC     = c("beta_max", "fert_k", "q10", "kz_deep_frac", "h_ml", "bomb_total", "sigma_d14c"))
TI_SIGMA_D <- c(0.02, 0.05, 0.10, 0.15, 0.20, 0.30, 0.50)             # the D row's sigma ladder: 0.02 ~ the bottles' cluster se; the rest representation error
TI_NM_MAXIT <- 1500; TI_BFGS_MAXIT <- 100
TI_GATE_TOL <- 1e-4
TI_SMOKE   <- nzchar(Sys.getenv("TI_SMOKE", ""))
if (TI_SMOKE) { TI_FAC <- c(0.85, 1.00, 1.15); TI_NM_MAXIT <- 20; TI_BFGS_MAXIT <- 5; TI_SETS <- TI_SETS[c("bomb", "armC")] }
TI_OUT     <- ccx_path("outputs", "diagnostics", sprintf("tau_iso_overdetermined_%s%s", format(Sys.Date(), "%Y%m%d"), if (TI_SMOKE) "_smoke" else ""))
sink_log <- file(paste0(TI_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)
TI_COMMIT <- if (file.exists("FROZEN_FROM_COMMIT.txt")) substr(trimws(readLines("FROZEN_FROM_COMMIT.txt")[1]), 1, 7) else
             tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")
cat(sprintf("== TAU_ISO OVER-DETERMINED? k_w x %s at %s -- commit %s, %s ==\n", paste(TI_FAC, collapse = "/"), TI_ARM, TI_COMMIT, format(Sys.time())))
cat(sprintf("profile sets: %s\n\n", paste(sprintf("%s = {%s}", names(TI_SETS), vapply(TI_SETS, paste, "", collapse = ",")), collapse = "; ")))

# ---- the observations the reads use (READ, never typed) ---------------
obs <- ccx_prepare_obs(); do_D <- dg_gateD_obs()
OBS_D <- c(NH = do_D$region$NH_ml$mean, SH = do_D$region$SH_ml$mean)
OBS_D_SE <- c(NH = do_D$region$NH_ml$se, SH = do_D$region$SH_ml$se)
cat(sprintf("obs: ML D levels NH %+.3f +- %.3f (n_bottles %d, clusters %d), SH %+.3f +- %.3f (%d, %d); gate D asym %+.3f +- %.3f\n\n",
            OBS_D[["NH"]], OBS_D_SE[["NH"]], do_D$region$NH_ml$n_bottles, do_D$region$NH_ml$n_clusters,
            OBS_D[["SH"]], OBS_D_SE[["SH"]], do_D$region$SH_ml$n_bottles, do_D$region$SH_ml$n_clusters, do_D$asym, do_D$asym_se))

# ---- stage 1 machinery: the dg path (p directly; exact zeros) ----------
v0 <- dg_vector(TI_ARM); md <- v0$md; KW0 <- v0$p$k_w
r_ref <- dg_run(v0); ref <- unlist(dg_streams(r_ref, v0))
cat(sprintf("HARNESS GATE 1: dg streams at the canonical vs stored: sum %.4f vs %.4f -> %s\n", sum(ref[names(md$streams)]), sum(md$streams),
            if (abs(sum(ref[names(md$streams)]) - sum(md$streams)) < TI_GATE_TOL) "PASS" else "FAIL"))
if (abs(sum(ref[names(md$streams)]) - sum(md$streams)) >= TI_GATE_TOL) stop("harness gate 1 failed")
gD_ref <- dg_gateD_verdict(dg_gateD(r_ref, v0))
# THE MODEL'S OWN tau_iso: the mixed layer's ANNUAL-MEAN carbon over its gross
# invasion at the PI atmosphere (the isotopic e-folding: an isotope anomaly
# relaxes at the GROSS rate, the CO2 anomaly at gross / (DIC/CO2*) -- the
# Revelle-free one). gx = asx k_w K0 [GtC/yr/ppm] is exactly the model's
# invasion coefficient; the carbon is aux$ml_mass_kg (the MEAN thickness) x the
# spinup's ML DIC. ⚠ The first cut read sp$y's ML carbon, which under the
# periodic spinup is the JANUARY state -- NH winter-deep, SH summer-shallow --
# and printed a 2x hemispheric asymmetry (6.95 / 3.40 yr) that was the phase,
# not the timescale (the 12:12 run's log). The area cancels: tau = h DIC / (k_w K0 pCO2).
tau_iso <- function(sp, kw) {
  aux <- sp$aux; pco2 <- ccx_const("CO2_PI_PPM")
  vapply(HEMIS, function(h) {
    C_ml <- aux$ml_mass_kg[[h]] * aux$dic0[[h]] / aux$mol_per_GtC; K0 <- carb_constants(aux$sst[[h]])$K0
    C_ml / (aux$asx[[h]] * kw * K0 * pco2) }, 0)
}
tau0 <- tau_iso(r_ref$sp, KW0)
cat(sprintf("canonical: k_w %.1f m/yr, h_ml %.2f m; tau_iso NH %.2f yr, SH %.2f yr (ML carbon / gross PI invasion); ML D NH %+.3f SH %+.3f (obs %+.3f / %+.3f); gate D z %+.2f; bomb_total %.1f, sigma_d14c %.2f\n\n",
            KW0, v0$p$h_ml, tau0[["NH"]], tau0[["SH"]], gD_ref$region[["NH_ml"]], gD_ref$region[["SH_ml"]], OBS_D[["NH"]], OBS_D[["SH"]], gD_ref$z, v0$bomb_total, v0$sigma_d14c))
point_v <- function(fac, pm = NULL) {   # the canonical's vector with k_w scaled; pm overlays a re-optimised nuisance set
  v <- v0; v$p$k_w <- KW0 * fac
  if (!is.null(pm)) { for (n in names(pm)) if (n %in% names(v$p)) v$p[[n]] <- pm[[n]]
                      for (n in c("luc_scale", "bomb_total", "sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c")) if (!is.null(pm[[n]])) v[[n]] <- pm[[n]]
                      v$p$k_w <- KW0 * fac }   # the axis is never overlaid
  v
}
read_point <- function(v) {
  r <- dg_run(v); out <- r$out
  stv <- unlist(dg_streams(r, v)); cm <- intersect(names(stv), names(ref)); d <- stv[cm] - ref[cm]
  gD <- dg_gateD_verdict(dg_gateD(r, v)); rows <- function(pat) sum(d[grep(pat, cm)])
  list(d = d, dlik = sum(d), gD = gD, D = c(NH = gD$region[["NH_ml"]], SH = gD$region[["SH_ml"]]),
       tau = tau_iso(r$sp, v$p$k_w), h_ml = v$p$h_ml, k_w = v$p$k_w, bomb_total = v$bomb_total, sigma_d14c = v$sigma_d14c,
       bomb = rows("^d14c_(NH|SH)$"), d13lev = rows("^d13c_level"), co2 = rows("^co2"), d14prof = rows("^d14c_(profile|deep|intcal)"), seas = rows("seasonal"),
       spin_resid = if (!is.null(r$sp$periodic)) r$sp$periodic$resid_carbon else NA_real_)
}
fmt <- function(lab, rp) sprintf("%-16s | dlik %+8.1f | ML D NH %+.3f SH %+.3f (z %+5.1f %+5.1f) | gate D z %+5.2f | tau_iso %.2f/%.2f yr | h_ml %.1f k_w %.0f bomb %.1f sig14 %.2f | rows: bomb %+6.1f d13lev %+6.1f co2 %+6.1f d14prof %+6.1f seas %+6.1f%s",
                                lab, rp$dlik, rp$D[["NH"]], rp$D[["SH"]], (rp$D[["NH"]] - OBS_D[["NH"]]) / OBS_D_SE[["NH"]], (rp$D[["SH"]] - OBS_D[["SH"]]) / OBS_D_SE[["SH"]],
                                rp$gD$z, rp$tau[["NH"]], rp$tau[["SH"]], rp$h_ml, rp$k_w, rp$bomb_total, rp$sigma_d14c, rp$bomb, rp$d13lev, rp$co2, rp$d14prof, rp$seas,
                                if (is.finite(rp$spin_resid) && rp$spin_resid >= PS_TOL) sprintf(" | SPINUP NOT CONVERGED %.1e", rp$spin_resid) else "")
g0 <- read_point(point_v(1))
cat(sprintf("HARNESS GATE 2: k_w x1 reproduces the canonical: dlik %+.2e -> %s\n\n", g0$dlik, if (abs(g0$dlik) < 1e-6) "PASS" else "FAIL"))
if (abs(g0$dlik) >= 1e-6) stop("harness gate 2 failed")

# ---- stage 1: RAW ------------------------------------------------------
cat(sprintf("== STAGE 1 RAW: k_w x %s, everything else fixed ==\n", paste(TI_FAC, collapse = "/")))
S1 <- lapply(TI_FAC, function(fac) { rp <- if (fac == 1) g0 else read_point(point_v(fac)); cat(fmt(sprintf("raw x%.2f", fac), rp), "\n"); rp })
names(S1) <- as.character(TI_FAC)

# ---- stage 2: PROFILES over the nuisance sets ----------------------------
cat("\n== STAGE 2 PROFILES: k_w PINNED at the scaled value, the set re-optimised (logpost; reads on likelihood) ==\n")
rm_pins <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm_pins), add = TRUE)
bp0 <- ccx_mode_base(md); bp0$pump_mode <- md$pump_mode
st <- ccx_mode_start(md, "tau_iso"); pm0 <- st$p
lp0 <- ccx_make_logpost(base_params = bp0, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
v_s <- lp0(st$u); ref_st <- attr(v_s, "streams")
cat(sprintf("HARNESS GATE 3: rebuilt logpost %.4f (shift %+.4f) vs stored %.4f -> %s\n", as.numeric(v_s) - st$logpost_shift, st$logpost_shift, md$logpost,
            if (abs(as.numeric(v_s) - st$logpost_shift - md$logpost) < TI_GATE_TOL) "PASS" else "FAIL"))
if (abs(as.numeric(v_s) - st$logpost_shift - md$logpost) >= TI_GATE_TOL) stop("harness gate 3 failed")
ccx_unpin_params(rm_pins); rm_pins <- list()
profile_point <- function(fac, set) {
  pins <- c(ccx_mode_pins(md), k_w = KW0 * fac)          # the file's own pins + the AXIS as a pin (a pin holds a fitted name)
  rm <- ccx_apply_pins(pins); on.exit(ccx_unpin_params(rm), add = TRUE)
  bp <- bp0; for (n in names(pins)) bp[[n]] <- pins[[n]]
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
  pm <- pm0[setdiff(names(pm0), names(pins))]
  u <- ccx_par_to_unc(pm); stopifnot(all(is.finite(u)))
  idx <- match(set, CCX_PARAM_NAMES); stopifnot(!any(is.na(idx)))
  fobj <- function(z) { uu <- u; uu[idx] <- z; x <- -as.numeric(lp(uu)); if (!is.finite(x)) 1e10 else x }
  if (length(idx) == 1L) {   # 1-D: Brent over a wide bracket in unc (log) space, then polish
    o1 <- stats::optim(u[idx], fobj, method = "Brent", lower = u[idx] - 2, upper = u[idx] + 2, control = list(reltol = 1e-12))
    best <- o1; n_eval <- o1$counts[1]
  } else {
    o1 <- stats::optim(u[idx], fobj, method = "Nelder-Mead", control = list(maxit = TI_NM_MAXIT, reltol = 1e-10))
    o2 <- stats::optim(o1$par, fobj, method = "BFGS", control = list(maxit = TI_BFGS_MAXIT, reltol = 1e-12))
    best <- if (o2$value < o1$value) o2 else o1; n_eval <- o1$counts[1] + o2$counts[1]
  }
  uu <- u; uu[idx] <- best$par; v <- lp(uu); pmb <- ccx_unc_to_par(uu)
  st_c <- attr(v, "streams"); cm <- intersect(names(st_c), names(ref_st))
  list(fac = fac, set = set, pm = pmb, dlik = sum(st_c[cm] - ref_st[cm]), d = st_c[cm] - ref_st[cm], n_eval = n_eval,
       read = read_point(point_v(fac, pmb)))
}
S2 <- list()
for (sn in names(TI_SETS)) {
  cat(sprintf("-- set %s = {%s} --\n", sn, paste(TI_SETS[[sn]], collapse = ", ")))
  S2[[sn]] <- lapply(TI_FAC, function(fac) {
    t0 <- proc.time()[["elapsed"]]
    r2 <- tryCatch(profile_point(fac, TI_SETS[[sn]]), error = function(e) { cat(sprintf("%s x%.2f FAILED: %s\n", sn, fac, conditionMessage(e))); NULL })
    if (!is.null(r2)) cat(sprintf("%s [%s evals, %.0f s]\n    largest rows: %s\n", fmt(sprintf("%s x%.2f", sn, fac), r2$read), format(r2$n_eval), proc.time()[["elapsed"]] - t0,
                                  paste(sprintf("%s %+.1f", names(sort(r2$d))[1:4], sort(r2$d)[1:4]), collapse = ", ")))
    r2 })
  names(S2[[sn]]) <- as.character(TI_FAC)
}

# ---- the table ---------------------------------------------------------
tab <- do.call(rbind, lapply(TI_FAC, function(fac) {
  f <- as.character(fac); row <- data.frame(fac = fac, raw = S1[[f]]$dlik, raw_bomb = S1[[f]]$bomb, raw_d13lev = S1[[f]]$d13lev,
                                            D_NH = S1[[f]]$D[["NH"]], D_SH = S1[[f]]$D[["SH"]], tau_NH = S1[[f]]$tau[["NH"]])
  for (sn in names(S2)) { r2 <- S2[[sn]][[f]]
    row[[sn]] <- if (is.null(r2)) NA else r2$dlik
    row[[paste0(sn, "_D_NH")]] <- if (is.null(r2)) NA else r2$read$D[["NH"]]
    row[[paste0(sn, "_bomb")]] <- if (is.null(r2)) NA else r2$read$bomb_total
    if ("h_ml" %in% TI_SETS[[sn]]) { row[[paste0(sn, "_h_ml")]] <- if (is.null(r2)) NA else r2$read$h_ml; row[[paste0(sn, "_tau_NH")]] <- if (is.null(r2)) NA else r2$read$tau[["NH"]] }
  }
  row }))
cat("\n== THE TABLE (dlik vs the canonical, likelihood; D = the ML air-sea d13C disequilibrium; tau in yr) ==\n"); print(tab, digits = 4, row.names = FALSE)

# ---- the decomposition at the target: who pays for the longer tau_iso? --------
ft <- as.character(TI_FAC_TARGET)
if (ft %in% names(S1)) {
  cat(sprintf("\n== AT k_w x%.2f (where the ML D levels sit on the bottles): the price and WHO PAYS IT ==\n", TI_FAC_TARGET))
  line <- function(lab, rp, d) cat(sprintf("  %-10s dlik %+7.1f | bomb rows %+7.1f | d13c level rows %+7.1f | co2 rows %+6.1f | other %+6.1f | top: %s\n", lab, rp$dlik, rp$bomb, rp$d13lev, rp$co2,
                                             rp$dlik - rp$bomb - rp$d13lev - rp$co2, paste(sprintf("%s %+.1f", names(sort(d))[1:3], sort(d)[1:3]), collapse = ", ")))
  line("raw", S1[[ft]], S1[[ft]]$d)
  for (sn in names(S2)) if (!is.null(S2[[sn]][[ft]])) line(sn, S2[[sn]][[ft]]$read, S2[[sn]][[ft]]$d)
}

# ---- stage 3: the D row's pull and the joint optimum -----------------------
cat("\n== STAGE 3: the D row's pull (both ML levels; sigma ladder) on the deepest profile ==\n")
deep <- names(S2)[length(S2)]
prof <- vapply(TI_FAC, function(fac) { r2 <- S2[[deep]][[as.character(fac)]]; if (is.null(r2)) NA_real_ else r2$dlik }, 0)
Dm   <- t(vapply(TI_FAC, function(fac) { r2 <- S2[[deep]][[as.character(fac)]]; if (is.null(r2)) c(NA_real_, NA_real_) else r2$read$D }, c(0, 0)))
lf <- log(TI_FAC); ok <- is.finite(prof)
quad_opt <- function(y) {   # argmax of a quadratic in log(fac); returns (fac*, curvature, max |resid|)
  q <- stats::lm(y ~ lf + I(lf^2), subset = ok); b <- unname(coef(q))
  c(fac = if (is.finite(b[3]) && b[3] < 0) exp(-b[2] / (2 * b[3])) else NA_real_, curv = b[3], resid = max(abs(residuals(q))))
}
spl_opt <- function(y) { s <- stats::splinefun(lf[ok], y[ok], method = "natural"); g <- seq(min(lf), max(lf), length.out = 2001); exp(g[which.max(s(g))]) }
qb <- quad_opt(prof)
cat(sprintf("the %s profile alone: quadratic optimum k_w x%.3f (curvature %.0f per ln^2, max |resid| %.1f), spline optimum x%.3f\n", deep, qb[["fac"]], qb[["curv"]], qb[["resid"]], spl_opt(prof)))
cat(sprintf("  (the raw scan's optimum: quadratic x%.3f, spline x%.3f)\n", quad_opt(vapply(S1, `[[`, 0, "dlik"))[["fac"]], spl_opt(vapply(S1, `[[`, 0, "dlik"))))
joint <- do.call(rbind, lapply(TI_SIGMA_D, function(sg) {
  Lrow <- -0.5 * ((Dm[, 1] - OBS_D[["NH"]])^2 + (Dm[, 2] - OBS_D[["SH"]])^2) / sg^2
  y <- prof + Lrow; q <- quad_opt(y)
  data.frame(sigma_D = sg, row_at_x1 = Lrow[TI_FAC == 1], row_at_target = Lrow[TI_FAC == TI_FAC_TARGET], joint_quad = q[["fac"]], joint_spline = spl_opt(y), quad_resid = q[["resid"]])
}))
cat("\njoint optimum of (profile + D row) along k_w, per sigma_D:\n"); print(joint, digits = 4, row.names = FALSE)
half <- sqrt(TI_FAC_TARGET)   # halfway to the target in log space
cross <- if (any(is.finite(joint$joint_spline))) { j <- joint[is.finite(joint$joint_spline), ]
  if (any(j$joint_spline <= half) && any(j$joint_spline > half)) exp(stats::approx(log(j$joint_spline), log(j$sigma_D), xout = log(half))$y) else NA } else NA
cat(sprintf("\nTHE CROSSING: the D row moves the joint optimum halfway to x%.2f (i.e. to x%.3f) at sigma_D ~ %s\n", TI_FAC_TARGET, half,
            if (is.finite(cross)) sprintf("%.3f permil", cross) else "outside the ladder"))
cat(sprintf("the bottles' own cluster se is %.3f / %.3f; the D row at that se, x1: %.0f, at x%.2f: %.0f (a pull of %+.0f)\n",
            OBS_D_SE[["NH"]], OBS_D_SE[["SH"]], joint$row_at_x1[1], TI_FAC_TARGET, joint$row_at_target[1], joint$row_at_target[1] - joint$row_at_x1[1]))

saveRDS(list(fac = TI_FAC, S1 = S1, S2 = S2, tab = tab, joint = joint, cross = cross, ref = ref, ref_st = ref_st, gD_ref = gD_ref, tau0 = tau0, KW0 = KW0,
             obs_D = OBS_D, obs_D_se = OBS_D_SE, sets = TI_SETS, sigma_D = TI_SIGMA_D, canonical = TI_ARM, md_logpost = md$logpost,
             provenance = list(commit = TI_COMMIT, built = format(Sys.time()), seed = "none (deterministic; no RNG on any path)", mode_file = ccx_mode_file(TI_ARM),
                               objective = "C++ logpost under the file's pins + k_w pinned at KW0 x fac; reads on likelihood streams")), paste0(TI_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n", TI_OUT))
