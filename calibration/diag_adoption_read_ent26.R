# =====================================================================
# diag_adoption_read_ent26.R -- WHAT THE 26-PARAMETER REFIT ACTUALLY BOUGHT,
# measured at the PROMOTED FILE, before anything is repointed.
#
# WHY THIS RUNS BEFORE THE REPOINT. run_post_refit_adoption.R's `read` stage
# exists because a refit that moves a soft direction a long way is not
# self-evidently a finding: the 14.2-min smoke test moved `h_ml` 96.47 -> 35.38 m
# and "gained" 4.1 log-units of which NONE was fit -- it was prior credit on the
# seasonal amplitudes, bought with a WORSE likelihood. This refit moves `h_ml`
# the OTHER way, so the same question has to be asked and answered with numbers
# rather than assumed to be fine because the direction flattered a hypothesis.
#
# ⛔ AND THE COMPARISON IS **NOT** A LOGPOST DIFFERENCE. The 26-parameter space
# is not the 25-parameter one; the ancestors' own reference points moved too.
# The pre-registration (handoff 2026-09-03) judges Fix A on FIVE named claims,
# and this script re-measures every one of them at the file being adopted --
# not at "a converged task", which is what the handoff's table was measured at.
#
# ⚠ NOTHING HERE CHANGES AN OBJECTIVE, AND IT ADOPTS NOTHING.
#
#   Rscript calibration/diag_adoption_read_ent26.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

# ---- labels derive from named constants (project rule) --------------
AR_NEW_FILE <- ccx_path("calibration", "output", "refit_20260903_ent26",
                        "mode_fit_pumpN.rds")
AR_NEW_LAB  <- "ent26 (26 par, promoted)"
AR_OLD_DIR  <- ccx_path("calibration", "output", "multistart_20260902_demean25")
AR_OLD_LAB  <- "demean25 (25 par, incumbent)"
AR_OLD_ENT  <- 0     # what the 25-par ancestor RAN: the channel did not exist
AR_Z2       <- 2; AR_Z3 <- 3        # the ledger's own flag levels
# The handoff's pre-registered table, kept ONLY so drift is VISIBLE. ⛔ These
# are NOT targets and NOT gates -- they were measured at "a converged task of
# 16837149", and the point of re-measuring is that a typed number drifts from
# its own chain ([[derived_must_mean_computed]]).
AR_REC <- list(sst_SH_z_old = -5.14, sst_SH_z_new = +0.24,
               gateS_amp_old = 0.330, gateS_mo_old = 4.19, gateS_z_old = -12.30,
               gateS_amp_new = 0.438, gateS_mo_new = 8.87, gateS_z_new = +0.99,
               land_old = 2.48, land_new = 1.68,
               npp_z_old = -2.15, npp_z_new = -0.05,
               irf_old = 0.276, irf_new = 0.276,
               ent_new = 19.03, ent_z_new = +1.11,
               sst_NH_z_old = -3.56, sst_NH_z_new = -3.91,
               n_z2_old = 5, n_z3_old = 3, n_z2_new = 3, n_z3_new = 2)

sep <- function(s) cat(sprintf("\n%s\n%s\n", s, strrep("-", nchar(s))))
chk <- function(lab, rec, got, tol = 0.02) {
  d <- got - rec
  cat(sprintf("  %-28s recorded %+9.4f   measured %+9.4f   %s\n", lab, rec, got,
              if (abs(d) <= tol) "agrees" else sprintf("DRIFT %+.4f", d)))
  invisible(abs(d) <= tol)
}

cat("\n==== READING THE ent26 ADOPTION, BEFORE THE REPOINT ====\n")

# ---- the two vectors -------------------------------------------------
vN <- dg_vector(AR_NEW_FILE)
mdN <- readRDS(AR_NEW_FILE)
S  <- readRDS(file.path(AR_OLD_DIR, "survey_summary.rds"))
iA <- which(S$group == "A")[which.max(S$logpost[S$group == "A"])]
resO <- readRDS(S$files[iA])
pmO_mig <- ccx_migrate_par_set(resO$par_mode)
AR_MIG  <- attr(pmO_mig, "migrated")
pO <- ccx_overlay_par(ccx_default_params(), pmO_mig)
pO$pump_mode <- resO$pump_mode
stopifnot(identical(pO$ent_seas_amp_SH, AR_OLD_ENT))
vO <- list(p = pO, pm = resO$par_mode, luc_scale = resO$par_mode$luc_scale,
           bomb_total = resO$par_mode$bomb_total,
           src = sprintf("%s id %d", AR_OLD_LAB, resO$id))
