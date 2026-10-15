#!/usr/bin/env Rscript
# =====================================================================
# diag_iav_cut_smoothed_land.R -- PRICE a low-pass gcb_land_sink row for the interannual cut (2026-10-06).
#
# WHY. Marcus 2026-10-06, on notes/proposal_2026-10-06_iav_cut.md's decisions: "Price a smoothed row first
# (Recommended)"; "Monthly (Recommended)"; on the scope, "Explain why ocean enso is not also a part of this. But I
# think that land enso only is a good path." The preview found that under the cut, gcb_land_sink pays ~-35 to -48 for
# disagreeing with the growth record's ENSO response, and GCB's own budget contradicts the DGVMs' year-to-year ENSO
# signal that the row scores (C4). Under the split's own logic the main names care about the TREND, so the row's
# interannual part is the candidate to drop.
#
# THE LOW-PASS ROW, defined so it needs NO new sigma. The row is independent Gaussians at sd s (0.5 GtC/yr) on the
# per-year residual e (GCB target - model). With P the orthogonal projection onto [1, ns(year, df)] over the GCB years,
#   |e|^2 = |Pe|^2 + |(I-P)e|^2   exactly, so   row = [low part] + [high part],  high = -|(I-P)e|^2 / (2 s^2).
# The low-pass row is the row MINUS its high part: what the row says about the trend, under the row's OWN assumptions.
# df 6 over 66 years is the ~11-yr scale the imbalance smoothing already uses (LIK_IMB_SMOOTH_YR); df 4 and 9 bracket it.
# It is priced by br_cell's `extra` (a term ADDED to the objective): extra = +|(I-P)e|^2 / (2 s^2), with e from a re-run
# scored by dg_streams' own residuals (never a second copy of the row).
#
# THE SCOPES (gamma_diff held at the canonical's 0.25 in both, as Marcus leans; monthly estimator, as ruled):
#   land        stage 1 fits the land lag and a common land scale to the detrended monthly growth ALONE (= A0);
#   land_ocean  + the ocean limb w_enso_l2, with gcb_ocean_enso_slope moved INTO the module (and out of the main one).
# For each scope and each land-row treatment (raw, low-pass): B1 unrefitted and B2 (the five other land names
# re-optimized), the futures at B2. Then the JOINT objective's lag profile with the low-pass row (the 7-name land block
# re-optimized at each lag): does smoothing the land row ALONE move the joint lag?
# ⛔ ADOPTS NOTHING; changes no objective. No RNG.
# Usage: Rscript calibration/diag_iav_cut_smoothed_land.R [preview rds]   (CCX_SM_WORKERS, default 4; CCX_SM_SMOKE=1)
# =====================================================================
t_start <- Sys.time()
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
SM_DRIVER  <- "calibration/diag_iav_cut_smoothed_land.R"
args <- commandArgs(trailingOnly = TRUE)
SM_IN <- if (length(args)) args[1] else file.path("outputs", "diagnostics", "iav_cut_preview_20261006_hilda33p.rds")
SM_SMOKE   <- identical(Sys.getenv("CCX_SM_SMOKE", ""), "1")
SM_WORKERS <- as.integer(Sys.getenv("CCX_SM_WORKERS", "4"))
SM_GAMMA   <- c("gamma_enso_land_NH", "gamma_enso_land_SH"); SM_OCEAN <- "w_enso_l2"
SM_LAND_ROW  <- "gcb_land_sink"; SM_SLOPE_ROW <- "gcb_ocean_enso_slope"
SM_LP_DF   <- 6L                     # the low-pass scale: ~11 yr over the 66 GCB years
SM_LP_SENS <- c(4L, 9L)              # its bracket, read at the B2 vectors only
SM_LAGS    <- c(1, 2, 3, 4, 5, 6, 8) # + the mode: the joint profile with the low-pass row
SM_NM_MAXIT <- 150L
TR_BLOCK   <- c("beta_max", "fert_k", SM_GAMMA, "luc_scale", "imb_share_land", "ndep_ret")
BR_OBS_WEEKLY <- file.path("data-raw", "downloads", "mbl_zonal_co2_GL.txt")
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L
if (SM_SMOKE) { BR_BFGS_MAXIT <- 2L; BR_NM_MAXIT <- 8L; BR_ROUNDS <- 1L; SM_NM_MAXIT <- 6L; SM_LAGS <- c(2, 5) }
SM_OUT <- sub("iav_cut_preview_", "iav_cut_smoothed_land_", sub("[.]rds$", if (SM_SMOKE) "_SMOKE" else "", SM_IN))
COMMIT <- ccx_git_stamp()
source(file.path("calibration", "lib_block_reopt.R"))
PV <- readRDS(SM_IN); P <- PV$provenance; BR_WIN <- P$window; BR_TREND_DF <- P$trend_df
SM_REST <- P$rest
LOGCON <- file(paste0(SM_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | from %s (%s @%s) | %d workers%s\n", SM_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), SM_IN,
            P$driver, P$commit, SM_WORKERS, if (SM_SMOKE) " | ⚠ SMOKE: tiny budgets, NOT A RESULT" else ""))

