# =====================================================================
# pulse_band.R -- CarboTope's CARBON-CYCLE UNCERTAINTY on the Pulse lab's pulse: a 100 GtC
# release in 2050, run for a subsample of the hilda31w MCMC posterior draws, beside FaIR
# 2.2.4 (calib 1.6.0)'s 841-configuration band for the same pulse.
#
# WHY. Marcus 2026-10-15: "How does CarboTope's carbon uncertainty compare to FaIR's?", then
# "Run both, 200 draws for the pulse band". The app's Pulse lab draws one best-fit line;
# FaIR's grid (data/fair_pulse_grid.rds) carries a 5-95 % band. This driver supplies the
# missing CarboTope band. Nothing here is read by the app.
#
# DRAWS. PB_N rows of outputs/mcmc_check_20261014_hilda31w_200k/pooled_u_thin2.rds (17 000 rows,
# chain by chain), at evenly spaced indices: round(seq(1, nrow, length.out = PB_N)). No RNG: the
# selection is a fixed rule, so it spans all four chains equally. The chains' own seeds are in
# the draws file's provenance and are copied into this artifact's.
#
# EACH DRAW is decoded and run exactly as calibration/build_futures_ribbons.R runs its draws
# (that block is repeated here verbatim: the mode's structure, gate, pins and bands, then
# ccx_mode_run_params() and app_spinup()), and each background is run as server.R's
# pulse_runs() runs it: a base and a pulse arm, both with APP_PULSE_EMIS_METHOD.
#
# GATES.
#   GC  the decoded MODE through this machinery reproduces the app's own central pulse runs
#       (APP_SPIN, default bomb/luc) to PB_CENTRAL_TOL ppm. Tolerance = the band builder's
#       RB_CENTRAL_TOL.
#   GCm mutation: the mode with beta_max x (1 + PB_MUT_FRAC) must FAIL GC (power check).
#   G99 >= 99 % of draws run (the band builder's rule), or nothing is written.
#
# REPRODUCIBILITY. No RNG and no wall-clock time in the artifact, so two runs at one commit
# must be byte-identical (checked at a small --n with --out-tag).
#
# Usage (repo root, or a frozen copy of it):
#   Rscript outputs/diagnostics/carbon_spread_20261015/pulse_band.R [--n=200] [--cores=6]
#           [--out-tag=] [--commit=<sha>]
# =====================================================================
PB_ARGS <- commandArgs(trailingOnly = TRUE)
pb_arg <- function(key, default) {
  hit <- grep(sprintf("^--%s=", key), PB_ARGS, value = TRUE)
  if (length(hit)) sub(sprintf("^--%s=", key), "", hit[1]) else default
}
PB_ROOT <- normalizePath(getwd())
stopifnot(file.exists(file.path(PB_ROOT, "DESIGN.md")))
PB_T0 <- Sys.time()

suppressMessages(library(shiny))
setwd(file.path(PB_ROOT, "app"))
invisible(utils::capture.output(suppressWarnings(suppressMessages(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv())))))
setwd(PB_ROOT)

# ---- named constants: every label and filename derives from these --------
PB_DRIVER      <- "outputs/diagnostics/carbon_spread_20261015/pulse_band.R"
PB_DIR         <- file.path(PB_ROOT, dirname(PB_DRIVER))
PB_N           <- as.integer(pb_arg("n", 200L))
PB_CORES       <- as.integer(pb_arg("cores", 6L))
PB_OUT_TAG     <- pb_arg("out-tag", "")
PB_DRAWS_FILE  <- "outputs/mcmc_check_20261014_hilda31w_200k/pooled_u_thin2.rds"
PB_BGS         <- c("vvL", "vvM", "vvH")      # the Low / Medium / High backgrounds compared in chat
PB_YEAR        <- 2050L                       # the Pulse lab's default release year
PB_GTC         <- 100                         # the Pulse lab's default size = FaIR's grid size
PB_YEARS       <- APP_PULSE_YEARS             # the Pulse lab's run span
PB_PROBS       <- c(0.05, 0.50, 0.95)         # FaIR's band is 5-95 %
PB_KEY_YEARS   <- c(2060L, 2075L, 2100L, 2150L, 2200L, 2250L, 2300L)
PB_CENTRAL_TOL <- 1e-6                        # ppm: = build_futures_ribbons.R's RB_CENTRAL_TOL
PB_MUT_NAME    <- "beta_max"
PB_MUT_FRAC    <- 0.01
PB_FAIR_FILE   <- file.path("data", APP_FAIR_PULSE_FILE)
PB_STEM        <- paste0("pulse_band", if (nzchar(PB_OUT_TAG)) paste0("_", PB_OUT_TAG) else "")
PB_OUT_RDS     <- file.path(PB_DIR, paste0(PB_STEM, ".rds"))
PB_OUT_CSV     <- file.path(PB_DIR, paste0(PB_STEM, "_key_years.csv"))
PB_OUT_DRAWS   <- file.path(PB_DIR, paste0(PB_STEM, "_draws.csv"))
PB_LOG         <- file.path(PB_DIR, paste0(PB_STEM, ".log"))
PB_COMMIT <- if (nzchar(pb_arg("commit", ""))) paste(pb_arg("commit", ""), "(frozen copy)") else
  ccx_git_stamp()

