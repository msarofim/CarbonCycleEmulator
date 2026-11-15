#!/usr/bin/env Rscript
# =====================================================================
# diag_card4_enso_estimators.R -- card 4's last sentence, re-measured at the canonical (group B item B19, 2026-11-11).
#
# WHY. Known-issues card 4 ends: "On the first chart's measure the model's variability is more ENSO-driven than the
# record's; on the What-if tab's measure it is less". The 10-15 review measured "less" as r +0.18 vs +0.29 (hilda31w)
# on the N7 estimator (calibration/diag_card4_audit.R section 8: model growth from app_annual_growth() against GCB's
# atm_growth, 1959-2024, anomaly about a 3-dof spline). The 11-11 review re-measured "on that estimator" and found the
# model AHEAD at every lag tried (r +0.29/+0.58/+0.67 vs -0.15/+0.19/+0.37 at 0/3/6 months), with no script kept.
# Two things differ between those readings and neither was stated: (1) which OBSERVED series -- the What-if tab has
# drawn NOAA's MBL global growth on the annual-mean-difference estimator since 2026-09-26 (from 1980), not GCB's
# Jan-to-Jan atm_growth (from 1959); (2) whether the ENSO index is lagged. This driver puts every combination side by
# side at the canonical, with an error bar on each model-minus-record difference, so the sentence can be judged on
# measurements rather than on one reading.
#
# WHAT. The model series is the app's own historical run (APP_HIST, the canonical, loaded through app/global.R).
# Estimators (rows of the table):
#   GATEV   card 4a's caption: rv_variability() (growth regressed on emissions with a time-varying AF, GtC/yr; GCB obs;
#           1959-2024). Its anomaly series are re-used, only the index lag changes.
#   WHATIF  the What-if tab exactly: app_annual_growth(APP_HIST$out) against app_obs_growth(APP_OBS_GROWTH) (NOAA MBL,
#           annual means differenced), on the tab's default window (the slider's default intersected with the observed
#           record, as server.R's cf_window()), anomaly = residual about ns(year, df = 3) -- the scatter sentence's.
#   N7      the 10-08/10-15 reading: the same model series against GCB atm_growth / GtC_PER_PPM, 1959-2024, same spline.
#   N7_80   N7's GCB series on WHATIF's years: separates "which observed product" from "which years".
# Index: the observed Nino 3.4 anomaly (data/forcing_enso.rds, the series card 4's caption uses), annual mean of the
# twelve months ending LAG months before each calendar year ends (LAG 0 = the calendar year).
# Error bar: the model-minus-record difference in r, by a paired moving-block bootstrap over years (block CE_BLOCK
# years, CE_B replicates, seed CE_SEED set immediately before the resampling and stamped into the output), and
# Williams' t for two dependent correlations sharing one variable (Steiger 1980, eq. 7).
#
# Usage: Rscript calibration/diag_card4_enso_estimators.R      # ~3 min, read-only; changes no app text
#        [--index=shipped|grid|relsst_lp|relsst]                # 11-15; non-default writes ..._idx-<name>.{log,rds}
# =====================================================================
t_start <- Sys.time()
ROOT <- normalizePath(getwd())
stopifnot(file.exists(file.path(ROOT, "app", "global.R")))
setwd(file.path(ROOT, "app"))
invisible(capture.output(suppressMessages(suppressWarnings(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv())))))
setwd(ROOT)
rv_need_gates()

