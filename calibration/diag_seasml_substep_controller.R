# =====================================================================
# diag_seasml_substep_controller.R -- WHY START 017's OBJECTIVE IS NON-SMOOTH (2026-10-03, CHANGELOG 10-03 j)
#
# THE QUESTION (CHANGELOG 10-03 e). The objective-#15 lag arm's start 017, resumed, stalled at logpost
# -1306.89 (124 below the mode). There a step of 0.1 x the mode's conditional sd moves
#   kz +: co2_seasonal_SPO -248.8   kz_deep_frac +: -250.3   h_ml +: d13c_seasonal_SPO -2.0e37
# while the opposite steps are smooth. Candidates named there, UNTESTED: a clip on the SH mixed-layer
# depth; a periodic spinup converging to a different cycle; a substep-count switch; a d13C ratio over a
# near-empty box.
#
# WHAT THIS DRIVER TESTS, in order:
#   0. both vectors reproduce their stored logposts (or nothing below can be read off them);
#   1. CONVERGENCE UNDER REFINEMENT: the objective at the point, its six steps and the mode, at 1, 2, 4,
#      8, 16 x the controller's substep count. Forced through ccx_substeps_for(), so the periodic
#      spinup's one-year map and the transient run at the SAME count -- every number is a consistent
#      evaluation (the 09-16 d mixed-count trap does not arise);
#   2. THE ANATOMY: the stiffness the integrator really meets -- its own diffusion Jacobian (the
#      dzl / dzml / dz1_eff of src/ccx_core.cpp, the held per-interface K = aux$kz_int) on a fine time
#      grid -- against what ccx_substeps_for() assumed, decomposed into its two departures;
#   3. THE EDGE: the same comparison along h_ml, at the mode's and at 017's other values;
#   4. WHO IS IN IT: every registered mode, every start file of every seas_ml = 1 wave, the MCMC
#      stage-1 draws (hilda33d) and Laplace draws about hilda34g;
#   5. A CANDIDATE FIX, PRICED IN-PROCESS ONLY (R/ is not touched; the objective is Marcus's to change):
#      the controller at the interpolant's CONTINUOUS extremes (what ccx_seas_ml_guard() reads) with
#      the HELD annual-mean K profile (what the integrator uses), plus a STOP where the needed count
#      exceeds CCX_SUBSTEPS_MAX instead of a silent clamp;
#   6. the straight line 017 -> mode, re-read on the converged objective.
#
# Run from the repo root, BLAS pinned:  VECLIB_MAXIMUM_THREADS=1 nice -n 10 Rscript calibration/diag_seasml_substep_controller.R
# Writes outputs/diagnostics/seasml_substep_controller_<date>.{log,rds}; the rds first, then the prose.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
SC_DRIVER     <- "calibration/diag_seasml_substep_controller.R"
SC_MODE_KEY   <- "hilda34g"                       # the canonical = the #15 lag arm (10-03 h)
SC_LABEL      <- "hilda_csl3v0kaidgbe"
SC_WAVE_TAIL  <- paste0("_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0",
                        "_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452_sdby_npp_tsens=0.0291")
SC_STUCK_ID   <- 17L
SC_STUCK_FILE <- file.path("calibration", "output", paste0("resume017_20261003_", SC_LABEL, SC_WAVE_TAIL),
                           sprintf("start_%03d.rds", SC_STUCK_ID))
SC_STEP_FRAC  <- 0.1                              # = diag_obj15_refit_read.R's RD_GRAD_FRAC (conditional sds)
SC_SMOOTH_TOL <- 1                                # = its RD_SMOOTH_TOL: |d_up + d_dn| past this is NON-SMOOTH
SC_DIRS       <- c("h_ml", "kz", "kz_deep_frac")  # the three directions 10-03 (e) flagged
SC_MULTS      <- c(1L, 2L, 4L, 8L, 16L)           # x the controller's own substep count
SC_CONV_TOL   <- SC_SMOOTH_TOL / 100              # |lp(x8) - lp(x16)| below this = converged: 100x under the
                                                  #   smoothness flag's own scale, so refinement residue can
                                                  #   neither create nor hide a flag
SC_REPRO_TOL  <- 1e-6                             # log-units: a vector reproduces its stored logpost
SC_LIMIT      <- CCX_RK4_STAB_LIMIT               # RK4 on the negative real axis (R/model.R)
SC_TARGET     <- CCX_STAB_SAFETY * CCX_RK4_STAB_LIMIT   # what the controller aims at
SC_NT         <- CCX_MLD_FINE_GRID                # time samples per year: the grid the guard's extremes come from
SC_HML_SCAN   <- c(seq(60, 72, by = 1), seq(72.5, 75, by = 0.25), seq(75.1, 75.5, by = 0.1))
SC_MC_N       <- 20000L                           # Laplace draws about the mode, per width
SC_MC_WIDTHS  <- c(1, 2)                          # x the Laplace covariance's sds (the MCMC found it ~2x TOO WIDE,
                                                  #   10-02 t; 2x is a deliberately far tail)
SC_MC_SEED    <- 20261003L
SC_MCMC_POOLED <- file.path("outputs", "mcmc_check", "pooled_u.rds")   # hilda33d stage 1 (10-02 v)
SC_MCMC_KEY   <- "hilda33d"
SC_ARTEFACT_Z_CTRL <- 2                         # a SELECTION, not a gate: stable start points with z above this (within
                                                  #   ~30 % of the limit) are re-scored in 4(e) as the near-limit control
SC_LINE_T     <- seq(0, 1, by = 0.05)             # = the read's RD_LINE_T
SC_LINE_MULT  <- 4L                               # the straight line, re-read at this refinement
SC_BLOWUP_D13C <- 100                             # permil: |d13c_SH| past this marks the blow-up's first year
SC_TAG  <- format(Sys.Date(), "%Y%m%d")
SC_OUT  <- file.path("outputs", "diagnostics", sprintf("seasml_substep_controller_%s", SC_TAG))
COMMIT  <- ccx_git_stamp()
PROV <- list(driver = SC_DRIVER, commit = COMMIT, date = format(Sys.time(), "%Y-%m-%d %H:%M %Z"),
             host = Sys.info()[["nodename"]], r = R.version.string,
             blas_threads = Sys.getenv("VECLIB_MAXIMUM_THREADS", "(unset)"),
             mode = ccx_mode_file(SC_MODE_KEY), stuck = SC_STUCK_FILE, mcmc = SC_MCMC_POOLED,
             objective = "#15 (LIK_USE_ICE_D13C, ice CO2 to 1958); periodic spinup per each mode's own record",
             seed = SC_MC_SEED, seed_applied = "set.seed() immediately before each Laplace width's mvn draw (section 4d)",
             units = "logpost in log-units; stiffness rho / lambda in 1/yr; z = (1/12)/substeps x rho; depths in m")
