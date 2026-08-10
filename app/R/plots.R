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
plot_keeling <- function(out, obs, yr_range, hemi = "both", show_obs = TRUE) {
  k <- out$t >= yr_range[1] & out$t <= yr_range[2]
  d <- out[k, ]
  series <- switch(hemi,
    both = data.frame(t = rep(d$t, 2), co2 = c(d$co2_NH, d$co2_SH),
                      who = rep(c("Model, Northern Hemisphere",
                                  "Model, Southern Hemisphere"), each = nrow(d))),
    NH   = data.frame(t = d$t, co2 = d$co2_NH, who = "Model, Northern Hemisphere"),
    SH   = data.frame(t = d$t, co2 = d$co2_SH, who = "Model, Southern Hemisphere"))

  p <- ggplot(series, aes(t, co2, colour = who)) +
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
  p + scale_colour_manual(values = c(
        "Model, Northern Hemisphere" = PAL[["nh"]],
        "Model, Southern Hemisphere" = PAL[["sh"]],
        "Measured, Mauna Loa"        = "#7b241c",
        "Measured, South Pole"       = "#1a5276")) +
    labs(x = LAB_YEAR, y = LAB_CO2, caption = app_provenance_caption()) +
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