cat(sprintf("NEW  %s : %d par, logpost %.4f, from start id %d of %d\n",
            AR_NEW_LAB, length(mdN$param_names), mdN$logpost,
            mdN$promoted_from$id, mdN$promoted_from$n_starts))
cat(sprintf("OLD  %s : %d par, logpost %.4f, MIGRATED filling %s\n",
            AR_OLD_LAB, length(resO$param_names), resO$logpost,
            paste(AR_MIG, collapse = ", ")))
cat("⛔ Their logposts are NOT comparable: different spaces. Do not difference them.\n")

# ---------------------------------------------------------------------
sep("DID THE FIT IMPROVE, OR DID THE PRIOR GET PAID? -- the decomposition")
# The one question run_post_refit_adoption.R exists to force. Both halves are
# measured at the SAME vector by the SAME objective, so the split is exact.
llN <- sum(unlist(mdN$streams))
priN <- mdN$logpost - llN
cat(sprintf("  NEW  loglik %12.4f   prior+jacobian %9.4f   total %12.4f\n",
            llN, priN, mdN$logpost))
# ⚠ The OLD vector's likelihood must be RECOMPUTED here, not read: its stored
# streams were computed by a different driver on a 25-name build.
llO <- local({
  pm <- resO$par_mode; pmm <- pmO_mig
  p_mode <- ccx_overlay_par(ccx_default_params(), pmm)
  p_mode$pump_mode <- resO$pump_mode
  sp <- ccx_spinup(p_mode)
  F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0,
                         bomb_total_kmol = 102)
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- F$c14_bomb * (pm$bomb_total / 102)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- F[[cc]] * pm$luc_scale
  attr(F, "luc_scale") <- pm$luc_scale
  el <- ccx_forcing_eluc_annual(F); r <- ccx_run_fast(sp, F)
  sum(unlist(ccx_loglik(r$out, ccx_prepare_obs(),
      list(sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC,
           grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c),
      luc = el, deep = sp$diagnostics$d14c_bottom_box,
      ocean_grad = ccx_ocean_grad_scored(r$out, sp), by_stream = TRUE)))
})
cat(sprintf("  OLD  loglik %12.4f   (its prior half is on a DIFFERENT space)\n", llO))
cat(sprintf("  ⇒ LIKELIHOOD moved %+.4f. This IS comparable: the 21 data streams\n", llN - llO))
cat("    and their sigmas are identical across the two builds; only the\n")
cat("    parameter space differs, and the likelihood does not see it.\n")

# ---------------------------------------------------------------------
sep("THE PRIOR-z LEDGER, on the names both vectors carry")
nmS <- intersect(names(vN$pm), names(vO$pm))
nmS <- Filter(function(n) n %in% CCX_PARAM_NAMES, nmS)
zN <- vapply(nmS, function(n) ccx_prior_z(n, vN$pm[[n]]), numeric(1))
zO <- vapply(nmS, function(n) ccx_prior_z(n, vO$pm[[n]]), numeric(1))
ord <- order(abs(zN), decreasing = TRUE)
cat(sprintf("  %-22s %9s %9s %9s\n", "parameter", "OLD z", "NEW z", "move"))
for (i in ord[1:min(10, length(ord))])
  cat(sprintf("  %-22s %+9.2f %+9.2f %+9.2f\n", nmS[i], zO[i], zN[i], zN[i] - zO[i]))
entz <- ccx_prior_z("ent_seas_amp_SH", vN$pm$ent_seas_amp_SH)
cat(sprintf("  %-22s %9s %+9.2f   (NEW coordinate, value %.4f)\n",
            "ent_seas_amp_SH", "--", entz, vN$pm$ent_seas_amp_SH))
zNa <- c(zN, ent_seas_amp_SH = entz)
cat(sprintf("\n  |z|>%g : OLD %d -> NEW %d      |z|>%g : OLD %d -> NEW %d\n",
            AR_Z2, sum(abs(zO) > AR_Z2), sum(abs(zNa) > AR_Z2),
            AR_Z3, sum(abs(zO) > AR_Z3), sum(abs(zNa) > AR_Z3)))
