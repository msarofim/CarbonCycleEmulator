#!/usr/bin/env Rscript
# =====================================================================
# fit_iav_module.R -- OBJECTIVE #17's STAGE 1: the interannual MODULE fitted to its own two observations
# (RULED 2026-10-06 n; Marcus: "Build: land + ocean module (Recommended)"). R/likelihood.R "OBJECTIVE #17".
#
# WHAT. The module's names -- the land ENSO lag L, ONE scale s on the two land amplitudes (NH : SH held at
# hilda33p's, since the global growth sees only their sum) and the ocean ENSO limb w = w_enso_l2 -- are
# fitted to the module's likelihood, ccx_iav_module_loglik():
#     -(n_eff / 2) log(SSR / SSR_ref) + gcb_ocean_enso_slope's row,
# the SSR on the detrended monthly global growth (1980-2024, n_eff LIK_IAV_NEFF), the slope row pinning
# the limb. Every OTHER name is held at the BASE mode file's values (stage 2 then refits them with the
# module's names pinned). gamma_diff stays at the base's fixed 0.25 (Marcus: "land ENSO only").
# The priors are left out, as ruled (the handoff's objective): the lag's U(0, 12) and w's U(0, 60) are flat,
# and the land pair's N(0, 2) moves the log-density by ~0.02 across the whole move, so the module's optimum
# is its maximum-likelihood point.
#
# HOW (the preview's method, CHANGELOG 10-06 l / m, on real runs throughout but the first step):
#   1 BASIN    a superposition scan over L (one run per lag; s fitted in closed form, w at the base) finds
#              the basin -- a START, never an answer;
#   2 OPTIMUM  Nelder-Mead on (L, log s, w) over REAL runs of the full module objective, from that start;
#   3 PROFILE  the lag's profile on real runs (s, w re-optimised per lag), its 1- and 2-sigma ranges
#              (drops of 0.5 / 2 in log-likelihood);
#   4 LAPLACE  the module's Hessian in (L, s, w) by central differences on real runs -> the covariance the
#              ruled cut posterior propagates (Marcus: "Laplace + propagation (Recommended)"). The steps stay
#              inside one month of L: the lag's cubic stencil is smooth within a month, kinked at whole months.
#   + CHECK    with --check=<an earlier stage-1 rds>: how far each name moved, in that run's own 1-sigma
#              (Marcus: "One pass + check (Recommended)": stop below 0.1 sigma; a larger move goes to him).
#
# GATES (the driver stops on any): the ratio file is the one the ruling names (md5); the base reproduces its
# stored rows through the dg path (<= 1e-6); the superposition reproduces a direct run; the profile's best
# lag is the optimum's; the Hessian is negative definite.
# OUTPUTS: calibration/output/iav_module_<date>_<base>.rds (the stage-1 RESULT stage 2 pins from) and
# outputs/diagnostics/iav_module_<date>_<base>.log. ⛔ ADOPTS NOTHING. No RNG.
# Usage: Rscript calibration/fit_iav_module.R [--base=<mode name or file>] [--check=<stage-1 rds>]
#        (CCX_IAV_WORKERS, default 6; CCX_IAV_SMOKE=1 for tiny budgets)
# =====================================================================
t_start <- Sys.time()
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
IAV_DRIVER   <- "calibration/fit_iav_module.R"
IAV_ARGS     <- commandArgs(trailingOnly = TRUE)
iav_arg <- function(key, default) { h <- grep(sprintf("^--%s=", key), IAV_ARGS, value = TRUE)
  if (length(h)) sub(sprintf("^--%s=", key), "", h[1]) else default }
