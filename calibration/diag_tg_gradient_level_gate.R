# =====================================================================
# T-G (handoff 2026-09-08g §1): GATE GL -- the interhemispheric d13C gradient
# LEVEL, a DESIGN gate beside H, at the canonical hilda31, the column control
# and the defaults.
#
# PRE-REGISTERED: FAIL at the canonical. FALSIFIED IF: PASS -- then the
# 1.97x is a level artefact of the offset itself.
# The gate is dg_gateGL_verdict() in lib_design_gates.R (ledger id "GL"),
# kernel mutation-tested in test-gate-bounds.R. Nothing is adopted.
# Usage: Rscript calibration/diag_tg_gradient_level_gate.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

TG_ARMS <- c(CCX_MODE_CANONICAL, "column_control", "defaults")
TG_OUT <- ccx_path("outputs", "diagnostics", sprintf("tg_gradient_level_gate_%s.rds", format(Sys.Date(), "%Y%m%d")))
obs <- ccx_prepare_obs(); ho <- dg_gateH_obs(obs)
cat(sprintf("observed d13C gradient (MLO - SPO) %+.5f permil, sd %.4f, n %d, n_eff %.1f, se %.5f, %d-%d; CO2 %+.4f ppm se %.4f\n",
            ho$d13c$mean, ho$d13c$sd, ho$d13c$n, ho$d13c$n_eff, ho$d13c$se, min(obs$d13c_grad$year), max(obs$d13c_grad$year), ho$co2$mean, ho$co2$se))
RES <- list()
for (a in TG_ARMS) {
  va <- if (a == "column_control") dg_vector(CCX_MODE_COLUMN_CONTROL) else dg_vector(a)
  g  <- dg_gateH(va, obs, ho); vH <- dg_gateH_verdict(g, ho)
  # ⭐ RULING 3 (2026-09-09): the GATE is now the AUGMENTED form (rep_frac
  # DERIVED inside the verdict from this same g/ho); the BARE-se form is what is
  # reported beside it, as v$z_bare. The two arms below swapped roles that day.
  vL <- dg_gateGL_verdict(g, ho)                       # THE GATE (augmented)
  rep_frac <- vL$rep_frac                              # |1 - R_co2|, derived not typed
  vR <- dg_gateGL_verdict(g, ho, rep_frac = 0)         # the retired bare-se form
  RES[[a]] <- list(g = g, H = vH, GL = vL, GL_bare = vR, grad_off_d13c = va$grad_off_d13c, rep_frac = rep_frac)
  cat(sprintf("\n  %-16s raw model gradient %+.5f (ratio %.3f); fitted grad_off_d13c %+.5f absorbs %+.5f of the %+.5f miss\n", a, g$d13c, vL$ratio, if (is.null(va$grad_off_d13c)) NA else va$grad_off_d13c, if (is.null(va$grad_off_d13c)) NA else va$grad_off_d13c, g$d13c - ho$d13c$mean))
  cat(sprintf("    GATE GL (RULING 3, augmented: se_obs %.5f + |1 - R_co2| %.3f x |obs| in quadrature = %.5f): z %+.2f -> %s | REPORTED, the retired bare-se form: z %+.2f -> %s | GATE H contrast z %+.2f %s\n",
              vL$se_obs, rep_frac, vL$se, vL$z, if (vL$pass) "PASS" else "FAIL", vR$z, if (vR$pass) "PASS" else "FAIL", vH$z, if (vH$pass) "PASS" else "FAIL"))
}
vc <- RES[[CCX_MODE_CANONICAL]]$GL
cat(sprintf("\n=== VERDICT === prediction 'FAIL at the canonical': z %+.2f -> %s\n", vc$z, if (!vc$pass) "CONFIRMED" else "FALSIFIED (the 1.97x is a level artefact of the offset)"))
cat(sprintf("  ⭐ RULED 2026-09-09 (Marcus, ruling 3): the gate bounds on the AUGMENTED form; the bare-se z is reported beside it. The allowance moves the canonical %+.2f -> %+.2f and the gate still FAILS.\n", vc$z_bare, vc$z))
saveRDS(list(arms = RES, obs = ho, mode = CCX_MODE_CANONICAL, date = Sys.time()), TG_OUT)
cat(sprintf("saved %s\n⛔ Nothing adopted.\n", TG_OUT))