sink(PB_LOG, split = TRUE)
cat(sprintf("=== %s @%s, run %s ===\n", PB_DRIVER, PB_COMMIT, format(PB_T0, "%Y-%m-%d %H:%M")))

# ---- the mode, as build_futures_ribbons.R resolves it (verbatim) ----------
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
RB_BASE <- ccx_mode_base(md)
RB_GATE <- ccx_apply_gate(ccx_mode_struct(md))
RB_PINS <- ccx_mode_pins(md)
invisible(ccx_apply_pins(RB_PINS))
ccx_require_param_set(md, PB_DRIVER)
invisible(ccx_adopt_mode_band(md))
ccx_check_mode_decode(md)
u0 <- ccx_par_to_unc(md$par_mode)
stopifnot(identical(names(u0), md$param_names))
cat(sprintf("mode %s (%s); %d fitted names, %d held\n", CCX_MODE_CANONICAL, ccx_mode_struct(md),
            length(u0), length(RB_PINS)))

# ---- one background's pulse pair, as server.R pulse_runs() --------------
pulse_pair <- function(spin, bg, bomb = NULL, luc = NULL) {
  e <- APP_SCEN_EMIS[APP_SCEN_EMIS$scenario == bg, ]
  y <- seq(PB_YEARS[1], PB_YEARS[2])
  base_em <- data.frame(year = y,
                        fossil_GtC = stats::approx(e$year, e$fossil_GtC, xout = y, rule = 2)$y,
                        luc_GtC    = stats::approx(e$year, e$luc_GtC,    xout = y, rule = 2)$y)
  pulse_em <- base_em
  pulse_em$fossil_GtC[pulse_em$year == PB_YEAR] <- pulse_em$fossil_GtC[pulse_em$year == PB_YEAR] + PB_GTC
  run <- function(em) {
    a <- list(spin, bg, PB_YEARS, bg, emissions = em, interp_method = APP_PULSE_EMIS_METHOD)
    if (!is.null(bomb)) a$bomb_total_kmol <- bomb
    if (!is.null(luc))  a$luc_scale <- luc
    do.call(app_run_coupled, a)$climate
  }
  b <- run(base_em); p <- run(pulse_em)
  data.frame(year = b$year, d_co2_ppm = p$co2_ppm - b$co2_ppm,
             share = (p$co2_ppm - b$co2_ppm) / (PB_GTC / ccx_const("GtC_PER_PPM")),
             d_gmst = p$gmst - b$gmst)
}
run_vector <- function(pv) {
  pm <- pv
  for (n in names(RB_PINS)) pm[[n]] <- RB_PINS[[n]]
  rp <- ccx_mode_run_params(md, pm, base = RB_BASE)
  sp <- app_spinup(rp$p)
  nwarn <- 0L
  res <- lapply(PB_BGS, function(bg) withCallingHandlers(
    pulse_pair(sp, bg, rp$bomb_total, rp$luc_scale),
    warning = function(w) { nwarn <<- nwarn + 1L; invokeRestart("muffleWarning") }))
  names(res) <- PB_BGS
  list(res = res, nwarn = nwarn)
}

# ---- GATE GC (+ its mutation): the decoded mode = the app's central pulse ---
cat("\n--- the central line ---\n")
central <- lapply(PB_BGS, function(bg) suppressWarnings(pulse_pair(APP_SPIN, bg)))
names(central) <- PB_BGS
gc_stat <- function(r) max(vapply(PB_BGS, function(bg)
  max(abs(r$res[[bg]]$d_co2_ppm - central[[bg]]$d_co2_ppm)), numeric(1)))
