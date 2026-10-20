# =====================================================================
# downloads.R -- the data behind every chart (CSV) and the chart itself (PNG).
# 2026-10-20 (instructor-facing features: homework and sharing).
#
# ⭐ THE CSV IS READ OFF THE PLOT OBJECT, NOT REBUILT BESIDE IT. Each download
# calls the SAME function the chart's renderPlotFit() draws (server.R registers
# it there, by output id), and app_dl_table() evaluates each drawn layer's own
# aesthetic mapping on that layer's own data. A second copy of a chart's
# arithmetic written here for the CSV is how a download would come to disagree
# with the picture -- the caption-sync bug class with a new face.
# tests/testthat/test-app-downloads.R checks every chart's CSV against
# ggplot_build() of the same plot (what the device is handed), and
# mutation-tests that check.
#
# ⛔ WHAT A ROW IS. One drawn mark: a point, a vertex of a line, a bar, a band
# edge pair, a tile. Text, reference lines (geom_hline / geom_vline) and
# annotate() layers are not data and are left out. Values are the layer's own,
# BEFORE position adjustments: a stacked area lists each band's own value (its
# drawn top is the running sum, which the CSV header says).
#
# ⚠ plotOutput() IS WRAPPED HERE (app_dl_plot_output() below, assigned over the
# name). Every chart in ui.R and in server.R's renderUI blocks gets its two
# download links from that one place, so neither file names a download id, and
# a chart added later gets links the moment it has an APP_DL_SPEC entry.
# test-app-downloads.R fails if a plotOutput() id has no entry.
# =====================================================================

# ---- copy (DRAFT for Marcus; listed in CHANGELOG 2026-10-20 b) --------------
APP_DL_LEAD       <- "Download:"
APP_DL_LABEL_CSV  <- "data (CSV)"
APP_DL_LABEL_PNG  <- "figure (PNG)"
APP_DL_EMPTY      <- "Nothing is drawn on this chart yet, so there is nothing to download."
APP_DL_CSV_TITLE  <- "%s data download: %s"                    # APP_TITLE, chart name
APP_DL_PNG_FOOT   <- "%s. Model mode %s, code %s."             # release, mode, commit label
APP_DL_STACK_NOTE <- paste("Areas are stacked: each band is listed at its own value, and its top edge",
                           "on the chart is the running sum of the bands drawn below it.")
APP_DL_AXIS_FMT   <- "as labeled on the chart: %s"
APP_DL_DIAGRAM_LAYER   <- "arrow label"
APP_DL_DIAGRAM_DUP_FMT <- "%s (%d)"                            # a name printed on two arrows
APP_DL_DIAGRAM_NOTE    <- paste("One row per arrow, at the value its label rounds. A name printed on two",
                                "arrows is numbered (1), (2) from left to right on the diagram.")
APP_DL_AXIS_NONE  <- "the chart's categories"
APP_DL_ROW_NOTE   <- paste("One row per drawn mark (a line vertex, a point, a bar, a band edge pair",
                           "or a tile). Reference lines and text labels are not listed.")

# ---- file names: <app>_<version>_<chart>.<ext> --------------------------------
APP_DL_FILE_FMT   <- "%s_%s_%s.%s"
app_dl_filename <- function(id, ext) {
  sp <- app_dl_spec(id)
  sprintf(APP_DL_FILE_FMT, tolower(APP_TITLE), APP_VERSION, sp$stem, ext)
}

# ---- the PNG ------------------------------------------------------------------
# renderPlot() draws at 72 dpi times the screen's pixel ratio; the download is
# that drawing at APP_DL_PNG_SCALE x, so it matches what a high-density screen shows.
APP_DL_SCREEN_RES <- 72
APP_DL_PNG_SCALE  <- 2
# when a chart has not been laid out yet (Shiny reports no size): the full panel. A FUNCTION, because
# plots.R (APP_PANEL_PX) is sourced after this file (Shiny loads app/R/ alphabetically).
APP_DL_FALLBACK_HEIGHT_PX <- 400
app_dl_fallback_px <- function() c(width = APP_PANEL_PX[["full"]] + APP_PLOT_MARGIN_PX,
                                   height = APP_DL_FALLBACK_HEIGHT_PX)

# ---- the CSV ------------------------------------------------------------------
APP_DL_CSV_DIGITS <- 15      # significant digits: what write.csv() prints, read back to ~1e-15
APP_DL_CSV_BOM    <- TRUE    # a UTF-8 byte-order mark, so Excel reads CO₂, δ¹³C and ‰ correctly
APP_DL_COMMENT    <- "# "
# alpha below which a line or a set of points is the chart's "faint" one (the
# Keeling raw box 0.55, the δ¹³C raw box 0.35, the imbalance annual lines 0.32)
APP_DL_FAINT_ALPHA <- 0.6

