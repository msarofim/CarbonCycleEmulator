#!/usr/bin/env Rscript
# =====================================================================
# diag_obj15_refit_read.R -- READING THE OBJECTIVE-#15 REFIT (2026-10-03; handoff
# notes/handoff_2026-10-03_obj15_refit.md §5 step 3, on the model of diag_obj14_refit_read.R).
#
# THE REFIT (CHANGELOG 10-02 ee): two arms on objective #15, 24 dispersed starts each on the Mac,
# from frozen worktrees at 3fc5dca, each promoted (GATES 1-5) with its Hessian recomputed:
#   LAG arm      hilda_csl3v0kaidgbe -- 34 free: the 33 + lag_enso_land (W1, DESIGN's L_MEI);
#   CONTROL arm  hilda_csl3v0kaidgb  -- 33 free: the lag gate CLOSED, i.e. lag 0 (ruled D2).
# THE INCUMBENT is hilda33d: the #14 optimum RESTAMPED under #15 (10-02 cc). It is the pre-refit
# baseline, NOT an optimum of #15, so "refit - incumbent" is what re-fitting bought on #15's rows.
#
# WHAT IT READS (the handoff's list):
#   1. THE SURVEYS: how many starts converged, how tightly they agree, what separates the top two
#      clusters, and start 017 (OUT OF TIME at -1319.6): how far from the best, coordinate by
#      coordinate, and which rows it loses.
#   2. THE LAG: its value, its Laplace sd (marginal and conditional), what it trades with; the land
#      ENSO amplitudes at the three vectors.
#   3. THE ARMS ON LIKELIHOOD. ⛔ Never on stored logposts: the lag arm's carries the lag's flat
#      prior and its logit Jacobian, which the control's cannot. Same rows (asserted), the lag's AIC
#      worth at ONE extra name, and each arm against the incumbent.
#   4. WHICH ROWS THE LAG BUYS: lag - control, row by row, beside D3's conditional profile (10-02 dd,
#      lag_profile_obj15_20261002.rds), which predicted the pull from gcb_land_sink and the SPO rows.
#   5. WHY k_w STAYED HIGH (~1900 m/yr against Naegler 2009's 1446):
#      (a) THE PULL: each row's d(row)/d(log k_w) at each arm's mode, by central difference. > 0 =
#          the row wants FASTER gas exchange. Rows + prior + Jacobian must sum to ~0 at an optimum:
#          a built-in check that the point IS a mode in this direction.
#      (b) a CONDITIONAL profile toward 1446 (every other name held): what each row pays.
#      (c) THE RIDGE (Laplace): which names move with k_w when it moves, and the marginal cost of
#          1446 = 0.5 z^2 on the MARGINAL sd. ⚠ Linear; (b) overstates and (c) approximates the
#          profile likelihood, which only a re-optimisation at fixed k_w could measure.
#   6. THE TIMING the lag buys: the model's monthly growth against Nino 3.4, D3's P3 estimator
#      verbatim (observed: growth peaks 5 months after the index, 10-02 x).
#   7. THE FUTURES the app would show: van Vuuren L / M / H CO2 at 2100 and 2300 (history spliced
#      in, as app_run_coupled() does), and SSP5-8.5 at 2300 unspliced (= 10-01 a's convention).
#   8. WHICH PARAMETERS carry the lag - control futures move (added 2026-10-03 g): every fitted name in
#      exactly one group, each group SWAPPED both ways between the two arms (control + the lag's group =
#      add-one; lag - the group = remove-one), diag_obj14_refit_read.R's method; the likelihood-only group
#      must move the futures by EXACTLY 0.
# ⛔ ADOPTS NOTHING. No RNG.
# Usage: Rscript calibration/diag_obj15_refit_read.R
#   CCX_RD15_CTL=<mode path or name> replaces the control -- an INTERIM read before the control arm
#   has landed. The output tag and every header then SAY that the control is a stand-in.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
RD_DRIVER    <- "calibration/diag_obj15_refit_read.R"
RD_LABEL_LAG <- "hilda_csl3v0kaidgbe"
RD_LABEL_CTL <- "hilda_csl3v0kaidgb"
RD_WAVE_TAIL <- paste0("_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0",
                       "_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452_sdby_npp_tsens=0.0291")
RD_LAG_WAVE  <- file.path("calibration", "output", paste0("multistart_20261002ee_", RD_LABEL_LAG, RD_WAVE_TAIL))
RD_CTL_WAVE  <- file.path("calibration", "output", paste0("multistart_20261002ee_", RD_LABEL_CTL, RD_WAVE_TAIL))
# the lag arm, REGISTERED as `hilda34g` and adopted 2026-10-03 (h); its directory was renamed then from
# refit_20261003_obj15_hilda_csl3v0kaidgbe (the path the 10-03 (b)-(g) outputs record)
RD_LAG_MODE  <- ccx_mode_file("hilda34g")
RD_CTL_MODE_FINAL <- file.path("calibration", "output", "refit_20261003_obj15_hilda_csl3v0kaidgb", "mode_fit_pumpN.rds")
RD_CTL_MODE  <- local({ v <- Sys.getenv("CCX_RD15_CTL", ""); if (nzchar(v)) v else RD_CTL_MODE_FINAL })
RD_INTERIM   <- !identical(RD_CTL_MODE, RD_CTL_MODE_FINAL)
RD_INC       <- "hilda33d"                      # the incumbent, restamped under #15 (10-02 cc)
RD_LAG       <- "lag_enso_land"
RD_AMP       <- c("gamma_enso_land_NH", "gamma_enso_land_SH")
RD_KW        <- "k_w"
RD_KW_LIT    <- ccx_const("KW_PRIOR_CENTRE")    # 1446 m/yr, Naegler 2009 (R/constants.R)
RD_KW_GRID   <- c(RD_KW_LIT, 1550, 1650, 1750, 1850, 2000, 2100)   # m/yr, the conditional profile (5b)
RD_KW_H_FRAC <- 0.1                             # central-difference half-step = 0.1 x each arm's CONDITIONAL sd of
                                                #   log k_w: recompute_hessian.R's own step convention (a fixed 1 %
                                                #   was 2 conditional sds, outside the quadratic region)
