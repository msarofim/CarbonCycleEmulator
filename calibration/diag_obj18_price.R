#!/usr/bin/env Rscript
# =====================================================================
# diag_obj18_price.R -- OBJECTIVE #18 PRICED at #17's basin B with the BUILT objective (handoff
# notes/handoff_2026-10-07c_obj18_build.md s. 3.5; CHANGELOG 2026-10-07 f). diag_obj17_price.R's design, on #18.
#
# WHAT. The main objective under the label hilda_csl3v0kaidgbemwt (#17 + the detrended ENSO index + the low-pass
# gcb_ocean_sink row), at basin B's vector (RULED 10-07 b: #17's representative; 10-07 f: stage 1's base), with the
# module's four names PINNED at
#   P0   B's own pins (#17's stage 1 at hilda33p; w_enso_l2 14.73): where the pricing's emulation scored, and
#   S18  stage 1 under #18 at B (fit_iav_module.R --struct; w_enso_l2 16.61, +1.47 sigma from P0): the values stage 2
#        will pin.
# Cells (likelihood against REF, on #18's rows):
#   REF        #18 minus the index (the shipped index, the low-pass ocean row) at P0 = the emulation's REF;
#   B1         #18 at P0, nothing refitted (the index switch alone) = the emulation's B1, -12.342383;
#   B1s        #18 at S18, nothing refitted (B1 + the module's move: the redesign's resistance);
#   B2 / B2s   ... + the five land names re-optimized (beta_max, fert_k, luc_scale, imb_share_land, ndep_ret:
#              diag_obj17_price.R's block and method, whitened by B's stored Hessian block);
#   B2f / B2fs ... with beta_max HELD at B's value and the other four re-optimized: the index's effect at a FIXED
#              position on the beta_max / fert_k ridge (diag_iav_redesign_ridge.R's cell at B's beta_max).
# FUTURES: CO2 in 2300 (SSP5-8.5; vvH spliced on the historical emissions; br_futures()) at hilda33p, B and every cell,
# read against the ridge's MEASURED 1-sigma width (iav_redesign_ridge_read_20261007_wide.rds, natural space): a futures
# move smaller than that width is not a finding ([[block_refit_futures_can_be_ridge_position]]).
# GATES (the driver stops on any): B reproduces its stored logpost and rows under its own label (identical()); REF and
# B1 reproduce the emulation (diag_iav_redesign_price.R @e891fa9) within the objective's noise floor (1e-5); stage 1's
# file is a non-smoke #18 run at B's file, and its values ARE the pricing mirror's (identical(): the run reproduced it
# exactly), so B1s must reproduce the emulation's resistance at P1d; B2 must reproduce the emulation's B2, and B2f the
# ridge's cell at B's beta_max, each within its own re-fit's convergence bound (1/2 x O18_MODE_TOL^2 per free name) --
# the same method from the same start on the same objective, so a larger gap is a defect. The futures of B, B1 and B2
# must reproduce the emulation's, and B2f's the ridge cell's, to O18_FUT_TOL (a vector that reproduces bit for bit
# reproduces its futures bit for bit; the tolerance only absorbs a re-fit that lands within its bound).
# ⛔ ADOPTS NOTHING. No RNG.
# Usage: Rscript calibration/diag_obj18_price.R   (CCX_P18_WORKERS, default 4; CCX_P18_SMOKE=1 tiny budgets, re-fit gates
#        reported only)
# OUTPUTS: outputs/diagnostics/obj18_price_<date>.{log,rds}
# =====================================================================
t_start <- Sys.time()
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L      # = the emulation's and the ridge's
source(file.path("calibration", "lib_block_reopt.R"))                   # br_prec, br_u_of_par, br_futures
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
O18_DRIVER  <- "calibration/diag_obj18_price.R"
O18_LABEL   <- "hilda_csl3v0kaidgbemwt"                                  # objective #18 (RULED 10-07 f)
O18_FIELDS  <- c("enso_index", "gcb_ocean_lowpass_df")                   # what #18 adds to #17's block
O18_MODE_B  <- file.path("calibration", "output", "refit_20261006_obj17_basinB_start001_DRYRUN", "mode_fit_pumpN.rds")
O18_MODE_B_MD5 <- "081eb16f4fe718692004fb1cf9645891"                     # the file the 10-07 (b)/(d)/(e) tables name
O18_CANON   <- "hilda33p"                                                # the canonical, for the futures' reference
O18_STAGE1  <- file.path("calibration", "output",
                         "iav_module_20261007_refit_20261006_obj17_basinB_start001_DRYRUN_hilda_csl3v0kaidgbemwt.rds")
