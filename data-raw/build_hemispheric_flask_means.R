# =====================================================================
# build_hemispheric_flask_means.R -- an OBSERVED hemispheric mean for CO2 AND
# d13C, built the same way, from the same flask network.
#
# THE PROBLEM THIS SOLVES (N5, Marcus 2026-09-22). For CO2 the station-vs-
# hemisphere comparison was a download: NOAA publishes a zonal MBL reference.
# ⛔ FOR d13C NO SUCH PRODUCT EXISTS -- measured, not assumed: the MBL form's
# parameter list is CO2/CH4/N2O/SF6, and `ghg.php?param=C13` returns an empty
# fragment with no generated file. So the hemispheric mean has to be BUILT.
#
# ⭐ AND CO2 IS BUILT HERE TOO, WHICH IS NOT REDUNDANT. `rep_dC` ties the two
# species by mass balance, so the test that matters is whether the MEASURED CO2
# offset predicts the MEASURED d13C one. Comparing a flask-network d13C average
# against NOAA's FITTED, SMOOTHED MBL reference would make that a comparison of
# two products as much as of two species -- the like-for-like rule. Same sites,
# same weighting, same months, same code, one species argument apart.
#
# ⭐ THE METHOD IS MARCUS'S RULING: "all sites, poleward-weighted, gaps dropped."
#   ALL SITES    -- every surface-flask site with a monthly record; no quality or
#                   length filter (D13C_MIN_MONTHS = 1). Sites the coordinate
#                   table omits are recovered from their own samples; only a
#                   record too MOBILE to place in a band is dropped, by measured
#                   spread and with that spread printed.
#   WEIGHTED     -- by LATITUDE-BAND AREA, equal steps in sin(latitude). This is
#                   NOAA's own MBL weighting, which is the reason to use it: the
#                   CO2 comparison already in hand was built that way.
#                   ⚠ It is also what "poleward-weighted" must mean
#                   operationally -- the network is dense in the tropical
#                   Pacific and sparse at high latitude, so an unweighted mean
#                   of SITES drowns the poles; area weighting gives each band
#                   its share however many sites sit in it. The two other
#                   readings are CARRIED as extra columns so the sensitivity to
#                   the wording is a measured number.
#   GAPS DROPPED -- no interpolation, no curve fitting. A site contributes to a
#                   month only if it reported; a band with no contributing site
#                   is dropped and the remaining band weights RENORMALIZED.
#                   ⚠ CONSEQUENCE: the contributing set changes month to month,
#                   so some month-to-month variability is network turnover, not
#                   atmosphere. Hence the comparisons downstream are MEANS OVER
#                   DECADES, and the band/site counts travel with the product.
#
# Writes data/obs_d13c_hemispheric.rds and data/obs_co2_hemispheric_flask.rds.
# Usage:  Rscript data-raw/build_hemispheric_flask_means.R
# =====================================================================
.root <- local({
  d <- normalizePath(getwd(), mustWork = FALSE)
  for (i in 1:8) { if (file.exists(file.path(d, "DESIGN.md"))) break; d <- dirname(d) }
  d
})
setwd(.root)

SPECIES <- list(
  d13c = list(ftp  = "https://gml.noaa.gov/aftp/data/trace_gases/co2c13/flask/surface/",
              pat  = "co2c13_%s_surface-flask_1_sil_month.txt",
              evt  = "co2c13_%s_surface-flask_1_sil_event.txt",
              rex  = "co2c13_([a-z0-9]+)_surface-flask_1_sil_month\\.txt",
              out  = "obs_d13c_hemispheric.rds", lo = -30, hi = 0, unit = "permil"),
  co2  = list(ftp  = "https://gml.noaa.gov/aftp/data/trace_gases/co2/flask/surface/txt/",
              pat  = "co2_%s_surface-flask_1_ccgg_month.txt",
              evt  = "co2_%s_surface-flask_1_ccgg_event.txt",
              rex  = "co2_([a-z0-9]+)_surface-flask_1_ccgg_month\\.txt",
              out  = "obs_co2_hemispheric_flask.rds", lo = 200, hi = 600, unit = "ppm"))