IAV_BASE     <- iav_arg("base", CCX_MODE_CANONICAL)
IAV_CHECK    <- iav_arg("check", "")
IAV_SMOKE    <- identical(Sys.getenv("CCX_IAV_SMOKE", ""), "1")
IAV_WORKERS  <- as.integer(Sys.getenv("CCX_IAV_WORKERS", "6"))
IAV_GAMMA    <- c("gamma_enso_land_NH", "gamma_enso_land_SH")   # scaled TOGETHER by s
IAV_OCEAN    <- "w_enso_l2"
IAV_LAG      <- "lag_enso_land"
stopifnot(identical(CCX_IAV_MODULE_NAMES, c(IAV_LAG, IAV_GAMMA, IAV_OCEAN)))
# THE NH : SH RATIO is hilda33p's (ruled: "NH : SH held at the canonical's"), NAMED and md5-checked, so it
# cannot drift with the base: s = 1 means hilda33p's two amplitudes.
IAV_RATIO_MODE <- "hilda33p"
IAV_RATIO_MD5  <- "525404989a20ece51ec8bd088c7d4638"
IAV_LAG_MAX  <- CCX_ENSO_LAG_MAX                                # the lag's prior support, (0, 12) months
IAV_W_MAX    <- CCX_PARAM_TABLE[[IAV_OCEAN]]$hi                 # the limb's prior support, (0, 60)
IAV_LAGS_SUP <- seq(0.5, 10, by = 0.25)                         # 1 BASIN: the preview's grid (CUT_LAGS_A)
IAV_NM_MAXIT <- 400L; IAV_NM_RELTOL <- 1e-8                     # 2 OPTIMUM (the preview: 2 x 150, 1e-8)
IAV_PROF_LAGS <- c(2, 3, 4, 4.5, 5, 5.5, 6.5, 7, 7.5, 8, 9, 10) # 3 PROFILE (+ the optimum's own lag)
IAV_PROF_MAXIT <- 150L
IAV_SIG      <- c(one = 0.5, two = 2)                           # profile drops for the 1 / 2 sigma ranges
IAV_H_STEP   <- c(L = 0.05, s = 0.01, w = 0.25)                 # 4 LAPLACE: central-difference steps
IAV_CHECK_TOL <- 0.1                                            # + CHECK: RULED, in each name's own 1 sigma
# 0 GATES: the base's stored rows through the dg path, max |diff| PER ROW. RULED 2026-10-07 (Marcus: "Raise to 1e-5, named
# (Recommended)"). It was a literal 1e-6, and it stopped #17's landing check at basin A (id 10: 1.7e-6, in the three d13C
# level / ice-core rows) on the OBJECTIVE's numerical noise floor, not on a defect: a 1e-12 nudge of one name moves the rows
# by 0.4-1.6e-6 at BOTH basins, and basin B passed at 1e-10 only because its path crossed no step (CHANGELOG 2026-10-07 a).
# 1e-5 is the tolerance promote_multistart_mode.R GATE 4 and recompute_hessian.R GATE 1 use for the same question, ~6x the
# measured per-row floor. Mutation-tested 2026-10-07: a dropped land ENSO pin still fails it.
IAV_REPRO_TOL <- 1e-5
IAV_XLAGS    <- -6:18                                           # the timing read (br_timing's BR_XLAGS)
IAV_PREVIEW  <- file.path("outputs", "diagnostics", "iav_cut_smoothed_land_20261006_hilda33p.rds")  # its land_ocean scope
if (IAV_SMOKE) { IAV_LAGS_SUP <- c(1, 3, 6, 9); IAV_NM_MAXIT <- 8L; IAV_PROF_LAGS <- c(4, 7); IAV_PROF_MAXIT <- 4L }
IAV_DATE <- format(Sys.Date(), "%Y%m%d")
COMMIT   <- ccx_git_stamp()

# ---- the base, the ratio, the observations ------------------------------------------
BASE_FILE <- ccx_mode_file(IAV_BASE); md <- readRDS(BASE_FILE)
# a promoted file is always `mode_fit_pump<arm>.rds`, so its DIRECTORY names it (refit_<date>_obj17_...)
BASE_NAME <- if (file.exists(IAV_BASE)) {
  b <- sub("[.]rds$", "", basename(IAV_BASE)); if (grepl("^mode_fit_pump", b)) basename(dirname(IAV_BASE)) else b
} else IAV_BASE
IAV_TAG  <- paste0(IAV_DATE, "_", BASE_NAME, if (IAV_SMOKE) "_SMOKE" else "")
IAV_OUT  <- file.path("calibration", "output", sprintf("iav_module_%s.rds", IAV_TAG))
IAV_LOG  <- file.path("outputs", "diagnostics", sprintf("iav_module_%s.log", IAV_TAG))
LOGCON <- file(IAV_LOG, open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | base %s (%s) | %d workers%s\n", IAV_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"),
            BASE_NAME, ccx_mode_struct(md), IAV_WORKERS, if (IAV_SMOKE) " | ⚠ SMOKE: tiny budgets, NOT A RESULT" else ""))