O18_EMUL    <- file.path("outputs", "diagnostics", "iav_redesign_price_20261007.rds")         # @e891fa9
O18_RIDGE   <- file.path("outputs", "diagnostics", "iav_redesign_ridge_20261007_wide.rds")    # @78b67e0
O18_RIDGE_READ <- file.path("outputs", "diagnostics", "iav_redesign_ridge_read_20261007_wide.rds")
O18_ROW     <- "gcb_ocean_sink"
O18_REST    <- c("beta_max", "fert_k", "luc_scale", "imb_share_land", "ndep_ret")   # diag_obj17_price.R's B2 block
O18_HELD    <- "beta_max"
O18_FOLLOW  <- setdiff(O18_REST, O18_HELD)                               # = diag_iav_redesign_ridge.R's RF_FOLLOW, in order
O18_REPRO_TOL <- 1e-5                                                    # the objective's noise floor (memory objective_noise_floor_optimum_on_spike)
O18_FUT_TOL <- 1e-6                                                      # ppm: a bit-identical vector's futures
O18_SMOKE   <- identical(Sys.getenv("CCX_P18_SMOKE", ""), "1")
O18_WORKERS <- as.integer(Sys.getenv("CCX_P18_WORKERS", "4"))
O18_MODE_TOL <- 0.1; O18_PULL_H <- 0.1; O18_NDEPS <- 0.01; O18_RELTOL <- 1e-12     # = lib_block_reopt.R's defaults
O18_BFGS_MAXIT <- if (O18_SMOKE) 2L else 200L; O18_NM_MAXIT <- if (O18_SMOKE) 6L else 1500L; O18_ROUNDS <- if (O18_SMOKE) 1L else 3L
O18_REFIT_TOL <- function(k) 0.5 * O18_MODE_TOL^2 * k                    # a re-fit's own convergence bound, k free names
O18_TAG  <- paste0(format(Sys.Date(), "%Y%m%d"), if (O18_SMOKE) "_SMOKE" else "")
O18_OUT  <- file.path("outputs", "diagnostics", sprintf("obj18_price_%s", O18_TAG))
COMMIT   <- ccx_git_stamp()
`%||%` <- function(a, b) if (is.null(a)) b else a
LOGCON <- file(paste0(O18_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | %s at basin B (%s) | stage 1 %s | %d workers%s\n", O18_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"),
            O18_LABEL, O18_MODE_B, O18_STAGE1, O18_WORKERS, if (O18_SMOKE) " | ⚠ SMOKE: tiny budgets, NOT A RESULT" else ""))

# ---- the inputs ---------------------------------------------------------------------
if (!identical(unname(tools::md5sum(O18_MODE_B)), O18_MODE_B_MD5)) stop("basin B's file is not the one the 10-07 tables name")
MD  <- readRDS(O18_MODE_B); SPF <- ccx_spinup_from_label(ccx_mode_spinup(MD))
stopifnot(identical(ccx_mode_struct(MD), CCX_MODE_OBJ17_STRUCT))
b17 <- ccx_struct_block(ccx_mode_struct(MD)); b18 <- ccx_struct_block(O18_LABEL)
stopifnot(identical(setdiff(names(b18), names(b17)), O18_FIELDS), identical(b18[names(b17)], b17))
OBS <- ccx_prepare_obs()
P0  <- ccx_mode_pins(MD); P0 <- stats::setNames(as.numeric(unclass(P0)), names(P0))
TEN <- P0[setdiff(names(P0), CCX_IAV_MODULE_NAMES)]
EM  <- readRDS(O18_EMUL); RG <- readRDS(O18_RIDGE); RR <- readRDS(O18_RIDGE_READ); S18F <- readRDS(O18_STAGE1)
stopifnot(identical(EM$provenance$mode_b_md5, O18_MODE_B_MD5), identical(RG$provenance$mode_b_md5, O18_MODE_B_MD5),
          !EM$provenance$smoke)
