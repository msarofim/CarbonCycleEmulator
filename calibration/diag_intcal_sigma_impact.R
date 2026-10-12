# =====================================================================
# diag_intcal_sigma_impact.R -- the IMPACT of the IntCal sigma-units bug
# (notes/code_review_2026-10-12.md s.1), MEASURED, not fixed.
#
# THE BUG. data/obs_d14c_intcal20.rds carries `err` = the 14C-AGE sigma in
# YEARS (9-11), and R/likelihood.R scores the d14c_intcal row with it as if it
# were permil: sd = sqrt(err^2 + LIK_D14C_REP_OTHER^2). The published Delta14C
# sigma is column 5 of IntCal20 (intcal.org/curves/intcal20.14c), 1.2-1.4 permil.
#
# WHAT THIS DOES (nothing in data/, R/, src/, app/, tests/ is touched):
#   1. parses the published file (downloaded separately; its sha256 is CHECKED
#      here) and takes column 5 for exactly the years the row scores. The row's
#      d14c VALUES stay as the repo computes them, and the 4 permil term stays in
#      quadrature, so only sigma changes.
#   2. at the canonical mode: the row both ways, chi2/n both ways, residuals.
#   3. PSIS / importance reweighting of the MCMC posterior: N draws evenly
#      spaced through the pooled file; per draw, Delta-l = l_IntCal(corrected) -
#      l_IntCal(coded); every other row is unchanged, so the weight is exp(Delta-l).
#
# HOW THE MODEL IS RUN: ccx_make_logpost() -- THE objective, with by_stream --
# exactly as calibration/run_mcmc_check.R builds it (gate, pins, band, spin-up).
# The model output is read by a TAP on ccx_loglik(): an in-memory wrapper that
# records its arguments (out, err, luc) and calls the original unchanged. The
# IntCal row is then recomputed from the tapped `out` with the coded sigma and
# REQUIRED to equal the objective's own d14c_intcal stream (an identity gate),
# before the corrected-sigma version is computed the same way.
# The vvM coupled run is build_futures_ribbons.R's run_vector() for ONE scenario,
# by the app's own functions (app_spinup, app_run_coupled), gated against the
# app's central run.
#
# REPRODUCIBILITY. No RNG anywhere: the draws are a deterministic index rule on a
# tracked file. The artifact carries no wall-clock time; two runs must be
# byte-identical (checked by running twice to two --out paths).
#
# Usage (from a FROZEN worktree root; never from a tree being edited):
#   Rscript calibration/diag_intcal_sigma_impact.R --n=1000 --cores=6 \
#     --out=<abs .rds> --log=<abs .log> --commit=<sha> [--vvm=1] [--time_only=0]
# =====================================================================
IM_ARGS <- commandArgs(trailingOnly = TRUE)
im_arg <- function(key, default) {
  hit <- grep(sprintf("^--%s=", key), IM_ARGS, value = TRUE)
  if (length(hit)) sub(sprintf("^--%s=", key), "", hit[1]) else default
}
IM_ROOT <- normalizePath(getwd())
stopifnot(file.exists(file.path(IM_ROOT, "DESIGN.md")))
IM_T0 <- Sys.time()

