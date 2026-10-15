# =====================================================================
# diag_ocean_candidates.R -- SCORE CANDIDATES A AND B1 ON THE SAME FIVE ROWS
# AS THE PUMP.  (Marcus 2026-08-15, DESIGN.md sec.3.4a)
#
# THE POINT OF SCORING THEM TOGETHER. Four ocean structures have gone into this
# repo and come back out over three days, each argued on its own mechanism
# story. `diag_dic_gradient.R` showed why that does not converge: the pump
# PASSED all three of its pre-registered clauses while the channel it was
# argued on measured EXACTLY ZERO. A mechanism that passes on a channel nobody
# named is indistinguishable from a mechanism that is understood. So the
# candidates are scored on ONE fixed row set, and the rows are fixed here
# before any of them runs.
#
#   1. ocean sink -> ~3.1 GtC/yr                       (item 9 clause 2)
#   2. deep D14C -> -175.3 +/- 10.3 permil             (item 9 clause 3)
#   3. h_ml relaxes below ~163 m                       (item 9 clause 1)
#   4. preindustrial vertical DIC gradient -> +244.7 umol/kg   NOT IN OBJECTIVE
#   5. preindustrial vertical d13C gradient -> -0.938 permil   NOT IN OBJECTIVE
#
# ---------------------------------------------------------------------
# A PREDICTION ABOUT ROWS 4 AND 5, DERIVED BEFORE RUNNING AND WORTH MORE THAN
# THE SCAN.
#
# DIC and 13C are CONSERVED and have NO interior source or sink in this model.
# A steady state of any transport operator -- diffusive, advective, or both --
# therefore has a UNIFORM interior ratio, because a conserved tracer with no
# interior source has zero steady flux divergence everywhere. 14C is different
# ONLY because radioactive decay IS an interior sink, which is exactly why the
# model already has a D14C gradient (-51 -> -187) and exactly no DIC or d13C
# gradient (1986.3 uniform, +1.560 uniform).
#
#   ==> NEITHER CANDIDATE A NOR CANDIDATE B1 CAN MOVE ROWS 4 AND 5 AT ALL, AT
#       ANY PARAMETER VALUE. Not "does not much"; CANNOT, by conservation.
#       Only a mechanism with an interior source -- biology -- can.
#
# This is asserted numerically in part 0 rather than trusted, and if it fails
# the shim is wrong. It also means the five rows do NOT rank four
# interchangeable options: rows 1-3 are a transport question and rows 4-5 are a
# biology question, and the honest output of this file is a statement about
# which COMBINATION is needed, not a winner.
#
# ---------------------------------------------------------------------
# PRE-REGISTERED DECISION RULE, written before any scan ran:
#
#   * A or B1 reaches deep D14C |z| < 1 while holding the sink near 3.1 AND
#     relaxing h_ml  ->  the transport deficit is structural, not biological,
#     and it should be fixed with the cheap candidate BEFORE the pump.
#   * Neither does  ->  a single diffusive column with one extra knob is not
#     enough, and B2 (a separate high-latitude column, i.e. HILDA) becomes
#     INDICATED rather than merely available. Per Marcus 2026-08-15 that is
#     itself the result: complexity that is FORCED by observations is a
#     pedagogical finding, not a pedagogical cost.
#   * Rows 4-5 unmoved by both, as predicted  ->  the pump is not in
#     competition with A or B1 and the "pump vs refit" framing was wrong twice
#     over.
#
# THE ONE METHODOLOGICAL CHOICE, FLAGGED NOT RESOLVED. Candidate A needs a
# functional form for K(z), and the form is not given by the data. Taken:
#
#     K(z_interface) = kz * exp(-(z - h_ml) / z_K),  anchored f = 1 at the ML base
#
# WHY THIS ANCHOR. It leaves `kz` meaning the NEAR-SURFACE diffusivity, which is
# the thing Ledwell's NATRE tracer release actually measures ((1.7 +/- 0.2)e-5
# m2/s = 536 m2/yr at ~300 m). Under the current constant-K column `kz` = 5000
# is a whole-column effective value 9x NATRE and comparable to nothing measured.
# Under this form the 9x discrepancy becomes a TESTABLE claim about one number
# rather than an acknowledged fiction. z_K -> Inf recovers the shipped model
# exactly, and that is run as the control in every table.
# NOT TAKEN, and they would answer differently: a two-parameter form with an
# abyssal floor K_deep (the real abyss is NOT quiescent -- mixing near rough
# topography is large), and a power law. Neither is excluded by anything here.
#
# THE kz BRACKET IS SCANNED PAST ON PURPOSE, as diag_h_ml_roles.R part 4 did.
# CCX_PARAM_TABLE bounds kz to [3830, 6200] to stop deep D14C running away.
# Candidate A DISSOLVES THAT BRACKET'S RATIONALE -- with K falling with depth,
# a large near-surface kz no longer implies a ventilated abyss, so the parameter
# no longer controls the observable the bound was protecting. Bounding the
# observable rather than the parameter is the standing lesson here. If A wins,
# the bracket must be re-derived, NOT carried over.
#
# WHAT IS AND IS NOT BUILT. Candidate B1 needs NO new code at all --
# `w_out_NH`/`w_out_SH` are real parameters, implemented in BOTH R/model.R and
# src/ccx_core.cpp, defaulting to 0. It is scanned through the FAST C++ path.
# Candidate A is a shim over ccx_deriv() in this file's environment, gated by a
# no-op mutation test, and must use the R integrator (~32 s/run).
# Part 0 gates that the two paths are commensurable before anything is compared.
#
# RUNTIME ~40 min (the iso-sink root-finds dominate; each is ~8 R runs).
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

