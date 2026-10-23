# =====================================================================
# test-app-downloads.R -- every chart's CSV download lists exactly what the chart
# draws (app/R/downloads.R, 2026-10-20).
#
# ⭐ THE ORACLE IS ggplot_build(), NOT THE EXTRACTOR. app_dl_table() reads each
# layer's aesthetic mapping off the plot object; the check below reads what
# ggplot hands the device -- positions after stat and position adjustments,
# colours after the scales -- and maps the CSV onto the same footing:
#   * a discrete axis by the panel scale's own limits;
#   * a stacked bar or area by its own signed height (ymax - ymin, negative
#     below zero), a horizontal bar on its x;
#   * every legend entry through the chart's own colour / fill / linetype scale,
#     against the colour the mark was drawn in;
#   * stat_align (geom_area) draws every band at every band's x: the vertices at
#     the CSV's x are compared, and every other vertex must be a zero-height pad
#     or lie on the straight line between them.
# The CSV is read back from the DOWNLOAD HANDLER's file (testServer), through its
# provenance header and byte-order mark, so the file a student gets is what is
# checked. Only the row-to-layer bookkeeping (which block of rows is which plot
# layer) comes from the extractor, and the oracle checks that every layer the
# device draws marks for is listed.
#
# ⚠ ONE COARSE COMPARISON. A continuous fill (the constraint map's tiles) is kept
# by ggplot_build() only as a colour, so tile values are checked at the device's
# 8-bit colour resolution; the mutation for that column is sized to it.
#
# MUTATION-TESTED: every column of every chart's CSV is altered in turn, a row is
# dropped and one duplicated, and two faults are put into the extractor itself;
# each must be reported.
# =====================================================================

.dl_app_dir <- file.path(.root, "app")
.dl_files <- file.path(.dl_app_dir, c("ui.R", "server.R", "R/downloads.R"))

skip_if_no_app <- function() {
  skip_if_not_installed("shiny"); skip_if_not_installed("ggplot2"); skip_if_not_installed("bslib")
  skip_if(!all(file.exists(.dl_files)), "app files absent")
  skip_if_no_cpp(); skip_if_no_climate()
}

# ---- the oracle -----------------------------------------------------------------
`%||%` <- function(a, b) if (is.null(a)) b else a
DLO_SKIP_GEOMS <- c("GeomText", "GeomLabel", "GeomHline", "GeomVline", "GeomAbline", "GeomBlank",
                    "GeomRect", "GeomSegment", "GeomCurve")
DLO_DRAWS <- list(GeomRibbon = c("x", "ymin", "ymax"), GeomErrorbar = c("x", "ymin", "ymax"))
dlo_draws <- function(L) DLO_DRAWS[[class(L$geom)[1]]] %||% c("x", "y")
DLO_TOL <- 1e-12   # relative; the CSV prints 15 significant digits

dlo_read_lines <- function(l) {
  l[1] <- sub("^﻿", "", l[1])
  body <- l[!startsWith(l, "# ")]
  list(header = l[startsWith(l, "# ")],
       table = if (length(body)) utils::read.csv(text = body, check.names = FALSE, stringsAsFactors = FALSE,
                                                 na.strings = "", encoding = "UTF-8"))
}
dlo_read_csv <- function(f) {
  x <- dlo_read_lines(readLines(f, encoding = "UTF-8", warn = FALSE))
  x$bom <- identical(readBin(f, "raw", 3L), as.raw(c(0xef, 0xbb, 0xbf)))
  x
}
dlo_data_layers <- function(p) which(vapply(p$layers, function(L) {
  k <- L$constructor
  !(class(L$geom)[1] %in% DLO_SKIP_GEOMS) && !(is.call(k) && identical(k[[1]], quote(annotate)))
}, logical(1)))
dlo_roles <- function(tab, sp) {
  y <- sp$y[1]
  map <- c(stats::setNames("x", sp$x[1]), stats::setNames("y", y), stats::setNames("ymin", paste0(y, "_low")),
           stats::setNames("ymax", paste0(y, "_high")))
  if (!is.null(sp$value)) map[[sp$value[1]]] <- "value"
  nm <- names(tab); names(tab) <- ifelse(nm %in% names(map), map[nm], nm)
  tab
}
dlo_same <- function(dv, cv, tol = DLO_TOL) {
  if (is.numeric(dv) && is.numeric(cv)) length(dv) == length(cv) && all(abs(dv - cv) <= tol * pmax(1, abs(dv)))
  else identical(unname(as.character(dv)), unname(as.character(cv)))
}

