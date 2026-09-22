# =====================================================================
# plots.R -- one ggplot theme and one palette for the whole app.
#
# Every colour and label here is a named constant. Changing what a series MEANS
# without changing its label is the recurring bug this guards against.
# =====================================================================

PAL <- c(
  model     = "#1b6ca8",
  model2    = "#7fb3d5",
  obs       = "#22313f",
  nh        = "#c0392b",
  sh        = "#2471a3",
  atm       = "#5d6d7e",
  land      = "#27ae60",
  ocean     = "#2980b9",
  pulse     = "#d35400",
  off       = "#8e44ad",
  grid      = "#e5e8e8"
)

LAB_CO2   <- "CO₂ (ppm)"
LAB_YEAR  <- "Year"
LAB_D13C  <- "δ¹³C (‰)"
LAB_D14C  <- "Δ¹⁴C (‰)"
LAB_GTC   <- "Carbon (GtC)"
LAB_TEMP  <- "Temperature above 1850–1900 (°C)"

theme_ccx <- function(base_size = 13) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = PAL[["grid"]], linewidth = 0.4),
      plot.title    = element_text(face = "bold", size = base_size + 1),
      plot.subtitle = element_text(colour = "grey35", size = base_size - 1),
      plot.caption  = element_text(colour = "grey45", size = base_size - 3, hjust = 0),
      legend.position = "top",
      legend.title = element_blank(),
      plot.margin = margin(6, 10, 6, 6)
    )
}

#' Standard annotation carried by every plot that uses model output
app_provenance_caption <- function(extra = NULL) {
  base <- sprintf("Model: %s (%s). Not peer-reviewed teaching software.",
                  app_params$source, app_params$status)
  if (is.null(extra)) base else paste(base, extra, sep = "  ")
}

# ---------------------------------------------------------------------
# Tab 1: the Keeling curve
# ---------------------------------------------------------------------
# ⭐ TWO MODEL LINES SINCE 2026-09-22, AND THE REASON IS LIKE-FOR-LIKE.
# The likelihood never compared the model's hemispheric BOX to a station: it
# compared `box - rep_dC`, a fitted station-vs-box representation offset applied
# to CO2 and d13C together by mass balance (R/likelihood.R, LIK_REP_SOURCE_D13C).
# Until now this panel drew the raw box against the station points, i.e. a
# DIFFERENT comparison from the one that was scored -- about 4 ppm different, on
# the app's flagship chart, where the scored CO2 level stream fits to a fraction
# of that. So both are drawn: the solid line is what the calibration scored, the
# faint one is the raw box it came from, and the caption names the offset and how
# far outside its prior it sits. Dropping the faint line would turn a disclosed
# stand-in into a display convention, which is the thing to avoid here; dropping
# the solid one is what we had, which misreports the fit. Card 1 of the "Known
# issues" tab carries the residual and asks whether the offset is acceptable.
plot_keeling <- function(out, obs, yr_range, hemi = "both", show_obs = TRUE,
                         rep_dC = APP_REP_DC) {
  k <- out$t >= yr_range[1] & out$t <= yr_range[2]
  d <- out[k, ]
  off <- if (is.null(rep_dC) || !is.finite(rep_dC)) 0 else rep_dC
  lab_n <- "Model, Northern Hemisphere"; lab_s <- "Model, Southern Hemisphere"
  lab_nb <- "Model box, north"
  lab_sb <- "Model box, south"
  series <- switch(hemi,
    both = data.frame(t = rep(d$t, 2), co2 = c(d$co2_NH, d$co2_SH) - off,
                      who = rep(c(lab_n, lab_s), each = nrow(d))),
    NH   = data.frame(t = d$t, co2 = d$co2_NH - off, who = lab_n),
    SH   = data.frame(t = d$t, co2 = d$co2_SH - off, who = lab_s))
  raw <- switch(hemi,
    both = data.frame(t = rep(d$t, 2), co2 = c(d$co2_NH, d$co2_SH),
                      who = rep(c(lab_nb, lab_sb), each = nrow(d))),
    NH   = data.frame(t = d$t, co2 = d$co2_NH, who = lab_nb),
    SH   = data.frame(t = d$t, co2 = d$co2_SH, who = lab_sb))

  p <- ggplot(series, aes(t, co2, colour = who)) +
    {if (off != 0) geom_line(data = raw, aes(t, co2, colour = who),
                             linewidth = 0.5, alpha = 0.55)} +
    geom_line(linewidth = 0.6)

  if (show_obs) {
    o <- obs$co2[obs$co2$decimal_date >= yr_range[1] &
                   obs$co2$decimal_date <= yr_range[2], ]
    if (hemi == "NH") o <- o[o$station == "MLO", ]
    if (hemi == "SH") o <- o[o$station == "SPO", ]
    if (nrow(o)) {
      o$who <- ifelse(o$station == "MLO", "Measured, Mauna Loa",
                      "Measured, South Pole")
      p <- p + geom_point(data = o, aes(decimal_date, co2_ppm, colour = who),
                          size = 0.5, alpha = 0.7, inherit.aes = FALSE)
    }
  }
  p + scale_colour_manual(values = stats::setNames(
        c(PAL[["nh"]], PAL[["sh"]], "#7b241c", "#1a5276",
          PAL[["nh"]], PAL[["sh"]]),
        c(lab_n, lab_s, "Measured, Mauna Loa", "Measured, South Pole",
          lab_nb, lab_sb))) +
    guides(colour = guide_legend(nrow = 2, byrow = TRUE)) +
    labs(x = LAB_YEAR, y = LAB_CO2,
         caption = if (off != 0)
           # wrap the ASSEMBLED caption: the provenance prefix is part of the
           # first line's width (see rv_cap() in plots_review.R)
           paste(strwrap(app_provenance_caption(sprintf(paste(
             "Solid = what the calibration scored against these stations: the",
             "hemispheric box minus a fitted station offset of %.2f ppm. Faint =",
             "the box itself. Card 1 of Known issues has the residuals."), off)),
             width = 95), collapse = "\n")
           else app_provenance_caption()) +
    theme_ccx()
}

