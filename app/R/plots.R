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
LAB_GROWTH <- "CO₂ growth (ppm per year)"
# The pulse lab's two y axes (F4). Named because the radio that switches
# between them is in ui.R and the sentence that describes them is in server.R:
# three files, one fact, and the standing rule is that they share a constant.
LAB_PULSE_AIRBORNE <- "Share of the pulse still in the air"
LAB_PULSE_WARMING  <- "Extra warming caused by the pulse (°C)"
# Named because this series has TWO possible observational sources and the panel
# must say which it drew -- see plot_growth_rate().
LAB_GROWTH_OBS  <- "Measured (Global Carbon Budget)"
# ⛔ The sentence that keeps plot_pulse_partition() honest. See its roxygen.
PULSE_PARTITION_NOTE <- paste("This is how much EXTRA carbon each reservoir holds because of",
                              "the pulse \u2014 the difference between running with it and",
                              "without. It is not a trace of where those particular molecules",
                              "went, which is a different question with a different answer.")
GROWTH_UNIT_NOTE <- paste("Annual means differenced. Measured growth is the Global Carbon",
                          "Budget's atmospheric growth, converted GtC/yr ÷", 
                          "GtC per ppm. Review card 4 scores the same series in GtC/yr.")

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

# ⛔ ggplot CAPTIONS CLIP, THEY DO NOT WRAP -- a caption longer than the panel
# is silently truncated mid-sentence, and the provenance prefix below counts
# toward line 1's width. The review tab learned this on 2026-09-22 (l) and
# wrapped its own captions (rv_cap()); the TEACHING panels did not, and on
# 2026-09-22 the pulse-partition panel's caption lost the clause that keeps it
# honest ("it is not a trace of where those molecules went") to exactly this.
# Wrapping here fixes every panel at once and cannot be forgotten at a call site.
APP_CAP_WIDTH <- 150   # characters; the teaching panels are wider than the cards