RD_MODE_TOL  <- 0.1                             # a point is a mode in k_w if the conditional optimum along k_w lies
                                                #   < 0.1 CONDITIONAL sd away (= |gradient| x sd_cond): scaled to the
                                                #   arm's own curvature, not a typed slope
# the rows that read each hemisphere's box (R/likelihood.R: MLO = the NH box, SPO = the SH box; d14c_intcal
# interpolates d14c_NH; both ice-core rows read the SH box, Law Dome being at 66.7 S)
RD_NH_ROWS   <- c("co2_level_MLO", "co2_seasonal_MLO", "d13c_level_MLO", "d13c_seasonal_MLO", "d14c_NH", "d14c_intcal")
RD_SH_ROWS   <- c("co2_level_SPO", "co2_seasonal_SPO", "d13c_level_SPO", "d13c_seasonal_SPO", "d14c_SH", "co2_icecore", "d13c_icecore")
RD_PULL_PER  <- log(1.1)                        # pulls are printed per +10 % in k_w
RD_CMH_TO_MYR <- 0.01 * 8766                    # 1 cm/h = 87.66 m/yr (Naegler's 16.5 cm/h = 1446)
RD_REPRO_TOL <- 1e-6                            # log-units: a mode reproduces its stored logpost
RD_AIC_K     <- 1L                              # the lag arm fits one more name than the control
RD_STUCK_ID  <- 17L                             # the lag arm's far start (handoff §4)
# ...and its RESUME (2026-10-03 c-d): the same driver continued from its own checkpoint, fresh wall, nice'd
RD_STUCK_RESUME <- file.path("calibration", "output", paste0("resume017_20261003_", RD_LABEL_LAG, RD_WAVE_TAIL), "start_017.rds")
RD_LINE_T    <- seq(0, 1, by = 0.05)            # the straight line from the stuck point (t = 0) to the mode (t = 1)
RD_LINE_TOL  <- 1e-3                            # log-units: a dip below the start counts as a BARRIER past this (the
                                                #   objective's roundoff floor is ~4e-6; 250x it)
RD_GRAD_FRAC <- 0.1                             # smoothness probe: a step of 0.1 x each name's CONDITIONAL sd at the mode
RD_SMOOTH_TOL <- 1                              # log-units: |d_up + d_dn| past this flags a NON-SMOOTH direction. On a
                                                #   smooth bowl the pair sums to -RD_GRAD_FRAC^2 = -0.01 at the mode's own
                                                #   curvature, so the tolerance is 100x the smooth expectation
RD_TOP_N     <- 10L
RD_D3_FILE   <- file.path("outputs", "diagnostics", "lag_profile_obj15_20261002.rds")
RD_D3_LAG    <- 2.5                             # D3's best L on the likelihood (10-02 dd)
RD_WIN       <- c(1980L, 2024L)                 # = D3's P3 window (= 10-02 x)
RD_TREND_DF  <- 5L
RD_XLAGS     <- -6:18                           # months; > 0 = Nino 3.4 LEADS growth
RD_OBS_WEEKLY <- file.path("data-raw", "downloads", "mbl_zonal_co2_GL.txt")
RD_FUT_SPLICE <- c(vvL = TRUE, vvM = TRUE, vvH = TRUE, ssp585 = FALSE)
RD_FUT_YEARS  <- c(2100L, 2300L)
RD_TAG  <- sprintf("%s%s", format(Sys.Date(), "%Y%m%d"), if (RD_INTERIM) "_INTERIM" else "")
RD_OUT  <- file.path("outputs", "diagnostics", sprintf("obj15_refit_read_%s", RD_TAG))
COMMIT  <- ccx_git_stamp()
stopifnot(isTRUE(LIK_USE_ICE_D13C), identical(LIK_ICE_CO2_END, 1958))      # objective #15
sink(paste0(RD_OUT, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s\n", RD_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  lag arm  %s\n  control  %s%s\n  incumbent %s (%s)\n", RD_LAG_MODE, RD_CTL_MODE,
            if (RD_INTERIM) "   ⚠ INTERIM: a STAND-IN for the control arm, which has not landed" else "",
            RD_INC, ccx_mode_file(RD_INC)))

OBS <- ccx_prepare_obs()
# One arm's own space: its gate and pins (ccx_apply_pins of a gated file's pins opens the gate
# first and ccx_unpin_params() closes it), its base, its spinup, its objective. Everything that
# encodes or decodes a `u` happens inside, because the table itself moves between arms.
in_arm <- function(md, f) {
  r <- ccx_apply_pins(ccx_mode_pins(md))
  on.exit(ccx_unpin_params(r), add = TRUE)
  stopifnot(identical(md$param_names, CCX_PARAM_NAMES))
  bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
  spf <- ccx_spinup_from_label(ccx_mode_spinup(md))
  lp  <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = spf, obs = OBS)
  invisible(utils::capture.output(st <- ccx_mode_start(md, "obj15 read")))
  stopifnot(length(st$absent) == 0L, st$logpost_shift == 0)
  f(lp, st$u, bp)
}
ev <- function(lp, u) { v <- lp(u); s <- unlist(attr(v, "streams")); list(logpost = as.numeric(v), streams = s, lik = sum(s)) }
# the file's Hessian statistics, NAMED (the stored vectors carry no names)
fit_stats <- function(md) { fs <- ccx_mode_fit_stats(md); nm <- fs$param_names
  fs$sd <- stats::setNames(as.numeric(fs$sd), nm); fs$sd_conditional <- stats::setNames(as.numeric(fs$sd_conditional), nm)
  dimnames(fs$cov) <- list(nm, nm); fs }