RATIO_FILE <- ccx_mode_file(IAV_RATIO_MODE)
if (!identical(unname(tools::md5sum(RATIO_FILE)), IAV_RATIO_MD5)) stop("the ratio file is not the one the ruling names")
mr <- readRDS(RATIO_FILE)
G0 <- vapply(IAV_GAMMA, function(n) mr$par_mode[[n]], 0)       # s = 1: hilda33p's amplitudes
OBS <- ccx_prepare_obs()
GRO <- ccx_iav_growth_obs()
VB  <- dg_vector(BASE_FILE)
if (!identical(VB$p[["gamma_diff"]], 0.25)) stop("gamma_diff is not the held 0.25 on this base")
B0 <- c(L = VB$p[[IAV_LAG]], s = VB$p[[IAV_GAMMA[1]]] / G0[[1]], w = VB$p[[IAV_OCEAN]])
s_sh <- VB$p[[IAV_GAMMA[2]]] / G0[[2]]
cat(sprintf("ratio %s (md5 %s): %s = %.7f / %.7f, NH : SH = %.4f; base's own: L %.4f, s %.5f (SH's %.5f), w %.4f, gamma_diff %.2f\n",
            IAV_RATIO_MODE, IAV_RATIO_MD5, paste(IAV_GAMMA, collapse = " / "), G0[[1]], G0[[2]], G0[[1]] / G0[[2]],
            B0[["L"]], B0[["s"]], s_sh, B0[["w"]], VB$p[["gamma_diff"]]))
if (abs(B0[["s"]] - s_sh) > 1e-9 * max(1, abs(s_sh)))
  warning("the base's land pair is NOT at the ruled NH : SH ratio (s_NH ", B0[["s"]], " vs s_SH ", s_sh, "): the module sets both")
cat(sprintf("growth product %s (sha256 %s...); window %d-%d, trend df %d, n_eff %.4f\n", LIK_IAV_GROWTH_RDS,
            substr(GRO$provenance$sha256, 1, 12), LIK_IAV_WIN[1], LIK_IAV_WIN[2], LIK_IAV_TREND_DF, LIK_IAV_NEFF))

# ---- runs at a module setting, every other name at the base -------------------------
vec_at <- function(L, s, w) {             # = lib_block_reopt.R br_vec(), for the module's three
  v <- VB
  blk <- c(stats::setNames(s * G0, IAV_GAMMA), stats::setNames(w, IAV_OCEAN))
  for (n in names(blk)) { if (n %in% names(v$p)) v$p[[n]] <- blk[[n]]; v$pm[[n]] <- blk[[n]] }
  v$p[[IAV_LAG]] <- L; v$pm[[IAV_LAG]] <- L
  v$p <- ccx_set_enso(v$p, v$pm)
  v$luc_scale <- v$pm$luc_scale
  v
}
run_at <- function(L, s, w) { v <- vec_at(L, s, w); r <- dg_run(v); r$v <- v; r }

cat("\n=== 0. GATES ===\n")
R_BASE <- run_at(B0[["L"]], B0[["s"]], B0[["w"]])
st0 <- unlist(dg_streams(R_BASE, R_BASE$v, obs = OBS)); ms0 <- unlist(md$streams)
dmax <- max(abs(st0[names(ms0)] - ms0))
cat(sprintf("  the base's %d stored rows through the dg path: max |diff| %.1e (tol %g)%s\n", length(ms0), dmax, IAV_REPRO_TOL,
            if (!identical(sort(names(st0)), sort(names(ms0)))) " ⚠ the row SETS differ" else ""))
if (dmax > IAV_REPRO_TOL || !identical(sort(names(st0)), sort(names(ms0)))) stop("the base does not reproduce its stored rows")
GP_BASE <- ccx_iav_growth_pair(R_BASE$out, R_BASE$F, GRO$monthly)
SSR_REF <- sum((GP_BASE$mod - GP_BASE$obs)^2)       # the module's reference: the base's own SSR (a constant)
mod_ll <- function(r) ccx_iav_module_loglik(r$out, r$F, OBS, ssr_ref = SSR_REF, obs_g = GRO$monthly)
LL_BASE <- mod_ll(R_BASE)
cat(sprintf("  the module at the base: SSR %.4f (the reference), slope row %+.4f, growth r %.4f\n",
            LL_BASE[["ssr"]], LL_BASE[["slope_row"]], LL_BASE[["r"]]))