# ---- provenance, resolved once per process --------------------------------------
APP_DL_MODE      <- CCX_MODE_CANONICAL
APP_DL_MODE_FILE <- tryCatch(ccx_mode_file(APP_DL_MODE), error = function(e) NA_character_)
APP_DL_MODE_MD5  <- if (!is.na(APP_DL_MODE_FILE) && file.exists(APP_DL_MODE_FILE))
  unname(tools::md5sum(APP_DL_MODE_FILE)) else NA_character_
# the deployed copy has no .git: make_deploy_bundle.sh writes FROZEN_FROM_COMMIT.txt
# (2026-10-20), which ccx_git_stamp() reads as "<hash>+frozen?"
APP_DL_COMMIT    <- ccx_git_stamp()
app_dl_commit_label <- function(stamp = APP_DL_COMMIT) {
  if (endsWith(stamp, CCX_STAMP_FROZEN))
    sprintf("%s (the deployed copy was built from this commit)", sub(CCX_STAMP_FROZEN, "", stamp, fixed = TRUE))
  else if (identical(stamp, CCX_STAMP_NONE)) "unknown (this copy carries no commit record)"
  else stamp
}

# ---- column definitions ---------------------------------------------------------
# c(name, definition). One definition per quantity, shared across charts.
DLC <- list(
  dyear    = c("decimal_year", "decimal year (the calendar year plus the fraction of it elapsed)"),
  year     = c("year", "calendar year"),
  yearmid  = c("year", "decimal year; each annual mean is placed at mid-year, and the release is at its 1 January"),
  co2      = c("co2_ppm", "atmospheric CO₂, parts per million of dry air (ppm)"),
  co2_seas = c("co2_minus_annual_mean_ppm", "CO₂ above its annual mean, ppm"),
  month    = c("month", "months since 1 January (0-12)"),
  cum_gtc  = c("cumulative_gtc", "carbon added since 1750, GtC (billion tonnes of carbon)"),
  af       = c("airborne_fraction", "share of all carbon emitted since 1750 still in the air (0-1)"),
  sink_lab = c("sink", "which sink"),
  gtc_yr   = c("gtc_per_year", "carbon flux, GtC per year"),
  growth   = c("co2_growth_ppm_per_year", "year-over-year change in the annual mean CO₂, ppm per year"),
  resid    = c("model_minus_measured_ppm_per_year", "model minus measured CO₂ growth, ppm per year"),
  d13c     = c("d13c_permil", "δ¹³C, per mil (‰) relative to the VPDB standard"),
  d14c     = c("d14c_permil", "Δ¹⁴C, per mil (‰)"),
  gmst     = c("temperature_c", "global mean surface temperature above 1850-1900, °C"),
  frac     = c("share_of_pulse", "share of the pulse still in the air (0-1)"),
  dT       = c("extra_warming_c", "extra warming caused by the pulse, °C"),
  pct      = c("percent_of_pulse", "percent of the pulse's carbon"),
  cm_part  = c("model_part", "part of the model"),
  cm_obs   = c("measurement", "what is measured"),
  cm_val   = c("loglik_units_moved", "log-likelihood units the measurement moves when that part of the model moves one step"),
  cm_pull  = c("loglik_units_gained", "log-likelihood units the measurement gains by moving the parameter"),
  cm_par   = c("parameter", "model parameter"),
  flow     = c("flow", "the arrow's name on the diagram"),
  flow_val = c("gtc_per_year", "carbon flow, GtC per year (sum of the two hemispheres)"))
DLC_LAYER  <- c("layer", "how the chart draws the row (line, faint line, dashed line, points, area, band, bars, error bars, tiles, fitted line)")
DLC_SERIES <- c("series", "the chart's legend entry")
DLC_PANEL  <- c("panel", "which side-by-side panel of the chart")
DLC_LOW    <- "lower edge of the drawn range, same unit as %s"
DLC_HIGH   <- "upper edge of the drawn range, same unit as %s"

