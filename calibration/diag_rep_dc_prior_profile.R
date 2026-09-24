# =====================================================================
# diag_rep_dc_prior_profile.R -- T4p (the R2 test menu, 2026-09-22 (q) item 3):
# "what would the model look like under a CANDIDATE rep_dC prior?" --
# answered EXACTLY from T1's measured profile, with NO objective change.
#
# ⛔⛔ THIS IS A PROBE AND IT CHANGES NOTHING. No objective change, no mode file
# written, no prior altered, no model run. It reads the T1 ladder's artifacts
# (written by diag_rep_dc_product_ladder.R, a DIFFERENT script) and re-scores
# them against candidate priors. The objective stays frozen at #13.
#
# ⭐⭐⭐ WHY THIS IS EXACT AND NOT AN APPROXIMATION -- the one argument that makes
# the whole file legitimate, so read it before trusting a number:
#
#   T4 asks for the JOINT optimum of  L(r, theta) + priors(theta) + logprior(r)
#   over the free offset r = rep_dC and the other 28 names theta.  Profiling:
#       max_{r,theta} [ ... ]  ==  max_r [ max_theta ( L + priors_theta ) + logprior(r) ]
#   The inner maximisation is over theta AT FIXED r, where logprior(r) is an
#   ADDITIVE CONSTANT -- so the inner optimum does not depend on which rep_dC
#   prior is in force.  T1 MEASURED that inner optimum at 9 values of r with all
#   28 other names fully re-optimised.  Therefore
#       REST(r) := logpost_T1(r) - logprior_shipped(r)
#   is the prior-free profile, and the T4 answer under ANY candidate prior is
#       argmax_r [ REST(r) + logprior_candidate(r) ].
#   Exact up to (a) interpolation between the 9 rungs and (b) each rung's own
#   Nelder-Mead convergence.  GATE LOO measures (a); the T1 replicates measured
#   (b) and found 2.1e-3 log-units at the canonical rung.
#
# ⚠ THIS IS NOT THE CONJUGATE MAP, WHICH THIS PROJECT ALREADY MEASURED AS
# UNUSABLE HERE. The 09-22 (u) side test found the analytic conjugate formula
# understated every measured shift by up to 0.58 ppm against a 0.15 tolerance
# and refused to print itself as the answer. That failure was a LINEARISATION of
# the profile. This file does not linearise: it uses the profile T1 measured.
# `~/.claude/CLAUDE.md`, "use real data when you have it" -- PCHIP through the
# measured anchors, never a 2-parameter fit to them.
#
# ⛔ WHAT THIS DOES **NOT** REPLACE. T4 proper also wanted the arm REGISTERED and
# scored by the standard scorecard. Registration is a mode-file act and stays
# blocked behind the ruling (freeze record §4.1). This file answers the
# decision-relevant half -- where the offset lands, what it costs on the
# LIKELIHOOD (which is prior-free and therefore comparable across candidates),
# and which products and gates move -- so the ruling can be taken on measured
# numbers instead of on a refit that cannot be run until the ruling is taken.
#
# ⚠ AND IT INHERITS EVERY T1 CAVEAT. In particular the identities: `co2_pi` and
# `part1000_close` are SOLVED quantities, not products, and are reported under
# CHECKS. A `/floor` ratio is meaningless because T1's noise floor is zero; read
# each product against its OBSERVATIONAL sigma instead.
#
# Usage:  Rscript calibration/diag_rep_dc_prior_profile.R          # the report
#         Rscript calibration/diag_rep_dc_prior_profile.R mutate   # gate power
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
setwd(.root)
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

# ---- NAMED CONSTANTS: every label, filename and column below derives from ----
RPP_TAG        <- "rep_dc_prior_profile"
RPP_DATE       <- "20260923"
# ⚠ OVERRIDABLE ONLY so the MUTATION TEST can point at a deliberately corrupted
# COPY of the ladder. A mutated run also redirects RPP_OUTDIR, so it can never
# write into the real run's directory and be read back as if it were one.
RPP_LADDER_DIR <- Sys.getenv("RPP_LADDER_DIR",
                    file.path("outputs", "diagnostics", "rep_dc_product_ladder_20260923"))