BR_OBS <- ccx_prepare_obs()
MODE_FILE <- ccx_mode_file(P$mode); md <- readRDS(MODE_FILE)
stopifnot(identical(unname(tools::md5sum(MODE_FILE)), P$mode_md5))
BR_MD <- list(BASE = md); BR_LABEL_LAG <- ccx_mode_struct(md); BR_LABEL_ZERO <- NA_character_
BR_PINS <- stats::setNames(as.numeric(md$pins), names(md$pins))
BR_SPF <- list(BASE = ccx_spinup_from_label(ccx_mode_spinup(md))); BR_VB <- list(BASE = dg_vector(MODE_FILE))
L0 <- md$par_mode[["lag_enso_land"]]; G0 <- vapply(SM_GAMMA, function(n) md$par_mode[[n]], 0); W0 <- md$par_mode[[SM_OCEAN]]
SD_LAND <- LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE
GCB_YRS <- sort(BR_OBS$gcb$year)
OBS_G <- br_obs_growth()

# ---- the low-pass decomposition of the land row ----------------------------------------------------------------
proj <- function(df) { X <- stats::model.matrix(~ splines::ns(GCB_YRS, df = df)); X %*% solve(crossprod(X), t(X)) }
PLP <- proj(SM_LP_DF)
land_res <- function(r, v) { e <- unlist(attr(dg_streams(r, v, obs = BR_OBS, residuals = TRUE), "residuals")[[SM_LAND_ROW]])
  stopifnot(length(e) == length(GCB_YRS)); e }
high_part <- function(e, Pm = PLP) { h <- as.numeric(e - Pm %*% e); -sum(h^2) / (2 * SD_LAND^2) }
vec_of <- function(block, L) br_vec("BASE", block, L)
#' br_cell's `extra` for the low-pass row: the run at `par`, then +|(I-P)e|^2/(2 s^2) (i.e. MINUS the high part)
lp_extra <- function(blk_names) function(par) { v <- vec_of(unlist(par[blk_names]), par[["lag_enso_land"]])
  -high_part(land_res(dg_run(v), v)) }

cat("\n=== 0. GATES ===\n")
id0 <- br_cell("BASE", L0, SM_REST, max_rounds = 0L)
if (abs(id0$logpost - md$logpost) > 1e-6) stop("the base does not reproduce its stored logpost")
RC <- dg_run(BR_VB$BASE); SC <- unlist(dg_streams(RC, BR_VB$BASE, obs = BR_OBS)); e0 <- land_res(RC, BR_VB$BASE)
raw0 <- sum(stats::dnorm(e0, 0, SD_LAND, log = TRUE)); lo0 <- raw0 - high_part(e0)
cat(sprintf("  the row from its own residuals: %.6f vs the objective's %.6f (diff %.1e); high part %.3f, low-pass row %.3f\n",
            raw0, id0$streams[[SM_LAND_ROW]], raw0 - id0$streams[[SM_LAND_ROW]], high_part(e0), lo0))
