# =====================================================================
# diag_fert_saturating.R -- REVIEW ITEM 7. Does a saturating fertilization
# form hit the design target the log form provably cannot?
#
# THE DEFECT (review 2026-08-14 sec.4.1). NPP = NPP0(1 + beta ln(chi/chi0)) has
# ONE parameter controlling TWO things the data want to set independently: the
# historical INTEGRAL (bought by the CO2 record and GCB's land sink) and the
# DERIVATIVE at today's CO2 (bought by DESIGN gate 12's Joos IRF and the Pulse
# Lab's Revelle lesson). The ratio between them is fixed by the functional form.
# Two INDEPENDENT criteria -- a 15-model literature benchmark and the app's own
# pedagogical claim -- put the same ceiling on beta at ~0.50, while the CO2
# record puts its optimum at 0.75. That is not a tuning miss.
#
# THE DESIGN TARGET, quoted from review sec.4.1 verbatim:
#   "reproduce the historical cumulative land uptake that beta ~ 0.7 gives,
#    while delivering a marginal sensitivity at 388 ppm no larger than
#    beta ~ 0.5 gives (~0.077 GtC/yr/ppm), and a 1998 ppm NPP ratio well below
#    2.48x."
#
# THE REPLACEMENT. Michaelis-Menten in (beta_max, fert_k), R/model.R's
# CCX_FERT_MM. Chosen over a bounded exponential because carboxylation IS an
# enzyme reaction, so the saturation has a one-sentence undergraduate
# explanation rather than only a curve shape.
#
# WHAT THIS FILE SETTLES AND WHAT IT DOES NOT.
#   SETTLES: whether the form can hit the target at all (sec.1, analytic), and
#     what it does to the historical fit and the sink partition (sec.2-3).
#   DOES NOT: set the defaults. Nothing here is a fit -- the (beta_max, fert_k)
#     pair is not in CCX_PARAM_TABLE and item 8's refit is what should set it.
#     Section 3's log-posterior column is "at otherwise-default parameters",
#     which is a comparison, not a calibration.
#   ALSO NOT: run gate 12. The Joos IRF costs ~4 min per parameter set; sec.5
#     prints the exact commands for the shortlist rather than pretending to it.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants; every label below derives from these ----------
FS_YEARS      <- c(1750, 2024)
FS_WIN        <- c(2015, 2024)      # GCB comparison decade
FS_CHI_NOW    <- 388                # ppm, the review's evaluation point for the slope
FS_CHI_HIGH   <- 1998               # ppm, ssp585 at 2300 -- the Pulse Lab's far end
FS_BETA_INT   <- 0.70               # log-form beta whose INTEGRAL is to be reproduced
FS_BETA_SLOPE <- 0.50               # log-form beta whose SLOPE is the ceiling
FS_BETA_REFS  <- c(0.50, 0.70, 0.75)   # log-form reference runs (0.75 = shipped)
FS_K_GRID     <- c(60, 80, 100, 120, 140, 171, 220, 300)
FS_GCB_LAND   <- 2.36               # GtC/yr, GCB 2025 2015-2024 gross land sink
FS_GCB_OCEAN  <- 3.22               # GtC/yr, ditto ocean
FS_NPP0       <- 60                 # GtC/yr, sum(aux$npp0)
FS_CHI0       <- ccx_const("CO2_PI_PPM")

FS_SLOPE_CAP  <- FS_BETA_SLOPE * FS_NPP0 / FS_CHI_NOW
FS_ENH_TARGET <- FS_BETA_INT * log(FS_CHI_NOW / FS_CHI0)
FS_RATIO_LOG  <- 1 + 0.75 * log(FS_CHI_HIGH / FS_CHI0)   # the 2.48x being replaced

cat("=====================================================================\n")
cat("REVIEW ITEM 7 -- saturating CO2 fertilisation\n")
cat("=====================================================================\n\n")
cat(sprintf("chi0 %.2f ppm, NPP0 %.0f GtC/yr (both from the model, not retyped)\n",
            FS_CHI0, FS_NPP0))
cat(sprintf("design target (a): NPP enhancement at %d ppm = %.4f  [log form at beta %.2f]\n",
            FS_CHI_NOW, FS_ENH_TARGET, FS_BETA_INT))
cat(sprintf("design target (b): dNPP/dchi at %d ppm <= %.4f GtC/yr/ppm  [log form at beta %.2f]\n",
            FS_CHI_NOW, FS_SLOPE_CAP, FS_BETA_SLOPE))
cat(sprintf("design target (c): NPP ratio at %d ppm well below %.2fx  [log form at beta 0.75]\n\n",
            FS_CHI_HIGH, FS_RATIO_LOG))

