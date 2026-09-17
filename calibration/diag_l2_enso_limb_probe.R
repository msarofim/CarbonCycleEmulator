# =====================================================================
# THE LAYER-2 NINO3.4 LIMB, UNREFITTED PROBE at the canonical (prereg
# notes/prereg_2026-09-17k_l2_enso_limb_refit.md §4 PE1-PE2, N1).
#
# WHAT: the canonical's own vector under struct "hilda_cl2" (k_l2 2, w0_l2 27 Sv)
# with the shim gamma_enso_ocn_* SET TO 0 and w_enso_l2 on the prereg's grid --
# nothing refit. Read: the 09-04g ENSO regression of the annual ocean sink on
# Nino3.4 (year term, 1959-2024), the likelihood on the 25 rows against the
# canonical AS SHIPPED (shim on, limb off) and against the solubility-only point
# (shim 0, limb 0), the rows that move, GATE V, and the floor's clipping (the
# limb with w0_l2 -> Inf is the UNCLIPPED linear anomaly; P0e records the
# difference rather than assuming it).
#
# GATES (harness): the canonical's stored streams reproduce (gate 1); the
# solubility-only point reproduces the 09-17 T-A2 scan's line (an independent
# product: ta2_enso_return_depth_20260917.log) -- slope -0.1873, r -0.572,
# lik -1405.82.
#
# Every number below is computed here; every label derives from the constants.
# Usage: Rscript calibration/diag_l2_enso_limb_probe.R      (~3 min, C++ core)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
L2_STRUCT   <- "hilda_cl2"
L2_GRID     <- c(0, 14, 18.7, 25, 32, 40)          # Sv per index; 0 = N1; 14-25 = Meinen's bracket; 32 = the scan's need; 40 = the REFUTED line
L2_BRACKET  <- c(14, 25)                            # obs_eq_cell.rds$w0_prior$per_index_sv
L2_WIN      <- c(1959, 2024)                        # = SC_ENSO_WIN, the 09-04g estimator's window
L2_LINEAR_W0 <- 1e6                                 # w0_l2 for the UNCLIPPED comparison (the floor never binds)
# the independent reference lines (the 09-17 T-A2 scan, calibration/diag_ta2_enso_return_depth.R at hilda30h)
L2_REF_SOL  <- c(slope = -0.1873, r = -0.572, lik = -1405.82); L2_REF_TOL <- c(slope = 2e-3, r = 5e-3, lik = 0.05)
L2_PE1_REACH <- c(28, 36)                           # prereg §4 PE1: the observed slope reached within this Sv/index band
L2_PE2_ROWS <- c("co2_level_MLO", "co2_level_SPO", "co2_icecore"); L2_PE2_TOL <- 2     # log-units at w = 25
L2_ROW_SHOW <- 0.5
L2_OUT <- ccx_path("outputs", "diagnostics", sprintf("l2_enso_limb_probe_%s.rds", format(Sys.Date(), "%Y%m%d")))
t0 <- Sys.time()

v <- dg_vector(CCX_MODE_CANONICAL); obs <- ccx_prepare_obs()
cat(sprintf("arm %s: %s\n  pins: %s; migrated: %s; spinup: %s\n", CCX_MODE_CANONICAL, v$src,
            if (length(v$pins)) paste(sprintf("%s=%g", names(v$pins), v$pins), collapse = ",") else "none",
            if (length(v$migrated)) paste(v$migrated, collapse = ",") else "none", v$spinup_label))
stopifnot(!ccx_l2_on(v$p))                          # every registered structure: k_l2 = 0
blk <- ccx_struct_block(L2_STRUCT)
# L2_K (env, optional): the return-layer SENSITIVITY (prereg PA7, run unrefitted here): overrides k_l2; the output name says so
L2_K_ENV <- Sys.getenv("L2_K", ""); if (nzchar(L2_K_ENV)) { blk$k_l2 <- as.integer(L2_K_ENV); L2_OUT <- sub("\\.rds$", sprintf("_k%d.rds", blk$k_l2), L2_OUT) }
cat(sprintf("the limb's structure '%s': k_l2 %d, w0_l2 %g Sv (obs_eq_cell.rds$w0_prior$mean_sv)\n", L2_STRUCT, blk$k_l2, blk$w0_l2))

