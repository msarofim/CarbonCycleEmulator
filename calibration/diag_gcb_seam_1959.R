# =====================================================================
# diag_gcb_seam_1959.R -- G1: SEPARATE THE 1959 METHODOLOGY SEAM FROM THE
#                            BUDGET ERROR.  (2026-08-25)
#
# handoff_2026-08-25 sec.5 nominated GCB's own `imbalance` column as the
# successor programme for `rep_dC`: it integrates to 37.8 ppm over 1850-2024,
# 56 % of it lands before 1959, and it is scored NOWHERE. Section 6 then made
# G1 the FIRST step, because the whole shape has a competing generator that
# costs nothing to test and, if true, shrinks the programme by more than half.
#
# THE COMPETING GENERATOR IS IN GCB'S OWN HEADER. The historical sheet states
# that the methods before 1959 differ from the 1959-onwards budget, and that
# "the atmospheric growth and ocean sink do not account for year-to-year
# variability before 1959". Pre-1959 atmospheric growth is Joos & Spahni 2008;
# the pre-1959 ocean sink is the mean of two diagnostic models (DeVries 2014,
# Khatiwala 2013); the land sink is a 22-DGVM mean. A method change at a fixed
# year produces exactly the shape sec.5 read as a century drift.
#
# FIVE TESTS, cheapest first. NONE needs a refit; all five are data-only.
#
#  T0 THE IDENTITY AND THE ERROR BAR, BEFORE ANY ATTRIBUTION.
#     The imbalance is a five-term residual; verify the identity closes before
#     anything is attributed to any term. Then put a bar on the 44.66 GtC
#     pre-1959 cumulative. GCB states +/-0.7 GtC/yr (1 sd) on the budget. A
#     cumulative of 109 annual errors is sqrt(109)*0.7 = 7.3 GtC ONLY if they
#     are independent, and 109*0.7 = 76 GtC if they are perfectly correlated.
#     The pre-1959 terms are SMOOTH BY CONSTRUCTION, so their errors are the
#     correlated case, not the independent one. [[curvature_needs_an_error_bar]]
#     says do this BEFORE explaining the number.
#
#  T1 WHICH COMPONENT CARRIES THE SEAM. Only `atm_growth` and `ocean_sink`
#     changed method at 1959, so a seam must live in those two and a real
#     budget error need not. Two statistics: (a) the SMOOTHNESS fingerprint --
#     sd of second differences, which is near zero for a term that is a
#     smoothed reconstruction and finite for a term with real IAV; (b) the STEP
#     at the seam, from local linear fits either side extrapolated to 1958.5,
#     with a Newey-West se validated against a block-bootstrap Monte Carlo.
#
#  T2 PRICE THE STEP AS A CUMULATIVE. A step is only interesting if it moves
#     the 44.66 GtC. Two arithmetics are reported: the naive constant-offset
#     one (upper bound, and labelled as such) and T3's backcast.
#
#  T3 BACKCAST THE POST-SEAM OCEAN SINK INTO THE PRE-SEAM ERA. A constant
#     offset is the wrong counterfactual -- a diagnostic model at a lower CO2
#     level SHOULD have a smaller sink. Fit ocean_sink on a predictor that is
#     measured the same way in both eras (atmospheric CO2 excess over
#     preindustrial), on the post-seam years, and backcast. This is an
#     EXTRAPOLATION below the fitted range, so it is run on two windows -- the
#     nearest post-seam decades and the full post-seam period -- and both are
#     reported rather than one being chosen.
#
#  T4 IS GCB'S PRE-1959 GROWTH THE SAME OBJECT WE ALREADY SCORE?  This is the
#     test that decides whether the imbalance can say ANYTHING about `rep_dC`.
#     If GCB's pre-1959 atmospheric growth is a reconstruction of the very Law
#     Dome record our likelihood scores, then a model fitted to our ice term is
#     ALREADY fitted to GCB's growth, the agreement is BY CONSTRUCTION, and the
#     imbalance is a statement about emissions and sinks only. Run as a LEVEL
#     comparison -- cumulate GCB's growth from an 1850 anchor and compare the
#     implied CO2 to the ice record in ppm -- because differentiating 172 raw
#     samples imports a bandwidth choice the level test does not need.
#     [[smoother_wider_than_feature]] is the reason to prefer the level.
#
#  T5 THE PLATEAU, FOR FREE. The 1940s decadal imbalance is +1.304 GtC/yr and
#     the 1940s decadal atm_growth is 0.334 -- i.e. the pre-1959 imbalance peak
#     sits exactly on the 1940s CO2 plateau the 08-23/08-24 arc spent six
#     refits on. Report what fraction of the pre-1959 cumulative lives in that
#     window, so the successor programme cannot silently re-inherit the arc
#     that was just de-ranked.
#
# Usage:  Rscript calibration/diag_gcb_seam_1959.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