if (abs(raw0 - id0$streams[[SM_LAND_ROW]]) > 1e-8) stop("the residual-based row does not reproduce the objective's")
ex0 <- br_cell("BASE", L0, SM_REST, max_rounds = 0L, extra = lp_extra(SM_REST))
cat(sprintf("  extra at the canonical: %.6f = -high part %.6f (diff %.1e)\n", ex0$extra, -high_part(e0), ex0$extra + high_part(e0)))
if (abs(ex0$extra + high_part(e0)) > 1e-8) stop("the extra term does not reproduce the decomposition")
# the decomposition is exact: a random residual splits into its two parts to rounding
ez <- seq_along(GCB_YRS) %% 7 - 3
if (abs(sum(ez^2) - sum((PLP %*% ez)^2) - sum((ez - PLP %*% ez)^2)) > 1e-9) stop("the projection is not orthogonal")

cat("\n=== 1. STAGE 1 (the module), monthly estimator, gamma_diff held at the canonical ===\n")
X <- NULL
gm <- function(r) { m <- data.frame(k = r$F$year * 12L + r$F$month, g = br_cen12((r$out$co2_NH + r$out$co2_SH) / 2))
  M <- merge(m, OBS_G, by = "k", suffixes = c("_mod", "_obs"))
  M <- M[M$k >= BR_WIN[1] * 12L + 1L & M$k <= BR_WIN[2] * 12L + 12L & stats::complete.cases(M), ]
  if (is.null(X)) X <<- stats::model.matrix(~ splines::ns((M$k - 1) / 12, df = BR_TREND_DF))
  Q <- function(g) as.numeric(g - X %*% qr.solve(X, g)); list(mod = Q(M$g_mod), obs = Q(M$g_obs)) }
run_s <- function(L, s, w = W0) { v <- vec_of(c(stats::setNames(s * G0, SM_GAMMA), stats::setNames(w, SM_OCEAN)), L)
  r <- dg_run(v); r$v <- v; r }
g_can <- gm(RC); SSR_CAN <- sum((g_can$mod - g_can$obs)^2); NE <- PV$n_eff[["m"]]
o0 <- PV$opt[PV$opt$arm == "A0" & PV$opt$est == "m", ]
nm1 <- stats::optim(c(o0$L_star, log(o0$s)), function(x) { if (x[1] < 0 || x[1] > 12) return(1e10)
  g <- gm(run_s(x[1], exp(x[2]))); sum((g$mod - g$obs)^2) }, method = "Nelder-Mead", control = list(maxit = SM_NM_MAXIT, reltol = 1e-8))
S_LAND <- c(L = nm1$par[1], s = exp(nm1$par[2]), w = W0)
nm2 <- stats::optim(c(S_LAND[["L"]], log(S_LAND[["s"]]), W0), function(x) { if (x[1] < 0 || x[1] > 12 || x[3] < 0) return(1e10)
  r <- run_s(x[1], exp(x[2]), x[3]); g <- gm(r)
  -(-(NE / 2) * log(sum((g$mod - g$obs)^2) / SSR_CAN) + unlist(dg_streams(r, r$v, obs = BR_OBS))[[SM_SLOPE_ROW]]) },
  method = "Nelder-Mead", control = list(maxit = 2L * SM_NM_MAXIT, reltol = 1e-8))
S_LO <- c(L = nm2$par[1], s = exp(nm2$par[2]), w = nm2$par[3])
SCOPES <- list(land = S_LAND, land_ocean = S_LO)
for (sc in names(SCOPES)) { x <- SCOPES[[sc]]; r <- run_s(x[["L"]], x[["s"]], x[["w"]]); g <- gm(r)
  cat(sprintf("  %-10s lag %.3f months, land x%.3f (%.3f / %.3f), %s %.2f | growth r %.3f (canonical %.3f), ssr ratio %.3f | %s %+.3f (canonical %+.3f)\n",
              sc, x[["L"]], x[["s"]], x[["s"]] * G0[[1]], x[["s"]] * G0[[2]], SM_OCEAN, x[["w"]], stats::cor(g$mod, g$obs),
              stats::cor(g_can$mod, g_can$obs), sum((g$mod - g$obs)^2) / SSR_CAN, SM_SLOPE_ROW,
              unlist(dg_streams(r, r$v, obs = BR_OBS))[[SM_SLOPE_ROW]], SC[[SM_SLOPE_ROW]])) }

