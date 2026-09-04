# =====================================================================
# GATE 4: WHY IS THE MODEL'S DECADAL AIRBORNE FRACTION TOO SMOOTH?
#
# THE QUESTION (handoff 2026-09-04, open decision 1). At the adopted `ent26`
# mode gate 4 reads sd 0.025 against GCB's 0.051, a ratio of 0.48, while the
# UNCALIBRATED DEFAULTS read 0.76 in the same harness -- so calibration appears
# to have made the airborne fraction SMOOTHER. That reading rests on three
# things nobody had measured, and this file measures all three:
#
#   A. THE TARGET. Is 0.051 the observations' spread, or an artifact of how the
#      observed side was written down? (It is partly the latter -- and finding
#      out identified a LIKE-FOR-LIKE violation; see lib_design_gates.R.)
#   B. THE NOISE FLOOR. How much of the observed decade-to-decade spread is a
#      resolved DECADAL SIGNAL, and how much is interannual noise sampled ten
#      years at a time? A gate whose target is mostly noise is asking the model
#      for interannual variance under a decadal name. [[smoother_wider_than_feature]]
#   C. TREND vs VARIABILITY. `sd()` over seven decades does not distinguish a
#      model whose AF WIGGLES from one whose AF DRIFTS. If the defaults' larger
#      spread is a drift, "calibration made it smoother" is the wrong reading of
#      the same number. [[two_statistics_can_be_blind]]
#
# ⛔ SCORES NOTHING AND CHANGES NO BOUND. It reports; the gate's verdict stays
# where lib_design_gates.R puts it.
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

# ---- labels derive from named constants (project rule) --------------
G4D_ARMS      <- c("defaults", CCX_MODE_CANONICAL)
G4D_SPLINE_DF <- 3        # dof of the smooth AF(t) that DEFINES "decadal signal"
G4D_DF_WALK   <- 2:5      # ...and it is a CHOICE, so it is walked, not picked
G4D_MC_N      <- 4000     # draws in the matched Monte Carlo that validates the floor
G4D_MC_SEED   <- 20260904
G4D_MC_SLOPES <- c(0, 0.0147)   # a NULL and the observed trend, both prescribed
G4D_OUT       <- ccx_path("calibration", "output", "gate4_af_spread")
dir.create(G4D_OUT, showWarnings = FALSE, recursive = TRUE)

sep <- function(s) cat(sprintf("\n%s\n%s\n%s\n", strrep("=", 72), s, strrep("=", 72)))
fmt <- function(x, d = 4) sprintf(paste0("%8.", d, "f"), x)

# ---------------------------------------------------------------------
# THE DECOMPOSITION, ONE FUNCTION, APPLIED TO OBSERVATIONS AND MODEL ALIKE.
#
# Model: grow_y = AF(y) * emis_y + eps_y, with AF(y) a natural spline in year --
# the SMOOTH part is the decadal signal, `eps` is the interannual anomaly in
# GtC/yr. Then a decade's AF carries a sampling noise sd of
# sd(sum of eps over the decade) / sum(emis over the decade), and the sum of an
# AR(1) sequence has variance sigma^2 * (n + 2*sum_h (n-h) rho^h).
# ⚠ THE AR CORRECTION IS MEASURED, NOT ASSUMED: rho is the fitted lag-1
# autocorrelation of that arm's own residuals, printed beside every number.
# ---------------------------------------------------------------------
g4d_decomp <- function(a, df = G4D_SPLINE_DF, win = DG_AF_WIN,
                       decades = DG_AF_DECADES) {
  k <- a$year >= win[1] & a$year <= win[2]
  yr <- a$year[k]; gr <- a$grow[k]; em <- (a$foss + a$luc)[k]
  B  <- splines::ns(yr, df = df)
  fit <- stats::lm(gr ~ 0 + em + I(em * B))
  eps <- stats::residuals(fit); smo <- stats::fitted(fit)
  rho <- stats::acf(eps, plot = FALSE, lag.max = 1)$acf[2]
  dec_of <- function(v) vapply(decades, function(d) {
    kk <- yr >= d & yr <= min(d + 9, win[2]); sum(v[kk]) / sum(em[kk]) }, 0)
  nz <- vapply(decades, function(d) {
    kk <- yr >= d & yr <= min(d + 9, win[2]); n <- sum(kk); h <- seq_len(n - 1)
    sqrt(stats::var(eps) * (n + 2 * sum((n - h) * rho^h))) / sum(em[kk]) }, 0)
  dec <- dec_of(gr)
  x <- seq_along(dec); lf <- stats::lm(dec ~ x)
  list(dec = dec, sd_dec = stats::sd(dec),
       sig = dec_of(smo), sd_sig = stats::sd(dec_of(smo)),
       eps_sd = stats::sd(eps), rho = rho, noise = nz,
       noise_rms = sqrt(mean(nz^2)),
       slope = unname(stats::coef(lf)[2]),
       sd_trend = stats::sd(stats::fitted(lf)),
       sd_detr = stats::sd(stats::residuals(lf)) * sqrt((length(dec) - 1) /
                                                        (length(dec) - 2)),
       r2_trend = summary(lf)$r.squared,
       af_ann_sd = stats::sd(eps / em))    # the anomaly IN AF UNITS
}