#' The seasonal cycle on its own: one average year
plot_seasonal <- function(out, obs, window = c(2000, 2024)) {
  ms <- ccx_model_year_stats(out, "co2_NH")
  k <- ms$year >= window[1] & ms$year <= window[2]
  a <- mean(ms$a[k]); b <- mean(ms$b[k])
  oh <- ccx_year_harmonic(obs$co2$decimal_date[obs$co2$station == "MLO"],
                          obs$co2$co2_ppm[obs$co2$station == "MLO"])
  ko <- oh$year >= window[1] & oh$year <= window[2]
  ao <- mean(oh$a[ko]); bo <- mean(oh$b[ko])

  phi <- seq(0, 1, length.out = 200)
  d <- rbind(
    data.frame(month = phi * 12, co2 = a * sin(2 * pi * phi) + b * cos(2 * pi * phi),
               who = "Model"),
    data.frame(month = phi * 12, co2 = ao * sin(2 * pi * phi) + bo * cos(2 * pi * phi),
               who = "Measured, Mauna Loa"))
  ggplot(d, aes(month, co2, colour = who)) +
    geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.3) +
    geom_line(linewidth = 0.9) +
    scale_x_continuous(breaks = seq(0, 12, 2),
                       labels = c("Jan", "Mar", "May", "Jul", "Sep", "Nov", "Jan")) +
    scale_colour_manual(values = c(Model = PAL[["model"]],
                                   `Measured, Mauna Loa` = PAL[["obs"]])) +
    labs(x = NULL, y = "CO₂ above the annual mean (ppm)",
         subtitle = sprintf("Average seasonal cycle, %d–%d", window[1], window[2]),
         caption = app_provenance_caption()) +
    theme_ccx()
}