#' Every problem found; character(0) when the CSV lists exactly what the device was handed.
#' @param pairing list(layers, words, n): which plot layer each block of CSV rows is, in row order
dlo_check <- function(p, csv_tab, sp, pairing, tol = DLO_TOL) {
  b <- ggplot2::ggplot_build(p)
  tab <- dlo_roles(csv_tab, sp)
  lay <- b$layout$layout
  nl <- function(x) gsub("\n", " ", x, fixed = TRUE)
  fv <- names(c(p$facet$params$facets, p$facet$params$rows, p$facet$params$cols))
  probs <- character()
  drawn_any <- vapply(dlo_data_layers(p), function(i) {
    bd <- b$data[[i]]; dr <- intersect(dlo_draws(p$layers[[i]]), names(bd))
    any(stats::complete.cases(bd[dr]))
  }, logical(1))
  want <- dlo_data_layers(p)[drawn_any]
  if (!identical(as.integer(sort(pairing$layers)), as.integer(want)))
    probs <- c(probs, sprintf("layers drawn %s, layers in the CSV %s", paste(want, collapse = ","),
                              paste(pairing$layers, collapse = ",")))
  if (sum(pairing$n) != nrow(tab))
    return(c(probs, sprintf("%d CSV rows, %d claimed by layers", nrow(tab), sum(pairing$n))))
  start <- c(0L, cumsum(pairing$n))
  for (k in seq_along(pairing$layers)) {
    i <- pairing$layers[k]; L <- p$layers[[i]]
    r <- tab[(start[k] + 1L):start[k + 1L], , drop = FALSE]
    if (!all(r$layer == pairing$words[k]))
      probs <- c(probs, sprintf("layer %d: rows not labeled '%s'", i, pairing$words[k]))
    bd <- b$data[[i]]
    dr <- intersect(dlo_draws(L), names(bd))
    bd <- bd[stats::complete.cases(bd[dr]), , drop = FALSE]
    if (length(unique(lay$PANEL)) > 1L && !any(fv %in% names(L$layer_data(p$data))))
      bd <- bd[bd$PANEL == bd$PANEL[1], , drop = FALSE]   # drawn once per panel, listed once
    flipped <- isTRUE(bd$flipped_aes[1])
    stacked <- inherits(L$position, c("PositionStack", "PositionFill"))
    pos <- function(a) {
      ax <- if (a == "x") "x" else "y"
      v <- bd[[a]]
      sc_list <- if (ax == "x") b$layout$panel_scales_x else b$layout$panel_scales_y
      sidx <- lay[[if (ax == "x") "SCALE_X" else "SCALE_Y"]][match(bd$PANEL, lay$PANEL)]
      if (sc_list[[sidx[1]]]$is_discrete()) {
        out <- character(length(v))
        for (s in unique(sidx)) {
          kk <- sidx == s; out[kk] <- nl(sc_list[[s]]$get_limits()[round(as.numeric(v[kk]))])
        }
        out
      } else as.numeric(v)
    }
    own <- function(lo, hi) ifelse(hi <= 0 & lo < 0, lo - hi, hi - lo)
    D <- data.frame(row.names = seq_len(nrow(bd))); C <- data.frame(row.names = seq_len(nrow(r)))
    for (a in intersect(c("x", "y", "ymin", "ymax"), names(r))) {
      if (all(is.na(r[[a]]))) next
      D[[a]] <- if (stacked && a == (if (flipped) "x" else "y"))
        own(bd[[paste0(a, "min")]], bd[[paste0(a, "max")]]) else pos(a)
      C[[a]] <- r[[a]]
    }
    m <- if (isTRUE(L$inherit.aes)) utils::modifyList(as.list(p$mapping), as.list(L$mapping)) else as.list(L$mapping)
    ae <- intersect(c("colour", "fill", "linetype", "shape"), setdiff(names(m), names(L$aes_params)))
    ae <- ae[vapply(ae, function(a) { sc <- b$plot$scales$get_scales(a); !is.null(sc) && sc$is_discrete() },
                    logical(1))]
    if ("series" %in% names(r) && any(!is.na(r$series))) {
      if (length(ae)) {
        sc <- b$plot$scales$get_scales(ae[1])
        D$series <- as.character(bd[[ae[1]]]); C$series <- as.character(sc$map(r$series))
      } else probs <- c(probs, sprintf("layer %d: a series column but no discrete scale to check it on", i))
    } else if (length(ae)) probs <- c(probs, sprintf("layer %d: drawn by %s but no series listed", i, ae[1]))
    if ("value" %in% names(r) && any(!is.na(r$value))) {
      sc <- b$plot$scales$get_scales("fill")
      lim <- sc$get_limits(); v <- r$value
      edge <- tol * max(abs(lim))   # a value printed at 15 digits may land a hair outside the limits
      v[v < lim[1] & v >= lim[1] - edge] <- lim[1]; v[v > lim[2] & v <= lim[2] + edge] <- lim[2]
      D$value <- toupper(as.character(bd$fill)); C$value <- toupper(as.character(sc$map(v)))
    }
    if ("panel" %in% names(r) && any(!is.na(r$panel))) {
      D$panel <- nl(do.call(paste, c(lapply(fv, function(v) as.character(lay[[v]][match(bd$PANEL, lay$PANEL)])),
                                     sep = " / ")))
      C$panel <- r$panel
    }
    if (!setequal(names(D), names(C))) {
      probs <- c(probs, sprintf("layer %d: drawn %s, listed %s", i, paste(names(D), collapse = ","),
                                paste(names(C), collapse = ",")))
      next
    }
    C <- C[names(D)]
    if (inherits(L$stat, "StatAlign")) {
      key_d <- paste(D$series %||% "", D$panel %||% ""); key_c <- paste(C$series %||% "", C$panel %||% "")
      at <- logical(nrow(D))
      for (g in unique(key_d)) {
        kk <- which(key_d == g); xs <- C$x[key_c == g]
        at[kk] <- vapply(D$x[kk], function(x) any(abs(xs - x) <= tol * max(1, abs(x))), logical(1))
        ex <- kk[!at[kk]]
        if (length(ex) && sum(at[kk]) >= 2L) {
          ok <- abs(D$y[ex]) <= tol |
            abs(stats::approx(D$x[kk][at[kk]], D$y[kk][at[kk]], xout = D$x[ex], rule = 2)$y - D$y[ex]) <=
              1e-9 * pmax(1, abs(D$y[ex]))
          if (!all(ok)) probs <- c(probs, sprintf("layer %d: %d aligned vertices are not interpolations", i, sum(!ok)))
        }
      }
      D <- D[at, , drop = FALSE]
    }
    if (nrow(D) != nrow(C)) {
      probs <- c(probs, sprintf("layer %d: %d marks drawn, %d rows listed", i, nrow(D), nrow(C))); next
    }
    num <- vapply(D, is.numeric, logical(1))
    ord <- c(names(D)[!num], names(D)[num])
    D <- D[do.call(order, unname(as.list(D[ord]))), ord, drop = FALSE]
    C <- C[do.call(order, unname(as.list(C[ord]))), ord, drop = FALSE]
    for (a in ord) if (!dlo_same(D[[a]], C[[a]], tol))
      probs <- c(probs, sprintf("layer %d (%s): column %s differs", i, pairing$words[k], a))
  }
  probs
}

