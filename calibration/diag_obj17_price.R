#!/usr/bin/env Rscript
# =====================================================================
# diag_obj17_price.R -- OBJECTIVE #17 PRICED on the canonical BEFORE the refit (the build's step 7; handoff
# notes/handoff_2026-10-06c_iav_cut_build.md s. 3). The BUILT objective this time, not the preview's emulation.
#
# WHAT. The main objective under the label hilda_csl3v0kaidgbemw (the low-pass land row; the slope row moved to
# the module), at hilda33p's vector, with the module's four names PINNED:
#   REF  at hilda33p's own module values -- the canonical scored on #17's rows;
#   B1   at stage 1's values (calibration/output/iav_module_<date>_hilda33p.rds), nothing refitted;
#   B2   B1 with the five other land names re-optimised (beta_max, fert_k, luc_scale, imb_share_land, ndep_ret:
#        the preview's block), whitened by hilda33p's stored block precision (lib_block_reopt.R's method);
# and the futures at B2 (SSP5-8.5 and vvH in 2300) against the canonical's.
# GATES: hilda33p reproduces its stored logpost under its OWN label; REF reproduces the smoke check's #17
# likelihood decomposition (land row = the pricing preview's low-pass row); B1 and B2 land within a stated
# tolerance of the preview's (CHANGELOG 10-06 m: land + ocean, low-pass, B1 -10.86 / B2 -10.25). The tolerance is
# NOT typed: the stage-1 values differ from the preview's by < 3e-4 of their own Laplace sigma, so the two
# B1s must agree to the change that difference makes, measured here by re-pricing B1 at the PREVIEW's values.
# ⛔ ADOPTS NOTHING. No RNG.
# Usage: Rscript calibration/diag_obj17_price.R [stage-1 rds]   (CCX_P17_SMOKE=1 for a tiny budget)
# =====================================================================
t_start <- Sys.time()
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

P17_DRIVER <- "calibration/diag_obj17_price.R"
P17_ARGS   <- commandArgs(trailingOnly = TRUE)
P17_MODE   <- "hilda33p"
P17_LABEL  <- "hilda_csl3v0kaidgbemw"
P17_STAGE1 <- if (length(P17_ARGS)) P17_ARGS[1] else file.path("calibration", "output", "iav_module_20261006_hilda33p.rds")
P17_PREVIEW <- file.path("outputs", "diagnostics", "iav_cut_smoothed_land_20261006_hilda33p.rds")
P17_REST   <- c("beta_max", "fert_k", "luc_scale", "imb_share_land", "ndep_ret")     # the preview's B2 block
P17_SMOKE  <- identical(Sys.getenv("CCX_P17_SMOKE", ""), "1")
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L               # the preview's futures
P17_MODE_TOL <- 0.1; P17_PULL_H <- 0.1; P17_NDEPS <- 0.01; P17_RELTOL <- 1e-12       # = lib_block_reopt.R's defaults
P17_BFGS_MAXIT <- if (P17_SMOKE) 2L else 200L; P17_NM_MAXIT <- if (P17_SMOKE) 6L else 1500L; P17_ROUNDS <- if (P17_SMOKE) 1L else 3L
P17_TAG <- paste0(format(Sys.Date(), "%Y%m%d"), "_", P17_MODE, if (P17_SMOKE) "_SMOKE" else "")
P17_OUT <- file.path("outputs", "diagnostics", sprintf("obj17_price_%s", P17_TAG))
COMMIT  <- ccx_git_stamp()
source(file.path("calibration", "lib_block_reopt.R"))        # br_prec, br_u_of_par, br_futures
LOGCON <- file(paste0(P17_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | %s under %s | stage 1 %s%s\n", P17_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), P17_MODE,
            P17_LABEL, P17_STAGE1, if (P17_SMOKE) " | ⚠ SMOKE: tiny budgets, NOT A RESULT" else ""))

MODE_FILE <- ccx_mode_file(P17_MODE); md <- readRDS(MODE_FILE); MODE_MD5 <- unname(tools::md5sum(MODE_FILE))
S1 <- readRDS(P17_STAGE1)
if (!identical(S1$provenance$base_md5, MODE_MD5)) stop("stage 1 was not fitted at this base")
OBS <- ccx_prepare_obs(); SPF <- ccx_spinup_from_label(ccx_mode_spinup(md))
PINS_C <- stats::setNames(as.numeric(md$pins), names(md$pins))
MOD_OWN <- unlist(md$par_mode[CCX_IAV_MODULE_NAMES])
MOD_S1  <- S1$pins[CCX_IAV_MODULE_NAMES]
cat(sprintf("module at hilda33p: %s\nmodule at stage 1:  %s\n", paste(sprintf("%s %.5f", names(MOD_OWN), MOD_OWN), collapse = ", "),
            paste(sprintf("%s %.5f", names(MOD_S1), MOD_S1), collapse = ", ")))

