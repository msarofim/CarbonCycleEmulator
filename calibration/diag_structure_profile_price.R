# =====================================================================
# diag_structure_profile_price.R -- THE PRICE OF THE INTERMEDIATE PROFILE
# (prereg 2026-09-06c sec.7, amendment 3): an iso-fit frontier on the slabs' weight. Prereg notes/prereg_2026-09-06c_structure_identifiability.md
# sec.5 (the amendment): the first run's Hessian at the working arm was
# INDEFINITE because the point was far from an optimum (gradients up to 6114
# per log-unit), and marginal sds off an indefinite matrix are not a count.
#
# Maximizes the LIKELIHOOD (objective change #8 included, NO priors) over the
# same ten log-parameters with everything else at ent26, L-BFGS-B inside
# physical box bounds, then recomputes the Hessian there and scores I1-I10.
# ⚠ A conditional optimum of ten parameters with sixteen held is NOT a mode
# and nothing here is adopted.
#
# Usage:  Rscript calibration/diag_structure_conditional_optimum.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))

SO_STEP        <- 0.05; SO_STEPS_STAB <- c(0.025, 0.1); SO_STAB_TOL <- 0.25
SO_GRAD_STEP   <- 0.01                  # log step for L-BFGS-B's numerical gradient
SO_MUT         <- 0.5; SO_MUT_MIN <- 2
SO_SD_SUPPORT  <- 0.5; SO_COUPLING <- 0.5
SO_HILDA_W     <- c(u_hs = 17 / 38, tau_q = 510 / 538)
SO_NEW <- c("kz_deep_frac", "kz_zscale", "u_hs", "tau_q", "hs_asx_frac", "h_hs")
SO_OLD <- c("kz", "k_w", "bomb_total", "h_ml")
SO_ALL <- c(SO_NEW, SO_OLD)
SO_ARM <- list(hs_frac = 0.16, u_hs = 38, tau_q = 538, sst_hs = 2, q_attach_from = 10,
               kz_zscale = 253, kz_deep_frac = 0.166, hs_asx_frac = 1)
SO_BOUNDS <- list(kz_deep_frac = c(1e-3, 1), kz_zscale = c(50, 3000), u_hs = c(1, 400),
                  tau_q = c(30, 5000), hs_asx_frac = c(0.05, 5), h_hs = c(20, 500),
                  kz = c(500, 20000), k_w = c(300, 6000), bomb_total = c(60, 200), h_ml = c(30, 300))
SO_MAXIT  <- 150
SO_I7_FRAC <- 0.5
SO_OUT <- ccx_path("outputs", "diagnostics", "structure_profile_price_20260906.rds")
SO_W <- c(3, 10, 30)                      # the frontier device: slab weight multipliers
SO_NEFF_TRUE <- LIK_D14C_MID_NEFF

v0 <- dg_vector(CCX_MODE_CANONICAL)
base_p <- v0$p
for (n in names(SO_ARM)) base_p[[n]] <- SO_ARM[[n]]
base_p$h_hs <- base_p$h_ml
centre <- c(kz_deep_frac = base_p$kz_deep_frac, kz_zscale = base_p$kz_zscale, u_hs = base_p$u_hs,
            tau_q = base_p$tau_q, hs_asx_frac = base_p$hs_asx_frac, h_hs = base_p$h_hs,
            kz = base_p$kz, k_w = base_p$k_w, bomb_total = v0$bomb_total, h_ml = base_p$h_ml)
cat(sprintf("\n=== THE PRICE OF THE INTERMEDIATE PROFILE: iso-fit frontier over the slab weight; %d free; mode %s ===\n",
            length(SO_ALL), CCX_MODE_CANONICAL))
cat(sprintf("  start: %s\n", paste(sprintf("%s %.4g", names(centre), centre), collapse = ", ")))

cache <- new.env()
ll_at <- function(theta) {          # theta: log-offsets from `centre`, named
  key <- paste(LIK_D14C_MID_NEFF, paste(sprintf("%s=%.7f", names(theta), theta), collapse = ";"))
  if (!is.null(cache[[key]])) return(cache[[key]])
  p <- base_p; v <- v0
  for (n in names(theta)) { val <- centre[[n]] * exp(theta[[n]])
    if (n == "bomb_total") v$bomb_total <- val else p[[n]] <- val }
  v$p <- p
  res <- tryCatch({ r <- dg_run(v); st <- dg_streams(r, v); list(ll = sum(st), st = st) },
                  error = function(e) list(ll = -1e10, st = NULL))
  if (!is.finite(res$ll)) res$ll <- -1e10
  cache[[key]] <- res
  res
}
th0 <- stats::setNames(rep(0, length(SO_ALL)), SO_ALL)
f0  <- ll_at(th0)
# the two references under objective #8, recomputed
ref_R0 <- local({ v <- v0; p <- v0$p; p$hs_frac <- 0; v$p <- p; r <- dg_run(v); sum(dg_streams(r, v)) })
cat(sprintf("  logL at the arm %.3f;  ent26 (32 boxes) under objective #8 %.3f;  gap %+.2f\n",
            f0$ll, ref_R0, f0$ll - ref_R0))