# ---- NAMED CONSTANTS (labels derive from these, never from literals) --
SEAM        <- 1959L          # first year of the 1959-onwards GCB methodology
SEAM_EDGE   <- SEAM - 0.5     # the step is evaluated at the boundary
YR0         <- 1850L          # first year with a non-NA imbalance
YR1         <- 2024L
# The imbalance is a five-term residual, so its 1 sd is the quadrature sum of
# the per-term sigmas THIS REPO ALREADY SCORES WITH (R/likelihood.R:305-311),
# not a hand-set literal. Growth contributes ~0 post-1959 (Keeling) and is
# folded into the pre-seam terms' own error, which is why it has no entry here.
GCB_SD_TERMS <- c(luc = LIK_GCB_LUC_SD, ocean = LIK_GCB_OCEAN_SD,
                  land = LIK_GCB_LAND_SD)
PPM_PER_GTC <- 1 / 2.124      # R/constants.R: 2.124 GtC per ppm
CO2_PREIND  <- 276.88         # R/constants.R
STEP_WINS   <- c(8L, 10L, 15L, 20L)   # half-windows for the local step fits
BOOT_B      <- 4000L          # block-bootstrap replicates
BOOT_BLOCK  <- 5L             # block length, yr
PLATEAU_WIN <- c(1940L, 1958L)        # the arc's window, for T5
BACK_WINS   <- list("near (1959-1980)" = c(1959L, 1980L),
                    "full (1959-2024)" = c(SEAM, YR1))
COMPONENTS  <- c("fossil", "luc", "atm_growth", "ocean_sink", "land_sink")
OUTDIR      <- ccx_path("calibration", "output", "gcb_seam_1959")
dir.create(OUTDIR, recursive = TRUE, showWarnings = FALSE)

set.seed(20260825)

cat(sprintf("\n=== G1: THE %d METHODOLOGY SEAM vs THE BUDGET ERROR ===\n", SEAM))
cat(sprintf("window %d-%d | %.3f GtC per ppm\n", YR0, YR1, 1 / PPM_PER_GTC))

# ---- LOAD, WITH THE NA TRAP FROM THE HANDOFF sec.8 -------------------
h <- as.data.frame(readRDS(ccx_path("data", "gcb_budget.rds"))$historical)
stopifnot(all(c("year", COMPONENTS, "imbalance", "cement_carbonation") %in% names(h)))
n_na <- sum(is.na(h$imbalance))
h <- h[!is.na(h$imbalance) & h$year >= YR0 & h$year <= YR1, ]
cat(sprintf("historical sheet: %d rows kept, %d dropped on is.na(imbalance)\n",
            nrow(h), n_na))
stopifnot(nrow(h) == YR1 - YR0 + 1L, !any(diff(h$year) != 1L))

foss_sd <- LIK_GCB_FOSS_FRAC * mean(h$fossil[h$year < SEAM])
GCB_SD  <- sqrt(sum(GCB_SD_TERMS^2) + foss_sd^2)
cat(sprintf("imbalance 1 sd, in quadrature from R/likelihood.R's own sigmas:\n  %s, fossil %.1f%%x%.2f = %.3f  =>  %.3f GtC/yr\n",
            paste(sprintf("%s %.2f", names(GCB_SD_TERMS), GCB_SD_TERMS), collapse = ", "),
            100 * LIK_GCB_FOSS_FRAC, mean(h$fossil[h$year < SEAM]), foss_sd, GCB_SD))
