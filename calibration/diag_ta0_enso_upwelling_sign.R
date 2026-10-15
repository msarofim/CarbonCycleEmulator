# =====================================================================
# T-A0 (handoff 2026-09-08g §1): the ENSO-UPWELLING SIGN check at the canonical
# hilda31 -- option A's probe, unrefitted. Decides A vs B.
#
# The model's only ENSO path to the ocean is SST solubility (WRONG sign:
# solubility-only r -0.525, slope -0.163 GtC/yr per Nino3.4 unit vs GCB
# +0.115, r +0.49), canceled by the fitted additive flux gamma_enso_ocn_*.
# Option A: switch the column's upwelling limb ON (w_up > 0, shipped 0) and
# MODULATE it by (1 - gamma x Nino3.4) -- El Nino suppresses upwelling, so less
# DIC-rich water reaches the mixed layer, pCO2 falls, uptake RISES: the right
# sign by construction. With gamma_enso_ocn_* = 0 the regression is the
# scorecard's solubility-only estimator (annual ocean uptake ~ year + Nino3.4).
#
# PRE-REGISTERED: r flips from -0.52 to >= +0.3 at gamma <= 0.5.
# FALSIFIED IF: r stays negative -- the reservoir contrast is essential and B
# (the tropical box) is the build.
#
# HOW, without touching either core: the pure-R transient (bit-parity with
# C++ to 3e-13 ppm, 1.5 min a run) with a session wrapper on ccx_deriv() that
# sets p$w_up = W0 x max(0, 1 - gamma x forc$enso) per call. The spinup runs
# at w_up = W0 (the annual-mean state). gamma = 0 arms run in C++.
# ⚠ SIZING. The handoff's ruling (2) -- gamma from the Fix B reservoir -- is
# still OWED; this is a SCAN over W0 x gamma, not a declared number. W0's
# bracket: 4 m/yr is the classical upwelling-diffusion value (Hoffert et al.
# 1980 -- a RECOLLECTION, labeled); the scan runs 0.5-4 m/yr.
# Usage: Rscript calibration/diag_ta0_enso_upwelling_sign.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
TA0_W0    <- c(0.5, 1, 2, 4)            # m/yr
TA0_GAMMA <- c(0.25, 0.5, 1.0)          # per Nino3.4 unit
TA0_P_R   <- 0.3; TA0_P_GAMMA <- 0.5    # prediction
TA0_WIN   <- c(1959, 2024)              # = SC_ENSO_WIN (diag_whole_model_scorecard.R)
TA0_ROW_SHOW <- 3
TA0_OUT <- ccx_path("outputs", "diagnostics", sprintf("ta0_enso_upwelling_sign_%s.rds", format(Sys.Date(), "%Y%m%d")))

v <- dg_vector(CCX_MODE_CANONICAL); obs <- ccx_prepare_obs()
en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))); en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
g <- obs$gcb; mg <- merge(g[, c("year", "ocean_sink")], en_ann, by = "year"); mg <- mg[complete.cases(mg) & mg$year >= TA0_WIN[1] & mg$year <= TA0_WIN[2], ]
fo <- stats::lm(ocean_sink ~ year + nino34_anom, data = mg)
enso_slope <- function(r) { s <- dg_annual_sinks(r); d <- merge(data.frame(year = s$year, oc = s$ocean), en_ann, by = "year")
  d <- d[d$year >= TA0_WIN[1] & d$year <= TA0_WIN[2], ]; f <- stats::lm(oc ~ year + nino34_anom, data = d)
  c(slope = coef(f)[["nino34_anom"]], se = summary(f)$coefficients["nino34_anom", 2], r = stats::cor(residuals(stats::lm(oc ~ year, d)), d$nino34_anom), sink = mean(s$ocean[s$year >= 2015 & s$year <= 2023])) }
cat(sprintf("GCB observed: slope %+.4f +/- %.4f GtC/yr per index, r %+.3f (n %d)\n", coef(fo)[["nino34_anom"]], summary(fo)$coefficients["nino34_anom", 2], stats::cor(residuals(stats::lm(ocean_sink ~ year, mg)), mg$nino34_anom), nrow(mg)))
# the two references: the canonical (patch on) and solubility-only (patch off), C++
v0 <- v; v0$p$gamma_enso_ocn_NH <- 0; v0$p$gamma_enso_ocn_SH <- 0
rC <- dg_run(v); r0 <- dg_run(v0); st0 <- unlist(dg_streams(r0, v0))
REF <- list(canonical = enso_slope(rC), solubility_only = enso_slope(r0))
cat(sprintf("hilda31 full model: slope %+.4f (r %+.3f); solubility-only (gamma_enso_ocn 0): slope %+.4f (r %+.3f); co2 2020 %.2f\n", REF$canonical[["slope"]], REF$canonical[["r"]], REF$solubility_only[["slope"]], REF$solubility_only[["r"]], r0$out$co2_NH[which.min(abs(r0$out$t - 2020))]))