ARMS <- list(lag = RD_LAG_MODE, control = RD_CTL_MODE, incumbent = RD_INC)
MD <- lapply(ARMS, function(a) readRDS(ccx_mode_file(a)))
stopifnot(identical(ccx_mode_struct(MD$lag), RD_LABEL_LAG),
          RD_INTERIM || identical(ccx_mode_struct(MD$control), RD_LABEL_CTL),
          identical(ccx_mode_struct(MD$incumbent), RD_LABEL_CTL))

# ---- 0. each vector reproduces its own stored logpost ------------------------------------------
cat(sprintf("\n=== 0. EACH VECTOR REPRODUCES ITS STORED LOGPOST (tol %g) ===\n", RD_REPRO_TOL))
E <- lapply(names(MD), function(a) in_arm(MD[[a]], function(lp, u, bp) {
  e <- ev(lp, u); prior <- e$logpost - e$lik
  lag_term <- if (RD_LAG %in% names(u)) { s <- CCX_PARAM_TABLE[[RD_LAG]]
    .ccx_prior_eval(s, ccx_unc_to_par(u)[[RD_LAG]], bp) + .log_jac(u[[RD_LAG]], s) } else 0
  pz <- vapply(names(u), function(n) tryCatch(ccx_prior_z(n, ccx_unc_to_par(u)[[n]], p = bp), error = function(e) NA_real_), 0)
  c(e, list(prior = prior, lag_term = lag_term, prior_z = pz, u = u, par = ccx_unc_to_par(u)))
}))
names(E) <- names(MD)
for (a in names(E)) {
  d <- E[[a]]$logpost - MD[[a]]$logpost
  cat(sprintf("  %-9s %-20s %2d free  logpost %.6f (stored %.6f, diff %+.1e)  likelihood %.4f on %d rows  prior+Jacobian %.4f%s\n",
              a, ccx_mode_struct(MD[[a]]), length(E[[a]]$u), E[[a]]$logpost, MD[[a]]$logpost, d, E[[a]]$lik,
              length(E[[a]]$streams), E[[a]]$prior,
              if (E[[a]]$lag_term != 0) sprintf(" (of it the lag's flat prior + logit Jacobian %.4f)", E[[a]]$lag_term) else ""))
  if (!(abs(d) <= RD_REPRO_TOL)) stop(a, " does NOT reproduce its stored logpost: nothing below can be read off it")
}
rows <- names(E$lag$streams)
stopifnot(setequal(rows, names(E$control$streams)), setequal(rows, names(E$incumbent$streams)))
cat(sprintf("  the three vectors score the SAME %d rows\n", length(rows)))

# ---- 1. the surveys ------------------------------------------------------------------------------
cat("\n=== 1. THE SURVEYS (start files; the collector's own verdict is in each wave's collect log) ===\n")
read_wave <- function(dir) {
  if (!dir.exists(dir)) return(NULL)
  fs <- sort(list.files(dir, pattern = "^start_[0-9]+[.]rds$", full.names = TRUE))
  S <- lapply(fs, readRDS); names(S) <- vapply(S, function(s) sprintf("%03d", s$id), "")
  S
}
W <- list(lag = read_wave(RD_LAG_WAVE), control = if (RD_INTERIM) NULL else read_wave(RD_CTL_WAVE))
SURV <- list()
for (a in names(W)) {
  S <- W[[a]]
  if (is.null(S)) { cat(sprintf("  %-8s (no wave read%s)\n", a, if (RD_INTERIM && a == "control") ": INTERIM" else "")); next }
  tb <- data.frame(id = vapply(S, `[[`, 0L, "id"), logpost = vapply(S, `[[`, 0, "logpost"),
                   converged = vapply(S, function(s) isTRUE(s$converged), TRUE),
                   out_of_time = vapply(S, function(s) isTRUE(s$out_of_time), TRUE),
                   minutes = vapply(S, `[[`, 0, "minutes"), tol = vapply(S, `[[`, 0, "cycle_tol"))
  best <- max(tb$logpost[tb$converged]); tb$gap <- best - tb$logpost
  SURV[[a]] <- tb
  cat(sprintf("  %-8s %d starts, %d CONVERGED, %d OUT OF TIME; best converged %.4f; within the cycle tol (%.2g) of it: %d; within 0.01: %d; within 0.2: %d\n",
              a, nrow(tb), sum(tb$converged), sum(tb$out_of_time), best, tb$tol[1], sum(tb$gap <= tb$tol[1]),
              sum(tb$gap <= 0.01), sum(tb$gap <= 0.2)))
  cat(sprintf("           the rest: %s\n", paste(sprintf("%03d %.2f%s", tb$id, -tb$gap, ifelse(tb$out_of_time, " (OOT)", ""))[tb$gap > 0.2], collapse = ", ")))
}
# what separates the top two clusters of the LAG wave, coordinate by coordinate, in Laplace sds
fsL <- fit_stats(MD$lag)
stopifnot(identical(fsL$param_names, names(E$lag$u)), isTRUE(MD$lag$pd))
sep_by_coord <- function(u1, u0, sd) { d <- (u1 - u0)[names(sd)] / sd; d[order(-abs(d))] }
# Every distinct LEVEL (converged starts, logpost rounded to 0.01) and every start that ran out of time,
# against the best: the coordinates that separate them, in the best mode's MARGINAL Laplace sds. The
# collector counts BASINS by a u-space radius; this says WHAT each one is (#14's second "basin" was h_ml
# alone, the 09-28e near-degeneracy).
LEVELS <- list()
for (a in names(W)) {
  S <- W[[a]]; if (is.null(S)) next
  tb <- SURV[[a]]; md_a <- MD[[a]]; fs_a <- if (a == "lag") fsL else fit_stats(md_a)
  ib <- sprintf("%03d", tb$id[tb$converged][which.max(tb$logpost[tb$converged])])
  cl <- split(tb$id[tb$converged], round(tb$logpost[tb$converged], 2)); cl <- cl[order(-as.numeric(names(cl)))]
  cat(sprintf("  %s converged levels (logpost to 0.01): %s\n", toupper(a), paste(sprintf("%s x%d", names(cl), lengths(cl)), collapse = ", ")))
  reps <- c(vapply(cl[-1], function(ids) sprintf("%03d", ids[1]), ""), sprintf("%03d", tb$id[tb$out_of_time]))
  for (i in reps) {
    d <- sep_by_coord(S[[i]]$u_mode, S[[ib]]$u_mode, fs_a$sd)
    LEVELS[[paste(a, i)]] <- list(arm = a, id = as.integer(i), logpost = S[[i]]$logpost, d_coord = d)
    cat(sprintf("    id %s (%.4f, %s; %+.4f vs id %s): %s\n      natural: %s\n", i, S[[i]]$logpost,
                if (isTRUE(S[[i]]$out_of_time)) "OUT OF TIME" else "converged", S[[i]]$logpost - S[[ib]]$logpost, ib,
                paste(sprintf("%s %+.1f sd", names(d), d)[1:6], collapse = ", "),
                paste(vapply(names(d)[1:3], function(n) sprintf("%s %.4g -> %.4g", n, S[[ib]]$par_mode[[n]], S[[i]]$par_mode[[n]]), ""), collapse = "; ")))
  }
}