# ---- sources ----------------------------------------------------------------------
DLS <- list(
  model    = function() sprintf("Model output: %s, computed live with the %s parameter set.",
                                APP_RELEASE_NAME, APP_DL_MODE),
  co2_obs  = function() paste("Measured CO₂: Mauna Loa monthly means (Scripps Institution of Oceanography",
                              "and NOAA Global Monitoring Laboratory); South Pole monthly flask means (NOAA GML)."),
  d13c_obs = function() "Measured δ¹³C: Mauna Loa and South Pole monthly flask means (NOAA GML and INSTAAR).",
  d14c_obs = function() "Measured Δ¹⁴C: the zonal atmospheric compilation of Hua et al. (2022).",
  gcb      = function() "Measured budget: Global Carbon Budget 2025.",
  luc      = function() paste("Land-use split: the Global Carbon Budget 2025 bookkeeping models;",
                              "this model does not measure it."),
  mbl      = function() {
    cit <- tryCatch(APP_OBS_GROWTH$provenance$citation, error = function(e) NULL)
    paste("Measured growth:", if (is.null(cit)) "NOAA GML marine boundary layer reference." else cit)
  },
  scen     = function() APP_SCENARIO_SRC,
  fair     = function() "FaIR lines, where drawn: FaIR 2.2.4 (calib 1.6.0), 841-configuration ensemble.",
  bands    = function() "Shaded ranges, where drawn: runs that vary the fitted carbon-cycle parameters (precomputed).",
  cmap     = function() sprintf("Computed from the %s fit by nudging each parameter (precomputed).", APP_DL_MODE),
  drivers  = function() "Prescribed model inputs; see Under the hood, “What drives the model”.",
  review   = function() "Measured from this model and the observations named on the card.")

# ---- one entry per chart ------------------------------------------------------------
# stem: file name part; chart: the name in the CSV header (DRAFT copy); x / y / value:
# DLC entries for the mapped aesthetics; sources: DLS keys; note: extra header line.
# A function entry is evaluated per call (charts whose labels are built at run time).
APP_DL_SPEC <- list(
  k_plot     = list(stem = "keeling_curve", chart = "CO₂ at Mauna Loa and the South Pole",
                    x = DLC$dyear, y = DLC$co2, sources = c("model", "co2_obs")),
  k_seasonal = list(stem = "seasonal_cycle", chart = "The average seasonal cycle of CO₂",
                    x = DLC$month, y = DLC$co2_seas, sources = c("model", "co2_obs")),
  w_partition = list(stem = "where_carbon_goes", chart = "Where the emitted carbon went",
                     x = DLC$dyear, y = DLC$cum_gtc, sources = c("model", "gcb"), note = APP_DL_STACK_NOTE),
  w_af       = list(stem = "airborne_fraction", chart = "Airborne fraction",
                    x = DLC$dyear, y = DLC$af, sources = "model"),
  w_gcb      = list(stem = "sinks_vs_budget", chart = "The model's sinks against the measured budget",
                    x = DLC$sink_lab, y = DLC$gtc_yr, sources = c("model", "gcb")),
  w_imbalance_plot = list(stem = "land_sink_imbalance", chart = "The land sink and the budget's imbalance",
                          x = DLC$year, y = DLC$gtc_yr, sources = c("model", "gcb")),
  w_regrowth_plot  = list(stem = "forest_regrowth", chart = "Land clearing and forest regrowth",
                          x = DLC$year, y = DLC$gtc_yr, sources = "luc"),
  c_plot     = list(stem = "what_if_co2", chart = "Global-average CO₂ with mechanisms switched off",
                    x = DLC$dyear, y = DLC$co2, sources = "model"),
  c_growth   = list(stem = "what_if_growth", chart = "Annual CO₂ growth rate",
                    x = DLC$year, y = DLC$growth, sources = c("model", "mbl")),
  c_resid    = list(stem = "what_if_growth_residual", chart = "Model minus measured CO₂ growth",
                    x = DLC$year, y = DLC$resid, sources = c("model", "mbl")),
  c_driver   = function(id) {
    nm <- sub("^c_driver_", "", id)
    d  <- CCX_DRIVERS[[CCX_MECHANISMS[[nm]]$driver]]
    list(stem = paste0("what_if_driver_", nm), chart = d$label,
         x = DLC$dyear, y = c("value", d$unit), sources = c("model", "drivers"))
  },
  i_d13c     = list(stem = "d13c", chart = "δ¹³C: the Suess effect",
                    x = DLC$dyear, y = DLC$d13c, sources = c("model", "d13c_obs")),
  i_d14c     = list(stem = "d14c", chart = "Δ¹⁴C: the bomb spike",
                    x = DLC$dyear, y = DLC$d14c, sources = c("model", "d14c_obs")),
  f_plot     = list(stem = "futures", chart = "Futures",
                    x = DLC$year, y = c("value", "CO₂ in ppm, temperature in °C above 1850-1900, or the pulse's share or warming, as on the chart's y axis"),
                    sources = c("model", "scen", "fair", "bands")),
  f_partition = list(stem = "pulse_partition", chart = "Where the extra carbon ends up",
                     x = DLC$dyear, y = DLC$pct, sources = "model", note = APP_DL_STACK_NOTE),
  cm_map     = list(stem = "constraint_map", chart = "Which parts of the model each measurement tests",
                    x = DLC$cm_part, y = DLC$cm_obs, value = DLC$cm_val, sources = "cmap"),
  cm_tension = list(stem = "constraint_tension", chart = "Where the measurements disagree",
                    x = DLC$cm_pull, y = DLC$cm_par, sources = "cmap"),
  h_diagram  = list(stem = "box_diagram", chart = "The model's boxes and the carbon flows between them",
                    x = DLC$flow, y = DLC$flow_val, sources = "model",
                    layer = "\u201carrow label\u201d: the number printed on an arrow", rows = APP_DL_DIAGRAM_NOTE))
