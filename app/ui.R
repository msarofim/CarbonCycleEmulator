# =====================================================================
# ui.R -- six teaching tabs (DESIGN section 7) plus, since 2026-09-22, a
# SEVENTH for the beta review.
#
# Audience is introductory environmental science. The house style, from
# CLAUDE.md: every panel opens with a one-sentence takeaway, units get a
# tooltip, and anything a specialist would want goes in a collapsible so it does
# not tax everyone else.
#
# ⭐ THE SEVENTH TAB HAS A DIFFERENT AUDIENCE ON PURPOSE. "Known issues" is
# written for the people being asked to judge the model, not for the student:
# it names each remaining flaw, shows it measured by the running model, and asks
# whether it is a deal-breaker, fixable or acceptable. The six teaching tabs are
# untouched by it, except where a flaw is VISIBLE on one of them -- there the
# tab carries a one-line pointer to its card, because a reader who finds a
# defect before the app admits to it has found a hidden defect.
# =====================================================================

# A unit gloss rendered as a dotted-underline tooltip.
gloss <- function(term, meaning) {
  tags$abbr(title = meaning, style = "text-decoration: underline dotted; cursor: help;",
            term)
}

takeaway <- function(...) div(class = "takeaway", ...)

info_box <- function(title, ...) {
  tags$details(class = "moreinfo", tags$summary(title), div(...))
}

# The provenance banner. Deliberately not dismissible: what the model is fitted
# to changes what every number on every tab means.
provenance_banner <- function() {
  cls <- if (app_params$has_posterior) "prov prov-ok" else "prov prov-warn"
  div(class = cls,
      tags$strong(sprintf("%s %s \u2014 parameters: %s (%s).",
                          toupper(APP_STAGE), APP_VERSION,
                          app_params$source, app_params$status)),
      " ", app_params$detail,
      " ", APP_STAGE_NOTE,
      " ", tags$em(sprintf("Reviewers: see the \u201c%s\u201d tab.", RV_TAB_TITLE)))
}

# Shown once, at the top of the first tab: the only place a first-time visitor
# is told what they just waited for. Measured, not guessed -- see APP_WARMUP_NOTE.
warmup_note <- function() div(class = "caveat", APP_WARMUP_NOTE)

# A pointer FROM a teaching tab TO the card that owns a flaw visible on it.
# Written as a function so the card number cannot be typed twice.
see_card <- function(id, what) {
  c_ <- rv_card(id)
  div(class = "caveat",
      tags$strong(sprintf("Known issue %d: ", c_$id)), what,
      sprintf(" See \u201c%s\u201d \u2192 card %d, \u201c%s\u201d.",
              RV_TAB_TITLE, c_$id, c_$title))
}

# ---- the review tab's furniture -------------------------------------
review_ask_block <- function() {
  tags$ul(class = "asklist", lapply(RV_ASK, function(a)
    tags$li(tags$strong(a), " \u2014 ", RV_ASK_GLOSS[[a]])))
}

#' One card. `plot_id` NULL for a card with nothing to draw.
review_card <- function(id, plot_id = NULL, plot_height = "330px",
                        extra_plot_id = NULL, extra_height = "300px") {
  c_ <- rv_card(id)
  url <- rv_card_url(id)
  div(class = "card-issue",
      h4(sprintf("%d. %s", c_$id, c_$title)),
      div(class = "card-class",
          tags$strong(toupper(c_$class)), " \u2014 ", RV_CLASS_GLOSS[[c_$class]]),
      p(c_$plain),
      if (!is.null(plot_id)) plotOutput(plot_id, height = plot_height),
      if (!is.null(extra_plot_id)) plotOutput(extra_plot_id, height = extra_height),
      info_box("The detail behind this one", p(c_$detail)),
      div(class = "card-ask", tags$strong("What I am asking: "), c_$ask),
      if (is.null(url))
        div(class = "caveat",
            tags$strong("The comment link is not set in this build. "),
            sprintf("Reply on the post and lead with \u201ccard %d\u201d.", c_$id))
      else
        p(tags$a(href = url, target = "_blank",
                 sprintf("Comment on card %d \u2192", c_$id))))
}