stopifnot(isTRUE(LIK_USE_ICE_D13C), identical(LIK_ICE_CO2_END, 1958))      # objective #15
if (!file.exists(SC_STUCK_FILE)) stop("the resumed start file is missing: ", SC_STUCK_FILE)
sink(paste0(SC_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s on %s (BLAS threads %s)\n", SC_DRIVER, COMMIT, PROV$date, PROV$host, PROV$blas_threads))
OUT <- list(provenance = PROV)
save_out <- function() saveRDS(OUT, paste0(SC_OUT, ".rds"))

OBS <- ccx_prepare_obs()
# ---- the substep override (in-process; ccx_resolve_substeps() looks the controller up by name) ----
.ss_shipped <- ccx_substeps_for
SS_MODE <- list(type = "shipped")
ccx_substeps_for <- function(p, grid = ccx_ocean_grid(p$h_ml), dt = 1 / 12) {
  switch(SS_MODE$type,
         shipped = .ss_shipped(p, grid, dt),
         mult    = as.integer(SS_MODE$k * .ss_shipped(p, grid, dt)),
         fix     = ss_candidate(p, grid, dt)[["ss"]],
         stop("unknown SS_MODE"))
}
with_ss <- function(mode, expr) { old <- SS_MODE; SS_MODE <<- mode; on.exit(SS_MODE <<- old); force(expr) }

# THE CANDIDATE FIX (section 5), written as a twin of ccx_substeps_for() so the diff is the two named
# departures and nothing else: (A) the extremes are the interpolant's CONTINUOUS ones -- the very
# f_min / f_max ccx_seas_ml_guard() reads (review A16) -- and (B) K is the HELD profile ccx_prepare()
# hands the integrator (ccx_kz_profile on the ANNUAL-MEAN grid), not the profile re-evaluated on the
# moved grid. (C) where the bound needs more than CCX_SUBSTEPS_MAX it STOPS (-> -Inf in the
# objective) instead of clamping to a count the bound itself says is unstable.
ss_candidate <- function(p, grid = ccx_ocean_grid(p$h_ml), dt = 1 / 12) {
  .grids <- list(grid)
  K_held <- max(ccx_kz_profile(p, grid))
  if (ccx_seas_ml_ls_on(p)) {
    .sh <- ccx_mld_shape("ls")
    .fs <- c(min(vapply(HEMIS, function(h) .sh[[h]]$f_min, numeric(1))),
             max(vapply(HEMIS, function(h) .sh[[h]]$f_max, numeric(1))))
    .grids <- lapply(.fs, function(f) ccx_grid_at_h_ml(grid, grid$h_ml * f))
  }
  lam <- max(vapply(.grids, function(g)
    ccx_diffusion_eigmax(K_held, g) +
      ccx_advection_eigbound(c(p$w_up, p$w_out_NH, p$w_out_SH), g, p) +
      ccx_tr_box_eigbound(p, g) + ccx_e_loop_eigbound(p, g) + ccx_thc_eigbound(p, g), numeric(1)))
  lam <- lam + ccx_eq_cell_eigbound(p)
  need <- dt * lam / (CCX_STAB_SAFETY * CCX_RK4_STAB_LIMIT)
  if (isTRUE(SS_MODE$stop_at_cap) && need > CCX_SUBSTEPS_MAX)
    stop(sprintf("ss_candidate: the bound needs %.1f substeps, past CCX_SUBSTEPS_MAX = %d", need, CCX_SUBSTEPS_MAX))
  c(need = need, ss = as.integer(min(max(CCX_SUBSTEPS_MIN, ceiling(need)), CCX_SUBSTEPS_MAX)))
}
# the SHIPPED bound's own `need` (its body, returning the value before the ceiling)
ss_need_shipped <- function(p, grid = ccx_ocean_grid(p$h_ml), dt = 1 / 12) {
  .grids <- list(grid)
  if (ccx_seas_ml_ls_on(p)) {
    .sh <- ccx_mld_shape("ls")
    .fs <- c(min(vapply(HEMIS, function(h) min(.sh[[h]]$f_month), numeric(1))),
             max(vapply(HEMIS, function(h) max(.sh[[h]]$f_month), numeric(1))))
    .grids <- lapply(.fs, function(f) ccx_grid_at_h_ml(grid, grid$h_ml * f))
  }
  lam <- max(vapply(.grids, function(g)
    ccx_diffusion_eigmax(max(ccx_kz_profile(p, g)), g) +
      ccx_advection_eigbound(c(p$w_up, p$w_out_NH, p$w_out_SH), g, p) +
      ccx_tr_box_eigbound(p, g) + ccx_e_loop_eigbound(p, g) + ccx_thc_eigbound(p, g), numeric(1))) + ccx_eq_cell_eigbound(p)
  c(need = dt * lam / (CCX_STAB_SAFETY * CCX_RK4_STAB_LIMIT), lam = lam)
}

# ---- the stiffness the integrator REALLY meets --------------------------------------------------
# The diffusion Jacobian exactly as src/ccx_core.cpp builds it at time t: dzl = the grid with the ML at
# h_ml f(t) and layer 1 absorbing the excursion (times a_ml/a_ls under D1), dzml from dzl, layer 1 at
# its EFFECTIVE thickness on the ML interface under D1, K = aux$kz_int (held at the annual mean).
J_diff <- function(K, dzl, dz1_eff) {
  n <- length(dzl); A <- matrix(0, n, n); dzml <- (dzl[-n] + dzl[-1]) / 2
  for (kk in seq_len(n - 1)) {
    b <- kk + 1; dzb <- if (kk == 1) dz1_eff else dzl[b]
    ra <- K[kk] / (dzl[kk] * dzml[kk]); rb <- K[kk] / (dzb * dzml[kk])
    A[kk, kk] <- A[kk, kk] - ra; A[kk, b] <- A[kk, b] + rb
    A[b, kk]  <- A[b, kk] + ra;  A[b, b]  <- A[b, b] - rb
  }
  A
}
geom_of <- function(p) {             # the structure's D1 geometry, from ONE ccx_prepare (areas do not move)
  aux <- ccx_prepare(p)
  list(share = stats::setNames(vapply(HEMIS, function(h) aux$a_ml[[h]] / aux$a_ls[[h]], 0), HEMIS),
       d1_on = isTRUE(aux$d1_on == 1L), shapes = aux$mld_coef)
}
rho_at <- function(p, grid, G, h, f) {
  ht <- grid$h_ml * f; dzl <- grid$dz; sh <- G$share[[h]]
  dzl[2] <- dzl[2] + (dzl[1] - ht) * sh; dzl[1] <- ht
  d1e <- if (G$d1_on) dzl[2] / sh else dzl[2]
  c(rho = max(Mod(eigen(J_diff(ccx_kz_profile(p, grid), dzl, d1e), only.values = TRUE)$values)), dz1 = dzl[2])
}
# full-year profile (section 2) ...
stiff_year <- function(p, G, grid = ccx_ocean_grid(p$h_ml), n_t = SC_NT) {
  tt <- (seq_len(n_t) - 0.5) / n_t
  stats::setNames(lapply(HEMIS, function(h) {
    r <- vapply(tt, function(t) rho_at(p, grid, G, h, ccx_mld_eval(G$shapes[[h]], t)$f), numeric(2))
    list(t = tt, rho = r["rho", ], dz1 = r["dz1", ])
  }), HEMIS)
}
# ... and the fast form for thousands of draws (sections 3-4): the stiffness at each carried shape's two
# continuous extremes. Asserted equal to the full-year maximum on every section-2 point.
stiff_ext <- function(p, G, grid = ccx_ocean_grid(p$h_ml)) {
  max(vapply(HEMIS, function(h) max(rho_at(p, grid, G, h, G$shapes[[h]]$f_max)[["rho"]],
                                     rho_at(p, grid, G, h, G$shapes[[h]]$f_min)[["rho"]]), 0))
}
assess <- function(p, G, grid = ccx_ocean_grid(p$h_ml)) {
  # P8 first: past the guard's wall (the carried shape's continuous max at or below layer 1's base)
  # the objective is -Inf by ccx_seas_ml_guard() and layer 1 has no thickness to take an eigenvalue of
  p8 <- cumsum(grid$dz)[2] - p$h_ml * max(vapply(HEMIS, function(h) ccx_mld_shape("ls")[[h]]$f_max, 0))
  if (!(p8 > 0)) return(c(h_ml = p$h_ml, kz = p$kz, kz_deep_frac = p$kz_deep_frac, p8_margin = p8, rho = NA,
                          need_shipped = NA, ss_shipped = NA, z_shipped = NA, need_fix = NA, ss_fix = NA, z_fix = NA))
  s0 <- ccx_mode_ss_safe(.ss_shipped, p, grid); sc <- ss_candidate(p, grid)
  r  <- stiff_ext(p, G, grid)
  c(h_ml = p$h_ml, kz = p$kz, kz_deep_frac = p$kz_deep_frac, p8_margin = p8,
    rho = r, need_shipped = ss_need_shipped(p, grid)[["need"]], ss_shipped = s0, z_shipped = r / 12 / s0,
    need_fix = sc[["need"]], ss_fix = sc[["ss"]], z_fix = r / 12 / sc[["ss"]])
}
ccx_mode_ss_safe <- function(fun, p, grid) tryCatch(fun(p, grid), error = function(e) NA_integer_)

# ---- one arm's objective (the read driver's in_arm idiom) --------------------------------------
CAP <- new.env()
.orf <- ccx_run_fast
ccx_run_fast <- function(spin, F, substeps = "auto", retry_na = TRUE) { r <- .orf(spin, F, substeps, retry_na); CAP$r <- r; r }
in_arm <- function(md, f) {
  r <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(r), add = TRUE)
  stopifnot(identical(md$param_names, CCX_PARAM_NAMES))
  bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  spf <- ccx_spinup_from_label(ccx_mode_spinup(md))
  spf_cap <- function(p) { CAP$p <- p; sp <- spf(p); CAP$sp <- sp; sp }
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = spf_cap, obs = OBS)
  invisible(utils::capture.output(st <- ccx_mode_start(md, "substep controller")))
  stopifnot(length(st$absent) == 0L, st$logpost_shift == 0)
  f(lp, st$u, bp)
}
ev <- function(lp, u) {
  for (x in ls(CAP)) rm(list = x, envir = CAP)
  t0 <- Sys.time(); v <- tryCatch(lp(u), error = function(e) structure(NA_real_, err = conditionMessage(e)))
  list(logpost = as.numeric(v), streams = unlist(attr(v, "streams")), err = attr(v, "err"),
       ss = if (!is.null(CAP$r)) CAP$r$substeps else NA_integer_, sec = as.numeric(Sys.time() - t0, units = "secs"),
       p = CAP$p, sp = CAP$sp, out = if (!is.null(CAP$r)) CAP$r$out else NULL)
}

