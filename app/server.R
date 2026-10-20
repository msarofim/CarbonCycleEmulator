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
  # The FaIR checkbox serves the Scenarios overlay and the pulse lab's 100 GtC pulse; its label says which (2026-10-15).
  observeEvent(input$f_mode, updateCheckboxInput(session, "f_fair", label = app_fair_check_label(input$f_mode)),
               ignoreInit = TRUE)

  # fmt_gtc() moved to app/R/plots.R (2026-09-08g): the diagram function needs it too
  fmt_pct <- function(x) sprintf("%.0f%%", 100 * x)

  # ---- RESPONSIVE TEXT WRAPPING (2026-09-25 c) ----------------------
  # ⭐⭐ Captions and subtitles are wrapped to a PIXEL budget, and until now that
  # budget was the FLOOR -- the narrowest layout the app supports -- so they were
  # correct everywhere and needlessly tall on a wide screen. Shiny knows the width
  # each plot was actually given, and re-runs a renderPlot when its size changes,
  # so the real width can be published for the duration of one render.
  # ⚠ READING clientData IS WHAT MAKES IT RESPONSIVE: it is reactive, so a resize
  # re-runs the render with the new width and the caption re-wraps.
  # ⚠ The width is CLEARED on exit, so anything rendering outside a plot -- and
  # the figure scripts and the test suite, which have no session at all -- falls
  # back to the floor rather than inheriting whatever the last plot happened to be.
  # ⛔ The id is passed EXPLICITLY and gated: `renderPlotFit("x", ...)` assigned to
  # `output$y` would silently wrap to another panel's width, which is the
  # caption-sync bug class with a new face. test-plot-text-fits.R asserts every id
  # matches its output.
  # `height` (2026-10-15): the box diagram's height FOLLOWS its width, so the diagram keeps one shape and its
  # text scales with it (plot_box_diagram's `scale`); every other plot keeps renderPlot's default ("auto").
  renderPlotFit <- function(id, expr, env = parent.frame(), quoted = FALSE, height = "auto") {
    fn <- shiny::exprToFunction(expr, env, quoted)
    shiny::renderPlot({
      app_set_panel_px(session$clientData[[paste0("output_", id, "_width")]])
      on.exit(app_clear_panel_px(), add = TRUE)
      fn()
    }, height = height)
  }

  # ---- 1. Keeling ----------------------------------------------------
  output$k_plot <- renderPlotFit("k_plot", 
    plot_keeling(APP_HIST$out, APP_OBS, input$k_years, input$k_hemi, input$k_obs))

  output$k_seasonal <- renderPlotFit("k_seasonal", plot_seasonal(APP_HIST$out, APP_OBS))

  output$k_takeaway <- renderText({
    # 2026-10-12 code review: the three numbers come from app_keeling_numbers() (global.R) -- the
    # scored line, calendar-year means, the observations over the run's own last year. It was
    # which.min(abs(t - 1958)) (a tie that picked December 1957), one December of the raw box, and
    # a typed `year >= 2023` window running past the run's end.
    kn <- app_keeling_numbers(APP_HIST$out, APP_OBS$co2[APP_OBS$co2$station == "MLO", ], APP_REP_DC)
    # ⚠ WHAT THIS SENTENCE MAY NOT SAY (Marcus 2026-09-22, review K1/K2). It
    # read "Given only emissions ... Nothing here was tuned to the shape of this
    # curve", and both halves were false. The model is driven by emissions AND
    # global temperature AND an ENSO index AND volcanic aerosol, all prescribed;
    # and the CO₂ level and seasonal cycle at BOTH stations are rows of the
    # objective, so this curve is among the things the calibration was scored
    # against. The honest claim is narrower and still worth making: what the
    # model is not told is how the carbon DIVIDES between air, land and ocean.
    # A7 (Marcus 2026-10-01, "add N deposition as a driver"): nitrogen
    # deposition has been a prescribed input since hilda33d (data/forcing_ndep.rds,
    # the NOx + NH3 emissions proxy); the list omitted it. The same driver is a
    # row of the "What drives the model" table (output$h_drivers).
    # Marcus 2026-10-15 ("Apply all the app text suggestions"): the quantity and the year are named ("today" read against What-if's 425)
    sprintf(paste("At Mauna Loa, the model produces %.0f ppm in %d, rising to %.0f ppm in %d;",
                  "the measured value is about %.0f ppm. The model's inputs are",
                  # Marcus 2026-10-02 (carbotopecomment): "volcanic aerosol light diffusion",
                  # and the "what it is never told ... the next tab" sentence deleted.
                  "emissions, global temperature, an ENSO index, volcanic aerosol",
                  "light diffusion and nitrogen deposition, and its calibration data include the CO₂ level and",
                  "seasonal cycle at both Mauna Loa and the South Pole. But it is",
                  # Marcus 2026-10-11 (CarboTopecomments.10.11.26): "it only adjusts", verbatim.
                  "not an abstract regression: it only adjusts quantities that",
                  "stand for physical things."),
            kn$start, kn$start_year, kn$now, kn$now_year, kn$obs_now)
  })

  # ---- 2. Where does it go -------------------------------------------
  hist_F <- reactive({
    app_build_forcing("historical", APP_HIST_YEARS, prod_c14 = APP_SPIN$prod_c14)
  })
  partition <- reactive(partition_table(APP_HIST$out, hist_F()))

  output$w_partition <- renderPlotFit("w_partition", plot_partition(partition(), input$w_years))
  output$w_af  <- renderPlotFit("w_af", plot_airborne_fraction(partition(), input$w_years))
  output$w_gcb <- renderPlotFit("w_gcb", plot_gcb_bars(APP_HIST$out, APP_GCB, hist_F()))

  latest <- reactive({
    pt <- partition()
    pt[nrow(pt), ]
  })
  output$w_atm   <- renderText(fmt_gtc(latest()$atmosphere))
  output$w_land  <- renderText(fmt_gtc(latest()$land))
  output$w_ocean <- renderText(fmt_gtc(latest()$ocean))

  # Marcus 2026-09-22 (W1): report each box, do not editorialize. The closure
  # is stated because this panel's whole claim is that the three add up --
  # and until 09-22 they did not (see partition_table()).
  output$w_takeaway <- renderText({
    d <- latest()
    s <- d$atmosphere + d$land + d$ocean
    # 2026-10-15 review: "%s is in the land" -> the land SINK (GCB convention, partition_table()), with the
    # clearing it is net of; both numbers from the same row. The land as a stock gained far less.
    sprintf(paste("Of the %s of carbon emitted since 1750, %s is still in the",
                  "air, %s was taken up by the land sink (while land clearing released %s",
                  "from it) and %s is in the ocean — %s, %s and",
                  "%s of the total."),   # "The three add back to ..." cut, Marcus 2026-10-15 ("Apply all the app text suggestions")
            fmt_gtc(d$emitted), fmt_gtc(d$atmosphere), fmt_gtc(d$land), fmt_gtc(d$cum_luc),
            fmt_gtc(d$ocean), fmt_pct(d$atmosphere / d$emitted),
            fmt_pct(d$land / d$emitted), fmt_pct(d$ocean / d$emitted))
  })

  # W2 (Marcus 2026-09-22), COMPUTED. He asked for a note that deforestation
  # added to emissions up to some date and was a net sink after. /!\ IT NEVER IS:
  # land-use emissions are positive in every year of this driver. What crosses
  # is the LAND AS A WHOLE. Both crossings are computed here -- the model's and
  # the measured one -- because the difference between them is itself the
  # honest disclosure.
  #
  # /!\ REWRITTEN 2026-09-24 (p), and both changes are CORRECTIONS OF FACT, not
  # of style:
  #
  #   1. It used to credit the sink's growth to "CO2 fertilization AND FOREST
  #      REGROWTH on former farmland". In GCB's accounting -- and in this model
  #      -- regrowth is netted INSIDE the land-use input, not inside the natural
  #      sink, and CO2 fertilization is this model's ONLY long-term land-uptake
  #      term ([[ccx_land_sink_single_term]]) -- ⚠ true then, NOT since hilda33d
  #      (2026-10-01), which adds N-deposition retention; the "single cause"
  #      sentence below was deleted for that reason. The old sentence attributed the
  #      sink to a mechanism the model does not contain. It was harmless until
  #      09-24 (n) drew regrowth on this very tab, at which point the page
  #      contradicted itself.
  #   2. Its last sentence left "runs a larger land sink than GCB" standing as
  #      an unqualified fault, and the panel immediately below now says a larger
  #      sink is the one that CLOSES GCB's budget (the imbalance is positive).
  #      The clause that reconciles them points at that panel.
  #
  # /!\ Both cross-references quote a heading by NAME, from the SHARED constant
  # in global.R -- never retyped here, or renaming a heading would silently
  # leave this text pointing at nothing.
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
    # 2026-10-12 code review: the model's net land flux on CALENDAR-YEAR boundaries, from
    # app_sinks_annual() -- the construction GCB's numbers (and this tab's other two panels) use. It
    # diffed annual MEANS of the land stock, a half-year offset (printed 1970; calendar years 1969).
    ann <- app_sinks_annual(APP_HIST$out, hist_F())
    mod <- cross(ann$yr, ann$land_net)
    obs <- cross(APP_GCB$year, APP_GCB$land_sink - APP_GCB$luc)
    # Marcus 2026-10-02 (carbotopecomment), his paragraph. The two years stay COMPUTED, by the
    # same 11-year rule as before (1989 GCB / 1969 model at hilda33d); a missing one drops its
    # clause rather than printing NA. "Carbon fertilization" is written in the app's own term.
    lead <- paste("Land-use change (agriculture, deforestation, and so forth) has been a net",
                  "source to the atmosphere for the whole record. However, over time the",
                  "natural land sink has been growing due to CO₂ fertilization")
    see <- sprintf("see “%s” below", APP_IMBALANCE_HEADING)
    when <- if (!is.na(obs) && !is.na(mod))
      sprintf(paste(", and so the total land contribution switched from a net source to a",
                    "net sink around %d (based on the Global Carbon Budget, GCB) or in %d",
                    "(based on our model — %s)."), obs, mod, see)
    else if (!is.na(obs))
      sprintf(paste(", and so the total land contribution switched from a net source to a",
                    "net sink around %d (based on the Global Carbon Budget, GCB)."), obs)
    else if (!is.na(mod))
      sprintf(paste(", and so the total land contribution switched from a net source to a",
                    "net sink in %d (based on our model — %s)."), mod, see)
    else "."
    paste0(lead, when)
  })

  # ---- THE IMBALANCE BAND (handoff 09-24 e item 3) ------------------
  # /!\ THE WHOLE PANEL TURNS ON A SIGN. GCB's imbalance is POSITIVE, which
  # means its own sinks are too SMALL to close its budget -- so a LARGER model
  # sink moves TOWARD closure, not away from it. "Above GCB" is not "too high",
  # and the takeaway below states the direction rather than leaving a reader to
  # assume the usual one.
  #
  # /!\ AND THE CONTAINMENT IS COMPUTED, NOT DESCRIBED. 09-24 (k) drew this for
  # print and its first reading was "inside the band for most of the record",
  # which the numbers corrected to 4 of 7 decades. A sentence a reader could
  # check against the chart has to be produced by the same arithmetic the chart
  # is.
  imbalance_dec <- reactive(app_imbalance_decades(APP_HIST$out, APP_GCB, hist_F()))
  # \u26d4 THE DECOMPOSITION IS COMPUTED, LIKE THE CONTAINMENT ABOVE IT
  # (2026-09-25). The info box below used to TYPE "about 0.3 GtC" and name three
  # of the five terms, on the panel whose own takeaway computes its numbers --
  # and the typed value had already drifted from the +0.32 the decomposition
  # gives. Same reactive inputs as the containment, so the box and the chart
  # cannot describe different runs.
  imbalance_id <- reactive(app_imbalance_identity(APP_HIST$out, APP_GCB, hist_F()))

  output$w_imbalance_ui <- renderUI({
    tagList(
      takeaway(textOutput("w_imbalance_takeaway", inline = TRUE)),
      plotOutput("w_imbalance_plot", height = "330px"),
      div(class = "caveat", tags$strong("What the band is: "), IMB_BAND_NOTE),
      # Marcus 2026-10-11: the tab said GCB's budget does not add up three times, "we probably
      # only need two". This box's first paragraph ("The leftover carbon in the measured budget is
      # positive ...") was cut: it restated his own paragraph under APP_IMBALANCE_HEADING (ui.R),
      # and the band note (IMB_BAND_NOTE) is the other one kept.
      info_box("Why a bigger sink can be the closer one",
               p(local({
                 z <- imbalance_id()
                 # \u26a0 THE WORD CARRIES THE SIGN, so the magnitudes print
                 # unsigned after "plus"/"less" -- a signed "-0.30" after "less"
                 # reads as a double negative. The two small terms keep their
                 # signs because no word orders them.
                 a <- function(v) sprintf("%.2f", abs(v))
                 # 2026-10-15 review: it said "no remainder at all ... exactly ... Nothing is left
                 # unexplained" while printing the remainder (0.007 GtC/yr at hilda31w).
                 sprintf(paste("Taking the whole gap apart accounts for almost all of it. Against",
                               "the measured budget this model's land sink runs about %s GtC",
                               "a year high over %d\u2013%d, and that is almost exactly the budget's",
                               "leftover carbon (%s), plus a cement sink this model does not",
                               "have (%s), less the fitted land-use scaling (%s) \u2014 with the",
                               "model's growth and ocean differences adding %+.2f and %+.2f.",
                               "The terms leave a remainder of %.3f GtC a year,",
                               "about %.0f%% of the gap they account for."),
                         a(z$d_land), z$window[1], z$window[2],
                         a(z$imbal), a(z$cement), a(z$d_luc),
                         -z$d_grow, -z$d_ocn,
                         abs(z$closure), 100 * abs(z$closure / z$d_land))
               })))
               # 2026-10-02: "The one place the model really does sit outside the band is the
               # last few years" DELETED -- false at hilda33d, where the 1980s are outside too
               # (model 2.13 vs band top 1.71 GtC/yr); the takeaway above now counts them.
    )
  })

  output$w_imbalance_plot <- renderPlotFit("w_imbalance_plot", 
    plot_land_sink_imbalance(APP_HIST$out, APP_GCB, hist_F()))

  output$w_imbalance_takeaway <- renderText({
    s <- imbalance_dec()
    inb  <- sum(s$in_band); n <- nrow(s)
    # Marcus 2026-10-02 (carbotopecomment), his three sentences. Both counts are COMPUTED and
    # counted SEPARATELY ("inside the band" needs model >= GCB as well; at hilda33d they agree,
    # 5 of 7), and "takes up more than the GCB estimate" is only asserted while it is true of
    # every decade.
    above   <- sum(s$model > s$obs)
    exceeds <- sum(s$obs + s$imbal > s$model)
    # Marcus 2026-10-15 ("Apply all the app text suggestions"): the "sits inside the band in N of M decades" sentence cut -- while the
    # model is above GCB in every decade it states the third sentence again.
    sprintf(paste("The model takes up more carbon than the GCB estimate%s.",
                  "When the budget imbalance is added to the GCB estimate, it exceeds the",
                  "model estimate in %d out of %d decades on this chart."),
            if (above == n) "" else sprintf(" in %d of %d decades", above, n), exceeds, n)
  })

  # ---- REGROWTH TIER 1 (Marcus 2026-09-24) --------------------------
  # ⭐⭐ The whole section renders through uiOutput rather than plotOutput so a
  # checkout without data/forcing_luc_gross_split.rds says what is missing
  # instead of drawing an empty panel. ⛔ AND THE TWO SENTENCES THAT CANNOT BE
  # DROPPED are both here: the split is ASSERTED from GCB's bookkeeping models
  # and not measured by this model, and the future half of the curve is a
  # prescribed decay. Those are not hedges, they are what the number IS.
  output$w_regrowth_ui <- renderUI({
    if (is.null(APP_LUC_SPLIT))
      return(div(class = "caveat",
                 "The land-use split is not built in this checkout — run",
                 tags$code("Rscript data-raw/build_luc_gross_split.R"), "."))
    h   <- APP_LUC_SPLIT$historical
    obs <- APP_LUC_SPLIT$obs_window
    now <- h[h$year >= obs[2] - 9 & h$year <= obs[2], ]
    tagList(
      fluidRow(
        column(4, div(class = "readout-label", "Deforestation, gross"),
               div(class = "readout", sprintf("%.2f", mean(now$gross_GtC)))),
        column(4, div(class = "readout-label", "Forest regrowth"),
               div(class = "readout", sprintf("%.2f", mean(now$regrowth_GtC)))),
        # 2026-10-15 review: "what the model burns" -> it is a net land-use INPUT, not something burned
        column(4, div(class = "readout-label", "Net, the land-use input the model is given"),
               div(class = "readout", sprintf("%.2f", mean(now$net_GtC))))
      ),
      div(class = "readout-label",
          sprintf("GtC per year, %d–%d average", min(now$year), max(now$year))),
      br(),
      takeaway(textOutput("w_regrowth_takeaway", inline = TRUE)),
      plotOutput("w_regrowth_plot", height = "330px"),
      div(class = "caveat", tags$strong("Where this number comes from: "),
          textOutput("w_regrowth_caveat", inline = TRUE))
      # Marcus 2026-10-02 (carbotopecomment): the "Why splitting it changes nothing the model
      # does" explainer DELETED. Its one load-bearing fact (the split is the bookkeeping
      # models') is still in APP_LUC_SPLIT_NOTE, the caveat just above -- in Marcus's own
      # wording since 2026-10-02 (carbotopecomments.10.2.26).
    )
  })

  # ⛔ FOUND 2026-10-11 by the all-controls sweep (Marcus: "check all combinations and
  # perturbations"): a "Years shown" window that ends before the split is observed
  # (e.g. 1750-1751) left the chart no rows and it crashed ("arguments imply differing
  # number of rows: 0, 1"). validate() rather than stop(): its message survives the
  # error sanitizing a deployed app applies.
  output$w_regrowth_plot <- renderPlotFit("w_regrowth_plot", {
    validate(need(input$w_years[2] >= APP_LUC_SPLIT$obs_window[1],
                  sprintf(paste("The deforestation and regrowth estimates begin in %d.",
                                "Move the end of “Years shown” to %d or later to see them."),
                          APP_LUC_SPLIT$obs_window[1], APP_LUC_SPLIT$obs_window[1])))
    plot_luc_gross_split(APP_LUC_SPLIT, input$w_years)
  })

  # /!\ THE LAST SENTENCE IS MEASURED, NOT ASSERTED. Which half moved is the
  # interesting fact -- the net land-use flux has fallen while gross clearing
  # has not -- but "clearing is flat and regrowth is rising" is a DIRECTIONAL
  # claim, so it is read off the two trends rather than typed. A GCB revision
  # that flips either one flips the sentence with it.
  output$w_regrowth_takeaway <- renderText({
    h   <- APP_LUC_SPLIT$historical
    obs <- APP_LUC_SPLIT$obs_window
    now <- h[h$year >= obs[2] - 9 & h$year <= obs[2], ]
    all <- h[h$year >= obs[1] & h$year <= obs[2], ]
    frac  <- function(d) -sum(d$regrowth_GtC) / sum(d$gross_GtC)
    s_reg <- unname(stats::coef(stats::lm(-all$regrowth_GtC ~ all$year))[2]) * 10
    # Marcus 2026-10-02 (carbotopecomment + "Do the roughly level recommended approach"): his
    # sentences, every number COMPUTED. "[YEAR]" became "roughly level" because the observed
    # record has no single peak (highest in 1959, a second maximum ~2011; the lowest decades are
    # the 1980s and the partial 2020s, within 0.1 % of each other). "Roughly level" is only said
    # while the decade means stay within REGROWTH_LEVEL_TOL of their average (at most 6.4 % off
    # at hilda33d, the 2010s; measured 10-02 w); the regrowth clause follows the
    # sign of its trend. ⚠ Not Our World in Data's AREA series, which peaks in the 1980s:
    # these are the bookkeeping models' gross CARBON emissions (CHANGELOG 10-02 w).
    dec <- stats::aggregate(gross_GtC ~ I((year %/% 10) * 10), data = all, FUN = mean)
    n_d <- stats::aggregate(year ~ I((year %/% 10) * 10), data = all, FUN = length)
    dm  <- dec$gross_GtC[n_d$year >= REGROWTH_DECADE_MIN_N]
    level <- max(abs(dm / mean(dm) - 1)) <= REGROWTH_LEVEL_TOL
    # ...and "Add a clause (Recommended)" (Marcus 2026-10-02): the AREA cleared each year peaked
    # in the 1980s -- Our World in Data, "Deforestation and Forest Loss" (H. Ritchie, 2021, minor
    # edits Nov 2024; accessed 2026-10-02): "Global deforestation peaked in the 1980s", from FAO and
    # Williams (2006). A reader comparing that page with this chart would otherwise see a
    # contradiction; the two measure different things (area vs the bookkeeping models' carbon).
    area <- "(in carbon terms; the area of forest cleared each year peaked in the 1980s)"
    lead <- if (level)
      sprintf(paste("Deforestation emissions have stayed roughly level since %d, at about",
                    "%.1f\u2013%.1f GtC a year by decade %s"), obs[1], min(dm), max(dm), area)
    else
      sprintf("Deforestation emissions have ranged from %.1f to %.1f GtC a year by decade since %d %s",
              min(dm), max(dm), obs[1], area)
    sprintf(paste("%s, whereas forest regrowth has %s over time. While over the %d to %d period,",
                  "forest regrowth has compensated for %s of deforestation emissions, in the",
                  "last decade it has compensated for %s (%.2f GtC absorbed/year versus %.2f",
                  "GtC emitted/year)."),
            lead, if (s_reg > 0) "gotten larger" else "not grown",
            obs[1], obs[2], fmt_pct(frac(all)), fmt_pct(frac(now)),
            -mean(now$regrowth_GtC), mean(now$gross_GtC))
  })

  output$w_regrowth_caveat <- renderText(APP_LUC_SPLIT_NOTE)

  # ---- 3. Counterfactuals --------------------------------------------
  # ⭐⭐ MULTI-SELECT since 2026-09-25 (Marcus: "Can we add radio boxes so you can
  # turn off multiple things simultaneously?"). THE ENGINE ALWAYS ALLOWED IT --
  # ccx_apply_mechanisms() takes a VECTOR and folds the switches in order -- and
  # the order does not matter, because the seven switches touch disjoint
  # parameters (beta/beta_max, q10+sst_scale+sst_obs, gamma_enso, gamma_diff,
  # k_w, revelle_frozen) and disjoint forcing columns (aod, the emissions
  # columns). What changed here is the input control and the copy around it,
  # not the model.
  #
  # ⛔⛔ NOTHING IN THIS BLOCK MAY ADD UP THE PER-SWITCH CLAIMS. Each blurb
  # quotes its own switch's effect -- "switch it off and about 40 % of the
  # wobble goes" (hilda34g; "about a quarter" until 2026-10-03) -- and those DO NOT
  # COMPOSE. Measured over 1959-2024 (the figures in R/mechanisms.R's enso entry,
  # at an older mode): ENSO -23 %, temperature -22 %,
  # volcanic light -8 %, but ALL THREE TOGETHER only -43 %, not -53 %. So every
  # number printed below is COMPUTED FROM THE COMBINED RUN, the blurbs are shown
  # labeled and separate so they cannot read as a running total, and with more
  # than one ticked the scatter note says in words that they do not add.
  #
  # ⚠ ZERO SELECTED IS A LEGITIMATE STATE, not an error: it is the full model
  # against the measurements, which is a thing a reader may well want to look at.
  # Every output below handles it rather than req()-ing it away, because a
  # checkbox group can be emptied and a blank tab reads as a broken one.
  cf_off <- reactive(input$c_mech %||% character())

  cf_run <- reactive({
    off <- cf_off()
    if (!length(off)) return(NULL)
    app_run_mechanisms(off, APP_HIST_YEARS, "historical")
  })

  # The counterfactual's output table, or NULL when nothing is switched off.
  # ⛔ ONE accessor, so no panel below can differ about what "no counterfactual"
  # means -- plot_counterfactual() and plot_growth_rate() both take alt = NULL.
  cf_alt <- reactive({ r <- cf_run(); if (is.null(r)) NULL else r$out })

  output$c_plot <- renderPlotFit("c_plot",
    plot_counterfactual(APP_HIST$out, cf_alt(), input$c_years,
                        app_mech_key(cf_off())))

  # One labeled block per ticked switch (Marcus's own fallback for the
  # multi-select: "print more than 1 text box below"). Labeled and separated
  # rather than concatenated -- see the non-additivity warning above.
  output$c_blurb <- renderUI({
    off <- cf_off()
    if (!length(off))
      return(div(style = "margin-top:12px; font-size:0.93rem;",
                 "Nothing is switched off, so the charts show the full model",
                 "against the measurements. Tick one or more boxes to remove",
                 "a mechanism; tick several to remove them together."))
    div(style = "margin-top:12px; font-size:0.93rem;",
        lapply(off, function(n) {
          m <- CCX_MECHANISMS[[n]]
          # 2026-10-15 review: "{n_years}" in a blurb (R/mechanisms.R, which is sourced before APP_HIST_YEARS
          # exists) is the run's own length, filled here -- it read "the same 270 years" for a 275-year run
          tags$p(tags$strong(m$label), tags$br(),
                 gsub("{n_years}", diff(APP_HIST_YEARS) + 1L, m$blurb, fixed = TRUE))
        }))
  })

  # ⚠ THE CAVEATS COME BACK FROM THE RUN, not from a second walk of
  # CCX_MECHANISMS here: ccx_apply_mechanisms() appends one per switch in the
  # order it was given them, so they line up with cf_off() BY CONSTRUCTION. The
  # length check is there because that alignment is an assumption about another
  # file, and an unlabeled list is better than a mislabeled one.
  output$c_caveat <- renderUI({
    off <- cf_off(); r <- cf_run()
    if (is.null(r) || !length(r$caveats)) return(NULL)
    cav <- r$caveats
    body <- if (length(cav) == length(off))
      tags$ul(Map(function(n, cv)
        tags$li(tags$strong(paste0(CCX_MECHANISMS[[n]]$label, ": ")), cv), off, cav))
    else
      paste(cav, collapse = " ")
    div(class = "caveat", body)   # "Worth knowing:" label cut, Marcus 2026-10-15 ("Apply all the app text suggestions")
  })

  # C2 (Marcus 2026-09-22). The growth-rate panel, with observations (C1) --
  # the panel that makes the ENSO claim in the blurb checkable (C3).
  output$c_growth <- renderPlotFit("c_growth",
    plot_growth_rate(APP_HIST$out, cf_alt(), APP_OBS_GROWTH,
                     input$c_years, app_mech_key(cf_off())))

  # ⛔ ONE WINDOW, COMPUTED ONCE, HANDED TO ALL THREE SENTENCES AND THE STRIP.
  # The scatter note, the residual note and the residual chart all describe "the
  # same years"; if they derived the intersection separately they could disagree
  # about which years while all three printed a range, which is worse than any
  # one of them being wrong alone.
  # \u26d4 THE SPAN COMES FROM THE SERIES THAT IS ACTUALLY DRAWN. It read
  # APP_GCB's 1959-2024 until 2026-09-26, while the observed growth is now the
  # NOAA MBL reference starting 1980 -- a window claiming years the observation
  # does not have is the same like-for-like bug one level up.
  cf_obs_span <- reactive({
    o <- app_obs_growth(APP_OBS_GROWTH)
    if (is.null(o)) NULL else range(o$year)
  })
  cf_window <- reactive({
    sp <- cf_obs_span(); if (is.null(sp)) return(input$c_years)
    c(max(input$c_years[1], sp[1]), min(input$c_years[2], sp[2]))
  })

  # MEASURED, not asserted: the scatter each series carries about its own
  # decadal trend. A sentence claiming the wobbles shrink has to be a sentence
  # that would change if they did not.
  #
  # ⛔ ALL SERIES ARE MEASURED ON THE SAME YEARS, and the first version of this
  # was not. The model runs from 1750 but GCB's atmospheric growth starts 1959,
  # so a window of 1850-2024 gave the model 174 years and the observation 66 --
  # and the model's pre-1959 growth is small and nearly smooth, which deflated
  # its scatter and flattered the comparison. The window is the INTERSECTION of
  # the slider and the observed record, and the sentence says which years it
  # used. (The standing like-for-like rule, ~/.claude/CLAUDE.md.)
  output$c_growth_note <- renderText({
    off <- cf_off()
    yr  <- cf_window()
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
    ob <- scatter(app_obs_growth(APP_OBS_GROWTH))
    if (is.na(a) || is.na(ob)) return("")
    if (!length(off))
      return(sprintf(paste("Over %d–%d, the year-to-year scatter about the",
                           "decadal trend is %.2f ppm/yr in the full model",
                           "against %.2f in the measured record."),
                     yr[1], yr[2], a, ob))
    b <- scatter(mod_g(cf_alt()))
    if (is.na(b)) return("")
    txt <- sprintf(paste("Over %d–%d, the year-to-year scatter about the decadal trend is:",
                         "full model %.2f ppm/yr, without %s %.2f (%s),",
                         "and the measured record %.2f."),
                   yr[1], yr[2], a, app_mech_list(off), b,
                   if (b < a) sprintf("%.0f%% less", 100 * (1 - b / a))
                   else sprintf("%.0f%% more", 100 * (b / a - 1)),
                   ob)
    # ⛔⛔ THE NON-ADDITIVITY WARNING, IN WORDS AND WITHOUT AN INVENTED NUMBER.
    # The per-switch blurbs in the sidebar each quote their own effect, and a
    # reader with three ticked will otherwise add them up. No figure is given
    # here because computing the individual effects would mean N more model runs
    # on every click, and the measured example that IS available lives in
    # R/mechanisms.R's enso entry rather than in this window.
    # Marcus 2026-10-11 (CarboTopecomments.10.11.26): "Change to", verbatim.
    if (length(off) > 1L)
      txt <- paste(txt, paste("The combined figure above includes interactions between",
                              "the different climate effects."))
    txt
  })

  # F2 (Marcus 2026-09-24): "full model minus measured" and "experiment minus
  # measured" — as NUMBERS ON THIS PANEL. Each residual is the vertical gap
  # between two lines already drawn above, so nothing here needs its own
  # alignment. The same residuals are now DRAWN as well (output$c_resid).
  output$c_growth_resid <- renderText({
    off <- cf_off()
    r <- app_growth_residuals(APP_HIST$out, cf_alt(), APP_OBS_GROWTH, cf_window())
    if (is.null(r)) return("")
    # ⚠ THE WORST YEAR IS REPORTED BECAUSE A BIAS/RMS PAIR CANNOT SHOW AN
    # EPISODIC ERROR. "Consistently 0.1 high" and "fine except 1992 and 1998"
    # give nearly the same two numbers, and only the second is a story about
    # volcanoes and El Nino — which is what this tab is for.
    # "Relative to" is Marcus's (2026-10-15); it was "Against".
    txt <- sprintf(paste("Relative to the measured record over the same %d years:",
                         "the full model runs %+.2f ppm/yr on average (typical",
                         "miss %.2f), and its single worst year is %d at %+.2f."),
                   r$full$n, r$full$bias, r$full$rms, r$full$worst_year,
                   r$full$worst)
    if (!is.null(r$alt))
      txt <- paste(txt,
        sprintf(paste("Without %s the average becomes %+.2f and the",
                      "typical miss %.2f — %s."),
                app_mech_list(off), r$alt$bias, r$alt$rms,
                if (r$alt$rms < r$full$rms)
                  # Marcus 2026-10-02: "14% further from the data"; its twin matched
                  sprintf("%.0f%% closer to the data", 100 * (1 - r$alt$rms / r$full$rms))
                else if (r$alt$rms > r$full$rms)
                  sprintf("%.0f%% further from the data", 100 * (r$alt$rms / r$full$rms - 1))
                else "no change"))
    txt
  })

  # ---- THE RESIDUAL STRIP (Marcus 2026-09-25) ------------------------
  # "Is the difference between observed and model added to the 2nd panel
  # possible?" -- yes, and it goes in its OWN strip under the growth chart
  # rather than on its axes. The residuals are roughly +/-0.5 ppm/yr against a
  # growth rate that runs 0-3, so drawn on the shared axis they would be a flat
  # squiggle along the bottom, colliding with the low end of the data.
  # ⛔ IT SHARES THE GROWTH CHART'S x LIMITS AND ITS WINDOW, and takes the
  # SAME app_annual_growth / app_obs_growth definitions, so the strip cannot
  # come to describe different years or a different estimator from the panel it
  # sits under.
  output$c_resid <- renderPlotFit("c_resid",
    plot_growth_resid(APP_HIST$out, cf_alt(), APP_OBS_GROWTH, cf_window(),
                      app_mech_key(cf_off())))

  # ---- F1 (Marcus 2026-09-24): the DRIVER panel ----------------------
  # The two panels above draw what the model DID. This one draws what it was
  # TOLD -- and draws it twice, before and after the switch, which is the only
  # place in the app a reader can see that "El Nino off" and "volcanoes off" are
  # two different KINDS of operation. See plot_driver()'s header.
  #
  # ⛔ IT USES THE COUNTERFACTUAL'S OWN FORCING (`cf_run()$forcing`), not a
  # freshly built one. Re-deriving would put a second forcing on the page beside
  # the run, which is exactly how the futures and historical tabs came to draw
  # different pasts (CHANGELOG 09-22 (x)).
  #
  # ⭐ ONE CHART PER TICKED SWITCH since the multi-select. Each driver's
  # column is touched by at most its OWN switch (volcanic -> aod, emissions ->
  # the emissions columns, enso -> enso, warming -> gmst; the last two since
  # 2026-10-02, when Marcus ruled that "off" zeroes the index), so handing every panel the combined forcing is not only safe
  # but right: it is the input that run actually received.
  #
  # ⚠ The outputs are declared ONCE HERE, one per switch that has a driver,
  # with the id and the output name the SAME EXPRESSION -- which is a stronger
  # guarantee than the static `output$x <- renderPlotFit("x")` form that
  # test-plot-text-fits.R test 7 greps for, because the two cannot drift apart.
  # That gate cannot see this form; the id is checked here instead.
  for (.nm in names(CCX_MECHANISMS)) local({
    nm <- .nm
    if (is.null(CCX_MECHANISMS[[nm]]$driver)) return(invisible(NULL))
    id <- paste0("c_driver_", nm)
    output[[id]] <- renderPlotFit(id, {
      req(nm %in% cf_off())
      d <- ccx_driver_series(nm, APP_HIST$forcing, APP_PARAMS,
                             F_off = cf_run()$forcing)
      req(!is.null(d))
      plot_driver(d, input$c_years,
                  paste("Without:", CCX_MECHANISMS[[nm]]$label))
    })
  })

  output$c_driver_ui <- renderUI({
    off <- cf_off()
    if (!length(off))
      return(div(class = "caveat",
                 "Nothing is switched off, so there is no before-and-after",
                 "input to draw."))
    has_drv <- vapply(off, function(n) !is.null(CCX_MECHANISMS[[n]]$driver), logical(1))
    withd <- off[has_drv]; nod <- off[!has_drv]
    bits <- list()
    if (length(withd)) {
      fo <- cf_run()$forcing
      bits <- c(bits, lapply(withd, function(n) {
        d <- ccx_driver_series(n, APP_HIST$forcing, APP_PARAMS, F_off = fo)
        # MEASURED, not asserted: whether the switch touched the input at all.
        # 2026-10-15 review: a switch may carry its own `driver_note` (R/mechanisms.R). "Warming's effect" does:
        # its input is drawn as zero, but the world in that run still warms, so "removes this input" misled.
        note <- if (isTRUE(d$removes_driver) && !is.null(CCX_MECHANISMS[[n]]$driver_note))
          CCX_MECHANISMS[[n]]$driver_note
        else if (isTRUE(d$removes_driver))
          sprintf(paste("Switching off “%s” removes this input: the purple",
                        "line is the driver the counterfactual actually ran with."),
                  CCX_MECHANISMS[[n]]$label)
        else
          sprintf(paste("Switching off “%s” does not touch this input — it is",
                        "identical in both runs, so only one line is drawn. The model",
                        "still receives it and simply stops responding to it."),
                  CCX_MECHANISMS[[n]]$label)
        tagList(plotOutput(paste0("c_driver_", n), height = "260px"),
                div(class = "caveat", note))
      }))
    }
    # ⛔ THE PARAMETER SWITCHES GET A SENTENCE, NOT A CHART. There is no
    # prescribed series behind them, and CO2 in this slot would be a model
    # OUTPUT under a heading that says "driver".
    if (length(nod))
      bits <- c(bits, list(div(class = "caveat",
        tags$strong(sprintf("%s %s no driver to show. ", app_mech_list(nod, sentence_start = TRUE),
                            if (length(nod) == 1L) "has" else "have")),
        paste("Switches like this do not remove an input — they change how",
              "strongly the model responds to carbon it already has. The two",
              "charts above are where their effect shows up."))))
    do.call(tagList, bits)
  })

  output$c_takeaway <- renderText({
    off <- cf_off()
    a <- APP_HIST$out
    # 2026-10-15 review: "today" was the run's last MONTH (426 ppm, a December of the raw box) while the Keeling
    # tab's "today" is an annual mean (423); now the last full year's annual mean, and the sentence names it.
    y_now <- max(floor(a$t + 1e-9))
    co2_now <- function(o) app_annual_mean_of(o$t, o$co2_global, y_now)
    if (!length(off))
      return(sprintf(paste("Nothing is switched off: this is the full model, with",
                           "global-average CO₂ at %.0f ppm in %d. Tick a mechanism to see what the",
                           "model does without it."), co2_now(a), y_now))
    b <- cf_alt()
    d <- co2_now(b) - co2_now(a)
    # ⛔⛔ A SWITCH WITH NO EFFECT ON THE LEVEL IS NOT A SWITCH WITH NO EFFECT,
    # and until 2026-09-25 this sentence could not tell the reader apart from
    # the other. Tick El Nino and volcanic haze together and it printed "CO2
    # today would be 425 ppm instead of 425 — a difference of +0 ppm", which
    # reads as "nothing happened". MEASURED in that state: the year-to-year
    # scatter drops 0.27 -> 0.15 ppm/yr (43 % less) and the residual against the
    # record worsens 26 %, with 1991 — Pinatubo — as the worst year. Both
    # switches are interannual by construction, so a level of ~0 is the RIGHT
    # answer and the wrong sentence.
    #
    # ⚠ THE THRESHOLD IS DERIVED FROM THE FORMAT, NOT PICKED. Below half a ppm
    # the "%.0f" above prints "+0", so half a ppm is exactly the point at which
    # the numeric sentence stops saying anything — no hand-chosen tolerance is
    # involved, and changing the format changes the threshold with it.
    if (abs(d) < TAKEAWAY_PPM_RESOLUTION)
      return(sprintf(paste("With %s switched off, global-average CO₂ in %d is unchanged to the",
                           "nearest ppm — these are year-to-year mechanisms, and",
                           "they move the wobble rather than the level. The",
                           "growth-rate chart below is where they show up."),
                     app_mech_list(off), y_now))
    sprintf(paste("With %s switched off, global-average CO₂ in %d would be %.0f ppm instead of",
                  "%.0f — a difference of %s%.0f ppm."),
            app_mech_list(off), y_now, co2_now(b), co2_now(a),
            if (d > 0) "+" else "", d)
  })

  # ---- 4. Isotopes ---------------------------------------------------
  # I1 + the like-for-like fix: APP_REP_DC is the offset the likelihood applied,
  # so the solid line is the comparison that was scored (same argument as the
  # Keeling panel's two lines).
  output$i_d13c <- renderPlotFit("i_d13c", 
    plot_d13c(APP_HIST$out, APP_OBS, input$i_years,
              input$i_hemi %||% "both", APP_REP_DC))
  output$i_d14c <- renderPlotFit("i_d14c", plot_d14c(APP_HIST$out, APP_OBS, input$i_years))

  output$i_takeaway <- renderText({
    o <- APP_HIST$out
    # 2026-10-12 code review: both ends are CALENDAR-YEAR MEANS. `which.min(abs(t - 1850))` tied and
    # took December 1849, against the run's last month; fixing only the tie would have compared a
    # January with a December, across the seasonal cycle.
    d13c_drop <- app_annual_mean_of(o$t, o$d13c_NH, 1850) -
                 app_annual_mean_of(o$t, o$d13c_NH, max(floor(o$t + 1e-9)))
    ip <- which.max(o$d14c_NH)
    # 2026-10-15 review: the fall was credited to fossil carbon only; land-use carbon is ¹³C-poor plant carbon too
    sprintf(paste("δ¹³C has fallen %.2f‰ since 1850 as fossil and land-use carbon (both originally",
                  "from plants) diluted the air — the fingerprint that the extra CO₂ is fossil and",
                  "land-use carbon. Δ¹⁴C tells",
                  "a different story: weapons testing %s by %d, and",
                  # Marcus 2026-10-02 (carbotopecomment), his wording
                  "the rate at which it declines provides information about the",
                  "speed of carbon exchange between pools."),
            d13c_drop,
            # Marcus 2026-10-15 ("Apply all the app text suggestions"): what nearly doubled is the air's carbon-14, not Δ¹⁴C (≈0 -> +900‰)
            if (o$d14c_NH[ip] > 500) "nearly doubled the air's carbon-14" else "sent it spiking",
            floor(o$t[ip]))
  })

  # ---- 5. Futures ----------------------------------------------------
  future_runs <- reactive({
    req(input$f_scen)
    stats::setNames(
      lapply(input$f_scen, function(s)
        app_run_coupled(APP_SPIN, s, APP_FUTURE_YEARS)),
      names(APP_SCENARIOS)[match(input$f_scen, APP_SCENARIOS)])
  })

  # ⛔ THE PATHWAY THE LAST RUN USED, captured HERE and not read from the
  # slider later. The readout below describes the executed run; reading
  # `input$s_kind` at render time would let the sentence change while the two
  # numbers beside it stayed on the previous pathway.
  # ⭐ THE TAKEAWAY MUST DESCRIBE THE RUN THE USER PRESSED, not the sliders as
  # they now sit. `s_kind` was captured this way on 09-25 for exactly that
  # reason; 09-26 extends it to the RATE, the zero year and the emissions
  # pathway itself, because the rewritten takeaway quotes numbers off them. A
  # reader who drags the rate slider without pressing "Run it" would otherwise
  # watch the sentence change underneath two numbers that did not move.
  stylised_spec <- reactiveVal(NULL)
  stylised_run <- eventReactive(input$s_go, {
    em <- app_stylised_emissions(input$s_kind, APP_FUTURE_YEARS,
                                 to_zero_year = input$s_zero_year,
                                 rate_pct = input$s_rate,
                                 background = input$s_bg)
    stylised_spec(list(kind = input$s_kind, rate_pct = input$s_rate,
                       to_zero_year = input$s_zero_year, emissions = em))
    app_run_coupled(APP_SPIN, input$s_bg, APP_FUTURE_YEARS,
                    nonco2_scenario = input$s_bg, emissions = em)
  })

  # The comparison line for "Build your own" is the scenario "Everything else follows" names (Marcus 2026-10-15,
  # comments 10.15.26b: "the 2nd scenario should be the 'everything else follows' scenario"). It used to be the
  # FIRST scenario ticked on the Scenarios tab, which the Build-your-own panel never shows. Captured at the press,
  # like the run it is drawn against, so the pair cannot disagree about the background.
  stylised_bg_run <- eventReactive(input$s_go, {
    stats::setNames(list(app_run_coupled(APP_SPIN, input$s_bg, APP_FUTURE_YEARS)),
                    names(APP_SCENARIOS)[match(input$s_bg, APP_SCENARIOS)])
  })

  # 2026-10-20: the runs moved to global.R (app_pulse_runs()), which sees only the inputs
  # APP_PULSE_DEFAULTS names; the default settings are served from the precomputed product
  # (app_pulse_lab()), anything else is computed live as before.
  # ⭐ AND THE DEFAULT IS DRAWN WITHOUT A CLICK; A CHANGED SETTING GRAYS THE RESULT OUT (Marcus
  # 2026-10-20; global.R app_pulse_stale()). `pulse_shown` is the result on screen and the inputs it
  # was run at; every reader of the result goes through pulse_runs(), as before.
  pulse_inputs <- reactive(app_pulse_inputs(input))
  pulse_shown  <- reactiveVal(NULL)
  observeEvent(input$p_go, {
    inp <- pulse_inputs()
    pulse_shown(list(pr = app_pulse_lab(inp), inp = inp))
  })
  # opened (or set back) at the defaults: the stored result, with no click. Nothing is drawn when the
  # product is absent or refused; the click then computes it, as before.
  observe({
    req(identical(input$f_mode, "Pulse lab"))
    inp <- pulse_inputs()
    if (app_pulse_is_default(inp)) {
      r <- app_pulse_default_result()
      if (!is.null(r)) pulse_shown(list(pr = r, inp = inp))
    }
  })
  pulse_runs  <- reactive({ s <- pulse_shown(); req(s); s$pr })
  pulse_stale <- reactive(identical(input$f_mode, "Pulse lab") &&
                            app_pulse_stale(pulse_shown()$inp, pulse_inputs()))
  observe(session$sendCustomMessage("ccx_pulse_stale",
                                    list(stale = pulse_stale(), ids = as.list(APP_PULSE_RESULT_IDS))))
  output$p_stale_note <- renderUI(if (pulse_stale()) div(class = "caveat", APP_PULSE_STALE_NOTE))

  output$f_plot <- renderPlotFit("f_plot", {
    if (identical(input$f_mode, "Pulse lab")) {
      pr <- pulse_runs()
      # F4: the same pair of runs, differenced two ways. Carbon is a SHARE of
      # the pulse; temperature is degrees -- so they cannot share an axis, and
      # the radio picks the panel rather than relabeling one.
      # 2026-10-15 review: the temperature view now draws FaIR too (its mean; the grid has no band for it), as the
      # FaIR note and APP_PULSE_SHAPE_NOTE already said it did -- the RUN's settings, exactly as the CO₂ view
      if (identical(input$f_yvar, "gmst"))
        plot_pulse_warming(pr$base$climate, pr$pulse$climate, pr$year, pr$gtc,
                           fair = if (isTRUE(input$f_fair)) app_fair_pulse(pr$bg, pr$year, pr$gtc))
      else
        plot_pulse_decay(pr$base$climate, pr$pulse$climate, pr$year, pr$gtc,
                         tag = list(out = pr$tagged$out, tag = pr$tagged$tag), pulse_out = pr$pulse$out,
                         # the RUN's settings, not the live inputs, so FaIR matches the lines drawn
                         fair = if (isTRUE(input$f_fair)) app_fair_pulse(pr$bg, pr$year, pr$gtc))
    } else if (identical(input$f_mode, "Build your own")) {
      r <- stylised_run()
      runs <- c(stylised_bg_run(), list(`Your scenario` = r))
      # F5: run 1750-2150, SHOW 1900-2150. The two spans are separate
      # constants; see the note on APP_FUTURE_VIEW in global.R.
      plot_future(runs, input$f_yvar %||% APP_FUTURE_YVAR_DEFAULT,
                  if (identical(input$f_yvar, "gmst")) LAB_TEMP else LAB_CO2,
                  view = APP_FUTURE_VIEW)
    } else {
      rs <- future_runs()
      # ⭐ 2026-09-26: standard FaIR as a dashed reference, on request.
      # ⛔ PASS THE SLICE OF APP_SCENARIOS, NOT `names(rs)`. The runs are named with
      # the DISPLAY labels and APP_FAIR is keyed on the ids; handing over the
      # labels matched nothing and drew no line, which looks exactly like
      # agreement. The named slice carries both, so the two keyings cannot
      # drift apart again.
      # B7 (Marcus 2026-10-01, "Laplace first, MCMC as the check"): the
      # precomputed ribbons for the selected scenarios, and the caption sentence
      # that labels them (or says why none is drawn). Only on the van Vuuren
      # scenarios -- "Build your own" and the pulse lab have no ribbons.
      plot_future(rs, input$f_yvar,
                  if (identical(input$f_yvar, "gmst")) LAB_TEMP else LAB_CO2,
                  view = APP_FUTURE_VIEW,
                  fair = if (isTRUE(input$f_fair))
                    app_fair_overlay(APP_SCENARIOS[APP_SCENARIOS %in% input$f_scen],
                                     input$f_yvar),
                  bands = app_future_bands(input$f_scen, input$f_yvar),
                  note = app_ribbon_note(input$f_yvar))
    }
  })

  # The FaIR comparison's caveat, shown only when the comparison is. ⚠ It says
  # the two are NOT like-for-like before 2024 (the emulator splices the observed
  # budget, FaIR does not), because a reader who spots that gap unaided has
  # found a hidden defect rather than a documented one.
  output$f_fair_note <- renderUI({
    if (!isTRUE(input$f_fair) || identical(input$f_mode, "Build your own")) return(NULL)
    if (identical(input$f_mode, "Pulse lab")) {
      # 2026-10-12: offered again, now that FaIR was run on this tab's pulse -- with the reason when it was not
      pr <- pulse_runs(); why <- app_fair_pulse_why(pr$bg, pr$year, pr$gtc)
      # 2026-10-15 review: both notes are FORMATS now -- the year is the splice's (global.R), never typed
      return(div(class = "caveat", if (is.null(why)) sprintf(APP_FAIR_PULSE_NOTE, APP_SPLICE_YEAR + 1L) else why))
    }
    div(class = "caveat", sprintf(APP_FAIR_NOTE, APP_SPLICE_YEAR))
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
        # decays are normalized to their OWN value at y1, so the comparison is
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
      # Marcus 2026-10-02 (carbotopecomment), his wording ("GHGs" spelled out for the reader).
      sprintf(paste("Release %d GtC in %d and %s of it is still in the air a",
                    "century later; %s after %d years. Unlike other greenhouse gases",
                    "(methane, nitrous oxide), which are chemically or photochemically",
                    "destroyed, emitted carbon is not destroyed; it just moves between",
                    "sinks. The result of this is that a share of carbon emissions is",
                    "effectively permanent on a human timescale."),
              pr$gtc, pr$year, fmt_pct(f(y1)), fmt_pct(f(y2)), y2 - pr$year)
      }
    } else if (identical(input$f_mode, "Build your own")) {
      r <- stylised_run(); cl <- r$climate; sp <- stylised_spec()
      # ⛔ THE SECOND CLAUSE IS CONDITIONAL ON THE BRANCH (2026-09-25). It used
      # to read "even when emissions stop" for ALL THREE `s_kind` values, and
      # emissions stop in only ONE of them (`to_zero`). On the DEFAULT branch
      # (`constant`, hold at today's level) they never stop at all, so the
      # sentence asserted a counterfactual the run did not perform, printed
      # beside two numbers the run did produce.
      #
      # ⛔⛔ 2026-09-26: the replacement clause was itself WRONG on the app's
      # own default. It read "a fixed rate only ever approaches zero" -- but
      # `s_rate` spans -5 to +5 and DEFAULTS TO +1, so the default `rate`
      # pathway GROWS exponentially and approaches nothing. One string was
      # covering three pathways by disjunction, which is how it came to assert
      # the opposite of what the run did. Now ONE BRANCH PER PATHWAY, on the
      # SIGN of the rate as well as the kind, with the numbers read off the
      # captured pathway rather than described in words.
      # ⚠ The `to_zero` wording is Marcus's and is VERBATIM. Note that only
      # FOSSIL emissions reach zero there -- `app_stylised_emissions()` always
      # takes land use from the background scenario -- so "emissions stop" is
      # fossil-only. Flagged for him rather than edited.
      # ⭐ THE CLAUSE IS A PURE FUNCTION in global.R so that it can be GATED
      # (test-stylised-takeaway.R). The bug it replaced -- "a fixed rate only
      # ever approaches zero", on a slider that defaults to +1 %/yr -- was
      # untestable precisely because it lived inside this renderText.
      tail_clause <- app_stylised_tail_clause(
        sp$kind, sp$rate_pct, sp$emissions,
        APP_EMIS_HIST$fossil_GtC[APP_EMIS_HIST$year == max(APP_EMIS_HIST$year)],
        climate = cl)   # 2026-10-02: the to_zero temperature clause is read off the run
      sprintf("Your pathway reaches %.0f ppm and %+.1f °C by %d. %s",
              cl$co2_ppm[nrow(cl)], cl$gmst[nrow(cl)], max(cl$year), tail_clause)
    } else {
      # 2026-10-12 code review: min/max over EVERY ticked run (app_scenario_span, global.R); it read
      # the first and last ticked run, and the menu is not ordered by outcome.
      sp <- app_scenario_span(future_runs())
      # 2026-10-15 review: one ticked scenario printed "span 620 to 620 ppm"
      if (length(future_runs()) == 1L)
        return(sprintf(paste("By %d this scenario reaches %.0f ppm and %.1f °C.",
                             "A scenario is a choice about future emissions."),
                       sp$year, sp$co2[1], sp$gmst[1]))
      sprintf(paste("By %d these scenarios span %.0f to %.0f ppm and %.1f to",
                    "%.1f °C. The spread comes from choices about future emissions."),
              sp$year, sp$co2[1], sp$co2[2], sp$gmst[1], sp$gmst[2])
    }
  })

  # F2 (Marcus 2026-09-22): the second pulse panel. Rendered only in the pulse
  # lab, and only once a result is on screen -- after a click, or (since 2026-10-20)
  # on opening the tab at the default settings, from the stored result.
  # ⭐ THE OCEAN BY DEPTH (Marcus 2026-10-16, app/R/ocean_depth.R): the three runs restarted
  # once a year from saved states, ~0.7 s each. Its own reactive, so the pulse chart above
  # draws without waiting for it.
  # The precomputed default carries its split as `depth` (2026-10-20, global.R app_pulse_lab()).
  pulse_depth <- reactive({
    pr <- pulse_runs()
    if (!is.null(pr$depth)) pr$depth else
      app_pulse_depth_runs(APP_SPIN, pr[c("base", "pulse", "tagged")], pr$year)
  })
  output$f_partition <- renderPlotFit("f_partition", {
    req(identical(input$f_mode, "Pulse lab"))
    pr <- pulse_runs()
    plot_pulse_partition(app_pulse_partition_table(pulse_depth(), pr$gtc), pr$gtc, pr$year)
  })

  # ---- CUMULATIVE CARBON AND TEMPERATURE (Marcus 2026-09-25) ---------
  # "Add text for the pulse radio button about the relationship between
  # cumulative carbon and temperature (e.g., each ton of CO2 emitted adds
  # effectively permanent temperature)."
  #
  # \u26a0\u26a0 THE PROSE IS A PLACEHOLDER FOR MARCUS. The pedagogy on this tab is
  # his; this is drafted so the slot is not empty and the numbers are real, and
  # it is listed as owed copy in the handoff exactly as the "Build your own"
  # sentence is. Rewording it does not touch the arithmetic.
  #
  # \u26d4 EVERY NUMBER IS MEASURED FROM THE RUN THE READER JUST TRIGGERED, not
  # quoted from the literature. A textbook figure here would be a number this
  # app cannot check, printed beside two panels drawn from a model that might
  # disagree with it.
  #
  # \u26d4 AND IT IS NOT CALLED TCRE. TCRE is defined for cumulative emissions
  # along a transient pathway; this is the warming from a PULSE laid on top of a
  # scenario, which is the numerator of an AGTP, not the same quantity. Naming
  # it TCRE would be a category error of exactly the kind the project's
  # like-for-like rule exists to stop, so the copy says "warming per unit of
  # extra carbon" and leaves the acronym out.
  #
  # \u26a0 PROPORTIONALITY IS STATED, NOT DEMONSTRATED HERE, and says so: showing
  # it would need a second pulse size, i.e. a third model run on every click.
  output$f_pulse_permanence <- renderUI({
    req(identical(input$f_mode, "Pulse lab"))
    pr <- pulse_runs()
    b <- pr$base$climate; p <- pr$pulse$climate
    d <- p$gmst - b$gmst
    at <- function(y) d[which.min(abs(b$year - y))]
    y100 <- pr$year + 100L; yend <- max(b$year)
    peak <- max(d, na.rm = TRUE)
    if (!is.finite(peak) || peak <= 0) return(NULL)
    keep <- at(yend) / peak
    per1000 <- at(y100) / pr$gtc * 1000
    info_box("What this says about carbon and temperature",
      p(sprintf(paste("This %d GtC pulse warms the world by %.3f \u00b0C a century",
                      "later \u2014 %.2f \u00b0C per 1000 GtC \u2014 and by %s of its own peak",
                      "warming still at %d, %d years after release."),
                pr$gtc, at(y100), per1000, fmt_pct(keep), yend, yend - pr$year)),
      # Marcus 2026-10-11 (CarboTopecomments.10.11.26), his two "Change"s, verbatim.
      # Marcus 2026-10-15 ("Apply all the app text suggestions"): "Two things are worth separating here. The first is that" cut (no second)
      p("The warming",
        "barely decays: a pulse of carbon emissions keeps warming the world for as",
        "long as this model runs, so on any human timescale the temperature",
        "resulting from a tonne of CO₂ is permanent."),
      # ⭐ Marcus 2026-10-11: his paragraph REPLACES the "total, not the rate" paragraph, the
      # measured-proportionality caveat and the horizon sentence ("And it barely depends on when
      # you look"), whose claim his last clause now carries. His wording, verbatim except "form"
      # -> "from", "dC" -> "°C", and every NUMBER read from the named constants in global.R
      # (gated by test-pulse-linearity.R against the driver's own CSV), so the sentence cannot
      # outlive the measurement: his draft's "2.5%" was hilda33p's. The horizon range is the
      # measured horizons' range, read off the constant's names.
      # RULED 2026-10-11 (Marcus: "Temperature only (Recommended)"): "on concentrations and
      # temperature" -> "on temperature". At hilda29e the CO2 response per GtC spreads 6.4-7.0 % across
      # 10-500 GtC (pulse_vs_tcre_20261011.log), ~3x the temperature figure this sentence quotes.
      # 2026-10-15 review: these numbers were MEASURED at the app's defaults (APP_PULSE_LIN_SRC: background
      # APP_SCENARIO_BG, release APP_PULSE_YEAR_DEFAULT), so the sentence says so; both read from the constants.
      p(sprintf(paste("The effects of a pulse of carbon emissions on temperature are",
                      "insensitive to the size of the pulse in this model.",
                      "At the default settings (%s background, released %d), across pulses",
                      "from %g to %g GtC, the figure above moves by only %.1f%%,",
                      "and the impact on temperature is about %.1f °C per 1000 GtC from any",
                      "time period between %d and %d years after release."),
                sub("\\s*\\(.*\\)$", "", names(APP_SCENARIOS)[match(APP_SCENARIO_BG, APP_SCENARIOS)]),
                APP_PULSE_YEAR_DEFAULT,
                APP_PULSE_LIN_SIZES[1], APP_PULSE_LIN_SIZES[2], APP_PULSE_LIN_SPREAD,
                APP_PULSE_PER1000_ABOUT,
                min(as.integer(names(APP_PULSE_PER1000_BY_HORIZON))),
                max(as.integer(names(APP_PULSE_PER1000_BY_HORIZON))))),
      p(APP_PULSE_SHAPE_NOTE))
  })

  output$f_notes <- renderUI({
    how <- if (identical(input$f_mode, "Pulse lab")) {
      div(class = "caveat",
          tags$strong("How this is computed: "),
          "the model runs twice — once with the pulse and once without, from ",
          "identical starting conditions — and the difference between the two ",
          "is the pulse's effect.")
    } else NULL
    # F5 (2026-09-24): the runs now reach 2150, which puts the stylized "+5 %
    # per year" case 26x outside the range the CO2->forcing curve was fitted
    # over. ccx_run_coupled() has always warned about this to the console; on
    # a tab a student can drive there with one slider, the console is not
    # where the warning belongs. CONDITIONAL -- nothing renders unless a run
    # actually leaves the range. See app_erf_range_note() in global.R.
    cls <- switch(input$f_mode %||% "Scenarios",
                  # 2026-10-15 review: + the BASE run -- the note now also warns below the range, and without the
                  # pulse the run falls lower (vvLN: 236 ppm vs 246), which is the console's number
                  "Pulse lab"     = list(pulse_runs()$pulse$climate, pulse_runs()$base$climate),
                  "Build your own" = list(stylised_run()$climate),
                  lapply(future_runs(), `[[`, "climate"))
    note <- app_erf_range_note(cls)
    if (is.null(note)) how
    else tagList(how, div(class = "caveat",
                          tags$strong("Outside the fitted range: "), note))
  })

  # ---- 6. WHAT PINS DOWN WHAT? (Marcus 2026-09-25) -------------------
  # ⚠ NOTHING IS RE-DERIVED HERE. Every number below is read or summed from
  # data/constraint_map.rds, which calibration/diag_constraint_map.R gated. A
  # second implementation of the same arithmetic in the app is how the land sink
  # spent a month on a half-year offset (memory `app_sink_half_year_offset`).
  cm_tensions <- reactive(app_cmap_tensions(APP_CMAP))

  output$cm_map_ui <- renderUI({
    if (is.null(APP_CMAP))
      return(div(class = "caveat",
                 sprintf("The constraint map is not shown: %s — run", APP_CMAP_WHY),
                 tags$code("Rscript calibration/diag_constraint_map.R"), "."))
    tagList(
      plotOutput("cm_map", height = "430px"),
      div(class = "caveat", tags$strong("What this can and cannot say: "),
          APP_CMAP_NOTE,
          # Marcus 2026-10-02 (carbotopecomment): "Move this up to the yellow box" -- from the
          # structure section below. Appended to the box, NOT to APP_CMAP_NOTE, which is also
          # printed on the chart and asserted verbatim by test-constraint-map-panel.R.
          local({
            tot <- rowSums(APP_CMAP$MC)
            sprintf(paste(" Read the row totals, not just the colors: the strongest row",
                          "here is worth %s log-units and the weakest %s, so a bright",
                          "cell in a weak row is a large share of very little."),
                    fmt_cmap_total(max(tot)), fmt_cmap_total(min(tot)))
          }),
          # 2026-10-08 (h): the cut's El Niño settings are not on the map; NULL (nothing) without the cut
          app_cmap_module_note(APP_CMAP))
    )
  })

  output$cm_map <- renderPlotFit("cm_map",
    plot_constraint_map(APP_CMAP, input$cm_level))

  output$cm_tension_ui <- renderUI({
    tn <- cm_tensions()
    if (is.null(tn)) return(div(class = "caveat",
      "No opposing pair is present in this build of the map."))
    plotOutput("cm_tension", height = "320px")
  })

  output$cm_tension <- renderPlotFit("cm_tension", plot_constraint_tension(cm_tensions()))

  # The takeaway names the measurements that carry the most weight and says who
  # holds them -- COMPUTED from the row totals and row shares, so a refit moves
  # the sentence rather than leaving it asserting the old winner.
  output$cm_takeaway <- renderText({
    # no stability file computed against THIS map -> no takeaway (APP_CMAP_STAB logs why)
    if (is.null(APP_CMAP) || is.null(APP_CMAP_STAB)) return("")
    tot <- sort(rowSums(APP_CMAP$MC), decreasing = TRUE)
    top <- names(tot)[1:3]
    # ⛔ 2026-09-27: this used to say "mostly influenced by <argmax>" for all
    # three rows, and two of the three are TIES whose winner changes with the
    # arm (0.13 pp and 0.85 pp). The phrase is now a pure function in global.R
    # so it can be gated, and it reports a tie as a tie. Since 2026-10-14 a tie is a winner that
    # loses the row in more than APP_CMAP_TIE_LOST_MAX of the posterior draws.
    who <- vapply(top, function(r) app_cmap_holder_phrase(APP_CMAP$MC[r, ], APP_CMAP_STAB$lost_share[[r]]),
                  character(1))
    paste0("The metrics most sensitive to changes in this model are ",
           paste(sprintf("%s — %s", top, who), collapse = "; "),
           ". A metric low on the chart is one this model could change a good",
           " deal without results changing substantially.")   # Marcus 2026-10-02
  })

  output$cm_pin_note <- renderText({
    if (is.null(APP_CMAP)) return("")
    sprintf(paste("Measured here: only %.0f%% of the sensitivity in this map is of",
                  "the pinning kind. Almost everything is a pull, so the fitted",
                  "numbers sit where opposing pulls cancel rather than where any",
                  "one measurement would put them."),
            100 * APP_CMAP$pin_share)
  })

  # ⭐⭐ THE STRUCTURAL READING (Marcus asked for the qualitative judgment, not
  # only the parameter table). Each claim is a JUDGMENT about the model's shape,
  # and each one carries the number it rests on, COMPUTED from the map here so
  # the prose cannot outlive the measurement. ⚠ Where a claim is a judgment
  # rather than a measurement, it says so in its own words.
  output$cm_structure_ui <- renderUI({
    if (is.null(APP_CMAP)) return(NULL)
    MC <- APP_CMAP$MC
    sh <- function(row, col) 100 * MC[row, col] / sum(MC[row, ])
    tn <- cm_tensions()
    # 2026-10-15 review: BOTH sides seasonal (was either), because the sentence below now says these pairs set the
    # two seasonal cycles against each other. At hilda31w the same four pairs either way (q10 is one: CO₂ vs δ¹³C cycle).
    seas <- if (is.null(tn)) NULL else tn[grepl("seasonal", tn$up) & grepl("seasonal", tn$down), ]
    # ⛔⛔ PER PARAMETER, NOT PER COMPONENT. A component's total is a SUM over its
    # parameters, so a component holding ONE parameter looks "unwatched" beside
    # one holding seven, however hard its parameter is pinned -- and the first
    # draft of this sentence said exactly that about air-sea gas exchange, whose
    # single parameter `k_w` has the HIGHEST total leverage of all 29. A sum is
    # not a rate until you divide by the count.
    par_tot <- sort(colSums(APP_CMAP$M))
    # 2026-10-15 review: the three quietest were all LIKELIHOOD/REPORTING-only names (grad_off_d13c, grad_off_co2,
    # imb_share_ocean_rest), printed as code. Those are the map's names with no slot in the model's parameter list
    # (APP_PARAMS) other than the two FORCING parameters the app carries separately (as output$h_params does);
    # the rest print as their plain-English labels (APP_PARAM_META, params_meta.R), quoted as the table shows them.
    lik_only <- setdiff(names(par_tot), c(names(APP_PARAMS), "bomb_total", "luc_scale"))
    quiet <- utils::head(setdiff(names(par_tot), lik_only), 3L)
    quiet <- vapply(quiet, function(nm) {
      d <- APP_PARAM_META[[nm]]$desc
      sprintf("“%s”", if (is.null(d)) nm else d)
    }, character(1))
    pump_top <- names(which.max(MC[, "Biological pump"]))
    tagList(
      p(tags$strong("The ocean's Δ¹⁴C is mainly a ventilation measurement. "),
        sprintf(paste("%.0f%% of the ocean's Δ¹⁴C sensitivity is to the mixed",
                      "layer and the vertical mixing below it."),
                sh("Δ¹⁴C in the ocean", "Mixed layer & vertical mixing")),
        # Marcus 2026-10-02: "That is the useful reading and also the limiting one:" deleted
        " A change to the ocean's structure that leaves its ventilation rate alone",
        " would barely register in the radiocarbon profile at all."),
      # 2026-10-15 review: "the only thing influenced by" -> "the measurement ... influences most" (48 % of the
      # pump's leverage at hilda31w, not all of it); said only while it is the pump's largest row
      p(tags$strong(if (identical(pump_top, "Ocean interior chemistry"))
                      "The interior chemistry is the measurement the biological pump influences most. "
                    else sprintf("The biological pump influences %s more than any other measurement. ", pump_top)),
        sprintf(paste("%.0f%% of the interior DIC, δ¹³C and alkalinity gradients'",
                      "sensitivity is to the pump, and the pump has much less",   # 2026-10-15 review: 18.5 % of its
                      "influence elsewhere (%.0f%% of the atmospheric CO₂",          # leverage is on the d13C level row
                      "level's sensitivity)."),
                sh("Ocean interior chemistry", "Biological pump"),
                sh("CO₂ level", "Biological pump")),
        " The pump is necessary for matching these bottle data, even though it",
        " turns out that the pump has little influence on the rest of the",
        " system."),
      p(tags$strong("The seasonal cycle is two constraints in tension. "),
        sprintf(paste("The seasonal CO₂ cycle and the seasonal δ¹³C cycle take %.0f%% and",
                      "%.0f%% of their sensitivity from the seasonal-cycle parameters, and they",
                      "disagree about them:"),
                sh("CO₂ seasonal cycle", "Seasonal cycle"),
                sh("δ¹³C seasonal cycle", "Seasonal cycle")),
        # 2026-10-15 review: "seasonal parameters (seas_lag_p_NH, ..., q10)" -- q10 is land uptake, and code names
        # are not reader copy
        if (!is.null(seas) && nrow(seas))
          sprintf(paste(" %s of the strongest opposing pairs are parameters that set the CO₂ and",
                        "δ¹³C seasonal cycles against each other."),
                  nrow(seas)) else NULL,
        " The fitted phase and amplitude are a compromise between the two tracers.",
        # ⚠ CLAUDE'S DRAFT, FOR MARCUS'S WORDING (2026-10-02, carbotopecomment: "Can we change
        # this to a theory about why the tracers seem to be inconsistent given our model
        # structure?"). It replaces "A judgment, not a measurement: ... one knob per hemisphere
        # where two tracers want two different answers." The theory is the one MEASURED in
        # [[ccx_sst_seas_veto]] (2026-08-21): the ocean's seasonal channel is ANTIPHASE to the net
        # cycle, so strengthening it SHRINKS the CO2 amplitude while the land's d13C swing stays,
        # and the d13C rows veto it (72 % of the cost). Stated STRUCTURALLY on purpose: that
        # note's numbers are from an older mode, so no direction-at-this-fit is claimed.
        " A likely reason they disagree, given how this model is built: it makes its",
        " seasonal cycle from two channels that run in opposite directions — plants on",
        " land, which take up and release carbon with a strong ¹³C fingerprint, and the",
        " surface ocean, which gives off CO₂ as it warms in summer and carries almost no",
        " ¹³C fingerprint. The ocean channel shrinks the seasonal CO₂ swing without",
        " shrinking the δ¹³C swing in step, so the two tracers respond differently to",
        " the same seasonal settings — and with one seasonal setting per hemisphere,",
        " the fit can only split the difference."),
      p(tags$strong("The land's magnitude is well constrained; its shape is not. "),
        # 2026-10-15 review: "pinned hard" / "only pinned as a combination" -> "constrained" ("pinning" is the
        # sidebar's defined term for one kind of sensitivity, not a synonym for well constrained)
        sprintf(paste("Land uptake takes %.0f%% of the CO₂ level's sensitivity and",
                      "%.0f%% of the measured budget's, so how much carbon the land",
                      "takes up today is tightly constrained."),
                sh("CO₂ level", "Land uptake"), sh("Measured land & ocean sinks", "Land uptake")),
        # Marcus 2026-10-02: name the two numbers; the descriptions are params_meta.R's own
        sprintf(paste(" But the two numbers that set it (the maximum boost CO₂",
                      "fertilization can give, beta_max, and the CO₂ level needed for",
                      "half that boost, fert_k) are only constrained as a combination: on",
                      "their own each is about %.0f\u00d7 tighter than the fit leaves the",
                      "pair jointly."),
                max(APP_CMAP$sd_ratio[c("beta_max", "fert_k")]))),
        # 2026-10-01 (Marcus, review 10-01c A3): " CO2 fertilization is this
        # model's only long-term land-uptake term, so the saturation shape --
        # the part that decides the future -- is exactly the part the
        # present-day record does not separate." DELETED. Its premise is false
        # since hilda33d (N-deposition retention is a second long-term sink).
      # Marcus 2026-10-02 (carbotopecomment): his sentence replaces the paragraph; the three
      # names stay COMPUTED (the per-PARAMETER totals above). Its "read the row totals" warning
      # moved up into the map's own caveat box (output$cm_map_ui), and the paragraph on the
      # least-sensitive measurement that followed it is DELETED.
      p(tags$strong("Some parameters have little influence on the model, "),
        sprintf("and are not well constrained by observations, such as %s.",
                if (length(quiet) > 1L)
                  paste0(paste(quiet[-length(quiet)], collapse = ", "), ", and ",
                         quiet[length(quiet)]) else quiet))
    )
  })

  # ---- 6. Under the hood ---------------------------------------------
  # The box diagram. ARROWS CARRY THEIR FLUXES (2026-08-13): unlabeled arrows
  # were the single biggest pedagogical gap in the app -- the entire
  # "CO2 only lasts 5 years" lesson is that photosynthesis and air-sea exchange
  # are ~70 and ~95 GtC/yr while emissions are ~11 and the net imbalance ~5, and
  # an arrow without a number cannot say that. Numbers come from APP_FLUX_NOW
  # (R/fluxes.R), i.e. from the model's own tap, not from a table typed here.
  # 2026-10-15 (Marcus: legibility): one SHAPE at every width -- the height is the width times DIAGRAM_ASPECT and
  # every text size is multiplied by the same width ratio, so the layout tuned at DIAGRAM_REF_PX is what any
  # reader sees, larger or smaller.
  output$h_diagram <- renderPlotFit("h_diagram",
    plot_box_diagram(APP_FLUX_NOW, APP_HIST$out[nrow(APP_HIST$out), ], app_params$p, n_layers = APP_SPIN$grid$nl,
                     scale = diagram_scale(session$clientData$output_h_diagram_width)),
    height = function() diagram_height_px(session$clientData$output_h_diagram_width))

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
  # printing them as "—" would understate what is known. Since 2026-10-15 the
  # other likelihood-only names the mode fits (the gradient offsets, sigma_d14c)
  # are carried too (APP_LIK_ONLY), so no fitted row prints "—".
  output$h_params <- renderTable(
    # + the GATED D2/D3 names when the mode fits them (2026-10-01): CCX_PARAM_NAMES is this process's
    # table and the gate is closed in the app; the D3 shares are likelihood-side and carried from the
    # mode file like rep_dC
    app_param_table(CCX_PARAM_NAMES,
                    c(APP_PARAMS, list(bomb_total = APP_BOMB_TOTAL,
                                       luc_scale  = APP_LUC_SCALE,
                                       rep_dC     = APP_REP_DC), APP_IMB_SHARES, APP_LIK_ONLY),
                    extra = APP_GATED_FIT,
                    # 2026-10-06: the "Set" column, from the mode file's own lists (params_meta.R)
                    fitted = APP_FITTED_NAMES, held = APP_HELD_NAMES),
    striped = TRUE, width = "100%")

  # ---- 7. Known issues (the beta review) -----------------------------
  # Each panel is rendered ONLY when its tab is visible, which is what keeps the
  # expensive issues (2-5, each needing a model run the app does not already
  # have) off the startup path. withProgress gives the first view of the tab a
  # reason for the wait instead of a blank panel.
  rv_render <- function(id, f, label) renderPlotFit(id, {
    withProgress(message = label, value = NULL, f())
  })
  output$rv_repdc     <- rv_render("rv_repdc", rv_plot_repdc,     "Comparing the model with Mauna Loa")
  output$rv_gradient  <- rv_render("rv_gradient", rv_plot_gradient,  "Measuring the north\u2013south gradients")
  output$rv_diseq     <- rv_render("rv_diseq", rv_plot_diseq,     "Measuring the ocean's isotopic disequilibrium")
  output$rv_variance  <- rv_render("rv_variance", rv_plot_variance,  "Measuring the year-to-year variability")
  output$rv_enso      <- rv_render("rv_enso", rv_plot_enso,      "Running the model with its ENSO mechanisms off")
  output$rv_irf       <- rv_render("rv_irf", rv_plot_irf,       "Releasing a pulse and following it")
  output$rv_partition <- rv_render("rv_partition", rv_plot_partition, "Following the pulse for a thousand years")
  output$rv_oclim       <- rv_render("rv_oclim", rv_plot_oclim, "Reading the ocean's climate effect")
  output$rv_oclim_stake <- rv_render("rv_oclim_stake", rv_plot_oclim_stake, "Reading what it is worth in 2300")

  # THE STAND-IN LIST IS GENERATED, NOT TYPED. Which names are held, and at what
  # value, is a property of the mode file the app is running; a hand-kept table
  # here would be a second claim about the model that nothing checks.
  # TWO TABLES, BECAUSE THEY ARE TWO LISTS (Marcus 2026-09-22, review N12).
  # The card's prose named the STAND-INS and this table listed the PINS, and
  # the tab presented them as one. The stand-in list is a judgment (RV_SHIMS,
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
    # 2026-10-15 review: both tables printed code names only; the plain-English description from the
    # parameter label table (APP_PARAM_META, params_meta.R) leads, the code name follows
    data.frame(`Stand-in` = app_param_desc(names(x$shims)),
               `Code name` = names(x$shims),
               `What it stands in for` = unlist(x$shims, use.names = FALSE),
               `In this fit` = ifelse(held, "held at a value (below)", "fitted freely"),
               check.names = FALSE)
  }, striped = TRUE, width = "100%")

  output$rv_shims <- renderTable({
    x <- rv_stand_ins()
    if (rv_failed(x) || !length(x$pins))
      return(data.frame(Note = "The held-parameter list is unavailable in this build."))
    data.frame(`Held parameter` = app_param_desc(names(x$pins)),
               `Code name` = names(x$pins),
               `Held at` = formatC(as.numeric(x$pins), digits = 4, format = "g"),
               `Also a stand-in` = ifelse(names(x$pins) %in% x$shims_held, "yes", ""),
               check.names = FALSE)
  }, striped = TRUE, width = "100%")

  output$rv_constants <- renderUI({
    x <- rv_stand_ins()
    if (rv_failed(x)) return(div(class = "caveat", x$msg))
    tagList(
      p(sprintf(paste("%d of the model's %d physical constants are still marked",
                      "provisional \u2014 their values were inferred by fitting the model,",   # 2026-10-15 review
                      "or simply held, rather than traced to a published measurement:"),
                length(x$provisional), x$n_constants)),
      p(tags$code(paste(x$provisional, collapse = ", "))),
      if (!is.na(x$n_fitted))
        p(tags$small(sprintf(paste("The running fit has %d free parameters;",
                                   "the held parameters are listed above."), x$n_fitted))))
  })

  # TWO TABLES, NOT ONE (Marcus 2026-09-22, review U2). IGCC temperature sat in
  # "What it is fitted to", which is wrong in the direction that matters: it is
  # PRESCRIBED forcing, and listing a driver as a target overstates what the
  # model derives for itself. Historical land-use change is a driver too. The
  # split is also what makes the Keeling tab's corrected takeaway checkable --
  # a reader can see the driver list it refers to.
  # A7 (Marcus 2026-10-01): N deposition added. Source per
  # data-raw/build_ndep_forcing.R: a proxy built from NOx + NH3 emissions, the
  # CMIP7 ScenarioMIP history (van Vuuren et al., Zenodo v1.1.1) to 2023 and the
  # seven-marker mean for 2024.
  # 2026-10-15 review: (1) the observed SEA-SURFACE temperature is a driver too (sst_obs = 1 at hilda31w;
  # data-raw/build_sst_forcing.R: HadSST.4.2.0.0 hemispheric annual anomalies, re-based to 1850-1900, file 1850-2025)
  # and was missing; (2) the ENSO row is named for the index the canonical RUNS (ccx_enso_index_of(APP_PARAMS) =
  # "detrend" at hilda31w), and (3) ends where the run ends instead of "present". New end years read APP_HIST_YEARS;
  # the ENSO start is CCX_DRIVERS$enso$since (R/mechanisms.R).
  output$h_drivers <- renderTable({
    y_end <- APP_HIST_YEARS[2]
    enso_lab <- switch(ccx_enso_index_of(APP_PARAMS),
                       detrend = "ENSO index (detrended Ni\u00f1o 3.4)",
                       demean  = "ENSO index (Ni\u00f1o 3.4)",
                       "ENSO index (from Ni\u00f1o 3.4)")
    data.frame(
      Driver = c("Fossil CO\u2082 emissions", "Land-use change CO\u2082",
                 "Global mean temperature", "Sea-surface temperature, each hemisphere",
                 enso_lab,
                 "Volcanic aerosol", "Bomb and industrial \u00b9\u2074C",
                 "Nitrogen deposition on land"),
      Covers = c("1750\u20132024", "1750\u20132024", "1850\u20132024",
                 sprintf("1850\u2013%d", y_end),
                 sprintf("%d\u2013%d", CCX_DRIVERS$enso$since, y_end), "1850\u20132024", "1952\u20132023",
                 "1750\u20132024"),
      Source = c("Global Carbon Budget 2025",
                 "Global Carbon Budget 2025 (OSCAR v3.1 before 1850)",
                 "IGCC", "Met Office Hadley Centre HadSST.4.2.0.0", "NOAA PSL",
                 "NASA GISS, CMIP7 stratospheric aerosol",
                 "Tans (1981) / Naegler & Levin (2006); Laemmel et al. 2025",
                 "Built from NOx and NH\u2083 emissions, CMIP7 ScenarioMIP (van Vuuren et al.)"),
      check.names = FALSE)
  }, striped = TRUE, width = "100%")

  # 2026-10-15 review, every row checked against R/likelihood.R and the canonical's own scored streams
  # (ccx_mode_file()$streams at hilda31w): ADDED the ice-core d13C row (d13c_icecore: Rubino et al. 2019 samples,
  # in-run and before LIK_ICE_D13C_END, i.e. 1752-1976) and the ocean bomb-14C inventory (excess_c14_ocean: Naegler &
  # Levin 2006, 1975 and 1995); the South Pole's SEASONAL cycle is scored (co2_seasonal_SPO); the ice-core CO2 row is
  # scored only before LIK_ICE_CO2_END (1752-1957, was "1700-1978"); IntCal20 ends where Hua begins (1750-1940, was
  # "1750-1950"); Hua's Delta14C measures EXCHANGE of atoms, not net uptake.
  output$h_data <- renderTable({
    data.frame(
      Record = c("Mauna Loa CO\u2082", "South Pole CO\u2082", "Law Dome ice-core CO\u2082",
                 "Law Dome ice-core \u03b4\u00b9\u00b3C (Rubino et al. 2019)",
                 "Mauna Loa & South Pole \u03b4\u00b9\u00b3C", "Zonal \u0394\u00b9\u2074C (Hua et al. 2022)",
                 "IntCal20 tree-ring \u0394\u00b9\u2074C",
                 "Ocean bomb-\u00b9\u2074C inventory (Naegler & Levin 2006)", "Global Carbon Budget 2025",
                 "GLODAPv2.2023 ocean bottles"),
      Covers = c("1958\u20132024", "1975\u20132024", "1752\u20131957", "1752\u20131976", "1977\u20132024",
                 "1941\u20132019", "1750\u20131940", "1975 and 1995", "1959\u20132024", "depth climatology"),
      `Used for` = c("CO\u2082 level and seasonal cycle", "Southern CO\u2082 level and seasonal cycle",
                     "CO\u2082 before the station record", "\u03b4\u00b9\u00b3C before the station record",
                     "The fossil fingerprint",
                     "Air\u2013sea and air\u2013land exchange speed",
                     "Pre-bomb \u00b9\u2074C (industrial Suess effect)",
                     "How much bomb \u00b9\u2074C the ocean took up",
                     "Splitting land from ocean uptake",
                     "The ocean's interior carbon and \u03b4\u00b9\u00b3C"),
      check.names = FALSE)
  }, striped = TRUE, width = "100%")
}