#' The box diagram: each drawn arrow label is "<number>\n<name>". Row k of the CSV must carry
#' arrow k's name (a name printed twice numbered left to right) and a value that rounds to
#' the printed number at the printed precision.
dlo_check_diagram <- function(p, csv_tab, sp) {
  b <- ggplot2::ggplot_build(p)
  i <- which(vapply(p$layers, function(L) inherits(L$geom, "GeomText") &&
                      !(is.call(L$constructor) && identical(L$constructor[[1]], quote(annotate))), logical(1)))
  bd <- do.call(rbind, lapply(i, function(j) b$data[[j]][, c("x", "label")]))
  bd <- bd[grepl("^[0-9.]+\n", bd$label), , drop = FALSE]
  num <- sub("\n.*$", "", bd$label); nm <- gsub("\n", " ", sub("^[0-9.]+\n", "", bd$label))
  for (n in unique(nm[duplicated(nm)])) { k <- which(nm == n); nm[k[order(bd$x[k])]] <- sprintf("%s (%d)", n, seq_along(k)) }
  tab <- dlo_roles(csv_tab, sp)
  if (length(nm) != nrow(tab)) return(sprintf("%d arrow labels drawn, %d rows listed", length(nm), nrow(tab)))
  dec <- ifelse(grepl(".", num, fixed = TRUE), nchar(sub("^[0-9]+\\.", "", num)), 0L)
  probs <- character()
  if (!all(tab$layer == "arrow label")) probs <- "rows not labeled 'arrow label'"
  for (k in seq_along(nm)) {
    if (!identical(tab$x[k], nm[k])) { probs <- c(probs, sprintf("row %d: '%s', drawn '%s'", k, tab$x[k], nm[k])); next }
    if (!isTRUE(abs(tab$y[k] - as.numeric(num[k])) <= 0.5 * 10^(-dec[k]) + 1e-12))
      probs <- c(probs, sprintf("arrow '%s': drawn %s, listed %s", nm[k], num[k], format(tab$y[k])))
  }
  probs
}

