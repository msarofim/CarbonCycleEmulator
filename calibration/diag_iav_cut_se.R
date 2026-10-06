#!/usr/bin/env Rscript
# =====================================================================
# diag_iav_cut_se.R -- ERROR BARS on the growth module's amplitudes (2026-10-06), at the lag the preview found.
#
# WHY. calibration/diag_iav_cut_preview.R reports the growth module's optimum (arm A1: the land ENSO lag, a common
# land scale s, gamma_diff) and the lag's profile range, but not s's or gamma_diff's. A ratio "the growth wants
# gamma_diff 0.56, the canonical holds 0.25" is not a finding until it has a bar (the standing rule: a magnitude
# needs its error bar before it needs an explanation).
# METHOD. At the preview's A1 lag (read from its rds), the same superposition bases, the same detrended estimators.
# Each amplitude's PROFILE likelihood, the other re-fitted at every point, at the measured n_eff:
#   l(x) = -(n_eff / 2) log(SSR(x) / SSR_min);  1 sigma where l >= -0.5, 2 sigma where l >= -2.
# Both estimators (monthly n_eff 22.5, annual 44.8), and the correlation of the two estimates (OLS, n_eff-scaled).
# ⛔ ADOPTS NOTHING. No RNG.
# Usage: Rscript calibration/diag_iav_cut_se.R [path/to/iav_cut_preview_<tag>.rds]
# =====================================================================
t_start <- Sys.time()
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
SE_DRIVER <- "calibration/diag_iav_cut_se.R"
args <- commandArgs(trailingOnly = TRUE)
SE_IN <- if (length(args)) args[1] else {
  c0 <- list.files(file.path("outputs", "diagnostics"), pattern = "^iav_cut_preview_[0-9]{8}_[a-z0-9]+[.]rds$", full.names = TRUE)
  if (!length(c0)) stop("no iav_cut_preview rds; pass a path"); sort(c0, decreasing = TRUE)[1] }
