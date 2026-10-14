# =====================================================================
# promote_cmap_stability.R -- put the constraint map's POSTERIOR WINNER STABILITY into
# data/constraint_map_stability.rds, the file the app's takeaway reads (Marcus 2026-10-14, verbatim:
# "Posterior winner stability (Recommended)"; CHANGELOG 2026-10-14 c, d).
#
# THE RULE (app/global.R, app_cmap_holder_phrase): a row's mode winner is NAMED only if it holds the row
# in at least 1 - APP_CMAP_TIE_LOST_MAX of the posterior draws; otherwise the row is reported as a tie.
# This script carries, per row, the share of draws in which the mode's winner LOSES the row. It is read
# off a landed calibration/diag_cmap_posterior_spread.R run, with no model run and no RNG:
#   - the share is RECOMPUTED from the run's per-draw winners against the shipped map's own winners,
#     and must equal the run's own table exactly;
#   - the run must be LIKE-FOR-LIKE with the shipped map: same mode, and its map at the mode
#     identical() to data/constraint_map.rds's MC. The artifact carries that MC, so the app and
#     test-cmap-tie.R refuse a stability file once the map is rebuilt;
#   - the source run is named by path and md5, with its draws and their chains' provenance.
# Deterministic: no wall-clock time in the artifact, so two runs at one commit are byte-identical.
#
# Usage (repo root):
#   Rscript calibration/promote_cmap_stability.R --from=<landed cmap_posterior_spread rds> [--out=data/constraint_map_stability.rds]
# =====================================================================
PS_ARGS <- commandArgs(trailingOnly = TRUE)
ps_arg <- function(key, default) {
  hit <- grep(sprintf("^--%s=", key), PS_ARGS, value = TRUE)
  if (length(hit)) sub(sprintf("^--%s=", key), "", hit[1]) else default
}
stopifnot(file.exists("DESIGN.md"))
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

PS_DRIVER <- "calibration/promote_cmap_stability.R"
PS_FROM   <- ps_arg("from", "")
PS_OUT    <- ps_arg("out", file.path("data", "constraint_map_stability.rds"))
PS_MAP    <- file.path("data", "constraint_map.rds")
PS_RULING <- "Marcus 2026-10-14: \"Posterior winner stability (Recommended)\"; refused half-steps: \"Finite half only (Recommended)\""
stopifnot(nzchar(PS_FROM), file.exists(PS_FROM), file.exists(PS_MAP))
PS_COMMIT <- ccx_git_stamp(exclude = PS_OUT)

src <- readRDS(PS_FROM); cm <- readRDS(PS_MAP)
bad <- ccx_cmap_problems(cm, CCX_MODE_CANONICAL)
if (length(bad)) stop("the shipped map is not the canonical's: ", paste(bad, collapse = "; "))
# LIKE-FOR-LIKE with the shipped map
if (!identical(src$provenance$mode, CCX_MODE_CANONICAL)) stop("the run is at mode ", src$provenance$mode, ", not ", CCX_MODE_CANONICAL)
if (!identical(src$MC_mode$MC, cm$MC)) stop("the run's map at the mode is not identical() to ", PS_MAP, ": rebuild one or the other")
FAM <- rownames(cm$MC)
stopifnot(setequal(rownames(src$winners), FAM), ncol(src$winners) == src$provenance$n)
# RECOMPUTED, and required to equal the run's own table
w0 <- apply(cm$MC, 1, function(r) names(which.max(r)))
lost <- vapply(FAM, function(f) mean(src$winners[f, ] != w0[[f]]), numeric(1))
tab <- src$table[match(FAM, src$table$family), ]
if (!identical(unname(lost), tab$share_other_winner) || !identical(unname(w0), tab$winner))
  stop("the recomputed winner-loss shares differ from the run's own table")
cat(sprintf("%s @%s: %d rows from %s (%d draws); like-for-like with %s (mode %s, map commit %s)\n",
            PS_DRIVER, PS_COMMIT, length(FAM), PS_FROM, src$provenance$n, PS_MAP, CCX_MODE_CANONICAL,
            cm$provenance$commit))
for (f in FAM) cat(sprintf("  %-30s winner %-30s lost in %5.1f %% of draws\n", f, w0[[f]], 100 * lost[[f]]))

out <- list(
  lost_share = lost, winner = w0, MC_map = cm$MC,
  provenance = list(
    driver = PS_DRIVER, commit = PS_COMMIT, ruling = PS_RULING,
    rule = "share of posterior draws in which the shipped map's winner of a row is not that row's largest component",
    mode = CCX_MODE_CANONICAL, map = PS_MAP, map_commit = cm$provenance$commit,
    map_stored_logpost = cm$provenance$stored_logpost,
    source = PS_FROM, source_md5 = unname(tools::md5sum(PS_FROM)),
    source_driver = src$provenance$driver, source_commit = src$provenance$commit,
    n_draws = src$provenance$n, draws = src$provenance$draws, draws_md5 = src$provenance$draws_md5,
    draws_rows = src$provenance$rows, chains = src$provenance$draws_provenance$chains,
    chain_md5 = src$provenance$draws_provenance$chain_md5, chain_seeds = src$provenance$draws_provenance$chain_seeds,
    refused_half_steps = sum(nzchar(src$join$refused)), step = src$provenance$step,
    seed = NA_integer_, seed_note = "no RNG here or in the source run (evenly spaced draws); the chains' seeds are recorded above"))
saveRDS(out, PS_OUT)
cat(sprintf("wrote %s (md5 %s)\n", PS_OUT, unname(tools::md5sum(PS_OUT))))
