# =====================================================================
# diag_d13c_gradient_levers.R -- WHICH LEVER MOVES THE HEMISPHERIC d13C GRADIENT? (2026-09-20 r)
#
# THE DEFECT (handoff_2026-09-20r_hemispheric_d13c_gradient.md §1): at the canonical the MLO-SPO
# d13C gradient is 2.0x observed (-0.134 vs -0.0668 +- 0.0048 permil) while the CO2 gradient is
# right to 9 % -- gate H's contrast (+11.9 sigma) says the miss is ISOTOPIC, not transport, and
# `grad_off_d13c` hides it from the objective ([[ccx_offsets_absorb_the_errors]]). So every
# reading below is on the GATES (H, GL, Q) and the raw MLO Suess residual, never on the
# `d13c_gradient` stream, which is blind to the level.
#
# WHAT IT DOES. One coordinate at a time at the canonical's point (everything else held, the
# file's own spinup, the C++ core), on the handoff's candidate list:
#   [1] ra_ratio -- the land's GROSS isotope loop (R/model.R ~1245; built 08-12, default 0,
#       never fitted, never scanned against the gradient). NH-heavy damping with the right sign.
#   [2] d13c_foss +- 2 permil (the fossil signature; scales the NH anomaly per ppm), and the
#       LUC hemispheric split SWAPPED (a wrong split moves BOTH gradients -- the control shows it).
#   [3] k_w x {0.5, 2} -- air-sea gross exchange (the SH is ocean-heavy: a LARGER exchange could
#       WIDEN the gradient; this says whether the ocean side is the wrong place to look).
# Candidate [4] (hemispheric alpha_photo) needs a code change -- `alpha_photo` is one global
# aux number -- and is deferred until [1]-[3] are read.
#
# ⚠ A CONDITIONAL SCAN AT A FITTED POINT DOES NOT PRICE A MECHANISM (handoff §3): this RANKS
# candidates and FALSIFIES; only a refit adopts. Every row prints the same panel:
#   gate H (R_co2, R_d13c, contrast z) | gate GL z | gate Q n_sd | MLO Suess residual obs-model
#   1990-2020 (mean, and the 1990->2020 drift) | the d13c_level_* / d13c_seasonal_* / bomb
#   d14c_* streams | the 26-row likelihood.
# Output: outputs/diagnostics/d13c_gradient_levers_<date>.{log,rds}
# Usage: Rscript calibration/diag_d13c_gradient_levers.R   (~2-3 min, C++ core)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f); ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
GL_OUT <- ccx_path("outputs", "diagnostics", sprintf("d13c_gradient_levers_%s", format(Sys.Date(), "%Y%m%d")))
GL_RA_GRID    <- c(0, 0.25, 0.5, 1, 2)     # ra_ratio: 0 = the canonical (no gross loop); Ra/GPP ~ 0.5 is the literature's upper end
GL_FOSS_SHIFT <- c(-2, +2)                 # permil, applied to the forcing table's d13c_foss (the transient only; the spinup has no fossil flux)
GL_KW_MULT    <- c(0.5, 2)                 # x the fitted k_w
GL_SUESS_WIN  <- c(1990, 2020)             # the MLO Suess-residual window the handoff names
GL_STREAMS    <- c("d13c_level_MLO", "d13c_level_SPO", "d13c_seasonal_MLO", "d13c_seasonal_SPO",
                   "d13c_gradient", "d14c_NH", "d14c_SH", "co2_gradient")