SITEPAGE <- "https://gml.noaa.gov/dv/site/?program=ccgg&type=Surface"
# ---------------------------------------------------------------------
# THE MARINE ARM (2026-09-22). Marcus's ruling is ALL SITES and that stays the
# primary; this carries the other arm of the question beside it in the same
# product, so the downstream tie test can be read both ways without a second
# build and without either arm being the one somebody has to re-derive.
#
# WHY IT IS NOT A DETAIL: the model's box is a MASS-weighted hemisphere. NH
# continental boundary-layer air is roughly 6 % of NH atmospheric mass (land
# fraction ~0.39 x BL mass fraction ~0.15) while latitude-band-area weighting
# gives it its AREA share -- so the all-sites mean weights continental air
# several-fold above the mass it represents, and the MBL product weights it at
# zero. The truth is between, nearer MBL. Carrying both measures the gap
# instead of arguing about it.
#
# ⭐ THE SUBSET IS NOAA'S OWN (data-raw/downloads/mbl_sites_co2.txt, fetched by
# download_data.R), never a coastal/elevation rule invented here.
MBL_SITES_FILE <- file.path(.root, "data-raw", "downloads", "mbl_sites_co2.txt")
# The stations the hemispheric mean is differenced against downstream. ⚠ The
# all-sites NH mean CONTAINS Mauna Loa, i.e. the very station it is compared
# with, which pulls the mean toward the station and SHRINKS the offset. NOAA's
# MBL selection drops MLO (altitude) and so removes that for the NH on its own;
# it KEEPS South Pole, so the SH arm carries the same self-inclusion and a third
# arm measures it.
SELF_STATION <- c(NH = "mlo", SH = "spo")

MBL_CODES <- local({
  if (!file.exists(MBL_SITES_FILE))
    stop("the MBL site list is missing: ", MBL_SITES_FILE,
         "\n  run data-raw/download_data.R (fetch_mbl_sites) first -- this build",
         "\n  will NOT fall back to an invented marine rule.")
  d <- utils::read.table(MBL_SITES_FILE, comment.char = "#",
                         col.names = c("code", "lat", "lon"),
                         stringsAsFactors = FALSE)
  if (nrow(d) < 20 || !"spo" %in% d$code || "mlo" %in% d$code)
    stop("the MBL site list is not what it should be (", nrow(d),
         " sites, spo ", "spo" %in% d$code, ", mlo ", "mlo" %in% d$code, ")")
  cat(sprintf("[mbl] %d sites in NOAA's CO2 MBL selection\n", nrow(d)))
  sort(d$code)
})
NBAND    <- 12   # equal-area bands per hemisphere, in sin(lat)
MIN_MONTHS <- 1  # "all sites" (Marcus): only a site with NO data is dropped
# A record whose samples span more than this cannot be placed in a latitude band
# and is dropped WITH ITS MEASURED SPREAD PRINTED. 10 deg is under half a band
# at the equator (~7.7 deg there) and comfortably admits the `poc*` ship grids,
# whose measured spreads are 1.9-3.3 deg. It drops `wpc` (62.9 deg, both
# hemispheres) and nothing else.
MAX_LAT_SPREAD <- 10
CACHE <- file.path(.root, "data-raw", "downloads", "noaa_flask_monthly")
dir.create(CACHE, recursive = TRUE, showWarnings = FALSE)