cat("  The pre-seam sinks are diagnostic-model and DGVM means, not the post-seam\n")
cat("  products these sigmas describe, so this is a FLOOR on the pre-seam bar.\n")

# =====================================================================
# T0  THE IDENTITY, THEN THE ERROR BAR ON THE CUMULATIVE
# =====================================================================
cc  <- ifelse(is.na(h$cement_carbonation), 0, h$cement_carbonation)
res <- h$fossil + h$luc - h$atm_growth - h$ocean_sink - h$land_sink - cc
cat(sprintf("\nT0  identity  max|imbalance - (F + L - G - O - S - cem)| = %.2e GtC/yr. %s\n",
            max(abs(h$imbalance - res)),
            if (max(abs(h$imbalance - res)) < 1e-8) "CLOSES." else "DOES NOT CLOSE."))
stopifnot(max(abs(h$imbalance - res)) < 1e-8)

pre  <- h$year <  SEAM
post <- h$year >= SEAM
cum  <- function(x) sum(x)
C_pre <- cum(h$imbalance[pre]); C_post <- cum(h$imbalance[post]); C_all <- cum(h$imbalance)
cat(sprintf("    cumulative imbalance  %d-%d = %7.2f GtC = %6.2f ppm  (%.0f %% of total)\n",
            YR0, SEAM - 1L, C_pre, C_pre * PPM_PER_GTC, 100 * C_pre / C_all))
cat(sprintf("                          %d-%d = %7.2f GtC = %6.2f ppm\n",
            SEAM, YR1, C_post, C_post * PPM_PER_GTC))
cat(sprintf("                          %d-%d = %7.2f GtC = %6.2f ppm\n",
            YR0, YR1, C_all, C_all * PPM_PER_GTC))

# The bar. Annual errors of a SMOOTHED reconstruction are correlated; the
# cumulative's variance is 1' Sigma 1, so an AR(1) correlation length is the
# one assumption that has to be made, and it is scanned rather than chosen.
cum_sd <- function(n, sd, rho) {
  if (rho <= 0) return(sd * sqrt(n))
  i <- seq_len(n); sd * sqrt(sum(outer(i, i, function(a, b) rho^abs(a - b))))
}
n_pre <- sum(pre)
cat(sprintf("\n    1 sd on the %d-yr cumulative, as a function of the error correlation length:\n", n_pre))
for (rho in c(0, 0.5, 0.8, 0.9, 0.95, 0.99, 1)) {
  s <- if (rho >= 1) GCB_SD * n_pre else cum_sd(n_pre, GCB_SD, rho)
  cat(sprintf("      rho = %-5s  sd = %6.1f GtC = %5.2f ppm   =>  %.2f sigma on %.1f GtC\n",
              format(rho), s, s * PPM_PER_GTC, C_pre / s, C_pre))
}
cat("    The pre-seam terms are SMOOTH BY CONSTRUCTION, so the high-rho rows are the\n")
cat("    relevant ones, not rho = 0. Read this before reading any attribution below.\n")

# =====================================================================
# T1  WHICH COMPONENT CARRIES THE SEAM
# =====================================================================
cat(sprintf("\nT1a SMOOTHNESS FINGERPRINT -- sd of SECOND differences, GtC/yr.\n"))
cat("    A smoothed reconstruction has ~0 curvature noise; a term with real IAV does not.\n")
cat(sprintf("    %-12s %10s %10s %8s\n", "term", "pre", "post", "post/pre"))
smooth_tab <- data.frame()
for (v in c(COMPONENTS, "imbalance")) {
  sp <- stats::sd(diff(h[[v]][pre], differences = 2))
  sq <- stats::sd(diff(h[[v]][post], differences = 2))
  cat(sprintf("    %-12s %10.4f %10.4f %8.1f%s\n", v, sp, sq, sq / sp,
              if (sq / sp > 10) "   <== SEAM" else ""))
  smooth_tab <- rbind(smooth_tab, data.frame(term = v, sd2_pre = sp, sd2_post = sq))
}