MOD_P0  <- P0[CCX_IAV_MODULE_NAMES]
MOD_S18 <- S18F$pins[CCX_IAV_MODULE_NAMES]
cat(sprintf("module P0  (B's own pins):          %s\nmodule S18 (stage 1 under #18 at B): %s\n",
            paste(sprintf("%s %.5f", names(MOD_P0), MOD_P0), collapse = ", "), paste(sprintf("%s %.5f", names(MOD_S18), MOD_S18), collapse = ", ")))

#' Basin B's vector under `label`, the module pinned at `mod` (on top of the ten), `strip` removing structure fields from
#' the base. Builds the objective ONCE and hands FUN an evaluator of the free names' natural values (`over`). Gate and
#' pins undone on exit.
with_label <- function(label, mod, FUN, strip = NULL) {
  pins <- c(TEN, mod)
  g <- ccx_apply_gate(label); on.exit(ccx_unapply_gate(g), add = TRUE)
  r <- ccx_apply_pins(pins);  on.exit(ccx_unpin_params(r), add = TRUE, after = FALSE)
  bp <- ccx_apply_structure(ccx_default_params(), label, seas_ml = MD$seas_ml, pump_field = ccx_mode_pump_field(MD))
  for (n in names(pins)) bp[[n]] <- pins[[n]]
  for (n in strip) bp[[n]] <- NULL
  bp$pump_mode <- MD$pump_mode
  lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = SPF, obs = OBS)
  ev <- function(over = NULL) {
    pm <- ccx_mode_par_with_pins(MD); for (n in names(over)) pm[[n]] <- over[[n]]
    v <- lp(ccx_par_to_unc(pm))
    if (!is.finite(v)) return(list(logpost = -Inf))
    list(logpost = as.numeric(v), lik = attr(v, "loglik"), prior = as.numeric(v) - attr(v, "loglik"),
         streams = unlist(attr(v, "streams")))
  }
  FUN(ev)
}
score <- function(mod, over = NULL, label = O18_LABEL, strip = NULL) with_label(label, mod, function(ev) ev(over), strip)
#' Re-optimize `block` (natural `held` names fixed) at basin B's vector under #18 with the module at `mod`: whitened by B's
#' stored Hessian block, BFGS + Nelder-Mead rounds until every whitened slope < O18_MODE_TOL (diag_obj17_price.R's B2
#' method; the emulation's reopt() and the ridge's profile_cell(), line for line, on the built objective).
reopt <- function(mod, block, held = NULL, what) {
  U <- chol(br_prec(MD, block)); u0 <- br_u_of_par(MD, block)
  par_of_z <- function(z) { uu <- u0 + backsolve(U, z)
    c(held, stats::setNames(as.list(vapply(block, function(n) .from_unc(uu[[n]], CCX_PARAM_GATED_ALL[[n]] %||% CCX_PARAM_TABLE[[n]]), 0)), block)) }
  t0 <- Sys.time()
  o <- with_label(O18_LABEL, mod, function(ev) {
    f <- function(z) { v <- tryCatch(ev(par_of_z(z))$logpost, error = function(e) -Inf); if (is.finite(v)) -v else 1e10 }
    slope <- function(z) vapply(seq_along(z), function(i) { e <- rep(0, length(z)); e[i] <- O18_PULL_H
      (f(z + e) - f(z - e)) / (2 * O18_PULL_H) }, 0)
    z <- rep(0, length(block)); s <- slope(z); s_start <- s; rounds <- 0L
    while (max(abs(s)) >= O18_MODE_TOL && rounds < O18_ROUNDS) {
      rounds <- rounds + 1L
      o1 <- stats::optim(z, f, method = "BFGS", control = list(ndeps = rep(O18_NDEPS, length(z)), reltol = O18_RELTOL, maxit = O18_BFGS_MAXIT))
      o2 <- stats::optim(rep(0, length(z)), function(w) f(o1$par + w), method = "Nelder-Mead", control = list(reltol = O18_RELTOL, maxit = O18_NM_MAXIT))
      z <- o1$par + o2$par; s <- slope(z)
    }
    list(z = z, s = s, s_start = s_start, rounds = rounds, at = ev(par_of_z(z))) })
  o$par <- unlist(par_of_z(o$z)); o$converged <- max(abs(o$s)) < O18_MODE_TOL; o$what <- what; o$block <- block
  o$held <- unlist(held); o$mod <- mod; o$minutes <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
  o
}
#' Basin B's dg vector rebuilt under `label` (the file's own vector and pins, by dg_vector()'s resolver) with `vals`
#' (natural) overriding names. The model list may differ from the stored one only in the label's added fields.
vec_under <- function(label, vals = NULL) {
  V <- dg_vector(O18_MODE_B)
  if (!identical(label, ccx_mode_struct(MD))) {
    md_l <- MD; md_l$struct <- label
    p_l <- ccx_overlay_par(ccx_mode_base(md_l), V$pm); p_l$pump_mode <- MD$pump_mode
    moved <- Filter(function(n) !identical(p_l[[n]], V$p[[n]]), union(names(p_l), names(V$p)))
    if (!setequal(moved, setdiff(names(ccx_struct_block(label)), names(b17)))) stop("vec_under(): the rebuilt list moved ", paste(moved, collapse = ", "))
    V$p <- p_l
  }
  for (n in names(vals)) { if (n %in% names(V$p)) V$p[[n]] <- vals[[n]]; V$pm[[n]] <- vals[[n]] }
  V$p <- ccx_set_enso(V$p, V$pm); V$luc_scale <- V$pm$luc_scale; V
}
fut_of <- function(V) br_futures(V, dg_spinup(V))
GATES <- list()
gate <- function(name, value, tol, what) {
  ok <- is.finite(value) && abs(value) <= tol
  GATES[[name]] <<- c(value = value, tol = tol, pass = ok)
  cat(sprintf("  GATE %-22s %s: %+.3e (tol %.1e) %s\n", name, what, value, tol, if (ok) "PASS" else "FAIL"))
  if (!ok) stop("GATE ", name, " failed: ", what)
}

