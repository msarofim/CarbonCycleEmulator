# =====================================================================
# diag_kz_pump_scan.R -- PK-2 / PK-3 / PK-4 of
# notes/prereg_2026-09-15b_kz_pump_diagnosis.md: the kz SCAN at the canonical
# (hilda30c), UNREFITTED, on the C++ objective, with the 25 rows decomposed.
#   Arm A -- raw: every other name at the canonical vector (the pump re-solves:
#            export scales with kz).
#   Arm B -- LAND-COMPENSATED: at each kz the three land names of the 08-31
#            recipe (beta_max, fert_k, q10) re-optimised on the full logpost,
#            every other name held. GATE PK-2g: at kz x 1 the optimum must
#            reproduce the stored logpost (no improvement on the mode).
#   PK-3  -- the kz_deep_frac scan, arm A only, at the canonical kz.
#   PK-4  -- the 13C mechanism read inside arm B: the 1750-2025 change in
#            reservoir carbon and 13C-signal (final state vs spinup), land vs
#            ocean, and the atmospheric d13C at 2010.
# Per point: the 25-row likelihood delta vs the canonical, logpost, and the
# diagnostics (export, ML exchange rate, modern DIC gradient, ocean sink
# 2015-2023, bomb ocean excess 1975/1995, d13C_atm 2010). Nothing adopted.
# Usage: Rscript calibration/diag_kz_pump_scan.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
KS_COMMIT <- ccx_git_stamp()
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
KS_ARM    <- CCX_MODE_CANONICAL
KS_KZ_FAC <- c(0.35, 0.5, 0.7, 1, 1.4)            # kz multipliers (log-spaced about 1)
KS_F_GRID <- c(NA, 0.03, 0.06, 0.089, 0.15)       # kz_deep_frac; NA = the canonical's own (0.0117); 0.089 = the E mode's
KS_LAND   <- c("beta_max", "fert_k", "q10")       # the 08-31 recipe's re-optimised names (arm B)
KS_SURF   <- c("kz_deep_frac", "h_ml", "k_w", "bomb_total", "sigma_d14c")   # arm C (amendment A3): + these, at KS_C_FAC only
KS_C_FAC  <- c(0.5, 0.7, 1)
KS_C_NM_MAXIT <- 1500; KS_C_BFGS_MAXIT <- 100
KS_GATE_TOL <- 1e-3                               # PK-2g: arm B at kz x 1 reproduces the stored logpost within this
KS_NM_MAXIT <- 400; KS_BFGS_MAXIT <- 60
KS_ATM_D13C_YEAR <- 2010
KS_OUT    <- ccx_path("outputs", "diagnostics", sprintf("kz_pump_scan_%s", format(Sys.Date(), "%Y%m%d")))
sink_log <- file(paste0(KS_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE)
on.exit({ sink(); close(sink_log) }, add = TRUE)
cat(sprintf("== PK-2/3/4 the kz scan at %s (prereg 2026-09-15b) ==\n", KS_ARM))
cat(sprintf("kz x %s; kz_deep_frac %s; arm B re-optimises %s; gate tol %g\n\n", paste(KS_KZ_FAC, collapse = "/"),
            paste(ifelse(is.na(KS_F_GRID), "canon", KS_F_GRID), collapse = "/"), paste(KS_LAND, collapse = ","), KS_GATE_TOL))

# ---- the objective, under the file's pins (the test-mode-file.R pattern) ---
md <- readRDS(ccx_mode_file(KS_ARM))
rm_pins <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm_pins), add = TRUE)
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
st <- ccx_mode_start(md, "kz_scan")
lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
v0 <- lp(st$u)
cat(sprintf("HARNESS GATE: rebuilt logpost %.4f (shift %+.4f) vs stored %.4f -> %s\n", as.numeric(v0) - st$logpost_shift,
            st$logpost_shift, md$logpost, if (abs(as.numeric(v0) - st$logpost_shift - md$logpost) < 1e-4) "PASS" else "FAIL"))
if (abs(as.numeric(v0) - st$logpost_shift - md$logpost) >= 1e-4) stop("harness gate failed")
pm0 <- st$p; ref_st <- attr(v0, "streams"); rows <- names(ref_st)   # the MIGRATED + seeded vector (absent names at their OFF values)
stopifnot(all(u_of_chk <- abs(ccx_par_to_unc(pm0) - st$u) < 1e-12))
cat(sprintf("stored streams sum %.3f vs rebuilt %.3f\n", sum(md$streams), sum(ref_st)))
u_of <- function(pm) ccx_par_to_unc(pm)
iland <- match(KS_LAND, CCX_PARAM_NAMES); stopifnot(!any(is.na(iland)))