# the Futures chart names its columns by what it is showing
APP_DL_FUTURE_Y <- list(co2_ppm = DLC$co2, gmst = DLC$gmst)
APP_DL_PULSE_Y  <- list(co2_ppm = DLC$frac, gmst = DLC$dT)
# the review cards: one entry each, named from the card (rv_card()) they sit on;
# the card numbers are ui.R's review_card() calls, asserted by test-app-downloads.R
APP_DL_RV_CARD <- c(rv_repdc = 1L, rv_gradient = 2L, rv_diseq = 3L, rv_variance = 4L, rv_enso = 4L,
                    rv_irf = 5L, rv_partition = 5L, rv_oclim = 8L, rv_oclim_stake = 8L)

#' The spec for one output id, or NULL for a chart with no downloads
app_dl_spec <- function(id) {
  if (!is.null(APP_DL_SPEC[[id]]) && is.list(APP_DL_SPEC[[id]])) return(APP_DL_SPEC[[id]])
  if (grepl("^c_driver_", id) && sub("^c_driver_", "", id) %in% names(CCX_MECHANISMS) &&
      !is.null(CCX_MECHANISMS[[sub("^c_driver_", "", id)]]$driver))
    return(APP_DL_SPEC$c_driver(id))
  if (id %in% names(APP_DL_RV_CARD)) {
    n <- APP_DL_RV_CARD[[id]]
    return(list(stem = sprintf("known_issue_%d_%s", n, sub("^rv_", "", id)),
                chart = sprintf("Known issue %d: %s", n, rv_card(as.numeric(n))$title),   # card ids are doubles
                x = c("x", NA_character_), y = c("y", NA_character_),
                sources = c("model", "review")))
  }
  NULL
}

# ---- the extractor ------------------------------------------------------------------
APP_DL_GEOM_WORD <- c(GeomLine = "line", GeomPath = "line", GeomStep = "line", GeomPoint = "points",
                      GeomArea = "area", GeomRibbon = "band", GeomCol = "bars", GeomBar = "bars",
                      GeomTile = "tiles", GeomRaster = "tiles", GeomErrorbar = "error bars",
                      GeomLinerange = "ranges", GeomPointrange = "points", GeomSmooth = "fitted line")
APP_DL_POS <- c("x", "y", "ymin", "ymax")
# The positions each geom DRAWS. A mark missing any of them is not drawn (ggplot drops it as
# missing), so it is not listed; an inherited `y` an error bar does not draw is not listed either.
APP_DL_GEOM_POS <- list(GeomRibbon = c("x", "ymin", "ymax"), GeomErrorbar = c("x", "ymin", "ymax"),
                        GeomLinerange = c("x", "ymin", "ymax"), GeomPointrange = c("x", "y", "ymin", "ymax"))
app_dl_geom_pos <- function(L) {
  k <- class(L$geom)[1]
  if (!is.null(APP_DL_GEOM_POS[[k]])) APP_DL_GEOM_POS[[k]] else c("x", "y")
}
APP_DL_GROUP_AES <- c("colour", "fill", "linetype", "shape", "group")

app_dl_is_annotation <- function(L) {
  k <- L$constructor
  is.call(k) && identical(k[[1]], quote(annotate))
}

#' The layers a CSV lists: indices into p$layers
app_dl_data_layers <- function(p) {
  which(vapply(p$layers, function(L)
    class(L$geom)[1] %in% names(APP_DL_GEOM_WORD) && !app_dl_is_annotation(L), logical(1)))
}

#' A layer's effective mapping: the plot's (when inherited), the layer's over it, minus set params
app_dl_mapping <- function(p, L) {
  m <- if (isTRUE(L$inherit.aes)) {
    m0 <- as.list(p$mapping); for (n in names(L$mapping)) m0[[n]] <- L$mapping[[n]]; m0
  } else as.list(L$mapping)
  m <- m[!vapply(m, is.null, logical(1))]
  m[setdiff(names(m), names(L$aes_params))]
}

app_dl_discrete <- function(v) is.character(v) || is.factor(v) || is.logical(v)

#' The facet variables of a plot, as quosures
app_dl_facets <- function(p) {
  f <- p$facet$params
  c(as.list(f$facets), as.list(f$rows), as.list(f$cols))
}

