#!/usr/bin/env Rscript
# diag_ice_d13c_sigma.R -- the NUMBERS for D4 (the sigma of the Law Dome ice-core d13C row) and
# the W2/W3 choices that ride with it, BEFORE objective #15 is assembled.
#
# Marcus 2026-10-02 ruled the row IN ("Add it in this refit") and the ice-core CO2 row CUT to
# pre-1958 ("Cut to pre-1958"); CHANGELOG 10-02 (z), plan notes/plan_2026-10-02_obj15_lag_iced13c.md
# W2/W3, handoff 10-02h sec. 2 (D4). Nothing here changes the objective. It measures:
#   S1 THE DATA. Rubino et al. 2019's d13C samples (data/obs_icecore.rds, the file the CO2 row
#      reads), their STATED errors, by era, under each candidate end year.
#   S2 SCATTER ABOUT RUBINO'S OWN SPLINE -- the sample-level noise the data themselves show
#      (measurement + firn/representation), by era. ⚠ The spline was fitted TO these samples,
#      so this UNDERSTATES independent noise somewhat; it is a floor, not a ceiling.
#   S3 ICE vs THE SOUTH POLE STATION in the overlap (SPO d13C starts 1977): the offset and the
#      scatter between two records of the SAME air -- the analog of the CO2 row's
#      "ice - SPO = -0.31 +- 0.15 ppm, 1962-96" (likelihood.R).
#   S4 THE CANONICAL'S RESIDUAL (hilda33d, its own spinup): model SH box vs each sample, read
#      exactly as the CO2 ice row reads co2_SH (approx on the monthly series at the sample's
#      year), by era; and the row's log-likelihood and chi2/n under each candidate sigma.
#   S5 CIRCULARITY: D13C_PI (R/constants.R) is the Law Dome SPLINE's 1745-1755 mean and the
#      spinup PINS the 1750 atmosphere to it (spinup.R / periodic_spinup.R `d13c0`). Which
#      samples sit in that window, and what the model reads there.
#   S6 W3: the CO2 ice row before and after the pre-1958 cut, at the canonical.
# No RNG. Run from the repo root:  Rscript calibration/diag_ice_d13c_sigma.R
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) ----------------
ARM              <- "hilda33d"                  # the canonical, via ccx_mode_file()
END_DESIGN       <- 1990                        # DESIGN.md sec. 4: "pre-1990 Suess target"
END_STATION      <- 1977                        # SPO d13C's first year (data/obs_d13c_monthly.rds)
CO2_CUT          <- 1958                        # W3, RULED 10-02: ice CO2 scored only before this year
ANCHOR_WIN       <- c(1745, 1755)               # R/constants.R D13C_PI: the spline's mean over this
ERAS             <- c(1750, 1850, 1900, 1958, 1977, 1990, 2000)
REP_CANDIDATES   <- c(station_rep = LIK_D13C_REP_ERR)   # the station rows' own floor, 0.05 permil
OUT_STEM         <- file.path("outputs", "diagnostics", sprintf("ice_d13c_sigma_%s", format(Sys.Date(), "%Y%m%d")))
DRIVER           <- "calibration/diag_ice_d13c_sigma.R"

commit <- ccx_git_stamp()
dirty  <- ccx_stamp_dirty(commit)   # the rds keeps `dirty`: TRUE / FALSE / NA = git could not tell
sink(paste0(OUT_STEM, ".log"), split = TRUE)
cat(sprintf("%s @%s, %s | arm %s\n\n", DRIVER, commit,
            format(Sys.time(), "%Y-%m-%d %H:%M"), ARM))

ice <- readRDS(ccx_path("data", "obs_icecore.rds"))
d <- as.data.frame(ice$d13c_samples)
d <- data.frame(id = d$SampleID, firn = d$age_ice == "firn", year = d$age_CO2,
                d13c = d$d13CO2, err = d$d13CO2err)
d <- d[order(d$year), ]
sp <- as.data.frame(ice$d13c_spline)
d$spline <- stats::approx(sp$year, sp$d13c, xout = d$year)$y
era <- function(y) cut(y, ERAS, right = FALSE, dig.lab = 4)
inrun <- d$year >= ERAS[1]

