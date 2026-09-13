# =====================================================================
# THE EQUATORIAL CELL, UNREFITTED PROBE (prereg notes/prereg_2026-09-13g_
# equatorial_cell_build.md §4: PE1, N1, PE6 -- the three predictions read
# BEFORE the array). Everything runs at the canonical VECTOR (hilda30c) with
# the "hilda_eq" structure applied on top: the same 30 fitted names, the cell's
# OBSERVED geometry (data/obs_eq_cell.rds), w_eq = 27 Sv (the W0 prior mean),
# and gamma_eq scanned. NOTHING is refitted; the ML keeps the canonical's h_ml
# while losing 4 % of its area to the cell (choice D1), so every price here is
# an UPPER bound on what the array will pay.
#
#   PE1  with w_eq = 27 Sv the solubility-only ENSO ocean r (-0.527 at
#        hilda30c) flips POSITIVE at gamma_eq <= 1.0.
#   N1   gamma_eq = 0 (a MEAN cell, no modulation): r stays at the
#        solubility-only value +/- 0.02; the cell's own sst_eq_enso term is
#        the only ENSO path left and must be SMALL (|dr| < 0.05).
#   PE6  the cells' surface d13C lands inside GLODAP's tropical surface band
#        (|lat| <= 5, <= 50 m; the Pacific mask and the whole band).
# Also read (not gated): the B1 row (model contrast, z at sigma 6.77), the
# common-row likelihood price against the solubility-only reference, the CO2
# LEVEL rows and the deep 14C rows (PE4/PE5's unrefit preview), and the
# ocean sink 2015-2023.
# THE REFERENCE is the canonical with gamma_enso_ocn_* = 0 (the additive
# ocean ENSO term OFF), as T-A1/T-A2 used: the cell REPLACES that term (PE2),
# so the fair contrast is against the model without it.
# Usage: Rscript calibration/diag_eq_cell_probe.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))
EQ_W0       <- NULL                          # Sv; NULL = the product's W0 prior mean (never typed)
EQ_GAMMA    <- c(0, 0.25, 0.5, 0.75, 1.0, 1.25)   # per Nino3.4 unit; 0 is N1
EQ_WIN      <- c(1959, 2024)                 # = SC_ENSO_WIN
EQ_N1_TOL   <- 0.02                          # N1: |r - r_ref| <= this
EQ_N1_DRMAX <- 0.05                          # N1: the sst_eq_enso-only shift must be below this
EQ_PE1_GMAX <- 1.0                           # PE1: the flip must come at gamma_eq <= this
EQ_PE6_LAT  <- 5; EQ_PE6_DEPTH <- 50; EQ_PE6_FLAG <- 2
EQ_ROW_SHOW <- 0.5
EQ_GLODAP   <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
EQ_OUT      <- ccx_path("outputs", "diagnostics", sprintf("eq_cell_probe_%s.rds", format(Sys.Date(), "%Y%m%d")))

obs_eq <- ccx_eq_cell_obs()
W0 <- if (is.null(EQ_W0)) obs_eq$w0_prior$mean_sv else EQ_W0
v <- dg_vector(CCX_MODE_CANONICAL); obs <- ccx_prepare_obs()
cat(sprintf("arm %s: %s\n  pins: %s; migrated: %s; spinup: %s\n", CCX_MODE_CANONICAL, v$src,
            if (length(v$pins)) paste(sprintf("%s=%g", names(v$pins), v$pins), collapse = ",") else "none",
            if (length(v$migrated)) paste(v$migrated, collapse = ",") else "none", v$spinup_label))
stopifnot(identical(v$spinup_label, "periodic"))   # the cell's mean state must be IN the equilibrium

en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))); en_ann <- stats::aggregate(nino34_anom ~ year, data = en, FUN = mean, na.rm = TRUE)
g <- obs$gcb; mg <- merge(g[, c("year", "ocean_sink")], en_ann, by = "year"); mg <- mg[stats::complete.cases(mg) & mg$year >= EQ_WIN[1] & mg$year <= EQ_WIN[2], ]
fo <- stats::lm(ocean_sink ~ year + nino34_anom, data = mg); OBS_SLOPE <- coef(fo)[["nino34_anom"]]
OBS_R <- stats::cor(residuals(stats::lm(ocean_sink ~ year, mg)), mg$nino34_anom)
enso_stat <- function(r) { s <- dg_annual_sinks(r); d <- merge(data.frame(year = s$year, oc = s$ocean), en_ann, by = "year")
  d <- d[d$year >= EQ_WIN[1] & d$year <= EQ_WIN[2], ]; f <- stats::lm(oc ~ year + nino34_anom, data = d)
  c(slope = coef(f)[["nino34_anom"]], se = summary(f)$coefficients["nino34_anom", 2],
    r = stats::cor(residuals(stats::lm(oc ~ year, d)), d$nino34_anom), sink = mean(s$ocean[s$year >= 2015 & s$year <= 2023])) }
