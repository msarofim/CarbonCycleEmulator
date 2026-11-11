# =====================================================================
# helper-diagram-pixels.R -- does the box diagram's text clear its arrows and boxes, and does every arrowhead show?
# Measured on PIXELS drawn by ragg, the device the app draws with (2026-11-11; CHANGELOG 2026-11-11 n).
#
# WHY PIXELS. The boxes are geom_label()s sized by the font, and the arrows are fixed data coordinates, so a wider font
# grows the boxes over the arrow ends. The host draws in DejaVu Sans (Ubuntu's default sans; its render matched the
# live image to 102 of 152,550 pixels, max difference 2/255), about 22 % wider in bold than this machine's Helvetica,
# and the litterfall arrowhead disappeared under the Soil box there only. Each element is drawn ALONE into an
# in-memory ragg device and the checks run on the ink masks, so text metrics are the rasteriser's, not a model's.
#
# THE FONT. ggplot draws text in the default family "", which ragg resolves to the system default and not through
# systemfonts' registry, so dgp_use_font() points the text and label geoms at "sans" and registers DejaVu Sans as
# "sans" for this process ("system" clears the registry: "sans" is then Helvetica on macOS, as "" is).
# =====================================================================

DGP_DEJAVU_CANDIDATES <- c(
  Sys.getenv("CCX_DEJAVU_DIR"),
  "/usr/share/fonts/truetype/dejavu",
  Sys.glob("/Users/*/miniforge3/pkgs/matplotlib-base-*/lib/python3*/site-packages/matplotlib/mpl-data/fonts/ttf"))
dgp_dejavu_dir <- function() {
  for (d in DGP_DEJAVU_CANDIDATES)
    if (nzchar(d) && all(file.exists(file.path(d, c("DejaVuSans.ttf", "DejaVuSans-Bold.ttf"))))) return(d)
  NULL
}

#' Draw text in `font`: "system" (the platform's default sans) or "dejavu" (the host's)
dgp_use_font <- function(font = c("system", "dejavu")) {
  font <- match.arg(font)
  systemfonts::clear_registry()
  if (font == "dejavu") {
    d <- dgp_dejavu_dir(); if (is.null(d)) stop("DejaVu Sans not found; set CCX_DEJAVU_DIR")
    systemfonts::register_font("sans", plain = file.path(d, "DejaVuSans.ttf"), bold = file.path(d, "DejaVuSans-Bold.ttf"),
                               italic = file.path(d, "DejaVuSans-Oblique.ttf"),
                               bolditalic = file.path(d, "DejaVuSans-BoldOblique.ttf"))
  }
  ggplot2::update_geom_defaults("text", list(family = "sans"))
  ggplot2::update_geom_defaults("label", list(family = "sans"))
  invisible(systemfonts::match_fonts("sans", weight = "bold")$path)
}
dgp_reset_font <- function() {
  systemfonts::clear_registry()
  ggplot2::update_geom_defaults("text", NULL); ggplot2::update_geom_defaults("label", NULL)
}

#' Non-white pixels of a plot drawn at W x H px (72 dpi, as Shiny draws at pixel ratio 1): logical H x W matrix
dgp_ink <- function(p, W, H) {
  cap <- ragg::agg_capture(width = W, height = H, res = 72, background = "white")
  dev <- grDevices::dev.cur(); on.exit(grDevices::dev.off(dev), add = TRUE)
  print(p)
  r <- cap(native = TRUE)
  m <- matrix(unclass(r) != -1L, nrow = H, ncol = W, byrow = TRUE)   # -1L is opaque white in a nativeRaster
  m
}

#' The plot with only some layers, and only some rows of one of them; `arrow = FALSE` drops a segment's head;
#' `colour` redraws text in another colour (the box names are white, which leaves no ink outside a box)
dgp_only <- function(p, k, rows = NULL, arrow = TRUE, colour = NULL) {
  l <- ggplot2::ggproto(NULL, p$layers[[k]])
  if (!is.null(rows)) l$data <- p$layers[[k]]$data[rows, , drop = FALSE]
  if (!arrow) { gp <- l$geom_params; gp$arrow <- NULL; l$geom_params <- gp }
  if (!is.null(colour)) { ap <- l$aes_params; ap$colour <- colour; l$aes_params <- ap }
  q <- p; q$layers <- list(l); q
}
dgp_dilate <- function(m, r) {
  if (r <= 0) return(m)
  H <- nrow(m); W <- ncol(m); out <- m
  for (dy in -r:r) for (dx in -r:r) {
    if (dx * dx + dy * dy > r * r) next
    ys <- max(1, 1 + dy):min(H, H + dy); xs <- max(1, 1 + dx):min(W, W + dx)
    out[ys, xs] <- out[ys, xs] | m[ys - dy, xs - dx]
  }
  out
}

