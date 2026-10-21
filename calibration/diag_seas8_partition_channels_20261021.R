# =====================================================================
# diag_seas8_partition_channels_20261021.R -- T8a (the land/ocean TYPE split,
# like-for-like with the ent26 record) and T8b (the channel decomposition with
# each channel's effective d13C-per-ppm signature), at the canonical hilda31w.
#
# THE QUESTION (Marcus, 2026-10-21). The app says the CO2 and d13C seasonal
# cycles disagree because the model's cycle is "land plants which have a strong
# 13C fingerprint, and the surface ocean without a fingerprint". In nature the
# same opposing land and ocean responses fit both tracers, so the misfit must sit
# in how THIS model sizes, times or signs a channel. Measure it.
#
# METHOD. Each channel's contribution is a VECTOR difference of the scored
# first-harmonic (a, b) pair, base minus the run with that channel switched off,
# reduced over the SAME years for CO2 and d13C at a station (the intersection of
# the two observed records, as diag_seas_signature_inversion.R and the ent26
# like-for-like did). Every run uses the canonical's own structure, pins, bands
# and PERIODIC spinup (lib_seas8_20261021.R; gate R0 below).
#
# THE CHANNELS AT hilda31w (each has an exact switch):
#   land  : NEP NH / NEP SH   seas_npp_amp_{NH,SH} = 0
#           resp NH / resp SH seas_T_amp_{NH,SH} = 0
#   ocean : SST NH / SST SH   sst_seas_amp_{NH,SH} = 0 (solubility AND the SST seen
#                             by the T-dependent alphas)
#           SH mixed layer    seas_ml = 0 (the canonical runs ml_nh_cycle = 0, so
#                             this removes the SH ML cycle only: entrainment of real
#                             water and the seasonal ML mass)
#           entrainment shim  ent_seas_amp_SH -- PINNED 0 at hilda31w, so ABSENT
#   isotope: T-dep alphas     alpha_as_tdep = 0 (the retired scalar alphas)
#   forcing: fossil seasonality (EDGAR weights -> 1), fire seasonality (f_fire -> 0),
#            both (FORC_USE_EMIS_SEASONALITY's content), land ENSO (CCX_ENSO_PARAMS -> 0)
#
# Usage: Rscript calibration/diag_seas8_partition_channels_20261021.R
#   (CCX_SEAS8_OUT overrides the output directory)
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(file.path("calibration", "lib_seas8_20261021.R"))

S8A_DRIVER <- "calibration/diag_seas8_partition_channels_20261021.R"
S8A_STEM   <- file.path(S8_OUT_DIR, sprintf("t8ab_partition_channels_%s", S8_MODE))
S8A_NBOOT  <- 2000L
S8A_SEED   <- 20261021L      # applied IMMEDIATELY before the observed-signature bootstrap (sec.4)
S8A_COMMIT <- ccx_git_stamp()
dir.create(S8_OUT_DIR, showWarnings = FALSE, recursive = TRUE)

# ---- the OBSERVED TYPE split at SPO: registered values + their bootstrap intervals ----
# Point values and the ocean-phase interval are the registry's (status "retired":
# PROVENANCE, used here as observed values, NOT re-derived -- the inversion cannot run
# at the canonical, ccx_inversion_broken_at_canonical). The other three intervals are
# not registered; they are the alpha_as_tdep = 0 re-run of 2026-09-04g, which
# reproduced the registered points (notes/assessment_2026-09-04_public_readiness.md
# sec.2b table: land 0.681 [0.479, 0.905] @ 9.30 [8.78, 9.77]; ocean 0.524 [0.309, 0.728]).
S8A_OBS <- list(
  land  = list(amp = ccx_const("SPO_SEAS_AMP_LAND_INV"), amp_ci = c(0.479, 0.905),
               mo = ccx_const("SPO_SEAS_LAND_PHASE_INV"), mo_ci = c(8.78, 9.77)),
  ocean = list(amp = ccx_const("SPO_SEAS_AMP_OCEAN_INV"), amp_ci = c(0.309, 0.728),
               mo = ccx_const("SPO_SEAS_OCEAN_PHASE_INV"),
               mo_ci = c(ccx_const("SPO_SEAS_OCEAN_PHASE_INV_LO"), ccx_const("SPO_SEAS_OCEAN_PHASE_INV_HI"))),
  total = list(amp = ccx_const("SPO_SEAS_AMP_OBS")))