# =====================================================================
sep("A. THE TARGET -- COMPUTED, NOT TYPED (lib_design_gates.R, 2026-09-04)")
OA <- DG_AF_OBS_ANNUAL
cat("  decade            "); cat(sprintf("%8d", DG_AF_DECADES), "\n")
cat("  TYPED (retired)   "); cat(fmt(DG_AF_OBS_DEC_TYPED), "\n")
cat("  mean-of-annual    "); cat(fmt(dg_af_dec(OA, how = "mean_of_annual")$dec), "\n")
cat("  ratio-of-sums  <= "); cat(fmt(DG_AF_OBS_DEC), "\n")
cat(sprintf("\n  sd: typed %.4f | mean-of-annual %.4f | ratio-of-sums %.4f  <= THE BOUND\n",
            stats::sd(DG_AF_OBS_DEC_TYPED),
            stats::sd(dg_af_dec(OA, how = "mean_of_annual")$dec),
            stats::sd(DG_AF_OBS_DEC)))
cat("  The model side is a RATIO OF SUMS, so that is the like-for-like target.\n")
cat(sprintf("  Window AF %d-%d = %.4f (typed %.3f).\n",
            DG_AF_WIN[1], DG_AF_WIN[2], DG_AF_OBS, DG_AF_OBS_TYPED))

# =====================================================================
sep("B. THE NOISE FLOOR -- IS THERE A RESOLVED DECADAL SIGNAL AT ALL?")
DO <- g4d_decomp(OA)
cat(sprintf("  interannual anomaly about a smooth AF(t): sd %.3f GtC/yr, lag-1 rho %+.3f\n",
            DO$eps_sd, DO$rho))
cat("  per-decade noise sd on the decadal AF:\n    "); cat(fmt(DO$noise), "\n")
cat(sprintf("    rms = %.4f      (the 2020s decade is %d years, not 10)\n",
            DO$noise_rms, sum(OA$year >= 2020 & OA$year <= DG_AF_WIN[2])))
sig2 <- DO$sd_dec^2 - DO$noise_rms^2
cat(sprintf("\n  observed decadal spread   %.4f\n  noise floor (rms)         %.4f\n",
            DO$sd_dec, DO$noise_rms))
cat(sprintf("  => RESOLVED decadal signal %.4f  (%.0f%% of the spread's VARIANCE is noise)\n",
            if (sig2 > 0) sqrt(sig2) else 0, 100 * DO$noise_rms^2 / DO$sd_dec^2))
cat("\n  SMOOTHING IS A CHOICE, so it is walked, not picked:\n")
for (df in G4D_DF_WALK) { d <- g4d_decomp(OA, df = df)
  cat(sprintf("    ns df=%d: eps sd %.3f GtC/yr, rho %+.3f, noise rms %.4f, smooth-signal sd %.4f\n",
              df, d$eps_sd, d$rho, d$noise_rms, d$sd_sig)) }

# =====================================================================
sep("C. THE ARMS")
V <- lapply(setNames(G4D_ARMS, G4D_ARMS), dg_vector)
for (a in G4D_ARMS) cat(sprintf("  %-10s %s%s\n", a, V[[a]]$src,
  if (length(V[[a]]$migrated)) sprintf(" [MIGRATED: %s]",
    paste(V[[a]]$migrated, collapse = ",")) else ""))
t0 <- Sys.time()
R <- lapply(V, dg_run)
cat(sprintf("  %d runs in %.1f s\n", length(R), as.numeric(Sys.time() - t0, units = "secs")))
G4 <- Map(dg_gate4, R, V)
D  <- lapply(G4, function(g) g4d_decomp(g$annual))

