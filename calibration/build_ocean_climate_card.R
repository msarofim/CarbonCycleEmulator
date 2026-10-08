#!/usr/bin/env Rscript
# =====================================================================
# build_ocean_climate_card.R -- the data behind Known-issues card 8, "the ocean's climate effect" (2026-10-08 j).
#
# Marcus 2026-10-08: "go ahead with the card and futures re-measurement". The card says the model's ocean loses
# uptake to warming about twice as strongly as the GCB 2025 ocean models, and decades earlier; that this is H2 (one
# issue, CHANGELOG 10-08 i); and what it is worth to the futures. Every number on it comes from THIS artifact, which
# only COLLECTS three committed diagnostics at the canonical -- nothing is re-derived here, so the card cannot
# disagree with the drivers that measured it:
#   OC  calibration/diag_ocean_climate_gobm.R   the 2015-24 effect, 10 GOBM protocols emulated, and its parts
#   TS  calibration/diag_h2_time_shape.R        the annual series vs GCB Fig. S10, the per-K ratio, the emergence
#   FS  calibration/diag_h2_futures_stake.R     CO2 in 2100 / 2300 with the SST response scaled to GCB's size
# The full emulation takes minutes, too slow for a card that renders when it is opened; hence an artifact, as the
# constraint map's (data/constraint_map.rds).
#
# GATES (stop on any): each input names the canonical's mode file by md5; the stake's arm is the GCB-sized one its
# own header defines; the series cover the window the card quotes.
# Output: data/ocean_climate_card.rds (+ outputs/diagnostics/ocean_climate_card_<date>_<canonical>.log). No RNG.
# Usage:  Rscript calibration/build_ocean_climate_card.R
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

OCC_DRIVER <- "calibration/build_ocean_climate_card.R"
# the three products AT THE CANONICAL -- move these at every adoption (the md5 gate refuses a stale one)
OCC_IN <- list(
  OC = file.path("outputs", "diagnostics", "ocean_climate_gobm_20261008_obj18p2b1.rds"),
  TS = file.path("outputs", "diagnostics", "h2_time_shape_20261008_hilda29e.rds"),
  FS = file.path("outputs", "diagnostics", "h2_futures_stake_20261008_hilda29e.rds"))
OCC_GCB      <- c(mean = -0.20, sd = 0.05)            # GCB 2025 p. 3242 (VERIFIED, diag_ocean_climate_gobm.R header)
OCC_GCB_PCT  <- c(mean = -7.1, lo = -10.7, hi = -4.2)  # the same source: % of the CO2 effect, its model range
OCC_WINDOW   <- c(2015L, 2024L)
OCC_EMERGE   <- -0.10                                  # diag_h2_time_shape.R H2_EMERGE: half GCB's 2015-24 value
OCC_SCEN     <- c("ssp585", "vvH", "vvM")              # the futures the card quotes
OCC_OUT <- file.path("data", "ocean_climate_card.rds")
OCC_LOG <- file.path("outputs", "diagnostics",
                     sprintf("ocean_climate_card_%s_%s.log", format(Sys.Date(), "%Y%m%d"), CCX_MODE_CANONICAL))
COMMIT  <- ccx_git_stamp(exclude = OCC_OUT)

say <- function(...) { txt <- sprintf(...); cat(txt); cat(txt, file = OCC_LOG, append = TRUE) }
if (file.exists(OCC_LOG)) file.remove(OCC_LOG)
mode_file <- ccx_mode_file(); md5 <- unname(tools::md5sum(mode_file))
say("%s @%s | canonical %s (md5 %s) | %s\n", OCC_DRIVER, COMMIT, CCX_MODE_CANONICAL, md5, format(Sys.time(), "%Y-%m-%d %H:%M"))

OC <- readRDS(OCC_IN$OC); TS <- readRDS(OCC_IN$TS); FS <- readRDS(OCC_IN$FS)
oc_md5 <- sub("^md5 ", "", regmatches(OC$provenance, regexpr("md5 [0-9a-f]{32}", OC$provenance)))
g <- c(OC = identical(oc_md5, md5), TS = identical(TS$provenance$ccx_mode_md5, md5),
       FS = identical(FS$provenance$mode_md5, md5))
say("GATE inputs at the canonical's mode file: %s\n", paste(sprintf("%s %s", names(g), ifelse(g, "PASS", "FAIL")), collapse = ", "))
if (!all(g)) stop("an input was not made at the canonical's mode file: rebuild it at this canonical first")

# ---- the 2015-24 effect and its parts (OC) -------------------------------------------
sst <- mean(OC$table[, "effect_sst_only"]); tot <- OC$ensemble[["mean"]]
eff <- list(ccx = OC$ensemble, gcb = OCC_GCB, ratio = tot / OCC_GCB[["mean"]],
            ratio_range = tot / (OCC_GCB[["mean"]] + c(-1, 1) * OCC_GCB[["sd"]]),
            pct = OC$ensemble_pct, gcb_pct = OCC_GCB_PCT,
            parts = c(thermal = sst, enso_and_stratification = tot - sst), window = OCC_WINDOW)

