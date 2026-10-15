# Conveyor scoping arithmetic for handoff 2026-08-13b section 4.3: NH sinking,
# deep interhemispheric flow, SH upwelling. Volume flux Q in Sv -> per-hemisphere
# velocities, mixed-layer flush times, deep transit time, and the Delta14C that
# transit alone would produce. Paper design numbers, NOT a model run -- the
# mechanism is NOT built. Idealized plug flow; ignores the source water own
# preindustrial Delta14C (~-50 permil) and all diffusion, so read it as
# order-right, not as a prediction. See the handoff for the caveats.

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
A_NH <- ccx_const("OCEAN_AREA_NH"); A_SH <- ccx_const("OCEAN_AREA_SH")
A <- A_NH + A_SH; H <- ccx_const("OCEAN_DEPTH"); lam <- ccx_const("LAMBDA_C14")
SPY <- 365.25*86400; h_ml <- 75
V_deep <- A*(H - h_ml)
cat(sprintf("ocean area NH %.2e SH %.2e m2; deep volume %.3e m3\n", A_NH, A_SH, V_deep))
cat(sprintf("%5s | %8s %8s | %8s %8s | %8s | %8s\n", "Sv", "w_NH", "w_SH",
            "flushNH", "flushSH", "transit", "D14C_adv"))
for (sv in c(10, 15, 20, 27, 30)) {
  Q <- sv*1e6*SPY                                   # m3/yr
  w_NH <- Q/A_NH; w_SH <- Q/A_SH; tr <- V_deep/Q
  cat(sprintf("%5g | %8.2f %8.2f | %8.1f %8.1f | %8.0f | %8.1f\n",
      sv, w_NH, w_SH, h_ml/w_NH, h_ml/w_SH, tr, 1000*(exp(-lam*tr)-1)))
}
cat(sprintf("\nSv giving the observed deep D14C of -170 permil from transit ALONE: %.1f\n",
            (V_deep/(-log(1-170/1000)/lam))/(1e6*SPY)))
cat(sprintf("model equilibration time C_ml/F_gross = 10.5 yr (measured, part 5)\n"))
for (sv in c(15, 27)) {
  Q <- sv*1e6*SPY; tf <- h_ml/(Q/A_SH)
  cat(sprintf("  at %g Sv: SH ml sits at tau_f/(tau_f+tau_eq) = %.2f of full equilibrium (%.0f%% cut)\n",
              sv, tf/(tf+10.5), 100*(1 - tf/(tf+10.5))))
}
cat("\nempirical slope from the runs already done (w_up 4, kz 5000):\n")
cat(sprintf("  ml depletion eased 0.204 permil -> atmospheric bias eased 0.093 => slope %.2f\n",
            0.093/0.204))

# =====================================================================
# ADDED 2026-08-13 by the configuration red team
# (notes/redteam_2026-08-13_conveyor_configurations.md).
#
# THE ARITHMETIC ABOVE DIVIDES BY THE WRONG VOLUME. It uses V_deep = the whole
# sub-mixed-layer ocean, but under sec.4.2's own four limbs the water path is
# NH bottom -> SH bottom -> up the SH column -> SH ml -> NH ml. NH oc1..oc9 --
# 30 % of the deep ocean -- receives NO advective flux at all and is never
# traversed. Correcting that, together with sec.4.3's own source-water caveat,
# the two errors NEARLY CANCEL: the Sv needed for a deep D14C of -170 permil is
# 26.3, not sec.4.3's hedged ~37. The headline survives; its hedge does not.
# =====================================================================
RT_D14C_TARGET <- -170            # permil, observed deep-ocean Delta14C
RT_SRC_D14C    <- -51.2           # permil, model preindustrial NH mixed layer
RT_AMOC_RAPID  <- c(16.9, 1.2)    # Sv, RAPID 26N mean +/- sd, Apr 2004 - Dec 2020