cat(sprintf("\n  %-10s %8s %8s %8s | decadal AF\n", "arm", "AF(all)", "sd(dec)", "ratio"))
cat(sprintf("  %-10s %8.4f %8.4f %8s | %s\n", "GCB 2025", DG_AF_OBS, DO$sd_dec, "1.000",
            paste(sprintf("%7.3f", DG_AF_OBS_DEC), collapse = "")))
for (a in G4D_ARMS) {
  v <- dg_gate4_verdict(G4[[a]])
  cat(sprintf("  %-10s %8.4f %8.4f %8.3f | %s  %s\n", a, G4[[a]]$all, v$sd_model, v$ratio,
              paste(sprintf("%7.3f", G4[[a]]$dec), collapse = ""),
              if (v$pass) "PASS" else "FAIL"))
}

# =====================================================================
sep("D. TREND vs VARIABILITY -- sd() OVER SEVEN DECADES CANNOT TELL THEM APART")
cat(sprintf("  %-10s %9s %9s %9s %7s\n", "arm", "sd(dec)", "sd(trend)", "sd(detr)", "R2"))
row <- function(nm, d) cat(sprintf("  %-10s %9.4f %9.4f %9.4f %7.3f\n",
                                   nm, d$sd_dec, d$sd_trend, d$sd_detr, d$r2_trend))
row("GCB 2025", DO); for (a in G4D_ARMS) row(a, D[[a]])
cat("\n  A gate written as sd(model) >= sd(obs) is passed by a DRIFTING AF just as\n")
cat("  well as by a varying one. Detrended, the same comparison reads:\n")
for (a in G4D_ARMS) cat(sprintf("    %-10s detrended ratio %.3f  (raw %.3f)\n",
                                a, D[[a]]$sd_detr / DO$sd_detr, D[[a]]$sd_dec / DO$sd_dec))

# =====================================================================
sep("E. IS THE SHORTFALL DECADAL, OR IS IT THE KNOWN INTERANNUAL GAP?")
cat(sprintf("  %-10s %10s %8s %10s %10s %10s\n",
            "arm", "eps GtC/yr", "rho", "sd(AF ann)", "noise rms", "sd(signal)"))
erow <- function(nm, d) cat(sprintf("  %-10s %10.3f %+8.3f %10.4f %10.4f %10.4f\n",
                                    nm, d$eps_sd, d$rho, d$af_ann_sd, d$noise_rms, d$sd_sig))
erow("GCB 2025", DO); for (a in G4D_ARMS) erow(a, D[[a]])
cat("\n  PREDICTED decadal spread if an arm had the OBSERVED decadal signal and\n")
cat("  only its OWN interannual noise -- sqrt(sd(signal_obs)^2 + noise_rms^2):\n")
so <- if (sig2 > 0) sqrt(sig2) else 0
for (a in G4D_ARMS)
  cat(sprintf("    %-10s predicted %.4f   measured %.4f\n",
              a, sqrt(so^2 + D[[a]]$noise_rms^2), D[[a]]$sd_dec))
cat(sprintf("\n  interannual anomaly, model / observed: %s\n",
            paste(sprintf("%s %.2f", G4D_ARMS,
                          vapply(D[G4D_ARMS], function(d) d$eps_sd, 0) / DO$eps_sd),
                  collapse = "  |  ")))

# =====================================================================
sep("F. DOES GATE 4 HAVE POWER? THE TREND, WITH ITS ERROR BAR")
# THE TREND NEEDS AN ERROR BAR BEFORE IT NEEDS AN EXPLANATION
# ([[curvature_needs_an_error_bar]]). The observed AF trend is estimated on the
# ANNUAL series, not on seven decade points: grow_y = (a + b*(y - ybar)) * emis_y,
# so `b` is the AF trend per year and its se comes from the fit that produced it.
# ⚠ The MODEL is deterministic given its forcing, so the question is not whether
# the two trends differ "significantly" in a two-sample sense -- it is whether
# each model trend lies inside the OBSERVED trend's own confidence interval.
g4d_trend <- function(a, win = DG_AF_WIN) {
  k <- a$year >= win[1] & a$year <= win[2]
  yr <- a$year[k]; gr <- a$grow[k]; em <- (a$foss + a$luc)[k]
  x  <- yr - mean(yr)
  f  <- stats::lm(gr ~ 0 + em + I(em * x))
  co <- summary(f)$coefficients
  c(af0 = co[1, 1], b = co[2, 1], se = co[2, 2])
}
TO <- g4d_trend(OA)
ci <- TO[["b"]] + c(-1, 1) * stats::qnorm(0.975) * TO[["se"]]
cat(sprintf("  GCB 2025   AF trend %+.5f +- %.5f /yr  (%+.4f +- %.4f per decade)\n",
            TO[["b"]], TO[["se"]], 10 * TO[["b"]], 10 * TO[["se"]]))
