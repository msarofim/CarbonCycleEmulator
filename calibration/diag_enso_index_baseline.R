# =====================================================================
# diag_enso_index_baseline.R -- RULING A's measurement: does the ENSO index
# get to carry a non-zero MEAN and a TREND into a 35.5-yr land chain?
#
# WHY THIS IS OWED. 2026-09-02 made the ENSO land term a ONE-WAY GPP
# MODULATION (`1df8654`). The price was -65.74 log-units at fixed parameters,
# and the diagnosis was that the price is a property of the FORCING, not of the
# structure: `nino34_anom` averages -0.218 over 1948-2024 and is identically 0
# before, so a sustained anomaly that used to load onto `soil_fast` alone
# (tau = 2.0 yr) now loads onto the whole land chain (35.5 yr).
#
# WHY THE MEAN IS NOT ZERO, and this is the substance of the ruling.
# data-raw/build_calibration_data.R anomalises Nino 3.4 against
# ENSO_CLIM_BASE = 1991-2020 -- the WMO normal, a FIXED and RECENT base. The
# tropical Pacific warmed over the record, so the early decades sit below zero
# BY CONSTRUCTION. That warming is mean-state, not ENSO; the model already
# carries GMST as its own forcing and a `q10` respiration path on it. Leaving
# the offset in makes `gamma_enso_land_*` absorb a base-period convention.
#
# ⛔ THIS FILE DOES NOT DECIDE. It prices the four candidate conventions at ONE
# fixed 25-parameter vector so the ruling is made on numbers. Nothing in `data/`
# or `R/` is modified; the treatments are applied by wrapping
# ccx_build_forcing() for the duration of one measurement and restoring it.
#
# THE FOUR TREATMENTS
#   asis     the shipped index. 1991-2020 base, mean -0.218 over the span.
#   demean   subtract the span mean. Removes the STEP at 1948; leaves the trend.
#   detrend  remove a linear fit over the span. Removes mean AND mean-state warming.
#   roll     ONI-style: centred 30-yr base refreshed every 5 yr, rebuilt from the
#            ABSOLUTE Nino 3.4 SST in nina34.data. ⚠ that record starts in 1948,
#            so the early blocks CANNOT have a centred window -- they are
#            CLIPPED, and the clipping is REPORTED rather than hidden.
# THE EXTENSION THAT DID NOT SURVIVE ITS OWN CONTROL. `roll`'s clipping falls on
# the EARLY blocks, which is exactly where the mean-state offset is largest, so
# an UNCLIPPED rolling base is the version worth pricing. It needs SST from 1933
# and nina34.data starts in 1948, so the local ERSSTv5 netCDF was the candidate
# extension -- `fix_v5` (same base period, other product) as the control and
# `roll_full` (rolling base, no early clipping) as the treatment.
#
# ⛔ GATE G-P REFUSES THEM, and the refusal is the finding. nina34.data's own
# footer says ERSST **V6**; the local netCDF is v5. Deseasonalised over the
# shared 1991-2020 window the two agree in PHASE (r 0.984) and disagree in
# AMPLITUDE: regressing PSL on the v5 average gives slope 0.842, i.e. the v5
# index swings ~19 % wider. That is FIVE TIMES the entire sd spread of the four
# conventions this file exists to separate (3.3 %), so any `roll_full` minus
# `fix_v5` difference prices an amplitude mismatch and calls it a convention.
# ⚠ IT IS NOT AN EXTRACTION BUG, which was checked before it was blamed on the
# product: the equatorial profile of the local file is textbook (warm pool
# 29.5 degC at 150E, cold tongue 24.7 at 90-100W), the lag scan peaks at 0, and
# no box or weighting variant tried -- flat vs cos, +/-1 grid cell in either
# direction, 6S-6N -- brings the slope inside.
# ⇒ TO PRICE AN UNCLIPPED ROLLING BASE, PULL THE **v6** Nino 3.4 RECORD back to
#   at least 1933. That is a download and a MANIFEST entry, not a code change.
#
# THE GATES, because a wrapper that silently does nothing looks exactly like a
# treatment that costs nothing ([[broken_gate_reports_nothing]]):
#   G-I  IDENTITY -- `asis` through the wrapper must reproduce the UNWRAPPED
#        logpost to the bit. If it does not, the wrapper is not a no-op and no
#        other number here means anything.
#   G-F  FIRED -- the wrapper must have been called at least once per treatment.
#   G-M  MUTATION -- a deliberate +EI_MUT_OFFSET offset must move the logpost.
#        A treatment machinery that cannot move the objective cannot price one
#        ([[mutation_test_gates]]).
#   G-B  INTENT -- each treatment's realised mean/trend in the BUILT column must
#        match what its name claims, measured after interpolation, not before.
#
# Usage:  Rscript calibration/diag_enso_index_baseline.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))