# ---- named constants (every label and filename derives from these) ----------
CE_DRIVER   <- "calibration/diag_card4_enso_estimators.R"
CE_LAGS     <- c(0L, 3L, 6L, 9L)          # months the index LEADS the calendar year; 0/3/6 = the 11-11 review's
CE_PEAK_LAGS <- 0:18                      # the phase scan (months)
CE_DF       <- 3L                         # the What-if scatter sentence's spline (server.R c_growth_note)
CE_N7_WIN   <- c(1959L, 2024L)            # diag_card4_audit.R CA_GR_WIN
CE_SLIDER   <- c(1850L, as.integer(APP_HIST_YEARS[2]))   # the What-if slider's default (ui.R c_years); checked below
CE_SEED     <- 20261111L
CE_B        <- 5000L                      # bootstrap replicates
CE_BLOCK    <- 3L                         # moving-block length, years
CE_CI       <- c(0.05, 0.95)              # a 90 % interval
CE_REVIEW   <- list(lags = c(0L, 3L, 6L), r_model = c(0.29, 0.58, 0.67), r_obs = c(-0.15, 0.19, 0.37))  # B19's numbers
# --index= (added 2026-11-15, Marcus: "Do the cheap test for the RONI"): which observed index every r is taken against.
# The model is still the canonical's, forced by its own (detrended) index; only the correlating index changes.
CE_INDEX <- sub("^--index=", "", grep("^--index=", commandArgs(trailingOnly = TRUE), value = TRUE)[1])
if (is.na(CE_INDEX)) CE_INDEX <- "shipped"
CE_INDEX_SRC <- c(
  shipped   = "data/forcing_enso.rds nino34_anom, observed (not the model's detrended driver)",
  grid      = "ERSST v6 grid Nino 3.4, fixed base 1991-2020 (lib_enso_index.R; MANIFEST ersst_v6_monthly, sha256 checked): the product-swap control for the two below",
  relsst_lp = "data/forcing_enso_relsst.rds nino34_relsst_lp: ERSST v6 Nino 3.4 minus the 21-yr low-passed 20S-20N mean (09-29; partial window in its last 10 yr)",
  relsst    = "ERSST v6 Nino 3.4 minus the UNFILTERED 20S-20N mean anomaly, fixed base 1991-2020: RONI's subtraction (its variance rescaling omitted; r and r^2 shares do not depend on scale)")
if (!CE_INDEX %in% names(CE_INDEX_SRC)) stop("--index must be one of ", paste(names(CE_INDEX_SRC), collapse = ", "))
CE_STEM <- file.path("outputs", "diagnostics",
                     sprintf("card4_enso_estimators_%s_%s%s", format(Sys.Date(), "%Y%m%d"), CCX_MODE_CANONICAL,
                             if (CE_INDEX == "shipped") "" else paste0("_idx-", CE_INDEX)))

commit <- ccx_git_stamp(); dirty <- ccx_stamp_dirty(commit)
mode_file <- ccx_mode_file(); md5 <- unname(tools::md5sum(mode_file))
dir.create(dirname(CE_STEM), showWarnings = FALSE, recursive = TRUE)
LOG <- paste0(CE_STEM, ".log"); if (file.exists(LOG)) file.remove(LOG)
say <- function(...) { txt <- sprintf(...); cat(txt); cat(txt, file = LOG, append = TRUE) }
say("%s | commit %s%s | canonical %s (%s, md5 %s) | %s\n", CE_DRIVER, commit, if (dirty) " (dirty)" else "",
    CCX_MODE_CANONICAL, basename(dirname(mode_file)), md5, format(Sys.time(), "%Y-%m-%d %H:%M"))

# ---- gates --------------------------------------------------------------------
# the slider default this driver assumes is the one ui.R declares
ui_txt <- paste(readLines(file.path(ROOT, "app", "ui.R")), collapse = "\n")
if (!grepl(sprintf("\"c_years\"[^)]*value = c\\(%d, *APP_HIST_YEARS\\[2\\]\\)", CE_SLIDER[1]), ui_txt))
  stop("ui.R's c_years default is not c(", CE_SLIDER[1], ", APP_HIST_YEARS[2]): update CE_SLIDER")