#' The CSV with one entry of one column altered (NULL when the column cannot be)
dlo_mutate <- function(tab, col, sp) {
  v <- tab[[col]]; k <- which(!is.na(v))[1]
  if (is.na(k)) return(NULL)
  if (is.numeric(v)) {
    is_fill <- !is.null(sp$value) && identical(col, sp$value[1])
    coarse <- is_fill || isTRUE(sp$coarse)   # values the device keeps only as a colour, or as a rounded label
    v[k] <- if (coarse) v[k] + 0.25 * diff(range(v, na.rm = TRUE)) + 1 else v[k] + 1e-9 * max(1, abs(v[k]))
  } else {
    alt <- setdiff(unique(v[!is.na(v)]), v[k])
    v[k] <- if (length(alt)) alt[1] else paste0(v[k], " (mutated)")
  }
  tab[[col]] <- v
  tab
}

# ---- 1-2. static: every chart has a spec, the review-card numbers are ui.R's -------------
.dl_calls <- function(file, fn) {
  out <- list()
  walk <- function(e) {
    if (is.call(e)) {
      if (is.name(e[[1]]) && identical(as.character(e[[1]]), fn)) out[[length(out) + 1L]] <<- e
      for (a in as.list(e)[-1]) if (!missing(a)) walk(a)
    }
  }
  for (e in parse(file, keep.source = FALSE)) walk(e)
  out
}

test_that("1. every plotOutput() id in ui.R and server.R has a download spec", {
  skip_if_no_app()
  ids <- unlist(lapply(file.path(.dl_app_dir, c("ui.R", "server.R")), function(f)
    unlist(lapply(.dl_calls(f, "plotOutput"), function(e) if (is.character(e[[2]])) e[[2]]))))
  rc <- .dl_calls(file.path(.dl_app_dir, "ui.R"), "review_card")
  ids <- c(ids, unlist(lapply(rc, function(e) Filter(is.character, as.list(e)[-1]))))
  ids <- setdiff(unique(ids), "330px")
  ids <- ids[!grepl("px$", ids)]
  expect_gt(length(ids), 25L)
  # the spec table's and the review map's NAMES, read off the parse tree (no app needed)
  src <- parse(file.path(.dl_app_dir, "R", "downloads.R"), keep.source = FALSE)
  rhs <- function(nm) src[[which(vapply(src, function(x) is.call(x) && identical(as.character(x[[1]]), "<-") &&
                                          identical(as.character(x[[2]]), nm), logical(1)))]][[3]]
  spec_names <- names(as.list(rhs("APP_DL_SPEC"))[-1])
  rv_names <- names(eval(rhs("APP_DL_RV_CARD")))
  expect_true("c_driver" %in% spec_names)   # the driver charts' ids are c_driver_<mechanism>
  missing_spec <- setdiff(ids, c(spec_names, rv_names))
  expect_identical(missing_spec, character(0))
  # ...and server.R names the driver charts by that prefix
  expect_true(any(grepl('paste0("c_driver_", n)', readLines(file.path(.dl_app_dir, "server.R")), fixed = TRUE)))
})