# ---- labels derive from named constants (project rule) --------------
EI_ARM        <- "from90"
EI_BASIN      <- "calibration/output/multistart_20260901_enso25/start_000.rds"
EI_WIN        <- c(1948, 2024)      # the ENSO-active record, as in the pre-check
EI_CLIM_BASE  <- c(1991, 2020)      # = ENSO_CLIM_BASE in build_calibration_data.R
EI_ROLL_LEN   <- 30                 # ONI centred base-period length, years
EI_ROLL_STEP  <- 5                  # ONI base-period refresh interval, years
EI_MUT_OFFSET <- 1.0                # deg C, the G-M mutation
EI_RAW        <- file.path("data-raw", "downloads", "nina34.data")
EI_RAW_MISS   <- -99.99
EI_ERSST      <- file.path("data-raw", "downloads", "ersst_v5_sst_mnmean.nc")
EI_BOX_LAT    <- c(-5, 5)           # Nino 3.4, 5S-5N   (= the nina34.data box)
EI_BOX_LON    <- c(190, 240)        # Nino 3.4, 170W-120W in degrees east
EI_ERSST_EPOCH <- "1800-01-01"      # the netCDF's `days since` origin
EI_PRE_FILE   <- file.path("outputs", "diagnostics", "enso_gpp_margin_pre.rds")
EI_OUT        <- file.path("outputs", "diagnostics", "enso_index_baseline.rds")
EI_TREATMENTS <- c("asis", "demean", "detrend", "roll")   # the shipped product
EI_EXTEND     <- c("fix_v5", "roll_full")                 # priced ONLY if G-P passes
EI_HEAD       <- tryCatch(system("git rev-parse HEAD", intern = TRUE)[[1]],
                          error = function(e) NA_character_)

cat(sprintf("\n%s\nRULING A: WHAT BASELINE CONVENTION DOES THE ENSO INDEX GET?\n  arm %s, basin %s, span %d-%d, commit %s\n%s\n",
            strrep("=", 78), EI_ARM, basename(dirname(EI_BASIN)),
            EI_WIN[1], EI_WIN[2], substr(EI_HEAD, 1, 7), strrep("=", 78)))

# =====================================================================
# 1. THE INDEX ITSELF -- mean, trend, and where they come from
# =====================================================================
en_ship <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds")))
en_ship <- en_ship[!is.na(en_ship$nino34_anom), c("year", "month", "nino34_anom")]
names(en_ship)[3] <- "value"

ei_span <- function(d) d$year >= EI_WIN[1] & d$year <= EI_WIN[2]
ei_stats <- function(yr, mo, v) {
  tt <- yr + (mo - 0.5) / 12
  fit <- stats::lm(v ~ tt)
  c(mean = mean(v), trend = unname(stats::coef(fit)[2]) * 10, sd = stats::sd(v))
}
s0 <- ei_stats(en_ship$year[ei_span(en_ship)], en_ship$month[ei_span(en_ship)],
               en_ship$value[ei_span(en_ship)])
cat(sprintf("\n=== 1. THE SHIPPED INDEX (base %d-%d, the WMO normal) ===\n",
            EI_CLIM_BASE[1], EI_CLIM_BASE[2]))
cat(sprintf("  over %d-%d: mean %+.4f, trend %+.4f degC/decade, sd %.4f (n = %d months)\n",
            EI_WIN[1], EI_WIN[2], s0[["mean"]], s0[["trend"]], s0[["sd"]],
            sum(ei_span(en_ship))))
