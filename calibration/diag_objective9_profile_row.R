# =====================================================================
# diag_objective9_profile_row.R -- THE MUTATION GATE FOR OBJECTIVE CHANGE #9
# (2026-09-06; prereg_2026-09-07 sec.2: "the bottom-attached arm must lose
# >= 9 log-units on the row relative to the independent form").
#
# Scores the interior profile (A, B, deep) of each structural arm of the
# 09-06 arc under (i) the three independent rows as shipped and (ii) the one
# MVN row with the measured covariance at both block sizes. The arms are
# REBUILT and their one solved number RE-SOLVED here (uniform kz for the
# columns / bottom conduit; the deep floor f for the K(z) arms), so nothing
# is typed from a log. Steady state only: the row scores the spinup.
#
# Usage:  Rscript calibration/diag_objective9_profile_row.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()
source(ccx_path("calibration", "lib_design_gates.R"))
O9_HS_FRAC <- 0.16; O9_U_HS <- 38; O9_TAU_Q <- 538; O9_SST_HS <- 2; O9_ZK <- 253
O9_HS_ASX_ARM <- 0.8            # the 09-06c sec.7 arm
O9_F_BOTTOM_ARM <- 0.166        # 09-06b's K(z)+bottom arm solved f (re-solved below; the label only)
O9_GATE_LOSS <- 9               # the prereg's mutation number
O9_F_LO <- 1e-3; O9_F_GRID <- 16
O9_OUT <- ccx_path("outputs", "diagnostics", "objective9_profile_row_20260906.rds")

v0 <- dg_vector(CCX_MODE_CANONICAL)
tgm <- ccx_mid_d14c_target(); tgd <- ccx_deep_d14c_target(); D_OBS <- tgd$target
PC <- lapply(c("30", "60"), function(b) ccx_profile_d14c_cov(as.integer(b))); names(PC) <- c("30", "60")
if (any(vapply(PC, is.null, TRUE))) stop("profile covariance build product absent -- run data-raw/build_glodap_profile_covariance.R")
mu <- c(tgm$slabs$target, tgd$target); sd_ind <- c(tgm$slabs$sd, tgd$sd)
NL <- ccx_ocean_grid(v0$p$h_ml)$nl
cat(sprintf("\n=== OBJECTIVE #9 MUTATION -- mode %s ===\n  targets A %.1f B %.1f deep %.1f; independent sd %.1f / %.1f / %.1f; contrast se(B-deep) %.2f (30) %.2f (60)\n",
            CCX_MODE_CANONICAL, mu[1], mu[2], mu[3], sd_ind[1], sd_ind[2], sd_ind[3], PC[["30"]]$se[["BD"]], PC[["60"]]$se[["BD"]]))

deep_of <- function(p) ccx_spinup(p)$diagnostics$d14c_bottom_box
par_q <- function(attach, hs_asx = 1) { p <- v0$p
  p$hs_frac <- O9_HS_FRAC; p$u_hs <- O9_U_HS; p$tau_q <- O9_TAU_Q; p$sst_hs <- O9_SST_HS
  p$q_attach_from <- attach; p$hs_asx_frac <- hs_asx; p }
par_col <- function() { p <- v0$p; p$hs_frac <- 0; p }
solve_kz <- function(p, kz0) { g <- function(lk) { q <- p; q$kz <- exp(lk); deep_of(q) - D_OBS }
  lo <- log(kz0); hi <- log(kz0); n <- 0
  while (g(lo) > 0 && n < 60) { lo <- lo - 0.25; n <- n + 1 }; n <- 0
  while (g(hi) < 0 && n < 60) { hi <- hi + 0.25; n <- n + 1 }
  if (g(lo) > 0 || g(hi) < 0) return(NA_real_); exp(stats::uniroot(g, c(lo, hi), tol = 1e-6)$root) }
solve_f <- function(p) { g <- function(lf) { q <- p; q$kz_deep_frac <- exp(lf); deep_of(q) - D_OBS }
  lfs <- seq(0, log(O9_F_LO), length.out = O9_F_GRID); gv <- vapply(lfs, g, 0); sc <- which(diff(sign(gv)) != 0)
  if (!length(sc)) return(NA_real_)
  exp(stats::uniroot(g, c(lfs[sc[1]], lfs[sc[1] + 1]), tol = 1e-6)$root) }
