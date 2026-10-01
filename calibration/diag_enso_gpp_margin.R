# =====================================================================
# diag_enso_gpp_margin.R -- the two things the 2026-09-02 ENSO restructuring
# owes a measurement.
#
# WHAT CHANGED. The ENSO land anomaly was ONE SIGNED FLUX out of `soil_fast` at
# alpha13 = 1; its reverse limb ran atmosphere -> soil_fast, a land uptake that
# never passes through vegetation, and for the SH that reverse direction was the
# MAJORITY direction (61 % of ENSO-active months, 44.5 GtC against 21.7). It is
# now a ONE-WAY MODULATION folded into the two GPP limbs, split by
# npp_leaf_frac. No new fitted coordinate; the parameter count is still 25.
#
# THE TWO MEASUREMENTS, and why each is owed:
#
#   1. THE MARGIN. Folding the anomaly into a gross flux buys one-wayness at the
#      price of a new way to go negative: a large enough gamma shuts
#      photosynthesis off entirely. add_flux's `alpha13_signed = TRUE` reason (a)
#      declares that state rejected rather than fatal -- which is right, and is
#      also exactly the shape of a guard that can never fire. So the margin has
#      to be a NUMBER, not an assumption. ⚠ The bound below is the
#      PREINDUSTRIAL gross limb, which is CONSERVATIVE against fertilisation
#      (modern npp is higher) and NOT conservative against land clearing -- the
#      cleared fraction is reported alongside so the reader can see both.
#
#   2. THE PRICE. A structural change moves the objective at FIXED parameters,
#      and that number decides whether the owed 25-par refit starts from the
#      09-01 basin or somewhere else. ⚠ It is NOT a verdict on the change: the
#      change was made on physical grounds the data cannot adjudicate
#      (diag_enso_two_channel_precheck.R measured both isotopic discriminants
#      BELOW noise), so a worse logpost is a cost to be known, not a refutation.
#
# HOW THE PRICE IS MEASURED, and why it needs two invocations. There is no way
# to hold two versions of R/model.R in one session. So this file is run TWICE:
#
#     git worktree add /tmp/ccx_pre <the pre-change commit>
#     cp calibration/diag_enso_gpp_margin.R /tmp/ccx_pre/calibration/
#     cd /tmp/ccx_pre && Rscript calibration/diag_enso_gpp_margin.R pre
#     cd <repo>        && Rscript calibration/diag_enso_gpp_margin.R post
#
# The `pre` run writes its logpost to EG_PRE_FILE; the `post` run reads it and
# differences. ⚠ THE `post` RUN HARD-ERRORS IF THAT FILE IS ABSENT OR WAS
# WRITTEN BY THE WRONG CODE -- it records the commit it ran at and the post run
# checks it is NOT this one. A comparison that silently skips is worse than no
# comparison ([[broken_gate_reports_nothing]]), and a file that compares this
# build against itself is the [[gate_reads_its_own_output]] failure.
#
# Usage:  Rscript calibration/diag_enso_gpp_margin.R {pre|post}
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))

# ---- labels derive from named constants (project rule) --------------
EG_ROLE     <- local({
  a <- commandArgs(trailingOnly = TRUE)
  if (length(a) != 1L || !a[[1]] %in% c("pre", "post"))
    stop("usage: Rscript calibration/diag_enso_gpp_margin.R {pre|post}")
  a[[1]]
})
EG_ARM      <- "from90"          # the shipped arm; migrated, and it says so
EG_BASIN    <- "calibration/output/multistart_20260901_enso25/start_000.rds"
EG_WIN      <- c(1948, 2024)     # the ENSO-active record, as in the pre-check
EG_STRESS   <- c(1, 2, 4, 8, 16) # gamma multipliers the margin is walked over
EG_PRE_FILE <- file.path("outputs", "diagnostics", "enso_gpp_margin_pre.rds")
EG_HEAD     <- ccx_git_stamp()
# ⛔ THE COMMIT IS NOT THE IDENTITY OF THE CODE. The first run of this file
# proved it: the `post` role ran with the model change UNCOMMITTED, so
# `git rev-parse HEAD` returned the same hash as the `pre` worktree and the
# self-comparison guard refused -- correctly, and for the wrong reason. What
# must differ is the MODEL SOURCE, so that is what is fingerprinted.
EG_SRC      <- c("R/model.R", "src/ccx_core.cpp")
EG_FP       <- paste(tools::md5sum(EG_SRC), collapse = "-")