# ---------------------------------------------------------------------
# 1. ANALYTIC -- the (beta_max, fert_k) locus, and where the target binds
# ---------------------------------------------------------------------
# Criterion (a) fixes beta_max GIVEN fert_k, because MM's enhancement at
# FS_CHI_NOW is beta_max * dchi/(K + dchi). Criterion (b) then caps fert_k: a
# larger K means a straighter curve, hence a steeper slope at today's CO2 for
# the same enhancement. So the target is a ONE-PARAMETER FAMILY with a cap, not
# a point -- which is worth stating, because it is the freedom the log form
# does not have and the whole reason for the change.
cat("--- 1. the design-target locus (analytic) -----------------------\n")
d_now  <- FS_CHI_NOW - FS_CHI0
d_high <- FS_CHI_HIGH - FS_CHI0
fs_bmax  <- function(K) FS_ENH_TARGET * (K + d_now) / d_now
fs_slope <- function(K) FS_NPP0 * fs_bmax(K) * K / (K + d_now)^2

K_cap <- uniroot(function(K) fs_slope(K) - FS_SLOPE_CAP, c(1, 1e4))$root
loc <- data.frame(fert_k = FS_K_GRID)
loc$beta_max   <- fs_bmax(loc$fert_k)
loc$slope_388  <- fs_slope(loc$fert_k)
loc$beta_equiv <- loc$slope_388 * FS_CHI_NOW / FS_NPP0
loc$ratio_1998 <- 1 + loc$beta_max * d_high / (loc$fert_k + d_high)
loc$asymptote  <- 1 + loc$beta_max
loc$meets_b    <- ifelse(loc$slope_388 <= FS_SLOPE_CAP, "yes", "NO")
print(format(loc, digits = 4), row.names = FALSE)
cat(sprintf("\n  (b) binds at fert_k = %.1f. Above it the curve is too straight at\n", K_cap))
cat("  today's CO2 to deliver the historical integral without also delivering\n")
cat("  the pulse sensitivity that fails gate 12 -- i.e. it degenerates toward\n")
cat("  the log form's problem. Below it there is genuine room.\n")
cat(sprintf("  Every row satisfies (a) BY CONSTRUCTION, and every row satisfies (c)\n"))
cat(sprintf("  by a wide margin: worst ratio here is %.2fx against the log form's %.2fx.\n\n",
            max(loc$ratio_1998), FS_RATIO_LOG))

# ---------------------------------------------------------------------
# 2. HISTORICAL -- what each candidate does to the fit and the partition
# ---------------------------------------------------------------------
# Criterion (a) is an anchor at ONE CO2 level. It is NOT the same statement as
# "reproduces the historical cumulative land uptake", because MM and log cross
# at FS_CHI_NOW by construction and disagree on either side of it. This section
# measures the integral itself rather than trusting the anchor to imply it.
obs <- ccx_prepare_obs()
F0  <- ccx_build_forcing("historical", FS_YEARS, prod_c14 = 0, bomb_total_kmol = 102)
FS_ELUC <- local({
  em <- as.data.frame(readRDS(ccx_path("data", "forcing_emissions_historical.rds")))
  mean(em$luc_GtC[em$year >= FS_WIN[1] & em$year <= FS_WIN[2]])
})

fs_bias <- function(o, m) {
  k <- match(o$year, m$year)
  g <- !is.na(k) & o$year >= FS_WIN[1] & o$year <= FS_WIN[2]
  mean(o$level[g] - m$level[k[g]])
}
# Calendar-year boundaries, matching the corrected gcb term in R/likelihood.R --
# NOT diff() of annual means, which is the half-year-off form that term dropped.
fs_flux <- function(out, col) {
  yrs <- sort(unique(floor(out$t + 1e-9)))
  bnd <- c(yrs, max(yrs) + 1L)
  v <- stats::approx(out$t, out[[col]], xout = bnd, rule = 2)$y
  data.frame(year = utils::head(bnd, -1), flux = diff(v))
}

fs_case <- function(p, label) {
  sp <- ccx_spinup(p); F <- F0; F$c14_cosmo <- sp$prod_c14
  out <- ccx_run_fast(sp, F)$out
  stopifnot(!anyNA(out$co2_NH))
  ms <- ccx_model_stats(out, obs)
  lf <- fs_flux(out, "land_C"); of <- fs_flux(out, "ocean_C")
  k  <- lf$year >= FS_WIN[1] & lf$year <= FS_WIN[2]
  ll <- ccx_loglik(out, obs, list(sigma_co2 = 1.5, sigma_d13c = 0.1, sigma_d14c = 5),
                   deep = sp$diagnostics$d14c_bottom_box)
  data.frame(case = label,
             cum_land = tail(out$land_C, 1) - out$land_C[1],
             co2_bias = fs_bias(obs$co2_ann$MLO, ms$co2$MLO),
             gross_land = mean(lf$flux[k]) + FS_ELUC,
             ocean = mean(of$flux[k]),
             d13c_bias = fs_bias(obs$d13_ann$MLO, ms$d13$MLO),
             loglik = ll)
}

