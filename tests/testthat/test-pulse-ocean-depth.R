# =====================================================================
# THE OCEAN BY DEPTH in the pulse lab's partition panels (app/R/ocean_depth.R) -- 2026-10-16.
#
# Marcus 2026-10-16: split "ocean" into upper / intermediate / deep, in BOTH panels; HD split by
# depth; blues, light at top; built by annual restarts. Display only.
#
# WHAT IS ASSERTED, and where each threshold comes from:
#   * the weights PARTITION the ocean -- identity at float tolerance; a box left out is refused
#     by name (MUTATION: drop one box);
#   * the three groups sum to the panel's ocean total at EVERY instant, for EACH panel: against
#     the same states' ocean sum at SUMMATION roundoff (n boxes x eps x inventory), and against the
#     CURRENT ocean band (the unsplit run's `$out`) at the chain's roundoff bound. MUTATION: drop a
#     box (validator bypassed) and both fail;
#   * the restarted run reproduces the unsplit one, under a bound from the integrator's own
#     roundoff accumulation (months x substeps x eps). MUTATIONS, each measured 2026-10-16 to
#     clear the bound by > 1e7: an off-by-one instant mapping (1.5e-3) and a stale T_deep
#     (4.5e-4); and a forcing table from another run is REFUSED by app_pulse_depth_runs().
#     ⚠ A missing ENSO history or T_deep is refused by the MODEL itself (ccx_land_enso(),
#     ccx_mix_g_series()), and a HELD ENSO history is a true null here (the future ENSO index
#     decays to ~1e-18), so neither is a mutation of this guard;
#   * the plotted shares close to 100 % after the release: the tagged panel within the decay
#     undo's own second-order term (lambda^2 Delta^2 / 8, R/c14_tag.R) plus roundoff, the extra
#     panel within the chain bound -- laws, not tolerances chosen to pass;
#   * THE LESSON is an ORDERING between two measured panels (the tagged atoms reach the deep ocean
#     faster than the extra carbon does), never a typed share;
#   * the legend keys derive from the grid (MUTATION: move a boundary and the key moves);
#   * the five fills, as drawn, clear tools/palette_check.py's target (MUTATION: ColorBrewer's
#     Blues triple, the obvious pick, fails).
# =====================================================================
skip_if_no_cpp()
skip_if_no_climate()
source(ccx_path("calibration", "lib_design_gates.R"))
suppressMessages(library(ggplot2))

OD_SCEN  <- "vvM"                       # the pulse lab's default background
OD_YEARS <- c(1750, 2150)               # short of 2300 to keep the file fast; nothing here depends on it
OD_PULSE <- c(year = 2050, gtc = 100)
OD_LATER <- c(20, 50, 100)              # yr after the release at which the ordering is read
OD_DELTA <- 1                           # yr: the release is spread over ONE calendar year
OD_EPS   <- .Machine$double.eps

.od <- new.env(parent = environment())
local({
  assign("app_params", list(source = "test", status = "test"), envir = .od)
  sys.source(file.path(.root, "app", "R", "plots.R"), envir = .od)
  sys.source(file.path(.root, "app", "R", "ocean_depth.R"), envir = .od)
})
odf <- function(nm) get(nm, envir = .od)

.v    <- dg_vector(CCX_MODE_CANONICAL)
.spin <- dg_spinup(.v)
.em <- ccx_scenario_emissions(OD_SCEN)
.yy <- seq(OD_YEARS[1], OD_YEARS[2])
.base_em <- data.frame(year = .yy,
                       fossil_GtC = stats::approx(.em$year, .em$fossil_GtC, xout = .yy, rule = 2)$y,
                       luc_GtC    = stats::approx(.em$year, .em$luc_GtC,    xout = .yy, rule = 2)$y)