if ("gcb_ocean_enso_slope" %in% names(st0) && !identical(LL_BASE[["slope_row"]], st0[["gcb_ocean_enso_slope"]]))
  stop("the module's slope row is not the main objective's row")
f_mod <- function(x) {                    # x = (L, log s, w); -loglik, 1e10 off the support
  if (!is.finite(sum(x)) || x[1] <= 0 || x[1] >= IAV_LAG_MAX || x[3] <= 0 || x[3] >= IAV_W_MAX) return(1e10)
  v <- tryCatch(mod_ll(run_at(x[1], exp(x[2]), x[3]))[["loglik"]], error = function(e) NA_real_)
  if (is.finite(v)) -v else 1e10 }

cat("\n=== 1. BASIN: superposition over the lag (s in closed form, w at the base) ===\n")
gp_of <- function(r) ccx_iav_growth_pair(r$out, r$F, GRO$monthly)
R0 <- run_at(B0[["L"]], 0, B0[["w"]]); P0 <- gp_of(R0)
sup <- parallel::mclapply(IAV_LAGS_SUP, function(L) { while (sink.number() > 0L) sink()
  gp_of(run_at(L, 1, B0[["w"]]))$mod - P0$mod }, mc.cores = IAV_WORKERS)
if (any(vapply(sup, inherits, logical(1), "try-error"))) stop("a superposition run failed")
SUP <- do.call(rbind, lapply(seq_along(IAV_LAGS_SUP), function(i) { E <- sup[[i]]; y <- P0$obs - P0$mod
  s <- max(0, sum(E * y) / sum(E^2)); data.frame(L = IAV_LAGS_SUP[i], s = s, ssr = sum((y - s * E)^2)) }))
j <- which.min(SUP$ssr)
# the check: at the scan's best (L, s) the superposed growth equals a direct run. (Not at the base: there
# s = 1 for hilda33p, and parts-vs-direct is an identity with no power.)
sup_dir <- gp_of(run_at(SUP$L[j], SUP$s[j], B0[["w"]]))$mod
sup_err <- sqrt(mean((P0$mod + SUP$s[j] * sup[[j]] - sup_dir)^2)); sup_sig <- sqrt(mean(sup_dir^2))
cat(sprintf("  superposition vs a direct run at the scan's best (L %.2f, s %.3f): rms %.2e ppm/yr against a signal of %.3f\n",
            SUP$L[j], SUP$s[j], sup_err, sup_sig))
if (sup_err > 1e-2 * sup_sig) stop("superposition does not hold at the scan's best")
cat(sprintf("  the scan's best: L %.2f, s %.3f (growth-only, w at the base) -- the START of step 2\n", SUP$L[j], SUP$s[j]))

cat("\n=== 2. OPTIMUM: Nelder-Mead on real runs of the full module objective ===\n")
x0 <- c(SUP$L[j], log(max(SUP$s[j], 1e-3)), B0[["w"]])
t2 <- Sys.time()
nm <- stats::optim(x0, f_mod, method = "Nelder-Mead", control = list(maxit = IAV_NM_MAXIT, reltol = IAV_NM_RELTOL))
OPT <- c(L = nm$par[1], s = exp(nm$par[2]), w = nm$par[3])
R_OPT <- run_at(OPT[["L"]], OPT[["s"]], OPT[["w"]]); LL_OPT <- mod_ll(R_OPT)
cat(sprintf("  %d evaluations, convergence %d, %.1f min\n", nm$counts[["function"]], nm$convergence,
            as.numeric(difftime(Sys.time(), t2, units = "mins"))))
cat(sprintf("  L %.4f months, s %.5f (%s = %.5f / %.5f), %s %.4f\n", OPT[["L"]], OPT[["s"]], paste(IAV_GAMMA, collapse = " / "),
            OPT[["s"]] * G0[[1]], OPT[["s"]] * G0[[2]], IAV_OCEAN, OPT[["w"]]))