# ---- named constants: every label and filename derives from these --------
IM_DRIVER     <- "calibration/diag_intcal_sigma_impact.R"
IM_N          <- as.integer(im_arg("n", 1000L))
IM_CORES      <- as.integer(im_arg("cores", 6L)); stopifnot(IM_CORES >= 1L, IM_CORES <= 6L)
IM_OUT        <- im_arg("out", "")
IM_LOG        <- im_arg("log", "")
IM_VVM        <- as.integer(im_arg("vvm", 1L)) == 1L
IM_TIME_ONLY  <- as.integer(im_arg("time_only", 0L))   # >0: time this many draws, write nothing else
IM_COMMIT     <- paste(im_arg("commit", "?"), "(frozen git worktree; data-raw/downloads symlinked to the main tree)")
stopifnot(nzchar(IM_OUT), nzchar(IM_LOG))
IM_MODE_LP_STORED <- -1166.949732                       # the canonical's stored logpost, as the task states it
IM_LP_TOL     <- 1e-5                                   # run_mcmc_check.R's MC_LP_TOL / test-mode-file's tolerance
IM_ID_TOL     <- 1e-9                                   # identity gate: recomputed coded row vs the objective's stream
IM_CENTRAL_TOL <- 1e-6                                  # build_futures_ribbons.R's RB_CENTRAL_TOL
IM_DRAWS_FILE <- file.path("outputs", "mcmc_check_20261009_hilda29e_200k", "pooled_u_thin2.rds")
IM_CHAIN_DIR  <- dirname(IM_DRAWS_FILE)
IM_RIBBON_FILE <- file.path("outputs", "diagnostics", "futures_ribbons_mcmc_20261009_hilda29e_200k.rds")
IM_IC_URL     <- "https://intcal.org/curves/intcal20.14c"
IM_IC_FILE    <- file.path("data-raw", "downloads", "intcal20", "intcal20.14c")
IM_IC_ACCESSED <- "2026-10-12"
IM_IC_SHA256  <- "974a66649f2ac8a53e6c99e256b019ac6982f999b12dcf7193162d4c1c09168e"
IM_IC_HEADER  <- "# CAL BP, 14C age,Sigma,Delta 14C,Sigma"
IM_IC_COLS    <- c("calBP", "c14age", "sig_age_yr", "d14c_pub", "sig_d14c_permil")
IM_IC_SIGMA_COL <- 5L                                   # Delta14C sigma, permil
IM_IC_BASE_YEAR <- 1950                                 # CE = 1950 - cal BP
IM_SCEN       <- "vvM"
IM_CO2_YEAR   <- 2024L
IM_SINK_WIN   <- c(2010L, 2019L)
IM_KEY_YEARS  <- c(2100L, 2150L)
IM_PROBS      <- c(0.05, 0.50, 0.95)
IM_SHIFT_FLAG <- 0.5                                    # verdict: a parameter shift > this many posterior sd
IM_BAND_FRAC  <- 0.1                                    # verdict: a CO2 quantile shift > this x the 5-95 width
IM_TREND_UNIT <- 100                                    # residual trend reported per century

# ---- the app (it sources R/ itself), loaded as build_futures_ribbons.R loads it ----
dir.create(dirname(IM_LOG), showWarnings = FALSE, recursive = TRUE)
sink(IM_LOG, split = TRUE)
cat(sprintf("=== %s @%s, root %s, run %s ===\n", IM_DRIVER, IM_COMMIT, IM_ROOT,
            format(IM_T0, "%Y-%m-%d %H:%M")))
cat(sprintf("Sys.getenv: VECLIB_MAXIMUM_THREADS=%s OPENBLAS_NUM_THREADS=%s\n",
            Sys.getenv("VECLIB_MAXIMUM_THREADS"), Sys.getenv("OPENBLAS_NUM_THREADS")))
suppressMessages(library(shiny))
setwd(file.path(IM_ROOT, "app"))
invisible(utils::capture.output(suppressWarnings(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv()))))
setwd(IM_ROOT)
source(file.path(IM_ROOT, "calibration", "lib_run_inputs.R"))
ccx_require_run_inputs()
options(warn = 1)

# ---- 1. the published IntCal20 file, parsed as DATA ----------------------
ic_path <- file.path(IM_ROOT, IM_IC_FILE)
stopifnot(file.exists(ic_path))
ic_sha <- unname(tools::sha256sum(ic_path))
if (!identical(ic_sha, IM_IC_SHA256)) stop("IntCal20 file sha256 ", ic_sha, " != recorded ", IM_IC_SHA256)
L <- readLines(ic_path, warn = FALSE, encoding = "UTF-8")
if (!any(trimws(L) == IM_IC_HEADER)) stop("IntCal20 header line not found: '", IM_IC_HEADER, "'")
body <- L[!grepl("^#", L) & nzchar(trimws(L))]
pub <- utils::read.csv(text = body, header = FALSE, col.names = IM_IC_COLS,
                       colClasses = rep("numeric", length(IM_IC_COLS)))
stopifnot(ncol(pub) == 5L, all(is.finite(as.matrix(pub))))
pub$year <- IM_IC_BASE_YEAR - pub$calBP
cat(sprintf("\n[1] %s: %d data rows, sha256 %s (checked); column %d '%s' used\n",
            IM_IC_FILE, nrow(pub), ic_sha, IM_IC_SIGMA_COL, IM_IC_COLS[IM_IC_SIGMA_COL]))

