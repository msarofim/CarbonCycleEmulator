for (f in list.files("R", pattern="\\.R$", full.names=TRUE)) source(f)
cat("adaptMCMC installed:", requireNamespace("adaptMCMC", quietly=TRUE), "\n")
r <- tryCatch(ccx_run_mcmc(n_iter = 4, n_chains = 1), error = function(e) conditionMessage(e))
cat("ccx_run_mcmc() at the canonical, default args:\n"); print(if (is.character(r)) substr(r, 1, 600) else names(r))
# with gate+pins applied by the caller (what run_mcmc_check.R does), does it start from the table inits?
md <- readRDS(ccx_mode_file()); invisible(ccx_apply_gate(ccx_mode_struct(md))); invisible(ccx_apply_pins(ccx_mode_pins(md)))
init <- ccx_init_unc(); cat("\nccx_init_unc() names == fitted names:", identical(names(init), CCX_PARAM_NAMES), " length", length(init), "\n")
print(round(init - ccx_par_to_unc(md$par_mode), 2))