#' One layer's rows, in the layer's own units, before stat and position.
#' `stat_layer`: for a layer whose stat changes its data (geom_smooth's fit), the
#' drawn values from ggplot_build(), with each group mapped back to its legend entry.
app_dl_layer_rows <- function(p, i, built = NULL) {
  L <- p$layers[[i]]
  d <- L$layer_data(p$data)
  m <- app_dl_mapping(p, L)
  ev <- function(q) {
    v <- tryCatch(rlang::eval_tidy(q, data = d), error = function(e) NULL)
    if (is.null(v)) return(NULL)
    if (length(v) == 1L && nrow(d) != 1L) v <- rep(v, nrow(d))
    if (length(v) != nrow(d)) return(NULL)
    v
  }
  vals <- lapply(m, ev); vals <- vals[!vapply(vals, is.null, logical(1))]
  grp <- intersect(APP_DL_GROUP_AES, names(vals))
  grp <- grp[vapply(vals[grp], app_dl_discrete, logical(1))]
  series <- if (length(grp)) as.character(vals[[grp[1]]]) else NULL
  fac <- app_dl_facets(p)
  panel <- if (length(fac)) {
    pv <- lapply(fac, function(q) tryCatch(rlang::eval_tidy(q, data = d), error = function(e) NULL))
    pv <- pv[!vapply(pv, is.null, logical(1))]
    if (length(pv)) do.call(paste, c(lapply(pv, as.character), sep = " / ")) else NULL
  }
  stat_changes <- !inherits(L$stat, c("StatIdentity", "StatAlign"))
  if (stat_changes) {
    # the fit is what is drawn; ggplot_build() is the only source of it
    if (is.null(built)) built <- ggplot2::ggplot_build(p)
    b <- built$data[[i]]
    key <- if (length(grp)) { v <- vals[[grp[1]]]; if (is.factor(v)) levels(droplevels(v)) else sort(unique(as.character(v))) }
    out <- data.frame(x = b$x, y = b$y, stringsAsFactors = FALSE)
    if (!is.null(key)) out$series <- key[b$group]
    return(out)
  }
  out <- data.frame(row.names = seq_len(nrow(d)))
  pos <- intersect(app_dl_geom_pos(L), names(vals))
  for (a in pos)
    out[[a]] <- if (app_dl_discrete(vals[[a]])) as.character(vals[[a]]) else as.numeric(vals[[a]])
  if (!is.null(series)) out$series <- series
  if (!is.null(panel)) out$panel <- panel
  if (!is.null(vals$fill) && is.numeric(vals$fill)) out$value <- vals$fill
  # rows a geom drops as missing are not drawn, so they are not listed
  out[stats::complete.cases(out[pos]), , drop = FALSE]
}

#' How each listed layer is drawn, in the words the charts' own captions use ("faint", "dashed")
app_dl_layer_word <- function(L) {
  base <- APP_DL_GEOM_WORD[[class(L$geom)[1]]]
  a <- L$aes_params$alpha; lt <- L$aes_params$linetype
  if (base %in% c("line", "points") && is.numeric(a) && a < APP_DL_FAINT_ALPHA) base <- paste("faint", base)
  if (base == "line" && !is.null(lt) && !lt %in% c("solid", 1)) base <- "dashed line"
  base
}

#' Number two layers drawn the same way only when they share a legend entry, so no
#' two rows of the CSV can claim the same mark (the δ¹³C chart's two lines per hemisphere
#' are "faint line" and "line"; a clash left over is numbered)
app_dl_dedupe_words <- function(words, series) {
  for (w in unique(words)) {
    k <- which(words == w)
    if (length(k) < 2L) next
    s <- lapply(series[k], function(x) if (is.null(x)) "" else unique(x))
    clash <- any(vapply(seq_along(k), function(a) any(vapply(seq_along(k), function(b)
      a != b && length(intersect(s[[a]], s[[b]])) > 0L, logical(1))), logical(1)))
    if (clash) words[k] <- paste(w, seq_along(k))
  }
  words
}

