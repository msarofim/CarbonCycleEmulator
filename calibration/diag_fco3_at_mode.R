# =====================================================================
# diag_fco3_at_mode.R -- RE-MEASURE ALPHA_AS_FCO3 at a mode (2026-10-13)
#
# WHY. R/constants.R ALPHA_AS_FCO3 = 0.082 is the surface [CO3=]/DIC that Zhang et al.
# (1995)'s eps_DIC-g = a*T*fCO3 + b*T + c HOLDS FIXED instead of solving per step. It
# was measured "at the 25-parameter mode's own surface state (NH 0.0856, SH 0.0786)" -- an
# ancestral mode, on the legacy alkalinity and carbonate table. The citation rulings
# (notes/citation_rulings_2026-10-12.md) say: re-measure it at the new mode. Its whole
# contribution is a*T*fCO3 ~ 0.020 permil, so this is a provenance check, not a fit.
#
# HOW. THE MODEL'S OWN SURFACE STATE (M): ccx_run()'s edge_fn hook hands over the air-sea driving
#       pCO2 and SST at each month's OPENING state, the (y, t) the first RK4 stage evaluates
#       (ccx_deriv(record = TRUE): the seasonal SST, the
#       seasonal mixed-layer mass and the SH entrainment channel all feed it). DIC is
#       recovered by inverting the model's own pco2_from_dic() at the label's ALK and
#       carbonate table, then fCO3 = K1 K2 / (h^2 + K1 h + K1 K2). Under seas_ml 1 a static
#       mass would mis-read the concentration ([[seasonal_box_observable_artefact]]); (M)
#       never divides by a mass. Averaged over the window's 12 months.
#   Windows: the last full year of the historical run (CO3 falls as DIC rises) and the
#   spun-up 1750 year. The 0.082 was taken at the run's END (present day), so 2024 is its
#   like-for-like epoch; the constant is applied at EVERY epoch, so which one it should
#   represent is a methodological choice, reported here and not made.
# ⛔ TRIED AND DROPPED (2026-10-13, the first run of this driver): the LEGACY RECIPE of
#   diag_alpha_as_up_precheck.R section 1 -- the run's last MONTHLY row of ML carbon over the
#   STATIC mixed-layer mass, at the annual-mean SST. At a seas_ml 1 mode it read SH 0.616 at
#   hilda31w (seawater runs ~0.05-0.15): December's austral-summer layer is thin, so its
#   carbon over the annual-mean mass reads DIC far too low. It was valid when the 0.082 was
#   measured (seas_ml 0); it is the seasonal-box artifact here, so it is not reported.
# No RNG. Output: outputs/diagnostics/fco3_at_mode_<date>.{log,rds} (provenance in the rds).
# =====================================================================
for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))

FC_MODES  <- strsplit(Sys.getenv("CCX_FC_MODES", "hilda29e,hilda31w"), ",")[[1]]
FC_YEARS  <- c(1750, 2024)
FC_WINDOWS <- list(preindustrial = 1750, present = 2024)
FC_SHIPPED <- ccx_const("ALPHA_AS_FCO3")
FC_DATE   <- format(Sys.Date(), "%Y%m%d")
FC_OUT    <- file.path("outputs", "diagnostics", sprintf("fco3_at_mode_%s", FC_DATE))

fco3_of <- function(h, k) (k$K1 * k$K2) / (h^2 + k$K1 * h + k$K1 * k$K2)
dic_from_pco2 <- function(pco2, alk, sst, k)
  stats::uniroot(function(d) pco2_from_dic(d, alk, sst, k = k) - pco2, c(1.0e-3, 3.5e-3), tol = 1e-14)$root