# ---- named constants ------------------------------------------------
OC_YEARS     <- c(1750, 2024)
OC_BOMB_REF  <- 102
OC_H_REF     <- 75
OC_H_GRID    <- c(50, 75, 100, 140, 184, 220)
OC_SINK_WIN  <- c(2010, 2019)
OC_MODE_PATH <- ccx_path("calibration", "output", "quarantine",
                         "20260815_pre_gradient_terms", "mode_fit.rds")
OC_PUMP_RDS  <- ccx_path("calibration", "output", "dic_gradient",
                         "diag_dic_gradient.rds")
OC_NATRE     <- 536          # m2/yr, Ledwell NATRE; redteam 2026-08-13 sec.1
OC_N_EFF     <- 20           # the deep-D14C target's convention, reused
# Candidate A's grid. z_K = Inf IS the shipped constant-K model and is the
# control column of every table below.
OC_ZK_GRID   <- c(Inf, 5000, 3000, 2000, 1200)           # m
OC_KZ_GRID   <- c(5000, 8000, 12000)                     # m2/yr
OC_KZ_RANGE  <- c(2500, 20000)                           # m2/yr, iso-sink search
# Candidate B1's grid. Dense because it is free -- it runs through the C++ core.
OC_WOUT_GRID <- c(0, 0.5, 1, 2, 3, 5, 8, 12, 20)         # m/yr
OC_WOUT_ALLOC <- c("SH only", "NH only", "both")
# SH-only is the physically motivated allocation (the outcrop is a Southern
# Ocean feature) AND a testable claim about the MLO-SPO gradient the likelihood
# already scores. The other two are run so the claim is visible as a choice.
OC_ERR_MODE  <- list(sigma_d13c = 0.44, sigma_d14c = 5,
                     grad_off_co2 = -0.549, grad_off_d13c = +0.107)
OC_OUTDIR    <- ccx_path("calibration", "output", "ocean_candidates")

dir.create(OC_OUTDIR, recursive = TRUE, showWarnings = FALSE)
sep <- function(s) cat(sprintf("\n\n=== %s ===\n", s))

obs      <- ccx_prepare_obs()
base_forc <- ccx_build_forcing("historical", OC_YEARS, prod_c14 = 0,
                               bomb_total_kmol = OC_BOMB_REF)
tg_d14 <- ccx_deep_d14c_target()

# GLODAP rows 4 and 5, on the model's own layers, from the pump diagnostic's
# saved profile so the two files cannot disagree about the observation.
if (!file.exists(OC_PUMP_RDS))
  stop("run calibration/diag_dic_gradient.R first -- this file scores against its rows")
pumpres <- readRDS(OC_PUMP_RDS)
op      <- pumpres$obsprof
OC_DIC_GRAD_OBS <- op$dic[nrow(op)] - op$dic[1]
OC_D13_GRAD_OBS <- op$d13[nrow(op)] - op$d13[1]

# =====================================================================
# THE CANDIDATE-A SHIM
# =====================================================================
# Implemented as a CORRECTION to the shipped constant-K diffusion rather than a
# replacement for it, so the base operator is never re-derived:
#   base uses  F_k = kz          (c_a - c_b) / dz_mid_k
#   we want    F_k = kz * f_k    (c_a - c_b) / dz_mid_k
#   so add     dF  = kz (f_k - 1)(c_a - c_b) / dz_mid_k, antisymmetric per tracer.
# f = 1 everywhere is therefore a BIT-EXACT no-op, which is the mutation gate.
.oc <- new.env(parent = emptyenv())
.oc$on <- FALSE; .oc$f <- NULL

.oc_deriv_base <- ccx_deriv
ccx_deriv <- function(y, t, p, forc, grid, aux, record = FALSE) {
  dy <- .oc_deriv_base(y, t, p, forc, grid, aux, record = record)
  if (!.oc$on) return(dy)
  if (record) stop("K_z(z) shim: the flux tap does not see the correction")
  fk <- .oc$f
  for (h in HEMIS) {
    col <- c(aux$idx[[h]]$ml, aux$idx[[h]]$oc)
    for (k in seq_len(grid$nl)) {
      if (fk[k] == 1) next
      a <- col[k]; b <- col[k + 1]
      for (tr in CCX_TRACERS) {
        dF <- p$kz * (fk[k] - 1) *
          (y[a, tr] / grid$dz[k] - y[b, tr] / grid$dz[k + 1]) / aux$dz_mid[k]
        dy[a, tr] <- dy[a, tr] - dF
        dy[b, tr] <- dy[b, tr] + dF
      }
    }
  }
  dy
}