md  <- readRDS(ccx_mode_file(SC_MODE_KEY)); s17 <- readRDS(SC_STUCK_FILE)
stopifnot(identical(ccx_mode_struct(md), SC_LABEL), identical(s17$struct, SC_LABEL), isTRUE(s17$resumed),
          identical(s17$param_names, md$param_names))
fs  <- ccx_mode_fit_stats(md)
sdc <- stats::setNames(as.numeric(fs$sd_conditional), fs$param_names)
sdm <- stats::setNames(as.numeric(fs$sd), fs$param_names)

# ---- 0. reproduction ---------------------------------------------------------------------------
cat(sprintf("\n=== 0. BOTH VECTORS REPRODUCE THEIR STORED LOGPOSTS (tol %g) ===\n", SC_REPRO_TOL))
R0 <- in_arm(md, function(lp, u, bp) list(mode = ev(lp, u), s17 = ev(lp, s17$u_mode), u_mode = u))
for (a in c("mode", "s17")) {
  stored <- if (a == "mode") md$logpost else s17$logpost
  d <- R0[[a]]$logpost - stored
  cat(sprintf("  %-5s logpost %.6f (stored %.6f, diff %+.1e) at %d substeps\n", a, R0[[a]]$logpost, stored, d, R0[[a]]$ss))
  if (!(abs(d) <= SC_REPRO_TOL)) stop(a, " does NOT reproduce its stored logpost (missing untracked data? e.g. ",
                                      "data-raw/downloads/nuclear14c): nothing below can be read off it")
}
u_mode <- R0$u_mode; u0 <- s17$u_mode
PTS <- list(mode = u_mode, s017 = u0)
for (n in SC_DIRS) { h <- SC_STEP_FRAC * sdc[[n]]
  up <- u0; up[[n]] <- up[[n]] + h; dn <- u0; dn[[n]] <- dn[[n]] - h
  PTS[[paste0(n, "+")]] <- up; PTS[[paste0(n, "-")]] <- dn }
OUT$points <- PTS

# ---- 1. convergence under refinement -------------------------------------------------------------
cat(sprintf("\n=== 1. THE OBJECTIVE UNDER SUBSTEP REFINEMENT (x %s the controller's count, spinup AND transient) ===\n",
            paste(SC_MULTS, collapse = ", ")))
CONV <- in_arm(md, function(lp, u, bp) {
  out <- list()
  for (nm in names(PTS)) for (k in SC_MULTS) {
    e <- with_ss(if (k == 1L) list(type = "shipped") else list(type = "mult", k = k), ev(lp, PTS[[nm]]))
    rec <- e[c("logpost", "streams", "ss", "sec", "err")]
    if (k == 1L) {                   # keep the controller-count run's internals for section 2
      rec$par <- e$p[c("h_ml", "kz", "kz_deep_frac", "sst_seas_amp_SH")]
      rec$periodic <- e$sp$periodic[c("resid_carbon", "iterations")]
      if (!is.null(e$out)) {
        o <- e$out; yr <- floor(o$t)
        big <- which(abs(o$d13c_SH) > SC_BLOWUP_D13C)
        rec$orbit <- c(ml_C_SH_first = o$ml_C_SH[1], ml_C_SH_min = min(o$ml_C_SH),
                       d13c_SH_absmax = max(abs(o$d13c_SH)), first_year_blowup = if (length(big)) yr[big[1]] else NA_real_)
      }
      rec$geom <- geom_of(e$p); rec$p <- e$p
    }
    out[[sprintf("%s|%d", nm, k)]] <- rec
  }
  out
})
OUT$conv <- lapply(CONV, function(x) x[setdiff(names(x), c("p", "geom"))]); save_out()
lpk <- function(nm, k) CONV[[sprintf("%s|%d", nm, k)]]$logpost
row <- function(nm, k, r) CONV[[sprintf("%s|%d", nm, k)]]$streams[[r]]
kmax <- max(SC_MULTS); kpen <- SC_MULTS[length(SC_MULTS) - 1L]
cat(sprintf("  %-14s %s | integration error at the controller's count (x1 - x%d) | refinement residue (x%d - x%d)\n",
            "point", paste(sprintf("%12s", paste0("x", SC_MULTS)), collapse = ""), kmax, kpen, kmax))
