#!/usr/bin/env Rscript
# =====================================================================
# diag_iav_kernel_preview.R -- C5 of the interannual-cut preview (2026-10-06): can ONE response SHAPE satisfy both
# the growth record and the seasonal rows?
#
# WHY. calibration/diag_iav_cut_preview.R found that the growth record alone puts the land ENSO lag at ~5.9 months,
# while the four seasonal rows prefer ~1-2.6 months, and that their preference is INFORMATION (the observed per-year
# harmonics projected on the model's ENSO signature), not visibility (C2). A hypothesis that would explain both:
# the per-year harmonic fit responds to the within-year CURVATURE of the concentration (the ONSET of the flux
# anomaly), the 12-month growth to the smoothed flux (its CENTROID). The model's land term is one fixed delay of
# Nino 3.4, so its onset and centroid move together; a response with a short onset and a memory tail would let them
# separate. This preview TESTS that, before anyone builds it.
#
# THE SHAPE. The land term's input becomes the lagged index passed through a CAUSAL exponential memory,
#   x(t) = sum_{j=0..J} w_j N(t - L - j),  w_j = exp(-j / tau) / sum(exp(-j / tau)),  tau = 0 -> the model as built.
# Normalized, so the amplitude keeps its meaning (GtC/yr per index unit, integrated). It is applied by wrapping
# ccx_land_enso() for the duration of a run (both cores read the land series through it); tau = 0 is GATED
# identical() to the unwrapped run, and tau > 0 must move the answer. The ocean limb keeps reading the index at t.
#
# AT EACH (L, tau): the growth module's fit (the cut's stage 1: a common land scale s and gamma_diff fitted by
# superposition on the detrended monthly growth, the ocean limb at the canonical), then a REAL run at that fit, scored
# by the main objective's own rows (dg_streams): the seasonal rows, gcb_land_sink, the total -- every other name at
# the canonical, unrefitted.
# ⛔ ADOPTS NOTHING; a diagnostic wrapper, not a model change. No RNG.
# Usage: Rscript calibration/diag_iav_kernel_preview.R   (CCX_KP_SMOKE=1)
# =====================================================================
t_start <- Sys.time()
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
KP_DRIVER <- "calibration/diag_iav_kernel_preview.R"
KP_SMOKE  <- identical(Sys.getenv("CCX_KP_SMOKE", ""), "1")
KP_MODE   <- CCX_MODE_CANONICAL
KP_GAMMA  <- c("gamma_enso_land_NH", "gamma_enso_land_SH")
KP_OCEAN  <- "w_enso_l2"
KP_VOLC   <- "gamma_diff"
KP_TAUS   <- c(0, 1, 2, 3, 4, 6, 9)                     # months of memory
KP_LAGS   <- c(0, 0.5, 1, 1.5, 2, 2.5, 3, 4, 5, 6, 7)   # months of onset delay
KP_J      <- 36L                                        # kernel truncation, months
SEAS_ROWS <- c("co2_seasonal_MLO", "co2_seasonal_SPO", "d13c_seasonal_MLO", "d13c_seasonal_SPO")
KP_LAND_ROW <- "gcb_land_sink"
BR_WIN <- c(1980L, 2024L); BR_TREND_DF <- 5L
BR_OBS_WEEKLY <- file.path("data-raw", "downloads", "mbl_zonal_co2_GL.txt")
if (KP_SMOKE) { KP_TAUS <- c(0, 3); KP_LAGS <- c(1, 4) }
KP_TAG <- paste0(format(Sys.Date(), "%Y%m%d"), "_", KP_MODE, if (KP_SMOKE) "_SMOKE" else "")
KP_OUT <- file.path("outputs", "diagnostics", sprintf("iav_kernel_preview_%s", KP_TAG))
COMMIT <- ccx_git_stamp()
source(file.path("calibration", "lib_block_reopt.R"))   # br_vec, br_cen12, br_obs_growth
LOGCON <- file(paste0(KP_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | canonical %s%s\n", KP_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), KP_MODE,
            if (KP_SMOKE) " | ⚠ SMOKE: tiny grid, NOT A RESULT" else ""))

