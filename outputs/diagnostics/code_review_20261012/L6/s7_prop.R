for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
ccx_load_cpp()
D <- "outputs/mcmc_check_20261009_hilda29e_200k"
S <- readRDS(file.path(D, "chain_1.rds"))
cat("chain_1: iter", S$iter, " n_acc", S$n_acc, " n_acc_post", S$n_acc_post, " kept", nrow(S$samples), "\n")
cat("provenance commit", S$provenance$commit, " extended:", paste(sapply(S$provenance$extended, function(e) paste(e$from, e$to, e$commit)), collapse="; "), "\n")
md <- readRDS(ccx_mode_file()); invisible(ccx_apply_gate(ccx_mode_struct(md))); invisible(ccx_apply_pins(ccx_mode_pins(md)))
invisible(ccx_adopt_mode_band(md))
d <- length(CCX_PARAM_NAMES); sd_scale <- 2.38^2/d
Lp <- chol(sd_scale * S$C + sd_scale * S$provenance$eps * diag(d))
bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
lpf <- ccx_make_logpost(base_params = bp, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
set.seed(7)
U <- readRDS(file.path(D, "pooled_u_thin2.rds")); if (is.list(U) && !is.matrix(U)) U <- U$u
cat("pooled class", class(U), dim(U), "\n")
idx <- sample(nrow(U), 40)
res <- t(sapply(idx, function(i) { u <- U[i, ]; names(u) <- CCX_PARAM_NAMES
  l0 <- tryCatch(as.numeric(lpf(u)), error=function(e) NA)
  pr <- u + as.vector(rnorm(d) %*% Lp); names(pr) <- CCX_PARAM_NAMES
  w <- NULL
  l1 <- withCallingHandlers(tryCatch(as.numeric(lpf(pr)), error=function(e) {w <<- conditionMessage(e); NA}), warning=function(wn) invokeRestart("muffleWarning"))
  c(l0 = l0, l1 = l1) }))
cat("current lp finite:", sum(is.finite(res[,1])), "/", nrow(res), "\n")
cat("proposal lp finite:", sum(is.finite(res[,2])), "/", nrow(res), "; -Inf:", sum(res[,2] == -Inf, na.rm=TRUE), "; NA(error):", sum(is.na(res[,2])), "\n")
acc <- pmin(1, exp(res[,2] - res[,1])); cat("mean MH acceptance prob of these proposals:", round(mean(acc[is.finite(acc)]), 3), " (finite only); with -Inf as 0:", round(mean(ifelse(is.finite(res[,2]), acc, 0)), 3), "\n")
print(summary(res[,2] - res[,1]))