# ---- the site list, with coordinates --------------------------------
cat("[1] site coordinates\n")
html <- paste(readLines(url(SITEPAGE), warn = FALSE), collapse = "\n")
# ⚠ `(?s)` IS LOAD-BEARING. R's `.` does not match a newline even under
# perl = TRUE, and this table's cells span lines -- without it the row regex
# matches nothing, the frame comes back NULL, and the failure surfaces much
# later as "'by' must specify a uniquely valid column" from merge().
rows <- regmatches(html, gregexpr("(?s)<tr[^>]*>.*?</tr>", html, perl = TRUE))[[1]]
cells <- lapply(rows, function(r) {
  cc <- regmatches(r, gregexpr("(?s)<t[dh][^>]*>.*?</t[dh]>", r, perl = TRUE))[[1]]
  trimws(gsub("<[^>]+>", "", cc))
})
cells <- Filter(function(c) length(c) >= 5 && grepl("^[A-Z0-9]{3}[*]?$", c[1]), cells)
SITES0 <- do.call(rbind, lapply(cells, function(c)
  data.frame(code = tolower(sub("[*]$", "", c[1])),
             lat = suppressWarnings(as.numeric(c[4])), stringsAsFactors = FALSE)))
SITES0 <- SITES0[!is.na(SITES0$lat), ]
SITES0 <- SITES0[!duplicated(SITES0$code), ]
# fail HERE, where the cause is visible, not three steps later inside merge()
if (is.null(SITES0) || !nrow(SITES0))
  stop("parsed no sites from ", SITEPAGE, " -- the page layout has changed")
cat(sprintf("    %d surface sites with coordinates\n", nrow(SITES0)))

cache_get <- function(sp, code, which = c("pat", "evt")) {
  which <- match.arg(which)
  f <- file.path(CACHE, sprintf(sp[[which]], code))
  if (!file.exists(f))
    try(utils::download.file(paste0(sp$ftp, basename(f)), f, quiet = TRUE, mode = "wb"),
        silent = TRUE)
  if (!file.exists(f) || file.info(f)$size < 200) NULL else f
}

read_site <- function(sp, code) {
  f <- cache_get(sp, code, "pat"); if (is.null(f)) return(NULL)
  d <- try(utils::read.table(f, comment.char = "#",
                             col.names = c("site", "year", "month", "value")), silent = TRUE)
  if (inherits(d, "try-error") || !nrow(d)) return(NULL)
  # ⚠ RANGE FILTER, NOT A SENTINEL TEST. These files use more than one
  # missing-value convention (-99.99, -999.99); a plausible-range gate catches
  # every one of them and also a corrupted row, without a list to maintain.
  d <- d[is.finite(d$value) & d$value > sp$lo & d$value < sp$hi, ]
  if (!nrow(d)) return(NULL)
  data.frame(code = code, year = d$year, month = d$month, value = d$value)
}

# ⭐ A site the coordinate table omits gets its latitude from ITS OWN SAMPLES,
# and a MOBILE record is rejected by MEASUREMENT rather than by name. 22 of the
# d13C records are ship tracks and cruises (`poc*`, `scs*`, `wpc`) plus one land
# site (`obn`) the Surface listing does not carry. VALIDATED: `pocn05` and
# `pocs30` come back at exactly +5.00 and -30.00 -- the nominal latitude their
# CODE encodes -- so this agrees with NOAA's convention where one exists.
site_lat_from_events <- function(sp, code) {
  f <- cache_get(sp, code, "evt"); if (is.null(f) || file.info(f)$size < 1000) return(NULL)
  ln <- readLines(f, warn = FALSE); ln <- ln[!startsWith(ln, "#")]
  la <- suppressWarnings(as.numeric(vapply(strsplit(trimws(ln), "\\s+"), function(x)
    if (length(x) >= 22) x[22] else NA_character_, "")))
  la <- la[is.finite(la) & abs(la) <= 90]
  if (length(la) < 10) return(NULL)
  data.frame(code = code, lat = stats::median(la), spread = diff(range(la)),
             stringsAsFactors = FALSE)
}