#' The table behind a chart: one row per drawn mark, long format
#' @return a data.frame with columns layer, series, panel, x, y, ymin, ymax, value
#'   (whichever the chart has); `attr(, "stacked")` TRUE when an area layer stacks
app_dl_table <- function(p) {
  if (!inherits(p, "ggplot")) return(NULL)
  idx <- app_dl_data_layers(p)
  if (!length(idx)) return(NULL)
  built <- NULL
  if (any(vapply(idx, function(i) !inherits(p$layers[[i]]$stat, c("StatIdentity", "StatAlign")), logical(1))))
    built <- ggplot2::ggplot_build(p)
  rows <- lapply(idx, function(i) app_dl_layer_rows(p, i, built))
  words <- app_dl_dedupe_words(vapply(idx, function(i) app_dl_layer_word(p$layers[[i]]), character(1)),
                               lapply(rows, `[[`, "series"))
  parts <- Map(function(r, w) {
    if (!nrow(r)) return(NULL)
    cbind(data.frame(layer = rep(w, nrow(r)), stringsAsFactors = FALSE), r)
  }, rows, words)
  keep <- !vapply(parts, is.null, logical(1))
  parts <- parts[keep]
  if (!length(parts)) return(NULL)
  cols <- unique(unlist(lapply(parts, names)))
  parts <- lapply(parts, function(r) { for (c_ in setdiff(cols, names(r))) r[[c_]] <- NA; r[cols] })
  tab <- do.call(rbind, parts)
  order <- c("layer", "series", "panel", APP_DL_POS, "value")
  tab <- tab[intersect(order, names(tab))]
  # a label broken over two lines on the chart ("North\nminus south") is one line in the file
  for (c_ in names(tab)) if (is.character(tab[[c_]])) tab[[c_]] <- gsub("\n", " ", tab[[c_]], fixed = TRUE)
  rownames(tab) <- NULL
  attr(tab, "layers") <- idx[keep]
  attr(tab, "layer_words") <- words[keep]
  attr(tab, "layer_n") <- vapply(parts, nrow, integer(1))
  attr(tab, "stacked") <- any(vapply(idx, function(i)
    inherits(p$layers[[i]]$geom, "GeomArea") && inherits(p$layers[[i]]$position, "PositionStack"), logical(1)))
  attr(tab, "axis") <- list(x = app_dl_label_text(p$labels$x), y = app_dl_label_text(p$labels$y))
  tab
}

#' An axis title as text: a plotmath title (app_plotmath(), plots.R) turned back into its
#' Unicode string, so "Δ¹⁴C (‰)" reads as on the chart rather than as plotmath source
app_dl_label_text <- function(lab) {
  if (is.null(lab)) return(NULL)
  if (is.character(lab)) return(paste(lab, collapse = " "))
  if (is.expression(lab)) lab <- lab[[1]]
  sup <- stats::setNames(names(PLOTMATH_SUP), PLOTMATH_SUP)
  sub <- stats::setNames(names(PLOTMATH_SUB), PLOTMATH_SUB)
  conv <- function(x, map) paste(map[strsplit(x, "")[[1]]], collapse = "")
  walk <- function(e) {
    if (is.character(e)) return(e)
    if (is.call(e)) {
      f <- as.character(e[[1]])
      if (identical(f, "*")) return(paste0(walk(e[[2]]), walk(e[[3]])))
      if (identical(f, "^")) return(paste0(walk(e[[2]]), conv(walk(e[[3]]), sup)))
      if (identical(f, "[")) return(paste0(walk(e[[2]]), conv(walk(e[[3]]), sub)))
    }
    paste(deparse(e), collapse = "")
  }
  walk(lab)
}

#' The box diagram is a schematic: its data are the flows its arrows print. Two arrows
#' that print the same name (the warm and the cold ocean column's pair) are numbered left
#' to right by where their labels sit, so each row names one arrow.
app_dl_diagram_table <- function(p) {
  i <- which(vapply(p$layers, function(L) inherits(L$geom, "GeomText") && !app_dl_is_annotation(L) &&
                                            all(c("nm", "val") %in% names(L$data)), logical(1)))
  if (length(i) != 1L) return(NULL)
  d <- p$layers[[i]]$data
  nm <- gsub("\n", " ", d$nm, fixed = TRUE)
  lx <- if (all(c("x", "xend", "pos") %in% names(d))) d$x + d$pos * (d$xend - d$x) else seq_along(nm)
  for (n in unique(nm[duplicated(nm)])) {
    k <- which(nm == n)
    nm[k[order(lx[k])]] <- sprintf(APP_DL_DIAGRAM_DUP_FMT, n, seq_along(k))
  }
  tab <- data.frame(layer = APP_DL_DIAGRAM_LAYER, x = nm, y = d$val, stringsAsFactors = FALSE)
  attr(tab, "layers") <- i
  attr(tab, "layer_words") <- APP_DL_DIAGRAM_LAYER
  attr(tab, "layer_n") <- nrow(tab)
  tab
}

#' Rename x / y / ymin / ymax / value to the spec's column names
app_dl_named <- function(tab, sp) {
  nm <- names(tab)
  y_name <- sp$y[1]
  map <- c(x = sp$x[1], y = y_name, ymin = paste0(y_name, "_low"), ymax = paste0(y_name, "_high"),
           value = if (!is.null(sp$value)) sp$value[1] else "value")
  a <- attributes(tab)
  names(tab) <- ifelse(nm %in% names(map), map[nm], nm)
  for (k in c("axis", "stacked", "layers", "layer_words", "layer_n")) attr(tab, k) <- a[[k]]
  tab
}

