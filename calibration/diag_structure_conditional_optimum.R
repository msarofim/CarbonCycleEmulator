# =====================================================================
# diag_structure_conditional_optimum.R -- THE IDENTIFIABILITY CHECK, RE-RUN AT
# A CONDITIONAL OPTIMUM. Prereg notes/prereg_2026-09-06c_structure_identifiability.md
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
SO_MAXIT  <- 60
SO_I7_FRAC <- 0.5
SO_OUT <- ccx_path("outputs", "diagnostics", "structure_conditional_optimum_20260906.rds")

v0 <- dg_vector(CCX_MODE_CANONICAL)
base_p <- v0$p
for (n in names(SO_ARM)) base_p[[n]] <- SO_ARM[[n]]
base_p$h_hs <- base_p$h_ml
centre <- c(kz_deep_frac = base_p$kz_deep_frac, kz_zscale = base_p$kz_zscale, u_hs = base_p$u_hs,
            tau_q = base_p$tau_q, hs_asx_frac = base_p$hs_asx_frac, h_hs = base_p$h_hs,
            kz = base_p$kz, k_w = base_p$k_w, bomb_total = v0$bomb_total, h_ml = base_p$h_ml)
cat(sprintf("\n=== CONDITIONAL OPTIMUM of %d parameters at the 09-06b arm; mode %s ===\n",
            length(SO_ALL), CCX_MODE_CANONICAL))
cat(sprintf("  start: %s\n", paste(sprintf("%s %.4g", names(centre), centre), collapse = ", ")))