cat("\n=== 0. GATES ===\n")
own <- score(MOD_P0, label = ccx_mode_struct(MD))
same_rows <- identical(own$streams[names(unlist(MD$streams))], unlist(MD$streams))
cat(sprintf("  B under its own label (%s): logpost %.9f vs stored %.9f, identical() %s; its %d rows identical() %s\n",
            ccx_mode_struct(MD), own$logpost, MD$logpost, identical(own$logpost, MD$logpost), length(MD$streams), same_rows))
if (!identical(own$logpost, MD$logpost) || !same_rows) stop("basin B does not reproduce its stored logpost / rows under its own label")
s1p <- S18F$provenance
cat(sprintf("  stage 1: %s @%s, base md5 %s, %s -> %s (index '%s'), smoke %s\n", s1p$driver, s1p$commit, s1p$base_md5, s1p$base_struct,
            s1p$struct, s1p$enso_index, s1p$smoke))
if (!identical(s1p$base_md5, O18_MODE_B_MD5) || !identical(s1p$struct, O18_LABEL) || isTRUE(s1p$smoke) || !identical(s1p$enso_index, "detrend"))
  stop("the stage-1 file is not a non-smoke #18 run at basin B's file")
MIR <- EM$stage1$B_detrend$pins[CCX_IAV_MODULE_NAMES]
cat(sprintf("  stage 1's values vs the pricing mirror's (emulation $stage1$B_detrend): identical() %s\n", identical(MOD_S18, MIR)))
if (!identical(MOD_S18, MIR)) stop("stage 1's values are not the mirror's: re-derive the B1s gate before pricing")
REF <- score(MOD_P0, strip = "enso_index")
gate("REF_logpost", REF$logpost - EM$ref$logpost_lp, O18_REPRO_TOL, "REF (#18 minus the index) vs the emulation's REF")
gate("REF_rows", max(abs(REF$streams[names(EM$ref$st_lp)] - EM$ref$st_lp)), O18_REPRO_TOL, "REF's rows vs the emulation's")