pv0 <- ccx_unc_to_par(u0)
gc <- gc_stat(run_vector(pv0))
cat(sprintf("GC: decoded mode vs the app's APP_SPIN pulse runs: max |diff| %.3g ppm (tol %g)\n", gc, PB_CENTRAL_TOL))
if (!(gc < PB_CENTRAL_TOL)) stop("GC FAIL: the draw machinery does not reproduce the app's central pulse")
pvm <- pv0; pvm[[PB_MUT_NAME]] <- pvm[[PB_MUT_NAME]] * (1 + PB_MUT_FRAC)
gcm <- gc_stat(run_vector(pvm))
cat(sprintf("GCm: %s x %.2f gives max |diff| %.3g ppm: %s\n", PB_MUT_NAME, 1 + PB_MUT_FRAC, gcm,
            if (gcm > PB_CENTRAL_TOL) "the gate rejects it (has power)" else "PASSES: the gate has no power"))
if (!(gcm > PB_CENTRAL_TOL)) stop("GCm FAIL: a perturbed vector passes GC")

# ---- the draws (fixed rule, no RNG) -------------------------------------
U_all <- readRDS(file.path(PB_ROOT, PB_DRAWS_FILE))
stopifnot(is.matrix(U_all), identical(colnames(U_all), names(u0)), all(is.finite(U_all)))
dprov <- attr(U_all, "provenance")
PB_IDX <- as.integer(round(seq(1, nrow(U_all), length.out = PB_N)))
per_chain <- as.integer(dprov$per_chain)
PB_CHAIN <- (PB_IDX - 1L) %/% per_chain + 1L
U <- U_all[PB_IDX, , drop = FALSE]
PB_DRAWS_MD5 <- unname(tools::md5sum(file.path(PB_ROOT, PB_DRAWS_FILE)))
cat(sprintf("\n--- %d of %d draws (every ~%.1f-th row; per chain %s), %d cores, backgrounds %s ---\n",
            PB_N, nrow(U_all), (nrow(U_all) - 1) / (PB_N - 1),
            paste(tabulate(PB_CHAIN, length(dprov$chains)), collapse = "/"), PB_CORES,
            paste(PB_BGS, collapse = ", ")))
t1 <- Sys.time()
runs <- parallel::mclapply(seq_len(PB_N), function(i) tryCatch(
  run_vector(ccx_unc_to_par(U[i, ])), error = function(e) list(error = conditionMessage(e))),
  mc.cores = PB_CORES, mc.preschedule = TRUE)
ok <- vapply(runs, function(r) is.null(r$error), logical(1))
nwarn <- sum(vapply(runs[ok], function(r) r$nwarn, integer(1)))
cat(sprintf("%d of %d draws ran (%.1f min); %d failed; %d warnings muffled across the good draws\n",
            sum(ok), PB_N, as.numeric(difftime(Sys.time(), t1, units = "mins")), sum(!ok), nwarn))
if (any(!ok)) cat("  first failures:", paste(utils::head(unique(unlist(lapply(runs[!ok], `[[`, "error"))), 3),
                                          collapse = " | "), "\n")
if (sum(ok) < 0.99 * PB_N) stop("G99 FAIL: more than 1 % of the draws failed; not writing a censored band")

# ---- quantiles per background and year, beside FaIR -----------------------
fair <- readRDS(file.path(PB_ROOT, PB_FAIR_FILE))
fpv <- attr(fair, "provenance")
yr <- central[[1]]$year
bands <- do.call(rbind, lapply(PB_BGS, function(bg) {
  S <- do.call(cbind, lapply(runs[ok], function(r) r$res[[bg]]$share))     # years x draws
  Tm <- do.call(cbind, lapply(runs[ok], function(r) r$res[[bg]]$d_gmst))
  qs <- t(apply(S, 1, stats::quantile, probs = PB_PROBS, names = FALSE))
  qt <- t(apply(Tm, 1, stats::quantile, probs = PB_PROBS, names = FALSE))
  fr <- fair[fair$scenario == bg & fair$release_year == PB_YEAR, ]
  fi <- match(yr, fr$year)
  data.frame(background = bg, year = yr,
             ccx_central = central[[bg]]$share, ccx_q05 = qs[, 1], ccx_q50 = qs[, 2], ccx_q95 = qs[, 3],
             fair_mean = fr$af_mean[fi], fair_p05 = fr$af_p05[fi], fair_p50 = fr$af_median[fi],
             fair_p95 = fr$af_p95[fi],
             ccx_dT_central = central[[bg]]$d_gmst, ccx_dT_q05 = qt[, 1], ccx_dT_q95 = qt[, 3],
             fair_dT_mean = fr$d_gmst_mean[fi])
}))
bands <- bands[bands$year >= PB_YEAR, ]
key <- bands[bands$year %in% PB_KEY_YEARS, ]
key$ccx_width <- key$ccx_q95 - key$ccx_q05
key$fair_width <- key$fair_p95 - key$fair_p05
key$width_ratio_fair_over_ccx <- key$fair_width / key$ccx_width