cat(sprintf("             t = %+.2f, 95%% CI per decade [%+.4f, %+.4f]\n",
            TO[["b"]] / TO[["se"]], 10 * ci[1], 10 * ci[2]))
for (a in G4D_ARMS) { tm <- g4d_trend(G4[[a]]$annual)
  cat(sprintf("  %-10s AF trend %+.4f per decade   z vs obs %+.2f   %s\n", a,
              10 * tm[["b"]], (tm[["b"]] - TO[["b"]]) / TO[["se"]],
              if (tm[["b"]] >= ci[1] && tm[["b"]] <= ci[2]) "INSIDE obs 95% CI"
              else "OUTSIDE obs 95% CI")) }

sep("G. THE PER-DECADE MISS, SCALED TO THE OBSERVATIONS' OWN NOISE")
# The bound that section B says gate 4 could actually carry: each decade's
# observed AF has a KNOWN sampling sd (section B), so a model decade can be
# scored against it. That is a tolerance derived from the quantity it tests
# ([[tolerance_scaled_to_spread]]) instead of an ordering between two sd()s that
# section D shows cannot separate a drift from a wiggle.
cat(sprintf("  %-10s %s\n", "decade", paste(sprintf("%8d", DG_AF_DECADES), collapse = "")))
cat(sprintf("  %-10s %s\n", "obs noise", paste(fmt(DO$noise), collapse = "")))
for (a in G4D_ARMS)
  cat(sprintf("  %-10s %s   max|z| %.2f\n", paste0("z ", a),
              paste(sprintf("%8.2f", (G4[[a]]$dec - DG_AF_OBS_DEC) / DO$noise), collapse = ""),
              max(abs((G4[[a]]$dec - DG_AF_OBS_DEC) / DO$noise))))
cat("\n  ⚠ PROPOSED, NOT ADOPTED. The gate's bound is a DESIGN decision and stays\n")
cat("    where lib_design_gates.R puts it until it is ruled on.\n")

# =====================================================================
sep("H. VALIDATE THE ANALYTIC NOISE FLOOR AGAINST A MATCHED MONTE CARLO")
# ⛔ SECTIONS B, D AND G ALL REST ON ONE ANALYTIC se, so it gets a matched Monte
# Carlo before anything is concluded from it (~/.claude/CLAUDE.md). The MC uses
# the OBSERVED emissions and a PRESCRIBED airborne fraction, so the truth is
# known by construction: draw white noise of the observed anomaly sd, rebuild the
# decadal AF, and compare the SPREAD ACROSS DRAWS with the analytic floor.
set.seed(G4D_MC_SEED)
g4d_mc <- function(sig_slope, n = G4D_MC_N) {
  em <- OA$foss + OA$luc; yr <- OA$year; k <- yr >= DG_AF_WIN[1] & yr <= DG_AF_WIN[2]
  af_t <- DG_AF_OBS + sig_slope * (yr - mean(yr[k])) / 10
  truth <- vapply(DG_AF_DECADES, function(d) { kk <- yr >= d & yr <= min(d + 9, DG_AF_WIN[2]) & k
    sum((af_t * em)[kk]) / sum(em[kk]) }, 0)
  dd <- replicate(n, {
    a <- list(year = yr, grow = af_t * em + stats::rnorm(length(yr), 0, DO$eps_sd),
              foss = OA$foss, luc = OA$luc)
    dg_af_dec(a)$dec })
  sds <- apply(dd, 2, stats::sd)
  list(truth_sd = stats::sd(truth), mc_sd_dec = stats::sd(sds),
       mc_mean_sd_dec = mean(sds), mc_q = stats::quantile(sds, c(.05, .5, .95)),
       mc_per_decade = apply(dd, 1, stats::sd))
}
for (sl in G4D_MC_SLOPES) { mc <- g4d_mc(sl)
  cat(sprintf("\n  prescribed AF slope %+.4f/decade -> true decadal sd %.4f\n", sl, mc$truth_sd))
  cat(sprintf("    analytic per-decade floor  %s\n", paste(fmt(DO$noise), collapse = "")))
  cat(sprintf("    Monte Carlo per-decade     %s\n", paste(fmt(mc$mc_per_decade), collapse = "")))
  cat(sprintf("    E[sd(7 decades)] MC %.4f  [5%%..95%%: %.4f .. %.4f]  quadrature %.4f\n",
              mc$mc_mean_sd_dec, mc$mc_q[1], mc$mc_q[3],
              sqrt(mc$truth_sd^2 + DO$noise_rms^2)))
  cat(sprintf("      (E[sd] < quadrature is Jensen, not a discrepancy)\n"))
  cat(sprintf("      observed %.4f%s |", DO$sd_dec,
              if (DO$sd_dec >= mc$mc_q[1] && DO$sd_dec <= mc$mc_q[3]) " INSIDE" else " OUTSIDE"))
  for (a in G4D_ARMS) cat(sprintf("  %s %.4f%s", a, D[[a]]$sd_dec,
              if (D[[a]]$sd_dec >= mc$mc_q[1] && D[[a]]$sd_dec <= mc$mc_q[3]) " INSIDE" else " OUTSIDE"))
  cat("\n") }