ann <- tapply(en_ship$value[ei_span(en_ship)], en_ship$year[ei_span(en_ship)], mean)
dec <- tapply(as.numeric(ann), (as.integer(names(ann)) %/% 10) * 10, mean)
cat("  decadal means: ")
cat(paste(sprintf("%ds %+.2f", as.integer(names(dec)), dec), collapse = "  "), "\n")
cat("  ⇒ the early decades sit BELOW zero because the base period is RECENT.\n")
cat("    That gradient is mean-state warming of the Nino 3.4 box, not ENSO.\n")

# =====================================================================
# 2. THE FOUR CANDIDATE INDICES
# =====================================================================
# ---- ONI-style rolling base, rebuilt from the ABSOLUTE SST ----------
ei_read_psl <- function(path, missing) {
  ln  <- readLines(path)
  hdr <- scan(text = ln[1], quiet = TRUE)
  body <- ln[2:(1 + (hdr[2] - hdr[1] + 1))]
  m <- do.call(rbind, lapply(body, function(l) scan(text = l, quiet = TRUE)))
  d <- data.frame(year = rep(m[, 1], 12),
                  month = rep(seq_len(12), each = nrow(m)),
                  value = as.vector(m[, -1]))
  d$value[d$value %in% missing | d$value < -90] <- NA_real_
  d[order(d$year, d$month), ]
}
# ---- the ABSOLUTE Nino 3.4 SST from ERSSTv5, back to 1854 -----------
# The netCDF is a 2-degree global field; the box is area-weighted by cos(lat),
# which is the same average nina34.data reports. It exists here for ONE reason:
# a centred 30-yr base for 1948 needs SST from 1933, and nina34.data starts in
# 1948. ⚠ It is a DIFFERENT SST VERSION from the shipped index, which is why
# `fix_v5` is priced alongside it rather than assumed immaterial.
ei_nino34_ersst <- function() {
  nc  <- ncdf4::nc_open(ccx_path(EI_ERSST))
  on.exit(ncdf4::nc_close(nc), add = TRUE)
  lat <- ncdf4::ncvar_get(nc, "lat"); lon <- ncdf4::ncvar_get(nc, "lon")
  tm  <- ncdf4::ncvar_get(nc, "time")
  il  <- which(lat >= EI_BOX_LAT[1] & lat <= EI_BOX_LAT[2])
  io  <- which(lon >= EI_BOX_LON[1] & lon <= EI_BOX_LON[2])
  if (!length(il) || !length(io)) stop("the Nino 3.4 box selected no grid cells")
  sst <- ncdf4::ncvar_get(nc, "sst", start = c(min(io), min(il), 1),
                          count = c(length(io), length(il), -1))
  W   <- matrix(rep(cos(lat[il] * pi / 180), each = length(io)), nrow = length(io))
  v   <- apply(sst, 3, function(m) sum(m * W, na.rm = TRUE) / sum(W * is.finite(m)))
  d   <- as.Date(EI_ERSST_EPOCH) + tm
  data.frame(year = as.integer(format(d, "%Y")),
             month = as.integer(format(d, "%m")), value = v)
}

# ---- the two base-period conventions, as functions of an ABSOLUTE series ----
ei_fixed_base <- function(a) {
  k  <- a$year >= EI_CLIM_BASE[1] & a$year <= EI_CLIM_BASE[2]
  cl <- tapply(a$value[k], a$month[k], mean)
  data.frame(year = a$year, month = a$month,
             value = a$value - as.numeric(cl[as.character(a$month)]))
}
# ⚠ THE CLIPPING IS REPORTED, NOT HIDDEN. A centred EI_ROLL_LEN window needs
# EI_ROLL_LEN/2 years on each side; a block without them has its window shifted
# to the nearest FULL one. That is standard practice at a record end and it is
# also exactly where the mean-state bias is largest, so the count is returned.
# ⚠ THE COUNT IS OVER BLOCKS THAT INTERSECT EI_WIN. Blocks outside the scored
# span cannot affect any number here, and counting them would inflate the
# reported defect of a series that is long enough where it matters.
ei_roll_base <- function(a) {
  y_lo <- min(a$year); y_hi <- max(a$year)
  blocks <- sort(unique((a$year %/% EI_ROLL_STEP) * EI_ROLL_STEP))
  n_clip <- 0L; n_blk <- 0L
  out <- do.call(rbind, lapply(blocks, function(b) {
    scored <- b + EI_ROLL_STEP - 1L >= EI_WIN[1] && b <= EI_WIN[2]
    if (scored) n_blk <<- n_blk + 1L
    ctr <- b + EI_ROLL_STEP / 2
    lo  <- round(ctr - EI_ROLL_LEN / 2); hi <- lo + EI_ROLL_LEN - 1L
    clipped <- FALSE
    if (lo < y_lo) { lo <- y_lo; hi <- lo + EI_ROLL_LEN - 1L; clipped <- TRUE }
    if (hi > y_hi) { hi <- y_hi; lo <- hi - EI_ROLL_LEN + 1L; clipped <- TRUE }
    if (clipped && scored) n_clip <<- n_clip + 1L
    w  <- a$year >= lo & a$year <= hi
    cl <- tapply(a$value[w], a$month[w], mean)
    k  <- a$year >= b & a$year < b + EI_ROLL_STEP
    data.frame(year = a$year[k], month = a$month[k],
               value = a$value[k] - as.numeric(cl[as.character(a$month[k])]))
  }))
  out <- out[order(out$year, out$month), ]
  list(tbl = out, n_clip = n_clip, n_blk = n_blk)
}

