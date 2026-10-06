# =====================================================================
# diag_d4_readout.R -- D4, the canonical's modern NPP against the ruled target,
# with the N-retention flux QUOTED BESIDE IT (Marcus 2026-10-01, review 10-01c
# B1: "Do the recommendation" = keep the readout EXCLUSIVE and quote the
# retained flux next to it).
#
# WHY A DRIVER. D4's numbers (67.67, z +1.50; the gross flux 0.498) were read on
# 10-01 (c) inside the #14 refit reader, under the SPLINE emissions
# interpolation. The 10-01 (k) flip to piecewise-constant moved every stored
# logpost; this re-reads D4 at the canonical as it now stands, for the B8
# assessment record, with its provenance.
#
# THE TWO READOUTS (CHANGELOG 10-01 c, choice 4):
#   exclusive (RULED): GPP - Ra + the ENSO term -- the model's `npp` readout
#     (ccx_run_fast()$npp, the one the likelihood's npp_modern row reads);
#   inclusive (NOT ruled, printed for the record): + ndep_ret x 1e-3 x the land
#     N deposition, the GROSS retention flux into soil_slow.
# Output: outputs/diagnostics/d4_readout_<date>.{log,csv}. No RNG.
# Usage: Rscript calibration/diag_d4_readout.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
D4_DRIVER <- "calibration/diag_d4_readout.R"
D4_OUT <- ccx_path("outputs", "diagnostics", sprintf("d4_readout_%s", format(Sys.Date(), "%Y%m%d")))
D4_GTC_PER_KGC_TGN <- 1e-3     # ndep_ret [kg C / kg N] x deposition [Tg N / yr] -> GtC / yr
D4_COMMIT <- ccx_git_stamp()

md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
pm <- ccx_mode_par_with_pins(md)
rp <- ccx_mode_run_params(md, pm, base = ccx_mode_base(md))   # the app's own mapping, the file's own structure
sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(rp$p)
tg <- ccx_npp_modern_target()
F  <- ccx_build_forcing("historical", c(1750, tg$win[2]), prod_c14 = sp$prod_c14,
                        bomb_total_kmol = rp$bomb_total, luc_scale = rp$luc_scale,
                        enso_index = ccx_enso_index_of(rp$p), aod_mode = ccx_aod_mode_of(rp$p))
r  <- ccx_run_fast(sp, F)
kn <- floor(r$npp$t) >= tg$win[1] & floor(r$npp$t) <= tg$win[2]
npp_excl <- mean(r$npp$npp_NH[kn] + r$npp$npp_SH[kn])
kf <- floor(F$t) >= tg$win[1] & floor(F$t) <= tg$win[2]
dep <- mean(F$ndep_NH[kf] + F$ndep_SH[kf])                  # Tg N / yr on land
ret <- pm$ndep_ret * D4_GTC_PER_KGC_TGN * dep                 # the GROSS retention flux, GtC / yr
z <- function(x) (x - tg$centre) / tg$sd

sink(paste0(D4_OUT, ".log"), split = TRUE)
cat(sprintf("=== %s @%s, run %s ===\n", D4_DRIVER, D4_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("mode %s; emissions interpolation \"%s\"; target %.2f +/- %.2f GtC/yr over %d-%d\n",
            CCX_MODE_CANONICAL, CCX_EMIS_METHOD_DEFAULT, tg$centre, tg$sd, tg$win[1], tg$win[2]))
cat(sprintf("D4 (exclusive, RULED): modern NPP %.2f GtC/yr, z %+.2f\n", npp_excl, z(npp_excl)))
cat(sprintf("  beside it: %+.2f GtC/yr retained via N deposition (GROSS: ndep_ret %.2f kg C/kg N x %.1f Tg N/yr)\n",
            ret, pm$ndep_ret, dep))
cat(sprintf("  (inclusive, not ruled: %.2f, z %+.2f)\n", npp_excl + ret, z(npp_excl + ret)))
sink()
utils::write.csv(data.frame(mode = CCX_MODE_CANONICAL, emis_method = CCX_EMIS_METHOD_DEFAULT,
                            win0 = tg$win[1], win1 = tg$win[2], target = tg$centre, target_sd = tg$sd,
                            npp_exclusive = npp_excl, z_exclusive = z(npp_excl),
                            ndep_ret = pm$ndep_ret, ndep_TgN = dep, retention_gross_GtC = ret,
                            npp_inclusive = npp_excl + ret, z_inclusive = z(npp_excl + ret),
                            driver = D4_DRIVER, commit = D4_COMMIT),
                 paste0(D4_OUT, ".csv"), row.names = FALSE)