# ---- the time shape (TS) ---------------------------------------------------------------
w <- TS$years >= OCC_WINDOW[1] & TS$years <= OCC_WINDOW[2]
if (sum(w) != diff(OCC_WINDOW) + 1L) stop("the series do not cover ", OCC_WINDOW[1], "-", OCC_WINDOW[2])
em <- TS$m2[TS$m2$threshold == OCC_EMERGE, ]
if (nrow(em) != 1L) stop("no emergence row at the threshold ", OCC_EMERGE)
shape <- list(years = TS$years, ccx = unname(TS$ccx), ccx_lo = unname(TS$ccx_lo), ccx_hi = unname(TS$ccx_hi),
              gcb = TS$gcb, per_K = c(ccx = TS$m3["ccx", "b"], gcb = TS$m3["gcb", "b"]),
              per_K_ratio = TS$ratio, emergence = c(threshold = OCC_EMERGE, ccx = em$ccx, gcb = em$gcb, lead = em$lead_yr),
              shape_r = TS$m4)

# ---- the futures (FS): the GCB-sized arm and its GCB +-1 sigma -------------------------
FT <- FS$table
arms <- c(f_T = "f_T", f_T_lo = "f_T_lo", f_T_hi = "f_T_hi")
if (!all(arms %in% FT$arm) || !all(OCC_SCEN %in% FT$scenario)) stop("the stake product lacks an arm or a scenario")
pick <- function(arm, s, col) FT[FT$arm == arm & FT$scenario == s & FT$mode == "all", col]
fut <- do.call(rbind, lapply(OCC_SCEN, function(s) data.frame(
  scenario = s, base_2100 = pick("f1", s, "co2_2100"), base_2300 = pick("f1", s, "co2_2300"),
  d_2100 = pick("f_T", s, "d_2100"), d_2300 = pick("f_T", s, "d_2300"),
  d_2300_gcb_lo_sd = pick("f_T_lo", s, "d_2300"), d_2300_gcb_hi_sd = pick("f_T_hi", s, "d_2300"))))
stake <- list(f = FS$arms_all[c("f_T", "f_T_lo", "f_T_hi")], table = fut,
              note = "unrefitted: the ocean's SST anomaly scaled by f all-time; the historical fit would move under any f < 1")

say("\n2015-24 climate effect: CCX %.3f +/- %.3f GtC/yr (protocols %.3f to %.3f) vs GCB %.2f +/- %.2f -> %.2fx (%.2f-%.2fx over GCB's 1 sigma)\n",
    eff$ccx[["mean"]], eff$ccx[["sd"]], eff$ccx[["min"]], eff$ccx[["max"]], OCC_GCB[["mean"]], OCC_GCB[["sd"]],
    eff$ratio, min(eff$ratio_range), max(eff$ratio_range))
say("  as %% of the CO2 effect: CCX %.1f %% vs GCB %.1f %% (models %.1f to %.1f)\n", eff$pct[["mean"]],
    OCC_GCB_PCT[["mean"]], OCC_GCB_PCT[["lo"]], OCC_GCB_PCT[["hi"]])
say("  parts: thermal %.3f, ENSO limb + stratification %+.3f\n", eff$parts[["thermal"]], eff$parts[["enso_and_stratification"]])
say("per K of SST: CCX %.3f, GCB %.3f GtC/yr per K -> ratio %.2f +/- %.2f\n", shape$per_K[["ccx"]], shape$per_K[["gcb"]],
    shape$per_K_ratio[["ratio"]], shape$per_K_ratio[["se"]])
say("emergence (11-yr mean stays below %.2f): CCX %d, GCB %d -> %d years earlier\n", OCC_EMERGE, em$ccx, em$gcb, em$lead_yr)
say("futures, GCB-sized response (f %.3f; %.3f-%.3f over GCB's 1 sigma), CO2 change in 2300 (2100):\n",
    stake$f[["f_T"]], stake$f[["f_T_lo"]], stake$f[["f_T_hi"]])
for (i in seq_len(nrow(fut)))
  say("  %-7s %+.1f ppm (%+.1f to %+.1f) of %.1f; 2100 %+.1f of %.1f\n", fut$scenario[i], fut$d_2300[i],
      fut$d_2300_gcb_lo_sd[i], fut$d_2300_gcb_hi_sd[i], fut$base_2300[i], fut$d_2100[i], fut$base_2100[i])

saveRDS(list(effect = eff, shape = shape, stake = stake,
             provenance = list(driver = OCC_DRIVER, commit = COMMIT, mode = CCX_MODE_CANONICAL, mode_file = mode_file,
                               mode_md5 = md5,
                               inputs = lapply(OCC_IN, function(p) c(path = p, md5 = unname(tools::md5sum(p)))),
                               input_commits = c(OC = sub(".*@([0-9a-f]+[^;]*);.*", "\\1", OC$provenance),
                                                 TS = TS$provenance$commit, FS = FS$provenance$commit),
                               gcb = "GCB 2025 (ESSD 18:3211) p. 3242 and Suppl. Fig. S10, as the input drivers cite it",
                               rng = "none", built = format(Sys.time(), "%Y-%m-%d %H:%M"))), OCC_OUT)
say("provenance: %s @%s; canonical %s md5 %s; inputs %s; no RNG\nwrote %s\n", OCC_DRIVER, COMMIT, CCX_MODE_CANONICAL, md5,
    paste(basename(unlist(OCC_IN)), collapse = ", "), OCC_OUT)
