# =====================================================================
# diag_round6_read.R -- the ROUND-6 READ (2026-09-11): what the seas_ml = 1
# refit (multistart_20260910_round6_seasml1_sd1.0452, jobs 17343694 + 17345351
# + round 2 17354346) says against the seas_ml = 0 canonical `hilda31p`.
# Compares on LIKELIHOOD (the 09-09x ruling: "likelihood-only" meant COMPARE on
# likelihood), lists the stream deltas, and takes the P2 / P12 reads from the
# start files' own prior_z. Scores both vectors THROUGH THE OBJECTIVE
# (ccx_make_logpost(by_stream = TRUE)), never a hand-built reconstruction.
# Output: <outdir>/round6_read.log. NOTHING HERE ADOPTS ANYTHING.
# =====================================================================
suppressMessages(for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)); ccx_load_cpp()
D <- "calibration/output/multistart_20260910_round6_seasml1_sd1.0452"
b1 <- readRDS(file.path(D, "start_004.rds")); b2 <- readRDS(file.path(D, "start_001.rds")); b3 <- readRDS(file.path(D, "start_009.rds"))
md <- readRDS(ccx_mode_file())   # hilda31p, seas_ml 0
cat(sprintf("basin1 id4 %.4f seas_ml %d struct %s | basin2 id1 %.4f | basin3 id9 %.4f | hilda31p %.4f\n", b1$logpost, b1$seas_ml, b1$struct, b2$logpost, b3$logpost, md$logpost))
score <- function(pm, seas_ml) { bp <- ccx_apply_structure(ccx_default_params(), "hilda", seas_ml = seas_ml); bp$pump_mode <- "N"
  v <- ccx_make_logpost(base_params = bp, by_stream = TRUE)(ccx_par_to_unc(pm)); list(lp = as.numeric(v), st = unlist(attr(v, "streams"))) }
s0 <- score(md$par_mode, 0); s1 <- score(b1$par_mode, 1); s2 <- score(b2$par_mode, 1)
cat(sprintf("\nreproduce: hilda31p %.6f (file %.6f) | basin1 %.6f (file %.6f) | basin2 %.6f (file %.6f)\n", s0$lp, md$logpost, s1$lp, b1$logpost, s2$lp, b2$logpost))
cat(sprintf("\nLIKELIHOOD (sum of streams): hilda31p(seas_ml0) %.4f | basin1(seas_ml1) %.4f  d=%+.4f | basin2 %.4f  d=%+.4f\n", sum(s0$st), sum(s1$st), sum(s1$st)-sum(s0$st), sum(s2$st), sum(s2$st)-sum(s0$st)))
cat(sprintf("PRIOR+JAC: hilda31p %.4f | basin1 %.4f | basin2 %.4f\n", s0$lp-sum(s0$st), s1$lp-sum(s1$st), s2$lp-sum(s2$st)))
d <- s1$st - s0$st; o <- order(-abs(d))
cat("\nstream deltas basin1 - hilda31p (|d| > 0.5):\n"); for (i in o) if (abs(d[i]) > 0.5) cat(sprintf("  %-22s %+8.3f   (%.3f -> %.3f)\n", names(d)[i], d[i], s0$st[i], s1$st[i]))
cat("\nPRIOR z beyond 2 sigma, and the P2 / P12 reads:\n")
z0 <- md$prior_z; z1 <- b1$prior_z; z2 <- b2$prior_z
for (n in CCX_PARAM_NAMES) if (abs(z0[[n]]) > 2 || abs(z1[[n]]) > 2 || n %in% c("sst_seas_amp_NH","ent_seas_amp_SH","h_ml"))
  cat(sprintf("  %-18s z: hilda31p %+6.2f  basin1 %+6.2f  basin2 %+6.2f   value: %9.4f -> %9.4f (%+.1f%%)\n", n, z0[[n]], z1[[n]], z2[[n]], md$par_mode[[n]], b1$par_mode[[n]], 100*(b1$par_mode[[n]]/md$par_mode[[n]]-1)))
cat(sprintf("\nent_seas_amp_SH: %.4f (basin1) / %.4f (basin2) vs corrected centre 6.5525 -> %.2fx / %.2fx\n", b1$par_mode$ent_seas_amp_SH, b2$par_mode$ent_seas_amp_SH, b1$par_mode$ent_seas_amp_SH/6.5525, b2$par_mode$ent_seas_amp_SH/6.5525))
cat("\nlargest parameter moves basin1 vs hilda31p:\n"); mv <- sapply(CCX_PARAM_NAMES, function(n) 100*(b1$par_mode[[n]]/md$par_mode[[n]]-1)); for (n in names(sort(-abs(mv)))[1:8]) cat(sprintf("  %-18s %+7.1f%%  (%.4g -> %.4g)\n", n, mv[[n]], md$par_mode[[n]], b1$par_mode[[n]]))
cat("\nbasin1 vs basin2 parameter differences > 1%:\n"); for (n in CCX_PARAM_NAMES) { r <- 100*(b2$par_mode[[n]]/b1$par_mode[[n]]-1); if (abs(r) > 1) cat(sprintf("  %-18s %+7.1f%%  (%.4g vs %.4g)\n", n, r, b1$par_mode[[n]], b2$par_mode[[n]])) }
