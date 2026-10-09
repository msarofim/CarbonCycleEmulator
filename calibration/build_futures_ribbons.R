# =====================================================================
# build_futures_ribbons.R -- the Futures tab's uncertainty RIBBONS, by the
# LAPLACE approximation at the best fit (Marcus 2026-10-01, review 10-01c B7:
# "Laplace first, MCMC as the check").
#
# WHAT. N draws from a multivariate normal in the UNCONSTRAINED (u) space,
# centred on the canonical's stored mode, with the covariance the mode file
# stores (the inverse negative Hessian, calibration/recompute_hessian.R). Each
# draw is decoded through the file's own transforms and bands, gets the file's
# NINE HELD values added back, and is run through the FULL NONLINEAR model --
# its own spin-up, then every scenario on the Futures tab -- by the APP'S OWN
# functions (app_spinup, app_run_coupled; the app is loaded with
# shiny::loadSupport exactly as Shiny loads it). The per-year quantiles go to
# data/futures_ribbons.rds, which the app reads; the app never runs draws.
#
# ⚠ WHAT IT IS NOT. A Gaussian at the mode is not a posterior: the record's
# widest directions (the h_ml near-degeneracy, the npp_tsens ridge) are the ones
# it handles worst, and the bands are CONDITIONAL on the file's held values. The
# label says so (RB_LABEL), and says MCMC when the draws are supplied (--draws).
# ⚠ WHICH EMISSIONS INTERPOLATION THE STORED COVARIANCE WAS COMPUTED UNDER is a
# property of the MODE, keyed in RB_COV_EMIS (an unlisted canonical stops the
# run). hilda33d's predates the 2026-10-01 flip (spline -> constant), which
# moved the likelihood by -0.16 at the mode; hilda29e's (recompute_hessian.R,
# 2026-10-08, no override) is under constant, the same as the runs. Until
# 2026-10-09 the note was hard-coded to hilda33d's case. With supplied draws
# the covariance enters only the delta-method pre-check. Recorded in the artifact.
#
# THE CENTRAL LINE IS THE APP'S, CHECKED. The draw machinery is fed the mode's
# own vector first and must reproduce the app's central runs (APP_SPIN through
# app_run_coupled) to RB_CENTRAL_TOL; ccx_mode_run_params() (R/paths.R) is the
# ONE mapping both use. A linear (delta-method) sd at a few key cells is
# printed beside the sampled sd as the order-of-magnitude pre-check.
#
# REPRODUCIBILITY (~/.claude/CLAUDE.md: a seed is recorded IN THE ARTIFACT).
# set.seed(RB_SEED) sits immediately before the ONE rnorm() call that draws
# the standard normals; every draw is fixed before any model run, so the
# forked runs consume no RNG. The seed, the RNG kind and where it is applied
# are stored in `provenance`. The artifact carries no wall-clock time, so two
# runs at one commit must be BYTE-IDENTICAL (checked with --out to a second path).
#
# Usage (from the repo root):
#   Rscript calibration/build_futures_ribbons.R [--n=1000] [--cores=8] [--out=data/futures_ribbons.rds]
#   ... --draws=<rds of a u-space matrix, colnames = the fitted names> --out=<not data/>
#   pushes SUPPLIED draws (the MCMC check's pooled posterior, calibration/run_mcmc_check.R)
#   through the SAME machinery, so the two bands differ only in where the draws came from.
# =====================================================================
RB_ARGS <- commandArgs(trailingOnly = TRUE)
rb_arg <- function(key, default) {
  hit <- grep(sprintf("^--%s=", key), RB_ARGS, value = TRUE)
  if (length(hit)) sub(sprintf("^--%s=", key), "", hit[1]) else default
}
RB_ROOT <- normalizePath(getwd())
stopifnot(file.exists(file.path(RB_ROOT, "DESIGN.md")))
RB_T0 <- Sys.time()

# ---- the app, loaded the way Shiny loads it (global.R, then app/R/*.R) ----
suppressMessages(library(shiny))
setwd(file.path(RB_ROOT, "app"))
invisible(utils::capture.output(suppressWarnings(
  shiny::loadSupport(getwd(), renv = globalenv(), globalrenv = globalenv()))))
setwd(RB_ROOT)