cat(sprintf("\n%s\nENSO -> GPP RESTRUCTURING: THE MARGIN AND THE PRICE  [role: %s]\n  arm %s, basin %s\n  commit %s\n%s\n",
            strrep("=", 78), EG_ROLE, EG_ARM, basename(dirname(EG_BASIN)),
            EG_HEAD, strrep("=", 78)))
cat(sprintf("  model source fingerprint %s\n", substr(EG_FP, 1, 12)))

v  <- dg_vector(EG_ARM)
r  <- dg_run(v)
pm <- ccx_migrate_par_set(readRDS(EG_BASIN)$par_mode)
g  <- ccx_gamma_enso(pm)

# =====================================================================
# 1. THE MARGIN
# =====================================================================
cat("\n=== 1. THE MARGIN: can the modulation shut photosynthesis off? ===\n")
k   <- r$F$year >= EG_WIN[1] & r$F$year <= EG_WIN[2]
en  <- r$F$enso[k]
cat(sprintf("  ENSO index over %d-%d: sd %.3f, max|index| %.3f (n = %d months)\n",
            EG_WIN[1], EG_WIN[2], stats::sd(en), max(abs(en)), sum(k)))
cat(sprintf("  ra_ratio %.3f, npp_leaf_frac %.3f\n", v$p$ra_ratio, v$p$npp_leaf_frac))
cat(sprintf("\n  %3s | %10s %12s %12s | %9s\n",
            "hem", "gamma", "peak |anom|", "gross GPP PI", "anom/GPP"))
marg <- list()
for (h in HEMIS) {
  gam  <- g[[paste0("land_", h)]]
  anom <- abs(gam) * max(abs(en))
  # PREINDUSTRIAL gross limb = npp0_h * (1 + ra_ratio). It is what the two GPP
  # add_flux calls sum to when `cleared`, `capacity` and `fert` are all at their
  # preindustrial values, which is the state the anomaly is measured against.
  gpp0 <- r$sp$aux$npp0[[h]] * (1 + v$p$ra_ratio)
  marg[[h]] <- anom / gpp0
  cat(sprintf("  %3s | %+10.4f %12.3f %12.3f | %8.2f %%\n",
              h, gam, anom, gpp0, 100 * anom / gpp0))
}
cat(sprintf("\n  ⇒ worst hemisphere: %s at %.2f %% of its own gross GPP limb.\n",
            names(which.max(unlist(marg))), 100 * max(unlist(marg))))
cat("  STRESS: the gamma multiplier at which the anomaly would reach the limb.\n")
for (m in EG_STRESS) {
  w <- m * max(unlist(marg))
  cat(sprintf("    gamma x %-3g -> %6.1f %% %s\n", m, 100 * w,
              if (w >= 1) "⛔ SHUTS PHOTOSYNTHESIS OFF" else "ok"))
}
cat(sprintf("  ⇒ it would take a gamma about %.0fx the fitted one to bite.\n",
            1 / max(unlist(marg))))
cat("  ⚠ CONSERVATIVE AGAINST FERTILISATION (modern npp exceeds npp0) and NOT\n")
cat(sprintf("    conservative against clearing (luc_scale = %.4f in this arm).\n",
            v$luc_scale))
cat("  ⚠ ra_ratio is 0 in this arm, so the gross limb IS npp -- the gross\n")
cat("    respiration loop is off by default and adds no headroom here.\n")

# =====================================================================
# 2. THE PRICE, at fixed parameters -- TOTAL AND BY STREAM
# =====================================================================
# ⚠ BY STREAM, NOT ONLY THE TOTAL. A structural change that preserves the NET
# atmospheric anomaly exactly (this one does: the old flux and the new
# modulation put the same carbon into the same atmosphere) can only pay in the
# streams, and which streams pay is the whole diagnosis. A bare total invites
# exactly the rationalisation the "implausible result = bug" rule forbids.
cat("\n=== 2. THE PRICE: the same 25-par vector through both structures ===\n")
u0 <- ccx_par_to_unc(pm)
stopifnot(all(is.finite(u0)))
bp <- ccx_default_params(); bp$pump_mode <- v$md$pump_mode
lp <- ccx_make_logpost(base_params = bp)
v0 <- lp(u0)
cat(sprintf("  logpost at the 09-01 basin vector, THIS build: %.4f\n", v0))
cat(sprintf("  (%d parameters; migrated: %s)\n", length(CCX_PARAM_NAMES),
            paste(attr(pm, "migrated"), collapse = ", ")))

