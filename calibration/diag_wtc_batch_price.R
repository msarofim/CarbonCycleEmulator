# =====================================================================
# diag_wtc_batch_price.R -- WHAT THE CITATION BATCH COSTS AT THE CANONICAL, item by item,
# before any refit (2026-10-12; label hilda_csl3v0kaidgbemwtc, "New label (a) (Recommended)").
#
# The 09-16 e hygiene-batch idiom: the canonical's vector (hilda29e, objective #18) is scored
# under #18's base with ONE item of the batch added at a time, then with all of them. The two
# new FITTED names (bomb_share_NH, seas_T_lag) are held at their LEGACY values (0.90, 2.0) by
# the default-param slots, so the item rows price the CONSTANTS alone; the gate itself (wtc_free)
# is priced separately as an identity: opened at the legacy values it must reproduce the
# all-items likelihood exactly.
#
# ⛔ COMPARED ON LIKELIHOOD (the sum of the streams), NEVER ON LOGPOST: the arms carry different
# prior terms (the gate's two uniform priors and their logit Jacobians), and a pinned file's
# logpost is not comparable to a free one's ([[compare_gaps_not_absolute_logposts]]).
#
# GATES (stop, not warn):
#   G1  #18's objective at hilda29e reproduces the file's STORED logpost (minus the seed shift).
#   G2  the gate opened at the legacy values reproduces the all-items LIKELIHOOD (difference 0).
#
# Usage: Rscript calibration/diag_wtc_batch_price.R --commit=<sha>
# Output: outputs/diagnostics/wtc_batch_price_20261012/{price.rds, price.log via tee}
# =====================================================================

for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)
ccx_load_cpp()

WP_LABEL   <- "hilda_csl3v0kaidgbemwtc"
WP_MODE    <- CCX_MODE_CANONICAL
WP_OUTDIR  <- ccx_path("outputs", "diagnostics", "wtc_batch_price_20261012")
WP_G1_TOL  <- 1e-5                     # test-mode-file's stored-logpost tolerance
WP_TOP     <- 6                        # streams printed per item
args <- commandArgs(trailingOnly = TRUE)
WP_COMMIT  <- sub("^--commit=", "", grep("^--commit=", args, value = TRUE))
if (!length(WP_COMMIT)) stop("--commit=<sha> is required (it is stamped into the output)")
dir.create(WP_OUTDIR, recursive = TRUE, showWarnings = FALSE)

md  <- readRDS(ccx_mode_file(WP_MODE))
bp0 <- ccx_mode_base(md); if (!is.null(md$pump_mode)) bp0$pump_mode <- md$pump_mode
# #18's gates, THEN its pins (ccx_gate_require's order)
hg0 <- ccx_apply_gate(ccx_mode_struct(md))
.todo <- ccx_mode_pins(md); .todo <- .todo[names(.todo) %in% CCX_PARAM_NAMES]
.rm <- if (length(.todo)) ccx_apply_pins(.todo) else list()
st  <- ccx_mode_start(md, "diag_wtc_batch_price")
score <- function(bp) {
  v <- suppressWarnings(ccx_make_logpost(base_params = bp, by_stream = TRUE)(st$u))
  list(lp = as.numeric(v), ll = attr(v, "loglik"), lpr = attr(v, "logprior"), streams = attr(v, "streams"))
}

cat(sprintf("mode %s (struct %s), commit %s\n", WP_MODE, ccx_mode_struct(md), WP_COMMIT))
s0 <- score(bp0)
g1 <- s0$lp - st$logpost_shift - md$logpost
cat(sprintf("G1  #18 at %s: logpost %.6f vs stored %.6f (shift %.6f): diff %.2e\n",
            WP_MODE, s0$lp, md$logpost, st$logpost_shift, g1))
if (abs(g1) > WP_G1_TOL) stop("G1 FAILED: #18's objective does not reproduce the stored logpost")

blk <- ccx_struct_block(WP_LABEL)
items <- list(
  alk_surface     = "alk_surface",
  carb_salinity   = "carb_salinity",
  ocean_depth     = "ocean_depth",
  sst_seas_lags   = c("sst_seas_lag_NH", "sst_seas_lag_SH"),
  nuc_share_ts    = "nuc_share_ts",
  alpha_photo_eps = "alpha_photo_eps",
  pump_eps13_org  = "pump_eps13_org",
  intcal_sigma    = "intcal_sd_published")
with_fields <- function(fields) { bp <- bp0; for (n in fields) bp[[n]] <- blk[[n]]; bp }

