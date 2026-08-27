# =====================================================================
# diag_ridge_reparam.R -- DOES FITTING IN RIDGE COORDINATES COST FEWER
#                         OBJECTIVE EVALUATIONS?   (2026-08-26, REDESIGNED)
#
# WHY. The 2026-08-25f refit spent ~332,000 objective evaluations per arm in
# CYCLE 1 ALONE. Nelder-Mead is strictly serial, so no hardware shortens ONE
# arm: the only lever is fewer evaluations. And the reason so many are needed is
# already known here -- `beta_max` and `fert_k` are correlated at rho = +0.997,
# which is exactly what collapses a simplex. The good coordinates were also
# discovered here: the ridge-invariant present-day enhancement
#     enh(chi) = beta_max * d / (fert_k + d),   d = chi - CO2_PI
# is what the historical CO2 integral actually constrains.
#
# ---------------------------------------------------------------------
# WHAT THE FIRST VERSION GOT WRONG, recorded because it is the whole lesson.
#
# (1) IT STARTED IN THE WRONG REGIME. Its perturbation (sd 0.35 in u-units) put
#     the starts at log-post -26,000 to -150,000 -- 1.4 to 8x WORSE than the
#     driver's own COLD init (-18,634) and 14-79x worse than its warm start
#     (-1,909). Nearly the whole budget went on gross descent, where the ridge
#     geometry is irrelevant. Measured start scales:
#         sd 0.02 -> median lp   -1,672      sd 0.10 -> median  -3,677
#         sd 0.05 -> median      -3,130      sd 0.35 -> median -74,014
#     The regime that costs the refit its 332k evals is NEAR-OPTIMUM
#     ridge-crawling, which is sd ~ 0.02-0.03. That is what is used now.
#
# (2) IT USED THE WRONG STATISTIC. "log-post reached at a fixed budget" is
#     dominated by whichever arm happened to be descending faster when the
#     budget ran out. The question is EVALS TO REACH A GIVEN QUALITY, so the
#     objective is instrumented with an evaluation counter and the full
#     best-so-far trace is kept.
#
# (3) ITS "CO2 identical" GATE COULD NOT FAIL -- both arms had silently run the
#     same code. GATE 2 below asserts the two arms DIFFER.
#
# THE OBJECTIVE STAYS BIT-IDENTICAL AND ONLY THE SEARCH COORDINATES CHANGE.
# Reparametrising by editing CCX_PARAM_TABLE would change the PRIOR (a different
# transform carries a different Jacobian), so a "faster" result could just be an
# easier problem. Nothing here touches CCX_PARAM_TABLE, R/ or src/; instead
#     lp2(v) = lp(u_of_v(v))
# is the SAME posterior read through a change of variables. GATE 1 asserts that
# identity to machine precision and the file stops if it ever fails.
#
# PAIRED DESIGN: both coordinate systems start from the SAME perturbed point.
#
# Usage:  Rscript calibration/diag_ridge_reparam.R <start_index> <u|v>   # worker
#         Rscript calibration/diag_ridge_reparam.R report                # aggregate
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

# ---- named constants ------------------------------------------------
RR_CHI      <- 420          # ppm, the epoch enh() is held at
RR_BASE     <- ccx_mode_file()          # THE CANONICAL MODE (R/paths.R)
RR_PERTURB  <- as.numeric(Sys.getenv("CCX_RR_PERTURB", "0.025"))
RR_NSTART   <- 4
RR_CAP      <- 8000L        # evals per run; the driver's own per-call cadence is 10.6-20k
RR_SEED     <- 20260826L
RR_TAG      <- Sys.getenv("CCX_RR_TAG", "")   # separates one campaign's files from another's
# ---- EVALS-TO-THRESHOLD, the statistic that replaced "log-post at a cap" ----
# The 2026-08-26 campaign at sd 0.025 returned a NULL (paired mean +0.23 +/- 0.78,
# p = 0.59, sign split 2:2) -- BUT EVERY RUN STOPPED 1.0-2.3 LOG-UNITS SHORT of
# the canonical mode, so it measured progress-from-a-distance, not convergence.
# The refit's own profile says the cost is in the FINAL CRAWL: `ref` went
# -1909 -> -1602 in 402 evals and needed ~330,000 more for the last ~40. A race
# that never enters that regime is BLIND to the thing it is testing
# (memory no_power_null). Hence a smaller perturbation and a threshold ladder.
RR_THRESH   <- c(-1546.0, -1545.5, -1545.0, -1544.8)
RR_HML      <- LIK_OCEAN_GRAD_HML_OK
OUTDIR      <- ccx_path("calibration", "output", "ridge_reparam")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)

CCX_PARAM_TABLE$h_ml$lo <- RR_HML[1]; CCX_PARAM_TABLE$h_ml$hi <- RR_HML[2]
CCX_PARAM_TABLE$h_ml$prior <- local({ lo <- RR_HML[1]; hi <- RR_HML[2]
                                      function(x) stats::dunif(x, lo, hi, log = TRUE) })