# ---- the mode, its space, the objective (run_mcmc_check.R's construction) ----
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
MODE_MD5 <- unname(tools::md5sum(ccx_mode_file(CCX_MODE_CANONICAL)))
BASE <- ccx_mode_base(md)
invisible(ccx_apply_gate(ccx_mode_struct(md)))
PINS <- ccx_mode_pins(md); invisible(ccx_apply_pins(PINS))
ccx_require_param_set(md, IM_DRIVER)
invisible(ccx_adopt_mode_band(md))
ccx_check_mode_decode(md)
u0 <- ccx_par_to_unc(md$par_mode)
stopifnot(identical(names(u0), md$param_names))
bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
OBS <- ccx_prepare_obs()

# THE TAP: records what the objective's ccx_loglik() call was handed, then calls it unchanged.
.CAP <- new.env()
.ccx_loglik_orig <- ccx_loglik
ccx_loglik <- function(out, obs, err, luc = NULL, ...) {
  .CAP$out <- out; .CAP$err <- err; .CAP$luc <- luc
  .ccx_loglik_orig(out, obs, err, luc = luc, ...)
}
lpf <- ccx_make_logpost(obs = OBS, base_params = bp, by_stream = TRUE,
                        spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))

# the row's window, READ exactly as R/likelihood.R reads it
ic_end <- if (!is.null(OBS$d14_nh_ann)) min(OBS$d14_nh_ann$year) else 1950
IC <- as.data.frame(OBS$intcal)
IC <- IC[IC$year >= 1750 & IC$year < ic_end, ]
k <- match(IC$year, pub$year)
if (anyNA(k)) stop("published IntCal20 lacks years: ", paste(IC$year[is.na(k)], collapse = ", "))
IC$sig_pub <- pub$sig_d14c_permil[k]
IC$d14c_pub <- pub$d14c_pub[k]
IC$sd_coded <- sqrt(IC$err^2 + LIK_D14C_REP_OTHER^2)
IC$sd_corr  <- sqrt(IC$sig_pub^2 + LIK_D14C_REP_OTHER^2)
all_ic <- as.data.frame(OBS$intcal); ka <- match(all_ic$year, pub$year)
cat(sprintf("    scored window: %d <= year < %d (ic_end READ from the Hua rows), n = %d\n",
            min(IC$year), ic_end, nrow(IC)))
cat(sprintf("    coded err (14C-age yr): %g-%g; published Delta14C sigma: %g-%g permil; LIK_D14C_REP_OTHER = %g permil\n",
            min(IC$err), max(IC$err), min(IC$sig_pub), max(IC$sig_pub), LIK_D14C_REP_OTHER))
cat(sprintf("    sd used, mean over the window: coded %.3f, corrected %.3f permil (weight ratio mean(1/sd^2) %.2fx)\n",
            mean(IC$sd_coded), mean(IC$sd_corr), mean(1 / IC$sd_corr^2) / mean(1 / IC$sd_coded^2)))
D14_CHECK <- c(window = max(abs(IC$d14c - IC$d14c_pub)),
               all_rows = max(abs(all_ic$d14c - pub$d14c_pub[ka]), na.rm = TRUE))
cat(sprintf("    CHECK (not a change): CCX's converted d14c vs published column 4: max |diff| %.3f permil (scored window), %.3f (all %d rows 1700-1950)\n",
            D14_CHECK[["window"]], D14_CHECK[["all_rows"]], nrow(all_ic)))