S8A_OBS_SRC <- paste("SPO_SEAS_*_INV (R/constants.R, status retired = provenance) + the 09-04g",
                     "alpha_as_tdep=0 re-run's 95% bootstrap (notes/assessment_2026-09-04_public_readiness.md sec.2b)")
# ---- the ent26 record, for side-by-side (memory ccx_land_limb_is_ungated; same note) ----
S8A_ENT26 <- list(land = c(amp = 0.7153, mo = 8.86), ocean = c(amp = 0.4046, mo = 9.17),
                  total = c(amp = 1.1513, mo = 9.03), scalar_sum = 1.1199,
                  d13_per_ppm_ratio = c(MLO = 0.97, SPO = 1.21))

# ---- the channels ---------------------------------------------------------------
S8A_LAND  <- c("NEP NH", "NEP SH", "resp NH", "resp SH")
S8A_OCEAN <- c("SST NH", "SST SH", "SH mixed layer")
S8A_OCEAN_ENT26 <- c("SST NH", "SST SH")   # ent26's ocean set; its shim is pinned 0 here
S8A_OTHER <- c("T-dep alphas", "fossil seas", "fire seas", "emissions seas (both)", "land ENSO")
S8A_CASES <- list(
  `NEP NH`  = list(seas_npp_amp_NH = 0), `NEP SH` = list(seas_npp_amp_SH = 0),
  `resp NH` = list(seas_T_amp_NH = 0),   `resp SH` = list(seas_T_amp_SH = 0),
  `SST NH`  = list(sst_seas_amp_NH = 0), `SST SH` = list(sst_seas_amp_SH = 0),
  `SH mixed layer` = list(seas_ml = 0L),
  `T-dep alphas`   = list(alpha_as_tdep = 0L),
  `land ENSO`      = stats::setNames(as.list(rep(0, length(CCX_ENSO_PARAMS))), CCX_ENSO_PARAMS),
  `ALL land off`   = list(seas_npp_amp_NH = 0, seas_npp_amp_SH = 0, seas_T_amp_NH = 0, seas_T_amp_SH = 0),
  `ALL ocean off`  = list(sst_seas_amp_NH = 0, sst_seas_amp_SH = 0, seas_ml = 0L),
  `ALL 7 CO2 chans off` = list(seas_npp_amp_NH = 0, seas_npp_amp_SH = 0, seas_T_amp_NH = 0,
                               seas_T_amp_SH = 0, sst_seas_amp_NH = 0, sst_seas_amp_SH = 0, seas_ml = 0L))
.emis0 <- ccx_emission_seasonality
S8A_EMIS <- list(
  `fossil seas` = function() { s <- .emis0(); s$weights$fossil_NH[] <- 1; s$weights$fossil_SH[] <- 1; s },
  `fire seas`   = function() { s <- .emis0(); s$f_fire <- 0; s },
  `emissions seas (both)` = function() { s <- .emis0(); s$weights$fossil_NH[] <- 1
    s$weights$fossil_SH[] <- 1; s$f_fire <- 0; s })

sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))
cat(sprintf("=== %s @%s, %s ===\n", S8A_DRIVER, S8A_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))
S <- s8_setup(S8A_DRIVER)
cat(sprintf("mode %s | %s | md5 %s\n", S8_MODE, S$mode_file, S$mode_md5))
L   <- ccx_load_mode(S8_MODE)
obs <- ccx_prepare_obs()
YR  <- lapply(stats::setNames(nm = S8_STATIONS), function(st)
  intersect(obs$co2_seas[[st]]$year, obs$d13_seas[[st]]$year))
cat(sprintf("years (CO2 x d13C intersection): MLO %d-%d (n %d), SPO %d-%d (n %d); window %d-%d\n",
            min(YR$MLO), max(YR$MLO), length(YR$MLO), min(YR$SPO), max(YR$SPO), length(YR$SPO),
            S8_WINDOW[1], S8_WINDOW[2]))

# ---- what the canonical RUNS (the fitted seasonal values must reach the list) ----
SEAS_NAMES <- c("npp_frac_NH", "seas_T_amp_NH", "seas_T_amp_SH", "seas_lag_p_NH", "seas_lag_p_SH",
                "sst_seas_amp_NH", "sst_seas_amp_SH", "seas_T_lag", "ent_seas_amp_SH")