# ---------------------------------------------------------------------
# Tab 2: where does the carbon go
# ---------------------------------------------------------------------
partition_table <- function(out, F) {
  cum <- app_cumulative_emissions(F)
  atm0 <- out$co2_global[1] * ccx_const("GtC_PER_PPM")
  atm  <- out$co2_global * ccx_const("GtC_PER_PPM") - atm0
  land <- out$land_C  - out$land_C[1]
  ocean <- out$ocean_C - out$ocean_C[1]
  data.frame(t = out$t, emitted = cum, atmosphere = atm, land = land, ocean = ocean)
}

plot_partition <- function(pt, yr_range) {
  k <- pt$t >= yr_range[1] & pt$t <= yr_range[2]
  d <- pt[k, ]
  long <- rbind(
    data.frame(t = d$t, gtc = d$atmosphere, where = "Stayed in the air"),
    data.frame(t = d$t, gtc = d$land,       where = "Taken up by land"),
    data.frame(t = d$t, gtc = d$ocean,      where = "Taken up by the ocean"))
  long$where <- factor(long$where, levels = c("Stayed in the air",
                                              "Taken up by land",
                                              "Taken up by the ocean"))
  ggplot(long, aes(t, gtc, fill = where)) +
    geom_area(alpha = 0.9) +
    geom_line(data = d, aes(t, emitted), inherit.aes = FALSE,
              linewidth = 0.7, colour = "grey20", linetype = "22") +
    annotate("text", x = yr_range[1] + 0.05 * diff(yr_range),
             y = max(d$emitted) * 0.93, hjust = 0, size = 3.4, colour = "grey20",
             label = "dashed = total emitted") +
    scale_fill_manual(values = c("Stayed in the air" = PAL[["atm"]],
                                 "Taken up by land" = PAL[["land"]],
                                 "Taken up by the ocean" = PAL[["ocean"]])) +
    labs(x = LAB_YEAR, y = paste("Cumulative", LAB_GTC),
         caption = app_provenance_caption()) +
    theme_ccx()
}

plot_airborne_fraction <- function(pt, yr_range) {
  k <- pt$t >= yr_range[1] & pt$t <= yr_range[2] & pt$emitted > 1
  d <- pt[k, ]
  d$af <- d$atmosphere / d$emitted
  ggplot(d, aes(t, af)) +
    geom_hline(yintercept = 0.5, colour = "grey75", linewidth = 0.3, linetype = "22") +
    geom_line(colour = PAL[["model"]], linewidth = 0.8) +
    scale_y_continuous(labels = function(x) paste0(round(100 * x), "%")) +
    labs(x = LAB_YEAR, y = "Share of all emissions still in the air",
         caption = app_provenance_caption(
           "Dashed line at 50% for reference.")) +
    theme_ccx()
}

plot_gcb_bars <- function(out, gcb, window = c(2014, 2023)) {
  yr <- floor(out$t)
  ann <- stats::aggregate(cbind(ocean_C, land_C) ~ yr, data = out, FUN = mean)
  ann <- ann[order(ann$yr), ]
  ann$ocean_sink <- c(NA, diff(ann$ocean_C))
  ann$land_sink  <- c(NA, diff(ann$land_C))
  k <- ann$yr >= window[1] & ann$yr <= window[2]
  g <- gcb[gcb$year >= window[1] & gcb$year <= window[2], ]
  d <- rbind(
    data.frame(sink = "Ocean", who = "This model", gtc = mean(ann$ocean_sink[k], na.rm = TRUE)),
    data.frame(sink = "Ocean", who = "Global Carbon Budget", gtc = mean(g$ocean_sink)),
    data.frame(sink = "Land",  who = "This model", gtc = mean(ann$land_sink[k], na.rm = TRUE)),
    data.frame(sink = "Land",  who = "Global Carbon Budget", gtc = mean(g$land_sink)))
  ggplot(d, aes(sink, gtc, fill = who)) +
    geom_col(position = position_dodge(width = 0.7), width = 0.6) +
    geom_text(aes(label = sprintf("%.2f", gtc)),
              position = position_dodge(width = 0.7), vjust = -0.4, size = 3.4) +
    scale_fill_manual(values = c("This model" = PAL[["model"]],
                                 "Global Carbon Budget" = PAL[["obs"]])) +
    labs(x = NULL, y = "Average uptake (GtC per year)",
         subtitle = sprintf("%d–%d average", window[1], window[2]),
         caption = app_provenance_caption()) +
    theme_ccx()
}