test_that("2. APP_DL_RV_CARD's card numbers are the ones ui.R's review_card() calls draw each chart on", {
  skip_if_no_app()
  src <- parse(file.path(.dl_app_dir, "R", "downloads.R"), keep.source = FALSE)
  rv <- eval(src[[which(vapply(src, function(x) is.call(x) && identical(as.character(x[[1]]), "<-") &&
                                 identical(as.character(x[[2]]), "APP_DL_RV_CARD"), logical(1)))]][[3]])
  rc <- .dl_calls(file.path(.dl_app_dir, "ui.R"), "review_card")
  ui_map <- unlist(lapply(rc, function(e) {
    ids <- Filter(function(a) is.character(a) && !grepl("px$", a), as.list(e)[-1])
    stats::setNames(rep(as.integer(e[[2]]), length(ids)), unlist(ids))
  }))
  expect_setequal(names(rv), names(ui_map))
  expect_identical(rv[names(ui_map)], ui_map)
})

# ---- 3. the app itself: every chart, several views ------------------------------------
test_that("3. every chart's downloaded CSV is exactly what the chart draws, and the check has power", {
  skip_if_no_app()
  app <- suppressMessages(shiny::shinyAppDir(.dl_app_dir))
  shiny::testServer(app, {
    AE <- environment(renderPlotFit)   # the server's frame; its parents hold global.R and app/R
    A <- function(nm) get(nm, envir = AE)
    seen <- character(); mutations <- 0L; caught <- 0L
    check_view <- function(label, ids = ls(dl_plots), mutate = FALSE) {
      for (id in ids) {
        sp <- A("app_dl_spec_for")(id, input$f_mode, input$f_yvar)
        expect_false(is.null(sp), info = id)
        if (identical(id, "h_diagram")) sp$coarse <- TRUE   # its numbers are printed rounded
        f <- output[[paste0(id, "_csv")]]
        x <- dlo_read_csv(f)
        expect_true(x$bom, info = id)
        p <- A("app_dl_build")(get(id, dl_plots), A("app_dl_fallback_px")()[["width"]], session)
        if (!inherits(p, "ggplot") || is.null(x$table)) next
        tb <- if (identical(id, "h_diagram")) A("app_dl_diagram_table")(p) else A("app_dl_table")(p)
        pr <- list(layers = attr(tb, "layers"), words = attr(tb, "layer_words"), n = attr(tb, "layer_n"))
        chk <- function(t) if (identical(id, "h_diagram")) dlo_check_diagram(p, t, sp) else dlo_check(p, t, sp, pr)
        expect_identical(chk(x$table), character(0), info = sprintf("%s [%s]", id, label))
        seen <<- union(seen, id)
        if (mutate) {
          for (col in names(x$table)) {
            mt <- dlo_mutate(x$table, col, sp)
            if (is.null(mt)) next
            mutations <<- mutations + 1L
            hit <- length(chk(mt)) > 0L
            caught <<- caught + hit
            expect_true(hit, info = sprintf("mutating column '%s' of %s went unnoticed", col, id))
          }
          if (nrow(x$table) > 1L) {
            for (mt in list(x$table[-nrow(x$table), , drop = FALSE], x$table[c(seq_len(nrow(x$table)), 1L), , drop = FALSE])) {
              mutations <<- mutations + 1L; hit <- length(chk(mt)) > 0L; caught <<- caught + hit
              expect_true(hit, info = sprintf("a dropped or duplicated row of %s went unnoticed", id))
            }
          }
        }
      }
    }
    mech_drv <- names(Filter(function(m) !is.null(m$driver), A("CCX_MECHANISMS")))
    # view 1: every tab at its defaults, every driver chart switched on, FaIR on Scenarios
    session$setInputs(tabs = "The Keeling Curve", k_years = c(1958, 2024), k_hemi = "both", k_obs = TRUE,
                      w_years = c(1850, 2024), c_mech = mech_drv, c_years = c(1850, 2024),
                      i_years = c(1940, 2024), i_hemi = "both", f_mode = "Scenarios",
                      f_scen = c("vvL", "vvM", "vvH"), f_yvar = "co2_ppm", f_fair = TRUE, cm_level = "component")
    check_view("defaults", mutate = TRUE)
    # view 2: the other settings
    session$setInputs(k_hemi = "NH", k_obs = FALSE, i_hemi = "SH", i_years = c(1955, 1990), w_years = c(1960, 2000),
                      c_mech = character(0), cm_level = "parameter", f_yvar = "gmst", f_scen = "vvH")
    check_view("alternates", c("k_plot", "i_d13c", "i_d14c", "w_partition", "w_af", "w_regrowth_plot",
                               "c_plot", "c_growth", "c_resid", "cm_map", "f_plot"))
    # view 3: the pulse lab (the app's default pulse), both y variables, FaIR on
    session$setInputs(tabs = "Futures", f_mode = "Pulse lab", f_yvar = "co2_ppm", f_fair = TRUE,
                      p_bg = "vvM", p_gtc = 100, p_year = 2050, p_go = 1)
    check_view("pulse", c("f_plot", "f_partition"), mutate = TRUE)
    session$setInputs(f_yvar = "gmst")
    check_view("pulse, temperature", "f_plot")
    # view 4: build your own
    session$setInputs(f_mode = "Build your own", f_yvar = "co2_ppm", s_kind = "to_zero", s_zero_year = 2070,
                      s_rate = 1, s_bg = "vvM", s_go = 1)
    check_view("build your own", "f_plot")
    # every chart was checked with something drawn
    expect_setequal(seen, ls(dl_plots))
    expect_gt(mutations, 150L)
    expect_identical(caught, mutations)

    # ---- the extractor's own faults are caught end to end (the download file, not the table) ----
    session$setInputs(tabs = "The Keeling Curve", k_hemi = "both", k_obs = TRUE)
    host <- environment(A("app_dl_layer_rows"))
    orig <- get("app_dl_layer_rows", envir = host)
    faults <- list(
      shift_y = function(p, i, built = NULL) { r <- orig(p, i, built); if ("y" %in% names(r)) r$y <- r$y * (1 + 1e-9); r },
      drop_last = function(p, i, built = NULL) { r <- orig(p, i, built); r[-nrow(r), , drop = FALSE] })
    for (nm in names(faults)) {
      assign("app_dl_layer_rows", faults[[nm]], envir = host)
      x <- tryCatch(dlo_read_csv(output$k_plot_csv), finally = assign("app_dl_layer_rows", orig, envir = host))
      p <- A("app_dl_build")(get("k_plot", dl_plots), A("app_dl_fallback_px")()[["width"]], session)
      tb <- A("app_dl_table")(p)
      pr <- list(layers = attr(tb, "layers"), words = attr(tb, "layer_words"), n = attr(tb, "layer_n"))
      expect_true(length(dlo_check(p, x$table, A("app_dl_spec_for")("k_plot"), pr)) > 0L,
                  info = sprintf("extractor fault '%s' passed the check", nm))
    }
    expect_identical(get("app_dl_layer_rows", envir = host), orig)
  })
})