# the app's historical run is the canonical's (APP_PARAMS decoded from the mode file)
md <- readRDS(mode_file)
# bomb_total / luc_scale / rep_dC have no slot in the parameter list (memory ccx_app_label_tables_gated): the app
# carries them as APP_BOMB_TOTAL / APP_LUC_SCALE / APP_REP_DC; a fitted name found in neither place FAILS the gate
app_val <- function(n) {
  if (!is.null(APP_PARAMS[[n]])) return(APP_PARAMS[[n]])
  side <- list(bomb_total = APP_BOMB_TOTAL, luc_scale = APP_LUC_SCALE, rep_dC = APP_REP_DC)[[n]]
  if (is.null(side)) NA_real_ else side
}
dp <- vapply(md$param_names, function(n) abs(app_val(n) - md$par_mode[[n]]) / max(1e-12, abs(md$par_mode[[n]])), 0)
# a fitted name absent from the app must be a LIKELIHOOD-only name (an error scale, an offset, an allocation share):
# one the model's parameter list does not have, so it cannot reach the run
lik_only <- md$param_names[is.na(dp)]
if (any(lik_only %in% names(ccx_default_params())))
  stop("fitted model parameters with no value in the app: ", paste(intersect(lik_only, names(ccx_default_params())), collapse = ", "))
say("  likelihood-only fitted names (not in the model's parameter list, so not in the run): %s\n", paste(lik_only, collapse = ", "))
dp <- dp[!is.na(dp)]
say("GATE: the app's parameters vs the mode file's par_mode, max relative difference %.1e over %d fitted names -> %s\n",
    max(dp), length(dp), if (max(dp) < 1e-10) "PASS" else "FAIL")
if (max(dp) >= 1e-10) stop("the app's parameters are not the canonical's mode")

# ---- the index ----------------------------------------------------------------
ersst_v6 <- function() {   # the checksummed v6 grid, read as data-raw/build_enso_relsst.R reads it
  source(ccx_path("calibration", "lib_enso_index.R"))
  man <- utils::read.csv(ccx_path("data-raw", "downloads", "MANIFEST.csv"), stringsAsFactors = FALSE)
  row <- man[man$key == "ersst_v6_monthly", ]
  stopifnot(nrow(row) == 1L, identical(digest::digest(file = ccx_path(row$file), algo = "sha256"), row$sha256))
  ccx_path(row$file)
}
en <- switch(CE_INDEX,
  shipped   = as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))),
  relsst_lp = with(readRDS(ccx_path("data", "forcing_enso_relsst.rds")),
                   data.frame(year = year, month = month, nino34_anom = nino34_relsst_lp)),
  {   # grid, relsst (v5 is eix_relative_sst()'s default; the v6 path is passed explicitly, as the 09-29 build does)
    p <- ersst_v6()
    n34 <- eix_fixed_base(eix_ersst_box(EIX_BOX_N34, path = p)); v <- n34$value
    if (CE_INDEX == "relsst") {
      tr <- eix_fixed_base(eix_ersst_box(EIX_BOX_TROP, path = p))
      m <- match(n34$year * 12L + n34$month, tr$year * 12L + tr$month); stopifnot(!anyNA(m))
      v <- v - tr$value[m]
    }
    data.frame(year = n34$year, month = n34$month, nino34_anom = v)
  })
say("index (--index=%s): %s\n", CE_INDEX, CE_INDEX_SRC[[CE_INDEX]])
en <- en[order(en$year, en$month), ]
idx_annual <- function(lag) {   # mean of the 12 months ending `lag` months before December of each year
  mi <- en$year * 12L + en$month - 1L                     # month index
  v <- en$nino34_anom
  yrs <- sort(unique(en$year))
  vapply(yrs, function(y) {
    want <- (y * 12L + 11L - lag) - 0:11
    k <- match(want, mi)
    if (any(is.na(k)) || any(!is.finite(v[k]))) NA_real_ else mean(v[k])
  }, 0) |> stats::setNames(yrs)
}
IDX <- lapply(stats::setNames(CE_LAGS, paste0("lag", CE_LAGS)), idx_annual)
IDX_PEAK <- lapply(stats::setNames(CE_PEAK_LAGS, paste0("lag", CE_PEAK_LAGS)), idx_annual)

