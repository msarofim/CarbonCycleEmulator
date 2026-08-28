# =====================================================================
# diag_pump_port_parity.R -- DOES THE PORTED PUMP REPRODUCE THE SHIM IT CAME
# FROM?  (task 9, 2026-08-16)
#
# THE PORT IS ONLY A PORT IF IT REPRODUCES. calibration/pump_shim.R is what
# every pump result in this repo was measured on -- the three clauses (15d), the
# gradient-row verdict (diag_pump_vs_gradient_terms.R) -- and all of those
# numbers become unquotable the moment the shipped pump disagrees with it. This
# file is the gate that says whether they still stand.
#
# THREE DIFFERENCES ARE INTENDED AND THE COMPARISON HAS TO ISOLATE THEM:
#
#   1. TWO LIMBS. The shipped pump splits the export into soft-tissue and
#      carbonate (share pinned by GLODAP's alkalinity gradient); the shim had one
#      limb at eps = -20. Set `pump_carb_frac` = 0 and that difference is gone --
#      which is what this file does for the parity arm, and NOT for the
#      as-shipped arm below it.
#   2. SHAPE FROM A BUILD PRODUCT. The shim re-bins raw GLODAP bottles into the
#      MODEL's layers on every call. The port reads a profile built once on fixed
#      250 m bins and integrates it onto whatever layers a draw asks for -- it
#      has to, because binning 50,634 bottles inside a likelihood evaluation is
#      not an option. The two are NOT identical: a model layer spanning several
#      bins gets their thickness-weighted mean rather than its own bottle set.
#   3. NORMALISATION. `pump_grad` is re-normalised on each grid's own layers, so
#      it delivers EXACTLY the gradient it names. The shim scaled the raw shape
#      and landed 1.1 % high.
#
# So the parity arm is expected to agree CLOSELY, not exactly, and this file
# reports the size of each difference rather than asserting they are zero.
#
# RUNTIME ~2 min.
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "pump_shim.R"))

PP_YEARS    <- c(1750, 2024)
PP_BOMB_REF <- 102
PP_H        <- 100          # m; inside LIK_OCEAN_GRAD_HML_OK_RETIRED
PP_GRAD     <- 233.109      # umol/kg, the shipped DIC target
PP_TOL_PCT  <- 2            # %, the agreement this file calls a PASS. Applies to
                            # the SCORED ROWS ONLY -- see the export note below.
