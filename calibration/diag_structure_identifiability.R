# =====================================================================
# diag_structure_identifiability.R -- HOW MANY OF THE STRUCTURE'S PARAMETERS
# CAN THE DATA AFFORD? A local curvature check before the refit is designed.
#
# Pre-registered in notes/prereg_2026-09-06c_structure_identifiability.md.
# Central-difference Hessian of the LIKELIHOOD (no priors; objective change #8
# included) in ten log-parameters at the 09-06b working arm, plus a mutation
# check per parameter. Reports conditional and marginal sds, the correlation
# matrix, the softest directions, and the pre-declared affordability count.
#
# ⚠ The base point is NOT an optimum of this objective, so the curvature is a
# LOCAL statement about the data's leverage, not a posterior. The gradient is
# printed so the reader can see how far from an optimum it sits.
#
# Usage:  Rscript calibration/diag_structure_identifiability.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))

# ---- named constants ---------------------------------------------------
SI_STEP        <- 0.05                  # log step for the Hessian
SI_STEPS_STAB  <- c(0.025, 0.1)         # diagonal step-stability checks (new params)
SI_STAB_TOL    <- 0.25                  # prereg I6: agreement within 25 %
SI_MUT         <- 0.5                   # mutation size, log
SI_MUT_MIN     <- 2                     # log-units a mutation must move some stream
SI_SD_SUPPORT  <- 0.5                   # prereg: data-supported if marginal sd (log) < this
SI_COUPLING    <- 0.5                   # prereg I5: |r| threshold
SI_HILDA_W     <- c(u_hs = 17 / 38, tau_q = 510 / 538)   # one-remove prior widths, log-approx
SI_NEW <- c("kz_deep_frac", "kz_zscale", "u_hs", "tau_q", "hs_asx_frac", "h_hs")
SI_OLD <- c("kz", "k_w", "bomb_total", "h_ml")
SI_ALL <- c(SI_NEW, SI_OLD)
SI_ARM <- list(hs_frac = 0.16, u_hs = 38, tau_q = 538, sst_hs = 2, q_attach_from = 10,
               kz_zscale = 253, kz_deep_frac = 0.166, hs_asx_frac = 1)
SI_OUT <- ccx_path("outputs", "diagnostics", "structure_identifiability_20260906.rds")

v0 <- dg_vector(CCX_MODE_CANONICAL)
base_p <- v0$p
for (n in names(SI_ARM)) base_p[[n]] <- SI_ARM[[n]]
base_p$h_hs <- base_p$h_ml                     # explicit, so it can be varied
centre <- c(kz_deep_frac = base_p$kz_deep_frac, kz_zscale = base_p$kz_zscale,
            u_hs = base_p$u_hs, tau_q = base_p$tau_q, hs_asx_frac = base_p$hs_asx_frac,
            h_hs = base_p$h_hs, kz = base_p$kz, k_w = base_p$k_w,
            bomb_total = v0$bomb_total, h_ml = base_p$h_ml)
cat(sprintf("\n=== STRUCTURE IDENTIFIABILITY -- mode %s, arm: %s ===\n", CCX_MODE_CANONICAL,
            paste(sprintf("%s %g", names(SI_ARM), unlist(SI_ARM)), collapse = ", ")))
cat(sprintf("  centre: %s\n", paste(sprintf("%s %.4g", names(centre), centre), collapse = ", ")))
cat(sprintf("  step %g (log); mutation %g; support if marginal sd < %g\n", SI_STEP, SI_MUT, SI_SD_SUPPORT))

# ---- evaluation, memoized on the log-offset vector ---------------------
cache <- new.env()
ll_at <- function(theta) {
  key <- paste(sprintf("%s=%.6f", names(theta), theta), collapse = ";")
  if (!is.null(cache[[key]])) return(cache[[key]])
  p <- base_p; v <- v0
  for (n in names(theta)) {
    val <- centre[[n]] * exp(theta[[n]])
    if (n == "bomb_total") v$bomb_total <- val else p[[n]] <- val
  }
  v$p <- p
  r  <- dg_run(v); st <- dg_streams(r, v)
  res <- list(ll = sum(st), st = st)
  cache[[key]] <- res
  res
}
th0 <- stats::setNames(rep(0, length(SI_ALL)), SI_ALL)
e   <- function(i, h) { t <- th0; t[[i]] <- h; t }
e2  <- function(i, j, hi, hj) { t <- th0; t[[i]] <- hi; t[[j]] <- hj; t }
f0  <- ll_at(th0)
cat(sprintf("  base log-likelihood %.3f  (streams: %d)\n", f0$ll, length(f0$st)))

