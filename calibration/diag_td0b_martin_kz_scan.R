# =====================================================================
# T-D0b (2026-09-08h): does round 6's D have somewhere to go? The Martin shape
# at the canonical's K(z) held the 262 umol/kg gradient with a TENTH of the
# export (T-D0), because K_deep is 129 m2/yr. A refit would move kz_deep_frac,
# kz and pump_grad together. This scans kz_deep_frac (and kz at its best
# value) UNREFITTED under both Martin arms, reading what the refit will trade:
# the export (Nowicki 2022 ~10 GtC/yr, cited in memory overturning_and_mld_
# literature), the below-1000 m share, the sub-ML step (option C's amplitude),
# the deep d13C, the deep rows' log-likelihood, gate Q. ⚠ NO Joos anything
# here (Marcus 09-08h: the lifetime is emergent, never scored).
# Nothing adopted. Usage: Rscript calibration/diag_td0b_martin_kz_scan.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R")); source(ccx_path("calibration", "lib_glodap_obs.R"))
source(ccx_path("calibration", "lib_martin_shape.R"))
KS_FRAC   <- c(0.011, 0.02, 0.05, 0.1, 0.2, 0.5, 1)     # kz_deep_frac (canonical 0.0110 first)
KS_KZ_X   <- c(0.5, 1, 2)                              # kz multipliers at the best frac
KS_ARMS   <- c("martin_tail", "martin_full")
KS_EXPORT_LIT <- 10.2                                   # GtC/yr, Nowicki et al. 2022 global export (memory overturning_and_mld_literature)
KS_DEEP_ROWS <- c("ocean_grad_dic", "ocean_grad_d13c", "ocean_grad_alk", "d14c_profile_level", "d14c_profile_ab", "d14c_profile_bd", "hs_surf_dic", "hs_surf_d13c")
KS_OUT <- ccx_path("outputs", "diagnostics", sprintf("td0b_martin_kz_scan_%s.rds", format(Sys.Date(), "%Y%m%d")))
v <- dg_vector(CCX_MODE_CANONICAL); mld <- readRDS(ccx_path("data", "obs_mld.rds"))$seasonal; tg7 <- dg_gcb_target(DG_SINK_WIN)
d13 <- function(y, i) 1000 * (sum(y[i, "C13"]) / sum(y[i, "C"]) / ccx_const("R13_VPDB") - 1)
read <- function(arm, frac, kzx = 1) {
  va <- v; va$p$kz_deep_frac <- frac; va$p$kz <- v$p$kz * kzx; MS_ARM <<- arm; MS_P <<- va$p
  r <- dg_run(va); sp <- r$sp; aux <- sp$aux; y <- sp$y; g <- sp$grid
  zt <- cumsum(g$dz)[seq_len(g$nl)]; zb <- cumsum(g$dz)[-1]; fb <- pmin(pmax((zb - 1000) / (zb - zt), 0), 1)
  S <- lapply(HEMIS, function(h) aux$pump[[h]]$org + aux$pump[[h]]$carb)
  E <- sum(unlist(S)); Eb <- sum(unlist(lapply(S, function(s) sum(s * fb))))
  step1 <- mean(vapply(HEMIS, function(h) { i <- aux$idx[[h]]; rho <- ccx_const("RHO_SEAWATER")
    y[i$oc[1], "C"] * aux$mol_per_GtC / (aux$a_ls[[h]] * g$dz[2] * rho) * 1e6 - y[i$ml, "C"] * aux$mol_per_GtC / aux$ml_mass_kg[[h]] * 1e6 }, numeric(1)))
  amp_sh <- (max(mld$SH$f_ent) - min(mld$SH$f_ent)) / 2 * step1
  st <- unlist(dg_streams(r, va)); q <- dg_gateQ(r, va); g7 <- dg_gate7_verdict(dg_gate7(r), tg7)
  c(frac = frac, kzx = kzx, K_deep = aux$kz_int[g$nl], export = E, below1000 = Eb, step1 = step1, amp_sh = amp_sh,
    deep_d13c = mean(vapply(HEMIS, function(h) d13(y, aux$idx[[h]]$oc[10]), numeric(1))), Q = q$n_sd, sink_oc = g7$ocean %||% NA,
    lik = sum(st), deep8 = sum(st[KS_DEEP_ROWS]), st)
}
MS_ARM <- "glodap"; MS_P <- v$p; base <- read("glodap", v$p$kz_deep_frac)
cat(sprintf("canonical (GLODAP shape): kz %.0f, kz_deep_frac %.4f (K_deep %.0f), export %.1f GtC/yr (%.1f below 1000 m), step1 %+.1f, deep d13C %+.2f, Q %.2f, lik %.2f, deep rows %.2f\n",
            v$p$kz, v$p$kz_deep_frac, base[["K_deep"]], base[["export"]], base[["below1000"]], base[["step1"]], base[["deep_d13c"]], base[["Q"]], base[["lik"]], base[["deep8"]]))