# ---- S1 the data ---------------------------------------------------------------
cat("=== S1. Rubino et al. 2019 d13C samples (data/obs_icecore.rds) ===\n")
cat(sprintf("all %d samples, %d-%d; %d before %d (outside the run); %d firn-air samples\n",
            nrow(d), min(d$year), max(d$year), sum(!inrun), ERAS[1], sum(d$firn)))
for (end in c(END_STATION, END_DESIGN, Inf)) {
  k <- inrun & d$year < end
  cat(sprintf("  in-run, year < %-4s : n = %3d | stated err mean %.3f, median %.3f, max %.3f permil\n",
              if (is.finite(end)) end else "all", sum(k), mean(d$err[k]), stats::median(d$err[k]), max(d$err[k])))
}
cat("  by era (in-run):\n")
print(aggregate(cbind(n = 1, err_mean = err) ~ era(year), d[inrun, ],
                function(x) if (all(x == 1)) sum(x) else round(mean(x), 3)), row.names = FALSE)

# ---- S2 scatter about the spline ----------------------------------------------
cat("\n=== S2. Sample scatter about Rubino's own spline (a FLOOR on sample-level noise) ===\n")
d$res_spline <- d$d13c - d$spline
s2 <- aggregate(res_spline ~ era(year), d[inrun, ], function(x) c(n = length(x), mean = mean(x), sd = stats::sd(x)))
print(do.call(data.frame, s2), digits = 3, row.names = FALSE)
s2_all <- stats::sd(d$res_spline[inrun & d$year < END_DESIGN])
s2_pre <- stats::sd(d$res_spline[inrun & d$year < END_STATION])
cat(sprintf("  pooled sd: year < %d %.4f | year < %d %.4f permil (in-run)\n", END_STATION, s2_pre, END_DESIGN, s2_all))
cat(sprintf("  stated-error RMS over the same samples: %.4f / %.4f -> excess (quadrature) %.4f / %.4f\n",
            sqrt(mean(d$err[inrun & d$year < END_STATION]^2)), sqrt(mean(d$err[inrun & d$year < END_DESIGN]^2)),
            sqrt(max(s2_pre^2 - mean(d$err[inrun & d$year < END_STATION]^2), 0)),
            sqrt(max(s2_all^2 - mean(d$err[inrun & d$year < END_DESIGN]^2), 0))))

# ---- S3 ice vs the stations in the overlap ------------------------------------
cat("\n=== S3. Ice vs the station records over their overlap (the same air, two methods) ===\n")
obs <- ccx_prepare_obs()
for (st in c("SPO", "MLO")) {
  h <- obs$d13_ann[[st]]
  if (is.null(h)) next
  k <- match(d$year, h$year); g <- !is.na(k)
  if (!any(g)) next
  dd <- d$d13c[g] - h$level[k[g]]
  cat(sprintf("  ice - %s annual level: n = %d (%d-%d) | mean %+.4f, sd %.4f, RMS %.4f permil\n",
              st, sum(g), min(d$year[g]), max(d$year[g]), mean(dd), stats::sd(dd), sqrt(mean(dd^2))))
}
cat("  (the CO2 analogue, likelihood.R: ice - SPO = -0.31 +- 0.15 ppm over 1962-96)\n")

# ---- S4 the canonical's residual ------------------------------------------------
cat(sprintf("\n=== S4. The canonical %s: model SH box vs the samples (read as the CO2 ice row reads co2_SH) ===\n", ARM))
v <- dg_vector(ARM)
cat(sprintf("  vector: %s | spinup %s | migrated: %s\n", v$src, v$spinup_label,
            if (length(v$migrated)) paste(v$migrated, collapse = ",") else "none"))
r <- dg_run(v); out <- r$out
d$model <- stats::approx(out$t, out$d13c_SH, xout = d$year, rule = 2)$y
d$res_model <- d$d13c - d$model
s4 <- aggregate(res_model ~ era(year), d[inrun, ], function(x) c(n = length(x), mean = mean(x), sd = stats::sd(x),
                                                                  rms = sqrt(mean(x^2))))
