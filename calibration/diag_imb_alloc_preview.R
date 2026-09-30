# =====================================================================
# diag_imb_alloc_preview.R -- WHAT WOULD D3 DO AT A FIXED VECTOR? (2026-09-30 i)
#
# Ruling D3 (Marcus 2026-09-30): "For the GCB budget imbalance: the calibration
# should have freedom to move it where it helps the model solve best." The
# proposed form (handoff 09-30b sec.3 step 3) replaces the two GCB sink rows'
# targets with
#     land   target = GCB_land  + s_land  * I(t)
#     ocean  target = GCB_ocean + s_ocean * I(t)
# with s_land, s_ocean >= 0 and s_land + s_ocean <= 1 (the rest of I is "not a
# sink error", i.e. an emissions or growth error, which in the model can only
# be carried by luc_scale). I(t) is GCB's budget imbalance, treated one of
# several ways -- the choice Marcus has to make, so this driver prices each.
#
# WHAT THIS IS: a PREVIEW at ONE fixed parameter vector (the alignment screen's
# control). No fit. For each treatment of I(t) it reports the shares that
# maximise the two rows, their standard errors, the rows' log-likelihood gain,
# and how much of the share estimate comes from the imbalance's LEVEL versus its
# INTERANNUAL noise. It bounds nothing about a refit (which moves every other
# parameter too); it says what the new rows would ask for at today's fit.
#
# GATES (stop, not warn):
#   G1 IDENTITY: the control's logpost equals its stored optimum (as the screen).
#   G2 ROWS: this driver's own reconstruction of `gcb_land_sink` and
#      `gcb_ocean_sink` at s = 0 equals the objective's by-stream values.
#   G3 OPTIMUM: the analytic constrained optimum is no worse than a brute-force
#      grid over the simplex (so the projection algebra is checked, not trusted).
#   G4 IDENTITY OF THE BUDGET: the five-term decomposition closes to its
#      numerical floor (reported; gated at 10 % of d_land, the 09-24 rule).
#
# CONTROL: diag_alignment_screen.R's -- hilda_csl3v0kai at v0k basin 1, the
# (v) D carve-out re-fit (tau 500, 11 names rebalanced), rescored under the label.
# No RNG. USAGE: Rscript calibration/diag_imb_alloc_preview.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
IA_DRIVER <- "calibration/diag_imb_alloc_preview.R"
IA_TAG    <- "imb_alloc_preview"
IA_DATE   <- format(Sys.Date(), "%Y%m%d")
IA_OUT    <- ccx_path("outputs", "diagnostics", sprintf("%s_%s", IA_TAG, IA_DATE))
# the alignment screen's control, verbatim (calibration/diag_alignment_screen.R)
IA_MODE   <- ccx_path("calibration", "output",
  "multistart_20260928c_hilda_csl3v0k_seasml1_pin_ent_seas_amp_SH=0_w_eq=27_gamma_eq=1_pump_export=9.08_w_vent=0_gamma_vent=0_w_thc=0_gamma_enso_ocn_NH=0_gamma_enso_ocn_SH=0_sd1.0452",
  "promoted_basin1", "mode_fit_pumpN.rds")
IA_STRUCT <- "hilda_csl3v0kai"
IA_CTRL_PROFILE <- ccx_path("outputs", "diagnostics", "tau_soil_slow_profile_fixedstock_stock8053_20260929.rds")
IA_CTRL_VALUE   <- 500
IA_FEX_PROXY    <- 0.8053
IA_FREE11 <- c("beta_max", "fert_k", "luc_scale", "q10", "seas_T_amp_NH", "seas_T_amp_SH",
               "seas_lag_p_NH", "seas_lag_p_SH", "npp_frac_NH", "kz", "rep_dC")
IA_ID_TOL  <- 1e-3        # G1, the screen's tolerance
IA_ROW_TOL <- 1e-6        # G2, log-units: the two forcing paths are exact by test-luc-scale.R
IA_GRID    <- 0.002       # G3 simplex grid step
IA_SMOOTH_YR <- 11L       # centred window, = the app's APP_LUC_SMOOTH_YR (app/global.R)
IA_WINDOWS <- list(c(1959L, 2024L), c(1960L, 1989L), c(1990L, 2009L), c(2010L, 2024L))
# the treatments of I(t) priced here -- the choice put to Marcus
IA_TREAT <- c(RAW = "annual imbalance as published",
              SMOOTH = sprintf("%d-yr centred running mean, window shrinks at the ends", IA_SMOOTH_YR),
              CONST = "full-period (1959-2024) mean, a pure level shift",
              RAW_CEM = "annual imbalance + cement carbonation sink",
              SMOOTH_CEM = sprintf("%d-yr smooth of (imbalance + cement)", IA_SMOOTH_YR),
              CONST_CEM = "full-period mean of (imbalance + cement)")