.pulse_em <- .base_em
.pulse_em$fossil_GtC[.pulse_em$year == OD_PULSE[["year"]]] <-
  .pulse_em$fossil_GtC[.pulse_em$year == OD_PULSE[["year"]]] + OD_PULSE[["gtc"]]
.run <- function(em, tag_base = NULL)
  ccx_run_coupled(.spin, OD_SCEN, OD_YEARS, emissions = em,
                  bomb_total_kmol = .v$bomb_total, luc_scale = .v$luc_scale,
                  interp_method = "constant", c14_tag_base = tag_base, keep_forcing = TRUE)
.runs <- list(base = .run(.base_em), pulse = .run(.pulse_em), tagged = .run(.pulse_em, .base_em))
.W  <- odf("app_ocean_depth_weights")(.spin)
.ti <- odf("app_ocean_depth_instants")(.runs$pulse$forcing, OD_PULSE[["year"]])
.chains <- lapply(.runs, function(r) odf("app_run_states_at")(.spin, r$forcing, .ti))
.series <- function(W) lapply(.chains, function(ch) odf("app_reservoir_series")(ch, .spin, W))
.S <- .series(.W)
# the cores' own ocean index set (R/forcing.R ccx_run()); `[[` on a list gives NULL for an absent box
.ocean_idx <- unlist(lapply(HEMIS, function(h) { ix <- .spin$aux$idx[[h]]
  c(ix[["ml"]], ix[["oc"]], ix[["hs"]], ix[["hd"]], ix[["eq"]], ix[["tr"]]) }))
.inv_C   <- sum(.spin$y[.ocean_idx, "C"])
.inv_C14 <- sum(.spin$y[.ocean_idx, "C14"])
.nsteps  <- .chains$pulse$nsteps

# ---- the weights ----------------------------------------------------
test_that("the weights partition the ocean: every ocean box sums to 1, nothing else carries any", {
  rs <- rowSums(.W)
  expect_equal(unname(rs[.ocean_idx]), rep(1, length(.ocean_idx)), tolerance = 64 * OD_EPS)
  expect_true(all(rs[-.ocean_idx] == 0))
  expect_true(all(.W >= 0))
  for (h in HEMIS) {
    up  <- paste0(h, "_", c("ml", "hs", paste0("oc", 1:3)))
    mid <- paste0(h, "_oc", 4:6)
    dp  <- paste0(h, "_oc", 7:10)
    expect_true(all(.W[up, "upper"] == 1), info = h)
    expect_true(all(.W[mid, "intermediate"] == 1), info = h)
    expect_true(all(.W[dp, "deep"] == 1), info = h)
  }
})

test_that("HD is split by depth: each group gets the share of HD's thickness inside it", {
  bot <- cumsum(.spin$grid$dz); top_hd <- .spin$aux$h_hs; fl <- sum(.spin$grid$dz)
  z_u <- bot[1L + odf("OCEAN_DEPTH_LAST_LAYER")[["upper"]]]
  z_i <- bot[1L + odf("OCEAN_DEPTH_LAST_LAYER")[["intermediate"]]]
  # thickness in meters, read back off the weights, against the layer bottoms
  th <- .W["NH_hd", ] * .spin$aux$dz_hd
  expect_equal(unname(th[["upper"]]), max(0, z_u - top_hd), tolerance = 1e-12)
  expect_equal(unname(th[["intermediate"]]), z_i - max(z_u, top_hd), tolerance = 1e-12)
  expect_equal(unname(th[["deep"]]), fl - z_i, tolerance = 1e-12)
  expect_identical(.W["NH_hd", ], .W["SH_hd", ])
  # the HS box must sit wholly in the upper group for "upper" to hold it whole
  expect_lte(.spin$aux$h_hs, z_u)
})

test_that("MUTATION: a box left out of the groups is refused by name", {
  expect_error(odf("app_ocean_depth_weights")(.spin, drop = "oc5"), "NH_oc5")
  expect_error(odf("app_ocean_depth_weights")(.spin, drop = "hd"), "NH_hd")
})

