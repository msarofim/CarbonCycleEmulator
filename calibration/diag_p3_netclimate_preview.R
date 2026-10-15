#!/usr/bin/env Rscript
# =====================================================================
# diag_p3_netclimate_preview.R -- PRICE P3 BEFORE IT IS BUILT (Marcus 2026-10-04: "Preview P3 with q10 freed
# (Recommended)"; notes/proposal_2026-10-04_npp_tsens_prior.md section 5).
#
# P3 is a GCB 2025 net-climate-effect ROW in the objective: the land sink's response to 1901-2024 climate change,
# on TRENDY's definition (S2 - S1: climate varying vs held at its 1901-20 mean), -0.8 +/- 0.7 GtC/yr over 2015-24
# (ESSD 18:3211 s. 3.7.2; lit note G3). It constrains the greening term AND q10 together, which is why q10 is freed
# here: the 10-04 (i) analytic P3 held q10 at the canonical's 1.06 (prior z -2.54).
#
# AT hilda34g's own lag, the 8-name land block + q10 are re-optimized on [the #15 logpost + the row], every other
# name held. The row is computed from each evaluation's own model vector by br_net_climate() (two more historical
# runs per evaluation). Cells:
#   ID   the 9-name block, NO row: a slope check at the mode (the frame's identity gate)
#   R1   the row, q10 FREE, from the mode: what P3 does
#   RH   the row with q10 HELD at the canonical's (the 8-name block): the analytic 10-04 (i) P3 (+0.0066), checked
#   Q    the row with q10 HELD at P3_Q10_PROFILE (the land block re-optimized): what matching GCB's net climate effect
#        would cost the record. (A literature START at q10 1.4 was smoked first: it sits ~100 whitened units out, at
#        -4347 on the #15 likelihood with the rest held -- a profile answers the same question for far less.)
# ⚠ Every cell computes the row from ALL NINE names (the q10 the objective is using), never from the 8-name block.
# ⛔ A PREVIEW: adopts nothing, changes no objective, writes no mode file. No RNG.
# Usage: Rscript calibration/diag_p3_netclimate_preview.R   (CCX_P3_WORKERS=<n>, default 3; CCX_P3_SMOKE=1)
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
P3_DRIVER     <- "calibration/diag_p3_netclimate_preview.R"
P3_SMOKE      <- identical(Sys.getenv("CCX_P3_SMOKE", ""), "1")
P3_WORKERS    <- as.integer(Sys.getenv("CCX_P3_WORKERS", "3"))
BR_LABEL_LAG  <- "hilda_csl3v0kaidgbe"
BR_LABEL_ZERO <- "hilda_csl3v0kaidgb"
P3_BASE       <- c(LAG = ccx_mode_file("hilda34g"))
P3_GREEN      <- "npp_tsens"; P3_Q10 <- "q10"
P3_BLOCK8     <- c(P3_GREEN, "beta_max", "fert_k", "gamma_enso_land_NH", "gamma_enso_land_SH", "luc_scale", "imb_share_land", "ndep_ret")
P3_BLOCK9     <- c(P3_BLOCK8, P3_Q10)
P3_ROW        <- c(mean = -0.8, sd = 0.7)            # GtC/yr, 2015-24, GCB 2025 ESSD 18:3211 s. 3.7.2 (lit note G3)
P3_NET_WIN    <- c(2015L, 2024L); P3_NET_CLIM <- c(1901L, 1920L)
P3_Q10_PROFILE <- c(1.25, 1.4)                      # 1.4 = Mahecha 2010's ecosystem Q10 1.4 +/- 0.1 (lit G14); 1.25 between it and Hector's 1.2
BR_WIN <- c(1980L, 2024L); BR_TREND_DF <- 5L; BR_XLAGS <- -6:18
BR_OBS_WEEKLY <- file.path("data-raw", "downloads", "mbl_zonal_co2_GL.txt")
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L
if (P3_SMOKE) { BR_BFGS_MAXIT <- 2L; BR_NM_MAXIT <- 10L; BR_ROUNDS <- 1L }
P3_TAG  <- paste0(format(Sys.Date(), "%Y%m%d"), if (P3_SMOKE) "_SMOKE" else "")
P3_OUT  <- file.path("outputs", "diagnostics", sprintf("obj16_p3_preview_%s", P3_TAG))
COMMIT  <- ccx_git_stamp()
stopifnot(isTRUE(LIK_USE_ICE_D13C), identical(LIK_ICE_CO2_END, 1958))      # objective #15
source(file.path("calibration", "lib_block_reopt.R"))
LOGCON <- file(paste0(P3_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | %d workers%s\n", P3_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), P3_WORKERS,
            if (P3_SMOKE) " | ⚠ SMOKE: tiny optimiser budget, NOT A RESULT" else ""))