cat(sprintf("GCB observed: slope %+.4f +/- %.4f GtC/yr per index, r %+.3f (n %d)\n", OBS_SLOPE, summary(fo)$coefficients["nino34_anom", 2], OBS_R, nrow(mg)))

# ---- the reference: the canonical, additive ocean ENSO term OFF ----------------
v0 <- v; v0$p$gamma_enso_ocn_NH <- 0; v0$p$gamma_enso_ocn_SH <- 0
t0 <- Sys.time(); r0 <- dg_run(v0); st0 <- unlist(dg_streams(r0, v0)); e0 <- enso_stat(r0)
cat(sprintf("%s solubility-only reference: slope %+.4f (r %+.3f), sink %.2f, lik %.2f on %d rows; %.0f s\n",
            CCX_MODE_CANONICAL, e0[["slope"]], e0[["r"]], e0[["sink"]], sum(st0), length(st0), as.numeric(Sys.time() - t0, units = "secs")))

# ---- the cell arms ----------------------------------------------------------
cell_vec <- function(gamma, w = W0) {
  ve <- v0
  ve$p <- ccx_apply_structure(ve$p, "hilda_eq", seas_ml = ve$p$seas_ml)
  ve$p$w_eq <- w; ve$p$gamma_eq <- gamma
  ve
}
tg_b1 <- ccx_eq_b1_target()
RES <- list()
for (gm in EQ_GAMMA) {
  t0 <- Sys.time(); ve <- cell_vec(gm); re <- dg_run(ve); ste <- unlist(dg_streams(re, ve)); e <- enso_stat(re)
  common <- intersect(names(ste), names(st0)); d <- ste[common] - st0[common]
  new_rows <- setdiff(names(ste), names(st0))
  b1 <- ccx_model_eq_b1(re$out[re$out$t < DG_SINK_LAST + 1, ], re$sp$aux)
  z_b1 <- (b1$value - tg_b1$target) / tg_b1$sd
  big <- names(d)[order(-abs(d))]; big <- big[abs(d[big]) > EQ_ROW_SHOW]
  lev <- sum(d[grepl("co2_level|co2_icecore", names(d))]); d14 <- d[grepl("d14c|c14", names(d))]
  # the cell's mean pCO2 excess over the ML at the spinup (the preindustrial reservoir)
  o <- re$out; pi_rows <- o$t < 1760
  pi_exc <- vapply(HEMIS, function(h) mean(o[[paste0("eq_pco2_", h)]][pi_rows] - o[[paste0("ml_pco2_", h)]][pi_rows]), numeric(1))
  cat(sprintf("  gamma_eq %.2f (W0 %.0f Sv): slope %+.4f (r %+.3f) = %.2fx obs; sink %.2f; B1 model %+.1f (NH %+.1f / SH %+.1f) z %+.2f [PI cell-ML %+.1f/%+.1f uatm]; common-row lik %+.2f [CO2-level %+.2f; gcb_ocean_sink %+.2f; max|14C| %.2f] + new rows %s; [%s]; %.0f s\n",
              gm, W0, e[["slope"]], e[["r"]], e[["slope"]] / OBS_SLOPE, e[["sink"]], b1$value, b1$by_hemi[["NH"]], b1$by_hemi[["SH"]], z_b1, pi_exc[["NH"]], pi_exc[["SH"]],
              sum(d), lev, d[["gcb_ocean_sink"]], if (length(d14)) max(abs(d14)) else 0,
              paste(sprintf("%s %+.2f", new_rows, ste[new_rows]), collapse = ", "),
              if (length(big)) paste(sprintf("%s %+.2f", big, d[big]), collapse = ", ") else sprintf("no row > %g", EQ_ROW_SHOW),
              as.numeric(Sys.time() - t0, units = "secs")))
  RES[[sprintf("g%.2f", gm)]] <- list(gamma = gm, w0 = W0, slope = e[["slope"]], se = e[["se"]], r = e[["r"]], sink = e[["sink"]],
                                       b1 = b1, z_b1 = z_b1, pi_excess = pi_exc, dlik_common = sum(d), lev = lev,
                                       sink_row = d[["gcb_ocean_sink"]], d14max = if (length(d14)) max(abs(d14)) else 0,
                                       rows = d, new_rows = ste[new_rows], run = if (gm == 1.0) re else NULL)
}
# N1b -- the ATTRIBUTION control for N1: the mean cell with its own Nino3.4 SST
# slope switched off. If r returns to the solubility-only value, the whole of
# N1's shift is the cell's local solubility term (a PHYSICAL term the observed
# +0.115 net also contains), not the index leaking through the loop or the
# reader. Not a prereg prediction; added after the first read (2026-09-13g).
vn <- cell_vec(0); vn$p$sst_eq_enso <- 0
rn <- dg_run(vn); en1b <- enso_stat(rn)
cat(sprintf("  N1b gamma_eq 0 AND sst_eq_enso 0: slope %+.4f (r %+.3f) -- vs solubility-only r %+.3f\n", en1b[["slope"]], en1b[["r"]], e0[["r"]]))
T <- do.call(rbind, lapply(RES, function(x) data.frame(gamma = x$gamma, slope = x$slope, r = x$r, sink = x$sink, b1 = x$b1$value, z_b1 = x$z_b1,
                                                         dlik_common = x$dlik_common, lev = x$lev, sink_row = x$sink_row, d14max = x$d14max)))