build <- function(nm, codes) {
  sp <- SPECIES[[nm]]
  cat(sprintf("\n[%s] monthly files\n", nm))
  dat <- do.call(rbind, Filter(Negate(is.null), lapply(codes, function(c) read_site(sp, c))))
  dat <- merge(dat, SITES0, by = "code")
  n_per <- table(dat$code)
  dat <- dat[dat$code %in% names(n_per)[n_per >= MIN_MONTHS], ]
  cat(sprintf("    %d sites contribute %d site-months, %d-%d\n",
              length(unique(dat$code)), nrow(dat), min(dat$year), max(dat$year)))

  edges <- seq(0, 1, length.out = NBAND + 1)
  dat$hemi <- ifelse(dat$lat >= 0, "NH", "SH")
  dat$band <- findInterval(pmin(abs(sin(dat$lat * pi / 180)), 1 - 1e-12), edges)
  ea <- function(d) { bm <- stats::aggregate(value ~ band, data = d, FUN = mean); mean(bm$value) }

  # One aggregation, run on each site subset. Every arm is EXACTLY the same
  # estimator on a different network, which is what makes the arms comparable.
  arm <- function(d0, suffix) {
    if (!nrow(d0)) return(NULL)
    parts <- split(d0, interaction(d0$hemi, d0$year, d0$month, drop = TRUE))
    out <- do.call(rbind, lapply(parts, function(d) data.frame(
      hemi = d$hemi[1], year = d$year[1], month = d$month[1],
      equalarea  = ea(d),
      unweighted = mean(d$value),
      coslat     = stats::weighted.mean(d$value, cos(d$lat * pi / 180)),
      n_band = length(unique(d$band)), n_site = length(unique(d$code)))))
    if (nzchar(suffix))
      names(out)[-(1:3)] <- paste0(names(out)[-(1:3)], suffix)
    out[order(out$hemi, out$year, out$month), ]
  }

  hm <- arm(dat, "")
  # MARINE arm, and MARINE MINUS THE STATION ITSELF. Merged on hemi/year/month,
  # all.x = TRUE: a month with no marine site is NA in that arm rather than
  # dropping the month from the primary, which would silently change the
  # all-sites answer the ruling asked for.
  d_mbl  <- dat[dat$code %in% MBL_CODES, ]
  d_self <- d_mbl[d_mbl$code != SELF_STATION[d_mbl$hemi], ]
  for (a in list(list(d_mbl, "_mbl"), list(d_self, "_mblx"))) {
    z <- arm(a[[1]], a[[2]])
    if (!is.null(z)) hm <- merge(hm, z, by = c("hemi", "year", "month"), all.x = TRUE)
  }
  hm <- hm[order(hm$hemi, hm$year, hm$month), ]; rownames(hm) <- NULL
  attr(hm, "species")  <- nm
  attr(hm, "units")    <- sp$unit
  attr(hm, "source")   <- paste("NOAA GML Carbon Cycle Cooperative Global Air Sampling",
                                "Network, surface-flask monthly means;", sp$ftp,
                                "Site coordinates from gml.noaa.gov/dv/site.")
  attr(hm, "accessed") <- format(Sys.Date())
  attr(hm, "method")   <- paste("Marcus 2026-09-22: all sites, latitude-band-area",
                                "(equal sin-lat,", NBAND, "bands/hemisphere) weighted,",
                                "gaps dropped -- no interpolation, empty bands dropped and",
                                "weights renormalised. `unweighted` and `coslat` carried for",
                                "sensitivity to the wording.")
  attr(hm, "n_sites")  <- length(unique(dat$code))
  attr(hm, "sites")    <- sort(unique(dat$code))
  # The marine arm's provenance travels IN the product, so a reader never has to
  # take the script's word for which sites it is.
  attr(hm, "arms") <- paste(
    "`equalarea`/`unweighted`/`coslat` = ALL sites (the ruling, primary).",
    "`*_mbl` = NOAA's own CO2 MBL site selection (gml.noaa.gov/ccgg/mbl/,",
    "see data-raw/downloads/mbl_sites_co2.txt) -- the MARINE arm.",
    "`*_mblx` = the marine arm with the comparison station itself removed",
    "(mlo from NH, spo from SH); NH *_mbl already excludes mlo, so NH *_mbl and",
    "*_mblx are identical BY CONSTRUCTION and SH is where this arm bites.")
  attr(hm, "mbl_sites") <- sort(intersect(unique(dat$code), MBL_CODES))
  attr(hm, "n_mbl")     <- length(attr(hm, "mbl_sites"))
  # ⚠ BOTH SPECIES ARE BUILT ON THIS SAME SET, so the tie test downstream is
  # comparing chemistry and not networks. Recorded in the product so a reader
  # does not have to take the script's word for it.
  attr(hm, "common_site_set") <- TRUE
  out <- file.path(.root, "data", sp$out)
  saveRDS(hm, out)
  cat(sprintf("    wrote %s (%d hemisphere-months)\n", basename(out), nrow(hm)))
  for (h in c("NH", "SH")) {
    k <- hm$hemi == h
    cat(sprintf("    %s: %d-%d, median %d bands / %d sites per month\n", h,
                min(hm$year[k]), max(hm$year[k]),
                stats::median(hm$n_band[k]), stats::median(hm$n_site[k])))
  }
  invisible(hm)
}

