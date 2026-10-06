#!/usr/bin/env Rscript
# =====================================================================
# diag_iav_cut_scope.R -- the interannual-cut preview's B2, SPLIT into its ENSO and its volcanic part (2026-10-06).
#
# WHY. diag_iav_cut_preview.R's B2 (A1's interannual names held, the five other land names re-optimised) recovers
# only 8 of B1's 80 log-units, and it moves beta_max and fert_k up ~14 %, which moves SSP5-8.5 CO2 in 2300 by
# about -30 ppm. That is the leakage a cut is meant to prevent, so it needs an owner before any scope is
# recommended: the ENSO names (lag + amplitude) or gamma_diff (whose AOD forcing has a non-zero mean)?
# THE ARMS, both from A1 (read from the preview's rds), each B1 (unrefitted) and B2 (the 5 land names re-optimised):
#   ENSO  A1's lag and amplitude, gamma_diff at the canonical's 0.25;
#   VOLC  the canonical's lag and amplitude, gamma_diff at A1's value.
# ⛔ ADOPTS NOTHING. No RNG.
# Usage: Rscript calibration/diag_iav_cut_scope.R [path/to/iav_cut_preview_<tag>.rds]   (CCX_SCOPE_WORKERS, default 4)
# =====================================================================
t_start <- Sys.time()
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
SC_DRIVER  <- "calibration/diag_iav_cut_scope.R"
args <- commandArgs(trailingOnly = TRUE)
SC_IN <- if (length(args)) args[1] else {
  c0 <- list.files(file.path("outputs", "diagnostics"), pattern = "^iav_cut_preview_[0-9]{8}_[a-z0-9]+[.]rds$", full.names = TRUE)
  if (!length(c0)) stop("no iav_cut_preview rds; pass a path"); sort(c0, decreasing = TRUE)[1] }
SC_WORKERS <- as.integer(Sys.getenv("CCX_SCOPE_WORKERS", "4"))
SC_GAMMA <- c("gamma_enso_land_NH", "gamma_enso_land_SH"); SC_VOLC <- "gamma_diff"
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L
SC_OUT <- sub("iav_cut_preview_", "iav_cut_scope_", sub("[.]rds$", "", SC_IN))
COMMIT <- ccx_git_stamp()
source(file.path("calibration", "lib_block_reopt.R"))
PV <- readRDS(SC_IN); P <- PV$provenance
SC_REST <- P$rest
LOGCON <- file(paste0(SC_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | from %s (%s @%s) | %d workers\n", SC_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), SC_IN,
            P$driver, P$commit, SC_WORKERS))

BR_OBS <- ccx_prepare_obs()
MODE_FILE <- ccx_mode_file(P$mode); md <- readRDS(MODE_FILE)
stopifnot(identical(unname(tools::md5sum(MODE_FILE)), P$mode_md5))
BR_MD <- list(BASE = md); BR_LABEL_LAG <- ccx_mode_struct(md); BR_LABEL_ZERO <- NA_character_
BR_PINS <- stats::setNames(as.numeric(md$pins), names(md$pins))
BR_SPF <- list(BASE = ccx_spinup_from_label(ccx_mode_spinup(md))); BR_VB <- list(BASE = dg_vector(MODE_FILE))
L0 <- md$par_mode[["lag_enso_land"]]; G0 <- vapply(SC_GAMMA, function(n) md$par_mode[[n]], 0); D0 <- BR_VB$BASE$p[[SC_VOLC]]
A1 <- PV$A1
ARMS <- list(ENSO = list(L = A1[["L"]], s = A1[["s"]], d = D0), VOLC = list(L = L0, s = 1, d = A1[["d"]]))
cat(sprintf("arms: ENSO = lag %.3f, amplitude x%.3f, %s %.2f | VOLC = lag %.3f, amplitude x1, %s %.3f\n",
            ARMS$ENSO$L, ARMS$ENSO$s, SC_VOLC, ARMS$ENSO$d, ARMS$VOLC$L, SC_VOLC, ARMS$VOLC$d))