# ---- named constants: every label and filename derives from these --------
RB_DRIVER     <- "calibration/build_futures_ribbons.R"
RB_N          <- as.integer(rb_arg("n", 1000L))
RB_CORES      <- as.integer(rb_arg("cores", 8L))
RB_OUT        <- file.path(RB_ROOT, rb_arg("out", file.path("data", "futures_ribbons.rds")))
RB_DRAWS_FILE <- rb_arg("draws", "")           # supplied draws instead of the Gaussian (see Usage)
if (nzchar(RB_DRAWS_FILE) && grepl("^data/", sub(paste0("^", RB_ROOT, "/"), "", RB_OUT)))
  stop("--draws output must not land in data/: the app reads data/futures_ribbons.rds")
RB_DATE       <- format(Sys.Date(), "%Y%m%d")
# the log is named after the artifact, so a byte-identity rerun (--out elsewhere) logs apart
RB_LOG        <- file.path(RB_ROOT, "outputs", "diagnostics",
                           sprintf("%s_%s.log", sub("\\.rds$", "", basename(RB_OUT)), RB_DATE))
RB_PROBS      <- c(0.05, 0.50, 0.95)          # the ruled band: 5-95 %, plus the median
RB_SEED       <- 20261001L
RB_RNG_KIND   <- c("Mersenne-Twister", "Inversion", "Rejection")
RB_SCEN       <- APP_SCENARIOS                # the seven van Vuuren markers the tab offers
RB_YEARS      <- APP_FUTURE_YEARS             # the tab's run span
RB_VARS       <- unname(APP_FUTURE_YVARS)     # the tab's two y-variables
RB_KEY_YEARS  <- c(2050L, 2100L, 2150L)       # per-draw values kept for the MCMC check
RB_CENTRAL_TOL <- 1e-6                        # ppm / degC: the decoded mode vs the app's own run
RB_GRAD_FRAC  <- 0.1                          # delta-method step, x each name's marginal u-sd
RB_LIN_CELLS  <- list(c("vvH", "co2_ppm", 2150L), c("vvVL", "co2_ppm", 2150L),
                      c("vvM", "gmst", 2100L))
# --commit=<sha>: the driver is RUN FROM A FROZEN COPY (`git archive` of that commit; never
# edit a script an interpreter is reading), which is not a checkout and cannot stamp itself
RB_COMMIT <- if (nzchar(rb_arg("commit", ""))) paste(rb_arg("commit", ""), "(frozen git-archive copy)") else
  ccx_git_stamp(exclude = RB_OUT)   # its own product under data/ is never an input

dir.create(dirname(RB_LOG), showWarnings = FALSE, recursive = TRUE)
sink(RB_LOG, split = TRUE)
cat(sprintf("=== %s @%s, run %s ===\n", RB_DRIVER, RB_COMMIT, format(RB_T0, "%Y-%m-%d %H:%M")))

# ---- the mode, its fitted set, and its covariance -------------------------
md <- readRDS(ccx_mode_file(CCX_MODE_CANONICAL))
RB_BASE <- ccx_mode_base(md)                  # the file's OWN structure, resolved once for every draw
RB_GATE <- ccx_apply_gate(ccx_mode_struct(md))
RB_PINS <- ccx_mode_pins(md)
invisible(ccx_apply_pins(RB_PINS))
ccx_require_param_set(md, RB_DRIVER)
invisible(ccx_adopt_mode_band(md))             # the file's h_ml / kz bands, before any decode
ccx_check_mode_decode(md)                      # GATE: u_mode decodes to the file's own par_mode
u0 <- ccx_par_to_unc(md$par_mode)              # the Hessian's centre (recompute_hessian.R), not u_mode
fs <- ccx_mode_fit_stats(md)
Sig <- fs$cov
stopifnot(isTRUE(fs$pd), identical(names(u0), md$param_names),
          identical(rownames(Sig), names(u0)), identical(colnames(Sig), names(u0)))
k <- length(u0)
RB_N_HELD <- length(RB_PINS)
RB_WORDS  <- c("one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
               "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
               "seventeen", "eighteen", "nineteen", "twenty")
RB_HELD_WORD <- if (RB_N_HELD <= length(RB_WORDS)) RB_WORDS[RB_N_HELD] else as.character(RB_N_HELD)
# the ruled label (review 10-01c B7), with the count read off the file's pins. With --draws it is a
# PROVENANCE label only, not ruled app copy: a --draws product may not land in data/ (above), so the
# app never shows it; the shipped wording is Marcus's.
RB_LABEL <- if (nzchar(RB_DRAWS_FILE))
  sprintf("MCMC posterior draws (supplied), conditional on the %s held values", RB_HELD_WORD) else
  sprintf("Gaussian approximation at the best fit, conditional on the %s held values", RB_HELD_WORD)
