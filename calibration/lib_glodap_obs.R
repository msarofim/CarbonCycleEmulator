# =====================================================================
# lib_glodap_obs.R -- the GLODAPv2.2023 bottle subset, binned onto a model grid.
# PURE DATA. It reads a CSV and returns numbers; it touches no model file and
# installs no wrapper.
#
# ⭐ EXTRACTED 2026-09-02 from calibration/pump_shim.R, VERBATIM. The reason is
# not tidiness. GATE G (ocean DIC level against GLODAP) needs exactly these three
# helpers, and `pump_shim.R` CANNOT be sourced to get them: it wraps `ccx_deriv()`
# in the global environment, so sourcing it into a gate report would change the
# model the gates are measuring. The alternative -- a second copy of the binning
# -- is the caption-sync bug class this repo has been bitten by (`dg_annual_sinks`
# was extracted in 08-31 for the same reason: "a second copy of an estimator is
# the day the end handling changes in one and the two report the same quantity at
# two values with nothing saying so").
#
# ⚠ SAFE TO SOURCE TWICE. Everything here is a pure function or a constant; there
# is no wrapper to re-capture and so no double-source guard is needed. That is
# precisely the property `pump_shim.R` does not have.
#
# ⚠ THE CSV IS GITIGNORED (853 MB uncompressed upstream; this is a 3.2 MB subset).
# A fresh clone must re-download and re-run the awk extraction -- the command is
# in the CHANGELOG entry for the original pull. Callers that need it should FAIL
# LOUDLY rather than skip.
#
# SOURCE. GLODAPv2.2023 Merged Master File, glodap.info, doi:10.25921/z7hc-v261;
# Lauvset et al. (2024), Earth Syst. Sci. Data 16:2047, doi:10.5194/essd-16-2047-2024.
# =====================================================================

# ---------------------------------------------------------------------
# THE OBSERVED PROFILE, ON THE MODEL'S OWN LAYERS. The export field is solved
# against a TARGET PROFILE, so the binning that produces that profile is part of
# the pump's construction and lives here with it.
#
# Same volume-weighting as data-raw/build_glodap_deep_targets.R (bin to
# 5 deg lat x 10 deg lon x 250 m, weight cells by cos(lat)) -- GLODAP bottles
# over-sample the Atlantic, so a raw bottle mean is biased. dg_bin() returns the
# raw mean beside it so the size of that bias stays visible.
# ---------------------------------------------------------------------
PUMP_GLODAP  <- ccx_path("data-raw", "downloads", "glodap_c13c14_subset.csv")
PUMP_FLAG_OK <- 2                          # GLODAP: 2 = acceptable measurement
PUMP_DLAT <- 5; PUMP_DLON <- 10; PUMP_DZ <- 250   # binning, as the build script

#' The GLODAPv2.2023 bottle subset, read once per session.
dg_glodap_bottles <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) cache <<- utils::read.csv(PUMP_GLODAP)
    cache
  }
})

#' Volume-weighted mean of one GLODAP field over a depth slab
dg_bin <- function(val, flag, zmin, zmax) {
  d  <- dg_glodap_bottles()
  ok <- is.finite(d[[val]]) & d[[val]] > -900 &
        is.finite(d[[flag]]) & d[[flag]] == PUMP_FLAG_OK &
        d$depth >= zmin & d$depth < zmax
  if (sum(ok) < 20) return(list(n = sum(ok), vw = NA_real_, raw = NA_real_,
                                sd = NA_real_))
  x    <- d[ok, ]
  id   <- paste(floor(x$lat / PUMP_DLAT), floor(x$lon / PUMP_DLON),
                floor(x$depth / PUMP_DZ))
  cell <- tapply(x[[val]], id, mean)
  w    <- cos(tapply(x$lat, id, mean) * pi / 180)
  list(n = sum(ok), n_cells = length(cell), raw = mean(x[[val]]),
       vw = sum(cell * w) / sum(w), sd = stats::sd(cell))
}

#' Observed DIC / d13C / D14C on the layers of a given grid
dg_obs_profile <- function(grid) {
  zb <- c(0, cumsum(grid$dz))
  do.call(rbind, lapply(seq_along(grid$dz), function(k) {
    a <- zb[k]; b <- zb[k + 1]
    rc <- dg_bin("tco2", "tco2f", a, b)
    r3 <- dg_bin("c13",  "c13f",  a, b)
    r4 <- dg_bin("c14",  "c14f",  a, b)
    data.frame(k = k - 1L, top = a, bot = b,
               n_dic = rc$n, dic = rc$vw, dic_raw = rc$raw, dic_sd = rc$sd,
               n_d13 = r3$n, d13 = r3$vw, d13_sd = r3$sd,
               n_d14 = r4$n, d14 = r4$vw, d14_sd = r4$sd)
  }))
}