CONV_TAB <- do.call(rbind, lapply(names(PTS), function(nm) {
  v <- vapply(SC_MULTS, function(k) lpk(nm, k), 0); ss <- vapply(SC_MULTS, function(k) CONV[[sprintf("%s|%d", nm, k)]]$ss, 0L)
  cat(sprintf("  %-14s %s | %+14.4f | %+.2e\n", nm, paste(sprintf("%12.3f", v), collapse = ""), v[1] - v[length(v)],
              v[length(v) - 1] - v[length(v)]))
  cat(sprintf("  %-14s %s\n", "", paste(sprintf("%12s", paste0("ss ", ss)), collapse = "")))
  data.frame(point = nm, t(stats::setNames(v, paste0("x", SC_MULTS))), err_ctrl = v[1] - v[length(v)],
             resid = v[length(v) - 1] - v[length(v)], ss_ctrl = ss[1])
}))
OUT$conv_table <- CONV_TAB
stopifnot(all(abs(CONV_TAB$resid) < SC_CONV_TOL))
cat(sprintf("  ✓ every point CONVERGED: |x%d - x%d| < %g at all %d\n", kpen, kmax, SC_CONV_TOL, nrow(CONV_TAB)))
cat(sprintf("  the row the controller's count gets wrong at 017: co2_seasonal_SPO %.3f at x1 vs %.3f at x%d (%+.3f); d13c_seasonal_SPO %.4f vs %.4f\n",
            row("s017", 1, "co2_seasonal_SPO"), row("s017", kmax, "co2_seasonal_SPO"), kmax,
            row("s017", 1, "co2_seasonal_SPO") - row("s017", kmax, "co2_seasonal_SPO"),
            row("s017", 1, "d13c_seasonal_SPO"), row("s017", kmax, "d13c_seasonal_SPO")))
SMOOTH <- do.call(rbind, lapply(SC_DIRS, function(n) {
  f <- function(k) c(up = lpk(paste0(n, "+"), k) - lpk("s017", k), dn = lpk(paste0(n, "-"), k) - lpk("s017", k))
  a <- f(1L); b <- f(kmax)
  data.frame(name = n, d_up_x1 = a[["up"]], d_dn_x1 = a[["dn"]], pair_x1 = sum(a),
             d_up_conv = b[["up"]], d_dn_conv = b[["dn"]], pair_conv = sum(b))
}))
OUT$smoothness <- SMOOTH; save_out()
cat(sprintf("  smoothness at 017, %g conditional sd each way (a smooth bowl gives %.2f; flag |pair| > %g):\n",
            SC_STEP_FRAC, -SC_STEP_FRAC^2, SC_SMOOTH_TOL))
for (i in seq_len(nrow(SMOOTH))) with(SMOOTH[i, ], cat(sprintf(
  "    %-13s controller's count: up %s dn %s pair %s   |   converged (x%d): up %+.3f dn %+.3f pair %+.3f\n",
  name, format(d_up_x1, digits = 5), format(d_dn_x1, digits = 5), format(pair_x1, digits = 5), kmax, d_up_conv, d_dn_conv, pair_conv)))
stopifnot(all(abs(SMOOTH$pair_x1) > SC_SMOOTH_TOL))        # POWER: the flag fires at the controller's count ...
stopifnot(all(abs(SMOOTH$pair_conv) <= SC_SMOOTH_TOL))     # ... and is gone on the converged objective
cat("  ✓ the flag FIRES at the controller's count in all three directions and CLEARS on the converged objective\n")

# ---- 2. the anatomy ---------------------------------------------------------------------------
cat("\n=== 2. THE STIFFNESS THE INTEGRATOR MEETS vs WHAT THE CONTROLLER ASSUMED (SH winter peak) ===\n")
ANAT <- do.call(rbind, lapply(names(PTS), function(nm) {
  rec <- CONV[[sprintf("%s|1", nm)]]; p <- rec$p; G <- rec$geom; grid <- ccx_ocean_grid(p$h_ml)
  sy <- stiff_year(p, G, grid); ss <- rec$ss
  rmax_year <- max(vapply(sy, function(x) max(x$rho), 0)); rext <- stiff_ext(p, G, grid)
  # every departure, at the binding (deepest) extreme: shipped = sampled extremes + re-evaluated K;
  # (A) continuous extremes; (A+B) + the held K
  sh <- ccx_mld_shape("ls"); fmx <- c(samp = max(vapply(HEMIS, function(h) max(sh[[h]]$f_month), 0)),
                                     cont = max(vapply(HEMIS, function(h) sh[[h]]$f_max, 0)))
  lam <- function(f, held) { g <- ccx_grid_at_h_ml(grid, grid$h_ml * f)
    ccx_diffusion_eigmax(if (held) max(ccx_kz_profile(p, grid)) else max(ccx_kz_profile(p, g)), g) }
  zz <- vapply(sy, function(x) x$rho / 12 / ss, numeric(length(sy[[1]]$rho)))
  k_moved <- max(ccx_kz_profile(p, ccx_grid_at_h_ml(grid, grid$h_ml * fmx[["cont"]])))
  nd <- ss_need_shipped(p, grid)
  data.frame(point = nm, h_ml = p$h_ml, kz = p$kz, sst_seas_amp_SH = p$sst_seas_amp_SH,
             dz1_min_SH = min(sy$SH$dz1), dz1_at_sampled_max = grid$dz[2] - grid$h_ml * (fmx[["samp"]] - 1),
             need = nd[["need"]], ss = ss, rho_true = rmax_year, rho_ext = rext,
             lam_shipped = lam(fmx[["samp"]], FALSE), lam_A = lam(fmx[["cont"]], FALSE), lam_AB = lam(fmx[["cont"]], TRUE),
             K_moved_over_held = k_moved / max(ccx_kz_profile(p, grid)),
             z_true = rmax_year / 12 / ss, days_unstable = 365.25 * max(colMeans(zz > SC_LIMIT)),
             t_peak = sy$SH$t[which.max(sy$SH$rho)])
}))
OUT$anatomy <- ANAT; save_out()
stopifnot(all(abs(ANAT$rho_ext / ANAT$rho_true - 1) < 1e-3))   # the two-extremes shortcut IS the year's maximum
for (i in seq_len(nrow(ANAT))) with(ANAT[i, ], cat(sprintf(
  "  %-14s h_ml %.3f: layer 1 at the SH peak %.3f m (controller's sampled peak: %.3f m); need %.5f -> %d substeps\n      rho %.1f/yr vs the controller's lambda %.1f (A: %.1f, A+B: %.1f); K on the moved grid %.3f x held; z %.3f vs limit %.3f -> UNSTABLE %.1f days/yr, peak at t = %.3f yr\n",
  point, h_ml, dz1_min_SH, dz1_at_sampled_max, need, ss, rho_true, lam_shipped, lam_A, lam_AB, K_moved_over_held,
  z_true, SC_LIMIT, days_unstable, t_peak)))