print(do.call(data.frame, s4), digits = 3, row.names = FALSE)
cands <- list(stated_only = function(e) e)
for (nm in names(REP_CANDIDATES)) local({ rr <- REP_CANDIDATES[[nm]]; cands[[nm]] <<- function(e) sqrt(e^2 + rr^2) })
cands$spline_scatter <- function(e) sqrt(e^2 + s2_all^2)
cat("\n  the row under each candidate sigma (model at the canonical, nothing refitted):\n")
cat(sprintf("  %-16s %-8s %4s %12s %10s %10s\n", "sigma", "end", "n", "logL", "chi2/n", "mean|z|"))
tab4 <- NULL
for (nm in names(cands)) for (end in c(END_STATION, END_DESIGN)) {
  k <- inrun & d$year < end; s <- cands[[nm]](d$err[k]); z <- d$res_model[k] / s
  ll <- sum(stats::dnorm(d$d13c[k], d$model[k], s, log = TRUE))
  cat(sprintf("  %-16s < %-6d %4d %12.2f %10.2f %10.2f\n", nm, end, sum(k), ll, mean(z^2), mean(abs(z))))
  tab4 <- rbind(tab4, data.frame(sigma = nm, end = end, n = sum(k), logL = ll, chi2_n = mean(z^2)))
}
cat(sprintf("  (for scale: the station d13C level rows score %d + %d annual points at sd %.2f permil)\n",
            nrow(obs$d13_ann$MLO), nrow(obs$d13_ann$SPO), LIK_D13C_REP_ERR))

# ---- S5 circularity --------------------------------------------------------------
cat("\n=== S5. Circularity with the pre-industrial anchor D13C_PI ===\n")
cat(sprintf("  D13C_PI = %.3f permil: %s\n", ccx_const("D13C_PI"),
            CCX_CONSTANTS$D13C_PI$source))
k <- d$year >= ANCHOR_WIN[1] & d$year <= ANCHOR_WIN[2]
cat(sprintf("  samples inside the anchor window %d-%d: %d (%s); in-run of those: %d\n", ANCHOR_WIN[1], ANCHOR_WIN[2],
            sum(k), paste(sprintf("%d: %.2f", d$year[k], d$d13c[k]), collapse = ", "), sum(k & inrun)))
cat(sprintf("  the model at %d (the spinup's pinned instant): %.4f permil\n", ERAS[1],
            stats::approx(out$t, out$d13c_SH, xout = ERAS[1], rule = 2)$y))

# ---- S6 W3: the CO2 ice row before / after the cut --------------------------------
cat(sprintf("\n=== S6. W3: the CO2 ice row at the canonical, all in-run samples vs year < %d ===\n", CO2_CUT))
oi <- obs$ice; inr <- oi$year >= floor(min(out$t) + 1e-9)
mod <- stats::approx(out$t, out$co2_SH, xout = oi$year, rule = 2)$y
ll <- function(k) sum(stats::dnorm(oi$CO2ppm[k], mod[k], oi$sd[k], log = TRUE))
kc <- inr & oi$year < CO2_CUT
cat(sprintf("  all in-run: n = %d, logL %.2f | year < %d: n = %d, logL %.2f | the cut rows: n = %d, logL %.2f\n",
            sum(inr), ll(inr), CO2_CUT, sum(kc), ll(kc), sum(inr & !kc), ll(inr & !kc)))
res_cut <- oi$CO2ppm[inr & !kc] - mod[inr & !kc]
cat(sprintf("  the cut rows' residual (obs - model): mean %+.2f, sd %.2f ppm (sigma %.2f)\n",
            mean(res_cut), stats::sd(res_cut), mean(oi$sd[inr & !kc])))

saveRDS(list(samples = d, scatter_spline = s2, model_resid = s4, row_candidates = tab4,
             provenance = list(driver = DRIVER, commit = commit, dirty = dirty, arm = ARM, src = v$src,
                               spinup = v$spinup_label, end_design = END_DESIGN, end_station = END_STATION,
                               co2_cut = CO2_CUT, anchor_win = ANCHOR_WIN, rng = "none",
                               date = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(OUT_STEM, ".rds"))
cat(sprintf("\nprovenance: %s @%s; arm %s (%s spinup); data/obs_icecore.rds (Rubino et al. 2019); no RNG\n",
            DRIVER, commit, ARM, v$spinup_label))
sink()