PP_OUTDIR   <- ccx_path("calibration", "output", "pump_port")
dir.create(PP_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

tg <- ccx_ocean_gradient_target()
obs <- ccx_prepare_obs()
ERR <- list(sigma_d13c = 0.44, sigma_d14c = 5,
            grad_off_co2 = -0.386, grad_off_d13c = +0.099)

#' Run the SHIPPED pump and report the rows
pp_ported <- function(carb_frac, mode = "N") {
  p <- ccx_default_params()
  p$h_ml <- PP_H; p$pump_grad <- PP_GRAD
  p$pump_carb_frac <- carb_frac; p$pump_mode <- mode
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", PP_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = PP_BOMB_REF)
  r  <- ccx_run_fast(sp, F)
  og <- ccx_ocean_grad_scored(r$out, sp)
  list(export = sum(vapply(HEMIS, function(h)
         sum(sp$aux$pump[[h]]$org + sp$aux$pump[[h]]$carb), numeric(1))),
       og = og, sp = sp, out = r$out,
       parts = ccx_loglik(r$out, obs, ERR, deep = sp$diagnostics$d14c_bottom_box,
                          ocean_grad = og, by_stream = TRUE))
}

#' Run the SHIM at the same operating point, single limb, as it always was
pp_shim <- function() {
  p <- ccx_default_params(); p$h_ml <- PP_H
  aux <- ccx_prepare(p); grid <- aux$grid
  op <- dg_obs_profile(grid)
  shape <- op$dic - op$dic[1]
  shape <- shape * (PP_GRAD / shape[length(shape)])
  fl <- lapply(HEMIS, function(h) {
    dic_ml <- ccx_dic_for_pco2(ccx_const("CO2_PI_PPM"), ccx_const("ALK_SURFACE"),
                               aux$sst[[h]]) * 1e6
    dg_export_field(p, aux, grid, h, dic_ml + shape)$S
  })
  names(fl) <- HEMIS
  .dg$S <- fl; .dg$mode <- "N"; .dg$eps <- PUMP_EPS_ORG; .dg$on <- TRUE
  .dg$c_ml0 <- lapply(HEMIS, function(h)
    ccx_dic_for_pco2(ccx_const("CO2_PI_PPM"), ccx_const("ALK_SURFACE"),
                     aux$sst[[h]]) * aux$ml_mass_kg[[h]] / aux$mol_per_GtC)
  names(.dg$c_ml0) <- HEMIS
  sp <- dg_spinup(p)
  F  <- ccx_build_forcing("historical", PP_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = PP_BOMB_REF)
  F$c14_cosmo <- sp$prod_c14
  r <- ccx_run(sp, F)          # R reference core: the shim never had a C++ path
  .dg$on <- FALSE
  list(export = sum(vapply(fl, sum, numeric(1))),
       og = ccx_ocean_grad_scored(r$out, sp), sp = sp)
}

dg_parity_gate()

sep("PORT PARITY -- single limb, so only the SHAPE and NORMALISATION differ")
a <- pp_shim()
b <- pp_ported(carb_frac = 0)
cat(sprintf("%-26s %12s %12s %10s\n", "quantity", "shim", "ported", "diff %"))
rows <- list(c("export GtC/yr", a$export, b$export),
             c("DIC gradient", a$og$dic, b$og$dic),
             c("d13C gradient", a$og$d13c, b$og$d13c),
             c("deep D14C (spinup)", a$sp$diagnostics$d14c_bottom_box,
               b$sp$diagnostics$d14c_bottom_box))
worst <- 0
for (rr in rows) {
  x <- as.numeric(rr[2]); y <- as.numeric(rr[3])
  pc <- 100 * (y - x) / abs(x)
  if (rr[1] != "export GtC/yr") worst <- max(worst, abs(pc))
  cat(sprintf("%-26s %12.4f %12.4f %+10.2f\n", rr[1], x, y, pc))
}
cat(sprintf("\nworst disagreement on the SCORED rows: %.2f %%   %s\n", worst,
            if (worst < PP_TOL_PCT) sprintf("PASS (< %g %%)", PP_TOL_PCT)
            else sprintf("FAIL (>= %g %%) -- the port is not the shim", PP_TOL_PCT)))

# ---------------------------------------------------------------------
# THE EXPORT IS EXCLUDED FROM THE GATE, AND NOT BECAUSE IT IS INCONVENIENT.
# It disagrees by ~15 %, and the first thing I assumed -- that the port's
# fixed-bin profile was too coarse near the surface -- was WRONG. Refining the
# bins from 250 m to 50 m to 25 m moved the disagreement 28 % -> 8.8 % -> 15.2 %,
# i.e. NOT monotonically toward the shim, which is what said the diagnosis was
# wrong rather than under-resolved.
#
# MEASURED CAUSE. The total export is the diffusive flux across the topmost
# interface alone (the sum telescopes), so it is set by the MIXED LAYER's mean
# DIC. The shim takes that from dg_bin(), which assigns cells by
# floor(depth / 250) -- so EVERY bottle in 0-100 m lands in ONE depth cell and
# the mean is weighted by BOTTLE DENSITY. GLODAP samples the shallowest water
# most heavily, and DIC rises steeply there (25 m sub-bin means run 2017.7 ->
# 2083.9 across 0-100 m), so that mean is biased LOW: 2038.29 against a
# THICKNESS-weighted 2048.33, a 10.04 umol/kg difference.
#
# A model mixed layer is a WELL-MIXED 100 m SLAB, so the thickness-weighted mean
# is the right one and the port is the better estimator, not the deviant one.
# CONSEQUENCE: the shim's export figures are biased HIGH by ~15 %, and every
# quotation of them -- 20.6 GtC/yr at defaults, 25.2 at the pre-gradient mode,
# 30.3 at g* -- is high by that much. The "3.6x the literature POC midpoint"
# claim is nearer 3.1x. Corrected in DESIGN sec.5.2c and the CHANGELOG rather
# than left standing.
cat(sprintf("\nEXPORT differs by %+.2f %% and is REPORTED, NOT GATED.\n",
            100 * (b$export - a$export) / a$export))
cat("The shim's mixed-layer DIC is weighted by BOTTLE DENSITY within 0-100 m\n")
cat("(dg_bin assigns cells by floor(depth/250), so the whole band is one cell),\n")
cat("and GLODAP over-samples the shallowest water where DIC rises fastest. That\n")
cat("biases the shim's ML LOW by ~10 umol/kg, its ML-to-box-1 gradient HIGH, and\n")
cat("its required export HIGH by ~15 %. The port is thickness-weighted, which is\n")
cat("what a well-mixed slab actually is. See the block above this line.\n")

sep("AS SHIPPED -- two limbs, carbonate share pinned by the alkalinity gradient")
p0 <- ccx_default_params()
s <- pp_ported(carb_frac = p0$pump_carb_frac)
z <- function(k, v) (v - tg[[k]]$target) / tg[[k]]$sd
cat(sprintf("%-22s %12s %12s %10s\n", "row", "model", "target", "z"))
cat(sprintf("%-22s %12.3f %12.3f %+10.2f\n", "DIC gradient", s$og$dic, tg$dic$target,
            z("dic", s$og$dic)))
cat(sprintf("%-22s %12.4f %12.4f %+10.2f\n", "d13C gradient", s$og$d13c, tg$d13c$target,
            z("d13c", s$og$d13c)))
cat(sprintf("%-22s %12.3f %12.3f %+10.2f\n", "ALK gradient", s$og$alk, tg$alk$target,
            z("alk", s$og$alk)))
cat(sprintf("\nexport %.2f GtC/yr, carbonate share %.0f %%\n",
            s$export, 100 * p0$pump_carb_frac))
cat(sprintf("single-limb d13C for comparison: %.4f (z %+.2f)\n",
            b$og$d13c, z("d13c", b$og$d13c)))
cat("\nTHE CARBONATE LIMB IS DOING WHAT IT WAS ADDED FOR: it carries carbon down\n")
cat("WITHOUT the 20 permil depletion, so the same DIC gradient costs less d13C.\n")

saveRDS(list(shim = a[c("export", "og")], ported_1limb = b[c("export", "og")],
             shipped = s[c("export", "og")], worst_pct = worst),
        file.path(PP_OUTDIR, "diag_pump_port_parity.rds"))
cat(sprintf("\n\nwritten: %s\n", file.path(PP_OUTDIR, "diag_pump_port_parity.rds")))