# Rebuild the run AT THE BASIN VECTOR (not the arm) so the per-stream numbers
# describe the same point the total above does.
pb <- bp
for (n in intersect(names(pb), CCX_PARAM_NAMES)) pb[[n]] <- pm[[n]]
pb <- ccx_set_enso(pb, pm)
spb <- ccx_spinup(pb)
Fb  <- ccx_build_forcing("historical", DG_YEARS, prod_c14 = spb$prod_c14,
                         bomb_total_kmol = pm$bomb_total, luc_scale = pm$luc_scale)
ob  <- ccx_run_fast(spb, Fb)$out
errb <- list(sigma_d14c = pm$sigma_d14c, rep_dC = pm$rep_dC,
             grad_off_co2 = pm$grad_off_co2, grad_off_d13c = pm$grad_off_d13c)
stb <- ccx_loglik(ob, ccx_prepare_obs(), errb, luc = ccx_forcing_eluc_annual(Fb),
                  deep = spb$diagnostics$d14c_bottom_box,
                  ocean_grad = ccx_ocean_grad_scored(ob, spb), by_stream = TRUE)
nb <- nrow(ob)
traj <- c(co2_NH_2024 = ob[nb, "co2_NH"], co2_SH_2024 = ob[nb, "co2_SH"],
          d13c_NH_2024 = ob[nb, "d13c_NH"], d14c_NH_2024 = ob[nb, "d14c_NH"])
cat(sprintf("  by-stream loglik total %.4f over %d streams\n",
            sum(unlist(stb)), length(stb)))
cat(sprintf("  CO2_NH(2024) %.3f ppm   d13c_NH %.4f permil   D14c_NH %.2f permil\n",
            traj[["co2_NH_2024"]], traj[["d13c_NH_2024"]], traj[["d14c_NH_2024"]]))

dir.create(dirname(EG_PRE_FILE), recursive = TRUE, showWarnings = FALSE)
if (identical(EG_ROLE, "pre")) {
  saveRDS(list(logpost = v0, streams = unlist(stb), traj = traj,
               commit = EG_HEAD, fp = EG_FP, when = Sys.time(),
               basin = EG_BASIN, arm = EG_ARM, npar = length(CCX_PARAM_NAMES)),
          EG_PRE_FILE)
  cat(sprintf("  written: %s\n", EG_PRE_FILE))
  cat("  => now run the SAME file with role `post` in the post-change tree.\n")
} else {
  if (!file.exists(EG_PRE_FILE))
    stop("no `pre` measurement at ", EG_PRE_FILE, " -- run this file with role ",
         "`pre` in a worktree at the pre-change commit FIRST. Refusing to ",
         "report a price with nothing to compare against.")
  pre <- readRDS(EG_PRE_FILE)
  # THE SELF-COMPARISON GUARD, on the MODEL SOURCE rather than the commit.
  if (identical(pre$fp, EG_FP))
    stop("the `pre` measurement was written by the SAME model source as this ",
         "run (fingerprint ", substr(EG_FP, 1, 12), "). That compares the build ",
         "against itself. Run the `pre` role in a tree with the pre-change ",
         "R/model.R and src/ccx_core.cpp.")
  if (!identical(pre$npar, length(CCX_PARAM_NAMES)))
    stop("the `pre` measurement has ", pre$npar, " parameters and this build has ",
         length(CCX_PARAM_NAMES), " -- the logposts are on different spaces and ",
         "are not comparable ([[compare_gaps_not_absolute_logposts]]).")
  if (!identical(pre$basin, EG_BASIN) || !identical(pre$arm, EG_ARM))
    stop("the `pre` measurement was taken at a different arm/basin.")
  cat(sprintf("\n  logpost, PRE  (%s, fp %s): %.4f\n", substr(pre$commit, 1, 7),
              substr(pre$fp, 1, 8), pre$logpost))
  cat(sprintf("  logpost, POST (%s, fp %s): %.4f\n", EG_HEAD,
              substr(EG_FP, 1, 8), v0))
  cat(sprintf("  => THE RESTRUCTURING COSTS %+.4f log-units at fixed parameters.\n",
              v0 - pre$logpost))

  cat("\n  WHERE IT IS PAID, stream by stream (post - pre; negative = worse):\n")
  nm <- union(names(pre$streams), names(unlist(stb)))
  po <- unlist(stb)
  d  <- vapply(nm, function(n) {
          a <- if (n %in% names(po)) po[[n]] else NA_real_
          b <- if (n %in% names(pre$streams)) pre$streams[[n]] else NA_real_
          a - b }, numeric(1))
  ord <- order(d)
  for (n in nm[ord])
    cat(sprintf("    %-24s %+12.4f\n", n, d[[n]]))
  cat(sprintf("    %-24s %+12.4f\n", "SUM (loglik only)", sum(d, na.rm = TRUE)))

  cat("\n  AND WHAT MOVED IN THE TRAJECTORY (post - pre):\n")
  for (n in names(traj))
    cat(sprintf("    %-16s %+10.4f   (pre %.4f -> post %.4f)\n", n,
                traj[[n]] - pre$traj[[n]], pre$traj[[n]], traj[[n]]))

  cat("\n  ⚠ AT FIXED PARAMETERS. The refit has not run; the coefficients were\n")
  cat("    fitted to the OLD structure, so this is an UPPER BOUND on the cost.\n")
  cat("  ⚠ NOT A VERDICT. The change was made on physical grounds the data\n")
  cat("    cannot adjudicate -- both isotopic discriminants are below noise\n")
  cat("    (diag_enso_two_channel_precheck.R).\n")
}

