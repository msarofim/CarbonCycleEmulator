# lib_ed.R -- helpers for the early-drawdown diagnosis (scratch only; NOT repo code).
# Every PD100 here goes through the repo's own builders (R/joos_irf.R): ccx_pulse_forcings,
# ccx_pulse_ref_state, ccx_pulse_background, ccx_hold_forcing, ccx_pulse_continue, ccx_pulse_pair --
# i.e. ccx_pd100() unrolled so the intermediate tables can be kept. ed_check_vs_pd100() asserts the
# unrolled run is byte-for-byte ccx_pd100()'s.

ED_REPO <- "/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator"
setwd(ED_REPO)
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))

ED_MARKS   <- c(1, 2, 5, 10, 20, 50, 100, 300)
ED_CLIMATE <- "free"
ED_END     <- JOOS_PULSE_YR + 300 + 10        # forcing to 2325: every mark interior
ED_GPP     <- ccx_const("GtC_PER_PPM")

# Joos et al. 2013 Table 5 (p. 2803): multi-model-mean fits, Eq. 11, GtC for ocean / land
ED_JOOS_T5 <- list(
  ocean = list(a0 = 60.29, a = c(-26.48, -17.45, -16.35), tau = c(390.5, 100.5, 4.551)),
  land  = list(a0 = 17.07, a = c(332.1, -334.1, -15.09),  tau = c(74.76, 70.31, 6.139)))
ed_joos_fit <- function(k, t) { s <- ED_JOOS_T5[[k]]
  s$a0 + vapply(t, function(tt) sum(s$a * exp(-tt / s$tau)), numeric(1)) }

#' A canonical-structure vector with some FITTED names replaced, built the dg_vector() way
#' (ccx_mode_base + ccx_overlay_par on the migrated fitted list), never a bare loop.
ed_v_with <- function(v, changes = list()) {
  pm <- v$pm
  for (n in names(changes)) {
    if (is.null(pm[[n]])) stop("ed_v_with: ", n, " is not in the fitted list")
    pm[[n]] <- changes[[n]]
  }
  attr(pm, "migrated_done") <- TRUE
  p <- ccx_overlay_par(ccx_mode_base(v$md), pm)
  p$pump_mode <- v$md$pump_mode
  v2 <- v; v2$p <- p; v2$pm <- pm
  v2$luc_scale <- pm$luc_scale; v2$bomb_total <- pm$bomb_total
  v2
}

#' Value of fitted name `n` at mode + k posterior sd, stepped in the mode file's UNCONSTRAINED space
ed_step <- function(v, n, k) {
  u <- v$md$u_mode[[n]] + k * v$md$sd_unc[[n]]
  ccx_unc_to_par(stats::setNames(u, n))[[1]]
}

#' Re-point a spun-up/history state at a different MODEL list (process-only change from that
#' instant on). Refuses a change that moves the ocean grid (h_ml), which cannot be spliced.
ed_repoint <- function(sp, p2) {
  aux2 <- ccx_prepare(p2, grid = sp$grid)
  if (!identical(aux2$grid, sp$grid)) stop("ed_repoint: the change moves the ocean grid")
  sp$params <- p2; sp$aux <- aux2
  sp
}

#' The PD100, unrolled. `p_after` (optional) = a MODEL list applied from JOOS_REF_YEAR on
#' (process-only), with the history and its 2010 state the arm's own.
ed_pd100 <- function(v, spin = NULL, climate = ED_CLIMATE, end_year = ED_END, p_after = NULL,
                     pulse = JOOS_PULSE) {
  if (is.null(spin)) spin <- dg_spinup(v)
  pf <- ccx_pulse_forcings(spin, c(JOOS_REF_YEAR, end_year), v$bomb_total, v$luc_scale)
  sp_ref <- ccx_pulse_ref_state(spin, pf$F_hist)
  if (!is.null(p_after)) sp_ref <- ed_repoint(sp_ref, p_after)
  F_bkg <- ccx_pulse_background(sp_ref, pf$F_fwd, climate)
  F_hold <- ccx_hold_forcing(sp_ref, F_bkg)
  attr(F_hold, "pd_climate") <- climate
  pre <- F_hold$t < JOOS_PULSE_YR
  sp_rel <- ccx_pulse_continue(sp_ref, F_hold[pre, , drop = FALSE])
  Fp <- F_hold[!pre, , drop = FALSE]
  pp <- ccx_pulse_pair(sp_rel, Fp, pulse, climate)
  b <- pp$b; q <- pp$q
  t <- Fp$t - Fp$t[1]
  irf <- (ccx_pd_co2(q) - ccx_pd_co2(b)) / (pulse / JOOS_PPM_PER)
  d <- data.frame(t = t,
                  air   = (ccx_pd_co2(q) - ccx_pd_co2(b)) * ED_GPP,
                  ocean = q$ocean_C - b$ocean_C,
                  land  = q$land_C  - b$land_C)
  for (bx in c("ml", "hs", "eq", "tr", "deep")) {
    cs <- paste0(bx, "_C_", HEMIS)
    d[[bx]] <- if (all(cs %in% names(q)) && !anyNA(q[, cs])) rowSums(q[, cs]) - rowSums(b[, cs]) else NA_real_
  }
  list(t = t, irf = irf, d = d, b = b, q = q, dT = pp$dT, iter = pp$iter, converged = pp$converged,
       hold_dev = attr(F_hold, "dev"), target = attr(F_hold, "target"),
       sp_rel = sp_rel, Fp = Fp, climate = climate, gmst_rel = Fp$gmst[1])
}

ed_at <- function(o, h, col = NULL) { k <- which.min(abs(o$t - h)); if (is.null(col)) k else o$d[k, col] }
ed_irf_at <- function(o, h) o$irf[which.min(abs(o$t - h))]
#' time-integrated IRF to TH (yr), trapezoid on the monthly series from the release
ed_th <- function(o, th) { k <- o$t <= th + 1e-9; x <- o$t[k]; y <- o$irf[k]
  sum(diff(x) * (head(y, -1) + tail(y, -1)) / 2) }

#' One summary row
ed_row <- function(o, label) {
  data.frame(label = label,
             irf1 = ed_irf_at(o, 1), irf5 = ed_irf_at(o, 5), irf20 = ed_irf_at(o, 20),
             irf100 = ed_irf_at(o, 100), irf300 = ed_irf_at(o, 300),
             th20 = ed_th(o, 20), th100 = ed_th(o, 100),
             oc5 = ed_at(o, 5, "ocean"), ld5 = ed_at(o, 5, "land"),
             oc20 = ed_at(o, 20, "ocean"), ld20 = ed_at(o, 20, "land"),
             oc100 = ed_at(o, 100, "ocean"), ld100 = ed_at(o, 100, "land"),
             hold_dev = o$hold_dev, target = o$target, stringsAsFactors = FALSE)
}