#' The K(z) shape on a given grid. f[1] == 1 by construction (the ML interface).
oc_shape <- function(grid, z_K) {
  z <- cumsum(grid$dz)[seq_len(grid$nl)]     # interface depths, m
  if (!is.finite(z_K)) rep(1, grid$nl) else exp(-(z - grid$h_ml) / z_K)
}

#' MUTATION GATE: f == 1 must be bit-exact, and a perturbed f must NOT be.
oc_shim_gate <- function() {
  p <- ccx_default_params(); aux <- ccx_prepare(p); grid <- aux$grid
  y <- ccx_spinup(p)$y
  # A REAL forcing slice, not a hand-built list: `ccx_deriv` needs `d13c_foss`,
  # which only ccx_build_forcing() supplies, and a fake list fails loudly rather
  # than silently running a different model. Index 3000 is ~1999, i.e. a month
  # with large emissions, so the gate is exercised on a live derivative.
  ig <- 3000L; fc <- ccx_forcing_at(base_forc, ig); tg <- base_forc$t[ig]
  .oc$on <- FALSE; d0 <- ccx_deriv(y, tg, p, fc, grid, aux)
  .oc$on <- TRUE; .oc$f <- rep(1, grid$nl); d1 <- ccx_deriv(y, tg, p, fc, grid, aux)
  .oc$f <- oc_shape(grid, 1500);            d2 <- ccx_deriv(y, tg, p, fc, grid, aux)
  .oc$on <- FALSE
  cat(sprintf("\nSHIM GATE  f == 1 no-op      max|d| = %.3e   %s\n",
              max(abs(d1 - d0)), if (max(abs(d1 - d0)) == 0) "PASS (bit-exact)" else "FAIL"))
  cat(sprintf("           f = exp(-z/1500)  max|d| = %.3e   %s\n",
              max(abs(d2 - d0)),
              if (max(abs(d2 - d0)) > 1e-6) "PASS (the shim does something)" else "FAIL"))
  if (max(abs(d1 - d0)) != 0 || max(abs(d2 - d0)) <= 1e-6)
    stop("K_z(z) shim failed its mutation gate")
  invisible(TRUE)
}

# =====================================================================
# EVALUATION
# =====================================================================
#' Score one configuration. `engine` = "cpp" (fast, no shim) or "R" (shim-aware).
oc_eval <- function(p, bomb_total, luc_scale, err, z_K = Inf, engine = "cpp") {
  aux <- ccx_prepare(p); grid <- aux$grid
  if (is.finite(z_K)) { .oc$f <- oc_shape(grid, z_K); .oc$on <- TRUE }
  sp <- tryCatch(ccx_spinup(p), error = function(e) NULL)
  if (is.null(sp)) { .oc$on <- FALSE; return(NULL) }
  F <- base_forc
  F$c14_cosmo <- sp$prod_c14
  F$c14_bomb  <- base_forc$c14_bomb * (bomb_total / OC_BOMB_REF)
  for (cc in c("e_luc_NH", "e_luc_SH", "cum_luc_NH", "cum_luc_SH"))
    F[[cc]] <- base_forc[[cc]] * luc_scale
  attr(F, "luc_scale") <- luc_scale
  eluc <- ccx_forcing_eluc_annual(base_forc); eluc$eluc <- eluc$eluc * luc_scale
  r <- tryCatch(if (engine == "cpp") ccx_run_fast(sp, F) else ccx_run(sp, F),
                error = function(e) NULL)
  .oc$on <- FALSE
  if (is.null(r) || anyNA(r$out$co2_NH)) return(NULL)
  ps  <- ccx_loglik(r$out, obs, err, luc = eluc,
                    deep = sp$diagnostics$d14c_bottom_box, by_stream = TRUE)
  yr  <- floor(r$out$t + 1e-9); ann <- tapply(r$out$ocean_C, yr, mean)
  yy  <- as.integer(names(ann))
  k   <- which(yy >= OC_SINK_WIN[1] & yy <= OC_SINK_WIN[2])
  # ROWS 4 AND 5, measured not assumed: the interior gradient in the
  # PREINDUSTRIAL state, top interior box to bottom interior box.
  i1  <- aux$idx$NH$oc[1]; iN <- tail(aux$idx$NH$oc, 1)
  kap <- aux$a_oc$NH * ccx_const("RHO_SEAWATER") / aux$mol_per_GtC
  dic <- function(i, k) sp$y[i, "C"] / grid$dz[k] / kap * 1e6
  d13 <- function(i) 1000 * (sp$y[i, "C13"] /
                               (sp$y[i, "C"] * ccx_const("R13_VPDB")) - 1)
  list(total = sum(ps), parts = ps,
       sink = if (length(k) > 1) mean(diff(ann[k])) else NA_real_,
       deep = sp$diagnostics$d14c_bottom_box,
       z14  = (sp$diagnostics$d14c_bottom_box - tg_d14$target) / tg_d14$sd,
       dic_grad = dic(iN, grid$nl + 1) - dic(i1, 2),
       d13_grad = d13(iN) - d13(i1),
       ocean = sp$diagnostics$ocean_C_GtC,
       resid = sp$diagnostics$max_abs_dCdt)
}