# ---- per-draw evaluation --------------------------------------------------
eval_u <- function(u) {
  rm(list = ls(.CAP), envir = .CAP)
  v <- tryCatch(lpf(u), error = function(e) structure(-Inf, err = conditionMessage(e)))
  if (!is.finite(v) || is.null(.CAP$out)) return(list(ok = FALSE, lp = as.numeric(v)))
  st <- attr(v, "streams"); out <- .CAP$out; err <- .CAP$err
  mod <- stats::approx(out$t, out[["d14c_NH"]], xout = IC$year + 0.5, rule = 2)$y
  r <- IC$d14c - mod
  ll_coded <- sum(stats::dnorm(IC$d14c, mod, IC$sd_coded, log = TRUE))
  ll_corr  <- sum(stats::dnorm(IC$d14c, mod, IC$sd_corr,  log = TRUE))
  ms <- ccx_model_stats(out, OBS)$co2$MLO
  co2 <- ms$level[ms$year == IM_CO2_YEAR] - (if (is.null(err$rep_dC)) 0 else err$rep_dC)
  fl <- ccx_calendar_flux(out); fl <- merge(fl, .CAP$luc, by = "year")
  w  <- fl$year >= IM_SINK_WIN[1] & fl$year <= IM_SINK_WIN[2]
  stopifnot(sum(w) == diff(IM_SINK_WIN) + 1L)
  list(ok = TRUE, lp = as.numeric(v), loglik = attr(v, "loglik"), logprior = attr(v, "logprior"),
       ll_ic_obj = st[["d14c_intcal"]], ll_ic_coded = ll_coded, ll_ic_corr = ll_corr,
       chi2n_coded = mean((r / IC$sd_coded)^2), chi2n_corr = mean((r / IC$sd_corr)^2),
       res_mean = mean(r), res_rms = sqrt(mean(r^2)),
       res_trend = unname(stats::coef(stats::lm(r ~ IC$year))[2]) * IM_TREND_UNIT,
       co2_mlo = co2, ocean_sink = mean(fl$ocean[w]), land_sink_gross = mean(fl$land[w] + fl$eluc[w]),
       resid = r, model = mod)
}
run_vvm <- function(pv) {   # build_futures_ribbons.R's run_vector(), ONE scenario
  pm <- pv
  for (n in names(PINS)) pm[[n]] <- PINS[[n]]
  rp <- ccx_mode_run_params(md, pm, base = BASE)
  sp <- app_spinup(rp$p)
  nwarn <- 0L
  cl <- withCallingHandlers(
    app_run_coupled(sp, IM_SCEN, APP_FUTURE_YEARS, bomb_total_kmol = rp$bomb_total,
                    luc_scale = rp$luc_scale)$climate,
    warning = function(w) { nwarn <<- nwarn + 1L; invokeRestart("muffleWarning") })
  list(co2 = cl$co2_ppm, year = cl$year, nwarn = nwarn)
}

# ---- 2. GATES, then the mode -----------------------------------------------
cat("\n[2] the canonical mode\n")
m0 <- eval_u(u0)
cat(sprintf("    GATE mode logpost: recomputed %.6f, stored in file %.6f, task-stated %.6f (diff %.2e)\n",
            m0$lp, md$logpost, IM_MODE_LP_STORED, m0$lp - md$logpost))
if (!(abs(m0$lp - md$logpost) < IM_LP_TOL && abs(md$logpost - IM_MODE_LP_STORED) < 1e-6))
  stop("GATE FAILED: the frozen tree does not reproduce the canonical's stored logpost")
cat(sprintf("    GATE identity: recomputed coded row %.10f vs the objective's d14c_intcal %.10f (diff %.2e)\n",
            m0$ll_ic_coded, m0$ll_ic_obj, m0$ll_ic_coded - m0$ll_ic_obj))
if (!(abs(m0$ll_ic_coded - m0$ll_ic_obj) < IM_ID_TOL)) stop("GATE FAILED: the row recomputation is not the objective's row")
seg <- function(r, lo, hi) mean(r[IC$year >= lo & IC$year <= hi])
MODE <- list(lp = m0$lp, ll_coded = m0$ll_ic_coded, ll_corr = m0$ll_ic_corr,
             dll = m0$ll_ic_corr - m0$ll_ic_coded,
             chi2n_coded = m0$chi2n_coded, chi2n_corr = m0$chi2n_corr,
             res_mean = m0$res_mean, res_rms = m0$res_rms, res_trend_per_century = m0$res_trend,
             res_seg = c(`1750-1849` = seg(m0$resid, 1750, 1849), `1850-1899` = seg(m0$resid, 1850, 1899),
                         `1900-1940` = seg(m0$resid, 1900, 1940)),
             obs_change_1750s_to_1930s = mean(IC$d14c[IC$year %in% 1750:1759]) - mean(IC$d14c[IC$year %in% 1931:1940]),
             mod_change_1750s_to_1930s = mean(m0$model[IC$year %in% 1750:1759]) - mean(m0$model[IC$year %in% 1931:1940]),
             rows = data.frame(year = IC$year, obs = IC$d14c, model = m0$model, resid = m0$resid,
                               sd_coded = IC$sd_coded, sd_corr = IC$sd_corr),
             co2_mlo_2024 = m0$co2_mlo, ocean_sink = m0$ocean_sink, land_sink_gross = m0$land_sink_gross)
cat(sprintf("    IntCal row log-lik: coded %.2f, corrected %.2f (Delta %+.2f; a normalisation shift plus the residual term)\n",
            MODE$ll_coded, MODE$ll_corr, MODE$dll))
