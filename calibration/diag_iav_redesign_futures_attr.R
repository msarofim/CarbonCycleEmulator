#!/usr/bin/env Rscript
# =====================================================================
# diag_iav_redesign_futures_attr.R -- WHICH re-fitted name carries the redesign's futures move? (CHANGELOG 2026-10-07 d)
# calibration/diag_iav_redesign_price.R found that at basin B the detrended index ALONE moves CO2 in 2300 by +0.02 ppm
# (B1), but with the five land names re-optimised (B2) by +23 ppm under SSP5-8.5 (+11 under vvH). Here each B2 name is set
# back to B's value, ONE AT A TIME, everything else at B2 (the index detrended): the futures' change is that name's share.
# GATES: the B2 and B1 vectors rebuilt here reproduce the pricing's stored futures exactly (B1 = all five set back).
# Usage: Rscript calibration/diag_iav_redesign_futures_attr.R [pricing rds]
# OUTPUTS: outputs/diagnostics/iav_redesign_futures_attr_<date>.{log,rds}. ⛔ ADOPTS NOTHING. No RNG.
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
source(file.path("calibration", "lib_design_gates.R"))
BR_FUT_SPLICE <- c(ssp585 = FALSE, vvH = TRUE); BR_FUT_YEAR <- 2300L      # = the pricing's (the refit read's s. 5)
source(file.path("calibration", "lib_block_reopt.R"))
ccx_load_cpp()

# ---- named constants (every label below derives from these) -------------------------
FA_DRIVER <- "calibration/diag_iav_redesign_futures_attr.R"
FA_ARGS   <- commandArgs(trailingOnly = TRUE)
FA_PRICE  <- if (length(FA_ARGS)) FA_ARGS[1] else file.path("outputs", "diagnostics", "iav_redesign_price_20261007.rds")
FA_OUT <- file.path("outputs", "diagnostics", sprintf("iav_redesign_futures_attr_%s", format(Sys.Date(), "%Y%m%d")))
COMMIT <- ccx_git_stamp()
sink(paste0(FA_OUT, ".log"), split = TRUE)
PR <- readRDS(FA_PRICE); PV <- PR$provenance
cat(sprintf("%s @%s, %s | from %s (%s @%s) | basin B %s | index '%s'\n", FA_DRIVER, COMMIT, format(Sys.time(), "%Y-%m-%d %H:%M"),
            FA_PRICE, PV$driver, PV$commit, PV$mode_b, PV$index))
if (!identical(unname(tools::md5sum(PV$mode_b)), PV$mode_b_md5)) stop("basin B's file is not the one the pricing read")
set_names <- function(V, vals) { for (n in names(vals)) { if (n %in% names(V$p)) V$p[[n]] <- vals[[n]]; V$pm[[n]] <- vals[[n]] }
  V$p <- ccx_set_enso(V$p, V$pm); V$luc_scale <- V$pm$luc_scale; V$bomb_total <- V$pm$bomb_total; V }
VB <- dg_vector(PV$mode_b); VD <- VB; VD$p$enso_index <- CCX_ENSO_INDEX_CODES[[PV$index]]
stopifnot(identical(ccx_enso_index_of(VD$p), PV$index))
BLK <- PR$b2_block; B_OF <- vapply(names(BLK), function(n) VB$pm[[n]], 0)
fut <- function(V) br_futures(V, dg_spinup(V))
F_B2 <- fut(set_names(VD, BLK)); F_B1 <- fut(VD)
g <- c(B2 = max(abs(F_B2 - PR$futures["B2", ])), B1 = max(abs(F_B1 - PR$futures["B1", ])))
cat(sprintf("GATES: rebuilt B2 vs the pricing's futures, max |diff| %.1e ppm; B1 (all five at B) %.1e ppm\n", g[["B2"]], g[["B1"]]))
if (any(g > 1e-6)) stop("the rebuilt vectors do not reproduce the pricing's futures")
ATT <- t(vapply(names(BLK), function(n) { b <- BLK; b[[n]] <- B_OF[[n]]; F_B2 - fut(set_names(VD, b)) }, numeric(length(BR_FUT_SPLICE))))
TOT <- F_B2 - F_B1
cat(sprintf("\nCO2 in %d: B2 %s; B1 %s; B2 - B1 %s ppm\n", BR_FUT_YEAR, paste(sprintf("%s %.2f", names(F_B2), F_B2), collapse = ", "),
            paste(sprintf("%s %.2f", names(F_B1), F_B1), collapse = ", "), paste(sprintf("%s %+.2f", names(TOT), TOT), collapse = ", ")))
cat("each name's share: B2 minus B2-with-that-name-at-B's-value (ppm), and its fraction of B2 - B1\n")
cat(sprintf("  %-16s %12s %12s %10s %10s   %s\n", "name", names(TOT)[1], names(TOT)[2], "frac", "frac", "value B2 (B)"))
for (n in rownames(ATT)) cat(sprintf("  %-16s %+12.2f %+12.2f %10.2f %10.2f   %.5g (%.5g)\n", n, ATT[n, 1], ATT[n, 2], ATT[n, 1] / TOT[[1]],
                                     ATT[n, 2] / TOT[[2]], BLK[[n]], B_OF[[n]]))
cat(sprintf("  %-16s %+12.2f %+12.2f %10.2f %10.2f   (the one-at-a-time sum; the rest is interaction)\n", "SUM", sum(ATT[, 1]), sum(ATT[, 2]),
            sum(ATT[, 1]) / TOT[[1]], sum(ATT[, 2]) / TOT[[2]]))
saveRDS(list(attribution = ATT, total = TOT, futures_b2 = F_B2, futures_b1 = F_B1, block_b2 = BLK, block_b = B_OF,
             provenance = list(driver = FA_DRIVER, commit = COMMIT, price = FA_PRICE, price_commit = PV$commit, mode_b = PV$mode_b,
                               index = PV$index, futures = paste(names(BR_FUT_SPLICE), collapse = "+"), year = BR_FUT_YEAR,
                               date = format(Sys.time(), "%Y-%m-%d %H:%M"), rng = "none", units = "ppm")), paste0(FA_OUT, ".rds"))
cat(sprintf("\nsaved %s.{log,rds}\n⛔ ADOPTS NOTHING.\n", FA_OUT))
sink()
