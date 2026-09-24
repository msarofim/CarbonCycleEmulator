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

# ⛔ THIS HELPER MUST BE DEFINED **BEFORE** THE SERVER FUNCTION, AND THE SERVER
# FUNCTION MUST BE THE LAST TOP-LEVEL EXPRESSION IN THIS FILE.
#
# Shiny's two-file app style takes `source("server.R")$value` -- the value of the
# LAST top-level expression -- as the server. `%||%` used to sit at the BOTTOM of
# this file, so Shiny received a two-argument helper instead of the server and
# every session died with
#     Error in server(...) : unused arguments (input = ..., output = ...)
# before a single output rendered. The UI still built, the banner still showed,
# and every plot was simply blank -- which reads as "slow" or "empty data", not
# as a crash. Found 2026-09-22 by actually opening the app in a browser; the
# smoke tests up to then had sourced global.R and never run a session.
# test-review-cards.R now asserts this file's last value takes
# (input, output, session), and mutation-tests that assertion.
`%||%` <- function(a, b) if (is.null(a)) b else a

function(input, output, session) {

  # fmt_gtc() moved to app/R/plots.R (2026-09-08g): the diagram function needs it too
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
    # ⚠ WHAT THIS SENTENCE MAY NOT SAY (Marcus 2026-09-22, review K1/K2). It
    # read "Given only emissions ... Nothing here was tuned to the shape of this
    # curve", and both halves were false. The model is driven by emissions AND
    # global temperature AND an ENSO index AND volcanic aerosol, all prescribed;
    # and the CO₂ level and seasonal cycle at BOTH stations are rows of the
    # objective, so this curve is among the things the calibration was scored
    # against. The honest claim is narrower and still worth making: what the
    # model is not told is how the carbon DIVIDES between air, land and ocean.
    sprintf(paste("The model produces %.0f ppm in %d, rising to %.0f ppm today;",
                  "the measured value is about %.0f ppm. The model's inputs are",
                  "emissions, global temperature, an ENSO index and volcanic aerosol,",
                  "and its calibration data include the CO₂ level and",
                  "seasonal cycle at both Mauna Loa and the South Pole. But it is",
                  "not an abstract regression: it can only adjust quantities that",
                  "stand for physical things. And what it is never told is how",
                  "the emitted carbon divides between air, land and ocean —",
                  "that comes out of the bookkeeping, and it is the next tab."),
            o$co2_NH[i0], floor(o$t[i0]), o$co2_NH[i1], last_obs)
  })

  # ---- 2. Where does it go -------------------------------------------
  hist_F <- reactive({
    app_build_forcing("historical", APP_HIST_YEARS, prod_c14 = APP_SPIN$prod_c14)
  })
  partition <- reactive(partition_table(APP_HIST$out, hist_F()))

  output$w_partition <- renderPlot(plot_partition(partition(), input$w_years))
  output$w_af  <- renderPlot(plot_airborne_fraction(partition(), input$w_years))
  output$w_gcb <- renderPlot(plot_gcb_bars(APP_HIST$out, APP_GCB, hist_F()))

  latest <- reactive({
    pt <- partition()
    pt[nrow(pt), ]
  })
  output$w_atm   <- renderText(fmt_gtc(latest()$atmosphere))
  output$w_land  <- renderText(fmt_gtc(latest()$land))
  output$w_ocean <- renderText(fmt_gtc(latest()$ocean))

  # Marcus 2026-09-22 (W1): report each box, do not editorialise. The closure
  # is stated because this panel's whole claim is that the three add up --
  # and until 09-22 they did not (see partition_table()).
  output$w_takeaway <- renderText({
    d <- latest()
    s <- d$atmosphere + d$land + d$ocean
    sprintf(paste("Of the %s of carbon emitted since 1750, %s is still in the",
                  "air, %s is in the land and %s is in the ocean — %s, %s and",
                  "%s of the total. The three add back to %s."),
            fmt_gtc(d$emitted), fmt_gtc(d$atmosphere), fmt_gtc(d$land),
            fmt_gtc(d$ocean), fmt_pct(d$atmosphere / d$emitted),
            fmt_pct(d$land / d$emitted), fmt_pct(d$ocean / d$emitted),
            fmt_gtc(s))
  })

  # W2 (Marcus 2026-09-22), COMPUTED. He asked for a note that deforestation
  # added to emissions up to some date and was a net sink after. ⚠ IT NEVER IS:
  # land-use emissions are positive in every year of this driver. What crosses
  # is the LAND AS A WHOLE. Both crossings are computed here -- the model's and
  # the measured one -- because the difference between them is itself the
  # honest disclosure (this model's land sink runs high against GCB, which is
  # what gate 7 scores at z +1.36).
  output$w_luc_note <- renderText({
    k <- APP_LUC_SMOOTH_YR
    cross <- function(year, v) {
      sm <- stats::filter(v, rep(1 / k, k), sides = 2)
      i <- which(!is.na(sm) & sm > 0)
      if (!length(i)) return(NA_integer_)
      # the FIRST year of the smoothable record is not a crossing -- it only
      # means the series was already positive when the record began
      if (i[1] == which(!is.na(sm))[1]) return(NA_integer_)
      year[i[1]]
    }
    pt <- partition()
    a <- stats::aggregate(list(g = pt$land_gross), list(year = floor(pt$t)), mean)
    mod <- cross(a$year[-1], diff(a$g))
    obs <- cross(APP_GCB$year, APP_GCB$land_sink - APP_GCB$luc)
    paste(
      sprintf(paste("Land-use change \u2014 agriculture, deforestation and the rest",
                    "\u2014 has been an emission SOURCE for the whole of this record.",
                    "What changed is the land as a whole: the natural land sink",
                    "grew until it outweighed those emissions, through CO\u2082",
                    "fertilisation and forest regrowth on former farmland.")),
      if (is.na(obs)) "" else
        sprintf(paste("In the measured budget the land crossed from a net source",
                      "to a net sink around %d (%d-year average)."), obs, k),
      if (is.na(mod)) "" else
        sprintf(paste("This model crosses around %d \u2014 %s than the measurements,",
                      "which is one of the places it runs a larger land sink than",
                      "the Global Carbon Budget does."),
                mod, if (!is.na(obs) && mod < obs) "earlier" else "later"))
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

  # C2 (Marcus 2026-09-22). The growth-rate panel, with observations (C1) --
  # the panel that makes the ENSO claim in the blurb checkable (C3).
  output$c_growth <- renderPlot({
    m <- CCX_MECHANISMS[[input$c_mech]]
    plot_growth_rate(APP_HIST$out, cf_run()$out, APP_GCB,
                     input$c_years, paste("Without:", m$label))
  })

  # MEASURED, not asserted: the scatter each series carries about its own
  # decadal trend. A sentence claiming the wobbles shrink has to be a sentence
  # that would change if they did not.
  #
  # ⛔ ALL THREE ARE MEASURED ON THE SAME YEARS, and the first version of this
  # was not. The model runs from 1750 but GCB's atmospheric growth starts 1959,
  # so a window of 1850-2024 gave the model 174 years and the observation 66 --
  # and the model's pre-1959 growth is small and nearly smooth, which deflated
  # its scatter and flattered the comparison. The window is now the INTERSECTION
  # of the slider and the observed record, and the sentence says which years it
  # used. (The standing like-for-like rule, ~/.claude/CLAUDE.md.)
  output$c_growth_note <- renderText({
    m <- CCX_MECHANISMS[[input$c_mech]]
    yr <- c(max(input$c_years[1], min(APP_GCB$year)),
            min(input$c_years[2], max(APP_GCB$year)))
    if (diff(yr) < 12) return(paste("Choose a window of at least a dozen years",
                                    "inside the measured record to compare the",
                                    "year-to-year scatter."))
    scatter <- function(g) {
      g <- g[g$year >= yr[1] & g$year <= yr[2], ]
      if (nrow(g) < GROWTH_RESID_MIN_YEARS) return(NA_real_)
      stats::sd(stats::residuals(stats::lm(g ~ splines::ns(year, df = 3), data = g)))
    }
    mod_g <- app_annual_growth      # ⛔ ONE definition, shared with the chart (F2)
    a  <- scatter(mod_g(APP_HIST$out))
    b  <- scatter(mod_g(cf_run()$out))
    ob <- scatter(app_obs_growth(APP_GCB))
    if (is.na(a) || is.na(b) || is.na(ob)) return("")
    sprintf(paste("Over %d\u2013%d, the year-to-year scatter about the decadal trend is:",
                  "full model %.2f ppm/yr, without \u201c%s\u201d %.2f (%s),",
                  "and the measured record %.2f."),
            yr[1], yr[2], a, m$label, b,
            if (b < a) sprintf("%.0f %% less", 100 * (1 - b / a))
            else sprintf("%.0f %% more", 100 * (b / a - 1)),
            ob)
  })

  # F2 (Marcus 2026-09-24): "full model minus measured" and "experiment minus
  # measured" \u2014 as NUMBERS ON THIS PANEL, which is what he asked for and what
  # keeps the tab at three charts. Each residual is the vertical gap between two
  # lines already drawn above, so nothing here needs its own alignment.
  #
  # \u26d4 THE WINDOW IS COMPUTED ONCE, HERE, AND HANDED TO BOTH SENTENCES. The
  # scatter note derives the same intersection; if these two ever computed it
  # separately they could disagree about which years they describe while both
  # printed a year range, which is worse than either being wrong alone.
  output$c_growth_resid <- renderText({
    m  <- CCX_MECHANISMS[[input$c_mech]]
    yr <- c(max(input$c_years[1], min(APP_GCB$year)),
            min(input$c_years[2], max(APP_GCB$year)))
    r <- app_growth_residuals(APP_HIST$out, cf_run()$out, APP_GCB, yr)
    if (is.null(r)) return("")
    # \u26a0 THE WORST YEAR IS REPORTED BECAUSE A BIAS/RMS PAIR CANNOT SHOW AN
    # EPISODIC ERROR. "Consistently 0.1 high" and "fine except 1992 and 1998"
    # give nearly the same two numbers, and only the second is a story about
    # volcanoes and El Nino \u2014 which is what this tab is for.
    txt <- sprintf(paste("Against the measured record over the same %d years:",
                         "the full model runs %+.2f ppm/yr on average (typical",
                         "miss %.2f), and its single worst year is %d at %+.2f."),
                   r$full$n, r$full$bias, r$full$rms, r$full$worst_year,
                   r$full$worst)
    if (!is.null(r$alt))
      txt <- paste(txt,
        sprintf(paste("Without \u201c%s\u201d the average becomes %+.2f and the",
                      "typical miss %.2f \u2014 %s."),
                m$label, r$alt$bias, r$alt$rms,
                if (r$alt$rms < r$full$rms)
                  sprintf("%.0f %% closer to the measurements", 100 * (1 - r$alt$rms / r$full$rms))
                else if (r$alt$rms > r$full$rms)
                  sprintf("%.0f %% further from them", 100 * (r$alt$rms / r$full$rms - 1))
                else "no change"))
    txt
  })

  # ---- F1 (Marcus 2026-09-24): the DRIVER panel ----------------------
  # The two panels above draw what the model DID. This one draws what it was
  # TOLD -- and draws it twice, before and after the switch, which is the only
  # place in the app a reader can see that "El Nino off" and "volcanoes off" are
  # two different KINDS of operation. See plot_driver()'s header.
  #
  # \u26d4 IT USES THE COUNTERFACTUAL'S OWN FORCING (`cf_run()$forcing`), not a
  # freshly built one. Re-deriving would put a second forcing on the page beside
  # the run, which is exactly how the futures and historical tabs came to draw
  # different pasts (CHANGELOG 09-22 (x)).
  c_driver <- reactive({
    req(input$c_mech)
    ccx_driver_series(input$c_mech, APP_HIST$forcing, APP_PARAMS,
                      F_off = cf_run()$forcing)
  })

  output$c_driver_ui <- renderUI({
    d <- c_driver()
    if (is.null(d))
      # \u26d4 THE THREE PARAMETER SWITCHES GET A SENTENCE, NOT A CHART. There is
      # no prescribed series behind them, and CO2 in this slot would be a model
      # OUTPUT under a heading that says "driver".
      return(div(class = "caveat",
                 tags$strong("This switch has no driver to show. "),
                 paste("It does not remove an input \u2014 it changes how strongly",
                       "the model responds to carbon it already has. The two",
                       "charts above are where its effect shows up.")))
    tagList(plotOutput("c_driver", height = "260px"),
            textOutput("c_driver_note"))
  })

  output$c_driver <- renderPlot({
    d <- c_driver(); req(d)
    plot_driver(d, input$c_years,
                paste("Without:", CCX_MECHANISMS[[input$c_mech]]$label))
  })

  # MEASURED, not asserted: whether the switch touched the input at all.
  output$c_driver_note <- renderText({
    d <- c_driver(); req(d)
    m <- CCX_MECHANISMS[[input$c_mech]]
    if (isTRUE(d$removes_driver))
      sprintf(paste("Switching off \u201c%s\u201d removes this input: the purple line",
                    "is the driver the counterfactual actually ran with."),
              m$label)
    else
      sprintf(paste("Switching off \u201c%s\u201d does not touch this input \u2014 it is",
                    "identical in both runs, so only one line is drawn. The model",
                    "still receives it and simply stops responding to it."),
              m$label)
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
  # I1 + the like-for-like fix: APP_REP_DC is the offset the likelihood applied,
  # so the solid line is the comparison that was scored (same argument as the
  # Keeling panel's two lines).
  output$i_d13c <- renderPlot(
    plot_d13c(APP_HIST$out, APP_OBS, input$i_years,
              input$i_hemi %||% "both", APP_REP_DC))
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
        app_run_coupled(APP_SPIN, s, APP_FUTURE_YEARS)),
      names(APP_SSPS)[match(input$f_ssps, APP_SSPS)])
  })

  stylised_run <- eventReactive(input$s_go, {
    em <- app_stylised_emissions(input$s_kind, APP_FUTURE_YEARS,
                                 to_zero_year = input$s_zero_year,
                                 rate_pct = input$s_rate,
                                 background = input$s_bg)
    app_run_coupled(APP_SPIN, input$s_bg, APP_FUTURE_YEARS,
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
      # ⚠ BOTH arms carry APP_PULSE_EMIS_METHOD, or the pair would differ by the
      # interpolation as well as by the pulse -- which is the one thing this
      # tab's difference is not allowed to contain.
      base  = app_run_coupled(APP_SPIN, input$p_bg, yrs, input$p_bg,
                              emissions = base_em,
                              interp_method = APP_PULSE_EMIS_METHOD),
      pulse = app_run_coupled(APP_SPIN, input$p_bg, yrs, input$p_bg,
                              emissions = pulse_em,
                              interp_method = APP_PULSE_EMIS_METHOD),
      gtc = input$p_gtc, year = input$p_year)
  })

  output$f_plot <- renderPlot({
    if (identical(input$f_mode, "Pulse lab")) {
      pr <- pulse_runs()
      # F4: the same pair of runs, differenced two ways. Carbon is a SHARE of
      # the pulse; temperature is degrees -- so they cannot share an axis, and
      # the radio picks the panel rather than relabelling one.
      if (identical(input$f_yvar, "gmst"))
        plot_pulse_warming(pr$base$climate, pr$pulse$climate, pr$year, pr$gtc)
      else
        plot_pulse_decay(pr$base$climate, pr$pulse$climate, pr$year, pr$gtc)
    } else if (identical(input$f_mode, "Build your own")) {
      r <- stylised_run()
      runs <- c(future_runs()[1], list(`Your scenario` = r))
      # F5: run 1750-2150, SHOW 1900-2150. The two spans are separate
      # constants; see the note on APP_FUTURE_VIEW in global.R.
      plot_future(runs, input$f_yvar %||% APP_FUTURE_YVAR_DEFAULT,
                  if (identical(input$f_yvar, "gmst")) LAB_TEMP else LAB_CO2,
                  view = APP_FUTURE_VIEW)
    } else {
      plot_future(future_runs(), input$f_yvar,
                  if (identical(input$f_yvar, "gmst")) LAB_TEMP else LAB_CO2,
                  view = APP_FUTURE_VIEW)
    }
  })

  output$f_takeaway <- renderText({
    if (identical(input$f_mode, "Pulse lab")) {
      pr <- pulse_runs()
      cb <- pr$base$climate; cp <- pr$pulse$climate
      ppm <- pr$gtc / ccx_const("GtC_PER_PPM")
      f <- function(y) (cp$co2_ppm[cp$year == y] - cb$co2_ppm[cb$year == y]) / ppm
      dT <- function(y) cp$gmst[cp$year == y] - cb$gmst[cb$year == y]
      y1 <- pr$year + 100; y2 <- min(pr$year + 250, max(cb$year))
      if (identical(input$f_yvar, "gmst")) {
        # ⛔ WHICH ONE OUTLASTS THE OTHER IS MEASURED HERE, NOT ASSERTED.
        # The textbook reading is that the warming holds up while the airborne
        # fraction drains away -- but that is a claim about THIS model's
        # climate module at THIS pulse size, and a sentence stating it
        # unconditionally would go on stating it after a refit moved it. Both
        # decays are normalised to their OWN value at y1, so the comparison is
        # of shapes and the pulse size cancels out of it.
        keep_T <- if (dT(y1) > 0) dT(y2) / dT(y1) else NA_real_
        keep_C <- f(y2) / f(y1)
        tail <- if (is.na(keep_T)) "" else sprintf(
          paste(" Over that stretch the warming keeps %s of its century-later",
                "value and the airborne carbon keeps %s, so the %s is the",
                "longer-lived of the two."),
          fmt_pct(keep_T), fmt_pct(keep_C),
          if (keep_T > keep_C) "warming" else "carbon")
        sprintf(paste0("Release %d GtC in %d and the world is %.2f °C warmer ",
                       "a century later, and %.2f °C warmer after %d years.%s"),
                pr$gtc, pr$year, dT(y1), dT(y2), y2 - pr$year, tail)
      } else {
      sprintf(paste("Release %d GtC in %d and %s of it is still in the air a",
                    "century later; %s after %d years. Carbon dioxide is not a",
                    "pollutant that washes out — a large share of it is",
                    "effectively permanent on any human timescale."),
              pr$gtc, pr$year, fmt_pct(f(y1)), fmt_pct(f(y2)), y2 - pr$year)
      }
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

  # F2 (Marcus 2026-09-22): the second pulse panel. Rendered only in the pulse
  # lab, and only after the user has run one -- pulse_runs() is an eventReactive
  # on the button, so it does not fire on tab entry.
  output$f_partition <- renderPlot({
    req(identical(input$f_mode, "Pulse lab"))
    pr <- pulse_runs()
    plot_pulse_partition(pr$base$out, pr$pulse$out, pr$gtc, pr$year)
  })

  output$f_notes <- renderUI({
    how <- if (identical(input$f_mode, "Pulse lab")) {
      div(class = "caveat",
          tags$strong("How this is computed: "),
          "the model runs twice — once with the pulse and once without, from ",
          "identical starting conditions — and the difference between the two ",
          "is the pulse's effect.")
    } else NULL
    # F5 (2026-09-24): the runs now reach 2150, which puts the stylised "+5 %
    # per year" case 26x outside the range the CO2->forcing curve was fitted
    # over. ccx_run_coupled() has always warned about this to the console; on
    # a tab a student can drive there with one slider, the console is not
    # where the warning belongs. CONDITIONAL -- nothing renders unless a run
    # actually leaves the range. See app_erf_range_note() in global.R.
    cls <- switch(input$f_mode %||% "Scenarios",
                  "Pulse lab"     = list(pulse_runs()$pulse$climate),
                  "Build your own" = list(stylised_run()$climate),
                  lapply(future_runs(), `[[`, "climate"))
    note <- app_erf_range_note(cls)
    if (is.null(note)) how
    else tagList(how, div(class = "caveat",
                          tags$strong("Outside the fitted range: "), note))
  })

  # ---- 6. Under the hood ---------------------------------------------
  # The box diagram. ARROWS CARRY THEIR FLUXES (2026-08-13): unlabelled arrows
  # were the single biggest pedagogical gap in the app -- the entire
  # "CO2 only lasts 5 years" lesson is that photosynthesis and air-sea exchange
  # are ~70 and ~95 GtC/yr while emissions are ~11 and the net imbalance ~5, and
  # an arrow without a number cannot say that. Numbers come from APP_FLUX_NOW
  # (R/fluxes.R), i.e. from the model's own tap, not from a table typed here.
  output$h_diagram <- renderPlot(
    plot_box_diagram(APP_FLUX_NOW, APP_HIST$out[nrow(APP_HIST$out), ], app_params$p))

  # THE LABEL TABLE IS GATED, NOT TYPED HERE (2026-09-22, Marcus review U1).
  # It used to be a `desc`/`unit` pair written inline in this block, last
  # updated in the ~22-name era, so most of the 38 rows printed NA. Both the
  # table and the check that it covers CCX_PARAM_NAMES now live in
  # app/R/params_meta.R, where tests/testthat/test-app-params-table.R can reach
  # them without starting the app.
  #
  # ⚠ THE VALUE SOURCE IS NOT `APP_PARAMS` ALONE. Three fitted names have no
  # slot in ccx_default_params() and are carried separately by global.R --
  # `bomb_total` and `luc_scale` are FORCING parameters the app applies through
  # app_build_forcing(), and `rep_dC` is the station offset the likelihood
  # scored through. All three have a fitted value this app is running on, so
  # printing them as "—" would understate what is known. The remaining
  # likelihood-only names (the gradient offsets, sigma_d14c) genuinely are not
  # carried, and print "—" correctly.
  output$h_params <- renderTable(
    app_param_table(CCX_PARAM_NAMES,
                    c(APP_PARAMS, list(bomb_total = APP_BOMB_TOTAL,
                                       luc_scale  = APP_LUC_SCALE,
                                       rep_dC     = APP_REP_DC))),
    striped = TRUE, width = "100%")

  # ---- 7. Known issues (the beta review) -----------------------------
  # Each panel is rendered ONLY when its tab is visible, which is what keeps the
  # expensive cards (3-6, each needing a model run the app does not already
  # have) off the startup path. withProgress gives the first view of the tab a
  # reason for the wait instead of a blank panel.
  rv_render <- function(f, label) renderPlot({
    withProgress(message = label, value = NULL, f())
  })
  output$rv_repdc     <- rv_render(rv_plot_repdc,     "Comparing the model with Mauna Loa")
  output$rv_gradient  <- rv_render(rv_plot_gradient,  "Measuring the north-south gradients")
  output$rv_diseq     <- rv_render(rv_plot_diseq,     "Measuring the ocean's isotopic disequilibrium")
  output$rv_variance  <- rv_render(rv_plot_variance,  "Measuring the year-to-year variability")
  output$rv_enso      <- rv_render(rv_plot_enso,      "Running the model with its ENSO mechanisms off")
  output$rv_irf       <- rv_render(rv_plot_irf,       "Releasing a pulse and following it")
  output$rv_partition <- rv_render(rv_plot_partition, "Following the pulse for a thousand years")
  output$rv_control   <- rv_render(rv_plot_control,   "Running the simpler control model")

  # THE STAND-IN LIST IS GENERATED, NOT TYPED. Which names are held, and at what
  # value, is a property of the mode file the app is running; a hand-kept table
  # here would be a second claim about the model that nothing checks.
  # TWO TABLES, BECAUSE THEY ARE TWO LISTS (Marcus 2026-09-22, review N12).
  # The card's prose named the STAND-INS and this table listed the PINS, and
  # the tab presented them as one. The stand-in list is a judgement (RV_SHIMS,
  # sourced to the 09-16 whole-model review and gated); the pin list is read
  # off the mode file. Which stand-ins are currently HELD is computed.
  output$rv_standins <- renderTable({
    x <- rv_stand_ins()
    if (rv_failed(x) || !length(x$shims))
      return(data.frame(Note = "The stand-in list is unavailable in this build."))
    if (length(x$shim_problems))
      return(data.frame(Problem = c("The stand-in list does not match this build.",
                                    x$shim_problems), check.names = FALSE))
    held <- names(x$shims) %in% x$shims_held
    data.frame(`Stand-in` = names(x$shims),
               `What it stands in for` = unlist(x$shims, use.names = FALSE),
               `In this fit` = ifelse(held, "held at a value (below)", "fitted freely"),
               check.names = FALSE)
  }, striped = TRUE, width = "100%")

  output$rv_shims <- renderTable({
    x <- rv_stand_ins()
    if (rv_failed(x) || !length(x$pins))
      return(data.frame(Note = "The held-parameter list is unavailable in this build."))
    data.frame(`Held parameter` = names(x$pins),
               `Held at` = formatC(as.numeric(x$pins), digits = 4, format = "g"),
               `Also a stand-in` = ifelse(names(x$pins) %in% x$shims_held, "yes", ""),
               check.names = FALSE)
  }, striped = TRUE, width = "100%")

  output$rv_constants <- renderUI({
    x <- rv_stand_ins()
    if (rv_failed(x)) return(div(class = "caveat", x$msg))
    tagList(
      p(sprintf(paste("%d of the model's %d physical constants are still marked",
                      "provisional \u2014 their values were inverted through the model,",
                      "or held, rather than traced to a published measurement:"),
                length(x$provisional), x$n_constants)),
      p(tags$code(paste(x$provisional, collapse = ", "))),
      if (!is.na(x$n_fitted))
        p(tags$small(sprintf(paste("The running fit has %d free parameters;",
                                   "the held names are listed above."), x$n_fitted))))
  })

  # TWO TABLES, NOT ONE (Marcus 2026-09-22, review U2). IGCC temperature sat in
  # "What it is fitted to", which is wrong in the direction that matters: it is
  # PRESCRIBED forcing, and listing a driver as a target overstates what the
  # model derives for itself. Historical land-use change is a driver too. The
  # split is also what makes the Keeling tab's corrected takeaway checkable --
  # a reader can see the driver list it refers to.
  output$h_drivers <- renderTable({
    data.frame(
      Driver = c("Fossil CO\u2082 emissions", "Land-use change CO\u2082",
                 "Global mean temperature", "El Ni\u00f1o index (Ni\u00f1o 3.4)",
                 "Volcanic aerosol", "Bomb and industrial \u00b9\u2074C"),
      Covers = c("1750\u20132024", "1750\u20132024", "1850\u20132024",
                 "1948\u2013present", "1850\u20132024", "1952\u20132023"),
      Source = c("Global Carbon Budget 2025",
                 "Global Carbon Budget 2025 (OSCAR v3.1 before 1850)",
                 "IGCC", "NOAA PSL",
                 "NASA GISS, CMIP7 stratospheric aerosol",
                 "Tans (1981) / Naegler & Levin (2006); Laemmel et al. 2025"),
      check.names = FALSE)
  }, striped = TRUE, width = "100%")

  output$h_data <- renderTable({
    data.frame(
      Record = c("Mauna Loa CO\u2082", "South Pole CO\u2082", "Law Dome ice cores",
                 "Mauna Loa & South Pole \u03b4\u00b9\u00b3C", "Zonal \u0394\u00b9\u2074C (Hua et al. 2022)",
                 "IntCal20 tree-ring \u0394\u00b9\u2074C", "Global Carbon Budget 2025",
                 "GLODAPv2.2023 ocean bottles"),
      Covers = c("1958\u2013present", "1975\u2013present", "1700\u20131978", "1977\u20132024",
                 "1941\u20132019", "1750\u20131950", "1959\u20132024", "depth climatology"),
      `Used for` = c("CO\u2082 level and seasonal cycle", "Southern CO\u2082 level",
                     "Preindustrial CO\u2082", "The fossil fingerprint",
                     "Ocean and land uptake speed", "Preindustrial \u00b9\u2074C decline",
                     "Splitting land from ocean uptake",
                     "The ocean's interior carbon and \u03b4\u00b9\u00b3C"),
      check.names = FALSE)
  }, striped = TRUE, width = "100%")
}