test_that("a seasonal HS/HD boundary (seas_ml = 2) is refused, not approximated", {
  sp <- .spin; sp$params$seas_ml <- 2; sp$params$seas_drivers <- 1
  expect_error(odf("app_ocean_depth_weights")(sp), "seas_ml = 2")
})

# ---- the three groups sum to the ocean total, at every instant, for each panel -----------
# Each panel's ocean in fraction-of-pulse units, from a reservoir series `s` (list base/pulse/tagged).
.undo <- function(t) exp(ccx_const("LAMBDA_C14") * (t - .runs$tagged$tag$s_mid))
.panel_ocean <- function(s, groups) {
  extra <-rowSums(sapply(groups, function(cc) s$pulse[[paste0(cc, "_C")]] - s$base[[paste0(cc, "_C")]])) /
    OD_PULSE[["gtc"]]
  tagd <- rowSums(sapply(groups, function(cc) s$tagged[[paste0(cc, "_C14")]] - s$pulse[[paste0(cc, "_C14")]])) *
    .undo(s$tagged$t) / .runs$tagged$tag$gtc
  list(extra = extra, tagged = tagd)
}
# (1) the SAME states' ocean sum; (2) the CURRENT ocean band, from the unsplit runs' `$out`
.same_state <- function(s) list(
  extra  = (s$pulse$ocean_C - s$base$ocean_C) / OD_PULSE[["gtc"]],
  tagged = (s$tagged$ocean_C14 - s$pulse$ocean_C14) * .undo(s$tagged$t) / .runs$tagged$tag$gtc)
.rows <- .S$pulse$row
.current <- list(
  extra  = (.runs$pulse$out$ocean_C - .runs$base$out$ocean_C)[.rows] / OD_PULSE[["gtc"]],
  tagged = ccx_tag_partition(.runs$tagged$out, .runs$pulse$out, .runs$tagged$tag)$ocean[.rows])
# ⭐ THE BOUNDS ARE LAWS. Summing n boxes of inventory I costs at most n eps I per sum, two sums per
# panel (a difference of runs), in units of the pulse; the chain adds its own roundoff accumulation,
# nsteps eps relative to each inventory, on each of the two runs.
OD_TOL_SUM   <- c(extra  = 2 * length(.ocean_idx) * OD_EPS * .inv_C   / OD_PULSE[["gtc"]],
                  tagged = 2 * length(.ocean_idx) * OD_EPS * .inv_C14 / OD_PULSE[["gtc"]] * max(.undo(.ti)))
OD_TOL_CHAIN <- OD_TOL_SUM + c(extra  = 2 * .nsteps * OD_EPS * .inv_C   / OD_PULSE[["gtc"]],
                               tagged = 2 * .nsteps * OD_EPS * .inv_C14 / OD_PULSE[["gtc"]] * max(.undo(.ti)))

test_that("the three groups sum to each panel's ocean total at EVERY instant", {
  grp <- .panel_ocean(.S, odf("OCEAN_DEPTH_GROUPS"))
  ss  <- .same_state(.S)
  for (pn in c("extra", "tagged")) {
    expect_length(grp[[pn]], length(.ti))
    expect_lte(max(abs(grp[[pn]] - ss[[pn]])), OD_TOL_SUM[[pn]])
    # ... and to the ocean band the panel drew before the split (the unsplit run)
    expect_lte(max(abs(grp[[pn]] - .current[[pn]])), OD_TOL_CHAIN[[pn]])
  }
})

test_that("MUTATION: drop one box from a group and the sum test fails, at both comparisons", {
  Wm <- odf("app_ocean_depth_weights")(.spin, drop = "oc5", validate = FALSE)
  Sm <- .series(Wm)
  grp <- .panel_ocean(Sm, odf("OCEAN_DEPTH_GROUPS"))
  ss  <- .same_state(Sm)
  for (pn in c("extra", "tagged")) {
    expect_gt(max(abs(grp[[pn]] - ss[[pn]])), OD_TOL_SUM[[pn]])
    expect_gt(max(abs(grp[[pn]] - .current[[pn]])), OD_TOL_CHAIN[[pn]])
  }
})