COMMIT <- tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) "?")
DIRTY  <- tryCatch(length(system("git status --porcelain -- R src data calibration", intern = TRUE)) > 0, error = function(e) NA)

# ---- the control (as diag_alignment_screen.R builds it) -----------------------
md <- readRDS(ccx_mode_file(IA_MODE)); invisible(ccx_apply_pins(md$pins))
cp <- readRDS(IA_CTRL_PROFILE); ctrl <- cp[[which(vapply(cp, `[[`, numeric(1), "value") == IA_CTRL_VALUE)]]
bp <- ccx_mode_base(md); bp$pump_mode <- md$pump_mode
bp <- ccx_apply_structure(bp, IA_STRUCT, as.character(md$seas_ml), pump_field = md$pump_field)
for (n in names(md$pins)) bp[[n]] <- md$pins[[n]]
for (n in names(ctrl$over)) bp[[n]] <- ctrl$over[[n]]
bp$litter_slow_frac <- ctrl$over$litter_slow_frac / IA_FEX_PROXY
stopifnot(isTRUE(ccx_inert_on(bp)), abs(bp$litter_slow_frac - 0.05) < 1e-12)
p0 <- as.list(ccx_unc_to_par(md$u_mode)); for (n in IA_FREE11) p0[[n]] <- ctrl$par[[n]]
u_ctrl <- ccx_par_to_unc(unlist(p0)[md$param_names])

# G1
lp <- ccx_make_logpost(base_params = bp, by_stream = TRUE)
l_ctrl <- lp(u_ctrl); st <- attr(l_ctrl, "streams")
id_d <- as.numeric(l_ctrl) - ctrl$opt
if (abs(id_d) > IA_ID_TOL) stop(sprintf("G1 FAIL: control logpost %.6f vs stored %.6f", as.numeric(l_ctrl), ctrl$opt))

# ---- the run, and the objective's own annual sinks ----------------------------
pv <- ccx_unc_to_par(u_ctrl); p <- ccx_overlay_par(bp, pv)
sp <- ccx_spinup_from_label(ccx_mode_spinup(md))(p)
F  <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = sp$prod_c14, bomb_total_kmol = pv$bomb_total,
                        luc_scale = pv$luc_scale, enso_index = ccx_enso_index_of(p), aod_mode = ccx_aod_mode_of(p))
r  <- ccx_run_fast(sp, F); out <- r$out
el <- ccx_forcing_eluc_annual(F)
# ⚠ VERBATIM the likelihood's estimator (R/likelihood.R, "GCB sinks: PARTITION only"):
# stocks interpolated to calendar-year boundaries, linear extrapolation at the ends.
yrs <- sort(unique(floor(out$t + 1e-9))); bnd <- c(yrs, max(yrs) + 1L)
tt <- out$t; nt <- length(tt)
stock_at <- function(v) {
  y  <- stats::approx(tt, v, xout = bnd)$y
  lo <- bnd < tt[1]; hi <- bnd > tt[nt]
  if (any(lo)) y[lo] <- v[1] + (bnd[lo] - tt[1]) * (v[2] - v[1]) / (tt[2] - tt[1])
  if (any(hi)) y[hi] <- v[nt] + (bnd[hi] - tt[nt]) * (v[nt] - v[nt - 1]) / (tt[nt] - tt[nt - 1])
  y
}
atm_C <- (out$co2_NH + out$co2_SH) * (ccx_const("GtC_PER_PPM") / 2)
flux <- data.frame(year = utils::head(bnd, -1), ocean = diff(stock_at(out$ocean_C)),
                   land = diff(stock_at(out$land_C)), grow = diff(stock_at(atm_C)))
gcb <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$budget)
g <- merge(gcb, flux, by = "year"); g <- merge(g, data.frame(year = el$year, eluc = el$eluc), by = "year")
g$land_resid <- g$land + g$eluc                       # the model's RESIDUAL land sink
n <- nrow(g)

# G2 -- the rows at s = 0 must be the objective's rows
row_l <- function(s, I) sum(stats::dnorm(g$land_sink + s * I, g$land_resid, LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE, log = TRUE))
row_o <- function(s, I) sum(stats::dnorm(g$ocean_sink + s * I, g$ocean, LIK_GCB_OCEAN_SD, log = TRUE))
g2 <- c(land = row_l(0, 0) - st[["gcb_land_sink"]], ocean = row_o(0, 0) - st[["gcb_ocean_sink"]])
if (any(abs(g2) > IA_ROW_TOL)) stop(sprintf("G2 FAIL: rows differ from the objective's by %s", paste(signif(g2, 3), collapse = " / ")))