# ---- the diagnostics of a vector (one C++ run, the gate machinery) ------
v_base <- dg_vector(KS_ARM)
diag_of <- function(pm) {
  v <- v_base; v$pm <- pm; v$p <- ccx_overlay_par(v$p, pm)
  for (nm in c("luc_scale", "bomb_total", "sigma_d14c", "rep_dC", "grad_off_co2", "grad_off_d13c")) if (!is.null(pm[[nm]])) v[[nm]] <- pm[[nm]]
  r <- dg_run(v); sp <- r$sp; out <- r$out; yr <- floor(out$t + 1e-9)
  ex <- sum(unlist(lapply(sp$aux$pump, function(h) h$org + h$carb)))
  g <- ccx_ocean_grad_scored(out, sp); s7 <- dg_gate7(r)
  exc <- function(Y) ccx_c14_kmol(mean(out$ocean_C14[yr == Y]) - out$ocean_C14[1])
  # PK-4: reservoir carbon and 13C-signal change 1750 -> end of run (final state vs the spinup)
  fin <- ccx_run_fast(sp, r$F)$state; y0 <- sp$y
  ocean <- unlist(lapply(HEMIS, function(h) c(sp$aux$idx[[h]]$ml, sp$aux$idx[[h]]$oc, sp$aux$idx[[h]]$hs, sp$aux$idx[[h]]$hd)))
  land  <- unlist(lapply(HEMIS, function(h) sp$aux$idx[[h]]$land))
  # A3: the 13C-SIGNAL change in GtC-equivalent (dC13 / R_VPDB) -- a magnitude, not a ratio over a dC that can cross zero
  d13 <- function(ix) { dC <- sum(fin[ix, "C"] - y0[ix, "C"]); d13 <- sum(fin[ix, "C13"] - y0[ix, "C13"]) / ccx_const("R13_VPDB")
    c(dC = dC, dC13eq = d13, light_excess = d13 - dC) }
  c(export = ex, ml_exch = pm$kz / (0.5 * (sp$grid$dz[1] + sp$grid$dz[2]) * sp$grid$dz[1]),
    dic_grad = g$dic, sink_ocean = s7$ocean, sink_land = s7$land, exc1975 = exc(1975), exc1995 = exc(1995),
    d13c_atm = mean(out$d13c_NH[yr == KS_ATM_D13C_YEAR]), ocean = d13(ocean), land = d13(land))
}

# ---- arm B: re-optimise the land three at a held vector ----------------
reopt <- function(pm, idx = iland, nm_maxit = KS_NM_MAXIT, bfgs_maxit = KS_BFGS_MAXIT) {
  u <- u_of(pm); f <- function(z) { uu <- u; uu[idx] <- z; x <- -as.numeric(lp(uu)); if (!is.finite(x)) 1e10 else x }
  o1 <- stats::optim(u[idx], f, method = "Nelder-Mead", control = list(maxit = nm_maxit, reltol = 1e-10))
  o2 <- stats::optim(o1$par, f, method = "BFGS", control = list(maxit = bfgs_maxit, reltol = 1e-12))
  best <- if (o2$value < o1$value) o2 else o1
  uu <- u; uu[idx] <- best$par
  list(u = uu, pm = ccx_unc_to_par(uu), val = lp(uu), n_eval = o1$counts[1] + o2$counts[1])
}