navbarPage(
  title = APP_TITLE,
  id = "tabs",
  theme = bs_theme(version = 5, bootswatch = "flatly", base_font = font_google("Inter")),
  header = tagList(
    tags$head(tags$style(HTML("
      .takeaway { font-size: 1.08rem; line-height: 1.5; background: #eef5fb;
                  border-left: 4px solid #1b6ca8; padding: 10px 14px;
                  margin-bottom: 14px; border-radius: 3px; }
      .prov { font-size: 0.87rem; padding: 7px 12px; margin-bottom: 12px;
              border-radius: 3px; }
      .prov-warn { background: #fdf3e3; border-left: 4px solid #d68910; }
      .prov-ok   { background: #eafaf1; border-left: 4px solid #27ae60; }
      .moreinfo { margin-top: 12px; font-size: 0.92rem; }
      .moreinfo > summary { cursor: pointer; color: #1b6ca8; font-weight: 600; }
      .moreinfo > div { padding: 8px 4px 4px 14px; color: #333; }
      .caveat { font-size: 0.88rem; color: #7d6608; background: #fef9e7;
                padding: 8px 12px; border-radius: 3px; margin-top: 10px; }
      .readout { font-size: 1.5rem; font-weight: 700; color: #1b6ca8; }
      .readout-label { font-size: 0.85rem; color: #555; }
      .card-issue { border: 1px solid #d5dbdb; border-radius: 5px;
                    padding: 16px 18px; margin-bottom: 22px; background: #fff; }
      .card-issue h4 { font-weight: 700; margin-bottom: 6px; }
      .card-class { font-size: 0.82rem; color: #555; margin-bottom: 10px; }
      .card-ask { background: #eef5fb; border-left: 4px solid #1b6ca8;
                  padding: 9px 13px; margin-top: 12px; border-radius: 3px; }
      .asklist { font-size: 0.95rem; }
    "))),
    div(style = "padding: 0 14px;", provenance_banner())
  ),

  # ---- 1. The Keeling Curve ------------------------------------------
  tabPanel(
    "The Keeling Curve",
    sidebarLayout(
      sidebarPanel(
        width = 3,
        sliderInput("k_years", "Years shown", min = 1750, max = 2024,
                    value = c(1958, 2024), step = 1, sep = ""),
        radioButtons("k_hemi", "Hemisphere",
                     c("Both" = "both", "Northern only" = "NH",
                       "Southern only" = "SH")),
        checkboxInput("k_obs", "Show measurements", TRUE),
        info_box("Why the two hemispheres differ",
                 p("Almost all fossil fuel is burned north of the equator, so",
                   "the Northern Hemisphere runs a little higher. Air takes",
                   "about a year to mix between hemispheres, which is why the",
                   "south lags rather than matching."),
                 p("The northern seasonal swing is much larger because most of",
                   "the world's land — and so most of its vegetation — is in",
                   "the north."))
      ),
      mainPanel(
        width = 9,
        warmup_note(),
        takeaway(textOutput("k_takeaway", inline = TRUE)),
        plotOutput("k_plot", height = "380px"),
        see_card(1, paste("Two model lines are drawn. The solid one is what the",
                          "calibration actually scored against these measurements",
                          "\u2014 the hemispheric box minus a fitted station offset",
                          "\u2014 and the faint one is the box itself.")),
        hr(),
        h5("The seasonal cycle on its own"),
        p("Strip out the long-term rise and one year is left: the land",
          "breathing in during the northern growing season and out again in",
          "winter."),
        plotOutput("k_seasonal", height = "260px")
      )
    )
  ),

  # ---- 2. Where does the carbon go -----------------------------------
  tabPanel(
    "Where does the carbon go?",
    sidebarLayout(
      sidebarPanel(
        width = 3,
        sliderInput("w_years", "Years shown", min = 1750, max = 2024,
                    value = c(1850, 2024), step = 1, sep = ""),
        info_box("What the numbers mean",
                 p(gloss("GtC", "gigatonnes of carbon: a billion tonnes"),
                   " is the unit. One GtC is about 3.7 billion tonnes of CO₂."),
                 p("The ", gloss("airborne fraction",
                                 "the share of everything ever emitted that is still in the air"),
                   " is the single most useful summary: it says how much of the",
                   "problem the land and ocean have absorbed for us."))
      ),
      mainPanel(
        width = 9,
        takeaway(textOutput("w_takeaway", inline = TRUE)),
        fluidRow(
          column(4, div(class = "readout-label", "Still in the air"),
                 div(class = "readout", textOutput("w_atm", inline = TRUE))),
          column(4, div(class = "readout-label", "Taken up by land"),
                 div(class = "readout", textOutput("w_land", inline = TRUE))),
          column(4, div(class = "readout-label", "Taken up by the ocean"),
                 div(class = "readout", textOutput("w_ocean", inline = TRUE)))
        ),
        br(),
        plotOutput("w_partition", height = "330px"),
        hr(),
        fluidRow(
          column(6, h5("Airborne fraction"), plotOutput("w_af", height = "260px")),
          column(6, h5("Does the model agree with the measured budget?"),
                 plotOutput("w_gcb", height = "260px"))
        )
      )
    )
  ),

  # ---- 3. What if ----------------------------------------------------
  tabPanel(
    "What if…?",
    sidebarLayout(
      sidebarPanel(
        width = 3,
        p(tags$strong("Switch a mechanism off"), " and the model reruns without it."),
        radioButtons("c_mech", NULL, choices = ccx_mechanism_choices()),
        sliderInput("c_years", "Years shown", min = 1750, max = 2024,
                    value = c(1850, 2024), step = 1, sep = ""),
        uiOutput("c_blurb")
      ),
      mainPanel(
        width = 9,
        takeaway(textOutput("c_takeaway", inline = TRUE)),
        plotOutput("c_plot", height = "400px"),
        uiOutput("c_caveat"),
        info_box("Why there is no separate 'no land sink' switch",
                 p("In this model the land takes up carbon for exactly one",
                   "reason: plants grow faster when CO₂ is higher. There is no",
                   "second land-uptake mechanism to remove, so offering two",
                   "switches would imply a distinction the model does not have."))
      )
    )
  ),

  # ---- 4. Isotope fingerprints ---------------------------------------
  tabPanel(
    "Isotope fingerprints",
    sidebarLayout(
      sidebarPanel(
        width = 3,
        sliderInput("i_years", "Years shown", min = 1750, max = 2024,
                    value = c(1940, 2024), step = 1, sep = ""),
        info_box("What the two isotopes tell you",
                 p(tags$strong("δ¹³C"), " — plants prefer the lighter carbon-12,",
                   "so fossil fuels (ancient plants) are ¹³C-poor. Burning them",
                   "dilutes the air's ¹³C. That falling line is the fingerprint",
                   "that the extra CO₂ is fossil, not volcanic or oceanic."),
                 p(tags$strong("Δ¹⁴C"), " — carbon-14 is radioactive and decays",
                   "over thousands of years, so fossil carbon has none left at",
                   "all. The 1960s spike is from atmospheric nuclear weapons",
                   "tests, and how fast it fell tells us how quickly the ocean",
                   "and land take carbon out of the air."))
      ),
      mainPanel(
        width = 9,
        takeaway(textOutput("i_takeaway", inline = TRUE)),
        h5("δ¹³C: the Suess effect"),
        plotOutput("i_d13c", height = "280px"),
        see_card(2, paste("The model's north\u2013south \u03b4\u00b9\u00b3C difference is about",
                          "twice the measured one. The trend at each station is",
                          "right; the difference between them is not.")),
        hr(),
        h5("Δ¹⁴C: the bomb spike and how fast it drained away"),
        plotOutput("i_d14c", height = "300px"),
        info_box("Why the southern spike arrives later and smaller",
                 p("Nearly all atmospheric weapons tests were in the north. The",
                   "spike had to mix across the equator, which takes about a",
                   "year, and by the time it arrived it had already been diluted."))
      )
    )
  ),

  # ---- 5. Futures ----------------------------------------------------
  tabPanel(
    "Futures",
    sidebarLayout(
      sidebarPanel(
        width = 3,
        tabsetPanel(
          id = "f_mode", type = "pills",
          tabPanel(
            "Scenarios", br(),
            checkboxGroupInput("f_ssps", "Compare scenarios",
                               choices = APP_SSPS,
                               selected = c("ssp126", "ssp245", "ssp585")),
            radioButtons("f_yvar", "Show",
                         c("CO₂ concentration" = "co2_ppm",
                           "Temperature" = "gmst"))
          ),
          tabPanel(
            "Build your own", br(),
            selectInput("s_kind", "Fossil emissions after today",
                        c("Hold at today's level" = "constant",
                          "Fall linearly to zero" = "to_zero",
                          "Change by a fixed rate" = "rate")),
            conditionalPanel("input.s_kind == 'to_zero'",
                             sliderInput("s_zero_year", "Reach zero in",
                                         2030, 2100, 2060, step = 5, sep = "")),
            conditionalPanel("input.s_kind == 'rate'",
                             sliderInput("s_rate", "Percent per year",
                                         -5, 5, 1, step = 0.5)),
            selectInput("s_bg", "Everything else follows", APP_SSPS,
                        selected = "ssp245"),
            actionButton("s_go", "Run it", class = "btn-primary btn-sm")
          ),
          tabPanel(
            "Pulse lab", br(),
            selectInput("p_bg", "Background scenario", APP_SSPS,
                        selected = "ssp245"),
            sliderInput("p_gtc", "Pulse size (GtC)", 10, 500,
                        APP_PULSE_GtC_DEFAULT, step = 10),
            sliderInput("p_year", "Release it in", 2030, 2100,
                        APP_PULSE_YEAR_DEFAULT, step = 10, sep = ""),
            actionButton("p_go", "Release the pulse", class = "btn-primary btn-sm"),
            helpText("Runs the model twice — with and without the pulse — and",
                     "takes the difference. That is the only honest way to ask",
                     "what one extra tonne does.")
          )
        )
      ),
      mainPanel(
        width = 9,
        takeaway(textOutput("f_takeaway", inline = TRUE)),
        plotOutput("f_plot", height = "400px"),
        uiOutput("f_notes"),
        info_box("Where the future temperature comes from",
                 p("This model tracks carbon, not the whole climate system. Its",
                   "CO₂ is turned into a temperature using a response fitted to",
                   "FaIR, a widely used climate emulator. Everything that is not",
                   "CO₂ — methane, aerosols, ozone — is held at that scenario's",
                   "values and does not respond to anything you change here."),
                 p("So the honest reading is: you are changing CO₂ only, in a",
                   "world whose other greenhouse gases and pollutants follow the",
                   "background scenario you picked."))
      )
    )
  ),

  # ---- 7. Known issues (the beta review) ------------------------------
  # Cards are rendered from RV_CARDS by stable id, so reordering this block
  # cannot renumber a card somebody has already written a comment about.
  tabPanel(
    RV_TAB_TITLE,
    fluidRow(
      column(
        9, offset = 0,
        h3(sprintf("What this model gets wrong \u2014 and a question for you (%s %s)",
                   APP_STAGE, APP_VERSION)),
        p(RV_TAB_LEAD),
        review_ask_block(),
        div(class = "caveat", APP_FEEDBACK_HOW),
        if (!app_link_ok(APP_FEEDBACK_URL))
          div(class = "prov prov-warn",
              tags$strong("This build has no comment link set. "),
              "Set APP_FEEDBACK_URL in app/global.R before deploying."),
        p(tags$small(paste("Every number below is measured by the model this app",
                           "is running, not quoted from a note. The first time you",
                           "open this tab some cards run the model again and take",
                           "a few seconds."))),
        hr(),
        review_card(1, "rv_repdc",   "320px"),
        review_card(2, "rv_gradient", "300px"),
        review_card(3, "rv_diseq",   "320px"),
        review_card(4, "rv_variance", "300px", "rv_enso", "320px"),
        review_card(5, "rv_irf",     "320px", "rv_partition", "300px"),
        review_card(6, "rv_control", "330px"),
        review_card(7, NULL),
        review_card(8, NULL),
        div(class = "card-issue",
            h4("The stand-ins and the provisional constants, listed"),
            tableOutput("rv_shims"),
            uiOutput("rv_constants"))
      )
    )
  ),

  # ---- 6. Under the hood ---------------------------------------------
  tabPanel(
    "Under the hood",
    fluidRow(
      column(
        7,
        h4("What this model is"),
        p("Two hemispheres, each with an atmosphere, a two-pool land biosphere,",
          "and an ocean column of a mixed layer over ten diffusive layers.",
          "Monthly steps from 1750. It carries all three carbon isotopes —",
          "¹²C, ¹³C and ¹⁴C — which is what lets the isotope tab work."),
        plotOutput("h_diagram", height = "330px"),
        h4("Parameters"),
        p("These are the numbers the calibration fits. Everything else — ocean",
          "area, the mass of the atmosphere, carbonate chemistry constants — is",
          "fixed from measurements and cited in the repository."),
        tableOutput("h_params")
      ),
      column(
        5,
        h4("What it is fitted to"),
        tableOutput("h_data"),
        h4("What it cannot do"),
        tags$ul(
          tags$li("No methane, nitrous oxide, aerosols or ozone. Only CO₂."),
          tags$li(paste("No ocean circulation — the deep ocean is reached by",
                        "diffusion only, which is a real simplification of how",
                        "carbon actually gets down there.")),
          tags$li(paste("Two land pools standing in for every ecosystem on",
                        "Earth. No fire, no permafrost, no nutrient limitation.")),
          tags$li(paste("Two boxes of atmosphere. Nothing about where in a",
                        "hemisphere anything happens.")),
          tags$li("Teaching software. Not peer-reviewed, not for citation.")
        ),
        h4("Source"),
        p("Model, data-download scripts and the full decision log are in the",
          "repository, including what was tried and abandoned."),
        p(tags$a(href = APP_REPO_URL, target = "_blank", APP_REPO_URL)),
        p(tags$small(APP_AUTHOR))
      )
    )
  )
)
