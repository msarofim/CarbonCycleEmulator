#!/usr/bin/env Rscript
# =====================================================================
# diag_iav_station_timing.R -- C6 of the interannual-cut preview (2026-10-06): does ENSO reach the two STATIONS the
# seasonal rows score (MLO, SPO) at the same time as the GLOBAL MBL mean the growth module scores?
#
# WHY. The seasonal rows compare MLO with the model's NH box and SPO with its SH box; the growth module compares the
# global MBL mean with the model's global mean. Each box is instantly mixed, so in the model both hemispheres see a
# land anomaly as soon as it is emitted. If the real stations see ENSO at different times from the global mean (a
# tropical station early, the South Pole late), one land lag cannot satisfy both statistics, and the disagreement is
# the two-box representation, not either data stream.
# WHAT. The same estimator on every record: a centred 12-month difference of monthly CO2, 1980-2024, detrended by a
# natural spline (df 5), cross-correlated with Nino 3.4 read k months late. Observed: NOAA MBL global (weekly ->
# monthly), Scripps MLO and SPO (data/obs_co2_monthly.rds, the records the seasonal rows score). Model: the global
# mean, the NH box and the SH box, at the canonical and at the growth module's optimum (A1, read from the preview rds).
# ⛔ ADOPTS NOTHING. No RNG.
# Usage: Rscript calibration/diag_iav_station_timing.R [path/to/iav_cut_preview_<tag>.rds]
# =====================================================================
t_start <- Sys.time()
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
ST_DRIVER <- "calibration/diag_iav_station_timing.R"
args <- commandArgs(trailingOnly = TRUE)
ST_IN <- if (length(args)) args[1] else {
  c0 <- list.files(file.path("outputs", "diagnostics"), pattern = "^iav_cut_preview_[0-9]{8}_[a-z0-9]+[.]rds$", full.names = TRUE)
  if (!length(c0)) stop("no iav_cut_preview rds; pass a path"); sort(c0, decreasing = TRUE)[1] }