#' The export a pump would need to hold the observed DIC gradient against this
#' column's diffusion, GtC/yr. ANALYTIC: the per-box sources telescope, so the
#' total is just the diffusive flux across the TOP interface at the target
#' profile. Depends on kz AND on h_ml (through dz_mid[1]), which is why it is
#' reported as a surface in part 3 rather than as one number.
oc_export <- function(p, aux, grid, z_K) {
  fk <- oc_shape(grid, z_K)
  dg <- op$dic - op$dic[1]
  sum(vapply(HEMIS, function(h) {
    kap <- aux$a_oc[[h]] * ccx_const("RHO_SEAWATER") / aux$mol_per_GtC
    dml <- ccx_dic_for_pco2(ccx_const("CO2_PI_PPM"), ccx_const("ALK_SURFACE"),
                            aux$sst[[h]]) * 1e6
    cc  <- kap * (dml + dg) * 1e-6
    p$kz * fk[1] * (cc[1] - cc[2]) / aux$dz_mid[1] * -1
  }, numeric(1)))
}

sep("PART 0. GATES -- the shim, the two engines, and the rows-4-and-5 prediction")
oc_shim_gate()

pm <- if (file.exists(OC_MODE_PATH)) readRDS(OC_MODE_PATH)$par_mode else NULL
if (is.null(pm)) stop("quarantined mode absent -- this file scores at the mode")
pmode <- ccx_default_params()
for (n in intersect(names(pmode), names(pm))) pmode[[n]] <- pm[[n]]
pmode <- ccx_set_enso(pmode, pm)
pmode$h_ml <- 184                       # the pre-gradient MAP mode's own value
auxm <- ccx_prepare(pmode); gm <- auxm$grid

# COMMENSURABILITY GATE. Candidate B1 is scored through the C++ core and
# candidate A through the R reference integrator. The two tables are only
# comparable if the engines agree, so measure it rather than cite test-parity.R.
refC <- oc_eval(pmode, pm$bomb_total, pm$luc_scale, OC_ERR_MODE, engine = "cpp")
refR <- oc_eval(pmode, pm$bomb_total, pm$luc_scale, OC_ERR_MODE, engine = "R")
cat(sprintf("\nENGINE GATE  logL  cpp %.4f   R %.4f   |d| = %.2e\n",
            refC$total, refR$total, abs(refC$total - refR$total)))
cat(sprintf("             sink  cpp %.6f   R %.6f   |d| = %.2e\n",
            refC$sink, refR$sink, abs(refC$sink - refR$sink)))
if (abs(refC$total - refR$total) > 1e-3)
  stop("cpp and R disagree -- the A and B1 tables would not be commensurable")
cat("             PASS -- the two candidate tables can be read against each other.\n")

cat(sprintf("\nREFERENCE (mode parameters, h_ml = %g, no candidate):\n", pmode$h_ml))
cat(sprintf("  sink %.3f | deep D14C %.1f (z %+.2f) | DIC grad %+.1f | d13C grad %+.3f | logL %.1f\n",
            refC$sink, refC$deep, refC$z14, refC$dic_grad, refC$d13_grad, refC$total))
cat(sprintf("  observed:                              DIC grad %+.1f | d13C grad %+.3f\n",
            OC_DIC_GRAD_OBS, OC_D13_GRAD_OBS))

# =====================================================================
# PART 1. CANDIDATE B1 -- THE OUTCROP. Already built; C++ path; free.
# =====================================================================
sep("PART 1. CANDIDATE B1 -- OUTCROP (w_out_NH / w_out_SH, ALREADY BUILT)")
cat("No new code. These are real parameters in R/model.R AND src/ccx_core.cpp,\n")
cat("defaulting to 0 and bit-reproducing the pure-diffusion model there.\n")
cat("Scored at the mode's other parameters, h_ml = 184.\n\n")
cat(sprintf("%-8s", "w_out"))
for (a in OC_WOUT_ALLOC) cat(sprintf(" %22s", a))
cat("\n")
cat(sprintf("%-8s", "m/yr"))
for (a in OC_WOUT_ALLOC) cat(sprintf(" %10s %5s %5s", "logL", "z14", "sink"))
cat("\n")
b1 <- list()
for (w in OC_WOUT_GRID) {
  cat(sprintf("%-8g", w))
  for (a in OC_WOUT_ALLOC) {
    p <- pmode
    p$w_out_NH <- if (a %in% c("NH only", "both")) w else 0
    p$w_out_SH <- if (a %in% c("SH only", "both")) w else 0
    e <- oc_eval(p, pm$bomb_total, pm$luc_scale, OC_ERR_MODE)
    b1[[paste(a, w)]] <- e
    if (is.null(e)) cat(sprintf(" %10s %5s %5s", "NA", "", "")) else
      cat(sprintf(" %10.1f %+5.2f %5.3f", e$total, e$z14, e$sink))
  }
  cat("\n")
}
b1ok  <- b1[!vapply(b1, is.null, logical(1))]
b1best <- names(b1ok)[which.max(vapply(b1ok, function(e) e$total, numeric(1)))]
cat(sprintf("\nbest B1 configuration: %s   logL %.1f (reference %.1f, %+.1f)\n",
            b1best, b1ok[[b1best]]$total, refC$total,
            b1ok[[b1best]]$total - refC$total))