abs_v6  <- ei_read_psl(ccx_path(EI_RAW), EI_RAW_MISS)
abs_v6  <- abs_v6[!is.na(abs_v6$value), ]
abs_v5  <- ei_nino34_ersst()
r_v6    <- ei_roll_base(abs_v6)
r_v5    <- ei_roll_base(abs_v5)
en_roll <- r_v6$tbl
en_fix5 <- ei_fixed_base(abs_v5)
en_rollf<- r_v5$tbl

ei_make <- function(kind) {
  d <- en_ship
  k <- ei_span(d)
  if (kind == "asis")    return(d)
  if (kind == "demean") { d$value <- d$value - mean(d$value[k]); return(d) }
  if (kind == "detrend") {
    tt  <- d$year + (d$month - 0.5) / 12
    fit <- stats::lm(d$value[k] ~ tt[k])
    d$value <- d$value - as.numeric(stats::coef(fit)[1] + stats::coef(fit)[2] * tt)
    return(d)
  }
  if (kind == "roll")     return(en_roll)
  if (kind == "fix_v5")   return(en_fix5)
  if (kind == "roll_full")return(en_rollf)
  if (kind == "mutate") { d$value <- d$value + EI_MUT_OFFSET; return(d) }
  stop("unknown treatment: ", kind)
}

cat(sprintf("\n=== 2. THE CANDIDATE INDICES (ONI base %d yr, refreshed every %d) ===\n",
            EI_ROLL_LEN, EI_ROLL_STEP))
cat(sprintf("  roll      (nina34.data, from %d): %d scored blocks, %d CLIPPED\n",
            min(abs_v6$year), r_v6$n_blk, r_v6$n_clip))
cat(sprintf("  roll_full (ERSSTv5,      from %d): %d scored blocks, %d CLIPPED\n",
            min(abs_v5$year), r_v5$n_blk, r_v5$n_clip))
cat(sprintf("\n  %-8s | %9s %11s %8s\n", "index", "mean", "trend/dec", "sd"))
for (kd in c(EI_TREATMENTS, EI_EXTEND)) {
  d <- ei_make(kd); k <- ei_span(d)
  s <- ei_stats(d$year[k], d$month[k], d$value[k])
  cat(sprintf("  %-9s| %+9.4f %+11.4f %8.4f%s\n", kd, s[["mean"]], s[["trend"]], s[["sd"]],
              if (kd %in% EI_EXTEND) "   (ERSSTv5)" else ""))
}

# =====================================================================
# 3. THE PRICE OF EACH, AT ONE FIXED 25-PARAMETER VECTOR
# =====================================================================
pm <- ccx_migrate_par_set(readRDS(ccx_path(EI_BASIN))$par_mode)
u0 <- ccx_par_to_unc(pm)
stopifnot(all(is.finite(u0)))
v  <- dg_vector(EI_ARM)
bp <- ccx_default_params(); bp$pump_mode <- v$md$pump_mode