# ---- the restarted run reproduces the unsplit run -----------------------------------------
test_that("the restarted runs reproduce the unsplit runs under the roundoff bound", {
  for (n in names(.runs)) {
    mm <- odf("app_chain_mismatch")(.S[[n]], .runs[[n]]$out, .chains[[n]]$nsteps)
    expect_lte(mm$max, mm$bound, label = n)
  }
})

test_that("MUTATION: an off-by-one instant and a stale T_deep both exceed the bound", {
  s1 <- .S$pulse; s1$row <- s1$row - 1L
  mm1 <- odf("app_chain_mismatch")(s1, .runs$pulse$out, .nsteps)
  expect_gt(mm1$max, mm1$bound)
  # a continuation that stops carrying T_deep after the first segment (ccx_mix_g_series() would
  # REFUSE a missing one, so the quiet failure is a stale one)
  skip_if_not(ccx_mix_on(.spin$params), "the stratification feedback is off: T_deep is not carried")
  src <- readLines(file.path(.root, "app", "R", "ocean_depth.R"), warn = FALSE)
  k <- grep("if (mix) tdeep <- ccx_mix_tdeep_after", src, fixed = TRUE)
  expect_length(k, 1L)
  src[k] <- sub("if (mix)", "if (mix && j == 1L)", src[k], fixed = TRUE)
  em <- new.env(parent = .od); eval(parse(text = src), envir = em)
  chm <- get("app_run_states_at", envir = em)(.spin, .runs$pulse$forcing, .ti)
  sm <- odf("app_reservoir_series")(chm, .spin, .W)
  mm2 <- odf("app_chain_mismatch")(sm, .runs$pulse$out, chm$nsteps)
  expect_gt(mm2$max, mm2$bound)
})

test_that("app_pulse_depth_runs() refuses a run restarted on another run's forcing", {
  dr <- odf("app_pulse_depth_runs")(.spin, .runs, OD_PULSE[["year"]])
  expect_named(dr, c("base", "pulse", "tagged", "tag", "keys"))
  bad <- .runs; bad$pulse$forcing <- bad$base$forcing
  expect_error(odf("app_pulse_depth_runs")(.spin, bad, OD_PULSE[["year"]]), "restarted run differs")
  nof <- .runs; nof$tagged$forcing <- NULL
  expect_error(odf("app_pulse_depth_runs")(.spin, nof, OD_PULSE[["year"]]), "keep_forcing")
})

test_that("keep_forcing returns the table the run integrated, and is opt-in", {
  # re-running the core on the kept table reproduces the run bit for bit
  r2 <- ccx_run_fast(.spin, .runs$pulse$forcing)
  expect_identical(r2$out, .runs$pulse$out)
  # without it, no `$forcing`, and every number is the same run's: keep_forcing moves nothing
  r0 <- ccx_run_coupled(.spin, OD_SCEN, OD_YEARS, emissions = .base_em, bomb_total_kmol = .v$bomb_total,
                        luc_scale = .v$luc_scale, interp_method = "constant")
  expect_null(r0$forcing)
  expect_identical(r0$out, .runs$base$out)
  expect_identical(r0$climate, .runs$base$climate)
})

# ---- the plotted table --------------------------------------------------------------------
.dr  <- odf("app_pulse_depth_runs")(.spin, .runs, OD_PULSE[["year"]])
.tab <- odf("app_pulse_partition_table")(.dr, OD_PULSE[["gtc"]])