cat(sprintf("    chi2/n: coded %.3f, corrected %.3f (n = %d)\n", MODE$chi2n_coded, MODE$chi2n_corr, nrow(IC)))
cat(sprintf("    residual obs - model: mean %+.2f, RMS %.2f permil; trend %+.2f permil/century over %d-%d\n",
            MODE$res_mean, MODE$res_rms, MODE$res_trend_per_century, min(IC$year), max(IC$year)))
cat(sprintf("    residual mean by period: %s\n",
            paste(sprintf("%s %+.2f", names(MODE$res_seg), MODE$res_seg), collapse = "; ")))
cat(sprintf("    Suess decline, 1750s mean minus 1931-40 mean: obs %.2f, model %.2f permil (model - obs %+.2f)\n",
            MODE$obs_change_1750s_to_1930s, MODE$mod_change_1750s_to_1930s,
            MODE$mod_change_1750s_to_1930s - MODE$obs_change_1750s_to_1930s))
cat(sprintf("    at the mode: MLO CO2 %d (scored line) %.3f ppm; %d-%d mean ocean sink %.3f, land sink (gross, GCB convention) %.3f GtC/yr\n",
            IM_CO2_YEAR, MODE$co2_mlo_2024, IM_SINK_WIN[1], IM_SINK_WIN[2], MODE$ocean_sink, MODE$land_sink_gross))

CENTRAL_DC <- NA_real_
if (IM_VVM) {
  central <- suppressWarnings(app_run_coupled(APP_SPIN, IM_SCEN, APP_FUTURE_YEARS))$climate
  v0 <- run_vvm(ccx_unc_to_par(u0))
  CENTRAL_DC <- max(abs(v0$co2 - central$co2_ppm))
  cat(sprintf("    GATE central line: decoded mode vs the app's APP_SPIN %s run, co2_ppm max |diff| %.3g (tol %g)\n",
              IM_SCEN, CENTRAL_DC, IM_CENTRAL_TOL))
  if (!(CENTRAL_DC < IM_CENTRAL_TOL)) stop("GATE FAILED: the vvM machinery does not reproduce the app's central line")
  MODE$vvm_co2 <- stats::setNames(v0$co2[match(IM_KEY_YEARS, v0$year)], IM_KEY_YEARS)
}

# ---- 3. the draws -----------------------------------------------------------
U <- readRDS(file.path(IM_ROOT, IM_DRAWS_FILE))
DRAWS_MD5 <- unname(tools::md5sum(file.path(IM_ROOT, IM_DRAWS_FILE)))
stopifnot(is.matrix(U), identical(colnames(U), names(u0)))
S_ALL <- nrow(U)
pp <- attr(U, "provenance")
IM_STEP <- S_ALL %/% IM_N
IDX <- IM_STEP * seq_len(IM_N)
IM_INDEX_RULE <- sprintf("rows (S %%/%% N) * (1:N) of the pooled file: step %d, rows %d..%d of %d",
                         IM_STEP, min(IDX), max(IDX), S_ALL)
# each pooled row back to its chain sample, by the file's own pool rule
per_chain <- pp$per_chain; stopifnot(per_chain * length(pp$chains) == S_ALL)
CH <- lapply(pp$chains, function(f) readRDS(file.path(IM_ROOT, IM_CHAIN_DIR, f)))
chain_of <- (IDX - 1L) %/% per_chain + 1L
jrow     <- pp$pool_thin * ((IDX - 1L) %% per_chain + 1L)
lp_stored <- mapply(function(c, j) CH[[c]]$samples_lp[j], chain_of, jrow)
same_u <- mapply(function(i, c, j) identical(unname(U[i, ]), unname(CH[[c]]$samples[j, ])), IDX, chain_of, jrow)
stopifnot(all(same_u))
rm(CH)
cat(sprintf("\n[3] draws: %s (md5 %s), %s; each mapped to its chain sample (identical u: %d/%d)\n",
            IM_DRAWS_FILE, DRAWS_MD5, IM_INDEX_RULE, sum(same_u), length(same_u)))

one_draw <- function(i) {
  u <- U[i, ]
  e <- eval_u(u)
  e$resid <- NULL; e$model <- NULL
  if (IM_VVM && isTRUE(e$ok)) {
    v <- tryCatch(run_vvm(ccx_unc_to_par(u)), error = function(err) NULL)
    e$vvm <- if (is.null(v)) rep(NA_real_, length(IM_KEY_YEARS)) else v$co2[match(IM_KEY_YEARS, v$year)]
    e$vvm_nwarn <- if (is.null(v)) NA_integer_ else v$nwarn
  }
  e
}