# ---- gradient and diagonal ------------------------------------------------
n <- length(SI_ALL); H <- matrix(NA_real_, n, n, dimnames = list(SI_ALL, SI_ALL))
grad <- stats::setNames(numeric(n), SI_ALL)
for (i in SI_ALL) {
  fp <- ll_at(e(i, SI_STEP))$ll; fm <- ll_at(e(i, -SI_STEP))$ll
  grad[[i]] <- (fp - fm) / (2 * SI_STEP)
  H[i, i]   <- (fp - 2 * f0$ll + fm) / SI_STEP^2
}
cat("\n  gradient (d logL / d log-param) and conditional sd 1/sqrt(-H_ii):\n")
stab <- list()
for (i in SI_ALL) {
  csd <- if (H[i, i] < 0) 1 / sqrt(-H[i, i]) else Inf
  line <- sprintf("  %-13s grad %+9.2f   H_ii %+10.2f   cond sd %7.3f", i, grad[[i]], H[i, i], csd)
  if (i %in% SI_NEW) {
    hs <- vapply(SI_STEPS_STAB, function(h) (ll_at(e(i, h))$ll - 2 * f0$ll + ll_at(e(i, -h))$ll) / h^2, 0)
    stab[[i]] <- c(hs[1], H[i, i], hs[2])
    line <- paste0(line, sprintf("   H_ii at steps %s: %s", paste(c(SI_STEPS_STAB[1], SI_STEP, SI_STEPS_STAB[2]), collapse = "/"),
                                 paste(sprintf("%+.2f", stab[[i]]), collapse = " / ")))
  }
  cat(line, "\n")
}

# ---- off-diagonals ---------------------------------------------------------
for (a in seq_len(n - 1)) for (b in (a + 1):n) {
  i <- SI_ALL[a]; j <- SI_ALL[b]; h <- SI_STEP
  v <- (ll_at(e2(i, j, h, h))$ll - ll_at(e2(i, j, h, -h))$ll -
        ll_at(e2(i, j, -h, h))$ll + ll_at(e2(i, j, -h, -h))$ll) / (4 * h^2)
  H[i, j] <- v; H[j, i] <- v
}
NH <- -H
ev <- eigen((NH + t(NH)) / 2, symmetric = TRUE)
pd <- all(ev$values > 0)
cat(sprintf("\n  -H eigenvalues: %s   %s\n", paste(sprintf("%.3g", ev$values), collapse = " "),
            if (pd) "POSITIVE DEFINITE" else "NOT PD -- marginal sds below are from a REGULARISED matrix"))
NHr <- if (pd) NH else { vv <- ev$values; vv[vv < max(vv) * 1e-6] <- max(vv) * 1e-6
                         ev$vectors %*% diag(vv) %*% t(ev$vectors) }
Cov <- solve((NHr + t(NHr)) / 2)
msd <- sqrt(diag(Cov)); names(msd) <- SI_ALL
Cor <- Cov / outer(msd, msd)
cat("\n  parameter       cond sd   marginal sd   prior width   verdict\n")
support <- stats::setNames(logical(n), SI_ALL)
for (i in SI_ALL) {
  csd <- if (H[i, i] < 0) 1 / sqrt(-H[i, i]) else Inf
  w <- if (i %in% names(SI_HILDA_W)) SI_HILDA_W[[i]] else NA
  ok <- is.finite(msd[[i]]) && msd[[i]] < SI_SD_SUPPORT && (is.na(w) || msd[[i]] < w)
  support[[i]] <- ok
  cat(sprintf("  %-13s %8.3f   %10.3f   %10s   %s\n", i, csd, msd[[i]],
              if (is.na(w)) "-" else sprintf("%.2f", w),
              if (i %in% SI_NEW) (if (ok) "DATA-SUPPORTED" else "declare") else "(existing)"))
}
cat("\n  correlation matrix (marginal):\n")
cat(sprintf("  %-13s %s\n", "", paste(sprintf("%7s", substr(SI_ALL, 1, 7)), collapse = "")))
for (i in SI_ALL) cat(sprintf("  %-13s %s\n", i, paste(sprintf("%+7.2f", Cor[i, ]), collapse = "")))
cat("\n  softest two directions of -H (eigenvectors, largest loadings):\n")
for (k in c(n, n - 1)) {
  vec <- ev$vectors[, k]; o <- order(-abs(vec))[1:4]
  cat(sprintf("    eigenvalue %.3g : %s\n", ev$values[k],
              paste(sprintf("%s %+.2f", SI_ALL[o], vec[o]), collapse = ", ")))
}