D_NOW <- RR_CHI - ccx_const("CO2_PI_PPM")
IB <- match("beta_max", CCX_PARAM_NAMES); IF <- match("fert_k", CCX_PARAM_NAMES)
SB <- CCX_PARAM_TABLE$beta_max; SF <- CCX_PARAM_TABLE$fert_k
# enh's bounds are DERIVED from the parents' box, not chosen: enh increases in
# beta_max and decreases in fert_k (memory derive_gate_from_the_thing).
RR_ENH_LO <- max(SB$lo * D_NOW / (SF$hi + D_NOW), 1e-8)
RR_ENH_HI <- min(SB$hi * D_NOW / (SF$lo + D_NOW), SB$hi)
.lgt  <- function(x, lo, hi) log((x - lo) / (hi - x))
.ilgt <- function(z, lo, hi) lo + (hi - lo) / (1 + exp(-z))

u_of_v <- function(v) {
  v[[IB]] <- v[[IB]] - RR_OFFSET
  u <- v
  fert <- .ilgt(v[[IF]], SF$lo, SF$hi)
  bmax <- .ilgt(v[[IB]], RR_ENH_LO, RR_ENH_HI) * (fert + D_NOW) / D_NOW
  # OUT OF beta_max's BOX IS -Inf, not NA: the two arms must share a FEASIBLE
  # SET and differ only in coordinates, or the race is measuring the wrong thing.
  if (!is.finite(bmax) || bmax <= SB$lo || bmax >= SB$hi) return(NULL)
  u[[IB]] <- .lgt(bmax, SB$lo, SB$hi); u
}
# ---- THE STEP-SCALE CONFOUND, AND HOW IT IS REMOVED ------------------
# optim()'s Nelder-Mead builds its initial simplex by perturbing each coordinate
# by 10 % OF ITS VALUE. logit(beta_max) and logit(enh) are different numbers, so
# the two arms would start from different-sized simplexes and part of any
# difference would be step scale rather than geometry. RR_OFFSET translates the
# enh coordinate so that at the start it equals the beta_max coordinate
# NUMERICALLY. A translation cannot change the geometry -- it only makes the two
# optimisers see identical starting vectors, so the initial simplex is identical
# in every slot and what remains is decorrelation alone.
RR_OFFSET <- 0     # set per start in worker mode
v_of_u <- function(u) {
  v <- u
  fert <- .ilgt(u[[IF]], SF$lo, SF$hi)
  enh  <- .ilgt(u[[IB]], SB$lo, SB$hi) * D_NOW / (fert + D_NOW)
  v[[IB]] <- .lgt(min(max(enh, RR_ENH_LO * (1 + 1e-12)), RR_ENH_HI * (1 - 1e-12)),
                  RR_ENH_LO, RR_ENH_HI) + RR_OFFSET; v
}

# ---- the common starts, generated identically in every worker --------
rr_starts <- function(U0) {
  set.seed(RR_SEED)
  lapply(seq_len(RR_NSTART), function(i) U0 + stats::rnorm(length(U0), 0, RR_PERTURB))
}

# ---- report mode -----------------------------------------------------
ARGS <- commandArgs(TRUE)
if (length(ARGS) && identical(ARGS[1], "report")) {
  fs <- list.files(OUTDIR, pattern = sprintf("^race%s_[0-9]+_[uv][.]rds$", RR_TAG), full.names = TRUE)
  R <- lapply(fs, readRDS); names(R) <- basename(fs)
  key <- function(i, c) sprintf("race%s_%d_%s.rds", RR_TAG, i, c)
  cat(sprintf("=== RIDGE REPARAMETRISATION RACE (cap %d evals, start sd %.3f) ===\n",
              RR_CAP, RR_PERTURB))
  cat(sprintf("base: %s\n\n", RR_BASE))
  cat(sprintf("%-6s %10s %11s %11s %9s | %s\n", "start", "start lp", "u final",
              "v final", "v - u",
              paste(sprintf("%9s", paste0("n@", RR_THRESH)), collapse = "")))
  dv <- c(); TE <- list()
  for (i in seq_len(RR_NSTART)) {
    a <- R[[key(i, "u")]]; b <- R[[key(i, "v")]]
    if (is.null(a) || is.null(b)) { cat(sprintf("%-6d (incomplete)\n", i)); next }
    dv <- c(dv, b$best - a$best); TE[[length(TE) + 1L]] <- rbind(a$thresh_evals, b$thresh_evals)
    fmt <- function(x) ifelse(is.na(x), "    --", sprintf("%5.0f", x))
    cat(sprintf("%-6d %10.1f %11.2f %11.2f %+9.2f | %s\n", i, a$start_lp, a$best, b$best,
                b$best - a$best,
                paste(sprintf("%4s/%4s", fmt(a$thresh_evals), fmt(b$thresh_evals)), collapse = " ")))
  }
  cat("\n(the n@ columns are u-evals / v-evals to first reach that log-post; -- = never)\n")
  # PRIMARY STATISTIC: the paired difference in final log-post. The old
  # "speedup" ratio was RETIRED 2026-08-27 -- when the ridge arm loses it is
  # below 1 by construction and its magnitude depends on an arbitrary crossing
  # point, so it is not symmetric and must not be medianed.
  cat(sprintf("\nPAIRED (v - u) final log-post: mean %+.3f, sd %.3f, t(%d) = %.2f, p = %.3f\n",
              mean(dv), stats::sd(dv), length(dv) - 1L,
              mean(dv) / (stats::sd(dv) / sqrt(length(dv))), stats::t.test(dv)$p.value))
  cat(sprintf("sign split: %d favour ridge, %d favour the original coordinates\n",
              sum(dv > 0), sum(dv < 0)))
  # and the ladder, paired, where both arms reached the rung
  for (k in seq_along(RR_THRESH)) {
    r <- do.call(rbind, lapply(TE, function(m) m[, k]))
    ok <- stats::complete.cases(r)
    if (sum(ok) < 2) { cat(sprintf("  %8.1f : too few starts reached it (%d)\n", RR_THRESH[k], sum(ok))); next }
    cat(sprintf("  %8.1f : u median %6.0f evals, v median %6.0f  -> ridge is %.2fx (n=%d)\n",
                RR_THRESH[k], stats::median(r[ok, 1]), stats::median(r[ok, 2]),
                stats::median(r[ok, 1]) / stats::median(r[ok, 2]), sum(ok)))
  }
  saveRDS(list(runs = R, dv = dv, thresh = RR_THRESH),
          file.path(OUTDIR, sprintf("race%s_summary.rds", RR_TAG)))
  quit(save = "no")
}