id0 <- br_cell("BASE", L0, SC_REST, max_rounds = 0L)
if (abs(id0$logpost - md$logpost) > 1e-6) stop("the base does not reproduce its stored logpost")
TASKS <- unlist(lapply(names(ARMS), function(a) lapply(c(0L, BR_ROUNDS), function(k) list(arm = a, rounds = k))), recursive = FALSE)
flush(LOGCON)
RES <- parallel::mclapply(TASKS, function(tk) { while (sink.number() > 0L) sink()
  a <- ARMS[[tk$arm]]
  o <- try(br_cell("BASE", a$L, SC_REST, hold = as.list(stats::setNames(a$s * G0, SC_GAMMA)), max_rounds = tk$rounds,
                   base_over = if (a$d != D0) stats::setNames(list(a$d), SC_VOLC) else NULL))
  if (!inherits(o, "try-error")) { o$arm <- tk$arm; o$tag <- sprintf("%s_%s", tk$arm, if (tk$rounds == 0L) "B1" else "B2") }
  o }, mc.cores = SC_WORKERS, mc.preschedule = FALSE)
bad <- vapply(RES, function(o) inherits(o, "try-error") || is.null(o$L), logical(1))
if (any(bad)) stop("a cell failed: ", paste(vapply(RES[bad], function(o) as.character(o)[1], ""), collapse = " | "))
names(RES) <- vapply(RES, `[[`, "", "tag")
vec_of <- function(o) { a <- ARMS[[o$arm]]
  v <- br_vec("BASE", c(stats::setNames(a$s * G0, SC_GAMMA), o$block[SC_REST]), a$L); v$p[[SC_VOLC]] <- a$d; v }
FUT <- t(vapply(RES, function(o) { v <- vec_of(o); br_futures(v, dg_spinup(v)) }, numeric(length(BR_FUT_SPLICE))))
colnames(FUT) <- sprintf("%s_%d", names(BR_FUT_SPLICE), BR_FUT_YEAR)
fut0 <- br_futures(BR_VB$BASE, dg_spinup(BR_VB$BASE))
TAB <- do.call(rbind, lapply(RES, function(o) data.frame(cell = o$tag, d_lik = o$lik - id0$lik,
  d_land_sink = o$streams[["gcb_land_sink"]] - id0$streams[["gcb_land_sink"]],
  d_seasonal = sum(o$streams[grepl("seasonal", names(o$streams))] - id0$streams[grepl("seasonal", names(id0$streams))]),
  beta_max = o$block[["beta_max"]], fert_k = o$block[["fert_k"]], converged = isTRUE(o$converged), rounds = o$rounds,
  minutes = round(o$minutes, 1))))
TAB <- cbind(TAB, sweep(FUT[TAB$cell, , drop = FALSE], 2, fut0))
colnames(TAB)[(ncol(TAB) - 1):ncol(TAB)] <- paste0("d_", colnames(FUT))
cat(sprintf("canonical: beta_max %.4f, fert_k %.2f; CO2 2300 %s = %s ppm\n", md$par_mode$beta_max, md$par_mode$fert_k,
            paste(colnames(FUT), collapse = " / "), paste(sprintf("%.2f", fut0), collapse = " / ")))
print(TAB, digits = 4, row.names = FALSE)
for (b in c("ENSO_B2", "VOLC_B2")) { d <- RES[[b]]$streams - id0$streams
  cat(sprintf("  %s, the rows that move most (vs the canonical):\n", b)); print(round(d[order(-abs(d))][1:8], 3)) }
sink()
saveRDS(list(table = TAB, futures = FUT, futures_canonical = fut0, arms = ARMS,
             cells = lapply(RES, `[`, c("tag", "L", "block", "logpost", "lik", "streams", "converged", "rounds")),
             provenance = list(driver = SC_DRIVER, commit = COMMIT, input = SC_IN, input_commit = P$commit, mode = P$mode,
                               mode_md5 = P$mode_md5, rest = SC_REST, rng = "none", date = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(SC_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds} | %.1f min\n", SC_OUT, as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