# ---- the frontier ------------------------------------------------------------
lo <- vapply(SO_ALL, function(n) log(SO_BOUNDS[[n]][1] / centre[[n]]), 0)
hi <- vapply(SO_ALL, function(n) log(SO_BOUNDS[[n]][2] / centre[[n]]), 0)
set_w <- function(W) assign("LIK_D14C_MID_NEFF", SO_NEFF_TRUE * W, envir = globalenv())
tgm_true <- ccx_mid_d14c_target(n_eff = SO_NEFF_TRUE)
st_R0 <- local({ set_w(1); v <- v0; p <- v0$p; p$hs_frac <- 0; v$p <- p; r <- dg_run(v); dg_streams(r, v) })
res <- list()
cat(sprintf("\n  %-4s %9s %9s %8s %8s %8s | %8s %7s %7s %7s %6s %7s %7s %7s\n", "W", "logL_true", "vs ent26", "z slabA", "z slabB", "z deep",
            "f", "z_K", "u_hs", "tau_q", "hs_asx", "kz", "h_ml", "sink"))
for (W in SO_W) {
  set_w(W)
  n_eval <- 0
  fn <- function(x) { n_eval <<- n_eval + 1; -ll_at(stats::setNames(x, SO_ALL))$ll }
  gr <- function(x) vapply(seq_along(x), function(i) { xp <- x; xm <- x; xp[i] <- x[i] + SO_GRAD_STEP; xm[i] <- x[i] - SO_GRAD_STEP
    (fn(xp) - fn(xm)) / (2 * SO_GRAD_STEP) }, 0)
  opt <- stats::optim(th0, fn, gr, method = "L-BFGS-B", lower = lo, upper = hi, control = list(maxit = SO_MAXIT, factr = 1e5))
  th <- stats::setNames(opt$par, SO_ALL)
  # re-score under the TRUE objective
  set_w(1); f_true <- ll_at(th)
  vals <- centre * exp(th)
  vv <- v0; pp <- base_p; for (n in SO_ALL) { if (n == "bomb_total") vv$bomb_total <- vals[[n]] else pp[[n]] <- vals[[n]] }
  vv$p <- pp; r1 <- dg_run(vv); sl <- ccx_model_d14c_slabs(r1$sp); tgd <- ccx_deep_d14c_target()
  zA <- (sl[1] - tgm_true$slabs$target[1]) / tgm_true$slabs$sd[1]; zB <- (sl[2] - tgm_true$slabs$target[2]) / tgm_true$slabs$sd[2]
  zD <- (r1$sp$diagnostics$d14c_bottom_box - tgd$target) / tgd$sd
  g7 <- dg_gate7(r1)
  res[[as.character(W)]] <- list(W = W, th = th, vals = vals, ll_true = f_true$ll, st = f_true$st, zA = zA, zB = zB, zD = zD,
                                 sink = g7$ocean, conv = opt$convergence, msg = opt$message, evals = n_eval)
  cat(sprintf("  %-4g %9.2f %+9.2f %+8.2f %+8.2f %+8.2f | %8.3f %7.0f %7.1f %7.0f %6.3f %7.0f %7.1f %6.2f   (conv %d, %d evals)\n",
              W, f_true$ll, f_true$ll - sum(st_R0), zA, zB, zD, vals[["kz_deep_frac"]], vals[["kz_zscale"]], vals[["u_hs"]],
              vals[["tau_q"]], vals[["hs_asx_frac"]], vals[["kz"]], vals[["h_ml"]], g7$ocean, opt$convergence, n_eval))
}
cat("\n  per-stream at each frontier point, TRUE objective, delta vs ent26:\n")
cat(sprintf("  %-22s %9s %s\n", "stream", "ent26", paste(sprintf("%9s", paste0("W", SO_W)), collapse = "")))
for (s in names(st_R0))
  cat(sprintf("  %-22s %9.2f %s\n", s, st_R0[[s]], paste(sprintf("%+9.2f", vapply(res, function(r) r$st[[s]] - st_R0[[s]], 0)), collapse = "")))
verdict <- function(ok) if (isTRUE(ok)) "PASS" else "FAIL"
inside <- vapply(res, function(r) abs(r$zA) < 1.5 && abs(r$zB) < 1.5, TRUE)
w10 <- res[["10"]]
first <- if (any(inside)) res[[which(inside)[1]]] else NULL
i15 <- inside[["10"]]
i16 <- !is.null(first) && (first$ll_true - sum(st_R0)) > -60
i17 <- !is.null(first) && first$vals[["tau_q"]] < 2000 && first$vals[["u_hs"]] > 15 && first$vals[["kz_deep_frac"]] < 0.5
pay <- if (!is.null(first)) { d <- first$st - st_R0; sort(d)[1:3] } else NULL
i18 <- !is.null(pay) && !any(grepl("co2_level", names(pay)[1]))
cat(sprintf("\n  I15 at W = 10 both slabs inside |z| < 1.5           : %s  (z %+.2f / %+.2f)\n", verdict(i15), w10$zA, w10$zB))
cat(sprintf("  I16 the PRICE at the first W that holds the profile : %s  (%s)\n", verdict(i16),
            if (is.null(first)) "no frontier point holds it" else sprintf("W %g: %+.1f vs ent26", first$W, first$ll_true - sum(st_R0))))
cat(sprintf("  I17 conduit alive and f < 0.5 there                 : %s  (%s)\n", verdict(i17),
            if (is.null(first)) "-" else sprintf("tau_q %.0f, u_hs %.1f, f %.3f", first$vals[["tau_q"]], first$vals[["u_hs"]], first$vals[["kz_deep_frac"]])))
cat(sprintf("  I18 the payers are bomb / pump d13C, not CO2 level  : %s  (%s)\n", verdict(i18),
            if (is.null(pay)) "-" else paste(sprintf("%s %+.1f", names(pay), pay), collapse = ", ")))
cat("  ⚠ W is a DEVICE to trace the frontier; every number above is re-scored under the TRUE objective. Nothing adopted.\n")
saveRDS(list(res = res, st_R0 = st_R0, centre = centre), SO_OUT); cat(sprintf("  saved %s\n", SO_OUT))