draws_long <- do.call(rbind, lapply(which(ok), function(i) do.call(rbind, lapply(PB_BGS, function(bg) {
  r <- runs[[i]]$res[[bg]]; k <- r$year %in% PB_KEY_YEARS
  data.frame(draw_row = PB_IDX[i], chain = PB_CHAIN[i], background = bg, year = r$year[k],
             share = r$share[k], d_gmst = r$d_gmst[k])
}))))

prov <- list(
  driver = PB_DRIVER, commit = PB_COMMIT, mode = CCX_MODE_CANONICAL, struct = ccx_mode_struct(md),
  mode_file = sub(paste0("^", PB_ROOT, "/"), "", ccx_mode_file(CCX_MODE_CANONICAL)),
  draws_file = PB_DRAWS_FILE, draws_md5 = PB_DRAWS_MD5, draws_rows = nrow(U_all),
  draw_rule = "rows round(seq(1, nrow, length.out = n)); no RNG", draw_rows_used = PB_IDX,
  draw_chain = PB_CHAIN, chain_seeds = dprov$chain_seeds, chain_files = dprov$chains,
  chain_md5 = dprov$chain_md5, held = RB_PINS,
  n_draws = PB_N, n_ok = sum(ok), n_failed = sum(!ok), n_warnings = nwarn,
  pulse = sprintf("%g GtC fossil CO2 added to the release year %d (annual-mean-conserving interpolation %s, both arms)",
                  PB_GTC, PB_YEAR, APP_PULSE_EMIS_METHOD),
  backgrounds = PB_BGS, run_span = PB_YEARS, probs = PB_PROBS,
  share = "(CO2 with pulse - without) / (pulse GtC / GtC_PER_PPM), annual mean of the calendar year",
  varied = "the 31 fitted carbon-cycle parameters (MCMC posterior); held values, the climate response (fitted to FaIR), non-CO2 forcing and structure fixed",
  fair_file = PB_FAIR_FILE, fair_label = fpv$model, fair_configs = fpv$n_configs,
  fair_metric = fpv$metric, fair_averaging = fpv$averaging,
  gate_GC = sprintf("max |diff| %.3g ppm < %g", gc, PB_CENTRAL_TOL),
  gate_GCm = sprintf("%s x %.2f: %.3g ppm > %g", PB_MUT_NAME, 1 + PB_MUT_FRAC, gcm, PB_CENTRAL_TOL),
  rng = "none in this driver", units = "share: fraction of the pulse; dT: K")
saveRDS(structure(list(bands = bands, key = key, provenance = prov), class = "list"), PB_OUT_RDS)
key_out <- key; key_out$provenance <- sprintf("%s @%s; %s; %d MCMC draws; FaIR %s %s configs; see %s",
  PB_DRIVER, PB_COMMIT, CCX_MODE_CANONICAL, sum(ok), fpv$model, fpv$n_configs, basename(PB_OUT_RDS))
utils::write.csv(key_out, PB_OUT_CSV, row.names = FALSE)
draws_long$provenance <- key_out$provenance[1]
utils::write.csv(draws_long, PB_OUT_DRAWS, row.names = FALSE)

cat("\n--- key years: share of the pulse still in the air (5-95 %) ---\n")
show <- key[, c("background", "year", "ccx_central", "ccx_q05", "ccx_q95", "fair_mean", "fair_p05", "fair_p95",
                "ccx_width", "fair_width", "width_ratio_fair_over_ccx")]
print(format(show, digits = 3), row.names = FALSE)
cat(sprintf("\nwrote %s, %s, %s\n=== done %s ===\n", basename(PB_OUT_RDS), basename(PB_OUT_CSV),
            basename(PB_OUT_DRAWS), format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
sink()