cat("\n=== 2. THE MAIN OBJECTIVE under each scope, with the raw and the low-pass land row (B1 unrefitted, B2 = 5 land names) ===\n")
TASKS <- list()
for (sc in names(SCOPES)) for (row in c("raw", "lowpass")) for (k in c(0L, BR_ROUNDS)) {
  x <- SCOPES[[sc]]
  hold <- as.list(c(stats::setNames(x[["s"]] * G0, SM_GAMMA), if (sc == "land_ocean") stats::setNames(x[["w"]], SM_OCEAN)))
  TASKS[[length(TASKS) + 1L]] <- list(id = sprintf("%s_%s_%s", sc, row, if (k == 0L) "B1" else "B2"), L = x[["L"]], free = SM_REST,
    hold = hold, rounds = k, drop = if (sc == "land_ocean") SM_SLOPE_ROW else NULL,
    extra = if (row == "lowpass") lp_extra(c(SM_REST, names(hold))) else NULL) }
for (L in sort(c(SM_LAGS, L0))) TASKS[[length(TASKS) + 1L]] <- list(id = sprintf("prof_%g", L), L = L, free = TR_BLOCK, hold = NULL,
  rounds = if (abs(L - L0) < 1e-12) BR_ROUNDS else BR_ROUNDS, drop = NULL, extra = lp_extra(TR_BLOCK))
flush(LOGCON)
RES <- parallel::mclapply(TASKS, function(tk) { while (sink.number() > 0L) sink()
  o <- try(br_cell("BASE", tk$L, tk$free, hold = tk$hold, max_rounds = tk$rounds, drop = tk$drop, extra = tk$extra))
  if (!inherits(o, "try-error")) o$id <- tk$id
  o }, mc.cores = SM_WORKERS, mc.preschedule = FALSE)
bad <- vapply(RES, function(o) inherits(o, "try-error") || is.null(o$L), logical(1))
if (any(bad)) stop("a cell failed: ", paste(vapply(RES[bad], function(o) as.character(o)[1], ""), collapse = " | "))
names(RES) <- vapply(RES, `[[`, "", "id")
saveRDS(list(res = RES, scopes = SCOPES, commit = COMMIT), paste0(SM_OUT, "_cells.rds"))

# every B cell scored on BOTH treatments at its own vector (so a raw-optimized point is also read on the low-pass row)
cell_vec <- function(o) { blk <- o$block[intersect(names(o$block), c(SM_REST, SM_GAMMA, SM_OCEAN))]; vec_of(blk, o$L) }
read_cell <- function(o, sc) { v <- cell_vec(o); r <- dg_run(v); st <- unlist(dg_streams(r, v, obs = BR_OBS)); e <- land_res(r, v)
  main <- setdiff(names(id0$streams), if (sc == "land_ocean") SM_SLOPE_ROW)
  hp <- high_part(e); hp0 <- high_part(e0)
  c(d_main_raw = sum(st[main]) - sum(id0$streams[main]),
    d_main_lowpass = sum(st[main]) - sum(id0$streams[main]) - (hp - hp0),
    d_land_raw = st[[SM_LAND_ROW]] - id0$streams[[SM_LAND_ROW]], d_land_low = (st[[SM_LAND_ROW]] - hp) - (id0$streams[[SM_LAND_ROW]] - hp0),
    d_land_high = hp - hp0, d_seasonal = sum(st[grepl("seasonal", names(st))]) - sum(id0$streams[grepl("seasonal", names(id0$streams))]),
    beta_max = o$block[["beta_max"]], fert_k = o$block[["fert_k"]],
    d_low_df4 = (st[[SM_LAND_ROW]] - high_part(e, proj(SM_LP_SENS[1]))) - (id0$streams[[SM_LAND_ROW]] - high_part(e0, proj(SM_LP_SENS[1]))),
    d_low_df9 = (st[[SM_LAND_ROW]] - high_part(e, proj(SM_LP_SENS[2]))) - (id0$streams[[SM_LAND_ROW]] - high_part(e0, proj(SM_LP_SENS[2]))),
    conv = as.numeric(isTRUE(o$converged))) }