if (IM_TIME_ONLY > 0L) {
  ti <- IDX[seq_len(min(IM_TIME_ONLY, length(IDX)))]
  t1 <- Sys.time(); tt <- vapply(ti, function(i) { s <- Sys.time(); one_draw(i); as.numeric(difftime(Sys.time(), s, units = "secs")) }, numeric(1))
  cat(sprintf("TIMING (serial, vvm %s): %d draws, %.2f s/draw (range %.2f-%.2f); projected %d draws on %d workers: %.1f min (assuming linear scaling)\n",
              IM_VVM, length(ti), mean(tt), min(tt), max(tt), IM_N, IM_CORES, mean(tt) * IM_N / IM_CORES / 60))
  sink(); quit(save = "no")
}

t1 <- Sys.time()
res <- parallel::mclapply(IDX, one_draw, mc.cores = IM_CORES, mc.preschedule = TRUE)
el <- as.numeric(difftime(Sys.time(), t1, units = "mins"))
ok <- vapply(res, function(r) isTRUE(r$ok), logical(1))
cat(sprintf("    %d of %d draws evaluated (%.1f min on %d workers, %.2f s/draw/worker)\n",
            sum(ok), IM_N, el, IM_CORES, el * 60 * IM_CORES / IM_N))
g <- function(nm) vapply(res, function(r) if (isTRUE(r$ok) && !is.null(r[[nm]])) as.numeric(r[[nm]]) else NA_real_, numeric(1))
PD <- data.frame(row = IDX, chain = chain_of, chain_sample = jrow, lp_stored = lp_stored,
                 lp = g("lp"), loglik = g("loglik"), logprior = g("logprior"),
                 ll_ic_obj = g("ll_ic_obj"), ll_ic_coded = g("ll_ic_coded"), ll_ic_corr = g("ll_ic_corr"),
                 chi2n_coded = g("chi2n_coded"), chi2n_corr = g("chi2n_corr"),
                 res_mean = g("res_mean"), res_rms = g("res_rms"), res_trend_per_century = g("res_trend"),
                 co2_mlo_2024 = g("co2_mlo"), ocean_sink_2010_2019 = g("ocean_sink"),
                 land_sink_gross_2010_2019 = g("land_sink_gross"))
PD$dll <- PD$ll_ic_corr - PD$ll_ic_coded
if (IM_VVM) {
  vv <- t(vapply(res, function(r) if (isTRUE(r$ok) && !is.null(r$vvm)) r$vvm else rep(NA_real_, length(IM_KEY_YEARS)),
                 numeric(length(IM_KEY_YEARS))))
  for (j in seq_along(IM_KEY_YEARS)) PD[[sprintf("vvM_co2_%d", IM_KEY_YEARS[j])]] <- vv[, j]
  PD$vvm_nwarn <- vapply(res, function(r) if (is.null(r$vvm_nwarn)) NA_real_ else as.numeric(r$vvm_nwarn), numeric(1))
}
# per-draw identity gates
id_dev <- max(abs(PD$ll_ic_coded - PD$ll_ic_obj), na.rm = TRUE)
lp_dev <- max(abs(PD$lp - PD$lp_stored), na.rm = TRUE)
cat(sprintf("    GATE identity per draw: max |recomputed coded row - objective's row| %.2e (tol %g)\n", id_dev, IM_ID_TOL))
if (!(id_dev < IM_ID_TOL)) stop("GATE FAILED per draw: row recomputation drifted from the objective")
cat(sprintf("    CHECK: recomputed logpost vs the chain's stored samples_lp: max |diff| %.3g over %d draws\n", lp_dev, sum(ok)))

# ---- PSIS / IS diagnostics and the reweighted posterior ----------------------
lw <- PD$dll
D <- ccx_is_diagnostics(lw)
w <- D$w
cat(sprintf("\n    Delta-l across draws: mean %.2f, sd %.2f, range [%.2f, %.2f]\n",
            mean(lw, na.rm = TRUE), stats::sd(lw, na.rm = TRUE), min(lw, na.rm = TRUE), max(lw, na.rm = TRUE)))
cat(sprintf("    ccx_is_diagnostics: S %d, failed %d, ESS %.1f (%.1f %%), max w %.3f, k-hat %.3f (reliable below %.3f): k_ok %s\n",
            D$S, D$n_failed, D$ess, 100 * D$ess_frac, D$max_w, D$k_hat, D$k_ok_below, D$k_ok))
