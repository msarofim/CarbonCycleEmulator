for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
ccx_load_cpp()
D <- "outputs/mcmc_check_20261009_hilda29e_200k"
S <- readRDS(file.path(D, "chain_1.rds"))
md <- readRDS(ccx_mode_file()); invisible(ccx_apply_gate(ccx_mode_struct(md))); invisible(ccx_apply_pins(ccx_mode_pins(md)))
invisible(ccx_adopt_mode_band(md))
d <- length(CCX_PARAM_NAMES); sd_scale <- 2.38^2/d
Lp <- chol(sd_scale * S$C + sd_scale * S$provenance$eps * diag(d))
bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
lpf <- ccx_make_logpost(base_params = bp, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))
spfn <- ccx_spinup_from_label(ccx_mode_spinup(md))
set.seed(7)
U <- readRDS(file.path(D, "pooled_u_thin2.rds"))
idx <- sample(nrow(U), 40)
props <- lapply(idx, function(i) { u <- U[i, ]; pr <- u + as.vector(rnorm(d) %*% Lp); names(pr) <- CCX_PARAM_NAMES; pr })
why <- function(u) {
  pv <- ccx_unc_to_par(u); p_pr <- bp; for (n in names(pv)) p_pr[[n]] <- pv[[n]]
  lp <- 0; for (n in CCX_PARAM_NAMES) { s <- CCX_PARAM_TABLE[[n]]; lp <- lp + .ccx_prior_eval(s, pv[[n]], p_pr) + .log_jac(u[[n]], s) }
  if (!is.finite(lp)) return("prior -Inf")
  p <- bp; for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]; p <- ccx_set_enso(p, p_pr)
  sp <- tryCatch(spfn(p), error = function(e) e)
  if (inherits(sp, "error")) return(paste("spinup error:", conditionMessage(sp)))
  if (!is.finite(sp$prod_c14) || sp$prod_c14 <= 0) return("prod_c14 bad")
  if (!is.null(sp$periodic) && (!is.finite(sp$periodic$resid_carbon) || sp$periodic$resid_carbon >= PS_TOL)) return(sprintf("periodic not converged resid %.3g", sp$periodic$resid_carbon))
  "later (run NA / retried / loglik)"
}
for (k in seq_along(props)) { v <- tryCatch(as.numeric(lpf(props[[k]])), error=function(e) NA)
  if (!is.finite(v)) { pv <- ccx_unc_to_par(props[[k]]); cat(sprintf("prop %d: %s | h_ml %.2f kz %.0f k_w %.0f kz_deep_frac %.4f h_hs %.1f u_hs %.1f\n", k, why(props[[k]]), pv$h_ml, pv$kz, pv$k_w, pv$kz_deep_frac, pv$h_hs, pv$u_hs)) } }