cat(sprintf("  ✓ the two-extremes shortcut equals the full-year maximum at all %d points (used in sections 3-4)\n", nrow(ANAT)))
a17 <- ANAT[ANAT$point == "s017", ]
# the bound is linear in kz here (diffusion only: no advective, cell or loop term is live under this
# label), so the kz that reaches the next count is kz x ceiling(need) / need -- checked, not assumed
r_tmp <- ccx_apply_pins(ccx_mode_pins(md))
kz_sw <- a17$kz * ceiling(a17$need) / a17$need
p_sw  <- CONV[["s017|1"]]$p; p_sw$kz <- kz_sw * (1 + 1e-9)
stopifnot(.ss_shipped(p_sw) == ceiling(a17$need) + 1L)
du_sw <- .to_unc(kz_sw, CCX_PARAM_TABLE$kz) - .to_unc(a17$kz, CCX_PARAM_TABLE$kz)
ccx_unpin_params(r_tmp)
cat(sprintf("  017 sits %.2e substeps BELOW the %d -> %d switch: kz %.4f -> %.4f flips it, %.2e conditional sd in u\n",
            ceiling(a17$need) - a17$need, as.integer(ceiling(a17$need)), as.integer(ceiling(a17$need)) + 1L,
            a17$kz, kz_sw, du_sw / sdc[["kz"]]))
OUT$switch <- list(need = a17$need, kz = a17$kz, kz_switch = kz_sw, du_cond_sd = du_sw / sdc[["kz"]])
o_hp <- CONV[["h_ml+|1"]]$orbit; o_0 <- CONV[["s017|1"]]$orbit
cat(sprintf("  the h_ml+ blow-up: SH mixed-layer carbon %.1f GtC at the first month (017: %.1f), MIN over the run %.1f GtC (017: %.1f); |d13c_SH| max %.3g permil, past %g from %s\n",
            o_hp[["ml_C_SH_first"]], o_0[["ml_C_SH_first"]], o_hp[["ml_C_SH_min"]], o_0[["ml_C_SH_min"]],
            o_hp[["d13c_SH_absmax"]], SC_BLOWUP_D13C, format(o_hp[["first_year_blowup"]])))
cat(sprintf("  the periodic spinup CONVERGED at every point (resid_carbon <= %.1e, %s iterations): it finds the fixed point of the discrete map whether or not that map is stable\n",
            max(vapply(names(PTS), function(nm) CONV[[sprintf("%s|1", nm)]]$periodic$resid_carbon, 0)),
            paste(range(vapply(names(PTS), function(nm) CONV[[sprintf("%s|1", nm)]]$periodic$iterations, 0)), collapse = "-")))

# ---- 3. the edge along h_ml -------------------------------------------------------------------
cat("\n=== 3. THE EDGE ALONG h_ml (the other values held) ===\n")
r_md <- ccx_apply_pins(ccx_mode_pins(md))
bp_md <- ccx_mode_base(md); bp_md$pump_mode <- md$pump_mode
G_md <- geom_of(ccx_overlay_par(bp_md, md$par_mode))
scan_h <- function(par) do.call(rbind, lapply(SC_HML_SCAN, function(hm) {
  q <- ccx_overlay_par(bp_md, par); q$h_ml <- hm
  tryCatch(assess(q, G_md), error = function(e) NULL) }))
EDGE <- list(mode = scan_h(md$par_mode), s017 = scan_h(s17$par_mode))
OUT$edge <- EDGE; save_out()
s_h <- CCX_PARAM_TABLE$h_ml; h_mode <- md$par_mode[["h_ml"]]
for (a in names(EDGE)) {
  E <- EDGE[[a]]
  cat(sprintf("  other values at the %s:\n", toupper(a)))
  cat(sprintf("    %7s %9s %8s %9s %8s %8s %8s\n", "h_ml", "P8 margin", "ss now", "z now", "ss fix", "z fix", "need fix"))
  for (i in seq_len(nrow(E))) with(as.list(E[i, ]), cat(sprintf("    %7.2f %9.3f %8d %9.3f %8d %8.3f %8.1f%s\n",
    h_ml, p8_margin, as.integer(ss_shipped), z_shipped, as.integer(ss_fix), z_fix, need_fix,
    if (z_shipped > SC_LIMIT) "  <- UNSTABLE now" else "")))
  ib <- which(E[, "z_shipped"] > SC_LIMIT)[1]
  if (!is.na(ib)) cat(sprintf("    first UNSTABLE h_ml on the scan: %.2f m (the last stable one %.2f m) = %.2f marginal sds of u(h_ml) above the mode's %.2f m\n",
                              E[ib, "h_ml"], E[ib - 1, "h_ml"], (.to_unc(E[ib, "h_ml"], s_h) - .to_unc(h_mode, s_h)) / sdm[["h_ml"]], h_mode))
  icap <- which(E[, "need_fix"] > CCX_SUBSTEPS_MAX)[1]
  live <- E[, "need_fix"] <= CCX_SUBSTEPS_MAX
  cat(sprintf("    under the fix, z <= %.3f wherever it runs (target %.3f, limit %.3f); it STOPS (needs more than CCX_SUBSTEPS_MAX = %d) only from h_ml %s (P8 margin %s m)\n",
              max(E[live, "z_fix"]), SC_TARGET, SC_LIMIT, CCX_SUBSTEPS_MAX, if (is.na(icap)) "(not reached)" else sprintf("%.2f", E[icap, "h_ml"]),
              if (is.na(icap)) "-" else sprintf("%.3f", E[icap, "p8_margin"])))
}
ccx_unpin_params(r_md)

# ---- 4. who is in it --------------------------------------------------------------------------
cat("\n=== 4. WHO IS IN THE UNSTABLE REGION ===\n")
WHO <- list()
# (a) the registered modes
REG <- do.call(rbind, lapply(names(CCX_MODE_FILES), function(k) {
  mk <- readRDS(ccx_mode_file(k)); r <- ccx_apply_pins(ccx_mode_pins(mk)); on.exit(ccx_unpin_params(r))
  b <- ccx_mode_base(mk); b$pump_mode <- mk$pump_mode; p <- ccx_overlay_par(b, mk$par_mode)
  a <- if (ccx_seas_ml_ls_on(p)) assess(p, geom_of(p)) else
    c(h_ml = p$h_ml, kz = p$kz, kz_deep_frac = p$kz_deep_frac, p8_margin = NA, rho = NA, need_shipped = NA,
      ss_shipped = .ss_shipped(p), z_shipped = NA, need_fix = NA, ss_fix = ss_candidate(p)[["ss"]], z_fix = NA)
  data.frame(mode = k, struct = ccx_mode_struct(mk), seas_ml = ccx_mode_seas_ml(mk), t(a))
}))
WHO$registered <- REG; OUT$who <- WHO; save_out()
cat("  (a) the registered modes:\n"); print(REG[, c("mode", "struct", "seas_ml", "h_ml", "kz", "p8_margin", "ss_shipped", "z_shipped", "ss_fix", "z_fix")], digits = 4, row.names = FALSE)
# (b) every start file of every seas_ml = 1 wave
waves <- sort(list.dirs(file.path("calibration", "output"), recursive = FALSE))
waves <- c(waves[grepl("^(multistart|resume)", basename(waves))])
ST <- do.call(rbind, lapply(waves, function(w) {
  fs_ <- sort(list.files(w, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE)); if (!length(fs_)) return(NULL)
  do.call(rbind, lapply(fs_, function(f) {
    s <- tryCatch(readRDS(f), error = function(e) NULL)
    if (is.null(s) || !isTRUE(s$seas_ml == 1) || is.null(s$par_mode) || is.null(s$struct)) return(NULL)
    a <- tryCatch({
      b <- ccx_apply_structure(ccx_default_params(), s$struct, seas_ml = s$seas_ml,
                               pump_field = if (is.null(s$pump_field)) "solved" else ccx_parse_pump_field(s$pump_field))
      for (n in names(s$pins)) b[[n]] <- s$pins[[n]]
      p <- b; for (n in names(s$par_mode)) p[[n]] <- s$par_mode[[n]]
      assess(p, geom_of(p))
    }, error = function(e) NULL)
    if (is.null(a)) return(data.frame(wave = basename(w), id = s$id, logpost = s$logpost, converged = isTRUE(s$converged),
                                      out_of_time = isTRUE(s$out_of_time), assessed = FALSE))
    data.frame(wave = basename(w), id = s$id, logpost = s$logpost, converged = isTRUE(s$converged),
               out_of_time = isTRUE(s$out_of_time), assessed = TRUE, t(a))
  }))
}))
ST$gap <- ave(ST$logpost, ST$wave, FUN = function(x) max(x, na.rm = TRUE)) - ST$logpost
WHO$starts <- ST; OUT$who <- WHO; save_out()
ok <- ST[ST$assessed, ]; bad <- ok[ok$z_shipped > SC_LIMIT, ]; moved <- ok[ok$ss_fix != ok$ss_shipped, ]
cat(sprintf("  (b) start files, seas_ml = 1, every wave: %d read (%d assessed, %d waves); final point UNSTABLE under the shipped controller: %d; count moved by the fix: %d\n",
            nrow(ST), nrow(ok), length(unique(ST$wave)), nrow(bad), nrow(moved)))