# ---- 4. the provenance header, the file names, the PNG ---------------------------------
test_that("4. each CSV opens with its provenance; names derive from the constants; the PNG is the chart at 2x", {
  skip_if_no_app()
  app <- suppressMessages(shiny::shinyAppDir(.dl_app_dir))
  shiny::testServer(app, {
    AE <- environment(renderPlotFit); A <- function(nm) get(nm, envir = AE)
    # every input the charts read is set, so no chart is drawn from a NULL setting
    session$setInputs(tabs = "The Keeling Curve", k_years = c(1958, 2024), k_hemi = "both", k_obs = TRUE,
                      w_years = c(1850, 2024), c_mech = "fertilisation", c_years = c(1850, 2024),
                      i_years = c(1940, 2024), i_hemi = "both", cm_level = "component", f_mode = "Scenarios",
                      f_scen = c("vvL", "vvM"), f_yvar = "co2_ppm", f_fair = FALSE)
    mode_file <- A("ccx_mode_file")(A("CCX_MODE_CANONICAL"))
    for (id in c("k_plot", "w_gcb", "cm_map", "f_plot", "h_diagram", "rv_repdc")) {
      x <- dlo_read_csv(output[[paste0(id, "_csv")]])
      h <- sub("^# ", "", x$header)
      sp <- A("app_dl_spec_for")(id, input$f_mode, input$f_yvar)
      expect_true(sprintf(A("APP_DL_CSV_TITLE"), A("APP_TITLE"), sp$chart) %in% h, info = id)
      expect_true(sprintf("Release: %s", A("APP_RELEASE_NAME")) %in% h, info = id)
      expect_true(any(grepl(sprintf("^Model mode: %s \\(parameter file %s, md5 %s\\)$", A("CCX_MODE_CANONICAL"),
                                    basename(mode_file), unname(tools::md5sum(mode_file))), h)), info = id)
      expect_true(sprintf("Code commit: %s", A("app_dl_commit_label")(ccx_git_stamp())) %in% h, info = id)
      expect_false(any(grepl("Code commit: unknown", h, fixed = TRUE)), info = id)   # a checkout always has one
      expect_true(all(sprintf("  %s", vapply(sp$sources, function(k) A("DLS")[[k]](), "")) %in% h), info = id)
      # every column has a definition, and none reads NA
      for (col in names(x$table)) expect_true(any(startsWith(h, sprintf("  %s: ", col))), info = paste(id, col))
      expect_false(any(grepl(": NA$", h)), info = id)
    }
    # file names: <app>_<version>_<stem>.<ext>, all different
    fn <- vapply(ls(dl_plots), function(id) A("app_dl_filename")(id, "csv"), "")
    expect_false(anyDuplicated(fn) > 0)
    expect_true(all(fn == sprintf(A("APP_DL_FILE_FMT"), tolower(A("APP_TITLE")), A("APP_VERSION"),
                                  vapply(ls(dl_plots), function(id) A("app_dl_spec")(id)$stem, ""), "csv")))
    # the PNG: a PNG, at APP_DL_PNG_SCALE times the panel's size
    f <- output$k_plot_png
    sig <- readBin(f, "raw", 24L)
    expect_identical(sig[1:8], as.raw(c(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a)))
    be <- function(r) sum(as.integer(r) * 256^(3:0))
    sz <- A("app_dl_size")(session, "k_plot")   # the panel's reported size (testServer reports 600 x 400)
    expect_equal(be(sig[17:20]), sz[["width"]] * A("APP_DL_PNG_SCALE"))
    expect_equal(be(sig[21:24]), sz[["height"]] * A("APP_DL_PNG_SCALE"))
    # nothing drawn yet (the pulse lab before its button): the files say so instead of failing
    session$setInputs(tabs = "Futures", f_mode = "Pulse lab")
    x <- dlo_read_csv(output$f_partition_csv)
    expect_null(x$table)
    expect_true(sprintf("# %s", A("APP_DL_EMPTY")) %in% x$header)
    expect_identical(readBin(output$f_partition_png, "raw", 4L), as.raw(c(0x89, 0x50, 0x4e, 0x47)))
  })
})