# ---- the series ---------------------------------------------------------------
anom <- function(x, yr) stats::residuals(stats::lm(x ~ splines::ns(yr, df = CE_DF)))
mg <- app_annual_growth(APP_HIST$out); names(mg)[2] <- "model"
mbl <- app_obs_growth(APP_OBS_GROWTH); names(mbl)[2] <- "obs"
gcb <- data.frame(year = APP_GCB$year, obs = APP_GCB$atm_growth / ccx_const("GtC_PER_PPM"))
obs_span <- range(mbl$year)
win_whatif <- c(max(CE_SLIDER[1], obs_span[1]), min(CE_SLIDER[2], obs_span[2]))   # server.R cf_window()
build <- function(obs, win) {
  d <- merge(mg, obs, by = "year"); d <- d[d$year >= win[1] & d$year <= win[2], ]
  data.frame(year = d$year, m = anom(d$model, d$year), o = anom(d$obs, d$year))
}
v <- rv_variability()
EST <- list(
  GATEV  = data.frame(year = v$years, m = as.numeric(v$model_anom), o = as.numeric(v$obs_anom)),
  WHATIF = build(mbl, win_whatif),
  N7     = build(gcb, CE_N7_WIN),
  N7_80  = build(gcb, win_whatif))
EST_LAB <- c(GATEV = "card 4a caption (GATE V: GtC/yr, AF regression; GCB; 1959-2024)",
             WHATIF = sprintf("What-if tab as drawn (NOAA MBL, annual means; %d-%d; ns df %d)", win_whatif[1], win_whatif[2], CE_DF),
             N7 = sprintf("10-15 'What-if' reading (GCB atm_growth; %d-%d; ns df %d)", CE_N7_WIN[1], CE_N7_WIN[2], CE_DF),
             N7_80 = sprintf("GCB atm_growth on the What-if years (%d-%d; ns df %d)", win_whatif[1], win_whatif[2], CE_DF))
for (k in names(EST)) say("  %-6s n %2d, %d-%d | %s\n", k, nrow(EST[[k]]), min(EST[[k]]$year), max(EST[[k]]$year), EST_LAB[[k]])

# ---- statistics ---------------------------------------------------------------
williams <- function(r12, r13, r23, n) {      # H0: rho12 = rho13 (variable 1 shared); Steiger 1980 eq. 7
  detR <- 1 - r12^2 - r13^2 - r23^2 + 2 * r12 * r13 * r23
  rb <- (r12 + r13) / 2
  t <- (r12 - r13) * sqrt((n - 1) * (1 + r23) / (2 * ((n - 1) / (n - 3)) * detR + rb^2 * (1 - r23)^3))
  c(t = t, p = 2 * stats::pt(-abs(t), df = n - 3))
}
block_idx <- function(n, L) {                 # one moving-block resample of 1..n
  starts <- sample.int(n - L + 1L, ceiling(n / L), replace = TRUE)
  as.vector(unlist(lapply(starts, function(s) s:(s + L - 1L))))[seq_len(n)]
}
rows <- list()
for (k in names(EST)) for (lg in CE_LAGS) {
  d <- EST[[k]]; x <- IDX[[paste0("lag", lg)]][as.character(d$year)]
  ok <- is.finite(x) & is.finite(d$m) & is.finite(d$o); d <- d[ok, ]; x <- x[ok]; n <- nrow(d)
  rm <- stats::cor(d$m, x); ro <- stats::cor(d$o, x); rmo <- stats::cor(d$m, d$o)
  w <- williams(rm, ro, rmo, n)
  set.seed(CE_SEED)                           # immediately before the call that consumes the stream
  bs <- replicate(CE_B, { i <- block_idx(n, CE_BLOCK); stats::cor(d$m[i], x[i]) - stats::cor(d$o[i], x[i]) })
  ci <- stats::quantile(bs, CE_CI, names = FALSE)
  rows[[length(rows) + 1L]] <- data.frame(estimator = k, lag_mo = lg, n = n, r_model = rm, r_obs = ro,
                                          diff = rm - ro, ci_lo = ci[1], ci_hi = ci[2], williams_t = w[["t"]],
                                          williams_p = w[["p"]], r_model_obs = rmo, sd_ratio = stats::sd(d$m) / stats::sd(d$o))
}
tab <- do.call(rbind, rows)
say("\n=== r with Nino 3.4 (annual mean of the 12 months ending LAG months before December); model minus record ===\n")
say("  90%% interval: paired moving-block bootstrap, block %d yr, B %d, seed %d. Williams' t: dependent r sharing the index.\n",
    CE_BLOCK, CE_B, CE_SEED)