# the emissions interpolation each mode's STORED covariance was computed under (see the header)
RB_COV_EMIS <- c(hilda33d = "spline",     # computed before the 2026-10-01 flip (CHANGELOG 10-01)
                 hilda29e = "constant")   # recompute_hessian.R 2026-10-08, after the flip, no override
if (!CCX_MODE_CANONICAL %in% names(RB_COV_EMIS))
  stop("RB_COV_EMIS does not say which emissions interpolation ", CCX_MODE_CANONICAL,
       "'s covariance was computed under: check its Hessian's date against the 2026-10-01 flip and add it")
RB_COV_NOTE <- if (RB_COV_EMIS[[CCX_MODE_CANONICAL]] == CCX_EMIS_METHOD_DEFAULT)
  sprintf("computed under the %s emissions interpolation, the same as the runs", CCX_EMIS_METHOD_DEFAULT) else
  sprintf("computed under the %s emissions interpolation; the runs use %s (the 2026-10-01 flip moved the likelihood -0.16 at hilda33d's mode); used as stored",
          RB_COV_EMIS[[CCX_MODE_CANONICAL]], CCX_EMIS_METHOD_DEFAULT)
if (nzchar(RB_DRAWS_FILE)) RB_COV_NOTE <- paste0(RB_COV_NOTE, "; with supplied draws it enters only the delta-method pre-check")
cat(sprintf("mode %s (%s); %d fitted names, %d held; logpost %.6f; covariance PD, cond %.3g\n",
            CCX_MODE_CANONICAL, ccx_mode_struct(md), k, RB_N_HELD, md$logpost,
            max(abs(fs$eigen$values)) / min(abs(fs$eigen$values))))
cat(sprintf("held: %s\n", paste(sprintf("%s = %g", names(RB_PINS), RB_PINS), collapse = ", ")))
cat(sprintf("label: %s\ncovariance: %s\n", RB_LABEL, RB_COV_NOTE))

# ---- the run for ONE physical vector, by the app's own functions ----------
run_vector <- function(pv) {
  pm <- pv
  for (n in names(RB_PINS)) pm[[n]] <- RB_PINS[[n]]
  rp <- ccx_mode_run_params(md, pm, base = RB_BASE)
  sp <- app_spinup(rp$p)
  nwarn <- 0L
  res <- lapply(RB_SCEN, function(s) {
    cl <- withCallingHandlers(
      app_run_coupled(sp, s, RB_YEARS, bomb_total_kmol = rp$bomb_total,
                      luc_scale = rp$luc_scale)$climate,
      warning = function(w) { nwarn <<- nwarn + 1L; invokeRestart("muffleWarning") })
    as.matrix(cl[, RB_VARS])
  })
  list(res = res, nwarn = nwarn, year = NULL)
}
years_of <- function() app_run_coupled(APP_SPIN, RB_SCEN[[1]], RB_YEARS)$climate$year

# ---- GATE: the decoded mode reproduces the app's own central runs ---------
cat("\n--- the central line ---\n")
central <- lapply(RB_SCEN, function(s)
  as.matrix(suppressWarnings(app_run_coupled(APP_SPIN, s, RB_YEARS))$climate[, RB_VARS]))
RB_YEAR <- years_of()
pv0 <- ccx_unc_to_par(u0)
r0 <- run_vector(pv0)
dc <- max(vapply(seq_along(RB_SCEN), function(j) max(abs(r0$res[[j]] - central[[j]])), numeric(1)))
cat(sprintf("decoded mode vs the app's APP_SPIN runs: max |diff| %.3g (tol %g) over %d scenarios x %d years x %d vars\n",
            dc, RB_CENTRAL_TOL, length(RB_SCEN), length(RB_YEAR), length(RB_VARS)))
if (!(dc < RB_CENTRAL_TOL)) stop("the draw machinery does not reproduce the app's central line")

