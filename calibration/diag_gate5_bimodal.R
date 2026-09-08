# =====================================================================
# GATE 5's NH statistic on a DOUBLE-PEAKED curve (2026-09-08h).
# The observed NH bomb curve has two peaks (the 1963 and 1964 spring
# stratospheric intrusions); dg_peak() is an argmax, so which lump is higher
# decides "the peak time" by a whole year. The model reproduces the double peak
# with the SECOND lump higher; the observation has the FIRST higher by 2.4 %.
# T-I's 1:1 input-timing sensitivity and diag_nh_bomb_levers.R's ZERO removal
# sensitivity are both this. Reads: peak 1 / trough / peak 2 for obs and model;
# the estimator's flip under a +/- tilt of the OBSERVED series (a mutation of
# the statistic, not the model); and whether a removal lever deepens the
# model's trough. ⚠ No Joos anything. Nothing adopted.
# Usage: Rscript calibration/diag_gate5_bimodal.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
G5_W1 <- c(1963.3, 1964.05); G5_WT <- c(1963.9, 1964.45); G5_W2 <- c(1964.3, 1965.1)   # peak 1 / trough / peak 2 windows, yr
G5_TILT <- c(-0.05, -0.03, -0.02, 0, 0.02, 0.03, 0.05)                                 # per yr about 1964.15, applied to the OBSERVED series
G5_LEVERS <- list(tau_ex = c(0.5, 1, 2), k_w = c(1, 2, 3), h_ml = c(1, 2))
G5_OUT <- ccx_path("outputs", "diagnostics", sprintf("gate5_bimodal_%s.rds", format(Sys.Date(), "%Y%m%d")))
feat <- function(t, v) { w <- function(win, f) { k <- t >= win[1] & t <= win[2]; i <- which(k)[f(v[k])]; c(t = t[i], v = v[i]) }
  p1 <- w(G5_W1, which.max); tr <- w(G5_WT, which.min); p2 <- w(G5_W2, which.max)
  c(p1_t = p1[["t"]], p1_v = p1[["v"]], tr_t = tr[["t"]], tr_v = tr[["v"]], p2_t = p2[["t"]], p2_v = p2[["v"]], drop = p1[["v"]] - tr[["v"]], p2_minus_p1 = p2[["v"]] - p1[["v"]], argmax_t = dg_peak(t, v)[["t"]]) }
ob <- dg_obs_bomb$NH; fo <- feat(ob$t, ob$v)
v <- dg_vector(CCX_MODE_CANONICAL); r <- dg_run(v); fm <- feat(r$out$t, r$out$d14c_NH)
ob5 <- dg_obs_gate5(); sp5 <- dg_obs_gate5_spread()
cat("=== 1. The two peaks and the trough (NH, permil) ===\n")
cat(sprintf("  %-8s peak1 %.2f (%.0f)  trough %.2f (%.0f)  peak2 %.2f (%.0f)  drop %.0f  peak2-peak1 %+.0f  argmax -> %.2f\n", "observed", fo[["p1_t"]], fo[["p1_v"]], fo[["tr_t"]], fo[["tr_v"]], fo[["p2_t"]], fo[["p2_v"]], fo[["drop"]], fo[["p2_minus_p1"]], fo[["argmax_t"]]))
cat(sprintf("  %-8s peak1 %.2f (%.0f)  trough %.2f (%.0f)  peak2 %.2f (%.0f)  drop %.0f  peak2-peak1 %+.0f  argmax -> %.2f\n", "model", fm[["p1_t"]], fm[["p1_v"]], fm[["tr_t"]], fm[["tr_v"]], fm[["p2_t"]], fm[["p2_v"]], fm[["drop"]], fm[["p2_minus_p1"]], fm[["argmax_t"]]))
cat(sprintf("  peak-1 timing: model minus obs %+.2f yr (%+.2f of gate 5's nh_t sd %.3f); peak-2 timing %+.2f yr; the argmax difference %+.2f yr is the two curves choosing DIFFERENT lumps\n",
            fm[["p1_t"]] - fo[["p1_t"]], (fm[["p1_t"]] - fo[["p1_t"]]) / sp5$sd[["nh_t"]], sp5$sd[["nh_t"]], fm[["p2_t"]] - fo[["p2_t"]], fm[["argmax_t"]] - fo[["argmax_t"]]))