# start 017: where it is, and which rows it loses -- at its RESUMED final point when the resume exists
STUCK <- NULL
if (!is.null(W$lag) && sprintf("%03d", RD_STUCK_ID) %in% names(W$lag)) {
  s17 <- W$lag[[sprintf("%03d", RD_STUCK_ID)]]
  if (file.exists(RD_STUCK_RESUME)) {
    s17r <- readRDS(RD_STUCK_RESUME)
    stopifnot(identical(s17r$param_names, s17$param_names), isTRUE(s17r$resumed))
    cat(sprintf("\n  START %03d was RESUMED (%s): %.4f -> %.4f, %s after %.0f more min (%d evals in all, %.2f s/eval)\n",
                RD_STUCK_ID, dirname(RD_STUCK_RESUME), s17$logpost, s17r$logpost,
                if (isTRUE(s17r$converged)) "CONVERGED" else if (isTRUE(s17r$out_of_time)) "OUT OF TIME again" else "stopped",
                s17r$minutes, s17r$n_eval, s17r$sec_per_eval))
    s17 <- s17r
  }
  d17 <- sep_by_coord(s17$u_mode, E$lag$u, fsL$sd)
  e17 <- in_arm(MD$lag, function(lp, u, bp) { stopifnot(identical(names(s17$u_mode), names(u))); ev(lp, s17$u_mode) })
  dr  <- e17$streams[rows] - E$lag$streams[rows]; dr <- dr[order(dr)]
  cat(sprintf("\n  START %03d: %s, %s after %.0f min (%d evals, %.2f s/eval); logpost %.4f = %.2f below the mode (likelihood %+.2f, prior+Jacobian %+.2f)\n",
              RD_STUCK_ID, if (isTRUE(s17$converged)) "CONVERGED" else "NOT converged", if (isTRUE(s17$out_of_time)) "OUT OF TIME" else "in time",
              s17$minutes, s17$n_eval, s17$sec_per_eval, e17$logpost, E$lag$logpost - e17$logpost, e17$lik - E$lag$lik,
              (e17$logpost - e17$lik) - E$lag$prior))
  tr <- s17$trace; g17 <- diff(tr$logpost); lab <- sprintf("c%d/r%d", tr$cycle[-1], tr$restart[-1])
  cat(sprintf("    its gains, step by step: %s\n", paste(sprintf("%s %+.2f", lab, g17), collapse = ", ")))
  cat(sprintf("    furthest coordinates from the mode (marginal sds): %s\n", paste(sprintf("%s %+.1f", names(d17), d17)[1:RD_TOP_N], collapse = ", ")))
  cat(sprintf("    rows it loses most: %s\n", paste(sprintf("%s %+.2f", names(dr), dr)[1:8], collapse = ", ")))
  # IS IT A BASIN? Two cheap tests on the objective itself (no optimiser):
  #  (1) the STRAIGHT LINE to the mode: a dip below the start (past RD_LINE_TOL) is a barrier on that
  #      line -- consistent with a separate basin (a curved path could still avoid it); a monotone
  #      rise says the point is on the main basin's slope and the optimiser was merely slow;
  #  (2) SMOOTHNESS at the point: a step of RD_GRAD_FRAC conditional sds along each name, both ways. On a
  #      smooth surface the two moves nearly cancel (d_up + d_dn = -RD_GRAD_FRAC^2 at the mode's own curvature);
  #      |d_up + d_dn| > RD_SMOOTH_TOL flags a NON-SMOOTH direction -- a regime edge or a numerical singularity,
  #      where a simplex stalls. (A raw central gradient is the wrong instrument there: at 017 it read -1.5e38.)
  lt <- in_arm(MD$lag, function(lp, u, bp) {
    u0 <- s17$u_mode; u1 <- u
    line <- t(vapply(RD_LINE_T, function(t) { e <- tryCatch(ev(lp, u0 + t * (u1 - u0)), error = function(x) list(logpost = NA_real_, lik = NA_real_))
      c(t = t, logpost = e$logpost, lik = e$lik) }, numeric(3)))
    sdc <- fsL$sd_conditional[names(u0)]; e0 <- ev(lp, u0)
    sm <- lapply(names(u0), function(n) { h <- RD_GRAD_FRAC * sdc[[n]]; up <- u0; dn <- u0; up[[n]] <- up[[n]] + h; dn[[n]] <- dn[[n]] - h
      bad <- list(logpost = -Inf, streams = e0$streams * NA, lik = NA_real_)       # an evaluation that ERRORS
      eu <- tryCatch(ev(lp, up), error = function(x) bad); ed <- tryCatch(ev(lp, dn), error = function(x) bad)
      jump <- if (abs(eu$logpost - e0$logpost) >= abs(ed$logpost - e0$logpost)) eu$streams - e0$streams else ed$streams - e0$streams
      list(d_up = eu$logpost - e0$logpost, d_dn = ed$logpost - e0$logpost, row = names(jump)[which.max(abs(jump))], row_d = jump[which.max(abs(jump))]) })
    names(sm) <- names(u0)
    list(line = line, smooth = sm)
  })
  ln <- lt$line; dip <- ln[1, "logpost"] - min(ln[, "logpost"], na.rm = TRUE)
  mono <- all(diff(ln[, "logpost"]) >= -RD_LINE_TOL, na.rm = TRUE)
  cat(sprintf("    (1) the straight line to the mode (t = 0 the stuck point, 1 the mode), logpost: %s\n",
              paste(sprintf("%.2f", ln[c(1, 3, 5, 7, 9, 11, 15, 21), "logpost"]), collapse = " ")))
  cat(sprintf("        largest dip below the start %.4f; %s\n", max(0, dip),
              if (mono) "MONOTONE RISE: the point is on the main basin's slope -- a STUCK start, not a second basin"
              else if (dip > RD_LINE_TOL) "a BARRIER on the line: consistent with a SEPARATE basin" else "not monotone, but no dip below the start"))
  smt <- data.frame(name = names(lt$smooth), d_up = vapply(lt$smooth, `[[`, 0, "d_up"), d_dn = vapply(lt$smooth, `[[`, 0, "d_dn"),
                    row = vapply(lt$smooth, `[[`, "", "row"), row_d = vapply(lt$smooth, function(x) unname(x$row_d), 0))
  smt$pair_sum <- smt$d_up + smt$d_dn; smt$slope_x_sd <- (smt$d_up - smt$d_dn) / (2 * RD_GRAD_FRAC)
  rough <- smt[abs(smt$pair_sum) > RD_SMOOTH_TOL, ]; rough <- rough[order(-abs(rough$pair_sum)), ]
  cat(sprintf("    (2) smoothness, %g conditional sd each way: %d of %d directions NON-SMOOTH (|d_up + d_dn| > %g; a smooth bowl gives %.2f)\n",
              RD_GRAD_FRAC, nrow(rough), nrow(smt), RD_SMOOTH_TOL, -RD_GRAD_FRAC^2))
  if (nrow(rough)) for (i in seq_len(min(6L, nrow(rough)))) with(rough[i, ], cat(sprintf(
    "        %-16s up %s  down %s   the row that jumps: %s %s\n", name, format(d_up, digits = 4), format(d_dn, digits = 4), row, format(row_d, digits = 4))))
  smooth_ok <- smt[abs(smt$pair_sum) <= RD_SMOOTH_TOL, ]
  cat(sprintf("        on the %d smooth directions, slope x conditional sd: largest %s\n", nrow(smooth_ok),
              paste(sprintf("%s %+.2f", smooth_ok$name, smooth_ok$slope_x_sd)[order(-abs(smooth_ok$slope_x_sd))][1:4], collapse = ", ")))
  STUCK <- list(id = RD_STUCK_ID, logpost = e17$logpost, lik = e17$lik, d_coord = d17, d_rows = dr, trace = tr,
                resumed = file.exists(RD_STUCK_RESUME), line = ln, line_dip = dip, line_monotone = mono, smoothness = smt)
}