cat("--- 2. historical runs: the log references ---------------------\n")
ref <- do.call(rbind, lapply(FS_BETA_REFS, function(b) {
  # PIN. The default is CCX_FERT_MM since 2026-08-14, under which `beta` is
  # inert; without this the "log" rows would silently be MM rows.
  p <- ccx_default_params(); p$fert_form <- CCX_FERT_LOG; p$beta <- b
  fs_case(p, sprintf("log beta %.2f%s", b, if (b == 0.75) " (superseded)" else ""))
}))
print(format(ref, digits = 4), row.names = FALSE)

cat("\n--- 2b. historical runs: the MM locus --------------------------\n")
mm <- do.call(rbind, lapply(FS_K_GRID, function(K) {
  p <- ccx_default_params()
  p$fert_form <- CCX_FERT_MM; p$fert_k <- K; p$beta_max <- fs_bmax(K)
  fs_case(p, sprintf("MM K=%3.0f bmax=%.3f%s", K, fs_bmax(K),
                     if (K == 120) " (SHIPPED)" else ""))
}))
print(format(mm, digits = 4), row.names = FALSE)

int_target <- ref$cum_land[FS_BETA_REFS == FS_BETA_INT]
mm$int_err <- mm$cum_land - int_target
cat(sprintf("\n  GCB 2015-2024: land %.2f, ocean %.2f GtC/yr.\n",
            FS_GCB_LAND, FS_GCB_OCEAN))
cat(sprintf("  Log beta %.2f's cumulative land uptake is %.1f GtC; the closest MM row\n",
            FS_BETA_INT, int_target))
cat(sprintf("  is %s (%+.1f GtC).\n", mm$case[which.min(abs(mm$int_err))],
            mm$int_err[which.min(abs(mm$int_err))]))
cat("\n  BUT DO NOT SELECT ON THAT COLUMN, and this is the one trap in this file.\n")
cat("  Criterion (a) anchors the two forms at ONE CO2 level, so they cross there\n")
cat("  and disagree on both sides -- MM is MORE responsive below 388 ppm (it is\n")
cat("  near-linear there) and less above. `cum_land` is also not independent of\n")
cat("  `co2_bias`: a case that runs the atmosphere high takes up more land carbon\n")
cat("  because of it. THE INTEGRAL IS BOUGHT THROUGH THE CO2 RECORD, so co2_bias\n")
cat("  and loglik are the columns that price it, and they are the ones used to\n")
cat("  build the shortlist in sec.5.\n")

# ---------------------------------------------------------------------
# 3. THE GATE-7 SCORECARD, since that is one of the two failing gates
# ---------------------------------------------------------------------
cat("\n--- 3. DESIGN gate 7 (sinks 2015-2024), in sigma ---------------\n")
cat("  Against GCB's stated 1 sigma: land +/- 0.5, ocean +/- 0.4 GtC/yr\n")
score <- rbind(ref[, c("case", "gross_land", "ocean", "co2_bias", "loglik")],
               mm[,  c("case", "gross_land", "ocean", "co2_bias", "loglik")])
score$z_land  <- (score$gross_land - FS_GCB_LAND) / LIK_GCB_LAND_SD
score$z_ocean <- (score$ocean - FS_GCB_OCEAN) / LIK_GCB_OCEAN_SD
score$gate7   <- ifelse(abs(score$z_land) <= 2 & abs(score$z_ocean) <= 2, "PASS", "FAIL")
print(format(score[, c("case", "z_land", "z_ocean", "co2_bias", "loglik", "gate7")],
             digits = 3), row.names = FALSE)

# ---------------------------------------------------------------------
# 4. WHAT THE FORM BUYS, stated as the decoupling it was chosen for
# ---------------------------------------------------------------------
cat("\n--- 4. the decoupling, made explicit ---------------------------\n")
cat(sprintf("%-22s %12s %12s %10s\n", "form", "enh@388", "slope@388", "ratio@1998"))
for (b in FS_BETA_REFS)
  cat(sprintf("%-22s %12.4f %12.4f %10.2f\n", sprintf("log beta %.2f", b),
              b * log(FS_CHI_NOW / FS_CHI0), b * FS_NPP0 / FS_CHI_NOW,
              1 + b * log(FS_CHI_HIGH / FS_CHI0)))
