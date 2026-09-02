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
#            ABSOLUTE Nino 3.4 SST. ⚠ the record is 1948-2026, so the first and
#            last blocks CANNOT have a centred window -- they are CLIPPED, and
#            the clipping is REPORTED rather than hidden.
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
EI_PRE_FILE   <- file.path("outputs", "diagnostics", "enso_gpp_margin_pre.rds")
EI_OUT        <- file.path("outputs", "diagnostics", "enso_index_baseline.rds")
EI_TREATMENTS <- c("asis", "demean", "detrend", "roll")
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
abs_sst <- ei_read_psl(ccx_path(EI_RAW), EI_RAW_MISS)
abs_sst <- abs_sst[!is.na(abs_sst$value), ]

# ⚠ THE CLIPPING IS REPORTED, NOT HIDDEN. A centred EI_ROLL_LEN window needs
# EI_ROLL_LEN/2 years on each side; the record's first and last blocks have
# neither, so their window is shifted to the nearest FULL one. That is the
# standard NOAA practice at the record ends and it is also exactly where the
# trend bias is largest, so the count of shifted blocks is printed.
y_lo <- min(abs_sst$year); y_hi <- max(abs_sst$year)
blocks <- sort(unique((abs_sst$year %/% EI_ROLL_STEP) * EI_ROLL_STEP))
n_clip <- 0L
en_roll <- do.call(rbind, lapply(blocks, function(b) {
  ctr <- b + EI_ROLL_STEP / 2
  lo  <- round(ctr - EI_ROLL_LEN / 2); hi <- lo + EI_ROLL_LEN - 1L
  if (lo < y_lo) { lo <- y_lo; hi <- lo + EI_ROLL_LEN - 1L; n_clip <<- n_clip + 1L }
  if (hi > y_hi) { hi <- y_hi; lo <- hi - EI_ROLL_LEN + 1L; n_clip <<- n_clip + 1L }
  cl <- tapply(abs_sst$value[abs_sst$year >= lo & abs_sst$year <= hi],
               abs_sst$month[abs_sst$year >= lo & abs_sst$year <= hi], mean)
  k  <- abs_sst$year >= b & abs_sst$year < b + EI_ROLL_STEP
  data.frame(year = abs_sst$year[k], month = abs_sst$month[k],
             value = abs_sst$value[k] - as.numeric(cl[as.character(abs_sst$month[k])]))
}))
en_roll <- en_roll[order(en_roll$year, en_roll$month), ]

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
  if (kind == "roll")    return(en_roll)
  if (kind == "mutate") { d$value <- d$value + EI_MUT_OFFSET; return(d) }
  stop("unknown treatment: ", kind)
}

cat(sprintf("\n=== 2. THE CANDIDATE INDICES (ONI base %d yr, refreshed every %d) ===\n",
            EI_ROLL_LEN, EI_ROLL_STEP))
cat(sprintf("  rolling base: %d blocks, %d of them CLIPPED at a record end\n",
            length(blocks), n_clip))
cat(sprintf("\n  %-8s | %9s %11s %8s\n", "index", "mean", "trend/dec", "sd"))
for (kd in EI_TREATMENTS) {
  d <- ei_make(kd); k <- ei_span(d)
  s <- ei_stats(d$year[k], d$month[k], d$value[k])
  cat(sprintf("  %-8s | %+9.4f %+11.4f %8.4f\n", kd, s[["mean"]], s[["trend"]], s[["sd"]]))
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
g_b <- TRUE
for (kd in EI_TREATMENTS) {
  want <- switch(kd, asis = NA_real_, demean = 0, detrend = 0, roll = NA_real_)
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

saveRDS(list(treatments = res, mutation = mut, bare = v_bare, pre = pre,
             index_stats = lapply(setNames(EI_TREATMENTS, EI_TREATMENTS), function(kd) {
               d <- ei_make(kd); k <- ei_span(d)
               ei_stats(d$year[k], d$month[k], d$value[k]) }),
             n_clip = n_clip, blocks = length(blocks), win = EI_WIN,
             clim_base = EI_CLIM_BASE, roll = c(EI_ROLL_LEN, EI_ROLL_STEP),
             arm = EI_ARM, basin = EI_BASIN, commit = EI_HEAD, when = Sys.time()),
        ccx_path(EI_OUT))
cat(sprintf("\n  written: %s\n", EI_OUT))
cat(sprintf("\n%s\n⛔ THIS FILE DOES NOT RULE. It hands the ruling four numbers.\n%s\n",
            strrep("=", 78), strrep("=", 78)))
