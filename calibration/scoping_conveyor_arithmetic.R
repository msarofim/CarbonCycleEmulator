# Conveyor scoping arithmetic for handoff 2026-08-13b section 4.3: NH sinking,
# deep interhemispheric flow, SH upwelling. Volume flux Q in Sv -> per-hemisphere
# velocities, mixed-layer flush times, deep transit time, and the Delta14C that
# transit alone would produce. Paper design numbers, NOT a model run -- the
# mechanism is NOT built. Idealised plug flow; ignores the source water own
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