RPP_OUTDIR     <- Sys.getenv("RPP_OUTDIR",
                    file.path("outputs", "diagnostics", sprintf("%s_%s", RPP_TAG, RPP_DATE)))
RPP_LOG        <- file.path(RPP_OUTDIR, sprintf("%s_%s.log", RPP_TAG, RPP_DATE))
RPP_RDS        <- file.path(RPP_OUTDIR, sprintf("%s_%s.rds", RPP_TAG, RPP_DATE))

RPP_MU_MEAS    <- 0.776    # MEASURED station-vs-hemisphere offset, MBL zonal
RPP_MU_MASSW   <- -0.215   # MASS-WEIGHTED expectation for a whole-atmosphere box
# The candidate grid = the decision space R2 actually faces. The sigma floor
# 0.2 ppm is Francey et al. 2019's defensible representation-term floor; 1.0 is
# the shipped LIK_CO2_REP_ERR; 0.5 is the midpoint that the 09-22 (u) side test
# also probed, so the two are cross-checkable.
RPP_MU_GRID    <- c(0.000, RPP_MU_MEAS, RPP_MU_MASSW)
RPP_SIG_GRID   <- c(1.0, 0.5, 0.2)
RPP_GRID_N     <- 20001L   # fine grid inside the ladder for the argmax
RPP_EDGE_FRAC  <- 0.01     # argmax within this fraction of a ladder end = BOUNDARY
# ⛔⛔ THE FIRST VERSION OF THIS GATE WAS BLIND, AND THE MUTATION TEST SAID SO.
# It scaled its own tolerance to the spread of the leave-one-out residuals --
# but a corrupted rung CONTAMINATES ITS NEIGHBOURS' residuals too, so injecting
# -20 log-units into one rung inflated the bound faster than the residual, and
# the gate passed. A bound computed from the data it tests cannot reject that
# data; it is [[gate_reads_its_own_output]] in a tolerance's clothing.
#
# THE REPLACEMENT TAKES ITS BOUND FROM OUTSIDE THE LADDER. A profile likelihood
# in `rep_dC` over this range must be (a) strictly INCREASING, because the
# likelihood-only optimum lies ABOVE the top rung -- measured independently at
# 3.7 ppm, curvature sd 0.30, by diag_rep_dc_prior_centre_width.R on 09-22 (u)
# -- and (b) CONCAVE, because it is a max over nuisance directions of a smooth
# function approaching that optimum. Neither statement comes from this ladder,
# and no mutation of this ladder can move either.
RPP_SHAPE_SLOPE_MIN <- 0        # dL/dr must exceed this at every ladder interval
RPP_SHAPE_CURV_MAX  <- 0        # second divided difference must not exceed this
RPP_U_CURV_SD       <- 0.30     # 09-22 (u)'s measured curvature sd, ppm -> the corroboration
# The dominance tolerance is FROZEN from the clean 09-23 read (max |LOO| 0.449),
# NOT recomputed per run -- for exactly the reason above. ⚠ Its provenance IS
# this ladder, so it can never reject this ladder; it rejects a CHANGE to it,
# which is the only thing a mutation test can ask of it.
RPP_DOM_TOL    <- 0.45
RPP_LOO_K      <- 8
RPP_MUT_HIT    <- -20      # mutation: log-units injected into one rung
RPP_PROV_KEYS  <- c("mode", "mode_file", "spinup", "objective")

dir.create(RPP_OUTDIR, showWarnings = FALSE, recursive = TRUE)
sink(RPP_LOG, split = TRUE)
on.exit(sink(), add = TRUE)
cat(sprintf("== %s (T4p) == %s ==\n", RPP_TAG, format(Sys.time())))
cat("PROBE ONLY: no objective change, no mode file written, no model run.\n\n")

