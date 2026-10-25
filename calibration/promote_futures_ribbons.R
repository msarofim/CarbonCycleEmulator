# =====================================================================
# promote_futures_ribbons.R -- put a LANDED MCMC band into data/futures_ribbons.rds, the file the
# app reads (Marcus 2026-10-09: "Ship the 200k band (Recommended)"; CHANGELOG 2026-10-09 f).
#
# build_futures_ribbons.R refuses to write --draws output into data/, so an MCMC run can never land
# there by accident. THIS is the deliberate path. It copies the BANDS of an artifact a landing already
# built and committed, numbers untouched (no model run, no RNG), and:
#   - checks that the draws file named on the command line IS the one the bands were built from (its
#     md5 against the one in the artifact's `method`);
#   - records the chains' seeds, their RNG kind, where the seed is applied, the chain files' md5s, the
#     window and the pooling rule IN THE ARTIFACT (~/.claude/CLAUDE.md: a seed is recorded in the
#     artifact, not only in its source). The builder's own `seed` stays NA: it applied none;
#   - DROPS `key_draws` (every draw's value at 2050 / 2100 / 2150: ~22 MB in memory, which the app never
#     reads). It stays in the source artifact, named here by path and md5;
#   - sets the band's LABEL. ⚠ APP COPY, Marcus's: APP_RIBBON_NOTE (app/global.R) renders
#     "Shaded: the 5–95% range of N model runs — a <label>." Until he words it, the builder's
#     provenance label is carried and `label_ruled` is FALSE;
#   - runs ccx_ribbons_problems() at the canonical before writing, and refuses on any problem.
# Deterministic: no RNG and no wall-clock time in the artifact, so two runs at one commit are
# byte-identical (shown with --out to a second path).
#
# Usage (repo root):
#   Rscript calibration/promote_futures_ribbons.R --from=<landed ribbons rds> --draws=<pooled draws it was
#       built from> [--label="<Marcus's wording>"] [--out=data/futures_ribbons.rds]
# =====================================================================
PR_ARGS <- commandArgs(trailingOnly = TRUE)
pr_arg <- function(key, default) {
  hit <- grep(sprintf("^--%s=", key), PR_ARGS, value = TRUE)
  if (length(hit)) sub(sprintf("^--%s=", key), "", hit[1]) else default
}
stopifnot(file.exists("DESIGN.md"))
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

PR_DRIVER <- "calibration/promote_futures_ribbons.R"
PR_FROM   <- pr_arg("from", "")
PR_DRAWS  <- pr_arg("draws", "")
PR_OUT    <- pr_arg("out", file.path("data", "futures_ribbons.rds"))
PR_LABEL  <- pr_arg("label", "")
PR_DROP   <- "key_draws"                       # never read by the app
PR_GLOBAL <- file.path("app", "global.R")
if (!nzchar(PR_FROM) || !nzchar(PR_DRAWS)) stop("--from= and --draws= are both required")
stopifnot(file.exists(PR_FROM), file.exists(PR_DRAWS), file.exists(PR_GLOBAL))
# the product is excluded from the dirty check when it sits inside the repo (git refuses an outside pathspec).
# 2026-10-25: the shared helper; the old startsWith() test also matched a sibling directory named <repo>2/
PR_EXCL <- ccx_stamp_exclude(PR_OUT)

# the tab's scenario ids and y-variables, PARSED out of global.R (pure literals), as test-futures-ribbons.R
# does: sourcing it would compile the core and run a spin-up
pr_env <- new.env(parent = baseenv())
for (e in parse(PR_GLOBAL))
  if (is.call(e) && length(e) >= 3L && identical(as.character(e[[1]]), "<-") &&
      is.name(e[[2]]) && as.character(e[[2]]) %in% c("APP_SCENARIOS", "APP_FUTURE_YVARS"))
    eval(e, pr_env)
stopifnot(length(pr_env$APP_SCENARIOS) > 0L, length(pr_env$APP_FUTURE_YVARS) > 0L)

