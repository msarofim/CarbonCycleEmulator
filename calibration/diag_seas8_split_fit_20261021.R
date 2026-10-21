# =====================================================================
# diag_seas8_split_fit_20261021.R -- T8c step 2: ONE re-optimization of the
# seasonal parameter block on a stated set of likelihood rows, every other fitted
# parameter held at the canonical mode.
#
# The block, the row sets and the reason variant B exists are in
# diag_seas8_split_screen_20261021.R (whose rds this reads for the scales and the
# quadratic starts). In short:
#   variant A (Marcus's default): block log-prior + seasonal rows only
#     A_i = CO2 seasonal rows, A_ii = d13C seasonal rows, A_iii = all four
#   variant B (the rows NEEDED for the joint fit to reproduce the mode): every row
#     B_i = all rows minus the d13C seasonal rows, B_ii = all rows minus the CO2
#     seasonal rows, B_iii = all rows (= the canonical objective on the block)
# The non-block priors are constants (their names are held) and are included.
#
# OPTIMIZER (deterministic, no RNG): cycles of Nelder-Mead restarts then a BFGS
# polish, run_price_profile.R's recipe with a tighter cycle tolerance (the block is
# 8-D and the quantities read off it are differences of a few log-units). Each
# restart re-centres the simplex on the best point so far; coordinates are scaled
# by S8F_SIMPLEX_SD x the block-marginal sd of B_iii at the mode (screen), so the
# first simplex step is S8F_SIMPLEX_SD sd in every direction. The returned point is
# RE-EVALUATED and only an evaluated improvement is kept. Resumable by checkpoint.
#
# Usage: Rscript calibration/diag_seas8_split_fit_20261021.R --set=B_i --start=mode
#          [--start=quad:B_i | --start=fit:<path to another fit's rds>] [--budget-min=75]
# =====================================================================
S8F_ARGS <- commandArgs(trailingOnly = TRUE)
s8f_arg <- function(key, default) {
  hit <- grep(sprintf("^--%s=", key), S8F_ARGS, value = TRUE)
  if (length(hit)) sub(sprintf("^--%s=", key), "", hit[1]) else default
}
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(file.path("calibration", "lib_seas8_20261021.R"))

S8F_DRIVER      <- "calibration/diag_seas8_split_fit_20261021.R"
S8F_COMMIT      <- ccx_git_stamp()
S8F_SET         <- s8f_arg("set", "")
S8F_START       <- s8f_arg("start", "mode")
S8F_BUDGET_MIN  <- as.numeric(s8f_arg("budget-min", 75))   # CPU minutes, this fit
S8F_RESTARTS    <- 3L
S8F_CYCLES      <- 6L
S8F_NM_MAXIT    <- 3000L
S8F_NM_RELTOL   <- 1e-10
S8F_TOL         <- 1e-4      # a restart gaining less than this ends the cycle's restarts
S8F_CYCLE_TOL   <- 0.01      # a cycle gaining less than this is CONVERGED (log-units)
S8F_POLISH_MAXIT <- 300L
S8F_NDEPS       <- 1e-3      # BFGS finite-difference step in scaled units: 1e-3 x 10 x S8F_SIMPLEX_SD sd = 0.01 sd
S8F_SIMPLEX_SD  <- 1         # first NM simplex step, in block-marginal sd
S8F_PENALTY_MULT <- 10; S8F_PENALTY_FLOOR <- 1e6
S8F_SCREEN <- file.path(S8_OUT_DIR, sprintf("t8c_screen_%s.rds", S8_MODE))
stopifnot(nzchar(S8F_SET))
S8F_TAG  <- sprintf("%s_from_%s", S8F_SET, gsub("[^A-Za-z0-9_]", "", sub("^fit:.*/t8c_fit_", "fit_", sub("[.]rds$", "", S8F_START))))
S8F_STEM <- file.path(S8_OUT_DIR, sprintf("t8c_fit_%s", S8F_TAG))
S8F_CKPT <- paste0(S8F_STEM, "_ckpt.rds")
cpu_min <- function() { t <- proc.time(); (t[["user.self"]] + t[["sys.self"]]) / 60 }
say <- function(...) { cat(sprintf(...)); flush.console() }
say("=== %s @%s, %s: set %s, start %s ===\n", S8F_DRIVER, S8F_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"),
    S8F_SET, S8F_START)