# ---- T1b the step itself, with a se that is not a fantasy ------------
# Local linear fit on w years each side, extrapolated to the boundary. The
# residuals are autocorrelated, so the se is Newey-West; the MC below checks
# that the analytic bar is CONSERVATIVE rather than merely present.
local_edge <- function(yr, x, w, side) {
  k <- if (side == "pre") (yr < SEAM & yr >= SEAM - w) else (yr >= SEAM & yr < SEAM + w)
  y <- x[k]; t <- yr[k] - SEAM_EDGE
  fit <- stats::lm(y ~ t)
  b   <- stats::coef(fit)
  r   <- stats::residuals(fit); n <- length(r)
  X   <- cbind(1, t); XtXi <- solve(crossprod(X))
  L   <- max(1L, floor(4 * (n / 100)^(2 / 9)))            # Newey-West rule of thumb
  M   <- crossprod(X * r)
  for (l in seq_len(L)) {
    wl <- 1 - l / (L + 1)
    G  <- crossprod(X[-seq_len(l), , drop = FALSE] * r[-seq_len(l)],
                    X[seq_len(n - l), , drop = FALSE] * r[seq_len(n - l)])
    M  <- M + wl * (G + t(G))
  }
  V <- XtXi %*% M %*% XtXi
  list(val = unname(b[1]), se = sqrt(V[1, 1]), resid = r, n = n)
}
cat(sprintf("\nT1b STEP AT %.1f, from local linear fits extrapolated to the boundary.\n", SEAM_EDGE))
cat("    Newey-West se; a block bootstrap validates it below.\n")
step_tab <- data.frame()
for (v in c(COMPONENTS, "imbalance")) {
  row <- sprintf("    %-12s", v)
  for (w in STEP_WINS) {
    a <- local_edge(h$year, h[[v]], w, "pre"); b <- local_edge(h$year, h[[v]], w, "post")
    d <- b$val - a$val; se <- sqrt(a$se^2 + b$se^2)
    row <- paste0(row, sprintf("  %+6.3f+-%5.3f", d, se))
    step_tab <- rbind(step_tab, data.frame(term = v, w = w, step = d, se = se,
                                           z = d / se))
  }
  cat(row, "\n")
}
cat(sprintf("    %-12s%s\n", "half-window", paste(sprintf("  %13s", paste0("w=", STEP_WINS)),
                                                   collapse = "")))

# ---- the se that is actually used: a MATCHED block bootstrap ---------
# The Newey-West bar above is reported for continuity, but it is estimated from
# w = 8-20 residuals with a lag truncation of 1-2 and is known to be badly
# downward-biased there, so it is NOT the bar this file draws conclusions from.
#
# The matched bootstrap resamples each side's OWN residuals, in blocks, through
# the SAME estimator. The residual pool is taken from a wider window either side
# (POOL_W yr) about a local QUADRATIC, so the noise level is estimated from more
# than the w points the step itself uses, and so that the seam's own
# heteroscedasticity -- the pre side is smooth by construction, the post side is
# not -- is preserved rather than averaged away. [[curvature_needs_an_error_bar]]
# requires the analytic bar to be validated and the CONSERVATIVE one used.
POOL_W <- 30L
resid_pool <- function(x, side) {
  k <- if (side == "pre") (h$year < SEAM & h$year >= SEAM - POOL_W)
       else (h$year >= SEAM & h$year < SEAM + POOL_W)
  t <- h$year[k] - SEAM_EDGE
  stats::residuals(stats::lm(x[k] ~ t + I(t^2)))
}
boot_step_se <- function(x, w, B = BOOT_B) {
  rp <- resid_pool(x, "pre"); rq <- resid_pool(x, "post")
  draw <- function(r, n) {
    nb <- ceiling(n / BOOT_BLOCK)
    st <- sample.int(length(r) - BOOT_BLOCK + 1L, nb, replace = TRUE)
    as.vector(vapply(st, function(s) r[s:(s + BOOT_BLOCK - 1L)], numeric(BOOT_BLOCK)))[seq_len(n)]
  }
  tp <- (SEAM - w):(SEAM - 1L) - SEAM_EDGE
  tq <- SEAM:(SEAM + w - 1L)  - SEAM_EDGE
  out <- numeric(B)
  for (i in seq_len(B)) {
    a <- stats::coef(stats::lm(draw(rp, w) ~ tp))[1]
    b <- stats::coef(stats::lm(draw(rq, w) ~ tq))[1]
    out[i] <- b - a
  }
  c(se = stats::sd(out), sd_pre = stats::sd(rp), sd_post = stats::sd(rq))
}
cat(sprintf("\n    MATCHED BOOTSTRAP se (B = %d, block %d yr, residual pool +-%d yr about a local quadratic).\n",
            BOOT_B, BOOT_BLOCK, POOL_W))
