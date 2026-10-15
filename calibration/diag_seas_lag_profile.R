# =====================================================================
# diag_seas_lag_profile.R -- IS THE (3.5 + LAG)/12 SEASONAL PHASE
# CONVENTION WRONG? Profile the two lag constants at the adopted mode.
#
# THE CLAIM UNDER TEST, from handoff 2026-08-20 section 3a: every seasonal
# driver peaks 1-2 months later than climatology (NH SST Oct, land T Sep,
# NPP Aug), the `(3.5 + LAG)/12` convention already bakes a mid-July peak into
# the zero-lag case, and `CCX_SEAS_T_LAG = 2.0` then pushes the land-T peak to
# mid-September while the constant's own comment says "peak after Jun".
#
# WHY IT NEEDS ITS OWN SCRIPT. Both lags are COMPILE-TIME constants -- R-side
# in R/model.R and a hardcoded twin in src/ccx_core.cpp as `static const
# double` -- so they cannot be varied inside one R session. Each point needs a
# source patch, a rebuild and a fresh process. This script does that in a
# COPY under tempdir(); it never writes to the working tree. (Handoff section 2:
# never edit a script a long job is executing -- the same discipline applied to
# the model source.)
#
# THE SLICE IS BIASED TOWARD THE INCUMBENT, and that has to be said before the
# numbers: the mode was FITTED at (2.0, 2.5) and no challenger is re-optimized,
# which is exactly the `match_incumbents_optim` trap -- a fitted incumbent
# against a grid challenger bought 309 log-units of pure artifact last time.
# So a challenger that LOSES here proves little. A challenger that WINS, or a
# margin far larger than that artifact scale, is the informative outcome.
#
# Usage:  Rscript calibration/diag_seas_lag_profile.R
# =====================================================================
for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)

LAGP_MODE_FILE <- ccx_mode_file()
LAGP_T_GRID    <- c(0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0)   # CCX_SEAS_T_LAG, months
LAGP_S_GRID    <- c(0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5)   # CCX_SST_SEAS_LAG, months
LAGP_T_HOLD    <- CCX_SEAS_T_LAG                          # shipped, held in the S sweep
LAGP_S_HOLD    <- CCX_SST_SEAS_LAG                        # shipped, held in the T sweep

root <- ccx_root()
work <- file.path(tempdir(), "ccx_lag_profile")
unlink(work, recursive = TRUE); dir.create(file.path(work, dirname(LAGP_MODE_FILE)),
                                           recursive = TRUE, showWarnings = FALSE)
for (d in c("R", "src", "data")) file.copy(file.path(root, d), work, recursive = TRUE)
file.copy(file.path(root, "DESIGN.md"), work)                 # the repo-root marker
file.copy(file.path(root, LAGP_MODE_FILE), file.path(work, LAGP_MODE_FILE))

# The per-point worker. Gates that the patch actually took before it spends a
# model run -- a silently unpatched constant would return the incumbent's number
# under a challenger's label, which is the worst possible failure here.
writeLines(c(
'for (f in list.files("R", pattern = "R$", full.names = TRUE)) source(f)',
'ccx_load_cpp()',
'a <- as.numeric(commandArgs(TRUE))',
'stopifnot(abs(CCX_SEAS_T_LAG - a[1]) < 1e-9, abs(CCX_SST_SEAS_LAG - a[2]) < 1e-9)',
'md <- readRDS(ccx_mode_file())',
'b <- ccx_default_params(); b$pump_mode <- md$pump_mode',
'obs <- ccx_prepare_obs()',
'p <- b; for (n in intersect(names(p), names(md$par_mode))) p[[n]] <- md$par_mode[[n]]',
'sp <- ccx_spinup(p)',
'F <- ccx_build_forcing("historical", c(1750, 2024), prod_c14 = 0, bomb_total_kmol = 102)',
'F$c14_cosmo <- sp$prod_c14',
'out <- ccx_run_fast(sp, F)$out',
'bs <- ccx_loglik(out, obs, err = p, by_stream = TRUE)',
'ms <- ccx_model_stats(out, obs)',
'amp <- function(x) 2 * mean(sqrt(x$a^2 + x$b^2))',
'pk  <- function(x) (atan2(mean(x$a), mean(x$b)) / (2 * pi)) %% 1',
'dmo <- function(m, o) ((pk(m) - pk(o) + 0.5) %% 1 - 0.5) * 12',
'sq <- grep("seasonal", names(bs), value = TRUE)',
'cat(sprintf("RESULT %.2f %.2f %.3f %.3f %.4f %.3f %s\\n", a[1], a[2],',
'  sum(unlist(bs)), sum(unlist(bs[sq])), amp(ms$co2_seas$MLO),',
'  dmo(ms$co2_seas$MLO, obs$co2_seas$MLO),',
'  paste(sprintf("%s=%.1f", sub("_seasonal", "", sq), unlist(bs[sq])), collapse = " ")))'),
con = file.path(work, "one_lag.R"))