cat(sprintf("  deep D14C z %+.2f (reference %+.2f) | sink %.3f | DIC grad %+.1f | d13C grad %+.3f\n",
            b1ok[[b1best]]$z14, refC$z14, b1ok[[b1best]]$sink,
            b1ok[[b1best]]$dic_grad, b1ok[[b1best]]$d13_grad))

# h_ml profile at the best B1 setting -- clause 1
cat("\nCLAUSE 1: does h_ml relax? (best B1 setting vs w_out = 0)\n")
wbest <- as.numeric(sub("^.* ", "", b1best)); abest <- sub(" [^ ]+$", "", b1best)
cat(sprintf("%-14s", "arm"))
for (h in OC_H_GRID) cat(sprintf(" %9s", sprintf("h=%g", h)))
cat("   best h\n")
b1prof <- list()
for (arm in list(list(id = "w_out = 0", w = 0), list(id = b1best, w = wbest))) {
  v <- vapply(OC_H_GRID, function(h) {
    p <- pmode; p$h_ml <- h
    p$w_out_NH <- if (arm$w > 0 && abest %in% c("NH only", "both")) arm$w else 0
    p$w_out_SH <- if (arm$w > 0 && abest %in% c("SH only", "both")) arm$w else 0
    e <- oc_eval(p, pm$bomb_total, pm$luc_scale, OC_ERR_MODE)
    if (is.null(e)) c(NA_real_, NA_real_, NA_real_) else c(e$total, e$z14, e$sink)
  }, numeric(3))
  b1prof[[arm$id]] <- v
  cat(sprintf("%-14s", arm$id))
  for (j in seq_len(ncol(v))) cat(sprintf(" %9.1f", v[1, j]))
  cat(sprintf("   %g m\n", OC_H_GRID[which.max(v[1, ])]))
}

# =====================================================================
# PART 2. CANDIDATE A -- DEPTH-DEPENDENT K_z. Shim; R integrator; ~32 s/run.
# =====================================================================
sep("PART 2. CANDIDATE A -- K(z) = kz exp(-(z - h_ml)/z_K)")
cat("z_K = Inf is the SHIPPED constant-K model and is the control column.\n")
cat(sprintf("kz runs PAST its bracket [%g, %g] on purpose -- see the header on why\n",
            CCX_PARAM_TABLE$kz$lo, CCX_PARAM_TABLE$kz$hi))
cat("candidate A dissolves the bracket's rationale rather than violating it.\n\n")
gsh <- ccx_ocean_grid(pmode$h_ml)
cat("the shape, at h_ml = 184 (K/kz at each interface):\n")
cat(sprintf("%8s", "z_K"))
for (z in cumsum(gsh$dz)[seq_len(gsh$nl)]) cat(sprintf(" %7.0f", z))
cat("\n")
for (zk in OC_ZK_GRID) {
  cat(sprintf("%8s", if (is.finite(zk)) sprintf("%g", zk) else "Inf"))
  for (v in oc_shape(gsh, zk)) cat(sprintf(" %7.3f", v))
  cat("\n")
}
cat("\n")
cat(sprintf("%8s %8s", "kz", "z_K"))
cat(sprintf(" %10s %7s %8s %9s %9s\n", "logL", "z14", "sink", "DIC grad", "d13 grad"))
a_res <- list()
for (kzv in OC_KZ_GRID) for (zk in OC_ZK_GRID) {
  p <- pmode; p$kz <- kzv
  e <- oc_eval(p, pm$bomb_total, pm$luc_scale, OC_ERR_MODE, z_K = zk, engine = "R")
  a_res[[sprintf("kz%g_zK%s", kzv, zk)]] <- c(list(kz = kzv, z_K = zk), e)
  cat(sprintf("%8g %8s", kzv, if (is.finite(zk)) sprintf("%g", zk) else "Inf"))
  if (is.null(e)) cat("        NA\n") else
    cat(sprintf(" %10.1f %+7.2f %8.3f %9.1f %9.3f\n",
                e$total, e$z14, e$sink, e$dic_grad, e$d13_grad))
}
aok  <- a_res[!vapply(a_res, function(e) is.null(e$total), logical(1))]