r <- readRDS(PR_FROM)
pv <- r$provenance
from_md5  <- unname(tools::md5sum(PR_FROM))
draws_md5 <- unname(tools::md5sum(PR_DRAWS))
cat(sprintf("=== %s @%s ===\nfrom  %s (md5 %s)\ndraws %s (md5 %s)\n", PR_DRIVER,
            ccx_git_stamp(exclude = PR_EXCL), PR_FROM, from_md5, PR_DRAWS, draws_md5))

# ---- GATES: an MCMC band, built from THESE draws, at the canonical ----------
if (!grepl("^SUPPLIED draws ", pv[["method"]])) stop("not a supplied-draws (MCMC) band: ", pv[["method"]])
if (!grepl(sprintf("(md5 %s)", draws_md5), pv[["method"]], fixed = TRUE))
  stop("the bands were not built from --draws: its md5 ", draws_md5, " is not in the artifact's method")
U <- readRDS(PR_DRAWS)
dp <- attr(U, "provenance")
if (is.null(dp) || is.null(dp[["chain_seeds"]])) stop("the draws carry no chain provenance")
if (!identical(dp[["mode"]], pv[["mode"]])) stop("draws' mode ", dp[["mode"]], " != the bands' ", pv[["mode"]])
if (nrow(U) != pv[["n_draws"]]) stop("draws ", nrow(U), " != the bands' n_draws ", pv[["n_draws"]])
# the chains' RNG kind and where their seed is applied, from the chain files the draws name (the
# snapshot directory beside the draws), md5-checked against the draws' own record
ch_files <- file.path(dirname(PR_DRAWS), dp[["chains"]])
stopifnot(all(file.exists(ch_files)))
if (!identical(unname(tools::md5sum(ch_files)), dp[["chain_md5"]]))
  stop("the chain files beside the draws are not the ones the draws were read from (md5)")
cp <- readRDS(ch_files[1])$provenance

# ---- the shipped artifact --------------------------------------------------
out <- r[setdiff(names(r), PR_DROP)]
out$provenance$label <- if (nzchar(PR_LABEL)) PR_LABEL else pv[["label"]]
out$provenance$label_ruled <- nzchar(PR_LABEL)
out$provenance$draws_provenance <- c(dp, list(
  draws_file = PR_DRAWS, draws_md5 = draws_md5,
  chain_rng_kind = cp[["rng_kind"]], chain_seed_applied = cp[["seed_applied"]]))
out$provenance$promoted <- list(driver = PR_DRIVER, commit = ccx_git_stamp(exclude = PR_EXCL),
                                from = PR_FROM, from_md5 = from_md5, dropped = PR_DROP,
                                dropped_note = sprintf("%s stays in %s (md5 %s)", PR_DROP, PR_FROM, from_md5))

bad <- ccx_ribbons_problems(out, CCX_MODE_CANONICAL, pr_env$APP_SCENARIOS, pr_env$APP_FUTURE_YVARS)
if (length(bad)) stop("ccx_ribbons_problems() refuses it: ", paste(bad, collapse = "; "))
stopifnot(identical(out$bands, r$bands))       # the numbers are the landing's, untouched

cat(sprintf("mode %s; %d draws (%d ok); %d band rows; chains seeded %s (%s)\n", pv[["mode"]],
            pv[["n_draws"]], pv[["n_ok"]], nrow(out$bands), paste(dp[["chain_seeds"]], collapse = " "),
            paste(cp[["rng_kind"]], collapse = "/")))
cat(sprintf("label (%s): %s\n", if (nzchar(PR_LABEL)) "RULED" else "NOT YET RULED: the builder's provenance label",
            out$provenance$label))
cat(sprintf("dropped %s: %.1f MB -> %.1f MB in memory\n", PR_DROP,
            as.numeric(utils::object.size(r)) / 2^20, as.numeric(utils::object.size(out)) / 2^20))
cat("ccx_ribbons_problems() at the canonical: none\n")
dir.create(dirname(PR_OUT), showWarnings = FALSE, recursive = TRUE)
saveRDS(out, PR_OUT)
cat(sprintf("wrote %s (md5 %s)\n", PR_OUT, unname(tools::md5sum(PR_OUT))))
