# =====================================================================
# diag_seas8_lead_obs_20261021.R -- T8d: is the observed MLO d13C lead real, and is it what
# costs the d13C seasonal row its 18.1 log-units in the joint fit?
#
# WHY (2026-10-21). (t) attributed the CO2/d13C seasonal conflict to timing: observed MLO d13C
# leads CO2's antiphase by 0.144 mo (4.4 days) and the model cannot open the lead. That came from
# ELIMINATION (holding eps at 18.35 left the loss at 17.2) plus the phase numbers, never from a
# direct test. Marcus: "I'm surprised that a 4 day offset at Mauna Loa matters for a monthly
# model." Two tests he chose ("Run tests 1 and 2"):
#
#   TEST 1, MAGNITUDE AND SIGN. Per-year leads (each year's d13C peak minus CO2's trough, on the
#     likelihood's own per-year harmonics): their sd, how many years show a lead, and the row's
#     sigma in days. Then the d13C MLO row's joint-vs-d13C-only difference (stored streams, T8c)
#     split EXACTLY into a mean-vector part -- itself split into rotation (phase) and scaling
#     (amplitude), both orders -- and the year-to-year remainder. Prediction if the attribution
#     holds: the rotation part carries most of the 18.1.
#   TEST 2, SAMPLING. The same lead from CO2 measured on the SAME flasks as the d13C (Scripps flask
#     CO2 x Scripps flask d13C), from the NOAA flask programme (NOAA flask CO2 x INSTAAR d13C), and
#     the cross pairs; plus same-tracer phase differences between products. Prediction if the lead
#     is a CO2-sampling artefact: it vanishes in the same-flask pairs.
#
# ESTIMATOR. ccx_year_harmonic() (level + trend + first harmonic per calendar year, >= 9 months),
# inside LIK_SEAS_WINDOW, exactly what the seasonal rows score. "Lead" = phase(d13C) minus the
# phase of -CO2, wrapped to (-6, 6] months; negative = d13C early. Month 0 = 1 Jan. A pairing's
# headline lead is from the MEAN vectors over its common years (the row's and (t)'s estimator);
# the per-year leads give its spread. se = sd / sqrt(N), and an AR(1)-inflated se from the per-year
# leads' lag-1 autocorrelation. No RNG.
#
# DATA. The calibration's own monthly frames (data/obs_co2_monthly.rds, data/obs_d13c_monthly.rds,
# built by data-raw/build_calibration_data.R from column 5 of the Scripps files, "adjusted to 24:00
# hours on the 15th of each month", and the NOAA monthly files), plus the NOAA flask CO2 monthly file
# at MLO, which the calibration does not read (data-raw/downloads/noaa_flask_monthly/, md5 recorded).
#
# Usage: Rscript calibration/diag_seas8_lead_obs_20261021.R > <S8_OUT_DIR>/t8d_lead_obs_<mode>.log
# =====================================================================
for (.lf in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(.lf)
source(file.path("calibration", "lib_seas8_20261021.R"))

S8D_DRIVER  <- "calibration/diag_seas8_lead_obs_20261021.R"
S8D_COMMIT  <- ccx_git_stamp()
S8D_STATION <- "MLO"
S8D_DAYS_MO <- 365.25 / 12                   # days per month, for the day-scale readings
S8D_NOAA_FLASK_CO2 <- file.path("data-raw", "downloads", "noaa_flask_monthly",
                                "co2_mlo_surface-flask_1_ccgg_month.txt")
S8D_T8C     <- file.path(S8_OUT_DIR, sprintf("t8c_split_%s.rds", S8_MODE))
S8D_ROW     <- "d13c_seasonal_MLO"
S8D_STEM    <- file.path(S8_OUT_DIR, sprintf("t8d_lead_obs_%s", S8_MODE))
say <- function(...) { cat(sprintf(...)); flush.console() }
say("=== %s @%s, %s ===\n", S8D_DRIVER, S8D_COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"))
say("estimator: ccx_year_harmonic() per calendar year (>= %d months), window %d-%d (LIK_SEAS_WINDOW)\n",
    LIK_ANNUAL_MIN_MONTHS, LIK_SEAS_WINDOW[1], LIK_SEAS_WINDOW[2])

# ---- the series ---------------------------------------------------------------------------------
co2m <- as.data.frame(readRDS(ccx_path("data", "obs_co2_monthly.rds")))
d13m <- as.data.frame(readRDS(ccx_path("data", "obs_d13c_monthly.rds")))
ln <- readLines(S8D_NOAA_FLASK_CO2); ln <- ln[!grepl("^#", ln) & nzchar(trimws(ln))]
nf <- utils::read.table(text = ln, col.names = c("site", "year", "month", "co2_ppm"))
if (!all(nf$site == S8D_STATION)) stop("the NOAA flask file holds a site other than ", S8D_STATION)
nf$decimal_date <- nf$year + (nf$month - 0.5) / 12      # as build_calibration_data.R dates NOAA monthly files
SER <- list(
  co2_sio_insitu = co2m[co2m$station == "MLO",           c("decimal_date", "co2_ppm")],
  co2_sio_flask  = co2m[co2m$station == "MLO_SIO_FLASK", c("decimal_date", "co2_ppm")],
  co2_noaa_insitu = co2m[co2m$station == "MLO_NOAA",     c("decimal_date", "co2_ppm")],
  co2_noaa_flask = nf[, c("decimal_date", "co2_ppm")],
  d13_sio_flask  = d13m[d13m$station == "MLO",           c("decimal_date", "d13c")],
  d13_instaar_flask = d13m[d13m$station == "MLO_NOAA",   c("decimal_date", "d13c")])
SER_LABEL <- c(co2_sio_insitu = "Scripps in situ CO2 (the CO2 row)",
               co2_sio_flask = "Scripps flask CO2 (same flasks as the d13C row)",
               co2_noaa_insitu = "NOAA in situ CO2",
               co2_noaa_flask = "NOAA flask CO2 (same programme as INSTAAR d13C)",
               d13_sio_flask = "Scripps flask d13C (the d13C row)",
               d13_instaar_flask = "INSTAAR flask d13C (NOAA flasks)")
H <- lapply(SER, function(s) {
  h <- ccx_year_harmonic(s[[1]], s[[2]])
  h[h$year >= LIK_SEAS_WINDOW[1] & h$year <= LIK_SEAS_WINDOW[2], ]
})
say("\n=== 0. SERIES (years scored inside the window) ===\n")
for (n in names(H)) say("  %-18s %-48s %d-%d  N %d\n", n, SER_LABEL[[n]], min(H[[n]]$year), max(H[[n]]$year), nrow(H[[n]]))

# gate: the primary pair reproduces the row's own per-year harmonics
obs <- ccx_prepare_obs()
o13 <- obs$d13_seas[[S8D_STATION]]; oco <- obs$co2_seas[[S8D_STATION]]
g1 <- max(abs(c(H$d13_sio_flask$a - o13$a[match(H$d13_sio_flask$year, o13$year)],
                H$d13_sio_flask$b - o13$b[match(H$d13_sio_flask$year, o13$year)],
                H$co2_sio_insitu$a - oco$a[match(H$co2_sio_insitu$year, oco$year)],
                H$co2_sio_insitu$b - oco$b[match(H$co2_sio_insitu$year, oco$year)])), na.rm = TRUE)
g1n <- all(H$d13_sio_flask$year %in% o13$year) && all(o13$year %in% H$d13_sio_flask$year)
say("GATE O: the primary series' per-year coefficients equal ccx_prepare_obs()'s (max |diff| %.1e, same years %s) -> %s\n",
    g1, g1n, if (g1 == 0 && g1n) "PASS" else "FAIL")
if (!(g1 == 0 && g1n)) stop("the driver's harmonics are not the likelihood's")

# ---- leads -------------------------------------------------------------------------------------
lead_tab <- function(hc, hd, yrs = NULL) {
  y <- intersect(hc$year, hd$year); if (!is.null(yrs)) y <- intersect(y, yrs)
  kc <- match(y, hc$year); kd <- match(y, hd$year)
  vc <- c(mean(hc$a[kc]), mean(hc$b[kc])); vd <- c(mean(hd$a[kd]), mean(hd$b[kd]))
  per <- mapply(function(ac, bc, ad, bd) s8_dmo(s8_ang_mo(c(ad, bd)), s8_ang_mo(-c(ac, bc))),
                hc$a[kc], hc$b[kc], hd$a[kd], hd$b[kd])
  n <- length(per); sdv <- stats::sd(per)
  rho <- if (n > 3) stats::cor(per[-1], per[-n]) else NA_real_
  se <- sdv / sqrt(n)
  list(years = y, per_year = per,
       summ = data.frame(N = n, first = min(y), last = max(y),
                         lead_meanvec = s8_dmo(s8_ang_mo(vd), s8_ang_mo(-vc)),
                         lead_mean = mean(per), sd = sdv, se = se, rho1 = rho,
                         se_ar1 = se * sqrt((1 + max(rho, 0)) / (1 - max(rho, 0))),
                         frac_lead = mean(per < 0), median = stats::median(per)))
}
PAIRS <- list(
  P0_primary          = c("co2_sio_insitu", "d13_sio_flask"),
  P1_sio_same_flask   = c("co2_sio_flask", "d13_sio_flask"),
  P2_noaa_same_flask  = c("co2_noaa_flask", "d13_instaar_flask"),
  P3_noaa_insitu_x_sio = c("co2_noaa_insitu", "d13_sio_flask"),
  P4_sio_insitu_x_instaar = c("co2_sio_insitu", "d13_instaar_flask"))
common <- Reduce(intersect, lapply(H, `[[`, "year"))
LEAD <- list(own = list(), common = list())
fmt_row <- function(nm, s) say("  %-24s N %2d (%d-%d) | mean-vector %+.3f mo (%+.1f d) | per-year mean %+.3f, sd %.3f (%.1f d), se %.3f, AR1 se %.3f (rho %+.2f) | %2.0f%% of years lead\n",
                               nm, s$N, s$first, s$last, s$lead_meanvec, s$lead_meanvec * S8D_DAYS_MO,
                               s$lead_mean, s$sd, s$sd * S8D_DAYS_MO, s$se, s$se_ar1, s$rho1, 100 * s$frac_lead)
say("\n=== TEST 2a. THE LEAD BY PAIRING (negative = d13C early), each on its own common years ===\n")
for (nm in names(PAIRS)) { LEAD$own[[nm]] <- lead_tab(H[[PAIRS[[nm]][1]]], H[[PAIRS[[nm]][2]]]); fmt_row(nm, LEAD$own[[nm]]$summ) }
say("\n=== TEST 2b. THE SAME PAIRINGS on the years every series has (%d-%d, N %d) ===\n", min(common), max(common), length(common))
for (nm in names(PAIRS)) { LEAD$common[[nm]] <- lead_tab(H[[PAIRS[[nm]][1]]], H[[PAIRS[[nm]][2]]], common); fmt_row(nm, LEAD$common[[nm]]$summ) }

say("\n=== TEST 2c. SAME-TRACER PHASE DIFFERENCES between products (paired by year; positive = first one later) ===\n")
phase_diff <- function(h1, h2, flip = FALSE) {
  y <- intersect(h1$year, h2$year); k1 <- match(y, h1$year); k2 <- match(y, h2$year)
  d <- mapply(function(a1, b1, a2, b2) s8_dmo(s8_ang_mo(c(a1, b1)), s8_ang_mo(c(a2, b2))), h1$a[k1], h1$b[k1], h2$a[k2], h2$b[k2])
  mv <- s8_dmo(s8_ang_mo(c(mean(h1$a[k1]), mean(h1$b[k1]))), s8_ang_mo(c(mean(h2$a[k2]), mean(h2$b[k2]))))
  data.frame(N = length(y), first = min(y), last = max(y), meanvec = mv, mean = mean(d), sd = stats::sd(d),
             se = stats::sd(d) / sqrt(length(d)))
}
SAME <- list(
  co2_sio_flask_minus_insitu   = c("co2_sio_flask", "co2_sio_insitu"),
  co2_noaa_flask_minus_insitu  = c("co2_noaa_flask", "co2_noaa_insitu"),
  co2_noaa_insitu_minus_sio_insitu = c("co2_noaa_insitu", "co2_sio_insitu"),
  co2_noaa_flask_minus_sio_flask = c("co2_noaa_flask", "co2_sio_flask"),
  d13_instaar_minus_sio        = c("d13_instaar_flask", "d13_sio_flask"))
SAMED <- lapply(SAME, function(p) phase_diff(H[[p[1]]], H[[p[2]]]))
for (nm in names(SAMED)) { s <- SAMED[[nm]]
  say("  %-34s N %2d (%d-%d) | mean-vector %+.3f mo (%+.1f d) | per-year mean %+.3f, sd %.3f, se %.3f\n",
      nm, s$N, s$first, s$last, s$meanvec, s$meanvec * S8D_DAYS_MO, s$mean, s$sd, s$se) }

say("\n=== TEST 2d. BY DECADE (mean-vector, Scripps; own years): the primary lead, the same-flask lead, and flask minus in situ CO2 ===\n")
DEC <- do.call(rbind, lapply(seq(1980, 2020, 10), function(d0) {
  y <- intersect(LEAD$own$P0_primary$years, d0:(d0 + 9)); if (length(y) < 3) return(NULL)
  s0 <- lead_tab(H$co2_sio_insitu, H$d13_sio_flask, y)$summ
  s1 <- lead_tab(H$co2_sio_flask, H$d13_sio_flask, y)$summ
  hf <- H$co2_sio_flask[H$co2_sio_flask$year %in% y, ]; hi <- H$co2_sio_insitu[H$co2_sio_insitu$year %in% y, ]
  fd <- phase_diff(hf, hi)
  data.frame(decade = d0, N = s0$N, lead_primary = s0$lead_meanvec, se_primary = s0$se,
             lead_same_flask = s1$lead_meanvec, se_same_flask = s1$se, N_same_flask = s1$N,
             co2_flask_minus_insitu = fd$meanvec, se_flask_minus_insitu = fd$se)
}))
for (i in seq_len(nrow(DEC))) with(DEC[i, ], say(
  "  %ds N %2d | primary %+.3f (%+.1f d) se %.3f | same-flask %+.3f (%+.1f d) se %.3f | CO2 flask - in situ %+.3f (%+.1f d) se %.3f\n",
  decade, N, lead_primary, lead_primary * S8D_DAYS_MO, se_primary, lead_same_flask, lead_same_flask * S8D_DAYS_MO,
  se_same_flask, co2_flask_minus_insitu, co2_flask_minus_insitu * S8D_DAYS_MO, se_flask_minus_insitu))

# ---- TEST 1: the row's sigma, and what the 18.1 is made of -------------------------------------
say("\n=== TEST 1a. THE ROW'S SIGMA AND THE PER-YEAR SCATTER (%s) ===\n", S8D_ROW)
ob <- c(o13$a_mean, o13$b_mean); A2 <- sqrt(sum(ob^2))          # half-amplitude of the mean vector
sig <- c(o13$sd_a, o13$sd_b); N13 <- o13$n_years
sig_days <- sig / A2 * 12 / (2 * pi) * S8D_DAYS_MO               # a rotation of one sigma, in days
ph_d13 <- vapply(seq_len(nrow(H$d13_sio_flask)), function(i) s8_ang_mo(c(H$d13_sio_flask$a[i], H$d13_sio_flask$b[i])), 0)
ph_co2 <- vapply(seq_len(nrow(H$co2_sio_insitu)), function(i) s8_ang_mo(c(H$co2_sio_insitu$a[i], H$co2_sio_insitu$b[i])), 0)
circ_sd <- function(ph) { z <- exp(1i * 2 * pi * ph / 12); sqrt(-2 * log(Mod(mean(z)))) * 12 / (2 * pi) }
say("  N %d years; observed d13C %.4f permil peak-to-peak (half-amplitude %.4f) @ %.2f mo\n", N13, 2 * A2, A2, s8_ang_mo(ob))
say("  sigma: sd_a %.4f, sd_b %.4f permil = %.1f, %.1f days of phase at that amplitude\n", sig[1], sig[2], sig_days[1], sig_days[2])
say("  per-year phase scatter (circular sd): d13C %.3f mo (%.1f d), CO2 %.3f mo (%.1f d), the lead %.3f mo (%.1f d)\n",
    circ_sd(ph_d13), circ_sd(ph_d13) * S8D_DAYS_MO, circ_sd(ph_co2), circ_sd(ph_co2) * S8D_DAYS_MO,
    LEAD$own$P0_primary$summ$sd, LEAD$own$P0_primary$summ$sd * S8D_DAYS_MO)
rot <- function(v, dmo) { th <- -2 * pi * dmo / 12; c(v[1] * cos(th) - v[2] * sin(th), v[1] * sin(th) + v[2] * cos(th)) }
chk_rot <- s8_dmo(s8_ang_mo(rot(ob, 0.1)), s8_ang_mo(ob))
if (abs(chk_rot - 0.1) > 1e-12) stop("rot() does not move the peak by +dmo months")
cost_mv <- function(m) N13 / 2 * sum(((ob - m) / sig)^2)          # the mean-vector part of -logL (exact for per-year Gaussians)
say("  first principles: a pure phase error of D months at the observed amplitude costs N/2 * |dv / sigma|^2:\n")
for (D in c(0.05, -LEAD$own$P1_sio_same_flask$summ$lead_meanvec, 0.10, -LEAD$own$P0_primary$summ$lead_meanvec, 0.166, 0.25)) say("    D %.3f mo (%.1f d): %.2f log-units\n", D, D * S8D_DAYS_MO, cost_mv(rot(ob, D)))

say("\n=== TEST 1b. THE JOINT FIT'S LOSS ON %s, SPLIT (T8c, %s) ===\n", S8D_ROW, basename(S8D_T8C))
T8 <- readRDS(S8D_T8C)
if (!identical(T8$provenance$mode, S8_MODE)) stop("T8c was run at ", T8$provenance$mode)
vj <- T8$cycles$B_iii$d13_MLO; vd <- T8$cycles$B_ii$d13_MLO; vc <- T8$cycles$B_i$d13_MLO; vm <- T8$cycles$mode$d13_MLO
if (!isTRUE(all.equal(T8$cycles$obs$d13_MLO, ob, tolerance = 1e-12)))
  stop("T8c's observed MLO d13C vector is not this row's mean vector (years differ?)")
row_of <- function(s) unname(T8$best[[s]]$streams[[S8D_ROW]])
dl_row <- row_of("B_iii") - row_of("B_ii")                        # joint minus d13C-only, as (s) reports
say("  row: joint %.3f, d13C-only %.3f, CO2-only %.3f -> joint - d13C-only %+.3f\n", row_of("B_iii"), row_of("B_ii"), row_of("B_i"), dl_row)
for (s in c("obs", "mode", "B_i", "B_ii", "B_iii")) { v <- T8$cycles[[s]]$d13_MLO
  say("  %-5s d13C %.4f @ %.3f mo | vs obs: amplitude x%.3f, phase %+.3f mo | mean-vector cost %.2f\n", s, s8_amp(v), s8_ang_mo(v),
      sqrt(sum(v^2)) / A2, s8_dmo(s8_ang_mo(v), s8_ang_mo(ob)), cost_mv(v)) }
mv_part <- -(cost_mv(vj) - cost_mv(vd))                            # in logL units, joint minus d13C-only
rem     <- dl_row - mv_part
dph <- s8_dmo(s8_ang_mo(vd), s8_ang_mo(vj)); sc <- sqrt(sum(vd^2)) / sqrt(sum(vj^2))
p1_rot <- -(cost_mv(vj) - cost_mv(rot(vj, dph)))                   # order 1: rotate J to D's phase, then scale
p1_sc  <- -(cost_mv(rot(vj, dph)) - cost_mv(vd))
p2_sc  <- -(cost_mv(vj) - cost_mv(vj * sc))                        # order 2: scale first, then rotate
p2_rot <- -(cost_mv(vj * sc) - cost_mv(vd))
if (abs(s8_dmo(s8_ang_mo(rot(vj * sc, dph)), s8_ang_mo(vd))) > 1e-9 || max(abs(rot(vj * sc, dph) - vd)) > 1e-12)
  stop("the rotation-and-scaling path does not land on the d13C-only vector")
say("  joint vs d13C-only: phase %+.3f mo (%+.1f d), amplitude x%.3f\n", dph, dph * S8D_DAYS_MO, sc)
say("  the joint fit's loss %+.3f = mean-vector part %+.3f + year-to-year remainder %+.3f\n", dl_row, mv_part, rem)
say("    mean-vector part, rotate then scale: phase %+.3f, amplitude %+.3f\n", p1_rot, p1_sc)
say("    mean-vector part, scale then rotate: amplitude %+.3f, phase %+.3f\n", p2_sc, p2_rot)

saveRDS(list(series = SER_LABEL, harmonics = H, lead = LEAD, same_tracer = SAMED, decades = DEC,
             sigma = list(sd = sig, days = sig_days, n_years = N13, obs_vec = ob, half_amp = A2,
                          phase_sd_mo = c(d13 = circ_sd(ph_d13), co2 = circ_sd(ph_co2))),
             split = list(row = S8D_ROW, joint = row_of("B_iii"), d13_only = row_of("B_ii"), loss = dl_row,
                          mean_vector = mv_part, remainder = rem, dphase_mo = dph, amp_ratio = sc,
                          rotate_then_scale = c(phase = p1_rot, amplitude = p1_sc),
                          scale_then_rotate = c(amplitude = p2_sc, phase = p2_rot)),
             provenance = list(driver = S8D_DRIVER, commit = S8D_COMMIT, mode = S8_MODE, t8c = S8D_T8C,
                               t8c_commit = T8$provenance$commit,
                               inputs_md5 = tools::md5sum(c(ccx_path("data", "obs_co2_monthly.rds"),
                                                            ccx_path("data", "obs_d13c_monthly.rds"),
                                                            S8D_NOAA_FLASK_CO2)),
                               estimator = "ccx_year_harmonic(), LIK_SEAS_WINDOW", window = LIK_SEAS_WINDOW,
                               min_months = LIK_ANNUAL_MIN_MONTHS, rng = "none",
                               units = "months (day readings at 365.25/12 d per month); permil; ppm; log-units",
                               built = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(S8D_STEM, ".rds"))
say("\nwrote %s.rds\n", S8D_STEM)
