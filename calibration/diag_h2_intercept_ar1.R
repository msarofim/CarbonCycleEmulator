#!/usr/bin/env Rscript
# =====================================================================
# diag_h2_intercept_ar1.R -- H2's TWO SIGNATURES WITH ERROR BARS THAT ALLOW FOR AUTOCORRELATION
# (2026-10-21; Marcus: "Run the two H2 tests at hilda31w first".)
#
# THE TRIGGER. diag_h2_time_shape.R's M3 regresses the yearly ocean climate effect (CCX minus GCB 2025's
# GOBM ensemble mean) on the SST anomaly and reads two numbers: the per-K ratio (1.80 +/- 0.41 at hilda31w)
# and the gap's intercept at no warming (-0.062 +/- 0.036; H2 predicts ~0). Both +/- are OLS standard
# errors, which its log calls "a floor, the residuals are autocorrelated". A 1.7-sigma intercept on a floor
# se is not yet a finding (~/.claude/CLAUDE.md: a curvature/intercept needs an ERROR BAR before an
# explanation; validate an analytic se against a matched Monte Carlo).
#
# WHAT THIS DOES, on the STORED series (no model run):
#   GATE R  the OLS fit reproduces the stored m3 to 1e-12 (the series read is the one M3 used).
#   E1      OLS, Newey-West HAC (Bartlett, lags H2A_NW_LAGS), and GLS with AR(1) errors (nlme::gls), for the
#           gap's intercept and for each series' slope; the ratio's se by the delta method on each.
#   E2      a MATCHED Monte Carlo: AR(1) errors with the fitted rho and innovation sd on the same dsst, true
#           intercept 0 and the fitted slope; the OLS intercept's sd across draws is the se the data's
#           autocorrelation implies, and the share of draws with |a| >= |a_obs| is the two-sided p under H2.
#   POWER   what this test can and cannot separate: a constant offset vs a response that grows with warming.
#           It cannot separate H2 from any OTHER too-large per-K response; that is CHECK 4's job
#           (diag_ocean_climate_gobm.R: how the effect's share of the CO2 effect moves with kz).
# =====================================================================
suppressMessages(for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f))

H2A_DRIVER   <- "calibration/diag_h2_intercept_ar1.R"
H2A_IN       <- Sys.getenv("CCX_H2A_IN", file.path("outputs", "diagnostics", "h2_time_shape_20261013_hilda31w.rds"))
H2A_NW_LAGS  <- c(2L, 4L, 8L)              # Newey-West truncation lags reported (years)
H2A_MC_N     <- 20000L                     # Monte Carlo draws
H2A_SEED     <- 20261021L                  # set immediately before the Monte Carlo draws (E2)
H2A_GATE_TOL <- 1e-12
H2A_OUT      <- file.path("outputs", "diagnostics", sprintf("h2_intercept_ar1_%s_%s", format(Sys.Date(), "%Y%m%d"),
                                                          CCX_MODE_CANONICAL))
COMMIT <- ccx_git_stamp()