# ---------------------------------------------------------------------
# ⭐ LATITUDES ARE RESOLVED ONCE, ACROSS SPECIES, AND THE TWO PRODUCTS ARE BUILT
# ON THE SAME SITES. Both are required for the tie test and neither is optional:
#
#   1. A SITE'S LATITUDE IS A PROPERTY OF THE SITE, NOT THE SPECIES. The CO2
#      ship records (`poc*`, `scs*`) have NO event file at all -- measured: the
#      URL 404s and only the monthly file exists -- so resolving latitudes
#      per-species lost all 21 of them for CO2 while d13C kept them, and the
#      CO2 mean was then built on a network missing the entire Pacific ship
#      grid. The resolver now tries EVERY species' event files for a code.
#   2. THE TIE TEST NEEDS THE SAME NETWORK. Its whole question is whether the
#      measured CO2 offset predicts the measured d13C one; if the two means come
#      from different site sets, a disagreement could be the networks rather
#      than the chemistry. So both are built on the INTERSECTION, and what each
#      species gives up to that is printed.
# ---------------------------------------------------------------------
usable <- lapply(names(SPECIES), function(nm) {
  sp <- SPECIES[[nm]]
  idx <- paste(readLines(url(sp$ftp), warn = FALSE), collapse = "\n")
  unique(sub(sp$rex, "\\1", unique(regmatches(idx, gregexpr(sp$rex, idx))[[1]])))
})
names(usable) <- names(SPECIES)
all_codes <- sort(unique(unlist(usable)))
need <- setdiff(all_codes, SITES0$code)
cat(sprintf("\n[lat] %d code(s) absent from the coordinate table; resolving from event files\n",
            length(need)))
resolved <- do.call(rbind, Filter(Negate(is.null), lapply(need, function(cd) {
  for (nm in names(SPECIES)) {
    r <- site_lat_from_events(SPECIES[[nm]], cd)
    if (!is.null(r)) return(r)
  }
  NULL
})))
if (!is.null(resolved)) {
  mob <- resolved[resolved$spread > MAX_LAT_SPREAD, ]
  if (nrow(mob)) for (i in seq_len(nrow(mob)))
    cat(sprintf("    ⚠ DROPPED %s: samples span %.1f deg of latitude (limit %.0f) -- mobile\n",
                mob$code[i], mob$spread[i], MAX_LAT_SPREAD))
  resolved <- resolved[resolved$spread <= MAX_LAT_SPREAD, ]
  cat(sprintf("    resolved %d of %d\n", nrow(resolved), length(need)))
  SITES0 <- rbind(SITES0, data.frame(code = resolved$code, lat = resolved$lat))
}
COMMON <- Reduce(intersect, usable)
COMMON <- intersect(COMMON, SITES0$code)
cat(sprintf("[common] %d sites carry BOTH species and have a latitude", length(COMMON)))
cat(sprintf(" (of %d d13C, %d CO2)\n", length(usable$d13c), length(usable$co2)))

for (nm in names(SPECIES)) build(nm, COMMON)