if (nrow(bad)) { cat("      the unstable ones:\n"); print(bad[, c("wave", "id", "logpost", "gap", "converged", "out_of_time", "h_ml", "p8_margin", "ss_shipped", "z_shipped", "ss_fix")], digits = 5, row.names = FALSE) }
if (nrow(moved)) { cat("      every start whose count the fix moves (its stored logpost would move):\n")
  print(moved[, c("wave", "id", "logpost", "gap", "converged", "h_ml", "ss_shipped", "ss_fix", "z_shipped", "z_fix")], digits = 5, row.names = FALSE) }
cat(sprintf("      highest h_ml among CONVERGED final points: %.2f m (P8 margin %.2f m, z %.3f)\n",
            max(ok$h_ml[ok$converged]), ok$p8_margin[ok$converged][which.max(ok$h_ml[ok$converged])],
            ok$z_shipped[ok$converged][which.max(ok$h_ml[ok$converged])]))
# (c) the MCMC stage-1 draws (hilda33d; same geometry, no lag)
mk <- readRDS(ccx_mode_file(SC_MCMC_KEY)); r <- ccx_apply_pins(ccx_mode_pins(mk))
b33 <- ccx_mode_base(mk); b33$pump_mode <- mk$pump_mode; G33 <- geom_of(ccx_overlay_par(b33, mk$par_mode))
U <- readRDS(SC_MCMC_POOLED); stopifnot(all(SC_DIRS %in% colnames(U)), all(colnames(U) %in% CCX_PARAM_NAMES))
dec <- function(Um) lapply(SC_DIRS, function(n) .from_unc(Um[, n], CCX_PARAM_TABLE[[n]]))
assess_draws <- function(Um, base, G) {
  x <- dec(Um); names(x) <- SC_DIRS
  t(vapply(seq_len(nrow(Um)), function(i) { q <- base; for (n in SC_DIRS) q[[n]] <- x[[n]][i]; assess(q, G) }, numeric(11)))
}
MC33 <- assess_draws(U, ccx_overlay_par(b33, mk$par_mode), G33)
mc_bad <- which(MC33[, "z_shipped"] > SC_LIMIT)
MCMC_BAD_U <- U[mc_bad, , drop = FALSE]                    # re-scored in (e), under hilda33d's own objective
ccx_unpin_params(r)
WHO$mcmc <- MC33; WHO$mcmc_bad <- mc_bad; OUT$who <- WHO; save_out()
q_mc <- stats::quantile(MC33[, "h_ml"], c(0.5, 0.99, 0.999, 1))
cat(sprintf("  (c) MCMC stage 1 (%s, %d pooled draws): h_ml median %.2f, 99%% %.2f, 99.9%% %.2f, max %.2f m; min P8 margin %.2f m; max z %.3f (limit %.3f); max substeps %d; UNSTABLE draws: %d (%d distinct point%s)\n",
            SC_MCMC_KEY, nrow(U), q_mc[[1]], q_mc[[2]], q_mc[[3]], q_mc[[4]], min(MC33[, "p8_margin"]), max(MC33[, "z_shipped"]),
            SC_LIMIT, as.integer(max(MC33[, "ss_shipped"])), length(mc_bad), nrow(unique(MCMC_BAD_U)),
            if (nrow(unique(MCMC_BAD_U)) == 1L) "" else "s"))
# (d) Laplace draws about the mode -- a LOCAL instrument: it knows the mode's curvature, not a ridge's
# reach, so its tail is read against (c), never instead of it
r_md <- ccx_apply_pins(ccx_mode_pins(md))
LAP <- lapply(SC_MC_WIDTHS, function(wd) {
  set.seed(SC_MC_SEED)                                     # immediately before the draw that consumes it
  Z <- matrix(stats::rnorm(SC_MC_N * length(u_mode)), SC_MC_N) %*% chol(md$cov) * wd
  Um <- sweep(Z, 2, u_mode, "+"); colnames(Um) <- names(u_mode)
  A <- assess_draws(Um, bp_md, G_md); feas <- A[, "p8_margin"] > 0
  list(width = wd, h_ml_q = stats::quantile(A[, "h_ml"], c(0.5, 0.999, 1)), n_p8 = sum(!feas),
       n_unstable = sum(A[feas, "z_shipped"] > SC_LIMIT), frac_ss_gt_floor = mean(A[feas, "ss_shipped"] > CCX_SUBSTEPS_MIN),
       max_z = max(A[feas, "z_shipped"]), min_p8 = min(A[feas, "p8_margin"]))
})
ccx_unpin_params(r_md)
WHO$laplace <- LAP; OUT$who <- WHO; save_out()
for (L in LAP) cat(sprintf("  (d) Laplace about %s, %g x sd, %d draws (seed %d): h_ml median %.2f, 99.9%% %.2f, max %.2f m; past the P8 wall %d; min P8 margin %.2f m; max z %.3f; count above the floor %.3f%%; UNSTABLE: %d\n",
                           SC_MODE_KEY, L$width, SC_MC_N, SC_MC_SEED, L$h_ml_q[[1]], L$h_ml_q[[2]], L$h_ml_q[[3]], L$n_p8, L$min_p8, L$max_z,
                           100 * L$frac_ss_gt_floor, L$n_unstable))
cat(sprintf("      ⚠ the Laplace puts h_ml's 99.9%% at %.1f m where the MCMC's is %.1f m: along h_ml the posterior is a RIDGE the local curvature does not see, so (c) is the answer to \"can a draw reach it\"\n",
            LAP[[1]]$h_ml_q[[2]], q_mc[[3]]))

# (e) HOW BIG IS THE ARTIFACT where it occurs: every UNSTABLE start-file point, every stable one past
# SC_ARTEFACT_Z_CTRL (the near-limit control), each wave's best (the far control) and the MCMC's
# unstable draws, re-scored at the controller's count and refined -- under TODAY's objective for that
# point's own structure, pins and param set (an older wave's stored logpost was scored under its own
# objective, so `stored` is shown but only ctrl - refined measures the integrator). A point whose
# param set this build cannot encode is listed as SKIPPED, never silently dropped.
pseudo_md <- function(s) list(struct = s$struct, seas_ml = s$seas_ml, pump_field = s$pump_field, pump_mode = s$pump_mode,
                              pins = s$pins, param_names = s$param_names, spinup = ccx_spinup_label(CCX_OBJECTIVE_SPINUP))
