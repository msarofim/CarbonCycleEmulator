# =====================================================================
# diag_emission_scale_degeneracy.R -- can the model tell a fossil-emission
# error from a land-use one, or would a second input scale be unidentifiable?
#
# THE QUESTION (Marcus, 2026-08-14). `luc_scale` shipped as the 17th parameter.
# Fossil emissions carry GCB 2025's stated +/-5 % (LIK_GCB_FOSS_FRAC) and are
# still prescribed EXACT. `foss_scale` is the obvious sibling -- but the CO2
# record mostly constrains the SUM of the two cumulative inputs, so the two
# scales could be degenerate, and adding an unidentifiable parameter is how a
# posterior acquires a ridge that the sampler then explores instead of the
# physics. Measure the degeneracy BEFORE adding the parameter.
#
# WHAT WOULD BREAK THE DEGENERACY, stated first so the result can disagree:
#   * D14C. Fossil carbon is 14C-FREE by definition (that is the Suess effect);
#     land-use carbon carries the vegetation pool's own 14C, which is near
#     contemporary before 1950 and BOMB-ENRICHED after. This is the strongest
#     discriminator in principle.
#   * d13C. Weaker -- fossil is -24.0 to -28.3 permil (time-varying, DATA.md)
#     and the biosphere is a similar depletion, so the contrast is small.
#   * TIME PROFILE. Fossil grows near-exponentially; LUC is flat to declining.
#     The ice core and the early instrumental record see different mixtures.
#   * HEMISPHERIC SPLIT. 0.95 vs 0.55 -- but NOTHING in the likelihood scores
#     the interhemispheric gradient (review sec.2.3), so this channel is
#     currently mute and cannot help.
#
# HOW IT IS SCORED. A 2-D profile of the FULL log-posterior, with the fossil
# scale applied as a column multiply and its own +/-5 % lognormal prior added by
# hand -- deliberately NOT by adding foss_scale to CCX_PARAM_TABLE, because the
# point of this file is to decide whether it should be added at all.
#
# READING IT. If the surface has a long flat valley along the iso-carbon line
# foss*504.7 + luc*289.3 = const, the pair is degenerate. If it has an interior
# maximum with curvature in BOTH directions, it is not.
#
# RUNTIME ~4 min.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

DG_YEARS  <- c(1750, 2024)
DG_FOSS   <- c(0.90, 0.95, 1.00, 1.05, 1.10)
DG_LUC    <- c(0.50, 0.65, 0.80, 0.95, 1.10, 1.25)
DG_BETAS  <- c(0.55, 0.75)
DG_SIGMA_D13C <- 0.44          # the value mode_fit chose; see diag_beta_luc_profile.R
DG_FOSS_SDLOG <- LIK_GCB_FOSS_FRAC   # GCB 2025 stated 1 sigma on fossil, 0.05