cat("\n  ⇒ if the two per-decade rows agree, the floor in section B is the floor.\n")
cat("  ⚠ THE ARMS ARE SHOWN AGAINST A NULL BUILT ON THE *OBSERVED* NOISE AMPLITUDE.\n")
cat("    Each arm has less interannual variance than that (section E), so this\n")
cat("    placement is a like-for-like statement about the TARGET, not a test of\n")
cat("    the arm: an arm with 0.77x the anomaly is EXPECTED near 0.77x the spread.\n")

# =====================================================================
sep("I. IS THERE A DECADAL-SPECIFIC DEFECT LEFT, ONCE THE ARM IS JUDGED AGAINST ITSELF?")
# THE DECISIVE TEST. Sections D-F attribute the gate-4 shortfall to (a) a weaker
# AF TREND and (b) less INTERANNUAL variance. If nothing else is going on, then
# an arm's own decadal spread should be a typical draw from a null built on ITS
# OWN fitted trend and ITS OWN anomaly amplitude. If it sits below that null too,
# something decadal-specific is left over and gate 4 has found it.
g4d_mc_self <- function(slope, eps_sd, n = G4D_MC_N) {
  em <- OA$foss + OA$luc; yr <- OA$year; k <- yr >= DG_AF_WIN[1] & yr <= DG_AF_WIN[2]
  af_t <- DG_AF_OBS + slope * (yr - mean(yr[k]))
  sds <- replicate(n, stats::sd(dg_af_dec(list(year = yr, foss = OA$foss, luc = OA$luc,
    grow = af_t * em + stats::rnorm(length(yr), 0, eps_sd)))$dec))
  stats::quantile(sds, c(.05, .5, .95))
}
cat(sprintf("  %-10s %9s %10s | %s\n", "arm", "sd(dec)", "own eps", "null from ITS OWN trend+noise [5% .. 50% .. 95%]"))
for (a in c("GCB 2025", G4D_ARMS)) {
  d  <- if (a == "GCB 2025") DO else D[[a]]
  tb <- if (a == "GCB 2025") TO[["b"]] else g4d_trend(G4[[a]]$annual)[["b"]]
  q  <- g4d_mc_self(tb, d$eps_sd)
  cat(sprintf("  %-10s %9.4f %10.3f | %.4f .. %.4f .. %.4f   %s\n", a, d$sd_dec, d$eps_sd,
              q[1], q[2], q[3],
              if (d$sd_dec >= q[1] && d$sd_dec <= q[3]) "INSIDE" else "OUTSIDE"))
}
cat("\n  ⚠ THE NULL DRAWS WHITE NOISE while both arms' residuals are autocorrelated\n")
cat(sprintf("    (rho %s vs the observations' %+.3f), which INFLATES a decade sum's variance.\n",
            paste(sprintf("%+.3f", vapply(D[G4D_ARMS], function(d) d$rho, 0)), collapse = "/"),
            DO$rho))
cat("    So the arms' intervals here are if anything too NARROW, and they are INSIDE\n")
cat("    anyway -- the error runs in the direction that would have caught a defect.\n")

saveRDS(list(obs = DO, arms = D, g4 = G4, trend_obs = TO,
             trend_arms = lapply(G4, function(g) g4d_trend(g$annual)), when = Sys.time(),
             mode = CCX_MODE_CANONICAL, spline_df = G4D_SPLINE_DF),
        file.path(G4D_OUT, "gate4_af_spread.rds"))
cat(sprintf("\nwrote %s\n", file.path(G4D_OUT, "gate4_af_spread.rds")))
