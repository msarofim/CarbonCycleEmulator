# =====================================================================
# THE REGISTERED PREDICTION FOR THE PER-HEMISPHERE NPP LAG
#
# notes/collect_2026-08-29d sec.4 pre-registered this, before the split existed:
#
#   "make the NPP lag HEMISPHERE-SPECIFIC ... Then the SH can be rotated to
#    theta ~ 165-168 deg while the NH stays at its fitted value, and the fit
#    should take the SH cancellation on its own. THE PREDICTION TO PRE-REGISTER:
#    the NH rows' -788 disappears (they are untouched), leaving the SH-side cost
#    of ~-35 to -50 against SH-land moving 1.308 -> ~1.07."
#
# The split shipped 2026-08-31. This scores the prediction.
#
# ⚠ THE BASELINE MOVED. That prediction was registered against the 08-25f mode
# (seas_lag_p 1.7677, SH-land 1.308). The current mode is the 08-30 refit
# (1.7502) on a THREE-TIMES-CHANGED objective. So the ABSOLUTE numbers are not
# expected to reproduce and are not scored as such; what is scored is the
# STRUCTURAL claim -- that rotating the SH alone costs one to two orders of
# magnitude less than rotating both did, and that the NH seasonal rows barely
# move.
#
# ⚠ AND THE OLD -838 IS NOT A LIKE-FOR-LIKE COMPARATOR EITHER, for the same
# reason. It is quoted below as the ORDER OF MAGNITUDE the structural claim is
# about, never as a number this run must reproduce.
#
# Run:  Rscript calibration/diag_split_lag_prediction.R      (~4 min)
# =====================================================================

for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

SL_MODE  <- file.path("calibration", "output", "refit_20260830_gamma_diff_remap",
                      "from90", "mode_fit_pumpN.rds")
SL_YEARS <- c(1750, 2024)
SL_SH    <- c(1.7502, 2.00, 2.25, 2.50)   # SH lag arms; first = the mode's own
SL_OUT   <- "outputs/diagnostics/split_lag_prediction.rds"

md <- readRDS(SL_MODE); ccx_adopt_mode_band(md)
pv <- ccx_mode_params(SL_MODE)
NH_LAG <- pv$seas_lag_p           # legacy scalar in a 21-parameter mode file
cat(sprintf("mode %s\n  NH lag held at its fitted %.4f; SH lag scanned.\n\n",
            basename(dirname(SL_MODE)), NH_LAG))
obs <- ccx_prepare_obs()

run_at <- function(sh_lag, mods = list()) {
  p <- ccx_default_params()
  for (n in intersect(names(p), CCX_PARAM_NAMES)) p[[n]] <- pv[[n]]
  # ⚠ the mode is a 21-parameter file: it has the LEGACY scalar and neither of
  # the split names, so set BOTH explicitly rather than letting the fallback
  # quietly give the SH the NH's value.
  p$seas_lag_p_NH <- NH_LAG; p$seas_lag_p_SH <- sh_lag
  p$gamma_enso <- pv$gamma_enso; p$pump_mode <- md$pump_mode
  for (n in names(mods)) p[[n]] <- mods[[n]]
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", SL_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14; F$c14_bomb <- F$c14_bomb * (pv$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pv$luc_scale
  attr(F, "luc_scale") <- pv$luc_scale
  o <- ccx_run_fast(sp, F)$out
  ll <- ccx_loglik(o, obs, list(sigma_d14c = pv$sigma_d14c, rep_dC = pv$rep_dC,
                                grad_off_co2 = pv$grad_off_co2,
                                grad_off_d13c = pv$grad_off_d13c),
                   luc = ccx_forcing_eluc_annual(F),
                   deep = sp$diagnostics$d14c_bottom_box,
                   ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE)
  list(ll = unlist(ll), out = o, ms = ccx_model_stats(o, obs))
}
amp <- function(v) sqrt(sum(v^2))
pick <- function(ms, k) { kk <- strsplit(k, ".", fixed = TRUE)[[1]]; ms[[kk[1]]][[kk[2]]] }
vec_of <- function(h) if (is.null(h)) c(NA, NA) else c(mean(h$a), mean(h$b))
sh_land <- function(sh_lag) {
  b <- vec_of(pick(run_at(sh_lag)$ms, "co2_seas.SPO"))
  z <- vec_of(pick(run_at(sh_lag, list(seas_npp_amp_SH = 0, seas_T_amp_SH = 0))$ms,
                   "co2_seas.SPO"))
  amp(b - z)
}

base <- run_at(SL_SH[1])
cat(sprintf("%8s %12s | %14s %14s | %14s %14s | %9s\n", "SH lag", "d total",
            "co2_seas_MLO", "d13c_seas_MLO", "co2_seas_SPO", "d13c_seas_SPO", "SH-land"))
rows <- list()
for (L in SL_SH) {
  r <- if (identical(L, SL_SH[1])) base else run_at(L)
  d <- r$ll - base$ll
  nm <- function(k) if (k %in% names(d)) unname(d[[k]]) else NA_real_
  x <- data.frame(sh_lag = L, dtotal = sum(d, na.rm = TRUE),
                  co2_MLO = nm("co2_seasonal_MLO"), d13_MLO = nm("d13c_seasonal_MLO"),
                  co2_SPO = nm("co2_seasonal_SPO"), d13_SPO = nm("d13c_seasonal_SPO"),
                  shland = sh_land(L))
  rows[[length(rows) + 1]] <- x
  cat(sprintf("%8.4f %12.2f | %14.2f %14.2f | %14.2f %14.2f | %9.3f\n",
              x$sh_lag, x$dtotal, x$co2_MLO, x$d13_MLO, x$co2_SPO, x$d13_SPO, x$shland))
}
res <- do.call(rbind, rows)
dir.create(dirname(SL_OUT), recursive = TRUE, showWarnings = FALSE)
saveRDS(list(res = res, nh_lag = NH_LAG, mode = SL_MODE), SL_OUT)

r225 <- res[which.min(abs(res$sh_lag - 2.25)), ]
nh_pay <- abs(r225$co2_MLO) + abs(r225$d13_MLO)
cat("\n=====================================================================\n")
cat("SCORING THE PREDICTION (structural claim only -- see the header)\n")
cat("=====================================================================\n")
cat(sprintf("  At SH lag 2.25, holding the NH at %.4f:\n", NH_LAG))
cat(sprintf("    total cost           %+10.2f   (both lags moved together: order -838)\n", r225$dtotal))
cat(sprintf("    NH seasonal rows pay %+10.2f   (both moved together: order -788)\n", -nh_pay))
cat(sprintf("    SH seasonal rows pay %+10.2f\n", r225$co2_SPO + r225$d13_SPO))
cat(sprintf("    SH-land amplitude    %10.3f   (predicted to fall toward ~1.07)\n", r225$shland))
cat(sprintf("    baseline SH-land     %10.3f\n", res$shland[1]))
cat("\n  CLAIM 1 -- the NH rows are spared: ")
cat(if (nh_pay < 100) "SUPPORTED\n" else "REFUTED\n")
cat("  CLAIM 2 -- the total is 1-2 orders below the joint rotation: ")
cat(if (abs(r225$dtotal) < 200) "SUPPORTED\n" else "REFUTED\n")
cat("  CLAIM 3 -- SH-land amplitude falls: ")
cat(if (r225$shland < res$shland[1]) "SUPPORTED\n" else "REFUTED\n")