RES <- list()
for (a in KS_ARMS) {
  cat(sprintf("\n=== %s: kz_deep_frac scan at the canonical kz (lik and deep rows RELATIVE to the canonical) ===\n", a))
  cat(sprintf("  %6s %7s | %7s %8s | %7s %7s | %8s %6s %6s | %8s %8s | %s\n", "frac", "K_deep", "export", "<1000 m", "step1", "amp SH", "deep13C", "Q", "sink", "d lik", "d deep8", "rows |d| > 3"))
  for (fr in KS_FRAC) { z <- read(a, fr); RES[[sprintf("%s_f%g", a, fr)]] <- z
    d <- z[names(base)] - base; rows <- setdiff(names(d), c("frac", "kzx", "K_deep", "export", "below1000", "step1", "amp_sh", "deep_d13c", "Q", "sink_oc", "lik", "deep8"))
    big <- rows[order(-abs(d[rows]))][abs(sort(-abs(d[rows]))) > 3]
    cat(sprintf("  %6.3f %7.0f | %7.2f %8.2f | %+7.1f %7.1f | %+8.2f %6.2f %6.2f | %+8.1f %+8.1f | %s\n", fr, z[["K_deep"]], z[["export"]], z[["below1000"]], z[["step1"]], z[["amp_sh"]], z[["deep_d13c"]], z[["Q"]], z[["sink_oc"]], d[["lik"]], d[["deep8"]], paste(sprintf("%s %+.0f", big, d[big]), collapse = ", "))) }
  best <- KS_FRAC[which.max(vapply(KS_FRAC, function(fr) RES[[sprintf("%s_f%g", a, fr)]][["lik"]], numeric(1)))]
  cat(sprintf("  best frac by the unrefitted likelihood: %g; kz x {%s} there:\n", best, paste(KS_KZ_X, collapse = ", ")))
  for (kx in KS_KZ_X) { z <- read(a, best, kx); RES[[sprintf("%s_f%g_kz%g", a, best, kx)]] <- z; d <- z[names(base)] - base
    cat(sprintf("    kz x %.1f: K_deep %.0f | export %.2f (<1000 m %.2f) | step1 %+.1f amp SH %.1f | deep13C %+.2f Q %.2f sink %.2f | d lik %+.1f d deep8 %+.1f\n", kx, z[["K_deep"]], z[["export"]], z[["below1000"]], z[["step1"]], z[["amp_sh"]], z[["deep_d13c"]], z[["Q"]], z[["sink_oc"]], d[["lik"]], d[["deep8"]])) }
}
MS_ARM <- "glodap"
cat("\n=== READING ===\n")
T <- as.data.frame(do.call(rbind, RES)); T$arm <- sub("_f.*", "", names(RES))
for (a in KS_ARMS) { Ta <- T[T$arm == a & T$kzx == 1 & is.finite(T$lik), ]; kb <- which.max(Ta$lik)
  cat(sprintf("  %s: export crosses the literature %.1f GtC/yr at kz_deep_frac ~ %s; the unrefitted likelihood peaks at frac %g (%+.1f vs canonical); there step1 %+.1f (canonical %+.1f), deep d13C %+.2f (obs +0.47), below 1000 m %.2f GtC/yr\n", a, KS_EXPORT_LIT,
              if (any(Ta$export >= KS_EXPORT_LIT) && any(Ta$export < KS_EXPORT_LIT)) sprintf("%.3f", stats::approx(Ta$export, Ta$frac, xout = KS_EXPORT_LIT, ties = "ordered")$y) else if (all(Ta$export >= KS_EXPORT_LIT)) "below the scan (every arm exports more)" else "above the scan",
              Ta$frac[kb], Ta$lik[kb] - base[["lik"]], Ta$step1[kb], base[["step1"]], Ta$deep_d13c[kb], Ta$below1000[kb])) }
# THE ARITHMETIC (computed, not typed): how much remineralized carbon a DIFFUSIVE deep can return.
# Martin puts ~14 % of the export below 1000 m; Nowicki's 10.2 GtC/yr over the LS area's share gives the
# flux that must come back up through K(1000 m). The observed deep DIC excess below 1000 m (GLODAP shape:
# (1 - shape(1000)) x pump_grad) over the remaining depth is the gradient available to carry it.
sp0 <- ccx_spinup(v$p); g <- sp0$grid; aux <- sp0$aux; K <- aux$kz_int; zi <- cumsum(g$dz)[seq_len(g$nl)]
k1000 <- which.min(abs(zi - 1000)); A_ls <- aux$a_ls$NH + aux$a_ls$SH; rho <- ccx_const("RHO_SEAWATER")
shape <- .ms_shape_glodap(g); dC_below <- (1 - shape[k1000 + 1]) * v$p$pump_grad          # umol/kg of DIC excess still to be gained below the 1000 m interface
F_martin_1000 <- KS_EXPORT_LIT * (A_ls / (ccx_const("OCEAN_AREA_NH") + ccx_const("OCEAN_AREA_SH"))) * (1000 / 100)^(-MS_MARTIN_B) / (49 / 100)^(-MS_MARTIN_B) * 0 + KS_EXPORT_LIT * (zi[k1000] / g$h_ml)^(-MS_MARTIN_B)   # GtC/yr crossing ~1000 m if the export is the literature value at the ML base, Martin below
F_diff_cap <- K[k1000] * A_ls * rho * (dC_below * 1e-6 / (sum(g$dz) - zi[k1000])) * 12 / 1e15        # GtC/yr a diffusive return can carry on the OBSERVED deep gradient
cat(sprintf("  diffusive-return capacity below %.0f m at the canonical K (%.0f m2/yr): the observed deep DIC excess below there (%.0f umol/kg over %.0f m) carries %.4f GtC/yr; Martin at a %.1f GtC/yr export puts %.2f GtC/yr through that interface -> %.0fx short. A Martin D that delivers light carbon to the deep needs an ADVECTIVE return (option E); the profile form at a held gradient (T-D0) starves the export instead.\n",
            zi[k1000], K[k1000], dC_below, sum(g$dz) - zi[k1000], F_diff_cap, KS_EXPORT_LIT, F_martin_1000, F_martin_1000 / F_diff_cap))
saveRDS(list(base = base, table = T, consts = list(frac = KS_FRAC, kz_x = KS_KZ_X, export_lit = KS_EXPORT_LIT), mode = CCX_MODE_CANONICAL, date = Sys.time()), KS_OUT)
cat(sprintf("saved %s\n⛔ Nothing adopted.\n", KS_OUT))
