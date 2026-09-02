# =====================================================================
# lib_enso_index.R -- ONE definition of every candidate ENSO forcing index.
#
# WHY A LIB. Two diagnostics need these: diag_enso_index_baseline.R (which
# BASELINE convention does the shipped index get?) and diag_enso_index_bakeoff.R
# (which INDEX fits best, each given its own best gammas?). Two private copies of
# "demean" is exactly the drift this project keeps paying for, so there is one.
#
# ⚠ EVERY BUILDER RETURNS THE SAME SHAPE: a data.frame(year, month, value) of
# MONTHLY values, whatever the source's native resolution, so a caller can
# interpolate them all identically. A builder that cannot cover a month omits
# the ROW rather than emitting a zero -- zero is a real ENSO state and must
# never stand in for "no data" ([[intersect_is_a_silent_default]] in spirit).
#
# ⛔ THE PRODUCTS ARE NOT INTERCHANGEABLE. nina34.data (PSL, footer says ERSST
# V6) and the local ERSSTv5 grid disagree by 15 % in ENSO AMPLITUDE over
# 1991-2020 -- verified NOT to be our extraction, which reproduces CPC's
# published v5 index at r 1.0000. Any comparison ACROSS products must either
# re-fit the gammas (which absorbs amplitude) or say out loud that it did not.
# =====================================================================

EIX_CLIM_BASE <- c(1991, 2020)   # = ENSO_CLIM_BASE in build_calibration_data.R
EIX_ROLL_LEN  <- 30              # ONI centred base-period length, years
EIX_ROLL_STEP <- 5               # ONI base-period refresh interval, years
EIX_BOX_N34   <- list(lat = c(-5, 5), lon = c(190, 240))   # 5S-5N, 170W-120W
EIX_BOX_TROP  <- list(lat = c(-20, 20), lon = NULL)        # 20S-20N, all lons
EIX_ERSST     <- file.path("data-raw", "downloads", "ersst_v5_sst_mnmean.nc")
EIX_EPOCH     <- "1800-01-01"
EIX_PSL       <- file.path("data-raw", "downloads", "nina34.data")
EIX_PSL_MISS  <- -99.99
EIX_MEI_EXT   <- file.path("data-raw", "downloads", "mei_ext_table.html")

# ---- PSL year-by-month tables (nina34.data and friends) -------------
eix_read_psl <- function(path = ccx_path(EIX_PSL), missing = EIX_PSL_MISS) {
  ln  <- readLines(path); hdr <- scan(text = ln[1], quiet = TRUE)
  m <- do.call(rbind, lapply(ln[2:(1 + (hdr[2] - hdr[1] + 1))],
                             function(l) scan(text = l, quiet = TRUE)))
  d <- data.frame(year = rep(m[, 1], 12), month = rep(seq_len(12), each = nrow(m)),
                  value = as.vector(m[, -1]))
  d$value[d$value %in% missing | d$value < -90] <- NA_real_
  d <- d[!is.na(d$value), ]
  d[order(d$year, d$month), ]
}

# ---- an area-weighted box mean from the ERSST grid ------------------
# cos(lat) weighting; the same average nina34.data reports. VERIFIED against
# CPC's published ERSSTv5 Nino 3.4: r 1.0000, slope 0.997, monthly climatologies
# within 0.02 degC. Do not "improve" it without re-running that check.
eix_ersst_box <- function(box, path = ccx_path(EIX_ERSST)) {
  if (!requireNamespace("ncdf4", quietly = TRUE)) stop("lib_enso_index: ncdf4 required")
  nc <- ncdf4::nc_open(path); on.exit(ncdf4::nc_close(nc), add = TRUE)
  lat <- ncdf4::ncvar_get(nc, "lat"); lon <- ncdf4::ncvar_get(nc, "lon")
  tm  <- ncdf4::ncvar_get(nc, "time"); sst <- ncdf4::ncvar_get(nc, "sst")
  il <- which(lat >= box$lat[1] & lat <= box$lat[2])
  io <- if (is.null(box$lon)) seq_along(lon) else which(lon >= box$lon[1] & lon <= box$lon[2])
  if (!length(il) || !length(io)) stop("lib_enso_index: the box selected no grid cells")
  W <- matrix(rep(cos(lat[il] * pi / 180), each = length(io)), nrow = length(io))
  v <- apply(sst[io, il, , drop = FALSE], 3,
             function(m) sum(m * W, na.rm = TRUE) / sum(W * is.finite(m)))
  d <- as.Date(EIX_EPOCH) + tm
  data.frame(year = as.integer(format(d, "%Y")),
             month = as.integer(format(d, "%m")), value = v)
}