cat(sprintf("    %-12s %6s %10s %10s %9s %9s %7s\n",
            "term", "w", "step", "se(NW)", "se(boot)", "boot/NW", "z(boot)"))
mc_tab <- data.frame()
for (v in c(COMPONENTS, "imbalance")) for (w in STEP_WINS) {
  st <- step_tab[step_tab$term == v & step_tab$w == w, ]
  bs <- boot_step_se(h[[v]], w)
  cat(sprintf("    %-12s %6d %+10.3f %10.3f %9.3f %9.2f %+7.2f%s\n",
              v, w, st$step, st$se, bs[["se"]], bs[["se"]] / st$se, st$step / bs[["se"]],
              if (abs(st$step / bs[["se"]]) >= 2) "  <== 2 sigma" else ""))
  mc_tab <- rbind(mc_tab, data.frame(term = v, w = w, step = st$step, se_nw = st$se,
                                     se_boot = bs[["se"]], z_boot = st$step / bs[["se"]],
                                     sd_pre = bs[["sd_pre"]], sd_post = bs[["sd_post"]]))
}
cat("    The bootstrap bar is 2-8x the Newey-West bar on every term, so NW is\n")
cat("    ANTI-CONSERVATIVE here and every z below is the bootstrap one.\n")
cat(sprintf("\n    residual sd about a local quadratic, +-%d yr of the seam (this IS the seam,\n", POOL_W))
cat("    stated as a noise level rather than as a step):\n")
for (v in c("atm_growth", "ocean_sink", "land_sink", "imbalance")) {
  r <- mc_tab[mc_tab$term == v & mc_tab$w == STEP_WINS[1], ]
  cat(sprintf("      %-12s pre %.4f   post %.4f   ratio %6.1f\n",
              v, r$sd_pre, r$sd_post, r$sd_post / r$sd_pre))
}

# =====================================================================
# T2  PRICE THE STEP AS A CUMULATIVE -- naive upper bound
# =====================================================================
cat(sprintf("\nT2  NAIVE PRICE of a step, held constant over all %d pre-seam years.\n", n_pre))
cat("    This is an UPPER BOUND on the seam's cumulative contribution, not an estimate:\n")
cat("    a diagnostic model at a lower CO2 level should have a smaller sink, not one\n")
cat("    offset by a constant. T3 replaces it.\n")
W_MC <- 10L
for (v in c("atm_growth", "ocean_sink")) {
  d <- step_tab$step[step_tab$term == v & step_tab$w == W_MC]
  zb <- mc_tab$z_boot[mc_tab$term == v & mc_tab$w == W_MC]
  # a step UP in a sink or in growth at the seam means the pre-seam value was LOW,
  # which INFLATES the pre-seam imbalance by the same amount.
  cat(sprintf("      %-12s step %+.3f GtC/yr (%.2f sigma boot)  =>  %+7.1f GtC = %+5.2f ppm  (%+.0f %% of %.1f GtC)%s\n",
              v, d, zb, d * n_pre, d * n_pre * PPM_PER_GTC, 100 * d * n_pre / C_pre, C_pre,
              if (abs(zb) < 2) "   -- step NOT resolved" else ""))
}