# =====================================================================
# 3. WHY THE PRICE IS WHAT IT IS -- AND IT IS A PROPERTY OF THE FORCING
# =====================================================================
# The two structures put the SAME net carbon into the SAME atmosphere at every
# instant, so a large price is not self-evidently explicable and must not be
# rationalised. It is explicable, and the explanation is a number:
#
#   THE ENSO INDEX IS NOT ZERO-MEAN. Its mean over the record is a SUSTAINED
#   anomaly, and the two structures load that mean onto pools with residence
#   times that differ by more than an order of magnitude:
#     OLD: a sustained soil_fast -> atm flux draws soil_fast down until its
#          respiration falls to match => the stock shift is anomaly x tau_soil_fast.
#     NEW: a sustained GPP modulation changes what enters the WHOLE land chain
#          => the stock shift is anomaly x (veg + soil residence time).
# ⇒ THE SAME COEFFICIENT MEANS SOMETHING DIFFERENT IN THE TWO STRUCTURES, which
#   is why the price is an upper bound that a refit should largely recover.
# ⚠ AND IT RAISES A CHOICE NOBODY HAS MADE: whether the ENSO index should be
#   DEMEANED over its non-zero span so the term is a pure anomaly. Under the old
#   structure the mean was nearly inert; under the new one it is a ~1 ppm lever.
#   NOT RESOLVED HERE. [[methodological choices are explicit]]
cat("\n=== 3. WHY: the ENSO index is not zero-mean, and the pools differ ===\n")
eall <- r$F$enso
cat(sprintf("  mean ENSO index, whole run %d-%d : %+.5f  (sd %.4f, n %d)\n",
            min(r$F$year), max(r$F$year), mean(eall), stats::sd(eall), length(eall)))
cat(sprintf("  mean ENSO index, %d-%d       : %+.5f  (sd %.4f, n %d)\n",
            EG_WIN[1], EG_WIN[2], mean(en), stats::sd(en), sum(k)))
cat(sprintf("  before %d the index is identically %.1f, so the two structures are\n",
            EG_WIN[1], mean(eall[!k])))
cat("  bit-identical there and the whole difference is post-1948.\n")
gsh   <- g[["land_SH"]]
sust  <- -gsh * mean(eall)
tau_v <- v$p$npp_leaf_frac * v$p$tau_leaf + (1 - v$p$npp_leaf_frac) * v$p$tau_wood
tau_s <- (1 - v$p$litter_slow_frac) * v$p$tau_soil_fast +
          v$p$litter_slow_frac * v$p$tau_soil_slow
cat(sprintf("\n  sustained SH GPP anomaly from the mean: -(%+.4f) x (%+.5f) = %+.5f GtC/yr\n",
            gsh, mean(eall), sust))
cat(sprintf("  effective land residence time: veg %.2f + soil %.2f = %.2f yr\n",
            tau_v, tau_s, tau_v + tau_s))
cat(sprintf("  tau_soil_fast (the OLD form's only pool):            %.2f yr\n",
            v$p$tau_soil_fast))
dstock <- sust * ((tau_v + tau_s) - v$p$tau_soil_fast)
cat(sprintf("  => extra land stock in the NEW form: %+.4f GtC = %+.4f ppm of CO2\n",
            dstock, -dstock / DG_GtC_PER_PPM))
cat("  ⚠ THAT IS A FULL-EQUILIBRIUM ESTIMATE and the anomaly has only run since\n")
cat(sprintf("    %d (%d yr against a %.0f yr time constant), with the ocean and\n",
            EG_WIN[1], max(r$F$year) - EG_WIN[1], tau_v + tau_s))
cat("    CO2 fertilisation both damping it -- so it is an OVERESTIMATE of the\n")
cat("    measured shift, and should be read for its SIGN and ORDER only.\n")

cat("\n=== DONE ===\n")