# ---- base-period conventions, as functions of an ABSOLUTE series ----
eix_fixed_base <- function(a, base = EIX_CLIM_BASE) {
  k  <- a$year >= base[1] & a$year <= base[2]
  cl <- tapply(a$value[k], a$month[k], mean)
  data.frame(year = a$year, month = a$month,
             value = a$value - as.numeric(cl[as.character(a$month)]))
}
# ONI-style centred base refreshed every EIX_ROLL_STEP years. A block without a
# full centred window has its window SHIFTED to the nearest full one; `n_clip`
# counts those, restricted to blocks intersecting `win`, and is RETURNED so a
# caller can report the defect rather than inherit it silently.
eix_roll_base <- function(a, win) {
  y_lo <- min(a$year); y_hi <- max(a$year)
  blocks <- sort(unique((a$year %/% EIX_ROLL_STEP) * EIX_ROLL_STEP))
  n_clip <- 0L; n_blk <- 0L
  out <- do.call(rbind, lapply(blocks, function(b) {
    scored <- b + EIX_ROLL_STEP - 1L >= win[1] && b <= win[2]
    if (scored) n_blk <<- n_blk + 1L
    ctr <- b + EIX_ROLL_STEP / 2
    lo <- round(ctr - EIX_ROLL_LEN / 2); hi <- lo + EIX_ROLL_LEN - 1L; clip <- FALSE
    if (lo < y_lo) { lo <- y_lo; hi <- lo + EIX_ROLL_LEN - 1L; clip <- TRUE }
    if (hi > y_hi) { hi <- y_hi; lo <- hi - EIX_ROLL_LEN + 1L; clip <- TRUE }
    if (clip && scored) n_clip <<- n_clip + 1L
    w  <- a$year >= lo & a$year <= hi
    cl <- tapply(a$value[w], a$month[w], mean)
    k  <- a$year >= b & a$year < b + EIX_ROLL_STEP
    data.frame(year = a$year[k], month = a$month[k],
               value = a$value[k] - as.numeric(cl[as.character(a$month[k])]))
  }))
  list(tbl = out[order(out$year, out$month), ], n_clip = n_clip, n_blk = n_blk)
}

# ---- post-hoc adjustments to an ANOMALY series ----------------------
eix_demean <- function(d, win) {
  k <- d$year >= win[1] & d$year <= win[2]
  d$value <- d$value - mean(d$value[k]); d
}
# ⛔ A DETREND IS ONLY VALID INSIDE ITS FITTING WINDOW. Fitted on 1948-2024 and
# applied to the full ERSST record, this imposes **+1.22 degC (+1.39 sigma) at
# 1854** -- a fabricated 19th-century ENSO ramp, over a span 54 % of which lies
# outside the window. In the 2026-09-02 bake-off that artifact WON the native
# span by 24.3 log-units, which is the model exploiting it, not a better index.
# So extrapolation is refused unless the caller says it wants it, and `frac` says
# how far out of sample it went.
EIX_EXTRAP_MAX <- 0.05     # fraction of rows allowed outside the fitting window
eix_detrend <- function(d, win, allow_extrap = FALSE) {
  k  <- d$year >= win[1] & d$year <= win[2]
  if (sum(k) < 24) stop("eix_detrend: fewer than 24 months inside the window")
  frac <- mean(!k)
  if (frac > EIX_EXTRAP_MAX && !allow_extrap)
    stop(sprintf(paste0("eix_detrend: %.0f%% of the series lies OUTSIDE the %d-%d ",
                        "fitting window, so the correction there is EXTRAPOLATED ",
                        "and fabricates signal (at the far end it reached +1.39 sd ",
                        "in the 09-02 bake-off). Restrict the series to the window, ",
                        "or pass allow_extrap = TRUE and say so in the report."),
                 100 * frac, win[1], win[2]))
  tt <- d$year + (d$month - 0.5) / 12
  f  <- stats::lm(d$value[k] ~ tt[k])
  d$value <- d$value - as.numeric(stats::coef(f)[1] + stats::coef(f)[2] * tt)
  attr(d, "extrap_frac") <- frac
  d
}