# ---- 2. the lag -----------------------------------------------------------------------------------
cat("\n=== 2. THE LAG AND THE LAND ENSO AMPLITUDES ===\n")
specL <- CCX_PARAM_GATED_ALL[[RD_LAG]]
L  <- E$lag$par[[RD_LAG]]; pL <- plogis(E$lag$u[[RD_LAG]]); dxdu <- (specL$hi - specL$lo) * pL * (1 - pL)
sdL <- fsL$sd[[RD_LAG]] * dxdu; sdLc <- fsL$sd_conditional[[RD_LAG]] * dxdu
corL <- stats::cov2cor(fsL$cov)[RD_LAG, ]; corL <- corL[setdiff(names(corL), RD_LAG)]; corL <- corL[order(-abs(corL))]
cat(sprintf("  %s = %.3f months; Laplace sd %.3f (marginal) / %.3f (conditional) months; prior U(%g, %g) on a logit; D3's conditional profile best %g\n",
            RD_LAG, L, sdL, sdLc, specL$lo, specL$hi, RD_D3_LAG))
cat(sprintf("  ±2 marginal sd: [%.2f, %.2f] months (linear on the natural scale; the logit's own interval is [%.2f, %.2f])\n",
            L - 2 * sdL, L + 2 * sdL, specL$lo + (specL$hi - specL$lo) * plogis(E$lag$u[[RD_LAG]] - 2 * fsL$sd[[RD_LAG]]),
            specL$lo + (specL$hi - specL$lo) * plogis(E$lag$u[[RD_LAG]] + 2 * fsL$sd[[RD_LAG]])))
cat(sprintf("  its largest posterior correlations: %s\n", paste(sprintf("%s %+.2f", names(corL), corL)[1:6], collapse = ", ")))
amp <- sapply(E, function(e) unlist(e$par[RD_AMP]))
print(round(amp, 4))
cat(sprintf("  marginal sd of the amplitudes at the lag arm: NH %.4f, SH %.4f (u = natural, tr id)\n",
            fsL$sd[[RD_AMP[1]]], fsL$sd[[RD_AMP[2]]]))

# ---- 3. the arms on likelihood ----------------------------------------------------------------------
cat("\n=== 3. THE ARMS ON LIKELIHOOD (same rows; never the stored logposts) ===\n")
lk <- vapply(E, `[[`, 0, "lik")
cat(sprintf("  likelihood: lag %.4f, control %.4f, incumbent %.4f\n", lk[["lag"]], lk[["control"]], lk[["incumbent"]]))
dLC <- lk[["lag"]] - lk[["control"]]
cat(sprintf("  lag - control = %+.4f at %d more name(s) => dAIC (lag vs control) = 2*%d - 2*(%+.4f) = %+.2f %s\n",
            dLC, RD_AIC_K, RD_AIC_K, dLC, 2 * RD_AIC_K - 2 * dLC,
            if (RD_INTERIM) "(⚠ INTERIM: against a STAND-IN that was not re-fitted on #15 -- NOT the lag's AIC worth)"
            else if (2 * RD_AIC_K - 2 * dLC < -2) "(the lag EARNS its parameter)" else if (2 * RD_AIC_K - 2 * dLC < 2) "(a tie under the < 2 convention)" else "(the lag does NOT earn its parameter)"))
