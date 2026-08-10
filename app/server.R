# =====================================================================
# server.R
#
# Every panel runs the model live -- a full 1750-2100 integration is ~40 ms and
# a coupled future run ~170 ms, so there is nothing to precompute and no lookup
# table to fall out of date with the model.
#
# The takeaway lines are COMPUTED, not written. A hard-coded sentence saying
# "the ocean has absorbed a quarter of our emissions" would silently become a
# lie the first time the calibration changed. Every number a student reads comes
# from the run they are looking at.
# =====================================================================

function(input, output, session) {

  fmt_gtc <- function(x) sprintf("%s GtC", format(round(x), big.mark = ","))
  fmt_pct <- function(x) sprintf("%.0f%%", 100 * x)

  # ---- 1. Keeling ----------------------------------------------------
  output$k_plot <- renderPlot(
    plot_keeling(APP_HIST$out, APP_OBS, input$k_years, input$k_hemi, input$k_obs))

  output$k_seasonal <- renderPlot(plot_seasonal(APP_HIST$out, APP_OBS))

  output$k_takeaway <- renderText({
    o <- APP_HIST$out
    i0 <- which.min(abs(o$t - 1958)); i1 <- nrow(o)
    obs_mlo <- APP_OBS$co2[APP_OBS$co2$station == "MLO", ]
    last_obs <- mean(obs_mlo$co2_ppm[obs_mlo$year >= 2023])
    sprintf(paste("Given only emissions, the model produces %.0f ppm in %d,",
                  "rising to %.0f ppm today; the measured value is about %.0f ppm.",
                  "Nothing here was tuned to the shape of this curve — the rise",
                  "comes out of the carbon bookkeeping."),
            o$co2_NH[i0], floor(o$t[i0]), o$co2_NH[i1], last_obs)
  })

  # ---- 2. Where does it go -------------------------------------------
  hist_F <- reactive({
    ccx_build_forcing("historical", APP_HIST_YEARS, prod_c14 = APP_SPIN$prod_c14)
  })
  partition <- reactive(partition_table(APP_HIST$out, hist_F()))

  output$w_partition <- renderPlot(plot_partition(partition(), input$w_years))
  output$w_af  <- renderPlot(plot_airborne_fraction(partition(), input$w_years))
  output$w_gcb <- renderPlot(plot_gcb_bars(APP_HIST$out, APP_GCB))

  latest <- reactive({
    pt <- partition()
    pt[nrow(pt), ]
  })
  output$w_atm   <- renderText(fmt_gtc(latest()$atmosphere))
  output$w_land  <- renderText(fmt_gtc(latest()$land))
  output$w_ocean <- renderText(fmt_gtc(latest()$ocean))

  output$w_takeaway <- renderText({
    d <- latest()
    sprintf(paste("Of the %s of carbon emitted since 1750, %s of it — %s — is",
                  "still in the air. The land and the ocean have quietly taken",
                  "the rest, and they are the only reason the number is not far",
                  "worse."),
            fmt_gtc(d$emitted), fmt_pct(d$atmosphere / d$emitted),
            fmt_gtc(d$atmosphere))
  })

  # ---- 3. Counterfactuals --------------------------------------------
  cf_run <- reactive({
    req(input$c_mech)
    app_run_mechanisms(input$c_mech, APP_HIST_YEARS, "historical")
  })

  output$c_plot <- renderPlot({
    m <- CCX_MECHANISMS[[input$c_mech]]
    plot_counterfactual(APP_HIST$out, cf_run()$out, input$c_years,
                        paste("Without:", m$label))
  })

  output$c_blurb <- renderUI({
    m <- CCX_MECHANISMS[[input$c_mech]]
    div(style = "margin-top:12px; font-size:0.93rem;", m$blurb)
  })

  output$c_caveat <- renderUI({
    cav <- cf_run()$caveats
    if (!length(cav)) return(NULL)
    div(class = "caveat", tags$strong("Worth knowing: "), paste(cav, collapse = " "))
  })

  output$c_takeaway <- renderText({
    m <- CCX_MECHANISMS[[input$c_mech]]
    a <- APP_HIST$out; b <- cf_run()$out
    i <- nrow(a)
    d <- b$co2_global[i] - a$co2_global[i]
    sprintf(paste("Without %s, CO₂ today would be %.0f ppm instead of %.0f —",
                  "a difference of %s%.0f ppm."),
            tolower(m$label), b$co2_global[i], a$co2_global[i],
            if (d > 0) "+" else "", d)
  })

  # ---- 4. Isotopes ---------------------------------------------------
  output$i_d13c <- renderPlot(plot_d13c(APP_HIST$out, APP_OBS, input$i_years))
  output$i_d14c <- renderPlot(plot_d14c(APP_HIST$out, APP_OBS, input$i_years))

  output$i_takeaway <- renderText({
    o <- APP_HIST$out
    i0 <- which.min(abs(o$t - 1850)); i1 <- nrow(o)
    ip <- which.max(o$d14c_NH)
    sprintf(paste("δ¹³C has fallen %.2f‰ since 1850 as fossil carbon diluted the",
                  "air — the fingerprint that the extra CO₂ is fossil. Δ¹⁴C tells",
                  "a different story: weapons testing nearly %s it by %d, and",
                  "watching it drain away is how we measure the speed of the",
                  "carbon cycle itself."),
            o$d13c_NH[i0] - o$d13c_NH[i1],
            if (o$d14c_NH[ip] > 500) "doubled" else "spiked",
            floor(o$t[ip]))
  })

  # ---- 5. Futures ----------------------------------------------------
  future_runs <- reactive({
    req(input$f_ssps)
    stats::setNames(
      lapply(input$f_ssps, function(s)
        ccx_run_coupled(APP_SPIN, s, APP_FUTURE_YEARS)),
      names(APP_SSPS)[match(input$f_ssps, APP_SSPS)])
  })

  stylised_run <- eventReactive(input$s_go, {
    em <- app_stylised_emissions(input$s_kind, APP_FUTURE_YEARS,
                                 to_zero_year = input$s_zero_year,
                                 rate_pct = input$s_rate,
                                 background = input$s_bg)
    ccx_run_coupled(APP_SPIN, input$s_bg, APP_FUTURE_YEARS,
                    nonco2_scenario = input$s_bg, emissions = em)
  })

  pulse_runs <- eventReactive(input$p_go, {
    yrs <- APP_PULSE_YEARS
    bg <- APP_SSP_EMIS[APP_SSP_EMIS$scenario == input$p_bg, ]
    y <- seq(yrs[1], yrs[2])
    base_em <- data.frame(
      year = y,
      fossil_GtC = stats::approx(bg$year, bg$fossil_GtC, xout = y, rule = 2)$y,
      luc_GtC    = stats::approx(bg$year, bg$luc_GtC,    xout = y, rule = 2)$y)
    pulse_em <- base_em
    # Released over a single year, so the pulse size is exactly what the slider
    # says once the annual-mean-conserving interpolation has run.
    pulse_em$fossil_GtC[pulse_em$year == input$p_year] <-
      pulse_em$fossil_GtC[pulse_em$year == input$p_year] + input$p_gtc
    list(
      base  = ccx_run_coupled(APP_SPIN, input$p_bg, yrs, input$p_bg,
                              emissions = base_em),
      pulse = ccx_run_coupled(APP_SPIN, input$p_bg, yrs, input$p_bg,
                              emissions = pulse_em),
      gtc = input$p_gtc, year = input$p_year)
  })

  output$f_plot <- renderPlot({
    if (identical(input$f_mode, "Pulse lab")) {
      pr <- pulse_runs()
      plot_pulse_decay(pr$base$climate, pr$pulse$climate, pr$year, pr$gtc)
    } else if (identical(input$f_mode, "Build your own")) {
      r <- stylised_run()
      runs <- c(future_runs()[1], list(`Your scenario` = r))
      plot_future(runs, input$f_yvar %||% "co2_ppm",
                  if (identical(input$f_yvar, "gmst")) LAB_TEMP else LAB_CO2)
    } else {
      plot_future(future_runs(), input$f_yvar,
                  if (identical(input$f_yvar, "gmst")) LAB_TEMP else LAB_CO2)
    }
  })

  output$f_takeaway <- renderText({
    if (identical(input$f_mode, "Pulse lab")) {
      pr <- pulse_runs()
      cb <- pr$base$climate; cp <- pr$pulse$climate
      ppm <- pr$gtc / ccx_const("GtC_PER_PPM")
      f <- function(y) (cp$co2_ppm[cp$year == y] - cb$co2_ppm[cb$year == y]) / ppm
      y1 <- pr$year + 100; y2 <- min(pr$year + 250, max(cb$year))
      sprintf(paste("Release %d GtC in %d and %s of it is still in the air a",
                    "century later; %s after %d years. Carbon dioxide is not a",
                    "pollutant that washes out — a large share of it is",
                    "effectively permanent on any human timescale."),
              pr$gtc, pr$year, fmt_pct(f(y1)), fmt_pct(f(y2)), y2 - pr$year)
    } else if (identical(input$f_mode, "Build your own")) {
      r <- stylised_run(); cl <- r$climate
      sprintf(paste("Your pathway reaches %.0f ppm and %+.1f °C by %d. Note how",
                    "little the temperature falls even when emissions stop —",
                    "the CO₂ already up there does not come back down quickly."),
              cl$co2_ppm[nrow(cl)], cl$gmst[nrow(cl)], max(cl$year))
    } else {
      rs <- future_runs()
      lo <- rs[[1]]$climate; hi <- rs[[length(rs)]]$climate
      sprintf(paste("By %d these scenarios span %.0f to %.0f ppm and %.1f to",
                    "%.1f °C. The spread is a choice, not a forecast."),
              max(lo$year), min(lo$co2_ppm[nrow(lo)], hi$co2_ppm[nrow(hi)]),
              max(lo$co2_ppm[nrow(lo)], hi$co2_ppm[nrow(hi)]),
              min(lo$gmst[nrow(lo)], hi$gmst[nrow(hi)]),
              max(lo$gmst[nrow(lo)], hi$gmst[nrow(hi)]))
    }
  })

  output$f_notes <- renderUI({
    if (identical(input$f_mode, "Pulse lab")) {
      div(class = "caveat",
          tags$strong("How this is computed: "),
          "the model runs twice — once with the pulse and once without, from ",
          "identical starting conditions — and the difference between the two ",
          "is the pulse's effect. Running only the pulse case would confound it ",
          "with everything else happening in the scenario.")
    } else NULL
  })

  # ---- 6. Under the hood ---------------------------------------------
  output$h_diagram <- renderPlot({
    boxes <- data.frame(
      x = c(2, 1, 3, 5, 5), y = c(4, 2.4, 2.4, 3.0, 1.2),
      lab = c("Atmosphere", "Vegetation", "Soil", "Ocean\nmixed layer",
              "Deep ocean\n(10 layers)"),
      col = c(PAL[["atm"]], PAL[["land"]], PAL[["land"]],
              PAL[["ocean"]], PAL[["ocean"]]))
    stock <- APP_HIST$out[nrow(APP_HIST$out), ]
    arrows_df <- data.frame(
      x = c(2, 1, 3, 2.6, 5, 5), xend = c(1, 3, 2, 4.6, 2.6, 5),
      y = c(3.7, 2.4, 2.7, 3.9, 3.3, 2.6), yend = c(2.8, 2.4, 3.7, 3.2, 4.1, 1.7))
    ggplot() +
      geom_segment(data = arrows_df, aes(x, y, xend = xend, yend = yend),
                   arrow = arrow(length = unit(0.16, "cm"), type = "closed"),
                   colour = "grey45", linewidth = 0.5) +
      geom_label(data = boxes, aes(x, y, label = lab, fill = I(col)),
                 colour = "white", fontface = "bold", size = 3.6,
                 label.padding = unit(0.4, "lines"), label.r = unit(0.15, "lines")) +
      annotate("text", x = 3, y = 0.4, size = 3.3, colour = "grey35",
               label = sprintf(paste("Today: atmosphere %s, land %s, ocean %s.",
                                     "Each box exists twice — once per hemisphere."),
                               fmt_gtc(stock$co2_global * ccx_const("GtC_PER_PPM")),
                               fmt_gtc(stock$land_C), fmt_gtc(stock$ocean_C))) +
      xlim(0.2, 6) + ylim(0, 4.6) + theme_void()
  })

  output$h_params <- renderTable({
    nm <- CCX_PARAM_NAMES
    desc <- c(
      beta = "CO₂ fertilisation strength", q10 = "Soil respiration warming response",
      k_w = "Air-sea gas transfer speed", h_ml = "Ocean mixed-layer depth",
      kz = "Deep-ocean mixing rate", tau_ex = "Interhemispheric mixing time",
      npp_frac_NH = "Northern share of plant growth",
      seas_amp_NH = "Northern seasonal amplitude",
      seas_amp_SH = "Southern seasonal amplitude",
      seas_phase_NH = "Northern seasonal timing",
      seas_phase_SH = "Southern seasonal timing",
      gamma_enso = "ENSO carbon sensitivity", tau_soil = "Soil turnover time",
      bomb_total = "Total bomb ¹⁴C released",
      sigma_co2 = "CO₂ mismatch allowance", sigma_d13c = "δ¹³C mismatch allowance",
      sigma_d14c = "Δ¹⁴C mismatch allowance")
    unit <- c(beta = "—", q10 = "—", k_w = "m/yr", h_ml = "m", kz = "m²/yr",
              tau_ex = "yr", npp_frac_NH = "—", seas_amp_NH = "GtC/yr",
              seas_amp_SH = "GtC/yr", seas_phase_NH = "month",
              seas_phase_SH = "month", gamma_enso = "GtC/yr per index unit",
              tau_soil = "yr", bomb_total = "kmol", sigma_co2 = "ppm",
              sigma_d13c = "‰", sigma_d14c = "‰")
    v <- vapply(nm, function(n) {
      x <- APP_PARAMS[[n]]
      if (is.null(x)) NA_real_ else as.numeric(x)
    }, numeric(1))
    data.frame(Parameter = unname(desc[nm]),
               Value = ifelse(is.na(v), "—", formatC(v, digits = 3, format = "g")),
               Units = unname(unit[nm]), check.names = FALSE)
  }, striped = TRUE, width = "100%")

  output$h_data <- renderTable({
    data.frame(
      Record = c("Mauna Loa CO₂", "South Pole CO₂", "Law Dome ice cores",
                 "Mauna Loa & South Pole δ¹³C", "Zonal Δ¹⁴C (Hua et al. 2022)",
                 "IntCal20 tree-ring Δ¹⁴C", "Global Carbon Budget 2025",
                 "IGCC temperature"),
      Covers = c("1958–present", "1975–present", "1700–1978", "1977–2024",
                 "1941–2019", "1750–1950", "1959–2024", "1850–2024"),
      `Used for` = c("CO₂ level and seasonal cycle", "Southern CO₂ level",
                     "Preindustrial CO₂", "The fossil fingerprint",
                     "Ocean and land uptake speed", "Preindustrial ¹⁴C decline",
                     "Splitting land from ocean uptake", "Driving the carbon cycle"),
      check.names = FALSE)
  }, striped = TRUE, width = "100%")
}

`%||%` <- function(a, b) if (is.null(a)) b else a