.EI_ORIG  <- ccx_build_forcing
.EI_STATE <- new.env(parent = emptyenv())
ei_install <- function(tbl) {
  .EI_STATE$n <- 0L; .EI_STATE$mean <- NA_real_; .EI_STATE$trend <- NA_real_
  assign("ccx_build_forcing", function(...) {
    F <- .EI_ORIG(...)
    en <- tbl[!is.na(tbl$value), ]
    e  <- stats::approx(en$year + (en$month - 0.5) / 12, en$value,
                        xout = F$t, rule = 2)$y
    e[F$year < min(en$year)] <- FORC_ENSO_PRE1948
    F$enso <- e
    kk <- F$year >= EI_WIN[1] & F$year <= EI_WIN[2]
    st <- ei_stats(F$year[kk], F$month[kk], F$enso[kk])
    .EI_STATE$n <- .EI_STATE$n + 1L
    .EI_STATE$mean <- st[["mean"]]; .EI_STATE$trend <- st[["trend"]]
    F
  }, envir = globalenv())
}
ei_restore <- function() assign("ccx_build_forcing", .EI_ORIG, envir = globalenv())

ei_price <- function(kind) {
  ei_install(ei_make(kind))
  on.exit(ei_restore(), add = TRUE)
  lp  <- ccx_make_logpost(base_params = bp)
  val <- lp(u0)
  list(logpost = val, fired = .EI_STATE$n,
       mean = .EI_STATE$mean, trend = .EI_STATE$trend)
}

cat("\n=== 3. THE PRICE AT THE 09-01 BASIN VECTOR (25 par, migrated) ===\n")
lp_bare  <- ccx_make_logpost(base_params = bp)
v_bare   <- lp_bare(u0)
cat(sprintf("  UNWRAPPED logpost, this build, shipped index: %.6f\n", v_bare))

res <- lapply(EI_TREATMENTS, ei_price); names(res) <- EI_TREATMENTS
mut <- ei_price("mutate")
# ⛔ THE EXTENSION IS NOT PRICED UNLESS G-P LICENSES IT. Computing the numbers
# and then declining to interpret them is how a refused comparison gets quoted
# anyway; the run below is conditional so there is nothing to quote.

# ---- THE GATES ------------------------------------------------------
cat("\n  --- GATES ---\n")
g_i <- isTRUE(all.equal(res$asis$logpost, v_bare, tolerance = 0))
cat(sprintf("  G-I IDENTITY : wrapped `asis` %.6f vs unwrapped %.6f -> %s\n",
            res$asis$logpost, v_bare, if (g_i) "PASS (bit-identical)" else "⛔ FAIL"))
if (!g_i)
  stop("the wrapper is not a no-op on the shipped index. Every price below ",
       "would be confounded with a wrapper artefact. Refusing to report.")
g_f <- all(vapply(res, function(r) r$fired >= 1L, logical(1)))
cat(sprintf("  G-F FIRED    : calls per treatment %s -> %s\n",
            paste(vapply(res, function(r) r$fired, integer(1)), collapse = "/"),
            if (g_f) "PASS" else "⛔ FAIL"))
if (!g_f) stop("the wrapper never fired; the treatments were not applied.")
d_mut <- mut$logpost - v_bare
cat(sprintf("  G-M MUTATION : a %+.2f offset moves the logpost %+.2f -> %s\n",
            EI_MUT_OFFSET, d_mut,
            if (abs(d_mut) > 1) "PASS (the machinery has power)" else "⛔ FAIL"))
if (!(abs(d_mut) > 1))
  stop("a full-degree offset does not move the objective; this file cannot ",
       "price a baseline convention ([[mutation_test_gates]]).")
# G-P PRODUCT -- may the ERSSTv5 rows be differenced against the v6 ones at all?
# ⚠ THE BOUND IS DERIVED FROM THE SPREAD IT MUST RESOLVE, not typed
# ([[tolerance_scaled_to_spread]]). The four v6 conventions differ from one
# another by EI_CONV_SPREAD in anomaly sd; a product whose amplitude differs by
# more than that cannot be differenced against them, because the difference
# would be mostly product. Compared on the DESEASONALISED series over the shared
# climatology window, so the comparison is of ENSO amplitude and not of a
# seasonal cycle or a mean either base period removes anyway.
sd_conv <- vapply(EI_TREATMENTS, function(kd) {
             d <- ei_make(kd); k <- ei_span(d); stats::sd(d$value[k]) }, numeric(1))