cat(sprintf("  control - incumbent = %+.4f (re-fitting on #15 at the same 33 names); lag - incumbent = %+.4f\n",
            lk[["control"]] - lk[["incumbent"]], lk[["lag"]] - lk[["incumbent"]]))
cat(sprintf("  (stored logposts, NOT comparable, shown for the record: lag %.4f, control %.4f, incumbent %.4f)\n",
            E$lag$logpost, E$control$logpost, E$incumbent$logpost))

# ---- 4. which rows the lag buys ----------------------------------------------------------------------
cat("\n=== 4. WHICH ROWS THE LAG BUYS (lag - control), beside D3's conditional move at L = 2.5 ===\n")
dRow <- E$lag$streams[rows] - E$control$streams[rows]
d3 <- tryCatch(readRDS(RD_D3_FILE), error = function(e) NULL)
d3c <- if (!is.null(d3)) d3$streams[, sprintf("L%g", RD_D3_LAG)] else NULL
tab4 <- data.frame(row = rows, lag_minus_control = round(dRow, 3),
                   control_minus_incumbent = round(E$control$streams[rows] - E$incumbent$streams[rows], 3),
                   d3_conditional = if (is.null(d3c)) NA else round(unname(d3c[rows]), 3))
tab4 <- tab4[order(-abs(tab4$lag_minus_control)), ]
print(tab4, row.names = FALSE)
if (is.null(d3)) cat("  ⚠ D3's profile file is missing: its column is NA\n") else
  cat(sprintf("  (D3's column is CONDITIONAL: hilda33d with only the two land amplitudes re-optimised, at L = %g vs L = 0)\n", RD_D3_LAG))

# ---- 5. why k_w stayed high ----------------------------------------------------------------------------
cat(sprintf("\n=== 5. WHY k_w STAYED HIGH (Naegler 2009: %g m/yr) ===\n", RD_KW_LIT))
fsC <- lapply(MD, fit_stats)
KW <- lapply(names(MD), function(a) in_arm(MD[[a]], function(lp, u, bp) {
  s <- CCX_PARAM_TABLE[[RD_KW]]; stopifnot(identical(s$tr, "log"))
  h <- RD_KW_H_FRAC * fsC[[a]]$sd_conditional[[RD_KW]]
  up <- u; dn <- u; up[[RD_KW]] <- u[[RD_KW]] + h; dn[[RD_KW]] <- u[[RD_KW]] - h
  eu <- ev(lp, up); ed <- ev(lp, dn)
  pull <- (eu$streams[rows] - ed$streams[rows]) / (2 * h)
  pull_prior <- ((eu$logpost - eu$lik) - (ed$logpost - ed$lik)) / (2 * h)
  prof <- t(vapply(RD_KW_GRID, function(k) { uu <- u; uu[[RD_KW]] <- .to_unc(k, s); e <- ev(lp, uu)
    c(k_w = k, lik = e$lik, prior = e$logpost - e$lik, e$streams[rows]) }, numeric(3 + length(rows))))
  list(pull = pull, pull_prior = pull_prior, profile = prof, h = h)
}))
names(KW) <- names(MD)
for (a in names(MD)) {
  k <- E[[a]]$par[[RD_KW]]; sdk <- fsC[[a]]$sd[[RD_KW]]; sdkc <- fsC[[a]]$sd_conditional[[RD_KW]]
  zlit <- (log(k) - log(RD_KW_LIT)) / sdk
  cat(sprintf("  %-9s k_w %.1f m/yr (%.1f cm/h) = %+.1f %% vs %g; prior z %+.2f; Laplace sd %.2f %% marginal / %.2f %% conditional => %g is %.1f MARGINAL sds away (Laplace cost 0.5 z^2 = %.1f log-units)%s\n",
              a, k, k / RD_CMH_TO_MYR, 100 * (k / RD_KW_LIT - 1), RD_KW_LIT, E[[a]]$prior_z[[RD_KW]], 100 * sdk, 100 * sdkc, RD_KW_LIT,
              zlit, 0.5 * zlit^2, if (a == "incumbent") " [its Hessian is #14's: a restamp recomputes no Hessian]" else ""))
}
cat(sprintf("\n  (a) THE PULL at each mode: d(row)/d(log k_w), printed per +10 %% in k_w (x %.4f); > 0 = the row wants FASTER exchange\n", RD_PULL_PER))
PULL <- sapply(KW, `[[`, "pull") * RD_PULL_PER
pp   <- vapply(KW, `[[`, 0, "pull_prior") * RD_PULL_PER
ordr <- order(-abs(PULL[, "lag"]))
print(round(PULL[ordr, ], 3))
cat(sprintf("  prior + Jacobian: %s\n", paste(sprintf("%s %+.3f", names(pp), pp), collapse = ", ")))
tot <- colSums(PULL) + pp
off <- vapply(names(MD), function(a) abs(tot[[a]] / RD_PULL_PER) * fsC[[a]]$sd_conditional[[RD_KW]], 0)
cat(sprintf("  rows + prior, per 10 %% (half-steps %s in log k_w): %s\n", paste(signif(vapply(KW, `[[`, 0, "h"), 3), collapse = " / "),
            paste(sprintf("%s %+.4f", names(tot), tot), collapse = ", ")))
cat(sprintf("  => the conditional optimum along k_w lies %s CONDITIONAL sd from each point (a mode: < %g)\n",
            paste(sprintf("%s %.3f", names(off), off), collapse = ", "), RD_MODE_TOL))