# ---------------------------------------------------------------------
# Tab 3: counterfactuals
# ---------------------------------------------------------------------
plot_counterfactual <- function(base, alt, yr_range, label) {
  k <- base$t >= yr_range[1] & base$t <= yr_range[2]
  d <- rbind(
    data.frame(t = base$t[k], co2 = base$co2_global[k], who = "Full model"),
    data.frame(t = alt$t[k],  co2 = alt$co2_global[k],  who = label))
  ggplot(d, aes(t, co2, colour = who)) +
    geom_line(linewidth = 0.8) +
    scale_colour_manual(values = stats::setNames(c(PAL[["model"]], PAL[["off"]]),
                                                 c("Full model", label))) +
    labs(x = LAB_YEAR, y = LAB_CO2, caption = app_provenance_caption()) +
    theme_ccx()
}

# ---------------------------------------------------------------------
# Tab 4: isotopes
# ---------------------------------------------------------------------
plot_d13c <- function(out, obs, yr_range) {
  k <- out$t >= yr_range[1] & out$t <= yr_range[2]
  o <- obs$d13[obs$d13$station == "MLO", ]
  o <- o[o$decimal_date >= yr_range[1] & o$decimal_date <= yr_range[2], ]
  ggplot(out[k, ], aes(t, d13c_NH)) +
    geom_line(colour = PAL[["model"]], linewidth = 0.7) +
    {if (nrow(o)) geom_point(data = o, aes(decimal_date, d13c),
                             colour = PAL[["obs"]], size = 0.6, alpha = 0.7)} +
    labs(x = LAB_YEAR, y = LAB_D13C,
         caption = app_provenance_caption(
           "Blue = model, dark = Mauna Loa measurements.")) +
    theme_ccx()
}

plot_d14c <- function(out, obs, yr_range) {
  k <- out$t >= yr_range[1] & out$t <= yr_range[2]
  d <- rbind(
    data.frame(t = out$t[k], v = out$d14c_NH[k], who = "Model, Northern Hemisphere"),
    data.frame(t = out$t[k], v = out$d14c_SH[k], who = "Model, Southern Hemisphere"))
  on <- obs$d14_nh[obs$d14_nh$t >= yr_range[1] & obs$d14_nh$t <= yr_range[2], ]
  os <- obs$d14_sh[obs$d14_sh$t >= yr_range[1] & obs$d14_sh$t <= yr_range[2], ]
  ggplot(d, aes(t, v, colour = who)) +
    geom_line(linewidth = 0.7) +
    {if (nrow(on)) geom_point(data = data.frame(t = on$t, v = on$d14c,
                                                who = "Measured, Northern Hemisphere"),
                              size = 0.4, alpha = 0.6)} +
    {if (nrow(os)) geom_point(data = data.frame(t = os$t, v = os$d14c,
                                                who = "Measured, Southern Hemisphere"),
                              size = 0.4, alpha = 0.6)} +
    scale_colour_manual(values = c(
      "Model, Northern Hemisphere" = PAL[["nh"]],
      "Model, Southern Hemisphere" = PAL[["sh"]],
      "Measured, Northern Hemisphere" = "#7b241c",
      "Measured, Southern Hemisphere" = "#1a5276")) +
    labs(x = LAB_YEAR, y = LAB_D14C, caption = app_provenance_caption()) +
    theme_ccx()
}

# ---------------------------------------------------------------------
# Tab 5: futures and pulses
# ---------------------------------------------------------------------
plot_future <- function(runs, yvar, ylab) {
  d <- do.call(rbind, lapply(names(runs), function(n) {
    cl <- runs[[n]]$climate
    data.frame(year = cl$year, y = cl[[yvar]], who = n)
  }))
  ggplot(d, aes(year, y, colour = who)) +
    geom_line(linewidth = 0.8) +
    labs(x = LAB_YEAR, y = ylab, caption = app_provenance_caption()) +
    theme_ccx()
}