# ---- PE6: the cells' surface d13C against GLODAP's tropical surface band -----
gl <- utils::read.csv(EQ_GLODAP)
gl <- gl[gl$c13 > -9000 & gl$c13f == EQ_PE6_FLAG & abs(gl$lat) <= EQ_PE6_LAT & gl$depth <= EQ_PE6_DEPTH, ]
lon360 <- (gl$lon %% 360); lw <- obs_eq$consts$lon %% 360           # the product's mask: 160E..80W = 160..280
pac <- lon360 >= lw[1] & lon360 <= lw[2]
band_stat <- function(x) c(mean = mean(x$c13), sd = stats::sd(x$c13), n = nrow(x), yr = mean(x$year))
PAC <- band_stat(gl[pac, ]); ALL <- band_stat(gl)
re1 <- RES[["g1.00"]]$run
d13c_cell_at <- function(o, yr) { j <- which(o$t >= yr - 0.5 & o$t < yr + 0.5)
  vapply(HEMIS, function(h) mean(1000 * (o[[paste0("eq_C13_", h)]][j] / o[[paste0("eq_C_", h)]][j] / ccx_const("R13_VPDB") - 1)), numeric(1)) }
d13c_ml_at <- function(o, yr) { j <- which(o$t >= yr - 0.5 & o$t < yr + 0.5)
  vapply(HEMIS, function(h) mean(1000 * (o[[paste0("ml_C13_", h)]][j] / o[[paste0("ml_C_", h)]][j] / ccx_const("R13_VPDB") - 1)), numeric(1)) }
m_cell <- d13c_cell_at(re1$out, round(PAC[["yr"]])); m_ml <- d13c_ml_at(re1$out, round(PAC[["yr"]]))
PE6 <- all(m_cell >= PAC[["mean"]] - 2 * PAC[["sd"]] & m_cell <= PAC[["mean"]] + 2 * PAC[["sd"]])
cat(sprintf("\nPE6 surface d13C at %d: GLODAP Pacific band (|lat|<=%g, <=%g m, flag %d) %.2f +/- %.2f permil (n %d); whole tropical band %.2f +/- %.2f (n %d)\n     model cell NH %.2f / SH %.2f (ML %.2f / %.2f) at gamma_eq 1 -> %s (inside the Pacific band's 2 sd)\n",
            round(PAC[["yr"]]), EQ_PE6_LAT, EQ_PE6_DEPTH, EQ_PE6_FLAG, PAC[["mean"]], PAC[["sd"]], PAC[["n"]], ALL[["mean"]], ALL[["sd"]], ALL[["n"]],
            m_cell[["NH"]], m_cell[["SH"]], m_ml[["NH"]], m_ml[["SH"]], if (PE6) "PASS" else "FAIL"))