sep("0. THE SEASONAL VALUES THE RUN USES vs the mode file")
for (n in SEAS_NAMES) {
  ref <- if (!is.null(S$md$par_mode[[n]])) S$md$par_mode[[n]] else S$md$pins[[n]]
  cat(sprintf("  %-16s run %12.6g | file %12.6g %s %s\n", n, L$p[[n]], ref,
              if (n %in% names(S$md$pins)) "(PINNED)" else "(fitted)",
              if (isTRUE(all.equal(L$p[[n]], ref))) "ok" else "MISMATCH"))
  if (!isTRUE(all.equal(L$p[[n]], ref))) stop("fitted value does not reach the run: ", n)
}
cat(sprintf("  structure: seas_ml %s, ml_nh_cycle %s, alpha_as_tdep %s, seas_npp_amp NH/SH %g/%g, tau_ex_seas_amp %g, pump_seas_amp %g\n",
            L$p$seas_ml, L$p$ml_nh_cycle, L$p$alpha_as_tdep, L$p$seas_npp_amp_NH, L$p$seas_npp_amp_SH,
            L$p$tau_ex_seas_amp, L$p$pump_seas_amp))

t0 <- proc.time()
base <- s8_run(L, S$spf, obs, list(), YR)
# GATE R0: the run path reproduces the stored streams, row by row
dr <- unlist(base$ll)[names(S$md$streams)] - unlist(S$md$streams)
cat(sprintf("\nGATE R0: run-path streams vs the mode file's, max |diff| %.2e over %d rows (tol %g) -> %s\n",
            max(abs(dr)), length(dr), CCX_REPRO_TOL, if (max(abs(dr)) <= CCX_REPRO_TOL) "PASS" else "FAIL"))
if (!(max(abs(dr)) <= CCX_REPRO_TOL)) { print(dr[abs(dr) > CCX_REPRO_TOL]); stop("GATE R0 failed") }

cases <- list()
for (nm in names(S8A_CASES)) cases[[nm]] <- s8_run(L, S$spf, obs, S8A_CASES[[nm]], YR)
for (nm in names(S8A_EMIS))  cases[[nm]] <- s8_run(L, S$spf, obs, list(), YR, emis_fn = S8A_EMIS[[nm]])
run_min <- (proc.time() - t0)[["elapsed"]] / 60
bad <- names(cases)[vapply(cases, function(x) x$retried || (is.finite(x$resid_carbon) && x$resid_carbon >= PS_TOL), logical(1))]
cat(sprintf("%d runs in %.1f min; periodic spinup unconverged or substep-retried: %s\n",
            length(cases) + 1L, run_min, if (length(bad)) paste(bad, collapse = ", ") else "none"))

obsv <- list()
for (st in S8_STATIONS) {
  k <- match(YR[[st]], obs$co2_seas[[st]]$year); j <- match(YR[[st]], obs$d13_seas[[st]]$year)
  obsv[[paste0("co2_", st)]] <- c(mean(obs$co2_seas[[st]]$a[k]), mean(obs$co2_seas[[st]]$b[k]))
  obsv[[paste0("d13_", st)]] <- c(mean(obs$d13_seas[[st]]$a[j]), mean(obs$d13_seas[[st]]$b[j]))
}
contrib <- function(nm, key) base$v[[key]] - cases[[nm]]$v[[key]]
vsum <- function(chs, key) Reduce(`+`, lapply(chs, contrib, key = key))

# ---------------------------------------------------------------------------------
sep("1. WHERE THE CANONICAL STANDS (peak-to-peak, mean vector over the intersection years)")
cat(sprintf("  %-4s %9s %9s %7s %7s %7s | %9s %9s %7s %7s\n", "stn", "CO2 obs", "CO2 mod", "ratio",
            "obs mo", "mod mo", "d13 obs", "d13 mod", "obs mo", "mod mo"))