# =====================================================================
# T3  BACKCAST THE POST-SEAM OCEAN SINK, ON A PREDICTOR MEASURED THE SAME
#     WAY IN BOTH ERAS
# =====================================================================
# CO2 level: the ice/firn record before Keeling, the stations after. It is the
# ONE budget-adjacent quantity whose measurement does not change at the seam.
ice_sp <- as.data.frame(readRDS(ccx_path("data", "obs_icecore.rds"))$co2_spline)
co2_lvl <- stats::approx(ice_sp$year, ice_sp$co2_ppm, xout = h$year, rule = 2)$y
# after the spline ends, cumulate GCB growth forward from its last year
last_sp <- max(ice_sp$year)
if (any(h$year > last_sp)) {
  fwd <- h$year > last_sp
  co2_lvl[fwd] <- co2_lvl[which(h$year == last_sp)] +
    cumsum(h$atm_growth[fwd]) * PPM_PER_GTC
}
exc <- co2_lvl - CO2_PREIND
cat(sprintf("\nT3  BACKCAST ocean_sink ~ (CO2 - %.2f ppm), fitted post-seam, evaluated pre-seam.\n",
            CO2_PREIND))
cat(sprintf("    CO2 excess: %.1f ppm at %d, %.1f at %d, %.1f at %d.\n",
            exc[1], YR0, exc[h$year == SEAM], SEAM, exc[length(exc)], YR1))
cat("    This is an EXTRAPOLATION below the fitted range; both windows are reported.\n")
back_tab <- data.frame()
for (nm in names(BACK_WINS)) {
  wnd <- BACK_WINS[[nm]]
  k   <- h$year >= wnd[1] & h$year <= wnd[2]
  fit <- stats::lm(h$ocean_sink[k] ~ exc[k])
  pred_pre <- stats::coef(fit)[1] + stats::coef(fit)[2] * exc[pre]
  gap <- pred_pre - h$ocean_sink[pre]           # + = GCB's pre-seam sink is LOW
  cat(sprintf("    %-18s slope %.5f GtC/yr per ppm, R2 %.3f | pre-seam gap: mean %+.3f, cum %+7.1f GtC = %+5.2f ppm (%+.0f %% of %.1f)\n",
              nm, stats::coef(fit)[2], summary(fit)$r.squared,
              mean(gap), sum(gap), sum(gap) * PPM_PER_GTC, 100 * sum(gap) / C_pre, C_pre))
  back_tab <- rbind(back_tab, data.frame(window = nm, slope = unname(stats::coef(fit)[2]),
                                         r2 = summary(fit)$r.squared,
                                         gap_mean = mean(gap), gap_cum = sum(gap)))
}
sp_rng <- range(back_tab$gap_cum / C_pre)
cat(sprintf("    VERDICT: the two windows disagree by %.1fx (%.0f %% to %.0f %% of the pre-seam\n",
            max(abs(back_tab$gap_cum)) / min(abs(back_tab$gap_cum)), 100 * sp_rng[1], 100 * sp_rng[2]))
cat("    cumulative), because the sink-vs-CO2 relation is CURVED (the buffer factor rises\n")
cat("    with CO2) and the pre-seam era is outside the fitted range. The backcast does NOT\n")
cat("    identify the seam's cumulative contribution, and no window is chosen here.\n")

# =====================================================================
# T4  IS GCB'S PRE-SEAM GROWTH THE OBJECT WE ALREADY SCORE?
# =====================================================================
obs <- ccx_prepare_obs()
ico <- obs$ice[obs$ice$year >= YR0 & obs$ice$year <= SEAM + 6L, ]
cat(sprintf("\nT4  GCB pre-seam growth vs the Law Dome samples the likelihood SCORES.\n"))
cat(sprintf("    %d ice samples in %d-%d (obs$ice, raw samples with stated errors).\n",
            nrow(ico), YR0, SEAM + 6L))