#' Every element's ink, by kind and name. Layers are found by geom and by their data, not by position: the boxes are
#' annotation_custom() layers in the order of the box-name text layer (the GeomText whose data has `hw`), the flow
#' labels the GeomText whose data has `nm` and `val`, the footnotes the remaining (annotate()d) text.
dgp_elements <- function(p, W, H) {
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], "")
  has <- function(k, cols) is.data.frame(p$layers[[k]]$data) && all(cols %in% names(p$layers[[k]]$data))
  k_seg <- which(geoms == "GeomSegment"); k_box <- which(geoms == "GeomCustomAnn")
  k_txt <- which(geoms == "GeomText")
  k_name <- Filter(function(k) has(k, c("hw", "lab")), k_txt); k_flow <- Filter(function(k) has(k, c("nm", "val")), k_txt)
  k_note <- setdiff(k_txt, c(k_name, k_flow))
  stopifnot(length(k_seg) == 1L, length(k_name) == 1L, length(k_flow) == 1L, length(k_box) == nrow(p$layers[[k_name]]$data))
  arrows <- p$layers[[k_seg]]$data; names_d <- p$layers[[k_name]]$data
  tag <- function(d, i) sprintf("%s (%s)", sub("\n", " ", d$nm[i]), format(d$val[i], digits = 3))
  out <- list(arrow = list(), head = list(), text = list(), box = list(), name = list(), note = list())
  for (i in seq_len(nrow(arrows))) {
    a <- dgp_ink(dgp_only(p, k_seg, i), W, H); s <- dgp_ink(dgp_only(p, k_seg, i, arrow = FALSE), W, H)
    out$arrow[[tag(arrows, i)]] <- a; out$head[[tag(arrows, i)]] <- a & !s
  }
  fl <- p$layers[[k_flow]]$data
  for (i in seq_len(nrow(fl))) out$text[[tag(fl, i)]] <- dgp_ink(dgp_only(p, k_flow, i), W, H)
  for (i in seq_len(nrow(names_d))) {
    nm <- sub("\n.*", "", names_d$lab[i])
    out$box[[nm]] <- dgp_ink(dgp_only(p, k_box[i]), W, H)
    out$name[[nm]] <- dgp_ink(dgp_only(p, k_name, i, colour = "black"), W, H)   # its glyphs, wherever they fall
  }
  for (k in k_note) out$note[[sprintf("note %d", k)]] <- dgp_ink(dgp_only(p, k), W, H)
  out
}

#' Collisions in one drawing. `clear` is the clearance in px text must keep from arrows, boxes and other text; an
#' arrowhead must be at least `head_min` visible outside every box; `free` names arrows that must keep `clear` from
#' every box except within `end_px` of their head (land-use change rises from BETWEEN the land boxes); every arrow's
#' shaft must show at least `shaft_min` px outside the boxes.
#' Returns a data frame of failures (empty = clean), with the overlap in px.
dgp_check <- function(el, clear = 2, head_min = 0.95, free = character(), end_px = 6, notes_edge = TRUE, shaft_min = 12) {
  H <- nrow(el$box[[1]]); W <- ncol(el$box[[1]])
  any_of <- function(lst) Reduce(`|`, lst, matrix(FALSE, H, W))
  boxes <- any_of(el$box); arrows <- any_of(el$arrow)
  bad <- data.frame(check = character(), a = character(), b = character(), px = numeric())
  add <- function(check, a, b, px) bad[nrow(bad) + 1L, ] <<- list(check, a, b, px)
  texts <- c(el$text, el$note)
  # a label drawn wholly outside the image leaves no ink, and no edge check can see it
  for (a in c(names(texts), names(el$name))) if (!any(c(texts, el$name)[[a]])) add("text not drawn", a, "", 0)
  dil <- lapply(texts, dgp_dilate, r = clear)
  for (a in names(texts)) {
    n <- sum(dil[[a]] & arrows); if (n) add("text on an arrow", a, "arrows", n)
    for (b in names(el$box)) { n <- sum(dil[[a]] & el$box[[b]]); if (n) add("text on a box", a, b, n) }
    for (b in names(texts)) if (a < b) { n <- sum(dil[[a]] & texts[[b]]); if (n) add("text on text", a, b, n) }
    is_note <- a %in% names(el$note)
    if (!is_note || notes_edge) {
      e <- texts[[a]]; n <- sum(e[c(1, H), ]) + sum(e[, c(1, W)]); if (n) add("text at the image edge", a, "edge", n)
    }
  }
  for (b in names(el$name)) {
    n <- sum(dgp_dilate(el$name[[b]], clear) & !el$box[[b]]); if (n) add("name outside its box", b, b, n)
  }
  bn <- names(el$box)
  for (i in seq_along(bn)) for (j in seq_along(bn)) if (i < j) {
    n <- sum(dgp_dilate(el$box[[i]], clear) & el$box[[j]]); if (n) add("box on a box", bn[i], bn[j], n)
  }
  for (a in names(el$head)) {
    h <- el$head[[a]]; n <- sum(h)
    if (n == 0) { add("arrowhead not drawn", a, "", 0); next }
    vis <- sum(h & !boxes) / n
    if (vis < head_min) add("arrowhead under a box", a, sprintf("%.0f %% visible", 100 * vis), n - sum(h & !boxes))
  }
  # every arrow keeps a visible shaft at least shaft_min px long (the litterfall arrow shrank to ~6 px on DejaVu)
  for (a in names(el$arrow)) {
    v <- which(el$arrow[[a]] & !el$head[[a]] & !boxes, arr.ind = TRUE)
    len <- if (nrow(v)) sqrt(diff(range(v[, 1]))^2 + diff(range(v[, 2]))^2) else 0
    if (len < shaft_min) add("arrow shaft too short", a, sprintf("%.0f px visible", len), len)
  }
  for (a in free) {
    m <- el$arrow[[a]]; if (is.null(m)) { add("free arrow missing", a, "", 0); next }
    hd <- which(el$head[[a]], arr.ind = TRUE)
    near_head <- matrix(FALSE, H, W); near_head[hd] <- TRUE; near_head <- dgp_dilate(near_head, end_px)
    n <- sum(dgp_dilate(m & !near_head, clear) & boxes); if (n) add("arrow grazes a box", a, "boxes", n)
  }
  bad
}