cat(sprintf("  module loglik %+.4f vs the base (growth %+.4f, slope row %+.4f -> %+.4f); SSR %.4f -> %.4f; growth r %.4f -> %.4f\n",
            LL_OPT[["loglik"]] - LL_BASE[["loglik"]], LL_OPT[["growth"]], LL_BASE[["slope_row"]], LL_OPT[["slope_row"]],
            LL_BASE[["ssr"]], LL_OPT[["ssr"]], LL_BASE[["r"]], LL_OPT[["r"]]))
if (nm$convergence != 0L && !IAV_SMOKE) stop("Nelder-Mead did not converge within ", IAV_NM_MAXIT, " evaluations")
# the timing read (br_timing's definition): the detrended growth's correlation with Nino 3.4 led by k months
timing <- function(r) { gp <- gp_of(r); F <- r$F
  m <- data.frame(k = F$year * 12L + F$month, nino = F$enso)
  xc <- sapply(IAV_XLAGS, function(Lg) { n <- m$nino[match(gp$k - Lg, m$k)]
    c(mod = stats::cor(gp$mod, n, use = "complete.obs"), obs = stats::cor(gp$obs, n, use = "complete.obs")) })
  c(peak_mod = IAV_XLAGS[which.max(xc["mod", ])], peak_obs = IAV_XLAGS[which.max(xc["obs", ])]) }
TM <- rbind(base = timing(R_BASE), optimum = timing(R_OPT))
cat(sprintf("  growth peak after Nino 3.4: base %+d, optimum %+d months (the record %+d)\n",
            TM["base", "peak_mod"], TM["optimum", "peak_mod"], TM["optimum", "peak_obs"]))
if (file.exists(IAV_PREVIEW)) {
  pv <- readRDS(IAV_PREVIEW)$scopes$land_ocean
  cat(sprintf("  the preview's answer (%s, land_ocean, at hilda33p): L %.4f, s %.5f, w %.4f -> this run's differences %+.4f, %+.5f, %+.4f\n",
              basename(IAV_PREVIEW), pv[["L"]], pv[["s"]], pv[["w"]], OPT[["L"]] - pv[["L"]], OPT[["s"]] - pv[["s"]], OPT[["w"]] - pv[["w"]]))
}

cat("\n=== 3. PROFILE of the lag on real runs (s and w re-optimised at each lag) ===\n")
PL <- sort(unique(c(IAV_PROF_LAGS, OPT[["L"]])))
prof <- parallel::mclapply(PL, function(L) { while (sink.number() > 0L) sink()
  if (abs(L - OPT[["L"]]) < 1e-12) return(c(L = L, s = OPT[["s"]], w = OPT[["w"]], ll = LL_OPT[["loglik"]], conv = 0, n = 0))
  g <- function(y) f_mod(c(L, y[1], y[2]))
  o <- stats::optim(c(log(OPT[["s"]]), OPT[["w"]]), g, method = "Nelder-Mead",
                    control = list(maxit = IAV_PROF_MAXIT, reltol = IAV_NM_RELTOL))
  c(L = L, s = exp(o$par[1]), w = o$par[2], ll = -o$value, conv = o$convergence, n = o$counts[["function"]]) },
  mc.cores = IAV_WORKERS)
if (any(vapply(prof, inherits, logical(1), "try-error"))) stop("a profile cell failed")
PROF <- as.data.frame(do.call(rbind, prof)); PROF$dll <- PROF$ll - LL_OPT[["loglik"]]
print(round(PROF, 4), row.names = FALSE)
if (max(PROF$dll) > 1e-3) warning("a profile cell beats the optimum by ", signif(max(PROF$dll), 3), ": the optimum is not the best")
fine <- seq(min(PROF$L), max(PROF$L), by = 0.01); spf <- stats::splinefun(PROF$L, PROF$dll, method = "natural")(fine)
rng <- function(dl) { k <- fine[spf >= -dl]; c(min(k), max(k)) }
RNG1 <- rng(IAV_SIG[["one"]]); RNG2 <- rng(IAV_SIG[["two"]])
on_grid <- B0[["L"]] >= min(fine) && B0[["L"]] <= max(fine)
cat(sprintf("  the lag: 1-sigma %.2f-%.2f, 2-sigma %.2f-%.2f months (drops %.1f / %.1f); the base's %.2f %s\n",
            RNG1[1], RNG1[2], RNG2[1], RNG2[2], IAV_SIG[["one"]], IAV_SIG[["two"]], B0[["L"]],
            if (!on_grid) "is OFF the profile's grid" else
              sprintf("sits at %+.2f%s", spf[which.min(abs(fine - B0[["L"]]))],
                      if (B0[["L"]] < RNG2[1] || B0[["L"]] > RNG2[2]) " (OUTSIDE 2 sigma)" else "")))
