#!/usr/bin/env Rscript
# =====================================================================
# build_review_precompute.R -- the Known-issues tab's expensive values, computed once (2026-10-15).
#
# Marcus 2026-10-15: "Precompute the known issues". The tab's first view ran, live: the canonical's gate run
# (1750-2025; cards 2, 3, 4), the ENSO knockout re-run (card 4b) and the pulse (PD100 + the 1000-year partition;
# card 5). On Connect Cloud's 1 CPU that took 30.7 s once (CHANGELOG 2026-10-15 w). This stores the rv_memo()
# value of every key in RV_PRE_KEYS (app/R/review.R) at the canonical, computed by the SAME functions the app
# calls, so the tab reads them instead of running them.
#
# The product names the canonical's mode file by md5; the app refuses one made at another (it then computes live,
# as before). It is computed with options(ccx.rv_precompute = FALSE), so it never reads the product it replaces.
# tests/testthat/test-review-precompute.R recomputes every key live and compares, so a code change that moves a
# value fails the suite until this is re-run.
#
# Output: data/review_precompute.rds (+ outputs/diagnostics/review_precompute_<date>_<canonical>.log). No RNG.
# Usage:  Rscript calibration/build_review_precompute.R      (from the repo root)
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)
ccx_load_cpp()

RVP_DRIVER <- "calibration/build_review_precompute.R"
options(ccx.rv_precompute = FALSE)          # compute live; never read the product being rebuilt
rv <- new.env(parent = globalenv())
sys.source(file.path("app", "R", "review.R"), envir = rv)

RVP_OUT <- do.call(file.path, as.list(rv$RV_PRE_FILE))
RVP_LOG <- file.path("outputs", "diagnostics",
                     sprintf("review_precompute_%s_%s.log", format(Sys.Date(), "%Y%m%d"), CCX_MODE_CANONICAL))
COMMIT  <- ccx_git_stamp(exclude = RVP_OUT)

say <- function(...) { txt <- sprintf(...); cat(txt); cat(txt, file = RVP_LOG, append = TRUE) }
if (file.exists(RVP_LOG)) file.remove(RVP_LOG)
mode_file <- ccx_mode_file(); md5 <- unname(tools::md5sum(mode_file))
# repo-relative in the product: it ships in the public repository and the deploy bundle
mode_rel <- sub(paste0("^", normalizePath(ccx_root()), "/"), "", normalizePath(mode_file))
say("%s @%s | canonical %s (%s, md5 %s) | %s\n", RVP_DRIVER, COMMIT, CCX_MODE_CANONICAL, mode_rel, md5,
    format(Sys.time(), "%Y-%m-%d %H:%M"))

values <- list(); secs <- numeric(0)
for (k in names(rv$RV_PRE_KEYS)) {
  t0 <- proc.time()[["elapsed"]]
  v <- get(rv$RV_PRE_KEYS[[k]], envir = rv)()
  secs[[k]] <- proc.time()[["elapsed"]] - t0
  if (rv$rv_failed(v)) stop("key '", k, "' failed: ", v$msg)
  values[[k]] <- v
  say("  %-12s %-16s %6.1f s  %8.1f kB\n", k, rv$RV_PRE_KEYS[[k]], secs[[k]],
      as.numeric(utils::object.size(v)) / 1024)
}

x <- list(values = values,
          provenance = list(driver = RVP_DRIVER, commit = COMMIT,
                            mode = CCX_MODE_CANONICAL, mode_file = mode_rel, mode_md5 = md5,
                            keys = rv$RV_PRE_KEYS, seconds = secs,
                            built = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
                            r_version = R.version.string, rng = "none",
                            note = paste("rv_memo() values of app/R/review.R's RV_PRE_KEYS at the canonical,",
                                         "computed live with options(ccx.rv_precompute = FALSE)")))
problems <- rv$rv_pre_problems(x, mode_file)
if (length(problems)) stop("the product would be refused: ", paste(problems, collapse = "; "))
saveRDS(x, RVP_OUT)
say("wrote %s (%.1f kB on disk; %.1f s of computation stored)\n", RVP_OUT,
    file.size(RVP_OUT) / 1024, sum(secs))