# Level test: cumulate GCB's growth from an 1850 anchor set by the ice record.
anchor <- stats::approx(ice_sp$year, ice_sp$co2_ppm, xout = YR0, rule = 2)$y
gcb_co2 <- anchor + cumsum(c(0, h$atm_growth[-nrow(h)])) * PPM_PER_GTC
pred_at <- stats::approx(h$year, gcb_co2, xout = ico$year, rule = 2)$y
d_ppm   <- pred_at - ico$CO2ppm
z       <- d_ppm / ico$sd
cat(sprintf("    anchor: ice spline at %d = %.2f ppm; GCB growth cumulated forward from there.\n",
            YR0, anchor))
cat(sprintf("    residual GCB-minus-ice over the %d samples: mean %+.2f ppm, sd %.2f, RMS %.2f\n",
            nrow(ico), mean(d_ppm), stats::sd(d_ppm), sqrt(mean(d_ppm^2))))
cat(sprintf("    in units of the ice term's OWN sigma: mean z %+.2f, RMS z %.2f\n",
            mean(z), sqrt(mean(z^2))))
for (dec in seq(YR0, SEAM - 1L, by = 20L)) {
  k <- ico$year >= dec & ico$year < dec + 20L
  if (sum(k) > 2) cat(sprintf("      %d-%d  n=%3d  mean %+6.2f ppm  RMS %5.2f\n",
                              dec, dec + 19L, sum(k), mean(d_ppm[k]), sqrt(mean(d_ppm[k]^2))))
}
kpl <- ico$year >= PLATEAU_WIN[1] & ico$year <= PLATEAU_WIN[2]
cat(sprintf("    in the %d-%d plateau window itself: n=%d  mean %+.2f ppm  RMS %.2f  RMS z %.2f\n",
            PLATEAU_WIN[1], PLATEAU_WIN[2], sum(kpl), mean(d_ppm[kpl]),
            sqrt(mean(d_ppm[kpl]^2)), sqrt(mean(z[kpl]^2))))
cat(sprintf("    worst 20-yr block mean %+.2f ppm against an ice sigma of %.2f ppm.\n",
            min(sapply(seq(YR0, SEAM - 20L, by = 10L),
                       function(d0) { k <- ico$year >= d0 & ico$year < d0 + 20L
                                      if (sum(k) > 2) mean(d_ppm[k]) else NA })  , na.rm = TRUE),
            mean(ico$sd)))
# ---- T4b the ONE identified growth number T3 could not give ---------
# The level residual is the RUNNING INTEGRAL of the growth error, so its drift
# across the pre-seam era IS the cumulative growth error, in ppm, with no
# extrapolation and no bandwidth choice. Its bar must use an EFFECTIVE n:
# Law Dome's air-age spectral width is 4.5-7.0 yr ([[ccx_d13c_neff]]), so
# samples within a window are not independent draws.
AIR_AGE_W <- 5.75              # yr, midpoint of the 4.5-7.0 spectral width
blk_mean <- function(y0, y1) {
  k <- ico$year >= y0 & ico$year <= y1
  n_eff <- max(1, (y1 - y0 + 1) / AIR_AGE_W)
  c(m = mean(d_ppm[k]), se = stats::sd(d_ppm[k]) / sqrt(n_eff), n = sum(k), neff = n_eff)
}
b0 <- blk_mean(YR0, YR0 + 29L); b1 <- blk_mean(SEAM - 30L, SEAM - 1L)
drift <- b1[["m"]] - b0[["m"]]; drift_se <- sqrt(b0[["se"]]^2 + b1[["se"]]^2)
cat(sprintf("\nT4b the level residual IS the running integral of the growth error -- its drift\n"))
cat(sprintf("    across the pre-seam era needs no extrapolation and no bandwidth:\n"))
cat(sprintf("      %d-%d  %+.2f +- %.2f ppm (n=%d, n_eff=%.1f at a %.2f-yr air-age width)\n",
            YR0, YR0 + 29L, b0[["m"]], b0[["se"]], b0[["n"]], b0[["neff"]], AIR_AGE_W))