cat("\n=== 1. UNREFITTED: B1 (the index switch, module at P0) and B1s (+ the module's move to stage 1's values) ===\n")
B1  <- score(MOD_P0)
B1s <- score(MOD_S18)
gate("B1_logpost", B1$logpost - EM$b1$logpost_lp, O18_REPRO_TOL, "B1 vs the emulation's B1")
gate("B1_rows", max(abs(B1$streams[names(EM$b1$st_lp)] - EM$b1$st_lp)), O18_REPRO_TOL, "B1's rows vs the emulation's")
RES_P1d <- sum(EM$resistance$P1d_detrend_lp)
gate("B1s_resistance", (B1s$lik - B1$lik) - RES_P1d, O18_REPRO_TOL, "B1s - B1 vs the emulation's resistance at P1d (redesign's rows)")
row_table <- function(d, top = 10L) d[order(-abs(d))][seq_len(min(top, length(d)))]
d1  <- B1$streams - REF$streams[names(B1$streams)]
d1s <- B1s$streams - REF$streams[names(B1s$streams)]
cat(sprintf("  B1  likelihood %+.6f against REF (prior %+.6f) -- the emulation's B1 %+.6f\n", B1$lik - REF$lik, B1$prior - REF$prior,
            EM$b1$lik_lp - EM$ref$lik_lp))
print(round(row_table(d1), 3))
cat(sprintf("  B1s likelihood %+.6f against REF; the module's move P0 -> S18 costs %+.6f on #18's WHOLE objective (#17 as landed: %+.4f)\n",
            B1s$lik - REF$lik, B1s$lik - B1$lik, sum(EM$resistance$P1_shipped_full)))
print(round(row_table(B1s$streams - B1$streams[names(B1s$streams)]), 3))

cat(sprintf("\n=== 2. RE-FITTED: B2 / B2s (%s re-optimised) and B2f / B2fs (%s HELD at B's %.5f, %s re-optimised) ===\n",
            paste(O18_REST, collapse = ", "), O18_HELD, MD$par_mode[[O18_HELD]], paste(O18_FOLLOW, collapse = ", ")))
HELD_B <- stats::setNames(list(MD$par_mode[[O18_HELD]]), O18_HELD)
CELLS <- list(B2 = list(mod = MOD_P0, block = O18_REST, held = NULL), B2s = list(mod = MOD_S18, block = O18_REST, held = NULL),
              B2f = list(mod = MOD_P0, block = O18_FOLLOW, held = HELD_B), B2fs = list(mod = MOD_S18, block = O18_FOLLOW, held = HELD_B))
RO <- parallel::mclapply(names(CELLS), function(k) { while (sink.number() > 0L) sink()
  x <- CELLS[[k]]; reopt(x$mod, x$block, x$held, k) }, mc.cores = O18_WORKERS)