S  <- s8_setup(S8F_DRIVER)
SC <- readRDS(S8F_SCREEN)
if (!identical(SC$provenance$mode_md5, S$mode_md5)) stop("the screen was built at a different mode file")
BLOCK <- SC$block
if (!identical(BLOCK, intersect(BLOCK, CCX_PARAM_NAMES))) stop("the screen's block is not fitted here")
if (!S8F_SET %in% names(SC$sets)) stop("unknown set ", S8F_SET, "; known: ", paste(names(SC$sets), collapse = ", "))
ROWS <- setdiff(SC$sets[[S8F_SET]], "logprior")
say("BLOCK (%d): %s\nROWS (%d): %s\n", length(BLOCK), paste(BLOCK, collapse = ", "), length(ROWS),
    paste(ROWS, collapse = ", "))
SCALE <- S8F_SIMPLEX_SD * 10 * SC$pred$B_iii$marg_sd     # z = 0.1 (NM's first step) -> S8F_SIMPLEX_SD sd
u0 <- S$u0

parts <- function(x) {
  u <- u0; u[BLOCK] <- x
  v <- tryCatch(S$lp(u), error = function(e) NULL)
  if (is.null(v) || !is.finite(as.numeric(v))) return(NULL)
  st <- unlist(attr(v, "streams"))
  list(obj = attr(v, "logprior") + sum(st[ROWS]), logprior = attr(v, "logprior"), streams = st,
       logpost = as.numeric(v))
}
x_start <- switch(sub(":.*", "", S8F_START),
  mode = u0[BLOCK],
  quad = { q <- SC$pred[[sub("^quad:", "", S8F_START)]]
           if (is.null(q) || !isTRUE(q$neg_def)) stop("no usable quadratic prediction for ", S8F_START)
           u0[BLOCK] + q$du },
  fit  = { fr <- readRDS(sub("^fit:", "", S8F_START)); fr$result$x[BLOCK] },
  stop("unknown --start ", S8F_START))
p_st <- parts(x_start)
if (is.null(p_st)) stop("the start is not finite")
say("start objective %.6f (log-prior %.4f)\n", p_st$obj, p_st$logprior)
PENALTY <- max(S8F_PENALTY_FLOOR, S8F_PENALTY_MULT * abs(p_st$obj))

ID <- list(set = S8F_SET, start = S8F_START, mode_md5 = S$mode_md5, rows = ROWS, block = BLOCK)
St <- if (file.exists(S8F_CKPT)) readRDS(S8F_CKPT) else
  list(x = x_start, best = -p_st$obj, cycle = 0L, n_eval = 0L,
       trace = data.frame(cycle = 0L, step = "start", obj = p_st$obj, cpu_min = 0), id = ID)
if (!identical(St$id, ID)) stop(S8F_CKPT, " belongs to another fit: move it aside")
if (St$cycle > 0L) say("RESUMED at cycle %d, objective %.6f\n", St$cycle, -St$best)
cpu0 <- cpu_min() - (if (nrow(St$trace)) max(St$trace$cpu_min) else 0)
used <- function() cpu_min() - cpu0
centre <- NULL
negz <- function(z) { St$n_eval <<- St$n_eval + 1L; p <- parts(centre + z * SCALE)
  if (is.null(p)) PENALTY else -p$obj }