# ---- PK-2 -------------------------------------------------------------
res <- list(A = list(), B = list())
DA <- DB <- matrix(NA_real_, length(KS_KZ_FAC), length(rows), dimnames = list(KS_KZ_FAC, rows))
tabA <- tabB <- NULL
for (i in seq_along(KS_KZ_FAC)) {
  fac <- KS_KZ_FAC[i]; pm <- pm0; pm$kz <- pm0$kz * fac
  t0 <- proc.time()[["elapsed"]]
  vA <- lp(u_of(pm)); dA <- diag_of(pm)
  DA[i, ] <- attr(vA, "streams") - ref_st
  tabA <- rbind(tabA, data.frame(fac = fac, kz = pm$kz, logpost = as.numeric(vA) - st$logpost_shift, dlik = sum(DA[i, ]), t(dA)))
  cat(sprintf("A kz x%.2f (%.0f): logpost %.2f (dlik %+.2f), export %.1f, ML exch %.2f/yr, DIC grad %.1f, sink %.2f, exc75/95 %.1f/%.1f, d13c_atm %.3f  [%.0f s]\n",
              fac, pm$kz, as.numeric(vA) - st$logpost_shift, sum(DA[i, ]), dA["export"], dA["ml_exch"], dA["dic_grad"], dA["sink_ocean"],
              dA["exc1975"], dA["exc1995"], dA["d13c_atm"], proc.time()[["elapsed"]] - t0))
  t0 <- proc.time()[["elapsed"]]
  rb <- reopt(pm); dB <- diag_of(rb$pm)
  DB[i, ] <- attr(rb$val, "streams") - ref_st
  tabB <- rbind(tabB, data.frame(fac = fac, kz = pm$kz, logpost = as.numeric(rb$val) - st$logpost_shift, dlik = sum(DB[i, ]),
                                 beta_max = rb$pm$beta_max, fert_k = rb$pm$fert_k, q10 = rb$pm$q10, n_eval = rb$n_eval, t(dB)))
  cat(sprintf("B kz x%.2f: logpost %.2f (dlik %+.2f) after %d evals; beta_max %.3f fert_k %.1f q10 %.3f; sink ocean/land %.2f/%.2f; d13c_atm %.3f; dC ocean/land %.1f/%.1f; light-13C excess ocean/land %+.2f/%+.2f GtC-eq  [%.0f s]\n",
              fac, as.numeric(rb$val) - st$logpost_shift, sum(DB[i, ]), rb$n_eval, rb$pm$beta_max, rb$pm$fert_k, rb$pm$q10,
              dB["sink_ocean"], dB["sink_land"], dB["d13c_atm"], dB["ocean.dC"], dB["land.dC"], dB["ocean.light_excess"], dB["land.light_excess"],
              proc.time()[["elapsed"]] - t0))
  res$A[[i]] <- list(pm = pm, v = vA, diag = dA); res$B[[i]] <- list(pm = rb$pm, v = rb$val, diag = dB)
}
i1 <- which(KS_KZ_FAC == 1)
g2 <- abs(tabB$logpost[i1] - md$logpost)
cat(sprintf("\nGATE PK-2g: arm B at kz x 1 reproduces the stored logpost: %.4f vs %.4f (|diff| %.2e vs %g) -> %s\n",
            tabB$logpost[i1], md$logpost, g2, KS_GATE_TOL, if (g2 < KS_GATE_TOL) "PASS" else "FAIL -- the optimiser moved off the mode; a finding about the mode"))

cat("\n-- arm A (raw): the 25 rows, delta vs the canonical --\n"); print(round(t(DA), 2))
cat("\n-- arm B (land-compensated): the 25 rows, delta vs the canonical --\n"); print(round(t(DB), 2))
cat("\n-- arm A table --\n"); print(tabA, digits = 4)
cat("\n-- arm B table --\n"); print(tabB, digits = 4)

# ---- the predictions ----------------------------------------------------
half <- which(KS_KZ_FAC == 0.5)
co2rows <- c("co2_level_MLO", "co2_level_SPO", "co2_icecore"); bomb <- c("d14c_NH", "d14c_SH"); d13 <- c("d13c_level_MLO", "d13c_level_SPO")
ordA <- sort(DA[half, ]); ordB <- sort(DB[half, ])
cat("\n== P2A (raw, kz x 0.5) ==\n")
cat(sprintf("largest charges: %s\n", paste(sprintf("%s %+.1f", names(ordA)[1:5], ordA[1:5]), collapse = ", ")))
cat(sprintf("CO2-level+icecore rows %+.1f (predicted the largest block); bomb rows %+.1f (predicted <= -20) -> %s; export %.1f (predicted ~22.8); ocean_grad_dic %+.2f (predicted |.| < 3) -> %s\n",
            sum(DA[half, co2rows]), sum(DA[half, bomb]), if (sum(DA[half, bomb]) <= -20) "PASS" else "FAIL",
            tabA$export[half], DA[half, "ocean_grad_dic"], if (abs(DA[half, "ocean_grad_dic"]) < 3) "PASS" else "FAIL"))
