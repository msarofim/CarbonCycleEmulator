#!/usr/bin/env Rscript
# =====================================================================
# build_app_precompute.R -- the app's start-up runs and the pulse lab's default, computed once (2026-10-20).
#
# A first visit to CarboTope on Connect Cloud waited 18-27 s on the loading page (the C++ compile, the 1750
# spin-up, the historical run and the one-year flux trace in app/global.R) and ~17 s for "Release the pulse" at
# its default settings (CHANGELOG 2026-10-20 a). This stores, at the canonical, the values the app would
# compute for both, by the SAME functions (app/global.R app_spinup(), app_hist_run(), app_flux_trace(),
# app_pulse_runs(); app/R/ocean_depth.R app_pulse_depth_runs()), so the app reads them instead of running them.
# The pattern is calibration/build_review_precompute.R's (2026-10-15).
#
# Each product names the canonical's mode file by md5 and records the run inputs it was built at
# (app_pre_inputs()); the app refuses one built at anything else and computes live, as before. Everything is
# computed with options(ccx.app_precompute = FALSE), so the build never reads the products it replaces.
# tests/testthat/test-app-precompute.R recomputes every value live and requires identity, so a code or data
# change that moves a value fails the suite until this is re-run. RE-RUN IT AT EVERY ADOPTION.
#
# Output: data/app_startup_precompute.rds (gzip: read at every start) and data/pulse_default_precompute.rds
# (xz: 2 MB, read on the first default release) + outputs/diagnostics/app_precompute_<date>_<canonical>.log.
# No RNG. Values are in the model's own units (GtC, ppm, GtC/yr, degC, years), exactly as the app computes them.
# Usage:  Rscript calibration/build_app_precompute.R      (from the repo root)
# =====================================================================
for (f in list.files("R", pattern = "[.]R$", full.names = TRUE)) source(f)

APD_DRIVER <- "calibration/build_app_precompute.R"
options(ccx.app_precompute = FALSE,   # compute live; never read the products being rebuilt
        ccx.cpp_prebuild = FALSE)     # compile in this process (no background build)
app <- new.env(parent = globalenv())
sys.source(file.path("app", "global.R"), envir = app)       # computes the start-up values live
for (f in sort(list.files(file.path("app", "R"), pattern = "[.]R$", full.names = TRUE)))
  sys.source(f, envir = app)

APD_OUT <- vapply(app$APP_PRE_FILES, function(p) do.call(file.path, as.list(p)), character(1))
APD_COMPRESS <- c(startup = "gzip", pulse = "xz")
APD_LOG <- file.path("outputs", "diagnostics",
                     sprintf("app_precompute_%s_%s.log", format(Sys.Date(), "%Y%m%d"), CCX_MODE_CANONICAL))
COMMIT  <- ccx_git_stamp(exclude = unname(APD_OUT))

say <- function(...) { txt <- sprintf(...); cat(txt); cat(txt, file = APD_LOG, append = TRUE) }
if (file.exists(APD_LOG)) file.remove(APD_LOG)
mode_file <- ccx_mode_file(); md5 <- unname(tools::md5sum(mode_file))
# repo-relative in the product: it ships in the public repository and the deploy bundle
mode_rel <- sub(paste0("^", normalizePath(ccx_root()), "/"), "", normalizePath(mode_file))
say("%s @%s | canonical %s (%s, md5 %s) | params: %s | %s\n", APD_DRIVER, COMMIT, CCX_MODE_CANONICAL, mode_rel,
    md5, app$app_params$source, format(Sys.time(), "%Y-%m-%d %H:%M"))
if (!identical(app$app_params$source, "posterior mode"))
  stop("the app did not load the canonical mode file (it resolved '", app$app_params$source, "')")

timed <- function(expr) {
  t0 <- proc.time()[["elapsed"]]; v <- force(expr)
  list(v = v, s = proc.time()[["elapsed"]] - t0)
}
# ---- the start-up values. global.R computed them while it was sourced; they are computed AGAIN here, timed,
# by the same functions, and must come out identical (a determinism check at no extra cost).
st <- list(spin = timed(app$app_spinup(app$APP_PARAMS)))
st$hist <- timed(app$app_hist_run(st$spin$v))
st$flux <- timed(app$app_flux_trace(st$spin$v))
for (k in names(st)) {
  ref <- get(c(spin = "APP_SPIN", hist = "APP_HIST", flux = "APP_FLUX")[[k]], envir = app)
  if (!identical(st[[k]]$v, ref)) stop("start-up value '", k, "' is not reproducible within one process")
}
# ---- the pulse lab's default: what app_pulse_lab() computes live for APP_PULSE_DEFAULTS, then the depth split
inp <- app$APP_PULSE_DEFAULTS
if (!app$app_pulse_is_default(inp)) stop("APP_PULSE_DEFAULTS is not judged the default")
pu <- list(runs = timed(app$app_pulse_lab(inp)))
if (!is.null(pu$runs$v$depth)) stop("app_pulse_lab() served a stored value with the product switched off")
pu$depth <- timed(app$app_pulse_depth_runs(app$APP_SPIN, pu$runs$v[c("base", "pulse", "tagged")], pu$runs$v$year))

parts <- list(startup = st, pulse = pu)
for (product in names(parts)) {
  p <- parts[[product]]
  stopifnot(identical(names(p), app$APP_PRE_KEYS[[product]]))
  secs <- vapply(p, `[[`, numeric(1), "s")
  x <- list(values = lapply(p, `[[`, "v"),
            inputs = app$app_pre_inputs(product),
            provenance = list(driver = APD_DRIVER, commit = COMMIT,
                              mode = CCX_MODE_CANONICAL, mode_file = mode_rel, mode_md5 = md5,
                              keys = app$APP_PRE_KEYS[[product]], seconds = secs,
                              built = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
                              r_version = R.version.string, platform = R.version$platform,
                              cpp_built_by = .ccx_cpp_env$built_by, rng = "none",
                              note = paste("app/global.R's", product, "values at the canonical, computed live",
                                           "with options(ccx.app_precompute = FALSE); model units")))
  problems <- app$app_pre_problems(x, product)
  if (length(problems)) stop("the ", product, " product would be refused: ", paste(problems, collapse = "; "))
  saveRDS(x, APD_OUT[[product]], compress = APD_COMPRESS[[product]])
  if (!identical(readRDS(APD_OUT[[product]]), x)) stop("the ", product, " product does not read back identical")
  for (k in names(secs))
    say("  %-8s %-6s %6.2f s  %8.1f kB in memory\n", product, k, secs[[k]],
        as.numeric(utils::object.size(x$values[[k]])) / 1024)
  say("wrote %s (%s, %.1f kB on disk; %.1f s of computation stored)\n", APD_OUT[[product]],
      APD_COMPRESS[[product]], file.size(APD_OUT[[product]]) / 1024, sum(secs))
}