ARMS <- list()
ARMS$ent26 <- list(lbl = "ent26 column (kz as fitted)", p = par_col())
p <- par_col(); k <- solve_kz(p, p$kz); p$kz <- k; ARMS$col_pin <- list(lbl = sprintf("column, obs-pinned kz %.0f", k), p = p)
p <- par_q(1, O9_HS_ASX_ARM); p$kz_zscale <- O9_ZK; f <- solve_f(p); p$kz_deep_frac <- f
ARMS$hilda <- list(lbl = sprintf("HILDA attach + K(z), hs_asx %.1f, f %.3f", O9_HS_ASX_ARM, f), p = p)
p <- par_q(NL); k <- solve_kz(p, p$kz * 0.3); p$kz <- k; ARMS$bot_pin <- list(lbl = sprintf("bottom attach, uniform obs-pinned kz %.0f", k), p = p)
p <- par_q(NL); p$kz_zscale <- O9_ZK; f <- solve_f(p); p$kz_deep_frac <- f
ARMS$bot_kz <- list(lbl = sprintf("bottom attach + K(z), f %.3f (09-06b)", f), p = p)

score <- function(p) { sp <- ccx_spinup(p); sl <- ccx_model_d14c_slabs(sp)
  m <- c(sl[[1]], sl[[2]], sp$diagnostics$d14c_bottom_box)
  c(A = m[1], B = m[2], deep = m[3], BD = m[2] - m[3],
    ind = sum(stats::dnorm(mu, m, sd_ind, log = TRUE)),
    mvn30 = ccx_dmvnorm_log(mu, m, PC[["30"]]$cov), mvn60 = ccx_dmvnorm_log(mu, m, PC[["60"]]$cov)) }
S <- t(vapply(ARMS, function(a) score(a$p), numeric(7)))
ref <- S["hilda", ]
cat(sprintf("\n  %-46s %7s %7s %7s %6s | %8s %8s %8s | %s\n", "arm", "A", "B", "deep", "B-D", "indep", "mvn30", "mvn60", "loss vs HILDA arm: indep / mvn60  (mvn60 - indep)"))
for (k in rownames(S)) { x <- S[k, ]
  cat(sprintf("  %-46s %7.1f %7.1f %7.1f %+6.1f | %8.2f %8.2f %8.2f | %+7.2f / %+7.2f  (%+6.2f)\n", ARMS[[k]]$lbl, x["A"], x["B"], x["deep"], x["BD"],
              x["ind"], x["mvn30"], x["mvn60"], x["ind"] - ref["ind"], x["mvn60"] - ref["mvn60"], (x["mvn60"] - ref["mvn60"]) - (x["ind"] - ref["ind"]))) }
extra <- function(k) (S[k, "mvn60"] - ref["mvn60"]) - (S[k, "ind"] - ref["ind"])   # what the MVN form adds to the arm's loss, beyond the independent rows
cat(sprintf("\n  GATE (prereg sec.2, 60-deg block): the bottom-attached arms lose >= %g MORE on the row than under the independent form:\n", O9_GATE_LOSS))
for (k in c("bot_pin", "bot_kz")) cat(sprintf("    %-46s extra loss %+6.2f  -> %s\n", ARMS[[k]]$lbl, -extra(k), if (-extra(k) >= O9_GATE_LOSS) "PASS" else "FAIL"))
cat(sprintf("    %-46s extra loss %+6.2f  (the columns; +4 sigma on the contrast, so they too should pay)\n", ARMS$col_pin$lbl, -extra("col_pin")))
cat(sprintf("    %-46s extra loss %+6.2f\n", ARMS$ent26$lbl, -extra("ent26")))
cat("\n  ⚠ Nothing adopted: LIK_USE_D14C_PROFILE_MVN ships FALSE. This is the number the ruling asked for.\n")
saveRDS(list(scores = S, arms = lapply(ARMS, `[[`, "lbl"), mu = mu, sd_ind = sd_ind), O9_OUT); cat(sprintf("  saved %s\n", O9_OUT))