ST$file <- NA_character_
for (w in waves) { fs_ <- sort(list.files(w, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE))
  ids <- vapply(fs_, function(f) as.integer(readRDS(f)$id), 0L); ST$file[ST$wave == basename(w)] <- fs_[match(ST$id[ST$wave == basename(w)], ids)] }
best_idx <- unlist(lapply(split(seq_len(nrow(ST)), ST$wave), function(i) i[which.max(ST$logpost[i])]))
sel <- sort(unique(c(which(ST$assessed & ST$z_shipped > SC_ARTEFACT_Z_CTRL), best_idx)))
ART <- do.call(rbind, lapply(split(sel, ST$wave[sel]), function(ii) {
  s1 <- readRDS(ST$file[ii[1]]); pmd <- pseudo_md(s1)
  skip <- function(why) data.frame(wave = ST$wave[ii], id = ST$id[ii], kind = NA, stored = ST$logpost[ii], ctrl = NA, x4 = NA, x8 = NA,
                                   ss = NA, z = ST$z_shipped[ii], h_ml = ST$h_ml[ii], converged = ST$converged[ii], status = paste("SKIPPED:", why),
                                   encoded = NA_character_)
  r_w <- tryCatch(ccx_apply_pins(ccx_mode_pins(pmd)), error = function(e) NULL)
  if (is.null(r_w)) return(skip("pins"))
  how <- "as stored"
  if (!identical(s1$param_names, CCX_PARAM_NAMES)) {
    # a wave older than some fitted names: HOLD each later name at the value ccx_migrate_par_set()
    # gives it -- the repo's own absence contract (absent = its mechanism OFF), which sits on the
    # transform's boundary and so cannot be ENCODED as a fitted coordinate. Pinned, the wave's own
    # fitted space comes back exactly and its stored u is read as it stands.
    later <- setdiff(CCX_PARAM_NAMES, s1$param_names)
    pv <- tryCatch(ccx_migrate_par_set(as.list(s1$par_mode)), error = function(e) NULL)
    ccx_unpin_params(r_w); r_w <- NULL
    if (is.null(pv) || length(setdiff(s1$param_names, CCX_PARAM_NAMES)) || !all(later %in% names(pv)))
      return(skip("param set (no absence contract)"))
    pmd$pins <- c(pmd$pins, unlist(pv[later]))
    r_w <- tryCatch(ccx_apply_pins(ccx_mode_pins(pmd)), error = function(e) NULL)
    if (is.null(r_w) || !identical(s1$param_names, CCX_PARAM_NAMES)) {
      if (!is.null(r_w)) ccx_unpin_params(r_w)
      return(skip("param set (pinning the later names did not restore it)"))
    }
    how <- paste0("later names held at their absence values: ", paste(sprintf("%s=%g", later, unlist(pv[later])), collapse = ","))
  }
  on.exit(ccx_unpin_params(r_w))
  # ⛔ ENCODE FROM THE NATURAL VALUES, never reuse the stored u: a start file's u is in ITS table, and
  # h_ml's lower bound moved 30 -> 42.5 m on 09-16, so a pre-09-16 u decodes 13-31 % away from the
  # point that wave actually evaluated (the first run of this driver scored those waves at the wrong
  # h_ml). A natural value outside today's bounds cannot be scored here and is listed as SKIPPED.
  enc_u <- function(s) {
    u <- tryCatch(ccx_par_to_unc(as.list(s$par_mode)), error = function(e) NULL)
    if (is.null(u) || !all(is.finite(u))) return(NULL)
    list(u = u, how = how)
  }
  bp_w <- ccx_mode_base(pmd); bp_w$pump_mode <- pmd$pump_mode
  lp_w <- ccx_make_logpost(base_params = bp_w, by_stream = TRUE, spinup_fn = CCX_OBJECTIVE_SPINUP, obs = OBS)
  do.call(rbind, lapply(ii, function(i) {
    s <- readRDS(ST$file[i])
    if (!identical(s$param_names, s1$param_names)) return(skip("param set differs within the wave")[ii == i, ])
    e_u <- enc_u(s); if (is.null(e_u)) return(skip("a natural value lies outside today's bounds")[ii == i, ])
    u <- e_u$u
    a <- ev(lp_w, u); b <- with_ss(list(type = "mult", k = 4L), ev(lp_w, u)); c8 <- with_ss(list(type = "mult", k = 8L), ev(lp_w, u))
    data.frame(wave = ST$wave[i], id = ST$id[i], kind = if (i %in% best_idx) "wave best" else if (ST$z_shipped[i] > SC_LIMIT) "UNSTABLE" else "near limit",
               stored = s$logpost, ctrl = a$logpost, x4 = b$logpost, x8 = c8$logpost, ss = a$ss, z = ST$z_shipped[i], h_ml = ST$h_ml[i],
               converged = isTRUE(s$converged), status = "scored", encoded = e_u$how)
  }))
}))
if (length(mc_bad)) {                                      # the MCMC's unstable draw(s), under hilda33d's objective
  ART <- rbind(ART, in_arm(mk, function(lp, u, bp) do.call(rbind, lapply(seq_len(nrow(unique(MCMC_BAD_U))), function(j) {
    uu <- unique(MCMC_BAD_U)[j, ]; names(uu) <- CCX_PARAM_NAMES
    a <- ev(lp, uu); b <- with_ss(list(type = "mult", k = 4L), ev(lp, uu)); c8 <- with_ss(list(type = "mult", k = 8L), ev(lp, uu))
    data.frame(wave = paste0("mcmc stage 1 (", SC_MCMC_KEY, ")"), id = mc_bad[j], kind = "UNSTABLE", stored = NA, ctrl = a$logpost,
               x4 = b$logpost, x8 = c8$logpost, ss = a$ss, z = MC33[mc_bad[j], "z_shipped"], h_ml = MC33[mc_bad[j], "h_ml"],
               converged = NA, status = "scored", encoded = "as stored")
  }))))
}
ART$artefact <- ART$ctrl - ART$x8; ART$resid <- ART$x4 - ART$x8
WHO$artefact <- ART; OUT$who <- WHO; save_out()
sc_ <- ART[ART$status == "scored", ]
cat(sprintf("  (e) the artefact (controller's count - x8, today's objective), %d points scored, %d SKIPPED (param set), refinement residue |x4 - x8| max %.1e:\n",
            nrow(sc_), sum(ART$status != "scored"), max(abs(sc_$resid))))
for (k in c("UNSTABLE", "near limit", "wave best")) { a <- sc_[sc_$kind %in% k, ]; if (!nrow(a)) next
  fin <- is.finite(a$artefact)
  cat(sprintf("      %-10s n %3d (%d not finite at both counts): artefact median %+.3f, range [%+.3f, %+.3f]; |artefact| > %g at %d; converged among them %d (their artefact: %s)\n",
              k, nrow(a), sum(!fin), stats::median(a$artefact[fin]), min(a$artefact[fin]), max(a$artefact[fin]), SC_SMOOTH_TOL,
              sum(abs(a$artefact[fin]) > SC_SMOOTH_TOL), sum(a$converged %in% TRUE),
              if (any(a$converged %in% TRUE)) paste(sprintf("%+.2f", a$artefact[a$converged %in% TRUE]), collapse = ", ") else "-")) }