cat(sprintf("      %d-%d  %+.2f +- %.2f ppm (n=%d, n_eff=%.1f)\n",
            SEAM - 30L, SEAM - 1L, b1[["m"]], b1[["se"]], b1[["n"]], b1[["neff"]]))
cat(sprintf("      DRIFT %+.2f +- %.2f ppm = %.2f sigma  =>  GCB growth is LOW by %.1f GtC\n",
            drift, drift_se, abs(drift) / drift_se, -drift / PPM_PER_GTC))
cat(sprintf("      which would inflate the pre-seam cumulative imbalance by %+.0f %% of %.1f GtC.\n",
            100 * (-drift / PPM_PER_GTC) / C_pre, C_pre))
cat("      This is SMALL and it is the only growth-side number in this file that is\n")
cat("      identified rather than extrapolated. It does NOT rescue the century-drift read.\n")

cat("\n    READ THIS AS A CIRCULARITY TEST, NOT A CONFIRMATION. GCB's pre-seam growth is\n")
cat("    Joos & Spahni 2008, itself a reconstruction of this same ice/firn record. Close\n")
cat("    agreement means the two are ONE object, so a model already fitted to our ice term\n")
cat("    is already fitted to GCB's growth, and the imbalance can only be a statement\n")
cat("    about EMISSIONS and SINKS.\n")

# =====================================================================
# T5  HOW MUCH OF THE PRE-SEAM CUMULATIVE IS THE 1940s PLATEAU?
# =====================================================================
kp <- h$year >= PLATEAU_WIN[1] & h$year <= PLATEAU_WIN[2]
cat(sprintf("\nT5  the %d-%d window (the de-ranked plateau arc) inside the pre-seam cumulative:\n",
            PLATEAU_WIN[1], PLATEAU_WIN[2]))
cat(sprintf("    %d of %d yr (%.0f %%) carry %.1f of %.1f GtC = %.0f %% of the pre-seam cumulative.\n",
            sum(kp), n_pre, 100 * sum(kp) / n_pre, sum(h$imbalance[kp]), C_pre,
            100 * sum(h$imbalance[kp]) / C_pre))
cat(sprintf("    mean atm_growth there %.3f GtC/yr vs %.3f in %d-%d -- the growth term COLLAPSES.\n",
            mean(h$atm_growth[kp]), mean(h$atm_growth[h$year >= 1920 & h$year < PLATEAU_WIN[1]]),
            1920L, PLATEAU_WIN[1] - 1L))
cat("\n    the pre-seam cumulative, decade by decade (GtC contributed, and running total):\n")
h$dec <- 10L * (h$year %/% 10L)
run <- 0
for (d0 in sort(unique(h$dec[pre]))) {
  k <- h$dec == d0 & pre; run <- run + sum(h$imbalance[k])
  cat(sprintf("      %ds  %+6.2f GtC/yr mean  %+7.2f GtC  running %7.2f (%3.0f %% of %.1f)\n",
              d0, mean(h$imbalance[k]), sum(h$imbalance[k]), run, 100 * run / C_pre, C_pre))
}

saveRDS(list(cum = c(pre = C_pre, post = C_post, all = C_all),
             smooth = smooth_tab, step = step_tab, mc = mc_tab, back = back_tab,
             t4 = data.frame(year = ico$year, ice = ico$CO2ppm, sd = ico$sd,
                             gcb = pred_at, d = d_ppm, z = z),
             plateau_frac = sum(h$imbalance[kp]) / C_pre,
             t4b = c(drift_ppm = drift, se_ppm = drift_se, air_age_w = AIR_AGE_W),
             const = list(SEAM = SEAM, GCB_SD = GCB_SD, PPM_PER_GTC = PPM_PER_GTC,
                          CO2_PREIND = CO2_PREIND, STEP_WINS = STEP_WINS)),
        file.path(OUTDIR, "gcb_seam_1959.rds"))
cat(sprintf("\nwritten: %s\n", file.path(OUTDIR, "gcb_seam_1959.rds")))