en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))); en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
g <- obs$gcb; mg <- merge(g[, c("year", "ocean_sink")], en_ann, by = "year"); mg <- mg[stats::complete.cases(mg) & mg$year >= L2_WIN[1] & mg$year <= L2_WIN[2], ]
fo <- stats::lm(ocean_sink ~ year + nino34_anom, data = mg); OBS_SLOPE <- coef(fo)[["nino34_anom"]]; OBS_SE <- summary(fo)$coefficients["nino34_anom", 2]
enso_slope <- function(r) { s <- dg_annual_sinks(r); d <- merge(data.frame(year = s$year, oc = s$ocean), en_ann, by = "year")
  d <- d[d$year >= L2_WIN[1] & d$year <= L2_WIN[2], ]; f <- stats::lm(oc ~ year + nino34_anom, data = d)
  c(slope = coef(f)[["nino34_anom"]], se = summary(f)$coefficients["nino34_anom", 2], r = stats::cor(residuals(stats::lm(oc ~ year, d)), d$nino34_anom)) }
cat(sprintf("GCB observed: slope %+.4f +/- %.4f GtC/yr per index, r %+.3f (n %d)\n", OBS_SLOPE, OBS_SE, stats::cor(residuals(stats::lm(ocean_sink ~ year, mg)), mg$nino34_anom), nrow(mg)))
# the floor's clipping on the FORCING (demeaned monthly index, the objective's own record)
x <- en$nino34_anom[en$year >= 1948 & en$year <= 2024]; x <- x - mean(x)
ov <- dg_gateV_obs()

# ---- gate 1: the canonical as shipped reproduces its stored streams -----
r_can <- dg_run(v); st_can <- unlist(dg_streams(r_can, v)); e_can <- enso_slope(r_can); V_can <- dg_gateV(r_can)
d1 <- max(abs(st_can[names(v$md$streams)] - v$md$streams))
cat(sprintf("gate 1: the canonical's 25 rows reproduce to %.1e (lik %.4f); ENSO slope %+.4f (r %+.3f); GATE V sd %.3f\n", d1, sum(st_can), e_can[["slope"]], e_can[["r"]], V_can$sd))
stopifnot(d1 < 1e-6)

run_at <- function(w, w0 = blk$w0_l2) {
  vv <- v; vv$p$gamma_enso_ocn_NH <- 0; vv$p$gamma_enso_ocn_SH <- 0
  vv$p$k_l2 <- blk$k_l2; vv$p$w0_l2 <- w0; vv$p$w_enso_l2 <- w
  r <- dg_run(vv); st <- unlist(dg_streams(r, vv)); e <- enso_slope(r); V <- dg_gateV(r)
  list(w = w, w0 = w0, st = st, lik = sum(st), slope = e[["slope"]], se = e[["se"]], r = e[["r"]], V_sd = V$sd,
       floor_frac = mean(x > w0 / max(w, 1e-9)))
}
rows <- lapply(L2_GRID, run_at)
sol <- rows[[1]]
cat(sprintf("\nN1 solubility-only (shim 0, limb 0): slope %+.4f (r %+.3f), lik %.2f; vs the 09-17 scan %+.4f / %+.3f / %.2f -> %s\n",
            sol$slope, sol$r, sol$lik, L2_REF_SOL[["slope"]], L2_REF_SOL[["r"]], L2_REF_SOL[["lik"]],
            if (abs(sol$slope - L2_REF_SOL[["slope"]]) < L2_REF_TOL[["slope"]] && abs(sol$r - L2_REF_SOL[["r"]]) < L2_REF_TOL[["r"]] &&
                abs(sol$lik - L2_REF_SOL[["lik"]]) < L2_REF_TOL[["lik"]]) "REPRODUCES" else "DOES NOT REPRODUCE"))
cat(sprintf("the shim's worth at the canonical: %+.2f (canonical %.2f vs solubility-only %.2f)\n\n", sum(st_can) - sol$lik, sum(st_can), sol$lik))