say("  %-6s %4s %3s  %7s %7s  %7s  %-17s  %6s %6s  %8s  %8s\n", "est", "lag", "n", "r_mod", "r_obs", "diff", "90% interval",
    "W t", "W p", "r(m,o)", "sd m/o")
for (i in seq_len(nrow(tab))) with(tab[i, ], say("  %-6s %4d %3d  %+7.3f %+7.3f  %+7.3f  [%+6.3f, %+6.3f]  %+6.2f %6.3f  %+8.3f  %8.3f\n",
  estimator, lag_mo, n, r_model, r_obs, diff, ci_lo, ci_hi, williams_t, williams_p, r_model_obs, sd_ratio))

# ---- which reading the 11-11 review reproduced ---------------------------------
say("\n=== the 11-11 review's numbers (lags %s): model %s vs record %s ===\n", paste(CE_REVIEW$lags, collapse = "/"),
    paste(sprintf("%+.2f", CE_REVIEW$r_model), collapse = "/"), paste(sprintf("%+.2f", CE_REVIEW$r_obs), collapse = "/"))
for (k in names(EST)) {
  s <- tab[tab$estimator == k & tab$lag_mo %in% CE_REVIEW$lags, ]
  dev <- max(abs(c(s$r_model - CE_REVIEW$r_model, s$r_obs - CE_REVIEW$r_obs)))
  say("  %-6s max |difference| from the review's six numbers %.3f%s\n", k, dev, if (dev < 0.006) "  <- REPRODUCES (to the printed digits)" else "")
}

# ---- the card's sentence, per estimator -------------------------------------------
say("\n=== card 4: 'more ENSO-driven' (model r > record r) per estimator and lag; 'clear' = the 90%% interval excludes 0 ===\n")
for (k in names(EST)) {
  s <- tab[tab$estimator == k, ]
  say("  %-6s %s\n", k, paste(sprintf("lag %d: %s%s", s$lag_mo, ifelse(s$diff > 0, "model MORE", "model LESS"),
                                       ifelse(s$ci_lo > 0 | s$ci_hi < 0, " (clear)", " (not clear)")), collapse = "; "))
}

# ---- where each series' r peaks along the lag: a PHASE test ------------------------------
# app_annual_growth() and the MBL series difference ANNUAL MEANS (a growth centred near 1 January of year y); GCB's
# atm_growth is a JAN-TO-JAN difference (centred near 1 July). If N7's split is that half-year offset and not the
# model, the model's peak lag on N7 sits about 6 months beyond the record's, and on the like-for-like WHATIF the two
# peaks sit together.
peak <- do.call(rbind, lapply(names(EST), function(k) {
  d <- EST[[k]]
  r <- t(vapply(CE_PEAK_LAGS, function(lg) {
    x <- IDX_PEAK[[paste0("lag", lg)]][as.character(d$year)]; ok <- is.finite(x)
    c(stats::cor(d$m[ok], x[ok]), stats::cor(d$o[ok], x[ok]))
  }, c(0, 0)))
  data.frame(estimator = k, peak_lag_model = CE_PEAK_LAGS[which.max(r[, 1])], r_peak_model = max(r[, 1]),
             peak_lag_obs = CE_PEAK_LAGS[which.max(r[, 2])], r_peak_obs = max(r[, 2]))
}))
say("\n=== the lag (months, %d-%d) at which r peaks, per series ===\n", min(CE_PEAK_LAGS), max(CE_PEAK_LAGS))
for (i in seq_len(nrow(peak))) with(peak[i, ], say("  %-6s model peaks at lag %2d (r %+.3f); record at lag %2d (r %+.3f)\n",
  estimator, peak_lag_model, r_peak_model, peak_lag_obs, r_peak_obs))