keep <- function(res, step) {
  x <- centre + res$par * SCALE
  p <- parts(x); v <- if (is.null(p)) PENALTY else -p$obj
  St$trace <<- rbind(St$trace, data.frame(cycle = St$cycle, step = step, obj = -v, cpu_min = used()))
  if (v < St$best) { St$x <<- stats::setNames(x, BLOCK); St$best <<- v }
  saveRDS(St, S8F_CKPT)
}
z0 <- rep(0, length(BLOCK))
converged <- FALSE
while (St$cycle < S8F_CYCLES && used() < S8F_BUDGET_MIN) {
  St$cycle <- St$cycle + 1L; c_start <- St$best
  for (r in seq_len(S8F_RESTARTS)) {
    if (used() >= S8F_BUDGET_MIN) break
    r_start <- St$best; centre <- St$x
    res <- stats::optim(z0, negz, method = "Nelder-Mead",
                        control = list(maxit = S8F_NM_MAXIT, reltol = S8F_NM_RELTOL))
    keep(res, sprintf("NM restart %d", r))
    say("  cycle %d NM %d: obj %.6f (gain %.6f, %d evals, %.1f CPU-min)\n", St$cycle, r, -St$best,
        r_start - St$best, res$counts[["function"]], used())
    if (r_start - St$best < S8F_TOL) break
  }
  if (used() < S8F_BUDGET_MIN) {
    p_start <- St$best; centre <- St$x
    res <- stats::optim(z0, negz, method = "BFGS",
                        control = list(maxit = S8F_POLISH_MAXIT, reltol = S8F_NM_RELTOL,
                                       ndeps = rep(S8F_NDEPS, length(BLOCK))))
    keep(res, "BFGS polish")
    say("  cycle %d BFGS: obj %.6f (gain %.6f, convergence %d, %.1f CPU-min)\n", St$cycle, -St$best,
        p_start - St$best, res$convergence, used())
  }
  if (c_start - St$best < S8F_CYCLE_TOL) {
    converged <- TRUE
    say("cycle %d gained %.6f < %g: CONVERGED\n", St$cycle, c_start - St$best, S8F_CYCLE_TOL); break
  }
}
if (!converged) say("STOPPED %s without a converged cycle (%.1f CPU-min)\n",
                    if (St$cycle >= S8F_CYCLES) "at the cycle cap" else "at the budget", used())
pf <- parts(St$x)
u_best <- u0; u_best[BLOCK] <- St$x; nat <- ccx_unc_to_par(u_best)
RES <- list(x = St$x, natural = unlist(nat[BLOCK]), obj = pf$obj, logprior = pf$logprior,
            streams = pf$streams, logpost = pf$logpost, loglik = sum(pf$streams))
say("\nRESULT %s: objective %.6f | log-prior %.4f | full logpost %.4f | full likelihood %.4f\n", S8F_TAG,
    RES$obj, RES$logprior, RES$logpost, RES$loglik)
say("  seasonal rows: %s\n", paste(sprintf("%s %.3f", unlist(S8_SEAS_ROWS), RES$streams[unlist(S8_SEAS_ROWS)]),
                                    collapse = ", "))
say("  block: %s\n", paste(sprintf("%s %.5g", BLOCK, RES$natural), collapse = ", "))
saveRDS(list(result = RES, converged = converged, trace = St$trace, n_eval = St$n_eval,
             provenance = list(driver = S8F_DRIVER, lib = "calibration/lib_seas8_20261021.R",
                               commit = S8F_COMMIT, mode = S8_MODE, mode_file = S$mode_file,
                               mode_md5 = S$mode_md5, set = S8F_SET, rows = ROWS, block = BLOCK,
                               start = S8F_START, start_x = x_start, scale = SCALE,
                               recipe = c(restarts = S8F_RESTARTS, cycles = S8F_CYCLES, nm_maxit = S8F_NM_MAXIT,
                                          nm_reltol = S8F_NM_RELTOL, tol = S8F_TOL, cycle_tol = S8F_CYCLE_TOL,
                                          polish_maxit = S8F_POLISH_MAXIT, ndeps = S8F_NDEPS,
                                          simplex_sd = S8F_SIMPLEX_SD),
                               budget_cpu_min = S8F_BUDGET_MIN, cpu_min = used(),
                               rng = "none (Nelder-Mead and BFGS are deterministic)",
                               held = "every fitted name outside BLOCK at the canonical mode; pins as the mode file",
                               built = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(S8F_STEM, ".rds"))
say("wrote %s.rds\n=== DONE ===\n", S8F_STEM)