obs <- ccx_prepare_obs()
base <- ccx_build_forcing("historical", DG_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
DG_CUM_FOSS <- sum(ccx_forcing_eluc_annual(
  transform(base, e_luc_NH = base$e_foss_NH, e_luc_SH = base$e_foss_SH))$eluc)
DG_CUM_LUC  <- sum(ccx_forcing_eluc_annual(base)$eluc)

cat(sprintf("\ncumulative inputs 1750-2024: fossil %.1f GtC, land-use %.1f GtC\n",
            DG_CUM_FOSS, DG_CUM_LUC))
cat(sprintf("prior 1 sigma in CARBON: fossil %.1f GtC (%.0f %%), land-use %.1f GtC (%.0f %%)\n",
            DG_FOSS_SDLOG * DG_CUM_FOSS, 100 * DG_FOSS_SDLOG,
            0.28 * DG_CUM_LUC, 28))
cat(sprintf("=> the land-use prior admits %.1fx more carbon movement than the fossil one\n",
            (0.28 * DG_CUM_LUC) / (DG_FOSS_SDLOG * DG_CUM_FOSS)))
cat(sprintf("iso-carbon line: d(luc)/d(foss) = -%.1f/%.1f = %+.2f\n\n",
            DG_CUM_FOSS, DG_CUM_LUC, -DG_CUM_FOSS / DG_CUM_LUC))

FOSS_COLS <- c("e_foss_NH", "e_foss_SH")
LUC_COLS  <- c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")

dg_run <- function(beta, fs, ls) {
  p <- ccx_default_params(); p$beta <- beta
  sp <- ccx_spinup(p)
  F  <- base
  F$c14_cosmo <- sp$prod_c14
  for (cc in FOSS_COLS) F[[cc]] <- base[[cc]] * fs
  for (cc in LUC_COLS)  F[[cc]] <- base[[cc]] * ls
  out <- ccx_run_fast(sp, F)$out
  el  <- ccx_forcing_eluc_annual(F)
  err <- list(sigma_co2 = 1.5, sigma_d13c = DG_SIGMA_D13C, sigma_d14c = 5)
  ccx_loglik(out, obs, err, luc = el, by_stream = TRUE)
}

# full objective = likelihood + BOTH input priors (the Jacobians are constant
# across a grid in the natural scale and cancel in every difference reported)
dg_post <- function(parts, fs, ls)
  sum(parts) + stats::dlnorm(fs, 0, DG_FOSS_SDLOG, log = TRUE) +
               stats::dlnorm(ls, 0, 0.28, log = TRUE)

for (b in DG_BETAS) {
  M <- matrix(NA_real_, length(DG_FOSS), length(DG_LUC),
              dimnames = list(sprintf("%.2f", DG_FOSS), sprintf("%.2f", DG_LUC)))
  store <- list()
  for (i in seq_along(DG_FOSS)) for (j in seq_along(DG_LUC)) {
    pr <- dg_run(b, DG_FOSS[i], DG_LUC[j])
    store[[paste(i, j)]] <- pr
    M[i, j] <- dg_post(pr, DG_FOSS[i], DG_LUC[j])
  }
  cat(sprintf("\n== beta %.2f: log-POSTERIOR relative to this grid's max ==\n", b))
  cat("rows = foss_scale, cols = luc_scale\n")
  print(round(M - max(M), 1))
  k <- which(M == max(M), arr.ind = TRUE)[1, ]
  cat(sprintf("  argmax: foss_scale %.2f, luc_scale %.2f\n",
              DG_FOSS[k[1]], DG_LUC[k[2]]))

  # Degeneracy test: walk ALONG the iso-carbon line through the argmax and see
  # whether the objective is flat there. Flat = degenerate.
  cat("\n  ALONG the iso-carbon line through the argmax (equal total emitted C):\n")
  f0 <- DG_FOSS[k[1]]; l0 <- DG_LUC[k[2]]
  cat(sprintf("  %10s %10s %12s | %s\n", "foss", "luc", "d logpost",
              "d14c_NH  d14c_SH  d13c_MLO  co2_lvl_MLO  icecore"))
  ref <- NULL
  for (df in c(-0.08, -0.04, 0, 0.04, 0.08)) {
    fs <- f0 + df
    ls <- l0 - df * DG_CUM_FOSS / DG_CUM_LUC
    if (ls <= 0.1) next
    pr <- dg_run(b, fs, ls)
    lpv <- dg_post(pr, fs, ls)
    if (df == 0) ref <- list(lp = lpv, pr = pr)
    cat(sprintf("  %10.3f %10.3f %12.1f | %8.1f %8.1f %9.1f %12.1f %8.1f\n",
                fs, ls, lpv - ref$lp,
                pr[["d14c_NH"]] - ref$pr[["d14c_NH"]],
                pr[["d14c_SH"]] - ref$pr[["d14c_SH"]],
                pr[["d13c_level_MLO"]] - ref$pr[["d13c_level_MLO"]],
                pr[["co2_level_MLO"]] - ref$pr[["co2_level_MLO"]],
                pr[["co2_icecore"]] - ref$pr[["co2_icecore"]]))
  }
  cat("  (deltas are relative to the df = 0 row, which is why it reads 0.0;\n",
      "   a DEGENERATE pair would show near-zero d logpost across this walk)\n")
}