cat(sprintf("  the row: net climate effect on S_LAND, %d-%d vs %d-%d climate held, N(%+.1f, %.1f) GtC/yr (GCB 2025 TRENDY)\n",
            P3_NET_WIN[1], P3_NET_WIN[2], P3_NET_CLIM[1], P3_NET_CLIM[2], P3_ROW[["mean"]], P3_ROW[["sd"]]))

BR_OBS <- ccx_prepare_obs()
BR_MD  <- lapply(P3_BASE, readRDS)
stopifnot(identical(ccx_mode_struct(BR_MD$LAG), BR_LABEL_LAG), P3_Q10 %in% BR_MD$LAG$param_names)
BR_PINS <- stats::setNames(as.numeric(BR_MD$LAG$pins), names(BR_MD$LAG$pins))
BR_SPF <- lapply(BR_MD, function(md) ccx_spinup_from_label(ccx_mode_spinup(md)))
BR_VB  <- lapply(P3_BASE, dg_vector)
L_LAG  <- BR_MD$LAG$par_mode[["lag_enso_land"]]

# the row, from a natural parameter list: the model vector the evaluation implies, its net climate effect
net_of <- function(par, blk) br_net_climate(br_vec("LAG", unlist(par[blk]), L_LAG), P3_NET_WIN, P3_NET_CLIM)[["net_climate"]]
row_of <- function(net) stats::dnorm(net, P3_ROW[["mean"]], P3_ROW[["sd"]], log = TRUE)
extra9 <- function(par) row_of(net_of(par, P3_BLOCK9))      # every cell: the q10 the objective is using
q10_z  <- function(q) ccx_prior_z(P3_Q10, q, p = BR_VB$LAG$p)

# ---- ID: the frame, and the canonical's own net climate effect ----------------------------------------
cat("\n=== ID. the 9-name block (land block + q10), NO row: a slope check AT the mode ===\n")
id0 <- br_cell("LAG", L_LAG, P3_BLOCK9, max_rounds = 0L)
net0 <- net_of(as.list(id0$block), P3_BLOCK9)
cat(sprintf("  logpost %.6f (stored %.6f); max |whitened slope| %.4f; q10 %.4f (prior z %+.2f); npp_tsens %+.5f; net climate effect %+.3f GtC/yr -> the row %.3f (z %+.2f)\n",
            id0$logpost, BR_MD$LAG$logpost, max(abs(id0$slope)), id0$block[[P3_Q10]], q10_z(id0$block[[P3_Q10]]), id0$block[[P3_GREEN]],
            net0, row_of(net0), (net0 - P3_ROW[["mean"]]) / P3_ROW[["sd"]]))
if (abs(id0$logpost - BR_MD$LAG$logpost) > 1e-6 || !id0$converged) stop("the frame's identity gate fails")

# ---- the cells, forked ----------------------------------------------------------------------------------
q10_0 <- id0$block[[P3_Q10]]
JOBS <- c(list(R1 = list(free = P3_BLOCK9, hold = NULL, label = "the row, q10 free, from the mode"),
               RH = list(free = P3_BLOCK8, hold = stats::setNames(q10_0, P3_Q10), label = "the row, q10 HELD at the canonical's")),
          stats::setNames(lapply(P3_Q10_PROFILE, function(q) list(free = P3_BLOCK8, hold = stats::setNames(q, P3_Q10),
                                                                  label = sprintf("the row, q10 HELD at %g", q))),
                          sprintf("Q%g", P3_Q10_PROFILE)))
cat(sprintf("\n=== cells: %d on %d forked workers ===\n", length(JOBS), P3_WORKERS))
flush(LOGCON)
RES <- parallel::mclapply(names(JOBS), function(k) { while (sink.number() > 0L) sink(); j <- JOBS[[k]]
  o <- br_cell("LAG", L_LAG, j$free, hold = j$hold, extra = extra9)
  stopifnot(setequal(names(o$block), P3_BLOCK9))
  v <- br_vec("LAG", o$block, L_LAG); r <- dg_run(v)
  o$net <- net_of(as.list(o$block), P3_BLOCK9)
  o$futures <- stats::setNames(br_futures(v, r$sp), sprintf("%s_%d", names(BR_FUT_SPLICE), BR_FUT_YEAR))
  o$cell <- k; o$label <- j$label; o }, mc.cores = P3_WORKERS, mc.preschedule = FALSE)