# ---- the imbalance treatments -------------------------------------------------
smooth_shrink <- function(v, k = IA_SMOOTH_YR) {
  h <- (k - 1L) %/% 2L
  vapply(seq_along(v), function(i) mean(v[max(1L, i - h):min(length(v), i + h)]), numeric(1))
}
imb <- g$imbalance; cem <- g$cement_carbonation
I_of <- list(RAW = imb, SMOOTH = smooth_shrink(imb), CONST = rep(mean(imb), n),
             RAW_CEM = imb + cem, SMOOTH_CEM = smooth_shrink(imb + cem), CONST_CEM = rep(mean(imb + cem), n))
stopifnot(identical(names(I_of), names(IA_TREAT)))

sl <- LIK_GCB_LAND_SD * LIK_LAND_SINK_INFLATE; so <- LIK_GCB_OCEAN_SD
r_l <- g$land_resid - g$land_sink; r_o <- g$ocean - g$ocean_sink   # model minus GCB
# constrained weighted LS on {s_l >= 0, s_o >= 0, s_l + s_o <= 1}; the two rows are
# independent Gaussians, so the objective is a_l (s_l - sl*)^2 + a_o (s_o - so*)^2 + const
share_opt <- function(I) {
  II <- sum(I^2); a_l <- II / sl^2; a_o <- II / so^2
  s_l <- sum(r_l * I) / II; s_o <- sum(r_o * I) / II
  un <- c(s_l, s_o)
  cl <- function(x) min(max(x, 0), 1)
  c1 <- c(cl(s_l), cl(s_o))
  if (sum(c1) > 1) {                     # project onto s_l + s_o = 1 in the a-metric
    x <- cl((a_l * s_l + a_o * (1 - s_o)) / (a_l + a_o)); c1 <- c(x, 1 - x)
  }
  list(unconstrained = un, s = c1, se = c(sl, so) / sqrt(II),
       frac_level = n * mean(I)^2 / II)  # share of sum(I^2) carried by the LEVEL, not the noise
}
obj_ll <- function(s, I) row_l(s[1], I) + row_o(s[2], I)
res <- lapply(names(I_of), function(k) {
  I <- I_of[[k]]; o <- share_opt(I)
  # G3 -- brute force over the simplex
  gr <- expand.grid(a = seq(0, 1, IA_GRID), b = seq(0, 1, IA_GRID)); gr <- gr[gr$a + gr$b <= 1 + 1e-12, ]
  best <- max(mapply(function(a, b) obj_ll(c(a, b), I), gr$a, gr$b))
  at <- obj_ll(o$s, I)
  if (at < best - 1e-9) stop(sprintf("G3 FAIL (%s): analytic optimum %.6f below grid %.6f", k, at, best))
  c(treat = k, s_land_un = o$unconstrained[1], s_ocean_un = o$unconstrained[2],
    s_land = o$s[1], s_ocean = o$s[2], s_rest = 1 - sum(o$s),
    se_land = o$se[1], se_ocean = o$se[2], frac_level = o$frac_level,
    dll_land = row_l(o$s[1], I) - row_l(0, 0), dll_ocean = row_o(o$s[2], I) - row_o(0, 0),
    dll_both = at - obj_ll(c(0, 0), 0), grid_best = best - obj_ll(c(0, 0), 0))
})

# ---- the budget identity at the control (G4) ----------------------------------
ident <- lapply(IA_WINDOWS, function(w) {
  k <- g$year >= w[1] & g$year <= w[2]; m <- function(v) mean(v[k])
  z <- c(d_land = m(g$land_resid - g$land_sink), imbal = m(g$imbalance), cement = m(g$cement_carbonation),
         d_luc = m(g$eluc - g$luc), d_grow = m(g$grow - g$atm_growth), d_ocn = m(g$ocean - g$ocean_sink))
  c(win0 = w[1], win1 = w[2], z, closure = z[["d_land"]] - (z[["imbal"]] + z[["cement"]] + z[["d_luc"]] - z[["d_grow"]] - z[["d_ocn"]]))
})
ident <- as.data.frame(do.call(rbind, ident))
full <- ident[1, ]
if (abs(full$closure) > 0.1 * abs(full$d_land)) stop(sprintf("G4 FAIL: closure %.4f vs d_land %.4f", full$closure, full$d_land))