for (st in S8_STATIONS) {
  co <- obsv[[paste0("co2_", st)]]; cm <- base$v[[paste0("co2_", st)]]
  dO <- obsv[[paste0("d13_", st)]]; dM <- base$v[[paste0("d13_", st)]]
  cat(sprintf("  %-4s %9.4f %9.4f %6.3fx %7.2f %7.2f | %9.5f %9.5f %7.2f %7.2f\n", st,
              s8_amp(co), s8_amp(cm), s8_amp(cm) / s8_amp(co), s8_ang_mo(co), s8_ang_mo(cm),
              s8_amp(dO), s8_amp(dM), s8_ang_mo(dO), s8_ang_mo(dM)))
}
cat("  seasonal rows (log-units):", paste(sprintf("%s %.3f", unlist(S8_SEAS_ROWS),
                                                   unlist(base$ll)[unlist(S8_SEAS_ROWS)]), collapse = ", "), "\n")

# ---------------------------------------------------------------------------------
sep("2. T8a -- THE TYPE SPLIT (channel-sum route), like-for-like with ent26")
cat("  land  = NEP NH + NEP SH + resp NH + resp SH (vector sum of single knockouts)\n")
cat("  ocean = SST NH + SST SH + SH mixed layer   (ent26's set was SST NH + SST SH + the shim;\n")
cat("          the shim is pinned 0 here, so 'ocean, ent26 set' = SST NH + SST SH)\n")
t8a <- list()
for (st in S8_STATIONS) {
  key <- paste0("co2_", st)
  Lv <- vsum(S8A_LAND, key); Ov <- vsum(S8A_OCEAN, key); Oe <- vsum(S8A_OCEAN_ENT26, key)
  Lj <- base$v[[key]] - cases[["ALL land off"]]$v[[key]]
  Oj <- base$v[[key]] - cases[["ALL ocean off"]]$v[[key]]
  Tv <- base$v[[key]]
  canc <- 1 - s8_amp(Lv + Ov) / (s8_amp(Lv) + s8_amp(Ov))
  cat(sprintf("\n  --- %s (model total %.4f @ %.2f)\n", st, s8_amp(Tv), s8_ang_mo(Tv)))
  cat(sprintf("  %-26s %8s %7s | %s\n", "limb", "amp ppm", "peak mo", "observed (95%) / ratio / phase err / inside?"))
  row <- function(lab, v, ob = NULL) {
    s <- sprintf("  %-26s %8.4f %7.2f", lab, s8_amp(v), s8_ang_mo(v))
    if (!is.null(ob)) {
      ins_a <- s8_amp(v) >= ob$amp_ci[1] && s8_amp(v) <= ob$amp_ci[2]
      ins_m <- s8_dmo(s8_ang_mo(v), ob$mo_ci[1]) >= 0 && s8_dmo(ob$mo_ci[2], s8_ang_mo(v)) >= 0
      s <- paste0(s, sprintf(" | %.3f [%.3f, %.3f] @ %.2f [%.2f, %.2f] | %.2fx | %+.2f mo | amp %s, phase %s",
                             ob$amp, ob$amp_ci[1], ob$amp_ci[2], ob$mo, ob$mo_ci[1], ob$mo_ci[2],
                             s8_amp(v) / ob$amp, s8_dmo(s8_ang_mo(v), ob$mo),
                             if (ins_a) "IN" else "OUT", if (ins_m) "IN" else "OUT"))
    }
    cat(s, "\n")
  }
  row("land (channel sum)", Lv, if (st == "SPO") S8A_OBS$land)
  row("ocean (channel sum, full)", Ov, if (st == "SPO") S8A_OBS$ocean)
  row("ocean (ent26 set: SST only)", Oe, if (st == "SPO") S8A_OBS$ocean)
  row("land (joint knockout)", Lj); row("ocean (joint knockout)", Oj)
  row("land + ocean (vector)", Lv + Ov)
  cat(sprintf("  scalar |L|+|O| %.4f ; vector |L+O| %.4f ; cancellation 1-|L+O|/(|L|+|O|) = %.1f %% ; L-O phase gap %.2f mo\n",
              s8_amp(Lv) + s8_amp(Ov), s8_amp(Lv + Ov), 100 * canc, abs(s8_dmo(s8_ang_mo(Lv), s8_ang_mo(Ov)))))
  cat(sprintf("  scalar |L|+|O| vs model total: %+.1f %% (ent26 record: %+.1f %%)\n",
              100 * ((s8_amp(Lv) + s8_amp(Ov)) / s8_amp(Tv) - 1),
              100 * (S8A_ENT26$scalar_sum / S8A_ENT26$total[["amp"]] - 1)))
  cat(sprintf("  residual (total - L - O) %.4f @ %.2f  [emission seasonality, ENSO, nonlinearity]\n",
              s8_amp(Tv - Lv - Ov), s8_ang_mo(Tv - Lv - Ov)))
  cat(sprintf("  additivity: channel-sum vs joint knockout, land %+.1f %%, ocean %+.1f %%\n",
              100 * (s8_amp(Lv) / s8_amp(Lj) - 1), 100 * (s8_amp(Ov) / s8_amp(Oj) - 1)))
  t8a[[st]] <- list(land = Lv, ocean = Ov, ocean_ent26set = Oe, land_joint = Lj, ocean_joint = Oj,
                    total = Tv, cancellation = canc)
}
ob_L <- s8_vec(S8A_OBS$land$amp, S8A_OBS$land$mo); ob_O <- s8_vec(S8A_OBS$ocean$amp, S8A_OBS$ocean$mo)
cat(sprintf("\n  OBSERVED SPO (registered points): |L|+|O| %.3f, |L+O| %.3f, cancellation %.1f %%, L-O gap %.2f mo\n",
            S8A_OBS$land$amp + S8A_OBS$ocean$amp, s8_amp(ob_L + ob_O),
            100 * (1 - s8_amp(ob_L + ob_O) / (S8A_OBS$land$amp + S8A_OBS$ocean$amp)),
            abs(s8_dmo(S8A_OBS$land$mo, S8A_OBS$ocean$mo))))