#' The #17 objective with the module pinned at `mod`, as a function of the FREE names' natural values (a named
#' list overriding hilda33p's): returns the logpost with its streams. Gate and pins undone on exit.
score17 <- function(mod, over = NULL, label = P17_LABEL, pins = c(PINS_C, mod)) {
  g <- ccx_apply_gate(label); on.exit(ccx_unapply_gate(g), add = TRUE)
  r <- ccx_apply_pins(pins);  on.exit(ccx_unpin_params(r), add = TRUE, after = FALSE)
  bp <- ccx_apply_structure(ccx_default_params(), label, seas_ml = md$seas_ml, pump_field = ccx_mode_pump_field(md))
  for (n in names(pins)) bp[[n]] <- pins[[n]]
  bp$pump_mode <- md$pump_mode
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = SPF, obs = OBS)
  pm <- ccx_mode_par_with_pins(md); for (n in names(over)) pm[[n]] <- over[[n]]
  v <- lp(ccx_par_to_unc(pm))
  list(logpost = as.numeric(v), lik = attr(v, "loglik"), streams = unlist(attr(v, "streams")))
}

cat("\n=== 0. GATES ===\n")
own <- score17(NULL, label = ccx_mode_struct(md), pins = PINS_C)
cat(sprintf("  hilda33p under its own label: logpost %.6f vs stored %.6f (diff %.1e)\n", own$logpost, md$logpost, own$logpost - md$logpost))
if (!identical(own$logpost, md$logpost)) stop("hilda33p does not reproduce its stored logpost under its own label")
REF <- score17(MOD_OWN)
pv <- readRDS(P17_PREVIEW)
lp_row <- pv$gate[["objective_row"]] - pv$gate[["high_part"]]
cat(sprintf("  REF (hilda33p on #17's rows): likelihood %.6f; land row %.6f vs the pricing preview's low-pass row %.6f (diff %.1e)\n",
            REF$lik, REF$streams[["gcb_land_sink"]], lp_row, REF$streams[["gcb_land_sink"]] - lp_row))
if (abs(REF$streams[["gcb_land_sink"]] - lp_row) > 1e-8) stop("REF's land row is not the preview's low-pass row")
if ("gcb_ocean_enso_slope" %in% names(REF$streams)) stop("the slope row is still in #17's main objective")
com <- setdiff(names(REF$streams), "gcb_land_sink")
if (!identical(REF$streams[com], own$streams[com])) stop("REF moved a row the cut does not touch")

cat("\n=== B1: the module at stage 1's values, nothing refitted ===\n")
B1 <- score17(MOD_S1)
d1 <- B1$streams - REF$streams[names(B1$streams)]
cat(sprintf("  likelihood %+.4f against REF (the preview's land + ocean, low-pass: %+.4f)\n", B1$lik - REF$lik,
            pv$b_table$d_main_lowpass[pv$b_table$cell == "land_ocean_lowpass_B1"]))
print(round(sort(d1[abs(d1) > 0.05]), 3))
# the tolerance, MEASURED: B1 at the preview's own module values (the land_ocean scope's L, s, w on hilda33p's ratio)
pvs <- pv$scopes$land_ocean; G0 <- S1$ratio
MOD_PV <- c(lag_enso_land = pvs[["L"]], gamma_enso_land_NH = pvs[["s"]] * G0[[1]], gamma_enso_land_SH = pvs[["s"]] * G0[[2]],
            w_enso_l2 = pvs[["w"]])
B1pv <- score17(MOD_PV)
b1_prev <- pv$b_table$d_main_lowpass[pv$b_table$cell == "land_ocean_lowpass_B1"]
TOL_B1 <- max(abs(B1$lik - B1pv$lik), 1e-6) * 10
cat(sprintf("  at the PREVIEW's values B1 is %+.6f (preview %+.6f; diff %.1e, the built objective vs its emulation);\n",
            B1pv$lik - REF$lik, b1_prev, B1pv$lik - REF$lik - b1_prev))
cat(sprintf("  stage 1's values move B1 by %.1e, so the gate on B1 vs the preview is 10x that: %.1e\n", abs(B1$lik - B1pv$lik), TOL_B1))
if (abs(B1pv$lik - REF$lik - b1_prev) > 1e-6) stop("the BUILT objective does not reproduce the preview's B1 at the preview's values")
if (abs(B1$lik - REF$lik - b1_prev) > TOL_B1 + 1e-6) stop("B1 at stage 1's values is not within the measured tolerance of the preview's")

cat("\n=== B2: the five other land names re-optimised (whitened, BFGS + Nelder-Mead rounds) ===\n")
u0 <- br_u_of_par(md, P17_REST); U <- chol(br_prec(md, P17_REST))
fB2 <- function(z) { uu <- u0 + backsolve(U, z); par <- stats::setNames(as.list(vapply(P17_REST, function(n)
    .from_unc(uu[[n]], CCX_PARAM_GATED_ALL[[n]] %||% CCX_PARAM_TABLE[[n]]), 0)), P17_REST)
  v <- tryCatch(score17(MOD_S1, over = par)$logpost, error = function(e) -Inf); if (is.finite(v)) -v else 1e10 }
