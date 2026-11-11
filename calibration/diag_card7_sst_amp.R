#!/usr/bin/env Rscript
# =====================================================================
# diag_card7_sst_amp.R -- card 7 vs What pins down what? on the seasonal SST amplitude (group B item B21, 2026-11-11).
#
# WHY. Card 7: "The stand-ins that matter most for what this app claims are the station offset (issue 1), the δ¹³C
# gradient offset (issue 2 is scored net of it), and a seasonal sea-surface-temperature amplitude fitted well under the
# observed one." What pins down what?'s paragraph "Some parameters have little influence on the model, and are not
# well constrained by observations, such as ..." lists the three lowest-leverage model parameters on the map, which at
# hilda31fl begin with the two SST seasonal swings. The two texts measure different things -- how far a stand-in sits
# from its measurement, and how much a one-sd move changes the fit -- so both can be true; this driver puts the
# numbers for each side next to each other at the canonical.
#
# WHAT. (1) The fitted half-amplitudes against ERSSTv5's (SST_SEAS_AMP_*_OBS in R/constants.R) and against their
# Laplace sd. (2) Their rank on the map (data/constraint_map.rds), with the app's own "quiet" computation re-stated.
# (3) Forward runs (dg path, everything else at the mode): each amplitude at its fitted value, at the observed value,
# and at zero; per run the likelihood change by row family and the seasonal cycle the Keeling tab draws (the mean
# one-harmonic fit of the NH box over the seasonal window, and the SH box's) against the stations'. A raw move
# overstates the cost of the observed value, because nothing else is allowed to compensate; it is an upper bound.
#
# Usage: Rscript calibration/diag_card7_sst_amp.R     # ~1 min, read-only, no RNG
# =====================================================================
t_start <- Sys.time()
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp(); source(ccx_path("calibration", "lib_design_gates.R"))

# ---- named constants ------------------------------------------------------------
SA_DRIVER <- "calibration/diag_card7_sst_amp.R"
SA_ARM    <- CCX_MODE_CANONICAL
SA_NAMES  <- c(NH = "sst_seas_amp_NH", SH = "sst_seas_amp_SH")
SA_OBS    <- c(NH = ccx_const("SST_SEAS_AMP_NH_OBS"), SH = ccx_const("SST_SEAS_AMP_SH_OBS"))
SA_WIN    <- LIK_SEAS_WINDOW                    # the seasonal rows' window (R/likelihood.R)
SA_QUIET_N <- 3L                                 # server.R: utils::head(..., 3L)
SA_FAMILIES <- c(co2_seasonal = "^co2_seasonal", d13c_seasonal = "^d13c_seasonal", co2_other = "^co2_(?!seasonal)",
                 d13c_other = "^d13c_(?!seasonal)", d14c = "^(d14c|excess_c14)", ocean_surface = "^(ocean_grad|hs_surf)",
                 gcb = "^gcb")
SA_STEM <- file.path("outputs", "diagnostics", sprintf("card7_sst_amp_%s_%s", format(Sys.Date(), "%Y%m%d"), SA_ARM))

commit <- ccx_git_stamp(); dirty <- ccx_stamp_dirty(commit)
mode_file <- ccx_mode_file(SA_ARM); md5 <- unname(tools::md5sum(mode_file))
dir.create(dirname(SA_STEM), showWarnings = FALSE, recursive = TRUE)
LOG <- paste0(SA_STEM, ".log"); if (file.exists(LOG)) file.remove(LOG)
say <- function(...) { txt <- sprintf(...); cat(txt); cat(txt, file = LOG, append = TRUE) }
say("%s | commit %s%s | canonical %s (%s, md5 %s) | %s\n", SA_DRIVER, commit, if (dirty) " (dirty)" else "",
    SA_ARM, basename(dirname(mode_file)), md5, format(Sys.time(), "%Y-%m-%d %H:%M"))

# ---- (1) fitted vs observed -----------------------------------------------------------
v0 <- dg_vector(SA_ARM); md <- v0$md
fit <- vapply(SA_NAMES, function(n) v0$p[[n]], 0)
sdm <- sqrt(diag(ccx_mode_fit_stats(md)$cov))      # marginal Laplace sd, unconstrained scale
cm <- readRDS(ccx_path("data", "constraint_map.rds"))
if (!identical(cm$provenance$mode, SA_ARM) && !is.null(cm$provenance$mode))
  stop("data/constraint_map.rds was built at ", cm$provenance$mode, ", not ", SA_ARM)
say("\n=== (1) the fitted seasonal SST half-amplitudes vs ERSSTv5 (1975-2024 hemispheric climatology) ===\n")
for (h in names(SA_NAMES)) say("  %s: fitted %.3f K vs observed %.3f K = %.0f%% of observed; map's marginal sd (unconstrained) %.3f\n",
  h, fit[[h]], SA_OBS[[h]], 100 * fit[[h]] / SA_OBS[[h]], cm$sd_marginal[[SA_NAMES[[h]]]])

