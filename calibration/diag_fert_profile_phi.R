# ⛔ HELD-ERA RECORD (2026-10-12). This script builds its Joos PD100 by hand with the climate HELD
# (`gmst <- gmst[1]`), which is no longer the live protocol: card 5, gate L, the scorecard and
# diag_joos_irf.R now run R/joos_irf.R ccx_pd100() with the climate FREE (Marcus 2026-10-12, "free
# everywhere"; scope "Builder + live consumers"). Its hand-held table also leaves the observed-SST
# columns running and restarts T_deep at 0 -- both FIXED in the builder (ccx_pulse_forcings,
# ccx_pulse_ref_state), NOT here. Kept unconverted as the record of what it printed: do not quote its
# IRFs or partitions as the canonical's.
# =====================================================================
# diag_fert_profile_phi.R -- the fertilization-shape profile under both land
# structures: hilda_csl3 (phi 0.5, shipped) and hilda_csl3v0 (phi 0, 2026-09-28).
# At each fert_k, beta_max is RE-FITTED (1-D) and the other 27 free parameters
# are FROZEN at hilda29l. Prints logpost, the PD100 IRF@100 (ccx_irf_pd) and the
# model's FACE-equivalent NPP response for 400 -> 564 ppm.
#
# ⚠ FROZEN-VECTOR. Every logpost cost here is an UPPER BOUND on what a refit pays
# ([[sens_scan_achievable]]: on 08-25 a frozen -4674 landed at ~-47 after refit).
# It ranks the options; it does not price them.
# ⚠ beta_max's prior support is [0, 3] (CCX_PARAM_TABLE). Under phi 0 the
# conditional optimum sits AT that bound, and rows past it are bound-limited.
# ⚠ FACE-equivalent = the MM factor ratio only, i.e. the INSTANT NPP response to a
# CO2 step; FACE is temperate forest and informs LIMITS, not values (Marcus 08-25).
#
# USAGE: Rscript calibration/diag_fert_profile_phi.R     (~1 min)
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
md <- readRDS(ccx_mode_file("hilda29l"))
invisible(ccx_apply_pins(md$pins))
PROF_FERTK <- c(60, 120, 200, 300, 500, 824.6, 1051.7, 1500, 1990)
STRUCTS <- c("hilda_csl3", "hilda_csl3v0")
ix <- match(c("beta_max", "fert_k"), md$param_names)
mk_lp <- function(struct) { bp <- ccx_default_params(); bp$pump_mode <- md$pump_mode
  bp <- ccx_apply_structure(bp, struct, as.character(md$seas_ml), pump_field = md$pump_field)
  for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]; ccx_make_logpost(base_params = bp) }
irf100 <- function(struct, u) {
  m2 <- md; m2$struct <- struct; pr <- as.list(ccx_unc_to_par(u))
  for (n in names(pr)) m2$par_mode[[n]] <- pr[[n]]
  pm <- ccx_migrate_par_set(ccx_mode_par_with_pins(m2))
  p <- ccx_overlay_par(ccx_mode_base(m2), pm); p$pump_mode <- md$pump_mode
  sp <- ccx_spinup(p)
  Fh <- ccx_build_forcing("historical", c(1750, JOOS_REF_YEAR), prod_c14 = sp$prod_c14, bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale)
  sr <- sp; sr$y <- ccx_run_fast(sp, Fh)$state
  Ff <- suppressWarnings(ccx_build_forcing("historical", c(JOOS_REF_YEAR, JOOS_PULSE_YR + 110), prod_c14 = sp$prod_c14, bomb_total_kmol = 0, luc_scale = pm$luc_scale))
  for (cc in c("e_foss_NH","e_foss_SH","e_luc_NH","e_luc_SH","enso","c14_bomb","c14_nuclear")) Ff[[cc]] <- 0
  Ff$gmst <- Ff$gmst[1]
  o <- ccx_irf_pd(sr, ccx_hold_forcing(sr, Ff)); o$irf[which.min(abs(o$t - 100))] }
cat(sprintf("hilda29l logpost %.2f; beta_max re-fitted at each fert_k, 27 others FROZEN at hilda29l\n", md$logpost))
cat(sprintf("%-13s %8s %9s %10s %9s %9s  %s\n", "struct", "fert_k", "beta_max", "logpost", "d vs 29l", "IRF@100", "FACE-eq (400->564)"))
for (st in STRUCTS) { lp <- mk_lp(st)
  for (k in PROF_FERTK) {
    u <- md$u_mode; u[ix[2]] <- .to_unc(k, CCX_PARAM_TABLE$fert_k)
    f <- function(z) { u[ix[1]] <- z; v <- lp(u); if (!is.finite(v)) 1e8 else -v }
    o <- optimize(f, c(-8, 8), tol = 1e-4); u[ix[1]] <- o$minimum
    pr <- as.list(ccx_unc_to_par(u))
    face <- pr$beta_max * (564 - 278) / (k + 564 - 278) / (1 + pr$beta_max * (400 - 278) / (k + 400 - 278)) * (1 + pr$beta_max * (400-278)/(k+400-278)) 
    face <- (1 + pr$beta_max * 286 / (k + 286)) / (1 + pr$beta_max * 122 / (k + 122)) - 1
    cat(sprintf("%-13s %8.1f %9.4f %10.2f %+9.2f %9.3f  %6.1f %%\n", st, k, pr$beta_max, -o$objective,
                -o$objective - md$logpost, irf100(st, u), 100 * face))
  } }
cat(sprintf("Joos IRF@100 (Table 5) = %.3f\n", joos_irf(100)))
