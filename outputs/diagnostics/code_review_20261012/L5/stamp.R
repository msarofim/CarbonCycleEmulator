setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
source("R/aaa_root.R"); source("R/provenance.R")
s <- ccx_git_stamp(); cat("stamp:", s, " dirty:", ccx_stamp_dirty(s), "\n")
# exclude with an absolute path
cat("excl abs:", ccx_git_stamp(exclude = ccx_path("data","futures_ribbons.rds")), "\n")
# exclude a path containing a space / glob char
cat("excl glob-ish:", ccx_git_stamp(exclude = "data/*.rds"), "\n")
# stamp_dirty on edge strings
for (x in c("abc1234", "abc1234+dirty", "abc1234+dirty?", "abc1234+frozen?", "?")) cat(x, "->", ccx_stamp_dirty(x), "\n")
# importance diagnostics small checks
source("R/importance.R")
set.seed(1); lw <- rnorm(1000)
d <- ccx_is_diagnostics(lw); cat(sprintf("normal lw: ess %.1f khat %.3f klim %.3f ok %s\n", d$ess, d$k_hat, d$k_ok_below, d$k_ok))
d <- ccx_is_diagnostics(c(rep(0,999), 50)); cat(sprintf("one-dominant: ess %.3f khat %s ok %s\n", d$ess, d$k_hat, d$k_ok))
d <- ccx_is_diagnostics(rep(0, 1000)); cat(sprintf("all-equal: ess %.1f khat %s ok %s\n", d$ess, d$k_hat, d$k_ok))
d <- ccx_is_diagnostics(c(rnorm(10))); cat(sprintf("S=10: khat %s klim %s ok %s\n", d$k_hat, d$k_ok_below, d$k_ok))
d <- tryCatch(ccx_is_diagnostics(c(rnorm(4))), error=function(e) conditionMessage(e)); print(d)
print(ccx_wquantile(1:10, rep(1,10), c(0.05, 0.5, 0.95))); print(quantile(1:10, c(.05,.5,.95)))
