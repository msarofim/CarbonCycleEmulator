# =====================================================================
# build_export_seasonal_prior.R -- THE SEASONAL SHAPE OF EXPORT PRODUCTION, per
#   hemisphere x band, as a PRIOR PRODUCT for the seasonal export (option O5)
#   data-raw/downloads/cmip6_export_seasonal_shape.{csv,_meta.json}
#     -> data/obs_export_seasonal_shape_cmip6.rds
#
# Reads the CMIP6 epc100 climatologies built by
# data-raw/build_cmip6_export_seasonal_shape.py (20 models, 1995-2014, areacello-
# weighted, LS = |lat| < 57.14 / HS = the rest, per hemisphere) and ships, per
# series (NH_LS, SH_LS, NH_HS, SH_HS): the per-model first-harmonic relative
# amplitude, lag in the MODEL's own convention (R/model.R pump_seas_lag: NH
# peaks mid-July + lag, SH mid-January + lag), peak/mean, the harmonic's share
# of the seasonal variance; their ensemble median and IQR; and the UNIT-MEAN
# ENSEMBLE-MEDIAN 12-month shape (month centers), so a later build can drive
# the pump with the DATA's shape rather than a sine (the "use real data when
# you have it" rule) -- the HS boxes' peak/mean of ~3 is a rectified bloom no
# sine on [0, 1] can carry.
#
# ⚠ PROVENANCE: MODELS, not observations (the 2026-08-27 acceptance for the
# land NPP shape is the precedent; pedagogical tool). Never describe this as an
# observational constraint. The satellite NPP climatology is the cross-check
# (a LOWER bound on export seasonality); the SOM-FFN SO pCO2 amplitude
# (data/obs_so_pco2_seas_amp.rds) is the out-of-sample result row.
# Run from the repo root:  Rscript data-raw/build_export_seasonal_prior.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ES_CSV  <- ccx_path("data-raw/downloads", "cmip6_export_seasonal_shape.csv")
ES_META <- ccx_path("data-raw/downloads", "cmip6_export_seasonal_shape_meta.json")
ES_OUT  <- ccx_path("data", "obs_export_seasonal_shape_cmip6.rds")
ES_SERIES <- c("NH_LS", "SH_LS", "NH_HS", "SH_HS")
ES_WINDOW <- c(1995L, 2014L)
x <- read.csv(ES_CSV, stringsAsFactors = FALSE)
meta <- jsonlite::fromJSON(ES_META, simplifyVector = FALSE)
stopifnot(length(meta) >= 15)
per_model <- do.call(rbind, lapply(meta, function(m) do.call(rbind, lapply(ES_SERIES, function(s) data.frame(
  model = m$model, series = s, mean_PgC = m[[s]]$mean, amp_rel = m[[s]]$amp_rel, lag_mo = m[[s]]$lag_mo,
  peak_month = m[[s]]$peak_month, rect = m[[s]]$rect, frac_h1 = m[[s]]$frac_h1, units = m$units, stringsAsFactors = FALSE)))))
summ <- do.call(rbind, lapply(ES_SERIES, function(s) { d <- per_model[per_model$series == s, ]
  q <- function(v) stats::quantile(v, c(0.25, 0.5, 0.75), na.rm = TRUE)
  data.frame(series = s, n = nrow(d), amp_q25 = q(d$amp_rel)[1], amp_med = q(d$amp_rel)[2], amp_q75 = q(d$amp_rel)[3],
             lag_q25 = q(d$lag_mo)[1], lag_med = q(d$lag_mo)[2], lag_q75 = q(d$lag_mo)[3],
             rect_med = q(d$rect)[2], frac_h1_med = q(d$frac_h1)[2], mean_PgC_med = q(d$mean_PgC)[2], row.names = NULL) }))
# the unit-mean ensemble-median monthly shape per series
shape <- lapply(ES_SERIES, function(s) { k <- x[startsWith(x$series, paste0(s, "|")), ]
  mods <- unique(k$series); M <- sapply(mods, function(m) { v <- k$value[k$series == m]; v / mean(v) })
  list(month = 1:12, median = apply(M, 1, median), q25 = apply(M, 1, stats::quantile, 0.25), q75 = apply(M, 1, stats::quantile, 0.75), n = ncol(M)) })
names(shape) <- ES_SERIES
out <- list(per_model = per_model, summary = summ, shape = shape, window = ES_WINDOW, hs_lat = 57.14, horizon_m = 100,
            lag_convention = "R/model.R pump_seas_lag: NH peaks at month 6.5 + lag, SH at 0.5 + lag (mid-July / mid-January at lag 0); months from 1 Jan, decimal",
            provenance = "CMIP6 historical epc100 (Omon), 20 models, r1i1p1f1 preferred, 1995-2014 monthly climatology, areacello-weighted; Pangeo/GCS catalogue. MODELS, NOT OBSERVATIONS (Marcus 2026-08-27 acceptance class). Built by data-raw/build_cmip6_export_seasonal_shape.py + this script.",
            caveat = "epc100 is the sinking POC flux at 100 m; the model's export leaves the ML base (~65 m). Shape only is read. The HS boxes' first harmonic exceeds the mean (a rectified bloom): a sine factor on [0, 1] cannot represent it -- use the `shape` climatology or a rectified form there.",
            built = format(Sys.time(), "%Y-%m-%d %H:%M"))
saveRDS(out, ES_OUT)
cat(sprintf("wrote %s (%d models)\n", ES_OUT, length(meta))); print(summ, digits = 3)
for (s in ES_SERIES) cat(sprintf("%s shape (unit mean, median): %s\n", s, paste(sprintf("%.2f", shape[[s]]$median), collapse = " ")))