# ---- where the missing variance sits: ENSO-related vs the rest, in units of the RECORD's variance ----------------
# At each like-for-like estimator's shared peak lag: the ENSO-related part of a series' variance is r^2 x its variance,
# the rest (1 - r^2) x its variance; both are expressed as fractions of the record's variance, so the model's two parts
# and the record's two parts can be compared directly. A linear, single-index split: an ENSO response the lagged
# annual index cannot represent lands in "the rest".
say("\n=== variance split at the shared peak lag (fractions of the RECORD's variance) ===\n")
split <- do.call(rbind, lapply(c("GATEV", "WHATIF"), function(k) {
  pk <- peak[peak$estimator == k, ]
  if (pk$peak_lag_model != pk$peak_lag_obs) return(NULL)
  d <- EST[[k]]; x <- IDX_PEAK[[paste0("lag", pk$peak_lag_model)]][as.character(d$year)]; ok <- is.finite(x)
  rm <- stats::cor(d$m[ok], x[ok]); ro <- stats::cor(d$o[ok], x[ok]); v <- stats::var(d$m[ok]) / stats::var(d$o[ok])
  data.frame(estimator = k, lag = pk$peak_lag_model, model_total = v, model_enso = rm^2 * v, model_rest = (1 - rm^2) * v,
             record_enso = ro^2, record_rest = 1 - ro^2)
}))
for (i in seq_len(nrow(split))) with(split[i, ], say(paste0("  %-6s lag %2d: model total %.2f = ENSO-related %.2f + rest %.2f;",
  " record 1.00 = ENSO-related %.2f + rest %.2f -> the model's shortfall is %.2f in the rest and %+.2f in the ENSO part\n"),
  estimator, lag, model_total, model_enso, model_rest, record_enso, record_rest, record_rest - model_rest, model_enso - record_enso))

prov <- list(driver = CE_DRIVER, commit = commit, dirty = dirty, canonical = CCX_MODE_CANONICAL, mode_file = mode_file,
             mode_md5 = md5, model_series = "APP_HIST$out via app_annual_growth() (app/global.R startup run)",
             obs = c(MBL = "data/mbl_global_growth.rds $growth (APP_OBS_GROWTH)", GCB = "data/gcb_budget.rds atm_growth / GtC_PER_PPM",
                     GATEV = "rv_variability() (lib_design_gates.R dg_v_anom)"),
             index = CE_INDEX_SRC[[CE_INDEX]], index_option = CE_INDEX,
             windows = list(whatif = win_whatif, n7 = CE_N7_WIN, slider_default = CE_SLIDER), spline_df = CE_DF,
             rng = sprintf("set.seed(%d) immediately before each estimator x lag bootstrap (%d replicates, moving block %d yr)",
                           CE_SEED, CE_B, CE_BLOCK),
             date = format(Sys.time(), "%Y-%m-%d %H:%M"))
saveRDS(list(table = tab, peak = peak, split = split, series = EST, index = IDX, labels = EST_LAB, review = CE_REVIEW, provenance = prov),
        paste0(CE_STEM, ".rds"))
say("\nprovenance: %s @%s; %s md5 %s; seed %d (bootstrap); saved %s.{log,rds} | %.1f min\n", CE_DRIVER, commit,
    CCX_MODE_CANONICAL, md5, CE_SEED, CE_STEM, as.numeric(difftime(Sys.time(), t_start, units = "mins")))