plot_pulse_decay <- function(base_cl, pulse_cl, pulse_year, pulse_gtc) {
  d <- data.frame(year = base_cl$year,
                  frac = (pulse_cl$co2_ppm - base_cl$co2_ppm) /
                    (pulse_gtc / ccx_const("GtC_PER_PPM")))
  d <- d[d$year >= pulse_year, ]
  ggplot(d, aes(year, frac)) +
    geom_hline(yintercept = 0, colour = "grey75", linewidth = 0.3) +
    geom_line(colour = PAL[["pulse"]], linewidth = 0.9) +
    scale_y_continuous(labels = function(x) paste0(round(100 * x), "%")) +
    labs(x = LAB_YEAR, y = "Share of the pulse still in the air",
         caption = app_provenance_caption()) +
    theme_ccx()
}


#' The box diagram ("Under the hood"). ARROWS CARRY THEIR FLUXES (2026-08-13):
#' unlabelled arrows were the single biggest pedagogical gap in the app -- the
#' entire "CO2 only lasts 5 years" lesson is that photosynthesis and air-sea
#' exchange are ~70 and ~95 GtC/yr while emissions are ~11 and the net imbalance
#' ~5, and an arrow without a number cannot say that. Numbers come from the
#' flux trace (R/fluxes.R), i.e. from the model's own tap, never a typed table.
#'
#' THE SEVEN-BOX FORM (2026-09-08g). With the HILDA structure on (`p$hs_frac >
#' 0`) each hemisphere also has a cold high-latitude surface box and a cold
#' deep box; they are drawn on the right with their OWN numbers from the
#' per-edge trace (`CCX_FLUX_HS`), and the low-latitude air-sea arrows show the
#' warm share only (the channel totals include the cold box by design).
#'
#' @param fx one row of the annual flux trace (APP_FLUX_NOW)
#' @param stock the last row of the historical run's `out`
#' @param p the app's parameter list (for `hs_frac`)
fmt_gtc <- function(x) sprintf("%s GtC", format(round(x), big.mark = ","))