if (D$ess < 5) cat("    ⚠ ESS < 5: k_ok is NOT trusted here (the dormant -Inf k-hat case)\n")

wstats <- function(x, w) {
  okx <- is.finite(x) & is.finite(w); x <- x[okx]; w <- w[okx]
  wu <- rep(1, length(x))
  mu_u <- mean(x); sd_u <- stats::sd(x); mu_w <- sum(w * x) / sum(w)
  qu <- ccx_wquantile(x, wu, IM_PROBS); qw <- ccx_wquantile(x, w, IM_PROBS)
  c(mean_u = mu_u, mean_w = mu_w, sd_u = sd_u, shift_sd = (mu_w - mu_u) / sd_u,
    q05_u = qu[1], q50_u = qu[2], q95_u = qu[3], q05_w = qw[1], q50_w = qw[2], q95_w = qw[3])
}
PV <- t(vapply(IDX, function(i) unlist(ccx_unc_to_par(U[i, ]))[names(u0)], numeric(length(u0))))
colnames(PV) <- names(u0)
PAR <- as.data.frame(t(apply(PV[ok, , drop = FALSE], 2, wstats, w = w[ok])))
PAR$name <- rownames(PAR); PAR <- PAR[order(-abs(PAR$shift_sd)), c("name", setdiff(names(PAR), "name"))]
rownames(PAR) <- NULL
cat("\n    parameters (natural scale), ranked by |mean shift| in unweighted-posterior sd:\n")
print(PAR, digits = 4, row.names = FALSE)

outs <- c("co2_mlo_2024", "ocean_sink_2010_2019", "land_sink_gross_2010_2019", "res_rms", "res_mean",
          "res_trend_per_century", "chi2n_corr", if (IM_VVM) sprintf("vvM_co2_%d", IM_KEY_YEARS))
OUTS <- as.data.frame(t(vapply(outs, function(o) wstats(PD[[o]][ok], w[ok]), numeric(10))))
OUTS$quantity <- rownames(OUTS); OUTS <- OUTS[, c("quantity", setdiff(names(OUTS), "quantity"))]; rownames(OUTS) <- NULL
OUTS$width_u <- OUTS$q95_u - OUTS$q05_u
OUTS$max_q_shift_over_width <- pmax(abs(OUTS$q05_w - OUTS$q05_u), abs(OUTS$q50_w - OUTS$q50_u),
                                    abs(OUTS$q95_w - OUTS$q95_u)) / OUTS$width_u
cat("\n    outputs, unweighted vs reweighted:\n")
print(OUTS, digits = 5, row.names = FALSE)

RIB_CHECK <- NULL
if (IM_VVM && file.exists(file.path(IM_ROOT, IM_RIBBON_FILE))) {
  kd <- readRDS(file.path(IM_ROOT, IM_RIBBON_FILE))$key_draws
  RIB_CHECK <- vapply(IM_KEY_YEARS, function(y) {
    s <- kd[kd$scenario == IM_SCEN & kd$var == "co2_ppm" & kd$year == y, ]
    max(abs(s$value[match(IDX, s$draw)] - PD[[sprintf("vvM_co2_%d", y)]]), na.rm = TRUE)
  }, numeric(1))
  names(RIB_CHECK) <- IM_KEY_YEARS
  cat(sprintf("    CHECK vs the shipped band's per-draw values (%s, %s): max |diff| %s ppm\n",
              IM_RIBBON_FILE, IM_SCEN, paste(sprintf("%d: %.3g", IM_KEY_YEARS, RIB_CHECK), collapse = ", ")))
}

# ---- 4. the verdict, measured -----------------------------------------------
reliable <- isTRUE(D$k_ok) && D$ess >= 5
big_par <- PAR$name[abs(PAR$shift_sd) > IM_SHIFT_FLAG]
co2_rows <- OUTS[OUTS$quantity %in% sprintf("vvM_co2_%d", IM_KEY_YEARS), ]
big_co2 <- co2_rows$quantity[co2_rows$max_q_shift_over_width > IM_BAND_FRAC]
VERDICT <- if (!reliable)
  sprintf("UNRELIABLE: k-hat %.3f (limit %.3f), ESS %.1f of %d -- the reweighting cannot answer; only a refit can.",
          D$k_hat, D$k_ok_below, D$ess, D$S) else
  sprintf("k-hat %.3f < %.3f, ESS %.1f: parameters moved > %.1f sd: %s; vvM CO2 quantiles moved > %.1f x band width: %s",
          D$k_hat, D$k_ok_below, D$ess, IM_SHIFT_FLAG, if (length(big_par)) paste(big_par, collapse = ", ") else "none",
          IM_BAND_FRAC, if (length(big_co2)) paste(big_co2, collapse = ", ") else if (IM_VVM) "none" else "not run")