test_that("the plotted shares close to 100 % after the release, within the laws", {
  kc <- .tab$t >= OD_PULSE[["year"]] + 1
  cl <- tapply(.tab$frac[kc], list(.tab$panel[kc], .tab$t[kc]), sum)
  law_tag <- ccx_const("LAMBDA_C14")^2 * OD_DELTA^2 / 8
  expect_lte(max(abs(cl[odf("PANEL_PULSE_EXTRA"), ] - 1)), OD_TOL_CHAIN[["extra"]] +
               2 * .nsteps * OD_EPS * sum(.spin$y[, "C"]) / OD_PULSE[["gtc"]])
  expect_lte(max(abs(cl[odf("PANEL_PULSE_TAGGED"), ] - 1)), law_tag + OD_TOL_CHAIN[["tagged"]] +
               2 * .nsteps * OD_EPS * sum(.spin$y[, "C14"]) / OD_PULSE[["gtc"]])
  # and before the release nothing is there
  k0 <- .tab$t == OD_PULSE[["year"]]
  expect_true(all(abs(.tab$frac[k0]) < 1e-9))
})

test_that("THE LESSON: the tagged atoms reach the deep ocean faster than the extra carbon", {
  deep <- odf("app_ocean_depth_keys")(.spin$grid)[["deep"]]
  for (off in OD_LATER) {
    ti <- OD_PULSE[["year"]] + odf("OCEAN_DEPTH_INSTANT_OFFSET") + off
    at <- function(pn) .tab$frac[.tab$panel == pn & .tab$where == deep & abs(.tab$t - ti) < 1e-6]
    expect_gt(at(odf("PANEL_PULSE_TAGGED")), at(odf("PANEL_PULSE_EXTRA")))
  }
})

test_that("the legend keys derive from the grid, and move when a boundary moves (MUTATION)", {
  keys <- odf("app_ocean_depth_keys")(.spin$grid)
  b <- odf("app_ocean_depth_bounds")(.spin$grid)
  r <- function(z) as.character(round(z / odf("OCEAN_DEPTH_LABEL_ROUND_M")) * odf("OCEAN_DEPTH_LABEL_ROUND_M"))
  expect_match(keys[["upper"]], r(b[2]), fixed = TRUE)
  expect_match(keys[["intermediate"]], r(b[3]), fixed = TRUE)
  expect_match(keys[["deep"]], r(b[3]), fixed = TRUE)
  moved <- odf("app_ocean_depth_keys")(.spin$grid, last = c(upper = 4L, intermediate = 6L))
  expect_false(identical(moved[["upper"]], keys[["upper"]]))
  expect_identical(levels(.tab$where), c(odf("KEY_PULSE_AIR"), odf("KEY_PULSE_LAND"), unname(keys)))
})

test_that("the panel RENDERS: two facets, five fills in stack order, the closure sentence", {
  g <- odf("plot_pulse_partition")(.tab, OD_PULSE[["gtc"]], OD_PULSE[["year"]])
  b <- ggplot2::ggplot_build(g)
  expect_length(unique(b$layout$layout$PANEL), 2L)
  pal <- odf("PAL")
  want <- unname(pal[c("atm", "land", "ocean_upper", "ocean_mid", "ocean_deep")])
  expect_setequal(toupper(unique(b$data[[1]]$fill)), toupper(want))
  expect_match(paste(g$labels$caption, collapse = " "), "add to 100%", fixed = TRUE)
})