EI_CONV_SPREAD <- (max(sd_conv) - min(sd_conv)) / stats::sd(en_ship$value[ei_span(en_ship)])

ia <- en_ship; ip <- ei_fixed_base(abs_v5)
mp <- match(ia$year * 12L + ia$month, ip$year * 12L + ip$month)
kp <- !is.na(mp) & ia$year >= EI_CLIM_BASE[1] & ia$year <= EI_CLIM_BASE[2]
cA <- tapply(ia$value[kp], ia$month[kp], mean); cP <- tapply(ip$value[mp[kp]], ia$month[kp], mean)
aA <- ia$value[kp]     - as.numeric(cA[as.character(ia$month[kp])])
aP <- ip$value[mp[kp]] - as.numeric(cP[as.character(ia$month[kp])])
slope <- unname(stats::coef(stats::lm(aA ~ aP))[2])
g_p   <- abs(slope - 1) <= EI_CONV_SPREAD
cat(sprintf("  G-P PRODUCT  : ERSSTv5 vs the shipped v6 index, deseasonalised %d-%d:\n",
            EI_CLIM_BASE[1], EI_CLIM_BASE[2]))
cat(sprintf("                 r %.4f (phase agrees), amplitude slope %.3f\n",
            stats::cor(aA, aP), slope))
cat(sprintf("                 bound |slope-1| <= %.4f, the sd spread of the %d\n",
            EI_CONV_SPREAD, length(EI_TREATMENTS)))
cat(sprintf("                 conventions it must separate -> %s\n",
            if (g_p) "PASS" else sprintf("⛔ FAIL (%.1fx the bound)",
                                         abs(slope - 1) / EI_CONV_SPREAD)))
# ⚠ A GATE THAT CAN ONLY FAIL IS AS UNINFORMATIVE AS ONE THAT CAN ONLY PASS
# (ruling 2, `c811b82`). G-P is exercised in BOTH directions here: against the
# shipped index itself, where the slope is 1 by construction and it must PASS.
ei_slope <- function(a, b) unname(stats::coef(stats::lm(a ~ b))[2])
EI_GP_MUT <- 1 + 2 * EI_CONV_SPREAD    # a scaling the bound must reject, derived
sl_id  <- ei_slope(aA, aA * 1)                       # the index against itself
sl_mut <- ei_slope(aA, aA * EI_GP_MUT)               # deliberately rescaled
if (!(abs(sl_id - 1) <= EI_CONV_SPREAD))
  stop("G-P rejects the shipped index against ITSELF (slope ", signif(sl_id, 6),
       "). A gate that cannot pass cannot license anything.")
if (abs(sl_mut - 1) <= EI_CONV_SPREAD)
  stop("G-P accepts a product rescaled by ", signif(EI_GP_MUT, 4),
       " (slope ", signif(sl_mut, 6), "). A gate that cannot fail is not a gate.")
cat(sprintf("                 ⤷ mutation, BOTH directions: itself -> slope %.3f\n", sl_id))
cat(sprintf("                   PASS; rescaled x%.3f -> slope %.3f FAIL.\n",
            EI_GP_MUT, sl_mut))

g_b <- TRUE
for (kd in EI_TREATMENTS) {
  want <- switch(kd, demean = 0, detrend = 0, NA_real_)   # roll/asis unconstrained
  got  <- res[[kd]]$mean
  ok   <- is.na(want) || abs(got - want) < 1e-8
  g_b  <- g_b && ok
  cat(sprintf("  G-B INTENT   : %-8s built-column mean %+.6f trend %+.4f/dec %s\n",
              kd, got, res[[kd]]$trend,
              if (is.na(want)) "(unconstrained)" else if (ok) "PASS" else "⛔ FAIL"))
}
if (!g_b) stop("a treatment's realised mean does not match its name.")

# ---- THE TABLE ------------------------------------------------------
pre <- if (file.exists(ccx_path(EI_PRE_FILE))) readRDS(ccx_path(EI_PRE_FILE)) else NULL
cat(sprintf("\n  %-8s | %14s %12s | %s\n", "index", "logpost", "vs asis",
            if (is.null(pre)) "" else "vs PRE-restructuring"))