ST_STATIONS <- c("MLO", "SPO")                    # the seasonal rows' records (Scripps)
ST_CHECK    <- c("MLO_NOAA", "SPO_NOAA")          # the same air, measured independently: a cross-check only
ST_SHIFTS <- -6:18
ST_GAMMA <- c("gamma_enso_land_NH", "gamma_enso_land_SH"); ST_OCEAN <- "w_enso_l2"; ST_VOLC <- "gamma_diff"
BR_OBS_WEEKLY <- file.path("data-raw", "downloads", "mbl_zonal_co2_GL.txt")
ST_OUT <- sub("iav_cut_preview_", "iav_station_timing_", sub("[.]rds$", "", ST_IN))
COMMIT <- ccx_git_stamp()
source(file.path("calibration", "lib_block_reopt.R"))
PV <- readRDS(ST_IN); P <- PV$provenance; BR_WIN <- P$window; BR_TREND_DF <- P$trend_df
LOGCON <- file(paste0(ST_OUT, ".log"), open = "wt"); sink(LOGCON, split = TRUE)
cat(sprintf("%s @%s, %s | from %s (%s @%s)\n", ST_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"), ST_IN, P$driver, P$commit))

MODE_FILE <- ccx_mode_file(P$mode); md <- readRDS(MODE_FILE)
stopifnot(identical(unname(tools::md5sum(MODE_FILE)), P$mode_md5))
BR_MD <- list(BASE = md); BR_VB <- list(BASE = dg_vector(MODE_FILE))
G0 <- vapply(ST_GAMMA, function(n) md$par_mode[[n]], 0); W0 <- md$par_mode[[ST_OCEAN]]; D0 <- BR_VB$BASE$p[[ST_VOLC]]
L0 <- md$par_mode[["lag_enso_land"]]
run_at <- function(L, s, d) { v <- br_vec("BASE", c(stats::setNames(s * G0, ST_GAMMA), stats::setNames(W0, ST_OCEAN)), L)
  v$p[[ST_VOLC]] <- d; dg_run(v) }

# the index, monthly, on k = 12 year + month
en <- as.data.frame(readRDS(ccx_path("data", "forcing_enso.rds"))); en$k <- as.integer(en$year) * 12L + en$month
# the estimator on a monthly series given as (k, co2): complete monthly grid, centred difference, window, detrend
cen_grid <- function(k, x) { kk <- seq(min(k), max(k)); v <- x[match(kk, k)]; data.frame(k = kk, g = br_cen12(v)) }
timing <- function(G) {
  G <- G[G$k >= BR_WIN[1] * 12L + 1L & G$k <= BR_WIN[2] * 12L + 12L & is.finite(G$g), ]
  tt <- (G$k - 1) / 12; d <- stats::residuals(stats::lm(G$g ~ splines::ns(tt, df = BR_TREND_DF)))
  rr <- vapply(ST_SHIFTS, function(sh) stats::cor(d, en$nino34_anom[match(G$k - sh, en$k)], use = "complete.obs"), 0)
  list(k = G$k, d = d, peak = ST_SHIFTS[which.max(rr)], r = max(rr), rr = rr, n = nrow(G)) }

obs <- utils::read.table(BR_OBS_WEEKLY, comment.char = "#")
mo <- stats::aggregate(list(co2 = obs$V5), list(year = obs$V1, month = obs$V2), mean)
st <- as.data.frame(readRDS(ccx_path("data", "obs_co2_monthly.rds")))
OBS <- c(list(MBL_global = timing(cen_grid(mo$year * 12L + mo$month, mo$co2))),
         stats::setNames(lapply(c(ST_STATIONS, ST_CHECK), function(s) { o <- st[st$station == s, ]
           timing(cen_grid(o$year * 12L + o$month, o$co2_ppm)) }), c(ST_STATIONS, ST_CHECK)))
RUNS <- list(canonical = run_at(L0, 1, D0), A1 = run_at(PV$A1[["L"]], PV$A1[["s"]], PV$A1[["d"]]))
MOD <- lapply(RUNS, function(r) { k <- r$F$year * 12L + r$F$month
  list(global = timing(data.frame(k = k, g = br_cen12((r$out$co2_NH + r$out$co2_SH) / 2))),
       NH_box = timing(data.frame(k = k, g = br_cen12(r$out$co2_NH))),
       SH_box = timing(data.frame(k = k, g = br_cen12(r$out$co2_SH)))) })
tab <- rbind(
  do.call(rbind, lapply(names(OBS), function(n) data.frame(record = paste("observed", n), months = OBS[[n]]$n,
                                                            peak = OBS[[n]]$peak, r = OBS[[n]]$r))),
  do.call(rbind, lapply(names(MOD), function(a) do.call(rbind, lapply(names(MOD[[a]]), function(n)
    data.frame(record = sprintf("model %s, %s", a, n), months = MOD[[a]][[n]]$n, peak = MOD[[a]][[n]]$peak, r = MOD[[a]][[n]]$r))))))
cat(sprintf("each record's growth (centred 12-month difference, %d-%d, detrended df %d) against Nino 3.4 read k months late:\n",
            BR_WIN[1], BR_WIN[2], BR_TREND_DF))
print(tab, digits = 3, row.names = FALSE)
# station against its box, and global against global, at both settings (the like-for-like each statistic uses)
pairs <- list(c("MBL_global", "global"), c("MLO", "NH_box"), c("SPO", "SH_box"))
cmp <- do.call(rbind, lapply(names(MOD), function(a) do.call(rbind, lapply(pairs, function(p) {
  o <- OBS[[p[1]]]; m <- MOD[[a]][[p[2]]]; k <- intersect(o$k, m$k)
  data.frame(setting = a, observed = p[1], model = p[2], r = stats::cor(o$d[match(k, o$k)], m$d[match(k, m$k)]),
             peak_gap = m$peak - o$peak) }))))
cat("each observed record against the model series its statistic compares it with (detrended growth; peak_gap = model - observed, months):\n")
print(cmp, digits = 3, row.names = FALSE)
sink()
saveRDS(list(table = tab, compare = cmp, xcorr = list(obs = lapply(OBS, `[[`, "rr"), model = lapply(MOD, function(x) lapply(x, `[[`, "rr"))),
             shifts = ST_SHIFTS, provenance = list(driver = ST_DRIVER, commit = COMMIT, input = ST_IN, input_commit = P$commit,
                                                  mode = P$mode, mode_md5 = P$mode_md5, window = BR_WIN, trend_df = BR_TREND_DF,
                                                  stations = ST_STATIONS, check = ST_CHECK, rng = "none", date = format(Sys.time(), "%Y-%m-%d %H:%M"))),
        paste0(ST_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds} | %.1f min\n", ST_OUT, as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
