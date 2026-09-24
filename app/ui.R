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
#
# ⚠ SHORTENED 2026-09-22 (Marcus, review O2: "simplify yellow box text"). It
# used to carry stage + version + source + status + the full fit description +
# the beta note + the reviewer pointer, which is five sentences above every
# tab. What is left is what a first-time reader needs before they read a
# number: what this is, that it is one fit rather than a posterior, and where
# the flaws are written down. The rest moved to "Under the hood" as
# provenance_detail(), which is where someone who wants it will look.
provenance_banner <- function() {
  cls <- if (app_params$has_posterior) "prov prov-ok" else "prov prov-warn"
  div(class = cls,
      tags$strong(sprintf("%s %s \u2014 %s.", toupper(APP_STAGE), APP_VERSION,
                          app_params$status)),
      " Teaching software \u2014 not peer-reviewed, not for citation.",
      " ", tags$em(sprintf("Reviewers: see the \u201c%s\u201d tab.", RV_TAB_TITLE)))
}

# What the banner used to carry, kept whole and moved off the top of every tab.
provenance_detail <- function() {
  tagList(
    p(sprintf("Parameters: %s (%s).", app_params$source, app_params$status),
      " ", app_params$detail),
    p(APP_STAGE_NOTE))
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
        # Marcus's own wording (2026-09-22, review K4), used as supplied.
        see_card(1, paste("Two model lines are drawn. The solid one shows the",
                          "model result including a fitted station offset. The",
                          "faint one is the box before the offset.")),
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
                 # W4 (Marcus 2026-09-22): the old gloss called this "the single
                 # most useful summary", which overclaims. It is a ratio of one
                 # year's emissions to one year's uptake, so it moves with how
                 # fast emissions are changing and how far the sinks are from
                 # equilibrium -- not only with how good the sinks are.
                 p("The ", gloss("airborne fraction",
                                 "the share of everything ever emitted that is still in the air"),
                   " is the ratio of emissions to the rise in atmospheric",
                   "concentration in a given year. It is a popular metric, but",
                   "easily misunderstood: it depends both on how quickly emissions",
                   "are changing and on the total sink (itself a reflection of how",
                   "far the land and ocean are from equilibrium), so any change —",
                   "or lack of change — in the airborne fraction should not be",
                   "attributed to one factor alone."))
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
        # W2 (Marcus 2026-09-22). Computed, not recalled -- and the computation
        # corrected the premise; see output$w_luc_note.
        div(class = "caveat", tags$strong("About land use: "),
            textOutput("w_luc_note", inline = TRUE)),
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
        # C1 + C2 + C3 (Marcus 2026-09-22). The level chart above cannot show
        # what ENSO does -- a 1-2 ppm wobble is invisible against a 130 ppm rise
        # -- so "switch it off and the wobbles go" was a claim the tab never
        # drew. This is the panel that carries it, and it is also where the
        # observations belong: the ENSO switch means nothing until you can see
        # it move the model toward the data.
        hr(),
        h5("The same run, year by year"),
        p("The chart above is the level. This one is how much CO₂ went up in",
          "each single year — which is where the interannual wobbles live, and",
          "where switching a mechanism off is actually visible."),
        plotOutput("c_growth", height = "300px"),
        textOutput("c_growth_note"),
        # F1 (Marcus 2026-09-24): "a third panel showing the driver itself --
        # volcanic AOD by year, the ENSO index by year, emissions by year."
        # Placed THIRD, after the level and the growth rate, because it reads
        # backwards: here is what the model did, here is where the wobbles live,
        # and here is the input those came from. Rendered through uiOutput
        # because three of the seven switches have no driver to draw and get a
        # sentence instead of an empty chart (server.R, output$c_driver_ui).
        hr(),
        h5("The driver behind the switch"),
        p("The two charts above are what the model did. This one is what it was",
          "told \u2014 the input series itself, drawn as the full model receives it",
          "and as the counterfactual receives it. Some switches delete the input;",
          "others leave it exactly as it is and remove only the model's response",
          "to it."),
        uiOutput("c_driver_ui"),
        # C5 (Marcus 2026-09-22): "exactly one reason" was true of the
        # SECULAR sink and false as written -- the seasonal cycle is driven by
        # a prescribed seasonal light and temperature shape, not by CO₂.
        info_box("Why there is no separate 'no land sink' switch",
                 p("The land's long-term uptake in this model has one cause:",
                   "plants grow faster when CO₂ is higher. There is no second",
                   "long-term land-uptake mechanism to remove, so offering two",
                   "switches would imply a distinction the model does not have."),
                 p("The land does breathe in and out over the year as well, but",
                   "that seasonal swing is driven by sunlight and temperature",
                   "rather than by CO₂, and it very nearly cancels within each",
                   "year. It is the seasonal cycle on the first tab."))
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
        # I1 (Marcus 2026-09-22): the same control the Keeling tab has. The
        # north-south difference is discussed on this tab and was never drawn.
        radioButtons("i_hemi", "Hemisphere (\u03b4\u00b9\u00b3C)",
                     c("Both" = "both", "Northern only" = "NH",
                       "Southern only" = "SH")),
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
        # The splice caption (Marcus 2026-09-22). Every mode on this tab -- the
        # scenarios, build-your-own and the pulse lab -- used to carry the
        # SSP/LUH2 land-use history instead of the observed budget the Keeling
        # tab draws, so this tab sat 12-14 ppm below that one at 2024 with
        # nothing on the page to say why. The runs are spliced now
        # (app_splice_history); this says so, because a handover the reader
        # cannot see is the same problem one step further along.
        div(class = "caveat", APP_SPLICE_NOTE),
        # F2 (Marcus 2026-09-22): only in the pulse lab, and only once a pulse
        # has been run. conditionalPanel keeps it out of the other two modes
        # rather than rendering an empty box there.
        conditionalPanel(
          "input.f_mode == 'Pulse lab'",
          hr(),
          h5("Where the extra carbon ends up"),
          plotOutput("f_partition", height = "300px")),
        uiOutput("f_notes"),
        # F1 (Marcus 2026-09-22): his reframing, used as supplied, and the
        # "honest reading" paragraph deleted as he asked.
        info_box("Where the future temperature comes from",
                 p("Future scenario temperatures are a result of feeding scenario",
                   "emissions through the FaIR model. The pulse lab and the",
                   "build-your-own scenarios only allow changes to carbon",
                   "emissions, not non-CO₂ greenhouse gases, aerosols, or ozone",
                   "precursors."))
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
        # N2 (Marcus 2026-09-22) applies here too: the "measured by the running
        # model, not quoted from a note" claim is cut from BOTH places it was
        # made (RV_TAB_LEAD was the other). What is left is the part a reader
        # needs -- why the tab pauses on first view.
        p(tags$small(paste("The first time you open this tab some cards run the",
                           "model again and take a few seconds."))),
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
            # N12 (Marcus 2026-09-22): two lists, labelled, because they are
            # two different things -- see card 8's detail.
            h5("Stand-ins: fitted names that absorb a discrepancy"),
            tableOutput("rv_standins"),
            h5("Held: parameters the calibration was not allowed to move"),
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
        # U6 (Marcus 2026-09-22): the GOAL before the structure, his wording.
        p("A carbon-cycle model able to duplicate observed hemispheric, seasonal",
          "and isotopic patterns, integrated into a pedagogical framework."),
        # U4 (Marcus 2026-09-22): "It carries all three carbon isotopes" became
        # "All exchanges include all three isotopes"; the trailing clause cut.
        p("Two hemispheres, each with an atmosphere, a two-pool land biosphere,",
          "and an ocean column of a mixed layer over ten diffusive layers, with",
          "a cold high-latitude surface box and a deep box alongside it.",
          "Monthly steps from 1750. All exchanges include all three carbon",
          "isotopes — ¹²C, ¹³C and ¹⁴C."),
        plotOutput("h_diagram", height = "330px"),
        h4("Parameters"),
        p("These are the numbers the calibration fits. Everything else — ocean",
          "area, the mass of the atmosphere, carbonate chemistry constants — is",
          "fixed from measurements and cited in the repository."),
        tableOutput("h_params")
      ),
      column(
        5,
        # U2 (Marcus 2026-09-22): IGCC temperature used to sit in the table
        # below, which says what the model is FITTED to. It is a driver. Two
        # boxes now, and the driver list is what the Keeling tab's takeaway
        # points at.
        h4("What drives the model"),
        p(tags$small("Prescribed inputs.")),
        tableOutput("h_drivers"),
        h4("What it is fitted to"),
        p(tags$small("Observations the calibration scored the model against.")),
        tableOutput("h_data"),
        h4("What it cannot do"),
        tags$ul(
          tags$li("No methane, nitrous oxide, aerosols or ozone. Only CO₂."),
          # U5/N6 (Marcus 2026-09-22): "No ocean circulation — diffusion only"
          # was STALE. The canonical carries HILDA cold surface and deep boxes
          # in each hemisphere, a biological pump in both columns, and an
          # ENSO-driven upwelling limb. What it does NOT have is any deep
          # exchange BETWEEN the hemispheres — they meet only in the air — and
          # that is the honest sentence. The tropical box was explored and not
          # adopted.
          tags$li(paste("The two hemispheres meet only in the atmosphere. Carbon",
                        "does move between the surface and the deep ocean — by",
                        "mixing, by a biological pump, by sinking cold water at",
                        "high latitudes, and by an upwelling limb that responds",
                        "to El Niño — but there is no deep exchange from one",
                        "hemisphere's ocean to the other's, and no tropical",
                        "ocean box between them.")),
          tags$li(paste("Two land pools standing in for every ecosystem on",
                        "Earth. No fire, no permafrost, no nutrient limitation.")),
          tags$li(paste("Two boxes of atmosphere. Nothing about where in a",
                        "hemisphere anything happens.")),
          tags$li("Teaching software. Not peer-reviewed, not for citation.")
        ),
        h4("Which numbers this app is running on"),
        provenance_detail(),
        h4("Source"),
        p("Model, data-download scripts and the full decision log are in the",
          "repository, including what was tried and abandoned."),
        p(tags$a(href = APP_REPO_URL, target = "_blank", APP_REPO_URL)),
        # U3 / ruling R4 (Marcus 2026-09-22): no institutional affiliation on
        # this page. Marron Institute is for professional output — posters,
        # talks, papers — and this app is Substack-facing.
        p(tags$small(APP_AUTHOR))
      )
    )
  )
)