measure <- function(mode) {
  v  <- dg_vector(mode); sp <- dg_spinup(v); p <- v$p
  F  <- withCallingHandlers(
    ccx_build_forcing("historical", FC_YEARS, prod_c14 = sp$prod_c14, bomb_total_kmol = v$bomb_total,
                      luc_scale = v$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p),
                      nuc_share = ccx_nuc_share_of(p)),
    warning = function(w) if (grepl("held FLAT", conditionMessage(w))) invokeRestart("muffleWarning"))
  aux <- ccx_prepare(p, ccx_grid_of(p)); alk <- ccx_aux_alk(aux); cc <- ccx_aux_carb(aux)
  yr  <- floor(F$t + 1e-9)
  res <- list()
  # (M) the model's own recorded surface state, per window
  for (w in names(FC_WINDOWS)) {
    y0 <- FC_WINDOWS[[w]]
    s  <- sp
    if (y0 > FC_YEARS[1]) {
      k0 <- which(yr == y0)[1] - 1L
      F1 <- F[seq_len(k0), ]
      s$y <- ccx_run_fast(sp, F1)$state
      s$enso_hist <- ccx_enso_hist_after(F1$enso, sp$enso_hist)
      if (ccx_mix_on(sp$params)) s$tdeep0 <- ccx_mix_tdeep_after(F1$gmst, F1$t, sp$params, sp$tdeep0)
    }
    Fw <- F[yr == y0, ]
    r  <- ccx_run(s, Fw, edge_fn = function(fl, y, t) list(pco2 = fl$pco2_ml, sst = fl$sst_ml, t = t))
    tr <- r$edge_trace
    m <- vapply(HEMIS, function(h) {
      f <- vapply(tr, function(e) {
        k <- carb_constants(e$sst[[h]], cc)
        d <- dic_from_pco2(e$pco2[[h]], alk, e$sst[[h]], k)
        fco3_of(h_from_dic_alk(d, alk, e$sst[[h]], k = k), k)
      }, 0)
      c(mean = mean(f), min = min(f), max = max(f), n = length(f))
    }, numeric(4))
    res[[w]] <- m
  }
  res$struct <- ccx_mode_struct(ccx_mode_file(mode)); res$md5 <- unname(tools::md5sum(ccx_mode_file(mode)))
  res$alk <- alk; res$carb_file <- if (is.null(aux$carb_cc)) "legacy carb_coefs()" else "the label's table"
  res
}

cat(sprintf("=== ALPHA_AS_FCO3 re-measured (shipped %.3f) -- %s, %s ===\n", FC_SHIPPED, ccx_git_stamp(), FC_DATE))
out <- list()
for (m in FC_MODES) {
  r <- measure(m); out[[m]] <- r
  cat(sprintf("\n%s (%s; ALK %.1f umol/kg, %s)\n", m, r$struct, r$alk * 1e6, r$carb_file))
  for (w in names(FC_WINDOWS)) {
    x <- r[[w]]
    cat(sprintf("  (M) model's own state, %-13s NH %.4f [%.4f, %.4f]  SH %.4f [%.4f, %.4f]  mean %.4f  (%d months)\n",
                paste0(FC_WINDOWS[[w]], ":"), x["mean", "NH"], x["min", "NH"], x["max", "NH"],
                x["mean", "SH"], x["min", "SH"], x["max", "SH"], mean(x["mean", ]), as.integer(x["n", "NH"])))
  }
}
a <- ccx_const("ALPHA_AS_ZHANG_A")
cat(sprintf("\nWorth: a x T x dfCO3 with a = %.4f permil/K: per 0.01 of fCO3 at 17 degC, %.4f permil (of an ~8.7 permil eps_DIC-g).\n",
            a, a * 17 * 0.01))
saveRDS(list(modes = out, shipped = FC_SHIPPED,
             provenance = list(driver = "calibration/diag_fco3_at_mode.R", commit = ccx_git_stamp(), date = FC_DATE,
                               modes = FC_MODES, years = FC_YEARS, windows = FC_WINDOWS, rng = "none",
                               units = "fCO3 = [CO3=]/DIC, dimensionless")),
        paste0(FC_OUT, ".rds"))
cat("wrote", paste0(FC_OUT, ".rds"), "\n")