cat(sprintf("  ent26 SPO record: land %.4f @ %.2f (%.2fx), ocean %.4f @ %.2f (%.2fx), total %.4f @ %.2f\n",
            S8A_ENT26$land[["amp"]], S8A_ENT26$land[["mo"]], S8A_ENT26$land[["amp"]] / S8A_OBS$land$amp,
            S8A_ENT26$ocean[["amp"]], S8A_ENT26$ocean[["mo"]], S8A_ENT26$ocean[["amp"]] / S8A_OBS$ocean$amp,
            S8A_ENT26$total[["amp"]], S8A_ENT26$total[["mo"]]))
cat("  MLO has NO registered observed TYPE split (the inversion's MLO outputs were never registered).\n")

# ---------------------------------------------------------------------------------
sep("3. T8b -- EVERY CHANNEL'S CO2 and d13C CONTRIBUTION and its EFFECTIVE SIGNATURE")
cat("  dCO2, dd13C = base - knockout (vectors), peak-to-peak. sig_proj = (dd13 . dCO2)/|dCO2|^2,\n")
cat("  permil per ppm, SIGNED (negative = d13C falls as CO2 rises: a depleted source). sig_mag =\n")
cat("  |dd13|/|dCO2|. 'off-antiphase' = months between dd13 and -dCO2 (0 = a signed scalar).\n")
cat("  d13C-only channels (|dCO2| < 1e-3) report the d13C vector alone.\n")
alpha_land <- L$p$alpha_photo_eps
t8b <- list()
for (st in S8_STATIONS) {
  kc <- paste0("co2_", st); kd <- paste0("d13_", st)
  C  <- base$co2_mean[[st]]
  cat(sprintf("\n  --- %s  (model mean CO2 over the years %.1f ppm; first-principles land expectation\n", st, C))
  cat(sprintf("        -eps_photo/C = -%.1f/%.1f = %.4f permil/ppm; pure net air-sea invasion at -2 permil: %.4f)\n",
              if (is.null(alpha_land)) NA else alpha_land, C,
              if (is.null(alpha_land)) NA else -alpha_land / C, -2 / C))
  cat(sprintf("  %-22s %8s %6s | %9s %6s | %9s %8s %8s | %9s %9s\n", "channel", "dCO2", "peak",
              "dd13C", "peak", "sig_proj", "sig_mag", "off-anti", "dll CO2", "dll d13C"))
  rows <- list()
  for (nm in c(S8A_LAND, S8A_OCEAN, S8A_OTHER, "ALL land off", "ALL ocean off", "ALL 7 CO2 chans off")) {
    dc <- contrib(nm, kc); dd <- contrib(nm, kd)
    a_c <- s8_amp(dc); a_d <- s8_amp(dd)
    sp_ <- if (a_c > 1e-3) sum(dd * dc) / sum(dc * dc) * 1 else NA_real_
    sm_ <- if (a_c > 1e-3) a_d / a_c else NA_real_
    off <- if (a_c > 1e-3 && a_d > 1e-6) abs(s8_dmo(s8_ang_mo(dd), s8_ang_mo(-dc))) else NA_real_
    rC <- paste0("co2_seasonal_", st); rD <- paste0("d13c_seasonal_", st)
    dllC <- cases[[nm]]$ll[[rC]] - base$ll[[rC]]; dllD <- cases[[nm]]$ll[[rD]] - base$ll[[rD]]
    cat(sprintf("  %-22s %8.4f %6.2f | %9.5f %6.2f | %9.5f %8.5f %8.2f | %+9.2f %+9.2f\n", nm, a_c,
                s8_ang_mo(dc), a_d, s8_ang_mo(dd), sp_, sm_, off, dllC, dllD))
    rows[[nm]] <- data.frame(station = st, channel = nm, dco2_amp = a_c, dco2_mo = s8_ang_mo(dc),
                             dd13_amp = a_d, dd13_mo = s8_ang_mo(dd), sig_proj = sp_, sig_mag = sm_,
                             off_antiphase_mo = off, dll_co2_row_if_off = dllC, dll_d13_row_if_off = dllD)
  }
  # the sum check for the d13C side too
  sumc <- vsum(c(S8A_LAND, S8A_OCEAN), kc); sumd <- vsum(c(S8A_LAND, S8A_OCEAN), kd)
  jc <- contrib("ALL 7 CO2 chans off", kc); jd <- contrib("ALL 7 CO2 chans off", kd)
  cat(sprintf("  ADDITIVITY (7 CO2 channels): CO2 sum %.4f vs joint %.4f (%+.1f %%); d13C sum %.5f vs joint %.5f (%+.1f %%)\n",
              s8_amp(sumc), s8_amp(jc), 100 * (s8_amp(sumc) / s8_amp(jc) - 1),
              s8_amp(sumd), s8_amp(jd), 100 * (s8_amp(sumd) / s8_amp(jd) - 1)))
  # the LIMB signatures (land / ocean aggregates), like-for-like with the observed station signature
  for (lab in c("land", "ocean")) {
    chs <- if (lab == "land") S8A_LAND else S8A_OCEAN
    dc <- vsum(chs, kc); dd <- vsum(chs, kd)
    cat(sprintf("  %s LIMB signature: sig_proj %.5f, sig_mag %.5f permil/ppm, off-antiphase %.2f mo\n",
                toupper(lab), sum(dd * dc) / sum(dc * dc), s8_amp(dd) / s8_amp(dc),
                abs(s8_dmo(s8_ang_mo(dd), s8_ang_mo(-dc)))))
  }
  t8b[[st]] <- do.call(rbind, rows)
}