#' The column glossary for a table, in its column order
app_dl_glossary <- function(tab, sp) {
  y_name <- sp$y[1]
  ax <- attr(tab, "axis")
  axis_def <- function(def, lab) if (!is.na(def)) def
    else if (is.null(lab) || !nzchar(lab)) APP_DL_AXIS_NONE else sprintf(APP_DL_AXIS_FMT, lab)
  defs <- c(layer = if (!is.null(sp$layer)) sp$layer else DLC_LAYER[2], series = DLC_SERIES[2], panel = DLC_PANEL[2])
  defs[[sp$x[1]]] <- axis_def(sp$x[2], ax$x); defs[[y_name]] <- axis_def(sp$y[2], ax$y)
  defs[[paste0(y_name, "_low")]]  <- sprintf(DLC_LOW, y_name)
  defs[[paste0(y_name, "_high")]] <- sprintf(DLC_HIGH, y_name)
  if (!is.null(sp$value)) defs[[sp$value[1]]] <- sp$value[2]
  defs[names(tab)]
}

#' The full CSV text: provenance header, then the table
#' @param link the deep link to the view the chart was drawn in, or NULL
app_dl_csv_lines <- function(tab, sp, link = NULL) {
  src <- vapply(sp$sources, function(k) DLS[[k]](), character(1))
  hdr <- c(sprintf(APP_DL_CSV_TITLE, APP_TITLE, sp$chart),
           sprintf("Release: %s", APP_RELEASE_NAME),
           sprintf("Model mode: %s (parameter file %s, md5 %s)", APP_DL_MODE,
                   basename(APP_DL_MODE_FILE), APP_DL_MODE_MD5),
           sprintf("Code commit: %s", app_dl_commit_label()),
           if (!is.null(link)) sprintf("Link to this view: %s", link),
           "Teaching software, not peer-reviewed.",
           "Sources:", paste0("  ", src))
  if (is.null(tab) || !nrow(tab))
    return(paste0(APP_DL_COMMENT, c(hdr, APP_DL_EMPTY)))
  gl <- app_dl_glossary(tab, sp)
  hdr <- c(hdr, "Columns:", sprintf("  %s: %s", names(gl), gl),
           if (!is.null(sp$rows)) sp$rows else APP_DL_ROW_NOTE, sp$note)
  con <- textConnection("body", "w", local = TRUE)
  on.exit(close(con))
  out <- tab
  for (c_ in names(out)) if (is.numeric(out[[c_]])) out[[c_]] <- signif(out[[c_]], APP_DL_CSV_DIGITS)
  utils::write.csv(out, con, row.names = FALSE, na = "")
  c(paste0(APP_DL_COMMENT, hdr), body)
}

app_dl_write_csv <- function(lines, file) {
  con <- file(file, open = "wb")
  on.exit(close(con))
  if (APP_DL_CSV_BOM) writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con)
  writeBin(charToRaw(enc2utf8(paste0(paste(lines, collapse = "\n"), "\n"))), con)
}

#' Build a chart's plot the way its renderPlotFit() does, with a device open (the
#' captions are wrapped by measuring text on it) and the panel width published.
#' @return the plot, or a condition when the chart has nothing to draw (req / validate)
app_dl_build <- function(fn, width_px, session = shiny::getDefaultReactiveDomain()) {
  app_set_panel_px(width_px)
  on.exit(app_clear_panel_px(), add = TRUE)
  tryCatch(shiny::withReactiveDomain(session, shiny::isolate(fn())),
           shiny.silent.error = function(e) e,
           error = function(e) e)
}

app_dl_device <- function(file, w, h) {
  if (requireNamespace("ragg", quietly = TRUE))
    ragg::agg_png(file, width = w * APP_DL_PNG_SCALE, height = h * APP_DL_PNG_SCALE,
                  res = APP_DL_SCREEN_RES * APP_DL_PNG_SCALE)
  else grDevices::png(file, width = w * APP_DL_PNG_SCALE, height = h * APP_DL_PNG_SCALE,
                      res = APP_DL_SCREEN_RES * APP_DL_PNG_SCALE)
}

#' The provenance line appended to a downloaded figure's caption
app_dl_png_foot <- function()
  sprintf(APP_DL_PNG_FOOT, APP_RELEASE_NAME, APP_DL_MODE, app_dl_commit_label())

app_dl_size <- function(session, id) {
  cd <- shiny::isolate(session$clientData)
  w <- cd[[paste0("output_", id, "_width")]]; h <- cd[[paste0("output_", id, "_height")]]
  w <- if (is.numeric(w) && length(w) == 1L && is.finite(w) && w > 0) w else app_dl_fallback_px()[["width"]]
  h <- if (is.numeric(h) && length(h) == 1L && is.finite(h) && h > 0) h else app_dl_fallback_px()[["height"]]
  c(width = w, height = h)
}