cat(sprintf("%-6s %9s %8s %7s %9s %9s %8s %6s  rows |d| > %.1f vs the canonical\n", "w", "slope", "se", "r", "dlik_can", "dlik_sol", "V_sd", "floor", L2_ROW_SHOW))
for (rw in rows) {
  dr <- rw$st - st_can[names(rw$st)]; big <- dr[abs(dr) > L2_ROW_SHOW]; big <- big[order(-abs(big))]
  cat(sprintf("%6.1f %+9.4f %8.4f %+7.3f %+9.2f %+9.2f %8.3f %6.3f  %s\n", rw$w, rw$slope, rw$se, rw$r, rw$lik - sum(st_can), rw$lik - sol$lik, rw$V_sd, rw$floor_frac,
              if (length(big)) paste(sprintf("%s %+.2f", names(big), big), collapse = ", ") else "-"))
}
# the gain and where the observed slope is reached (linear fit over the grid below the floor's reach)
ws <- vapply(rows, `[[`, numeric(1), "w"); sl <- vapply(rows, `[[`, numeric(1), "slope")
fit <- stats::lm(sl ~ ws); gain <- coef(fit)[["ws"]]; w_obs <- (OBS_SLOPE - coef(fit)[[1]]) / gain
cat(sprintf("\nslope = %+.4f + %.5f x w (R2 %.5f); the OBSERVED slope is reached at w = %.1f Sv per index [%.1f, %.1f] at GCB's +/-1 se\n",
            coef(fit)[[1]], gain, summary(fit)$r.squared, w_obs, (OBS_SLOPE - OBS_SE - coef(fit)[[1]]) / gain, (OBS_SLOPE + OBS_SE - coef(fit)[[1]]) / gain))
w_flip <- -coef(fit)[[1]] / gain
cat(sprintf("r flips sign at w = %.1f; Meinen's bracket [%g, %g] reaches slope [%+.4f, %+.4f] = [%.2f, %.2f]x obs\n", w_flip, L2_BRACKET[1], L2_BRACKET[2],
            coef(fit)[[1]] + gain * L2_BRACKET[1], coef(fit)[[1]] + gain * L2_BRACKET[2],
            (coef(fit)[[1]] + gain * L2_BRACKET[1]) / OBS_SLOPE, (coef(fit)[[1]] + gain * L2_BRACKET[2]) / OBS_SLOPE))

# ---- P0e: the floor vs the unclipped linear anomaly at the bracket's top and at the need ----
lin <- lapply(c(25, w_obs), function(w) list(clip = run_at(w), lin = run_at(w, w0 = L2_LINEAR_W0)))
for (l in lin) cat(sprintf("floor vs linear at w %.1f: slope %+.4f vs %+.4f (%.1f %% apart), lik %.2f vs %.2f; the floor binds in %.1f %% of months\n",
                           l$clip$w, l$clip$slope, l$lin$slope, 100 * abs(l$clip$slope - l$lin$slope) / abs(l$lin$slope), l$clip$lik, l$lin$lik, 100 * l$clip$floor_frac))

# ---- VERDICTS (prereg 09-17k §4) ------------------------------------------
cat("\n=== VERDICTS (prereg 2026-09-17k, unrefitted) ===\n")
pe1_mono <- all(diff(sl) > 0); r18 <- rows[[which(ws == 18.7)]]$r
cat(sprintf("  PE1 slope monotone in w: %s; r positive by 18.7 (%+.3f): %s; the observed slope reached within [%g, %g] (%.1f): %s\n",
            if (pe1_mono) "PASS" else "FAIL", r18, if (r18 > 0) "PASS" else "FAIL", L2_PE1_REACH[1], L2_PE1_REACH[2], w_obs,
            if (w_obs >= L2_PE1_REACH[1] && w_obs <= L2_PE1_REACH[2]) "PASS" else "FAIL"))
r25 <- rows[[which(ws == 25)]]; d25 <- r25$st[L2_PE2_ROWS] - st_can[L2_PE2_ROWS]
cat(sprintf("  PE2 CO2-level rows at w 25 within %g log-units of the canonical: %s (%s)\n", L2_PE2_TOL,
            if (all(abs(d25) < L2_PE2_TOL)) "PASS" else "FAIL", paste(sprintf("%s %+.2f", L2_PE2_ROWS, d25), collapse = ", ")))
cat(sprintf("  N1 reproduces the 09-17 scan's solubility-only line: %s\n",
            if (abs(sol$slope - L2_REF_SOL[["slope"]]) < L2_REF_TOL[["slope"]]) "PASS" else "FAIL"))
cat(sprintf("  the PRE-CHECK's prediction (the need at [29.7, 35.0]): measured %.1f\n", w_obs))
saveRDS(list(rows = rows, canonical = list(st = st_can, slope = e_can, V = V_can), obs = c(slope = OBS_SLOPE, se = OBS_SE), fit = coef(fit), w_obs = w_obs,
             linear = lin, grid = L2_GRID, struct = L2_STRUCT, blk = blk, arm = CCX_MODE_CANONICAL, commit = system("git rev-parse --short HEAD", intern = TRUE),
             when = Sys.time()), L2_OUT)
cat(sprintf("saved %s (%.1f min)\nEXIT 0\n", L2_OUT, as.numeric(difftime(Sys.time(), t0, units = "mins"))))
