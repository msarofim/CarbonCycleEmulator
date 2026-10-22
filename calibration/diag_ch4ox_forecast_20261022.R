# =====================================================================
# diag_ch4ox_forecast_20261022.R -- what does the CO2 from oxidised FUGITIVE FOSSIL METHANE do to the canonical?
# Marcus 2026-10-22: "Do the cheap tests for both methane and CFC."
#
# THE FACT BEING PRICED. GCB's fossil CO2 (E_FOS, which CCX burns) counts CO from incomplete combustion and vented
# methane from oil production, but NOT fugitive CH4 from coal, oil and gas. GCB 2025 supplement S.8.1 (p. 27 of
# data-raw/downloads/gcb2025_supplement.pdf) puts the CO2 from its oxidation at 0.083 GtC/yr for 2008-2017
# (min-max 0.061-0.098), from Saunois et al. 2020's top-down fossil CH4.
#
# THE ARM (a stated assumption, not data). The missing source is added as fossil CO2 PROPORTIONAL to E_FOS:
# e_foss x (1 + r), with r = 0.083 / mean E_FOS 2008-2017 of the model's own input. So it
#   * has the history of fossil CO2 (no fossil CH4 emission history is used),
#   * is oxidised INSTANTLY (the ~decade CH4 lifetime is ignored),
#   * carries the fossil-fuel d13C and no 14C. Fossil CH4 is more 13C-depleted than fuel CO2, so the arm
#     UNDERSTATES the d13C effect; the 14C effect is exact for a 14C-free source.
#
# METHOD (no refit, no RNG), T8f's:
#   1. GATE R1: the objective rebuilt here reproduces the mode's stored logpost; GATE W: the wrapper at r = 0 is the
#      identity, and at r > 0 it moves the objective (a mutation test of the injection itself);
#   2. every row at the canonical, with and without the source, at r for the GCB central value and its min/max;
#   3. physical outputs at the canonical: CO2, d13C, D14C in the last year;
#   4. the gradient of the objective with and without the source, by central differences at md$hess_eps;
#   5. one Newton step on the stored Hessian over all 31 names, evaluated at steps 1 and 0.5.
#
# Usage: Rscript calibration/diag_ch4ox_forecast_20261022.R > outputs/diagnostics/ch4ox_20261022_<mode>/ch4ox_forecast_<mode>.log
# =====================================================================
for (.lf in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(.lf)
ccx_load_cpp()

CH4_DRIVER   <- "calibration/diag_ch4ox_forecast_20261022.R"
CH4_COMMIT   <- ccx_git_stamp()
CH4_MODE     <- CCX_MODE_CANONICAL
CH4_YEARS    <- c(1750, 2024)                         # the objective's span (ccx_make_logpost default)
CH4_OUT_DIR  <- file.path("outputs", "diagnostics", sprintf("ch4ox_20261022_%s", CH4_MODE))
CH4_STEM     <- file.path(CH4_OUT_DIR, sprintf("ch4ox_forecast_%s", CH4_MODE))
CH4_GCB_FILE <- file.path("data-raw", "downloads", "gcb2025_global_budget.csv")
CH4_SRC      <- "GCB 2025 supplement S.8.1 (p. 27): fossil CH4 oxidation, 2008-2017, from Saunois et al. 2020 top-down"
CH4_OX_GTC   <- c(central = 0.083, min = 0.061, max = 0.098)   # GtC/yr, the supplement's numbers
CH4_REF_YRS  <- 2008:2017                             # the supplement's decade
CH4_NEWTON_STEPS <- c(1, 0.5)
CH4_LARGE_SD <- 2                                     # a forecast move beyond this (posterior sd) is flagged
CH4_READ_YEAR <- CH4_YEARS[2]                         # physical outputs read in this year
say <- function(...) { cat(sprintf(...)); flush.console() }
dir.create(CH4_OUT_DIR, showWarnings = FALSE, recursive = TRUE)
say("=== %s @%s, %s ===\n", CH4_DRIVER, CH4_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"))

# ---- the canonical's objective, gated (test-flask-label.R's fl_score / lib_seas8's s8_setup sequence) ----
md <- readRDS(ccx_mode_file(CH4_MODE))
invisible(ccx_apply_gate(ccx_mode_struct(md)))
invisible(ccx_apply_pins(ccx_mode_pins(md)))
ccx_require_param_set(md, CH4_DRIVER)
invisible(ccx_adopt_mode_band(md))
ccx_check_mode_decode(md)
spf <- ccx_spinup_from_label(ccx_mode_spinup(md))
bp0 <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp0$pump_mode <- md$pump_mode
P  <- md$param_names
u0 <- unlist(ccx_par_to_unc(md$par_mode[CCX_PARAM_NAMES]))[CCX_PARAM_NAMES]
if (!identical(names(u0), P)) stop("the fitted names are not the mode file's")

# ---- THE INJECTION: ccx_run_fast() with the fossil columns scaled by (1 + CH4_R) ----
# The objective calls ccx_run_fast(sp, F) by name, so replacing it in the global environment reaches every
# scored run; the spinup (fossil = 0 in 1750) never calls it. CH4_CALLS counts the wrapper's use.
.ccx_run_fast_orig <- ccx_run_fast
CH4_R <- 0; CH4_CALLS <- 0L
ccx_run_fast <- function(spin, F, ...) {
  CH4_CALLS <<- CH4_CALLS + 1L
  if (CH4_R != 0) { F$e_foss_NH <- F$e_foss_NH * (1 + CH4_R); F$e_foss_SH <- F$e_foss_SH * (1 + CH4_R) }
  .ccx_run_fast_orig(spin, F, ...)
}
lp <- ccx_make_logpost(base_params = bp0, by_stream = TRUE, spinup_fn = spf)
score <- function(u, r) {
  CH4_R <<- r; on.exit(CH4_R <<- 0)
  v <- lp(u)
  list(v = as.numeric(v), rows = c(unlist(attr(v, "streams")), logprior = attr(v, "logprior")))
}

say("\n=== 1. GATES ===\n")
n0 <- CH4_CALLS; s0 <- score(u0, 0)
d0 <- s0$v - md$logpost
say("GATE R1: the objective rebuilt here scores the mode %.6f vs stored %.6f (diff %.2e, tol %g) -> %s\n",
    s0$v, md$logpost, d0, CCX_REPRO_TOL, if (abs(d0) <= CCX_REPRO_TOL) "PASS" else "FAIL")
if (!(abs(d0) <= CCX_REPRO_TOL)) stop("the canonical objective does not reproduce its mode")
if (CH4_CALLS == n0) stop("GATE W: the objective never called the wrapped ccx_run_fast()")

# r from the model's OWN fossil input, and the GCB file as a cross-check
L0  <- ccx_load_mode(CH4_MODE)                       # the canonical's run list (lib_seas8's s8_run path)
sp0 <- spf(L0$p)
F0  <- ccx_scaled_forcing(sp0, CH4_YEARS, luc_scale = L0$luc_scale, bomb_total = L0$bomb_total)$F
yr  <- floor(F0$t); k <- yr %in% CH4_REF_YRS
efos_ref <- mean(F0$e_foss_NH[k] + F0$e_foss_SH[k])
gcb <- utils::read.csv(CH4_GCB_FILE, comment.char = "#", check.names = FALSE)
efos_gcb <- mean(gcb[gcb$Year %in% CH4_REF_YRS, "fossil emissions excluding carbonation"])
R <- CH4_OX_GTC / efos_ref
say("E_FOS %d-%d: model input %.4f GtC/yr, GCB file %.4f (diff %+.4f) -> r = %s\n",
    min(CH4_REF_YRS), max(CH4_REF_YRS), efos_ref, efos_gcb, efos_ref - efos_gcb,
    paste(sprintf("%s %.5f", names(R), R), collapse = ", "))
cum_add <- R[["central"]] * sum(F0$e_foss_NH + F0$e_foss_SH) / 12
say("  cumulative source added %d-%d at the central r: %.2f GtC (%.2f ppm emitted)\n",
    CH4_YEARS[1], CH4_YEARS[2], cum_add, cum_add / ccx_const("GtC_PER_PPM"))
sW <- score(u0, R[["central"]])
say("GATE W (mutation): the wrapper at r = %.5f moves the objective by %+.4f -> %s\n",
    R[["central"]], sW$v - s0$v, if (abs(sW$v - s0$v) > CCX_REPRO_TOL) "PASS (live)" else "FAIL (dead)")
if (!(abs(sW$v - s0$v) > CCX_REPRO_TOL)) stop("GATE W: the fossil injection did not reach the objective")
s00 <- score(u0, 0)
if (!identical(s00$v, s0$v)) stop("GATE W: the wrapper did not restore r = 0")

say("\n=== 2. EVERY ROW at the canonical, no refit (row change = with source - without) ===\n")
arms <- lapply(R, function(r) score(u0, r))
tab <- data.frame(row = names(s0$rows), base = s0$rows,
                  d_min = arms$min$rows - s0$rows, d_central = arms$central$rows - s0$rows,
                  d_max = arms$max$rows - s0$rows, stringsAsFactors = FALSE)
tab <- tab[order(-abs(tab$d_central)), ]
for (i in seq_len(nrow(tab))) if (abs(tab$d_central[i]) > 1e-3)
  say("  %-28s %+9.3f  [min %+8.3f, max %+8.3f]\n", tab$row[i], tab$d_central[i], tab$d_min[i], tab$d_max[i])
say("  rows moving by <= 1e-3: %d of %d\n", sum(abs(tab$d_central) <= 1e-3), nrow(tab))
say("  TOTAL logpost change: min %+.3f, central %+.3f, max %+.3f\n",
    arms$min$v - s0$v, arms$central$v - s0$v, arms$max$v - s0$v)

say("\n=== 3. PHYSICAL OUTPUTS at the canonical, %d (no refit) ===\n", CH4_READ_YEAR)
phys <- function(r) {
  CH4_R <<- r; on.exit(CH4_R <<- 0)
  o <- ccx_run_fast(sp0, F0)$out; k <- floor(o$t) == CH4_READ_YEAR
  c(co2 = mean((o$co2_NH[k] + o$co2_SH[k]) / 2), d13c = mean((o$d13c_NH[k] + o$d13c_SH[k]) / 2),
    d14c = mean((o$d14c_NH[k] + o$d14c_SH[k]) / 2))
}
ph0 <- phys(0); phc <- phys(R[["central"]])
say("  CO2 %.3f -> %.3f ppm (%+.3f); d13C %.4f -> %.4f permil (%+.4f); D14C %.3f -> %.3f permil (%+.3f)\n",
    ph0[["co2"]], phc[["co2"]], phc[["co2"]] - ph0[["co2"]], ph0[["d13c"]], phc[["d13c"]],
    phc[["d13c"]] - ph0[["d13c"]], ph0[["d14c"]], phc[["d14c"]], phc[["d14c"]] - ph0[["d14c"]])

say("\n=== 4. GRADIENTS by central differences at md$hess_eps (with and without the source) ===\n")
h <- md$hess_eps[P]
g_old <- g_new <- stats::setNames(numeric(length(P)), P)
for (nm in P) {
  up <- u0; dn <- u0; up[nm] <- up[nm] + h[[nm]]; dn[nm] <- dn[nm] - h[[nm]]
  g_old[[nm]] <- (score(up, 0)$v - score(dn, 0)$v) / (2 * h[[nm]])
  g_new[[nm]] <- (score(up, R[["central"]])$v - score(dn, R[["central"]])$v) / (2 * h[[nm]])
}
if (!all(is.finite(c(g_old, g_new)))) stop("a non-finite gradient component")
sdU <- md$sd_unc[P]
say("  |g| x sd, largest five, without the source: %s\n",
    paste(sprintf("%s %+.3f", names(sort(-abs(g_old * sdU)))[1:5], (g_old * sdU)[names(sort(-abs(g_old * sdU)))[1:5]]), collapse = ", "))
dg <- g_new - g_old
say("  the SOURCE's gradient (g_new - g_old) x sd, largest five: %s\n",
    paste(sprintf("%s %+.3f", names(sort(-abs(dg * sdU)))[1:5], (dg * sdU)[names(sort(-abs(dg * sdU)))[1:5]]), collapse = ", "))

say("\n=== 5. NEWTON STEP on the stored Hessian (all %d names) ===\n", length(P))
negH <- -md$hessian[P, P]
newton <- function(g) { du <- solve(negH, g); list(du = du, gain = 0.5 * sum(g * du)) }
fo <- newton(g_old); fn <- newton(g_new)
say("  forecast gain over the mode: without the source %+.3f (the mode's own residual), with %+.3f\n", fo$gain, fn$gain)
du_src <- fn$du - fo$du
ord <- order(-abs(du_src / sdU))
say("  the SOURCE's forecast move (Newton with - without), posterior sd, largest six:\n")
for (i in ord[1:6]) say("    %-22s %+7.3f sd%s\n", P[i], (du_src / sdU)[i], if (abs((du_src / sdU)[i]) > CH4_LARGE_SD) "  (beyond the quadratic's reach)" else "")
evals <- list()
for (st in CH4_NEWTON_STEPS) {
  uN <- u0 + st * fn$du
  sN <- score(uN, R[["central"]])
  evals[[sprintf("step_%g", st)]] <- list(u = uN, v = sN$v, rows = sN$rows)
  say("  with the source, Newton step %.1f EVALUATED: %.4f (%+.4f over the canonical under the source; forecast %+.4f)\n",
      st, sN$v, sN$v - arms$central$v, (st - st^2 / 2) * 2 * fn$gain)
}

out <- list(
  provenance = list(driver = CH4_DRIVER, commit = CH4_COMMIT, run = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                    mode = CH4_MODE, mode_file = ccx_mode_file(CH4_MODE),
                    mode_md5 = unname(tools::md5sum(ccx_mode_file(CH4_MODE))), years = CH4_YEARS,
                    source = CH4_SRC, ox_gtc = CH4_OX_GTC, ref_years = CH4_REF_YRS,
                    arm = "e_foss x (1 + r): fossil history, instant oxidation, fossil d13C, 14C-free",
                    units = "logpost in log-likelihood units; r dimensionless; physical outputs ppm / permil",
                    rng = "none", step = "md$hess_eps", newton_steps = CH4_NEWTON_STEPS),
  efos_ref = c(model = efos_ref, gcb_file = efos_gcb), r = R, cum_add_gtc = cum_add,
  base = s0, arms = arms, rows = tab, phys = rbind(without = ph0, with_central = phc),
  g_old = g_old, g_new = g_new, newton = list(without = fo, with = fn, src_du = du_src, evals = evals))
saveRDS(out, paste0(CH4_STEM, ".rds"))
say("\nwrote %s.rds\n", CH4_STEM)
