# =====================================================================
# diag_hygiene_batch_price.R -- PRICE the 2026-09-16 (d) objective-hygiene
# batch at every registered mode, ONE ITEM AT A TIME and all together, on the
# LIKELIHOOD streams (like-for-like: same par_mode, same structure, the same
# spinup label), so restamp_mode_objective.R can be handed a measured delta
# and the CHANGELOG a per-item receipt. Items (each has a reproduction switch):
#   D14C   the deep / slab D14C rows read EVERY box in their window (HD too)     LIK_D14C_EVERY_BOX
#   GCB    the land-sink sigma at GCB's stated 0.5, no x3 multiplier            LIK_LAND_SINK_INFLATE
#   EXC    Naegler 2009's net-CO2-uptake correction on the excess-14C centers    LIK_EXCESS_C14_UPTAKE_CORR
#   SST    the pre-1850 SST anomaly at the product's 1850-1900 mean, not 1850   FORC_SST_PRE1850_MEAN
# plus the PRIOR-only item (no likelihood move): h_hs under its Holte prior.
# Usage: Rscript calibration/diag_hygiene_batch_price.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
HB_COMMIT <- ccx_git_stamp()
ccx_load_cpp()
HB_OUT <- ccx_path("outputs", "diagnostics", sprintf("hygiene_batch_price_%s", format(Sys.Date(), "%Y%m%d")))
sink_log <- file(paste0(HB_OUT, ".log"), open = "wt"); sink(sink_log, split = TRUE); on.exit({ sink(); close(sink_log) }, add = TRUE)
cat(sprintf("== the hygiene batch, priced (commit %s) ==\n", HB_COMMIT))
OLD <- list(LIK_D14C_EVERY_BOX = FALSE, LIK_LAND_SINK_INFLATE = 3.0, LIK_EXCESS_C14_UPTAKE_CORR = c(`1975` = 1, `1995` = 1), FORC_SST_PRE1850_MEAN = FALSE)
NEW <- list(LIK_D14C_EVERY_BOX = TRUE,  LIK_LAND_SINK_INFLATE = 1.0, LIK_EXCESS_C14_UPTAKE_CORR = c(`1975` = 1.03, `1995` = 1.08), FORC_SST_PRE1850_MEAN = TRUE)
ITEMS <- c(D14C = "LIK_D14C_EVERY_BOX", GCB = "LIK_LAND_SINK_INFLATE", EXC = "LIK_EXCESS_C14_UPTAKE_CORR", SST = "FORC_SST_PRE1850_MEAN")
set_all <- function(vals) for (n in names(vals)) assign(n, vals[[n]], envir = globalenv())
score <- function(md) {
  bp <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp$pump_mode <- md$pump_mode
  rm <- ccx_apply_pins(ccx_mode_pins(md)); on.exit(ccx_unpin_params(rm), add = TRUE)
  u <- suppressMessages(utils::capture.output(st <- ccx_mode_start(md, "price"))); u <- st$u   # migrated + seeded, as every gate 4 does
  v <- ccx_make_logpost(base_params = bp, by_stream = TRUE, spinup_fn = ccx_spinup_from_label(ccx_mode_spinup(md)))(u)
  list(lp = as.numeric(v), st = attr(v, "streams"), prior = attr(v, "logprior"))
}
RES <- list()
for (m in names(CCX_MODE_FILES)) {
  md <- readRDS(ccx_mode_file(m)); cat(sprintf("\n-- %s (stored logpost %.4f, stored likelihood %.4f) --\n", m, md$logpost, sum(unlist(md$streams))))
  set_all(OLD); base <- score(md)
  gate <- sum(base$st[names(md$streams)]) - sum(unlist(md$streams))
  cat(sprintf("HARNESS GATE (all switches OLD): likelihood reproduces to %+.6f -> %s\n", gate, if (abs(gate) < 1e-4) "PASS" else "FAIL"))
  rows <- list(); per <- c()
  for (it in names(ITEMS)) { vals <- OLD; vals[[ITEMS[[it]]]] <- NEW[[ITEMS[[it]]]]; set_all(vals); s <- score(md)
    d <- s$st[names(base$st)] - base$st; per[it] <- sum(d); rows[[it]] <- d[abs(d) > 1e-6]
    cat(sprintf("  %-4s alone: likelihood %+9.4f | %s\n", it, sum(d), paste(sprintf("%s %+.3f", names(rows[[it]]), rows[[it]]), collapse = ", "))) }
  set_all(NEW); all <- score(md); d_all <- all$st[names(base$st)] - base$st
  cat(sprintf("  ALL together: likelihood %+9.4f (sum of singles %+9.4f; interaction %+.4f) | logpost %.4f -> %.4f (prior move %+.4f, of which h_hs prior %+.4f)\n",
              sum(d_all), sum(per), sum(d_all) - sum(per), base$lp, all$lp, all$prior - base$prior,
              .ccx_prior_eval(CCX_PARAM_TABLE$h_hs, md$par_mode[["h_hs"]]) - dunif(md$par_mode[["h_hs"]], 20, 500, log = TRUE)))
  RES[[m]] <- list(base = base, all = all, per_item = per, rows = rows, delta_lik = sum(d_all), gate = gate)
}
set_all(NEW)
cat("\n== RESTAMP DELTAS (likelihood, the number restamp_mode_objective.R is handed) ==\n")
for (m in names(RES)) cat(sprintf("%-10s %+.4f\n", m, RES[[m]]$delta_lik))
saveRDS(list(res = RES, old = OLD, new = NEW, commit = HB_COMMIT, built = format(Sys.time())), paste0(HB_OUT, ".rds"))
cat(sprintf("saved %s.{log,rds}\n", HB_OUT))