# ---- (2) the map --------------------------------------------------------------------
par_tot <- sort(colSums(cm$M))
model_names <- intersect(names(par_tot), c(names(ccx_default_params()), "bomb_total", "luc_scale"))
quiet <- utils::head(model_names, SA_QUIET_N)
say("\n=== (2) the map (%s; step = %s) ===\n", basename(ccx_path("data", "constraint_map.rds")), cm$provenance$step)
say("  total leverage, the %d model parameters, lowest first:\n", length(model_names))
for (i in seq_along(model_names)) say("    %2d %-16s %6.2f%s\n", i, model_names[i], par_tot[[model_names[i]]],
                                      if (model_names[i] %in% SA_NAMES) "   <- SST seasonal swing" else "")
say("  the app's 'little influence' list (the %d lowest): %s\n", SA_QUIET_N, paste(quiet, collapse = ", "))

# ---- (3) forward runs -------------------------------------------------------------------
obs <- ccx_prepare_obs()
seas_amp <- function(st, win) {     # peak-to-trough of the mean one-harmonic cycle over the window, and its phase
  k <- st$year >= win[1] & st$year <= win[2]; a <- mean(st$a[k]); b <- mean(st$b[k])
  c(p2t = 2 * sqrt(a^2 + b^2), peak_month = (atan2(a, b) / (2 * pi) * 12) %% 12)
}
co2_scored <- ccx_obs_co2_scored(obs, ccx_co2_flask_on(v0$err), monthly = TRUE)$co2   # the MLO rows the canonical scores (flask)
obs_cyc <- function(stn) {
  o <- co2_scored[co2_scored$station == stn, ]
  seas_amp(ccx_year_harmonic(o$decimal_date, o$co2_ppm), SA_WIN)
}
OBS_CYC <- list(NH = obs_cyc("MLO"), SH = obs_cyc("SPO"))
r_ref <- dg_run(v0); ref <- unlist(dg_streams(r_ref, v0))
g1 <- abs(sum(ref[names(md$streams)]) - sum(md$streams))
say("\nHARNESS GATE: dg streams at the canonical vs stored, diff %.1e -> %s\n", g1, if (g1 < 1e-4) "PASS" else "FAIL")
if (g1 >= 1e-4) stop("harness gate failed")
nm_rows <- names(ref); n_hit <- rowSums(sapply(SA_FAMILIES, function(p) grepl(p, nm_rows, perl = TRUE)))
if (any(n_hit != 1L)) stop("rows not in exactly one family: ", paste(nm_rows[n_hit != 1L], collapse = ", "))
ARMS <- list(fitted = fit, observed = SA_OBS, NH_observed = c(NH = SA_OBS[["NH"]], SH = fit[["SH"]]),
             zero = c(NH = 0, SH = 0))
res <- lapply(names(ARMS), function(a) {
  v <- v0; for (h in names(SA_NAMES)) v$p[[SA_NAMES[[h]]]] <- ARMS[[a]][[h]]
  r <- dg_run(v); st <- unlist(dg_streams(r, v)); d <- st[nm_rows] - ref[nm_rows]
  fam <- vapply(SA_FAMILIES, function(p) sum(d[grepl(p, nm_rows, perl = TRUE)]), 0)
  cyc <- list(NH = seas_amp(ccx_model_year_stats(r$out, "co2_NH"), SA_WIN),
              SH = seas_amp(ccx_model_year_stats(r$out, "co2_SH"), SA_WIN))
  list(arm = a, amp = ARMS[[a]], dlik = sum(d), fam = fam, cyc = cyc, top = sort(d)[1:3])
})
names(res) <- names(ARMS)
say("\n=== (3) forward runs, everything else at the mode; seasonal cycle = mean one-harmonic fit %d-%d (the Keeling tab's) ===\n",
    SA_WIN[1], SA_WIN[2])
say("  stations (scored series): MLO peak-to-trough %.2f ppm, peak month %.2f; SPO %.2f ppm, peak month %.2f\n",
    OBS_CYC$NH[["p2t"]], OBS_CYC$NH[["peak_month"]], OBS_CYC$SH[["p2t"]], OBS_CYC$SH[["peak_month"]])
for (a in names(res)) with(res[[a]], {
  say("  %-12s amp NH %.2f SH %.2f K | NH box %.2f ppm (%+.1f%% vs fitted), SH box %.2f ppm (%+.1f%%) | dlik %+9.2f | %s\n",
      arm, amp[["NH"]], amp[["SH"]], cyc$NH[["p2t"]], 100 * (cyc$NH[["p2t"]] / res$fitted$cyc$NH[["p2t"]] - 1),
      cyc$SH[["p2t"]], 100 * (cyc$SH[["p2t"]] / res$fitted$cyc$SH[["p2t"]] - 1), dlik,
      paste(sprintf("%s %+.2f", names(fam), fam), collapse = ", "))
})

saveRDS(list(fit = fit, obs = SA_OBS, map_total = par_tot, model_names = model_names, quiet = quiet, runs = res,
             obs_cycle = OBS_CYC, provenance = list(driver = SA_DRIVER, commit = commit, dirty = dirty, canonical = SA_ARM,
             mode_file = mode_file, mode_md5 = md5, map = "data/constraint_map.rds", window = SA_WIN,
             rng = "none (deterministic)", date = format(Sys.time(), "%Y-%m-%d %H:%M"))), paste0(SA_STEM, ".rds"))
say("\nprovenance: %s @%s; %s md5 %s; no RNG; saved %s.{log,rds} | %.1f min\n", SA_DRIVER, commit, SA_ARM, md5, SA_STEM,
    as.numeric(difftime(Sys.time(), t_start, units = "mins")))