cat(sprintf("\n[4] VERDICT: %s\n", VERDICT))

# ---- the artifact (no wall-clock time: two runs must be byte-identical) -------
out <- list(
  per_draw = PD, params_natural = PV, weights = w, is_diag = D[setdiff(names(D), "w")],
  params = PAR, outputs = OUTS, mode = MODE, verdict = VERDICT,
  checks = list(d14c_vs_published_col4 = D14_CHECK, row_identity_max = id_dev,
                lp_vs_chain_stored_max = lp_dev, central_vvm_max = CENTRAL_DC, vs_shipped_band = RIB_CHECK),
  provenance = list(
    driver = IM_DRIVER, commit = IM_COMMIT, frozen_tree = IM_ROOT,
    mode = CCX_MODE_CANONICAL, struct = ccx_mode_struct(md),
    mode_file = sub(paste0("^", IM_ROOT, "/"), "", ccx_mode_file(CCX_MODE_CANONICAL)), mode_file_md5 = MODE_MD5,
    mode_logpost_stored = md$logpost,
    draws_file = IM_DRAWS_FILE, draws_md5 = DRAWS_MD5, draws_provenance = pp[c("reader", "reader_commit", "chain_commit", "chain_seeds", "pool_rule")],
    index_rule = IM_INDEX_RULE, n = IM_N, rows = IDX,
    intcal_url = IM_IC_URL, intcal_file = IM_IC_FILE, intcal_accessed = IM_IC_ACCESSED, intcal_sha256 = ic_sha,
    intcal_column_used = sprintf("column %d of %d ('%s', the Delta14C sigma in permil); header '%s'",
                                 IM_IC_SIGMA_COL, length(IM_IC_COLS), IM_IC_COLS[IM_IC_SIGMA_COL], IM_IC_HEADER),
    intcal_window = c(min(IC$year), max(IC$year)), intcal_ic_end_read = ic_end,
    sd_coded = "sqrt(err^2 + LIK_D14C_REP_OTHER^2), err = data/obs_d14c_intcal20.rds$err (14C-AGE sigma, yr)",
    sd_corrected = "sqrt(sigma_pub^2 + LIK_D14C_REP_OTHER^2), sigma_pub = IntCal20 column 5",
    rep_other_permil = LIK_D14C_REP_OTHER,
    d14c_values = "the repo's own converted d14c (data/obs_d14c_intcal20.rds), unchanged",
    weight = "exp(l_IntCal(corrected sd) - l_IntCal(coded sd)); every other row is unchanged",
    smoothing = "none: raw importance weights; k-hat from ccx_is_diagnostics() (PSIS tail fit) is the reliability test",
    quantiles = sprintf("ccx_wquantile() for BOTH arms (unit weights for the unweighted), probs %s",
                        paste(IM_PROBS, collapse = "/")),
    co2_2024 = "MLO scored line: the NH box's annual level (ccx_model_stats) minus the draw's rep_dC",
    sinks = sprintf("ccx_calendar_flux(); ocean = d(ocean_C)/dt; land = d(land_C)/dt + the model's own E_LUC (GCB S_LAND convention); %d-%d mean",
                    IM_SINK_WIN[1], IM_SINK_WIN[2]),
    vvm = if (IM_VVM) sprintf("build_futures_ribbons.R's run_vector() for %s only: app_spinup + app_run_coupled over %s",
                              IM_SCEN, paste(APP_FUTURE_YEARS, collapse = "-")) else "not run",
    emis_method = CCX_EMIS_METHOD_DEFAULT, spinup = ccx_mode_spinup(md),
    rng = "none used", r_version = R.version.string))
dir.create(dirname(IM_OUT), showWarnings = FALSE, recursive = TRUE)
saveRDS(out, IM_OUT)
cat(sprintf("\nsaved %s; total %.1f min\n", IM_OUT, as.numeric(difftime(Sys.time(), IM_T0, units = "mins"))))
sink()