cat("\n== P2B (land-compensated, kz x 0.5) -- THE READ ==\n")
cat(sprintf("largest charges: %s\n", paste(sprintf("%s %+.1f", names(ordB)[1:6], ordB[1:6]), collapse = ", ")))
cat(sprintf("CO2-level+icecore rows %+.1f (predicted within 10 of the canonical) -> %s\n", sum(DB[half, co2rows]), if (abs(sum(DB[half, co2rows])) <= 10) "PASS" else "FAIL"))
cat(sprintf("d13c_level rows %+.1f (predicted <= -20; < 5 in magnitude would mean NOT the kz constraint) -> %s\n", sum(DB[half, d13]),
            if (sum(DB[half, d13]) <= -20) "PASS" else if (abs(sum(DB[half, d13])) < 5) "REFUTED: the d13C level rows do not hold kz" else "FAIL (moves, but less than predicted)"))
cat(sprintf("bomb rows %+.1f (predicted <= -10) -> %s; gcb_ocean_sink %+.1f (predicted <= -5) -> %s\n", sum(DB[half, bomb]),
            if (sum(DB[half, bomb]) <= -10) "PASS" else "FAIL", DB[half, "gcb_ocean_sink"], if (DB[half, "gcb_ocean_sink"] <= -5) "PASS" else "FAIL"))
cat(sprintf("the total, arm B at kz x 0.5: %+.1f log-units; at kz x 0.35: %+.1f; at kz x 1.4: %+.1f\n", tabB$dlik[half], tabB$dlik[1], tabB$dlik[length(KS_KZ_FAC)]))
cat("\n== P4 (mechanism, arm B) ==\n")
for (i in seq_along(KS_KZ_FAC)) cat(sprintf("kz x%.2f: dC ocean %.1f land %.1f GtC (1750-2025); 13C-signal change ocean %.1f land %.1f GtC-eq (light excess %+.2f / %+.2f); d13c_atm(%d) %.3f\n",
                                            KS_KZ_FAC[i], tabB$ocean.dC[i], tabB$land.dC[i], tabB$ocean.dC13eq[i], tabB$land.dC13eq[i],
                                            tabB$ocean.light_excess[i], tabB$land.light_excess[i], KS_ATM_D13C_YEAR, tabB$d13c_atm[i]))

# ---- arm C (amendment A3): + the surface / 14C names --------------------
cat("\n== arm C (A3): land three + kz_deep_frac, h_ml, k_w, bomb_total, sigma_d14c re-optimised ==\n")
isurf <- match(KS_SURF, CCX_PARAM_NAMES); stopifnot(!any(is.na(isurf))); iC <- c(iland, isurf)
DC <- matrix(NA_real_, length(KS_C_FAC), length(rows), dimnames = list(KS_C_FAC, rows)); tabC <- NULL; res$C <- list()
for (i in seq_along(KS_C_FAC)) {
  fac <- KS_C_FAC[i]; pm <- pm0; pm$kz <- pm0$kz * fac; t0 <- proc.time()[["elapsed"]]
  rc <- reopt(pm, idx = iC, nm_maxit = KS_C_NM_MAXIT, bfgs_maxit = KS_C_BFGS_MAXIT); dC <- diag_of(rc$pm)
  DC[i, ] <- attr(rc$val, "streams") - ref_st
  tabC <- rbind(tabC, data.frame(fac = fac, kz = pm$kz, logpost = as.numeric(rc$val) - st$logpost_shift, dlik = sum(DC[i, ]), n_eval = rc$n_eval,
                                 beta_max = rc$pm$beta_max, kz_deep_frac = rc$pm$kz_deep_frac, h_ml = rc$pm$h_ml, k_w = rc$pm$k_w,
                                 bomb_total = rc$pm$bomb_total, sigma_d14c = rc$pm$sigma_d14c, t(dC)))
  cat(sprintf("C kz x%.2f: logpost %.2f (dlik %+.2f) after %d evals; kz_deep_frac %.4f (K_deep %.0f) h_ml %.1f k_w %.0f bomb_total %.1f sigma_d14c %.2f beta_max %.3f; bomb rows %+.1f; profile_level %+.1f; sink %+.1f; largest: %s  [%.0f s]\n",
              fac, as.numeric(rc$val) - st$logpost_shift, sum(DC[i, ]), rc$n_eval, rc$pm$kz_deep_frac, rc$pm$kz * rc$pm$kz_deep_frac, rc$pm$h_ml, rc$pm$k_w,
              rc$pm$bomb_total, rc$pm$sigma_d14c, rc$pm$beta_max, sum(DC[i, bomb]), DC[i, "d14c_profile_level"], DC[i, "gcb_ocean_sink"],
              paste(sprintf("%s %+.1f", names(sort(DC[i, ]))[1:5], sort(DC[i, ])[1:5]), collapse = ", "), proc.time()[["elapsed"]] - t0))
  res$C[[i]] <- list(pm = rc$pm, v = rc$val, diag = dC)
}
iC1 <- which(KS_C_FAC == 1); gC <- abs(tabC$logpost[iC1] - md$logpost)
cat(sprintf("GATE PK-2g (arm C): at kz x 1, %.4f vs stored %.4f (|diff| %.2e) -> %s\n", tabC$logpost[iC1], md$logpost, gC,
            if (gC < KS_GATE_TOL) "PASS" else "FAIL -- the 8-name optimiser moved off the mode; a finding about the mode"))