if (RNG2[1] <= min(fine) || RNG2[2] >= max(fine))
  cat("  ⚠ the 2-sigma range reaches the end of the profile's grid: it is a bound, not a range\n")

cat("\n=== 4. LAPLACE: the module's Hessian in (L, s, w), central differences on real runs ===\n")
th0 <- c(L = OPT[["L"]], s = OPT[["s"]], w = OPT[["w"]]); h <- IAV_H_STEP
if (floor(th0[["L"]] - h[["L"]]) != floor(th0[["L"]] + h[["L"]]))
  warning("the lag's steps straddle a whole month (the stencil's kink): the L curvature mixes two segments")
ll_th <- function(th) { if (th[["L"]] <= 0 || th[["L"]] >= IAV_LAG_MAX || th[["w"]] <= 0 || th[["w"]] >= IAV_W_MAX || th[["s"]] <= 0) return(NA_real_)
  mod_ll(run_at(th[["L"]], th[["s"]], th[["w"]]))[["loglik"]] }
pts <- list(c0 = th0)
for (a in names(th0)) { e <- th0; e[[a]] <- e[[a]] + h[[a]]; pts[[paste0(a, "+")]] <- e
                        e <- th0; e[[a]] <- e[[a]] - h[[a]]; pts[[paste0(a, "-")]] <- e }
for (pr in utils::combn(names(th0), 2, simplify = FALSE)) for (sg in list(c(1, 1), c(1, -1), c(-1, 1), c(-1, -1))) {
  e <- th0; e[[pr[1]]] <- e[[pr[1]]] + sg[1] * h[[pr[1]]]; e[[pr[2]]] <- e[[pr[2]]] + sg[2] * h[[pr[2]]]
  pts[[sprintf("%s%s%s%s", pr[1], if (sg[1] > 0) "+" else "-", pr[2], if (sg[2] > 0) "+" else "-")]] <- e }
LLP <- unlist(parallel::mclapply(pts, function(th) { while (sink.number() > 0L) sink(); ll_th(th) }, mc.cores = IAV_WORKERS))
names(LLP) <- names(pts)
if (anyNA(LLP)) stop("a Hessian point left the support")
H <- matrix(0, 3, 3, dimnames = list(names(th0), names(th0)))
for (a in names(th0)) H[a, a] <- (LLP[[paste0(a, "+")]] - 2 * LLP[["c0"]] + LLP[[paste0(a, "-")]]) / h[[a]]^2
for (pr in utils::combn(names(th0), 2, simplify = FALSE)) {
  a <- pr[1]; b <- pr[2]; k <- function(x, y) LLP[[sprintf("%s%s%s%s", a, x, b, y)]]
  H[a, b] <- H[b, a] <- (k("+", "+") - k("+", "-") - k("-", "+") + k("-", "-")) / (4 * h[[a]] * h[[b]]) }
ev <- eigen(H, symmetric = TRUE, only.values = TRUE)$values
cat(sprintf("  Hessian eigenvalues %s (all must be < 0)\n", paste(signif(ev, 4), collapse = ", ")))
if (any(ev >= 0) && !IAV_SMOKE) stop("the module's Hessian is not negative definite at the optimum")
COV <- if (all(ev < 0)) solve(-H) else matrix(NA_real_, 3, 3, dimnames = dimnames(H))
SD <- sqrt(diag(COV)); CORR <- COV / outer(SD, SD)
cat(sprintf("  Laplace 1-sigma: L %.3f months, s %.4f, w %.3f; correlations L-s %+.2f, L-w %+.2f, s-w %+.2f\n",
            SD[["L"]], SD[["s"]], SD[["w"]], CORR["L", "s"], CORR["L", "w"], CORR["s", "w"]))