# ---------------------------------------------------------------------------------
sep("4. THE STATION d13C-PER-ppm SIGNATURE, model vs observed, with the observed bootstrap")
cat(sprintf("  Bootstrap over YEARS of the intersection set (paired CO2/d13C years), %d draws,\n", S8A_NBOOT))
cat(sprintf("  seed %d applied immediately before the draws. The model series has no interannual\n", S8A_SEED))
cat("  scatter in its harmonic beyond forcing, so its ratio is a point. Also the 'all years' reading\n")
cat("  (each series over its own years, lib_seas_limbs.R's sl_ratio_at, the ent26 estimator).\n")
set.seed(S8A_SEED)
t8sig <- list()
for (st in S8_STATIONS) {
  hc <- obs$co2_seas[[st]]; hd <- obs$d13_seas[[st]]
  kc <- match(YR[[st]], hc$year); kd <- match(YR[[st]], hd$year); n <- length(YR[[st]])
  bs <- replicate(S8A_NBOOT, { j <- sample.int(n, n, replace = TRUE)
    s8_amp(c(mean(hd$a[kd][j]), mean(hd$b[kd][j]))) / s8_amp(c(mean(hc$a[kc][j]), mean(hc$b[kc][j]))) })
  o_sig <- s8_amp(obsv[[paste0("d13_", st)]]) / s8_amp(obsv[[paste0("co2_", st)]])
  m_sig <- s8_amp(base$v[[paste0("d13_", st)]]) / s8_amp(base$v[[paste0("co2_", st)]])
  ci <- stats::quantile(bs, c(0.025, 0.975), names = FALSE)
  # signed projection of the observed d13C vector on the observed CO2 vector, and off-antiphase
  oc <- obsv[[paste0("co2_", st)]]; od <- obsv[[paste0("d13_", st)]]
  mc <- base$v[[paste0("co2_", st)]]; mdv <- base$v[[paste0("d13_", st)]]
  # all-years estimator (sl_ratio_at)
  allv <- function(h) c(mean(h$a), mean(h$b))
  o_all <- s8_amp(allv(hd)) / s8_amp(allv(hc))
  m_all <- s8_amp(allv(base$ms$d13_seas[[st]])) / s8_amp(allv(base$ms$co2_seas[[st]]))
  cat(sprintf("  %s: observed %.5f [%.5f, %.5f] permil/ppm; model %.5f -> ratio %.2fx [%.2f, %.2f]; model inside obs CI: %s\n",
              st, o_sig, ci[1], ci[2], m_sig, m_sig / o_sig, m_sig / ci[2], m_sig / ci[1],
              if (m_sig >= ci[1] && m_sig <= ci[2]) "YES" else "NO"))
  cat(sprintf("       off-antiphase: observed %.2f mo, model %.2f mo; all-years estimator: obs %.5f, model %.5f, ratio %.2fx (ent26 %.2fx)\n",
              abs(s8_dmo(s8_ang_mo(od), s8_ang_mo(-oc))), abs(s8_dmo(s8_ang_mo(mdv), s8_ang_mo(-mc))),
              o_all, m_all, m_all / o_all, S8A_ENT26$d13_per_ppm_ratio[[st]]))
  t8sig[[st]] <- list(obs = o_sig, obs_ci = ci, model = m_sig, ratio = m_sig / o_sig,
                      ratio_ci = c(m_sig / ci[2], m_sig / ci[1]), obs_all = o_all, model_all = m_all,
                      boot = bs)
}

