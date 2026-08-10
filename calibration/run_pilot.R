# Pilot calibration: short chains to check mixing, acceptance and R-hat before
# committing to a production run. NOT a posterior for reporting.
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
N_ITER <- 1500; N_CHAINS <- 4; SEED <- 2026
cat(sprintf("pilot: %d iters x %d chains, seed %d\n", N_ITER, N_CHAINS, SEED))
t0 <- Sys.time()
fit <- ccx_run_mcmc(n_iter = N_ITER, n_chains = N_CHAINS, seed = SEED)
cat(sprintf("elapsed: %.1f min\n", as.numeric(difftime(Sys.time(), t0, units = "mins"))))
saveRDS(fit, "calibration/output/pilot_fit.rds")
cat("acceptance rates:", sprintf("%.3f", sapply(fit$chains, function(c) c$acceptance.rate)), "\n")