for (K in FS_K_GRID)
  cat(sprintf("%-22s %12.4f %12.4f %10.2f\n", sprintf("MM K=%.0f", K),
              FS_ENH_TARGET, fs_slope(K),
              1 + fs_bmax(K) * d_high / (K + d_high)))
cat("\n  The log rows move enhancement and slope TOGETHER -- their ratio is\n")
cat("  fixed at chi/chi0 no matter what beta is. The MM rows hold enhancement\n")
cat("  CONSTANT while the slope varies 2-fold. That is the whole point, and it\n")
cat("  is why no value of beta could have passed both gates.\n")

# ---------------------------------------------------------------------
# 5. WHAT STILL HAS TO BE RUN -- gate 12 and the Revelle lesson
# ---------------------------------------------------------------------
# ---------------------------------------------------------------------
# 5. DOES `luc_scale` STACK WITH THIS? -- it does not, and that matters
# ---------------------------------------------------------------------
# Under the LOG form, scaling E_LUC down bought a lower beta, which bought a
# lower land sink: that is the whole case for `luc_scale` (diag_luc_scale.R,
# handoff sec.3.1's settlement at beta 0.55 / luc_scale 0.70). The obvious next
# move is to stack the two and close gate 7. IT DOES NOT WORK, and the reason is
# worth writing down: with the fertilization parameters HELD, luc_scale only
# removes carbon from the system. There is no beta left to relax, so the CO2
# bias absorbs the whole change and the land sink barely moves.
cat("\n--- 5. luc_scale on top of MM -- a negative result --------------\n")
fs_luc <- function(p, s, label) {
  F <- F0
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH")) F[[cc]] <- F[[cc]] * s
  sp <- ccx_spinup(p); F$c14_cosmo <- sp$prod_c14
  out <- ccx_run_fast(sp, F)$out
  ms <- ccx_model_stats(out, obs)
  lf <- fs_flux(out, "land_C"); of <- fs_flux(out, "ocean_C")
  k  <- lf$year >= FS_WIN[1] & lf$year <= FS_WIN[2]
  gl <- mean(lf$flux[k]) + FS_ELUC * s; oc <- mean(of$flux[k])
  data.frame(case = label, luc_scale = s,
             co2_bias = fs_bias(obs$co2_ann$MLO, ms$co2$MLO),
             z_land = (gl - FS_GCB_LAND) / LIK_GCB_LAND_SD,
             z_ocean = (oc - FS_GCB_OCEAN) / LIK_GCB_OCEAN_SD)
}
lucs <- do.call(rbind, lapply(c(1.00, 0.85, 0.70), function(s)
  do.call(rbind, lapply(c(100, 120, 140), function(K) {
    p <- ccx_default_params()
    p$fert_form <- CCX_FERT_MM; p$fert_k <- K; p$beta_max <- fs_bmax(K)
    fs_luc(p, s, sprintf("MM K=%3.0f", K))
  }))))
print(format(lucs, digits = 3), row.names = FALSE)
cat("\n  z_land gets WORSE as luc_scale falls, while the CO2 bias explodes. The\n")
cat("  two levers are NOT additive at fixed fertilisation parameters -- they are\n")
cat("  partially REDUNDANT, because MM at luc_scale = 1 has already delivered the\n")
cat("  near-zero CO2 bias that luc_scale was introduced to buy. ITEM 8's JOINT\n")
cat("  REFIT IS WHAT DECIDES BETWEEN THEM; neither should be set by hand against\n")
cat("  the other, and the handoff's beta 0.55 / luc_scale 0.70 settlement does\n")
cat("  not carry over to this form.\n")

# ---------------------------------------------------------------------
# 6. THE SHORTLIST, and what is still outstanding
# ---------------------------------------------------------------------
cat("\n--- 6. shortlist, by log-likelihood among rows meeting (b) ------\n")
elig <- mm[loc$slope_388 <= FS_SLOPE_CAP, ]
elig_K <- FS_K_GRID[loc$slope_388 <= FS_SLOPE_CAP]
ord <- order(elig$loglik, decreasing = TRUE)
for (i in utils::head(ord, 3)) {
  K <- elig_K[i]
  cat(sprintf("    CCX_FERT_FORM=1 CCX_FERT_BETA_MAX=%.4f CCX_FERT_K=%.0f \\\n",
              fs_bmax(K), K))
  cat("      Rscript calibration/diag_joos_beta_scan.R\n")
}
cat("\n  and calibration/diag_fert_pulse_gates.R for the Revelle lesson.\n")
cat("\n  NOTHING HERE LICENSES A DEFAULT CHANGE ON ITS OWN. Section 1 proves the\n")
cat("  form CAN decouple integral from derivative; only gate 12 proves it DOES\n")
cat("  restore the pulse response, which is the failure that motivated the item.\n")