# ---------------------------------------------------------------------------------
sep("5. HEADROOM: what each seasonal row would gain if the model's MEAN vector matched the observed")
cat("  The model's per-year (a, b) shifted by (obs mean - model mean) over the row's own years,\n")
cat("  scored with the row's own sigma (obs interannual sd). The scale for T8c's losses.\n")
head5 <- list()
for (st in S8_STATIONS) for (tr in c("co2", "d13")) {
  o <- if (tr == "co2") obs$co2_seas[[st]] else obs$d13_seas[[st]]
  m <- if (tr == "co2") base$ms$co2_seas[[st]] else base$ms$d13_seas[[st]]
  k <- match(o$year, m$year); g <- !is.na(k)
  ll0 <- sum(stats::dnorm(o$a[g], m$a[k[g]], o$sd_a, log = TRUE)) + sum(stats::dnorm(o$b[g], m$b[k[g]], o$sd_b, log = TRUE))
  sa <- mean(o$a[g]) - mean(m$a[k[g]]); sb <- mean(o$b[g]) - mean(m$b[k[g]])
  ll1 <- sum(stats::dnorm(o$a[g], m$a[k[g]] + sa, o$sd_a, log = TRUE)) + sum(stats::dnorm(o$b[g], m$b[k[g]] + sb, o$sd_b, log = TRUE))
  rn <- paste0(if (tr == "co2") "co2_seasonal_" else "d13c_seasonal_", st)
  cat(sprintf("  %-18s row %9.3f (recomputed %9.3f) ; mean-matched %9.3f ; headroom %+8.3f ; n years %d ; mean-vector bias %.4f (%.2f sd_a-equiv)\n",
              rn, base$ll[[rn]], ll0, ll1, ll1 - ll0, sum(g), sqrt(sa^2 + sb^2),
              sqrt((sa / o$sd_a)^2 + (sb / o$sd_b)^2)))
  head5[[rn]] <- c(row = base$ll[[rn]], recomputed = ll0, mean_matched = ll1, headroom = ll1 - ll0)
}