#' The chart's table, from its plot function (NULL when nothing is drawn)
app_dl_chart_table <- function(id, fn, width_px, session = shiny::getDefaultReactiveDomain()) {
  f <- tempfile(fileext = ".png")
  app_dl_device(f, width_px, app_dl_fallback_px()[["height"]])
  on.exit({ grDevices::dev.off(); unlink(f) }, add = TRUE)
  p <- app_dl_build(fn, width_px, session)
  if (inherits(p, "condition") || !inherits(p, "ggplot")) return(NULL)
  sp <- app_dl_spec(id)
  tab <- if (identical(id, "h_diagram")) app_dl_diagram_table(p) else app_dl_table(p)
  tab
}

#' The spec for a chart as it is drawn now: the Futures chart names its columns by its pill and y variable
app_dl_spec_for <- function(id, mode = NULL, yvar = NULL) {
  sp <- app_dl_spec(id)
  if (identical(id, "f_plot")) {
    tbl <- if (identical(mode, "Pulse lab")) APP_DL_PULSE_Y else APP_DL_FUTURE_Y
    if (!is.null(yvar) && !is.null(tbl[[yvar]])) sp$y <- tbl[[yvar]]
    if (identical(mode, "Pulse lab")) sp$x <- DLC$yearmid
  }
  sp
}

#' Register the CSV and PNG download handlers for every chart with a spec
#' @param plots environment of plot functions by output id (server.R's renderPlotFit fills it)
#' @param link function returning the current deep link, or NULL
#' @param futures function returning the Futures tab's pill and y variable (list(mode, yvar)), for its column names
app_dl_server <- function(output, session, plots, link = function() NULL,
                          futures = function() list(mode = NULL, yvar = NULL)) {
  spec_now <- function(id) {
    f <- shiny::isolate(futures())
    app_dl_spec_for(id, f$mode, f$yvar)
  }
  ids <- function() ls(plots)
  register <- function(id) {
    output[[paste0(id, "_csv")]] <- shiny::downloadHandler(
      filename = function() app_dl_filename(id, "csv"),
      content = function(file) {
        sz <- app_dl_size(session, id)
        fn <- get0(id, envir = plots, inherits = FALSE)
        tab <- if (is.null(fn)) NULL else app_dl_chart_table(id, fn, sz[["width"]], session)
        sp <- spec_now(id)
        app_dl_write_csv(app_dl_csv_lines(if (is.null(tab)) NULL else app_dl_named(tab, sp), sp,
                                          shiny::isolate(link())), file)
      },
      contentType = "text/csv")
    output[[paste0(id, "_png")]] <- shiny::downloadHandler(
      filename = function() app_dl_filename(id, "png"),
      content = function(file) {
        sz <- app_dl_size(session, id)
        fn <- get0(id, envir = plots, inherits = FALSE)
        app_dl_device(file, sz[["width"]], sz[["height"]])
        on.exit(grDevices::dev.off(), add = TRUE)
        p <- if (is.null(fn)) NULL else app_dl_build(fn, sz[["width"]], session)
        if (inherits(p, "ggplot")) {
          cap <- p$labels$caption
          p <- p + ggplot2::labs(caption = paste(c(if (!is.null(cap) && nzchar(cap)) cap, app_dl_png_foot()),
                                                 collapse = "\n"))
          print(p)
        } else {
          grid::grid.newpage()
          grid::grid.text(APP_DL_EMPTY, gp = grid::gpar(fontsize = CAPTION_PT + 2, col = "grey30"))
        }
      },
      contentType = "image/png")
  }
  for (id in ids()) if (!is.null(app_dl_spec(id))) register(id)
  invisible(NULL)
}

# ---- the UI ----------------------------------------------------------------------
APP_DL_CSS <- "
  .ccx-dl { font-size: 0.8rem; color: #666; text-align: right; margin: -4px 4px 8px 0; }
  .ccx-dl a { color: #1b6ca8; }
"
#' The two links under a chart
app_dl_links <- function(id) {
  tagList(
    singleton(tags$head(tags$style(HTML(APP_DL_CSS)), app_link_head())),
    div(class = "ccx-dl", APP_DL_LEAD, " ",
        downloadLink(paste0(id, "_csv"), APP_DL_LABEL_CSV), " · ",
        downloadLink(paste0(id, "_png"), APP_DL_LABEL_PNG)))
}

#' shiny::plotOutput() with the chart's download links under it (when it has a spec)
app_dl_plot_output <- function(outputId, ...) {
  out <- shiny::plotOutput(outputId, ...)
  if (is.null(app_dl_spec(outputId))) return(out)
  tagList(out, app_dl_links(outputId))
}
plotOutput <- app_dl_plot_output