GRP <- list(`NH-box rows` = RD_NH_ROWS, `SH-box rows` = RD_SH_ROWS, `every other row` = setdiff(rows, c(RD_NH_ROWS, RD_SH_ROWS)))
stopifnot(all(unlist(GRP) %in% rows))
gp <- t(vapply(GRP, function(r) colSums(PULL[r, , drop = FALSE]), numeric(ncol(PULL))))
gp <- rbind(gp, `prior + Jacobian` = pp)
cat("  the pulls BY HEMISPHERIC BOX (per +10 % in k_w):\n"); print(round(gp, 2))
cat(sprintf("  rows pulling UP (lag arm): %+.2f in all; DOWN: %+.2f; the prior: %+.2f\n",
            sum(PULL[PULL[, "lag"] > 0, "lag"]), sum(PULL[PULL[, "lag"] < 0, "lag"]), pp[["lag"]]))
for (a in c("lag", if (!RD_INTERIM) "control")) if (off[[a]] > RD_MODE_TOL)
  cat(sprintf("  ⚠ the %s refit is NOT a mode along k_w at this tolerance: read its pulls as a slope at a point\n", a))
cat(sprintf("\n  (b) CONDITIONAL profile at the LAG mode (every other name held), d vs the mode, rows with |d| > 1 anywhere:\n"))
pf <- KW$lag$profile; dP <- sweep(pf[, rows, drop = FALSE], 2, E$lag$streams[rows])
keep <- apply(abs(dP), 2, max) > 1
pt <- data.frame(k_w = pf[, "k_w"], d_lik = round(pf[, "lik"] - E$lag$lik, 2), d_prior = round(pf[, "prior"] - E$lag$prior, 2),
                 round(dP[, keep, drop = FALSE], 2), check.names = FALSE)
print(pt, row.names = FALSE)
cat("  (c) THE RIDGE at the lag mode: each name's move when k_w moves +1 marginal sd and the rest follow their conditional expectation\n")
Sig <- fsL$cov; rk <- Sig[, RD_KW] / sqrt(Sig[RD_KW, RD_KW]); cr <- stats::cov2cor(Sig)[, RD_KW]
ord <- order(-abs(cr)); ord <- ord[names(cr)[ord] != RD_KW]
rt <- data.frame(name = names(cr)[ord], corr = round(cr[ord], 3), move_u = signif(rk[ord], 3),
                 move_in_own_marginal_sds = round(rk[ord] / sqrt(diag(Sig))[ord], 2))
print(utils::head(rt, RD_TOP_N), row.names = FALSE)

# ---- 6. the timing --------------------------------------------------------------------------------------
cat(sprintf("\n=== 6. GROWTH TIMING against Nino 3.4 (D3's P3 estimator: centred 12-month difference, ns(df %d) detrended, %d-%d) ===\n",
            RD_TREND_DF, RD_WIN[1], RD_WIN[2]))
cen12 <- function(x) { n <- length(x); g <- rep(NA_real_, n); i <- 7:(n - 6); g[i] <- x[i + 6] - x[i - 6]; g }
wk <- utils::read.table(RD_OBS_WEEKLY, comment.char = "#")
mo <- stats::aggregate(list(co2 = wk$V5), list(year = wk$V1, month = wk$V2), mean); mo <- mo[order(mo$year, mo$month), ]
obs_g <- data.frame(k = mo$year * 12L + mo$month, g = cen12(mo$co2))
timing <- function(out, F) {
  m <- data.frame(k = F$year * 12L + F$month, g = cen12((out$co2_NH + out$co2_SH) / 2), nino = F$enso)
  M <- merge(m, obs_g, by = "k", suffixes = c("_mod", "_obs"))
  M <- M[M$k >= RD_WIN[1] * 12L + 1L & M$k <= RD_WIN[2] * 12L + 12L & stats::complete.cases(M), ]
  tt <- (M$k - 1) / 12
  detr <- function(g) stats::residuals(stats::lm(g ~ splines::ns(tt, df = RD_TREND_DF)))
  xc <- sapply(RD_XLAGS, function(Lg) { n <- m$nino[match(M$k - Lg, m$k)]
    c(mod = stats::cor(detr(M$g_mod), n, use = "complete.obs"), obs = stats::cor(detr(M$g_obs), n, use = "complete.obs")) })
  c(peak_mod = RD_XLAGS[which.max(xc["mod", ])], r_mod = max(xc["mod", ]), peak_obs = RD_XLAGS[which.max(xc["obs", ])],
    r_obs = max(xc["obs", ]), r_mod_obs = stats::cor(detr(M$g_mod), detr(M$g_obs)))
}
V <- lapply(ARMS, dg_vector)
stopifnot(isTRUE(all.equal(V$lag$p[[RD_LAG]], L)), ccx_enso_lag_of(V$control$p) == 0, ccx_enso_lag_of(V$incumbent$p) == 0)
RUN <- lapply(V, dg_run)
TT <- do.call(rbind, lapply(names(RUN), function(a) data.frame(vector = a, lag = ccx_enso_lag_of(V[[a]]$p), t(timing(RUN[[a]]$out, RUN[[a]]$F)))))
print(TT, digits = 3, row.names = FALSE)

# ---- 7. the futures ----------------------------------------------------------------------------------------
cat("\n=== 7. FUTURES: global CO2 (ppm), vV scenarios history-spliced (as the app), SSP5-8.5 unspliced (= 10-01 a) ===\n")
hist_em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))[, c("year", "fossil_GtC", "luc_GtC")]
emis <- function(s) { if (!RD_FUT_SPLICE[[s]]) return(NULL); e <- ccx_scenario_emissions(s)
  rbind(hist_em, e[e$year > max(hist_em$year), c("year", "fossil_GtC", "luc_GtC")]) }