cache <- new.env()
ll_at <- function(theta) {          # theta: log-offsets from `centre`, named
  key <- paste(sprintf("%s=%.7f", names(theta), theta), collapse = ";")
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

# ---- optimize ----------------------------------------------------------------
lo <- vapply(SO_ALL, function(n) log(SO_BOUNDS[[n]][1] / centre[[n]]), 0)
hi <- vapply(SO_ALL, function(n) log(SO_BOUNDS[[n]][2] / centre[[n]]), 0)
n_eval <- 0
fn <- function(x) { n_eval <<- n_eval + 1; -ll_at(stats::setNames(x, SO_ALL))$ll }
gr <- function(x) vapply(seq_along(x), function(i) {
  xp <- x; xm <- x; xp[i] <- x[i] + SO_GRAD_STEP; xm[i] <- x[i] - SO_GRAD_STEP
  (fn(xp) - fn(xm)) / (2 * SO_GRAD_STEP) }, 0)
t0 <- Sys.time()
opt <- stats::optim(th0, fn, gr, method = "L-BFGS-B", lower = lo, upper = hi,
                    control = list(maxit = SO_MAXIT, factr = 1e5))
cat(sprintf("\n  L-BFGS-B: convergence %d (%s), %d iterations, %d evaluations, %.1f min\n",
            opt$convergence, opt$message, opt$counts[["function"]], n_eval,
            as.numeric(difftime(Sys.time(), t0, units = "mins"))))
th1 <- stats::setNames(opt$par, SO_ALL)
f1  <- ll_at(th1)
cat(sprintf("  logL %.3f -> %.3f  (%+.2f);  gap to ent26 now %+.2f\n", f0$ll, f1$ll, f1$ll - f0$ll, f1$ll - ref_R0))
cat("\n  parameter       start      optimum    x-fold   on bound?\n")
for (n in SO_ALL) {
  val <- centre[[n]] * exp(th1[[n]])
  onb <- if (abs(th1[[n]] - lo[[n]]) < 1e-3) "LOWER" else if (abs(th1[[n]] - hi[[n]]) < 1e-3) "UPPER" else ""
  cat(sprintf("  %-13s %9.4g  %11.4g  %7.3f   %s\n", n, centre[[n]], val, exp(th1[[n]]), onb))
}
cat("\n  per-stream, arm -> optimum (delta), and vs ent26 under objective #8:\n")
st_R0 <- local({ v <- v0; p <- v0$p; p$hs_frac <- 0; v$p <- p; r <- dg_run(v); dg_streams(r, v) })
for (s in names(f1$st))
  cat(sprintf("  %-22s %9.2f -> %9.2f  (%+8.2f)   vs ent26 %+8.2f\n", s, f0$st[[s]], f1$st[[s]],
              f1$st[[s]] - f0$st[[s]], f1$st[[s]] - st_R0[[s]]))
# the gates at the optimum
vv <- v0; pp <- base_p; for (n in SO_ALL) { val <- centre[[n]] * exp(th1[[n]]); if (n == "bomb_total") vv$bomb_total <- val else pp[[n]] <- val }
vv$p <- pp; r1 <- dg_run(vv)
g7 <- dg_gate7(r1); v7 <- dg_gate7_verdict(g7, dg_gcb_target(DG_SINK_WIN))
g5 <- dg_gate5(r1); v5 <- dg_gate5_verdict(g5, dg_obs_gate5(), dg_obs_gate5_spread())
slabs <- ccx_model_d14c_slabs(r1$sp); tgm <- ccx_mid_d14c_target()
cat(sprintf("\n  at the optimum: sink %.2f (gate 7 z %+.2f), NH peak year z %+.2f, deep %.1f, slabs %.1f / %.1f (z %+.2f / %+.2f)\n",
            g7$ocean, v7$z_ocean, v5$z[["nh_t"]], r1$sp$diagnostics$d14c_bottom_box, slabs[1], slabs[2],
            (slabs[1] - tgm$slabs$target[1]) / tgm$slabs$sd[1], (slabs[2] - tgm$slabs$target[2]) / tgm$slabs$sd[2]))
cat(sprintf("  HS %.1f  HD %.1f  LS ml %.1f permil\n", r1$sp$diagnostics$d14c_hs[["NH"]], r1$sp$diagnostics$d14c_hd[["NH"]],
            1000 * (r1$sp$y[r1$sp$aux$idx$NH$ml, "C14"] / r1$sp$y[r1$sp$aux$idx$NH$ml, "C"] - 1)))

# ---- Hessian at the optimum ------------------------------------------------
e  <- function(i, h) { t <- th1; t[[i]] <- t[[i]] + h; t }
e2 <- function(i, j, hi_, hj) { t <- th1; t[[i]] <- t[[i]] + hi_; t[[j]] <- t[[j]] + hj; t }
n <- length(SO_ALL); H <- matrix(NA_real_, n, n, dimnames = list(SO_ALL, SO_ALL))
grad <- stats::setNames(numeric(n), SO_ALL); stab <- list()
for (i in SO_ALL) {
  fp <- ll_at(e(i, SO_STEP))$ll; fm <- ll_at(e(i, -SO_STEP))$ll
  grad[[i]] <- (fp - fm) / (2 * SO_STEP); H[i, i] <- (fp - 2 * f1$ll + fm) / SO_STEP^2
  if (i %in% SO_NEW)
    stab[[i]] <- c(vapply(SO_STEPS_STAB[1], function(h) (ll_at(e(i, h))$ll - 2 * f1$ll + ll_at(e(i, -h))$ll) / h^2, 0),
                   H[i, i],
                   vapply(SO_STEPS_STAB[2], function(h) (ll_at(e(i, h))$ll - 2 * f1$ll + ll_at(e(i, -h))$ll) / h^2, 0))
}
for (a in seq_len(n - 1)) for (b in (a + 1):n) {
  i <- SO_ALL[a]; j <- SO_ALL[b]; h <- SO_STEP
  v <- (ll_at(e2(i, j, h, h))$ll - ll_at(e2(i, j, h, -h))$ll - ll_at(e2(i, j, -h, h))$ll + ll_at(e2(i, j, -h, -h))$ll) / (4 * h^2)
  H[i, j] <- v; H[j, i] <- v
}
NH <- (-H + t(-H)) / 2
ev <- eigen(NH, symmetric = TRUE); pd <- all(ev$values > 0)
cat(sprintf("\n  gradient at the optimum (should be ~0 off-bound): %s\n", paste(sprintf("%s %+.1f", SO_ALL, grad), collapse = ", ")))
cat(sprintf("  -H eigenvalues: %s   %s\n", paste(sprintf("%.3g", ev$values), collapse = " "), if (pd) "POSITIVE DEFINITE" else "NOT PD"))
NHr <- if (pd) NH else { vv_ <- ev$values; vv_[vv_ < max(vv_) * 1e-6] <- max(vv_) * 1e-6; ev$vectors %*% diag(vv_) %*% t(ev$vectors) }
Cov <- solve((NHr + t(NHr)) / 2); msd <- sqrt(diag(Cov)); names(msd) <- SO_ALL; Cor <- Cov / outer(msd, msd)
support <- stats::setNames(logical(n), SO_ALL)
cat("\n  parameter       cond sd   marginal sd   prior width   verdict\n")
for (i in SO_ALL) {
  csd <- if (H[i, i] < 0) 1 / sqrt(-H[i, i]) else Inf
  w <- if (i %in% names(SO_HILDA_W)) SO_HILDA_W[[i]] else NA
  support[[i]] <- is.finite(msd[[i]]) && msd[[i]] < SO_SD_SUPPORT && (is.na(w) || msd[[i]] < w)
  cat(sprintf("  %-13s %8.3f   %10.3f   %10s   %s\n", i, csd, msd[[i]], if (is.na(w)) "-" else sprintf("%.2f", w),
              if (i %in% SO_NEW) (if (support[[i]]) "DATA-SUPPORTED" else "declare") else "(existing)"))
}
cat("\n  correlation matrix (marginal):\n")
cat(sprintf("  %-13s %s\n", "", paste(sprintf("%7s", substr(SO_ALL, 1, 7)), collapse = "")))
for (i in SO_ALL) cat(sprintf("  %-13s %s\n", i, paste(sprintf("%+7.2f", Cor[i, ]), collapse = "")))
cat("\n  softest two directions of -H:\n")
for (k in c(n, n - 1)) { vec <- ev$vectors[, k]; o <- order(-abs(vec))[1:4]
  cat(sprintf("    eigenvalue %.3g : %s\n", ev$values[k], paste(sprintf("%s %+.2f", SO_ALL[o], vec[o]), collapse = ", "))) }
cat(sprintf("\n  MUTATION +/- %g (log) at the optimum: largest single-stream move\n", SO_MUT))
mut <- stats::setNames(numeric(n), SO_ALL)
for (i in SO_ALL) {
  d <- rbind(ll_at(e(i, SO_MUT))$st - f1$st, ll_at(e(i, -SO_MUT))$st - f1$st)
  j <- which.max(abs(d)); mut[[i]] <- abs(d)[j]
  cat(sprintf("  %-13s max |dlogL| %8.2f  on %-22s  %s\n", i, mut[[i]], colnames(d)[(j - 1) %/% 2 + 1],
              if (mut[[i]] >= SO_MUT_MIN) "has power" else "NO POWER"))
}

verdict <- function(ok) if (isTRUE(ok)) "PASS" else "FAIL"
csd_of <- function(i) if (H[i, i] < 0) 1 / sqrt(-H[i, i]) else Inf
soft <- ev$vectors[, n]; losoft <- SO_ALL[order(-abs(soft))[1:3]]
cn <- Cor[SO_NEW, SO_OLD]; imax <- which(abs(cn) == max(abs(cn)), arr.ind = TRUE)[1, ]
i1 <- mut[["h_hs"]] < SO_MUT_MIN && csd_of("h_hs") > 2
i2 <- support[["kz_deep_frac"]] && support[["hs_asx_frac"]]
i3 <- !support[["u_hs"]] && !support[["tau_q"]] && sum(losoft %in% c("u_hs", "tau_q", "hs_asx_frac")) >= 2
i4 <- is.finite(msd[["kz_zscale"]]) && msd[["kz_zscale"]] >= SO_SD_SUPPORT && msd[["kz_zscale"]] <= 2
i5 <- max(abs(cn)) > SO_COUPLING && SO_OLD[imax[[2]]] %in% c("k_w", "bomb_total")
i6 <- all(vapply(stab, function(s) all(abs(s / s[2] - 1) <= SO_STAB_TOL), TRUE))
i7 <- (f1$ll - ref_R0) > SO_I7_FRAC * (f0$ll - ref_R0)
i8 <- exp(th1[["hs_asx_frac"]]) < 1
i9 <- exp(th1[["k_w"]]) < 1 && exp(th1[["bomb_total"]]) > 1
i10 <- pd
cat(sprintf("\n  I1  h_hs has NO power                        : %s  (mut %.2f, cond sd %.2f)\n", verdict(i1), mut[["h_hs"]], csd_of("h_hs")))
cat(sprintf("  I2  ⭐ kz_deep_frac and hs_asx_frac supported  : %s  (msd %.3f / %.3f)\n", verdict(i2), msd[["kz_deep_frac"]], msd[["hs_asx_frac"]]))
cat(sprintf("  I3  u_hs / tau_q NOT separately supported     : %s  (msd %.3f / %.3f; softest %s)\n", verdict(i3), msd[["u_hs"]], msd[["tau_q"]], paste(losoft, collapse = ", ")))
cat(sprintf("  I4  kz_zscale weakly supported (0.5..2)      : %s  (msd %.3f)\n", verdict(i4), msd[["kz_zscale"]]))
cat(sprintf("  I5  strongest new-old coupling via k_w/bomb  : %s  (|r| %.2f, %s-%s)\n", verdict(i5), max(abs(cn)), SO_NEW[imax[[1]]], SO_OLD[imax[[2]]]))
cat(sprintf("  I6  curvatures step-stable                    : %s\n", verdict(i6)))
cat(sprintf("  I7  closes > %.0f%% of the gap to ent26          : %s  (gap %+.1f -> %+.1f)\n", 100 * SO_I7_FRAC, verdict(i7), f0$ll - ref_R0, f1$ll - ref_R0))
cat(sprintf("  I8  hs_asx_frac < 1                           : %s  (%.3f)\n", verdict(i8), exp(th1[["hs_asx_frac"]])))
cat(sprintf("  I9  k_w down, bomb_total up                   : %s  (x%.3f, x%.3f)\n", verdict(i9), exp(th1[["k_w"]]), exp(th1[["bomb_total"]])))
cat(sprintf("  I10 -H positive definite at the optimum       : %s\n", verdict(i10)))
cat(sprintf("\n  ⇒ DATA-SUPPORTED new parameters at the conditional optimum: %d of %d -- %s\n",
            sum(support[SO_NEW]), length(SO_NEW), if (any(support[SO_NEW])) paste(SO_NEW[support[SO_NEW]], collapse = ", ") else "none"))
cat("  ⚠ A conditional optimum of 10 with 16 held is NOT a mode. Nothing adopted.\n")
saveRDS(list(th_opt = th1, centre = centre, ll0 = f0$ll, ll1 = f1$ll, ref_R0 = ref_R0, st0 = f0$st, st1 = f1$st,
             st_R0 = st_R0, H = H, grad = grad, Cov = Cov, Cor = Cor, msd = msd, mut = mut, stab = stab, eig = ev,
             pd = pd, support = support, opt = opt, gates = list(g7 = g7, v7 = v7, g5 = g5, v5 = v5), slabs = slabs), SO_OUT)
cat(sprintf("  saved %s\n", SO_OUT))