# ---- 1. load the ladder -------------------------------------------------
files <- sort(list.files(RPP_LADDER_DIR, pattern = "[.]rds$", full.names = TRUE))
if (!length(files)) stop("no ladder artifacts at ", RPP_LADDER_DIR)
lad <- lapply(files, readRDS)

# ---- GATE PROV: the 12 artifacts must describe ONE experiment ------------
gate_prov <- function(lad) {
  bad <- character(0)
  for (k in RPP_PROV_KEYS) {
    v <- vapply(lad, function(x) as.character(x$provenance[[k]] %||% NA), "")
    if (length(unique(v)) != 1L) bad <- c(bad, sprintf("%s differs: %s", k,
      paste(unique(v), collapse = " | ")))
  }
  nc <- vapply(lad, function(x) x$conv, 0L)
  if (any(nc != 0L)) bad <- c(bad, sprintf("conv != 0 in: %s",
    paste(vapply(lad, function(x) x$job$label, "")[nc != 0L], collapse = ", ")))
  rung0 <- vapply(lad, function(x) x$job$rung, 0)
  rep0  <- vapply(lad, function(x) x$job$rep,  0L)
  prof  <- rung0[rep0 == 0L]
  if (anyDuplicated(prof)) bad <- c(bad, "duplicate rung among rep==0 artifacts")
  if (length(prof) < 5L)   bad <- c(bad, sprintf("only %d profile rungs", length(prof)))
  bad
}
`%||%` <- function(a, b) if (is.null(a)) b else a
bad <- gate_prov(lad)
cat("GATE PROV : ", if (!length(bad)) "PASS\n" else
      paste0("FAIL\n  - ", paste(bad, collapse = "\n  - "), "\n"))
if (length(bad) && !identical(commandArgs(TRUE)[1], "mutate")) stop("GATE PROV failed")

# ⚠ recorded, NOT gated: T1's artifacts predate the tree_dirty stamp (handoff
# 09-23 (a) §6). They carry commit 422e473 while HEAD at launch was 3edcd33.
td <- vapply(lad, function(x) as.character(x$provenance$tree_dirty %||% "ABSENT"), "")
cat(sprintf("            tree_dirty stamp: %s | commit(s): %s\n",
    paste(unique(td), collapse = ","),
    paste(unique(vapply(lad, function(x) x$provenance$commit %||% "NA", "")), collapse = ",")))

# ---- 2. the prior-free profile REST(r) ----------------------------------
# ⛔ the prior is READ FROM THE OBJECTIVE, never re-typed here.
prior_shipped <- CCX_PARAM_TABLE$rep_dC$prior
stopifnot(is.function(prior_shipped))
cat(sprintf("            shipped prior: N(0, LIK_CO2_REP_ERR = %.3f), tr = '%s'\n\n",
            LIK_CO2_REP_ERR, CCX_PARAM_TABLE$rep_dC$tr))

prof <- lad[vapply(lad, function(x) x$job$rep, 0L) == 0L]
o    <- order(vapply(prof, function(x) x$job$rung, 0))
prof <- prof[o]
rr   <- vapply(prof, function(x) x$job$rung, 0)
lpst <- vapply(prof, function(x) x$products$scalar[["logpost"]], 0)
llik <- vapply(prof, function(x) x$products$scalar[["loglik"]],  0)
rest <- lpst - vapply(rr, prior_shipped, 0)

# CHECK (an IDENTITY, never evidence): REST + shipped prior reproduces logpost.
idmax <- max(abs(rest + vapply(rr, prior_shipped, 0) - lpst))
cat(sprintf("CHECK     : REST identity closes to %.2e (an IDENTITY -- carries no evidence)\n", idmax))