point <- function(tl, sl) {
  m <- readLines(file.path(work, "R", "model.R"))
  m <- sub("^CCX_SEAS_T_LAG   <- [0-9.]+", sprintf("CCX_SEAS_T_LAG   <- %s", tl), m)
  m <- sub("^CCX_SST_SEAS_LAG <- [0-9.]+", sprintf("CCX_SST_SEAS_LAG <- %s", sl), m)
  writeLines(m, file.path(work, "R", "model.R"))
  cc <- readLines(file.path(work, "src", "ccx_core.cpp"))
  cc <- sub("^static const double SEAS_T_LAG = [0-9.]+;",
            sprintf("static const double SEAS_T_LAG = %s;", tl), cc)
  cc <- sub("^static const double SST_SEAS_LAG = [0-9.]+;",
            sprintf("static const double SST_SEAS_LAG = %s;", sl), cc)
  writeLines(cc, file.path(work, "src", "ccx_core.cpp"))
  stopifnot(any(grepl(sprintf("SEAS_T_LAG = %s;", tl), cc, fixed = TRUE)),
            any(grepl(sprintf("SST_SEAS_LAG = %s;", sl), cc, fixed = TRUE)))
  o <- suppressWarnings(system2("Rscript", c("one_lag.R", tl, sl),
                                stdout = TRUE, stderr = FALSE))
  r <- grep("^RESULT", o, value = TRUE)
  if (!length(r)) sprintf("RESULT %s %s FAILED", tl, sl) else r[1]
}

owd <- setwd(work); on.exit(setwd(owd))
cat(sprintf("profiling at %s (arm %s mode), shipped values T=%.1f S=%.1f\n\n",
            LAGP_MODE_FILE, CCX_MODE_CANONICAL, LAGP_T_HOLD, LAGP_S_HOLD))
cat("Everything except the profiled constant is FROZEN at the mode. See the\n")
cat("header: the incumbent is fitted here and the challengers are not.\n\n")
show <- function(lines, what) {
  cat(sprintf("\n--- %s ---\n", what))
  cat(sprintf("%7s %7s %12s %12s %9s %8s  %s\n",
              "T_LAG", "SST_LAG", "total_logL", "seas_logL", "MLO_p2p", "MLO_dmo", "per-stream"))
  for (l in lines) {
    f <- strsplit(sub("^RESULT ", "", l), " ")[[1]]
    cat(sprintf("%7s %7s %12s %12s %9s %8s  %s\n", f[1], f[2], f[3], f[4], f[5], f[6],
                paste(f[-(1:6)], collapse = " ")))
  }
}
show(vapply(LAGP_T_GRID, function(t) point(t, LAGP_S_HOLD), character(1)),
     sprintf("CCX_SEAS_T_LAG sweep (SST lag held at %.1f)", LAGP_S_HOLD))
show(vapply(LAGP_S_GRID, function(s) point(LAGP_T_HOLD, s), character(1)),
     sprintf("CCX_SST_SEAS_LAG sweep (land-T lag held at %.1f)", LAGP_T_HOLD))
cat("\nobserved MLO CO2 peak-to-peak, 1975-2024: 6.764 ppm (NOT 3.02 -- that is\n")
cat("the SEMI-amplitude; see diag_sst_seas_zeroing.R's correction block).\n")