# ---------------------------------------------------------------------
# PART 2b. THE ISO-SINK SLICE -- THE ONLY FAIR COMPARISON, AND THE DECISIVE ONE
# ---------------------------------------------------------------------
# THE GRID ABOVE CANNOT BE READ AS "A LOSES", and the reason is a defect in it,
# not a result. The REFERENCE sits at kz = 6119.2, which is its OWN FITTED
# OPTIMUM, and every row above sits at a coarse grid point that is not. The
# z_K = Inf column measures exactly how big that penalty is: the SAME model at
# kz 5000 scores -2579.4 against the reference's -2269.7 -- a 309 log-unit gap
# from a 22 % change in one parameter. Any comparison that lets the incumbent be
# optimized and the challenger not is rigged, and by roughly that much.
#
# The fix is not a full 19-parameter refit per z_K (that is ~5.4 h each). It is
# to ask the question candidate A was actually proposed to answer:
#
#   AT MATCHED OCEAN SINK, does K(z) buy a better deep D14C than constant K?
#
# That is the decoupling claim in one line. Solve kz(z_K) such that the sink
# equals the reference's, then read off deep D14C and logL. Monotone in kz, so
# uniroot on log kz converges in ~8 evaluations.
oc_iso_kz <- function(z_K, target_sink, h = pmode$h_ml) {
  f <- function(lk) {
    p <- pmode; p$kz <- exp(lk); p$h_ml <- h
    e <- oc_eval(p, pm$bomb_total, pm$luc_scale, OC_ERR_MODE, z_K = z_K,
                 engine = "R")
    if (is.null(e)) NA_real_ else e$sink - target_sink
  }
  r <- tryCatch(uniroot(f, log(OC_KZ_RANGE), tol = 1e-3), error = function(e) NULL)
  if (is.null(r)) return(NULL)
  p <- pmode; p$kz <- exp(r$root); p$h_ml <- h
  c(list(kz = exp(r$root)),
    oc_eval(p, pm$bomb_total, pm$luc_scale, OC_ERR_MODE, z_K = z_K, engine = "R"))
}

sep("PART 2b. ISO-SINK: does K(z) buy deep D14C at a matched ocean sink?")
cat(sprintf("kz is solved so every row has the reference's sink, %.3f GtC/yr.\n",
            refC$sink))
cat("z_K = Inf is the incumbent and MUST return kz = 6119.2 and z14 = +1.70 --\n")
cat("that row is a self-check on the root-find, not a result.\n\n")
cat(sprintf("%9s %10s %8s %10s %11s %12s\n", "z_K", "kz solved", "z14", "logL",
            "d logL", "export GtC/yr"))
iso <- list()
for (zk in OC_ZK_GRID) {
  e <- oc_iso_kz(zk, refC$sink)
  iso[[format(zk)]] <- e
  if (is.null(e)) { cat(sprintf("%9s %10s\n", format(zk), "no root")); next }
  p <- pmode; p$kz <- e$kz
  cat(sprintf("%9s %10.0f %+8.2f %10.1f %+11.1f %12.1f\n", format(zk), e$kz,
              e$z14, e$total, e$total - refC$total, oc_export(p, auxm, gm, zk)))
}
isook <- iso[!vapply(iso, is.null, logical(1))]
# CANDIDATE A IS THE FINITE-z_K ROWS ONLY. z_K = Inf is the shipped model, and
# scoring it as a candidate is how the first version of this file's decision
# rule managed to "pass" on the incumbent.
isoA  <- isook[names(isook) != "Inf"]
abz   <- names(isoA)[which.min(abs(vapply(isoA, function(e) e$z14, numeric(1))))]
abst  <- names(isoA)[which.max(vapply(isoA, function(e) e$total, numeric(1)))]
cat(sprintf("\nbest A for CLAUSE 3 at matched sink: z_K = %s, kz = %.0f -> z14 %+.2f (incumbent %+.2f)\n",
            abz, isoA[[abz]]$kz, isoA[[abz]]$z14, refC$z14))
cat(sprintf("best A for logL     at matched sink: z_K = %s, kz = %.0f -> logL %.1f (%+.1f)\n",
            abst, isoA[[abst]]$kz, isoA[[abst]]$total, isoA[[abst]]$total - refC$total))
cat("\nCAVEAT, and it bounds every conclusion below: this re-optimises TWO of 19\n")
cat("parameters (kz here, h_ml next). `k_w`, `bomb_total` and the land are still\n")
cat("at values fitted for a constant-K column. A full refit can still move this.\n")

cat("\nCLAUSE 1: does h_ml relax? (best-clause-3 iso-sink A vs the incumbent)\n")
cat(sprintf("%-22s", "arm"))
for (h in OC_H_GRID) cat(sprintf(" %9s", sprintf("h=%g", h)))
cat("   best h\n")
aprof <- list()
for (arm in list(list(id = "constant K (control)", kz = pmode$kz, zk = Inf),
                 list(id = sprintf("A kz%.0f zK%s", isoA[[abz]]$kz, abz),
                      kz = isoA[[abz]]$kz, zk = as.numeric(abz)))) {
  v <- vapply(OC_H_GRID, function(h) {
    p <- pmode; p$h_ml <- h; p$kz <- arm$kz
    e <- oc_eval(p, pm$bomb_total, pm$luc_scale, OC_ERR_MODE, z_K = arm$zk,
                 engine = "R")
    if (is.null(e)) c(NA_real_, NA_real_, NA_real_) else c(e$total, e$z14, e$sink)
  }, numeric(3))
  aprof[[arm$id]] <- v
  cat(sprintf("%-22s", arm$id))
  for (j in seq_len(ncol(v))) cat(sprintf(" %9.1f", v[1, j]))
  cat(sprintf("   %g m\n", OC_H_GRID[which.max(v[1, ])]))
}