# the T1 replicates ARE the convergence floor at one rung
repj <- lad[vapply(lad, function(x) x$job$rep, 0L) > 0L]
floor_lp <- if (length(repj))
  max(abs(vapply(repj, function(x) x$products$scalar[["logpost"]], 0) - lpst[which.max(rr)])) else NA_real_
cat(sprintf("            T1 convergence floor at the canonical rung: %.2e log-units (n = %d)\n\n",
            floor_lp, length(repj)))

# ---- 3. PCHIP through the measured anchors ------------------------------
pchip <- function(x, y) splinefun(x, y, method = if (all(diff(y) > 0) || all(diff(y) < 0))
                                                   "monoH.FC" else "fmm")
# ---- GATE SHAPE: monotone + concave, both from OUTSIDE this ladder --------
# ⚠ TESTED ON **BOTH** CURVES. `llik` alone leaves a logpost-only corruption
# ungated, and REST -- not llik -- is what every candidate below is read off.
shape_of <- function(y) {
  sl <- diff(y) / diff(rr)
  cv <- diff(sl) / ((rr[-(1:2)] - rr[-((length(rr)-1):length(rr))]) / 2)
  list(slope = sl, curv = cv,
       bad_m = which(sl <= RPP_SHAPE_SLOPE_MIN), bad_c = which(cv > RPP_SHAPE_CURV_MAX))
}
cat("GATE SHAPE: loglik AND REST must be strictly INCREASING and CONCAVE\n")
shp <- list(loglik = shape_of(llik), REST = shape_of(rest))
for (nm in names(shp)) { z <- shp[[nm]]
  cat(sprintf("            %-6s slope : %s\n", nm, paste(sprintf("%.2f", z$slope), collapse = " ")))
  cat(sprintf("            %-6s curv  : %s\n", nm, paste(sprintf("%.2f", z$curv),  collapse = " ")))
  if (length(z$bad_m)) cat(sprintf("            ⛔ %s NOT INCREASING between rungs %.3f and %.3f\n",
                                    nm, rr[z$bad_m], rr[z$bad_m + 1]))
  if (length(z$bad_c)) cat(sprintf("            ⛔ %s NOT CONCAVE at rung %.3f\n", nm, rr[z$bad_c + 1]))
}
shape_bad <- any(vapply(shp, function(z) length(z$bad_m) + length(z$bad_c) > 0, TRUE))
cat("            ", if (!shape_bad) "PASS\n" else "FAIL\n")
if (shape_bad && !identical(commandArgs(TRUE)[1], "mutate")) stop("GATE SHAPE failed")
slope <- shp$loglik$slope; curv <- shp$loglik$curv
# ⭐ CORROBORATION, not a gate: the top-rung curvature implies a likelihood-only
# curvature sd of 1/sqrt(-d2L), against (u)'s independently measured 0.30 ppm.
sd_here <- 1 / sqrt(-tail(curv, 1))
cat(sprintf("            curvature sd from this ladder %.3f ppm vs (u)'s independent %.3f -> %.0f %% apart\n\n",
            sd_here, RPP_U_CURV_SD, 100 * abs(sd_here - RPP_U_CURV_SD) / RPP_U_CURV_SD))

# ---- the interpolation ERROR BAR -- REPORTED, deliberately NOT a gate -----
# Leave-one-out on REST(r) says how wrong the curve BETWEEN the anchors is.
# ⛔ It is not gated on, because its only available bound would be its own
# spread, which is the blindness described at RPP_DOM_TOL above.
pchip <- function(x, y) splinefun(x, y, method = if (all(diff(y) > 0) || all(diff(y) < 0))
                                                   "monoH.FC" else "fmm")
loo_resid <- function(x, y) {
  out <- rep(NA_real_, length(y))
  for (i in seq_along(y)) if (i > 2L && i < length(y) - 1L)
    out[i] <- y[i] - pchip(x[-i], y[-i])(x[i])
  out
}
lr <- loo_resid(rr, rest)
interp_sd <- max(abs(lr), na.rm = TRUE)
cat("BAR (not a gate): leave-one-out residuals on REST(r)\n")
for (i in which(!is.na(lr))) cat(sprintf("            rung %7.3f  resid %+9.4f\n", rr[i], lr[i]))
cat(sprintf("            => interpolation bar on a reconstructed logpost: %.3f log-units\n\n", interp_sd))