# ---- report -------------------------------------------------------------------
R <- as.data.frame(do.call(rbind, res), stringsAsFactors = FALSE)
for (c in setdiff(names(R), "treat")) R[[c]] <- as.numeric(R[[c]])
sink(paste0(IA_OUT, ".log"), split = TRUE)
cat(sprintf("=== PROVENANCE === driver %s, commit %s%s, run %s; no RNG\n", IA_DRIVER, COMMIT,
            if (isTRUE(DIRTY)) " (DIRTY)" else "", format(Sys.time(), "%Y-%m-%d %H:%M")))
cat(sprintf("  structure %s at v0k basin 1; control %s value %g; G1 d %.2e; G2 rows d %.1e / %.1e\n",
            IA_STRUCT, basename(IA_CTRL_PROFILE), IA_CTRL_VALUE, id_d, g2[1], g2[2]))
cat(sprintf("  rows: land sigma %.2f, ocean sigma %.2f GtC/yr (objective #13); GCB years %d-%d (n %d); luc_scale %.4f\n\n",
            sl, so, min(g$year), max(g$year), n, pv$luc_scale))
cat("=== THE BUDGET IDENTITY AT THE CONTROL (model minus GCB, GtC/yr) ===\n")
cat("    d_land = imbal + cement + d_luc - d_grow - d_ocn  (+ closure)\n")
print(format(ident, digits = 3), row.names = FALSE)
k1 <- full
cat(sprintf("\n  where (imbalance + cement) %.3f GtC/yr goes at the control (%d-%d): land %+.3f (%.0f %%), ocean %+.3f (%.0f %%),\n",
            k1$imbal + k1$cement, k1$win0, k1$win1, k1$d_land, 100 * k1$d_land / (k1$imbal + k1$cement),
            k1$d_ocn, 100 * k1$d_ocn / (k1$imbal + k1$cement)))
cat(sprintf("  E_LUC via luc_scale %+.3f (%.0f %%), growth %+.3f (%.0f %%), closure %+.4f\n",
            -k1$d_luc, 100 * -k1$d_luc / (k1$imbal + k1$cement), -k1$d_grow, 100 * -k1$d_grow / (k1$imbal + k1$cement), k1$closure))
cat("  ⚠ luc_scale < 1 LOWERS the land excess: a smaller E_LUC means less residual sink is needed for the same CO2.\n\n")
cat("=== SHARES THAT MAXIMISE THE TWO ROWS, AT THE FIXED CONTROL ===\n")
cat("  s_* = constrained optimum on {>= 0, sum <= 1}; *_un = unconstrained; se = sigma / sqrt(sum I^2)\n")
cat("  frac_level = share of sum(I^2) carried by the imbalance's MEAN (the rest is its year-to-year noise)\n")
cat("  dll = row log-likelihood gain over s = 0 at FIXED parameters (a refit can do better)\n")
for (i in seq_len(nrow(R))) with(R[i, ], cat(sprintf(
  "  %-10s s_land %.3f (un %.3f, se %.3f)  s_ocean %.3f (un %+.3f, se %.3f)  rest %.3f | frac_level %.2f | dll land %+6.2f ocean %+5.2f both %+6.2f (grid %+6.2f)\n",
  treat, s_land, s_land_un, se_land, s_ocean, s_ocean_un, se_ocean, s_rest, frac_level, dll_land, dll_ocean, dll_both, grid_best)))
cat("\n  treatments:\n"); for (k in names(IA_TREAT)) cat(sprintf("    %-10s %s\n", k, IA_TREAT[[k]]))
cat(sprintf("\n  imbalance: mean %+.3f, sd %.3f, lag-1 autocorrelation %.2f; smooth range %+.2f..%+.2f; 2024 raw %+.2f\n",
            mean(imb), stats::sd(imb), stats::acf(imb, plot = FALSE)$acf[2], min(I_of$SMOOTH), max(I_of$SMOOTH), imb[g$year == 2024]))
sink()
saveRDS(list(shares = R, identity = ident, I = cbind(year = g$year, as.data.frame(I_of)),
             rows = data.frame(year = g$year, model_land = g$land_resid, gcb_land = g$land_sink,
                               model_ocean = g$ocean, gcb_ocean = g$ocean_sink),
             provenance = sprintf("%s @%s%s; %s; control %s tau %g; no RNG", IA_DRIVER, COMMIT,
                                  if (isTRUE(DIRTY)) " (DIRTY)" else "", IA_STRUCT, basename(IA_CTRL_PROFILE), IA_CTRL_VALUE)),
        paste0(IA_OUT, ".rds"))