bad <- vapply(RO, inherits, logical(1), "try-error"); if (any(bad)) stop("a re-fit failed: ", paste(unlist(RO[bad]), collapse = " | "))
names(RO) <- names(CELLS)
for (k in names(RO)) { o <- RO[[k]]
  cat(sprintf("  %-5s %d round(s), %.1f min, max whitened slope %.3f -> %.3f (converged < %.1f: %s); likelihood %+.4f against REF, prior %+.4f\n",
              k, o$rounds, o$minutes, max(abs(o$s_start)), max(abs(o$s)), O18_MODE_TOL, o$converged, o$at$lik - REF$lik, o$at$prior - REF$prior))
  cat(sprintf("        the block: %s\n", paste(sprintf("%s %.5g (B %.5g)", names(o$par), o$par, vapply(names(o$par), function(n) MD$par_mode[[n]], 0)),
                                             collapse = "; ")))
}
if (!O18_SMOKE) {
  if (!all(vapply(RO, `[[`, logical(1), "converged"))) stop("a re-fit did not converge within ", O18_ROUNDS, " rounds")
  gate("B2_vs_emulation", RO$B2$at$logpost - EM$b2$logpost_lp, O18_REFIT_TOL(length(O18_REST)), "B2 vs the emulation's B2 (logpost)")
  rg <- RG$table[RG$table$obj == "redesign" & abs(RG$table$beta_max - MD$par_mode[[O18_HELD]]) < 1e-12, ]
  if (nrow(rg) != 1L) stop("the ridge has no redesign cell at B's beta_max")
  gate("B2f_vs_ridge", RO$B2f$at$logpost - rg$logpost, O18_REFIT_TOL(length(O18_FOLLOW)), "B2f vs the ridge's cell at B's beta_max (logpost)")
  cat(sprintf("  (exactness, reported: B2's block vs the emulation's max |diff| %.1e; B2f's vs the ridge cell's fert_k %+.1e, ndep_ret %+.1e)\n",
              max(abs(RO$B2$par[names(EM$b2_block)] - EM$b2_block)), RO$B2f$par[["fert_k"]] - rg$fert_k, RO$B2f$par[["ndep_ret"]] - rg$ndep_ret))
}
for (k in c("B2", "B2s")) { d <- RO[[k]]$at$streams - REF$streams[names(RO[[k]]$at$streams)]
  cat(sprintf("  %s per row against REF:\n", k)); print(round(row_table(d), 3))
  cat(sprintf("    of which the ice cores %+.3f, the CO2 level rows %+.3f, the seasonal rows %+.3f, the two GCB rows %+.3f\n",
              sum(d[grep("icecore", names(d))]), sum(d[grep("^co2_level_", names(d))]), sum(d[grep("seasonal", names(d))]),
              sum(d[c("gcb_ocean_sink", "gcb_land_sink")]))) }

cat(sprintf("\n=== 3. THE FUTURES: CO2 (ppm) in %d, read against the ridge's measured 1-sigma width ===\n", BR_FUT_YEAR))
VC <- dg_vector(ccx_mode_file(O18_CANON))
FV <- list(hilda33p = VC, B = vec_under(ccx_mode_struct(MD)), B1 = vec_under(O18_LABEL, MOD_P0), B1s = vec_under(O18_LABEL, MOD_S18))
for (k in names(RO)) FV[[k]] <- vec_under(O18_LABEL, c(RO[[k]]$mod, RO[[k]]$par))    # $par carries the held name too
for (k in setdiff(names(FV), c("hilda33p", "B")))
  if (!identical(ccx_enso_index_of(dg_spinup(FV[[k]])$params), "detrend")) stop(k, ": the vector does not carry the detrended index")
FUT <- t(vapply(FV, fut_of, numeric(length(BR_FUT_SPLICE))))
gate("FUT_B", max(abs(FUT["B", ] - EM$futures["B", ])), O18_FUT_TOL, "B's futures vs the emulation's")
gate("FUT_B1", max(abs(FUT["B1", ] - EM$futures["B1", ])), O18_FUT_TOL, "B1's futures vs the emulation's")
if (!O18_SMOKE) {
  cat(sprintf("  (re-fit cells: B2 vs the emulation's B2 %+.4f / %+.4f ppm; B2f vs the ridge's cell %+.4f / %+.4f ppm -- reported: a re-fit within its bound may move them)\n",
              FUT["B2", 1] - EM$futures["B2", 1], FUT["B2", 2] - EM$futures["B2", 2], FUT["B2f", 1] - rg$ssp585, FUT["B2f", 2] - rg$vvH))
}
RN <- RR$fits$redesign_natural
W1 <- rbind(lo = RN$fut_lo - RN$fut_hat, hi = RN$fut_hi - RN$fut_hat)   # the ridge's 1-sigma futures interval about its optimum
cat(sprintf("  the ridge (redesign, natural space; %s): %s optimum %.3f, 1-sigma %.3f-%.3f -> SSP5-8.5 %+.1f / %+.1f, vvH %+.1f / %+.1f ppm about %.1f / %.1f\n",
            basename(O18_RIDGE_READ), O18_HELD, RN$measured[["opt"]], RN$measured[["lo"]], RN$measured[["hi"]], W1["lo", "ssp585"], W1["hi", "ssp585"],
            W1["lo", "vvH"], W1["hi", "vvH"], RN$fut_hat[["ssp585"]], RN$fut_hat[["vvH"]]))