p_rt  <- ccx_default_params(); g_rt <- ccx_ocean_grid(p_rt$h_ml)
V_path   <- A_NH * g_rt$dz[g_rt$nl + 1] + A_SH * sum(g_rt$dz[-1])
V_bypass <- A_NH * sum(g_rt$dz[2:g_rt$nl])
cat(sprintf("\n== red team: the volume the limbs actually traverse ==\n"))
cat(sprintf("V_deep (used above) %.4e m3\n", V_deep))
cat(sprintf("V_path (sec.4.2)    %.4e m3  = %.0f%% of V_deep\n", V_path, 100 * V_path / V_deep))
cat(sprintf("NH oc1..oc%d bypassed %.4e m3 = %.0f%% of V_deep, advectively DEAD\n",
            g_rt$nl - 1, V_bypass, 100 * V_bypass / V_deep))

sv_needed <- function(V, src) {
  t <- -log((1 + RT_D14C_TARGET / 1000) / (1 + src / 1000)) / lam
  c(t = t, sv = V / t / (1e6 * SPY))
}
cat(sprintf("\nSv needed for deep D14C = %g permil:\n", RT_D14C_TARGET))
for (cfg in list(list("V_deep, no source correction", V_deep, 0),
                 list("V_deep, source -51.2 (sec.4.3's own hedge)", V_deep, RT_SRC_D14C),
                 list("V_path, no source correction", V_path, 0),
                 list("V_path, source -51.2  <-- THE HONEST NUMBER", V_path, RT_SRC_D14C))) {
  r <- sv_needed(cfg[[2]], cfg[[3]])
  cat(sprintf("  %-44s %5.1f Sv  (transit %.0f yr)\n", cfg[[1]], r[["sv"]], r[["t"]]))
}
r_rapid <- V_path / (RT_AMOC_RAPID[1] * 1e6 * SPY)
cat(sprintf("\nat the MEASURED AMOC (%.1f +/- %.1f Sv, RAPID 26N): transit %.0f yr ->\n",
            RT_AMOC_RAPID[1], RT_AMOC_RAPID[2], r_rapid))
cat(sprintf("  deep D14C %.0f permil, OUTSIDE the model's own [-150, -200] bracket.\n",
            1000 * ((1 + RT_SRC_D14C / 1000) * exp(-lam * r_rapid) - 1)))
cat("  => the honest target is a JOINT (Q, kz) result, not 'transit alone'. Diffusion\n")
cat("     mixes the profile back the other way; transit sets the floor.\n")

cat(sprintf("\nthe advective limb is a FIRST-ORDER flux, not a perturbation:\n"))
s_rt <- ccx_spinup(p_rt); i_rt <- s_rt$aux$idx$NH
dic  <- s_rt$y[i_rt$ml, "C"] * 1e15 / 12 / (A_NH * g_rt$dz[1])
k_rt <- carb_constants(s_rt$aux$sst$NH)
for (sv in c(15, 27))
  cat(sprintf("  %2g Sv x %.3f mol/m3 = %.1f GtC/yr around the loop\n",
              sv, dic, sv * 1e6 * SPY * dic * 12 / 1e15))
cat(sprintf("  for scale, gross air-sea exchange (NH) = %.1f GtC/yr\n",
            s_rt$aux$asx$NH * p_rt$k_w * k_rt$K0 * ccx_const("CO2_PI_PPM")))
cat(sprintf("\nand the preindustrial column is EXACTLY uniform in DIC (spread %.2e%%),\n",
            100 * (max(s_rt$y[c(i_rt$ml, i_rt$oc), "C"] / (A_NH * g_rt$dz)) /
                   min(s_rt$y[c(i_rt$ml, i_rt$oc), "C"] / (A_NH * g_rt$dz)) - 1)))
cat("so advection is a PURE ISOTOPE OPERATOR preindustrially: it cannot fix the ~14%\n")
cat("low ocean carbon inventory and cannot stand in for a biological pump.\n")