# ---- GATE DOMINANCE: the only check here with EXTERNAL power -------------
# The 09-22 (u) side test optimised the SAME objective at the same candidate
# corners with 8 of 29 names free. Its landing point is therefore a FEASIBLE
# point of T1's fully-free conditional problem, so T1's profile loglik at the
# SAME pinned rep_dC cannot be WORSE. Every row can fail; that is the point.
# ⚠ Row-level failures within the measured interpolation bar are reported as
# INTERPOLATION, not waved away -- the bar is measured just below, and the
# verdict names which of the two it is.
RPP_U_CORNERS <- data.frame(   # outputs/diagnostics/rep_dc_prior_centre_width_20260922.log Sec.3
  mu     = c(0.00,      0.00,      0.00,      0.78,      0.78),
  sigma  = c(1.00,      0.50,      0.20,      0.50,      0.20),
  rep_dC = c(3.516,     2.945,     1.390,     3.115,     1.865),
  loglik = c(-1391.805, -1394.456, -1420.485, -1393.280, -1409.422))

# ---- the ERROR BAR: four interpolators through the SAME 9 anchors --------
# `~/.claude/CLAUDE.md`: a number needs an error bar before it needs an
# explanation. The anchors are measured; the curve BETWEEN them is a choice,
# so the spread across that choice IS the uncertainty on every fitted rep_dC.
RPP_INTERP <- list(
  monoH.FC = function(x, y) splinefun(x, y, method = "monoH.FC"),
  fmm      = function(x, y) splinefun(x, y, method = "fmm"),
  natural  = function(x, y) splinefun(x, y, method = "natural"),
  linear   = function(x, y) approxfun(x, y))

# ---- 4. reconstruct T4 for each candidate prior -------------------------
f_rest <- pchip(rr, rest)
f_llik <- pchip(rr, llik)
SCAL   <- names(prof[[1]]$products$scalar)
f_scal <- lapply(SCAL, function(s) pchip(rr, vapply(prof, function(x) x$products$scalar[[s]], 0)))
names(f_scal) <- SCAL

grid <- seq(min(rr), max(rr), length.out = RPP_GRID_N)
edge <- RPP_EDGE_FRAC * diff(range(rr))
recon <- function(mu, sg) {
  v  <- f_rest(grid) + dnorm(grid, mu, sg, log = TRUE)
  i  <- which.max(v)
  r  <- grid[i]
  boundary <- (r - min(rr) < edge) || (max(rr) - r < edge)
  list(mu = mu, sigma = sg, rep_dC = r, boundary = boundary,
       loglik = f_llik(r), scal = vapply(SCAL, function(s) f_scal[[s]](r), 0))
}
f_ll_dom <- pchip(rr, llik)
dom <- RPP_U_CORNERS
dom$T1_full <- f_ll_dom(dom$rep_dC)
dom$gap     <- dom$T1_full - dom$loglik
cat("GATE DOMIN: T1's FULL-refit profile vs the 09-22 (u) 8-free refit, same pinned rep_dC\n")
for (i in seq_len(nrow(dom))) with(dom[i, ], cat(sprintf(
  "            mu %5.2f sg %4.2f  r %6.3f  u_8free %11.3f  T1_full %11.3f  gap %+7.3f  %s\n",
  mu, sigma, rep_dC, loglik, T1_full, gap,
  if (gap >= 0) "PASS" else if (abs(gap) <= RPP_DOM_TOL) "PASS (within the frozen interpolation tol)"
  else "*** FAIL -- OUTSIDE THE BAR ***")))