SE_GAMMA <- c("gamma_enso_land_NH", "gamma_enso_land_SH"); SE_OCEAN <- "w_enso_l2"; SE_VOLC <- "gamma_diff"
SE_GRID_S <- seq(0.5, 2.5, by = 0.01); SE_GRID_D <- seq(0, 1.5, by = 0.005)
SE_SIG <- c(one = 0.5, two = 2)
BR_OBS_WEEKLY <- file.path("data-raw", "downloads", "mbl_zonal_co2_GL.txt")
SE_OUT <- sub("iav_cut_preview_", "iav_cut_se_", sub("[.]rds$", "", SE_IN))
COMMIT <- ccx_git_stamp()
source(file.path("calibration", "lib_block_reopt.R"))
PV <- readRDS(SE_IN); P <- PV$provenance
BR_WIN <- P$window; BR_TREND_DF <- P$trend_df
LOGCON <- file(paste0(SE_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | from %s (%s @%s)\n", SE_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), SE_IN, P$driver, P$commit))

MODE_FILE <- ccx_mode_file(P$mode); md <- readRDS(MODE_FILE)
stopifnot(identical(unname(tools::md5sum(MODE_FILE)), P$mode_md5))
BR_MD <- list(BASE = md); BR_VB <- list(BASE = dg_vector(MODE_FILE))
G0 <- vapply(SE_GAMMA, function(n) md$par_mode[[n]], 0); W0 <- md$par_mode[[SE_OCEAN]]; D0 <- BR_VB$BASE$p[[SE_VOLC]]
L1 <- PV$A1[["L"]]
OBS_G <- br_obs_growth(); ANN <- readRDS(P$obs_annual)$growth
run_at <- function(L, s, d, w) { v <- br_vec("BASE", c(stats::setNames(s * G0, SE_GAMMA), stats::setNames(w, SE_OCEAN)), L)
  v$p[[SE_VOLC]] <- d; dg_run(v) }
est <- list(
  m = function(r) { m <- data.frame(k = r$F$year * 12L + r$F$month, g = br_cen12((r$out$co2_NH + r$out$co2_SH) / 2))
    M <- merge(m, OBS_G, by = "k", suffixes = c("_mod", "_obs"))
    M <- M[M$k >= BR_WIN[1] * 12L + 1L & M$k <= BR_WIN[2] * 12L + 12L & stats::complete.cases(M), ]
    list(t = (M$k - 1) / 12, mod = M$g_mod, obs = M$g_obs) },
  a = function(r) { co2 <- tapply((r$out$co2_NH + r$out$co2_SH) / 2, floor(r$out$t), mean)
    gm <- data.frame(year = as.integer(names(co2))[-1], g_mod = diff(as.numeric(co2)))
    A <- merge(gm, stats::setNames(ANN[, 1:2], c("year", "g_obs")), by = "year"); A <- A[A$year >= BR_WIN[1] & A$year <= BR_WIN[2], ]
    list(t = A$year, mod = A$g_mod, obs = A$g_obs) })
R <- list(g000 = run_at(L1, 0, 0, 0), E = run_at(L1, 1, 0, 0), V = run_at(L1, 0, D0, 0), O = run_at(L1, 0, 0, W0))
OUT <- list()
for (e in names(est)) {
  b <- lapply(R, est[[e]]); X <- stats::model.matrix(~ splines::ns(b$g000$t, df = BR_TREND_DF))
  Q <- function(g) as.numeric(g - X %*% qr.solve(X, g))
  y <- Q(b$g000$obs) - Q(b$g000$mod) - Q(b$O$mod - b$g000$mod)
  xs <- Q(b$E$mod - b$g000$mod); xd <- Q(b$V$mod - b$g000$mod)
  n_e <- PV$n_eff[[e]]
  ssr_at <- function(s, dd) sum((y - s * xs - dd * xd)^2)
  # each amplitude profiled, the other re-fitted (non-negative) at every grid point
  prof_s <- vapply(SE_GRID_S, function(s) { r <- y - s * xs; dd <- max(0, sum(r * xd) / sum(xd^2)); ssr_at(s, dd) }, 0)
  prof_d <- vapply(SE_GRID_D / D0, function(dd) { r <- y - dd * xd; s <- max(0, sum(r * xs) / sum(xs^2)); ssr_at(s, dd) }, 0)
  rng <- function(grid, ssr, dl) { ll <- -(n_e / 2) * log(ssr / min(ssr)); range(grid[ll >= -dl]) }
  A <- cbind(xs, xd); bh <- qr.solve(A, y); s2 <- sum((y - A %*% bh)^2) / (length(y) - 2)
  V <- s2 * solve(crossprod(A)) * length(y) / n_e
  OUT[[e]] <- data.frame(estimator = e, n_eff = n_e, L = L1, s = bh[1], s_1lo = rng(SE_GRID_S, prof_s, SE_SIG[["one"]])[1],
    s_1hi = rng(SE_GRID_S, prof_s, SE_SIG[["one"]])[2], s_2lo = rng(SE_GRID_S, prof_s, SE_SIG[["two"]])[1],
    s_2hi = rng(SE_GRID_S, prof_s, SE_SIG[["two"]])[2], gamma_diff = bh[2] * D0,
    d_1lo = rng(SE_GRID_D, prof_d, SE_SIG[["one"]])[1], d_1hi = rng(SE_GRID_D, prof_d, SE_SIG[["one"]])[2],
    d_2lo = rng(SE_GRID_D, prof_d, SE_SIG[["two"]])[1], d_2hi = rng(SE_GRID_D, prof_d, SE_SIG[["two"]])[2],
    se_s_ols = sqrt(V[1, 1]), se_d_ols = sqrt(V[2, 2]) * D0, cor_s_d = V[1, 2] / sqrt(V[1, 1] * V[2, 2]),
    z_d_vs_canonical = (bh[2] * D0 - D0) / (sqrt(V[2, 2]) * D0), z_s_vs_canonical = (bh[1] - 1) / sqrt(V[1, 1]))
}
TAB <- do.call(rbind, OUT); rownames(TAB) <- NULL
cat(sprintf("at the A1 lag %.3f months; profile ranges (the other amplitude re-fitted), and OLS se scaled by n/n_eff:\n", L1))
print(TAB, digits = 3, row.names = FALSE)
sink()
saveRDS(list(tab = TAB, provenance = list(driver = SE_DRIVER, commit = COMMIT, input = SE_IN, input_commit = P$commit,
                                          mode = P$mode, mode_md5 = P$mode_md5, L = L1, rng = "none",
                                          date = format(Sys.time(), "%Y-%m-%d %H:%M"))), paste0(SE_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds} | %.1f min\n", SE_OUT, as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