sink_log <- file(paste0(GL_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE); on.exit({ sink(); close(sink_log) }, add = TRUE)
obs <- ccx_prepare_obs(); ho <- dg_gateH_obs(obs); can <- dg_vector(CCX_MODE_CANONICAL)
cat(sprintf("d13C GRADIENT LEVERS, one coordinate at a time at %s's point  %s\n  %s\n  obs gradients: CO2 %+.4f +- %.4f ppm; d13C %+.4f +- %.4f permil; gate Q obs %.2f +- %.2f\n",
            CCX_MODE_CANONICAL, format(Sys.time()), can$src, ho$co2$mean, ho$co2$se, ho$d13c$mean, ho$d13c$se, DG_Q_OBS, DG_Q_SD))
cat(sprintf("  canonical: ra_ratio %g (model default; not in the table), k_w %.1f, npp_frac_NH %.2f, grad_off_d13c %+.4f\n\n",
            can$p$ra_ratio, can$p$k_w, can$p$npp_frac_NH, can$grad_off_d13c))

# the MLO Suess residual, raw obs - model station level, no rep_dC (the stream carries that)
suess <- function(r, st = "MLO") {
  ms <- ccx_model_stats(r$out, obs); o <- obs$d13_ann[[st]]; m <- ms$d13[[st]]
  k <- o$year >= GL_SUESS_WIN[1] & o$year <= GL_SUESS_WIN[2]
  d <- o$level[k] - m$level[match(o$year[k], m$year)]
  fit <- stats::lm(d ~ o$year[k])
  c(mean = mean(d), drift = unname(coef(fit)[2]) * diff(GL_SUESS_WIN))
}
res <- list()
panel <- function(v, lab, r = NULL) {
  if (is.null(r)) r <- dg_run(v)
  gh <- dg_gateH_verdict(dg_gateH(v, obs, ho, r = r), ho); gl <- dg_gateGL_verdict(dg_gateH(v, obs, ho, r = r), ho)
  gq <- dg_gateQ(r, v); st <- dg_streams(r, v, obs = obs); su <- suess(r)
  o <- c(R_co2 = gh$R_co2, R_d13c = gh$R_d13c, zH = gh$z, zGL = gl$z, Q = gq$mean, Qn = gq$n_sd,
         suess_mean = su[["mean"]], suess_drift = su[["drift"]], st[GL_STREAMS], lik = sum(st))
  cat(sprintf("  %-30s R_co2 %.3f R_d13c %.3f zH %+6.2f | GL z %+6.2f | Q %+.3f (%.2f sd) | Suess obs-mod %+.3f drift %+.3f | lvl %6.1f/%6.1f seas %6.1f/%6.1f grad %6.1f d14c %7.1f/%7.1f | lik %8.2f\n",
              lab, o[["R_co2"]], o[["R_d13c"]], o[["zH"]], o[["zGL"]], o[["Q"]], o[["Qn"]], o[["suess_mean"]], o[["suess_drift"]],
              o[["d13c_level_MLO"]], o[["d13c_level_SPO"]], o[["d13c_seasonal_MLO"]], o[["d13c_seasonal_SPO"]], o[["d13c_gradient"]],
              o[["d14c_NH"]], o[["d14c_SH"]], o[["lik"]]))
  res[[lab]] <<- o; invisible(o)
}
cat("[0] the canonical as stored (must reproduce the 09-20 scorecard: R_co2 0.911, R_d13c 2.001, zH +11.85, GL z -10.03, Q 3.15 sd, lik -1391.81)\n")
base <- panel(can, "canonical as stored")

cat("\n[1] ra_ratio -- the land's GROSS isotope loop (net carbon flux unchanged by construction)\n")
for (ra in GL_RA_GRID[-1]) { v <- can; v$p$ra_ratio <- ra; panel(v, sprintf("ra_ratio %.2f", ra)) }
ra <- do.call(rbind, res[grep("^ra_ratio|^canonical", names(res))])
cat(sprintf("  => R_d13c across ra_ratio [0, 2]: %.3f -> %.3f (%+.3f); R_co2 %.3f -> %.3f; gate Q %.2f -> %.2f sd; Suess mean %+.3f -> %+.3f; d14c_NH %+.1f\n",
            ra[1, "R_d13c"], ra[nrow(ra), "R_d13c"], ra[nrow(ra), "R_d13c"] - ra[1, "R_d13c"], ra[1, "R_co2"], ra[nrow(ra), "R_co2"],
            ra[1, "Qn"], ra[nrow(ra), "Qn"], ra[1, "suess_mean"], ra[nrow(ra), "suess_mean"], ra[nrow(ra), "d14c_NH"] - ra[1, "d14c_NH"]))

cat("\n[2a] the fossil d13C signature, shifted on the forcing table (transient only)\n")
for (s in GL_FOSS_SHIFT) { r <- dg_run(can); r$F$d13c_foss <- r$F$d13c_foss + s; r$out <- ccx_run_fast(r$sp, r$F)$out
  panel(can, sprintf("d13c_foss %+d permil", s), r = r) }
cat("\n[2b] the LUC hemispheric split SWAPPED (NH <-> SH) -- moves BOTH gradients if the split matters\n")
r <- dg_run(can); tmp <- r$F$e_luc_NH; r$F$e_luc_NH <- r$F$e_luc_SH; r$F$e_luc_SH <- tmp
tmp <- r$F$cum_luc_NH; r$F$cum_luc_NH <- r$F$cum_luc_SH; r$F$cum_luc_SH <- tmp
r$out <- ccx_run_fast(r$sp, r$F)$out; panel(can, "LUC split swapped", r = r)

cat("\n[3] k_w -- air-sea gross exchange (spinup sees it)\n")
for (m in GL_KW_MULT) { v <- can; v$p$k_w <- can$p$k_w * m; v$pm$k_w <- v$p$k_w; panel(v, sprintf("k_w x %.1f (%.0f m/yr)", m, v$p$k_w)) }

tab <- do.call(rbind, res)
cat("\n[4] RANKING by |R_d13c - 1| with R_co2 held (a lever that moves R_co2 by more than the CO2 control's se is transport, not isotopes)\n")
ord <- order(abs(tab[, "R_d13c"] - 1))
for (i in ord) cat(sprintf("  %-30s |R_d13c-1| %.3f  dR_co2 %+.3f  dlik %+7.2f  dQ %+.2f sd\n", rownames(tab)[i], abs(tab[i, "R_d13c"] - 1),
                           tab[i, "R_co2"] - base[["R_co2"]], tab[i, "lik"] - base[["lik"]], tab[i, "Qn"] - base[["Qn"]]))
saveRDS(list(res = res, tab = tab, grids = list(ra = GL_RA_GRID, foss = GL_FOSS_SHIFT, kw = GL_KW_MULT), suess_win = GL_SUESS_WIN,
             canonical = CCX_MODE_CANONICAL, built = format(Sys.time())), paste0(GL_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n", GL_OUT))