LOGCON <- file(paste0(H2A_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s | %s\n", H2A_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))
X <- readRDS(H2A_IN); pv <- X$provenance
cat(sprintf("input: %s (driver %s @%s, %s; CCX series %s, mode md5 %s)\n", H2A_IN, pv$driver, pv$commit, pv$date,
            pv$ccx, pv$ccx_mode_md5))
yrs <- X$years; ccx <- unname(X$ccx); gcb <- unname(X$gcb); dsst <- unname(X$dsst); gap <- ccx - gcb
n <- length(yrs)
cat(sprintf("%d years, %d-%d; units GtC/yr (uptake positive) against K of SST warming vs %s\n\n", n, min(yrs), max(yrs),
            "the record's first decade"))

# ---- GATE R ------------------------------------------------------------------------------------------------
ols <- function(y) stats::lm(y ~ dsst)
co  <- function(f) summary(f)$coefficients
f_g <- ols(gap); f_c <- ols(ccx); f_b <- ols(gcb)
stored <- X$m3[, c("a", "b", "a_se", "b_se")]
mine   <- rbind(ccx = c(co(f_c)[1, 1], co(f_c)[2, 1], co(f_c)[1, 2], co(f_c)[2, 2]),
                gcb = c(co(f_b)[1, 1], co(f_b)[2, 1], co(f_b)[1, 2], co(f_b)[2, 2]),
                gap = c(co(f_g)[1, 1], co(f_g)[2, 1], co(f_g)[1, 2], co(f_g)[2, 2]))
dR <- max(abs(mine - stored))
cat(sprintf("GATE R: OLS reproduces the stored M3 (max |diff| %.1e, tol %.0e) -> %s\n", dR, H2A_GATE_TOL,
            if (dR <= H2A_GATE_TOL) "PASS" else "FAIL"))
if (dR > H2A_GATE_TOL) stop("GATE R failed: the series is not the one M3 used")

# ---- E1 three estimators -----------------------------------------------------------------------------------
rho_of <- function(f) { e <- stats::residuals(f); sum(e[-1] * e[-n]) / sum(e^2) }
nw_se  <- function(f, L) sqrt(diag(sandwich::NeweyWest(f, lag = L, prewhite = FALSE, adjust = TRUE)))
gls1   <- function(y) { d <- data.frame(y = y, x = dsst, t = seq_len(n))
  g <- nlme::gls(y ~ x, data = d, correlation = nlme::corAR1(form = ~ t), method = "ML")
  s <- summary(g)$tTable
  c(a = s[1, 1], a_se = s[1, 2], b = s[2, 1], b_se = s[2, 2],
    phi = unname(stats::coef(g$modelStruct$corStruct, unconstrained = FALSE))) }
est <- function(nm, y, f) {
  rows <- list(data.frame(series = nm, method = "OLS", a = co(f)[1, 1], a_se = co(f)[1, 2], b = co(f)[2, 1], b_se = co(f)[2, 2]))
  for (L in H2A_NW_LAGS) { s <- nw_se(f, L)
    rows[[length(rows) + 1]] <- data.frame(series = nm, method = sprintf("Newey-West L=%d", L), a = co(f)[1, 1], a_se = s[[1]],
                                           b = co(f)[2, 1], b_se = s[[2]]) }
  g <- gls1(y)
  rows[[length(rows) + 1]] <- data.frame(series = nm, method = sprintf("GLS AR(1), phi %.2f", g[["phi"]]), a = g[["a"]],
                                         a_se = g[["a_se"]], b = g[["b"]], b_se = g[["b_se"]])
  do.call(rbind, rows) }
E1 <- rbind(est("gap", gap, f_g), est("ccx", ccx, f_c), est("gcb", gcb, f_b))
cat("\n=== E1. INTERCEPT a (GtC/yr at no warming) AND SLOPE b (GtC/yr per K), three estimators ===\n")
cat(sprintf("  OLS residual lag-1 autocorrelation: gap %.2f, ccx %.2f, gcb %.2f\n", rho_of(f_g), rho_of(f_c), rho_of(f_b)))
E1$a_z <- E1$a / E1$a_se
print(transform(E1, a = round(a, 4), a_se = round(a_se, 4), b = round(b, 4), b_se = round(b_se, 4), a_z = round(a_z, 2)),
      row.names = FALSE)
cat("  the per-K ratio CCX / GCB (delta method on each method's slope se):\n")
for (m in unique(E1$method[E1$series == "gap"])) {
  mm <- if (startsWith(m, "GLS")) "^GLS" else paste0("^", gsub("([()=])", "\\\\\\1", m), "$")
  rc <- E1[E1$series == "ccx" & grepl(mm, E1$method), ]; rb <- E1[E1$series == "gcb" & grepl(mm, E1$method), ]
  r <- rc$b / rb$b; rse <- abs(r) * sqrt((rc$b_se / rc$b)^2 + (rb$b_se / rb$b)^2)
  cat(sprintf("    %-22s %.2f +/- %.2f\n", sub(",.*", "", m), r, rse)) }

# ---- E2 matched Monte Carlo --------------------------------------------------------------------------------
e   <- stats::residuals(f_g); rho <- rho_of(f_g)
sdi <- stats::sd(e) * sqrt(1 - rho^2)                     # AR(1) innovation sd giving the residuals' marginal sd
b0  <- co(f_g)[2, 1]
set.seed(H2A_SEED)                                         # immediately before the draws
ahat <- vapply(seq_len(H2A_MC_N), function(i) {
  u <- numeric(n); u[1] <- stats::rnorm(1, 0, stats::sd(e))
  z <- stats::rnorm(n - 1L, 0, sdi)
  for (k in 2:n) u[k] <- rho * u[k - 1L] + z[k - 1L]
  stats::coef(stats::lm.fit(cbind(1, dsst), b0 * dsst + u))[[1]] }, numeric(1))
a_obs <- co(f_g)[1, 1]
mc_se <- stats::sd(ahat); mc_p <- mean(abs(ahat) >= abs(a_obs))
cat(sprintf("\n=== E2. MATCHED MONTE CARLO (gap; AR(1) rho %.2f, innovation sd %.4f; true a = 0, b = %.4f; %d draws, seed %d) ===\n",
            rho, sdi, b0, H2A_MC_N, H2A_SEED))
cat(sprintf("  the OLS intercept's sd across draws: %.4f GtC/yr (OLS's own se %.4f: %.2fx too small)\n", mc_se,
            co(f_g)[1, 2], mc_se / co(f_g)[1, 2]))
cat(sprintf("  observed a = %.4f -> %.2f MC sd; two-sided p under H2 (a = 0) = %.3f\n", a_obs, a_obs / mc_se, mc_p))
cat(sprintf("  ⚠ the MC takes rho from the OLS residuals, which bias it LOW at n = %d; the GLS phi row is the check\n", n))

# ---- POWER -------------------------------------------------------------------------------------------------
cat("\n=== POWER: what the intercept can separate ===\n")
cat(sprintf("  with the MC se, a constant offset of |a| >= %.3f GtC/yr would be detected at 2 sd; the GCB 2015-24 effect is -0.20.\n",
            2 * mc_se))
cat("  ⚠ It separates a CONSTANT OFFSET from a response that GROWS WITH WARMING. Any too-large per-K response predicts\n",
    "   a = 0, so a = 0 cannot tell H2 (mixing defeats the surface's adjustment) from another cause of a too-large response.\n", sep = "")

out <- list(E1 = E1, mc = list(se = mc_se, p = mc_p, rho = rho, innov_sd = sdi, n = H2A_MC_N, draws_summary = stats::quantile(ahat, c(.025, .5, .975))),
            gateR = dR,
            provenance = list(driver = H2A_DRIVER, commit = COMMIT, input = H2A_IN, input_provenance = pv,
                              seed = H2A_SEED, seed_applied = "set.seed() immediately before the Monte Carlo draws (E2)",
                              nw_lags = H2A_NW_LAGS, units = "GtC/yr (uptake positive); per K of SST vs 1959-68",
                              date = format(Sys.time(), "%Y-%m-%d %H:%M")))
saveRDS(out, paste0(H2A_OUT, ".rds"))
cat(sprintf("\nwrote %s.{log,rds}\n", H2A_OUT))
sink(); close(LOGCON)