# ---- mutation: does each parameter move ANY observed stream? --------------
cat(sprintf("\n  MUTATION +/- %g (log): largest single-stream move\n", SI_MUT))
mut <- stats::setNames(numeric(n), SI_ALL); mut_stream <- character(n); names(mut_stream) <- SI_ALL
for (i in SI_ALL) {
  d <- rbind(ll_at(e(i, SI_MUT))$st - f0$st, ll_at(e(i, -SI_MUT))$st - f0$st)
  j <- which.max(abs(d)); mut[[i]] <- abs(d)[j]; mut_stream[[i]] <- colnames(d)[(j - 1) %/% 2 + 1]
  cat(sprintf("  %-13s max |dlogL| %8.2f  on %-22s  %s\n", i, mut[[i]], mut_stream[[i]],
              if (mut[[i]] >= SI_MUT_MIN) "has power" else "NO POWER"))
}

# ---- verdicts -----------------------------------------------------------------
verdict <- function(ok) if (isTRUE(ok)) "PASS" else "FAIL"
csd_of <- function(i) if (H[i, i] < 0) 1 / sqrt(-H[i, i]) else Inf
i1 <- mut[["h_hs"]] < SI_MUT_MIN && csd_of("h_hs") > 2
i2 <- support[["kz_deep_frac"]] && support[["hs_asx_frac"]]
soft <- ev$vectors[, n]; lo <- SI_ALL[order(-abs(soft))[1:3]]
i3 <- !support[["u_hs"]] && !support[["tau_q"]] && sum(lo %in% c("u_hs", "tau_q", "hs_asx_frac")) >= 2
i4 <- is.finite(msd[["kz_zscale"]]) && msd[["kz_zscale"]] >= SI_SD_SUPPORT && msd[["kz_zscale"]] <= 2
cn <- Cor[SI_NEW, SI_OLD]; strongest <- SI_OLD[apply(abs(cn), 1, which.max)]; names(strongest) <- SI_NEW
i5 <- max(abs(cn)) > SI_COUPLING && SI_OLD[which(abs(cn) == max(abs(cn)), arr.ind = TRUE)[1, 2]] %in% c("k_w", "bomb_total")
i6 <- all(vapply(stab, function(s) all(abs(s / s[2] - 1) <= SI_STAB_TOL), TRUE))
n_support <- sum(support[SI_NEW])
cat(sprintf("\n  I1  h_hs has NO power                        : %s  (mut %.2f, cond sd %.2f)\n", verdict(i1), mut[["h_hs"]], csd_of("h_hs")))
cat(sprintf("  I2  ⭐ kz_deep_frac and hs_asx_frac supported  : %s  (msd %.3f / %.3f)\n", verdict(i2), msd[["kz_deep_frac"]], msd[["hs_asx_frac"]]))
cat(sprintf("  I3  u_hs / tau_q NOT separately supported     : %s  (msd %.3f / %.3f vs widths %.2f / %.2f; softest: %s)\n",
            verdict(i3), msd[["u_hs"]], msd[["tau_q"]], SI_HILDA_W[["u_hs"]], SI_HILDA_W[["tau_q"]], paste(lo, collapse = ", ")))
cat(sprintf("  I4  kz_zscale weakly supported (0.5..2)      : %s  (msd %.3f)\n", verdict(i4), msd[["kz_zscale"]]))
cat(sprintf("  I5  strongest new-old coupling via k_w/bomb  : %s  (max |r| %.2f; per new param: %s)\n", verdict(i5), max(abs(cn)),
            paste(sprintf("%s->%s", SI_NEW, strongest), collapse = ", ")))
cat(sprintf("  I6  new-parameter curvatures step-stable      : %s\n", verdict(i6)))
cat(sprintf("\n  ⇒ DATA-SUPPORTED new parameters: %d of %d -- %s\n", n_support, length(SI_NEW),
            if (n_support) paste(SI_NEW[support[SI_NEW]], collapse = ", ") else "none"))
cat("  ⚠ Local curvature at a NON-optimum, matched parameters, no priors. Nothing adopted.\n")
saveRDS(list(H = H, grad = grad, Cov = Cov, Cor = Cor, msd = msd, mut = mut, mut_stream = mut_stream,
             stab = stab, eig = ev, support = support, centre = centre, base_ll = f0$ll, streams = f0$st,
             step = SI_STEP, pd = pd), SI_OUT)
cat(sprintf("  saved %s\n", SI_OUT))