# ---- THE DRAWS (the only RNG in this driver) ------------------------------
if (nzchar(RB_DRAWS_FILE)) {
  U <- readRDS(file.path(RB_ROOT, RB_DRAWS_FILE))
  stopifnot(is.matrix(U), identical(colnames(U), names(u0)), all(is.finite(U)))
  RB_N <- nrow(U)
  RB_DRAWS_MD5 <- unname(tools::md5sum(file.path(RB_ROOT, RB_DRAWS_FILE)))
} else {
  L <- chol(Sig)                                  # Sig = t(L) %*% L
  RNGkind(RB_RNG_KIND[1], RB_RNG_KIND[2], RB_RNG_KIND[3])
  set.seed(RB_SEED)                               # immediately before the one rnorm() call
  Z <- matrix(stats::rnorm(RB_N * k), RB_N, k)
  U <- sweep(Z %*% L, 2, u0, "+"); colnames(U) <- names(u0)
}
cat(sprintf("\n--- %d draws (%s), %d cores ---\n", RB_N,
            if (nzchar(RB_DRAWS_FILE)) paste("supplied:", RB_DRAWS_FILE) else
              sprintf("seed %d, %s", RB_SEED, paste(RB_RNG_KIND, collapse = "/")), RB_CORES))
t1 <- Sys.time()
runs <- parallel::mclapply(seq_len(RB_N), function(i) tryCatch(
  run_vector(ccx_unc_to_par(U[i, ])), error = function(e) list(error = conditionMessage(e))),
  mc.cores = RB_CORES, mc.preschedule = TRUE)
ok <- vapply(runs, function(r) is.null(r$error), logical(1))
nwarn <- sum(vapply(runs[ok], function(r) r$nwarn, integer(1)))
cat(sprintf("%d of %d draws ran (%.1f min); %d failed; %d warnings muffled across the good draws\n",
            sum(ok), RB_N, as.numeric(difftime(Sys.time(), t1, units = "mins")), sum(!ok), nwarn))
if (any(!ok)) cat("  first failures:", paste(utils::head(unique(unlist(lapply(runs[!ok], `[[`, "error"))), 3),
                                          collapse = " | "), "\n")
if (sum(ok) < 0.99 * RB_N) stop("more than 1 % of the draws failed; not writing bands from a censored sample")

# ---- the quantiles, per scenario, variable and year -----------------------
bands <- list(); key <- list(); sds <- list()
for (j in seq_along(RB_SCEN)) for (v in RB_VARS) {
  M <- do.call(rbind, lapply(runs[ok], function(r) r$res[[j]][, v]))      # draws x years
  q <- apply(M, 2, stats::quantile, probs = RB_PROBS, names = FALSE, type = 7)
  bands[[length(bands) + 1L]] <- data.frame(
    scenario = unname(RB_SCEN[j]), label = names(RB_SCEN)[j], var = v, year = RB_YEAR,
    q05 = q[1, ], q50 = q[2, ], q95 = q[3, ], central = unname(central[[j]][, v]),
    stringsAsFactors = FALSE)
  kk <- match(RB_KEY_YEARS, RB_YEAR)
  key[[length(key) + 1L]] <- data.frame(
    draw = rep(which(ok), times = length(kk)), scenario = unname(RB_SCEN[j]), var = v,
    year = rep(RB_KEY_YEARS, each = sum(ok)), value = as.vector(M[, kk]), stringsAsFactors = FALSE)
  sds[[sprintf("%s|%s", RB_SCEN[j], v)]] <- stats::setNames(apply(M[, kk, drop = FALSE], 2, stats::sd), RB_KEY_YEARS)
}
bands <- do.call(rbind, bands); rownames(bands) <- NULL
key <- do.call(rbind, key); rownames(key) <- NULL

cat("\n--- the bands at the key years (5 % / median / 95 %; central = the app's line) ---\n")
for (s in RB_SCEN) for (v in RB_VARS) for (y in RB_KEY_YEARS) {
  b <- bands[bands$scenario == s & bands$var == v & bands$year == y, ]
  cat(sprintf("  %-5s %-7s %d  %8.2f  %8.2f  %8.2f   central %8.2f  (sd %.2f)\n", s, v, y,
              b$q05, b$q50, b$q95, b$central, sds[[sprintf("%s|%s", s, v)]][[as.character(y)]]))
}
inside <- mean(bands$central >= bands$q05 & bands$central <= bands$q95)
cat(sprintf("the central line lies inside [5 %%, 95 %%] in %.1f %% of the %d cells\n", 100 * inside, nrow(bands)))