# Marcus 2026-10-23 ("Scripps draft (Recommended)"; CHANGELOG 10-23 s): the CO2 and d13C credits name the Scripps CO2
# Program, whose records the app scores and plots (data-raw/build_calibration_data.R); the NOAA GML / INSTAAR credits
# they replace named the cross-check records. The Mauna Loa CO2 credit says "flask", so it must agree with the
# series the app plots: APP_CO2_FLASK (global.R) is the switch.
test_that("5. the observation credits name the Scripps CO2 Program, and Mauna Loa's CO2 credit matches the plotted series", {
  skip_if_no_app()
  app <- suppressMessages(shiny::shinyAppDir(.dl_app_dir))
  shiny::testServer(app, {
    AE <- environment(renderPlotFit); A <- function(nm) get(nm, envir = AE)
    co2 <- A("DLS")$co2_obs(); d13 <- A("DLS")$d13c_obs()
    for (s in c(co2, d13)) {
      expect_true(grepl("Scripps CO₂ Program", s, fixed = TRUE), info = s)
      expect_false(grepl("NOAA|INSTAAR", s), info = s)
    }
    expect_identical(grepl("Mauna Loa monthly flask means", co2, fixed = TRUE), isTRUE(A("APP_CO2_FLASK")))
    # MUTATION: a credit that names the other series fails the same comparison
    co2_mut <- if (isTRUE(A("APP_CO2_FLASK"))) sub("monthly flask means", "monthly means", co2, fixed = TRUE) else
      sub("Mauna Loa monthly means", "Mauna Loa monthly flask means", co2, fixed = TRUE)
    expect_false(identical(co2_mut, co2))
    expect_false(identical(grepl("Mauna Loa monthly flask means", co2_mut, fixed = TRUE), isTRUE(A("APP_CO2_FLASK"))))
  })
})