dom_bad <- which(dom$gap < 0 & abs(dom$gap) > RPP_DOM_TOL)
cat("            ", if (!length(dom_bad)) "PASS\n\n" else "FAIL\n\n")
if (length(dom_bad) && !identical(commandArgs(TRUE)[1], "mutate")) stop("GATE DOMINANCE failed")

cands <- do.call(rbind, lapply(RPP_SIG_GRID, function(s)
           do.call(rbind, lapply(RPP_MU_GRID, function(m) {
             z <- recon(m, s)
             data.frame(mu = m, sigma = s, rep_dC = z$rep_dC, boundary = z$boundary,
                        loglik = z$loglik, t(z$scal), check.names = FALSE) }))))
# the measured error bar on every fitted rep_dC below
spread_of <- function(mu, sg) {
  v <- vapply(RPP_INTERP, function(mk) {
    f <- mk(rr, rest); grid[which.max(f(grid) + dnorm(grid, mu, sg, log = TRUE)) ] }, 0)
  diff(range(v))
}
cands$rep_dC_bar <- mapply(spread_of, cands$mu, cands$sigma)

canon_ll <- llik[which.max(rr)]
cands$d_loglik <- cands$loglik - canon_ll

cat("== T4p: the fitted model under each CANDIDATE rep_dC prior ==\n")
cat("   (dloglik is against the canonical's -1391.8032; the LIKELIHOOD is prior-free\n")
cat("    and therefore the only quantity comparable ACROSS rows. A logpost is not.)\n\n")
cat(sprintf("%6s %6s %10s %8s %10s %9s %9s %9s %9s %8s %s\n",
    "mu", "sigma", "rep_dC", "+/-", "dloglik", "irf100", "land1000", "gateD_z", "gateGL_z", "af_all", "note"))
for (i in seq_len(nrow(cands))) with(cands[i, ], cat(sprintf(
  "%6.3f %6.2f %10.3f %8.3f %+10.2f %9.4f %9.2f %9.3f %9.3f %8.4f %s\n",
  mu, sigma, rep_dC, rep_dC_bar, d_loglik, irf100, part1000_land, gateD_z, gateGL_z, af_all,
  if (boundary) "⛔ AT A LADDER END -- NOT A NUMBER" else "")))

cat("\n== CHECKS (identities, never evidence of flatness) ==\n")
for (i in seq_len(nrow(cands))) with(cands[i, ], cat(sprintf(
  "   mu %6.3f sigma %4.2f : co2_pi %9.4f  part1000_close %8.5f\n", mu, sigma, co2_pi, part1000_close)))

saveRDS(list(cands = cands, dominance = dom, slope = slope, curv = curv, rungs = rr, rest = rest, loglik = llik, logpost = lpst,
             loo = lr, interp_sd = interp_sd, floor_lp = floor_lp,
             provenance = list(driver = "calibration/diag_rep_dc_prior_profile.R",
               reads = RPP_LADDER_DIR, ladder_commit = unique(vapply(lad, function(x) x$provenance$commit %||% "NA", "")),
               mode = lad[[1]]$provenance$mode, objective = lad[[1]]$provenance$objective,
               spinup = lad[[1]]$provenance$spinup,
               shipped_prior = sprintf("N(0, LIK_CO2_REP_ERR = %.3f)", LIK_CO2_REP_ERR),
               rng = "NONE -- this driver draws no random numbers",
               mu_grid = RPP_MU_GRID, sigma_grid = RPP_SIG_GRID, loo_k = RPP_LOO_K,
               units = "rep_dC ppm; partition %; loglik log-units",
               commit = tryCatch(system("git rev-parse --short HEAD", intern = TRUE), error = function(e) NA),
               tree_dirty = tryCatch(length(system("git status --porcelain", intern = TRUE)) > 0, error = function(e) NA),
               built = format(Sys.time()))), RPP_RDS)
cat(sprintf("\nsaved: %s\n", RPP_RDS))