#' Standard annotation carried by every plot that uses model output
app_provenance_caption <- function(extra = NULL, width = APP_CAP_WIDTH) {
  base <- sprintf("Model: %s (%s). Not peer-reviewed teaching software.",
                  app_params$source, app_params$status)
  txt <- if (is.null(extra)) base else paste(base, extra, sep = "  ")
  paste(strwrap(txt, width = width), collapse = "\n")
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
# ⛔ THE LAND TERM IS THE **GCB CONVENTION** SINCE 2026-09-22 (Marcus's ruling
# R1), AND WITHOUT IT THIS PANEL DID NOT BALANCE.
#
# Land-use emissions are an INTERNAL TRANSFER in this model: `e_luc` moves
# carbon OUT of the land pool and into the air. So they cannot also be an
# ADDITION to the atmosphere+land+ocean system -- only FOSSIL carbon is new to
# it. Plotting the raw pool change against a dashed line that included land use
# left the stack 237.6 GtC below the line at 2024 (32 % of cumulative
# emissions), which is exactly cumulative LUC, and read as a mass-conservation
# failure the model does not have: against cumulative FOSSIL the three areas
# close to -1.05 GtC, i.e. 0.2 %.
#
# The fix is the convention the Global Carbon Budget itself uses, and the one
# GATE 7 already scores against (`dg_annual_sinks()` adds `eluc` back the same
# way): the LAND SINK is the residual terrestrial uptake EXCLUDING land-use
# emissions, so land-use carbon appears once, on the emitted side. The three
# terms then sum to TOTAL emissions, which is the budget a reader recognises.
#
# ⚠ `land_gross` keeps the raw pool change, because the two are different
# quantities and a caller that wants the actual land stock must not silently
# get the sink instead.
partition_table <- function(out, F) {
  cum <- app_cumulative_emissions(F)
  atm0 <- out$co2_global[1] * ccx_const("GtC_PER_PPM")
  atm  <- out$co2_global * ccx_const("GtC_PER_PPM") - atm0
  land_gross <- out$land_C  - out$land_C[1]
  ocean <- out$ocean_C - out$ocean_C[1]
  # cumulative land-use emissions on the model's own monthly grid, carrying the
  # fitted `luc_scale` because it is applied to the forcing columns themselves
  cum_luc <- cumsum((F$e_luc_NH + F$e_luc_SH) / 12)
  data.frame(t = out$t, emitted = cum,
             atmosphere = atm, land = land_gross + cum_luc, ocean = ocean,
             land_gross = land_gross, cum_luc = cum_luc)
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
             label = "dashed = total emitted (fossil + land use)") +
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

plot_gcb_bars <- function(out, gcb, F, window = c(2014, 2023)) {
  yr <- floor(out$t)
  ann <- stats::aggregate(cbind(ocean_C, land_C) ~ yr, data = out, FUN = mean)
  ann <- ann[order(ann$yr), ]
  ann$ocean_sink <- c(NA, diff(ann$ocean_C))
  # ⛔ THE GCB CONVENTION, as in partition_table() above and in the gate. GCB's
  # "land sink" is the RESIDUAL terrestrial sink, EXCLUDING land-use emissions;
  # the raw pool change includes the LUC outflow, so comparing it with GCB's
  # number was not like-for-like and made the model's land bar low by roughly
  # the LUC flux (~1 GtC/yr recently). GATE 7 scores land 3.09 against GCB and
  # PASSES precisely because dg_annual_sinks() adds `eluc` back; this panel did
  # not, so the app and the gate disagreed about the same quantity.
  eluc <- ccx_forcing_eluc_annual(F)
  ann$land_sink <- c(NA, diff(ann$land_C)) +
    eluc$eluc[match(ann$yr, eluc$year)]
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
    # headroom for the dodged value labels, which left the panel before
    # 2026-09-22 (vjust puts them above the bar with nothing reserved)
    scale_y_continuous(expand = expansion(mult = c(0.02, 0.14))) +
    labs(x = NULL, y = "Average uptake (GtC per year)",
         subtitle = sprintf("%d–%d average", window[1], window[2]),
         caption = app_provenance_caption(
           paste("Land sink on the Global Carbon Budget's convention: the",
                 "residual terrestrial sink, excluding land-use emissions."))) +
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

#' The global-mean CO2 of a run, whoever produced it
#'
#' ⛔ `co2_global` IS NOT A COLUMN OF EVERY RUN and assuming it is has already
#' cost one silent bug. `ccx_run_fast()` / `ccx_run_coupled()` return `co2_NH`
#' and `co2_SH`; `app/global.R` ATTACHES `co2_global` by hand to the historical
#' run and to `app_run_mechanisms()` output, and the PULSE runs go through
#' neither. Reading the column directly gave NULL there, the series became
#' numeric(0), `rbind` dropped its rows without complaint, and a stacked-area
#' panel drew two of its three bands. Derive it; do not trust the attachment.
ccx_global_co2 <- function(o) {
  if (!is.null(o$co2_global)) o$co2_global else (o$co2_NH + o$co2_SH) / 2
}

#' The year-over-year CO2 growth rate: model, counterfactual, and observed
#'
#' ⭐ ADDED 2026-09-22, Marcus review C2 (and 08-29 spec item ①b): "a useful
#' additional chart would be the year-over-year increase in CO2: that would help
#' show interannual variability and how ENSO years matter for that." It is the
#' highest-value single addition in the review because it serves THREE comments
#' at once -- C1 (put observations on this tab; the ENSO switch means nothing
#' until you can see it move the model toward the data), C2 itself, and C3 ("switch
#' it off and the wobbles go" is a claim about a quantity this tab never drew).
#' Review card 4's variance shortfall is also a statement about THIS series.
#'
#' ⚠ UNITS ARE ppm/yr HERE AND GtC/yr ON REVIEW CARD 4, DELIBERATELY. ppm/yr is
#' the number a reader has met ("CO2 rose 2.4 ppm last year"); card 4 reproduces
#' GATE V, which is defined in GtC/yr, and re-expressing a gate to match a
#' teaching panel would be the worse trade. Both axes say which they are, and
#' GROWTH_UNIT_NOTE states the conversion on the panel itself.
#'
#' ⚠ THE OBSERVED SERIES IS GCB'S `atm_growth`, THE SAME SOURCE GATE V SCORES
#' AGAINST (calibration/lib_design_gates.R, dg_annual_budget). Deriving a second
#' "observed growth rate" from the station records would put two different
#' observations under one name in one app -- the caption-sync bug class -- and
#' they would not agree: `atm_growth` is a global mass budget, a station is a
#' point. It is GtC/yr in the file and is divided by GtC_PER_PPM here.
#'
#' ⚠ THE MODEL SERIES IS A DIFFERENCE OF ANNUAL MEANS, not of monthly values at a
#' fixed month. A December-to-December difference carries the seasonal cycle's own
#' year-to-year wobble into what is supposed to be an ANNUAL growth rate; in the NH
#' box that is the larger signal of the two.
#'
#' @param base model output (the full model)
#' @param alt  model output with a mechanism removed, or NULL
#' @param gcb  the GCB budget table (APP_GCB), or NULL to omit observations
#' @param label the legend label for `alt`
plot_growth_rate <- function(base, alt = NULL, gcb = NULL, yr_range = c(1960, 2024),
                             label = "Mechanism off", show_obs = TRUE) {
  ann <- app_annual_growth        # ⛔ ONE definition; see its header (F2)
  b <- ann(base); b$who <- "Full model"
  d <- b
  if (!is.null(alt)) { x <- ann(alt); x$who <- label; d <- rbind(d, x) }
  if (!is.null(gcb) && isTRUE(show_obs) && "atm_growth" %in% names(gcb)) {
    o <- app_obs_growth(gcb); o$who <- LAB_GROWTH_OBS
    d <- rbind(d, o)
  }
  d <- d[d$year >= yr_range[1] & d$year <= yr_range[2], ]
  cols <- stats::setNames(c(PAL[["model"]], PAL[["off"]], PAL[["obs"]]),
                          c("Full model", label, LAB_GROWTH_OBS))
  ggplot(d, aes(year, g, colour = who)) +
    geom_line(linewidth = 0.7) +
    geom_point(size = 0.8) +
    scale_colour_manual(values = cols[names(cols) %in% unique(d$who)]) +
    labs(x = LAB_YEAR, y = LAB_GROWTH,
         caption = app_provenance_caption(GROWTH_UNIT_NOTE)) +
    theme_ccx()
}

# ---------------------------------------------------------------------
# Tab 3: the DRIVER panel (Marcus review F1, 2026-09-24)
# ---------------------------------------------------------------------
# "A third panel showing the driver itself -- volcanic AOD by year, the ENSO
# index by year, emissions by year."
#
# \u2b50 WHAT MAKES THIS MORE THAN A THIRD CHART: it draws the driver BEFORE and
# AFTER the switch, so the reader can see which KIND of switch they just threw.
# Two of them (volcanic, emissions) delete the input -- the purple line drops to
# zero. Two of them (El Nino, warming) leave the input untouched and remove the
# model's RESPONSE to it: the El Nino still happens, the model just stops
# listening. That distinction is the single most-confused thing about this tab,
# it is what C5's "the world still warms either way" caveat is trying to say in
# words, and it has never been drawn.
#
# \u26d4 THE COVERAGE ZERO IS DISCLOSED ON THE FACE OF THE CHART, not in a
# footnote. The Nino 3.4 index is identically zero before 1948 and the AOD and
# temperature series before 1850 (R/mechanisms.R CCX_DRIVERS, and the constants
# it names). The tab's DEFAULT window is 1850-2024, so the ENSO driver opens
# with 98 years of flat zero that a reader will otherwise take as a statement
# about the climate rather than about the archive.
#
# \u26d4 NO SECOND Y-AXIS AND NO RESCALING. The four drivers carry four different
# units and this panel draws exactly one of them at a time, labelled with its
# own. Overlaying them on a shared axis -- the obvious "show all three at once"
# reading of the comment -- would put GtC/yr, degrees C and a dimensionless
# optical depth on one scale, where the only honest normalisation is z-scores
# and those hide the thing the panel exists to show (a driver going to zero).
DRIVER_KEPT_NOTE <- paste("This switch leaves the driver alone \u2014 the two lines are",
                          "identical. What it removes is the model's RESPONSE to it.")

plot_driver <- function(drv, yr_range, label = "Mechanism off") {
  k <- drv$t >= yr_range[1] & drv$t <= yr_range[2]
  d <- data.frame(t = drv$t[k], v = drv$full[k], who = "Full model")
  if (isTRUE(drv$removes_driver))
    d <- rbind(d, data.frame(t = drv$t[k], v = drv$off[k], who = label))
  cols <- stats::setNames(c(PAL[["model"]], PAL[["off"]]), c("Full model", label))
  extra <- if (isTRUE(drv$removes_driver)) NULL else DRIVER_KEPT_NOTE
  # The coverage zero, marked where it is VISIBLE and stated where it is not.
  gap <- !is.na(drv$since) && yr_range[1] < drv$since
  if (gap)
    extra <- paste(c(extra, sprintf(paste("This series is identically zero before %d,",
                                          "which is where the observational record",
                                          "begins \u2014 not a statement that nothing",
                                          "happened earlier."), drv$since)),
                   collapse = "  ")
  g <- ggplot(d, aes(t, v, colour = who)) +
    geom_hline(yintercept = 0, colour = "grey75", linewidth = 0.3) +
    geom_line(linewidth = 0.7) +
    scale_colour_manual(values = cols[names(cols) %in% unique(d$who)]) +
    labs(x = LAB_YEAR, y = drv$unit, subtitle = drv$label,
         caption = app_provenance_caption(extra)) +
    theme_ccx()
  if (gap)
    g <- g + geom_vline(xintercept = drv$since, linetype = "22", colour = "grey55") +
      annotate("text", x = drv$since, y = Inf, label = paste(" record begins", drv$since),
               hjust = 0, vjust = 1.4, size = 3.1, colour = "grey40")
  g
}

#' The annual CO2 growth rate of a run, on the model's own calendar years
#'
#' \u26d4 EXTRACTED 2026-09-24 (F2) BECAUSE IT WAS WRITTEN THREE TIMES -- here,
#' in `output$c_growth_note` (app/server.R) and in the F3 diagnostic. The
#' residual numbers F2 adds must be measured against EXACTLY the series the
#' panel draws, and three hand-copies of an annualisation is how that stops
#' being true without anything failing. One definition, used by both.
#'
#' Partial first/last years are dropped (`n == 12`): a year with 7 months in it
#' has a mean that is a seasonal phase, not an annual mean, and differencing it
#' manufactures a growth-rate outlier at each end of every window.
app_annual_growth <- function(o) {
  g <- ccx_global_co2(o)
  a <- stats::aggregate(list(co2 = g), list(year = floor(o$t)), mean)
  n <- stats::aggregate(list(n = g), list(year = floor(o$t)), length)
  a <- a[n$n == 12, ]
  data.frame(year = a$year[-1], g = diff(a$co2))
}

#' The observed annual growth rate, from the Global Carbon Budget
app_obs_growth <- function(gcb) {
  data.frame(year = gcb$year, g = gcb$atm_growth / ccx_const("GtC_PER_PPM"))
}

#' F2 (Marcus 2026-09-24): "full model minus measured" and "experiment minus
#' measured", AS NUMBERS ON THE SECOND PANEL rather than as panels of their own.
#'
#' \u2b50 WHY NUMBERS ON THIS PANEL AND NOT A NEW PANEL. The growth chart already
#' draws all three series in the SAME UNITS on ONE axis, so each residual is
#' just the vertical gap between two lines already in front of the reader. A
#' separate residual panel would re-draw the same information a second time and
#' add a third chart to a tab that now has three.
#'
#' \u26d4 THE WINDOW IS THE INTERSECTION OF THE SLIDER AND THE OBSERVED RECORD,
#' and it is passed IN rather than recomputed, so it cannot drift from the
#' scatter sentence beside it. The model runs from 1750 and GCB's atmospheric
#' growth starts 1959; a window of 1850-2024 would give the model 174 years and
#' the observation 66, which is the like-for-like bug this panel already fixed
#' once (app/server.R, output$c_growth_note).
#'
#' \u26a0 WHAT NUMBERS CANNOT SHOW, and the caller should not pretend otherwise: a
#' mean and an RMS cannot tell "consistently 0.1 high" from "fine except 1992
#' and 1998". `worst_year` is returned for exactly that reason -- it is the one
#' statistic here that reveals an EPISODIC error, and a bias/RMS pair alone
#' would hide it.
#'
#' @return NULL when the window holds too few overlapping years, else a list
#'   with the per-series bias, RMS and worst year.
app_growth_residuals <- function(base, alt, gcb, yr) {
  if (is.null(gcb) || !"atm_growth" %in% names(gcb)) return(NULL)
  ob <- app_obs_growth(gcb)
  one <- function(o) {
    m <- app_annual_growth(o)
    d <- merge(m, ob, by = "year", suffixes = c("_mod", "_obs"))
    d <- d[d$year >= yr[1] & d$year <= yr[2], ]
    if (nrow(d) < GROWTH_RESID_MIN_YEARS) return(NULL)
    r <- d$g_mod - d$g_obs
    list(bias = mean(r), rms = sqrt(mean(r^2)), n = nrow(d),
         worst_year = d$year[which.max(abs(r))], worst = r[which.max(abs(r))])
  }
  a <- one(base); b <- if (is.null(alt)) NULL else one(alt)
  if (is.null(a)) return(NULL)
  list(full = a, alt = b)
}

# The floor below which a bias/RMS pair is noise rather than a measurement. Same
# dozen-year bar the scatter sentence already uses, and named so the two cannot
# drift apart.
GROWTH_RESID_MIN_YEARS <- 12L

#' Where the pulse carbon ends up: share in air, land and ocean over time
#'
#' ⭐ ADDED 2026-09-22, Marcus review F2: "for the pulse lab, I would like a
#' second panel showing where the pulse carbon ends up (e.g., percent
#' atmosphere, land, ocean)."
#'
#' ⛔⛔ THE CAPTION IS LOAD-BEARING AND MAY NOT BE LOOSENED. This panel answers
#' "how much ADDED carbon is in each reservoir", which is a PERTURBATION
#' question -- the difference between a run with the pulse and the same run
#' without. It does NOT answer "where did those molecules go", which is a LABEL
#' question and has a different answer: the two are 2.8x apart at 100 years
#' ([[pulse_label_vs_perturb]]). A caption that says "where the molecules went"
#' over this chart would be wrong by that factor, and it is exactly the phrasing
#' a reader reaches for.
#'
#' ⚠ THE LAND-USE CONVENTION DOES NOT ARISE HERE, and that is worth stating
#' because it dominates the OTHER partition panel (plot_partition(), review R1).
#' Both runs carry identical land-use forcing, so the LUC transfer cancels
#' exactly in the difference. No term is added back.
#'
#' The closure residual is COMPUTED and shown rather than assumed: the three
#' shares must add to 100 %, and a panel that silently did not would be
#' reporting a leak as physics.
plot_pulse_partition <- function(base, pulse, pulse_gtc, pulse_year,
                                 yr_max = NULL) {
  gp <- ccx_const("GtC_PER_PPM")
  t  <- base$t
  # ⛔ `co2_global` IS NOT A COLUMN OF EVERY RUN. `ccx_run_fast()` and
  # `ccx_run_coupled()` return `co2_NH` / `co2_SH`; global.R ADDS `co2_global`
  # by hand to the historical run and to `app_run_mechanisms()` output, and the
  # PULSE runs never go through either. Reading it here returned NULL, so the
  # atmosphere series was numeric(0), `rbind` silently dropped its rows, and the
  # panel drew land and ocean stacking to ~80 % with no air band and no error.
  # Found 2026-09-22 by looking at the rendered chart. Derive it here instead of
  # trusting a column somebody else may or may not have attached.
  d_atm   <- (ccx_global_co2(pulse) - ccx_global_co2(base)) * gp
  d_land  <- pulse$land_C  - base$land_C
  d_ocean <- pulse$ocean_C - base$ocean_C
  k <- t >= pulse_year
  if (!is.null(yr_max)) k <- k & t <= yr_max
  sh <- function(v) 100 * v[k] / pulse_gtc
  long <- rbind(
    data.frame(t = t[k], pct = sh(d_atm),   where = "Still in the air"),
    data.frame(t = t[k], pct = sh(d_land),  where = "Taken up by land"),
    data.frame(t = t[k], pct = sh(d_ocean), where = "Taken up by the ocean"))
  long$where <- factor(long$where, levels = c("Still in the air",
                                              "Taken up by land",
                                              "Taken up by the ocean"))
  # THE CLOSURE IS A GATE, NOT A DECORATION. The three shares must add to 100 %;
  # a panel that silently did not would be reporting a leak as physics. It is
  # also what would have caught the missing-air-band bug above on its own --
  # with the atmosphere dropped it is nowhere near 1.
  #
  # ⚠ MEASURED FROM AFTER THE PULSE HAS LANDED, and the first version was not.
  # The pulse is released over a single year, so at t = pulse_year none of it is
  # in yet, all three differences are 0, and closure is 0 -- which the check
  # faithfully reported as a "100 % closure error". That is the RAMP, not a
  # leak. The ramp still belongs on the CHART (a reader should see the pulse
  # arrive); it does not belong in a conservation check. Hence two windows.
  stopifnot(length(d_atm) == length(t), length(d_land) == length(t),
            length(d_ocean) == length(t))
  kc <- k & t >= pulse_year + 1
  closure <- (d_atm + d_land + d_ocean)[kc] / pulse_gtc
  resid <- if (any(kc)) 100 * max(abs(closure - 1)) else NA_real_
  ggplot(long, aes(t, pct, fill = where)) +
    geom_area(alpha = 0.9) +
    scale_fill_manual(values = c("Still in the air" = PAL[["atm"]],
                                 "Taken up by land" = PAL[["land"]],
                                 "Taken up by the ocean" = PAL[["ocean"]])) +
    labs(x = LAB_YEAR, y = sprintf("Share of the %g GtC pulse (%%)", pulse_gtc),
         caption = app_provenance_caption(paste(
           PULSE_PARTITION_NOTE,
           if (is.na(resid))
             "The window is too short to check that the three shares add up."
           else sprintf(paste("The three add to 100 %% of the pulse to within",
                              "%.2f %% at every step after it is released \u2014",
                              "carbon is conserved, so this is a partition and",
                              "not an estimate."), resid)))) +
    theme_ccx()
}

# ---------------------------------------------------------------------
# Tab 4: isotopes
# ---------------------------------------------------------------------
#' The station-representation offset, converted to permil on the model's own state
#'
#' ⭐ THE SAME LIKE-FOR-LIKE FIX THE KEELING PANEL GOT ON 2026-09-22, applied to
#' d13C (Marcus review I1 exposed it: showing the hemispheres separately makes
#' the comparison visible, so it had better be the comparison that was scored).
#' The likelihood never compared the model's d13C BOX to a station either: it
#' compared `box - rep_dC * (d_s - d13c_box) / co2_box`, because `rep_dC` is one
#' parameter tied across species by mass balance (R/likelihood.R, the
#' LIK_REP_SOURCE_D13C block). ⚠ REPRODUCED HERE, NOT APPROXIMATED -- the
#' conversion is evaluated on the model's OWN CO2 and d13C at each step, exactly
#' as the likelihood does, so the faint and solid lines differ by what the fit
#' actually saw and not by a constant chosen for the chart.
ccx_d13c_station <- function(d13c_box, co2_box, rep_dC) {
  if (is.null(rep_dC) || rep_dC == 0) return(d13c_box)
  d13c_box - rep_dC * (LIK_REP_SOURCE_D13C - d13c_box) / co2_box
}

#' delta-13C, with a hemisphere toggle (Marcus review I1)
#'
#' ⭐ ADDED 2026-09-22: "we talk about the north-south difference, but we only
#' show the global match. Could we show the two hemispheres separately? Maybe
#' with a button like on the Keeling curve?" Both hemispheres were already in
#' `out`; the panel simply never drew the southern one. Showing them is also
#' what puts REVIEW CARD 2's flaw -- the model's north-south d13C difference is
#' about twice the measured one -- where a reader can see it instead of only
#' reading about it.
plot_d13c <- function(out, obs, yr_range, hemi = "both", rep_dC = 0) {
  k <- out$t >= yr_range[1] & out$t <= yr_range[2]
  o_all <- obs$d13[obs$d13$decimal_date >= yr_range[1] &
                   obs$d13$decimal_date <= yr_range[2], ]
  arms <- list(NH = list(col = "d13c_NH", co2 = "co2_NH", st = "MLO",
                         lab = "Northern box", olab = "Measured, Mauna Loa",
                         pal = PAL[["nh"]], opal = "#7b241c"),
               SH = list(col = "d13c_SH", co2 = "co2_SH", st = "SPO",
                         lab = "Southern box", olab = "Measured, South Pole",
                         pal = PAL[["sh"]], opal = "#1a5276"))
  keep <- if (identical(hemi, "both")) c("NH", "SH") else hemi
  mod <- NULL; raw <- NULL; pts <- NULL; cols <- c()
  for (h in keep) {
    a <- arms[[h]]
    scored <- ccx_d13c_station(out[[a$col]][k], out[[a$co2]][k], rep_dC)
    mod <- rbind(mod, data.frame(t = out$t[k], v = scored, who = a$lab))
    raw <- rbind(raw, data.frame(t = out$t[k], v = out[[a$col]][k], who = a$lab))
    oo <- o_all[o_all$station == a$st, ]
    if (nrow(oo))
      pts <- rbind(pts, data.frame(t = oo$decimal_date, v = oo$d13c, who = a$olab))
    cols[a$lab] <- a$pal; cols[a$olab] <- a$opal
  }
  gap <- if (identical(hemi, "both")) {
    n <- out$d13c_NH[k]; s <- out$d13c_SH[k]
    sprintf(" The model's north-minus-south difference averages %+.2f\u2030 over this window \u2014 see Known issues, card 2.",
            mean(n - s))
  } else ""
  ggplot(mod, aes(t, v, colour = who)) +
    geom_line(data = raw, linewidth = 0.5, alpha = 0.35) +
    geom_line(linewidth = 0.75) +
    {if (!is.null(pts)) geom_point(data = pts, size = 0.5, alpha = 0.65)} +
    scale_colour_manual(values = cols[names(cols) %in%
                                      unique(c(mod$who, pts$who))]) +
    labs(x = LAB_YEAR, y = LAB_D13C,
         caption = app_provenance_caption(paste0(
           "Solid = the comparison the calibration scored (box minus the station offset of card 1); ",
           "faint = the box itself; points = measurements.", gap))) +
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
#' @param view two years, the window to CROP to (F5). Defaults to the whole
#'   run; the app passes APP_FUTURE_VIEW. Cropping by filtering rather than by
#'   coord_cartesian() on purpose -- see the note on APP_FUTURE_VIEW in
#'   global.R: a zoom would leave the y scale trained on years 1750 onward and
#'   silently widen the axis against a window that no longer contains them.
plot_future <- function(runs, yvar, ylab, view = NULL) {
  d <- do.call(rbind, lapply(names(runs), function(n) {
    cl <- runs[[n]]$climate
    data.frame(year = cl$year, y = cl[[yvar]], who = n)
  }))
  if (!is.null(view)) {
    d <- d[d$year >= view[1] & d$year <= view[2], ]
    # A view that selects nothing would draw an empty panel with axes, which
    # reads as "the model is flat here" rather than as a mistake. Refuse.
    if (!nrow(d))
      stop(sprintf("view %d-%d selects no model years", view[1], view[2]))
  }
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
    labs(x = LAB_YEAR, y = LAB_PULSE_AIRBORNE,
         caption = app_provenance_caption()) +
    theme_ccx()
}

#' The pulse lab's TEMPERATURE view (F4, Marcus 2026-09-22).
#'
#' The difference of the two runs' GMST, which is the only honest pulse
#' temperature -- the same paired construction plot_pulse_decay() uses for the
#' carbon, so the two views are differences of the SAME pair of runs and can be
#' read against each other.
#'
#' ⚠ WHY THE SERIES IS CLIPPED AT THE PULSE YEAR. The honest answer, measured
#' 2026-09-24: the pre-pulse difference is NOT zero, and the clip is hiding a
#' real defect rather than a definitional one. `ccx_annual_to_monthly()`
#' interpolates annual emissions with a NATURAL SPLINE, which is global, so a
#' one-year pulse rings backwards through its neighbours -- up to 3.06 ppm of
#' CO2 and 0.003 degC appear in the 26 years BEFORE the release, alternating in
#' sign. That is acausal and it is an artefact of the interpolator.
#' ⛔ The clip is kept because drawing it would invite the reader to interpret
#' ringing as physics, but it is NOT a fix and must not be described as one.
#' calibration/diag_pulse_spline_ringing.R measures both the artefact and its
#' consequence: the answers the tab actually quotes move by 0.05 percentage
#' points at +100 yr, so the numbers stand and the defect is presentational.
#' The fix is Marcus's call -- it lives either in the model's forcing path or
#' in the app's pulse construction, and only the second is free.
plot_pulse_warming <- function(base_cl, pulse_cl, pulse_year, pulse_gtc) {
  d <- data.frame(year = base_cl$year,
                  dT = pulse_cl$gmst - base_cl$gmst)
  d <- d[d$year >= pulse_year, ]
  ggplot(d, aes(year, dT)) +
    geom_hline(yintercept = 0, colour = "grey75", linewidth = 0.3) +
    geom_line(colour = PAL[["pulse"]], linewidth = 0.9) +
    labs(x = LAB_YEAR, y = LAB_PULSE_WARMING,
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

# Characters per line in the diagram's two footnotes. Named because the footnote
# grows whenever a mechanism is added to the model, and the failure mode is a
# line that runs off BOTH panel edges rather than an error.
DIAGRAM_NOTE_WIDTH <- 118

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
  # ⛔ LAND CLEARING IS ITS OWN ARROW SINCE 2026-09-22 (Marcus). It used to be
  # ADDED INTO the soil-to-atmosphere arrow -- `fx$rh + fx$luc` under a label
  # that said "respiration" -- so the one flux the whole land-use convention
  # argument is about (R1, 09-22: land use is an INTERNAL TRANSFER out of the
  # land pool into the air) had no arrow anywhere on the diagram that explains
  # the model. It is small, 1.0 against 69.6 GtC/yr, which is exactly why it
  # could hide: the printed number rounds to 71 either way. R/fluxes.R's own
  # header already says these two "must not be merged".
  #
  # ⚠ IT LEAVES BOTH LAND POOLS, NOT ONE. At `f_luc_wood` = 0 the debit is split
  # pro rata by ccx_luc_pool_shares(): ~24 % from the vegetation boxes and ~76 %
  # from the soils (70 % of the whole from the SLOW soil). Drawing one arrow per
  # pool would put "0" and "1" on two arrows for a 1 GtC/yr flux, so it is ONE
  # arrow rising from between the two land boxes -- the land as a whole -- and
  # the footnote says which pools it comes out of. Placed in the empty wedge
  # between photosynthesis and respiration, whose attachment points on the
  # atmosphere are moved apart by 0.25 to open it.
  arrows_df <- data.frame(
    x    = c(1.75, 1,   3,   2.6, 5,   5,   2.0, 2.0),
    xend = c(1,    3,   2.25, 4.6, 2.6, 5,   2.0, 2.0),
    y    = c(3.68, 2.4, 2.7, 3.75, 3.15, 2.6, 4.7, 2.55),
    yend = c(2.8,  2.4, 3.68, 3.05, 4.05, 1.7, 4.3, 3.62),
    # "to the deep" is the NET surface-to-interior transfer: the diffusive return
    # (`ml_int`, negative = upward) PLUS the biological pump's export (`pump`, a
    # channel of its own). Shown as one net number with the export named, so the
    # arrow cannot read "-40 to the deep" (which it did until 2026-09-08g).
    val  = c(fx$gpp, fx$litter, fx$rh, as_down, as_up, fx$ml_int + fx$pump,
             fx$foss, fx$luc),
    hj   = c(1.15, 0.5, -0.1, 0.5, 0.5, -0.15, -0.2, -0.12),
    vj   = c(0.5,  -0.6, 0.5, 1.5, -1.0, 0.5, 0.5, 0.5),
    # ⚠ THE NEW ARROW'S NAME IS READ FROM R/fluxes.R's CHANNEL TABLE, which
    # states that nothing downstream may name a channel in prose without reading
    # it from there. The older arrows predate that rule and keep their teaching
    # words; a new one has no reason to add a second name for the same flux.
    nm   = c("photosynthesis", "litterfall", "respiration",
             if (hs_on) "air to warm sea" else "air to sea",
             if (hs_on) "warm sea to air" else "sea to air",
             sprintf("to the deep, net\n(%.0f down as the biological\npump, %.0f back up by mixing)", fx$pump, -fx$ml_int),
             "fossil fuels",
             tolower(CCX_FLUX_CHANNELS[["luc"]])))
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
  # ⚠ THE POOL SPLIT IS COMPUTED FROM THE SAME EXPRESSION THE MODEL USES
  # (R/model.R's land-use block), not typed: `f_luc_wood` is a parameter and the
  # pro-rata shares move with the pools' sizes, so a sentence naming "mostly the
  # soil" has to be one that would change if that stopped being true.
  luc_note <- local({
    fw <- p$f_luc_wood
    if (is.null(fw) || !is.finite(fw) || !is.finite(fx$luc) || fx$luc == 0) return("")
    w <- if (fw >= 1) c(0, 1, 0, 0) else {
      sh <- ccx_luc_pool_shares(p); v <- (1 - fw) * sh; v[2] <- v[2] + fw; v
    }
    veg <- w[1] + w[2]; soil <- w[3] + w[4]
    sprintf(" Land-use change takes carbon out of the land pools themselves (%.0f%% soil, %.0f%% plants), not out of thin air.",
            100 * soil, 100 * veg)
  })
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
    # ⚠ WRAPPED, NOT HAND-BROKEN. This footnote used to carry a literal "\n" at a
    # point that happened to fit; adding the land-use clause (2026-09-22) pushed
    # the second line past BOTH panel edges, because an annotate() label clips
    # exactly as a caption does. strwrap() at a named measure means the next
    # clause someone adds cannot do that again.
    annotate("text", x = xmax / 2, y = 0.70, size = 3.1, colour = "grey35", lineheight = 1.05,
             label = paste(strwrap(sprintf(paste0(
               "Arrows are flows in GtC per year (%d). Stocks today: ",
               "atmosphere %s, land %s, ocean %s. ",
               "Each box exists twice — once per hemisphere.%s"),
               fx$year,
               fmt_gtc(stock$co2_global * ccx_const("GtC_PER_PPM")),
               fmt_gtc(stock$land_C), fmt_gtc(stock$ocean_C),
               paste0(
                 if (hs_on) " The cold boxes are the high-latitude ocean; the warm arrows exclude them." else "",
                 luc_note)), width = DIAGRAM_NOTE_WIDTH), collapse = "\n")) +
    annotate("text", x = xmax / 2, y = 0.18, size = 3.2, colour = "grey20", fontface = "bold", lineheight = 1.05,
             label = sprintf(paste0("Photosynthesis and the sea move %.0f GtC a year in and out of the air, ",
                                    "so an average CO₂ molecule\nstays only ~%.1f years. ",
                                    "The ADDED carbon still takes centuries to go."),
                             fx$atm_out, fx$tau_turn)) +
    xlim(0.1, xmax) + ylim(0, 4.9) + theme_void()
}
