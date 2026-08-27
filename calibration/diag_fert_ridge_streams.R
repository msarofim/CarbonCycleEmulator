# =====================================================================
# diag_fert_ridge_streams.R -- WHICH LIKELIHOOD STREAM REJECTS A STRONGLY
#                              SATURATING FERTILISATION?  (2026-08-25)
#
# diag_fert_ridge_gates.R found that travelling along the (beta_max, fert_k)
# ridge to STRONG saturation, at fixed present-day NPP enhancement, fixes three
# structural gates at once:
#
#   gate 4  decadal AF trend  -0.0007 -> +0.0163 (target +0.0148); sd 0.019 ->
#           0.040 (target 0.048); r(obs) -0.06 -> +0.57
#   gate 7  land sink  +2.12 sigma -> +0.74 sigma, i.e. INSIDE
#   gate 12 integrated IRF 11.69/23.81/39.06 -> 13.15/28.08/47.64, i.e. INSIDE
#           at all three horizons for the first time at any fitted vector
#   FACE    predicted response 13.6 % -> 3.8 %, i.e. into the mature-forest
#           range Marcus 2026-08-25 named as the relevant end
#
# AND IT COSTS 8657 LOG-UNITS. That number is the whole finding: the likelihood
# rejects, hard, the cell that satisfies every structural check. One of three
# things is true and they have different consequences, so the stream
# decomposition is not optional --
#
#   (a) a stream is genuinely in physical conflict with the AF trend, in which
#       case the model has a real internal contradiction to report;
#   (b) a stream is over-weighted or mis-specified, in which case the objective
#       is wrong and the gates are right;
#   (c) the cost is an artefact of freezing 19 other parameters, in which case
#       only a refit settles it (memory ccx_seas_q10_ridge: beta_max/fert_k
#       absorbed 85 % of exactly this kind of frozen cost for q10 -- but here
#       those two are the ones being MOVED, so that particular absorber is
#       unavailable and the rest of the vector has to do it).
#
# This file cannot distinguish (c) from (a)/(b) -- only a refit can. What it CAN
# do is name the streams, which decides whether a refit is even worth running
# and what it should hold.
#
# NO IRF HERE, so it is cheap: the historical run and ccx_loglik(by_stream) only.
#
# Usage:  Rscript calibration/diag_fert_ridge_streams.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

FS_MODE_FILE <- ccx_mode_file()
FS_YEARS     <- c(1750, 2024)
FS_CHI_NOW   <- 420
FS_KGRID     <- c(60, 120, 250, 400)
OUTDIR       <- ccx_path("calibration", "output", "fert_ridge_gates")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)
CHI0 <- ccx_const("CO2_PI_PPM")

md <- readRDS(FS_MODE_FILE)
stopifnot(identical(md$param_names, CCX_PARAM_NAMES))
P0 <- ccx_default_params()
for (n in intersect(names(P0), CCX_PARAM_NAMES)) P0[[n]] <- md$par_mode[[n]]
P0$gamma_enso <- md$par_mode$gamma_enso
P0$pump_mode  <- md$pump_mode
ERR0 <- list(sigma_d14c = md$par_mode$sigma_d14c, rep_dC = md$par_mode$rep_dC,
             grad_off_co2 = md$par_mode$grad_off_co2, grad_off_d13c = md$par_mode$grad_off_d13c)
LUC0 <- md$par_mode$luc_scale; BOMB0 <- md$par_mode$bomb_total
OBS  <- ccx_prepare_obs()
d_now <- FS_CHI_NOW - CHI0
ENH0  <- P0$beta_max * d_now / (P0$fert_k + d_now)

fs_streams <- function(p) {
  sp <- ccx_spinup(p)
  F  <- ccx_build_forcing("historical", FS_YEARS, prod_c14 = sp$prod_c14,
                          bomb_total_kmol = BOMB0, luc_scale = LUC0)
  o  <- ccx_run_fast(sp, F)$out
  unlist(ccx_loglik(o, OBS, ERR0, luc = ccx_forcing_eluc_annual(F),
                    deep = sp$diagnostics$d14c_bottom_box,
                    ocean_grad = ccx_ocean_grad_scored(o, sp), by_stream = TRUE))
}

cat(sprintf("\n=== WHICH STREAM REJECTS STRONG SATURATION? ===\n"))
cat(sprintf("ridge held at enh(%d ppm) = %.4f; mode fert_k %.1f / beta_max %.4f\n\n",
            FS_CHI_NOW, ENH0, P0$fert_k, P0$beta_max))
S0 <- fs_streams(P0)
S  <- lapply(FS_KGRID, function(K) {
  p <- P0; p$fert_k <- K; p$beta_max <- ENH0 * (K + d_now) / d_now; fs_streams(p)
})
names(S) <- sprintf("K=%g", FS_KGRID)

D <- vapply(S, function(s) s[names(S0)] - S0, numeric(length(S0)))
ord <- order(D[, 1])
cat(sprintf("%-22s %10s | %s\n", "stream", "mode logL",
            paste(sprintf("%10s", colnames(D)), collapse = "")))
for (nm in names(S0)[ord]) {
  if (max(abs(D[nm, ])) < 0.5) next
  cat(sprintf("%-22s %10.1f | %s\n", nm, S0[[nm]],
              paste(sprintf("%+10.1f", D[nm, ]), collapse = "")))
}
cat(sprintf("%-22s %10.1f | %s\n", "TOTAL", sum(S0),
            paste(sprintf("%+10.1f", colSums(D)), collapse = "")))
cat(sprintf("%-22s %10s | %s\n", "  of which SEASONAL", "",
            paste(sprintf("%+10.1f", colSums(D[grepl("seas", rownames(D)), , drop = FALSE])),
                  collapse = "")))
cat(sprintf("%-22s %10s | %s\n", "  of which NON-seasonal", "",
            paste(sprintf("%+10.1f", colSums(D[!grepl("seas", rownames(D)), , drop = FALSE])),
                  collapse = "")))

saveRDS(list(S0 = S0, S = S, D = D, enh0 = ENH0, kgrid = FS_KGRID),
        file.path(OUTDIR, "fert_ridge_streams.rds"))
cat(sprintf("\nwritten: %s\n", file.path(OUTDIR, "fert_ridge_streams.rds")))