HALF <- pmin(abs(W1["lo", ]), abs(W1["hi", ]))                            # the narrower side: the conservative width
cat(sprintf("  %-9s %10s %9s %10s %9s   %s\n", "", "SSP5-8.5", "vs B", "vvH", "vs B", "vs the ridge's 1-sigma (the narrower side)"))
for (k in rownames(FUT)) { dB <- FUT[k, ] - FUT["B", ]
  cat(sprintf("  %-9s %10.2f %+9.2f %10.2f %+9.2f   %s\n", k, FUT[k, 1], dB[1], FUT[k, 2], dB[2],
              if (k %in% c("hilda33p", "B")) "" else sprintf("%.2f / %.2f of the width%s", abs(dB[1]) / HALF[1], abs(dB[2]) / HALF[2],
                                                             if (all(abs(dB) < HALF)) " -- INSIDE: not a finding" else ""))) }
cat(sprintf("  the index's own effect at a FIXED %s (B2f - B): SSP5-8.5 %+.2f, vvH %+.2f (the ridge read at B's %s: %+.2f / %+.2f)\n", O18_HELD,
            FUT["B2f", 1] - FUT["B", 1], FUT["B2f", 2] - FUT["B", 2], O18_HELD,
            RR$index_effect$ssp585[abs(RR$index_effect$beta_max - MD$par_mode[[O18_HELD]]) < 1e-12],
            RR$index_effect$vvH[abs(RR$index_effect$beta_max - MD$par_mode[[O18_HELD]]) < 1e-12]))
cat(sprintf("  the module's move P0 -> S18 at each cell: B1 %+.2f / %+.2f, B2 %+.2f / %+.2f, B2f %+.2f / %+.2f ppm\n",
            FUT["B1s", 1] - FUT["B1", 1], FUT["B1s", 2] - FUT["B1", 2], FUT["B2s", 1] - FUT["B2", 1], FUT["B2s", 2] - FUT["B2", 2],
            FUT["B2fs", 1] - FUT["B2f", 1], FUT["B2fs", 2] - FUT["B2f", 2]))

saveRDS(list(ref = REF, own = own, b1 = B1, b1s = B1s, refits = RO, d1 = d1, d1s = d1s, futures = FUT, ridge_width = W1, gates = GATES,
             pins = list(P0 = P0, mod_p0 = MOD_P0, mod_s18 = MOD_S18),
             provenance = list(driver = O18_DRIVER, commit = COMMIT, date = format(Sys.time(), "%Y-%m-%d %H:%M"), smoke = O18_SMOKE,
                               label = O18_LABEL, mode_b = O18_MODE_B, mode_b_md5 = O18_MODE_B_MD5, canon = O18_CANON,
                               canon_md5 = unname(tools::md5sum(ccx_mode_file(O18_CANON))), stage1 = O18_STAGE1,
                               stage1_md5 = unname(tools::md5sum(O18_STAGE1)), stage1_commit = s1p$commit, emulation = O18_EMUL,
                               emulation_commit = EM$provenance$commit, ridge = O18_RIDGE, ridge_commit = RG$provenance$commit,
                               ridge_read = O18_RIDGE_READ, rest = O18_REST, held = O18_HELD, follow = O18_FOLLOW,
                               tols = c(repro = O18_REPRO_TOL, fut = O18_FUT_TOL, mode = O18_MODE_TOL, pull_h = O18_PULL_H, ndeps = O18_NDEPS,
                                        reltol = O18_RELTOL, bfgs = O18_BFGS_MAXIT, nm = O18_NM_MAXIT, rounds = O18_ROUNDS),
                               futures = paste(names(BR_FUT_SPLICE), collapse = "+"), fut_year = BR_FUT_YEAR, workers = O18_WORKERS,
                               rng = "none", units = "log-likelihood units; CO2 ppm")),
        paste0(O18_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds} | %.1f min\n⛔ ADOPTS NOTHING.\n", O18_OUT, as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
sink(); close(LOGCON)