# ---- ⭐ RELATIVE SST: the OBSERVATIONAL detrend ---------------------
# Nino 3.4 anomaly MINUS the tropical-mean (20S-20N) anomaly, both from the SAME
# product and the SAME base period. It removes the forced mean-state warming
# WITHOUT a statistical fit and WITHOUT a model: the tropical mean IS the forced
# signal, measured rather than estimated ([[threshold_from_obs_or_law]]).
# It is also the physically right quantity -- deep convection and the Walker
# circulation respond to RELATIVE warmth, not absolute SST, and the circulation
# is what carries ENSO into the land carbon flux.
# ⚠ AND IT COSTS ENSO SIGNAL, MEASURED: the tropical mean is ITSELF 44 % ENSO
# (r = 0.667 against Nino 3.4 at a +1 month lag), so subtracting it whole removes
# the lagged tropical response along with the forced warming -- the index loses
# 19 % of its sd (0.877 -> 0.707) and the 09-02 bake-off ranked it LAST.
# `lowpass = TRUE` subtracts only the LOW-FREQUENCY tropical mean, which carries
# the forced trend but not the 2-7 yr ENSO band: sd 0.866 (1 % lost) and +4.0
# log-units recovered. That is the version to use if this route is used at all.
EIX_LF_YEARS <- 21          # centred low-pass, well above the ENSO band
eix_relative_sst <- function(lowpass = FALSE) {
  a <- eix_fixed_base(eix_ersst_box(EIX_BOX_N34))
  t <- eix_fixed_base(eix_ersst_box(EIX_BOX_TROP))
  m <- match(a$year * 12L + a$month, t$year * 12L + t$month)
  stopifnot(!anyNA(m))
  tv <- t$value[m]
  if (lowpass) {
    n <- length(tv); h <- (EIX_LF_YEARS * 12L) %/% 2L
    tv <- vapply(seq_len(n), function(i) mean(tv[max(1, i - h):min(n, i + h)]), numeric(1))
    attr(a, "partial_window") <- sum(seq_len(n) <= h | seq_len(n) > n - h)
  }
  data.frame(year = a$year, month = a$month, value = a$value - tv)
}

# ---- MEI ------------------------------------------------------------
# MEI.ext is BIMONTHLY; the season is assigned to its SECOND month, which is
# MEI_MONTH_RULE in build_calibration_data.R. Kept identical on purpose.
eix_mei_ext <- function(path = ccx_path(EIX_MEI_EXT)) {
  L <- gsub("<[^>]*>", "", readLines(path, warn = FALSE))
  rows <- grep("^[0-9]{4}\t", L, value = TRUE)
  if (!length(rows)) stop("lib_enso_index: no MEI.ext data rows parsed from ", path)
  M <- do.call(rbind, lapply(rows, function(l) as.numeric(strsplit(l, "\t")[[1]])))
  d <- data.frame(year = rep(M[, 1], 12), month = rep(seq_len(12), each = nrow(M)),
                  value = as.vector(M[, -1]))
  d <- d[!is.na(d$value), ]; d[order(d$year, d$month), ]
}
eix_meiv2 <- function() {
  e <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds")))
  e <- e[!is.na(e$mei), c("year", "month", "mei")]
  names(e)[3] <- "value"; e[order(e$year, e$month), ]
}
# ⚠ THE NAME IS NOW HALF TRUE. This returns the Nino 3.4 column exactly as it
# sits in data/forcing_enso.rds -- the 1991-2020 fixed-base anomaly. Since
# RULING A was adopted (2026-09-02) `ccx_build_forcing()` removes that column's
# 1948-2024 mean, so what SHIPS is `eix_demean(eix_nino34_shipped(),
# FORC_ENSO_DEMEAN_WIN)`. Read this as "the stored column", and reach for the
# demeaned form when you want what the model actually sees.
eix_nino34_shipped <- function() {
  e <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds")))
  e <- e[!is.na(e$nino34_anom), c("year", "month", "nino34_anom")]
  names(e)[3] <- "value"; e[order(e$year, e$month), ]
}

# ---- summary statistics, one definition ------------------------------
eix_stats <- function(d, win) {
  k <- d$year >= win[1] & d$year <= win[2]
  if (sum(k) < 24) return(c(n = sum(k), mean = NA, sd = NA, trend = NA))
  tt <- d$year[k] + (d$month[k] - 0.5) / 12
  c(n = sum(k), mean = mean(d$value[k]), sd = stats::sd(d$value[k]),
    trend = unname(stats::coef(stats::lm(d$value[k] ~ tt))[2]) * 10)
}