# ---- the wrapper ------------------------------------------------------------
.ta0_deriv_base <- ccx_deriv; TA0_W_CUR <- 0; TA0_G_CUR <- 0
ccx_deriv <- function(y, t, p, forc, grid, aux, record = FALSE) {
  p$w_up <- TA0_W_CUR * max(0, 1 - TA0_G_CUR * forc$enso)
  .ta0_deriv_base(y, t, p, forc, grid, aux, record)
}
RES <- list()
for (W in TA0_W0) {
  vw <- v0; vw$p$w_up <- W
  sp <- ccx_spinup(vw$p)
  Fw <- ccx_build_forcing("historical", DG_YEARS, prod_c14 = sp$prod_c14, bomb_total_kmol = vw$bomb_total, luc_scale = vw$luc_scale)
  o0 <- ccx_run_fast(sp, Fw)$out; r_0 <- list(sp = sp, F = Fw, out = o0); e0 <- enso_slope(r_0); stw <- unlist(dg_streams(r_0, vw))
  d <- stw - st0; big <- names(d)[order(-abs(d))][abs(sort(-abs(d))) > TA0_ROW_SHOW]
  cat(sprintf("\n  W0 %.1f m/yr, gamma 0 (C++): slope %+.4f (r %+.3f), sink 2015-23 %.2f GtC/yr, co2 2020 %.2f; lik %+.1f vs solubility-only [%s]\n", W, e0[["slope"]], e0[["r"]], e0[["sink"]], o0$co2_NH[which.min(abs(o0$t - 2020))], sum(d), paste(sprintf("%s %+.1f", big, d[big]), collapse = ", ")))
  RES[[sprintf("W%g_g0", W)]] <- c(W0 = W, gamma = 0, e0, lik = sum(stw))
  for (G in TA0_GAMMA) {
    TA0_W_CUR <<- W; TA0_G_CUR <<- G; t0 <- Sys.time()
    oR <- suppressWarnings(ccx_run(sp, Fw))$out; TA0_W_CUR <<- 0; TA0_G_CUR <<- 0
    r_g <- list(sp = sp, F = Fw, out = oR); e <- enso_slope(r_g); stg <- unlist(dg_streams(r_g, vw))
    cat(sprintf("    gamma %.2f: slope %+.4f +/- %.4f (r %+.3f)  = %.2fx obs; sink %.2f; lik %+.1f vs gamma 0; %.0f s\n", G, e[["slope"]], e[["se"]], e[["r"]], e[["slope"]] / coef(fo)[["nino34_anom"]], e[["sink"]], sum(stg) - sum(stw), as.numeric(Sys.time() - t0, units = "secs")))
    RES[[sprintf("W%g_g%g", W, G)]] <- c(W0 = W, gamma = G, e, lik = sum(stg))
  }
}
ccx_deriv <- .ta0_deriv_base
T <- as.data.frame(do.call(rbind, RES))
cat("\n=== VERDICT ===\n")
ok <- T[T$gamma > 0 & T$gamma <= TA0_P_GAMMA & T$r >= TA0_P_R, ]
cat(sprintf("  prediction 'r flips from %+.2f to >= %+.1f at gamma <= %.1f': %s\n", REF$solubility_only[["r"]], TA0_P_R, TA0_P_GAMMA,
            if (nrow(ok)) sprintf("CONFIRMED at %s", paste(sprintf("W0 %g / gamma %g (r %+.2f, %.2fx obs)", ok$W0, ok$gamma, ok$r, ok$slope / coef(fo)[["nino34_anom"]]), collapse = "; ")) else if (any(T$r[T$gamma > 0] > 0)) sprintf("PARTLY: the sign flips (max r %+.2f at W0 %g / gamma %g) but not to +0.3 at gamma <= 0.5", max(T$r[T$gamma > 0]), T$W0[which.max(T$r)], T$gamma[which.max(T$r)]) else "FALSIFIED: r stays negative at every W0 x gamma -- the reservoir contrast is essential; B is the build"))
saveRDS(list(table = T, ref = REF, obs = list(slope = coef(fo)[["nino34_anom"]]), mode = CCX_MODE_CANONICAL, date = Sys.time()), TA0_OUT)
cat(sprintf("saved %s\n⛔ Nothing adopted. w_up stays 0 in every mode file.\n", TA0_OUT))