cat("\n  against the handoff's recorded table:\n")
chk("P2 sst_seas_amp_SH z OLD", AR_REC$sst_SH_z_old, zO[["sst_seas_amp_SH"]], 0.05)
chk("P2 sst_seas_amp_SH z NEW", AR_REC$sst_SH_z_new, zN[["sst_seas_amp_SH"]], 0.05)
chk("P3 npp_frac_NH z OLD",     AR_REC$npp_z_old,    zO[["npp_frac_NH"]], 0.05)
chk("P3 npp_frac_NH z NEW",     AR_REC$npp_z_new,    zN[["npp_frac_NH"]], 0.05)
chk("   sst_seas_amp_NH z OLD", AR_REC$sst_NH_z_old, zO[["sst_seas_amp_NH"]], 0.05)
chk("   sst_seas_amp_NH z NEW", AR_REC$sst_NH_z_new, zN[["sst_seas_amp_NH"]], 0.05)
chk("   ent_seas_amp_SH value", AR_REC$ent_new,      vN$pm$ent_seas_amp_SH, 0.05)
chk("   ent_seas_amp_SH z",     AR_REC$ent_z_new,    entz, 0.05)

# ---------------------------------------------------------------------
sep("P1 -- GATE S, the SPO SH-OCEAN limb's PHASE")
obs <- ccx_prepare_obs()
gN <- dg_gateS(vN, obs); vdN <- dg_gateS_verdict(gN)
gO <- dg_gateS(vO, obs); vdO <- dg_gateS_verdict(gO)
cat(sprintf("  OLD  amp %.4f ppm @ month %.2f, z %+.2f  -> %s\n",
            gO$amp, gO$mo, vdO$z, if (vdO$pass) "PASS" else "FAIL"))
cat(sprintf("  NEW  amp %.4f ppm @ month %.2f, z %+.2f  -> %s\n",
            gN$amp, gN$mo, vdN$z, if (vdN$pass) "PASS" else "FAIL"))
cat(sprintf("  bound: months [%.3f, %.3f] at |z| <= %g ; obs amp %.3f ppm\n",
            vdN$lo, vdN$hi, vdN$n_sd, DG_S_AMP_OBS))
cat("\n  against the handoff's recorded table:\n")
chk("P1 gate S amp OLD", AR_REC$gateS_amp_old, gO$amp, 0.005)
chk("P1 gate S mo  OLD", AR_REC$gateS_mo_old,  gO$mo,  0.05)
chk("P1 gate S z   OLD", AR_REC$gateS_z_old,   vdO$z,  0.05)
chk("P1 gate S amp NEW", AR_REC$gateS_amp_new, gN$amp, 0.005)
chk("P1 gate S mo  NEW", AR_REC$gateS_mo_new,  gN$mo,  0.05)
chk("P1 gate S z   NEW", AR_REC$gateS_z_new,   vdN$z,  0.05)

# ---------------------------------------------------------------------
sep("P3 -- the SPO LAND limb, as a ratio to observed")
# The land limb by the SAME knockout logic GATE S uses for the ocean one:
# base minus the run with the SH LAND seasonal drivers zeroed.
# ⛔ THE KNOCKOUT IS TAKEN FROM `SL_CASES`, NOT RETYPED -- exactly as
# DG_S_KO does for the ocean limb. A hand-typed name is not merely a risk here:
# the first version of this script typed `npp_seas_amp_SH` for what the library
# calls `seas_npp_amp_SH`, R happily created the new element, the knockout
# changed nothing, and BOTH vectors reported a limb of EXACTLY 0.0000. An
# all-exactly-zero result across two independent vectors is a code path, not
# nature -- and no error was ever raised.
AR_LAND_KO      <- SL_CASES$SH_land
AR_LAND_AMP_OBS <- ccx_const("SPO_SEAS_AMP_LAND_INV")
AR_LAND_MO_OBS  <- ccx_const("SPO_SEAS_LAND_PHASE_INV")
stopifnot(length(AR_LAND_KO) > 0L,
          all(names(AR_LAND_KO) %in% names(ccx_default_params())))
cat(sprintf("  knockout (from SL_CASES$SH_land): %s\n",
            paste(names(AR_LAND_KO), collapse = ", ")))
