# GATE S's blind phase moved 4.10 -> 4.38 at hilda31w. Candidate cause: the label's per-hemisphere ERSSTv5 SST lag
# (SH 1.536 vs the legacy CCX_SST_SEAS_LAG 1.32). Test: the gate's OWN blind read (test-gate-bounds.R's construction)
# at hilda31w with the lag as fitted, then restored to the legacy value. Everything else held at the canonical.
setwd("/Users/MarcusMarcus/Documents/2026/CodeProjects/CarbonCycleEmulator")
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(ccx_path("calibration", "lib_design_gates.R"))
obs <- ccx_prepare_obs(); v0 <- dg_vector(CCX_MODE_CANONICAL)
cat(sprintf("canonical %s @%s; run lags NH %s SH %s (absent = legacy %.2f)\n", CCX_MODE_CANONICAL, ccx_git_stamp(),
            format(v0$p$sst_seas_lag_NH %||% NA), format(v0$p$sst_seas_lag_SH %||% NA), CCX_SST_SEAS_LAG))
read <- function(v) {
  full  <- dg_gateS_verdict(dg_gateS(v, obs))
  ko <- DG_S_KO; ko$seas_ml <- NULL
  base <- dg_spo_vec(v, obs); vk <- v; for (n in names(ko)) vk$p[[n]] <- ko[[n]]
  d <- base - dg_spo_vec(vk, obs)
  c(whole_amp = full$amp, whole_mo = full$mo, blind_amp = sl_amp(d), blind_mo = sl_ang_mo(d))
}
arms <- list(
  "A as fitted (NH 1.325, SH 1.536)" = v0,
  "B SH -> legacy 1.32"              = { v <- v0; v$p$sst_seas_lag_SH <- CCX_SST_SEAS_LAG; v },
  "C both -> legacy 1.32"            = { v <- v0; v$p$sst_seas_lag_SH <- CCX_SST_SEAS_LAG; v$p$sst_seas_lag_NH <- CCX_SST_SEAS_LAG; v })
R <- t(sapply(arms, read))
print(round(R, 3))
cat(sprintf("\nblind phase: A %.3f; B %.3f (moved %+.3f mo for a %+.3f mo SH lag change); C %.3f\n", R[1, "blind_mo"], R[2, "blind_mo"],
            R[2, "blind_mo"] - R[1, "blind_mo"], CCX_SST_SEAS_LAG - 1.536, R[3, "blind_mo"]))
cat(sprintf("hilda29e's recorded blind read: 4.10 (test-gate-bounds.R); the share of the +0.28 move the SH lag accounts for: %.0f %%\n",
            100 * (R[1, "blind_mo"] - R[2, "blind_mo"]) / (4.377 - 4.10)))