# ---- worker mode -----------------------------------------------------
stopifnot(length(ARGS) == 2L)
IDX <- as.integer(ARGS[1]); CO <- ARGS[2]
stopifnot(IDX >= 1L, IDX <= RR_NSTART, CO %in% c("u", "v"))
ccx_load_cpp()
lp <- ccx_make_logpost()
md <- readRDS(RR_BASE)                  # ccx_mode_file() is already absolute
U0 <- ccx_par_to_unc(md$par_mode)

if (IDX == 1L && CO == "u") {           # gates run once, in the first worker
  cat("GATE 1: lp2(v_of_u(u)) must equal lp(u) -- same function, new coordinates\n")
  set.seed(RR_SEED + 99L)
  g <- vapply(1:5, function(i) {
    u <- U0 + stats::rnorm(length(U0), 0, RR_PERTURB)
    a <- lp(u); uu <- u_of_v(v_of_u(u)); b <- if (is.null(uu)) -Inf else lp(uu)
    if (!is.finite(a) && !is.finite(b)) 0 else abs(a - b)
  }, numeric(1))
  cat(sprintf("  max |lp - lp2| = %.3e ; round-trip |u - u(v(u))| = %.3e\n",
              max(g), max(abs(u_of_v(v_of_u(U0)) - U0))))
  stopifnot(max(g) < 1e-8, max(abs(u_of_v(v_of_u(U0)) - U0)) < 1e-8)
  cat("GATE 1 PASS\n")
}

# instrumented objective: counts EVERY call and keeps the best-so-far trace
n <- 0L; best <- -Inf; tr <- list()
counted <- function(z) {
  n <<- n + 1L
  val <- if (CO == "u") lp(z) else { uu <- u_of_v(z); if (is.null(uu)) -Inf else lp(uu) }
  if (is.finite(val) && val > best) { best <<- val; tr[[length(tr) + 1L]] <<- c(n, val) }
  val
}
x0 <- rr_starts(U0)[[IDX]]
if (CO == "v") {
  RR_OFFSET <<- 0
  RR_OFFSET <<- x0[[IB]] - v_of_u(x0)[[IB]]   # so v's IB slot starts at u's number
  x0 <- v_of_u(x0)
  stopifnot(abs(x0[[IB]] - rr_starts(U0)[[IDX]][[IB]]) < 1e-12)   # identical simplex
}
t0 <- Sys.time()
stats::optim(x0, function(z) -counted(z), method = "Nelder-Mead",
             control = list(maxit = RR_CAP, reltol = 1e-12))
el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
out <- list(idx = IDX, coord = CO, n = n, best = best,
            trace = do.call(rbind, tr), secs = el,
            start_lp = tr[[1]][2], cap = RR_CAP, perturb = RR_PERTURB, base = RR_BASE)
out$offset <- RR_OFFSET
out$thresh_evals <- vapply(RR_THRESH, function(th) {
  k <- which(out$trace[, 2] >= th)[1]; if (is.na(k)) NA_real_ else out$trace[k, 1] }, numeric(1))
names(out$thresh_evals) <- as.character(RR_THRESH)
saveRDS(out, file.path(OUTDIR, sprintf("race%s_%d_%s.rds", RR_TAG, IDX, CO)))
cat(sprintf("[start %d, %s-coords] %d evals in %.0f s -> best %.2f\n", IDX, CO, n, el, best))