rows <- list(); top <- list()
for (k in names(items)) {
  sk <- score(with_fields(items[[k]]))
  d  <- sk$streams - s0$streams[names(sk$streams)]
  rows[[k]] <- data.frame(item = k, d_loglik = sk$ll - s0$ll, stringsAsFactors = FALSE)
  dd <- d[abs(d) > 0]
  top[[k]]  <- head(dd[order(-abs(dd))], WP_TOP)
}
all_fields <- unlist(items, use.names = FALSE)
s_all <- score(with_fields(all_fields))
d_all <- s_all$streams - s0$streams[names(s_all$streams)]
missing <- setdiff(names(s0$streams), names(s_all$streams)); added <- setdiff(names(s_all$streams), names(s0$streams))

# G2: the gate opened at the legacy values = the all-items likelihood. Swap #18's gates for the
# label's (which adds the two names), re-pin, and start from the canonical under the LABEL (the
# two absent names are seeded at init by the start, then set to their legacy values below).
ccx_unpin_params(.rm); ccx_unapply_gate(hg0)
bp_g <- with_fields(c(all_fields, "wtc_free"))
hg <- ccx_apply_gate(WP_LABEL)
.rm <- if (length(.todo)) ccx_apply_pins(.todo) else list()
# the canonical's vector + the two names at their LEGACY values, encoded directly (ccx_mode_start()
# refuses a file lacking them; how the refit's starts seed them is the driver's business)
pv <- as.list(md$par_mode); pv[["bomb_share_NH"]] <- FORC_BOMB_NH_SHARE; pv[["seas_T_lag"]] <- CCX_SEAS_T_LAG
stopifnot(all(CCX_PARAM_NAMES %in% names(pv)))
ug <- ccx_par_to_unc(pv[CCX_PARAM_NAMES])
vg <- suppressWarnings(ccx_make_logpost(base_params = bp_g, by_stream = TRUE)(ug))
g2 <- attr(vg, "loglik") - s_all$ll
ccx_unpin_params(.rm); ccx_unapply_gate(hg)
cat(sprintf("G2  gate opened at the legacy values (0.90, 2.0): likelihood diff vs all-items %.2e\n", g2))
if (abs(g2) > 1e-9) stop("G2 FAILED: the gate at its legacy values is not the held model")

tab <- do.call(rbind, rows)
tab <- rbind(tab, data.frame(item = "ALL (sum of streams)", d_loglik = s_all$ll - s0$ll))
cat(sprintf("\nlikelihood at %s under #18: %.4f on %d streams\n", WP_MODE, s0$ll, length(s0$streams)))
cat(sprintf("%-22s %12s\n", "item", "d loglik"))
for (i in seq_len(nrow(tab))) cat(sprintf("%-22s %+12.4f\n", tab$item[i], tab$d_loglik[i]))
cat(sprintf("interaction (ALL - sum of items): %+.4f\n", tab$d_loglik[nrow(tab)] - sum(tab$d_loglik[-nrow(tab)])))
if (length(missing) || length(added))
  cat(sprintf("streams renamed: -%s / +%s (the B slab's name follows its edges)\n",
              paste(missing, collapse = ","), paste(added, collapse = ",")))
cat("\nlargest stream moves per item:\n")
for (k in names(top)) cat(sprintf("  %-16s %s\n", k, paste(sprintf("%s %+.3f", names(top[[k]]), top[[k]]), collapse = "; ")))
cat(sprintf("  %-16s %s\n", "ALL", paste(sprintf("%s %+.3f", names(head(d_all[order(-abs(d_all))], WP_TOP)),
                                                  head(d_all[order(-abs(d_all))], WP_TOP)), collapse = "; ")))

saveRDS(list(table = tab, streams_18 = s0$streams, streams_all = s_all$streams, top = top,
             gates = c(G1 = g1, G2 = g2),
             provenance = list(driver = "calibration/diag_wtc_batch_price.R", commit = WP_COMMIT,
                               mode = WP_MODE, mode_file = ccx_mode_file(WP_MODE), base_struct = ccx_mode_struct(md),
                               label = WP_LABEL, pins = names(md$pins), held = c(bomb_share_NH = FORC_BOMB_NH_SHARE,
                               seas_T_lag = CCX_SEAS_T_LAG), compared_on = "likelihood (sum of streams)",
                               run = format(Sys.time(), "%Y-%m-%d %H:%M %Z"))),
        file.path(WP_OUTDIR, "price.rds"))
cat(sprintf("\nwritten %s\n", file.path(WP_OUTDIR, "price.rds")))