BT <- do.call(rbind, lapply(grep("^land", names(RES), value = TRUE), function(id) { sc <- sub("_(raw|lowpass)_B[12]$", "", id)
  data.frame(cell = id, t(read_cell(RES[[id]], sc))) }))
fut0 <- br_futures(BR_VB$BASE, dg_spinup(BR_VB$BASE))
FUT <- t(vapply(grep("_B2$", names(RES), value = TRUE), function(id) { v <- cell_vec(RES[[id]]); br_futures(v, dg_spinup(v)) - fut0 },
                numeric(length(BR_FUT_SPLICE))))
colnames(FUT) <- sprintf("d_%s_%d", names(BR_FUT_SPLICE), BR_FUT_YEAR)
cat(sprintf("  every likelihood is against the canonical; 'main' = the main objective's rows (land_ocean: without %s, which moved to the module);\n", SM_SLOPE_ROW))
cat(sprintf("  _raw / _lowpass = the land row as scored now / its low-pass part (df %d); d_low_df4/9 bracket the scale\n", SM_LP_DF))
print(BT, digits = 4, row.names = FALSE)
cat("  CO2 change in 2300 at each B2 (ppm):\n"); print(round(FUT, 2))

cat(sprintf("\n=== 3. THE JOINT OBJECTIVE with the low-pass land row: the %d-name land block re-optimised per lag ===\n", length(TR_BLOCK)))
PR <- do.call(rbind, lapply(grep("^prof_", names(RES), value = TRUE), function(id) { o <- RES[[id]]
  data.frame(L = o$L, obj = o$logpost + o$extra, lik_lowpass = o$lik + o$extra, conv = isTRUE(o$converged), rounds = o$rounds,
             gamma_NH = o$block[[SM_GAMMA[1]]], gamma_SH = o$block[[SM_GAMMA[2]]], minutes = round(o$minutes, 1)) }))
PR <- PR[order(PR$L), ]; PR$d_lik <- PR$lik_lowpass - PR$lik_lowpass[which.min(abs(PR$L - L0))]
fine <- seq(min(PR$L), max(PR$L), by = 0.01); L_lp <- fine[which.max(stats::splinefun(PR$L, PR$lik_lowpass, method = "natural")(fine))]
print(PR, digits = 5, row.names = FALSE)
cat(sprintf("  with the low-pass land row the JOINT objective's lag peaks at %.2f months (raw row: 2.48 on 10-06's spline; growth alone: %.2f)\n",
            L_lp, S_LAND[["L"]]))
sink()
saveRDS(list(scopes = SCOPES, b_table = BT, futures = FUT, futures_canonical = fut0, profile = PR, L_lowpass_joint = L_lp,
             gate = c(raw_row = raw0, objective_row = id0$streams[[SM_LAND_ROW]], high_part = high_part(e0)),
             provenance = list(driver = SM_DRIVER, commit = COMMIT, input = SM_IN, input_commit = P$commit, mode = P$mode,
                               mode_md5 = P$mode_md5, lp_df = SM_LP_DF, lp_sens = SM_LP_SENS, sd_land = SD_LAND, lags = SM_LAGS,
                               rest = SM_REST, gamma_diff = "held at the canonical", estimator = "monthly", rng = "none",
                               smoke = SM_SMOKE, date = format(Sys.time(), "%Y-%m-%d %H:%M"))), paste0(SM_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds} | %.1f min\n", SM_OUT, as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