# ---------------------------------------------------------------------------------
sep("6. POWER OF THE SPO TYPE-SPLIT COMPARISON: the observed limbs are conditional on two signatures")
cat("  NOT a new target and NOT the retired bootstrap: the closed-form two-signature split of the\n")
cat("  OBSERVED mean vectors, L = (d13 - s_O CO2)/(s_L - s_O), O = CO2 - L, at four signature pairs.\n")
cat("  Row 1 is the registered constants' basis (09-04g, alpha_as_tdep = 0: s_O = -0.00461; s_L at\n")
cat("  eps 18 over the window's mean CO2). The others use hilda31w's OWN limb signatures (sec.3).\n")
S8A_SO_REG <- -0.00461    # the retired inversion's s_O at alpha_as_tdep = 0 (memory ccx_inversion_broken_at_canonical)
landSPO <- vsum(S8A_LAND, "d13_SPO"); landSPOc <- vsum(S8A_LAND, "co2_SPO")
ocSPO <- vsum(S8A_OCEAN, "d13_SPO");  ocSPOc  <- vsum(S8A_OCEAN, "co2_SPO")
sL_w <- sum(landSPO * landSPOc) / sum(landSPOc^2); sO_w <- sum(ocSPO * ocSPOc) / sum(ocSPOc^2)
pairs6 <- rbind(c(-ccx_const("ALPHA_PHOTO_EPS") / base$co2_mean[["SPO"]], S8A_SO_REG),
                c(-L$p$alpha_photo_eps / base$co2_mean[["SPO"]], S8A_SO_REG),
                c(sL_w, S8A_SO_REG), c(sL_w, sO_w))
rownames(pairs6) <- c("registered basis (eps 18, s_O tdep=0)", "eps 16.2, s_O tdep=0",
                      "hilda31w land limb, s_O tdep=0", "hilda31w land AND ocean limbs")
t8pow <- list()
for (i in seq_len(nrow(pairs6))) {
  sLi <- pairs6[i, 1]; sOi <- pairs6[i, 2]
  Lo <- (obsv$d13_SPO - sOi * obsv$co2_SPO) / (sLi - sOi); Oo <- obsv$co2_SPO - Lo
  cat(sprintf("  %-40s s_L %.5f s_O %.5f (sep %.1fx) -> obs land %.3f @ %.2f, ocean %.3f @ %.2f | model/obs land %.2fx, ocean %.2fx\n",
              rownames(pairs6)[i], sLi, sOi, sLi / sOi, s8_amp(Lo), s8_ang_mo(Lo), s8_amp(Oo), s8_ang_mo(Oo),
              s8_amp(t8a$SPO$land) / s8_amp(Lo), s8_amp(t8a$SPO$ocean) / s8_amp(Oo)))
  t8pow[[rownames(pairs6)[i]]] <- c(s_L = sLi, s_O = sOi, land = s8_amp(Lo), land_mo = s8_ang_mo(Lo),
                                     ocean = s8_amp(Oo), ocean_mo = s8_ang_mo(Oo))
}

saveRDS(list(t8a = t8a, t8b = t8b, signature = t8sig, headroom = head5, obs_vectors = obsv, obs_split_power = t8pow,
             base_vectors = base$v, case_vectors = lapply(cases, `[[`, "v"),
             case_ll = lapply(cases, `[[`, "ll"), base_ll = base$ll, years = YR,
             obs_limbs = S8A_OBS, ent26 = S8A_ENT26,
             provenance = list(driver = S8A_DRIVER, lib = "calibration/lib_seas8_20261021.R",
                               commit = S8A_COMMIT, mode = S8_MODE, mode_file = S$mode_file,
                               mode_md5 = S$mode_md5, spinup = ccx_mode_spinup(S$md),
                               struct = ccx_mode_struct(S$md), seas_ml = ccx_mode_seas_ml(S$md),
                               span = S8_YEARS, seas_window = S8_WINDOW,
                               years_rule = "intersection of observed CO2 and d13C harmonic years per station",
                               units = "peak-to-peak ppm / permil; peak month of first harmonic; signatures permil per ppm",
                               seed = S8A_SEED, rng_kind = RNGkind(),
                               seed_applied = "set.seed() immediately before the observed d13C-per-ppm bootstrap (sec.4); nothing else is stochastic",
                               nboot = S8A_NBOOT, obs_limb_source = S8A_OBS_SRC,
                               built = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(S8A_STEM, ".rds"))
cat(sprintf("\nwrote %s.rds\n", S8A_STEM))
sep("DONE")