slope <- function(z) vapply(seq_along(z), function(i) { e <- rep(0, length(z)); e[i] <- P17_PULL_H
  (fB2(z + e) - fB2(z - e)) / (2 * P17_PULL_H) }, 0)
z <- rep(0, length(P17_REST)); s <- slope(z); rounds <- 0L; t2 <- Sys.time()
while (max(abs(s)) >= P17_MODE_TOL && rounds < P17_ROUNDS) {
  rounds <- rounds + 1L
  o1 <- stats::optim(z, fB2, method = "BFGS", control = list(ndeps = rep(P17_NDEPS, length(z)), reltol = P17_RELTOL, maxit = P17_BFGS_MAXIT))
  o2 <- stats::optim(rep(0, length(z)), function(w) fB2(o1$par + w), method = "Nelder-Mead", control = list(reltol = P17_RELTOL, maxit = P17_NM_MAXIT))
  z <- o1$par + o2$par; s <- slope(z)
  cat(sprintf("  round %d: logpost %.4f, max whitened slope %.3f\n", rounds, -fB2(z), max(abs(s))))
}
uB2 <- u0 + backsolve(U, z)
parB2 <- stats::setNames(as.list(vapply(P17_REST, function(n) .from_unc(uB2[[n]], CCX_PARAM_GATED_ALL[[n]] %||% CCX_PARAM_TABLE[[n]]), 0)), P17_REST)
B2 <- score17(MOD_S1, over = parB2)
d2 <- B2$streams - REF$streams[names(B2$streams)]
b2_prev <- pv$b_table$d_main_lowpass[pv$b_table$cell == "land_ocean_lowpass_B2"]
cat(sprintf("  %d rounds, %.1f min, converged (max whitened slope < %.1f): %s\n", rounds,
            as.numeric(difftime(Sys.time(), t2, units = "mins")), P17_MODE_TOL, max(abs(s)) < P17_MODE_TOL))
cat(sprintf("  likelihood %+.4f against REF (the preview's: %+.4f); prior part %+.4f\n", B2$lik - REF$lik, b2_prev,
            (B2$logpost - B2$lik) - (REF$logpost - REF$lik)))
cat(sprintf("  the block: %s\n", paste(sprintf("%s %.5g (hilda33p %.5g)", P17_REST, unlist(parB2),
                                                 vapply(P17_REST, function(n) md$par_mode[[n]], 0)), collapse = "; ")))
print(round(sort(d2[abs(d2) > 0.05]), 3))
SEAS <- grep("seasonal", names(d2), value = TRUE)
cat(sprintf("  of which the seasonal rows %+.3f and the land row %+.3f\n", sum(d2[SEAS]), d2[["gcb_land_sink"]]))

cat("\n=== THE FUTURES at B2 (CO2 in 2300, ppm) ===\n")
vb <- dg_vector(MODE_FILE); vb2 <- vb
for (n in c(names(MOD_S1), P17_REST)) { val <- c(MOD_S1, unlist(parB2))[[n]]; if (n %in% names(vb2$p)) vb2$p[[n]] <- val; vb2$pm[[n]] <- val }
vb2$p <- ccx_set_enso(vb2$p, vb2$pm); vb2$luc_scale <- vb2$pm$luc_scale
f0 <- br_futures(vb, dg_spinup(vb)); f2 <- br_futures(vb2, dg_spinup(vb2))
cat(sprintf("  %s: canonical %.2f -> B2 %.2f (%+.2f)\n", names(f0), f0, f2, f2 - f0), sep = "")
cat(sprintf("  (the preview's land + ocean low-pass B2: SSP5-8.5 %+.2f, vvH %+.2f)\n", pv$futures["land_ocean_lowpass_B2", 1],
            pv$futures["land_ocean_lowpass_B2", 2]))

sink(); close(LOGCON)
saveRDS(list(ref = REF, b1 = B1, b1_at_preview = B1pv, b2 = B2, b2_block = unlist(parB2), b2_converged = max(abs(s)) < P17_MODE_TOL,
             b2_rounds = rounds, d1 = d1, d2 = d2, futures_canonical = f0, futures_b2 = f2,
             provenance = list(driver = P17_DRIVER, commit = COMMIT, mode = P17_MODE, mode_md5 = MODE_MD5, label = P17_LABEL,
                               stage1 = P17_STAGE1, stage1_commit = S1$provenance$commit, module = MOD_S1, rest = P17_REST,
                               preview = P17_PREVIEW, tol_b1 = TOL_B1, rng = "none", smoke = P17_SMOKE,
                               date = as.character(Sys.Date()))), paste0(P17_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds} | %.1f min\n", P17_OUT, as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