FUT <- t(sapply(names(V), function(a) { v <- V[[a]]; sp <- dg_spinup(v)
  unlist(lapply(names(RD_FUT_SPLICE), function(s) {
    rr <- suppressWarnings(ccx_run_coupled(sp, s, c(1750L, max(RD_FUT_YEARS)), emissions = emis(s),
                                           bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale))
    co2 <- tapply((rr$out$co2_NH + rr$out$co2_SH) / 2, floor(rr$out$t), mean)
    stats::setNames(co2[as.character(RD_FUT_YEARS)], sprintf("%s_%d", s, RD_FUT_YEARS)) })) }))
print(round(FUT, 1))
cat(sprintf("  lag - control: %s\n", paste(sprintf("%s %+.1f", colnames(FUT), FUT["lag", ] - FUT["control", ]), collapse = ", ")))
cat(sprintf("  lag - incumbent: %s\n", paste(sprintf("%s %+.1f", colnames(FUT), FUT["lag", ] - FUT["incumbent", ]), collapse = ", ")))

# ---- 8. which parameters carry the lag - control futures move ----------------------------------------------
cat("\n=== 8. FUTURES DECOMPOSITION, lag - control: each group swapped both ways (diag_obj14_refit_read.R's method) ===\n")
RD_FUT8 <- c("ssp585", "vvH")
GROUPS8 <- list(LAG = c(RD_LAG, RD_AMP), GREEN = "npp_tsens", FERT = c("beta_max", "fert_k"), NDEP = "ndep_ret", Q10 = "q10",
                LUC = "luc_scale", NONMODEL = c("bomb_total", "sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c",
                                               "imb_share_land", "imb_share_ocean_rest"))
GROUPS8$REST <- setdiff(names(E$lag$u), unlist(GROUPS8))
stopifnot(setequal(unlist(GROUPS8), names(E$lag$u)), !anyDuplicated(unlist(GROUPS8)))
fut8 <- function(v) { sp <- dg_spinup(v)
  vapply(RD_FUT8, function(sc) { rr <- suppressWarnings(ccx_run_coupled(sp, sc, c(1750L, max(RD_FUT_YEARS)), emissions = emis(sc),
                                                                        bomb_total_kmol = v$bomb_total, luc_scale = v$luc_scale))
    co2 <- tapply((rr$out$co2_NH + rr$out$co2_SH) / 2, floor(rr$out$t), mean); co2[[as.character(max(RD_FUT_YEARS))]] }, 0) }
# a swap copies the group's MODEL fields and FITTED values (the control's lag is its base value, 0 = OFF), then
# re-sets the ENSO block from the fitted list (the 10-01 a swap(), verbatim in kind)
swap8 <- function(to, from, names) {
  v <- to
  for (n in names) {
    if (n %in% names(v$p)) v$p[[n]] <- if (n %in% names(from$p)) from$p[[n]] else 0
    v$pm[[n]] <- if (!is.null(from$pm[[n]])) from$pm[[n]] else if (n %in% names(from$p)) from$p[[n]] else NULL
  }
  v$p <- ccx_set_enso(v$p, v$pm)
  if ("bomb_total" %in% names) v$bomb_total <- v$pm$bomb_total
  if ("luc_scale" %in% names) v$luc_scale <- v$pm$luc_scale
  v
}
f_L <- fut8(V$lag); f_C <- fut8(V$control)
dec8 <- do.call(rbind, lapply(names(GROUPS8), function(g) {
  add <- fut8(swap8(V$control, V$lag, GROUPS8[[g]])) - f_C
  rem <- f_L - fut8(swap8(V$lag, V$control, GROUPS8[[g]]))
  data.frame(group = g, n = length(GROUPS8[[g]]), what = c("add-one", "remove-one"), rbind(add, rem), check.names = FALSE) }))
tot8 <- data.frame(group = "TOTAL", n = length(E$lag$u), what = "lag - control", t(f_L - f_C), check.names = FALSE)
D8 <- rbind(dec8, tot8); D8[RD_FUT8] <- round(D8[RD_FUT8], 2)
print(D8, row.names = FALSE)
cat(sprintf("  (columns: CO2 at %d, ppm; SSP5-8.5 unspliced, vvH spliced; the arms' own values reproduce section 7: lag %s, control %s)\n",
            max(RD_FUT_YEARS), paste(round(f_L, 1), collapse = " / "), paste(round(f_C, 1), collapse = " / ")))
nm8 <- as.matrix(dec8[dec8$group == "NONMODEL", RD_FUT8])
cat(sprintf("  CHECK: the likelihood-only group moves the futures by max |%.3g| (must be 0)\n", max(abs(nm8))))
if (max(abs(nm8)) > 1e-9) stop("a likelihood-only name moved a future: the swap touches something it does not name")
stopifnot(isTRUE(all.equal(unname(f_L), unname(FUT["lag", sprintf("%s_%d", RD_FUT8, max(RD_FUT_YEARS))]), tolerance = 1e-10)))

sink()
out <- list(evals = lapply(E, function(e) e[c("logpost", "lik", "prior", "lag_term", "streams", "par", "prior_z")]),
            surveys = SURV, levels = LEVELS, stuck = STUCK, lag = list(value = L, sd = sdL, sd_conditional = sdLc, cor = corL, amplitudes = amp),
            arms = list(lik = lk, d_lag_control = dLC, d_aic = 2 * RD_AIC_K - 2 * dLC), rows = tab4,
            k_w = list(pull = PULL, pull_prior = pp, total = tot, mode_offset_sd = off, by_box = gp, profile = KW$lag$profile, ridge = rt,
                       half_step = vapply(KW, `[[`, 0, "h")),
            timing = TT, futures = FUT, futures_decomposition = D8, groups8 = GROUPS8,
            provenance = sprintf("%s @%s; lag %s; control %s%s; incumbent %s; objective #15; no RNG", RD_DRIVER, COMMIT,
                                 RD_LAG_MODE, RD_CTL_MODE, if (RD_INTERIM) " (INTERIM STAND-IN)" else "", RD_INC))
saveRDS(out, paste0(RD_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}\nprovenance: %s\n", RD_OUT, out$provenance))