# =====================================================================
# PART 3. DOES A LET THE PUMP BE BUILT AT A DEFENSIBLE EXPORT? (analytic)
# =====================================================================
# diag_dic_gradient.R found the export needed to hold the observed DIC gradient
# is 22.0 GtC/yr = 2.6x literature, because the export is set by how fast
# diffusion destroys the gradient. Under K(z) the deep interfaces destroy it far
# more slowly, so the required export should fall. This needs NO run: the export
# is the diffusive flux across the top interface evaluated on the target profile,
# and the sum telescopes.
sep("PART 3. THE PUMP'S IMPLIED EXPORT UNDER CANDIDATE A (analytic, no runs)")
cat(sprintf("literature global POC export 5-12 GtC/yr; NATRE %g m2/yr\n\n", OC_NATRE))
cat(sprintf("%8s", "kz"))
for (zk in OC_ZK_GRID) cat(sprintf(" %11s", if (is.finite(zk)) sprintf("z_K %g", zk) else "z_K Inf"))
cat("\n")
for (kzv in OC_KZ_GRID) {
  p <- pmode; p$kz <- kzv
  cat(sprintf("%8g", kzv))
  for (zk in OC_ZK_GRID) cat(sprintf(" %11.1f", oc_export(p, auxm, gm, zk)))
  cat("\n")
}
cat("\nNOTE, and it is the reason this table is small print: the export is set by\n")
cat("the TOP interface, where the shape is anchored at f = 1. So K(z) as\n")
cat("parameterised here does NOT reduce the required export at fixed kz -- it\n")
cat("only does so by letting kz itself be smaller. Read the kz axis, not the\n")
cat("z_K axis. If the best A configuration wants a LARGER kz, candidate A makes\n")
cat("the pump's export problem WORSE, not better, and the two are then in\n")
cat("tension rather than complementary -- which would correct DESIGN sec.3.4a.\n")

# =====================================================================
# PART 4. THE FIVE ROWS, ALL FOUR CANDIDATES
# =====================================================================
sep("PART 4. THE FIVE-ROW COMPARISON")
pumpon  <- pumpres$arms$hml[["pump D  "]]
pumpoff <- pumpres$arms$hml[["pump OFF"]]
jP <- which.max(pumpon[1, ])
cat(sprintf("%-26s %9s %8s %8s %9s %10s %9s\n", "candidate", "logL", "sink",
            "z14", "best h", "DIC grad", "d13 grad"))
cat(sprintf("%-26s %9.1f %8.3f %+8.2f %9g %10.1f %9.3f\n", "reference (none)",
            refC$total, refC$sink, refC$z14, 184, refC$dic_grad, refC$d13_grad))
cat(sprintf("%-26s %9.1f %8.3f %+8.2f %9g %10.1f %9.3f\n",
            sprintf("A  z_K %s (iso-sink)", abz), isoA[[abz]]$total,
            isoA[[abz]]$sink, isoA[[abz]]$z14,
            OC_H_GRID[which.max(aprof[[2]][1, ])],
            isoA[[abz]]$dic_grad, isoA[[abz]]$d13_grad))
cat(sprintf("%-26s %9.1f %8.3f %+8.2f %9g %10.1f %9.3f\n",
            sprintf("B1 %s", b1best), b1ok[[b1best]]$total, b1ok[[b1best]]$sink,
            b1ok[[b1best]]$z14, OC_H_GRID[which.max(b1prof[[2]][1, ])],
            b1ok[[b1best]]$dic_grad, b1ok[[b1best]]$d13_grad))
cat(sprintf("%-26s %9.1f %8.3f %+8.2f %9g %10.1f %9.3f\n", "C  pump (DIC-limited)",
            pumpon[1, jP], pumpon[3, jP],
            (pumpon[2, jP] - tg_d14$target) / tg_d14$sd, OC_H_GRID[jP],
            2241 - 1986.3, -0.628 - 1.560))
cat(sprintf("%-26s %9s %8.1f %8s %9s %10.1f %9.3f\n", "OBSERVED", "", 3.1, "0.00",
            "50-75", OC_DIC_GRAD_OBS, OC_D13_GRAD_OBS))