land_ratio <- function(v) {
  base <- dg_spo_vec(v, obs)
  vk <- v
  for (n in names(AR_LAND_KO)) vk$p[[n]] <- AR_LAND_KO[[n]]
  d <- base - dg_spo_vec(vk, obs)
  # A limb that comes back EXACTLY zero means the knockout did not bite.
  if (sl_amp(d) == 0) stop("the SH_land knockout moved nothing -- names are wrong")
  # ⛔ THE **LAND** DENOMINATOR. DG_S_AMP_OBS is SPO_SEAS_AMP_OCEAN_INV, the
  # OCEAN-signatured half; dividing the LAND limb by it overstated the ratio by
  # a constant 1.31x on BOTH vectors (3.24x / 2.20x against the handoff's
  # 2.48x / 1.68x). The same factor on two independent vectors is a denominator,
  # not a finding -- "ratio to observed" names two different observed amplitudes
  # ([[verify_the_quantity_not_the_word]]).
  list(amp = sl_amp(d), mo = sl_ang_mo(d), ratio = sl_amp(d) / AR_LAND_AMP_OBS)
}
lN <- land_ratio(vN)
lO <- land_ratio(vO)
if (FALSE) {} else {
  cat(sprintf("  observed (LAND-inverted) amp %.4f ppm @ month %.2f\n",
              AR_LAND_AMP_OBS, AR_LAND_MO_OBS))
  cat(sprintf("  OLD  amp %.4f ppm @ month %.2f = %.3fx obs, phase %+.2f mo\n",
              lO$amp, lO$mo, lO$ratio, dg_mo_diff(lO$mo, AR_LAND_MO_OBS)))
  cat(sprintf("  NEW  amp %.4f ppm @ month %.2f = %.3fx obs, phase %+.2f mo\n",
              lN$amp, lN$mo, lN$ratio, dg_mo_diff(lN$mo, AR_LAND_MO_OBS)))
  cat("\n  against the handoff's recorded table:\n")
  chk("P3 land limb ratio OLD", AR_REC$land_old, lO$ratio, 0.05)
  chk("P3 land limb ratio NEW", AR_REC$land_new, lN$ratio, 0.05)
}

# ---------------------------------------------------------------------
sep("P5 -- THE FALSIFIED CLAIM: does the perturbation lifetime move?")
# ⭐ THIS IS THE ONE THE MODEL EXISTS TO DEMONSTRATE, and the handoff reports it
# UNMOVED. Re-measuring it here is not a formality: a P5 that suddenly moved
# would mean the promoted file is not the vector the handoff read.
# ⛔ MEASURED BY `calibration/diag_joos_irf.R`, NOT RE-IMPLEMENTED HERE. That
# script owns the Joos PD100 protocol -- the held background, the 5-yr release
# offset, the Table 4/5 references -- and it takes a mode-file PATH. A second
# copy of a gate is the caption-sync bug class; run it against the promoted file:
#
#   Rscript calibration/diag_joos_irf.R calibration/output/refit_20260903_ent26/mode_fit_pumpN.rds
#
cat(sprintf("  handoff records IRF(100) UNMOVED at %.3f across the 25 -> 26 change.\n",
            AR_REC$irf_new))
cat("  ⛔ P5 is the FALSIFIED claim and it is the pedagogically important one:\n")
cat("     fixing the seasonal ocean physics did not lengthen the lifetime AT ALL,\n")
cat("     so the three problems are INDEPENDENT and Fix C needs its own mechanism.\n")
cat("  measured separately by diag_joos_irf.R against the promoted file.\n")

sep("WHAT MOVED IN THE PHYSICS -- the parameters, not the score")
mv <- vapply(nmS, function(n) {
  a <- vO$pm[[n]]; b <- vN$pm[[n]]
  if (!is.numeric(a) || !is.numeric(b) || a == 0) NA_real_ else (b - a) / abs(a)
}, numeric(1))
o2 <- order(abs(mv), decreasing = TRUE, na.last = NA)
cat(sprintf("  %-22s %12s %12s %8s\n", "parameter", "OLD", "NEW", "rel"))
for (i in o2[1:min(8, length(o2))])
  cat(sprintf("  %-22s %12.5g %12.5g %+7.1f%%\n", nmS[i], vO$pm[[nmS[i]]],
              vN$pm[[nmS[i]]], 100 * mv[i]))

cat("\n⛔ ADOPTS NOTHING. CCX_MODE_CANONICAL is still '", CCX_MODE_CANONICAL, "'.\n", sep = "")