# ---- the palette, as drawn ----------------------------------------------------------------
.od_tool <- file.path(.root, "tools", "palette_check.py")
.od_composite <- function(hex, alpha) {
  v <- grDevices::col2rgb(hex)[, 1]
  sprintf("#%02x%02x%02x", round(alpha * v[1] + (1 - alpha) * 255),
          round(alpha * v[2] + (1 - alpha) * 255), round(alpha * v[3] + (1 - alpha) * 255))
}
.od_min_de <- function(cols) {
  out <- suppressWarnings(system2("python3", c(shQuote(.od_tool), shQuote(cols)), stdout = TRUE, stderr = TRUE))
  m <- regmatches(out, regexpr("minimum over all pairs and vision types: [0-9.]+", out))
  if (length(m) != 1L) stop("could not read the checker's minimum:\n", paste(out, collapse = "\n"))
  as.numeric(sub(".*: ", "", m))
}
.od_target <- function() {
  l <- grep("^DE_TARGET\\s*=", readLines(.od_tool, warn = FALSE), value = TRUE)
  as.numeric(sub("^DE_TARGET\\s*=\\s*([0-9.]+).*", "\\1", l))
}

test_that("the five fills, composited as drawn, clear the checker's target; Brewer Blues does not", {
  skip_if(!file.exists(.od_tool), "tools/palette_check.py absent")
  skip_if(unname(Sys.which("python3")) == "", "python3 not available")
  pal <- odf("PAL"); a <- odf("PULSE_PARTITION_ALPHA")
  fills <- vapply(pal[c("atm", "land", "ocean_upper", "ocean_mid", "ocean_deep")], .od_composite, "", alpha = a)
  tgt <- .od_target()
  expect_true(is.finite(tgt) && tgt > 0)
  expect_gte(.od_min_de(fills), tgt)
  # MUTATION: the obvious pick (ColorBrewer Blues 3-class, light to dark) beside the same air and land
  brewer <- vapply(c(pal[["atm"]], pal[["land"]], "#9ecae1", "#4292c6", "#08519c"), .od_composite, "", alpha = a)
  expect_lt(.od_min_de(brewer), tgt)
})

# ---- the legend, measured on the RENDERED grob --------------------------------------------
# ggplot clips a legend row that does not fit (it never wraps one), so the row count is chosen by
# measuring (plots.R app_legend_nrow()). Checked here on the drawn guide box, not on the chooser's
# own arithmetic: at the 768 px floor (552 px panel) and at 1440 px (1056 px panel, measured
# 2026-09-25 in plots.R), the box must fit inside the panel less theme_ccx()'s margin.
.od_legend_px <- function(g, px) {
  f <- tempfile(fileext = ".png")
  grDevices::png(f, width = px, height = 330, res = 72)
  on.exit({ grDevices::dev.off(); unlink(f) }, add = TRUE)
  gt <- ggplot2::ggplotGrob(g)
  i <- which(gt$layout$name == "guide-box-top")
  if (length(i) != 1L) stop("no single top guide box in: ", paste(gt$layout$name, collapse = ", "))
  grid::convertWidth(grid::grobWidth(gt$grobs[[i]]), "in", valueOnly = TRUE) * 72
}
.od_plot_at <- function(px, nrow = NULL) {
  f <- tempfile(fileext = ".png")
  grDevices::png(f, width = px, height = 330, res = 72)
  on.exit({ grDevices::dev.off(); unlink(f) }, add = TRUE)
  odf("app_set_panel_px")(px); on.exit(odf("app_clear_panel_px")(), add = TRUE)
  g <- odf("plot_pulse_partition")(.tab, OD_PULSE[["gtc"]], OD_PULSE[["year"]])
  if (!is.null(nrow)) g <- g + ggplot2::guides(fill = ggplot2::guide_legend(nrow = nrow))
  g
}

test_that("the five-key legend fits the panel at the floor and at 1440 px (MUTATION: one row at the floor)", {
  for (px in c(odf("APP_PANEL_PX")[["full"]], 1056L)) {
    w <- .od_legend_px(.od_plot_at(px), px)
    expect_lte(w, px - odf("APP_PLOT_MARGIN_PX"), label = paste("legend at", px, "px"))
  }
  floor_px <- odf("APP_PANEL_PX")[["full"]]
  expect_gt(.od_legend_px(.od_plot_at(floor_px, nrow = 1L), floor_px), floor_px - odf("APP_PLOT_MARGIN_PX"))
})