names(RES) <- names(JOBS)
bad <- vapply(RES, function(o) inherits(o, "try-error") || !is.list(o) || is.null(o$logpost), TRUE)
if (any(bad)) stop(sum(bad), " cell(s) FAILED")
saveRDS(list(jobs = lapply(JOBS, `[`, c("free", "hold", "label")), res = RES, commit = COMMIT), paste0(P3_OUT, "_cells.rds"))

# ---- the read --------------------------------------------------------------------------------------------
cat("\n=== THE READ (likelihood = the #15 rows; the row's own term shown apart; d = vs the canonical) ===\n")
v0 <- br_vec("LAG", id0$block, L_LAG); fut0 <- stats::setNames(br_futures(v0, dg_spinup(v0)), sprintf("%s_%d", names(BR_FUT_SPLICE), BR_FUT_YEAR))
rowtab <- function(nm, o, net, fut) data.frame(cell = nm, npp_tsens = o$block[[P3_GREEN]], q10 = o$block[[P3_Q10]],
  q10_z = q10_z(o$block[[P3_Q10]]), beta_max = o$block[["beta_max"]],
  net = net, row = row_of(net), d_lik = o$lik - id0$lik, d_logpost = o$logpost - id0$logpost,
  ssp585 = fut[[1]], vvH = fut[[2]], conv = isTRUE(o$converged), evals = o$n_eval %||% NA)
TAB <- rbind(rowtab("canonical (no row)", id0, net0, fut0), do.call(rbind, lapply(names(RES), function(k) rowtab(k, RES[[k]], RES[[k]]$net, RES[[k]]$futures))))
print(TAB, digits = 5, row.names = FALSE)
for (k in names(RES)) cat(sprintf("  %s: %s\n", k, RES[[k]]$label))
best <- RES$R1
gain <- (best$logpost + best$extra) - (id0$logpost + row_of(net0))
cat(sprintf("  P3 with q10 free: the objective + row gains %+.3f over the canonical (the row %+.3f, the #15 likelihood %+.3f, the priors %+.3f)\n",
            gain, best$extra - row_of(net0), best$lik - id0$lik, (best$logpost - best$lik) - (id0$logpost - id0$lik)))
cat(sprintf("  npp_tsens %+.5f -> %+.5f; q10 %.3f -> %.3f (prior z %+.2f -> %+.2f); net climate effect %+.3f -> %+.3f GtC/yr; SSP5-8.5 2300 %.1f -> %.1f ppm\n",
            id0$block[[P3_GREEN]], best$block[[P3_GREEN]], id0$block[[P3_Q10]], best$block[[P3_Q10]], q10_z(id0$block[[P3_Q10]]),
            q10_z(best$block[[P3_Q10]]), net0, best$net, fut0[[1]], best$futures[[1]]))
tot <- vapply(RES, function(o) o$logpost + o$extra, 0)
cat(sprintf("  the q10 PROFILE with the row (objective + row, d vs R1): %s\n",
            paste(sprintf("q10 %.3f: %+.3f (net %+.3f GtC/yr, #15 likelihood %+.3f)", vapply(RES, function(o) o$block[[P3_Q10]], 0),
                          tot - tot[["R1"]], vapply(RES, `[[`, 0, "net"), vapply(RES, `[[`, 0, "lik") - RES$R1$lik), collapse = "; ")))
cat("  ⚠ CONDITIONAL: 25 names held. CO2 is interactive here and prescribed in TRENDY; the bias that makes is MEASURED small\n     (diag_net_climate_co2_feedback.R: -0.023 GtC/yr at hilda34g, +0.009 at q10 1.4).\n")

sink(); close(LOGCON)
saveRDS(list(table = TAB, identity = id0, cells = RES, gain = gain,
             provenance = sprintf("%s @%s; base hilda34g (%s) at L %.4f; blocks %s (+q10); the row N(%g, %g) on %d-%d vs %d-%d climate held; objective #15; no RNG; %s",
                                  P3_DRIVER, COMMIT, P3_BASE[["LAG"]], L_LAG, paste(P3_BLOCK8, collapse = ","), P3_ROW[["mean"]], P3_ROW[["sd"]],
                                  P3_NET_WIN[1], P3_NET_WIN[2], P3_NET_CLIM[1], P3_NET_CLIM[2], format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(P3_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}\n", P3_OUT))