cat("\n--- the rows-4-and-5 prediction, scored ---\n")
mv <- max(abs(c(isoA[[abz]]$dic_grad, b1ok[[b1best]]$dic_grad)))
m5 <- max(abs(c(isoA[[abz]]$d13_grad, b1ok[[b1best]]$d13_grad)))
cat(sprintf("A and B1 move the DIC gradient by at most %.2e umol/kg and the\n", mv))
cat(sprintf("d13C gradient by at most %.2e permil. Predicted: EXACTLY ZERO, by\n", m5))
cat("conservation -- neither tracer has an interior source, so any steady state\n")
cat("of any transport operator is uniform in ratio.\n")
cat(sprintf("VERDICT: %s\n", if (mv < 1e-6 && m5 < 1e-9)
  "CONFIRMED. Transport CANNOT produce the observed interior gradients."
  else "NOT CONFIRMED -- a transport candidate moved a conserved-tracer gradient. Debug."))

sep("PART 5. THE DECISION RULE, SCORED")
# THIS BLOCK HAS BEEN WRONG TWICE AND BOTH FAILURES ARE WORTH KEEPING IN VIEW.
#   v1 read the z_K = Inf CONTROL as if it were candidate A, so it "passed" on
#      the incumbent, and it never checked clause 2 at all.
#   v2 indexed the iso-sink winner out of the WRONG LIST (`aok`, the coarse
#      grid, keyed "kz8000_zK3000") with an iso-sink key ("5000"). R returns
#      NULL for a missing name, abs(NULL$z14) is numeric(0), and min() silently
#      dropped it -- so the rule scored B1 alone and fired the OPPOSITE way.
# A zero-length vector vanishing inside min() is the failure mode to watch for:
# it does not error, it just quietly removes a candidate from the comparison.
# Hence the explicit length assertions below.
a_best  <- isoA[[abz]]
stopifnot(!is.null(a_best), length(a_best$z14) == 1L,
          length(b1ok[[b1best]]$z14) == 1L)
zA <- abs(a_best$z14); zB <- abs(b1ok[[b1best]]$z14)
cat(sprintf("candidate A  best |z| at matched sink: %.2f  (z_K = %s, kz = %.0f, d logL %+.1f)\n",
            zA, abz, a_best$kz, a_best$total - refC$total))
cat(sprintf("candidate B1 best |z|:                 %.2f  (%s, d logL %+.1f)\n",
            zB, b1best, b1ok[[b1best]]$total - refC$total))
cat(sprintf("incumbent    |z|:                      %.2f\n", abs(refC$z14)))
bestz <- min(zA, zB)
if (bestz < 1) {
  cat("\nRULE FIRES: a one-knob transport fix reaches |z| < 1 AT MATCHED SINK.\n")
  cat("The deep-D14C deficit is STRUCTURAL -- a single diffusive column with a\n")
  cat("depth-DEPENDENT K reaches the target that the same column with a constant\n")
  cat("K cannot. B2 is NOT indicated by this result.\n")
  cat("BUT READ CLAUSE 1 BEFORE CONCLUDING: the h_ml profile above is what says\n")
  cat("whether the winner also supplies what h_ml = 184 m is faking, and a\n")
  cat("candidate that fixes clause 3 while leaving clause 1 untouched has solved\n")
  cat("one of the two things the ocean structure is wanted for, not both.\n")
  cat("AND NOTE HOW LITTLE THE OBJECTIVE CARES: over the iso-sink rows the logL\n")
  cat("spread from z_K Inf to z_K 3000 is ~2 units while deep D14C moves ~3.5\n")
  cat("sigma. That is the deep-D14C term's sigma (10.3 permil at n_eff = 20)\n")
  cat("doing exactly what it should -- a 1.9 sigma gain IS only ~1.4 log-units --\n")
  cat("but it means z_K would be WEAKLY IDENTIFIED in a refit, and how weakly is\n")
  cat("set by the GLODAP n_eff choice that build_glodap_deep_targets.R flagged as\n")
  cat("UNRESOLVED. Adopting A puts weight on that unresolved choice.\n")
} else {
  cat("RULE FIRES THE OTHER WAY: no one-knob change to a SINGLE diffusive column\n")
  cat("reaches |z| < 1 while holding the sink. Per the header, B2 -- a separate\n")
  cat("high-latitude column (HILDA) -- is now INDICATED rather than merely\n")
  cat("available, and per Marcus 2026-08-15 the forced complexity is itself the\n")
  cat("pedagogical result: this is how much structure observed reality requires.\n")
}
cat("\nAND INDEPENDENT OF WHICH: rows 4 and 5 are untouchable by transport, so the\n")
cat("pump is NOT in competition with A, B1 or B2. The question was never which\n")
cat("candidate; it is which COMBINATION, and the objective cannot currently see\n")
cat("two of the five rows at all.\n")

saveRDS(list(reference = refC, b1 = b1, b1prof = b1prof, a = a_res,
             iso = iso, aprof = aprof,
             rows_obs = c(dic = OC_DIC_GRAD_OBS, d13 = OC_D13_GRAD_OBS)),
        file.path(OC_OUTDIR, "diag_ocean_candidates.rds"))
cat(sprintf("\n\nwritten: %s\n", file.path(OC_OUTDIR, "diag_ocean_candidates.rds")))