BR_OBS <- ccx_prepare_obs()
MODE_FILE <- ccx_mode_file(KP_MODE); md <- readRDS(MODE_FILE); MODE_MD5 <- unname(tools::md5sum(MODE_FILE))
BR_MD <- list(BASE = md); BR_VB <- list(BASE = dg_vector(MODE_FILE))
L0 <- md$par_mode[["lag_enso_land"]]; G0 <- vapply(KP_GAMMA, function(n) md$par_mode[[n]], 0)
W0 <- md$par_mode[[KP_OCEAN]]; D0 <- BR_VB$BASE$p[[KP_VOLC]]
OBS_G <- br_obs_growth()
vec_at <- function(L, s = 1, d = D0, w = W0) {
  v <- br_vec("BASE", c(stats::setNames(s * G0, KP_GAMMA), stats::setNames(w, KP_OCEAN)), L); v$p[[KP_VOLC]] <- d; v }

# ---- the memory kernel, applied by wrapping the land series' one builder ---------------------------------------
.LAND_ENSO_ORIG <- ccx_land_enso
kern_w <- function(tau) if (tau == 0) 1 else { w <- exp(-(0:KP_J) / tau); w / sum(w) }
kern_centroid <- function(tau) sum((seq_along(kern_w(tau)) - 1) * kern_w(tau))
run_k <- function(L, tau, ...) {
  v <- vec_at(L, ...)
  if (tau > 0) { w <- kern_w(tau)
    # causal convolution with ZERO history. Exact for the one call that spans 1750-2025 (the index is 0 before
    # 1948); the spinup's short calls carry no ENSO at all, which is asserted rather than assumed.
    assign("ccx_land_enso", function(enso, L, hist = NULL) { x <- as.numeric(.LAND_ENSO_ORIG(enso, L, hist)); n <- length(x)
      if (n <= length(w) && any(x != 0)) stop("run_k(): a short land-ENSO series with a nonzero index; zero history is not exact")
      y <- x * w[1]
      for (j in seq_along(w)[-1]) { if (j > n) break; y[j:n] <- y[j:n] + w[j] * x[seq_len(n - j + 1)] }
      y }, envir = globalenv())
    on.exit(assign("ccx_land_enso", .LAND_ENSO_ORIG, envir = globalenv()), add = TRUE) }
  r <- dg_run(v); r$v <- v; r }

growth_m <- function(r) {
  m <- data.frame(k = r$F$year * 12L + r$F$month, g = br_cen12((r$out$co2_NH + r$out$co2_SH) / 2))
  M <- merge(m, OBS_G, by = "k", suffixes = c("_mod", "_obs"))
  M[M$k >= BR_WIN[1] * 12L + 1L & M$k <= BR_WIN[2] * 12L + 12L & stats::complete.cases(M), ] }
streams <- function(r) unlist(dg_streams(r, r$v, obs = BR_OBS))

cat("\n=== 0. GATES ===\n")
RC <- run_k(L0, 0)
SC <- streams(RC)
cat(sprintf("  tau = 0 reproduces the unwrapped run: %s; canonical likelihood %.6f (stored streams sum %.6f)\n",
            identical(RC$out, dg_run(vec_at(L0))$out), sum(SC), sum(unlist(md$streams))))
if (!identical(RC$out, dg_run(vec_at(L0))$out) || abs(sum(SC) - sum(unlist(md$streams))) > 1e-6) stop("tau = 0 gate failed")
Rk3 <- run_k(L0, 3)
moved <- max(abs(Rk3$out$co2_NH - RC$out$co2_NH))
cat(sprintf("  tau = 3 moves the NH box by up to %.3f ppm (must be > 0); the wrapper is restored after the run: %s\n",
            moved, identical(ccx_land_enso, .LAND_ENSO_ORIG)))
if (moved <= 0 || !identical(ccx_land_enso, .LAND_ENSO_ORIG)) stop("the kernel wrapper gate failed")

# ---- the bases: everything interannual OFF, the diffuse-light and ocean terms alone ---------------------------
R000 <- run_k(L0, 0, s = 0, d = 0, w = 0); M000 <- growth_m(R000); k_ref <- M000$k
X <- stats::model.matrix(~ splines::ns((k_ref - 1) / 12, df = BR_TREND_DF)); Qm <- function(g) as.numeric(g - X %*% qr.solve(X, g))
gm <- function(r) { M <- growth_m(r); stopifnot(identical(M$k, k_ref)); M$g_mod }
y_obs <- Qm(M000$g_obs); g000 <- Qm(M000$g_mod)
Vb <- Qm(gm(run_k(L0, 0, s = 0, d = D0, w = 0)) - M000$g_mod)
Ob <- Qm(gm(run_k(L0, 0, s = 0, d = 0, w = W0)) - M000$g_mod)
ssr_can <- sum((Qm(gm(RC)) - y_obs)^2)
nnls2 <- function(y, A) { best <- list(b = c(0, 0), ssr = sum(y^2))
  for (S in list(1, 2, 1:2)) { b <- qr.solve(A[, S, drop = FALSE], y); if (any(b < 0)) next
    bb <- c(0, 0); bb[S] <- b; ssr <- sum((y - A %*% bb)^2); if (ssr < best$ssr) best <- list(b = bb, ssr = ssr) }
  best }