# ---- PRE-CHECK: the linear (delta-method) sd at a few cells ----------------
# sd_lin = sqrt(g' Sig g), g the central-difference gradient in u-space at
# RB_GRAD_FRAC x each name's marginal sd. Printed beside the sampled sd: a
# ratio far from 1 is either nonlinearity worth knowing about or a bug.
cat("\n--- pre-check: delta-method sd vs sampled sd ---\n")
cell_value <- function(rr, cell) {
  j <- match(cell[1], RB_SCEN); y <- match(as.integer(cell[3]), RB_YEAR)
  rr$res[[j]][y, cell[2]]
}
gr <- parallel::mclapply(names(u0), function(n) {
  h <- RB_GRAD_FRAC * sqrt(Sig[n, n]); up <- u0; dn <- u0
  up[[n]] <- up[[n]] + h; dn[[n]] <- dn[[n]] - h
  ru <- run_vector(ccx_unc_to_par(up)); rd <- run_vector(ccx_unc_to_par(dn))
  vapply(RB_LIN_CELLS, function(cl) (cell_value(ru, cl) - cell_value(rd, cl)) / (2 * h), numeric(1))
}, mc.cores = RB_CORES)
G <- do.call(rbind, gr); rownames(G) <- names(u0)
sd_lin <- sqrt(colSums(G * (Sig %*% G)))
lin <- data.frame(cell = vapply(RB_LIN_CELLS, paste, "", collapse = " "), sd_linear = sd_lin,
                  sd_sampled = vapply(RB_LIN_CELLS, function(cl)
                    sds[[sprintf("%s|%s", cl[1], cl[2])]][[cl[3]]], numeric(1)))
lin$ratio <- lin$sd_sampled / lin$sd_linear
print(lin, row.names = FALSE, digits = 4)
cat(sprintf("names with an exactly-zero gradient (likelihood-only): %s\n",
            paste(rownames(G)[rowSums(abs(G)) == 0], collapse = ", ")))

# ---- the artifact (no wall-clock time in it: two runs must be byte-identical) ----
out <- list(
  bands = bands,
  key_draws = key,
  linear_check = lin,
  provenance = list(
    driver = RB_DRIVER, commit = RB_COMMIT,
    mode = CCX_MODE_CANONICAL, struct = ccx_mode_struct(md),
    mode_file = sub(paste0("^", RB_ROOT, "/"), "", ccx_mode_file(CCX_MODE_CANONICAL)),
    mode_logpost = md$logpost, par_mode = md$par_mode, u_center = u0,
    method = if (nzchar(RB_DRAWS_FILE)) sprintf("SUPPLIED draws %s (md5 %s), each run like a Laplace draw", RB_DRAWS_FILE, RB_DRAWS_MD5) else paste("Laplace: multivariate normal in the unconstrained (u) space at the stored mode,",
                   "covariance = the mode file's stored inverse negative Hessian; each draw decoded",
                   "through the file's own transforms and bands (ccx_adopt_mode_band), the held",
                   "values added back, and run through the full nonlinear model (its own spin-up,",
                   "then app_run_coupled per scenario) by the app's own functions"),
    covariance_note = RB_COV_NOTE,
    label = RB_LABEL, n_held = RB_N_HELD, held = RB_PINS,
    n_draws = RB_N, n_ok = sum(ok), n_failed = sum(!ok), n_warnings = nwarn,
    probs = RB_PROBS, scenarios = RB_SCEN, years = range(RB_YEAR), vars = RB_VARS,
    emis_method = CCX_EMIS_METHOD_DEFAULT,
    seed = if (nzchar(RB_DRAWS_FILE)) NA_integer_ else RB_SEED, rng_kind = RB_RNG_KIND,
    seed_applied = if (nzchar(RB_DRAWS_FILE)) "draws supplied: their seeds are recorded in their own source (e.g. each MCMC chain file)" else paste("set.seed() immediately before the single rnorm(n_draws x n_names) call that",
                         "draws the standard normals; the draw matrix is fixed before any model run,",
                         "so the forked runs consume no RNG"),
    central_check_max_abs = dc, central_check_tol = RB_CENTRAL_TOL))
dir.create(dirname(RB_OUT), showWarnings = FALSE, recursive = TRUE)
saveRDS(out, RB_OUT)
cat(sprintf("\nsaved %s (%d band rows); total %.1f min\n", sub(paste0("^", RB_ROOT, "/"), "", RB_OUT),
            nrow(bands), as.numeric(difftime(Sys.time(), RB_T0, units = "mins"))))
sink()