plot_box_diagram <- function(fx, stock, p) {
  hs_on <- isTRUE(p$hs_frac > 0)
  boxes <- data.frame(
    x = c(2, 1, 3, 5, 5), y = c(4, 2.4, 2.4, 3.0, 1.2),
    lab = c("Atmosphere", "Vegetation\n(leaves + wood)", "Soil\n(fast + slow)",
            "Ocean\nmixed layer", "Deep ocean\n(10 layers)"),
    col = c(PAL[["atm"]], PAL[["land"]], PAL[["land"]], PAL[["ocean"]], PAL[["ocean"]]))
  as_down <- fx$as_down - if (hs_on) fx$hs_as_down else 0
  as_up   <- fx$as_up   - if (hs_on) fx$hs_as_up   else 0
  # x/xend/yend and the flux each segment carries, kept in ONE table so a
  # moved arrow cannot end up with another arrow's number.
  arrows_df <- data.frame(
    x    = c(2,   1,   3,   2.6, 5,   5,   2.0),
    xend = c(1,   3,   2,   4.6, 2.6, 5,   2.0),
    y    = c(3.7, 2.4, 2.7, 3.75, 3.15, 2.6, 4.7),
    yend = c(2.8, 2.4, 3.7, 3.05, 4.05, 1.7, 4.3),
    # "to the deep" is the NET surface-to-interior transfer: the diffusive return
    # (`ml_int`, negative = upward) PLUS the biological pump's export (`pump`, a
    # channel of its own). Shown as one net number with the export named, so the
    # arrow cannot read "-40 to the deep" (which it did until 2026-09-08g).
    val  = c(fx$gpp, fx$litter, fx$rh + fx$luc, as_down, as_up, fx$ml_int + fx$pump, fx$foss),
    hj   = c(1.15, 0.5, -0.1, 0.5, 0.5, -0.15, -0.2),
    vj   = c(0.5,  -0.6, 0.5, 1.5, -1.0, 0.5, 0.5),
    nm   = c("photosynthesis", "litterfall", "respiration",
             if (hs_on) "air to warm sea" else "air to sea",
             if (hs_on) "warm sea to air" else "sea to air",
             sprintf("to the deep, net\n(%.0f down as the biological\npump, %.0f back up by mixing)", fx$pump, -fx$ml_int),
             "fossil fuels"))
  xmax <- 6.1
  if (hs_on) {
    xmax <- 7.9
    # The cold boxes sit to the right; their air-sea pair leaves the atmosphere
    # ABOVE the warm pair (y 4.12 / 3.92 against 3.75) so the two pairs never
    # cross, and their labels are pushed to the right-hand end of the arrows.
    boxes <- rbind(boxes, data.frame(
      x = c(6.9, 6.9), y = c(3.5, 1.2),
      lab = c(sprintf("Cold surface\n(high latitude, %.0f%%)", 100 * p$hs_frac), "Cold deep\nocean"),
      col = c(PAL[["ocean"]], PAL[["ocean"]])))
    arrows_df <- rbind(arrows_df, data.frame(
      x    = c(2.6, 6.45, 6.9, 6.3),
      xend = c(6.45, 2.6, 6.9, 5.6),
      y    = c(4.12, 3.42, 3.1, 1.35),
      yend = c(3.62, 3.92, 1.7, 1.35),
      val  = c(fx$hs_as_down, fx$hs_as_up, fx$hs_hd_net, fx$hd_int_net),
      hj   = c(-0.55, -0.55, -0.15, 0.5),
      vj   = c(-0.5, 1.5, 0.5, -0.6),
      nm   = c("air to cold sea", "cold sea to air",
               sprintf("sinks, net (of which\n%.1f biological export)", fx$hs_pump), "cold deep to interior")))
  }
  arrows_df$lab <- sprintf("%.0f\n%s", arrows_df$val, arrows_df$nm)
  ggplot() +
    geom_segment(data = arrows_df, aes(x, y, xend = xend, yend = yend),
                 arrow = arrow(length = unit(0.16, "cm"), type = "closed"),
                 colour = "grey45", linewidth = 0.5) +
    geom_text(data = arrows_df,
              aes((x + xend) / 2, (y + yend) / 2, label = lab, hjust = hj, vjust = vj),
              size = 2.9, colour = "grey20", lineheight = 0.9) +
    geom_label(data = boxes, aes(x, y, label = lab, fill = I(col)),
               colour = "white", fontface = "bold", size = 3.4,
               label.padding = unit(0.4, "lines"), label.r = unit(0.15, "lines")) +
    annotate("text", x = xmax / 2, y = 0.70, size = 3.1, colour = "grey35", lineheight = 1.05,
             label = sprintf(paste0("Arrows are flows in GtC per year (%d). Stocks today: ",
                                    "atmosphere %s, land %s, ocean %s.\n",
                                    "Each box exists twice — once per hemisphere.%s"),
                             fx$year,
                             fmt_gtc(stock$co2_global * ccx_const("GtC_PER_PPM")),
                             fmt_gtc(stock$land_C), fmt_gtc(stock$ocean_C),
                             if (hs_on) " The cold boxes are the high-latitude ocean; the warm arrows exclude them." else "")) +
    annotate("text", x = xmax / 2, y = 0.18, size = 3.2, colour = "grey20", fontface = "bold", lineheight = 1.05,
             label = sprintf(paste0("Photosynthesis and the sea move %.0f GtC a year in and out of the air, ",
                                    "so an average CO₂ molecule\nstays only ~%.1f years. ",
                                    "The ADDED carbon still takes centuries to go."),
                             fx$atm_out, fx$tau_turn)) +
    xlim(0.1, xmax) + ylim(0, 4.9) + theme_void()
}