cat(sprintf("\n=== C5. THE GRID: %d onset lags x %d memories; at each, the growth module's fit, then the main rows at it ===\n",
            length(KP_LAGS), length(KP_TAUS)))
GRID <- do.call(rbind, lapply(KP_TAUS, function(tau) do.call(rbind, lapply(KP_LAGS, function(L) {
  E <- Qm(gm(run_k(L, tau, s = 1, d = 0, w = 0)) - M000$g_mod)
  fit <- nnls2(y_obs - g000 - Ob, cbind(E, Vb)); s <- fit$b[1]; d <- fit$b[2] * D0
  r <- run_k(L, tau, s = s, d = d); st <- streams(r); g <- Qm(gm(r))
  data.frame(tau = tau, L = L, centroid = L + kern_centroid(tau), s = s, gamma_diff = d,
             ssr_ratio = sum((g - y_obs)^2) / ssr_can, r = stats::cor(g, y_obs),
             d_seas = sum(st[SEAS_ROWS]) - sum(SC[SEAS_ROWS]), d_land = st[[KP_LAND_ROW]] - SC[[KP_LAND_ROW]],
             d_other = sum(st) - sum(SC) - (sum(st[SEAS_ROWS]) - sum(SC[SEAS_ROWS])) - (st[[KP_LAND_ROW]] - SC[[KP_LAND_ROW]]),
             d_lik = sum(st) - sum(SC)) }))))
print(GRID, digits = 3, row.names = FALSE)
NE_M <- 22.5   # the monthly n_eff measured at the canonical (diag_iav_cut_preview.R; 10-06 timing re-read)
GRID$dll_growth <- -(NE_M / 2) * log(GRID$ssr_ratio)
b_g <- GRID[which.max(GRID$dll_growth), ]; b_s <- GRID[which.max(GRID$d_seas), ]
cat(sprintf("\n  best for the GROWTH (n_eff %.1f): tau %g, L %g (centroid %.1f months): growth %+.2f, seasonal rows %+.2f, land sink %+.2f, all rows %+.2f\n",
            NE_M, b_g$tau, b_g$L, b_g$centroid, b_g$dll_growth, b_g$d_seas, b_g$d_land, b_g$d_lik))
cat(sprintf("  best for the SEASONAL ROWS (at the growth-fitted amplitudes): tau %g, L %g (centroid %.1f): growth %+.2f, seasonal rows %+.2f, land sink %+.2f\n",
            b_s$tau, b_s$L, b_s$centroid, b_s$dll_growth, b_s$d_seas, b_s$d_land))
cat("  per memory, the onset lag that is best for the growth, and what the seasonal rows say there:\n")
PT <- do.call(rbind, lapply(split(GRID, GRID$tau), function(G) { j <- which.max(G$dll_growth)
  data.frame(tau = G$tau[j], L_best_growth = G$L[j], centroid = G$centroid[j], dll_growth = G$dll_growth[j], d_seas = G$d_seas[j],
             d_land = G$d_land[j], d_lik = G$d_lik[j], L_best_seas = G$L[which.max(G$d_seas)], d_seas_best = max(G$d_seas)) }))
print(PT, digits = 3, row.names = FALSE)

sink()
saveRDS(list(grid = GRID, per_tau = PT, best_growth = b_g, best_seas = b_s,
             provenance = list(driver = KP_DRIVER, commit = COMMIT, mode = KP_MODE, mode_file = MODE_FILE, mode_md5 = MODE_MD5,
                               taus = KP_TAUS, lags = KP_LAGS, kernel_J = KP_J, window = BR_WIN, trend_df = BR_TREND_DF,
                               n_eff_monthly = NE_M, rng = "none", smoke = KP_SMOKE, date = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(KP_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds} | %.1f min\n", KP_OUT, as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