cat("\n=== 2. The statistic's fragility: tilt the OBSERVED series by (1 + s (t - 1964.15)) and re-read its argmax ===\n")
for (s in G5_TILT) { vv <- ob$v * (1 + s * (ob$t - 1964.15)); cat(sprintf("  tilt %+.2f/yr (peak2/peak1 ratio %.3f): argmax %.2f\n", s, max(vv[ob$t >= G5_W2[1] & ob$t <= G5_W2[2]]) / max(vv[ob$t >= G5_W1[1] & ob$t <= G5_W1[2]]), dg_peak(ob$t, vv)[["t"]])) }
cat(sprintf("  (the observed peak-1/peak-2 heights differ by %.1f %%; the zonal spread on nh_v is %.0f permil = %.1f %% -- the observed argmax is itself a coin toss between lumps, which is what the %.2f-yr nh_t spread records)\n", 100 * abs(fo[["p2_minus_p1"]]) / fo[["p1_v"]], sp5$sd[["nh_v"]], 100 * sp5$sd[["nh_v"]] / fo[["p1_v"]], sp5$sd[["nh_t"]]))
cat("\n=== 3. Do the removal levers change the SHAPE (trough depth, peak2 - peak1)? ===\n")
RES <- list()
for (lv in names(G5_LEVERS)) for (x in G5_LEVERS[[lv]]) { va <- v; va$p[[lv]] <- v$p[[lv]] * x; rr <- dg_run(va); f <- feat(rr$out$t, rr$out$d14c_NH); RES[[sprintf("%s_%g", lv, x)]] <- c(lever = lv, x = x, f)
  cat(sprintf("  %-7s x %.1f: peak1 %.0f @ %.2f  trough %.0f  peak2 %.0f @ %.2f  drop %.0f (obs %.0f)  peak2-peak1 %+.0f (obs %+.0f)  argmax %.2f\n", lv, x, f[["p1_v"]], f[["p1_t"]], f[["tr_v"]], f[["p2_v"]], f[["p2_t"]], f[["drop"]], fo[["drop"]], f[["p2_minus_p1"]], fo[["p2_minus_p1"]], f[["argmax_t"]])) }
cat("\n=== 4. READING ===\n")
cat("  Gate 5's 'NH peak +2.17 sigma late' is the argmax choosing the 1964 lump in the model and the 1963 lump in the observation. The model's peak-1 timing is",
    sprintf("%+.2f yr", fm[["p1_t"]] - fo[["p1_t"]]), "from the observed. The miss is the SHAPE: the observed curve drops", sprintf("%.0f", fo[["drop"]]), "between the peaks, the model", sprintf("%.0f;", fm[["drop"]]),
    "no removal lever in the scan reproduces that drop, so the model's atmosphere holds too much of the 1963 delivery into 1964 -- either the delivery series' 1963-Q4/1964-Q1 share (Tans Table 2 quarterly intervals, shaped by the observed record) or a removal path the scan does not touch (the NH land's fast pools). The gate needs a statistic that is not an argmax on a bimodal curve: peak-1 time, the trough depth, or the curve RMS the d14c_NH stream already scores.\n")
saveRDS(list(obs = fo, model = fm, levers = RES, windows = list(p1 = G5_W1, tr = G5_WT, p2 = G5_W2), date = Sys.time(), mode = CCX_MODE_CANONICAL), G5_OUT)
cat(sprintf("saved %s\n⛔ Nothing adopted.\n", G5_OUT))