for (k in unique(ART$status[ART$status != "scored"])) cat(sprintf("      %s: %d point(s)\n", k, sum(ART$status == k)))
cat("      every unstable point, worst first:\n")
ub <- sc_[sc_$kind == "UNSTABLE", ]; ub <- ub[order(-abs(ub$artefact)), ]
for (i in seq_len(nrow(ub))) with(ub[i, ], cat(sprintf("        %-52s id %3d %s z %.2f h_ml %.2f: ctrl %s  x8 %.2f  artefact %s%s\n",
  substr(wave, 1, 52), as.integer(id), if (isTRUE(converged)) "CONV" else "    ", z, h_ml, format(ctrl, digits = 7), x8, format(artefact, digits = 4),
  if (is.finite(stored) && abs(stored - ctrl) > SC_REPRO_TOL) sprintf("  (stored %.2f, another objective)", stored) else "")))
n_unconv <- sum(!(abs(sc_$resid) < SC_CONV_TOL), na.rm = TRUE)
cat(sprintf("      refinement check: %d of %d scored points have |x4 - x8| >= %g (their x8 is not yet a converged value)\n",
            n_unconv, nrow(sc_), SC_CONV_TOL))

# ---- 5. the candidate fix, priced --------------------------------------------------------------
cat("\n=== 5. THE CANDIDATE FIX, PRICED (in-process; R/ untouched) ===\n")
FIXSS <- list(type = "fix", stop_at_cap = TRUE)
# every registered mode scored as test-mode-file.R scores it: its own pins and base, ccx_mode_start()'s
# encoding (an older file's absent names migrated, a seeded name's prior + Jacobian a KNOWN constant,
# `logpost_shift`), its own recorded spinup. Reproduction is gated on stored + shift.
score_mode <- function(k) {
  mk <- readRDS(ccx_mode_file(k))
  r <- ccx_apply_pins(ccx_mode_pins(mk)); on.exit(ccx_unpin_params(r))
  bp <- ccx_mode_base(mk); if (!is.null(mk$pump_mode)) bp$pump_mode <- mk$pump_mode
  invisible(utils::capture.output(st <- ccx_mode_start(mk, "substep controller pricing")))
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(mk)), obs = OBS)
  a <- ev(lp, st$u); b <- with_ss(FIXSS, ev(lp, st$u))
  data.frame(mode = k, stored = mk$logpost, shift = st$logpost_shift, shipped = a$logpost, fix = b$logpost,
             d = b$logpost - a$logpost, ss_shipped = a$ss, ss_fix = b$ss, identical_streams = identical(a$streams, b$streams))
}
PRICE <- do.call(rbind, lapply(names(CCX_MODE_FILES), score_mode))
OUT$price <- PRICE; save_out()
print(PRICE, digits = 10, row.names = FALSE)
stopifnot(all(abs(PRICE$shipped - PRICE$shift - PRICE$stored) <= SC_REPRO_TOL))
cat(sprintf("  registered modes whose count the fix moves: %d of %d; whose logpost it moves: %d (largest |d| %.1e)\n",
            sum(PRICE$ss_fix != PRICE$ss_shipped), nrow(PRICE), sum(PRICE$d != 0), max(abs(PRICE$d))))
FIXPTS <- in_arm(md, function(lp, u, bp) lapply(PTS, function(x) with_ss(FIXSS, ev(lp, x))[c("logpost", "ss", "err")]))
FIXTAB <- data.frame(point = names(PTS), fix = vapply(FIXPTS, `[[`, 0, "logpost"), ss_fix = vapply(FIXPTS, `[[`, 0L, "ss"),
                     converged = vapply(names(PTS), function(nm) lpk(nm, kmax), 0))
FIXTAB$d_vs_converged <- FIXTAB$fix - FIXTAB$converged
OUT$fix_points <- FIXTAB; save_out()
print(FIXTAB, digits = 10, row.names = FALSE)
pair_fix <- vapply(SC_DIRS, function(n) (FIXTAB$fix[FIXTAB$point == paste0(n, "+")] - FIXTAB$fix[FIXTAB$point == "s017"]) +
                                         (FIXTAB$fix[FIXTAB$point == paste0(n, "-")] - FIXTAB$fix[FIXTAB$point == "s017"]), 0)
cat(sprintf("  under the fix the three pair sums are %s (flag > %g) and every point agrees with its converged value to %.1e\n",
            paste(sprintf("%s %+.3f", SC_DIRS, pair_fix), collapse = ", "), SC_SMOOTH_TOL, max(abs(FIXTAB$d_vs_converged))))
stopifnot(all(abs(pair_fix) <= SC_SMOOTH_TOL), all(abs(FIXTAB$d_vs_converged) < SC_CONV_TOL))
# THE GATE A FIX WOULD SHIP WITH, and its MUTATION: "the controller's count keeps the integrator's own
# stiffness inside the RK4 limit" -- PASSES under the fix over the whole edge scan and FAILS under the
# shipped controller (so it has power on exactly the case that broke).
gate <- function(E, which) all(E[, which] <= SC_LIMIT)
g_fix <- gate(EDGE$s017[EDGE$s017[, "need_fix"] <= CCX_SUBSTEPS_MAX, , drop = FALSE], "z_fix")
g_now <- gate(EDGE$s017, "z_shipped")
cat(sprintf("  the proposed gate on the edge scan: fix %s, shipped %s (must be PASS / FAIL)\n",
            if (g_fix) "PASS" else "FAIL", if (g_now) "PASS" else "FAIL"))
stopifnot(g_fix, !g_now)

# ---- 6. the straight line, converged ---------------------------------------------------------
cat(sprintf("\n=== 6. THE STRAIGHT LINE 017 -> MODE at x%d (10-03 e read it at the controller's count) ===\n", SC_LINE_MULT))
LINE <- in_arm(md, function(lp, u, bp) t(vapply(SC_LINE_T, function(t) {
  x <- u0 + t * (u_mode - u0)
  a <- ev(lp, x); b <- with_ss(list(type = "mult", k = SC_LINE_MULT), ev(lp, x))
  c(t = t, ctrl = a$logpost, ss_ctrl = a$ss, refined = b$logpost) }, numeric(4))))
OUT$line <- LINE; save_out()
cat(sprintf("  t:        %s\n  ctrl:     %s\n  x%d:       %s\n", paste(sprintf("%9.2f", LINE[, "t"]), collapse = ""),
            paste(sprintf("%9.1f", LINE[, "ctrl"]), collapse = ""), SC_LINE_MULT, paste(sprintf("%9.1f", LINE[, "refined"]), collapse = "")))
dip <- LINE[1, "refined"] - min(LINE[, "refined"])
cat(sprintf("  converged: start %.2f, min %.2f (dip %.2f below the start), end %.2f; %s\n", LINE[1, "refined"], min(LINE[, "refined"]),
            max(0, dip), LINE[nrow(LINE), "refined"],
            if (all(diff(LINE[, "refined"]) >= -1e-3)) "MONOTONE RISE" else "not monotone"))
save_out()
cat(sprintf("\nwrote %s.{log,rds}\n", SC_OUT))
sink()