# the same covariance on the FOUR names stage 2 pins (the two gammas are s x G0): J d(theta)
J <- rbind(lag_enso_land = c(1, 0, 0), gamma_enso_land_NH = c(0, G0[[1]], 0), gamma_enso_land_SH = c(0, G0[[2]], 0),
           w_enso_l2 = c(0, 0, 1)); colnames(J) <- names(th0)
COV4 <- J %*% COV %*% t(J)

PINS <- c(lag_enso_land = OPT[["L"]], gamma_enso_land_NH = OPT[["s"]] * G0[[1]], gamma_enso_land_SH = OPT[["s"]] * G0[[2]],
          w_enso_l2 = OPT[["w"]])
stopifnot(identical(names(PINS), CCX_IAV_MODULE_NAMES))
cat("\n=== THE STAGE-1 RESULT: the module's four names, to be PINNED in stage 2 ===\n")
cat(sprintf("  %s = %.17g\n", names(PINS), PINS), sep = "")
CHK <- NULL
if (nzchar(IAV_CHECK)) {
  cat("\n=== + CHECK against an earlier stage 1 (RULED: stop below", IAV_CHECK_TOL, "of each name's own 1 sigma) ===\n")
  ref <- readRDS(IAV_CHECK)
  d <- c(L = OPT[["L"]] - ref$optimum[["L"]], s = OPT[["s"]] - ref$optimum[["s"]], w = OPT[["w"]] - ref$optimum[["w"]])
  z <- d / ref$laplace$sd[names(d)]
  CHK <- list(ref = IAV_CHECK, ref_commit = ref$provenance$commit, delta = d, z = z, tol = IAV_CHECK_TOL,
              pass = all(abs(z) < IAV_CHECK_TOL))
  cat(sprintf("  %s moved %+.4f = %+.3f sigma\n", names(d), d, z), sep = "")
  cat(sprintf("  VERDICT: %s\n", if (CHK$pass) "STOP -- every name moved less than the ruled tolerance"
              else "a name moved MORE than the ruled tolerance: this goes to Marcus before any second refit"))
}

out <- list(
  pins = PINS, optimum = OPT, base_values = B0, ratio = G0,
  loglik = rbind(base = LL_BASE, optimum = LL_OPT), ssr_ref = SSR_REF, timing = TM,
  nm = list(start = x0, par = nm$par, value = nm$value, counts = nm$counts, convergence = nm$convergence),
  scan = SUP, profile = PROF, lag_1sigma = RNG1, lag_2sigma = RNG2,
  laplace = list(theta = th0, step = h, points = LLP, hessian = H, cov = COV, sd = SD, corr = CORR, J = J, cov4 = COV4),
  check = CHK,
  provenance = list(
    driver = IAV_DRIVER, commit = COMMIT, date = as.character(Sys.Date()), smoke = IAV_SMOKE,
    base = BASE_NAME, base_file = BASE_FILE, base_md5 = unname(tools::md5sum(BASE_FILE)), base_struct = ccx_mode_struct(md),
    ratio_mode = IAV_RATIO_MODE, ratio_md5 = IAV_RATIO_MD5,
    growth_product = LIK_IAV_GROWTH_RDS, growth_sha256 = GRO$provenance$sha256,
    window = LIK_IAV_WIN, trend_df = LIK_IAV_TREND_DF, n_eff = LIK_IAV_NEFF, span_end = LIK_IAV_SPAN_END,
    objective = "-(n_eff/2) log(SSR/ssr_ref) + gcb_ocean_enso_slope (no priors: flat / negligible, see header)",
    gamma_diff = VB$p[["gamma_diff"]], lags_scan = IAV_LAGS_SUP, nm_maxit = IAV_NM_MAXIT, nm_reltol = IAV_NM_RELTOL,
    prof_lags = PL, prof_maxit = IAV_PROF_MAXIT, sig_drops = IAV_SIG, h_step = IAV_H_STEP, check_tol = IAV_CHECK_TOL,
    workers = IAV_WORKERS, rng = "none",
    units = "L months; s x hilda33p's land pair; gamma GtC/yr per index unit; w_enso_l2 as the table"))
saveRDS(out, IAV_OUT)
cat(sprintf("\nsaved %s and %s | %.1f min\n", IAV_OUT, IAV_LOG, as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
sink(); close(LOGCON)