iCh <- which(KS_C_FAC == 0.5)
cat(sprintf("P2C at kz x 0.5: bomb rows %+.1f (predicted <= -100) -> %s; d14c_profile_level %+.1f (predicted >= -5) -> %s; total %+.1f (predicted <= -150) -> %s\n",
            sum(DC[iCh, bomb]), if (sum(DC[iCh, bomb]) <= -100) "PASS" else "FAIL", DC[iCh, "d14c_profile_level"], if (DC[iCh, "d14c_profile_level"] >= -5) "PASS" else "FAIL",
            tabC$dlik[iCh], if (tabC$dlik[iCh] <= -150) "PASS" else if (abs(tabC$dlik[iCh]) < 30) "REFUTED: a lower-kz basin exists" else "FAIL (holds, but less than predicted)"))
cat("\n-- arm C rows --\n"); print(round(t(DC), 2)); cat("\n-- arm C table --\n"); print(tabC[, 1:11], digits = 4)

# ---- PK-3: kz_deep_frac, arm A ------------------------------------------
cat("\n== PK-3: kz_deep_frac at the canonical kz (arm A) ==\n")
DF <- matrix(NA_real_, length(KS_F_GRID), length(rows), dimnames = list(ifelse(is.na(KS_F_GRID), "canon", KS_F_GRID), rows)); tabF <- NULL
for (i in seq_along(KS_F_GRID)) {
  pm <- pm0; if (!is.na(KS_F_GRID[i])) pm$kz_deep_frac <- KS_F_GRID[i]
  vF <- lp(u_of(pm)); dF <- diag_of(pm); DF[i, ] <- attr(vF, "streams") - ref_st
  tabF <- rbind(tabF, data.frame(f = pm$kz_deep_frac, K_deep = pm$kz * pm$kz_deep_frac, logpost = as.numeric(vF) - st$logpost_shift, dlik = sum(DF[i, ]), t(dF)))
  cat(sprintf("f %.4f (K_deep %.0f): logpost %.2f (dlik %+.2f); export %.1f; DIC grad %.1f; largest: %s\n", pm$kz_deep_frac, pm$kz * pm$kz_deep_frac,
              as.numeric(vF) - st$logpost_shift, sum(DF[i, ]), dF["export"], dF["dic_grad"],
              paste(sprintf("%s %+.1f", names(sort(DF[i, ]))[1:4], sort(DF[i, ])[1:4]), collapse = ", ")))
}
iE <- which(KS_F_GRID == 0.089)
cat(sprintf("P3: f = 0.089 unrefitted costs %+.1f (predicted <= -20) -> %s; led by %s\n", tabF$dlik[iE],
            if (tabF$dlik[iE] <= -20) "PASS" else if (tabF$dlik[iE] > -5) "REFUTED: cheap -- the deep-K rise was free at the canonical" else "FAIL (costs, but less than predicted)",
            paste(sprintf("%s %+.1f", names(sort(DF[iE, ]))[1:3], sort(DF[iE, ])[1:3]), collapse = ", ")))
cat("\n-- PK-3 rows --\n"); print(round(t(DF), 2))

saveRDS(list(arm = KS_ARM, kz_fac = KS_KZ_FAC, f_grid = KS_F_GRID, land = KS_LAND, ref_streams = ref_st, DA = DA, DB = DB, DF = DF,
             tabA = tabA, tabB = tabB, tabF = tabF, DC = DC, tabC = tabC, c_fac = KS_C_FAC, surf = KS_SURF, res = res,
             gate_pk2g = g2 < KS_GATE_TOL, gate_pk2g_C = gC < KS_GATE_TOL, md_logpost = md$logpost,
             commit = KS_COMMIT), paste0(KS_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n", KS_OUT))