# ---- verdicts ----------------------------------------------------------------
cat("\n=== VERDICTS (prereg 2026-09-13g §4, unrefitted at", CCX_MODE_CANONICAL, ") ===\n")
n1 <- RES[["g0.00"]]; N1 <- abs(n1$r - e0[["r"]]) <= EQ_N1_TOL
cat(sprintf("  N1  gamma_eq = 0: r %+.3f vs solubility-only %+.3f (dr %+.3f; tol %.2f, sst_eq_enso-only bound %.2f): %s\n",
            n1$r, e0[["r"]], n1$r - e0[["r"]], EQ_N1_TOL, EQ_N1_DRMAX, if (N1) "PASS" else if (abs(n1$r - e0[["r"]]) < EQ_N1_DRMAX) "MARGINAL (inside the sst_eq_enso bound, outside tol)" else "FAIL -- the mean cell leaks the index"))
N1b <- abs(en1b[["r"]] - e0[["r"]]) <= EQ_N1_TOL
cat(sprintf("  N1b with sst_eq_enso = 0 as well: r %+.3f (dr %+.3f): %s\n", en1b[["r"]], en1b[["r"]] - e0[["r"]],
            if (N1b) "the N1 shift IS the cell's own solubility term, entirely" else "the shift is NOT the solubility term alone -- something else carries the index"))
pos <- T$gamma[T$r > 0]; g_flip <- if (length(pos)) min(pos) else NA
# the linear-interpolated zero crossing of r(gamma), for the record
cr <- if (any(T$r > 0) && any(T$r < 0)) { i <- max(which(T$r < 0 & c(T$r[-1] > 0, FALSE))); T$gamma[i] + (0 - T$r[i]) * (T$gamma[i + 1] - T$gamma[i]) / (T$r[i + 1] - T$r[i]) } else NA
PE1 <- !is.na(g_flip) && g_flip <= EQ_PE1_GMAX
cat(sprintf("  PE1 r flips positive at gamma_eq %s (interpolated crossing %s; bound %.2f): %s\n",
            if (is.na(g_flip)) "NEVER in the scan" else sprintf("%.2f", g_flip), if (is.na(cr)) "n/a" else sprintf("%.2f", cr), EQ_PE1_GMAX,
            if (PE1) "PASS" else "FAIL"))
# where the OBSERVED slope is reached, by interpolation on the scan
g_obs <- if (any(T$slope >= OBS_SLOPE)) { i <- max(which(T$slope < OBS_SLOPE & c(T$slope[-1] >= OBS_SLOPE, FALSE))); if (length(i)) T$gamma[i] + (OBS_SLOPE - T$slope[i]) * (T$gamma[i + 1] - T$gamma[i]) / (T$slope[i + 1] - T$slope[i]) else NA } else NA
cat(sprintf("  the observed slope %+.4f is reached at gamma_eq ~ %s (PE7's fitted range is [0.4, 1.1]; the 1997-99 bracket 0.5-0.9)\n", OBS_SLOPE, if (is.na(g_obs)) "beyond the scan" else sprintf("%.2f", g_obs)))
cat(sprintf("  B1 at W0 %.0f Sv, unrefitted: model %+.1f vs %+.1f +/- %.2f (z %+.2f at gamma_eq 1) -- PE8 reads this AFTER the fit, not here\n", W0, RES[["g1.00"]]$b1$value, tg_b1$target, tg_b1$sd, RES[["g1.00"]]$z_b1))
print(T, row.names = FALSE, digits = 4)
for (x in RES) x$run <- NULL
saveRDS(list(table = T, res = lapply(RES, function(x) { x$run <- NULL; x }), ref = list(streams = st0, enso = e0), obs = list(slope = OBS_SLOPE, r = OBS_R, n = nrow(mg)),
             pe6 = list(pacific = PAC, all = ALL, model_cell = m_cell, model_ml = m_ml, pass = PE6),
             verdicts = list(N1 = N1, N1b = N1b, n1b_enso = en1b, PE1 = PE1, g_flip = g_flip, g_cross = cr, g_obs = g_obs, PE6 = PE6),
             w0 = W0, gamma = EQ_GAMMA, mode = CCX_MODE_CANONICAL, src = v$src, pins = v$pins,
             prereg = "notes/prereg_2026-09-13g_equatorial_cell_build.md", date = Sys.time()), EQ_OUT)
cat("saved", EQ_OUT, "\n")