for (kd in EI_TREATMENTS) {
  r <- res[[kd]]
  cat(sprintf("  %-8s | %14.4f %+12.4f | %s\n", kd, r$logpost,
              r$logpost - res$asis$logpost,
              if (is.null(pre)) "" else sprintf("%+.4f", r$logpost - pre$logpost)))
}
cat("\n  --- THE UNCLIPPED ROLLING BASE ---\n")
ext <- NULL
if (g_p) {
  ext <- lapply(EI_EXTEND, ei_price); names(ext) <- EI_EXTEND
  cat(sprintf("  SST PRODUCT  (fix_v5 - asis)     : %+9.4f  same base, other product\n",
              ext$fix_v5$logpost - res$asis$logpost))
  cat(sprintf("  CONVENTION   (roll_full - fix_v5): %+9.4f  same product, rolling vs fixed\n",
              ext$roll_full$logpost - ext$fix_v5$logpost))
  cat(sprintf("  ⇒ unclipped rolling base vs the best mean-only treatment: %+.4f\n",
              ext$roll_full$logpost - res$demean$logpost))
} else {
  cat(sprintf("  ⛔ NOT PRICED. G-P FAILED: the only long SST record on disk is\n"))
  cat(sprintf("     ERSSTv5 and the shipped index is v6, %.1fx too far apart in\n",
              abs(slope - 1) / EI_CONV_SPREAD))
  cat("     amplitude to difference against. `roll`'s CLIPPING and the CONVENTION\n")
  cat(sprintf("     therefore remain CONFOUNDED, and `roll`'s %+.4f is a LOWER BOUND\n",
              res$roll$logpost - res$asis$logpost))
  cat("     on what the convention is worth -- the clipped blocks are the EARLY\n")
  cat("     ones, which is exactly where the mean-state offset is largest.\n")
  cat(sprintf("     ⇒ TO SETTLE IT: pull the ERSST **v6** Nino 3.4 record back to\n"))
  cat(sprintf("       %d (a centred %d-yr base for %d needs it), add a MANIFEST\n",
              EI_WIN[1] - EI_ROLL_LEN / 2, EI_ROLL_LEN, EI_WIN[1]))
  cat("       entry, and re-run. No code here changes.\n")
}

if (!is.null(pre)) {
  cat(sprintf("\n  ⚠ the PRE column is the 09-02 pre-restructuring build (%s, %s),\n",
              substr(pre$commit, 1, 7), format(pre$when, "%Y-%m-%d")),
      sep = "")
  cat(sprintf("    logpost %.4f. `asis` minus PRE = %+.4f reproduces the recorded price.\n",
              pre$logpost, res$asis$logpost - pre$logpost))
  cat("    ⛔ THE OTHER ROWS MIX TWO CHANGES (structure AND convention) and are\n")
  cat("      the number that matters for where a refit STARTS, not a price of\n")
  cat("      the convention alone -- that is the `vs asis` column.\n")
}

saveRDS(list(treatments = res, extension = ext, mutation = mut,
             product_slope = slope, product_bound = EI_CONV_SPREAD, g_p = g_p,
             bare = v_bare, pre = pre,
             index_stats = lapply(setNames(c(EI_TREATMENTS, EI_EXTEND),
                                           c(EI_TREATMENTS, EI_EXTEND)), function(kd) {
               d <- ei_make(kd); k <- ei_span(d)
               ei_stats(d$year[k], d$month[k], d$value[k]) }),
             n_clip = c(roll = r_v6$n_clip, roll_full = r_v5$n_clip),
             n_blk = c(roll = r_v6$n_blk, roll_full = r_v5$n_blk), win = EI_WIN,
             clim_base = EI_CLIM_BASE, roll = c(EI_ROLL_LEN, EI_ROLL_STEP),
             arm = EI_ARM, basin = EI_BASIN, commit = EI_HEAD, when = Sys.time()),
        ccx_path(EI_OUT))
cat(sprintf("\n  written: %s\n", EI_OUT))
cat(sprintf("\n%s\n⛔ THIS FILE DOES NOT RULE. It hands the ruling %d numbers and one refusal.\n%s\n",
            strrep("=", 78), length(EI_TREATMENTS), strrep("=", 78)))
